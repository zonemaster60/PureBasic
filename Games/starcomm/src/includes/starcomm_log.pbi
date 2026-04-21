; starcomm_log.pbi
; Ring-buffer log (LogLine, PrintLog), stardate, captain's log, crash handler, init logging
; XIncluded from starcomm.pb

Procedure InitLogging()
  AppendFileLine(gSessionLogPath, "---")
  AppendFileLine(gSessionLogPath, Timestamp() + " session start")
  AppendFileLine(gSessionLogPath, "data=" + GetFilePart(gDatPath) + " (fallback " + GetFilePart(gIniPath) + ")")
EndProcedure

Procedure CrashHandler()
  ; Called by OnErrorCall(); keep this short/safe.
  Protected msg.s
  msg = Timestamp() + " crash"
  msg + " | msg=" + ErrorMessage()
  msg + " | code=" + Str(ErrorCode())
  msg + " | file=" + ErrorFile()
  msg + " | line=" + Str(ErrorLine())
  msg + " | addr=" + Str(ErrorAddress())
  msg + " | mode=" + Str(gMode)
  msg + " | loc=" + Str(gMapX) + "," + Str(gMapY) + "," + Str(gx) + "," + Str(gy)
  msg + " | last_cmd=" + gLastCmdLine
  AppendFileLine(gCrashLogPath, msg)
  AppendFileLine(gSessionLogPath, msg)
EndProcedure

Procedure LogLine(s.s)
  gLog(gLogPos) = s
  gLogPos + 1
  If gLogPos > ArraySize(gLog())
    gLogPos = 0
  EndIf

  AppendFileLine(gSessionLogPath, Timestamp() + " " + s)
EndProcedure

Procedure PrintLog()
  Protected n.i = ArraySize(gLog()) + 1
  Protected i.i, idx.i, line.s
  For i = 0 To n - 1
    idx = (gLogPos + i) % n
    line = gLog(idx)
    If line <> ""
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print("- ")
      ResetColor()
      PrintN(line)
    EndIf
  Next
EndProcedure

Procedure AdvanceStardate(steps.i = 1)
  ; Each turn advances stardate by 0.1 per step
  gStardate = gStardate + (0.1 * steps)
  ; Every 10 turns = 1 day
  Protected totalTurns.i = Int(gStardate * 10) - 250000
  gGameDay = Int(totalTurns / 10) + 1
EndProcedure

Procedure AdvanceGameTurn(steps.i = 1)
  Protected i.i
  For i = 1 To steps
    gGameTurn + 1
    If gGameTurn % 50 = 0 And gBankBalance > 0
      Protected interest.i = Int(gBankBalance * 0.01)
      If interest < 1 : interest = 1 : EndIf
      gBankBalance + interest
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN("BANK NOTIFICATION: Interest earned! (+" + Str(interest) + " credits)")
      ResetColor()
    EndIf
    GenerateCheatCode()
  Next
EndProcedure

Procedure.s FormatStardate()
  Protected dayStr.s = "Day " + Str(gGameDay)
  Protected stardateStr.s = " [" + FormatNumber(gStardate, 1) + "]"
  ProcedureReturn dayStr + stardateStr
EndProcedure

Procedure AddCaptainLog(entry.s)
  ; Prepend stardate to entry
  Protected loggedEntry.s = FormatStardate() + " " + entry
  
  If gCaptainLogCount < ArraySize(gCaptainLog())
    gCaptainLog(gCaptainLogCount) = loggedEntry
    gCaptainLogCount = gCaptainLogCount + 1
  Else
    ; Log is full - archive it
    If gTotalArchives < 10
      ; Archive current log
      gTotalArchives + 1
      Protected arcNum.i = gTotalArchives
      
      ; Copy current log to archive
      Protected j.i
      Select arcNum
        Case 1
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive1(j) = gCaptainLog(j)
          Next
          gArchive1Count(1) = ArraySize(gCaptainLog())
        Case 2
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive2(j) = gCaptainLog(j)
          Next
          gArchive1Count(2) = ArraySize(gCaptainLog())
        Case 3
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive3(j) = gCaptainLog(j)
          Next
          gArchive1Count(3) = ArraySize(gCaptainLog())
        Case 4
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive4(j) = gCaptainLog(j)
          Next
          gArchive1Count(4) = ArraySize(gCaptainLog())
        Case 5
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive5(j) = gCaptainLog(j)
          Next
          gArchive1Count(5) = ArraySize(gCaptainLog())
        Case 6
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive6(j) = gCaptainLog(j)
          Next
          gArchive1Count(6) = ArraySize(gCaptainLog())
        Case 7
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive7(j) = gCaptainLog(j)
          Next
          gArchive1Count(7) = ArraySize(gCaptainLog())
        Case 8
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive8(j) = gCaptainLog(j)
          Next
          gArchive1Count(8) = ArraySize(gCaptainLog())
        Case 9
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive9(j) = gCaptainLog(j)
          Next
          gArchive1Count(9) = ArraySize(gCaptainLog())
        Case 10
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive10(j) = gCaptainLog(j)
          Next
          gArchive1Count(10) = ArraySize(gCaptainLog())
      EndSelect
      
      ; Clear current log and add new entry
      Protected k.i
      For k = 0 To ArraySize(gCaptainLog()) - 1
        gCaptainLog(k) = ""
      Next
      gCaptainLog(0) = loggedEntry
      gCaptainLogCount = 1
    Else
      ; All archives full - shift current log like before
      Protected m.i
      For m = 0 To ArraySize(gCaptainLog()) - 2
        gCaptainLog(m) = gCaptainLog(m + 1)
      Next
      gCaptainLog(ArraySize(gCaptainLog())) = loggedEntry
    EndIf
  EndIf
