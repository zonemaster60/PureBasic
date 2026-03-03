; starcomm_macros.pbi
; Macro system: InitMacroFolder, GetNextInput, MacroList, MacroCreate, MacroRun, MacroChainInsert, MacroShow, MacroEdit, MacroDelete
; XIncluded from starcomm.pb

Procedure InitMacroFolder()
  If FileSize(MacroPath) = -1
    CreateDirectory(MacroPath)
  EndIf
EndProcedure

;==============================================================================
; GetNextInput()
; Replaces Input() in the main CMD> loop. When a macro is playing back, returns
; the next queued command without blocking. PAUSE lines prompt the user to press
; Enter (and optionally type 'stop'). Falls through to real Input() when idle.
;==============================================================================
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

  While gMacroPlaybackActive = 1 And gMacroQueuePos < gMacroQueueSize
    nextCmd  = gMacroQueue(gMacroQueuePos)
    gMacroQueuePos + 1

    If gMacroQueuePos >= gMacroQueueSize
      gMacroPlaybackActive = 0
    EndIf

    metaVerb = TrimLower(TokenAt(nextCmd, 1))

    ; ---- PAUSE ----
    If metaVerb = "pause"
      ConsoleColor(#C_YELLOW, #C_BLACK)
      Print("[MACRO] Paused press Enter to continue (type 'stop' to abort) > ")
      ResetColor()
      pauseResp = TrimLower(Trim(Input()))
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
      Continue
    EndIf

    ; ---- DELAY <ms> ----
    If metaVerb = "delay"
      delayMs = ClampInt(ParseIntSafe(TokenAt(nextCmd, 2), 500), 0, 5000)
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      PrintN("[MACRO] Delay " + Str(delayMs) + "ms")
      ResetColor()
      Delay(delayMs)
      Continue
    EndIf

    ; ---- CHAIN <macroname> ----
    If metaVerb = "chain"
      MacroChainInsert(TrimLower(TokenAt(nextCmd, 2)))
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
      Continue
    EndIf

    ; ---- Regular command echo and return to main loop ----
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("[MACRO] ")
    ResetColor()
    PrintN(nextCmd)
    Delay(350)
    LogLine("[MACRO] " + nextCmd)
    ProcedureReturn nextCmd
  Wend

  ; Macro finished naturally
  If gMacroPlaybackActive = 0 And gMacroPlaybackName <> ""
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] '" + gMacroPlaybackName + "' completed.")
    ResetColor()
    gMacroPlaybackName = ""
  EndIf

  ProcedureReturn Input()
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
  Protected safeName.s  = ""
  Protected ci.i        = 0
  Protected ch.s        = ""
  Protected fpath.s     = ""
  Protected resp.s      = ""
  Protected fid.i       = 0
  Protected lineCount.i = 0
  Protected entry.s     = ""

  If name = ""
    PrintN("Usage: MACRO CREATE <name>")
    ProcedureReturn
  EndIf

  ; Sanitize: letters, digits, underscore, hyphen only
  For ci = 1 To Len(name)
    ch = Mid(name, ci, 1)
    If (ch >= "a" And ch <= "z") Or (ch >= "A" And ch <= "Z") Or
       (ch >= "0" And ch <= "9") Or ch = "_" Or ch = "-"
      safeName + ch
    EndIf
  Next ci
  If safeName = ""
    PrintN("Invalid macro name. Use letters, numbers, _ or -")
    ProcedureReturn
  EndIf

  InitMacroFolder()
  fpath = MacroPath + safeName + ".txt"

  If FileSize(fpath) >= 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print("Macro '" + safeName + "' already exists. Overwrite? (YES) > ")
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
  PrintN("  Creating macro: " + safeName)
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
    If lineCount >= 50
      PrintN("  Maximum 50 lines reached.")
      Break
    EndIf
  ForEver

  CloseFile(fid)

  If lineCount = 0
    DeleteFile(fpath)
    PrintN("  No commands entered. Macro not saved.")
  Else
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  Macro '" + safeName + "' saved " + Str(lineCount) + " command(s)")
    PrintN("  File: " + fpath)
    ResetColor()
    LogLine("MACRO CREATE: " + safeName + " (" + Str(lineCount) + " lines)")
  EndIf
EndProcedure

;==============================================================================
; MacroRun(name.s)
; Loads a macro file into the playback queue. The main loop's GetNextInput()
; will feed each command automatically on subsequent turns.
;==============================================================================
Procedure MacroRun(name.s)
  ; Variables for file I/O
  Protected fpath.s       = ""
  Protected fid.i         = 0
  Protected fline.s       = ""
  ; Variables for REPEAT expansion
  Protected rawCount.i    = 0
  Protected ri.i          = 0
  Protected rj.i          = 0
  Protected rk.i          = 0
  Protected rl.i          = 0
  Protected repeatN.i     = 0
  Protected repeatStart.i = 0
  Protected repeatEnd.i   = 0
  Protected Dim rawLines.s(99)   ; temp storage for raw file lines (max 100)

  If name = ""
    PrintN("Usage: MACRO RUN <name>")
    ProcedureReturn
  EndIf

  fpath = MacroPath + name + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Macro '" + name + "' not found. Use MACRO LIST to see saved macros.")
    ResetColor()
    ProcedureReturn
  EndIf

  fid = ReadFile(#PB_Any, fpath)
  If fid = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Could not open macro file: " + fpath)
    ResetColor()
    ProcedureReturn
  EndIf

  ; Phase 1 read raw lines (comments stripped, blank lines skipped)
  rawCount = 0
  While Not Eof(fid) And rawCount < 100
    fline = Trim(ReadString(fid))
    If fline <> "" And Left(fline, 1) <> ";"
      rawLines(rawCount) = fline
      rawCount + 1
    EndIf
  Wend
  CloseFile(fid)

  ; Phase 2 expand REPEAT <n> / END_REPEAT blocks into the queue
  gMacroQueueSize = 0
  gMacroQueuePos  = 0
  ri = 0

  While ri < rawCount
    If TrimLower(TokenAt(rawLines(ri), 1)) = "repeat"
      repeatN     = ClampInt(ParseIntSafe(TokenAt(rawLines(ri), 2), 1), 1, 20)
      repeatStart = ri + 1
      repeatEnd   = -1
      ; Scan forward for matching END_REPEAT
      rj = ri + 1
      While rj < rawCount
        If TrimLower(rawLines(rj)) = "end_repeat"
          repeatEnd = rj
          Break
        EndIf
        rj + 1
      Wend
      If repeatEnd >= 0
        ; Expand: copy inner block repeatN times
        For rk = 1 To repeatN
          For rl = repeatStart To repeatEnd - 1
            If gMacroQueueSize < #MACRO_QUEUE_MAX
              gMacroQueue(gMacroQueueSize) = rawLines(rl)
              gMacroQueueSize + 1
            EndIf
          Next rl
        Next rk
        ri = repeatEnd + 1
      Else
        ; No matching END_REPEAT treat REPEAT line as a normal (skipped) line
        ri + 1
      EndIf
    ElseIf TrimLower(rawLines(ri)) = "end_repeat"
      ri + 1   ; orphan END_REPEAT skip
    Else
      If gMacroQueueSize < #MACRO_QUEUE_MAX
        gMacroQueue(gMacroQueueSize) = rawLines(ri)
        gMacroQueueSize + 1
      EndIf
      ri + 1
    EndIf
  Wend

  If gMacroQueueSize = 0
    PrintN("Macro '" + name + "' has no runnable commands.")
    ProcedureReturn
  EndIf

  gMacroPlaybackActive = 1
  gMacroPlaybackName   = name

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("[MACRO] Running '" + name + "' " + Str(gMacroQueueSize) + " command(s) queued.")
  PrintN("[MACRO] Commands execute automatically. PAUSE to pause, MACRO STOP to abort.")
  ResetColor()
  LogLine("MACRO RUN: " + name + " (" + Str(gMacroQueueSize) + " commands)")
EndProcedure

;==============================================================================
; MacroChainInsert(name.s)
; Called by GetNextInput() when a CHAIN <name> line is encountered.
; Loads the sub-macro and splices its commands into the active queue at the
; current playback position, so they run next before the remaining commands.
;==============================================================================
Procedure MacroChainInsert(name.s)
  Protected fpath.s      = ""
  Protected fid.i        = 0
  Protected fline.s      = ""
  Protected subCount.i   = 0
  Protected spaceAvail.i = 0
  Protected si.i         = 0
  Protected Dim subLines.s(49)   ; temp: up to 50 lines from sub-macro

  If name = ""
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: no macro name given, skipping.")
    ResetColor()
    ProcedureReturn
  EndIf

  fpath = MacroPath + name + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: '" + name + "' not found, skipping.")
    ResetColor()
    ProcedureReturn
  EndIf

  fid = ReadFile(#PB_Any, fpath)
  If fid = 0 : ProcedureReturn : EndIf

  subCount = 0
  While Not Eof(fid) And subCount < 50
    fline = Trim(ReadString(fid))
    If fline <> "" And Left(fline, 1) <> ";"
      subLines(subCount) = fline
      subCount + 1
    EndIf
  Wend
  CloseFile(fid)

  If subCount = 0 : ProcedureReturn : EndIf

  ; Clamp to available space
  spaceAvail = #MACRO_QUEUE_MAX - gMacroQueueSize
  If subCount > spaceAvail
    subCount = spaceAvail
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("[MACRO] CHAIN: queue nearly full, '" + name + "' truncated to " + Str(subCount) + " command(s).")
    ResetColor()
  EndIf

  If subCount <= 0 : ProcedureReturn : EndIf

  ; Shift remaining queued commands forward to open a gap at gMacroQueuePos
  For si = gMacroQueueSize - 1 To gMacroQueuePos Step -1
    gMacroQueue(si + subCount) = gMacroQueue(si)
  Next si

  ; Splice sub-macro lines into the gap
  For si = 0 To subCount - 1
    gMacroQueue(gMacroQueuePos + si) = subLines(si)
  Next si

  gMacroQueueSize + subCount

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("[MACRO] CHAIN: spliced '" + name + "' (" + Str(subCount) + " commands) at position " + Str(gMacroQueuePos))
  ResetColor()
EndProcedure

;==============================================================================
; MacroShow(name.s)
; Displays the contents of a macro file with line numbers.
;==============================================================================
Procedure MacroShow(name.s)
  Protected fpath.s   = ""
  Protected fid.i     = 0
  Protected lineNum.i = 0
  Protected fline.s   = ""

  If name = ""
    PrintN("Usage: MACRO SHOW <name>")
    ProcedureReturn
  EndIf

  fpath = MacroPath + name + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Macro '" + name + "' not found.")
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
  PrintN("  MACRO: " + name)
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

  InitMacroFolder()
  fpath = MacroPath + name + ".txt"

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  Editing macro: " + name)
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
    If lineCount >= 50
      PrintN("  Maximum 50 lines reached.")
      Break
    EndIf
  ForEver

  CloseFile(wfid)

  If lineCount = 0
    DeleteFile(fpath)
    PrintN("  No commands entered. Macro '" + name + "' removed.")
  Else
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  Macro '" + name + "' updated " + Str(lineCount) + " command(s).")
    ResetColor()
    LogLine("MACRO EDIT: " + name + " (" + Str(lineCount) + " lines)")
  EndIf
EndProcedure

;==============================================================================
; MacroDelete(name.s)
; Confirms and deletes a macro file.
;==============================================================================
Procedure MacroDelete(name.s)
  Protected fpath.s = ""
  Protected resp.s  = ""

  If name = ""
    PrintN("Usage: MACRO DELETE <name>")
    ProcedureReturn
  EndIf

  fpath = MacroPath + name + ".txt"
  If FileSize(fpath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Macro '" + name + "' not found. Use MACRO LIST to see saved macros.")
    ResetColor()
    ProcedureReturn
  EndIf

  ConsoleColor(#C_YELLOW, #C_BLACK)
  Print("Delete macro '" + name + "'? (YES) > ")
  ResetColor()
  resp = TrimLower(Trim(Input()))
  resp = ReplaceString(ReplaceString(resp, Chr(13), ""), Chr(10), "")

  If resp = "yes"
    If DeleteFile(fpath)
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN("Macro '" + name + "' deleted.")
      ResetColor()
      LogLine("MACRO DELETE: " + name)
    Else
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
      PrintN("ERROR: Could not delete macro file.")
      ResetColor()
    EndIf
  Else
    PrintN("Delete cancelled.")
  EndIf
EndProcedure
