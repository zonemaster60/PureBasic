

Declare.i E_CUSTOM_MSG_REQUESTER(_head.s,_body.s)
Declare E_CATCH_EVENTS()
Declare E_KEYBOARD_INPUT_KEYS()

Procedure E_MISSING_CONTROLLER_DIALOG()
  
  If e_show_play_field.b=#False
    ProcedureReturn #False 
  EndIf
  
  If e_engine\e_controller_only_mode=#False
    ProcedureReturn #False  
  EndIf
   
  If ElapsedMilliseconds()>e_idle_for_reconnection.i
    E_CHECK_FOR_XBOX_JOYSTICK()
    e_idle_for_reconnection.i=ElapsedMilliseconds()+e_reconnection_idle_time.i
  EndIf
  
    
    If e_xbox_controller\xbox_joystick_present=#True
      e_engine\e_engine_mode=#ACTIVE
      
      ProcedureReturn #False
    EndIf
    
 E_GAME_INPUT_LOGIC(#KEYBOARD)  ;fallback!
  
EndProcedure

Procedure E_GAME_OPTIONS_LOOP()
  
  Define _kkey.i=0
  Define _ckey.i=0
  
  If e_show_play_field.b=#False
    ProcedureReturn #False 
  EndIf
 
 If e_engine\e_controller_only_mode=#False
   _kkey.i=E_KEYBOARD_INPUT_KEYS()
   _ckey.i=E_GAME_INPUT_LOGIC(#XBOX_CONTROLLER)
 Else
   _ckey.i=E_GAME_INPUT_LOGIC(#XBOX_CONTROLLER)
 EndIf
 
 e_engine\e_engine_mode=#OPTION
 
 If _kkey.i=#B Or _ckey.i=#B
      e_engine\e_engine_mode=#ACTIVE
      e_engine\e_next_world= e_map_map_back_up_for_going_back.s
      e_engine\e_game_mode=#GAME_MODE_DAY
      e_ai42_suffix.s=""
      E_SOUND_BUTTON_SOUND_PLAY()
    EndIf
     
    
EndProcedure


Procedure E_GAME_PAUSE_DIALOG()
  
  ;game over handler:
 world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer

If e_show_play_field.b=#False
    ProcedureReturn #False 
EndIf
  
  
  E_SOUND_PAUSE_GLOBAL_SOUND()
  E_SOUND_PAUSE_BOSS_MUSIC()
E_SHOW_CRT_EFFECT()
    ;controller section
    e_xbox_controller\xbox_joystick_button_id=E_XBOX_CONTROLLER_BUTTON_INPUT()
    
  
    If  e_xbox_controller\xbox_joystick_button_id=#A
  
      
      e_engine\e_engine_mode=#QUIT
      
      If IsSound(player_statistics\player_sound_on_death_id)
        StopSound(player_statistics\player_sound_on_death_id)
      EndIf

      
      E_SOUND_BUTTON_SOUND_PLAY()
      E_GRAB_SRC_SCREEN()  
    EndIf
    
    If e_xbox_controller\xbox_joystick_button_id=#B
      
      e_engine\e_engine_mode=#CONTINUE
      
      E_SOUND_BUTTON_SOUND_PLAY()
    
    EndIf
    
    
    ;keyboardsection:
    
    If v_keyboard_present.b<>0
      
   
      If E_KEYBOARD_INPUT_KEYS()=#A
        e_engine\e_engine_mode=#QUIT
        
        If IsSound(player_statistics\player_sound_on_death_id)
          StopSound(player_statistics\player_sound_on_death_id)
        EndIf
        
        E_SOUND_BUTTON_SOUND_PLAY()
       
       E_GRAB_SRC_SCREEN()
      EndIf
      
      If E_KEYBOARD_INPUT_KEYS()=#B
        
        e_engine\e_engine_mode=#CONTINUE
        
        E_SOUND_BUTTON_SOUND_PLAY()

      EndIf
      
      
    EndIf
  
  Select e_engine\e_engine_mode
      
    Case #CONTINUE
      e_engine\e_engine_mode=#ACTIVE
      e_engine\e_show_gray_scale=#False
      E_SOUND_CONTINUE_GLOBAL_SOUND()
      E_SOUND_CONTINUE_BOSS_MUSIC()
    Case #QUIT
      e_engine\e_next_world="start.worldmap"    
      e_engine\e_engine_mode=#ACTIVE
     ; e_engine\e_graphic_source=e_map_gfx_paradise_path.s
      e_engine\e_game_mode=#GAME_MODE_DAY
      e_ai42_suffix.s=""
      e_engine_fresh_start.b=#True  
      e_engine\e_show_gray_scale=#False
    
  EndSelect
  
 
EndProcedure

Procedure E_RESET_GAME_TO_START_MAP()
  
 
EndProcedure


Procedure E_GAME_OVER()
  ;here we do Not show a simple "game over, we show a new world!
  ;user can quit like in normal game mode or buy some extras and go back to the fight!
  
  If e_show_play_field.b=#False
    ProcedureReturn #False 
  EndIf
  
  If e_resurection_map.s=""
      ; E_GAME_OVER_LOOP_MSG() ;no alternative world? no valhalla? go to the simple message: you are dead!
    ProcedureReturn #False
  EndIf
 
   ;this is for the resurection map, if exists
  e_engine\e_next_world=e_resurection_map.s ;dead.worldmap
  e_engine\e_engine_mode=#ACTIVE  ;yes we are dead, but we are active!

EndProcedure



; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 155
; FirstLine = 152
; Folding = -
; Optimizer
; EnableXP
; DPIAware
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant