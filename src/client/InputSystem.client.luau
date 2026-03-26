-- InputSystem (entry point)
-- Boots the InputController on the client.
-- Studio path: StarterPlayer.StarterPlayerScripts.InputSystem
-- Sprint: 001 | System: Input System

local InputController = require(script.Parent.InputController)

-- InputController self-initializes on require (all event connections are made there).
-- This script's role is to ensure the module is loaded at game start.
-- Other client systems should require InputController directly to connect to its events.

print("[InputSystem] Initialized. State:", InputController.GetState())
