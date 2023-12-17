; Remember to enable XP Skin Support!
; Demonstrates how to use ExplorerBars

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

;- Gadget Constants
Enumeration
  #ExplorerBar
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(7)

; load in some example icons
image(0)\normal = LoadImg("icons\shell32_1007.ico", 16, 16, 0)
image(1)\normal = LoadImg("icons\shell32_271.ico", 16, 16, 0)
image(2)\normal = LoadImg("icons\shell32_22.ico", 16, 16, 0)
image(3)\normal = LoadImg("icons\shell32_18.ico", 16, 16, 0)
image(4)\normal = LoadImg("icons\shell32_235.ico", 16, 16, 0)
image(5)\normal = LoadImg("icons\shell32_4.ico", 16, 16, 0)
image(6)\normal = LoadImg("icons\shell32_4.ico", 96, 96, 0)

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
      
        Debug MenuID
        
      EndIf
        
    ; resize panelex and textcontrolex when main window resized
    Case #WM_SIZE
      
      MoveWindow_(ExplorerBarID(#ExplorerBar), 5, 5, 210, WindowHeight(#Window_0)-10, #True)
      MoveWindow_(PanelExID(0, -1), 215, 5, WindowWidth(#Window_0)-220, WindowHeight(#Window_0)-10, #True)
      
  EndSelect
  
  ProcedureReturn #PB_ProcessPureBasicEvents
  
EndProcedure

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseWindow(#Window_0)
    End
  EndIf
EndProcedure

; creates a window
Procedure Open_Window_0()
  
  OpenWindow(#Window_0, 50, 50, 700, 500, "ExplorerBar Example", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ; create our ExplorerBar
  CreateExplorerBar(WindowID(#Window_0), #ExplorerBar, 5, 5, 210, 490, 0)
  AddExplorerBarGroup("System Tasks", 0)
    ExplorerBarImageItem(0, "View system information", image(0)\normal, 0, 0, 0)
    ExplorerBarImageItem(1, "Add or remove programs", image(1)\normal, 0, 0, 0)
    ExplorerBarImageItem(2, "Change a setting", image(2)\normal, 0, 0, 0)
  AddExplorerBarGroup("Other Places", 0)
    ExplorerBarImageItem(3, "My Network Places", image(3)\normal, 0, 0, 0)
    ExplorerBarImageItem(4, "My Documents", image(4)\normal, 0, 0, 0)
    ExplorerBarImageItem(5, "Shared Documents", image(5)\normal, 0, 0, 0)
    ExplorerBarImageItem(6, "Control Panel", image(2)\normal, 0, 0, 0)
  AddExplorerBarGroup("Details", 0)
    ExplorerBarItem(7, "Example Item 1")
    ExplorerBarItem(8, "Example Item 2")
  
  ; create PanelEx as main window content
  CreatePanelEx(0, WindowID(#Window_0), 215, 5, 480, 490, 0)
  AddPanelExImagePage(2, image(6)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  
  ; attach our events callback for processing Windows ProGUI messages
  SetWindowCallback(@ProGUI_EventCallback())
  
EndProcedure


Open_Window_0() ; create window
HideWindow(0, 0)  ; show our newly created window

; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  
Until Event = #PB_Event_CloseWindow
JustExit()

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 113
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = ExplorerBarExample(x64).exe