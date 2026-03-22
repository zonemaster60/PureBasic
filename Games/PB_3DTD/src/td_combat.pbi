Procedure FreeEnemyVisuals(*Enemy.Enemy)
  If *Enemy\accentEntity
    FreeEntity(*Enemy\accentEntity)
    *Enemy\accentEntity = 0
  EndIf

  If *Enemy\hpBackEntity
    FreeEntity(*Enemy\hpBackEntity)
    *Enemy\hpBackEntity = 0
  EndIf

  If *Enemy\hpFillEntity
    FreeEntity(*Enemy\hpFillEntity)
    *Enemy\hpFillEntity = 0
  EndIf
EndProcedure

Procedure UpdateEnemyAccent(*Enemy.Enemy)
  If *Enemy\accentEntity = 0
    ProcedureReturn
  EndIf

  Select *Enemy\type
    Case #EnemyType_Runner
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.52, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Brute
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.78, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Swarm
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.26, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Shield
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.55, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Splitter
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.48, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Glider
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.02, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Leech
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.36, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Siege
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 0.88, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Overseer
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 1.00, *Enemy\z, #PB_Absolute)

    Case #EnemyType_Boss
      MoveEntity(*Enemy\accentEntity, *Enemy\x, *Enemy\y + 1.22, *Enemy\z, #PB_Absolute)
  EndSelect
EndProcedure

Procedure UpdateEnemyHealthBar(*Enemy.Enemy)
  Protected Ratio.f = *Enemy\hp / *Enemy\maxHP
  Protected Width.f

  If Ratio < 0
    Ratio = 0
  ElseIf Ratio > 1
    Ratio = 1
  EndIf

  If Ratio > 0.60
    SetEntityMaterial(*Enemy\hpFillEntity, MaterialID(MatHealthFillHigh))
  ElseIf Ratio > 0.30
    SetEntityMaterial(*Enemy\hpFillEntity, MaterialID(MatHealthFillMid))
  Else
    SetEntityMaterial(*Enemy\hpFillEntity, MaterialID(MatHealthFillLow))
  EndIf

  Width = 1.60 * Ratio
  MoveEntity(*Enemy\hpBackEntity, *Enemy\x, *Enemy\y + 1.18, *Enemy\z, #PB_Absolute)
  MoveEntity(*Enemy\hpFillEntity, *Enemy\x - (1.60 - Width) * 0.5, *Enemy\y + 1.20, *Enemy\z, #PB_Absolute)
  ScaleEntity(*Enemy\hpBackEntity, 1.72, 0.10, 0.22, #PB_Absolute)
  ScaleEntity(*Enemy\hpFillEntity, Width, 0.07, 0.14, #PB_Absolute)
EndProcedure

Procedure ReprojectEnemiesToPath()
  Protected BestDistance.f
  Protected BestSegment.i
  Protected BestProgress.f
  Protected SegmentDX.f
  Protected SegmentDZ.f
  Protected SegmentDot.f
  Protected SegmentX.f
  Protected SegmentZ.f
  Protected CurrentDistance.f
  Protected I.i

  If PathPointCount < 2
    ProcedureReturn
  EndIf

  ForEach Enemies()
    BestDistance = 1000000.0
    BestSegment = 0
    BestProgress = 0

    For I = 0 To PathPointCount - 2
      SegmentDX = PathWX(I + 1) - PathWX(I)
      SegmentDZ = PathWZ(I + 1) - PathWZ(I)

      If SegmentLength(I) > 0.001
        SegmentDot = ((Enemies()\x - PathWX(I)) * SegmentDX + (Enemies()\z - PathWZ(I)) * SegmentDZ) / (SegmentLength(I) * SegmentLength(I))
        If SegmentDot < 0
          SegmentDot = 0
        ElseIf SegmentDot > 1
          SegmentDot = 1
        EndIf

        SegmentX = PathWX(I) + SegmentDX * SegmentDot
        SegmentZ = PathWZ(I) + SegmentDZ * SegmentDot
        CurrentDistance = Sqr((Enemies()\x - SegmentX) * (Enemies()\x - SegmentX) + (Enemies()\z - SegmentZ) * (Enemies()\z - SegmentZ))

        If CurrentDistance < BestDistance
          BestDistance = CurrentDistance
          BestSegment = I
          BestProgress = SegmentLength(I) * SegmentDot
        EndIf
      EndIf
    Next

    Enemies()\segment = BestSegment
    Enemies()\progress = BestProgress
    Enemies()\x = PathWX(BestSegment) + SegmentDirX(BestSegment) * BestProgress
    Enemies()\z = PathWZ(BestSegment) + SegmentDirZ(BestSegment) * BestProgress

    If Enemies()\flyer
      Enemies()\y = 1.45 + Sin(ElapsedMilliseconds() / 220.0 + Enemies()\flightPhase) * 0.22
    EndIf

    MoveEntity(Enemies()\entity, Enemies()\x, Enemies()\y, Enemies()\z, #PB_Absolute)
    UpdateEnemyAccent(@Enemies())
    UpdateEnemyHealthBar(@Enemies())
  Next
EndProcedure

Procedure UpdateEffects(DT.f)
  ForEach Towers()
    If Towers()\muzzleTimer > 0
      Towers()\muzzleTimer - DT
      If Towers()\muzzleTimer <= 0
        Towers()\muzzleTimer = 0
        MoveEntity(Towers()\muzzleEntity, 0, -10, 0, #PB_Absolute)
        Select Towers()\type
          Case #TowerType_Pulse
            ScaleEntity(Towers()\muzzleEntity, 0.26, 0.26, 0.26, #PB_Absolute)
          Case #TowerType_Cannon
            ScaleEntity(Towers()\muzzleEntity, 0.24, 0.24, 0.24, #PB_Absolute)
          Case #TowerType_Frost
            ScaleEntity(Towers()\muzzleEntity, 0.22, 0.22, 0.22, #PB_Absolute)
          Case #TowerType_Beam
            ScaleEntity(Towers()\muzzleEntity, 0.18, 0.18, 0.18, #PB_Absolute)
          Case #TowerType_Mortar
            ScaleEntity(Towers()\muzzleEntity, 0.26, 0.26, 0.26, #PB_Absolute)
          Case #TowerType_Sky
            ScaleEntity(Towers()\muzzleEntity, 0.20, 0.20, 0.20, #PB_Absolute)
        EndSelect
      Else
        MoveEntity(Towers()\muzzleEntity, WorldXFromGrid(Towers()\gx), 1.35 + Towers()\muzzleTimer * 0.5, WorldZFromGrid(Towers()\gz), #PB_Absolute)
      EndIf
    EndIf
  Next

  Protected I.i
  Protected Pulse.f
  Protected Y.f

  For I = 0 To #AmbientCount - 1
    If AmbientEntity(I)
      Pulse = 0.5 + 0.5 * Sin(ElapsedMilliseconds() / 400.0 + AmbientPhase(I))
      Y = 0.10 + Pulse * 0.18
      MoveEntity(AmbientEntity(I), AmbientBaseX(I), Y, AmbientBaseZ(I), #PB_Absolute)
    EndIf
  Next

  ForEach Enemies()
    If Enemies()\flashTimer > 0
      Enemies()\flashTimer - DT
      If Enemies()\flashTimer <= 0
        Enemies()\flashTimer = 0

        Select Enemies()\type
          Case #EnemyType_Runner
            SetEntityMaterial(Enemies()\entity, MaterialID(MatRunner))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatRunnerAccent))
          Case #EnemyType_Brute
            SetEntityMaterial(Enemies()\entity, MaterialID(MatBrute))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatBruteAccent))
          Case #EnemyType_Swarm
            SetEntityMaterial(Enemies()\entity, MaterialID(MatSwarm))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatSwarmAccent))
          Case #EnemyType_Shield
            SetEntityMaterial(Enemies()\entity, MaterialID(MatShield))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatShieldAccent))
          Case #EnemyType_Splitter
            SetEntityMaterial(Enemies()\entity, MaterialID(MatSplitter))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatSplitterAccent))
          Case #EnemyType_Glider
            SetEntityMaterial(Enemies()\entity, MaterialID(MatGlider))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatGliderAccent))
          Case #EnemyType_Leech
            SetEntityMaterial(Enemies()\entity, MaterialID(MatLeech))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatLeechAccent))
          Case #EnemyType_Siege
            SetEntityMaterial(Enemies()\entity, MaterialID(MatSiege))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatSiegeAccent))
          Case #EnemyType_Overseer
            SetEntityMaterial(Enemies()\entity, MaterialID(MatOverseer))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatOverseerAccent))
          Case #EnemyType_Boss
            SetEntityMaterial(Enemies()\entity, MaterialID(MatBoss))
            SetEntityMaterial(Enemies()\accentEntity, MaterialID(MatBossAccent))
        EndSelect
      EndIf
    EndIf
  Next
