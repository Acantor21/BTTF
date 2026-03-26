-- InputController
-- Platform-agnostic input translation layer for Hill Valley.
-- Converts raw device input into a fixed 11-action vocabulary.
-- Client only — never require from server.
-- Studio path: StarterPlayer.StarterPlayerScripts.InputController
-- Sprint: 001 | System: Input System | GDD: design/gdd/input-system.md
--
-- Events (connect to these from other client systems):
--   OrbitDelta      -> fires({dx: number, dy: number})
--   ZoomDelta       -> fires({delta: number})
--   TiltDelta       -> fires({pitch: number, roll: number})
--   CargoSelect     -> fires({cargoId: string})
--   DropHover       -> fires(worldPos: Vector3)  [continuous while hovering]
--   DropCommit      -> fires(worldPos: Vector3)
--   DropCancel      -> fires()
--   MartyTap        -> fires({npcId: string})
--   TimelineScrub   -> fires({t: number})  [0.0–1.0]
--   ParkCommit      -> fires()
--   DiscardItem     -> fires({cargoId: string})
--
-- Control (call these from external systems):
--   LockInput()     -> nil
--   UnlockInput()   -> nil
--   SetActiveCargoId(cargoId: string | nil) -> nil  (Cargo UI calls this on CargoSelect)
--   SetHandItems(items) -> nil
--   GetHandItems()  -> {[string]: {validDropZones: {string}}}
--   GetActiveItemId() -> string?

local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local InputConfig = require(script.Parent.InputConfig)

-- ─── State machine ────────────────────────────────────────────────────────────

local STATE_IDLE       = "Idle"
local STATE_CARGO_HELD = "CargoHeld"
local STATE_LOCKED     = "Locked"

local _state        = STATE_IDLE
local _activeCargoId: string? = nil

-- ─── BindableEvents ───────────────────────────────────────────────────────────

local function _makeEvent(name: string): BindableEvent
	local be = Instance.new("BindableEvent")
	be.Name = name
	be.Parent = script
	return be
end

local _beOrbitDelta    = _makeEvent("OrbitDelta")
local _beZoomDelta     = _makeEvent("ZoomDelta")
local _beTiltDelta     = _makeEvent("TiltDelta")
local _beCargoSelect   = _makeEvent("CargoSelect")
local _beDropHover     = _makeEvent("DropHover")
local _beDropCommit    = _makeEvent("DropCommit")
local _beDropCancel    = _makeEvent("DropCancel")
local _beMartyTap      = _makeEvent("MartyTap")
local _beTimelineScrub = _makeEvent("TimelineScrub")
local _beParkCommit    = _makeEvent("ParkCommit")
local _beDiscardItem   = _makeEvent("DiscardItem")

-- ─── Gyroscope availability ───────────────────────────────────────────────────

local _gyroAvailable = UserInputService.GyroscopeEnabled

-- ─── Touch tracking ───────────────────────────────────────────────────────────

local _activeTouches: {[InputObject]: boolean} = {}
local _touchCount = 0
local _primaryTouch: InputObject? = nil
local _prevTouchPos: Vector2 = Vector2.zero

-- Drop hold state
local _dropHoldThread: thread? = nil
local _dropHoverActive = false
local _dropHoldStartPos: Vector2 = Vector2.zero

-- Double-tap tracking for ParkCommit
local _lastTapTime = 0
local _lastTapPos: Vector2 = Vector2.zero

-- Mouse orbit tracking
local _mouseOrbitActive = false
local _prevMousePos: Vector2 = Vector2.zero

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function _isInCargoZone(screenPos: Vector2): boolean
	local viewportY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
	return screenPos.Y > viewportY * (1 - InputConfig.CARGO_UI_HEIGHT_FRACTION)
end

local function _hitDiorama(screenPos: Vector2): (boolean, Vector3?)
	local camera = workspace.CurrentCamera
	if not camera then return false, nil end
	local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	local dioramaParts = CollectionService:GetTagged(InputConfig.DIORAMA_TAG)
	if #dioramaParts > 0 then
		params.FilterDescendantsInstances = dioramaParts
		params.FilterType = Enum.RaycastFilterType.Include
	end
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params)
	return result ~= nil, result and result.Position or nil
end

local function _hitsDeLorean(screenPos: Vector2): boolean
	local camera = workspace.CurrentCamera
	if not camera then return false end
	local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	local deloreanParts = CollectionService:GetTagged(InputConfig.DELOREAN_TAG)
	if #deloreanParts == 0 then return false end
	params.FilterDescendantsInstances = deloreanParts
	params.FilterType = Enum.RaycastFilterType.Include
	return workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, params) ~= nil
end

local function _cancelDropHoldTimer()
	if _dropHoldThread then
		task.cancel(_dropHoldThread)
		_dropHoldThread = nil
	end
end

local function _cancelDropGesture()
	_cancelDropHoldTimer()
	if _dropHoverActive then
		_dropHoverActive = false
		_beDropCancel:Fire()
	end
end

local function _goIdle()
	_cancelDropGesture()
	_state = STATE_IDLE
