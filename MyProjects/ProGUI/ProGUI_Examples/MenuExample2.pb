; Remember to enable XP Skin Support!
; Demonstrates multiple menus with different styles in container gadgets on same window

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
  #MENU_2
  #MENU_3
  #MENU_4
  #MENU_5
  #MENU_6
  #MENU_7
  #MENU_8
  #MENU_9
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

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
      
        Debug MenuID ; display selected menu item
        
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
  
  OpenWindow(#Window_0, 50, 50, 800, 500, "MenuExample 2: Multiple menus attached to PureBasic Container Gadgets", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  SetMenuExImageSize(16, 16)
  
  ; sub menu
  CreatePopupMenuEx(#MENU_1, #UISTYLE_WHIDBEY)
  MenuItemEx(0, "Submenu 0", image(6)\normal, image(6)\hot, image(6)\disabled, 0)
  
  CreatePopupMenuEx(#MENU_7, #UISTYLE_BUTTON)
  MenuItemEx(0, "Submenu 1", image(6)\normal, image(6)\hot, image(6)\disabled, 0)
  
  CreatePopupMenuEx(#MENU_8, #UISTYLE_OFFICE2003)
  MenuItemEx(0, "Submenu 2", image(6)\normal, image(6)\hot, image(6)\disabled, 0)
  
  ; main menu
  CreateMenuEx(#MENU_0, WindowID(#Window_0), #UISTYLE_WHIDBEY)
  MenuTitleEx("Title &1")
  MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
  MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
  MenuTitleEx("Title &2")
  MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
  MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
  MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
  MenuTitleEx("Title &3")
  MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
  MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
  SetMenuExImageSize(32, 32)
  MenuTitleEx("&Big Icons")
  MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
  MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
  MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  
  container = ContainerGadget(#PB_Any, 100,200,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_6, GadgetID(container), #UISTYLE_EXPLORER)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  CloseGadgetList()
  
  UseGadgetList(WindowID(#Window_0))
  container = ContainerGadget(#PB_Any, 100,300,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_2, GadgetID(container), #UISTYLE_MOZILLA)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  CloseGadgetList()
  
  UseGadgetList(WindowID(#Window_0))
  container = ContainerGadget(#PB_Any, 200,400,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_3, GadgetID(container), #UISTYLE_BEVELED_A)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  CloseGadgetList()
  
  UseGadgetList(WindowID(#Window_0))
  container = ContainerGadget(#PB_Any, 300,50,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_4, GadgetID(container), #UISTYLE_OFFICE2003)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  CloseGadgetList()
  
  UseGadgetList(WindowID(#Window_0))
  container = ContainerGadget(#PB_Any, 450,200,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_9, GadgetID(container), #UISTYLE_OFFICE2007)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  CloseGadgetList()
  
  UseGadgetList(WindowID(#Window_0))
  container = ContainerGadget(#PB_Any, 200,120,300,50, #PB_Container_Raised)
    SetMenuExImageSize(16, 16)
    CreateMenuEx(#MENU_5, GadgetID(container), #UISTYLE_BUTTON)
    MenuTitleEx("Title &1")
    MenuItemEx(1, "&Item 1$\bCtrl+C", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuItemEx(2, "Item &2", image(0)\normal, image(0)\hot, image(0)\disabled, 0)
    MenuTitleEx("Title &2")
    MenuItemEx(3, "&Item 3", image(1)\normal, image(1)\hot, image(1)\disabled, MenuExID(#MENU_1))
    MenuItemEx(4, "Item &4$\bCtrl+S", image(2)\normal, image(2)\hot, image(2)\disabled, 0)
    MenuItemEx(11, "Item &11 (no icon)", 0, 0, 0, 0)
    MenuBarEx()
    MenuItemEx(5, "&\i\c0000a0&Item 5\n$\bCtrl+B", image(3)\normal, image(3)\hot, image(3)\disabled, 0)
    MenuTitleEx("Title &3")
    MenuItemEx(6, "&Item 6", image(4)\normal, image(4)\hot, image(4)\disabled, 0)
    MenuItemEx(7, "Item &7", image(5)\normal, image(5)\hot, image(5)\disabled, 0)
    SetMenuExImageSize(32, 32)
    MenuTitleEx("&Big Icons")
    MenuItemEx(8, "&Item 8", image(19)\normal, image(19)\hot, image(19)\disabled, 0)
    MenuItemEx(9, "Item &9$\bShift+Del", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
    MenuItemEx(10, "Item &10", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
    
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
; CursorPosition = 284
; FirstLine = 270
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = MenuExample2(x64).exe