; Core helpers, logging, DPI, elevation, power/session handling.

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If IsLaunchActive()
      PrepareForApplicationExit()
      ProcedureReturn
    EndIf
    FinalizeApplicationExit()
  EndIf
EndProcedure

Procedure.i IsLaunchActive()
  If LaunchActive
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure PrepareForApplicationExit()
  AppQuitting = 1
  If IsWindow(0)
    HideWindow(0, 1)
  EndIf
EndProcedure

Procedure FinalizeApplicationExit()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  End
EndProcedure

Procedure.s HelpText()
  Protected t.s
  t + #APP_NAME + " - In-App Help" + #CRLF$ + #CRLF$
  t + "What it does" + #CRLF$
  t + "- Launches a game (EXE or Steam) and applies temporary boosts." + #CRLF$
  t + "- Can keep the current power plan or switch to High performance / Ultimate Performance per game, then restore your previous plan." + #CRLF$
  t + "- Optionally stops selected services during gameplay, then starts them again when you exit." + #CRLF$
  t + "- Can temporarily lower safe background process priority while a boosted game runs." + #CRLF$
  t + "- Logs actions to " + #APP_NAME + ".log and can restore after a crash." + #CRLF$ + #CRLF$
  t + "What it does NOT do" + #CRLF$
  t + "- It does not permanently change Windows settings." + #CRLF$
  t + "- It does not 'disable' services (startup type). It only stops/starts them temporarily." + #CRLF$ + #CRLF$
  t + "Quick start" + #CRLF$
  t + "1) Add games:" + #CRLF$
  t + "   - Add: prompts for name + EXE + args" + #CRLF$
  t + "   - Browse EXE: adds one EXE quickly (deduped)" + #CRLF$
  t + "   - Add Folder: scans a folder and tries to pick the main EXE per game folder" + #CRLF$
  t + "   - Import Steam Game: opens a picker for one installed Steam game and launches via AppID" + #CRLF$
  t + "   - File -> Import Profiles / Export Profiles: move your game setup between machines" + #CRLF$
  t + "   - File -> Create Snapshot / Restore Snapshot: back up and restore the full local library state" + #CRLF$
  t + "   - File -> Undo Last Change: revert the most recent library edit/import/remove/move action" + #CRLF$
  t + "   - File -> Redo Last Change: reapply the last undone library action" + #CRLF$
  t + "2) Edit a game:" + #CRLF$
  t + "   - Select a game -> Edit -> choose a preset, set priority/power mode, add tags/notes, and pick services" + #CRLF$
  t + "   - In the services picker you can also right-click selected rows to Start/Stop now." + #CRLF$
  t + "   - Drag games in the main list to reorder them, or use Move Up / Move Down when viewing All Games sorted by Name." + #CRLF$
  t + "3) Run:" + #CRLF$
  t + "   - Select a game -> Run" + #CRLF$ + #CRLF$
  t + "Services (important)" + #CRLF$
  t + "- Services you check are saved per game." + #CRLF$
  t + "- When you click Run, " + #APP_NAME + " stops services and records ONLY those it actually stopped." + #CRLF$
  t + "- On exit, it restarts exactly that recorded set." + #CRLF$
  t + "- If a service fails to stop/start, the log records the error." + #CRLF$ + #CRLF$
  t + "Crash recovery" + #CRLF$
  t + "- While a game is running, session.ini is marked 'dirty' and stores:" + #CRLF$
  t + "  - the previous power plan GUID" + #CRLF$
  t + "  - the effective list of stopped services" + #CRLF$
  t + "- Next time " + #APP_NAME + " starts, it detects a dirty session and restores power plan/services." + #CRLF$ + #CRLF$
  t + "Where files are" + #CRLF$
  t + "- games.ini, session.ini, " + #APP_NAME + ".log are stored next to the EXE." + #CRLF$
  t + "- Use the Open Log button to open " + #APP_NAME + ".log." + #CRLF$ + #CRLF$
  t + "- Use the library sidebar, filter box, and sort menu on the main window to find games quickly." + #CRLF$
  t + "- Profile imports merge duplicates by Steam AppID or EXE path." + #CRLF$
  t + "- Tools -> Settings lets you choose the default preset and thumbnail size." + #CRLF$
  t + "- Steam games try to fetch cached artwork thumbnails automatically." + #CRLF$
  t + "- Tools -> Diagnostics shows CPU usage, memory status, tuned background processes, and the active Windows power plan." + #CRLF$ + #CRLF$
  t + "Troubleshooting" + #CRLF$
  t + "- Admin rights: service control requires an elevated process. " + #APP_NAME + " auto-prompts via UAC." + #CRLF$
  t + "- Steam games: " + #APP_NAME + " waits for a new process whose EXE path starts with the game's install folder." + #CRLF$
  t + "- If Run 'does nothing', make sure a game is selected, then check " + #APP_NAME + ".log." + #CRLF$
  t + "- Ultimate Performance is used only if Windows exposes it; otherwise the app falls back to High performance." + #CRLF$
  ProcedureReturn t
