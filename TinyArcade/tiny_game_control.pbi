;tiny game engine player control:

Procedure T_GAME_OVER_CHECK()
  ;here:
  
  Define file.i=0
  
    If tiny_game_logic\tiny_player_lifes<1
    tiny_game_mode.i=#GAME_OWER 
  EndIf
  
  If tiny_game_logic\tiny_player_score>=tiny_game_logic\tiny_player_score_top
    
    file.i=OpenFile(#PB_Any,tiny_directory_path+tiny_save_path)
    
    If IsFile(file.i)=0
    ProcedureReturn #False    
    EndIf
    
    WriteStringN(file.i,Str(tiny_game_logic\tiny_player_score))
    
    CloseFile(file.i)
    
  EndIf
  
  
  
EndProcedure


Procedure T_PLAYER()
  ;player movement
  
  Define key.i=0
  
  If e_xbox_controller\xbox_joystick_id_max>=0
    key.i=E_XBOX_CONTROLLER_DIRECTION_DPAD()
     
  EndIf
  
  If T_KEYBOARD_BASE()<>#False
 
  key.i=T_KEYBOARD_BASE()  
  EndIf
  
  
  tiny_game_logic\tiny_player_control_delay-tiny_game_logic\tiny_player_control_dec
  
  If tiny_game_logic\tiny_player_control_delay>0
  ProcedureReturn #False  ;do nothing!
  EndIf
  
  
  
  Select key.i
      
    Case #XBOX_CONTROLLER_DC_LEFT
      
      If tiny_game_logic\tiny_player_object_pos_x<=tiny_game_logic\tiny_left_border_save_area
      ProcedureReturn #False    ;do nothing
      EndIf
      
      tiny_game_logic\tiny_player_object_pos_x-tiny_game_logic\tiny_player_move_step_x
      T_SOUND_PLAYER()
      
      
Case #XBOX_CONTROLLER_DC_RIGHT
  
  If (tiny_game_logic\tiny_player_object_pos_x+tiny_game_logic\tiny_player_object_w)>=tiny_game_logic\tiny_right_border_save_area
  ProcedureReturn #False ;do nithing  
  EndIf
  
      
   tiny_game_logic\tiny_player_object_pos_x+tiny_game_logic\tiny_player_move_step_x
  T_SOUND_PLAYER()
      
      EndSelect
      
  tiny_game_logic\tiny_player_control_delay=tiny_game_logic\tiny_player_control_start_value
      
EndProcedure

Procedure T_RESPAWN_ENEMY(i.i)
  
  tiny_game_logic\tiny_obstacle_pos_x[i.i]=Random(ScreenWidth()/(i.i+1)-64)
  tiny_game_logic\tiny_obstacle_pos_x[i.i]+32 ;keep it in screen
  tiny_game_logic\tiny_obstacle_pos_y[i.i]=tiny_game_logic\tiny_obstacle_default_pos_y
  
  
  EndProcedure



Procedure T_RESCUE_AI()
  ;here we go for some situations:
  
  If tiny_game_logic\tiny_object_to_rescue_bound_to_player=#True
  ProcedureReturn #False    
  EndIf
  
  
  If tiny_game_logic\tiny_object_to_rescue_pos_y>tiny_game_logic\tiny_object_to_rescue_dead_zone_y
  tiny_game_logic\tiny_object_to_rescue_pos_y=tiny_game_logic\tiny_object_to_rescue_default_pos_y
  tiny_game_logic\tiny_player_lifes-1
  
  tiny_game_logic\tiny_object_to_rescue_pos_x=Random(ScreenWidth()-64)+32
  
   If IsSound(tiny_game_logic\tiny_object_to_rescue_dead_sound_id)

    PlaySound(tiny_game_logic\tiny_object_to_rescue_dead_sound_id,#PB_Sound_MultiChannel,50)
    EndIf
  
EndIf
EndProcedure


Procedure T_RESCUE_SAVE_PLACE()
  ;check for saved rescue:
  

  
  If tiny_game_logic\tiny_object_to_rescue_bound_to_player=#False  
  ProcedureReturn #False    
  EndIf
  
  
  If tiny_game_logic\tiny_player_object_pos_x>=tiny_game_logic\tiny_right_border_save_area
    tiny_game_logic\tiny_player_score+10
    tiny_game_logic\tiny_object_to_rescue_pos_x=Random(ScreenWidth()-64)+32
    tiny_game_logic\tiny_object_to_rescue_pos_y=tiny_game_logic\tiny_object_to_rescue_default_pos_y
    tiny_game_logic\tiny_object_to_rescue_bound_to_player=#False  
    If tiny_beat\tiny_beat_counter>0
      tiny_beat\tiny_beat_counter-1
      EndIf
  EndIf
  
    If tiny_game_logic\tiny_player_object_pos_x<=tiny_game_logic\tiny_left_border_save_area
    tiny_game_logic\tiny_player_score+10
    tiny_game_logic\tiny_object_to_rescue_pos_x=Random(ScreenWidth()-64)+32
    tiny_game_logic\tiny_object_to_rescue_pos_y=tiny_game_logic\tiny_object_to_rescue_default_pos_y
    tiny_game_logic\tiny_object_to_rescue_bound_to_player=#False  
    If tiny_beat\tiny_beat_counter>0
      tiny_beat\tiny_beat_counter-1
      EndIf
  EndIf
  
  If tiny_game_logic\tiny_player_score_top<tiny_game_logic\tiny_player_score
  tiny_game_logic\tiny_player_score_top=tiny_game_logic\tiny_player_score  
  EndIf
  
  
  EndProcedure

Procedure T_ENEMY()
  Define i.i=0
  
  
  tiny_game_logic\tiny_obstacle_control_delay-tiny_game_logic\tiny_obstacle_control_dec
  If tiny_game_logic\tiny_obstacle_control_delay>0
    ProcedureReturn #False  
  EndIf
  
  For i.i=0 To tiny_game_logic\tiny_obstacle_max
    
    tiny_game_logic\tiny_obstacle_pos_y[i.i]+tiny_game_logic\tiny_obstacle_move_step
    
    If IsSound(tiny_game_logic\tiny_obstacle_move_sound_id)
    PlaySound(tiny_game_logic\tiny_obstacle_move_sound_id, #PB_Sound_MultiChannel,50)
    EndIf
    
    
    If tiny_game_logic\tiny_obstacle_pos_y[i.i]>tiny_game_logic\tiny_obstacle_remove_zone_y
      
      T_RESPAWN_ENEMY(i.i)
      
    EndIf
    
  Next
  
  tiny_game_logic\tiny_obstacle_control_delay=tiny_game_logic\tiny_obstacle_control_start_value
  
EndProcedure



Procedure T_RESCUE()
  ;here we go for the not player objects:
  
  
    If tiny_game_logic\tiny_object_to_rescue_bound_to_player=#True
    tiny_game_logic\tiny_object_to_rescue_pos_x=tiny_game_logic\tiny_player_object_pos_x 
    tiny_game_logic\tiny_object_to_rescue_pos_y=tiny_game_logic\tiny_player_object_pos_y-tiny_game_logic\tiny_object_to_rescue_h
     ProcedureReturn #False
  EndIf
  
  tiny_game_logic\tiny_object_to_rescue_control_delay-tiny_game_logic\tiny_object_to_rescue_control_dec
  If tiny_game_logic\tiny_object_to_rescue_control_delay>0
  ProcedureReturn #False    
  EndIf
  

  
  
  tiny_game_logic\tiny_object_to_rescue_pos_y+tiny_game_logic\tiny_object_to_rescue_move_step_y
  
  tiny_game_logic\tiny_object_to_rescue_control_delay=tiny_game_logic\tiny_object_to_rescue_control_start_value
  
  If IsSound(tiny_game_logic\tiny_object_to_rescue_move_sound_id)=0
    ProcedureReturn #False
  EndIf
  
  PlaySound(tiny_game_logic\tiny_object_to_rescue_move_sound_id,#PB_Sound_MultiChannel,50)
  
  
EndProcedure




Procedure T_TINY_BEAT_CONTROLLER()
  ;here we go for frame indebended control
  
 
  If tiny_beat\tiny_beat_actual>ElapsedMilliseconds()
   ProcedureReturn #False   ;do nothing
  EndIf 
 
  tiny_beat\tiny_beat_actual=ElapsedMilliseconds()+tiny_beat\tiny_beat_counter
  ;here we go with the mess
  
  If  e_xbox_controller\xbox_joystick_id_max>=0
  
  If tiny_game_mode.i=#GAME_OWER
    If E_XBOX_CONTROLLER_BUTTON_INPUT()=#XBOX_CONTROLLER_START
      T_GAME_DEFAULT_VALUES()
      
     EndIf
   EndIf
 EndIf
 
  
 If tiny_game_mode.i=#GAME_OWER
   If T_KEYBOARD_BASE()=#XBOX_CONTROLLER_START
     T_GAME_DEFAULT_VALUES()
   EndIf
 EndIf
 
   
  
  If tiny_game_mode.i=#GAME_OWER
  ProcedureReturn #False  
  EndIf
  
 T_PLAYER()
 T_COLLISION_PLAYER()
 T_RESCUE()
T_RESCUE_AI()
T_RESCUE_SAVE_PLACE()
T_ENEMY()
T_COLLISION_FOE()
T_GAME_OVER_CHECK()

  
EndProcedure
