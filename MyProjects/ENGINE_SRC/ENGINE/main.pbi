;******************************************** Information **************************
;Original Code & Concept
;Deutschmann Walter (Mark Dowen)
;https://mark-dowen.itch.io/

;202103192224
;world maps with name part: nrsp are no respawn maps, this maps are hubs for further expansions, this maps do not save any progress, because they are some kind of hub maps
;no respawn hub maps can be exptended with new entry points for new world maps
;first no respawn hubmap is : 1_nrsp.worldmap, this map is activated after the dragon is free, so we can expand the game using this central/main map 
;so we can build new entry points for new quests and new worlds, for expansion of the story, after complete the main story
;20210926
;Now the engine gets some extensions to create jump and runs

;26112021
;attackanim does not work, so do not set the attackanim switch for objects in the ai42 creator 

;06062023
;fully gfx encryption/decryption mode: for PNG files
;cache mode (default)
;just in time (implemented manually) deactivate cache mode!

EnableExplicit ;use only declared variables

XIncludeFile "const.pbi"
XIncludeFile "system.pbi"
XIncludeFile "var.pbi"
XIncludeFile "worldvar.pbi"
XIncludeFile "fundament.pbi"
XIncludeFile "math.pbi"
XIncludeFile "engine_core_error_handling.pbi"
XIncludeFile "xbox_controller.pbi"
XIncludeFile "input.pbi"
XIncludeFile "aiobjects.pbi"
XIncludeFile "file_integrity_manager.pbi"
XIncludeFile "extension.pbi" 
XIncludeFile "timer_core.pbi"
XIncludeFile "error.pbi"
XIncludeFile "develope_core.pbi"
XIncludeFile "map_info_system.pbi"
XIncludeFile "interpreter.pbi"
XIncludeFile "parser.pbi"
XIncludeFile "launcher.pbi"
XIncludeFile "io_gui.pbi"
XIncludeFile "network.pbi"
XIncludeFile "secu_pack.pbi"
XIncludeFile "soundsystem.pbi"
XIncludeFile "simple_ai.pbi"
XIncludeFile "stream_handler.pbi"
XIncludeFile "player_include.pbi"
XIncludeFile "npc_text_system.pbi"
XIncludeFile "respawn.pbi"
XIncludeFile "grab_screen.pbi"
XIncludeFile "sgfx.pbi"
XIncludeFile "terraformer.pbi"
XIncludeFile "text.pbi"
XIncludeFile "alternative_object.pbi"
XIncludeFile "dialog.pbi"
XIncludeFile "arcade_adventure_display.pbi"
XIncludeFile "arcade_game_input_logic.pbi"
XIncludeFile "physic_simple.pbi"
XIncludeFile "classic_adventure_core_engine_control.pbi"
XIncludeFile "createworld.pbi"

E_ENGINE_START_VALUES_DEFAULT()
E_PARSE_BASE(v_engine_base.s+v_engine_basic_path)
e_version_info\version_info_text=""+Year(Date())+Month(Date())+Day(Date())+Hour(Date())+Minute(Date())+"GAME VERSION: PROTOTYPE ALPHA "+" Engine Version:"+StrF((#PB_EDITOR_BUILDCOUNT),4)
E_ENGINE_USER_SETTINGS()
E_PARSE_BASE(v_engine_base+engine_launcher\launcher_prefs_base) ;overwrite some defaults
;E_CHECK_CORE_INTEGRITY()
E_SEARCH_FILES_FOR_PACK()
E_ENGINE_CHECK_MINIMUM_REQUIREMENT()
E_INIT_INPUT_DEVICE(e_engine\e_controller_only_mode)
E_Open_Display_True_Screen(v_win_x,v_win_y,1,1,v_display_name)
E_Open_Display_WIN(v_win_x,v_win_y,1,1,v_display_name) 
E_Open_Display_WIN_MAX(v_win_x,v_win_y,1,1,v_display_name) 
E_SETUP_BOOT_SCREEN()
E_SHOW_BOOT_SCREEN()
E_SET_UP_GAME_DIRECTORY(v_temp_directory.s); the core routine for all gfx decoding/copying!!!!
E_GLOBAL_EFFECTS_PARSER()
E_LOAD_GAME_MODE()
E_INIT_CRT()
E_LOAD_CRT_EFFECT()
SpriteQuality(e_engine\e_sprite_quality) ;script value from parser routine
    ;----------------------

If e_engine\e_os_min_version<>#ENGINE_OS_VERSION_ANY
If e_engine\e_os_version<e_engine\e_os_min_version
  If MessageRequester("Engine Information:"," Wrong (OLD) OS Version Detected"+Chr(13)+"          "+Chr(13)+" Starting  Engine With Other (OLDER) OS Than Expected.",#PB_MessageRequester_Ok)
  EndIf
EndIf
EndIf

E_LOG_INIT()

;here we set the screen margins:

;defaults:
; e_left_margin.f=300
; e_top_margin.f=200
; e_bottom_margin.f=300
; e_right_margin.f=500
e_game_screen_height.f=v_screen_h.f* e_engine\e_world_screen_factor_x
e_screen_v_center.f=v_win_max_height-(v_screen_h.f*e_engine\e_world_screen_factor_x)
e_screen_v_center.f=e_screen_v_center.f/2
;---------------------------------- here we go for the dpi ----------------------------
;v_win_max_width=v_win_max_width
; e_game_screen_height.f=e_game_screen_height.f
; v_screen_center_w=v_screen_center_w
; v_screen_center_h=v_screen_center_h
; v_win_max_height.f=v_win_max_height
;--------------------------------------------------------------------------------------

E_CORE_ENV()
E_PLAYER_OBJECT_SETUP()
E_REGISTER_FONT()
E_ENGINE_LOAD_FONT()

E_LOCALE_OVERRIDE(e_use_locale.b)

E_INIT_GFX_FONT_DIGIT()
E_GUI_GFX_SETUP()
       
       ; E_DATA_INTEGRITY(e_map_gfx_paradise_path.s,e_map_gfx_devil_path.s,"*.png")
     
     ;here we go for the start of the game (startscreen ,Continue/New/options/Exit)
     e_engine\e_next_world=e_engine\e_entry_point ; hard coded game entrypoint
        ;------------------------------------------------
    
     ;-----------------------------------------------------------
     E_CUSTOM_MSG_REQUESTER_INIT(e_engine_custom\custom_extension_core_path)
     E_SET_UP_VERSION_DEBUG() ;used for developement, not final product
     E_GET_WORLD_DATA()  
     ;-------------------------------------------------
     E_PLAYER_SYMBOLS_HEALTH_ADD()
     player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols
     player_statistics\player_name=Mid(UserName(),1,FindString(UserName()," ")-1);default!
     E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
     
     ;delete the bootscreen gfx, free the memory:
   
      e_engine_fresh_start.b=#True
          
     E_INIT_DAY_NIGHT_SYSTEM()
     E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND()
     E_CHECK_FOR_XBOX_JOYSTICK()
     
     Procedure E_WORLD_DESTINY()
         ;some specials we try, to keep a random, but in some way static procedural openworld
      
       If e_engine\e_random_seed>0 
         RandomSeed(e_engine\e_random_seed)
        EndIf

     EndProcedure
       
     ;--------------------------------------
         
     Procedure E_NO_RESPAWN_CLEAN_UP(e_actuall_world.s)
       
       ;delete maps, wich are no respawn maps, so they are alway set to start situation if reentered
       
       If e_map_no_respawn.b=#True
         If DeleteFile(e_engine\e_save_path+e_actuall_world.s)
         Else
           ProcedureReturn #False 
         EndIf
         
       EndIf      
       
     EndProcedure
        
     Procedure E_SET_INITIAL_MAP_DATA()
       
       boss_bar\boss_bar_is_active=#False
       boss_bar\boss_bar_is_true=#False
       player_statistics\player_is_level_up=#False
       player_statistics\player_debug_weapon_active=#False
            
       ;show a basic info if map changed
       e_engine\e_map_status=#MAP_NOT_DEFINED
       e_engine\e_error_count=0
       e_engine\e_error_detected=#False ;flip flo
       e_engine\e_actuall_world=e_engine\e_next_world
       ;----------------------------------------------------------
      
       e_engine\e_loot_activate_object_in_map=#False
       e_engine\e_map_auto_loot_done=#False
       e_version_info\map_show_version_info=#False
       e_engine\e_world_show_timer=#False
       e_engine\e_map_use_black_stamp=#False ;set to  this value #false !!!!!!!, only true for testing!, value is set by map data!
       e_engine\e_map_use_fog_of_war=#False   ;set to false, #true is for debugging only
       e_engine\e_count_active_boos_guards=0
       e_map_timer\_map_time=0
       e_map_timer\_map_time_stop=0
       e_map_timer\_next_map=""
       e_engine\e_map_show_scroll_text=#False
       e_world_info_system\world_info_system_map_screen_name=""
       e_engine\e_npc_text_field_show=#False
       
       
       e_map_use_quest_system.b=#False  ;default
       e_map_no_respawn.b=#False        ;default, we can respawn every map, changed by mapfile
       e_map_can_pause_id.b=#True       ;default, changed by mapfile
                                        ;here we have the right list entry: (if no map found, we use the last map in the list)
       e_quest_xp.f=0                   ;on start we do not have any quest related xp, changed by  map.
       e_engine\e_map_mode_fight=#True
       e_gate_to_open_name.s="NOGATE"  
       e_engine\e_player_auto_move_direction_x=#NO_DIRECTION
       e_engine\e_player_auto_move_direction_y=#NO_DIRECTION
       e_engine_global_effects\global_effect_name=""
       e_engine\e_day_night_overide=#WORLD_DAY_NIGHT_NOT_DEFINED
       e_engine\e_enemy_count=0
       e_engine\e_change_emitter_is_active=#False      
       
     EndProcedure
        
     Procedure E_ENGINE_GAME_DEFAULTS()
       ;basic game defaults for engine,including startup/entrypoint
       
       e_ingame_info_text\r=255
       e_ingame_info_text\g=255
       e_ingame_info_text\b=0
       
       If e_engine\e_map_title_wait_for_fade_out>0
         e_engine\e_map_title_wait_for_fade_out=#True
       EndIf
            
       Select e_engine\e_full_intro
           
         Case #False
           
           e_engine\e_next_world="start.worldmap" ;the intro starts here!(short intro, fast start) for debugging
           
         Case #True
           e_engine\e_next_world="ready_for_inject.worldmap"  ;the intro starts here! (full intro!), for release
           
         Default
           e_engine\e_next_world="ready_for_inject.worldmap" ;the intro starts here! (full intro!), for release
           
       EndSelect
             
     EndProcedure
       
     Procedure E_NEW_MAP_START_UP_DATA()
       ;all data used to make actual loaded map working:     
       
       e_clear_inventory.b=#False
       
       ;some settings for infosystem:
       ;this infos are timebased:
       e_map_name_show_on_screen=e_engine_heart_beat\beats_since_start+e_map_name_show_timer.i
       e_show_play_field=#True  ;used as fix, if no procedural system is in use
       e_map_timer\_map_time_stop=e_engine_heart_beat\beats_since_start+e_map_timer\_map_time
       e_engine_global_effects\global_effect_flash_light_status=#FLASH_LIGHT_OFF
       e_engine_global_effects\global_effect_global_light_status=#GLOBAL_LIGHT_OFF ;default, is switched on by special tile...
       e_engine_world_control\use_global_scroll=#True
       e_engine\e_engine_time_slice_actual_time=e_engine_heart_beat\beats_since_start
       e_engine\e_scroll_object_id=0 ;restart the scroll object id
       e_engine\e_scroll_left_border=0-e_engine\e_engine_internal_screen_w
       player_statistics\player_pos_x=0  
       player_statistics\player_pos_y=0
       e_engine\e_engine_boss_object_kill_switch=#False ;for debug/develope
       e_engine\e_do_start_screen_shot=#True
       e_engine\e_crypto_io_counter=0
       e_engine\e_crypto_io_counter_fail=0
             
;        ;!!!!this is for demo version!!!!:
;       e_engine\e_game_status=#NEW  
;       e_engine\e_engine_demo=#True
;     
     EndProcedure    
     
     Procedure E_CHANGE_ROOM(e_next_world.s)
       
       e_engine\e_start_position_screen_shot_taken=#False
       E_NO_RESPAWN_CLEAN_UP(e_engine\e_actuall_world)
       E_GARBAGE_COLLECTOR()
       
       Define _ok.i=0,_found.b=#False
       
       E_SET_INITIAL_MAP_DATA()
       E_NEW_OR_CONTINUE()  ;deactivate for debugging,  so we can jump directly to the map we are working on
                            ;E_CHECK_FOR_XBOX_JOYSTICK()
       E_LOADING_SCREEN(#False)
       E_WORLD_DESTINY()
       ;E_PLAYER_STATUS_LOAD(#ENGINE_SAVE_MODE_PACK)
       ;E_INIT_INPUT_FIELD(v_key_input_field\input_field_location)
       
       ResetList(pool_map())
       ForEach pool_map()  
         
         If pool_map()\_name=e_next_world.s
           _found.b=#True
           Break   
         EndIf
         
       Next
            
       If _found.b=#False
         E_ERROR_MAP(#E_ERROR_MAP_NOT_FOUND)
         ResetList(pool_map())
         ProcedureReturn #False
       EndIf
       
       e_engine\e_map_name=pool_map()\_name
       e_engine\e_siluette_path=e_engine\e_world_source+e_engine\e_map_name+"."+e_engine\e_siluette_suffix
       E_SILUETTE_PARSER()
       E_STREAM_BUILD_WORLD(e_engine\e_map_name)     
;        
;        If e_engine\e_error_detected=#True
;          _ok.i=MessageRequester("!ATTENTION! ****ENGINE INFORMATION*****","*****ERRORS DETECTED******"+Chr(13)+"NOT ALL MAP ELEMENTS LOADED"+Chr(13)+"CHECK:"+e_engine\e_log_file_path,#PB_MessageRequester_Ok)
;        EndIf
       
       e_engine\e_map_status=#MAP_RUNNING  ;default
       e_engine\e_reaper_on_screen=#False
       E_SET_LAST_MAP()
       E_GET_MAP_NAME()
       E_GET_MAP_SCREEN_NAME()
       E_SOUND_PLAY_GLOBAL_SOUND()
       E_NEW_MAP_START_UP_DATA()
       E_AI_RESET()
       If e_engine\e_map_title_wait_for_fade_out=#True
       e_engine\e_wait_for_map_title=#True 
       EndIf
       
     EndProcedure  

     If  e_engine\e_controller_only_mode=#False
       
       ; _ok.l=MessageRequester("KEYBOARD ERROR:"," Cant find  keyboard ?"+Chr(13)+" [ENTER] TO ACTIVATE KEYBOARD",#PB_MessageRequester_Ok)
       
       If InitKeyboard()
         KeyboardMode(#PB_Keyboard_International)  ;we use the layout of the region  
         
         v_keyboard_present.b=#True  
         e_engine\e_controller_only_mode=#False
       Else
         e_engine\e_controller_only_mode=#True
         
       EndIf
       
     EndIf
        
     E_ENGINE_GAME_DEFAULTS()
     
     ;for debugging and  develope:
     e_engine\e_next_world="dummy.worldmap"    ;we hav eto use this here, because of the crypting, so savedata is not editable!
     ;---   

     Repeat
       
       If e_engine\e_actuall_world<>e_engine\e_next_world
         E_CHANGE_ROOM(e_engine\e_next_world)
       EndIf
       
       E_INTERACTION_CORE()
       E_SHOW_PLAY_FIELD()    ;default
                              ;here we handle all screen/window resolution and display output situations
       
     ForEver
          
     End

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 154
; FirstLine = 127
; Folding = --
; Optimizer
; DPIAware
; UseIcon = disk.ico
; Executable = arcade_demo_src.exe
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; Compiler = PureBasic 6.03 beta 1 LTS - C Backend (Windows - x64)
; EnableCompileCount = 4340
; EnableBuildCount = 1400
; EnableExeConstant