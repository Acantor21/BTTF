-- DropConfig
-- Tuning constants for the Drop Mechanic.
-- Shared between server and client.
-- Studio path: ReplicatedStorage.Config.DropConfig
-- Sprint: 002 | System: Drop Mechanic | GDD: design/gdd/drop-mechanic.md

local DropConfig = {}

DropConfig.ARC_HEIGHT           = 8
DropConfig.BASE_ARC_DURATION    = 0.45
DropConfig.ARC_DISTANCE_FACTOR  = 0.008
DropConfig.ARC_MAX_DURATION     = 0.8

DropConfig.ZONE_SNAP_MAX_DISTANCE = 12

DropConfig.BASE_VFX_SCALE        = 1.0
DropConfig.VFX_DELTA_MULTIPLIER  = 0.3

DropConfig.RIPPLE_DELAY    = 0.0
DropConfig.RIPPLE_DURATION = 1.0

DropConfig.PARK_VFX_DURATION = 3.2
DropConfig.PARK_BEATS = {
	{ name = "drive_start",     t = 0.0 },
	{ name = "brake_screech",   t = 1.2 },
	{ name = "hard_stop",       t = 2.0 },
	{ name = "flux_flash",      t = 2.5 },
	{ name = "engine_winddown", t = 3.2 },
}

DropConfig.ERA_BLASTOFF_DURATION = 5.0
DropConfig.BLASTOFF_BEATS = {
	{ name = "accelerate",         t = 0.0 },
	{ name = "flux_charge",        t = 1.5 },
	{ name = "vertical_launch",    t = 2.0 },
	{ name = "era_blend_complete", t = 3.5 },
	{ name = "reentry_begin",      t = 4.0 },
	{ name = "reentry_land",       t = 5.0 },
}

DropConfig.BASE_DEGRADATION    = 16.0
DropConfig.STABILITY_PENALTY   = {
	[3] = 0.0,
	[2] = 2.0,
	[1] = 5.0,
	[0] = 10.0,
}
DropConfig.WARNING_THRESHOLD   = 30.0
DropConfig.CRITICAL_THRESHOLD  = 10.0

DropConfig.REMOTE_COMMIT_DROP      = "DropMechanic_CommitDrop"
DropConfig.REMOTE_DROP_ACK         = "DropMechanic_DropAck"
DropConfig.REMOTE_DROP_REJECT      = "DropMechanic_DropReject"
DropConfig.REMOTE_PARK_TRIGGER     = "DropMechanic_ParkTrigger"
DropConfig.REMOTE_CONDITION_UPDATE = "DropMechanic_ConditionUpdate"

DropConfig.RIPPLE_INITIAL_SIZE  = 1.5
DropConfig.RIPPLE_MAX_SIZE      = 18
DropConfig.RIPPLE_THICKNESS     = 0.25
DropConfig.RIPPLE_COLOR         = Color3.fromRGB(180, 145, 255)

DropConfig.LANDING_BURST_COUNT    = 15
DropConfig.LANDING_BURST_SPEED    = 8
DropConfig.LANDING_BURST_LIFETIME = 0.55
DropConfig.LANDING_BURST_COLOR    = Color3.fromRGB(200, 165, 255)

return DropConfig
