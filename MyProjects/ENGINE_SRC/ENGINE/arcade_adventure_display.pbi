



Declare.i E_CUSTOM_MSG_REQUESTER(_h.s,_b.s)

Procedure E_Open_Display_WIN_MAX(display_x,display_y,display_w,display_h,display_name.s)
  
 ;fullscreen (windowed screen)
  

  
  If e_engine\e_true_screen=#True
  ProcedureReturn #False  
  EndIf
  
  

  
 
  If  e_engine\e_fullscreen=#False
  ProcedureReturn #False ;we did not set to fullscreen  
  EndIf
  
  If ExamineDesktops()=0
    E_DESKTOP_INFORMATION_MISSING()
  EndIf
  
  
  Select e_vsync
      
    Case #True
      v_display_id=OpenWindow(#ENGINE_WINDOW_ID,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,"AWAKENING"+e_engine\e_copy_right_text.s,#PB_Window_BorderLess)
      v_display_id=WindowID(#ENGINE_WINDOW_ID)
      v_screen_id=OpenWindowedScreen(v_display_id,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#True,0,0,#PB_Screen_WaitSynchronization)
     
      
    Default 
      
      v_display_id=OpenWindow(#ENGINE_WINDOW_ID,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,"AWAKENING"+e_engine\e_copy_right_text,#PB_Window_BorderLess)
      v_display_id=WindowID(#ENGINE_WINDOW_ID)
      v_screen_id=OpenWindowedScreen(v_display_id,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#True,0,0,#PB_Screen_NoSynchronization)
     
       ;do not show mouse pointer if game is runing in full window
      
  EndSelect
  
  e_engine\e_npc_text_field_x=0
  e_engine\e_npc_text_field_y=ScreenHeight()-ScreenHeight()/6
  e_engine\e_npc_text_field_w=ScreenWidth()
  e_engine\e_npc_text_field_h=ScreenHeight()/6
  StickyWindow(#ENGINE_WINDOW_ID,#False)
  ShowCursor_(#False)
  ResizeWindow(#ENGINE_WINDOW_ID,0,0,DesktopWidth(0)/DesktopResolutionX(),DesktopHeight(0)/DesktopResolutionY())
  SetActiveWindow(#ENGINE_WINDOW_ID)
 
  
  
EndProcedure



Procedure E_Open_Display_WIN(display_x,display_y,display_w,display_h,display_name.s)
  
  ;here we go for the window version...
  
  Define ok.b=0
  
  
  If e_engine\e_true_screen=#True
  ProcedureReturn #False  
  EndIf
  
  If  e_engine\e_fullscreen=#True
  ProcedureReturn #False ;we set to fullscreen  
  EndIf
  

  
  
  Select e_vsync
      
    Case #True
      v_display_id=OpenWindow(#ENGINE_WINDOW_ID,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,"AWAKENING"+e_engine\e_copy_right_text)
      v_display_id=WindowID(#ENGINE_WINDOW_ID)
      v_screen_id=OpenWindowedScreen(v_display_id,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#True,0,0,#PB_Screen_WaitSynchronization)
    
         
    Default 
      
      v_display_id=OpenWindow(#ENGINE_WINDOW_ID,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,"AWAKENING"+e_engine\e_copy_right_text)
      v_display_id=WindowID(#ENGINE_WINDOW_ID)
      v_screen_id=OpenWindowedScreen(v_display_id,display_x,display_y,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#True,0,0,#PB_Screen_NoSynchronization)
      
    
      
  EndSelect
  
  e_engine\e_npc_text_field_x=0
  e_engine\e_npc_text_field_y=ScreenHeight()-ScreenHeight()/6
  e_engine\e_npc_text_field_w=ScreenWidth()
  e_engine\e_npc_text_field_h=ScreenHeight()/6
  StickyWindow(#ENGINE_WINDOW_ID,#False)
  ResizeWindow(#ENGINE_WINDOW_ID,0,0,e_engine\e_engine_internal_screen_w/DesktopResolutionX(),e_engine\e_engine_internal_screen_h/DesktopResolutionY())
  SetActiveWindow(#ENGINE_WINDOW_ID)
EndProcedure


Procedure E_Open_Display_True_Screen(display_x,display_y,display_w,display_h,display_name.s)
  
;full screen classic mode, open game screen directly

 
  If    e_engine\e_true_screen=#False
  ProcedureReturn #False ;we did not set to fullscreen  
  EndIf
  

  
  
  Select e_vsync
      
    Case #True
      
      
      v_screen_id=OpenScreen(e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,32,display_name.s,#PB_Screen_SmartSynchronization)   ;woraround for wrong screensize if first start
      
      
    Case #False
      v_screen_id=OpenScreen(e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,32,display_name.s,#PB_Screen_NoSynchronization)
      
    Default 
      
     v_screen_id=OpenScreen(e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,32,display_name.s,#PB_Screen_SmartSynchronization)
   
      
  EndSelect
  
  
  If v_screen_id=0
    e_engine\e_true_screen=#False
    E_Open_Display_WIN(display_x,display_y,display_w,display_h,display_name.s)
    ProcedureReturn #False
  EndIf
  
  
  e_engine\e_npc_text_field_x=0
  e_engine\e_npc_text_field_y=ScreenHeight()-ScreenHeight()/6
  e_engine\e_npc_text_field_w=ScreenWidth()
  e_engine\e_npc_text_field_h=ScreenHeight()/6
 
  
 
  
  
EndProcedure



Procedure E_GRAY_SCALE(DC)
  If e_engine\e_show_gray_scale<>#True
  ProcedureReturn #False  
  EndIf
  
Define COLORADJUSTMENT.COLORADJUSTMENT


GetColorAdjustment_(DC, Coloradjustment)
SetStretchBltMode_(DC, #HALFTONE)

COLORADJUSTMENT\caColorfulness = e_engine\e_colorness
COLORADJUSTMENT\caBrightness = e_engine\e_brightnes

SetColorAdjustment_(DC, COLORADJUSTMENT)
StretchBlt_(DC, 0, 0, e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h, DC, 0, 0,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#SRCCOPY)



EndProcedure


Procedure E_CREATE_SCREEN_SHOT_FOR_SAVE_POINT()
  
  
  ;use this for any kind of screenshot situations!
  
;   If e_engine\e_start_position_screen_shot_taken=#True   ;set this value outside this routine to force screenshot of actual position in game/map/level
;   ProcedureReturn #False  
;   EndIf
  
 
  
 
  
  ;here we go for the save file pic:
  If IsSprite(e_engine\e_save_pictogram_id)
  FreeSprite(e_engine\e_save_pictogram_id)  
  EndIf
  
     e_engine\e_save_pictogram_id=GrabSprite(#PB_Any,1,1,e_engine\e_engine_internal_screen_w-1,e_engine\e_engine_internal_screen_h-1)


  If IsSprite(e_engine\e_save_pictogram_id)
    SaveSprite(e_engine\e_save_pictogram_id,e_engine\e_save_pictogram_path+e_engine\e_save_pictogram_file,#PB_ImagePlugin_PNG,10)
    CopyFile(e_engine\e_save_pictogram_path+e_engine\e_save_pictogram_file,e_engine\e_temp_core+e_engine\e_save_pictogram_file)
    Debug "SRC "+e_engine\e_save_pictogram_path+e_engine\e_save_pictogram_file
    Debug "DEST "+e_engine\e_temp_core+e_engine\e_save_pictogram_file
 EndIf

;e_engine\e_start_position_screen_shot_taken=#True  ;any way! so we do not try to grab screens/save screens if something went wrong

EndProcedure




Procedure E_SET_UP_SCREEN_SHOT_SYSTEM_FOR_SAVE()
  ;global settings for the screen shot routine
  
      
    ; e_engine\e_start_position_screen_shot_taken=#False
      E_CREATE_SCREEN_SHOT_FOR_SAVE_POINT() 
     
   EndProcedure
   
   

Procedure E_SHOW_PLAYER_HEARD_SYMBOLS()
  
   If e_engine\e_map_show_gui=#False
  ProcedureReturn #False  
  EndIf
  
If player_statistics\player_health_symbol_show=#False
  ProcedureReturn #False  
EndIf

If IsSprite(player_statistics\player_health_symbol_gfx_id)=0
ProcedureReturn #False  
EndIf



  Define _actual.b=1

  
    While _actual.b<=player_statistics\player_health_symbol_max_symbols
         DisplayTransparentSprite(player_statistics\player_health_symbol_gfx_id,player_statistics\player_health_symbol_pos_x+player_statistics\player_health_symbol_offset_x*_actual.b,player_statistics\player_health_symbol_pos_y+player_statistics\player_health_symbol_offset_y,player_statistics\player_health_symbol_transparency,RGB(10,10,10))
    _actual.b+1
  Wend
  _actual.b=1
  While _actual.b<=player_statistics\player_health_symbol_actual_symbol
         DisplayTransparentSprite(player_statistics\player_health_symbol_gfx_id,player_statistics\player_health_symbol_pos_x+player_statistics\player_health_symbol_offset_x*_actual.b,player_statistics\player_health_symbol_pos_y+player_statistics\player_health_symbol_offset_y,player_statistics\player_health_symbol_transparency)
    _actual.b+1
  Wend
  
  
EndProcedure


Procedure E_SHOW_GFX_FONT_DIGIT()
  ;here we show the digits only... u
  
  Define _dummy.s=Str(player_statistics\player_gold)
  Define _len.b=0
  Define _pos2.b=0,_pos1.b=0,_pos0.b=0
  
  If _dummy.s=""
  _dummy.s="000"  
  EndIf
  
  _len.b=Len(_dummy.s)

  _pos0.b=Val(Right(_dummy.s,1))
  _dummy.s=Left(_dummy.s,Len(_dummy.s)-1)
  _pos1.b=Val(Right(_dummy.s,1))
  _dummy.s=Left(_dummy.s,Len(_dummy.s)-1)
  _pos2.b=Val(Right(_dummy.s,1))
  
  gfx_font\gfx_font_object_pos_x=player_statistics\player_GUI_gold_pos_x+player_statistics\player_GUI_gold_width+player_statistics\player_GUI_gold_width
  
  
  If IsSprite(gfx_font\gfx_font_object_digit_id[_pos0.b])
      DisplayTransparentSprite(gfx_font\gfx_font_object_digit_id[_pos0.b],gfx_font\gfx_font_object_pos_x,player_statistics\player_GUI_gold_pos_y,player_statistics\player_health_symbol_transparency)
  EndIf
  
  If IsSprite(gfx_font\gfx_font_object_digit_id[_pos1.b])
        DisplayTransparentSprite(gfx_font\gfx_font_object_digit_id[_pos1.b],gfx_font\gfx_font_object_pos_x-SpriteWidth(gfx_font\gfx_font_object_digit_id[_pos1.b]),player_statistics\player_GUI_gold_pos_y,player_statistics\player_health_symbol_transparency)
  EndIf
  
  If IsSprite(gfx_font\gfx_font_object_digit_id[_pos2.b])
    DisplayTransparentSprite(gfx_font\gfx_font_object_digit_id[_pos2.b],gfx_font\gfx_font_object_pos_x-SpriteWidth(gfx_font\gfx_font_object_digit_id[_pos1.b])-SpriteWidth(gfx_font\gfx_font_object_digit_id[_pos2.b]),player_statistics\player_GUI_gold_pos_y,player_statistics\player_health_symbol_transparency)
  EndIf
  

EndProcedure


Procedure E_SHOW_PLAYER_GOLD()
  
  
  If e_engine\e_map_show_gui=#False
  ProcedureReturn #False  
  EndIf
  
  
   If IsSprite(player_statistics\player_GUI_gold_id)=0
  ProcedureReturn #False  
  EndIf
  

DisplayTransparentSprite(player_statistics\player_GUI_gold_id,player_statistics\player_GUI_gold_pos_x,player_statistics\player_GUI_gold_pos_y,player_statistics\player_health_symbol_transparency)  ;for testing just the health values...
E_SHOW_GFX_FONT_DIGIT() 
  
  
EndProcedure


Procedure E_SHOW_VERSION_INFO(e_version_info_text.s)
  
  
 If  e_version_info\map_show_version_info=#False
  ProcedureReturn #False  
EndIf


  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_DEBUG))
  DrawText(e_version_info\version_inf_x,e_version_info\version_inf_y,"Build:  "+e_version_info\version_info_text ,RGB(200,200,200))
  

  
EndProcedure




Procedure E_SHOW_DEMO_INFO()
  
  
 If  e_engine\e_engine_demo=#False
  ProcedureReturn #False  
EndIf


  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_DEBUG))
  DrawText(e_engine\e_engine_internal_screen_w-64,24,"DEMO" ,RGB(200,200,200))
  

  
EndProcedure


Procedure E_SHOW_BOSS_KILL_SWITCH()
  
  If e_engine\e_engine_boss_object_kill_switch=#False
  ProcedureReturn #False  
  EndIf
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_DEBUG))
  DrawText(e_engine\e_engine_internal_screen_w-600,320,"BOSS CHEAT MODE" ,RGB(Random(200),200,200))
  
  
EndProcedure








   Procedure E_SHOW_COORDINATES()
     
     If ListSize(world_object())<1
     ProcedureReturn #False  
     EndIf
     
     
     If world_object()\object_show_coordinates<>#True
     ProcedureReturn #False  
     EndIf
     
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(#FONT_DEBUG))
      DrawText(world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,StrF(world_object()\object_x+e_engine\e_world_offset_x)+":"+StrF(world_object()\object_y+e_engine\e_world_offset_y)+" T:"+Str(world_object()\object_reset_position_time_counter),RGB(255,0,255))
    
        
      EndProcedure
      
 
 
 

Procedure E_SHOW_MAP_NAME()
  
  If e_engine\e_map_name_show_total_timer>e_engine_heart_beat\beats_since_start
  ProcedureReturn #False  
  EndIf
  
  
  
  Define _map_name_part_1.s=""
  Define _map_name_part_2.s=""
  Define _found_comma.i=0
  
  
  If e_engine\e_actuall_world<>"dead.worldmap"
    If e_engine_heart_beat\beats_since_start>(e_map_name_show_on_screen.i+e_engine\e_map_name_start_show_timer) Or e_map_name_show.b=#False
      e_engine\e_wait_for_map_title=#False
  ProcedureReturn #False  
  EndIf
  EndIf
  
If Len(e_world_info_system\world_info_system_map_screen_name)<1
  ProcedureReturn #False
EndIf
  

DrawingMode(#PB_2DDrawing_Transparent)
DrawingFont(FontID(#FONT_MAP_NAME_ID))

e_world_info_system\world_info_system_map_screen_name=E_INTERPRETER_GET_KEYWORD(e_world_info_system\world_info_system_map_screen_name)

_found_comma.i=FindString(e_world_info_system\world_info_system_map_screen_name,",")
_map_name_part_1.s=Mid(e_world_info_system\world_info_system_map_screen_name,1,FindString(e_world_info_system\world_info_system_map_screen_name,",",1)-1)
_map_name_part_2.s=Mid(e_world_info_system\world_info_system_map_screen_name,2+FindString(e_world_info_system\world_info_system_map_screen_name,",",1))



   If IsImage(e_engine\e_map_name_background_id)
     DrawAlphaImage(ImageID(e_engine\e_map_name_background_id),0,e_world_info_system\world_info_system_map_name_pos_y-16,e_engine\e_world_map_name_banner_transparency) ;try without, may look better?
   EndIf

  If _found_comma.i<>0
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y,_map_name_part_1.s,RGB(100,100,100))
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y+1,_map_name_part_1.s,RGB(e_world_info_system\rgb_r_map,e_world_info_system\rgb_g_map,e_world_info_system\rgb_b_map))
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y+e_world_info_system\world_info_system_map_name_line_offset,_map_name_part_2.s,RGB(100,100,100))
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y+e_world_info_system\world_info_system_map_name_line_offset+1,_map_name_part_2.s,RGB(e_world_info_system\rgb_r_map,e_world_info_system\rgb_g_map,e_world_info_system\rgb_b_map))
  
Else
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y,e_world_info_system\world_info_system_map_screen_name,RGB(100,100,100))
  DrawText(e_world_info_system\world_info_system_map_name_pos_x,e_world_info_system\world_info_system_map_name_pos_y+1,e_world_info_system\world_info_system_map_screen_name,RGB(e_world_info_system\rgb_r_map,e_world_info_system\rgb_g_map,e_world_info_system\rgb_b_map))
  
EndIf


  
  
EndProcedure



Procedure E_SHOW_CRT_INFO()
  
If e_engine\e_crt_show=#False
  ProcedureReturn #False  
EndIf


 DrawingMode(#PB_2DDrawing_Transparent)
 DrawingFont(FontID(#FONT_DEBUG))
 DrawText(0,e_version_info\version_inf_y,"CRT MODE : OFF = F11",RGB(200,200,200))
  
EndProcedure



Procedure E_SHOW_INFO_ON_MAP()
  
  ;called by E_GLOBAL_TEXT_OUTPUT()
  
  
  If e_engine\e_map_name_show_total_timer>e_engine_heart_beat\beats_since_start
  ProcedureReturn #False  
  EndIf
  
  
  If Len(e_world_info_system\world_info_system_permanent_text)<1
    ProcedureReturn #False
  EndIf
  
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_SCREEN_HEAD))
  
  e_world_info_system\world_info_system_permanent_text=E_INTERPRETER_GET_KEYWORD(e_world_info_system\world_info_system_permanent_text)
  
  DrawText(e_world_info_system\world_info_system_permanent_text_x,e_world_info_system\world_info_system_permanent_text_y,e_world_info_system\world_info_system_permanent_text,RGB(50,50,50))
  DrawText(e_world_info_system\world_info_system_permanent_text_x,e_world_info_system\world_info_system_permanent_text_y+1,e_world_info_system\world_info_system_permanent_text,RGB(e_world_info_system\rgb_r,e_world_info_system\rgb_g,e_world_info_system\rgb_b))
  
  
  
  
EndProcedure


Procedure E_SHOW_INFO_TEXT()
  ;here we show some info text if system says so:
  
  If e_ingame_info_text\show=#False
  ProcedureReturn #False  
  EndIf
  
  DrawText(e_ingame_info_text\x,e_ingame_info_text\y,e_ingame_info_text\text,RGB(e_ingame_info_text\r,e_ingame_info_text\g,e_ingame_info_text\b),RGB(e_ingame_info_text\r,e_ingame_info_text\g,e_ingame_info_text\b))
  
EndProcedure






Procedure  E_GLOBAL_TEXT_OUTPUT()
  
e_engine\DC=StartDrawing(ScreenOutput())
E_SHOW_TIMER_OBJECT()
E_SHOW_MAP_NAME()
E_SHOW_INFO_ON_MAP()
E_SHOW_BOSS_NAME()
E_SCROLL_TEXT_BASE()
E_NPC_TEXT_OUTPUT()
E_SHOW_VERSION_INFO(e_version_info\version_info_text)
E_SHOW_CRT_INFO()
E_SHOW_DEBUG_INFO()
E_SHOW_COORDINATES()
E_SHOW_DEMO_INFO()
;E_SHOW_INFO_TEXT()
;E_SHOW_TEXT_INPUT_FIELD()
E_SHOW_FPS()
E_SHOW_BOSS_KILL_SWITCH()
E_GRAY_SCALE(e_engine\DC)
StopDrawing()


EndProcedure 




  Procedure E_DRAW_FINAL_RENDER_WIN()
    ;just a simple overlay, shows game/engine state and player data(game data)
  
    
    If e_engine\e_gfx_pause_valid=#True And e_engine\e_engine_mode=#PAUSE  
     
      DisplayTransparentSprite(e_engine\e_gfx_pause_id,e_engine\e_gfx_position_x,e_engine\e_gfx_position_y,240)  
      e_engine\e_show_gray_scale=#True
      E_GAME_PAUSE_DIALOG()
      
    EndIf
    
    If e_engine\e_engine_mode=#GAME_OVER
          E_GAME_OVER()
    EndIf
    
    If e_engine\e_engine_mode=#NO_XBOX_INPUT_DEVICE 
      
    
    DisplayTransparentSprite(e_engine\e_gfx_no_controller_id,0,0,255)
    E_MISSING_CONTROLLER_DIALOG()
          
    EndIf
    
  EndProcedure



Procedure E_SHOW_PLAY_FIELD()
  ;draw the mess
  
  If e_show_play_field.b=#False
     e_world_shake\world_shake_horizontal=0  ;reset world shake(rumble)
     e_world_shake\world_shake_vertical=0
    ProcedureReturn #False 
  EndIf
  
E_STAMP_OVERLAY()
E_SHOW_WORLD_START()
E_STAMP_OVERLAY_SHOW()

E_BOSS_SHOW_HEALTH_BAR(#False)  
;----------------
E_GLOBAL_TEXT_OUTPUT()
E_BOSS_SHOW_HEALTH_BAR(#BOSS_BAR_SHOW_COVER)
E_SHOW_PLAYER_HEARD_SYMBOLS()
E_SHOW_PLAYER_GOLD()
E_GLOBAL_FPS_COUNTER()
E_DRAW_FINAL_RENDER_WIN() 
E_SHOW_CRT_EFFECT()

FlipBuffers()


         

EndProcedure


; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 251
; FirstLine = 215
; Folding = --
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant