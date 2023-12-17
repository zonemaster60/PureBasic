;Create Window:
OpenWindow(0, #PB_Ignore, #PB_Ignore, 800, 600, "Simple Text Editor", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)

;Add menus:
CreateMenu(0, WindowID(0))
MenuItem(1, "&Open")
MenuItem(2, "&Save")
MenuItem(3, "&Exit")

;Add Editor:
EditorGadget(0, 0, 0, 0, 0)
SetGadgetFont(0, LoadFont(0, "Courier New", 10))

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

;Process window messages until closed:
Repeat
    Select WaitWindowEvent()
    Case #PB_Event_Menu
        Select EventMenu()
        Case 1: MessageRequester("Open clicked directly or with '&' mnemonic.", GetGadgetText(0))
        Case 2: MessageRequester("Save clicked directly or with '&' mnemonic.", GetGadgetText(0))
        Case 3: 
          JustExit()
        EndSelect
    Case #PB_Event_SizeWindow: ResizeGadget(0, 0, 0, WindowWidth(0, #PB_Window_InnerCoordinate), WindowHeight(0, #PB_Window_InnerCoordinate))
    Case #PB_Event_CloseWindow:
      JustExit()
    EndSelect
ForEver
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 26
; FirstLine = 6
; Folding = -
; EnableXP
; DPIAware