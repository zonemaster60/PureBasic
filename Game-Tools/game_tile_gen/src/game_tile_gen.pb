; ====================================================================
; Tile Generator for Map Editors
; PureBasic v6.30+ (Windows)
; Generates seamless/auto-tiling tiles and tilesheets.
; Based on game_sprite_gen.pb
; ====================================================================

EnableExplicit

#TILE_SIZE = 32
#PREVIEW_SCALE = 8
#MAX_COLORS = 16
#APP_NAME = "Game_Tile_Gen"

Global version.s = "v1.0.0.0"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Structure TileData
  Array pixels.l(#TILE_SIZE, #TILE_SIZE)
  width.l
  height.l
  name.s
EndStructure

Structure ColorPalette
  Array colors.l(#MAX_COLORS)
  numColors.l
  name.s
EndStructure

Enumeration
  #Window
  #ListPalette
  #ListTileType
  #ButtonGenerate
  #ButtonSaveTile
  #ButtonExportTileset
  #CanvasPreview
  #TextSeed
  #StringSeed
  #CheckSymmetry
  #CheckOutline
  #TextComplexity
  #SpinComplexity
  #TextStatus
EndEnumeration

Enumeration TileTypeId
  #TileGrass
  #TileWater
  #TileDirt
  #TileStone
EndEnumeration

Global.TileData currentTile
Global.ColorPalette currentPalette
Global Dim palettes.ColorPalette(10)
Global randomSeed.l
Global NewList tileTypeIds.l()

Declare InitializePalettes()
Declare DrawTilePreview()
Declare GenerateTile(*tile.TileData, tileType.l, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateCurrentTile()
Declare SaveCurrentTile()
Declare ExportTileset()
Declare.l SaveTilePNG(filename.s, *tile.TileData)
Declare.l SaveTilesetPNG(filename.s)
Declare.l SaveTsx(filename.s, imageFilename.s)

Procedure ConfirmExit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If hMutex
      CloseHandle_(hMutex)
      hMutex = 0
    EndIf
    End
  EndIf
EndProcedure

Procedure.l RGB2(r.l, g.l, b.l)
  ProcedureReturn (r << 16) | (g << 8) | b
EndProcedure

Procedure.l RandomColor(*palette.ColorPalette)
  If *palette\numColors > 0
    ProcedureReturn *palette\colors(Random(*palette\numColors - 1))
  EndIf
  ProcedureReturn RGB2(Random(255), Random(255), Random(255))
EndProcedure

Procedure ClearTile(*tile.TileData)
  Protected x, y

  For y = 0 To #TILE_SIZE - 1
    For x = 0 To #TILE_SIZE - 1
      *tile\pixels(x, y) = 0
    Next
  Next
EndProcedure

Procedure SetPixel(*tile.TileData, x.l, y.l, color.l)
  If x >= 0 And x < #TILE_SIZE And y >= 0 And y < #TILE_SIZE
    *tile\pixels(x, y) = color
  EndIf
EndProcedure

Procedure.l GetPixel(*tile.TileData, x.l, y.l)
  If x >= 0 And x < #TILE_SIZE And y >= 0 And y < #TILE_SIZE
    ProcedureReturn *tile\pixels(x, y)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure DrawRectangle(*tile.TileData, x.l, y.l, w.l, h.l, color.l)
  Protected i, j

  For j = y To y + h - 1
    For i = x To x + w - 1
      SetPixel(*tile, i, j, color)
    Next
  Next
EndProcedure

Procedure ApplySymmetry(*tile.TileData)
  Protected x, y, color

  For y = 0 To #TILE_SIZE - 1
    For x = 0 To #TILE_SIZE / 2 - 1
      color = GetPixel(*tile, x, y)
      SetPixel(*tile, #TILE_SIZE - 1 - x, y, color)
    Next
  Next
EndProcedure

Procedure AddOutline(*tile.TileData, outlineColor.l)
  Protected x, y, i, j
  Protected NewList outline.l()

  For y = 0 To #TILE_SIZE - 1
    For x = 0 To #TILE_SIZE - 1
      If GetPixel(*tile, x, y) <> 0
        For j = -1 To 1
          For i = -1 To 1
            If GetPixel(*tile, x + i, y + j) = 0
              AddElement(outline())
              outline() = (x + i) | ((y + j) << 16)
            EndIf
          Next
        Next
      EndIf
    Next
  Next

  ForEach outline()
    x = outline() & $FFFF
    y = (outline() >> 16) & $FFFF
    SetPixel(*tile, x, y, outlineColor)
  Next
EndProcedure

Procedure GenerateTile(*tile.TileData, tileType.l, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected x, y
  Protected baseColor.l, detailColor.l, secondaryColor.l
  Protected noiseChance.l

  ClearTile(*tile)

  *tile\name = "Tile"
  *tile\width = #TILE_SIZE
  *tile\height = #TILE_SIZE

  baseColor = RandomColor(*palette)
  detailColor = RandomColor(*palette)
  secondaryColor = RandomColor(*palette)
  noiseChance = 10 + complexity / 3

  Select tileType
    Case #TileGrass
      *tile\name = "Grass"
      If *palette\numColors > 0 : baseColor = *palette\colors(0) : EndIf
      If *palette\numColors > 1 : detailColor = *palette\colors(1) : EndIf

      DrawRectangle(*tile, 0, 0, #TILE_SIZE, #TILE_SIZE, baseColor)
      For y = 0 To #TILE_SIZE - 1
        For x = 0 To #TILE_SIZE - 1
          If Random(100) < noiseChance
            SetPixel(*tile, x, y, detailColor)
          EndIf
        Next
      Next

    Case #TileWater
      *tile\name = "Water"
      If *palette\numColors > 0 : baseColor = *palette\colors(0) : EndIf
      If *palette\numColors > 1 : detailColor = *palette\colors(1) : EndIf
      If *palette\numColors > 2 : secondaryColor = *palette\colors(2) : EndIf

      DrawRectangle(*tile, 0, 0, #TILE_SIZE, #TILE_SIZE, baseColor)
      For y = 0 To #TILE_SIZE - 1
        For x = 0 To #TILE_SIZE - 1
          If (Sin((x + Random(4)) * 0.4) + Cos((y + Random(4)) * 0.4)) > 0.6 And Random(100) < (20 + complexity / 2)
            SetPixel(*tile, x, y, detailColor)
          ElseIf Random(100) < (complexity / 5)
            SetPixel(*tile, x, y, secondaryColor)
          EndIf
        Next
      Next

    Case #TileDirt
      *tile\name = "Dirt"
      If *palette\numColors > 0 : baseColor = *palette\colors(0) : EndIf
      If *palette\numColors > 1 : detailColor = *palette\colors(1) : EndIf
      If *palette\numColors > 2 : secondaryColor = *palette\colors(2) : EndIf

      DrawRectangle(*tile, 0, 0, #TILE_SIZE, #TILE_SIZE, baseColor)
      For y = 0 To #TILE_SIZE - 1
        For x = 0 To #TILE_SIZE - 1
          If Random(100) < (15 + complexity / 3)
            SetPixel(*tile, x, y, detailColor)
          ElseIf Random(100) < (5 + complexity / 10)
            SetPixel(*tile, x, y, secondaryColor)
          EndIf
        Next
      Next

    Case #TileStone
      *tile\name = "Stone"
      If *palette\numColors > 0 : baseColor = *palette\colors(0) : EndIf
      If *palette\numColors > 1 : secondaryColor = *palette\colors(1) : EndIf
      detailColor = RGB2(40, 40, 40)

      DrawRectangle(*tile, 0, 0, #TILE_SIZE, #TILE_SIZE, baseColor)
      For y = 0 To #TILE_SIZE - 1
        For x = 0 To #TILE_SIZE - 1
          If Random(100) < (10 + complexity / 3)
            SetPixel(*tile, x, y, secondaryColor)
          EndIf
        Next
      Next

      If complexity > 40
        For y = 3 To #TILE_SIZE - 4 Step 6
          For x = 0 To #TILE_SIZE - 1
            If Random(100) < 70
              SetPixel(*tile, x, y, detailColor)
            EndIf
          Next
        Next
      EndIf
  EndSelect

  If symmetry
    ApplySymmetry(*tile)
  EndIf
EndProcedure

Procedure DrawTilePreview()
  Protected x, y, color

  If StartDrawing(CanvasOutput(#CanvasPreview))
    Box(0, 0, GadgetWidth(#CanvasPreview), GadgetHeight(#CanvasPreview), RGB2(200, 200, 200))

    For y = 0 To #TILE_SIZE - 1
      For x = 0 To #TILE_SIZE - 1
        color = GetPixel(@currentTile, x, y)
        If color = 0
          Box(x * #PREVIEW_SCALE, y * #PREVIEW_SCALE, #PREVIEW_SCALE, #PREVIEW_SCALE, RGB2(255, 255, 255))
        Else
          Box(x * #PREVIEW_SCALE, y * #PREVIEW_SCALE, #PREVIEW_SCALE, #PREVIEW_SCALE, color)
        EndIf
      Next
    Next

    StopDrawing()
  EndIf
EndProcedure

Procedure.l SaveTilePNG(filename.s, *tile.TileData)
  Protected img, x, y, color

  img = CreateImage(#PB_Any, #TILE_SIZE, #TILE_SIZE, 32)
  If img
    StartDrawing(ImageOutput(img))
    For y = 0 To #TILE_SIZE - 1
      For x = 0 To #TILE_SIZE - 1
        color = GetPixel(*tile, x, y)
        If color = 0
          Plot(x, y, RGBA(0, 0, 0, 0))
        Else
          Plot(x, y, color | $FF000000)
        EndIf
      Next
    Next
    StopDrawing()

    SaveImage(img, filename, #PB_ImagePlugin_PNG)
    FreeImage(img)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s EscapeXml(s.s)
  Protected out.s = ReplaceString(s, "&", "&amp;")
  out = ReplaceString(out, "<", "&lt;")
  out = ReplaceString(out, ">", "&gt;")
  out = ReplaceString(out, Chr(34), "&quot;")
  ProcedureReturn out
EndProcedure

Procedure.s GetFileNameOnly(path.s)
  Protected name.s = GetFilePart(path)
  ProcedureReturn name
EndProcedure

Procedure.l SaveTilesetPNG(filename.s)
  Protected tileType, variant
  Protected img, x, y, px, py, color
  Protected symmetry, outline, complexity, paletteIndex
  Protected tilesetW, tilesetH
  Protected tileLocal.TileData

  paletteIndex = GetGadgetState(#ListPalette)
  complexity = GetGadgetState(#SpinComplexity)
  symmetry = GetGadgetState(#CheckSymmetry)
  outline = GetGadgetState(#CheckOutline)

  tilesetW = #TILE_SIZE * 16
  tilesetH = #TILE_SIZE * 4

  img = CreateImage(#PB_Any, tilesetW, tilesetH, 32)
  If img = 0
    ProcedureReturn #False
  EndIf

  StartDrawing(ImageOutput(img))
  Box(0, 0, tilesetW, tilesetH, RGBA(0, 0, 0, 0))

  For tileType = 0 To 3
    For variant = 0 To 15
      RandomSeed((randomSeed + tileType * 1000 + variant) & $7FFFFFFF)
      GenerateTile(@tileLocal, tileType, @palettes(paletteIndex), symmetry, complexity)
      If outline
        AddOutline(@tileLocal, RGB2(0, 0, 0))
      EndIf

      px = variant * #TILE_SIZE
      py = tileType * #TILE_SIZE

      For y = 0 To #TILE_SIZE - 1
        For x = 0 To #TILE_SIZE - 1
          color = GetPixel(@tileLocal, x, y)
          If color = 0
            Plot(px + x, py + y, RGBA(0, 0, 0, 0))
          Else
            Plot(px + x, py + y, color | $FF000000)
          EndIf
        Next
      Next
    Next
  Next

  StopDrawing()

  SaveImage(img, filename, #PB_ImagePlugin_PNG)
  FreeImage(img)

  ProcedureReturn #True
EndProcedure

Procedure.l SaveTsx(filename.s, imageFilename.s)
  Protected tsxName.s = GetFilePart(filename, #PB_FileSystem_NoExtension)
  Protected columns = 16
  Protected tileCount = 16 * 4
  Protected imgW = #TILE_SIZE * columns
  Protected imgH = #TILE_SIZE * 4
  Protected file
  Protected imageRef.s = EscapeXml(GetFileNameOnly(imageFilename))

  file = CreateFile(#PB_Any, filename)
  If file = 0
    ProcedureReturn #False
  EndIf

  WriteStringN(file, "<?xml version='1.0' encoding='UTF-8'?>")
  WriteStringN(file, "<tileset version='1.10' tiledversion='1.10.2' name='" + EscapeXml(tsxName) + "' tilewidth='" + Str(#TILE_SIZE) + "' tileheight='" + Str(#TILE_SIZE) + "' tilecount='" + Str(tileCount) + "' columns='" + Str(columns) + "'>")
  WriteStringN(file, "  <image source='" + imageRef + "' width='" + Str(imgW) + "' height='" + Str(imgH) + "'/>")

  ; Per-tile type labels (helps filtering in Tiled)
  Protected tileId, row
  Protected typeName.s
  For tileId = 0 To tileCount - 1
    row = tileId / columns
    Select row
      Case 0 : typeName = "grass"
      Case 1 : typeName = "water"
      Case 2 : typeName = "dirt"
      Case 3 : typeName = "stone"
      Default : typeName = "tile"
    EndSelect
    WriteStringN(file, "  <tile id='" + Str(tileId) + "' type='" + typeName + "'/>")
  Next

  WriteStringN(file, "</tileset>")
  CloseFile(file)

  ProcedureReturn #True
EndProcedure

Procedure InitializePalettes()
  Protected i

  ; Simple palettes tuned for tiles
  palettes(0)\name = "Grassland"
  palettes(0)\numColors = 4
  palettes(0)\colors(0) = RGB2(60, 160, 70)
  palettes(0)\colors(1) = RGB2(80, 180, 85)
  palettes(0)\colors(2) = RGB2(40, 140, 55)
  palettes(0)\colors(3) = RGB2(120, 200, 110)

  palettes(1)\name = "Ocean"
  palettes(1)\numColors = 4
  palettes(1)\colors(0) = RGB2(40, 100, 190)
  palettes(1)\colors(1) = RGB2(60, 140, 220)
  palettes(1)\colors(2) = RGB2(20, 70, 150)
  palettes(1)\colors(3) = RGB2(120, 200, 255)

  palettes(2)\name = "Dirt"
  palettes(2)\numColors = 4
  palettes(2)\colors(0) = RGB2(130, 90, 50)
  palettes(2)\colors(1) = RGB2(150, 110, 70)
  palettes(2)\colors(2) = RGB2(110, 70, 35)
  palettes(2)\colors(3) = RGB2(170, 130, 90)

  palettes(3)\name = "Stone"
  palettes(3)\numColors = 4
  palettes(3)\colors(0) = RGB2(140, 140, 140)
  palettes(3)\colors(1) = RGB2(170, 170, 170)
  palettes(3)\colors(2) = RGB2(110, 110, 110)
  palettes(3)\colors(3) = RGB2(210, 210, 210)

  For i = 4 To ArraySize(palettes())
    palettes(i)\name = "Palette " + Str(i)
    palettes(i)\numColors = 4
    palettes(i)\colors(0) = RGB2(Random(200), Random(200), Random(200))
    palettes(i)\colors(1) = RGB2(Random(200), Random(200), Random(200))
    palettes(i)\colors(2) = RGB2(Random(200), Random(200), Random(200))
    palettes(i)\colors(3) = RGB2(Random(200), Random(200), Random(200))
  Next

  currentPalette = palettes(0)
EndProcedure

Procedure PopulatePalettes()
  Protected i

  ClearGadgetItems(#ListPalette)
  For i = 0 To ArraySize(palettes())
    AddGadgetItem(#ListPalette, -1, palettes(i)\name)
  Next
  SetGadgetState(#ListPalette, 0)
EndProcedure

Procedure AddTileTypeItem(title.s, typeId.l)
  AddGadgetItem(#ListTileType, -1, title)
  AddElement(tileTypeIds())
  tileTypeIds() = typeId
EndProcedure

Procedure PopulateTileTypes()
  ClearGadgetItems(#ListTileType)
  ClearList(tileTypeIds())

  AddTileTypeItem("Grass", #TileGrass)
  AddTileTypeItem("Water", #TileWater)
  AddTileTypeItem("Dirt", #TileDirt)
  AddTileTypeItem("Stone", #TileStone)

  SetGadgetState(#ListTileType, 0)
EndProcedure

Procedure GenerateCurrentTile()
  Protected symmetry, outline, complexity
  Protected paletteIndex, typeIndex, tileType
  Protected inputSeed.s

  paletteIndex = GetGadgetState(#ListPalette)
  typeIndex = GetGadgetState(#ListTileType)

  If typeIndex < 0
    SetGadgetText(#TextStatus, "Select a tile type first.")
    ProcedureReturn
  EndIf

  ResetList(tileTypeIds())
  SelectElement(tileTypeIds(), typeIndex)
  tileType = tileTypeIds()

  symmetry = GetGadgetState(#CheckSymmetry)
  outline = GetGadgetState(#CheckOutline)
  complexity = GetGadgetState(#SpinComplexity)

  inputSeed = GetGadgetText(#StringSeed)
  If inputSeed <> ""
    randomSeed = Val(inputSeed)
  Else
    randomSeed = Random($7FFFFFFF)
    SetGadgetText(#StringSeed, Str(randomSeed))
  EndIf

  RandomSeed(randomSeed)
  GenerateTile(@currentTile, tileType, @palettes(paletteIndex), symmetry, complexity)

  If outline
    AddOutline(@currentTile, RGB2(0, 0, 0))
  EndIf

  DrawTilePreview()
  SetGadgetText(#TextStatus, "Generated: " + currentTile\name + " (Seed: " + Str(randomSeed) + ")")
  DisableGadget(#ButtonSaveTile, #False)
  DisableGadget(#ButtonExportTileset, #False)
EndProcedure

Procedure SaveCurrentTile()
  Protected filename.s = SaveFileRequester("Save Tile", "tile.png", "PNG Images (*.png)|*.png", 0)

  If filename
    If SaveTilePNG(filename, @currentTile)
      SetGadgetText(#TextStatus, "Saved: " + filename)
      MessageRequester("Success", "Tile saved successfully!", #PB_MessageRequester_Ok)
    Else
      SetGadgetText(#TextStatus, "Error: Failed to save file")
      MessageRequester("Error", "Failed to save tile!", #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure ExportTileset()
  Protected filenamePng.s = SaveFileRequester("Export Tileset Image", "tileset.png", "PNG Images (*.png)|*.png", 0)
  Protected filenameTsx.s

  If filenamePng = ""
    ProcedureReturn
  EndIf

  If SaveTilesetPNG(filenamePng) = 0
    SetGadgetText(#TextStatus, "Error: Failed to export PNG")
    MessageRequester("Error", "Failed to export tileset PNG!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  filenameTsx = GetPathPart(filenamePng) + GetFilePart(filenamePng, #PB_FileSystem_NoExtension) + ".tsx"
  If SaveTsx(filenameTsx, filenamePng) = 0
    SetGadgetText(#TextStatus, "Exported PNG, but TSX failed: " + filenamePng)
    MessageRequester("Warning", "Tileset PNG exported, but TSX creation failed.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  SetGadgetText(#TextStatus, "Exported: " + filenamePng + " + " + filenameTsx)
  MessageRequester("Success", "Tileset exported for Tiled (PNG + TSX).", #PB_MessageRequester_Ok)
EndProcedure

; ====================================================================
; Main Program
; ====================================================================

UsePNGImageEncoder()

If InitSprite()
  InitializePalettes()

  OpenWindow(#Window, 0, 0, 720, 560, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)

  TextGadget(#PB_Any, 10, 10, 150, 20, "Palette:")
  ListIconGadget(#ListPalette, 10, 30, 180, 200, "Palette", 160, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  PopulatePalettes()

  TextGadget(#PB_Any, 10, 240, 150, 20, "Tile Type:")
  ListIconGadget(#ListTileType, 10, 260, 180, 140, "Type", 160, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  PopulateTileTypes()

  TextGadget(#PB_Any, 210, 10, 200, 20, "Preview:")
  CanvasGadget(#CanvasPreview, 210, 30, #TILE_SIZE * #PREVIEW_SCALE, #TILE_SIZE * #PREVIEW_SCALE, #PB_Canvas_Border)

  FrameGadget(#PB_Any, 210, 290, 256, 140, "Options")

  CheckBoxGadget(#CheckSymmetry, 220, 310, 230, 20, "Vertical Symmetry")
  SetGadgetState(#CheckSymmetry, #True)

  CheckBoxGadget(#CheckOutline, 220, 335, 230, 20, "Add Black Outline")
  SetGadgetState(#CheckOutline, #False)

  TextGadget(#TextComplexity, 220, 355, 220, 20, "Detail (0-100):")
  SpinGadget(#SpinComplexity, 220, 375, 220, 25, 0, 100, #PB_Spin_Numeric)
  SetGadgetState(#SpinComplexity, 50)

  TextGadget(#TextSeed, 220, 405, 100, 20, "Random Seed:")
  StringGadget(#StringSeed, 305, 405, 140, 20, "")

  ButtonGadget(#ButtonGenerate, 500, 30, 200, 40, "Generate Tile")
  ButtonGadget(#ButtonSaveTile, 500, 80, 200, 35, "Save Tile PNG")
  ButtonGadget(#ButtonExportTileset, 500, 125, 200, 35, "Export Tileset (16x4)")

  TextGadget(#PB_Any, 500, 180, 200, 80, "Tileset layout: 4 rows (types) x 16 cols (variants)." + #CRLF$ + "Row0=Grass Row1=Water Row2=Dirt Row3=Stone")

  FrameGadget(#PB_Any, 10, 420, 690, 130, "Status")
  TextGadget(#TextStatus, 20, 445, 670, 95, "Ready. Select a palette and tile type, then click Generate.")

  DisableGadget(#ButtonSaveTile, #True)
  DisableGadget(#ButtonExportTileset, #True)

  currentTile\width = #TILE_SIZE
  currentTile\height = #TILE_SIZE
  ClearTile(@currentTile)
  DrawTilePreview()

  Define event

  Repeat
    event = WaitWindowEvent()

    Select event
      Case #PB_Event_CloseWindow
        ConfirmExit()

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ButtonGenerate
            GenerateCurrentTile()

          Case #ButtonSaveTile
            SaveCurrentTile()

          Case #ButtonExportTileset
            ExportTileset()
        EndSelect
    EndSelect
  ForEver

Else
  MessageRequester("Error", "Failed to initialize sprite system!", #PB_MessageRequester_Error)
EndIf

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 611
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = game_tile_gen.ico
; Executable = ..\Game_Tile_Gen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = Game_Tile_Gen
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = A configurable game tile generator
; VersionField7 = Game_Tile_Gen
; VersionField8 = Game_Tile_Gen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60