; Remember to enable XP Skin Support!
; Side-by-side comparison example of SplitterEx against PureBasic SplitterGadget

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

#WindowWidth  = 500
#WindowHeight = 500

;- Window Constants
Enumeration
  #Window_0
  #Window_1
EndEnumeration

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseWindow(#Window_0)
    End
  EndIf
EndProcedure

; creates our ProGUI SplitterEx example window
Procedure Open_Window_0()
  
  OpenWindow(#Window_0, 50, 50, #WindowWidth, #WindowHeight, "Splitter Example 1: ProGUI SplitterEx with additional skin rendering", #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  HyperLinkGadget(27, 10, 5, 180, 30, "This is a green hyperlink", RGB(0,255,0))
  HyperLinkGadget(28, 200, 5, 220, 30, "This is a red hyperlink", RGB(255,0,0))
  
  SetGadgetFont(28, LoadFont(1, "courier", 10, #PB_Font_Underline | #PB_Font_Bold))

  ListIconGadget(20, 115, 10, 100, 190, "Test", 100)
  For k=0 To 10
    AddGadgetItem(20, -1, "Element "+Str(k))
  Next
  
  ExplorerListGadget(21, 115, 10, 100, 190, "", #PB_Explorer_AlwaysShowSelection|#PB_Explorer_FullRowSelect|#PB_Explorer_MultiSelect)

  TreeGadget(23, 115, 10, 100, 190)
  
  For k=0 To 10
    AddGadgetItem(23, -1, "Hello "+Str(k))
  Next

  PanelGadget(26, 0, 0, 400, 400)
    For k=0 To 5
      AddGadgetItem(26, -1, "Line "+Str(k))
      ButtonGadget(62+k, 10, 10, 100, 20, "Test"+Str(k))
    Next
  CloseGadgetList()
  
  SplitterEx(WindowID(#Window_0), 22, 0, 0, #WindowWidth/2, #WindowHeight/2, GadgetID(21), GadgetID(20), #UISTYLE_OFFICE2007, #SPLITTEREX_VERTICAL)
  SplitterEx(WindowID(#Window_0), 24, 0, 0, #WindowWidth, #WindowHeight, GadgetID(23), SplitterExID(22), #SPLITTEREX_DEFAULTSKIN2, 0)
  SplitterEx(WindowID(#Window_0), 25, 0, 40, #WindowWidth, #WindowHeight-40, SplitterExID(24), GadgetID(26), 0, 0)
  
  SetSplitterExAttribute(25, #SPLITTEREX_POSITION, 300)
  
EndProcedure

; creates our PureBasic SplitterGadget example window
Procedure Open_Window_1()
  
  OpenWindow(#Window_1, 600, 50, #WindowWidth, #WindowHeight, "Splitter Example 1: PureBasic SplitterGadget", #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  HyperLinkGadget(7, 10, 5, 180, 30, "This is a green hyperlink", RGB(0,255,0))
  HyperLinkGadget(8, 200, 5, 220, 30, "This is a red hyperlink", RGB(255,0,0))
  
  SetGadgetFont(8, LoadFont(0, "courier", 10, #PB_Font_Underline | #PB_Font_Bold))

  ListIconGadget(0, 115, 10, 100, 190, "Test", 100)
  For k=0 To 10
    AddGadgetItem(0, -1, "Element "+Str(k))
  Next
  
  ExplorerListGadget(1, 115, 10, 100, 190, "", #PB_Explorer_AlwaysShowSelection|#PB_Explorer_FullRowSelect|#PB_Explorer_MultiSelect)

  TreeGadget(3, 115, 10, 100, 190)
  
  For k=0 To 10
    AddGadgetItem(3, -1, "Hello "+Str(k))
  Next

  PanelGadget(6, 0, 0, 400, 400)
    For k=0 To 5
      AddGadgetItem(6, -1, "Line "+Str(k))
      ButtonGadget(32+k, 10, 10, 100, 20, "Test"+Str(k))
    Next
  CloseGadgetList()

  SplitterGadget(2, 0, 0, #WindowWidth/2, #WindowHeight/2, 1, 0)
  SplitterGadget(4, 0, 0, #WindowWidth, #WindowHeight, 3, 2, #PB_Splitter_Vertical | #PB_Splitter_Separator)
  SplitterGadget(5, 0, 40, #WindowWidth, #WindowHeight-40, 4, 6, #PB_Splitter_Vertical)
  
  SetGadgetState(5, 300)
  
EndProcedure

Open_Window_0() ; create ProGUI example window
HideWindow(#Window_0, 0)  ; show our newly created window

Open_Window_1() ; create PureBasic example window
HideWindow(#Window_1, 0)  ; show our newly created window

; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  window = EventWindow()
  
  If Event = #SPLITTEREX_MOUSEDOWN
    Debug "SplitterEx gripper mouse down"
  ElseIf Event = #SPLITTEREX_MOUSEUP
    Debug "SplitterEx gripper mouse up"
  ElseIf Event = #SPLITTEREX_MOUSEHOVER
    Debug "SplitterEx gripper mouse hover : "+Str(EventlParam())
  EndIf
  
  If Event = #PB_Event_Gadget
      
    Select EventGadget()

      Case 8
        
        SetGadgetState(5, 333)
        SetGadgetState(2, 333)
        
    EndSelect
    
  ElseIf Event = #PB_Event_SizeWindow
    
    ; resize main ProGUI SplitterEx when example window resized
    If window = #Window_0
      
      MoveWindow_(SplitterExID(25), 0, 40, WindowWidth(#Window_0), WindowHeight(#Window_0)-41, 1)
      
    ; resize main PureBasic SplitterGadget when example window resized
    ElseIf window = #Window_1
    
      ResizeGadget(5, #PB_Ignore, #PB_Ignore, WindowWidth(#Window_1), WindowHeight(#Window_1)-41) ; Our 'master' splitter gadget
      
    EndIf
    
  EndIf
  
Until Event = #PB_Event_CloseWindow
JustExit()
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 149
; FirstLine = 125
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = SplitterExample1(x64).exe