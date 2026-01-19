# PB2DEngine (PureBasic) — Engine Manual (Planned v1)

This manual describes the *planned* PB2DEngine API and workflow for building complete 2D games in PureBasic 6.30.

- Target: Windows
- Rendering: `OpenWindowedScreen()` / PureBasic 2D sprite pipeline
- Data format: JSON for scenes, prefabs, and project config
- Scripting: LuaJIT (`lua51.dll`) with an engine API exposed to Lua

> Note
> The repository currently contains a v0.1 scaffold. This manual is a forward-looking specification and usage guide so the engine can be implemented consistently.

## 1. Concepts

### 1.1 Game Loop
- Fixed timestep update: gameplay/physics at a stable `dt` (default 1/60)
- Render interpolation: draw using `alpha` for smooth motion

### 1.2 Project Layout
A typical game project using the engine:

```
PB2DEngine/
  engine/              Engine runtime modules
  game/                Your game code and content
  assets/              Packed assets (images/sound/fonts)
  docs/                This manual
  build/               Compiled output
```

Suggested game content structure:

```
game/
  main.pb             Game entry glue or scene selection
  main.lua            Script entry (optional)
  scenes/
    boot.json
    level1.json
  prefabs/
    player.json
    enemy_slime.json
  scripts/
    player_controller.lua
  tilesets/
    dungeon.tsx.json  (engine-friendly tileset JSON)
```

### 1.3 Scenes, Entities, Components
- **Scene**: a collection of entities plus runtime systems and settings (camera, gravity, music)
- **Entity**: an integer id; it has zero or more components
- **Component**: a small data struct (Transform, SpriteRenderer, Collider, Script…)
- **System**: code that updates all entities with required components (PhysicsSystem, RenderSystem, ScriptSystem)

### 1.4 Coordinates
- World coordinates are floats (pixels in world space)
- Screen coordinates are ints (pixels on backbuffer)
- For pixel-art games, use **virtual resolution + scaling**

### 1.5 Asset IDs
Assets load through an `Asset` module and are referenced by string keys in JSON and Lua.

Example: `"sprites/player.png"`, `"sfx/jump.wav"`, `"music/level1.ogg"`.

---

## 2. Building and Running

### 2.1 Standard Build
- Compile `Main.pb` (or your game’s entry file).
- Ship `lua51.dll` next to the `.exe` if scripting is enabled.

### 2.2 Build Flags (Compile-Time Constants)
Planned compile-time constants (passed via `pbcompiler -co NAME=VALUE`):

- `SMOKE_TEST=1`: runs for ~2 seconds then exits (CI)
- `HEADLESS=1`: no window/no rendering (CI). Writes `smoke.log` next to the exe
- `DEVTOOLS=1`: enables hot-reload and debug UI

### 2.3 Runtime Config
Planned JSON file: `game/config.json`

```json
{
  "window": {"width": 1280, "height": 720, "resizable": true},
  "render": {"virtualWidth": 640, "virtualHeight": 360, "scaleMode": "fit"},
  "audio": {"master": 1.0, "music": 0.8, "sfx": 1.0},
  "entryScene": "scenes/boot.json"
}
```

---

## 3. JSON Content

### 3.1 Scene JSON (Planned)
A scene declares:
- scene settings (gravity, background color)
- camera settings
- list of entities with components

```json
{
  "name": "level1",
  "settings": {
    "gravity": [0, 1200],
    "clearColor": [20, 20, 24]
  },
  "camera": {
    "mode": "follow",
    "target": "@player",
    "zoom": 1.0
  },
  "entities": [
    {
      "id": "@player",
      "components": {
        "Transform": {"pos": [120, 220]},
        "SpriteRenderer": {"texture": "sprites/player.png", "origin": [16, 16], "layer": 10},
        "Animator": {"controller": "anim/player.json"},
        "Collider": {"type": "aabb", "size": [20, 28], "offset": [0, 2], "isTrigger": false},
        "Rigidbody": {"body": "dynamic", "mass": 1.0},
        "Script": {"file": "scripts/player_controller.lua"}
      }
    }
  ]
}
```

### 3.2 Prefab JSON (Planned)
Prefabs define reusable entities. Scenes can instantiate prefabs.

