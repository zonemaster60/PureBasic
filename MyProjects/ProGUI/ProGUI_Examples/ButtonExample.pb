; Remember to enable XP Skin Support!
; Demonstrates how to use the ButtonEx controls and custom skin modification
Restart:
CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

;- Window Constants
Enumeration
  #Window_0
EndEnumeration

;- Menu/Button Command Constants
Enumeration
  #Command_Button1
  #Command_Button2
  #Command_Button3
  #Command_Button4
  #Command_Button5
  #Command_Button6
  #Command_Button7
  #Command_Button8
  #Command_Button9
  #Command_Button10
  #Command_Button11
  #Command_Button12
EndEnumeration

; set up structure for easy access to icon images
Structure images
  normal.i
  hot.i
  pressed.i
  disabled.i
EndStructure
Global Dim image.images(5)

; load in some example icons
image(0)\normal = LoadImg("icons\shell32_235.ico", 16, 16, 0)
image(0)\hot = ImgBlend(image(0)\normal, 255, 30, 0, 0, 0, 0)
image(0)\pressed = ImgBlend(image(0)\normal, 255, 0, -30, 0, 0, 0)
image(1)\normal = ImgBlend(LoadImg("icons\newlogo2_256x256.png", 256, 256, 0), 100, 0, 0, 0, 0, #ImgBlend_DestroyOriginal)
image(2)\normal = LoadImg("icons\dccmanager\downloadpanel_border.png", 0, 0, 0)
image(3)\normal = LoadImg("icons\advanced.ico", 32, 32, 0)
image(3)\hot = ImgBlend(image(3)\normal, 255, 30, 0, 0, 0, 0)
image(3)\pressed = ImgBlend(image(3)\normal, 255, 0, -30, 0, 0, 0)
image(4)\normal = LoadImg("icons\color.ico", 32, 32, 0)
image(4)\hot = ImgBlend(image(4)\normal, 255, 30, 0, 0, 0, 0)
image(4)\pressed = ImgBlend(image(4)\normal, 255, 0, -30, 0, 0, 0)

;- process ProGUI Windows event messages here
; events can also be simply captured using WaitWindowEvent() too in the main event loop, but for ease of porting the examples to other languages the callback method is used.
; #PB_Event_Menu and EventMenu() can be used to get the selected menu item when using the WaitWindowEvent() method.
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    ; handle selection of menu items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
          
        MenuID = LWord(wParam)
        
        ; tint the default button skin with a random colour!
        If MenuID = #Command_Button12
          
          r.s = Str(Random(255))
          g.s = Str(Random(255))
          b.s = Str(Random(255))
          skin = GetButtonExSkin(#Command_Button1)
          SetSkinProperty(skin, "buttonex", "normal", "overlay", "rgba("+r+","+g+","+b+", 80)")
          SetSkinProperty(skin, "buttonex", "hot", "overlay", "rgba("+r+","+g+","+b+", 80)")
          SetSkinProperty(skin, "buttonex", "pressed", "overlay", "rgba("+r+","+g+","+b+", 80)")
 
        ; debug output the button ID
        Else
        
          Debug MenuID
          
        EndIf
        
      EndIf
      
    ; resize panelex when main window resized
    Case #WM_SIZE
      
      MoveWindow_(PanelExID(0, -1), 0, 0, WindowWidth(#Window_0), WindowHeight(#Window_0), #True)
      
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
  
  OpenWindow(#Window_0, 50, 50, 700, 500, "Button Example: Resize the main window!", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ;- Create PanelEx as main window content
  CreatePanelEx(0, WindowID(#Window_0), 0, 0, WindowWidth(#Window_0), WindowHeight(#Window_0), 0)
  page = AddPanelExImagePage(2, image(1)\normal, 0, 0, 0, 0, #PNLX_CENTRE|#PNLX_VCENTRE)
  SetPanelExPageBorder(0, 0, image(2)\normal, -1, 0, 0, 0)
  SetPanelExPageScrolling(0, 0, #PNLX_AUTOSCROLL, #True)
  
  ;- Create a big button
  ButtonEx(page, #Command_Button1, 50, 50, 200, 100, "A Great Big Button!", 0, 0, 0, 0, 0)
  
  ;- Create a button with icon
  ButtonEx(page, #Command_Button2, 50, 160, 160, 32, "Button and Icon", image(0)\normal, image(0)\hot, image(0)\pressed, 0, 0)
  
  ;- Create a semi-transparent button!
  button = ButtonEx(page, #Command_Button3, 50, 202, 160, 60, "Semi-Transparent!", image(0)\normal, image(0)\hot, image(0)\pressed, 0, 0)
  ; Because the ButtonEx is really a subclassed PanelEx with user-callback
  ; we can use the normal PanelEx commands on it's handle and change the alpha transparency! :D
  SetPanelExPageAlpha(button, 0, 100, 0)
  
  ;- Create a button with modified skin
  ; copy system default skin of ButtonEx
  newSkin = CopySkin(GetButtonExSkin(#Command_Button1))
  ; make position of icon for normal state left aligned
  SetSkinProperty(newSkin, "buttonex", "normal", "image position", "x: 0; y: centre")
  ; add a background image for hot state
  SetSkinProperty(newSkin, "buttonex", "hot", "background image", "icons\stop.ico")
  ; make the background tile
  SetSkinProperty(newSkin, "buttonex", "hot", "background position", "tile: true")
  ; make text red for hot state and change font and make it bigger (with bold and strikethrough effect)
  SetSkinProperty(newSkin, "buttonex", "hot", "text", "colour: red; font: Verdana, 11, bold, strike")
  ; change mouse cursor for hot state
  SetSkinProperty(newSkin, "buttonex", "hot", "cursor", "hand")
  
  ButtonEx(page, #Command_Button4, 400, 50, 200, 64, "Modified Button Skin", image(0)\normal, image(0)\hot, image(0)\pressed, 0, newSkin)
  
  ;- Create a toggle button
  ToggleButtonEx(page, #Command_Button5, 50, 282, 160, 60, "Toggle Button", image(3)\normal, image(3)\hot, image(3)\pressed, image(4)\normal, image(4)\hot, image(4)\pressed, 0, 0)
  
  ;- Create a sticky toggle button
  ToggleButtonEx(page, #Command_Button6, 50, 352, 160, 60, "Sticky Toggle", image(3)\normal, image(3)\hot, image(3)\pressed, image(4)\normal, image(4)\hot, image(4)\pressed, 0, #BUTTONEX_STICKYSKIN)
  
  ;- Create check box button
  button = CheckButtonEx(page, #Command_Button7, 500, 150, 100, 20, "Check Box", 0)
  
  ;- Create some radio buttons
  RadioButtonEx(page, #Command_Button8, 500, 200, 120, 20, "Radio Button 1", 0)
  RadioButtonEx(page, #Command_Button9, 500, 230, 120, 20, "Radio Button 2", 0)
  RadioButtonEx(page, #Command_Button10, 500, 260, 120, 20, "Radio Button 3", 0)
  RadioButtonEx(page, #Command_Button11, 500, 290, 120, 20, "Radio Button 4", 0)
  
  ;- Create an image button that will tint the system default button skin with a random colour when clicked
  ImageButtonEx(page, #Command_Button12, 500, 360, 0, 0, image(4)\normal, image(4)\hot, image(4)\pressed, 0)
  ; create a nice tooltip for the image button
  ButtonExToolTip(#Command_Button12, "Tint the default button skin with a random colour!")
  
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
; CursorPosition = 4
; FirstLine = 109
; Folding = -
; EnableThread
; EnableXP
; EnableUser
; Executable = ButtonExample(x64).exe