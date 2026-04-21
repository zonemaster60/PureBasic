; starcomm_macros.pbi
; Macro system: InitMacroFolder, GetNextInput, MacroList, MacroCreate, MacroRun, MacroChainInsert, MacroShow, MacroEdit, MacroDelete
; XIncluded from starcomm.pb

Procedure InitMacroFolder()
  If FileSize(MacroPath) = -1
    CreateDirectory(MacroPath)
  EndIf
EndProcedure

Procedure.i NormalizeMacroName(name.s, *outName.String)
  Protected trimmed.s = Trim(name)
  If trimmed = "" : ProcedureReturn 0 : EndIf
  If IsSafeFileToken(trimmed) = 0
    ProcedureReturn 0
  EndIf
  *outName\s = trimmed
  ProcedureReturn 1
EndProcedure

Procedure CompactMacroQueue()
  Protected remaining.i = gMacroQueueSize - gMacroQueuePos
  Protected i.i
  If remaining <= 0
    gMacroQueueSize = 0
    gMacroQueuePos = 0
    ProcedureReturn
  EndIf
  If gMacroQueuePos <= 0 : ProcedureReturn : EndIf
  For i = 0 To remaining - 1
    gMacroQueue(i) = gMacroQueue(gMacroQueuePos + i)
  Next
  For i = remaining To #MACRO_QUEUE_MAX - 1
    gMacroQueue(i) = ""
  Next
  gMacroQueueSize = remaining
  gMacroQueuePos = 0
EndProcedure

Procedure FinishMacroPlaybackIfDone(*completed.String = 0)
  If gMacroQueuePos >= gMacroQueueSize
    If *completed
      *completed\s = gMacroPlaybackName
    EndIf
    gMacroPlaybackActive = 0
    gMacroQueueSize = 0
    gMacroQueuePos = 0
  EndIf
EndProcedure

