;PB4.00
;20061127, now works with unicode executables

Declare createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
Declare.s getSpecialFolder(id)

Procedure.s getSpecialFolder(id)
  Protected path.s, *ItemId.ITEMIDLIST
 
  *itemId = #Null
  If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
    path = Space(#MAX_PATH)
    If SHGetPathFromIDList_(*itemId, @path)
      If Right(path, 1) <> "\"
        path + "\"
      EndIf
      ProcedureReturn path
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
  ;obj - path to the exe that is linked to, lnk - link name, dir - working
  ;directory, icon - path to the icon file, index - icon index in iconfile
  Protected hRes.l, mem.s, ppf.IPersistFile
  CompilerIf #PB_Compiler_Unicode
    Protected psl.IShellLinkW
  CompilerElse
    Protected psl.IShellLinkA
  CompilerEndIf

  ;make shure COM is active
  CoInitialize_(0)
  hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)

  If hRes = 0
    psl\SetPath(Obj)
    psl\SetArguments(arg)
    psl\SetDescription(desc)
    psl\SetWorkingDirectory(dir)
    psl\SetIconLocation(icon, index)
    ;query IShellLink for the IPersistFile interface for saving the
    ;link in persistent storage
    hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)

    If hRes = 0
      ;CompilerIf #PB_Compiler_Unicode
        ;save the link
        hRes = ppf\Save(lnk, #True)
;       CompilerElse
;         ;ensure that the string is ansi unicode
;         mem = Space(#MAX_PATH)
;         MultiByteToWideChar_(#CP_ACP, 0, lnk, -1, mem, #MAX_PATH)
;         ;save the link
;         hRes = ppf\Save(mem, #True)
;       CompilerEndIf
      ppf\Release()
    EndIf
    psl\Release()
  EndIf

  ;shut down COM
  CoUninitialize_()

  DataSection
    CLSID_ShellLink:
    Data.l $00021401
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IShellLink:
    CompilerIf #PB_Compiler_Unicode
      Data.l $000214F9
    CompilerElse
      Data.l $000214EE
    CompilerEndIf
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IPersistFile:
    Data.l $0000010b
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
  EndDataSection
  ProcedureReturn hRes
EndProcedure

#CSIDL_WINDOWS = $24
#CSIDL_DESKTOPDIRECTORY = $10

Global obj.s, obj2.s, lnk.s, lnk2.s

obj = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyFlipBook\HandyFlipBook.exe"
obj2 = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyFlipBook"
lnk = getSpecialFolder(#CSIDL_ALTSTARTUP)
lnk2 = getSpecialFolder(#CSIDL_DESKTOPDIRECTORY)

; check for existence of desktop link
If FileSize(lnk2 + "HandyFlipBook.lnk") = -1
  If createShellLink(obj, lnk2 + "HandyFlipBook.lnk", "", "Start HandyFlipBook", obj2, obj, 0) = 0
    MessageRequester("Info", "A Desktop link was created.", #PB_MessageRequester_Info)
  EndIf
EndIf

DeclareModule FlipBook
   Structure FlipBook
      Array page.i(0)
      canvasID.i
      x.d
      y.d
      width.d
      height.d
      nrPages.i
      currentPage.i
      cornerX.l
      cornerY.l
      backgroundColor.i
   EndStructure
   
   Declare New(canvasID, x, y, width, height, backgroundColor)
   Declare AddPage(*book.FlipBook, makeImage, color, borderColor, borderWidth.d)
   Declare DrawBook(*book.FlipBook, x, y, doAnimation = #True)
   Declare HandleEvent(*book.FlipBook, event)
EndDeclareModule

Module FlipBook
   EnableExplicit
   
   #epsilon = 0.0000001
   #flipTimer = 1000
   
   Procedure.d Clamp(value.d, min.d, max.d)
      If value < min
         ProcedureReturn min
      ElseIf value > max
         ProcedureReturn max
      EndIf
      ProcedureReturn value
   EndProcedure
   
   Procedure New(canvasID, x, y, width, height,backgroundColor)
      Protected *book.FlipBook = AllocateStructure(FlipBook)
      If *book
         *book\canvasID = canvasID
         *book\x = DesktopScaledX(x)
         *book\y = DesktopScaledY(y)
         *book\width = DesktopScaledX(width)
         *book\height = DesktopScaledY(height)
         *book\backgroundColor = backgroundColor
      EndIf
      ProcedureReturn *book
   EndProcedure
   
   Procedure AddPage(*book.FlipBook, makeImage, color, borderColor, borderWidth.d)
      If *book
         Protected pageNr = *book\nrPages
         *book\nrPages + 1
         ReDim *book\page(*book\nrPages)
         If makeImage
            *book\page(pageNr) = CreateImage(#PB_Any, *book\width, *book\height, 32, color)
            If IsImage(*book\page(pageNr)) And StartVectorDrawing(ImageVectorOutput(*book\page(pageNr)))
               AddPathBox(0, 0, *book\width, *book\height)
               VectorSourceColor(borderColor)
               StrokePath(borderWidth, #PB_Path_Preserve)
               VectorSourceColor(RGBA(128,128,128,200))
               StrokePath(4)
               StopVectorDrawing()
            EndIf
         EndIf
         ProcedureReturn pageNr
      EndIf
      ProcedureReturn 0
   EndProcedure
   
   Procedure Mirror(x1,y1.d,x2.d,y2.d,x3.d,y3.d, *resultX.Double, *resultY.Double)
      Protected m.d = (y3 - y2) / (x3 - x2 + #epsilon)
      Protected c.d = (x3 * y2 - x2 * y3) / (x3 - x2 + #epsilon)
      Protected d.d = (x1 + (y1 - c) * m) / (1 + m * m + #epsilon)
      *resultX\d = 2 * d - x1
      *resultY\d = 2 * d * m - y1 + 2 * c
   EndProcedure
   
   Procedure DrawHighlight(x1, y1, x2, y2, x3, y3, x4, y4, width, flags = #PB_Path_Default)
      Protected nx.d = y1 - y2
      Protected ny.d = x2 - x1
      Protected di.d = Sqr(nx * nx + ny * ny) + #epsilon
      Protected di1.d = Sqr(Pow(x1 - x3,2) + Pow(y1 - y3, 2))
      Protected di2.d = Sqr(Pow(x2 - x4,2) + Pow(y2 - y4, 2))
      If di1 > di2
         VectorSourceLinearGradient(x1, y1, x1 - (nx / di) * di1 * width, y1 - (ny / di) * di1 * width)
      Else
         VectorSourceLinearGradient(x2, y2, x2 - (nx / di) * di2 * width, y2 - (ny / di) * di2 * width)
      EndIf
      VectorSourceGradientColor(RGBA(225,225,225,0), 1.0)
      VectorSourceGradientColor(RGBA(255,255,255,0), 0.8)
      VectorSourceGradientColor(RGBA(200,200,200,64), 0.3)
      VectorSourceGradientColor(RGBA(255,255,255,128), 0.1)
      VectorSourceGradientColor(RGBA(0,0,0,64), 0.0)
      FillPath(flags)
   EndProcedure
   
   Procedure DrawShadow(x1.d, y1.d, x2.d, y2.d, x3.d, y3.d, x4.d, y4.d, width.d, pos.d, alpha)
      Protected nx.d = y1 - y2
      Protected ny.d = x2 - x1
      Protected di.d = Sqr(nx * nx + ny * ny) + #epsilon    
      Protected dx.d = (x1 + x2) * 0.5 - (x3 + x4) * 0.5
      Protected dy.d = (y1 + y2) * 0.5 - (y3 + y4) * 0.5
      Protected di2.d = Sqr(dx*dx+dy*dy)    
      VectorSourceLinearGradient(x1, y1, x1 + (nx / di) * width, y1 + (ny / di) * width)
      VectorSourceGradientColor(RGBA(0,0,0,alpha * (1 - Abs(di2 / width))), 1)     
      VectorSourceGradientColor(RGBA(255,255,255,0), pos)
      VectorSourceGradientColor(RGBA(255,255,255,0), 0)
      FillPath()
   EndProcedure
   
   Procedure DrawPage(*book.FlipBook, pageNr, x, y)
      If pageNr >= 0 And pageNr <= ArraySize(*book\page()) And IsImage(*book\page(pageNr))
         MovePathCursor(x, y)
         DrawVectorImage(ImageID(*book\page(pageNr)))
      EndIf
   EndProcedure
   
   Procedure DrawBook(*book.FlipBook, x, y, doAnimation = #True)
      Protected nextPageNr
      Protected.d nx, ny, di
      Protected.d px1, py1, px2, py2
      Protected.d midX, midY, midX1, midY1, midX2, midY2
      If StartVectorDrawing(CanvasVectorOutput(*book\canvasID)) = 0
         ProcedureReturn
      EndIf
      VectorSourceColor(*book\backgroundColor)
      FillVectorOutput()      
      TranslateCoordinates(*book\x, *book\y)     
      If *book\cornerX > 0
         nextPageNr = *book\currentPage
         x = Clamp(x, -*book\width * 1.5 + 1 , *book\width * 0.5 - 1)
      Else
         nextPageNr = *book\currentPage - 1
         x = Clamp(x, -*book\width * 0.5 - 1 , *book\width * 1.5 + 1)
      EndIf     
      ; draw left page if this is not the first page
      If *book\currentPage > 0 And *book\currentPage <= *book\nrPages + 1
         If *book\currentPage > *book\nrPages
            DrawPage(*book, *book\nrPages, -*book\width * 1.5, -*book\height * 0.5)
         Else
            DrawPage(*book, *book\currentPage - 1, -*book\width * 1.5, -*book\height * 0.5)
         EndIf
         AddPathBox(-*book\width * 1.5, -*book\height * 0.5, *book\width, *book\height)
         DrawHighlight(-*book\width * 1.5, -*book\height * 0.5, -*book\width * 1.5, *book\height * 0.5,
                       -*book\width * 0.5, -*book\height * 0.5, -*book\width * 0.5, *book\height * 0.5, -1)
      EndIf
      ; draw right page if this is not the last page
      If (*book\currentPage + 1) >= 0 And (*book\currentPage + 1) <= *book\nrPages
         DrawPage(*book, *book\currentPage, -*book\width * 0.5, -*book\height * 0.5)
         AddPathBox(-*book\width * 0.5, -*book\height * 0.5, *book\width, *book\height)
         DrawHighlight(-*book\width * 0.5, -*book\height * 0.5, -*book\width * 0.5, *book\height * 0.5,
                       *book\width * 0.5, -*book\height * 0.5, *book\width * 0.5, *book\height * 0.5,  1)
      EndIf    
      If doAnimation
         ; calculate mirror axis
         midX = (x + *book\cornerX) * 0.5
         midY = (y + *book\cornerY) * 0.5         
         nx = Pow(*book\cornerY - midY, 2) / (*book\cornerX - midX + #epsilon)
         ny = Pow(*book\cornerX - midX, 2) / (*book\cornerY - midY + #epsilon)         
         midX1 = Clamp(midX - nx, -Abs(*book\cornerX), Abs(*book\cornerX))
         midY1 = *book\cornerY        
         If ((*book\cornerY < 0) And ((midY - ny) < -*book\cornerY) And (y > *book\cornerY)) Or
            ((*book\cornerY > 0) And ((midY - ny) > -*book\cornerY) And (y < *book\cornerY))
            ; mirror axis crosses vertical edge
            midX2 = *book\cornerX
            midY2 = midY - ny
         Else
            ; mirror axis crosses horizontal edge
            midX2 = Clamp(MidX1 + (*book\height * (midX - midX1) / (midY1 - midY - #epsilon)) * Sign(*book\cornerY), -Abs(*book\cornerX), Abs(*book\cornerX))
            midY2 = -*book\cornerY
         EndIf       
         ; mirror the page corners
         Mirror(*book\cornerX, *book\cornerY, midX1,midY1,midX2,midY2,@px1,@py1)
         Mirror(*book\cornerX, -*book\cornerY,midX1,midY1,midX2,midY2,@px2,@py2)        
         If (*book\cornerX > 0 And px2 > *book\cornerX) Or (*book\cornerX < 0 And px2 < *book\cornerX)
            px2 = midX2
            py2 = midY2
         EndIf       
         If *book\cornerX < 0
            TranslateCoordinates(-*book\width, 0)
         EndIf        
         ; rotate and draw image
         If nextPageNr + Sign(*book\cornerX) >= 0 And nextPageNr + Sign(*book\cornerX) <= *book\nrPages
            MovePathCursor(midX1, midY1)
            AddPathLine(midX2, midY2)
            AddPathLine(px2 - (1 - Abs((*book\width * 0.5 * Sign(*book\cornerX) + px2) / *book\width)) * DesktopScaledX(50) * Sign(*book\cornerX), py2)
            AddPathLine(px1 - (1 - Abs((*book\width * 0.5 * Sign(*book\cornerX) + px1) / *book\width)) * DesktopScaledX(50) * Sign(*book\cornerX), py1)
            DrawShadow(midX1, midY1, midX2, midY2,
                       -*book\cornerX, *book\cornerY, *book\cornerX, -*book\cornerY,
                       *book\width * Sign(*book\cornerY * *book\cornerX), 0, 128)           
            MovePathCursor(midX1, midY1)
            AddPathLine(midX2, midY2)
            AddPathLine(px2,py2)
            AddPathLine(px1,py1)
            ClosePath()         
            SaveVectorState()
            ClipPath(#PB_Path_Preserve)          
            SaveVectorState()          
            If *book\cornerY < 0
               If *book\cornerX > 0
                  RotateCoordinates(px1, py1, Degree(-ATan2(py2 - py1, px2 - px1)))
                  DrawPage(*book, nextPageNr + Sign(*book\cornerX), px1, py1)
               Else
                  RotateCoordinates(px1, py1, Degree(-ATan2(py1 - py2, px1 - px2)) + 180)
                  DrawPage(*book, nextPageNr + Sign(*book\cornerX), px1 - *book\width, py1)
               EndIf
            Else
               RotateCoordinates(px1, py1, Degree(-ATan2(py1 - py2, px1 - px2)))
               If *book\cornerX > 0
                  DrawPage(*book, nextPageNr + Sign(*book\cornerX), px1, py1 - *book\height)
               Else
                  DrawPage(*book, nextPageNr + Sign(*book\cornerX), px1 - *book\width , py1 - *book\height)
               EndIf
            EndIf           
            RestoreVectorState()
            DrawHighlight(midX1, midY1, midX2, midY2, px1, py1, px2, py2, Sign(*book\cornerY * *book\cornerX))
            RestoreVectorState()
         EndIf        
         MovePathCursor(midX1, midY1)
         AddPathLine(midX2,midY2)
         AddPathLine(*book\cornerX + Sign(*book\cornerX), -*book\cornerY - Sign(*book\cornerY))
         AddPathLine(*book\cornerX + Sign(*book\cornerX),  *book\cornerY + Sign(*book\cornerY))
         ClosePath()
         If nextPageNr + Sign(*book\cornerX) * 2 < 0 Or nextPageNr + Sign(*book\cornerX) * 2 >= *book\nrPages
            VectorSourceColor(*book\backgroundColor)
            FillPath()
         Else
            ClipPath()
            DrawPage(*book, nextPageNr + Sign(*book\cornerX) * 2, -*book\width * 0.5, -*book\height * 0.5)
            
            AddPathBox(-*book\width * 0.5, -*book\height * 0.5, *book\width, *book\height)
            
            DrawHighlight(-*book\width * 0.5, -*book\height * 0.5, -*book\width * 0.5, *book\height * 0.5,
                          *book\width * 0.5, -*book\height * 0.5, *book\width * 0.5, *book\height * 0.5,
                          Sign(*book\cornerX), #PB_Path_Preserve)
            
            DrawShadow(midX1, midY1, midX2, midY2,
                       *book\cornerX, *book\cornerY, *book\cornerX, -*book\cornerY,
                       *book\width * Sign(-*book\cornerY * *book\cornerX), 0.95, 200)
            
         EndIf
      EndIf    
      StopVectorDrawing()
   EndProcedure
   
   Procedure HandleEvent(*book.FlipBook, event)
      Protected mx.d, my.d
      Static lButton, autoFlip, grabX.d, grabY.d, targetX.d, targetY.d, nextPage   
      Select event
         Case #PB_Event_Timer
            If EventTimer() = #flipTimer
               If autoFlip
                  If (Abs(targetX - grabX)) > 1
                     grabX + (targetX - grabX) * 0.3
                     grabY + (targetY - grabY) * 0.3
                     DrawBook(*book, grabX, grabY)
                  Else
                     *book\currentPage = nextPage
                     autoFlip = 0
                     RemoveWindowTimer(0, #flipTimer)
                     DrawBook(*book, targetX, targetY, #False)
                  EndIf
               EndIf
            EndIf
         Case #PB_Event_Gadget
            mx = GetGadgetAttribute(*book\canvasID, #PB_Canvas_MouseX)
            my = GetGadgetAttribute(*book\canvasID, #PB_Canvas_MouseY)
            
            If EventType() = #PB_EventType_LeftButtonDown
               If Abs(mx - (*book\x - *book\width * 0.5)) > *book\width * 0.65
                  *book\cornerX = *book\width * Sign(mx - *book\x) * 0.5
                  *book\cornerY = *book\height * Sign(my - *book\y) * 0.5
                  If (*book\currentPage + Sign(*book\cornerX)) >= 0 And (*book\currentPage + Sign(*book\cornerX)) <= *book\nrPages
                     lButton = 1
                  EndIf
               EndIf
            ElseIf EventType() = #PB_EventType_LeftButtonUp
               If lButton
                  lButton = 0
                  If ((*book\cornerX > 0) And ((mx - *book\x) < *book\width * 0.25)) Or
                     ((*book\cornerX < 0) And ((mx - *book\x) > -*book\width * 1.25))
                     nextPage = *book\currentPage + 2 * Sign(*book\cornerX)
                     targetX = *book\width * 1.5 * Sign(-*book\cornerX)
                     targetY = *book\cornerY
                  Else
                     targetX = *book\cornerX
                     targetY = *book\cornerY
                  EndIf
                  AddWindowTimer(0, #flipTimer, 25)
                  autoFlip = 1
               EndIf
            ElseIf EventType() = #PB_EventType_MouseMove
               If autoFlip = 0 And lButton
                  If *book\cornerX < 0
                     mx + *book\width
                  EndIf
                  grabX = (mx - *book\x)
                  grabY = (my - *book\y)
                  DrawBook(*book, grabX, grabY)
                  Delay(25)
               EndIf
            EndIf
      EndSelect
      
   EndProcedure  
   DisableExplicit
EndModule

CompilerIf #PB_Compiler_IsMainFile
  ; enter the name of the file here
  Define vers.s = "v0.0.0.4 (20242404)"
  Define filename.s = OpenFileRequester("Open a file", "",
                                      "All Files|*.*|Script Files|*.bat;*.cmd|Source Files|*.pb;*.pbi|Text Files|*.txt",0)
  Define filename2.s = GetFilePart(filename)
   OpenWindow(0,0,0,800,600,"HandyFlipBook "+vers+" - Viewing file: '"+filename2+"'",#PB_Window_ScreenCentered | #PB_Window_SystemMenu)
   CanvasGadget(0,0,0,WindowWidth(0),WindowHeight(0))
   SetGadgetAttribute(0, #PB_Canvas_Cursor, #PB_Cursor_Hand) ; <= add this line
   
   UseModule FlipBook
   *book.FlipBook = New(0, (GadgetWidth(0) - 5) * 0.75, GadgetHeight(0) * 0.5, GadgetWidth(0) * 0.5 - 10, GadgetHeight(0) - 20, RGBA(32,32,32,255))
   ; change font size here
   LoadFont(0, "Arial", 8)
   ; change the #PB_Compiler_File to a text file of your choosing
   If Not ReadFile(0, filename)
     CloseWindow(0)
     MessageRequester("Error:","No file to read!",#PB_MessageRequester_Error)
     End
   Else
      pageNr = AddPage(*book, #True,RGBA(32, 200, 32, 255), RGBA(255,255,255,255),5)
      StartVectorDrawing(ImageVectorOutput(*book\page(pageNr)))
      ScaleCoordinates(DesktopResolutionX(), DesktopResolutionY())
      AddPathCircle(195,200,175)
      VectorSourceColor(RGBA(128, 250, 128, 255))
      StrokePath(15)
      VectorFont(FontID(0))
      ScaleCoordinates(2 / DesktopResolutionX(), 2 / DesktopResolutionY())
      MovePathCursor(DesktopScaledX(-100), DesktopScaledY(250))
      DrawVectorParagraph("Use the mouse to flip the pages!",*book\width,*book\height,#PB_VectorParagraph_Center)
      DrawVectorParagraph("<<< Changes by: zonemaster60 >>>",*book\width,*book\height,#PB_VectorParagraph_Center)
      DrawVectorParagraph("<<< Original code by Mr. L.! >>>",*book\width,*book\height,#PB_VectorParagraph_Center)
      ScaleCoordinates(2, 2)
      VectorSourceColor(RGBA(255, 255, 255, 255))
      MovePathCursor(DesktopScaledX(-145), DesktopScaledY(40))
      DrawVectorParagraph("HandyFlipBook" + #CRLF$ + #CRLF$ + "'" + filename2 + "'" + #CRLF$ + #CRLF$,*book\width,*book\height,#PB_VectorParagraph_Center)     
      StopVectorDrawing()
      AddPage(*book, #True, RGBA(200, 200, 200, 255), RGBA(255,255,255,255), 5)
      While Not Eof(0)
         pageNr = AddPage(*book, #True, RGBA(Random(255,128), Random(255,128), Random(255,128), 255), RGBA(255,255,255,255),20)
         StartVectorDrawing(ImageVectorOutput(*book\page(pageNr)))
         VectorSourceColor(RGBA(0, 0, 0, 255))
         VectorFont(FontID(0))
         y = 25
         AddPathBox(10, 10, *book\width - 20, *book\height - 20)
         ClipPath()
         Repeat
            MovePathCursor(15.5, y+0.5)
            DrawVectorText(ReplaceString(ReadString(0), Chr(9), " "))
            y + VectorTextHeight(" ")
         Until y > *book\height - 65 Or Eof(0)
         MovePathCursor(0, *book\height - 30)
         DrawVectorParagraph("Page " + Str(*book\nrPages - 2), *book\width, 30, #PB_VectorParagraph_Center)
         StopVectorDrawing()
      Wend
      If (*book\nrPages & 1) = 0
        AddPage(*book, #True, RGBA(200, 200, 200, 255), RGBA(255,255,255,255), 5)
      EndIf
      AddPage(*book, #True,RGBA(32, 200, 32, 255), RGBA(255,255,255,255), 5)    
   EndIf     
   DrawBook(*book, 0, 0, #False)
   Repeat
      event = WaitWindowEvent()
      HandleEvent(*book, event)
    Until event = #PB_Event_CloseWindow
    Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
      If Req = #PB_MessageRequester_Yes
        End
      EndIf
CompilerEndIf

; IDE Options = PureBasic 6.11 LTS Beta 1 (Windows - x64)
; CursorPosition = 414
; FirstLine = 411
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = HandyFlipBook.ico
; Executable = HandyFlipBook.exe
; IncludeVersionInfo
; VersionField0 = 0,0,0,1
; VersionField1 = 0,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = HandyFlipBook.exe
; VersionField4 = v0.0.0.4
; VersionField5 = v0.0.0.1
; VersionField6 = Handy Flip Book for viewing text files
; VersionField7 = HandyFlipBook.exe
; VersionField8 = HandyFlipBook.exe
; VersionField9 = David Scouten
; VersionField10 = David Scouten
; VersionField13 = zonemaster@yahoo.com