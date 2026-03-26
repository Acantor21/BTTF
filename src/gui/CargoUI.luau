-- CargoUI
-- Client-side cargo hand tray UI.
-- Studio path: StarterGui.CargoUI
-- Sprint: 002 | System: Cargo UI | GDD: design/gdd/cargo-ui.md

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local CargoUIConfig = require(script.Parent.CargoUIConfig)
local CargoUI = {}

local _localPlayer = Players.LocalPlayer
local _playerGui = _localPlayer and _localPlayer:FindFirstChildOfClass("PlayerGui")
if not _playerGui then return CargoUI end

local _InputController = nil
task.spawn(function()
	local scripts = _localPlayer:WaitForChild("PlayerScripts", 10)
	if scripts then
		local ok, result = pcall(require, scripts:WaitForChild("InputController", 5))
		if ok then
			_InputController = result
			if _activeItemId then _InputController.SetActiveCargoId(_activeItemId) end
			if _InputController.SetHandItems then _InputController.SetHandItems(_buildHandItems()) end
		end
	end
end)

local _remotesFolder   = ReplicatedStorage:WaitForChild("CargoUIRemotes", 10)
local _reHandChanged   = _remotesFolder and _remotesFolder:WaitForChild("CargoUI_HandChanged",   5)
local _reItemDiscarded = _remotesFolder and _remotesFolder:WaitForChild("CargoUI_ItemDiscarded", 5)
local _rePoolExhausted = _remotesFolder and _remotesFolder:WaitForChild("CargoUI_PoolExhausted", 5)

local _hand: {any}       = {}
local _poolCount: number = 0
local _activeItemId: string? = nil
local _slotFrames: {Frame}   = {}
local _gui: ScreenGui?       = nil

-- Zone mapping: targetVariable → valid drop zones
local ALL_ZONES = {"zone_mcflyHouse", "zone_townSquare", "zone_clockTower", "zone_docGarage", "zone_biffCar"}
local ZONE_BY_TARGET: {[string]: {string}} = {
	georgeConfidence  = {"zone_mcflyHouse"},
	biffInfluence     = {"zone_townSquare"},
	mcflyLegacy       = {"zone_mcflyHouse"},
	economicHealth    = {"zone_townSquare"},
	timelineStability = {"zone_clockTower"},
	docReputation     = {"zone_docGarage"},
	almanacExists     = {"zone_townSquare"},
}

function _buildHandItems(): {[string]: {validDropZones: {string}}}
	local items: {[string]: {validDropZones: {string}}} = {}
	for _, item in ipairs(_hand) do
		local zones = (item.targetVariable and ZONE_BY_TARGET[item.targetVariable]) or ALL_ZONES
		items[item.id] = { validDropZones = zones }
	end
	return items
end

local function _makeSlot(index: number): Frame
	local BASE = CargoUIConfig.BASE_SLOT_SIZE
	local slot = Instance.new("Frame")
	slot.Name = "Slot_" .. index
	slot.Size = UDim2.new(0, BASE, 0, BASE)
	slot.BackgroundColor3 = CargoUIConfig.COLOR_SLOT_EMPTY
	slot.BackgroundTransparency = 0.10; slot.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10); corner.Parent = slot
	local border = Instance.new("UIStroke")
	border.Name = "Border"; border.Thickness = 2
	border.Color = CargoUIConfig.COLOR_INACTIVE_BORDER; border.Parent = slot
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"; nameLabel.Size = UDim2.new(1, -6, 0.45, 0)
	nameLabel.Position = UDim2.new(0, 3, 0.52, 0); nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = CargoUIConfig.COLOR_TEXT_PRIMARY
	nameLabel.TextSize = 11; nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true; nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Text = ""; nameLabel.Visible = false; nameLabel.Parent = slot
	local catLabel = Instance.new("TextLabel")
	catLabel.Name = "CategoryLabel"; catLabel.Size = UDim2.new(1, -4, 0.30, 0)
	catLabel.Position = UDim2.new(0, 2, 0.08, 0); catLabel.BackgroundTransparency = 1
	catLabel.TextColor3 = CargoUIConfig.COLOR_TEXT_SECONDARY
	catLabel.TextSize = 9; catLabel.Font = Enum.Font.Gotham
	catLabel.TextXAlignment = Enum.TextXAlignment.Center
	catLabel.TextTruncate = Enum.TextTruncate.AtEnd
	catLabel.Text = ""; catLabel.Visible = false; catLabel.Parent = slot
	local placeholder = Instance.new("TextLabel")
	placeholder.Name = "Placeholder"; placeholder.Size = UDim2.new(1, 0, 1, 0)
	placeholder.BackgroundTransparency = 1
	placeholder.TextColor3 = CargoUIConfig.COLOR_TEXT_SECONDARY
	placeholder.TextSize = 22; placeholder.Font = Enum.Font.Gotham
	placeholder.Text = "·"; placeholder.Visible = true; placeholder.Parent = slot
	local button = Instance.new("TextButton")
	button.Name = "TapButton"; button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1; button.Text = ""; button.ZIndex = 2
	button.Parent = slot
	button.Activated:Connect(function()
		local item = _hand[index]
		if not item then return end
		if item.id == _activeItemId then return end
		_activeItemId = item.id
		if _InputController then _InputController.SetActiveCargoId(item.id) end
		_refreshActiveSlot()
	end)
	return slot
end

local function _buildGui()
	local BASE = CargoUIConfig.BASE_SLOT_SIZE
	local GAP  = CargoUIConfig.SLOT_GAP
	local FRAC = CargoUIConfig.TRAY_HEIGHT_FRACTION
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CargoUIGui"; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false; screenGui.Parent = _localPlayer.PlayerGui
	local trayFrame = Instance.new("Frame")
	trayFrame.Name = "TrayFrame"
	trayFrame.Size = UDim2.new(1, 0, FRAC, 0)
	trayFrame.Position = UDim2.new(0, 0, 1 - FRAC, 0)
	trayFrame.BackgroundColor3 = CargoUIConfig.COLOR_TRAY_BG
	trayFrame.BackgroundTransparency = 0.35; trayFrame.BorderSizePixel = 0
	trayFrame.Parent = screenGui
	local gaugeFrame = Instance.new("Frame")
	gaugeFrame.Name = "ConditionGauge"
	gaugeFrame.Size = UDim2.new(0, 0, 1, 0); gaugeFrame.Position = UDim2.new(0, 0, 0, 0)
	gaugeFrame.BackgroundColor3 = CargoUIConfig.COLOR_GAUGE_HEALTHY
	gaugeFrame.BorderSizePixel = 0; gaugeFrame.Visible = false; gaugeFrame.Parent = trayFrame
	local totalSlotWidth = BASE * 3 + GAP * 2
	local slotContainer = Instance.new("Frame")
	slotContainer.Name = "SlotContainer"
	slotContainer.Size = UDim2.new(0, totalSlotWidth, 0, BASE)
	slotContainer.Position = UDim2.new(0.5, -(totalSlotWidth // 2), 0, CargoUIConfig.TRAY_PADDING_TOP)
	slotContainer.BackgroundTransparency = 1; slotContainer.Parent = trayFrame
	local poolLabel = Instance.new("TextLabel")
	poolLabel.Name = "PoolLabel"
	poolLabel.Size = UDim2.new(1, 0, 0, CargoUIConfig.POOL_LABEL_HEIGHT)
	poolLabel.Position = UDim2.new(0, 0, 1, -(CargoUIConfig.POOL_LABEL_HEIGHT + 4))
	poolLabel.BackgroundTransparency = 1
	poolLabel.TextColor3 = CargoUIConfig.COLOR_TEXT_SECONDARY
	poolLabel.TextSize = 12; poolLabel.Font = Enum.Font.Gotham
	poolLabel.TextXAlignment = Enum.TextXAlignment.Center
	poolLabel.Text = "0 items left"; poolLabel.Parent = trayFrame
	_slotFrames = {}
	for i = 1, 3 do
		local slot = _makeSlot(i)
		slot.Position = UDim2.new(0, (i-1)*(BASE+GAP), 0, 0)
		slot.Parent = slotContainer; _slotFrames[i] = slot
	end
	_gui = screenGui
end

function _refreshActiveSlot()
	local BASE = CargoUIConfig.BASE_SLOT_SIZE
	local ACTIVE_SIZE = math.floor(BASE * CargoUIConfig.ACTIVE_SLOT_SCALE)
	local ti = TweenInfo.new(CargoUIConfig.SELECTION_SCALE_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	for i, sf in ipairs(_slotFrames) do
		local item = _hand[i]
		local isActive = item ~= nil and item.id == _activeItemId
		local sz = isActive and ACTIVE_SIZE or BASE
		local bg = isActive and CargoUIConfig.COLOR_SLOT_ACTIVE
			or (item ~= nil and CargoUIConfig.COLOR_SLOT_OCCUPIED or CargoUIConfig.COLOR_SLOT_EMPTY)
		TweenService:Create(sf, ti, { Size = UDim2.new(0, sz, 0, sz), BackgroundColor3 = bg }):Play()
		local border = sf:FindFirstChild("Border") :: UIStroke
		if border then
			TweenService:Create(border, ti, {
				Color = isActive and CargoUIConfig.COLOR_ACTIVE_BORDER or CargoUIConfig.COLOR_INACTIVE_BORDER
			}):Play()
		end
	end
end

local function _rebuildTray()
	for i, sf in ipairs(_slotFrames) do
		local item = _hand[i]
		local nl = sf:FindFirstChild("NameLabel") :: TextLabel
		local cl = sf:FindFirstChild("CategoryLabel") :: TextLabel
		local ph = sf:FindFirstChild("Placeholder") :: TextLabel
		sf.BackgroundTransparency = 0.10
		if nl then nl.TextTransparency = 0 end
		if item then
			sf.BackgroundColor3 = CargoUIConfig.COLOR_SLOT_OCCUPIED
			if nl then nl.Text = item.displayName or item.id; nl.Visible = true end
			if cl then cl.Text = item.targetVariable or ""; cl.Visible = item.targetVariable ~= nil end
			if ph then ph.Visible = false end
		else
			sf.BackgroundColor3 = CargoUIConfig.COLOR_SLOT_EMPTY; sf.BackgroundTransparency = 0.25
			if nl then nl.Text = ""; nl.Visible = false end
			if cl then cl.Text = ""; cl.Visible = false end
			if ph then ph.Visible = true end
		end
	end
	local tf = _gui and _gui:FindFirstChild("TrayFrame")
	local pl = tf and tf:FindFirstChild("PoolLabel") :: TextLabel
	if pl then
		local n = _poolCount
		pl.Text = n == 1 and "1 item left" or (n .. " items left")
	end
	_refreshActiveSlot()
end

local function _onHandChanged(hand, poolCount)
	_hand = hand or {}; _poolCount = poolCount or 0
	local activePresent = false
	for _, item in ipairs(_hand) do
		if item.id == _activeItemId then activePresent = true; break end
	end
	if not activePresent then
		if #_hand > 0 then
			_activeItemId = _hand[1].id
			if _InputController then _InputController.SetActiveCargoId(_activeItemId) end
		else
			_activeItemId = nil
			if _InputController then _InputController.SetActiveCargoId(nil) end
		end
	end
	_rebuildTray()
	if _InputController and _InputController.SetHandItems then
		_InputController.SetHandItems(_buildHandItems())
	end
end

local function _onItemDiscarded(itemId)
	for i, sf in ipairs(_slotFrames) do
		local item = _hand[i]
		if item and item.id == itemId then
			local ti = TweenInfo.new(CargoUIConfig.DISCARD_ANIM_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			TweenService:Create(sf, ti, { BackgroundTransparency = 1, Position = sf.Position + UDim2.new(0,0,0,28) }):Play()
			local nl = sf:FindFirstChild("NameLabel") :: TextLabel
			if nl then TweenService:Create(nl, ti, { TextTransparency = 1 }):Play() end
			break
		end
	end
end

local function _onPoolExhausted()
	if not _gui then return end
	local tf = _gui:FindFirstChild("TrayFrame") :: Frame
	if not tf then return end
	TweenService:Create(tf, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

_buildGui()
if _reHandChanged   then _reHandChanged.OnClientEvent:Connect(_onHandChanged)    end
if _reItemDiscarded then _reItemDiscarded.OnClientEvent:Connect(_onItemDiscarded) end
if _rePoolExhausted then _rePoolExhausted.OnClientEvent:Connect(_onPoolExhausted) end

CargoUI._test = {
	getHand         = function() return _hand         end,
	getPoolCount    = function() return _poolCount     end,
	getActiveItemId = function() return _activeItemId  end,
	getGui          = function() return _gui           end,
	getSlotFrames   = function() return _slotFrames    end,
}
return CargoUI
