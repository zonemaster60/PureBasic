Procedure HideRangeIndicators()
  Protected I.i

  For I = 0 To #RangeSegmentCount - 1
    MoveEntity(RangeSegments(I), 0, -10, 0, #PB_Absolute)
  Next
EndProcedure

Procedure ShowRangeIndicators(CenterX.f, CenterZ.f, Radius.f)
  Protected I.i
  Protected Angle.f
  Protected X.f
  Protected Z.f

  For I = 0 To #RangeSegmentCount - 1
    Angle = #Tau * I / #RangeSegmentCount
    X = CenterX + Cos(Angle) * Radius
    Z = CenterZ + Sin(Angle) * Radius
    MoveEntity(RangeSegments(I), X, 0.09, Z, #PB_Absolute)
    ScaleEntity(RangeSegments(I), 0.10, 0.02, 0.10, #PB_Absolute)
  Next
EndProcedure

Procedure.i FindTower(TowerID.i)
  If FindTowerPointer(TowerID)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i FindTowerPointer(TowerID.i)
  ForEach Towers()
    If Towers()\id = TowerID
      ProcedureReturn @Towers()
    EndIf
  Next

  ProcedureReturn 0
EndProcedure

Procedure.i AnyUpgradeableTower()
  ForEach Towers()
    If Towers()\type <> #TowerType_Block And Towers()\level < 3
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure SelectTower(TowerID.i)
  Protected *Tower.Tower
  Protected Radius.f
  Protected CenterX.f
  Protected CenterZ.f

  SelectedTowerID = 0
  RangePreviewActive = #False
  HideRangeIndicators()

  If TowerID <> 0
    *Tower = FindTowerPointer(TowerID)
    If *Tower
      SelectedTowerID = TowerID
      CenterX = WorldXFromGrid(*Tower\gx)
      CenterZ = WorldZFromGrid(*Tower\gz)
      Radius = *Tower\range
      If Radius > 0
        ShowRangeIndicators(CenterX, CenterZ, Radius)
      EndIf
    EndIf
  EndIf

  If TowerID <> 0 And SelectedTowerID = 0
    PendingGridAction = #GridAction_None
  EndIf

  RefreshSidebar()
EndProcedure

Procedure.f TowerPreviewRange(TowerType.i)
  Protected PreviewTower.Tower

  If TowerType <= #TowerType_None
    ProcedureReturn 0
  EndIf

  PreviewTower\type = TowerType
  PreviewTower\level = 1
  ConfigureTowerStats(@PreviewTower)
  ProcedureReturn PreviewTower\range
EndProcedure

Procedure ConfigureTowerStats(*Tower.Tower)
  Select *Tower\type
    Case #TowerType_Pulse
      *Tower\range = (5.6 + (*Tower\level - 1) * 0.45) * ConfigTowerRangeScale
      *Tower\damage = (15 + (*Tower\level - 1) * 7) * ConfigTowerDamageScale
      *Tower\fireDelay = 0.66 - (*Tower\level - 1) * 0.06
      If *Tower\fireDelay < 0.42
        *Tower\fireDelay = 0.42
      EndIf
      *Tower\projectileSpeed = 18 + (*Tower\level - 1) * 2
      *Tower\splash = 0
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 1

    Case #TowerType_Cannon
      *Tower\range = (4.9 + (*Tower\level - 1) * 0.30) * ConfigTowerRangeScale
      *Tower\damage = (30 + (*Tower\level - 1) * 15) * ConfigTowerDamageScale
      *Tower\fireDelay = 1.28 - (*Tower\level - 1) * 0.10
      If *Tower\fireDelay < 0.85
        *Tower\fireDelay = 0.85
      EndIf
      *Tower\projectileSpeed = 14 + (*Tower\level - 1)
      *Tower\splash = 1.8 + (*Tower\level - 1) * 0.25
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 1

    Case #TowerType_Frost
      *Tower\range = (5.1 + (*Tower\level - 1) * 0.35) * ConfigTowerRangeScale
      *Tower\damage = (7 + (*Tower\level - 1) * 3) * ConfigTowerDamageScale
      *Tower\fireDelay = 0.52 - (*Tower\level - 1) * 0.04
      If *Tower\fireDelay < 0.34
        *Tower\fireDelay = 0.34
      EndIf
      *Tower\projectileSpeed = 17 + (*Tower\level - 1)
      *Tower\splash = 0
      *Tower\slowPower = 0.62 - (*Tower\level - 1) * 0.07
      If *Tower\slowPower < 0.38
        *Tower\slowPower = 0.38
      EndIf
      *Tower\slowTime = 1.3 + (*Tower\level - 1) * 0.35
      *Tower\shotCount = 1

    Case #TowerType_Beam
      *Tower\range = (4.6 + (*Tower\level - 1) * 0.30) * ConfigTowerRangeScale
      *Tower\damage = (11 + (*Tower\level - 1) * 7) * ConfigTowerDamageScale
      *Tower\fireDelay = 0.20 - (*Tower\level - 1) * 0.02
      If *Tower\fireDelay < 0.12
        *Tower\fireDelay = 0.12
      EndIf
      *Tower\projectileSpeed = 30 + (*Tower\level - 1) * 2
      *Tower\splash = 0
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 1

    Case #TowerType_Mortar
      *Tower\range = (6.8 + (*Tower\level - 1) * 0.45) * ConfigTowerRangeScale
      *Tower\damage = (40 + (*Tower\level - 1) * 16) * ConfigTowerDamageScale
      *Tower\fireDelay = 1.70 - (*Tower\level - 1) * 0.14
      If *Tower\fireDelay < 1.20
        *Tower\fireDelay = 1.20
      EndIf
      *Tower\projectileSpeed = 11 + (*Tower\level - 1)
      *Tower\splash = 2.5 + (*Tower\level - 1) * 0.35
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 1

    Case #TowerType_Sky
      *Tower\range = (6.2 + (*Tower\level - 1) * 0.35) * ConfigTowerRangeScale
      *Tower\damage = (22 + (*Tower\level - 1) * 9) * ConfigTowerDamageScale
      *Tower\fireDelay = 0.58 - (*Tower\level - 1) * 0.04
      If *Tower\fireDelay < 0.42
        *Tower\fireDelay = 0.42
      EndIf
      *Tower\projectileSpeed = 24 + (*Tower\level - 1) * 2
      *Tower\splash = 0
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 1 + Bool(*Tower\level >= 3)

    Case #TowerType_Block
      *Tower\range = 0
      *Tower\damage = 0
      *Tower\fireDelay = 0
      *Tower\projectileSpeed = 0
      *Tower\splash = 0
      *Tower\slowPower = 0
      *Tower\slowTime = 0
      *Tower\shotCount = 0
  EndSelect
EndProcedure

Procedure.i BuildTower(GX.i, GZ.i, TowerType.i)
  Protected Cost.i = TowerBaseCost(TowerType)
  Protected X.f = WorldXFromGrid(GX)
  Protected Z.f = WorldZFromGrid(GZ)
  Protected HeadY.f = 1.25

  If GameState <> #GameState_Playing
    ProcedureReturn #False
  EndIf

  If GX < 0 Or GX >= #GridWidth Or GZ < 0 Or GZ >= #GridHeight
    ProcedureReturn #False
  EndIf

  If CellCanHostTower(GX, GZ, TowerType) = #False
    If Grid(GX, GZ)\towerID <> 0
      SetStatus("That tile is already occupied.", 1.5)
    ElseIf TowerType = #TowerType_Block
      If IsRouteEndpoint(GX, GZ)
        SetStatus("The route endpoints cannot be blocked.", 1.5)
      Else
        SetStatus("Blocks can only be placed on the route.", 1.5)
      EndIf
    Else
      SetStatus("The path must stay open.", 1.5)
    EndIf
    ProcedureReturn #False
  EndIf

  If Gold < Cost
    If TowerType = #TowerType_Block
      SetStatus("Not enough gold for a block.", 1.5)
    Else
      SetStatus("Not enough gold for a " + TowerName(TowerType) + " tower.", 1.5)
    EndIf
    ProcedureReturn #False
  EndIf

  If TowerType = #TowerType_Block
    If CanPlaceBlockAt(GX, GZ) = #False
      SetStatus("That block would seal every route.", 1.5)
      ProcedureReturn #False
    EndIf
  EndIf

  AddElement(Towers())
  Towers()\id = NextTowerID
  NextTowerID + 1
  Towers()\type = TowerType
  Towers()\level = 1
  Towers()\gx = GX
  Towers()\gz = GZ
  Towers()\cooldown = 0.1
  Towers()\targetMode = #TargetMode_First
  Towers()\totalValue = Cost
  ConfigureTowerStats(@Towers())

  Select TowerType
    Case #TowerType_Pulse
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatAccent), X, 0.45, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatPulse), X, HeadY, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatMuzzlePulse), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 1.15, 0.78, 1.15, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.58, 0.70, 0.58, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.26, 0.26, 0.26, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 0, 18, 0, #PB_Absolute)

    Case #TowerType_Cannon
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatAccent), X, 0.42, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatCannon), X, 1.05, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatMuzzleCannon), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 1.18, 0.72, 1.18, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.88, 0.38, 0.88, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.24, 0.24, 0.24, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 0, 45, 0, #PB_Absolute)

    Case #TowerType_Frost
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatAccent), X, 0.45, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatFrost), X, HeadY, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatMuzzleFrost), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 1.02, 0.95, 1.02, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.52, 0.96, 0.52, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.22, 0.22, 0.22, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 0, -20, 0, #PB_Absolute)

    Case #TowerType_Beam
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatAccent), X, 0.40, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatBeam), X, 1.05, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatMuzzleBeam), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 0.96, 0.72, 0.96, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.40, 1.10, 0.40, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.18, 0.18, 0.18, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 0, 30, 12, #PB_Absolute)

    Case #TowerType_Mortar
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatAccent), X, 0.40, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatMortar), X, 0.96, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatMuzzleMortar), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 1.22, 0.64, 1.22, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.62, 0.70, 0.62, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.26, 0.26, 0.26, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 0, 0, 90, #PB_Absolute)

    Case #TowerType_Sky
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatAccent), X, 0.42, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshCone), MaterialID(MatSky), X, 1.18, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatMuzzleSky), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, 1.00, 0.82, 1.00, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, 0.52, 1.05, 0.52, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.20, 0.20, 0.20, #PB_Absolute)
      RotateEntity(Towers()\headEntity, 180, 0, 0, #PB_Absolute)

    Case #TowerType_Block
      Towers()\baseEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatBlock), X, 0.50, Z)
      Towers()\headEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatAccent), X, 1.04, Z)
      Towers()\muzzleEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatBlock), X, -10, Z)
      ScaleEntity(Towers()\baseEntity, #CellSize * 0.70, 0.82, #CellSize * 0.70, #PB_Absolute)
      ScaleEntity(Towers()\headEntity, #CellSize * 0.42, 0.26, #CellSize * 0.42, #PB_Absolute)
      ScaleEntity(Towers()\muzzleEntity, 0.01, 0.01, 0.01, #PB_Absolute)
  EndSelect

  Gold - Cost
  Grid(GX, GZ)\towerID = Towers()\id

  If TowerType = #TowerType_Block
    RecalculatePath(#True, -1, -1)
  EndIf

  SelectTower(Towers()\id)
  If TowerType = #TowerType_Block
    SetStatus("Block deployed. Ground enemies are rerouting.", 1.4)
  Else
    SetStatus(TowerName(TowerType) + " tower deployed.", 1.2)
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure UpgradeSelectedTower()
  Protected *Tower.Tower
  Protected UpgradeCost.i

  If SelectedTowerID = 0
    ProcedureReturn
  EndIf

  *Tower = FindTowerPointer(SelectedTowerID)
  If *Tower = 0
    SelectTower(0)
    ProcedureReturn
  EndIf

  If *Tower\type = #TowerType_Block
    SetStatus("Blocks cannot be upgraded.", 1.3)
    ProcedureReturn
  EndIf

  If *Tower\level >= 3
    SetStatus("That tower is already maxed.", 1.3)
    ProcedureReturn
  EndIf

  UpgradeCost = Int(TowerBaseCost(*Tower\type) * (0.65 + 0.30 * *Tower\level))

  If Gold < UpgradeCost
    SetStatus("You need " + Str(UpgradeCost) + " gold to upgrade.", 1.4)
    ProcedureReturn
  EndIf

  Gold - UpgradeCost
  *Tower\level + 1
  *Tower\totalValue + UpgradeCost
  ConfigureTowerStats(*Tower)
  SetStatus(TowerName(*Tower\type) + " tower upgraded to level " + Str(*Tower\level) + ".", 1.4)
  SelectTower(*Tower\id)
EndProcedure

Procedure UpgradeTowerByID(TowerID.i)
  SelectTower(TowerID)
  UpgradeSelectedTower()
EndProcedure

Procedure SellSelectedTower()
  Protected *Tower.Tower
  Protected SellValue.i
  Protected GX.i
  Protected GZ.i

  If SelectedTowerID = 0
    ProcedureReturn
  EndIf

  *Tower = FindTowerPointer(SelectedTowerID)
  If *Tower = 0
    SelectTower(0)
    ProcedureReturn
  EndIf

  SellValue = Int(*Tower\totalValue * 0.75)
  GX = *Tower\gx
  GZ = *Tower\gz
  Gold + SellValue
  Grid(GX, GZ)\towerID = 0
  ChangeCurrentElement(Towers(), *Tower)
  FreeEntity(Towers()\baseEntity)
  FreeEntity(Towers()\headEntity)
  FreeEntity(Towers()\muzzleEntity)
  If Towers()\type = #TowerType_Block
    RecalculatePath(#True, -1, -1)
    SetStatus("Block sold. The route reopens and enemies adjust.", 1.4)
  Else
    SetStatus("Tower sold for " + Str(SellValue) + " gold.", 1.4)
  EndIf
  DeleteElement(Towers())
  SelectTower(0)
EndProcedure

Procedure SellTowerByID(TowerID.i)
  SelectTower(TowerID)
  SellSelectedTower()
EndProcedure
