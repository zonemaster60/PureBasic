


Declare E_SORT_MAP_OBJECTS_BY_LAYER()
;Declare E_INVENTORY_OBJECT_DATA_PARSER()
Declare E_PLAYER_STATUS_SET_DEFAULT()
Declare E_PLAYER_STATUS_SAVE(_mode.i)
Declare E_PLAYER_STATUS_LOAD(_mode.i)
Declare E_SET_UP_SCREEN_SHOT_SYSTEM_FOR_SAVE()
Declare E_CREATE_SCREEN_SHOT_FOR_SAVE_POINT() 


  

Procedure E_SET_UP_VERSION_DEBUG()
  ;here e check for developement, if this version is new or old,
  ;if this version id> stored, we clean the save homedirectory, so the game starts with the first map/titlescreen
  
EndProcedure




Procedure E_SAVE_GAME_MODE()
  ;EASY,NORMAL,HARD
  Define _ok.i=0
  Define _file_name.s="core.inf"
  
  _ok.i=CreateFile(#PB_Any,e_engine\e_save_path+_file_name.s)
  
  If IsFile(_ok.i)=0
    ProcedureReturn #False
  EndIf
  
  WriteStringN(_ok.i,Str(e_engine\e_engine_game_mode))
  
  CloseFile(_ok.i)
  
EndProcedure


Procedure E_LOAD_GAME_MODE()
  ;EASY,NORMAL,HARD
  Define _ok.i=0
  Define _file_name.s="core.inf"
  
  _ok.i=ReadFile(#PB_Any,e_engine\e_save_path+_file_name.s)
  
  If IsFile(_ok.i)=0
    ProcedureReturn #False
  EndIf
  
  e_engine\e_engine_game_mode=Val(ReadString(_ok.i))
  
  CloseFile(_ok.i)
  
  
EndProcedure






Procedure E_CLEAN_SNAPSHOT_DIRECTORY()
  ;this routine will delete worldmap files from our savedirectory
  ;so we start at the beginning of the last map, if we lost our last "heard"
  Define _file_id.i=0
  Define _directory.i=0
  
  _directory.i=ExamineDirectory(#PB_Any,e_engine\e_save_path,"*")
  
  While NextDirectoryEntry(_directory.i)
    If DirectoryEntryType(_directory.i)=#PB_DirectoryEntry_File 
      DeleteFile(e_engine\e_save_path+DirectoryEntryName(_directory.i))
    EndIf
    
  Wend
  FinishDirectory(_directory.i)
  

EndProcedure


Procedure E_NEW_OR_CONTINUE()
  ;check which startscreen we use:
  
  Define _file_id.i=0
  Define _dummy.s=""
  e_engine\e_map_is_from_save_dir=#False
  
  E_UNPACK_CREATE_LOCATION_LOAD(e_engine\e_save_path+"COMPASS")  
  
  _file_id.i=ReadFile(#PB_Any,e_engine\e_save_path+"COMPASS")
  
  If IsFile(_file_id.i)
    _dummy.s=ReadString(_file_id.i)
    
    If Len(_dummy.s)>1
      
      If _dummy.s="dummy_reload" Or _dummy.s="reload.worldmap"
      
       e_continue_game_entry.s="intro.worldmap"
       e_engine\e_map_is_from_save_dir=#True
         
      Else
        e_continue_game_entry.s=_dummy.s
        e_engine\e_map_is_from_save_dir=#True
      EndIf
      
      e_engine\e_game_status=#CONTINUE
      e_engine\e_map_is_from_save_dir=#True
    Else
      e_engine\e_game_status=#NEW  
      E_PLAYER_STATUS_SET_DEFAULT()
      E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
      E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
       
    EndIf
    
   
      
    ;--------------------------------------------------------------------
    
       
    CloseFile(_file_id.i)
  
  
  EndIf
  
    If e_engine\e_engine_create_distribution=#False
      ProcedureReturn #False  
    EndIf
    
  
  DeleteFile(e_engine\e_save_path+"COMPASS")
    
EndProcedure


Procedure E_SET_AFTER_FINAL_DEAD()
  
  
  
  ;used for continuesystem
  Define  _file_id.i=0
  ;we use this if all heards a used, so we have to start all new.....
  ;If e_engine\e_actuall_world<>"intro.worldmap"  And e_engine\e_actuall_world<>"reload_final_map" And e_engine\e_actuall_world <>"credit.worldmap" ;intro map is used for start of the game, so we do not have to use it as "last Map", its always the first maps
    
    _file_id.i=CreateFile(#PB_Any,e_engine\e_save_path+"COMPASS")
    
    If IsFile(_file_id.i)
      WriteString(_file_id.i,e_engine\e_new_game_entry)
      CloseFile(_file_id.i)
      E_PACK_CREATE_LOCATION_SAVE(e_engine\e_save_path+"COMPASS")
    EndIf
    
  
  
EndProcedure

Procedure E_SET_NEW_START_FOR_JUMPN_RUN_MAP()
  ;used for continuesystem
  Define  _file_id.i=0
  ;we use this if all heards a used, so we have to start all new.....
  ;If e_engine\e_actuall_world<>"intro.worldmap"  And e_engine\e_actuall_world<>"reload_final_map" And e_engine\e_actuall_world <>"credit.worldmap" ;intro map is used for start of the game, so we do not have to use it as "last Map", its always the first maps
    
    If e_map_no_respawn=#True Or e_engine\e_actuall_world="reload_final_map"
    ProcedureReturn #False  
    EndIf
   
    _file_id.i=CreateFile(#PB_Any,e_engine\e_save_path+"COMPASS")
    
    If IsFile(_file_id.i)
      WriteString(_file_id.i,e_engine\e_new_game_entry)
      CloseFile(_file_id.i)
      E_PACK_CREATE_LOCATION_SAVE(e_engine\e_save_path+"COMPASS")
    EndIf
    
  ;EndIf
  
EndProcedure


Procedure E_SET_LAST_MAP()
  ;used for continuesystem
  Define  _file_id.i=0
  
  ;If e_engine\e_actuall_world<>"intro.worldmap"  And e_engine\e_actuall_world<>"reload_final_map" And e_engine\e_actuall_world <>"credit.worldmap" ;intro map is used for start of the game, so we do not have to use it as "last Map", its always the first maps
    
    If e_map_no_respawn=#True Or e_engine\e_actuall_world="reload_final_map"
    ProcedureReturn #False  
    EndIf
    
    _file_id.i=CreateFile(#PB_Any,e_engine\e_save_path+"COMPASS")
    
    If IsFile(_file_id.i)
      WriteString(_file_id.i,e_engine\e_actuall_world)
      CloseFile(_file_id.i)
      E_PACK_CREATE_LOCATION_SAVE(e_engine\e_save_path+"COMPASS")
    EndIf
    
  ;EndIf
  
EndProcedure




Procedure E_PLAYER_STATUS_SET_GOD_MODE()

    ;godmode for demo, testing and debugging: (for thorin quest and awakening)
player_statistics\player_health_actual=10
player_statistics\player_health_max=10
player_statistics\player_xp_actual=0
player_statistics\player_xp_max=100
player_statistics\player_level=0
player_statistics\player_level_defence_max=10
player_statistics\player_level_fight=1000
;player_statistics\player_gold=0  ;not used for jumpnrun
player_statistics\player_xp_count_to_zero=0
player_statistics\player_weapon_axe=#True
player_statistics\player_weapon_shield=#True
player_statistics\player_ready_for_new_world=#False
player_statistics\player_difficulty_scale=1
player_statistics\player_has_companion=#False
player_statistics\player_gold_in_chamber=10000
player_statistics\player_axe_speed_base=1
player_statistics\player_axe_speed_max=5
player_statistics\player_game_mode=#PLAYER_GAME_MODE_NORMAL
player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols_default
player_statistics\player_health_symbol_max_symbols=player_statistics\player_health_symbol_max_symbols_default
e_quest_xp.f=0
EndProcedure



Procedure E_PLAYER_STATUS_SET_DEFAULT()
;for now e use a simple solution, just let it do... (for final release replace/extend this solution with a more secure and crypted one)
player_statistics\player_health_actual=10
player_statistics\player_health_max=10
player_statistics\player_xp_actual=0
player_statistics\player_xp_max=100
player_statistics\player_level=1
player_statistics\player_level_defence_max=10
player_statistics\player_level_fight=10
player_statistics\player_gold=0
player_statistics\player_xp_count_to_zero=0
player_statistics\player_difficulty_scale=1
player_statistics\player_ready_for_new_world=#False 
player_statistics\player_weapon_axe=0
player_statistics\player_weapon_shield=0
player_statistics\player_has_companion=#False
player_statistics\player_gold_in_chamber=0
player_statistics\player_axe_speed_base=1
player_statistics\player_axe_speed_max=1 ;change this for default maximum speed
player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols_default
player_statistics\player_health_symbol_max_symbols=player_statistics\player_health_symbol_max_symbols_default
;player_statistics\player_game_mode=#PLAYER_GAME_MODE_NORMAL
e_quest_xp.f=0
EndProcedure

Procedure E_PLAYER_STATUS_SET_DEFAULT_FOR_CONTINUE_AFTER_DEAD()
;for now e use a simple solution, just let it do... (for final release replace/extend this solution with a more secure and crypted one)
player_statistics\player_health_actual=10
player_statistics\player_health_max=10
player_statistics\player_xp_actual=0
player_statistics\player_xp_max=100
player_statistics\player_level=1
player_statistics\player_level_defence_max=10
player_statistics\player_level_fight=10
player_statistics\player_gold=0
player_statistics\player_xp_count_to_zero=0
player_statistics\player_difficulty_scale=1
player_statistics\player_ready_for_new_world=#False 
player_statistics\player_weapon_axe=0
player_statistics\player_weapon_shield=0
player_statistics\player_has_companion=#False
player_statistics\player_gold_in_chamber=0
player_statistics\player_axe_speed_base=1
player_statistics\player_axe_speed_max=1 ;change this for default maximum speed
; player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols_default
;player_statistics\player_health_symbol_max_symbols=player_statistics\player_health_symbol_max_symbols_default
;player_statistics\player_game_mode=#PLAYER_GAME_MODE_NORMAL
e_quest_xp.f=0
EndProcedure





















Procedure.s E_GET_COMPANION_INFO()
  ;work around /fix for companion not present if map is changed....
  
  Define _ok.i=0
  Define _val.s=""
  
  If player_statistics\player_has_companion=#False
    ProcedureReturn ""
  EndIf
  
 
  _ok.i=ReadFile(#PB_Any,e_engine\e_save_path+e_engine\e_companion_save_file)
  
  If _ok.i=0
    ProcedureReturn ""
  EndIf
  
  _val.s=ReadString(_ok.i)
  
    CloseFile(_ok.i)
  ProcedureReturn _val.s
  
  
EndProcedure











Procedure E_PLAYER_STATUS_SAVE(_mode.i)
  ;here we save player releated data, like HP, inventory, magic, level....
  Define _ok.i=0

   
  
  
  If  player_statistics\player_health_symbol_actual_symbol<1
     ProcedureReturn #False
  EndIf
  
    
      _ok.i=OpenFile(#PB_Any,e_engine\e_save_path+e_engine\e_player_save_file)
    
      If IsFile(_ok.i)=0
      ProcedureReturn #False  
      EndIf
      
      ;for now e use a simple solution, just let it do... (for final release replace/extend this solution with a more secure and crypted one)
    
      WriteStringN(_ok.i,Str(player_statistics\player_gold))
      WriteStringN(_ok.i,Str(player_statistics\player_has_companion))
      WriteStringN(_ok.i,Str(player_statistics\player_health_symbol_actual_symbol))
      WriteStringN(_ok.i,Str(player_statistics\player_health_symbol_max_symbols))
      WriteStringN(_ok.i,Str(player_statistics\player_weapon_axe))
      WriteStringN(_ok.i,Str(player_statistics\player_level_fight))
      CloseFile(_ok.i)
      
      If e_engine\e_engine_create_distribution=#False
      ProcedureReturn #False  
      EndIf
      
      
      Select _mode.i
          
        Case #ENGINE_SAVE_MODE_PACK
        E_PACK_CREATE_PLAYER_SAVE_PACK(e_engine\e_save_path+e_engine\e_player_save_file)
      
          
      EndSelect
      
          
          
  
 EndProcedure
 
 
 
 
 Procedure E_PLAYER_STATUS_LOAD(_mode.i)
  ;here we save player releated data, like HP, inventory, magic, level....
   
   
   
   
  Define _ok.i=0
  Define _dummy.s=""
  Define _val.i=0
  
  If e_godmode.b=#True
    E_PLAYER_STATUS_SET_GOD_MODE()
    ProcedureReturn #False
  EndIf
  
  
  Select _mode.i
      
      Case #ENGINE_SAVE_MODE_PACK
       E_UNPACK_CREATE_PLAYER_SAVE(e_engine\e_save_path+e_engine\e_player_save_file)  
     
  EndSelect
  
  
  
  
  
  _ok.i=ReadFile(#PB_Any,e_engine\e_save_path+e_engine\e_player_save_file)
  
   ;player_statistics\player_ready_for_new_world=#False
  
  If IsFile(_ok.i)

    player_statistics\player_gold=Val(ReadString(_ok.i))
    ;player_statistics\player_xp_count_to_zero=ValF(ReadString(_ok.i))  ;if system crashed and we start with a questdone map, all of our xp will count!
    
   ; player_statistics\player_weapon_shield=Val(ReadString(_ok.i))
    player_statistics\player_has_companion=Val(ReadString(_ok.i))
   ; player_statistics\player_gold_in_chamber=Val(ReadString(_ok.i))
    player_statistics\player_health_symbol_actual_symbol=Val(ReadString(_ok.i))
    player_statistics\player_health_symbol_max_symbols=Val(ReadString(_ok.i))
    player_statistics\player_weapon_axe=Val(ReadString(_ok.i))
    player_statistics\player_level_fight=Val(ReadString(_ok.i))
    CloseFile(_ok.i)

    player_statistics\player_difficulty_scale=1 ;not used
  
    Else
    
      E_PLAYER_STATUS_SET_DEFAULT()
    
    EndIf
    
    
    ;if we use compressor (some sort of cheatprotection...)
    
    Select _mode.i
      Case #ENGINE_SAVE_MODE_PACK
        DeleteFile(e_engine\e_save_path+e_engine\e_player_save_file)
    EndSelect
    
  
EndProcedure
 
 

  








Procedure E_SAVE_RESPAWN_WORLD(_val.s)
  

 
  
  ;now we try to save the mess:
  Define  _ok.i=0
  Define wc_quest_book.i=0
  
  
  ;keep it here?

  
  ;-----
  
  If ListSize(world_object())<1
  ProcedureReturn  #False
  EndIf
  
  
  _ok.i=CreateFile(#PB_Any,e_engine\e_save_path+_val.s)
  
  
  If  IsFile(_ok.i)=0
  ProcedureReturn #False  
  EndIf
  
   
    E_SAVING_SCREEN(#False)
    
    WriteStringN(_ok.i,"*********************************************************************************************************")
    WriteStringN(_ok.i,"WORLD MAP CREATOR FILE : GENERATED BY -WORLDMAP CREATOR- TOOL ")
    WriteStringN(_ok.i,"DEUTSCHMANN WALTER (DEUTSCHMANN DEVELOPEMENT) ALL RIGHTS RESERVED")
    WriteStringN(_ok.i,"DO NOT CHANGE CONTENTS OF FILE, THIS MAY HARM SYSTEM AND APP STABILITY")
    WriteStringN(_ok.i,"MAP OBJECTS: ")
    WriteStringN(_ok.i,Str(ListSize(world_object()) ))
    WriteStringN(_ok.i,"*********************************************************************************************************")
    WriteStringN(_ok.i,"WORLD_VIEW_W")
    WriteStringN(_ok.i,StrF( v_screen_w.f))
    WriteStringN(_ok.i,"WORLD_VIEW_H")
    WriteStringN(_ok.i,StrF( v_screen_h.f))
    WriteStringN(_ok.i,"WORLD_START:"); keyword for io system to read map file startign with next position in skript file
    WriteStringN(_ok.i,"WORLD_GLOBAL_SOUND")
    WriteStringN(_ok.i,e_global_sound_full_path.s) ;for mapcreator we use full path of sound
    WriteStringN(_ok.i,"DAY_NIGHT_INTENSE_MAX")
    WriteStringN(_ok.i,Str(day_night_cycle\light_intensity_max))
    WriteStringN(_ok.i,"DAY_NIGHT_INTENSE_MIN")
    WriteStringN(_ok.i,Str(day_night_cycle\light_intensity_min))
    WriteStringN(_ok.i,"DAY_NIGHT_INTENSE_ACTUAL")
    WriteStringN(_ok.i,Str(day_night_cycle\light_intensity_actual))
    WriteStringN(_ok.i,"USE_AUTO_LAYER")     ;here we store the autolayer function
    WriteStringN(_ok.i,"0")
    WriteStringN(_ok.i,"OFFSETX:")
    WriteStringN(_ok.i,Str(e_engine\e_world_offset_x))
    WriteStringN(_ok.i,"OFFSETY:")
    WriteStringN(_ok.i,Str(e_engine\e_world_offset_y))
    WriteStringN(_ok.i,"SHOW_VERSION_INFO")
    WriteStringN(_ok.i,Str( e_version_info\map_show_version_info))
    WriteStringN(_ok.i,"MAP_AUTO_SWITCH_TIMER")
    WriteStringN(_ok.i,Str(e_map_timer\_map_time))
    WriteStringN(_ok.i,"SWITCH_MAP")
    WriteStringN(_ok.i,e_map_timer\_next_map)
    WriteStringN(_ok.i,"SWITCH_MAP_ON_TRIGGER")
    WriteStringN(_ok.i,Str(e_engine\e_switch_map_on_trigger))
    WriteStringN(_ok.i,"MAP_SHOW_TIMER")
    WriteStringN(_ok.i,Str(e_engine\e_world_show_timer))
    WriteStringN(_ok.i,"MAP_USE_BLACK_STAMP")
    WriteStringN(_ok.i,Str(e_engine\e_map_use_black_stamp))
    WriteStringN(_ok.i,"SCROLL")
    WriteStringN(_ok.i,Str(e_engine\e_engine_scroll_map))
    WriteStringN(_ok.i,"WORLD_GLOBAL_EFFECT")
    WriteStringN(_ok.i,e_engine_global_effects\global_effect_name)
    WriteStringN(_ok.i,"WORLD_SHOW_SCROLL_TEXT")
    WriteStringN(_ok.i,Str(e_engine\e_map_show_scroll_text))       
    WriteStringN(_ok.i,"MAP_SHOW_GUI")
    WriteString(_ok.i,Str(e_engine\e_map_show_gui))
 
                  

    WriteStringN(_ok.i,"MAP_CAN_PAUSE")
    If e_map_can_pause_id=#False
      WriteStringN(_ok.i,"NO")
    Else
      WriteStringN(_ok.i,"YES")
    EndIf
    
    WriteStringN(_ok.i,"MAP_USE_RESPAWN")
    If e_map_no_respawn.b=#True
      WriteStringN(_ok.i,"NO")
    Else
      WriteStringN(_ok.i,"YES")
    EndIf
    
    WriteStringN(_ok.i,"MAP_FIGHT")
    Select e_engine\e_map_mode_fight
        
      Case #True
        WriteStringN(_ok.i,"YES")
        
      Case #False
        
        WriteStringN(_ok.i,"NO")
        
      Default 
       WriteStringN(_ok.i,"YES")
        
        
    EndSelect
    
         
    WriteStringN(_ok.i,"MAP_USE_QUEST_SYSTEM")
    WriteStringN(_ok.i,Str(e_map_use_quest_system.b))
    WriteStringN(_ok.i,"MAP_DAY_TIMER")
    WriteStringN(_ok.i,Str(e_map_use_daytimer.b))
    
    WriteStringN(_ok.i,"MAP_IS_ARENA")
    
    Select e_engine\e_world_map_is_arena_map
      Case #True
        WriteStringN(_ok.i,"YES")
        
      Default
        
        WriteStringN(_ok.i,"NO")
    EndSelect
    
    WriteStringN(_ok.i,"MAP_AUTO_RANDOM_LOOT_DONE")
    WriteStringN(_ok.i,Str(e_engine\e_map_auto_loot_done))
    
    
    ResetList(world_object())
    
 ForEach world_object()
      
   If world_object()\object_do_not_save=#False
        WriteStringN(_ok.i,"NEXTELEMENT:")
        WriteStringN(_ok.i,"OBJECTSOURCE:")
        WriteStringN(_ok.i,GetFilePart(world_object()\object_ai_path))
        WriteStringN(_ok.i,"OBJECT_X:")
        
        If world_object()\object_use_position_back_up=#True
          WriteStringN(_ok.i,Str(world_object()\object_origin_position_x))
          Else        
          WriteStringN(_ok.i,Str(world_object()\object_x))
        EndIf
        
       
        
        WriteStringN(_ok.i,"OBJECT_Y:")
        
   
        
           If world_object()\object_use_position_back_up=#True
          WriteStringN(_ok.i,Str(world_object()\object_origin_position_y))
          Else        
          WriteStringN(_ok.i,Str(world_object()\object_y))
        EndIf
        WriteStringN(_ok.i,"OBJECTLAYER:")
        WriteStringN(_ok.i,Str(world_object()\object_layer))
        WriteStringN(_ok.i,"OBJECT_W:")
        WriteStringN(_ok.i,Str(world_object()\object_w))
        WriteStringN(_ok.i,"OBJECT_H:")
        WriteStringN(_ok.i,Str(world_object()\object_h))
        
        If world_object()\object_full_screen<>0
          WriteStringN(_ok.i,"FULLSCREEN:")
          WriteStringN(_ok.i,Str(world_object()\object_full_screen))
        EndIf
        
     
        
        
      EndIf  ;save it?
      
      
    Next  
    
    WriteStringN(_ok.i,"QUESTBOOK_CHAPTERS")
    WriteStringN(_ok.i,Str(player_statistics\player_quest_size))  ;actual questsize, just a simple modus for simple questsystem
    
    CloseFile(_ok.i)
    
     ;
     
e_engine\e_engine_reset_object_position=#False

  
EndProcedure



Procedure E_SET_STATUS_AFTER_GAME_OVER()
  ;here we start the game with new maps,initial data,... delete the snapshots:
  Define _file_id.i=0
  Define _directory.i=0
  
  
  If e_godmode.b=#True
  ProcedureReturn #False  
  EndIf
  
  _directory.i=ExamineDirectory(#PB_Any,e_engine\e_save_path,e_engine\e_ai_map_filter)
  
  While NextDirectoryEntry(_directory.i)
    If DirectoryEntryType(_directory.i)=#PB_DirectoryEntry_File 
      DeleteFile(e_engine\e_save_path+DirectoryEntryName(_directory.i))
    EndIf
    
  Wend
  FinishDirectory(_directory.i)
  
  If player_statistics\player_gold>20
    player_statistics\player_gold-20
  Else
    player_statistics\player_gold=0
  EndIf
  
  E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
  
   If e_godmode.b=#True
    ProcedureReturn #False
  EndIf
  
  If player_statistics\player_gold<1
      e_engine\e_game_status=#NEW  
      E_PLAYER_STATUS_SET_DEFAULT_FOR_CONTINUE_AFTER_DEAD()
      E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
      E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
      E_SET_AFTER_FINAL_DEAD()  ;after all gold and heards are consumed, we start from the vey beginning....
  EndIf
  
  
EndProcedure


Procedure E_CHECK_FOR_RESPAWN_AREA()
  
  
  
  If e_map_no_respawn.b=#True
     ProcedureReturn #False ;jump out if no respawn area, we go for the origin map
  EndIf
    E_SAVE_RESPAWN_WORLD(e_engine\e_actuall_world) ;save actual status, before we leave map/area
    E_PLAYER_STATUS_SAVE(#ENGINE_SAVE_MODE_PACK)
    E_SAVE_WORLD_TIME()

 EndProcedure
  
  
  

  Procedure E_SEARCH_FOR_RESPAWN_MAP(_world.s)
    
    ;if map was already created with procedural system, we go and find it
    
    Define _work_file.s=e_engine\e_save_path+_world.s
    Define _dir.i=0
    Define _name.s=""
    
    e_map_status_is_respawn.b=#False ;we need this for the procedural system, we do not create new objects on already final/respawn build map
    
    
    _dir.i=ExamineDirectory(#PB_Any,e_engine\e_save_path,"**")
    
    If IsDirectory(_dir.i)
      
      While NextDirectoryEntry(_dir.i)
        
        _name.s=DirectoryEntryName(_dir.i)
        
        If DirectoryEntryType(_dir.i)=#PB_DirectoryEntry_File
          If _name.s=_world.s
            FinishDirectory(_dir.i)
            e_map_status_is_respawn.b=#True  ;we need this for the procedural system, we do not create new objects on already final/respawn build map
            ProcedureReturn #True  
          EndIf
        EndIf
        
      Wend
      
      FinishDirectory(_dir.i) 
      
    EndIf
    
    
    
  EndProcedure

; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 351
; FirstLine = 347
; Folding = ---
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant