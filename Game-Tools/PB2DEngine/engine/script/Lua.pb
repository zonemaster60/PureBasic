EnableExplicit

XIncludeFile "../core/Log.pb"
XIncludeFile "../input/Input.pb"

; This module is a thin wrapper around LuaJIT (lua51.dll).
; You must ship `lua51.dll` next to the built exe, or in PATH.

DeclareModule Lua
  Declare.i Init(dllPath.s = "lua51.dll")
  Declare Shutdown()

  ; Registers engine functions into Lua globals (Log, Math, ...)
  Declare RegisterEngineApi()

  Declare.i LoadFile(scriptPath.s)
  Declare CallGlobalNoArgs(functionName.s)
  Declare CallGlobalUpdate(functionName.s, dt.f)

  Declare.i State()
EndDeclareModule

 Module Lua
   Global g_dll.i
   Global g_L.i

   #LUA_TFUNCTION = 6

  PrototypeC.i luaL_newstate()
  PrototypeC luaL_openlibs(L.i)
  PrototypeC.i luaL_loadfile(L.i, *filename)
  PrototypeC.i lua_pcall(L.i, nargs.i, nresults.i, errfunc.i)
  PrototypeC lua_close(L.i)
  PrototypeC lua_getfield(L.i, idx.i, k.s)
  PrototypeC lua_settop(L.i, idx.i)
  PrototypeC lua_pushnumber(L.i, n.d)
  PrototypeC lua_pushstring(L.i, s.s)
  PrototypeC lua_createtable(L.i, narr.i, nrec.i)
  PrototypeC lua_setfield(L.i, idx.i, k.s)
  PrototypeC.i lua_type(L.i, idx.i)
  PrototypeC.i lua_tonumber(L.i, idx.i)
  PrototypeC.i lua_toboolean(L.i, idx.i)
  PrototypeC lua_pushboolean(L.i, b.i)
  PrototypeC.i lua_tolstring(L.i, idx.i, *len)
  PrototypeC lua_pushvalue(L.i, idx.i)
  PrototypeC.i luaL_checknumber(L.i, arg.i)
  PrototypeC.i luaL_checklstring(L.i, arg.i, *len)
  PrototypeC.i luaL_error(L.i, fmt.s)
  PrototypeC.i lua_pushcclosure(L.i, fn.i, n.i)

  Global p_luaL_newstate.luaL_newstate
  Global p_luaL_openlibs.luaL_openlibs
  Global p_luaL_loadfile.luaL_loadfile
  Global p_lua_pcall.lua_pcall
  Global p_lua_close.lua_close
  Global p_lua_getfield.lua_getfield
  Global p_lua_settop.lua_settop
  Global p_lua_pushnumber.lua_pushnumber
  Global p_lua_pushstring.lua_pushstring
  Global p_lua_createtable.lua_createtable
  Global p_lua_setfield.lua_setfield
  Global p_lua_type.lua_type
  Global p_lua_tonumber.lua_tonumber
  Global p_lua_toboolean.lua_toboolean
  Global p_lua_pushboolean.lua_pushboolean
  Global p_lua_tolstring.lua_tolstring
  Global p_lua_pushvalue.lua_pushvalue
  Global p_luaL_checknumber.luaL_checknumber
  Global p_luaL_checklstring.luaL_checklstring
  Global p_luaL_error.luaL_error
  Global p_lua_pushcclosure.lua_pushcclosure

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
    p_lua_pushstring = GetFunction(g_dll, "lua_pushstring")
    p_lua_createtable = GetFunction(g_dll, "lua_createtable")
    p_lua_setfield = GetFunction(g_dll, "lua_setfield")
    p_lua_type = GetFunction(g_dll, "lua_type")
    p_lua_tonumber = GetFunction(g_dll, "lua_tonumber")
    p_lua_toboolean = GetFunction(g_dll, "lua_toboolean")
    p_lua_pushboolean = GetFunction(g_dll, "lua_pushboolean")
    p_lua_tolstring = GetFunction(g_dll, "lua_tolstring")
    p_lua_pushvalue = GetFunction(g_dll, "lua_pushvalue")
    p_luaL_checknumber = GetFunction(g_dll, "luaL_checknumber")
    p_luaL_checklstring = GetFunction(g_dll, "luaL_checklstring")
    p_luaL_error = GetFunction(g_dll, "luaL_error")
    p_lua_pushcclosure = GetFunction(g_dll, "lua_pushcclosure")

    If p_luaL_newstate = 0 : Log::Error("Lua bind missing: luaL_newstate") : EndIf
    If p_luaL_openlibs = 0 : Log::Error("Lua bind missing: luaL_openlibs") : EndIf
    If p_luaL_loadfile = 0 : Log::Error("Lua bind missing: luaL_loadfile") : EndIf
    If p_lua_pcall = 0 : Log::Error("Lua bind missing: lua_pcall") : EndIf
    If p_lua_close = 0 : Log::Error("Lua bind missing: lua_close") : EndIf
    If p_lua_getfield = 0 : Log::Error("Lua bind missing: lua_getfield") : EndIf
    If p_lua_settop = 0 : Log::Error("Lua bind missing: lua_settop") : EndIf
    If p_lua_pushnumber = 0 : Log::Error("Lua bind missing: lua_pushnumber") : EndIf
    If p_lua_pushstring = 0 : Log::Error("Lua bind missing: lua_pushstring") : EndIf
    If p_lua_createtable = 0 : Log::Error("Lua bind missing: lua_createtable") : EndIf
    If p_lua_setfield = 0 : Log::Error("Lua bind missing: lua_setfield") : EndIf
    If p_lua_type = 0 : Log::Error("Lua bind missing: lua_type") : EndIf
    If p_lua_tonumber = 0 : Log::Error("Lua bind missing: lua_tonumber") : EndIf
    If p_lua_toboolean = 0 : Log::Error("Lua bind missing: lua_toboolean") : EndIf
    If p_lua_pushboolean = 0 : Log::Error("Lua bind missing: lua_pushboolean") : EndIf
    If p_lua_tolstring = 0 : Log::Error("Lua bind missing: lua_tolstring") : EndIf
    If p_lua_pushvalue = 0 : Log::Error("Lua bind missing: lua_pushvalue") : EndIf
    If p_luaL_checknumber = 0 : Log::Error("Lua bind missing: luaL_checknumber") : EndIf
    If p_luaL_checklstring = 0 : Log::Error("Lua bind missing: luaL_checklstring") : EndIf
    If p_luaL_error = 0 : Log::Error("Lua bind missing: luaL_error") : EndIf
    If p_lua_pushcclosure = 0 : Log::Error("Lua bind missing: lua_pushcclosure") : EndIf

    If p_luaL_newstate = 0 Or p_luaL_openlibs = 0 Or p_luaL_loadfile = 0 Or p_lua_pcall = 0 Or p_lua_close = 0 Or p_lua_getfield = 0 Or p_lua_settop = 0 Or p_lua_pushnumber = 0 Or p_lua_pushstring = 0 Or p_lua_createtable = 0 Or p_lua_setfield = 0 Or p_lua_pushvalue = 0 Or p_lua_type = 0 Or p_lua_tonumber = 0 Or p_lua_toboolean = 0 Or p_lua_pushboolean = 0 Or p_lua_tolstring = 0 Or p_luaL_checknumber = 0 Or p_luaL_checklstring = 0 Or p_luaL_error = 0 Or p_lua_pushcclosure = 0
      Log::Error("LuaJIT function binding failed")
      CloseLibrary(g_dll)
      g_dll = 0
      ProcedureReturn #False
    EndIf

    g_L = p_luaL_newstate()
    If g_L = 0
      Log::Error("luaL_newstate failed")
      CloseLibrary(g_dll)
      g_dll = 0
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
     p_lua_setfield(g_L, -10002, "Log")

    ; Math table
    p_lua_createtable(g_L, 0, 1)

    p_lua_pushcclosure(g_L, @L_MathClamp(), 0)
    p_lua_setfield(g_L, -2, "Clamp")

     p_lua_pushvalue(g_L, -1)
     p_lua_setfield(g_L, -10002, "Math")

    ; Input table
    p_lua_createtable(g_L, 0, 4)

    p_lua_pushcclosure(g_L, @L_InputDown(), 0)
    p_lua_setfield(g_L, -2, "Down")

    p_lua_pushcclosure(g_L, @L_InputPressed(), 0)
    p_lua_setfield(g_L, -2, "Pressed")

    p_lua_pushcclosure(g_L, @L_InputReleased(), 0)
    p_lua_setfield(g_L, -2, "Released")

    p_lua_pushcclosure(g_L, @L_InputAxis(), 0)
    p_lua_setfield(g_L, -2, "Axis")

     p_lua_pushvalue(g_L, -1)
     p_lua_setfield(g_L, -10002, "Input")

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
  EndProcedure

  Procedure.i LoadFile(scriptPath.s)
    If g_L = 0
      ProcedureReturn #False
    EndIf

    Protected normalized.s = ReplaceString(scriptPath, "\\", "/")

    ; Pass UTF-8 C-string to LuaJIT.
    Protected *pathUtf8 = AllocateMemory(StringByteLength(normalized, #PB_UTF8) + 1)
    If *pathUtf8 = 0
      ProcedureReturn #False
    EndIf
    PokeS(*pathUtf8, normalized, -1, #PB_UTF8)

    Protected rc = p_luaL_loadfile(g_L, *pathUtf8)
    FreeMemory(*pathUtf8)
    If rc <> 0
      Log::Error("Lua load error: " + PeekLuaString(g_L, -1))
      p_lua_settop(g_L, 0)
      ProcedureReturn #False
    EndIf

    rc = p_lua_pcall(g_L, 0, 0, 0)
    If rc <> 0
      Log::Error("Lua runtime error: " + PeekLuaString(g_L, -1))
      p_lua_settop(g_L, 0)
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure CallGlobalNoArgs(functionName.s)
    If g_L = 0
      ProcedureReturn
    EndIf

    p_lua_getfield(g_L, -10002, functionName)
    If p_lua_type(g_L, -1) <> #LUA_TFUNCTION
      p_lua_settop(g_L, -2)
      ProcedureReturn
    EndIf

    Protected rc = p_lua_pcall(g_L, 0, 0, 0)
    If rc <> 0
      Log::Error("Lua error calling " + functionName + ": " + PeekLuaString(g_L, -1))
      p_lua_settop(g_L, 0)
    EndIf
  EndProcedure

  Procedure CallGlobalUpdate(functionName.s, dt.f)
    If g_L = 0
      ProcedureReturn
    EndIf

    p_lua_getfield(g_L, -10002, functionName)
    If p_lua_type(g_L, -1) <> #LUA_TFUNCTION
      p_lua_settop(g_L, -2)
      ProcedureReturn
    EndIf

    p_lua_pushnumber(g_L, dt)

    Protected rc = p_lua_pcall(g_L, 1, 0, 0)
    If rc <> 0
      Log::Error("Lua error calling " + functionName + ": " + PeekLuaString(g_L, -1))
      p_lua_settop(g_L, 0)
    EndIf
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