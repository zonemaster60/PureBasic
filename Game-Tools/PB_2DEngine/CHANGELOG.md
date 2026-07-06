# Changelog

## Unreleased

- Hardened engine startup and shutdown so partial initialization failures return cleanly and only initialized subsystems are torn down.
- Fixed input binding behavior so built-in actions follow loaded JSON bindings and defaults remain available when configs only override some actions.
- Improved graphics lifecycle management by tracking window and screen state, handling partial init failures safely, and draining pending close events.
- Corrected Lua numeric bindings to use floating-point values, cleaned Lua stack handling during API registration and global calls, and improved script call safety.
- Simplified the Lua loader to bind only the LuaJIT functions the engine actually uses, reducing unnecessary init-time failure points.
- Added timing and logging safeguards, including fallback timers, log file open failure reporting, headless auto-exit coverage, negative frame delta clamping, and invalid FPS protection.
- Added stronger runtime guards across the engine: validated graphics dimensions, protected frame begin/end from invalid screen state, made audio/world/demo-scene init and shutdown idempotent, logged startup version/build mode, and capped runaway fixed-step catch-up work under stalls.
- Added a centralized engine shutdown path, richer input binding load diagnostics, Lua callback failure handling, and new Lua helpers for engine/time/math access.
- Replaced placeholder world rendering with a small moving-entity simulation and added a basic demo overlay showing engine state in the windowed build.
- Added mouse input state tracking, world entity spawn/query/control APIs, and Lua accessors so scripts can inspect and steer entities at runtime.
- Enabled smoke-test logging for windowed runs as well and throttled smoke rendering loops to keep automated verification predictable.
- Replaced placeholder subsystem `Debug` lifecycle messages with structured engine logs for `World` and `DemoScene`.
