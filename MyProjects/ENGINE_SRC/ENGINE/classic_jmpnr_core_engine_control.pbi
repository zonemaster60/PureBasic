;message system
; new version:20191018: indexeI() is used for all object <--> object operations


Declare E_BUILD_GLOBAL_INDEX()
Declare E_ACTIVATE_ON_COMPANION()
Declare E_CHECK_IF_PLAYER_DEAD()
Declare E_SET_RANDOM_START_DIRECTION()  
Declare E_SET_PLAYER_GRAVITY_OFF()
Declare E_JUMP_STOPP()
Declare E_COLLISION_OBJECT_CHANGE()







Procedure E_QUEST_INFO_DEFAULT(_actual_world.s,_next_world.s,_text_german.s,_text_english.s)
  ;set text shown on screen, if action is missing (player forgot to take key...), quest importatn situation
           e_player_warning\e_player_warning_text_english=_text_english.s
           e_player_warning\e_player_warning_text_german=_text_german.s
           e_player_warning\e_player_warning_show=#True
           e_player_warning\e_player_warning_show_time_max=e_engine_heart_beat\beats_since_start+(e_player_warning\e_player_warning_show_time/2)
           e_player_warning\e_player_warning_text_move_y_actual_pos=0
           e_engine\e_actuall_world=_actual_world.s
           e_engine\e_next_world=_next_world.s
         
  
EndProcedure







Procedure E_DEFAULT_ARENA_EXIT()
  
  If e_engine\e_world_map_is_arena_map=#False
    ProcedureReturn #False
   EndIf
  
        e_engine\e_next_world="1_nrsp.worldmap"

EndProcedure









Procedure E_PLAYER_CAN_NOT_GO_TO_THIS_AREA()
  
           e_player_warning\e_player_warning_text_english="I can not go this way."
           e_player_warning\e_player_warning_text_german="Ich kann diesen Weg noch nicht gehen."
           e_player_warning\e_player_warning_show=#True
           e_player_warning\e_player_warning_show_time_max=e_engine_heart_beat\beats_since_start+(e_player_warning\e_player_warning_show_time/2)
           e_player_warning\e_player_warning_text_move_y_actual_pos=0
           e_engine\e_message_type=#MESSAGE_TYPE_GFX_CAN_NOT_GO_THIS_WAY
  
EndProcedure






Procedure  E_CLEAN_UP_WEAPON()
  
  
  ;routine for weapon control after hit
  
  
  
  If ListSize(world_object())<1
    ProcedureReturn #False  
  EndIf
  
  ResetList(world_object())
  
  ForEach world_object()
    
    If world_object()\object_is_weapon=#True
          world_object()\object_is_active=#False
          world_object()\object_remove_from_list=#True
          world_object()\object_is_weapon=#False
          ProcedureReturn #False
    EndIf
  
  Next

  
EndProcedure




 

Procedure E_SET_UP_FOR_INPUT_IDLE()
  ;for some special effects 
  e_idle_time_before_input_check.i=e_engine_heart_beat\beats_since_start+e_idle_time.i
EndProcedure












