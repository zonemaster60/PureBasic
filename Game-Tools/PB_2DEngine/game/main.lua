-- game/main.lua

function OnCreate()
    local playerId = World.FindEntity("player")

    Log.Info("Lua: Script started!")
    Log.Info("Lua: Math.Clamp test (5, 0, 10) = " .. tostring(Math.Clamp(5, 0, 10)))
    Log.Info("Lua: Math.Lerp test (0, 10, 0.25) = " .. tostring(Math.Lerp(0, 10, 0.25)))
    Log.Info("Lua: Engine.IsHeadless = " .. tostring(Engine.IsHeadless()))
    Log.Info("Lua: World.EntityCount = " .. tostring(World.EntityCount()))

    if playerId ~= 0 then
        Log.Info("Lua: Player starts at (" .. tostring(World.EntityX(playerId)) .. ", " .. tostring(World.EntityY(playerId)) .. ")")
    end

    Audio.SetGroupVolume("ui", 90)
end

function OnUpdate(dt)
    local playerId = World.FindEntity("player")
    local selectedId = World.SelectedEntity()
    local mouseWorldX = Engine.ScreenToWorldX(Input.MouseX())
    local mouseWorldY = Engine.ScreenToWorldY(Input.MouseY())

    -- Example: Check for input from Lua
    if Input.Pressed("quit") then
        Log.Warn("Lua: Quit requested via script!")
    end
    
    -- Axis test
    local horizontal = Input.Axis("left", "right")

    if playerId ~= 0 and not Engine.IsHeadless() and Input.MousePressed(1) then
        World.MoveEntityToward(playerId, mouseWorldX, mouseWorldY, 220.0)
    end

    if not Engine.IsHeadless() and Input.MousePressed(2) then
        local picked = World.PickEntityAt(mouseWorldX, mouseWorldY)
        World.SelectEntity(picked)
    end

    if selectedId ~= 0 and not Engine.IsHeadless() and Input.MouseDown(2) then
        World.SetEntityPosition(selectedId, mouseWorldX, mouseWorldY)
    end

    if not Engine.IsHeadless() and Input.Pressed("spawn") then
        local name = "spawn_" .. tostring(World.EntityCount() + 1)
        local spawned = World.SpawnEntitySprite(name, mouseWorldX, mouseWorldY, 0, 0, 16, 0xFF78DC, "game/assets/spawn.bmp")
    end

    if not Engine.IsHeadless() and Input.Pressed("save_scene") then
        if World.SaveScene("game/scene.generated.json") then
            Log.Info("Lua: Saved scene to game/scene.generated.json")
        end
    end

    if Input.Pressed("volume_up") then
        Audio.SetGroupVolume("master", Audio.GroupVolume("master") + 5)
        Log.Info("Lua: Master volume = " .. tostring(Audio.GroupVolume("master")))
    end

    if Input.Pressed("volume_down") then
        Audio.SetGroupVolume("master", Audio.GroupVolume("master") - 5)
        Log.Info("Lua: Master volume = " .. tostring(Audio.GroupVolume("master")))
    end

end

function OnDestroy()
    Log.Info("Lua: Script shutting down.")
end
