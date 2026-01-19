-- Demo Lua script for PB2DEngine

function OnCreate()
  Log.Info("Lua OnCreate()")
  Log.Info("Math.Clamp(2.5, 0, 1) = " .. tostring(Math.Clamp(2.5, 0, 1)))
  Log.Info("Input.Down('left') = " .. tostring(Input.Down("left")))
  Log.Info("Input.Axis('left','right') = " .. tostring(Input.Axis("left", "right")))
end

function OnUpdate(dt)
  -- called at fixed timestep for now

  local actions = {"run", "jump", "shoot", "fire", "dash", "crouch"}
  for _, a in ipairs(actions) do
    if Input.Pressed(a) then
      Log.Info("Pressed " .. a)
    end
    if Input.Released(a) then
      Log.Info("Released " .. a)
    end
  end
end

function OnDestroy()
  Log.Info("Lua OnDestroy()")
end
