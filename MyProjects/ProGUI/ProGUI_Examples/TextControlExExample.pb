; Remember to enable XP Skin Support!
; Demonstrates how to use TextControlEx's and various styles

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items
    Case #WM_COMMAND
      
      If Hword(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
      
        Debug MenuID ; display selected menu item
        
      EndIf
      
    ; resize panelex when main window resized
    Case #WM_SIZE
    
      SetWindowPos_(PanelExID(0, -1), 0, 0, 0, WindowWidth(#Window_0), WindowHeight(#Window_0), #SWP_NOCOPYBITS|#SWP_NOREDRAW|#SWP_NOOWNERZORDER)
      
    ; display a clicked link ID
    Case #TCX_LINK_CLICK
    
      Debug "Link "+Str(wParam)+" Clicked!"
      
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
  
  OpenWindow(#Window_0, 50, 50, 800, 500, "TextControlEx Example", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  font1 = LoadFontEx("Verdana", 10, 0)
  font2 = LoadFontEx("Arial", 12, #Font_Bold)
  setTextControlExFont(-1, font2, #True)
  setTextControlExColour(-1, 0, MakeRGB(180,180,255))
  
  img = LoadImg("icons\marble.png", 0, 0, 0)
  Gradient = CreateGradient(0, MakeColour(180, 150, 167, 255), MakeColour(10, 228, 226, 255))
  
  CreatePanelEx(0, WindowID(#Window_0), 0, 0, 800, 500, 0)
  AddPanelExImagePage(-1, img, 0, 0, 0, 0, #PNLX_TILE)
  SetPanelExPageBackground(0, 0, Gradient, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_OVERLAY, 0)
  
  RandomSeed(1337)
  TextControlEx(PanelExID(0,0), 0, Random(600), Random(300), 0, 0, "Bold text with coloured back fill and padding", #TCX_BK_FILL|#TCX_CENTRE)
  SetTextControlExPadding(0, 5, 5, 5, 5)
  SetTextControlExFont(-1, font1, #False)
  TextControlEx(PanelExID(0,0), 1, Random(600), Random(300), 0, 0, "Some normal example text", 0)
  SetTextControlExColour(-1, MakeRGB(255,0,0), 0)
  TextControlEx(PanelExID(0,0), 2, Random(600), Random(300), 0, 0, "Red example text", 0)
  SetTextControlExColour(-1, 0, 0)
  Gradient = CreateGradient(0, MakeColour(255, 255, 255, 0), MakeColour(0,0,0,255))
  SetTextControlExGradient(-1, Gradient)
  TextControlEx(PanelExID(0,0), 3, Random(600), Random(300), 0, 0, "Example text on alpha blend gradient background", #TCX_BK_GRADIENT)
  text.s = "This is a multi-line\|\bTextControlEx\b with a \l123\c0000ffHyper Link\n\l\|and another \l1234\c0000ffHyper Link with Underline Hover\n|\c0000ff\uHyper Link with Underline Hover\n\l and some more text!"
  TextControlEx(PanelExID(0,0), 4, Random(600), Random(300), 0, 0, text, 0)
  
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
; CursorPosition = 90
; FirstLine = 76
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = TextControlExExample(x64).exe