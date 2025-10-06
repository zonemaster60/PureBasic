;tiny engine error system

Define _ok.i=#False 

Procedure T_ERROR(_void.i)
  Define _ok.i=0
  
  Select _void.i
      
    Case #ERR_XBOX_CONTROLLER
      If tiny_keyboard.i=0
      _ok.i=MessageRequester("ERROR", "ERROR JOYSTICK",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      End
    EndIf
    
    ;we can use keyboard
      
      
          Case #ERR_OPEN_WINDOW
      _ok.i=MessageRequester("ERROR", "ERROR OPEN WINDOW",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      End
      
        Case #ERR_OPEN_GAME_SCREEN
      _ok.i=MessageRequester("ERROR", "ERROR OPEN GAME SCREEN",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      End
      
         Case #ERR_GFX_SYSTEM
      _ok.i=MessageRequester("ERROR", "ERROR GFX SYSTEM",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      End
      
               Case #ERR_HOST_SYSTEM
      _ok.i=MessageRequester("ERROR", "ERROR HOST SYSTEM (NO DESKTOP)",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      End
      
  EndSelect
  
  
EndProcedure
