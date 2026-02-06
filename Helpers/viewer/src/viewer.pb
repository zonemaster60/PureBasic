; viewer.pb - PureBasic 6.30 console file viewer (Windows)
EnableExplicit

#CHUNK_LINES = 1024
#APP_NAME = "Viewer"

; Windows Virtual-Key codes (RawKey() typically matches these on Windows)
#VK_UP     = 38
#VK_DOWN   = 40
#VK_PRIOR  = 33 ; PageUp
#VK_NEXT   = 34 ; PageDown
#VK_HOME   = 36
#VK_END    = 35

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #STD_INPUT_HANDLE  = -10
  #STD_OUTPUT_HANDLE = -11

  #ENABLE_PROCESSED_INPUT   = $0001
  #ENABLE_LINE_INPUT        = $0002
  #ENABLE_ECHO_INPUT        = $0004
  #ENABLE_WINDOW_INPUT      = $0008
  #ENABLE_MOUSE_INPUT       = $0010
  #ENABLE_INSERT_MODE       = $0020
  #ENABLE_QUICK_EDIT_MODE   = $0040
  #ENABLE_EXTENDED_FLAGS    = $0080
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  CompilerIf Defined(COORD, #PB_Structure) = 0
    Structure COORD
      x.w
      y.w
    EndStructure
  CompilerEndIf

  CompilerIf Defined(SMALL_RECT, #PB_Structure) = 0
    Structure SMALL_RECT
      Left.w
      Top.w
      Right.w
      Bottom.w
    EndStructure
  CompilerEndIf

  CompilerIf Defined(CONSOLE_SCREEN_BUFFER_INFO, #PB_Structure) = 0
    Structure CONSOLE_SCREEN_BUFFER_INFO
      dwSize.COORD
      dwCursorPosition.COORD
      wAttributes.w
      srWindow.SMALL_RECT
      dwMaximumWindowSize.COORD
    EndStructure
  CompilerEndIf
CompilerEndIf

Procedure.i ClampI(v.i, lo.i, hi.i)
  If v < lo : ProcedureReturn lo : EndIf
  If v > hi : ProcedureReturn hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.s ClipToWidth(text.s, cols.i)
  If cols <= 0 : ProcedureReturn "" : EndIf
  If Len(text) > cols : ProcedureReturn Left(text, cols) : EndIf
  ProcedureReturn text
EndProcedure

Procedure.i ConsoleCols()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected h.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If h And GetConsoleScreenBufferInfo_(h, @csbi)
      ProcedureReturn (csbi\srWindow\Right - csbi\srWindow\Left + 1)
    EndIf
  CompilerEndIf
  ProcedureReturn 80
EndProcedure

Procedure.i ConsoleRows()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected h.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If h And GetConsoleScreenBufferInfo_(h, @csbi)
      ProcedureReturn (csbi\srWindow\Bottom - csbi\srWindow\Top + 1)
    EndIf
  CompilerEndIf
  ProcedureReturn 25
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Procedure DisableConsoleMouseAndQuickEdit()
    ; Best effort to avoid accidental mouse-driven scrolling/selection.
    Protected hIn.i = GetStdHandle_(#STD_INPUT_HANDLE)
    Protected mode.l

    If hIn And GetConsoleMode_(hIn, @mode)
      mode | #ENABLE_EXTENDED_FLAGS
      mode & ~#ENABLE_QUICK_EDIT_MODE
      mode & ~#ENABLE_INSERT_MODE
      mode & ~#ENABLE_MOUSE_INPUT
      SetConsoleMode_(hIn, mode)
    EndIf
  EndProcedure

  Procedure EnsureNoConsoleScrollback()
    ; Clamp screen buffer to visible window size (prevents scrollback).
    Protected hOut.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If hOut = 0 : ProcedureReturn : EndIf
    If GetConsoleScreenBufferInfo_(hOut, @csbi) = 0 : ProcedureReturn : EndIf

    Protected winW.w = csbi\srWindow\Right - csbi\srWindow\Left + 1
    Protected winH.w = csbi\srWindow\Bottom - csbi\srWindow\Top + 1
    If winW < 1 Or winH < 1 : ProcedureReturn : EndIf

    Protected buf.COORD
    buf\x = winW
    buf\y = winH

    SetConsoleScreenBufferSize_(hOut, buf)
  EndProcedure
CompilerEndIf

Procedure.i LoadFileIntoArray(fileName.s, Array lines.s(1))
  Protected f.i, count.i, cap.i

  f = ReadFile(#PB_Any, fileName)
  If f = 0 : ProcedureReturn -1 : EndIf

  cap = #CHUNK_LINES
  Dim lines(cap - 1)
  count = 0

  While Eof(f) = 0
    If count >= cap
      cap + #CHUNK_LINES
      ReDim lines(cap - 1)
    EndIf
    lines(count) = ReadString(f)
    count + 1
  Wend

  CloseFile(f)

  If count = 0
    Dim lines(0)
    ProcedureReturn 0
  EndIf

  ReDim lines(count - 1)
  ProcedureReturn count
EndProcedure

Procedure DrawScreen(Array lines.s(1), lineCount.i, topLine.i, fileName.s)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    EnsureNoConsoleScrollback()
  CompilerEndIf

  Protected cols.i = ConsoleCols()
  Protected rowsTotal.i = ConsoleRows()
  Protected viewRows.i = rowsTotal - 1
  Protected i.i, idx.i, maxTop.i
  Protected status.s

  If viewRows < 1 : viewRows = 1 : EndIf
  maxTop = lineCount - viewRows
  If maxTop < 0 : maxTop = 0 : EndIf
  topLine = ClampI(topLine, 0, maxTop)

  ClearConsole()
  ConsoleLocate(0, 0)

  For i = 0 To viewRows - 1
    idx = topLine + i
    If idx < lineCount
      PrintN(ClipToWidth(lines(idx), cols))
    Else
      PrintN("")
    EndIf
  Next

  status = fileName + "  |  Lines: " + Str(lineCount) + "  |  " + Str(topLine + 1) + "-" + Str(ClampI(topLine + viewRows, 0, lineCount)) + #CRLF$ +
           "  |  Up/Down PgUp/PgDn Home/End  |  W/S also work  |  Q/Esc quits"
  If Len(status) > cols : status = Left(status, cols) : EndIf

  ConsoleLocate(0, viewRows)
  Print(status)
EndProcedure

; ---- Main ----
OpenConsole()
EnableGraphicalConsole(1)

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  DisableConsoleMouseAndQuickEdit()
  EnsureNoConsoleScrollback()
CompilerEndIf

If CountProgramParameters() < 1
  PrintN("Usage: " + #APP_NAME + " <file>")
  PrintN("Keys: Up/Down, PgUp/PgDn, Home/End, W/S, Q or Esc")
  Input()
  End
EndIf

Define fileName.s = ProgramParameter(0)
Define Dim lines.s(0)
Define lineCount.i = LoadFileIntoArray(fileName, lines())

If lineCount < 0
  PrintN("Error: can't open file: " + fileName)
  Input()
  End
EndIf

Define topLine.i = 0
Define k.s, rk.i
Define rowsTotal.i, viewRows.i, maxTop.i

DrawScreen(lines(), lineCount, topLine, fileName)

Repeat
  k = Inkey()
  rk = RawKey()

  rowsTotal = ConsoleRows()
  viewRows = rowsTotal - 1
  If viewRows < 1 : viewRows = 1 : EndIf
  maxTop = lineCount - viewRows
  If maxTop < 0 : maxTop = 0 : EndIf

  If k <> ""
    Select k
      Case Chr(27), "q", "Q"
        Break
      Case "w", "W"
        topLine - 1
      Case "s", "S"
        topLine + 1
    EndSelect
  ElseIf rk
    Select rk
      Case #VK_UP
        topLine - 1
      Case #VK_DOWN
        topLine + 1
      Case #VK_PRIOR
        topLine - viewRows
      Case #VK_NEXT
        topLine + viewRows
      Case #VK_HOME
        topLine = 0
      Case #VK_END
        topLine = maxTop
    EndSelect
  Else
    Delay(10)
    Continue
  EndIf

  topLine = ClampI(topLine, 0, maxTop)
  DrawScreen(lines(), lineCount, topLine, fileName)
  Delay(10)
ForEver

CloseConsole()
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 4
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = viewer.ico
; Executable = ..\Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = viewer
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Console text viewer
; VersionField7 = viewer
; VersionField8 = viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60