; Remember to enable XP Skin Support!
; Demonstrates how to use PannelEx's

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
  #Web
  #REBAR_0
EndEnumeration

Global Gradient

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  disabled.i
EndStructure
Global Dim image.images(36)

; load in some example icons
image(0)\normal = LoadImg("icons\image.ico", 16, 16, 0)
image(0)\hot = LoadImg("icons\image_h.ico", 16, 16, 0)
image(0)\disabled = LoadImg("icons\image_d.ico", 16, 16, 0)

image(1)\normal = LoadImg("icons\color.ico", 32, 32, 0)
image(1)\hot = LoadImg("icons\color_h.ico", 32, 32, 0)
image(1)\disabled = LoadImg("icons\color_d.ico", 32, 32, 0)

image(24)\normal = LoadImg("icons\test.jpg", 0, 0, 0)
image(25)\normal = LoadImg("icons\test.png", 0, 0, 0)

image(26)\normal = LoadImg("icons\border.png", 0, 0, 0)
image(26)\hot = LoadImg("icons\border_m.png", 0, 0, 0)

image(2)\normal = LoadImg("icons\newlogo2_256x256.png", 0, 0, 0)

; PanelEx user custom callback
Procedure myPanelCallback(window, message, wParam, lParam)

  Select message

    Case #WM_SIZE

      MoveWindow_(GadgetID(#Web), 0, 0, LWord(lParam), HWord(lParam), #False)

  EndSelect

  ProcedureReturn Result

EndProcedure

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
   
        ; handle page selection
        If MenuID = 1
          ShowPanelExPage(0, 0)
        ElseIf MenuID = 2
          ShowPanelExPage(0, 1)
        ElseIf MenuID = 3
          ShowPanelExPage(0, 2)
        ElseIf MenuID = 4
          ShowPanelExPage(0, 3)
        ElseIf MenuID = 5
          ShowPanelExPage(0, 4)
        ElseIf MenuID = 6
          ShowPanelExPage(0, 5)
        EndIf
        
        ; handle nested PanelEx background gradient colour change
        If MenuID = 31
          colour = ColorRequester()
          If colour <> -1
            SetGradientColour(Gradient, 0, MakeColour(50, Red(colour), Green(colour), Blue(colour)))
            SetGradientColour(Gradient, 1, MakeColour(255, Red(colour), Green(colour), Blue(colour)))
            SetPanelExPageBackground(1, 0, Gradient, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, 0)
          EndIf
        EndIf
      
        Debug MenuID
        
      EndIf
      
    ; resize panelex and textcontrolex when main window resized
    Case #WM_SIZE
      
      SendMessage_(PanelExID(0, -1), #WM_SETREDRAW, #False, 0)
      SetWindowPos_(PanelExID(0, -1), 0, 0, RebarHeight(#REBAR_0), WindowWidth(#Window_0), WindowHeight(#Window_0)-RebarHeight(#REBAR_0), #SWP_NOCOPYBITS|#SWP_NOREDRAW|#SWP_NOZORDER)
      SetWindowPos_(TextControlExID(28), 0, WindowWidth(#Window_0)-210, WindowHeight(#Window_0)-230, 0, 0, #SWP_NOCOPYBITS|#SWP_NOREDRAW|#SWP_NOZORDER|#SWP_NOSIZE)
      SendMessage_(PanelExID(0, -1), #WM_SETREDRAW, #True, 0)
      RedrawWindow_(PanelExID(0, -1),0,0,#RDW_NOERASE|#RDW_INVALIDATE|#RDW_UPDATENOW|#RDW_ALLCHILDREN)
      
    ; handle textcontrolex link hover
    Case #TCX_LINK_HOVER
    
      Debug "hover: "+Str(wParam)
      
    ; handle textcontrolex link click
    Case #TCX_LINK_CLICK
      
      Debug "click: "+Str(wParam)
 
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
  
  font = LoadFontEx("Verdana", 8, 0)
  SetTextControlExFont(-1, font, 0)
  
  OpenWindow(#Window_0, 50, 50, 600, 500, "PannelExExample 1", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  SetUIColourMode(#UICOLOURMODE_DEFAULT_GREY)
  
  ; main menu
  menu = CreateMenuEx(#MENU_0, WindowID(#Window_0), #UISTYLE_OFFICE2007)
  MenuTitleEx("&Select Page Here!")
  MenuItemEx(1, "Page &1$\bF1", image(0)\normal, 0, 0, 0)
  MenuItemEx(2, "Page &2$\bF2", image(0)\normal, 0, 0, 0)
  MenuItemEx(3, "Page &3$\bF3", image(0)\normal, 0, 0, 0)
  MenuItemEx(4, "Page &4$\bF4", image(0)\normal, 0, 0, 0)
  MenuItemEx(5, "Page &5$\bF5", image(0)\normal, 0, 0, 0)
  MenuItemEx(6, "Page &6$\bF6", image(0)\normal, 0, 0, 0)
  
  CreateRebar(#REBAR_0, WindowID(#Window_0), 0, #RBS_VARHEIGHT | #RBS_BANDBORDERS | #UISTYLE_OFFICE2007, 0)
  AddRebarGadget(menu, "", 0, 0, GetMenuExBarHeight(menu)-3, 0, #RBBS_BREAK|#RBBS_GRIPPERALWAYS|#RBBS_CHILDEDGE)
  
  ; creates a new pannelex
  CreatePanelEx(0, WindowID(#Window_0), 0, GetMenuExBarHeight(#MENU_0), 300, 300, @myPanelCallback())
  
  ; page 1
  window = AddPanelExImagePage(2, image(25)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  ; make the page scrollable
  SetPanelExPageScrolling(0, 0, #PNLX_AUTOSCROLL, #True)
  
  TextControlEx(PanelExID(0, 0), 28, 210, 250, 0, 0, "Try \uresizing\u the \bMain\b \l1982\b\c0000ffWindow!\n|\u\b\c0000ffWindow!\n\l", 0)
  
  ; page 2
  AddPanelExImagePage(0, image(24)\normal, 60, 70, 0, 0, #PNLX_MASKED)
  FrameGadget(#PB_Any, 80, 80, 100, 160, "Frame Label")
  ButtonGadget(0, 100, 100, 70, 30, "PB Button") 
  StringGadget(1, 100, 200, 70, 20, "String Gadget")

  ; page 3
  AddPanelExImagePage(7, image(25)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  FrameGadget(#PB_Any, 40, 90, 100, 60, "Frame Label")
  ButtonGadget(2, 210, 160, 70, 30, "PB Button") 
  StringGadget(3, 50, 120, 70, 20, "String Gadget")
  
  ; page 4
  window = AddPanelExImagePage(1, image(25)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  ButtonGadget(4, 180, 100, 100, 30, "PB Button") 
  StringGadget(5, 50, 200, 70, 20, "String Gadget")
  TextGadget(6, 180, 250, 110, 20, "Normal TextGadget")
  TextControlEx(window, 43, 180, 280, 0, 0, "\bTextControlEx\b no \uflickering!", 0)
  
  ; page 5
  window = AddPanelExPage(4)
  TextControlEx(window, 7, 130, 100, 0, 0, "This is some example text with colour escape code \c5050ffEffect\n", 0)
  
  ; page 6
  window = AddPanelExPage(-1)
  WebGadget(#Web,0,0,580,280,"http://www.progui.co.uk")
  
  ;/ creates a new pannelex inside page 1
  CreatePanelEx(1, PanelExID(0, 0), 10, 10, 260, 260, 0)
  
  ; page 1
  Gradient = CreateGradient(#VerticalGRADIENT, MakeColour(100, 100, 100, 100), MakeColour(255, 255, 200, 200))
  AddPanelExPage(Gradient)
  
  border.RECT
  border\left = 6
  border\right = 72
  border\top = 8
  border\bottom = 72
  SetPanelExPageBorder(1, 0, image(26)\normal, image(26)\hot, border, 0, -1)
  
  GetWindowRect_(PanelExID(1, 0), @rc.RECT)
  TextControlEx(PanelExID(1, 0), 123, 0, 0, rc\right-rc\left, (rc\bottom-rc\top)-100, "Complex \bEffects\b can be implemented\|easily with PanelEx's!\|\|This is a \l123\c0000ffPanelEx\n|\c0000ff\uPanelEx\n\l within a PanelEx!", #TCX_CENTRE|#TCX_VCENTRE)
  SetTextControlExPadding(123, 20, 10, 20, 10)
  
  ImageButtonEx(PanelExID(1, 0), 31, 110, 190, 0, 0, image(1)\normal, image(1)\hot, ImgBlend(image(1)\normal, 255, 0, 0, 0, 50, 0), image(1)\disabled)
  ButtonExToolTip(31, "Select PanelEx Gradient Colour...")
  
  ImageButtonEx(PanelExID(0, 0), 32, 280, 10, 0, 0, image(2)\normal, ImgBlend(image(2)\normal, 255, 20, 20, 0, 0, 0), ImgBlend(image(2)\normal, 255, 0, 0, 0, 50, 0), image(2)\normal)
  
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
    gadgetID = EventGadget()
    If gadgetID <> #web
      Debug gadgetID
    EndIf
  EndIf
  
Until Event = #PB_Event_CloseWindow
FreeGadget(#web) ; removes slight delay on close when using dll version
JustExit()

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 179
; FirstLine = 175
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = PanelExample(x64).exe