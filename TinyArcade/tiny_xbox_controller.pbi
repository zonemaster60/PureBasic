;here we try to integrate the microsoft xbox controller



Structure e_xbox_controller
 xbox_joystick_id.i
 xbox_joystick_id_max.i
 xbox_joystick_name.s
 xbox_joystick_axis_x.f
 xbox_joystick_axis_y.f
 xbox_joystick_present.b
 xbox_joystick_button_id.i
 xbox_joystick_thread_id.i
 xbox_joystick_button_hold.b
 xbox_joystick_button_hold_timer.i
 xbox_button_A.b
 xbox_button_A_is_hold.b
 xbox_button_B.b
 xbox_button_X.b
 xbox_button_Y.b
 xbox_button_START.b
 xbox_button_SELECT.b
 xbox_button_A_released.b
 xbox_button_a_pressed.b
 xbox_button_A_is_ready.b
 controller_suffix.s
 EndStructure


 Global e_xbox_controller.e_xbox_controller
 
 

 
 




 
Procedure E_XBOX_CONTROLLER_DIRECTION_DPAD()

  If e_xbox_controller\xbox_joystick_id_max<=0
  ProcedureReturn #False    
  EndIf
  
  
  ExamineJoystick(e_xbox_controller\xbox_joystick_id)
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) >0
    ProcedureReturn #XBOX_CONTROLLER_DC_RIGHT
  EndIf
  
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) <0
         ProcedureReturn #XBOX_CONTROLLER_DC_LEFT
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) >0

    ProcedureReturn #XBOX_CONTROLLER_DC_UP
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) <0
        ProcedureReturn #XBOX_CONTROLLER_DC_DOWN
  EndIf
  

  ProcedureReturn #XBOX_CONTROLLER_NO_DIRECTION
  
EndProcedure









Procedure E_XBOX_CONTROLLER_BUTTON_INPUT()
  
  ;check for the controller keys...
  
  ;if no button is pressed status is set to #false  
  
    If e_xbox_controller\xbox_joystick_id_max<=0
  ProcedureReturn #False    
  EndIf
  
ExamineJoystick(e_xbox_controller\xbox_joystick_id)
  
       If JoystickButton(e_xbox_controller\xbox_joystick_id,1)
  
        ProcedureReturn #XBOX_CONTROLLER_A
     EndIf

   
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,2)
  
        ProcedureReturn #XBOX_CONTROLLER_B
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,3)
 
        ProcedureReturn #XBOX_CONTROLLER_X
  EndIf
  
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,4)

        ProcedureReturn #XBOX_CONTROLLER_Y
  EndIf
  

  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,7)
        ProcedureReturn #XBOX_CONTROLLER_SELECT
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,8)
       ProcedureReturn #XBOX_CONTROLLER_START
  EndIf
  
  
  
  ProcedureReturn #XBOX_CONTROLLER_NO_BUTTON
  
  
EndProcedure





Procedure.s E_GET_XBOX_JOYSTICK_INFO()
  If e_xbox_controller\controller_suffix=""
    e_xbox_controller\controller_suffix="XBOX"
  EndIf
  
  ProcedureReturn JoystickName(e_xbox_controller\xbox_joystick_id)
EndProcedure

 
 
 
 
 
 
 Procedure E_SETUP_XBOX_JOYSTICK()
   
   e_xbox_controller\xbox_joystick_id_max=InitJoystick()
   Debug e_xbox_controller\xbox_joystick_id_max
   

     ProcedureReturn e_xbox_controller\xbox_joystick_id_max
  
   
   
 EndProcedure

  

 Procedure E_CHECK_FOR_XBOX_JOYSTICK()
   
  
  e_xbox_controller\xbox_joystick_id_max=E_SETUP_XBOX_JOYSTICK()  
  
  If e_xbox_controller\xbox_joystick_id_max>0
    e_xbox_controller\xbox_joystick_present=#True
    e_xbox_controller\xbox_joystick_id=0 ;we support only #1 joystick in this version
    ;e_xbox_controller\xbox_joystick_id_max=0
    e_xbox_controller\xbox_joystick_name=UCase(E_GET_XBOX_JOYSTICK_INFO())
    


  Else
    e_xbox_controller\xbox_joystick_present=#False
  EndIf
  
  
  
EndProcedure

Procedure E_XBOX_CONTROLLER_RECONNECT()
  E_CHECK_FOR_XBOX_JOYSTICK()
 EndProcedure  



 


  
