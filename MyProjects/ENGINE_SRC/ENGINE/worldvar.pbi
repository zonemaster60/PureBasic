;variables and constants for the world creation

;

;----------------------------------------------------------------------------------

Global e_shadow_y_offset.f=8 ;static for developement 
Global e_global_player_x.f=0
Global e_global_player_y.f=0
Global e_game_screen_height.f=1
Global e_screen_v_center.f=1
;Global e_do_anim.b=#False 
Global e_play_music.b=#True
;here we try a frame controlsystem  (max 60 frames per seconds)
;Global e_global_fps.i=0
;Global e_frame_base.i=0  ;ElapsedMS+e_frame_time
;Global e_server_ticks.i=60  ;engine server ticks

;-----animation system :

Global e_complete_anim_path.s=""

;-----------------------------------------------------------------

;global soundsystem:

Global e_global_sound_full_path.s=""


;Global e_sound_global_volume.i =50  ;default if no sound volume is found in script
Global e_sound_channel.i=0
;-------------------------------------------------------


;some vars for internal memory handling:
Global e_memory_used.i=0

;here we try some screen fps control:
Global e_max_fps.i=0  ;if 0 max fps of system, else max fps = value
Global e_max_fps_ticker.i=0 ; if 0 max fps of system, else max fps = value
;

Global e_parent_direction_x.i=#NO_DIRECTION
Global e_parent_direction_y.i=#NO_DIRECTION
;----------------------------------------

Global e_key.i  ;used for some inkey opersations so we can  setup for : A, SPACE  = action  (e_key.i=#ACTION if A or Space key is pressed.....)

;****************************************************************
;working on stream technology
Global e_engine_stream_map.b=#False
Global e_dummy_for_all.b  ;a variable used for debugging

;------------------------------------------------------- save system --------

;Global e_save_path.s=""
Global e_user_account_id.b=#False 
;some vars for continue or new game settings:
Global e_continue_game_entry.s=""

;some extras:
Global e_idle_time.i=5000
Global e_idle_time_before_input_check.i=e_idle_time.i
Global e_reconnection_idle_time.i=1000
Global e_idle_for_reconnection.i=e_reconnection_idle_time.i
Global e_loading_banner_path.s=""
Global e_loading_banner_gfx_valid.b=#False
Global e_last_status_music.b=#True

Global e_last_map_backup.s=""
Global e_player_move_direction_x.i=#NO_DIRECTION
Global e_player_move_direction_y.i=#NO_DIRECTION

;Global e_controller_only_mode.b=#False  ;default ---> for release and official test builds

;***********************************for the fight screen:*************************************

Global e_player_actual_hp.f=0
Global e_player_max_hp.f=0


;here we try the conversation s window
Global e_quest_level.i=0
Global e_quest_directory.s=""
Global e_quest_logic_base.s=""




;some global help variables for the realtime fight system:



Global e_player_weapon_path_ai42.s=""
Global e_fight_timeout.i=0
Global e_fight_timeout_player.i=0
;Global *e_weapon_id=0

;Global *e_back_up_list_object_id=0  ;used for multiple back up  and restore operations for the list system
Global e_map_map_back_up_for_going_back.s=""
Global e_map_can_pause_id.b=#True ;default
Global e_map_no_respawn.b=#False  ;default =#false  



Global e_TEXT_FIELD_INTENSY.i=255 ;default if no script
Global e_map_use_quest_system.b=#False
Global e_quest_done_list.s="" ; here we store the quests done (map names), we use this to control which map to load after quest done, and the map to load if quest area is left.
Global e_NPC_maximum_text_alternative.b=0 ;default = 1 Textoption
   ;default, we use direct HDD reading for gfx/sound, can be changed in ini


Global e_max_interactive_object_in_view.i=10 ;for developement, value will be set in script or set to 0 for unlimited objects

Global e_map_use_daytimer.b=#True ;default (map script controlled)

Global e_use_dynamic_shadow_effect.b=#False 
Global e_use_shadow_gfx.b=#False  
Global e_shadow_dynamic_move_start.f=0.1  ;
Global e_shadow_dynamic_move_max.f=10
Global e_engine_global_ini_path.s="" ;nothing? is initialised by ini script
Global e_shadow_dynamic_move_step.f=0
;default,  we use this at the beginning of the terraformer routine, so we need one call (if objewct changed)instead of multiple calls
Global e_auto_save_system_timer.i=10000  ;autosave every 10 seconds (can be changed in script)
Global e_fatal_error_text.s="SORRY USER, FATAL ERROR, ENGINE CAN NOT FIND ANY MAP DATA. PRESS [C] TO QUIT"
Global e_fatal_error.b=#False
Global e_map_status_is_respawn.b=#False
Global e_show_play_field.b=#False  ;used for procedural system...show map if its already build
Global e_show_FPS.b=#False
Global e_godmode.b=#False  ;default use STRG+G to switch (for developement, and debugging)
Global e_vsync.b=#True     ;default
Global e_extended_procedural.b=#False
Global e_health_bar_change.i=0  ;if <>player health we redraw the healthbar
;Global e_player_save_file.s=""
Global e_inventory_save_file.s=""
Global e_health_bar_show.b=#True ;default 
Global e_player_save_status_pause.i =10000 ; default, so player can use save function every 10sec, not permanent, or in very short intervalls, used to keep system stable (maybe there could be problems for database?)
Global e_player_save_actual_status.i=0     ;
Global e_actual_xp.f=0
Global e_quest_xp.f=0  ;use for quest done xp system 
Global e_npc_show_core_info.b=#False  ;set to #true (script) if you want to display the used sourcefile for npc text , its easier for debuggingreasons if you want add text to npc
Global e_npc_debugging_dummy_text_var.s=""
Global e_gfx_fight_lost_path.s=""
Global e_gfx_fight_lost_x.f=0
Global e_gfx_fight_lost_y.f=0
Global e_game_pause_song_path.s=""
Global e_refresh_gui.b=#False
Global e_show_gui_text.b=#True ;default
Global e_gate_to_open_name.s="NO_GATE"
Global e_toggle_shadow.i=0
Global e_world_win_name.s=""  ;stores the name of the world for player win screen
Global e_next_world_back_up.s="" ;is used in combination with winworld, so we can exchange nextworld - winworld
Global e_max_interactive_object_in_view_back_up.i=0
Global e_pause_for_random_action.i=5000  ;default... we calculate random situations with a pause,
Global e_pause_for_random_action_actual_time.i=0

Global e_global_spawn_timer_loot.i=5000  ;try it? not implement yet
Global e_crypt_key.f=0
Global e_need_gold.i=0
Global e_default_world.s="endofworld.worldmap"
Global e_max_interactive_object_in_view_override.i=0
Global e_show_donation_request.b=#True ;default we show the donation website
Global e_clear_inventory.b=#False      ;do not clear the inventory with the garbage collector, only if game is started as "NEW GAME"
Global e_engine_fresh_start.b=#True    ;indicator to inject the saved inventory object on player position,to the world 
Global e_worldmap_name_suffix.s=""
Global e_map_gfx_paradise_path.s=""  ;store the paradise MOD path
Global e_map_gfx_devil_path.s=""
Global e_sound_song_of_the_night_id.i
Global e_sound_song_of_the_night_path.s=""
Global e_sound_song_of_the_day_id.i
Global e_sound_song_of_the_day_path.s=""
Global e_game_mode.i=#GAME_MODE_DAY  ;default
Global e_night_suffix.s=""
Global e_ai42_suffix.s=""
Global e_day_time.i=1 ;default in minutes  (calculation= e_daytime.l=e_daytime.l*60sec*1000ms)
Global e_day_night_switch.i=e_day_time.i
Global e_world_status.i=#WORLD_STATUS_DAY
Global e_day_night_clock_segment_angle.f=360/24  ;default earth like time. used to rotate the sun/moon disk
Global e_day_night_clock_position.f=0
Global e_engine_use_stream_timer.b=#False ;default we stream and refresh realtime if out of sight
Global e_stream_timer_seconds.i=0
Global e_use_difficulty_scaler.b=#False ;default we do not scale the enemy hp with player level
Global e_local.s=""  ;get the local information (language?)



;Global e_scroll_text_is_valid.b=#False
Global e_scroll_text_move_x.f=0 ;default
Global e_scroll_text_move_y.f=1 ;default
Global e_scroll_text_start_x.f=450  ;default
;Global e_scroll_text_start_y.f=700;default
Global e_scroll_text_start_backup_y.f=700 ;default
Global e_gold_show.b=#False
Global e_font_directory.s


Global e_show_minimum_frames.b =#False ; debug
Global e_use_locale.b=#True            ;default we support multilingual output, automatic detection by system language


Global e_resurection_map.s=""
Global e_last_world_before_dead.s=""
Global e_MAP_info_font_name.s="TimesNewRoman" ;default
Global e_MAP_info_font_size.f=11              ;default
Global e_map_name_show.b=#False
Global e_map_name_show_timer.i=10000       ;default, use script to change it
Global e_map_name_show_on_screen.i=0;ElapsedMilliseconds()+e_map_name_show_timer.i  ;default  rest the value at position you need
Global e_day_night_changed.b=#False                                               ;for the stream system, we keep some objects (bosses) with their actual data if day night changed 
Global e_xp_text_rgb.i=RGB(255,255,255)   ;default, use this for some optical GUI specials
Global *e_sprite_back_up=0
Global *thread_engine_object=0

Global e_gfx_fov.f=0
Global e_engine_controller_timer.i=10000  ;seconds, default value hardcoded for developement/debugging, change it with script
Global e_engine_show_info_timer.i=5000    ;default (bootscreen delay) use ini script to set new value (0......x)
Global e_switch_plane.b=#True             ;used for specials like teleport, we switch the buffer afetr all is drawn....
Global e_engine_inventory_legacy_mode.b=#False






;--- engine _structure (NEW)

Structure e_engine
  *e_pointer_sound_boss
  e_border_top.i
  e_border_bottom.i
  e_border_left.i
  e_border_right.i
  e_use_screen_border.b
  e_iso_mode.b
  e_start_up_load_symbol_paths.s
  e_start_up_load_symbol_gfx_id.i
  e_temp_core.s
  e_animation_source.s
  e_sound_boss_sound_volume.i
  e_use_launcher.b
  e_launcher_hand_shake.s
  e_map_show_gui.b
  e_start_playfield.i
  e_map_name.s
  e_siluette_active.b
  e_siluette_intensity.i
  e_siluette_suffix.s
  e_siluette_path.s
  e_siluette_R.i
  e_siluette_G.i
  e_siluette_B.i
  e_siluette_RGB.i
  e_siluette_file_id.i
  e_engine_map_ground.i             ;the overall variable for the layer of map object. we use this for some effects (put objects to the ground layer)
  e_error_count.i
  e_anim_valid.b                    ;true if anim frames false if no animframes (wrong animframedirectory, wrong settings...) we show the default gfx
  e_day_night_overide.i
  e_day_night_backup.i
  e_shadow_color_r.i
  e_shadow_color_g.i
  e_shadow_color_b.i
  e_xp_value.i
  e_allert_fov_x.f
  e_allert_fov_y.f
  e_engine_reset_object_position.b
  e_loot_activate_object_in_map.b
  e_water_effect_size_x.f
  e_water_effect_size_y.f
  e_external_tool_id.i
  e_controller_only_mode.b
  e_server_ticks.i
  e_scroll_text_start_y.f
  e_scroll_text_is_valid.b
  e_frame_base.i
  e_engine_mode.b
  e_loading_banner_id.i
  e_gfx_pause_id.i
  e_gfx_position_x.f
  e_gfx_position_y.f
  e_gfx_pause_valid.b
  e_gfx_continue_id.i
  e_gfx_quit_valid.b
  e_gfx_continue_valid.b
  e_gfx_quit_path.s
  e_gfx_continue_path.s
  e_gfx_show_pause.b 
  e_gfx_no_controller_path.s
  e_gfx_no_controller_id.i
  e_game_status.i
  e_engine_game_mode.i
  e_engine_object_last_layer.i
  e_engine_collision_type_pixel.b
  e_engine_scroll_map.b
  e_engine_no_scroll_margin.f
  e_engine_input_mode.i
  e_world_map_head_suffix.s
  e_world_map_scroll_text_suffix.s
  e_show_imune_text.b
  e_game_mode.i
  e_global_light_data_file.s
  e_global_fps.i
  e_sound_pool_path.s;="" ;used for interactive developement, you can delete the files in the SOUND folder, needed sounds/effect will be moved from POOL to SOUND, so we can setup interactiv all needed soundfiles and delete/remove not needed files from the gamedirectory
  e_switch_map_on_trigger.b;=#False
  e_world_show_timer.b     ;=#False
  e_global_sound_frequence_back_up.i;=0
  e_use_virtual_buffer.b            ;=#False
  e_show_gray_scale.b               ;=#False
  e_brightnes.i                     ;=10  ;default if greayscale is active
  e_colorness.i                     ;=-100;default for grayscale
  DC.i                              ;=0
  e_COLOR_GRAY.i                    ;=RGB(100,100,100)
  e_COLOR_YELLOW.i                  ;=RGB(255, 255, 27)
  e_COLOR_ORANGE.i                  ;=RGB(255, 161, 27)
  e_COLOR_BLACK.i                   ;=RGB(0,0,0)
  e_COLOR_WHIHE.i                   ;=RGB(255,255,255)
  e_temp_directory.s                ;=""
  e_stamp_over_lay_id.i           ;=0
  e_map_use_black_stamp.b           ;=#False
  e_map_use_fog_of_war.b            ;=#False
  e_boss_object_name_to_show.s
  e_map_use_special_effect .b          ;if this flag is set we use mirror/water/posteffects, this flag is set with map data, if found a special effects tile this value is set to #true
  e_world_map_name_banner_transparency.i  ;default, changed by script
  e_world_map_is_arena_map.b              ;default
  e_world_map_arena_id.i                  ;arena number (easy arena starts with 0....higher arena number is more challenging)
  e_engine_status.i                       ;status is used for develope and game modes (release)
  e_engine_use_load_icon.b                ;=#False
  e_companion_save_file.s
  e_map_auto_loot_done.b  ;use this for random loot, to save the map status
  e_map_auto_loot_done_global.b
  e_map_is_from_save_dir.b  ;if true we do not use loot creator and procedural creator
  e_interpreter_trigger_string.s
  e_cpu_count.i
  e_cpu_name.s
  *_actual_list_object
  *e_index_object_pointer
  *e_gfx
  e_engine_source_element.s
  e_crt_gfx_id.i
  e_crt_show.b
  e_crt_gfx_id_source.s
  e_crt_effect_level.i
  e_crt_effect_noise.i
  e_crt_effect_noise_rnd.i
  e_crt_scan_line_rnd.i
  e_crt_scan_line.i
  e_engine_window_move.i
  e_message_type.i
  e_engine_internal_screen_w.i
  e_engine_internal_screen_h.i
  e_change_full_screen.b
  e_screen_backup_w.i
  e_screen_backup_h.i
  e_changed.b
  e_pause_path.s
  e_world_offset_x.f
  e_world_offset_y.f
  e_world_logic_path.s
  e_next_world.s
  e_actuall_world.s 
  e_list_size.i
  e_graphic_source.s
  e_sound_source.s
  e_scroll_text_margin_top.f
  e_scroll_text_margin_bottom.f
  e_graphic_source_log.s
  e_ai_filter.s
   e_world_screen_factor_x.f   ;zoomfactor For output of the final render  ;1 =used if no valid value found (calculated)
   e_world_screen_factor_y.f ;zoomfactor for output of the final render
  e_ai_gfx_path.s
  e_ai_map_filter.s
  e_world_source.s
  e_world_auto_layer.b
  e_fullscreen.b
  e_sprite_quality.i  ;standard
  e_error_silent_mode.b           ; default, if set to #true (script) no GFX_FALLBACK will be shown and engine will try to execute the code  if data is valid or not.
  e_screen_type.i      ;default
  e_global_dummy_debug_output_string.s
  e_copy_right_text.s
  e_error_detected.b    
  e_new_game_entry.s
  e_true_screen.b
   e_os_min_version.i
 e_os_version.i                   ;here we read the os version, for now we show a requester if os version not the version we expect (WinDows 10)
 e_random_seed.i  ;here we can store a value for randomsee, randomize, so we can get everyengine start the same "random" or every engine start a new seed
 e_log_file_path.s 
 e_log_file_id.i
 e_log_gfx_source.s
 e_log_ai_source.s
 e_show_debug.b
 e_world_auto_scroll_x.f
 e_world_auto_scroll_y.f
  e_map_x_offset_backup.f ;used to continue with correct ,apoffset if player oved from map to "house/dungeon...." and back to map.
 e_map_y_offset_backup.f 
 e_map_status.i ;holds the status: map left, map entered , map running
 e_left_margin.f
 e_right_margin.f
 e_top_margin.f
 e_bottom_margin.f
 e_map_name_start_show_timer.i
 e_map_name_show_total_timer.i
 e_sort_map_by_layer.b
 e_count_active_boos_guards.i
 e_is_collision.b
 e_objects_in_screen.i
 e_player_sfgx_ini_path.s
 e_interface_sgfx_ini_path.s
 e_do_anim.b
 e_gfx_place_holder_path.s
 e_npc_text_path.s
 e_info_text_path.s
 e_npc_text_field_x.f
 e_npc_text_field_y.f
 e_npc_text_field_w.f
 e_npc_text_field_h.f
 e_npc_text_field_show.b;=#False
 e_npc_dummy_text_for_debugging.s;=""
 e_npc_language.i
 e_npc_language_file_suffix.s ;default=english
 e_npc_text_field_texture_id.i;=0  ;used if present, instead of the drawn box 
 e_map_name_background_path.s
 e_npc_text_field_texture_path.s
 e_map_name_background_id.i
 e_world_map_name_language_suffix.s ;default = english
 e_player_auto_move_direction_x.i
 e_player_auto_move_direction_y.i
 e_button_a_path.s
 e_button_a_id.i
 e_locale_suffix.s
 e_player_weapon_x.f
 e_player_weapon_y.f
 e_player_autolayer.b
 e_player_layer.b
 e_player_does_collision.b ;used for fight system, do not throw axe / playerweapon if #true
 e_clear_screen.b
 e_timer_sound_path.s
 e_timer_sound_id.i
 e_timer_sound_volume.i
 e_timer_speed.i
 e_timer_full_size.i
 e_object_last_direction_x.i ;used for parent child interaction
 e_object_last_direction_y.i
 e_show_FPS.b
 e_velocity_horizontal_active.b
 e_velocity_vertical_active.b
 e_map_show_scroll_text.b
 e_scroll_text_source.s
 e_entry_point.s
 e_sound_global_volume.i
 e_global_sound_id.i
 e_global_sound_path.s
 e_global_sound_path_back_up.s
 e_used_in_map.s
 e_frame_target.i
 e_frames.i
 e_enemy_last_x.f
 e_enemy_last_y.f
 e_enemy_last_position_active.i
 e_enemy_last_layer.i
 e_enemy_count.i
 e_enemy_maximum.i
 e_gfx_folder.s
 e_engine_create_distribution.b
 e_engine_distribution_paths.s
 e_engine_distribution_source.s
 e_engine_distribution_anim_source.s
 e_engine_distribution_file_list.s
 e_engine_time_slice.i
 e_engine_time_slice_actual_time.i
 e_reaper_on_screen.b
 e_full_intro.b
 e_scroll_gfx_width.f
 e_scroll_gfx_height.f
 e_scroll_gfx_default_pos_x.f[9]
 e_scroll_gfx_default_pos_y.f[9]
 e_scroll_speed_x.f[9]
 e_scroll_speed_y.f[9]
 e_scroll_gfx_actual_pos_x1.f[9]  ;used for none fullscreen scrollobject/effects
 e_scroll_gfx_actual_pos_y1.f[9]
 e_scroll_gfx_actual_pos_x2.f[9]
 e_scroll_gfx_actual_pos_y2.f[9]
 e_scroll_auto.b[9]
 e_scroll_object_id.i ;hods the id of the scroll object/number
 e_scroll_left_border.f
 e_scroll_right_border.f
 e_scroll_bottom_border.f
 e_scroll_top_border.f
 e_scroll_gfx_object_valid.b
 e_map_title_wait_for_fade_out.b
 e_wait_for_map_title.b
 e_fov_auto.b
 e_fov_x.f
 e_fov_y.f
 e_change_emitter_is_active.b
 e_change_emitter_id.i
 e_engine_demo.b
 e_save_path.s
 e_player_save_file.s
 e_save_pictogram_path.s
 e_save_pictogram_id.i
 e_save_pictogram_file.s
 e_start_position_screen_shot_taken.b
 e_engine_boss_object_kill_switch.b
 e_do_start_screen_shot.b
 e_map_mode_fight.b
 e_make_distribution.b
 e_make_suffix.s
 e_gfx_crypto.b
 e_crypto_io_counter.q
 e_crypto_io_counter_fail.q
  EndStructure

;---endstructure new


  Global e_engine.e_engine
  ;set some defaults (can be overwritten by external data)
  e_engine\e_map_title_wait_for_fade_out=#False
  e_engine\ e_engine_map_ground =#True           ;the overall variable for the layer of map object. we use this for some effects (put objects to the ground layer)
  e_engine\ e_error_count=0
  e_engine\ e_anim_valid   =#False                 ;true if anim frames false if no animframes (wrong animframedirectory, wrong settings...) we show the default gfx
  e_engine\ e_day_night_overide=#False
  e_engine\ e_day_night_backup=#False
  e_engine\ e_shadow_color_r=0
  e_engine\ e_shadow_color_g=0
  e_engine\ e_shadow_color_b=0
  e_engine\ e_xp_value=0
  e_engine\ e_allert_fov_x=64
  e_engine\ e_allert_fov_y=64
  e_engine\ e_engine_reset_object_position=#False
  e_engine\e_loot_activate_object_in_map=#False
  e_engine\e_water_effect_size_x=1
  e_engine\e_water_effect_size_y=1
  e_engine\e_external_tool_id=0
  e_engine\e_controller_only_mode=#False ;default 
  e_engine\e_server_ticks=60
  e_engine\e_scroll_text_is_valid=#False
  e_engine\e_frame_base=0
  e_engine\e_sound_global_volume=50
  e_engine\e_scroll_text_source=""
  e_engine\e_world_map_scroll_text_suffix=""
  e_engine\e_map_show_scroll_text=#False
  e_engine\e_clear_screen=#True
  e_engine\e_player_weapon_x=0
  e_engine\e_player_weapon_y=0
  e_engine\e_player_autolayer=0
  e_engine\e_player_does_collision=#False
  e_engine\e_locale_suffix=""
  e_engine\e_button_a_id=0
  e_engine\e_button_a_path=""
  e_engine\e_player_auto_move_direction_x=#NO_DIRECTION
  e_engine\e_player_auto_move_direction_y=#NO_DIRECTION
  e_engine\e_world_map_name_language_suffix=""
  e_engine\e_map_name_background_id=0
  e_engine\e_npc_text_field_texture_path=""
  e_engine\e_map_name_background_path=""
  e_engine\ e_npc_text_field_texture_id=0  ;used if present, instead of the drawn box 
  e_engine\e_npc_language_file_suffix=""
  e_engine\ e_npc_text_field_x=0
  e_engine\ e_npc_text_field_y=0
  e_engine\ e_npc_text_field_w=0
  e_engine\ e_npc_text_field_h=0
  e_engine\ e_npc_language=#EN
  e_engine\e_npc_text_field_show=#False
  e_engine\ e_gfx_place_holder_path=""
  e_engine\ e_npc_text_path=""
  e_engine\ e_info_text_path=""
  e_engine\e_do_anim=#False
  e_engine\e_interface_sgfx_ini_path=""
  e_engine\e_player_sfgx_ini_path.s=""
  e_engine\e_objects_in_screen=0
  e_engine\e_is_collision=#False
  e_engine\e_count_active_boos_guards=0
  e_engine\e_sort_map_by_layer=#False
  e_engine\e_map_name_start_show_timer=0
  e_engine\e_map_name_show_total_timer=0
  e_engine\e_left_margin=0
  e_engine\e_right_margin=0
  e_engine\e_top_margin=0
  e_engine\e_bottom_margin=0
  e_engine\e_map_x_offset_backup=0
  e_engine\e_map_y_offset_backup=0
  e_engine\e_map_status=#MAP_NOT_DEFINED
  e_engine\e_os_min_version=0
  e_engine\e_os_version=OSVersion()
  e_engine\e_log_file_path="data\LOG\engine_debug_log"
  e_engine\e_log_file_id=0
  e_engine\e_show_debug=#False
  e_engine\e_world_auto_scroll_x=0
  e_engine\e_world_auto_scroll_y=0
  e_engine\e_new_game_entry=""
  e_engine\e_world_screen_factor_x=1
  e_engine\e_world_screen_factor_y=1
  e_engine\e_error_detected=#False
  e_engine\e_copy_right_text="   GAME ENGINE & TOOLS by Deutschmann Walter. Code done in Purebasic"
  e_engine\e_global_dummy_debug_output_string=""
  e_engine\e_screen_type=#WINDOW_SCREEN
  e_engine\e_error_silent_mode=#False
  ;e_engine\e_sprite_quality=#PB_Sprite_NoFiltering
  e_engine\e_fullscreen=#True
  e_engine\e_world_auto_layer=#False
  e_engine\e_world_source=""
  e_engine\e_ai_gfx_path=""
  e_engine\e_ai_map_filter=""
  e_engine\e_ai_filter=""
  e_engine\e_graphic_source_log=""
  e_engine\e_graphic_source=""
  e_engine\e_gfx_folder=""
  e_engine\e_temp_core=""
  e_engine\e_sound_source=""
  e_engine\e_list_size=0
  e_engine\e_next_world=Str(ElapsedMilliseconds()) ; default if not init
  e_engine\e_actuall_world=Str(ElapsedMilliseconds()) ;default if not init
  e_engine\e_world_logic_path=""
  e_engine\e_pause_path=""
  e_engine\e_world_offset_x=0
  e_engine\e_world_offset_y=0
  e_engine\e_changed=#False
  e_engine\e_screen_backup_h=1
  e_engine\e_screen_backup_w=1
  e_engine\e_change_full_screen=#False
  e_engine\e_engine_internal_screen_h=1
  e_engine\e_engine_internal_screen_w=1
  e_engine\e_message_type=#False
  e_engine\_actual_list_object=0
  e_engine\e_index_object_pointer=0
  e_engine\e_gfx=0
  e_engine\e_true_screen=#True
  e_engine\e_cpu_count=CountCPUs()
  e_engine\e_cpu_name=CPUName()
  e_engine\e_game_mode=#GAME_MODE_DAY  ;default
  e_engine\e_engine_mode=#ACTIVE
  e_engine\e_game_status=#NEW 
  e_engine\e_loading_banner_id=0
  e_engine\e_interpreter_trigger_string="NOT_DEFINED"
  e_engine\e_map_is_from_save_dir=#False
  e_engine\e_companion_save_file=""
  e_engine\e_map_auto_loot_done=#False
  e_engine\e_map_auto_loot_done_global=#False
  e_engine\e_engine_use_load_icon=#False
  e_engine\e_world_map_arena_id=0
  e_engine\e_engine_status=#E_GAME_MODE
  e_engine\e_boss_object_name_to_show=""
  e_engine\e_map_use_special_effect=#False
  e_engine\e_world_map_name_banner_transparency=200
  e_engine\e_world_map_is_arena_map=#False
  e_engine\e_show_gray_scale=#False
  e_engine\e_brightnes=10
  e_engine\e_colorness=-100
  e_engine\DC=0
  e_engine\e_COLOR_BLACK=RGB(0,0,0)
  e_engine\e_COLOR_GRAY=RGB(100,100,100)
  e_engine\e_COLOR_ORANGE=RGB(255,161,27)
  e_engine\e_COLOR_YELLOW=RGB(255,255,27)
  e_engine\e_COLOR_WHIHE=RGB(255,255,255)
  e_engine\e_temp_directory=""
  e_engine\e_start_position_screen_shot_taken=#False
  e_engine\e_stamp_over_lay_id=0
  e_engine\e_map_use_black_stamp=#False
  e_engine\e_map_use_fog_of_war=#False
  e_engine\e_sound_pool_path=""
  e_engine\e_switch_map_on_trigger=#False
  e_engine\e_world_show_timer=#False
  e_engine\e_global_sound_frequence_back_up=0
  e_engine\e_use_virtual_buffer=#False
  e_engine\e_show_gray_scale=#False
  e_engine\e_global_light_data_file=""
  e_engine\e_gfx_pause_id=#False
  e_engine\e_gfx_position_x=0
  e_engine\e_gfx_position_y=0
  e_engine\e_gfx_pause_valid=#False
  e_engine\e_gfx_continue_valid=#False
  e_engine\e_gfx_continue_id=0
  e_engine\e_gfx_quit_path=""
  e_engine\e_gfx_continue_path=""
  e_engine\e_gfx_show_pause=#False
  e_engine\e_gfx_no_controller_path=""
  e_engine\e_gfx_no_controller_id=0
  e_engine\e_engine_game_mode=#PLAYER_GAME_MODE_NORMAL
  e_engine\e_engine_object_last_layer=0
  e_engine\e_engine_collision_type_pixel=#False
  e_engine\e_engine_scroll_map=#True
  e_engine\e_engine_no_scroll_margin=0
  e_engine\e_engine_input_mode=#False
  e_engine\e_world_map_head_suffix=""
  e_engine\e_show_imune_text=#False
  e_engine\e_global_sound_id=0
  e_engine\e_global_sound_path=""
  e_engine\e_global_sound_path_back_up=""
  e_engine\e_used_in_map=""
  e_engine\e_enemy_last_x=0
  e_engine\e_enemy_last_y=0
  e_engine\e_enemy_last_position_active=#False
  e_engine\e_enemy_last_layer=-128
  e_engine\e_engine_time_slice=20000000000000000000 ;ms  try this value for some multitasking/treading engine base
  e_engine\e_reaper_on_screen=#False
  e_engine\e_full_intro=#True ;default
  e_engine\e_change_emitter_is_active=#False
  e_engine\e_change_emitter_id=0
  e_engine\e_engine_demo=#False
  e_engine\e_save_path=""
  e_engine\e_player_save_file=""
  e_engine\e_engine_create_distribution=#True
  e_engine\e_engine_boss_object_kill_switch=#False
  e_engine\e_do_start_screen_shot=#False
  e_engine\e_map_mode_fight=#True
  e_engine\e_make_distribution=#False
  e_engine\e_make_suffix=""
  e_engine\e_gfx_crypto=#False ; set to true for gfx auto crypto (needed if you want a "MAKE" ), GFX will be en/decrypted on the fly



; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 253
; FirstLine = 236
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant