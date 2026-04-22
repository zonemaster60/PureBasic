# Changelog

## Unreleased

- Hardened engine startup and shutdown so partial initialization failures return cleanly and only initialized subsystems are torn down.
- Fixed input binding behavior so built-in actions follow loaded JSON bindings and defaults remain available when configs only override some actions.
- Improved graphics lifecycle management by tracking window and screen state, handling partial init failures safely, and draining pending close events.
- Corrected Lua numeric bindings to use floating-point values, cleaned Lua stack handling during API registration and global calls, and improved script call safety.
- Simplified the Lua loader to bind only the LuaJIT functions the engine actually uses, reducing unnecessary init-time failure points.
- Added timing and logging safeguards, including fallback timers, log file open failure reporting, headless auto-exit coverage, negative frame delta clamping, and invalid FPS protection.
- Replaced placeholder subsystem `Debug` lifecycle messages with structured engine logs for `World` and `DemoScene`.
