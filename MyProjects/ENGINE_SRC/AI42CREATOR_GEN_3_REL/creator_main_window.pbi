;here we go for the main window:

Declare E_DRAW_GFX()

Procedure E_SHOW_GFX()
  E_DRAW_GFX()
EndProcedure

Procedure E_SHOW_ASSET_FOLDER()
  
  RunProgram("explorer.exe",GetPathPart(creator\creator_last_file),"")

EndProcedure

Procedure E_OPEN_MAIN_WINDOW()
  creator_window\window_id=OpenWindow(#PB_Any,creator_window\window_x,creator_window\window_y,creator_window\window_widht,creator_window\window_height,creator_window\window_title+" "+creator\creator_last_file+" DNA_SIZE: "+Str(creator\creator_objects_in_dna),#PB_Window_SystemMenu|#PB_Window_MaximizeGadget|#PB_Window_MinimizeGadget|#PB_Window_TitleBar|#PB_Window_SizeGadget|#PB_Window_Maximize)
  
  If IsWindow(creator_window\window_id)=0
  E_ERROR(#ERROR_WINDOW_MAIN)
EndIf
  
EndProcedure

Procedure E_CREATE_CHILD_WINDOW()
  creator_window\window_child_id=OpenWindow(#PB_Any,creator_window\window_x,creator_window\window_y,320,256,"GFX",#PB_Window_SizeGadget|#PB_Window_TitleBar|#PB_Window_Tool,WindowID(creator_window\window_id))
  
  If WindowID(creator_window\window_child_id)=0
    E_ERROR(#WARNING_WINDOW_CHILD)
  Else
  SetWindowColor(creator_window\window_child_id,RGB(50,50,50)) 
  ;StickyWindow(creator_window\window_child_id,#True)
  EndIf
  
EndProcedure



; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 32
; FirstLine = 12
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0