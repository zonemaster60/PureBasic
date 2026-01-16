;------------------------------------------------------------------------------
; Movement and enemies (extracted from pbzt.pb)
;------------------------------------------------------------------------------

; ToggleLeverDoorsAt
Procedure ToggleLeverDoorsAt(BoardIdx.i, LeverX.i, LeverY.i)
  ; Built-in lever mechanic: toggles adjacent 'd' doors to 'o' open and back.
  ; Only affects lever-operated doors, not key doors.
  ; This is separate from scripted levers/doors (which can use flags + #SET).
  Protected b.i = BoardIdx
  Protected x.i, y.i
  Protected idx.i
  Protected ch.a

  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf

  For y = LeverY - 1 To LeverY + 1
    For x = LeverX - 1 To LeverX + 1
      If x < 0 Or y < 0 Or x >= #MAP_W Or y >= #MAP_H
        Continue
      EndIf

      idx = x + y * #MAP_W
      ch = Boards(b)\Map[idx]

      If ch = Asc("d")
        Boards(b)\Map[idx] = Asc("o")
        Boards(b)\Color[idx] = Palette(Asc("o"))
      ElseIf ch = Asc("o")
        Boards(b)\Map[idx] = Asc("d")
        Boards(b)\Color[idx] = Palette(Asc("d"))
      EndIf
    Next
  Next
EndProcedure

; TryMovePlayer
Procedure.b TryMovePlayer(dx.i, dy.i)
  Protected nx.i = PlayerX + dx
  Protected ny.i = PlayerY + dy
  Protected ch.a
  Protected idx.i
  Protected objId.i
  Protected hint.s
  Protected destBoard.i
  Protected destX.i
  Protected destY.i

  If nx < 0 Or ny < 0 Or nx >= #MAP_W Or ny >= #MAP_H
    ProcedureReturn AttemptBoardEdgeExit(dx, dy)
  EndIf

  ; bump-to-exit: if walking into outer border wall and an exit is defined
  If (nx = 0 And dx < 0) Or (nx = #MAP_W - 1 And dx > 0) Or (ny = 0 And dy < 0) Or (ny = #MAP_H - 1 And dy > 0)
    If GetCell(nx, ny) = Asc("#")
      If AttemptBoardEdgeExit(dx, dy)
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf

  idx = nx + ny * #MAP_W
  objId = ObjOverlayId(idx)
  If objId <> 0 And ObjOverlaySolid(idx)
    ; Enemies are solid, but bumping them is an attack.
    If ObjOverlayChar(idx) = Asc("E")
      RemoveObjectById(objId)
      PlaySfx(#Sfx_Hurt)
      Score + 25

      ; Chance to drop HP pickup on enemy kill.
      If Random(99) < #ENEMY_DROP_HEALTH_PCT
        If GetCell(nx, ny) = Asc(".") Or GetCell(nx, ny) = Asc(" ")
          SetCell(nx, ny, Asc(Chr(#HEALTH_PICKUP_CHAR)))
        EndIf
      EndIf

      objId = 0
    ElseIf ObjOverlayChar(idx) = Asc("w")
      PlaySfx(#Sfx_Beep)
      TriggerObjectLabel(objId, "TOUCH")
      ProcedureReturn #False
    Else
      PlaySfx(#Sfx_Beep)
      TriggerObjectLabel(objId, "TOUCH")
      ProcedureReturn #False
    EndIf
  EndIf

  ch = GetCell(nx, ny)

  ; Key door
  If ch = Asc("D")
    If Keys > 0
      Keys - 1
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Door)
    Else
      SetStatus("Need a key (+) for the door.")
      ProcedureReturn #False
    EndIf

  ; Colored key doors (A/B/C/F need keys 1/2/3/4)
  ElseIf (ch >= Asc("A") And ch <= Asc("C")) Or ch = Asc("F")
    Protected neededKey.s
    neededKey = DoorColorToKeyChar(ch)
    If neededKey <> "" And GetColorKeyCount(neededKey) > 0
      AddColorKey(neededKey, -1)
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Door)
    Else
      SetStatus("Need a matching colored key (" + neededKey + ") for this door.")
      ProcedureReturn #False
    EndIf

  ; Lever-controlled door (closed)
  ElseIf ch = Asc("d")
    SetStatus("The door is locked by a lever (L).")
    ProcedureReturn #False

  ; Lever tile: toggle nearby lever-doors
  ElseIf ch = Asc("L")
    ToggleLeverDoorsAt(CurBoard(), nx, ny)
    PlaySfx(#Sfx_Beep)

  ElseIf CellIsSolidForPlayer(nx, ny)
    ; Attack enemy object / collect treasure by bumping
    If objId <> 0 And ObjOverlayChar(idx) = Asc("E")
      RemoveObjectById(objId)
      PlaySfx(#Sfx_Hurt)
      Score + 25

      ; Chance to drop HP pickup on enemy kill.
      If Random(99) < #ENEMY_DROP_HEALTH_PCT
        If GetCell(nx, ny) = Asc(".") Or GetCell(nx, ny) = Asc(" ")
          SetCell(nx, ny, Asc(Chr(#HEALTH_PICKUP_CHAR)))
        EndIf
      EndIf
    ElseIf ch = Asc("$")
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Treasure)
      Score + 10
    Else
      ProcedureReturn #False
    EndIf
  EndIf

  ch = GetCell(nx, ny)
  Select ch
    Case Asc("$")
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Treasure)
      Score + 10

    Case Asc("+")
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Key)
      Keys + 1

    Case Asc(Chr(#HEALTH_PICKUP_CHAR))
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Treasure)
      Health + 1
      SetStatus("+1 HP")

    Case Asc("1"), Asc("2"), Asc("3"), Asc("4")
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Key)
      AddColorKey(Chr(ch), 1)

    Case Asc("t")
      ; torch pickup: enables light radius in dark rooms
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Treasure)

      If TorchStepsLeft >= #TORCH_MAX_STEPS
        TorchStepsLeft = #TORCH_MAX_STEPS
        ScriptItems("TORCH") = 1
        SetStatus("Torch already full. (" + Str(#TORCH_MAX_STEPS) + " steps)")
      ElseIf TorchStepsLeft > 0
        TorchStepsLeft = #TORCH_MAX_STEPS
        ScriptItems("TORCH") = 1
        SetStatus("Refilled torch! (" + Str(#TORCH_MAX_STEPS) + " steps)")
      Else
        TorchStepsLeft = #TORCH_MAX_STEPS
        ScriptItems("TORCH") = 1
        SetStatus("Picked up a torch! (" + Str(#TORCH_MAX_STEPS) + " steps)")
      EndIf

    Case Asc("T")
      ; lantern pickup: bigger radius, longer fuel
      SetCell(nx, ny, Asc("."))
      PlaySfx(#Sfx_Treasure)

      If LanternStepsLeft >= #LANTERN_MAX_STEPS
        LanternStepsLeft = #LANTERN_MAX_STEPS
        ScriptItems("LANTERN") = 1
        SetStatus("Lantern already full. (" + Str(#LANTERN_MAX_STEPS) + " steps)")
      ElseIf LanternStepsLeft > 0
        LanternStepsLeft = #LANTERN_MAX_STEPS
        ScriptItems("LANTERN") = 1
        SetStatus("Refilled lantern! (" + Str(#LANTERN_MAX_STEPS) + " steps)")
      Else
        LanternStepsLeft = #LANTERN_MAX_STEPS
        ScriptItems("LANTERN") = 1
        SetStatus("Picked up a lantern! (" + Str(#LANTERN_MAX_STEPS) + " steps)")
      EndIf

    Case Asc("~")
      Health - 1
      If Health < 1
        KillPlayer()
        ProcedureReturn #False
      EndIf
      PlaySfx(#Sfx_Hurt)

    Case Asc("!")
      hint = GetBangMarkerText(nx, ny)
      If hint <> ""
        SetStatus(hint, 3500)
        PlaySfx(#Sfx_Beep)
      Else
        ; fallback if it's a bare marker
        SetStatus("...", 1500)
        PlaySfx(#Sfx_Beep)
      EndIf

      If World\BangOneShot
        SetCell(nx, ny, Asc("."))
      EndIf

    Case Asc("P")
      If SelectPassageAt(CurBoard(), nx, ny)
        destBoard = Clamp(Passages()\DestBoard, 0, BoardCount - 1)

        If Passages()\UseBoardStart
          destX = Boards(destBoard)\StartX
          destY = Boards(destBoard)\StartY
        Else
          destX = Passages()\DestX
          destY = Passages()\DestY
        EndIf

        destX = Clamp(destX, 0, #MAP_W - 1)
        destY = Clamp(destY, 0, #MAP_H - 1)

        SwitchBoard(destBoard, "")
        PlayerX = destX
        PlayerY = destY

        SetStatus("Passage -> Board " + Str(destBoard) + " (" + Str(destX) + "," + Str(destY) + ")")
        PlaySfx(#Sfx_Exit)
        ProcedureReturn #True
      Else
        SetStatus("Passage not configured (Shift+F3 in editor)")
        PlaySfx(#Sfx_Beep)
      EndIf

    Case Asc("^")
      ; convenience: next board
      If BoardCount > 1
        SwitchBoard((CurBoard() + 1) % BoardCount, "")
        ProcedureReturn #True
      Else
        PlaySfx(#Sfx_Exit)
        SetStatus("Exit reached.")
      EndIf
  EndSelect

  PlayerX = nx
  PlayerY = ny

  ; light fuel drains by movement (only on dark boards)
  If Boards(CurBoard())\Dark
    If TorchStepsLeft > 0
      TorchStepsLeft - 1
      If TorchStepsLeft <= 0
        TorchStepsLeft = 0
        ScriptItems("TORCH") = 0
        SetStatus("Your torch burned out.")
        PlaySfx(#Sfx_Beep)
      EndIf
    EndIf
    If LanternStepsLeft > 0
      LanternStepsLeft - 1
      If LanternStepsLeft <= 0
        LanternStepsLeft = 0
        ScriptItems("LANTERN") = 0
        SetStatus("Your lantern went out.")
        PlaySfx(#Sfx_Beep)
      EndIf
    EndIf
  EndIf

  PlaySfx(#Sfx_Step)

  ; Non-solid object contact triggers TOUCH
  objId = ObjOverlayId(PlayerX + PlayerY * #MAP_W)
  If objId <> 0 And ObjOverlaySolid(PlayerX + PlayerY * #MAP_W) = 0
    PlaySfx(#Sfx_Beep)
    TriggerObjectLabel(objId, "TOUCH")
  EndIf

  ProcedureReturn #True
EndProcedure

; UpdateEnemies
Procedure UpdateEnemies()
  Protected b.i = CurBoard()
  Protected dx.i, dy.i, r.i
  Protected nx.i, ny.i
  Protected targetCh.a
  Protected targetId.i
  Protected oldIdx.i, newIdx.i
  Protected Dim occupied.b(#MAP_W * #MAP_H - 1)

  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf

  ; Overlay is needed for collision checks.
  RebuildObjectOverlay()

  ; Track enemy occupancy so multiple enemies can't stack.
  ForEach Objects()
    If Objects()\Alive And Objects()\Board = b And Objects()\Solid And Objects()\Char = Asc("E")
      occupied(Objects()\X + Objects()\Y * #MAP_W) = 1
    EndIf
  Next

  ForEach Objects()
    If Objects()\Alive And Objects()\Board = b And Objects()\Solid And Objects()\Char = Asc("E")
      dx = 0 : dy = 0

      r = Random(99)
      If r < 60
        If Abs(PlayerX - Objects()\X) > Abs(PlayerY - Objects()\Y)
          dx = SignI(PlayerX - Objects()\X)
        Else
          dy = SignI(PlayerY - Objects()\Y)
        EndIf
      Else
        Select Random(3)
          Case 0 : dx = -1
          Case 1 : dx = 1
          Case 2 : dy = -1
          Case 3 : dy = 1
        EndSelect
      EndIf

      If dx = 0 And dy = 0
        Continue
      EndIf

      nx = Objects()\X + dx
      ny = Objects()\Y + dy
      If nx < 0 Or ny < 0 Or nx >= #MAP_W Or ny >= #MAP_H
        Continue
      EndIf

      If nx = PlayerX And ny = PlayerY
        Health - 1
        If Health < 1
          KillPlayer()
        Else
          PlaySfx(#Sfx_Hurt)
        EndIf
        Continue
      EndIf

      ; Don't path through exits.
      newIdx = nx + ny * #MAP_W
      targetCh = Boards(b)\Map[newIdx]
      If targetCh = Asc("^")
        Continue
      EndIf

      ; Respect map solids (walls, doors, etc.).
      If Solid(targetCh)
        Continue
      EndIf

      ; No enemy stacking.
      oldIdx = Objects()\X + Objects()\Y * #MAP_W
      If occupied(newIdx) And newIdx <> oldIdx
        Continue
      EndIf

      ; Prevent enemies stepping into solid objects.
      targetId = ObjOverlayId(newIdx)
      If targetId <> 0 And ObjOverlaySolid(newIdx)
        Continue
      EndIf

      occupied(oldIdx) = 0
      occupied(newIdx) = 1
      Objects()\X = nx
      Objects()\Y = ny
    EndIf
  Next
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 292
; FirstLine = 371
; Folding = -
; EnableXP
; DPIAware