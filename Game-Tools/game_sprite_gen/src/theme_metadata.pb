Procedure InitializeThemeLabels()
  themeLabels(#ThemeSpace) = "Space / Sci-Fi"
  themeLabels(#ThemeNature) = "Nature / Forest"
  themeLabels(#ThemeFire) = "Fire / Lava"
  themeLabels(#ThemeOcean) = "Ocean / Water"
  themeLabels(#ThemeMetal) = "Metal / Robot"
  themeLabels(#ThemeCandy) = "Candy / Pastel"
  themeLabels(#ThemeMilitary) = "Military / Camo"
  themeLabels(#ThemeUrban) = "Urban / Vehicles"
EndProcedure

Procedure AddThemeTypeEntry(themeId.l, title.s, typeId.l)
  AddElement(themeTypeEntries())
  themeTypeEntries()\themeId = themeId
  themeTypeEntries()\title = title
  themeTypeEntries()\typeId = typeId
EndProcedure

Procedure InitializeTypeEntries()
  ClearList(themeTypeEntries())

  AddThemeTypeEntry(#ThemeSpace, "Space Ship", #TypeSpaceShip)
  AddThemeTypeEntry(#ThemeSpace, "Alien", #TypeAlien)
  AddThemeTypeEntry(#ThemeSpace, "Planet", #TypePlanet)
  AddThemeTypeEntry(#ThemeSpace, "Power Up", #TypePowerUp)
  AddThemeTypeEntry(#ThemeSpace, "Space Shuttle", #TypeSpaceShuttle)
  AddThemeTypeEntry(#ThemeSpace, "Rocket", #TypeRocket)
  AddThemeTypeEntry(#ThemeSpace, "Satellite", #TypeSatellite)
  AddThemeTypeEntry(#ThemeSpace, "Space Station", #TypeSpaceStation)
  AddThemeTypeEntry(#ThemeSpace, "Lunar Lander", #TypeLunarLander)
  AddThemeTypeEntry(#ThemeSpace, "Star Fighter", #TypeStarFighter)
  AddThemeTypeEntry(#ThemeSpace, "Capital Ship", #TypeCapitalShip)
  AddThemeTypeEntry(#ThemeSpace, "Cargo Ship", #TypeCargo)
  AddThemeTypeEntry(#ThemeSpace, "Scout Ship", #TypeScout)
  AddThemeTypeEntry(#ThemeSpace, "Mining Ship", #TypeMiningShip)

  AddThemeTypeEntry(#ThemeNature, "Tree", #TypeTree)
  AddThemeTypeEntry(#ThemeNature, "Animal", #TypeAnimal)
  AddThemeTypeEntry(#ThemeNature, "Terrain", #TypeTerrain)
  AddThemeTypeEntry(#ThemeNature, "Food", #TypeFood)

  AddThemeTypeEntry(#ThemeFire, "Monster", #TypeMonster)
  AddThemeTypeEntry(#ThemeFire, "Particle", #TypeParticle)
  AddThemeTypeEntry(#ThemeFire, "Crystal", #TypeCrystal)

  AddThemeTypeEntry(#ThemeOcean, "Animal", #TypeAnimal)
  AddThemeTypeEntry(#ThemeOcean, "Terrain", #TypeTerrain)

  AddThemeTypeEntry(#ThemeMetal, "Robot", #TypeRobot)
  AddThemeTypeEntry(#ThemeMetal, "Weapon", #TypeWeapon)
  AddThemeTypeEntry(#ThemeMetal, "Building", #TypeBuilding)

  AddThemeTypeEntry(#ThemeCandy, "Food", #TypeFood)
  AddThemeTypeEntry(#ThemeCandy, "Power Up", #TypePowerUp)
  AddThemeTypeEntry(#ThemeCandy, "Particle", #TypeParticle)

  AddThemeTypeEntry(#ThemeMilitary, "Tank", #TypeTank)
  AddThemeTypeEntry(#ThemeMilitary, "Helicopter", #TypeHelicopter)
  AddThemeTypeEntry(#ThemeMilitary, "Jet Fighter", #TypeJet)
  AddThemeTypeEntry(#ThemeMilitary, "Soldier", #TypeSoldier)
  AddThemeTypeEntry(#ThemeMilitary, "Humvee", #TypeHumvee)

  AddThemeTypeEntry(#ThemeUrban, "Sports Car", #TypeSportsCar)
  AddThemeTypeEntry(#ThemeUrban, "Sedan", #TypeSedan)
  AddThemeTypeEntry(#ThemeUrban, "SUV", #TypeSUV)
  AddThemeTypeEntry(#ThemeUrban, "Pickup Truck", #TypePickupTruck)
  AddThemeTypeEntry(#ThemeUrban, "Semi Truck", #TypeSemiTruck)
  AddThemeTypeEntry(#ThemeUrban, "Van", #TypeVan)
  AddThemeTypeEntry(#ThemeUrban, "Motorcycle", #TypeMotorcycle)
  AddThemeTypeEntry(#ThemeUrban, "Scooter", #TypeScooter)
  AddThemeTypeEntry(#ThemeUrban, "Race Car", #TypeRaceCar)
  AddThemeTypeEntry(#ThemeUrban, "Bus", #TypeBus)
EndProcedure

Procedure PopulateThemeList()
  Protected themeId

  InitializeThemeLabels()
  ClearGadgetItems(#ListTheme)

  For themeId = 0 To #THEME_COUNT - 1
    AddGadgetItem(#ListTheme, -1, themeLabels(themeId))
  Next

  SetGadgetState(#ListTheme, #ThemeSpace)
EndProcedure

Procedure UpdateThemeTypes()
  Protected theme = GetGadgetState(#ListTheme)
  Protected hasItems.i

  ClearGadgetItems(#ListType)
  ClearList(typeIds())

  ForEach themeTypeEntries()
    If themeTypeEntries()\themeId = theme
      AddGadgetItem(#ListType, -1, themeTypeEntries()\title)
      AddElement(typeIds())
      typeIds() = themeTypeEntries()\typeId
      hasItems = #True
    EndIf
  Next

  If hasItems
    SetGadgetState(#ListType, 0)
    SetStatus("Select a sprite type, then click Generate.")
  Else
    SetStatus("No sprite types available for this theme")
  EndIf
EndProcedure

Procedure InitializePalettes()
  ; Space/Sci-Fi Palette
  themePalettes(#ThemeSpace)\name = "Space"
  themePalettes(#ThemeSpace)\numColors = 6
  themePalettes(#ThemeSpace)\colors(0) = RGB2(0, 100, 200)
  themePalettes(#ThemeSpace)\colors(1) = RGB2(100, 100, 150)
  themePalettes(#ThemeSpace)\colors(2) = RGB2(200, 200, 255)
  themePalettes(#ThemeSpace)\colors(3) = RGB2(150, 0, 200)
  themePalettes(#ThemeSpace)\colors(4) = RGB2(0, 200, 255)
  themePalettes(#ThemeSpace)\colors(5) = RGB2(50, 50, 100)

  ; Nature Palette
  themePalettes(#ThemeNature)\name = "Nature"
  themePalettes(#ThemeNature)\numColors = 6
  themePalettes(#ThemeNature)\colors(0) = RGB2(34, 139, 34)
  themePalettes(#ThemeNature)\colors(1) = RGB2(107, 142, 35)
  themePalettes(#ThemeNature)\colors(2) = RGB2(85, 107, 47)
  themePalettes(#ThemeNature)\colors(3) = RGB2(139, 69, 19)
  themePalettes(#ThemeNature)\colors(4) = RGB2(160, 82, 45)
  themePalettes(#ThemeNature)\colors(5) = RGB2(46, 139, 87)

  ; Fire/Lava Palette
  themePalettes(#ThemeFire)\name = "Fire"
  themePalettes(#ThemeFire)\numColors = 5
  themePalettes(#ThemeFire)\colors(0) = RGB2(255, 0, 0)
  themePalettes(#ThemeFire)\colors(1) = RGB2(255, 100, 0)
  themePalettes(#ThemeFire)\colors(2) = RGB2(255, 200, 0)
  themePalettes(#ThemeFire)\colors(3) = RGB2(200, 0, 0)
  themePalettes(#ThemeFire)\colors(4) = RGB2(100, 0, 0)

  ; Ocean/Water Palette
  themePalettes(#ThemeOcean)\name = "Ocean"
  themePalettes(#ThemeOcean)\numColors = 5
  themePalettes(#ThemeOcean)\colors(0) = RGB2(0, 105, 148)
  themePalettes(#ThemeOcean)\colors(1) = RGB2(0, 150, 200)
  themePalettes(#ThemeOcean)\colors(2) = RGB2(0, 191, 255)
  themePalettes(#ThemeOcean)\colors(3) = RGB2(25, 25, 112)
  themePalettes(#ThemeOcean)\colors(4) = RGB2(100, 149, 237)

  ; Metal/Robot Palette
  themePalettes(#ThemeMetal)\name = "Metal"
  themePalettes(#ThemeMetal)\numColors = 5
  themePalettes(#ThemeMetal)\colors(0) = RGB2(128, 128, 128)
  themePalettes(#ThemeMetal)\colors(1) = RGB2(169, 169, 169)
  themePalettes(#ThemeMetal)\colors(2) = RGB2(192, 192, 192)
  themePalettes(#ThemeMetal)\colors(3) = RGB2(105, 105, 105)
  themePalettes(#ThemeMetal)\colors(4) = RGB2(70, 70, 70)

  ; Candy/Pastel Palette
  themePalettes(#ThemeCandy)\name = "Candy"
  themePalettes(#ThemeCandy)\numColors = 6
  themePalettes(#ThemeCandy)\colors(0) = RGB2(255, 182, 193)
  themePalettes(#ThemeCandy)\colors(1) = RGB2(255, 218, 185)
  themePalettes(#ThemeCandy)\colors(2) = RGB2(221, 160, 221)
  themePalettes(#ThemeCandy)\colors(3) = RGB2(176, 224, 230)
  themePalettes(#ThemeCandy)\colors(4) = RGB2(255, 240, 245)
  themePalettes(#ThemeCandy)\colors(5) = RGB2(255, 192, 203)

  ; Military/Camouflage Palette
  themePalettes(#ThemeMilitary)\name = "Military"
  themePalettes(#ThemeMilitary)\numColors = 6
  themePalettes(#ThemeMilitary)\colors(0) = RGB2(85, 107, 47)
  themePalettes(#ThemeMilitary)\colors(1) = RGB2(75, 95, 40)
  themePalettes(#ThemeMilitary)\colors(2) = RGB2(107, 142, 35)
  themePalettes(#ThemeMilitary)\colors(3) = RGB2(128, 128, 128)
  themePalettes(#ThemeMilitary)\colors(4) = RGB2(139, 90, 43)
  themePalettes(#ThemeMilitary)\colors(5) = RGB2(70, 70, 70)

  ; Urban/City Palette
  themePalettes(#ThemeUrban)\name = "Urban"
  themePalettes(#ThemeUrban)\numColors = 6
  themePalettes(#ThemeUrban)\colors(0) = RGB2(255, 0, 0)
  themePalettes(#ThemeUrban)\colors(1) = RGB2(0, 0, 255)
  themePalettes(#ThemeUrban)\colors(2) = RGB2(255, 255, 0)
  themePalettes(#ThemeUrban)\colors(3) = RGB2(50, 50, 50)
  themePalettes(#ThemeUrban)\colors(4) = RGB2(200, 200, 200)
  themePalettes(#ThemeUrban)\colors(5) = RGB2(0, 200, 0)
EndProcedure
