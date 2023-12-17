; Remember to enable XP Skin Support!
; Demonstrates how to use rebars

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
  #MENU_0
  #MENU_1
  #REBAR_0
  #PopupMenu_0
  #TOOLBAR_0
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(36)

; load in some example icons
image(0)\normal = LoadImg("icons\cut.ico", 16, 16, 0)
image(0)\hot = LoadImg("icons\cut_h.ico", 16, 16, 0)
image(0)\disabled = LoadImg("icons\cut_d.ico", 16, 16, 0)

image(1)\normal = LoadImg("icons\paste.ico", 16, 16, 0)
image(1)\hot = LoadImg("icons\paste_h.ico", 16, 16, 0)
image(1)\disabled = LoadImg("icons\paste_d.ico", 16, 16, 0)

image(2)\normal = LoadImg("icons\image.ico", 16, 16, 0)
image(2)\hot = LoadImg("icons\image_h.ico", 16, 16, 0)
image(2)\disabled = LoadImg("icons\image_d.ico", 16, 16, 0)

image(3)\normal = LoadImg("icons\multimedia.ico", 16, 16, 0)
image(3)\hot = LoadImg("icons\multimedia_h.ico", 16, 16, 0)
image(3)\disabled = LoadImg("icons\multimedia_d.ico", 16, 16, 0)

image(4)\normal = LoadImg("icons\package.ico", 16, 16, 0)
image(4)\hot = LoadImg("icons\package_h.ico", 16, 16, 0)
image(4)\disabled = LoadImg("icons\package_d.ico", 16, 16, 0)

image(5)\normal = LoadImg("icons\preferences.ico", 16, 16, 0)
image(5)\hot = LoadImg("icons\preferences_h.ico", 16, 16, 0)
image(5)\disabled = LoadImg("icons\preferences_d.ico", 16, 16, 0)

image(6)\normal = LoadImg("icons\jump.ico", 16, 16, 0)
image(6)\hot = LoadImg("icons\jump_h.ico", 16, 16, 0)
image(6)\disabled = LoadImg("icons\jump_d.ico", 16, 16, 0)

image(19)\normal = LoadImg("icons\copy doc.ico", 32, 32, 0)
image(19)\hot = LoadImg("icons\copy doc_h.ico", 32, 32, 0)
image(19)\disabled = LoadImg("icons\copy doc_d.ico", 32, 32, 0)

image(20)\normal = LoadImg("icons\computer on.ico", 32, 32, 0)
image(20)\hot = LoadImg("icons\computer on_h.ico", 32, 32, 0)
image(20)\disabled = LoadImg("icons\computer on_d.ico", 32, 32, 0)

image(21)\normal = LoadImg("icons\search.ico", 32, 32, 0)
image(21)\hot = LoadImg("icons\search_h.ico", 32, 32, 0)
image(21)\disabled = LoadImg("icons\search_d.ico", 32, 32, 0)

image(7)\normal = LoadImg("icons\advanced.ico", 32, 32, 0)
image(7)\hot = LoadImg("icons\advanced_h.ico", 32, 32, 0)
image(7)\disabled = LoadImg("icons\advanced_d.ico", 32, 32, 0)

image(8)\normal = LoadImg("icons\back_alt.ico", 32, 32, 0)
image(8)\hot = LoadImg("icons\back_alt_h.ico", 32, 32, 0)
image(8)\disabled = LoadImg("icons\back_alt_d.ico", 32, 32, 0)

image(9)\normal = LoadImg("icons\color.ico", 32, 32, 0)
image(9)\hot = LoadImg("icons\color_h.ico", 32, 32, 0)
image(9)\disabled = LoadImg("icons\color_d.ico", 32, 32, 0)

image(10)\normal = LoadImg("icons\computer on.ico", 32, 32, 0)
image(10)\hot = LoadImg("icons\computer on_h.ico", 32, 32, 0)
image(10)\disabled = LoadImg("icons\computer on_d.ico", 32, 32, 0)

image(11)\normal = LoadImg("icons\copy doc.ico", 32, 32, 0)
image(11)\hot = LoadImg("icons\copy doc_h.ico", 32, 32, 0)
image(11)\disabled = LoadImg("icons\copy doc_d.ico", 32, 32, 0)

image(12)\normal = LoadImg("icons\movies.ico", 32, 32, 0)
image(12)\hot = LoadImg("icons\movies_h.ico", 32, 32, 0)
image(12)\disabled = LoadImg("icons\movies_d.ico", 32, 32, 0)

image(13)\normal = LoadImg("icons\new archive.ico", 32, 32, 0)
image(13)\hot = LoadImg("icons\new archive_h.ico", 32, 32, 0)
image(13)\disabled = LoadImg("icons\new archive_d.ico", 32, 32, 0)

image(14)\normal = LoadImg("icons\new doc.ico", 32, 32, 0)
image(14)\hot = LoadImg("icons\new doc_h.ico", 32, 32, 0)
image(14)\disabled = LoadImg("icons\new doc_d.ico", 32, 32, 0)

image(15)\normal = LoadImg("icons\refresh.ico", 32, 32, 0)
image(15)\hot = LoadImg("icons\refresh_h.ico", 32, 32, 0)
image(15)\disabled = LoadImg("icons\refresh_d.ico", 32, 32, 0)

image(16)\normal = LoadImg("icons\search.ico", 32, 32, 0)
image(16)\hot = LoadImg("icons\search_h.ico", 32, 32, 0)
image(16)\disabled = LoadImg("icons\search_d.ico", 32, 32, 0)

