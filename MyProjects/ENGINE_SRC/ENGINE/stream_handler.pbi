;here we focus on stream routines 



Declare E_TELE_PORT_EFFECT()
Declare E_CHECK_FOR_RESPAWN_AREA() 
Declare E_NPC_FREE_RESOURCES() 
  
  
  Procedure E_REBUILD_OBJECT_GFX_SIZE()
    
    If world_object()\object_backup_size=#False
    ProcedureReturn #False  
    EndIf
    
    world_object()\object_w=world_object()\object_backup_size_w
    world_object()\object_h=world_object()\object_backup_size_h
    ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_w,world_object()\object_h)
    
    If world_object()\object_random_size_on_start<>0 
      ZoomSprite(world_object()\object_gfx_id_default_frame,(world_object()\object_w*world_object()\object_random_size_on_start/100)+1,(world_object()\object_h*world_object()\object_random_size_on_start/100)+1)
    EndIf
    
  EndProcedure
  


  
  Procedure E_REBUILD_POSITION_AFTER_PIXEL_LIFETIME_XY()
;defined position reset system for objects, activated by different trigger values or called from special routines 
  

  If world_object()\object_reset_position_on_pixel_count=#False
  ProcedureReturn #False  
EndIf

E_TELE_PORT_EFFECT()
  world_object()\object_life_time_pixel_count_x=0
  world_object()\object_life_time_pixel_count_y=0
  world_object()\object_x=world_object()\object_origin_position_x
  world_object()\object_y=world_object()\object_origin_position_y
  
  If world_object()\object_use_transparency_back_up=#True
  world_object()\object_transparency=world_object()\object_transparency_back_up  
  EndIf
  E_REBUILD_OBJECT_GFX_SIZE()
   
EndProcedure



Procedure E_REBUILD_POSITION_XY()
;defined position reset system for objects, activated by different trigger values or called from special routines 
  

  If world_object()\object_reset_position_on_timer=#False And world_object()\object_area_loop_horizont=#False And world_object()\object_area_loop_vertical=#False  And world_object()\object_reset_position_on_fade_out=#False 
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_reset_position_on_fade_out=#True
    If world_object()\object_transparency>1
    ProcedureReturn #False  
    EndIf
    
  EndIf
  
 If world_object()\object_use_position_back_up=#True
  world_object()\object_x=world_object()\object_origin_position_x
  world_object()\object_y=world_object()\object_origin_position_y
EndIf

  
  If world_object()\object_use_transparency_back_up=#True
  world_object()\object_transparency=world_object()\object_transparency_back_up  
  EndIf
  E_REBUILD_OBJECT_GFX_SIZE()
   
EndProcedure



Procedure  E_REBUILD_POSITION_FROM_BACKUP()
  ;use this to prevent objects get stuck in level after  checkpoint reload 
  ;this is a workaround used mostly for gravity objects, because the get stuck after a checkpoint reload, if they are on ground when checkpoint saved
  
  
  
  If world_object()\object_use_position_back_up=#False 
  ProcedureReturn #False  
  EndIf
  

  world_object()\object_x=world_object()\object_origin_position_x
  world_object()\object_y=world_object()\object_origin_position_y
  
  If world_object()\object_use_transparency_back_up=#True
  world_object()\object_transparency=world_object()\object_transparency_back_up  
  EndIf
  E_REBUILD_OBJECT_GFX_SIZE()
  
EndProcedure


Procedure.b E_CHECK_IF_OBJECT_IN_EFFECT_AREA()
  
  ;attention use this only for objects you want to emit only, if in area
  ;use this for some effects like attentions to player
  
  If world_object()\object_use_effect_area=#False
  ProcedureReturn #True 
  EndIf
  

  
    If Abs((world_object()\object_x+e_engine\e_world_offset_x)-player_statistics\player_pos_x)<world_object()\object_effect_area_w
    
    If Abs((world_object()\object_y+e_engine\e_world_offset_y)-player_statistics\player_pos_y)<world_object()\object_effect_area_h
    
      ProcedureReturn #True
      
    EndIf
    
  EndIf
  
  
  ProcedureReturn #False
  
  
EndProcedure




Procedure.b E_CHECK_IF_OBJECT_IN_ALLERT_AREA()
  
  ;outsourced from main loop to make it more readable and better handling for extensions
 

  
  
  ;check for allert timer is active:
  If world_object()\object_allert_on_player=#True Or world_object()\object_use_own_trigger_zone=#True ; world_object()\object_use_own_trigger_zone = posibility to set individual trigger zones, setting is done like allert_on_player
    
    If world_object()\object_allert_stay=#True

      If e_engine_heart_beat\beats_since_start<world_object()\object_allert_overide_timer_stop
        If world_object()\object_stop_scroll_after_allert=#True And           engine_launcher\engine_true_screen=#False
         e_engine\e_engine_no_scroll_margin=WindowWidth(#ENGINE_WINDOW_ID)
         e_engine\e_engine_scroll_map=#False  
       EndIf
       
        If world_object()\object_stop_scroll_after_allert=#True And           engine_launcher\engine_true_screen=#True
         e_engine\e_engine_no_scroll_margin=ScreenWidth()
         e_engine\e_engine_scroll_map=#False  
        EndIf
        
        ProcedureReturn world_object()\object_allert_on_player  ;we are on allert
      EndIf
     
     
    EndIf
    
    
  EndIf
  
  
  world_object()\object_allert_stay=#False
  
 
  
  If world_object()\object_is_active=#False
    world_object()\object_allert_stay=#False
   
     ProcedureReturn #False  
  EndIf
  
  ;-------------------------------------------------------     
  
  
  If world_object()\object_allert_on_player=#False Or e_engine\e_allert_fov_x=0 And e_engine\e_allert_fov_y=0 
    
;           If world_object()\object_allert_stay=#False
;         E_SOUND_CORE_CONTROLLER(#ENGINE_SOUND_PLAY_ON_ALLERT)
;         EndIf
    world_object()\object_allert_stay=#True
      ProcedureReturn  world_object()\object_allert_stay                                                                    ;we are on allert anyway (object DNA values turn on/off this switch)
  EndIf
  

  
  ;object uses allert, so we reset the allert situation
  
 
  If world_object()\object_use_own_trigger_zone=#False 
  If Abs((world_object()\object_x+e_engine\e_world_offset_x)-player_statistics\player_pos_x) <e_engine\e_allert_fov_x
    
    If Abs((world_object()\object_y+e_engine\e_world_offset_y)-player_statistics\player_pos_y)<e_engine\e_allert_fov_y
      
;             If world_object()\object_allert_stay=#False
;         E_SOUND_CORE_CONTROLLER(#ENGINE_SOUND_PLAY_ON_ALLERT)
;         EndIf
     
      world_object()\object_allert_stay=#True
        
      If world_object()\object_show_boss_bar=#True
        boss_bar\boss_bar_is_active=#True  
      EndIf
      
    Else
      
      world_object()\object_allert_stay=#False
       
    If world_object()\object_show_boss_bar=#False
      world_object()\object_hp=world_object()\object_hp_max
     
    EndIf
    
     world_object()\object_is_in_fight=#False
   
       
;        If world_object()\object_show_boss_bar=#True
;       boss_bar\boss_bar_is_active=#False  
;     EndIf
      
    EndIf
    
  EndIf
EndIf

If world_object()\object_use_own_trigger_zone=#True
  If Abs((world_object()\object_x+e_engine\e_world_offset_x)-player_statistics\player_pos_x) <world_object()\object_own_trigger_zone_w
    
    If Abs((world_object()\object_y+e_engine\e_world_offset_y)-player_statistics\player_pos_y)<world_object()\object_own_trigger_zone_h
      
;           If world_object()\object_allert_stay=#False
;         E_SOUND_CORE_CONTROLLER(#ENGINE_SOUND_PLAY_ON_ALLERT)
;         EndIf

      
      world_object()\object_allert_stay=#True
     
      If world_object()\object_show_boss_bar=#True
        boss_bar\boss_bar_is_active=#True  
      EndIf
      
    Else
      
  
      world_object()\object_allert_stay=#False
       
    If world_object()\object_show_boss_bar=#False
      world_object()\object_hp=world_object()\object_hp_max
     
    EndIf
    
     world_object()\object_is_in_fight=#False
   
       
;        If world_object()\object_show_boss_bar=#True
;       boss_bar\boss_bar_is_active=#False  
;     EndIf
      
    EndIf
    
  EndIf
  
EndIf

  
  


If world_object()\object_allert_overide_by_player_attack=#True
  
  If e_engine_heart_beat\beats_since_start<world_object()\object_allert_overide_timer_stop
    world_object()\object_allert_stay=#True 
    world_object()\object_is_in_fight=#False
  Else
    world_object()\object_allert_overide_by_player_attack=#False
  EndIf
EndIf

If world_object()\object_allert_stay=#True
  
  If world_object()\object_life_timer_on_activation>0
    world_object()\object_life_time=world_object()\object_life_timer_on_activation
    world_object()\object_end_of_life_time=e_engine_heart_beat\beats_since_start+world_object()\object_life_time
    world_object()\object_life_timer_on_activation=0
    
  EndIf
  
  If world_object()\object_random_rotate_on_activation<>0
    world_object()\object_random_rotate=Random(world_object()\object_random_rotate_on_activation)
    world_object()\object_random_rotate_on_activation=0  
    world_object()\object_rotate=world_object()\object_random_rotate
  EndIf
  
    
 E_SOUND_CORE_CONTROLLER(#ENGINE_SOUND_PLAY_ON_ALLERT)
  world_object()\object_allert_overide_timer_stop=e_engine_heart_beat\beats_since_start+world_object()\object_allert_overide_timer
 
EndIf

     
     
      


  ProcedureReturn world_object()\object_allert_stay
  
  
EndProcedure



Procedure.b E_CHECK_IF_OBJECT_IN_GFX_AREA()
  
  ;outsourced from main loop to make it more readable and better handling for extensions
  
   
       
  world_object()\object_is_in_gfx_area=#False
  world_object()\object_is_in_area_shadow=#False;no shadows in area, we use  the performanceguard routine to handle the field of view, this is used for variuos perfomrance tweaks (shadows, spritequality...)
 
    If world_object()\object_full_screen=#True Or world_object()\object_is_scroll_back_ground=#True
      world_object()\object_is_in_gfx_area=#True  
      ProcedureReturn world_object()\object_is_in_gfx_area
  EndIf
  

If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w)<1
  world_object()\object_remove_from_list=#True   ;for this game we do not have any objects outside left screen margin  
  ProcedureReturn #False
EndIf
    
    If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w) >(0-e_gfx_fov.f) And  (world_object()\object_x+e_engine\e_world_offset_x)<(v_screen_w.f+e_gfx_fov.f)
      
      If (world_object()\object_y+e_engine\e_world_offset_y +world_object()\object_h)>(0-e_gfx_fov.f) And ( world_object()\object_y+e_engine\e_world_offset_y)<(v_screen_h.f+e_gfx_fov.f)
        
       world_object()\object_is_in_gfx_area=#True
       world_object()\object_is_in_area_shadow=#True  
  
     EndIf
     
      
    EndIf
    
    If world_object()\object_is_in_gfx_area=#False
      If world_object()\object_is_weapon=#True
        world_object()\object_is_active=#False
        world_object()\object_remove_from_list=#True
        
      EndIf
         E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    EndIf
    ;-----------------------------------------
    
 
     ;--
    
    ;-- default: we relase objects out of left screen
   If e_engine_game_type\engine_use_left_barier=#True And world_object()\object_turn_on_left_screen=#False
    If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w)<0
      world_object()\object_is_in_gfx_area=#False
      world_object()\object_remove_from_list=#True
  
    EndIf
  EndIf
  
     ;--something special for "left barier feature" added 23112022: objects whichg turn on left screen position is reseted to a valid value
   If e_engine_game_type\engine_use_left_barier=#True And world_object()\object_turn_on_left_screen=#True
    If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w)<0
      world_object()\object_x+world_object()\object_w   
    EndIf
  EndIf
  ;-----------------------

  
    
  ProcedureReturn  world_object()\object_is_in_gfx_area
  
EndProcedure


Procedure.b E_CHECK_IF_OBJECT_IN_INDEX_AREA()
  
  ;outsourced from main loop to make it more readable and better handling for extensions
  
  
  
    If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w) >(0-e_engine\e_fov_x) And  (world_object()\object_x+e_engine\e_world_offset_x)<(v_screen_w.f+e_engine\e_fov_x)
      
      If (world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_h)>(0-e_engine\e_fov_y) And ( world_object()\object_y+e_engine\e_world_offset_y)<(v_screen_h.f+e_engine\e_fov_y)
        
        ProcedureReturn #True
                  
      EndIf
      
    EndIf
    
    ProcedureReturn #False
    
