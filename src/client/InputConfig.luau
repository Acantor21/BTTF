-- InputConfig
-- All tuning constants for the Input System.
-- Studio path: StarterPlayer.StarterPlayerScripts.InputConfig
-- Sprint: 001 | System: Input System | GDD: design/gdd/input-system.md

local InputConfig = {}

-- Orbit
InputConfig.ORBIT_SENSITIVITY   = 0.006   -- rad/px. Validated in diorama prototype.
-- Zoom
InputConfig.ZOOM_SENSITIVITY    = 0.5     -- studs/px
InputConfig.ZOOM_MIN            = 60      -- studs (closest camera can get)
InputConfig.ZOOM_MAX            = 120     -- studs (furthest camera can get)
-- Gyroscope
InputConfig.GYRO_SENSITIVITY    = 0.0015  -- rad/(rad/s). Keep at ≤25% of ORBIT_SENSITIVITY.
-- Drop hold
InputConfig.DROP_HOLD_THRESHOLD = 0.15    -- seconds. Misfire prevention window.
-- ParkCommit double-tap
InputConfig.DOUBLE_TAP_THRESHOLD = 0.35   -- seconds between two taps
InputConfig.DOUBLE_TAP_RADIUS    = 40     -- pixels. Second tap must be within this distance.
-- DiscardItem swipe-down
InputConfig.DISCARD_SWIPE_MIN_DIST = 60   -- pixels downward before DiscardItem fires
-- Cargo UI zone (bottom fraction of screen). DiscardItem gestures must begin here.
InputConfig.CARGO_UI_HEIGHT_FRACTION = 0.20
-- Diorama hitbox tag (CollectionService tag on diorama surface parts)
InputConfig.DIORAMA_TAG   = "DioramaSurface"
InputConfig.DELOREAN_TAG  = "DeLorean"

return InputConfig
