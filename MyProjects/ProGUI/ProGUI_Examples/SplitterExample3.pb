; Remember to enable XP Skin Support!
; Further demonstrates how to customize a system default SplitterEx skin
; and the "Anchoring" feature of the SplitterEx.
; Thanks to electrochrisso for this code example :)

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseWindow(#Window_0)
    End  
  EndIf
EndProcedure

If OpenWindow(#Window_0,0,0,640,480,"Splitter Example 3: Further custom modification of skin and Anchoring (single click on gripper)",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_SizeGadget|#PB_Window_Invisible)
  
  ExplorerListGadget(0,0,0,0,0,"C:\*.*")
  EditorGadget(1,0,0,0,0):SetGadgetText(1,"Editor Gadget 1")
  EditorGadget(2,0,0,0,0):SetGadgetText(2,"Editor Gadget 2")
  
  SetGlobalSkinColourTheme("blue")
  
  SplitterEx(WindowID(0),3,5,5,630,470/2,GadgetID(0),GadgetID(1),#UISTYLE_OFFICE2007,#SPLITTEREX_ANCHOREDLEFT)
  SplitterEx(WindowID(0),4,5,5,630,470,SplitterExID(3),GadgetID(2),#UISTYLE_OFFICE2007,#SPLITTEREX_VERTICAL|#SPLITTEREX_ANCHOREDBOTTOM)
  skin1 = CopySkin(GetSplitterExSkin(3))
  skin2 = CopySkin(GetSplitterExSkin(4))
  
  ;SetSkinProperty(skin1, "splitterex:blue", "normal", "background", "-1") ; Set background to none, this makes the SplitterEx share the background of the vertical SplitterEx
  SetSkinProperty(skin1, "splitterex:blue", "normal", "background", "#00ff00") ; Set green background for horizontal splitter
  SetSkinProperty(skin2, "splitterex:blue", "normal vertical", "background", "#0000ff") ; Set blue background for vertical splitter
  
  SetSkinProperty(skin1, "splitterex:blue", "normal", "gripper size", "width: 10; height: 0") ; make this skin's gripper fill the height of the SplitterEx and make it fatter ;)
  SetSkinProperty(skin1, "splitterex:blue", "normal", "first padding", "right: 5") ; make padding at the left side of gripper more for this skin
  SetSkinProperty(skin1, "splitterex:blue", "normal", "second padding", "left: 5") ; make padding at the right side of gripper more for this skin
  SetSkinProperty(skin2, "splitterex:blue", "normal vertical", "gripper size", "width: 0; height: 15") ; make this skin's gripper fill the width of the SplitterEx and make it fatter ;)
  SetSkinProperty(skin2, "splitterex:blue", "normal vertical", "first padding", "bottom: 2") ; make padding at the bottom side of gripper more for this skin
  SetSkinProperty(skin2, "splitterex:blue", "normal vertical", "second padding", "top: 2") ; make padding at the top side of gripper more for this skin
  SetSplitterExSkin(3, skin1, "", 0)
  SetSplitterExSkin(4, skin2, "", 0)
  
  SetSplitterExAttribute(4,#SPLITTEREX_POSITION,400)
  SetSplitterExAttribute(3,#SPLITTEREX_POSITION,200)
  
  HideWindow(0, #False) ; show our window
  
  ; main event loop
  Repeat
    Event = WaitWindowEvent()
    Select Event
        
        ; handle gadget events
      Case #PB_Event_Gadget
        
        Select EventGadget()
          Case 0
            If EventType()=#PB_EventType_LeftClick
              AddGadgetItem(1,-1,GetGadgetItemText(0,GetGadgetState(0)))
            EndIf
          Case 1
            If EventType() <> #EN_UPDATE ; filter out EditorGadget redraw notifications
              SetGadgetText(2,GetGadgetText(1))
            EndIf
          Case 2
            If EventType() <> #EN_UPDATE ; filter out EditorGadget redraw notifications
              AddGadgetItem(1,-1,"Editor 2")
            EndIf
        EndSelect
        
        ; resize SplitterEx when main window sized
      Case #PB_Event_SizeWindow
        MoveWindow_(SplitterExID(4),5,5,WindowWidth(0)-10,WindowHeight(0)-10, #True)
    EndSelect
  Until Event = #PB_Event_CloseWindow
  JustExit()
EndIf
End
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 18
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = SplitterExample3(x64).exe