EndProcedure

Procedure.i PlannedEnemyType(CurrentWave.i, SpawnIndex.i, SpawnCount.i)
  Select CurrentLevel
    Case 2
      If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
        ProcedureReturn PlannedBossType(CurrentWave)
      EndIf

      If CurrentWave >= 4 And WaveRemainder(SpawnIndex, 4) = 1
        ProcedureReturn #EnemyType_Glider
      EndIf

      If CurrentWave >= 5 And WaveRemainder(SpawnIndex, 6) = 3
        ProcedureReturn #EnemyType_Shield
      EndIf

      If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 8) = 6
        ProcedureReturn #EnemyType_Leech
      EndIf

      If CurrentWave >= 3 And WaveRemainder(SpawnIndex, 5) = 0
        ProcedureReturn #EnemyType_Swarm
      EndIf

      If CurrentWave >= 6 And WaveRemainder(SpawnIndex, 7) = 5
        ProcedureReturn #EnemyType_Brute
      EndIf

      ProcedureReturn #EnemyType_Runner

    Case 3
      If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
        ProcedureReturn PlannedBossType(CurrentWave)
      EndIf

      If CurrentWave >= 4 And WaveRemainder(SpawnIndex, 5) = 2
        ProcedureReturn #EnemyType_Brute
      EndIf

      If CurrentWave >= 5 And WaveRemainder(SpawnIndex, 6) = 4
        ProcedureReturn #EnemyType_Splitter
      EndIf

      If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 7) = 1
        ProcedureReturn #EnemyType_Shield
      EndIf

      If CurrentWave >= 8 And WaveRemainder(SpawnIndex, 8) = 3
        ProcedureReturn #EnemyType_Glider
      EndIf

      If CurrentWave >= 9 And WaveRemainder(SpawnIndex, 9) = 5
        ProcedureReturn #EnemyType_Siege
      EndIf

      If CurrentWave >= 2 And WaveRemainder(SpawnIndex, 4) = 1
        ProcedureReturn #EnemyType_Swarm
      EndIf

      ProcedureReturn #EnemyType_Runner

    Case 4
      If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
        ProcedureReturn PlannedBossType(CurrentWave)
      EndIf

      If CurrentWave >= 3 And WaveRemainder(SpawnIndex, 4) = 1
        ProcedureReturn #EnemyType_Brute
      EndIf

      If CurrentWave >= 5 And WaveRemainder(SpawnIndex, 5) = 2
        ProcedureReturn #EnemyType_Splitter
      EndIf

      If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 6) = 4
        ProcedureReturn #EnemyType_Glider
      EndIf

      If CurrentWave >= 8 And WaveRemainder(SpawnIndex, 7) = 0
        ProcedureReturn #EnemyType_Siege
      EndIf

      ProcedureReturn #EnemyType_Runner

    Case 5
      If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
        ProcedureReturn PlannedBossType(CurrentWave)
      EndIf

      If CurrentWave >= 3 And WaveRemainder(SpawnIndex, 4) = 0
        ProcedureReturn #EnemyType_Swarm
      EndIf

      If CurrentWave >= 5 And WaveRemainder(SpawnIndex, 5) = 3
        ProcedureReturn #EnemyType_Shield
      EndIf

      If CurrentWave >= 6 And WaveRemainder(SpawnIndex, 6) = 1
        ProcedureReturn #EnemyType_Splitter
      EndIf

      If CurrentWave >= 8 And WaveRemainder(SpawnIndex, 7) = 5
        ProcedureReturn #EnemyType_Glider
      EndIf

      If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 8) = 2
        ProcedureReturn #EnemyType_Leech
      EndIf

      ProcedureReturn #EnemyType_Runner

    Case 6
      If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
        ProcedureReturn PlannedBossType(CurrentWave)
      EndIf

      If CurrentWave >= 2 And WaveRemainder(SpawnIndex, 4) = 2
        ProcedureReturn #EnemyType_Brute
      EndIf

      If CurrentWave >= 4 And WaveRemainder(SpawnIndex, 5) = 0
        ProcedureReturn #EnemyType_Shield
      EndIf

      If CurrentWave >= 6 And WaveRemainder(SpawnIndex, 6) = 3
        ProcedureReturn #EnemyType_Glider
      EndIf

      If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 7) = 6
        ProcedureReturn #EnemyType_Splitter
      EndIf

      If CurrentWave >= 9 And WaveRemainder(SpawnIndex, 9) = 4
        ProcedureReturn #EnemyType_Siege
      EndIf

      ProcedureReturn #EnemyType_Runner
  EndSelect

  If WaveRemainder(CurrentWave, 4) = 0 And SpawnIndex = SpawnCount - 1
    ProcedureReturn PlannedBossType(CurrentWave)
  EndIf

  If CurrentWave >= 6 And WaveRemainder(SpawnIndex, 5) = 2
    ProcedureReturn #EnemyType_Brute
  EndIf

  If CurrentWave >= 8 And WaveRemainder(SpawnIndex, 6) = 3
    ProcedureReturn #EnemyType_Shield
  EndIf

  If CurrentWave >= 7 And WaveRemainder(SpawnIndex, 6) = 1
    ProcedureReturn #EnemyType_Glider
  EndIf

  If CurrentWave >= 6 And WaveRemainder(SpawnIndex, 8) = 6
    ProcedureReturn #EnemyType_Leech
  EndIf

  If CurrentWave >= 3 And WaveRemainder(SpawnIndex, 4) = 1
    ProcedureReturn #EnemyType_Swarm
  EndIf

  If CurrentWave >= 5 And WaveRemainder(SpawnIndex, 7) = 5
    ProcedureReturn #EnemyType_Splitter
  EndIf

  If CurrentWave >= 9 And WaveRemainder(SpawnIndex, 9) = 7
    ProcedureReturn #EnemyType_Siege
  EndIf

  If CurrentWave >= 2 And WaveRemainder(SpawnIndex, 5) = 4
    ProcedureReturn #EnemyType_Brute
  EndIf

  ProcedureReturn #EnemyType_Runner
