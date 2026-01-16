;------------------------------------------------------------------------------
; World loading/saving (extracted from pbzt.pb)
;------------------------------------------------------------------------------

CompilerIf #PB_Compiler_IsMainFile
  CompilerError "Compile pb_szzt.pb (main) instead of includes/world_io.pbi."
CompilerEndIf

;------------------------------------------------------------------------------
; ParseIntDefault
; Purpose: Procedure: Parse Int Default.
;------------------------------------------------------------------------------

Procedure.i ParseIntDefault(Value.s, DefaultValue.i)
  Value = Trim(Value)
  If Value = "" : ProcedureReturn DefaultValue : EndIf

  If FindString(Value, "-", 1) Or (Asc(Left(Value, 1)) >= '0' And Asc(Left(Value, 1)) <= '9')
    ProcedureReturn Val(Value)
  EndIf

  ProcedureReturn DefaultValue
EndProcedure

;------------------------------------------------------------------------------
; CreateSingleBoardWorldFromLegacyFile
; Purpose: Procedure: Create Single Board World From Legacy File.
;------------------------------------------------------------------------------

Procedure CreateSingleBoardWorldFromLegacyFile(FilePath.s)
  World\FilePath = FilePath
  World\Name = GetFilePart(FilePath)
  World\StartBoard = 0
  World\CurrentBoard = 0
  World\BangOneShot = 0

  ClearList(Passages())

  EnsureWorldBoards(1)
  Boards(0)\Name = GetFilePart(FilePath)
EndProcedure

;------------------------------------------------------------------------------
; BuildMapLine
; Purpose: Serialize one row of the board map.
;------------------------------------------------------------------------------

Procedure.s BuildMapLine(BoardIdx.i, RowY.i)
  Protected x.i
  Protected s.s

  If BoardIdx < 0 Or BoardIdx >= BoardCount : ProcedureReturn "" : EndIf
  If RowY < 0 Or RowY >= #MAP_H : ProcedureReturn "" : EndIf

  s = ""
  For x = 0 To #MAP_W - 1
    s + Chr(Boards(BoardIdx)\Map[x + RowY * #MAP_W])
  Next

  ProcedureReturn s
EndProcedure

;------------------------------------------------------------------------------
; LoadWorld
; Purpose: Load a PBZT world from a text file.
;------------------------------------------------------------------------------

Procedure.b LoadWorld(FilePath.s)
  Protected f.i, line.s, section.s
  Protected eq.i, left.s, right.s, cval.i
  Protected hdr.s, close.i
  Protected kvKey.String, kvVal.String

  ; Start every world load from app preferences.
  ; Worlds can still override by including Sfx* keys in their [World] section.
  LoadPrefs()

  Protected boardIdx.i = -1
  Protected mapY.i
  Protected colorsY.i
  Protected legacyMode.b

  Protected objectId.i
  Protected inScript.b

  Protected inMusic.b

  Protected passageBoard.i
  Protected passageX.i
  Protected passageY.i
  Protected passageDestBoard.i
  Protected passageDestX.i
  Protected passageDestY.i
  Protected passageUseBoardStart.i
  Protected passageTouched.b

  ResetRules()
  ClearList(Objects())
  ClearList(Passages())

  World\FilePath = ""
  World\Name = "Untitled"
  World\StartBoard = 0
  World\CurrentBoard = 0
  World\BangOneShot = 0

  ; Sound tuning: default comes from INI (LoadPrefs), but worlds can override via [World] keys.

  EnsureWorldBoards(1)
  InitBlankBoard(0)
  ConvertEnemyTilesToObjects(0)
  ConvertWaterTilesToObjects(0)

  If FileSize(FilePath) <= 0
    SetStatus("World file missing; started blank.")
    ResetPlayerToBoardStart()
    ProcedureReturn #False
  EndIf

  f = ReadFile(#PB_Any, FilePath)
  If f = 0
    SetStatus("Failed to open world.")
    ResetPlayerToBoardStart()
    ProcedureReturn #False
  EndIf

  section = ""
  mapY = 0
  colorsY = 0
  objectId = 0
  inScript = #False
  inMusic = #False

  passageBoard = 0
  passageX = 0
  passageY = 0
  passageDestBoard = 0
  passageDestX = 0
  passageDestY = 0
  passageUseBoardStart = 0
  passageTouched = #False

  While Eof(f) = 0
    line = ReadString(f)
    line = ReplaceString(line, Chr(9), " ")
    line = ReplaceString(line, Chr(13), "")

    ; Comments are lines starting with "# " (hash+space).
    ; This avoids treating map border "#" rows as comments.
    If Left(LTrim(line), 2) = "# "
      Continue
    EndIf

    ; Commit buffered passage when a new section begins.
    If passageTouched
      If Left(Trim(line), 1) = "[" And FindString(line, "]", 1)
        passageBoard = Clamp(passageBoard, 0, BoardCount - 1)
        passageX = Clamp(passageX, 0, #MAP_W - 1)
        passageY = Clamp(passageY, 0, #MAP_H - 1)
        passageDestBoard = Clamp(passageDestBoard, 0, BoardCount - 1)
        passageDestX = Clamp(passageDestX, 0, #MAP_W - 1)
        passageDestY = Clamp(passageDestY, 0, #MAP_H - 1)

        UpsertPassage(passageBoard, passageX, passageY, passageDestBoard, passageDestX, passageDestY, Bool(passageUseBoardStart <> 0))
        passageTouched = #False
      EndIf
    EndIf

    ; inside a [Passage] block, buffer key/value lines until next section
    If section = "PASSAGE"
      If Trim(line) = "" : Continue : EndIf

      eq = FindString(line, "=", 1)
      If eq > 0
        left = UCase(Trim(Left(line, eq - 1)))
        right = Trim(Mid(line, eq + 1))
        Select left
          Case "BOARD" : passageBoard = ParseIntDefault(right, passageBoard)
          Case "X" : passageX = ParseIntDefault(right, passageX)
          Case "Y" : passageY = ParseIntDefault(right, passageY)
          Case "DESTBOARD" : passageDestBoard = ParseIntDefault(right, passageDestBoard)
          Case "DESTX" : passageDestX = ParseIntDefault(right, passageDestX)
          Case "DESTY" : passageDestY = ParseIntDefault(right, passageDestY)
          Case "USEBOARDSTART", "USESTART" : passageUseBoardStart = Bool(ParseIntDefault(right, 0) <> 0)
        EndSelect
        passageTouched = #True
      EndIf
      Continue
    EndIf

    ; inside ScriptBegin/End block: keep raw lines (except section headers)
    If inScript
      If Left(Trim(line), 1) = "[" And FindString(line, "]", 1)
        ; script ended implicitly by new section
        inScript = #False
      Else
        If Trim(line) = "ScriptEnd"
          inScript = #False
        Else
          If SelectObjectById(objectId)
            Objects()\Script + line + #LF$
          EndIf
        EndIf
        Continue
      EndIf
    EndIf

    ; inside MusicBegin/End block: keep raw lines (except section headers)
    If inMusic
      If Left(Trim(line), 1) = "[" And FindString(line, "]", 1)
        inMusic = #False
      Else
        If Trim(line) = "MusicEnd"
          inMusic = #False
        Else
          If boardIdx >= 0 And boardIdx < BoardCount
            Boards(boardIdx)\Music + line + #LF$
          EndIf
        EndIf
        Continue
      EndIf
    EndIf

    If Trim(line) = ""
      Continue
    EndIf

    If Left(Trim(line), 1) = "[" And FindString(line, "]", 1)
      ; Extract section name inside brackets, e.g. "[Map]" -> "MAP"
      hdr = Trim(line)
      close = FindString(hdr, "]", 1)
      section = ""
      If close > 2
        section = UCase(Mid(hdr, 2, close - 2))
      EndIf

      If section = "PASSAGE"
        passageBoard = 0
        passageX = 0
        passageY = 0
        passageDestBoard = 0
        passageDestX = 0
        passageDestY = 0
        passageUseBoardStart = 0
        passageTouched = #False

      ElseIf Left(section, 5) = "BOARD"
        boardIdx + 1
        EnsureWorldBoards(boardIdx + 1)
        InitBlankBoard(boardIdx)
        mapY = 0
        colorsY = 0
        section = "BOARD"

      ElseIf section = "MAP"
        If boardIdx = -1
          legacyMode = #True
          boardIdx = 0
          CreateSingleBoardWorldFromLegacyFile(FilePath)
          EnsureWorldBoards(1)
          InitBlankBoard(0)
        EndIf
        mapY = 0

      ElseIf section = "OBJECT"
        If boardIdx < 0
          boardIdx = 0
          EnsureWorldBoards(1)
        EndIf
        objectId = AddObject(boardIdx, Boards(boardIdx)\StartX, Boards(boardIdx)\StartY)
        If SelectObjectById(objectId)
          Objects()\Script = "" ; will be set by ScriptBegin or properties
          Objects()\IP = 0
          Objects()\Wait = 0
        EndIf

      EndIf

      Continue
    EndIf

    Select section
      Case "WORLD"
        eq = FindString(line, "=", 1)
        If eq > 0
          left = UCase(Trim(Left(line, eq - 1)))
          right = Trim(Mid(line, eq + 1))
            Select left
              Case "NAME" : World\Name = right
              Case "STARTBOARD" : World\StartBoard = ParseIntDefault(right, 0)
              Case "BANGONESHOT" : World\BangOneShot = Bool(ParseIntDefault(right, 0) <> 0)

              Case "RESPAWNATWORLDSTART" : World\RespawnAtWorldStart = Bool(ParseIntDefault(right, 1) <> 0)
              Case "DEATHLOSESCORE" : World\DeathLoseScore = Clamp(ParseIntDefault(right, 0), 0, 999999)
              Case "DEATHLOSEKEYS" : World\DeathLoseKeys = Clamp(ParseIntDefault(right, 0), 0, 9999)
              Case "DEATHRESPAWNDELAYMS" : World\DeathRespawnDelayMS = Clamp(ParseIntDefault(right, 1200), 0, 60000)
              Case "DEATHFADEMS" : World\DeathFadeMS = Clamp(ParseIntDefault(right, 700), 0, 60000)

              ; optional per-world sound tuning (defaults are 1.0)
              Case "SFXMASTERVOL" : SfxMasterVol = ClampF(ValF(right), 0.0, 4.0)
              Case "SFXPITCH" : SfxPitchMul = ClampF(ValF(right), 0.5, 2.0)
              Case "SFXNOISE" : SfxNoiseMul = ClampF(ValF(right), 0.0, 2.0)
              Case "SFXVIB" : SfxVibMul = ClampF(ValF(right), 0.0, 2.0)
            EndSelect
        EndIf

      Case "PALETTE"
        eq = FindString(line, "=", 1)
        If eq > 0
          left = Trim(Left(line, eq - 1))
          right = Trim(Mid(line, eq + 1))
          If Len(left) >= 1
            cval = Val(right)
            Palette(Asc(Left(left, 1))) = Clamp(cval, 0, 255)

          EndIf
        EndIf

      Case "SOLIDS"
        line = Trim(line)
        If line <> ""
          ; Savegames may include enemies as objects; keep map letter 'E' passable.
          If Asc(Left(line, 1)) <> Asc("E")
            Solid(Asc(Left(line, 1))) = 1
          EndIf
        EndIf

      Case "PASSAGE"
        If Trim(line) = "" : Continue : EndIf

        Protected eq2.i, left2.s, right2.s
        eq2 = FindString(line, "=", 1)
        If eq2 > 0
          left2 = UCase(Trim(Left(line, eq2 - 1)))
          right2 = Trim(Mid(line, eq2 + 1))
          Select left2
            Case "BOARD" : passageBoard = ParseIntDefault(right2, passageBoard)
            Case "X" : passageX = ParseIntDefault(right2, passageX)
            Case "Y" : passageY = ParseIntDefault(right2, passageY)
            Case "DESTBOARD" : passageDestBoard = ParseIntDefault(right2, passageDestBoard)
            Case "DESTX" : passageDestX = ParseIntDefault(right2, passageDestX)
            Case "DESTY" : passageDestY = ParseIntDefault(right2, passageDestY)
            Case "USEBOARDSTART", "USESTART" : passageUseBoardStart = Bool(ParseIntDefault(right2, 0) <> 0)
          EndSelect
          passageTouched = #True
        EndIf

      Case "BOARD"
        If boardIdx < 0 : Continue : EndIf

        If Trim(line) = "MusicBegin"
          Boards(boardIdx)\Music = ""
          inMusic = #True
          Continue
        EndIf

        ReadKeyValueLine(line, @kvKey, @kvVal)
        Select kvKey\s
          Case "NAME"
            Boards(boardIdx)\Name = kvVal\s

          Case "EXITN", "NORTH", "N"
            Boards(boardIdx)\ExitN = ParseIntDefault(kvVal\s, -1)
          Case "EXITS", "SOUTH", "S"
            Boards(boardIdx)\ExitS = ParseIntDefault(kvVal\s, -1)
          Case "EXITW", "WEST", "W"
            Boards(boardIdx)\ExitW = ParseIntDefault(kvVal\s, -1)
          Case "EXITE", "EAST", "E"
            Boards(boardIdx)\ExitE = ParseIntDefault(kvVal\s, -1)

          Case "STARTX"
            Boards(boardIdx)\StartX = ParseIntDefault(kvVal\s, 1)
          Case "STARTY"
            Boards(boardIdx)\StartY = ParseIntDefault(kvVal\s, 1)
          Case "DARK"
            Boards(boardIdx)\Dark = Bool(ParseIntDefault(kvVal\s, 0) <> 0)
        EndSelect

      Case "MAP"
        If boardIdx < 0 : Continue : EndIf

        If mapY < #MAP_H
          Protected x3.i, ch3.a
          Protected row3.s

          row3 = line
          If Len(row3) > #MAP_W
            row3 = Left(row3, #MAP_W)
          ElseIf Len(row3) < #MAP_W
            row3 + RSet("", #MAP_W - Len(row3), " ")
          EndIf

          For x3 = 0 To #MAP_W - 1
            ch3 = Asc(Mid(row3, x3 + 1, 1))
            Boards(boardIdx)\Map[x3 + mapY * #MAP_W] = ch3

            ; If a savegame omits [Colors], fall back to palette color.
            If colorsY = 0
              Boards(boardIdx)\Color[x3 + mapY * #MAP_W] = Palette(ch3)
            EndIf
          Next
          mapY + 1
        EndIf

      Case "COLORS"
        If boardIdx < 0 : Continue : EndIf

        If colorsY < #MAP_H
          Protected x4.i, idx4.i
          Protected row4.s
          Protected hexCh.s
          Protected hexPair.s

          row4 = Trim(line)

          ; Backward-compatible parsing:
          ; - Old format: 80 hex nibbles (0..15), 1 char per tile.
          ; - New format: 160 hex digits (00..FF), 2 chars per tile.
          If Len(row4) >= #MAP_W * 2
            If Len(row4) > #MAP_W * 2
              row4 = Left(row4, #MAP_W * 2)
            ElseIf Len(row4) < #MAP_W * 2
              row4 + RSet("", #MAP_W * 2 - Len(row4), "0")
            EndIf

            For x4 = 0 To #MAP_W - 1
              idx4 = x4 + colorsY * #MAP_W
              hexPair = Mid(row4, x4 * 2 + 1, 2)
              Boards(boardIdx)\Color[idx4] = Clamp(Val("$" + hexPair), 0, 255)
            Next
          Else
            If Len(row4) > #MAP_W
              row4 = Left(row4, #MAP_W)
            ElseIf Len(row4) < #MAP_W
              row4 + RSet("", #MAP_W - Len(row4), "0")
            EndIf

            For x4 = 0 To #MAP_W - 1
              idx4 = x4 + colorsY * #MAP_W
              hexCh = Mid(row4, x4 + 1, 1)
              Boards(boardIdx)\Color[idx4] = ReadHexNibbleChar(hexCh)
            Next
          EndIf

          colorsY + 1
        EndIf

      Case "GAME"
        ReadKeyValueLine(line, @kvKey, @kvVal)
        Select kvKey\s
          Case "WORLDFILE" : World\FilePath = kvVal\s
          Case "CURRENTBOARD" : World\CurrentBoard = ParseIntDefault(kvVal\s, World\CurrentBoard)
          Case "PLAYERX" : PlayerX = ParseIntDefault(kvVal\s, PlayerX)
          Case "PLAYERY" : PlayerY = ParseIntDefault(kvVal\s, PlayerY)
          Case "SCORE" : Score = Clamp(ParseIntDefault(kvVal\s, Score), 0, 999999999)
          Case "KEYS" : Keys = Clamp(ParseIntDefault(kvVal\s, Keys), 0, 9999)
          Case "HEALTH" : Health = Clamp(ParseIntDefault(kvVal\s, Health), 0, 9999)
          Case "TORCHSTEPSLEFT" : TorchStepsLeft = Clamp(ParseIntDefault(kvVal\s, TorchStepsLeft), 0, #TORCH_MAX_STEPS)
          Case "LANTERNSTEPSLEFT" : LanternStepsLeft = Clamp(ParseIntDefault(kvVal\s, LanternStepsLeft), 0, #LANTERN_MAX_STEPS)
          Case "DEATHPENDING" : DeathPending = Bool(ParseIntDefault(kvVal\s, 0) <> 0)
        EndSelect

      Case "FLAGS"
        line = Trim(line)
        If line <> ""
          ScriptFlags(line) = 1
        EndIf

      Case "ITEMS"
        ReadKeyValueLine(line, @kvKey, @kvVal)
        If kvKey\s <> ""
          ScriptItems(kvKey\s) = ParseIntDefault(kvVal\s, 0)
        EndIf

      Case "COLORKEYS"
        ReadKeyValueLine(line, @kvKey, @kvVal)
        If kvKey\s <> ""
          ColorKeys(kvKey\s) = ParseIntDefault(kvVal\s, 0)
        EndIf

      Case "OBJECTSTATE"
        If objectId = 0 : Continue : EndIf

        If Trim(line) = "ScriptBegin"
          inScript = #True
          Continue
        EndIf

        ReadKeyValueLine(line, @kvKey, @kvVal)
        If kvKey\s = "" : Continue : EndIf

        ; Keep element selection stable: scripts stream into current object.
        If ListSize(Objects()) > 0
          Select kvKey\s
            Case "ID"
              Objects()\Id = ParseIntDefault(kvVal\s, Objects()\Id)
              objectId = Objects()\Id

            Case "ALIVE" : Objects()\Alive = Bool(ParseIntDefault(kvVal\s, Objects()\Alive) <> 0)
            Case "BOARD" : Objects()\Board = ParseIntDefault(kvVal\s, Objects()\Board)
            Case "X" : Objects()\X = ParseIntDefault(kvVal\s, Objects()\X)
            Case "Y" : Objects()\Y = ParseIntDefault(kvVal\s, Objects()\Y)
            Case "CHAR" : If kvVal\s <> "" : Objects()\Char = Asc(Left(kvVal\s, 1)) : EndIf
            Case "COLOR" : Objects()\Color = Clamp(ParseIntDefault(kvVal\s, Objects()\Color), 0, 255)
            Case "SOLID" : Objects()\Solid = Bool(ParseIntDefault(kvVal\s, Objects()\Solid) <> 0)
            Case "NAME" : Objects()\Name = kvVal\s
            Case "IP" : Objects()\IP = ParseIntDefault(kvVal\s, Objects()\IP)
            Case "WAIT" : Objects()\Wait = ParseIntDefault(kvVal\s, Objects()\Wait)
          EndSelect
        EndIf

    EndSelect
  Wend

  ; Commit trailing [Passage] block at EOF.
  If passageTouched
    passageBoard = Clamp(passageBoard, 0, BoardCount - 1)
    passageX = Clamp(passageX, 0, #MAP_W - 1)
    passageY = Clamp(passageY, 0, #MAP_H - 1)
    passageDestBoard = Clamp(passageDestBoard, 0, BoardCount - 1)
    passageDestX = Clamp(passageDestX, 0, #MAP_W - 1)
    passageDestY = Clamp(passageDestY, 0, #MAP_H - 1)

    UpsertPassage(passageBoard, passageX, passageY, passageDestBoard, passageDestX, passageDestY, Bool(passageUseBoardStart <> 0))
  EndIf

  CloseFile(f)

  If boardIdx < 0
    boardIdx = 0
    EnsureWorldBoards(1)
    InitBlankBoard(0)
  Else
    EnsureWorldBoards(boardIdx + 1)
  EndIf

  Protected bi.i
  For bi = 0 To BoardCount - 1
    ConvertWaterTilesToObjects(bi)
    SanitizeBoard(bi)
  Next

  ForEach Objects()
    Objects()\X = Clamp(Objects()\X, 0, #MAP_W - 1)
    Objects()\Y = Clamp(Objects()\Y, 0, #MAP_H - 1)
    Objects()\Board = Clamp(Objects()\Board, 0, BoardCount - 1)
    Objects()\Script = NormalizeScriptText(Objects()\Script)
  Next

  SyncNextObjectIdFromObjects()

  World\StartBoard = Clamp(World\StartBoard, 0, BoardCount - 1)
  World\CurrentBoard = Clamp(World\CurrentBoard, 0, BoardCount - 1)

  PlayerX = Clamp(PlayerX, 0, #MAP_W - 1)
  PlayerY = Clamp(PlayerY, 0, #MAP_H - 1)

  If Solid(Boards(CurBoard())\Map[PlayerX + PlayerY * #MAP_W])
    ResetPlayerToBoardStart()
  EndIf

  If SfxReady
    BuildSfxCache()
  EndIf

  ; Start per-board music immediately after a successful load.
  If World\CurrentBoard >= 0 And World\CurrentBoard < BoardCount
    If Boards(World\CurrentBoard)\Music <> ""
      StartBoardMusic("WORLD:" + World\FilePath + ":BOARD:" + Str(World\CurrentBoard), Boards(World\CurrentBoard)\Music)
    Else
      StopBoardMusic()
    EndIf
  Else
    StopBoardMusic()
  EndIf

  RebuildObjectOverlay()

  SetStatus("Loaded game: " + GetFilePart(FilePath) + " (" + Str(BoardCount) + " boards, " + Str(ListSize(Objects())) + " objects)", 4000)
  ProcedureReturn #True
EndProcedure

;------------------------------------------------------------------------------
; SaveWorld
; Purpose: Save current PBZT world to a text file.
;------------------------------------------------------------------------------

Procedure.b SaveWorldCore(FilePath.s, UpdateWorldPath.b, CleanInvalidPassages.b)
  Protected f.i
  Protected Dim used.b(255)
  Protected b.i, x.i, y.i, ch.a

  If FilePath = "" : ProcedureReturn #False : EndIf

  ; mark used characters across all boards and objects
  For b = 0 To BoardCount - 1
    For y = 0 To #MAP_H - 1
      For x = 0 To #MAP_W - 1
        ch = Boards(b)\Map[x + y * #MAP_W]
        used(ch) = #True
      Next
    Next
  Next

  ForEach Objects()
    used(Objects()\Char) = #True
  Next

  ; optionally remove passage definitions that no longer sit on 'P' tiles
  If CleanInvalidPassages
    ForEach Passages()
      If Passages()\Board >= 0 And Passages()\Board < BoardCount
        If Boards(Passages()\Board)\Map[Passages()\X + Passages()\Y * #MAP_W] <> Asc("P")
          DeleteElement(Passages())
        EndIf
      Else
        DeleteElement(Passages())
      EndIf
    Next
  EndIf

  If ListSize(Passages()) > 0
    used(Asc("P")) = #True
  EndIf

  used(Asc("@")) = #True

  f = CreateFile(#PB_Any, FilePath)
  If f = 0
    SetStatus("Save failed.")
    ProcedureReturn #False
  EndIf

  WriteStringN(f, "# " + #APP_NAME + " World v2")
  WriteStringN(f, "# " + Str(#MAP_W) + "x" + Str(#MAP_H))
  WriteStringN(f, "")

   WriteStringN(f, "[World]")
  WriteStringN(f, "Name=" + World\Name)
  WriteStringN(f, "StartBoard=" + Str(World\StartBoard))
  WriteStringN(f, "BangOneShot=" + Str(Bool(World\BangOneShot <> 0)))
  WriteStringN(f, "RespawnAtWorldStart=" + Str(Bool(World\RespawnAtWorldStart <> 0)))
  WriteStringN(f, "DeathLoseScore=" + Str(Clamp(World\DeathLoseScore, 0, 999999)))
  WriteStringN(f, "DeathLoseKeys=" + Str(Clamp(World\DeathLoseKeys, 0, 9999)))
  WriteStringN(f, "DeathRespawnDelayMS=" + Str(Clamp(World\DeathRespawnDelayMS, 0, 60000)))
  WriteStringN(f, "DeathFadeMS=" + Str(Clamp(World\DeathFadeMS, 0, 60000)))
  WriteStringN(f, "SfxMasterVol=" + StrF(ClampF(SfxMasterVol, 0.0, 4.0), 2))
  WriteStringN(f, "SfxPitch=" + StrF(ClampF(SfxPitchMul, 0.5, 2.0), 2))
  WriteStringN(f, "SfxNoise=" + StrF(ClampF(SfxNoiseMul, 0.0, 2.0), 2))
  WriteStringN(f, "SfxVib=" + StrF(ClampF(SfxVibMul, 0.0, 2.0), 2))
  WriteStringN(f, "")

  WriteStringN(f, "[Palette]")
  For ch = 0 To 255
    If used(ch)
      WriteStringN(f, Chr(ch) + "=" + Str(Palette(ch)))
    EndIf
  Next
  WriteStringN(f, "")

  WriteStringN(f, "[Solids]")
  For ch = 0 To 255
    If Solid(ch)
      WriteStringN(f, Chr(ch))
    EndIf
  Next

  ForEach Passages()
    WriteStringN(f, "")
    WriteStringN(f, "[Passage]")
    WriteStringN(f, "Board=" + Str(Passages()\Board))
    WriteStringN(f, "X=" + Str(Passages()\X))
    WriteStringN(f, "Y=" + Str(Passages()\Y))
    WriteStringN(f, "DestBoard=" + Str(Passages()\DestBoard))
    WriteStringN(f, "DestX=" + Str(Passages()\DestX))
    WriteStringN(f, "DestY=" + Str(Passages()\DestY))
    WriteStringN(f, "UseBoardStart=" + Str(Bool(Passages()\UseBoardStart <> 0)))
  Next

  For b = 0 To BoardCount - 1
    WriteStringN(f, "")
    WriteStringN(f, "[Board]")
    WriteStringN(f, "Name=" + Boards(b)\Name)
    WriteStringN(f, "ExitN=" + Str(Boards(b)\ExitN))
    WriteStringN(f, "ExitS=" + Str(Boards(b)\ExitS))
    WriteStringN(f, "ExitW=" + Str(Boards(b)\ExitW))
    WriteStringN(f, "ExitE=" + Str(Boards(b)\ExitE))
    WriteStringN(f, "StartX=" + Str(Boards(b)\StartX))
    WriteStringN(f, "StartY=" + Str(Boards(b)\StartY))
    WriteStringN(f, "Dark=" + Str(Bool(Boards(b)\Dark <> 0)))

    If Trim(Boards(b)\Music) <> ""
      WriteStringN(f, "MusicBegin")
      Protected musicLineCnt.i, mi.i, musicLine.s
      musicLineCnt = CountString(Boards(b)\Music, #LF$) + 1
      For mi = 1 To musicLineCnt
        musicLine = StringField(Boards(b)\Music, mi, #LF$)
        musicLine = ReplaceString(musicLine, #CR$, "")
        If mi = musicLineCnt And Trim(musicLine) = ""
          Break
        EndIf
        WriteStringN(f, musicLine)
      Next
      WriteStringN(f, "MusicEnd")
    EndIf
 
    WriteStringN(f, "[Map]")
    For y = 0 To #MAP_H - 1
      WriteStringN(f, BuildMapLine(b, y))
    Next

    ; Per-cell color indices (0..255). Two hex digits per cell (00..FF).
    WriteStringN(f, "")
    WriteStringN(f, "[Colors]")
    Protected colorRow.s
    Protected c.i
    For y = 0 To #MAP_H - 1
      colorRow = ""
      For x = 0 To #MAP_W - 1
        c = Clamp(Boards(b)\Color[x + y * #MAP_W], 0, 255)
        colorRow + RSet(Hex(c), 2, "0")
      Next
      WriteStringN(f, colorRow)
    Next

    ForEach Objects()
      If Objects()\Alive And Objects()\Board = b
        WriteStringN(f, "")
        WriteStringN(f, "[Object]")
        WriteStringN(f, "Name=" + Objects()\Name)
        WriteStringN(f, "X=" + Str(Objects()\X))
        WriteStringN(f, "Y=" + Str(Objects()\Y))
        WriteStringN(f, "Char=" + Chr(Objects()\Char))
        WriteStringN(f, "Color=" + Str(Clamp(Objects()\Color, 0, 255)))
        WriteStringN(f, "Solid=" + Str(Bool(Objects()\Solid <> 0)))
        WriteStringN(f, "ScriptBegin")

        Protected i.i, cnt.i, ln.s
        cnt = GetScriptLineCount(Objects()\Script)
        For i = 0 To cnt - 1
          ln = GetScriptLine(Objects()\Script, i)
          WriteStringN(f, ln)
        Next

        WriteStringN(f, "ScriptEnd")
      EndIf
    Next
  Next

  CloseFile(f)

  If UpdateWorldPath
    World\FilePath = FilePath
    ; Useful default for next run.
    PrefLastWorldPath = FilePath
    SavePrefs()
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.b SaveWorld(FilePath.s)
  If SaveWorldCore(FilePath, #True, #True)
    SetStatus("Saved world: " + GetFilePart(FilePath) + " (" + Str(BoardCount) + " boards, " + Str(ListSize(Objects())) + " objects, " + Str(ListSize(Passages())) + " passages)")
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.b SaveWorldAutosave(FilePath.s)
  ; Do not modify the world (no passage cleanup) and do not change World\FilePath.
  ProcedureReturn SaveWorldCore(FilePath, #False, #False)
EndProcedure

;------------------------------------------------------------------------------
; SaveGame / LoadGame
; Purpose: Quicksave wrappers (savegame is a full snapshot).
;------------------------------------------------------------------------------

Procedure.b SaveGame(FilePath.s)
  ; Save a full snapshot to a text file.
  ProcedureReturn SaveWorldCore(FilePath, #False, #False)
EndProcedure

Procedure.b LoadGame(FilePath.s)
  ; Load a snapshot from a text file.
  ProcedureReturn LoadWorld(FilePath)
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 107
; FirstLine = 762
; Folding = --
; EnableXP
; DPIAware