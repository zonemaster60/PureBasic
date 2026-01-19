# PB2DEngine — API Reference (Planned v1)

This is the *planned* API surface for the engine. Names are chosen to avoid conflicts with PureBasic built-in command names.

Conventions:
- `entity.i` is an integer entity id.
- `Vec2` is a structure `{x.f, y.f}`.
- Functions often use `*out` pointers in PB for structs.

---

## Core / Log

### `Log::Init()`
Initializes debugger logging.

### `Log::InitFile(filePath.s)`
Writes logs to a file (also echoes to debugger output).

### `Log::Info(message.s)` / `Log::Warn(message.s)` / `Log::Error(message.s)`
Writes a log line.

---

## Core / Time

### `Time::Init(targetFps.i)`
Sets the fixed timestep.

### `Time::NowSeconds()`
Returns time in seconds.

### `Time::FixedDeltaSeconds()`
Returns fixed dt in seconds.

---

## Gfx / Renderer2D (planned)

### `Gfx::Init(title.s, width.i, height.i)`
Creates the window and windowed screen.

### `Gfx::InitHeadless(width.i, height.i)`
Initializes without any window or GPU resources.

### `Gfx::BeginFrame()` / `Gfx::EndFrame()`
Frame boundaries.

### `Gfx::GetScreenWidth()` / `Gfx::GetScreenHeight()`
Backbuffer size currently used.

### `Renderer2D::SetCamera(posX.f, posY.f, zoom.f)`
Sets active camera transform.

### `Renderer2D::DrawSprite(textureId.i, x.f, y.f, rot.f, sx.f, sy.f, layer.i)`
Adds a queued sprite draw.

### `Renderer2D::Flush()`
Sorts queued draws and displays them.

---

## Input

### `Input::Init()`
Initializes input state.

### `Input::Poll()`
Updates input states.

Planned action system:

### `Input::LoadBindings(jsonFile.s)`
Loads action bindings.

### `Input::Down(actionName.s)`
Returns whether action is held.

### `Input::Pressed(actionName.s)`
Returns whether action was pressed this frame.

### `Input::Released(actionName.s)`
Returns whether action was released this frame.

---

## Audio

### `Audio::Init()` / `Audio::Shutdown()`
Initializes audio.

### `Audio::LoadSfx(path.s)`
Returns sound id.

### `Audio::PlaySfx(soundId.i)`
Plays loaded sound.

Planned higher-level API:

### `Audio::Play(path.s, bus.s = "SFX")`
Plays a sound by asset key.

### `Audio::SetBusVolume(bus.s, volume.f)`
Sets volume for `Master`, `Music`, `SFX`, `UI`.

---

## World / Scene

### `World::Init()` / `World::Shutdown()`
World lifetime.

### `World::LoadScene(scenePath.s)`
Loads a scene from JSON.

### `World::UnloadScene()`
Unloads the active scene.

### `World::CreateGameEntity()`
Creates an entity.

### `World::DestroyEntity(entity.i)`
Destroys an entity and all components.

---

## Components (planned)

### Transform
- `pos (Vec2)`
- `rot (float)`
- `scale (Vec2)`

API:
- `Transform::GetPosition(entity, *outVec2)`
- `Transform::SetPosition(entity, x, y)`
- `Transform::Translate(entity, dx, dy)`

### SpriteRenderer
- `textureKey (string)`
- `origin (Vec2)`
- `layer (int)`
- `tint (Color)`

### Animator
- `controllerKey (string)`
- current state, time

### Collider
- `type`: `aabb` / `circle` / `tilemap`
- `isTrigger`: bool

### Rigidbody
- `body`: `static` / `dynamic` / `kinematic`
- `velocity (Vec2)`
- `gravityScale (float)`

### Script
- `file (string)`

### AudioSource
- `bus`, `volume`, `loop`, `autoplay`

---

## Physics2D (planned)

### `Physics2D::SetMode(mode.s)`
- `"platformer"` (gravity and ground detection)
- `"topdown"` (no gravity, slide collision)

### `Rigidbody::SetVelocity(entity, vx, vy)`
### `Rigidbody::GetVelocity(entity, *outVx, *outVy)`
### `Rigidbody::IsGrounded(entity)` (platformer)

Collision events (to scripts):
- `OnCollisionEnter(self, otherEntity)`
- `OnTriggerEnter(self, otherEntity)`

---

## Lua API (planned)

See: `docs/LuaAPI_Final.md` for the final Lua API surface.

Modules exposed to Lua:
- `Log.Info/Warn/Error`
- `Input.Down/Pressed/Released`
- `Transform.*`
- `Rigidbody.*`
- `Audio.Play`, `Audio.SetBusVolume`
- `World.LoadScene`, `World.InstantiatePrefab`
- `Math.Normalize`, `Math.Clamp`, etc.

Script object:
- `self.entity` (entity id)
- `self.scene` (scene id)
