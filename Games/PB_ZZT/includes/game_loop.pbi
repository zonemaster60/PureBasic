;------------------------------------------------------------------------------
; Main game loop (extracted from pbzt.pb)
;------------------------------------------------------------------------------

Procedure.s GetSaveGamesDir()
  ; Store savegames under a dedicated folder.
  ; If INI [World] SaveDir is set, prefer it.
  Protected dir.s

  dir = Trim(PrefSaveDir)
  If dir = ""
    dir = GetPathPart(ProgramFilename()) + "saves" + #PS$
  Else
    ; If SaveDir is relative, resolve it next to the executable.
    Protected isAbs.b = #False

    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If Left(dir, 2) = "\\" ; UNC
        isAbs = #True
      ElseIf Len(dir) >= 2 And Mid(dir, 2, 1) = ":" ; C:\...
        isAbs = #True
      ElseIf Left(dir, 1) = "\\" Or Left(dir, 1) = "/" ; root-relative
        isAbs = #True
      EndIf
    CompilerElse
      If Left(dir, 1) = #PS$
        isAbs = #True
      EndIf
    CompilerEndIf

    If isAbs = #False
      dir = GetPathPart(ProgramFilename()) + dir
    EndIf
  EndIf

  ; Ensure trailing separator.
  If Right(dir, 1) <> #PS$
    dir + #PS$
  EndIf

  ; Try to create if missing.
  If FileSize(dir) <> -2
    CreateDirectory(dir)
  EndIf

  ; Fallback if still invalid.
  If FileSize(dir) <> -2
    dir = GetPathPart(ProgramFilename()) + "saves" + #PS$
    If FileSize(dir) <> -2
      CreateDirectory(dir)
    EndIf
  EndIf

  ProcedureReturn dir
EndProcedure

Procedure.i GetQuickSaveSlot()
  ; Slot range is 1..5
  PrefQuickSaveSlot = Clamp(PrefQuickSaveSlot, 1, 5)
  ProcedureReturn PrefQuickSaveSlot
EndProcedure

Procedure SetQuickSaveSlot(slot.i)
  PrefQuickSaveSlot = Clamp(slot, 1, 5)
  SavePrefs()
EndProcedure

Procedure.s GetQuickSavePath()
  Protected saveDir.s
  Protected slot.i

  saveDir = GetSaveGamesDir()
  slot = GetQuickSaveSlot()
  ProcedureReturn saveDir + #APP_NAME + "_quicksave" + Str(slot) + ".sav.txt"
EndProcedure

Procedure MainLoop(List WorldFiles.s())
  Define lastEnemyMS.i = ElapsedMilliseconds()
  Define lastObjMS.i = ElapsedMilliseconds()
  Define lastEditorAutosaveMS.i = ElapsedMilliseconds()
  Define quit.b
  Define ev.i

  Repeat
    Repeat
      ev = WindowEvent()
      Select ev
        Case #PB_Event_CloseWindow
          If ConfirmExit()
            If EditMode
              ; Safety net: write an autosave snapshot on exit.
              Define autoPath.s
              autoPath = GetPathPart(ProgramFilename()) + #APP_NAME + "_editor_autosave.txt"
              SaveWorldAutosave(autoPath)
            EndIf
            quit = #True
          EndIf
      EndSelect
    Until ev = 0

    ExamineKeyboard()

    If KeyHit(#PB_Key_Escape)
      If ConfirmExit()
        If EditMode
          ; Safety net: write an autosave snapshot on exit.
          Define autoPath.s
          autoPath = GetPathPart(ProgramFilename()) + #APP_NAME + "_editor_autosave.txt"
          SaveWorldAutosave(autoPath)
        EndIf
        quit = #True
      EndIf
    EndIf

    If KeyHit(#PB_Key_F2)
      If EditMode
        ; Safety net: write an autosave snapshot when leaving editor mode.
        Define autoPath.s
        autoPath = GetPathPart(ProgramFilename()) + #APP_NAME + "_editor_autosave.txt"
        SaveWorldAutosave(autoPath)

        StopEditor()
      Else
        StartEditor()
        lastEditorAutosaveMS = ElapsedMilliseconds()
      EndIf
    EndIf

    If KeyHit(#PB_Key_F1) And EditMode = 0
      OpenHelpDialog(#False)
    EndIf

    If KeyHit(#PB_Key_F11) And EditMode
      World\BangOneShot = Bool(World\BangOneShot = 0)
      If World\BangOneShot
        SetStatus("! markers set to one-shot (F11)")
      Else
        SetStatus("! markers set to repeat (F11)")
      EndIf
      SavePrefs()
    EndIf

    If KeyHit(#PB_Key_F12)
      If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
        DebugWindowSizing = Bool(DebugWindowSizing = 0)
        If DebugWindowSizing
          SetStatus("Debug window sizing ON (Shift+F12)")
        Else
          SetStatus("Debug window sizing OFF (Shift+F12)")
        EndIf
      Else
        DebugOverlay = Bool(DebugOverlay = 0)
        If DebugOverlay
          SetStatus("Debug overlay ON (F12)")
        Else
          SetStatus("Debug overlay OFF (F12)")
        EndIf
      EndIf
      SavePrefs()
    EndIf

    Define runHeld.b = Bool(KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift))
    Define ctrlHeld.b = Bool(KeyboardPushed(#PB_Key_LeftControl) Or KeyboardPushed(#PB_Key_RightControl))

      ; Preferences hotkeys (handy when running from IDE/temp exe paths)
      If ctrlHeld And KeyHit(#PB_Key_S)
        PrefWinX = WindowX(0)
        PrefWinY = WindowY(0)
        PrefWinW = WindowWidth(0)
        PrefWinH = WindowHeight(0)
        PrefLevelsDir = LevelsDir
        SavePrefs()
        SetStatus("Saved prefs: " + PrefGetPath(), 5000)
      EndIf
 
      If ctrlHeld And KeyHit(#PB_Key_L)
        LoadPrefs()
        If SfxReady
          BuildSfxCache()
        EndIf
        SetStatus("Loaded prefs: " + PrefGetPath(), 5000)
      EndIf

      ; Quicksave slot controls.
      If ctrlHeld And KeyHit(#PB_Key_F5)
        SetQuickSaveSlot(GetQuickSaveSlot() + 1)
        SetStatus("Quicksave slot: " + Str(GetQuickSaveSlot()), 2500)
      EndIf
      If ctrlHeld And KeyHit(#PB_Key_F9)
        SetQuickSaveSlot(GetQuickSaveSlot() - 1)
        SetStatus("Quicksave slot: " + Str(GetQuickSaveSlot()), 2500)
      EndIf

    ; Quick diagnostics: re-run startup sanity checks.
    If ctrlHeld And KeyHit(#PB_Key_T)
      BuildWorldList(WorldFiles())
      If StartupSelfTest(WorldFiles())
        SetStatus("Startup self-test OK", 2500)
      EndIf
    EndIf

    If EditMode
      ; Periodic editor autosave (every 3 minutes).
      ; Writes next to the executable and does not change World\FilePath.
      If ElapsedMilliseconds() - lastEditorAutosaveMS > 180000
        Define autoPath.s
        autoPath = GetPathPart(ProgramFilename()) + #APP_NAME + "_editor_autosave.txt"
        If SaveWorldAutosave(autoPath)
          SetStatus("Autosaved: " + GetFilePart(autoPath), 2500)
        EndIf
        lastEditorAutosaveMS = ElapsedMilliseconds()
      EndIf

      If runHeld
        If KeyRepeat(#PB_Key_Left, 170, 40)
          CursorX - 1
        ElseIf KeyRepeat(#PB_Key_Right, 170, 40)
          CursorX + 1
        ElseIf KeyRepeat(#PB_Key_Up, 170, 40)
          CursorY - 1
        ElseIf KeyRepeat(#PB_Key_Down, 170, 40)
          CursorY + 1
        EndIf
      Else
        If KeyRepeat(#PB_Key_Left)
          CursorX - 1
        ElseIf KeyRepeat(#PB_Key_Right)
          CursorX + 1
        ElseIf KeyRepeat(#PB_Key_Up)
          CursorY - 1
        ElseIf KeyRepeat(#PB_Key_Down)
          CursorY + 1
        EndIf
      EndIf

      CursorX = Clamp(CursorX, 0, #MAP_W - 1)
      CursorY = Clamp(CursorY, 0, #MAP_H - 1)

      If KeyHit(#PB_Key_Tab)
        CycleBrush()
      EndIf

      If KeyHit(#PB_Key_Space) Or KeyHit(#PB_Key_Return)
        PaintAtCursor()
      EndIf

      If KeyHit(#PB_Key_Delete)
        SetCell(CursorX, CursorY, Asc(" "))
        SetCellColor(CursorX, CursorY, BrushColor)
      EndIf

      ; Tile color editing (editor mode):
      ; - C: set brush color from current cursor cell
      ; - [ and ]: decrement/increment brush color
      
      If KeyHit(#PB_Key_C)
        Protected bPick.i = CurBoard()
        If bPick >= 0 And bPick < BoardCount
          BrushColor = Boards(bPick)\Color[CursorX + CursorY * #MAP_W]
          SetStatus("Brush color picked: " + Str(BrushColor), 1200)
        EndIf
      EndIf

      If KeyHit(#PB_Key_LeftBracket)
        BrushColor = Clamp(BrushColor - 1, 0, 255)
      EndIf
      If KeyHit(#PB_Key_RightBracket)
        BrushColor = Clamp(BrushColor + 1, 0, 255)
      EndIf

      If KeyHit(#PB_Key_F1)
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          OpenBoardDialog()
        Else
          OpenHelpDialog(#True)
        EndIf
      EndIf

      If KeyHit(#PB_Key_F3)
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          OpenPassageDialog()
        Else
          OpenObjectDialog(GetObjectIdAt(CurBoard(), CursorX, CursorY))
        EndIf
      EndIf

      If KeyHit(#PB_Key_F4)
        If DeleteObjectAt(CurBoard(), CursorX, CursorY)
          SetStatus("Deleted object.")
        EndIf
      EndIf

      If KeyHit(#PB_Key_F10)
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          OpenWorldDialog()
        Else
          OpenSoundDialog()
        EndIf
      EndIf

      ; Quick compose for current board music.
      If ctrlHeld And KeyHit(#PB_Key_M)
        OpenBoardMusicDialog(CurBoard())
      EndIf

      If KeyHit(#PB_Key_F6)
        EditorPrevBoard()
      EndIf

      If KeyHit(#PB_Key_F7)
        EditorNextBoard()
      EndIf

      If KeyHit(#PB_Key_F8)
        EditorNewBoard()
      EndIf

      If KeyHit(#PB_Key_F5)
        Define savePath.s
        savePath = SaveFileRequester("Save world", World\FilePath, #APP_NAME + " world (*.txt)|*.txt", 0)
        If savePath = "" And LevelsDir <> ""
          savePath = SaveFileRequester("Save world", LevelsDir + GetFilePart(World\FilePath), #APP_NAME + " world (*.txt)|*.txt", 0)
        EndIf
        If savePath <> ""
          SaveWorld(savePath)
          BuildWorldList(WorldFiles())
        EndIf
      EndIf

      If KeyHit(#PB_Key_F9)
        Define loadPath.s
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          loadPath = GetPathPart(ProgramFilename()) + #APP_NAME + "_editor_autosave.txt"
        Else
          loadPath = OpenFileRequester("Load world", LevelsDir, #APP_NAME + " world (*.txt)|*.txt", 0)
        EndIf

        If loadPath <> "" And FileSize(loadPath) > 0
          LoadWorld(loadPath)
          Score = 0 : Keys = 0 : ClearMap(ColorKeys()) : Health = 5
          TorchStepsLeft = 0 : LanternStepsLeft = 0
          DeathPending = #False : DeathAtMS = 0 : DeathFadeUntilMS = 0
          SetStatus("Loaded world: " + World\Name + " (" + Str(BoardCount) + " boards, " + Str(ListSize(Objects())) + " objects)")
        Else
          If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
            SetStatus("Autosave not found: " + #APP_NAME + "_editor_autosave.txt", 2500)
          EndIf
        EndIf
      EndIf

    Else
      RebuildObjectOverlay()

      ; Quicksave/quickload in play mode only.
      ; (F5/F9 are world save/load in editor.)
      
      If KeyHit(#PB_Key_F5)
        Define savePath.s
        Define saveDir.s
        saveDir = GetSaveGamesDir()
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          savePath = SaveFileRequester("Save game", saveDir, #APP_NAME + " savegame (*.sav.txt)|*.sav.txt", 0)
        Else
          savePath = GetQuickSavePath()
        EndIf

        If savePath <> ""
          If SaveGame(savePath)
            SetStatus("Saved game: " + GetFilePart(savePath), 2500)
          Else
            SetStatus("Save failed.", 2500)
          EndIf
        EndIf
      EndIf

      If KeyHit(#PB_Key_F9)
        Define loadPath.s
        Define saveDir.s
        saveDir = GetSaveGamesDir()
        If KeyboardPushed(#PB_Key_LeftShift) Or KeyboardPushed(#PB_Key_RightShift)
          loadPath = OpenFileRequester("Load game", saveDir, #APP_NAME + " savegame (*.sav.txt)|*.sav.txt", 0)
        Else
          loadPath = GetQuickSavePath()
        EndIf

        If loadPath <> ""
          If LoadGame(loadPath)
            SetStatus("Loaded game: " + GetFilePart(loadPath), 2500)
          Else
            SetStatus("Load failed.", 2500)
          EndIf
        EndIf
      EndIf

      ; Fishing: press F when next to a water object (w)
      If KeyHit(#PB_Key_F)
        Protected nearWater.b
        Protected idx.i

        nearWater = #False

        idx = (PlayerX - 1) + PlayerY * #MAP_W
        If PlayerX > 0 And ObjOverlayChar(idx) = Asc("w") : nearWater = #True : EndIf

        idx = (PlayerX + 1) + PlayerY * #MAP_W
        If PlayerX < #MAP_W - 1 And ObjOverlayChar(idx) = Asc("w") : nearWater = #True : EndIf

        idx = PlayerX + (PlayerY - 1) * #MAP_W
        If PlayerY > 0 And ObjOverlayChar(idx) = Asc("w") : nearWater = #True : EndIf

        idx = PlayerX + (PlayerY + 1) * #MAP_W
        If PlayerY < #MAP_H - 1 And ObjOverlayChar(idx) = Asc("w") : nearWater = #True : EndIf

        If nearWater
          Protected roll.i
          roll = Random(99)

          ; ~35% total catch rate; split into a few outcomes.
          If roll < 12
            ScriptItems("BOOT") + 1
            SetStatus("You fished up an old boot...  (Boots: " + Str(ScriptItems("BOOT")) + ")", 2500)
          ElseIf roll < 22
            ScriptItems("TREASURE") + 1
            Score + 5
            SetStatus("Lucky! You found treasure in the water.  (+5 score)", 3000)
          ElseIf roll < 35
            ScriptItems("FISH") + 1
            SetStatus("You caught a fish!  (Fish: " + Str(ScriptItems("FISH")) + ")", 2500)
          Else
            SetStatus("No bites...", 2000)
          EndIf
        Else
          SetStatus("You need to be next to water to fish.", 2500)
        EndIf
      EndIf

      ; Title-screen convenience: Space/Enter triggers :ENTER on board 0 only.
      If CurBoard() = 0 And (KeyHit(#PB_Key_Space) Or KeyHit(#PB_Key_Return))
        ForEach Objects()
          If Objects()\Alive And Objects()\Board = 0
            TriggerObjectLabel(Objects()\Id, "ENTER")
          EndIf
        Next
      EndIf

      If DeathPending
        If ElapsedMilliseconds() - DeathAtMS > World\DeathRespawnDelayMS
          RespawnPlayer()
        EndIf
      EndIf

      If Health > 0 And DeathPending = 0
        ; One move per frame (no diagonal double-step)
        If runHeld
          If KeyRepeat(#PB_Key_Left, 170, 40)
            TryMovePlayer(-1, 0)
          ElseIf KeyRepeat(#PB_Key_Right, 170, 40)
            TryMovePlayer(1, 0)
          ElseIf KeyRepeat(#PB_Key_Up, 170, 40)
            TryMovePlayer(0, -1)
          ElseIf KeyRepeat(#PB_Key_Down, 170, 40)
            TryMovePlayer(0, 1)
          EndIf
        Else
          If KeyRepeat(#PB_Key_Left)
            TryMovePlayer(-1, 0)
          ElseIf KeyRepeat(#PB_Key_Right)
            TryMovePlayer(1, 0)
          ElseIf KeyRepeat(#PB_Key_Up)
            TryMovePlayer(0, -1)
          ElseIf KeyRepeat(#PB_Key_Down)
            TryMovePlayer(0, 1)
          EndIf
        EndIf
      EndIf

      If KeyHit(#PB_Key_R)
        LoadWorldByIndex(WorldIndex, WorldFiles())
        SetStatus("Restarted.")
      EndIf

      If KeyHit(#PB_Key_PageUp)
        LoadWorldByIndex(WorldIndex - 1, WorldFiles())
      EndIf

      If KeyHit(#PB_Key_PageDown)
        LoadWorldByIndex(WorldIndex + 1, WorldFiles())
      EndIf

      If ElapsedMilliseconds() - lastEnemyMS > 220
        lastEnemyMS = ElapsedMilliseconds()
        If Health > 0
          UpdateEnemies()
        EndIf
      EndIf

      If ElapsedMilliseconds() - lastObjMS > 120
        lastObjMS = ElapsedMilliseconds()
        If Health > 0
          UpdateObjects()
        EndIf
      EndIf
    EndIf

    DrawWorld()
    Delay(10)
  Until quit
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 355
; FirstLine = 480
; Folding = --
; EnableXP
; DPIAware