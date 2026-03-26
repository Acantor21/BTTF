-- DropMechanicClient
-- Client-side presentation for the Drop Mechanic.
-- Studio path: StarterPlayerScripts.DropMechanicClient
-- Sprint: 002 | System: Drop Mechanic | GDD: design/gdd/drop-mechanic.md

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local DropConfig      = require(ReplicatedStorage.Config.DropConfig)
local InputController = require(script.Parent.InputController)

local function _makeEvent(name: string): BindableEvent
	local be = Instance.new("BindableEvent")
	be.Name = name; be.Parent = script
	return be
end

local _beDropLanded    = _makeEvent("OnDropLanded")
local _beDropCancelled = _makeEvent("OnDropCancelled")
local _beZoneHighlight = _makeEvent("OnZoneHighlight")

local function _waitForRemote(folderName: string, remoteName: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild(folderName, 10)
	if not folder then error(("[DropMechanicClient] Timed out waiting for %s"):format(folderName)) end
	local remote = folder:WaitForChild(remoteName, 10)
	if not remote then error(("[DropMechanicClient] Timed out waiting for remote %s"):format(remoteName)) end
	return remote :: RemoteEvent
end

local _reCommitDrop  = _waitForRemote("DropMechanicRemotes", DropConfig.REMOTE_COMMIT_DROP)
local _reDropAck     = _waitForRemote("DropMechanicRemotes", DropConfig.REMOTE_DROP_ACK)
local _reDropReject  = _waitForRemote("DropMechanicRemotes", DropConfig.REMOTE_DROP_REJECT)
local _reParkTrigger = _waitForRemote("DropMechanicRemotes", DropConfig.REMOTE_PARK_TRIGGER)

local _zoneAnchors: {[string]: BasePart} = {}

local function _refreshZoneAnchors()
	local folder = workspace:FindFirstChild("DropZones")
	if not folder then return end
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") then _zoneAnchors[child.Name] = child :: BasePart end
	end
end
_refreshZoneAnchors()

local _dzFolder = workspace:FindFirstChild("DropZones")
if _dzFolder then
	_dzFolder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then _zoneAnchors[child.Name] = child :: BasePart end
	end)
end

local _hoveredZone:        string? = nil
local _arcInFlight:        boolean = false
local _zoneHighlightState: {[string]: string} = {}
local _arcConn:            RBXScriptConnection? = nil
local _arcVisual:          BasePart? = nil

local HIGHLIGHT_COLOR = Color3.fromRGB(80, 220, 80)
local DIM_COLOR       = Color3.fromRGB(40, 100, 40)
local NORMAL_COLOR    = Color3.fromRGB(160, 160, 160)

local function _setZoneHighlight(zoneId: string, state: string)
	if _zoneHighlightState[zoneId] == state then return end
	_zoneHighlightState[zoneId] = state
	local part = _zoneAnchors[zoneId]
	if not part then return end
	if state == "highlighted" then
		part.Color = HIGHLIGHT_COLOR; part.Material = Enum.Material.Neon
	elseif state == "dimmed" then
		part.Color = DIM_COLOR; part.Material = Enum.Material.SmoothPlastic
	else
		part.Color = NORMAL_COLOR; part.Material = Enum.Material.SmoothPlastic
	end
end

local function _clearAllHighlights()
	for zoneId in _zoneAnchors do _setZoneHighlight(zoneId, "normal") end
	if _hoveredZone ~= nil then _hoveredZone = nil; _beZoneHighlight:Fire(nil) end
end

local function _evaluateNearestZone(worldHit: Vector3, validZones: {string}): string?
	local nearestId: string? = nil
	local nearestDist: number = math.huge
	for _, zoneId in validZones do
		local anchor = _zoneAnchors[zoneId]
		if anchor then
			local dx = anchor.Position.X - worldHit.X
			local dz = anchor.Position.Z - worldHit.Z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < nearestDist then nearestDist = dist; nearestId = zoneId end
		end
	end
	return nearestDist <= DropConfig.ZONE_SNAP_MAX_DISTANCE and nearestId or nil
end

local function _bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t
	return (u * u) * p0 + (2 * u * t) * p1 + (t * t) * p2
end

local function _handPosition(): Vector3
	local anchor = workspace:FindFirstChild("DropHandAnchor")
	if anchor and anchor:IsA("BasePart") then return (anchor :: BasePart).Position end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then return root.Position + Vector3.new(0, 2, 0) end
	return Vector3.new(0, 10, 0)
end

local function _playArc(itemId: string, zoneId: string)
	local anchor = _zoneAnchors[zoneId]
	if not anchor then _beDropLanded:Fire(itemId, zoneId, 0); return end
	_arcInFlight = true
	local p0 = _handPosition()
	local p2 = anchor.Position
	local p1 = (p0 + p2) / 2 + Vector3.new(0, DropConfig.ARC_HEIGHT, 0)
	local dur = math.min(DropConfig.BASE_ARC_DURATION + (p2 - p0).Magnitude * DropConfig.ARC_DISTANCE_FACTOR, DropConfig.ARC_MAX_DURATION)
	local visual = Instance.new("Part")
	visual.Size = Vector3.new(0.5, 0.5, 0.5); visual.Shape = Enum.PartType.Ball
	visual.Color = Color3.fromRGB(255, 200, 50); visual.Material = Enum.Material.Neon
	visual.CanCollide = false; visual.Anchored = true; visual.CastShadow = false
	visual.Name = "DropArcVisual"; visual.Position = p0; visual.Parent = workspace
	_arcVisual = visual
	if _arcConn then _arcConn:Disconnect(); _arcConn = nil end
	local elapsed = 0
	_arcConn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local t = math.min(elapsed / dur, 1)
		visual.Position = _bezier(p0, p1, p2, t)
		if t >= 1 then
			if _arcConn then _arcConn:Disconnect() end
			_arcConn = nil; visual:Destroy(); _arcVisual = nil; _arcInFlight = false
			_beDropLanded:Fire(itemId, zoneId, dur); _setZoneHighlight(zoneId, "normal")
		end
	end)
end

InputController.DropHover:Connect(function(hitPoint: Vector3?)
	if _arcInFlight then return end
	local activeItemId = InputController.GetActiveItemId()
	if not activeItemId then _clearAllHighlights(); return end
	local item = InputController.GetHandItems()[activeItemId]
	if not item or not hitPoint then _clearAllHighlights(); return end
	local validZones = item.validDropZones
	local nearest = _evaluateNearestZone(hitPoint, validZones)
	for zoneId in _zoneAnchors do
		local isValid = false
		for _, vz in validZones do if vz == zoneId then isValid = true; break end end
		if zoneId == nearest then _setZoneHighlight(zoneId, "highlighted")
		elseif isValid then _setZoneHighlight(zoneId, "dimmed")
		else _setZoneHighlight(zoneId, "normal") end
	end
	if nearest ~= _hoveredZone then _hoveredZone = nearest; _beZoneHighlight:Fire(nearest) end
end)

InputController.DropCommit:Connect(function(hitPoint: Vector3?)
	if _arcInFlight then return end
	local activeItemId = InputController.GetActiveItemId()
	if not activeItemId then _beDropCancelled:Fire(); return end
	local committedZone: string? = nil
	if hitPoint then
		local item = InputController.GetHandItems()[activeItemId]
		if item then committedZone = _evaluateNearestZone(hitPoint, item.validDropZones) end
	end
	if not committedZone then _clearAllHighlights(); _beDropCancelled:Fire(); return end
	for zoneId in _zoneAnchors do
		if zoneId ~= committedZone then _setZoneHighlight(zoneId, "normal") end
	end
	_reCommitDrop:FireServer(activeItemId, committedZone)
end)

InputController.DropCancel:Connect(function() _clearAllHighlights(); _beDropCancelled:Fire() end)
InputController.ParkCommit:Connect(function() _clearAllHighlights(); _reParkTrigger:FireServer() end)

_reDropAck.OnClientEvent:Connect(function(itemId: unknown, zoneId: unknown)
	if type(itemId) ~= "string" or type(zoneId) ~= "string" then
		warn("[DropMechanicClient] DropAck — bad payload types"); return
	end
	_clearAllHighlights(); _playArc(itemId, zoneId)
end)

_reDropReject.OnClientEvent:Connect(function(itemId: unknown, zoneId: unknown, reason: unknown)
	warn(("[DropMechanicClient] Drop rejected — item=%s zone=%s reason=%s"):format(
		tostring(itemId), tostring(zoneId), tostring(reason)))
	_clearAllHighlights(); _beDropCancelled:Fire()
end)

local DropMechanicClient = {}
DropMechanicClient.OnDropLanded    = _beDropLanded.Event
DropMechanicClient.OnDropCancelled = _beDropCancelled.Event
DropMechanicClient.OnZoneHighlight = _beZoneHighlight.Event
function DropMechanicClient.GetHoveredZone(): string? return _hoveredZone end
function DropMechanicClient.IsArcInFlight(): boolean return _arcInFlight end
return DropMechanicClient