Procedure E_NIGHT_INTRO_SONG_START()
  
  ;start the night song sfx to tell night is comming!
  
  If IsSound(e_sound_song_of_the_night_id.i)
    
    Select SoundStatus(e_sound_song_of_the_night_id.i)
        
      Case #PB_Sound_Stopped
        PlaySound(e_sound_song_of_the_night_id.i,#PB_Sound_Loop,e_engine\e_sound_global_volume)
        
      Case #PB_Sound_Paused
        PlaySound(e_sound_song_of_the_night_id.i,#PB_Sound_Loop ,e_engine\e_sound_global_volume)
        
      Default
        PlaySound(e_sound_song_of_the_night_id.i,#PB_Sound_Loop ,e_engine\e_sound_global_volume)
        
    EndSelect
    
    
  EndIf
  
  
EndProcedure


Procedure E_NIGHT_INTRO_SONG_STOPP()
  
  
  If IsSound(e_sound_song_of_the_night_id.i)
    StopSound(e_sound_song_of_the_night_id.i)  
 EndIf
  
 If IsSound(e_engine\e_global_sound_id)=0
   ProcedureReturn #False
 EndIf
 
    
    Select SoundStatus(e_engine\e_global_sound_id)
        
      Case #PB_Sound_Stopped
        PlaySound(e_engine\e_global_sound_id,#PB_Sound_Loop ,e_engine\e_sound_global_volume)
        
      Case #PB_Sound_Paused
        PlaySound(e_engine\e_global_sound_id,#PB_Sound_Loop ,e_engine\e_sound_global_volume)
        
      Default
        PlaySound(e_engine\e_global_sound_id,#PB_Sound_Loop ,e_engine\e_sound_global_volume)
        
    EndSelect
    
    
  
EndProcedure



  
  Procedure E_SETUP_BOSS_HEALTH_BAR()
    
    ;only called if boss object is hit:
    
    If IsSprite(boss_bar\boss_bar_front_gfx_id)=0
    ProcedureReturn #False  
    EndIf
    
    
    If boss_bar\boss_bar_update=#False
    ProcedureReturn #False  
    EndIf
    
    

    boss_bar\boss_bar_size_factor=boss_bar\boss_bar_actual_health/boss_bar\boss_bar_maximum_health
    ZoomSprite(boss_bar\boss_bar_front_gfx_id,boss_bar\boss_bar_size_w*boss_bar\boss_bar_size_factor,boss_bar\boss_bar_size_h)
    boss_bar\boss_bar_update=#False
  
  
 
EndProcedure

  

Procedure E_SETUP_ENEMY_HEALTH_BAR()
  
  If world_object()\object_health_bar_update=#True And world_object()\object_show_hp_bar=#True  
     world_object()\object_health_bar_update=#False  
    
    If world_object()\object_health_bar_actual_hp<1
      E_STATUS_TRIGGER() 
      ProcedureReturn #False
    EndIf
    
    If IsSprite(world_object()\object_health_bar_id)=0
    ProcedureReturn #False  
    EndIf
    
   
    world_object()\object_health_bar_factor=world_object()\object_health_bar_actual_hp/world_object()\object_health_bar_maximum_hp
    ZoomSprite(world_object()\object_health_bar_id,world_object()\object_health_bar_size_w*world_object()\object_health_bar_factor,world_object()\object_health_bar_size_h)
    
  EndIf   
  
EndProcedure


Procedure  E_GET_QUEST_CONTROLLER()
  
 ;put here logic system for quest 
  
  
EndProcedure




Procedure E_QUICK_SAVE_AND_RECOVER_TEXT()
  ;;player  savesystem  with regeneration for HP, and status . (special savepoints on map)
  
       player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols
      
        E_SAVE_RESPAWN_WORLD(e_engine\e_actuall_world)


  
  
  
  EndProcedure
   



Procedure E_QUICK_SAVE()
  
    E_CHECK_FOR_RESPAWN_AREA()

 EndProcedure
 
 
 
 
 
 Procedure E_DIE_WITH_BOSS_CHECK()
   
   
   Define *_boss
   
   
   
   
   
   If ListSize(world_object())<1
     ProcedureReturn #False  
   EndIf
   
   
   ;here we stop enemy spawn if wanted:
   If world_object()\object_is_boss=#False
     ProcedureReturn #False  
   EndIf
   
   
   *_boss=@world_object()  
   
   ;look for the enemies/emitters to switch off
   
   ResetList(world_object())
   
   ForEach world_object()
     ;simple:
     ;we can scan the complete map, only objects already in stream/gfx area will be affected, because no other objects store information about object status
     
     If world_object()\object_remove_with_boss=#True
       world_object()\object_remove_from_list=#True
     EndIf
     
   Next
   
   If ChangeCurrentElement(world_object(),*_boss)
   EndIf
   
   
 EndProcedure

 

Procedure E_DIE_WITH_GUARD_CHECK()
  
  
  Define *_guard
  
  
  
  If ListSize(world_object())<1
    ProcedureReturn #False  
  EndIf
  
  
  ;here we stop enemy spawn if wanted:
  If world_object()\object_is_boss_guard=#False
    ProcedureReturn #False  
  EndIf
  
  
  *_guard=@world_object()  
  
  ;look for the enemies/emitters to switch off
  
  ResetList(world_object())
  
  ForEach world_object()
    ;simple:
    ;we can scan the complete map, only objects already in stream/gfx area will be affected, because no other objects store information about object status
    
    If world_object()\object_remove_with_guard=#True
      world_object()\object_remove_from_list=#True
    EndIf
    
  Next
  
  If ChangeCurrentElement(world_object(),*_guard)
  EndIf
  
  
EndProcedure





 
 
 
 
Procedure E_CLEAN_UP_BASE_SAVE_DIRECTORY()
  Define _dir.i=0
   
  ;be very carefull about deleting files on disk!!!
  _dir.i=ExamineDirectory(#PB_Any,e_engine\e_save_path,"*.*")
  
  If IsDirectory(_dir.i)
    
    While NextDirectoryEntry(_dir.i)
      If DirectoryEntryType(_dir.i)=#PB_DirectoryEntry_File 
             DeleteFile(e_engine\e_save_path+DirectoryEntryName(_dir.i))   
        EndIf
   Wend
FinishDirectory(_dir.i)
EndIf

  
  EndProcedure
  
  
  Procedure E_SCROLL_BACK_GROUND_AUTO()
    ;if the background/scrolllayer does autoscroll (use this for eg. "sunset")
    Define i.i=0
    
    For i.i=0 To e_engine\e_scroll_object_id-1
      If e_engine\e_scroll_auto[i.i]=#True
        e_engine\e_scroll_gfx_actual_pos_x1[i.i]-e_engine\e_scroll_speed_x[i.i]
        e_engine\e_scroll_gfx_actual_pos_x2[i.i]-e_engine\e_scroll_speed_x[i.i]
   
      EndIf
      
      Next
    
    
    
  EndProcedure
  


Procedure E_EFFECT_RESET()
  ;here we set some effects (objects) back to default situation
  ;first we go for the touchtransparency:
      If world_object()\object_collision_transparency<>0
      world_object()\object_transparency=world_object()\object_transparency_back_up  
    EndIf
    ;----------------------------------------------------------------------------------------
    
    If world_object()\object_sound_is_boss=#True
    E_SOUND_PAUSE_GLOBAL_SOUND() 
    EndIf
    
    
EndProcedure


Procedure E_KEY_MOVE_WORLD_BLOCK_WISE(direction.i)
  ;here we move the world per defined blocksize if player out of margin


  Select direction.i
      
      
    Case #DOWN
      
      e_engine\e_world_offset_y-world_object()\object_move_y
      world_object()\object_y+world_object()\object_move_y
     ; world_object()\object_move_direction_y=#DOWN
      ;world_object()\object_last_move_direction_y=#DOWN
player_statistics\player_moves_world=#True
      
    Case #UP
      e_engine\e_world_offset_y+e_engine_game_type\engine_block_size_y
      ;world_object()\object_y-350
      ;world_object()\object_move_direction_y=#UP
      ;world_object()\object_last_move_direction_y=#UP
      player_statistics\player_moves_world=#True
      
    Case #LEFT
      
      If e_engine_game_type\engine_use_left_barier=#True  
      ProcedureReturn #False  
      EndIf
      
      e_engine\e_world_offset_x+world_object()\object_move_x
     world_object()\object_x-world_object()\object_move_x
     ; world_object()\object_move_direction_x=#LEFT
    ;world_object()\object_last_move_direction_x=#LEFT

      
    Case #RIGHT
      e_engine\e_world_offset_x-world_object()\object_move_x
      world_object()\object_x+world_object()\object_move_x
      ;world_object()\object_move_direction_x=#RIGHT
      ;world_object()\object_last_move_direction_x=#RIGHT
  
  EndSelect
  

EndProcedure




Procedure E_KEY_MOVE_WORLD_PER_PIXEL(direction.i)
  ;here we move the world  per pixel if player out of margin
  

  Select direction.i
      
      
    Case #DOWN
      
      e_engine\e_world_offset_y-world_object()\object_move_y
     ; world_object()\object_y+world_object()\object_move_y
     ; world_object()\object_move_direction_y=#DOWN
      ;world_object()\object_last_move_direction_y=#DOWN
player_statistics\player_moves_world=#True
      
    Case #UP
      e_engine\e_world_offset_y+world_object()\object_move_y
      ;world_object()\object_y-350
      ;world_object()\object_move_direction_y=#UP
      ;world_object()\object_last_move_direction_y=#UP
      player_statistics\player_moves_world=#True
      
    Case #LEFT
      
      If e_engine_game_type\engine_use_left_barier=#True  
      ProcedureReturn #False  
      EndIf
      
      e_engine\e_world_offset_x+world_object()\object_move_x
    ; world_object()\object_x-world_object()\object_move_x
     ; world_object()\object_move_direction_x=#LEFT
    ;world_object()\object_last_move_direction_x=#LEFT

      
    Case #RIGHT
      e_engine\e_world_offset_x-world_object()\object_move_x
      ;world_object()\object_x+world_object()\object_move_x
      ;world_object()\object_move_direction_x=#RIGHT
      ;world_object()\object_last_move_direction_x=#RIGHT
  
  EndSelect
  

EndProcedure



Procedure E_KEY_MOVE_WORLD(direction.i)
  ;here we move the world if player out of margin
  
  Define i.i=0

  
  If  e_engine_game_type\engine_use_block_scroll=#True  
    E_KEY_MOVE_WORLD_BLOCK_WISE(direction.i)
    ProcedureReturn #False
   
  EndIf
  
  If world_object()\object_use_horizontal_velocity=#True
  world_object()\object_move_x=world_object()\object_move_x_max  
  EndIf
  

  
  Select direction.i
      
      
    Case #DOWN
      
      e_engine\e_world_offset_y-world_object()\object_move_y
      world_object()\object_y+world_object()\object_move_y
      ; world_object()\object_move_direction_y=#DOWN
      ;world_object()\object_last_move_direction_y=#DOWN
      player_statistics\player_moves_world=#True
      
      
    Case #UP
      e_engine\e_world_offset_y+world_object()\object_move_y
      world_object()\object_y-world_object()\object_move_y
      ;world_object()\object_move_direction_y=#UP
      ;world_object()\object_last_move_direction_y=#UP
      player_statistics\player_moves_world=#True
   
    Case #LEFT
      
      If e_engine_game_type\engine_use_left_barier=#True  
        ProcedureReturn #False  
      EndIf
      
      e_engine\e_world_offset_x+world_object()\object_move_x
      world_object()\object_x-world_object()\object_move_x
;       world_object()\object_move_direction_x=#LEFT
;       world_object()\object_last_move_direction_x=#LEFT
      player_statistics\player_moves_world=#True
      For i.i=0 To e_engine\e_scroll_object_id-1
        e_engine\e_scroll_gfx_actual_pos_y1[i.i]-e_engine\e_scroll_speed_y[i.i]
        e_engine\e_scroll_gfx_actual_pos_y2[i.i]-e_engine\e_scroll_speed_y[i.i]
      Next 
      
    Case #RIGHT
      e_engine\e_world_offset_x-world_object()\object_move_x
      world_object()\object_x+world_object()\object_move_x
      ;world_object()\object_move_direction_x=#RIGHT
      ;world_object()\object_last_move_direction_x=#RIGHT
      player_statistics\player_moves_world=#True
      
      For i.i=0 To e_engine\e_scroll_object_id-1
        e_engine\e_scroll_gfx_actual_pos_x1[i.i]-e_engine\e_scroll_speed_x[i.i]
        e_engine\e_scroll_gfx_actual_pos_x2[i.i]-e_engine\e_scroll_speed_x[i.i]
      Next
      
  EndSelect
  


EndProcedure




  
  Procedure E_CHANGE_DIRECTION()
    
    
  If world_object()\object_is_attacking=#True
  ProcedureReturn #False  
  EndIf
  
    
If ChangeCurrentElement(world_object(),brain\e_object_system_id1)=0
ProcedureReturn #False
EndIf

    Select world_object()\object_last_move_direction_y
        
      Case #UP

        world_object()\object_move_direction_y=#DOWN
        world_object()\object_last_move_direction_y=#DOWN
        world_object()\object_vertical_direction_change=#True
      Case #DOWN
  
        world_object()\object_move_direction_y=#UP
        world_object()\object_last_move_direction_y=#UP
        world_object()\object_vertical_direction_change=#True
        
      EndSelect
      
      
      Select world_object()\object_last_move_direction_x
      Case #LEFT
        
  world_object()\object_horizontal_direction_change=#True
          
          world_object()\object_move_direction_x=#RIGHT
          world_object()\object_last_move_direction_x=#RIGHT

        Case #RIGHT
          
   world_object()\object_horizontal_direction_change=#True
        
        world_object()\object_move_direction_x=#LEFT
        world_object()\object_last_move_direction_x=#LEFT
      
        EndSelect
 

  EndProcedure

  
  Procedure E_AUTO_SCROLL_X()
  e_engine\e_world_offset_x+e_engine\e_world_auto_scroll_x
    EndProcedure
  
  Procedure E_AUTO_SCROLL_Y()
 e_engine\e_world_offset_y+e_engine\e_world_auto_scroll_y
    EndProcedure
    




 
  
  
  
  
  
  Procedure E_ANALYSE_LOOT()
    
    ;loot management core
    
  If world_object()\object_is_active=#False
    ProcedureReturn #False  
  EndIf
  
;code here:
  
EndProcedure


Procedure E_STOP_MOVE()
  ;just set move to #NO_DIRECTION
  
  world_object()\object_move_direction_x=#NO_DIRECTION
  world_object()\object_move_direction_y=#NO_DIRECTION
  world_object()\object_last_move_direction_x=#NO_DIRECTION
  world_object()\object_last_move_direction_y=#NO_DIRECTION
  
EndProcedure



Procedure  E_COLLISION_OVERIDE(*o1, *o2,type.i)
  
  
;*o1, *o2, not used (for now)

If world_object()\object_static_move=#True
  E_STOP_MOVE()
EndIf

If world_object()\object_keep_move_direction=#True
E_STATUS_TRIGGER()
ProcedureReturn #False  
EndIf

E_COLLISION_OBJECT_CHANGE()
  
  Select type.i
      
    Case #ALL
      e_engine\e_is_collision=#False
     
    Case #NOTHING
      ;world_object()\object_move_direction_x=#NO_DIRECTION
;      world_object()\object_last_move_direction_x=#NO_DIRECTION
      ;world_object()\object_move_direction_y=#NO_DIRECTION
    ;  world_object()\object_last_move_direction_y=#NO_DIRECTION
      ;world_object()\object_is_moving=#False 
      

      
    Case #FLIP_FLOP
      
      If world_object()\object_follow_player<>0
        ProcedureReturn #False
      EndIf
      
      E_CHANGE_DIRECTION() 
      
    Case  #STOP_MOVE
      ;works for objects with "#AI_STGHT_MOVE"
      E_CHANGE_DIRECTION() 
      
      
    Case #KILL_OBJECT
      
      If brain\e_internal_name1<>brain\e_internal_name2  ;prevent killing object themselves 
        
        world_object()\object_hp=0
        E_STATUS_TRIGGER()
        
        
        
      EndIf
      
    Default
      
      ;no movement if collision is default
         ;  world_object()\object_move_direction_x=#NO_DIRECTION
          ; world_object()\object_last_move_direction_x=#NO_DIRECTION
          ; world_object()\object_move_direction_y=#NO_DIRECTION
      ;world_object()\object_last_move_direction_y=#NO_DIRECTION
      
  EndSelect
  
  
  
  
EndProcedure



Procedure E_COLLISION_REMOVE_OBJECT_HANDLING()
  ;for some special  situations, like triggered actions:
;   *e_collisions_object_id=@world_object()
;   If ChangeCurrentElement(world_object(),indexeI()\index)=0
;   ProcedureReturn #False  
;   EndIf
   
  world_object()\object_is_active=#False  
  world_object()\object_remove_from_list=#True
     
  EndProcedure  


  










Procedure E_COLLISION_KILL_PLAYER()
  ;here we kill the player if deadly objects attack/collision with player, like rocks, big stones..
  player_statistics\player_health_symbol_actual_symbol=0
  e_engine\e_engine_mode=#GAME_OVER
  
EndProcedure












Procedure E_PICK_UP_WEAPON(_type.i)
  
  Select _type.i
      
    Case #WEAPON_AXE
;         world_object()\object_is_active=#False
;       world_object()\object_do_not_save=#True
      
      player_statistics\player_weapon_axe=#True
      If IsSound(player_statistics\player_sound_on_item_pic_up_id)
      PlaySound(player_statistics\player_sound_on_item_pic_up_id)
    EndIf
    
           e_player_warning\e_player_warning_text_english="My Axe!" 
           e_player_warning\e_player_warning_text_german="Meine Axt!"
           e_player_warning\e_player_warning_show=#True
           e_player_warning\e_player_warning_show_time_max=e_engine_heart_beat\beats_since_start+e_player_warning\e_player_warning_show_time
           e_player_warning\e_player_warning_text_move_y_actual_pos=0
           
            Case #WEAPON_SHIELD
;         world_object()\object_is_active=#False
;       world_object()\object_do_not_save=#True
              
      player_statistics\player_weapon_shield=#True
      If IsSound(player_statistics\player_sound_on_item_pic_up_id)
      PlaySound(player_statistics\player_sound_on_item_pic_up_id)  
    EndIf
    
           e_player_warning\e_player_warning_text_english="My Shield!" 
           e_player_warning\e_player_warning_text_german="Mein Schild!"
           e_player_warning\e_player_warning_show=#True
           e_player_warning\e_player_warning_show_time_max=e_engine_heart_beat\beats_since_start+e_player_warning\e_player_warning_show_time
           e_player_warning\e_player_warning_text_move_y_actual_pos=0

  EndSelect
  
  
EndProcedure

Procedure E_REMOVE_EMITTER()
  
If  world_object()\object_emit_stop_on_collision=#False
  ProcedureReturn #False    
EndIf

  world_object()\object_emit_on_timer=#False  
  world_object()\object_emit_on_jump=#False
  world_object()\object_emit_on_move=#False

  
EndProcedure



Procedure E_FIGHT_DEFAULT()
  
  ;this is for jumpnrun and action games, we reduce the ammount of settings and routines for fight/life values to the absolute minimum, (more to come)
  
     If world_object()\object_does_attack<>0
       E_CHECK_IF_PLAYER_DEAD()
     EndIf
     
  EndProcedure

  
  
  Procedure E_TIMER_ADD()
    
     If  world_object()\object_life_timer_on_collision<1
    ProcedureReturn #False
    EndIf
    
      world_object()\object_life_time=world_object()\object_life_timer_on_collision  ;activate lifetimer on collison
      world_object()\object_end_of_life_time=e_engine_heart_beat\beats_since_start+world_object()\object_life_time
      world_object()\object_life_timer_on_collision=0 ;set it to default
  EndProcedure
  
  
  Procedure E_COLLISION_OBJECT_CHANGE()
    
    
    
    If world_object()\object_change_on_collision=#False
    ProcedureReturn #False  
    EndIf
    
    If world_object()\object_has_changed_on_collsion=#True
    ProcedureReturn #False  
  EndIf
    E_REMOVE_GRAVITY()
    world_object()\object_has_changed_on_collsion=#True
    
    
  EndProcedure
  



  
Procedure E_COLLISION_ENEMY_HANDLING_DEFAULT()
  ;routine for collision  enemy-> player, not player!
  

  E_COLLISION_OBJECT_CHANGE()
  

  
If brain\e_internal_name2="#PLAYER" Or brain\e_internal_name2="#PLAYER_BIRD"
E_FIGHT_DEFAULT()
EndIf

 
EndProcedure





Procedure  E_COLLISION_EVIL_BAT_HANDLING()
  
  Select brain\e_internal_name2
      

          
       Case "#PLAYER","#PLAYER_BIRD"
        E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#FLIP_FLOP)
        E_FIGHT_DEFAULT()
         
      Default
        E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#FLIP_FLOP)
        
      
  EndSelect
  
  
  
EndProcedure










Procedure E_COLLISION_TRIGGER_HANDLING()
  ;here we try extended interaction
  
  Select brain\e_internal_name2
      
    Case "#TRIGGER"
      world_object()\object_remove_from_list=#True   ;remove, default trigger for activating rockfalls ...(trigger is a barrier, which is removed)
   
      
  EndSelect
  

  
EndProcedure













Procedure E_COLLISION_PORTAL_HANDLING_0()
  
  ;here the code:

  If world_object()\object_is_active=#False
    ProcedureReturn #False   ;test this?
  EndIf
  
  e_switch_plane.b=#False
  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK) ;save status of player if map is changed
  E_GRAB_SRC_SCREEN()
  
  
  e_map_map_back_up_for_going_back.s=e_engine\e_actuall_world
  
  Select  e_engine\e_actuall_world
      
  
      
    Case "castle_start.worldmap"
      
      e_engine\e_next_world="vally_walk.worldmap"  ;for now, because we have no worlds/stages outside for now
      
      
    Case "load_cave_1.worldmap"
      
      e_engine\e_next_world="cave_1.worldmap"
      
      
            
    Case "load_cave_2.worldmap"
     
      e_engine\e_next_world="cave_2.worldmap"
      
      
    Case "load_vally.worldmap"
       
      e_engine\e_next_world="vally_walk.worldmap" ;for now, because we have no worlds/stages outside for now
      
      
    Case "vally_walk.worldmap"
      
      e_engine\e_next_world="cave_1.worldmap"  ;for now, because we have no worlds/stages outside for now

    Case "cave_1.worldmap" 
      
      e_engine\e_next_world="cave_2.worldmap"  ;for now, because we have no worlds/stages outside for now

    Case "cave_2.worldmap"
     
      e_engine\e_next_world="cave_3.worldmap"  ;for now, because we have no worlds/stages outside for now

      
       Case "cave_3.worldmap"
     
      e_engine\e_next_world="cave_4.worldmap"  ;for now, because we have no worlds/stages outside for now
  
      
    Case "cave_4.worldmap"
      
      e_engine\e_next_world="swamp.worldmap"  ;for now, because we have no worlds/stages outside for now
    
    Case "swamp.worldmap"
       
       e_engine\e_next_world="swamp1.worldmap"  ;for now, because we have no worlds/stages outside for now
      
       Case "swamp1.worldmap"
      
       e_engine\e_next_world="swamp2.worldmap"  ;for now, because we have no worlds/stages outside for now
           
     Case "swamp2.worldmap"
       
       e_engine\e_next_world= "swamp_temple.worldmap" ;for now, because we have no worlds/stages outside for now
       
        
     Case "swamp_temple.worldmap"
       
       e_engine\e_next_world="swamp_temple_hall_off_dead.worldmap"  ;for now, because we have no worlds/stages outside for now 
       
     Case "swamp_temple_hall_off_dead.worldmap"
      
       e_engine\e_next_world=  "swamp_temple_hell.worldmap"
       
     Case "winter_mountain_map_flappy.worldmap"
      
       e_engine\e_next_world=  "winter_flappy1.worldmap"
       
     Case "swamp_temple_hell_game_winter.worldmap"
       
       e_engine\e_next_world=  "winter_mountain_map.worldmap"
       
       
     Case "winter_flappy1.worldmap"
       
       e_engine\e_next_world=  "winter_flappy_boss.worldmap"
       
       Case "winter_flappy_boss.worldmap"
      
       e_engine\e_next_world=  "winter_flappy_feed.worldmap"
       
     Case "winter_flappy_feed.worldmap"
         
          e_engine\e_next_world=  "winter_garden.worldmap"
          
          
       Case "winter_garden.worldmap"
         
          e_engine\e_next_world=  "winter_castle.worldmap"
          
          
              Case "winter_castle.worldmap"
          
          e_engine\e_next_world= "winter_ball_room.worldmap"
          
             
              Case "winter_ball_room.worldmap"
         
          e_engine\e_next_world= "final.worldmap"
          
              Case "final.worldmap"
         
          e_engine\e_next_world= "duster.worldmap"
          
              Case "duster.worldmap"
         
          e_engine\e_next_world= "pumpkin.worldmap"
          
              Case "pumpkin.worldmap"
        
          e_engine\e_next_world= "pumkin_2.worldmap"
          
               Case "pumkin_2.worldmap"
         
          e_engine\e_next_world= "mspumkin.worldmap"
          
                Case "mspumkin.worldmap"
         
          e_engine\e_next_world= "mspumkin_exit.worldmap"
          
          
                   Case "mspumkin_exit.worldmap"
          
          e_engine\e_next_world= "rotten_cave_1.worldmap"
          
          
        Case "rotten_cave_exit.worldmap"
           e_engine\e_next_world= "rotten_cave_final.worldmap"
          
        
       
    Default
      
     
      e_engine\e_next_world="start.worldmap"
          
  EndSelect


EndProcedure




Procedure E_COLLISION_PORTAL_HANDLING_1()



   
  e_switch_plane.b=#False
  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
  E_GRAB_SRC_SCREEN()
   e_map_map_back_up_for_going_back.s=e_engine\e_actuall_world
  Select  e_engine\e_actuall_world
      
  
      
    Case "cave_1.worldmap"
     
      e_engine\e_next_world="load_cave_1.worldmap" 
      
    Case "vally_walk.worldmap"
      
      e_engine\e_next_world="load_vally.worldmap"
 
    Case "swamp1.worldmap"
   
      e_engine\e_next_world="load_swamp_1.worldmap"
      
      
      Case "load_swamp_1.worldmap"
     
      e_engine\e_next_world="swamp1.worldmap"
    
       Case "swamp2.worldmap"
  
      e_engine\e_next_world="load_swamp_2.worldmap"
      
    Case "load_swamp_2.worldmap"
    
      e_engine\e_next_world="swamp2.worldmap"
      
      
    Case "load_swamp_temple.worldmap"
       
        e_engine\e_next_world="swamp_temple.worldmap"
        
        
        Case "swamp_temple.worldmap"
     
      e_engine\e_next_world="load_swamp_temple.worldmap"
      
    Case "swamp_temple_hall_off_dead.worldmap"
    
      e_engine\e_next_world="load_swamp_temple_hall_off_dead.worldmap"
      
      
    Case "swamp_temple_hell_game_winter.worldmap"

      e_engine\e_next_world="load_swamp_temple_hell_game_winter.worldmap"
      
      
    Case "winter_mountain_map.worldmap"
  
      e_engine\e_next_world="load_winter_mountain_map.worldmap"
    
    Default
     
      e_engine\e_next_world="start.worldmap"
          
  EndSelect
  
  

EndProcedure

Procedure E_COLLISION_PORTAL_HANDLING_2()


If e_engine\e_world_map_is_arena_map=#True
    ProcedureReturn #False
   EndIf
   

  e_switch_plane.b=#False
  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
  E_GRAB_SRC_SCREEN()
   e_map_map_back_up_for_going_back.s=e_engine\e_actuall_world
  
  Select  e_engine\e_actuall_world
      
   Case "cave_2.worldmap"
     
      e_engine\e_next_world="load_cave_2.worldmap"  ;for now, because we have no worlds/stages outside for now
  
 
    Default
     
      e_engine\e_next_world="start.worldmap"
          
  EndSelect
  




EndProcedure

Procedure E_COLLISION_PORTAL_HANDLING_3()

  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
   
EndProcedure

Procedure E_COLLISION_PORTAL_HANDLING_4()

 E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
  
 EndProcedure
 

Procedure E_COLLISION_PORTAL_HANDLING_5()

  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
    

EndProcedure




Procedure E_COLLISION_PORTAL_HANDLING_6()

 E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
         

   

 EndProcedure
 
 
 

Procedure E_COLLISION_PORTAL_HANDLING_7()

  
    E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)     


EndProcedure




Procedure E_COLLISION_PORTAL_HANDLING_8()
  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)

EndProcedure


Procedure E_COLLISION_PORTAL_HANDLING_9()
E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
  ;
  
  EndProcedure
  
  
  
  
 
  
  
 
  
  







  

  
  
  Procedure  E_COLLISION_AXE()
    
    Define _player_attack.f=0
    
    
  
    If world_object()\object_no_weapon_interaction=#True
       
       E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
      
     ProcedureReturn #False
    EndIf
  

     
    
    player_statistics\player_throw_axe=#False
    
    
    
   

    ;------------------------------------------------ if object out of fight or not in fight (uses allert on player switch), but if player hits the object with axe,object will instant switch to default mode :allert = #true
    
    If world_object()\object_is_boss=#True
            
      If e_engine\e_count_active_boos_guards>0
        e_ingame_info_text\timer=e_ingame_info_text\show_time+e_engine_heart_beat\beats_since_start
        e_ingame_info_text\text=world_object()\object_info_text
        ProcedureReturn #False  
      EndIf
      
    EndIf
    
   

  
    If world_object()\object_allert_stay=#False
      
        If world_object()\object_allert_on_player=#True
          world_object()\object_allert_overide_by_player_attack=#True
          world_object()\object_allert_overide_timer_stop=e_engine_heart_beat\beats_since_start+world_object()\object_allert_overide_timer
       EndIf
         
         E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
         E_CLEAN_UP_WEAPON()

       
         ProcedureReturn #False
    EndIf
   ;------------------------------------------------- 
      
    ;first step we use some object internal name releated collision handling:
    Select brain\e_internal_name2

        
      Case "#TRIGGER"
        E_COLLISION_TRIGGER_HANDLING()
         ProcedureReturn #False
             
      Default
        
     
;         

        
        ;--- here we do the default collision check for all other objects:
  
        ;--------------------------
        
        ;go on:
        

        
        ;here is the fight calculation
       
        
        world_object()\object_hp-player_statistics\player_level_fight
        world_object()\object_health_bar_actual_hp=world_object()\object_hp
        world_object()\object_health_bar_update=#True
        
        If world_object()\object_show_boss_bar=#True 
          boss_bar\boss_bar_actual_health=world_object()\object_hp  
          boss_bar\boss_bar_update=#True  
        EndIf
        

           
        If IsSound( player_statistics\player_hit_enemy_sound_id)
          SoundVolume(player_statistics\player_hit_enemy_sound_id,player_statistics\player_hit_enemy_sound_volume)
             PlaySound(player_statistics\player_hit_enemy_sound_id)
          EndIf

  
           
         If world_object()\object_hp<1
           world_object()\object_hp=0
                     ; E_ARENA_LOGIC()  ;not for jumpnrun
           E_DIE_WITH_BOSS_CHECK()
           E_DIE_WITH_GUARD_CHECK()
           E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#KILL_OBJECT);we do Not overide collision settings, this is collision
           
           
           
         Else
           
           E_CHECK_IF_HIT_EFFECT()
           
         EndIf

        E_CLEAN_UP_WEAPON()  
        E_STATUS_TRIGGER() ;here we change the object if hit / collsion, this is used for all objects not defined
  EndSelect
  

EndProcedure









Procedure.i E_ASK_YES_NO(_inf.s,_max_gold.s)
  ;for simple requester handling if in shops:
  
  
  Select e_engine\e_npc_language
               Case #DE
                 
                ProcedureReturn E_CUSTOM_MSG_REQUESTER("Shop:"+world_object()\object_ingame_name," Für "+_inf.s+" kaufen? Du besitzt "+_max_gold.s)
                 
               Case #EN
                 ProcedureReturn E_CUSTOM_MSG_REQUESTER("Shop:"+world_object()\object_ingame_name,"Spend "+_inf.s+" gold? You have "+_max_gold.s)
                 
                 
               Default 
               ProcedureReturn E_CUSTOM_MSG_REQUESTER("Shop:"+world_object()\object_ingame_name,"Spend "+_inf.s+" gold? You have "+_max_gold.s)
             EndSelect
  
EndProcedure



Procedure E_PLAYER_POSITION_ON_KEY()
  ;try to correct player position, so we can jump on  "threw " platforms (button + direction, or just direction, or just button....)

  If world_object()\object_ignore_one_key=#False Or E_XBOX_CONTROLLER_BUTTON_INPUT()<>#B Or player_statistics\player_is_ready_to_fall=#False
  ProcedureReturn #False  
  EndIf
  
  
  Define *_actual_local_element=@world_object()
  
  Define _y.f=world_object()\object_y
  Define _h.f=world_object()\object_h
  
  ChangeCurrentElement(world_object(),player_statistics\player_list_object_id)
  
  If world_object()\object_y<_y.f
 
  world_object()\object_y=_y.f+_h.f
  player_statistics\player_is_ready_to_jump=#False  ;change this  #FALSE, because we need  valid position on ground!
  world_object()\object_is_on_ground=#False
  player_statistics\player_on_ground=#False
  player_statistics\player_is_ready_to_fall=#False
  EndIf
  
  ChangeCurrentElement(world_object(),*_actual_local_element)
  
EndProcedure







Procedure E_CORRECT_POSITION_IF_TRANSPORTED(_void.b)
  
  If _void.b=#False
  ProcedureReturn #False  
  EndIf
  
  ;if player is on object with transporter function (like movable platforms)
 
;   
;   If (world_object()\object_x+e_engine\e_world_offset_x-world_object()\object_move_x)<(e_engine\e_left_margin-e_engine\e_engine_no_scroll_margin)
;     E_KEY_MOVE_WORLD(#LEFT)
;   EndIf
;   
;   If  (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_move_x)>(e_engine\e_right_margin+e_engine\e_engine_no_scroll_margin)
;     E_KEY_MOVE_WORLD(#RIGHT)
;    EndIf
  

  
If(world_object()\object_y+e_engine\e_world_offset_y-world_object()\object_move_y)<(e_engine\e_top_margin-e_engine\e_engine_no_scroll_margin)
  ;E_KEY_MOVE_WORLD_BLOCK_WISE(#UP)
  E_KEY_MOVE_WORLD_PER_PIXEL(#UP)
 

EndIf

 If(world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_move_y)>(e_engine\e_bottom_margin+e_engine\e_engine_no_scroll_margin)
  ; E_KEY_MOVE_WORLD_BLOCK_WISE(#DOWN)
   E_KEY_MOVE_WORLD_PER_PIXEL(#DOWN)
 EndIf
        
  
EndProcedure


Procedure E_CORRECT_PLAYER_POSITION()
  ;try to correct player position, so we can jump on  "on Top " platforms
  
  
   If world_object()\object_check_if_player_on_top=#False 
      ;for some situation like fading platforms:
      ProcedureReturn #False
    EndIf
    
    If world_object()\object_is_transporter=#True
    ProcedureReturn #False  
    EndIf
    
  
    Define _void.b=#False
    Define _move_x.f=0
    Define _move_direction_x.i=#NO_DIRECTION
    Define _y.f=0
    
    Define _is_transporter.b=#False
    Define *_actual_local_element=0
  
  *_actual_local_element=@world_object()
   
  
  _y.f=world_object()\object_y+world_object()\object_hit_box_y
  
  ChangeCurrentElement(world_object(),player_statistics\player_list_object_id)
  
  
  If (world_object()\object_y+world_object()\object_hit_box_h+world_object()\object_hit_box_y)>_y.f
 
  
  world_object()\object_y=_y.f-world_object()\object_hit_box_h-world_object()\object_hit_box_y
  player_statistics\player_is_ready_to_jump=#True
  world_object()\object_is_on_ground=#True
  player_statistics\player_on_ground=#True
  EndIf
  
 ChangeCurrentElement(world_object(),*_actual_local_element)

EndProcedure


Procedure E_CORRECT_PLAYER_POSITION_ON_TRANSPORTER()
  ;try to correct player position, so we can jump on  "on Top " platforms
  
  
   If world_object()\object_check_if_player_on_top=#False 
      ;for some situation like fading platforms:
      ProcedureReturn #False
    EndIf
    
    If world_object()\object_is_transporter=#False
    ProcedureReturn #False  
    EndIf
    
  
    Define _void.b=#False
    Define _move_x.f=0
    Define _move_direction_x.i=#NO_DIRECTION
    Define _y.f=0
    
    Define _is_transporter.b=#False
    Define *_actual_local_element=0
  
  *_actual_local_element=@world_object()
   ;try to correct player position, so we can jump on  "on Top " platforms
   _is_transporter.b=world_object()\object_is_transporter
   
   
   If _is_transporter.b=#True
     _void.b=#True  
     _move_x.f=world_object()\object_move_x
     _move_direction_x.i=world_object()\object_move_direction_x
   EndIf
 
  
  _y.f=world_object()\object_y
  
  ChangeCurrentElement(world_object(),player_statistics\player_list_object_id)
  
  
  If (world_object()\object_y+world_object()\object_h)>_y.f
 
  
  world_object()\object_y=_y.f-world_object()\object_h
  player_statistics\player_is_ready_to_jump=#True
  world_object()\object_is_on_ground=#True
  player_statistics\player_on_ground=#True
  EndIf
  
   E_CORRECT_POSITION_IF_TRANSPORTED(_void.b)

   
  
 If world_object()\object_is_transporter=#True
     ChangeCurrentElement(world_object(),*_actual_local_element)
 EndIf
 
 
 ;E_PLAYER_POSITION_ON_KEY()
EndProcedure


Procedure E_COLLISION_PLAYER_BASE_LOGIC()
  ;here we have some fundamental values/checkings if player collision with map object

  
  If world_object()\object_collision_ignore_player=#True
    E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
    ProcedureReturn #False
  EndIf
  
 E_REMOVE_EMITTER()
  
EndProcedure


Procedure E_COLLISION_PLAYER_HANDLING()
  ;bit more readable
  e_quest_level.i=#QUEST_WAITING
  e_engine\e_player_does_collision=#True
  E_CORRECT_PLAYER_POSITION_ON_TRANSPORTER()
  E_CORRECT_PLAYER_POSITION()
  E_COLLISION_PLAYER_BASE_LOGIC()
  E_FIGHT_DEFAULT()
  
  
  
  
  
;   If world_object()\object_collision_ignore_player=#True
;     E_COLLISION_OVERIDE(#ALL)
;     ProcedureReturn #False
;   EndIf
  
  If world_object()\object_action_on_internal_name=#False
    
    E_COLLISION_NPC()
    E_STATUS_TRIGGER()
    
    E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#NOTHING)
   
      e_engine\e_player_auto_move_direction_x=#NO_DIRECTION  ;default, backup system if player colides and no action is defined
      e_engine\e_player_auto_move_direction_y=#NO_DIRECTION
     ProcedureReturn #False
  EndIf
  
;here we go for some special objects, so we use object internal or given names for internal handling, to select action
  
  Select  brain\e_internal_name2
      
      
    Case "#AXE_PICK_UP"
      E_STATUS_TRIGGER()
      E_PICK_UP_WEAPON(#WEAPON_AXE)

      
     Case "#LOOT_CHEST_ATTACK_UP_OPEN","#LOOT_CHEST_POWER_UP_OPEN","#LOOT_CHEST_SHIELD_UP_OPEN","#EVIL_CRATE"
    E_STATUS_TRIGGER()
      
  Case "#DUNGEON_PORTAL0"
    E_GRAB_SRC_SCREEN()
    
    E_COLLISION_PORTAL_HANDLING_0()
    Case "#DUNGEON_PORTAL1"
      E_GRAB_SRC_SCREEN()
     
      E_COLLISION_PORTAL_HANDLING_1()
    Case "#DUNGEON_PORTAL2"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_2()
    Case "#DUNGEON_PORTAL3"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_3()
    Case "#DUNGEON_PORTAL4"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_4()
    Case "#DUNGEON_PORTAL5"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_5()
    Case "#DUNGEON_PORTAL6"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_6()
  
    Case "#DUNGEON_PORTAL7"
      E_GRAB_SRC_SCREEN()
     
      E_COLLISION_PORTAL_HANDLING_7()
    
    Case "#DUNGEON_PORTAL8"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_8()
    Case "#DUNGEON_PORTAL9"
      E_GRAB_SRC_SCREEN()
      
      E_COLLISION_PORTAL_HANDLING_9()
      
    Case "#TELEPORT_EXIT"
      E_GRAB_SRC_SCREEN()
     

    
    Case "#TRIGGER"
      E_COLLISION_TRIGGER_HANDLING()
      
     Case "#AXE","#BIRD_AXE"
       E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
      
    Case "#BARRIER","#WALL_OF_CHANGE"
         E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
      
    
    Case "#STOP"
      e_engine\e_player_auto_move_direction_x=#NO_DIRECTION ;make shure we give the control back to player 
      e_engine\e_player_auto_move_direction_y=#NO_DIRECTION  ;make shure we give the control back to player 
      E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#ALL)
   
      Case "#INFOBLOCK"
        
        If player_statistics\player_weapon_axe<>#True
          E_COLLISION_NPC()
        Else
          world_object()\object_is_active=#False
          
        EndIf
        
          
         Case "#TELEPORT_BY_TRIGGER"
       E_GRAB_SRC_SCREEN()
       E_DEFAULT_ARENA_EXIT()

         

       
     Default
 
  E_SET_PLAYER_GRAVITY_OFF()
  E_STATUS_TRIGGER()
  E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#FLIP_FLOP)
  
 
  EndSelect
  


EndProcedure




Procedure E_DO_FULL_COLLISION()
  
  ;this is used to check for collisions object (extended system to reduce collisions calculation)
  ;if valid parameters  (id1 <> id2 OR 0) we do full collision check
  ;if no valid parameter (id1=id2 NOT 0)  we jump out of collision check, we do not check collision (enemy<->enemy)
  
  
  
  If brain\e_collision_id1=0 Or  brain\e_collision_id2=0
    ProcedureReturn #True  ;nothing special, we have to check the collision
  EndIf
  
  If brain\e_collision_id1<>brain\e_collision_id2
    ProcedureReturn #True  ;not the same , so we check collision
  EndIf
  
  ProcedureReturn #False  ;do nothing (id1=id2 NOT 0)
EndProcedure








Procedure E_COLLISION_DATA(e_internal_name1.s,e_internal_name2.s,*o1,*o2)
  ;we use the internal name for interaction selection, index is not used for now
  ;here we go for the object interaction 


  E_TIMER_ADD()
  

;check which object colides..

Select  e_internal_name1 .s
    
  Case "#PLAYER","#PLAYER_BIRD"
    E_COLLISION_PLAYER_HANDLING()
    
  Case "#AXE","#BIRD_AXE"
        E_COLLISION_AXE()
    
    
  
  Default 
   
  E_STATUS_TRIGGER()
  E_COLLISION_OVERIDE(brain\e_object_system_id1,brain\e_object_system_id2,#FLIP_FLOP)
    
    
EndSelect
 

EndProcedure




Procedure.b  E_COLLISION_SYSTEM_SIMPLE(move_direction.b,*e_sprite_back_up)
  ;move direction,object_gfx_buffer, actual object list index
 
    
  If world_object()\object_allert_stay=#False  ; we are not ready for fight/not in fight area
  ProcedureReturn  #False   
  EndIf   
  
  If *e_sprite_back_up=0
    ProcedureReturn #False
  EndIf
   
  
  
   
 e_engine\e_is_collision=#False
 ; e_engine\e_is_collision=#False  ;collision status on start
                           ;here we catch some data of the actual world object
  
 
  
;   If   SelectElement(world_object(),e_object_system_id1.i) =0
;   ProcedureReturn #False  
;   EndIf
  
  
  Define x.f =world_object()\object_x+world_object()\object_hit_box_x
  Define y.f=world_object()\object_y+world_object()\object_hit_box_y
  Define mx.f=world_object()\object_move_x
  Define my.f=world_object()\object_move_y
  
  If world_object()\object_auto_move_x<>0
    mx.f=world_object()\object_auto_move_x
  EndIf
  
  If world_object()\object_auto_move_y<>0
    my.f=world_object()\object_auto_move_y
  EndIf
  
  brain\e_internal_name1=world_object()\object_internal_name
  brain\e_collision_id1=world_object()\object_collision_static_id

 
  
  ;here we try to check if collision :
 

  
  If ListSize(indexerC())<1
  ProcedureReturn #False  
  EndIf
  
  ResetList(indexerC())
  
  ForEach indexerC()
    
    e_engine\e_is_collision=#False
      
      ChangeCurrentElement(world_object(),indexerC()\index)

              If IsSprite(world_object()\object_hit_box_gfx_id) And world_object()\object_is_active=#True 
          
        brain\e_collision_id2=world_object()\object_collision_static_id


        brain\e_object_system_id2=@world_object()
        
      
      
        Select move_direction.b
            
          Case #UP
            
           If world_object()\object_collision=#True And world_object()\object_use_gravity=#False
            
             If brain\e_object_system_id1<>brain\e_object_system_id2 ;do not check collision with object of same id
               
               
               If E_DO_FULL_COLLISION()=#True
                     e_engine\e_is_collision=SpriteCollision(*e_sprite_back_up,x.f,y.f-my.f,world_object()\object_hit_box_gfx_id,world_object()\object_x+world_object()\object_hit_box_x,world_object()\object_y+world_object()\object_hit_box_y)
              EndIf
              
              If e_engine\e_is_collision<>#False
                e_engine\e_is_collision=#True ;default
                
                brain\e_internal_name2=world_object()\object_internal_name
                brain\e_collision_id2=world_object()\object_collision_static_id
                E_COLLISION_DATA(brain\e_internal_name1,brain\e_internal_name2,brain\e_object_system_id1,brain\e_object_system_id2)
                ProcedureReturn e_engine\e_is_collision
              EndIf
              
            EndIf
            EndIf
            
            
          Case #DOWN
            
              If world_object()\object_collision=#True
            
            If brain\e_object_system_id1<>brain\e_object_system_id2  ;do not check collision with object of same id
              
              If E_DO_FULL_COLLISION()=#True
              e_engine\e_is_collision=SpriteCollision(*e_sprite_back_up,x.f,y.f+my.f,world_object()\object_hit_box_gfx_id,world_object()\object_x+world_object()\object_hit_box_x,world_object()\object_y+world_object()\object_hit_box_y)
              EndIf
              
              If e_engine\e_is_collision<>#False
                e_engine\e_is_collision=#True ;default
                

                brain\e_internal_name2=world_object()\object_internal_name
                brain\e_collision_id2=world_object()\object_collision_static_id
                E_COLLISION_DATA(brain\e_internal_name1,brain\e_internal_name2,brain\e_object_system_id1,brain\e_object_system_id2)
                        
                ProcedureReturn e_engine\e_is_collision
              EndIf
              
            EndIf
      
          EndIf
          
            
            
        Case #LEFT
          
            If world_object()\object_collision=#True
       
            If brain\e_object_system_id1<>brain\e_object_system_id2 ;do not check collision with object of same id
              
              If E_DO_FULL_COLLISION()=#True
              e_engine\e_is_collision=SpriteCollision(*e_sprite_back_up,x.f-mx.f,y.f,world_object()\object_hit_box_gfx_id,world_object()\object_x+world_object()\object_hit_box_x,world_object()\object_y+world_object()\object_hit_box_y)
            EndIf
            
              
              
              If e_engine\e_is_collision<>#False
                e_engine\e_is_collision=#True ;default
                

                brain\e_internal_name2=world_object()\object_internal_name
                 brain\e_collision_id2=world_object()\object_collision_static_id
                E_COLLISION_DATA(brain\e_internal_name1,brain\e_internal_name2,brain\e_object_system_id1,brain\e_object_system_id2)
             
                
                ProcedureReturn e_engine\e_is_collision
              EndIf
              
            EndIf
              EndIf
            
            
          Case #RIGHT
            
            
              If world_object()\object_collision=#True
            If brain\e_object_system_id1<>brain\e_object_system_id2;do not check collision with object of same id
              
              If E_DO_FULL_COLLISION()=#True
              e_engine\e_is_collision=SpriteCollision(*e_sprite_back_up,x.f+mx.f,y.f,world_object()\object_hit_box_gfx_id,world_object()\object_x+world_object()\object_hit_box_x,world_object()\object_y+world_object()\object_hit_box_y)
              EndIf
              
              If e_engine\e_is_collision<>#False
                e_engine\e_is_collision=#True ;default
               

                 brain\e_internal_name2=world_object()\object_internal_name
                 brain\e_collision_id2=world_object()\object_collision_static_id
                E_COLLISION_DATA(brain\e_internal_name1,brain\e_internal_name2,brain\e_object_system_id1,brain\e_object_system_id2)
          
                
                ProcedureReturn e_engine\e_is_collision
              EndIf
              
            EndIf
  
            EndIf
            
        EndSelect
        
      EndIf 
              

            

     Next

 
       
       
     
EndProcedure




Procedure E_CHECK_INPUT_IDLE()
  

  If e_engine_heart_beat\beats_since_start>e_idle_time_before_input_check.i
    
   E_XBOX_CONTROLLER_RECONNECT()
  EndIf
    
     
   EndProcedure
   
   
     
   Procedure E_QUIT_EXIT_ERROR() 
     E_SAVE_WORLD_TIME()
     E_CLEAN_UP()
     E_LOG("LOG END","LOG END","LOG END") 
     End 
     
   EndProcedure
   
   
   Procedure   E_QUIT() 
     E_SAVE_WORLD_TIME()
     E_NETWORK_OPEN_INTERNET_EXPLORER_WITH_TARGET()
     E_CLEAN_UP()
     E_LOG("LOG END","LOG END","LOG END") 
     End 
     
   EndProcedure



Procedure  E_OBJECT_AUTO_MOVE_X()
  
  If  world_object()\object_auto_move_x>0
    ;world_object()\object_move_direction=#RIGHT
    world_object()\object_last_move_direction_x=#RIGHT
    world_object()\object_move_x=world_object()\object_auto_move_x
  EndIf
  
  If  world_object()\object_auto_move_x<0
    ;   world_object()\object_move_direction=#LEFT
    world_object()\object_last_move_direction_x=#LEFT
    world_object()\object_move_x=world_object()\object_auto_move_x
  EndIf
  
EndProcedure


Procedure  E_OBJECT_AUTO_MOVE_Y()
  
  
  If  world_object()\object_auto_move_y>0
    ; world_object()\object_move_direction=#DOWN
    world_object()\object_last_move_direction_y=#DOWN
    world_object()\object_move_y=world_object()\object_auto_move_y
  EndIf
  
  If  world_object()\object_auto_move_y<0
    ; world_object()\object_move_direction=#UP
    world_object()\object_last_move_direction_y=#UP
    world_object()\object_move_y=world_object()\object_auto_move_y
  EndIf
  
  
EndProcedure
  






Procedure.b E_GRAVITY_CORRECTION()
  
  If e_engine_game_type\engine_gravity=0 Or world_object()\object_use_gravity=#False
    ProcedureReturn #False  
  EndIf
  
   If E_CHECK_IF_OBJECT_IN_ALLERT_AREA()=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_is_jumping=#True 
    ProcedureReturn #False  
  EndIf
  
  
  
  If E_COLLISION_SYSTEM_SIMPLE(#DOWN,*e_sprite_back_up)=#False
    
    If ChangeCurrentElement(world_object(),indexeI()\index)=0
      ProcedureReturn #False  
    EndIf
    
    world_object()\object_move_direction_y=#DOWN
    world_object()\object_last_move_direction_y=#DOWN
  Else
    E_REMOVE_MOVE()
EndIf

 
  
EndProcedure





Procedure E_FOLLOW_PLAYER()
  
  
  
  If player_statistics\player_companion_hunt_for_attraction=#True

  EndIf
  
  
  If world_object()\object_x<(player_statistics\player_pos_x-e_engine\e_world_offset_x) And Random(world_object()\object_follow_player)=1
    If world_object()\object_move_direction_x=#LEFT
    world_object()\object_horizontal_direction_change=#True  
    EndIf
    
    world_object()\object_move_direction_x=#RIGHT
    world_object()\object_last_move_direction_x=#RIGHT
    
    
    ProcedureReturn #False
     EndIf
  
     If world_object()\object_x>((player_statistics\player_pos_x-e_engine\e_world_offset_x)) And Random(world_object()\object_follow_player)=1
         If world_object()\object_move_direction_x=#RIGHT
    world_object()\object_horizontal_direction_change=#True  
    EndIf
    world_object()\object_move_direction_x=#LEFT
    world_object()\object_last_move_direction_x=#LEFT
    
    ProcedureReturn #False
  EndIf
  
  If world_object()\object_y<(player_statistics\player_pos_y-e_engine\e_world_offset_y) And Random(world_object()\object_follow_player)=1
    world_object()\object_move_direction_y=#DOWN
    world_object()\object_last_move_direction_y=#DOWN
    world_object()\object_vertical_direction_change=#True
    ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_y>(player_statistics\player_pos_y-e_engine\e_world_offset_y) And Random(world_object()\object_follow_player)=1
    world_object()\object_move_direction_y=#UP
    world_object()\object_last_move_direction_y=#UP
    world_object()\object_vertical_direction_change=#True
    ProcedureReturn #False
  EndIf
  
  
  
EndProcedure


Procedure E_VELOCE_MOVE_HORIZONTAL_RESET()
  ;set move horizontal to 0
  ;call this if movement is not x
  
  
   
  If e_engine\e_velocity_horizontal_active=#False
    ProcedureReturn #False
  EndIf
   
  
If world_object()\object_use_horizontal_velocity=#False
  ProcedureReturn #False  
EndIf

world_object()\object_move_x=world_object()\object_velocity_horizontal ;!!!
world_object()\object_horizontal_direction_change=#False
  
EndProcedure


Procedure E_VELOCE_MOVE_HORIZONTAL()
  ;try to make a move  veloce
  
  If e_engine\e_velocity_horizontal_active=#False
    ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_horizontal_velocity=#False
  ProcedureReturn #False  
EndIf


  world_object()\object_move_x+world_object()\object_velocity_horizontal
  
  If world_object()\object_move_x>world_object()\object_move_x_max
  world_object()\object_move_x=world_object()\object_move_x_max
  
EndIf

  
EndProcedure



Procedure E_VELOCE_MOVE_VERTICAL_RESET()
  ;set move horizontal to 0
  ;call this if movement is not x
  
  
   
  If e_engine\e_velocity_vertical_active=#False
    ProcedureReturn #False
  EndIf
  
If world_object()\object_use_vertical_velocity=#False
  ProcedureReturn #False  
EndIf


world_object()\object_move_y=world_object()\object_velocity_vertical ;!!!
world_object()\object_vertical_direction_change=#False


  
EndProcedure



Procedure E_VELOCE_MOVE_VERTICAL()
  ;try to make a move  veloce
  
  If e_engine\e_velocity_vertical_active=#False
    ProcedureReturn #False
  EndIf
  
  
  If world_object()\object_use_vertical_velocity=#False
  ProcedureReturn #False  
EndIf


  world_object()\object_move_y+world_object()\object_velocity_vertical
  
  If world_object()\object_move_y>world_object()\object_move_y_max
  world_object()\object_move_y=world_object()\object_move_y_max
  
EndIf

  
  EndProcedure
  
  
  Procedure E_VELOCE_HANDLER()
    ;all default veloce control calls:
    
    
  If world_object()\object_horizontal_direction_change=#True
    E_VELOCE_MOVE_HORIZONTAL_RESET() 
  EndIf
  
  If world_object()\object_vertical_direction_change=#True
    E_VELOCE_MOVE_VERTICAL_RESET() 
  EndIf
  
    
    E_VELOCE_MOVE_VERTICAL()
    E_VELOCE_MOVE_HORIZONTAL()
    
    
    
  EndProcedure

  
  
  
  
Procedure E_JUMP_CORE_ENEMY()
   
If world_object()\object_is_on_ground=#True
  world_object()\object_is_jumping=#False
  world_object()\object_jump_size_actual=0
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  world_object()\object_move_y=world_object()\object_move_y_max
  E_SOUND_PLAY_JUMP()
 EndIf
 
  
 If world_object()\object_jump_size_actual<world_object()\object_jump_size
  world_object()\object_is_on_ground=#False
  world_object()\object_jump_size_actual+world_object()\object_jump_step
  world_object()\object_move_direction_y=#UP
  world_object()\object_last_move_direction_y=#UP
   world_object()\object_is_jumping=#True
 ProcedureReturn #False
  EndIf
  
  ;world_object()\object_jump_size_actual=0
  world_object()\object_is_jumping=#False
  world_object()\object_is_on_ground=#False
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  world_object()\object_is_jumping=#True
  
EndProcedure


Procedure E_JUMP_STOPP()
;use this to stopp jump, from any position of player!  
  world_object()\object_jump_size_actual=world_object()\object_jump_size
EndProcedure


Procedure E_JUMP_CORE_VELOC_ENEMY()
  ;this routine is under developement, we will use jump acceleration
  
  
  
If world_object()\object_is_on_ground=#True
  world_object()\object_is_jumping=#False
  world_object()\object_jump_size_actual=0
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  world_object()\object_move_y=world_object()\object_move_y_max
 E_SOUND_PLAY_JUMP()
 EndIf


 If world_object()\object_jump_size_actual<world_object()\object_jump_size
  world_object()\object_is_on_ground=#False
  world_object()\object_jump_size_actual+world_object()\object_jump_step
  world_object()\object_move_direction_y=#UP
  world_object()\object_last_move_direction_y=#UP
  world_object()\object_is_jumping=#True
  If world_object()\object_move_y>0
    world_object()\object_move_y-world_object()\object_jump_velocity
  EndIf
    ProcedureReturn #False
  EndIf
  
  ;world_object()\object_jump_size_actual=0
  world_object()\object_is_jumping=#False
  world_object()\object_is_on_ground=#False
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  world_object()\object_is_jumping=#True
   If world_object()\object_move_y<world_object()\object_move_y_max
   world_object()\object_move_y+world_object()\object_jump_velocity
 EndIf

 
EndProcedure



Procedure E_JUMP_CORE_MANAGER_ENEMY()
  
If  world_object()\object_jump_velocity>0
  E_JUMP_CORE_VELOC_ENEMY()
  E_EMITTER_ON_JUMP()
Else
      
  E_JUMP_CORE_ENEMY()
  E_EMITTER_ON_JUMP()
EndIf



EndProcedure



Procedure E_JUMP_CORE()
  
  
  
  
  If world_object()\object_is_jumping=#False
  world_object()\object_jump_size_actual=0
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  ProcedureReturn #False
  EndIf
  
  
  
 If world_object()\object_jump_size_actual<world_object()\object_jump_size
  world_object()\object_is_on_ground=#False
  world_object()\object_jump_size_actual+world_object()\object_jump_step
  world_object()\object_move_direction_y=#UP
  world_object()\object_last_move_direction_y=#UP
  ProcedureReturn #False
  EndIf
  
  world_object()\object_jump_size_actual=0
  world_object()\object_is_jumping=#False
  world_object()\object_is_on_ground=#False
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
EndProcedure

Procedure E_JUMP_CORE_VELOC()
  ;this routine is under developement, we will use jump acceleration
  
 
  
  
If world_object()\object_is_on_ground=#True
  world_object()\object_move_y=world_object()\object_move_y_max 
EndIf

  ;player_statistics\player_move_y=world_object()\object_move_y ;for debugging
  
  If world_object()\object_is_jumping=#False
  world_object()\object_jump_size_actual=0
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
  world_object()\object_move_y=world_object()\object_move_y_max
  ProcedureReturn #False
  EndIf
  
  
  
 If world_object()\object_jump_size_actual<world_object()\object_jump_size
  world_object()\object_is_on_ground=#False
  world_object()\object_jump_size_actual+world_object()\object_jump_step
  world_object()\object_move_direction_y=#UP
  world_object()\object_last_move_direction_y=#UP
  If world_object()\object_move_y>0
    world_object()\object_move_y-world_object()\object_jump_velocity
  EndIf
  
  ProcedureReturn #False
  EndIf
  
  world_object()\object_jump_size_actual=0
  world_object()\object_is_jumping=#False
  world_object()\object_is_on_ground=#False
  world_object()\object_move_direction_y=#DOWN
  world_object()\object_last_move_direction_y=#DOWN
   If world_object()\object_move_y<world_object()\object_move_y_max
   world_object()\object_move_y+world_object()\object_jump_velocity
 EndIf
 
 
EndProcedure


Procedure E_JUMP_CORE_MANAGER()
  
  If world_object()\object_can_jump=#False Or world_object()\object_use_gravity=#False
    ProcedureReturn #False  
  EndIf
  
  
  
If  world_object()\object_jump_velocity>0
   
     E_JUMP_CORE_VELOC()
Else
      
      E_JUMP_CORE()
    EndIf
    
    
  
EndProcedure

 
    

  Procedure E_KEEP_DIRECTION_ON_DEFAULT_VALUE()
    
    ;this will keep the movement in direction if static move
    
     If world_object()\object_static_move=#False
         ProcedureReturn #False  
     EndIf
;     
;     If world_object()\object_overide_static_move=#True  ;for objects witch use static move from start (at creation) but do not use any static move after
;     ProcedureReturn #False  
;     EndIf
;     

    
    Select world_object()\object_use_default_direction
        
      Case "#UP"
          world_object()\object_move_direction_y=#UP
          world_object()\object_last_move_direction_y=#UP
        
      Case "#DOWN"
        world_object()\object_move_direction_y=#DOWN
          world_object()\object_last_move_direction_y=#DOWN
        
        
      Case "#LEFT"
        world_object()\object_move_direction_x=#LEFT
        world_object()\object_last_move_direction_x=#LEFT
        
        
      Case "#RIGHT"
        world_object()\object_move_direction_x=#RIGHT
        world_object()\object_last_move_direction_x=#RIGHT
    
        
    EndSelect
    
    
    
    
    
  EndProcedure


  
  
  Procedure E_CHANGE_DIRECTION_ON_RANDOM_VALUE()
    
    ;this is the new routine for random movement E_AI_RANDOM_FAST_MOVE() an E_AI_RANDOM_MOVE() stay in place for legacy support
    
    If world_object()\object_change_direction_on_random=#False
        ProcedureReturn #False  
    EndIf
    
    
    
    If Random(world_object()\object_random_change_direction_x)=1
     
      Select world_object()\object_last_move_direction_x
          
        Case #LEFT
          
          world_object()\object_move_direction_x=#RIGHT
          world_object()\object_last_move_direction_x=#RIGHT
          world_object()\object_horizontal_direction_change=#True
          
        Case #RIGHT
          
          world_object()\object_move_direction_x=#LEFT
          world_object()\object_last_move_direction_x=#LEFT
          world_object()\object_horizontal_direction_change=#True
          
          
          
        Default 
          world_object()\object_move_direction_x=#LEFT
          world_object()\object_last_move_direction_x=#LEFT
          world_object()\object_horizontal_direction_change=#True

          
      EndSelect
      
           
    EndIf
    
      
       ;if we jump only x values can change by AI
       If world_object()\object_is_jumping=#True
       ProcedureReturn #False   
       EndIf
       ;------------------------
    
    If Random(world_object()\object_random_change_direction_y)=1
      
 
      
        Select world_object()\object_last_move_direction_y
          
          Case #UP
            
           world_object()\object_move_direction_y=#DOWN
           world_object()\object_last_move_direction_y=#DOWN
           world_object()\object_vertical_direction_change=#True
          
        Case #DOWN
          
                world_object()\object_move_direction_y=#UP
                world_object()\object_last_move_direction_y=#UP
                world_object()\object_vertical_direction_change=#True
                
              Default
                
                world_object()\object_move_direction_y=#UP
                world_object()\object_last_move_direction_y=#UP
                world_object()\object_vertical_direction_change=#True
         

      EndSelect
      
      
    EndIf
    
    
    
    
  EndProcedure
  
  

  
;     Procedure E_CHECK_FOR_TURN_PIXEL_MOVE_X()
;       
;       
;        If world_object()\object_use_life_time_per_pixel=#True
;       ProcedureReturn #False  
;       EndIf
;       
;       
;       
;       If  world_object()\object_change_direction_x_on_max=#False 
;         ProcedureReturn #False  
;       EndIf
;       
;        
;       
;       Select world_object()\object_last_move_direction_x
;           
;         Case #LEFT
;           
;          
;             
;             world_object()\object_life_time_pixel_count_x+world_object()\object_move_x
;             
;             If world_object()\object_life_time_pixel_count_x<world_object()\object_life_time_pixel_x
;             ProcedureReturn #False  
;             EndIf
;             
;           
;             E_REMOVE_MOVE_PIXEL_LIFETIME()
;          
;         
;               
;               world_object()\object_move_direction_x=#RIGHT 
;               world_object()\object_last_move_direction_x=#RIGHT
;               world_object()\object_life_time_pixel_count_x=0
;               
; 
;               world_object()\object_horizontal_direction_change=#True
;               E_REBUILD_POSITION_AFTER_PIXEL_LIFETIME_XY()
;               If world_object()\object_change_after_pixel_count=#True
;                 world_object()\object_can_change=#True 
;                 E_STATUS_TRIGGER()
;               EndIf
;            
;             
;       
;           
;           
;           
;         Case #RIGHT
;         
; ;             
;              world_object()\object_life_time_pixel_count_x+world_object()\object_move_x
; ;             
; ;             
;              If world_object()\object_life_time_pixel_count_x<world_object()\object_life_time_pixel_x
;             ProcedureReturn #False  
;             EndIf
;             
;             
;             E_REMOVE_MOVE_PIXEL_LIFETIME()
;             
;          
;                world_object()\object_move_direction_x=#LEFT
;                world_object()\object_last_move_direction_x=#LEFT
;               world_object()\object_life_time_pixel_count_x=0
; 
;               world_object()\object_horizontal_direction_change=#True
;               E_REBUILD_POSITION_AFTER_PIXEL_LIFETIME_XY()
;               If world_object()\object_change_after_pixel_count=#True
;                 world_object()\object_can_change=#True  
;                 E_STATUS_TRIGGER()
;               EndIf
;               
;          
; ;             
;      
;       EndSelect 
;        
;       
;     EndProcedure
;     
    
    
    
;     Procedure E_CHECK_FOR_TURN_PIXEL_MOVE_Y()
;       
;       If world_object()\object_use_life_time_per_pixel=#True
;       ProcedureReturn #False  
;       EndIf
;       
;       
;       If  world_object()\object_change_direction_y_on_max=#False 
;         ProcedureReturn #False  
;       EndIf
;       
;        ;if we jump only x values can change by AI
;        If world_object()\object_is_jumping=#True 
;        ProcedureReturn #False   
;        EndIf
;        
;        If world_object()\object_life_time_pixel_y<1
;        ProcedureReturn #False  
;        EndIf
;        
;        
;        ;AI jumpsection
;        
;       
;            
;     Select world_object()\object_last_move_direction_y
;         
;         
;       Case #UP
;         
;           world_object()\object_life_time_pixel_count_y+world_object()\object_move_y
;           If world_object()\object_life_time_pixel_count_y<world_object()\object_life_time_pixel_y
;           ProcedureReturn #False  
;           EndIf
;           
;          
;             E_REMOVE_MOVE_PIXEL_LIFETIME()
;         
;          
;             world_object()\object_move_direction_y=#DOWN
;             world_object()\object_last_move_direction_y=#DOWN
;             world_object()\object_life_time_pixel_count_y=0
;             world_object()\object_vertical_direction_change=#True
;                If world_object()\object_change_after_pixel_count=#True
;                  world_object()\object_can_change=#True  
;                  E_STATUS_TRIGGER()
;              EndIf
;         
;           
;        
;         
;           Case #DOWN
;       
;           world_object()\object_life_time_pixel_count_y+world_object()\object_move_y
;           If world_object()\object_life_time_pixel_count_y<world_object()\object_life_time_pixel_y
;           ProcedureReturn #False  
;           EndIf
;           
;           
;             E_REMOVE_MOVE_PIXEL_LIFETIME()
;       
;           
;             world_object()\object_move_direction_y=#UP
;             world_object()\object_last_move_direction_y=#UP
;              world_object()\object_life_time_pixel_count_y=0
; 
;              world_object()\object_vertical_direction_change=#True
;                 If world_object()\object_change_after_pixel_count=#True
;                   world_object()\object_can_change=#True 
;                   E_STATUS_TRIGGER()
;       EndIf
;     
;       
;        EndSelect 
;        
;  
;     
;   EndProcedure
;   
  
  Procedure E_CHECK_FOR_PIXEL_MOVE()
    
    
    If world_object()\object_life_time_pixel_x=0 And world_object()\object_life_time_pixel_y=0
    ProcedureReturn #False  
    EndIf
    

       
    
    Select world_object()\object_move_direction_x
        
        
      Case #LEFT,#RIGHT
        
        If world_object()\object_life_time_pixel_x>0
          world_object()\object_life_time_pixel_count_x+world_object()\object_move_x
       
          
          If world_object()\object_life_time_pixel_count_x>world_object()\object_life_time_pixel_x
                If world_object()\object_change_after_pixel_count=#True
                        world_object()\object_can_change=#True  
                        E_STATUS_TRIGGER()
                        ProcedureReturn #False
                      EndIf
                      
            If world_object()\object_remove_after_pixel_count=#True
              world_object()\object_remove_from_list=#True
              ProcedureReturn #False
            EndIf
            
            If world_object()\object_change_direction_x_on_max=#True
              world_object()\object_life_time_pixel_count_x=0
              
              Select world_object()\object_move_direction_x
                  
                Case #RIGHT
                  world_object()\object_move_direction_x=#LEFT
                  world_object()\object_last_move_direction_x=#LEFT
                  
                Case #LEFT
                  world_object()\object_move_direction_x=#RIGHT
                  world_object()\object_last_move_direction_x=#RIGHT
                  EndSelect
                
              
            EndIf
            
             
              If world_object()\object_stop_after_pixel_count=#True  
               E_REMOVE_MOVE_PIXEL_LIFETIME()
              EndIf
              
                     
            EndIf
            
        EndIf
   
          

        
    
        
       EndSelect 
       
         
       ;if we jump only x values can change by AI
       If world_object()\object_is_jumping=#True
       ProcedureReturn #False   
       EndIf
       ;------------------------
       
       Select world_object()\object_move_direction_y
      Case #UP,#DOWN
       
        If world_object()\object_life_time_pixel_y>0
          world_object()\object_life_time_pixel_count_y+world_object()\object_move_y
          If world_object()\object_life_time_pixel_count_y>world_object()\object_life_time_pixel_y
            
                      If world_object()\object_change_after_pixel_count=#True
                        world_object()\object_can_change=#True  
                        E_STATUS_TRIGGER()
                         ProcedureReturn #False
                      EndIf
            If world_object()\object_remove_after_pixel_count=#True
              world_object()\object_remove_from_list=#True
              ProcedureReturn #False
            EndIf
            
            
             If world_object()\object_change_direction_y_on_max=#True
              world_object()\object_life_time_pixel_count_y=0
              Select world_object()\object_move_direction_y
                Case #UP
                  world_object()\object_move_direction_y=#DOWN
                  world_object()\object_last_move_direction_y=#DOWN
                  
                Case #DOWN
                  world_object()\object_move_direction_y=#UP
                  world_object()\object_last_move_direction_y=#UP
                  EndSelect
                
              
            EndIf
            
            
               If world_object()\object_stop_after_pixel_count=#True  
               E_REMOVE_MOVE_PIXEL_LIFETIME()
              EndIf
            EndIf
            
            
          EndIf
          
       
        
        
    EndSelect
    
    
   
    
    
  EndProcedure
  
  Procedure E_JUMP_START_ENEMY()
    

    
    
    If world_object()\object_can_jump=#False 
    ProcedureReturn #False  
    EndIf
    
    
    
  
    
    
      
;     If world_object()\object_use_random_jump=#True And world_object()\object_is_jumping=#True
;   If Random(world_object()\object_jump_start_random)=1  
;      world_object()\object_is_jumping=#False
;       ProcedureReturn #False
;     EndIf
;   EndIf
;   
    
    
     If world_object()\object_is_jumping=#True
       E_JUMP_CORE_MANAGER_ENEMY()  
       
     If world_object()\object_stop_jump_counter>0 
      world_object()\object_jump_counter+1  
      
     If world_object()\object_jump_counter>world_object()\object_stop_jump_counter
        world_object()\object_jump_counter=0
       world_object()\object_is_jumping=#False
      ProcedureReturn #False
      EndIf
   
    EndIf
    
       ProcedureReturn #False
  EndIf
    
    
  If world_object()\object_use_random_jump=#True And world_object()\object_is_jumping=#False
  If Random(world_object()\object_jump_start_random)=1  
      E_JUMP_CORE_MANAGER_ENEMY()
      ProcedureReturn #False
    EndIf
  EndIf
  

  
    
  If world_object()\object_use_random_jump=#False And world_object()\object_is_jumping=#False
    E_JUMP_CORE_MANAGER_ENEMY()
  EndIf
  
 
  
    
EndProcedure



Procedure.b E_ENEMY_MOVEMENT_LOGIC()
  
  world_object()\object_horizontal_direction_change=#False
  
  world_object()\object_guarded=#False
  
  If world_object()\object_stop_if_guard_on_screen=#True
    If e_engine\e_count_active_boos_guards>0
      world_object()\object_guarded=#True
      world_object()\object_move_direction_x=#NO_DIRECTION
      world_object()\object_move_direction_y=#NO_DIRECTION
      world_object()\object_last_move_direction_x=#NO_DIRECTION
      world_object()\object_last_move_direction_y=#NO_DIRECTION
      ProcedureReturn #False  
    EndIf
    
  EndIf
  
  
  If world_object()\object_stop_move_right_border=#True
    If (world_object()\object_x+world_object()\object_hit_box_w+e_engine\e_world_offset_x)>e_engine\e_engine_internal_screen_w
      world_object()\object_move_direction_x=#NO_DIRECTION
      world_object()\object_move_direction_y=#NO_DIRECTION
       world_object()\object_horizontal_direction_change=#True
        ProcedureReturn #False 
    EndIf
  EndIf
  
  
 ; If e_engine\e_engine_scroll_map=#True Or e_engine\e_engine_scroll_map=#False  ;???????????????????????? remove this shit!
    If world_object()\object_turn_on_right_border=#True
      If (world_object()\object_x+world_object()\object_hit_box_w+world_object()\object_move_x+e_engine\e_world_offset_x)>e_engine\e_engine_internal_screen_w
        world_object()\object_move_direction_x=#LEFT
        world_object()\object_last_move_direction_x=#LEFT
        world_object()\object_horizontal_direction_change=#True
        world_object()\object_overide_static_move=#True
        If world_object()\object_turn_on_right_border=#True
        world_object()\object_x-world_object()\object_hit_box_w
        EndIf
        
        ProcedureReturn #False 
      EndIf
    EndIf
;EndIf
  
;   If e_engine\e_engine_scroll_map=#False
;     If world_object()\object_turn_on_right_border=#True
;       If (world_object()\object_x+world_object()\object_hit_box_w+world_object()\object_move_x+e_engine\e_world_offset_x)>e_engine\e_engine_internal_screen_w
;         world_object()\object_move_direction_x=#LEFT
;         world_object()\object_last_move_direction_x=#LEFT
;         world_object()\object_horizontal_direction_change=#True
;         world_object()\object_overide_static_move=#True
;    world_object()\object_x-world_object()\object_hit_box_w
;         ProcedureReturn #False 
;       EndIf
;     EndIf
;   EndIf
;   
  
  
  
  If e_engine\e_engine_scroll_map=#True Or e_engine\e_engine_scroll_map=#False
  If world_object()\object_turn_on_left_screen=#True  
    If (world_object()\object_x+world_object()\object_hit_box_w+e_engine\e_world_offset_x)<e_engine\e_left_margin
      world_object()\object_move_direction_x=#RIGHT
      world_object()\object_last_move_direction_x=#RIGHT
     ; world_object()\object_horizontal_direction_change=#True  ;do not use this! because map could scroll faster than movement of object, so it is outside of action
      
    
        ProcedureReturn #False
    EndIf
    
  EndIf
EndIf



;   If e_engine\e_engine_scroll_map=#False
;   If world_object()\object_turn_on_left_screen=#True  
;     If (world_object()\object_x+world_object()\object_hit_box_w+e_engine\e_world_offset_x)<e_engine\e_left_margin
;       world_object()\object_move_direction_x=#RIGHT
;       world_object()\objecT_last_move_direction_x=#RIGHT
;       ;world_object()\object_horizontal_direction_change=#True
;       ;no workaround for now... 
;       
;         ProcedureReturn #False
;     EndIf
;     
;   EndIf
; EndIf

  
  If world_object()\object_turn_on_screen_center=#True
    If (world_object()\object_x+world_object()\object_hit_box_w+e_engine\e_world_offset_x)<e_engine\e_engine_internal_screen_w/2
      world_object()\object_move_direction_x=#RIGHT
      world_object()\objecT_last_move_direction_x=#RIGHT
      world_object()\object_horizontal_direction_change=#True
      world_object()\object_overide_static_move=#True
      ProcedureReturn #False
    EndIf
    
  EndIf
  
  If  world_object()\object_is_jumping=#False
    If world_object()\object_allert_stay=#False  ; we are not ready for fight/not in fight area
      ProcedureReturn  #False   
    EndIf   
  EndIf
  
  ProcedureReturn #True
  
  
  
EndProcedure






Procedure  E_PIXEL_MOVE_LOGIC()
  ;routines to change direction if pixel...
  E_CHECK_FOR_PIXEL_MOVE()
;   E_CHECK_FOR_TURN_PIXEL_MOVE_X() 
;   E_CHECK_FOR_TURN_PIXEL_MOVE_Y() 
  
  ;E_CHANGE_DIRECTION_ON_DEFAULT_VALUE()
  E_CHANGE_DIRECTION_ON_RANDOM_VALUE()
  
EndProcedure




Procedure E_ENEMY_MOVE()
  
  ;we need an origin enemy collision and movement handler....
  ;if enemy AI Level <1, enemy/object will NOT MOVE
  

  ;try it here :))))
  
   
  If world_object()\object_move_direction_x<>#NO_DIRECTION Or world_object()\object_move_direction_y<>#NO_DIRECTION
    E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_MOVE)
  EndIf
  
   
  If world_object()\object_static_move=#True
  ProcedureReturn #False  
  EndIf
  
  If E_ENEMY_MOVEMENT_LOGIC()=#False
  If world_object()\object_horizontal_direction_change=#True
    E_VELOCE_MOVE_HORIZONTAL_RESET() 
    world_object()\object_horizontal_direction_change=#False
  EndIf
  
    If world_object()\object_vertical_direction_change=#True
    E_VELOCE_MOVE_VERTICAL_RESET() 
    world_object()\object_vertical_direction_change=#False
  EndIf
  
    ProcedureReturn #False
  EndIf
  
  ;---------------------
    
  


  
  If world_object()\object_follow_player<>0  ;random value base
    E_FOLLOW_PLAYER()
  EndIf
  
  
 
 
  E_PIXEL_MOVE_LOGIC()
  E_OBJECT_AUTO_MOVE_X()
  E_VELOCE_HANDLER()
  E_JUMP_START_ENEMY()
   
  
 If world_object()\object_is_jumping=#False
    E_OBJECT_AUTO_MOVE_Y()
 EndIf
 
 

 
  ;E_AI_BASE(world_object()\object_use_ai)  ;default 
  
  
 If world_object()\object_is_jumping=#False
  If world_object()\object_move_direction_y=#UP And world_object()\object_use_gravity=#True 
  world_object()\object_move_direction_y=#NO_DIRECTION  
  EndIf
  
EndIf




  
EndProcedure



Procedure E_OBJECT_NO_COLLISION_HANDLING()
  
  If world_object()\object_collision=#True
  ProcedureReturn #False  
  EndIf
  
    
    
    Select world_object()\object_move_direction_y
        
      Case #UP
        
        If(world_object()\object_y+e_engine\e_world_offset_y-world_object()\object_move_y)>0
          world_object()\object_y-world_object()\object_move_y
         
        EndIf
        
      Case #DOWN
        
        If(world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_move_y)<v_screen_h
          world_object()\object_y+world_object()\object_move_y
         
        EndIf
        
    EndSelect
    
    Select world_object()\object_move_direction_x
        
      Case #LEFT
        If(world_object()\object_x+e_engine\e_world_offset_x-world_object()\object_move_x)>0
          world_object()\object_x-world_object()\object_move_x
          E_VELOCE_MOVE_HORIZONTAL()
        EndIf
        
        
        
      Case #RIGHT
        If(world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_move_x)<v_screen_w
          world_object()\object_x+world_object()\object_move_x
          E_VELOCE_MOVE_HORIZONTAL()
        EndIf
        
    EndSelect
    



  
EndProcedure


Procedure E_PLAYER_MOVE_COLLISION()
  
  ;now we got our own player collsion routine! (with collision check)
  
  If world_object()\object_is_player=0
  ProcedureReturn   #False
  EndIf
  
  If world_object()\object_collision=#False
  ProcedureReturn #False  
  EndIf
  
  
  Define _player_id.i=0
  Define _object_id.i=0
  Define _key.i=#NO_BUTTON  
  Define _button.i=#NO_BUTTON
  Define _key_gamepad.i=#NO_BUTTON
  Define _button_gamepad.i=#NO_DIRECTION                 
  
  e_engine\e_player_auto_move_direction_x=#NO_DIRECTION
  e_engine\e_player_auto_move_direction_y=#NO_DIRECTION
  e_engine_world_control\use_global_scroll=#False
  
 
            player_statistics\player_key_pressed=#False
            player_statistics\player_moves_world=#False
      ;  If world_object()\object_is_jumping=#False Or world_object()\object_use_gravity=#False
            world_object()\object_move_direction_x=#NO_DIRECTION  ;need this for correct GFX output, it will be set to last_move_direction_x, as this will show the right anim face/frame
 ;          world_object()\object_move_direction_y=#NO_DIRECTION
;          world_object()\object_last_move_direction_y=#NO_DIRECTION
        ;EndIf
            
            If world_object()\object_use_gravity=#False 
             world_object()\object_move_direction_y=#NO_DIRECTION 
            EndIf
            
      
          ;------------------------  work around for some wrong anim effects----
            world_object()\object_anim_move_direction_x=#NO_DIRECTION
            world_object()\object_anim_move_direction_y=#NO_DIRECTION
         ;-------------------------------------------------------------
        
        If  e_engine\e_npc_text_field_show=#True  ;if textfield is shown we do not move!
          ProcedureReturn #False
        EndIf
        
  
        
 
          
         If  e_xbox_controller\xbox_joystick_present=#True 
           _key_gamepad.i=E_XBOX_CONTROLLER_DIRECTION_L_STICK()
            _button_gamepad.i=E_XBOX_CONTROLLER_BUTTON_INPUT()
            If _key_gamepad.i=#NO_DIRECTION
            _key_gamepad.i=E_XBOX_CONTROLLER_DIRECTION_DPAD()  
            EndIf
            
      
        EndIf
        
       
          If  e_xbox_controller\xbox_joystick_present=#False 
          _key_gamepad.i=E_KEYBOARD_INPUT_DIRECTION()
          _button_gamepad.i=E_KEYBOARD_INPUT_KEYS()
          
          If _button_gamepad.i=#NO_BUTTON
            _button.i=E_GAME_INPUT_MOUSE()  
          EndIf
          
      
        EndIf
      
        
            
;             
         Select _key_gamepad.i
;                 
           Case #UP
             ;              
             If world_object()\object_use_gravity=#False
             If world_object()\object_move_flappy_mode=#False
               If world_object()\object_use_gravity=#True 
                 ProcedureReturn #False  
               EndIf
              
                world_object()\object_move_direction_y=#UP
                world_object()\object_last_move_direction_y=#UP
            
               EndIf
               
             EndIf
             
               
              Case #DOWN
                world_object()\object_move_direction_y=#DOWN
                world_object()\object_last_move_direction_y=#DOWN
              
                
              Case #LEFT
                world_object()\object_move_direction_x=#LEFT
                world_object()\object_last_move_direction_x=#LEFT
                player_statistics\player_last_direction=#LEFT
                world_object()\object_anim_move_direction_x=#LEFT
                
                E_VELOCE_MOVE_HORIZONTAL()
                 
;                  If player_statistics\player_on_ground=#False  ;does not work for now
;             world_object()\object_move_direction_y=#DOWN
;             world_object()\object_last_move_direction_y=#DOWN
;             player_statistics\player_last_direction=#DOWN
;           EndIf
             
                
              Case #RIGHT
                world_object()\object_move_direction_x=#RIGHT
                world_object()\object_last_move_direction_x=#RIGHT
                player_statistics\player_last_direction=#RIGHT
                world_object()\object_anim_move_direction_x=#RIGHT
                 
                E_VELOCE_MOVE_HORIZONTAL()  
                
;             If player_statistics\player_on_ground=#False  ;does not work for now..
;             world_object()\object_move_direction_y=#DOWN
;             world_object()\object_last_move_direction_y=#DOWN
;             player_statistics\player_last_direction=#DOWN
;           EndIf
              Default
                
              E_VELOCE_MOVE_HORIZONTAL_RESET()
                
          
            EndSelect
            
            
            Select _button_gamepad.i
                
              Case #A
                
                
;                 If e_xbox_controller\xbox_joystick_button_hold=#True  ;not used/implemented in xbox controller routine
;                 ProcedureReturn #False  
;                 EndIf
                
              
               
                If world_object()\object_move_flappy_mode=#True And player_statistics\player_is_ready_to_jump=#True
                  world_object()\object_move_direction_y=#UP
                   world_object()\object_is_jumping=#True
                   player_statistics\player_is_ready_to_jump=#False
                  
                                   
               E_SOUND_PLAY_JUMP()
               
             EndIf
           
                
             If player_statistics\player_is_ready_to_jump=#True   And world_object()\object_move_flappy_mode=#False
                
                  player_statistics\player_is_ready_to_fall=#True
             If player_statistics\player_on_ground=#True 
               world_object()\object_is_jumping=#True
               player_statistics\player_is_ready_to_jump=#False
               E_SOUND_PLAY_JUMP()
             EndIf
           EndIf
      
           
         Case #B
           
           
           
           
         Case #X
          
           
              Default
                player_statistics\player_is_ready_to_jump=#True
                player_statistics\player_is_ready_to_fall=#True
                
                
                
                
         
            EndSelect
    
     
             

  
        ; E_JUMP_CORE()  ;workin(no velocity)
        
        ;E_JUMP_CORE_VELOC()  ;new with velocity...test it..
        
        E_JUMP_CORE_MANAGER()
  
; e_player_move_direction_x.i=world_object()\object_move_direction_x       
;e_player_move_direction_y.i=world_object()\object_move_direction_y

        If _button_gamepad.i<>#NO_BUTTON Or _key_gamepad.i<>#NO_DIRECTION
          world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer  
          E_SET_UP_FOR_INPUT_IDLE()  
        EndIf
        
    
  If e_engine\e_player_auto_move_direction_x<>#NO_DIRECTION
     world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer  
    world_object()\object_move_direction_x=e_engine\e_player_auto_move_direction_x
    world_object()\object_last_move_direction_x=e_engine\e_player_auto_move_direction_x
  EndIf
  
  If e_engine\e_player_auto_move_direction_y<>#NO_DIRECTION
     world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer  
    world_object()\object_move_direction_y=e_engine\e_player_auto_move_direction_y
    world_object()\object_last_move_direction_y=e_engine\e_player_auto_move_direction_y
  EndIf
  

  If world_object()\object_move_direction_x<>#NO_DIRECTION 
  
player_statistics\player_move_direction_x=world_object()\object_move_direction_x
player_statistics\player_move_direction_y=world_object()\object_move_direction_y
  E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_MOVE)  

EndIf



  If e_engine\e_engine_scroll_map=#False

   If (world_object()\object_x+world_object()\object_w+e_engine\e_world_offset_x)>e_engine\e_engine_internal_screen_w
     world_object()\object_x-world_object()\object_move_x ;-world_object()\object_w
   EndIf
   
   
      If (world_object()\object_x+e_engine\e_world_offset_x)<e_engine\e_left_margin
     world_object()\object_x+world_object()\object_move_x ;-world_object()\object_w
   EndIf

 EndIf
 
 world_object()\object_action_status_x=world_object()\object_move_direction_x
 world_object()\object_action_status_y=world_object()\object_move_direction_y
 
 

 
 
 brain\e_object_system_id1=@world_object()

   
   ;get the temporary sprite for collsions check:
   

    *e_sprite_back_up=0 

    
 
    
        If IsSprite(world_object()\object_gfx_id_default_frame)
          
           If IsSprite(world_object()\object_hit_box_gfx_id)
        *e_sprite_back_up=world_object()\object_hit_box_gfx_id
        
      Else
        *e_sprite_back_up=world_object()\object_gfx_id_default_frame
      EndIf
      
          
      Else
        ProcedureReturn #False
      EndIf
      
     
  
        
        e_world_object\e_world_object_1_attack=world_object()\object_attack
        e_world_object\e_world_object_1_hp=world_object()\object_hp
        
  
       
        If world_object()\object_move_direction_x=#LEFT 
          
          If E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_x,*e_sprite_back_up)=#False
            
            If  ChangeCurrentElement(world_object(), indexeI()\index)=0
              
              ProcedureReturn #False  
            EndIf
            
            If (world_object()\object_x+e_engine\e_world_offset_x-world_object()\object_move_x)<(e_engine\e_left_margin-e_engine\e_engine_no_scroll_margin)
              E_KEY_MOVE_WORLD(#LEFT)
              
            Else
              world_object()\object_x-world_object()\object_move_x
              
            EndIf
            
          Else
          
            E_IN_AIR_TIMER_KILL(#RESET)
            
          EndIf
          
        EndIf
  
      
     
        
        If   world_object()\object_move_direction_x=#RIGHT
          
          If E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_x,*e_sprite_back_up)=#False
            If ChangeCurrentElement(world_object(),indexeI()\index)=0
              
              ProcedureReturn #False  
            EndIf
            
            
            If  (world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_move_x)>(e_engine\e_right_margin+e_engine\e_engine_no_scroll_margin)
              E_KEY_MOVE_WORLD(#RIGHT)
              
            Else
              world_object()\object_x+world_object()\object_move_x
              
            EndIf
            
          Else
            
            E_IN_AIR_TIMER_KILL(#RESET)
            
          EndIf
          
        EndIf

      
       
        
        If   world_object()\object_move_direction_y=#DOWN 
          
                  
          If E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_y,*e_sprite_back_up)=#False
            
            If ChangeCurrentElement(world_object(),indexeI()\index)=0
              ProcedureReturn #False  
            EndIf
            
            If (world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_move_y)>(e_engine\e_bottom_margin+e_engine\e_engine_no_scroll_margin)
              E_KEY_MOVE_WORLD(#DOWN)
                          player_statistics\player_on_ground=#False

            Else
              world_object()\object_y+world_object()\object_move_y
              world_object()\object_is_on_ground=#False
              player_statistics\player_on_ground=#False
            EndIf
            
          Else
            world_object()\object_is_on_ground=#True
            player_statistics\player_on_ground=#True
            world_object()\object_move_direction_y=#NO_DIRECTION
            E_IN_AIR_TIMER_KILL(#RESET)
          EndIf
       
        EndIf
  
      
     
           
        If  world_object()\object_move_direction_y=#UP
          
       
  
          If  E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_y,*e_sprite_back_up)=#False
            If ChangeCurrentElement(world_object(), indexeI()\index)=0
              ProcedureReturn #False  
            EndIf
            
            If(world_object()\object_y+e_engine\e_world_offset_y-world_object()\object_move_y)<(e_engine\e_top_margin-e_engine\e_engine_no_scroll_margin)
              E_KEY_MOVE_WORLD(#UP)
             
                         Else
                           world_object()\object_y-world_object()\object_move_y
                            world_object()\object_is_on_ground=#False
                            player_statistics\player_on_ground=#False
              
            EndIf
       
          EndIf
          
        EndIf
        
  
      
        
       
        E_GRAVITY_CORRECTION()
   



  
EndProcedure




Procedure E_KEY_MOVE(_type.i)
  
  ;_type.l= #IS_PLAYER.....#IS_ENEMY...
  ;so we can select what to do with one universal routine
  


      
  If  E_OBJECT_MOVE_TIMER()=#True
    ProcedureReturn #False  
 
  Else
    E_ENEMY_MOVE() 
  EndIf

    

world_object()\object_did_collision=#False
world_object()\object_action_status_x=world_object()\object_move_direction_x
world_object()\object_action_status_y=world_object()\object_move_direction_y


  
  ; --- end of no collision section 

brain\e_object_system_id1=@world_object()

   
   ;get the temporary sprite for collsions check:
   

    *e_sprite_back_up=0 

    
 
    
        If IsSprite(world_object()\object_gfx_id_default_frame)
          
           If IsSprite(world_object()\object_hit_box_gfx_id)
        *e_sprite_back_up=world_object()\object_hit_box_gfx_id
        
      Else
        *e_sprite_back_up=world_object()\object_gfx_id_default_frame
      EndIf
      
          
      Else
        ProcedureReturn #False
      EndIf
      
     

         

 
;--- non player object:
 
If world_object()\object_is_player=0 And  world_object()\object_collision=#True
  ;start_main_if

 
 If world_object()\object_allert_stay=#False
  ProcedureReturn #False  ;no allert we jump out   
 EndIf

  
      ; And world_object()\object_move_direction<>#NO_DIRECTION;here we have the complex data for collsion and movement and playerobject
      
           
 If player_statistics\player_moves_world=#UP 
  world_object()\object_move_direction_y=#DOWN
EndIf

 If player_statistics\player_moves_world=#DOWN 
  world_object()\object_move_direction_y=#UP
 EndIf
 
 ;need this if we want prevent objects mov horizontal if they are falling:
     If world_object()\object_move_direction_x<>#NO_DIRECTION
        If world_object()\object_no_horizontal_move_active=#True
        world_object()\object_move_direction_x=#NO_DIRECTION  
     EndIf
        
   EndIf
   
   ;--------------------------------------------------------------
 

      If   world_object()\object_move_direction_x=#RIGHT
   
    
      If  E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_x,*e_sprite_back_up)=#False
        
        If  ChangeCurrentElement(world_object(), indexeI()\index)=0
                     ProcedureReturn #False  
        EndIf
        world_object()\object_x+world_object()\object_move_x
        
      Else
        
        world_object()\object_did_collision=#True
        E_REMOVE_MOVE()
        E_COLLISION_ENEMY_HANDLING_DEFAULT()
        
     
      EndIf
      
   
   
    EndIf
 
  
    
    If world_object()\object_move_direction_x=#LEFT
      
      If E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_x,*e_sprite_back_up)=#False
        
        If ChangeCurrentElement(world_object(), indexeI()\index)=0
                      ProcedureReturn #False  
        EndIf
        
          world_object()\object_x-world_object()\object_move_x
        Else
        world_object()\object_did_collision=#True
        E_REMOVE_MOVE()
        E_COLLISION_ENEMY_HANDLING_DEFAULT()
        EndIf
        

      EndIf
  
      
      ;something special:
      
  
      
      
      

  If  world_object()\object_move_direction_y=#UP  
    
 
     
      If E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_y,*e_sprite_back_up)=#False
        
        If ChangeCurrentElement(world_object(), indexeI()\index)=0
                      ProcedureReturn #False  
        EndIf
        
        world_object()\object_y-world_object()\object_move_y 
        
      Else
        world_object()\object_did_collision=#True
        E_REMOVE_MOVE()
         E_COLLISION_ENEMY_HANDLING_DEFAULT()
       
            EndIf
            
        
     
          EndIf
  

    If   world_object()\object_move_direction_y=#DOWN

      
      If  E_COLLISION_SYSTEM_SIMPLE(world_object()\object_move_direction_y,*e_sprite_back_up)=#False
                If  ChangeCurrentElement(world_object(),indexeI()\index)=0
              ProcedureReturn #False  
        EndIf
        world_object()\object_y+world_object()\object_move_y
        world_object()\object_is_on_ground=#False
        world_object()\object_is_ready_to_jump=#False
        If world_object()\object_no_horizontal_move_if_falling=#True
          world_object()\object_no_horizontal_move_active=#True
        EndIf
        
  Else
    world_object()\object_is_on_ground=#True
    world_object()\object_is_ready_to_jump=#True
    world_object()\object_no_horizontal_move_active=#False
    world_object()\object_did_collision=#True
    E_REMOVE_MOVE()
    E_COLLISION_ENEMY_HANDLING_DEFAULT()

   EndIf
        
 EndIf

    
E_GRAVITY_CORRECTION()
         ProcedureReturn #False
       EndIf
  
E_OBJECT_NO_COLLISION_HANDLING()
  
  EndProcedure
  
 





  Procedure E_SELECT_EVENT(v_message.i)
    
    Select v_message.i
        
        
      Case #PB_Event_CloseWindow
        e_engine\e_engine_mode=#PAUSE
        
        
      Case #PB_Event_MoveWindow
        
      Case #PB_Event_MinimizeWindow
        SetWindowState(#ENGINE_WINDOW_ID,#PB_Window_Minimize)
        
        
    EndSelect
    
  EndProcedure


Procedure E_CATCH_EVENTS()
  ;here catch the window events, so we get no event errors, buffer overfolw
  ;we try to use this routine for touch interaction also
  If e_engine\e_true_screen=#True
  ProcedureReturn #False  
  EndIf
  
  
  v_message.i=WindowEvent()
  E_SELECT_EVENT(v_message.i)
  
  
EndProcedure

   
   Procedure E_XP_MULTIPLICATOR_CONTROLLER()
     ;timer based system for the multiplicator visuals:
     
     If e_engine_heart_beat\beats_since_start>e_xp_multiplicator\e_xp_multiplicator_actual_time
     e_xp_multiplicator\e_xp_multiplicator=1  ;no multiplicator because we took too long 
     EndIf
 
     
   EndProcedure
   
   
    
     
     Procedure E_INDEX_FOR_INTERACTION_RESET()
       ;here we try some functions and performance optimizing
       
       If ListSize(indexeI())<1
       ProcedureReturn #False  
       EndIf
       
         
                  
          ClearList(indexeI())
  
       
      
     EndProcedure
     
   
  
     Procedure E_INDEX_FOR_COLLISION_RESET()
       
       If ListSize(indexerC())<1
          ProcedureReturn #False  
       EndIf
            
         ClearList(indexerC())  
      
       
     EndProcedure
  
  
  
  Procedure E_BUILD_GLOBAL_INDEX()
    

    
     
    If world_object()\object_use_indexer=#True 
      If AddElement(indexeI())
        indexeI()\index=@world_object() 
       EndIf
      
      
    EndIf
    
    
    If world_object()\object_collision=#True 
      
      If AddElement(indexerC())
        indexerC()\index=@world_object() 
      EndIf
      
    EndIf
    
    
    
  EndProcedure
  
  
  
  Procedure  E_HIDE_AWAY_SYSTEM_OFF()
    
    ;
    
    If e_engine_heart_beat\beats_since_start<world_object()\object_hide_away_time   ;we hide a specific time, so we don not flicker between layers.... 
      ProcedureReturn #False   
    EndIf
    
    
    If IsSound(world_object()\object_random_hide_away_sound_id)
      If SoundStatus(world_object()\object_random_hide_away_sound_id)<>#PB_Sound_Playing
        SoundVolume(world_object()\object_random_hide_away_sound_id,world_object()\object_random_hide_away_sound_volume)
        PlaySound(world_object()\object_random_hide_away_sound_id)  
      EndIf
    EndIf
    
    world_object()\object_layer=world_object()\object_actual_layer_back_up
     world_object()\object_hide_away_status=#False
     world_object()\object_hide_away_pause_time=e_engine_heart_beat\beats_since_start+world_object()\object_hide_away_pause
     
     If world_object()\object_ignore_weapon_on_hide=#True
      world_object()\object_no_weapon_interaction=#False  ;we set the weapon interaction to #false  if boss uses hideaway mode
    EndIf
    
    If world_object()\object_no_collision_on_hide=#True
    world_object()\object_collision=#True 
    EndIf
    e_engine\e_sort_map_by_layer=#True
  EndProcedure
  
  
  
  
  Procedure  E_HIDE_AWAY_SYSTEM_ON()
    
    If world_object()\object_hide_away_pause_time>e_engine_heart_beat\beats_since_start
    ProcedureReturn #False  
    EndIf
    
    
    If IsSound(world_object()\object_random_hide_away_sound_id)
      
      If SoundStatus(world_object()\object_random_hide_away_sound_id)<>#PB_Sound_Playing
        SoundVolume(world_object()\object_random_hide_away_sound_id,world_object()\object_random_hide_away_sound_volume)
      PlaySound(world_object()\object_random_hide_away_sound_id,world_object()\object_random_hide_away_sound_volume)  
      EndIf
    EndIf
    
    world_object()\object_layer=world_object()\object_hide_away_layer
    
    If world_object()\object_ignore_weapon_on_hide=#True
      world_object()\object_no_weapon_interaction=#True  ;we set the weapon interaction to #false  if boss uses hideaway mode
    EndIf
    
    
    If world_object()\object_no_collision_on_hide=#True
    world_object()\object_collision=#False  
    EndIf
    
    world_object()\object_hide_away_status=#True
    world_object()\object_hide_away_time=e_engine_heart_beat\beats_since_start+world_object()\object_hide_away_time_out
   
   e_engine\e_sort_map_by_layer=#True
  EndProcedure
  
  
  
  Procedure E_RANDOM_HIDE_AWAY_CONTROLLER()
    ;here we go for the special effect:
    
    Select world_object()\object_hide_away_status
        
      Case #True
        
        E_HIDE_AWAY_SYSTEM_OFF()
        
      Case #False
        
        E_HIDE_AWAY_SYSTEM_ON()
        
      Default
        
        world_object()\object_hide_away_status=#False
    EndSelect
    
    
  EndProcedure
  
  
  
  
  Procedure E_FADE_BOUNCE()
    
    If world_object()\object_fade_bounce=0
     ProcedureReturn #False 
    EndIf
    
    
    
    If world_object()\object_fade_bounce_add=#True
      
      If (world_object()\object_transparency+world_object()\object_fade_bounce)<world_object()\object_transparency_back_up
        world_object()\object_transparency+world_object()\object_fade_bounce
      Else
        world_object()\object_fade_bounce_add=#False
        world_object()\object_transparency=world_object()\object_transparency_back_up
      EndIf
      
      ProcedureReturn #False
      
    EndIf
    
    
    If (world_object()\object_transparency-world_object()\object_fade_bounce)>0
        world_object()\object_transparency-world_object()\object_fade_bounce
      Else
        world_object()\object_fade_bounce_add=#True
        world_object()\object_transparency=0
      EndIf
    
    
    
  EndProcedure
  
  Procedure E_ROTATE_DIRECTION()
    
    If world_object()\object_use_rotate_direction=#False
      ProcedureReturn #False
    EndIf
    
    Select world_object()\object_move_direction_x
        
        
      Case #LEFT
        RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_rotate_left,#PB_Relative)
        
        
      Case #RIGHT
        
        RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_rotate_right,#PB_Relative)
        
        
        
    EndSelect
    
    
    
    EndProcedure
  
  
  Procedure E_EFFECT_CONTROLLER()
    
    Define _factor.f=1
    

    ;black box of effects
    E_FADE_BOUNCE()
    
    If Random(world_object()\object_random_size_change)=1
      If world_object()\object_random_size_factor<>0
        ;         world_object()\object_x+SpriteWidth(world_object()\object_gfx_id_default_frame)/2
        ;         world_object()\object_y+SpriteHeight(world_object()\object_gfx_id_default_frame)/2
        _factor.f=(Random(world_object()\object_random_size_factor)+1)/100
        ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_w*_factor.f,world_object()\object_h*_factor.f)
        
      EndIf
    EndIf
    
    

    
    
    
    
    
    If IsSprite(world_object()\object_gfx_id_default_frame)=0
      ProcedureReturn #False
    EndIf
    

    If world_object()\object_random_transparency>0
      world_object()\object_transparency=Random(world_object()\object_random_transparency)
    EndIf
    
    If world_object()\object_manual_rotate<>0
      RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_manual_rotate,#PB_Relative)
    EndIf
    
    If world_object()\object_auto_rotate<>0
      RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_auto_rotate,#PB_Relative)
      
    EndIf
    
    ;check for touch transparency:
    
    
    If Random(world_object()\object_use_random_shadow_color)=1
      world_object()\object_shadow_color=RGB(Random(255),Random(255),Random(255))
    EndIf
    
    
    
    
    If world_object()\object_fade_in_on_creation=#True
      If world_object()\object_transparency<255; owrld_object()\object_transparency_target
        world_object()\object_transparency+world_object()\object_fade_in_on_creation_step
   
    EndIf
  EndIf
  
    
    
  EndProcedure
  
  
  
  
  
  
  
  

  Procedure E_SWING_ROTATION()
    ;here we swing the object :
    
    If world_object()\object_use_swing_rotate=#False
      ProcedureReturn #False  
    EndIf
    
    
    
    Select world_object()\object_swing_rotate_step_direction
        
      Case #SWING_ROTATION_ADD_SECTOR
        world_object()\object_swing_rotate_actual_angle+world_object()\object_swing_rotate_step
        RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_swing_rotate_step,#PB_Relative)
        
        
      Case #SWING_ROTATION_SUB_SECTOR
        world_object()\object_swing_rotate_actual_angle+world_object()\object_swing_rotate_step
        RotateSprite(world_object()\object_gfx_id_default_frame,(0-world_object()\object_swing_rotate_step),#PB_Relative)
        
      Default 
        world_object()\object_swing_rotate_step_direction=#SWING_ROTATION_ADD_SECTOR
    EndSelect
    
    
    
    If world_object()\object_swing_rotate_actual_angle<world_object()\object_swing_rotate_angle
      ProcedureReturn #False
    EndIf
    
    world_object()\object_swing_rotate_actual_angle=0
    
    
    
    Select world_object()\object_swing_rotate_step_direction
        
      Case #SWING_ROTATION_SUB_SECTOR
        world_object()\object_swing_rotate_step_direction=#SWING_ROTATION_ADD_SECTOR
        
      Case #SWING_ROTATION_ADD_SECTOR
        
        world_object()\object_swing_rotate_step_direction=#SWING_ROTATION_SUB_SECTOR
        
      Default 
        world_object()\object_swing_rotate_step_direction=#SWING_ROTATION_ADD_SECTOR
        
    EndSelect
    
  EndProcedure 


Procedure E_RESIZE_OBJECT_PER_TICK()
  ;works only for non anim objects
  

   If world_object()\object_resize_per_tick=0
    ProcedureReturn #False  
  EndIf
  
  If IsSprite(world_object()\object_gfx_id_default_frame)=0
  ProcedureReturn #False  
  EndIf
  
  
  If SpriteWidth(world_object()\object_gfx_id_default_frame)<2
    If world_object()\object_remove_after_full_resize=#True
      world_object()\object_remove_from_list=#True  
    EndIf
        ProcedureReturn #False
  EndIf
  
  If SpriteHeight(world_object()\object_gfx_id_default_frame)<2
    If world_object()\object_remove_after_full_resize=#True
      world_object()\object_remove_from_list=#True  
    EndIf
    ProcedureReturn #False
  EndIf
  
 
  
  ;negative values will shrink, positive will zoom, 0 will do nothing

  world_object()\object_h+world_object()\object_resize_per_tick
  world_object()\object_w+world_object()\object_resize_per_tick

  
  ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_w,world_object()\object_h)
  world_object()\object_x-world_object()\object_resize_per_tick
  world_object()\object_y-world_object()\object_resize_per_tick

  
EndProcedure





Procedure E_CONTROL_OUT_OF_AREA_OBJECTS()
  ;here we do special activities for objects out of area if needed
  ;objects / bosses can increase power/health if out of area, so player does not gain any advantage if hiding from the boss

  If world_object()\object_area_no_limit=#True
    world_object()\object_x=world_object()\object_origin_position_x 
    world_object()\object_y=world_object()\object_origin_position_y
    ProcedureReturn #False
  EndIf
  
  
 
  
  
  ;--------------------------------------------------  ultimo situations, one value, one action
    If world_object()\object_remove_if_out_of_area=#True
      world_object()\object_remove_from_list=#True  
      ProcedureReturn #False
    EndIf
    
    If world_object()\object_spawn_at_player_if_out_of_area=#True 
            If world_object()\object_respawn_timer_target>e_engine_heart_beat\beats_since_start ;if there is a timer, we respawn on the timer end
       ProcedureReturn #False  
    
   EndIf
   ;--------------------------------------------------------------------------------------------------------------------   
   
   
   ;--------------------------------- multiple action  on situation, one situation, multiple actions/settings
      
      world_object()\object_x=player_statistics\player_pos_x-e_engine\e_world_offset_x
      world_object()\object_y=player_statistics\player_pos_y-e_engine\e_world_offset_y
      world_object()\object_respawn_timer_target=e_engine_heart_beat\beats_since_start+world_object()\object_respawn_timer
      world_object()\object_stop_if_attraction=#False  ;if we stopped out of are because of attraction, we go on without any
     
    EndIf
    
    
    If world_object()\object_restore_health_if_out_of_area>0
     
      If world_object()\object_hp<world_object()\object_hp_max
        world_object()\object_hp+world_object()\object_restore_health_if_out_of_area 
        
        
        
        If world_object()\object_show_boss_bar=#True 
          boss_bar\boss_bar_actual_health=world_object()\object_hp 
          boss_bar\boss_bar_update=#True 
        EndIf
        
      EndIf
      
       If world_object()\object_hp>world_object()\object_hp_max
        world_object()\object_hp=world_object()\object_hp_max  
        EndIf
      
    EndIf
    

  
EndProcedure


  Procedure E_OBJECT_SPEED_CHANGE()
    ;change speed?
    If world_object()\object_use_speed_change=#False
    ProcedureReturn #False  
    EndIf
       
     world_object()\object_move_x+world_object()\object_speed_change_x
     world_object()\object_move_y+world_object()\object_speed_change_y

    EndProcedure
    



  
  
     Procedure E_TIMEBASED_CONTROL()
     ;indexed objects only!
     ;here we try some engine timer based effects (for each object)
       
       
     
      If  world_object()\object_fade_out_per_tick>0 And world_object()\object_use_fade=#True  
       world_object()\object_transparency-world_object()\object_fade_out_per_tick
        If world_object()\object_transparency<1
         world_object()\object_transparency=0
         If world_object()\object_change_on_fade_out=#True
            world_object()\object_can_change=#True 
            E_STATUS_TRIGGER()
         EndIf
         
       EndIf
       
     EndIf
       
       
       
     If  world_object()\object_fade_out_per_tick>0 And world_object()\object_use_fade=#True  
       If world_object()\object_transparency<1
         world_object()\object_transparency=0
         If world_object()\object_remove_after_fade_out=#True
           world_object()\object_remove_from_list=#True
         EndIf
         
       EndIf
       
     EndIf
     
     
  
     

     
     
     If world_object()\object_life_time>0
       
       If e_engine_heart_beat\beats_since_start>world_object()\object_end_of_life_time
         
     
          
           If world_object()\object_is_weapon=#True
           player_statistics\player_throw_axe=#False  
           EndIf
         
         
         If world_object()\object_remove_after_timer=#True 
           world_object()\object_remove_from_list=#True 
           world_object()\object_is_active=#False
         EndIf
         
         
    
         
       
         
         
         If world_object()\object_inactive_after_timer=#True
           world_object()\object_is_active=#False  
           
         EndIf
         
         
             
         If world_object()\object_change_on_life_time_is_over=#True 
            world_object()\object_can_change=#True
            E_STATUS_TRIGGER()
         EndIf
         
       EndIf
       
       
       
       
     EndIf
     
     
     
     ;we need this here, not in trigger routine
    If Random(world_object()\object_random_hide_away)=1
      E_RANDOM_HIDE_AWAY_CONTROLLER()
    EndIf
    
    If world_object()\object_hide_away_status=#True
      
      If world_object()\object_hp<world_object()\object_hp_max
        world_object()\object_hp+ world_object()\object_restore_health_if_hide_away
        
        If world_object()\objecT_hp>world_object()\object_hp_max
        world_object()\object_hp=world_object()\object_hp_max  
        EndIf
        
        If world_object()\object_show_boss_bar=#True 
          boss_bar\boss_bar_actual_health=world_object()\object_hp 
          boss_bar\boss_bar_update=#True 
        EndIf
      EndIf
      
    EndIf
   
    
    If world_object()\object_restore_health_if_not_allert>0
      If  world_object()\object_allert_stay=#False
        
           If world_object()\object_hp<world_object()\object_hp_max
        world_object()\object_hp+ world_object()\object_restore_health_if_not_allert
        
        If world_object()\object_hp>world_object()\object_hp_max
        world_object()\object_hp=world_object()\object_hp_max  
        EndIf
        
        If world_object()\object_show_boss_bar=#True 
          boss_bar\boss_bar_actual_health=world_object()\object_hp 
          boss_bar\boss_bar_update=#True 
        EndIf
        E_SOUND_PLAY_ON_RESTORE()
      EndIf
        
      EndIf
      
    EndIf
    
    
     
    
    
  
    E_OBJECT_SPEED_CHANGE()
    E_RESIZE_OBJECT_PER_TICK()
    
     
   EndProcedure


  
  Procedure E_REACTIVATION_CHECK()
    ;here we can reactivate objects if the object script use this


 
    If world_object()\object_reactivation_timer_ms<1 ;nothing
      ProcedureReturn #False   
    EndIf
   
    If world_object()\object_is_active=#True
    ProcedureReturn #False  
    EndIf
     
 
    
    If e_engine_heart_beat\beats_since_start<world_object()\object_reactivation_time
      world_object()\object_is_active=#False
      ProcedureReturn #False  
    EndIf
    
    ;here we reset some settings:

  
       world_object()\object_is_active=#True 
       world_object()\object_end_of_life_time=e_engine_heart_beat\beats_since_start+world_object()\object_life_time
       world_object()\object_reactivation_time=e_engine_heart_beat\beats_since_start+world_object()\object_reactivation_timer_ms
       world_object()\object_child_total_counter=0 ;reset the maximum child objects counter

     

    
    
    ;some defaults:
    
    
  EndProcedure
  
  
  
  
  Procedure E_INTERACTIVE_ACTIVATE()
    
    ;we can activate hidden objects in map, after enemy is killed/loot drops on specific position
    
    If world_object()\object_activate_other_on_creation=#False
    ProcedureReturn #False  
    EndIf
    
    
     If ListSize(world_object())<1
      ProcedureReturn #False
    EndIf
    
    
    world_object()\object_activate_other_on_creation=#False; we get one chance!prevent from multiscanning the same object....
     ResetList(world_object())
    
      ForEach world_object()
        
    
            
            If world_object()\object_activated_by_object=#True
              world_object()\object_is_active=#True
              world_object()\object_activated_by_object=#False ;so we can activate next object if more than one object in map to activate
              E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_ACTIVATE)
               ;ProcedureReturn #False  ;we jump out if the first valid object in list is found.
            EndIf
            
     
          
   
        
      Next 
      
 
    
  EndProcedure
  
  Procedure E_OBJECT_DAY_NIGHT_INTERACTION()
    
    ;are there any objects activated by night/day , or deactivated
    
    Select e_world_status.i
        
      Case #WORLD_STATUS_DAY
        
        If world_object()\object_activate_on_day
           world_object()\object_is_active=#True  
         EndIf
         
         
      
      If world_object()\object_deactivate_on_day=#True
        world_object()\object_is_active=#False
        
       If  world_object()\object_remove_on_day=#True
         world_object()\object_remove_from_list=#True 
         
       EndIf
       
        
        E_SET_UP_FOR_REMOVE_AFTER_DAY_NIGHT_AI42()
        
      EndIf
      
        
        
        
      Case #WORLD_STATUS_NIGHT
        
           
        If world_object()\object_activate_on_night
        world_object()\object_is_active=#True  
      EndIf
      
      
      
      If world_object()\object_deactivate_on_night=#True
        world_object()\object_is_active=#False
        If world_object()\object_remove_on_night=#True
           world_object()\object_remove_from_list=#True  
          
        EndIf
        
         E_SET_UP_FOR_REMOVE_AFTER_DAY_NIGHT_AI42()
        
      EndIf
      
        
    EndSelect
    
    
  EndProcedure
  
  
  
  Procedure E_CHECK_COMPASS()
    ;check which startscreen we use:
    
    Define _file_id.i=0
    Define _dummy.s=""
    e_engine\e_map_is_from_save_dir=#False
    
    _file_id.i=ReadFile(#PB_Any,e_engine\e_save_path+"COMPASS")
    
    If IsFile(_file_id.i)
      _dummy.s=Trim(ReadString(_file_id.i))
      
      If Len(_dummy.s)<1
        CloseFile(_file_id.i)
        ProcedureReturn #False  ;no data
      EndIf
      
      CloseFile(_file_id.i)
      
      If DeleteFile(e_engine\e_save_path+_dummy.s)
      Else
        ProcedureReturn #False
      EndIf
      
      
      
    EndIf
  EndProcedure




Procedure E_PLAYER_SETUP_FOR_GAME_OVER()
  ;here all code to setup the player/game for a game over situation
        E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
        player_statistics\player_health_symbol_actual_symbol=1;player_statistics\player_health_symbol_max_symbols    - we have new map handling, if player dies player will start at the last check point if continue is used, but with 1 heart! (we can keep gold value correct) :)))
        E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
        ;E_CHECK_COMPASS()
        e_engine\e_engine_mode=#GAME_OVER  ;uncomment for function!, comment if we use another /other way for gameover like: E_SET_UP_FOR_GAME_OVER_ON_OBJECT()
  
EndProcedure


Procedure E_PLAYER_LAST_VALID_SAVE_POINT()
  ;here we go for the game location if player is not  game over
  Define _dummy.i
  
     _dummy.i=player_statistics\player_health_symbol_actual_symbol
      E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
      player_statistics\player_health_symbol_actual_symbol=_dummy.i
      E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
      e_engine\e_engine_reset_object_position=#True
      e_last_world_before_dead.s=e_engine\e_actuall_world
      e_engine\e_actuall_world="reload_dummy"
     E_GRAB_SRC_SCREEN()
EndProcedure

    
  
  Procedure E_CHECK_IF_PLAYER_DEAD()
    ;here we go for the routines if player is hit/dead
     E_IN_AIR_TIMER_KILL(#RESET)
     player_statistics\player_health_symbol_actual_symbol-1
     E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_PLAYER_DEAD)
      If player_statistics\player_health_symbol_actual_symbol<1
        E_PLAYER_SETUP_FOR_GAME_OVER()
        E_GRAB_SRC_SCREEN()
    Else
      ;load the last "save" point
     E_PLAYER_LAST_VALID_SAVE_POINT()
      ProcedureReturn #False
    EndIf
    

    
  EndProcedure
  
  
  
    Procedure E_SET_PLAYER_DEAD()
   
    ;special for immortal on screen!
     player_statistics\player_health_symbol_actual_symbol-1
     E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_PLAYER_DEAD)
      If player_statistics\player_health_symbol_actual_symbol<1
        E_PLAYER_SETUP_FOR_GAME_OVER()
        E_GRAB_SRC_SCREEN()
    Else
      ;load the last "save" point
     E_PLAYER_LAST_VALID_SAVE_POINT()
      ProcedureReturn #False
    EndIf
    

    
  EndProcedure
  Procedure E_CHECK_PLAYER_GOLD_ACTION()
    ;if GOLD>=100 give player an extra max heard!
    
    ;hard coded for developement phase:
    
    If player_statistics\player_gold<100
    ProcedureReturn #False  
    EndIf
    
    player_statistics\player_gold-100
    
    If player_statistics\player_health_symbol_max_symbols<10  ;set a maximum, but refresh health if 100 gold collected
      player_statistics\player_health_symbol_max_symbols+1
    EndIf
    player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols
    E_SOUND_PLAY_PLAYER_LEVEL_UP()
    
  EndProcedure
  
  
  
  Procedure E_ROTATE_OBJECT()
    
    If world_object()\object_rotate=0
    ProcedureReturn #False  
  EndIf
  
  If IsSprite(world_object()\object_gfx_id_default_frame)=0
  ProcedureReturn #False  
  EndIf
  
     RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_rotate,#PB_Relative)
 
  EndProcedure
  
  

  Procedure E_CHECK_FOR_OBJECT_IN_FRONT_PLAYER_TRANSPARENCY()
    ;is the object drawn with transparency if in front of player?
    
    
  If world_object()\object_use_in_front_transparency=#False
    ProcedureReturn #False  
  EndIf
  
  If e_engine\e_player_layer>world_object()\object_layer
  ProcedureReturn #False   
  EndIf
  

        world_object()\object_transparency=world_object()\object_transparency_back_up
  
  
  If world_object()\object_x<(player_statistics\player_pos_x-e_engine\e_world_offset_x)
    
    If world_object()\object_y<(player_statistics\player_pos_y-e_engine\e_world_offset_y)
      
      If (world_object()\object_x+world_object()\object_w)>(player_statistics\player_pos_x-e_engine\e_world_offset_x)
        
        If (world_object()\object_y+world_object()\object_h)>(player_statistics\player_pos_y-e_engine\e_world_offset_y)
          
          world_object()\object_transparency=world_object()\object_in_front_transparency
        
         EndIf
        
      EndIf
      
      
    EndIf
    
  EndIf
  
 

    
  EndProcedure
  
  
  
  
  
  
  

  
  
  Procedure E_OBJECT_GLOBAL_GFX_ACTION_CONTROLLER()
    
    ;home for all gfx effects per object, put them here, not in terraformer!!! (beter performance, terraformer should only show teh result of maipulation, so we are not framebased...
    
If world_object()\object_allert_stay=#False
  ProcedureReturn #False  
Else
   If world_object()\object_random_rotate_on_activation<>0
      world_object()\object_rotate=Random(world_object()\object_random_rotate_on_activation)
      world_object()\object_random_rotate_on_activation=0
  EndIf
EndIf

    
  If world_object()\object_random_rotate<>0
    world_object()\object_rotate=Random(world_object()\object_random_rotate)  
  EndIf
  
 E_ROTATE_DIRECTION()
 E_ROTATE_OBJECT()
 E_SWING_ROTATION() 
 E_CHECK_FOR_OBJECT_IN_FRONT_PLAYER_TRANSPARENCY()   
 
    
  EndProcedure
  
  
  
  
  Procedure E_CHECK_IF_OBJECT_DEACTIVATE_TRACTOR()
    ;hotfix/workaround for tractor object_collision, object position is left margin, which causes transported object moved out of screen/map area
    
    If (world_object()\object_x+e_engine\e_world_offset_x)>0
      ProcedureReturn #False
    EndIf
    
    If world_object()\object_collision_tractor_object=#False
      ProcedureReturn #False  
    EndIf
    
    If world_object()\object_deactivate_tractor_if_left_border=#False
      ProcedureReturn #False  
    EndIf
    
  ;hotfix:
  ;if no move direction the player object will not transportd if collision
  
  world_object()\object_move_direction_x=#NO_DIRECTION
  world_object()\object_move_direction_y=#NO_DIRECTION
  EndProcedure
  
  
  
  
  Procedure E_SET_PLAYER_GRAVITY_OFF()
    ;use this for some effects like hoovwering, you can switch off gravity use for this situation.
    If world_object()\object_set_player_gravity_off=#False
    ProcedureReturn #False  
    EndIf
    
    player_statistics\player_ignore_gravity=#True
    
    
  EndProcedure
  
  
   Procedure E_SET_UP_FOR_GARBAGE_COLLECTOR_SINGLE_SHOT()
    
  
; sort list to get faster acces to objects to release

      If world_object()\object_remove_from_list<>#True
        ProcedureReturn #False
      EndIf
    
    E_RELEASE_OBJECT_FROM_LIST()
    
  EndProcedure
  
  
  
  Procedure E_SET_UP_FOR_GARBAGE_COLLECTOR()
    
    ;here we check for objects to give to the garbagecollector
    ResetList(world_object())
;        
; sort list to get faster acces to objects to release
  SortStructuredList(world_object(),#PB_Sort_Descending , OffsetOf(world_objects\object_remove_from_list), TypeOf(world_objects\object_remove_from_list))
; 
     ForEach world_object()
      If world_object()\object_remove_from_list=#True
        E_RELEASE_OBJECT_FROM_LIST()
      Else
        ProcedureReturn #False
      EndIf
     Next
    
    
  EndProcedure
  
  

  
  
  Procedure E_EMITTER_CORE_HANDLER()
    
    ;try to tidy up the mess...
    ;some combinations of settings do not work!
    

    ;Define *_me
    
      If E_CHECK_IF_OBJECT_IN_EFFECT_AREA()=#False
      ProcedureReturn #False  
    EndIf
    
    
    If world_object()\object_idle=#True
      
      If world_object()\object_emitter_pause_if_idle=#True
        
        If world_object()\object_emit_on_timer=#True
          world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer  ;idle, so timer is not ready!
        EndIf
        ProcedureReturn #False
      EndIf
    EndIf
    
    
    If world_object()\object_did_spawn=#True 
          If world_object()\object_emitter_pause_if_idle=#True
          If world_object()\object_emit_on_timer=#True
     world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer  ;idle, so timer is not ready!
    EndIf
        ProcedureReturn #False
      EndIf
    EndIf
    
    If  world_object()\object_use_asset_load_pause=#True
      If world_object()\object_asset_load_pause_start>e_engine_heart_beat\beats_since_start
      ProcedureReturn #False  
      EndIf
      world_object()\object_asset_load_pause_start=e_engine_heart_beat\beats_since_start+world_object()\object_asset_load_pause
    EndIf
    
    ;*_me=@world_object()
    
 
    
    
    E_SET_UP_FOR_CHILD_AI42_BY_RANDOM() 
    ;ChangeCurrentElement(world_object(),*_me)
    E_SET_UP_FOR_CHILD_AI42_BY_DAY_NIGHT_RANDOM()
    ;ChangeCurrentElement(world_object(),*_me)
    
    If E_GET_EMIT_OBJECT_USE_TIMER()=#True
    ProcedureReturn #False  
    EndIf
    
    E_GET_EMIT_OBJECT_ON_MOVE()
    E_GET_EMIT_OBJECT_USE_MAX_OBJECT()
    
    

          
    
    EndProcedure
    
    Procedure E_COLLISION_ON_OFF()
      
      ;for special collsion handling (object can move threw collision objects.
      ;without timer object changes status every cycle, so its not stuck in collision
      ;timer makes move threw collision object possible
      
      If world_object()\object_collision_on_off=#False
      ProcedureReturn #False  
    EndIf
    

    
    
    world_object()\object_collision=#True -world_object()\object_collision
      
   
    EndProcedure
    
    
    Procedure E_CHANGE_EMITTER_OBJECT()
      ;here we go:
      If e_engine\e_change_emitter_is_active=#False Or world_object()\object_emitter_id=0
         ProcedureReturn #False  
      EndIf
      
       ;ProcedureReturn #False    ;we do not use this for now...testing without this 
      
      ;here we go for the emitter to change
      
      If world_object()\object_emitter_id<>e_engine\e_change_emitter_id 
      ProcedureReturn #False   
      EndIf
      
      world_object()\object_remove_from_list=#True ;make shure its removed after change!
      E_STREAM_LOAD_SPRITE(#E_ADD_CHANGED_EMITTER_TO_MAP)
    
      
      
    EndProcedure
    
    
    
    Procedure E_CHECK_FOR_EMITTER_OBJECT_CHANGE()
      ;for now its used to find emitter to change 
      ;call this before  E_CHNAGE_EMITTER_OBJECT(), to get valid data
      
      If world_object()\object_change_emitter=#False Or e_engine\e_change_emitter_is_active=#True
        ProcedureReturn #False
      EndIf
      
      If world_object()\object_change_emitter_with_id<=0
        ProcedureReturn #False
      EndIf
      
      ;so now we try to change all emitters in viewport 
      e_engine\e_change_emitter_is_active=#True
      e_engine\e_change_emitter_id=world_object()\object_change_emitter_with_id
      
      
    EndProcedure
    
    
  
  Procedure E_WORLD_OBJECT_SETUP()
    ;overall routine for each run, to actualise the world state..
    ;some reset for default
    e_engine\e_clear_screen=#True  ;can changed to #FALSE, by tile/asset
    e_engine\e_engine_source_element=""

    Define *_me
    
    ;---

    
    If ListSize(world_object())<1
      ProcedureReturn #False
    EndIf
    
    e_engine\e_enemy_maximum=0
    
    
       E_SET_UP_FOR_GARBAGE_COLLECTOR()
       E_INDEX_FOR_COLLISION_RESET()
       E_INDEX_FOR_INTERACTION_RESET()
       
       
       e_engine_build_in_effect\e_sgfx_object_counter=1
    
    ;remove all objects to remove:

    
    ;now check objects change on random situations (in stream/map area)
       ResetList(world_object())
       
    
       
    ForEach world_object()
      
 
     
      world_object()\object_idle=#False
      world_object()\object_effect_pause=#False
      ; E_TIMEBASED_CONTROL()
    
      E_AREA_LOOP_HANDLER()
      E_AREA_TIMED_RESET_X_Y()
      
      If E_CHECK_IF_OBJECT_IN_ALLERT_AREA()=#False
      world_object()\object_idle=#True  
    EndIf
    
    
   
      
   
      
      
    If E_CHECK_IF_OBJECT_IN_GFX_AREA()=#True

         ; E_TALK_AREA_NPC() ;does not work, do not use this object setting!
      
          If world_object()\object_no_clear_screen=#True
            e_engine\e_clear_screen=#False  
          EndIf
          
          If world_object()\object_use_glass_effect=#True
          e_engine_build_in_effect\e_sgfx_object_counter+1  
          EndIf
          E_CHECK_FOR_EMITTER_OBJECT_CHANGE()
         E_CHANGE_EMITTER_OBJECT()
          
          E_AI_CHANGE_OBJECT_STATUS_TO_FADE_OUT()
          E_KEEP_DIRECTION_ON_DEFAULT_VALUE()
          
          If world_object()\object_use_enemy_maximum=#True
            e_engine\e_enemy_maximum=world_object()\object_enemy_maximum  
          EndIf
          
         If world_object()\object_use_player_position=#True And (player_statistics\player_pos_x+player_statistics\player_pos_y)<>0
            world_object()\object_x=player_statistics\player_pos_x-e_engine\e_world_offset_x+world_object()\object_player_position_offset_x
            world_object()\object_y=player_statistics\player_pos_y-e_engine\e_world_offset_y+world_object()\object_player_position_offset_y
         EndIf
          
         E_INTERACTIVE_ACTIVATE()
        
         
           EndIf
        
        E_CHECK_IF_OBJECT_DEACTIVATE_TRACTOR()
      
        
        If E_CHECK_IF_OBJECT_IN_STREAM_AREA()=#True
          ; E_EMITTER_BY_TRIGGER()
          E_COLLISION_ON_OFF()
          E_BUILD_GLOBAL_INDEX()
          E_OBJECT_DAY_NIGHT_INTERACTION()
          E_SET_UP_FOR_CHILD_AI42_BY_DAY_NIGHT_RANDOM()
          ; E_TIMEBASED_CONTROL()
          E_REACTIVATION_CHECK()
          E_EFFECT_RESET()  
          E_EFFECT_CONTROLLER()
          E_PHYSIC_SIMPLE()
         ; E_STREAM_LOAD_SPRITE(#E_STREAM) 
          E_AI_INIT_GET_SPAWN_POSITION()
          E_AI_SPAWN_OBJECT_DESTINATION_ON_INTERNAL()
          E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_RANDOM)
          E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_ROTATE)
;           E_SET_UP_FOR_CHILD_AI42_BY_RANDOM()  
;           E_SET_UP_FOR_CHILD_AI42_BY_DAY_NIGHT_RANDOM()
          E_EMITTER_CORE_HANDLER()  ;12022023
          E_CALL_DEAD()
          E_FOLLOW_PLAYER_ON_TIMER()
          E_CHECK_STATUS_CHANGE_BY_RANDOM()
          E_STREAM_LOAD_SPRITE(#E_STREAM) 
          E_SOUND_PLAY_BOSS_MUSIC()
          E_SET_GLOBAL_EFFECT_ON_OBJECT()
          
         
          
          ;E_SET_UP_FOR_GAME_OVER_ON_OBJECT() ; does not work...
        Else
          E_CONTROL_OUT_OF_AREA_OBJECTS()
       
        EndIf
        
        
        E_OBJECT_GLOBAL_GFX_ACTION_CONTROLLER()
        E_TIMEBASED_CONTROL()
        E_RESTART_GLOBAL_EFFECTS()

   Next

    E_SCROLL_BACK_GROUND_AUTO()         
    E_CHECK_PLAYER_GOLD_ACTION()
    
  EndProcedure
  
  


  
   
  Procedure E_CORE_WORLD_MANGER()
    ;here we go for the on screen action (indexed objects)
    ;it was used to resident in the terraforming include.....
    ;go for some centralized code!
    ;try to get all the info for the objects to finaly show them on screen
    
   
   E_WORLD_OBJECT_SETUP()
;
  EndProcedure
  
  
  
  
  Procedure E_MAP_AUTO_SWITCH_NEXT_MAP()
    ;this routine uses map timer to change map (maplist = switch_map.list)
    ;we store the autoswitch map names in structured list  auto_map()\name
    
  If e_map_timer\_map_time<1  ;nothing
    ProcedureReturn #False  
  EndIf
  
  
  If Len(e_map_timer\_next_map)<1
  ProcedureReturn #False  
  EndIf
  
  If e_map_timer\_map_time_stop>e_engine_heart_beat\beats_since_start
  ProcedureReturn  #False
EndIf

;load last saved player stats:

E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)  ;for now we use the non encrypted data
E_GRAB_SRC_SCREEN()
;no get the map
 e_engine\e_next_world=e_map_timer\_next_map


EndProcedure




  
Procedure E_SYSTEM_TIMER()
  ;the heart of all speed!
  ;if there is a situation to prevent from timing, we can exit here and no timer action is executed (timebase is paused until gam is in "game mode")
  
  If grab_screen\screen_is_active=#True
  ProcedureReturn #False  
  EndIf
  e_engine_heart_beat\beats_since_start+e_engine_heart_beat\heart_rate  ;the core heartrate of the system, most of timed actions are calculated this way, so it is Systemtime independent, it will only increase if engine is active/running
  
  
EndProcedure



  
  

Procedure E_INTERACTION_CORE()
  
  ;here we check if its time to calculate some inputs and gfx or just show the screen?
  
     Define _keyboard.b=#False
     
     E_CATCH_EVENTS()
     

     
       Select e_engine\e_engine_mode
         Case #PAUSE,#NO_XBOX_INPUT_DEVICE
              ProcedureReturn #False
        EndSelect
        
   
    
     If e_engine\e_true_screen=#False  ;hardware full screen is not active!
     If GetWindowState(#ENGINE_WINDOW_ID)=#PB_Window_Minimize  ;if windowed full screen
          ProcedureReturn  #False ;do nothing if window is in tastkbar, minimized
        EndIf
      EndIf
      
      
  If grab_screen\screen_is_active=#True
  ProcedureReturn #False  
  EndIf
       
  
  
     If  e_engine\e_frame_base>ElapsedMilliseconds()  ;timeout < time, for interaction/object control, framerate independed
        ProcedureReturn #False  
    EndIf
      
     
  ;-- here all object calculation stuff :    
     
     e_engine\e_frame_base=ElapsedMilliseconds()+e_engine\e_server_ticks  ;engine-time based action, so we use allways the same action/input/output/effect/timer speed 
     
     E_SYSTEM_TIMER()
     E_SGFX_INTENSITY(e_engine_build_in_effect\e_sgfx_effect_mode)
     
     
   
       If  e_ingame_info_text\timer>e_engine_heart_beat\beats_since_start
         e_ingame_info_text\show=#True
          Else
          e_ingame_info_text\show=#False
       EndIf
       
       

       E_MAP_AUTO_SWITCH_NEXT_MAP()
       ;E_INTERFACE_MULTI_OBJECT_CONTROL()  ;now from display routine moved here! use this for openworld
       E_SCROLL_TEXT_MOVE()
       
       
      
      
       If e_xbox_controller\xbox_joystick_present=#False And  e_engine\e_controller_only_mode=#True   ;here we go for the actual gamepad system, we use keyboard as backup, but not for playing
         e_engine\e_engine_mode=#NO_XBOX_INPUT_DEVICE  
       Else
         E_GAME_INPUT_LOGIC(#XBOX_CONTROLLER)
         
       EndIf

     If e_engine\e_controller_only_mode=#False
       E_GAME_INPUT_LOGIC(#KEYBOARD)
       E_GAME_INPUT_LOGIC(#MOUSE)
     EndIf
     
      ; E_XBOX_CONTROLLER_BUTTON_IS_READY()
       E_CHECK_INPUT_IDLE()
       E_WORLD_SYSTEM_TIME_BASE()  ;engine ingame time
       E_CORE_WORLD_MANGER()
       
              



       If ListSize(indexeI())<1
         ProcedureReturn #False
       EndIf
       
;        e_refresh_gui.b=#False
;        
;        If  player_statistics\player_xp_count_to_zero<>0 Or player_statistics\player_level_defence<=player_statistics\player_level_defence_max
;         e_refresh_gui.b=#True  
;        EndIf

       
       ResetList(indexeI())
       
       e_engine\_actual_list_object=0
       brain\e_object_system_id1=0
       brain\e_object_system_id2=0
       
       
       ForEach indexeI()
         
         If indexeI()\index
                
         If ChangeCurrentElement(world_object(),indexeI()\index) 
           
           
           
          If IsSprite(world_object()\object_gfx_id_default_frame)
         
           
            If world_object()\object_is_player<>0
              
             e_engine\e_player_does_collision=#False  ;for player weapon handling, we reset it to #false (#false = weapon can be used, if changed to #true, no weapon throw possible-->saves from memory/invalid memory error
             player_statistics\player_pos_x=world_object()\object_x+e_engine\e_world_offset_x
             player_statistics\player_pos_y=world_object()\object_y+e_engine\e_world_offset_y
             e_engine\e_player_weapon_x=world_object()\object_x
             e_engine\e_player_weapon_y=world_object()\object_y
             e_engine\e_player_layer=world_object()\object_layer
             player_statistics\player_list_object_id=@world_object()
             e_engine\_actual_list_object=@indexeI()
             player_statistics\player_ignore_gravity=#False          
             E_IN_AIR_TIMER_KILL(#False)
             E_PLAYER_MOVE_COLLISION() ;keyboard inputs for player inner margin
                        ; E_LEVEL_UP_EFFECT()
            
            
             
            If  world_object()\object_weapon_create_paths_ai42>""
              e_player_weapon_path_ai42.s=world_object()\object_weapon_create_paths_ai42
            EndIf
            
         
              
              If ChangeCurrentElement(indexeI(),e_engine\_actual_list_object)
              
              Else
                
                ProcedureReturn #False
              EndIf
              
            Else
              
              ;not player?
              
               If world_object()\object_is_enemy=0 And world_object()\object_is_player=0
                E_KEY_MOVE(#False)   
              EndIf
          
           
           If world_object()\object_is_enemy<>0  ;is used for every/any object which has movement, because the move logic system is behind the "enemy routines", you must use the collision routine to make enemylike action (attack the player)
              
            e_engine\_actual_list_object=@indexeI()
            
            If world_object()\object_does_attack<>0
                 e_world_object\e_world_object_1_attack=world_object()\object_attack
            EndIf
               
                 
      If world_object()\object_allert_overide_by_player_attack=#True
          world_object()\object_allert_stay=#True 
      EndIf
        
       E_KEY_MOVE(#IS_ENEMY) 
       
        
         If ChangeCurrentElement(indexeI(),e_engine\_actual_list_object)
         Else
           
           ProcedureReturn #False
         EndIf
         
         
           EndIf
              
          EndIf
          
     
          
         
            
              
         EndIf  ;is sprite????
     
         
        
        
         
           
          ; E_KEY_MOVE(#GRAVITY)
       
         
         
       EndIf ;is object valid? not removed from list (ready to remove)
       
 
     EndIf  ;valid index
      
     Next
      e_need_gold.i=0
    
     E_AUTO_SCROLL_X()
     E_AUTO_SCROLL_Y()
     
     E_CHECK_DAY_NIGHT_CHANGE()
     E_XP_MULTIPLICATOR_CONTROLLER() 
     
     E_SHADOW_SYSTEM()
    ; E_CHECK_FOR_FIGHT_OFF()
    ;;;;;;;;;;;;; E_SORT_MAP_OBJECTS_BY_LAYER()  ;now in terraformer....
     
     
  EndProcedure
  

; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 2253
; FirstLine = 2236
; Folding = --------------------
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