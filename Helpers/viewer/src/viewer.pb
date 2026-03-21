; viewer.pb - PureBasic 6.30 console file viewer (cross-platform)
EnableExplicit

#CHUNK_LINES = 1024
#APP_NAME = "Viewer"
#NAV_NONE = 0
#NAV_QUIT = 1
#NAV_UP = 2
#NAV_DOWN = 3
#NAV_PAGEUP = 4
#NAV_PAGEDOWN = 5
#NAV_HOME = 6
#NAV_END = 7
Global version.s = "1.0.0.2"

; Windows Virtual-Key codes for RawKey() fallback navigation
#VK_UP     = 38
#VK_DOWN   = 40
#VK_PRIOR  = 33 ; PageUp
#VK_NEXT   = 34 ; PageDown
#VK_HOME   = 36
#VK_END    = 35

Procedure.i IsValidConsoleHandle(h.i)
  If h = 0 Or h = -1
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure.i ParseAnsiNavigation(seq.s)
  Select seq
    Case Chr(27) + "[A", Chr(27) + "OA"
      ProcedureReturn #NAV_UP
    Case Chr(27) + "[B", Chr(27) + "OB"
      ProcedureReturn #NAV_DOWN
    Case Chr(27) + "[5~"
      ProcedureReturn #NAV_PAGEUP
    Case Chr(27) + "[6~"
      ProcedureReturn #NAV_PAGEDOWN
    Case Chr(27) + "[H", Chr(27) + "OH", Chr(27) + "[1~", Chr(27) + "[7~"
      ProcedureReturn #NAV_HOME
    Case Chr(27) + "[F", Chr(27) + "OF", Chr(27) + "[4~", Chr(27) + "[8~"
      ProcedureReturn #NAV_END
  EndSelect

  ProcedureReturn #NAV_NONE
EndProcedure

Procedure.i IsAnsiPrefix(seq.s)
  Select seq
    Case Chr(27), Chr(27) + "[", Chr(27) + "O", Chr(27) + "[1", Chr(27) + "[4", Chr(27) + "[5", Chr(27) + "[6", Chr(27) + "[7", Chr(27) + "[8"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #STD_INPUT_HANDLE  = -10
  #STD_OUTPUT_HANDLE = -11

  #ENABLE_EXTENDED_FLAGS    = $0080
  #ENABLE_QUICK_EDIT_MODE   = $0040
  #ENABLE_INSERT_MODE       = $0020
  #ENABLE_MOUSE_INPUT       = $0010

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
  ; Replace tabs with spaces for consistent viewing
  text = ReplaceString(text, #TAB$, "    ")
  If Len(text) > cols : ProcedureReturn Left(text, cols) : EndIf
  ProcedureReturn text
EndProcedure

Procedure.i ConsoleCols()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected h.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If IsValidConsoleHandle(h) And GetConsoleScreenBufferInfo_(h, @csbi)
      ProcedureReturn (csbi\srWindow\Right - csbi\srWindow\Left + 1)
    EndIf
  CompilerEndIf
  ProcedureReturn 80
EndProcedure

Procedure.i ConsoleRows()
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected h.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If IsValidConsoleHandle(h) And GetConsoleScreenBufferInfo_(h, @csbi)
      ProcedureReturn (csbi\srWindow\Bottom - csbi\srWindow\Top + 1)
    EndIf
  CompilerEndIf
  ProcedureReturn 25
EndProcedure

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Procedure DisableConsoleMouseAndQuickEdit()
    Protected hIn.i = GetStdHandle_(#STD_INPUT_HANDLE)
    Protected mode.l
    If IsValidConsoleHandle(hIn) And GetConsoleMode_(hIn, @mode)
      mode | #ENABLE_EXTENDED_FLAGS
      mode & ~#ENABLE_QUICK_EDIT_MODE
      mode & ~#ENABLE_INSERT_MODE
      mode & ~#ENABLE_MOUSE_INPUT
      SetConsoleMode_(hIn, mode)
    EndIf
  EndProcedure

  Procedure EnsureNoConsoleScrollback()
    Protected hOut.i = GetStdHandle_(#STD_OUTPUT_HANDLE)
    Protected csbi.CONSOLE_SCREEN_BUFFER_INFO
    If IsValidConsoleHandle(hOut) = 0 : ProcedureReturn : EndIf
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
  Protected f.i, count.i, cap.i, format.i
  f = ReadFile(#PB_Any, fileName)
  If f = 0 : ProcedureReturn -1 : EndIf
  
  format = ReadStringFormat(f) ; Detect UTF-8/UTF-16/Ascii
  cap = #CHUNK_LINES
  Dim lines(cap - 1)
  count = 0
  While Eof(f) = 0
    If count >= cap
      cap + #CHUNK_LINES
      ReDim lines(cap - 1)
    EndIf
    lines(count) = ReadString(f, format)
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
  Protected cols.i = ConsoleCols()
  Protected rowsTotal.i = ConsoleRows()
  Protected viewRows.i = rowsTotal - 1
  Protected i.i, idx.i
  Protected status.s
  Protected clipped.s
  Protected currentLineLen.i
  Protected firstShown.i
  Protected lastShown.i

  If viewRows < 1 : viewRows = 1 : EndIf
  
  ConsoleLocate(0, 0)
  ; Draw file content
  For i = 0 To viewRows - 1
    idx = topLine + i
    clipped = ""
    If idx < lineCount
      clipped = ClipToWidth(lines(idx), cols)
      Print(clipped)
    EndIf
    ; Clear to end of line to avoid artifacts from previous draws
    currentLineLen = Len(clipped)
    
    If cols - currentLineLen > 0
      Print(Space(cols - currentLineLen))
    EndIf
    
    If i < viewRows - 1
        PrintN("")
    EndIf
  Next

  ; Status line
  If lineCount = 0
    firstShown = 0
    lastShown = 0
  Else
    firstShown = topLine + 1
    lastShown = ClampI(topLine + viewRows, 0, lineCount)
  EndIf
  status = " " + GetFilePart(fileName) + " | " + Str(lineCount) + " lines | " + Str(firstShown) + "-" + Str(lastShown) + " | Q: Quit"
  status = ClipToWidth(status, cols)
  
  ConsoleLocate(0, viewRows)
  ConsoleColor(0, 7)
  Print(status + Space(cols - Len(status)))
  ConsoleColor(7, 0)
EndProcedure

; ---- Main ----
If OpenConsole() = 0 : End : EndIf
EnableGraphicalConsole(1)

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  DisableConsoleMouseAndQuickEdit()
  EnsureNoConsoleScrollback()
CompilerEndIf

If CountProgramParameters() < 1
  PrintN("Usage: " + #APP_NAME + " <file>")
  PrintN("Keys: Up/Down, PgUp/PgDn, Home/End, W/S, J/K, Q or Esc")
  Print("Press Enter to exit...")
  Input()
  CloseConsole()
  End
EndIf

Define fileName.s = ProgramParameter(0)
Define Dim lines.s(0)
Define lineCount.i = LoadFileIntoArray(fileName, lines())

If lineCount < 0
  PrintN("Error: Could not open file: " + fileName)
  Print("Press Enter to exit...")
  Input()
  CloseConsole()
  End
EndIf

Define topLine.i = 0
Define k.s, seq.s, ch.s
Define rk.i, nav.i, deadline.i
Define colsTotal.i, rowsTotal.i, viewRows.i, maxTop.i
Define lastTop.i = -1
Define lastCols.i = -1
Define lastRows.i = -1

Repeat
  colsTotal = ConsoleCols()
  rowsTotal = ConsoleRows()
  viewRows = rowsTotal - 1
  If viewRows < 1 : viewRows = 1 : EndIf
  maxTop = lineCount - viewRows
  If maxTop < 0 : maxTop = 0 : EndIf
  topLine = ClampI(topLine, 0, maxTop)

  ; Only redraw if something changed
  If topLine <> lastTop Or rowsTotal <> lastRows Or colsTotal <> lastCols
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If rowsTotal <> lastRows Or colsTotal <> lastCols
        EnsureNoConsoleScrollback()
      EndIf
    CompilerEndIf
    DrawScreen(lines(), lineCount, topLine, fileName)
    lastTop = topLine
    lastRows = rowsTotal
    lastCols = colsTotal
  EndIf

  nav = #NAV_NONE
  k = Inkey()
  rk = 0
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    rk = RawKey()
  CompilerEndIf
  If k = Chr(27)
    seq = k
    deadline = ElapsedMilliseconds() + 40

    Repeat
      ch = Inkey()
      If ch <> ""
        seq + ch
        nav = ParseAnsiNavigation(seq)
        If nav <> #NAV_NONE Or IsAnsiPrefix(seq) = 0
          Break
        EndIf
      Else
        Delay(1)
      EndIf
    Until ElapsedMilliseconds() >= deadline

    If nav = #NAV_NONE
      If ParseAnsiNavigation(seq) <> #NAV_NONE
        nav = ParseAnsiNavigation(seq)
      ElseIf Len(seq) = 1
        nav = #NAV_QUIT
      EndIf
    EndIf
  ElseIf k <> ""
    Select k
      Case "q", "Q"
        nav = #NAV_QUIT
      Case "w", "W"
        nav = #NAV_UP
      Case "s", "S"
        nav = #NAV_DOWN
      Case "k", "K"
        nav = #NAV_UP
      Case "j", "J"
        nav = #NAV_DOWN
    EndSelect
  EndIf

  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If nav = #NAV_NONE And rk
      Select rk
        Case #VK_UP : nav = #NAV_UP
        Case #VK_DOWN : nav = #NAV_DOWN
        Case #VK_PRIOR : nav = #NAV_PAGEUP
        Case #VK_NEXT : nav = #NAV_PAGEDOWN
        Case #VK_HOME : nav = #NAV_HOME
        Case #VK_END : nav = #NAV_END
      EndSelect
    EndIf
  CompilerEndIf

  Select nav
    Case #NAV_QUIT
      Break
    Case #NAV_UP
      topLine - 1
    Case #NAV_DOWN
      topLine + 1
    Case #NAV_PAGEUP
      topLine - viewRows
    Case #NAV_PAGEDOWN
      topLine + viewRows
    Case #NAV_HOME
      topLine = 0
    Case #NAV_END
      topLine = maxTop
  EndSelect
  
  Delay(16) ; ~60fps response
ForEver

CloseConsole()
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 13
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = viewer.ico
; Executable = ..\Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = viewer
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Console text viewer
; VersionField7 = viewer
; VersionField8 = viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60