Procedure.i LoadMacroLines(name.s, Array outLines.s(1), *outCount.Integer, allowRepeat.i)
  Protected safeName.String
  Protected fpath.s
  Protected fid.i
  Protected rawCount.i = 0
  Protected overflow.i = 0
  Protected line.s
  Protected Dim rawLines.s(#MACRO_FILE_LINE_MAX - 1)
  Protected ri.i
  Protected rj.i
  Protected rk.i
  Protected repeatN.i
  Protected repeatStart.i
  Protected repeatEnd.i
  Protected outCount.i = 0

  *outCount\i = 0
  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn 0
  EndIf

  fpath = MacroPath + safeName\s + ".txt"
  If FileSize(fpath) < 0
    PrintN("Macro '" + safeName\s + "' not found. Use MACRO LIST to see saved macros.")
    ProcedureReturn 0
  EndIf

  fid = ReadFile(#PB_Any, fpath)
  If fid = 0
    PrintN("ERROR: Could not open macro file: " + fpath)
    ProcedureReturn 0
  EndIf

  While Not Eof(fid) And rawCount < #MACRO_FILE_LINE_MAX
    line = Trim(ReadString(fid))
    If line <> "" And Left(line, 1) <> ";"
      rawLines(rawCount) = line
      rawCount + 1
    EndIf
  Wend
  If Eof(fid) = 0
    overflow = 1
  EndIf
  CloseFile(fid)

  If allowRepeat = 0
    For ri = 0 To rawCount - 1
      outLines(ri) = rawLines(ri)
    Next
    outCount = rawCount
  Else
    ri = 0
    While ri < rawCount
      If TrimLower(TokenAt(rawLines(ri), 1)) = "repeat"
        repeatN = ClampInt(ParseIntSafe(TokenAt(rawLines(ri), 2), 1), 1, 20)
        repeatStart = ri + 1
        repeatEnd = -1
        rj = ri + 1
        While rj < rawCount
          If TrimLower(rawLines(rj)) = "end_repeat"
            repeatEnd = rj
            Break
          EndIf
          rj + 1
        Wend
        If repeatEnd >= 0
          For rk = 1 To repeatN
            For rj = repeatStart To repeatEnd - 1
              If outCount < #MACRO_FILE_LINE_MAX
                outLines(outCount) = rawLines(rj)
                outCount + 1
              Else
                overflow = 1
              EndIf
            Next
          Next
          ri = repeatEnd + 1
        Else
          overflow = 1
          ri + 1
        EndIf
      ElseIf TrimLower(rawLines(ri)) = "end_repeat"
        overflow = 1
        ri + 1
      Else
        If outCount < #MACRO_FILE_LINE_MAX
          outLines(outCount) = rawLines(ri)
          outCount + 1
        Else
          overflow = 1
        EndIf
        ri + 1
      EndIf
    Wend
  EndIf

  *outCount\i = outCount
  If overflow
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("[MACRO] Warning: '" + safeName\s + "' exceeded parsing limits; extra/invalid lines were skipped.")
    ResetColor()
  EndIf
  ProcedureReturn 1
EndProcedure

;==============================================================================
; GetNextInput()
; Replaces Input() in the main CMD> loop. When a macro is playing back, returns
; the next queued command without blocking. PAUSE lines prompt the user to press
; Enter (and optionally type 'stop'). Falls through to real Input() when idle.
;==============================================================================
CompilerIf Defined(TEST_MODE, #PB_Constant)
Global gTestInputLoaded.i = 0
Global Dim gTestInputLines.s(0)
Global gTestInputCount.i = 0
Global gTestInputPos.i = 0

CompilerIf Defined(TEST_SCRIPT, #PB_Constant) = 0
  #TEST_SCRIPT = "test_scripts/smoke_start_quit.txt"
CompilerEndIf

Procedure LoadTestInputScript()
  If gTestInputLoaded
    ProcedureReturn
  EndIf

  gTestInputLoaded = 1

  Protected testScriptName.s = ReplaceString(#TEST_SCRIPT, "'", "")
  testScriptName = ReplaceString(testScriptName, Chr(34), "")
  Protected testPath.s = AppPath + testScriptName
  Protected f.i
  Protected line.s

  If FileSize(testPath) < 0
    ProcedureReturn
  EndIf

  f = ReadFile(#PB_Any, testPath)
  If f = 0
    ProcedureReturn
  EndIf

  While Eof(f) = 0
    line = ReadString(f)
    If gTestInputCount > ArraySize(gTestInputLines())
      ReDim gTestInputLines(gTestInputCount)
    EndIf
    gTestInputLines(gTestInputCount) = line
    gTestInputCount + 1
  Wend

  CloseFile(f)
EndProcedure
CompilerEndIf

Procedure.s ReadConsoleInput()
  CompilerIf Defined(TEST_MODE, #PB_Constant)
    LoadTestInputScript()
    If gTestInputPos < gTestInputCount
      Protected scriptedLine.s = gTestInputLines(gTestInputPos)
      gTestInputPos + 1
      PrintN(scriptedLine)
      ProcedureReturn scriptedLine
    EndIf
    ProcedureReturn Chr(4)
  CompilerElse
    ProcedureReturn Input()
  CompilerEndIf
EndProcedure

Procedure.s GetNextInput()
  ; All locals declared up-front (EnableExplicit + loop-safe)
  Protected nextCmd.s    = ""
  Protected pauseResp.s  = ""
  Protected metaVerb.s   = ""
  Protected deferCmd.s   = ""
  Protected condOK.i     = 0
  Protected delayMs.i    = 0
  Protected mtok.i       = 0
  Protected mtokStr.s    = ""
  Protected completedName.s = ""

  While gMacroPlaybackActive = 1 And gMacroQueuePos < gMacroQueueSize
    nextCmd  = gMacroQueue(gMacroQueuePos)
    gMacroQueuePos + 1

    metaVerb = TrimLower(TokenAt(nextCmd, 1))

    ; ---- PAUSE ----
    If metaVerb = "pause"
      ConsoleColor(#C_YELLOW, #C_BLACK)
      Print("[MACRO] Paused press Enter to continue (type 'stop' to abort) > ")
      ResetColor()
      pauseResp = TrimLower(Trim(ReadConsoleInput()))
      pauseResp = ReplaceString(ReplaceString(pauseResp, Chr(13), ""), Chr(10), "")
      If pauseResp = "stop"
        gMacroPlaybackActive = 0
        gMacroQueueSize      = 0
        gMacroQueuePos       = 0
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("[MACRO] Playback stopped by user.")
        ResetColor()
        gMacroPlaybackName = ""
        ProcedureReturn "end"
      EndIf
      FinishMacroPlaybackIfDone(@completedName)
      Continue
    EndIf

    ; ---- DELAY <ms> ----
    If metaVerb = "delay"
      delayMs = ClampInt(ParseIntSafe(TokenAt(nextCmd, 2), 500), 0, 5000)
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      PrintN("[MACRO] Delay " + Str(delayMs) + "ms")
      ResetColor()
      Delay(delayMs)
      FinishMacroPlaybackIfDone(@completedName)
      Continue
    EndIf

    ; ---- CHAIN <macroname> ----
    If metaVerb = "chain"
      MacroChainInsert(TrimLower(TokenAt(nextCmd, 2)))
      FinishMacroPlaybackIfDone(@completedName)
      Continue
    EndIf

    ; ---- IF_* conditional commands ----
    ; Syntax:  IF_<condition> <game command to run if true>
    ; e.g.     IF_FUEL_LOW    DOCK
    ;          IF_HULL_LOW    NAV 270 1
    ;          IF_TORP_EMPTY  NAV 0 5
    If Left(metaVerb, 3) = "if_"
      ; Collect everything from token 2 onward as the deferred action
      deferCmd = ""
      mtok     = 2
      mtokStr  = TokenAt(nextCmd, mtok)
      While mtokStr <> ""
        If deferCmd <> "" : deferCmd + " " : EndIf
        deferCmd + mtokStr
        mtok + 1
        mtokStr = TokenAt(nextCmd, mtok)
      Wend
      condOK = 0
      Select metaVerb
        Case "if_fuel_low"      : If gMacroFuelPct    < 25                               : condOK = 1 : EndIf
        Case "if_hull_low"      : If gMacroHullPct    < 40                               : condOK = 1 : EndIf
        Case "if_shields_low"   : If gMacroShieldsPct < 30                               : condOK = 1 : EndIf
        Case "if_torp_empty"    : If gMacroTorpCount  = 0                                : condOK = 1 : EndIf
        Case "if_cargo_full"    : If gMacroOreMax > 0 And gMacroOre >= gMacroOreMax      : condOK = 1 : EndIf
        Case "if_dilithium_low" : If gMacroDilithium  < 5                                : condOK = 1 : EndIf
        Case "if_docked"        : If gDocked = 1                                         : condOK = 1 : EndIf
        Case "if_not_docked"    : If gDocked = 0                                         : condOK = 1 : EndIf
      EndSelect
      If condOK And deferCmd <> ""
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("[MACRO] COND TRUE:  " + nextCmd + "  →  " + deferCmd)
        ResetColor()
        Delay(350)
        ProcedureReturn deferCmd
      Else
        ConsoleColor(#C_DARKGRAY, #C_BLACK)
        PrintN("[MACRO] COND FALSE: " + nextCmd)
        ResetColor()
      EndIf
      FinishMacroPlaybackIfDone(@completedName)
      Continue
    EndIf

    ; ---- Regular command echo and return to main loop ----
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("[MACRO] ")
    ResetColor()
    PrintN(nextCmd)
    Delay(350)
    LogLine("[MACRO] " + nextCmd)
    FinishMacroPlaybackIfDone(@completedName)
    ProcedureReturn nextCmd
  Wend

  ; Macro finished naturally
  If completedName <> ""
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] '" + completedName + "' completed.")
    ResetColor()
    gMacroPlaybackName = ""
  ElseIf gMacroPlaybackActive = 0 And gMacroPlaybackName <> ""
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] '" + gMacroPlaybackName + "' completed.")
    ResetColor()
    gMacroPlaybackName = ""
  EndIf

  ProcedureReturn ReadConsoleInput()
EndProcedure

;==============================================================================
; MacroList()
; Lists all saved macro files in the macros folder.
;==============================================================================
Procedure MacroList()
  Protected count.i   = 0
  Protected fname.s   = ""
  Protected mname.s   = ""
  Protected fpath.s   = ""
  Protected fid.i     = 0
  Protected lineCnt.i = 0
  Protected fline.s   = ""

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  SAVED MACROS " + MacroPath)
  PrintDivider()
  ResetColor()

  If ExamineDirectory(0, MacroPath, "*.txt")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_File
        fname   = DirectoryEntryName(0)
        mname   = Left(fname, Len(fname) - 4)
        fpath   = MacroPath + fname
        lineCnt = 0
        fid = ReadFile(#PB_Any, fpath)
        If fid
          While Not Eof(fid)
            fline = Trim(ReadString(fid))
            If fline <> "" And Left(fline, 1) <> ";"
              lineCnt + 1
            EndIf
          Wend
          CloseFile(fid)
        EndIf
        Print("  ")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        Print(mname)
        ResetColor()
        PrintN("  (" + Str(lineCnt) + " command(s))")
        count + 1
      EndIf
    Wend
    FinishDirectory(0)
  EndIf

  If count = 0
    PrintN("  No macros found. Use  MACRO CREATE <name>  to make one.")
  EndIf
  PrintN("")
EndProcedure

;==============================================================================
; MacroCreate(name.s)
; Interactive line-by-line macro creation. Saves to macros/<name>.txt
;==============================================================================
Procedure MacroCreate(name.s)
  Protected safeName.String
  Protected fpath.s     = ""
  Protected resp.s      = ""
  Protected fid.i       = 0
  Protected lineCount.i = 0
  Protected entry.s     = ""

  If name = ""
    PrintN("Usage: MACRO CREATE <name>")
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn
  EndIf

  InitMacroFolder()
  fpath = MacroPath + safeName\s + ".txt"

  If FileSize(fpath) >= 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print("Macro '" + safeName\s + "' already exists. Overwrite? (YES) > ")
    ResetColor()
    resp = TrimLower(Trim(Input()))
    resp = ReplaceString(ReplaceString(resp, Chr(13), ""), Chr(10), "")
    If resp <> "yes"
      PrintN("Cancelled.")
      ProcedureReturn
    EndIf
  EndIf

  fid = CreateFile(#PB_Any, fpath)
  If fid = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Could not create macro file: " + fpath)
    ResetColor()
    ProcedureReturn
  EndIf

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  Creating macro: " + safeName\s)
  PrintN("  Enter one game command per line (NAV, SCAN, WARP, MINE, STATUS, etc.)")
  PrintN("  Lines starting with ; are comments.  PAUSE = pause playback for input.")
  PrintN("  Press Enter on an empty line or type END to finish.")
  PrintDivider()
  ResetColor()

  Repeat
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("  " + Str(lineCount + 1) + "> ")
    ResetColor()
    entry = Trim(Input())
    entry = ReplaceString(ReplaceString(entry, Chr(13), ""), Chr(10), "")
    If TrimLower(entry) = "end" Or entry = ""
      Break
    EndIf
    WriteStringN(fid, entry)
    lineCount + 1
    If lineCount >= #MACRO_FILE_LINE_MAX
      PrintN("  Maximum " + Str(#MACRO_FILE_LINE_MAX) + " lines reached.")
      Break
    EndIf
  ForEver

  CloseFile(fid)

  If lineCount = 0
    DeleteFile(fpath)
    PrintN("  No commands entered. Macro not saved.")
  Else
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  Macro '" + safeName\s + "' saved " + Str(lineCount) + " command(s)")
    PrintN("  File: " + fpath)
    ResetColor()
    LogLine("MACRO CREATE: " + safeName\s + " (" + Str(lineCount) + " lines)")
  EndIf
EndProcedure

;==============================================================================
; MacroRun(name.s)
; Loads a macro file into the playback queue. The main loop's GetNextInput()
; will feed each command automatically on subsequent turns.
;==============================================================================
Procedure MacroRun(name.s)
  Protected safeName.String
  Protected loadedCount.Integer
  Protected i.i
  Protected Dim loadedLines.s(#MACRO_FILE_LINE_MAX - 1)

  If name = ""
    PrintN("Usage: MACRO RUN <name>")
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn
  EndIf

  If LoadMacroLines(safeName\s, loadedLines(), @loadedCount, 1) = 0
    ProcedureReturn
  EndIf

  gMacroQueueSize = 0
  gMacroQueuePos  = 0
  For i = 0 To loadedCount\i - 1
    If gMacroQueueSize < #MACRO_QUEUE_MAX
      gMacroQueue(gMacroQueueSize) = loadedLines(i)
      gMacroQueueSize + 1
    Else
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("[MACRO] '" + safeName\s + "' exceeds queue capacity; only first " + Str(#MACRO_QUEUE_MAX) + " commands loaded.")
      ResetColor()
      Break
    EndIf
  Next

  If gMacroQueueSize = 0
    PrintN("Macro '" + safeName\s + "' has no runnable commands.")
    ProcedureReturn
  EndIf

  gMacroPlaybackActive = 1
  gMacroPlaybackName   = safeName\s

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("[MACRO] Running '" + safeName\s + "' " + Str(gMacroQueueSize) + " command(s) queued.")
  PrintN("[MACRO] Commands execute automatically. PAUSE to pause, MACRO STOP to abort.")
  ResetColor()
  LogLine("MACRO RUN: " + safeName\s + " (" + Str(gMacroQueueSize) + " commands)")
EndProcedure

;==============================================================================
; MacroChainInsert(name.s)
; Called by GetNextInput() when a CHAIN <name> line is encountered.
; Loads the sub-macro and splices its commands into the active queue at the
; current playback position, so they run next before the remaining commands.
;==============================================================================
Procedure MacroChainInsert(name.s)
  Protected safeName.String
  Protected subCount.Integer
  Protected spaceAvail.i = 0
  Protected si.i         = 0
  Protected Dim subLines.s(#MACRO_FILE_LINE_MAX - 1)

  If name = ""
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: no macro name given, skipping.")
    ResetColor()
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: invalid macro name, skipping.")
    ResetColor()
    ProcedureReturn
  EndIf

  If LoadMacroLines(safeName\s, subLines(), @subCount, 1) = 0
    ProcedureReturn
  EndIf

  If subCount\i = 0 : ProcedureReturn : EndIf

  CompactMacroQueue()

  ; Clamp to available space
  spaceAvail = #MACRO_QUEUE_MAX - gMacroQueueSize
  If subCount\i > spaceAvail
    subCount\i = spaceAvail
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: queue nearly full, '" + safeName\s + "' truncated to " + Str(subCount\i) + " command(s).")
    ResetColor()
  EndIf

  If subCount\i <= 0 : ProcedureReturn : EndIf

  ; Shift remaining queued commands forward to open a gap at gMacroQueuePos
  For si = gMacroQueueSize - 1 To gMacroQueuePos Step -1
    gMacroQueue(si + subCount\i) = gMacroQueue(si)
  Next si

  ; Splice sub-macro lines into the gap
  For si = 0 To subCount\i - 1
    gMacroQueue(gMacroQueuePos + si) = subLines(si)
  Next si

  gMacroQueueSize + subCount\i

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("[MACRO] CHAIN: spliced '" + safeName\s + "' (" + Str(subCount\i) + " commands) at position " + Str(gMacroQueuePos))
  ResetColor()
EndProcedure

;==============================================================================
; MacroShow(name.s)
; Displays the contents of a macro file with line numbers.
;==============================================================================
Procedure MacroShow(name.s)
  Protected safeName.String
  Protected fpath.s   = ""
  Protected fid.i     = 0
  Protected lineNum.i = 0
  Protected fline.s   = ""

  If name = ""
    PrintN("Usage: MACRO SHOW <name>")
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn
  EndIf

  fpath = MacroPath + safeName\s + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Macro '" + safeName\s + "' not found.")
    ResetColor()
    ProcedureReturn
  EndIf

  fid = ReadFile(#PB_Any, fpath)
  If fid = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Could not read macro file.")
    ResetColor()
    ProcedureReturn
  EndIf

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  MACRO: " + safeName\s)
  PrintDivider()
  ResetColor()

  lineNum = 1
  While Not Eof(fid)
    fline = ReadString(fid)
    If Trim(fline) <> ""
      If Left(Trim(fline), 1) = ";"
        ConsoleColor(#C_DARKGRAY, #C_BLACK)
        PrintN("      " + fline)
        ResetColor()
      Else
        Print("  " + Str(lineNum) + ": ")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN(fline)
        ResetColor()
        lineNum + 1
      EndIf
    EndIf
  Wend
  CloseFile(fid)
  PrintN("")
EndProcedure

;==============================================================================
; MacroEdit(name.s)
; Shows existing macro, confirms replacement, then re-enters interactively.
;==============================================================================
Procedure MacroEdit(name.s)
  Protected safeName.String
  Protected fpath.s     = ""
  Protected rfid.i      = 0
  Protected wfid.i      = 0
  Protected fline.s     = ""
  Protected lineNum.i   = 0
  Protected resp.s      = ""
  Protected entry.s     = ""
  Protected lineCount.i = 0

  If name = ""
    PrintN("Usage: MACRO EDIT <name>")
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn
  EndIf

  InitMacroFolder()
  fpath = MacroPath + safeName\s + ".txt"

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  Editing macro: " + safeName\s)
  ResetColor()

  If FileSize(fpath) >= 0
    rfid = ReadFile(#PB_Any, fpath)
    If rfid
      lineNum = 1
      While Not Eof(rfid)
        fline = ReadString(rfid)
        If Trim(fline) <> ""
          If Left(Trim(fline), 1) = ";"
            ConsoleColor(#C_DARKGRAY, #C_BLACK)
            PrintN("      " + fline)
            ResetColor()
          Else
            Print("  " + Str(lineNum) + ": ")
            ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
            PrintN(fline)
            ResetColor()
            lineNum + 1
          EndIf
        EndIf
      Wend
      CloseFile(rfid)
    EndIf
    PrintN("")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print("  Replace all commands with new input? (YES) > ")
    ResetColor()
    resp = TrimLower(Trim(Input()))
    resp = ReplaceString(ReplaceString(resp, Chr(13), ""), Chr(10), "")
    If resp <> "yes"
      PrintN("Edit cancelled.")
      ProcedureReturn
    EndIf
  Else
    PrintN("  Macro not found, will create as new.")
  EndIf

  wfid = CreateFile(#PB_Any, fpath)
  If wfid = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Could not write macro file: " + fpath)
    ResetColor()
    ProcedureReturn
  EndIf

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("  Enter new commands. Empty line or END to finish.")
  PrintDivider()
  ResetColor()

  Repeat
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("  " + Str(lineCount + 1) + "> ")
    ResetColor()
    entry = Trim(Input())
    entry = ReplaceString(ReplaceString(entry, Chr(13), ""), Chr(10), "")
    If TrimLower(entry) = "end" Or entry = ""
      Break
    EndIf
    WriteStringN(wfid, entry)
    lineCount + 1
    If lineCount >= #MACRO_FILE_LINE_MAX
      PrintN("  Maximum " + Str(#MACRO_FILE_LINE_MAX) + " lines reached.")
      Break
    EndIf
  ForEver

  CloseFile(wfid)

  If lineCount = 0
    DeleteFile(fpath)
    PrintN("  No commands entered. Macro '" + safeName\s + "' removed.")
  Else
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  Macro '" + safeName\s + "' updated " + Str(lineCount) + " command(s).")
    ResetColor()
    LogLine("MACRO EDIT: " + safeName\s + " (" + Str(lineCount) + " lines)")
  EndIf
EndProcedure

;==============================================================================
; MacroDelete(name.s)
; Confirms and deletes a macro file.
;==============================================================================
Procedure MacroDelete(name.s)
  Protected safeName.String
  Protected fpath.s = ""
  Protected resp.s  = ""

  If name = ""
    PrintN("Usage: MACRO DELETE <name>")
    ProcedureReturn
  EndIf

  If NormalizeMacroName(name, @safeName) = 0
    PrintN("Invalid macro name. Use letters, numbers, . _ or -")
    ProcedureReturn
  EndIf

  fpath = MacroPath + safeName\s + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Macro '" + safeName\s + "' not found. Use MACRO LIST to see saved macros.")
    ResetColor()
    ProcedureReturn
  EndIf

  ConsoleColor(#C_YELLOW, #C_BLACK)
  Print("Delete macro '" + safeName\s + "'? (YES) > ")
  ResetColor()
  resp = TrimLower(Trim(Input()))
  resp = ReplaceString(ReplaceString(resp, Chr(13), ""), Chr(10), "")

  If resp = "yes"
    If DeleteFile(fpath)
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN("Macro '" + safeName\s + "' deleted.")
      ResetColor()
      LogLine("MACRO DELETE: " + safeName\s)
    Else
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
      PrintN("ERROR: Could not delete macro file.")
      ResetColor()
    EndIf
  Else
    PrintN("Delete cancelled.")
  EndIf
EndProcedure
