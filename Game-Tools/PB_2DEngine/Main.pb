; PB_2DEngine v1.0.0.0
; Entry point

EnableExplicit

Global version.s = "v1.0.0.2"

#DEFAULT_ENGINE_TITLE = "PB_2DEngine"
#DEFAULT_ENGINE_WIDTH = 1280
#DEFAULT_ENGINE_HEIGHT = 720
#DEFAULT_ENGINE_TARGET_FPS = 60
#MAX_FRAME_DELTA = 0.25
#MAX_FIXED_UPDATES_PER_FRAME = 8
#MAX_FIXED_UPDATES_PER_FRAME_SMOKE = 12

XIncludeFile "engine/core/Config.pb"
XIncludeFile "engine/core/Time.pb"
XIncludeFile "engine/core/Log.pb"
XIncludeFile "engine/gfx/Gfx.pb"
XIncludeFile "engine/input/Input.pb"
XIncludeFile "engine/audio/Audio.pb"
XIncludeFile "engine/world/Camera.pb"
XIncludeFile "engine/world/World.pb"
XIncludeFile "engine/script/Lua.pb"

XIncludeFile "game/DemoScene.pb"

Procedure ShutdownEngine(gfxReady.i, inputReady.i, audioReady.i, luaReady.i, worldReady.i, demoSceneLoaded.i, luaScriptLoaded.i)
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

Procedure Main()
  Protected gfxReady.i = #False
  Protected inputReady.i = #False
  Protected audioReady.i = #False
  Protected luaReady.i = #False
  Protected worldReady.i = #False
  Protected demoSceneLoaded.i = #False
  Protected luaScriptLoaded.i = #False
  Protected engineTitle.s = #DEFAULT_ENGINE_TITLE
  Protected engineWidth.i = #DEFAULT_ENGINE_WIDTH
  Protected engineHeight.i = #DEFAULT_ENGINE_HEIGHT
  Protected engineTargetFps.i = #DEFAULT_ENGINE_TARGET_FPS
  Protected inputBindingsPath.s = "game/input.json"
  Protected scriptPath.s = "game/main.lua"
  Protected scenePath.s = "game/scene.json"
  Protected audioManifestPath.s = "game/audio.json"

  CompilerIf Defined(HEADLESS, #PB_Constant)
    ; Write next to the executable for CI friendliness.
    Log::InitFile(GetPathPart(ProgramFilename()) + "smoke.log")
  CompilerElseIf Defined(SMOKE_TEST, #PB_Constant)
    Log::InitFile(GetPathPart(ProgramFilename()) + "smoke.log")
  CompilerElse
    Log::Init()
  CompilerEndIf

  If Config::Load("game/config.json")
    engineTitle = Config::Title()
    engineWidth = Config::Width()
    engineHeight = Config::Height()
    engineTargetFps = Config::TargetFps()
    inputBindingsPath = Config::InputBindingsPath()
    scriptPath = Config::ScriptPath()
    scenePath = Config::ScenePath()
    audioManifestPath = Config::AudioManifestPath()
    Log::Info("Loaded engine config: game/config.json")
  ElseIf Config::LastLoadMessage() <> ""
    Log::Warn("Using built-in defaults. " + Config::LastLoadMessage())
  EndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Log::Info(engineTitle + " " + version + " starting in HEADLESS mode")
  CompilerElse
    Log::Info(engineTitle + " " + version + " starting")
  CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    If Gfx::InitHeadless(engineWidth, engineHeight) = #False
      Log::Error("Failed to init headless graphics")
      ShutdownEngine(gfxReady, inputReady, audioReady, luaReady, worldReady, demoSceneLoaded, luaScriptLoaded)
      ProcedureReturn
    EndIf
  CompilerElse
    If Gfx::Init(engineTitle, engineWidth, engineHeight) = #False
      Log::Error("Failed to init graphics")
      ShutdownEngine(gfxReady, inputReady, audioReady, luaReady, worldReady, demoSceneLoaded, luaScriptLoaded)
      ProcedureReturn
    EndIf
  CompilerEndIf
  gfxReady = #True

  If Input::Init() = #False
    Log::Error("Failed to init input")
    ShutdownEngine(gfxReady, inputReady, audioReady, luaReady, worldReady, demoSceneLoaded, luaScriptLoaded)
    ProcedureReturn
  EndIf
  inputReady = #True

  Camera::Init(engineWidth, engineHeight)

  ; Optional input bindings
  If FileSize(inputBindingsPath) > 0
    If Input::LoadBindings(inputBindingsPath)
      Log::Info("Loaded input bindings: " + inputBindingsPath)
      If Input::LastLoadMessage() <> ""
        Log::Warn(Input::LastLoadMessage())
      EndIf
    Else
      If Input::LastLoadMessage() <> ""
        Log::Warn("Failed to load input bindings; using defaults. " + Input::LastLoadMessage())
      Else
        Log::Warn("Failed to load input bindings; using defaults")
      EndIf
    EndIf
  EndIf

  If Audio::Init() = #False
    Log::Warn("Audio init failed; continuing")
  Else
    audioReady = #True
    If Audio::LoadManifest(audioManifestPath) = #False And Audio::LastLoadMessage() <> ""
      Log::Warn(Audio::LastLoadMessage())
    EndIf
  EndIf

  If Lua::Init("luajit/lua51.dll") = #False
    Log::Warn("Lua init failed; continuing without scripting")
  Else
    luaReady = #True
    ; Loads game script if present
    If FileSize(scriptPath) > 0
      If Lua::LoadFile(scriptPath)
        If Lua::CallGlobalNoArgs("OnCreate")
          luaScriptLoaded = #True
        Else
          Log::Warn("Lua OnCreate failed; disabling script callbacks")
        EndIf
      Else
        Log::Warn("Failed to load game script: " + scriptPath)
      EndIf
    Else
      Log::Info("No game script found: " + scriptPath)
    EndIf
  EndIf

  World::Init(scenePath)
  worldReady = #True

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Log::Info("HEADLESS enabled: skipping DemoScene visual load")
  CompilerElse
    DemoScene::Load()
    demoSceneLoaded = #True
  CompilerEndIf

  Time::Init(engineTargetFps)

  Protected quit.i = #False
  Protected dtFixed.f = Time::FixedDeltaSeconds()
  If dtFixed <= 0.0
    dtFixed = 1.0 / 60.0
  EndIf

  Protected accumulator.f = 0.0
  Protected lastTime.d = Time::NowSeconds()
  Protected maxFixedUpdatesPerFrame.i = #MAX_FIXED_UPDATES_PER_FRAME

  CompilerIf Defined(SMOKE_TEST, #PB_Constant)
    maxFixedUpdatesPerFrame = #MAX_FIXED_UPDATES_PER_FRAME_SMOKE
  CompilerEndIf

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
    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      Gfx::PumpEvents()
    CompilerEndIf

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
    CompilerElseIf Defined(HEADLESS, #PB_Constant)
      If Time::NowSeconds() >= smokeEndTime
        quit = #True
      EndIf
    CompilerEndIf

    Protected now.d = Time::NowSeconds()
    Protected frameDelta.f = (now - lastTime)
    If frameDelta < 0.0
      frameDelta = 0.0
    EndIf
    If frameDelta > #MAX_FRAME_DELTA
      frameDelta = #MAX_FRAME_DELTA
    EndIf
    lastTime = now

    accumulator + frameDelta

    Protected updatesThisFrame.i = 0

    While accumulator >= dtFixed
      World::Update(dtFixed)
      If luaScriptLoaded And Lua::State()
        If Lua::CallGlobalUpdate("OnUpdate", dtFixed) = #False
          Log::Warn("Lua OnUpdate failed; disabling script callbacks")
          luaScriptLoaded = #False
        EndIf
      EndIf
      accumulator - dtFixed

      updatesThisFrame + 1
      If updatesThisFrame >= maxFixedUpdatesPerFrame
        Log::Warn("Frame update budget exceeded; dropping accumulated time")
        accumulator = 0.0
        Break
      EndIf
    Wend

    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      Gfx::BeginFrame()
      Protected alpha.f = accumulator / dtFixed
      If alpha < 0.0
        alpha = 0.0
      ElseIf alpha > 1.0
        alpha = 1.0
      EndIf
      World::Render(alpha)
      DemoScene::RenderUI()
      Gfx::EndFrame()
      Delay(1)
    CompilerElse
      ; Avoid a hot spin in CI/headless runs.
      Delay(1)
    CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Until quit
  CompilerElse
    Until quit Or Gfx::WindowClosed()
  CompilerEndIf

  ShutdownEngine(gfxReady, inputReady, audioReady, luaReady, worldReady, demoSceneLoaded, luaScriptLoaded)
EndProcedure

Main()

; IDE Options = PureBasic 6.40 (Windows - x64)
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = Main.ico
; Executable = Main.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = PB_2DEngine
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = PureBasic 2D Engine with LUA scripting
; VersionField7 = PB_2DEngine
; VersionField8 = PB_2DEngine.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60