EndProcedure


Procedure E_AREA_TIMED_RESET_X_Y()
 
  
  If world_object()\object_reset_position_time_counter>e_engine_heart_beat\beats_since_start Or world_object()\object_reset_position_on_timer=#False
  ProcedureReturn #False
  EndIf
  
      world_object()\object_reset_position_time_counter=e_engine_heart_beat\beats_since_start+world_object()\object_reset_position_time_ms
      E_REBUILD_POSITION_XY()
  
  
EndProcedure



Procedure E_AREA_LOOP_HANDLER()
  ;rest and set objets if arealoop is set
  
  

  
  ;does not work!
  
  If world_object()\object_area_loop_horizont=#False And world_object()\object_area_loop_vertical=#False
  ProcedureReturn #False   ;nothing to do  
  EndIf
  
  ;here we go:


    
    If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w)>(v_screen_w.f+e_gfx_fov.f)
      E_REBUILD_POSITION_XY() 
     ProcedureReturn #False
    EndIf
    
    If (world_object()\object_x+e_engine\e_world_offset_x)<e_gfx_fov
      E_REBUILD_POSITION_XY() 
     ProcedureReturn #False
    EndIf
    

;-------------------------------------------------  
  

    If (world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_h)>(v_screen_h.f+e_gfx_fov.f)
     E_REBUILD_POSITION_XY() 
 ProcedureReturn #False
    EndIf
    
    If (world_object()\object_y+e_engine\e_world_offset_y)<e_gfx_fov.f
      E_REBUILD_POSITION_XY() 
      ProcedureReturn #False  
    EndIf
    

  
  
