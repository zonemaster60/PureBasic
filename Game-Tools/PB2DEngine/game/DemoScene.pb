EnableExplicit

XIncludeFile "../engine/core/Log.pb"
XIncludeFile "../engine/gfx/Gfx.pb"
XIncludeFile "../engine/input/Input.pb"
XIncludeFile "../engine/audio/Audio.pb"
XIncludeFile "../engine/math/Vec2.pb"
XIncludeFile "../engine/world/World.pb"

DeclareModule DemoScene
  Declare Load()
  Declare Unload()
  Declare RenderUI()
EndDeclareModule

Module DemoScene
  Global g_player.i
  Global g_playerPos.Vec2::T
  Global g_playerVel.Vec2::T

  Global g_playerSprite.i
  Global g_sfxBlip.i

  Procedure Load()
    Log::Info("Loading demo scene")

    ; Create a simple colored sprite
    g_playerSprite = CreateSprite(#PB_Any, 32, 32, #PB_Sprite_AlphaBlending)
    If g_playerSprite
      StartDrawing(SpriteOutput(g_playerSprite))
      Box(0, 0, 32, 32, RGB(255, 200, 60))
      Box(4, 4, 24, 24, RGB(40, 40, 60))
      StopDrawing()
    EndIf

    ; Optional sound (user can add file later)
    ; Place a wav at: PB2DEngine\assets\blip.wav
    g_sfxBlip = 0
    If FileSize("assets\\blip.wav") > 0
      g_sfxBlip = Audio::LoadSfx("assets\\blip.wav")
    EndIf

    g_player = World::CreateGameEntity()
    Vec2::Make(@g_playerPos, 200, 200)
    Vec2::Make(@g_playerVel, 0, 0)

    World::SetTransform(g_player, @g_playerPos)
    World::SetVelocity(g_player, @g_playerVel)
  EndProcedure

  Procedure Unload()
    If IsSprite(g_playerSprite)
      FreeSprite(g_playerSprite)
    EndIf
  EndProcedure

  Procedure RenderUI()
    ; Handle player movement locally for v0.1
    Protected speed.f = 220.0
    Vec2::Make(@g_playerVel, 0, 0)

    If Input::ActionDown(Input::#Action_Left)  : g_playerVel\x - speed : EndIf
    If Input::ActionDown(Input::#Action_Right) : g_playerVel\x + speed : EndIf
    If Input::ActionDown(Input::#Action_Up)    : g_playerVel\y - speed : EndIf
    If Input::ActionDown(Input::#Action_Down)  : g_playerVel\y + speed : EndIf

    World::SetVelocity(g_player, @g_playerVel)

    ; Simplified: Demo tracks pos locally too
    Protected delta.Vec2::T
    Vec2::Scale(@delta, @g_playerVel, 1.0 / 60.0)
    Vec2::Add(@g_playerPos, @g_playerPos, @delta)

    If g_playerPos\x < 0 : g_playerPos\x = 0 : Audio::PlaySfx(g_sfxBlip) : EndIf
    If g_playerPos\y < 0 : g_playerPos\y = 0 : Audio::PlaySfx(g_sfxBlip) : EndIf
    If g_playerPos\x > Gfx::GetScreenWidth() - 32 : g_playerPos\x = Gfx::GetScreenWidth() - 32 : Audio::PlaySfx(g_sfxBlip) : EndIf
    If g_playerPos\y > Gfx::GetScreenHeight() - 32 : g_playerPos\y = Gfx::GetScreenHeight() - 32 : Audio::PlaySfx(g_sfxBlip) : EndIf

    DisplaySprite(g_playerSprite, Int(g_playerPos\x), Int(g_playerPos\y))

    ; Text overlay / tooltip
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Transparent)

    Protected y.i = 10
    DrawText(10, y, "Controls:", RGB(230, 230, 230))
    y + 18

    Protected line.s
    line = Space(64)

    ; For now, show the most important demo actions.
    ; Next step: iterate all actions directly from Input module.
    Input::GetBindingDisplay("left", @line)   : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("right", @line)  : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("up", @line)     : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("down", @line)   : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    y + 6
    Input::GetBindingDisplay("run", @line)    : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("jump", @line)   : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("shoot", @line)  : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("fire", @line)   : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("dash", @line)   : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    Input::GetBindingDisplay("crouch", @line) : DrawText(10, y, line, RGB(220, 220, 220)) : y + 16
    y + 6
    Input::GetBindingDisplay("quit", @line)   : DrawText(10, y, line, RGB(220, 220, 220))

    StopDrawing()
  EndProcedure
EndModule