```json
{
  "name": "enemy_slime",
  "components": {
    "Transform": {"pos": [0, 0]},
    "SpriteRenderer": {"texture": "sprites/slime.png", "layer": 10},
    "Collider": {"type": "aabb", "size": [18, 14]},
    "Script": {"file": "scripts/slime_ai.lua"}
  }
}
```

### 3.3 Animation Controller (Planned)
```json
{
  "spritesheet": "sprites/player_sheet.png",
  "frameSize": [32, 32],
  "animations": {
    "idle": {"frames": [0,1,2,3], "fps": 8, "loop": true},
    "run":  {"frames": [8,9,10,11,12,13], "fps": 12, "loop": true}
  }
}
```

---

## 4. Core Engine Modules (Planned)

### 4.1 `Core`
Responsibilities:
- main loop, fixed timestep, event pump
- logging, assertions, profiling markers

### 4.2 `World`
Responsibilities:
- scene load/unload
- entity creation/destruction
- component storage

### 4.3 `Renderer2D`
Responsibilities:
- camera transform + culling
- sprite sorting by (layer, ySort, texture)
- optional virtual resolution scaling

### 4.4 `Input`
Action mapping:
- map key/gamepad/mouse to named actions
- edge states: pressed/released/held

### 4.5 `Audio`
- buses: Master/Music/SFX/UI
- `AudioSource` component (entity-attached)
- streaming music (if supported), otherwise looped sound

### 4.6 `Physics2D`
Two modes:
- **Platformer mode**: gravity + collision resolution against tilemap
- **Top-down mode**: no gravity; slide collisions; optional y-sort

Physics primitives:
- AABB
- tilemap colliders
- triggers

### 4.7 `Scripting (LuaJIT)`
- per-entity scripts with callbacks
- engine API accessible from Lua

---

## 5. Lua Scripting (Planned)

### 5.1 Script Lifecycle
Each script can implement:
- `OnCreate(self)`
- `OnUpdate(self, dt)`
- `OnFixedUpdate(self, dt)` (optional)
- `OnDestroy(self)`
- `OnCollisionEnter(self, other)` / `OnTriggerEnter(self, other)`

### 5.2 Example: Player Controller (Platformer)
```lua
function OnCreate(self)
  self.speed = 220
  self.jumpVelocity = -520
end

function OnUpdate(self, dt)
  local move = 0
  if Input.Down("left") then move = move - 1 end
  if Input.Down("right") then move = move + 1 end

  local vx, vy = Rigidbody.GetVelocity(self.entity)
  Rigidbody.SetVelocity(self.entity, move * self.speed, vy)

  if Input.Pressed("jump") and Rigidbody.IsGrounded(self.entity) then
    Rigidbody.SetVelocity(self.entity, vx, self.jumpVelocity)
    Audio.Play("sfx/jump.wav")
  end
end
```

### 5.3 Example: Top-down Movement
```lua
function OnUpdate(self, dt)
  local x, y = 0, 0
  if Input.Down("left") then x = x - 1 end
  if Input.Down("right") then x = x + 1 end
  if Input.Down("up") then y = y - 1 end
  if Input.Down("down") then y = y + 1 end

  local nx, ny = Math.Normalize(x, y)
  Transform.Translate(self.entity, nx * 160 * dt, ny * 160 * dt)
end
```

---

## 6. “Build a Complete Game” Checklist

### 6.1 Minimal Game (No Editor)
1. Create `game/config.json` (window, entryScene)
2. Create `game/scenes/boot.json` and/or `level1.json`
3. Create prefabs (`game/prefabs/player.json`, enemies)
4. Add assets in `assets/` (sprites/sfx/music)
5. Add scripts in `game/scripts/`
6. Compile and ship `lua51.dll` + `assets/` + `game/`

### 6.2 Shipping
- Use `Asset` packer (planned) to bundle assets
- Disable `DEVTOOLS`
- Validate headless smoke test in CI

---

## 7. Roadmap (Suggested Implementation Order)
1. Renderer2D + Camera + SpriteRenderer component
2. Asset manager (textures/sounds/fonts) + hot reload in dev
3. Input action mapping config
4. Scene JSON loader + prefab instancing
5. Lua bindings for Transform/Input/Audio + per-entity scripts
6. Collision + tilemap + platformer/topdown physics modes
7. Animator + sprite sheets
8. UI module + debug overlay
9. Build/packaging tooling
