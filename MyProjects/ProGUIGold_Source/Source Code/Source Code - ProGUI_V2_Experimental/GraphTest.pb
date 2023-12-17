XIncludeFile "ProGUI.pb"
ProGUI_Init()

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  ;XIncludeFile "ProGUI_PB.pb"
CompilerEndIf

;#DEBUGENABLED = -1 ; -1 = enable debug
;XIncludeFile "debuglog.pb"

StartProGUI("", 0, 0, 0, 0, 0, 0, 0)

Global graph, graph2

;- Window Constants
#windowWidth = 1600
#windowHeight = 768

Enumeration
  #Window_0
EndEnumeration

Procedure testCallback(*value.double)
      
      value.d = *value\d
      
      If Abs(value) < 0.5
        b = 128 + 127 * Abs(value)
        col = MakeColour(255, 0, 0, b)
      Else
        r = 255 * Abs(value)
        col = MakeColour(255, r, 0, 0)
      EndIf
      ;col = MakeColour(255, 0, 255, 0)
      ProcedureReturn col
      
    EndProcedure

Procedure ProGUI_EventCallback(hwnd, message, wParam, lParam)
    
    Select message
            
        Case #WM_SIZE
            
            margin = 40
            ResizeGraph(graph, margin, margin, (WindowWidth(#Window_0)/2)-(margin*2), WindowHeight(#Window_0)-(margin*2), 0)
            ResizeGraph(graph2, (WindowWidth(#Window_0)/2), margin, (WindowWidth(#Window_0)/2)-(margin), WindowHeight(#Window_0)-(margin*2), 0)
            
    EndSelect
    
    ProcedureReturn #PB_ProcessPureBasicEvents
    
EndProcedure

Procedure Open_Window_0()
  
  SetUIColourMode(#UICOLOURMODE_DEFAULT_GREY)
  
  OpenWindow(#Window_0, 0, 0, #windowWidth, #windowHeight, "Test", #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_Invisible)
  
  LimitWindowSize(WindowID(#Window_0), 264, 200, 0, 0)
  
  ; *font.GL_Fonts = GL_LoadFont("Poo", 12, #Font_Cleartype)
    ; Debug *font
    ; Debug *font\Name
    ; Debug *font\PointSize
    ; Debug *font\Flags
    ; Debug "-----"
    ; Debug *font\HFONT[0]
    ; Debug *font\HFONT[1]
    ; 
    ; Debug "*****"
    ; Debug GL_Font(*font)
    
    graph = CreateGraph(WindowID(#Window_0), #ProGUI_Any, 10, 10, 500, 500)
    SetGraphTitle(graph, "Helloooooo!", MakeColor(255, 0, 0, 0), 0)
    ;SetGraphTitle(graph, "", MakeColor(255, 0, 0, 0), 0)
    SetGraphAxisRanges(graph, 0, 16, 0, 10, 0)
    ;* need to fix *
    ;SetGraphBorder(graph, 20, MakeColour(255, 255, 0, 0), 0)
    SetGraphAxisLabels(graph, "X Axis Test", "Y Axis Test", 0)
    ;SetGraphAxisLabelsFont(graph, "Verdana", 16, 0, 0)
    ;SetGraphAxisLabelsColour(graph, MakeColour(255, 255, 0, 0), 0)
    ;* need to fix
    ;SetGraphPadding(graph, 40, 10, 40, 0)
    
    ;SetGraphTickSize(graph, 8, 2, 40, 0)
    ;SetGraphGridlines(graph, #True, MakeColour(155, 0, 0, 255), 1, #True, MakeColour(65, 0, 0, 255), 1, #False, MakeColour(255, 0, 0, 255), 1, 0)
    ;SetGraphGridlines(graph, #True, MakeColour(155, 0, 0, 255), 10, #True, MakeColour(65, 0, 0, 255), 10, #False, MakeColour(255, 0, 0, 255), 1, 0)
    
    ;SetGraphTicks(graph, #False, 0)
    
    Dim ln.POINTD(7)
    ln(0)\x = 0 : ln(0)\y = 0
    ln(1)\x = 2 : ln(1)\y = 2
    ln(2)\x = 3 : ln(2)\y = 4
    ln(3)\x = 5 : ln(3)\y = 6
    ln(4)\x = 8 : ln(4)\y = 7
    ln(5)\x = 9 : ln(5)\y = 8
    ln(6)\x = 11 : ln(6)\y = 4
    AddGraphLine(graph, ln(), ArraySize(ln()), MakeColor(255, 0, 0, 255), 0, #GL_Line_Style_Dash, "This is a line", #GL_Line_Node_Dot, 0, 0, #True, #True, 0)
    
    Dim ln.POINTD(5)
    ln(0)\x = 1 : ln(0)\y = 0
    ln(1)\x = 2 : ln(1)\y = 1
    ln(2)\x = 3 : ln(2)\y = 2
    ln(3)\x = 4 : ln(3)\y = 3
    ln(4)\x = 5 : ln(4)\y = 7
    AddGraphLine(graph, ln(), ArraySize(ln()), MakeColor(155, 255, 0, 0), 0, 0, "Weeeee!", #GL_Line_Node_Diamond, 0, 0, #True, #False, 0)
    
    ln(0)\x = -5 : ln(0)\y = 2
    ln(1)\x = 2 : ln(1)\y = 4
    ln(2)\x = 3 : ln(2)\y = 6
    ln(3)\x = 4 : ln(3)\y = 8
    ln(4)\x = 5 : ln(4)\y = 14
    AddGraphLine(graph, ln(), ArraySize(ln()), MakeColor(255, 0, 100, 0), 0, 0, "Test line label", #GL_Line_Node_Star, 0, 0, #True, #False, 0)
    
    ;AddGraphRange(graph, 2, 8, 0, 10, MakeColour(100, 255, 0, 0), 1, "blah", 0)
    ;AddGraphRange(graph, 8, 14, 0, 10, MakeColour(100, 0, 255, 0), 1, "wah", 0)
    
    ln(0)\x = -8 : ln(0)\y = 1
    ln(1)\x = -7 : ln(1)\y = 2
    ln(2)\x = -8 : ln(2)\y = 3
    ln(3)\x = -6 : ln(3)\y = 4
    ln(4)\x = -7 : ln(4)\y = 5
    AddGraphLine(graph, ln(), ArraySize(ln()), MakeColor(255, 200, 0, 200), 1, 0, "grrrr", #GL_Line_Node_Cross, 0, #False, #True, #False, 0)
    
    ln(0)\x = -8 : ln(0)\y = -1
    ln(1)\x = -7 : ln(1)\y = -2
    ln(2)\x = -8 : ln(2)\y = -3
    ln(3)\x = -6 : ln(3)\y = -4
    ln(4)\x = -7 : ln(4)\y = -5
    AddGraphLine(graph, ln(), ArraySize(ln()), MakeColor(255, 155, 155, 0), 3, 0, "poo!", #GL_Line_Node_Triangle, 0, #False, #True, #False, 0)
    
    graph2 = CreateGraph(WindowID(#Window_0), #ProGUI_Any, 510, 10, 500, 500)
    SetGraphTitle(graph2, "Another Graph with Density Plot!", MakeColor(255, 0, 0, 0), 0)
    SetGraphAxisRanges(graph2, 0, 20, 0, 20, 0)
    ;* need to fix *
    ;SetGraphBorder(graph2, 20, MakeColour(255, 255, 0, 0), 0)
    SetGraphAxisLabels(graph2, "X Axis Test", "Y Axis Test", 0)
    ;SetGraphAxisLabelsFont(graph2, "Verdana", 16, 0, 0)
    ;SetGraphAxisLabelsColour(graph2, MakeColour(255, 255, 0, 0), 0)
    ;* need to fix
    ;SetGraphPadding(graph2, 40, 10, 40, 0)
    
    ;SetGraphTickSize(graph2, 8, 2, 80, 0)
    ;SetGraphGridlines(graph2, #False, MakeColour(155, 0, 0, 255), 2, #False, MakeColour(65, 0, 0, 255), 1, 0)
    ;SetGraphGridlines(graph2, #True, MakeColour(155, 0, 0, 255), 10, #True, MakeColour(65, 0, 0, 255), 10, 0)
    
    ;SetGraphTicks(graph2, #False, 0)
    
    sizex = 120
    sizey = 120
    
    Dim vals.d(sizex - 1, sizey - 1)
    
    For i = 0 To sizex - 1
      For j = 0 To sizey - 1
        vals(i, j) = Cos(i / 10) * Sin(j / 10) / Tan(i * j / 10000)
        If IsInfinity(vals(i, j))
          vals(i, j) = 0
        EndIf
        ;Debug(vals(i, j))
      Next
    Next
    
    ;density1 = AddGraphDensityPlot(graph2, 0, 20, 0, 20, vals(), ArraySize(vals(), 1), ArraySize(vals(), 2), MakeColour(255, 255, 0, 0), MakeColour(255, 0, 255, 0), "Density Plot", @testCallback(), 0)
    
    sizex = 60
    sizey = 20
    
    Dim vals.d(sizex - 1, sizey - 1)
    
    For i = 0 To sizex - 1
      For j = 0 To sizey - 1
        vals(i, j) = Cos(i / 10) * Sin(j / 10); / Tan(i * j / 10000)
        If IsInfinity(vals(i, j))
          vals(i, j) = 0
        EndIf
        ;Debug(vals(i, j))
      Next
    Next
    
    density2 = AddGraphDensityPlot(graph2, 0, 20, 0, 20, vals(), ArraySize(vals(), 1), ArraySize(vals(), 2), MakeColour(255, 0, 255, 0), MakeColour(255, 0, 0, 255), "Density Plot2", 0, 0)
    
    SetGraphDensityPlotGridlines(graph2, density1, #True, 1, MakeColour(255, 0, 0, 0), 0)
    
    ;SetGraphDensityPlotValueOptions(graph2, density2, #False, #True, 0)
    ;SetGraphDensityPlotValueOptions(graph2, density1, #True, #False, 0)
    
    Dim bar.GL_GraphBar(6)
    
    bar(0)\label = "Bar 1"
    bar(0)\colour = MakeColour(255, 0, 0, 255)
    bar(0)\minPos = 14
    bar(0)\maxPos = 14
    bar(0)\minValue = 0
    bar(0)\maxValue = 5
    
    bar(1)\label = "Bar 2"
    bar(1)\colour = MakeColour(255, 255, 0, 0)
    bar(1)\minPos = 16
    bar(1)\maxPos = 16
    bar(1)\minValue = 0
    bar(1)\maxValue = 8
    
    bar(2)\label = "Bar 3"
    bar(2)\colour = MakeColour(255, 0, 255, 0)
    bar(2)\minPos = 19;19
    bar(2)\maxPos = 19;19
    bar(2)\minValue = 0
    bar(2)\maxValue = 10
    
    bar(3)\label = "Bar 4"
    bar(3)\colour = MakeColour(255, 0, 255, 255)
    bar(3)\minPos = 22
    bar(3)\maxPos = 22
    bar(3)\minValue = 0
    bar(3)\maxValue = 12
    
    bar(4)\label = "Bar 5"
    bar(4)\colour = MakeColour(255, 255, 255, 0)
    bar(4)\minPos = 26
    bar(4)\maxPos = 26
    bar(4)\minValue = 0
    bar(4)\maxValue = 8
    
    bar(5)\label = "Bar 6"
    bar(5)\colour = MakeColour(255, 255, 0, 255)
    bar(5)\minPos = 28
    bar(5)\maxPos = 28
    bar(5)\minValue = 0
    bar(5)\maxValue = 5
    
    ;bars = AddGraphBars(graph, bar(), ArraySize(bar()), #False, 0)
    
    Dim bar.GL_GraphBar(3)
    
    bar(0)\label = "Bar 1"
    bar(0)\colour = MakeColour(255, 249, 205, 130)
    bar(0)\minPos = 8
    bar(0)\maxPos = 8
    bar(0)\minValue = 0
    bar(0)\maxValue = 5
    
    bar(1)\label = "Bar 2"
    bar(1)\colour = MakeColour(255, 145, 201, 216)
    bar(1)\minPos = 9
    bar(1)\maxPos = 9
    bar(1)\minValue = 0
    bar(1)\maxValue = 8
    
    bar(2)\label = "Bar 3"
    bar(2)\colour = MakeColour(255, 146, 177, 83)
    bar(2)\minPos = 10
    bar(2)\maxPos = 10
    bar(2)\minValue = 0
    bar(2)\maxValue = 10
    
    ;bars2 = AddGraphBars(graph, bar(), ArraySize(bar()), #True, 0)
    
    testFont = GL_LoadFont("Arial", 14, #Font_Bold)
    ;AddGraphFeatureLabel(graph, "This is a test feature", MakeColour(255, 255, 0, 0), testFont, 14, 12, 45, 0)
    ;AddGraphFeatureLabel(graph, "Another test feature label", MakeColour(255, 0, 0, 255), testFont, 0, 15, 0, 0)
    
    ;AddGraphRuler(graph, 6, 0, "Test ruler1", MakeColour(155, 255, 0, 0), 0, 1, 0, 0)
    ;AddGraphRuler(graph, 9, 0, "Test ruler2", MakeColour(155, 0, 0, 255), 0, 1, 0, 0)
    ;AddGraphRuler(graph, 4, 1, "Test ruler3", MakeColour(155, 0, 155, 0), 3, 3, 0, 0)
    
    
    Dim p.POINTD(7)
    p(0)\x = -14 : p(0)\y = 2
    p(1)\x = -12 : p(1)\y = 4
    p(2)\x = -11 : p(2)\y = 8
    p(3)\x = -7 : p(3)\y = 8
    p(4)\x = -3 : p(4)\y = 8
    p(5)\x = -2 : p(5)\y = 4
    p(6)\x = 0 : p(6)\y = 2
    
    ;AddGraphPolyRange(graph, "Poly Range", MakeColour(100, 255, 0, 0), p(), ArraySize(p()), 1, 5, 1, 1, 0)
  
  ; attach our events callback for processing Windows ProGUI messages
  SetWindowCallback(@ProGUI_EventCallback())
  
EndProcedure


Open_Window_0() ; create main window
HideWindow(0, 0)  ; show our newly created window




; enter main event loop
Repeat
  
  Event = WaitWindowEvent()
  
  If Event = #WM_KEYDOWN
    If EventwParam() = #VK_ESCAPE
      Break
    EndIf
    
    If EventwParam() = #VK_LEFT
      
      SetGraphScroll(graph, 1, 0, 0)
    ElseIf EventwParam() = #VK_RIGHT
      
      SetGraphScroll(graph, -1, 0, 0)
    EndIf
  EndIf
  
  
Until Event = #PB_Event_CloseWindow And EventWindow() = #Window_0

ProGUI_End()
End

; IDE Options = PureBasic 5.71 LTS (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableThread
; EnableXP
; Executable = GraphTest.exe
; DisableDebugger
; EnableUnicode