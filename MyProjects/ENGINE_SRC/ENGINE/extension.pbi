


;extension is used for what it means: extensions: joystick/pad,alternative APi,.....
;------------------- all externals ---------------------------------------------------------------
XIncludeFile "EXTERNAL_CODE/memory_usage.pb"
;--------------------------------------------------------------
;------------------------- some external devices if present we can/want to  use:
Declare  E_LOG(s0.s,s1.s,s2.s)

 

Procedure E_CORE_ENV()
  ;here we define some engine situations, like controlled randomize, physics, and some stuff we may need and use 
  ;use of this routine / procedure is optional
  ;lets go:


 EndProcedure
 
 
 Procedure E_ENGINE_LOAD_GFX_FONT()
   
   
   
 EndProcedure
 
 
 Procedure E_REGISTER_FONT()
   
   ;if there is a valid extern font it will be used, if not or if it is a valid systemfont nothing happens, but loading the font....
   ;ProcedureReturn #False
   
   If RegisterFontFile(e_font_directory.s+e_GUI_font\e_GUI_screen_head_font)
     If FindString(e_GUI_font\e_GUI_screen_head_font,".")>0
       e_GUI_font\e_GUI_screen_head_font=Left(e_GUI_font\e_GUI_screen_head_font,FindString(e_GUI_font\e_GUI_screen_head_font,".")-1)
     EndIf
     
   EndIf
   
   
   If RegisterFontFile(e_font_directory.s+e_GUI_font\e_GUI_map_name_font_name)
     If FindString(e_GUI_font\e_GUI_map_name_font_name,".")>0
       e_GUI_font\e_GUI_map_name_font_name=Left(e_GUI_font\e_GUI_map_name_font_name,FindString(e_GUI_font\e_GUI_map_name_font_name,".")-1)
     EndIf
     
   EndIf
   
   
   If RegisterFontFile(e_font_directory.s+e_GUI_font\e_GUI_npc_font_name)
     If FindString(e_GUI_font\e_GUI_npc_font_name,".")>0
       e_GUI_font\e_GUI_npc_font_name=Left(e_GUI_font\e_GUI_npc_font_name,FindString(e_GUI_font\e_GUI_npc_font_name,".")-1)  
     EndIf
     
   EndIf
   
   
 EndProcedure
 
 
 
 Procedure E_ENGINE_LOAD_FONT()
   
   
   
   
   ;load some font for gui and npc textbox
   
   If LoadFont(#NPC_FONT_ID,e_GUI_font\e_GUI_npc_font_name,e_GUI_font\e_GUI_npc_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
  e_GUI_font\e_GUI_npc_font_size*1.3
   EndIf
   
   If LoadFont(#GUI_FONT_ID,e_GUI_font\e_GUI_font_name,e_GUI_font\e_GUI_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
      If LoadFont(#FONT_SCREEN_HEAD,e_GUI_font\e_GUI_screen_head_font,e_GUI_font\e_GUI_screen_head_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   If LoadFont(#XP_MULTIPLICATOR_FONT_ID,e_xp_multiplicator\e_xp_multiplicator_font_name,e_xp_multiplicator\e_xp_mutliplicator_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   If LoadFont(#PLAYER_INFO_FONT_ID,player_statistics\player_info_font_name,player_statistics\player_info_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   If LoadFont(#FONT_INVENTORY,e_GUI_font\e_GUI_inventory_font_name,e_GUI_font\e_GUI_inventory_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   If LoadFont(#FONT_GOLD_TEXT,e_GUI_font\e_GUI_gold_font_name,e_GUI_font\e_GUI_gold_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   If LoadFont(#FONT_XP_BAR,e_GUI_font\e_GUI_xp_font_name,e_GUI_font\e_GUI_xp_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   
   If LoadFont(#FONT_INFO_FONT,e_GUI_font\e_GUI_info_font_name,e_GUI_font\e_GUI_info_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
    e_GUI_font\e_GUI_info_font_size*1.3
   EndIf
   
    If LoadFont(#FONT_DEBUG,e_GUI_font\e_GUI_debug_font_name,e_GUI_font\e_GUI_debug_font_name_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
    EndIf
    
   
   If LoadFont(#FONT_XP_COUNTER,e_GUI_font\e_GUI_xp_font_name,e_GUI_font\e_GUI_xp_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   If LoadFont(#FONT_MAP_NAME_ID,e_GUI_font\e_GUI_map_name_font_name,e_GUI_font\e_GUI_map_name_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
   If LoadFont(#FONT_TIMER,e_map_timer\_map_timer_font_name,e_map_timer\_map_timer_font_size/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
     If LoadFont(#FONT_TIMER_SMALL,e_map_timer\_map_timer_font_name,24/DesktopResolutionY(),#PB_Font_HighQuality)
     
   EndIf
   
   
 EndProcedure
 
 
 
 Procedure E_CUSTOM_REQUESTER_TEXT(_head.s,_body.s)
  
  
   
     DrawText(e_engine_custom\custom_msg_requester_pos_x+4,e_engine_custom\custom_msg_requester_pos_y+2,_head.s,RGB(240,240,240))
     DrawingFont(FontID(#FONT_CUSTOM_MSG_REQUESTER_BODY))
     DrawText(e_engine_custom\custom_msg_requester_pos_x+4,e_engine_custom\custom_msg_requester_pos_y+e_engine_custom\custom_msg_requester_height/4+12,_body.s,RGB(240,240,240))

   
 EndProcedure
 
 

 
 Procedure E_CUSTOM_MSG_REQUESTER_DRAW(_head.s,_body.s)
   
   StartDrawing(ScreenOutput())
   DrawingMode(#PB_2DDrawing_Transparent)
   DrawingFont(FontID(#FONT_CUSTOM_MSG_REQUESTER_HEAD))
   
   
   If IsImage(e_engine_custom\custom_msg_requester_back_gfx_id)
     DrawAlphaImage(ImageID(e_engine_custom\custom_msg_requester_back_gfx_id),e_engine_custom\custom_msg_requester_pos_x,e_engine_custom\custom_msg_requester_pos_y,e_engine_custom\custom_msg_requester_transparency)
   EndIf
   
   If IsImage(e_engine_custom\custom_msg_requester_button_yes_id)
     DrawAlphaImage(ImageID(e_engine_custom\custom_msg_requester_button_yes_id),e_engine_custom\custom_msg_requester_pos_x+e_engine_custom\custom_button_yes_x,e_engine_custom\custom_msg_requester_pos_y+e_engine_custom\custom_button_yes_y,e_engine_custom\custom_msg_requester_transparency)
   EndIf
   
   If IsImage(e_engine_custom\custom_msg_requester_button_no_id)
     DrawAlphaImage(ImageID(e_engine_custom\custom_msg_requester_button_no_id),e_engine_custom\custom_msg_requester_pos_x+e_engine_custom\custom_button_no_x,e_engine_custom\custom_msg_requester_pos_y+e_engine_custom\custom_button_no_y,e_engine_custom\custom_msg_requester_transparency)
   EndIf
   
   If IsSound(e_engine_custom\custom_msg_requester_sound_id)
     SoundVolume(e_engine_custom\custom_msg_requester_sound_id,100)
     PlaySound(e_engine_custom\custom_msg_requester_sound_id)
   EndIf
   
   
   E_CUSTOM_REQUESTER_TEXT(_head.s,_body.s)
   
   
   StopDrawing()

 EndProcedure
 
 
 
 Procedure E_CUSTOM_MSG_REQUESTER_FONT_SETUP()
   
   If LoadFont(#FONT_CUSTOM_MSG_REQUESTER_HEAD,e_engine_custom\custom_msg_requester_font_head,e_engine_custom\custom_msg_reqester_font_size_head/DesktopResolutionY())
     
   EndIf
   
    If LoadFont(#FONT_CUSTOM_MSG_REQUESTER_BODY,e_engine_custom\custom_msg_requester_font_body,e_engine_custom\custom_msg_reqester_font_size_body/DesktopResolutionY())
     
   EndIf
   
  
   
 EndProcedure
 
  Procedure  E_CUSTOM_MSG_REQUESTER_GFX_SETUP_SPRITE()
   
   e_engine_custom\custom_msg_requester_back_gfx_id=LoadSprite(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_back_gfx_path,#PB_Sprite_AlphaBlending)
   e_engine_custom\custom_msg_requester_button_no_id=LoadSprite(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_button_no_path,#PB_Sprite_AlphaBlending)
   e_engine_custom\custom_msg_requester_button_yes_id=LoadSprite(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_button_yes_path,#PB_Sprite_AlphaBlending)
   
   
   If IsSprite(e_engine_custom\custom_msg_requester_back_gfx_id)
     If e_engine_custom\custom_msg_requester_width>0 And e_engine_custom\custom_msg_requester_height>0
       ZoomSprite(e_engine_custom\custom_msg_requester_back_gfx_id,e_engine_custom\custom_msg_requester_width,e_engine_custom\custom_msg_requester_height)
     Else
          EndIf
   EndIf
   
   
   
 EndProcedure
 
 
 
 
 
  Procedure  E_CUSTOM_MSG_REQUESTER_GFX_SETUP()
   
   e_engine_custom\custom_msg_requester_back_gfx_id=LoadImage(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_back_gfx_path,0)
   e_engine_custom\custom_msg_requester_button_no_id=LoadImage(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_button_no_path,0)
   e_engine_custom\custom_msg_requester_button_yes_id=LoadImage(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_button_yes_path,0)
   
   
   If IsImage(e_engine_custom\custom_msg_requester_back_gfx_id)
     If e_engine_custom\custom_msg_requester_width>0 And e_engine_custom\custom_msg_requester_height>0
       ResizeImage(e_engine_custom\custom_msg_requester_back_gfx_id,e_engine_custom\custom_msg_requester_width,e_engine_custom\custom_msg_requester_height)
     Else
          EndIf
   EndIf
   
   
   
 EndProcedure

 
 
 Procedure E_CUSTOM_MSG_REQUESTER_SOUND_SETUP()
   
   e_engine_custom\custom_msg_requester_sound_id=LoadSound(#PB_Any,e_engine_custom\custom_msg_requester_gfx_core_path+e_engine_custom\custom_msg_requester_sound_path,#PB_Sound_Streaming)
   
   
   
 EndProcedure
 

 
 
 Procedure E_CUSTOM_MSG_REQUESTER_SETUP(_key.s,_ok.i)
   
   Select _key.s
       
     Case "CUSTOM_MSG_REQUESTER_POS_X"
       e_engine_custom\custom_msg_requester_pos_x=ValF(ReadString(_ok.i))
       
       
     Case "CUSTOM_MSG_REQUESTER_POS_Y"
       e_engine_custom\custom_msg_requester_pos_y=ValF(ReadString(_ok.i))
       
       
     Case "CUSTOM_MSG_REQUESTER_WIDTH"
       e_engine_custom\custom_msg_requester_width=ValF(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_HEIGHT"
       e_engine_custom\custom_msg_requester_height=ValF(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_TITLE"
       e_engine_custom\custom_msg_requester_titel=Trim(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_GFX_CORE_PATH"
       e_engine_custom\custom_msg_requester_gfx_core_path=v_engine_base+Trim(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_BUTTON_YES_PATH"
       e_engine_custom\custom_msg_requester_button_yes_path=Trim(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_BUTTON_NO_PATH"
       e_engine_custom\custom_msg_requester_button_no_path=Trim(ReadString(_ok.i))
       
     Case "CUSTOM_REQUESTER_BACK_GFX_PATH"
       e_engine_custom\custom_msg_requester_back_gfx_path=Trim(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_FONT_HEAD"
       e_engine_custom\custom_msg_requester_font_head=Trim(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_FONT_SIZE_HEAD"
       e_engine_custom\custom_msg_reqester_font_size_head=ValF(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_FONT_COLOR"
       e_engine_custom\custom_msg_requester_font_color_RGB=RGB(200,200,0) ;hard coded for now, we do not interprete the script in detail, maybe later with an update
       
     Case "CUSTOM_MSG_REQUESTER_FONT_BODY" 
        e_engine_custom\custom_msg_requester_font_body=Trim(ReadString(_ok.i))
       
       Case "CUSTOM_MSG_REQUESTER_FONT_SIZE_BODY"
       e_engine_custom\custom_msg_reqester_font_size_body=ValF(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_YES_POS_X"
       e_engine_custom\custom_button_yes_x=ValF(ReadString(_ok.i))
     Case "CUSTOM_MSG_REQUESTER_YES_POS_Y"
       e_engine_custom\custom_button_yes_y=ValF(ReadString(_ok.i))
     Case "CUSTOM_MSG_REQUESTER_NO_POS_X"
       e_engine_custom\custom_button_no_x=ValF(ReadString(_ok.i))
     Case "CUSTOM_MSG_REQUESTER_NO_POS_Y"
       e_engine_custom\custom_button_no_y=ValF(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_TRANSPARENCY"
       e_engine_custom\custom_msg_requester_transparency=Val(ReadString(_ok.i))
       
     Case "CUSTOM_MSG_REQUESTER_POP_UP_SOUND"
       e_engine_custom\custom_msg_requester_sound_path=Trim(ReadString(_ok.i))
       
     Case "ENGINE_GFX_FONT"
     
       
     Case "ENGINE_GFX_FONT_NAME"
      
       
   EndSelect
   
   
   
 EndProcedure
 
 
 
 
 
 Procedure.b E_CUSTOM_MSG_REQUESTER_INIT(_ini_file.s)
   Define _ok.i=0
   
   
   _ok.i=ReadFile(#PB_Any,_ini_file.s)
   
   If _ok.i=0
  
   ProcedureReturn #False  
   EndIf
   
   ;file is valid:
   
   While Not Eof(_ok.i)
     E_CUSTOM_MSG_REQUESTER_SETUP(Trim(ReadString(_ok.i)),_ok.i)  ;key
   Wend
   
   CloseFile(_ok.i)
     
   E_CUSTOM_MSG_REQUESTER_FONT_SETUP()
   E_CUSTOM_MSG_REQUESTER_GFX_SETUP()
   E_CUSTOM_MSG_REQUESTER_SOUND_SETUP()
   
 EndProcedure
 
 
 Procedure E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND()
   ;here we load the soundeffect for the floppy loading symbol
   

   e_engine_build_in_effect\e_sound_disk_drive_id=LoadSound(#PB_Any,e_engine_build_in_effect\e_sound_disk_drive_path,#PB_Sound_Streaming)
   
   If IsSound(e_engine_build_in_effect\e_sound_disk_drive_id)=0
        E_LOG(e_engine\e_engine_source_element,"DISK_DRIVE_SOUND_EFFECT_MISSING",GetFilePart(e_engine_build_in_effect\e_sound_disk_drive_path))
   EndIf
   
   
   
   
 EndProcedure
 
 
 Procedure E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND_PLAY()
   ;here we play the soundeffect for the floppy loading symbol

  If e_engine_build_in_effect\e_sound_disk_drive_play=#False
   ProcedureReturn #False  
 EndIf
    
   
 If  IsSound(e_engine_build_in_effect\e_sound_disk_drive_id)=0
 ProcedureReturn #False  
 EndIf
SoundVolume(e_engine_build_in_effect\e_sound_disk_drive_id,100)
   PlaySound(e_engine_build_in_effect\e_sound_disk_drive_id)
   

   
 EndProcedure
 
 
  Procedure E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND_STOP()
  
  If e_engine_build_in_effect\e_sound_disk_drive_play=#False
   ProcedureReturn #False  
 EndIf
   
   
   If e_engine_build_in_effect\e_sound_disk_drive_valid=#False
   ProcedureReturn #False  
 EndIf
 
   StopSound(e_engine_build_in_effect\e_sound_disk_drive_id,#PB_All)
   
   
   
 EndProcedure
 
 
 
