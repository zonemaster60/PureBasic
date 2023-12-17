;here we try to integrate the microsoft xbox controller

Declare E_SET_UP_FOR_INPUT_IDLE()

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
 
 

 
 Procedure E_GET_XBOX_JOYSTICK_INPUT()
  
   If e_xbox_controller\xbox_joystick_present=#False  
      ProcedureReturn #False
  EndIf
  
  
  ;all ok:
    ExamineJoystick(e_xbox_controller\xbox_joystick_id)
    ProcedureReturn #True
  
  
EndProcedure





 
Procedure E_XBOX_CONTROLLER_DIRECTION_DPAD()
  
  
  If  E_GET_XBOX_JOYSTICK_INPUT()=#False
      ProcedureReturn #False
  EndIf
  
  
  ;we have a controller !!!!
  
 
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) >0

    ProcedureReturn #RIGHT
  EndIf
  
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) <0
         ProcedureReturn #LEFT
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) >0

    ProcedureReturn #UP
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) <0
        ProcedureReturn #DOWN
  EndIf
  

   ProcedureReturn #NO_DIRECTION
EndProcedure






Procedure E_XBOX_CONTROLLER_DIRECTION_R_STICK()
  
  
  If  E_GET_XBOX_JOYSTICK_INPUT()=#False
    ProcedureReturn #False
  EndIf

  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,1,#PB_Absolute) >0
    ProcedureReturn #RIGHT
  EndIf
  
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,1,#PB_Absolute) <0
    ProcedureReturn #LEFT
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,1,#PB_Absolute) >0
    ProcedureReturn #DOWN
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,1,#PB_Absolute) <0
    ProcedureReturn #UP
  EndIf
  
  
  ProcedureReturn #NO_DIRECTION
  
EndProcedure






Procedure E_XBOX_CONTROLLER_DIRECTION_L_STICK()
  
  If  E_GET_XBOX_JOYSTICK_INPUT()=#False
    ProcedureReturn #False
  EndIf
  
  
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,0,#PB_Absolute) >0
       ProcedureReturn #RIGHT
  EndIf
  
  
  If  JoystickAxisX(e_xbox_controller\xbox_joystick_id,0,#PB_Absolute) <0
    
    ProcedureReturn #LEFT
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,0,#PB_Absolute) >0
        ProcedureReturn #DOWN
  EndIf
  
  
  If  JoystickAxisY(e_xbox_controller\xbox_joystick_id,0,#PB_Absolute) <0
    
    ProcedureReturn #UP
  EndIf
  
  ProcedureReturn #NO_DIRECTION
  
EndProcedure



Procedure E_XBOX_CONTROLLER_BUTTON_INPUT()
  
  ;check for the controller keys...
  
  ;if no button is pressed status is set to #false  
  
  If  E_GET_XBOX_JOYSTICK_INPUT()=#False
    ProcedureReturn #False
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,7) And JoystickAxisX(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute) >0
    ProcedureReturn #CHANGE_COLOR_TO_GRAY
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,7) And JoystickAxisY(e_xbox_controller\xbox_joystick_id,2,#PB_Absolute)>0
    
    ProcedureReturn #E_CRT_ON_OFF
    
  EndIf
  
  
       If JoystickButton(e_xbox_controller\xbox_joystick_id,1)
  
        ProcedureReturn #A  
     EndIf

   
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,2)
  
        ProcedureReturn #B 
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,3)
 
        ProcedureReturn #X
  EndIf
  
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,4)

        ProcedureReturn #Y 
  EndIf
  
 
;   
;   If JoystickButton(e_xbox_controller\xbox_joystick_id,5)
;    
;         ProcedureReturn #LB
;   EndIf
;   
;   If JoystickButton(e_xbox_controller\xbox_joystick_id,6)
;     
;         ProcedureReturn #RB
;   EndIf
  
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,7)
        ProcedureReturn #SELECT
  EndIf
  
  If JoystickButton(e_xbox_controller\xbox_joystick_id,8)
       ProcedureReturn #START
  EndIf
  
  
;   If JoystickButton(e_xbox_controller\xbox_joystick_id,9)
;       ProcedureReturn #LSTICK
;   EndIf
;   
;   If JoystickButton(e_xbox_controller\xbox_joystick_id,10)
;     ProcedureReturn #RSTICK
;   EndIf
;   
;     If JoystickButton(e_xbox_controller\xbox_joystick_id,18)
;       ProcedureReturn #START
;   EndIf
  

  
  
  ProcedureReturn #NO_BUTTON
  
  
EndProcedure





Procedure.s E_GET_XBOX_JOYSTICK_INFO()
  If e_xbox_controller\controller_suffix=""
    e_xbox_controller\controller_suffix="XBOX"
  EndIf
  
  ProcedureReturn JoystickName(e_xbox_controller\xbox_joystick_id)
EndProcedure

 
 
 
 
 
 
 Procedure E_SETUP_XBOX_JOYSTICK()
   
   e_xbox_controller\xbox_joystick_id_max=InitJoystick()
   
   If e_xbox_controller\xbox_joystick_id_max<0
     ProcedureReturn #False  
   Else
     ProcedureReturn e_xbox_controller\xbox_joystick_id_max
   EndIf
   
   
 EndProcedure

  

Procedure E_CHECK_FOR_XBOX_JOYSTICK()
  
  e_xbox_controller\xbox_joystick_id=E_SETUP_XBOX_JOYSTICK()  
  
  If e_xbox_controller\xbox_joystick_id
    e_xbox_controller\xbox_joystick_present=#True
    e_xbox_controller\xbox_joystick_id=0 ;we support only #1 joystick in this version
    e_xbox_controller\xbox_joystick_id_max=0
    e_xbox_controller\xbox_joystick_name=UCase(E_GET_XBOX_JOYSTICK_INFO())
    
    If FindString(e_xbox_controller\xbox_joystick_name,e_xbox_controller\controller_suffix)=0 And e_xbox_controller\controller_suffix<>"ANY"
      e_xbox_controller\xbox_joystick_present=#False
      e_xbox_controller\xbox_joystick_id=-1
    EndIf
    
    E_SET_UP_FOR_INPUT_IDLE()
  Else
    e_xbox_controller\xbox_joystick_present=#False
  EndIf
  
  
  
EndProcedure

Procedure E_XBOX_CONTROLLER_RECONNECT()
  E_CHECK_FOR_XBOX_JOYSTICK()
 EndProcedure  



 


  