EndProcedure

Procedure PrintCaptainLog(search.s)
  Protected shownCount.i, a.i, viewArc.i, startIdx.i, j.i
  Protected searchArc.s, arcPrefix.s, arcNum.s, arrPtr.s, entryLower.s
  Protected maxShow.i = 20
  Protected i.i
  
  PrintDivider()
  
  ; Check for archive selection
  search = TrimLower(search)
  shownCount = 0
  
  ; Handle archive commands
  If search = "archives" Or search = "archive"
    PrintN("Captain's Log Archives:")
    PrintN("")
    PrintN("Current Log: " + Str(gCaptainLogCount) + " entries")
    For a = 1 To gTotalArchives
      PrintN("Archive " + Str(a) + ": " + Str(gArchive1Count(a)) + " entries")
    Next
    If gTotalArchives = 0
      PrintN("No archives yet.")
    EndIf
    PrintN("")
    PrintN("Use LOG to view current, or LOG ARCHIVE <1-" + Str(gTotalArchives) + "> to view an archive.")
    PrintDivider()
    ProcedureReturn
  EndIf
  
  arcPrefix = "archive "
  If FindString(search, arcPrefix) = 1
    ; View specific archive
    arcNum = RemoveString(search, arcPrefix)
    arcNum = RemoveString(arcNum, " ")
    viewArc = ParseIntSafe(arcNum, 0)
    
    If viewArc < 1 Or viewArc > gTotalArchives
      PrintN("Archive " + Str(viewArc) + " does not exist.")
      PrintDivider()
      ProcedureReturn
    EndIf
    
    ; Show archive
    PrintN("Captain's Log - Archive " + Str(viewArc) + ":")
    PrintN("")
    
    startIdx = gArchive1Count(viewArc) - 20
    If startIdx < 0 : startIdx = 0 : EndIf
    
    searchArc = RemoveString(search, "archive " + arcNum)
    searchArc = Trim(searchArc)
    
    For j = startIdx To gArchive1Count(viewArc) - 1
      Select viewArc
        Case 1 : arrPtr = gCaptainArchive1(j)
        Case 2 : arrPtr = gCaptainArchive2(j)
        Case 3 : arrPtr = gCaptainArchive3(j)
        Case 4 : arrPtr = gCaptainArchive4(j)
        Case 5 : arrPtr = gCaptainArchive5(j)
        Case 6 : arrPtr = gCaptainArchive6(j)
        Case 7 : arrPtr = gCaptainArchive7(j)
        Case 8 : arrPtr = gCaptainArchive8(j)
        Case 9 : arrPtr = gCaptainArchive9(j)
        Case 10 : arrPtr = gCaptainArchive10(j)
      EndSelect
      
      If arrPtr <> ""
        If searchArc <> ""
          If FindString(TrimLower(arrPtr), searchArc) > 0
            PrintN(arrPtr)
            shownCount + 1
          EndIf
        Else
          PrintN(arrPtr)
          shownCount + 1
        EndIf
      EndIf
    Next
    
    If shownCount = 0
      If searchArc <> ""
        PrintN("No entries found matching: " + searchArc)
      Else
        PrintN("No entries in this archive.")
      EndIf
    EndIf
    PrintN("")
    PrintN("Total entries: " + Str(gArchive1Count(viewArc)))
    PrintDivider()
    ProcedureReturn
  EndIf
  
  ; Show current log
  PrintN("Captain's Log:")
  PrintN("")
  
  If search = ""
    ; Show last entries
    startIdx = gCaptainLogCount - maxShow
    If startIdx < 0 : startIdx = 0 : EndIf
    
    For i = startIdx To gCaptainLogCount - 1
      If i >= 0 And i < ArraySize(gCaptainLog()) + 1
        If gCaptainLog(i) <> ""
          PrintN(gCaptainLog(i))
          shownCount = shownCount + 1
        EndIf
      EndIf
    Next
  Else
    ; Search entries
    For i = 0 To gCaptainLogCount - 1
      If gCaptainLog(i) <> ""
        entryLower = TrimLower(gCaptainLog(i))
        If FindString(entryLower, search) > 0
          PrintN(gCaptainLog(i))
          shownCount = shownCount + 1
        EndIf
      EndIf
    Next
  EndIf
  
  If shownCount = 0
    If search <> ""
      PrintN("No entries found matching: " + search)
    Else
      PrintN("No log entries yet.")
    EndIf
  EndIf
  PrintN("")
  PrintN("Total entries: " + Str(gCaptainLogCount))
  If gTotalArchives > 0
    PrintN("Archives available: " + Str(gTotalArchives))
  EndIf
  PrintN("Usage: LOG - show recent | LOG <search> - search entries")
  PrintN("       LOG ARCHIVES - list all archives")
  PrintN("       LOG ARCHIVE <1-10> - view archive (add search term)")
  PrintN("       LOG PURGE YES - delete all current log entries")
  PrintDivider()
EndProcedure
