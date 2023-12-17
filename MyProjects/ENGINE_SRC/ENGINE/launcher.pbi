;Engine Launcher!
;this is the starticon for the engine
;we start the engine as process!





Structure engine_launcher
  launch_path.s
  init_path.s
  ini_file_id.i
  key_word.s
  argument.s
  request.b
  engine_id.i
  setup_path.s
  hand_shake.s
  hand_shake_id.i
  win_pos_x.f
  win_pos_y.f
  win_w.f
  win_h.f
  win_bg_immage.i
  win_bg_immage_path.s
  win_bg_gadget_id.i
  win_id.i
  silent.b
  event.i
  gadget_ok.i
  gadget_gadget_container.i
  gadget_true_screen.i
  gadget_full_screen.i
  engine_screen_full.s
  engine_true_screen.b
  launcher_prefs_base.s
  crt_show.b
EndStructure

Global engine_launcher.engine_launcher

engine_launcher\launcher_prefs_base="data/ini/prefs.ini"
engine_launcher\engine_screen_full="YES"
engine_launcher\engine_true_screen=e_engine\e_true_screen ;default
engine_launcher\crt_show=0

Procedure E_LAUNCHER_WRITE_SETTINGS()
  ;here we write a snipped for the engine to overwrite the engine defaultsettings
  Define _file_id.i=0
  
  _file_id.i=CreateFile(#PB_Any,v_engine_base.s+engine_launcher\launcher_prefs_base)
  
  If IsFile(_file_id.i)=0
  ProcedureReturn #False ;no personal prefs  
EndIf

WriteStringN(_file_id.i,"FULLSCREEN")
WriteStringN(_file_id.i,engine_launcher\engine_screen_full)
WriteStringN(_file_id.i,"TRUE_SCREEN")
WriteStringN(_file_id.i,Str(engine_launcher\engine_true_screen))
WriteStringN(_file_id.i,"SHOW_CRT")
WriteStringN(_file_id.i,Str(engine_launcher\crt_show))

CloseFile(_file_id.i)
  
EndProcedure




Procedure E_LAUNCHER_SHOW_GRAPHICS()
  
   StartDrawing(WindowOutput(engine_launcher\win_id))
 If IsImage(engine_launcher\win_bg_immage)
    DrawAlphaImage(ImageID(engine_launcher\win_bg_immage),1,1,255)
 EndIf
 StopDrawing()
  
EndProcedure


Procedure E_LAUNCHER_LOAD_GRAPHICS()
  
  engine_launcher\win_bg_immage=LoadImage(#PB_Any,engine_launcher\win_bg_immage_path,0)
  
  
  

  
EndProcedure


Procedure E_CLEAN_UP_LAUNCHER()
  
  If IsImage(engine_launcher\win_bg_immage)
    FreeImage(engine_launcher\win_bg_immage)
  EndIf
  
  CloseWindow(engine_launcher\win_id)
 
  
EndProcedure




Procedure E_LAUNCHER_EVENTS(_event.i)
  
  Select _event.i
      
    Case #PB_Event_Gadget
      
      Select EventGadget()
          
        Case engine_launcher\gadget_full_screen
          engine_launcher\engine_screen_full="YES"
          engine_launcher\engine_true_screen=0
          engine_launcher\crt_show =0
          
        Case engine_launcher\engine_true_screen
          engine_launcher\engine_true_screen=1
          engine_launcher\engine_screen_full="NO"
         engine_launcher\crt_show=1
          
          
      EndSelect
      
    Case #PB_Event_Repaint, #PB_Event_ActivateWindow
      E_LAUNCHER_SHOW_GRAPHICS()
      
      
  EndSelect
  

EndProcedure


Procedure E_OPEN_LAUNCHER_WIN()
  
  ;here we go for the launcher window #
  ;here we sho some important informations about engine and settings
  ;launcher is used for file and update integrity of the engine game data
  
  ;we center(backup data) for resize
  Define _d.i=ExamineDesktops()
  

  
  
  engine_launcher\win_id=OpenWindow(#PB_Any,engine_launcher\win_pos_x,engine_launcher\win_pos_y,engine_launcher\win_w,engine_launcher\win_h,"Engine Launcher: Engine: Build:  "+e_version_info\version_info_text,#PB_Window_ScreenCentered|#PB_Window_SystemMenu)
  

 ;add gadgets (actually with fixed values, should be outsourced to script?)
 
  engine_launcher\win_pos_x=(DesktopWidth(0)/2)/DesktopResolutionX()-engine_launcher\win_w/2
  engine_launcher\win_pos_y=(DesktopHeight(0)/2)/DesktopResolutionY()-engine_launcher\win_h/2
 
 ResizeWindow(engine_launcher\win_id,engine_launcher\win_pos_x,engine_launcher\win_pos_y,e_engine\e_engine_internal_screen_w/DesktopResolutionX(),e_engine\e_engine_internal_screen_h/DesktopResolutionY())
 
 ;engine_launcher\gadget_gadget_container=ContainerGadget(#PB_Any,0,0,engine_launcher\win_w,engine_launcher\win_h)
 
;  If IsGadget(engine_launcher\gadget_gadget_container)=0
;  E_CLEAN_UP_LAUNCHER()
;  EndIf
 
 E_LAUNCHER_LOAD_GRAPHICS()

 ;no add other gadgets:
 ;engine_launcher\gadget_ok=ButtonGadget(#PB_Any,620/DesktopResolutionX(),670/DesktopResolutionY(),64/DesktopResolutionX(),32/DesktopResolutionY(),"OK",#PB_Button_Default)
 engine_launcher\gadget_full_screen=ButtonGadget(#PB_Any,340/DesktopResolutionX(),500/DesktopResolutionY(),256/DesktopResolutionX(),32/DesktopResolutionY(),"FULLSCREEN (WINDOW)",#PB_Button_Default)
 engine_launcher\gadget_true_screen=ButtonGadget(#PB_Any,600/DesktopResolutionX(),500/DesktopResolutionY(),256/DesktopResolutionX(),32/DesktopResolutionY(),"TRUESCREEN",#PB_Button_Default)

 E_LAUNCHER_SHOW_GRAPHICS()
 
 Repeat 
   
   engine_launcher\event=WaitWindowEvent()
   
   If engine_launcher\event=#PB_Event_CloseWindow
     E_CLEAN_UP_LAUNCHER()
     E_QUIT()
   EndIf
   
  
   
   
 Until engine_launcher\event=#PB_Event_Gadget
 
 E_LAUNCHER_EVENTS(engine_launcher\event)
 E_LAUNCHER_WRITE_SETTINGS()
 E_CLEAN_UP_LAUNCHER()

EndProcedure



Procedure E_ENGINE_USER_SETTINGS()
  
  
  If e_engine\e_use_launcher=#False
  ProcedureReturn #False   
  EndIf
  

  
engine_launcher\init_path=GetCurrentDirectory()+"data\launcher_init.ini"

engine_launcher\ini_file_id=ReadFile(#PB_Any,engine_launcher\init_path)

If engine_launcher\ini_file_id=0
    engine_launcher\request=MessageRequester("ENGINE LAUNCHER","Missing  "+engine_launcher\init_path,#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
  ProcedureReturn #False ;we go on without personal settings
EndIf

While Not Eof(engine_launcher\ini_file_id)
  
  engine_launcher\key_word=Trim(ReadString(engine_launcher\ini_file_id))
  
  Select engine_launcher\key_word
      

      
    Case "WIN_W"
    engine_launcher\win_w=ValF(ReadString(engine_launcher\ini_file_id) )
  Case "WIN_H"
    engine_launcher\win_h=ValF(ReadString(engine_launcher\ini_file_id)  )
      
  Case "WIN_X"
    engine_launcher\win_pos_x=ValF(ReadString(engine_launcher\ini_file_id)  )
      
  Case "WIN_Y"
    engine_launcher\win_pos_y=ValF(ReadString(engine_launcher\ini_file_id)  )
    
  Case "WIN_BG"
    engine_launcher\win_bg_immage_path=e_engine\e_graphic_source+ReadString(engine_launcher\ini_file_id) 
    
  Case "SILENT"
    engine_launcher\silent=Val(ReadString(engine_launcher\ini_file_id))
      
  EndSelect
  
  
  
Wend

CloseFile(engine_launcher\ini_file_id)


E_OPEN_LAUNCHER_WIN()
  
  EndProcedure


