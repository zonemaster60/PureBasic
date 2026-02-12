;tiny engine window system, all hard coded, no external settings!

Procedure T_GFX_DATA()
  
  If IsSprite(tiny_game_logic\tiny_object_to_rescue_id)=0
  ProcedureReturn #False    
  EndIf
  
  tiny_game_logic\tiny_object_to_rescue_h=SpriteHeight(tiny_game_logic\tiny_object_to_rescue_id)
  tiny_game_logic\tiny_object_to_rescue_w=SpriteWidth(tiny_game_logic\tiny_object_to_rescue_id)
  
EndProcedure


Procedure T_GAME_DEFAULT_VALUES()
  ;here is the basic of all
  Define i.i=0
    
  tiny_game_logic\tiny_left_border_save_area=16
 ;nothing for now, reset value after screen open!
 
  tiny_game_logic\tiny_player_object_pos_x=240
  tiny_game_logic\tiny_player_object_pos_y=250
  tiny_game_logic\tiny_player_move_step_x=16
  tiny_game_logic\tiny_player_control_start_value=100
  tiny_game_logic\tiny_player_control_delay=100
  tiny_game_logic\tiny_player_control_dec=10
  tiny_game_logic\tiny_player_score=0
  tiny_game_logic\tiny_player_lifes=3
  tiny_game_logic\tiny_object_to_rescue_control_dec=10
  tiny_game_logic\tiny_object_to_rescue_control_delay=200
  tiny_game_logic\tiny_object_to_rescue_control_start_value=200
  tiny_game_logic\tiny_object_to_rescue_dead_zone_y=280
  tiny_game_logic\tiny_object_to_rescue_move_step_y=16
  tiny_game_logic\tiny_object_to_rescue_pos_x=100
  tiny_game_logic\tiny_object_to_rescue_pos_y=8
  tiny_game_logic\tiny_object_to_rescue_default_pos_y=8
  tiny_game_logic\tiny_object_to_rescue_default_pos_x=100
  tiny_game_logic\tiny_obstacle_control_dec=10
  tiny_game_logic\tiny_obstacle_control_delay=200
  tiny_game_logic\tiny_obstacle_control_start_value=200
  tiny_game_logic\tiny_obstacle_max=2
  tiny_game_logic\ tiny_obstacle_default_pos_x=120
  tiny_game_logic\tiny_obstacle_default_pos_y=8
  tiny_game_logic\tiny_obstacle_move_step=8
  tiny_game_logic\tiny_obstacle_remove_zone_y=260
  tiny_beat\tiny_beat_size=100
  tiny_beat\tiny_beat_counter=20
  tiny_game_logic\tiny_object_to_rescue_bound_to_player=#False  
  tiny_beat\tiny_beat_start=ElapsedMilliseconds()+tiny_beat\tiny_beat_size
  tiny_game_mode=#GAME_RUNNING
  
  For i.i=0 To 2  ;we load the maximum of obstacles!
    tiny_game_logic\tiny_obstacle_pos_y[i.i]=tiny_game_logic\tiny_obstacle_default_pos_y
Next

tiny_game_logic\tiny_obstacle_pos_x[0]=Random(ScreenWidth()/3)
tiny_game_logic\tiny_obstacle_pos_x[0]+32 ;keep it in screen
tiny_game_logic\tiny_obstacle_pos_x[1]=Random(ScreenWidth()/3)+ScreenWidth()/3
tiny_game_logic\tiny_obstacle_pos_x[2]=Random(ScreenWidth()/3)+ScreenWidth()/3+ScreenWidth()/3-32



EndProcedure


Procedure T_GAME_SETUP()
  
  ;
  Define i.i=0
  Define file.i=0
  
   ;hardcoded settings:
  tiny_screen_objects\tiny_arcade_frame_path="GFX\arcade_frame.png"
  tiny_screen_objects\tiny_back_ground_0_path="GFX\water.png"
  tiny_screen_objects\tiny_back_ground_1_path="GFX\ship_wreck.png"
  tiny_screen_objects\tiny_game_logic_gfx_path="GFX\save_area.png"
  tiny_game_logic\tiny_background_song_path="SND\background.ogg"
  tiny_game_logic\tiny_player_move_sound_path="SND\ping_pong1.ogg"
  tiny_game_logic\tiny_object_to_rescue_path="GFX\rescue.png"
  tiny_game_logic\tiny_player_life_gfx_path="GFX\heart.png"
  tiny_screen_objects\tiny_game_over_gfx_path="GFX\game_over.png"
  tiny_game_logic\tiny_player_object_path="GFX\boat.png"
  tiny_screen_objects\tiny_pause_gfx_path="GFX\pause.png"
  tiny_game_logic\tiny_obstacle_path="GFX\obstacle.png"
  tiny_game_logic\tiny_object_to_rescue_move_sound_path="SND\ping_pong3.ogg"
  tiny_game_logic\tiny_object_to_rescue_dead_sound_path="SND\ping_pong2.ogg"
  tiny_game_logic\tiny_obstacle_move_sound_path="SND\ping_pong3.ogg"
  tiny_game_logic\tiny_obstacle_move_sound_path="SND\foe.ogg"

  