EndProcedure



Procedure.b E_CHECK_IF_OBJECT_IN_STREAM_AREA()
  
  ;outsourced from main loop to make it more readable and better handling for extensions
  
  
  world_object()\object_is_in_stream_area=#False
  
  If (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_w) >(0-e_engine\e_fov_x) And  (world_object()\object_x+e_engine\e_world_offset_x)<(v_screen_w.f+e_engine\e_fov_x)
    
    If (world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_h)>(0-e_engine\e_fov_y) And ( world_object()\object_y+e_engine\e_world_offset_y)<(v_screen_h.f+e_engine\e_fov_y)
      
      world_object()\object_is_in_stream_area=#True 
      
    EndIf
    
  EndIf
  
  
  
  If world_object()\object_is_in_stream_area=#False
    If world_object()\object_respawn_timer_target<e_engine_heart_beat\beats_since_start
      world_object()\object_respawn_timer_target=e_engine_heart_beat\beats_since_start+world_object()\object_respawn_timer
    EndIf
  EndIf
  
  If world_object()\object_full_screen=#True Or world_object()\object_is_scroll_back_ground=#True
    world_object()\object_is_in_stream_area=#True 
  EndIf
  
  If world_object()\object_area_no_limit=#True
    world_object()\object_is_in_stream_area=#True 
  EndIf
  
  
  ProcedureReturn world_object()\object_is_in_stream_area
  
  
  
EndProcedure
      
      
      
      
      Procedure E_FREE_SGFX()
        ;remove SGFX, if object is removed
        
        If world_object()\object_activate_global_flash=#True
        e_engine_global_effects\global_effect_flash_light_status=#FLASH_LIGHT_OFF  
        EndIf
        
        
      EndProcedure
      


Procedure E_FREE_SOUND()
  

  If IsSound(world_object()\object_sound_on_change_id)
    StopSound(world_object()\object_sound_on_change_id)
       FreeSound(world_object()\object_sound_on_change_id)
  EndIf
  
  
  If IsSound(world_object()\object_sound_on_restore_id)
    StopSound(world_object()\object_sound_on_restore_id)
  FreeSound(world_object()\object_sound_on_restore_id)
  EndIf
 
  If IsSound(world_object()\object_sound_id)
    StopSound(world_object()\object_sound_id)
     FreeSound(world_object()\object_sound_id)
   EndIf
   
   If IsSound(world_object()\object_emit_sound_id)
     StopSound(world_object()\object_emit_sound_id)
   FreeSound(world_object()\object_emit_sound_id)  
   EndIf
   
   
   If IsSound(world_object()\object_sound_on_treasure_found_id)
     StopSound(world_object()\object_sound_on_treasure_found_id)
  FreeSound(world_object()\object_sound_on_treasure_found_id)  
