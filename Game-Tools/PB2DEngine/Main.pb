; PB2DEngine v0.1
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
  CompilerIf Defined(HEADLESS, #PB_Constant)
    ; Write next to the executable for CI friendliness.
    Log::InitFile(GetPathPart(ProgramFilename()) + "smoke.log")
  CompilerElse
    Log::Init()
  CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    If Gfx::InitHeadless(1280, 720) = #False
      Log::Error("Failed to init headless graphics")
      End
    EndIf
  CompilerElse
    If Gfx::Init("PB2DEngine", 1280, 720) = #False
      Log::Error("Failed to init graphics")
      End
    EndIf
  CompilerEndIf

  If Input::Init() = #False
    Log::Error("Failed to init input")
    End
  EndIf

  ; Optional input bindings
  If FileSize("game\\input.json") > 0
    If Input::LoadBindings("game\\input.json")
      Log::Info("Loaded input bindings: game\\input.json")
    Else
      Log::Warn("Failed to load input bindings; using defaults")
    EndIf
  EndIf

  If Audio::Init() = #False
    Log::Warn("Audio init failed; continuing")
  EndIf

  If Lua::Init("luajit\\lua51.dll") = #False
    Log::Warn("Lua init failed; continuing without scripting")
  Else
    ; Loads game script if present
    If FileSize("game\\main.lua") > 0
      If Lua::LoadFile("game\\main.lua")
        Lua::CallGlobalNoArgs("OnCreate")
      Else
        Log::Warn("Failed to load game script: game\\main.lua")
      EndIf
    Else
      Log::Info("No game script found: game\\main.lua")
    EndIf
  EndIf

  World::Init()

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Log::Info("HEADLESS enabled: skipping DemoScene visual load")
  CompilerElse
    DemoScene::Load()
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

  Protected hasMainLua.i = #False
  If FileSize("game\\main.lua") > 0
    hasMainLua = #True
  EndIf

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
       If hasMainLua And Lua::State()
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
      ; Keep render path disabled for CI/headless runs
    CompilerEndIf

  CompilerIf Defined(HEADLESS, #PB_Constant)
    Until quit
  CompilerElse
    Until quit Or Gfx::WindowClosed()
  CompilerEndIf

   If hasMainLua And Lua::State()
     Lua::CallGlobalNoArgs("OnDestroy")
   EndIf

  CompilerIf Not Defined(HEADLESS, #PB_Constant)
    DemoScene::Unload()
  CompilerEndIf

  World::Shutdown()
  Audio::Shutdown()
  Lua::Shutdown()
  Gfx::Shutdown()
  Log::Shutdown()
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 137
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin