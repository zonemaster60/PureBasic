





Procedure E_SCROLL_TEXT_LOAD(_work_file.s)
  
  
   If e_engine\e_map_show_scroll_text=#False
    ProcedureReturn #False  
  EndIf
  
  Define _work_file_id.i=0
  Define _scroll_text_pos_x.f=0
  Define _scroll_text_pos_y.f=0
  Define _color.i=0
  Define _r.i=0
  Define _g.i=0
  Define _b.i=0
  Define _dummy.s=""
  Define _work_file_backup.s=""
  Define _header_found.b=#False
 
  e_engine\e_scroll_text_is_valid=#False
  
  If ListSize(engine_text_system())>=1
    ResetList(engine_text_system())
    ForEach engine_text_system()
      engine_text_system()\engine_text_string=""  
    Next
    ClearList(engine_text_system())
    
  EndIf

  
_work_file_backup.s=_work_file.s
_work_file.s+e_engine\e_world_map_name_language_suffix
  
  
  _work_file_id.i=ReadFile(#PB_Any,_work_file.s)
  
  If _work_file_id.i=0
     _work_file_id.i=ReadFile(#PB_Any,_work_file_backup.s)  ;fallback to "English"/default
   
    
     If _work_file_id.i=0
        ProcedureReturn #False  ;nothing to do....
     EndIf
     
  EndIf
  
  ;first we read the basic color settings (global text)
  
  ;go for the header:
  
  
  While _header_found.b=#False And Not(Eof(_work_file_id.i))
    
    _dummy.s=ReadString(_work_file_id.i)
    If FindString(_dummy.s,"SCROLLTEXT")
    _header_found.b=#True  
    EndIf
    
    
    
  Wend
  
  If _header_found.b=#False
  ProcedureReturn #False  
  EndIf
  ;new system not compatible with old format
  
  Repeat 
    _dummy.s=ReadString(_work_file_id.i)
    
    
    Select _dummy.s
        
      Case "#R#"
        _r.i=Val(ReadString(_work_file_id.i))
      Case "#G#"
          _g.i=Val(ReadString(_work_file_id.i)  )
      Case "#B#"
        _b.i=Val(ReadString(_work_file_id.i)  )
      Case "#X#"
         _scroll_text_pos_x.f=ValF(ReadString(_work_file_id.i)  )
      Case "#Y#"
         _scroll_text_pos_y.f=ValF(ReadString(_work_file_id.i)  )
      Case "#SCROLLSPEED_UP#"
         e_scroll_text_move_y.f=ValF(ReadString(_work_file_id.i))
      Case "#SCROLL_SPEED_DOWN#"
        
      Case "#SCROLL_SPEED_LEFT#"
        
      Case "#SCROLL_SPEED_RIGHT#"
        
      Case "#SCROLL_TEXT_MARGIN_TOP#"
        e_engine\e_scroll_text_margin_top=ValF(ReadString(_work_file_id.i))
        
      Case "#SCROLL_TEXT_MARGIN_BOTTOM#"
         e_engine\e_scroll_text_margin_bottom=ValF(ReadString(_work_file_id.i))
      
      
        
    EndSelect
    

      
    
Until _dummy.s="#END#" Or Eof(_work_file_id.i)
  
  
If  e_engine\e_scroll_text_margin_bottom=0
e_engine\e_scroll_text_margin_bottom=e_engine\e_engine_internal_screen_h
EndIf

  
  
  _color.i=RGB(_r.i,_g.i,_b.i)
  
  While Not Eof(_work_file_id.i)
    If AddElement(engine_text_system())
      
    Else
      ProcedureReturn #False
    EndIf
    
    engine_text_system()\engine_text_string=ReadString(_work_file_id.i)
    engine_text_system()\engine_text_pos_y=(ListSize(engine_text_system())*e_GUI_font\e_GUI_info_font_size)
    engine_text_system()\engine_text_pos_x=_scroll_text_pos_x.f
    engine_text_system()\engine_text_color_RGB=_color.i
  Wend
  
  e_engine\e_scroll_text_is_valid=#True
  e_scroll_text_start_backup_y.f=_scroll_text_pos_y.f
  e_engine\e_scroll_text_start_y=_scroll_text_pos_y.f
  
  CloseFile(_work_file_id.i)
  
  
EndProcedure




Procedure E_SCROLL_TEXT_OUTPUT()
  
   If e_engine\e_map_show_scroll_text=#False
    ProcedureReturn #False  
  EndIf
  
  ResetList(engine_text_system())
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_INFO_FONT))
  
  ForEach engine_text_system()
    If engine_text_system()\engine_text_pos_y<e_engine\e_scroll_text_margin_bottom And engine_text_system()\engine_text_pos_y>e_engine\e_scroll_text_margin_top
      DrawText(engine_text_system()\engine_text_pos_x,engine_text_system()\engine_text_pos_y+e_engine\e_scroll_text_start_y,engine_text_system()\engine_text_string,engine_text_system()\engine_text_color_RGB)
    EndIf
    
  Next

  LastElement(engine_text_system())
  If (engine_text_system()\engine_text_pos_y+e_engine\e_scroll_text_start_y)<e_engine\e_scroll_text_margin_top
    e_engine\e_scroll_text_start_y=e_scroll_text_start_backup_y.f
  EndIf
  
  

EndProcedure



Procedure E_SCROLL_TEXT_MOVE()
  
  ;here we go for the values... this is called from core (timerbased) so we have fixed speed , no fps target
  
  If e_engine\e_map_show_scroll_text=#False
    ProcedureReturn #False  
  EndIf
  
  e_engine\e_scroll_text_start_y-e_scroll_text_move_y.f

  
EndProcedure
  


Procedure E_SCROLL_TEXT_BASE()
  
If e_engine\e_map_show_scroll_text=#False
  ProcedureReturn #False  
EndIf

If ListSize(engine_text_system())<1
ProcedureReturn #False  
EndIf



E_SCROLL_TEXT_OUTPUT()

EndProcedure



  Procedure E_GLOBAL_FPS_COUNTER()
         
   ;this routine is for engine internal fps analysis, we can use for frame based  actions (like skip if frames to low....)
   Static _frame_time.i=0
   Static _frame_id.i=0
   Static _start_time.i=0
   Static _end_time.i=0
   Static _c.f=0
   Static _s.f=0

    
   If _start_time.i=0
     _start_time.i=ElapsedMilliseconds()
   EndIf
   _frame_id.i+1
   
   _end_time.i=ElapsedMilliseconds()  
   
  If (_end_time.i  - _start_time.i)>999
    e_engine\e_global_fps=_frame_id.i
    e_engine_build_in_effect\e_frame_rate=_frame_id.i
     _start_time.i=0
     _frame_id.i=0
 EndIf
 

 
EndProcedure

Procedure E_SHOW_FPS()
  
    If e_engine\e_show_FPS=0
    ProcedureReturn #False  
  EndIf
  
   DrawingMode(#PB_2DDrawing_Default)
   DrawingFont(FontID(#FONT_INFO_FONT))
   
   DrawText(v_screen_w.f-700,100,"TFPS: "+Str(e_engine\e_frame_target),RGB(200,20,20),RGB(0,0,0))
  If  e_engine\e_global_fps>DesktopFrequency(0)/2
    DrawText(v_screen_w.f-600,100,"MFR: "+Str(e_engine\e_global_fps),RGB(20,200,20),RGB(0,0,0))
  Else
    DrawText(v_screen_w.f-600,100,"MFR: "+Str(e_engine\e_global_fps),RGB(200,20,20),RGB(0,0,0))
  EndIf
  
  DrawText(v_screen_w.f-500,100,"RAM: "+Str(GetCurrentMemoryUsage()/1024/1024),RGB(200,200,200),RGB(0,0,0))
  
  DrawText(v_screen_w.f-400,100,"OBS: "+Str(e_engine\e_objects_in_screen),RGB(200,200,200),RGB(0,0,0))
  
  DrawText(v_screen_w.f-200,100,"CIO: "+Str(e_engine\e_crypto_io_counter),RGB(200,200,200),RGB(0,0,0))
  
  DrawText(v_screen_w.f-300,100,"CIF: "+Str(e_engine\e_crypto_io_counter_fail),RGB(200,200,200),RGB(0,0,0))
  

  
EndProcedure


Procedure E_SHOW_DEBUG_INFO()
  
   If e_engine\e_show_debug<>#True
    ProcedureReturn #False  
  EndIf
  
  Define _dummy_text_for_input_device.s="KEY"
  Define _offset_y.f=32

  
  
  If IsScreenActive()=0
    ProcedureReturn #False
  EndIf
  


  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_DEBUG))
  
  DrawText(v_screen_w.f-200,10+_offset_y.f,"GOD:"+Str(e_godmode.b),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,24+_offset_y.f,"RAM: "+Str(GetCurrentMemoryUsage()/1024/1024),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,40+_offset_y.f,"OIS: "+Str(e_engine\e_objects_in_screen),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-1200,-16+_offset_y.f,"MAP: "+e_engine\e_actuall_world+" FILE: "+e_world_info_system\world_info_system_map_name,RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-1200,_offset_y.f,"NAME:   "+e_world_info_system\world_info_system_map_screen_name,RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,72+_offset_y.f,"OBJ: "+Str(ListSize(world_object())),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,88+_offset_y.f,"IDXi: "+Str(ListSize(indexeI())),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,104+_offset_y.f,"IDXc: "+Str(ListSize(indexerC())),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,120+_offset_y.f,"ERR: "+Str(e_engine\e_error_detected),RGB(200,200,200),RGB(0,0,0))
  
  DrawText(v_screen_w.f-200,152+_offset_y.f,"HP: "+Str(player_statistics\player_health_actual),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,168+_offset_y.f,"HEALMAX: "+StrF(player_statistics\player_health_symbol_max_symbols),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,184+_offset_y.f,"HEALDEF: "+StrF(player_statistics\player_health_symbol_max_symbols_default),RGB(200,200,200),RGB(0,0,0))

  DrawText(v_screen_w.f-200,200+_offset_y.f,"DEF: "+StrF(player_statistics\player_level_defence),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,216+_offset_y.f,"ATT: "+StrF(player_statistics\player_level_fight),RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,232+_offset_y.f,"LANG: "+ e_engine\e_locale_suffix,RGB(200,200,200),RGB(0,0,0))
  DrawText(v_screen_w.f-200,248+_offset_y.f,"GUARDS:"+Str(e_engine\e_count_active_boos_guards),RGB(200,200,200),RGB(0,0,0))
  If  e_xbox_controller\xbox_joystick_present=#True
    _dummy_text_for_input_device.s="XBX"
  EndIf
  If  e_engine\e_global_fps>DesktopFrequency(0)/2
    DrawText(v_screen_w.f-200,280+_offset_y.f,"MFR: "+Str(e_engine\e_global_fps),RGB(20,200,20),RGB(0,0,0))
  Else
    DrawText(v_screen_w.f-200,280+_offset_y.f,"MFR: "+Str(e_engine\e_global_fps),RGB(200,20,20),RGB(0,0,0))
  EndIf
  
  DrawText(v_screen_w.f-200,312+_offset_y.f,"FOV_X/Y: "+ StrF(e_engine\e_fov_x)+"/"+StrF(e_engine\e_fov_y),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,338+_offset_y.f,"GFOV:"+StrF(e_gfx_fov.f),RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-1200,16+_offset_y.f,"SCROLLTEXT"+e_engine\e_scroll_text_source+"  SHOW TEXT:"+Str(e_engine\e_map_show_scroll_text),RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-1200,58+_offset_y.f,"FONTPATHS: "+e_font_directory.s,RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-200,412+_offset_y.f,"PLGRND:"+Str(player_statistics\player_on_ground),RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-200,428+_offset_y.f,"PLCLMP:"+StrF(player_statistics\player_does_climp),RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-1200,36+_offset_y.f,"INPUT:"+  e_xbox_controller\xbox_joystick_name+" EXPECTED: "+e_xbox_controller\controller_suffix,RGB(200,100,100),(RGB(0,0,0)))
  DrawText(v_screen_w.f-200,442+_offset_y.f,"TICKS:"+ Str(e_engine\e_server_ticks),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,466+_offset_y.f,"FONT:"+ e_GUI_font\e_GUI_screen_head_font,RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,484+_offset_y.f,"HEARTRATE:"+ Str(e_engine_heart_beat\heart_rate),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,504+_offset_y.f,"HEARTBEATS:"+ Str(e_engine_heart_beat\beats_since_start),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,528+_offset_y.f,"AXEAKTIVE:"+ Str(player_statistics\player_weapon_axe),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,552+_offset_y.f,"ACT_ENEMY:"+ Str(e_engine\e_enemy_count),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-1200,24+_offset_y.f,"SILUETTE_FILE: "+ e_engine\e_siluette_path,RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,596+_offset_y.f,"AXETIMEOUT:"+ Str(e_fight_timeout.i),RGB(200,100,100),RGB(0,0,0))
  DrawText(v_screen_w.f-200,620+_offset_y.f,"ISO: "+Str(e_engine\e_iso_mode),RGB(200,100,100),RGB(0,0,0))
   

  
EndProcedure
   


; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 68
; FirstLine = 38
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; EnableOnError
; Executable = project17_adventure.exe
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant