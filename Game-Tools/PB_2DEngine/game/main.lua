-- game/main.lua

function OnCreate()
    Log.Info("Lua: Script started!")
    Log.Info("Lua: Math.Clamp test (5, 0, 10) = " .. tostring(Math.Clamp(5, 0, 10)))
end

function OnUpdate(dt)
    -- Example: Check for input from Lua
    if Input.Pressed("quit") then
        Log.Warn("Lua: Quit requested via script!")
    end
    
    -- Axis test
    local horizontal = Input.Axis("left", "right")
    if horizontal ~= 0 then
        Log.Info("Lua: Horizontal axis = " .. tostring(horizontal))
    end
end

function OnDestroy()
    Log.Info("Lua: Script shutting down.")
end
