



Procedure E_NPC_FREE_RESOURCES()
  
  If IsImage(npc_confy\confy_id)
    FreeImage(npc_confy\confy_id)  
  EndIf
  If IsSound(npc_text\npc_speach_output_id)  ;clean it up!
   FreeSound(npc_text\npc_speach_output_id)    
 EndIf
 
EndProcedure




Procedure E_GARBAGE_COLLECTOR()
  
  ;this is the big garbage collector, here we free all resources used by the map, so we can create a new map without memory leaks of the old version
  ;is there any global sound file active (in memory) ?
  
  ;reset selected values/variables of player statistics
  player_statistics\player_quest_size=#False
  player_statistics\player_quest_progress=0
  player_statistics\player_level_done=#False
  player_statistics\player_quest_bar_actual=0
  player_statistics\player_level_defence=0
  player_statistics\player_sound_on_shield_done=#False  
  e_engine\e_boss_object_name_to_show=""
  e_engine\e_world_auto_scroll_x=0
  e_engine\e_world_auto_scroll_y=0
  e_memory_used.i=0
  
  
 If ListSize(world_object())<1
     ProcedureReturn #False
 EndIf
   
  



 
                       ;set music to default, so if boss music was played, we start with the default level music
 
ResetList(world_object())

ForEach world_object()
E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_ALL_SOUND) ;try this? 
E_SOUND_STOP_BOSS_MUSIC()
E_FREE_SOUND()
E_FREE_GFX()
E_FREE_SGFX()




  
Next  
  
  ClearList(world_object())


  If ListSize(indexeI())
    ResetList(indexeI())
  ForEach indexeI()
    indexeI()\index=0
  Next 
  ClearList(indexeI())  
EndIf

If ListSize(indexerC())
  ResetList(indexerC())
  ForEach indexerC()
    indexerC()\index=0
  Next 
  ClearList(indexerC())  
EndIf


EndProcedure













Procedure E_AUTO_MAP_SWITCH_INTEGRITY_CHECK()
  If e_map_timer\_map_time<1 Or Len(e_map_timer\_next_map)<1
  e_map_timer\_map_time=0
  e_map_timer\_map_time_stop=0
  e_map_timer\_next_map=""
EndIf

EndProcedure




Procedure E_RANDOM_SPAWN_POSITION()
  
  
  If world_object()\object_spawn_random_x=0 And world_object()\object_spawn_random_y=0
    ProcedureReturn #False
  EndIf
  

  If world_object()\object_spawn_random_x>0
    world_object()\object_spawn_random_x=Random(world_object()\object_spawn_random_x)
  EndIf
  
   If world_object()\object_spawn_random_y>0
     world_object()\object_spawn_random_y=Random(world_object()\object_spawn_random_y)
  EndIf
  
  ;now check if we do negative value:
  
  If world_object()\object_random_spawn_positive_only=#True
   world_object()\object_x+world_object()\object_spawn_random_x
   world_object()\object_y+world_object()\object_spawn_random_y
  ProcedureReturn #False   ;no negative spawn  
  EndIf
  
  
  If Random(1)=0
      world_object()\object_spawn_random_y=0-world_object()\object_spawn_random_y
  EndIf
  
   If Random(1)=0
    world_object()\object_spawn_random_x=0-world_object()\object_spawn_random_x
  EndIf
  
   world_object()\object_x+world_object()\object_spawn_random_x
   world_object()\object_y+world_object()\object_spawn_random_y
  
EndProcedure



Procedure E_ACTIVATE_ON_COMPANION()
  ;if the player has no companion, objects which  actiated by companion will be set to inactive
  ;if player gets companion objects become/remain active
  
  
  If world_object()\object_activate_on_companion=#False
  ProcedureReturn #False
  EndIf
  
  If player_statistics\player_has_companion<>#True
    world_object()\object_is_active=#False  
    world_object()\object_is_active=#False
  EndIf
  
  If player_statistics\player_in_fight=#True
    world_object()\object_is_active=#False
    ProcedureReturn #False
  EndIf
  
  
  If player_statistics\player_has_companion=#True And player_statistics\player_in_fight=#False
    world_object()\object_is_active=#True 
  EndIf
  
  
  
EndProcedure




Procedure E_SET_BOSS_BAR_VALUES()
  ;here we set the hp bar size and the maximum hp....
  
  
  If world_object()\object_show_boss_bar=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_hp<1
  ProcedureReturn #False  
EndIf




  
    boss_bar\boss_bar_is_active=#True
    boss_bar\boss_bar_actual_health=world_object()\object_hp
    boss_bar\boss_bar_maximum_health=world_object()\object_hp
    boss_bar\boss_bar_size_factor=boss_bar\boss_bar_size_w/boss_bar\boss_bar_maximum_health
    ZoomSprite(boss_bar\boss_bar_back_gfx_id,boss_bar\boss_bar_size_w,boss_bar\boss_bar_size_h)
    ZoomSprite(boss_bar\boss_bar_front_gfx_id,boss_bar\boss_bar_size_w,boss_bar\boss_bar_size_h)
    ZoomSprite(boss_bar\boss_bar_cover_gfx_id,boss_bar\boss_bar_size_w,boss_bar\boss_bar_size_h)
    e_engine\e_boss_object_name_to_show=world_object()\object_ingame_name
    
EndProcedure



Procedure E_DIFFICULTY_SCALER()
  world_object()\object_hp_max=world_object()\object_hp_max*player_statistics\player_difficulty_scale
  world_object()\object_hp=world_object()\object_hp_max
EndProcedure


Procedure E_CHECK_FOR_SAVE_MAP_ON_CREATION()
 
  If world_object()\object_save_map_on_creation=#False
  ProcedureReturn #False  
  EndIf
  
  E_CHECK_FOR_RESPAWN_AREA()
  
EndProcedure



Procedure E_SET_OBJECT_MOVE_TIMER()
  
  Define _help.i=0
  
  If world_object()\object_use_make_move_timer=#False
  ProcedureReturn #False  
EndIf


_help.i=Random(world_object()\object_random_make_move_timer)

If _help.i>0
   world_object()\object_make_move_timer=_help.i
EndIf


world_object()\object_move_time=e_engine_heart_beat\beats_since_start+world_object()\object_make_move_timer
  
  
EndProcedure


Procedure E_SET_GLOBAL_SPAWN()
  ;if object uses global spawn (spawn over visible screen area) we correct the spawn data :
  
  If world_object()\object_use_global_spawn=#False
  ProcedureReturn #False  
EndIf

world_object()\object_x=Random(e_engine\e_engine_internal_screen_w)-e_engine\e_world_offset_x
world_object()\object_y=Random(e_engine\e_engine_internal_screen_h)-e_engine\e_world_offset_y
  
  
EndProcedure


  
  
  Procedure  E_SET_UP_FOR_TARGET_ON_PLAYER()
    ;try it....simple routine to shoot objects at playerdirection
    
    
    
    If world_object()\object_target_on_player=#False
      ProcedureReturn #False  
    EndIf
    
    
    Select e_player_move_direction_y
        
      Case #UP
        
        world_object()\object_use_default_direction="#UP"
        
      Case #DOWN
        
        world_object()\object_use_default_direction="#DOWN"
        
        
        
          
      Default
        
        

        
        If world_object()\object_y<player_statistics\player_pos_y
          world_object()\object_use_default_direction="#DOWN"
           ;ProcedureReturn #False  
        EndIf
        
        
    
        
        
        If world_object()\object_y>player_statistics\player_pos_y
          world_object()\object_use_default_direction="#UP"
          ; ProcedureReturn #False  
        EndIf
        
        
        
        
    EndSelect  
    
    
    Select e_player_move_direction_x
        
      Case #LEFT    
        
        world_object()\object_use_default_direction="#LEFT"
        
      Case #RIGHT
        
        world_object()\object_use_default_direction="#RIGHT"
        
      Default
        
        
        If world_object()\object_x<player_statistics\player_pos_x
          world_object()\object_use_default_direction="#RIGHT"
           ;ProcedureReturn #False  
        EndIf
        

        
        
        
         If world_object()\object_x>player_statistics\player_pos_x
           world_object()\object_use_default_direction="#LEFT"
           ; ProcedureReturn #False  
        EndIf
        

        
    EndSelect

  EndProcedure
  
  
  
   Procedure E_SET_STATIC_MOVE_DIRECTION()
    
    
    ;extended and backcompatible routine for default/random start direction
    
  If world_object()\object_static_move=#False
    ProcedureReturn #False  
  EndIf
  
  
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
  
  
      Procedure E_SET_RANDOM_START_DIRECTION_Y()
    
    
    
    
    ;extended and backcompatible routine for default/random start direction, including all directions
    
  If world_object()\object_use_random_start_direction_y=#False
    ProcedureReturn #False  
  EndIf
  
  
  Select Random(1)
      
    Case 0
      
   
      
      world_object()\object_move_direction_y=#UP
      world_object()\object_last_move_direction_y=#UP
      
    Case 1
      
    
      world_object()\object_move_direction_y=#DOWN
      world_object()\object_last_move_direction_y=#DOWN
  
     
  EndSelect
  
  
  EndProcedure
  
    Procedure E_SET_RANDOM_START_DIRECTION_X()
    
    
    
    
    ;extended and backcompatible routine for default/random start direction, including all directions
    
  If world_object()\object_use_random_start_direction_x=#False
    ProcedureReturn #False  
  EndIf
  
  
  Select Random(1)
   
      
    Case 0

      world_object()\object_move_direction_x=#LEFT
      world_object()\object_last_move_direction_x=#LEFT
    
      
    Case 1
   
      world_object()\object_move_direction_x=#RIGHT
      world_object()\object_last_move_direction_x=#RIGHT
     
    
     
  EndSelect
  
  
  EndProcedure
  
  
  
  Procedure E_SET_RANDOM_START_DIRECTION()
    
    
    
    
    ;extended and backcompatible routine for default/random start direction, including all directions
    
  If world_object()\object_use_random_start_direction=#False
    ProcedureReturn #False  
  EndIf
  
  
  Select Random(3)
      
    Case 0
      
      If world_object()\object_move_y=0
      ProcedureReturn #False  
      EndIf
      
      world_object()\object_move_direction_y=#UP
      world_object()\object_last_move_direction_y=#UP
      
    Case 1
      
      If world_object()\object_move_y=0
      ProcedureReturn #False  
      EndIf
      world_object()\object_move_direction_y=#DOWN
      world_object()\object_last_move_direction_y=#DOWN
   
      
    Case 2
      
      If world_object()\object_move_x=0
      ProcedureReturn #False  
      EndIf
      world_object()\object_move_direction_x=#LEFT
      world_object()\object_last_move_direction_x=#LEFT
    
      
    Case 3
      If world_object()\object_move_x=0
      ProcedureReturn #False  
      EndIf
      world_object()\object_move_direction_x=#RIGHT
      world_object()\object_last_move_direction_x=#RIGHT
     
      
    Default
      
      world_object()\object_move_direction_x=#LEFT
      world_object()\object_last_move_direction_x=#LEFT
      world_object()\object_move_direction_y=#DOWN
      world_object()\object_last_move_direction_y=#DOWN
     
  EndSelect
  
  
  EndProcedure
  
  
  Procedure E_CHECK_FOR_FADE_ON_CREATION()
     
    
    If world_object()\object_fade_in_on_creation=#True 
     world_object()\object_transparency=0
    EndIf
    
  EndProcedure
  
  
  Procedure E_SETUP_ALTERNATIVE_GFX()
    
    ;new with 2021117:
    ;random value could be type long, if value is big chance to get one of the "good things" is smaller, you will get often the default object
    ;if random is 0....6
    ;we use one of the objects definde, if no object is defined ("") we use default
    ;we can now use up to 6 different "loot" alternative objects
    
    If world_object()\object_use_random_alternative_gfx=0
      ProcedureReturn #False   ;no  alternative gfx randomsystem   
    EndIf
    
    
    
    Select  Random(world_object()\object_use_random_alternative_gfx)
        
      Case 0
        
        If  world_object()\object_alternative_random_gfx_ai0>""
          world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai0
        EndIf
        
      Case 1
         If  world_object()\object_alternative_random_gfx_ai1>""
        world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai1
        EndIf
      Case  2
         If  world_object()\object_alternative_random_gfx_ai2>""
        world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai2
        EndIf
      Case 3
        
         If  world_object()\object_alternative_random_gfx_ai3>""
           world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai3
         EndIf
         
        
       Case 4
         If  world_object()\object_alternative_random_gfx_ai4>""
           world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai4
           EndIf
        
         Case 5
            If  world_object()\object_alternative_random_gfx_ai5>""
              world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai5
              EndIf
        
            Case 6
               If  world_object()\object_alternative_random_gfx_ai6>""
                 world_object()\object_alternative_gfx_default_ai42=world_object()\object_alternative_random_gfx_ai6
               EndIf
               
        
       
    EndSelect
    
  EndProcedure
  
  
  
  Procedure E_SETUP_ENEMY_FIGHT_SYMBOL()
    
    
    If world_object()\object_use_fight_effect=#False
    ProcedureReturn #False  
    EndIf
    
    
    If Len(world_object()\object_fight_effect_gfx_path)<1
    ProcedureReturn #False  
    EndIf
    
    If IsSprite(world_object()\object_fight_effect_id)<>0
    ProcedureReturn #False   
    EndIf
  
 
    
    
    ZoomSprite(world_object()\object_fight_effect_id,world_object()\object_w*2,world_object()\object_h*2)
    world_object()\object_fight_effect_h=SpriteHeight(world_object()\object_fight_effect_id)
    world_object()\object_fight_effect_w=SpriteWidth(world_object()\object_fight_effect_id)
      
    
  EndProcedure
  
  
  
  Procedure E_SET_IF_STAMP_GFX()
  
  If world_object()\object_use_stamp=#False
  ProcedureReturn #False  
  EndIf
  

    If IsSprite(world_object()\object_stamp_gfx_id)
   
      world_object()\object_stamp_gfx_height=SpriteHeight(world_object()\object_stamp_gfx_id)/2-world_object()\object_h/2
      world_object()\object_stamp_gfx_width=SpriteWidth(world_object()\object_stamp_gfx_id)/2-world_object()\object_w/2
  
   EndIf
  
EndProcedure


Procedure E_SET_LIFE_PER_PIXEL()
  
  If world_object()\object_use_life_time_per_pixel=#False
   ProcedureReturn #False  
  EndIf
  
  world_object()\object_life_time_pixel_count_x=0
  world_object()\object_life_time_pixel_count_y=0
  
EndProcedure



Procedure E_SET_RANDOM_TRANSPARENCY()
  If world_object()\object_use_random_transparency_on_start=#False
  ProcedureReturn #False  
  EndIf
  
  world_object()\object_transparency=Random(world_object()\object_transparency)
  
EndProcedure

Procedure E_SET_GLOBAL_LIGHT_EFFECTS()
  
  ;put here code for global effects (like thuner/lightning)
  
  If world_object()\object_activate_global_flash=#False
  ProcedureReturn #False  
  EndIf
  
  e_engine_global_effects\global_effect_flash_light_intensity_dynamic=world_object()\object_transparency  
     
  
EndProcedure


Procedure E_RANDOM_LAYER()
  
  If world_object()\object_use_random_layer=#False
  ProcedureReturn #False
EndIf

world_object()\object_layer=Random(world_object()\object_random_layer)

EndProcedure


Procedure E_SET_HIT_BOX()
  ;here we create and set the hitbox gfx (not shown, but used for collision)
  
  If world_object()\object_collision=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_hit_box_w<1 Or world_object()\object_hit_box_h<1
        world_object()\object_hit_box_gfx_id=CreateSprite(#PB_Any,SpriteWidth(world_object()\object_gfx_id_default_frame),SpriteHeight(world_object()\object_gfx_id_default_frame),#PB_Sprite_AlphaBlending)
     EndIf
  
  If world_object()\object_hit_box_w>0 And world_object()\object_hit_box_h>0
    world_object()\object_hit_box_gfx_id=CreateSprite(#PB_Any,world_object()\object_hit_box_w,world_object()\object_hit_box_h,#PB_Sprite_AlphaBlending)
   
  EndIf
  
  
  
EndProcedure

Procedure E_SET_COLLISION_PARAMETER()
  ;if there is somthing to set:
  
  If world_object()\object_collision_get_dynamic_id=#False
  ProcedureReturn #False  
  EndIf
  
  world_object()\object_collision_static_id=ListIndex(world_object())+1
  
EndProcedure



Procedure E_SILUETTE_SET_UP()
  
  If e_engine\e_siluette_active=#False Or world_object()\object_no_siluette=#True
  ProcedureReturn #False  
  EndIf
  
  world_object()\object_color_RGB=e_engine\e_siluette_RGB
  world_object()\object_use_own_color=#True
  world_object()\object_own_color_intensity=e_engine\e_siluette_intensity
  
EndProcedure


Procedure E_SILUETTE_PARSER()
  ;for global color/mask settings, overwrite "own color" settings of objects to tint all objects with specified color and intensity, for an overall effect
  
  e_engine\e_siluette_active=#False
  
  e_engine\e_siluette_file_id=ReadFile(#PB_Any,e_engine\e_siluette_path)
  
  If IsFile(e_engine\e_siluette_file_id)=0
    ProcedureReturn #False ;no siluette file  
  EndIf
  
  While Not Eof(e_engine\e_siluette_file_id)
    
    Select ReadString(e_engine\e_siluette_file_id)
        
      Case "R"
        e_engine\e_siluette_R=Val(ReadString(e_engine\e_siluette_file_id))     
      Case "G"
        e_engine\e_siluette_G=Val(ReadString(e_engine\e_siluette_file_id))
        
      Case "B"
        e_engine\e_siluette_B=Val(ReadString(e_engine\e_siluette_file_id))
        
      Case "SILUETTE_INTENSITY"
        
        e_engine\e_siluette_intensity=Val(ReadString(e_engine\e_siluette_file_id))
        
      Case "SILUETTE"
       
        e_engine\e_siluette_active=Val(ReadString(e_engine\e_siluette_file_id))
        
        
    EndSelect
    
    
  Wend
  
  
  CloseFile(e_engine\e_siluette_file_id)
  
  If e_engine\e_siluette_active>0
    e_engine\e_siluette_active=#True  
    e_engine\e_siluette_RGB=RGB(e_engine\e_siluette_R,e_engine\e_siluette_G,e_engine\e_siluette_B)
  EndIf
  
  
  
  
EndProcedure


Procedure E_SET_SCROLL_BACK_GROUND()
  

  If world_object()\object_is_scroll_back_ground=#False
    ProcedureReturn #False  
  EndIf
  
  If e_engine\e_scroll_object_id>9
  ProcedureReturn #False  ;sorry no more scroll objects... /layers 
  EndIf
  
  
  
  
  
  
  If world_object()\object_full_screen=#True
  e_engine\e_scroll_gfx_default_pos_x[e_engine\e_scroll_object_id]=0
  e_engine\e_scroll_gfx_default_pos_y[e_engine\e_scroll_object_id]=0
Else
  ;we have to setup the scroll object for valid start -coordiantes  (because its a simple gfx scroll loop we
  world_object()\object_x=0
  world_object()\object_y=e_engine\e_engine_internal_screen_h-world_object()\object_h
  e_engine\e_scroll_gfx_default_pos_x[e_engine\e_scroll_object_id]=0
  e_engine\e_scroll_gfx_default_pos_y[e_engine\e_scroll_object_id]=world_object()\object_y
  
EndIf



  e_engine\e_scroll_auto[e_engine\e_scroll_object_id]=world_object()\object_back_ground_auto_scroll 

  e_engine\e_scroll_speed_x[e_engine\e_scroll_object_id]=world_object()\object_scroll_speed_h
  e_engine\e_scroll_speed_y[e_engine\e_scroll_object_id]=0
  
  e_engine\e_scroll_gfx_actual_pos_x1[e_engine\e_scroll_object_id]=e_engine\e_scroll_gfx_default_pos_x[e_engine\e_scroll_object_id]
  e_engine\e_scroll_gfx_actual_pos_y1[e_engine\e_scroll_object_id]=e_engine\e_scroll_gfx_default_pos_y[e_engine\e_scroll_object_id]
  
  e_engine\e_scroll_gfx_actual_pos_x2[e_engine\e_scroll_object_id]=e_engine\e_engine_internal_screen_w
  e_engine\e_scroll_gfx_actual_pos_y2[e_engine\e_scroll_object_id]=e_engine\e_scroll_gfx_default_pos_y[e_engine\e_scroll_object_id]
  
  world_object()\object_scroll_scroll_id=e_engine\e_scroll_object_id
  e_engine\e_scroll_object_id+1
 



EndProcedure

Procedure E_SET_ATTACK_DIRECTION()
  ;simple system: throw/move  player direction/playerposition
  
  If world_object()\object_use_attack_direction=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_x<(player_statistics\player_pos_x-e_engine\e_world_offset_x)
    world_object()\object_move_direction_x=#RIGHT  
  Else
    world_object()\object_move_direction_x=#LEFT
  EndIf
  
  
  
EndProcedure

Procedure E_SWITCH_MAP_ON_OBJECT()
  
  If world_object()\object_switch_map=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_switch_map_path=""
  ProcedureReturn #False  
  EndIf
  
  e_engine\e_next_world=world_object()\object_switch_map_path
  
EndProcedure

Procedure E_SET_OBJECT_INTERNAL_INDEX()
  ;give the object internal index (fingerprint/timestamp) for future manipulation?
  
  world_object()\object_internal_index=e_engine_heart_beat\beats_since_start

  
EndProcedure



Procedure E_FINAL_GFX_SETUP()
  

  
  ;this is the big mother of all final setups after basic data of  object loading, before we give the object to the engine
  E_SWITCH_MAP_ON_OBJECT()
  E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_CREATE)
  E_SETUP_ENEMY_FIGHT_SYMBOL()
  E_SETUP_ALTERNATIVE_GFX()  
  E_RANDOM_SPAWN_POSITION()
  E_CHECK_FOR_FADE_ON_CREATION()
  E_SET_LIFE_PER_PIXEL()
  E_SET_RANDOM_TRANSPARENCY()
  E_SET_GLOBAL_LIGHT_EFFECTS()
  E_RANDOM_LAYER()
  E_SET_HIT_BOX()
  E_SET_IF_STAMP_GFX()
  E_SET_COLLISION_PARAMETER()
  E_SET_OBJECT_MOVE_TIMER()
  E_SET_ATTACK_DIRECTION()
  E_SET_OBJECT_INTERNAL_INDEX()

  If world_object()\object_start_angle<>0
    RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_start_angle,#PB_Absolute)  
  EndIf
  
  If world_object()\object_change_emitter=#True
  e_engine\e_change_emitter_is_active=#False  ;reset the emitter change global engine system
  EndIf
  
  If world_object()\object_is_boss=#True
    If  e_engine\e_engine_boss_object_kill_switch=#True
      world_object()\object_hp=10  
      e_engine\e_engine_boss_object_kill_switch=#False
    EndIf
    
  EndIf
  
  If  world_object()\object_no_fight=#True
      e_engine\e_map_mode_fight=#False  
  EndIf
  
  
   
  
EndProcedure




  
Procedure E_RESIZE_GFX(*gfx)
  ;overall resize routine, for some effects
  
  If world_object()\object_resize_per_percent_x>0 
    ZoomSprite(*gfx,SpriteWidth(*gfx)*world_object()\object_resize_per_percent_x,SpriteHeight(*gfx))
  EndIf
  
  If world_object()\object_resize_per_percent_y>0 
    ZoomSprite(*gfx,SpriteWidth(*gfx),SpriteHeight(*gfx)*world_object()\object_resize_per_percent_y)
    
  EndIf
  
  If world_object()\object_resize_pixel_x>0 
    ZoomSprite(*gfx,world_object()\object_resize_pixel_x,SpriteHeight(*gfx))
    
  EndIf
  
  If world_object()\object_resize_pixel_y>0 
    ZoomSprite(*gfx,SpriteWidth(*gfx),world_object()\object_resize_pixel_y)
  EndIf
  
EndProcedure




Procedure E_CHECK_FOR_MISSING_DATA_SOUND()
  
  ;here we try to fix some missing components (sound)
  
  If IsSound(world_object()\object_sound_id)=0 And Len(world_object()\object_sound_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_path) 
  EndIf
  
  If IsSound(world_object()\object_create_child_sound_id)=0 And Len(world_object()\object_create_child_sound)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_create_child_sound) 
  EndIf
  
  If IsSound(world_object()\object_sound_on_restore_id)=0 And Len(world_object()\object_sound_on_restore_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_restore_path) 
  EndIf
  
  
  
  If IsSound(world_object()\object_sound_on_talk_id)=0 And Len(world_object()\object_sound_on_talk_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_talk_path) 
  EndIf
  
  
  If IsSound(world_object()\object_emit_sound_id)=0 And Len(world_object()\object_sound_on_emit_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_emit_path) 
  EndIf
  
  If IsSound(world_object()\object_sound_on_collision_id)=0 And Len(world_object()\object_sound_on_collision_path)>0
    If world_object()\object_sound_on_collision_path>""
      E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_collision_path)  
    EndIf
  EndIf
  
  If IsSound(world_object()\object_sound_on_random_id)=0 And  Len(world_object()\object_sound_on_random_path)>0
    If world_object()\object_sound_on_random_path>""
      E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_random_path)  
    EndIf
    
  EndIf
  
  
  
  If IsSound(world_object()\object_sound_on_move_id)=0 And Len(world_object()\object_sound_on_move_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_move_path)  
  EndIf
  
  If IsSound(world_object()\object_sound_on_rotate_id)=0 And Len(world_object()\object_sound_on_rotate_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_rotate_path)  
  EndIf
  
  If IsSound(world_object()\object_sound_on_create_id)=0 And Len(world_object()\object_sound_on_create_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_create_path)  
  EndIf
  
  
  If IsSound(world_object()\object_random_hide_away_sound_id)=0  And Len(world_object()\object_random_hide_away_sound)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_random_hide_away_sound)  
  EndIf
  
  If IsSound(world_object()\object_sound_on_activate_id)=0 And Len(world_object()\object_sound_on_activate_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_activate_path)  
  EndIf
  
  
  If IsSound(world_object()\object_sound_on_jump_id)=0 And Len(world_object()\object_sound_on_jump_paths)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_sound_on_jump_paths)  
  EndIf
  
  If IsSound(world_object()\object_boss_music_id)=0 And Len(world_object()\object_boss_music_path)>0
    E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,world_object()\object_boss_music_path)  
  EndIf
  
  
EndProcedure




Procedure E_SETUP_SOUND_EFFECTS()
  
  
  If Len(world_object()\object_sound_on_change_path)>0
    world_object()\object_sound_on_change_id=LoadSound( #PB_Any, v_engine_sound_path.s+world_object()\object_sound_on_change_path,#PB_Sound_Streaming)
  EndIf
  
  
  
  
  If Len(world_object()\object_sound_path)>0
    world_object()\object_sound_id=LoadSound( #PB_Any, v_engine_sound_path.s+world_object()\object_sound_path,#PB_Sound_Streaming)
  EndIf
  
  If Len(world_object()\object_sound_on_emit_path)>0
    world_object()\object_emit_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_emit_path)  
  EndIf
  
  
  If Len(world_object()\object_sound_on_restore_path)>0
    world_object()\object_sound_on_restore_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_restore_path)  
  EndIf
  
  
  If Len(world_object()\object_sound_on_collision_path)>0
    world_object()\object_sound_on_collision_id=LoadSound( #PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_collision_path,#PB_Sound_Streaming)
  EndIf
  
  If Len(world_object()\object_boss_music_path)>0
    world_object()\object_boss_music_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_boss_music_path,#PB_Sound_Streaming)  
  EndIf
  
  If Len(world_object()\object_sound_on_talk_path)>0
    world_object()\object_sound_on_talk_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_talk_path,#PB_Sound_Streaming)
  EndIf
  
  
  If Len(world_object()\object_sound_on_move_path)>0
    world_object()\object_sound_on_move_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_move_path)  ;no sound streaming !!!!
    If IsSound(world_object()\object_sound_on_move_id)
      world_object()\object_sound_on_move_length_ms=SoundLength(world_object()\object_sound_on_move_id,#PB_Sound_Millisecond)  
      world_object()\object_sound_on_move_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_move_length_ms
    EndIf
  EndIf
  
  
  If world_object()\object_play_sound_on_create=#True
  If world_object()\object_stream_sound_on_create=#True
    
   
    world_object()\object_sound_on_create_id=LoadSound(#PB_Any,v_engine_sound_path.s+ world_object()\object_sound_on_create_path,#PB_Sound_Streaming) 
    
  Else
    
    world_object()\object_sound_on_create_id=LoadSound(#PB_Any,v_engine_sound_path.s+ world_object()\object_sound_on_create_path) ;no sound streaming (default)
    
  EndIf
EndIf

  
  
  If Len(world_object()\object_create_child_sound)>0
    world_object()\object_create_child_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_create_child_sound, #PB_Sound_Streaming) ;;no sound streaming!
    
  EndIf
  
  
  If Len(world_object()\object_random_hide_away_sound)>0  ;change this: object_play_sound_on_hide_way =#true
    world_object()\object_random_hide_away_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_random_hide_away_sound, #PB_Sound_Streaming)
  EndIf
  
  If world_object()\object_play_sound_on_activate=#True
    world_object()\object_sound_on_activate_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_activate_path, #PB_Sound_Streaming)
  EndIf
  
  
  If Len(world_object()\object_alternative_create_sound_path)>0
    world_object()\object_alternative_create_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_alternative_create_sound_path, #PB_Sound_Streaming)
  EndIf
  
  
  
  
  If Len(world_object()\object_sound_on_rotate_path)>0
    
    
    world_object()\object_sound_on_rotate_id=LoadSound( #PB_Any, v_engine_sound_path.s+world_object()\object_sound_on_rotate_path) ;no sound streaming!
    If IsSound(world_object()\object_sound_on_rotate_id)
      world_object()\object_sound_on_rotate_length_ms=SoundLength(world_object()\object_sound_on_rotate_id,#PB_Sound_Millisecond)
      world_object()\object_sound_on_rotate_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_rotate_length_ms
    EndIf
    
  EndIf
  
  
  If Len(world_object()\object_sound_on_random_path)>0
    
    
    world_object()\object_sound_on_random_id=LoadSound( #PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_random_path) ;no sound streaming
    
    If IsSound(world_object()\object_sound_on_random_id)
      world_object()\object_sound_on_random_length_ms=SoundLength(world_object()\object_sound_on_random_id,#PB_Sound_Millisecond)
      world_object()\object_sound_on_random_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_random_length_ms
    EndIf
    
  EndIf
  
  
  If Len(world_object()\object_sound_on_treasure_found_path)>0
    world_object()\object_sound_on_treasure_found_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_treasure_found_path, #PB_Sound_Streaming)
  EndIf
  
  
  If Len(world_object()\object_sound_on_jump_paths)>0
    world_object()\object_sound_on_jump_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_jump_paths, #PB_Sound_Streaming)
    
  EndIf
  
  If Len(world_object()\object_sound_on_allert_path)>0
    world_object()\object_sound_on_allert_id=LoadSound(#PB_Any, v_engine_sound_path.s+world_object()\object_sound_on_allert_path)  
  EndIf
  
  If Len(world_object()\object_sound_on_rotate_path)>0
    world_object()\object_sound_on_rotate_id=LoadSound(#PB_Any,v_engine_sound_path.s+world_object()\object_sound_on_rotate_path)
  EndIf
  
  If world_object()\object_sound_on_emit_volume>100
    world_object()\object_sound_on_emit_volume=100
  EndIf
  
  If world_object()\object_sound_on_emit_volume<0
    world_object()\object_sound_on_emit_volume=0
  EndIf
  
  
  If world_object()\object_create_child_sound_volume>100
    world_object()\object_create_child_sound_volume=100
  EndIf
  
  If  world_object()\object_sound_on_allert_volume<0
    world_object()\object_sound_on_allert_volume=0
  EndIf
  
  If  world_object()\object_sound_on_allert_volume>100
    world_object()\object_sound_on_allert_volume=100
  EndIf
  
  
  If world_object()\object_create_child_sound_volume<0
    world_object()\object_create_child_sound_volume=0  
  EndIf
  
  If world_object()\object_sound_on_rotate_volume>100
    world_object()\object_sound_on_rotate_volume=100
  EndIf
  
  
  If world_object()\object_sound_on_rotate_volume<0
    world_object()\object_sound_on_rotate_volume=0
  EndIf
  
  If world_object()\object_sound_on_talk_volume>100
    world_object()\object_sound_on_talk_volume=100 
  EndIf
  
  If world_object()\object_sound_on_talk_volume<0
    world_object()\object_sound_on_talk_volume=0  
  EndIf
  
  If world_object()\object_boss_music_volume>100
    world_object()\object_boss_music_volume=100
  EndIf
  
  
  If world_object()\object_boss_music_volume<0
    world_object()\object_boss_music_volume=0
  EndIf
  
  If world_object()\object_sound_on_change_volume>100
    world_object()\object_sound_on_change_volume=100
  EndIf
  
  If world_object()\object_sound_on_restore_volume>100
    world_object()\object_sound_on_restore_volume=100
  EndIf
  
  If world_object()\object_sound_on_restore_volume<0
    world_object()\object_sound_on_restore_volume=0
  EndIf
  
  
  If world_object()\object_sound_volume>100
    world_object()\object_sound_volume=100
    
  EndIf
  
    If world_object()\object_sound_volume<0
    world_object()\object_sound_volume=0
    
  EndIf
  
  If world_object()\object_sound_on_change_volume<0
    world_object()\object_sound_on_change_volume=0
  EndIf
  
  If world_object()\object_sound_on_create_volume>100
  world_object()\object_sound_on_create_volume=100  
EndIf

If  world_object()\object_sound_on_create_volume<1
world_object()\object_sound_on_create_volume=0  
EndIf

  
  
EndProcedure





Procedure E_SET_GFX_SIZE()
  
  ;if DNA defines the GFX size we go on...:
  ;works only with single frame, no animframes supported for now
  
  If world_object()\object_gfx_set_w_h<>#True
  ProcedureReturn #False  
  EndIf
  
  If IsSprite(world_object()\object_gfx_id_default_frame)=0
    ProcedureReturn #False
  EndIf
  
  ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_gfx_w,world_object()\object_gfx_h)
  
EndProcedure


Procedure E_GFX_LOCALE_SETTING()
  ;try to get localized gfx!
  
  
  
  If  world_object()\object_use_locale=#False
    ProcedureReturn #False  
  EndIf
  
  Define _backup_path.s=world_object()\object_gfx_path
  
  If IsSprite(world_object()\object_gfx_id_default_frame)
    FreeSprite(world_object()\object_gfx_id_default_frame)
  EndIf
  

  ;try to get the locale sensitive gfx
  world_object()\object_gfx_path=e_engine\e_graphic_source+e_engine\e_locale_suffix.s+GetFilePart(world_object()\object_gfx_path)

  world_object()\object_gfx_id_default_frame=LoadSprite(#PB_Any,world_object()\object_gfx_path,#PB_Sprite_AlphaBlending)
 
  If IsSprite(world_object()\object_gfx_id_default_frame)
      ProcedureReturn #False  
  EndIf
  
  
  ;something went wrong, get the default gfx (english)
  world_object()\object_gfx_path=_backup_path.s
  world_object()\object_gfx_id_default_frame=LoadSprite(#PB_Any,world_object()\object_gfx_path,#PB_Sprite_AlphaBlending)
  

  
EndProcedure




Procedure E_INITIAL_SETTINGS_GFX()
  
  ;here we go for the basic initial gfx!
  ;we repair and check values, so we have valid data for the first start of the object

  E_SET_GFX_SIZE()
  
  
 world_object()\object_virtual_y=0
  
  If Len(world_object()\object_danger_gfx_path)>0
    world_object()\object_danger_gfx_id=LoadSprite(#PB_Any,e_engine\e_graphic_source+world_object()\object_danger_gfx_path,#PB_Sprite_AlphaBlending)
    
    If IsSprite(world_object()\object_danger_gfx_id)
      world_object()\object_danger_gfx_is_active=#True  
      world_object()\object_danger_gfx_hight=SpriteHeight(world_object()\object_danger_gfx_id)
      world_object()\object_danger_gfx_width=SpriteWidth(world_object()\object_danger_gfx_id)
    EndIf
    
    
  EndIf

  
  If Len(world_object()\object_shadow_gfx_path)>0
    
    world_object()\object_shadow_gfx_id=LoadSprite(#PB_Any,e_engine\e_graphic_source+world_object()\object_shadow_gfx_path,#PB_Sprite_AlphaBlending)
    If IsSprite(world_object()\object_shadow_gfx_id)
      ZoomSprite(world_object()\object_shadow_gfx_id,world_object()\object_w,world_object()\object_h/2)
      world_object()\object_shadow_h=SpriteHeight(world_object()\object_shadow_gfx_id)
      world_object()\object_shadow_w=SpriteWidth(world_object()\object_shadow_gfx_id)
    EndIf
  EndIf
  
  
  
  
  If IsSprite(world_object()\object_gfx_id_default_frame)
    If world_object()\object_random_size_on_start<>0 
      ZoomSprite(world_object()\object_gfx_id_default_frame,(world_object()\object_w*world_object()\object_random_size_on_start/100)+1,(world_object()\object_h*world_object()\object_random_size_on_start/100)+1)
    EndIf
  EndIf
  
  
  

  
   If IsSprite(world_object()\object_gfx_id_default_frame)
       If world_object()\object_use_random_angle<>0
         world_object()\object_angle_on_creation=Random(world_object()\object_use_random_angle)
         RotateSprite(world_object()\object_gfx_id_default_frame,world_object()\object_angle_on_creation,#PB_Relative)
         
       EndIf
       
     EndIf
     
    If Len(world_object()\object_fight_effect_gfx_path)>0
      world_object()\object_fight_effect_id=LoadSprite(#PB_Any,e_engine\e_graphic_source+world_object()\object_fight_effect_gfx_path,#PB_Sprite_AlphaBlending)
    EndIf
    
    If Len(world_object()\object_stamp_buffer_path)>0
      world_object()\object_stamp_gfx_id=LoadSprite(#PB_Any,world_object()\object_stamp_buffer_path,#PB_Sprite_AlphaBlending)
      
  EndIf
  
     If Len(world_object()\object_health_bar_path)>0 
               
            world_object()\object_health_bar_id=LoadSprite(#PB_Any,e_engine\e_graphic_source+world_object()\object_health_bar_path,#PB_Sprite_AlphaBlending)
           
          EndIf
          
          If Len(world_object()\object_health_bar_back_path)>0
            world_object()\object_health_bar_back_id=LoadSprite(#PB_Any,world_object()\object_health_bar_back_path,#PB_Sprite_AlphaBlending)
          EndIf
          
          
            If Len(GetFilePart(world_object()\object_price_tag_path))>0
            world_object()\object_price_tag_id=LoadSprite(#PB_Any,world_object()\object_price_tag_path,#PB_Sprite_AlphaBlending)
          EndIf
          
          
          If world_object()\object_is_player<>0
            
            If e_engine\e_fov_auto=#True
              
              e_engine\e_fov_x=world_object()\object_move_x
              e_engine\e_fov_y=world_object()\object_move_y
              
            EndIf
            
            
          EndIf
          

          
          
EndProcedure


Procedure E_TIMER_SET_UP()
  ;put here all timers on start:
  
  ;e_engine_heart_beat\beats_since_start =the engine internal timer, not connected to system timers, only progress if engine is in "play mode", so 
  ;timed actions allways will start and end with correct timing
  
  If world_object()\object_use_call_dead_timer=#True
  world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer
  EndIf
  
  If world_object()\object_use_asset_load_pause=#True
  world_object()\object_asset_load_pause_start=e_engine_heart_beat\beats_since_start+world_object()\object_asset_load_pause  
  EndIf
  

  
  If world_object()\object_emit_on_timer=#True
    world_object()\object_emit_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_emit_timer
  EndIf
  
  
  If world_object()\object_follow_player_after_timer=#True
      world_object()\object_follow_player_timer_actual=e_engine_heart_beat\beats_since_start+world_object()\object_follow_player_timer  
  EndIf
  
          
       If world_object()\object_random_life_time>0
   world_object()\object_life_time=Random(world_object()\object_random_life_time) 
   EndIf
      
      If world_object()\object_reset_position_on_timer=#True
      world_object()\object_reset_position_time_counter=e_engine_heart_beat\beats_since_start+world_object()\object_reset_position_time_ms
      EndIf
      
          If world_object()\object_weapon_timeout>0
      e_fight_timeout.i=world_object()\object_weapon_timeout  
      
      If player_statistics\player_axe_speed>1 
        
        If  player_statistics\player_axe_speed_base<1
        player_statistics\player_axe_speed_base=1  ;prevent from negative/zero division
        EndIf
        
        
        If player_statistics\player_axe_speed>player_statistics\player_axe_speed_max
          player_statistics\player_axe_speed=player_statistics\player_axe_speed_max
        Else
          player_statistics\player_axe_speed=player_statistics\player_axe_speed_base
        EndIf
          e_fight_timeout.i/player_statistics\player_axe_speed
      EndIf
      
      e_fight_timeout_player.i=e_engine_heart_beat\beats_since_start+e_fight_timeout.i
      
    EndIf
    
    If world_object()\object_set_day=#True 
     e_engine\e_day_night_overide=#WORLD_STATUS_DAY
     E_OVER_RIDE_DAY_NIGHT()
   EndIf
   
    If world_object()\object_set_night=#True 
     e_engine\e_day_night_overide=#WORLD_STATUS_NIGHT
     E_OVER_RIDE_DAY_NIGHT()
   EndIf
   
   
   world_object()\object_blink_start=e_engine_heart_beat\beats_since_start+world_object()\object_blink_timer
   world_object()\object_time_stamp=e_engine_heart_beat\beats_since_start ;use it or not 
  
EndProcedure



Procedure E_SET_UP_LIGHT_OBJECTS()
  
  
  If world_object()\object_is_light=#False
  ProcedureReturn #False  
  EndIf
  
   If world_object()\object_color_blue>255
     world_object()\object_color_blue=255
   EndIf
   
      If world_object()\object_color_green>255
     world_object()\object_color_green=255
   EndIf
   
 
    If world_object()\object_color_red>255
     world_object()\object_color_red=255
   EndIf
   
   
       If world_object()\object_color_blue<0
     world_object()\object_color_blue=0
   EndIf
   
      If world_object()\object_color_green<0
     world_object()\object_color_green=0
   EndIf
   
 
    If world_object()\object_color_red<0
     world_object()\object_color_red=0
   EndIf
   
   
   If world_object()\object_is_global_light=#True
   
    If world_object()\object_global_light_red>255
      world_object()\object_global_light_red=255  
    EndIf
    
    If world_object()\object_global_light_green>255
    world_object()\object_global_light_green=255  
  EndIf
  
  If  world_object()\object_global_light_blue>255
  world_object()\object_global_light_blue=255  
  EndIf
  
  If  world_object()\object_global_light_intensity>255
    world_object()\object_global_light_intensity=255 
  EndIf
  
  
  
  
    If world_object()\object_global_light_red<0
      world_object()\object_global_light_red=0
    EndIf
    
    If world_object()\object_global_light_green<0
    world_object()\object_global_light_green=0  
  EndIf
  
  If  world_object()\object_global_light_blue<0
  world_object()\object_global_light_blue=0  
  EndIf
  
  If  world_object()\object_global_light_intensity<0
    world_object()\object_global_light_intensity=0 
  EndIf
  
  e_engine_global_effects\global_effect_global_light_color_R=world_object()\object_global_light_red
  e_engine_global_effects\global_effect_global_light_color_G=world_object()\object_global_light_green
  e_engine_global_effects\global_effect_global_light_color_B=world_object()\object_global_light_blue
  
  e_engine_global_effects\global_effect_global_light_intensity=world_object()\object_global_light_intensity
  e_engine_global_effects\global_effect_global_light_layer=world_object()\object_layer  
  e_engine_global_effects\global_effect_global_light_color_RGB=RGB(e_engine_global_effects\global_effect_global_light_color_R,e_engine_global_effects\global_effect_global_light_color_G,e_engine_global_effects\global_effect_global_light_color_B)
 
  EndIf
  
            If world_object()\object_light_intensity>255
               world_object()\object_light_intensity=255  ;secure!  
             EndIf
             
              If world_object()\object_light_intensity<0
               world_object()\object_light_intensity=1  ;secure!  
          EndIf
          
    
  
EndProcedure



Procedure E_RANDOM_START_SPEED()
  
  ;do we start with random speed  (x)? or (y)?
  If world_object()\object_use_random_start_speed_x=#False And world_object()\object_use_random_start_speed_y=#False 
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_random_start_speed_x=#True
  world_object()\object_move_x=Random(world_object()\object_random_start_speed_x)+1
  EndIf
  
    If world_object()\object_use_random_start_speed_y=#True
  world_object()\object_move_y=Random(world_object()\object_random_start_speed_y)+1
  EndIf
  
EndProcedure



Procedure E_SET_UP_COLOR_EFFECTS()
  ;for some color_effects  
  
  
  
If world_object()\object_use_own_color=#False
ProcedureReturn #False  
EndIf


   world_object()\object_color_RGB=RGB(world_object()\object_color_red,world_object()\object_color_green,world_object()\object_color_blue)

  If world_object()\object_use_random_color_RGB=#True
      world_object()\object_color_RGB=RGB(Random(world_object()\object_color_red),Random(world_object()\object_color_green),Random(world_object()\object_color_blue))
  EndIf



  
EndProcedure




Procedure E_SET_TRUE_FALSE()
  ;object settings on object script on start
  ;use this to set/define a global valid state!
  
  
  If world_object()\object_use_speed_change>0
    world_object()\object_use_speed_change=#True  
  EndIf
  If world_object()\object_remove_after_timer>0
    world_object()\object_remove_after_timer=#True  
  EndIf
  If world_object()\object_save_map_on_collision>0
    world_object()\object_save_map_on_collision=#True  
  EndIf
  If  world_object()\object_is_weapon>0
    world_object()\object_is_weapon=#True  
  EndIf
  
  If world_object()\object_create_no_child_if_hide_away>0
    world_object()\object_create_no_child_if_hide_away=#True    
  EndIf
  If world_object()\object_action_on_internal_name>0
    world_object()\object_action_on_internal_name=#True
  EndIf
  If world_object()\object_use_locale>0
    world_object()\object_use_locale=#True
  EndIf
  If world_object()\object_use_random_transparency_on_start>0
    world_object()\object_use_random_transparency_on_start=#True  
  EndIf
  If world_object()\object_activate_on_night>0
    world_object()\object_activate_on_night=#True
  EndIf
  If world_object()\object_change_on_inventory_object>0
    world_object()\object_change_on_inventory_object=#True  
  EndIf
  If world_object()\object_inventory_quest_object_remove_after_use>0
    world_object()\object_inventory_quest_object_remove_after_use=#True  
  EndIf
  
  If world_object()\object_use_random_color_RGB>0
    world_object()\object_use_random_color_RGB=#True  
  EndIf
  If world_object()\object_reset_position_on_fade_out>0
    world_object()\object_reset_position_on_fade_out=#True  
  EndIf
  If world_object()\object_use_random_start_speed_y>0
    world_object()\object_use_random_start_speed_y=#True  
  EndIf
  If world_object()\object_use_random_start_speed_x>0
    world_object()\object_use_random_start_speed_x=#True  
  EndIf
  If world_object()\object_use_indexer>0
    world_object()\object_use_indexer=#True  
  EndIf
  If world_object()\object_fade_out_per_tick>0
    world_object()\object_use_fade=#True  
  EndIf
  If world_object()\object_do_not_save>0
    world_object()\object_do_not_save=#True  
  EndIf
  
  If world_object()\object_touch_collision>0
    world_object()\object_touch_collision=#True  
  EndIf
  If world_object()\object_use_shadow>0
    world_object()\object_use_shadow=#True  
  EndIf
  If world_object()\object_is_trigger>0
    world_object()\object_is_trigger=#True  
  EndIf
  If world_object()\object_area_no_limit>0
    world_object()\object_area_no_limit=#True  
  EndIf
  If world_object()\object_is_active>0
    world_object()\object_is_active=#True  
  EndIf
  If world_object()\object_do_not_show>0
    world_object()\object_do_not_show=#True  
  EndIf
  If world_object()\object_collision>0
    world_object()\object_collision=#True  
  EndIf
  If world_object()\object_is_anim>0
    world_object()\object_is_anim=#True  
  EndIf
  If world_object()\object_play_sound_on_collision>0
    world_object()\object_play_sound_on_collision=#True  
  EndIf
  If world_object()\object_play_sound_on_move>0
    world_object()\object_play_sound_on_move=#True  
  EndIf
  If world_object()\object_change_on_collision>0
    world_object()\object_change_on_collision=#True  
  EndIf
  If world_object()\object_target_on_player>0
    world_object()\object_target_on_player=#True
  EndIf
  If world_object()\object_use_parent_direction>0
    world_object()\object_use_parent_direction=#True  
  EndIf
  If world_object()\object_set_child_direction>0
    world_object()\object_set_child_direction=#True  
  EndIf
  If world_object()\object_play_sound_on_activate>0
    world_object()\object_play_sound_on_activate=#True  
  EndIf
  If world_object()\object_remove_with_boss>0
    world_object()\object_remove_with_boss=#True  
  EndIf
  If world_object()\object_is_boss>0
    world_object()\object_is_boss=#True  
  EndIf
  If world_object()\object_fade_in_on_creation>0
    world_object()\object_fade_in_on_creation=#True  
  EndIf

  If world_object()\object_use_day_night_change>0
    world_object()\object_use_day_night_change=#True  
  EndIf
  If world_object()\object_is_light>0
    world_object()\object_is_light=#True  
  EndIf
  If world_object()\object_remove_after_collison>0
    world_object()\object_remove_after_collison=#True  
  EndIf
  If world_object()\object_remove_after_change>0
    world_object()\object_remove_after_change=#True  
  EndIf
  If world_object()\object_inactive_after_change>0
    world_object()\object_inactive_after_change=#True  
  EndIf
  If world_object()\object_inactive_after_collision>0
    world_object()\object_inactive_after_collision=#True  
  EndIf
  If world_object()\object_no_collision_after_collision>0
    world_object()\object_no_collision_after_collision=#True  
  EndIf
  If world_object()\object_do_not_save_after_change>0
    world_object()\object_do_not_save_after_change=#True  
  EndIf
  If world_object()\object_remove_after_fade_out>0
    world_object()\object_remove_after_fade_out=#True  
  EndIf
  
  If  world_object()\object_change_on_dead>0
    world_object()\object_change_on_dead=#True 
  EndIf
  
  If world_object()\object_change_on_life_time_is_over>0
    world_object()\object_change_on_life_time_is_over=#True  
  EndIf
  
  If world_object()\object_use_map_ground>0
    world_object()\object_use_map_ground=#True  
  EndIf
  
  If world_object()\object_is_map_ground>0
    world_object()\object_is_map_ground=#True  
  EndIf
  
  If world_object()\object_is_loot>0
    world_object()\object_is_loot=#True  
  EndIf
  
  If world_object()\object_set_night>0
    world_object()\object_set_night=#True  
  EndIf
  
  If world_object()\object_set_day>0
    world_object()\object_set_day=#True  
  EndIf
  
  If world_object()\object_activate_on_companion>0
    world_object()\object_activate_on_companion=#True   
  EndIf
  
  If world_object()\object_change_move_after_collision>0
    world_object()\object_change_move_after_collision=#True  
  EndIf
  
  If world_object()\object_change_after_pixel_count>0
    world_object()\object_change_after_pixel_count=#True  
  EndIf
  
  If world_object()\object_play_sound_on_create>0
    world_object()\object_play_sound_on_create=#True  
  EndIf
  
  If world_object()\object_play_sound_on_create_child>0
    world_object()\object_play_sound_on_create_child=#True  
  EndIf
  
  If world_object()\object_use_fight_effect>0
    world_object()\object_use_fight_effect=#True  
  EndIf
  
  If world_object()\object_inactive_after_timer>0
    world_object()\object_inactive_after_timer=#True  
  EndIf
  
  If world_object()\object_allert_on_player>0
    world_object()\object_allert_on_player=#True  
  EndIf
  
  If world_object()\object_sound_play_on_rotate>0
    world_object()\object_sound_play_on_rotate=#True  
  EndIf
  
  If world_object()\object_no_weapon_interaction>0
    world_object()\object_no_weapon_interaction=#True  
  EndIf
  
  If world_object()\object_weapon_remove_after_hit>0
    world_object()\object_weapon_remove_after_hit=#True  
  EndIf
  
  If world_object()\object_play_sound_on_change>0
    world_object()\object_play_sound_on_change=#True  
  EndIf
  
  If world_object()\object_boss_music_mode>0
    world_object()\object_boss_music_mode=#True 
    player_statistics\player_do_not_play_fight_music=#True  ;no player fightmusic if used
  EndIf
  
  If world_object()\object_show_hit_effect>0
    world_object()\object_show_hit_effect=#True  
  EndIf
  
  If world_object()\object_jump_velocity_auto>0
    world_object()\object_jump_velocity_auto=#True  
  EndIf
  
  If world_object()\object_use_random_jump>0
    world_object()\object_use_random_jump=#True  
  EndIf
  
  If world_object()\object_is_boss_guard>0
    world_object()\object_is_boss_guard=#True  
  EndIf
  
  If world_object()\object_play_sound_on_allert>0
    world_object()\object_play_sound_on_allert=#True  
  EndIf
  
  
  
  
  If world_object()\object_is_NESW>0
    world_object()\object_is_NESW=#True  
  EndIf
  
  
  If world_object()\object_use_random_start_direction_x>0
    world_object()\object_use_random_start_direction_x=#True  
  EndIf
  
  If world_object()\object_use_random_start_direction_y>0
    world_object()\object_use_random_start_direction_y=#True  
  EndIf
  
  If world_object()\object_use_random_start_speed_x>0
    world_object()\object_use_random_start_speed_x=#True    
  EndIf
  
  If world_object()\object_is_global_light_on_collision>0
    world_object()\object_is_global_light_on_collision=#True    
  EndIf
  
  If world_object()\object_no_global_light_interaction>0
    world_object()\object_no_global_light_interaction=#True    
  EndIf
  
  If world_object()\object_is_global_light>0
    world_object()\object_is_global_light=#True  
  EndIf
  
  
  If world_object()\object_gfx_set_w_h>0
    world_object()\object_gfx_set_w_h=#True  
  EndIf
  
  If world_object()\object_no_flash_interaction>0
    world_object()\object_no_flash_interaction=#True  
  EndIf
  
  If world_object()\object_change_direction_y_on_max>0
    world_object()\object_change_direction_y_on_max=#True  
  EndIf
  
  If world_object()\object_change_direction_x_on_max>0
    world_object()\object_change_direction_x_on_max=#True  
  EndIf
  
  If world_object()\object_use_own_color>0
    world_object()\object_use_own_color=#True  
  EndIf
  
  If world_object()\object_stream_sound_on_move>0
    world_object()\object_stream_sound_on_move=#True  
  EndIf
  
  
  
  If world_object()\object_stream_sound_on_create>0
    world_object()\object_stream_sound_on_create=#True  
  EndIf
  
  If world_object()\object_activate_global_flash>0
    world_object()\object_activate_global_flash=#True  
  EndIf
  
  If world_object()\object_stop_after_pixel_count>0
    world_object()\object_stop_after_pixel_count=#True  
  EndIf
  
  If world_object()\object_stop_move_after_collision>0
    world_object()\object_stop_move_after_collision=#True
  EndIf
  
  
  If world_object()\object_play_sound_on_random>0
    world_object()\object_play_sound_on_random=#True  
  EndIf
  
  If world_object()\object_anim_loop>0
    world_object()\object_anim_loop=#True  
  EndIf
  
  If world_object()\object_remove_after_pixel_count>0
    world_object()\object_remove_after_pixel_count=#True  
  EndIf
  
  If world_object()\object_reset_position_on_pixel_count>0
    world_object()\object_reset_position_on_pixel_count=#True  
  EndIf
  
  
  If world_object()\object_use_life_time_per_pixel>0
    world_object()\object_use_life_time_per_pixel=#True  
  EndIf
  
  If world_object()\object_no_enemy_action>0
    world_object()\object_no_enemy_action=#True  
  EndIf
  
  If world_object()\object_collision_tractor_object>0
    world_object()\object_collision_tractor_object=#True  
  EndIf
  
  If world_object()\object_deactivate_tractor_if_left_border>0
    world_object()\object_deactivate_tractor_if_left_border=#True
  EndIf
  
  If world_object()\object_set_player_gravity_off>0
    world_object()\object_set_player_gravity_off=#True  
  EndIf
  

  
  If world_object()\object_ignore_one_key>0
    world_object()\object_ignore_one_key=#True  
  EndIf
  
  If  world_object()\object_is_transporter>0
    world_object()\object_is_transporter=#True  
  EndIf
  
  If world_object()\object_NPC_show_text_on_collision>0
    world_object()\object_NPC_show_text_on_collision=#True  
  EndIf
  
  If world_object()\object_turn_on_screen_center>0
    world_object()\object_turn_on_screen_center=#True  
  EndIf
  
  
  If world_object()\object_spawn_offset_parent_center>0
    world_object()\object_spawn_offset_parent_center=#True  
  EndIf
  
  If world_object()\object_use_rotate_direction>0
    world_object()\object_use_rotate_direction=#True  
  EndIf
  
  If world_object()\object_use_swing_rotate>0
    world_object()\object_use_swing_rotate=#True  
  EndIf
  
  If world_object()\object_play_sound_on_rotate>0
    world_object()\object_play_sound_on_rotate=#True  
  EndIf
  
  If world_object()\object_collision_ignore_player>0
    world_object()\object_collision_ignore_player=#True  
  EndIf
  
  If world_object()\object_NPC_switch_map_on_talk>0
    world_object()\object_NPC_switch_map_on_talk=#True  
  EndIf
  

  
  If world_object()\object_play_sound_on_talk>0
    world_object()\object_play_sound_on_talk=#True  
  EndIf
  
  
  If world_object()\object_shake_world>0
    world_object()\object_shake_world=#True  
  EndIf
  
  If world_object()\object_stop_if_guard_on_screen>0
    world_object()\object_stop_if_guard_on_screen=#True  
  EndIf
  
  If world_object()\object_NPC_remove_after_talk>0
    world_object()\object_NPC_remove_after_talk=#True
  EndIf
  
  If world_object()\object_emitter_pause_if_idle>0
    world_object()\object_emitter_pause_if_idle=#True  
  EndIf
  
  If world_object()\object_emit_stop_if_guard_on_screen>0
    world_object()\object_emit_stop_if_guard_on_screen=#True  
  EndIf
  
  If world_object()\object_is_spawn_destination>0
    world_object()\object_is_spawn_destination=#True  
  EndIf
  
  If world_object()\object_use_spawn_destination>0
    world_object()\object_use_spawn_destination=#True  
  EndIf
  
  If world_object()\object_use_random_layer>0
    world_object()\object_use_random_layer=#True  
  EndIf
  
  If world_object()\object_remove_after_full_resize>0
    world_object()\object_remove_after_full_resize=#True  
  EndIf
  
  If world_object()\object_use_creation_counter>0
    world_object()\object_use_creation_counter=#True  
  EndIf
  
  If world_object()\object_use_global_spawn>0
    world_object()\object_use_global_spawn=#True  
  EndIf
  
  If world_object()\object_use_status_controller_parent>0
    world_object()\object_use_status_controller_parent=#True  
  EndIf
  
  If world_object()\object_no_clear_screen>0
    world_object()\object_no_clear_screen=#True  
  EndIf
  
  If world_object()\object_random_spawn_positive_only>0
    world_object()\object_random_spawn_positive_only=#True  
  EndIf
  
  
  If world_object()\object_no_shake_interaction>0
    world_object()\object_no_shake_interaction=#True  
  EndIf
  
  If world_object()\object_use_gravity>0
    world_object()\object_use_gravity=#True  
  EndIf
  
  If world_object()\object_move_flappy_mode>0
    world_object()\object_move_flappy_mode=#True
  EndIf
  
  If world_object()\object_use_air_time_kill>0
    world_object()\object_use_air_time_kill=#True  
  EndIf
  
  If world_object()\object_save_map_on_creation>0
    world_object()\object_save_map_on_creation=#True  
  EndIf
  
  If world_object()\object_use_glass_effect>0
    world_object()\object_use_glass_effect=#True  
  EndIf
  
  If world_object()\object_collision_get_dynamic_id>0
    world_object()\object_collision_get_dynamic_id=#True  
  EndIf
  
  If world_object()\object_use_global_effect>0
    world_object()\object_use_global_effect=#True  
  EndIf
  
  If world_object()\object_stop_move_right_border>0
    world_object()\object_stop_move_right_border=#True  
  EndIf
  
  If world_object()\object_turn_on_right_border>0
    world_object()\object_turn_on_right_border=#True  
  EndIf
  
  If world_object()\object_turn_on_left_screen>0
    world_object()\object_turn_on_left_screen=#True  
  EndIf
  
  If world_object()\object_emit_on_timer>0
    world_object()\object_emit_on_timer=#True    
  EndIf
  
  If world_object()\object_emit_on_jump>0
    world_object()\object_emit_on_jump=#True  
  EndIf
  
  If world_object()\object_use_horizontal_velocity>0
    world_object()\object_use_horizontal_velocity=#True  
  EndIf
  
  If world_object()\object_use_vertical_velocity>0
    world_object()\object_use_vertical_velocity=#True  
  EndIf
  
  If world_object()\object_use_virtual_buffer>0
    world_object()\object_use_virtual_buffer=#True    
  EndIf
  
  If world_object()\object_use_make_move_timer>0
    world_object()\object_use_make_move_timer=#True  
  EndIf
  
  If world_object()\object_use_blink_timer>0
    world_object()\object_use_blink_timer=#True
  EndIf
  
  If world_object()\object_no_horizontal_move_if_falling>0
    world_object()\object_no_horizontal_move_if_falling=#True  
  EndIf
  
  If world_object()\object_no_siluette>0
    world_object()\object_no_siluette=#True  
  EndIf
  
  If world_object()\object_full_screen>0
    world_object()\object_full_screen=#True  
  EndIf
  
  
  If world_object()\object_use_in_front_transparency>0
    world_object()\object_use_in_front_transparency=#True  
  EndIf
  

  If  world_object()\object_change_on_fade_out>0
    world_object()\object_change_on_fade_out=#True  
  EndIf
  
  If world_object()\object_emit_stop_on_collision>0
    world_object()\object_emit_stop_on_collision=#True  
  EndIf
  
  If  world_object()\object_play_sound_on_emit>0
    world_object()\object_play_sound_on_emit=#True  
  EndIf
  
  If world_object()\object_play_sound_on_change>0
    world_object()\object_play_sound_on_change=#True  
  EndIf
  
  If world_object()\object_use_spawn_border_offset>0
    world_object()\object_use_spawn_border_offset=#True  
  EndIf
  
  If world_object()\object_show_hp_bar>0
    world_object()\object_show_hp_bar=#True  
  EndIf
  
  If world_object()\object_debug_if_remove>0
    world_object()\object_debug_if_remove=#True  
  EndIf
  
  If world_object()\object_no_child_if_move_down>0
    world_object()\object_no_child_if_move_down=#True  
  EndIf
  
  If world_object()\object_no_gravity_after_collision>0
    world_object()\object_no_gravity_after_collision=#True  
  EndIf
  
  
  
  If world_object()\object_use_teleport_effect>0
  world_object()\object_use_teleport_effect=#True  
  EndIf
  
  If world_object()\object_use_teleport_on_max_x>0
  world_object()\object_use_teleport_on_max_x=#True  
EndIf

If world_object()\object_save_map_on_remove>0
world_object()\object_save_map_on_remove=#True  
EndIf

If world_object()\object_set_fade_out_on_ai>0
world_object()\object_set_fade_out_on_ai=#True  
EndIf

If world_object()\object_activate_fade_out_on_ai>0
  world_object()\object_activate_fade_out_on_ai=#True  
EndIf

If world_object()\object_music_global_start>0
world_object()\object_music_global_start=#True  
EndIf

If world_object()\object_change_direction_on_random>0
world_object()\object_change_direction_on_random=#True  
EndIf

If world_object()\object_stop_all_music>0
world_object()\object_stop_all_music=#True 
EndIf

If world_object()\object_shadow_use_perspective=>0
world_object()\object_shadow_use_perspective=#True  
EndIf



If world_object()\object_ignore_weapon_on_hide>0
world_object()\object_ignore_weapon_on_hide=#True  
EndIf

If world_object()\object_no_collision_on_hide>0
world_object()\object_no_collision_on_hide=#True  
EndIf

If world_object()\object_remove_if_out_of_area>0
world_object()\object_remove_if_out_of_area=#True  
EndIf

If world_object()\object_slippery_mode>0
world_object()\object_slippery_mode=#True  
EndIf

If world_object()\object_is_arena_object>0
world_object()\object_is_arena_object=#True  
EndIf

If world_object()\object_play_sound_on_treasure>0
  world_object()\object_play_sound_on_treasure=#True
EndIf

If world_object()\object_allert_on_treasure>0
world_object()\object_allert_on_treasure=#True  
EndIf

If world_object()\object_spawn_at_player_if_out_of_area>0
world_object()\object_spawn_at_player_if_out_of_area=#True  
EndIf

If world_object()\object_is_attraction>0
world_object()\object_is_attraction=#True  
EndIf

If world_object()\object_attraction_pick_up>0
world_object()\object_attraction_pick_up=#True  
EndIf

If world_object()\object_activate_on_day>0
  world_object()\object_activate_on_day=#True
EndIf


If world_object()\object_deactivate_on_night>0
  world_object()\object_deactivate_on_night=#True
EndIf

If world_object()\object_deactivate_on_day>0
  world_object()\object_deactivate_on_day=#True
EndIf

If world_object()\object_effect_on_player_collision>0
  world_object()\object_effect_on_player_collision=#True  
EndIf


If world_object()\object_remove_after_effect_on_player>0
world_object()\object_remove_after_effect_on_player=#True  
EndIf

If world_object()\object_anim_stop_after_last_frame>0
world_object()\object_anim_stop_after_last_frame=#True  
EndIf

If world_object()\object_use_start_direction>0
world_object()\object_use_start_direction=#True  
EndIf

If world_object()\object_follow_player_after_timer>0
world_object()\object_follow_player_after_timer=#True  
EndIf

If world_object()\object_anim_no_auto_align>0
world_object()\object_anim_no_auto_align=#True  
EndIf

If world_object()\object_keep_move_direction>0
world_object()\object_keep_move_direction=#True  
EndIf

If world_object()\object_stop_scroll_after_allert>0
world_object()\object_stop_scroll_after_allert=#True  
EndIf

If world_object()\object_play_sound_on_restore>0
world_object()\object_play_sound_on_restore=#True  
EndIf

If world_object()\object_remove_with_guard>0
world_object()\object_remove_with_guard=#True  
EndIf

If world_object()\object_emitter_pause_if_spawn>0
world_object()\object_emitter_pause_if_spawn=#True  
EndIf

If  world_object()\object_use_effect_area>0
world_object()\object_use_effect_area=#True  
EndIf

If world_object()\object_use_auto_reposition>0
world_object()\object_use_auto_reposition=#True  
EndIf

If world_object()\object_use_virtual_buffer>0
world_object()\object_use_virtual_buffer=#True  
EndIf

If world_object()\object_use_call_dead_timer>0
world_object()\object_use_call_dead_timer=#True  
EndIf

If world_object()\object_is_reaper>0
world_object()\object_is_reaper=#True  
EndIf

If world_object()\object_use_physic_collision>0
world_object()\object_use_physic_collision=#True  
EndIf

If world_object()\object_use_physic_loop>0
world_object()\object_use_physic_loop=#True  
EndIf

If world_object()\object_use_physic_no_collision>0
world_object()\object_use_physic_no_collision=#True  
EndIf

If world_object()\object_use_asset_load_pause>0
world_object()\object_use_asset_load_pause=#True  
EndIf

If world_object()\object_collision_on_off>0
world_object()\object_collision_on_off=#True  
EndIf

If world_object()\object_is_scroll_back_ground>0
world_object()\object_is_scroll_back_ground=#True  
EndIf

If world_object()\object_back_ground_auto_scroll>0
  world_object()\object_back_ground_auto_scroll=#True  
EndIf

If world_object()\object_check_if_player_on_top>0
world_object()\object_check_if_player_on_top=#True  
EndIf

If world_object()\object_no_interaction_on_enemy>0
world_object()\object_no_interaction_on_enemy=#True  
EndIf

If world_object()\object_use_enemy_maximum>0
world_object()\object_use_enemy_maximum=#True  
EndIf

If world_object()\object_activate_other_on_creation>0
world_object()\object_activate_other_on_creation=#True  
EndIf

If world_object()\object_activated_by_object>0
  world_object()\object_activated_by_object=#True
EndIf

If world_object()\object_use_stamp>0
world_object()\object_use_stamp=#True  
EndIf

If  world_object()\object_use_player_position>0
world_object()\object_use_player_position=#True  
EndIf

If world_object()\object_turn_right_screen_full_spawn>0
world_object()\object_turn_right_screen_full_spawn=#True  
EndIf

If  world_object()\object_NPC_use_talk_area>0
world_object()\object_NPC_use_talk_area=#True  
EndIf

If world_object()\object_use_attack_direction>0
world_object()\object_use_attack_direction=#True  
EndIf

If world_object()\object_no_fight>0
world_object()\object_no_fight=#True  
EndIf

If world_object()\object_use_isometric>0
world_object()\object_use_isometric=#True  
EndIf



EndProcedure









Procedure E_SET_JUMP_PARAMETER()
  
   If world_object()\object_jump_velocity_auto=#True
   world_object()\object_jump_velocity=world_object()\object_move_y_max/world_object()\object_jump_size
   EndIf
  
 EndProcedure
 
 

Procedure E_SET_SPECIAL_GLOBAL_SITUATIONS_ON_OBJECT()
  
  ;here we set some global actions/situations on object
  If world_object()\object_is_boss_guard=#True
  e_engine\e_count_active_boos_guards+1 
EndIf

If world_object()\object_is_enemy<>0
 If e_engine\e_enemy_maximum>0
  e_engine\e_enemy_count+1  
EndIf
EndIf

  



  
EndProcedure


Procedure E_GET_DEFAULT_START_DIRECTION()
  
If world_object()\object_use_start_direction=#False
  ProcedureReturn #False  
EndIf

world_object()\object_move_direction_x=#NO_DIRECTION
world_object()\object_move_direction_y=#NO_DIRECTION
world_object()\object_last_move_direction_x=#NO_DIRECTION
world_object()\object_last_move_direction_y=#NO_DIRECTION

Select world_object()\object_default_start_direction
    
  Case "#LEFT"
    world_object()\object_move_direction_x=#LEFT
    world_object()\object_last_move_direction_x=#LEFT
    
  Case "#RIGHT"
    world_object()\object_move_direction_x=#RIGHT
    world_object()\object_last_move_direction_x=#RIGHT
    
  Case "#UP"
     world_object()\object_move_direction_y=#UP
     world_object()\object_last_move_direction_y=#UP
    
  Case "#DOWN"
     world_object()\object_move_direction_y=#DOWN
    world_object()\object_last_move_direction_y=#DOWN
    
    If world_object()\object_is_player<>0
      player_statistics\player_move_direction_x= world_object()\object_move_direction_x
      player_statistics\player_move_direction_y=world_object()\object_move_direction_y
    EndIf
    
    
    
EndSelect


  
  
EndProcedure


Procedure E_GET_STATIC_MOVE_DIRECTION()
  
If world_object()\object_static_move=#False
  ProcedureReturn #False  
EndIf


world_object()\object_move_direction_x=#NO_DIRECTION
world_object()\object_move_direction_y=#NO_DIRECTION
world_object()\object_last_move_direction_x=#NO_DIRECTION
world_object()\object_last_move_direction_y=#NO_DIRECTION

Select world_object()\object_use_default_direction
    
  Case "#LEFT"
    world_object()\object_move_direction_x=#LEFT
    world_object()\object_last_move_direction_x=#LEFT
    
  Case "#RIGHT"
    world_object()\object_move_direction_x=#RIGHT
    world_object()\object_last_move_direction_x=#RIGHT
    
  Case "#UP"
     world_object()\object_move_direction_y=#UP
    world_object()\object_last_move_direction_y=#UP
    
  Case "#DOWN"
     world_object()\object_move_direction_y=#DOWN
    world_object()\object_last_move_direction_y=#DOWN
    
    
    
    
EndSelect


  
  
EndProcedure
  

Procedure E_INIT_OBJECT_STATE_ON_START()
  
   E_SET_TRUE_FALSE() ;!first!!!!
   E_GFX_LOCALE_SETTING()
   E_INITIAL_SETTINGS_GFX()
   E_SETUP_SOUND_EFFECTS()
   E_SET_SPECIAL_GLOBAL_SITUATIONS_ON_OBJECT()
   E_CHECK_FOR_MISSING_DATA_SOUND()
   E_GET_DEFAULT_START_DIRECTION()
   E_GET_STATIC_MOVE_DIRECTION()
   E_TIMER_SET_UP()
   
  
  e_engine\e_gfx=world_object()\object_gfx_id_default_frame  ;*gfx, because of flexibility for more gfx effcts (also animframes in the future)
  E_RESIZE_GFX(e_engine\e_gfx)
  
  
  If world_object()\object_is_weapon=#True
  player_statistics\player_level_fight=world_object()\object_attack  
  EndIf
  

   
   world_object()\object_anim_loop_direction=1
    
   If world_object()\object_force_own_layer<>0
     
      world_object()\object_layer=world_object()\object_force_own_layer
      world_object()\object_auto_layer=world_object()\object_force_own_layer
      world_object()\object_actual_layer_back_up=world_object()\object_force_own_layer
    Else
      world_object()\object_actual_layer_back_up=world_object()\object_layer
    EndIf
  
    ;we have a valid object (gfx is loaded)
    ;now we do some initial settings:
  
       ;---- is it fullscreen?
     If world_object()\object_full_screen=#True
     world_object()\object_w=e_engine\e_engine_internal_screen_w
     world_object()\object_h=e_engine\e_engine_internal_screen_h
      If IsSprite(world_object()\object_gfx_id_default_frame)
        ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_w, world_object()\object_h)
      EndIf
    EndIf
    
    
    If world_object()\object_stamp_transparency<0
      world_object()\object_stamp_transparency=0
    EndIf
    
     If world_object()\object_stamp_transparency>255
      world_object()\object_stamp_transparency=255
    EndIf
      
      If world_object()\object_use_random_transparency_on_start=#True
        world_object()\object_transparency=world_object()\object_random_transparency_on_start
      EndIf
      
  
    world_object()\object_transparency_back_up=world_object()\object_transparency  ;can be usefull
    world_object()\object_allert_stay=#True  ;default! enemies and objects ready for/to fight
    world_object()\object_first_start=#True
    world_object()\object_end_of_life_time=e_engine_heart_beat\beats_since_start+world_object()\object_life_time
    
    world_object()\object_do_change=#False
    world_object()\object_ready_to_change=#False  ;switch for AI42 alternative routine (experimental)
    
    world_object()\object_light_color_RGB=RGB(world_object()\object_light_color_r,world_object()\object_light_color_g,world_object()\object_light_color_b)
    world_object()\object_is_in_fight=#False
    world_object()\object_do_create_child=#False
    
    
    world_object()\object_respawn_timer_target=e_engine_heart_beat\beats_since_start+world_object()\object_respawn_timer
  
   If world_object()\object_hp_factor>1  ;only if value is >1 if <2 we use the default hp stored in the object file
     world_object()\object_hp=player_statistics\player_level_fight*world_object()\object_hp_factor  
     world_object()\object_hp_max= world_object()\object_hp
   EndIf
   
   world_object()\object_health_bar_actual_hp=world_object()\object_hp
   
  If world_object()\object_is_arena_object=#True
  player_statistics\player_arena_enemies+1  
  EndIf


  If world_object()\object_use_player_direction_x=#True
    
    world_object()\object_move_direction_x=player_statistics\player_move_direction_x  
    world_object()\object_last_move_direction_x=player_statistics\player_move_direction_x 

  
 EndIf
  
  
 If world_object()\object_use_player_direction_y=#True

    world_object()\object_move_direction_y=player_statistics\player_move_direction_y  
    world_object()\object_last_move_direction_y=player_statistics\player_move_direction_y 

EndIf




If world_object()\object_activate_global_flash=#True
  e_engine_global_effects\global_effect_flash_light_status=#FLASH_LIGHT_ON
  e_engine_global_effects\global_effect_flash_light_layer=world_object()\object_layer
EndIf

    
;     If e_use_difficulty_scaler.b=#True
;       E_DIFFICULTY_SCALER()  
;     EndIf
    
 

  
    If world_object()\object_is_map_ground=#True
    e_engine\e_engine_map_ground=world_object()\object_layer 
  EndIf
  
  If world_object()\object_use_map_ground
    world_object()\object_layer=e_engine\e_engine_map_ground
  EndIf
  
    
   
    
    
    If world_object()\object_change_on_inventory_object=#True
      world_object()\object_can_change=#False ;no default change, only on right inventory object  
    EndIf
    
  
  
    

    
    If world_object()\object_NPC_show_text_on_collision=#True; Or world_object()\object_NPC_use_talk_area=#True
      world_object()\object_NPC_text_path=e_engine\e_npc_text_path+e_engine\e_actuall_world+"."+world_object()\object_NPC_internal_name+"."+world_object()\object_NPC_text_path
    EndIf
    
    
   
    world_object()\object_shadow_color=RGB(e_engine\e_shadow_color_r,e_engine\e_shadow_color_g,e_engine\e_shadow_color_b) 
    
    If world_object()\object_show_boss_bar>0
      E_SET_BOSS_BAR_VALUES()
    EndIf
    
    world_object()\object_collision_back_up=world_object()\object_collision
    

    
   
    world_object()\object_blink_object_show=#True       ;default we show all objects....
    
    If e_engine\e_game_status=#CONTINUE
      If world_object()\object_internal_name="#CONTINUEGAME"
        world_object()\object_is_active=#True
      EndIf
      
    EndIf
    
    world_object()\object_swing_rotate_start_angle=0  ;only positive values supported 
    world_object()\object_swing_rotate_step_direction=#SWING_ROTATION_ADD_SECTOR
    world_object()\object_swing_rotate_actual_angle=0
    
    
    
    ;---- some local language GFX settings:
    
   
     ;-----------------------------------------------
     
     
     If world_object()\object_activate_map_scroll=#True 
       e_engine\e_engine_no_scroll_margin=0
        e_engine\e_engine_scroll_map=#True
      EndIf

       If world_object()\object_deactivate_map_scroll=#True 
      e_engine\e_engine_no_scroll_margin=WindowWidth(#ENGINE_WINDOW_ID)
      e_engine\e_engine_scroll_map=#False
     EndIf
   
   world_object()\object_layer=world_object()\object_layer_add+e_engine\e_engine_object_last_layer
   
   
   If world_object()\object_use_spawn_offset=#True
     world_object()\object_x+world_object()\object_spawn_offset_x
     world_object()\object_y+world_object()\object_spawn_offset_y
    EndIf
   
   world_object()\object_backup_size_h=world_object()\object_h
   world_object()\object_backup_size_w=world_object()\object_w
   
   If world_object()\object_is_player<>0
    player_statistics\player_object_height=world_object()\object_h 
    player_statistics\player_object_widht=world_object()\object_w
  EndIf
  
   
   
    If world_object()\object_xp_on_remove<0
            world_object()\object_xp_on_remove=0  
          EndIf
          
          
          If world_object()\object_restore_health_if_out_of_area<0
            world_object()\object_restore_health_if_out_of_area=0
          EndIf
          
          If  world_object()\object_restore_health_if_hide_away<0
            world_object()\object_restore_health_if_hide_away=0  ;prevent from "cheating"  
          EndIf
          
  
          If world_object()\object_glass_effect_intensity>255
            world_object()\object_glass_effect_intensity=255
          EndIf
          
          If world_object()\object_global_light_intensity<0
          world_object()\object_glass_effect_intensity=0  
          EndIf
          
          
          
           If world_object()\object_restore_health_if_not_allert<0
            world_object()\object_restore_health_if_not_allert=0  ;no cheating....  
          EndIf
          
 If day_night_cycle\light_intensity_max=day_night_cycle\light_intensity_min
 e_map_use_daytimer=#False   ;no day/night cycle -> fallback if map does not have any infos about day night cycle (respawned maps will save infos for the day night cycle and overwrite the default settings of the values)  
 EndIf
 
  If world_object()\object_reset_position_on_pixel_count=#True
 world_object()\object_use_position_back_up=#True    ;logic: no need to set this manually in the DNA
 EndIf
 
 world_object()\object_move_x_max=world_object()\object_move_x  ;some backup for move speeds
 world_object()\object_move_y_max=world_object()\object_move_y

 If world_object()\object_move_x=0 And world_object()\object_move_y=0
   world_object()\object_move_direction_x=#NO_DIRECTION  
   world_object()\object_move_direction_y=#NO_DIRECTION  
 EndIf
 
 If world_object()\object_spawn_offset_parent_center=#True
   world_object()\object_x+world_object()\object_parent_width/2
   world_object()\objecT_y+world_object()\object_parent_height/2
 EndIf
 
 If world_object()\object_is_player<>0
      E_IN_AIR_TIMER_KILL(#RESET)
 EndIf
 
 
 If world_object()\object_use_parent_direction=#True
   world_object()\object_move_direction_x=e_engine\e_object_last_direction_x 
   world_object()\object_move_direction_y=e_engine\e_object_last_direction_y
      world_object()\object_last_move_direction_x=e_engine\e_object_last_direction_x 
    world_object()\object_last_move_direction_y=e_engine\e_object_last_direction_y 
 EndIf
 
 
 
   E_FINAL_GFX_SETUP()
   E_SET_UP_FOR_TARGET_ON_PLAYER()
   E_SET_STATIC_MOVE_DIRECTION()
   E_SET_RANDOM_START_DIRECTION()
   E_SET_RANDOM_START_DIRECTION_X()
   E_SET_RANDOM_START_DIRECTION_Y()
   E_SET_UP_COLOR_EFFECTS()
   E_SET_UP_LIGHT_OBJECTS()
   E_RANDOM_START_SPEED()
   ;E_SOUND_PAUSE_GLOBAL_SOUND()
   E_SET_JUMP_PARAMETER()
   E_SET_GLOBAL_SPAWN()
   E_VELOCE_MOVE_HORIZONTAL_RESET()
   E_VELOCE_MOVE_VERTICAL_RESET()
   E_CHECK_FOR_SAVE_MAP_ON_CREATION()
   E_SILUETTE_SET_UP()
   E_SETUP_ENEMY_HEALTH_BAR()
   E_SET_SCROLL_BACK_GROUND()
   
   If world_object()\object_stop_all_music=#True 
     E_SOUND_CORE_CONTROLLER(#ENGINE_STOP_GLOBAL_SOUND)    ;stop music (global music) if object is loaded with this parameter
   EndIf
   
   If world_object()\object_music_global_start=#True
   E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_GLOBAL)  
   EndIf
   
   
   world_object()\object_origin_position_x=world_object()\object_x
   world_object()\object_origin_position_y=world_object()\object_y
 
   If world_object()\object_is_reaper=#True
   e_engine\e_reaper_on_screen=#True  
 EndIf
 
 
 
   
EndProcedure



Procedure E_SET_ANIM_FRAME_TIME(_anim_max_frame.i)
  
  
    
  If _anim_max_frame.i<1  ;we have NO frames!!!!
    world_object()\object_is_anim=#False
  ProcedureReturn #False  
  EndIf
  
    
    If world_object()\object_anim_speed>0
      world_object()\object_anim_frame_time=1000/world_object()\object_anim_speed
    Else
      world_object()\object_anim_frame_time=e_engine_heart_beat\heart_rate
    
    EndIf
    
    world_object()\object_anim_timer=e_engine_heart_beat\beats_since_start+world_object()\object_anim_frame_time ;if elapsed time > anim_timer we show next anim frame and set a new timer

  
  EndProcedure


 


Procedure E_LOAD_ANIM_SPRITE()
  
  ;here we try to read the animfiles:
  ;init for the first entry
  
 
  Define _work_frame.l=0
  Define _exit_loop.b=0
  Define _supported_max_anim_frame.l=32
  Define _anim_max_frame.i=1
  Define _directory_id.i=0
  Define _directory_full_path.s=""

  
  ;e_complete_anim_path.s=v_engine_base.s+e_animation_source.s+world_object()\object_internal_name+"/"
  
  e_complete_anim_path.s=e_engine\e_animation_source+world_object()\object_internal_name+"/"
  e_engine\e_anim_valid=#False
  world_object()\object_is_anim_default=#False
  world_object()\object_is_anim_down=#False
  world_object()\object_is_anim_up=#False
  world_object()\object_is_anim_left=#False
  world_object()\object_is_anim_right=#False
  world_object()\object_is_anim_attack=#False
  world_object()\object_actual_anim_frame_attack=0
  world_object()\object_actual_anim_frame_down=0
  world_object()\object_actual_anim_frame_up=0
  world_object()\object_actual_anim_frame_left=0
  world_object()\object_actual_anim_frame_right=0
  world_object()\object_actual_anim_frame_default=0
  
  world_object()\object_last_move_direction_x=#RIGHT  ;here we store the last actual movedirection to show the correct animframe is object does not move
  world_object()\object_move_direction_x=#RIGHT      ;for first start we have no move direction
 ; world_object()\object_last_move_direction_y=#NO_DIRECTION  ;here we store the last actual movedirection to show the correct animframe is object does not move
  world_object()\object_move_direction_y=#NO_DIRECTION  ;for first start we have no move direction
  
  
 
;-------------------------------------- HERE WE START WITH THE ANIMFRAME LOADING FOR NON FULLSCREEN OBJECTS :
  
  ;some special needed for  random angles at start

 ;_dummy_angle.f=Random(world_object()\object_use_random_angle)
  
  
  ;attack
  
  
;   If world_object()\object_use_attack_anim=#True
;     While _work_frame.l<_supported_max_anim_frame.l And _exit_loop.b=0
;     
;     If IsSprite(world_object()\object_gfx_id_frame_anim_attack[_work_frame.l])
;     FreeSprite(world_object()\object_gfx_id_frame_anim_attack[_work_frame.l])
;     EndIf
;     
;     world_object()\object_gfx_id_frame_anim_attack[_work_frame.l]=LoadSprite(#PB_Any,e_complete_anim_path.s+"ATTACK/"+Str(_work_frame.l)+"."+world_object()\object_gfx_type,#PB_Sprite_AlphaBlending )  
;         
;     If IsSprite( world_object()\object_gfx_id_frame_anim_attack[_work_frame.l])
;       e_anim_valid.b=#True
;       
; If  world_object()\object_anim_no_auto_align=#False
; RotateSprite(world_object()\object_gfx_id_frame_anim_attack[_work_frame.l],270+_dummy_angle.f,#PB_Absolute)
; EndIf
; 
; *gfx=world_object()\object_gfx_id_frame_anim_attack[_work_frame.l]
; E_RESIZE_GFX(*gfx)
; 
;       world_object()\object_last_anim_frame_attack=_work_frame.l
;             _work_frame.l+1
;     Else
;       
;       If _work_frame.l>0
;           world_object()\object_is_anim_attack=#True
;       EndIf
;       
;       _exit_loop.b=1
;     EndIf
;     
;   Wend
;   
; 
; 
;   
; EndIf


 ; _anim_max_frame.i=_work_frame.l  ;very first value for anim frame time

  ;left
  
  
 If world_object()\object_move_y_only=#False
_directory_full_path.s=e_complete_anim_path.s+"LEFT\"
_directory_id.i= ExamineDirectory(#PB_Any,_directory_full_path.s,"*."+world_object()\object_gfx_type)

If IsDirectory(_directory_id.i)
  
    _exit_loop.b=0 
  _work_frame.l=0
  
  While  NextDirectoryEntry(_directory_id.i)
 
    
    If _work_frame.l<_supported_max_anim_frame.l
  
   
    world_object()\object_gfx_id_frame_left[_work_frame.l]=LoadSprite(#PB_Any,_directory_full_path.s+DirectoryEntryName(_directory_id.i),#PB_Sprite_AlphaBlending )  
    
 
        
    If IsSprite( world_object()\object_gfx_id_frame_left[_work_frame.l])
    
      If  world_object()\object_anim_no_auto_align=#False
        RotateSprite(world_object()\object_gfx_id_frame_left[_work_frame.l],270,#PB_Absolute)
      EndIf
      
      e_engine\e_gfx=world_object()\object_gfx_id_frame_left[_work_frame.l]
      E_RESIZE_GFX(e_engine\e_gfx)
      
      e_engine\e_anim_valid=#True
      world_object()\object_last_anim_frame_left=_work_frame.l
      _work_frame.l+1
      
    EndIf
    
  EndIf
Wend

If _work_frame.l>0
  world_object()\object_is_anim_left=#True
  _anim_max_frame.i=_work_frame.l
EndIf
  
FinishDirectory(_directory_id.i)

EndIf


  
  ;_anim_max_frame.i=_work_frame.l  ;very first value for anim frame time

  
;right
  
  _directory_full_path.s=e_complete_anim_path.s+"RIGHT\"
_directory_id.i= ExamineDirectory(#PB_Any,_directory_full_path.s,"*."+world_object()\object_gfx_type)

If IsDirectory(_directory_id.i)
  
    _exit_loop.b=0 
    _work_frame.l=0
    
  While  NextDirectoryEntry(_directory_id.i)
 
    
    If _work_frame.l<_supported_max_anim_frame.l


world_object()\object_gfx_id_frame_right[_work_frame.l]=LoadSprite(#PB_Any,_directory_full_path.s+DirectoryEntryName(_directory_id.i),#PB_Sprite_AlphaBlending )  

  
 
        
    If IsSprite( world_object()\object_gfx_id_frame_right[_work_frame.l])
      If  world_object()\object_anim_no_auto_align=#False
          RotateSprite(world_object()\object_gfx_id_frame_right[_work_frame.l],90,#PB_Absolute)
      EndIf
      
      e_engine\e_gfx=world_object()\object_gfx_id_frame_right[_work_frame.l]
      E_RESIZE_GFX(e_engine\e_gfx)
      
      e_engine\e_anim_valid=#True
      world_object()\object_last_anim_frame_right=_work_frame.l
      _work_frame.l+1
       
    EndIf
    
  EndIf
Wend

If _work_frame.l>0
  world_object()\object_is_anim_right=#True
  _anim_max_frame.i=_work_frame.l
EndIf
  
  FinishDirectory(_directory_id.i)
EndIf

EndIf



  _exit_loop.b=0 
  _work_frame.l=0
  ;up
  
  If world_object()\object_move_x_only=#False
 _directory_full_path.s= e_complete_anim_path.s+"UP\"
_directory_id.i= ExamineDirectory(#PB_Any, _directory_full_path.s,"*."+world_object()\object_gfx_type)

If IsDirectory(_directory_id.i)

  While  NextDirectoryEntry(_directory_id.i)
 
    
    If _work_frame.l<_supported_max_anim_frame.l

    
    world_object()\object_gfx_id_frame_up[_work_frame.l]=LoadSprite(#PB_Any, _directory_full_path.s+DirectoryEntryName(_directory_id.i),#PB_Sprite_AlphaBlending )  
   
    
 
        
    If IsSprite( world_object()\object_gfx_id_frame_up[_work_frame.l])
;       If  world_object()\object_anim_no_auto_align=#False
;         RotateSprite(world_object()\object_gfx_id_frame_up[_work_frame.l],270+_dummy_angle.f,#PB_Absolute)   ;up is default spriteposition!
;       EndIf
      
      e_engine\e_gfx=world_object()\object_gfx_id_frame_up[_work_frame.l]
      E_RESIZE_GFX(e_engine\e_gfx)
      
      e_engine\e_anim_valid=#True
      world_object()\object_last_anim_frame_up=_work_frame.l
      _work_frame.l+1
       
      
    EndIf
  EndIf
Wend

If _work_frame.l>0
  world_object()\object_is_anim_up=#True
  _anim_max_frame.i=_work_frame.l
EndIf
  
  FinishDirectory(_directory_id.i)
EndIf



  _exit_loop.b=0 
  _work_frame.l=0


;down

    
  _directory_full_path.s=e_complete_anim_path.s+"DOWN\"
  _directory_id.i= ExamineDirectory(#PB_Any,_directory_full_path.s,"*."+world_object()\object_gfx_type)
  
  If IsDirectory(_directory_id.i)
  
  While  NextDirectoryEntry(_directory_id.i)
 
    
    If _work_frame.l<_supported_max_anim_frame.l
  

    
    world_object()\object_gfx_id_frame_down[_work_frame.l]=LoadSprite(#PB_Any,_directory_full_path.s+DirectoryEntryName(_directory_id.i),#PB_Sprite_AlphaBlending )  

    
 
        
    If IsSprite( world_object()\object_gfx_id_frame_down[_work_frame.l])
      If  world_object()\object_anim_no_auto_align=#False
        RotateSprite(world_object()\object_gfx_id_frame_down[_work_frame.l],180,#PB_Absolute)
      EndIf
      
     e_engine\e_gfx=world_object()\object_gfx_id_frame_down[_work_frame.l]
      E_RESIZE_GFX(e_engine\e_gfx)
      
      e_engine\e_anim_valid=#True
      world_object()\object_last_anim_frame_down=_work_frame.l
      _work_frame.l+1
        
      
    EndIf
  EndIf
Wend

If _work_frame.l>0
  world_object()\object_is_anim_down=#True
  _anim_max_frame.i=_work_frame.l
EndIf
  
  FinishDirectory(_directory_id.i)
EndIf

EndIf

   
  _exit_loop.b=0 
  _work_frame.l=0

  ;default
  
 _directory_full_path.s=e_complete_anim_path.s+"DEFAULT\"
 _directory_id.i= ExamineDirectory(#PB_Any,_directory_full_path.s,"*."+world_object()\object_gfx_type)
 
 If IsDirectory(_directory_id.i)
 
  While  NextDirectoryEntry(_directory_id.i)
 
    
    If _work_frame.l<_supported_max_anim_frame.l

    world_object()\object_gfx_id_frame_anim_default[_work_frame.l]=LoadSprite(#PB_Any,_directory_full_path.s+DirectoryEntryName(_directory_id.i),#PB_Sprite_AlphaBlending )  
    
        
    If IsSprite( world_object()\object_gfx_id_frame_anim_default[_work_frame.l])

e_engine\e_gfx=world_object()\object_gfx_id_frame_anim_default[_work_frame.l]
      E_RESIZE_GFX(e_engine\e_gfx)
      
      e_engine\e_anim_valid=#True
      world_object()\object_last_anim_frame_default=_work_frame.l
      _work_frame.l+1
        
    EndIf
  EndIf
Wend

If _work_frame.l>0
  world_object()\object_is_anim_default=#True
  _anim_max_frame.i=_work_frame.l
EndIf
  
  FinishDirectory(_directory_id.i)
EndIf

  
If  e_engine\e_anim_valid=#False
  world_object()\object_is_anim=#False  ;show the default single frame gfx  
  ProcedureReturn #False
EndIf
  
E_SET_ANIM_FRAME_TIME(_anim_max_frame.i)



  

EndProcedure




  
  
  
  


  Procedure E_SETUP_AI(_arg.s)
;     
;   #AI_NOTHING
;   #AI_NO_MOVE
;   #AI_RANDOM_MOVE
;   #AI_RANDOM_FAST_MOVE
;   #AI_STATIC_MOVE
;   #AI_CHANGE_DIRECTION
    
    

    Select  _arg.s
        
      Case "#AI_NO_MOVE"
        
        world_object()\object_use_ai=#AI_NO_MOVE
        
      Case "#AI_RANDOM_MOVE"
          world_object()\object_use_ai=#AI_RANDOM_MOVE
        
      Case "#AI_RANDOM_FAST_MOVE"
          world_object()\object_use_ai=#AI_RANDOM_FAST_MOVE
        
        Case "#AI_STATIC_MOVE"
          world_object()\object_use_ai=#AI_STATIC_MOVE
        
        Case "#AI_CHANGE_DIRECTION"
          world_object()\object_use_ai=#AI_CHANGE_DIRECTION
          
        Case "#AI_PARENT_DIRECTION"
      world_object()\object_use_ai=#AI_PARENT_DIRECTION
      
      
      
      
          
        Default 
          world_object()\object_use_ai=#AI_NOTHING
    EndSelect
    
    
  EndProcedure
  

  

  Procedure E_INIT_OBJECT_DEFAULT_STATE() 
    ;here we set all defaults for a new added object (default values, this code block may be not used?)
    ;this values will be changed by reading the ai file
    
    ;here we go:
    world_object()\object_use_locale=#False
    world_object()\object_transparency=255  ;full visible
    world_object()\object_stop_if_attraction=#False
    world_object()\object_is_global_light=#False
    world_object()\object_go_for_attraction=#False
    world_object()\object_attraction_pick_up=#False
    world_object()\object_is_attraction=#False
    world_object()\object_area_no_limit=#False
    world_object()\object_allert_on_treasure=#False
    world_object()\object_play_sound_on_treasure=#False
    world_object()\object_slippery_mode=#False
    world_object()\object_use_attack_direction=#False
    world_object()\object_is_arena_object=#False
    world_object()\object_remove_if_out_of_area=#False
    world_object()\object_overide_static_move=#False
    world_object()\object_create_no_child_if_hide_away=#False
    world_object()\object_NPC_show_text_on_collision=#False
    world_object()\object_is_weapon=#False
    world_object()\object_no_collision_on_hide=#False
    world_object()\object_ignore_weapon_on_hide=#False

    world_object()\object_shadow_use_perspective=#False
    world_object()\object_stop_all_music=#False
    world_object()\object_boss_music_mode=#False
    world_object()\object_play_sound_on_change=#False
    world_object()\object_play_sound_on_create=#False
    world_object()\object_play_sound_on_create_child=#False
    world_object()\object_use_fight_effect=#False
    world_object()\object_weapon_remove_after_hit=#False
    world_object()\object_no_weapon_interaction=#False 
    world_object()\object_sound_play_on_rotate=#False
    world_object()\object_allert_on_player=#False
    world_object()\object_inactive_after_timer=#False
    world_object()\object_is_NESW=#False
    world_object()\object_set_day=#False
    world_object()\object_set_night=#False
    world_object()\object_is_loot=#False
    world_object()\object_is_map_ground=#False
    world_object()\object_use_map_ground=#False
    world_object()\object_change_on_life_time_is_over=#False
    world_object()\object_change_on_dead=#False
    world_object()\object_save_map_on_collision=#False
    world_object()\object_remove_after_fade_out=#False
    world_object()\object_do_not_save_after_change=#False
    world_object()\object_no_collision_after_collision=#False
    world_object()\object_inactive_after_collision=#False
    world_object()\object_inactive_after_change=#False
    world_object()\object_remove_after_change=#False
    world_object()\object_remove_after_collison=#False
    world_object()\object_is_light=#False
    world_object()\object_use_day_night_change=#False
    world_object()\object_fade_in_on_creation=#False
    world_object()\object_is_boss=#False

    world_object()\object_remove_with_boss=#False
    world_object()\object_play_sound_on_activate=#False
    world_object()\object_set_child_direction=#False
    world_object()\object_use_parent_direction=#False
    world_object()\object_target_on_player=#False
    world_object()\object_sound_is_boss=#False
    world_object()\object_change_on_collision=#False
    world_object()\object_play_sound_on_move=#False
    world_object()\object_play_sound_on_collision=#False
    world_object()\object_is_anim=#False
    world_object()\object_collision=#False
    world_object()\object_is_active=#False
    world_object()\object_is_trigger=#False
    world_object()\object_use_shadow=#False 
    world_object()\object_touch_collision=#False
    
    world_object()\object_do_not_save=#False  
    world_object()\object_use_fade=#False
    world_object()\object_use_indexer=#False
    world_object()\object_health_bar_active=#False
    world_object()\object_inventory_quest_object_remove_after_use=#False
    world_object()\object_change_on_inventory_object=#False
    world_object()\object_use_locale=#False
    world_object()\object_action_on_internal_name=#False
    world_object()\object_spawn_at_player_if_out_of_area=#False
    world_object()\object_collision_ignore_player=#False
    world_object()\object_do_not_save_after_collision=#False
    world_object()\object_change_move_after_collision=#False
    world_object()\object_activate_on_companion=#False
    world_object()\object_emit_on_move=#False
    world_object()\object_action_status_x=#NO_DIRECTION
    world_object()\object_action_status_y=#NO_DIRECTION 
    world_object()\object_NPC_switch_map_on_talk=#False
    world_object()\object_activate_on_day=#False
    world_object()\object_activate_on_night=#False
    world_object()\object_deactivate_on_day=#False
    world_object()\object_deactivate_on_night=#False
    world_object()\object_back_ground_auto_scroll=#False
    world_object()\object_effect_on_player_collision=#False 
    world_object()\object_remove_after_effect_on_player=#False  
    world_object()\object_remove_after_dead=#False
    world_object()\object_remove_on_night=#False
    world_object()\object_remove_on_day=#False
    world_object()\object_remove_after_last_anim_frame=#False
    world_object()\object_create_on_level_up=#False
    world_object()\object_deactivate_use_alternative_gfx=#False
    world_object()\object_change_on_last_frame=#False
    world_object()\object_use_spawn_offset=#False
    world_object()\object_anim_no_auto_align=#False
    world_object()\object_use_virtual_buffer=#False
    world_object()\object_move_x_only=#False
    world_object()\object_move_y_only=#False
    world_object()\object_use_static_id=0
    world_object()\object_use_dynamic_id=#False

    world_object()\object_use_energy_status=#False
    world_object()\object_use_position_on_raster=#False
    world_object()\object_use_timed_action=#False
    world_object()\object_use_gravity=#False
    world_object()\object_jump_size=0
    world_object()\object_can_jump=#False
    world_object()\object_jump_size_actual=0
    world_object()\object_can_move_in=#False ;enter houses and locations in jump and run world, after collision with "door" it is switched to #true, if you push key up. you will enter the level/house/location
    world_object()\object_is_on_ground=#False
    world_object()\object_use_player_direction_x=#False
    world_object()\object_use_player_direction_y=#False
    world_object()\object_use_random_start_direction=#False
    world_object()\object_play_sound_on_jump=#False
    world_object()\object_change_direction_on_random=#False
    world_object()\object_weapon_timeout=0
    world_object()\object_use_own_trigger_zone=#False
    world_object()\object_area_loop_horizont=#False
    world_object()\object_area_loop_vertical=#False
    world_object()\object_show_coordinates=#False
    world_object()\object_reset_position_on_timer=#False
    world_object()\object_emitter_use_max_objects=#False
    world_object()\object_use_transparency_back_up=#False
    world_object()\object_use_attack_anim=#False
    world_object()\object_is_attacking=#False
    world_object()\object_turn_on_left_screen=#False
    world_object()\object_use_position_back_up=#False
    world_object()\object_check_if_player_on_top=#False
    world_object()\object_anim_start_on_collison=#False
    world_object()\object_no_interaction_on_enemy=#False
    world_object()\object_emit_on_timer=#False
    world_object()\object_collision_flip_flop=#False
    world_object()\object_backup_size=#False
    world_object()\object_play_sound_once=#False
    world_object()\object_activate_map_scroll=#False
    world_object()\object_deactivate_map_scroll=#False
    world_object()\object_do_not_save_after_inactive=#False
    world_object()\object_use_status_controller=#False
    world_object()\object_static_move=#False
    world_object()\object_use_ai=#AI_NO_MOVE
    world_object()\object_use_stamp=#False
    world_object()\object_use_life_time_per_pixel=#False
    world_object()\object_reset_position_on_pixel_count=#False
    world_object()\object_remove_after_pixel_count=#False
    world_object()\object_anim_loop=#False
    world_object()\object_play_sound_on_random=#False
    world_object()\object_stop_after_pixel_count=#False
    world_object()\object_activate_global_flash=#False
    world_object()\object_use_random_transparency_on_start=#False
    world_object()\object_stream_sound_on_create=#False
    world_object()\object_stream_sound_on_move=#False
    world_object()\object_use_own_color=#False
    world_object()\object_change_direction_x_on_max=#False
    world_object()\object_no_flash_interaction=#False
    world_object()\object_change_direction_y_on_max=#False
    world_object()\object_gfx_set_w_h=#False
    world_object()\object_no_global_light_interaction=#False
    world_object()\object_is_global_light_on_collision=#False
    world_object()\object_use_random_start_speed_x=#False
    world_object()\object_use_random_start_speed_y=#False
    world_object()\object_reset_position_on_fade_out=#False
    world_object()\object_use_random_color_RGB=#False
    world_object()\object_use_random_start_direction_x=#False
    world_object()\object_use_random_start_direction_y=#False
    world_object()\object_use_speed_change=#False
    world_object()\object_remove_after_timer=#False
    world_object()\object_change_after_pixel_count=#False
    world_object()\object_show_hit_effect=#False
    world_object()\object_jump_velocity_auto=#False
    world_object()\object_use_random_jump=#False
    world_object()\object_is_boss_guard=#False
    world_object()\object_play_sound_on_allert=#False
    world_object()\object_no_enemy_action=#False
    world_object()\object_collision_tractor_object=#False
    world_object()\object_deactivate_tractor_if_left_border=#False
    world_object()\object_set_player_gravity_off=#False

    world_object()\object_ignore_one_key=#False
    world_object()\object_is_transporter=#False
    world_object()\object_stop_move_after_collision=#False
    world_object()\object_turn_on_screen_center=#False
    world_object()\object_spawn_offset_parent_center=#False
    world_object()\object_use_rotate_direction=#False
    world_object()\object_use_swing_rotate=#False
    world_object()\object_play_sound_on_rotate=#False
    world_object()\object_collision_ignore_player=#False
    world_object()\object_NPC_switch_map_on_talk=#False
    world_object()\object_activated_by_object=#False
    world_object()\object_activate_other_on_creation=#False
    world_object()\object_play_sound_on_talk=#False
    world_object()\object_shake_world=#False
    world_object()\object_stop_if_guard_on_screen=#False
    world_object()\object_NPC_remove_after_talk=#False
    world_object()\object_emitter_pause_if_idle=#False
    world_object()\object_emit_stop_if_guard_on_screen=#False
    world_object()\object_is_spawn_destination=#False
    world_object()\object_use_spawn_destination=#False
    world_object()\object_did_spawn=#False 
    world_object()\object_use_random_layer=#False
    world_object()\object_remove_after_full_resize=#False
    world_object()\object_use_creation_counter=#False
    world_object()\object_use_global_spawn=#False
    world_object()\object_use_status_controller_parent=#False
    world_object()\object_no_clear_screen=#False
    world_object()\object_random_spawn_positive_only=#False
    world_object()\object_no_shake_interaction=#False
    world_object()\object_move_flappy_mode=#False
    world_object()\object_use_air_time_kill=#False
    world_object()\object_save_map_on_creation=#False
    world_object()\object_use_glass_effect=#False
    world_object()\object_collision_get_dynamic_id=#False
    world_object()\object_use_global_effect=#False
    world_object()\object_stop_move_right_border=#False
    world_object()\object_turn_on_right_border=#False
    world_object()\object_emit_on_jump=#False
    world_object()\object_use_horizontal_velocity=#False
    world_object()\object_use_vertical_velocity=#False
    world_object()\object_vertical_direction_change=#False
    world_object()\object_horizontal_direction_change=#False
    world_object()\object_use_make_move_timer=#False
    world_object()\object_use_blink_timer=#False
    world_object()\object_no_horizontal_move_if_falling=#False
    world_object()\object_no_siluette=#False
    world_object()\object_use_in_front_transparency=#False
    world_object()\object_change_on_fade_out=#False
    world_object()\object_emit_stop_on_collision=#False
    world_object()\object_play_sound_on_emit=#False
    world_object()\object_play_sound_on_change=#False
    world_object()\object_use_spawn_border_offset=#False
    world_object()\object_show_hp_bar=#False
    world_object()\object_debug_if_remove=#False
    world_object()\object_no_child_if_move_down=#False
    world_object()\object_no_gravity_after_collision=#False
    world_object()\object_has_changed_on_collsion=#False
    world_object()\object_use_teleport_on_max_x=#False
    world_object()\object_use_teleport_effect=#False
    world_object()\object_save_map_on_remove=#False
    world_object()\object_set_fade_out_on_ai=#False
    world_object()\object_activate_fade_out_on_ai=#False
    world_object()\object_music_global_start=#False
    world_object()\object_anim_stop_after_last_frame=#False
    world_object()\object_use_start_direction=#False
    world_object()\object_follow_player_after_timer=#False
    world_object()\object_keep_move_direction=#False
    world_object()\object_stop_scroll_after_allert=#False
    world_object()\object_stream_gfx_loaded=#False
    world_object()\object_play_sound_on_restore=#False
    world_object()\object_sound_on_restore_is_playing=#False
    world_object()\object_remove_with_guard=#False
    world_object()\object_emitter_pause_if_spawn=#False
    world_object()\object_use_effect_area=#False
    world_object()\object_use_auto_reposition=#False
    world_object()\object_use_virtual_buffer=#False
    world_object()\object_use_call_dead_timer=#False
    world_object()\object_call_dead=#False
    world_object()\object_is_reaper=#False
    world_object()\object_use_physic_collision=#False
    world_object()\object_use_physic_loop=#False
    world_object()\object_use_physic_no_collision=#False
    world_object()\object_use_asset_load_pause=#False
    world_object()\object_collision_on_off=#False
    world_object()\object_is_scroll_back_ground=#False
    world_object()\object_use_enemy_maximum=#False
    world_object()\object_use_player_position=#False
    world_object()\object_turn_right_screen_full_spawn=#False
    world_object()\object_NPC_use_talk_area=#False
    world_object()\object_NPC_is_talking=#False
    world_object()\object_change_emitter=#False
    world_object()\object_switch_map=#False
    world_object()\object_use_isometric=#False
   
    EndProcedure
     
    
  

     
    

  
  Procedure E_STREAM_LOAD_SPRITE(_mode.i)
    ;***************************************************
    ;here we read all object relevant   infos
    
    
    If world_object()\object_stream_gfx_loaded=#True And _mode.i=#E_STREAM ;no objects are added to the map
      ProcedureReturn #False  
    EndIf
    
    e_engine\e_engine_source_element=world_object()\object_ai_path
    
    Define _dummy.s=""
    Define _sprt.i=0
    Define _ok.i=0
    Define _key.s=""
    Define _help_path.s=""
    Define _dummy_x.f=world_object()\object_x
    Define _dummy_y.f=world_object()\object_y
    Define _dummy_layer.i=world_object()\object_layer
    Define _dumy_last_list_element.i=0
    Define _dummy_found_string_pos.i=0
    Define _gfx_stream_buffer_found.b=#False  ; use it for the gfx virtual buffer stream system
    Define _remove_non_valid_element.b=#False
    Define _vmem_info.i=#False
    Define _direction_x.i=#NO_DIRECTION
    Define _direction_y.i=#NO_DIRECTION
    Define _dummy_w.f=world_object()\object_w
    Define _dummy_h.f=world_object()\object_h
    Define _child_parent_key.i=ElapsedMilliseconds()
    
    
    
    
    
     
  Define _w.f=0
  Define _h.f=0
  Define _md.i=0
  Define _x.f
  
   
  _w.f=world_object()\object_w
  _h.f=world_object()\object_h
  _md.i=world_object()\object_move_direction_x
  _x.f=world_object()\object_x
 
    
    e_engine\e_engine_object_last_layer=world_object()\object_layer
    e_engine\e_object_last_direction_x=world_object()\object_move_direction_x
    e_engine\e_object_last_direction_y=world_object()\object_move_direction_y
    
    
        
    
    Select _mode.i
        
       
       
        
        
        
        
      Case #E_ADD_ELEMENT_TO_MAP   ;add single object to map
        
        
        ;default initialising:
        
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_alternative_gfx_default_ai42
        
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i ;position the object in the same layer as the creator
          world_object()\object_ai_path=_dummy.s          
          world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
          e_engine\e_sort_map_by_layer=#True      

        
          
          
        
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT:",Str(ListSize(world_object())))
          ProcedureReturn  #False;we can not add an element  anymore
        EndIf
        
        
        
                 Case #E_ADD_JUMP_EMIT_TO_MAP  ;add single object to map
        
        
        ;default initialising:
        
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_emit_object_jump_ai42
   
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i ;position the object in the same layer as the creator
          world_object()\object_ai_path=_dummy.s
          
          world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
          e_engine\e_sort_map_by_layer=#True      
          
        
          
          
        
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT:",Str(ListSize(world_object())))
          ProcedureReturn  #False;we can not add an element  anymore
        EndIf
        
           Case #E_ADD_GLOBAL_EFFECT_TO_OBJECT  ;add single object to map
        
        
        ;default initialising:
        
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_global_effect_ai42
   
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i ;position the object in the same layer as the creator
          world_object()\object_ai_path=_dummy.s
          
          world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
          e_engine\e_sort_map_by_layer=#True      
          
        
          
          
        
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT:",Str(ListSize(world_object())))
          ProcedureReturn  #False;we can not add an element  anymore
        EndIf
        
           Case #E_ADD_OBJECT_EMITTED_TO_MAP   ;add single object to map (emitter, used for emitter with max objects...)
        
        
        ;default initialising:
        
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_emit_object_ai42_default


        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i ;position the object in the same layer as the creator
          world_object()\object_ai_path=_dummy.s
          
           world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
          e_engine\e_sort_map_by_layer=#True
          
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT:",Str(ListSize(world_object())))
          ProcedureReturn  #False;we can not add an element  anymore
        EndIf
        
        
        
                  Case #E_ADD_DEAD_TO_MAP   ;add single object to map (emitter, used for emitter with max objects...)
        
        
        ;default initialising:
        
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_dead_timer_object_ai42


        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i ;position the object in the same layer as the creator
          world_object()\object_ai_path=_dummy.s
          
           world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
          e_engine\e_sort_map_by_layer=#True
          
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT:",Str(ListSize(world_object())))
          ProcedureReturn  #False;we can not add an element  anymore
        EndIf
        
        
        
        
          Case #E_ADD_LEVEL_UP_EFFECT

        ;default initialising:
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_child_on_level_up_ai42
        ;_use_parent_direction_all.i=E_AI_SET_CHILD_DIRECTION()
        
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i
          world_object()\object_ai_path=_dummy.s
          world_object()\object_is_child=#True
           world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
      
        If _direction_x.i<>#NO_DIRECTION Or _direction_y.i<>#NO_DIRECTION
    
            world_object()\object_move_direction_x=_direction_x.i
            world_object()\object_last_move_direction_x=_direction_x.i
            
             world_object()\object_move_direction_y=_direction_y.i
            world_object()\object_last_move_direction_y=_direction_y.i
          EndIf
          e_engine\e_sort_map_by_layer=#True
          
       
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN Not ADD ELEMENT",Str(ListSize(world_object())))
          ProcedureReturn #False;we can not add an element  anymore
        EndIf
        
        
        
      Case #E_ADD_CHANGED_EMITTER_TO_MAP
        
        
        ;default initialising:
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_change_emitter_new_path
         
 
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i
          world_object()\object_ai_path=_dummy.s
          world_object()\object_is_child=#True
           world_object()\object_parent_height=_dummy_h.f
          world_object()\object_parent_width=_dummy_w.f
      
        If _direction_x.i<>#NO_DIRECTION Or _direction_y.i<>#NO_DIRECTION
    
            world_object()\object_move_direction_x=_direction_x.i
            world_object()\object_last_move_direction_x=_direction_x.i
            
             world_object()\object_move_direction_y=_direction_y.i
            world_object()\object_last_move_direction_y=_direction_y.i
          EndIf
          e_engine\e_sort_map_by_layer=#True
          
       
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT",Str(ListSize(world_object())))
          ProcedureReturn #False;we can not add an element  anymore
        EndIf
        
        
        
        
      Case #E_ADD_CHILD_TO_MAP

        
        
        ;default initialising:
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_child_gfx_ai_path
       ; _use_parent_direction_all.i=E_AI_SET_CHILD_DIRECTION()
     
        
        ;world_object()\object_do_create_child=#False
        
        If world_object()\object_set_child_direction=#True
          _direction_x.i=world_object()\object_move_direction_x  
          _direction_y.i=world_object()\object_move_direction_y  
        EndIf
        

        
        If AddElement(world_object())
           E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i
          world_object()\object_ai_path=_dummy.s
          world_object()\object_is_child=#True
           world_object()\object_parent_height=_dummy_h.f
           world_object()\object_parent_width=_dummy_w.f

          
        If _direction_x.i<>#NO_DIRECTION Or _direction_y.i<>#NO_DIRECTION
    
            world_object()\object_move_direction_x=_direction_x.i
            world_object()\object_last_move_direction_x=_direction_x.i
            
             world_object()\object_move_direction_y=_direction_y.i
            world_object()\object_last_move_direction_y=_direction_y.i
          EndIf
         e_engine\e_sort_map_by_layer=#True
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT",Str(ListSize(world_object())))
          ProcedureReturn #False;we can not add an element  anymore
        EndIf
        

      Case #E_ADD_DAY_EMIT_TO_MAP
        
        
        ;default initialising:
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_set_emitter_day_ai42
       ; _use_parent_direction_all.i=E_AI_SET_CHILD_DIRECTION()
     
       
        
        If world_object()\object_set_child_direction=#True
          _direction_x.i=world_object()\object_move_direction_x  
          _direction_y.i=world_object()\object_move_direction_y  
        EndIf
        
        If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i
          world_object()\object_ai_path=_dummy.s

          world_object()\object_is_child=#True
          ;world_object()\object_stream_gfx_loaded=#False
           
        If _direction_x.i<>#NO_DIRECTION Or _direction_y.i<>#NO_DIRECTION
    
            world_object()\object_move_direction_x=_direction_x.i
            world_object()\object_last_move_direction_x=_direction_x.i
            
             world_object()\object_move_direction_y=_direction_y.i
            world_object()\object_last_move_direction_y=_direction_y.i
          EndIf
          
          
          e_engine\e_sort_map_by_layer=#True
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT",Str(ListSize(world_object())))
          ProcedureReturn #False;we can not add an element  anymore
        EndIf
        
        
            Case #E_ADD_NIGHT_EMIT_TO_MAP
        
        
        ;default initialising:
        _dummy.s=GetPathPart(world_object()\object_ai_path)+world_object()\object_set_emitter_night_ai42
       ; _use_parent_direction_all.i=E_AI_SET_CHILD_DIRECTION()
     
        
        ;world_object()\object_do_create_child=#False
        
         If world_object()\object_set_child_direction=#True
          _direction_x.i=world_object()\object_move_direction_x  
          _direction_y.i=world_object()\object_move_direction_y  
        EndIf
        
        
        If AddElement(world_object())
           E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+_dummy_x.f
          world_object()\object_y+_dummy_y.f
          world_object()\object_layer=_dummy_layer.i
          world_object()\object_auto_layer=_dummy_layer.i
          world_object()\object_ai_path=_dummy.s
          world_object()\object_is_child=#True
          ;world_object()\object_stream_gfx_loaded=#False
        
         
        If _direction_x.i<>#NO_DIRECTION Or _direction_y.i<>#NO_DIRECTION
    
            world_object()\object_move_direction_x=_direction_x.i
            world_object()\object_last_move_direction_x=_direction_x.i
            
             world_object()\object_move_direction_y=_direction_y.i
            world_object()\object_last_move_direction_y=_direction_y.i
          EndIf
           
          e_engine\e_sort_map_by_layer=#True
        Else
          E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT",Str(ListSize(world_object())))
          ProcedureReturn #False;we can not add an element  anymore
        EndIf
        
      
  ;--------weapon    
      
        
      Case #E_ADD_PLAYER_WEAPON_TO_MAP
        
        ;this is as special  situation: 
        ;weapons are generated as "one shot" for default all directions and settings are set at start and kept until weapon is vanished
        ;default initialising:
        
        If e_engine\e_map_mode_fight=#False
        ProcedureReturn #False  
        EndIf
        
         
        If e_fight_timeout_player.i>e_engine_heart_beat\beats_since_start
          ProcedureReturn #False
        EndIf
        
         If world_object()\object_set_child_direction=#True
          _direction_x.i=world_object()\object_move_direction_x  
          _direction_y.i=world_object()\object_move_direction_y  
        EndIf
        
            
            _dummy.s=GetPathPart(world_object()\object_ai_path)+e_player_weapon_path_ai42.s
        ; _use_parent_direction_all.i=E_AI_SET_CHILD_DIRECTION()
          If AddElement(world_object())
          E_INIT_OBJECT_DEFAULT_STATE()
          world_object()\object_x+e_engine\e_player_weapon_x
          world_object()\object_y+e_engine\e_player_weapon_y
          world_object()\object_layer=e_engine\e_player_layer
          world_object()\object_ai_path=_dummy.s
          ;world_object()\object_do_not_stream=#True  ;changed 12032021
          ;world_object()\object_is_weapon=#True
          world_object()\object_is_child=#True
          ;world_object()\object_stream_gfx_loaded=#False  ;changed 12032021
          
          player_statistics\player_throw_axe=#True
          e_engine\e_sort_map_by_layer=#True
            Else
              E_LOG(e_engine\e_engine_source_element,"CAN NOT ADD ELEMENT",Str(ListSize(world_object())))
           ProcedureReturn #False;we can not add an element  anymore
        EndIf
        
    EndSelect
    
    
    _ok.i=ReadFile(#PB_Any,world_object()\object_ai_path)  ;default path
    
    If IsFile(_ok.i)=0
   ; 
      E_LOG(e_engine\e_engine_source_element,"CAN NOT CREATE ELEMENT: "+world_object()\object_ai_path,"")
              world_object()\object_remove_from_list=#True   ;we have no data to work with.... need at least a42 file 
    ProcedureReturn #False ;we got nothing!
    EndIf
    
  
    
    While Not Eof(_ok.i)
      
      _key.s=Trim(ReadString(_ok.i))  ;remove " " from the string, our keywords do not use  any " " on the begining or on the end or anywhere in the string
                                      ;--here we set the keywords to unitype, so we do not have to take care of the type using the ai42 (workaround, because some dataformats have changed)
                                      ;important lines! 
      If FindString(_key.s,"#",1)=0   ;keep _key.s#
        _key.s=Mid(_key.s,1,FindString(_key.s,".",1)-1)  ;remove .type
      EndIf
      ;-------------------------------
      
      Select _key.s
          
        Case "object_file#"
          world_object()\object_gfx_path=ReadString(_ok.i)
          
        Case "object_type#"
          _dummy.s=ReadString(_ok.i)
          world_object()\object_gfx_path=world_object()\object_gfx_path+"."+_dummy.s
          world_object()\object_gfx_type=_dummy.s
          
          ;-----------------for shadow map path------------------------------------

          
          
        Case "object_anim_speed"
          world_object()\object_anim_speed=Val(ReadString(_ok.i))
          
          
          
        Case "object_swing_rotate_angle"
          world_object()\object_swing_rotate_angle=Val(ReadString(_ok.i))
          
        Case "object_swing_rotate_step"
          world_object()\object_swing_rotate_step=ValF(ReadString(_ok.i))
          
          
          
        Case "object_death_action_ai42"
          world_object()\object_death_action_ai42=Trim(ReadString(_ok.i))
          
        Case "object_action_on_internal_name"
          world_object()\object_action_on_internal_name=Val(ReadString(_ok.i))
          
          
          
          
          
        Case "object_use_locale"
         
          world_object()\object_use_locale=Val(ReadString(_ok.i))
         
          
     
          
        Case "object_use_inventory_object"
          world_object()\object_use_inventory_object=Trim(ReadString(_ok.i))
          
        Case "object_change_on_inventory_object"
  
            world_object()\object_change_on_inventory_object=Val(ReadString(_ok.i))
     
          
        
        Case "object_inventory_quest_object_remove_after_use"
             world_object()\object_inventory_quest_object_remove_after_use=Val(ReadString(_ok.i))
       
          
        Case "object_show_boss_bar"
          world_object()\object_show_boss_bar=Val(ReadString(_ok.i))
          
          
        Case "object_fixed_xp"
          world_object()\object_fixed_xp=Val(ReadString(_ok.i))
          
        Case "object_follow_player"
          world_object()\object_follow_player=Val(ReadString(_ok.i))
          
        Case "object_gold_value"
          world_object()\object_gold_value=Val(ReadString(_ok.i))
          
        Case "object_health_bar_path"
          
          
          world_object()\object_health_bar_path= Trim(ReadString(_ok.i))
                   
           Case "object_health_bar_back_path"
          world_object()\object_health_bar_back_path=e_engine\e_graphic_source.s+Trim(ReadString(_ok.i))
         
      
          
        Case "object_open_gate_on_death"
          world_object()\object_open_gate_on_death=Trim(ReadString(_ok.i))
          
          
        Case "object_danger_gfx_path"
          world_object()\object_danger_gfx_path=Trim(ReadString(_ok.i))
          
        Case "object_is_amor_up_potion"
          world_object()\object_is_amor_up_potion=Val(ReadString(_ok.i))
          
       
        Case "object_is_heal_potion"
          world_object()\object_is_heal_potion=Val(ReadString(_ok.i))
          
      
          
          
        Case "object_inventory_object_path"
          world_object()\object_inventory_object_path=ReadString(_ok.i)
          
        Case "object_spawn_offset_x"
          world_object()\object_spawn_offset_x=ValF(ReadString(_ok.i))
          
        Case "object_spawn_offset_y"
          world_object()\object_spawn_offset_y=ValF(ReadString(_ok.i))
          
          
          
        Case "object_need_gold"
          world_object()\object_need_gold=Val(ReadString(_ok.i))
          
         
          
        Case "object_use_price_tag"
          
          world_object()\object_price_tag_path=e_engine\e_graphic_source.s+Trim(ReadString(_ok.i))
          
           
          
          
        Case "object_health_bar_size_w"
          world_object()\object_health_bar_size_w=ValF(ReadString(_ok.i))
          
        Case "object_health_bar_size_h"
          world_object()\object_health_bar_size_h=ValF(ReadString(_ok.i))
          
        Case "object_random_xp"
          world_object()\object_random_xp=Val(ReadString(_ok.i))
          
          
            
        Case "object_use_random_pause"
          world_object()\object_use_random_pause=Val(ReadString(_ok.i))
          
        Case "object_use_indexer"
      
            world_object()\object_use_indexer=Val(ReadString(_ok.i))
     
          
        Case "object_use_random_shadow_color"
          world_object()\object_use_random_shadow_color=Val(ReadString(_ok.i))
          
          
        Case "object_fade_out_per_tick"
                    world_object()\object_fade_out_per_tick=ValF(ReadString(_ok.i))
          
         
          
          
      
        Case "object_NPC_internal_name"
          world_object()\object_NPC_internal_name=ReadString(_ok.i)
          
        Case "object_NPC_text_path"
          world_object()\object_NPC_text_path=ReadString(_ok.i)
          
        Case "object_NPC_show_text_on_collision"
          world_object()\object_NPC_show_text_on_collision=Val(ReadString(_ok.i))
          
        Case "object_do_not_save"
            world_object()\object_do_not_save=Val(ReadString(_ok.i))
        
          
          
        Case "object_weapon_timeout"
          world_object()\object_weapon_timeout=Val(ReadString(_ok.i))
          
        Case "object_transparency"
          world_object()\object_transparency=255-ValF(ReadString(_ok.i))
           world_object()\object_transparency_target=world_object()\object_transparency+255
          world_object()\object_transparency_back_up=world_object()\object_transparency
    
          
      
        Case "object_touch_collision"
          
          
          world_object()\object_touch_collision=Val(ReadString(_ok.i))
          
         
          
          
        Case "object_touch_transparency"
          world_object()\object_touch_transparency=Val(ReadString(_ok.i))
          If world_object()\object_touch_transparency<1
            world_object()\object_touch_transparency=0
          EndIf
          If world_object()\object_touch_transparency>255
          world_object()\object_touch_transparency=255  
          EndIf
          
          
          
          
        Case "object_random_anim_start"
          world_object()\object_random_anim_start=Val(ReadString(_ok.i))
                 
          
        Case "object_random_size_on_start"
          world_object()\object_random_size_on_start=Random(ValF(ReadString(_ok.i)))
          
        Case "object_NPC_text_pic_path"
          world_object()\object_NPC_text_pic_path=ReadString(_ok.i)
          
        Case "object_weapon_create_paths_ai42"
          world_object()\object_weapon_create_paths_ai42=ReadString(_ok.i)
          
        Case "object_use_shadow"
          
        world_object()\object_use_shadow=Val(ReadString(_ok.i))
            
      
          
          
        Case "object_shadow_intense"
          world_object()\object_shadow_intense=Val(ReadString(_ok.i))
          
        Case "object_shadow_offset_x"
          world_object()\object_shadow_offset_x=ValF(ReadString(_ok.i))
          
        Case "object_shadow_offset_y"
          world_object()\object_shadow_offset_y=ValF(ReadString(_ok.i))
          
        Case "object_ontrigger_move_x"
          world_object()\object_ontrigger_move_x=ValF(ReadString(_ok.i))
          
        Case "object_ontrigger_move_y"
          world_object()\object_ontrigger_move_y=ValF(ReadString(_ok.i))
          
        Case "object_ontrigger_activate"
          world_object()\object_ontrigger_activate=Val(ReadString(_ok.i))
          
        Case "object_is_trigger"

            world_object()\object_is_trigger=Val(ReadString(_ok.i)) 
     
          
          
          
        Case "object_area_no_limit"
          
      
            world_object()\object_area_no_limit=Val(ReadString(_ok.i))
       
          
          
        Case "object_do_not_show"
          
          
         world_object()\object_do_not_show=Val(ReadString(_ok.i))
          
        Case "object_is_active"

          world_object()\object_is_active=Val(ReadString(_ok.i))
  
            

          
          
          
          
        Case "object_is_player"
          world_object()\object_is_player=Val(ReadString(_ok.i))
          
          
          
        Case "object_move_x"
          world_object()\object_move_x=ValF(ReadString(_ok.i))
          
        Case "object_move_y"
          world_object()\object_move_y=ValF(ReadString(_ok.i))
          
        Case "object_collision"
          world_object()\object_collision=Val(ReadString(_ok.i))          
          
          
        Case "object_internal_name"
          world_object()\object_internal_name=Trim(ReadString(_ok.i))
          
          
        Case "object_is_enemy"
          world_object()\object_is_enemy=Val(ReadString(_ok.i))
          
        Case "object_use_ai"
          E_SETUP_AI(ReadString(_ok.i))
          
        Case "object_is_anim"
          
          
            world_object()\object_is_anim=Val(ReadString(_ok.i))
        
          
          
        Case "object_use_default_direction"
          world_object()\object_use_default_direction=ReadString(_ok.i)
          
          
        Case "object_use_random_angle"
          world_object()\object_use_random_angle=ValF(ReadString(_ok.i))
          
          
        Case "object_random_transparency"
          world_object()\object_random_transparency=Val(ReadString(_ok.i))
          
        Case "object_random_rotate"
          world_object()\object_random_rotate=ValF(ReadString(_ok.i))
          
        Case "object_manual_rotate"
          world_object()\object_manual_rotate=ValF(ReadString(_ok.i))
          
        Case "object_auto_rotate"
          world_object()\object_auto_rotate=ValF(ReadString(_ok.i))
          
          
        Case "object_blink_timer"
          world_object()\object_blink_timer=Val(ReadString(_ok.i))
          
        Case "object_autotransport_x"
          world_object()\object_autotransport_x=ValF(ReadString(_ok.i))
          
        Case "object_autotransport_y"
          world_object()\object_autotransport_y=ValF(ReadString(_ok.i))
          
        Case "object_is_auto_scroll_x"
          world_object()\object_is_auto_scroll_x=ValF(ReadString(_ok.i))
          If  world_object()\object_is_auto_scroll_x<>0
            e_engine\e_world_auto_scroll_x=world_object()\object_is_auto_scroll_x
          EndIf
          
        Case "object_is_auto_scroll_y"
          
          world_object()\object_is_auto_scroll_y=ValF(ReadString(_ok.i))
          If   world_object()\object_is_auto_scroll_y<>0
            e_engine\e_world_auto_scroll_y=world_object()\object_is_auto_scroll_y
          EndIf
          
        Case "object_sound_path"
          world_object()\object_sound_path=Trim(ReadString(_ok.i))
    
              
 
          
          
          
        Case "object_child_total"
          world_object()\object_child_total=Val(ReadString(_ok.i))  ;stores the maximum number of childs generated (up to 128) , used for persistent objects, like spiders , so we have "respawn areas of enemies"
          
          
          
        Case "object_play_sound_on_collision"
       
            world_object()\object_play_sound_on_collision=Val(ReadString(_ok.i))
        
          
          
             
        Case "object_sound_on_collision_path"
              world_object()\object_sound_on_collision_path=Trim(ReadString(_ok.i))
           

          
          
        Case "object_sound_on_random_path"
          world_object()\object_sound_on_random_path=Trim(ReadString(_ok.i))
          
      
         
            
      
          
        Case "object_does_attack"
                world_object()\object_does_attack=Val(ReadString(_ok.i))
   
          
          
          Case "object_ingame_name"
              world_object()\object_ingame_name=ReadString(_ok.i)
          
          
        Case "object_sound_play_random"
          world_object()\object_sound_play_random=Val(ReadString(_ok.i))
          
        Case "object_sound_volume"
          
          world_object()\object_sound_volume=Val(ReadString(_ok.i))
       
      
          
          
        Case "object_collision_transparency"
          world_object()\object_collision_transparency=Val(ReadString(_ok.i))
          
          
        Case "object_play_sound_on_move"
          
      
          world_object()\object_play_sound_on_move=Val(ReadString(_ok.i))
       
        
        Case "object_sound_on_move_path"
          
         world_object()\object_sound_on_move_path=Trim(ReadString(_ok.i))
        

    
          
        Case "object_collision_tractor_object"
          world_object()\object_collision_tractor_object=Val(ReadString(_ok.i))
          
        Case "object_use_random_alternative_gfx"
          world_object()\object_use_random_alternative_gfx=Val(ReadString(_ok.i))   ;we fix this here, not changed in realtime... :)  , maximum: 0....3 !!!!
          
        Case "object_alternative_gfx_default_ai42"
          world_object()\object_alternative_gfx_default_ai42=ReadString(_ok.i)
         
        Case "object_alternative_random_gfx_ai0"
          world_object()\object_alternative_random_gfx_ai0=ReadString(_ok.i)
          
        Case "object_alternative_random_gfx_ai1"
          world_object()\object_alternative_random_gfx_ai1=ReadString(_ok.i)
          
        Case "object_alternative_random_gfx_ai2"
          world_object()\object_alternative_random_gfx_ai2=ReadString(_ok.i)
          
        Case "object_alternative_random_gfx_ai3"
          world_object()\object_alternative_random_gfx_ai3=ReadString(_ok.i)
          
           Case "object_alternative_random_gfx_ai4"
             world_object()\object_alternative_random_gfx_ai4=ReadString(_ok.i)
             
              Case "object_alternative_random_gfx_ai5"
                world_object()\object_alternative_random_gfx_ai5=ReadString(_ok.i)
                
                 Case "object_alternative_random_gfx_ai6"
          world_object()\object_alternative_random_gfx_ai6=ReadString(_ok.i)
          
        Case "object_change_on_collision"
          world_object()\object_change_on_collision=Val(ReadString(_ok.i))
     
        
          
          
          
        Case "object_auto_layer"
          world_object()\object_auto_layer=Val(ReadString(_ok.i))
          
        Case "object_change_on_random"
          
          world_object()\object_change_on_random=Val(ReadString(_ok.i))
          ;value>0 will use this, trigger is 1, 
          
          
       
          
          
        Case "object_sound_on_rotate_path"
          
     world_object()\object_sound_on_rotate_path=Trim(ReadString(_ok.i))
            
   
            ;value <>0 = sound, value =0 no sound!
     
            
        Case "object_sound_on_create_path"
          world_object()\object_sound_on_create_path=Trim(ReadString(_ok.i))

          
          Case "object_create_child_sound"
     
          
          world_object()\object_create_child_sound=Trim(ReadString(_ok.i))
          
          
        Case "object_is_key_for_gate"
          world_object()\object_is_key_for_gate=Trim(ReadString(_ok.i))
          
          
        Case "object_auto_move_x"
          world_object()\object_auto_move_x=ValF(ReadString(_ok.i))
          
        Case "object_auto_move_y"
          world_object()\object_auto_move_y=ValF(ReadString(_ok.i))
          
          
        Case "object_life_time"  ;used for objects with limited lifetime, used for just in time created objects(because of the timer)
          world_object()\object_life_time=Val(ReadString(_ok.i))
           
         
        Case "object_hp"
          world_object()\object_hp=Val(ReadString(_ok.i))
          world_object()\object_hp_max=world_object()\object_hp  ;store it
          
        Case "object_defence"
          world_object()\object_defence=Val(ReadString(_ok.i))
          
        Case "object_attack"
          world_object()\object_attack=Val(ReadString(_ok.i))
          
        Case "object_level"
          world_object()\object_level=Val(ReadString(_ok.i))
        Case "object_create_child"
          world_object()\object_create_child=Val(ReadString(_ok.i))
        Case "object_child0_gfx_ai42"
          world_object()\object_child0_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child1_gfx_ai42"
          world_object()\object_child1_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child2_gfx_ai42"
          world_object()\object_child2_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child3_gfx_ai42"
          world_object()\object_child3_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child4_gfx_ai42"
          world_object()\object_child4_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child5_gfx_ai42"
          world_object()\object_child5_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child6_gfx_ai42"
          world_object()\object_child6_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child7_gfx_ai42"
          world_object()\object_child7_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child8_gfx_ai42"
          world_object()\object_child8_gfx_ai42=Trim(ReadString(_ok.i))
        Case "object_child9_gfx_ai42"
          world_object()\object_child9_gfx_ai42=Trim(ReadString(_ok.i))
             
        Case "object_create_child_random"
          world_object()\object_create_child_random=Val(ReadString(_ok.i))
          
        Case "object_sound_is_boss"
               world_object()\object_sound_is_boss=Val(ReadString(_ok.i))
          
        Case "object_do_not_remove"
          
          
 
          
        Case "object_inventory_name"
          world_object()\object_inventory_name=ReadString(_ok.i)
          
        Case "object_random_size_factor"
          world_object()\object_random_size_factor=ValF(ReadString(_ok.i))
          
        Case "object_random_size_change"
          world_object()\object_random_size_change=Val(ReadString(_ok.i))
          
  
          
          
        Case "object_target_on_player"
          
          
          world_object()\object_target_on_player=Val(ReadString(_ok.i))
         
           
       
        Case "object_collision_static_id"
          world_object()\object_collision_static_id=Val(ReadString(_ok.i))
          world_object()\object_collision_static_id_backup=world_object()\object_collision_static_id  ;if we change the id we can go back to origin
          
        Case "object_collision_static_alternative_id"
          world_object()\ object_collision_static_alternative_id=Val(ReadString(_ok.i))
          
          
        Case "object_internal_name_alternative"
          world_object()\object_internal_name_alternative=Trim(ReadString(_ok.i))
          
         
        Case "object_use_parent_direction"
       
            world_object()\object_use_parent_direction=Val(ReadString(_ok.i))
       
        Case "object_set_child_direction"
               world_object()\object_set_child_direction=Val(ReadString(_ok.i))
         
          
        Case "object_random_hide_away"
          world_object()\object_random_hide_away=Val(ReadString(_ok.i))
          
        Case "object_random_hide_away_sound"
           world_object()\object_random_hide_away_sound=Trim(ReadString(_ok.i))
                     

          
               
     
        
      Case "object_sound_on_activate_path"
        
         world_object()\object_sound_on_activate_path=Trim(ReadString(_ok.i))
         
       Case "object_sound_on_activate_volume"
         world_object()\object_sound_on_activate_volume=Val(ReadString(_ok.i))
          
          
        Case "object_play_sound_on_activate"
          
            world_object()\object_play_sound_on_activate=Val(ReadString(_ok.i))
         
         
        
        Case "object_random_hide_away_sound_volume"
          world_object()\object_random_hide_away_sound_volume=Val(ReadString(_ok.i))
          
        Case "object_hide_away_layer"
          world_object()\object_hide_away_layer=Val(ReadString(_ok.i))
          
        Case "object_hide_away_time_out"
          world_object()\object_hide_away_time_out=Val(ReadString(_ok.i))
          
        Case "object_remove_with_boss"
         
            world_object()\object_remove_with_boss=Val(ReadString(_ok.i))
     
          
        Case "object_is_boss"
       
            world_object()\object_is_boss=Val(ReadString(_ok.i))
     
          
        Case "object_hide_away_pause"
          world_object()\object_hide_away_pause=Val(ReadString(_ok.i))
       
 
        Case "object_fade_in_on_creation"
  
            world_object()\object_fade_in_on_creation=Val(ReadString(_ok.i))
 
          
        Case "object_fade_in_on_creation_step"
          world_object()\object_fade_in_on_creation_step=ValF(ReadString(_ok.i))
          
          
        Case "object_use_day_night_change"
                  
            world_object()\object_use_day_night_change=Val(ReadString(_ok.i))
        
          

          
        Case "object_is_light"
        
            world_object()\object_is_light=Val(ReadString(_ok.i))
     
          
        Case "object_light_color_r"
          world_object()\object_light_color_r=Abs(Val(ReadString(_ok.i)))
          
        Case "object_light_color_g"
          world_object()\object_light_color_g=Abs(Val(ReadString(_ok.i)))
          
        Case "object_light_color_b"
          world_object()\object_light_color_b=Abs(Val(ReadString(_ok.i)))
          
        Case "object_light_intensity"
          world_object()\object_light_intensity=Abs(Val(ReadString(_ok.i)))
          
          
          
        Case "object_light_size_factor"
          
          world_object()\object_light_size_factor=Abs(Val(ReadString(_ok.i)))
       
          
              
          
        Case "object_remove_after_collison"
        
            world_object()\object_remove_after_collison=Val(ReadString(_ok.i))
            
      
          
          
        Case "object_remove_after_change"
    
            world_object()\object_remove_after_change=Val(ReadString(_ok.i))
            
      
          
        Case "object_inactive_after_change"
          
            world_object()\object_inactive_after_change=Val(ReadString(_ok.i))
      
      
          
        Case "object_inactive_after_collision"
              world_object()\object_inactive_after_collision=Val(ReadString(_ok.i))
      
        Case "object_no_collision_after_collision"
          world_object()\object_no_collision_after_collision=Val(ReadString(_ok.i))
          
        Case "object_do_not_save_after_change"
            world_object()\object_do_not_save_after_change=Val(ReadString(_ok.i))
     
          
          
        Case "object_remove_after_fade_out"
             world_object()\object_remove_after_fade_out=Val(ReadString(_ok.i))
         
          
        Case "object_remove_after_timer"
                world_object()\object_remove_after_timer=Val(ReadString(_ok.i))
    
        Case "object_save_map_on_collision"
               world_object()\object_save_map_on_collision=Val(ReadString(_ok.i))
         
          
   
        Case "object_reactivation_timer_ms"
          world_object()\object_reactivation_timer_ms=Val(ReadString(_ok.i))
          
          
        Case "object_create_child_sound_volume"
          world_object()\object_create_child_sound_volume=Val(ReadString(_ok.i))
          
          
        Case "object_change_on_dead"
              world_object()\object_change_on_dead=Val(ReadString(_ok.i))
      
          
        Case "object_change_on_life_time_is_over"
             world_object()\object_change_on_life_time_is_over=Val(ReadString(_ok.i))
   
          
        Case "object_use_map_ground"
          
            world_object()\object_use_map_ground=Val(ReadString(_ok.i))
      
          
          
          Case "object_is_map_ground"
            
            world_object()\object_is_map_ground=Val(ReadString(_ok.i))
        
          
        Case "object_is_loot"
          
      
          world_object()\object_is_loot=Val(ReadString(_ok.i))
         
          
        Case "object_layer_add"
          world_object()\object_layer_add=Val(ReadString(_ok.i))

           
           
         Case "object_set_night"
           
          
              world_object()\object_set_night=Val(ReadString(_ok.i))
         
           
           
             
         Case "object_set_day"
        
              world_object()\object_set_day=Val(ReadString(_ok.i))
        
            
          Case "object_spawn_random_x"
            world_object()\object_spawn_random_x=Val(ReadString(_ok.i))
            
            
          Case "object_spawn_random_y"
            world_object()\object_spawn_random_y=Val(ReadString(_ok.i))
            
          Case "object_fade_bounce"
            world_object()\object_fade_bounce=ValF(ReadString(_ok.i))
            
            
          Case "object_is_NESW"
            
            
        world_object()\object_is_NESW=Val(ReadString(_ok.i))
              
       
            
            
          Case "object_inactive_after_timer"
            
 
            world_object()\object_inactive_after_timer=Val(ReadString(_ok.i))
    
            
            
      
            
          Case "object_allert_on_player"
              
       
              world_object()\object_allert_on_player=Val(ReadString(_ok.i))
        
          Case "object_xp_on_remove"
            world_object()\object_xp_on_remove=Val(ReadString(_ok.i))
           
            
          Case "object_sound_play_on_rotate"
           
     
            world_object()\object_sound_play_on_rotate=Val(ReadString(_ok.i))
       
            
            
          Case "object_no_weapon_interaction"
            
            world_object()\object_no_weapon_interaction=Val(ReadString(_ok.i))
   
          
          
        Case "object_weapon_remove_after_hit"
          
     
            world_object()\object_weapon_remove_after_hit=Val(ReadString(_ok.i))

          
          
        Case "object_fight_effect_gfx_path"
          world_object()\object_fight_effect_gfx_path=Trim(ReadString(_ok.i))
          
        Case "object_use_fight_effect"
          
    
          world_object()\object_use_fight_effect=Val(ReadString(_ok.i))
     
          
        Case "object_allert_overide_timer"
          world_object()\object_allert_overide_timer=Val(ReadString(_ok.i))
          
        Case "object_play_sound_on_create_child"
          
       
            world_object()\object_play_sound_on_create_child=Val(ReadString(_ok.i))
   
          
        Case "object_play_sound_on_create"
          
        
            world_object()\object_play_sound_on_create=Val(ReadString(_ok.i))
     
          
          
        Case "object_play_sound_on_change"
          
         
            world_object()\object_play_sound_on_change=Val(ReadString(_ok.i))
     
          
          
          
        Case "object_alternative_create_sound_path"
        world_object()\object_alternative_create_sound_path=Trim(ReadString(_ok.i))
          
        
      Case "object_sound_on_talk_path"
        world_object()\object_sound_on_talk_path=Trim(ReadString(_ok.i))
          
  

          
          
        Case "object_life_timer_on_collision"
          world_object()\object_life_timer_on_collision=Val(ReadString(_ok.i))
          
        Case "object_life_timer_on_activation"
          world_object()\object_life_timer_on_activation=Val(ReadString(_ok.i))
          
        Case "object_random_rotate_on_activation"
          world_object()\object_random_rotate_on_activation=Val(ReadString(_ok.i))
          
          
        Case "object_boss_music_mode"
                  
       
            world_object()\object_boss_music_mode=Val(ReadString(_ok.i))
            
        
          
        Case "object_boss_music_volume"
          world_object()\object_boss_music_volume=Val(ReadString(_ok.i))
          
            
          
        Case "object_stop_all_music"
       
              world_object()\object_stop_all_music=Val(ReadString(_ok.i))
                
          
        Case "object_hp_factor"
          world_object()\object_hp_factor=Val(ReadString(_ok.i))
          
          
        Case "object_shadow_use_perspective"
         
            world_object()\object_shadow_use_perspective=Val(ReadString(_ok.i))
        
        Case "object_shadow_gfx_path"
          world_object()\object_shadow_gfx_path=Trim(ReadString(_ok.i))
          
 
      
        
          
        Case "object_ignore_weapon_on_hide"

            world_object()\object_ignore_weapon_on_hide=Val(ReadString(_ok.i))
        
        Case "object_no_collision_on_hide"
  
            world_object()\object_no_collision_on_hide=Val(ReadString(_ok.i))
    
        Case "object_is_weapon"
          world_object()\object_is_weapon=Val(ReadString(_ok.i))
        
   
          
        Case "object_create_no_child_if_hide_away"

            world_object()\object_create_no_child_if_hide_away=Val(ReadString(_ok.i))
        
          
        Case "object_restore_health_if_hide_away"
          world_object()\object_restore_health_if_hide_away=ValF(ReadString(_ok.i))
          
          
          
        Case "object_resize_per_tick"
          world_object()\object_resize_per_tick=ValF(ReadString(_ok.i))
          
        Case "object_remove_after_full_resize"
       
            world_object()\object_remove_after_full_resize=Val(ReadString(_ok.i))
        
          
     
    
          
        Case "object_remove_if_out_of_area"
          
     
            world_object()\object_remove_if_out_of_area=Val(ReadString(_ok.i))
      
          
          
          
        Case "object_restore_health_if_out_of_area"
          world_object()\object_restore_health_if_out_of_area=0
          world_object()\object_restore_health_if_out_of_area= ValF(ReadString(_ok.i))
          
        Case "object_restore_health_if_not_allert"
          
          world_object()\object_restore_health_if_not_allert=ValF(ReadString(_ok.i))
         
          
          
        Case "object_is_quiet"
          
    
          
        Case "object_slippery_mode"
               world_object()\object_slippery_mode=Val(ReadString(_ok.i))
     
        Case "object_is_arena_object"
        
            world_object()\object_is_arena_object=Val(ReadString(_ok.i))
       
          
       

        Case "object_play_sound_on_treasure"
            world_object()\object_play_sound_on_treasure=Val(ReadString(_ok.i))
            
        Case "object_sound_on_treasure_found_path"
          
          world_object()\object_sound_on_treasure_found_path=Trim(ReadString(_ok.i))
  
          
          
          
        Case "object_allert_on_treasure"
     
            world_object()\object_allert_on_treasure=Val(ReadString(_ok.i))
       
          
          
        Case "object_activate_on_inventory"
          world_object()\object_activate_on_inventory=Trim(ReadString(_ok.i))
          
          
        Case "object_spawn_at_player_if_out_of_area"
       
            world_object()\object_spawn_at_player_if_out_of_area=Val(ReadString(_ok.i))
       
          
        Case "object_respawn_timer"
          world_object()\object_respawn_timer=Val(ReadString(_ok.i))
          
        Case "object_collision_ignore_player"
                  world_object()\object_collision_ignore_player=Val(ReadString(_ok.i))
        
          
          
          
        Case "object_is_attraction"
    
            world_object()\object_is_attraction=Val(ReadString(_ok.i))
      
          
          
        Case "object_attraction_pick_up"
 
            world_object()\object_attraction_pick_up=Val(ReadString(_ok.i))

    
          

          
        Case "object_resize_per_percent_x"
          world_object()\object_resize_per_percent_x=ValF(ReadString(_ok.i))/100
          
          
        Case "object_resize_per_percent_y"
          world_object()\object_resize_per_percent_y=ValF(ReadString(_ok.i))/100
          
          
        Case "object_resize_pixel_x"
          world_object()\object_resize_pixel_x=ValF(ReadString(_ok.i))
          
          
        Case "object_resize_pixel_y"
          world_object()\object_resize_pixel_y=ValF(ReadString(_ok.i))
          
       
   
          
          
        Case "object_do_not_save_after_collision"
          If Val(ReadString(_ok.i))>0
          world_object()\object_do_not_save_after_collision=#True  
        EndIf
        
      Case "object_fade_out_on_collision"
        world_object()\object_fade_out_on_collision=ValF(ReadString(_ok.i))
        
      Case "object_move_on_collision_x"
        world_object()\object_move_on_collision_x=ValF(ReadString(_ok.i))
        
        
      Case "object_move_on_collision_y"
          world_object()\object_move_on_collision_y=ValF(ReadString(_ok.i))
        
      Case "object_change_move_after_collision"
             world_object()\object_change_move_after_collision=Val(ReadString(_ok.i))
   
        
            Case "object_activate_on_companion"
                        world_object()\object_activate_on_companion=#True  
        
            
                   
        Case "object_force_own_layer"
          world_object()\object_force_own_layer=Val(ReadString(_ok.i))
          
        Case "object_auto_layer"
          world_object()\object_auto_layer=Val(ReadString(_ok.i))
          
        Case "object_set_night_intensity"
          world_object()\object_set_night_intensity=Abs(ValF(ReadString(_ok.i)))
        
        Case "object_set_day_intensity"
           world_object()\object_set_day_intensity=Abs(ValF(ReadString(_ok.i)))
           


               
             Case "object_emit_on_move"
               
               If Val(ReadString(_ok.i))>0
                 world_object()\object_emit_on_move=#True  
             EndIf
             
             
           Case "object_emit_on_move_ai42"
             world_object()\object_emit_on_move_ai42=Trim(ReadString(_ok.i))
             
           Case "object_emit_on_move_random"
             world_object()\object_emit_on_move_random=Val(ReadString(_ok.i))
             
           Case "object_set_day_night_change_ai42"
             world_object()\object_set_day_night_change_ai42=Trim(ReadString(_ok.i))
             
           Case "object_NPC_switch_map_on_talk"
            
             world_object()\object_NPC_switch_map_on_talk=Val(ReadString(_ok.i))
          
           
         Case "object_NPC_switch_map_on_talk_file"
           world_object()\object_NPC_switch_map_on_talk_file=Trim(ReadString(_ok.i))
           
         Case "object_set_emitter_day_ai42"
           world_object()\object_set_emitter_day_ai42=Trim(ReadString(_ok.i))
           
         Case "object_set_emitter_night_ai42"
           world_object()\object_set_emitter_night_ai42=Trim(ReadString(_ok.i))
           
           
         Case "object_set_day_night_emitter_random"
           world_object()\object_set_day_night_emitter_random=Val(ReadString(_ok.i))
           
           
         Case "object_deactivate_on_day"
           world_object()\object_deactivate_on_day=Val(ReadString(_ok.i))
           
         
           
         Case "object_deactivate_on_night"
           world_object()\object_deactivate_on_night=Val(ReadString(_ok.i))
          
           
         Case "object_activate_on_day"
           world_object()\object_activate_on_day=Val(ReadString(_ok.i))
           
           
           
           
         Case "object_activate_on_night"
           world_object()\object_activate_on_night=Val(ReadString(_ok.i))
           
          
         
           
         Case "object_effect_on_player_collision"
    
           world_object()\object_effect_on_player_collision=Val(ReadString(_ok.i))
     
         
       Case "object_remove_after_effect_on_player"
       
             world_object()\object_remove_after_effect_on_player=Val(ReadString(_ok.i)) 
    
         
         
       Case "object_use_effect_on_percent_value"
         world_object()\object_use_effect_on_percent_value=ValF(ReadString(_ok.i))/100
      
       Case "object_change_value_per_percent"
         world_object()\object_change_value_per_percent=ValF(ReadString(_ok.i))
         
       Case "object_remove_after_dead"
        If Val(ReadString(_ok.i))>0
          world_object()\object_remove_after_dead=#True
        EndIf
        
      Case "object_remove_on_day"
        If Val(ReadString(_ok.i))>0
        world_object()\object_remove_on_day=#True  
      EndIf
      
      Case "object_remove_on_night"
        If Val(ReadString(_ok.i))>0
        world_object()\object_remove_on_night=#True  
        EndIf
        
      Case "object_remove_after_last_anim_frame"
        If Val(ReadString(_ok.i))>0
        world_object()\object_remove_after_last_anim_frame=#True  
        EndIf
        
      Case "object_create_on_level_up"
        If Val(ReadString(_ok.i))>0
          world_object()\object_create_on_level_up=#True  
        EndIf
        
      Case "object_child_on_level_up_ai42"
        world_object()\object_child_on_level_up_ai42=Trim(ReadString(_ok.i))
        
      Case "object_deactivate_use_alternative_gfx"
        If Val(ReadString(_ok.i))>0
        world_object()\object_deactivate_use_alternative_gfx=#True  
        EndIf
        
      Case "object_change_on_last_frame"
        If Val(ReadString(_ok.i))>0
        world_object()\object_change_on_last_frame=#True  
        EndIf
        
 
      Case "object_use_spawn_offset"
        If Val(ReadString(_ok.i))>0
        world_object()\object_use_spawn_offset=#True  
        EndIf
        
        
      Case "object_map_timer_active_on_talk"
        world_object()\object_NPC_map_timer_active_on_talk=Val(ReadString(_ok.i))
        
      Case "object_add_timer_to_map"
        world_object()\object_add_timer_to_map=Val(ReadString(_ok.i))
             
      Case "object_anim_no_auto_align"
        world_object()\object_anim_no_auto_align=Val(ReadString(_ok.i))
        
        
      Case "object_use_virtual_buffer"
        world_object()\object_use_virtual_buffer=Val(ReadString(_ok.i))
     
        
     
        
      Case "object_move_x_only"
        If Val(ReadString(_ok.i))>0
        world_object()\object_move_x_only=#True  
        EndIf
        
        
      Case "object_move_y_only"
         If Val(ReadString(_ok.i))>0
        world_object()\object_move_y_only=#True  
      EndIf
      
      
     
      
    Case "object_energy"
      world_object()\object_energy=Val(ReadString(_ok.i))
      
    Case "object_use_energy_status"
      If Val(ReadString(_ok.i))>0
        world_object()\object_use_energy_status=#True
      EndIf
      
    Case "object_use_position_on_raster"
      If Val(ReadString(_ok.i))>0
      world_object()\object_use_position_on_raster=#True  
      EndIf
      
    Case "object_use_timed_action"
      If Val(ReadString(_ok.i))>0
      world_object()\object_use_timed_action=#True  
      EndIf
      
     
    Case "object_use_gravity"
      
      world_object()\object_use_gravity=Val(ReadString(_ok.i))
    
      
      
    Case "object_can_jump"
      If Val(ReadString(_ok.i))>0
      world_object()\object_can_jump=#True  
    EndIf
    
  Case "object_jump_size"
    world_object()\object_jump_size=ValF(ReadString(_ok.i))
    
  Case "object_jump_step"
    world_object()\object_jump_step=ValF(ReadString(_ok.i))
    
  Case "object_use_player_direction_x"
    If Val(ReadString(_ok.i))>0
      world_object()\object_use_player_direction_x=#True  
    EndIf
    
    
  Case "object_use_player_direction_y"
     If Val(ReadString(_ok.i))>0
    world_object()\object_use_player_direction_y=#True
    EndIf
    
 
    
  Case "object_use_random_start_direction"
    If Val(ReadString(_ok.i))>0
    world_object()\object_use_random_start_direction=#True  
    EndIf
    

    
  Case "object_sound_on_jump_paths"
    world_object()\object_sound_on_jump_paths=Trim(ReadString(_ok.i))
   
  Case "object_play_sound_on_jump"
    If Val(ReadString(_ok.i))>0
    world_object()\object_play_sound_on_jump=#True  
    EndIf
    
  Case "object_sound_on_jump_volume"
    world_object()\object_sound_on_jump_volume=Val(ReadString(_ok.i))
    
    
  Case "object_change_direction_on_random"
  
      world_object()\object_change_direction_on_random=Val(ReadString(_ok.i))
    
    
  Case "object_random_change_direction_x"
    world_object()\object_random_change_direction_x=Val(ReadString(_ok.i))
    
    
  Case "object_random_change_direction_y"
     world_object()\object_random_change_direction_y=Val(ReadString(_ok.i))
     

     
   Case "object_use_own_trigger_zone"
     If Val(ReadString(_ok.i))>0
     world_object()\object_use_own_trigger_zone=#True  
     EndIf
     
     
   Case "object_own_trigger_zone_w"
     world_object()\object_own_trigger_zone_w=Abs(ValF(ReadString(_ok.i)))
     
      Case "object_own_trigger_zone_h"
        world_object()\object_own_trigger_zone_h=Abs(ValF(ReadString(_ok.i)))
        
      Case "object_area_loop_vertical"
        If Val(ReadString(_ok.i))>0
        world_object()\object_area_loop_vertical=#True  
        EndIf
        
      Case "object_area_loop_horizont"
        If Val(ReadString(_ok.i))>0
        world_object()\object_area_loop_horizont=#True  
        EndIf
        
      Case "object_show_coordinates"
        If Val(ReadString(_ok.i))>0
           world_object()\object_show_coordinates=#True  
        EndIf
        
      Case "object_reset_position_on_timer"
        If Val(ReadString(_ok.i))>0
        world_object()\object_reset_position_on_timer=#True  
        EndIf
        
        
      Case "object_reset_position_time_ms"
        world_object()\object_reset_position_time_ms=Val(ReadString(_ok.i))
        
      Case "object_emitter_max_objects"
        world_object()\object_emitter_max_objects=Val(ReadString(_ok.i))
        
      Case "object_emitter_use_max_objects"
        If Val(ReadString(_ok.i))>0
        world_object()\object_emitter_use_max_objects=#True  
        EndIf
        
      Case "object_emitter_max_objects_random"
        world_object()\object_emitter_max_objects_random=Val(ReadString(_ok.i))
        
           Case "object_emit_object_ai42_default"
             world_object()\object_emit_object_ai42_default=Trim(ReadString(_ok.i))
             
           Case "object_use_transparency_back_up"
             If Val(ReadString(_ok.i))>0
             world_object()\object_use_transparency_back_up=#True  
             EndIf
             
         
             
           Case "object_use_attack_anim"
             If Val(ReadString(_ok.i))>0
             world_object()\object_use_attack_anim=#True  
             EndIf
     
             
           Case "object_turn_on_left_screen"
          world_object()\object_turn_on_left_screen=Val(ReadString(_ok.i))
           
         Case "object_use_position_back_up"
           If Val(ReadString(_ok.i))>0
           world_object()\object_use_position_back_up=#True  
         EndIf
             
         
       Case "object_check_if_player_on_top"
       
         world_object()\object_check_if_player_on_top=Val(ReadString(_ok.i))
       

            Case "object_anim_start_on_collison"
             
              world_object()\object_anim_start_on_collison=Val(ReadString(_ok.i))
            
              
            Case "object_no_interaction_on_enemy"
           
              world_object()\object_no_interaction_on_enemy=Val(ReadString(_ok.i))
            
              
              
            Case "object_emit_on_timer"
          world_object()\object_emit_on_timer=Val(ReadString(_ok.i))
            Case "object_emit_timer"
              world_object()\object_emit_timer=Val(ReadString(_ok.i))
              
            Case "object_collision_flip_flop"
              If Val(ReadString(_ok.i))>0
              world_object()\object_collision_flip_flop=#True  
              EndIf
              
            Case "object_backup_size"
              If Val(ReadString(_ok.i))>0
                world_object()\object_backup_size=#True
              
              EndIf
              
            Case "object_play_sound_once"
              
              If Val(ReadString(_ok.i))>0
              world_object()\object_play_sound_once=#True  
              EndIf
              
              
            Case "object_activate_map_scroll"
              If Val(ReadString(_ok.i))>0
              world_object()\object_activate_map_scroll=#True  
              EndIf
              
            Case "object_deactivate_map_scroll"
              If Val(ReadString(_ok.i))>0
              world_object()\object_deactivate_map_scroll=#True  
              EndIf
              
            Case "object_do_not_save_after_inactive"
              If Val(ReadString(_ok.i))>0
              world_object()\object_do_not_save_after_inactive=#True  
              EndIf
              
              
            Case "object_use_status_controller"
              If Val(ReadString(_ok.i))>0
              world_object()\object_use_status_controller=#True  
              EndIf
              
              
            Case "object_static_move"
              If Val(ReadString(_ok.i))>0
              world_object()\object_static_move=#True  
              EndIf
              
            Case "object_use_stamp"
             
              world_object()\object_use_stamp=Val(ReadString(_ok.i))
            
          Case "object_stamp_buffer_path"
            world_object()\object_stamp_buffer_path=ReadString(_ok.i)
              
          Case "object_use_life_time_per_pixel"
      
            world_object()\object_use_life_time_per_pixel=Val(ReadString(_ok.i))
     
            
          Case "object_life_time_pixel_y"
            world_object()\object_life_time_pixel_y=ValF(ReadString(_ok.i))
            
            
          Case "object_life_time_pixel_x"
             world_object()\object_life_time_pixel_x=ValF(ReadString(_ok.i))
             
           Case "object_reset_position_on_pixel_count"
            
             world_object()\object_reset_position_on_pixel_count=Val(ReadString(_ok.i))
     
             
           Case "object_remove_after_pixel_count"
  
             world_object()\object_remove_after_pixel_count=Val(ReadString(_ok.i))
     
             
           Case "object_anim_loop"
         
             world_object()\object_anim_loop=Val(ReadString(_ok.i)) 
        
             
           Case "object_sound_on_move_volume"
             world_object()\object_sound_on_move_volume=Val(ReadString(_ok.i))
             
           Case "object_sound_on_create_volume"
             world_object()\object_sound_on_create_volume=Val(ReadString(_ok.i))

           Case "object_sound_on_random_volume"
             world_object()\object_sound_on_random_volume=Val(ReadString(_ok.i))
             
           Case "object_play_sound_on_random"
          
               world_object()\object_play_sound_on_random=Val(ReadString(_ok.i))
           
             
           Case "object_stop_after_pixel_count"
         
             world_object()\object_stop_after_pixel_count=Val(ReadString(_ok.i))
      
             
           Case "object_activate_global_flash"
       
             world_object()\object_activate_global_flash=Val(ReadString(_ok.i))
        
           Case "object_random_life_time"
             world_object()\object_random_life_time=Val(ReadString(_ok.i))
             
           Case "object_random_transparency_on_start"
             world_object()\object_random_transparency_on_start=Random(Val(ReadString(_ok.i)))
             
           Case "object_use_random_transparency_on_start"
        
             world_object()\object_use_random_transparency_on_start=Val(ReadString(_ok.i))
        
             
             Case "object_stream_sound_on_create"
               
               world_object()\object_stream_sound_on_create=Val(ReadString(_ok.i))
          
               
             Case "object_stream_sound_move"
               
               world_object()\object_stream_sound_on_move=Val(ReadString(_ok.i))
         
               
             Case "object_use_own_color"
             
               world_object()\object_use_own_color=Val(ReadString(_ok.i))
          
               
             Case "object_color_red"
               world_object()\object_color_red=Abs(Val(ReadString(_ok.i)))
               
                 Case "object_color_green"
                   world_object()\object_color_green=Abs(Val(ReadString(_ok.i)))
                   
                     Case "object_color_blue"
             world_object()\object_color_blue=Abs(Val(ReadString(_ok.i)))
             
           Case "object_change_direction_x_on_max"
   
               world_object()\object_change_direction_x_on_max=Val(ReadString(_ok.i))

             
             
                 Case "object_change_direction_y_on_max"
        
               world_object()\object_change_direction_y_on_max=Val(ReadString(_ok.i))
        
             
             
           Case "object_no_flash_interaction"
            
             world_object()\object_no_flash_interaction=Val(ReadString(_ok.i))
     
             
           Case "object_sound_on_collision_volume"
             world_object()\object_sound_on_collision_volume=Val(ReadString(_ok.i))
             
           Case "object_gfx_set_w_h"
           
               world_object()\object_gfx_set_w_h=Val(ReadString(_ok.i))
       
             
           Case "object_gfx_h"
             world_object()\object_gfx_h=ValF(ReadString(_ok.i))
             
           Case "object_gfx_w"
             world_object()\object_gfx_w=ValF(ReadString(_ok.i))
             
             
           Case "object_is_global_light"
           
             world_object()\object_is_global_light=Val(ReadString(_ok.i))
        
             
             
           Case "object_global_light_red"
             world_object()\object_global_light_red=Abs(Val(ReadString(_ok.i)))
             
             Case "object_global_light_green"
             world_object()\object_global_light_green=Abs(Val(ReadString(_ok.i)))
           Case "object_global_light_blue"
             world_object()\object_global_light_blue=Abs(Val(ReadString(_ok.i)))
             
           Case "object_global_light_intensity"
             world_object()\object_global_light_intensity=Abs(Val(ReadString(_ok.i)))
             
           Case "object_no_global_light_interaction"
    
             world_object()\object_no_global_light_interaction=Val(ReadString(_ok.i))
       
             
           Case "object_is_global_light_on_collision"
       
             world_object()\object_is_global_light_on_collision=Val(ReadString(_ok.i))
          
             
           Case "object_use_random_start_speed_x"
                     world_object()\object_use_random_start_speed_x=Val(ReadString(_ok.i))
             
             
           Case "object_use_random_start_speed_y"
             
             world_object()\object_use_random_start_speed_y=Val(ReadString(_ok.i))
            
             
           Case "object_random_start_speed_x"
             world_object()\object_random_start_speed_x=Val(ReadString(_ok.i))
             
             Case "object_random_start_speed_y"
               world_object()\object_random_start_speed_y=Val(ReadString(_ok.i))
               
             Case "object_reset_position_on_fade_out"
            
               world_object()\object_reset_position_on_fade_out=Val(ReadString(_ok.i))
            
               
               
             Case "object_use_random_color_RGB"
             
               world_object()\object_use_random_color_RGB=Val(ReadString(_ok.i)) 
         
             Case "object_boss_music_path"
               world_object()\object_boss_music_path=ReadString(_ok.i)
               
             Case "object_use_random_start_direction_x"
     
               world_object()\object_use_random_start_direction_x=Val(ReadString(_ok.i))
       
             
             Case "object_use_random_start_direction_y"
               
               world_object()\object_use_random_start_direction_y=Val(ReadString(_ok.i))
            
             Case "object_start_angle"
               world_object()\object_start_angle=Val(ReadString(_ok.i))
               
             Case "object_speed_change_x"
               world_object()\object_speed_change_x=ValF(ReadString(_ok.i))
               
             Case "object_speed_change_y"
               world_object()\object_speed_change_y=ValF(ReadString(_ok.i))
               
             Case "object_use_speed_change"
               world_object()\object_use_speed_change=Val(ReadString(_ok.i))
               
             Case "object_change_after_pixel_count"
               world_object()\object_change_after_pixel_count=Val(ReadString(_ok.i))
               
               Case "object_show_hit_effect"
                 world_object()\object_show_hit_effect=Val(ReadString(_ok.i))
                 
               Case "object_hit_effect_path"
                 world_object()\object_hit_effect_path=Trim(ReadString(_ok.i))
                 
               Case "object_jump_velocity"
                 world_object()\object_jump_velocity=ValF(ReadString(_ok.i))
                 
               Case "object_jump_velocity_auto"
                 world_object()\object_jump_velocity_auto=Val(ReadString(_ok.i))
                 
               Case "object_use_random_jump"
                 world_object()\object_use_random_jump=Val(ReadString(_ok.i))
                 
               Case "object_jump_start_random"
                 world_object()\object_jump_start_random=Val(ReadString(_ok.i))
                 
               Case "object_is_boss_guard"
                 world_object()\object_is_boss_guard=Val(ReadString(_ok.i))
                 
               Case "object_info_text"
                 world_object()\object_info_text=ReadString(_ok.i)
                 
               Case "object_sound_on_allert_path"
                 world_object()\object_sound_on_allert_path=Trim(ReadString(_ok.i))
                 
                 
               Case "object_play_sound_on_allert"
                 world_object()\object_play_sound_on_allert=Val(ReadString(_ok.i))
                 
               Case "object_sound_on_allert_volume"
                 world_object()\object_sound_on_allert_volume=Val(ReadString(_ok.i))
                 
               Case "object_no_enemy_action"
                 world_object()\object_no_enemy_action=Val(ReadString(_ok.i))
                 
               Case "object_deactivate_tractor_if_left_border"
                 world_object()\object_deactivate_tractor_if_left_border=Val(ReadString(_ok.i))
                 
                 
               Case "object_set_player_gravity_off"
                 world_object()\object_set_player_gravity_off=Val(ReadString(_ok.i))
                 
               
                 
               Case "object_ignore_one_key"
                 world_object()\object_ignore_one_key=Val(ReadString(_ok.i))
                 
               Case "object_is_transporter"
                 world_object()\object_is_transporter=Val(ReadString(_ok.i))
                 
               Case "object_stop_move_after_collision"
                 world_object()\object_stop_move_after_collision=Val(ReadString(_ok.i))
                 
               Case "object_turn_on_screen_center"
                 world_object()\object_turn_on_screen_center=Val(ReadString(_ok.i))
                 
               Case "object_spawn_offset_parent_center"
                 world_object()\object_spawn_offset_parent_center=Val(ReadString(_ok.i))
                 
               Case "object_rotate_right"
                 world_object()\object_rotate_right=ValF(ReadString(_ok.i))
                 
                 Case "object_rotate_left"
                   world_object()\object_rotate_left=ValF(ReadString(_ok.i))
                   
                 Case "object_use_rotate_direction"
                   world_object()\object_use_rotate_direction=Val(ReadString(_ok.i))
                                      
                 Case "object_use_swing_rotate"
                   world_object()\object_use_swing_rotate=Val(ReadString(_ok.i))
                   
                 Case "object_sound_on_rotate_volume"
                   world_object()\object_sound_on_rotate_volume=Val(ReadString(_ok.i))
                   
                 Case "object_play_sound_on_rotate"
                   world_object()\object_play_sound_on_rotate=Val(ReadString(_ok.i))
                   
                 Case "object_own_color_intensity"
                   world_object()\object_own_color_intensity=Val(ReadString(_ok.i))
                   
                 Case "object_play_sound_on_talk"
                   world_object()\object_play_sound_on_talk=Val(ReadString(_ok.i))
                   
                 Case "object_sound_on_talk_volume"
                   world_object()\object_sound_on_talk_volume=Val(ReadString(_ok.i))
                   
                 Case "object_shake_world"
                   world_object()\object_shake_world=Val(ReadString(_ok.i))
                   
                 Case "object_stop_if_guard_on_screen"
                   world_object()\object_stop_if_guard_on_screen=Val(ReadString(_ok.i))
                   
                 Case "object_NPC_remove_after_talk"
                   world_object()\object_NPC_remove_after_talk=Val(ReadString(_ok.i))
                   
                 Case "object_emitter_pause_if_idle"
                   world_object()\object_emitter_pause_if_idle=Val(ReadString(_ok.i))
                   
                 Case "object_emit_stop_if_guard_on_screen"
                   world_object()\object_emit_stop_if_guard_on_screen=Val(ReadString(_ok.i))
                   
                 Case "object_use_spawn_destination"
                   world_object()\object_use_spawn_destination=Val(ReadString(_ok.i))
                   
                 Case "object_is_spawn_destination"
                   world_object()\object_is_spawn_destination=Val(ReadString(_ok.i))
                   
                 Case "object_random_spawn_destination"
                   world_object()\object_random_spawn_destination=Val(ReadString(_ok.i))
                   
                 Case "object_use_random_layer"
                   world_object()\object_use_random_layer=Val(ReadString(_ok.i))
                   
                 Case "object_random_layer"
                   world_object()\object_random_layer=Val(ReadString(_ok.i))
                   
                 Case "object_use_creation_counter"
                   world_object()\object_use_creation_counter=Val(ReadString(_ok.i))
                   
                 Case "object_use_global_spawn"
                   world_object()\object_use_global_spawn=Val(ReadString(_ok.i))
                   
                 Case "object_use_status_controller_parent"
                   world_object()\object_use_status_controller_parent=Val(ReadString(_ok.i))
                   
                 Case "object_child_name"
                   world_object()\object_child_name=ReadString(_ok.i)
                   
                 Case "object_no_clear_screen"
                   world_object()\object_no_clear_screen=Val(ReadString(_ok.i))
                   
                 Case "object_random_spawn_positive_only"
                   world_object()\object_random_spawn_positive_only=Val(ReadString(_ok.i))
                   
                 Case "object_no_shake_interaction"
                   world_object()\object_no_shake_interaction=Val(ReadString(_ok.i))
                   
                 Case "object_move_flappy_mode"
                   world_object()\object_move_flappy_mode=Val(ReadString(_ok.i))
                   
                 Case "object_use_air_time_kill"
                   world_object()\object_use_air_time_kill=Val(ReadString(_ok.i))
                   
                 Case "object_hit_box_x"
                   world_object()\object_hit_box_x=Val(ReadString(_ok.i))
                   
                   Case "object_hit_box_y"
                     world_object()\object_hit_box_y=Val(ReadString(_ok.i))
                     
                     Case "object_hit_box_w"
                       world_object()\object_hit_box_w=Val(ReadString(_ok.i))
                       
                       Case "object_hit_box_h"
                         world_object()\object_hit_box_h=Val(ReadString(_ok.i))
                         
                       Case "object_save_map_on_creation"
                         world_object()\object_save_map_on_creation=Val(ReadString(_ok.i))
                         
                       Case "object_glass_effect_grab_size"
                         world_object()\object_glass_effect_grab_size=ValF(ReadString(_ok.i))
                         
                       Case "object_use_glass_effect"
                         world_object()\object_use_glass_effect=Val(ReadString(_ok.i))
                         
                       Case "object_glass_effect_intensity"
                         world_object()\object_glass_effect_intensity=Val(ReadString(_ok.i))
                         
                       Case "object_glass_effect_offset_x"
                         world_object()\object_glass_effect_offset_x=ValF(ReadString(_ok.i))
                         
                         
                       Case "object_glass_effect_offset_y"
                         world_object()\object_glass_effect_offset_y=ValF(ReadString(_ok.i))
                  
                         
                       Case "object_collision_get_dynamic_id"
                         world_object()\object_collision_get_dynamic_id=Val(ReadString(_ok.i))
                         
                       Case "object_use_global_effect"
                          world_object()\object_use_global_effect=Val(ReadString(_ok.i))
                          
                        Case "object_global_effect_ai42"
                          world_object()\object_global_effect_ai42=Trim(ReadString(_ok.i))
                          
                        Case "object_glass_effect_grab_x"
                          world_object()\object_glass_effect_grab_x=ValF(ReadString(_ok.i))
                          
                          Case "object_glass_effect_grab_y"
                            world_object()\object_glass_effect_grab_y=ValF(ReadString(_ok.i))
                            
                          Case "object_stop_move_right_border"
                            world_object()\object_stop_move_right_border=Val(ReadString(_ok.i))
                            
                          Case "object_turn_on_right_border"
                            world_object()\object_turn_on_right_border=Val(ReadString(_ok.i))
                            
                          Case "object_stop_jump_counter"
                            world_object()\object_stop_jump_counter=Val(ReadString(_ok.i))
                            
                          Case "object_emit_on_jump"
                            world_object()\object_emit_on_jump=Val(ReadString(_ok.i))
                            
                          Case "object_emit_object_jump_ai42"
                            world_object()\object_emit_object_jump_ai42=Trim(ReadString(_ok.i))
                            
                          Case "object_emit_jump_value"
                            world_object()\object_emit_jump_value=Val(ReadString(_ok.i))
                            
                          Case "object_use_horizontal_velocity"
                            world_object()\object_use_horizontal_velocity=Val(ReadString(_ok.i))
                            
                          Case "object_velocity_horizontal"
                            world_object()\object_velocity_horizontal=ValF(ReadString(_ok.i))
                            
                          Case "object_velocity_vertical"
                            world_object()\object_velocity_vertical=ValF(ReadString(_ok.i))
                            
                          Case "object_use_vertical_velocity"
                            world_object()\object_use_vertical_velocity=Val(ReadString(_ok.i))
                            
                          Case "object_make_move_timer"
                            world_object()\object_make_move_timer=Val(ReadString(_ok.i))
                            
                          Case "object_use_make_move_timer"
                            world_object()\object_use_make_move_timer=Val(ReadString(_ok.i))
                            
                          Case "object_random_make_move_timer"
                            world_object()\object_random_make_move_timer=Val(ReadString(_ok.i))
                            
                          Case "object_use_blink_timer"
                            world_object()\object_use_blink_timer=Val(ReadString(_ok.i))
                            
                          Case "object_no_horizontal_move_if_falling"
                            world_object()\object_no_horizontal_move_if_falling=Val(ReadString(_ok.i))
                            
                          Case "object_no_siluette"
                            world_object()\object_no_siluette=Val(ReadString(_ok.i))
                            
                          Case "object_full_screen"
                            world_object()\object_full_screen=Val(ReadString(_ok.i))
                            
                          Case "object_in_front_transparency"
                            world_object()\object_in_front_transparency=Val(ReadString(_ok.i))
                            
                          Case "object_use_in_front_transparency"
                            world_object()\object_use_in_front_transparency=Val(ReadString(_ok.i))
                            
                            
                          Case "object_change_on_fade_out"
                            world_object()\object_change_on_fade_out=Val(ReadString(_ok.i))
                            
                          Case "object_emit_stop_on_collision"
                            world_object()\object_emit_stop_on_collision=Val(ReadString(_ok.i))
                            
                          Case "object_play_sound_on_emit"
                            world_object()\object_play_sound_on_emit=Val(ReadString(_ok.i))
                            
                          Case "object_sound_on_emit_path"
                            world_object()\object_sound_on_emit_path=ReadString(_ok.i)
                            
                          Case "object_sound_on_emit_volume"
                            world_object()\object_sound_on_emit_volume=Val(ReadString(_ok.i))
                            
                          Case "object_sound_on_change_volume"
                            world_object()\object_sound_on_change_volume=Val(ReadString(_ok.i))
                            
                          Case "object_play_sound_on_change"
                            world_object()\object_play_sound_on_change=Val(ReadString(_ok.i))
                            
                          Case "object_sound_on_change_path"
                            world_object()\object_sound_on_change_path=ReadString(_ok.i)
                            
                          Case "object_use_spawn_border_offset"
                            world_object()\object_use_spawn_border_offset=Val(ReadString(_ok.i))
                            
                          Case "object_show_hp_bar"
                            world_object()\object_show_hp_bar=Val(ReadString(_ok.i))
                            
                          Case "object_debug_if_remove"
                            world_object()\object_debug_if_remove=Val(ReadString(_ok.i))
                            
                          Case "object_no_child_if_move_down"
                            world_object()\object_no_child_if_move_down=Val(ReadString(_ok.i))
                            
                          Case "object_no_gravity_after_collision"
                            world_object()\object_no_gravity_after_collision=Val(ReadString(_ok.i))
                         
                          Case "object_use_teleport_effect"
                            world_object()\object_use_teleport_effect=Val(ReadString(_ok.i))
                            
                          Case "object_teleport_gfx_path"
                            world_object()\object_teleport_gfx_path=ReadString(_ok.i)
                            
                          Case "object_use_teleport_on_max_x"
                            
                          Case "object_save_map_on_remove"
                            world_object()\object_save_map_on_remove=Val(ReadString(_ok.i))
                            
                          Case "object_set_fade_out_on_ai"
                            world_object()\object_set_fade_out_on_ai=Val(ReadString(_ok.i))
                            
                          Case "object_activate_fade_out_on_ai"
                            world_object()\object_activate_fade_out_on_ai=Val(ReadString(_ok.i))
                            
                          Case "object_music_global_start"
                            world_object()\object_music_global_start=Val(ReadString(_ok.i))
                            
                          Case "object_anim_stop_after_last_frame"
                            world_object()\object_anim_stop_after_last_frame=Val(ReadString(_ok.i))
                            
                          Case "object_use_start_direction"
                            world_object()\object_use_start_direction=Val(ReadString(_ok.i))
                            
                          Case "object_default_start_direction"
                            world_object()\object_default_start_direction=ReadString(_ok.i)
                            
                          Case "object_follow_player_after_timer"
                            world_object()\object_follow_player_after_timer=Val(ReadString(_ok.i))
                            
                          Case "object_follow_player_timer"
                            world_object()\object_follow_player_timer=Val(ReadString(_ok.i))
                            
                            
                          Case "object_follow_player_on_timer"
                            world_object()\object_follow_player_on_timer=Val(ReadString(_ok.i))
                            
                          Case "object_keep_move_direction"
                            world_object()\object_keep_move_direction=Val(ReadString(_ok.i))
                            
                          Case "object_emit_jump_object_max"
                            world_object()\object_emit_jump_object_max=Val(ReadString(_ok.i))
                            
                          Case "object_stop_scroll_after_allert"
                            world_object()\object_stop_scroll_after_allert=Val(ReadString(_ok.i))
                            
                          Case "object_play_sound_on_restore"
                            world_object()\object_play_sound_on_restore=Val(ReadString(_ok.i))
                            
                          Case "object_sound_on_restore_path"
                            world_object()\object_sound_on_restore_path=Trim(ReadString(_ok.i))
                            
                          Case "object_sound_on_restore_volume"
                            world_object()\object_sound_on_restore_volume=Val(ReadString(_ok.i))
                            
                          Case "object_remove_with_guard"
                            world_object()\object_remove_with_guard=Val(ReadString(_ok.i))
                            
                          Case "object_emitter_pause_if_spawn"
                            world_object()\object_emitter_pause_if_spawn=Val(ReadString(_ok.i))
                            
                          Case "object_use_effect_area"
                            world_object()\object_use_effect_area=Val(ReadString(_ok.i))
                            
                          Case "object_effect_area_w"
                            world_object()\object_effect_area_w=ValF(ReadString(_ok.i))
                            
                          Case "object_effect_area_h"
                            world_object()\object_effect_area_h=ValF(ReadString(_ok.i))
                            
                          Case "object_use_auto_reposition"
                            world_object()\object_use_auto_reposition=Val(ReadString(_ok.i))
                            
                          Case "object_use_virtual_buffer"
                            world_object()\object_use_virtual_buffer=Val(ReadString(_ok.i))
                            
                     
                            
                          Case "object_call_dead_timer"
                            world_object()\object_call_dead_timer=Val(ReadString(_ok.i))
                            
                          Case "object_use_call_dead_timer"
                            world_object()\object_use_call_dead_timer=Val(ReadString(_ok.i))
                            
                          Case "object_dead_timer_object_ai42"
                            world_object()\object_dead_timer_object_ai42=Trim(ReadString(_ok.i))
                            
                            
                          Case "object_is_reaper"
                            world_object()\object_is_reaper=Val(ReadString(_ok.i))
                            
                          Case "object_rigit_collision_x"
                            world_object()\object_rigit_collision_x=ValF(ReadString(_ok.i))
                            
                          Case "object_rigit_collision_y"
                            world_object()\object_rigit_collision_y=ValF(ReadString(_ok.i))
                            
                          Case "object_rigit_rotate"
                            world_object()\object_rigit_rotate=ValF(ReadString(_ok.i))
                            
                          Case "object_use_physic_collision"
                            world_object()\object_use_physic_collision=Val(ReadString(_ok.i))
                            
                          Case "object_use_physic_loop"
                            world_object()\object_use_physic_loop=Val(ReadString(_ok.i))
                            
                          Case "object_use_physic_no_collision"
                            world_object()\object_use_physic_no_collision=Val(ReadString(_ok.i))
                          Case "object_asset_load_pause"
                            world_object()\object_asset_load_pause=Val(ReadString(_ok.i))
                            
                          Case "object_use_asset_load_pause"
                            world_object()\object_use_asset_load_pause=Val(ReadString(_ok.i))
                            
                          Case "object_collision_on_off"
                            world_object()\object_collision_on_off=Val(ReadString(_ok.i))
                            
                      
                            
                          Case "object_is_scroll_back_ground"
                            world_object()\object_is_scroll_back_ground=Val(ReadString(_ok.i))
                            
                          Case "object_scroll_speed_h"
                            world_object()\object_scroll_speed_h=ValF(ReadString(_ok.i))
                            
                          Case "object_back_ground_auto_scroll"
                            world_object()\object_back_ground_auto_scroll=Val(ReadString(_ok.i))
                            
                          Case "object_enemy_maximum"
                            world_object()\object_enemy_maximum=Val(ReadString(_ok.i))
                            
                          Case "object_use_enemy_maximum"
                            world_object()\object_use_enemy_maximum=Val(ReadString(_ok.i))
                            
                          Case "object_activate_other_on_creation"
                            world_object()\object_activate_other_on_creation=Val(ReadString(_ok.i))
                          Case "object_activated_by_object"
                            world_object()\object_activated_by_object=Val(ReadString(_ok.i))
                            
                          Case "object_stamp_transparency"
                            world_object()\object_stamp_transparency=Val(ReadString(_ok.i))
                            
                          Case "object_use_player_position"
                            world_object()\object_use_player_position=Val(ReadString(_ok.i))
                            
                          Case "object_player_position_offset_y"
                            world_object()\object_player_position_offset_y=ValF(ReadString(_ok.i))
                            
                          Case "object_player_position_offset_x"
                            world_object()\object_player_position_offset_x=ValF(ReadString(_ok.i))
                          Case "object_turn_right_screen_full_spawn"
                            world_object()\object_turn_right_screen_full_spawn=Val(ReadString(_ok.i))
                            
                          Case "object_NPC_use_talk_area"
                            world_object()\object_NPC_use_talk_area=Val(ReadString(_ok.i))
                            
                          Case "object_NPC_talk_area_h"
                            world_object()\object_NPC_talk_area_h=ValF(ReadString(_ok.i))
                            
                          Case "object_NPC_talk_area_w"
                            world_object()\object_NPC_talk_area_w=Val(ReadString(_ok.i))
                            
                          Case "object_use_attack_direction"
                            world_object()\object_use_attack_direction=Val(ReadString(_ok.i))
                            
                          Case "object_change_emitter"
                            world_object()\object_change_emitter=Val(ReadString(_ok.i))
                            
                          Case "object_change_emitter_with_id"
                            world_object()\object_change_emitter_with_id=Val(ReadString(_ok.i))
                            
                          Case "object_emitter_id"
                            world_object()\object_emitter_id=Val(ReadString(_ok.i))
                            
                          Case "object_change_emitter_new_path"
                            world_object()\object_change_emitter_new_path=Trim(ReadString(_ok.i))
                            
                          Case "object_switch_map_path"
                            world_object()\object_switch_map_path=Trim(ReadString(_ok.i))
                            
                          Case "object_switch_map"
                            world_object()\object_switch_map=Val(ReadString(_ok.i))
                            
                          Case "object_no_fight"
                            world_object()\object_no_fight=Val(ReadString(_ok.i))
                          Case "object_use_isometric"
                            world_object()\object_use_isometric=Val(ReadString(_ok.i))
                        
                            
                         
     EndSelect
     

     
  
    Wend
    
    
    
 
    
    
    CloseFile(_ok.i)
    
   
    ;all core data read,
    ;now go for the gf
    
       _help_path.s=world_object()\object_gfx_path
    ;------------------------------------------------------------------------
    
    world_object()\object_gfx_path=e_engine\e_graphic_source+world_object()\object_gfx_path
    world_object()\object_stamp_buffer_path=e_engine\e_graphic_source+world_object()\object_stamp_buffer_path

    
    
    world_object()\object_gfx_id_default_frame=LoadSprite(#PB_Any,world_object()\object_gfx_path,#PB_Sprite_AlphaBlending )  ;old classic system for fallback...
   
        
   
          
          If IsSprite(world_object()\object_gfx_id_default_frame)
            ;---------------------------- automatic shadow position for all objects --------------------------- this is used if no shadow offset information is in the ai42 file, but shadow is #true
            ;world_object()\object_shadow_offset_x=SpriteWidth(world_object()\object_gfx_id_default_frame)/8
            ;world_object()\object_shadow_offset_y=SpriteHeight(world_object()\object_gfx_id_default_frame)/8
            ;------------------------------------------------------------
            world_object()\object_w=SpriteWidth(world_object()\object_gfx_id_default_frame)
            world_object()\object_h=SpriteHeight(world_object()\object_gfx_id_default_frame)
            world_object()\object_stream_gfx_loaded=#True
            
          Else
            E_LOG(e_engine\e_engine_source_element," WARNING MISSING: "+world_object()\object_ai_path,GetFilePart(world_object()\object_gfx_path))  
            world_object()\object_gfx_id_default_frame=LoadSprite(#PB_Any,e_engine\e_gfx_place_holder_path,#PB_Sprite_AlphaBlending )
           
            If IsSprite(world_object()\object_gfx_id_default_frame)
              
              If world_object()\object_w<1 Or world_object()\object_h<1
                world_object()\object_w=32
                world_object()\object_h=32
                ZoomSprite(world_object()\object_gfx_id_default_frame,world_object()\object_w,world_object()\object_h)
                world_object()\object_w=SpriteWidth(world_object()\object_gfx_id_default_frame)
                world_object()\object_h=SpriteHeight(world_object()\object_gfx_id_default_frame)
                
             
              
              EndIf
              world_object()\object_stream_gfx_loaded=#True
             
              Else
                
                E_LOG(e_engine\e_engine_source_element," WARNING MISSING: PLACEHOLDER FOR: "+world_object()\object_ai_path,GetFilePart(world_object()\object_gfx_path))
                DeleteElement(world_object())
                ProcedureReturn #False
       
              EndIf
              
          EndIf
          
            
          
          If world_object()\object_is_anim=#True
           E_LOAD_ANIM_SPRITE()
          EndIf
          
          E_INIT_OBJECT_STATE_ON_START()  ;master routine, can overwrite default settings!
          E_SET_UP_FOR_TARGET_ON_PLAYER()
          
          
          ;for " parent object border spawn" horizontal supoported only for now
          If world_object()\object_use_spawn_border_offset=#True
            
            ;set this if object uses parent border spawn (horizontal only supported)
            Select _md.i
              Case #RIGHT
                world_object()\object_x=_x.f+_w.f
              Case #LEFT
                world_object()\object_x=_x.f
                
            EndSelect
            
          EndIf
          
           
  
 EndProcedure
    
    
    


     Procedure E_STREAM_READ_WORLD_DATA(_ok.i)
      
       Define _key.s=""
       Define _valid.b=#False
      
      e_map_use_daytimer.b=#True  ;default 
      e_engine\e_world_map_is_arena_map=#False ;default
      e_engine\e_switch_map_on_trigger=#False
      e_engine\e_world_show_timer=#False
      e_engine\e_world_auto_layer=#False
      e_engine\e_world_map_is_arena_map=#False
      e_engine\e_map_auto_loot_done=#False
      e_engine\e_map_use_black_stamp=#False
      e_engine\e_pointer_sound_boss=0
      e_engine\e_map_mode_fight=#False
      e_switch_plane.b=#False
      e_engine\e_map_show_gui=#True
      
      While Not Eof(_ok.i)
        _valid.b=#False
        
        _key.s=ReadString(_ok.i)
        
        Select  _key.s
            
            
            ;day night cycle infos are stored by the engine, not by the map creator:
            
          Case "DAY_NIGHT_INTENSE_MAX"
                day_night_cycle\light_intensity_max=Val(ReadString(_ok.i))
                     
          Case "DAY_NIGHT_INTENSE_MIN"
             day_night_cycle\light_intensity_min=Val(ReadString(_ok.i))
             
           Case "DAY_NIGHT_INTENSE_ACTUAL"
                day_night_cycle\light_intensity_actual=Val(ReadString(_ok.i))
            
            ;----------------------------------------------------------------------------------------------------
            
          Case "WORLD_GLOBAL_SOUND"
            
            e_global_sound_full_path.s=Trim(ReadString(_ok.i))
                               
              e_engine\e_global_sound_path=GetFilePart(e_global_sound_full_path.s)
              
              
              If Len(e_engine\e_global_sound_path)>0
                
              If e_engine\e_global_sound_path_back_up<>e_engine\e_global_sound_path
                
                              ;different sound/different soundfile  we load the actual/new soundfile
                If IsSound(e_engine\e_global_sound_id)
                   FreeSound(e_engine\e_global_sound_id)
                EndIf

                e_engine\e_global_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+e_engine\e_global_sound_path,#PB_Sound_Streaming)  ;for default we set volume at 100% 
              
               EndIf
               
             Else
               
               If IsSound(e_engine\e_global_sound_id)<>0  ;no sound file is loaded, so we check if old id is active or id is active and free the resources used
                 FreeSound(e_engine\e_global_sound_id)
               EndIf
               
                
              EndIf
              
              
                
                If IsSound(e_engine\e_global_sound_id)<>0
                  e_engine\e_global_sound_path_back_up=e_engine\e_global_sound_path
                  
                  e_engine\e_global_sound_frequence_back_up=GetSoundFrequency(e_engine\e_global_sound_id)
                Else
                 
                  e_engine\e_global_sound_path_back_up=""
                  
                  If Len(e_engine\e_global_sound_path)>0
                    E_LOG(e_engine\e_engine_source_element,v_engine_sound_path.s+e_engine\e_global_sound_path,e_engine\e_global_sound_path)
                  EndIf
                  
                EndIf
                
                  
         
            
            
          Case "MAP_SHOW_TIMER"
            If Val(ReadString(_ok.i))>0
             e_engine\e_world_show_timer=#True
                      
            EndIf
            
            
            
          Case "USE_AUTO_LAYER"
            
            If ReadString(_ok.i)="YES"
              e_engine\e_world_auto_layer=#True
                        
            EndIf
            
            
          Case "MAP_CAN_PAUSE"
            If ReadString(_ok.i)="NO"
              e_map_can_pause_id.b=#False
            EndIf
            
          Case  "MAP_USE_RESPAWN"
            If ReadString(_ok.i)="NO"
              e_map_no_respawn.b=#True
            EndIf
            
          Case "MAP_DAY_TIMER"
            
            If Val(ReadString(_ok.i))<1
              e_map_use_daytimer.b=#False    
            EndIf
            
            
          Case "MAP_USE_QUEST_SYSTEM"
            
            Select Val(ReadString(_ok.i))
                
              Case 1
                e_map_use_quest_system.b=#True
                
            EndSelect
            
          Case "MAP_FIGHT"
            
            Select ReadString(_ok.i)
                
              Case "YES"
               e_engine\e_map_mode_fight=#True
                
                        EndSelect
            
            
            Case "MAP_IS_ARENA"
            
            Select ReadString(_ok.i)
                
              Case "YES"
                e_engine\e_world_map_is_arena_map=#True
                            
            EndSelect
            
          Case "OFFSETX:"
            e_engine\e_world_offset_x=Val(ReadString(_ok.i))
            
            
          Case "OFFSETY:"
            e_engine\e_world_offset_y=Val(ReadString(_ok.i))
            
            
            
          Case "MAP_AUTO_RANDOM_LOOT_DONE"
            If Val(ReadString(_ok.i))>0
            e_engine\e_map_auto_loot_done=#True  
            EndIf
            
            
          Case "SHOW_VERSION_INFO"
            If Val(ReadString(_ok.i))=1
            e_version_info\map_show_version_info=#True  
            EndIf
            
          
          Case "MAP_AUTO_SWITCH_TIMER"
            e_map_timer\_map_time=Val(ReadString(_ok.i))
            
          Case "SWITCH_MAP"
            e_map_timer\_next_map=ReadString(_ok.i)
            
          Case "SWITCH_MAP_ON_TRIGGER"
            If Val(ReadString(_ok.i))>0
            e_engine\e_switch_map_on_trigger=#True  
            EndIf
            
            
            Case "MAP_USE_BLACK_STAMP"
              If Val(ReadString(_ok.i))>0
               e_engine\e_map_use_black_stamp=#True  
              EndIf
              
            Case "SCROLL"
             
              If Val(ReadString(_ok.i))<>1
                If e_engine\e_true_screen=#True
                e_engine\e_engine_no_scroll_margin=ScreenWidth()
                e_engine\e_engine_scroll_map=#False
              Else
                e_engine\ e_engine_no_scroll_margin=WindowWidth(#ENGINE_WINDOW_ID)
                e_engine\e_engine_scroll_map=#False
              EndIf
              
              EndIf
              
            Case "WORLD_GLOBAL_EFFECT"
              Select ReadString(_ok.i)
                  
                Case "WINTER"
                  e_engine_global_effects\global_effect_name="WINTER"
                  
              EndSelect
              
              
            Case "WORLD_SHOW_SCROLL_TEXT"
              
              If Val(ReadString(_ok.i))>0
                  e_engine\e_map_show_scroll_text=#True
                  
                Else
                    e_engine\e_map_show_scroll_text=#False

          
              EndIf
              
              
            Case "MAP_SHOW_GUI"
              
              Select Val(ReadString(_ok.i))
                  
                Case #False
                  e_engine\e_map_show_gui=#False
                  
                Default
                  
                  e_engine\e_map_show_gui=#True
                  
              EndSelect
              
              
              

            
          Case "NEXTELEMENT:"
            
            If AddElement(world_object())
              
            E_INIT_OBJECT_DEFAULT_STATE()
            
           ; world_object()\object_is_active=#True            ;used for streamsystem.....
            ;world_object()\object_blink_object_show=#True
            world_object()\object_w=64 ;default for streamtechnology  maybe setup by script values...2D field of view :)
            world_object()\object_h=64 ;default  for streamtechnology
            
          Else
            
             E_LOG(e_engine\e_engine_source_element,"CAN NOT CREATE ELEMENT",Str(ListSize(world_object())))
             ProcedureReturn #False   
            EndIf
            
            
          Case "OBJECTSOURCE:"
            world_object()\object_ai_path=e_engine\e_graphic_source+Trim(ReadString(_ok.i)) ;we store the block script path, we use the script path for loading (sprite) and controlling the block
            
          Case "OBJECT_X:"
            world_object()\object_x=Val(ReadString(_ok.i))
           
            
            
          Case "OBJECT_Y:"
            world_object()\object_y=Val(ReadString(_ok.i))
           
            
          Case "OBJECTLAYER:"
            world_object()\object_layer=Val(ReadString(_ok.i))
            
            ;needed for the first load per streammodule, so we have the right internal size of the object to display  it the right way
          Case "OBJECT_W:"
            world_object()\object_w=Val(ReadString(_ok.i))
            
          Case "OBJECT_H:"
            world_object()\object_h=Val(ReadString(_ok.i))
              
          Case "FULLSCREEN:"
            
            If Val(ReadString(_ok.i))<>0
              world_object()\object_full_screen=#True  ;must be set here!!!
             EndIf
            
          
             
            
          Case "QUESTBOOK_CHAPTERS"
            player_statistics\player_quest_size=Val(ReadString(_ok.i))
            player_statistics\player_quest_bar_max=player_statistics\player_quest_size
            
        EndSelect
          
      
      Wend
    
    EndProcedure

    
    
    
    
    
    

 

      Procedure   E_STREAM_BUILD_WORLD(_world.s)
        ;now we search for the "START:" keyword in the world map data:
        Define _respawn.b=#False
        Define _ok.i=0
        Define _work_file.s=e_engine\e_world_source+_world.s
        Define _key.s=""
        Define _dummy.i=1
        e_engine\e_engine_scroll_map=#True
        e_engine\e_engine_no_scroll_margin=0
        e_map_use_quest_system.b=#False
        e_engine\e_day_night_overide=#WORLD_DAY_NIGHT_NOT_DEFINED
        
        player_statistics\player_arena_enemies=0  ;reset to default!
        
        If pool_map()\_respawn=#True    ;we reenter a map ???(mayby back from dungeon, from shop...)
          _respawn.b=E_SEARCH_FOR_RESPAWN_MAP(_world.s)
        EndIf
        
        If _respawn.b=#True        ; we found a valid map for respawn
          _work_file.s=e_engine\e_save_path+_world.s  
        EndIf
        
        ;here we load the map :
        
        _ok.i=ReadFile(#PB_Any,_work_file.s)
        
        If IsFile(_ok.i)=0
          E_LOG(e_engine\e_engine_source_element,_work_file.s,"File Missing") 
                ProcedureReturn #False  
        EndIf
        
        
        
        While Not Eof(_ok.i)
          
          _key.s=ReadString(_ok.i)
          
          Select _key.s
              
              
            Case "MAP OBJECTS:"
              _dummy .i=Val(ReadString(_ok.i))
              
              
            Case "WORLD_VIEW_W"
              v_screen_w.f=ValF(ReadString(_ok.i))   ;holds the size of the viepoint, new map system , new mapformat.
              e_engine\e_screen_backup_w=v_screen_w.f    
              
            Case "WORLD_VIEW_H"
              v_screen_h.f=ValF(ReadString(_ok.i))
              e_engine\e_screen_backup_h=v_screen_h.f
              
              
            Case "MAP_AUTO_RANDOM_LOOT_DONE"
              If Val(ReadString(_ok.i))>0
                e_engine\e_map_auto_loot_done_global=#True
              EndIf
              
              
            Case "WORLD_START:"  ;jump to the big parser, use this file id to scan the worldfile
              E_STREAM_READ_WORLD_DATA(_ok.i)
              
          EndSelect
          
          
        Wend
        
        
        
        
        CloseFile(_ok.i)
        
        
          
      If ListSize(world_object())<1
        E_ERROR_MAP(#E_ERROR_MAP_EMPTY)
        ProcedureReturn #False
      EndIf
      
      
      E_SET_DAY_NIGHT_AFTER_LOAD()
      
      e_engine\e_map_name_show_total_timer=e_engine_heart_beat\beats_since_start+e_engine\e_map_name_start_show_timer
      e_engine\e_scroll_text_source=_work_file.s+"."+e_engine\e_world_map_scroll_text_suffix

    e_switch_plane.b=#True  
   
        
      Select e_engine\e_map_show_scroll_text
            Case #True
            E_SCROLL_TEXT_LOAD(e_engine\e_scroll_text_source)
         
            
        EndSelect
        ;E_PLAYER_STATUS_LOAD_NO_CRYPT()
       ; E_PLAYER_STATUS_LOAD_DECRYPT()

        
        ;------------- important ----- arena maps always NO RESPAWN MAPS ------ you can not save progress, if you quit the game you will start outside the arena and loose all progress
        If e_engine\e_world_map_is_arena_map=#True
          e_map_no_respawn.b=#True  
        EndIf
        
        E_AUTO_MAP_SWITCH_INTEGRITY_CHECK()
       
       
      EndProcedure


      
      
      
      
      

Procedure E_GET_WORLD_DATA()

  ;here we gooooo
  
  Define _directory.i
  
  _directory.i=ExamineDirectory(#PB_Any, e_engine\e_world_source,e_engine\e_ai_map_filter)
  
  If IsDirectory(_directory.i)
    
    While  NextDirectoryEntry(_directory.i)
      
      If DirectoryEntryType(_directory.i)=#PB_DirectoryEntry_File
        
        If AddElement(pool_map())
          
          pool_map()\_name=DirectoryEntryName(_directory.i)
          pool_map()\_respawn=#True  ;map is loaded, if we saved it to the userdirectory we can reload it, with actual state
             
        EndIf
        
      Else
        
        e_engine\e_show_debug=#True
        
        
      EndIf
      
      
    Wend
    
    FinishDirectory(_directory.i)
  EndIf
  

  
  
EndProcedure


; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 3318
; FirstLine = 3299
; Folding = -----
; EnableThread
; EnableXP
; EnableUser
; EnableOnError
; Executable = dwarfking.exe
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant