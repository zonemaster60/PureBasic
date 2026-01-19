# PB2DEngine — Build & Release (Planned v1)

This guide covers typical build commands and what to ship.

---

## 1. Developer Build

- Compile the game entry `.pb` file.
- Ensure assets are present beside the exe.

Suggested output:
- `build/MyGame.exe`

---

## 2. Compile-Time Flags
Passed via `pbcompiler -co`.

- `DEVTOOLS=1`
  - Enable hot reload (assets/scripts)
  - Enable debug overlay
- `SMOKE_TEST=1`
  - Auto-exit after ~2 seconds
- `HEADLESS=1`
  - No graphics init and no rendering
  - Writes `smoke.log` next to the exe for CI

Example:

```text
pbcompiler.exe Main.pb -co HEADLESS=1 -co SMOKE_TEST=1 -o build\\MyGame_smoke.exe
```

---

## 3. What To Ship

Minimum files in your release folder:
- `MyGame.exe`
- `lua51.dll` (LuaJIT) if scripting is enabled
- `assets/` (or a packed `assets.pak` once implemented)
- `game/` JSON (scenes/prefabs/scripts) unless packed

---

## 4. CI Smoke Test

Goal: verify that the game boots, initializes systems, loads entry scene, runs the loop, then exits.

- Build headless smoke exe
- Run it
- Verify `smoke.log` exists and contains:
  - engine start
  - scene load
  - at least one heartbeat line

---

## 5. Asset Packaging (Planned)

Two modes:
- Loose files (fast iteration)
- Packed files (release)

Planned tool:
- `tools/pack_assets.pb` → outputs `assets.pak` + index
