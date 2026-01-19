# PB2DEngine — Final Lua Scripting API (v1 Spec)

This document defines the **final** Lua API for PB2DEngine v1.

Design goals:
- Small, consistent surface area
- Works for **platformer** and **top-down** games
- Avoids “magic globals”; uses modules (tables)
- Minimal allocations in hot paths
- Predictable naming: `GetX/SetX`, `IsX`, `Play`, `Load`

Lua version target:
- LuaJIT (Lua 5.1 semantics)

---

## 0. Conventions

### 0.1 Entity IDs
- Entities are numbers.
- Scenes may reference entities by string ids (e.g. `"@player"`) in JSON, but **Lua receives numeric ids**.

### 0.2 Vectors
To reduce allocations, most APIs use **numbers**, not tables.

- Positions and velocities are `(x, y)` numbers.

### 0.3 Time
- `dt` is seconds (float).

### 0.4 Error Handling
- Engine functions generally return `nil`/`false` on failure.
- In `DEVTOOLS`, errors will also log stack traces.

---

## 1. Script Lifecycle

A script file attached to an entity may define any of these functions:

### `function OnCreate(self)`
Called once when the script component is created.

### `function OnUpdate(self, dt)`
Called once per rendered frame.

### `function OnFixedUpdate(self, dt)`
Called at the fixed timestep (default 1/60). Use for physics.

### `function OnDestroy(self)`
Called when the entity is destroyed or scene unloads.

### Collision / Trigger callbacks

#### `function OnCollisionEnter(self, other)`
#### `function OnCollisionStay(self, other)`
#### `function OnCollisionExit(self, other)`

#### `function OnTriggerEnter(self, other)`
#### `function OnTriggerStay(self, other)`
#### `function OnTriggerExit(self, other)`

Where `other` is an entity id.

### `self` object
`self` is a table created by the engine:
- `self.entity` (number) entity id
- `self.name` (string|nil) optional name (e.g. "@player")
- `self.scene` (number) active scene id

You may add your own fields to `self`.

---

## 2. Global Modules

The engine exposes these globals:
- `Log`
- `Input`
- `Math`
- `Time`
- `World`
- `Scene`
- `Entity`
- `Transform`
- `Sprite`
- `Animator`
- `Physics`
- `Rigidbody`
- `Collider`
- `Audio`
- `Camera`
- `UI` (optional)

---

## 3. Module Reference

## 3.1 `Log`

### `Log.Info(message)`
### `Log.Warn(message)`
### `Log.Error(message)`

- `message`: string
- returns: none

---

## 3.2 `Input`

Input uses **action names** defined in JSON bindings.

### `Input.Down(action)`
- returns `true/false`

### `Input.Pressed(action)`
- returns `true/false` (edge)

### `Input.Released(action)`
- returns `true/false` (edge)

### `Input.Axis(negativeAction, positiveAction)`
- returns a number in `[-1, 1]`

Example:
```lua
local x = Input.Axis("left", "right")
```

---

## 3.3 `Math`

### `Math.Clamp(x, min, max)`
### `Math.Lerp(a, b, t)`
### `Math.Sign(x)`

### `Math.Length(x, y)`
### `Math.Normalize(x, y)`
- returns `nx, ny`

### `Math.Distance(ax, ay, bx, by)`

---

## 3.4 `Time`

### `Time.Delta()`
- returns `dt` for the current frame

### `Time.FixedDelta()`
- returns fixed dt

### `Time.Now()`
- returns seconds since start

---

## 3.5 `World`

### `World.LoadScene(path)`
- returns `true/false`

### `World.ReloadScene()`
### `World.UnloadScene()`

### `World.InstantiatePrefab(path, x, y)`
- returns `entityId | nil`

### `World.Destroy(entity)`

---

## 3.6 `Scene`

### `Scene.Find(nameOrTag)`
- returns `entityId | nil`
- supports `"@player"` as a name

### `Scene.FindAll(tag)`
- returns array of entity ids

### `Scene.SetGravity(x, y)`

---

## 3.7 `Entity`

### `Entity.IsValid(entity)`
### `Entity.GetName(entity)`
### `Entity.SetName(entity, name)`

### `Entity.Has(entity, componentName)`
- `componentName` is a string: `"Transform"`, `"Rigidbody"`, ...

---

