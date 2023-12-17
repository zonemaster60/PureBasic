; Remember to enable XP Skin Support!
; Demonstrates how to use ToolBarEx's

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
  #TOOLBAR_0
  #PopupMenu_0
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(12)

; load in some example icons
image(0)\normal = LoadImg("icons\advanced.ico", 32, 32, 0)
image(0)\hot = LoadImg("icons\advanced_h.ico", 32, 32, 0)
image(0)\disabled = LoadImg("icons\advanced_d.ico", 32, 32, 0)

image(1)\normal = LoadImg("icons\back_alt.ico", 32, 32, 0)
image(1)\hot = LoadImg("icons\back_alt_h.ico", 32, 32, 0)
image(1)\disabled = LoadImg("icons\back_alt_d.ico", 32, 32, 0)

image(2)\normal = LoadImg("icons\color.ico", 32, 32, 0)
image(2)\hot = LoadImg("icons\color_h.ico", 32, 32, 0)
image(2)\disabled = LoadImg("icons\color_d.ico", 32, 32, 0)

image(3)\normal = LoadImg("icons\computer on.ico", 32, 32, 0)
image(3)\hot = LoadImg("icons\computer on_h.ico", 32, 32, 0)
image(3)\disabled = LoadImg("icons\computer on_d.ico", 32, 32, 0)

image(4)\normal = LoadImg("icons\copy doc.ico", 32, 32, 0)
image(4)\hot = LoadImg("icons\copy doc_h.ico", 32, 32, 0)
image(4)\disabled = LoadImg("icons\copy doc_d.ico", 32, 32, 0)

image(5)\normal = LoadImg("icons\movies.ico", 32, 32, 0)
image(5)\hot = LoadImg("icons\movies_h.ico", 32, 32, 0)
image(5)\disabled = LoadImg("icons\movies_d.ico", 32, 32, 0)

image(6)\normal = LoadImg("icons\new archive.ico", 32, 32, 0)
image(6)\hot = LoadImg("icons\new archive_h.ico", 32, 32, 0)
image(6)\disabled = LoadImg("icons\new archive_d.ico", 32, 32, 0)

image(7)\normal = LoadImg("icons\new doc.ico", 32, 32, 0)
image(7)\hot = LoadImg("icons\new doc_h.ico", 32, 32, 0)
image(7)\disabled = LoadImg("icons\new doc_d.ico", 32, 32, 0)

image(8)\normal = LoadImg("icons\refresh.ico", 32, 32, 0)
image(8)\hot = LoadImg("icons\refresh_h.ico", 32, 32, 0)
image(8)\disabled = LoadImg("icons\refresh_d.ico", 32, 32, 0)

image(9)\normal = LoadImg("icons\search.ico", 32, 32, 0)
image(9)\hot = LoadImg("icons\search_h.ico", 32, 32, 0)
image(9)\disabled = LoadImg("icons\search_d.ico", 32, 32, 0)

image(10)\normal = LoadImg("icons\stop.ico", 32, 32, 0)
image(10)\hot = LoadImg("icons\stop_h.ico", 32, 32, 0)
image(10)\disabled = LoadImg("icons\stop_d.ico", 32, 32, 0)

image(11)\normal = LoadImg("icons\music 2.ico", 32, 32, 0)
image(11)\hot = LoadImg("icons\music 2_h.ico", 32, 32, 0)
image(11)\disabled = LoadImg("icons\music 2_d.ico", 32, 32, 0)

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of toolbar items
    Case #WM_COMMAND
      
      If Hword(wParam) = 0 ; is an ID
          
        ButtonID = LWord(wParam)
      
        Debug ButtonID ; display selected toolbar item
        
      EndIf
      
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
  
  OpenWindow(#Window_0, 50, 50, 800, 500, "ToolBarExExample 1", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ; create popupmenu
  SetMenuExImageSize(32,32)
  popupmenu = CreatePopupMenuEx(#PopupMenu_0, #UISTYLE_WHIDBEY)
  MenuItemEx(#PopupMenu_0, "Test menu", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
  MenuItemEx(#PopupMenu_0, "Another one!", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
  
  ; create toolbar
  toolbar = CreateToolBarEx(#TOOLBAR_0, WindowID(#Window_0), 32, 32, #TBSTYLE_WRAPABLE)
  
  ToolBarImageButtonEx(0, "Preferences", image(0)\normal, image(0)\hot, 0, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  SelectToolbarExButton(#TOOLBAR_0, 0, 1)
  ToolBarImageButtonEx(2, "\sBack", image(1)\normal, image(1)\hot, 0, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  ToolBarImageButtonEx(3, "\b\c842059c\c10bf50o\c59aa10l\c345512o\caa2066u\c005f00r", image(2)\normal, image(2)\hot, 0, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  ToolBarImageButtonEx(4, "", 0, 0, 0, #BTNS_SEP)
  ToolBarImageButtonEx(5, "Computer", image(3)\normal, image(3)\hot, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(6, "Copy Document", image(4)\normal, image(4)\hot, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(7, "\iMovies", image(5)\normal, image(5)\hot, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(8, "Archive", image(6)\normal, image(6)\hot, 0, #BTNS_AUTOSIZE) 
  ToolBarImageButtonEx(9, "\uNew\u Document", image(7)\normal, image(7)\hot, 0, #BTNS_AUTOSIZE)
  ToolBarDropdownImageButtonEx(10, popupmenu, "Refresh", image(8)\normal, image(8)\hot, 0, #BTNS_AUTOSIZE|#BTNS_WHOLEDROPDOWN)
  ToolBarImageButtonEx(11, "", 0, 0, 0, #BTNS_SEP)
  ToolBarImageButtonEx(12, "Search", image(9)\normal, image(9)\hot, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarImageButtonEx(13, "\bStop", image(10)\normal, image(10)\hot, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(14, "Music", image(11)\normal, image(11)\hot, 0, #BTNS_AUTOSIZE)
  
  DisableToolbarExButton(#TOOLBAR_0, 6, 1)
  DisableToolbarExButton(#TOOLBAR_0, 7, 1)
  
  ; free loaded icons as we don't need them anymore
  For n = 0 To 11
    FreeImg(image(n)\normal)
    FreeImg(image(n)\hot)
    FreeImg(image(n)\disabled)
  Next
  
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
; CursorPosition = 162
; FirstLine = 126
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = ToolbarExample(x64).exe