EndIf

If IsSound(world_object()\object_sound_on_talk_id)
  StopSound(world_object()\object_sound_on_talk_id)
  FreeSound(world_object()\object_sound_on_talk_id)  
EndIf

If IsSound(world_object()\object_sound_on_jump_id)
  StopSound(world_object()\object_sound_on_jump_id)
 FreeSound(world_object()\object_sound_on_jump_id)  
 EndIf

 If  IsSound(world_object()\object_sound_on_collision_id)
   StopSound(world_object()\object_sound_on_collision_id)
     FreeSound(world_object()\object_sound_on_collision_id)
   EndIf
   
  
   If IsSound(world_object()\object_sound_on_random_id)
     StopSound(world_object()\object_sound_on_random_id)
       FreeSound(world_object()\object_sound_on_random_id)
  EndIf
  

  
  If  IsSound(world_object()\object_sound_on_rotate_id)
    StopSound(world_object()\object_sound_on_rotate_id)
    FreeSound(  world_object()\object_sound_on_rotate_id)
  EndIf
  
  
  If  IsSound(world_object()\object_sound_on_move_id)
    StopSound(world_object()\object_sound_on_move_id)
        FreeSound(world_object()\object_sound_on_move_id)
  EndIf
  
  If  IsSound(world_object()\object_sound_on_create_id)
    StopSound(world_object()\object_sound_on_create_id)
       FreeSound(world_object()\object_sound_on_create_id)
     EndIf
     
     
     If IsSound(world_object()\object_create_child_sound_id)
       StopSound(world_object()\object_create_child_sound_id)
     FreeSound(world_object()\object_create_child_sound_id)
   EndIf
  
   If IsSound(world_object()\object_random_hide_away_sound_id)
     StopSound(world_object()\object_random_hide_away_sound_id)
      FreeSound(world_object()\object_random_hide_away_sound_id)
  EndIf
  
  If  IsSound(world_object()\object_alternative_create_sound_id)
    StopSound(world_object()\object_alternative_create_sound_id)
  FreeSound(world_object()\object_alternative_create_sound_id)  
  EndIf
  
  If IsSound(world_object()\object_sound_on_activate_id)
    StopSound(world_object()\object_sound_on_activate_id)
  FreeSound(world_object()\object_sound_on_activate_id)  
EndIf

If IsSound( world_object()\object_boss_music_id)
  StopSound(world_object()\object_boss_music_id)
FreeSound(world_object()\object_boss_music_id)  
EndIf

If IsSound(world_object()\object_sound_on_allert_id)
  StopSound(world_object()\object_sound_on_allert_id)
FreeSound(world_object()\object_sound_on_allert_id)  
EndIf

  
EndProcedure



Procedure E_FREE_GFX()
  
  Define _frame_id.l=0,_max_anim_frames.l=127
  ;free memory of single frames/gfx objects, not anims...
  

  If IsSprite(world_object()\object_shadow_gfx_id)
    FreeSprite(world_object()\object_shadow_gfx_id)  
  EndIf
  
  If IsSprite(world_object()\object_hit_box_gfx_id)
    FreeSprite(world_object()\object_hit_box_gfx_id)  
  EndIf
  
  If IsSprite(world_object()\object_glass_effect_gfx_id)
    FreeSprite(world_object()\object_glass_effect_gfx_id)  
  EndIf
  
  
  If IsSprite(world_object()\object_gfx_id_default_frame)
    FreeSprite(world_object()\object_gfx_id_default_frame)  
  EndIf
  
  If IsSprite(world_object()\object_health_bar_back_id)
    FreeSprite(world_object()\object_health_bar_back_id)  
  EndIf
  
  If IsSprite(world_object()\object_health_bar_id)
    FreeSprite(world_object()\object_health_bar_id)  
  EndIf
  
  
  If IsSprite(world_object()\object_danger_gfx_id)
    FreeSprite(world_object()\object_danger_gfx_id)  
  EndIf
  
  If IsSprite(world_object()\object_fight_effect_id)
    FreeSprite(world_object()\object_fight_effect_id)
  EndIf
  
  
  If IsSprite(world_object()\object_price_tag_id)
    FreeSprite(world_object()\object_price_tag_id)  
  EndIf
  
  If IsSprite(world_object()\object_stamp_gfx_id)
    FreeSprite(world_object()\object_stamp_gfx_id) 
    
  EndIf
  
  
    For _frame_id.l=0 To _max_anim_frames.l ;here we free the anim frame memory
    
    If IsSprite(world_object()\object_gfx_id_frame_down[_frame_id.l])
      FreeSprite(world_object()\object_gfx_id_frame_down[_frame_id.l])
     
    EndIf
    
    
    
    If IsSprite(world_object()\object_gfx_id_frame_up[_frame_id.l])
      FreeSprite(world_object()\object_gfx_id_frame_up[_frame_id.l])
      
    EndIf
    
    
    If IsSprite(world_object()\object_gfx_id_frame_left[_frame_id.l])
      FreeSprite(world_object()\object_gfx_id_frame_left[_frame_id.l])
    
    EndIf
    
    If IsSprite(world_object()\object_gfx_id_frame_right[_frame_id.l])
      FreeSprite(world_object()\object_gfx_id_frame_right[_frame_id.l])
      
    EndIf
    
    
    If IsSprite(world_object()\object_gfx_id_frame_anim_default[_frame_id.l])
      FreeSprite(world_object()\object_gfx_id_frame_anim_default[_frame_id.l])
      
    EndIf  
    
  Next
  


