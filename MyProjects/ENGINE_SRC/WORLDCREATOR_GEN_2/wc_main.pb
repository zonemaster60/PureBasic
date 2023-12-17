;world creator 

EnableExplicit  ;no vars without decleration
XIncludeFile "wc_fundament.pb"
XIncludeFile "wc_const.pb"
XIncludeFile "wc_system.pb"
XIncludeFile "wc_vars.pb"
XIncludeFile "wc_error.pb"
XIncludeFile "wc_parser.pb"
XIncludeFile "wc_object_parser.pb"
XIncludeFile "wc_window_system.pb"
XIncludeFile "wc_handler.pb"
XIncludeFile "wc_display.pb"
XIncludeFile "develope_log.pb"

If InitSound()
  wc_sound_system_valid.b=#True
Else
  wc_sound_system_valid.b=#False
EndIf

Procedure WC_INFO()
  
  ;------------------------------------ WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO 
Define _ok.l=0 ;for first start warning !!!!! to make shure user reads the info
_ok.l=MessageRequester("BUILD "+Str(#PB_Editor_BuildCount)+" BUGFIXES, USE AT YOUR OWN RISK ",Chr(13)+Chr(13)+"FEATURELIST:"+Chr(13)+"AUTO_CREATE: NPC BASE_FILE (EN,DE), MAP_NAME_BASE_FILE"+Chr(13)+"NEW OBJECT SAVE/LOAD SYSTEM USES KEYWORDS INSTEAD OF FULL RELATIVE PATH"+Chr(13)+"ADD_GLOBAL_SOUND,ADD_QUEST"+Chr(13)+"Code & Concept (C)2019 DEUTSCHMANN WALTER   "+Chr(13)+"Developed And Coded using 'PUREBASIC' "+Chr(13)+"https://www.purebasic.com/",#PB_MessageRequester_Info)
;----------------------------------- WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO 

EndProcedure

;some defaults;

ExamineDesktops()
WC_INFO()
WC_INI_BASE() ;call  the ini parser and set up for program start
WC_GLOBAL(v_ini_path.s)
WC_OPEN_WINDOW()
WC_OPEN_OBJECT_WINDOW()
WC_CHECK_RESOURCE()
WC_CHECK_RESOURCE_SOUND()
WC_LIST_RESOURCE_DIRECTORY()
WC_OBJECT_FILE_MERGER()
WC_SORT_GADGET_GFX()
WC_LOAD_OBJECT_GFX()
WC_SET_WINDOW_MENU(v_menu_script_path,v_window_parent_id.i)
WC_SET_DEFAULT_MENU_STATE_ON_START()
WC_GETDEL_POINTER()
;----------------------------------debugger------------------logs ----------------------------
DEV_LISTLOG()
;--------------------------------------------------------------------------------------------
wc_area_container_path.s=v_resource_path.s+wc_area_container_base

;ini for some values:

Repeat 
  
  v_event.l=WaitWindowEvent(0)
  
  If  v_event.l
    WC_GET_MOUSE_DESKTOP()
    WC_EVENT(v_event.l)
    WC_KEYBOARD(EventWindow())
  Else
    WC_SHOW_MAIN_SCREEN()   
  EndIf
  
ForEver



; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 63
; FirstLine = 21
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; UseIcon = WorldCreator.ico
; Executable = worldcreator.exe
; CPU = 1
; DisableDebugger
; EnableCompileCount = 681
; EnableBuildCount = 105
; EnableExeConstant