; Remember to enable XP Skin Support!

CompilerIf Defined(StartProGUI, #PB_Function) = #False
    ;IncludeFile "ProGUI_PB.pb"
CompilerEndIf
XIncludeFile "ProGUI.pb"

ProGUI_Init()
StartProGUI("", 0, 0, 0, 0, 0, 0, 0)


;- Window Constants
Enumeration
    #Window_0
EndEnumeration

;- Gadget Constants
Enumeration
    #PanelEx
    #PanelEx2
    #PanelEx3
    #PanelEx4
    #PanelEx5
    #PanelEx6
    #PanelExContainer
    #ExplorerBar
    #Button
    #Button2
    #Button3
    #Button4
    #Button5
    #Button6
    #Progress
    #Progress2
    #Container
    #Container2
    #String
    #Editor
    #Listview
    #Listicon
    #Tree
    #ExplorerCombo
    #Trackbar
    #DateGadget
    #Calender
    #Combobox
    #IPAddress
    #SpinGadget
    #CanvasGadget
    #OpenGL
    #WebGadget
EndEnumeration

; set up structure for easy access to icon images
Structure images
    normal.i
    hot.i
    disabled.i
EndStructure
Global Dim image.images(11)

; load in some example icons
image(0)\normal = LoadImg("icons\shell32_1007.ico", 16, 16, 0)
image(1)\normal = LoadImg("icons\shell32_271.ico", 16, 16, 0)
image(2)\normal = LoadImg("icons\shell32_22.ico", 16, 16, 0)
image(3)\normal = LoadImg("icons\shell32_18.ico", 16, 16, 0)
image(4)\normal = LoadImg("icons\shell32_235.ico", 16, 16, 0)
image(5)\normal = LoadImg("icons\shell32_4.ico", 16, 16, 0)
image(6)\normal = LoadImg("icons\shell32_4.ico", 96, 96, 0)
image(7)\normal = LoadImg("icons\background1.png", 0, 0, 0)
image(8)\normal = LoadImg("icons\downloadpanel_border.png", 0, 0, 0)
image(9)\normal = LoadImg("icons\border.png", 0, 0, 0)
image(10)\normal = LoadImg("icons\border_m.png", 0, 0, 0)

;- process ProGUI Windows event messages here
Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
    
    Select message
            
            ; resize panelex and textcontrolex when main window resized
        Case #WM_SIZE
           
            MoveWindow_(PanelExID(#PanelEx, -1), 5, 5, WindowWidth(#Window_0)-10, WindowHeight(#Window_0)-10, #False)
 
    EndSelect
    
    ProcedureReturn #PB_ProcessPureBasicEvents
    
EndProcedure

Structure testanim
    x.l
    y.l
    width.l
    height.l
    direction.b
EndStructure

Global sprite.testanim
sprite\width = 20
sprite\height = 20
sprite\y = 80

Procedure testCallback(hwnd, message, wParam, lParam)
    
    Select message
            
        Case #WM_ERASEBKGND
            
            brush = CreateSolidBrush_(RGB(255,0,0))
            rc.RECT
            rc\left = sprite\x
            rc\right = rc\left + sprite\width
            rc\top = sprite\y
            rc\bottom = rc\top + sprite\height
            FillRect_(wParam, rc, brush)
            DeleteObject_(brush)
            
    EndSelect
    
EndProcedure

Procedure animCallback(ID.i, animMessage.i, userid, *sprite.testanim)
    
    Select animMessage
    
        Case #ANIM_START
            
            
        Case #ANIM_UPDATE
            
            If *sprite\direction = 0
                *sprite\x + 1
            Else
                *sprite\x - 1
            EndIf
            
            If *sprite\x < 0
                *sprite\x = 0
                *sprite\direction = 0
            ElseIf *sprite\x + *sprite\width > PanelExWidth(#PanelEx5)
                *sprite\x = PanelExWidth(#PanelEx5) - *sprite\width
                *sprite\direction = 1
            EndIf
            
            ;StartDrawing(CanvasOutput(#CanvasGadget))
            ;Box(0, 0, 100, 100, RGB(Random(255), 0, 0))
            ;StopDrawing()
            
        Case #ANIM_RENDER
            
            RefreshPanelEx(#PanelEx5)
            
    EndSelect
            
EndProcedure

; creates a window
Procedure Open_Window_0()
    
    OpenWindow(#Window_0, 50, 50, 1200, 800, "ProGUI V2 test", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
    
    ; create PanelEx as main window content
    CreatePanelEx(#PanelEx, WindowID(#Window_0), 5, 5, 480, 490, 0)
    AddPanelExImagePage(#PanelEx, -1, image(7)\normal, 0, 0, 0, 0, #PNLX_TILE)
    SetPanelExPageBackground(#PanelEx, 0, -1, image(6)\normal, 0, 0, 0, 0, #PNLX_OVERLAY|#PNLX_CENTRE|#PNLX_VCENTRE, 0)
    SetPanelExPageBorder(#PanelEx, 0, image(8)\normal, -1, 0, 0, 0)
    SetPanelExPageScrolling(#PanelEx, 0, #PNLX_AUTOSCROLL, #True)
    
    x = 10
    y = 10
    ExplorerComboGadget(#ExplorerCombo, x, y, 200, 30, "C:/")
    
    TrackBarGadget(#Trackbar, x, y+40, 150, 30, 0, 10, #PB_TrackBar_Ticks) ; need to add exception to pattern hbrush to intercept wm_message and change dimensions to size of control
    
    DateGadget(#DateGadget, x, y+80, 200, 30)
    
    CalendarGadget(#Calender, x, y+120, 229, 164)

    ComboBoxGadget(#Combobox, x, y+294, 200, 30, #PB_ComboBox_Editable)
    AddGadgetItem(#Combobox, -1, "Test 1")
    AddGadgetItem(#Combobox, -1, "Test 2")
    AddGadgetItem(#Combobox, -1, "Test 3")
    SetGadgetState(#Combobox, 0)
    
    SpinGadget(#SpinGadget, x, y+334, 200, 30, 0, 100)
    
    CanvasGadget(#CanvasGadget, x, y+374, 200, 200)
    StartDrawing(CanvasOutput(#CanvasGadget))
    Box(0, 0, 100, 100, RGB(255, 0, 0))
    StopDrawing()
    
    ButtonGadget(#Button, x,y+584, 200, 200, "Test yay!")
    
    IPAddressGadget(#IPAddress,  x, 794, 200, 30)
    
    x = 300
    y = 10
    
    TextGadget(#PB_Any, x, y+150, 110, 20, "Normal TextGadget")
    
    HyperLinkGadget(28, x+150, 150, 220, 30, "This is a red hyperlink", RGB(255,0,0))
    
    SetGadgetFont(28, LoadFont(1, "courier", 10, #PB_Font_Underline | #PB_Font_Bold))
    
    StringGadget(#String, x, y+50, 130, 30, "Hello this is a string")
    
    EditorGadget(#Editor, x, y+200, 300, 200)
    SetGadgetText(#Editor, "This is an editor")
    
    ListViewGadget(#Listview, x+400, y+10, 300, 200, #PB_ListView_MultiSelect)
    For n = 0 To 30
       AddGadgetItem(#Listview, -1, "Test item " + Str(n))
    Next
   
    ListIconGadget(#Listicon, x+400, y+250, 300, 200, "Test column1", 100)
    AddGadgetColumn(#Listicon, 1, "Test column2", 100)
    AddGadgetColumn(#Listicon, 2, "Test column3", 100)
    For n = 0 To 30
        AddGadgetItem(#Listicon, -1, "Test item " + Str(n) + Chr(10) + "blaa " + Str(n) + Chr(10) + "Weee " + Str(n))
    Next
    
    TreeGadget(#Tree, x+400, y+490, 300, 200)
    For k=0 To 20
        AddGadgetItem(#Tree, -1, "Hello "+Str(k))
    Next
    
    ;WebGadget(#WebGadget, 10, 935, 800, 600, "www.progui.co.uk")
    
    x = 100
    y = 700
    ;ContainerGadget(#Container, 250, 450, 400, 400, #PB_Container_Raised) : container = GadgetID(#Container)
    
    ;CreatePanelEx(#PanelEx3, container, 50, 5, 300, 200, 0)
    CreatePanelEx(#PanelEx3, PanelExID(#PanelEx, 0), 250, 450, 400, 400, 0)
    AddPanelExPage(#PanelEx3, 4)
    SetPanelExPageBorder(#PanelEx3, 0, image(9)\normal, image(10)\normal, 0, 0, 0)
    SetPanelExPageScrolling(#PanelEx3, 0, #PNLX_AUTOSCROLL, #True)
    ;SetPanelExPageAlpha(#PanelEx3, 0, 100, 0)
    ButtonGadget(#Button2, 20, 20, 100, 20, "weeeee!")
    ButtonGadget(#Button5, 130, 20, 100, 20, "wooooo!")
    ProgressBarGadget(#Progress, 20, 60, 350, 30, 0, 100)
    SetGadgetState(#progress, 50)
    
    CreatePanelEx(#PanelEx4, PanelExID(#PanelEx3, 0), 55, 100, 250, 200, 0)
    AddPanelExPage(#PanelEx4, 6)
    SetPanelExPageScrolling(#PanelEx4, 0, #PNLX_AUTOSCROLL, #True)
    Debug "Panelex4: " + Str(PanelExID(#PanelEx4, -1))
    Debug "Panelex4Page: " + Str(PanelExID(#PanelEx4, 0))
    
    CheckButtonEx(PanelExID(#PanelEx4, 0), #Button3, 5, 5, 100, 30, "hello there!", 0)
    TextGadget(#PB_Any, 110, 5, 100, 30, "Blaa blaa blaa!")
    ProgressBarGadget(#Progress2, 20, 40, 350, 30, 0, 100)
    RadioButtonEx(PanelExID(#PanelEx4, 0), #Button6, 5, 300, 100, 30, "Testy ;)", 0)
     ContainerGadget(#Container2, 5, 80, 200, 200, #PB_Container_Double)
     ButtonGadget(#Button4, 20, 20, 100, 20, "Yo dude")
     TextGadget(#PB_Any, 20, 50, 100, 20, "Nice!")
     HyperLinkGadget(#PB_Any, 20, 80, 220, 30, "Blue hyperlink", RGB(0,0,255))
    SetGadgetFont(29, 1)
    
;     CreatePanelEx(#PanelEx6, PanelExID(#PanelEx, 0), 10, 235, 800, 600, 0)
;     AddPanelExPage(#PanelEx6, -1)
;     ;SetPanelExPageScrolling(#PanelEx6, 0, #PNLX_AUTOSCROLL, #True)
;     SetPanelExPageBorder(#PanelEx6, 0, image(9)\normal, image(10)\normal, 0, 0, 0)
;     WebGadget(#WebGadget, 0, 0, 800, 600, "www.progui.co.uk")
    
    x = 300
    y = 10
    CreatePanelEx(#PanelEx5, PanelExID(#PanelEx, 0), x+400, y+710, 200, 200, @testCallback())
    AddPanelExPage(#PanelEx5, 6)
    SetPanelExPageBorder(#PanelEx5, 0, image(9)\normal, image(10)\normal, 0, 0, 0)
    
    AnimStartEx(PanelExID(#PanelEx5, -1), 0, 60, 0, @animCallback(), 0, sprite)
    
    ; attach our events callback for processing Windows ProGUI messages
    SetWindowCallback(@ProGUI_EventCallback())
    
EndProcedure


Open_Window_0() ; create window
HideWindow(0, 0); show our newly created window

; enter main event loop
Repeat
    
    Event = WaitWindowEvent()
    
Until Event = #PB_Event_CloseWindow

ProGUI_End()
End
; IDE Options = PureBasic 5.72 (Windows - x86)
; CursorPosition = 260
; FirstLine = 230
; Folding = -
; EnableThread
; EnableXP
; Executable = DivertedRenderingExample.exe
; DisableDebugger
; EnableUnicode