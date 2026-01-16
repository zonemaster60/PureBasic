;------------------------------------------------------------------------------
; App bootstrap + shutdown helpers (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Startup self-test (procedures in includes/self_test.pbi)
;------------------------------------------------------------------------------

XIncludeFile "self_test.pbi"

Procedure InitDisplayAndLoadWorld(List WorldFiles.s())
  Define preferredIdx.i

  FontId = LoadFont(#PB_Any, "Consolas", 16, #PB_Font_HighQuality)
  If FontId = 0
    FontId = LoadFont(#PB_Any, "Courier New", 16, #PB_Font_HighQuality)
  EndIf
  If FontId = 0
    MessageRequester(#APP_NAME, "Failed To load a monospace font.")
    End
  EndIf

  OpenWindow(0, 0, 0, 640, 480, #APP_NAME, #WIN_FLAGS)

  ; Place window using saved preferences (if present).
  If PrefWinX <> 0 Or PrefWinY <> 0
    ResizeWindow(0, PrefWinX, PrefWinY, #PB_Ignore, #PB_Ignore)
  EndIf
  If PrefWinW > 0 And PrefWinH > 0
    ResizeWindow(0, #PB_Ignore, #PB_Ignore, PrefWinW, PrefWinH)
  EndIf

  If StartDrawing(WindowOutput(0))
    DrawingFont(FontID(FontId))
    TileW = TextWidth("W")
    TileH = TextHeight("W")
    StopDrawing()
  EndIf

  If TileW < 8 : TileW = 8 : EndIf
  If TileH < 12 : TileH = 12 : EndIf

  WinW = #MAP_W * TileW
  WinH = (#MAP_H + #UI_ROWS) * TileH

  ResizeWindowClient(0, WinW, WinH)

  If OpenWindowedScreen(WindowID(0), 0, 0, WinW, WinH, 0, 0, 0) = 0
    MessageRequester(#APP_NAME, "OpenWindowedScreen failed.")
    End
  EndIf

  BuildWorldList(WorldFiles())
  If LevelsDir = ""
    SetStatus("LevelsDir missing; starting blank.  INI: " + PrefGetPath(), 7000)
  Else
    SetStatus("LevelsDir: " + LevelsDir + " (" + Str(ListSize(WorldFiles())) + " files)  INI: " + PrefGetPath(), 7000)
  EndIf

  ; Prefer the title screen first, then last played, then first file.
  preferredIdx = FindWorldFileIndex(WorldFiles(), "title1.txt")

  ; If no title screen exists, fallback to last played world (by base name).
  ; (We intentionally don't require the stored absolute path to still exist.)
  If preferredIdx < 0 And PrefLastWorldPath <> ""
    preferredIdx = FindWorldFileIndex(WorldFiles(), GetFilePart(PrefLastWorldPath))
  EndIf

  If preferredIdx >= 0
    LoadWorldByIndex(preferredIdx, WorldFiles())
  Else
    LoadWorldByIndex(0, WorldFiles())
  EndIf

  BrushList = " .#~+$1234EABCFDdLo^*@PtThw="
  BrushIndex = 2
  BrushChar = Asc(Mid(BrushList, BrushIndex + 1, 1))
  BrushColor = Palette(BrushChar)

  StartupSelfTest(WorldFiles())
EndProcedure

Procedure ShutdownApp()
  ; Capture final window geometry (outer size).
  PrefWinX = WindowX(0)
  PrefWinY = WindowY(0)
  PrefWinW = WindowWidth(0)
  PrefWinH = WindowHeight(0)

  ; Persist all settings on exit.
  SavePrefs()

  ; free generated sounds
  FreeSfxSystem()

  If hMutex
    CloseHandle_(hMutex)
  EndIf
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 99
; FirstLine = 71
; Folding = -
; EnableXP
; DPIAware