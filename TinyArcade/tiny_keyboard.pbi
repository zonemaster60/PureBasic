;here we go for the keyboard inputs:



Procedure T_GET_KEYBOARD_KEY()
  ;here we go:
  
  Define key.i
  ExamineKeyboard()
  
    
  
      
  If KeyboardPushed( #PB_Key_Right)
      ProcedureReturn #XBOX_CONTROLLER_DC_RIGHT
    EndIf
    
  If KeyboardPushed( #PB_Key_Left)
       ProcedureReturn #XBOX_CONTROLLER_DC_LEFT
EndIf


If KeyboardPushed( #PB_Key_Space)
      ProcedureReturn #XBOX_CONTROLLER_START
      
    EndIf
    
  
  
EndProcedure



Procedure T_KEYBOARD_BASE()
  ;use keyboard?
  
  Define key.i=0
  
  If e_xbox_controller\xbox_joystick_id_max>0  ;we always try to use the gamecontroller
    ProcedureReturn #False    
  EndIf
  
  
  
  key.i=T_GET_KEYBOARD_KEY()
  
  
  ProcedureReturn key.i
  
  
  
  
EndProcedure