image(17)\normal = LoadImg("icons\stop.ico", 32, 32, 0)
image(17)\hot = LoadImg("icons\stop_h.ico", 32, 32, 0)
image(17)\disabled = LoadImg("icons\stop_d.ico", 32, 32, 0)

image(18)\normal = LoadImg("icons\music 2.ico", 32, 32, 0)
image(18)\hot = LoadImg("icons\music 2_h.ico", 32, 32, 0)
image(18)\disabled = LoadImg("icons\music 2_d.ico", 32, 32, 0)

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items and toolbar items
    Case #WM_COMMAND
      
      If Hword(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
      
        Debug MenuID ; display selected item ID
        
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
  
  OpenWindow(#Window_0, 50, 50, 800, 500, "RebarExample 2", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ; sub menu
  CreatePopupMenuEx(#MENU_1, #UISTYLE_WHIDBEY)
  MenuItemEx(0, "Submenu Item 0", image(6)\normal, image(6)\hot, image(6)\disabled, 0)
  
  ; main menu
  menu = CreateMenuEx(#MENU_0, WindowID(#Window_0), #UISTYLE_WHIDBEY)
  MenuTitleEx("Example Title &1")
  MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
  MenuItemEx(2, "Item &2 Disabled", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
  DisableMenuItemEx(#MENU_0, 2, 1)
  MenuTitleEx("Example Title &2")
  MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
  MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
  MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
  MenuTitleEx("Example Title &3")
  MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
  MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
  SetMenuExImageSize(32, 32)
  MenuTitleEx("&Big Icons")
  MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
  MenuItemEx(9, "Item &9$\bCtrl+X", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
  MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  
  ; create popupmenu
  SetMenuExImageSize(32,32)
  popupmenu = CreatePopupMenuEx(#PopupMenu_0, #UISTYLE_WHIDBEY)
  MenuItemEx(#PopupMenu_0, "Submenu Item 1", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
  MenuItemEx(#PopupMenu_0, "Submenu Item 2", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  
  ; create toolbar
  toolbar = CreateToolBarEx(#TOOLBAR_0, WindowID(#Window_0), 32, 32, #TBSTYLE_HIDECLIPPEDBUTTONS)
  
  ToolBarImageButtonEx(0, "Preferences", image(7)\normal, image(7)\hot, image(7)\disabled, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  SelectToolbarExButton(#TOOLBAR_0, 0, 1)
  ToolBarImageButtonEx(2, "Back", image(8)\normal, image(8)\hot, image(8)\disabled, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  ToolBarImageButtonEx(3, "Colours", image(9)\normal, image(9)\hot, image(9)\disabled, #BTNS_AUTOSIZE|#BTNS_CHECKGROUP)
  ToolBarImageButtonEx(4, "", 0, 0, 0, #BTNS_SEP)
  ToolBarImageButtonEx(5, "Computer", image(10)\normal, image(10)\hot, image(10)\disabled, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(6, "Copy Document", image(11)\normal, image(11)\hot, image(11)\disabled, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(7, "Movies", image(12)\normal, image(12)\hot, image(12)\disabled, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(8, "Archive", image(13)\normal, image(13)\hot, image(13)\disabled, #BTNS_AUTOSIZE) 
  ToolBarImageButtonEx(9, "New Document", image(14)\normal, image(14)\hot, image(14)\disabled, #BTNS_AUTOSIZE)
  ToolBarDropdownImageButtonEx(10, popupmenu, "Refresh", image(15)\normal, image(15)\hot, image(15)\disabled, #BTNS_AUTOSIZE|#BTNS_WHOLEDROPDOWN)
  ToolBarImageButtonEx(11, "", 0, 0, 0, #BTNS_SEP)
  ToolBarImageButtonEx(12, "Search", image(16)\normal, image(16)\hot, image(16)\disabled, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarImageButtonEx(13, "Stop", image(17)\normal, image(17)\hot, image(17)\disabled, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(14, "Music", image(18)\normal, image(18)\hot, image(18)\disabled, #BTNS_AUTOSIZE)
  
  DisableToolbarExButton(#TOOLBAR_0, 6, 1)
  DisableToolbarExButton(#TOOLBAR_0, 7, 1)

  stringgad = StringGadget(#PB_Any, 0, 0, 0, 0, "String Gadget")
    
  ; create a rebar
  CreateRebar(#REBAR_0, WindowID(#Window_0), 0, #RBS_VARHEIGHT | #RBS_BANDBORDERS, 0)
  
  AddRebarGadget(menu, "", 0, 0, 0, 0, #RBBS_BREAK | #RBBS_NOGRIPPER | #RBBS_CHILDEDGE)
  AddRebarGadget(toolbar, "", 620, 0, 0, 0, #RBBS_BREAK | #RBBS_CHILDEDGE | #RBBS_USECHEVRON)
  AddRebarGadget(GadgetID(stringgad), "", 620, 0, 20, 0, #RBBS_BREAK | #RBBS_CHILDEDGE)
  listview = ListIconGadget(#PB_Any, 0, 0, 0, 200, "List Icon Gadget", 100)
  AddRebarGadget(GadgetID(listview), "", 0, 0, 0, 0, #RBBS_BREAK | #RBBS_CHILDEDGE)
  
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
; CursorPosition = 208
; FirstLine = 205
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = RebarExample2(x64).exe