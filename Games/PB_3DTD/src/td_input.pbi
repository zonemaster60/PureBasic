Procedure UpdateHover()
  Protected Picked.i
  Protected GX.i
  Protected GZ.i
  Protected TowerID.i
  Protected MousePX.i
  Protected MousePY.i
  Protected BestDistance.f
  Protected CurrentDistance.f
  Protected CellCenterX.f
  Protected CellCenterY.f
  Protected Pulse.f
  Protected HoverSize.f
  Protected HoverHeight.f
  Protected HoverMaterial.i
  Protected FoundCell.i

  HoverGX = -1
  HoverGZ = -1

  MousePX = WindowMouseX(#Window_Main)
  MousePY = WindowMouseY(#Window_Main)

  If MousePX >= 0 And MousePX < #RenderWidth And MousePY >= 0 And MousePY < #WindowHeight
    Picked = MousePick(0, MousePX, MousePY, #Pick_Cell)

    If Picked <> -1
      BestDistance = 1000000.0
      FoundCell = #False

      ForEach Towers()
        If Towers()\baseEntity = Picked Or Towers()\headEntity = Picked Or Towers()\muzzleEntity = Picked
          HoverGX = Towers()\gx
          HoverGZ = Towers()\gz
          FoundCell = #True
          Break
        EndIf
      Next

      If FoundCell = #False
        For GX = 0 To #GridWidth - 1
          For GZ = 0 To #GridHeight - 1
            If Grid(GX, GZ)\entity = Picked Or Grid(GX, GZ)\decoEntity = Picked
              CellCenterX = (GX + 0.5) * #RenderWidth / #GridWidth
              CellCenterY = (GZ + 0.5) * #WindowHeight / #GridHeight
              CurrentDistance = Sqr((MousePX - CellCenterX) * (MousePX - CellCenterX) + (MousePY - CellCenterY) * (MousePY - CellCenterY))

              If CurrentDistance < BestDistance
                BestDistance = CurrentDistance
                HoverGX = GX
                HoverGZ = GZ
              EndIf
            EndIf
          Next
        Next
      EndIf
    EndIf
  EndIf

  If HoverGX = -1
    MoveEntity(HoverEntity, 0, -10, 0, #PB_Absolute)
    If SelectedTowerID = 0
      HideRangeIndicators()
      RangePreviewActive = #False
    EndIf
  Else
    TowerID = Grid(HoverGX, HoverGZ)\towerID
    HoverMaterial = MatHoverGood

    If PendingGridAction = #GridAction_Upgrade
      If TowerID <> 0 And FindTower(TowerID)
        ForEach Towers()
          If Towers()\id = TowerID
            If Towers()\type <> #TowerType_Block And Towers()\level < 3
              HoverMaterial = MatHoverUpgrade
            Else
              HoverMaterial = MatHoverBad
            EndIf
            Break
          EndIf
        Next
      Else
        HoverMaterial = MatHoverBad
      EndIf
    ElseIf PendingGridAction = #GridAction_Sell
      If TowerID <> 0
        HoverMaterial = MatHoverSell
      Else
        HoverMaterial = MatHoverBad
      EndIf
    ElseIf TowerID <> 0
      HoverMaterial = MatHoverBad
    ElseIf CurrentBuildType = #TowerType_Block
      If CanPlaceBlockAt(HoverGX, HoverGZ)
        HoverMaterial = MatHoverGood
      Else
        HoverMaterial = MatHoverBad
      EndIf
    ElseIf Grid(HoverGX, HoverGZ)\kind = #Cell_Path
      HoverMaterial = MatHoverBad
    Else
      HoverMaterial = MatHoverGood
    EndIf

    SetEntityMaterial(HoverEntity, MaterialID(HoverMaterial))

    Pulse = 0.5 + 0.5 * Sin(ElapsedMilliseconds() / 180.0)
    HoverSize = #CellSize * (0.78 + Pulse * 0.10)
    HoverHeight = 0.08 + Pulse * 0.05
    ScaleEntity(HoverEntity, HoverSize, HoverHeight, HoverSize, #PB_Absolute)
    MoveEntity(HoverEntity, WorldXFromGrid(HoverGX), 0.05 + HoverHeight * 0.5, WorldZFromGrid(HoverGZ), #PB_Absolute)

    If SelectedTowerID = 0 And PendingGridAction = #GridAction_None And CurrentBuildType <> #TowerType_None And TowerID = 0 And CellCanHostTower(HoverGX, HoverGZ, CurrentBuildType)
      ShowRangeIndicators(WorldXFromGrid(HoverGX), WorldZFromGrid(HoverGZ), TowerPreviewRange(CurrentBuildType))
      RangePreviewActive = #True
    ElseIf SelectedTowerID = 0 And RangePreviewActive
      HideRangeIndicators()
      RangePreviewActive = #False
    EndIf
  EndIf
EndProcedure

Procedure HandleBoardClick()
  Protected TowerID.i

  If HoverGX = -1 Or HoverGZ = -1
    If PendingGridAction = #GridAction_None
      SelectTower(0)
    EndIf
    ProcedureReturn
  EndIf

  TowerID = Grid(HoverGX, HoverGZ)\towerID

  If PendingGridAction = #GridAction_Upgrade
    If TowerID <> 0
      If FindTower(TowerID)
        ForEach Towers()
          If Towers()\id = TowerID
            If Towers()\level < 3
              UpgradeTowerByID(TowerID)
              PendingGridAction = #GridAction_None
            Else
              SelectTower(TowerID)
              SetStatus("That tower is already maxed.", 1.2)
            EndIf
            Break
          EndIf
        Next
      EndIf
    Else
      SetStatus("Click a placed tower to upgrade it.", 1.2)
    EndIf
    RefreshSidebar()
    ProcedureReturn
  ElseIf PendingGridAction = #GridAction_Sell
    If TowerID <> 0
      SellTowerByID(TowerID)
      PendingGridAction = #GridAction_None
    Else
      SetStatus("Click a placed tower to sell it.", 1.2)
    EndIf
    RefreshSidebar()
    ProcedureReturn
  EndIf

  If TowerID <> 0
    CurrentBuildType = #TowerType_None
    UpdateBuildButtons()
    SelectTower(TowerID)
    ProcedureReturn
  EndIf

  If CurrentBuildType = #TowerType_None
    SelectTower(0)
    SetStatus("Pick a tower type, then click a free tile.", 1.4)
    ProcedureReturn
  EndIf

  If BuildTower(HoverGX, HoverGZ, CurrentBuildType)
    RefreshSidebar()
  EndIf
EndProcedure

Procedure ProcessInput()
  Protected Event.i
  Protected GadgetID.i
  Protected MousePX.i
  Protected MousePY.i
  Protected LeftPressed.i
  Protected RightPressed.i
  Protected OverlayWasActive.i = StartOverlayActive
  Protected GadgetHandled.i

  Repeat
    Event = WindowEvent()

    Select Event
      Case #PB_Event_CloseWindow
        QuitGame()

      Case #PB_Event_Gadget
        GadgetID = EventGadget()
        Select GadgetID
          Case #Gadget_LevelCycle, #Gadget_BuildPulse, #Gadget_BuildCannon, #Gadget_BuildFrost, #Gadget_BuildBeam, #Gadget_BuildMortar, #Gadget_BuildSky, #Gadget_BuildBlock, #Gadget_Upgrade, #Gadget_Sell, #Gadget_Wave, #Gadget_Speed, #Gadget_Pause, #Gadget_TargetMode, #Gadget_MenuStart, #Gadget_MenuContinue, #Gadget_MenuLevel, #Gadget_MenuRunMode, #Gadget_MenuChallenge, #Gadget_MenuQuit, #Gadget_DebugGold, #Gadget_DebugWave, #Gadget_DebugLife, #Gadget_DebugClear
            GadgetHandled = #True
            HandleGadget(GadgetID)
        EndSelect
    EndSelect
  Until Event = 0

  If GadgetHandled And OverlayWasActive <> StartOverlayActive
    LeftWasDown = Bool(GetAsyncKeyState_(#VK_LBUTTON) & $8000)
    RightWasDown = Bool(GetAsyncKeyState_(#VK_RBUTTON) & $8000)
    ProcedureReturn
  EndIf

  ExamineKeyboard()
  ExamineMouse()
  ReleaseMouse(#True)
  MousePX = WindowMouseX(#Window_Main)
  MousePY = WindowMouseY(#Window_Main)
  LeftPressed = Bool(GetAsyncKeyState_(#VK_LBUTTON) & $8000)
  RightPressed = Bool(GetAsyncKeyState_(#VK_RBUTTON) & $8000)

  If KeyboardPushed(#PB_Key_Escape)
    QuitGame()
  EndIf

  If KeyboardPushed(#PB_Key_F1)
    If KeyF1WasDown = 0
      SetDebugPanelVisible(Bool(DebugPanelVisible = 0))
      If DebugPanelVisible
        SetStatus("Debug panel opened.", 0.8)
      Else
        SetStatus("Debug panel hidden.", 0.8)
      EndIf
    EndIf
    KeyF1WasDown = #True
  Else
    KeyF1WasDown = #False
  EndIf

  If DebugPanelVisible
    If KeyboardPushed(#PB_Key_G)
      If KeyGWasDown = 0
        ApplyDebugAction(#Gadget_DebugGold)
      EndIf
      KeyGWasDown = #True
    Else
      KeyGWasDown = #False
    EndIf

    If KeyboardPushed(#PB_Key_N)
      If KeyNWasDown = 0
        ApplyDebugAction(#Gadget_DebugWave)
      EndIf
      KeyNWasDown = #True
    Else
      KeyNWasDown = #False
    EndIf

    If KeyboardPushed(#PB_Key_L)
      If KeyLWasDown = 0
        ApplyDebugAction(#Gadget_DebugLife)
      EndIf
      KeyLWasDown = #True
    Else
      KeyLWasDown = #False
    EndIf

    If KeyboardPushed(#PB_Key_K)
      If KeyKWasDown = 0
        ApplyDebugAction(#Gadget_DebugClear)
      EndIf
      KeyKWasDown = #True
    Else
      KeyKWasDown = #False
    EndIf
  Else
    KeyGWasDown = #False
    KeyNWasDown = #False
    KeyLWasDown = #False
    KeyKWasDown = #False
  EndIf

  If StartOverlayActive
    If KeyboardPushed(#PB_Key_Return) Or KeyboardPushed(#PB_Key_Space) Or (LeftPressed And LeftWasDown = 0 And MousePX >= 530 And MousePX < 660 And MousePY >= 620 And MousePY < 650)
      If KeyEnterWasDown = 0
        If GameState = #GameState_Playing
          StartGame()
        ElseIf GameState = #GameState_Victory
          If CampaignMode And CurrentLevel < #LevelCount
            SetLevel(CurrentLevel + 1)
          EndIf
          RestartGame()
        ElseIf GameState <> #GameState_Playing
          CloseOverlay()
        Else
          RestartGame()
        EndIf
      EndIf
      KeyEnterWasDown = #True
      If LeftPressed
        LeftWasDown = #True
      EndIf
    ElseIf KeyboardPushed(#PB_Key_Left) Or KeyboardPushed(#PB_Key_Right)
      If KeyEnterWasDown = 0 And GameState = #GameState_Playing And Wave = 0 And EnemyAliveCount = 0 And ListSize(Towers()) = 0
        If KeyboardPushed(#PB_Key_Left)
          SetLevel(CurrentLevel - 1)
        Else
          SetLevel(CurrentLevel + 1)
        EndIf
        RebuildBoard()
      EndIf
      KeyEnterWasDown = #True
    Else
      KeyEnterWasDown = #False
    EndIf

    ProcedureReturn
  EndIf

  If KeyboardPushed(#PB_Key_Return) Or KeyboardPushed(#PB_Key_PadEnter)
    If KeyPlaceWasDown = 0 And MousePX >= 0 And MousePX < #RenderWidth And MousePY >= 0 And MousePY < #WindowHeight
      HandleBoardClick()
    EndIf
    KeyPlaceWasDown = #True
  Else
    KeyPlaceWasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_1) Or KeyboardPushed(#PB_Key_Pad1)
    If Key1WasDown = 0
      CurrentBuildType = #TowerType_Pulse
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Pulse tower selected.", 0.9)
    EndIf
    Key1WasDown = #True
  Else
    Key1WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_2) Or KeyboardPushed(#PB_Key_Pad2)
    If Key2WasDown = 0
      CurrentBuildType = #TowerType_Cannon
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Cannon tower selected.", 0.9)
    EndIf
    Key2WasDown = #True
  Else
    Key2WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_3) Or KeyboardPushed(#PB_Key_Pad3)
    If Key3WasDown = 0
      CurrentBuildType = #TowerType_Frost
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Frost tower selected.", 0.9)
    EndIf
    Key3WasDown = #True
  Else
    Key3WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_4) Or KeyboardPushed(#PB_Key_Pad4)
    If Key4WasDown = 0
      CurrentBuildType = #TowerType_Beam
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Beam tower selected.", 0.9)
    EndIf
    Key4WasDown = #True
  Else
    Key4WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_5) Or KeyboardPushed(#PB_Key_Pad5)
    If Key5WasDown = 0
      CurrentBuildType = #TowerType_Mortar
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Mortar tower selected.", 0.9)
    EndIf
    Key5WasDown = #True
  Else
    Key5WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_6) Or KeyboardPushed(#PB_Key_Pad6)
    If Key6WasDown = 0
      CurrentBuildType = #TowerType_Sky
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Sky tower selected.", 0.9)
    EndIf
    Key6WasDown = #True
  Else
    Key6WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_7) Or KeyboardPushed(#PB_Key_Pad7)
    If Key7WasDown = 0
      CurrentBuildType = #TowerType_Block
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()
      SetStatus("Block selected.", 0.9)
    EndIf
    Key7WasDown = #True
  Else
    Key7WasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_Space)
    If KeySpaceWasDown = 0
      If WaveActive = 0 And GameState = #GameState_Playing And Wave < #MaxWaves
        StartWave(#True)
      EndIf
    EndIf
    KeySpaceWasDown = #True
  Else
    KeySpaceWasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_U)
    If KeyUWasDown = 0
      If AnyUpgradeableTower()
        PendingGridAction = #GridAction_Upgrade
        CurrentBuildType = #TowerType_None
        UpdateBuildButtons()
        SetStatus("Upgrade mode active. Click a placed tower.", 1.2)
        RefreshSidebar()
      Else
        SetStatus("No placed towers can be upgraded right now.", 1.2)
      EndIf
    EndIf
    KeyUWasDown = #True
  Else
    KeyUWasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_T)
    If KeyTWasDown = 0 And SelectedTowerID <> 0
      HandleGadget(#Gadget_TargetMode)
    EndIf
    KeyTWasDown = #True
  Else
    KeyTWasDown = #False
  EndIf

  If KeyboardPushed(#PB_Key_S)
    If KeySWasDown = 0
      If AnySellableTower()
        PendingGridAction = #GridAction_Sell
        CurrentBuildType = #TowerType_None
        UpdateBuildButtons()
        SetStatus("Sell mode active. Click a placed tower.", 1.2)
        RefreshSidebar()
      Else
        SetStatus("There is nothing to sell right now.", 1.2)
      EndIf
    EndIf
    KeySWasDown = #True
  Else
    KeySWasDown = #False
  EndIf

  KeyEnterWasDown = #False

  UpdateHover()

  If LeftPressed
    If LeftWasDown = 0 And MousePX >= 0 And MousePX < #RenderWidth
      HandleBoardClick()
    EndIf
    LeftWasDown = #True
  Else
    LeftWasDown = #False
  EndIf

  If RightPressed
    If RightWasDown = 0
      PendingGridAction = #GridAction_None
      CurrentBuildType = #TowerType_None
      UpdateBuildButtons()
      If HoverGX <> -1 And HoverGZ <> -1 And Grid(HoverGX, HoverGZ)\towerID <> 0
        SelectTower(Grid(HoverGX, HoverGZ)\towerID)
      Else
        SelectTower(0)
      EndIf
    EndIf
    RightWasDown = #True
  Else
    RightWasDown = #False
  EndIf
EndProcedure
