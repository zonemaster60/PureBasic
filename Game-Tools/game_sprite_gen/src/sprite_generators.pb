Procedure GenerateSpaceShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected x, y, w, h, i
  Protected bodyColor.l, wingColor.l, detailColor.l, engineColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "SpaceShip"
  
  bodyColor = RandomColor(*palette)
  wingColor = RandomColor(*palette)
  detailColor = RandomColor(*palette)
  engineColor = RGB2(255, 100, 0)
  
  ; Body
  DrawRectangle(*sprite, 14, 8, 4, 16, bodyColor)
  
  ; Cockpit
  SetPixel(*sprite, 15, 6, detailColor)
  SetPixel(*sprite, 16, 6, detailColor)
  SetPixel(*sprite, 15, 7, detailColor)
  SetPixel(*sprite, 16, 7, detailColor)
  
  ; Wings
  For i = 0 To 5
    SetPixel(*sprite, 12 - i, 12 + i, wingColor)
    SetPixel(*sprite, 13 - i, 12 + i, wingColor)
  Next
  
  ; Engine
  SetPixel(*sprite, 15, 24, engineColor)
  SetPixel(*sprite, 16, 24, engineColor)
  SetPixel(*sprite, 15, 25, RGB2(255, 150, 0))
  SetPixel(*sprite, 16, 25, RGB2(255, 150, 0))
  
  ; Details based on complexity
  If complexity > 50
    For i = 0 To 3
      SetPixel(*sprite, 15, 10 + i * 2, detailColor)
      SetPixel(*sprite, 16, 10 + i * 2, detailColor)
    Next
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateAlien(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, eyeColor.l, detailColor.l
  Protected x, y
  
  ClearSprite(*sprite)
  *sprite\name = "Alien"
  
  bodyColor = RandomColor(*palette)
  eyeColor = RGB2(255, 255, 255)
  detailColor = RandomColor(*palette)
  
  ; Head
  DrawCircle(*sprite, 16, 12, 6, bodyColor)
  
  ; Eyes
  SetPixel(*sprite, 13, 11, eyeColor)
  SetPixel(*sprite, 14, 11, eyeColor)
  SetPixel(*sprite, 13, 12, RGB2(0, 0, 0))
  
  ; Body
  DrawRectangle(*sprite, 13, 18, 6, 8, bodyColor)
  
  ; Arms
  For y = 20 To 24
    SetPixel(*sprite, 11, y, bodyColor)
    SetPixel(*sprite, 12, y, bodyColor)
  Next
  
  ; Legs
  DrawRectangle(*sprite, 13, 26, 2, 4, bodyColor)
  DrawRectangle(*sprite, 17, 26, 2, 4, bodyColor)
  
  If complexity > 60
    ; Antennae
    For y = 5 To 10
      SetPixel(*sprite, 13, y, detailColor)
    Next
    DrawCircle(*sprite, 13, 4, 1, RGB2(255, 200, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateRobot(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, detailColor.l, jointColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Robot"
  
  bodyColor = RandomColor(*palette)
  detailColor = RandomColor(*palette)
  jointColor = RGB2(100, 100, 100)
  
  ; Head
  DrawRectangle(*sprite, 13, 6, 6, 5, bodyColor)
  SetPixel(*sprite, 14, 8, RGB2(255, 0, 0))
  SetPixel(*sprite, 17, 8, RGB2(255, 0, 0))
  
  ; Body
  DrawRectangle(*sprite, 12, 12, 8, 10, bodyColor)
  DrawRectangle(*sprite, 14, 14, 4, 2, detailColor)
  
  ; Arms
  DrawRectangle(*sprite, 9, 13, 2, 8, bodyColor)
  SetPixel(*sprite, 10, 15, jointColor)
  
  ; Legs
  DrawRectangle(*sprite, 13, 22, 2, 6, bodyColor)
  DrawRectangle(*sprite, 17, 22, 2, 6, bodyColor)
  SetPixel(*sprite, 14, 24, jointColor)
  SetPixel(*sprite, 18, 24, jointColor)
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateTree(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected trunkColor.l, leafColor.l, y, w
  
  ClearSprite(*sprite)
  *sprite\name = "Tree"
  
  trunkColor = RGB2(139, 69, 19)
  leafColor = RandomColor(*palette)
  
  ; Trunk
  DrawRectangle(*sprite, 14, 20, 4, 10, trunkColor)
  
  ; Leaves/Foliage
  For y = 0 To 3
    w = 10 - y * 2
    DrawRectangle(*sprite, 16 - w / 2, 8 + y * 3, w, 3, leafColor)
  Next
  
  ; Top
  DrawCircle(*sprite, 16, 6, 3, leafColor)
  
  If complexity > 50
    ; Add some fruit/details
    SetPixel(*sprite, 12, 12, RGB2(255, 0, 0))
    SetPixel(*sprite, 20, 10, RGB2(255, 0, 0))
    SetPixel(*sprite, 16, 14, RGB2(255, 0, 0))
  EndIf

  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure

Procedure GenerateAnimal(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, detailColor.l, eyeColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Animal"
  
  bodyColor = RandomColor(*palette)
  detailColor = RandomColor(*palette)
  eyeColor = RGB2(0, 0, 0)
  
  ; Body
  DrawCircle(*sprite, 16, 18, 6, bodyColor)
  
  ; Head
  DrawCircle(*sprite, 16, 10, 5, bodyColor)
  
  ; Ears
  DrawCircle(*sprite, 12, 6, 2, bodyColor)
  DrawCircle(*sprite, 20, 6, 2, bodyColor)
  
  ; Eyes
  SetPixel(*sprite, 14, 10, eyeColor)
  SetPixel(*sprite, 18, 10, eyeColor)
  
  ; Nose
  SetPixel(*sprite, 16, 12, RGB2(255, 150, 150))
  
  ; Legs
  DrawRectangle(*sprite, 12, 24, 2, 5, bodyColor)
  DrawRectangle(*sprite, 18, 24, 2, 5, bodyColor)
  
  ; Tail
  If complexity > 40
    Protected i
    For i = 0 To 5
      SetPixel(*sprite, 22 + i, 16 + i, detailColor)
    Next
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Car"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(100, 150, 200)
  wheelColor = RGB2(50, 50, 50)
  
  ; Body
  DrawRectangle(*sprite, 6, 16, 20, 8, bodyColor)
  
  ; Cabin
  DrawRectangle(*sprite, 10, 12, 12, 4, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 11, 13, 4, 2, windowColor)
  DrawRectangle(*sprite, 17, 13, 4, 2, windowColor)
  
  ; Wheels
  DrawCircle(*sprite, 10, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  If complexity > 50
    ; Headlights
    SetPixel(*sprite, 26, 17, RGB2(255, 255, 0))
    SetPixel(*sprite, 26, 18, RGB2(255, 255, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateCrystal(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected crystalColor.l, glowColor.l, i
  
  ClearSprite(*sprite)
  *sprite\name = "Crystal"
  
  crystalColor = RandomColor(*palette)
  glowColor = RGB2(200, 200, 255)
  
  ; Main crystal shape
  Protected x.l = 16
  Protected y.l = 26
  Protected size.l = 8
  
  For i = 0 To size
    DrawRectangle(*sprite, x - i / 2, y - i * 2, i, 1, crystalColor)
  Next
  
  ; Top point
  SetPixel(*sprite, 16, 10, crystalColor)
  SetPixel(*sprite, 15, 11, crystalColor)
  SetPixel(*sprite, 16, 11, crystalColor)
  SetPixel(*sprite, 17, 11, crystalColor)
  
  ; Glow effect
  If complexity > 60
    SetPixel(*sprite, 15, 12, glowColor)
    SetPixel(*sprite, 17, 12, glowColor)
    SetPixel(*sprite, 14, 14, glowColor)
    SetPixel(*sprite, 18, 14, glowColor)
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateWeapon(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected handleColor.l, bladeColor.l, detailColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Weapon"
  
  handleColor = RGB2(100, 50, 0)
  bladeColor = RGB2(200, 200, 220)
  detailColor = RandomColor(*palette)
  
  ; Handle
  DrawRectangle(*sprite, 14, 20, 4, 8, handleColor)
  
  ; Guard
  DrawRectangle(*sprite, 12, 19, 8, 2, detailColor)
  
  ; Blade
  Protected i
  For i = 0 To 15
    DrawRectangle(*sprite, 15 - i / 8, 4 + i, 2 + i / 4, 1, bladeColor)
  Next
  
  ; Tip
  SetPixel(*sprite, 16, 3, bladeColor)
  
  If complexity > 50
    ; Add energy effect
    SetPixel(*sprite, 14, 8, RGB2(0, 200, 255))
    SetPixel(*sprite, 18, 10, RGB2(0, 200, 255))
    SetPixel(*sprite, 15, 14, RGB2(0, 200, 255))
  EndIf

  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure

Procedure GenerateBuilding(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected buildingColor.l, windowColor.l, roofColor.l, x, y
  
  ClearSprite(*sprite)
  *sprite\name = "Building"
  
  buildingColor = RandomColor(*palette)
  windowColor = RGB2(255, 255, 150)
  roofColor = RGB2(150, 50, 50)
  
  ; Main building
  DrawRectangle(*sprite, 8, 12, 16, 18, buildingColor)
  
  ; Roof
  DrawRectangle(*sprite, 7, 10, 18, 2, roofColor)
  DrawRectangle(*sprite, 9, 8, 14, 2, roofColor)
  
  ; Windows
  For y = 0 To 2
    For x = 0 To 2
      DrawRectangle(*sprite, 10 + x * 4, 14 + y * 4, 2, 2, windowColor)
    Next
  Next
  
  ; Door
  DrawRectangle(*sprite, 14, 26, 4, 4, RGB2(100, 50, 0))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateMonster(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, eyeColor.l, teethColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Monster"
  
  bodyColor = RandomColor(*palette)
  eyeColor = RGB2(255, 0, 0)
  teethColor = RGB2(255, 255, 255)
  
  ; Body
  DrawCircle(*sprite, 16, 18, 8, bodyColor)
  
  ; Eyes
  DrawCircle(*sprite, 12, 14, 2, eyeColor)
  DrawCircle(*sprite, 20, 14, 2, eyeColor)
  
  ; Mouth
  DrawRectangle(*sprite, 10, 20, 12, 4, RGB2(0, 0, 0))
  
  ; Teeth
  Protected i
  For i = 0 To 5
    SetPixel(*sprite, 10 + i * 2, 20, teethColor)
    SetPixel(*sprite, 10 + i * 2, 23, teethColor)
  Next
  
  ; Horns
  If complexity > 50
    For i = 0 To 3
      SetPixel(*sprite, 10 - i, 10 - i, bodyColor)
      SetPixel(*sprite, 22 + i, 10 - i, bodyColor)
    Next
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GeneratePowerUp(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected coreColor.l, glowColor.l, i
  
  ClearSprite(*sprite)
  *sprite\name = "PowerUp"
  
  coreColor = RandomColor(*palette)
  glowColor = RGB2(255, 255, 0)
  
  ; Core
  DrawCircle(*sprite, 16, 16, 5, coreColor)
  
  ; Inner glow
  DrawCircle(*sprite, 16, 16, 3, glowColor)
  
  ; Outer particles
  For i = 0 To 7
    Protected angle.f = i * #PI / 4
    Protected px.l = 16 + Cos(angle) * 8
    Protected py.l = 16 + Sin(angle) * 8
    SetPixel(*sprite, px, py, glowColor)
    SetPixel(*sprite, px + 1, py, glowColor)
    SetPixel(*sprite, px, py + 1, glowColor)
  Next
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure

Procedure GeneratePlanet(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected planetColor.l, cloudColor.l, shadowColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Planet"
  
  planetColor = RandomColor(*palette)
  cloudColor = RGB2(255, 255, 255)
  shadowColor = RGB2(50, 50, 50)
  
  ; Planet body
  DrawCircle(*sprite, 16, 16, 10, planetColor)
  
  ; Continents/features
  DrawCircle(*sprite, 12, 14, 3, cloudColor)
  DrawCircle(*sprite, 20, 18, 2, cloudColor)
  DrawCircle(*sprite, 16, 20, 4, cloudColor)
  
  ; Shadow on one side
  If complexity > 40
    Protected y
    For y = 10 To 22
      Protected x
      For x = 22 To 26
        If GetPixel(*sprite, x, y) = planetColor
          SetPixel(*sprite, x, y, shadowColor)
        EndIf
      Next
    Next
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateFood(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected foodColor.l, detailColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Food"
  
  foodColor = RandomColor(*palette)
  detailColor = RGB2(255, 255, 0)
  
  ; Cherry/Fruit
  DrawCircle(*sprite, 14, 18, 5, foodColor)
  DrawCircle(*sprite, 18, 18, 5, foodColor)
  
  ; Stem
  Protected i
  For i = 0 To 6
    SetPixel(*sprite, 16, 12 - i, RGB2(0, 150, 0))
  Next
  
  ; Leaf
  SetPixel(*sprite, 14, 10, RGB2(0, 200, 0))
  SetPixel(*sprite, 15, 10, RGB2(0, 200, 0))
  SetPixel(*sprite, 14, 11, RGB2(0, 200, 0))
  
  ; Shine
  SetPixel(*sprite, 13, 16, RGB2(255, 255, 255))
  SetPixel(*sprite, 17, 16, RGB2(255, 255, 255))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateParticle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected particleColor.l, i, x, y
  
  ClearSprite(*sprite)
  *sprite\name = "Particle"
  
  particleColor = RandomColor(*palette)
  
  ; Center
  DrawCircle(*sprite, 16, 16, 2, particleColor)
  
  ; Sparkles
  For i = 0 To 11
    Protected angle.f = i * #PI / 6 + Random(100) / 100.0
    Protected dist.l = 4 + Random(4)
    x = 16 + Cos(angle) * dist
    y = 16 + Sin(angle) * dist
    SetPixel(*sprite, x, y, particleColor)
  Next
  
  If complexity > 60
    ; Add glow
    DrawCircle(*sprite, 16, 16, 6, RGB2(255, 255, 255))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateTerrain(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected groundColor.l, grassColor.l, y, x, height
  
  ClearSprite(*sprite)
  *sprite\name = "Terrain"
  
  groundColor = RGB2(139, 90, 43)
  grassColor = RGB2(34, 139, 34)
  
  ; Ground layers
  For x = 0 To #SPRITE_SIZE - 1
    height = 16 + Random(8) - 4
    For y = height To #SPRITE_SIZE - 1
      If y = height
        SetPixel(*sprite, x, y, grassColor)
      Else
        SetPixel(*sprite, x, y, groundColor)
      EndIf
    Next
  Next
  
  ; Grass blades
  If complexity > 50
    For x = 0 To #SPRITE_SIZE - 1 Step 3
      height = 16 + Random(8) - 4
      SetPixel(*sprite, x, height - 1, grassColor)
      SetPixel(*sprite, x, height - 2, grassColor)
    Next
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateTank(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, trackColor.l, turretColor.l, gunColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Tank"
  
  bodyColor = RGB2(85, 107, 47)
  trackColor = RGB2(50, 50, 50)
  turretColor = RGB2(75, 95, 40)
  gunColor = RGB2(60, 60, 60)
  
  ; Tracks
  DrawRectangle(*sprite, 6, 22, 20, 4, trackColor)
  DrawRectangle(*sprite, 7, 23, 18, 2, RGB2(70, 70, 70))
  
  ; Body
  DrawRectangle(*sprite, 8, 16, 16, 6, bodyColor)
  
  ; Turret
  DrawCircle(*sprite, 16, 16, 4, turretColor)
  
  ; Gun barrel
  DrawRectangle(*sprite, 4, 15, 8, 2, gunColor)
  SetPixel(*sprite, 3, 15, gunColor)
  SetPixel(*sprite, 3, 16, gunColor)
  SetPixel(*sprite, 2, 15, gunColor)
  SetPixel(*sprite, 2, 16, gunColor)
  
  ; Details
  If complexity > 50
    ; Hatch
    DrawRectangle(*sprite, 15, 14, 2, 2, RGB2(40, 40, 40))
    
    ; Track wheels
    Protected i
    For i = 0 To 3
      SetPixel(*sprite, 8 + i * 4, 24, RGB2(30, 30, 30))
    Next
    
    ; Camouflage pattern
    SetPixel(*sprite, 10, 17, RGB2(60, 80, 30))
    SetPixel(*sprite, 11, 17, RGB2(60, 80, 30))
    SetPixel(*sprite, 20, 19, RGB2(60, 80, 30))
    SetPixel(*sprite, 21, 19, RGB2(60, 80, 30))
  EndIf
  
  ; Antenna
  SetPixel(*sprite, 18, 13, RGB2(100, 100, 100))
  SetPixel(*sprite, 18, 12, RGB2(100, 100, 100))
  SetPixel(*sprite, 18, 11, RGB2(100, 100, 100))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateHelicopter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, rotorColor.l, windowColor.l, tailColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Helicopter"
  
  bodyColor = RGB2(85, 107, 47)
  rotorColor = RGB2(100, 100, 100)
  windowColor = RGB2(100, 150, 200)
  tailColor = RGB2(75, 95, 40)
  
  ; Main body
  DrawRectangle(*sprite, 10, 14, 12, 6, bodyColor)
  
  ; Cockpit/nose
  SetPixel(*sprite, 9, 15, bodyColor)
  SetPixel(*sprite, 9, 16, bodyColor)
  SetPixel(*sprite, 8, 16, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 10, 15, 3, 2, windowColor)
  
  ; Tail boom
  DrawRectangle(*sprite, 22, 16, 6, 2, tailColor)
  
  ; Tail rotor
  SetPixel(*sprite, 28, 15, rotorColor)
  SetPixel(*sprite, 28, 16, rotorColor)
  SetPixel(*sprite, 28, 17, rotorColor)
  SetPixel(*sprite, 28, 18, rotorColor)
  
  ; Main rotor (top)
  Protected i
  For i = 4 To 28 Step 2
    SetPixel(*sprite, i, 12, rotorColor)
  Next
  
  ; Rotor hub
  DrawCircle(*sprite, 16, 12, 1, RGB2(80, 80, 80))
  
  ; Skids (landing gear)
  DrawRectangle(*sprite, 8, 21, 16, 1, RGB2(60, 60, 60))
  SetPixel(*sprite, 11, 20, RGB2(60, 60, 60))
  SetPixel(*sprite, 12, 20, RGB2(60, 60, 60))
  SetPixel(*sprite, 19, 20, RGB2(60, 60, 60))
  SetPixel(*sprite, 20, 20, RGB2(60, 60, 60))
  
  If complexity > 50
    ; Missiles/weapons
    SetPixel(*sprite, 8, 19, RGB2(100, 100, 100))
    SetPixel(*sprite, 7, 19, RGB2(100, 100, 100))
    SetPixel(*sprite, 23, 19, RGB2(100, 100, 100))
    SetPixel(*sprite, 24, 19, RGB2(100, 100, 100))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateJet(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, wingColor.l, cockpitColor.l, engineColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Jet Fighter"
  
  bodyColor = RGB2(128, 128, 128)
  wingColor = RGB2(100, 100, 100)
  cockpitColor = RGB2(50, 100, 150)
  engineColor = RGB2(255, 100, 0)
  
  ; Main fuselage
  DrawRectangle(*sprite, 14, 6, 4, 20, bodyColor)
  
  ; Nose cone
  SetPixel(*sprite, 15, 5, bodyColor)
  SetPixel(*sprite, 16, 5, bodyColor)
  SetPixel(*sprite, 15, 4, bodyColor)
  SetPixel(*sprite, 16, 4, bodyColor)
  SetPixel(*sprite, 15, 3, RGB2(150, 150, 150))
  SetPixel(*sprite, 16, 3, RGB2(150, 150, 150))
  
  ; Cockpit
  DrawRectangle(*sprite, 15, 8, 2, 3, cockpitColor)
  
  ; Main wings
  Protected i
  For i = 0 To 6
    SetPixel(*sprite, 10 - i, 14 + i, wingColor)
    SetPixel(*sprite, 11 - i, 14 + i, wingColor)
  Next
  
  ; Tail fins
  For i = 0 To 3
    SetPixel(*sprite, 13 - i, 22 + i, wingColor)
    SetPixel(*sprite, 14 - i, 22 + i, wingColor)
  Next
  
  ; Vertical stabilizer
  For i = 0 To 4
    SetPixel(*sprite, 15, 22 + i, wingColor)
    SetPixel(*sprite, 16, 22 + i, wingColor)
  Next
  
  ; Engine exhaust
  SetPixel(*sprite, 15, 26, engineColor)
  SetPixel(*sprite, 16, 26, engineColor)
  SetPixel(*sprite, 15, 27, RGB2(255, 150, 0))
  SetPixel(*sprite, 16, 27, RGB2(255, 150, 0))
  
  If complexity > 50
    ; Missiles under wings
    SetPixel(*sprite, 8, 18, RGB2(200, 200, 200))
    SetPixel(*sprite, 8, 19, RGB2(200, 200, 200))
    
    ; Air intake
    SetPixel(*sprite, 14, 12, RGB2(60, 60, 60))
    SetPixel(*sprite, 17, 12, RGB2(60, 60, 60))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateSoldier(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected uniformColor.l, skinColor.l, weaponColor.l, helmetColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Soldier"
  
  uniformColor = RGB2(85, 107, 47)
  skinColor = RGB2(210, 180, 140)
  weaponColor = RGB2(50, 50, 50)
  helmetColor = RGB2(75, 95, 40)
  
  ; Helmet
  DrawRectangle(*sprite, 14, 6, 4, 3, helmetColor)
  SetPixel(*sprite, 15, 5, helmetColor)
  SetPixel(*sprite, 16, 5, helmetColor)
  
  ; Face
  DrawRectangle(*sprite, 14, 9, 4, 3, skinColor)
  
  ; Eyes
  SetPixel(*sprite, 15, 10, RGB2(0, 0, 0))
  SetPixel(*sprite, 16, 10, RGB2(0, 0, 0))
  
  ; Body/Torso
  DrawRectangle(*sprite, 13, 12, 6, 8, uniformColor)
  
  ; Arms
  DrawRectangle(*sprite, 11, 13, 2, 6, uniformColor)
  DrawRectangle(*sprite, 19, 13, 2, 6, uniformColor)
  
  ; Hands
  SetPixel(*sprite, 11, 19, skinColor)
  SetPixel(*sprite, 12, 19, skinColor)
  SetPixel(*sprite, 19, 19, skinColor)
  SetPixel(*sprite, 20, 19, skinColor)
  
  ; Legs
  DrawRectangle(*sprite, 14, 20, 2, 8, uniformColor)
  DrawRectangle(*sprite, 16, 20, 2, 8, uniformColor)
  
  ; Boots
  DrawRectangle(*sprite, 14, 28, 2, 2, RGB2(30, 30, 30))
  DrawRectangle(*sprite, 16, 28, 2, 2, RGB2(30, 30, 30))
  
  ; Rifle
  If complexity > 30
    Protected i
    For i = 0 To 6
      SetPixel(*sprite, 19 + i, 15 + i, weaponColor)
    Next
    
    ; Rifle stock
    SetPixel(*sprite, 19, 16, weaponColor)
    SetPixel(*sprite, 19, 17, weaponColor)
  EndIf
  
    ; Vest/gear details
  If complexity > 60
    DrawRectangle(*sprite, 14, 14, 4, 2, RGB2(70, 85, 35))
    SetPixel(*sprite, 15, 16, RGB2(150, 150, 150))
    SetPixel(*sprite, 16, 16, RGB2(150, 150, 150))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateHumvee(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l, detailColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Humvee"
  
  bodyColor = RGB2(85, 107, 47)
  windowColor = RGB2(80, 80, 100)
  wheelColor = RGB2(40, 40, 40)
  detailColor = RGB2(60, 60, 60)
  
  ; Main body
  DrawRectangle(*sprite, 6, 16, 20, 8, bodyColor)
  
  ; Hood/front
  DrawRectangle(*sprite, 4, 18, 2, 4, bodyColor)
  
  ; Cabin
  DrawRectangle(*sprite, 8, 12, 16, 4, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 9, 13, 3, 2, windowColor)
  DrawRectangle(*sprite, 13, 13, 3, 2, windowColor)
  DrawRectangle(*sprite, 17, 13, 3, 2, windowColor)
  
  ; Windshield
  DrawRectangle(*sprite, 5, 19, 1, 2, windowColor)
  
  ; Wheels
  DrawCircle(*sprite, 9, 24, 2, wheelColor)
  DrawCircle(*sprite, 23, 24, 2, wheelColor)
  
  ; Wheel rims
  SetPixel(*sprite, 9, 24, RGB2(100, 100, 100))
  SetPixel(*sprite, 23, 24, RGB2(100, 100, 100))
  
  ; Details
  If complexity > 50
    ; Headlights
    SetPixel(*sprite, 3, 19, RGB2(255, 255, 200))
    SetPixel(*sprite, 3, 20, RGB2(255, 255, 200))
    
    ; Side mirror
    SetPixel(*sprite, 7, 14, RGB2(100, 100, 100))
    
    ; Antenna
    SetPixel(*sprite, 20, 11, RGB2(120, 120, 120))
    SetPixel(*sprite, 20, 10, RGB2(120, 120, 120))
    SetPixel(*sprite, 20, 9, RGB2(120, 120, 120))
    
    ; Machine gun mount (on top)
    DrawRectangle(*sprite, 15, 10, 2, 2, detailColor)
    SetPixel(*sprite, 16, 9, detailColor)
    SetPixel(*sprite, 16, 8, detailColor)
  EndIf
  
  ; Grill
  DrawRectangle(*sprite, 4, 19, 1, 2, detailColor)

  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure

Procedure GenerateSpaceShuttle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, wingColor.l, windowColor.l, tileColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Space Shuttle"
  
  bodyColor = RGB2(240, 240, 240)
  wingColor = RGB2(200, 200, 200)
  windowColor = RGB2(50, 100, 150)
  tileColor = RGB2(40, 40, 40)
  
  ; Main fuselage
  DrawRectangle(*sprite, 14, 6, 4, 18, bodyColor)
  
  ; Nose cone
  SetPixel(*sprite, 15, 5, bodyColor)
  SetPixel(*sprite, 16, 5, bodyColor)
  SetPixel(*sprite, 15, 4, bodyColor)
  SetPixel(*sprite, 16, 4, bodyColor)
  SetPixel(*sprite, 15, 3, bodyColor)
  SetPixel(*sprite, 16, 3, bodyColor)
  
  ; Cockpit windows
  DrawRectangle(*sprite, 15, 7, 2, 2, windowColor)
  
  ; Delta wings
  Protected i
  For i = 0 To 8
    SetPixel(*sprite, 10 - i, 16 + i, wingColor)
    SetPixel(*sprite, 11 - i, 16 + i, wingColor)
    SetPixel(*sprite, 12 - i, 16 + i, wingColor)
  Next
  
  ; Vertical stabilizer
  For i = 0 To 5
    SetPixel(*sprite, 15, 20 + i, wingColor)
    SetPixel(*sprite, 16, 20 + i, wingColor)
  Next
  
  ; Heat shield tiles (black)
  If complexity > 50
    SetPixel(*sprite, 14, 23, tileColor)
    SetPixel(*sprite, 15, 23, tileColor)
    SetPixel(*sprite, 16, 23, tileColor)
    SetPixel(*sprite, 17, 23, tileColor)
    
    ; Payload bay
    DrawRectangle(*sprite, 14, 12, 4, 6, RGB2(100, 100, 100))
  EndIf
  
  ; Engine nozzles
  DrawRectangle(*sprite, 14, 24, 1, 2, RGB2(100, 100, 100))
  DrawRectangle(*sprite, 15, 24, 1, 2, RGB2(100, 100, 100))
  DrawRectangle(*sprite, 16, 24, 1, 2, RGB2(100, 100, 100))
  DrawRectangle(*sprite, 17, 24, 1, 2, RGB2(100, 100, 100))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateRocket(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, noseColor.l, finColor.l, engineColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Rocket"
  
  bodyColor = RGB2(240, 240, 240)
  noseColor = RGB2(255, 100, 100)
  finColor = RGB2(200, 200, 200)
  engineColor = RGB2(255, 150, 0)
  
  ; Main body
  DrawRectangle(*sprite, 13, 8, 6, 18, bodyColor)
  
  ; Nose cone
  Protected i
  DrawRectangle(*sprite, 14, 4, 4, 1, noseColor)
  DrawRectangle(*sprite, 15, 5, 2, 1, noseColor)
  SetPixel(*sprite, 16, 6, noseColor)
  
  ; Fins
  For i = 0 To 3
    SetPixel(*sprite, 11 - i, 22 + i, finColor)
    SetPixel(*sprite, 12 - i, 22 + i, finColor)
  Next
  
  ; Engine nozzle
  DrawRectangle(*sprite, 14, 26, 4, 2, RGB2(100, 100, 100))
  
  ; Flame
  SetPixel(*sprite, 15, 28, engineColor)
  SetPixel(*sprite, 16, 28, engineColor)
  SetPixel(*sprite, 14, 29, RGB2(255, 200, 0))
  SetPixel(*sprite, 15, 29, RGB2(255, 100, 0))
  SetPixel(*sprite, 16, 29, RGB2(255, 100, 0))
  SetPixel(*sprite, 17, 29, RGB2(255, 200, 0))
  
  ; Details
  If complexity > 40
    ; Stripes/markings
    DrawRectangle(*sprite, 13, 12, 6, 1, RGB2(255, 0, 0))
    DrawRectangle(*sprite, 13, 15, 6, 1, RGB2(0, 0, 255))
    DrawRectangle(*sprite, 13, 18, 6, 1, RGB2(255, 0, 0))
    
    ; Windows
    SetPixel(*sprite, 15, 10, RGB2(100, 150, 200))
    SetPixel(*sprite, 16, 10, RGB2(100, 150, 200))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateSatellite(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, panelColor.l, antennaColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Satellite"
  
  bodyColor = RGB2(150, 150, 150)
  panelColor = RGB2(0, 0, 150)
  antennaColor = RGB2(200, 200, 200)
  
  ; Main body
  DrawRectangle(*sprite, 12, 14, 8, 6, bodyColor)
  
  ; Solar panels (left)
  DrawRectangle(*sprite, 2, 12, 8, 10, panelColor)
  Protected i, j
  For i = 0 To 3
    For j = 0 To 4
      SetPixel(*sprite, 3 + i * 2, 13 + j * 2, RGB2(100, 100, 255))
    Next
  Next
  
  ; Solar panels (right)
  DrawRectangle(*sprite, 22, 12, 8, 10, panelColor)
  For i = 0 To 3
    For j = 0 To 4
      SetPixel(*sprite, 23 + i * 2, 13 + j * 2, RGB2(100, 100, 255))
    Next
  Next
  
  ; Antenna dish
  DrawCircle(*sprite, 16, 10, 2, antennaColor)
  SetPixel(*sprite, 16, 12, RGB2(100, 100, 100))
  SetPixel(*sprite, 16, 13, RGB2(100, 100, 100))
  
  ; Communications array
  If complexity > 50
    SetPixel(*sprite, 14, 8, antennaColor)
    SetPixel(*sprite, 18, 8, antennaColor)
    SetPixel(*sprite, 14, 7, antennaColor)
    SetPixel(*sprite, 18, 7, antennaColor)
  EndIf
  
    ; Central details
  DrawRectangle(*sprite, 14, 16, 4, 2, RGB2(100, 100, 100))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateSpaceStation(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected moduleColor.l, panelColor.l, windowColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Space Station"
  
  moduleColor = RGB2(180, 180, 180)
  panelColor = RGB2(0, 0, 150)
  windowColor = RGB2(255, 255, 150)
  
  ; Central hub
  DrawCircle(*sprite, 16, 16, 5, moduleColor)
  
  ; Modules
  DrawRectangle(*sprite, 6, 15, 6, 3, moduleColor)
  DrawRectangle(*sprite, 20, 15, 6, 3, moduleColor)
  DrawRectangle(*sprite, 15, 6, 3, 6, moduleColor)
  DrawRectangle(*sprite, 15, 20, 3, 6, moduleColor)
  
  ; Windows on modules
  SetPixel(*sprite, 8, 16, windowColor)
  SetPixel(*sprite, 23, 16, windowColor)
  SetPixel(*sprite, 16, 8, windowColor)
  SetPixel(*sprite, 16, 23, windowColor)
  
  ; Solar panels
  DrawRectangle(*sprite, 2, 14, 3, 5, panelColor)
  DrawRectangle(*sprite, 27, 14, 3, 5, panelColor)
  
  ; Central windows
  Protected i
  For i = 0 To 3
    Protected angle.f = i * #PI / 2
    Protected px.l = 16 + Cos(angle) * 3
    Protected py.l = 16 + Sin(angle) * 3
    SetPixel(*sprite, px, py, windowColor)
  Next
  
  If complexity > 60
    ; Docking ports
    DrawRectangle(*sprite, 11, 15, 2, 3, RGB2(100, 100, 100))
    DrawRectangle(*sprite, 19, 15, 2, 3, RGB2(100, 100, 100))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateLunarLander(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, legColor.l, goldColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Lunar Lander"
  
  bodyColor = RGB2(200, 200, 200)
  legColor = RGB2(150, 150, 150)
  goldColor = RGB2(255, 215, 0)
  
  ; Main body (octagonal)
  DrawRectangle(*sprite, 12, 14, 8, 6, bodyColor)
  SetPixel(*sprite, 11, 15, bodyColor)
  SetPixel(*sprite, 11, 16, bodyColor)
  SetPixel(*sprite, 11, 17, bodyColor)
  SetPixel(*sprite, 11, 18, bodyColor)
  SetPixel(*sprite, 20, 15, bodyColor)
  SetPixel(*sprite, 20, 16, bodyColor)
  SetPixel(*sprite, 20, 17, bodyColor)
  SetPixel(*sprite, 20, 18, bodyColor)
  
  ; Gold foil sections
  DrawRectangle(*sprite, 13, 15, 2, 4, goldColor)
  DrawRectangle(*sprite, 17, 15, 2, 4, goldColor)
  
  ; Landing legs
  Protected i
  For i = 0 To 3
    SetPixel(*sprite, 10 - i, 20 + i, legColor)
    SetPixel(*sprite, 21 + i, 20 + i, legColor)
  Next
  
  ; Foot pads
  DrawRectangle(*sprite, 6, 24, 2, 1, legColor)
  DrawRectangle(*sprite, 24, 24, 2, 1, legColor)
  
  ; Thruster
  DrawRectangle(*sprite, 14, 20, 4, 2, RGB2(100, 100, 100))
  
  If complexity > 50
    ; Antenna
    SetPixel(*sprite, 16, 13, RGB2(150, 150, 150))
    SetPixel(*sprite, 16, 12, RGB2(150, 150, 150))
    SetPixel(*sprite, 16, 11, RGB2(150, 150, 150))
    DrawCircle(*sprite, 16, 10, 1, RGB2(200, 200, 200))
    
    ; Ladder
    SetPixel(*sprite, 19, 17, RGB2(100, 100, 100))
    SetPixel(*sprite, 19, 18, RGB2(100, 100, 100))
    SetPixel(*sprite, 19, 19, RGB2(100, 100, 100))
  EndIf
  
  ; Window
  DrawRectangle(*sprite, 15, 15, 2, 2, RGB2(50, 100, 150))
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateStarFighter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, wingColor.l, cockpitColor.l, engineColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Star Fighter"
  
  bodyColor = RandomColor(*palette)
  wingColor = RandomColor(*palette)
  cockpitColor = RGB2(0, 200, 255)
  engineColor = RGB2(0, 150, 255)
  
  ; Main body
  DrawRectangle(*sprite, 14, 8, 4, 16, bodyColor)
  
  ; Cockpit dome
  DrawCircle(*sprite, 16, 9, 2, cockpitColor)
  
  ; Wings (swept back)
  Protected i
  For i = 0 To 6
    SetPixel(*sprite, 11 - i, 14 + i, wingColor)
    SetPixel(*sprite, 12 - i, 14 + i, wingColor)
    SetPixel(*sprite, 13 - i, 14 + i, wingColor)
  Next
  
  ; Weapon pods on wings
  DrawRectangle(*sprite, 8, 18, 2, 4, RGB2(100, 100, 100))
  
  ; Engine exhausts
  DrawCircle(*sprite, 14, 24, 1, RGB2(80, 80, 80))
  DrawCircle(*sprite, 17, 24, 1, RGB2(80, 80, 80))
  
  ; Engine glow
  SetPixel(*sprite, 14, 25, engineColor)
  SetPixel(*sprite, 17, 25, engineColor)
  SetPixel(*sprite, 14, 26, RGB2(100, 200, 255))
  SetPixel(*sprite, 17, 26, RGB2(100, 200, 255))
  
  ; Details
  If complexity > 50
    ; Energy weapons
    DrawRectangle(*sprite, 13, 6, 1, 2, RGB2(255, 0, 0))
    DrawRectangle(*sprite, 18, 6, 1, 2, RGB2(255, 0, 0))
    
    ; Hull details
    SetPixel(*sprite, 15, 12, RGB2(200, 200, 255))
    SetPixel(*sprite, 16, 12, RGB2(200, 200, 255))
    SetPixel(*sprite, 15, 16, RGB2(200, 200, 255))
    SetPixel(*sprite, 16, 16, RGB2(200, 200, 255))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateCapitalShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected hullColor.l, bridgeColor.l, turretColor.l, windowColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Capital Ship"
  
  hullColor = RandomColor(*palette)
  bridgeColor = RGB2(150, 150, 150)
  turretColor = RGB2(100, 100, 100)
  windowColor = RGB2(255, 255, 150)
  
  ; Main hull (wide body)
  DrawRectangle(*sprite, 8, 16, 16, 10, hullColor)
  
  ; Forward section
  Protected i
  For i = 0 To 4
    DrawRectangle(*sprite, 10 + i, 12 - i, 12 - i * 2, 1, hullColor)
  Next
  
  ; Bridge tower
  DrawRectangle(*sprite, 14, 10, 4, 6, bridgeColor)
  
  ; Bridge windows
  DrawRectangle(*sprite, 15, 11, 2, 1, windowColor)
  
  ; Hull windows
  SetPixel(*sprite, 10, 18, windowColor)
  SetPixel(*sprite, 13, 18, windowColor)
  SetPixel(*sprite, 18, 18, windowColor)
  SetPixel(*sprite, 21, 18, windowColor)
  
  ; Engine section
  DrawRectangle(*sprite, 10, 26, 3, 2, RGB2(100, 100, 100))
  DrawRectangle(*sprite, 19, 26, 3, 2, RGB2(100, 100, 100))
  
  ; Engine glow
  SetPixel(*sprite, 11, 28, RGB2(0, 150, 255))
  SetPixel(*sprite, 20, 28, RGB2(0, 150, 255))
  
  If complexity > 50
    ; Weapon turrets
    DrawCircle(*sprite, 12, 14, 1, turretColor)
    DrawCircle(*sprite, 20, 14, 1, turretColor)
    
    ; Hangars
    DrawRectangle(*sprite, 9, 20, 3, 2, RGB2(50, 50, 50))
    DrawRectangle(*sprite, 20, 20, 3, 2, RGB2(50, 50, 50))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateCargo(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected hullColor.l, containerColor.l, engineColor.l

  ClearSprite(*sprite)
  *sprite\name = "Cargo Ship"

  hullColor = RGB2(150, 150, 150)
  containerColor = RandomColor(*palette)
  engineColor = RGB2(255, 150, 0)

  ; Large cargo containers
  DrawRectangle(*sprite, 10, 8, 12, 6, containerColor)
  DrawRectangle(*sprite, 10, 15, 12, 6, RandomColor(*palette))

  ; Hull/frame
  DrawRectangle(*sprite, 12, 7, 8, 1, hullColor)
  DrawRectangle(*sprite, 12, 14, 8, 1, hullColor)
  DrawRectangle(*sprite, 12, 21, 8, 1, hullColor)

  ; Cockpit section (small)
  DrawRectangle(*sprite, 14, 4, 4, 3, hullColor)
  SetPixel(*sprite, 15, 5, RGB2(100, 150, 200))
  SetPixel(*sprite, 16, 5, RGB2(100, 150, 200))

  ; Engine pods
  DrawRectangle(*sprite, 11, 22, 3, 4, RGB2(100, 100, 100))
  DrawRectangle(*sprite, 18, 22, 3, 4, RGB2(100, 100, 100))

  ; Engine glow
  SetPixel(*sprite, 12, 26, engineColor)
  SetPixel(*sprite, 19, 26, engineColor)

  If complexity > 50
    ; Struts/supports
    SetPixel(*sprite, 10, 9, hullColor)
    SetPixel(*sprite, 10, 10, hullColor)
    SetPixel(*sprite, 21, 9, hullColor)
    SetPixel(*sprite, 21, 10, hullColor)

    ; Container details
    DrawRectangle(*sprite, 11, 9, 10, 1, RGB2(100, 100, 100))
    DrawRectangle(*sprite, 11, 16, 10, 1, RGB2(100, 100, 100))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateScout(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, cockpitColor.l, engineColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Scout Ship"
  
  bodyColor = RandomColor(*palette)
  cockpitColor = RGB2(100, 200, 255)
  engineColor = RGB2(0, 200, 255)
  
  ; Small sleek body
  DrawRectangle(*sprite, 15, 10, 2, 12, bodyColor)
  
  ; Nose
  SetPixel(*sprite, 15, 9, bodyColor)
  SetPixel(*sprite, 16, 9, bodyColor)
  SetPixel(*sprite, 15, 8, bodyColor)
  SetPixel(*sprite, 16, 8, bodyColor)
  
  ; Cockpit
  DrawCircle(*sprite, 16, 12, 2, cockpitColor)
  
  ; Small wings
  DrawRectangle(*sprite, 13, 16, 2, 3, bodyColor)
  DrawRectangle(*sprite, 17, 16, 2, 3, bodyColor)
  
  ; Engine
  DrawCircle(*sprite, 16, 22, 1, RGB2(100, 100, 100))
  
  ; Engine trail
  SetPixel(*sprite, 16, 23, engineColor)
  SetPixel(*sprite, 15, 24, RGB2(100, 220, 255))
  SetPixel(*sprite, 16, 24, engineColor)
  SetPixel(*sprite, 17, 24, RGB2(100, 220, 255))
  
  If complexity > 40
    ; Scanner dish
    DrawCircle(*sprite, 16, 14, 1, RGB2(200, 200, 200))
    
    ; Navigation lights
    SetPixel(*sprite, 13, 17, RGB2(255, 0, 0))
    SetPixel(*sprite, 19, 17, RGB2(0, 255, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateMiningShip(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected hullColor.l, drillColor.l, tankColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Mining Ship"
  
  hullColor = RGB2(200, 150, 0)
  drillColor = RGB2(150, 150, 150)
  tankColor = RGB2(100, 100, 100)
  
  ; Main hull (industrial)
  DrawRectangle(*sprite, 12, 12, 8, 10, hullColor)
  
  ; Storage tanks
  DrawCircle(*sprite, 14, 14, 2, tankColor)
  DrawCircle(*sprite, 18, 14, 2, tankColor)
  
  ; Drill arms (front)
  Protected i
  For i = 0 To 4
    SetPixel(*sprite, 10 - i, 8 + i, drillColor)
    SetPixel(*sprite, 21 + i, 8 + i, drillColor)
  Next
  
  ; Drill heads
  DrawCircle(*sprite, 6, 12, 2, RGB2(100, 100, 100))
  DrawCircle(*sprite, 25, 12, 2, RGB2(100, 100, 100))
  
  ; Drill bits (spinning)
  SetPixel(*sprite, 5, 12, RGB2(200, 200, 0))
  SetPixel(*sprite, 6, 11, RGB2(200, 200, 0))
  SetPixel(*sprite, 7, 12, RGB2(200, 200, 0))
  SetPixel(*sprite, 26, 12, RGB2(200, 200, 0))
  SetPixel(*sprite, 25, 11, RGB2(200, 200, 0))
  SetPixel(*sprite, 24, 12, RGB2(200, 200, 0))
  
  ; Cockpit
  DrawRectangle(*sprite, 15, 10, 2, 2, RGB2(100, 150, 200))
  
  ; Engine
  DrawRectangle(*sprite, 14, 22, 4, 2, RGB2(80, 80, 80))
  SetPixel(*sprite, 15, 24, RGB2(255, 150, 0))
  SetPixel(*sprite, 16, 24, RGB2(255, 150, 0))
  
  If complexity > 50
    ; Ore containers
    DrawRectangle(*sprite, 13, 18, 2, 3, RGB2(139, 69, 19))
    DrawRectangle(*sprite, 17, 18, 2, 3, RGB2(139, 69, 19))
    
    ; Warning stripes
    SetPixel(*sprite, 12, 13, RGB2(255, 255, 0))
    SetPixel(*sprite, 19, 13, RGB2(255, 255, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure



Procedure GenerateSportsCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Sports Car"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(50, 50, 80)
  wheelColor = RGB2(40, 40, 40)
  
  ; Low profile body
  DrawRectangle(*sprite, 6, 18, 20, 6, bodyColor)
  
  ; Hood slope
  DrawRectangle(*sprite, 4, 19, 2, 4, bodyColor)
  SetPixel(*sprite, 3, 20, bodyColor)
  SetPixel(*sprite, 3, 21, bodyColor)
  
  ; Windshield/cabin (sleek)
  DrawRectangle(*sprite, 12, 15, 8, 3, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 13, 16, 3, 1, windowColor)
  DrawRectangle(*sprite, 17, 16, 3, 1, windowColor)
  
  ; Wheels (low profile)
  DrawCircle(*sprite, 9, 24, 2, wheelColor)
  DrawCircle(*sprite, 23, 24, 2, wheelColor)
  
  ; Wheel rims (sporty)
  SetPixel(*sprite, 9, 24, RGB2(180, 180, 180))
  SetPixel(*sprite, 23, 24, RGB2(180, 180, 180))
  
  ; Rear spoiler
  DrawRectangle(*sprite, 23, 14, 2, 1, bodyColor)
  DrawRectangle(*sprite, 24, 15, 1, 3, bodyColor)
  
  If complexity > 50
    ; Headlights
    SetPixel(*sprite, 2, 20, RGB2(255, 255, 200))
    SetPixel(*sprite, 2, 21, RGB2(255, 255, 200))
    
    ; Racing stripes
    SetPixel(*sprite, 15, 19, RGB2(255, 255, 255))
    SetPixel(*sprite, 16, 19, RGB2(255, 255, 255))
    SetPixel(*sprite, 15, 20, RGB2(255, 255, 255))
    SetPixel(*sprite, 16, 20, RGB2(255, 255, 255))
    
    ; Air intake
    DrawRectangle(*sprite, 10, 16, 2, 1, RGB2(50, 50, 50))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateSedan(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Sedan"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(100, 150, 200)
  wheelColor = RGB2(50, 50, 50)
  
  ; Main body
  DrawRectangle(*sprite, 6, 17, 20, 7, bodyColor)
  
  ; Hood
  DrawRectangle(*sprite, 4, 18, 2, 5, bodyColor)
  
  ; Cabin roof
  DrawRectangle(*sprite, 10, 13, 12, 4, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 11, 14, 4, 2, windowColor)
  DrawRectangle(*sprite, 16, 14, 4, 2, windowColor)
  
  ; Windshield
  DrawRectangle(*sprite, 9, 15, 2, 2, windowColor)
  
  ; Rear window
  DrawRectangle(*sprite, 21, 15, 2, 2, windowColor)
  
  ; Wheels
  DrawCircle(*sprite, 10, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  ; Wheel hubs
  SetPixel(*sprite, 10, 24, RGB2(150, 150, 150))
  SetPixel(*sprite, 22, 24, RGB2(150, 150, 150))
  
  If complexity > 50
    ; Headlights
    SetPixel(*sprite, 3, 19, RGB2(255, 255, 200))
    SetPixel(*sprite, 3, 22, RGB2(255, 255, 200))
    
    ; Tail lights
    SetPixel(*sprite, 26, 19, RGB2(255, 0, 0))
    SetPixel(*sprite, 26, 22, RGB2(255, 0, 0))
    
    ; Door handles
    SetPixel(*sprite, 13, 19, RGB2(100, 100, 100))
    SetPixel(*sprite, 18, 19, RGB2(100, 100, 100))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateSUV(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "SUV"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(80, 100, 120)
  wheelColor = RGB2(45, 45, 45)
  
  ; Main body (tall)
  DrawRectangle(*sprite, 6, 14, 20, 10, bodyColor)
  
  ; Hood
  DrawRectangle(*sprite, 4, 16, 2, 6, bodyColor)
  
  ; Roof
  DrawRectangle(*sprite, 8, 10, 16, 4, bodyColor)
  
  ; Windows (higher up)
  DrawRectangle(*sprite, 9, 11, 4, 2, windowColor)
  DrawRectangle(*sprite, 14, 11, 4, 2, windowColor)
  DrawRectangle(*sprite, 19, 11, 4, 2, windowColor)
  
  ; Windshield
  DrawRectangle(*sprite, 6, 12, 2, 2, windowColor)
  
  ; Wheels (larger)
  DrawCircle(*sprite, 10, 24, 3, wheelColor)
  DrawCircle(*sprite, 22, 24, 3, wheelColor)
  
  ; Wheel rims
  DrawCircle(*sprite, 10, 24, 1, RGB2(150, 150, 150))
  DrawCircle(*sprite, 22, 24, 1, RGB2(150, 150, 150))
  
  ; Roof rack
  If complexity > 50
    DrawRectangle(*sprite, 9, 9, 14, 1, RGB2(100, 100, 100))
    SetPixel(*sprite, 10, 8, RGB2(100, 100, 100))
    SetPixel(*sprite, 15, 8, RGB2(100, 100, 100))
    SetPixel(*sprite, 20, 8, RGB2(100, 100, 100))
    
    ; Running boards
    DrawRectangle(*sprite, 8, 23, 16, 1, RGB2(120, 120, 120))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GeneratePickupTruck(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, bedColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Pickup Truck"
  
  bodyColor = RandomColor(*palette)
  bedColor = bodyColor
  windowColor = RGB2(100, 150, 200)
  wheelColor = RGB2(40, 40, 40)
  
  ; Cabin
  DrawRectangle(*sprite, 6, 14, 10, 10, bodyColor)
  
  ; Hood
  DrawRectangle(*sprite, 4, 16, 2, 6, bodyColor)
  
  ; Roof
  DrawRectangle(*sprite, 8, 11, 6, 3, bodyColor)
  
  ; Windows
  DrawRectangle(*sprite, 9, 12, 3, 1, windowColor)
  
  ; Windshield
  DrawRectangle(*sprite, 6, 13, 2, 2, windowColor)
  
  ; Truck bed
  DrawRectangle(*sprite, 16, 16, 10, 8, bedColor)
  
  ; Bed rails
  DrawRectangle(*sprite, 16, 15, 10, 1, RGB2(100, 100, 100))
  
  ; Tailgate
  DrawRectangle(*sprite, 26, 17, 1, 6, bedColor)
  
  ; Wheels
  DrawCircle(*sprite, 9, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  ; Wheel rims
  SetPixel(*sprite, 9, 24, RGB2(150, 150, 150))
  SetPixel(*sprite, 22, 24, RGB2(150, 150, 150))
  
  If complexity > 50
    ; Headlights
    SetPixel(*sprite, 3, 17, RGB2(255, 255, 200))
    SetPixel(*sprite, 3, 20, RGB2(255, 255, 200))
    
    ; Cargo in bed
    DrawRectangle(*sprite, 18, 18, 4, 3, RGB2(139, 69, 19))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateSemiTruck(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected cabColor.l, trailerColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Semi Truck"
  
  cabColor = RandomColor(*palette)
  trailerColor = RGB2(200, 200, 200)
  wheelColor = RGB2(40, 40, 40)
  
  ; Cab
  DrawRectangle(*sprite, 4, 16, 8, 8, cabColor)
  
  ; Cab roof
  DrawRectangle(*sprite, 5, 13, 6, 3, cabColor)
  
  ; Windshield
  DrawRectangle(*sprite, 4, 14, 2, 2, RGB2(100, 150, 200))
  
  ; Exhaust stack
  DrawRectangle(*sprite, 10, 12, 1, 4, RGB2(100, 100, 100))
  SetPixel(*sprite, 10, 11, RGB2(80, 80, 80))
  
  ; Trailer
  DrawRectangle(*sprite, 12, 14, 16, 10, trailerColor)
  
  ; Trailer doors
  DrawRectangle(*sprite, 27, 16, 1, 6, RGB2(150, 150, 150))
  
  ; Wheels (multiple)
  DrawCircle(*sprite, 8, 24, 2, wheelColor)
  DrawCircle(*sprite, 16, 24, 2, wheelColor)
  DrawCircle(*sprite, 24, 24, 2, wheelColor)
  
  If complexity > 50
    ; Grill
    DrawRectangle(*sprite, 3, 17, 1, 5, RGB2(100, 100, 100))
    
    ; Running lights
    SetPixel(*sprite, 12, 13, RGB2(255, 150, 0))
    SetPixel(*sprite, 27, 13, RGB2(255, 0, 0))
    
    ; Company logo
    DrawRectangle(*sprite, 18, 18, 6, 4, RGB2(255, 200, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateVan(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Van"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(100, 150, 200)
  wheelColor = RGB2(50, 50, 50)
  
  ; Main body (tall box)
  DrawRectangle(*sprite, 6, 12, 20, 12, bodyColor)
  
  ; Hood
  DrawRectangle(*sprite, 4, 16, 2, 6, bodyColor)
  
  ; Windshield
  DrawRectangle(*sprite, 6, 13, 2, 3, windowColor)
  
  ; Side windows
  DrawRectangle(*sprite, 10, 14, 3, 2, windowColor)
  DrawRectangle(*sprite, 15, 14, 3, 2, windowColor)
  DrawRectangle(*sprite, 20, 14, 3, 2, windowColor)
  
  ; Wheels
  DrawCircle(*sprite, 10, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  ; Wheel hubs
  SetPixel(*sprite, 10, 24, RGB2(150, 150, 150))
  SetPixel(*sprite, 22, 24, RGB2(150, 150, 150))
  
  ; Sliding door outline
  If complexity > 50
    DrawRectangle(*sprite, 13, 18, 1, 5, RGB2(100, 100, 100))
    
    ; Roof vent
    DrawRectangle(*sprite, 14, 11, 4, 1, RGB2(120, 120, 120))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateMotorcycle(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bikeColor.l, wheelColor.l, chromeColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Motorcycle"
  
  bikeColor = RandomColor(*palette)
  wheelColor = RGB2(40, 40, 40)
  chromeColor = RGB2(200, 200, 200)
  
  ; Front wheel
  DrawCircle(*sprite, 10, 22, 3, wheelColor)
  SetPixel(*sprite, 10, 22, chromeColor)
  
  ; Rear wheel
  DrawCircle(*sprite, 22, 22, 3, wheelColor)
  SetPixel(*sprite, 22, 22, chromeColor)
  
  ; Frame
  Protected i
  For i = 0 To 11
    SetPixel(*sprite, 10 + i, 22 - i, chromeColor)
  Next
  
  ; Fuel tank/seat
  DrawRectangle(*sprite, 14, 14, 6, 4, bikeColor)
  
  ; Handlebars
  DrawRectangle(*sprite, 9, 10, 3, 1, chromeColor)
  
  ; Front fork
  SetPixel(*sprite, 10, 11, chromeColor)
  SetPixel(*sprite, 10, 12, chromeColor)
  SetPixel(*sprite, 10, 13, chromeColor)
  
  ; Exhaust pipe
  For i = 0 To 5
    SetPixel(*sprite, 18 + i, 18 + i, chromeColor)
  Next
  SetPixel(*sprite, 24, 24, RGB2(100, 100, 100))
  
  ; Rider (optional)
  If complexity > 50
    ; Helmet
    DrawCircle(*sprite, 16, 8, 2, RGB2(255, 0, 0))
    
    ; Body
    DrawRectangle(*sprite, 15, 10, 2, 4, RGB2(50, 50, 50))
    
    ; Arms
    SetPixel(*sprite, 14, 11, RGB2(50, 50, 50))
    SetPixel(*sprite, 13, 11, RGB2(50, 50, 50))
    SetPixel(*sprite, 12, 11, RGB2(50, 50, 50))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateScooter(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected scooterColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Scooter"
  
  scooterColor = RandomColor(*palette)
  wheelColor = RGB2(50, 50, 50)
  
  ; Front wheel (small)
  DrawCircle(*sprite, 11, 24, 2, wheelColor)
  
  ; Rear wheel (small)
  DrawCircle(*sprite, 21, 24, 2, wheelColor)
  
  ; Footboard
  DrawRectangle(*sprite, 12, 22, 8, 2, scooterColor)
  
  ; Body/seat area
  DrawRectangle(*sprite, 16, 18, 6, 4, scooterColor)
  
  ; Seat
  DrawRectangle(*sprite, 17, 16, 4, 2, RGB2(100, 50, 0))
  
  ; Handlebars
  DrawRectangle(*sprite, 10, 16, 3, 1, RGB2(150, 150, 150))
  
  ; Front column
  SetPixel(*sprite, 11, 17, RGB2(150, 150, 150))
  SetPixel(*sprite, 11, 18, RGB2(150, 150, 150))
  SetPixel(*sprite, 11, 19, RGB2(150, 150, 150))
  
  ; Headlight
  SetPixel(*sprite, 11, 20, RGB2(255, 255, 200))
  
  If complexity > 40
    ; Storage compartment
    DrawRectangle(*sprite, 18, 19, 3, 2, RGB2(100, 100, 100))
    
    ; Mirror
    SetPixel(*sprite, 9, 16, RGB2(200, 200, 200))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateRaceCar(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, wheelColor.l, sponsorColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Race Car"
  
  bodyColor = RandomColor(*palette)
  wheelColor = RGB2(30, 30, 30)
  sponsorColor = RGB2(255, 255, 0)
  
  ; Aerodynamic body
  DrawRectangle(*sprite, 6, 19, 20, 5, bodyColor)
  
  ; Nose cone
  SetPixel(*sprite, 5, 20, bodyColor)
  SetPixel(*sprite, 5, 21, bodyColor)
  SetPixel(*sprite, 4, 20, bodyColor)
  SetPixel(*sprite, 4, 21, bodyColor)
  SetPixel(*sprite, 3, 21, bodyColor)
  
  ; Cockpit
  DrawRectangle(*sprite, 14, 17, 4, 2, RGB2(50, 50, 50))
  
  ; Roll cage
  DrawRectangle(*sprite, 13, 16, 6, 1, RGB2(150, 150, 150))
  
  ; Wheels (racing slicks)
  DrawCircle(*sprite, 10, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  ; Front wing
  DrawRectangle(*sprite, 4, 18, 3, 1, bodyColor)
  DrawRectangle(*sprite, 4, 24, 3, 1, bodyColor)
  
  ; Rear wing
  DrawRectangle(*sprite, 24, 16, 2, 1, bodyColor)
  DrawRectangle(*sprite, 25, 17, 1, 6, RGB2(150, 150, 150))
  
  If complexity > 50
    ; Racing number
    DrawRectangle(*sprite, 15, 20, 2, 2, sponsorColor)
    
    ; Sponsor decals
    SetPixel(*sprite, 10, 20, sponsorColor)
    SetPixel(*sprite, 11, 20, sponsorColor)
    SetPixel(*sprite, 18, 20, sponsorColor)
    SetPixel(*sprite, 19, 20, sponsorColor)
    
    ; Air intake
    DrawRectangle(*sprite, 12, 17, 2, 1, RGB2(50, 50, 50))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure


Procedure GenerateBus(*sprite.SpriteData, *palette.ColorPalette, symmetry.l, complexity.l)
  Protected bodyColor.l, windowColor.l, wheelColor.l
  
  ClearSprite(*sprite)
  *sprite\name = "Bus"
  
  bodyColor = RandomColor(*palette)
  windowColor = RGB2(100, 150, 200)
  wheelColor = RGB2(45, 45, 45)
  
  ; Main body (long and tall)
  DrawRectangle(*sprite, 4, 12, 24, 12, bodyColor)
  
  ; Windshield
  DrawRectangle(*sprite, 4, 13, 2, 3, windowColor)
  
  ; Side windows (many)
  Protected i
  For i = 0 To 4
    DrawRectangle(*sprite, 8 + i * 4, 14, 3, 2, windowColor)
  Next
  
  ; Wheels
  DrawCircle(*sprite, 10, 24, 2, wheelColor)
  DrawCircle(*sprite, 22, 24, 2, wheelColor)
  
  ; Wheel hubs
  SetPixel(*sprite, 10, 24, RGB2(150, 150, 150))
  SetPixel(*sprite, 22, 24, RGB2(150, 150, 150))
  
  ; Door
  DrawRectangle(*sprite, 6, 18, 3, 5, RGB2(100, 100, 100))
  
  If complexity > 50
    ; Destination sign
    DrawRectangle(*sprite, 5, 11, 6, 1, RGB2(255, 255, 0))
    
    ; Headlights
    SetPixel(*sprite, 3, 14, RGB2(255, 255, 200))
    SetPixel(*sprite, 3, 20, RGB2(255, 255, 200))
    
    ; Route number
    DrawRectangle(*sprite, 14, 11, 4, 1, RGB2(255, 255, 0))
  EndIf
  
  If symmetry > 0
    ApplySymmetry(*sprite, symmetry)
  EndIf
EndProcedure