EndProcedure

Procedure ShowHelp()
  Protected w.i, gText.i, gClose.i, gOpenLog.i
  Protected ev.i

  w = OpenWindow(#PB_Any, 0, 0, 820, 620, "Help", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w
    DisableWindow(0, 1)
    gText = EditorGadget(#PB_Any, 10, 10, 800, 560)
    SetGadgetText(gText, HelpText())
    SetGadgetAttribute(gText, #PB_Editor_ReadOnly, 1)

    gOpenLog = ButtonGadget(#PB_Any, 10, 580, 120, 30, "Open Log")
    gClose   = ButtonGadget(#PB_Any, 690, 580, 120, 30, "Close")

    If FontUI
      SetGadgetFont(gText, FontID(FontUI))
      SetGadgetFont(gOpenLog, FontID(FontUI))
      SetGadgetFont(gClose, FontID(FontUI))
    EndIf

    Repeat
      ev = WaitWindowEvent()
      Select ev
        Case #PB_Event_Gadget
          Select EventGadget()
            Case gOpenLog
              ViewLog()
            Case gClose
              CloseWindow(w)
              Break
          EndSelect
        Case #PB_Event_CloseWindow
          If EventWindow() = w
            CloseWindow(w)
            Break
          EndIf
      EndSelect
    ForEver

    DisableWindow(0, 0)
  EndIf
EndProcedure

Procedure.s NowStamp()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
EndProcedure

Procedure LogLine(msg.s)
  Protected f.i
  If FileSize(LogPath) >= 0
    f = OpenFile(#PB_Any, LogPath)
    If f
      FileSeek(f, Lof(f))
    EndIf
  Else
    f = CreateFile(#PB_Any, LogPath)
  EndIf

  If f
    WriteStringN(f, NowStamp() + "  " + msg)
    CloseFile(f)
  EndIf
EndProcedure

Procedure ViewLog()
  If FileSize(LogPath) < 0
    LogLine("Log created")
  EndIf
  RunProgram(LogPath, "", "", #PB_Program_Open)
EndProcedure

Procedure.i ScaleX(x.i)
  ProcedureReturn DesktopScaledX(x)
EndProcedure

Procedure.i ScaleY(y.i)
  ProcedureReturn DesktopScaledY(y)
EndProcedure

Procedure InitFonts()
  Protected baseSize.i = 10
  FontUI = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize))
  FontSmall = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize - 1))
  FontTitle = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize + 5), #PB_Font_Bold)
EndProcedure

Procedure.i IsProcessElevated()
  Protected hToken.i, elev.OC_TOKEN_ELEVATION, cb.l
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken) = 0
    ProcedureReturn 0
  EndIf
  cb = SizeOf(OC_TOKEN_ELEVATION)
  If GetTokenInformation_(hToken, #TokenElevation, @elev, cb, @cb) = 0
    CloseHandle_(hToken)
    ProcedureReturn 0
  EndIf
  CloseHandle_(hToken)
  ProcedureReturn elev\TokenIsElevated
EndProcedure

Procedure EnsureElevatedOrRelaunch()
  If IsProcessElevated() = 0
    LogLine("Not elevated (you may be in Administrators group, but process isn't elevated). Relaunching with UAC")
    If ShellExecute_(0, "runas", ProgramFilename(), "", GetPathPart(ProgramFilename()), #SW_SHOWNORMAL) > 32
      End
    EndIf
    LogLine("UAC relaunch failed")
    MessageRequester(#APP_NAME, "Admin rights are required (elevated process).")
    End
  EndIf
  LogLine("Running elevated")
EndProcedure

Procedure.s QuoteArg(s.s)
  If FindString(s, " ", 1) Or FindString(s, #DQUOTE$, 1)
    s = ReplaceString(s, #DQUOTE$, "\" + #DQUOTE$)
    ProcedureReturn #DQUOTE$ + s + #DQUOTE$
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.s TrimCRLF(s.s)
  s = ReplaceString(s, #CRLF$, #LF$)
  s = ReplaceString(s, #CR$, #LF$)
  While Right(s, 1) = #LF$
    s = Left(s, Len(s) - 1)
  Wend
  ProcedureReturn s
EndProcedure

Procedure.s RunProgramAndCapture(exe.s, args.s)
  Protected p.i, out.s, line.s
  p = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If p
    While ProgramRunning(p)
      If AvailableProgramOutput(p)
        line = ReadProgramString(p)
        out + line + #LF$
      Else
        Delay(5)
      EndIf
    Wend
    While AvailableProgramOutput(p)
      line = ReadProgramString(p)
      out + line + #LF$
    Wend
    CloseProgram(p)
  EndIf
  ProcedureReturn TrimCRLF(out)
EndProcedure

Procedure.s RunAndCapture(cmd.s)
  ProcedureReturn RunProgramAndCapture("cmd.exe", "/c " + cmd)
EndProcedure

Procedure.s EnsureTrailingSlash(p.s)
  If p = "" : ProcedureReturn "" : EndIf
  If Right(p, 1) <> "\\" And Right(p, 1) <> "/"
    p + "\\"
  EndIf
  ProcedureReturn p
EndProcedure

Procedure.s PathJoin(a.s, b.s)
  a = EnsureTrailingSlash(a)
  If Left(b, 1) = "\\" Or Left(b, 1) = "/"
    b = Mid(b, 2)
  EndIf
  ProcedureReturn a + b
EndProcedure

Procedure.s FormatPowerModeLabel(mode.i)
  Select mode
    Case #POWERMODE_HIGH
      ProcedureReturn "High performance"
    Case #POWERMODE_ULTIMATE
      ProcedureReturn "Ultimate Performance"
  EndSelect
  ProcedureReturn "Keep current"
EndProcedure

Procedure.s FormatPresetLabel(preset.i)
  Select preset
    Case #PRESET_SAFE
      ProcedureReturn "Safe"
    Case #PRESET_AGGRESSIVE
      ProcedureReturn "Aggressive"
  EndSelect
  ProcedureReturn "Balanced"
EndProcedure

Procedure.i ResolvePowerMode(mode.i, previousGuid.s = "")
  Select mode
    Case #POWERMODE_HIGH
      If previousGuid <> "" And LCase(previousGuid) = LCase(#POWER_GUID_HIGH)
        ProcedureReturn 0
      EndIf
      If SetActivePowerGuid(#POWER_GUID_HIGH)
        ProcedureReturn 1
      EndIf
    Case #POWERMODE_ULTIMATE
      If previousGuid <> "" And LCase(previousGuid) = LCase(#POWER_GUID_ULTIMATE)
        ProcedureReturn 0
      EndIf
      If SetActivePowerGuid(#POWER_GUID_ULTIMATE)
        ProcedureReturn 2
      EndIf
      If previousGuid <> "" And LCase(previousGuid) = LCase(#POWER_GUID_HIGH)
        ProcedureReturn 0
      EndIf
      If SetActivePowerGuid(#POWER_GUID_HIGH)
        ProcedureReturn 1
      EndIf
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure.s FormatDurationSeconds(totalSeconds.i)
  Protected hours.i, mins.i, secs.i
  If totalSeconds < 0 : totalSeconds = 0 : EndIf
  hours = totalSeconds / 3600
  mins = (totalSeconds % 3600) / 60
  secs = totalSeconds % 60
  If hours > 0
    ProcedureReturn Str(hours) + "h " + RSet(Str(mins), 2, "0") + "m"
  EndIf
  If mins > 0
    ProcedureReturn Str(mins) + "m " + RSet(Str(secs), 2, "0") + "s"
  EndIf
  ProcedureReturn Str(secs) + "s"
EndProcedure

Procedure.s FormatBytes(bytes.q)
  Protected value.d = bytes
  If value < 1024
    ProcedureReturn Str(bytes) + " B"
  ElseIf value < 1024 * 1024
    ProcedureReturn StrD(value / 1024, 1) + " KB"
  ElseIf value < 1024 * 1024 * 1024
    ProcedureReturn StrD(value / (1024 * 1024), 1) + " MB"
  EndIf
  ProcedureReturn StrD(value / (1024 * 1024 * 1024), 1) + " GB"
EndProcedure

Procedure.s CurrentPowerPlanName()
  Protected out.s = RunAndCapture("powercfg /getactivescheme")
  Protected openParen.i, closeParen.i
  openParen = FindString(out, "(", 1)
  closeParen = FindString(out, ")", openParen + 1)
  If openParen > 0 And closeParen > openParen
    ProcedureReturn Trim(Mid(out, openParen + 1, closeParen - openParen - 1))
  EndIf
  ProcedureReturn "Unknown"
EndProcedure

Procedure.i SystemMemoryStatus(*mem.OC_MEMORYSTATUSEX)
  If *mem = 0
    ProcedureReturn 0
  EndIf
  *mem\dwLength = SizeOf(OC_MEMORYSTATUSEX)
  ProcedureReturn GlobalMemoryStatusEx_(*mem)
EndProcedure

Procedure.q CpuUsagePercent()
  ProcedureReturn -1
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(SettingsIni)
    PreferenceGroup("ui")
    DefaultPreset = ReadPreferenceInteger("defaultPreset", #PRESET_BALANCED)
    ThumbnailSize = ReadPreferenceInteger("thumbnailSize", 18)
    SortMode = ReadPreferenceInteger("sortMode", #SORT_NAME_ASC)
    LibraryView = ReadPreferenceInteger("libraryView", #LIBRARY_ALL)
    RememberLastView = ReadPreferenceInteger("rememberLastView", 1)
    HistoryDepth = ReadPreferenceInteger("historyDepth", 10)
    SteamExeArgs = ReadPreferenceString("steamExeArgs", "")
    ClosePreferences()
  EndIf
  If DefaultPreset < #PRESET_SAFE Or DefaultPreset > #PRESET_AGGRESSIVE : DefaultPreset = #PRESET_BALANCED : EndIf
  If ThumbnailSize < 16 : ThumbnailSize = 16 : EndIf
  If ThumbnailSize > 32 : ThumbnailSize = 32 : EndIf
  If HistoryDepth < 1 : HistoryDepth = 1 : EndIf
  If HistoryDepth > 25 : HistoryDepth = 25 : EndIf
  If RememberLastView = 0
    SortMode = #SORT_NAME_ASC
    LibraryView = #LIBRARY_ALL
  EndIf
EndProcedure

Procedure SaveSettings()
  If OpenOrCreatePreferences(SettingsIni)
    PreferenceGroup("ui")
    WritePreferenceInteger("defaultPreset", DefaultPreset)
    WritePreferenceInteger("thumbnailSize", ThumbnailSize)
    WritePreferenceInteger("sortMode", SortMode)
    WritePreferenceInteger("libraryView", LibraryView)
    WritePreferenceInteger("rememberLastView", RememberLastView)
    WritePreferenceInteger("historyDepth", HistoryDepth)
    WritePreferenceString("steamExeArgs", SteamExeArgs)
    ClosePreferences()
  EndIf
EndProcedure

Procedure EditGlobalSteamArgs()
  SteamExeArgs = InputRequester(#APP_NAME, "Steam.exe arguments for all Steam games (optional):", SteamExeArgs)
EndProcedure

Procedure AddHistoryEntry(msg.s)
  AddElement(HistoryActions())
  HistoryActions() = NowStamp() + "  " + msg
  While ListSize(HistoryActions()) > HistoryDepth * 3
    FirstElement(HistoryActions())
    DeleteElement(HistoryActions())
  Wend
EndProcedure

Procedure.s SerializeGamesState()
  Protected s.s, line.s
  ForEach Games()
    line = ReplaceString(Games()\Name, "|", "%7C") + "|" + ReplaceString(Games()\ExePath, "|", "%7C") + "|" + ReplaceString(Games()\Args, "|", "%7C") + "|" + ReplaceString(Games()\WorkDir, "|", "%7C") + "|" + Str(Games()\Priority) + "|" + Str(Games()\Affinity) + "|" + ReplaceString(Games()\Services, "|", "%7C") + "|" + Str(Games()\LaunchMode) + "|" + Str(Games()\SteamAppId) + "|" + ReplaceString(Games()\SteamExe, "|", "%7C") + "|" + ReplaceString(Games()\SteamGameArgs, "|", "%7C") + "|" + Str(Games()\SteamDetectTimeoutMs) + "|" + ReplaceString(Games()\GameRoot, "|", "%7C") + "|" + Str(Games()\Preset) + "|" + Str(Games()\PowerMode) + "|" + Str(Games()\OptimizeBackground) + "|" + ReplaceString(ReplaceString(Games()\Notes, "|", "%7C"), #CRLF$, "<br>") + "|" + ReplaceString(Games()\Tags, "|", "%7C") + "|" + Str(Games()\LaunchCount) + "|" + Str(Games()\LastPlayed) + "|" + Str(Games()\LastDurationSec)
    s + line + #LF$
  Next
  ProcedureReturn s
EndProcedure

Procedure RestoreGamesState(serialized.s)
  Protected i.i, line.s, g.GameEntry
  ClearList(Games())
  For i = 1 To CountString(serialized, #LF$) + 1
    line = Trim(StringField(serialized, i, #LF$))
    If Trim(line) <> ""
      g\Name = ReplaceString(StringField(line, 1, "|"), "%7C", "|")
      g\ExePath = ReplaceString(StringField(line, 2, "|"), "%7C", "|")
      g\Args = ReplaceString(StringField(line, 3, "|"), "%7C", "|")
      g\WorkDir = ReplaceString(StringField(line, 4, "|"), "%7C", "|")
      g\Priority = Val(StringField(line, 5, "|"))
      g\Affinity = Val(StringField(line, 6, "|"))
      g\Services = ReplaceString(StringField(line, 7, "|"), "%7C", "|")
      g\LaunchMode = Val(StringField(line, 8, "|"))
      g\SteamAppId = Val(StringField(line, 9, "|"))
      g\SteamExe = ReplaceString(StringField(line, 10, "|"), "%7C", "|")
      g\SteamGameArgs = ReplaceString(StringField(line, 11, "|"), "%7C", "|")
      g\SteamDetectTimeoutMs = Val(StringField(line, 12, "|"))
      g\GameRoot = ReplaceString(StringField(line, 13, "|"), "%7C", "|")
      g\Preset = Val(StringField(line, 14, "|"))
      g\PowerMode = Val(StringField(line, 15, "|"))
      g\OptimizeBackground = Val(StringField(line, 16, "|"))
      g\Notes = ReplaceString(ReplaceString(StringField(line, 17, "|"), "%7C", "|"), "<br>", #CRLF$)
      g\Tags = ReplaceString(StringField(line, 18, "|"), "%7C", "|")
      g\LaunchCount = Val(StringField(line, 19, "|"))
      g\LastPlayed = Val(StringField(line, 20, "|"))
      g\LastDurationSec = Val(StringField(line, 21, "|"))
      AddElement(Games())
      Games() = g
    EndIf
  Next
EndProcedure

Procedure CaptureUndoState(label.s)
  AddElement(UndoStates())
  UndoStates() = SerializeGamesState()
  AddElement(UndoLabels())
  UndoLabels() = label
  While ListSize(UndoStates()) > HistoryDepth
    FirstElement(UndoStates())
    DeleteElement(UndoStates())
    FirstElement(UndoLabels())
    DeleteElement(UndoLabels())
  Wend
  ClearList(RedoStates())
  ClearList(RedoLabels())
  UndoLabel = label
  AddHistoryEntry("Checkpoint: " + label)
EndProcedure

Procedure UndoLastLibraryChange()
  Protected state.s, label.s
  If ListSize(UndoStates()) = 0
    MessageRequester(#APP_NAME, "Nothing to undo.")
    ProcedureReturn
  EndIf
  AddElement(RedoStates())
  RedoStates() = SerializeGamesState()
  AddElement(RedoLabels())
  RedoLabels() = UndoLabel
  LastElement(UndoStates()) : state = UndoStates() : DeleteElement(UndoStates())
  LastElement(UndoLabels()) : label = UndoLabels() : DeleteElement(UndoLabels())
  RestoreGamesState(state)
  SaveGames()
  RefreshList()
  AddHistoryEntry("Undo: " + label)
  UndoLabel = label
  RedoLabel = label
  MessageRequester(#APP_NAME, "Undid: " + label)
EndProcedure

Procedure RedoLastLibraryChange()
  Protected state.s, label.s
  If ListSize(RedoStates()) = 0
    MessageRequester(#APP_NAME, "Nothing to redo.")
    ProcedureReturn
  EndIf
  AddElement(UndoStates())
  UndoStates() = SerializeGamesState()
  AddElement(UndoLabels())
  UndoLabels() = RedoLabel
  LastElement(RedoStates()) : state = RedoStates() : DeleteElement(RedoStates())
  LastElement(RedoLabels()) : label = RedoLabels() : DeleteElement(RedoLabels())
  RestoreGamesState(state)
  SaveGames()
  RefreshList()
  AddHistoryEntry("Redo: " + label)
  MessageRequester(#APP_NAME, "Redid: " + label)
EndProcedure

Procedure ShowHistory()
  Protected w.i, g.i, b.i, ev.i, text.s
  w = OpenWindow(#PB_Any, 0, 0, 680, 420, "History", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w = 0 : ProcedureReturn : EndIf
  If IsWindow(0) : DisableWindow(0, 1) : EndIf
  g = EditorGadget(#PB_Any, 10, 10, 660, 360)
  SetGadgetAttribute(g, #PB_Editor_ReadOnly, 1)
  b = ButtonGadget(#PB_Any, 580, 380, 90, 28, "Close")
  ForEach HistoryActions()
    text + HistoryActions() + #CRLF$
  Next
  SetGadgetText(g, text)
  Repeat
    ev = WaitWindowEvent()
  Until ev = #PB_Event_CloseWindow Or (ev = #PB_Event_Gadget And EventGadget() = b)
  CloseWindow(w)
  If IsWindow(0) : DisableWindow(0, 0) : EndIf
EndProcedure

Procedure ShowSettings()
  Enumeration _SetWin 7000
    #W_Settings
  EndEnumeration
  Enumeration _SetGad 7100
    #S_DefaultPreset
    #S_ThumbSize
    #S_RememberView
    #S_HistoryDepth
    #S_SteamArgs
    #S_Save
    #S_Cancel
  EndEnumeration
  Protected w.i, ev.i
  w = OpenWindow(#W_Settings, 0, 0, 380, 280, "Settings", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w = 0 : ProcedureReturn : EndIf
  If IsWindow(0) : DisableWindow(0, 1) : EndIf
  TextGadget(#PB_Any, 16, 20, 120, 20, "Default preset")
  ComboBoxGadget(#S_DefaultPreset, 140, 16, 180, 24)
  AddGadgetItem(#S_DefaultPreset, -1, "Safe")
  AddGadgetItem(#S_DefaultPreset, -1, "Balanced")
  AddGadgetItem(#S_DefaultPreset, -1, "Aggressive")
  SetGadgetState(#S_DefaultPreset, DefaultPreset)
  TextGadget(#PB_Any, 16, 56, 120, 20, "Thumbnail size")
  StringGadget(#S_ThumbSize, 140, 52, 60, 24, Str(ThumbnailSize))
  CheckBoxGadget(#S_RememberView, 140, 90, 180, 22, "Remember last view")
  SetGadgetState(#S_RememberView, RememberLastView)
  TextGadget(#PB_Any, 16, 122, 120, 20, "History depth")
  StringGadget(#S_HistoryDepth, 140, 118, 60, 24, Str(HistoryDepth))
  ButtonGadget(#S_SteamArgs, 140, 154, 180, 28, "Steam.exe Args...")
  ButtonGadget(#S_Save, 190, 216, 70, 28, "Save")
  ButtonGadget(#S_Cancel, 270, 216, 70, 28, "Cancel")
  Repeat
    ev = WaitWindowEvent()
    If ev = #PB_Event_Gadget
      Select EventGadget()
        Case #S_SteamArgs
          EditGlobalSteamArgs()
        Case #S_Save
          DefaultPreset = GetGadgetState(#S_DefaultPreset)
          ThumbnailSize = Val(GetGadgetText(#S_ThumbSize))
          RememberLastView = GetGadgetState(#S_RememberView)
          HistoryDepth = Val(GetGadgetText(#S_HistoryDepth))
          If ThumbnailSize < 16 : ThumbnailSize = 16 : EndIf
          If ThumbnailSize > 32 : ThumbnailSize = 32 : EndIf
          If HistoryDepth < 1 : HistoryDepth = 1 : EndIf
          If HistoryDepth > 25 : HistoryDepth = 25 : EndIf
          ClearMap(GameThumbnail())
          SaveSettings()
          RefreshList()
          Break
        Case #S_Cancel
          Break
      EndSelect
    ElseIf ev = #PB_Event_CloseWindow
      Break
    EndIf
  ForEver
  CloseWindow(#W_Settings)
  If IsWindow(0) : DisableWindow(0, 0) : EndIf
EndProcedure

Procedure.s QuotedField(line.s, n.i)
  Protected i.i, q.i, start.i, count.i
  For i = 1 To Len(line)
    If Mid(line, i, 1) = #DQUOTE$
      If q = 0
        q = 1
        start = i + 1
      Else
        q = 0
        count + 1
        If count = n
          ProcedureReturn Mid(line, start, i - start)
        EndIf
      EndIf
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.s VdfUnescape(s.s)
  s = ReplaceString(s, "\\", "\")
  s = ReplaceString(s, "\\" + Chr(34), Chr(34))
  ProcedureReturn s
EndProcedure

Procedure.i ClampSteamDetectTimeout(timeoutMs.i)
  If timeoutMs < 5000 : ProcedureReturn 60000 : EndIf
  If timeoutMs > 300000 : ProcedureReturn 300000 : EndIf
  ProcedureReturn timeoutMs
EndProcedure

Procedure.s CollapseBackslashes(p.s)
  While FindString(p, "\\\\", 1)
    p = ReplaceString(p, "\\\\", "\\")
  Wend
  ProcedureReturn p
EndProcedure

Procedure.s GetActivePowerGuid()
  Protected out.s = RunAndCapture("powercfg /getactivescheme")
  Protected p.i = FindString(out, ":", 1)
  If p = 0 : p = FindString(out, "GUID", 1) : EndIf
  Protected i.i, token.s, c.s
  For i = 1 To Len(out)
    c = Mid(out, i, 1)
    If (c >= "0" And c <= "9") Or (c >= "a" And c <= "f") Or (c >= "A" And c <= "F") Or c = "-"
      token + c
      If Len(token) >= 36
        ProcedureReturn Left(token, 36)
      EndIf
    Else
      token = ""
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.i SetActivePowerGuid(guid.s)
  Protected activeGuid.s
  If guid = "" : ProcedureReturn 0 : EndIf
  RunAndCapture("powercfg /setactive " + guid)
  activeGuid = GetActivePowerGuid()
  If activeGuid <> "" And LCase(activeGuid) = LCase(guid)
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i OpenOrCreatePreferences(filePath.s)
  If OpenPreferences(filePath)
    ProcedureReturn 1
  EndIf
  If CreatePreferences(filePath)
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure SaveSession(prevPowerGuid.s, didSwitchPower.i, stoppedServices.s)
  If OpenOrCreatePreferences(SessionIni)
    PreferenceGroup("session")
    WritePreferenceInteger("didSwitchPower", didSwitchPower)
    WritePreferenceString("prevPowerGuid", prevPowerGuid)
    WritePreferenceInteger("didStopServices", Bool(stoppedServices <> ""))
    WritePreferenceString("stoppedServices", stoppedServices)
    WritePreferenceInteger("cleanExit", 0)
    ClosePreferences()
    LogLine("Session saved; powerSwitched=" + Str(didSwitchPower) + " servicesStopped=" + Str(Bool(stoppedServices <> "")))
  EndIf
EndProcedure

Procedure MarkSessionClean()
  If OpenOrCreatePreferences(SessionIni)
    PreferenceGroup("session")
    WritePreferenceInteger("cleanExit", 1)
    ClosePreferences()
    LogLine("Session marked clean")
  EndIf
EndProcedure

Procedure RestoreIfDirtySession()
  Protected didSwitchPower.i, cleanExit.i
  Protected prevPowerGuid.s
  Protected didStopServices.i
  Protected stoppedServices.s

  If FileSize(SessionIni) <= 0 : ProcedureReturn : EndIf

  If OpenPreferences(SessionIni)
    PreferenceGroup("session")
    didSwitchPower = ReadPreferenceInteger("didSwitchPower", 0)
    prevPowerGuid  = ReadPreferenceString("prevPowerGuid", "")
    didStopServices = ReadPreferenceInteger("didStopServices", 0)
    stoppedServices = ReadPreferenceString("stoppedServices", "")
    cleanExit = ReadPreferenceInteger("cleanExit", 1)
    ClosePreferences()
  EndIf

  If cleanExit = 0
    LogLine("Dirty session detected; restoring")
    If didStopServices And stoppedServices <> ""
      LogLine("Restarting services from crash: " + stoppedServices)
      RestartServicesPipeListAndLog(stoppedServices, "crash-restore")
    EndIf
    If didSwitchPower And prevPowerGuid <> ""
      LogLine("Restoring power plan: " + prevPowerGuid)
      SetActivePowerGuid(prevPowerGuid)
    EndIf
    MarkSessionClean()
  EndIf
EndProcedure

Procedure CleanupAfterLaunch(prevPowerGuid.s, didSwitchPower.i, stoppedServices.s)
  Protected restoredPower.i
  If stoppedServices <> ""
    RestartServicesPipeListAndLog(stoppedServices, "cleanup")
  EndIf
  If didSwitchPower And prevPowerGuid <> ""
    SetActivePowerGuid(prevPowerGuid)
    restoredPower = 1
    LogLine("Power plan restored: " + prevPowerGuid)
  EndIf
  If (stoppedServices <> "") Or restoredPower
    MarkSessionClean()
  EndIf
EndProcedure

Procedure PrepareBoostSession(*g.GameEntry, *ctx.BoostSessionContext)
  Protected resolvedMode.i

  *ctx\PrevPowerGuid = GetActivePowerGuid()
  *ctx\AppliedPowerGuid = ""
  *ctx\DidSwitchPower = 0
  *ctx\StoppedServices = ""

  If *ctx\PrevPowerGuid <> "" And *g\PowerMode <> #POWERMODE_KEEP
    resolvedMode = ResolvePowerMode(*g\PowerMode, *ctx\PrevPowerGuid)
    Select resolvedMode
      Case 1
        *ctx\DidSwitchPower = 1
        *ctx\AppliedPowerGuid = #POWER_GUID_HIGH
        SaveSession(*ctx\PrevPowerGuid, 1, "")
        LogLine("Power plan -> High performance; prev=" + *ctx\PrevPowerGuid)
      Case 2
        *ctx\DidSwitchPower = 1
        *ctx\AppliedPowerGuid = #POWER_GUID_ULTIMATE
        SaveSession(*ctx\PrevPowerGuid, 1, "")
        LogLine("Power plan -> Ultimate Performance; prev=" + *ctx\PrevPowerGuid)
      Default
        LogLine("Power plan unchanged; requested=" + FormatPowerModeLabel(*g\PowerMode))
    EndSelect
  EndIf

  If *g\Services <> ""
    LogLine("Stopping services (configured): " + *g\Services)
    *ctx\StoppedServices = StopServicesCsvAndLog(*g\Services, *g\Name)
    LogLine("Stopped services (effective): " + *ctx\StoppedServices)
    If *ctx\StoppedServices <> "" Or *ctx\DidSwitchPower
      SaveSession(*ctx\PrevPowerGuid, *ctx\DidSwitchPower, *ctx\StoppedServices)
    EndIf
  EndIf
EndProcedure

Procedure CleanupBoostSession(*ctx.BoostSessionContext)
  CleanupAfterLaunch(*ctx\PrevPowerGuid, *ctx\DidSwitchPower, *ctx\StoppedServices)
EndProcedure

Procedure ApplyProcessBoost(hProcess.i, *g.GameEntry)
  If *g\Priority
    SetPriorityClass_(hProcess, *g\Priority)
    LogLine("Set priority class=" + Str(*g\Priority))
  EndIf
  If *g\Affinity
    SetProcessAffinityMask_(hProcess, *g\Affinity)
    LogLine("Set affinity mask=" + Hex(*g\Affinity))
  EndIf
EndProcedure

Procedure RestoreProcessBoost(hProcess.i, gotAffinity.i, origPriority.l, processAffinity.q)
  If gotAffinity
    SetProcessAffinityMask_(hProcess, processAffinity)
  EndIf
  If origPriority
    SetPriorityClass_(hProcess, origPriority)
  EndIf
EndProcedure
