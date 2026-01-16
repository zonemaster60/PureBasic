;------------------------------------------------------------------------------
; Startup self-test helpers
;------------------------------------------------------------------------------

Procedure.b StartupSelfTest(List WorldFiles.s())
  Protected ok.b = #True
  Protected msg.s = ""
  Protected firstIssue.s = ""
  Protected b.i
  Protected idx.i

  ; Levels directory sanity.
  If LevelsDir <> ""
    If FileSize(LevelsDir) <> -2
      ok = #False
      firstIssue = "LevelsDir invalid"
      msg + "LevelsDir is not a directory:" + #LF$ + LevelsDir + #LF$
    Else
      If ListSize(WorldFiles()) <= 0
        ok = #False
        firstIssue = "No world files"
        msg + "No world files found in LevelsDir." + #LF$ + "(Expected *.txt worlds, like title1.txt)" + #LF$
      EndIf
    EndIf
  Else
    ; If no LevelsDir, worlds cannot load.
    If ListSize(WorldFiles()) <= 0
      ok = #False
      firstIssue = "LevelsDir empty"
      msg + "LevelsDir is empty and no world files are available." + #LF$
    EndIf
  EndIf

  ; World load sanity.
  If BoardCount <= 0
    ok = #False
    firstIssue = "No boards loaded"
    msg + "No boards loaded (BoardCount <= 0)." + #LF$
  EndIf

  If World\CurrentBoard < 0 Or World\CurrentBoard >= BoardCount
    ok = #False
    firstIssue = "Invalid current board"
    msg + "Invalid current board index: " + Str(World\CurrentBoard) + " / " + Str(BoardCount) + #LF$
  EndIf

  ; Player placement sanity.
  b = CurBoard()
  If b >= 0 And b < BoardCount
    If PlayerX < 0 Or PlayerX >= #MAP_W Or PlayerY < 0 Or PlayerY >= #MAP_H
      ok = #False
      If firstIssue = "" : firstIssue = "Bad player coords" : EndIf
      ResetPlayerToBoardStart()
      msg + "Player position out of bounds; reset to board start." + #LF$
    Else
      idx = PlayerX + PlayerY * #MAP_W
      If idx >= 0 And idx < #MAP_W * #MAP_H
        If Solid(Boards(b)\Map[idx])
          ok = #False
          If firstIssue = "" : firstIssue = "Player on solid" : EndIf
          ResetPlayerToBoardStart()
          msg + "Player spawned on a solid tile; reset to board start." + #LF$
        EndIf
      EndIf
    EndIf
  EndIf

  ; Store results for debug overlay.
  If ok
    SelfTestSummary = "OK"
    SelfTestDetails = ""
  Else
    If firstIssue = "" : firstIssue = "FAIL" : EndIf
    SelfTestSummary = "FAIL: " + firstIssue
    SelfTestDetails = Trim(msg)

    If DebugOverlay
      SetStatus("Startup self-test FAILED (DBG overlay has details)", 8000)
    Else
      SetStatus("Startup self-test FAILED (see dialog)", 8000)
      MessageRequester(#APP_NAME + " Self-Test", SelfTestDetails, #PB_MessageRequester_Error)
    EndIf
  EndIf

  ProcedureReturn ok
EndProcedure
