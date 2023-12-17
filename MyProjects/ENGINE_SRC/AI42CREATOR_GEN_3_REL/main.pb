;LICENCE: OPENSOURCE/FREEWARE
;CONCEPT AND PROGRAMMING: (C) DEUTSCHMANN WALTER (MARK DOWEN)
;COMPILER PURBASIC 6.00 CBE

EnableExplicit
XIncludeFile "constant.pbi"
XIncludeFile "env.pbi"
XIncludeFile "error.pbi"
XIncludeFile "parser.pbi"
XIncludeFile "creator_main_window.pbi"
XIncludeFile "gadget_system.pbi"
XIncludeFile "io.pbi"
XIncludeFile "input_system.pbi"
XIncludeFile "check_event.pbi"

E_PARSE_CREATOR_INI_FILE(creator\creator_ini_file)
E_OPEN_MAIN_WINDOW()
E_ADD_MENU()
E_ADD_SCROLL_AREA_GADGET()
E_LOAD_DEFAULT_AI_FILE(creator\creator_default_object_file)
E_CREATE_CHILD_WINDOW()

Repeat
  
  creator_window\window_event=WaitWindowEvent()
  
  If creator_window\window_event
    E_CHECK_EVENT(creator_window\window_event)
  EndIf  
  
Until creator\creator_signal=#E_END
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 29
; FirstLine = 5
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; UseIcon = 0.ico
; Executable = DNA_CREATOR.exe
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; Compiler = PureBasic 6.03 beta 4 LTS (Windows - x64)
; EnableCompileCount = 671
; EnableBuildCount = 79
; EnableExeConstant