; Remember to enable XP Skin Support!
; Demonstrates how to customize a system default SplitterEx skin
; Thanks to electrochrisso for his source code examples used as a base :)

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

Procedure OpenWindow_0()
  
  OpenWindow(#Window_0, 0, 0, 640, 480, "Splitter Example 2: custom modification of Office 2007 skin",#PB_Window_ScreenCentered|#PB_Window_SystemMenu|#PB_Window_SizeGadget|#PB_Window_Invisible)
  
  SetGlobalSkinColourTheme("blue")
  
  explorer = ExplorerListGadget(#PB_Any,0,0,0,0,"C:\*.*")
  editor = EditorGadget(#PB_Any,0,0,0,0)
  SetGadgetText(editor,"Editor Gadget 1")
  
  SplitterEx(WindowID(#Window_0),2,5,5,630,470,GadgetID(explorer),GadgetID(editor),#UISTYLE_OFFICE2007,0) ; create horizontal SplitterEx using default Office 2007 skin
  skin = GetSplitterExSkin(2) ; get a handle to the default system Office 2007 SplitterEx skin (you could also alter this skin directly, effecting all #UISTYLE_OFFICE2007 SplitterEx default skins)
  skin2 = CopySkin(skin) ; make a copy of the system skin
  
  Debug "Original background property of blue theme Office 2007 skin:"
  Debug GetSkinProperty(skin2, "splitterex:blue", "normal", "background") ; display this skins 'normal' state CSS markup for the SplitterEx background (from the blue theme)
  
  SetSkinProperty(skin2, "splitterex:blue", "normal", "background", "red") ; change this skin's background to red 
  ;SetSkinProperty(skin2, "splitterex:blue", "normal", "background", "#ff0000") ; another way to define 'red'
  ;SetSkinProperty(skin2, "splitterex:blue", "normal", "background", "rgb(255, 0, 0)") ; another way to define 'red'
  ;SetSkinProperty(skin2, "splitterex:blue", "normal", "background", "rgba(255, 0, 0, 255)") ; another way to define 'red' with alpha
  
  SetSkinProperty(skin2, "splitterex:blue", "normal", "gripper size", "width: 15; height: 0") ; make this skin's gripper fill the height of the SplitterEx and make it fatter ;)
  SetSkinProperty(skin2, "splitterex:blue", "normal", "first padding", "right: 10") ; make padding at the left side of gripper more for this skin
  SetSkinProperty(skin2, "splitterex:blue", "normal", "second padding", "left: 10") ; make padding at the right side of gripper more for this skin
  SetSplitterExSkin(2, skin2, "", 0)
  
  
  HideWindow(#Window_0, 0)
  
EndProcedure

OpenWindow_0()
  
; main event loop
Repeat
  Event = WaitWindowEvent()
  Select Event
      
    ; handle gadget events
    Case #PB_Event_Gadget
      
      Select EventGadget()
        Case 0
          Debug 0
        Case 1
          If EventType() <> #EN_UPDATE ; filter out EditorGadget redraw notifications
            Debug 1
          EndIf
        Case 2
          Debug 2
      EndSelect
      
    ; resize SplitterEx when main window sized
    Case #PB_Event_SizeWindow
      
      MoveWindow_(SplitterExID(2),5,5,WindowWidth(0)-10,WindowHeight(0)-10, #True)
      
  EndSelect
Until Event = #PB_Event_CloseWindow
JustExit()
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 13
; FirstLine = 7
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = SplitterExample2(x64).exe