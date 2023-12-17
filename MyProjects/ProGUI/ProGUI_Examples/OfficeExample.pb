; Remember to enable XP Skin Support!
; Demonstrates the new #UISTYLE_OFFICE2007, #UISTYLE_OFFICE2003 User Interface styles

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
  #MENU_10
  #MENU_11
  #MENU_12
  #MENU_13
  #MENU_14
  #MENU_15
  #REBAR_0
  #PopupMenu_0
  #ContextMenu
  #ContextMenu_1
  #ContextMenu_2
  #ContextMenu_3
  #ContextMenu_4
  #TOOLBAR_0
  #TOOLBAR_1
  #ExplorerBar
  #Splitter
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(100)

Global editor

;- Load Icons
image(0)\normal = LoadImg("icons\Office Icons\00139.ico", 16, 16, 0)
image(1)\normal = LoadImg("icons\Office Icons\01032.ico", 16, 16, 0)
image(2)\normal = LoadImg("icons\Office Icons\05965.ico", 16, 16, 0)
image(3)\normal = LoadImg("icons\Office Icons\01589.ico", 16, 16, 0)
image(4)\normal = LoadImg("icons\Office Icons\00178.ico", 16, 16, 0)
image(5)\normal = LoadImg("icons\Office Icons\06547.ico", 16, 16, 0)
image(6)\normal = LoadImg("icons\Office Icons\00762.ico", 16, 16, 0)
image(7)\normal = LoadImg("icons\Office Icons\09051.ico", 16, 16, 0)
image(8)\normal = LoadImg("icons\Office Icons\01714.ico", 16, 16, 0)
image(9)\normal = LoadImg("icons\Office Icons\00737.ico", 16, 16, 0)
image(10)\normal = LoadImg("icons\Office Icons\07226.ico", 16, 16, 0)
image(11)\normal = LoadImg("icons\Office Icons\00287.ico", 16, 16, 0)
image(12)\normal = LoadImg("icons\Office Icons\03621.ico", 16, 16, 0)
image(13)\normal = LoadImg("icons\Office Icons\00224.ico", 16, 16, 0)
image(14)\normal = LoadImg("icons\Office Icons\00285.ico", 16, 16, 0)
image(15)\normal = LoadImg("icons\Office Icons\07392.ico", 16, 16, 0)
image(16)\normal = LoadImg("icons\Office Icons\01707.ico", 16, 16, 0)
image(17)\normal = LoadImg("icons\Office Icons\02039.ico", 16, 16, 0)
image(18)\normal = LoadImg("icons\Office Icons\03739.ico", 16, 16, 0)
image(19)\normal = LoadImg("icons\Office Icons\05958.ico", 16, 16, 0)
image(20)\normal = LoadImg("icons\Office Icons\09276.ico", 16, 16, 0)
image(21)\normal = LoadImg("icons\Office Icons\02358.ico", 16, 16, 0)
image(22)\normal = LoadImg("icons\Office Icons\05905.ico", 16, 16, 0)
image(23)\normal = LoadImg("icons\Office Icons\03823.ico", 16, 16, 0)
image(24)\normal = LoadImg("icons\Office Icons\00018.ico", 16, 16, 0)
image(25)\normal = LoadImg("icons\Office Icons\00023.ico", 16, 16, 0)
image(26)\normal = LoadImg("icons\Office Icons\00003.ico", 16, 16, 0)
image(27)\normal = LoadImg("icons\Office Icons\00004.ico", 16, 16, 0)
image(28)\normal = LoadImg("icons\Office Icons\00109.ico", 16, 16, 0)
image(29)\normal = LoadImg("icons\Office Icons\00002.ico", 16, 16, 0)
image(30)\normal = LoadImg("icons\Office Icons\07387.ico", 16, 16, 0)
image(31)\normal = LoadImg("icons\Office Icons\00021.ico", 16, 16, 0)
image(32)\normal = LoadImg("icons\Office Icons\00019.ico", 16, 16, 0)
image(33)\normal = LoadImg("icons\Office Icons\00022.ico", 16, 16, 0)
image(34)\normal = LoadImg("icons\Office Icons\00108.ico", 16, 16, 0)
image(35)\normal = LoadImg("icons\Office Icons\00128.ico", 16, 16, 0)
image(36)\normal = LoadImg("icons\Office Icons\00129.ico", 16, 16, 0)
image(37)\normal = LoadImg("icons\Office Icons\01576.ico", 16, 16, 0)
image(38)\normal = LoadImg("icons\Office Icons\00916.ico", 16, 16, 0)
image(39)\normal = LoadImg("icons\Office Icons\00008.ico", 16, 16, 0)
image(40)\normal = LoadImg("icons\Office Icons\00142.ico", 16, 16, 0)
image(41)\normal = LoadImg("icons\Office Icons\00009.ico", 16, 16, 0)
image(42)\normal = LoadImg("icons\Office Icons\00016.ico", 16, 16, 0)
image(43)\normal = LoadImg("icons\Office Icons\00682.ico", 16, 16, 0)
image(44)\normal = LoadImg("icons\Office Icons\00931.ico", 16, 16, 0)
image(45)\normal = LoadImg("icons\Office Icons\01764.ico", 16, 16, 0)
image(46)\normal = LoadImg("icons\Office Icons\shapes.ico", 16, 16, 0)
image(47)\normal = LoadImg("icons\Office Icons\01031.ico", 16, 16, 0)
image(48)\normal = LoadImg("icons\Office Icons\04367.ico", 16, 16, 0)
image(49)\normal = LoadImg("icons\Office Icons\06717.ico", 16, 16, 0)
image(50)\normal = LoadImg("icons\Office Icons\00253.ico", 16, 16, 0)
image(51)\normal = LoadImg("icons\Office Icons\00779.ico", 16, 16, 0)
image(52)\normal = LoadImg("icons\Office Icons\00783.ico", 16, 16, 0)
image(53)\normal = LoadImg("icons\Office Icons\00782.ico", 16, 16, 0)
image(54)\normal = LoadImg("icons\Office Icons\03623.ico", 16, 16, 0)
image(55)\normal = LoadImg("icons\Office Icons\00144.ico", 16, 16, 0)
image(56)\normal = LoadImg("icons\Office Icons\05757.ico", 16, 16, 0)
image(57)\normal = LoadImg("icons\Office Icons\06094.ico", 16, 16, 0)
image(58)\normal = LoadImg("icons\Office Icons\00791.ico", 16, 16, 0)
image(59)\normal = LoadImg("icons\Office Icons\03743.ico", 16, 16, 0)
image(60)\normal = LoadImg("icons\Office Icons\01709.ico", 16, 16, 0)
image(61)\normal = LoadImg("icons\Office Icons\02041.ico", 16, 16, 0)
image(62)\normal = LoadImg("icons\Office Icons\00793.ico", 16, 16, 0)
image(63)\normal = LoadImg("icons\Office Icons\00790.ico", 16, 16, 0)
image(64)\normal = LoadImg("icons\Office Icons\06111.ico", 16, 16, 0)
image(65)\normal = LoadImg("icons\Office Icons\03727.ico", 16, 16, 0)
image(66)\normal = LoadImg("icons\Office Icons\04177.ico", 16, 16, 0)
image(67)\normal = LoadImg("icons\Office Icons\00794.ico", 16, 16, 0)
image(68)\normal = LoadImg("icons\Office Icons\00186.ico", 16, 16, 0)
image(69)\normal = LoadImg("icons\Office Icons\00184.ico", 16, 16, 0)
image(70)\normal = LoadImg("icons\Office Icons\01695.ico", 16, 16, 0)
image(71)\normal = LoadImg("icons\Office Icons\03631.ico", 16, 16, 0)
image(72)\normal = LoadImg("icons\Office Icons\02059.ico", 16, 16, 0)
image(73)\normal = LoadImg("icons\Office Icons\00798.ico", 16, 16, 0)
image(74)\normal = LoadImg("icons\Office Icons\00800.ico", 16, 16, 0)
image(75)\normal = LoadImg("icons\Office Icons\00107.ico", 16, 16, 0)
image(76)\normal = LoadImg("icons\Office Icons\00210.ico", 16, 16, 0)
image(77)\normal = LoadImg("icons\Office Icons\02626.ico", 16, 16, 0)
image(78)\normal = LoadImg("icons\Office Icons\03685.ico", 16, 16, 0)
image(79)\normal = LoadImg("icons\Office Icons\03688.ico", 16, 16, 0)
image(80)\normal = LoadImg("icons\Office Icons\03681.ico", 16, 16, 0)
image(81)\normal = LoadImg("icons\Office Icons\03683.ico", 16, 16, 0)
image(82)\normal = LoadImg("icons\Office Icons\00295.ico", 16, 16, 0)
image(83)\normal = LoadImg("icons\Office Icons\02166.ico", 16, 16, 0)
image(84)\normal = LoadImg("icons\Office Icons\02165.ico", 16, 16, 0)
image(85)\normal = LoadImg("icons\Office Icons\02164.ico", 16, 16, 0)
image(86)\normal = LoadImg("icons\Office Icons\03907.ico", 16, 16, 0)
image(87)\normal = LoadImg("icons\Office Icons\03908.ico", 16, 16, 0)
image(88)\normal = LoadImg("icons\Office Icons\03909.ico", 16, 16, 0)
image(89)\normal = LoadImg("icons\Office Icons\02068.ico", 16, 16, 0)
image(90)\normal = LoadImg("icons\Office Icons\02067.ico", 16, 16, 0)
image(91)\normal = LoadImg("icons\Office Icons\00984.ico", 16, 16, 0)
Global crossImage = LoadImg("icons\Office Icons\cross.png", 0, 0, 0)

