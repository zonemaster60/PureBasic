; Remember to enable XP Skin Support!
; Graph Library V1.00 by Chris Deeney 2013

CompilerIf Defined(StartProGUI, #PB_Function) = #False
  XIncludeFile "ProGUI_PB.pb"
CompilerEndIf

CompilerIf Defined(DEBUGENABLED, #PB_Constant) = #False
  #DEBUGENABLED = -1 ; -1 = enable debug
CompilerEndIf
XIncludeFile "debuglog.pb"

XIncludeFile "saveTIFF.pbi"

CompilerIf Defined(POINTF, #PB_Structure) = #False
Structure POINTF ; single precision point
  x.f
  y.f
EndStructure
CompilerEndIf

CompilerIf Defined(POINTD, #PB_Structure) = #False
Structure POINTD ; double precision point
  x.d
  y.d
EndStructure
CompilerEndIf

;- ----| Declarations
Declare GdipCalcTxt(dc, text.s, *width.integer, *height.integer, font)
Declare GdipRenderTxt(dc, x.f, y.f, text.s, ARGB, font, clipPath = #Null)
Declare GdipRenderTxtRotated(dc, x.f, y.f, text.s, ARGB, font, angle)
Declare drawLine(dc, x.f, y.f, x2.f, y2.f, thickness.f, ARGBColour, dashStyle = 0, highQuality = #True)
Declare drawHLine(dc, x.f, y.f, width.f, thickness.f, ARGBColour, AutoDPI = #False)
Declare drawHLineDashed(dc, x.f, y.f, width.f, thickness.f, ARGBColour, dashStyle = 1, AutoDPI = #False)
Declare drawVLine(dc, x.f, y.f, height.f, thickness.f, ARGBColour, AutoDPI = #False)
Declare drawVLineDashed(dc, x.f, y.f, height.f, thickness.f, ARGBColour, dashStyle = 1, AutoDPI = #False)
Declare drawLines(dc, *rc.RECT, Array points.POINTF(1), thickness.f, ARGB, dashStyle)
Declare drawNode(dc, x.f, y.f, nodeType, colour, size.f)
Declare drawNodes(dc, *rc.RECT, *line, Array points.POINTF(1))
Declare drawPolygon(dc, *rc.RECT, Array points.POINTF(1), fillColour.l, outlineColour.l, thickness.f, dashStyle.i, isfilled.b, isClosed.b, text.s, font)
Declare rectangle(dc, x.f, y.f, width.f, height.f, thickness.f, fillColour, outlineColour, outside.b)
Declare drawRectangle(dc, x.f, y.f, width.f, height.f, thickness.f, outlineColour, outside.b)
Declare fillRectangle(dc, x.f, y.f, width.f, height.f, fillColour)
Declare GdipRoundRect(dc, x, y, width, height, radious, thickness, fillColourARGB, outlineColourARGB)
Declare.s calcTxtProcisionSize(dc, value.d, width.i, font.i)

Declare RGBToHSV(color, *colorspace)
Declare.l RGB2HSL(*c)
Declare.l HSL2RGB(*c)

Declare.u GL_generateUniqueID_wordUnsigned()
Declare SetGraphDPI(GL_DPI_Constant)
Declare ShowErrorMsg(text.s, flags = 0)
Declare ShowWarningMsg(text.s, flags = 0)
Declare ShowQuestionMsg(text.s, flags = 0)
Declare GL_LoadFont(Name.s, PointSize.l, Flags.i)
Declare GL_FreeFont(*Handle)
Declare GL_Font(*Handle)
Declare getLoose_labelTicks(min.d, max.d, ntick.i)
Declare.s loose_label(min.d, max.d, ntick.i, index)
Declare RefreshGraph(id.i)
Declare updateGraphDragScrolling(*graph, hwnd, Started = #False)
Declare setGraphToolTip(*graph, text.s)
Declare setGraphToolTipXY(*graph, hwnd)
Declare setGraphToolTipXY2(*graph, hwnd, sx, sy, x, y)
Declare updateGraphDragZoomBox(*graph, hwnd, Started = #False)
Declare contextMenu(*graph, hwnd, x, y)
Declare openRangesWindow(*graph, x = 0, y = 0, width = 550, height = 230)
Declare.b IsNumericFloat(in_str.s)
Declare updateLegend(*graph)

DeclareDLL SetGraphAxisRanges(id.i, minX.d, maxX.d, minY.d, maxY.d, noRefresh.b)
DeclareDLL SaveGraph(id.i, savePath.s, GL_DPI_Constant)
DeclareDLL PrintGraph(id.i, GL_DPI_Constant)
DeclareDLL CopyGraphToClipboard(id.i, GL_DPI_Constant)

;-
;- ----| Macros
Macro MakeColour(a,r,g,b) ; Creates a Windows API compatible 32bit colour value with alpha channel.
  b|g<<8|r<<16|a<<24
EndMacro
Macro RGB(r,g,b) ; Creates an RGB colour
  r|g<<8|b<<16
EndMacro

Macro FastRGB(r, g, b)

  ; Faster equivalent of RGB(), although only suitable for integers

  (((r << 8 + g) << 8 ) + b)
 
EndMacro

Macro FastRed(color)
 
  ; Faster equivalent of Red(), although only suitable for integers

  ((color & $FF0000) >> 16)
 
EndMacro

Macro FastGreen(color)

  ; Faster equivalent of Green(), although only suitable for integers

  ((color & $FF00) >> 8)
 
EndMacro

Macro FastBlue(color)

  ; Faster equivalent of Blue(), although only suitable for integers

  (color & $FF)
 
EndMacro

Macro ReverseRGB(color)

  ; Changes RGB to BGR or vice versa

  ((color & $FF) << 16 | (color & $FF00) | (color & $FF0000) >> 16)
 
EndMacro

; detach the main PanelEx onto the desktop and resize off screen for high DPI printing
Macro GL_detachForHighDPI()
  
  graphHandle = GL_Graph()\Handle
  *graph.GL_Graphs = GL_Graph()
  parentHwnd = GetParent_(graphHandle)
  GetClientRect_(graphHandle, prc.RECT)
  MapWindowPoints_(graphHandle, parentHwnd, prc, 2)
  pxOffset = GL_Graph()\xOffset
  pyOffset = GL_Graph()\yOffset
  RefreshGraph(graphHandle)
  ShowWindow_(graphHandle, #SW_HIDE)
  ;SetPanelExPageBackground(GL_Graph()\Handle, 0, graphPrintBackground, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #True)
  SetGraphDPI(GL_DPI_Constant)
  SetWindowLongPtr_(graphHandle, #GWL_EXSTYLE, GetWindowLongPtr_(graphHandle, #GWL_EXSTYLE) | #WS_EX_TOOLWINDOW) ; make so that the PanelEx doesn't appear on the taskbar
  SetParent_(graphHandle, #Null) ; parent the main PanelEx to the desktop
  MoveWindow_(graphHandle, -(GL_Metric(GL_DPI)\printWidth+1000), -(GL_Metric(GL_DPI)\printHeight+1000), GL_Metric(GL_DPI)\printWidth, GL_Metric(GL_DPI)\printHeight, #True) ; +1000 = extra space added for positioning of window off screen, so as window border shadow isnt visible
  ShowWindow_(graphHandle, #SW_SHOW)
  *graph\xOffset = 0
  *graph\yOffset = 0
  RefreshGraph(graphHandle)
  SendMessage_(graphHandle, #WM_PAINT, 0, 0)
  
EndMacro

; re-attach main PanelEx onto main window
Macro GL_reattachForUI()
  
  ShowWindow_(graphHandle, #SW_HIDE)
  SetGraphDPI(#GL_DPI_Window)
  ;SetPanelExPageBackground(GL_Graph()\Handle, 0, 1, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, 0)
  SetParent_(graphHandle, parentHwnd)
  *graph\xOffset = pxOffset
  *graph\yOffset = pyOffset
  MoveWindow_(graphHandle, prc\left, prc\top, prc\right-prc\left, (prc\bottom-prc\top)-1, #False)
  MoveWindow_(graphHandle, prc\left, prc\top, prc\right-prc\left, prc\bottom-prc\top, #False)
  ShowWindow_(graphHandle, #SW_SHOW)
  
EndMacro

;-
;- ----| Constants

;- Default fonts
#GL_Default_font = "Arial"
#GL_Default_fontSize = 8

#GL_Default_titleFont = #GL_Default_font
#GL_Default_titleFontSize = 16
#GL_Default_titleColour = MakeColour(255, 0, 0, 0)

#GL_Default_axisLabelFont = #GL_Default_font
#GL_Default_axisLabelFontSize = 10
#GL_Default_axisLabelColour = MakeColour(255, 0, 0, 0)

#GL_Default_axisValueFont = #GL_Default_font
#GL_Default_axisValueFontSize = 8
#GL_Default_axisValueColour = MakeColour(255, 0, 0, 0)

#GL_Default_rangeFont = #GL_Default_font
#GL_Default_rangeFontSize = 26

#GL_Default_lineFont = #GL_Default_font
#GL_Default_lineFontSize = 12

#GL_Default_densityFont = #GL_Default_font
#GL_Default_densityFontSize = 6
#GL_Default_densityValueColour = MakeColour(255, 0, 0, 0)

#GL_Default_barFont = #GL_Default_font
#GL_Default_barFontSize = 16

#GL_Default_barValueFont = #GL_Default_font
#GL_Default_barValueFontSize = 8

#GL_Default_rulerFont = #GL_Default_font
#GL_Default_rulerFontSize = 12

#GL_Default_legendFont = #GL_Default_font
#GL_Default_legendFontSize = 10

;- Line style enumeration
Enumeration
  #GL_Line_Style_Solid
  #GL_Line_Style_Dash
  #GL_Line_Style_Dot
  #GL_Line_Style_DashDot
  #GL_Line_Style_DashDotDot
EndEnumeration

;- Line node type enumeration
Enumeration
  #GL_Line_Node_None
  #GL_Line_Node_Dot
  #GL_Line_Node_Circle
  #GL_Line_Node_Square
  #GL_Line_Node_SquareFilled
  #GL_Line_Node_Arrow
  #GL_Line_Node_Triangle
  #GL_Line_Node_TriangleFilled
  #GL_Line_Node_Diamond
  #GL_Line_Node_DiamondFilled
  #GL_Line_Node_Cross
  #GL_Line_Node_Star
EndEnumeration

;- Default settings
#GL_Default_padding = 60
#GL_Default_titlePadding = 10
#GL_Default_tickLength = 8
#GL_Default_tickWidth = 2
#GL_Default_tickSpacing = 40
#GL_Default_tickColour = MakeColour(255, 0, 0, 0)
#GL_Default_tickMinorColour = MakeColour(155, 0, 0, 0)
#GL_Default_tickMinorWidth = 1
#GL_Default_valuePadding = 6
#GL_Default_labelPadding = 10
#GL_Default_gridlineColour = MakeColour(255, 204, 204, 204)
#GL_Default_gridlineWidth = 1
#GL_Default_gridlineMinorColour = MakeColour(255, 234, 234, 234)
#GL_Default_gridlineMinorWidth = 1
#GL_Default_borderColour = MakeColour(255, 132, 132, 132)
#GL_Default_borderThickness = 2
#GL_Default_densityGridlineThickness = 1
#GL_Default_densityGridlineColour = MakeColour(255, 0, 0, 0)
#GL_Default_densityShowGridlines = #False
#GL_Default_densityShowValues = #True
#GL_Default_densityShowValuesOnHover = #True
#GL_Default_barWidth = 1
#GL_Default_showZeroAxis = 0;#True
#GL_Default_zeroAxisThickness = 1
#GL_Default_zeroAxisColour = MakeColour(255, 0, 0, 0)
#GL_Default_lineThickness = 2
#GL_Default_lineNodeType = #GL_Line_Node_Dot
#GL_Default_lineNodeSize = 8

#GL_ZoomFactor = 1.5
#GL_ZoomMaxFloatingPointPrecision = 4
#GL_ZoomBoxThickness = 1
#GL_ZoomBoxFillColour = MakeColour(35, 0, 0, 255)
#GL_ZoomBoxOutlineColour = MakeColour(200, 0, 0, 200)

;- Legend defaults
Enumeration
  #GL_Legend_Top
  #GL_Legend_Left
  #GL_Legend_Bottom
  #GL_Legend_Right
  #GL_Legend_Floating
EndEnumeration
#GL_Default_LegendOrientation = #GL_Legend_Top
#GL_Default_LegendKeyWidth = 30
#GL_Default_LegendPadding = 5
#GL_Default_LegendKeyPadding = 5
#GL_Default_LegendOutsidePadding = 10

;- Dialog gadget enumeration
Enumeration
  #GL_Ranges_String_Xmin
  #GL_Ranges_String_Xmax
  #GL_Ranges_String_Ymax
  #GL_Ranges_String_Ymin
  #GL_Ranges_Button_Apply
  #GL_Ranges_Button_Cancel
  #GL_Quality_Button_Okay
  #GL_Quality_Button_Cancel
  #GL_MaxGadgets
EndEnumeration

;- DPI constants
Enumeration 1
  #GL_DPI_Window ; default window editing DPI 96 (Windows standard)
  #GL_DPI_300
  #GL_DPI_600
  #GL_Max_DPI_Resolutions
EndEnumeration

#GL_PrintDPI = #GL_DPI_600

;-
;- ----| Structures

; hsv colour structure
Structure hsv
  h.f
  s.f
  v.f
EndStructure

; hsl colour structure
Structure hsl
  h.f
  s.f
  l.f
EndStructure

Enumeration
  ; do not change their order!
  #COLOR_RGB
  #COLOR_CMY
  #COLOR_HSV
  #COLOR_HSL
EndEnumeration

Structure Color
  StructureUnion
    r.f ; Red in RGB [0.0, 1.0]
    c.f ; Cyan in CMY [0.0, 1.0]
    h.f ; Hue in HSV/HSL [0.0, 360.0[
  EndStructureUnion
  StructureUnion
    g.f ; Green in RGB [0.0, 1.0]
    m.f ; Magenta in CMY [0.0, 1.0]
    s.f ; Saturation in HSV/HSL [0.0, 1.0]
  EndStructureUnion
  StructureUnion
    b.f ; Blue in RGB [0.0, 1.0]
    y.f ; Yellow in CMY [0.0, 1.0]
    v.f ; Value in HSV [0.0, 1.0]
    l.f ; Lightness in HSL [0.0, 1.0]
  EndStructureUnion
  type.l ; gives the type. One of #COLOR_RGB, #COLOR_CMY, #COLOR_HSV, #COLOR_HSL
EndStructure

;- Graph font DPI structures
Structure GL_Fonts
  Name.s
  PointSize.l
  Flags.i
  HFONT.i[#GL_Max_DPI_Resolutions]
EndStructure

;- Graph structures

Structure GL_GraphRanges
  xMin.d
  xMax.d
  yMin.d
  yMax.d
  colour.l
  label.s
  showBorder.b
EndStructure

Structure GL_GraphPolyRanges
  label.s
  colour.l
  thickness.i
  dashStyle.i
  isClosed.b
  isFilled.b
  Array pnt.POINTD(1)
EndStructure

Structure GL_GraphBar
  minValue.d
  maxValue.d
  minPos.d
  maxPos.d
  colour.l
  label.s
  rcf.RECTF ; stores calculated position and dimensions of bar in pixels
EndStructure

Structure GL_GraphBars
  isHorizontal.b
  Array bar.GL_GraphBar(1)
EndStructure

Structure GL_GraphDensityPlotValueCache
  value.s
  xRatio.i
EndStructure

Structure GL_GraphDensityPlots
  xMin.d
  xMax.d
  yMin.d
  yMax.d
  Array plot.d(1, 1)
  Array plotCache.GL_GraphDensityPlotValueCache(1, 1)
  minValue.d ; stores minimum detected value in passed array (pre-calced)
  maxValue.d ; stores maximum detected value in passed array (pre-calced)
  minColour.l
  maxColour.l
  label.s
  showValues.b
  showValuesOnHover.b
  showGridlines.b
  gridlineWidth.i
  gridlineColour.l
  valueFont.i
  valueColour.l
  *callback
EndStructure
  
Structure GL_GraphLines
  List pnt.POINTD()
  colour.l
  label.s
  thickness.i
  style.i
  nodeType.i
  nodeSize.i
  noLines.b ; if set to true, no rendering of lines i.e scatter graph
  showOnLegend.b
  showFloatingLabel.b
EndStructure

Structure GL_GraphLineLabels ; structure used for temp storage of line labels
  x.f
  y.f
  width.f
  height.f
  label.s
  colour.l
EndStructure

Structure GL_LabelFeatures
  x.f
  y.f
  angle.f
  label.s
  colour.l
  font.i
EndStructure

Structure GL_Rulers
  label.s
  isHorizontal.b
  position.d
  colour.l
  thickness.i
  style.i
  font.i
EndStructure

Structure GL_Dialogs
  PBWindowID.i
  gadget.i[#GL_MaxGadgets]
  Array dynamic.i(1) ; used for storing handles to gadgets created dynamically
  command.i ; used for storing extra state info
EndStructure

Structure GL_Graphs
  
  id.i
  handle.i
  contentHandle.i ; child PanelEx that contains main rendering of lines, ranges etc..
  
  padding.i
  valuePadding.i
  showTicks.b
  tickLength.i
  tickWidth.i
  tickSpacing.i
  tickColour.l
  tickMinorColour.l
  tickMinorWidth.i
  oxAxisMin.d ; original user set axis range values
  oyAxisMin.d
  oxAxisMax.d
  oyAxisMax.d
  xAxisMin.d ; current working axis range values
  yAxisMin.d
  xAxisMax.d
  yAxisMax.d
  cxAxisMin.d ; loose label calculated axis range values
  cyAxisMin.d
  cxAxisMax.d
  cyAxisMax.d
  nTicks.i  ; stores number of ticks
  title.s ; title of the graph
  titleFont.i ; handle to the GL_Font
  titlePadding.i
  titleColour.l
  xAxisLabel.s
  yAxisLabel.s
  axisLabelFont.i ; handle to the GL_Font
  axisLabelColour.l
  axisValueFont.i ; handle to the GL_Font
  axisValueColour.l
  labelPadding.i
  borderThickness.l
  borderColour.l
  gridlines.b ; flags whether to show gridlines
  gridlineColour.l
  gridlineWidth.i
  gridlinesMinor.b ; flags whether to show minor gridlines
  gridlineMinorColour.l
  gridlineMinorWidth.l
  rangeFont.i ; handle to the GL_Font
  lineFont.i ; handle to the GL_Font
  barFont.i ; handle to the GL_Font
  barValueFont.i ; handle to the GL_Font
  showZeroAxisLines.b
  zeroAxisThickness.l
  zeroAxisColour.l
  
  ; tooltip
  tooltipHWND.i
  
  ; scrolling and zooming
  xOffset.i
  yOffset.i
  zoomBox.b ; set to true if zoom box should be rendered
  zoomBoxStartX.i
  zoomBoxStartY.i
  zoomBoxX.i
  zoomBoxY.i
  
  ; legend
  legendHandle.i ; handle to the legend panelex
  legendOrientation.i ; where the legend is displayed
  legendKeyWidth.i
  legendFont.i ; handle to the GL_Font
  lWidth.i ; last legend width
  lHeight.i ; last legend height
  
  ; dialogue window handles and gadgets
  dialog_Ranges.GL_Dialogs
  dialog_Quality.GL_Dialogs
  
  ; graph elements
  List range.GL_GraphRanges()
  List prange.GL_GraphPolyRanges()
  List line.GL_GraphLines()
  List density.GL_GraphDensityPlots()
  List bars.GL_GraphBars()
  List label.GL_LabelFeatures()
  List ruler.GL_Rulers()
  
EndStructure

;- DPI printing metrics

Structure GL_DPIMetrics
  
  DPI.i ; dots per inch for this metric
  DPI_Ratio.d ; ratio used for resizing certain elements based on standard OS 96 dpi
  
  printWidth.i
  printHeight.i
  
  qualityDescription.s
  
EndStructure

;-
;- ----| Globals

;- load mouse pointers
Global GL_normalMousePointer = LoadCursor_(0, #IDC_ARROW)
Global GL_waitMousePointer = LoadCursor_(0, #IDC_WAIT)

;- Graph globals

Global GL_graphMutex = CreateMutex()
Global GraphMouseHook ; used for hooking WH_GETMESSAGE in order to pass WM_MOUSEWHEEL to graph callbacks when hovering over

;- Context menu globals
Global GL_ContextMenu ; handle used for right click context menu
Global GL_ContextMenuOpen ; set to true if the menu is open
Global GL_ContextMenuHwnd
Global GL_Command_Reset = GL_generateUniqueID_wordUnsigned()
Global GL_Command_SetRanges = GL_generateUniqueID_wordUnsigned()
Global GL_Command_Copy = GL_generateUniqueID_wordUnsigned()
Global GL_Command_Save = GL_generateUniqueID_wordUnsigned()
Global GL_Command_Print = GL_generateUniqueID_wordUnsigned()
Global GL_Command_ZoomIn = GL_generateUniqueID_wordUnsigned()
Global GL_Command_ZoomOut = GL_generateUniqueID_wordUnsigned()
Global GL_Command_densityShowValues = GL_generateUniqueID_wordUnsigned()

Global NewList GL_Graph.GL_Graphs()

;- DPI printing globals

Global GL_DPI = #GL_DPI_Window ; stores the current DPI setting for rendering
Global GL_DefaultPrintDPI = #GL_DPI_Window
Global Dim GL_Metric.GL_DPIMetrics(#GL_Max_DPI_Resolutions) ; global array of DPI metrics
Global NewList GL_Fonts.GL_Fonts() ; global list of font DPI objects

;-
;- ----| Setup DPI metrics
;  72 dpi (web) = 595 X 842 pixels
;  96 dpi (Windows OS) = 797 X 1123 pixels ("A4")
;  300 dpi (print) = 2480 X 3508 pixels (This is "A4" As I know it, i.e. "210mm X 297mm @ 300 dpi")
;  600 dpi (print) = 4960 X 7016 pixels

; window editing metrics
GL_Metric(#GL_DPI_Window)\DPI = 96
GL_Metric(#GL_DPI_Window)\DPI_Ratio = 1.0
GL_Metric(#GL_DPI_Window)\printWidth = 1123
GL_Metric(#GL_DPI_Window)\printHeight = 797
GL_Metric(#GL_DPI_Window)\qualityDescription = "draft"

; 300 DPI metrics
GL_Metric(#GL_DPI_300)\DPI = 300
GL_Metric(#GL_DPI_300)\DPI_Ratio = 3.125
GL_Metric(#GL_DPI_300)\printWidth = 3508-110 ; -110 = solves right margin clipping on printer
GL_Metric(#GL_DPI_300)\printHeight =  2480-110; -110 = solves bottom margin clipping on printer
GL_Metric(#GL_DPI_300)\qualityDescription = "high"

; 600 DPI metrics
GL_Metric(#GL_DPI_600)\DPI = 600
GL_Metric(#GL_DPI_600)\DPI_Ratio = 6.2475
GL_Metric(#GL_DPI_600)\printWidth = 7016-110 ; -110 = solves right margin clipping on printer
GL_Metric(#GL_DPI_600)\printHeight =  4960-110; -110 = solves bottom margin clipping on printer
GL_Metric(#GL_DPI_600)\qualityDescription = "very high"

;- Fonts
Global GL_Default_font = GL_LoadFont(#GL_Default_font, #GL_Default_fontSize, 0) ; internal default GL_Font
Global GL_Default_TitleFont = GL_LoadFont(#GL_Default_titleFont, #GL_Default_titleFontSize, #Font_Bold)
Global GL_Default_axisLabelFont = GL_LoadFont(#GL_Default_axisLabelFont, #GL_Default_axisLabelFontSize, 0)
Global GL_Default_axisValueFont = GL_LoadFont(#GL_Default_axisValueFont, #GL_Default_axisValueFontSize, 0)
Global GL_Default_rangeFont = GL_LoadFont(#GL_Default_rangeFont, #GL_Default_rangeFontSize, #Font_Bold)
Global GL_Default_lineFont = GL_LoadFont(#GL_Default_lineFont, #GL_Default_lineFontSize, #Font_Bold)
Global GL_Default_densityFont = GL_LoadFont(#GL_Default_densityFont, #GL_Default_densityFontSize, 0)
Global GL_Default_barFont = GL_LoadFont(#GL_Default_barFont, #GL_Default_barFontSize, #Font_Bold)
Global GL_Default_barValueFont = GL_LoadFont(#GL_Default_barValueFont, #GL_Default_barValueFontSize, #Font_Bold)
Global GL_Default_rulerFont = GL_LoadFont(#GL_Default_rulerFont, #GL_Default_rulerFontSize, #Font_Bold)
Global GL_Default_legendFont = GL_LoadFont(#GL_Default_legendFont, #GL_Default_legendFontSize, 0)

;-
;- ----| Callbacks / Hooks
;-

Procedure processMenuMessages(*graph.GL_Graphs, hwnd, message, wParam, lParam)
  
  Select message
      
      ; handle selection of menu items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
        
        MenuID = LWord(wParam)
        
        Select MenuID
            
          Case GL_Command_Reset
            
            SetGraphAxisRanges(*graph\handle, *graph\oxAxisMin, *graph\oxAxisMax, *graph\oyAxisMin, *graph\oyAxisMax, 0)
            
          Case GL_Command_SetRanges
            
            openRangesWindow(*graph)
            
          Case GL_Command_Copy
            
            CopyGraphToClipboard(*graph\handle, 0)
            
          Case GL_Command_Save
            
            SaveGraph(*graph\handle, "", 0)
            
          Case GL_Command_Print
            
            PrintGraph(*graph\handle, 0)
            
          Case GL_Command_ZoomOut
            
            zoom.d = #GL_ZoomFactor
        
            ; if zoomed beyond max 
            If *graph\cxAxisMax > Pow(2, 52) Or *graph\cyAxisMax > Pow(2, 52)
              ProcedureReturn #False
            EndIf
            
            GetClientRect_(hwnd, rc.RECT)
            grwidth = rc\right
            grheight = rc\bottom
            p.POINT
            p\x = grwidth/2
            p\y = grheight/2
            ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
            pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
            ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
            pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
            
            *graph\xAxisMin = ((*graph\xAxisMin-pointx)*zoom)+pointx
            *graph\xAxisMax = ((*graph\xAxisMax-pointx)*zoom)+pointx
            
            *graph\yAxisMin = ((*graph\yAxisMin-pointy)*zoom)+pointy
            *graph\yAxisMax = ((*graph\yAxisMax-pointy)*zoom)+pointy
            
            
            ; calc axis ticks
            tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
            xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
            yticks = Round(grheight/tickSpacing, #PB_Round_Down)
            oxticks = xticks
            oyticks = yticks
            xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
            yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
            
            txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
            *graph\cxAxisMin = ValD(txt)
            If xticks <= 1
              txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
            Else
              txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
            EndIf
            *graph\cxAxisMax = ValD(txt)
            txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
            *graph\cyAxisMin = ValD(txt)
            If yticks <= 1
              txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
            Else
              txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
            EndIf
            *graph\cyAxisMax = ValD(txt)
            
            ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
            npointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
    
            ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
            npointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
            
            rx.d = Round((pointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
            ry.d = Round((pointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
            
            rx2.d = Round((npointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
            ry2.d = Round((npointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
            
            *graph\xOffset - (rx-rx2)
            *graph\yOffset + (ry-ry2)
            
            setGraphToolTipXY(*graph, hwnd)
            
            RefreshGraph(*graph\handle)
            
          Case GL_Command_ZoomIn
            
            zoom.d = #GL_ZoomFactor
        
            ; if zoomed beyond max floating point precision then exit
            If Len(StringField(StrD(*graph\cxAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision
              ProcedureReturn #False
            EndIf
            
            GetClientRect_(hwnd, rc.RECT)
            grwidth = rc\right
            grheight = rc\bottom
            p.POINT
            p\x = grwidth/2
            p\y = grheight/2
            ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
            pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
            ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
            pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
            
            txMin.d = *graph\xAxisMin
            txMax.d = *graph\xAxisMax
            tyMin.d = *graph\yAxisMin
            tyMax.d = *graph\yAxisMax
            
            *graph\xAxisMin = ((*graph\xAxisMin-pointx)/zoom)+pointx
            *graph\xAxisMax = ((*graph\xAxisMax-pointx)/zoom)+pointx
            
            *graph\yAxisMin = ((*graph\yAxisMin-pointy)/zoom)+pointy
            *graph\yAxisMax = ((*graph\yAxisMax-pointy)/zoom)+pointy
            
            ; calc axis ticks
            tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
            xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
            yticks = Round(grheight/tickSpacing, #PB_Round_Down)
            oxticks = xticks
            oyticks = yticks
            xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
            yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
            
            txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
            *graph\cxAxisMin = ValD(txt)
            If xticks <= 1
              txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
            Else
              txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
            EndIf
            *graph\cxAxisMax = ValD(txt)
            txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
            *graph\cyAxisMin = ValD(txt)
            If yticks <= 1
              txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
            Else
              txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
            EndIf
            *graph\cyAxisMax = ValD(txt)
            
            If Len(StringField(StrD(*graph\cxAxisMin), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cxAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMin), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision
              *graph\xAxisMin = txMin
              *graph\xAxisMax = txMax
              *graph\yAxisMin = tyMin
              *graph\yAxisMax = tyMax
              ProcedureReturn #False
            EndIf
              
            ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
            npointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
    
            ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
            npointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
            
            rx.d = Round((pointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
            ry.d = Round((pointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
            
            rx2.d = Round((npointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
            ry2.d = Round((npointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
            
            *graph\xOffset - (rx-rx2)
            *graph\yOffset + (ry-ry2)
            
            setGraphToolTipXY(*graph, hwnd)
            
            RefreshGraph(*graph\handle)
            
        EndSelect
        
      EndIf
      
  EndSelect
  
  
EndProcedure

; used for injecting WM_MOUSEWHEEL msg into graph content window when hovering over instead of having to have focus
Procedure GraphMouseInputHook(nCode.i, wParam, lParam)
  
  If nCode >= 0
    
    *msg.MSG = lParam
    
    If *msg\message = #WM_MOUSEWHEEL Or *msg\message = #WM_MOUSEHWHEEL
      
      GetCursorPos_(p.POINT)
      hwnd = WindowFromPoint_(PeekQ(p))
      If *msg\hwnd <> hwnd And GetCapture_() = #Null
        GetWindowThreadProcessId_(hwnd, @processID)
        If processID = GetCurrentProcessId_()
          
          *msg\hwnd = hwnd
          
        EndIf
      EndIf
        
    EndIf
    
  EndIf
  
  ProcedureReturn CallNextHookEx_(GraphMouseHook, nCode, wParam, lParam)
  
EndProcedure

Procedure GraphCallback(hwnd, message, wParam, lParam)
  Static lytickspacing, lxtickspacing
  
  *graph.GL_Graphs = GetWindowLongPtr_(hwnd, #GWL_USERDATA)
  If *graph = #Null
    *graph.GL_Graphs = GetWindowLongPtr_(GetParent_(hwnd), #GWL_USERDATA)
  EndIf
  
  If *graph = #Null
    ProcedureReturn #False
  EndIf
  
  Select message
      
    ; handle right click context menu
    Case #WM_RBUTTONUP
      
      If *graph\handle = GetParent_(hwnd)
        
        GetCursorPos_(p.POINT)
        contextMenu(*graph, hwnd, p\x, p\y)
        
      EndIf
      
    Case #WM_COMMAND
      
      processMenuMessages(*graph, hwnd, message, wParam, lParam)  
      
    Case #WM_MOUSEMOVE
      
      GL_ContextMenuHwnd = 0 ; hack to stop menu from appearing twice if mouse is over parent panelex when deselected, fucking dodgy windows
      
      If *graph\contentHandle = GetParent_(hwnd) And wParam & #MK_LBUTTON
        
        updateGraphDragScrolling(*graph, hwnd)
        updateGraphDragZoomBox(*graph, hwnd)
        
      EndIf
      
    ; handle scrollling of graph, left click release
    Case #WM_LBUTTONUP
      
      If *graph\contentHandle = GetParent_(hwnd)
        
        updateGraphDragScrolling(*graph, hwnd, -1)
        updateGraphDragZoomBox(*graph, hwnd, -1)
        
      EndIf
    
    ; intercept max window size and alter so high DPI printing is possible  
    Case #WM_GETMINMAXINFO
      
      *pmmi.MINMAXINFO = lParam
      If *pmmi\ptMaxTrackSize\x < GL_Metric(GL_DPI)\printWidth
        *pmmi\ptMaxTrackSize\x = GL_Metric(GL_DPI)\printWidth
      EndIf
      If *pmmi\ptMaxTrackSize\y < GL_Metric(GL_DPI)\printHeight
        *pmmi\ptMaxTrackSize\y = GL_Metric(GL_DPI)\printHeight
      EndIf  
      
    Case #WM_SIZE
      
      GetClientRect_(hwnd, rc.RECT)
      padding = GL_Metric(GL_DPI)\DPI_Ratio**graph\padding
      grx = padding
      gry = padding
      grwidth = rc\right-(padding*2)
      grheight = rc\bottom-(padding*2)
      
      wParam = GetDC_(hwnd)
      
      ; calc extra height needed for title
      If *graph\title <> ""
        GdipCalcTxt(wParam, *graph\title, @txtWidth, @txtHeight, *graph\titleFont)
        tpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\titlePadding
        gry + (tpadding*2)
        grheight - (tpadding*2)
      EndIf
 
      ; calc graph x axis label height
      If *graph\xAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\xAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        tx = (rc\right/2)-(txtWidth/2)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        grheight - (txtHeight+(lpadding*2))
        
      EndIf
      
      ; calc graph y axis label width
      If *graph\yAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\yAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        grx + (txtHeight+(lpadding*2))
        grwidth - (txtHeight+(lpadding*2))
        
      EndIf
      
      ReleaseDC_(hwnd, wParam)
      
      If *graph\legendOrientation = #GL_Legend_Top
        GetClientRect_(*graph\legendHandle, lrc.RECT)
        If *graph\title <> ""
          gry + (lrc\bottom-lrc\top)-tpadding
          grheight - (lrc\bottom-lrc\top)+tpadding
        Else
          extra = padding-(lrc\bottom-lrc\top)
          extra - (GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendOutsidePadding)
          If extra < 0
            gry - extra
            grheight + extra
          EndIf
        EndIf
      EndIf
      
      MoveWindow_(*graph\contentHandle, grx, gry, grwidth, grheight, #False)
      
    Case #WM_PAINT
      
      GetClientRect_(hwnd, rc.RECT)
      padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
      grx = padding
      gry = padding
      grwidth = rc\right-(padding*2)
      grheight = rc\bottom-(padding*2)
      
      
      ; render graph title
      If *graph\title <> ""
        GdipCalcTxt(wParam, *graph\title, @txtWidth, @txtHeight, *graph\titleFont)
        GetWindowRect_(*graph\contentHandle, trc.RECT)
        MapWindowPoints_(0, hwnd, trc, 2)
        tx = ((trc\left+trc\right)/2)-(txtWidth/2)
        tpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\titlePadding
        theight = padding + (tpadding*2)
        ty = (theight/2)-(txtHeight/2)
        GdipRenderTxt(wParam, tx, ty, *graph\title, *graph\titleColour, *graph\titleFont)
        gry + (tpadding*2)
        grheight - (tpadding*2)
      EndIf
      
      ; calc graph x axis label height
      If *graph\xAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\xAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        tx = (rc\right/2)-(txtWidth/2)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        grheight - (txtHeight+(lpadding*2))
        
      EndIf
      
      ; calc graph y axis label width
      If *graph\yAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\yAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        grx + (txtHeight+(lpadding*2))
        grwidth - (txtHeight+(lpadding*2))
        
      EndIf
      
      ; render graph x axis label
      If *graph\xAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\xAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        tx = grx+(grwidth/2)-(txtWidth/2)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        ty = rc\bottom-((lpadding*2)+txtHeight)
        
        GdipRenderTxt(wParam, tx, ty, *graph\xAxisLabel, *graph\axisLabelColour, *graph\axisLabelFont)
        
      EndIf
      
      ; render graph y axis label
      If *graph\yAxisLabel <> ""
        
        GdipCalcTxt(wParam, *graph\yAxisLabel, @txtWidth, @txtHeight, *graph\axisLabelFont)
        padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
        vpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        lpadding = GL_metric(GL_DPI)\DPI_Ratio**graph\labelPadding
        
        ;ty = gry+(grheight/2)-(txtHeight/2)
        ty = gry+(grheight/2) ; centered already through transpose of coords
        tx = (lpadding*2)+(txtHeight/2) ; centered already through transpose of coords
        
        GdipRenderTxtRotated(wParam, tx, ty, *graph\yAxisLabel, *graph\axisLabelColour, *graph\axisLabelFont, 270)
        
      EndIf
      
      If *graph\legendOrientation = #GL_Legend_Top
        GetClientRect_(*graph\legendHandle, lrc.RECT)
        If *graph\title <> ""
          gry + (lrc\bottom-lrc\top)-tpadding
          grheight - (lrc\bottom-lrc\top)+tpadding
        Else
          extra = padding-(lrc\bottom-lrc\top)
          extra - (GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendOutsidePadding)
          If extra < 0
            gry - extra
            grheight + extra
          EndIf
        EndIf
      EndIf
      
      ; render axis ticks and values
      If *graph\xAxisMin < *graph\xAxisMax And *graph\yAxisMin < *graph\yAxisMax
        
        crc.RECT ; create clipping rect
        
        tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
        tickLength = GL_metric(GL_DPI)\DPI_Ratio**graph\tickLength
        tickWidth = GL_metric(GL_DPI)\DPI_Ratio**graph\tickWidth
        valuePadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
        yticks = Round(grheight/tickSpacing, #PB_Round_Down)
        oxticks = xticks
        oyticks = yticks
        xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
        If xticks <= 1 ; make sure there is always at least 2 ticks i.e min and max
          xticks = 2
        EndIf
        yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
        If yticks <= 1  ; make sure there is always at least 2 ticks i.e min and max
          yticks = 2
        EndIf
        xtickSpacing = Round(grwidth / (xticks-1), #PB_Round_Down)
        xtickSpacingError.f = (grwidth / (xticks-1))-Int(grwidth / (xticks-1))
        ytickSpacing = Round(grheight / (yticks-1), #PB_Round_Down)
        ytickSpacingError.f = (grheight / (yticks-1))-Int(grheight / (yticks-1))
        
        ; if tick spacing is less than or equal to zero the exit
        If ytickSpacing <= 0 Or xtickSpacing <= 0
          ProcedureReturn 0
        EndIf
        ; if ytickspacing is less than last ytickspacing (height has shrunk) and yoffset is greater then cap yoffset
        If ytickSpacing < lytickspacing
          If *graph\yOffset > ytickSpacing
            *graph\yOffset - Abs(ytickSpacing-lytickspacing)
          ElseIf *graph\yOffset < -ytickSpacing
            *graph\yOffset + Abs(ytickSpacing-lytickspacing)
          EndIf
        EndIf
        lytickspacing = ytickSpacing
        ; if xtickspacing is less than last xtickspacing (width has shrunk) and xoffset is greater then cap xoffset
        If xtickSpacing < lxtickspacing
          If *graph\xOffset > xtickSpacing
            *graph\xOffset - Abs(xtickSpacing-lxtickspacing)
          ElseIf *graph\xOffset < -xtickSpacing
            *graph\xOffset + Abs(xtickSpacing-lxtickspacing)
          EndIf
        EndIf
        lxtickspacing = xtickSpacing
        
        ; ****** x axis ******
        ytop = gry
        ybottom = gry+grheight
        
        crc\left = grx : crc\top = 0 : crc\right = crc\left + grwidth : crc\bottom = rc\bottom
        
        ; handle scrolling
        If *graph\xOffset > (xtickSpacing+xtickSpacingError)
          While *graph\xOffset > (xtickSpacing+xtickSpacingError)
            delta.d = Abs(ValD(loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 1))-ValD(loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 2)))
            *graph\xAxisMin - delta
            *graph\xAxisMax - delta
            *graph\xOffset - (xtickSpacing+xtickSpacingError)
          Wend
        ElseIf *graph\xOffset < -(xtickSpacing+xtickSpacingError)
          While *graph\xOffset < -(xtickSpacing+xtickSpacingError)
            delta.d = Abs(ValD(loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 1))-ValD(loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 2)))
            *graph\xAxisMin + delta
            *graph\xAxisMax + delta
            *graph\xOffset + (xtickSpacing+xtickSpacingError)
          Wend
        EndIf

        ; extra 2 ticks left off screen for scrolling
        x = Round(grx+(*graph\xOffset)+(1*xtickSpacingError)-(tickWidth/2), #PB_Round_Down)
        If *graph\xOffset <= xtickSpacing
          sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
          rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
          drawVLine(wParam, x, ytop, tickLength, tickWidth, *graph\tickColour)
          drawVLine(wParam, x, ybottom-tickLength, tickLength, tickWidth, *graph\tickColour)
          RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          If x+Round(tickWidth/2, #PB_Round_Nearest) >= grx
            txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
            If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
              txt = "0"
            EndIf
            GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
            GdipRenderTxt(wParam, x-((txtWidth/2)-(tickWidth/2)), ybottom+valuePadding, txt, *graph\axisValueColour, *graph\axisValueFont)
          EndIf
        EndIf
        If *graph\xOffset < -xtickSpacing
          x = Round(grx-(tickWidth/2), #PB_Round_Nearest)
        Else
          x = Round(grx+(*graph\xOffset)+(1*xtickSpacingError)-xtickSpacing-(tickWidth/2), #PB_Round_Nearest)
        EndIf
        sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
        rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
        drawVLine(wParam, x, ytop, tickLength, tickWidth, *graph\tickColour)
        drawVLine(wParam, x, ybottom-tickLength, tickLength, tickWidth, *graph\tickColour)
        RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
        
        ; extra 2 ticks right off screen for scrolling
        x = Round(grx+grwidth+(*graph\xOffset)+(1*xtickSpacingError)-(tickWidth/2), #PB_Round_Down)
        If *graph\xOffset >= -xtickSpacing
          sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
          rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
          drawVLine(wParam, x, ytop, tickLength, tickWidth, *graph\tickColour)
          drawVLine(wParam, x, ybottom-tickLength, tickLength, tickWidth, *graph\tickColour)
          RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          If x+Round(tickWidth/2, #PB_Round_Nearest) <= grx+grwidth
            txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
            If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
              txt = "0"
            EndIf
            GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
            GdipRenderTxt(wParam, x-((txtWidth/2)-(tickWidth/2)), ybottom+valuePadding, txt, *graph\axisValueColour, *graph\axisValueFont)
          EndIf
        EndIf
        If *graph\xOffset > xtickSpacing
          x = Round(grx+grwidth-(tickWidth/2), #PB_Round_Nearest)
        Else
          x = Round(grx+grwidth+(*graph\xOffset)+(1*xtickSpacingError)+xtickSpacing-(tickWidth/2), #PB_Round_Nearest)
        EndIf
        sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
        rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
        drawVLine(wParam, x, ytop, tickLength, tickWidth, *graph\tickColour)
        drawVLine(wParam, x, ybottom-tickLength, tickLength, tickWidth, *graph\tickColour)
        RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
        
        ; render in-between ticks / values
        txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
        *graph\cxAxisMin = ValD(txt)
        For n = 1 To xticks-2
          If tickWidth > 1 ; only take into acount tickwidth if greater than 1 pixel otherwise 0.5
            x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError)-(tickWidth/2), #PB_Round_Nearest)
          Else
            x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError), #PB_Round_Down)
          EndIf
          
          x + *graph\xOffset
          
          ; render ticks
          If *graph\showTicks = #True
            sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
            rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
            drawVLine(wParam, x, ytop, tickLength, tickWidth, *graph\tickColour)
            drawVLine(wParam, x, ybottom-tickLength, tickLength, tickWidth, *graph\tickColour)
            RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          EndIf
          
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, n)
          If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
            txt = "0"
          EndIf
          GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
          GdipRenderTxt(wParam, x-((txtWidth/2)-(tickWidth/2)), ybottom+valuePadding, txt, *graph\axisValueColour, *graph\axisValueFont)
        Next
        If xticks <= 1
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
        Else
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
        EndIf
        *graph\cxAxisMax = ValD(txt)
        
        
        ; ****** y axis ******
        xleft = grx
        xright = grx+grwidth
        
        crc\left = 0 : crc\top = gry : crc\right = rc\right : crc\bottom = crc\top+grheight
        
        ; handle scrolling
        If *graph\yOffset > (ytickSpacing+ytickSpacingError)
          While *graph\yOffset > (ytickSpacing+ytickSpacingError)
            delta.d = Abs(ValD(loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-0))-ValD(loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-1)))
            *graph\yAxisMin + delta
            *graph\yAxisMax + delta
            *graph\yOffset - (ytickSpacing+ytickSpacingError)
          Wend
        ElseIf *graph\yOffset < -(ytickSpacing+ytickSpacingError)
          While *graph\yOffset < -(ytickSpacing+ytickSpacingError)
            delta.d = Abs(ValD(loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-0))-ValD(loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-1)))
            *graph\yAxisMin - delta
            *graph\yAxisMax - delta
            *graph\yOffset + (ytickSpacing+ytickSpacingError)
          Wend
        EndIf
        
        ; extra 2 ticks top off screen for scrolling
        y = Round(gry+(*graph\yOffset)+(1*ytickSpacingError)-(tickWidth/2), #PB_Round_Down)
        If *graph\yOffset <= ytickSpacing
          sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
          rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
          drawHLine(wParam, xleft, y, tickLength, tickWidth, *graph\tickColour)
          drawHLine(wParam, xright-tickLength, y, tickLength, tickWidth, *graph\tickColour)
          RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          If y+Round(tickWidth/2, #PB_Round_Nearest) >= gry
            txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-0)
            If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
              txt = "0"
            EndIf
            GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
            GdipRenderTxt(wParam, xleft-(txtWidth+valuePadding), y-((txtHeight/2)-(tickWidth/2)), txt, *graph\axisValueColour, *graph\axisValueFont)
          EndIf
        EndIf
        If *graph\yOffset < -ytickSpacing
          y = Round(gry-(tickWidth/2), #PB_Round_Nearest)
        Else
          y = Round(gry+(*graph\yOffset)+(1*ytickSpacingError)-ytickSpacing-(tickWidth/2), #PB_Round_Nearest)
        EndIf
        sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
        rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
        drawHLine(wParam, xleft, y, tickLength, tickWidth, *graph\tickColour)
        drawHLine(wParam, xright-tickLength, y, tickLength, tickWidth, *graph\tickColour)
        RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
        
        ; extra 2 ticks bottom off screen for scrolling
        y = Round(gry+grheight+(*graph\yOffset)+(1*ytickSpacingError)-(tickWidth/2), #PB_Round_Down)
        If *graph\yOffset >= -ytickSpacing
          sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
          rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
          drawHLine(wParam, xleft, y, tickLength, tickWidth, *graph\tickColour)
          drawHLine(wParam, xright-tickLength, y, tickLength, tickWidth, *graph\tickColour)
          RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          If y+Round(tickWidth/2, #PB_Round_Nearest) <= gry+grheight
            txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
            If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
              txt = "0"
            EndIf
            GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
            GdipRenderTxt(wParam, xleft-(txtWidth+valuePadding), y-((txtHeight/2)-(tickWidth/2)), txt, *graph\axisValueColour, *graph\axisValueFont)
          EndIf
        EndIf
        If *graph\yOffset > ytickSpacing
          y = Round(gry+grheight-(tickWidth/2), #PB_Round_Nearest)
        Else
          y = Round(gry+grheight+(*graph\yOffset)+(1*ytickSpacingError)+ytickSpacing-(tickWidth/2), #PB_Round_Nearest)
        EndIf
        sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
        rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
        drawHLine(wParam, xleft, y, tickLength, tickWidth, *graph\tickColour)
        drawHLine(wParam, xright-tickLength, y, tickLength, tickWidth, *graph\tickColour)
        RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
        
        ; render in-between ticks / values
        txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
        *graph\cyAxisMin = ValD(txt)
        For n = 1 To yticks-2
          If tickWidth > 1 ; only take into acount tickwidth if greater than 1 pixel otherwise 0.5
            y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError)-(tickWidth/2), #PB_Round_Nearest)
          Else
            y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError), #PB_Round_Down)
          EndIf
          
          y + *graph\yOffset
          
          ; render ticks
          If *graph\showTicks = #True
            sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
            rRgn = IntersectClipRect_(wParam, crc\left, crc\top, crc\right, crc\bottom) ; clip to graph border
            drawHLine(wParam, xleft, y, tickLength, tickWidth, *graph\tickColour)
            drawHLine(wParam, xright-tickLength, y, tickLength, tickWidth, *graph\tickColour)
            RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
          EndIf
          
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, (yticks-1)-n)
          If ValF(txt) = 0 ; if zero then make sure display just zero with no floating point
            txt = "0"
          EndIf
          GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\axisValueFont)
          GdipRenderTxt(wParam, xleft-(txtWidth+valuePadding), y-((txtHeight/2)-(tickWidth/2)), txt, *graph\axisValueColour, *graph\axisValueFont)
        Next
        If yticks <= 1
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
        Else
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
        EndIf  
        *graph\cyAxisMax = ValD(txt)
        
      EndIf

      ; render border around graph
      drawRectangle(wParam, grx, gry, grwidth, grheight, *graph\borderThickness, *graph\borderColour, #True)
      
  EndSelect
  
EndProcedure

Procedure GraphContentCallback(hwnd, message, wParam, lParam)
  Static mouseStartX, mouseStartY, mouseCaptured, spt.POINT
  
  *graph.GL_Graphs = GetWindowLongPtr_(hwnd, #GWL_USERDATA)
  If *graph = #Null
    *graph.GL_Graphs = GetWindowLongPtr_(GetParent_(hwnd), #GWL_USERDATA)
  EndIf
  
  If *graph = #Null
    ProcedureReturn #False
  EndIf
  
  Select message
      
    ; intercept max window size and alter so high DPI printing is possible  
    Case #WM_GETMINMAXINFO
      
      *pmmi.MINMAXINFO = lParam
      If *pmmi\ptMaxTrackSize\x < GL_metric(GL_DPI)\printWidth
        *pmmi\ptMaxTrackSize\x = GL_metric(GL_DPI)\printWidth
      EndIf
      If *pmmi\ptMaxTrackSize\y < GL_metric(GL_DPI)\printHeight
        *pmmi\ptMaxTrackSize\y = GL_metric(GL_DPI)\printHeight
      EndIf  
      
    Case #WM_ERASEBKGND
      
      GetClientRect_(hwnd, rc.RECT)
      grx = *graph\xOffset
      gry = *graph\yOffset
      grwidth = rc\right
      grheight = rc\bottom
      x.f
      y.f
      
      ; render graph background fill
      brush = CreateSolidBrush_(RGB(255, 255, 255))
      FillRect_(wParam, rc, brush)
      DeleteObject_(brush)
      
      ;- render graph gridlines if set
      If *graph\gridlines <> #False And *graph\xAxisMin < *graph\xAxisMax And *graph\yAxisMin < *graph\yAxisMax
      
        ; calc axis ticks
        tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
        tickLength = GL_metric(GL_DPI)\DPI_Ratio**graph\tickLength
        tickWidth = GL_metric(GL_DPI)\DPI_Ratio**graph\tickWidth
        gridWidth = GL_metric(GL_DPI)\DPI_Ratio**graph\gridlineWidth
        gridMinorWidth = GL_metric(GL_DPI)\DPI_Ratio**graph\gridlineMinorWidth
        
        valuePadding = GL_metric(GL_DPI)\DPI_Ratio**graph\valuePadding
        xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
        yticks = Round(grheight/tickSpacing, #PB_Round_Down)
        oxticks = xticks
        oyticks = yticks
        xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
        yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
        xtickSpacing = Round(grwidth / (xticks-1), #PB_Round_Down)
        xtickSpacingError.f = (grwidth / (xticks-1))-Int(grwidth / (xticks-1))
        ytickSpacing = Round(grheight / (yticks-1), #PB_Round_Down)
        ytickSpacingError.f = (grheight / (yticks-1))-Int(grheight / (yticks-1))
        
        txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
        *graph\cxAxisMin = ValD(txt)
        If xticks <= 1
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
        Else
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
        EndIf
        *graph\cxAxisMax = ValD(txt)
        txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
        *graph\cyAxisMin = ValD(txt)
        If yticks <= 1
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
        Else
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
        EndIf
        *graph\cyAxisMax = ValD(txt)
        
        ; x axis
        ytop = gry
        ybottom = gry+grheight
        
        ; render extra scrolling gridlines at left
        ; major gridline
        If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
            x = Round(grx-(gridWidth/2), #PB_Round_Nearest)
          Else
            x = Round(grx, #PB_Round_Down)
          EndIf
        drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridWidth, *graph\gridlineColour)
        ; minor gridline
        If *graph\gridlinesMinor = #True
          If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
            x = Round(grx-(gridMinorWidth/2)-(xtickSpacing/2), #PB_Round_Nearest)
          Else
            x = Round(grx-(xtickSpacing/2), #PB_Round_Down)
          EndIf
          drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
        EndIf
        
        For n = 1 To xticks-2
          
          ; major gridline
          If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
            x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError)-(gridWidth/2), #PB_Round_Nearest)
          Else
            x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError), #PB_Round_Down)
          EndIf
          
          drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridWidth, *graph\gridlineColour)
          
          ; minor gridline
          If *graph\gridlinesMinor = #True
            If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
              x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError)-(gridMinorWidth/2)-(xtickSpacing/2), #PB_Round_Nearest)
            Else
              x = Round(grx+(n*xtickSpacing)+(n*xtickSpacingError)-(xtickSpacing/2), #PB_Round_Down)
            EndIf
            
            drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
            If n = xticks-2
              drawVLine(wParam, x+xtickSpacing, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour) ; draw end minor too when at end of loop
            EndIf
          EndIf
          
        Next
        If *graph\gridlinesMinor = #True
          If x = 0
            drawVLine(wParam, grwidth/2, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour) ; draw end minor too when at end of loop
          EndIf
        EndIf
        
        ; render extra scrolling gridlines at right
        ; major gridline
        If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
            x = Round(grx+grwidth-(gridWidth/2), #PB_Round_Nearest)
          Else
            x = Round(grx+grwidth, #PB_Round_Down)
          EndIf
        drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridWidth, *graph\gridlineColour)
        ; minor gridline
        If *graph\gridlinesMinor = #True
          If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
            x = Round(grx+grwidth+(xtickSpacing)+(xtickSpacingError)-(gridMinorWidth/2)-(xtickSpacing/2), #PB_Round_Nearest)
          Else
            x = Round(grx+grwidth+(xtickSpacing)+(xtickSpacingError)-(xtickSpacing/2), #PB_Round_Down)
          EndIf
          drawVLine(wParam, x, ytop-(ytickSpacing+ytickSpacingError), grheight+((ytickSpacing+ytickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
        EndIf
        
        ; y axis
        xleft = grx
        xright = grx+grwidth
        
        ; render extra scrolling gridlines at top
        ; major gridline
        If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
          y = Round(gry-(gridWidth/2), #PB_Round_Nearest)
        Else
          y = Round(gry, #PB_Round_Down)
        EndIf
        drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridWidth, *graph\gridlineColour)
        ; minor gridline
        If *graph\gridlinesMinor = #True
          If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
            y = Round(gry-(gridMinorWidth/2)-(ytickSpacing/2), #PB_Round_Nearest)
          Else
            y = Round(gry-(ytickSpacing/2), #PB_Round_Down)
          EndIf
          drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
        EndIf
          
        For n = 1 To yticks-2
          
          ; major gridline
          If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
            y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError)-(gridWidth/2), #PB_Round_Nearest)
          Else
            y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError), #PB_Round_Down)
          EndIf
          
          drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridWidth, *graph\gridlineColour)
          
          ; minor gridline
          If *graph\gridlinesMinor = #True
            If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
              y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError)-(gridMinorWidth/2)-(ytickSpacing/2), #PB_Round_Nearest)
            Else
              y = Round(gry+(n*ytickSpacing)+(n*ytickSpacingError)-(ytickSpacing/2), #PB_Round_Down)
            EndIf
            
            drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
            If n = yticks-2
              drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y+ytickSpacing, grwidth+((xtickSpacing+xtickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour) ; draw end minor too when at end of loop
            EndIf
          EndIf
          
        Next
        If *graph\gridlinesMinor = #True
          If y = 0
            drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), grheight/2, grwidth+((xtickSpacing+xtickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour) ; draw end minor too when at end of loop
          EndIf
        EndIf
        
        ; render extra scrolling gridlines at bottom
        ; major gridline
        If gridWidth > 1 ; only take into acount gridWidth if greater than 1 pixel otherwise 0.5
          y = Round(gry+grheight-(gridWidth/2), #PB_Round_Nearest)
        Else
          y = Round(gry+grheight, #PB_Round_Down)
        EndIf
        drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridWidth, *graph\gridlineColour)
        ; minor gridline
        If *graph\gridlinesMinor = #True
          If gridMinorWidth > 1 ; only take into acount gridMinorWidth if greater than 1 pixel otherwise 0.5
            y = Round(gry+grheight+(ytickSpacing)+(ytickSpacingError)-(gridMinorWidth/2)-(ytickSpacing/2), #PB_Round_Nearest)
          Else
            y = Round(gry+grheight+(ytickSpacing)+(ytickSpacingError)-(ytickSpacing/2), #PB_Round_Down)
          EndIf
          drawHLine(wParam, xleft-(xtickSpacing+xtickSpacingError), y, grwidth+((xtickSpacing+xtickSpacingError)*2), gridMinorWidth, *graph\gridlineMinorColour)
        EndIf
        
      EndIf
      
    Case #WM_PAINT
      
      GetClientRect_(hwnd, rc.RECT)
      padding = GL_metric(GL_DPI)\DPI_Ratio**graph\padding
      grwidth = rc\right
      grheight = rc\bottom
      
      ; don't render if graph max ranges are not set or incorrect
      If *graph\xAxisMin >= *graph\xAxisMax Or *graph\yAxisMin >= *graph\yAxisMax
        ProcedureReturn #False
      EndIf
      
      xAxisMin.d = *graph\cxAxisMin
      xAxisMax.d = *graph\cxAxisMax
      yAxisMin.d = *graph\cyAxisMin
      yAxisMax.d = *graph\cyAxisMax
      
      
      ;rsdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
      ;rRgn = IntersectClipRect_(wParam, rc\left, rc\top, rc\right, rc\bottom) ; clip inside range


      ;- **** render zero axis lines/ruler
      If *graph\showZeroAxisLines = #True
        
        zx.d = 0
        zy.d = 0
        zx = (grwidth/(xAxisMax-xAxisMin))*(zx-xAxisMin)
        zy = ((grheight/(yAxisMax-yAxisMin))*(zy-yAxisMin))
        zx + *graph\xOffset
        zy - *graph\yOffset
        zx = Round(zx, #PB_Round_Down)
        zy = Round(zy, #PB_Round_Up)
        
        If zy > 0 And zy < grheight
          ;drawHLine(wParam, 0, grheight-zy, grwidth, *graph\zeroAxisThickness, *graph\zeroAxisColour, #True)
          drawHLineDashed(wParam, 0, grheight-zy, grwidth, *graph\zeroAxisThickness, *graph\zeroAxisColour, 2, #True)
        EndIf  
        If zx > 0 And zx < grwidth
          ;drawVLine(wParam, zx, 0, grheight, *graph\zeroAxisThickness, *graph\zeroAxisColour, #True)
          drawVLineDashed(wParam, zx, 0, grheight, *graph\zeroAxisThickness, *graph\zeroAxisColour, 2, #True)
        EndIf
        
      EndIf
      
      ;- **** render density plots
      ForEach *graph\density()
        
        rxMin.d = *graph\density()\xMin
        rxMax.d = *graph\density()\xMax
        ryMin.d = *graph\density()\yMin
        ryMax.d = *graph\density()\yMax
        
        rxMin = (grwidth/(xAxisMax-xAxisMin))*(rxMin-xAxisMin)
        rxMax = (grwidth/(xAxisMax-xAxisMin))*(rxMax-xAxisMin)
        ryMin = ((grheight/(yAxisMax-yAxisMin))*(ryMin-yAxisMin))
        ryMax = ((grheight/(yAxisMax-yAxisMin))*(ryMax-yAxisMin))
        
        rxMin + *graph\xOffset
        rxMax + *graph\xOffset
        ryMin - *graph\yOffset
        ryMax - *graph\yOffset

        rrc.RECT
        rrc\left = rxMin
        rrc\right = rxMax
        rrc\top = grheight-ryMax
        rrc\bottom = grheight-ryMin
        
        xRatio.f = (rrc\right-rrc\left)/(ArraySize(*graph\density()\Plot(), 1))
        yRatio.f = (rrc\bottom-rrc\top)/(ArraySize(*graph\density()\Plot(), 2))
        
        minColour = *graph\density()\minColour
        minColour = RGB(Blue(minColour), Green(minColour), Red(minColour))
        maxColour = *graph\density()\maxColour
        maxColour = RGB(Blue(maxColour), Green(maxColour), Red(maxColour))
        minAlpha = Alpha(*graph\density()\minColour)
        maxAlpha = Alpha(*graph\density()\maxColour)
        
        
        range.d = *graph\density()\maxValue-*graph\density()\minValue
        blendRatio.d = 255/range
        
        ; don't bother calculating / rendering values if too small
        If *graph\density()\showValues = #True
          GdipCalcTxt(wParam, "-.0", @txtWidth, @txtHeight, *graph\density()\valueFont)
          If txtWidth > xRatio
            noRenderValues = #True
          Else
            noRenderValues = #False
          EndIf
        EndIf

        ; only loop through array elements that are visible
        si = 0
        sj = 0
        ei = ArraySize(*graph\density()\Plot(), 2)-1
        ej = ArraySize(*graph\density()\Plot(), 1)-1
        If rrc\top < -yRatio
          si = Round(Abs(rrc\top)/yRatio, #PB_Round_Down)
        EndIf
        If rrc\bottom > grheight+yRatio
          ei = (ArraySize(*graph\density()\Plot(), 2)-1)-Round((rrc\bottom-grheight)/yRatio, #PB_Round_Down)
        EndIf
        If rrc\left < -xRatio
          sj = Round(Abs(rrc\left)/xRatio, #PB_Round_Down)
        EndIf
        If rrc\right > grwidth+xRatio
          ej = (ArraySize(*graph\density()\Plot(), 1)-1)-Round((rrc\right-grwidth)/xRatio, #PB_Round_Down)
        EndIf
          
        For i = si To ei
          For j = sj To ej

            px.f = rrc\left+(j*xRatio)
            py.f = rrc\top+(i*yRatio)
            
            ; only render what's visible
            If px >= -xRatio And px < grwidth And py >= -yRatio And py < grheight
              
              value.d = *graph\density()\Plot(j, i)
            
              If *graph\density()\callback = #Null ; render default if no callback
                colour = AlphaBlendColour(minColour, maxColour, blendRatio*(value-*graph\density()\minValue))
                colour = MakeColour(255, Red(Colour), Green(Colour), Blue(colour))
              Else
                colour = CallFunctionFast(*graph\density()\callback, @value)
              EndIf
              
              fillRectangle(wParam, px, py, xRatio, yRatio, colour)
              
              ; render values if set
              If *graph\density()\showValues = #True And noRenderValues = #False
                If *graph\density()\plotCache(j, i)\xRatio <> Int(xRatio) ; only recalc if xRatio (width of box) has changed
                  value$ = calcTxtProcisionSize(wParam, value, xRatio, *graph\density()\valueFont)
                  *graph\density()\plotCache(j, i)\value = value$
                  *graph\density()\plotCache(j, i)\xRatio = Int(xRatio)
                EndIf
                value$ = *graph\density()\plotCache(j, i)\value
                
                If value$ <> ""
                  GdipCalcTxt(wParam, value$, @txtWidth, @txtHeight, *graph\density()\valueFont)
                  sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
                  rRgn = IntersectClipRect_(wParam, px, py, px+xRatio, py+yRatio) ; clip inside
                  
                  col.color
                  col\r = Blue(colour)
                  col\g = Green(colour)
                  col\b = Blue(colour)
                  col\type = #COLOR_RGB
                  *col.color = RGB2HSL(col)
                  If *col\l > 90
                    txtColour = MakeColour(255, 0, 0, 0)
                  Else
                    txtColour = MakeColour(255, 255, 255, 255)
                  EndIf
                  
                  GdipRenderTxt(wParam, px+(xRatio/2)-(txtWidth/2), py+(yRatio/2)-(txtHeight/2), value$, txtColour, *graph\density()\valueFont)
                  
                  RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
                EndIf
              EndIf
              
            EndIf
            
          Next
        Next
        
        ; render gridlines
        If *graph\density()\showGridlines = #True
          
          gfWidth.f = Round((GL_metric(GL_DPI)\DPI_Ratio**graph\density()\gridlineWidth), #PB_Round_Up)
          gWidth.f = Round((GL_metric(GL_DPI)\DPI_Ratio**graph\density()\gridlineWidth)/2, #PB_Round_Down)
          gWidth2.f = Round((GL_metric(GL_DPI)\DPI_Ratio**graph\density()\gridlineWidth)/2, #PB_Round_Up)
          
          If gfWidth*2 < xRatio And gfWidth*2 < yRatio ; make sure gridlines aren't bigger than box
            For i = si To ei+1
              
              py.f = Round(rrc\top+(i*yRatio), #PB_Round_Down)
              py2.f = Round(rrc\top+(i*yRatio), #PB_Round_Nearest)
              
              If i = ArraySize(*graph\density()\Plot(), 2)
                drawHLine(wParam, rrc\left-gWidth, py2-gWidth2, (rrc\right-rrc\left)+(gWidth*2), *graph\density()\gridlineWidth, *graph\density()\gridlineColour, #True)
              Else
                drawHLine(wParam, rrc\left-gWidth, py-gWidth, (rrc\right-rrc\left)+(gWidth), *graph\density()\gridlineWidth, *graph\density()\gridlineColour, #True)
              EndIf
              
            Next
            For j = sj To ej+1
             
              px.f = Round(rrc\left+(j*xRatio), #PB_Round_Down)
              px2.f = Round(rrc\left+(j*xRatio), #PB_Round_Nearest)
              
              If j = ArraySize(*graph\density()\Plot(), 1)
                drawVLine(wParam, px2-gwidth2, rrc\top-gWidth, (rrc\bottom-rrc\top)+(gWidth*2), *graph\density()\gridlineWidth, *graph\density()\gridlineColour, #True)
              Else
                drawVLine(wParam, px-gwidth, rrc\top-gWidth, (rrc\bottom-rrc\top)+(gWidth), *graph\density()\gridlineWidth, *graph\density()\gridlineColour, #True)
              EndIf
              
            Next
          EndIf
          
        EndIf
        
      Next
      
      ;- **** render ranges
      ForEach *graph\range()
        
        rxMin.d = *graph\range()\xMin
        rxMax.d = *graph\range()\xMax
        ryMin.d = *graph\range()\yMin
        ryMax.d = *graph\range()\yMax
        
        rxMin = (grwidth/(xAxisMax-xAxisMin))*(rxMin-xAxisMin)
        rxMax = (grwidth/(xAxisMax-xAxisMin))*(rxMax-xAxisMin)
        ryMin = ((grheight/(yAxisMax-yAxisMin))*(ryMin-yAxisMin))
        ryMax = ((grheight/(yAxisMax-yAxisMin))*(ryMax-yAxisMin))
        
        rxMin + *graph\xOffset
        rxMax + *graph\xOffset
        ryMin - *graph\yOffset
        ryMax - *graph\yOffset
        
        rxMin = Round(rxMin, #PB_Round_Down)
        rxMax = Round(rxMax, #PB_Round_Down)
        ryMin = Round(ryMin, #PB_Round_Up)
        ryMax = Round(ryMax, #PB_Round_Up)
        
        rrc.RECT
        rrc\left = rxMin
        rrc\right = rxMax
        rrc\top = grheight-ryMax
        rrc\bottom = grheight-ryMin
        
        ; only render what's visible
        
        If IntersectRect_(trc.RECT, rc, rrc) <> #False
          fillRectangle(wParam, rrc\left, rrc\top, rrc\right-rrc\left, rrc\bottom-rrc\top, *graph\range()\colour)
          
          If *graph\range()\showBorder = #True
            colour = *graph\range()\colour
            borderColour = MakeColour(255, Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
            drawRectangle(wParam, rrc\left, rrc\top, rrc\right-rrc\left, rrc\bottom-rrc\top, 1, borderColour, 0)
          EndIf
          
          ; bound rrc to graph width height so as range label is always visibly centred
          If rrc\left < 0
            rrc\left = 0
          EndIf
          If rrc\top < 0
            rrc\top = 0
          EndIf
          If rrc\right > grwidth
            rrc\right = grwidth
          EndIf
          If rrc\bottom > grheight
            rrc\bottom = grheight
          EndIf
          
          tx = rrc\left
          ty = rrc\top
          
          colour = *graph\range()\colour
          r = Blue(colour)
          g = Green(colour)
          b = Red(colour)
          a = Alpha(colour)
          
          colour = MakeColor(a, r/2, g/2, b/2)
          GdipCalcTxt(wParam, *graph\range()\label, @txtWidth, @txtHeight, *graph\rangeFont)
          
          rwidth = rrc\right-rrc\left
          rheight = rrc\bottom-rrc\top
          tx + (rwidth/2)-(txtWidth/2)
          ty + (rheight/2)-(txtHeight/2)
          sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
          rRgn = IntersectClipRect_(wParam, rrc\left, rrc\top, rrc\right, rrc\bottom) ; clip inside range
          GdipRenderTxt(wParam, tx, ty, *graph\range()\label, colour, *graph\rangeFont)
          RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
        EndIf
        
      Next
      
      ;- **** render poly ranges
      ForEach *graph\prange()
        
        Dim p.POINTF(ArraySize(*graph\prange()\pnt()))
        For n = 0 To ArraySize(*graph\prange()\pnt())-1
          
          x.f = *graph\prange()\pnt(n)\x
          y.f = *graph\prange()\pnt(n)\y
          x = (grwidth/(xAxisMax-xAxisMin))*(x-xAxisMin)
          y = -((grheight/(yAxisMax-yAxisMin))*(y-yAxisMin))
          y + grheight
          
          x + *graph\xOffset
          y + *graph\yOffset
          
          p(n)\x = Round(x, #PB_Round_Down)
          p(n)\y = Round(y, #PB_Round_Down)
          
        Next
        
        colour = *graph\prange()\colour
        
        If *graph\prange()\isFilled = #True
          fillColour = colour
          outlineColour = MakeColour(255, Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
        Else
          outlineColour = colour
        EndIf

        drawPolygon(wParam, rc, p(), fillColour, outlineColour, *graph\prange()\thickness, *graph\prange()\dashStyle, *graph\prange()\isFilled, *graph\prange()\isClosed, *graph\prange()\label, *graph\rangeFont)
        
      Next
      
      ;- **** render bars
      ForEach *graph\bars()
        
        numbars = ArraySize(*graph\bars()\bar())
        For i = 0 To numbars - 1
          
          If *graph\bars()\bar(i)\minPos <> *graph\bars()\bar(i)\maxPos
            pos1.d = *graph\bars()\bar(i)\minPos
            pos2.d = *graph\bars()\bar(i)\maxPos
          Else
          
            midpoint.d = (*graph\bars()\bar(i)\minPos + *graph\bars()\bar(i)\maxPos) / 2
            
            If i > 0
              prevmidpoint.d = (*graph\bars()\bar(i-1)\minPos + *graph\bars()\bar(i-1)\maxPos) / 2
            EndIf
            
            If i < numbars - 1
              nextmidpoint.d = (*graph\bars()\bar(i+1)\minPos + *graph\bars()\bar(i+1)\maxPos) / 2
            EndIf
            
            If numbars = 1
              
              If *graph\bars()\bar(i)\minPos <> *graph\bars()\bar(i)\maxPos
                  prevmidpoint = midpoint - (*graph\bars()\bar(i)\maxPos - *graph\bars()\bar(i)\minPos)
                  nextmidpoint = midpoint + (*graph\bars()\bar(i)\maxPos - *graph\bars()\bar(i)\minPos)
              Else
                  prevmidpoint = midpoint - 2
                  nextmidpoint = midpoint + 2
              EndIf
              
            ElseIf i = 0
                prevmidpoint = midpoint - (nextmidpoint - midpoint)
            ElseIf i = numbars - 1
                nextmidpoint = midpoint + (midpoint - prevmidpoint)
            EndIf
            
            If i > 0 And (*graph\bars()\bar(i - 1)\minPos <> *graph\bars()\bar(i - 1)\maxPos)
              pos1 = *graph\bars()\bar(i - 1)\maxPos
            Else
              pos1 = (midpoint + prevmidpoint) / 2
            EndIf
            If i < numbars - 1 And (*graph\bars()\bar(i + 1)\minPos <> *graph\bars()\bar(i + 1)\maxPos)
              pos2 = *graph\bars()\bar(i + 1)\minPos
            Else
              pos2 = (midpoint + nextmidpoint) / 2
            EndIf

          EndIf
          
          ; vertical bars
          If *graph\bars()\isHorizontal = #False
            
            minValue.d = *graph\bars()\bar(i)\minValue
            maxValue.d = *graph\bars()\bar(i)\maxValue
            
            ;Debug "-----"
            ;Debug pos1
            ;Debug pos2
            
            pos1 = (grwidth/(xAxisMax-xAxisMin))*(pos1-xAxisMin)
            pos2 = (grwidth/(xAxisMax-xAxisMin))*(pos2-xAxisMin)
            minValue = ((grheight/(yAxisMax-yAxisMin))*(minValue-yAxisMin))
            maxValue = ((grheight/(yAxisMax-yAxisMin))*(maxValue-yAxisMin))
            pos1 + *graph\xOffset
            pos2 + *graph\xOffset
            minValue - *graph\yOffset
            maxValue - *graph\yOffset
            
            rcf.RECTF
            rcf\left = pos1
            rcf\top = grheight-maxValue
            rcf\right = rcf\left + (pos2 - pos1)
            rcf\bottom = rcf\top + ((grheight-minValue)-(grheight-maxValue))
            
            rcf\top = Round(rcf\top, #PB_Round_Down)
            rcf\bottom = Round(rcf\bottom, #PB_Round_Down)
            
          ; horizontal bars  
          Else
            
            minValue.d = *graph\bars()\bar(i)\minValue
            maxValue.d = *graph\bars()\bar(i)\maxValue
            
            ;Debug "-----"
            ;Debug *graph\bars()\bar(i)\label
            ;Debug pos1
            ;Debug pos2
            
            pos1 = ((grheight/(yAxisMax-yAxisMin))*(pos1-yAxisMin))
            pos2 = ((grheight/(yAxisMax-yAxisMin))*(pos2-yAxisMin))
            minValue = (grwidth/(xAxisMax-xAxisMin))*(minValue-xAxisMin)
            maxValue = (grwidth/(xAxisMax-xAxisMin))*(maxValue-xAxisMin)
            pos1 - *graph\yOffset
            pos2 - *graph\yOffset
            minValue + *graph\xOffset
            maxValue + *graph\xOffset
            
            rcf.RECTF
            rcf\left = minValue
            rcf\top = grheight-pos2
            rcf\right = rcf\left + (maxValue - minValue)
            rcf\bottom = rcf\top + ((grheight-pos1)-(grheight-pos2))
            
            rcf\top = Round(rcf\top, #PB_Round_Down)
            rcf\bottom = Round(rcf\bottom, #PB_Round_Down)

          EndIf
            
          colour = *graph\bars()\bar(i)\colour
          
          col.color
          col\r = Blue(colour)
          col\g = Green(colour)
          col\b = Red(colour)
          col\type = #COLOR_RGB
          *col.color = RGB2HSL(col)
          *col\l / 1.8
          *col = HSL2RGB(*col)
          darkColour = MakeColour(255, Int(*col\r), Int(*col\g), Int(*col\b))
          
          col.color
          col\r = Blue(colour)
          col\g = Green(colour)
          col\b = Red(colour)
          col\type = #COLOR_RGB
          *col.color = RGB2HSL(col)
          *col\l / 3
          *col = HSL2RGB(*col)
          borderColour = MakeColour(255, Int(*col\r), Int(*col\g), Int(*col\b))
          
          ; swap dimensions if negative
          swappedTop = #False
          If rcf\top > rcf\bottom
            t.f = rcf\bottom
            rcf\bottom = rcf\top
            rcf\top = t
            swappedTop = #True
          EndIf
          swappedLeft = #False
          If rcf\left > rcf\right
            t.f = rcf\right
            rcf\right = rcf\left
            rcf\left = t
            swappedLeft = #True
          EndIf
          
          CopyRect_(*graph\bars()\bar(i)\rcf, rcf)
          
          ; only render what's visible
          trc.RECT\left = rcf\left : trc\top = rcf\top : trc\right = rcf\right : trc\bottom = rcf\bottom
          If IntersectRect_(trc, rc, trc) <> #False
            
            If *graph\bars()\isHorizontal = #False
              gradientFill(wParam, rcf, darkColour, colour)
            Else
              gradientFill(wParam, rcf, darkColour, colour, #True)
            EndIf
            drawRectangle(wParam, rcf\left, rcf\top, rcf\right-rcf\left, rcf\bottom-rcf\top, 1, borderColour, 0)
            
            ; render labels and values
            If *graph\bars()\isHorizontal = #False
              
              txt.s = *graph\bars()\bar(i)\label
              GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\barFont)
              
              tty.f = rcf\top+((rcf\bottom-rcf\top)/2) ; centered already through transpose of coords
              ttx.f = rcf\left+((rcf\right-rcf\left)/2) ; centered already through transpose of coords
              
              txtColour = MakeColour(255, Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
              
              ; render label
              sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
              rRgn = IntersectClipRect_(wParam, rcf\left, rcf\top, rcf\right, rcf\bottom) ; clip inside range
              GdipRenderTxtRotated(wParam, ttx, tty, txt, txtColour, *graph\barFont, 270)
              RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
              
              ; render value
              txt.s = StrD(*graph\bars()\bar(i)\maxValue)
              GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\barValueFont)
              If swappedTop = #False
                tty.f = rcf\top-(txtHeight*1.2)
              Else
                tty.f = rcf\bottom+(txtHeight*0.2)
              EndIf
              ttx.f = rcf\left+(((rcf\right-rcf\left)/2)-(txtWidth/2))
              GdipRenderTxt(wParam, ttx, tty, txt, MakeColour(255, 0, 0, 0), *graph\barValueFont)
              
              
            Else
              
              txt.s = *graph\bars()\bar(i)\label
              GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\barFont)
              
              tty.f = rcf\top+(((rcf\bottom-rcf\top)/2)-(txtHeight/2)) ; centered already through transpose of coords
              ttx.f = rcf\left+(((rcf\right-rcf\left)/2)-(txtWidth/2)) ; centered already through transpose of coords
              
              txtColour = MakeColour(255, Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
              
              ; render label
              sdc = SaveDC_(wParam) ; so as not to bugger up any nested clipping
              rRgn = IntersectClipRect_(wParam, rcf\left, rcf\top, rcf\right, rcf\bottom) ; clip inside range
              GdipRenderTxt(wParam, ttx, tty, txt, txtColour, *graph\barFont)
              RestoreDC_(wParam, sdc) ; previous dc states restored, e.g. clipping
              
              ; render value
              txt.s = StrD(*graph\bars()\bar(i)\maxValue)
              GdipCalcTxt(wParam, txt, @txtWidth, @txtHeight, *graph\barValueFont)
              tty.f = rcf\top+(((rcf\bottom-rcf\top)/2)-(txtHeight/2))
              If swappedLeft = #False
                ttx.f = rcf\right+(txtHeight*0.6)
              Else
                ttx.f = rcf\Left-(txtHeight*1.6)
              EndIf
              GdipRenderTxt(wParam, ttx, tty, txt, MakeColour(255, 0, 0, 0), *graph\barValueFont)
              
            EndIf
            
          EndIf
          
        Next
        
      Next
      
      ;- **** render lines
      NewList label.GL_GraphLineLabels()
      ForEach *graph\Line()
        
        colour = *graph\Line()\colour
        ;Debug "------"

        Dim ln.POINTF(ListSize(*graph\Line()\pnt()))
        n = 0 : highestN = 0 : highestY = $FFFFFF
        rrc.RECT : rrc\left = rc\right : rrc\top = rc\bottom : rrc\right = 0 : rrc\bottom = 0
        ForEach *graph\Line()\pnt()
          
          x.f = *graph\Line()\pnt()\x
          y.f = *graph\Line()\pnt()\y
          x = (grwidth/(xAxisMax-xAxisMin))*(x-xAxisMin)
          y = -((grheight/(yAxisMax-yAxisMin))*(y-yAxisMin))
          y + grheight
          
          x + *graph\xOffset
          y + *graph\yOffset
          
          ln(n)\x = Round(x, #PB_Round_Down)
          ln(n)\y = Round(y, #PB_Round_Down)
          
          ; update bounding box for rendering only what's visible
          If x < rrc\left
            rrc\left = x
          EndIf
          If x > rrc\right
            rrc\right = x
          EndIf
          If y < rrc\top
            rrc\top = y
          EndIf
          If y > rrc\bottom
            rrc\bottom = y
          EndIf
          
          ; find highest ln index for properly displaying of label
          If y < highestY ; pixels
            highestY = y
            highestN = n
          EndIf
          
          n + 1
          
        Next
        
        ; render only what's visible based on bounding box
        If IntersectRect_(trc.RECT, rc, rrc) <> #False
          
          If *graph\Line()\noLines = #False
            drawLines(wParam, rc, ln(), *graph\Line()\thickness, colour, *graph\Line()\style)
          EndIf
          
          drawNodes(wParam, rc, *graph\Line(), ln())
          
        EndIf
        
        If *graph\Line()\label <> "" And *graph\Line()\showFloatingLabel = #True
          GdipCalcTxt(wParam, *graph\Line()\label, @w, @h, *graph\lineFont)
          AddElement(label())
          label()\label = *graph\Line()\label
          label()\x = ln(highestN)\x
          label()\y = ln(highestN)\y
          label()\width = w
          label()\height = h
          label()\colour = colour
        EndIf
        
      Next
      
      ; algorithm for making sure labels don't overlap, vertical position is set to overlaping labels bottom position
      For n = 0 To 1
        
        ForEach label()
          
          padding = GL_metric(GL_DPI)\DPI_Ratio*2
          w = label()\width+(padding*2)
          h = label()\height+(padding*2)
          x = label()\x
          y = label()\y
          index = ListIndex(label())
          label.s = label()\label
          PushListPosition(label())
          ForEach label()
            If ListIndex(label()) <> index
              w2 = label()\width+(padding*2)
              h2 = label()\height+(padding*2)
              x2 = label()\x
              y2 = label()\y
              src.RECT
              src2.RECT
              src\left = x
              src\top = y
              src\right = x+w
              src\bottom = y+h
              src2\left = x2
              src2\top = y2
              src2\right = x2+w2
              src2\bottom = y2+h2
              If IntersectRect_(trc.RECT, src, src2)
                label()\y = y+h
              EndIf
            EndIf
          Next
          PopListPosition(label())
          
        Next
        
      Next
      
      ;- **** render rulers
      ForEach *graph\ruler()
        
        pos.f = *graph\ruler()\position
        
        ; vertical ruler
        If *graph\ruler()\isHorizontal = #False
          pos = (grwidth/(xAxisMax-xAxisMin))*(pos-xAxisMin)
          pos + *graph\xOffset
          pos = Round(pos, #PB_Round_Down)
          
          If pos >= rc\left And pos <= rc\right ; only render if visible
            If *graph\ruler()\label <> ""
              GdipCalcTxt(wParam, *graph\ruler()\label, @w, @h, *graph\ruler()\font)
              drawLine(wParam, pos, rc\top, pos, ((rc\bottom-rc\top)/2)-(w/2), *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
              drawLine(wParam, pos, ((rc\bottom-rc\top)/2)+(w/2), pos, rc\bottom, *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
              colour = *graph\ruler()\colour
              txtColour = MakeColour(Alpha(colour), Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
              GdipRenderTxtRotated(wParam, pos, ((rc\bottom-rc\top)/2), *graph\ruler()\label, txtColour, *graph\ruler()\font, 270)
            Else
              drawLine(wParam, pos, rc\top, pos, rc\bottom, *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
            EndIf
          EndIf
          
        ; horizontal ruler
        Else
          pos = -((grheight/(yAxisMax-yAxisMin))*(pos-yAxisMin))
          pos + grheight
          pos + *graph\yOffset
          pos = Round(pos, #PB_Round_Down)
          
          If pos >= rc\top And pos <= rc\bottom
            If *graph\ruler()\label <> ""
              GdipCalcTxt(wParam, *graph\ruler()\label, @w, @h, *graph\ruler()\font)
              drawLine(wParam, rc\left, pos, ((rc\right-rc\left)/2)-(w/2), pos, *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
              drawLine(wParam, ((rc\right-rc\left)/2)+(w/2), pos, rc\right, pos, *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
              colour = *graph\ruler()\colour
              txtColour = MakeColour(Alpha(colour), Int(Blue(colour)/2), Int(Green(colour)/2), Int(Red(colour)/2))
              GdipRenderTxtRotated(wParam, ((rc\right-rc\left)/2), pos, *graph\ruler()\label, txtColour, *graph\ruler()\font, 0)
            Else
              drawLine(wParam, rc\left, pos, rc\right, pos, *graph\ruler()\thickness, *graph\ruler()\colour, *graph\ruler()\style, #False)
            EndIf
          EndIf
          
        EndIf

      Next
      
      ;- **** render feature labels
      ForEach *graph\label()
        
        x.f = *graph\label()\x
        y.f = *graph\label()\y
        x = (grwidth/(xAxisMax-xAxisMin))*(x-xAxisMin)
        y = -((grheight/(yAxisMax-yAxisMin))*(y-yAxisMin))
        y + grheight
        
        x + *graph\xOffset
        y + *graph\yOffset
        
        x = Round(x, #PB_Round_Down)
        y = Round(y, #PB_Round_Down)
        
        ; calc bounding box for rendering only what's visible
        GdipCalcTxt(wParam, *graph\label()\label, @w, @h, *graph\label()\font)
        trc.RECT\left = x-(w/2)
        trc\top = y-(w/2)
        trc\right = x+(w/2)
        trc\bottom = y+(w/2)
        
        If IntersectRect_(trc, rc, trc) <> #False
          GdipRenderTxtRotated(wParam, x, y, *graph\label()\label, *graph\label()\colour, *graph\label()\font, *graph\label()\angle)
        EndIf
        
      Next
      
      ;- **** render line floating labels
      ForEach label()
        If label()\label <> ""
          a = Alpha(label()\colour)
          r = Blue(label()\colour)/2
          g = Green(label()\colour)/2
          b = Red(label()\colour)/2
          colour = MakeColour(a, r, g, b)
          padding = GL_metric(GL_DPI)\DPI_Ratio*2
          x = label()\x+padding
          y = label()\y
          w = label()\width+(padding*2)
          h = label()\height+(padding*2)
          r = 10
          
          ; calc bounding box for rendering only what's visible
          trc.RECT\left = x
          trc\top = y
          trc\right = x+w
          trc\bottom = y+h
          If IntersectRect_(trc, rc, trc) <> #False
            GdipRoundRect(wParam, x, y, w, h, r, 2, MakeColour(a, 255, 255, 255), colour)
            x+padding
            y+padding
            GdipRenderTxt(wParam, x, y, label()\label, colour, *graph\lineFont)
          EndIf
        EndIf
      Next
      
      ;- **** render zoom box
      If *graph\zoomBox = #True
        
        zsx = *graph\zoomBoxStartX
        zsy = *graph\zoomBoxStartY
        zx = *graph\zoomBoxX
        zy = *graph\zoomBoxY
        If zx < zsx
          tz = zsx
          zsx = zx
          zx = tz
        EndIf
        If zy < zsy
          tz = zsy
          zsy = zy
          zy = tz
        EndIf
        rectangle(wParam, zsx, zsy, zx-zsx, zy-zsy, #GL_ZoomBoxThickness, #GL_ZoomBoxFillColour, #GL_ZoomBoxOutlineColour, #True)
        
      EndIf
      
      ;RestoreDC_(wParam, rsdc) ; previous dc states restored, e.g. clipping
      
    ; handle mouse wheel zooming of graph
    Case #WM_MOUSEWHEEL
      
      scrollAmount.b = HWORD(wParam)
      scrollAmount / 120
      ;Debug "mousewheel: "+Str(scrollAmount)
      
      If scrollAmount > 0 ; mouse wheel scrolled up
        
        zoom.d = #GL_ZoomFactor
        
        ; if zoomed beyond max floating point precision then exit
        If Len(StringField(StrD(*graph\cxAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision
          ProcedureReturn #False
        EndIf
        
        GetClientRect_(hwnd, rc.RECT)
        grwidth = rc\right
        grheight = rc\bottom
        GetCursorPos_(p.POINT)
        MapWindowPoints_(0, hwnd, p, 1)
        ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
        pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
        ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
        pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        txMin.d = *graph\xAxisMin
        txMax.d = *graph\xAxisMax
        tyMin.d = *graph\yAxisMin
        tyMax.d = *graph\yAxisMax
        
        *graph\xAxisMin = ((*graph\xAxisMin-pointx)/zoom)+pointx
        *graph\xAxisMax = ((*graph\xAxisMax-pointx)/zoom)+pointx
        
        *graph\yAxisMin = ((*graph\yAxisMin-pointy)/zoom)+pointy
        *graph\yAxisMax = ((*graph\yAxisMax-pointy)/zoom)+pointy
        
        ; calc axis ticks
        tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
        xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
        yticks = Round(grheight/tickSpacing, #PB_Round_Down)
        oxticks = xticks
        oyticks = yticks
        xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
        yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
        
        txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
        *graph\cxAxisMin = ValD(txt)
        If xticks <= 1
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
        Else
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
        EndIf
        *graph\cxAxisMax = ValD(txt)
        txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
        *graph\cyAxisMin = ValD(txt)
        If yticks <= 1
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
        Else
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
        EndIf
        *graph\cyAxisMax = ValD(txt)
        
        If Len(StringField(StrD(*graph\cxAxisMin), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cxAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMin), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision Or Len(StringField(StrD(*graph\cyAxisMax), 2, ".")) > #GL_ZoomMaxFloatingPointPrecision
          *graph\xAxisMin = txMin
          *graph\xAxisMax = txMax
          *graph\yAxisMin = tyMin
          *graph\yAxisMax = tyMax
          ProcedureReturn #False
        EndIf
          
        ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
        npointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)

        ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
        npointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        rx.d = Round((pointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
        ry.d = Round((pointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
        
        rx2.d = Round((npointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
        ry2.d = Round((npointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
        
        *graph\xOffset - (rx-rx2)
        *graph\yOffset + (ry-ry2)
        
        setGraphToolTipXY(*graph, hwnd)
        
        RefreshGraph(*graph\handle)
        
      ElseIf scrollAmount < 0 ; mouse wheel scrolled down
        
        zoom.d = #GL_ZoomFactor
        
        ; if zoomed beyond max 
        If *graph\cxAxisMax > Pow(2, 52) Or *graph\cyAxisMax > Pow(2, 52)
          ProcedureReturn #False
        EndIf
        
        GetClientRect_(hwnd, rc.RECT)
        grwidth = rc\right
        grheight = rc\bottom
        GetCursorPos_(p.POINT)
        MapWindowPoints_(0, hwnd, p, 1)
        ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
        pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
        ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
        pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        *graph\xAxisMin = ((*graph\xAxisMin-pointx)*zoom)+pointx
        *graph\xAxisMax = ((*graph\xAxisMax-pointx)*zoom)+pointx
        
        *graph\yAxisMin = ((*graph\yAxisMin-pointy)*zoom)+pointy
        *graph\yAxisMax = ((*graph\yAxisMax-pointy)*zoom)+pointy
        
        
        ; calc axis ticks
        tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
        xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
        yticks = Round(grheight/tickSpacing, #PB_Round_Down)
        oxticks = xticks
        oyticks = yticks
        xticks = getLoose_labelTicks(*graph\xAxisMin, *graph\xAxisMax, xticks)
        yticks = getLoose_labelTicks(*graph\yAxisMin, *graph\yAxisMax, yticks)
        
        txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, 0)
        *graph\cxAxisMin = ValD(txt)
        If xticks <= 1
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks)
        Else
          txt.s = loose_label(*graph\xAxisMin, *graph\xAxisMax, oxticks, xticks-1)
        EndIf
        *graph\cxAxisMax = ValD(txt)
        txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, 0)
        *graph\cyAxisMin = ValD(txt)
        If yticks <= 1
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks)
        Else
          txt.s = loose_label(*graph\yAxisMin, *graph\yAxisMax, oyticks, yticks-1)
        EndIf
        *graph\cyAxisMax = ValD(txt)
        
        ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
        npointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)

        ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
        npointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        rx.d = Round((pointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
        ry.d = Round((pointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
        
        rx2.d = Round((npointx-*graph\cxAxisMin)*(grwidth/Abs(*graph\cxAxisMax-*graph\cxAxisMin))+*graph\xOffset, #PB_Round_Nearest)
        ry2.d = Round((npointy-*graph\cyAxisMin)*(grheight/Abs(*graph\cyAxisMax-*graph\cyAxisMin))+*graph\yOffset, #PB_Round_Nearest)
        
        *graph\xOffset - (rx-rx2)
        *graph\yOffset + (ry-ry2)
        
        setGraphToolTipXY(*graph, hwnd)
        
        RefreshGraph(*graph\handle)
        
      EndIf
      
    ; handle scrollling / zoombox of graph, left click
    Case #WM_LBUTTONDOWN
      
      If *graph\contentHandle = GetParent_(hwnd)
        
        If Not wParam & #MK_CONTROL
          
          updateGraphDragScrolling(*graph, hwnd, #True)
          
        ElseIf wParam & #MK_CONTROL
        
          updateGraphDragZoomBox(*graph, hwnd, #True)
          
        EndIf
        
      EndIf
      
    ; handle scrollling / zoombox of graph, left click release
    Case #WM_LBUTTONUP
      
      If *graph\contentHandle = GetParent_(hwnd)
       
        updateGraphDragScrolling(*graph, hwnd, -1)
        updateGraphDragZoomBox(*graph, hwnd, -1)
        
      EndIf

    ; handle scrollling of graph and zoom box, mouse move drag
    Case #WM_MOUSEMOVE
      
      GL_ContextMenuHwnd = 0 ; hack to stop menu from appearing twice if mouse is over parent panelex when deselected, fucking dodgy windows
      
      If *graph\contentHandle = GetParent_(hwnd) And wParam & #MK_LBUTTON
        
        updateGraphDragScrolling(*graph, hwnd)
        updateGraphDragZoomBox(*graph, hwnd)
      
      ElseIf *graph\contentHandle = GetParent_(hwnd)
        
        setGraphToolTipXY(*graph, hwnd)
        
      EndIf
      
    ; handle right click context menu
    Case #WM_RBUTTONUP
      
      If *graph\contentHandle = GetParent_(hwnd)
        
        GetCursorPos_(p.POINT)
        contextMenu(*graph, hwnd, p\x, p\y)
        
      EndIf
      
    Case #WM_COMMAND
      
      ;processMenuMessages(*graph, hwnd, message, wParam, lParam)
      
    Case #WM_SIZE
      
      updateLegend(*graph)
      
  EndSelect
  
EndProcedure

Procedure GraphLegendCallback(hwnd, message, wParam, lParam)
  
  *graph.GL_Graphs = GetWindowLongPtr_(hwnd, #GWL_USERDATA)
  If *graph = #Null
    *graph.GL_Graphs = GetWindowLongPtr_(GetParent_(hwnd), #GWL_USERDATA)
  EndIf
  
  If *graph = #Null
    ProcedureReturn #False
  EndIf
  
  Select message
      
    ; intercept max window size and alter so high DPI printing is possible  
    Case #WM_GETMINMAXINFO
      
      *pmmi.MINMAXINFO = lParam
      If *pmmi\ptMaxTrackSize\x < GL_Metric(GL_DPI)\printWidth
        *pmmi\ptMaxTrackSize\x = GL_Metric(GL_DPI)\printWidth
      EndIf
      If *pmmi\ptMaxTrackSize\y < GL_Metric(GL_DPI)\printHeight
        *pmmi\ptMaxTrackSize\y = GL_Metric(GL_DPI)\printHeight
      EndIf  
    
    Case #WM_PAINT
      
      GetClientRect_(*graph\legendHandle, rc.RECT)
      
      rectangle(wParam, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, 1, MakeColour(255, 255, 255, 255), MakeColour(255, 0, 0, 0), 0)
      
      keyPadding = GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyPadding
      padding = GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendPadding
      x = padding
      y = padding
      
      ForEach *graph\Line()

        If *graph\Line()\showOnLegend = #True And *graph\Line()\label <> ""

          GdipCalcTxt(wParam, *graph\Line()\label, @w, @h, *graph\legendFont)
          
          If x + (GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth) + w > (rc\right-rc\left)-padding
            x = padding
            y + h
          EndIf
          
          drawLine(wParam, x+keyPadding, y+(h/2), x+(GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth)-keyPadding, y+(h/2), *graph\Line()\thickness, *graph\Line()\colour, *graph\Line()\style, 0)
          size = *graph\Line()\nodeSize
          size * GL_metric(GL_DPI)\DPI_Ratio
          xpos.f = Round(x+keyPadding+(((GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth)-(keyPadding/2))/2)-(size/2), #PB_Round_Up)
          drawNode(wParam, xpos, y+(h/2), *graph\Line()\nodeType, *graph\Line()\colour, *graph\Line()\nodeSize)
          GdipRenderTxt(wParam, x+(GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth), y, *graph\Line()\label, MakeColour(255, 0, 0, 0), *graph\legendFont)

          x + (GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth) + w

        EndIf
        
      Next
      
      
  EndSelect
  
EndProcedure

Procedure GraphDialogCallback(hwnd, message, wParam, lParam)
  
  *graph.GL_Graphs = GetWindowLongPtr_(hwnd, #GWL_USERDATA)
  
  Select message
      
      ; handle selection of menu items and buttons
    Case #WM_COMMAND
      
      If HWord(wParam) = 0 ; is an ID
        
        ; ranges dialog window
        If *graph\dialog_Ranges\PBWindowID <> #Null And hwnd = WindowID(*graph\dialog_Ranges\PBWindowID)
          Select lParam
              
            Case GadgetID(*graph\dialog_Ranges\gadget[#GL_Ranges_Button_Apply])
          
              valid = #True
              txt$ = GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmin])
              If txt$ <> ""
                If IsNumericFloat(txt$) = #False
                  valid = #False
                  ShowWarningMsg("X axis minimum range value must be a valid number!")
                EndIf
              Else
                valid = #False
                ShowWarningMsg("Please set the X axis minimum range value!")
              EndIf
              If valid = #True
                txt$ = GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmax])
                If txt$ <> ""
                  If IsNumericFloat(txt$) = #False
                    valid = #False
                    ShowWarningMsg("X axis maximum range value must be a valid number!")
                  EndIf
                Else
                  valid = #False
                  ShowWarningMsg("Please set the X axis maximum range value!")
                EndIf
              EndIf
              If valid = #True
                txt$ = GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymin])
                If txt$ <> ""
                  If IsNumericFloat(txt$) = #False
                    valid = #False
                    ShowWarningMsg("Y axis minimum range value must be a valid number!")
                  EndIf
                Else
                  valid = #False
                  ShowWarningMsg("Please set the Y axis minimum range value!")
                EndIf
              EndIf
              If valid = #True
                txt$ = GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymax])
                If txt$ <> ""
                  If IsNumericFloat(txt$) = #False
                    valid = #False
                    ShowWarningMsg("Y axis maximum range value must be a valid number!")
                  EndIf
                Else
                  valid = #False
                  ShowWarningMsg("Please set the Y axis maximum range value!")
                EndIf
              EndIf
              
              If valid = #True
                *graph\xAxisMin = ValD(GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmin]))
                *graph\xAxisMax = ValD(GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmax]))
                *graph\yAxisMin = ValD(GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymin]))
                *graph\yAxisMax = ValD(GetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymax]))
                *graph\xOffset = 0
                *graph\yOffset = 0
                RefreshGraph(*graph\handle)
                CloseWindow(*graph\dialog_Ranges\PBWindowID)
                *graph\dialog_Ranges\PBWindowID = #Null
              EndIf
              
            Case GadgetID(*graph\dialog_Ranges\gadget[#GL_Ranges_Button_Cancel])
              
              CloseWindow(*graph\dialog_Ranges\PBWindowID)
              *graph\dialog_Ranges\PBWindowID = #Null
  
          EndSelect
        EndIf
        
        ; graph quality dialog window
        If *graph\dialog_Quality\PBWindowID <> #Null And hwnd = WindowID(*graph\dialog_Quality\PBWindowID)
          Select lParam
              
            Case GadgetID(*graph\dialog_Quality\gadget[#GL_Quality_Button_Okay])
              
              For n = #GL_DPI_Window To #GL_Max_DPI_Resolutions-1
                If GetGadgetState(*graph\dialog_Quality\dynamic(n)) = #True
                  GL_DefaultPrintDPI = n
                EndIf
              Next
              
              CloseWindow(*graph\dialog_Quality\PBWindowID)
              *graph\dialog_Quality\PBWindowID = #Null
              
              If *graph\dialog_Quality\command = GL_Command_Save
                
                SaveGraph(*graph\handle, "", GL_DefaultPrintDPI)
                
              ElseIf *graph\dialog_Quality\command = GL_Command_Print
                
                PrintGraph(*graph\handle, GL_DefaultPrintDPI)
                
              ElseIf *graph\dialog_Quality\command = GL_Command_Copy
                
                CopyGraphToClipboard(*graph\handle, GL_DefaultPrintDPI)
                
              EndIf
              
            Case GadgetID(*graph\dialog_Quality\gadget[#GL_Quality_Button_Cancel])
              
              CloseWindow(*graph\dialog_Quality\PBWindowID)
              *graph\dialog_Quality\PBWindowID = #Null
  
          EndSelect
        EndIf
        
      EndIf
      
    Case #WM_CLOSE
      
      ; close set ranges dialog
      If *graph\dialog_Ranges\PBWindowID <> #Null And hwnd = WindowID(*graph\dialog_Ranges\PBWindowID)
        CloseWindow(*graph\dialog_Ranges\PBWindowID)
        *graph\dialog_Ranges\PBWindowID = #Null
      EndIf
      
      ; close set graph quality dialog
      If *graph\dialog_Quality\PBWindowID <> #Null And hwnd = WindowID(*graph\dialog_Quality\PBWindowID)
        CloseWindow(*graph\dialog_Quality\PBWindowID)
        *graph\dialog_Quality\PBWindowID = #Null
      EndIf
      
  EndSelect
  
  ProcedureReturn #PB_ProcessPureBasicEvents
  
EndProcedure

;-
;- ----| Private Functions
Procedure RGBToHSV(color, *colorspace.hsv)

  ; ***************************************************************************
  ;
  ; Function: Converts an RGB color space to HSV
  ;
  ; Returns:  A structure containing the HSV values
  ;
  ; ***************************************************************************

  Protected r.f, g.f, b.f
  Protected r_temp.l, g_temp.l, b_temp.l
  Protected delta.f, min.f

  r_temp = FastRed(color)
  g_temp = FastGreen(color)
  b_temp = FastBlue(color)

  r = r_temp / 255
  g = g_temp / 255
  b = b_temp / 255
 
  If r < g
    min = r
  Else
    min = g
  EndIf
  If b < min
    b = min
  EndIf
 
  If r > g
    *colorspace\v = r
  Else
    *colorspace\v = g
  EndIf
  If b > *colorspace\v
    *colorspace\v = b
  EndIf
 
  delta = *colorspace\v - min

  If *colorspace\v = 0
    *colorspace\s = 0
  Else
    *colorspace\s = delta / *colorspace\v
  EndIf

  If *colorspace\s = 0
    *colorspace\h = 0
  Else
    If r = *colorspace\v
      *colorspace\h = 60 * (g - b) / delta
    ElseIf g = *colorspace\v
      *colorspace\h = 120 + 60 * (b - r) / delta
    ElseIf b = *colorspace\v
      *colorspace\h = 240 + 60 * (r - g) / delta
    EndIf
    If *colorspace\h < 0
      *colorspace\h + 360
    EndIf
  EndIf
   
EndProcedure

Procedure.f Max3F(a.f, b.f, c.f)
  If a > b
    If a > c
      ProcedureReturn a
    Else
      ProcedureReturn c
    EndIf
  Else
    If b > c
      ProcedureReturn b
    Else
      ProcedureReturn c
    EndIf
  EndIf
EndProcedure

Procedure.f Min3F(a.f, b.f, c.f)
  If a < b
    If a < c
      ProcedureReturn a
    Else
      ProcedureReturn c
    EndIf
  Else
    If b < c
      ProcedureReturn b
    Else
      ProcedureReturn c
    EndIf
  EndIf
EndProcedure

; change color to HSL
ProcedureDLL.l RGB2HSL(*c.Color) ; converts RGB-color *c to HSL and returns *c. No check if RGB is made!
  Protected r.f, g.f, b.f, max.f, min.f, delta.f
  r = *c\r
  g = *c\g
  b = *c\b
 
  max = Max3F(r,g,b)
  min = Min3F(r,g,b)
  delta = max - min
 
  If delta <> 0.0
    ; get lightness
    *c\l = (max + min) / 2.0
   
    ; get saturation
    If *c\l <= 0.5
      *c\s = delta/(max+min)
    Else
      *c\s = delta/(2-max-min)
    EndIf
   
    ; get hue
    If r = max
      *c\h = (g-b)/delta
    ElseIf g = max
      *c\h = 2.0 + (b-r)/delta
    ElseIf b = max
      *c\h = 4.0 + (r-g)/delta
    EndIf
   
    *c\h * 60.0
   
    If *c\h<0.0
      *c\h + 360.0
    EndIf
  Else
    ; it's black
    *c\s = 0
    *c\h = 0 ; *c\h is even undefined
  EndIf
 
  *c\type = #COLOR_HSL
 
  ProcedureReturn *c
EndProcedure

Procedure.f HSL2RGBHelper(q1.f, q2.f, h.f)
  If h >= 360.0
    h - 360.0
  ElseIf h < 0.0
    h + 360.0
  EndIf
 
  If h < 60.0
    ProcedureReturn q1+(q2-q1)*h/60.0
  ElseIf h < 180.0
    ProcedureReturn q2
  ElseIf h < 240.0
    ProcedureReturn q1+(q2-q1)*(240.0-h)/60.0
  Else
    ProcedureReturn q1
  EndIf
EndProcedure

ProcedureDLL.l HSL2RGB(*c.Color) ; converts HSL-color *c to RGB and returns *c. No check if HSL is made!
  Protected h.f, l.f, s.f
  Protected f.f, p1.f, p2.f, t.f
  Protected i.l
 
  h = *c\h
  l = *c\l
  s = *c\s
 
  If l<=0.5
    p2 = l*(1.0+s)
  Else
    p2 = l+s-l*s
  EndIf
 
  p1 = 2.0*l-p2
 
  If s=0.0
    ; it's a gray-tone
    *c\r = l
    *c\g = l
    *c\b = l
  Else
    *c\r = HSL2RGBHelper(p1, p2, h+120.0)
    *c\g = HSL2RGBHelper(p1, p2, h)
    *c\b = HSL2RGBHelper(p1, p2, h-120.0)
  EndIf
 
  *c\type = #COLOR_RGB
 
  ProcedureReturn *c
EndProcedure

Procedure GetScreenDPI(horiz.b=#False)
  ; Get screen dots per inch vertically (default) or horizontally
  Protected hdc, dpi
  hdc = GetDC_(0) ; Desktop device context
  If horiz
    dpi = GetDeviceCaps_(hdc, #LOGPIXELSX)
  Else
    dpi = GetDeviceCaps_(hdc, #LOGPIXELSY)
  EndIf
  ReleaseDC_(0, hdc)
  ProcedureReturn dpi
EndProcedure 

Procedure GL_LoadFont(Name.s, PointSize.l, Flags.i)
  
  If flags & #Font_Antialiased
    quality = #ANTIALIASED_QUALITY
    flags = flags &~ #ANTIALIASED_QUALITY
  ElseIf flags & #Font_NonAntialiased
    quality = #NONANTIALIASED_QUALITY
    flags = flags &~ #NONANTIALIASED_QUALITY
  ElseIf flags & #Font_Cleartype
    quality = #CLEARTYPE_QUALITY
    flags = flags &~ #CLEARTYPE_QUALITY
  ElseIf flags & #Font_Draft
    qaulity = #DRAFT_QUALITY
    flags = flags &~ #DRAFT_QUALITY
  EndIf
  
  If flags >= #FW_BOLD And flags <= #FW_BOLD+#Font_StrikeOut
    weight = #FW_BOLD
    flags = flags &~ #FW_BOLD
  EndIf
  
  If flags & #Font_Bold
    weight = #FW_BOLD
    flags = flags &~ #Font_Bold
  EndIf
  
  If flags & #Font_Italic
    italic = #True
    flags = flags &~ #Font_Italic
  EndIf
  
  If flags & #Font_Underline
    underline = #True
    flags = flags &~ #Font_Underline
  EndIf
  
  If flags & #Font_StrikeOut
    strikeout = #True
    flags = flags &~ #Font_StrikeOut
  EndIf
  
  If flags = 400
    flags = 0
  EndIf
  
  If flags & #PB_Font_Bold
    weight = #FW_BOLD
  EndIf
  If flags & #PB_Font_Italic
    italic = #True
  EndIf
  
  PushListPosition(GL_Fonts())
  *GL_FontHandle.GL_Fonts = AddElement(GL_Fonts())
  *GL_FontHandle\Name = Name
  *GL_FontHandle\PointSize = PointSize
  *GL_FontHandle\Flags = Flags
  
  For n = 0 To #GL_Max_DPI_Resolutions-1
    nHeight.f = -MulDiv_(PointSize, GL_Metric(n)\DPI, 72)
    handle = CreateFont_(nHeight, 0, 0, 0, weight, italic, underline, strikeout, #DEFAULT_CHARSET, #OUT_DEFAULT_PRECIS, #CLIP_DEFAULT_PRECIS, quality, #VARIABLE_PITCH, Name)
    If handle <> #False
      *GL_FontHandle\HFONT[n] = handle
    Else
      error = #True
      Break
    EndIf
  Next
  
  If error = #True
    For i = 0 To n
      FreeFontEx(*GL_FontHandle\HFONT[i])
    Next
    DeleteElement(GL_Fonts())
  Else
    *handle = *GL_FontHandle
  EndIf
  PopListPosition(GL_Fonts())
  
  ProcedureReturn *handle
  
EndProcedure

Procedure GL_FreeFont(*Handle.GL_Fonts)
  
  If *Handle <> #Null
    
    PushListPosition(GL_Fonts())
    ChangeCurrentElement(GL_Fonts(), *Handle)
    For n = 0 To #GL_Max_DPI_Resolutions-1
      FreeFontEx(*Handle\HFONT[n])
    Next
    DeleteElement(GL_Fonts())
    PopListPosition(GL_Fonts())
    
    ProcedureReturn #True
    
  EndIf
  
  ProcedureReturn #False
  
EndProcedure

Procedure GL_Font(*Handle.GL_Fonts)
  
  If *Handle = #Null
    
    *handle = GL_Default_font
 
  EndIf
  
  ProcedureReturn *Handle\HFONT[GL_DPI]
  
EndProcedure

; 
; Procedure setDPI(newDPI)
;   
;   DPI = newDPI
;   
; ;   ; change title font
; ;   SetTextControlExFont(#title, GL_metric(GL_DPI)\titleFont, #False)
; ;   
; ;   ; iterate through all columns and change fonts
; ;   PushListPosition(column())
; ;   ForEach column()
; ;     
; ;     SetTextControlExFont(column()\handle, GL_metric(GL_DPI)\columnHeaderFont, #False)
; ;     
; ;     ForEach column()\row()
; ;       
; ;       If column()\row()\textHandle <> #Null
; ;         
; ;         SetTextControlExFont(column()\row()\textHandle, GL_metric(GL_DPI)\rowFont, #False)
; ;         
; ;       EndIf
; ;       
; ;     Next
; ;     
; ;     If ListSize(column()\sub()) > 0
; ;       PushListPosition(column()\sub())
; ;       ForEach column()\sub()
; ;         
; ;         ForEach column()\sub()\row()
; ;           
; ;           If column()\sub()\row()\textHandle <> #Null
; ;             
; ;             SetTextControlExFont(column()\sub()\row()\textHandle, GL_metric(GL_DPI)\rowFont, #False)
; ;             
; ;           EndIf
; ;           
; ;         Next
; ;         
; ;         SetTextControlExFont(column()\sub()\handle, GL_metric(GL_DPI)\columnHeaderFont, #False)
; ;         
; ;       Next
; ;       PopListPosition(column()\sub())
; ;     EndIf
; ;     
; ;   Next
; ;   PopListPosition(column())
;   
; EndProcedure

Procedure.u GL_generateUniqueID_wordUnsigned()
  Static uniqueID.u = $FFFF
  
  uniqueID = uniqueID - 1
  
  ProcedureReturn uniqueID
EndProcedure

Procedure ShowErrorMsg(text.s, flags = 0)
  
  If flags = 0
    flags = #PB_MessageRequester_Ok
  EndIf
  
  ProcedureReturn MessageRequester("Error!", text, #MB_ICONERROR|flags)
  
EndProcedure

Procedure ShowWarningMsg(text.s, flags = 0)
  
  If flags = 0
    flags = #PB_MessageRequester_Ok
  EndIf
  
  ProcedureReturn MessageRequester("Warning!", text, #MB_ICONWARNING|flags)
  
EndProcedure

Procedure ShowQuestionMsg(text.s, flags = 0)
  
  If flags = 0
    flags = #PB_MessageRequester_YesNo
  EndIf
  ProcedureReturn MessageRequester("", text, #MB_ICONQUESTION|flags)
  
EndProcedure

Procedure rectangle(dc, x.f, y.f, width.f, height.f, thickness.f, fillColour, outlineColour, outside.b)
  
  size.f = GL_Metric(GL_DPI)\DPI_Ratio*thickness
  
  ; pen thickness is centred so need to offset to correct pixel
  x + Round(size/2, #PB_Round_Down)
  y + Round(size/2, #PB_Round_Down)
  width - (size)
  height - (size)
  
  If outside = #True
    x - size
    y - size
    width + (size*2)
    height + (size*2)
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  
  GdipCreatePen1(outlineColour, size, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  
  GdipCreateSolidFill(fillColour, @brush)
  
  GdipFillRectangle(GraphicObject, brush, x, y, width, height)
  GdipDrawRectangle(GraphicObject, pen, x, y, width, height)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
  GdipDeleteBrush(brush)
 
EndProcedure

Procedure drawRectangle(dc, x.f, y.f, width.f, height.f, thickness.f, outlineColour, outside.b)
  
  size.f = GL_Metric(GL_DPI)\DPI_Ratio*thickness
  
  If outside = #True
    ; pen thickness is centred so need to offset to correct pixel
    x + Round(size/2, #PB_Round_Down)
    y + Round(size/2, #PB_Round_Down)
    width - (size)
    height - (size)
    x - size
    y - size
    width + (size*2)
    height + (size*2)
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  
  GdipCreatePen1(outlineColour, size, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  
  GdipDrawRectangle(GraphicObject, pen, x, y, width, height)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
 
EndProcedure

Procedure fillRectangle(dc, x.f, y.f, width.f, height.f, fillColour)
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  ;CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
  CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3) ; SmoothingModeNone
  
  GdipCreateSolidFill(fillColour, @brush)
  
  GdipFillRectangle(GraphicObject, brush, x, y, width, height)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  GdipDeleteBrush(brush)
 
EndProcedure

Procedure GdipRoundRect(dc, x, y, width, height, radious, thickness, fillColourARGB, outlineColourARGB)
  
  size.f = GL_metric(GL_DPI)\DPI_Ratio*thickness
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh
  
  GdipCreatePen1(outlineColourARGB, size, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  
  x1 = x
  y1 = y
  x2 = x+width
  y2 = y+height
  
  GdipCreatePath(0, @path)
  GdipAddPathArc(path, x1, y1, radious, radious, 180, 90)
  GdipAddPathArc(path, x2-radious, y1, radious, radious, 270, 90)
  GdipAddPathArc(path, x2-radious, y2-radious, radious, radious, 0, 90)
  GdipAddPathArc(path, x1, y2-radious, radious, radious, 90, 90)
  GdipClosePathFigure(path)
  
  GdipCreateSolidFill(fillColourARGB, @brush)
  GdipFillPath(GraphicObject, brush, path)
  GdipDrawPath(GraphicObject, pen, path)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
  GdipDeleteBrush(brush)
  GdipDeletePath(path)
  
EndProcedure

; Procedure AngleEndPoint(x,y,Ang,LineLenght,*p.Point)
;     *p\x= x+LineLenght*Cos(Ang*#FIB)
;     *p\y= y+LineLenght*Sin(Ang*#FIB)
; EndProcedure

;Procedure AngLine(DC,x,y,Ang.f,LineLenght,LineWidth,RGB)
;    x2 = x+LineLenght*Cos(Ang*#FIB)
;    y2 = y+LineLenght*Sin(Ang*#FIB)
;    APILine(DC,x,y,x2 ,y2,LineWidth,RGB)
;EndProcedure

; Procedure GetANG(x1,y1,x2,y2)
;     a = x2-x1
;     b = y2-y1
;     c.f = Sqr(a*a+b*b)
;     Ang = ACos(a/c)*#RAD
;     If y1 < y2 : ProcedureReturn 360-Ang : EndIf
;     ProcedureReturn Ang
; EndProcedure

Procedure drawLine(dc, x.f, y.f, x2.f, y2.f, thickness.f, ARGBColour, dashStyle = 0, highQuality = #True)
  
  size.f = GL_metric(GL_DPI)\DPI_Ratio*thickness
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  If highQuality = #True
    CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
    CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh
  Else
    CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
    CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
    CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3) ; SmoothingModeNone
  EndIf
    
  GdipCreatePen1(ARGBColour, size, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  If dashStyle <> 0
    GdipSetPenDashStyle(pen, dashStyle)
  EndIf
  CallFunctionFast(*GdipDrawLine, GraphicObject, pen, x, y, x2, y2)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
 
EndProcedure

Procedure drawHLine(dc, x.f, y.f, width.f, thickness.f, ARGBColour, AutoDPI = #False)
  
  If AutoDPI = #True
    thickness = GL_metric(GL_DPI)\DPI_Ratio*thickness
  EndIf
  fillRectangle(dc, x, y, width, thickness, ARGBColour)

EndProcedure

Procedure drawVLine(dc, x.f, y.f, height.f, thickness.f, ARGBColour, AutoDPI = #False)
  
  If AutoDPI = #True
    thickness = GL_metric(GL_DPI)\DPI_Ratio*thickness
  EndIf
  fillRectangle(dc, x, y, thickness, height, ARGBColour)
  
EndProcedure

Procedure drawHLineDashed(dc, x.f, y.f, width.f, thickness.f, ARGBColour, dashStyle = 1, AutoDPI = #False)
  
  If AutoDPI = #True
    thickness = GL_metric(GL_DPI)\DPI_Ratio*thickness
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
  CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3) ; SmoothingModeNone
  
  GdipCreatePen1(ARGBColour, thickness, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  GdipSetPenDashStyle(pen, dashStyle)
  CallFunctionFast(*GdipDrawLine, GraphicObject, pen, x, y, x+width, y)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)

EndProcedure

Procedure drawVLineDashed(dc, x.f, y.f, height.f, thickness.f, ARGBColour, dashStyle = 1, AutoDPI = #False)
  
  If AutoDPI = #True
    thickness = GL_metric(GL_DPI)\DPI_Ratio*thickness
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
  CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3) ; SmoothingModeNone
  
  GdipCreatePen1(ARGBColour, thickness, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  GdipSetPenDashStyle(pen, dashStyle)
  CallFunctionFast(*GdipDrawLine, GraphicObject, pen, x, y, x, y+height)
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)

EndProcedure

; Global gInsctX.d = 0.00
; Global gInsctY.d = 0.00
; Procedure LineIntersect(x1.d,y1.d, x2.d,y2.d, x3.d,y3.d, x4.d,y4.d)
;   Define DBL_EPSILON = 0.0001
;   Protected mua.d, mub.d,denom.d,numera.d,numerb.d
;   Shared gInsctX
;   Shared gInsctY
;   
;   denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
;   numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)
;   numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)
;   
;   ;Are the lines coincident?
;   If( (Abs(numera) < DBL_EPSILON) And (Abs(numerb) < DBL_EPSILON) And (Abs(denom) < DBL_EPSILON) )
;     
;     gInsctX = (x1 + x2) / 2
;     gInsctY = (y1 + y2) / 2
;     
;     ProcedureReturn(#True)
;   EndIf
;   
;   ;Are the lines parallel?
;   If (Abs(denom) < EPS)
;     
;     gInsctX = 0
;     gInsctY = 0
;     ProcedureReturn(#False);
;   EndIf
;   
;   ;Is the intersection along the line segments?
;   mua = numera / denom
;   mub = numerb / denom
;   If (mua < 0 Or mua > 1 Or mub < 0 Or mub > 1)
;     
;     gInsctX = 0
;     gInsctY = 0
;     ProcedureReturn(#False)
;   EndIf
;   
;   gInsctX = x1 + mua * (x2 - x1)
;   gInsctY = y1 + mua * (y2 - y1)
;   
;   ProcedureReturn(#True)
; 
; EndProcedure

Procedure drawLines(dc, *rc.RECT, Array points.POINTF(1), thickness.f, ARGB, dashStyle)
  
  size.f = GL_metric(GL_DPI)\DPI_Ratio*thickness
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh
  
  GdipCreatePen1(ARGB, size, 2, @pen)
  GdipSetPenStartCap(pen, 2)
  GdipSetPenEndCap(pen, 2)
  GdipSetPenDashStyle(pen, dashStyle)
  
  GdipDrawLines(GraphicObject, pen, points(), ArraySize(points()))
  
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)

;Dim pnt.POINTF(ArraySize(points()))
;   ; remove points that are not visibly connected
;   i = 0
;   j = ArraySize(points())-1
;   
;   For n = 0 To j
;     
;     clip = #False
;     p.POINT : p\x = points(n)\x : p\y = points(n)\y
;     If PtInRect_(*rc, PeekQ(p)) = #False
;       If n > 0 And n < j
;         pp.POINT : pp\x = points(n-1)\x : pp\y = points(n-1)\y
;         np.POINT : np\x = points(n+1)\x : np\y = points(n+1)\y
;         If PtInRect_(*rc, PeekQ(pp)) = #False And PtInRect_(*rc, PeekQ(np)) = #False
;           Debug "clip point "+n
;           clip = #True
;         EndIf
;       ElseIf n = 0 And n < j
;         np.POINT : np\x = points(n+1)\x : np\y = points(n+1)\y
;         If PtInRect_(*rc, PeekQ(np)) = #False
;          Debug "clip point "+n
;          clip = #True
;         EndIf
;       ElseIf n > 0 And n = j
;         pp.POINT : pp\x = points(n-1)\x : pp\y = points(n-1)\y
;         If PtInRect_(*rc, PeekQ(pp)) = #False
;          Debug "clip point "+n
;          clip = #True
;         EndIf
;       EndIf
;     EndIf
;     
;     If clip = #False
;       ReDim pnt.POINTF(i+1)
;       pnt(i)\x = points(n)\x
;       pnt(i)\y = points(n)\y
;       i + 1
;     EndIf
;     
;   Next
; 
;   GdipCreatePen1(ARGB, size, 2, @pen)
;   GdipSetPenStartCap(pen, 2)
;   GdipSetPenEndCap(pen, 2)
;   GdipSetPenDashStyle(pen, dashStyle)
;   GdipDrawLines(GraphicObject, pen, pnt(), ArraySize(pnt()))
;   
;   CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
;   CallFunctionFast(*GdipDeletePen, pen)
 
EndProcedure

Procedure drawNode(dc, x.f, y.f, nodeType, colour, size.f)
  
  size.f = GL_metric(GL_DPI)\DPI_Ratio*size
  thickness.f = GL_metric(GL_DPI)\DPI_Ratio*2 ; 2 pixel thickness of pen
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh
  
  colour = MakeColour(255, Int(Blue(colour)/3), Int(Green(colour)/3), Int(Red(colour)/3))
  GdipCreateSolidFill(colour, @brush)
  GdipCreatePen1(colour, thickness, 2, @pen)
  
  Select nodeType
          
      Case #GL_Line_Node_Dot
        
        GdipFillEllipse(GraphicObject, brush, x-(size/2), y-(size/2), size, size)
        
      Case #GL_Line_Node_Circle
        
        GdipDrawEllipse(GraphicObject, pen, x-(size/2), y-(size/2), size, size)
        
      Case #GL_Line_Node_Square
        
        GdipDrawRectangle(GraphicObject, pen, x-(size/2), y-(size/2), size, size)
        
      Case #GL_Line_Node_SquareFilled
        
        GdipFillRectangle(GraphicObject, brush, x-(size/2), y-(size/2), size, size)
        
      Case #GL_Line_Node_Arrow
        
        Dim p.POINTF(3)
        p(0)\x = x-(size/2)
        p(0)\y = y+(size/2)
        p(1)\x = x
        p(1)\y = y+(thickness/2)-(size/2)
        p(2)\x = x+(size/2)
        p(2)\y = y+(size/2)
        GdipDrawLines(GraphicObject, pen, p(), 3)
        
      Case #GL_Line_Node_Triangle
        
        Dim p.POINTF(4)
        p(0)\x = x-(size/2)
        p(0)\y = y+(size/2)
        p(1)\x = x
        p(1)\y = y+(thickness/2)-(size/2)
        p(2)\x = x+(size/2)
        p(2)\y = y+(size/2)
        p(3)\x = p(0)\x
        p(3)\y = p(0)\y
        
        GdipCreatePath(0, @path)
        
        GdipAddPathLine(path, p(0)\x, p(0)\y, p(1)\x, p(1)\y)
        GdipAddPathLine(path, p(1)\x, p(1)\y, p(2)\x, p(2)\y)
        GdipAddPathLine(path, p(2)\x, p(2)\y, p(3)\x, p(3)\y)
        GdipClosePathFigure(path)
        
        GdipDrawPath(GraphicObject, pen, path)
        
        GdipDeletePath(path)
        
      Case #GL_Line_Node_TriangleFilled
        
        Dim p.POINTF(4)
        p(0)\x = x-(size/2)
        p(0)\y = y+(size/2)
        p(1)\x = x
        p(1)\y = y+(thickness/2)-(size/2)
        p(2)\x = x+(size/2)
        p(2)\y = y+(size/2)
        p(3)\x = p(0)\x
        p(3)\y = p(0)\y
        
        GdipCreatePath(0, @path)
        
        GdipAddPathLine(path, p(0)\x, p(0)\y, p(1)\x, p(1)\y)
        GdipAddPathLine(path, p(1)\x, p(1)\y, p(2)\x, p(2)\y)
        GdipAddPathLine(path, p(2)\x, p(2)\y, p(3)\x, p(3)\y)
        GdipClosePathFigure(path)
        
        GdipFillPath(GraphicObject, brush, path)
        
        GdipDeletePath(path)
        
      Case #GL_Line_Node_Diamond
        
        Dim p.POINTF(4)
        p(0)\x = x-(size/2)
        p(0)\y = y+(size/2)-(size/2)
        p(1)\x = x
        p(1)\y = y-(size/2)
        p(2)\x = x+(size/2)
        p(2)\y = y+(size/2)-(size/2)
        p(3)\x = x
        p(3)\y = y+size-(size/2)
        
        GdipCreatePath(0, @path)
        
        GdipAddPathLine(path, p(0)\x, p(0)\y, p(1)\x, p(1)\y)
        GdipAddPathLine(path, p(1)\x, p(1)\y, p(2)\x, p(2)\y)
        GdipAddPathLine(path, p(2)\x, p(2)\y, p(3)\x, p(3)\y)
        GdipAddPathLine(path, p(3)\x, p(3)\y, p(0)\x, p(0)\y)
        GdipClosePathFigure(path)
        
        GdipDrawPath(GraphicObject, pen, path)
        
        GdipDeletePath(path)
        
      Case #GL_Line_Node_DiamondFilled
        
        Dim p.POINTF(4)
        p(0)\x = x-(size/2)
        p(0)\y = y+(size/2)-(size/2)
        p(1)\x = x
        p(1)\y = y-(size/2)
        p(2)\x = x+(size/2)
        p(2)\y = y+(size/2)-(size/2)
        p(3)\x = x
        p(3)\y = y+size-(size/2)
        
        GdipCreatePath(0, @path)
        
        GdipAddPathLine(path, p(0)\x, p(0)\y, p(1)\x, p(1)\y)
        GdipAddPathLine(path, p(1)\x, p(1)\y, p(2)\x, p(2)\y)
        GdipAddPathLine(path, p(2)\x, p(2)\y, p(3)\x, p(3)\y)
        GdipAddPathLine(path, p(3)\x, p(3)\y, p(0)\x, p(0)\y)
        GdipClosePathFigure(path)
        
        GdipFillPath(GraphicObject, brush, path)
        
        GdipDeletePath(path)
        
      Case #GL_Line_Node_Cross
        
        GdipFillRectangle(GraphicObject, brush, x-(size/2), y-(thickness/2), size, thickness)
        GdipFillRectangle(GraphicObject, brush, x-(thickness/2), y-(size/2), thickness, size)
        
      Case #GL_Line_Node_Star
        
        GdipFillRectangle(GraphicObject, brush, x-(size/2), y-(thickness/2), size, thickness)
        GdipFillRectangle(GraphicObject, brush, x-(thickness/2), y-(size/2), thickness, size)
        CallFunctionFast(*GdipDrawLine, GraphicObject, pen, x-(size/2.7), y-(size/2.7), x+(size/2.7), y+(size/2.7))
        CallFunctionFast(*GdipDrawLine, GraphicObject, pen, x+(size/2.7), y-(size/2.7), x-(size/2.7), y+(size/2.7))
        
    EndSelect
    
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
  GdipDeleteBrush(brush)
  
EndProcedure

Procedure drawNodes(dc, *rc.RECT, *line.GL_GraphLines, Array points.POINTF(1))
  
  If *line\nodeType = #GL_Line_Node_None
    ProcedureReturn #False
  EndIf
  
  For n = 0 To ArraySize(points())-1
    
    ; only render node if visible
    If points(n)\x+(size/2) >= *rc\left And points(n)\x-(size/2) <= *rc\right And points(n)\y+(size/2) >= *rc\top And points(n)\y-(size/2) <= *rc\bottom
      
      drawNode(dc, points(n)\x, points(n)\y, *line\nodeType, *line\colour, *line\nodeSize)
      
    EndIf
    
  Next
  
EndProcedure

Procedure drawPolygon(dc, *rc.RECT, Array points.POINTF(1), fillColour.l, outlineColour.l, thickness.f, dashStyle.i, isfilled.b, isClosed.b, text.s, font.i)
  
  size.f = GL_metric(GL_DPI)\DPI_Ratio*thickness
  
  rrc.RECT : rrc\left = *rc\right : rrc\top = *rc\bottom : rrc\right = 0 : rrc\bottom = 0
  For n = 0 To ArraySize(points())-1
    ; update bounding box for rendering only what's visible
    x.f = points(n)\x
    y.f = points(n)\y
    If x < rrc\left
      rrc\left = x
    EndIf
    If x > rrc\right
      rrc\right = x
    EndIf
    If y < rrc\top
      rrc\top = y
    EndIf
    If y > rrc\bottom
      rrc\bottom = y
    EndIf
  Next
  
  If IntersectRect_(trc.RECT, *rc, rrc) = #False
    ProcedureReturn #False
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
  CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh
  
  GdipCreateSolidFill(fillColour, @brush)
  GdipCreatePen1(outlineColour, size, 2, @pen)
  GdipSetPenDashStyle(pen, dashStyle)
  GdipCreatePath(0, @path)
  GdipCreatePath(0, @path2)
  
  GdipAddPathLine2(path, points(), ArraySize(points()))
  If isClosed = #True
    GdipClosePathFigure(path)
  EndIf
  
  If isFilled = #True
    GdipAddPathPolygon(path2, points(), ArraySize(points()))
    GdipClosePathFigure(path2)
    GdipFillPath(GraphicObject, brush, path2)
    clipPath = path2
  EndIf
  If thickness > 0
    GdipDrawPath(GraphicObject, pen, path)
    clipPath = path
  EndIf
  
  If text <> ""

    GdipCalcTxt(dc, text, @txtWidth, @txtHeight, font)
    tx.f = rrc\left+((rrc\right-rrc\left)/2)-(txtWidth/2)
    ty.f = rrc\top+((rrc\bottom-rrc\top)/2)-(txtHeight/2)
    If isFilled = #True
      outlineColour = MakeColour(Alpha(fillColour), Blue(outlineColour), Green(outlineColour), Red(outlineColour))
    EndIf
    GdipRenderTxt(dc, tx, ty, text, outlineColour, font, clipPath)
    
  EndIf
    
  GdipDeletePath(path)
  GdipDeletePath(path2)
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  CallFunctionFast(*GdipDeletePen, pen)
  GdipDeleteBrush(brush)
  
EndProcedure

Procedure GdipRenderTxt(dc, x.f, y.f, text.s, ARGB, font, clipPath = #Null)
  
  SelectObject_(dc, GL_Font(font))
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh

  GdipCreateFontFromDC(dc, @fontObject)
  
  GdipCreateSolidFill(ARGB, @brush)
  
  *text = AllocateMemory(StringByteLength(text, #PB_Unicode)+2)
  PokeS(*text, text, -1, #PB_Unicode)
  
  If clipPath <> #Null
    GdipSetClipPath(GraphicObject, clipPath, 0)
  EndIf
  
  rc.RECTF
  rc\left = x
  rc\top = y
  GdipMeasureString(GraphicObject, *text, -1, fontObject, rc, #Null, rc, @codepointsFitted, @linesFilled)
  GdipDrawString(GraphicObject, *text, -1, fontObject, rc, #Null, brush)
  
  FreeMemory(*text)
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  GdipDeleteFont(fontObject)
  GdipDeleteBrush(brush)
  
EndProcedure

Procedure GdipRenderTxtRotated(dc, x.f, y.f, text.s, ARGB, font, angle)
  
  SelectObject_(dc, GL_Font(font))
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 2) ; QualityModeHigh
  CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 2) ; QualityModeHigh

  GdipCreateFontFromDC(dc, @fontObject)
  
  GdipCreateSolidFill(ARGB, @brush)
  
  *text = AllocateMemory(StringByteLength(text, #PB_Unicode)+2)
  PokeS(*text, text, -1, #PB_Unicode)
  
  rc.RECTF
  GdipMeasureString(GraphicObject, *text, -1, fontObject, rc, #Null, rc, @codepointsFitted, @linesFilled)
  
  GdipTranslateWorldTransform(GraphicObject, 0, 0, 1)
  GdipRotateWorldTransform(GraphicObject, angle, 1)
  GdipTranslateWorldTransform(GraphicObject, x, y, 1)
  
  rc\left = -((rc\right-rc\left)/2)
  rc\top = -((rc\bottom-rc\top)/2)
  GdipDrawString(GraphicObject, *text, -1, fontObject, rc, #Null, brush)
  GdipResetWorldTransform(GraphicObject)
  
  FreeMemory(*text)
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  GdipDeleteFont(fontObject)
  GdipDeleteBrush(brush)
  
EndProcedure

Procedure GdipCalcTxt(dc, text.s, *width.integer, *height.integer, font)
  
  SelectObject_(dc, GL_Font(font))
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  
  GdipCreateFontFromDC(dc, @fontObject)
  
  *text = AllocateMemory(StringByteLength(text, #PB_Unicode)+2)
  PokeS(*text, text, -1, #PB_Unicode)
  
  rc.RECTF
  GdipMeasureString(GraphicObject, *text, -1, fontObject, rc, #Null, rc, @codepointsFitted, @linesFilled)
  
  FreeMemory(*text)
  CallFunctionFast(*GdipDeleteGraphics, GraphicObject)
  GdipDeleteFont(fontObject)
  
  *width\i = rc\right-rc\left
  *height\i = rc\bottom-rc\top
  
  ProcedureReturn #True
  
EndProcedure

Procedure.d nicenum(x.d, round.b)
  
  exp.i
  f.d
  nf.d
  exp = Round(Log10(x), #PB_Round_Down)
  f = x/Pow(10.0, exp)
  
  If round
    If f < 1.5
      nf = 1
    ElseIf f < 3
      nf = 2
    ElseIf f < 7
      nf = 5
    Else
      nf = 10
    EndIf
  Else
    If f <= 1
      nf = 1
    ElseIf f <= 2
      nf = 2
    ElseIf f <= 5
      nf = 5
    Else
      nf = 10
    EndIf
  EndIf
  
  ProcedureReturn nf*Pow(10.0, exp)
  
EndProcedure

Procedure.s loose_label(min.d, max.d, ntick.i, index)
  
  If ntick < 2
    ntick = 2
  EndIf
  
  nfrac.i
  d.d
  graphmin.d
  graphmax.d
  range.d
  x.d
  
;   range = nicenum(max-min, #True) ; old false
;   d = nicenum(range/(ntick-1), #True)
;   graphmin = Round(min/d, #PB_Round_Nearest)*d ;old down
;   graphmax = Round(max/d, #PB_Round_Nearest)*d ; old up

  range = nicenum(max-min, #False) ; old false
  d = nicenum(range/(ntick-1), #True)
  graphmin = Round(min/d, #PB_Round_Down)*d ;old down
  graphmax = Round(max/d, #PB_Round_Up)*d ; old up

  If -Round(Log10(d), #PB_Round_Down) > 0
    nfrac = -Round(Log10(d), #PB_Round_Down)
  Else
    nfrac = 0
  EndIf
  
  x = graphmin
  For n = 1 To index
    x + d
  Next
  
  ProcedureReturn StrD(x, nfrac)
  
EndProcedure

Procedure getLoose_labelTicks(min.d, max.d, ntick.i)
  
  nfrac.i
  d.d
  graphmin.d
  graphmax.d
  range.d
  x.d
  
;   range = nicenum(max-min, #True) ; old false
;   d = nicenum(range/(ntick-1), #True)
;   graphmin = Round(min/d, #PB_Round_Nearest)*d ; old down
;   graphmax = Round(max/d, #PB_Round_Nearest)*d ; old up

  range = nicenum(max-min, #False) ; old false
  d = nicenum(range/(ntick-1), #True)
  graphmin = Round(min/d, #PB_Round_Down)*d ; old down
  graphmax = Round(max/d, #PB_Round_Up)*d ; old up

  x = graphmin
  Repeat
    x + d
    count + 1
  Until x >= (graphmax + 0.5*d)
  
  ProcedureReturn count
  
EndProcedure

Procedure updateGraphDragScrolling(*graph.GL_Graphs, hwnd, Started = #False)
  Static mouseStartX, mouseStartY, state
  
  GetCursorPos_(p.POINT)
  
  If Started = #True And state = #False
    
    mouseStartX = p\x
    mouseStartY = p\y
    
    SetCapture_(hwnd)
    SetPanelExPageCursor(*graph\contentHandle, 0, #IDC_SIZEALL)
    SetPanelExPageCursor(*graph\Handle, 0, #IDC_SIZEALL)
    state = #True
    
  ElseIf Started = -1 And state = #True
    
    ReleaseCapture_()
    SetPanelExPageCursor(*graph\contentHandle, 0, #IDC_CROSS)
    SetPanelExPageCursor(*graph\Handle, 0, #IDC_ARROW)
    state = #False
    
  ElseIf state = #True
    
    xDelta = p\x - mouseStartX
    yDelta = p\y - mouseStartY
    
    mouseStartX = p\x
    mouseStartY = p\y
    
    *graph\xOffset + xDelta
    *graph\yOffset + yDelta
    
    RefreshGraph(*graph\handle)
    
  EndIf
  
EndProcedure

Procedure updateGraphDragZoomBox(*graph.GL_Graphs, hwnd, Started = #False)
  Static state
  
  GetCursorPos_(p.POINT)
  
  If Started = #True And state = #False
    
    MapWindowPoints_(0, hwnd, p, 1)
    *graph\zoomBoxStartX = p\x
    *graph\zoomBoxStartY = p\y
    *graph\zoomBoxX = p\x
    *graph\zoomBoxY = p\y
    
    SetCapture_(hwnd)
    ;SetPanelExPageCursor(*graph\contentHandle, 0, #IDC_SIZEALL)
    ;SetPanelExPageCursor(*graph\Handle, 0, #IDC_SIZEALL)
    *graph\zoomBox = #True
    state = #True
    RefreshGraph(*graph\handle)
    setGraphToolTipXY2(*graph, hwnd, *graph\zoomBoxStartX, *graph\zoomBoxStartY, p\x, p\y)
    
  ElseIf Started = -1 And state = #True
    
    ReleaseCapture_()
    ;SetPanelExPageCursor(*graph\contentHandle, 0, #IDC_CROSS)
    ;SetPanelExPageCursor(*graph\Handle, 0, #IDC_ARROW)
    
    ; if zoomed beyond max floating point precision then exit
    If Len(StringField(StrD(*graph\cxAxisMax), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision And Len(StringField(StrD(*graph\cyAxisMax), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision
      
      GetClientRect_(hwnd, rc.RECT)
      grwidth = rc\right
      grheight = rc\bottom
      GetCursorPos_(p.POINT)
      MapWindowPoints_(0, hwnd, p, 1)
      
      ; make sure coords aren't same
      If *graph\zoomBoxStartX <> p\x And *graph\zoomBoxStartY <> p\y
        
  ;       sx = *graph\zoomBoxStartX
  ;       sy = *graph\zoomBoxStartY
  ;       x = p\x
  ;       y = p\y
  ;       width = Abs(sx-x)
  ;       height = Abs(sy-y)
  ;       sqrHalfWidth = ((width+height)/2)/2
  ;       cx = (sx+x)/2
  ;       cy = (sy+y)/2
  ;       sx = cx-sqrHalfWidth
  ;       x = cx+sqrHalfWidth
  ;       sy = cy-sqrHalfWidth
  ;       y = cy+sqrHalfWidth
  ;       
  ;       ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
  ;       zx.d = (((x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
  ;       zsx.d = (((sx-*graph\xOffset)*ratio)+*graph\cxAxisMin)
  ;       ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
  ;       zy.d = ((((grheight-y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
  ;       zsy.d = ((((grheight-sy)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
        zx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
        zsx.d = (((*graph\zoomBoxStartX-*graph\xOffset)*ratio)+*graph\cxAxisMin)
        ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
        zy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        zsy.d = ((((grheight-*graph\zoomBoxStartY)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
        
        If zx < zsx
          tz.d = zsx
          zsx = zx
          zx = tz
        EndIf
        If zy < zsy
          tz.d = zsy
          zsy = zy
          zy = tz
        EndIf
        
        ; calc axis ticks
        tickSpacing = GL_metric(GL_DPI)\DPI_Ratio**graph\tickSpacing
        xticks = Round(grwidth/tickSpacing, #PB_Round_Down)
        yticks = Round(grheight/tickSpacing, #PB_Round_Down)
        oxticks = xticks
        oyticks = yticks
        xticks = getLoose_labelTicks(zsx, zx, xticks)
        yticks = getLoose_labelTicks(zsy, zy, yticks)
        
        txt.s = loose_label(zsx, zx, oxticks, 0)
        zsx = ValD(txt)
        If xticks <= 1
          txt.s = loose_label(zsx, zx, oxticks, xticks)
        Else
          txt.s = loose_label(zsx, zx, oxticks, xticks-1)
        EndIf
        zx = ValD(txt)
        txt.s = loose_label(zsy, zy, oyticks, 0)
        zsy = ValD(txt)
        If yticks <= 1
          txt.s = loose_label(zsy, zy, oyticks, yticks)
        Else
          txt.s = loose_label(zsy, zy, oyticks, yticks-1)
        EndIf
        zy = ValD(txt)
        
        If Len(StringField(StrD(zsx), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision And Len(StringField(StrD(zx), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision And Len(StringField(StrD(zsy), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision And Len(StringField(StrD(zy), 2, ".")) <= #GL_ZoomMaxFloatingPointPrecision
          *graph\xAxisMin = zsx
          *graph\xAxisMax = zx
          *graph\yAxisMin = zsy
          *graph\yAxisMax = zy
          *graph\xOffset = 0
          *graph\yOffset = 0
        EndIf
        
      EndIf
    EndIf
    
    *graph\zoomBox = #False
    *graph\zoomBoxStartX = 0
    *graph\zoomBoxStartY = 0
    *graph\zoomBoxX = 0
    *graph\zoomBoxY = 0
    state = #False
    RefreshGraph(*graph\handle)
    
  ElseIf state = #True
    
    MapWindowPoints_(0, hwnd, p, 1)
    *graph\zoomBoxX = p\x
    *graph\zoomBoxY = p\y
    
    RefreshGraph(*graph\handle)
    setGraphToolTipXY2(*graph, hwnd, *graph\zoomBoxStartX, *graph\zoomBoxStartY, p\x, p\y)
    
  EndIf
  
EndProcedure

Procedure setGraphToolTip(*graph.GL_Graphs, text.s)
  
  If *graph\tooltipHWND = #Null
    hwnd = CreateWindowEx_(0, "tooltips_class32", 0, #WS_POPUP, #CW_USEDEFAULT, #CW_USEDEFAULT, #CW_USEDEFAULT, #CW_USEDEFAULT, PanelExID(*graph\contentHandle, 0), 0,  GetModuleHandle_(0), #Null)
    If hwnd <> 0
      
      *graph\tooltipHWND = hwnd
      
      tool.TOOLINFO
      tool\cbSize = SizeOf(TOOLINFO)
      tool\hwnd = PanelExID(*graph\contentHandle, 0)
      tool\uFlags = #TTF_IDISHWND | #TTF_SUBCLASS
      tool\uId = PanelExID(*graph\contentHandle, 0)
      tool\lpszText = @text
      SendMessage_(hwnd, #TTM_ADDTOOL, 0, @tool)
      
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndIf
  
  tool.TOOLINFO
  tool\cbSize = SizeOf(TOOLINFO)
  tool\hwnd = PanelExID(*graph\contentHandle, 0)
  tool\uFlags = #TTF_IDISHWND | #TTF_SUBCLASS
  tool\uId = PanelExID(*graph\contentHandle, 0)
  tool\lpszText = @text
  SendMessage_(*graph\tooltipHWND, #TTM_UPDATETIPTEXT, 0, @tool)
  
EndProcedure

Procedure.b IsNumericFloat(in_str.s)
 
  Static rex_IsNumericFloat
 
  If rex_IsNumericFloat = #Null
    rex_IsNumericFloat = CreateRegularExpression(#PB_Any,"^[[:digit:].-]+$") ; Any digit 0-9 and float
  EndIf
 
  ProcedureReturn MatchRegularExpression(rex_IsNumericFloat, in_str)
EndProcedure

Procedure.s strFE(x.f, dec.b = 6)
  If x = 0: ProcedureReturn "0": EndIf
  Protected e.l = (((PeekL(@x) >> 23) & %11111111) - 127) * Log10(2)
  If dec < 0: dec = 0: EndIf
  ProcedureReturn StrF(x / Pow(10, e), dec) + "e" +Str(e)
EndProcedure

Procedure.s strDE(x.d, dec.b = 6)
  If x = 0: ProcedureReturn "0": EndIf
  Protected e.q = (((PeekQ(@x) >> 52) & %11111111111) - 1023) * Log10(2)
  If dec < 0: dec = 0: EndIf
  ProcedureReturn StrD(x / Pow(10, e), dec) + "e" +Str(e)
EndProcedure

; Debug strDE(-3.5e20)
; Debug strDE(-3.5e-20)
; Debug strFE(3.5e20)
; Debug strFE(3.5e-20)
; 
; Debug StrDE(3, 1)

; returns a string that fits into width by iteratively lowering floating point precision
Procedure.s calcTxtProcisionSize(dc, value.d, width.i, font.i)
  
  padding = 0
  
  If IsNAN(Value)
    value$ = "NaN"
    GdipCalcTxt(dc, "-.1", @txtWidth, @txtHeight, font)
    If txtWidth+padding > width
      value$ = ""
    EndIf
    
    ProcedureReturn value$
  EndIf
  
  value$ = StrD(value)
  If FindString(value$, ".") > 0
    precision = Len(StringField(value$, 2, "."))
  EndIf
  Repeat
    value$ = StrD(value, precision)
    If ValD(value$) = 0
      value$ = "0"
    EndIf
    GdipCalcTxt(dc, value$, @txtWidth, @txtHeight, font)
    precision - 1
  Until txtWidth+padding < width Or precision <= 0
  
  If precision <= 0 Or value$ = "0"
    If Mid(value$, 1, 2) = "0."
      value$ = ReplaceString(value$, "0.", ".")
    EndIf
    If StringField(value$, 2, ".") = "0"
      value$ = ReplaceString(value$, ".0", "")
    EndIf
    If value > 9 Or value < -9
      value$ = Str(Round(value, #PB_Round_Nearest));StringField(value$, 1, ".")
    EndIf
    GdipCalcTxt(dc, "-.1", @txtWidth, @txtHeight, font)
  EndIf
  
  If txtWidth+padding > width
    value$ = ""
  EndIf
  
  ProcedureReturn value$
  
EndProcedure

Procedure setGraphToolTipXY(*graph.GL_Graphs, hwnd)
  
  GetClientRect_(hwnd, rc.RECT)
  grwidth = rc\right
  grheight = rc\bottom
  GetCursorPos_(p.POINT)
  MapWindowPoints_(0, hwnd, p, 1)
  ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
  pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
  ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
  pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
  
  xprecision = Len(StringField(StrD(*graph\cxAxisMax), 2, "."))+1
  yprecision = Len(StringField(StrD(*graph\cyAxisMax), 2, "."))+1
  
  txt$ = "X: "+StrD(pointx, xprecision)+" , Y: "+StrD(pointy, yprecision)
  
  xAxisMin.d = *graph\cxAxisMin
  xAxisMax.d = *graph\cxAxisMax
  yAxisMin.d = *graph\cyAxisMin
  yAxisMax.d = *graph\cyAxisMax
  
  ; check if over a density plot and show value if so
  ForEach *graph\density()
    
    If *graph\density()\showValuesOnHover = #True
    
      rxMin.d = *graph\density()\xMin
      rxMax.d = *graph\density()\xMax
      ryMin.d = *graph\density()\yMin
      ryMax.d = *graph\density()\yMax
  
      If pointx >= rxMin And pointx <= rxMax And pointy >= ryMin And pointy <= ryMax
        
        rxMin = (grwidth/(xAxisMax-xAxisMin))*(rxMin-xAxisMin)
        rxMax = (grwidth/(xAxisMax-xAxisMin))*(rxMax-xAxisMin)
        ryMin = ((grheight/(yAxisMax-yAxisMin))*(ryMin-yAxisMin))
        ryMax = ((grheight/(yAxisMax-yAxisMin))*(ryMax-yAxisMin))
        
        rxMin + *graph\xOffset
        rxMax + *graph\xOffset
        ryMin - *graph\yOffset
        ryMax - *graph\yOffset
  
        rrc.RECT
        rrc\left = rxMin
        rrc\right = rxMax
        rrc\top = grheight-ryMax
        rrc\bottom = grheight-ryMin
        
        xRatio.f = (rrc\right-rrc\left)/(ArraySize(*graph\density()\Plot(), 1))
        yRatio.f = (rrc\bottom-rrc\top)/(ArraySize(*graph\density()\Plot(), 2))
        
        x = Round((p\x-rrc\left)/xRatio, #PB_Round_Down)
        y = Round((p\y-rrc\top)/yRatio, #PB_Round_Down)
        
        txt$ + "  Density: "+StrD(*graph\density()\Plot(x, y))
        
      EndIf
      
    EndIf
      
  Next
  
  ; check if over a bar chart and show value if so
  ForEach *graph\bars()
    
    For n = 0 To ArraySize(*graph\bars()\bar())
      
      CopyRect_(rcf.RECTF, *graph\bars()\bar(n)\rcf)
      If p\x >= rcf\left And p\x <= rcf\right And p\y >= rcf\top And p\y <= rcf\bottom
        
        txt$ + "  Value: "+StrD(*graph\bars()\bar(n)\maxValue)
        Break 2
        
      EndIf
      
    Next
    
  Next
  
  setGraphToolTip(*graph, txt$)
  
EndProcedure

Procedure setGraphToolTipXY2(*graph.GL_Graphs, hwnd, sx, sy, x, y)
  
  GetClientRect_(hwnd, rc.RECT)
  grwidth = rc\right
  grheight = rc\bottom
  
  ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
  pointx.d = (((sx-*graph\xOffset)*ratio)+*graph\cxAxisMin)
  ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
  pointy.d = ((((grheight-sy)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
  
  ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
  pointx2.d = (((x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
  ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
  pointy2.d = ((((grheight-y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
  
  xprecision = Len(StringField(StrD(*graph\cxAxisMax), 2, "."))+1
  yprecision = Len(StringField(StrD(*graph\cyAxisMax), 2, "."))+1
  
  setGraphToolTip(*graph, "X: "+StrD(pointx, xprecision)+" , Y: "+StrD(pointy, yprecision)+"  X2: "+StrD(pointx2, xprecision)+" , Y2: "+StrD(pointy2, yprecision))
  
EndProcedure

Procedure contextMenu(*graph.GL_Graphs, hwnd, x, y)
    
  If GL_ContextMenu <> #False
      FreeMenuEx(GL_ContextMenu)
  EndIf
  
  pnt.POINT
  pnt\x = x
  pnt\y = y
  pointerhwnd = WindowFromPoint_(PeekQ(pnt))
  
  GL_ContextMenu = CreatePopupMenuEx(#ProGUI_Any, #UISTYLE_OFFICE2007)
  MenuItemEx(GL_Command_Reset, "Use &default ranges", 0, 0, 0, 0)
  MenuItemEx(GL_Command_SetRanges, "Set &ranges", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(GL_Command_ZoomIn, "Zoom &In", 0, 0, 0, 0)
  MenuItemEx(GL_Command_ZoomOut, "Zoom &Out", 0, 0, 0, 0)
  MenuBarEx()
  MenuItemEx(GL_Command_Copy, "&Copy", 0, 0, 0, 0)
  MenuItemEx(GL_Command_Save, "&Save", 0, 0, 0, 0)
  MenuItemEx(GL_Command_Print, "&Print", 0, 0, 0, 0)
    
    ; cut, copy, paste
;     MenuItemEx(#Command_Cut, "Cu&t$\bCtrl+X", image(#Img_Cut)\normal, 0, 0, 0)
;     MenuItemEx(#Command_Copy, "&Copy$\bCtrl+C", image(#Img_Copy)\normal, 0, 0, 0)
;     MenuItemEx(#Command_Paste, "&Paste$\bCtrl+V", image(#Img_Paste)\normal, 0, 0, 0)
;     MenuItemEx(#Command_SelectAll, "&Select A&ll$\bCtrl+A", 0, 0, 0, 0)
  
    
;     ; default menu items
;     MenuItemEx(#Command_Load, "&Open...$\bCtrl+O", image(#Img_Open)\normal, 0, 0, 0)
;     MenuItemEx(#Command_Save, "&Save$\bCtrl+S", image(#Img_Save)\normal, 0, 0, 0)
;     MenuItemEx(#Command_ExportCSV, "&Export to CSV$\bCtrl+E", image(#Img_ExportCSV)\normal, 0, 0, 0)
;     MenuBarEx()
;     MenuItemEx(#Command_Print, "&Print...$\bCtrl+P", image(#Img_Print)\normal, 0, 0, 0)
;     If printingAvailable = #False
;         DisableMenuItemEx(#ContextMenu, #Command_Print, #True)
;     EndIf
;     If isEditing() = #False
;         MenuBarEx()
;         MenuItemEx(#Command_Copy, "&Copy stack-up$\bCtrl+C", image(#Img_Copy)\normal, 0, 0, 0)
;     EndIf
;     

;   ; check if over a density plot and show value menu option
;   GetClientRect_(hwnd, rc.RECT)
;   grwidth = rc\right
;   grheight = rc\bottom
;   GetCursorPos_(p.POINT)
;   MapWindowPoints_(0, hwnd, p, 1)
;   ratio.d = Abs(*graph\cxAxisMax-*graph\cxAxisMin)/grwidth
;   pointx.d = (((p\x-*graph\xOffset)*ratio)+*graph\cxAxisMin)
;   ratio.d = Abs(*graph\cyAxisMax-*graph\cyAxisMin)/grheight
;   pointy.d = ((((grheight-p\y)+*graph\yOffset)*ratio)+*graph\cyAxisMin)
;   ForEach *graph\density()
;     
;     rxMin.d = *graph\density()\xMin
;     rxMax.d = *graph\density()\xMax
;     ryMin.d = *graph\density()\yMin
;     ryMax.d = *graph\density()\yMax
;     
;     
;     If pointx >= rxMin And pointx <= rxMax And pointy >= ryMin And pointy <= ryMax
;       
;       Debug "over"
;       
;       Break
;       
;     EndIf
;     
;   Next

  If GL_ContextMenuHwnd = 0
    GL_ContextMenuOpen = #True
    GL_ContextMenuHwnd = hwnd
    DisplayPopupMenuEx(GL_ContextMenu, hwnd, x, y)
    GL_ContextMenuOpen = #False
  EndIf
    
EndProcedure

Procedure openRangesWindow(*graph.GL_Graphs, x = 0, y = 0, width = 550, height = 230)
  
  If *graph\dialog_Ranges\PBWindowID = #Null
    GL_Ranges_Window = OpenWindow(#PB_Any, x, y, width, height, *graph\title+": Set Axis Ranges", #PB_Window_SystemMenu | #PB_Window_WindowCentered, PanelExID(*graph\contentHandle, 0))
    GL_Ranges_Text_1 = TextGadget(#PB_Any, 30, 40, 90, 20, "Minimum value")
    GL_Ranges_String_Xmin = StringGadget(#PB_Any, 120, 40, 150, 30, "")
    GL_Ranges_Text_2 = TextGadget(#PB_Any, 280, 40, 90, 20, "Maximum value")
    GL_Ranges_String_Xmax = StringGadget(#PB_Any, 370, 40, 150, 30, "")
    GL_Ranges_Text_3 = TextGadget(#PB_Any, 30, 130, 90, 20, "Minimum value")
    GL_Ranges_Text_4 = TextGadget(#PB_Any, 280, 130, 90, 20, "Maximum value")
    GL_Ranges_String_Ymax = StringGadget(#PB_Any, 370, 130, 150, 30, "")
    GL_Ranges_String_Ymin = StringGadget(#PB_Any, 120, 130, 150, 30, "")
    GL_Ranges_Frame_0 = FrameGadget(#PB_Any, 10, 10, 530, 80, "X Axis")
    GL_Ranges_Frame_1 = FrameGadget(#PB_Any, 10, 100, 530, 80, "Y Axis")
    GL_Ranges_Button_Apply = ButtonGadget(#PB_Any, 370, 190, 80, 30, "Apply")
    GL_Ranges_Button_Cancel = ButtonGadget(#PB_Any, 460, 190, 80, 30, "Cancel")
    
    *graph\dialog_Ranges\PBWindowID = GL_Ranges_Window
    *graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmin] = GL_Ranges_String_Xmin
    *graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmax] = GL_Ranges_String_Xmax
    *graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymin] = GL_Ranges_String_Ymin
    *graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymax] = GL_Ranges_String_Ymax
    *graph\dialog_Ranges\gadget[#GL_Ranges_Button_Apply] = GL_Ranges_Button_Apply
    *graph\dialog_Ranges\gadget[#GL_Ranges_Button_Cancel] = GL_Ranges_Button_Cancel
    
    SetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmin], StrD(*graph\cxAxisMin))
    SetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Xmax], StrD(*graph\cxAxisMax))
    SetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymin], StrD(*graph\cyAxisMin))
    SetGadgetText(*graph\dialog_Ranges\gadget[#GL_Ranges_String_Ymax], StrD(*graph\cyAxisMax))
    
    SetWindowLongPtr_(WindowID(*graph\dialog_Ranges\PBWindowID), #GWLP_USERDATA, *graph)
    SetWindowCallback(@GraphDialogCallback(), *graph\dialog_Ranges\PBWindowID)
  EndIf
  
EndProcedure

Procedure openGraphQualityWindow(*graph.GL_Graphs, command.i = 0)
  
  If *graph\dialog_Quality\PBWindowID = #Null
    
    width = 300
    h = 30
    margin = 10
    x = margin
    y = margin
    
    theight = 10
    For i = #GL_DPI_Window To #GL_Max_DPI_Resolutions-1
      theight + h+margin
    Next
    height = theight + (margin*4) + h
    
    GL_Quality_Window = OpenWindow(#PB_Any, x, y, width, height, *graph\title+": Set graph quality", #PB_Window_SystemMenu | #PB_Window_WindowCentered, PanelExID(*graph\contentHandle, 0))
    
    FrameGadget(#PB_Any, x, y, width-(margin*2), theight+margin, "Set Graph Quality")
    
    Dim *graph\dialog_Quality\dynamic(#GL_Max_DPI_Resolutions)
    
    y + (margin*2)
    x + margin
    For i = #GL_DPI_Window To #GL_Max_DPI_Resolutions-1
      *graph\dialog_Quality\dynamic(i) = OptionGadget(#PB_Any, x, y, width-(margin*4), h, "Quality "+GL_Metric(i)\qualityDescription+" ("+Str(GL_Metric(i)\DPI)+" dots per inch)")
      y + h+margin
    Next
    SetGadgetState(*graph\dialog_Quality\dynamic(GL_DefaultPrintDPI), #True)
    
    y + margin
    GL_Quality_Button_Cancel = ButtonGadget(#PB_Any, width-80-margin, y, 80, 30, "Cancel")
    GL_Quality_Button_Okay = ButtonGadget(#PB_Any, width-160-(margin*2), y, 80, 30, "Okay")
    
    *graph\dialog_Quality\PBWindowID = GL_Quality_Window
    *graph\dialog_Quality\gadget[#GL_Quality_Button_Okay] = GL_Quality_Button_Okay
    *graph\dialog_Quality\gadget[#GL_Quality_Button_Cancel] = GL_Quality_Button_Cancel
    *graph\dialog_Quality\command = command
    
    SetWindowLongPtr_(WindowID(*graph\dialog_Quality\PBWindowID), #GWLP_USERDATA, *graph)
    SetWindowCallback(@GraphDialogCallback(), *graph\dialog_Quality\PBWindowID)
    
  EndIf
  
EndProcedure

Procedure updateLegend(*graph.GL_Graphs)
  
  GetClientRect_(*graph\contentHandle, rc.RECT)
  MapWindowPoints_(*graph\contentHandle, *graph\handle, rc, 2)
  
  dc = CreateCompatibleDC_(0)
  
  width = rc\right-rc\left
  width - (GL_metric(GL_DPI)\DPI_Ratio*(#GL_Default_LegendOutsidePadding*2))
  
  keyPadding = GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyPadding
  padding = GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendPadding
  x = padding
  y = padding
  
  ; get initial max width
  ForEach *graph\Line()

    If *graph\Line()\showOnLegend = #True And *graph\Line()\label <> ""
      
      GdipCalcTxt(dc, *graph\Line()\label, @w, @h, *graph\legendFont)
      
      x + ((GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth) + w)
      
      If x > width-padding
        Break
      EndIf
      
      If x > maxWidth
        maxWidth = x
      EndIf
      
    EndIf
   
  Next
  
  If maxWidth = 0
    SetWindowPos_(*graph\legendHandle, 0, 0, 0, 0, 0, #SWP_NOMOVE)
    If *graph\lWidth <> maxWidth Or *graph\lHeight <> maxHeight
      RefreshGraph(*graph\handle)
    EndIf
      
    *graph\lWidth = maxWidth
    *graph\lHeight = maxHeight
    ProcedureReturn #False
  EndIf
    
  ; calc height by fitting into max width
  x = padding
  ForEach *graph\Line()

    If *graph\Line()\showOnLegend = #True And *graph\Line()\label <> ""
      
      GdipCalcTxt(dc, *graph\Line()\label, @w, @h, *graph\legendFont)
      
      If maxHeight = 0
        maxHeight = h+(padding*2)
      EndIf
      
      If x + ((GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth) + w) > maxWidth
        x = 0
        maxHeight + h
      EndIf
      
      x + ((GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendKeyWidth) + w)
  
    EndIf
    
  Next
  
  maxWidth + (padding*2)
  
  x = rc\Left+((rc\right-rc\left)/2)-(maxWidth/2)
  y = rc\top-maxHeight
  y - (GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_LegendOutsidePadding)
  SetWindowPos_(*graph\legendHandle, 0, x, y, maxWidth, maxHeight, 0)
  
  If *graph\lWidth <> maxWidth Or *graph\lHeight <> maxHeight
    RefreshGraph(*graph\handle)
  EndIf
    
  *graph\lWidth = maxWidth
  *graph\lHeight = maxHeight
  
  DeleteDC_(dc)
  
EndProcedure

;-
;- ----| Public Functions
ProcedureDLL Start_GraphLibrary()
  GdiStart()
  GraphMouseHook = SetWindowsHookEx_(#WH_GETMESSAGE, @GraphMouseInputHook(), #Null, GetCurrentThreadId_())
EndProcedure

ProcedureDLL End_GraphLibrary()
  GdiEnd()
EndProcedure
;-

ProcedureDLL SetGraphDPI(GL_DPI_Constant) ; Sets the Dots Per Inch for graph rendering: #GL_DPI_Window, #GL_DPI_300
  GL_DPI = GL_DPI_Constant
EndProcedure

ProcedureDLL CreateGraph(GraphID.i, WindowID.i, X.l, Y.l, Width.l, Height.l) ; creates a graph control
  
  LockMutex(GL_graphMutex)
  
  ; make sure graph control doesn't already exist
  If GraphID = #ProGUI_Any
    Repeat
      ; generate unique graph id
      GraphID = GL_generateUniqueID_wordUnsigned()
      ; check that same id doesnt already exist
      found = 0
      PushListPosition(GL_Graph())
      ForEach GL_Graph()
        If GL_Graph()\id = GraphID
          found = -1
          Break
        EndIf
      Next
      PopListPosition(GL_Graph())
    Until found = 0
    ProGUI_Any = #True
  Else
    ; make sure graph id doesnt exist
    PushListPosition(GL_Graph())
    ForEach GL_Graph()
      If GL_Graph()\id = GraphID
        UnlockMutex(GL_graphMutex)
        ProcedureReturn #False
      EndIf
    Next
    PopListPosition(GL_Graph())
  EndIf
  
  hwnd = PanelExID(CreatePanelEx(#ProGUI_Any, WindowID, X, Y, Width, Height, @GraphCallback()), -1)
  If hwnd <> #Null
    
    AddPanelExPage(1)
    
    GetClientRect_(hwnd, rc.RECT)
    padding = GL_metric(GL_DPI)\DPI_Ratio*#GL_Default_padding
    grx = padding
    gry = padding
    grwidth = rc\right-(padding*2)
    grheight = rc\bottom-(padding*2)
    
    childHwnd = PanelExID(CreatePanelEx(#ProGUI_Any, PanelExID(hwnd, 0), grx, gry, grwidth, grheight, @GraphContentCallback()), -1)
    AddPanelExPage(-1)
    SetPanelExPageCursor(childHwnd, 0, #IDC_CROSS)
    
    AddElement(GL_Graph())
    GL_Graph()\id = GraphID
    GL_Graph()\handle = hwnd
    GL_Graph()\contentHandle = childHwnd
    GL_Graph()\padding = #GL_Default_padding
    GL_Graph()\titleFont = GL_Default_TitleFont
    GL_Graph()\titlePadding = #GL_Default_titlePadding
    GL_Graph()\titleColour = #GL_Default_titleColour
    GL_Graph()\showTicks = #True
    GL_Graph()\tickLength = #GL_Default_tickLength
    GL_Graph()\tickWidth = #GL_Default_tickWidth
    GL_Graph()\tickSpacing = #GL_Default_tickSpacing
    GL_Graph()\tickColour = #GL_Default_tickColour
    GL_Graph()\tickMinorColour = #GL_Default_tickMinorColour
    GL_Graph()\tickMinorWidth = #GL_Default_tickMinorWidth
    GL_Graph()\valuePadding = #GL_Default_valuePadding
    GL_Graph()\axisLabelFont = GL_Default_axisLabelFont
    GL_Graph()\axisLabelColour = #GL_Default_axisLabelColour
    GL_Graph()\axisValueFont = GL_Default_axisValueFont
    GL_Graph()\axisValueColour = #GL_Default_axisValueColour
    GL_Graph()\labelPadding = #GL_Default_labelPadding
    GL_Graph()\borderThickness = #GL_Default_borderThickness
    GL_Graph()\borderColour = #GL_Default_borderColour
    GL_Graph()\gridlineColour = #GL_Default_gridlineColour
    GL_Graph()\gridlineWidth = #GL_Default_gridlineWidth
    GL_Graph()\gridlineMinorColour = #GL_Default_gridlineMinorColour
    GL_Graph()\gridlineMinorWidth = #GL_Default_gridlineMinorWidth
    GL_Graph()\gridlines = #True
    GL_Graph()\gridlinesMinor = #True
    GL_Graph()\rangeFont = GL_Default_rangeFont
    GL_Graph()\lineFont = GL_Default_lineFont
    GL_Graph()\barFont = GL_Default_barFont
    GL_Graph()\barValueFont = GL_Default_barValueFont
    GL_Graph()\showZeroAxisLines = #GL_Default_showZeroAxis
    GL_Graph()\zeroAxisThickness = #GL_Default_zeroAxisThickness
    GL_Graph()\zeroAxisColour = #GL_Default_zeroAxisColour
    
    ; legend
    legendHwnd = PanelExID(CreatePanelEx(#ProGUI_Any, PanelExID(hwnd, 0), 0, 0, 500, 100, @GraphLegendCallback()), -1)
    AddPanelExPage(-1)
    SetPanelExPageBackground(legendHwnd, 0, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_IGNORE, #PNLX_TRANSPARENT, 0)
    
    GL_Graph()\legendHandle = legendHwnd
    GL_Graph()\legendKeyWidth = #GL_Default_LegendKeyWidth
    GL_Graph()\legendOrientation = #GL_Default_LegendOrientation
    Gl_Graph()\legendFont = GL_Default_legendFont
    
    SetWindowLongPtr_(hwnd, #GWLP_USERDATA, @GL_Graph())
    SetWindowLongPtr_(childHwnd, #GWLP_USERDATA, @GL_Graph())
    SetWindowLongPtr_(legendHwnd, #GWLP_USERDATA, @GL_Graph())
    
    UnlockMutex(GL_graphMutex)
    RefreshPanelEx(hwnd)
    
    If ProGUI_Any = #True
      ProcedureReturn GraphID
    Else
      ProcedureReturn hwnd
    EndIf
    
  EndIf
  
  UnlockMutex(GL_graphMutex)
  ProcedureReturn #False
  
EndProcedure

Procedure FreeGraph(id.i) ; Frees a graph
  
  LockMutex(GL_graphMutex)
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      parentHwnd = GetParent_(GL_Graph()\handle)
      FreePanelEx(GL_Graph()\contentHandle)
      FreePanelEx(GL_Graph()\handle)
      
      ; remove fonts
      If GL_Graph()\titleFont <> GL_Default_TitleFont
        GL_FreeFont(GL_Graph()\titleFont)
      EndIf
      If GL_Graph()\axisLabelFont <> GL_Default_axisLabelFont
        GL_FreeFont(GL_Graph()\axisLabelFont)
      EndIf
      
      DeleteElement(GL_Graph())
      
      RedrawWindow_(parentHwnd, 0, 0, #RDW_ALLCHILDREN|#RDW_INVALIDATE|#RDW_UPDATENOW|#RDW_ERASENOW|#RDW_ERASE)
      
      retval = #True
      Break
      
    EndIf
  Next
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

Procedure ClearGraph(id.i, noRefresh.b) ; Clears / resets a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      ClearList(GL_Graph()\range())
      ClearList(GL_Graph()\Line())
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

Procedure RefreshGraph(id.i) ; Refreshes / updates a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GraphCallback(GL_Graph()\handle, #WM_SIZE, 0, 0)
      RefreshPanelEx(GL_Graph()\handle)
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL GraphID(id.l) ; Returns a handle to a Graph's window
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id
      
      retval = GL_Graph()\Handle
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL ResizeGraph(id.i, x, y, width, height, noRefresh.b) ; Resizes a graph to the given position and dimensions
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      hwnd = GL_Graph()\Handle
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  If retval = #True
    MoveWindow_(hwnd, x, y, width, height, 1-noRefresh)
  EndIf
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphPadding(id.i, padding.i, valuePadding.i, labelPadding.i, noRefresh.b) ; Sets the padding for a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\padding = padding
      GL_Graph()\valuePadding = valuePadding
      GL_Graph()\labelPadding = labelPadding
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphTitle(id.i, title.s, ARGBColour.l, noRefresh.b) ; Sets a graph's title
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\title = title
      GL_Graph()\titleColour = ARGBColour
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphTitleFont(id.i, FontName.s, PointSize.l, Flags.i, noRefresh.b) ; Sets a graph's title font
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      fontHandle = GL_LoadFont(FontName, PointSize, Flags)
      If fontHandle <> #Null
        GL_Graph()\titleFont = fontHandle
        If noRefresh = #False
          RefreshGraph(GL_Graph()\handle)
        EndIf
        retval = #True
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisRanges(id.i, minX.d, maxX.d, minY.d, maxY.d, noRefresh.b) ; Sets the minimum and maximum range values of a graph's axis
  
  If minX >= maxX Or minY >= maxY
    ProcedureReturn #False
  EndIf
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\oxAxisMin = minX
      GL_Graph()\oyAxisMin = minY
      GL_Graph()\oxAxisMax = maxX
      GL_Graph()\oyAxisMax = maxY
      GL_Graph()\xAxisMin = minX
      GL_Graph()\yAxisMin = minY
      GL_Graph()\xAxisMax = maxX
      GL_Graph()\yAxisMax = maxY
      GL_Graph()\xOffset = 0
      GL_Graph()\yOffset = 0
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisValuesFont(id.i, FontName.s, PointSize.l, Flags.i, noRefresh.b) ; Sets a graph's axis values font
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      fontHandle = GL_LoadFont(FontName, PointSize, Flags)
      If fontHandle <> #Null
        GL_Graph()\axisValueFont = fontHandle
        If noRefresh = #False
          RefreshGraph(GL_Graph()\handle)
        EndIf
        retval = #True
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisValuesColour(id.i, ARGBColour.l, noRefresh.b) ; Sets a graph's axis label colour
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\axisValueColour = ARGBColour
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphTicks(id.i, showTicks.b, noRefresh.b) ; Sets whether a graph's ticks are rendered and in what way 
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\showTicks = showTicks
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphTickSize(id.i, length.i, width.i, spacing.i, noRefresh.b) ; Sets the length, width and spacing of a graph's axis ticks
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\tickLength = length
      GL_Graph()\tickWidth = width
      GL_Graph()\tickSpacing = spacing
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphTickColour(id.i, ARGBColour.l, noRefresh.b) ; Sets a graph's axis label colour
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\tickColour = ARGBColour
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisLabels(id.i, xAxisLabel.s, yAxisLabel.s, noRefresh.b) ; Sets a graph's axis labels
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\xAxisLabel = xAxisLabel
      GL_Graph()\yAxisLabel = yAxisLabel
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisLabelsFont(id.i, FontName.s, PointSize.l, Flags.i, noRefresh.b) ; Sets a graph's axis labels font
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      fontHandle = GL_LoadFont(FontName, PointSize, Flags)
      If fontHandle <> #Null
        GL_Graph()\axisLabelFont = fontHandle
        If noRefresh = #False
          RefreshGraph(GL_Graph()\handle)
        EndIf
        retval = #True
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphAxisLabelsColour(id.i, ARGBColour.l, noRefresh.b) ; Sets a graph's axis label colour
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\axisLabelColour = ARGBColour
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphLabelsFont(id.i, FontName.s, PointSize.l, Flags.i, noRefresh.b) ; Sets a graph's labels font
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      fontHandle = GL_LoadFont(FontName, PointSize, Flags)
      If fontHandle <> #Null
        GL_Graph()\lineFont = fontHandle
        If noRefresh = #False
          RefreshGraph(GL_Graph()\handle)
        EndIf
        retval = #True
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphGridlines(id.i, showGridlines.b, colour.l, width.i, showMinorGridlines.b, minorColour.l, minorWidth.i, showZeroAxisGridline.b, zeroAxisColour.l, zeroAxisWidth.i, noRefresh.b) ; Sets whether a graph shows gridlines or not and the colour of the gridlines
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\gridlines = showGridlines
      GL_Graph()\gridlineColour = colour
      GL_Graph()\gridlineWidth = width
      GL_Graph()\gridlinesMinor = showMinorGridlines
      GL_Graph()\gridlineMinorColour = minorColour
      GL_Graph()\gridlineMinorWidth = minorWidth
      GL_Graph()\showZeroAxisLines = showZeroAxisGridline
      GL_Graph()\zeroAxisThickness = zeroAxisWidth
      GL_Graph()\zeroAxisColour = zeroAxisColour
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphBorder(id.i, thickness.l, ARGBColour.l, noRefresh.b) ; Sets the border thickness and colour around a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\borderThickness = thickness
      GL_Graph()\borderColour = ARGBColour
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphScroll(id.i, x.i, y.i, noRefresh.b)
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      GL_Graph()\xOffset + x
      GL_Graph()\yOffset + y
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = #True
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL AddGraphRange(id.i, minX.d, maxX.d, minY.d, maxY.d, colour.l, showBorder.b, label.s, noRefresh.b) ; Adds a coloured range to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\range())
      GL_Graph()\range()\xMin = minX
      GL_Graph()\range()\xMax = maxX
      GL_Graph()\range()\yMin = minY
      GL_Graph()\range()\yMax = maxY
      GL_Graph()\range()\colour = colour
      GL_Graph()\range()\label = label
      GL_Graph()\range()\showBorder = showBorder
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\range()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

Procedure AddGraphPolyRange(id.i, label.s, colour.l, Array points.POINTD(1), isFilled.b, thickness.i, dashStyle.i, isClosed.b, noRefresh.b) ; Adds a coloured polygon range to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\prange())
      GL_Graph()\prange()\label = label
      GL_Graph()\prange()\colour = colour
      GL_Graph()\prange()\isFilled = isFilled
      GL_Graph()\prange()\thickness = thickness
      GL_Graph()\prange()\dashStyle = dashStyle
      GL_Graph()\prange()\isClosed = isClosed
      
      Dim GL_Graph()\prange()\pnt(ArraySize(points()))
      CopyArray(points(), GL_Graph()\prange()\pnt())
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\prange()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

Procedure AddGraphLine(id.i, Array points.POINTD(1), colour.l, lineThickness.i, style.i, label.s, nodeType.i, nodeSize.i, noRenderLine.b, showOnLegend.b, showFloatingLabel.b, noRefresh.b) ; Adds a line to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\Line())
      For n = 0 To ArraySize(points())-1
        AddElement(GL_Graph()\Line()\pnt())
        CopyStructure(points(n), GL_Graph()\Line()\pnt(), POINTD)
      Next
      GL_Graph()\Line()\colour = colour
      GL_Graph()\Line()\label = label
      If lineThickness = #Null
        GL_Graph()\Line()\thickness = #GL_Default_lineThickness
      Else
        GL_Graph()\Line()\thickness = lineThickness
      EndIf
      GL_Graph()\Line()\nodeType = nodeType
      GL_Graph()\Line()\style = style
      If nodeSize = #Null
        GL_Graph()\Line()\nodeSize = #GL_Default_lineNodeSize
      Else
        GL_Graph()\Line()\nodeSize = nodeSize
      EndIf
      GL_Graph()\Line()\noLines = noRenderLine
      
      GL_Graph()\Line()\showOnLegend = showOnLegend
      GL_Graph()\Line()\showFloatingLabel = showFloatingLabel
      
      If GL_Graph()\Line()\showOnLegend = #True
        updateLegend(GL_Graph())
      EndIf
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
        
      retval = @GL_Graph()\Line()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

; callback takes the parameter *value.d (pointer to double precision value) and must return a colour value
Procedure AddGraphDensityPlot(id.i, minX.d, maxX.d, minY.d, maxY.d, Array density.d(2), minColour.l, maxColour.l, label.s, *callback, noRefresh.b) ; Adds a density plot to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\density())
      GL_Graph()\density()\label = label
      GL_Graph()\density()\xMin = minX
      GL_Graph()\density()\xMax = maxX
      GL_Graph()\density()\yMin = minY
      GL_Graph()\density()\yMax = maxY
      GL_Graph()\density()\minColour = minColour
      GL_Graph()\density()\maxColour = maxColour
      
      GL_Graph()\density()\gridlineColour = #GL_Default_densityGridlineColour
      GL_Graph()\density()\gridlineWidth = #GL_Default_densityGridlineThickness
      GL_Graph()\density()\showGridlines = #GL_Default_densityShowGridlines
      GL_Graph()\density()\showValues = #GL_Default_densityShowValues
      GL_Graph()\density()\showValuesOnHover = #GL_Default_densityShowValuesOnHover
      GL_Graph()\density()\valueFont = GL_Default_densityFont
      GL_Graph()\density()\valueColour = #GL_Default_densityValueColour
      
      GL_Graph()\density()\callback = *callback
      
      Dim GL_Graph()\density()\Plot(ArraySize(density(), 1), ArraySize(density(), 2))
      Dim GL_Graph()\density()\plotCache(ArraySize(density(), 1), ArraySize(density(), 2))
      CopyArray(density(), GL_Graph()\density()\Plot())
      
      ; find smallest value
      minValue.d = Infinity()
      For y = 0 To ArraySize(density(), 2)-1
        For x = 0 To ArraySize(density(), 1)-1
          If density(x, y) < minValue
            minValue = density(x, y)
          EndIf
        Next
      Next
      GL_Graph()\density()\minValue = minValue
      ;Debug "minValue: "+StrD(GL_Graph()\density()\minValue)
      
      ; find largest value
      maxValue.d = -Infinity()
      For y = 0 To ArraySize(density(), 2)-1
        For x = 0 To ArraySize(density(), 1)-1
          If density(x, y) > maxValue
            maxValue = density(x, y)
          EndIf
        Next
      Next
      GL_Graph()\density()\maxValue = maxValue
      ;Debug "maxValue: "+StrD(GL_Graph()\density()\maxValue)
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\density()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphDensityPlotGridlines(id.i, densityPlotID.i, showGridlines.b, thickness.i, colour.l, noRefresh.b) ; Sets a graph density plot gridlines 
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      ForEach GL_Graph()\density()
        
        If GL_Graph()\density() = densityPlotID
          
          GL_Graph()\density()\showGridlines = showGridlines
          GL_Graph()\density()\gridlineWidth = thickness
          GL_Graph()\density()\gridlineColour = colour
          
          If noRefresh = #False
            RefreshGraph(GL_Graph()\handle)
          EndIf
          
          retval = #True
          Break 2
        EndIf
        
      Next
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SetGraphDensityPlotValueOptions(id.i, densityPlotID.i, showValues.b, showValuesOnHover, noRefresh.b) ; Sets a graph density plot options 
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      ForEach GL_Graph()\density()
        
        If GL_Graph()\density() = densityPlotID
          
          GL_Graph()\density()\showValues = showValues
          GL_Graph()\density()\showValuesOnHover = showValuesOnHover
          
          If noRefresh = #False
            RefreshGraph(GL_Graph()\handle)
          EndIf
          
          retval = #True
          Break 2
        EndIf
        
      Next
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

Procedure AddGraphBars(id.i, Array bars.GL_GraphBar(1), isHorizontal.b, noRefresh.b) ; Adds a bar chart to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\bars())
      GL_Graph()\bars()\isHorizontal = isHorizontal
      
      Dim GL_Graph()\bars()\bar(ArraySize(bars()))
      CopyArray(bars(), GL_Graph()\bars()\bar())
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\bars()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL AddGraphFeatureLabel(id.i, label.s, colour.l, GL_Font.i, x.f, y.f, angle.f, noRefresh.b) ; Adds a feature text label to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\label())
      GL_Graph()\label()\label = label
      GL_Graph()\label()\colour = colour
      If GL_Font = #Null
        GL_Graph()\label()\font = GL_Default_font
      Else
        GL_Graph()\label()\font = GL_Font
      EndIf
      GL_Graph()\label()\x = x
      GL_Graph()\Label()\y = y
      GL_Graph()\Label()\angle = angle
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\label()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL AddGraphRuler(id.i, position.d, isHorizontal.b, label.s, colour.l, thickness.i, style.i, GL_Font.i, noRefresh.b) ; Adds a ruler to a graph
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      AddElement(GL_Graph()\ruler())
      GL_Graph()\ruler()\position = position
      GL_Graph()\ruler()\isHorizontal = isHorizontal
      GL_Graph()\ruler()\label = label
      GL_Graph()\ruler()\colour = colour
      If thickness <= 0
        thickness = 1
      EndIf
      GL_Graph()\ruler()\thickness = thickness
      Gl_Graph()\ruler()\style = style
      If GL_Font = #Null
        GL_Graph()\ruler()\font = GL_Default_rulerFont
      Else
        GL_Graph()\ruler()\font = GL_Font
      EndIf
      
      If noRefresh = #False
        RefreshGraph(GL_Graph()\handle)
      EndIf
      
      retval = @GL_Graph()\ruler()
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn retval
  
EndProcedure

ProcedureDLL SaveGraph(id.i, savePath.s, GL_DPI_Constant) ; Saves a graph as a TIFF image
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      If GL_DPI_Constant = #Null
        openGraphQualityWindow(GL_Graph(), GL_Command_Save)
        ProcedureReturn #False
      EndIf
      
      If savePath = ""
        savePath.s = SaveFileRequester("Save As TIFF image...", "", "TIFF image file (*.tiff;*.tif)|*.tiff;*.tif|All files (*.*)|*.*", 0)
        index = SelectedFilePattern()
      Else
        index = 1
      EndIf
      If index > -1 And savePath <> ""
        
        If GetExtensionPart(savePath) = ""
          savePath + ".tiff"
        EndIf
        
        SetCursor_(GL_waitMousePointer) ; change mouse pointer to hourglass as saving takes a few moments
        
        ; detach the main PanelEx onto the desktop and resize off screen for high DPI printing
        GL_detachForHighDPI()
        
        ; grab main PanelEx dc buffer, copy into image and save as TIFF with correct DPI
        dc = GetPanelExDC(GL_Graph()\Handle)
        
        GetClientRect_(GL_Graph()\Handle, rc.RECT)
        width = rc\right-rc\left
        height = rc\bottom-rc\top
        
        image = CreateImage(#PB_Any, width, height, 24)
        imagedc = StartDrawing(ImageOutput(image))
        BitBlt_(imagedc, 0, 0, width, height, dc, 0, 0, #SRCCOPY)
        
        ; re-attach main PanelEx onto main window
        GL_reattachForUI()
        
        If FileSize(savePath) > 0 And DeleteFile(savePath) = #False
          ShowErrorMsg("Error: File / Directory already exists and could not delete.")
          error = #True
        EndIf
        If error = #False; And GdiStart()
          compression = #EncoderValueCompressionLZW
          ; compression = #EncoderValueCompressionCCITT3
          ; compression = #EncoderValueCompressionCCITT4
          ; compression = #EncoderValueCompressionRle
          ; compression = #EncoderValueCompressionNone
          hbitmap = GetCurrentObject_(imagedc, #OBJ_BITMAP)
          success = SaveTIFF(hbitmap, savePath, compression, GL_Metric(GL_DPI_Constant)\DPI)
          ;GdiEnd()
        EndIf
        
        StopDrawing()
        
        FreeImage(image)
        
        SetCursor_(GL_normalMousePointer) ; change mouse pointer back to normal
        
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn success
  
EndProcedure

ProcedureDLL PrintGraph(id.i, GL_DPI_Constant)
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      If GL_DPI_Constant = #Null
        openGraphQualityWindow(GL_Graph(), GL_Command_Print)
        ProcedureReturn #False
      EndIf
      
      If PrintRequester()
        
        If StartPrinting("Graph: "+GL_Graph()\title)
          
          SetCursor_(GL_waitMousePointer) ; change mouse pointer to hourglass as saving takes a few moments
          
          ; detach the main PanelEx onto the desktop and resize off screen for high DPI printing
          GL_detachForHighDPI()
          
          ; grab main PanelEx dc buffer, copy into image and save as TIFF with correct DPI
          dc = GetPanelExDC(GL_Graph()\Handle)
          
          GetClientRect_(GL_Graph()\Handle, rc.RECT)
          width = rc\right-rc\left
          height = rc\bottom-rc\top
          
          image = CreateImage(#PB_Any, width, height, 24)
          imagedc = StartDrawing(ImageOutput(image))
          BitBlt_(imagedc, 0, 0, width, height, dc, 0, 0, #SRCCOPY)
          StopDrawing()
          
          ; re-attach main PanelEx onto main window
          GL_reattachForUI()
          
          If StartDrawing(PrinterOutput())
            
            DrawImage(ImageID(image), 0, 0, PrinterPageWidth(), PrinterPageHeight())
            
            StopDrawing()
            
            success = #True
            
          Else
            ShowErrorMsg("Error: Cannot draw to printer!")
          EndIf
          
          FreeImage(image)
          
          StopPrinting()
          
          SetCursor_(GL_normalMousePointer) ; change mouse pointer back to normal
          
        Else
          ShowErrorMsg("Error: Cannot print Graph: "+GL_Graph()\title+" print job!")
        EndIf
        
      EndIf
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn success
  
EndProcedure

ProcedureDLL CopyGraphToClipboard(id.i, GL_DPI_Constant)
  
  LockMutex(GL_graphMutex)
  PushListPosition(GL_Graph())
  ForEach GL_Graph()
    If GL_Graph()\id = id Or GL_Graph()\Handle = id
      
      If GL_DPI_Constant = #Null
        openGraphQualityWindow(GL_Graph(), GL_Command_Copy)
        ProcedureReturn #False
      EndIf
      
      ClearClipboard()
      SetCursor_(GL_waitMousePointer) ; change mouse pointer to hourglass as copying takes a few moments
      
      ; detach the main PanelEx onto the desktop and resize off screen for high DPI printing
      GL_detachForHighDPI()
      
      ; grab main PanelEx dc buffer, copy into image and save as TIFF with correct DPI
      dc = GetPanelExDC(GL_Graph()\Handle)
      
      GetClientRect_(GL_Graph()\Handle, rc.RECT)
      width = rc\right-rc\left
      height = rc\bottom-rc\top
      
      image = CreateImage(#PB_Any, width, height, 24)
      imagedc = StartDrawing(ImageOutput(image))
      BitBlt_(imagedc, 0, 0, width, height, dc, 0, 0, #SRCCOPY)
      StopDrawing()
      
      SetClipboardImage(image)
      
      FreeImage(image)
      
      ; re-attach main PanelEx onto main window
      GL_reattachForUI()
      
      SetCursor_(GL_normalMousePointer) ; change mouse pointer back to normal
      
      Break
      
    EndIf
  Next
  PopListPosition(GL_Graph())
  UnlockMutex(GL_graphMutex)
  
  ProcedureReturn success
    
EndProcedure

; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 12
; FirstLine = 12
; Folding = ------------------
; Markers = 958
; EnableXP