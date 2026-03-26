; Steam discovery, service control, and edit dialogs.

Procedure.s RegReadString(root.i, subKey.s, valueName.s)
  Protected hKey.i, type.l, cb.l
  Protected out.s

  If RegOpenKeyEx_(root, subKey, 0, #KEY_READ, @hKey)
    ProcedureReturn ""
  EndIf
  If RegQueryValueEx_(hKey, valueName, 0, @type, 0, @cb)
    RegCloseKey_(hKey)
    ProcedureReturn ""
  EndIf
  If (type <> #REG_SZ And type <> #REG_EXPAND_SZ) Or cb <= 2
    RegCloseKey_(hKey)
    ProcedureReturn ""
  EndIf

  out = Space((cb / SizeOf(Character)) + 2)
  If RegQueryValueEx_(hKey, valueName, 0, @type, @out, @cb) = 0
    out = PeekS(@out, -1)
  Else
    out = ""
  EndIf
  RegCloseKey_(hKey)
  ProcedureReturn out
EndProcedure

Procedure.s FindSteamExe()
  Protected p.s
  p = RegReadString(#HKEY_CURRENT_USER, "Software\\Valve\\Steam", "SteamExe")
  If p <> "" And LCase(GetExtensionPart(p)) = "exe" : ProcedureReturn p : EndIf

  p = RegReadString(#HKEY_CURRENT_USER, "Software\\Valve\\Steam", "SteamPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  p = RegReadString(#HKEY_LOCAL_MACHINE, "SOFTWARE\\WOW6432Node\\Valve\\Steam", "InstallPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  p = RegReadString(#HKEY_LOCAL_MACHINE, "SOFTWARE\\Valve\\Steam", "InstallPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure AddUniqueString(List L.s(), s.s)
  If s = "" : ProcedureReturn : EndIf
  ForEach L()
    If LCase(L()) = LCase(s)
      ProcedureReturn
    EndIf
  Next
  AddElement(L())
  L() = s
EndProcedure

Procedure GetSteamLibraries(steamRoot.s, List libs.s())
  ClearList(libs())
  steamRoot = EnsureTrailingSlash(steamRoot)
  AddUniqueString(libs(), steamRoot)

  Protected vdf.s = PathJoin(steamRoot, "steamapps\\libraryfolders.vdf")
  If FileSize(vdf) <= 0 : ProcedureReturn : EndIf

  Protected line.s, k.s, v.s
  If ReadFile(0, vdf)
    While Eof(0) = 0
      line = ReadString(0)
      k = QuotedField(line, 1)
      v = VdfUnescape(QuotedField(line, 2))
      If v <> ""
        If LCase(k) = "path"
          AddUniqueString(libs(), EnsureTrailingSlash(v))
        ElseIf Val(k) > 0 Or k = "0"
          If FindString(v, ":\\", 1) Or Left(v, 2) = "\\\\"
            AddUniqueString(libs(), EnsureTrailingSlash(v))
          EndIf
        EndIf
      EndIf
    Wend
    CloseFile(0)
  EndIf
EndProcedure

Procedure.s ReadAcfField(acfPath.s, keyWanted.s)
  Protected line.s, k.s, v.s
  If ReadFile(0, acfPath)
    While Eof(0) = 0
      line = ReadString(0)
      k = QuotedField(line, 1)
      If LCase(k) = LCase(keyWanted)
        v = QuotedField(line, 2)
        CloseFile(0)
        ProcedureReturn v
      EndIf
    Wend
    CloseFile(0)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.i GamesHasSteamApp(appId.i)
  If appId <= 0 : ProcedureReturn 0 : EndIf
  ForEach Games()
    If Games()\LaunchMode = 1 And Games()\SteamAppId = appId
      ProcedureReturn 1
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

Procedure.s GetSteamGameRootByAppId(steamExe.s, appId.i)
  Protected steamRoot.s, steamapps.s, acf.s, installdir.s
  Protected NewList libs.s()
  Protected lib.s, commonRoot.s

  If appId <= 0 : ProcedureReturn "" : EndIf
  If steamExe = "" Or FileSize(steamExe) <= 0
    steamExe = FindSteamExe()
  EndIf
  If steamExe = "" Or FileSize(steamExe) <= 0 : ProcedureReturn "" : EndIf

  steamRoot = EnsureTrailingSlash(GetPathPart(steamExe))
  GetSteamLibraries(steamRoot, libs())
  If ListSize(libs()) = 0 : ProcedureReturn "" : EndIf

  ForEach libs()
    lib = EnsureTrailingSlash(libs())
    steamapps = PathJoin(lib, "steamapps\\")
    If FileSize(steamapps) <> -2
      Continue
    EndIf
    acf = PathJoin(steamapps, "appmanifest_" + Str(appId) + ".acf")
    If FileSize(acf) > 0
      installdir = ReadAcfField(acf, "installdir")
      If installdir <> ""
        commonRoot = PathJoin(lib, "steamapps\\common\\")
        ProcedureReturn EnsureTrailingSlash(PathJoin(commonRoot, installdir))
      EndIf
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure.s ResolveSteamGameRoot(*g.GameEntry)
  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0
    *g\SteamExe = FindSteamExe()
  EndIf
  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0 : ProcedureReturn "" : EndIf
  If *g\SteamAppId <= 0 : ProcedureReturn "" : EndIf
  If *g\GameRoot = "" Or FileSize(*g\GameRoot) <> -2
    *g\GameRoot = GetSteamGameRootByAppId(*g\SteamExe, *g\SteamAppId)
  EndIf
  ProcedureReturn *g\GameRoot
EndProcedure

Structure SteamImportOption
  AppId.i
  Name.s
  InstallDir.s
  LibraryRoot.s
EndStructure

Procedure.i PickSteamGameDialog(List options.SteamImportOption())
  Enumeration _SteamPickerWindows 4000
    #W_SteamPick
  EndEnumeration
  Enumeration _SteamPickerGadgets 4100
    #SP_Info
    #SP_List
    #SP_Import
    #SP_ImportAll
    #SP_Cancel
  EndEnumeration

  Protected w.i, ev.i, selectedRow.i, selectedAppId.i

  w = OpenWindow(#W_SteamPick, 0, 0, 860, 520, "Import Steam Game", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w = 0
    ProcedureReturn 0
  EndIf

  If IsWindow(0)
    DisableWindow(0, 1)
  EndIf

  TextGadget(#SP_Info, 12, 12, 836, 36, "Select one installed Steam game to import, or use Import All. Only games not already in your list are shown. Double-click a row to import it immediately.")
  ListIconGadget(#SP_List, 12, 58, 836, 404, "Game", 290, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#SP_List, 1, "AppID", 90)
  AddGadgetColumn(#SP_List, 2, "Install Folder", 420)
  ButtonGadget(#SP_Import, 544, 474, 96, 30, "Import")
  ButtonGadget(#SP_ImportAll, 648, 474, 96, 30, "Import All")
  ButtonGadget(#SP_Cancel, 752, 474, 96, 30, "Cancel")

  If FontUI
    SetGadgetFont(#SP_Info, FontID(FontUI))
    SetGadgetFont(#SP_List, FontID(FontUI))
    SetGadgetFont(#SP_Import, FontID(FontUI))
    SetGadgetFont(#SP_ImportAll, FontID(FontUI))
    SetGadgetFont(#SP_Cancel, FontID(FontUI))
  EndIf

  ForEach options()
    AddGadgetItem(#SP_List, -1, options()\Name + Chr(10) + Str(options()\AppId) + Chr(10) + options()\InstallDir)
  Next

  If CountGadgetItems(#SP_List) > 0
    SetGadgetState(#SP_List, 0)
    SetGadgetItemState(#SP_List, 0, #PB_ListIcon_Selected)
    SetActiveGadget(#SP_List)
  EndIf
  DisableGadget(#SP_Import, Bool(CountGadgetItems(#SP_List) = 0))
  DisableGadget(#SP_ImportAll, Bool(CountGadgetItems(#SP_List) = 0))

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #SP_List
            If EventType() = #PB_EventType_LeftDoubleClick
              selectedRow = GetGadgetState(#SP_List)
              If selectedRow >= 0 And SelectElement(options(), selectedRow)
                selectedAppId = options()\AppId
                Break
              EndIf
            Else
              DisableGadget(#SP_Import, Bool(GetGadgetState(#SP_List) < 0))
            EndIf
          Case #SP_Import
            selectedRow = GetGadgetState(#SP_List)
            If selectedRow >= 0 And SelectElement(options(), selectedRow)
              selectedAppId = options()\AppId
              Break
            EndIf
          Case #SP_ImportAll
            selectedAppId = -1
            Break
          Case #SP_Cancel
            Break
        EndSelect

      Case #PB_Event_CloseWindow
        If EventWindow() = #W_SteamPick
          Break
        EndIf
    EndSelect
  ForEver

  CloseWindow(#W_SteamPick)
  If IsWindow(0)
    DisableWindow(0, 0)
  EndIf
  ProcedureReturn selectedAppId
EndProcedure

Procedure ImportSingleSteamGame()
  Protected steamExe.s = FindSteamExe()
  If steamExe = ""
    MessageRequester(#APP_NAME, "Steam not found (registry).")
    ProcedureReturn
  EndIf
  LogLine("Import single Steam game requested")

  Protected steamRoot.s = EnsureTrailingSlash(GetPathPart(steamExe))
  Protected NewList libs.s()
  Protected NewList options.SteamImportOption()
  Protected NewMap seenApp.i()
  GetSteamLibraries(steamRoot, libs())

  Protected lib.s, steamapps.s, file.s, appId.i, name.s, installdir.s
  Protected commonRoot.s
  Protected added.i, selectedAppId.i

  ForEach libs()
    lib = EnsureTrailingSlash(libs())
    steamapps = PathJoin(lib, "steamapps\\")
    If FileSize(steamapps) <> -2
      Continue
    EndIf

    If ExamineDirectory(#DIRID_STEAM_MANIFESTS, steamapps, "appmanifest_*.acf")
      While NextDirectoryEntry(#DIRID_STEAM_MANIFESTS)
        If DirectoryEntryType(#DIRID_STEAM_MANIFESTS) = #PB_DirectoryEntry_File
          file = DirectoryEntryName(#DIRID_STEAM_MANIFESTS)
          appId = Val(ReplaceString(ReplaceString(file, "appmanifest_", ""), ".acf", ""))
          If appId > 0 And GamesHasSteamApp(appId) = 0 And FindMapElement(seenApp(), Str(appId)) = 0
            name = ReadAcfField(PathJoin(steamapps, file), "name")
            installdir = ReadAcfField(PathJoin(steamapps, file), "installdir")
            If name <> "" And installdir <> ""
              AddElement(options())
              options()\AppId = appId
              options()\Name = name
              options()\InstallDir = installdir
              options()\LibraryRoot = lib
              seenApp(Str(appId)) = 1
            EndIf
          EndIf
        EndIf
      Wend
      FinishDirectory(#DIRID_STEAM_MANIFESTS)
    EndIf
  Next

  If ListSize(options()) = 0
    MessageRequester(#APP_NAME, "No new Steam games are available to import.")
    ProcedureReturn
  EndIf

  selectedAppId = PickSteamGameDialog(options())
  If selectedAppId = 0
    ProcedureReturn
  EndIf

  ForEach options()
    If selectedAppId = -1 Or options()\AppId = selectedAppId
      AddElement(Games())
      Games()\Name = options()\Name
      Games()\ExePath = ""
      Games()\Args = ""
      Games()\WorkDir = ""
      Games()\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
      Games()\Affinity = 0
      Games()\Services = ""
      Games()\LaunchMode = 1
      Games()\SteamAppId = options()\AppId
      Games()\SteamExe = steamExe
      Games()\SteamGameArgs = ""
      Games()\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
      commonRoot = PathJoin(options()\LibraryRoot, "steamapps\\common\\")
      Games()\GameRoot = EnsureTrailingSlash(PathJoin(commonRoot, options()\InstallDir))
      ApplyPresetDefaults(@Games(), DefaultPreset)
      Games()\Notes = ""
      Games()\Tags = "steam"
      Games()\LaunchCount = 0
      Games()\LastPlayed = 0
      Games()\LastDurationSec = 0
      added + 1
      If name <> "" : name + ", " : EndIf
      name + options()\Name
      If selectedAppId <> -1
        Break
      EndIf
    EndIf
  Next

  If added
    SaveGames()
    RefreshList()
    If selectedAppId = -1
      MessageRequester(#APP_NAME, "Imported " + Str(added) + " Steam game(s).")
    Else
      MessageRequester(#APP_NAME, "Imported Steam game: " + name)
    EndIf
  Else
    MessageRequester(#APP_NAME, "That Steam game could not be imported.")
  EndIf
  LogLine("Imported Steam game picker count: " + Str(added) + " | Selection=" + Str(selectedAppId))
EndProcedure

Procedure.s RunPowerShellAndCapture(ps.s)
  ProcedureReturn RunProgramAndCapture("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + ps + #DQUOTE$)
EndProcedure

Procedure.i IsProtectedServiceName(name.s)
  Protected key.s = LCase(Trim(name))
  Select key
    Case "winmgmt", "rpcss", "dcomlaunch", "eventlog", "plugplay", "bfe", "mpssvc", "audiosrv", "dhcp", "dnscache", "lanmanworkstation", "lanmanserver", "nlasvc", "wlansvc", "cryptsvc", "trustedinstaller", "wuauserv", "schedule", "power", "profsvc", "gpsvc", "themes", "samss", "lsm", "termservice", "w32time"
      ProcedureReturn 1
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure.i IsRiskyServiceName(name.s)
  Protected key.s = LCase(Trim(name))
  If IsProtectedServiceName(key)
    ProcedureReturn 0
  EndIf

  If FindString(key, "anti", 1) Or FindString(key, "cheat", 1) Or FindString(key, "defender", 1) Or FindString(key, "security", 1) Or FindString(key, "vpn", 1) Or FindString(key, "audio", 1) Or FindString(key, "network", 1) Or FindString(key, "firewall", 1) Or FindString(key, "update", 1)
    ProcedureReturn 1
  EndIf

  Select key
    Case "wscsvc", "windefend", "sense", "securityhealthservice", "mpssvc", "audiosrv", "audioendpointbuilder", "nlasvc", "netprofm", "lanmanworkstation", "lanmanserver", "bits", "cscservice", "vgc", "vgk", "easyanticheat", "bedaisy"
      ProcedureReturn 1
  EndSelect

  ProcedureReturn 0
EndProcedure

Procedure.s SanitizeServiceCsv(csv.s, allowProtected.i, logContext.s = "")
  Protected NewMap seen.i()
  Protected outCsv.s
  Protected i.i, n.i
  Protected original.s, name.s, key.s

  csv = Trim(csv)
  If csv = "" : ProcedureReturn "" : EndIf

  n = CountString(csv, ",") + 1
  For i = 1 To n
    original = Trim(StringField(csv, i, ","))
    If original = "" : Continue : EndIf
    name = RemoveString(RemoveString(original, #CR$), #LF$)
    key = LCase(name)
    If FindMapElement(seen(), key)
      Continue
    EndIf
    If allowProtected = 0 And IsProtectedServiceName(name)
      If logContext <> ""
        LogLine("[" + logContext + "] Skipping protected service: " + name)
      Else
        LogLine("Skipping protected service: " + name)
      EndIf
      Continue
    EndIf

    seen(key) = 1
    If outCsv <> "" : outCsv + "," : EndIf
    outCsv + name
  Next

  ProcedureReturn outCsv
EndProcedure

Procedure.s BuildSelectedServiceCsv(Map selected.i(), Map selectedName.s())
  Protected outCsv.s

  ForEach selected()
    If selected()
      If outCsv <> "" : outCsv + "," : EndIf
      If FindMapElement(selectedName(), MapKey(selected())) And selectedName() <> ""
        outCsv + selectedName()
      Else
        outCsv + MapKey(selected())
      EndIf
    EndIf
  Next

  ProcedureReturn outCsv
EndProcedure

Procedure.s RiskySelectedServicesCsv(Map selected.i(), Map selectedName.s())
  Protected riskyCsv.s
  Protected name.s

  ForEach selected()
    If selected()
      If FindMapElement(selectedName(), MapKey(selected())) And selectedName() <> ""
        name = selectedName()
      Else
        name = MapKey(selected())
      EndIf
      If IsRiskyServiceName(name)
        If riskyCsv <> "" : riskyCsv + "," : EndIf
        riskyCsv + name
      EndIf
    EndIf
  Next

  ProcedureReturn riskyCsv
EndProcedure

Procedure.i ConfirmRiskyServicesIfNeeded(csv.s)
  Protected riskyCsv.s
  Protected riskyCount.i
  Protected title.s
  Protected msg.s

  csv = SanitizeServiceCsv(csv, 1)
  If csv = "" : ProcedureReturn 1 : EndIf

  Protected i.i, n.i
  Protected item.s
  n = CountString(csv, ",") + 1
  For i = 1 To n
    item = Trim(StringField(csv, i, ","))
    If item <> "" And IsRiskyServiceName(item)
      If riskyCsv <> "" : riskyCsv + ", " : EndIf
      riskyCsv + item
      riskyCount + 1
    EndIf
  Next

  If riskyCount = 0
    ProcedureReturn 1
  EndIf

  title = #APP_NAME
  msg = "Warning: the selected service list includes potentially risky items." + #LF$ + #LF$ +
        riskyCsv + #LF$ + #LF$ +
        "Stopping these may break audio, networking, security software, or anti-cheat for some games." + #LF$ + #LF$ +
        "Continue anyway?"
  ProcedureReturn Bool(MessageRequester(title, msg, #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure ApplyServiceListStyling(listGadget.i)
  Protected r.i
  Protected name.s

  For r = 0 To CountGadgetItems(listGadget) - 1
    name = Trim(GetGadgetItemText(listGadget, r, 1))
    If name <> "" And IsRiskyServiceName(name)
      SetGadgetItemColor(listGadget, r, #PB_Gadget_FrontColor, RGB(170, 90, 0))
      SetGadgetItemColor(listGadget, r, #PB_Gadget_BackColor, RGB(255, 245, 220))
    Else
      SetGadgetItemColor(listGadget, r, #PB_Gadget_FrontColor, RGB(0, 0, 0))
      SetGadgetItemColor(listGadget, r, #PB_Gadget_BackColor, RGB(255, 255, 255))
    EndIf
  Next
EndProcedure

Procedure.s StopServicesCsvAndLog(csv.s, context.s)
  Protected out.s, line.s
  Protected sep.s = Chr(31)
  Protected i.i, n.i
  Protected name.s, action.s, result.s, before.s, after.s
  Protected stoppedPipe.s
  Protected ps.s

  csv = SanitizeServiceCsv(csv, 0, context)
  If csv = "" : ProcedureReturn "" : EndIf

  ps = "$sep=[char]31;"
  ps + "$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ };"
  ps + "foreach($n in $names){"
  ps + "  $before='';$after='';$result='';"
  ps + "  try{"
  ps + "    $svc=Get-Service -Name $n -ErrorAction Stop;"
  ps + "    $before=$svc.Status.ToString();"
  ps + "    if($svc.Status -ne 'Stopped'){"
  ps + "      Stop-Service -Name $n -Force -ErrorAction Stop;"
  ps + "      Start-Sleep -Milliseconds 200;"
  ps + "      $after=(Get-Service -Name $n -ErrorAction SilentlyContinue).Status.ToString();"
  ps + "      $result='OK';"
  ps + "    } else { $after=$before; $result='AlreadyStopped' }"
  ps + "  } catch { $msg=$_.Exception.Message -replace '[\r\n\t]',' '; $result='Error:'+$msg }"
  ps + "  $n+$sep+'Stop'+$sep+$result+$sep+$before+$sep+$after"
  ps + "}"
  out = RunPowerShellAndCapture(ps)

  n = CountString(out, #LF$) + 1
  For i = 1 To n
    line = StringField(out, i, #LF$)
    If line = "" : Continue : EndIf
    name   = Trim(StringField(line, 1, sep))
    action = Trim(StringField(line, 2, sep))
    result = Trim(StringField(line, 3, sep))
    before = Trim(StringField(line, 4, sep))
    after  = Trim(StringField(line, 5, sep))

    If name <> ""
      If context <> ""
        LogLine("[" + context + "] " + action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      Else
        LogLine(action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      EndIf
    EndIf

    If LCase(action) = "stop" And LCase(result) = "ok" And LCase(after) = "stopped"
      If stoppedPipe <> "" : stoppedPipe + "|" : EndIf
      stoppedPipe + name
    EndIf
  Next

  ProcedureReturn stoppedPipe
EndProcedure

Procedure StartServicesCsvAndLog(csv.s, context.s)
  Protected out.s, line.s
  Protected sep.s = Chr(31)
  Protected i.i, n.i
  Protected name.s, action.s, result.s, before.s, after.s
  Protected ps.s

  csv = SanitizeServiceCsv(csv, 1, context)
  If csv = "" : ProcedureReturn : EndIf

  ps = "$sep=[char]31;"
  ps + "$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ };"
  ps + "foreach($n in $names){"
  ps + "  $before='';$after='';$result='';"
  ps + "  try{"
  ps + "    $svc=Get-Service -Name $n -ErrorAction Stop;"
  ps + "    $before=$svc.Status.ToString();"
  ps + "    if($svc.Status -ne 'Running'){"
  ps + "      Start-Service -Name $n -ErrorAction Stop;"
  ps + "      Start-Sleep -Milliseconds 200;"
  ps + "      $after=(Get-Service -Name $n -ErrorAction SilentlyContinue).Status.ToString();"
  ps + "      $result='OK';"
  ps + "    } else { $after=$before; $result='AlreadyRunning' }"
  ps + "  } catch { $msg=$_.Exception.Message -replace '[\r\n\t]',' '; $result='Error:'+$msg }"
  ps + "  $n+$sep+'Start'+$sep+$result+$sep+$before+$sep+$after"
  ps + "}"
  out = RunPowerShellAndCapture(ps)

  n = CountString(out, #LF$) + 1
  For i = 1 To n
    line = StringField(out, i, #LF$)
    If line = "" : Continue : EndIf
    name   = Trim(StringField(line, 1, sep))
    action = Trim(StringField(line, 2, sep))
    result = Trim(StringField(line, 3, sep))
    before = Trim(StringField(line, 4, sep))
    after  = Trim(StringField(line, 5, sep))
    If name <> ""
      If context <> ""
        LogLine("[" + context + "] " + action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      Else
        LogLine(action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      EndIf
    EndIf
  Next
EndProcedure

Procedure.s PshEscapeSingle(s.s)
  ProcedureReturn ReplaceString(s, "'", "''")
EndProcedure

Procedure RestartServicesPipeListAndLog(stoppedServices.s, context.s)
  If stoppedServices = "" : ProcedureReturn : EndIf
  Protected csv.s = ReplaceString(stoppedServices, "|", ",")
  If context <> ""
    LogLine("[" + context + "] Restarting services: " + stoppedServices)
  Else
    LogLine("Restarting services: " + stoppedServices)
  EndIf
  StartServicesCsvAndLog(csv, context)
EndProcedure

Procedure GetAllServices(List out.ServiceInfo())
  ClearList(out())
  Protected raw.s, line.s, n.i
  Protected sep.s = Chr(31)
  raw = RunPowerShellAndCapture("Get-Service | ForEach-Object { $_.Name + [char]31 + $_.DisplayName + [char]31 + $_.Status + [char]31 + $_.StartType }")
  If raw = "" : ProcedureReturn : EndIf
  n = CountString(raw, #LF$) + 1

  Protected i.i
  Protected si.ServiceInfo
  For i = 1 To n
    line = StringField(raw, i, #LF$)
    If line = "" : Continue : EndIf
    si\Name        = StringField(line, 1, sep)
    si\DisplayName = StringField(line, 2, sep)
    si\Status      = StringField(line, 3, sep)
    si\StartType   = StringField(line, 4, sep)
    If si\Name <> ""
      AddElement(out())
      out() = si
    EndIf
  Next
EndProcedure

Procedure FillServiceList(listGadget.i, showAll.i, Map selected.i(), List all.ServiceInfo(), List recommended.s(), Map byName.ServiceInfo())
  ClearGadgetItems(listGadget)
  Protected sel.s, key.s
  Protected si.ServiceInfo

  If showAll
    ForEach all()
      sel = ""
      If FindMapElement(selected(), LCase(all()\Name)) And selected() : sel = "X" : EndIf
      AddGadgetItem(listGadget, -1, sel + Chr(10) + all()\Name + Chr(10) + all()\DisplayName + Chr(10) + all()\Status + Chr(10) + all()\StartType)
    Next
  Else
    ForEach recommended()
      key = LCase(recommended())
      If FindMapElement(byName(), key)
        si = byName()
        sel = ""
        If FindMapElement(selected(), LCase(si\Name)) And selected() : sel = "X" : EndIf
        AddGadgetItem(listGadget, -1, sel + Chr(10) + si\Name + Chr(10) + si\DisplayName + Chr(10) + si\Status + Chr(10) + si\StartType)
      EndIf
    Next
  EndIf

  ApplyServiceListStyling(listGadget)
EndProcedure

Procedure ToggleSelectedRows(listGadget.i, Map selected.i(), Map selectedName.s())
  Protected r.i, nameOrig.s, nameKey.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    If GetGadgetItemState(listGadget, r) & #PB_ListIcon_Selected
      nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
      nameKey = LCase(nameOrig)
      If nameKey <> ""
        If FindMapElement(selected(), nameKey) And selected()
          selected() = 0
          SetGadgetItemText(listGadget, r, "", 0)
        Else
          selected(nameKey) = 1
          selectedName(nameKey) = nameOrig
          SetGadgetItemText(listGadget, r, "X", 0)
        EndIf
      EndIf
    EndIf
  Next
EndProcedure

Procedure ClearAllSelected(listGadget.i, Map selected.i(), Map selectedName.s())
  ClearMap(selected())
  ClearMap(selectedName())
  Protected r.i
  For r = 0 To CountGadgetItems(listGadget) - 1
    SetGadgetItemText(listGadget, r, "", 0)
  Next
EndProcedure

Procedure SelectAllShown(listGadget.i, Map selected.i(), Map selectedName.s())
  Protected r.i, nameOrig.s, nameKey.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
    nameKey = LCase(nameOrig)
    If nameKey <> ""
      selected(nameKey) = 1
      selectedName(nameKey) = nameOrig
      SetGadgetItemText(listGadget, r, "X", 0)
    EndIf
  Next
EndProcedure

Procedure.s SelectedNamesCsv(listGadget.i)
  Protected r.i, nameOrig.s, csv.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    If GetGadgetItemState(listGadget, r) & #PB_ListIcon_Selected
      nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
      If nameOrig <> ""
        If csv <> "" : csv + "," : EndIf
        csv + nameOrig
      EndIf
    EndIf
  Next
  ProcedureReturn csv
EndProcedure

Procedure StopServicesNow(csv.s)
  csv = SanitizeServiceCsv(csv, 0, "service-picker")
  If csv = "" : ProcedureReturn : EndIf
  LogLine("Stop now (picker): " + csv)
  RunPowerShellAndCapture("$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } ; foreach($n in $names){ try{ Stop-Service -Name $n -Force -ErrorAction SilentlyContinue } catch{} }")
EndProcedure

Procedure StartServicesNow(csv.s)
  csv = SanitizeServiceCsv(csv, 1, "service-picker")
  If csv = "" : ProcedureReturn : EndIf
  LogLine("Start now (picker): " + csv)
  RunPowerShellAndCapture("$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } ; foreach($n in $names){ try{ Start-Service -Name $n -ErrorAction SilentlyContinue } catch{} }")
EndProcedure

Procedure RefreshServicesData(listGadget.i, showAllGadget.i, Map selected.i(), List all.ServiceInfo(), List recommended.s(), Map byName.ServiceInfo())
  GetAllServices(all())
  ClearMap(byName())
  ForEach all()
    byName(LCase(all()\Name)) = all()
  Next
  FillServiceList(listGadget, GetGadgetState(showAllGadget), selected(), all(), recommended(), byName())
EndProcedure

Procedure.s ServicesPickDialog(initialCsv.s, *autoRun.Integer)
  Enumeration _SvcWindows 1000
    #W_Svc
  EndEnumeration
  Enumeration _SvcGadgets 2000
    #S_List
    #S_BtnOk
    #S_BtnCancel
    #S_ShowAll
    #S_AutoRun
  EndEnumeration

  Protected NewList recommended.s()
  AddElement(recommended()) : recommended() = "Spooler"
  AddElement(recommended()) : recommended() = "WSearch"
  AddElement(recommended()) : recommended() = "SysMain"
  AddElement(recommended()) : recommended() = "WerSvc"
  AddElement(recommended()) : recommended() = "DiagTrack"
  AddElement(recommended()) : recommended() = "TrkWks"
  AddElement(recommended()) : recommended() = "MapsBroker"
  AddElement(recommended()) : recommended() = "Fax"
  AddElement(recommended()) : recommended() = "WMPNetworkSvc"
  AddElement(recommended()) : recommended() = "XblAuthManager"
  AddElement(recommended()) : recommended() = "XblGameSave"
  AddElement(recommended()) : recommended() = "XboxGipSvc"

  Protected NewList all.ServiceInfo()
  GetAllServices(all())
  Protected NewMap byName.ServiceInfo()
  ForEach all()
    byName(LCase(all()\Name)) = all()
  Next

  Protected NewMap selected.i()
  Protected NewMap selectedName.s()
  Protected i.i, n.i, item.s
  n = CountString(initialCsv, ",") + 1
  For i = 1 To n
    item = LCase(Trim(StringField(initialCsv, i, ",")))
    If item <> ""
      selected(item) = 1
      selectedName(item) = Trim(StringField(initialCsv, i, ","))
    EndIf
  Next

  Enumeration 3000
    #M_Svc
  EndEnumeration
  Enumeration 3100
    #MI_Toggle
    #MI_SelectAll
    #MI_ClearAll
    #MI_StopNow
    #MI_StartNow
    #MI_OpenServices
  EndEnumeration

  If OpenWindow(#W_Svc, 0, 0, 860, 520, "Pick Services (temporary)", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#PB_Any, 10, 10, 840, 35, "Select services to stop while the game runs. Protected core services are blocked; risky ones still require confirmation.")
    CheckBoxGadget(#S_ShowAll, 10, 45, 240, 22, "Show all services")
    ListIconGadget(#S_List, 10, 75, 840, 380, "Sel", 40, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_MultiSelect)
    AddGadgetColumn(#S_List, 1, "Service", 170)
    AddGadgetColumn(#S_List, 2, "Display name", 360)
    AddGadgetColumn(#S_List, 3, "Status", 90)
    AddGadgetColumn(#S_List, 4, "Start", 120)

    CheckBoxGadget(#S_AutoRun, 10, 472, 280, 22, "Auto-run game after OK")
    If *autoRun
      SetGadgetState(#S_AutoRun, Bool(*autoRun\i))
    EndIf

    ButtonGadget(#S_BtnOk, 650, 470, 90, 30, "OK")
    ButtonGadget(#S_BtnCancel, 760, 470, 90, 30, "Cancel")

    If CreatePopupMenu(#M_Svc)
      MenuItem(#MI_Toggle, "Toggle select")
      MenuBar()
      MenuItem(#MI_SelectAll, "Select all (shown)")
      MenuItem(#MI_ClearAll, "Clear all")
      MenuBar()
      MenuItem(#MI_StopNow, "Stop service now")
      MenuItem(#MI_StartNow, "Start service now")
      MenuBar()
      MenuItem(#MI_OpenServices, "Open Services (services.msc)")
    EndIf

    FillServiceList(#S_List, 0, selected(), all(), recommended(), byName())

    Protected ev.i, outCsv.s
    Repeat
      ev = WaitWindowEvent()
      Select ev
        Case #PB_Event_Gadget
          Select EventGadget()
            Case #S_ShowAll
              FillServiceList(#S_List, GetGadgetState(#S_ShowAll), selected(), all(), recommended(), byName())
            Case #S_List
              If EventType() = #PB_EventType_LeftDoubleClick
                ToggleSelectedRows(#S_List, selected(), selectedName())
              ElseIf EventType() = #PB_EventType_RightClick
                If GetGadgetState(#S_List) >= 0
                  DisplayPopupMenu(#M_Svc, WindowID(#W_Svc))
                EndIf
              EndIf
            Case #S_BtnOk
              outCsv = BuildSelectedServiceCsv(selected(), selectedName())
              If ConfirmRiskyServicesIfNeeded(outCsv) = 0
                Continue
              EndIf
              If *autoRun
                *autoRun\i = GetGadgetState(#S_AutoRun)
              EndIf
              CloseWindow(#W_Svc)
              ProcedureReturn outCsv
            Case #S_BtnCancel
              If *autoRun
                *autoRun\i = 0
              EndIf
              CloseWindow(#W_Svc)
              ProcedureReturn initialCsv
          EndSelect
        Case #PB_Event_CloseWindow
          If *autoRun
            *autoRun\i = 0
          EndIf
          CloseWindow(#W_Svc)
          ProcedureReturn initialCsv
        Case #PB_Event_Menu
          Select EventMenu()
            Case #MI_Toggle
              ToggleSelectedRows(#S_List, selected(), selectedName())
            Case #MI_SelectAll
              SelectAllShown(#S_List, selected(), selectedName())
            Case #MI_ClearAll
              ClearAllSelected(#S_List, selected(), selectedName())
            Case #MI_StopNow
              StopServicesNow(SelectedNamesCsv(#S_List))
              RefreshServicesData(#S_List, #S_ShowAll, selected(), all(), recommended(), byName())
            Case #MI_StartNow
              StartServicesNow(SelectedNamesCsv(#S_List))
              RefreshServicesData(#S_List, #S_ShowAll, selected(), all(), recommended(), byName())
            Case #MI_OpenServices
              RunProgram("services.msc", "", "", #PB_Program_Open)
          EndSelect
      EndSelect
    ForEver
  EndIf

  ProcedureReturn initialCsv
EndProcedure

Procedure.i PriorityToChoice(p.l)
  Select p
    Case 0 : ProcedureReturn 0
    Case #NORMAL_PRIORITY_CLASS : ProcedureReturn 1
    Case #ABOVE_NORMAL_PRIORITY_CLASS : ProcedureReturn 2
    Case #HIGH_PRIORITY_CLASS : ProcedureReturn 3
  EndSelect
  ProcedureReturn 2
EndProcedure

Procedure.l ChoiceToPriority(choice.i)
  Select choice
    Case 0 : ProcedureReturn 0
    Case 1 : ProcedureReturn #NORMAL_PRIORITY_CLASS
    Case 3 : ProcedureReturn #HIGH_PRIORITY_CLASS
  EndSelect
  ProcedureReturn #ABOVE_NORMAL_PRIORITY_CLASS
EndProcedure

Procedure.i OpenEditGameDialog(*cur.GameEntry, *autoRun.Integer)
  Enumeration _EditWindows 5000
    #W_EditGame
  EndEnumeration
  Enumeration _EditGadgets 5100
    #E_Preview
    #E_Name
    #E_Mode
    #E_Path
    #E_GameArgs
    #E_Timeout
    #E_Priority
    #E_Preset
    #E_PowerMode
    #E_Background
    #E_Tags
    #E_Notes
    #E_Services
    #E_AutoRun
    #E_Save
    #E_Cancel
  EndEnumeration

  Protected w.i, ev.i
  Protected saved.i
  Protected modeLabel.s
  Protected previewImg.i
  Protected previewPanelImg.i

  w = OpenWindow(#W_EditGame, 0, 0, 780, 520, "Edit Game", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w = 0
    ProcedureReturn 0
  EndIf

  If IsWindow(0)
    DisableWindow(0, 1)
  EndIf

  previewImg = ThumbnailImageForGameSized(*cur, 96)
  TextGadget(#PB_Any, 650, 16, 96, 20, "Preview")
  previewPanelImg = CreateImage(#PB_Any, 112, 112, 32, RGBA(245, 245, 245, 255))
  If IsImage(previewPanelImg) And StartDrawing(ImageOutput(previewPanelImg))
    Box(0, 0, 112, 112, RGBA(245, 245, 245, 255))
    If IsImage(previewImg)
      DrawAlphaImage(ImageID(previewImg), 8, 8)
    EndIf
    StopDrawing()
  EndIf
  ImageGadget(#E_Preview, 638, 44, 112, 112, ImageID(previewPanelImg), #PB_Image_Border)

  TextGadget(#PB_Any, 16, 16, 110, 20, "Game name")
  StringGadget(#E_Name, 140, 12, 480, 24, *cur\Name)
  TextGadget(#PB_Any, 16, 48, 110, 20, "Launch type")
  modeLabel = "EXE"
  If *cur\LaunchMode = 1 : modeLabel = "Steam" : EndIf
  StringGadget(#E_Mode, 140, 44, 160, 24, modeLabel, #PB_String_ReadOnly)
  TextGadget(#PB_Any, 16, 80, 110, 20, "Path / App")
  If *cur\LaunchMode = 1
    StringGadget(#E_Path, 140, 76, 480, 24, "AppID " + Str(*cur\SteamAppId) + " | " + *cur\SteamExe, #PB_String_ReadOnly)
  Else
    StringGadget(#E_Path, 140, 76, 480, 24, *cur\ExePath, #PB_String_ReadOnly)
  EndIf
  TextGadget(#PB_Any, 16, 112, 110, 20, "Game args")
  If *cur\LaunchMode = 1
    StringGadget(#E_GameArgs, 140, 108, 480, 24, *cur\SteamGameArgs)
  Else
    StringGadget(#E_GameArgs, 140, 108, 480, 24, *cur\Args)
  EndIf
  TextGadget(#PB_Any, 16, 144, 110, 20, "Detect timeout")
  StringGadget(#E_Timeout, 140, 140, 120, 24, Str(*cur\SteamDetectTimeoutMs))
  DisableGadget(#E_Timeout, Bool(*cur\LaunchMode = 0))

  TextGadget(#PB_Any, 16, 176, 110, 20, "Priority")
  ComboBoxGadget(#E_Priority, 140, 172, 180, 26)
  AddGadgetItem(#E_Priority, -1, "Don't change")
  AddGadgetItem(#E_Priority, -1, "Normal")
  AddGadgetItem(#E_Priority, -1, "Above normal")
  AddGadgetItem(#E_Priority, -1, "High")
  SetGadgetState(#E_Priority, PriorityToChoice(*cur\Priority))

  TextGadget(#PB_Any, 336, 144, 110, 20, "Preset")
  ComboBoxGadget(#E_Preset, 440, 140, 180, 26)
  AddGadgetItem(#E_Preset, -1, "Safe")
  AddGadgetItem(#E_Preset, -1, "Balanced")
  AddGadgetItem(#E_Preset, -1, "Aggressive")
  SetGadgetState(#E_Preset, *cur\Preset)

  TextGadget(#PB_Any, 336, 176, 110, 20, "Power mode")
  ComboBoxGadget(#E_PowerMode, 440, 172, 180, 26)
  AddGadgetItem(#E_PowerMode, -1, "Keep current")
  AddGadgetItem(#E_PowerMode, -1, "High performance")
  AddGadgetItem(#E_PowerMode, -1, "Ultimate Performance")
  SetGadgetState(#E_PowerMode, *cur\PowerMode)

  CheckBoxGadget(#E_Background, 140, 208, 340, 24, "Deprioritize safe background processes")
  SetGadgetState(#E_Background, Bool(*cur\OptimizeBackground))

  TextGadget(#PB_Any, 16, 242, 110, 20, "Tags")
  StringGadget(#E_Tags, 140, 238, 480, 24, *cur\Tags)
  TextGadget(#PB_Any, 16, 274, 110, 20, "Notes")
  EditorGadget(#E_Notes, 140, 270, 480, 84)
  SetGadgetText(#E_Notes, *cur\Notes)

  ButtonGadget(#E_Services, 140, 366, 180, 30, "Pick Services...")
  CheckBoxGadget(#E_AutoRun, 140, 406, 220, 22, "Auto-run game after save")
  If *autoRun
    SetGadgetState(#E_AutoRun, Bool(*autoRun\i))
  EndIf

  ButtonGadget(#E_Save, 430, 440, 90, 32, "Save")
  ButtonGadget(#E_Cancel, 530, 440, 90, 32, "Cancel")

  If FontUI
    SetWindowTitle(#W_EditGame, "Edit Game")
    SetGadgetFont(#E_Name, FontID(FontUI))
    SetGadgetFont(#E_Mode, FontID(FontUI))
    SetGadgetFont(#E_Path, FontID(FontUI))
    SetGadgetFont(#E_GameArgs, FontID(FontUI))
    SetGadgetFont(#E_Timeout, FontID(FontUI))
    SetGadgetFont(#E_Priority, FontID(FontUI))
    SetGadgetFont(#E_Preset, FontID(FontUI))
    SetGadgetFont(#E_PowerMode, FontID(FontUI))
    SetGadgetFont(#E_Background, FontID(FontUI))
    SetGadgetFont(#E_Tags, FontID(FontUI))
    SetGadgetFont(#E_Notes, FontID(FontUI))
    SetGadgetFont(#E_Services, FontID(FontUI))
    SetGadgetFont(#E_AutoRun, FontID(FontUI))
    SetGadgetFont(#E_Save, FontID(FontUI))
    SetGadgetFont(#E_Cancel, FontID(FontUI))
  EndIf

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #E_Services
            *cur\Services = ServicesPickDialog(*cur\Services, *autoRun)
            If *autoRun
              SetGadgetState(#E_AutoRun, Bool(*autoRun\i))
            EndIf
          Case #E_Preset
            ApplyPresetDefaults(*cur, GetGadgetState(#E_Preset))
            SetGadgetState(#E_Priority, PriorityToChoice(*cur\Priority))
            SetGadgetState(#E_PowerMode, *cur\PowerMode)
            SetGadgetState(#E_Background, Bool(*cur\OptimizeBackground))
          Case #E_Save
            *cur\Name = Trim(GetGadgetText(#E_Name))
            If *cur\Name = ""
              MessageRequester(#APP_NAME, "Game name is required.")
              Continue
            EndIf
            If *cur\LaunchMode = 1
              *cur\SteamGameArgs = GetGadgetText(#E_GameArgs)
              *cur\SteamDetectTimeoutMs = ClampSteamDetectTimeout(Val(GetGadgetText(#E_Timeout)))
            Else
              *cur\Args = GetGadgetText(#E_GameArgs)
            EndIf
            *cur\Preset = GetGadgetState(#E_Preset)
            *cur\Priority = ChoiceToPriority(GetGadgetState(#E_Priority))
            *cur\PowerMode = GetGadgetState(#E_PowerMode)
            *cur\OptimizeBackground = Bool(GetGadgetState(#E_Background))
            *cur\Tags = Trim(GetGadgetText(#E_Tags))
            *cur\Notes = GetGadgetText(#E_Notes)
            If *autoRun
              *autoRun\i = GetGadgetState(#E_AutoRun)
            EndIf
            saved = 1
            Break
          Case #E_Cancel
            Break
        EndSelect

      Case #PB_Event_CloseWindow
        Break
    EndSelect
  ForEver

  CloseWindow(#W_EditGame)
  If IsWindow(0)
    DisableWindow(0, 0)
  EndIf
  ProcedureReturn saved
EndProcedure

Procedure.i EditGameByIndex(idx.i, listGadget.i)
  Protected cur.GameEntry
  If SelectGameByIndex(idx, @cur) = 0 : ProcedureReturn 0 : EndIf
  Protected autoRun.i
  If OpenEditGameDialog(@cur, @autoRun) = 0
    ProcedureReturn 0
  EndIf

  Protected i.i = 0
  ForEach Games()
    If i = idx
      Games() = cur
      SaveGames()
      RefreshList()
      idx = VisibleIndexFromGameIndex(i)
      If idx >= 0 And idx < CountGadgetItems(listGadget)
        SetGadgetState(listGadget, idx)
        SetGadgetItemState(listGadget, idx, #PB_ListIcon_Selected)
        SetActiveGadget(listGadget)
      EndIf
      LogLine("Edited game: " + cur\Name)
      If autoRun
        LogLine("Auto-run after edit: " + cur\Name)
        If cur\LaunchMode = 1
          LaunchSteamBoosted(@cur)
        Else
          LaunchBoosted(@cur)
        EndIf
      EndIf
      ProcedureReturn 1
    EndIf
    i + 1
  Next
  ProcedureReturn 0
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 1024
; FirstLine = 993
; Folding = -------
; EnableXP
; DPIAware
