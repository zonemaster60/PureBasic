; starcomm_util.pbi
; General utility procedures: string helpers, color output, display primitives
; XIncluded from starcomm.pb

Procedure.s Timestamp()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
EndProcedure

Procedure AppendFileLine(path.s, line.s)
  ; Best-effort logging: never crash gameplay.
  Protected f.i
  If path = "" : ProcedureReturn : EndIf
  f = OpenFile(#PB_Any, path, #PB_File_Append)
  If f = 0
    f = CreateFile(#PB_Any, path)
  EndIf
  If f
    WriteStringN(f, line)
    CloseFile(f)
  EndIf
EndProcedure

Procedure.s ReadAllText(path.s)
  Protected f.i = ReadFile(#PB_Any, path)
  If f = 0 : ProcedureReturn "" : EndIf
  Protected len.i = Lof(f)
  If len <= 0
    CloseFile(f)
    ProcedureReturn ""
  EndIf
  Protected *m = AllocateMemory(len + 1)
  If *m = 0
    CloseFile(f)
    ProcedureReturn ""
  EndIf
  ReadData(f, *m, len)
  CloseFile(f)
  PokeB(*m + len, 0)
  Protected out.s = PeekS(*m, len, #PB_UTF8)
  FreeMemory(*m)
  ProcedureReturn out
EndProcedure

Procedure.i ChecksumFNV32(*mem, len.i)
  ; 32-bit FNV-1a (good enough to detect casual tampering)
  Protected h.q = 2166136261
  Protected i.i, b.i
  For i = 0 To len - 1
    b = PeekB(*mem + i) & $FF
    h = (h ! b) & $FFFFFFFF
    h = (h * 16777619) & $FFFFFFFF
  Next
  ProcedureReturn h & $FFFFFFFF
EndProcedure

Procedure XorScramble(*mem, len.i, seed.i)
  ; Simple stream XOR (obfuscation, not real security)
  Protected x.q = (seed & $FFFFFFFF) ! $A5A5A5A5
  Protected i.i, k.i, b.i
  For i = 0 To len - 1
    x = (x * 1664525 + 1013904223) & $FFFFFFFF
    k = (x >> 24) & $FF
    b = (PeekB(*mem + i) & $FF) ! k
    PokeB(*mem + i, b)
  Next
EndProcedure

Procedure.i ClampInt(v.i, lo.i, hi.i)
  If hi < lo : ProcedureReturn lo : EndIf
  If v < lo : ProcedureReturn lo : EndIf
  If v > hi : ProcedureReturn hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.f ClampF(v.f, lo.f, hi.f)
  If hi < lo : ProcedureReturn lo : EndIf
  If v < lo : ProcedureReturn lo : EndIf
  If v > hi : ProcedureReturn hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.s TrimLower(s.s)
  ProcedureReturn LCase(Trim(s))
EndProcedure

Procedure.i ParseIntSafe(s.s, defaultValue.i)
  Protected t.s = Trim(s)
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn Val(t)
EndProcedure

Procedure.s TokenAt(line.s, idx.i)
  Protected n.i = CountString(Trim(line), " ") + 1
  Protected i.i, t.s, c.i
  line = Trim(line)
  If line = "" : ProcedureReturn "" : EndIf
  For i = 1 To n
    t = StringField(line, i, " ")
    If t <> ""
      c + 1
      If c = idx : ProcedureReturn t : EndIf
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.s CleanLine(s.s)
  ; Keep only printable ASCII plus spaces; avoids stray control chars from some consoles/stdin.
  Protected out.s = ""
  Protected i.i, ch.i
  For i = 1 To Len(s)
    ch = Asc(Mid(s, i, 1))
    If ch = 9
      out + " "
    ElseIf ch >= 32 And ch <= 126
      out + Chr(ch)
    EndIf
  Next
  ProcedureReturn out
EndProcedure

Procedure.s SafeField(s.s)
  ; Save-file fields are | delimited and line-based.
  s = ReplaceString(s, Chr(13), " ")
  s = ReplaceString(s, Chr(10), " ")
  s = ReplaceString(s, "|", "/")
  ProcedureReturn s
EndProcedure

Procedure PrintDivider()
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("------------------------------------------------------------")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
EndProcedure

Procedure ResetColor()
  ConsoleColor(#C_WHITE, #C_BLACK)
EndProcedure

Procedure PrintCmd(cmd.s)
  ; Simple emphasis for command words in help
  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("  " + cmd)
  ResetColor()
EndProcedure

Procedure PrintLegendLine(indent.s)
  ; Prints a colorized legend line (caller controls surrounding text)
  Print(indent)
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("@") : ResetColor() : Print("=YourShip")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_DARKGRAY, #C_BLACK) : Print(".") : ResetColor() : Print("=EmptySector ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("O") : ResetColor() : Print("=Planet ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("*") : ResetColor() : Print("=Star (blocked) ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("%") : ResetColor() : Print("=Starbase ")
  ConsoleColor(#C_GREEN, #C_BLACK) : Print("+") : ResetColor() : Print("=Shipyard")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("E") : ResetColor() : Print("=EnemyShip ")
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("P") : ResetColor() : Print("=PirateShip ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("#") : ResetColor() : Print("=Wormhole ")
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("?") : ResetColor() : Print("=Blackhole ")
  ConsoleColor(#C_BROWN, #C_BLACK) : Print("S") : ResetColor() : Print("=Sun (blocked)")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_MAGENTA, #C_BLACK) : Print("D") : ResetColor() : Print("=Dilithium ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("A") : ResetColor() : Print("=Anomaly ")
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("K") : ResetColor() : Print("=Planet Killer ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("R") : ResetColor() : Print("=Refinery ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("$") : ResetColor() : PrintN("=StarComm HQ")
EndProcedure

Procedure SetColorForEnt(t.i)
  Select t
    Case #ENT_EMPTY
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
    Case #ENT_STAR
      ConsoleColor(#C_YELLOW, #C_BLACK)
    Case #ENT_PLANET
      ConsoleColor(#C_LIGHTBLUE, #C_BLACK)
    Case #ENT_BASE
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Case #ENT_SHIPYARD
      ConsoleColor(#C_GREEN, #C_BLACK)
    Case #ENT_ENEMY
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_PIRATE
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_WORMHOLE
      ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
    Case #ENT_BLACKHOLE
      ConsoleColor(#C_WHITE, #C_BLACK)
    Case #ENT_SUN
      ; Approx orange
      ConsoleColor(#C_BROWN, #C_BLACK)
    Case #ENT_DILITHIUM
      ConsoleColor(#C_MAGENTA, #C_BLACK)
    Case #ENT_ANOMALY
      ConsoleColor(#C_CYAN, #C_BLACK)
    Case #ENT_PLANETKILLER
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_REFINERY
      ConsoleColor(#C_YELLOW, #C_BLACK)
    Case #ENT_HQ
      ConsoleColor(#C_YELLOW, #C_BLACK)
    Default
      ResetColor()
  EndSelect
EndProcedure

Procedure SetColorForPercent(pct.i)
  pct = ClampInt(pct, 0, 100)
  If pct >= 67
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  ElseIf pct >= 34
    ConsoleColor(#C_YELLOW, #C_BLACK)
  Else
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
  EndIf
EndProcedure

Procedure.s SysText(flags.i)
  If (flags & #SYS_DISABLED) : ProcedureReturn "DISABLED" : EndIf
  If (flags & #SYS_DAMAGED)  : ProcedureReturn "DAMAGED"  : EndIf
  ProcedureReturn "OK"
EndProcedure

Procedure ClearLog()
  Protected n.i = ArraySize(gLog()) + 1
  Protected i.i
  For i = 0 To n - 1
    gLog(i) = ""
  Next
  gLogPos = 0
EndProcedure
