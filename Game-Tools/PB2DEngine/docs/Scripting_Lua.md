# PB2DEngine — Lua Scripting Guide (Planned v1)

See also: `docs/LuaAPI_Final.md` for the final API spec.

PB2DEngine uses LuaJIT (lua51.dll) and runs scripts attached to entities via a `Script` component.

---

## 1. Setup

- Ship `lua51.dll` alongside your `.exe`
- Store scripts in `game/scripts/`
- Attach scripts via scene/prefab JSON:

```json
{
  "components": {
    "Script": {"file": "scripts/player_controller.lua"}
  }
}
```

---

## 2. Script Lifecycle

Any of these functions may be implemented by your Lua file:

- `OnCreate(self)`
- `OnUpdate(self, dt)`
- `OnFixedUpdate(self, dt)`
- `OnDestroy(self)`

Collision callbacks (if entity has Collider/Rigidbody):
- `OnCollisionEnter(self, other)`
- `OnCollisionExit(self, other)`
- `OnTriggerEnter(self, other)`
- `OnTriggerExit(self, other)`

`self` fields:
- `self.entity` → entity id (number)
- `self.name` → optional id string (like "@player")

---

## 3. Engine API Available to Lua (Planned)

### 3.1 Logging
```lua
Log.Info("hello")
Log.Warn("watch out")
Log.Error("something broke")
```

### 3.2 Input
Actions are defined in JSON and loaded at startup.

```lua
if Input.Pressed("jump") then
  --
end

if Input.Down("left") then
  --
end
```

### 3.3 Transform
```lua
local x, y = Transform.GetPosition(self.entity)
Transform.SetPosition(self.entity, x + 10, y)
Transform.Translate(self.entity, 0, -5)
```

### 3.4 Rigidbody (Physics)
Platformer:
```lua
if Input.Pressed("jump") and Rigidbody.IsGrounded(self.entity) then
  local vx, vy = Rigidbody.GetVelocity(self.entity)
  Rigidbody.SetVelocity(self.entity, vx, -520)
end
```

Top-down:
```lua
Rigidbody.SetVelocity(self.entity, 80, 0)
```

### 3.5 Audio
```lua
Audio.Play("sfx/jump.wav")
Audio.SetBusVolume("Music", 0.75)
```

---

## 4. Examples

### 4.1 Platformer Controller
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

### 4.2 Top-down NPC Wander
```lua
function OnCreate(self)
  self.t = 0
end

function OnUpdate(self, dt)
  self.t = self.t + dt
  local vx = math.cos(self.t) * 50
  local vy = math.sin(self.t) * 50
  Rigidbody.SetVelocity(self.entity, vx, vy)
end
```

---

## 5. Performance Notes
- Prefer reading input once per update and writing to components.
- Avoid large allocations/tables per frame.
- Use prefabs and data-driven values instead of hardcoding.
