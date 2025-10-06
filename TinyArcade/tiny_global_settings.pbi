;here all global settings for the tiny game system



Global tiny_directory_path.s=GetCurrentDirectory()

Structure tiny_window
  window_x.i
  window_y.i
  window_w.i
  window_h.i
  window_id.i
  window_flags.i
  window_screen_id.i
  window_screen_w.i
  window_screen_h.i
  window_event.i
  
  
EndStructure

Structure tiny_screen_objects
  
  tiny_back_ground_0_id.i
  tiny_back_ground_0_path.s
  tiny_back_ground_1_id.i
  tiny_back_ground_1_path.s
  tiny_front_id.i
  tiny_front_paths.s
  tiny_arcade_frame_id.i
  tiny_arcade_frame_path.s
  tiny_game_logic_gfx_id.i
  tiny_game_logic_gfx_path.s
  tiny_game_over_gfx_path.s
  tiny_game_over_gfx_id.i
  tiny_pause_gfx_path.s
  tiny_pause_gfx_id.i
  
EndStructure

Structure tiny_game_logic
  tiny_left_border_save_area.i
  tiny_right_border_save_area.i
  tiny_player_object_pos_x.i
  tiny_player_object_pos_y.i
  tiny_player_object_id.i
  tiny_player_object_path.s
  tiny_player_move_step_x.i
  tiny_player_control_delay.i
  tiny_player_control_start_value.i
  tiny_player_control_dec.i
  tiny_player_score.i
  tiny_player_score_top.i
  tiny_player_lifes.i
  tiny_player_life_gfx_id.i
  tiny_player_life_gfx_path.s
  tiny_player_life_gfx_w.i
  tiny_player_object_w.i
  tiny_player_object_h.i
  tiny_player_move_sound_id.i
  tiny_player_move_sound_path.s
  tiny_player_boat_is_emty.i
  tiny_object_to_rescue_dead_zone_y.i
  tiny_object_to_rescue_pos_x.i
  tiny_object_to_rescue_pos_y.i
  tiny_object_to_rescue_default_pos_x.i
  tiny_object_to_rescue_default_pos_y.i
  tiny_object_to_rescue_move_step_y.i
  tiny_object_to_rescue_path.s
  tiny_object_to_rescue_id.i
  tiny_object_to_rescue_dead_sound_path.s
  tiny_object_to_rescue_dead_sound_id.i
  tiny_background_song_path.s
  tiny_background_song_id.i
  tiny_object_to_rescue_move_sound_id.i
  tiny_object_to_rescue_move_sound_path.s
  tiny_object_to_rescue_control_delay.i
  tiny_object_to_rescue_control_start_value.i
  tiny_object_to_rescue_control_dec.i
  tiny_object_to_rescue_h.i
  tiny_object_to_rescue_w.i
  tiny_object_to_rescue_bound_to_player.i
  tiny_obstacle_path.s
  tiny_obstacle_max.i
  tiny_obstacle_id.i[3]  ;0...2!!!
  tiny_obstacle_control_delay.i
  tiny_obstacle_control_start_value.i
  tiny_obstacle_control_dec.i
  tiny_obstacle_move_sound_id.i
  tiny_obstacle_move_sound_path.s
  tiny_obstacle_move_step.i
  tiny_obstacle_pos_x.i[3]
  tiny_obstacle_pos_y.i[3]
  tiny_obstacle_default_pos_x.i
  tiny_obstacle_default_pos_y.i
  tiny_obstacle_remove_zone_y.i
  EndStructure
  
  
  Structure tiny_beat 
    tiny_beat_actual.i
    tiny_beat_counter.i
    tiny_beat_size.i
    tiny_beat_start.i
  EndStructure

  Global tiny_window.tiny_window
  Global tiny_screen_objects.tiny_screen_objects
  Global tiny_game_logic.tiny_game_logic
  Global tiny_beat.tiny_beat
  Global tiny_game_mode.i=0
  Global tiny_keyboard.i=00
  Global tiny_save_path.s="SCORE\score"
  Define ok.i=0
  
  ;basic lib setup
  UsePNGImageDecoder()
  UseOGGSoundDecoder()
  tiny_keyboard.i=InitKeyboard()
  
  If InitSound()=0
    ok.i=MessageRequester("ERROR SOUNDSYSTEM","NO SOUND HARDWARE FOUND/NO VALID SOUND SYSTEM"+Chr(13)+"CONTINUE?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)
    
    If ok.i=#PB_MessageRequester_No
      End  
    EndIf
  EndIf

  
  
 
  
 
  
  
  
  
  
  
  
  
  
  