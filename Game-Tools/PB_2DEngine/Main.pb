; PB_2DEngine v0.1
; Entry point

EnableExplicit

XIncludeFile "engine/core/Time.pb"
XIncludeFile "engine/core/Log.pb"
XIncludeFile "engine/gfx/Gfx.pb"
XIncludeFile "engine/input/Input.pb"
XIncludeFile "engine/audio/Audio.pb"
XIncludeFile "engine/world/World.pb"
XIncludeFile "engine/script/Lua.pb"

XIncludeFile "game/DemoScene.pb"

Procedure Main()
  Protected gfxReady.i = #False
  Protected inputReady.i = #False
  Protected audioReady.i = #False
  Protected luaReady.i = #False
  Protected worldReady.i = #False
  Protected demoSceneLoaded.i = #False
  Protected luaScriptLoaded.i = #False

  CompilerIf Defined(HEADLESS, #PB_Constant)
    ; Write next to the executable for CI friendliness.
    Log::InitFile(GetPathPart(ProgramFilename()) + "smoke.log")
  CompilerElse
    Log::Init()
  CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    If Gfx::InitHeadless(1280, 720) = #False
      Log::Error("Failed to init headless graphics")
      Log::Shutdown()
      ProcedureReturn
    EndIf
  CompilerElse
    If Gfx::Init("PB_2DEngine", 1280, 720) = #False
      Log::Error("Failed to init graphics")
      Log::Shutdown()
      ProcedureReturn
    EndIf
  CompilerEndIf
  gfxReady = #True

  If Input::Init() = #False
    Log::Error("Failed to init input")
    If gfxReady
      Gfx::Shutdown()
    EndIf
    Log::Shutdown()
    ProcedureReturn
  EndIf
  inputReady = #True

  ; Optional input bindings
  If FileSize("game/input.json") > 0
    If Input::LoadBindings("game/input.json")
      Log::Info("Loaded input bindings: game/input.json")
    Else
      Log::Warn("Failed to load input bindings; using defaults")
    EndIf
  EndIf

  If Audio::Init() = #False
    Log::Warn("Audio init failed; continuing")
  Else
    audioReady = #True
  EndIf

  If Lua::Init("luajit/lua51.dll") = #False
    Log::Warn("Lua init failed; continuing without scripting")
  Else
    luaReady = #True
    ; Loads game script if present
    If FileSize("game/main.lua") > 0
      If Lua::LoadFile("game/main.lua")
        luaScriptLoaded = #True
        Lua::CallGlobalNoArgs("OnCreate")
      Else
        Log::Warn("Failed to load game script: game/main.lua")
      EndIf
    Else
      Log::Info("No game script found: game/main.lua")
    EndIf
  EndIf

  World::Init()
  worldReady = #True

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Log::Info("HEADLESS enabled: skipping DemoScene visual load")
  CompilerElse
    DemoScene::Load()
    demoSceneLoaded = #True
  CompilerEndIf

  Time::Init(60)

  Protected quit.i = #False
  Protected dtFixed.f = Time::FixedDeltaSeconds()
  Protected accumulator.f = 0.0
  Protected lastTime.d = Time::NowSeconds()

  CompilerIf Defined(SMOKE_TEST, #PB_Constant)
    Log::Info("SMOKE_TEST enabled: auto-exit after 2 seconds")
    Protected smokeEndTime.d = Time::NowSeconds() + 2.0
  CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    CompilerIf Not Defined(SMOKE_TEST, #PB_Constant)
      Protected smokeEndTime.d = Time::NowSeconds() + 2.0
    CompilerEndIf
  CompilerEndIf

  Protected frames.i = 0

  Repeat
    Input::Poll()

    CompilerIf Defined(HEADLESS, #PB_Constant)
      frames + 1
      If (frames % 60) = 0
        Log::Info("Headless heartbeat: frame=" + Str(frames))
      EndIf
    CompilerEndIf

    If Input::ActionDown(Input::#Action_Quit)
      quit = #True
    EndIf

    CompilerIf Defined(SMOKE_TEST, #PB_Constant)
      If Time::NowSeconds() >= smokeEndTime
        quit = #True
      EndIf
    CompilerEndIf

    Protected now.d = Time::NowSeconds()
    Protected frameDelta.f = (now - lastTime)
    If frameDelta > 0.25
      frameDelta = 0.25
    EndIf
    lastTime = now

    accumulator + frameDelta

    While accumulator >= dtFixed
      World::Update(dtFixed)
      If luaScriptLoaded And Lua::State()
        Lua::CallGlobalUpdate("OnUpdate", dtFixed)
      EndIf
      accumulator - dtFixed
    Wend

    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      Gfx::BeginFrame()
      World::Render(accumulator / dtFixed)
      DemoScene::RenderUI()
      Gfx::EndFrame()
    CompilerElse
      ; Avoid a hot spin in CI/headless runs.
      Delay(1)
    CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Until quit
  CompilerElse
    Until quit Or Gfx::WindowClosed()
  CompilerEndIf

  If luaScriptLoaded And Lua::State()
    Lua::CallGlobalNoArgs("OnDestroy")
  EndIf

  CompilerIf Not Defined(HEADLESS, #PB_Constant)
    If demoSceneLoaded
      DemoScene::Unload()
    EndIf
  CompilerEndIf

  If worldReady
    World::Shutdown()
  EndIf
  If inputReady
    Input::Shutdown()
  EndIf
  If audioReady
    Audio::Shutdown()
  EndIf
  If luaReady
    Lua::Shutdown()
  EndIf
  If gfxReady
    Gfx::Shutdown()
  EndIf
  Log::Shutdown()
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; FirstLine = 137
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; Executable = PB_2DEngine.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = PB_2DEngine
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = PureBasic 2D Engine with LUA scripting
; VersionField7 = PB_2DEngine
; VersionField8 = PB_2DEngine.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
