;here we store all routines which chnage the object on screen (like emitter, and alternative object)

Declare E_ANALYSE_LOOT()

Declare E_RANDOM_HIDE_AWAY_CONTROLLER()
Declare E_SETUP_AI(_arg.s)
Declare E_CHANGE_DIRECTION()
Declare E_TIMER_ADD()
Declare E_CORRECT_PLAYER_POSITION_ON_TRANSPORTER()





Procedure E_SHOW_XP_ON_PICK_UP()
   
;    player_statistics\player_xp_count_to_zero=world_object()\object_add_xp_on_collision
;    e_player_warning\e_player_warning_text_english="XP+ "+Str(world_object()\object_add_xp_on_collision)
;    e_player_warning\e_player_warning_text_german="XP+ "+Str(world_object()\object_add_xp_on_collision)
;    e_player_warning\e_player_warning_show=#True
;    e_player_warning\e_player_warning_show_time_max=ElapsedMilliseconds()+e_player_warning\e_player_warning_show_time/2
;    e_player_warning\e_player_warning_text_move_y_actual_pos=0

EndProcedure


Procedure E_WORLD_STATUS_CONTROLLER()
  ;here we handle some things like : open gate if boss is killed...

  
  If world_object()\object_use_status_controller=#False
  ProcedureReturn #False  
  EndIf
  
  
  Define _status_key_word.s=""
  Define *_object_id_back_up=0

  
  ;just backup the actual object
  *_object_id_back_up=@world_object()
 
  
  If *_object_id_back_up=0
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_hp>0
  ProcedureReturn #False  
  EndIf
  
  
 If Len(world_object()\object_open_gate_on_death)<1
  ProcedureReturn #False  
EndIf

_status_key_word.s=world_object()\object_open_gate_on_death

ResetList(world_object())

ForEach world_object()
  
  If _status_key_word.s=world_object()\object_internal_name  ;removes all objects with name=name
    world_object()\object_is_active=#False
    world_object()\object_do_not_save=#True
    world_object()\object_remove_from_list=#True
    If ChangeCurrentElement(world_object(),*_object_id_back_up)
    EndIf
    Break 

  EndIf
  
Next



 If ChangeCurrentElement(world_object(),*_object_id_back_up)

 EndIf

    
EndProcedure




Procedure E_WORLD_STATUS_CONTROLLER_PARENT_CHILD()
  ;here we handle some things like : parent is dead? kill the child

  
  If world_object()\object_use_status_controller_parent=#False
  ProcedureReturn #False  
  EndIf
  
  
  Define _status_key_word.s=""
  Define *_object_id_back_up=0

  
  ;just backup the actual object
  *_object_id_back_up=@world_object()
 
  
  If *_object_id_back_up=0
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_hp>0
  ProcedureReturn #False  
  EndIf
  
  
 If Len(world_object()\object_child_name)<1
  ProcedureReturn #False  
EndIf

_status_key_word.s=world_object()\object_child_name

ResetList(world_object())

ForEach world_object()
  
  If _status_key_word.s=world_object()\object_internal_name
    world_object()\object_remove_from_list=#True
    If ChangeCurrentElement(world_object(),*_object_id_back_up)
    EndIf

    Break
  EndIf
  
Next



 If ChangeCurrentElement(world_object(),*_object_id_back_up)

 EndIf

    
EndProcedure


