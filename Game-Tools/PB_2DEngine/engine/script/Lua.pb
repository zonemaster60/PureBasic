EnableExplicit

XIncludeFile "../core/Log.pb"
XIncludeFile "../core/Time.pb"
XIncludeFile "../gfx/Gfx.pb"
XIncludeFile "../input/Input.pb"
XIncludeFile "../audio/Audio.pb"
XIncludeFile "../world/World.pb"

; This module is a thin wrapper around LuaJIT (lua51.dll).
; You must ship `lua51.dll` next to the built exe, or in PATH.

DeclareModule Lua
  Declare.i Init(dllPath.s = "lua51.dll")
  Declare Shutdown()

  ; Registers engine functions into Lua globals (Log, Math, ...)
  Declare RegisterEngineApi()

  Declare.i LoadFile(scriptPath.s)
  Declare.i CallGlobalNoArgs(functionName.s)
  Declare.i CallGlobalUpdate(functionName.s, dt.f)

  Declare.i State()
EndDeclareModule

 Module Lua
   Global g_dll.i
   Global g_L.i

   #LUA_TFUNCTION = 6
  #LUA_GLOBALSINDEX = -10002

  PrototypeC.i luaL_newstate()
  PrototypeC luaL_openlibs(L.i)
  PrototypeC.i luaL_loadfile(L.i, *filename)
  PrototypeC.i lua_pcall(L.i, nargs.i, nresults.i, errfunc.i)
  PrototypeC lua_close(L.i)
  PrototypeC lua_getfield(L.i, idx.i, k.s)
  PrototypeC lua_settop(L.i, idx.i)
  PrototypeC lua_pushnumber(L.i, n.d)
  PrototypeC lua_createtable(L.i, narr.i, nrec.i)
  PrototypeC lua_setfield(L.i, idx.i, k.s)
  PrototypeC.i lua_type(L.i, idx.i)
  PrototypeC lua_pushboolean(L.i, b.i)
  PrototypeC.i lua_tolstring(L.i, idx.i, *len)
  PrototypeC.i lua_gettop(L.i)
  PrototypeC lua_pushvalue(L.i, idx.i)
  PrototypeC.d luaL_checknumber(L.i, arg.i)
  PrototypeC.i lua_pushcclosure(L.i, fn.i, n.i)

  Global p_luaL_newstate.luaL_newstate
  Global p_luaL_openlibs.luaL_openlibs
  Global p_luaL_loadfile.luaL_loadfile
  Global p_lua_pcall.lua_pcall
  Global p_lua_close.lua_close
  Global p_lua_getfield.lua_getfield
  Global p_lua_settop.lua_settop
  Global p_lua_pushnumber.lua_pushnumber
  Global p_lua_createtable.lua_createtable
  Global p_lua_setfield.lua_setfield
  Global p_lua_type.lua_type
  Global p_lua_pushboolean.lua_pushboolean
  Global p_lua_tolstring.lua_tolstring
  Global p_lua_gettop.lua_gettop
  Global p_lua_pushvalue.lua_pushvalue
  Global p_luaL_checknumber.luaL_checknumber
  Global p_lua_pushcclosure.lua_pushcclosure

  Procedure ResetLuaBindings()
    p_luaL_newstate = 0
    p_luaL_openlibs = 0
    p_luaL_loadfile = 0
    p_lua_pcall = 0
    p_lua_close = 0
    p_lua_getfield = 0
    p_lua_settop = 0
    p_lua_pushnumber = 0
    p_lua_createtable = 0
    p_lua_setfield = 0
    p_lua_type = 0
    p_lua_pushboolean = 0
    p_lua_tolstring = 0
    p_lua_gettop = 0
    p_lua_pushvalue = 0
    p_luaL_checknumber = 0
    p_lua_pushcclosure = 0
  EndProcedure

  Procedure ClearStack()
    If g_L And p_lua_settop
      p_lua_settop(g_L, 0)
    EndIf
  EndProcedure

  Procedure Pop(count.i = 1)
    Protected newTop.i

    If g_L = 0 Or p_lua_gettop = 0 Or p_lua_settop = 0 Or count <= 0
      ProcedureReturn
    EndIf

    newTop = p_lua_gettop(g_L) - count
    If newTop < 0
      newTop = 0
    EndIf

    p_lua_settop(g_L, newTop)
  EndProcedure

  Procedure.i PrepareGlobalFunctionCall(functionName.s)
    If g_L = 0 Or p_lua_getfield = 0 Or p_lua_type = 0
      ProcedureReturn #False
    EndIf

    p_lua_getfield(g_L, #LUA_GLOBALSINDEX, functionName)
    If p_lua_type(g_L, -1) <> #LUA_TFUNCTION
      Pop()
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure.s PeekLuaString(L.i, idx.i)
    Protected len.i
    Protected *c = p_lua_tolstring(L, idx, @len)
    If *c
      ProcedureReturn PeekS(*c, len, #PB_UTF8)
    EndIf
    ProcedureReturn ""
  EndProcedure

  Procedure.i Init(dllPath.s = "lua51.dll")
    If g_L
      ProcedureReturn #True
    EndIf

    ResetLuaBindings()

    g_dll = OpenLibrary(#PB_Any, dllPath)
    If g_dll = 0
      Log::Warn("LuaJIT DLL not found: " + dllPath)
      ProcedureReturn #False
    EndIf

    p_luaL_newstate = GetFunction(g_dll, "luaL_newstate")
    p_luaL_openlibs = GetFunction(g_dll, "luaL_openlibs")
    p_luaL_loadfile = GetFunction(g_dll, "luaL_loadfile")
    p_lua_pcall = GetFunction(g_dll, "lua_pcall")
    p_lua_close = GetFunction(g_dll, "lua_close")
    p_lua_getfield = GetFunction(g_dll, "lua_getfield")
    p_lua_settop = GetFunction(g_dll, "lua_settop")
    p_lua_pushnumber = GetFunction(g_dll, "lua_pushnumber")
    p_lua_createtable = GetFunction(g_dll, "lua_createtable")
    p_lua_setfield = GetFunction(g_dll, "lua_setfield")
    p_lua_type = GetFunction(g_dll, "lua_type")
    p_lua_pushboolean = GetFunction(g_dll, "lua_pushboolean")
    p_lua_tolstring = GetFunction(g_dll, "lua_tolstring")
    p_lua_gettop = GetFunction(g_dll, "lua_gettop")
    p_lua_pushvalue = GetFunction(g_dll, "lua_pushvalue")
    p_luaL_checknumber = GetFunction(g_dll, "luaL_checknumber")
    p_lua_pushcclosure = GetFunction(g_dll, "lua_pushcclosure")

    If p_luaL_newstate = 0 : Log::Error("Lua bind missing: luaL_newstate") : EndIf
    If p_luaL_openlibs = 0 : Log::Error("Lua bind missing: luaL_openlibs") : EndIf
    If p_luaL_loadfile = 0 : Log::Error("Lua bind missing: luaL_loadfile") : EndIf
    If p_lua_pcall = 0 : Log::Error("Lua bind missing: lua_pcall") : EndIf
    If p_lua_close = 0 : Log::Error("Lua bind missing: lua_close") : EndIf
    If p_lua_getfield = 0 : Log::Error("Lua bind missing: lua_getfield") : EndIf
    If p_lua_settop = 0 : Log::Error("Lua bind missing: lua_settop") : EndIf
    If p_lua_pushnumber = 0 : Log::Error("Lua bind missing: lua_pushnumber") : EndIf
    If p_lua_createtable = 0 : Log::Error("Lua bind missing: lua_createtable") : EndIf
    If p_lua_setfield = 0 : Log::Error("Lua bind missing: lua_setfield") : EndIf
    If p_lua_type = 0 : Log::Error("Lua bind missing: lua_type") : EndIf
    If p_lua_pushboolean = 0 : Log::Error("Lua bind missing: lua_pushboolean") : EndIf
    If p_lua_tolstring = 0 : Log::Error("Lua bind missing: lua_tolstring") : EndIf
    If p_lua_gettop = 0 : Log::Error("Lua bind missing: lua_gettop") : EndIf
    If p_lua_pushvalue = 0 : Log::Error("Lua bind missing: lua_pushvalue") : EndIf
    If p_luaL_checknumber = 0 : Log::Error("Lua bind missing: luaL_checknumber") : EndIf
    If p_lua_pushcclosure = 0 : Log::Error("Lua bind missing: lua_pushcclosure") : EndIf

    If p_luaL_newstate = 0 Or p_luaL_openlibs = 0 Or p_luaL_loadfile = 0 Or p_lua_pcall = 0 Or p_lua_close = 0 Or p_lua_getfield = 0 Or p_lua_settop = 0 Or p_lua_pushnumber = 0 Or p_lua_createtable = 0 Or p_lua_setfield = 0 Or p_lua_gettop = 0 Or p_lua_pushvalue = 0 Or p_lua_type = 0 Or p_lua_pushboolean = 0 Or p_lua_tolstring = 0 Or p_luaL_checknumber = 0 Or p_lua_pushcclosure = 0
      Log::Error("LuaJIT function binding failed")
      CloseLibrary(g_dll)
      g_dll = 0
      ResetLuaBindings()
      ProcedureReturn #False
    EndIf

    g_L = p_luaL_newstate()
    If g_L = 0
      Log::Error("luaL_newstate failed")
      CloseLibrary(g_dll)
      g_dll = 0
      ResetLuaBindings()
      ProcedureReturn #False
    EndIf

    p_luaL_openlibs(g_L)
    RegisterEngineApi()
    Log::Info("Lua initialized")
    ProcedureReturn #True
  EndProcedure

  ProcedureC.i L_LogInfo(L.i)
    Protected msg.s = PeekLuaString(L, 1)
    Log::Info(msg)
    ProcedureReturn 0
  EndProcedure

  ProcedureC.i L_LogWarn(L.i)
    Protected msg.s = PeekLuaString(L, 1)
    Log::Warn(msg)
    ProcedureReturn 0
  EndProcedure

  ProcedureC.i L_LogError(L.i)
    Protected msg.s = PeekLuaString(L, 1)
    Log::Error(msg)
    ProcedureReturn 0
  EndProcedure

  ProcedureC.i L_MathClamp(L.i)
    Protected x.d = p_luaL_checknumber(L, 1)
    Protected minv.d = p_luaL_checknumber(L, 2)
    Protected maxv.d = p_luaL_checknumber(L, 3)

    If x < minv : x = minv : EndIf
    If x > maxv : x = maxv : EndIf

    p_lua_pushnumber(L, x)
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_MathLerp(L.i)
    Protected a.d = p_luaL_checknumber(L, 1)
    Protected b.d = p_luaL_checknumber(L, 2)
    Protected t.d = p_luaL_checknumber(L, 3)

    p_lua_pushnumber(L, a + ((b - a) * t))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputDown(L.i)
    Protected actionName.s = PeekLuaString(L, 1)
    p_lua_pushboolean(L, Bool(Input::DownName(actionName)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputPressed(L.i)
    Protected actionName.s = PeekLuaString(L, 1)
    p_lua_pushboolean(L, Bool(Input::PressedName(actionName)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputReleased(L.i)
    Protected actionName.s = PeekLuaString(L, 1)
    p_lua_pushboolean(L, Bool(Input::ReleasedName(actionName)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputAxis(L.i)
    Protected neg.s = PeekLuaString(L, 1)
    Protected pos.s = PeekLuaString(L, 2)

    Protected v.d = 0.0
    If Input::DownName(neg)
      v - 1.0
    EndIf
    If Input::DownName(pos)
      v + 1.0
    EndIf

    p_lua_pushnumber(L, v)
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_TimeNow(L.i)
    p_lua_pushnumber(L, Time::NowSeconds())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_TimeFixedDelta(L.i)
    p_lua_pushnumber(L, Time::FixedDeltaSeconds())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_EngineIsHeadless(L.i)
    p_lua_pushboolean(L, Bool(Gfx::Headless()))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_EngineScreenToWorldX(L.i)
    Protected screenX.d = p_luaL_checknumber(L, 1)
    p_lua_pushnumber(L, Camera::ScreenToWorldX(screenX))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_EngineScreenToWorldY(L.i)
    Protected screenY.d = p_luaL_checknumber(L, 1)
    p_lua_pushnumber(L, Camera::ScreenToWorldY(screenY))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputMouseX(L.i)
    p_lua_pushnumber(L, Input::PointerX())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputMouseY(L.i)
    p_lua_pushnumber(L, Input::PointerY())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputMouseDown(L.i)
    Protected button.i = #PB_MouseButton_Left
    If p_lua_gettop(g_L) >= 1
      button = Int(p_luaL_checknumber(L, 1))
    EndIf
    p_lua_pushboolean(L, Bool(Input::PointerDown(button)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputMousePressed(L.i)
    Protected button.i = #PB_MouseButton_Left
    If p_lua_gettop(g_L) >= 1
      button = Int(p_luaL_checknumber(L, 1))
    EndIf
    p_lua_pushboolean(L, Bool(Input::PointerPressed(button)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_InputMouseReleased(L.i)
    Protected button.i = #PB_MouseButton_Left
    If p_lua_gettop(g_L) >= 1
      button = Int(p_luaL_checknumber(L, 1))
    EndIf
    p_lua_pushboolean(L, Bool(Input::PointerReleased(button)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldEntityCount(L.i)
    p_lua_pushnumber(L, World::EntityCount())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldFindEntity(L.i)
    Protected name.s = PeekLuaString(L, 1)
    p_lua_pushnumber(L, World::FindEntity(name))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSpawnEntity(L.i)
    Protected name.s = PeekLuaString(L, 1)
    Protected x.d = p_luaL_checknumber(L, 2)
    Protected y.d = p_luaL_checknumber(L, 3)
    Protected vx.d = p_luaL_checknumber(L, 4)
    Protected vy.d = p_luaL_checknumber(L, 5)
    Protected size.d = p_luaL_checknumber(L, 6)
    Protected color.i = Int(p_luaL_checknumber(L, 7))

    p_lua_pushnumber(L, World::SpawnEntity(name, x, y, vx, vy, size, color))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSpawnEntitySprite(L.i)
    Protected name.s = PeekLuaString(L, 1)
    Protected x.d = p_luaL_checknumber(L, 2)
    Protected y.d = p_luaL_checknumber(L, 3)
    Protected vx.d = p_luaL_checknumber(L, 4)
    Protected vy.d = p_luaL_checknumber(L, 5)
    Protected size.d = p_luaL_checknumber(L, 6)
    Protected color.i = Int(p_luaL_checknumber(L, 7))
    Protected spritePath.s = PeekLuaString(L, 8)

    p_lua_pushnumber(L, World::SpawnEntitySprite(name, x, y, vx, vy, size, color, spritePath))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldMoveEntityToward(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    Protected x.d = p_luaL_checknumber(L, 2)
    Protected y.d = p_luaL_checknumber(L, 3)
    Protected speed.d = p_luaL_checknumber(L, 4)

    p_lua_pushboolean(L, Bool(World::MoveEntityToward(entityId, x, y, speed)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSetEntityVelocity(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    Protected vx.d = p_luaL_checknumber(L, 2)
    Protected vy.d = p_luaL_checknumber(L, 3)

    p_lua_pushboolean(L, Bool(World::SetEntityVelocity(entityId, vx, vy)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldEntityPositionX(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    Protected posX.Float
    Protected posY.Float

    If World::GetEntityPosition(entityId, @posX, @posY)
      p_lua_pushnumber(L, posX\f)
    Else
      p_lua_pushnumber(L, 0.0)
    EndIf
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldEntityPositionY(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    Protected posX.Float
    Protected posY.Float

    If World::GetEntityPosition(entityId, @posX, @posY)
      p_lua_pushnumber(L, posY\f)
    Else
      p_lua_pushnumber(L, 0.0)
    EndIf
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldPickEntityAt(L.i)
    Protected worldX.d = p_luaL_checknumber(L, 1)
    Protected worldY.d = p_luaL_checknumber(L, 2)
    p_lua_pushnumber(L, World::PickEntityAt(worldX, worldY))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSelectEntity(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    p_lua_pushboolean(L, Bool(World::SelectEntity(entityId)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSelectedEntity(L.i)
    p_lua_pushnumber(L, World::SelectedEntity())
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSetEntityPosition(L.i)
    Protected entityId.i = Int(p_luaL_checknumber(L, 1))
    Protected worldX.d = p_luaL_checknumber(L, 2)
    Protected worldY.d = p_luaL_checknumber(L, 3)
    p_lua_pushboolean(L, Bool(World::SetEntityPosition(entityId, worldX, worldY)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_AudioPlay(L.i)
    Protected name.s = PeekLuaString(L, 1)
    Protected loop.i = #False

    If p_lua_gettop(g_L) >= 2
      loop = Int(p_luaL_checknumber(L, 2))
    EndIf

    p_lua_pushboolean(L, Bool(Audio::Play(name, loop)))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_AudioSetGroupVolume(L.i)
    Protected groupName.s = PeekLuaString(L, 1)
    Protected volume.i = Int(p_luaL_checknumber(L, 2))

    Audio::SetGroupVolume(groupName, volume)
    ProcedureReturn 0
  EndProcedure

  ProcedureC.i L_AudioGroupVolume(L.i)
    Protected groupName.s = PeekLuaString(L, 1)
    p_lua_pushnumber(L, Audio::GroupVolume(groupName))
    ProcedureReturn 1
  EndProcedure

  ProcedureC.i L_WorldSaveScene(L.i)
    Protected path.s = PeekLuaString(L, 1)
    p_lua_pushboolean(L, Bool(World::SaveScene(path)))
    ProcedureReturn 1
  EndProcedure

  Procedure RegisterEngineApi()
    If g_L = 0
      ProcedureReturn
    EndIf

    ; Log table
    p_lua_createtable(g_L, 0, 3)

    p_lua_pushcclosure(g_L, @L_LogInfo(), 0)
    p_lua_setfield(g_L, -2, "Info")

    p_lua_pushcclosure(g_L, @L_LogWarn(), 0)
    p_lua_setfield(g_L, -2, "Warn")

    p_lua_pushcclosure(g_L, @L_LogError(), 0)
    p_lua_setfield(g_L, -2, "Error")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Log")

    ; Math table
    p_lua_createtable(g_L, 0, 2)

    p_lua_pushcclosure(g_L, @L_MathClamp(), 0)
    p_lua_setfield(g_L, -2, "Clamp")

    p_lua_pushcclosure(g_L, @L_MathLerp(), 0)
    p_lua_setfield(g_L, -2, "Lerp")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Math")

    ; Input table
    p_lua_createtable(g_L, 0, 9)

    p_lua_pushcclosure(g_L, @L_InputDown(), 0)
    p_lua_setfield(g_L, -2, "Down")

    p_lua_pushcclosure(g_L, @L_InputPressed(), 0)
    p_lua_setfield(g_L, -2, "Pressed")

    p_lua_pushcclosure(g_L, @L_InputReleased(), 0)
    p_lua_setfield(g_L, -2, "Released")

    p_lua_pushcclosure(g_L, @L_InputAxis(), 0)
    p_lua_setfield(g_L, -2, "Axis")

    p_lua_pushcclosure(g_L, @L_InputMouseX(), 0)
    p_lua_setfield(g_L, -2, "MouseX")

    p_lua_pushcclosure(g_L, @L_InputMouseY(), 0)
    p_lua_setfield(g_L, -2, "MouseY")

    p_lua_pushcclosure(g_L, @L_InputMouseDown(), 0)
    p_lua_setfield(g_L, -2, "MouseDown")

    p_lua_pushcclosure(g_L, @L_InputMousePressed(), 0)
    p_lua_setfield(g_L, -2, "MousePressed")

    p_lua_pushcclosure(g_L, @L_InputMouseReleased(), 0)
    p_lua_setfield(g_L, -2, "MouseReleased")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Input")

    ; Time table
    p_lua_createtable(g_L, 0, 2)

    p_lua_pushcclosure(g_L, @L_TimeNow(), 0)
    p_lua_setfield(g_L, -2, "Now")

    p_lua_pushcclosure(g_L, @L_TimeFixedDelta(), 0)
    p_lua_setfield(g_L, -2, "FixedDelta")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Time")

    ; Engine table
    p_lua_createtable(g_L, 0, 3)

    p_lua_pushcclosure(g_L, @L_EngineIsHeadless(), 0)
    p_lua_setfield(g_L, -2, "IsHeadless")

    p_lua_pushcclosure(g_L, @L_EngineScreenToWorldX(), 0)
    p_lua_setfield(g_L, -2, "ScreenToWorldX")

    p_lua_pushcclosure(g_L, @L_EngineScreenToWorldY(), 0)
    p_lua_setfield(g_L, -2, "ScreenToWorldY")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Engine")

    ; World table
    p_lua_createtable(g_L, 0, 13)

    p_lua_pushcclosure(g_L, @L_WorldEntityCount(), 0)
    p_lua_setfield(g_L, -2, "EntityCount")

    p_lua_pushcclosure(g_L, @L_WorldFindEntity(), 0)
    p_lua_setfield(g_L, -2, "FindEntity")

    p_lua_pushcclosure(g_L, @L_WorldSpawnEntity(), 0)
    p_lua_setfield(g_L, -2, "SpawnEntity")

    p_lua_pushcclosure(g_L, @L_WorldSpawnEntitySprite(), 0)
    p_lua_setfield(g_L, -2, "SpawnEntitySprite")

    p_lua_pushcclosure(g_L, @L_WorldMoveEntityToward(), 0)
    p_lua_setfield(g_L, -2, "MoveEntityToward")

    p_lua_pushcclosure(g_L, @L_WorldSetEntityVelocity(), 0)
    p_lua_setfield(g_L, -2, "SetEntityVelocity")

    p_lua_pushcclosure(g_L, @L_WorldEntityPositionX(), 0)
    p_lua_setfield(g_L, -2, "EntityX")

    p_lua_pushcclosure(g_L, @L_WorldEntityPositionY(), 0)
    p_lua_setfield(g_L, -2, "EntityY")

    p_lua_pushcclosure(g_L, @L_WorldSaveScene(), 0)
    p_lua_setfield(g_L, -2, "SaveScene")

    p_lua_pushcclosure(g_L, @L_WorldPickEntityAt(), 0)
    p_lua_setfield(g_L, -2, "PickEntityAt")

    p_lua_pushcclosure(g_L, @L_WorldSelectEntity(), 0)
    p_lua_setfield(g_L, -2, "SelectEntity")

    p_lua_pushcclosure(g_L, @L_WorldSelectedEntity(), 0)
    p_lua_setfield(g_L, -2, "SelectedEntity")

    p_lua_pushcclosure(g_L, @L_WorldSetEntityPosition(), 0)
    p_lua_setfield(g_L, -2, "SetEntityPosition")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "World")

    ; Audio table
    p_lua_createtable(g_L, 0, 3)

    p_lua_pushcclosure(g_L, @L_AudioPlay(), 0)
    p_lua_setfield(g_L, -2, "Play")

    p_lua_pushcclosure(g_L, @L_AudioSetGroupVolume(), 0)
    p_lua_setfield(g_L, -2, "SetGroupVolume")

    p_lua_pushcclosure(g_L, @L_AudioGroupVolume(), 0)
    p_lua_setfield(g_L, -2, "GroupVolume")

    p_lua_pushvalue(g_L, -1)
    p_lua_setfield(g_L, #LUA_GLOBALSINDEX, "Audio")

    ; Leave Lua stack in a clean state after registration.
    ClearStack()

  EndProcedure

  Procedure Shutdown()
    If g_L
      p_lua_close(g_L)
      g_L = 0
    EndIf
    If g_dll
      CloseLibrary(g_dll)
      g_dll = 0
    EndIf

    ResetLuaBindings()
  EndProcedure

  Procedure.i LoadFile(scriptPath.s)
    If g_L = 0
      ProcedureReturn #False
    EndIf

    Protected normalized.s = ReplaceString(scriptPath, "\\", "/")

    ; Pass UTF-8 C-string to LuaJIT.
    Protected *pathUtf8 = AllocateMemory(StringByteLength(normalized, #PB_UTF8) + 1)
    If *pathUtf8 = 0
      Log::Error("Lua load error: failed to allocate script path buffer")
      ProcedureReturn #False
    EndIf
    PokeS(*pathUtf8, normalized, -1, #PB_UTF8)

    Protected rc = p_luaL_loadfile(g_L, *pathUtf8)
    FreeMemory(*pathUtf8)
    If rc <> 0
      Log::Error("Lua load error: " + PeekLuaString(g_L, -1))
      ClearStack()
      ProcedureReturn #False
    EndIf

    rc = p_lua_pcall(g_L, 0, 0, 0)
    If rc <> 0
      Log::Error("Lua runtime error: " + PeekLuaString(g_L, -1))
      ClearStack()
      ProcedureReturn #False
    EndIf

    ClearStack()

    ProcedureReturn #True
  EndProcedure

  Procedure.i CallGlobalNoArgs(functionName.s)
    If PrepareGlobalFunctionCall(functionName) = #False
      ProcedureReturn #True
    EndIf

    Protected rc = p_lua_pcall(g_L, 0, 0, 0)
    If rc <> 0
      Log::Error("Lua error calling " + functionName + ": " + PeekLuaString(g_L, -1))
      ClearStack()
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure.i CallGlobalUpdate(functionName.s, dt.f)
    If PrepareGlobalFunctionCall(functionName) = #False
      ProcedureReturn #True
    EndIf

    p_lua_pushnumber(g_L, dt)

    Protected rc = p_lua_pcall(g_L, 1, 0, 0)
    If rc <> 0
      Log::Error("Lua error calling " + functionName + ": " + PeekLuaString(g_L, -1))
      ClearStack()
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure.i State()
    ProcedureReturn g_L
  EndProcedure
EndModule

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 249
; FirstLine = 330
; Folding = ----
; EnableXP
; DPIAware