;so we got the basics, we go for de default gfx presentation

;load the arcade frame:
tiny_screen_objects\tiny_arcade_frame_id=LoadImage(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_arcade_frame_path)
tiny_screen_objects\tiny_back_ground_0_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_back_ground_0_path,#PB_Sprite_AlphaBlending)
tiny_screen_objects\tiny_back_ground_1_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_back_ground_1_path,#PB_Sprite_AlphaBlending)
tiny_screen_objects\tiny_game_logic_gfx_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_game_logic_gfx_path,#PB_Sprite_AlphaBlending)
tiny_game_logic\tiny_object_to_rescue_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_object_to_rescue_path,#PB_Sprite_AlphaBlending)
tiny_game_logic\tiny_player_object_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_player_object_path,#PB_Sprite_AlphaBlending)
tiny_game_logic\tiny_player_life_gfx_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_player_life_gfx_path,#PB_Sprite_AlphaBlending)
tiny_screen_objects\tiny_game_over_gfx_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_game_over_gfx_path,#PB_Sprite_AlphaBlending)
tiny_screen_objects\tiny_pause_gfx_id=LoadSprite(#PB_Any,tiny_directory_path+tiny_screen_objects\tiny_pause_gfx_path,#PB_Sprite_AlphaBlending)


tiny_game_logic\tiny_background_song_id=LoadSound(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_background_song_path)
tiny_game_logic\tiny_player_move_sound_id=LoadSound(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_player_move_sound_path)
tiny_game_logic\tiny_object_to_rescue_move_sound_id=LoadSound(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_object_to_rescue_move_sound_path)
tiny_game_logic\tiny_object_to_rescue_dead_sound_id=LoadSound(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_object_to_rescue_dead_sound_path)
tiny_game_logic\tiny_obstacle_move_sound_id=LoadSound(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_obstacle_move_sound_path)



;here a special for the obstacle :

For i.i=0 To tiny_game_logic\tiny_obstacle_max ;we load the maximum of obstacles!
  tiny_game_logic\tiny_obstacle_id[i.i]=LoadSprite(#PB_Any,tiny_directory_path+tiny_game_logic\tiny_obstacle_path,#PB_Sprite_AlphaBlending)
   tiny_game_logic\tiny_obstacle_pos_y[i.i]=tiny_game_logic\tiny_obstacle_default_pos_y
Next
tiny_game_logic\tiny_obstacle_pos_x[0]=Random(ScreenWidth()/3)
tiny_game_logic\tiny_obstacle_pos_x[0]+32 ;keep it in screen
tiny_game_logic\tiny_obstacle_pos_x[1]=Random(ScreenWidth()/3)+ScreenWidth()/3
tiny_game_logic\tiny_obstacle_pos_x[2]=Random(ScreenWidth()/3)+ScreenWidth()/3+ScreenWidth()/3-32
tiny_game_logic\tiny_right_border_save_area=ScreenWidth()-32


T_GFX_DATA() 


file.i=ReadFile(#PB_Any,tiny_directory_path+tiny_save_path)

If IsFile(file.i)=0
ProcedureReturn #False    
EndIf

tiny_game_logic\tiny_player_score_top=Val(ReadString(file.i))
CloseFile(file.i)
EndProcedure


Procedure T_WINDOW()

tiny_window\window_h=480
tiny_window\window_w=640
tiny_window\window_x=320
tiny_window\window_y=320
tiny_window\window_flags=#PB_Window_ScreenCentered|#PB_Window_SystemMenu


If ExamineDesktops()=0
  
  T_ERROR(#ERR_HOST_SYSTEM)
  
EndIf


tiny_window\window_id=OpenWindow(#PB_Any,tiny_window\window_x,tiny_window\window_y,tiny_window\window_w,tiny_window\window_h,"TINY GAME ENGINE",tiny_window\window_flags)


If IsWindow(tiny_window\window_id)=0
  
  T_ERROR(#ERR_OPEN_WINDOW)
  
EndIf



;we get a window, so we go for the game screen

tiny_window\window_screen_id=OpenWindowedScreen(WindowID(tiny_window\window_id),80,80,480,320)

If tiny_window\window_screen_id=0
  
  T_ERROR(#ERR_OPEN_GAME_SCREEN)
  
EndIf 

T_GAME_DEFAULT_VALUES()

T_GAME_SETUP()

EndProcedure