## 3.8 `Transform`

### `Transform.GetPosition(entity)` → `x, y`
### `Transform.SetPosition(entity, x, y)`

### `Transform.GetRotation(entity)` → `radians`
### `Transform.SetRotation(entity, radians)`

### `Transform.GetScale(entity)` → `sx, sy`
### `Transform.SetScale(entity, sx, sy)`

### `Transform.Translate(entity, dx, dy)`

---

## 3.9 `Sprite`

### `Sprite.SetTexture(entity, assetKey)`
### `Sprite.SetLayer(entity, layer)`
### `Sprite.SetTint(entity, r, g, b, a)`
### `Sprite.SetFlip(entity, flipX, flipY)`

### `Sprite.GetSize(entity)` → `w, h`

---

## 3.10 `Animator`

### `Animator.Play(entity, animationName)`
### `Animator.Stop(entity)`
### `Animator.IsPlaying(entity)` → `true/false`

### `Animator.GetFrame(entity)` → `frameIndex`

---

## 3.11 `Physics`

### `Physics.SetMode(mode)`
- `mode`: `"platformer"` or `"topdown"`

### `Physics.Raycast(x, y, dx, dy, maxDist, mask)`
- returns `hit, hx, hy, nx, ny, entity`

---

## 3.12 `Rigidbody`

### `Rigidbody.GetVelocity(entity)` → `vx, vy`
### `Rigidbody.SetVelocity(entity, vx, vy)`

### `Rigidbody.AddForce(entity, fx, fy)`

### `Rigidbody.SetGravityScale(entity, s)`

Platformer helpers:
### `Rigidbody.IsGrounded(entity)` → `true/false`
### `Rigidbody.SetMaxFallSpeed(entity, maxVy)`

Top-down helpers:
### `Rigidbody.SetMaxSpeed(entity, maxSpeed)`

---

## 3.13 `Collider`

### `Collider.SetTrigger(entity, isTrigger)`
### `Collider.SetSize(entity, w, h)`
### `Collider.SetOffset(entity, ox, oy)`

---

## 3.14 `Audio`

### `Audio.Play(assetKey, bus)`
- `bus` default: `"SFX"`

### `Audio.PlayMusic(assetKey)`
### `Audio.StopMusic()`

### `Audio.SetBusVolume(bus, volume)`
- `bus`: `"Master"`, `"Music"`, `"SFX"`, `"UI"`

---

## 3.15 `Camera`

### `Camera.GetPosition()` → `x, y`
### `Camera.SetPosition(x, y)`

### `Camera.Follow(entity)`
### `Camera.SetZoom(z)`

---

## 3.16 `UI` (optional)

For v1 a minimal immediate-mode UI is acceptable:

### `UI.Begin()` / `UI.End()`
### `UI.Label(text, x, y)`
### `UI.Button(text, x, y, w, h)` → `true/false`

---

## 4. Examples

## 4.1 Platformer Player Controller (Recommended Pattern)
```lua
function OnCreate(self)
  self.speed = 220
  self.jumpVelocity = -520
end

function OnFixedUpdate(self, dt)
  local move = Input.Axis("left", "right")

  local vx, vy = Rigidbody.GetVelocity(self.entity)
  Rigidbody.SetVelocity(self.entity, move * self.speed, vy)

  if Input.Pressed("jump") and Rigidbody.IsGrounded(self.entity) then
    Rigidbody.SetVelocity(self.entity, vx, self.jumpVelocity)
    Audio.Play("sfx/jump.wav")
  end
end
```

## 4.2 Top-down Character
```lua
function OnUpdate(self, dt)
  local ax = Input.Axis("left", "right")
  local ay = Input.Axis("up", "down")

  local nx, ny = Math.Normalize(ax, ay)
  Rigidbody.SetVelocity(self.entity, nx * 160, ny * 160)
end
```

## 4.3 Scene Loading
```lua
function OnUpdate(self, dt)
  if Input.Pressed("restart") then
    World.ReloadScene()
  end
end
```

---

## 5. Reserved Names / Compatibility

- Avoid naming Lua globals that collide with engine modules above.
- PB side should avoid function names that match PB libraries/commands.

---

## 6. Versioning

The engine will expose:
- `Engine.Version()` → string
- `Engine.ApiVersion()` → integer

Lua scripts may verify compatibility at load.