; simple example of how custom UI colours can be used
Procedure mixCustomColours(colour)
  
  alpha = 50
  
  For component = 0 To #MaxUIComponents-1
    
    ; if not menu background, menu dropshadow, item text, menu title text and disabled colour components
    If component <> #background And component <> #menuDropShadow And component <> #menuTextColor And component <> #menuTitleTextColor And component <> #disabledColor
      c = GetUIColour(#UISTYLE_WHIDBEY, component, 0)
      c = AlphaBlendColour(c, colour, alpha)
      SetUIColour(#UISTYLE_WHIDBEY, component, c, GetCurrentColourScheme()+#UICOLOURMODE_CUSTOM, #True) ; don't update
      
      c = GetUIColour(#UISTYLE_OFFICE2003, component, 0)
      c = AlphaBlendColour(c, colour, alpha)
      SetUIColour(#UISTYLE_OFFICE2003, component, c, GetCurrentColourScheme()+#UICOLOURMODE_CUSTOM, #True) ; don't update
      
      c = GetUIColour(#UISTYLE_OFFICE2007, component, 0)
      c = AlphaBlendColour(c, colour, alpha)
      If component = #MaxUIComponents-1
        SetUIColour(#UISTYLE_OFFICE2007, component, c, GetCurrentColourScheme()+#UICOLOURMODE_CUSTOM, 0) ; update on last colour set
      Else
        SetUIColour(#UISTYLE_OFFICE2007, component, c, GetCurrentColourScheme()+#UICOLOURMODE_CUSTOM, #True) ; don't update
      EndIf      
    EndIf
    
  Next
  
EndProcedure

;- Process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items and toolbar items
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        ID = LWord(wParam)
      
        ; handle checkboxes and radiochecks
        If ID >= 40 And ID <= 44
          SetMenuExItemState(#MENU_0, ID, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
        EndIf
        If ID = 45 Or ID = 47
          If GetMenuExItemState(#MENU_0, ID) = #True
            SetMenuExItemState(#MENU_0, ID, #False)
          Else
            SetMenuExItemState(#MENU_0, ID, #ItemEx_ShowCheckbox)
          EndIf
        EndIf
        If ID = 52 Or ID = 50
          If GetMenuExItemState(#MENU_0, ID) = #True
            SetMenuExItemState(#MENU_0, ID, #False)
          Else
            SetMenuExItemState(#MENU_0, ID, #ItemEx_ShowCheckbox|#ItemEx_UseIcon)
          EndIf
        EndIf
        If ID = 48 Or ID = 49
          If GetMenuExItemState(#MENU_0, ID) = #True
            SetMenuExItemState(#MENU_0, ID, #False)
          Else
            SetMenuExItemState(#MENU_0, ID, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
          EndIf
        EndIf
        If ID >= 55 And ID <= 74
          If GetMenuExItemState(#MENU_3, ID) = #True
            SetMenuExItemState(#MENU_3, ID, #False)
          Else
            SetMenuExItemState(#MENU_3, ID, #ItemEx_ShowCheckbox)
          EndIf
        EndIf
        If ID = 168
          If GetMenuExItemState(#MENU_0, ID) = #True
            SetMenuExItemState(#MENU_0, ID, #False)
            SetMenuItemEx(#MENU_0, ID, "Show &Gridlines", 0, 0, 0, 0)
          Else
            SetMenuExItemState(#MENU_0, ID, #ItemEx_ShowCheckbox|#ItemEx_UseIcon)
            SetMenuItemEx(#MENU_0, ID, "Hide &Gridlines", 0, 0, 0, 0)
          EndIf
        EndIf
        
        ; context menu
        If ID = 210
          result = FontRequester(GetFontName(GetMenuExFont()), GetFontSize(GetMenuExFont()), #PB_FontRequester_Effects)
          If result <> 0
            Font = LoadFontEx(SelectedFontName(), SelectedFontSize(), SelectedFontStyle())
            SetMenuExFont(Font)
          EndIf
        ElseIf ID = 228
          SetMenuExItemState(#ContextMenu_3, ID, #ItemEx_ShowRadiocheck)
          SetToolBarExStyle(#TOOLBAR_0, 0)
          SetRebarStyle(#REBAR_0, 0)
        ElseIf ID = 229
          SetMenuExItemState(#ContextMenu_3, ID, #ItemEx_ShowRadiocheck)
          SetToolBarExStyle(#TOOLBAR_0, #UISTYLE_OFFICE2003)
          SetRebarStyle(#REBAR_0, #UISTYLE_OFFICE2003)
          SetMenuItemEx(#ContextMenu, 208, "&Colour Theme", 0, 0, 0, #ContextMenu_1)
        ElseIf ID = 230
          SetMenuExItemState(#ContextMenu_3, ID, #ItemEx_ShowRadiocheck)
          SetToolBarExStyle(#TOOLBAR_0, #UISTYLE_OFFICE2007)
          SetRebarStyle(#REBAR_0, #UISTYLE_OFFICE2007)
          SetMenuItemEx(#ContextMenu, 208, "&Colour Theme", 0, 0, 0, #ContextMenu_4)
        ElseIf ID = 226
          If GetMenuExItemState(#ContextMenu, ID) = #False
            txt.s = "Small example of custom user interface colours, choose a colour to mix the current theme with!"
            AddGadgetItem(editor, -1, txt)
      
            colour = ColorRequester()
            If colour <> -1
              SetMenuExItemState(#ContextMenu, ID, #True)
              mixCustomColours(colour)
            EndIf
            
            ; set User Interface colour mode to auto custom
            SetUIColourMode(GetCurrentColourScheme()+#UICOLOURMODE_CUSTOM)
          Else
            SetUIColourMode(GetCurrentColourScheme())
            SetMenuExItemState(#ContextMenu, ID, #False)
          EndIf
        ElseIf ID = 225
          RunProgram("http://www.progui.co.uk/register.html")
        EndIf
        Select ID
          ; theme colour radiocheck group
          Case 213
            SetMenuExItemState(#ContextMenu_1, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu_4, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu, 226, #False)
            SetUIColourMode(#UICOLOURMODE_DEFAULT)
          Case 214
            SetMenuExItemState(#ContextMenu_1, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu_4, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu, 226, #False)
            SetUIColourMode(#UICOLOURMODE_DEFAULT_BLUE)
          Case 215
            SetMenuExItemState(#ContextMenu_1, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu_4, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu, 226, #False)
            SetUIColourMode(#UICOLOURMODE_DEFAULT_SILVER)
          Case 216
            SetMenuExItemState(#ContextMenu_1, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu_4, 214, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu, 226, #False)
            SetUIColourMode(#UICOLOURMODE_DEFAULT_OLIVE)
          Case 217
            SetMenuExItemState(#ContextMenu_1, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu_4, ID, #ItemEx_ShowRadiocheck)
            SetMenuExItemState(#ContextMenu, 226, #False)
            SetUIColourMode(#UICOLOURMODE_DEFAULT_GREY)
          ; menu style radiocheck group
          Case 218
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_BUTTON)
          Case 219
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_EXPLORER)
          Case 220
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_MOZILLA)
          Case 221
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_BEVELED_A)
          Case 222
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_BEVELED_B)
          Case 223
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_WHIDBEY)
          Case 224
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_OFFICE2003)
          Case 227
            SetMenuExItemState(#ContextMenu_2, ID, #ItemEx_ShowRadiocheck)
            SetMenuExStyle(#MENU_0, #UISTYLE_OFFICE2007)
        EndSelect
        
        ; display selected menu item in richedit control (with the exception of context menu)
        If ID < 210 Or ID > 226
          txt.s = "Menu item "+Str(ID)+" selected."
          AddGadgetItem(editor, -1, txt)
        EndIf
        
      EndIf
      
    ; resize richedit when rebar updated msg received
    Case #REBAR_UPDATED
  
      MoveWindow_(SplitterExID(#Splitter),  0, RebarHeight(#REBAR_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#REBAR_0), #True)
      
    ; resize richedit when window resizing
    Case #WM_SIZE
  
      MoveWindow_(SplitterExID(#Splitter), 0, RebarHeight(#REBAR_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#REBAR_0), #True)
          
    ; display right click context menu
    Case #WM_RBUTTONDOWN
      
      DisplayPopupMenuEx(#ContextMenu, hwnd, DesktopMouseX(), DesktopMouseY())
   
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
  
  SetGlobalSkinColourTheme(GetDefaultGlobalSkinColourTheme())
  
  OpenWindow(#Window_0, 50, 50, 800, 500, "Office Example", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  LimitWindowSize(WindowID(#Window_0), 350, 200, 0, 0)
  
  ;- *** Sub Menus ***
  ;- "Send To" Sub Menu
  CreatePopupMenuEx(#MENU_1, #UISTYLE_OFFICE2007)
  MenuItemEx(31, "Mail Re&cipient (for Review)...", image(19)\normal, 0, 0, 0)
  MenuItemEx(32, "M&ail Recipient (as Attachment)...", image(18)\normal, 0, 0, 0)
  MenuItemEx(33, "&Routing Recipient...", image(17)\normal, 0, 0, 0)
  MenuItemEx(34, "&Online Meeting Participant", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_1, 34, #True)
  MenuItemEx(35, "Recipient using a &Fax Modem...", image(16)\normal, 0, 0, 0)
  MenuItemEx(36, "Recipient using Internet Fa&x Service...", image(15)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(37, "Microsoft Office &PowerPoint", image(14)\normal, 0, 0, 0)
  
  ;- "Clear" Sub Menu
  CreatePopupMenuEx(#MENU_2, #UISTYLE_OFFICE2007)
  MenuItemEx(38, "&Formats", 0, 0, 0, 0)
  MenuItemEx(39, "&Contents     Del", 0, 0, 0, 0)
  
  ;- "Toolbars" Sub Menu
  CreatePopupMenuEx(#MENU_3, #UISTYLE_OFFICE2007)
  MenuItemEx(55, "Standard", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_3, 55, #ItemEx_ShowCheckbox)
  MenuItemEx(56, "Formatting", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_3, 56, #ItemEx_ShowCheckbox)
  MenuItemEx(57, "AutoText", 0, 0, 0, 0)
  MenuItemEx(58, "Control Toolbox", 0, 0, 0, 0)
  MenuItemEx(59, "Database", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_3, 59, #ItemEx_ShowCheckbox)
  MenuItemEx(60, "Drawing", 0, 0, 0, 0)
  MenuItemEx(61, "E-mail", 0, 0, 0, 0)
  MenuItemEx(62, "Forms", 0, 0, 0, 0)
  MenuItemEx(63, "Frames", 0, 0, 0, 0)
  MenuItemEx(64, "Mail Merge", 0, 0, 0, 0)
  MenuItemEx(65, "Outlining", 0, 0, 0, 0)
  MenuItemEx(66, "Picture", 0, 0, 0, 0)
  MenuItemEx(67, "Reviewing", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_3, 67, #ItemEx_ShowCheckbox)
  MenuItemEx(68, "Tables and Borders", 0, 0, 0, 0)
  MenuItemEx(69, "Task Pane", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_3, 69, #ItemEx_ShowCheckbox)
  MenuItemEx(70, "Visual Basic", 0, 0, 0, 0)
  MenuItemEx(71, "Web", 0, 0, 0, 0)
  MenuItemEx(72, "Web Tools", 0, 0, 0, 0)
  MenuItemEx(73, "Word Count", 0, 0, 0, 0)
  MenuItemEx(74, "Word Art", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(75, "&Customize", 0, 0, 0, 0)
  
  ;- "Reference" Sub Menu
  CreatePopupMenuEx(#MENU_4, #UISTYLE_OFFICE2007)
  MenuItemEx(92, "Foot&note...", 0, 0, 0, 0)
  MenuItemEx(93, "&Caption...", 0, 0, 0, 0)
  MenuItemEx(94, "Cross-&reference...", 0, 0, 0, 0)
  MenuItemEx(95, "In&dex and Tables...", 0, 0, 0, 0)
  
  ;- "Picture" Sub Menu
  CreatePopupMenuEx(#MENU_5, #UISTYLE_OFFICE2007)
  MenuItemEx(96, "&Clip Art...", image(43)\normal, 0, 0, 0)
  MenuItemEx(97, "&From File...", image(44)\normal, 0, 0, 0)
  MenuItemEx(98, "From &Scanner or Camera...", image(45)\normal, 0, 0, 0)
  MenuItemEx(99, "&New Drawing", image(42)\normal, 0, 0, 0)
  MenuItemEx(100, "&AutoShapes", image(46)\normal, 0, 0, 0)
  MenuItemEx(101, "&WordArt...", image(47)\normal, 0, 0, 0)
  MenuItemEx(102, "&Organization Chart", image(48)\normal, 0, 0, 0)
  MenuItemEx(103, "C&hart", image(49)\normal, 0, 0, 0)
  
  ;- "Frames" Sub Menu
  CreatePopupMenuEx(#MENU_6, #UISTYLE_OFFICE2007)
  MenuItemEx(120, "&Table of Contents in Frame", image(59)\normal, 0, 0, 0)
  MenuItemEx(121, "&New Frames Page", 0, 0, 0, 0)
  
  ;- "Language" Sub Menu
  CreatePopupMenuEx(#MENU_7, #UISTYLE_OFFICE2007)
  MenuItemEx(139, "Set &Language...", image(63)\normal, 0, 0, 0)
  MenuItemEx(140, "Tr&anslate...", image(64)\normal, 0, 0, 0)
  MenuItemEx(141, "&Thesaurus...$Shift+F7", 0, 0, 0, 0)
  MenuItemEx(142, "&Hyphenation...", 0, 0, 0, 0)
  
  ;- "Online Collaboration" Sub Menu
  CreatePopupMenuEx(#MENU_8, #UISTYLE_OFFICE2007)
  MenuItemEx(143, "&Meet Now", image(65)\normal, 0, 0, 0)
  MenuItemEx(144, "&Schedule Meeting...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_8, 144, #True)
  MenuItemEx(145, "&Web Discussions", image(66)\normal, 0, 0, 0)
  
  ;- "Letters and Mailings" Sub Menu
  CreatePopupMenuEx(#MENU_9, #UISTYLE_OFFICE2007)
  MenuItemEx(146, "&Mail Merge...", 0, 0, 0, 0)
  MenuItemEx(147, "Show Mail Merge &Toolbar", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(148, "&Envelopes and Labels...", image(67)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(149, "Letter Wi&zard...", 0, 0, 0, 0)
  
  ;- "Macro" Sub Menu
  CreatePopupMenuEx(#MENU_10, #UISTYLE_OFFICE2007)
  MenuItemEx(150, "&Macros...$Alt+F8", image(68)\normal, 0, 0, 0)
  MenuItemEx(151, "&Record New Macro...", image(69)\normal, 0, 0, 0)
  MenuItemEx(152, "&Security...", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(153, "&Visual Basic Editor$Alt+F11", image(70)\normal, 0, 0, 0)
  MenuItemEx(154, "Microsoft Script &Editor$Alt+Shift+F11", image(71)\normal, 0, 0, 0)
  
  ;- "Insert" Sub Menu
  CreatePopupMenuEx(#MENU_11, #UISTYLE_OFFICE2007)
  MenuItemEx(170, "&Table...", image(39)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(171, "Columns to the &Left", image(78)\normal, 0, 0, 0)
  MenuItemEx(172, "Columns to the &Right", image(79)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(173, "Rows &Above", image(80)\normal, 0, 0, 0)
  MenuItemEx(174, "Rows &Below", image(81)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(175, "C&ells...", image(82)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_11, 171, #True)
  DisableMenuItemEx(#MENU_11, 172, #True)
  DisableMenuItemEx(#MENU_11, 173, #True)
  DisableMenuItemEx(#MENU_11, 174, #True)
  DisableMenuItemEx(#MENU_11, 175, #True)
  
  ;- "Delete" Sub Menu
  CreatePopupMenuEx(#MENU_12, #UISTYLE_OFFICE2007)
  MenuItemEx(176, "&Table", 0, 0, 0, 0)
  MenuItemEx(177, "&Columns", image(83)\normal, 0, 0, 0)
  MenuItemEx(178, "&Rows", image(84)\normal, 0, 0, 0)
  MenuItemEx(179, "C&ells...", image(85)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_12, 176, #True)
  DisableMenuItemEx(#MENU_12, 177, #True)
  DisableMenuItemEx(#MENU_12, 178, #True)
  DisableMenuItemEx(#MENU_12, 179, #True)
  
  ;- "Select" Sub Menu
  CreatePopupMenuEx(#MENU_13, #UISTYLE_OFFICE2007)
  MenuItemEx(180, "&Table", 0, 0, 0, 0)
  MenuItemEx(181, "&Column", 0, 0, 0, 0)
  MenuItemEx(182, "&Row", 0, 0, 0, 0)
  MenuItemEx(183, "C&ell", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_13, 180, #True)
  DisableMenuItemEx(#MENU_13, 181, #True)
  DisableMenuItemEx(#MENU_13, 182, #True)
  DisableMenuItemEx(#MENU_13, 183, #True)
  
  ;- "AutoFit" Sub Menu
  CreatePopupMenuEx(#MENU_14, #UISTYLE_OFFICE2007)
  MenuItemEx(184, "Auto&Fit to Contents", image(86)\normal, 0, 0, 0)
  MenuItemEx(185, "AutoFit to &Window", image(87)\normal, 0, 0, 0)
  MenuItemEx(186, "Fi&xed Column Width", image(88)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(187, "Distribute Rows Eve&nly", image(89)\normal, 0, 0, 0)
  MenuItemEx(188, "Distribute Columns Evenl&y", image(90)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_14, 184, #True)
  DisableMenuItemEx(#MENU_14, 185, #True)
  DisableMenuItemEx(#MENU_14, 186, #True)
  DisableMenuItemEx(#MENU_14, 187, #True)
  DisableMenuItemEx(#MENU_14, 188, #True)
  
  ;- "Convert" Sub Menu
  CreatePopupMenuEx(#MENU_15, #UISTYLE_OFFICE2007)
  MenuItemEx(189, "Te&xt to Table...", 0, 0, 0, 0)
  MenuItemEx(190, "Ta&ble to Text...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_15, 189, #True)
  DisableMenuItemEx(#MENU_15, 190, #True)
  
  ;- *** Main Menu ***
  menu = CreateMenuEx(#MENU_0, WindowID(#Window_0), #UISTYLE_OFFICE2007)
  ;- "File" Menu Title
  MenuTitleEx("&File")
  MenuItemEx(1, "&New...", image(24)\normal, 0, 0, 0)
  MenuItemEx(2, "&Open...$Ctrl+O", image(25)\normal, 0, 0, 0)
  MenuItemEx(3, "&Close", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(4, "&Save$Ctrl+S", image(26)\normal, 0, 0, 0)
  MenuItemEx(5, "Save &As...", 0, 0, 0, 0)
  MenuItemEx(6, "Save as Web Pa&ge...", image(23)\normal, 0, 0, 0)
  MenuItemEx(7, "File Searc&h...", image(22)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(8, "Ve&rsions...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 8, 1)
  MenuBarEx()
  MenuItemEx(9, "We&b Page Preview", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 9, 1)
  MenuBarEx()
  MenuItemEx(10, "Page Set&up...", 0, 0, 0, 0)
  MenuItemEx(11, "Print Pre&view", image(28)\normal, 0, 0, 0)
  MenuItemEx(12, "&Print...$Ctrl+P", image(27)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 12, 1)
  MenuBarEx()
  MenuItemEx(13, "Sen&d To", 0, 0, 0, MenuExID(#MENU_1))
  MenuItemEx(14, "Propert&ies", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(15, "&1 Z:\\...\\My Documents\\test.doc",0,0,0,0)
  MenuItemEx(15, "&2 Z:\\...\\My Documents\\DCC Manager.doc",0,0,0,0)
  MenuItemEx(15, "&3 Z:\\...\\My Documents\\CV.doc",0,0,0,0)
  MenuItemEx(15, "&4 Z:\\...\\My Documents\\OperatingSystems.doc",0,0,0,0)
  MenuBarEx()
  MenuItemEx(15, "E&xit", 0, 0, 0, 0)
  
  ;- "Edit" Menu Title
  MenuTitleEx("&Edit")
  MenuItemEx(16, "Can't &Undo$Ctrl+Z", image(35)\normal, 0, 0, 0)
  MenuItemEx(17, "Can't &Repeat$Ctrl+Y", image(36)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(18, "Cu&t$Ctrl+X", image(31)\normal, 0, 0, 0)
  MenuItemEx(19, "&Copy$Ctrl+C", image(32)\normal, 0, 0, 0)
  MenuItemEx(20, "Office Clip&board...", image(21)\normal, 0, 0, 0)
  MenuItemEx(21, "&Paste$Ctrl+V", image(33)\normal, 0, 0, 0)
  MenuItemEx(22, "Paste &Special...", 0, 0, 0, 0)
  MenuItemEx(23, "Paste as &Hyperlink", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 23, #True)
  MenuBarEx()
  MenuItemEx(24, "Cle&ar", 0, 0, 0, MenuExID(#MENU_2))
  MenuItemEx(25, "Select A&ll", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(26, "&Find...$Ctrl+F", image(20)\normal, 0, 0, 0)
  MenuItemEx(27, "R&eplace...", 0, 0, 0, 0)
  MenuItemEx(28, "&Go To...$Ctrl+G", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(29, "Lin&ks...", 0, 0, 0, 0)
  MenuItemEx(30, "&Object", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 29, #True)
  DisableMenuItemEx(#MENU_0, 30, #True)
  
  ;- "View" Menu Title
  MenuTitleEx("&View")
  MenuItemEx(40, "&Normal", image(13)\normal, 0, 0, 0)
  MenuItemEx(41, "&Web Layout", image(12)\normal, 0, 0, 0)
  MenuItemEx(42, "&Print Layout", image(11)\normal, 0, 0, 0)
  MenuItemEx(43, "&Reading Layout", image(10)\normal, 0, 0, 0)
  MenuItemEx(44, "&Outline", image(9)\normal, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 40, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
  SetMenuExItemState(#MENU_0, 41, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
  SetMenuExItemState(#MENU_0, 43, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
  SetMenuExItemState(#MENU_0, 44, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon)
  SetMenuExItemState(#MENU_0, 42, #ItemEx_ShowRadiocheck|#ItemEx_UseIcon|#ItemEx_EndRadiocheckGroup)
  MenuBarEx()
  MenuItemEx(45, "Tas&k Pane$Ctrl+F1", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 45, #ItemEx_ShowCheckbox)
  MenuItemEx(46, "&Toolbars", 0, 0, 0, MenuExID(#MENU_3))
  MenuItemEx(47, "Ru&ler", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 47, #ItemEx_ShowCheckbox)
  MenuBarEx()
  MenuItemEx(48, "&Document Map", image(8)\normal, 0, 0, 0)
  MenuItemEx(49, "Thum&bnails", image(7)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(50, "&Header and Footer", image(6)\normal, 0, 0, 0)
  MenuItemEx(51, "&Footnotes", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 51, #True)
  MenuItemEx(52, "M&arkup", image(5)\normal, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 52, #ItemEx_ShowCheckbox|#ItemEx_UseIcon)
  MenuBarEx()
  MenuItemEx(53, "F&ull Screen", image(4)\normal, 0, 0, 0)
  MenuItemEx(54, "&Zoom...", 0, 0, 0, 0)
  
  ;- "Insert" Menu Title
  MenuTitleEx("&Insert")
  MenuItemEx(76, "&Break...", 0, 0, 0, 0)
  MenuItemEx(77, "Page N&umbers...", 0, 0, 0, 0)
  MenuItemEx(78, "Date and &Time...", 0, 0, 0, 0)
  MenuItemEx(79, "&AutoText", 0, 0, 0, 0)
  MenuItemEx(80, "&Field...", 0, 0, 0, 0)
  MenuItemEx(81, "&Symbol...", 0, 0, 0, 0)
  MenuItemEx(82, "Co&mment", image(3)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(83, "Refere&nce", 0, 0, 0, MenuExID(#MENU_4))
  MenuItemEx(84, "&Web Component...", image(2)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 84, #True)
  MenuBarEx()
  MenuItemEx(85, "&Picture", 0, 0, 0, MenuExID(#MENU_5))
  MenuItemEx(86, "Dia&gram...", image(1)\normal, 0, 0, 0)
  MenuItemEx(87, "Te&xt Box", image(0)\normal, 0, 0, 0)
  MenuItemEx(88, "Fi&le...", 0, 0, 0, 0)
  MenuItemEx(89, "&Object...", 0, 0, 0, 0)
  MenuItemEx(90, "Boo&kmark...", 0, 0, 0, 0)
  MenuItemEx(91, "Hyperl&ink...$Ctrl+K", image(37)\normal, 0, 0, 0)
  
  ;- "Format" Menu Title
  MenuTitleEx("F&ormat")
  MenuItemEx(104, "&Font...", image(50)\normal, 0, 0, 0)
  MenuItemEx(105, "&Paragraph...", image(51)\normal, 0, 0, 0)
  MenuItemEx(106, "Bullets and &Numbering...", image(52)\normal, 0, 0, 0)
  MenuItemEx(107, "&Borders and Shading...", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(108, "&Columns...", image(41)\normal, 0, 0, 0)
  MenuItemEx(109, "&Tabs...", 0, 0, 0, 0)
  MenuItemEx(110, "&Drop Cap...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 110, #True)
  MenuItemEx(111, "Te&xt Direction...", image(53)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 111, #True)
  MenuItemEx(112, "Change Cas&e...", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(113, "Bac&kground", 0, 0, 0, 0)
  MenuItemEx(114, "T&heme...", image(54)\normal, 0, 0, 0)
  MenuItemEx(115, "F&rames", 0, 0, 0, MenuExID(#MENU_6))
  MenuItemEx(116, "&AutoFormat...", image(55)\normal, 0, 0, 0)
  MenuItemEx(117, "&Styles and Formatting...", image(56)\normal, 0, 0, 0)
  MenuItemEx(118, "Re&veal Formatting...$Shift+F1", image(57)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(119, "&Object...", image(58)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 119, #True)
  
  ;- "Tools" Menu Title
  MenuTitleEx("&Tools")
  MenuItemEx(122, "&Spelling and Grammar...$F7", image(29)\normal, 0, 0, 0)
  MenuItemEx(123, "&Research...$Alt+R", image(30)\normal, 0, 0, 0)
  MenuItemEx(124, "&Language", 0, 0, 0, MenuExID(#MENU_7))
  MenuItemEx(125, "&Word Count...", 0, 0, 0, 0)
  MenuItemEx(126, "A&utoSummarize...", image(60)\normal, 0, 0, 0)
  MenuItemEx(127, "Speec&h", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(128, "Shared Wor&kspace...", 0, 0, 0, 0)
  MenuItemEx(129, "&Track Changes$Ctrl+Shift+E", image(61)\normal, 0, 0, 0)
  MenuItemEx(130, "Compare and Merge &Documents...", 0, 0, 0, 0)
  MenuItemEx(131, "&Protect Document...", 0, 0, 0, 0)
  MenuItemEx(132, "O&nline Collaboration", 0, 0, 0, MenuExID(#MENU_8))
  MenuBarEx()
  MenuItemEx(133, "L&etters and Mailings", 0, 0, 0, MenuExID(#MENU_9))
  MenuBarEx()
  MenuItemEx(134, "&Macro", 0, 0, 0, MenuExID(#MENU_10))
  MenuItemEx(135, "Templates and Add-&Ins...", 0, 0, 0, 0)
  MenuItemEx(136, "&AutoCorrect Options...", image(62)\normal, 0, 0, 0)
  MenuItemEx(137, "&Customize...", 0, 0, 0, 0)
  MenuItemEx(138, "&Options...", 0, 0, 0, 0)
  
  ;- "Table" Menu Title
  MenuTitleEx("T&able")
  MenuItemEx(155, "Dra&w Table", image(72)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(156, "&Insert", 0, 0, 0, MenuExID(#MENU_11))
  MenuItemEx(157, "&Delete", 0, 0, 0, MenuExID(#MENU_12))
  MenuItemEx(158, "Sele&ct", 0, 0, 0, MenuExID(#MENU_13))
  MenuItemEx(159, "&Merge Cells", image(73)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 159, #True)
  MenuItemEx(160, "S&plit Cells...", image(74)\normal, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 160, #True)
  MenuItemEx(161, "Split &Table", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 161, #True)
  MenuBarEx()
  MenuItemEx(162, "Table Auto&Format...", image(75)\normal, 0, 0, 0)
  MenuItemEx(163, "&AutoFit", 0, 0, 0, MenuExID(#MENU_14))
  MenuItemEx(164, "&Heading Rows Repeat", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 164, #True)
  MenuBarEx()
  MenuItemEx(165, "Con&vert", 0, 0, 0, MenuExID(#MENU_15))
  MenuItemEx(166, "&Sort...", image(76)\normal, 0, 0, 0)
  MenuItemEx(167, "F&ormula...", 0, 0, 0, 0)
  MenuItemEx(168, "Hide &Gridlines", image(77)\normal, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 168, #ItemEx_ShowCheckbox|#ItemEx_UseIcon)
  MenuBarEx()
  MenuItemEx(169, "Table P&roperties...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 169, #True)
  
  ;- "Window" Menu Title
  MenuTitleEx("&Window")
  MenuItemEx(191, "&New Window", 0, 0, 0, 0)
  MenuItemEx(192, "&Arrange All", 0, 0, 0, 0)
  MenuItemEx(193, "Compare Side &by Side with...", 0, 0, 0, 0)
  DisableMenuItemEx(#MENU_0, 193, #True)
  MenuItemEx(194, "&Split", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(195, "&1 Document1", 0, 0, 0, 0)
  SetMenuExItemState(#MENU_0, 195, #ItemEx_ShowCheckbox)
  
  ;- "Help" Menu Title
  MenuTitleEx("&Help")
  MenuItemEx(196, "Microsoft Office Word &Help$F1", image(91)\normal, 0, 0, 0)
  MenuItemEx(197, "Show the &Office Assistant", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(198, "&Microsoft Office Online", 0, 0, 0, 0)
  MenuItemEx(199, "&Contact Us", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(200, "Word&Perfect Help...", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(201, "Chec&k for Updates", 0, 0, 0, 0)
  MenuItemEx(202, "Detect and &Repair...", 0, 0, 0, 0)
  MenuItemEx(203, "Acti&vate Product...", 0, 0, 0, 0)
  MenuItemEx(204, "Customer &Feedback Options...", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(205, "&About Microsoft Office Word", 0, 0, 0, 0)
  
  ;- *** right click context menu ***
  ; 2003 colour themes
  CreatePopupMenuEx(#ContextMenu_1, #UISTYLE_OFFICE2007)
  MenuItemEx(213, "&Automatic", 0, 0, 0, 0)
  MenuItemEx(214, "\c382d96\b&Blue", 0, 0, 0, 0)
  MenuItemEx(215, "\c7c7c94\b&Silver", 0, 0, 0, 0)
  MenuItemEx(216, "\c758d5e\b&Olive", 0, 0, 0, 0)
  MenuItemEx(217, "\c666666\bClassic &Grey", 0, 0, 0, 0)
  SetMenuExItemState(#ContextMenu_1, 214, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_1, 215, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_1, 216, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_1, 217, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_1, 213, #ItemEx_ShowRadiocheck)
  ; 2007 colour themes
  CreatePopupMenuEx(#ContextMenu_4, #UISTYLE_OFFICE2007)
  MenuItemEx(213, "&Automatic", 0, 0, 0, 0)
  MenuItemEx(214, "\c90b9ee\b&Blue", 0, 0, 0, 0)
  MenuItemEx(217, "\c67707c\bBl&ack", 0, 0, 0, 0)
  MenuItemEx(215, "\cb4b3c8\b&Silver", 0, 0, 0, 0)
  SetMenuExItemState(#ContextMenu_4, 214, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_4, 215, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_4, 217, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_4, 213, #ItemEx_ShowRadiocheck)
  
  CreatePopupMenuEx(#ContextMenu_3, #UISTYLE_OFFICE2007)
  MenuItemEx(228, "&Standard", 0, 0, 0, 0)
  MenuItemEx(229, "Office 200&3", 0, 0, 0, 0)
  MenuItemEx(230, "Office 200&7", 0, 0, 0, 0)
  SetMenuExItemState(#ContextMenu_3, 228, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_3, 229, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_3, 230, #ItemEx_ShowRadiocheck)
  
  CreatePopupMenuEx(#ContextMenu_2, #UISTYLE_OFFICE2007)
  MenuItemEx(218, "&Button", 0, 0, 0, 0)
  MenuItemEx(219, "&Explorer", 0, 0, 0, 0)
  MenuItemEx(220, "&Mozilla Firefox", 0, 0, 0, 0)
  MenuItemEx(221, "Beveled &1", 0, 0, 0, 0)
  MenuItemEx(222, "Beveled &2", 0, 0, 0, 0)
  MenuItemEx(223, "Office &XP/Whidbey", 0, 0, 0, 0)
  MenuItemEx(224, "Office 200&3", 0, 0, 0, 0)
  MenuItemEx(227, "Office 200&7", 0, 0, 0, 0)
  SetMenuExItemState(#ContextMenu_2, 218, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 219, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 220, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 221, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 222, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 223, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 224, #ItemEx_ShowRadiocheck)
  SetMenuExItemState(#ContextMenu_2, 227, #ItemEx_ShowRadiocheck)
  
  CreatePopupMenuEx(#ContextMenu, #UISTYLE_OFFICE2007)
  MenuItemEx(208, "&Colour Theme", image(54)\normal, 0, 0, #ContextMenu_4)
  MenuBarEx()
  MenuItemEx(209, "&Menu Style", 0, 0, 0, #ContextMenu_2)
  MenuItemEx(210, "&Font and Size...", image(50)\normal, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(212, "&Rebar and Toolbar Style", 0, 0, 0, #ContextMenu_3)
  MenuItemEx(226, "Custom Colours E&xample... (Choose a \b\c842059c\c10bf50o\c59aa10l\c345512o\caa2066u\c005f00r\n!)", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(225, "\c0000ff\uRegister Now!\n for a commercial license", 0, 0, 0, 0)
  
  ;/ create test popupmenu for toolbar drop-down
  popupmenu = CreatePopupMenuEx(#PopupMenu_0, #UISTYLE_OFFICE2007)
  MenuItemEx(206, "Test menu", image(20)\normal, image(20)\hot, image(20)\disabled, 0)
  MenuItemEx(207, "Another one!", image(21)\normal, image(21)\hot, image(21)\disabled, 0)
  
  ;- create main toolbar
  toolbar = CreateToolBarEx(#TOOLBAR_0, WindowID(#Window_0), 16, 16, #TBSTYLE_HIDECLIPPEDBUTTONS|#UISTYLE_OFFICE2007)
  ToolBarImageButtonEx(0, "", image(24)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(1, "", image(25)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(2, "", image(26)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarSeparatorEx()
  ToolBarImageButtonEx(3, "", image(27)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(4, "", image(28)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarSeparatorEx()
  ToolBarImageButtonEx(5, "", image(29)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(6, "", image(30)\normal, 0, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarSeparatorEx()
  ToolBarImageButtonEx(7, "", image(31)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(8, "", image(32)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(9, "", image(33)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(10, "", image(34)\normal, 0, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarSeparatorEx()
  ToolBarDropdownImageButtonEx(11, popupmenu, "", image(35)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarDropdownImageButtonEx(12, popupmenu, "", image(36)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarSeparatorEx()
  ToolBarImageButtonEx(13, "", image(37)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(14, "", image(38)\normal, 0, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarImageButtonEx(15, "", image(39)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(16, "", image(40)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(17, "", image(41)\normal, 0, 0, #BTNS_AUTOSIZE)
  ToolBarImageButtonEx(18, "", image(42)\normal, 0, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  ToolBarSeparatorEx()
  ToolBarImageButtonEx(19, "", image(8)\normal, 0, 0, #BTNS_AUTOSIZE|#BTNS_CHECK)
  
  combo = ComboBoxGadget(#PB_Any, 50, 300, 76, 22, #PB_ComboBox_Editable)
  AddGadgetItem(combo, -1,"500%")
  AddGadgetItem(combo, -1,"200%")
  AddGadgetItem(combo, -1,"150%")
  AddGadgetItem(combo, -1,"100%")
  AddGadgetItem(combo, -1,"75%")
  AddGadgetItem(combo, -1,"50%")
  AddGadgetItem(combo, -1,"25%")
  AddGadgetItem(combo, -1,"10%")
  AddGadgetItem(combo, -1,"Page Width")
  AddGadgetItem(combo, -1,"Text Width")
  AddGadgetItem(combo, -1,"Whole Page")
  AddGadgetItem(combo, -1,"Two Pages")
  
  font = LoadFontEx(GetFontName(GetMenuExFont()), GetFontSize(GetMenuExFont()), 0)
  SetGadgetFont(combo, font)
  GadgetToolTip(combo, "Zoom")
  ToolBarExGadget(20, GadgetID(combo), 0, 1, 0, 3, #True)
  SetGadgetState(combo, 3)
  
  ToolBarImageButtonEx(21, "", image(91)\normal, 0, 0, #BTNS_AUTOSIZE)
  
  ;- disable some example buttons
  DisableToolbarExButton(toolbar, 7, #True)
  DisableToolbarExButton(toolbar, 8, #True)
  DisableToolbarExButton(toolbar, 9, #True)
  DisableToolbarExButton(toolbar, 11, #True)
  
  ;- some nice tooltips ;)
  ToolBarExToolTip(toolbar, 0, "New Blank Document")
  ToolBarExToolTip(toolbar, 1, "Open")
  ToolBarExToolTip(toolbar, 2, "Save")
  ToolBarExToolTip(toolbar, 3, "Print (No Printer)")
  ToolBarExToolTip(toolbar, 4, "Print Preview")
  ToolBarExToolTip(toolbar, 5, "Spelling and Grammer")
  ToolBarExToolTip(toolbar, 6, "Research")
  ToolBarExToolTip(toolbar, 7, "Cut")
  ToolBarExToolTip(toolbar, 8, "Copy")
  ToolBarExToolTip(toolbar, 9, "Paste")
  ToolBarExToolTip(toolbar, 10, "Format Painter")
  ToolBarExToolTip(toolbar, 11, "Undo Typing")
  ToolBarExToolTip(toolbar, 12, "Can't Redo")
  ToolBarExToolTip(toolbar, 13, "Insert Hyperlink")
  ToolBarExToolTip(toolbar, 14, "Tables and Borders")
  ToolBarExToolTip(toolbar, 15, "Insert Table")
  ToolBarExToolTip(toolbar, 16, "Insert Microsoft Excel Worksheet")
  ToolBarExToolTip(toolbar, 17, "Columns")
  ToolBarExToolTip(toolbar, 18, "Drawing")
  ToolBarExToolTip(toolbar, 19, "Document Map")
  ToolBarExToolTip(toolbar, 21, "Microsoft Office Word Help")
  
  ;- create help toolbar containing ComboBox and close button
  helpToolbar = CreateToolBarEx(#TOOLBAR_1, WindowID(#Window_0), 16, 16, 0)
  helpCombo = ComboBoxGadget(#PB_Any, 50, 300, 180, 22, #PB_ComboBox_Editable)
  SetGadgetFont(helpCombo, font)
  GadgetToolTip(helpCombo, "Type a question for help")
  SendMessage_(GadgetID(helpCombo), #CB_SETCUEBANNER, 0, "Type a question for help")
  ToolBarExGadget(300, GadgetID(helpCombo), 0, 0, 0, 0, #True)
  ToolBarImageButtonEx(301, "", crossImage, 0, 0, 0)
  ToolBarExToolTip(toolbar, 301, "Close Window")

  ;- disable Windows 7/Vista fade effect of toolbar buttons
  DisableToolBarExButtonFade(toolbar)
  
  ;- create a rebar
  CreateRebar(#REBAR_0, WindowID(#Window_0), 0, #RBS_VARHEIGHT|#UISTYLE_OFFICE2007, 0)
  AddRebarGadget(menu, "", 0, 100, GetMenuExBarHeight(menu)-3, 0, #RBBS_BREAK|#RBBS_CHILDEDGE|#RBBS_GRIPPERALWAYS)
  AddRebarGadget(helpToolbar, "", 206, 206, 0, 0, #RBBS_NOGRIPPER|#RBBS_FIXEDSIZE)
  AddRebarGadget(toolbar, "", 0, 0, 0, 0, #RBBS_BREAK)
  
  ;- create richedit control
  editor = EditorGadget(#PB_Any, 0, RebarHeight(#REBAR_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#REBAR_0))
  SetGadgetFont(editor, font)
  
  ;- add some example text to the richedit control
  txt.s = Chr(10)+"Welcome to the Office Example!"+Chr(10)+Chr(10)
  txt = txt + "Try changing your theme colour settings (XP), menu font and size in order to see ProGUI automatically adapt."+Chr(10)
  txt = txt + "ProGUI components also implement smooth and fast rendering, try resizing the main window!"+Chr(10)+Chr(10)
  txt = txt + "Keyboard hot-keys/shortcuts are also created automatically based on the menu item text."+Chr(10)+Chr(10)
  txt = txt + "Right click anywhere in this RichEdit control for a context pop-up menu with various style settings."+Chr(10)
  SetGadgetText(editor, txt)
  
  ;- create example ExplorerBar
  CreateExplorerBar(WindowID(#Window_0), #ExplorerBar, 5, 5, 210, 490, #UISTYLE_OFFICE2007)
  AddExplorerBarGroup("System Tasks", 0)
    ExplorerBarImageItem(0, "View system information", image(0)\normal, 0, 0, 0)
    ExplorerBarImageItem(1, "Add or remove programs", image(1)\normal, 0, 0, 0)
    ExplorerBarImageItem(2, "Change a setting", image(2)\normal, 0, 0, 0)
  AddExplorerBarGroup("Other Places", 0)
    ExplorerBarImageItem(3, "My Network Places", image(3)\normal, 0, 0, 0)
    ExplorerBarImageItem(4, "My Documents", image(4)\normal, 0, 0, 0)
    ExplorerBarImageItem(5, "Shared Documents", image(5)\normal, 0, 0, 0)
    ExplorerBarImageItem(6, "Control Panel", image(2)\normal, 0, 0, 0)
  AddExplorerBarGroup("Details", #True)
    ExplorerBarItem(7, "Example Item 1")
    ExplorerBarItem(8, "Example Item 2")
  
  ;- create main splitter control
  SplitterEx(WindowID(#Window_0), #Splitter, 0, RebarHeight(#REBAR_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#REBAR_0), GadgetID(editor), ExplorerBarID(#ExplorerBar), #UISTYLE_OFFICE2007, #SPLITTEREX_ANCHOREDRIGHT)
  SetSplitterExAttribute(#Splitter, #SPLITTEREX_POSITION, 600)
  SetSplitterExAttribute(#Splitter, #SPLITTEREX_SECONDMAXIMUMSIZE, 210)
  
  ; free loaded icons as we don't need them anymore
  For n = 0 To 100
    FreeImg(image(n)\normal)
    FreeImg(image(n)\hot)
    FreeImg(image(n)\disabled)
  Next
  
  ; attach our events callback for processing Windows ProGUI messages
  SetWindowCallback(@ProGUI_EventCallback())
  
EndProcedure

Open_Window_0() ; create window
HideWindow(0, 0)  ; show our newly created window

;- *** Enter main event loop ***
Repeat
  
  Event = WaitWindowEvent()
  
  If Event = #WM_RBUTTONDOWN ; capture rightclick on editor
    ProGUI_EventCallback(WindowID(#Window_0), #WM_RBUTTONDOWN, 0, 0)
  EndIf
  
Until Event = #PB_Event_CloseWindow
JustExit()
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 951
; FirstLine = 951
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = OfficeExample(x64).exe
; EnableUnicode