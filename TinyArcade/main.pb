;tiny arcade game base

EnableExplicit
XIncludeFile "tiny_global_settings.pbi"
XIncludeFile "tiny_const.pbi"
XIncludeFile "tiny_xbox_controller.pbi"
XIncludeFile "tiny_keyboard.pbi"
XIncludeFile "tiny_error.pbi"
XIncludeFile "tiny_window.pbi"
XIncludeFile "tiny_output.pbi"
XIncludeFile "tiny_event.pbi"
XIncludeFile "collison.pbi"
XIncludeFile "tiny_game_control.pbi"


 tiny_game_mode.i=#GAME_RUNNING

;go for the basics

If InitSprite()=0
  
  T_ERROR(#ERR_GFX_SYSTEM)
  
EndIf


If E_SETUP_XBOX_JOYSTICK()=#False 
   T_ERROR(#ERR_XBOX_CONTROLLER)  ;is raised if NO input device is found (keyboard)
EndIf

T_WINDOW()
T_ARCADE_FRAME()
T_SOUND_GLOBAL()

;main


Repeat
   
  tiny_window\window_event=WaitWindowEvent(2)
  
  T_EVENTS(tiny_window\window_event) 
  T_TINY_BEAT_CONTROLLER()
  T_GAME_SCREEN()
  Debug tiny_game_logic\tiny_object_to_rescue_bound_to_player
  
  Until tiny_window\window_event=#PB_Event_CloseWindow
; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 42
; FirstLine = 15
; Optimizer
; EnableXP
; EnableAdmin
; DllProtection
; UseIcon = GFX\disk.ico
; Executable = tiny_arcade.exe
; CPU = 4
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 319
; EnableBuildCount = 27
; EnableExeConstant