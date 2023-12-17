
Procedure E_MENU_EVENT()
  
  Select EventMenu()
      
    Case #E_MENU_ABOUT
          E_ERROR(#WARNING_ABOUT)
      
    Case #E_MENU_LOAD_DEFAULT
      E_LOAD_DEFAULT_AI_FILE(creator\creator_default_object_file)
      E_DRAW_GFX_NO_GFX()
      
    Case #E_MENU_LOAD_FILE
      E_LOAD_REQUEST()
               
    Case #E_MENU_SAVE_AS
      E_SAVE_REQUEST()
      
       Case #E_MENU_SAVE
      E_SAVE_NO_REQUEST()
      
    Case #E_MENU_SAVE_DEFAULT
     If E_ERROR(#WARNING_YES_NO)=#PB_MessageRequester_Yes
      E_SAVE_DEFAULT_AI_FILE(creator\creator_default_object_file)
    EndIf
      
    Case #E_MENU_SET_GFX_OBJECT
         E_SET_GFX()
      
    Case #E_MENU_QUIT
      E_ERROR(#WARNING_QUIT)
      
    Case #E_MENU_GFX_TO_FRONT
      If IsWindow(creator_window\window_child_id)
        SetActiveWindow(creator_window\window_child_id)
        E_SHOW_GFX()
      Else 
        E_CREATE_CHILD_WINDOW()
        E_SHOW_GFX()
      EndIf
      
    Case #E_MENU_ACTIVATE_NOT_ACTIVATED
      
      If E_ERROR(#WARNING_AUTO_AI_SET_YES_NO)=#PB_MessageRequester_Yes
        E_SET_DIRECTORY_WHERE_NON_ACTIVATED()
      EndIf
         
   Case #E_MENU_SHOW_ASSET_FOLDER
      E_SHOW_ASSET_FOLDER()
      
    Case #E_MENU_Ai42_REBUILD
      E_STACK_SAVE_LOAD_SCANNER()
  EndSelect
    
EndProcedure

Procedure  E_RESIZE_WINDOW()
  
  Select EventWindow()
      
    Case creator_window\window_child_id
      E_DRAW_GFX()
      
  EndSelect
  
EndProcedure

Procedure E_CHECK_EVENT(_event.i)
  ;here we go for the events
  
  Select _event.i
      
    Case #PB_Event_CloseWindow
      
      E_ERROR(#WARNING_QUIT)
      
    Case #PB_Event_SizeWindow
 E_RESIZE_WINDOW()
      
      Case #PB_Event_Menu
        E_MENU_EVENT()
        
      Case #PB_Event_Gadget
        E_HIGHLIGHT_OBJECTS_IN_TOUCH(EventGadget())
        
  EndSelect
  
EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 86
; FirstLine = 63
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