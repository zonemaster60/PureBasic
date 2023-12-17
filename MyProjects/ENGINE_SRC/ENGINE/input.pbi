

Procedure E_INIT_ALL_INPUT()
            v_keyboard_present.b=InitKeyboard()
            v_mouse_present.b=InitMouse()
          
  
EndProcedure




Procedure E_INIT_INPUT_DEVICE(_mode.b)
  
  Select _mode.b
      
    Case #False
      E_INIT_ALL_INPUT()
    Case #True
      ;nothing only gamepad!
      
      
  EndSelect
  
  
  
  
EndProcedure
  