EndProcedure

Procedure E_SET_SITUATION_BEFORE_RELEASE()
  ;here we reset/set situations before we finaly release object and  data
  
  If world_object()\object_is_boss_guard=#True  ;if it is boss guard, or other object (can be used for some quest/waves/...) 
  e_engine\e_count_active_boos_guards-1  ;less, one more is killed
  EndIf
  
  If world_object()\object_use_enemy_maximum=#True
    If e_engine\e_enemy_count>0
     e_engine\e_enemy_count-1
    EndIf
    
  EndIf
  
  
EndProcedure


 
Procedure E_RELEASE_OBJECT_FROM_LIST()
  
  
  ;remove objects, which marked as  "remove" 
  
  Define _frame_id.i=0,_max_anim_frames.i=32
  
  
 If ListSize(world_object())<1
   ProcedureReturn #False
 EndIf
 
  
  
  If world_object()\object_remove_from_list=#False 
    ProcedureReturn #False  
  EndIf
  

  If world_object()\object_is_reaper=#True
   e_engine\e_reaper_on_screen=#False   ;only one reaper on screen! there is only one reaper!
 EndIf
  
  
  If world_object()\object_is_boss
    boss_bar\boss_bar_is_active=#False
    world_object()\object_boss_music_is_playing=#False
    e_engine\e_pointer_sound_boss=0
  EndIf
  
  
  
  
  E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
  
  If world_object()\object_sound_is_boss=#True
       E_SOUND_CONTINUE_GLOBAL_SOUND()
  EndIf
  
  If world_object()\object_is_enemy<>0
    If e_engine\e_enemy_count>0
      e_engine\e_enemy_count-1  
    EndIf
  EndIf
  
  
  E_FREE_SOUND()
  E_FREE_GFX()
  E_FREE_SGFX()
  ;----------------------------------------------------
  

  
  
      For _frame_id.i=0 To _max_anim_frames.i  ;here we free the anim frame memory

      If IsSprite(world_object()\object_gfx_id_frame_down[_frame_id.i])
        FreeSprite(world_object()\object_gfx_id_frame_down[_frame_id.i])
      EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_up[_frame_id.i])
        FreeSprite(world_object()\object_gfx_id_frame_up[_frame_id.i])
      EndIf
      
      
      If IsSprite(world_object()\object_gfx_id_frame_left[_frame_id.i])
        FreeSprite(world_object()\object_gfx_id_frame_left[_frame_id.i])
      EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_right[_frame_id.i])
        FreeSprite(world_object()\object_gfx_id_frame_right[_frame_id.i])
      EndIf
      
      
      If IsSprite(world_object()\object_gfx_id_frame_anim_default[_frame_id.i])
        FreeSprite(world_object()\object_gfx_id_frame_anim_default[_frame_id.i])
      EndIf  
      
    Next
    
    
    E_SET_SITUATION_BEFORE_RELEASE()
    

    
     DeleteElement(world_object())     ;remove the object from list


EndProcedure





; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 218
; FirstLine = 199
; Folding = -
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; CPU = 1
; DisableDebugger
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant