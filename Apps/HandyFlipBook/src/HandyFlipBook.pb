; HandyFlipBook

#APP_NAME = "HandyFlipBook"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.1.0"
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
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
   Declare Clear(*book.FlipBook)
   Declare Free(*book.FlipBook)
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
   
    Procedure Free(*book.FlipBook)
       If *book
          Clear(*book)
          FreeStructure(*book)
       EndIf
    EndProcedure

    Procedure Clear(*book.FlipBook)
       Protected i.i

       If *book = 0
          ProcedureReturn
       EndIf

       For i = 0 To ArraySize(*book\page())
          If IsImage(*book\page(i))
             FreeImage(*book\page(i))
          EndIf
       Next

       ReDim *book\page(0)
       *book\nrPages = 0
       *book\currentPage = 0
       *book\cornerX = 0
       *book\cornerY = 0
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
      Protected.d m, c, d
      If Abs(x3 - x2) < #epsilon
         *resultX\d = 2 * x3 - x1
         *resultY\d = y1
      Else
         m = (y3 - y2) / (x3 - x2)
         c = y2 - m * x2
         d = (x1 + (y1 - c) * m) / (1 + m * m)
         *resultX\d = 2 * d - x1
         *resultY\d = 2 * d * m - y1 + 2 * c
      EndIf
   EndProcedure
   
   Procedure DrawHighlight(x1, y1, x2, y2, x3, y3, x4, y4, width, flags = #PB_Path_Default)
      Protected nx.d = y1 - y2
      Protected ny.d = x2 - x1
      Protected di.d = Sqr(nx * nx + ny * ny)
      Protected di1.d, di2.d
      If di < #epsilon : ProcedureReturn : EndIf
      di1 = Sqr(Pow(x1 - x3,2) + Pow(y1 - y3, 2))
      di2 = Sqr(Pow(x2 - x4,2) + Pow(y2 - y4, 2))
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
      Protected di.d = Sqr(nx * nx + ny * ny)
      Protected dx.d, dy.d, di2.d
      If di < #epsilon : ProcedureReturn : EndIf
      dx = (x1 + x2) * 0.5 - (x3 + x4) * 0.5
      dy = (y1 + y2) * 0.5 - (y3 + y4) * 0.5
      di2 = Sqr(dx*dx+dy*dy)    
      VectorSourceLinearGradient(x1, y1, x1 + (nx / di) * width, y1 + (ny / di) * width)
      VectorSourceGradientColor(RGBA(0,0,0,alpha * Clamp(1 - Abs(di2 / width), 0, 1)), 1)     
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

   Procedure DrawStaticPageWithHighlight(*book.FlipBook, pageNr.i, x.d, y.d, width.d, height.d, highlightDirection.i)
      If pageNr < 0 Or pageNr > ArraySize(*book\page())
         ProcedureReturn
      EndIf

      DrawPage(*book, pageNr, x, y)
      SaveVectorState()
      AddPathBox(x, y, width, height)
      ClipPath()
      DrawHighlight(x, y, x, y + height,
                    x + width, y, x + width, y + height,
                    highlightDirection)
      RestoreVectorState()
   EndProcedure

   Procedure DrawLeftStaticPage(*book.FlipBook)
      Protected pageNr.i

      If *book\currentPage <= 0 Or *book\currentPage > *book\nrPages + 1
         ProcedureReturn
      EndIf

      If *book\currentPage > *book\nrPages
         pageNr = *book\nrPages
      Else
         pageNr = *book\currentPage - 1
      EndIf

      DrawStaticPageWithHighlight(*book, pageNr, -*book\width * 1.5, -*book\height * 0.5, *book\width, *book\height, -1)
   EndProcedure

   Procedure DrawRightStaticPage(*book.FlipBook)
      If (*book\currentPage + 1) < 0 Or (*book\currentPage + 1) > *book\nrPages
         ProcedureReturn
      EndIf

      DrawStaticPageWithHighlight(*book, *book\currentPage, -*book\width * 0.5, -*book\height * 0.5, *book\width, *book\height, 1)
   EndProcedure
    
   Procedure DrawBook(*book.FlipBook, x, y, doAnimation = #True)
      Protected nextPageNr
      Protected.d nx, ny, di
      Protected.d px1, py1, px2, py2
      Protected.d midX, midY, midX1, midY1, midX2, midY2
      If StartVectorDrawing(CanvasVectorOutput(*book\canvasID)) = 0
         ProcedureReturn
      EndIf
      
      ; Clear background
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
      
      DrawLeftStaticPage(*book)
      DrawRightStaticPage(*book)
      
      If doAnimation
         ; calculate mirror axis
         midX = (x + *book\cornerX) * 0.5
         midY = (y + *book\cornerY) * 0.5         
         
         If Abs(*book\cornerX - midX) < #epsilon
            nx = 1000000 ; Large value
         Else
            nx = Pow(*book\cornerY - midY, 2) / (*book\cornerX - midX)
         EndIf
         
         If Abs(*book\cornerY - midY) < #epsilon
            ny = 1000000
         Else
            ny = Pow(*book\cornerX - midX, 2) / (*book\cornerY - midY)
         EndIf
         
         midX1 = Clamp(midX - nx, -Abs(*book\cornerX), Abs(*book\cornerX))
         midY1 = *book\cornerY        
         If ((*book\cornerY < 0) And ((midY - ny) < -*book\cornerY) And (y > *book\cornerY)) Or
            ((*book\cornerY > 0) And ((midY - ny) > -*book\cornerY) And (y < *book\cornerY))
            ; mirror axis crosses vertical edge
            midX2 = *book\cornerX
            midY2 = midY - ny
         Else
            ; mirror axis crosses horizontal edge
            If Abs(midY1 - midY) < #epsilon
               midX2 = midX1
            Else
               midX2 = Clamp(MidX1 + (*book\height * (midX - midX1) / (midY1 - midY)) * Sign(*book\cornerY), -Abs(*book\cornerX), Abs(*book\cornerX))
            EndIf
            midY2 = -*book\cornerY
         EndIf       
         
         ; mirror the page corners
         Mirror(*book\cornerX, *book\cornerY, midX1,midY1,midX2,midY2,@px1,@py1)
         Mirror(*book\cornerX, -*book\cornerY,midX1,midY1,midX2,midY2,@px2,@py2)        
         If (*book\cornerX > 0 And px2 > *book\cornerX) Or (*book\cornerX < 0 And px2 < *book\cornerX)
            px2 = midX2
            py2 = midY2
         EndIf       
         
         SaveVectorState()
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
            SaveVectorState()
            ClipPath()
            DrawPage(*book, nextPageNr + Sign(*book\cornerX) * 2, -*book\width * 0.5, -*book\height * 0.5)
            
            AddPathBox(-*book\width * 0.5, -*book\height * 0.5, *book\width, *book\height)
            DrawHighlight(-*book\width * 0.5, -*book\height * 0.5, -*book\width * 0.5, *book\height * 0.5,
                          *book\width * 0.5, -*book\height * 0.5, *book\width * 0.5, *book\height * 0.5,
                          Sign(*book\cornerX), #PB_Path_Preserve)
            
            DrawShadow(midX1, midY1, midX2, midY2,
                       *book\cornerX, *book\cornerY, *book\cornerX, -*book\cornerY,
                       *book\width * Sign(-*book\cornerY * *book\cornerX), 0.95, 200)
            RestoreVectorState()
         EndIf
         RestoreVectorState()
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
            If EventGadget() = *book\canvasID
               mx = GetGadgetAttribute(*book\canvasID, #PB_Canvas_MouseX)
               my = GetGadgetAttribute(*book\canvasID, #PB_Canvas_MouseY)
               
               Select EventType()
                  Case #PB_EventType_LeftButtonDown
                     If autoFlip = 0
                        If Abs(mx - (*book\x - *book\width * 0.5)) > *book\width * 0.65
                           *book\cornerX = *book\width * Sign(mx - *book\x) * 0.5
                           *book\cornerY = *book\height * Sign(my - *book\y) * 0.5
                           If (*book\currentPage + Sign(*book\cornerX)) >= 0 And (*book\currentPage + Sign(*book\cornerX)) <= *book\nrPages
                              lButton = 1
                           EndIf
                        EndIf
                     EndIf
                  Case #PB_EventType_LeftButtonUp
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
                  Case #PB_EventType_MouseMove
                     If autoFlip = 0 And lButton
                        If *book\cornerX < 0
                           mx + *book\width
                        EndIf
                        grabX = (mx - *book\x)
                        grabY = (my - *book\y)
                        DrawBook(*book, grabX, grabY)
                     EndIf
               EndSelect
            EndIf
      EndSelect
   EndProcedure  
   DisableExplicit
EndModule

UseModule FlipBook

#Window_Main  = 0
#Gadget_Canvas = 0
#Gadget_Web    = 1

#ViewMode_FlipBook = 1
#ViewMode_Web      = 2

Global ColorCanvasBackground.i = RGBA(36, 32, 28, 255)
Global ColorPageBackground.i   = RGBA(247, 242, 230, 255)
Global ColorPageBorder.i       = RGBA(124, 108, 88, 255)
Global ColorCoverBackground.i  = RGBA(86, 112, 80, 255)
Global ColorCoverAccent.i      = RGBA(228, 235, 214, 255)
Global ColorText.i             = RGBA(34, 30, 26, 255)

Global CurrentViewMode.i = #ViewMode_FlipBook
Global CurrentTempDirectory.s
Global WebViewerAvailable.i

Procedure CleanupTempDirectory()
  If CurrentTempDirectory <> "" And FileSize(CurrentTempDirectory) = -2
    DeleteDirectory(CurrentTempDirectory, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
  EndIf
  CurrentTempDirectory = ""
EndProcedure

Procedure.i EnsureDirectoryExists(directory.s)
  Protected normalized.s = ReplaceString(directory, "/", "\\")
  Protected currentPath.s
  Protected part.s
  Protected partCount.i
  Protected i.i

  If normalized = ""
    ProcedureReturn #True
  EndIf

  If Right(normalized, 1) = "\\"
    normalized = Left(normalized, Len(normalized) - 1)
  EndIf

  If FileSize(normalized) = -2
    ProcedureReturn #True
  EndIf

  If Len(normalized) >= 3 And Mid(normalized, 2, 2) = ":\\"
    currentPath = Left(normalized, 3)
    normalized = Mid(normalized, 4)
  EndIf

  partCount = CountString(normalized, "\\") + 1
  For i = 1 To partCount
    part = StringField(normalized, i, "\\")
    If part <> ""
      currentPath + part + "\\"
      If FileSize(currentPath) <> -2
        If CreateDirectory(currentPath) = 0
          ProcedureReturn #False
        EndIf
      EndIf
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.s CreateTempWorkspace(prefix.s)
  Protected tempRoot.s = GetTemporaryDirectory() + #APP_NAME + "\\"
  Protected tempDirectory.s

  If EnsureDirectoryExists(tempRoot) = 0
    ProcedureReturn ""
  EndIf

  tempDirectory = tempRoot + prefix + "-" + FormatDate("%yyyy%mm%dd-%hh%ii%ss", Date()) + "-" + Str(Random(999999)) + "\\"
  If EnsureDirectoryExists(tempDirectory)
    ProcedureReturn tempDirectory
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i IsSafeArchiveEntry(entryName.s)
  Protected normalized.s = ReplaceString(entryName, "/", "\\")
  Protected part.s
  Protected i.i
  Protected partCount.i

  If normalized = ""
    ProcedureReturn #False
  EndIf

  If Left(normalized, 1) = "\\" Or FindString(normalized, ":", 1)
    ProcedureReturn #False
  EndIf

  partCount = CountString(normalized, "\\") + 1
  For i = 1 To partCount
    part = StringField(normalized, i, "\\")
    If part = ".."
      ProcedureReturn #False
    EndIf
  Next

  If FindString(normalized, "\\\\", 1)
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.s NormalizeArchivePath(basePath.s, relativePath.s)
  Protected normalizedBase.s = ReplaceString(basePath, "/", "\\")
  Protected normalizedRelative.s = ReplaceString(relativePath, "/", "\\")
  Protected combinedPath.s
  Protected part.s
  Protected i.i
  Protected partCount.i
  NewList pathParts.s()

  If normalizedRelative = ""
    ProcedureReturn ""
  EndIf

  If Left(normalizedRelative, 1) = "\\" Or FindString(normalizedRelative, ":", 1)
    ProcedureReturn ""
  EndIf

  combinedPath = normalizedBase + normalizedRelative
  partCount = CountString(combinedPath, "\\") + 1

  For i = 1 To partCount
    part = StringField(combinedPath, i, "\\")
    Select part
      Case "", "."
        Continue
      Case ".."
        If ListSize(pathParts()) = 0
          ProcedureReturn ""
        EndIf
        LastElement(pathParts())
        DeleteElement(pathParts())
      Default
        AddElement(pathParts())
        pathParts() = part
    EndSelect
  Next

  If ListSize(pathParts()) = 0
    ProcedureReturn ""
  EndIf

  combinedPath = ""
  ForEach pathParts()
    If combinedPath <> ""
      combinedPath + "\\"
    EndIf
    combinedPath + pathParts()
  Next

  ProcedureReturn combinedPath
EndProcedure

Procedure.s ToFileUrl(fileName.s)
  Protected url.s = ReplaceString(fileName, "\\", "/")

  url = ReplaceString(url, "%", "%25")
  url = ReplaceString(url, "#", "%23")
  url = ReplaceString(url, "?", "%3F")
  url = ReplaceString(url, " ", "%20")

  ProcedureReturn "file:///" + url
EndProcedure

Procedure.i FindFirstNodeByName(node.i, nodeName.s)
  Protected foundNode.i
  Protected childNode.i

  If node = 0
    ProcedureReturn 0
  EndIf

  If LCase(GetXMLNodeName(node)) = LCase(nodeName)
    ProcedureReturn node
  EndIf

  childNode = ChildXMLNode(node)
  While childNode
    foundNode = FindFirstNodeByName(childNode, nodeName)
    If foundNode
      ProcedureReturn foundNode
    EndIf
    childNode = NextXMLNode(childNode)
  Wend

  ProcedureReturn 0
EndProcedure

Procedure.s ExtractEpubStartDocument(epubFile.s)
  Protected pack.i
  Protected tempDirectory.s
  Protected entryName.s
  Protected normalizedEntry.s
  Protected targetFile.s
  Protected targetDirectory.s
  Protected fallbackDocument.s
  Protected rootFile.s
  Protected normalizedRootFile.s
  Protected opfFile.s
  Protected startDocument.s
  Protected opfDirectory.s
  Protected manifestItemPath.s
  Protected relativeStartDocument.s
  Protected xml.i
  Protected manifestNode.i
  Protected spineNode.i
  Protected rootFileNode.i
  Protected childNode.i
  Protected idRef.s
  NewMap manifestItems.s()

  CleanupTempDirectory()
  tempDirectory = CreateTempWorkspace("epub")
  If tempDirectory = ""
    ProcedureReturn ""
  EndIf

  UseZipPacker()
  pack = OpenPack(#PB_Any, epubFile, #PB_PackerPlugin_Zip)
  If pack = 0
    CleanupTempDirectory()
    ProcedureReturn ""
  EndIf

  CurrentTempDirectory = tempDirectory
  If ExaminePack(pack)
    While NextPackEntry(pack)
      entryName = PackEntryName(pack)
      normalizedEntry = ReplaceString(entryName, "/", "\\")

      If IsSafeArchiveEntry(normalizedEntry)
        If Right(normalizedEntry, 1) = "\\"
          EnsureDirectoryExists(tempDirectory + normalizedEntry)
        Else
          targetFile = tempDirectory + normalizedEntry
          targetDirectory = GetPathPart(targetFile)
          If targetDirectory = "" Or EnsureDirectoryExists(targetDirectory)
            If UncompressPackFile(pack, targetFile, entryName) <> -1 And fallbackDocument = ""
              Select LCase(GetExtensionPart(normalizedEntry))
                Case "html", "htm", "xhtml"
                  fallbackDocument = targetFile
              EndSelect
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
  EndIf
  ClosePack(pack)

  xml = LoadXML(#PB_Any, tempDirectory + "META-INF\\container.xml")
  If xml
    rootFileNode = FindFirstNodeByName(MainXMLNode(xml), "rootfile")
    If rootFileNode
      rootFile = ReplaceString(GetXMLAttribute(rootFileNode, "full-path"), "/", "\\")
    EndIf
    FreeXML(xml)
  EndIf

  If rootFile <> ""
    normalizedRootFile = ReplaceString(rootFile, "/", "\\")
    If IsSafeArchiveEntry(normalizedRootFile)
      opfFile = tempDirectory + normalizedRootFile
      If FileSize(opfFile) >= 0
        xml = LoadXML(#PB_Any, opfFile)
        If xml
          manifestNode = FindFirstNodeByName(MainXMLNode(xml), "manifest")
          If manifestNode
            childNode = ChildXMLNode(manifestNode)
            While childNode
              If LCase(GetXMLNodeName(childNode)) = "item"
                manifestItemPath = NormalizeArchivePath(GetPathPart(normalizedRootFile), GetXMLAttribute(childNode, "href"))
                If manifestItemPath <> ""
                  manifestItems(GetXMLAttribute(childNode, "id")) = manifestItemPath
                EndIf
              EndIf
              childNode = NextXMLNode(childNode)
            Wend
          EndIf

          spineNode = FindFirstNodeByName(MainXMLNode(xml), "spine")
          If spineNode
            opfDirectory = GetPathPart(normalizedRootFile)
            childNode = ChildXMLNode(spineNode)
            While childNode
              If LCase(GetXMLNodeName(childNode)) = "itemref" And LCase(GetXMLAttribute(childNode, "linear")) <> "no"
                idRef = GetXMLAttribute(childNode, "idref")
                If FindMapElement(manifestItems(), idRef)
                  relativeStartDocument = manifestItems()
                  If IsSafeArchiveEntry(relativeStartDocument)
                    startDocument = tempDirectory + relativeStartDocument
                    If FileSize(startDocument) < 0
                      startDocument = ""
                    EndIf
                  EndIf
                  Break
                EndIf
              EndIf
              childNode = NextXMLNode(childNode)
            Wend
          EndIf
          FreeXML(xml)
        EndIf
      EndIf
    EndIf
  EndIf

  If startDocument = "" And fallbackDocument <> "" And FileSize(fallbackDocument) >= 0
    startDocument = fallbackDocument
  EndIf

  If startDocument = ""
    CleanupTempDirectory()
  EndIf

  ProcedureReturn startDocument
EndProcedure

Procedure UpdateWindowTitle(displayName.s, modeLabel.s)
  SetWindowTitle(#Window_Main, #APP_NAME + " " + version + " - " + modeLabel + ": '" + displayName + "'")
EndProcedure

Procedure.i ShowWebDocument(documentPath.s, displayName.s, modeLabel.s)
  If WebViewerAvailable = 0
    MessageRequester("Error", "Embedded web viewing is unavailable on this system. PDF and EPUB viewing need WebView support.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  HideGadget(#Gadget_Canvas, #True)
  HideGadget(#Gadget_Web, #False)
  SetGadgetText(#Gadget_Web, ToFileUrl(documentPath))
  CurrentViewMode = #ViewMode_Web
  UpdateWindowTitle(displayName, modeLabel)
  ProcedureReturn #True
EndProcedure

Procedure ResizeDocumentView(*book.FlipBook)
  If IsWindow(#Window_Main) = 0
    ProcedureReturn
  EndIf

  ResizeGadget(#Gadget_Canvas, 0, 0, WindowWidth(#Window_Main), WindowHeight(#Window_Main))
  If WebViewerAvailable
    ResizeGadget(#Gadget_Web, 0, 0, WindowWidth(#Window_Main), WindowHeight(#Window_Main))
  EndIf

  If *book
    *book\x = DesktopScaledX((GadgetWidth(#Gadget_Canvas) - 5) * 0.75)
    *book\y = DesktopScaledY(GadgetHeight(#Gadget_Canvas) * 0.5)
    If CurrentViewMode = #ViewMode_FlipBook
      DrawBook(*book, 0, 0, #False)
    EndIf
  EndIf
EndProcedure

Procedure ShowFlipBookDocument(*book.FlipBook, displayName.s)
  If WebViewerAvailable
    HideGadget(#Gadget_Web, #True)
  EndIf
  HideGadget(#Gadget_Canvas, #False)
  CurrentViewMode = #ViewMode_FlipBook
  UpdateWindowTitle(displayName, "Reading")
  DrawBook(*book, 0, 0, #False)
EndProcedure

Procedure.i AddCoverPage(*book.FlipBook, displayName.s, footerText.s)
  Protected pageNr.i = AddPage(*book, #True, ColorCoverBackground, ColorCoverAccent, 6)

  If StartVectorDrawing(ImageVectorOutput(*book\page(pageNr)))
    AddPathBox(30, 30, *book\width - 60, *book\height - 60)
    VectorSourceColor(RGBA(238, 242, 226, 64))
    FillPath()

    VectorFont(FontID(0), DesktopScaledY(28))
    VectorSourceColor(ColorCoverAccent)
    MovePathCursor(40, 70)
    DrawVectorParagraph(#APP_NAME, *book\width - 80, DesktopScaledY(40), #PB_VectorParagraph_Center)

    VectorFont(FontID(0), DesktopScaledY(16))
    MovePathCursor(50, 150)
    DrawVectorParagraph(displayName, *book\width - 100, *book\height - 220, #PB_VectorParagraph_Center)

    VectorFont(FontID(0), DesktopScaledY(10))
    MovePathCursor(60, *book\height - 120)
    DrawVectorParagraph("Use the mouse to flip pages.", *book\width - 120, 20, #PB_VectorParagraph_Center)
    MovePathCursor(60, *book\height - 90)
    DrawVectorParagraph(footerText, *book\width - 120, 20, #PB_VectorParagraph_Center)
    StopVectorDrawing()
  EndIf

  ProcedureReturn pageNr
EndProcedure

Procedure.s GetWrappedTextChunk(text.s, maxWidth.d, *consumed.Integer)
  Protected i.i
  Protected lastBreak.i
  Protected chunk.s

  If text = ""
    *consumed\i = 0
    ProcedureReturn ""
  EndIf

  If VectorTextWidth(text) <= maxWidth
    *consumed\i = Len(text)
    ProcedureReturn text
  EndIf

  For i = 1 To Len(text)
    chunk = Left(text, i)
    If VectorTextWidth(chunk) > maxWidth
      Break
    EndIf

    Select Mid(text, i, 1)
      Case " ", "-", "/", "\\"
        lastBreak = i
    EndSelect
  Next

  If lastBreak > 0
    *consumed\i = lastBreak
    ProcedureReturn RTrim(Left(text, lastBreak))
  EndIf

  *consumed\i = i - 1
  If *consumed\i < 1
    *consumed\i = 1
  EndIf
  ProcedureReturn Left(text, *consumed\i)
EndProcedure

Procedure.i AddTextDocumentPages(*book.FlipBook, fileName.s, displayName.s)
  Protected fileID.i
  Protected pageNr.i
  Protected y.d
  Protected lineText.s
  Protected pendingLine.s
  Protected pendingReady.i
  Protected pendingBlank.i
  Protected lineHeight.d
  Protected maxTextWidth.d
  Protected maxTextY.d
  Protected chunk.s
  Protected consumed.Integer

  fileID = ReadFile(#PB_Any, fileName)
  If fileID = 0
    MessageRequester("Error", "Unable to open '" + displayName + "'.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  Clear(*book)
  AddCoverPage(*book, displayName, "Text document viewer")
  AddPage(*book, #True, ColorPageBackground, ColorPageBorder, 4)

  While Eof(fileID) = 0 Or pendingReady
    pageNr = AddPage(*book, #True, ColorPageBackground, ColorPageBorder, 4)
    If StartVectorDrawing(ImageVectorOutput(*book\page(pageNr)))
      VectorSourceColor(ColorText)
      VectorFont(FontID(0), DesktopScaledY(10))
      y = 28
      lineHeight = VectorTextHeight("Ag") + 3
      maxTextWidth = *book\width - 56
      maxTextY = *book\height - 70
      AddPathBox(24, 22, *book\width - 48, *book\height - 58)
      ClipPath()

      Repeat
        If pendingReady = 0
          If Eof(fileID)
            Break
          EndIf

          lineText = ReplaceString(ReadString(fileID), Chr(9), "    ")
          pendingLine = lineText
          pendingBlank = Bool(pendingLine = "")
          pendingReady = #True
        EndIf

        If y > maxTextY
          Break
        EndIf

        If pendingBlank
          y + lineHeight
          pendingReady = #False
        Else
          chunk = GetWrappedTextChunk(pendingLine, maxTextWidth, @consumed)
          MovePathCursor(28, y)
          DrawVectorText(chunk)
          y + lineHeight

          pendingLine = LTrim(Mid(pendingLine, consumed\i + 1))
          If pendingLine = ""
            pendingReady = #False
          EndIf
        EndIf
      Until y > maxTextY Or (Eof(fileID) And pendingReady = 0)

      MovePathCursor(0, *book\height - 32)
      DrawVectorParagraph("Page " + Str(*book\nrPages - 2), *book\width, 24, #PB_VectorParagraph_Center)
      StopVectorDrawing()
    EndIf
  Wend

  CloseFile(fileID)

  If (*book\nrPages & 1) = 0
    AddPage(*book, #True, ColorPageBackground, ColorPageBorder, 4)
  EndIf
  AddCoverPage(*book, displayName, "Changes by: " + #EMAIL_NAME)

  ProcedureReturn #True
EndProcedure

Procedure.i LoadDocument(*book.FlipBook, fileName.s, displayName.s)
  Protected extension.s = LCase(GetExtensionPart(fileName))
  Protected epubDocument.s

  Select extension
    Case "pdf"
      ProcedureReturn ShowWebDocument(fileName, displayName, "Viewing PDF")

    Case "epub"
      epubDocument = ExtractEpubStartDocument(fileName)
      If epubDocument = ""
        MessageRequester("Error", "Unable to open EPUB content from '" + displayName + "'.", #PB_MessageRequester_Error)
        ProcedureReturn #False
      EndIf
      ProcedureReturn ShowWebDocument(epubDocument, displayName, "Viewing EPUB")

    Case "html", "htm", "xhtml"
      ProcedureReturn ShowWebDocument(fileName, displayName, "Viewing Document")

    Default
      If AddTextDocumentPages(*book, fileName, displayName)
        ShowFlipBookDocument(*book, displayName)
        ProcedureReturn #True
      EndIf
  EndSelect

  ProcedureReturn #False
EndProcedure

Declare Shutdown(*book.FlipBook = 0)

Procedure.i ConfirmExit(*book.FlipBook)
  Protected req.i

  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If req = #PB_MessageRequester_Yes
    Shutdown(*book)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure Shutdown(*book.FlipBook = 0)
  If *book
    Free(*book)
  EndIf

  CleanupTempDirectory()

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

CompilerIf #PB_Compiler_IsMainFile
  Define filename.s
  Define filename2.s
  Define event.i
  Define quit.i
  Define *book.FlipBook

  filename = OpenFileRequester("Open a document", "", "Supported Documents|*.txt;*.log;*.cfg;*.ini;*.json;*.xml;*.md;*.csv;*.bat;*.cmd;*.pb;*.pbi;*.fb2;*.html;*.htm;*.xhtml;*.pdf;*.epub|Text Documents|*.txt;*.log;*.cfg;*.ini;*.json;*.xml;*.md;*.csv;*.bat;*.cmd;*.pb;*.pbi;*.fb2|Web Documents|*.html;*.htm;*.xhtml|PDF Files|*.pdf|EPUB Files|*.epub|All Files|*.*", 0)
  filename2 = GetFilePart(filename)

  If filename = ""
    Shutdown()
    End
  EndIf

  If OpenWindow(#Window_Main, 0, 0, 900, 700, #APP_NAME + " " + version, #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_SizeGadget)
    CanvasGadget(#Gadget_Canvas, 0, 0, WindowWidth(#Window_Main), WindowHeight(#Window_Main))
    SetGadgetAttribute(#Gadget_Canvas, #PB_Canvas_Cursor, #PB_Cursor_Hand)

    WebViewerAvailable = WebGadget(#Gadget_Web, 0, 0, WindowWidth(#Window_Main), WindowHeight(#Window_Main), "about:blank", #PB_Web_Edge)
    If WebViewerAvailable = 0
      WebViewerAvailable = WebGadget(#Gadget_Web, 0, 0, WindowWidth(#Window_Main), WindowHeight(#Window_Main), "about:blank")
    EndIf
    If WebViewerAvailable
      HideGadget(#Gadget_Web, #True)
    EndIf

    *book = New(#Gadget_Canvas, (GadgetWidth(#Gadget_Canvas) - 5) * 0.75, GadgetHeight(#Gadget_Canvas) * 0.5, GadgetWidth(#Gadget_Canvas) * 0.5 - 10, GadgetHeight(#Gadget_Canvas) - 20, ColorCanvasBackground)

    If LoadFont(0, "Georgia", 9) = 0
      LoadFont(0, "Arial", 9)
    EndIf

    If *book = 0 Or LoadDocument(*book, filename, filename2) = 0
      Shutdown(*book)
      End
    EndIf

    Repeat
      event = WaitWindowEvent()
      Select event
        Case #PB_Event_Timer, #PB_Event_Gadget
          If CurrentViewMode = #ViewMode_FlipBook
            HandleEvent(*book, event)
          EndIf

        Case #PB_Event_SizeWindow
          ResizeDocumentView(*book)

        Case #PB_Event_CloseWindow
          quit = ConfirmExit(*book)
      EndSelect
    Until quit
  Else
    Shutdown()
  EndIf

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 5
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyFlipBook.ico
; Executable = ..\HandyFlipBook.exe
; IncludeVersionInfo
; VersionField0 = 1,0,1,0
; VersionField1 = 1,0,1,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyFlipBook
; VersionField4 = 1.0.1.0
; VersionField5 = 1.0.1.0
; VersionField6 = Handy Flip Book for viewing text, PDF, and EPUB files
; VersionField7 = HandyFlipBook
; VersionField8 = HandyFlipBook.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60