EndProcedure

Procedure SpawnEnemy(EnemyType.i, CurrentWave.i)
  Protected SizeX.f = 0.7
  Protected SizeY.f = 0.7
  Protected SizeZ.f = 0.7
  Protected Material.i = MatRunner
  Protected Mesh.i = MeshSphere
  Protected AccentMaterial.i = MatRunnerAccent
  Protected AccentMesh.i = MeshCube

  AddElement(Enemies())
  Enemies()\id = NextEnemyID
  NextEnemyID + 1
  Enemies()\type = EnemyType
  Enemies()\segment = 0
  Enemies()\progress = 0
  Enemies()\x = PathWX(0)
  Enemies()\z = PathWZ(0)
  Enemies()\slowFactor = 1.0
  Enemies()\slowTimer = 0
  Enemies()\damageToCore = 1

  Select EnemyType
    Case #EnemyType_Runner
      Enemies()\hp = 34 + CurrentWave * 9
      Enemies()\speed = 3.0 + CurrentWave * 0.12
      Enemies()\reward = 10 + CurrentWave
      Enemies()\y = 0.58
      Material = MatRunner
      Mesh = MeshSphere
      AccentMaterial = MatRunnerAccent
      AccentMesh = MeshCone
      SizeX = 0.72 : SizeY = 0.72 : SizeZ = 0.72

    Case #EnemyType_Brute
      Enemies()\hp = 100 + CurrentWave * 22
      Enemies()\speed = 2.0 + CurrentWave * 0.07
      Enemies()\reward = 24 + CurrentWave * 2
      Enemies()\y = 0.74
      Material = MatBrute
      Mesh = MeshCube
      AccentMaterial = MatBruteAccent
      AccentMesh = MeshCylinder
      SizeX = 1.08 : SizeY = 1.08 : SizeZ = 1.08

    Case #EnemyType_Swarm
      Enemies()\hp = 20 + CurrentWave * 5
      Enemies()\speed = 3.9 + CurrentWave * 0.14
      Enemies()\reward = 8 + CurrentWave
      Enemies()\y = 0.40
      Material = MatSwarm
      Mesh = MeshSphere
      AccentMaterial = MatSwarmAccent
      AccentMesh = MeshCone
      SizeX = 0.52 : SizeY = 0.52 : SizeZ = 0.52

    Case #EnemyType_Shield
      Enemies()\hp = 60 + CurrentWave * 12
      Enemies()\shield = 32 + CurrentWave * 7
      Enemies()\speed = 2.6 + CurrentWave * 0.08
      Enemies()\reward = 18 + CurrentWave
      Enemies()\y = 0.62
      Material = MatShield
      Mesh = MeshCylinder
      AccentMaterial = MatShieldAccent
      AccentMesh = MeshSphere
      SizeX = 0.76 : SizeY = 0.88 : SizeZ = 0.76

    Case #EnemyType_Splitter
      Enemies()\hp = 52 + CurrentWave * 10
      Enemies()\speed = 3.1 + CurrentWave * 0.10
      Enemies()\reward = 16 + CurrentWave
      Enemies()\y = 0.52
      Material = MatSplitter
      Mesh = MeshCube
      AccentMaterial = MatSplitterAccent
      AccentMesh = MeshCone
      SizeX = 0.68 : SizeY = 0.68 : SizeZ = 0.68

    Case #EnemyType_Glider
      Enemies()\hp = 42 + CurrentWave * 9
      Enemies()\speed = 3.6 + CurrentWave * 0.12
      Enemies()\reward = 14 + CurrentWave
      Enemies()\y = 1.55
      Enemies()\damageToCore = 2
      Enemies()\flyer = #True
      Enemies()\flightPhase = NextEnemyID * 0.35
      Material = MatGlider
      Mesh = MeshCone
      AccentMaterial = MatGliderAccent
      AccentMesh = MeshSphere
      SizeX = 0.62 : SizeY = 0.92 : SizeZ = 0.62

    Case #EnemyType_Leech
      Enemies()\hp = 54 + CurrentWave * 11
      Enemies()\speed = 2.8 + CurrentWave * 0.09
      Enemies()\reward = 17 + CurrentWave
      Enemies()\y = 0.48
      Enemies()\regenRate = 2.6 + CurrentWave * 0.15
      Enemies()\slowCap = 0.68
      Material = MatLeech
      Mesh = MeshSphere
      AccentMaterial = MatLeechAccent
      AccentMesh = MeshCylinder
      SizeX = 0.64 : SizeY = 0.64 : SizeZ = 0.64

    Case #EnemyType_Siege
      Enemies()\hp = 180 + CurrentWave * 28
      Enemies()\speed = 1.7 + CurrentWave * 0.05
      Enemies()\reward = 34 + CurrentWave * 2
      Enemies()\y = 0.84
      Enemies()\damageToCore = 3
      Enemies()\slowCap = 0.82
      Material = MatSiege
      Mesh = MeshCube
      AccentMaterial = MatSiegeAccent
      AccentMesh = MeshCylinder
      SizeX = 1.12 : SizeY = 1.12 : SizeZ = 1.12

    Case #EnemyType_Overseer
      Enemies()\hp = 280 + CurrentWave * 42
      Enemies()\speed = 1.9 + CurrentWave * 0.06
      Enemies()\reward = 105 + CurrentWave * 9
      Enemies()\y = 0.98
      Enemies()\damageToCore = 4
      Enemies()\shield = 60 + CurrentWave * 8
      Material = MatOverseer
      Mesh = MeshSphere
      AccentMaterial = MatOverseerAccent
      AccentMesh = MeshCylinder
      SizeX = 1.28 : SizeY = 1.28 : SizeZ = 1.28
      Enemies()\abilityCooldown = 4.0

    Case #EnemyType_Boss
      Enemies()\hp = 330 + CurrentWave * 55
      Enemies()\speed = 1.5 + CurrentWave * 0.05
      Enemies()\reward = 95 + CurrentWave * 8
      Enemies()\y = 1.08
      Enemies()\damageToCore = 4
      Material = MatBoss
      Mesh = MeshCylinder
      AccentMaterial = MatBossAccent
      AccentMesh = MeshCube
      SizeX = 1.42 : SizeY = 2.10 : SizeZ = 1.42
      Enemies()\abilityCooldown = 4.6
  EndSelect

  Enemies()\hp * ConfigEnemyHealthScale * ChallengeEnemyHealthScale
  Enemies()\speed * ConfigEnemySpeedScale * ChallengeEnemySpeedScale
  Enemies()\maxHP = Enemies()\hp
  Enemies()\entity = CreateEntity(#PB_Any, MeshID(Mesh), MaterialID(Material), Enemies()\x, Enemies()\y, Enemies()\z)
  ScaleEntity(Enemies()\entity, SizeX, SizeY, SizeZ, #PB_Absolute)
  Enemies()\accentEntity = CreateEntity(#PB_Any, MeshID(AccentMesh), MaterialID(AccentMaterial), Enemies()\x, Enemies()\y, Enemies()\z)

  Select EnemyType
    Case #EnemyType_Runner
      ScaleEntity(Enemies()\accentEntity, 0.34, 0.56, 0.34, #PB_Absolute)
      RotateEntity(Enemies()\accentEntity, 180, 0, 0, #PB_Absolute)
    Case #EnemyType_Brute
      ScaleEntity(Enemies()\accentEntity, 0.52, 0.22, 0.52, #PB_Absolute)
    Case #EnemyType_Swarm
      ScaleEntity(Enemies()\accentEntity, 0.24, 0.34, 0.24, #PB_Absolute)
      RotateEntity(Enemies()\accentEntity, 180, 0, 0, #PB_Absolute)
    Case #EnemyType_Shield
      ScaleEntity(Enemies()\accentEntity, 0.42, 0.24, 0.42, #PB_Absolute)
    Case #EnemyType_Splitter
      ScaleEntity(Enemies()\accentEntity, 0.30, 0.44, 0.30, #PB_Absolute)
      RotateEntity(Enemies()\accentEntity, 180, 0, 0, #PB_Absolute)
    Case #EnemyType_Glider
      ScaleEntity(Enemies()\accentEntity, 0.26, 0.26, 0.52, #PB_Absolute)
    Case #EnemyType_Leech
      ScaleEntity(Enemies()\accentEntity, 0.22, 0.34, 0.22, #PB_Absolute)
    Case #EnemyType_Siege
      ScaleEntity(Enemies()\accentEntity, 0.52, 0.18, 0.52, #PB_Absolute)
    Case #EnemyType_Overseer
      ScaleEntity(Enemies()\accentEntity, 0.44, 0.20, 0.44, #PB_Absolute)
    Case #EnemyType_Boss
      ScaleEntity(Enemies()\accentEntity, 0.48, 0.18, 0.48, #PB_Absolute)
  EndSelect

  Enemies()\hpBackEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatHealthBack), Enemies()\x, Enemies()\y + 1.18, Enemies()\z)
  Enemies()\hpFillEntity = CreateEntity(#PB_Any, MeshID(MeshCube), MaterialID(MatHealthFillHigh), Enemies()\x, Enemies()\y + 1.20, Enemies()\z)
  UpdateEnemyAccent(@Enemies())
  UpdateEnemyHealthBar(@Enemies())
  EnemyAliveCount + 1
EndProcedure

Procedure TriggerBossAbility(*Enemy.Enemy)
  Protected SpawnProgress.f

  If *Enemy\type <> #EnemyType_Boss And *Enemy\type <> #EnemyType_Overseer
    ProcedureReturn
  EndIf

  If *Enemy\type = #EnemyType_Overseer
    Select *Enemy\bossPhase
      Case 0
        ForEach Enemies()
          If Enemies()\type <> #EnemyType_Overseer And Enemies()\type <> #EnemyType_Boss
            Enemies()\shield + 18 + Wave * 2
          EndIf
        Next
        SetStatus("Overseer lattice: escorts gain fresh shielding.", 1.2)

      Case 1
        SpawnEnemy(#EnemyType_Leech, Wave)
        SpawnEnemy(#EnemyType_Glider, Wave)
        SetStatus("Overseer split: escort drones deployed.", 1.2)

      Case 2
        *Enemy\speed * 1.35
        *Enemy\abilityState = 2
        *Enemy\abilityTimer = 2.0
        SetStatus("Overseer drive: command core surges forward.", 1.2)
    EndSelect

    *Enemy\bossPhase + 1
    If *Enemy\bossPhase > 2
      *Enemy\bossPhase = 0
    EndIf

    *Enemy\abilityCooldown = 4.2
    ProcedureReturn
  EndIf

  Select *Enemy\bossPhase
    Case 0
      *Enemy\speed * 1.55
      *Enemy\abilityState = 1
      *Enemy\abilityTimer = 1.8
      SetStatus("Boss surge: the front line accelerates.", 1.2)

    Case 1
      *Enemy\shield + 80 + Wave * 10
      *Enemy\flashTimer = 0.12
      SetEntityMaterial(*Enemy\entity, MaterialID(MatFlash))
      SetStatus("Boss pulse: fresh shielding wraps the corebreaker.", 1.2)

    Case 2
      SpawnProgress = *Enemy\progress + 0.15
      SpawnSplitSwarm(*Enemy\segment, SpawnProgress)
      SpawnProgress = *Enemy\progress + 0.45
      SpawnSplitSwarm(*Enemy\segment, SpawnProgress)
      SetStatus("Boss rupture: support swarm released.", 1.2)
  EndSelect

  *Enemy\bossPhase + 1
  If *Enemy\bossPhase > 2
    *Enemy\bossPhase = 0
  EndIf

  *Enemy\abilityCooldown = 4.4
EndProcedure

Procedure StartWave(EarlyBonus.i)
  If GameState <> #GameState_Playing
    ProcedureReturn
  EndIf

  If WaveActive Or Wave >= #MaxWaves
    ProcedureReturn
  EndIf

  Wave + 1
  WaveActive = #True
  WaveSpawned = 0
  WaveToSpawn = 9 + Wave * 2
  WaveSpawnTimer = 0.5
  WaveCountdown = 0

  If EarlyBonus
    Gold + 15
  EndIf

  If Wave > HighestWaveReached
    HighestWaveReached = Wave
    SaveProgression()
  EndIf

  PlayWaveSound()
  SetStatus("Wave " + Str(Wave) + " begins.", 1.2)
  RefreshSidebar()
EndProcedure

Procedure UpdateSpawner(DT.f)
  Protected Type.i

  If WaveActive = 0 Or GameState <> #GameState_Playing
    ProcedureReturn
  EndIf

  WaveSpawnTimer - DT

  If WaveSpawned < WaveToSpawn And WaveSpawnTimer <= 0
    Type = PlannedEnemyType(Wave, WaveSpawned, WaveToSpawn)
    SpawnEnemy(Type, Wave)
    WaveSpawned + 1
    WaveSpawnTimer = (0.70 - Wave * 0.02) * ChallengeWaveDelayScale
    If WaveSpawnTimer < 0.18
      WaveSpawnTimer = 0.18
    EndIf
  EndIf
EndProcedure

Procedure UpdateEnemies(DT.f)
  Protected DistanceLeft.f
  Protected Remaining.f
  Protected EffectiveSpeed.f

  ForEach Enemies()
    If Enemies()\burnTimer > 0
      Enemies()\burnTimer - DT
      Enemies()\burnTick - DT

      If Enemies()\burnTick <= 0
        Enemies()\burnTick = 0.35
        Enemies()\hp - Enemies()\burnDamage
        If Enemies()\hp <= 0
          Gold + Enemies()\reward
          PlayHitSound()
          FreeEnemyVisuals(@Enemies())
          FreeEntity(Enemies()\entity)
          DeleteElement(Enemies())
          EnemyAliveCount - 1
          Continue
        EndIf
      EndIf

      If Enemies()\burnTimer <= 0
        Enemies()\burnTimer = 0
      EndIf
    EndIf

    If Enemies()\slowTimer > 0
      Enemies()\slowTimer - DT
      If Enemies()\slowTimer <= 0
        Enemies()\slowTimer = 0
        Enemies()\slowFactor = 1.0
      EndIf
    EndIf

    If Enemies()\regenRate > 0 And Enemies()\hp > 0 And Enemies()\hp < Enemies()\maxHP
      Enemies()\hp + Enemies()\regenRate * DT
      If Enemies()\hp > Enemies()\maxHP
        Enemies()\hp = Enemies()\maxHP
      EndIf
    EndIf

    If Enemies()\type = #EnemyType_Boss Or Enemies()\type = #EnemyType_Overseer
      If Enemies()\abilityCooldown > 0
        Enemies()\abilityCooldown - DT
        If Enemies()\abilityCooldown <= 0
          TriggerBossAbility(@Enemies())
        EndIf
      EndIf

      If Enemies()\abilityState = 1
        Enemies()\abilityTimer - DT
        If Enemies()\abilityTimer <= 0
          Enemies()\abilityTimer = 0
          Enemies()\abilityState = 0
          Enemies()\speed / 1.55
        EndIf
      ElseIf Enemies()\abilityState = 2
        Enemies()\abilityTimer - DT
        If Enemies()\abilityTimer <= 0
          Enemies()\abilityTimer = 0
          Enemies()\abilityState = 0
          Enemies()\speed / 1.35
        EndIf
      EndIf
    EndIf

    EffectiveSpeed = Enemies()\speed * Enemies()\slowFactor
    DistanceLeft = EffectiveSpeed * DT

    While DistanceLeft > 0 And Enemies()\segment < PathPointCount - 1
      Remaining = SegmentLength(Enemies()\segment) - Enemies()\progress

      If DistanceLeft < Remaining
        Enemies()\progress + DistanceLeft
        DistanceLeft = 0
      Else
        DistanceLeft - Remaining
        Enemies()\segment + 1
        Enemies()\progress = 0
      EndIf
    Wend

    If Enemies()\segment >= PathPointCount - 1
      CoreLives - Enemies()\damageToCore
      SetStatus(EnemyName(Enemies()\type) + " slipped through the maze.", 1.5)
      FreeEnemyVisuals(@Enemies())
      FreeEntity(Enemies()\entity)
      DeleteElement(Enemies())
      EnemyAliveCount - 1

      If CoreLives <= 0
        CoreLives = 0
        GameState = #GameState_Defeat
        WaveActive = #False
        SetStatus("The core collapsed. The run is over.", 4.0)
        ShowEndOverlay()
      EndIf
    Else
      Enemies()\x = PathWX(Enemies()\segment) + SegmentDirX(Enemies()\segment) * Enemies()\progress
      Enemies()\z = PathWZ(Enemies()\segment) + SegmentDirZ(Enemies()\segment) * Enemies()\progress
      If Enemies()\flyer
        Enemies()\y = 1.45 + Sin(ElapsedMilliseconds() / 220.0 + Enemies()\flightPhase) * 0.22
      EndIf
      MoveEntity(Enemies()\entity, Enemies()\x, Enemies()\y, Enemies()\z, #PB_Absolute)
      UpdateEnemyAccent(@Enemies())
      UpdateEnemyHealthBar(@Enemies())
    EndIf
  Next
EndProcedure

Procedure SpawnProjectile(*Tower.Tower, TargetID.i)
  Protected Material.i
  Protected Mesh.i
  Protected Scale.f
  Protected StartX.f = WorldXFromGrid(*Tower\gx)
  Protected StartZ.f = WorldZFromGrid(*Tower\gz)
  Protected StartY.f = 1.35

  Select *Tower\type
    Case #TowerType_Pulse
      Material = MatProjectilePulse
      Mesh = MeshSphere
      Scale = 0.34
    Case #TowerType_Cannon
      Material = MatProjectileCannon
      Mesh = MeshCube
      Scale = 0.42
    Case #TowerType_Frost
      Material = MatProjectileFrost
      Mesh = MeshSphere
      Scale = 0.30
    Case #TowerType_Beam
      Material = MatProjectileBeam
      Mesh = MeshSphere
      Scale = 0.20
    Case #TowerType_Mortar
      Material = MatProjectileMortar
      Mesh = MeshSphere
      Scale = 0.46
    Case #TowerType_Sky
      Material = MatProjectileSky
      Mesh = MeshSphere
      Scale = 0.24
  EndSelect

  AddElement(Projectiles())
  Projectiles()\id = NextProjectileID
  NextProjectileID + 1
  Projectiles()\type = *Tower\type
  Projectiles()\targetID = TargetID
  Projectiles()\x = StartX
  Projectiles()\y = StartY
  Projectiles()\z = StartZ
  Projectiles()\speed = *Tower\projectileSpeed
  Projectiles()\damage = *Tower\damage
  Projectiles()\splash = *Tower\splash
  Projectiles()\slowPower = *Tower\slowPower
  Projectiles()\slowTime = *Tower\slowTime
  Projectiles()\entity = CreateEntity(#PB_Any, MeshID(Mesh), MaterialID(Material), StartX, StartY, StartZ)
  ScaleEntity(Projectiles()\entity, Scale, Scale, Scale, #PB_Absolute)
EndProcedure

Procedure ApplyImpact(TargetID.i, X.f, Z.f, Damage.f, Splash.f, SlowPower.f, SlowTime.f)
  Protected CurrentDamage.f
  Protected DX.f
  Protected DZ.f
  Protected Distance.f
  Protected SpawnProgressA.f
  Protected SpawnProgressB.f

  If Splash > 0.05
    ForEach Enemies()
      DX = Enemies()\x - X
      DZ = Enemies()\z - Z
      Distance = Sqr(DX * DX + DZ * DZ)

      If Distance <= Splash
        CurrentDamage = Damage * (1.0 - Distance / (Splash + 0.2))
        If CurrentDamage < Damage * 0.35
          CurrentDamage = Damage * 0.35
        EndIf

        If Enemies()\shield > 0
          Enemies()\shield - CurrentDamage
          If Enemies()\shield < 0
            Enemies()\hp + Enemies()\shield
            Enemies()\shield = 0
          EndIf
        Else
          Enemies()\hp - CurrentDamage
        EndIf

        If SlowPower > 0 And SlowTime > 0
          If Enemies()\slowCap > 0 And SlowPower < Enemies()\slowCap
            SlowPower = Enemies()\slowCap
          EndIf
          If Enemies()\slowTimer <= 0 Or Enemies()\slowFactor > SlowPower
            Enemies()\slowFactor = SlowPower
          EndIf
          Enemies()\slowTimer = SlowTime
        EndIf

        If Enemies()\hp <= 0
          Gold + Enemies()\reward
          PlayHitSound()

          If Enemies()\type = #EnemyType_Splitter And Enemies()\maxHP > 40
            SpawnProgressA = Enemies()\progress + 0.15
            SpawnProgressB = Enemies()\progress + 0.45
            SpawnSplitSwarm(Enemies()\segment, SpawnProgressA)
            SpawnSplitSwarm(Enemies()\segment, SpawnProgressB)
          EndIf

          FreeEnemyVisuals(@Enemies())
          FreeEntity(Enemies()\entity)
          DeleteElement(Enemies())
          EnemyAliveCount - 1
        Else
          If Projectiles()\type = #TowerType_Pulse
            Enemies()\burnTimer = 1.8
            Enemies()\burnTick = 0.35
            Enemies()\burnDamage = 4 + Wave * 0.2
          EndIf
          Enemies()\flashTimer = 0.10
          SetEntityMaterial(Enemies()\entity, MaterialID(MatFlash))
          UpdateEnemyHealthBar(@Enemies())
        EndIf
      EndIf
    Next
  Else
    ForEach Enemies()
      If Enemies()\id = TargetID
        If Enemies()\shield > 0
          Enemies()\shield - Damage
          If Enemies()\shield < 0
            Enemies()\hp + Enemies()\shield
            Enemies()\shield = 0
          EndIf
        Else
          Enemies()\hp - Damage
        EndIf

        If SlowPower > 0 And SlowTime > 0
          If Enemies()\slowCap > 0 And SlowPower < Enemies()\slowCap
            SlowPower = Enemies()\slowCap
          EndIf
          If Enemies()\slowTimer <= 0 Or Enemies()\slowFactor > SlowPower
            Enemies()\slowFactor = SlowPower
          EndIf
          Enemies()\slowTimer = SlowTime
        EndIf

        If Enemies()\hp <= 0
          Gold + Enemies()\reward
          PlayHitSound()

          If Enemies()\type = #EnemyType_Splitter And Enemies()\maxHP > 40
            SpawnProgressA = Enemies()\progress + 0.15
            SpawnProgressB = Enemies()\progress + 0.45
            SpawnSplitSwarm(Enemies()\segment, SpawnProgressA)
            SpawnSplitSwarm(Enemies()\segment, SpawnProgressB)
          EndIf

          FreeEnemyVisuals(@Enemies())
          FreeEntity(Enemies()\entity)
          DeleteElement(Enemies())
          EnemyAliveCount - 1
        Else
          If Projectiles()\type = #TowerType_Pulse
            Enemies()\burnTimer = 1.8
            Enemies()\burnTick = 0.35
            Enemies()\burnDamage = 4 + Wave * 0.2
          EndIf
          Enemies()\flashTimer = 0.10
          SetEntityMaterial(Enemies()\entity, MaterialID(MatFlash))
          UpdateEnemyHealthBar(@Enemies())
        EndIf
        Break
      EndIf
    Next
  EndIf
EndProcedure

Procedure UpdateProjectiles(DT.f)
  Protected Found.i
  Protected TargetX.f
  Protected TargetY.f
  Protected TargetZ.f
  Protected DX.f
  Protected DY.f
  Protected DZ.f
  Protected Distance.f
  Protected TravelStep.f

  ForEach Projectiles()
    Found = #False

    ForEach Enemies()
      If Enemies()\id = Projectiles()\targetID
        Found = #True
        TargetX = Enemies()\x
        TargetY = Enemies()\y
        TargetZ = Enemies()\z
        Break
      EndIf
    Next

    If Found = 0
      FreeEntity(Projectiles()\entity)
      DeleteElement(Projectiles())
    Else
      DX = TargetX - Projectiles()\x
      DY = TargetY - Projectiles()\y
      DZ = TargetZ - Projectiles()\z
      Distance = Sqr(DX * DX + DY * DY + DZ * DZ)
      TravelStep = Projectiles()\speed * DT

      If Distance <= TravelStep Or Distance < 0.30
        ApplyImpact(Projectiles()\targetID, TargetX, TargetZ, Projectiles()\damage, Projectiles()\splash, Projectiles()\slowPower, Projectiles()\slowTime)
        FreeEntity(Projectiles()\entity)
        DeleteElement(Projectiles())
      Else
        Projectiles()\x + DX / Distance * TravelStep
        Projectiles()\y + DY / Distance * TravelStep
        Projectiles()\z + DZ / Distance * TravelStep
        MoveEntity(Projectiles()\entity, Projectiles()\x, Projectiles()\y, Projectiles()\z, #PB_Absolute)
      EndIf
    EndIf
  Next
EndProcedure

Procedure SpawnSplitSwarm(SourceSegment.i, SourceProgress.f)
  SpawnEnemy(#EnemyType_Swarm, Wave)
  Enemies()\segment = SourceSegment
  Enemies()\progress = SourceProgress
  Enemies()\x = PathWX(Enemies()\segment) + SegmentDirX(Enemies()\segment) * Enemies()\progress
  Enemies()\z = PathWZ(Enemies()\segment) + SegmentDirZ(Enemies()\segment) * Enemies()\progress
  MoveEntity(Enemies()\entity, Enemies()\x, Enemies()\y, Enemies()\z, #PB_Absolute)
  UpdateEnemyAccent(@Enemies())
  UpdateEnemyHealthBar(@Enemies())
EndProcedure

Procedure.f EnemyTargetMetric(*Enemy.Enemy, TowerX.f, TowerZ.f, TargetMode.i)
  Protected DX.f = *Enemy\x - TowerX
  Protected DZ.f = *Enemy\z - TowerZ
  Protected Distance.f = Sqr(DX * DX + DZ * DZ)

  Select TargetMode
    Case #TargetMode_Nearest
      ProcedureReturn 10000.0 - Distance
    Case #TargetMode_Strongest
      ProcedureReturn *Enemy\hp + *Enemy\shield
    Default
      ProcedureReturn *Enemy\segment * 1000 + *Enemy\progress
  EndSelect
EndProcedure

Procedure.i TowerCanTargetEnemy(*Tower.Tower, *Enemy.Enemy)
  If *Enemy\flyer
    Select *Tower\type
      Case #TowerType_Pulse, #TowerType_Beam, #TowerType_Sky
        ProcedureReturn #True
      Default
        ProcedureReturn #False
    EndSelect
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure UpdateTowers(DT.f)
  Protected TowerX.f
  Protected TowerZ.f
  Protected DX.f
  Protected DZ.f
  Protected Distance.f
  Protected BestMetric.f
  Protected Metric.f
  Protected TargetID.i
  Protected Shot.i

  ForEach Towers()
    If Towers()\type = #TowerType_Block
      Continue
    EndIf

    Select Towers()\type
      Case #TowerType_Pulse, #TowerType_Frost
        RotateEntity(Towers()\headEntity, 0, 28 * DT, 0, #PB_Relative)
      Case #TowerType_Cannon
        RotateEntity(Towers()\headEntity, 0, 20 * DT, 0, #PB_Relative)
      Case #TowerType_Beam
        RotateEntity(Towers()\headEntity, 0, 34 * DT, 0, #PB_Relative)
      Case #TowerType_Mortar
        RotateEntity(Towers()\headEntity, 0, 14 * DT, 0, #PB_Relative)
      Case #TowerType_Sky
        RotateEntity(Towers()\headEntity, 0, 42 * DT, 0, #PB_Relative)
    EndSelect
    Towers()\cooldown - DT

    If Towers()\cooldown <= 0
      BestMetric = -1
      TargetID = 0
      TowerX = WorldXFromGrid(Towers()\gx)
      TowerZ = WorldZFromGrid(Towers()\gz)

      ForEach Enemies()
        DX = Enemies()\x - TowerX
        DZ = Enemies()\z - TowerZ
        Distance = Sqr(DX * DX + DZ * DZ)

        If Distance <= Towers()\range And TowerCanTargetEnemy(@Towers(), @Enemies())
          Metric = EnemyTargetMetric(@Enemies(), TowerX, TowerZ, Towers()\targetMode)
          If Metric > BestMetric
            BestMetric = Metric
            TargetID = Enemies()\id
          EndIf
        EndIf
      Next

      If TargetID <> 0
        For Shot = 1 To Towers()\shotCount
          SpawnProjectile(@Towers(), TargetID)
        Next

        If Towers()\type = #TowerType_Pulse And Towers()\level >= 3
          ApplyImpact(TargetID, TowerX, TowerZ, Towers()\damage * 0.25, 1.7, 0, 0)
        EndIf

        If Towers()\type = #TowerType_Mortar And Towers()\level >= 3
          ForEach Enemies()
            If Enemies()\id = TargetID
              ApplyImpact(TargetID, Enemies()\x, Enemies()\z, Towers()\damage * 0.22, 1.3, 0.80, 0.8)
              Break
            EndIf
          Next
        EndIf

        If Towers()\type = #TowerType_Frost And Towers()\level >= 3
          ForEach Enemies()
            If Enemies()\id = TargetID
              ApplyImpact(TargetID, Enemies()\x, Enemies()\z, Towers()\damage * 0.20, 1.1, 0.55, 1.4)
              Break
            EndIf
          Next
        EndIf

        PlayTowerFireSound(Towers()\type)
        Towers()\muzzleTimer = 0.12
        MoveEntity(Towers()\muzzleEntity, TowerX, 1.35, TowerZ, #PB_Absolute)

        If Towers()\type = #TowerType_Beam
          ForEach Enemies()
            If Enemies()\id = TargetID
              Towers()\muzzleTimer = 0.06
              MoveEntity(Towers()\muzzleEntity, (TowerX + Enemies()\x) * 0.5, 0.95, (TowerZ + Enemies()\z) * 0.5, #PB_Absolute)
              ScaleEntity(Towers()\muzzleEntity, 0.12, 0.12, Distance * 0.5, #PB_Absolute)
              Break
            EndIf
          Next
        EndIf

        Towers()\cooldown = Towers()\fireDelay
      EndIf
    EndIf
  Next
EndProcedure

Procedure CheckWaveFinished()
  If GameState <> #GameState_Playing
    ProcedureReturn
  EndIf

  If WaveActive And WaveSpawned >= WaveToSpawn And EnemyAliveCount = 0
    WaveActive = #False

    If Wave >= #MaxWaves
      GameState = #GameState_Victory
      SetStatus("All waves cleared. The minimalist citadel holds.", 5.0)
      ShowEndOverlay()
    Else
      WaveCountdown = 11.0 * ChallengeWaveDelayScale
      Gold + 25 + Wave * 4
      SetStatus("Wave " + Str(Wave) + " cleared. Fortify the grid.", 2.0)
    EndIf
  EndIf
EndProcedure
