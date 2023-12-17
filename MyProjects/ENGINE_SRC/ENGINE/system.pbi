
;OS related variables, constatns used by engine
;messaging system, directory, filesystem
Global v_user_directory.s=GetHomeDirectory()
Global v_temp_directory.s=GetTemporaryDirectory()
Global v_engine_base.s=GetCurrentDirectory()
Global v_engine_boot_screen.s=""
Global v_engine_boot_screen_id.i=0
Global v_engine_base_file.s=""
Global v_engine_shadow_map_path.s=""
Global v_engine_sound_path.s=""
Global v_engine_base_file_id.b=0
Global v_message.i=-1; stores the message send by system/user  for further use
Global v_message_timeout.i=2; value for waitwindow event  in milliseconds, for multitasking env.
Global v_keyboard_present.b=#False
Global v_screen_system_sprite.b=#False
Global v_mouse_present.b=#False
Global v_touch_screen_present.b=#False
Global v_sound_system.b=#False
Global v_engine_basic_path.s="data/ini/ini.ini"
Global v_screen_center_w.i=0
Global v_screen_center_h.i=0
Global v_sound_balance_factor.f=0
Global v_screen_mode.b=#ENGINE_WINDOWED_SCREEN
;system internalls, fall back
 ;sysinternals for game engine 



;basic input devices and inits, other inits and devices are defined in the "extension.pbi"
;Global v_keyboard_present.b=0;InitKeyboard()
;Global v_mouse_present.b=0;InitMouse()
v_screen_system_sprite.b=InitSprite()
v_sound_system.b=InitSound()
