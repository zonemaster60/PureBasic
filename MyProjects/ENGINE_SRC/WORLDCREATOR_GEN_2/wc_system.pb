;here all the system vars

Global v_base.s=GetCurrentDirectory()
Global v_user.s=GetUserDirectory(#PB_Directory_AllUserData)
Global v_temp.s=GetTemporaryDirectory()
Global v_resource_path.s=""
Global v_resource_path_sound.s=""
Global v_resource_name.s=""
Global v_resource_type.s=""
Global v_resource_name_sound.s=""
Global v_cache_dir.s=""
Global v_cache_id.l=0  ;start with 0, is valid for session
Global v_cache_last_id.l=0
Global v_clean_cache_on_exit.b=#True ;default we do clean up the cache after exit

Global _d.l=ExamineDesktops()

Global v_desktop_w.f=DesktopWidth(0)
Global v_desktop_h.f=DesktopHeight(0)

Global v_window_w.f=0
Global v_window_h.f=0
Global v_window_main_x.f=1
Global v_window_main_y.f=1

Global v_window_parent_id.i=0
Global v_window_child_id.i=0
Global v_window_child_w.f=0
Global v_window_child_h.f=0

Global v_window_screen_id.i=0
Global v_window_child_screen_id.i=0
Global v_ini_path.s=""
Global v_menu_script_path.s=""
Global v_event_window_id.i=0

Global v_menu_id.i=0

Global v_mouse_desktop_x.f=0
Global v_mouse_desktop_y.f=0 ;for catching the mouse position all over the desktop screen

;---------------------- for develope ------

;hard coded for now---- replace with scripted infos

Global wc_menu_image_size.l=v_desktop_w.f/64
Global wc_transparency_color.l=0

;----------------------- basic handlers for work-gfx

Global wc_x_offset.i=0
Global wc_y_offset.i=0
Global wc_work_with.f=0
Global wc_work_height.f=0
Global wc_layer.b=0
Global wc_layer_show.b=-127  ;show all layers
Global wc_show_layer_id.b=#False
Global wc_pointer_gfx.i=0
Global wc_delpointer_gfx.l=0
Global wc_delpointer_path.s=""
Global wc_engine_screen_width.f=0  ;for the simulted engine screen (box shows area of  real rendered gamescreen)
Global wc_engine_screen_height.f=0 ;for the simulted engine screen (box shows area of  real rendered gamescreen)
Global wc_engine_screen_area_show.b=#False
Global wc_map_move_per_pixel.b=#False
Global wc_use_object_based_raster.b=1  ;default
Global wc_use_auto_layer.b=#False
Global wc_auto_object.s="NO AUTO LAYER"
Global wc_auto_layer.s="NO"
Global wc_ignore_map_error.b=#False
Global wc_sound_id.i=0
Global wc_sound_path.s=""
Global wc_full_sound_path.s=""
Global wc_map_use_global_sound.b=#False
Global wc_sound_system_valid.b=#False
Global wc_sound_ok.b=#True
Global wc_global_load_save_path.s=""
Global wc_area_container_path.s=""  ;holds the complete area  path:  world_creator_recource_path+wc_area_container_base.s
Global wc_area_container_base.s=""  ;holds the area directory name
Global wc_area_file_icon.i=0  ;holds the gfx file for the "icon" of the area object, the icon is shown  in th eobject menu
Global wc_objects_in_map.i=0  ;for window title / loading screen
;---------------------------------------------------------------------------------------------------------------------

Global wc_right.f=0
Global wc_right_bottom.f=0
;this vars are for the area  reset (we build an area  and set its coordinates to the left upper corner) 
;we go like this: if object_x< offet_x, offset_x=object_x

Global wc_quest_book.l=0  ;store the number of quests/map , simple system for now
Global wc_map_can_pause.s="YES"
Global wc_map_can_pause_id.b=#True 
Global wc_map_use_respawn.s="YES" ;default
Global wc_map_use_respawn_id.b=#True ;default
Global wc_map_use_quest_system.b=#False ;default
Global wc_map_fight.b=#True             ;default
Global wc_map_fight_text.s="YES"
Global wc_map_day_timer.b=#True
Global wc_map_is_arena_text.s="NO" ;default
Global wc_map_show_version_info.b=#False
Global wc_map_timer_switch.l=0
Global wc_switch_map_name.s=""
Global wc_map_switch_on_trigger.b=#False
Global wc_show_timer.b=#False
Global wc_map_use_black_stamp.b=#False
Global wc_scroll.b=#True  ;default
Global wc_scroll_yes_no.s="YES"
Global wc_global_effect.i=#WC_GLOBAL_EFFECT_NONE
Global wc_global_effect_info_text.s="NONE"
Global wc_map_show_scroll_text.b=#False
Global wc_map_show_gui.b=#True
Global wc_x_origin.i=0
Global wc_y_origin.i=0
;----------------------------------------------------------------------------------------------------------------------------



; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 48
; FirstLine = 89
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant