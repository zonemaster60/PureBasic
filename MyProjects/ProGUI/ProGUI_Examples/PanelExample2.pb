; Remember to enable XP Skin Support!
; Demonstrates advanced PanelEx features

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  IncludeFile "ProGUI_PB.pb"
CompilerEndIf
StartProGUI("David Scouten", -1112319170, 1437701721, -1059401024, -275681315, 1580455855, 0, 0)

Prototype GdiAlphaBlend_(ddc, dx, dy, dwidth, dheight, sdc, sx, sy, swidth, sheight, BlendMode)
Global Gdi32 = OpenLibrary(#PB_Any, "Gdi32.dll") 
If Gdi32
  Global GdiAlphaBlend_.GdiAlphaBlend_ = GetFunction(Gdi32, "GdiAlphaBlend")
Else 
  MessageRequester("Error!","Can't open Gdi32.dll",#MB_ICONERROR) 
EndIf

Global animThread

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
Global Dim image.images(8)

; set up structure and global list for our star field
Structure stars
  x.f
  y.f
  xs.f ; x speed
  ys.f ; y speed
  mx.f ; max x speed
  my.f ; max y speed
  ac.f ; acceleration
  width.f
  mwidth.f ; width that the star grows to
  height.f
  mheight.f ; height that the star grows to
  alpha.f ; alpha transparency 0 - 255
  alphas.f ; stores alpha value
  image.i ; pointer to image DC
EndStructure
Global NewList star.stars()
#maxStars = 2000
#maxStarSize = 128
#minStarSize = 5
#maxStarSpeed = 20
#minStarSpeed = 0.1
#maxStarAcceleration = 5
#minStarAcceleration = 0.1

Global animMutex = CreateMutex()

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
image(5)\normal = LoadImg("icons\border.png", 0, 0, 0)
image(6)\normal = LoadImg("icons\star.png", 0, 0, 0)
image(6)\hot = LoadImg("icons\star2.png", 0, 0, 0)
image(6)\pressed = LoadImg("icons\star3.png", 0, 0, 0)
image(7)\normal = LoadImg("icons\stars.jpg", 0, 0, 0)

; load font
font = LoadFontEx("Verdana", 8, 0)
SetTextControlExFont(-1, font, 0) ; make this the default font for all TextControlEx's created after

Procedure convertImageFormat(Image.i, Mode.b) ; Mode = #True: PreMultiplyAlpha, Mode = -1: UnPreMultiplyAlpha
    
    If GetIconInfo_(Image, @iInfo.ICONINFO) <> 0
        Image = iInfo\hbmColor
        Mask = iInfo\hbmMask
    EndIf
    
    If Mask <> 0
        
        GetObject_(Mask, SizeOf(BITMAP), @BM.BITMAP)
        width = BM\bmWidth
        height = BM\bmHeight
        
        If width > 0 And height > 0
            
            maskbitcount = 32
            maskextrabytesperrow = (4 - (width * bitcount / 8) % 4) % 4
            sizeheaders = SizeOf(BITMAPFILEHEADER) + SizeOf(BITMAPINFOHEADER)
            sizeimage = (width * maskbitcount / 8 + maskextrabytesperrow) * height
            *mask = AllocateMemory(sizeheaders + sizeimage)
            
            *bitmapfile.BITMAPFILEHEADER = *mask
            *bitmapfile\bfType = Asc("B") + Asc("M") << 8
            *bitmapfile\bfSize = sizeheaders +sizeimage
            *bitmapfile\bfOffBits = sizeheaders
            *bitmapinfo.BITMAPINFOHEADER = *mask + SizeOf(BITMAPFILEHEADER)
            *bitmapinfo\biSize = SizeOf(BITMAPINFOHEADER)
            *bitmapinfo\biWidth = width
            *bitmapinfo\biHeight = height
            *bitmapinfo\biPlanes = 1
            *bitmapinfo\biBitCount = maskbitcount
            *bitmapinfo\biCompression = 0
            *bitmapinfo\biSizeImage = sizeimage
            
            *maskdata = *mask + sizeheaders
            
            *maskdatapos = *maskdata
            
            newImage = CreateImage(#PB_Any, width, height, 32)
            
            hdc = StartDrawing(ImageOutput(newImage))
            GetDIBits_(hdc, Mask, 0, height, *mask+sizeheaders, *bitmapinfo, #DIB_RGB_COLORS)
            StopDrawing()
            FreeImage(newImage)
        EndIf
        
    EndIf
    
    GetObject_(Image, SizeOf(BITMAP), @BM.BITMAP)
    width = BM\bmWidth
    height = BM\bmHeight
    
    If width > 0 And height > 0
        
        bitcount = BM\bmBitsPixel
        extrabytesperrow = (4 - (width * bitcount / 8) % 4) % 4
        sizeheaders = SizeOf(BITMAPFILEHEADER) + SizeOf(BITMAPINFOHEADER)
        sizeimage = (width * bitcount / 8 + extrabytesperrow) * height
        *bitmap = AllocateMemory(sizeheaders + sizeimage)
        
        *bitmapfile.BITMAPFILEHEADER = *bitmap
        *bitmapfile\bfType = Asc("B") + Asc("M") << 8
        *bitmapfile\bfSize = sizeheaders +sizeimage
        *bitmapfile\bfOffBits = sizeheaders
        *bitmapinfo.BITMAPINFOHEADER = *bitmap + SizeOf(BITMAPFILEHEADER)
        *bitmapinfo\biSize = SizeOf(BITMAPINFOHEADER)
        *bitmapinfo\biWidth = width
        *bitmapinfo\biHeight = height
        *bitmapinfo\biPlanes = 1
        *bitmapinfo\biBitCount = bitcount
        *bitmapinfo\biCompression = 0
        *bitmapinfo\biSizeImage = sizeimage
        
        *bitmapdata = *bitmap + sizeheaders
        
        *bitmapdatapos = *bitmapdata
        
        newImage = CreateImage(#PB_Any, width, height, 32)
        
        hdc = StartDrawing(ImageOutput(newImage))
        GetDIBits_(hdc, image, 0, height, *bitmap+sizeheaders, *bitmapinfo, #DIB_RGB_COLORS)
        DrawingMode(#PB_2DDrawing_AllChannels)
        
        For y = 0 To height - 1
            For x = 0 To width - 1
                
                bbyte.a = PeekB(*bitmapdatapos) ; Blue
                gbyte.a = PeekB(*bitmapdatapos + 1) ; Green
                rbyte.a = PeekB(*bitmapdatapos + 2) ; Red
                r = rbyte : g = gbyte : b = bbyte
                a.a = PeekB(*bitmapdatapos + 3)
                
                ; if 24bit image and no mask then set alpha to full
                If BM\bmBitsPixel = 24 And *mask = 0
                    a = 255
                EndIf
                
                If a = 0 And *mask <> 0
                    a = PeekB(*maskdatapos)
                    If a = 0
                        a = 255
                    Else
                        a = 0
                    EndIf
                EndIf
                
                ; PreMultiplyAlpha
                If Mode = #True
                    r = r & $FF * a &$FF / $FF
                    g = g & $FF * a &$FF / $FF
                    b = b & $FF * a &$FF / $FF
                    ; UnPreMultiplyAlpha
                ElseIf mode = -1
                    If a > 0
                        r = (r * 255 + a / 2) / a
                        g = (g * 255 + a / 2) / a
                        b = (b * 255 + a / 2) / a
                    Else
                        r = 255
                        g = 255
                        b = 255
                    EndIf
                EndIf
                
                Plot(x,(height-1)-y, RGBA(r, g, b, a))
                
                *bitmapdatapos + bitcount / 8
                If *mask <> 0
                    *maskdatapos + maskbitcount / 8
                EndIf
            Next
            *bitmapdatapos + extrabytesperrow
            If *mask <> 0
                *maskdatapos + maskextrabytesperrow
            EndIf
        Next
        
        StopDrawing()
        
        FreeMemory(*bitmap)
        If *mask <> 0
            FreeMemory(*mask)
        EndIf
        
        sdc = StartDrawing(ImageOutput(newImage))
        ddc = CreateCompatibleDC_(sdc)
        retval = CreateCompatibleBitmap_(sdc, ImageWidth(newImage), ImageHeight(newImage))
        old = SelectObject_(ddc, retval)
        BitBlt_(ddc, 0, 0, ImageWidth(newImage), ImageHeight(newImage), sdc, 0, 0, #SRCCOPY)
        SelectObject_(ddc, old)
        DeleteDC_(ddc)
        StopDrawing()
        
        FreeImage(newImage)
        
    EndIf
    
    If iInfo\hbmColor <> 0
        DeleteObject_(iInfo\hbmColor)
    EndIf
    
    If iInfo\hbmMask <> 0
        DeleteObject_(iInfo\hbmMask)
    EndIf
    
    ProcedureReturn retval
    
EndProcedure

img = convertImageFormat(image(6)\normal, #True)
dc = CreateCompatibleDC_(0)
SelectObject_(dc, img)
image(6)\normal = dc
img = convertImageFormat(image(6)\hot, #True)
dc = CreateCompatibleDC_(0)
SelectObject_(dc, img)
image(6)\hot = dc
img = convertImageFormat(image(6)\pressed, #True)
dc = CreateCompatibleDC_(0)
SelectObject_(dc, img)
image(6)\pressed = dc

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
          
;           r.s = Str(Random(255))
;           g.s = Str(Random(255))
;           b.s = Str(Random(255))
;           skin = GetButtonExSkin(#Command_Button1)
;           SetSkinProperty(skin, "buttonex", "normal", "overlay", "rgba("+r+","+g+","+b+", 80)")
;           SetSkinProperty(skin, "buttonex", "hot", "overlay", "rgba("+r+","+g+","+b+", 80)")
;           SetSkinProperty(skin, "buttonex", "pressed", "overlay", "rgba("+r+","+g+","+b+", 80)")
 
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

Procedure PanelExCallback(hwnd, message, wParam, lParam)
  
  Select message
      
    Case #WM_ERASEBKGND
      
      If TryLockMutex(animMutex)
        ForEach star()
          
          alpha.a = star()\alpha
          GdiAlphaBlend_(wParam, star()\x, star()\y, star()\width, star()\height, star()\image, 0, 0, #maxStarSize, #maxStarSize, $1000000 | alpha<<16)
          
        Next
        UnlockMutex(animMutex)
      EndIf
      
  EndSelect
  
EndProcedure

Procedure Animation(dummy)
  
  Repeat
    
    LockMutex(animMutex)
    If ListSize(star()) < #maxStars
      AddElement(star())
      image = Random(2)
      Select image
        Case 0
          star()\image = image(6)\normal
        Case 1
          star()\image = image(6)\hot
        Case 2
          star()\image = image(6)\pressed
      EndSelect
      size = #minStarSize+Random(5)
      star()\width = size
      star()\height = size
      msize = Random(#maxStarSize)
      star()\mwidth = msize
      star()\mheight = msize
      star()\x = (PanelExWidth(0)/2)-(star()\width/2)
      star()\y = (PanelExHeight(0)/2)-(star()\height/2)
      star()\ac = Random(#maxStarAcceleration)/100
      star()\alphas = 50 + Random(200)
      If star()\ac < #minStarAcceleration
        star()\ac = #minStarAcceleration
      EndIf
      If Random(1) = 0
        star()\mx = Random(#maxStarSpeed)/10
        If star()\mx < #minStarSpeed
          star()\mx = #minStarSpeed
        EndIf
      Else
        star()\mx = -Random(#maxStarSpeed)/10
        If star()\mx > -#minStarSpeed
          star()\mx = -#minStarSpeed
        EndIf
      EndIf
      If Random(1) = 0
        star()\my = Random(#maxStarSpeed)/10
        If star()\my < #minStarSpeed
          star()\my = #minStarSpeed
        EndIf
      Else
        star()\my = -Random(#maxStarSpeed)/10
        If star()\my > -#minStarSpeed
          star()\my = -#minStarSpeed
        EndIf
      EndIf
    EndIf
    
    ForEach star()
      
      If Sign(star()\mx) = 1
        If star()\xs < star()\mx
          star()\xs + star()\ac
        EndIf
      Else
        If star()\xs >= star()\mx
          star()\xs - star()\ac
        EndIf
      EndIf
      
      If Sign(star()\my) = 1
        If star()\ys <= star()\my
          star()\ys + star()\ac
        EndIf
      Else
        If star()\ys >= star()\my
          star()\ys - star()\ac
        EndIf
      EndIf
      
      If star()\width < star()\mwidth
        star()\width + star()\ac
      EndIf
      If star()\height < star()\mheight
        star()\height + star()\ac
      EndIf
      
      star()\x + star()\xs
      star()\y + star()\ys
      
      star()\alpha = ((star()\alphas/(star()\mwidth))*(star()\width+40))-50
      If star()\alpha > 255
        star()\alpha = 255
      ElseIf star()\alpha < 0
        star()\alpha = 0
      EndIf
      
      If star()\x + star()\width < 0
        DeleteElement(star())
        Continue
      ElseIf star()\x > PanelExWidth(0)
        DeleteElement(star())
        Continue
      EndIf
      If star()\y + star()\height < 0
        DeleteElement(star())
        Continue
      ElseIf star()\y > PanelExHeight(0)
        DeleteElement(star())
        Continue
      EndIf
      
    Next
    UnlockMutex(animMutex)
       
    ;SetWindowTitle(0, "Stars: "+Str(ListSize(star())))
    ;settextcontrolextext(0, "Stars: "+Str(ListSize(star())))
    ;RefreshPanelEx(0)
    RedrawWindow_(PanelExID(0, 0), 0, 0, #RDW_INVALIDATE|#RDW_UPDATENOW)
    Delay(30)
  ForEver
  
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
  
  OpenWindow(#Window_0, 50, 50, 700, 500, "Panel Example2: Advanced effects! Resize the main window!", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  ;- create PanelEx as main window content with our starfield user callback
  CreatePanelEx(0, WindowID(#Window_0), 0, 0, WindowWidth(#Window_0), WindowHeight(#Window_0), @PanelExCallback())
  Gradient = CreateGradient(#VerticalGRADIENT, MakeColour(155, 100, 100, 200), MakeColour(255, 0, 0, 50))
  ;Gradient = CreateGradient(#VerticalGRADIENT, RGBA(100, 100, 200, 155), RGBA(0, 0, 50, 255))
  ;Gradient = -1
  page = AddPanelExImagePage(-1, image(7)\normal, 0, 0, 0, 0, #PNLX_TILE)
  ;page = AddPanelExImagePage(Gradient, 0, 0, 0, 0, 0, #PNLX_TILE)
  SetPanelExPageBackground(0, 0, Gradient, image(1)\normal, 0, 0, 0, 0, #PNLX_OVERLAY|#PNLX_CENTRE|#PNLX_VCENTRE, 0)
  SetPanelExPageBorder(0, 0, image(2)\normal, -1, 0, 0, 0)
  SetPanelExPageScrolling(0, 0, #PNLX_AUTOSCROLL, #True)
  
;   xbar = CreateExplorerBar(page, 0, 400, 100, 200, 400, 0)
;   AddExplorerBarGroup("Group one")
;   ExplorerBarItem(0, "Kick Ass!")
;   ExplorerBarItem(1, "Good Eh?")
;   AddExplorerBarGroup("Group Two")
;   ExplorerBarItem(3, "Niiiiice!")
;   SetPanelExPageAlpha(xbar, 0, 100, 0)
  
  ;/ create a new PanelEx inside main PanelEx
  CreatePanelEx(1, PanelExID(0, 0), 10, 10, 300, 150, 0)
  Gradient2 = CreateGradient(#VerticalGRADIENT, MakeColour(155, 255, 255, 255), MakeColour(255, 200, 200, 200))
  page = AddPanelExPage(Gradient2)
  SetPanelExPageScrolling(1, 0, #PNLX_AUTOSCROLL, #True)
  SetPanelExPageBorder(1, 0, image(5)\normal, 0, 0, 0, -1)
  TextControlEx(page, 0, 20, 20, 0, 0, "Complex \beffects\b are created with ease!", 0)
  ButtonEx(page, 0, 20, 100, 100, 30, "Not bad eh?", 0, 0, 0, 0, 0)
  
  ; attach our events callback for processing Windows ProGUI messages
  SetWindowCallback(@ProGUI_EventCallback())
  
  animThread = CreateThread(@Animation(), 0)
  
EndProcedure

Open_Window_0() ; create window
HideWindow(0, 0)  ; show our newly created window

; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  
Until Event = #PB_Event_CloseWindow
KillThread(animThread)
JustExit()

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 513
; FirstLine = 499
; Folding = --
; EnableThread
; EnableXP
; EnableUser
; Executable = PanelExample2(x64).exe
; DisableDebugger