Procedure E_SORT_MAP_OBJECTS_BY_LAYER()
  
 If  e_engine\e_sort_map_by_layer=#False
  ProcedureReturn #False  
 EndIf
  
    
  
  If ListSize(world_object())<1
    e_engine\e_sort_map_by_layer=#False
    ProcedureReturn #False  
  EndIf
  
   SortStructuredList(world_object(),#PB_Sort_Ascending,OffsetOf(world_objects\object_layer),TypeOf(world_objects\object_layer))
   e_engine\e_sort_map_by_layer=#False
   
EndProcedure


Procedure E_SORT_MAP_OBJECTS_BY_Y()
  
  ;for some isometric ? We use a modified copy of the origin y position (virtual y for object that use the isometric flag) virtual y = y if isometric flag is set or  0 if unset, so the object is always drawn right.
  ;this works for all objects and situations, without an complex algo/calculation of position for each object
  
  If e_engine\e_iso_mode<1
  ProcedureReturn #False  
  EndIf
  
  
  If ListSize(world_object())<1
       ProcedureReturn #False  
  EndIf
  
  SortStructuredList(world_object(),#PB_Sort_Ascending,OffsetOf(world_objects\object_virtual_y),TypeOf(world_objects\object_virtual_y))

EndProcedure


Procedure E_LEVEL_UP_EFFECT()
  ;some effects object_level up:
  
  If player_statistics\player_is_level_up=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_create_on_level_up<>#True
  ProcedureReturn #False  
  EndIf
  
 
  E_STREAM_LOAD_SPRITE(#E_ADD_LEVEL_UP_EFFECT)
  player_statistics\player_is_level_up=#False

  
EndProcedure


Procedure E_SET_GLOBAL_EFFECT_ON_OBJECT()
  
  
  If e_engine_global_effects\global_effect_name=""
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_use_global_effect=#False
    ProcedureReturn #False
  EndIf
      
      ;reset to valid state!
      world_object()\object_use_global_effect=#False
      
      E_STREAM_LOAD_SPRITE(#E_ADD_GLOBAL_EFFECT_TO_OBJECT)
      
  
EndProcedure


Procedure E_SET_EMITTER_OBJECT_SET_NEXT()
  
  If e_engine\e_enemy_maximum>0
    
    If e_engine\e_enemy_count>e_engine\e_enemy_maximum
      ProcedureReturn #False
    EndIf
    
    
  EndIf
  
      
    If  e_engine\e_frame_target>e_engine\e_global_fps
           ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf
  
  If world_object()\object_emitter_use_max_objects=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_is_active=#False ;Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False 
    ProcedureReturn #False  
  EndIf
  
    If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
     ProcedureReturn #False
  EndIf
  
  

  

    If world_object()\object_emitter_actual_object=>world_object()\object_emitter_max_objects
       ProcedureReturn #False  
    EndIf
    
    world_object()\object_emitter_actual_object+1
    
      If world_object()\object_use_random_pause<>0
    e_pause_for_random_action_actual_time.i=e_engine_heart_beat\beats_since_start+e_pause_for_random_action.i
  EndIf
      
  E_STREAM_LOAD_SPRITE(#E_ADD_OBJECT_EMITTED_TO_MAP)

  
  
EndProcedure



Procedure E_SET_EMITTER_OBJECT_ON_TIMER()
  
  If e_engine\e_enemy_maximum>0
    
    If e_engine\e_enemy_count>e_engine\e_enemy_maximum
      world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer
      ProcedureReturn #False
    EndIf
 
  EndIf
 
      
    If  e_engine\e_frame_target>e_engine\e_global_fps
           ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
         EndIf
   
  If world_object()\object_is_active=#False Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False 
    ProcedureReturn #False  
  EndIf
  
  
       
  
  If world_object()\object_emitter_use_max_objects=#True
    E_SET_EMITTER_OBJECT_SET_NEXT()
  ProcedureReturn #False  
  EndIf
  

 
  
  If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
     ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_random_pause<>0
    e_pause_for_random_action_actual_time.i=e_engine_heart_beat\beats_since_start+e_pause_for_random_action.i
  EndIf

  E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_EMIT)
  E_STREAM_LOAD_SPRITE(#E_ADD_OBJECT_EMITTED_TO_MAP)
  
  
EndProcedure


Procedure  E_EMITTER_ON_JUMP()
  ;do we emit something when we jump?
  
  
  
  If world_object()\object_emit_on_jump=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_is_jumping=#False
    ProcedureReturn #False
  EndIf
  
  
  If Random(world_object()\object_emit_jump_value)>0  ;here we go if permanent emit the value in the object data is 0, otherwise its  >0
    ProcedureReturn #False   
  EndIf
  
  If world_object()\object_emit_jump_object_max>0
    world_object()\object_emit_jump_counter+1
    
    If world_object()\object_emit_jump_counter>world_object()\object_emit_jump_object_max
       ProcedureReturn #False
    EndIf
    
    
  EndIf
  
  
  E_STREAM_LOAD_SPRITE(#E_ADD_JUMP_EMIT_TO_MAP)
  
EndProcedure




Procedure  E_SET_EMITTER_OBJECT_ON_MOVE(_ran.i)
  ; we use same concept as for alternative gfx, but wiht one important change: we select the alternative on the fly and keep the parent object
  ;ATTENTION WE DO NOT CHECK IF SOURCE ENTRY IS VALID!
  
; world_object()\object_do_create_child=#False
;   
  
    
    If  e_engine\e_frame_target>e_engine\e_global_fps
           ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
      EndIf
  
  If world_object()\object_is_active=#False Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
     ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_random_pause<>0
    e_pause_for_random_action_actual_time.i=e_engine_heart_beat\beats_since_start+e_pause_for_random_action.i
  EndIf
  
  
  
  Select _ran.i
      
    Case 0
      world_object()\object_child_gfx_ai_path=world_object()\object_emit_on_move_ai42
      world_object()\object_do_create_child=#True
       
     
      
    
      
  EndSelect
  
  
  If Len(Trim(world_object()\object_child_gfx_ai_path))<1
    world_object()\object_do_create_child=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_do_create_child=#True
    
    If world_object()\object_play_sound_on_create_child=#True
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CHILD_CREATE)  
  EndIf
  
 
  
  
  E_STREAM_LOAD_SPRITE(#E_ADD_CHILD_TO_MAP)

  
  EndIf
  
    
EndProcedure


Procedure E_GET_HIT_EFFECT()
  If world_object()\object_is_active=#False Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
    ProcedureReturn #False
  EndIf
  
  ;we clone from E_GET_CHILD_ROUTINE
  world_object()\object_child_gfx_ai_path=world_object()\object_hit_effect_path
  world_object()\object_do_create_child=#True
  E_STREAM_LOAD_SPRITE(#E_ADD_CHILD_TO_MAP)

EndProcedure

Procedure E_TELE_PORT_EFFECT()
  If world_object()\object_use_teleport_effect=#False
  ProcedureReturn #False  
  EndIf
  
   ;we clone from E_GET_CHILD_ROUTINE
  world_object()\object_child_gfx_ai_path=world_object()\object_teleport_gfx_path
  world_object()\object_do_create_child=#True
  E_STREAM_LOAD_SPRITE(#E_ADD_CHILD_TO_MAP)
  
EndProcedure


Procedure E_CALL_DEAD()
  ;usefull for player object only...
  If world_object()\object_use_call_dead_timer=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_call_dead_timer_total<e_engine_heart_beat\beats_since_start
      world_object()\object_call_dead=#True
     EndIf
  
If world_object()\object_call_dead=#False
ProcedureReturn #False  
EndIf

If e_engine\e_reaper_on_screen=#True
world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer
world_object()\object_call_dead=#False
ProcedureReturn #False  
EndIf


world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer
world_object()\object_call_dead=#False

E_STREAM_LOAD_SPRITE(#E_ADD_DEAD_TO_MAP)
;important! reset dead timer!

  
EndProcedure


Procedure  E_GET_CHILD_AI42_OBJECT(_ran.i)
  ; we use same concept as for alternative gfx, but wiht one important change: we select the alternative on the fly and keep the parent object
  ;ATTENTION WE DO NOT CHECK IF SOURCE ENTRY IS VALID!
  
  ; world_object()\object_do_create_child=#False
  
  
  ;here we have a new extension:
  ;if object is moving/up/down
  
    If e_engine\e_enemy_maximum>0
    
    If e_engine\e_enemy_count>e_engine\e_enemy_maximum
      ProcedureReturn #False
    EndIf
    
    
  EndIf
   
  
  If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
          ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf
  
  Select world_object()\object_move_direction_y
      
    Case #DOWN
      
      If world_object()\object_no_child_if_move_down=#True  ;no child if falling/move down
        If world_object()\object_collision=#False
          ProcedureReturn #False
        EndIf
    EndIf
    
        
  EndSelect
  
  
  If world_object()\object_is_active=#False Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
     ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_random_pause<>0
    e_pause_for_random_action_actual_time.i=e_engine_heart_beat\beats_since_start+e_pause_for_random_action.i
  EndIf 
  
  

  
  Select _ran.i
      
    Case 0
      world_object()\object_child_gfx_ai_path=world_object()\object_child0_gfx_ai42
      world_object()\object_do_create_child=#True
      
     
      
    Case 1
      world_object()\object_child_gfx_ai_path=world_object()\object_child1_gfx_ai42
      world_object()\object_do_create_child=#True
    
      
    Case 2
      world_object()\object_child_gfx_ai_path=world_object()\object_child2_gfx_ai42
      world_object()\object_do_create_child=#True
     
      
    Case 3
      world_object()\object_child_gfx_ai_path=world_object()\object_child3_gfx_ai42
      world_object()\object_do_create_child=#True
      
     
    Case 4
      world_object()\object_child_gfx_ai_path=world_object()\object_child4_gfx_ai42
      world_object()\object_do_create_child=#True
       
      
    Case 5
      world_object()\object_child_gfx_ai_path=world_object()\object_child5_gfx_ai42
      world_object()\object_do_create_child=#True
       
    Case 6
      world_object()\object_child_gfx_ai_path=world_object()\object_child6_gfx_ai42
      world_object()\object_do_create_child=#True
       
     
    Case 7
      world_object()\object_child_gfx_ai_path=world_object()\object_child7_gfx_ai42
      world_object()\object_do_create_child=#True
      
    
    Case 8
      world_object()\object_child_gfx_ai_path=world_object()\object_child8_gfx_ai42
      world_object()\object_do_create_child=#True
         

    Case 9
      world_object()\object_child_gfx_ai_path=world_object()\object_child9_gfx_ai42
      world_object()\object_do_create_child=#True
        
    
     
      
  EndSelect
  
  
  If Len(Trim(world_object()\object_child_gfx_ai_path))<1
    world_object()\object_do_create_child=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_do_create_child=#True
    
    If world_object()\object_play_sound_on_create_child=#True
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CHILD_CREATE)  
  EndIf
  
 
  
  
  E_STREAM_LOAD_SPRITE(#E_ADD_CHILD_TO_MAP)
 
  
EndIf

  
    
EndProcedure


Procedure  E_GET_EMIT_OBJECT_ON_MOVE()
  
  Define _ran.i=0
  
  
  
  If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
          ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf
  
  If  world_object()\object_emit_on_move=#False Or  world_object()\object_action_status_x=#NO_DIRECTION  And   world_object()\object_action_status_y=#NO_DIRECTION 
     ProcedureReturn #False  
  EndIf
  
  

  
  If Random(world_object()\object_emit_on_move_random)>0 
   
  ProcedureReturn #False  
  EndIf
  

   
  If world_object()\object_use_random_pause<>0
    ; take some breath before we check the next random situation
    If e_pause_for_random_action_actual_time>e_engine_heart_beat\beats_since_start
      ProcedureReturn #False
    EndIf 
  EndIf
  
 
    
    _ran.i=Random(world_object()\object_emit_on_move_random)
   
    
  
E_SET_EMITTER_OBJECT_ON_MOVE(_ran.i)
    
  
  EndProcedure
  
  
  
  Procedure  E_GET_EMIT_OBJECT_USE_MAX_OBJECT()
  
    
    
    Define _ran.i=world_object()\object_emitter_max_objects_random
    
  
      
    
    
  If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
          ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf
  
  If world_object()\object_emitter_use_max_objects=#False 
      ProcedureReturn #False  
  EndIf
  
  
  
  If ListSize(indexeI())>e_max_interactive_object_in_view.i And e_max_interactive_object_in_view.i>0
    ProcedureReturn #False ;we can not create any object, table is full, keep performance/frame rate
  EndIf

  If _ran.i>0
    If Random(_ran.i)=1
    E_SET_EMITTER_OBJECT_SET_NEXT()  
    EndIf
    ProcedureReturn #False

  EndIf
  
  E_SET_EMITTER_OBJECT_SET_NEXT()

    
  
  EndProcedure
  
  
  Procedure E_FOLLOW_PLAYER_ON_TIMER()
    ;for new simple variation if object change the follow with timer
    ;after timer is over, follow parameter in player_follow will be overwritten with the timer_follow paramenter,
    ;timer will be deactivated...
    ;"single shot"
    
    If world_object()\object_follow_player_after_timer=#False
    ProcedureReturn #False  
    EndIf
    
    If world_object()\object_follow_player_timer_actual>e_engine_heart_beat\beats_since_start
    ProcedureReturn #False  
    EndIf
    
    world_object()\object_follow_player_after_timer=#False
    world_object()\object_follow_player=world_object()\object_follow_player_on_timer
    
    
    
  EndProcedure
  
  
  
  Procedure.b  E_GET_EMIT_OBJECT_USE_TIMER()
    
        
      If world_object()\object_emit_on_timer=#False
        ProcedureReturn #False  
      EndIf
      
      
  
      
      If world_object()\object_emit_timer_actual<e_engine_heart_beat\beats_since_start
          world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer
          Else
          ProcedureReturn #True
       EndIf
       
      
    If world_object()\object_emit_stop_if_guard_on_screen=#True
      
      If e_engine\e_count_active_boos_guards>0
        world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer  ;reset  timer so it starts only if boss without guard
      ProcedureReturn #False  
      EndIf
   
    EndIf
    
   If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
          ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf
    

    E_SET_EMITTER_OBJECT_ON_TIMER()
    
  
  EndProcedure
  
  
  
  Procedure  E_GET_CHILD_AI42_BY_DAY_NIGHT()
  ; we use same concept as for alternative gfx, but wiht one important change: we select the alternative on the fly and keep the parent object
  ;ATTENTION WE DO NOT CHECK IF SOURCE ENTRY IS VALID!
  
    ; world_object()\object_do_create_child=#False
    

  If world_object()\object_is_active=#False Or world_object()\object_remove_from_list=#True Or world_object()\object_allert_stay=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_create_no_child_if_hide_away=#True And world_object()\object_hide_away_status=#True
     ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_random_pause<>0
    e_pause_for_random_action_actual_time.i=e_engine_heart_beat\beats_since_start+e_pause_for_random_action.i
  EndIf
  
  
  ;day night emmitter is only one entry, there are not more entries for this build


  
  Select e_world_status.i
      
    Case  #WORLD_STATUS_DAY
      
        If Len(Trim(world_object()\object_set_emitter_day_ai42))<1
    world_object()\object_do_create_child=#False
  ProcedureReturn #False  
EndIf

E_STREAM_LOAD_SPRITE(#E_ADD_DAY_EMIT_TO_MAP)

      
Case  #WORLD_STATUS_NIGHT
  
         If Len(Trim(world_object()\object_set_emitter_night_ai42))<1
    world_object()\object_do_create_child=#False
  ProcedureReturn #False  
EndIf
E_STREAM_LOAD_SPRITE(#E_ADD_NIGHT_EMIT_TO_MAP)

      
      
  EndSelect
  
  

  
    
EndProcedure
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Procedure  E_SET_UP_FOR_CHILD_AI42_BY_DAY_NIGHT_RANDOM()
  ;for some day night special (emitters/objects spawn)
    
    
  If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
          ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
    EndIf

  
  
  If Random(world_object()\object_set_day_night_emitter_random)<>1
  ProcedureReturn #False  
  EndIf
  
   
  If world_object()\object_use_random_pause<>0
    ; take some breath before we check the next random situation
    If e_pause_for_random_action_actual_time>e_engine_heart_beat\beats_since_start
      ProcedureReturn #False
    EndIf 
  EndIf
  
  


    E_GET_CHILD_AI42_BY_DAY_NIGHT()
    
  
  EndProcedure


Procedure  E_SET_UP_FOR_CHILD_AI42_BY_RANDOM()
  
  Define _ran.i=0
  
  
  
  
  If world_object()\object_use_creation_counter=#True
  
     If world_object()\object_child_total_counter>= world_object()\object_child_total
        ProcedureReturn  #False ;we do not go on with another object, we reached the maximum of this, until we are streamed back in screen  
    EndIf
    
  EndIf
  
  
  If ListSize(indexeI())>e_max_interactive_object_in_view.i And e_max_interactive_object_in_view.i>0
    ProcedureReturn #False ;we can not create any object, table is full, keep performance/frame rate
  EndIf
  
  
  
  
  If  e_engine\e_frame_target>e_engine\e_global_fps And world_object()\object_is_enemy=0
    ProcedureReturn #False ;we can not create any object, table is full/ keep performance/frame rate
  EndIf
  
  
   If world_object()\object_create_child_random>0
    
    
    If Random(world_object()\object_create_child_random)<>1
      
      If world_object()\object_use_creation_counter=#True  ;special for childcounter higher random, less childs, =random map design
        world_object()\object_child_total_counter+1
   
        
      EndIf
      
      ProcedureReturn #False  
    EndIf
    
    
  EndIf
  
   
  

  
   
  If world_object()\object_use_random_pause<>0
    ; take some breath before we check the next random situation
    If e_pause_for_random_action_actual_time>e_engine_heart_beat\beats_since_start
      ProcedureReturn #False
    EndIf 
  EndIf
  

 
  
    
    
    
    _ran.i=Random(world_object()\object_create_child)
    e_parent_direction_x.i=world_object()\object_move_direction_x
    e_parent_direction_y.i=world_object()\object_move_direction_y
    
    
    If world_object()\object_use_creation_counter=#True
     world_object()\object_child_total_counter+1
    EndIf
  
    E_GET_CHILD_AI42_OBJECT(_ran.i)
    
    
    
  
  EndProcedure
  
  
  
  
  Procedure  E_SET_UP_FOR_CHILD_AI42_BY_HIT()
    

    E_GET_HIT_EFFECT()
    


  
EndProcedure



Procedure  E_GET_ALTERNATIVE_AI42_OBJECT()
  
 
  If world_object()\object_remove_after_change=#True
     world_object()\object_remove_from_list=#True  
  EndIf
 
  E_STREAM_LOAD_SPRITE(#E_ADD_ELEMENT_TO_MAP)
  
  
  
  


EndProcedure



Procedure  E_SET_UP_FOR_ALTERNATIVE_AI42()
  
  ;default sytem for objecthandling :
If world_object()\object_can_change=#False
ProcedureReturn #False  
EndIf

  
  If Len(world_object()\object_alternative_gfx_default_ai42)<1
  ProcedureReturn #False  
  EndIf
  
   ;E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CHANGE)
   E_GET_ALTERNATIVE_AI42_OBJECT()

  
  
EndProcedure


Procedure  E_SET_UP_FOR_REMOVE_AFTER_DAY_NIGHT_AI42()
  
  ;do we change the object if day/night changed?
  ;for now e use the alternative gfx, which is the same as for dead/remove
 

  If world_object()\object_deactivate_use_alternative_gfx=#False
  ProcedureReturn #False  
  EndIf
  
  
  If Len(world_object()\object_alternative_gfx_default_ai42)<1
  ProcedureReturn #False  
  EndIf
  
    If world_object()\object_play_sound_on_change=#True
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CHANGE)  
    EndIf
    
    E_GET_ALTERNATIVE_AI42_OBJECT()

  
  
EndProcedure




Procedure  E_SET_UP_FOR_ALTERNATIVE_AI42_QUEST_OBJECT()
  

    
  If world_object()\object_alternative_gfx_default_ai42>""
    
    If world_object()\object_play_sound_on_change=#True
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CHANGE)  
    EndIf
    
     E_GET_ALTERNATIVE_AI42_OBJECT()
  
     
  EndIf
    
EndProcedure



Procedure E_CHANGE_OBJECT_STATUS()
  ;here we change the status defined in script (DNA 42)
  ;some simple object status AI
  
 If world_object()\object_no_enemy_action=#True
   ProcedureReturn #False  
EndIf

     If  world_object()\object_do_not_save_after_collision
     world_object()\object_do_not_save=#True  
     EndIf

  If world_object()\object_remove_after_collison=#True
    ;E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_remove_from_list=#True
   
 EndIf
  
    If world_object()\object_hp<1
    If world_object()\object_change_on_dead=#True
      world_object()\object_remove_from_list=#True
      world_object()\object_can_change=#True
      
      
    EndIf


    If world_object()\object_remove_after_dead=#True
      world_object()\object_remove_from_list=#True
      
      
    EndIf
  EndIf
  
  

  If world_object()\object_change_on_collision=#True
    ;E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_can_change=#True
  EndIf
  
  
  
  If world_object()\object_inactive_after_change=#True
    world_object()\object_is_active=#False
  EndIf
  
  If world_object()\object_inactive_after_collision=#True
    
    ;  E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_is_active=#False  
  EndIf
  
  If world_object()\object_remove_after_collison=#True
    ;E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_remove_from_list=#True  
  EndIf
  
  If world_object()\object_remove_after_change=#True
    ;  E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_remove_from_list=#True  
  EndIf
  
  If world_object()\object_no_collision_after_collision=#True
    world_object()\object_collision=#False
  EndIf
  
  If world_object()\object_do_not_save_after_change=#True
    world_object()\object_do_not_save=#True  
  EndIf
  
  
  If world_object()\object_is_active=#False
    If world_object()\object_do_not_save_after_inactive=#True
      world_object()\object_do_not_save=#True
    EndIf
  EndIf
  
  If world_object()\object_is_global_light_on_collision=#True
    world_object()\object_is_global_light=#True  
  EndIf
  


;-- keep this code on the end of this routine
  
  If world_object()\object_save_map_on_collision=#True
       E_SET_UP_SCREEN_SHOT_SYSTEM_FOR_SAVE()
       E_CHECK_FOR_RESPAWN_AREA()
  EndIf
  

EndProcedure





Procedure E_CHECK_IF_HIT_EFFECT()
  ;use this for some eccets if hit...
  
  If world_object()\object_show_hit_effect=#False
  ProcedureReturn #False  
  EndIf
  
  E_SET_UP_FOR_CHILD_AI42_BY_HIT()
  
EndProcedure


Procedure  E_CHECK_STATUS_CHANGE_BY_RANDOM()
  
  
  
  If Random(world_object()\object_change_on_random)<>1
  ProcedureReturn #False  
  EndIf

  E_CHANGE_OBJECT_STATUS()
  E_SET_UP_FOR_ALTERNATIVE_AI42()
  
  
EndProcedure


Procedure E_EFFECT_ON_PLAYER_JUMPN_RUN()
  
  
  If world_object()\object_is_heal_potion<>0
   If player_statistics\player_health_symbol_show=#True
     If player_statistics\player_health_symbol_actual_symbol<player_statistics\player_health_symbol_max_symbols
       player_statistics\player_health_symbol_actual_symbol+1
       
     EndIf
     
   EndIf
 EndIf
 

  
  
EndProcedure

Procedure E_REMOVE_GRAVITY()
  
  If world_object()\object_use_gravity=#False
  ProcedureReturn #False  
  EndIf
  
  world_object()\object_use_gravity=#False
  
EndProcedure



Procedure E_REMOVE_MOVE_PIXEL_LIFETIME()
  ;here we remove all of the move!

  
  If world_object()\object_stop_after_pixel_count=#False
         ProcedureReturn #False
  EndIf
   
    world_object()\object_use_gravity=#False
    world_object()\object_move_direction_x=#NO_DIRECTION
    world_object()\object_move_direction_y=#NO_DIRECTION
    world_object()\object_last_move_direction_x=#NO_DIRECTION
    world_object()\object_last_move_direction_y=#NO_DIRECTION
    world_object()\object_move_direction_backup=#NO_DIRECTION
    world_object()\object_use_default_direction=""
    world_object()\object_move_x=0
    world_object()\object_move_y=0
    world_object()\object_use_horizontal_velocity=#False
    world_object()\object_use_vertical_velocity=#False
    world_object()\object_static_move=#False
    world_object()\object_move_time=0
    world_object()\object_use_life_time_per_pixel=#False

    EndProcedure


Procedure E_REMOVE_MOVE()
  ;here we remove all of the move!

  
  If world_object()\object_stop_move_after_collision=#False 
     ProcedureReturn #False
  EndIf
    
    world_object()\object_use_gravity=#False
    world_object()\object_move_direction_x=#NO_DIRECTION
    world_object()\object_move_direction_y=#NO_DIRECTION
    world_object()\object_last_move_direction_x=#NO_DIRECTION
    world_object()\object_last_move_direction_y=#NO_DIRECTION
    world_object()\object_move_direction_backup=#NO_DIRECTION
    world_object()\object_use_default_direction=""
    world_object()\object_move_x=0
    world_object()\object_move_y=0
    world_object()\object_use_horizontal_velocity=#False
    world_object()\object_use_vertical_velocity=#False
    world_object()\object_static_move=#False
    world_object()\object_move_time=0
    world_object()\object_use_life_time_per_pixel=#False

    EndProcedure



Procedure E_STATUS_TRIGGER()
  
  ;key routine for collision actions
  ;here we do some checks for:  (switch gfx ....alternative gfx...)
  
 

  If world_object()\object_play_sound_on_collision=#True
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_COLLISION)  
  EndIf
  
  
  E_WORLD_STATUS_CONTROLLER_PARENT_CHILD()
  E_WORLD_STATUS_CONTROLLER()
 ; E_ANALYSE_LOOT()  ;check if we got some loot?  

;the object changes?  
  
  
  If world_object()\object_effect_on_player_collision=#True
    E_EFFECT_ON_PLAYER_JUMPN_RUN()
  EndIf
  
  player_statistics\player_gold+world_object()\object_gold_value
  
  If world_object()\object_add_timer_to_map>0
    e_map_timer\_map_time_stop+world_object()\object_add_timer_to_map
  EndIf
  
  

  
  ;----
     
     If world_object()\object_anim_start_on_collison=#True
     world_object()\object_is_anim=#True  
     EndIf
     
     
     If world_object()\object_change_move_after_collision=#True
       world_object()\object_move_x=world_object()\object_move_on_collision_x  
       world_object()\object_move_y=world_object()\object_move_on_collision_y  
        
     EndIf
     
  
     
     If world_object()\object_fade_out_on_collision
       world_object()\object_fade_out_per_tick=world_object()\object_fade_out_on_collision  
       world_object()\object_use_fade=#True
     EndIf
     
  

  
  
  If world_object()\object_no_collision_after_collision=#True
   ; E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_collision=#False 
  EndIf
  
  If world_object()\object_inactive_after_collision=#True
    ; E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_INTERACTIVE_SOUND)
    world_object()\object_is_active=#False 
   EndIf
   

If world_object()\object_collision_flip_flop
  E_CHANGE_DIRECTION()  
EndIf

    If world_object()\object_collision_tractor_object=#True
  e_engine\e_player_auto_move_direction_x=world_object()\object_move_direction_x
  e_engine\e_player_auto_move_direction_y=world_object()\object_move_direction_y

Else
  e_engine\e_player_auto_move_direction_x=#NO_DIRECTION
  e_engine\e_player_auto_move_direction_y=#NO_DIRECTION
  EndIf

  

  
  E_CHANGE_OBJECT_STATUS()
  E_SET_UP_FOR_ALTERNATIVE_AI42()

  
EndProcedure

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 625
; FirstLine = 618
; Folding = ----
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant