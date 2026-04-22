; ====================================================================
; Sprite Generator for Games
; PureBasic v6.30 Beta 6
; Creates pixel art sprites with various themes
; ====================================================================

EnableExplicit

#SPRITE_SIZE = 32
#PREVIEW_SCALE = 8
#PREVIEW_SIZE = #SPRITE_SIZE * #PREVIEW_SCALE
#EXPORT_SCALE = 8
#EXPORT_SIZE = #SPRITE_SIZE * #EXPORT_SCALE
#MAX_COLORS = 16
#THEME_COUNT = 8
#APP_NAME = "Game_Sprite_Gen"

Global version.s = "v1.0.0.3"
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

Structure SpriteData
  Array pixels.l(#SPRITE_SIZE, #SPRITE_SIZE)
  width.l
  height.l
  name.s
EndStructure

Enumeration SpriteTypeId
  #TypeSpaceShip
  #TypeAlien
  #TypeRobot
  #TypeTree
  #TypeAnimal
  #TypeCar
  #TypeCrystal
  #TypeWeapon
  #TypeBuilding
  #TypeMonster
  #TypePowerUp
  #TypePlanet
  #TypeFood
  #TypeParticle
  #TypeTerrain
  #TypeTank
  #TypeHelicopter
  #TypeJet
  #TypeSoldier
  #TypeHumvee
  #TypeSpaceShuttle
  #TypeRocket
  #TypeSatellite
  #TypeSpaceStation
  #TypeLunarLander
  #TypeStarFighter
  #TypeCapitalShip
  #TypeCargo
  #TypeScout
  #TypeMiningShip
  #TypeSportsCar
  #TypeSedan
  #TypeSUV
  #TypePickupTruck
  #TypeSemiTruck
  #TypeVan
  #TypeMotorcycle
  #TypeScooter
  #TypeRaceCar
  #TypeBus
EndEnumeration

Enumeration ThemeId
  #ThemeSpace
  #ThemeNature
  #ThemeFire
  #ThemeOcean
  #ThemeMetal
  #ThemeCandy
  #ThemeMilitary
  #ThemeUrban
EndEnumeration

Structure ColorPalette
  Array colors.l(#MAX_COLORS)
  numColors.l
  name.s
EndStructure

Structure ThemeTypeEntry
  themeId.l
  title.s
  typeId.l
EndStructure

Enumeration
  #Window
  #ListTheme
  #ListType
  #ButtonGenerate
  #ButtonRandomSeed
  #ButtonSave
  #ButtonExport
  #CanvasPreview
  #TextSeed
  #StringSeed
  #ComboSymmetry
  #CheckOutline
  #TextComplexity
  #SpinComplexity
  #TextStatus
EndEnumeration

Global.SpriteData currentSprite
Global.ColorPalette currentPalette
Global Dim themePalettes.ColorPalette(#THEME_COUNT - 1)
Global Dim themeLabels.s(#THEME_COUNT - 1)
Global Dim spriteGenerators.i(#TypeBus)
Global randomSeed.l
Global hasGeneratedSprite.i
Global NewList themeTypeEntries.ThemeTypeEntry()
Global NewList typeIds.l()

Declare GenerateSpaceShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateAlien(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateRobot(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateTree(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateAnimal(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateCrystal(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateWeapon(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateBuilding(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateMonster(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GeneratePowerUp(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GeneratePlanet(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateFood(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateParticle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateTerrain(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateTank(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateHelicopter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateJet(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSoldier(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateHumvee(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSpaceShuttle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateRocket(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSatellite(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSpaceStation(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateLunarLander(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateStarFighter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateCapitalShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateCargo(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateScout(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateMiningShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSportsCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSedan(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSUV(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GeneratePickupTruck(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateSemiTruck(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateVan(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateMotorcycle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateScooter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateRaceCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare GenerateBus(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
Declare ApplySymmetry(*sprite.SpriteData, symmetryType.l)
Declare AddOutline(*sprite.SpriteData, outlineColor.l)
Declare GenerateCurrentSprite()
Declare SaveCurrentSprite()
Declare ExportSpriteLarge()
Declare InitializeGeneratorRegistry()
Declare InitializeThemeLabels()
Declare AddThemeTypeEntry(themeId.l, title.s, typeId.l)
Declare InitializeTypeEntries()
Declare PopulateThemeList()
Declare UpdateThemeTypes()
Declare InitializePalettes()
Declare DrawSpritePreview()
Declare.i GetSelectedSpriteType(selectedIndex.l)
Declare ShowSaveResult(success.i, successText.s, errorText.s, statusText.s)
Declare.l SaveRenderedSprite(filename.s, *sprite.SpriteData, imageSize.l, scale.l)
Declare.l RenderSpriteImage(*sprite.SpriteData, imageId.i, scale.l)
Declare.l SaveSpritePNG(filename.s, *sprite.SpriteData)
Declare.l RGB2(r.l, g.l, b.l)
Declare.l RandomColor(*palette.ColorPalette)
Declare.i IsValidSeedText(text.s)
Declare ClearSprite(*sprite.SpriteData)
Declare SetPixel(*sprite.SpriteData, x.l, y.l, color.l)
Declare.l GetPixel(*sprite.SpriteData, x.l, y.l)
Declare DrawRectangle(*sprite.SpriteData, x.l, y.l, w.l, h.l, color.l)
Declare DrawCircle(*sprite.SpriteData, cx.l, cy.l, radius.l, color.l)
Declare CleanupAndExit()
Declare SetStatus(text.s)
Declare UpdateExportButtons(hasSprite.i)


; Exit procedure
Procedure CleanupAndExit()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf

  End
EndProcedure

Procedure ConfirmExit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CleanupAndExit()
  EndIf
EndProcedure

Procedure SetStatus(text.s)
  If IsGadget(#TextStatus)
    SetGadgetText(#TextStatus, text)
  EndIf
EndProcedure

Procedure UpdateExportButtons(hasSprite.i)
  If IsGadget(#ButtonSave)
    DisableGadget(#ButtonSave, Bool(hasSprite = 0))
  EndIf

  If IsGadget(#ButtonExport)
    DisableGadget(#ButtonExport, Bool(hasSprite = 0))
  EndIf
EndProcedure

Procedure.l RGB2(r.l, g.l, b.l)
  ProcedureReturn (r << 16) | (g << 8) | b
EndProcedure

Procedure.l RandomColor(*palette.ColorPalette)
  If *palette\numColors > 0
    ProcedureReturn *palette\colors(Random(*palette\numColors - 1))
  Else
    ProcedureReturn RGB2(Random(255), Random(255), Random(255))
  EndIf
EndProcedure

Procedure.i IsValidSeedText(text.s)
  Protected i, char.s

  If text = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(text)
    char = Mid(text, i, 1)
    If char < "0" Or char > "9"
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure ClearSprite(*sprite.SpriteData)
  Protected x, y

  *sprite\width = #SPRITE_SIZE
  *sprite\height = #SPRITE_SIZE
  *sprite\name = ""
  
  For y = 0 To #SPRITE_SIZE - 1
    For x = 0 To #SPRITE_SIZE - 1
      *sprite\pixels(x, y) = 0
    Next
  Next
EndProcedure

Procedure SetPixel(*sprite.SpriteData, x.l, y.l, color.l)
  If x >= 0 And x < #SPRITE_SIZE And y >= 0 And y < #SPRITE_SIZE
    *sprite\pixels(x, y) = color
  EndIf
EndProcedure

Procedure.l GetPixel(*sprite.SpriteData, x.l, y.l)
  If x >= 0 And x < #SPRITE_SIZE And y >= 0 And y < #SPRITE_SIZE
    ProcedureReturn *sprite\pixels(x, y)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure DrawRectangle(*sprite.SpriteData, x.l, y.l, w.l, h.l, color.l)
  Protected i, j
  
  For j = y To y + h - 1
    For i = x To x + w - 1
      SetPixel(*sprite, i, j, color)
    Next
  Next
EndProcedure

Procedure DrawCircle(*sprite.SpriteData, cx.l, cy.l, radius.l, color.l)
  Protected x, y, dx, dy
  
  For y = cy - radius To cy + radius
    For x = cx - radius To cx + radius
      dx = x - cx
      dy = y - cy
      If (dx * dx + dy * dy) <= (radius * radius)
        SetPixel(*sprite, x, y, color)
      EndIf
    Next
  Next
EndProcedure

Procedure ApplySymmetry(*sprite.SpriteData, symmetry.l)
  Protected x, y, color
  
  If symmetry = 1 ; Vertical symmetry
    For y = 0 To #SPRITE_SIZE - 1
      For x = 0 To #SPRITE_SIZE / 2 - 1
        color = GetPixel(*sprite, x, y)
        SetPixel(*sprite, #SPRITE_SIZE - 1 - x, y, color)
      Next
    Next
  ElseIf symmetry = 2 ; Horizontal symmetry
    For y = 0 To #SPRITE_SIZE / 2 - 1
      For x = 0 To #SPRITE_SIZE - 1
        color = GetPixel(*sprite, x, y)
        SetPixel(*sprite, x, #SPRITE_SIZE - 1 - y, color)
      Next
    Next
  ElseIf symmetry = 3 ; Both
    For y = 0 To #SPRITE_SIZE / 2 - 1
      For x = 0 To #SPRITE_SIZE / 2 - 1
        color = GetPixel(*sprite, x, y)
        SetPixel(*sprite, #SPRITE_SIZE - 1 - x, y, color)
        SetPixel(*sprite, x, #SPRITE_SIZE - 1 - y, color)
        SetPixel(*sprite, #SPRITE_SIZE - 1 - x, #SPRITE_SIZE - 1 - y, color)
      Next
    Next
  EndIf
EndProcedure

Procedure AddOutline(*sprite.SpriteData, outlineColor.l)
  Protected x, y, i, j, nx, ny
  Protected Dim outlineMask.l(#SPRITE_SIZE - 1, #SPRITE_SIZE - 1)
  
  For y = 0 To #SPRITE_SIZE - 1
    For x = 0 To #SPRITE_SIZE - 1
      If GetPixel(*sprite, x, y) <> 0
        For j = -1 To 1
          For i = -1 To 1
            nx = x + i
            ny = y + j
            If nx >= 0 And nx < #SPRITE_SIZE And ny >= 0 And ny < #SPRITE_SIZE
              If GetPixel(*sprite, nx, ny) = 0
                outlineMask(nx, ny) = #True
              EndIf
            EndIf
          Next
        Next
      EndIf
    Next
  Next
  
  For y = 0 To #SPRITE_SIZE - 1
    For x = 0 To #SPRITE_SIZE - 1
      If outlineMask(x, y)
        SetPixel(*sprite, x, y, outlineColor)
      EndIf
    Next
  Next
EndProcedure

XIncludeFile "theme_metadata.pb"
XIncludeFile "sprite_runtime.pb"
XIncludeFile "sprite_generators.pb"

; ====================================================================
; Main Program
; ====================================================================

UsePNGImageEncoder()

If InitSprite()
  InitializeGeneratorRegistry()
  InitializeTypeEntries()
  InitializePalettes()
  
  OpenWindow(#Window, 0, 0, 700, 600, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
  
  TextGadget(#PB_Any, 10, 10, 150, 20, "Theme / Palette:")
  ListIconGadget(#ListTheme, 10, 30, 150, 200, "Theme", 130, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)

  PopulateThemeList()
  
  TextGadget(#PB_Any, 10, 240, 150, 20, "Sprite Type:")
  ListIconGadget(#ListType, 10, 260, 150, 200, "Type", 130, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  
  UpdateThemeTypes()
  
  TextGadget(#PB_Any, 170, 10, 200, 20, "Preview:")
  CanvasGadget(#CanvasPreview, 170, 30, #SPRITE_SIZE * #PREVIEW_SCALE, #SPRITE_SIZE * #PREVIEW_SCALE, #PB_Canvas_Border)
  
  FrameGadget(#PB_Any, 170, 300, 250, 160, "Options")
  
  TextGadget(#PB_Any, 180, 325, 100, 20, "Symmetry:")
  ComboBoxGadget(#ComboSymmetry, 280, 322, 120, 22)
  AddGadgetItem(#ComboSymmetry, -1, "None")
  AddGadgetItem(#ComboSymmetry, -1, "Vertical")
  AddGadgetItem(#ComboSymmetry, -1, "Horizontal")
  AddGadgetItem(#ComboSymmetry, -1, "Both")
  SetGadgetState(#ComboSymmetry, 1) ; Default to Vertical
  
  CheckBoxGadget(#CheckOutline, 180, 350, 230, 20, "Add Black Outline")
  SetGadgetState(#CheckOutline, #True)
  
  TextGadget(#PB_Any, 180, 380, 220, 20, "Complexity (0-100):")
  SpinGadget(#SpinComplexity, 180, 400, 220, 25, 0, 100, #PB_Spin_Numeric)
  SetGadgetState(#SpinComplexity, 50)
  
  TextGadget(#TextSeed, 180, 430, 100, 20, "Seed:")
  StringGadget(#StringSeed, 220, 427, 100, 20, "")
  ButtonGadget(#ButtonRandomSeed, 330, 426, 80, 22, "Random")
  
  ButtonGadget(#ButtonGenerate, 430, 30, 250, 40, "Generate Sprite")

  ButtonGadget(#ButtonSave, 430, 80, 250, 35, "Save PNG (32x32)")
  ButtonGadget(#ButtonExport, 430, 125, 250, 35, "Export Scaled (256x256)")
  
  TextGadget(#PB_Any, 430, 180, 250, 80, "Features:" + #CRLF$ + "- 40 sprite types" + #CRLF$ + "- 8 color palettes" + #CRLF$ + "- Symmetry options" + #CRLF$ + "- Seed-based generation")
  
  FrameGadget(#PB_Any, 10, 470, 670, 120, "Status")
  TextGadget(#TextStatus, 20, 495, 650, 85, "Ready. Select a theme and sprite type, then click Generate.")
  
  UpdateExportButtons(#False)
  
  ; Initialize preview
  currentSprite\width = #SPRITE_SIZE
  currentSprite\height = #SPRITE_SIZE
  ClearSprite(@currentSprite)
  DrawSpritePreview()
  
  Define event
  
  Repeat
    event = WaitWindowEvent()
    
    Select event
      Case #PB_Event_CloseWindow
        ConfirmExit()
        
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ListTheme
            UpdateThemeTypes()
            
          Case #ButtonRandomSeed
            SetGadgetText(#StringSeed, Str(Random(999999)))
            
          Case #ButtonGenerate
            GenerateCurrentSprite()

            
          Case #ButtonSave
            SaveCurrentSprite()
            
          Case #ButtonExport
            ExportSpriteLarge()
        EndSelect
    EndSelect
  ForEver
  
Else
  MessageRequester("Error", "Failed to initialize sprite system!", #PB_MessageRequester_Error)
EndIf

If hMutex
  CloseHandle_(hMutex)
  hMutex = 0
EndIf

End

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 127
; FirstLine = 123
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = game_sprite_gen.ico
; Executable = ..\Game_Sprite_Gen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = Game_Sprite_Gen
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = A configurable game sprite generator
; VersionField7 = Game_Sprite_Gen
; VersionField8 = Game_Sprite_Gen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
