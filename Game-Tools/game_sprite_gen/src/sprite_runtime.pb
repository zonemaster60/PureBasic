Procedure InitializeGeneratorRegistry()
  spriteGenerators(#TypeSpaceShip) = @GenerateSpaceShip()
  spriteGenerators(#TypeAlien) = @GenerateAlien()
  spriteGenerators(#TypeRobot) = @GenerateRobot()
  spriteGenerators(#TypeTree) = @GenerateTree()
  spriteGenerators(#TypeAnimal) = @GenerateAnimal()
  spriteGenerators(#TypeCar) = @GenerateCar()
  spriteGenerators(#TypeCrystal) = @GenerateCrystal()
  spriteGenerators(#TypeWeapon) = @GenerateWeapon()
  spriteGenerators(#TypeBuilding) = @GenerateBuilding()
  spriteGenerators(#TypeMonster) = @GenerateMonster()
  spriteGenerators(#TypePowerUp) = @GeneratePowerUp()
  spriteGenerators(#TypePlanet) = @GeneratePlanet()
  spriteGenerators(#TypeFood) = @GenerateFood()
  spriteGenerators(#TypeParticle) = @GenerateParticle()
  spriteGenerators(#TypeTerrain) = @GenerateTerrain()
  spriteGenerators(#TypeTank) = @GenerateTank()
  spriteGenerators(#TypeHelicopter) = @GenerateHelicopter()
  spriteGenerators(#TypeJet) = @GenerateJet()
  spriteGenerators(#TypeSoldier) = @GenerateSoldier()
  spriteGenerators(#TypeHumvee) = @GenerateHumvee()
  spriteGenerators(#TypeSpaceShuttle) = @GenerateSpaceShuttle()
  spriteGenerators(#TypeRocket) = @GenerateRocket()
  spriteGenerators(#TypeSatellite) = @GenerateSatellite()
  spriteGenerators(#TypeSpaceStation) = @GenerateSpaceStation()
  spriteGenerators(#TypeLunarLander) = @GenerateLunarLander()
  spriteGenerators(#TypeStarFighter) = @GenerateStarFighter()
  spriteGenerators(#TypeCapitalShip) = @GenerateCapitalShip()
  spriteGenerators(#TypeCargo) = @GenerateCargo()
  spriteGenerators(#TypeScout) = @GenerateScout()
  spriteGenerators(#TypeMiningShip) = @GenerateMiningShip()
  spriteGenerators(#TypeSportsCar) = @GenerateSportsCar()
  spriteGenerators(#TypeSedan) = @GenerateSedan()
  spriteGenerators(#TypeSUV) = @GenerateSUV()
  spriteGenerators(#TypePickupTruck) = @GeneratePickupTruck()
  spriteGenerators(#TypeSemiTruck) = @GenerateSemiTruck()
  spriteGenerators(#TypeVan) = @GenerateVan()
  spriteGenerators(#TypeMotorcycle) = @GenerateMotorcycle()
  spriteGenerators(#TypeScooter) = @GenerateScooter()
  spriteGenerators(#TypeRaceCar) = @GenerateRaceCar()
  spriteGenerators(#TypeBus) = @GenerateBus()
EndProcedure

Procedure.i GetSelectedSpriteType(selectedIndex.l)
  Protected spriteType = #TypeSpaceShip

  If selectedIndex >= 0
    If SelectElement(typeIds(), selectedIndex)
      spriteType = typeIds()
    EndIf
  EndIf

  ProcedureReturn spriteType
EndProcedure

Procedure ShowSaveResult(success.i, successText.s, errorText.s, statusText.s)
  If success
    SetStatus(statusText)
    MessageRequester("Success", successText, #PB_MessageRequester_Ok)
  Else
    SetStatus("Error: " + errorText)
    MessageRequester("Error", errorText, #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure.l SaveRenderedSprite(filename.s, *sprite.SpriteData, imageSize.l, scale.l)
  Protected img

  img = CreateImage(#PB_Any, imageSize, imageSize, 32, RGBA(0, 0, 0, 0))
  If img = 0
    ProcedureReturn #False
  EndIf

  If RenderSpriteImage(*sprite, img, scale) = 0
    FreeImage(img)
    ProcedureReturn #False
  EndIf

  If SaveImage(img, filename, #PB_ImagePlugin_PNG) = 0
    FreeImage(img)
    ProcedureReturn #False
  EndIf

  FreeImage(img)
  ProcedureReturn #True
EndProcedure

Procedure DrawSpritePreview()
  Protected imgPreview, x, y
  
  If StartDrawing(CanvasOutput(#CanvasPreview))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, #PREVIEW_SIZE, #PREVIEW_SIZE, RGB2(40, 40, 40))

    ; Draw checkerboard behind transparent pixels.
    For y = 0 To #SPRITE_SIZE - 1
      For x = 0 To #SPRITE_SIZE - 1
        If (x + y) % 2 = 0
          Box(x * #PREVIEW_SCALE, y * #PREVIEW_SCALE, #PREVIEW_SCALE, #PREVIEW_SCALE, RGB2(60, 60, 60))
        EndIf
      Next
    Next

    StopDrawing()
  EndIf

  imgPreview = CreateImage(#PB_Any, #PREVIEW_SIZE, #PREVIEW_SIZE, 32, RGBA(0, 0, 0, 0))
  If imgPreview
    If RenderSpriteImage(@currentSprite, imgPreview, #PREVIEW_SCALE)
      If StartDrawing(CanvasOutput(#CanvasPreview))
        DrawingMode(#PB_2DDrawing_AlphaBlend)
        DrawImage(ImageID(imgPreview), 0, 0)
        StopDrawing()
      EndIf
    EndIf

    FreeImage(imgPreview)
  EndIf
EndProcedure

Procedure.l RenderSpriteImage(*sprite.SpriteData, imageId.i, scale.l)
  Protected x, y, color

  If StartDrawing(ImageOutput(imageId)) = 0
    ProcedureReturn #False
  EndIf

  For y = 0 To #SPRITE_SIZE - 1
    For x = 0 To #SPRITE_SIZE - 1
      color = GetPixel(*sprite, x, y)
      If color = 0
        If scale = 1
          Plot(x, y, RGBA(0, 0, 0, 0))
        Else
          Box(x * scale, y * scale, scale, scale, RGBA(0, 0, 0, 0))
        EndIf
      Else
        If scale = 1
          Plot(x, y, color | $FF000000)
        Else
          Box(x * scale, y * scale, scale, scale, color | $FF000000)
        EndIf
      EndIf
    Next
  Next

  StopDrawing()
  ProcedureReturn #True
EndProcedure

Procedure GenerateCurrentSprite()
  Protected theme = GetGadgetState(#ListTheme)
  Protected selectedIndex = GetGadgetState(#ListType)
  Protected spriteType.l
  Protected symmetry = GetGadgetState(#ComboSymmetry)
  Protected outline = GetGadgetState(#CheckOutline)
  Protected complexity = GetGadgetState(#SpinComplexity)
  Protected seedText.s = Trim(GetGadgetText(#StringSeed))

  If theme < 0 Or theme >= #THEME_COUNT
    SetStatus("Select a theme first")
    ProcedureReturn
  EndIf

  If selectedIndex < 0
    SetStatus("Select a sprite type first")
    ProcedureReturn
  EndIf
  
  If seedText <> ""
    If IsValidSeedText(seedText) = 0
      SetStatus("Seed must contain digits only")
      ProcedureReturn
    EndIf

    randomSeed = Val(seedText)
    RandomSeed(randomSeed)
  Else
    randomSeed = Random(999999)
    RandomSeed(randomSeed)
    SetGadgetText(#StringSeed, Str(randomSeed))
  EndIf

  CopyStructure(@themePalettes(theme), @currentPalette, ColorPalette)

  spriteType = GetSelectedSpriteType(selectedIndex)
  If spriteType < 0 Or spriteType > #TypeBus Or spriteGenerators(spriteType) = 0
    SetStatus("Selected sprite type is unavailable")
    ProcedureReturn
  EndIf

  CallFunctionFast(spriteGenerators(spriteType), @currentSprite, @currentPalette, symmetry, complexity)
  
  If outline
    AddOutline(@currentSprite, RGB2(0, 0, 0))
  EndIf

  hasGeneratedSprite = #True
  DrawSpritePreview()
  SetStatus("Generated: " + currentSprite\name + " (Seed: " + Str(randomSeed) + ")")
  UpdateExportButtons(#True)
EndProcedure

Procedure SaveCurrentSprite()
  Protected filename.s
  Protected success.i

  If hasGeneratedSprite = 0
    SetStatus("Generate a sprite first")
    ProcedureReturn
  EndIf

  filename = SaveFileRequester("Save Sprite", "sprite.png", "PNG Images (*.png)|*.png", 0)
  
  If filename
    success = SaveSpritePNG(filename, @currentSprite)
    ShowSaveResult(success, "Sprite saved successfully!", "Failed to save sprite!", "Saved: " + filename)
  EndIf
EndProcedure

Procedure.l SaveSpritePNG(filename.s, *sprite.SpriteData)
  ProcedureReturn SaveRenderedSprite(filename, *sprite, #SPRITE_SIZE, 1)
EndProcedure

Procedure ExportSpriteLarge()
  Protected filename.s
  Protected success.i

  If hasGeneratedSprite = 0
    SetStatus("Generate a sprite first")
    ProcedureReturn
  EndIf

  filename = SaveFileRequester("Export Sprite", "sprite_large.png", "PNG Images (*.png)|*.png", 0)
  
  If filename
    success = SaveRenderedSprite(filename, @currentSprite, #EXPORT_SIZE, #EXPORT_SCALE)
    ShowSaveResult(success, "Sprite exported successfully!", "Failed to export sprite!", "Exported: " + filename)
  EndIf
EndProcedure
