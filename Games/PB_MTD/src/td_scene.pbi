#APP_NAME = "PB_MTD"

Procedure.f WorldXFromGrid(GX.i)
  ProcedureReturn ((GX + 0.5) - #GridWidth / 2.0) * #CellSize
EndProcedure

Procedure.f WorldZFromGrid(GZ.i)
  ProcedureReturn ((GZ + 0.5) - #GridHeight / 2.0) * #CellSize
EndProcedure

Procedure.i GridXFromWorld(X.f)
  Protected LeftEdge.f = -(#GridWidth * #CellSize) / 2.0
  ProcedureReturn Int((X - LeftEdge) / #CellSize)
EndProcedure

Procedure.i GridZFromWorld(Z.f)
  Protected TopEdge.f = -(#GridHeight * #CellSize) / 2.0
  ProcedureReturn Int((Z - TopEdge) / #CellSize)
EndProcedure

Procedure.i IsPathCell(GX.i, GZ.i)
  Protected I.i

  For I = 0 To PathPointCount - 1
    If PathGX(I) = GX And PathGZ(I) = GZ
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure.i WaveRemainder(Value.i, Divisor.i)
  ProcedureReturn Value - Int(Value / Divisor) * Divisor
EndProcedure

Procedure.i TowerBaseCost(TowerType.i)
  Select TowerType
    Case #TowerType_Pulse
      ProcedureReturn 70
    Case #TowerType_Cannon
      ProcedureReturn 110
    Case #TowerType_Frost
      ProcedureReturn 90
    Case #TowerType_Beam
      ProcedureReturn 125
    Case #TowerType_Mortar
      ProcedureReturn 150
    Case #TowerType_Sky
      ProcedureReturn 135
    Case #TowerType_Block
      ProcedureReturn 50
  EndSelect

  ProcedureReturn 0
EndProcedure

Procedure.s TowerName(TowerType.i)
  Select TowerType
    Case #TowerType_Pulse
      ProcedureReturn "Pulse"
    Case #TowerType_Cannon
      ProcedureReturn "Cannon"
    Case #TowerType_Frost
      ProcedureReturn "Frost"
    Case #TowerType_Beam
      ProcedureReturn "Beam"
    Case #TowerType_Mortar
      ProcedureReturn "Mortar"
    Case #TowerType_Sky
      ProcedureReturn "Sky"
    Case #TowerType_Block
      ProcedureReturn "Block"
  EndSelect

  ProcedureReturn "None"
EndProcedure

Procedure.s EnemyName(EnemyType.i)
  Select EnemyType
    Case #EnemyType_Runner
      ProcedureReturn "Runner"
    Case #EnemyType_Brute
      ProcedureReturn "Brute"
    Case #EnemyType_Swarm
      ProcedureReturn "Swarm"
    Case #EnemyType_Shield
      ProcedureReturn "Shield"
    Case #EnemyType_Splitter
      ProcedureReturn "Splitter"
    Case #EnemyType_Glider
      ProcedureReturn "Glider"
    Case #EnemyType_Leech
      ProcedureReturn "Leech"
    Case #EnemyType_Siege
      ProcedureReturn "Siege"
    Case #EnemyType_Overseer
      ProcedureReturn "Overseer"
    Case #EnemyType_Boss
      ProcedureReturn "Boss"
  EndSelect

  ProcedureReturn "Unknown"
EndProcedure

Procedure LoadBalanceConfig()
  Protected ConfigFile.s = AppPath + "..\\balance.cfg"
  Protected Line.s
  Protected Pos.i
  Protected Key.s
  Protected Value.f

  ConfigTowerDamageScale = 1.0
  ConfigTowerRangeScale = 1.0
  ConfigEnemyHealthScale = 1.0
  ConfigEnemySpeedScale = 1.0
  ConfigBurnScale = 1.0

  If ReadFile(0, ConfigFile)
    While Eof(0) = 0
      Line = Trim(ReadString(0))
      Pos = FindString(Line, "=", 1)
      If Pos > 1
        Key = LCase(Trim(Left(Line, Pos - 1)))
        Value = ValF(Trim(Mid(Line, Pos + 1)))

        Select Key
          Case "tower_damage_scale"
            ConfigTowerDamageScale = Value
          Case "tower_range_scale"
            ConfigTowerRangeScale = Value
          Case "enemy_health_scale"
            ConfigEnemyHealthScale = Value
          Case "enemy_speed_scale"
            ConfigEnemySpeedScale = Value
          Case "burn_scale"
            ConfigBurnScale = Value
        EndSelect
      EndIf
    Wend
    CloseFile(0)
  Else
    SaveBalanceConfig()
  EndIf
EndProcedure

Procedure LoadProgression()
  Protected SaveFile.s = AppPath + "..\\progress.cfg"
  Protected Line.s
  Protected Pos.i
  Protected Key.s
  Protected Value.i

  HighestWaveReached = 0
  HighestLevelCleared = 0
  TotalVictories = 0

  If ReadFile(1, SaveFile)
    While Eof(1) = 0
      Line = Trim(ReadString(1))
      Pos = FindString(Line, "=", 1)
      If Pos > 1
        Key = LCase(Trim(Left(Line, Pos - 1)))
        Value = Val(Trim(Mid(Line, Pos + 1)))

        Select Key
          Case "highest_wave"
            HighestWaveReached = Value
          Case "highest_level"
            HighestLevelCleared = Value
          Case "victories"
            TotalVictories = Value
        EndSelect
      EndIf
    Wend
    CloseFile(1)
  Else
    SaveProgression()
  EndIf
EndProcedure

Procedure SaveProgression()
  Protected SaveFile.s = AppPath + "..\\progress.cfg"

  If CreateFile(1, SaveFile)
    WriteStringN(1, "highest_wave=" + Str(HighestWaveReached))
    WriteStringN(1, "highest_level=" + Str(HighestLevelCleared))
    WriteStringN(1, "victories=" + Str(TotalVictories))
    CloseFile(1)
  EndIf
EndProcedure

Procedure SaveBalanceConfig()
  Protected ConfigFile.s = AppPath + "..\\balance.cfg"

  If CreateFile(0, ConfigFile)
    WriteStringN(0, "tower_damage_scale=" + StrF(ConfigTowerDamageScale, 2))
    WriteStringN(0, "tower_range_scale=" + StrF(ConfigTowerRangeScale, 2))
    WriteStringN(0, "enemy_health_scale=" + StrF(ConfigEnemyHealthScale, 2))
    WriteStringN(0, "enemy_speed_scale=" + StrF(ConfigEnemySpeedScale, 2))
    WriteStringN(0, "burn_scale=" + StrF(ConfigBurnScale, 2))
    CloseFile(0)
  EndIf
EndProcedure

Procedure.s TargetModeName(TargetMode.i)
  Select TargetMode
    Case #TargetMode_First
      ProcedureReturn "First"
    Case #TargetMode_Nearest
      ProcedureReturn "Nearest"
    Case #TargetMode_Strongest
      ProcedureReturn "Strongest"
  EndSelect

  ProcedureReturn "Unknown"
EndProcedure

Procedure.s ChallengeModeName(Mode.i)
  Select Mode
    Case #Challenge_Standard
      ProcedureReturn "Standard"
    Case #Challenge_Frugal
      ProcedureReturn "Frugal"
    Case #Challenge_Blitz
      ProcedureReturn "Blitz"
    Case #Challenge_IronCore
      ProcedureReturn "Iron Core"
  EndSelect

  ProcedureReturn "Standard"
EndProcedure

Procedure ApplyChallengeMode(Mode.i)
  ChallengeMode = Mode
  ChallengeStartGold = 180
  ChallengeCoreLives = 20
  ChallengeEnemyHealthScale = 1.0
  ChallengeEnemySpeedScale = 1.0
  ChallengeWaveDelayScale = 1.0

  Select ChallengeMode
    Case #Challenge_Frugal
      ChallengeStartGold = 140
      ChallengeCoreLives = 18
    Case #Challenge_Blitz
      ChallengeEnemySpeedScale = 1.18
      ChallengeWaveDelayScale = 0.82
    Case #Challenge_IronCore
      ChallengeCoreLives = 12
      ChallengeEnemyHealthScale = 1.12
  EndSelect
EndProcedure

Procedure.i PlannedBossType(CurrentWave.i)
  If CurrentWave >= 10 And WaveRemainder(CurrentWave + CurrentLevel, 2) = 0
    ProcedureReturn #EnemyType_Overseer
  EndIf

  ProcedureReturn #EnemyType_Boss
EndProcedure

Procedure.s LevelName(Level.i)
  Select Level
    Case 1
      ProcedureReturn "Foundry Bend"
    Case 2
      ProcedureReturn "Cross Current"
    Case 3
      ProcedureReturn "Granite Spiral"
    Case 4
      ProcedureReturn "Red Mesa"
    Case 5
      ProcedureReturn "Split Exchange"
    Case 6
      ProcedureReturn "Iron Ladder"
  EndSelect

  ProcedureReturn "Unknown Arena"
EndProcedure

Procedure.s LevelDescription(Level.i)
  Select Level
    Case 1
      ProcedureReturn "Balanced lanes with room for all-rounder builds."
    Case 2
      ProcedureReturn "A broken river route with tighter anti-air pressure."
    Case 3
      ProcedureReturn "A long spiral approach built for endurance and bosses."
    Case 4
      ProcedureReturn "A dry outer bend with long firing lines and exposed corners."
    Case 5
      ProcedureReturn "Split turns and hard pivots reward flexible coverage."
    Case 6
      ProcedureReturn "A steep step-lane that keeps pressure close to the core."
  EndSelect

  ProcedureReturn "Hold the line."
EndProcedure

Procedure SetStatus(Text.s, Duration.f)
  MessageText = Text
  If MessageLogText = ""
    MessageLogText = Text
  Else
    MessageLogText + #LF$ + Text
  EndIf
  MessageTimer = Duration
EndProcedure

Procedure BuildPath()
  Protected GX.i
  Protected GZ.i
  Select CurrentLevel
    Case 1
      BasePathPointCount = 8
      BasePathGX(0) = 0 : BasePathGZ(0) = 3
      BasePathGX(1) = 2 : BasePathGZ(1) = 3
      BasePathGX(2) = 2 : BasePathGZ(2) = 1
      BasePathGX(3) = 5 : BasePathGZ(3) = 1
      BasePathGX(4) = 5 : BasePathGZ(4) = 5
      BasePathGX(5) = 8 : BasePathGZ(5) = 5
      BasePathGX(6) = 8 : BasePathGZ(6) = 2
      BasePathGX(7) = 11 : BasePathGZ(7) = 2

    Case 2
      BasePathPointCount = 9
      BasePathGX(0) = 0 : BasePathGZ(0) = 5
      BasePathGX(1) = 3 : BasePathGZ(1) = 5
      BasePathGX(2) = 3 : BasePathGZ(2) = 2
      BasePathGX(3) = 6 : BasePathGZ(3) = 2
      BasePathGX(4) = 6 : BasePathGZ(4) = 6
      BasePathGX(5) = 9 : BasePathGZ(5) = 6
      BasePathGX(6) = 9 : BasePathGZ(6) = 1
      BasePathGX(7) = 11 : BasePathGZ(7) = 1
      BasePathGX(8) = 11 : BasePathGZ(8) = 4

    Case 3
      BasePathPointCount = 10
      BasePathGX(0) = 0 : BasePathGZ(0) = 1
      BasePathGX(1) = 4 : BasePathGZ(1) = 1
      BasePathGX(2) = 4 : BasePathGZ(2) = 6
      BasePathGX(3) = 1 : BasePathGZ(3) = 6
      BasePathGX(4) = 1 : BasePathGZ(4) = 4
      BasePathGX(5) = 7 : BasePathGZ(5) = 4
      BasePathGX(6) = 7 : BasePathGZ(6) = 0
      BasePathGX(7) = 10 : BasePathGZ(7) = 0
      BasePathGX(8) = 10 : BasePathGZ(8) = 7
      BasePathGX(9) = 11 : BasePathGZ(9) = 7

    Case 4
      BasePathPointCount = 8
      BasePathGX(0) = 0 : BasePathGZ(0) = 6
      BasePathGX(1) = 2 : BasePathGZ(1) = 6
      BasePathGX(2) = 2 : BasePathGZ(2) = 2
      BasePathGX(3) = 6 : BasePathGZ(3) = 2
      BasePathGX(4) = 6 : BasePathGZ(4) = 7
      BasePathGX(5) = 9 : BasePathGZ(5) = 7
      BasePathGX(6) = 9 : BasePathGZ(6) = 3
      BasePathGX(7) = 11 : BasePathGZ(7) = 3

    Case 5
      BasePathPointCount = 10
      BasePathGX(0) = 0 : BasePathGZ(0) = 4
      BasePathGX(1) = 3 : BasePathGZ(1) = 4
      BasePathGX(2) = 3 : BasePathGZ(2) = 0
      BasePathGX(3) = 5 : BasePathGZ(3) = 0
      BasePathGX(4) = 5 : BasePathGZ(4) = 5
      BasePathGX(5) = 8 : BasePathGZ(5) = 5
      BasePathGX(6) = 8 : BasePathGZ(6) = 1
      BasePathGX(7) = 10 : BasePathGZ(7) = 1
      BasePathGX(8) = 10 : BasePathGZ(8) = 6
      BasePathGX(9) = 11 : BasePathGZ(9) = 6

    Case 6
      BasePathPointCount = 9
      BasePathGX(0) = 0 : BasePathGZ(0) = 2
      BasePathGX(1) = 2 : BasePathGZ(1) = 2
      BasePathGX(2) = 2 : BasePathGZ(2) = 7
      BasePathGX(3) = 5 : BasePathGZ(3) = 7
      BasePathGX(4) = 5 : BasePathGZ(4) = 3
      BasePathGX(5) = 7 : BasePathGZ(5) = 3
      BasePathGX(6) = 7 : BasePathGZ(6) = 6
      BasePathGX(7) = 10 : BasePathGZ(7) = 6
      BasePathGX(8) = 11 : BasePathGZ(8) = 6
  EndSelect

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      BasePathMask(GX, GZ) = #False
    Next
  Next

  For GX = 0 To BasePathPointCount - 2
    MarkPathSegment(BasePathGX(GX), BasePathGZ(GX), BasePathGX(GX + 1), BasePathGZ(GX + 1))
  Next

  RecalculatePath(#False, -1, -1)
EndProcedure

Procedure FreeBoardVisuals()
  Protected GX.i
  Protected GZ.i
  Protected I.i

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      If Grid(GX, GZ)\entity
        FreeEntity(Grid(GX, GZ)\entity)
        Grid(GX, GZ)\entity = 0
      EndIf
      If Grid(GX, GZ)\decoEntity
        FreeEntity(Grid(GX, GZ)\decoEntity)
        Grid(GX, GZ)\decoEntity = 0
      EndIf
      Grid(GX, GZ)\kind = #Cell_Empty
      Grid(GX, GZ)\towerID = 0
    Next
  Next

  If HoverEntity
    FreeEntity(HoverEntity)
    HoverEntity = 0
  EndIf

  For I = 0 To #RangeSegmentCount - 1
    If RangeSegments(I)
      FreeEntity(RangeSegments(I))
      RangeSegments(I) = 0
    EndIf
  Next

  If CoreEntity
    FreeEntity(CoreEntity)
    CoreEntity = 0
  EndIf

  For I = 0 To #AmbientCount - 1
    If AmbientEntity(I)
      FreeEntity(AmbientEntity(I))
      AmbientEntity(I) = 0
    EndIf
  Next
EndProcedure

Procedure RebuildBoard()
  FreeBoardVisuals()
  BuildPath()
  CreateBoard()
  SetupAmbientScene()
EndProcedure

Procedure SetupAmbientScene()
  Protected I.i

  For I = 0 To #AmbientCount - 1
    AmbientBaseX(I) = -12.0 + I * 2.4
    AmbientBaseZ(I) = -8.5 + WaveRemainder(I * 3 + CurrentLevel, 7) * 2.1
    AmbientPhase(I) = I * 0.6 + CurrentLevel * 0.4

    If WaveRemainder(I + CurrentLevel, 2) = 0
      AmbientEntity(I) = CreateEntity(#PB_Any, MeshID(MeshSphere), MaterialID(MatAmbientA), AmbientBaseX(I), 0.15, AmbientBaseZ(I))
      ScaleEntity(AmbientEntity(I), 0.12, 0.12, 0.12, #PB_Absolute)
    Else
      AmbientEntity(I) = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatAmbientB), AmbientBaseX(I), 0.12, AmbientBaseZ(I))
      ScaleEntity(AmbientEntity(I), 0.10, 0.10, 0.10, #PB_Absolute)
    EndIf
  Next
EndProcedure

Procedure MarkPathSegment(X1.i, Z1.i, X2.i, Z2.i)
  Protected StepValue.i
  Protected Cursor.i

  If X1 = X2
    If Z2 >= Z1
      StepValue = 1
    Else
      StepValue = -1
    EndIf

    Cursor = Z1
    Repeat
      BasePathMask(X1, Cursor) = #True
      If Cursor = Z2
        Break
      EndIf
      Cursor + StepValue
    ForEver
  Else
    If X2 >= X1
      StepValue = 1
    Else
      StepValue = -1
    EndIf

    Cursor = X1
    Repeat
      BasePathMask(Cursor, Z1) = #True
      If Cursor = X2
        Break
      EndIf
      Cursor + StepValue
    ForEver
  EndIf
EndProcedure

Procedure.i IsRouteEndpoint(GX.i, GZ.i)
  If BasePathPointCount <= 0
    ProcedureReturn #False
  EndIf

  If (GX = BasePathGX(0) And GZ = BasePathGZ(0)) Or (GX = BasePathGX(BasePathPointCount - 1) And GZ = BasePathGZ(BasePathPointCount - 1))
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i CellCanHostTower(GX.i, GZ.i, TowerType.i)
  If GX < 0 Or GX >= #GridWidth Or GZ < 0 Or GZ >= #GridHeight
    ProcedureReturn #False
  EndIf

  If Grid(GX, GZ)\towerID <> 0
    ProcedureReturn #False
  EndIf

  If TowerType = #TowerType_Block
    If (Grid(GX, GZ)\kind <> #Cell_Path And BasePathMask(GX, GZ) = #False) Or IsRouteEndpoint(GX, GZ)
      ProcedureReturn #False
    EndIf
  Else
    If Grid(GX, GZ)\kind = #Cell_Path
      ProcedureReturn #False
    EndIf
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i CanPlaceBlockAt(GX.i, GZ.i)
  If CellCanHostTower(GX, GZ, #TowerType_Block) = #False
    ProcedureReturn #False
  EndIf

  If RecalculatePath(#False, GX, GZ, #True) = #False
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure CreateFloorDecoration(GX.i, GZ.i, X.f, Z.f)
  If CurrentLevel = 1 And GX = 9 And (GZ = 0 Or GZ = 7)
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatDecoStone), X, 0.32, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.42, 0.60, 0.42, #PB_Absolute)
  ElseIf CurrentLevel = 2 And GZ = 0 And (GX = 1 Or GX = 5 Or GX = 10)
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCone), MaterialID(MatDecoMarker), X, 0.36, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.34, 0.78, 0.34, #PB_Absolute)
  ElseIf CurrentLevel = 3 And GX = 11 And (GZ = 1 Or GZ = 5)
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatDecoStone), X, 0.28, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.55, 0.55, 0.55, #PB_Absolute)
  ElseIf CurrentLevel = 4 And GX = 4 And (GZ = 0 Or GZ = 7)
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCone), MaterialID(MatDecoMarker), X, 0.34, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.36, 0.82, 0.36, #PB_Absolute)
  ElseIf CurrentLevel = 5 And (GX = 1 Or GX = 6 Or GX = 9) And GZ = 7
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCylinder), MaterialID(MatDecoStone), X, 0.30, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.36, 0.54, 0.36, #PB_Absolute)
  ElseIf CurrentLevel = 6 And GX = 10 And (GZ = 0 Or GZ = 2)
    Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatDecoMarker), X, 0.22, Z)
    ScaleEntity(Grid(GX, GZ)\decoEntity, 0.44, 0.44, 0.44, #PB_Absolute)
  EndIf
EndProcedure

Procedure RefreshBoardRouteVisuals()
  Protected GX.i
  Protected GZ.i
  Protected X.f
  Protected Z.f

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      X = WorldXFromGrid(GX)
      Z = WorldZFromGrid(GZ)

      If IsPathCell(GX, GZ)
        Grid(GX, GZ)\kind = #Cell_Path
        SetEntityMaterial(Grid(GX, GZ)\entity, MaterialID(MatPath))
        ScaleEntity(Grid(GX, GZ)\entity, #CellSize * 0.88, 0.14, #CellSize * 0.88, #PB_Absolute)
        MoveEntity(Grid(GX, GZ)\entity, X, -0.04, Z, #PB_Absolute)

        If Grid(GX, GZ)\decoEntity = 0
          Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatFlash), X, 0.04, Z)
        Else
          SetEntityMaterial(Grid(GX, GZ)\decoEntity, MaterialID(MatFlash))
          MoveEntity(Grid(GX, GZ)\decoEntity, X, 0.04, Z, #PB_Absolute)
        EndIf
        ScaleEntity(Grid(GX, GZ)\decoEntity, #CellSize * 0.56, 0.03, #CellSize * 0.56, #PB_Absolute)
      Else
        Grid(GX, GZ)\kind = #Cell_Empty
        SetEntityMaterial(Grid(GX, GZ)\entity, MaterialID(MatFloor))
        ScaleEntity(Grid(GX, GZ)\entity, #CellSize * 0.96, 0.08, #CellSize * 0.96, #PB_Absolute)
        MoveEntity(Grid(GX, GZ)\entity, X, -0.04, Z, #PB_Absolute)

        If Grid(GX, GZ)\decoEntity
          FreeEntity(Grid(GX, GZ)\decoEntity)
          Grid(GX, GZ)\decoEntity = 0
        EndIf

        CreateFloorDecoration(GX, GZ, X, Z)
      EndIf
    Next
  Next

  If CoreEntity And PathPointCount > 0
    MoveEntity(CoreEntity, PathWX(PathPointCount - 1), 0.7, PathWZ(PathPointCount - 1), #PB_Absolute)
  EndIf
EndProcedure

Procedure.i RecalculatePath(ApplyToEnemies.i, ExtraBlockGX.i = -1, ExtraBlockGZ.i = -1, PreviewOnly.i = #False)
  Protected Dim Dist.i(#GridWidth - 1, #GridHeight - 1)
  Protected Dim PrevGX.i(#GridWidth - 1, #GridHeight - 1)
  Protected Dim PrevGZ.i(#GridWidth - 1, #GridHeight - 1)
  Protected Dim Closed.i(#GridWidth - 1, #GridHeight - 1)
  Protected GX.i
  Protected GZ.i
  Protected BestDist.i
  Protected CurrentGX.i
  Protected CurrentGZ.i
  Protected NextGX.i
  Protected NextGZ.i
  Protected NeighborX.i
  Protected NeighborZ.i
  Protected Weight.i
  Protected NewDist.i
  Protected Found.i
  Protected StartGX.i
  Protected StartGZ.i
  Protected EndGX.i
  Protected EndGZ.i
  Protected HasBlock.i
  Protected BlockedByTower.i
  Protected PathIndex.i
  Protected ReverseCount.i
  Protected TempGX.i
  Protected TempGZ.i
  Protected I.i
  Protected DX.f
  Protected DZ.f

  If BasePathPointCount <= 1
    ProcedureReturn #False
  EndIf

  StartGX = BasePathGX(0)
  StartGZ = BasePathGZ(0)
  EndGX = BasePathGX(BasePathPointCount - 1)
  EndGZ = BasePathGZ(BasePathPointCount - 1)

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      Dist(GX, GZ) = 1000000
      PrevGX(GX, GZ) = -1
      PrevGZ(GX, GZ) = -1
      Closed(GX, GZ) = #False
    Next
  Next

  Dist(StartGX, StartGZ) = 0

  Repeat
    BestDist = 1000000
    CurrentGX = -1
    CurrentGZ = -1

    For GX = 0 To #GridWidth - 1
      For GZ = 0 To #GridHeight - 1
        If Closed(GX, GZ) = #False And Dist(GX, GZ) < BestDist
          BestDist = Dist(GX, GZ)
          CurrentGX = GX
          CurrentGZ = GZ
        EndIf
      Next
    Next

    If CurrentGX = -1
      Break
    EndIf

    If CurrentGX = EndGX And CurrentGZ = EndGZ
      Found = #True
      Break
    EndIf

    Closed(CurrentGX, CurrentGZ) = #True

    For I = 0 To 3
      Select I
        Case 0
          NeighborX = CurrentGX - 1 : NeighborZ = CurrentGZ
        Case 1
          NeighborX = CurrentGX + 1 : NeighborZ = CurrentGZ
        Case 2
          NeighborX = CurrentGX : NeighborZ = CurrentGZ - 1
        Default
          NeighborX = CurrentGX : NeighborZ = CurrentGZ + 1
      EndSelect

      If NeighborX >= 0 And NeighborX < #GridWidth And NeighborZ >= 0 And NeighborZ < #GridHeight
        BlockedByTower = #False
        HasBlock = #False

        If NeighborX = ExtraBlockGX And NeighborZ = ExtraBlockGZ
          HasBlock = #True
        ElseIf Grid(NeighborX, NeighborZ)\towerID <> 0
          ForEach Towers()
            If Towers()\id = Grid(NeighborX, NeighborZ)\towerID
              BlockedByTower = #True
              If Towers()\type = #TowerType_Block
                HasBlock = #True
              EndIf
              Break
            EndIf
          Next
        EndIf

        If NeighborX = StartGX And NeighborZ = StartGZ
          BlockedByTower = #False
          HasBlock = #False
        ElseIf NeighborX = EndGX And NeighborZ = EndGZ
          BlockedByTower = #False
          HasBlock = #False
        EndIf

        If HasBlock = #False And BlockedByTower = #False
          If BasePathMask(NeighborX, NeighborZ)
            Weight = 10
          Else
            Weight = 25
          EndIf

          NewDist = Dist(CurrentGX, CurrentGZ) + Weight
          If NewDist < Dist(NeighborX, NeighborZ)
            Dist(NeighborX, NeighborZ) = NewDist
            PrevGX(NeighborX, NeighborZ) = CurrentGX
            PrevGZ(NeighborX, NeighborZ) = CurrentGZ
          EndIf
        EndIf
      EndIf
    Next
  ForEver

  If Found = #False
    ProcedureReturn #False
  EndIf

  CurrentGX = EndGX
  CurrentGZ = EndGZ
  ReverseCount = 0

  While CurrentGX <> -1 And CurrentGZ <> -1 And ReverseCount < #MaxPathPoints
    PathGX(ReverseCount) = CurrentGX
    PathGZ(ReverseCount) = CurrentGZ
    NextGX = PrevGX(CurrentGX, CurrentGZ)
    NextGZ = PrevGZ(CurrentGX, CurrentGZ)
    CurrentGX = NextGX
    CurrentGZ = NextGZ
    ReverseCount + 1
  Wend

  If ReverseCount < 2
    ProcedureReturn #False
  EndIf

  PathPointCount = ReverseCount
  For I = 0 To PathPointCount / 2 - 1
    TempGX = PathGX(I)
    TempGZ = PathGZ(I)
    PathGX(I) = PathGX(PathPointCount - 1 - I)
    PathGZ(I) = PathGZ(PathPointCount - 1 - I)
    PathGX(PathPointCount - 1 - I) = TempGX
    PathGZ(PathPointCount - 1 - I) = TempGZ
  Next

  For PathIndex = 0 To PathPointCount - 1
    PathWX(PathIndex) = WorldXFromGrid(PathGX(PathIndex))
    PathWZ(PathIndex) = WorldZFromGrid(PathGZ(PathIndex))
  Next

  For I = 0 To #MaxPathPoints - 2
    SegmentLength(I) = 0
    SegmentDirX(I) = 0
    SegmentDirZ(I) = 0
  Next

  For I = 0 To PathPointCount - 2
    DX = PathWX(I + 1) - PathWX(I)
    DZ = PathWZ(I + 1) - PathWZ(I)
    SegmentLength(I) = Sqr(DX * DX + DZ * DZ)
    If SegmentLength(I) > 0.001
      SegmentDirX(I) = DX / SegmentLength(I)
      SegmentDirZ(I) = DZ / SegmentLength(I)
    EndIf
  Next

  If PreviewOnly = #False And Grid(0, 0)\entity
    RefreshBoardRouteVisuals()
  EndIf

  If PreviewOnly = #False And ApplyToEnemies
    ReprojectEnemiesToPath()
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure CreateMaterials()
  MatFloor = CreateMaterial(#PB_Any, #Null, RGB(214, 224, 228))
  MatPath = CreateMaterial(#PB_Any, #Null, RGB(222, 84, 38))
  MatPulse = CreateMaterial(#PB_Any, #Null, RGB(38, 126, 98))
  MatCannon = CreateMaterial(#PB_Any, #Null, RGB(179, 108, 61))
  MatFrost = CreateMaterial(#PB_Any, #Null, RGB(69, 126, 156))
  MatBeam = CreateMaterial(#PB_Any, #Null, RGB(126, 83, 156))
  MatMortar = CreateMaterial(#PB_Any, #Null, RGB(128, 91, 58))
  MatSky = CreateMaterial(#PB_Any, #Null, RGB(64, 142, 168))
  MatBlock = CreateMaterial(#PB_Any, #Null, RGB(72, 72, 72))
  MatRunner = CreateMaterial(#PB_Any, #Null, RGB(37, 57, 77))
  MatRunnerAccent = CreateMaterial(#PB_Any, #Null, RGB(122, 186, 229))
  MatBrute = CreateMaterial(#PB_Any, #Null, RGB(121, 70, 56))
  MatBruteAccent = CreateMaterial(#PB_Any, #Null, RGB(224, 132, 96))
  MatSwarm = CreateMaterial(#PB_Any, #Null, RGB(76, 112, 68))
  MatSwarmAccent = CreateMaterial(#PB_Any, #Null, RGB(176, 223, 108))
  MatShield = CreateMaterial(#PB_Any, #Null, RGB(60, 94, 120))
  MatShieldAccent = CreateMaterial(#PB_Any, #Null, RGB(155, 222, 255))
  MatSplitter = CreateMaterial(#PB_Any, #Null, RGB(131, 85, 108))
  MatSplitterAccent = CreateMaterial(#PB_Any, #Null, RGB(245, 163, 207))
  MatGlider = CreateMaterial(#PB_Any, #Null, RGB(82, 102, 132))
  MatGliderAccent = CreateMaterial(#PB_Any, #Null, RGB(190, 235, 255))
  MatLeech = CreateMaterial(#PB_Any, #Null, RGB(94, 116, 72))
  MatLeechAccent = CreateMaterial(#PB_Any, #Null, RGB(215, 247, 136))
  MatSiege = CreateMaterial(#PB_Any, #Null, RGB(96, 72, 56))
  MatSiegeAccent = CreateMaterial(#PB_Any, #Null, RGB(255, 192, 120))
  MatOverseer = CreateMaterial(#PB_Any, #Null, RGB(78, 52, 110))
  MatOverseerAccent = CreateMaterial(#PB_Any, #Null, RGB(221, 180, 255))
  MatBoss = CreateMaterial(#PB_Any, #Null, RGB(110, 38, 38))
  MatBossAccent = CreateMaterial(#PB_Any, #Null, RGB(255, 166, 112))
  MatProjectilePulse = CreateMaterial(#PB_Any, #Null, RGB(133, 241, 190))
  MatProjectileCannon = CreateMaterial(#PB_Any, #Null, RGB(255, 205, 124))
  MatProjectileFrost = CreateMaterial(#PB_Any, #Null, RGB(180, 236, 255))
  MatProjectileBeam = CreateMaterial(#PB_Any, #Null, RGB(214, 169, 255))
  MatProjectileMortar = CreateMaterial(#PB_Any, #Null, RGB(236, 190, 145))
  MatProjectileSky = CreateMaterial(#PB_Any, #Null, RGB(182, 244, 255))
  MatHoverGood = CreateMaterial(#PB_Any, #Null, RGB(237, 202, 116))
  MatHoverBad = CreateMaterial(#PB_Any, #Null, RGB(194, 79, 74))
  MatHoverUpgrade = CreateMaterial(#PB_Any, #Null, RGB(92, 176, 88))
  MatHoverSell = CreateMaterial(#PB_Any, #Null, RGB(214, 98, 58))
  MatRange = CreateMaterial(#PB_Any, #Null, RGB(188, 168, 112))
  MatCore = CreateMaterial(#PB_Any, #Null, RGB(228, 71, 71))
  MatAccent = CreateMaterial(#PB_Any, #Null, RGB(35, 40, 47))
  MatFlash = CreateMaterial(#PB_Any, #Null, RGB(255, 244, 212))
  MatMuzzlePulse = CreateMaterial(#PB_Any, #Null, RGB(158, 244, 202))
  MatMuzzleCannon = CreateMaterial(#PB_Any, #Null, RGB(255, 214, 134))
  MatMuzzleFrost = CreateMaterial(#PB_Any, #Null, RGB(198, 240, 255))
  MatMuzzleBeam = CreateMaterial(#PB_Any, #Null, RGB(223, 190, 255))
  MatMuzzleMortar = CreateMaterial(#PB_Any, #Null, RGB(242, 205, 160))
  MatMuzzleSky = CreateMaterial(#PB_Any, #Null, RGB(214, 248, 255))
  MatHealthBack = CreateMaterial(#PB_Any, #Null, RGB(75, 81, 87))
  MatHealthFillHigh = CreateMaterial(#PB_Any, #Null, RGB(78, 232, 106))
  MatHealthFillMid = CreateMaterial(#PB_Any, #Null, RGB(255, 205, 74))
  MatHealthFillLow = CreateMaterial(#PB_Any, #Null, RGB(234, 82, 69))
  MatDecoStone = CreateMaterial(#PB_Any, #Null, RGB(160, 155, 144))
  MatDecoMarker = CreateMaterial(#PB_Any, #Null, RGB(197, 121, 73))
  MatAmbientA = CreateMaterial(#PB_Any, #Null, RGB(212, 223, 217))
  MatAmbientB = CreateMaterial(#PB_Any, #Null, RGB(227, 214, 191))
EndProcedure

Procedure CreateMeshes()
  MeshCube = CreateCube(#PB_Any, 1)
  MeshSphere = CreateSphere(#PB_Any, 0.5, 14, 14)
  MeshCylinder = CreateCylinder(#PB_Any, 0.5, 1.0, 16, 1, #True)
  MeshCone = CreateCone(#PB_Any, 0.5, 1.0, 12, 1)
EndProcedure

Procedure CreateBoard()
  Protected GX.i
  Protected GZ.i
  Protected I.i
  Protected X.f
  Protected Z.f

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      Grid(GX, GZ)\towerID = 0
      Grid(GX, GZ)\kind = #Cell_Empty
      Grid(GX, GZ)\decoEntity = 0
    Next
  Next

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      X = WorldXFromGrid(GX)
      Z = WorldZFromGrid(GZ)

      If IsPathCell(GX, GZ)
        Grid(GX, GZ)\kind = #Cell_Path
        Grid(GX, GZ)\entity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatPath), X, -0.04, Z, #Pick_Cell)
        ScaleEntity(Grid(GX, GZ)\entity, #CellSize * 0.88, 0.14, #CellSize * 0.88, #PB_Absolute)

        Grid(GX, GZ)\decoEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatFlash), X, 0.04, Z)
        ScaleEntity(Grid(GX, GZ)\decoEntity, #CellSize * 0.56, 0.03, #CellSize * 0.56, #PB_Absolute)

        If CurrentLevel = 2 And WaveRemainder(GX + GZ, 2) = 0
          ScaleEntity(Grid(GX, GZ)\decoEntity, #CellSize * 0.42, 0.03, #CellSize * 0.42, #PB_Absolute)
        EndIf
      Else
        Grid(GX, GZ)\entity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatFloor), X, -0.04, Z, #Pick_Cell)
        ScaleEntity(Grid(GX, GZ)\entity, #CellSize * 0.96, 0.08, #CellSize * 0.96, #PB_Absolute)
      EndIf

  If Grid(GX, GZ)\kind = #Cell_Empty
        CreateFloorDecoration(GX, GZ, X, Z)
      EndIf
    Next
  Next

  HoverEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatHoverGood), 0, -10, 0)
  ScaleEntity(HoverEntity, #CellSize * 0.88, 0.10, #CellSize * 0.88, #PB_Absolute)

  For I = 0 To #RangeSegmentCount - 1
    RangeSegments(I) = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatRange), 0, -10, 0)
    ScaleEntity(RangeSegments(I), 0.12, 0.02, 0.12, #PB_Absolute)
  Next

  CoreEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatCore), PathWX(PathPointCount - 1), 0.7, PathWZ(PathPointCount - 1))
  ScaleEntity(CoreEntity, 1.2, 1.4, 1.2, #PB_Absolute)
EndProcedure

Procedure CreateScene()
  If InitEngine3D() = 0 Or InitSprite() = 0 Or InitKeyboard() = 0 Or InitMouse() = 0
    MessageRequester("Initialization failed", "PureBasic could not start the Engine3D, Sprite, Keyboard, or Mouse libraries.")
    End
  EndIf

  If OpenWindow(#Window_Main, 0, 0, #WindowWidth, #WindowHeight, "Minimalist Tower Defense" + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered) = 0
    End
  EndIf

  If OpenWindowedScreen(WindowID(#Window_Main), 0, 0, #RenderWidth, #WindowHeight, 0, 0, 0) = 0
    MessageRequester("Screen failed", "OpenWindowedScreen() could not create the OGRE render surface.")
    End
  EndIf

  BuildPath()
  LoadBalanceConfig()
  LoadProgression()
  ApplyChallengeMode(#Challenge_Standard)
  CreateMaterials()
  CreateMeshes()

  CreateCamera(0, 0, 0, 100, 100)
  MoveCamera(0, 0, 29, 20, #PB_Absolute)
  CameraLookAt(0, 0, 0, 1.5)
  CameraBackColor(0, RGB(241, 238, 230))

  CreateLight(#PB_Any, RGB(255, 247, 225), 0, 35, 0, #PB_Light_Point)
  CreateLight(#PB_Any, RGB(190, 210, 225), -18, 18, -12, #PB_Light_Point)

  RebuildBoard()
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; Folding = -----
; EnableXP
; DPIAware
