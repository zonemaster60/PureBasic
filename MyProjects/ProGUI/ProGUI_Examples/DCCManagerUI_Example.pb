; Remember to enable XP Skin Support!
; Demonstrates how ProGUI components can easily be used
; to create novel, attractive and sophisticated user interfaces.

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

Global mainPanelEx
Global searchString.s
Global searchThread
Global searchProgressBand
Global history

#historyStart = 1000 ; start of unique menu ID's
history = #historyStart
Global w_xpos
Global w_ypos
Global w_width
Global w_height
w_width = 800
w_height = 600

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

;- MenuBar and Toolbar Constants
Enumeration
  #PopupMenu_0
EndEnumeration

Enumeration
  #TOOLBAR_0
  #SEARCHTOOLBAR
EndEnumeration

Enumeration
  #MENU_4
  #MENU_9
  #MENU_10
  #MENU_12
  #MENU_0
  #MENU_1
  #MENU_13
  #MENU_14
  #MENU_15
  #MENU_16
  #MENU_17
  #MENU_18
  #MENU_19
  #MENU_20
  #TBUTTON_0
  #TBUTTON_1
  #TBUTTON_2
  #TBUTTON_3
  #TBUTTON_4
  #TBUTTON_5
  #TBUTTON_6
  #TBUTTON_7
  #TBUTTON_8
  #TBUTTON_9
  #TBUTTON_10
  #TBUTTON_11
  #TBUTTON_12
  #TBUTTON_13
  #TBUTTON_14
  #TBUTTON_15
  #TBUTTON_16
  #SearchButton
  #SearchDropDown
  #IdEditCopy
  #IdEditClear
EndEnumeration

;- Rebar Constants
Enumeration
  #REBAR_0
  #SearchRebar
EndEnumeration

;- Gadget Constants
Enumeration
  #TOOLTAB_0
  #SEARCHCONTAINER1
  #SEARCHCONTAINER2
  #SEARCHCONTAINER3
  #ListIcon_3
  #EditorSplitter
  #EditorSplitter2
  #Editor_0
  #CommandString
  #CommandButton
  #SearchListIcon
  #SearchString
  #SearchProgressBar
  #SearchSplitter
  #SearchContainer
  #Panel_0
  #Treeview_0
EndEnumeration

;- PannelEx Constants
Enumeration
  #PannelEx_0
EndEnumeration

;- Fonts
Enumeration
  #Font_7
  #Font_8
EndEnumeration

#searchRightSpace = 285
#STATUSHEADER = "Status: "

#TVM_SETITEMHEIGHT = (#TV_FIRST+27)

; set up structure for easy access to images
Structure images
  normal.l
  hot.l
  disabled.l
EndStructure
Global Dim image.images(60)

;- Load in some images
ImgPath("Icons\DCCManager") ; set the default path for LoadImg

; download tab
image(0)\normal = LoadImg("down_tab2.ico", 0, 0, 0)
image(0)\hot = LoadImg("down_tab3.ico", 0, 0, 0)
image(0)\disabled = LoadImg("down_tab1.ico", 0, 0, 0)
; servers tab
image(3)\normal = LoadImg("servers_tab2.ico", 0, 0, 0)
image(3)\hot = LoadImg("servers_tab3.ico", 0, 0, 0)
image(3)\disabled = LoadImg("servers_tab1.ico", 0, 0, 0)
; search tab
image(2)\normal = LoadImg("search_tab2.ico", 0, 0, 0)
image(2)\hot = LoadImg("search_tab3.ico", 0, 0, 0)
image(2)\disabled = LoadImg("search_tab1.ico", 0, 0, 0)

; small search button
image(39)\normal = LoadImg("search_small.ico", 0, 0, 0)
image(39)\hot = LoadImg("search_small_h.ico", 0, 0, 0)
image(39)\disabled = LoadImg("search_small.p", 0, 0, 0)
; search dropdown
image(41)\normal = LoadImg("dropdown.ico", 0, 0, 0)
image(41)\hot = LoadImg("dropdown_h.ico", 0, 0, 0)
; small search stop button
image(42)\normal = LoadImg("stop_small.ico", 0, 0, 0)
image(42)\hot = LoadImg("stop_small_h.ico", 0, 0, 0)
image(42)\disabled = LoadImg("stop_small.p", 0, 0, 0)

; preferences button
image(12)\normal = LoadImg("wrench.ico", 0, 0, 0)
image(12)\hot = LoadImg("wrench_h.ico", 0, 0, 0)
image(12)\disabled = LoadImg("wrench_p.ico", 0, 0, 0)

; about button
image(29)\normal = LoadImg("DCC2_32x32.ico", 0, 0, 0)
image(29)\hot = LoadImg("DCC2_32x32_h.ico", 0, 0, 0)
image(29)\disabled = LoadImg("DCC2_32x32_p.ico", 0, 0, 0)

; download close button
image(46)\normal = LoadImg("X.ico", 0, 0, 0)
image(46)\hot = LoadImg("X_h.ico", 0, 0, 0)
image(46)\disabled = LoadImg("X_p.ico", 0, 0, 0)

; download stop button
image(47)\normal = LoadImg("nstop.ico", 0, 0, 0)
image(47)\hot = LoadImg("nstop_h.ico", 0, 0, 0)
image(47)\disabled = LoadImg("nstop_p.ico", 0, 0, 0)

; download start button
image(48)\normal = LoadImg("play.ico", 0, 0, 0)
image(48)\hot = LoadImg("play_h.ico", 0, 0, 0)
image(48)\disabled = LoadImg("play_p.ico", 0, 0, 0)

; small system log icon
image(11)\normal = LoadImg("log.ico", 0, 0, 0)
image(11)\hot = LoadImg("log2.ico", 0, 0, 0)
image(11)\disabled = LoadImg("log3.ico", 0, 0, 0)

; small proxy computer icon
image(19)\normal = LoadImg("Proxy.ico", 0, 0, 0)

; small server icon
image(40)\normal = LoadImg("smallServer.ico", 0, 0, 0)
image(40)\hot = LoadImg("smallServerConnect.ico", 0, 0, 0)

; rebar background
image(51)\normal = LoadImg("rebarBackground3.png", 0, 0, 0)

; panel watermark
image(43)\normal = LoadImg("watermark2.png", 0, 0, 0)

; download panel border
image(44)\normal = LoadImg("border.png", 0, 0, 0)
image(44)\disabled = LoadImg("border_m.png", 0, 0, 0)

; download container panel border
image(45)\normal = LoadImg("downloadpanel_border.png", 0, 0, 0)

; download container panel background
image(49)\normal = LoadImg("panelbackground.png", 0, 0, 0)

; file pane default movie image
image(50)\normal = LoadImg("movie8_128x128.png", 0, 0, 0)

image(60)\normal = LoadImg("icons\border.png", 0, 0, 0)
image(60)\hot = LoadImg("icons\border_m.png", 0, 0, 0)

; command prompt icon
Global CommandIcon = LoadImg("command_prompt", 0, 0, 0)

; download title font
LoadFont(#Font_7, "Corbel", 14);, #PB_Font_Bold)
; download status font
LoadFont(#Font_8, "Verdana", 8)

;- Treeview helper procedures
Procedure.l AddTreeIcon(TreeID.l,image.l)
  hItem=AddGadgetItem(TreeID,-1,"",image)
  tvitem.TV_ITEM
  tvitem\hItem=hItem
  tvitem\mask=#TVIF_IMAGE
  SendMessage_(GadgetID(TreeID), #TVM_GETITEM,0,@tvitem)
  ClearGadgetItems(TreeID)
  
  res=tvitem\iImage   
  ProcedureReturn res
EndProcedure 

Procedure.l SetTreeIcon(TreeID.l,index,IcoIndex.l)
  hItem=GadgetItemID(TreeID,index)
  txt.s=Space(1000)
  tvitem.TV_ITEM
  tvitem\hItem=hItem
  tvitem\pszText=@txt
  tvitem\cchTextMax = 1000
  tvitem\mask=#TVIF_TEXT|#TVIF_IMAGE|#TVIF_HANDLE|#TVIF_SELECTEDIMAGE
  SendMessage_(GadgetID(TreeID), #TVM_GETITEM,0,@tvitem)
  tvitem\iImage=IcoIndex
  tvitem\iSelectedImage=IcoIndex
  SendMessage_(GadgetID(TreeID), #TVM_SETITEM,0,@tvitem)     
EndProcedure

Procedure.l SetTreeStateIcon(TreeID.l,index,IcoIndex.l)
  hItem=GadgetItemID(TreeID,index)
  txt.s=Space(1000)
  tvitem.TV_ITEM
  tvitem\hItem=hItem
  tvitem\pszText=@txt
  tvitem\cchTextMax = 1000
  tvitem\mask=#TVIF_TEXT|#TVIF_STATE|#TVIF_HANDLE
  SendMessage_(GadgetID(TreeID), #TVM_GETITEM,0,@tvitem)
  tvitem\state=IcoIndex
  tvitem\state=tvitem\state << 12
  tvitem\stateMask = #TVIS_STATEIMAGEMASK
  SendMessage_(GadgetID(TreeID), #TVM_SETITEM,0,@tvitem)     
EndProcedure

Procedure.l SetTreeExpanded(TreeID.l,index)
  hItem=GadgetItemID(TreeID,index)
  txt.s=Space(1000)
  tvitem.TV_ITEM
  tvitem\hItem=hItem
  tvitem\pszText=@txt
  tvitem\cchTextMax = 1000
  tvitem\mask=#TVIF_TEXT|#TVIF_STATE|#TVIF_HANDLE
  SendMessage_(GadgetID(TreeID), #TVM_GETITEM,0,@tvitem)
  tvitem\state=#TVIS_EXPANDED
  tvitem\stateMask = #TVIS_EXPANDED
  SendMessage_(GadgetID(TreeID), #TVM_SETITEM,0,@tvitem)     
EndProcedure

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseWindow(#Window_0)
    End
  EndIf
EndProcedure

;- File Pane Structure
#filePaneXOFFSET = 2
#filePaneYOFFSET = 2
#filePaneXSPACE = 5
#filePaneYSPACE = 5
Global filePaneWidth = 370
Global filePaneHeight = 231
Structure filePanes
  
  filename.s
  panelExID.l
  panelExHandle.l
  titleID.l
  albumArtID.l
  cancelButtonID.l
  stopButtonID.l
  infoTextID.l
  streamInfoID.l
  statusTextID.l
  progressBarID.l
  
EndStructure

Global NewList filePane.filePanes()

; creates a new file transfer pane in the main PanelEx transfers page
Procedure newFilePane(filename.s)
  Static headerGradient
  
  ; iterate through filePanes and calc next position for new filepane
  ForEach filePane()
    
    GetWindowRect_(filePane()\panelExHandle, @rc.RECT)
    MapWindowPoints_(0, mainPanelEx, @rc, 2)
    n = n + 1
    
  Next
  x = n*(filePaneWidth+1)
  
  ; add position offset if first filePane in list
  If x = 0
    x = x + #filePaneXOFFSET
  EndIf
  If y = 0
    y = y + #filePaneYOFFSET
  EndIf
  
  ; create new filePane element
  LastElement(filePane())
  If AddElement(filePane()) = 0 ; if we dont have enough mem to allocate new element in linked list, return
    ProcedureReturn -1 ; out of mem error
  EndIf
  
  id = CreatePanelEx(#PB_Any, PanelExID(mainPanelEx, 0), x, y, filePaneWidth, filePaneHeight, 0)
  panelExHandle = PanelExID(id, -1)
  page = AddPanelExImagePage(-1, image(49)\normal, 0, 0, 0, 0, 0)
  
  If headerGradient = 0
    headerGradient = CreateGradient(0, MakeColour(200, 255, 255, 255), MakeColour(0, 255, 255, 255))
  EndIf
  
  SetTextControlExFont(-1, FontID(#Font_7), #True)
  titleID = TextControlEx(page, #PB_Any, 10, 10, 0, 0, filename, #TCX_BK_GRADIENT)
  SetTextControlExGradient(titleID, headerGradient)
  SetTextControlExPadding(titleID, 5, 1, 10, 1)
  
  cancelButtonID = ImageButtonEx(page, #PB_Any, 343, 10, 0, 0, image(46)\normal, image(46)\hot, image(46)\disabled, image(46)\normal)
  ButtonExToolTip(cancelButtonID, "Cancel Download")
  
  albumArtID = ImageButtonEx(page, #PB_Any, 10, 40, 128, 128, image(50)\normal, 0, 0, 0)
  
  SetTextControlExFont(-1, FontID(#Font_8), 0)
  
  y = 40
  
  txt.s = "\bRelease Group\b: test\|"
  txt+"\bSource\b: TeleSync\|"
  txt+"\bSize\b: 600 MB\|"
  txt+"\l1234\bLink here:\b This is a test link|\c0000ff\bLink here:\b This is a test link\n\l\|"
  txt+"\bAudio\b: English | 130kbps | VBR MP3\|"
  txt+"\bSubtitles\b: N/A\|"
  txt+"\l12345\c0000ffView NFO\n|\c0000ff\uView NFO\u\n\l"
  
  infoTextID = TextControlEx(page, #PB_Any, 144, y, 0, 0, txt, #TCX_TRANSPARENT):y+14
  SetTextControlExLinePadding(infoTextID, 2)
  
  y+18
  
  statusTextID = TextControlEx(page, #PB_Any, 10, 180, 0, 0, "30 Minutes left, 350 of 600 MB (220 KB/sec)", #TCX_TRANSPARENT)
  
  progressBarID = ProgressBarGadget(#PB_Any, 10, 200, 328, 20, 0, 100)
  SetGadgetState(progressBarID, 50)
  
  stopButtonID = ImageButtonEx(page, #PB_Any, 343, 203, 0, 0, image(47)\normal, image(47)\hot, image(47)\disabled, image(47)\normal)
  ButtonExToolTip(stopButtonID, "Stop Download")
  
  ;/ put handles/IDs into filePane structure
  filePane()\filename = filename
  filePane()\panelExHandle = panelExHandle
  filePane()\panelExID = id
  filePane()\titleID = titleID
  filePane()\albumArtID = albumArtID
  filePane()\cancelButtonID = cancelButtonID
  filePane()\stopButtonID = stopButtonID
  filePane()\infoTextID = infoTextID
  filePane()\statusTextID = statusTextID
  filePane()\progressBarID = progressBarID
  
  ProcedureReturn panelExHandle
  
EndProcedure

Procedure simulateSearch(dummy)
  
  ShowRebarBand(RebarID(#SearchRebar), searchProgressBand, #True)
  SendMessage_(GadgetID(#SearchProgressBar), #WM_USER + 10, 1, 10)
  
  Repeat
    AddGadgetItem(#SearchListIcon, -1, "test search result "+Str(Random(1000)))
    StatusBarText(0, 0, #STATUSHEADER+"Searching for "+Chr(34)+searchString+Chr(34)+", found "+Str(CountGadgetItems(#SearchListIcon))+" results...")
    Delay(Random(1000))
  Until Random(100) = 0
  
  ShowRebarBand(RebarID(#SearchRebar), searchProgressBand, #False)
  ChangeToolbarExButton(#SEARCHTOOLBAR, #SearchButton, "", image(39)\normal, image(39)\hot, image(39)\disabled)
  ToolBarExToolTip(#SEARCHTOOLBAR, #SearchButton, "Search...")
  searchThread = 0
  StatusBarText(0, 0, #STATUSHEADER+"Search of "+Chr(34)+searchString+Chr(34)+" complete, found "+Str(CountGadgetItems(#SearchListIcon))+" results.")
  
EndProcedure

; user main panelex callback for resizing gadgets inside
Procedure myPannelCallback(Window, message, wParam, lParam)
  
  Select message

    Case #WM_SIZE
      
      width = lParam & $FFFF ; LOWORD
      height = (lParam >> 16) & $FFFF ; HIWORD
      MoveWindow_(GadgetID(#EditorSplitter), 0, 0, width, height, #False)
      
  EndSelect
  
  ProcedureReturn 0
EndProcedure

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items, toolbar items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        ID = LWord(wParam)
      
        ;- handle selection of panels
        ;/ Transfers panel selected
        If ID = #TBUTTON_0
          
          ShowPanelExPage(0, 0)
          
          ; set focus to search stringgadget
          SetActiveGadget(#SearchString)
        
        ;/ servers panel selected
        ElseIf ID = #TBUTTON_2
        
          ShowPanelExPage(0, 1)
          
          ; set focus to command stringgadget
          SetActiveGadget(#CommandString)
        
        ;/ search pannel selected
        ElseIf ID = #TBUTTON_15
          
          ShowPanelExPage(0, 2)
          
          ; set focus to search stringgadget
          SetActiveGadget(#SearchString)
          
        EndIf
        
        If ID = 26
          ShowPanelExPage(113, 1)
          
          SetParent_(pane, WindowID(win))
        ElseIf ID = 30
          ShowPanelExPage(113, 0)
        EndIf
        
        ;- handle search box events
        ; handle search dropdown button
        If ID = #SearchDropDown
          
          SendMessage_(ToolBarExID(#SEARCHTOOLBAR), #TB_GETRECT, #SearchDropDown, @rc.RECT)
          MapWindowPoints_(ToolBarExID(#SEARCHTOOLBAR), 0, @rc, 2)
          SelectToolbarExButton(#SEARCHTOOLBAR, #SearchDropDown, #True)
          DisplayPopupMenuEx(#PopupMenu_0, WindowID(#Window_0), rc\right-CalcMenuItemWidth(MenuExID(#PopupMenu_0))+1, rc\bottom)
          SelectToolbarExButton(#SEARCHTOOLBAR, #SearchDropDown, #False)
          
        ; search button pressed or enter pressed in search string gadget
        ElseIf ID = #SearchButton
        
          search.s = GetGadgetText(#SearchString)
          If searchThread = 0
            If search <> ""
              ClearGadgetItems(#SearchListIcon) ; ;clear previous search results
              SelectToolbarExButton(#TOOLBAR_0, #TBUTTON_15, #True) 
              ShowPanelExPage(0, 2)
              SetActiveGadget(#SearchSplitter) ; remove focus from search string gadget
              ChangeToolbarExButton(#SEARCHTOOLBAR, #SearchButton, "", image(42)\normal, image(42)\hot, image(42)\disabled)
              ToolBarExToolTip(#SEARCHTOOLBAR, #SearchButton, "Stop Search")
              InsertMenuItemEx(#PopupMenu_0, 0, history, search, 0, 0, 0, 0)
              history = history + 1
              searchString = search
              StatusBarText(0, 0, #STATUSHEADER+"Searching for "+Chr(34)+searchString+Chr(34)+"...")
              SetGadgetText(#SearchString, "")
              searchThread = CreateThread(@simulateSearch(), 0)
            EndIf
          Else
            KillThread(searchThread)
            searchThread = 0
            ShowRebarBand(RebarID(#SearchRebar), searchProgressBand, #False)
            ChangeToolbarExButton(#SEARCHTOOLBAR, #SearchButton, "", image(39)\normal, image(39)\hot, image(39)\disabled)
            ToolBarExToolTip(#SEARCHTOOLBAR, #SearchButton, "Search...")
            StatusBarText(0, 0, #STATUSHEADER+"Search of "+Chr(34)+searchString+Chr(34)+" canceled, found "+Str(CountGadgetItems(#SearchListIcon))+" results.")
          EndIf
          
        ; handle selection of history item
        ElseIf ID >= #historyStart
          SetGadgetText(#SearchString, GetMenuItemExText(#PopupMenu_0, ID))
        EndIf
        
        Debug ID
        
      EndIf
      
    ; resize main panelex and toolbar search box when main window resized
    Case #WM_SIZE
      
      SetWindowPos_(mainPanelEx, 0, 0, RebarHeight(#TOOLTAB_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#TOOLTAB_0)-23, #SWP_NOCOPYBITS|#SWP_NOREDRAW|#SWP_NOZORDER)
    
      SetToolBarExButtonWidth(#TOOLBAR_0, 1337, WindowWidth(#Window_0)-300)
      MoveWindow_(GadgetID(#SEARCHCONTAINER2), 1, 1, (WindowWidth(#Window_0)-#searchRightSpace)-17, 20, #False)
      MoveWindow_(GadgetID(#SearchString), 3, 3, (WindowWidth(#Window_0)-#searchRightSpace)-58, 18, #False)
      MoveWindow_(GadgetID(#SEARCHCONTAINER3), (WindowWidth(#Window_0)-#searchRightSpace)-53, 0, 53, 20, #False)
      
    ; detect TextControlEx link hover
    Case #TCX_LINK_HOVER
      
      Debug "hover: "+Str(wParam)
      
    ; detect TextControlEx link click
    Case #TCX_LINK_CLICK
      
      Debug "click: "+Str(wParam)
      
  EndSelect
  
  ProcedureReturn #PB_ProcessPureBasicEvents
  
EndProcedure

Procedure Open_Window_0()
   
  OpenWindow(#Window_0, 0, 0, w_width, w_height, "DCC Manager V1.8 User Interface Example", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  WindowBounds(#Window_0, 400, 200, #PB_Ignore, #PB_Ignore)
  
  If IsWindow(#Window_0)
    
    ;/ create empty search history popupmenu for search drop-down button
    popupmenu = CreatePopupMenuEx(#PopupMenu_0, 0)
    
    ; create main toolbar
    toolbar = CreateToolBarEx(#TOOLBAR_0, WindowID(#Window_0), 53, 39, #UISTYLE_IMAGE)
    
    ToolBarImageButtonEx(#TBUTTON_0, "", image(0)\normal, image(0)\hot, image(0)\disabled, #BTNS_CHECKGROUP)
    SetToolBarExButtonWidth(toolbar, #TBUTTON_0, 54)
    SelectToolbarExButton(#TOOLBAR_0, #TBUTTON_0, 1)
    ToolBarImageButtonEx(#TBUTTON_2, "", image(3)\normal, image(3)\hot, image(3)\disabled, #BTNS_CHECKGROUP)
    SetToolBarExButtonWidth(toolbar, #TBUTTON_2, 54)
    ToolBarImageButtonEx(#TBUTTON_15, "", image(2)\normal, image(2)\hot, image(2)\disabled, #BTNS_CHECKGROUP)
    SetToolBarExButtonWidth(toolbar, #TBUTTON_15, 54)
    ToolBarImageButtonEx(#TBUTTON_12, "", image(12)\normal, image(12)\hot, image(12)\disabled, #BTNS_AUTOSIZE)
    ToolBarImageButtonEx(#TBUTTON_16, "", image(29)\normal, image(29)\hot, image(29)\disabled, #BTNS_AUTOSIZE)
    
    ; create search string gadget mess lol
    ContainerGadget(#SEARCHCONTAINER1, 170, 18, (WindowWidth(#Window_0)-#searchRightSpace)-15, 22)
      SetGadgetColor(#SEARCHCONTAINER1, #PB_Gadget_BackColor, RGB(172,168,153))
      ContainerGadget(#SEARCHCONTAINER2, 1, 1, (WindowWidth(#Window_0)-#searchRightSpace)-17, 20)
      
        SetGadgetColor(#SEARCHCONTAINER2, #PB_Gadget_BackColor, RGB(255,255,255))
        StringGadget(#SearchString, 3, 3, (WindowWidth(#Window_0)-#searchRightSpace)-58, 18, "", #PB_String_BorderLess)
        
        ContainerGadget(#SEARCHCONTAINER3, (WindowWidth(#Window_0)-#searchRightSpace)-53, 0, 53, 20)
        search = CreateToolBarEx(#SEARCHTOOLBAR, GadgetID(#SEARCHCONTAINER3), 18, 20, #UISTYLE_IMAGE)
        ToolBarImageButtonEx(#SearchButton, "", image(39)\normal, image(39)\hot, image(39)\disabled, #BTNS_AUTOSIZE)
        ToolBarImageButtonEx(#SearchDropDown, "", image(41)\normal, image(41)\hot, image(41)\hot, #BTNS_AUTOSIZE)
        CloseGadgetList()
        SetParent_(GadgetID(#SEARCHCONTAINER3), GadgetID(#SEARCHCONTAINER2))
        
      CloseGadgetList()
    CloseGadgetList()
    
    ; insert search container into toolbar
    InsertToolBarExGadget(toolbar, 3, 1337, GadgetID(#SEARCHCONTAINER1), 3, 14, 12, 17, 0)
    
    ; some nice tooltips ;)
    ToolBarExToolTip(toolbar, #TBUTTON_0, "Transfers")
    ToolBarExToolTip(toolbar, #TBUTTON_2, "Servers")
    ToolBarExToolTip(toolbar, #TBUTTON_15, "Search Results")
    ToolBarExToolTip(toolbar, #TBUTTON_12, "Settings")
    ToolBarExToolTip(toolbar, #TBUTTON_16, "About")
    ToolBarExToolTip(search, #SearchButton, "Search...")
    ToolBarExToolTip(search, #SearchDropDown, "Search History")
    ToolBarExToolTipDelay(toolbar, 900, 0, 600)
    ToolBarExToolTipDelay(search, 1200, 0, 600)
    
    ; create rebar and insert main toolbar into it
    rebar = CreateRebar(#TOOLTAB_0, WindowID(#Window_0), image(51)\normal, #RBS_VARHEIGHT , 0)
    spacer = TextControlEx(WindowID(#Window_0), 1337, 0, 0, 0, 0, "", 0) ; a bit hackish! ;)
    AddRebarGadget(spacer, "", 0, 0, 4, 0, #RBBS_BREAK|#RBBS_NOGRIPPER)
    AddRebarGadget(toolbar, "", 0, 0, 41, 0, #RBBS_BREAK|#RBBS_NOGRIPPER)
    binfo.REBARBANDINFO
    binfo\cbSize = SizeOf(REBARBANDINFO)
    binfo\fMask = #RBBIM_HEADERSIZE
    binfo\cxHeader = 6
    SendMessage_(rebar, #RB_SETBANDINFO, 1, binfo)
    
    ; create main PanelEx
    mainPanelEx = CreatePanelEx(#PannelEx_0, WindowID(#Window_0), 0, RebarHeight(rebar), w_width, w_height-RebarHeight(rebar)-23, @myPannelCallback())
    
    ; create nice gradient for transfers page backgorund
    Gradient = CreateGradient(#VerticalGRADIENT, MakeColour(255, 133, 133, 126), MakeColour(255, 46, 44, 38))
    
    ;- create new transfers page
    page = AddPanelExImagePage(Gradient, image(43)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
    
    ; add nice drop-shadow border to page
    border.RECT
    border\left = 40
    border\right = 140
    border\top = 40
    border\bottom = 140
    SetPanelExPageBorder(#PannelEx_0, 0, image(45)\normal, -1, border, 0, 0)
    
    ; make page scrollable
    SetPanelExPageScrolling(mainPanelEx, 0, #PNLX_AUTOSCROLL, #True)
    
    ;- create new servers/log page
    Panel = AddPanelExPage(-1)
    
    ; create a tree gadget for displaying system log and servers
    TreeGadget(#ListIcon_3, 0, 0, 370, 190, #PB_Tree_AlwaysShowSelection)
    icons = ImageList_Create_(16, 16, #ILC_MASK | #ILC_COLOR32, 0, 0)
    SendMessage_(GadgetID(#ListIcon_3), #TVM_SETIMAGELIST, #TVSIL_NORMAL, icons)
    ImageList_ReplaceIcon_(icons, -1, image(11)\normal)
    ImageList_ReplaceIcon_(icons, -1, image(40)\normal)
    ImageList_ReplaceIcon_(icons, -1, image(40)\hot)
    ImageList_ReplaceIcon_(icons, -1, image(19)\normal)
    
    ; add system log icon to tree
    AddGadgetItem(#ListIcon_3, -1, "System")
    SetTreeIcon(#ListIcon_3,0,0)
    SetGadgetItemData(#ListIcon_3, 0, -1)
    
    ; set style of tree to display underline over items when mouse hover
    SetWindowLong_(GadgetID(#ListIcon_3), #GWL_STYLE, GetWindowLong_(GadgetID(#ListIcon_3), #GWL_STYLE) | #TVS_TRACKSELECT)
    SendMessage_(GadgetID(#ListIcon_3), #TVM_SETITEMHEIGHT, 19, 0) ; sets the hight of the tree items
    SetGadgetState(#ListIcon_3, 1)
    
    ; create a read only editor gadget for displaying server/system messages 
    EditorGadget(#Editor_0, 0, 0, 200, 200, #PB_Editor_ReadOnly)
    format.CHARFORMAT
    format\cbSize = SizeOf(CHARFORMAT)
    format\dwMask = #CFM_FACE|#CFM_SIZE
    format\yHeight = 8*20
    PokeS(@format\szFaceName,"Bitstream Vera Sans Mono")
    SendMessage_(GadgetID(#Editor_0),#EM_SETCHARFORMAT,#SCF_SELECTION,@format)
    SendMessage_(GadgetID(#Editor_0),#EM_SETOPTIONS,#ECOOP_SET, #ECO_AUTOVSCROLL)
    SendMessage_(GadgetID(#Editor_0),#EM_SETEVENTMASK,0, #ENM_LINK)
    SendMessage_(GadgetID(#Editor_0),#EM_SETREADONLY, #True, 0)
    
    ; add an RTF encoded welcome message string to the edit gadget
    lmsg.s = "{\rtf1{\colortbl;\red98\green124\blue118;}{\pard\qc\line **** Welcome to {\b\fs18 the DCC Manager V1.8 User Interface Example} ****\line {\b\cf1 ProGUI Version: "+StrF(ProGUIVersion(), 2)+"} \par}"
    AddGadgetItem(#Editor_0, -1, lmsg)
    
    ; create a command input bar
    test = ContainerGadget(#PB_Any, 0, 0, 400, 20, #PB_Container_BorderLess)
    StringGadget(#CommandString, 0, 0, 300, 20, "")
    ButtonImageGadget(#CommandButton, 305, -1, 40, 21, CommandIcon)
    CloseGadgetList()
    UseGadgetList(Panel)
    
    ; set up layout of tree, editor and command input
    SplitterGadget(#EditorSplitter2, 0, 0, 470, 50, #Editor_0, test, #PB_Splitter_SecondFixed)
    SplitterGadget(#EditorSplitter, 0, 0, 370, 190, #ListIcon_3, #EditorSplitter2, #PB_Splitter_FirstFixed|#PB_Splitter_Vertical)
    SetGadgetAttribute(#EditorSplitter, #PB_Splitter_FirstMinimumSize, 150)
    SetGadgetAttribute(#EditorSplitter, #PB_Splitter_SecondMinimumSize, 350)
    SetGadgetAttribute(#EditorSplitter2, #PB_Splitter_SecondMinimumSize, 25)
    SetGadgetAttribute(#EditorSplitter2, #PB_Splitter_FirstGadget, #Editor_0)
    SetGadgetState(#EditorSplitter2, 1000)
      
    ;- create new search page
    Panel = AddPanelExPage(-1)
    ProgressBarGadget(#SearchProgressBar, 0, 0, 200, 15, 0, 100, 8)
    ListIconGadget(#SearchListIcon, 0, 0, 470, 150, "File Name", 292, #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#SearchListIcon, 2, "Size", 55)
    AddGadgetColumn(#SearchListIcon, 3, "Bit Rate", 65)
    AddGadgetColumn(#SearchListIcon, 4, "Status", 110)
    AddGadgetColumn(#SearchListIcon, 5, "Sources", 55)
    SearchIconsList = ImageList_Create_(16, 16, #ILC_MASK | #ILC_COLOR32, 0, 0)
    SendMessage_(GadgetID(#SearchListIcon), #LVM_SETIMAGELIST, #LVSIL_NORMAL, SearchIconsList)
    SendMessage_(GadgetID(#SearchListIcon), #LVM_SETEXTENDEDLISTVIEWSTYLE , #LVS_EX_ONECLICKACTIVATE , #LVS_EX_ONECLICKACTIVATE)
    SendMessage_(GadgetID(#SearchListIcon), #LVM_SETEXTENDEDLISTVIEWSTYLE , #LVS_EX_UNDERLINEHOT , #LVS_EX_UNDERLINEHOT)
    SendMessage_(GadgetID(#SearchListIcon), #LVM_SETEXTENDEDLISTVIEWSTYLE , #LVS_EX_DOUBLEBUFFER , #LVS_EX_DOUBLEBUFFER)
    SetWindowLong_(GadgetID(#SearchListIcon), #GWL_STYLE, GetWindowLong_(GadgetID(#SearchListIcon), #GWL_STYLE)|#WS_CLIPCHILDREN)
    
    WebGadget(#SearchContainer, 0, 0, 100, 100, "")
    ;ButtonGadget(#SearchContainer, 0, 0, 100, 100, "test")
    SplitterGadget(#SearchSplitter, 0, 0, 200, 200, #SearchContainer, #SearchListIcon, #PB_Splitter_Vertical)
    SetGadgetAttribute(#SearchSplitter, #PB_Splitter_SecondMinimumSize, 528) 
    SetGadgetItemText(#SearchContainer, #PB_Web_HtmlCode, "This is where new releases would be displayed and is a web gadget")
    
    CreateRebar(#SearchRebar, Panel, 0, #RBS_VARHEIGHT | #CCS_NODIVIDER, 0)
    AddRebarGadget(GadgetID(#SearchSplitter), "", 600, 0, 0, 0, #RBBS_BREAK|#RBBS_NOGRIPPER|#RBBS_SIZEABLE)
    searchProgressBand = AddRebarGadget(GadgetID(#SearchProgressBar), "", 80, 80, 0, 0, #RBBS_BREAK|#RBBS_NOGRIPPER)
    ShowRebarBand(RebarID(#SearchRebar), searchProgressBand, 0)
      
    ;- create a status bar at the bottom of the main window
    bar = CreateStatusBar(0, WindowID(#Window_0)) 
    SetWindowPos_(bar, #HWND_TOP, 0,0,0,0,0)
    AddStatusBarField(600)
    StatusBarText(0, 0, #STATUSHEADER+"**** Welcome to the DCC Manager V1.8 User Interface Example ****")
    
    Gradient = CreateGradient(#VerticalGRADIENT, MakeColour(100, 255, 133, 126), MakeColour(180, 255, 44, 38))
    
    ; resize server page gadgets to fit in main panelex
    MoveWindow_(GadgetID(#EditorSplitter), 0, 0, PanelExWidth(mainPanelEx), PanelExHeight(mainPanelEx), #True)
    
    ; attach our events callback for processing Windows ProGUI messages
    SetWindowCallback(@ProGUI_EventCallback())
    
  EndIf

EndProcedure

Open_Window_0()
HideWindow(#Window_0, #False)

; create some test file panes
newFilePane("Example Media Title1 avi")
newFilePane("Example Media Title2 avi")

; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  
  If Event = #PB_Event_Gadget
    gadget = EventGadget()
    
    ;/ handle pressing of return key in search string gadget, set up temp keyboard accelerators on focus
    ; which triggers the #SearchButton menu event when return pressed
    If gadget = #SearchString
      Select EventType()
        Case #PB_EventType_Focus
          AddKeyboardShortcut(#Window_0, #PB_Shortcut_Return, #SearchButton)
        Case #PB_EventType_LostFocus
          RemoveKeyboardShortcut(#Window_0, #PB_Shortcut_Return)
      EndSelect 
    EndIf
    
    ;Debug gadget
  EndIf
  
Until Event = #PB_Event_CloseWindow
JustExit()

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 5
; FirstLine = 2
; Folding = --
; EnableThread
; EnableXP
; EnableUser
; Executable = DCCManagerUI_Example(x64).exe