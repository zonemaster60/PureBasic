;here we have som core/basic checkings for engine start up:

Declare E_QUIT()
Declare E_QUIT_EXIT_ERROR() 

Procedure E_ENGINE_INTERNAL_ERROR_MIN_RESOLUTION()
  
  Define _ok.b=0
  
  _ok.b=MessageRequester("ENGINE_INTERNAL_ERROR_HANDLER:","REQUIRED SCREEN RESOLUTION: "+Str(e_engine\e_engine_internal_screen_w)+" x "+Str(e_engine\e_engine_internal_screen_h)+Chr(13)+"ACTUAL RESOLUTION DETECTED: "+Str(DesktopWidth(0))+" x "+Str(DesktopHeight(0)),#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
  E_QUIT_EXIT_ERROR() 
EndProcedure


Procedure E_ENGINE_INTERNAL_ERROR_DX_VERSION()
  
  Define _ok.b=0
     _ok.b=MessageRequester("ENGINE_INTERNAL_ERROR_HANDLER:","DX Version missing",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
  ; E_QUIT_EXIT_ERROR() 
EndProcedure


Procedure E_DESKTOP_INFORMATION_MISSING()
  
    Define _ok.b=0
  
    _ok.b=MessageRequester("ENGINE_INTERNAL_ERROR_HANDLER:"," DESKTOP INFORMATION MISSING",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
  E_QUIT_EXIT_ERROR() 
  
EndProcedure


Procedure E_ENGINE_CHECK_MINIMUM_REQUIREMENT()
  
  ;go for screen resolution:
  
  If ExamineDesktops()=0
    E_DESKTOP_INFORMATION_MISSING()
  EndIf
  
  
  If DesktopWidth(0)<e_engine\e_engine_internal_screen_w Or DesktopHeight(0)<e_engine\e_engine_internal_screen_h
    E_ENGINE_INTERNAL_ERROR_MIN_RESOLUTION()
  EndIf
  
 
  If v_screen_system_sprite.b=0
  E_ENGINE_INTERNAL_ERROR_DX_VERSION()
  EndIf
  
  
EndProcedure
