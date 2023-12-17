;FUNDAMENT


UsePNGImageDecoder()
UseOGGSoundDecoder()
UsePNGImageEncoder()

Declare  E_QUIT()
Declare E_GET_PACK_GFX_AND_REBUILD_DISTI(_void.s)


;basic input devices and inits, other inits and devices are defined in the "extension.pbi"
;Global v_keyboard_present.b=0;InitKeyboard()
;Global v_mouse_present.b=0;InitMouse()

; "" is used if we want to use  default language output (english) 
;for now we suppor german (_DE) and english ("") for output, but all languages  shown in the selcect block are supported, just change the "" to _FR, _RU, _IT, _ES,....
;but beware: YOU must support and create the language output files to be shown on screen, if there is no text(emty file) in selected language, nothing or speech bubble without test will be shown

If OpenLibrary(0, "Kernel32.dll")
  Prototype GetSystemDefaultUILanguage()
  Define GetSystemDefaultUILanguage.GetSystemDefaultUILanguage = GetFunction(0, "GetSystemDefaultUILanguage")
  CloseLibrary(0)
EndIf

Select GetSystemDefaultUILanguage() & $0003FF
  Case #LANG_ENGLISH
    e_engine\e_npc_language=#EN
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=""
  Case #LANG_FRENCH
    e_engine\e_npc_language=#FR
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=".fr"
  Case #LANG_GERMAN
    e_engine\e_npc_language=#DE
    e_engine\e_locale_suffix="DE_"
    e_engine\e_world_map_name_language_suffix=".de"
  Case #LANG_RUSSIAN
    e_engine\e_npc_language=#RU
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=".ru"
  Case #LANG_SPANISH
    e_engine\e_npc_language=#ES
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=".es"
     Case #LANG_ITALIAN
    e_engine\e_npc_language=#IT
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=".it"
  Default
    e_engine\e_npc_language=#EN ;default english 
    e_engine\e_locale_suffix=""
    e_engine\e_world_map_name_language_suffix=""
    
EndSelect



Procedure E_LOCALE_OVERRIDE(e_use_locale.b)
  
  Select e_use_locale.b
      
    Case #False
       e_engine\e_npc_language=#EN ;for debugging, set #EN for default!!!
       e_engine\e_locale_suffix=""
       e_engine\e_world_map_name_language_suffix=""
    
  EndSelect
  
  
EndProcedure


Procedure E_SHOW_BOOT_SCREEN()
  
  If IsSprite(v_engine_boot_screen_id.i)
  DisplaySprite(v_engine_boot_screen_id.i,0,0)
EndIf

If IsSprite(e_engine\e_start_up_load_symbol_gfx_id)
  
  RotateSprite(e_engine\e_start_up_load_symbol_gfx_id,1,#PB_Relative)
  DisplaySprite(e_engine\e_start_up_load_symbol_gfx_id,e_engine\e_engine_internal_screen_w-SpriteWidth(e_engine\e_start_up_load_symbol_gfx_id)-64,e_engine\e_engine_internal_screen_h-SpriteHeight(e_engine\e_start_up_load_symbol_gfx_id)-64)
  
EndIf

  
  FlipBuffers()
EndProcedure



Procedure E_SETUP_BOOT_SCREEN()
  v_engine_boot_screen_id.i=LoadSprite(#PB_Any,v_engine_base.s+v_engine_boot_screen.s)
  e_engine\e_start_up_load_symbol_gfx_id=LoadSprite(#PB_Any,v_engine_base.s+e_engine\e_start_up_load_symbol_paths,#PB_Sprite_AlphaBlending)  

  
  If IsSprite(v_engine_boot_screen_id.i)
    ZoomSprite(v_engine_boot_screen_id.i,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h)
  EndIf
  
  
EndProcedure


Procedure E_GUI_GFX_SETUP()

 e_engine\e_gfx_pause_id=LoadSprite(#PB_Any,v_engine_base.s+GetPathPart(e_engine\e_pause_path)+e_engine\e_locale_suffix+GetFilePart(e_engine\e_pause_path),#PB_Sprite_AlphaBlending)
 e_engine\e_gfx_continue_id=LoadSprite(#PB_Any,v_engine_base.s+GetPathPart(e_engine\e_gfx_continue_path)+e_engine\e_locale_suffix+GetFilePart(e_engine\e_gfx_continue_path),#PB_Sprite_AlphaBlending)
 e_engine\e_npc_text_field_texture_id=LoadImage(#PB_Any,v_engine_base.s+GetPathPart(e_engine\e_npc_text_field_texture_path)+GetFilePart(e_engine\e_npc_text_field_texture_path),0)
 e_engine\e_map_name_background_id=LoadImage(#PB_Any,v_engine_base.s+GetPathPart(e_engine\e_map_name_background_path)+GetFilePart(e_engine\e_map_name_background_path),0)
 e_engine\e_loading_banner_id=LoadSprite(#PB_Any,v_engine_base.s+e_loading_banner_path.s,#PB_Sprite_AlphaBlending)
 e_engine\e_gfx_no_controller_id=LoadSprite(#PB_Any,v_engine_base.s+GetPathPart(e_engine\e_gfx_no_controller_path)+e_engine\e_locale_suffix+GetFilePart(e_engine\e_gfx_no_controller_path),#PB_Sprite_AlphaBlending)
  ;--------check for valid
 
  v_screen_center_w=(v_win_max_width-v_screen_w.f)/2
  v_screen_center_h=(v_win_max_height-v_screen_h.f)/2
 
 If IsSprite(e_engine\e_gfx_pause_id)
   e_engine\e_gfx_pause_valid=#True
      Else
   e_engine\e_gfx_pause_valid=#False  
 EndIf
 


 If IsSprite(e_engine\e_loading_banner_id)
     e_loading_banner_gfx_valid.b=#True
 Else
   e_loading_banner_gfx_valid.b=#False
 EndIf
 
    
         
         If IsImage(e_engine\e_map_name_background_id)
           
           ResizeImage(e_engine\e_map_name_background_id,e_engine\e_engine_internal_screen_w,128)
           
         EndIf
         
  
EndProcedure