end

-- ─── External control ─────────────────────────────────────────────────────────

local InputController = {}

InputController.OrbitDelta    = _beOrbitDelta.Event
InputController.ZoomDelta     = _beZoomDelta.Event
InputController.TiltDelta     = _beTiltDelta.Event
InputController.CargoSelect   = _beCargoSelect.Event
InputController.DropHover     = _beDropHover.Event
InputController.DropCommit    = _beDropCommit.Event
InputController.DropCancel    = _beDropCancel.Event
InputController.MartyTap      = _beMartyTap.Event
InputController.TimelineScrub = _beTimelineScrub.Event
InputController.ParkCommit    = _beParkCommit.Event
InputController.DiscardItem   = _beDiscardItem.Event

function InputController.LockInput()
	if _state == STATE_CARGO_HELD then
		_cancelDropGesture()
		_beDropCancel:Fire()
	end
	_cancelDropHoldTimer()
	_dropHoverActive = false
	_mouseOrbitActive = false
	_primaryTouch = nil
	_state = STATE_LOCKED
end

function InputController.UnlockInput()
	_state = STATE_IDLE
end

function InputController.SetActiveCargoId(cargoId: string?)
	_activeCargoId = cargoId
	if cargoId ~= nil then
		_state = STATE_CARGO_HELD
	else
		_goIdle()
	end
end

function InputController.GetState(): string
	return _state
end

-- ─── Touch input ──────────────────────────────────────────────────────────────

local function _startDropHoldTimer(touchPos: Vector2)
	_dropHoldStartPos = touchPos
	_dropHoldThread = task.delay(InputConfig.DROP_HOLD_THRESHOLD, function()
		_dropHoldThread = nil
		if _state ~= STATE_CARGO_HELD then return end
		local hitDiorama, worldPos = _hitDiorama(touchPos)
		if hitDiorama and worldPos then
			_dropHoverActive = true
			_beDropHover:Fire(worldPos)
		end
	end)
end

UserInputService.TouchStarted:Connect(function(touch: InputObject, _gameProcessed: boolean)
	if _state == STATE_LOCKED then return end
	_activeTouches[touch] = true
	_touchCount = _touchCount + 1
	if _touchCount == 2 and _primaryTouch ~= nil then
		_cancelDropGesture()
		_primaryTouch = nil
	end
	if _touchCount > 1 then return end
	_primaryTouch = touch
	_prevTouchPos = touch.Position
	local screenPos = Vector2.new(touch.Position.X, touch.Position.Y)
	if _isInCargoZone(screenPos) and not _dropHoverActive then return end
	if _state == STATE_CARGO_HELD and not _dropHoverActive then
		local hitDiorama, _ = _hitDiorama(screenPos)
		if hitDiorama then _startDropHoldTimer(screenPos) end
	end
end)

UserInputService.TouchMoved:Connect(function(touch: InputObject, _gameProcessed: boolean)
	if _state == STATE_LOCKED then return end
	if not _activeTouches[touch] then return end
	if _touchCount > 1 then return end
	local screenPos = Vector2.new(touch.Position.X, touch.Position.Y)
	local dx = screenPos.X - _prevTouchPos.X
	local dy = screenPos.Y - _prevTouchPos.Y
	_prevTouchPos = screenPos
	if _isInCargoZone(screenPos) and not _dropHoverActive then
		if dy >= InputConfig.DISCARD_SWIPE_MIN_DIST and _activeCargoId ~= nil then
			_beDiscardItem:Fire({ cargoId = _activeCargoId })
			_goIdle()
		end
		return
	end
	if _state == STATE_CARGO_HELD then
		local moveDist = math.sqrt(dx*dx + dy*dy)
		if _dropHoldThread ~= nil and moveDist > 8 then
			_cancelDropHoldTimer()
			_beDropCancel:Fire()
			_beOrbitDelta:Fire({ dx = dx, dy = dy })
			return
		end
		if _dropHoverActive then
			local hitDiorama, worldPos = _hitDiorama(screenPos)
			if hitDiorama and worldPos then
				_beDropHover:Fire(worldPos)
			else
				_dropHoverActive = false
				_beDropCancel:Fire()
			end
		end
		return
	end
	if _state == STATE_IDLE then
		_beOrbitDelta:Fire({ dx = dx, dy = dy })
	end
end)

UserInputService.TouchEnded:Connect(function(touch: InputObject, _gameProcessed: boolean)
	_activeTouches[touch] = nil
	_touchCount = math.max(0, _touchCount - 1)
	if touch ~= _primaryTouch then return end
	_primaryTouch = nil
	if _state == STATE_LOCKED then return end
	local screenPos = Vector2.new(touch.Position.X, touch.Position.Y)
	if _hitsDeLorean(screenPos) then
		local now = tick()
		local dist = (screenPos - _lastTapPos).Magnitude
		if now - _lastTapTime <= InputConfig.DOUBLE_TAP_THRESHOLD and dist <= InputConfig.DOUBLE_TAP_RADIUS then
			_beParkCommit:Fire()
			_lastTapTime = 0
		else
			_lastTapTime = now
			_lastTapPos = screenPos
		end
		_cancelDropGesture()
		return
	end
	if _state == STATE_CARGO_HELD then
		_cancelDropHoldTimer()
		if _dropHoverActive then
			_dropHoverActive = false
			local hitDiorama, worldPos = _hitDiorama(screenPos)
			if hitDiorama and worldPos and _activeCargoId ~= nil then
				_beDropCommit:Fire(worldPos)
			else
				_beDropCancel:Fire()
			end
		end
		return
	end
end)

UserInputService.TouchPinch:Connect(function(_touchPositions: {Vector2}, _scale: number, _velocity: number, state: Enum.UserInputState, _gameProcessed: boolean)
	if _state == STATE_LOCKED then return end
	if state ~= Enum.UserInputState.Change then return end
	_beZoomDelta:Fire({ delta = _velocity })
end)

-- ─── Mouse input ──────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
	if _state == STATE_LOCKED then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		_mouseOrbitActive = true
		_prevMousePos = Vector2.new(input.Position.X, input.Position.Y)
		local screenPos = _prevMousePos
		if _state == STATE_CARGO_HELD and not _dropHoverActive then
			local hitDiorama, _ = _hitDiorama(screenPos)
			if hitDiorama then _startDropHoldTimer(screenPos) end
		end
	end
end)

UserInputService.InputChanged:Connect(function(input: InputObject, _gameProcessed: boolean)
	if _state == STATE_LOCKED then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local screenPos = Vector2.new(input.Position.X, input.Position.Y)
		local dx = screenPos.X - _prevMousePos.X
		local dy = screenPos.Y - _prevMousePos.Y
		_prevMousePos = screenPos
		if not _mouseOrbitActive then return end
		if _state == STATE_CARGO_HELD then
			local moveDist = math.sqrt(dx*dx + dy*dy)
			if _dropHoldThread ~= nil and moveDist > 8 then
				_cancelDropHoldTimer()
				_beDropCancel:Fire()
				_beOrbitDelta:Fire({ dx = dx, dy = dy })
				return
			end
			if _dropHoverActive then
				local hitDiorama, worldPos = _hitDiorama(screenPos)
				if hitDiorama and worldPos then
					_beDropHover:Fire(worldPos)
				else
					_dropHoverActive = false
					_beDropCancel:Fire()
				end
			end
			return
		end
		if _state == STATE_IDLE then
			_beOrbitDelta:Fire({ dx = dx, dy = dy })
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		_beZoomDelta:Fire({ delta = input.Position.Z })
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		_mouseOrbitActive = false
		if _state == STATE_LOCKED then return end
		local screenPos = _prevMousePos
		if _hitsDeLorean(screenPos) then
			local now = tick()
			local dist = (screenPos - _lastTapPos).Magnitude
			if now - _lastTapTime <= InputConfig.DOUBLE_TAP_THRESHOLD and dist <= InputConfig.DOUBLE_TAP_RADIUS then
				_beParkCommit:Fire()
				_lastTapTime = 0
			else
				_lastTapTime = now
				_lastTapPos = screenPos
			end
			_cancelDropGesture()
			return
		end
		if _state == STATE_CARGO_HELD then
			_cancelDropHoldTimer()
			if _dropHoverActive then
				_dropHoverActive = false
				local hitDiorama, worldPos = _hitDiorama(screenPos)
				if hitDiorama and worldPos and _activeCargoId ~= nil then
					_beDropCommit:Fire(worldPos)
				else
					_beDropCancel:Fire()
				end
			end
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		if _state == STATE_CARGO_HELD and _dropHoverActive then
			_dropHoverActive = false
			_cancelDropHoldTimer()
			_beDropCancel:Fire()
		end
	end
end)

-- ─── Gyroscope (optional) ────────────────────────────────────────────────────

if _gyroAvailable then
	UserInputService.DeviceRotationChanged:Connect(function(rotation: CFrame, _rotationalVelocity: Vector3)
		if _state == STATE_LOCKED then return end
		local _, _, roll  = rotation:ToEulerAnglesXYZ()
		local pitch, _, _ = rotation:ToEulerAnglesXYZ()
		local gyroYaw   = roll  * InputConfig.GYRO_SENSITIVITY
		local gyroPitch = pitch * InputConfig.GYRO_SENSITIVITY
		if math.abs(gyroYaw) > 0.0001 or math.abs(gyroPitch) > 0.0001 then
			_beTiltDelta:Fire({ pitch = gyroPitch, roll = gyroYaw })
		end
	end)
end

-- ─── Hand item registry ─────────────────────────────────────────────────────

local _handItems: {[string]: {validDropZones: {string}}} = {}

function InputController.SetHandItems(items: {[string]: {validDropZones: {string}}})
	_handItems = items or {}
end

function InputController.GetHandItems(): {[string]: {validDropZones: {string}}}
	return _handItems
end

function InputController.GetActiveItemId(): string?
	return _activeCargoId
end

return InputController
