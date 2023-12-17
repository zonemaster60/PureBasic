;the main routine for parsing engine settings on startup
Declare E_PLAYER_STATUS_SET_DEFAULT()

Procedure E_SETUP_DEFAULT_START_TIME()
  ;here we setup the time for for the first start
  e_world_time\e_world_time_hour=e_world_time\e_world_time_start_hour
  e_world_time\e_world_time_minute=e_world_time\e_world_time_start_minute
  e_world_time\e_world_time_second=e_world_time\e_world_time_start_second
  e_day_night_clock_position.f=e_world_time\e_world_time_hour*e_day_night_clock_segment_angle.f
  
EndProcedure





Procedure E_TRY_DIRECTORY()
  ;does it work?
  Define _do.i=0
  Define _dodir.i=0
    
  _dodir.i=CreateDirectory(e_engine\e_save_path)
  _do.i=CreateFile(#PB_Any,e_engine\e_save_path+"validdirectory.pj17")
  
  If IsFile(_do.i)
    e_user_account_id.b=#True
    CloseFile(_do.i)
  
  EndIf
  
  
  
EndProcedure



Procedure   E_CREATE_USER_ACCOUNT()
  ;if not, we create the user account, its used for saving, snapshots and other
  Define _ok.i=0
  
  _ok.i=ExamineDirectory(#PB_Any,v_user_directory.s+e_engine\e_save_path,"*.*")
  
  If  IsDirectory(_ok.i)
    e_engine\e_save_path=v_user_directory.s+e_engine\e_save_path
    e_user_account_id.b=#True
    FinishDirectory(_ok.i)
  Else
    e_engine\e_save_path=v_user_directory.s+e_engine\e_save_path
    E_TRY_DIRECTORY()
  EndIf
  
  
EndProcedure



Procedure E_SET_UP_EFFECTS_FOR_START()
  ;do some corrections and checkings, load some stuff
  
  npc_text\npc_text_pop_up_sound_id=LoadSound(#PB_Any,npc_text\npc_text_pop_up_sound_path,#PB_Sound_Streaming) 
  e_engine\e_timer_sound_id=LoadSound(#PB_Any,e_engine\e_timer_sound_path,#PB_Sound_Streaming)
  
  If e_engine\e_timer_speed<0
    e_engine\e_timer_speed=0  
  EndIf
  
  e_engine_build_in_effect\e_sgfx_effect_time=e_engine_heart_beat\beats_since_start+e_engine_build_in_effect\e_sgfx_effect_timer
  
  If e_engine_build_in_effect\e_sgfx_effect_mode>0
    e_engine_build_in_effect\e_sgfx_effect_mode=#SGFX_DYNAMIC
  EndIf
  
  
EndProcedure


Procedure E_PLAYER_SYMBOLS_HEALTH_ADD()
  ;use this for positioning and presenting life/potion/heart/symbols on game screen:now load them (j
  If player_statistics\player_health_symbol_show=#False
  ProcedureReturn #False  
  EndIf
  
    
    If IsSprite(player_statistics\player_health_symbol_gfx_id)
    FreeSprite(player_statistics\player_health_symbol_gfx_id)  ;make shure no data is behind this structure; so we use this for the very first start and after a game over
    EndIf
    player_statistics\player_health_symbol_gfx_id=LoadSprite(#PB_Any,player_statistics\player_health_symbol_location,#PB_Sprite_AlphaBlending)
    
EndProcedure


Procedure E_INIT_GFX_FONT_DIGIT()
  ;only for the directory with the digits
  ;in this directory must gfx files stored
 
  Define _dir.i=0
  Define _gfx_id.b=0  ;for the 10 digit font
  _dir.i=ExamineDirectory(#PB_Any,gfx_font\gfx_font_object_digit_path,"*.png")
  
  If _dir.i=0
  ProcedureReturn #False  
  EndIf
  
  While NextDirectoryEntry(_dir.i) And _gfx_id.b<10
    If DirectoryEntryType(_dir.i)=#PB_DirectoryEntry_File
      ;try to load the gfx...
     gfx_font\gfx_font_object_digit_id[_gfx_id.b]=LoadSprite(#PB_Any,gfx_font\gfx_font_object_digit_path+DirectoryEntryName(_dir.i),#PB_Sprite_AlphaBlending)
     
     If IsSprite(gfx_font\gfx_font_object_digit_id[_gfx_id.b])
     _gfx_id.b+1  
     EndIf
     
     
    EndIf
    
    
  Wend
  
  
  FinishDirectory(_dir.i)
EndProcedure



Procedure  E_PLAYER_OBJECT_GET_VALUE(_file_id.i,_key.s)
  ;read the player inis and some boss inis
  
  _key.s=Trim(_key.s)
  
  Select  _key.s
      
      
    Case "CONFY_W"
      npc_confy\confy_w=Val(ReadString(_file_id.i))
    
      
    Case "CONFY_H"
      npc_confy\confy_h=Val(ReadString(_file_id.i))
    
      
    Case "INGAME_INFO_TEXT_TIME_SECONDS"
      e_player_warning\e_player_warning_show_time=Val(ReadString(_file_id.i))*1000
      
      If e_player_warning\e_player_warning_show_time<1000
        e_player_warning\e_player_warning_show_time=3000  ;default five seconds
        EndIf
      
      
    Case "PLAYER_CORE"
      player_statistics\player_core_path=v_engine_base+Trim(ReadString(_file_id.i))
      
    Case  "PLAYER_SOUND_ON_DEATH"
      player_statistics\player_sound_on_death=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
      player_statistics\player_sound_on_death_id.i=LoadSound(#PB_Any,player_statistics\player_sound_on_death,#PB_Sound_Streaming)
      
    Case "PLAYER_SOUND_ON_LEVEL_UP"
      player_statistics\player_sound_on_level_up= v_engine_sound_path.s+Trim(ReadString(_file_id.i))
      player_statistics\player_sound_on_level_up_id=LoadSound(#PB_Any,player_statistics\player_sound_on_level_up,#PB_Sound_Streaming)
      
    Case "PLAYER_SOUND_ON_FOUND_ALL_GEMS"
      player_statistics\player_sound_on_found_all_quest_objects=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
      player_statistics\player_sound_on_found_all_quest_objects_id=LoadSound(#PB_Any,player_statistics\player_sound_on_found_all_quest_objects,#PB_Sound_Streaming)
      
    Case "PLAYER_SOUND_ON_FIGHT"
      player_statistics\player_sound_on_fight=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
      player_statistics\player_sound_on_fight_id=LoadSound(#PB_Any,player_statistics\player_sound_on_fight,#PB_Sound_Streaming)
  
      
    Case "PLAYER_SOUND_ON_SHIELD_CHARGE"
      player_statistics\player_sound_on_shield_power_up_paths=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
      player_statistics\player_sound_on_shield_power_up_id=LoadSound(#PB_Any,player_statistics\player_sound_on_shield_power_up_paths,#PB_Sound_Streaming)
      
    Case "PLAYER_SOUND_ON_WIN"
     player_statistics\player_sound_on_win=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
     player_statistics\player_sound_on_win_id=LoadSound(#PB_Any,player_statistics\player_sound_on_win,#PB_Sound_Streaming)
     
   Case "PLAYER_INVENTORY_PICK_UP_SOUND"
     player_statistics\player_sound_on_item_pic_up_paths=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
     player_statistics\player_sound_on_item_pic_up_id=LoadSound(#PB_Any,player_statistics\player_sound_on_item_pic_up_paths,#PB_Sound_Streaming)
     
     
   Case "PLAYER_TELEPORT_SOUND"
     player_statistics\player_spawn_teleport_sound_path=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
     player_statistics\player_spawn_teleport_sound_id=LoadSound(#PB_Any,player_statistics\player_spawn_teleport_sound_path,#PB_Sound_Streaming)
     
   Case "PLAYER_HEALTH_BAR_SYMBOL"
     player_statistics\player_health_bar_symbol_path=player_statistics\player_core_path+ReadString(_file_id.i)
     
     
   Case "PLAYER_HEALTH_BAR"
     player_statistics\player_health_bar_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
     
   Case "PLAYER_HEALTH_BAR_WIDTH"
     player_statistics\player_health_bar_width=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_HEALTH_BAR_HEIGHT"
     player_statistics\player_health_bar_height=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_HEALTH_BAR_POSITION_X"
     player_statistics\player_health_bar_pos_x=ValF(ReadString(_file_id.i))
          
   Case "PLAYER_HEALTH_BAR_POSITION_Y"
     player_statistics\player_health_bar_pos_y=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_HEALTH_BAR_SHOW"
     player_statistics\player_health_bar_show=Val(ReadString(_file_id.i))
     
   Case "PLAYER_HEALTH_BAR_TRANSPARENCY"
     player_statistics\player_health_bar_transparency=255-Val(ReadString(_file_id.i))
     If player_statistics\player_health_bar_transparency<0
       player_statistics\player_health_bar_transparency=0
     EndIf
     
   Case "PLAYER_HEALTH_BAR_BACK_TRANSPARENCY"
      player_statistics\player_health_bar_back_transparency=255-Val(ReadString(_file_id.i))
     If player_statistics\player_health_bar_back_transparency<0
       player_statistics\player_health_bar_back_transparency=0
     EndIf
     
     Case "PLAYER_HEALTH_BAR_BACK"
       player_statistics\player_health_bar_back_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
       
     Case "PLAYER_HEALTH_BAR_BACK_OFFSET_X"
       player_statistics\player_health_bar_back_offset_x=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_HEALTH_BAR_BACK_OFFSET_Y"
       player_statistics\player_health_bar_back_offset_y=ValF(ReadString(_file_id.i))
       
     Case"PLAYER_HEALTH_BAR_BACK_HEIGHT"
       player_statistics\player_health_bar_back_height=ValF(ReadString(_file_id.i))
     
         
   Case "PLAYER_XP_BAR"
     player_statistics\player_xp_bar_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
     
      Case "PLAYER_XP_BAR_BACK"
       player_statistics\player_xp_bar_back_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
     
     Case "PLAYER_XP_BAR_WIDTH"
      
     player_statistics\player_xp_bar_width=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_XP_BAR_HEIGHT"
     player_statistics\player_xp_bar_height=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_XP_BAR_POSITION_X"
     player_statistics\player_xp_bar_pos_x=ValF(ReadString(_file_id.i))
          
   Case "PLAYER_XP_BAR_POSITION_Y"
     player_statistics\player_xp_bar_pos_y=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_XP_BAR_SHOW"
     player_statistics\player_xp_bar_show=Val(ReadString(_file_id.i))
     
   Case "PLAYER_XP_BAR_TRANSPARENCY"
     player_statistics\player_xp_bar_transparency=255-Val(ReadString(_file_id.i))
     If player_statistics\player_xp_bar_transparency<0
       player_statistics\player_xp_bar_transparency=0
     EndIf
     
   Case "PLAYER_XP_BAR_BACK_TRANSPARENCY"
      player_statistics\player_xp_bar_back_transparency=255-Val(ReadString(_file_id.i))
     If player_statistics\player_xp_bar_back_transparency<0
       player_statistics\player_xp_bar_back_transparency=0
     EndIf
     
          
     Case "PLAYER_XP_BAR_BACK_OFFSET_X"
       player_statistics\player_xp_bar_back_offset_x=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_XP_BAR_BACK_OFFSET_Y"
       player_statistics\player_xp_bar_back_offset_y=ValF(ReadString(_file_id.i))
       
     Case"PLAYER_XP_BAR_BACK_HEIGHT"
       player_statistics\player_xp_bar_back_height=ValF(ReadString(_file_id.i))
       
     Case"PLAYER_XP_BAR_BACK_WIDTH"
       player_statistics\player_xp_bar_back_width=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_START_XP"
       player_statistics\player_xp_max=ValF(ReadString(_file_id.i))
       
       
     Case "PLAYER_QUEST_BAR_WIDTH"
       player_statistics\player_quest_bar_width=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR_HEIGHT"
       player_statistics\player_quest_bar_height=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR_BACK"
       player_statistics\player_quest_bar_back_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR"
       player_statistics\player_quest_bar_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR_POSITION_X"
       player_statistics\player_quest_bar_pos_x=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR_POSITION_Y"
       player_statistics\player_quest_bar_pos_y=ValF(ReadString(_file_id.i))
       
     Case "PLAYER_QUEST_BAR_BACK_TRANSPARENCY"
       player_statistics\player_quest_bar_back_transparency=255-Val(ReadString(_file_id.i))  
       
       If player_statistics\player_quest_bar_back_transparency<0
       player_statistics\player_quest_bar_back_transparency=0  
       EndIf
       
       
     Case "PLAYER_QUEST_BAR_TRANSPARENCY"
       player_statistics\player_quest_bar_transparency=255-Val(ReadString(_file_id.i))
       
     If player_statistics\player_quest_bar_transparency<0
       player_statistics\player_quest_bar_transparency=0  
     EndIf
     
Case "PLAYER_INFO_FONT"
     player_statistics\player_info_font_name=Trim(ReadString(_file_id.i))
     
   Case "PLAYER_INFO_FONT_SIZE"
     player_statistics\player_info_font_size=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD"
     player_statistics\player_defence_object_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD_SOUND"
     player_statistics\player_defence_object_sound_path=v_engine_sound_path.s+Trim(ReadString(_file_id.i))
     player_statistics\player_defence_object_sound_id=LoadSound(#PB_Any,player_statistics\player_defence_object_sound_path,#PB_Sound_Streaming)
     
   Case "PLAYER_SHIELD_SHOW_TIMER"
     player_statistics\player_defence_object_show_time=Val(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD_BAR"
     player_statistics\player_defence_bar_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD_BAR_TRANSPARENCY"
     player_statistics\player_defence_bar_transparency=Val(ReadString(_file_id.i))
     
   Case "PLAYER_DEFENCE_TIMER"
     player_statistics\player_level_defence_timer=Val(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD_BAR_WIDTH"
     player_statistics\player_defence_bar_width=Val(ReadString(_file_id.i))
     
   Case "PLAYER_SHIELD_BAR_HEIGHT"
    player_statistics\player_defence_bar_height=Val(ReadString(_file_id.i)) 
      
     ;---sector of xp multiplactor we use the player.ini
     
   Case "XP_MULTIPLICATOR_START_VALUE"
     e_xp_multiplicator\e_xp_multiplicator=ValF(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_VALUE_ADD"
     e_xp_multiplicator\e_xp_multiplicator_add=ValF(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_VALUE_REDUCE"
     e_xp_multiplicator\e_xp_multiplicator_reduce=ValF(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_TIMER"
     e_xp_multiplicator\e_xp_multiplicator_timer=Val(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_MOVE_Y"
     e_xp_multiplicator\e_xp_multiplicator_text_y_move=ValF(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_MOVE_MAX"
     e_xp_multiplicator\e_xp_multiplicator_text_move_maximum=ValF(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_FONT"
     e_xp_multiplicator\e_xp_multiplicator_font_name=Trim(ReadString(_file_id.i))
     
   Case "XP_MULTIPLICATOR_FONT_SIZE"
     e_xp_multiplicator\e_xp_mutliplicator_font_size=ValF(ReadString(_file_id.i))
     
     
     
   Case "PLAYER_SCREEN_TEXT_MOVE_Y"
     e_player_warning\e_player_warning_text_move_y_counter_step=ValF(ReadString(_file_id.i))
     
   Case "PLAYER_SCREEN_TEXT_MOVE_MAX_Y"
     e_player_warning\e_player_warning_text_move_y_counter_max=ValF(ReadString(_file_id.i))
     
     
     
     
     
     
   Case "PLAYER_AXE_HIT_ENEMY_SOUND"
     player_statistics\player_hit_enemy_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+Trim(ReadString(_file_id.i)),#PB_Sound_Streaming)
     
   Case "PLAYER_AXE_HIT_SOUND_VOLUME"
     player_statistics\player_hit_enemy_sound_volume=Val(ReadString(_file_id.i))
     
   Case "PLAYER_HIT_BY_ENEMY_SOUND"
     player_statistics\player_hit_by_enemy_sound_id=LoadSound(#PB_Any,v_engine_sound_path.s+Trim(ReadString(_file_id.i)),#PB_Sound_Streaming)
     
   Case "PLAYER_INVENTORY_MAX"
     player_statistics\player_inventory_max=Val(ReadString(_file_id.i))
     
   Case "PLAYER_INVENTORY_X"
     player_statistics\player_inventory_pos_x=ValF(ReadString(_file_id.i))
         
   Case "PLAYER_INVENTORY_Y"
     player_statistics\player_inventory_pos_y=ValF(ReadString(_file_id.i))

     
   Case "PLAYER_INVENTORY_SHOW"
     If Val(ReadString(_file_id.i))<>0
       player_statistics\player_inventory_show=#True
     Else
         player_statistics\player_inventory_show=#False
       
     EndIf
     
     

     
   Case "PLAYER_INVENTORY_ITEM_Y_OFFSET"
     player_statistics\player_inventory_item_y_offset=ValF(ReadString(_file_id.i))
     
       Case "PLAYER_INVENTORY_ITEM_X_OFFSET"
         player_statistics\player_inventory_item_x_offset=ValF(ReadString(_file_id.i))
         
       Case "PLAYER_GOLD_TEXT_OFFSET_Y"
         player_statistics\player_gold_text_offset_y=ValF(ReadString(_file_id.i))
         
       Case "PLAYER_GOLD_TEXT_OFFSET_X"
         player_statistics\player_gold_text_offset_x=ValF(ReadString(_file_id.i))
         
         
       Case "PLAYER_GOLD_GUI_GFX"
         player_statistics\player_GUI_gold_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
         
       Case "PLAYER_GOLD_GUI_POS_X"
         player_statistics\player_GUI_gold_pos_x=ValF(ReadString(_file_id.i))
         
         Case "PLAYER_GOLD_GUI_POS_Y"
         player_statistics\player_GUI_gold_pos_y=ValF(ReadString(_file_id.i))
         
       Case "PLAYER_INVENTORY_TEXT_OFFSET_Y"
         player_statistics\player_inventory_text_offset_y=ValF(ReadString(_file_id.i))
         
       Case "PLAYER_INVENTORY_TEXT_OFFSET_X"
          player_statistics\player_inventory_text_offset_x=ValF(ReadString(_file_id.i))
          
        Case "PLAYER_INVENTORY_RASTER_X"
          player_statistics\player_inventory_raster_x=Val(ReadString(_file_id.i))
          
          Case "PLAYER_INVENTORY_RASTER_Y"
            player_statistics\player_inventory_raster_y=Val(ReadString(_file_id.i))
            
          Case "PLAYER_INVENTORY_MAX_OBJECTS_PER_LINE"
            player_statistics\player_inventory_max_objects_per_line=Val(ReadString(_file_id.i))
            
          Case "INVENTORY_BACK_GFX"
               player_statistics\player_inventory_back_banner_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
            
            ;---boss object section-----
            
          Case "BOSS_HEALTH_BAR_X"
            boss_bar\boss_bar_x=Val(ReadString(_file_id.i))
            
          Case "BOSS_HEALTH_BAR_Y"
            boss_bar\boss_bar_y=Val(ReadString(_file_id.i))
            
            Case "BOSS_HEALTH_BAR_FRONT_GFX"
            boss_bar\boss_bar_front_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
          Case "BOSS_HEALTH_BAR_BACK_GFX"
            boss_bar\boss_bar_back_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
          Case "BOSS_BAR_WIDTH"
            boss_bar\boss_bar_size_w=ValF(ReadString(_file_id.i))
            
          Case "BOSS_BAR_HEIGHT"
            boss_bar\boss_bar_size_h=ValF(ReadString(_file_id.i))
            
          Case "BOSS_BAR_DANGER_GFX"
            boss_bar\boss_bar_danger_gfx_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
          Case "BOSS_HEALTH_BAR_COVER"
            boss_bar\boss_bar_cover_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
          Case "BOSS_BAR_COVER_TRANSPARENCY"
            boss_bar\boss_bar_cover_transparency=Val(ReadString(_file_id.i))
            
            
          Case "BOSS_BAR_TEXT_OFFSET_X"
            boss_bar\boss_bar_boss_name_x_offset=ValF(ReadString(_file_id.i))
            
                   Case "BOSS_BAR_TEXT_OFFSET_Y"
            boss_bar\boss_bar_boss_name_y_offset=ValF(ReadString(_file_id.i))
            
         
          Case "PLAYER_FIGHT_SYMBOL"
            player_statistics\player_fight_symbol_paths=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
          Case "PLAYER_FIGHT_SYMBOL_TRANSPARENCY"
            player_statistics\player_fight_symbol_transparency=Val(ReadString(_file_id.i))
            
            
          Case "PLAYER_TORCH_LIGHT"
            player_statistics\player_torch_light_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
          Case "PLAYER_TORCH_LIGHT_TRANSPARENCY"
            player_statistics\player_torch_light_transparency=255-Val(ReadString(_file_id.i))
            
          Case "PLAYER_TORCH_LIGHT_FLICKER"
            player_statistics\player_torch_light_flicker=Val(ReadString(_file_id.i))
            
          Case "BUTTON_SOUND"
             button_sound\button_sound_active=#False
            If Val(ReadString(_file_id.i))>0
              button_sound\button_sound_active=#True  
            EndIf
            
          Case "BUTTON_SOUND_PATH"
            button_sound\button_sound_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
            
            
          Case "PLAYER_MAP_NAME_X"
            player_statistics\player_map_name_offset_x=ValF(ReadString(_file_id.i))
            
          Case "PLAYER_MAP_NAME_Y"
              player_statistics\player_map_name_offset_y=ValF(ReadString(_file_id.i))
              
            Case "PLAYER_NEXT_WORLD_VALUE"
              player_statistics\player_ready_for_new_world_value=Val(ReadString(_file_id.i))  ;actually not used 
        
           
        
              
            Case "PLAYER_AXE_SPEED_MAX"
              player_statistics\player_axe_speed_max=Abs(Val(ReadString(_file_id.i)))
              
            Case "PLAYER_SOUND_ON_FIGHT_VOLUME"
              player_statistics\player_sound_on_fight_volume=Abs(Val(ReadString(_file_id.i)))
              
              
              ;special ....for light effects, i will change this in later build, put it on right place...but now its just for develope and testing
            Case "LIGHT_MASK"
              day_night_cycle\light_mask_source=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
              
            Case "PLAYER_NAME"
              player_statistics\player_name=ReadString(_file_id.i)
              
            Case "PLAYER_FIGHT_TIMER"
              player_statistics\player_fight_timer=Val(ReadString(_file_id.i))
              
            Case "MAP_TIMER_GFX"
              e_map_timer\_map_timer_symbol_gfx_id=LoadImage(#PB_Any,player_statistics\player_core_path+Trim(ReadString(_file_id.i)),0)
              
            Case "MAP_TIMER_GFX_POSITION_Y"
              e_map_timer\_map_time_gfx_pos_y=ValF(ReadString(_file_id.i))
              
            Case "MAP_TIMER_GFX_POSITION_X"
              e_map_timer\_map_time_gfx_pos_x=ValF(ReadString(_file_id.i))
              
            Case "MAP_TIMER_TEXT_POSITION_X"
              e_map_timer\_map_time_text_pos_x=ValF(ReadString(_file_id.i))
              
            Case "MAP_TIMER_TEXT_POSITION_Y"
              e_map_timer\_map_time_text_pos_y=ValF(ReadString(_file_id.i))
              
            Case "MAP_TIMER_FONT"
              e_map_timer\_map_timer_font_name=Trim(ReadString(_file_id.i))
              
            Case "MAP_TIMER_FONT_SIZE"
              e_map_timer\_map_timer_font_size=ValF(ReadString(_file_id.i))
              
            Case "MAP_TIMER_FONT_SIZE_DYNAMIC"
              If Val(ReadString(_file_id.i))>0
                e_map_timer\_map_timer_font_size_dynamic=#True
               EndIf
              
             Case "MAP_TIMER_TEXT_POSITION_FONT_SMALL_X"
               e_map_timer\_map_time_text_position_font_small_x=ValF(ReadString(_file_id.i))
               
               
             Case "MAP_TIMER_TEXT_POSITION_FONT_SMALL_Y"
               e_map_timer\_map_time_text_position_font_small_y=ValF(ReadString(_file_id.i))
               
             Case "PLAYER_SHOW_INFO_AS_GFX"
               player_statistics\player_show_info_as_gfx=Val(ReadString(_file_id.i))
               
               If player_statistics\player_show_info_as_gfx>0
               player_statistics\player_show_info_as_gfx=#True  
               EndIf
               
             Case "PLAYER_GFX_CRITICAL_HIT"
               player_statistics\player_critical_hit_gfx_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
               
             Case "PLAYER_GFX_LEVEL_UP"
               player_statistics\player_level_up_gfx_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
               
             Case "PLAYER_SHOW_HEALTH_SYMBOL"
               player_statistics\player_health_symbol_show=Val(ReadString(_file_id.i))
               If player_statistics\player_health_symbol_show>0
                 player_statistics\player_health_symbol_show=#True 
               Else
                 player_statistics\player_health_symbol_show=#False
               EndIf
               
             Case "PLAYER_HEALTH_SYMBOL_LOCATION"
               player_statistics\player_health_symbol_location=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
               
             Case "PLAYER_HEALTH_SYMBOL_MAX"
               player_statistics\player_health_symbol_max_symbols=Val(ReadString(_file_id.i))
               player_statistics\player_health_symbol_max_symbols_default=player_statistics\player_health_symbol_max_symbols
               
             Case "PLAYER_HEALTH_SYMBOL_POS_X"
               player_statistics\player_health_symbol_pos_x=ValF(ReadString(_file_id.i))
                
                 Case "PLAYER_HEALTH_SYMBOL_POS_Y"
                   player_statistics\player_health_symbol_pos_y=ValF(ReadString(_file_id.i))
                   
                 Case "PLAYER_HEALTH_SYMBOL_OFFSET_X"
                   player_statistics\player_health_symbol_offset_x=ValF(ReadString(_file_id.i))
                   
                 Case "PLAYER_HEALTH_SYMBOL_TRANSPARENCY"
                   player_statistics\player_health_symbol_transparency=255-Val(ReadString(_file_id.i))
                 Case "PLAYER_TORCH_LIGHT_BIG"
                   player_statistics\player_torch_light_big_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
                   
                 Case "PLAYER_TORCH_LIGHT_BIG_TRANSPARENCY"
                   player_statistics\player_torch_light_big_transparency=255-Val(ReadString(_file_id.i))
                   
                 Case "NPC_BUTTON_B_PATH"
                   npc_text\npc_button_B_path=player_statistics\player_core_path+Trim(ReadString(_file_id.i))
                   
                   
                 Case "PLAYER_IN_AIR_TIME_KILL"
                   player_statistics\player_in_air_time_kill=Val(ReadString(_file_id.i))
              
               EndSelect
  

  
             EndProcedure
             
             
       
             

Procedure E_GLOBAL_EFFECTS_INIT_ON_START()
  
  ;here we do some basic settings 
  
  If e_engine\e_true_screen=#True  ;engine is set to hardwarescreen
  ProcedureReturn #False  
  EndIf
  
  
  If stamp_mask_buffer\back_buffer_resize>0
    stamp_mask_buffer\back_buffer_resize=#True
  Else
    stamp_mask_buffer\back_buffer_resize=#False
  EndIf
  
;   




  
  stamp_mask_buffer\back_buffer_id=LoadSprite(#PB_Any,v_engine_base.s+stamp_mask_buffer\back_buffer_path,#PB_Sprite_AlphaBlending)
  
  If IsSprite(stamp_mask_buffer\back_buffer_id)
    
    If stamp_mask_buffer\back_buffer_resize=#True
      stamp_mask_buffer\back_buffer_target_size_x=WindowWidth(#ENGINE_WINDOW_ID)
      stamp_mask_buffer\back_buffer_target_size_y=WindowHeight(#ENGINE_WINDOW_ID)
      ZoomSprite(stamp_mask_buffer\back_buffer_id,stamp_mask_buffer\back_buffer_target_size_x,stamp_mask_buffer\back_buffer_target_size_y)
    EndIf
    
    
  EndIf
  
 

  
  
e_engine_global_effects\global_effect_flash_light_color_RGB=RGB(e_engine_global_effects\global_effect_flash_light_color_R,e_engine_global_effects\global_effect_flash_light_color_G,e_engine_global_effects\global_effect_flash_light_color_B)
  
  
EndProcedure


Procedure E_GLOBAL_EFFECTS_INIT_ON_START_TRUE_SCREEN()
  
  ;here we do some basic settings 
  
  If e_engine\e_true_screen=#False
  ProcedureReturn #False  
  EndIf
  
  
  If stamp_mask_buffer\back_buffer_resize>0
    stamp_mask_buffer\back_buffer_resize=#True
  Else
    stamp_mask_buffer\back_buffer_resize=#False
  EndIf
  


  
  stamp_mask_buffer\back_buffer_id=LoadSprite(#PB_Any,v_engine_base.s+stamp_mask_buffer\back_buffer_path,#PB_Sprite_AlphaBlending)
  
  If IsSprite(stamp_mask_buffer\back_buffer_id)
    
    If stamp_mask_buffer\back_buffer_resize=#True
      stamp_mask_buffer\back_buffer_target_size_x=ScreenWidth()
      stamp_mask_buffer\back_buffer_target_size_y=ScreenHeight()
      ZoomSprite(stamp_mask_buffer\back_buffer_id,stamp_mask_buffer\back_buffer_target_size_x,stamp_mask_buffer\back_buffer_target_size_y)
    EndIf
    
    
  EndIf
  
 



e_engine_global_effects\global_effect_flash_light_color_RGB=RGB(e_engine_global_effects\global_effect_flash_light_color_R,e_engine_global_effects\global_effect_flash_light_color_G,e_engine_global_effects\global_effect_flash_light_color_B)
  
  
EndProcedure




Procedure E_GLOBAL_EFFECTS_PARSER()
  ;_experimentel
  Define _ok.i=1
  Define _key.s=""
  
  If ReadFile(_ok.i,e_engine_global_ini_path.s)
    
    While Not Eof(_ok.i)
      _key.s=ReadString(_ok.i)
      
      Select _key.s
          
        Case "SHADOW_SYSTEM_START"
          e_shadow_dynamic_move_start.f=ValF(ReadString(_ok.i))
          
        Case "SHADOW_SYSTEM_STEP"
          e_shadow_dynamic_move_step.f=ValF(ReadString(_ok.i))
          
        Case "SHADOW_SYSTEM_MAXIMUM"
          e_shadow_dynamic_move_max.f=ValF(ReadString(_ok.i))
          
          
        Case "HIT_BLINK_TIME"
          hit_blink\hit_blink_time_ms=Val(ReadString(_ok.i))
          
        Case "HIT_BLINK_INTENSITY"
          hit_blink\hit_blink_intensity=255-Val(ReadString(_ok.i))
          
        Case "HIT_BLINK_COLOR_R"
          hit_blink\hit_blink_color_r=Val(ReadString(_ok.i))
          
        Case "HIT_BLINK_COLOR_G"
          hit_blink\hit_blink_color_g=Val(ReadString(_ok.i))
          
        Case "HIT_BLINK_COLOR_B"
          hit_blink\hit_blink_color_b=Val(ReadString(_ok.i))
          
        Case "STAMP_BACK_BUFFER_PATH"
          stamp_mask_buffer\back_buffer_path=Trim(ReadString(_ok.i))
  
 
          
        Case "STAMP_BUFFER_TRANSPARENCY"
          stamp_mask_buffer\back_buffer_transparency=255-Val(ReadString(_ok.i))
        Case "STAMP_BUFFER_FULLSCREEN"
          stamp_mask_buffer\back_buffer_resize=Val(ReadString(_ok.i))


             Case "NPC_POP_UP_TEXT_FIELD_SOUND"
               npc_text\npc_text_pop_up_sound_path=v_engine_sound_path.s+Trim(ReadString(_ok.i))
               
             Case "NPC_POP_UP_TEXT_FIELD_SOUND_VOLUME"
               npc_text\npc_text_pop_up_sound_volume=Val(ReadString(_ok.i))
               
             Case "PLAYER_SHOW_XP_BAR"
               If Val(ReadString(_ok.i))>0
                 player_statistics\player_show_xp_bar=#True
               Else
                 player_statistics\player_show_xp_bar=#False
               EndIf
               
             Case "ENGINE_GLOBAL_EFFECT_FLASH_LIGHT_COLOR_R"
               e_engine_global_effects\global_effect_flash_light_color_R=Val(ReadString(_ok.i))
               
               Case "ENGINE_GLOBAL_EFFECT_FLASH_LIGHT_COLOR_G"
                 e_engine_global_effects\global_effect_flash_light_color_G=Val(ReadString(_ok.i))
                 
                 Case "ENGINE_GLOBAL_EFFECT_FLASH_LIGHT_COLOR_B"
                   e_engine_global_effects\global_effect_flash_light_color_B=Val(ReadString(_ok.i))
                   
                 Case "ENGINE_GLOBAL_EFFECT_FLASH_LIGHT_INTENSITY"
                   e_engine_global_effects\global_effect_flash_light_intensity=Val(ReadString(_ok.i))
                   
                 Case "ENGINE_MAP_NAME_POS_X"
                   e_world_info_system\world_info_system_map_name_pos_x=Val(ReadString(_ok.i))
                   
                     Case "ENGINE_MAP_NAME_POS_Y"
                       e_world_info_system\world_info_system_map_name_pos_y=Val(ReadString(_ok.i))
                       
                     Case "ENGINE_MAP_NAME_LINE_OFFSET"
                       e_world_info_system\world_info_system_map_name_line_offset=Val(ReadString(_ok.i))
                       
                     Case "ENGINE_SCREEN_BLEND_SPEED"
                       grab_screen\screen_transparency_change_speed=Abs(ValF(ReadString(_ok.i)))
                       
                     Case "ENGINE_SHAKE_SIZE_HORIZONTAL"
                       e_world_shake\world_shake_base_horizontal=Val(ReadString(_ok.i))
                       
                     Case "ENGINE_SHAKE_SIZE_VERTICAL"
                       e_world_shake\world_shake_base_vertical=Val(ReadString(_ok.i))
                       
                     Case "TIMER_SOUND_PATH"
                       e_engine\e_timer_sound_path=v_engine_sound_path.s+Trim(ReadString(_ok.i))
                       
                     Case "TIMER_SOUND_VOLUME"
                       e_engine\e_timer_sound_volume=Val(ReadString(_ok.i))
                       
                       If e_engine\e_timer_sound_volume>100
                       e_engine\e_timer_sound_volume=100  
                     EndIf
                     
                       If e_engine\e_timer_sound_volume<0
                       e_engine\e_timer_sound_volume=0  
                       EndIf
                       
                     Case "TIMER_SPEED"
                       e_engine\e_timer_speed=Val(ReadString(_ok.i))
                       
                     Case "SGFX_CALCULATION_TIMER"
                       e_engine_build_in_effect\e_sgfx_effect_timer=Val(ReadString(_ok.i))
                       
                     Case "SGFX_MODE_DYNAMIC"
                       e_engine_build_in_effect\e_sgfx_effect_mode=Val(ReadString(_ok.i))
                       
                      
                      

                       
      EndSelect
      
      
    Wend
    
    
    CloseFile(_ok.i)
    
  EndIf
  

  E_SET_UP_EFFECTS_FOR_START()
  E_GLOBAL_EFFECTS_INIT_ON_START()
  E_GLOBAL_EFFECTS_INIT_ON_START_TRUE_SCREEN() 
  

EndProcedure


Procedure E_INIT_BOSS_BAR()
  ;here we go for the boss healthbar
  
  ;here we go for the gfx. other values are set on the fly
  boss_bar\boss_bar_is_valid=#True ;default
  boss_bar\boss_bar_danger_gfx_is_valid=#True  ;default
  boss_bar\boss_bar_front_gfx_id=LoadSprite(#PB_Any,boss_bar\boss_bar_front_path,#PB_Sprite_AlphaBlending)
  boss_bar\boss_bar_back_gfx_id=LoadSprite(#PB_Any,boss_bar\boss_bar_back_path,#PB_Sprite_AlphaBlending)
  boss_bar\boss_bar_cover_gfx_id=LoadSprite(#PB_Any,boss_bar\boss_bar_cover_path,#PB_Sprite_AlphaBlending)
  
  If IsSprite(boss_bar\boss_bar_front_gfx_id)=0
   boss_bar\boss_bar_is_valid=#False 
 EndIf
 
  If IsSprite(boss_bar\boss_bar_back_gfx_id)=0
   boss_bar\boss_bar_is_valid=#False 
  EndIf
  
  boss_bar\boss_bar_danger_gfx_id=LoadSprite(#PB_Any,boss_bar\boss_bar_danger_gfx_path,#PB_Sprite_AlphaBlending)
  
  If IsSprite(boss_bar\boss_bar_danger_gfx_id)=0
    boss_bar\boss_bar_danger_gfx_is_valid=#False 
    
  Else
    
    boss_bar\boss_bar_danger_x=boss_bar\boss_bar_x-SpriteWidth(boss_bar\boss_bar_danger_gfx_id)
    boss_bar\boss_bar_danger_y=boss_bar\boss_bar_y
  EndIf
  
  
  
EndProcedure



Procedure E_INIT_BUTTON_SOUNDS()
  ;here we go for the button sounds we use in menu/options
  
  button_sound\button_sound_id=LoadSound(#PB_Any,button_sound\button_sound_path,#PB_Sound_Streaming)
  
  If IsSound(button_sound\button_sound_id)=0
      button_sound\button_sound_active=#False  ;set it false anyway, because no valid soundfile/path  
  EndIf
  
  
  
EndProcedure

Procedure E_PLAYER_OBJECT_GUI_ACTIVATE_JUMPN_RUN()
  ;here we init ther player gui system
  ;here we also load some bossfight gfx, because it is simple to do it here
  

If IsSprite(player_statistics\player_health_bar_symbol_id)
FreeSprite(player_statistics\player_health_bar_symbol_id)  
EndIf



If IsSprite(player_statistics\player_torch_light_id)
FreeSprite(player_statistics\player_torch_light_id)  
EndIf

player_statistics\player_torch_light_id=LoadSprite(#PB_Any,player_statistics\player_torch_light_path,#PB_Sprite_AlphaBlending)


If IsSprite(player_statistics\player_torch_light_id)
  player_statistics\player_torch_light_is_active=#True
  player_statistics\player_torch_light_height=SpriteHeight(player_statistics\player_torch_light_id)/2
  player_statistics\player_torch_light_width=SpriteWidth(player_statistics\player_torch_light_id)/2
Else
  player_statistics\player_torch_light_is_active=#False 
  
  
EndIf

If player_statistics\player_torch_light_transparency>255
player_statistics\player_torch_light_transparency=255  
EndIf

If player_statistics\player_torch_light_transparency<0
player_statistics\player_torch_light_transparency=0
EndIf

If IsSprite(day_night_cycle\light_mask_id)
FreeSprite(day_night_cycle\light_mask_id )
EndIf

day_night_cycle\light_mask_id=LoadSprite(#PB_Any,day_night_cycle\light_mask_source,#PB_Sprite_AlphaBlending)

If IsSprite(player_statistics\player_critical_hit_gfx_id)
FreeSprite(player_statistics\player_critical_hit_gfx_id)  
EndIf

If IsSprite(player_statistics\player_level_up_gfx_id)
FreeSprite(player_statistics\player_level_up_gfx_id)  
EndIf

player_statistics\player_critical_hit_gfx_id=LoadSprite(#PB_Any,player_statistics\player_critical_hit_gfx_path,#PB_Sprite_AlphaBlending)
player_statistics\player_level_up_gfx_id=LoadSprite(#PB_Any,player_statistics\player_level_up_gfx_path,#PB_Sprite_AlphaBlending)

If IsSprite(player_statistics\player_torch_light_big_id)
FreeSprite(player_statistics\player_torch_light_big_id) 
EndIf

player_statistics\player_torch_light_big_id=LoadSprite(#PB_Any,player_statistics\player_torch_light_big_path,#PB_Sprite_AlphaBlending)

If IsSprite(player_statistics\player_torch_light_big_id)
  player_statistics\player_torch_light_big_width=SpriteWidth(player_statistics\player_torch_light_big_id)/2
  player_statistics\player_torch_light_big_height=SpriteHeight(player_statistics\player_torch_light_big_id)/2
EndIf

If player_statistics\player_torch_light_big_transparency>255
player_statistics\player_torch_light_big_transparency=255  
EndIf

If player_statistics\player_torch_light_big_transparency<0
player_statistics\player_torch_light_big_transparency=0
EndIf

If IsSprite(player_statistics\player_GUI_gold_id)
  FreeSprite(player_statistics\player_GUI_gold_id)  
EndIf


player_statistics\player_GUI_gold_id=LoadSprite(#PB_Any,player_statistics\player_GUI_gold_path,#PB_Sprite_AlphaBlending)

If IsSprite(player_statistics\player_GUI_gold_id)
  player_statistics\player_GUI_gold_height=SpriteHeight(player_statistics\player_GUI_gold_id)
  player_statistics\player_GUI_gold_width=SpriteWidth(player_statistics\player_GUI_gold_id)
EndIf


;---boss bar section
E_INIT_BOSS_BAR()
E_INIT_BUTTON_SOUNDS()

EndProcedure





Procedure E_PLAYER_OBJECT_READ(_file_id.i)
  Define _arg.s=""
  Define _key.s=""
  
  
  While Not Eof(_file_id.i)
    
    _key.s=ReadString(_file_id.i)
     E_PLAYER_OBJECT_GET_VALUE(_file_id.i,_key.s)
    
  Wend
  CloseFile(_file_id.i)
E_PLAYER_OBJECT_GUI_ACTIVATE_JUMPN_RUN()
  
EndProcedure



Procedure E_PLAYER_OBJECT_SETUP()
  Define _file_id.i=0
  
  _file_id.i= ReadFile(#PB_Any,e_engine\e_player_sfgx_ini_path)
    If IsFile(_file_id.i)
      E_PLAYER_OBJECT_READ(_file_id.i)
    Else
      ;fallback 
      E_PLAYER_STATUS_SET_DEFAULT()
  EndIf
    
EndProcedure

Procedure  E_ENGINE_START_VALUES_DEFAULT()
  e_engine_game_type\engine_use_left_barier=#False
  e_engine_build_in_effect\e_sound_disk_drive_play=#False
  e_engine_game_type\engine_use_block_scroll=#False
  e_engine\e_velocity_horizontal_active=#False
  e_engine\e_crt_show=#False
  e_engine\e_gfx_crypto=#True

  
  
 
  
  
  EndProcedure

Procedure E_ENGINE_SETUP(_key.s,_arg.s)
  ;here is the kernel
  ; e_next_world.s="0.worldmap"  ;default if we do not use the "ENTRYPOINT" keyword in the script  (the keyword is used for debugging)
  
  _key.s=Trim(_key.s)
  _arg.s=Trim(_arg.s)
  
  Select _key.s
      
    Case "OSVERSION"

      Select _arg.s
        Case "WIN7"
          e_engine\e_os_min_version=#PB_OS_Windows_7
        Case "WIN8"
          e_engine\e_os_min_version=#PB_OS_Windows_8
        Case "WIN10"
          e_engine\e_os_min_version=#PB_OS_Windows_10
          
          Case "WIN11"
          e_engine\e_os_min_version=#PB_OS_Windows_11
          
        Case "WIN_ANY"
          e_engine\e_os_min_version=#ENGINE_OS_VERSION_ANY
        Default
          
      EndSelect
      
  EndSelect
   
  Select _key.s
   
       
        Case "EXTEND_PROCEDURAL"
         
          e_extended_procedural.b=Val(_arg.s)
          
          If e_extended_procedural.b>0
           
            e_extended_procedural.b=#True  
            
          Else
            e_extended_procedural.b=#False  
          EndIf
     
        Case "VSYNC"
          e_vsync.b=Val(_arg.s)
          
          Select  e_vsync.b
            Case 0
              e_vsync.b=#False
            Default
              e_vsync.b=#True
          EndSelect
          
        Case "SHOW_VERSION_INFO"
          If Val(_arg.s)>0
             e_version_info\map_show_version_info=#True  
          EndIf

      
      
    Case "ENGINE_IS_RUNNING_KEY"
      e_engine_core\core_start_identifier_location=_arg.s
      
    Case "ENGINE_EXTENSION"
      e_engine_custom\custom_extension_core_path=_arg.s
         
    Case "NPC_FONT"
     e_GUI_font\e_GUI_npc_font_name=_arg.s
      
    Case "NPC_FONT_SIZE"
      e_GUI_font\e_GUI_npc_font_size=ValF(_arg.s)
      
    Case "GUI_FONT"
      e_GUI_font\e_GUI_font_name=_arg.s
      
    Case "GUI_FONT_SIZE"
     e_GUI_font\e_GUI_font_size=ValF(_arg.s)
      
    Case "SHOW_GUI_TEXT"
      e_show_gui_text.b=Val(_arg.s)
      
      If e_show_gui_text.b>0
        e_show_gui_text.b=#True
      Else
        e_show_gui_text.b=#False  
      EndIf
      
    Case "INVENTORY_FONT_NAME"
      e_GUI_font\e_GUI_inventory_font_name=_arg.s
      
    Case "INVENTORY_FONT_SIZE"
      e_GUI_font\e_GUI_inventory_font_size=ValF(_arg.s)
      
    Case "INVENTORY_GOLD_FONT_NAME"
      e_GUI_font\e_GUI_gold_font_name=_arg.s
      
    Case "INVENTORY_GOLD_FONT_SIZE"
      e_GUI_font\e_GUI_gold_font_size=ValF(_arg.s)
      
    Case "XP_BAR_FONT_NAME"
      e_GUI_font\e_GUI_xp_font_name=_arg.s
      
    Case "XP_TEXT_FONT_NAME"
      e_GUI_font\e_GUI_xp_text_font_name=_arg.s
      
        Case "XP_TEXT_FONT_NAME_SIZE"
      e_GUI_font\e_GUI_xp_text_font_name_size=ValF(_arg.s)
      
    Case "XP_BAR_FONT_SIZE"
      e_GUI_font\e_GUI_xp_font_size=ValF(_arg.s)
      
    Case "MAP_NAME_FONT"
      e_GUI_font\e_GUI_map_name_font_name=_arg.s
      
    Case "MAP_NAME_FONT_SIZE"
      e_GUI_font\e_GUI_map_name_font_size=ValF(_arg.s)
      
    Case "SCREEN_HEAD_FONT"
      e_GUI_font\e_GUI_screen_head_font=_arg.s
      
    Case "SCREEN_HEAD_FONT_SIZE"
      e_GUI_font\e_GUI_screen_head_font_size=ValF(_arg.s)
      
    Case "DEBUG_FONT_NAME"
      e_GUI_font\e_GUI_debug_font_name=_arg.s
      
    Case "DEBUG_FONT_SIZE"
      e_GUI_font\e_GUI_debug_font_name_size=ValF(_arg.s)
      
    Case "INFO_FONT_NAME"
      e_GUI_font\e_GUI_info_font_name=_arg.s
      
    Case "INFO_FONT_SIZE"
      e_GUI_font\e_GUI_info_font_size=Val(_arg.s)
      
    Case "GFX_FONT_DIRECTORY_DIGIT"
      gfx_font\gfx_font_object_digit_path=v_engine_base.s+Trim((_arg.s))
      
    Case "NPC_TXT"
      e_engine\e_npc_text_path=_arg.s
      
    Case "SHOW_NPC_CORE"
      e_npc_show_core_info.b=Val(_arg.s)
      If e_npc_show_core_info.b>0
      e_npc_show_core_info.b=#True  
      EndIf
      
    Case "USE_DYNAMIC_SHADOW_EFFECT"
      
      e_use_dynamic_shadow_effect.b=#False
      If Val(_arg.s)>0
        e_use_dynamic_shadow_effect.b=#True
      EndIf
      
    Case "USE_SHADOW_GFX"
      e_use_shadow_gfx.b=#False
      If Val(_arg.s)>0
      e_use_shadow_gfx.b=#True  
      EndIf
      
    Case "FONT_DIRECTORY"
      e_font_directory.s=v_engine_base.s+_arg.s

    Case "GRAPHIC_PATH"
      e_engine\e_graphic_source= Trim(_arg.s)
      e_map_gfx_paradise_path.s=e_engine\e_graphic_source
      
    Case "GFX_FOLDER"
      e_engine\e_gfx_folder=Trim(_arg.s)
      
    Case "DISTRIBUTION_PATH"
      e_engine\e_engine_distribution_paths=_arg.s
      
    Case "DISTRIBUTION_FILE_LIST"
      e_engine\e_engine_distribution_file_list=_arg.s
      
      
    Case "ANIM_PATH"
      e_engine\e_animation_source=_arg.s
      
    Case "GRAPHIC_FILES"
     e_engine\e_ai_filter=_arg.s
      
    Case "WORLD_MAP"
      e_engine\e_ai_map_filter=_arg.s
      
    Case "WORLD_SOURCE"
      e_engine\e_world_source=v_engine_base.s+_arg.s
      
    Case "NPC_TEXT_MAXIMUM_ALTERNATIVE"
      e_NPC_maximum_text_alternative.b=Val(_arg.s)
      
    Case "SOUNDPATH"
      v_engine_sound_path.s=v_engine_base.s+_arg.s
      
          Case "SOUND_POOL_PATH"
          e_engine\e_sound_pool_path=v_engine_base.s+_arg.s
      
      
    Case "ENGINE_INTERNAL_SCREEN_W"
      v_screen_w.f=ValF(_arg.s) 
      e_engine\e_world_screen_factor_x= v_win_max_width.f/v_screen_w.f
      e_engine\e_engine_internal_screen_w=ValF(_arg.s)
      
    Case "ENGINE_INTERNAL_SCREEN_H"
      v_screen_h.f=Val(_arg.s)
      e_engine\e_world_screen_factor_y=v_win_max_height.f/v_screen_h.f
      e_engine\e_engine_internal_screen_h=ValF(_arg.s)
      
  
    Case "GFX_PLACE_HOLDER"
      e_engine\e_gfx_place_holder_path=_arg.s
      

      
    Case "QUALITY"
      
      If _arg.s="BEST"
        
        e_engine\e_sprite_quality=#PB_Sprite_BilinearFiltering
     
      Else
        
        e_engine\e_sprite_quality=#PB_Sprite_NoFiltering
        
      EndIf
      
    Case "SILENT_ERROR"
      
           
      If _arg.s= "YES"
        e_engine\e_error_silent_mode=#True
      Else
        e_engine\e_error_silent_mode=#False
      EndIf
      
    Case "SHOW_DEBUG"
      
      If _arg.s="YES"
       e_engine\ e_show_debug=#True
        
      Else
        e_engine\e_show_debug=#False
      EndIf
      
      
    Case "QUESTDONELIST"
          e_quest_done_list.s=_arg.s
          
        Case "CONTROLLER_ONLY_MODE"
          
          e_engine\e_controller_only_mode=Val(_arg.s)
          
          Select e_engine\e_controller_only_mode
              
            Case 0
              e_engine\e_controller_only_mode=#False
              
              
            Case 1
              
             e_engine\e_controller_only_mode=#True
              
          EndSelect
          
      
    Case "BOOTSCREEN"
            v_engine_boot_screen.s=_arg.s

          Case "NO_CONTROLLER"
            e_engine\e_gfx_no_controller_path=_arg.s
            

          Case "ENGINE_BOOT_FILE"
            e_engine\e_entry_point=_arg.s
    
            
          Case "LEFT_MARGIN"
            e_engine\e_left_margin=ValF(_arg.s)
            
          Case "TOP_MARGIN"
            e_engine\e_top_margin=ValF(_arg.s)
            
          Case "RIGHT_MARGIN"
            e_engine\e_right_margin=ValF(_arg.s)
            
          Case "BOTTOM_MARGIN"
            e_engine\e_bottom_margin=ValF(_arg.s)
            
      
    Case "GFXLOAD"
      e_loading_banner_path.s=_arg.s
      
      
    Case "LOAD_ANIM"
      e_engine\e_start_up_load_symbol_paths=_arg.s
    
    Case "ENTRYPOINT"
      e_engine\e_next_world=_arg.s
      e_engine\e_new_game_entry=_arg.s
      
    Case "PLAYER_WIN_WORLD"
      e_world_win_name.s=_arg.s
      
    Case "GLOBAL_SOUND_VOLUME"
    e_engine\e_sound_global_volume=Val(_arg.s)
            
    Case "ENGINE_SERVER_TICKS"  ;with this value we get a value for  interaction / second -> target:  get allways the same interactions/counters per second, if there are 60 frames or 30 frames...or if frames are not limited, we only check each timer the interactions
      
      If Val(_arg.s)>0
        
        e_engine\e_server_ticks=Int(1000/Val(_arg.s))  ;get the  ms for interaction (engine ticks)
        e_engine_heart_beat\heart_rate=e_engine\e_server_ticks*2
      EndIf
 
    
      
    Case "GFXPAUSE"
      e_engine\e_pause_path=_arg.s
     
      
      Case "QUESTSYSTEM"
        e_quest_directory.s=v_engine_base+_arg.s
        
        Case "QUESTLOGIC"
          e_quest_logic_base.s=v_engine_base+_arg.s
          
        Case "INFO_TEXT"
          e_engine\e_info_text_path=v_engine_base+_arg.s
        Case "GFXQUIT"
         e_engine\e_gfx_quit_path=_arg.s
          
        Case "GFXCONTINUE"
          e_engine\e_gfx_continue_path=_arg.s
          
        Case "GFX_DIALOG_POS_X"
        e_engine\e_gfx_position_x=ValF(_arg.s)
          
        Case "GFX_DIALOG_POS_Y"
         e_engine\e_gfx_position_y=ValF(_arg.s)
          
        Case "DIALOG_BANNER"
          e_engine\e_npc_text_field_texture_path=_arg.s
          
        Case "MAP_BANNER"
         e_engine\e_map_name_background_path=_arg.s
         
       Case "GFXGAMEOVER"
         e_gfx_fight_lost_path.s=_arg.s
   
  
     
    Case "TEXT_FIELD_INTENSY"
      e_TEXT_FIELD_INTENSY.i=Val(_arg.s)
      
      
     
      
      
    Case "FULLSCREEN"
      
      
      Select  _arg.s
        Case "YES"
          e_engine\e_fullscreen=#True
                Case "NO"
        
          e_engine\e_fullscreen=#False
          
        Default
           e_engine\e_fullscreen=#True
  
      EndSelect
      
          
      Case "PLAYER_SFX_INI"
        e_engine\e_player_sfgx_ini_path=v_engine_base.s+_arg.s
        
      Case "INTERFACE_SFX_INI"
        e_engine\e_interface_sgfx_ini_path=v_engine_base.s+_arg.s
        
      Case "ENGINE_SNAP_SHOT"
        e_engine\e_save_path=_arg.s
        E_CREATE_USER_ACCOUNT()
        
        
          
        
      Case "GLOBAL_ENGINE_EFFECTS"
        e_engine_global_ini_path.s=_arg.s
     
        
    
        
      Case "OBJECT_LIMIT"
        e_max_interactive_object_in_view.i=Val(_arg.s)
        e_max_interactive_object_in_view_back_up.i=e_max_interactive_object_in_view.i
        
      Case "OBJECT_LIMIT_OVERIDE"
        e_max_interactive_object_in_view_override.i=Val(_arg.s)
        
      Case "BUTTERFLYEFFECT"
        e_engine\e_random_seed=Val(_arg.s)
        
      Case "PLAYER_SAVE_FILE"
        e_engine\e_player_save_file=_arg.s
        
        
      Case "PLAYER_INVENTORY_SNAPSHOT"
        e_inventory_save_file.s=_arg.s
        
      Case "PLAYER_SAVE_PAUSE"
        e_player_save_status_pause.i=Val(_arg.s)*1000  ; 
        
        If e_player_save_status_pause.i>30000 Or e_player_save_status_pause.i<0
        e_player_save_status_pause.i=10000  ;fall back to get a valid pause
        EndIf
        e_player_save_actual_status.i=e_engine_heart_beat\beats_since_start+e_player_save_status_pause.i
        
      Case "PAUSE_ON_RANDOM_ACTION"
        e_pause_for_random_action.i=Val(_arg.s)
        
   
        
         
       Case "WORLDMAP_NAME_SUFFIX"
         e_worldmap_name_suffix.s=_arg.s
         
       Case "WORLD_MAP_HEAD_SUFFIX"
         e_engine\e_world_map_head_suffix=_arg.s
         
       Case "WORLD_MAP_SCROLL_TEXT_SUFFIX"
         e_engine\e_world_map_scroll_text_suffix=_arg.s
         

         Case "DEVIL_MODE_SONG"
          e_sound_song_of_the_night_path.s=v_engine_sound_path.s+_arg.s
          e_sound_song_of_the_night_id.i=LoadSound(#PB_Any,e_sound_song_of_the_night_path.s,#PB_Sound_Streaming)
          If IsSound(e_sound_song_of_the_night_id.i)=0
            E_LOG(e_engine\e_engine_source_element,"DEVIL_MODE_SONG",_arg.s)
          EndIf
          
        Case "DAY_MODE_SONG"
          e_sound_song_of_the_day_path.s=v_engine_sound_path.s+_arg.s
          e_sound_song_of_the_day_id.i=LoadSound(#PB_Any,e_sound_song_of_the_day_path.s,#PB_Sound_Streaming)
          If IsSound(e_sound_song_of_the_day_id.i)=0
            E_LOG(e_engine\e_engine_source_element,"DAY_MODE_SONG",_arg.s)
          EndIf
          
        Case "GFX_NIGHT_AI42_EXTENSION"
          e_night_suffix.s=_arg.s

          
        Case "TIME_TICK_RATE"
          e_world_time\e_world_time_tick=Val(_arg.s)
          If e_world_time\e_world_time_tick<1
          e_world_time\e_world_time_tick=1000  ;realtime !!!! 1000 ms = 1sec  
          EndIf
          
          
          ;default values if new game or first start of the game
          ;if game was saved, this values will be updated by loading the save data
        Case "TIME_START_H"
          e_world_time\e_world_time_start_hour=Val(_arg.s)
          
        Case "TIME_START_M"
          e_world_time\e_world_time_start_minute=Val(_arg.s)
          
        Case "TIME_START_S"
          e_world_time\e_world_time_start_second=Val(_arg.s)
          
        Case "DAY_TIME"
          e_world_time\e_world_time_start_day=Val(_arg.s)
          
        Case "NIGHT_TIME"
          e_world_time\e_world_time_start_night=Val(_arg.s)
          
        Case "MAXIMAL_DAYS_PER_YEAR"
          e_world_time\e_world_time_maximal_days_per_year=Val(_arg.s)
          
        Case "WORLD_TIME_SAVE_PATH"
          e_world_time\e_world_time_save_path=_arg.s
          
         ;------------------------------------------------------------ 
          
          
        Case "GOD_MODE"  ;comment this line for release version
          e_godmode.b=#False
          If Val(_arg.s)>0
            e_godmode.b=#True
          EndIf
          
        Case "USE_STREAM_TIMER"
          e_engine_use_stream_timer.b=Val(_arg.s)
          
          If e_engine_use_stream_timer.b>0
            e_engine_use_stream_timer.b=#True  
          EndIf
          
        Case "STREAM_TIMER_SECONDS"
          e_stream_timer_seconds.i=Val(_arg.s)*1000
          
        Case "DIFFICULTY_SCALER"
          
          If Val(_arg.s)
          e_use_difficulty_scaler.b=#True  
        EndIf
        
      Case "DIFFICUTLY_SCALER_FACTOR"
        player_statistics\player_difficulty_scale_factor=ValF(_arg.s)
        
        If player_statistics\player_difficulty_scale_factor<1
          player_statistics\player_difficulty_scale_factor=1  ;100% full scale!!!!  
        EndIf
        
             
        
      Case "USE_LOCALE"
        
        If Val(_arg.s)<>0
          e_use_locale.b=#True
        Else
          e_use_locale.b=#False
        EndIf
        
      Case "FOV_X"
       e_engine\e_fov_x=ValF(_arg.s)
        
      Case "FOV_Y"
        e_engine\e_fov_y=ValF(_arg.s)
        
      Case "ALLERT_FOV_X"
        e_engine\e_allert_fov_x=ValF(_arg.s)
        
      Case "ALLERT_FOV_Y"
        e_engine\e_allert_fov_y.f=ValF(_arg.s)
        
              
    Case "GFX_FOV"
      e_gfx_fov.f=ValF(_arg.s)
      

      Case "RESURECTION_MAP"
        e_resurection_map.s=Trim(_arg.s)
        
 
        
      Case "MAP_NAME_SHOW"
        If Val(_arg.s)<>0
          e_map_name_show.b=#True  
        Else
          e_map_name_show.b=#False
        EndIf

      
    Case "ENGINE_SHOW_INFO_TIMER"
      
      If Val(_arg.s)>0
        e_engine_show_info_timer.i= Val(_arg.s)
        
     EndIf
      
      
    Case "INVENTORY_LEGACY_MODE"
      e_engine_inventory_legacy_mode.b=#False
      If Val(_arg.s)=1
        e_engine_inventory_legacy_mode.b=#True
      EndIf

    
    Case "MAP_NAME_TRANSPARENCY"
      If Val(_arg.s)>0 And Val(_arg.s)<256
        e_engine\e_world_map_name_banner_transparency=Val(_arg.s)
      EndIf
      
    Case "ENGINE_MODE"
      
      Select _arg.s
          
        Case "DEVELOPE"
          e_engine\e_engine_status=  #E_DEVELOPER_MODE
          
       
          
          
        Default 
 e_engine\e_engine_status=  #E_GAME_MODE
 
 
 
 
      EndSelect
      
       Case "ENGINE_CREATE_DISTRIBUTION"
          e_engine\e_engine_create_distribution=Val(_arg.s)
      
    Case "DISK_READ_SOUND"
      e_engine_build_in_effect\e_sound_disk_drive_path=v_engine_sound_path.s+_arg.s
      
   
    Case "DISK_READ_SOUND_USE"
     
      
      If Val(_arg.s)<>0
        e_engine_build_in_effect\e_sound_disk_drive_play=#True
      EndIf
      
    Case "PATCH_FILE"
      file_integrity\patch_file_list_path=v_engine_base.s+_arg.s
      
      
    Case "GLOBAL_LIGHT_SAVE_PATH"
      e_engine\e_global_light_data_file=Trim(_arg.s)
      
      
      
      Case "SHOW_DONATION_REQUEST"
        Select _arg.s
            
          Case "YES","yes","Yes","YeS","yEs"
             e_show_donation_request.b=#True
            
          Default
            e_show_donation_request.b=#False
        EndSelect
        
      
    Case "USE_LOAD_ICON"
      e_engine\e_engine_use_load_icon=#False
      If Val(_arg.s)>0
      e_engine\e_engine_use_load_icon=#True  
      EndIf
      
    Case "COMPANION_FILE"
      e_engine\e_companion_save_file=_arg.s
      
      
    Case "INTERPRETER_TRIGGER"
      e_engine\e_interpreter_trigger_string=_arg.s
      
    Case "INFO_TEXT_X"
      e_version_info\version_inf_x=ValF(_arg.s)
      
    Case "INFO_TEXT_Y"
       e_version_info\version_inf_y=ValF(_arg.s)
      
    Case "USE_VIRTUAL_BUFFER"
      e_engine\e_use_virtual_buffer=Val(_arg.s)
      If e_engine\e_use_virtual_buffer>0
        e_engine\e_use_virtual_buffer=#True
      Else
        e_engine\e_use_virtual_buffer=#False
      EndIf
      
      
    Case "BRIGHTNESS"
      e_engine\e_brightnes=Val(_arg.s)
      
    Case "COLORNESS"
      e_engine\e_colorness=Val(_arg.s)
      
    Case "GRAY_SCALE_MODE"
      If Val(_arg.s)>0
        e_engine\e_show_gray_scale=#True
      Else
        e_engine\e_show_gray_scale=#False
      EndIf
      
      
    Case "TEMPORAL_DIRECTORY"
      e_engine\e_temp_directory=_arg.s  ;not used 

      
    Case "VKEY_SYSTEM"
      ;v_key_input_field\input_field_location=_arg.s
      
    Case "ENGINE_WORLD_MODE"
      e_engine_game_type\engine_mode_is_world_mode=Val(_arg.s)
      
    Case "ENGINE_JUMP_AND_RUN_MODE"
      e_engine_game_type\engine_mode_is_jump_and_run=Val(_arg.s)
      
    Case "ENGINE_GRAVITY_DEFAULT"
      e_engine_game_type\engine_gravity=ValF(_arg.s)
      
    Case "ENGINE_USE_BARIER_LEFT"
      
      If Val(_arg.s)>0
      e_engine_game_type\engine_use_left_barier=#True  
      EndIf
      
    Case "ENGINE_USE_BLOCK_SCROLL"
          
      If Val(_arg.s)>0
      e_engine_game_type\engine_use_block_scroll=#True  
      EndIf
      
    Case "ENGINE_BLOCK_SIZE_X"
      e_engine_game_type\engine_block_size_x=ValF(_arg.s)
      
        Case "ENGINE_BLOCK_SIZE_Y"
      e_engine_game_type\engine_block_size_y=ValF(_arg.s)
      
    Case "ENGINE_COLLISION_TYPE_PIXEL"
      
      If Val(_arg.s)>0
      e_engine\e_engine_collision_type_pixel=#True  
      EndIf
      
    Case "ENGINE_INFO_TEXT_TIME"
      e_ingame_info_text\show_time=Val(_arg.s)
      
      
    Case "MAP_NAME_START_SHOW_TIMER"
         e_engine\e_map_name_start_show_timer=Val(_arg.s)

      
    Case "TRUE_SCREEN"
      If Val(_arg.s)>0
        e_engine\e_true_screen=#True
      Else
       e_engine\e_true_screen=#False
      EndIf
      
      
    Case "ENGINE_HORIZONTAL_VELOCE"
      e_engine\e_velocity_horizontal_active=Val(_arg.s)
      
      If e_engine\e_velocity_horizontal_active>0
      e_engine\e_velocity_horizontal_active=#True  
      EndIf
      
      
    Case "ENGINE_VERTICAL_VELOCE"
      e_engine\e_velocity_vertical_active=Val(_arg.s)
      If e_engine\e_velocity_vertical_active>0
      e_engine\e_velocity_vertical_active=#True  
    EndIf
    
  Case "SILUETTE_SUFFIX"
    e_engine\e_siluette_suffix=_arg.s
    
    
  Case "LAUNCHER"
    
    Select Val(_arg.s)
        
      Case #False
        
        e_engine\e_use_launcher=#False
        
      Case #True
        
        e_engine\e_use_launcher=#True
        
      Default
        
        e_engine\e_use_launcher=#True
        
    EndSelect
    
  Case "LAUNCHER_HAND_SHAKE"
    e_engine\e_launcher_hand_shake=_arg.s
    
    
  Case "NPC_SPEACH_TO_TEXT_FILE_TYPE"
    npc_text\npc_speach_output_file_type=_arg.s
    
    
  Case "NPC_SPEACH_SET_GLOBAL_VOLUME"
    npc_text\npc_speach_set_global_volume=Val(_arg.s)
    
    
  Case "FRAME_TARGET"
    e_engine\e_frame_target=Val(_arg.s)
    
    
  Case "CONTROLLER_SUFFIX"
    e_xbox_controller\controller_suffix=_arg.s
    
  Case "FULL_INTRO"
    e_engine\e_full_intro=Val(_arg.s)
    
  Case "MAP_TITLE_WAIT_FADE_OUT"
    e_engine\e_map_title_wait_for_fade_out=Val(_arg.s)
    
  Case "FOV_AUTO"
    e_engine\e_fov_auto=Val(_arg.s)
    
  Case "BORDER_TOP"
    e_engine\e_border_top=Val(_arg.s)
    
  Case "BORDER_BOTTOM"
    e_engine\e_border_bottom=Val(_arg.s)
    
  Case "BORDER_RIGHT"
    e_engine\e_border_right=Val(_arg.s)
    
  Case "BORDER_LEFT"
    e_engine\e_border_left=Val(_arg.s)
    
  Case "USE_SCREEN_BORDER"
    e_engine\e_use_screen_border=Val(_arg.s)
    
      Case "ISO_MODE"
      e_engine\e_iso_mode=Val(_arg.s)
    
    
    
  Case "SHOW_CRT"
    If Val(_arg.s)>0
      e_engine\e_crt_show =#True
    EndIf
    
  Case "CRT_SOURCE"
    e_engine\e_crt_gfx_id_source=_arg.s
    
  Case "CRT_EFFECT"
    e_engine\e_crt_effect_level=Val(_arg.s)
    
  Case "CRT_EFFECT_NOISE"
    e_engine\e_crt_effect_noise=Val(_arg.s)
    
  Case "CRT_SCAN_LINE"
    e_engine\e_crt_scan_line=Val(_arg.s)
    
  Case "SAVE_PICTOGRAM"
    e_engine\e_save_pictogram_file=Trim(_arg.s)
    
    
  Case "MAKE"
    e_engine\e_make_distribution=Val(_arg.s)
    
  Case "MAKE_SUFFIX"
    e_engine\e_make_suffix=_arg.s
    
  EndSelect
  
  
  
EndProcedure




Procedure E_PARSE_INI_FILE(_file_id.i)
  ;here we parse the ini file 
  
  Define  _key.s=""
  Define  _arg.s=""
  
  
  While Not Eof(_file_id.i)
    _key.s=Trim(ReadString(_file_id.i))
    _arg.s=Trim(ReadString(_file_id.i))
    E_ENGINE_SETUP(_key.s,_arg.s)
  Wend
  
  
  EndProcedure


Procedure  E_PARSE_BASE(_p.s)
  ;here we read all basic information for the engine
  Define _file_id.i=0
  e_map_timer\_map_timer_font_size_dynamic=#False
  e_engine\e_fov_auto=#False
 
 _file_id.i= ReadFile(#PB_Any,_p.s)
 
 If IsFile(_file_id.i)
    E_PARSE_INI_FILE(_file_id.i)
    CloseFile(_file_id.i)  
    If e_engine\e_fov_auto>0
    e_engine\e_fov_auto=#True  
    EndIf
 
    If e_engine_heart_beat\heart_rate<1
    e_engine_heart_beat\heart_rate=1 ;how you dare!  
    EndIf
    e_engine_heart_beat\heart_rate=e_engine\e_server_ticks*2
    E_SETUP_DEFAULT_START_TIME()
    If e_engine\e_engine_create_distribution>0
    e_engine\e_engine_create_distribution=#True  
    EndIf
    If e_engine\e_make_distribution>0
    e_engine\e_make_distribution=#True  
    EndIf
    e_engine\e_save_pictogram_path=v_engine_base.s+e_engine\e_graphic_source
    
EndIf
   
  EndProcedure
  


; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 441
; FirstLine = 411
; Folding = ---
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant