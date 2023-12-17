; Remember to enable XP Skin Support!
; Demonstrates a Preferences window using PanelEx's and TextControlEx's

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

;- PannelEx Constants
Enumeration
  #PanelEx_0
EndEnumeration

;- Fonts
Enumeration
  #Font_0
EndEnumeration

; header font
LoadFont(#Font_0, "Verdana", 14, #PB_Font_HighQuality)

;- Gadget Constants
Enumeration
  #Button_Ok
  #Button_Cancel
  #Button_15
  
  #CheckBox_0
  #CheckBox_1
  #CheckBox_2
  #CheckBox_3
  #CheckBox_4
  #CheckBox_5
  #CheckBox_6
  #CheckBox_7
  #CheckBox_8
  
  #Radio_0
  #Radio_1
  #Radio_2
  #Radio_3
  #Radio_4
  #Radio_5
  #Radio_6
  #Radio_7
  
  #String_0
  #String_1
  #String_2
  #String_3
  #String_4
  #String_5
  #String_6
  #String_7
  #String_8
  #String_9
  #String_10
  #String_11
  
  #Treeview_0
  
  #TextControl_0
  #TextControl_1
  #TextControl_2
  #TextControl_3
  #TextControl_4
  #TextControl_5
  
  #Text_0
  #Text_1
  #Text_2
  #Text_3
  #Text_4
  #Text_5
  #Text_6
  #Text_7
  #Text_8
  #Text_9
  #Text_10
  #Text_11
  #Text_14
  
  #Frame3D_1
  #Frame3D_2
  #Frame3D_3
  #Frame3D_4
  #Frame3D_5
  #Frame3D_6
  #Frame3D_7
  #Frame3D_8
  #Frame3D_9
  #Frame3D_10
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(6)

; load in some example icons
image(0)\normal = LoadImg("Icons\Preferences Icons\general.ico", 16, 16, 0)
image(1)\normal = LoadImg("Icons\Preferences Icons\connection.ico", 16, 16, 0)
image(2)\normal = LoadImg("Icons\Preferences Icons\proxy.ico", 16, 16, 0)
image(3)\normal = LoadImg("Icons\Preferences Icons\downloads.ico", 16, 16, 0)
image(4)\normal = LoadImg("Icons\Preferences Icons\appearance.ico", 16, 16, 0)

image(5)\normal = LoadImg("Icons\DCCManager\watermark2.png", 0, 0, 0)
image(5)\normal = ImgBlend(image(5)\normal, 20, 20, 50, 0, 0, #ImgBlend_DestroyOriginal)

;/ some useful treeview icon routines
#TVM_SETITEMHEIGHT = (#TV_FIRST + 27)
Procedure.l AddTreeIcon(TreeID.l,image.l)
  hItem=AddGadgetItem(TreeID,-1,"",image)
  tvitem.TV_ITEM
  tvitem\hItem=hItem
  tvitem\mask=#TVIF_IMAGE
  SendMessage_(GadgetID(TreeID), #TVM_GETITEM,0,@tvitem)
  
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
  
  OpenWindow(#Window_0, 50, 50, 600, 450, "PreferencesExample", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ;/- ok and cancel buttons
  ButtonGadget(#Button_Ok, 438, 420, 76, 24, "OK")
  ButtonGadget(#Button_Cancel, 518, 420, 76, 24, "Cancel")
  
  ;/ treeview gadget setup
  TreeGadget(#Treeview_0, 5, 5, 145, 410, #PB_Tree_NoButtons)
  SetWindowLongPtr_(GadgetID(#Treeview_0), #GWL_STYLE, GetWindowLongPtr_(GadgetID(#Treeview_0), #GWL_STYLE) | #TVS_TRACKSELECT)
  
  SendMessage_(GadgetID(#Treeview_0), #TVM_SETITEMHEIGHT, 22, 0)
  SendMessage_(GadgetID(#Treeview_0), #TVM_SETINDENT, 28, 0)
  
  icons = ImageList_Create_(16, 16, #ILC_MASK | #ILC_COLOR32, 0, 0)
  SendMessage_(GadgetID(#Treeview_0), #TVM_SETIMAGELIST, #TVSIL_NORMAL, icons)
  ImageList_ReplaceIcon_(icons, -1, image(0)\normal)
  ImageList_ReplaceIcon_(icons, -1, image(1)\normal)
  ImageList_ReplaceIcon_(icons, -1, image(2)\normal)
  ImageList_ReplaceIcon_(icons, -1, image(3)\normal)
  ImageList_ReplaceIcon_(icons, -1, image(4)\normal)
  
  ;- treeview nodes
  AddGadgetItem(#Treeview_0, -1, "General")
  SetTreeIcon(#Treeview_0,0,2)
  
  AddGadgetItem(#Treeview_0, -1, "Connection")
  SetTreeIcon(#Treeview_0,1,0)
  SetTreeExpanded(#Treeview_0,1)
  
  AddGadgetItem(#Treeview_0, -1, "IRC Proxy", 0, 1)
  SetTreeIcon(#Treeview_0,2,1)
  AddGadgetItem(#Treeview_0, -1, "DCC Proxy", 0, 1)
  SetTreeIcon(#Treeview_0,3,1)
  
  AddGadgetItem(#Treeview_0, -1, "Transfers")
  SetTreeIcon(#Treeview_0,4,4)
  
  AddGadgetItem(#Treeview_0, -1, "Appearance")
  SetTreeIcon(#Treeview_0,5,3)
  
  ;- pannels
  CreatePanelEx(#PanelEx_0, WindowID(#Window_0), 155, 5, 440, 412, 0)
  
  ;/ setup TextControlEx style
  SetTextControlExFont(-1, #Font_0, 1)
  SetTextControlExPadding(-1, 2, 2, 2, 2)
  grad = CreateGradient(0, MakeColour(255,$E0,$E6,$E9), MakeColour(50,$E0,$E6,$E9))
  SetTextControlExGradient(-1, grad)
  
  ;/ general pannel
  window = AddPanelExImagePage(0, image(5)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  
  TextControlEx(window, #TextControl_0, 2, 2, 434, 0, "General", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  FrameGadget(#Frame3D_6, 13, 44, 410, 80, "File Associations")
  CheckBoxGadget(#CheckBox_2, 30, 70, 215, 20, " Associate .XDCC files with DCC Manager")
  CheckBoxGadget(#CheckBox_3, 30, 92, 260, 20, " Associate IRC:// browser links with DCC Manager")
  
  ;/ connection pannel
  window = AddPanelExImagePage(0, image(5)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  TextControlEx(window, #TextControl_1, 2, 2, 434, 0, "Connection", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  window = FrameGadget(#Frame3D_7, 13, 44, 410, 90, "IRC Details")
  SetWindowLongPtr_(window, #GWL_EXSTYLE, GetWindowLongPtr_(window, #GWL_EXSTYLE)|#WS_EX_TRANSPARENT)
  TextGadget(#Text_10, 30, 68, 60, 20, "Nick Name")
  hStringGadget = StringGadget(#String_9, 90, 68, 120, 20, "")
  SendMessage_(hStringGadget, #EM_SETLIMITTEXT, 9, 0)
  TextGadget(#Text_14, 30, 98, 60, 20, "Password")
  StringGadget(#String_11, 90, 98, 120, 20, "",#PB_String_Password)
  TextGadget(#Text_11, 230, 68, 25, 20, "Port")
  StringGadget(#String_10, 258, 68, 60, 20, "", #PB_String_Numeric)
  
  FrameGadget(#Frame3D_9, 13, 150, 410, 60, "IRC Servers")
  CheckBoxGadget(#CheckBox_6, 30, 176, 368, 20, " Disconnect server when all active and queued downloads complete.")
  
  ;/ irc proxy pannel
  window = AddPanelExImagePage(0, image(5)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  TextControlEx(window, #TextControl_2, 2, 2, 434, 0, "IRC Proxy", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  y = 36
  x = 5
  
  FrameGadget(#Frame3D_1, 8+x, 8+y, 370, 160, "Proxy Server Settings")
  OptionGadget(#Radio_0, 28+x, 38+y, 90, 20, "No Firewall")
  OptionGadget(#Radio_1, 28+x, 68+y, 90, 20, "Http-proxy")
  OptionGadget(#Radio_2, 28+x, 98+y, 90, 20, "Socks4-proxy")
  OptionGadget(#Radio_3, 28+x, 128+y, 90, 20, "Socks5-proxy")
  StringGadget(#String_0, 178+x, 38+y, 190, 20, "", #PB_String_LowerCase)
  TextGadget(#Text_0, 148+x, 38+y, 30, 20, "Host")
  TextGadget(#Text_1, 148+x, 68+y, 30, 20, "Port")
  StringGadget(#String_1, 178+x, 68+y, 60, 20, "", #PB_String_Numeric)
  
  y = 145
  FrameGadget(#Frame3D_2, 8+x, 218, 370, 160, "Authentication Settings")
  x = - 115
  TextGadget(#Text_2, 148+x, 98+y, 80, 20, "Authentication")
  CheckBoxGadget(#CheckBox_0, 228+x, 96+y, 20, 20, "")
  TextGadget(#Text_3, 148+x, 128+y, 60, 20, "User Name")
  StringGadget(#String_2, 148+x, 148+y, 220, 20, "")
  TextGadget(#Text_4, 148+x, 178+y, 50, 20, "Password")
  StringGadget(#String_3, 148+x, 198+y, 220, 20, "", #PB_String_Password)
  
  ;/ dcc proxy pannel
  window = AddPanelExImagePage(0, image(5)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  TextControlEx(window, #TextControl_3, 2, 2, 434, 0, "DCC Proxy", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  y = 36
  x = 5
  
  FrameGadget(#Frame3D_3, 8+x, 8+y, 370, 160, "Proxy Server Settings")
  OptionGadget(#Radio_4, 28+x, 38+y, 90, 20, "No Firewall")
  OptionGadget(#Radio_5, 28+x, 68+y, 90, 20, "Http-proxy")
  OptionGadget(#Radio_6, 28+x, 98+y, 90, 20, "Socks4-proxy")
  OptionGadget(#Radio_7, 28+x, 128+y, 90, 20, "Socks5-proxy")
  StringGadget(#String_4, 178+x, 38+y, 190, 20, "", #PB_String_LowerCase)
  TextGadget(#Text_5, 148+x, 38+y, 30, 20, "Host")
  TextGadget(#Text_6, 148+x, 68+y, 30, 20, "Port")
  StringGadget(#String_5, 178+x, 68+y, 60, 20, "", #PB_String_Numeric)
  
  y = 145
  FrameGadget(#Frame3D_4, 8+x, 218, 370, 160, "Authentication Settings")
  x = - 115
  TextGadget(#Text_7, 148+x, 98+y, 80, 20, "Authentication")
  CheckBoxGadget(#CheckBox_1, 228+x, 96+y, 20, 20, "")
  TextGadget(#Text_8, 148+x, 128+y, 60, 20, "User Name")
  StringGadget(#String_6, 148+x, 148+y, 220, 20, "")
  TextGadget(#Text_9, 148+x, 178+y, 50, 20, "Password")
  StringGadget(#String_7, 148+x, 198+y, 220, 20, "", #PB_String_Password)
  
  ;/ transfers pannel
  window = AddPanelExImagePage(0, image(5)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  TextControlEx(window, #TextControl_4, 2, 2, 434, 0, "Transfers", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  FrameGadget(#Frame3D_5, 13, 44, 410, 60, "Download Directory")
  StringGadget(#String_8, 22, 68, 368, 20, "")
  ButtonGadget(#Button_15, 393, 67, 22, 22, "...")
  
  FrameGadget(#Frame3D_8, 13, 120, 410, 80, "Actions")
  CheckBoxGadget(#CheckBox_4, 22, 144, 368, 20, " Delete incomplete files when downloads removed from transfer list.")
  CheckBoxGadget(#CheckBox_5, 22, 166, 368, 20, " Remove file from transfer list when complete.")
  
  ;/ appearance pannel
  window = AddPanelExPage(0)
  TextControlEx(window, #TextControl_5, 2, 2, 434, 0, "Appearance", #TCX_BK_GRADIENT|#TCX_TRANSPARENT|#TCX_VCENTRE)
  
  FrameGadget(#Frame3D_10, 13, 44, 410, 80, "Main Application Window")
  CheckBoxGadget(#CheckBox_7, 30, 70, 368, 20, " Save window size and position on exit.")
  CheckBoxGadget(#CheckBox_8, 30, 92, 368, 20, " Minimize to system tray on program launch.")
  
  ; attach our events callback for processing Windows ProGUI messages
  SetWindowCallback(@ProGUI_EventCallback())
  
EndProcedure

Open_Window_0() ; create window
HideWindow(0, 0)  ; show our newly created window

; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  
  ; handle gadget events
  If Event = #PB_Event_Gadget
    Select EventGadget()
        
      ;/ handle treeview pannel selections
      Case #Treeview_0
        
        If EventType() = #PB_EventType_Change
          treeitem = GetGadgetState(#Treeview_0)
          ShowPanelExPage(#PanelEx_0, treeitem)
        EndIf
      
      ;/ handle ok and cancel buttons
      Case #Button_Ok
        Break
      Case #Button_Cancel
        Break
    EndSelect
  EndIf
  
Until Event = #PB_Event_CloseWindow
JustExit()
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 361
; FirstLine = 355
; Folding = --
; EnableThread
; EnableXP
; EnableUser
; Executable = PreferencesExample(x64).exe