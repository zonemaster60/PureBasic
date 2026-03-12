; Game import, persistence, and process discovery.

Procedure.i HasManualExe(exePath.s)
  If exePath = "" : ProcedureReturn 0 : EndIf
  ForEach Games()
    If Games()\LaunchMode = 0 And Games()\ExePath <> ""
      If LCase(Games()\ExePath) = LCase(exePath)
        ProcedureReturn 1
      EndIf
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

Procedure AddExeEntry(exePath.s)
  Protected ge.GameEntry
  If exePath = "" : ProcedureReturn : EndIf
  If FileSize(exePath) <= 0 : ProcedureReturn : EndIf

  If HasManualExe(exePath)
    ProcedureReturn
  EndIf

  ge\Name = GetFilePart(exePath, #PB_FileSystem_NoExtension)
  ge\Name = ReplaceString(ge\Name, "_", " ")
  ge\ExePath = exePath
  ge\Args = ""
  ge\WorkDir = GetPathPart(exePath)
  ge\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
  ge\Affinity = 0
  ge\Services = ""
  ge\LaunchMode = 0
  ge\SteamAppId = 0
  ge\SteamExe = ""
  ge\SteamClientArgs = ""
  ge\SteamGameArgs = ""
  ge\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
  ge\GameRoot = ""
  ge\PowerGuid = ""

  AddElement(Games())
  Games() = ge
EndProcedure

Procedure.s NormalizeName(s.s)
  s = LCase(s)
  s = ReplaceString(s, " ", "")
  s = ReplaceString(s, "_", "")
  s = ReplaceString(s, "-", "")
  ProcedureReturn s
EndProcedure

Procedure.s TopFolderKey(baseFolder.s, fullExePath.s)
  Protected base.s = EnsureTrailingSlash(baseFolder)
  Protected rel.s, p.i
  If LCase(Left(fullExePath, Len(base))) <> LCase(base)
    ProcedureReturn "__" + LCase(GetFilePart(fullExePath))
  EndIf
  rel = Mid(fullExePath, Len(base) + 1)
  p = FindString(rel, "\\", 1)
  If p > 0
    ProcedureReturn Left(rel, p - 1)
  EndIf
  ProcedureReturn "__root__" + LCase(fullExePath)
EndProcedure

Procedure.q ScoreExeCandidate(baseFolder.s, fullExePath.s)
  Protected size.q = FileSize(fullExePath)
  Protected score.q = size
  Protected file.s = LCase(GetFilePart(fullExePath))
  Protected baseName.s = GetFilePart(fullExePath, #PB_FileSystem_NoExtension)
  Protected key.s = TopFolderKey(baseFolder, fullExePath)

  If FindString(file, "launcher", 1) : score / 10 : EndIf
  If FindString(file, "crash", 1)    : score / 20 : EndIf
  If FindString(file, "report", 1)   : score / 20 : EndIf
  If FindString(file, "updater", 1)  : score / 20 : EndIf
  If FindString(file, "helper", 1)   : score / 10 : EndIf
  If FindString(file, "server", 1)   : score / 15 : EndIf
  If FindString(file, "editor", 1)   : score / 15 : EndIf
  If FindString(file, "dedicated", 1): score / 15 : EndIf
  If FindString(file, "unitycrashhandler", 1) : score / 50 : EndIf
  If FindString(file, "jabswitch", 1) : score / 100 : EndIf

  If Left(key, 8) <> "__root__"
    If NormalizeName(baseName) = NormalizeName(key)
      score * 50
    EndIf
  EndIf

  Protected exeDir.s = GetPathPart(fullExePath)
  If LCase(exeDir) = LCase(EnsureTrailingSlash(baseFolder + key)) Or LCase(exeDir) = LCase(EnsureTrailingSlash(baseFolder))
    score * 2
  EndIf

  Protected base.s = EnsureTrailingSlash(baseFolder)
  Protected relDir.s = ""
  If LCase(Left(GetPathPart(fullExePath), Len(base))) = LCase(base)
    relDir = Mid(GetPathPart(fullExePath), Len(base) + 1)
  EndIf
  Protected depth.i = CountString(relDir, "\\")
  score / (depth + 1)
  ProcedureReturn score
EndProcedure

Procedure.i ShouldSkipExe(fileName.s)
  Protected f.s = LCase(fileName)
  If Left(f, 5) = "unins" : ProcedureReturn 1 : EndIf
  If Left(f, 5) = "setup" : ProcedureReturn 1 : EndIf
  If f = "dxsetup.exe" : ProcedureReturn 1 : EndIf
  If f = "uninstall.exe" : ProcedureReturn 1 : EndIf
  If f = "steam.exe" : ProcedureReturn 1 : EndIf
  If f = "steamcmd.exe" : ProcedureReturn 1 : EndIf
  If f = "steamservice.exe" : ProcedureReturn 1 : EndIf
  If f = "steamwebhelper.exe" : ProcedureReturn 1 : EndIf
  If f = "gameoverlayui.exe" : ProcedureReturn 1 : EndIf
  If f = "steamerrorreporter.exe" : ProcedureReturn 1 : EndIf
  If FindString(f, "vcredist", 1) : ProcedureReturn 1 : EndIf
  If FindString(f, "vc_redist", 1) : ProcedureReturn 1 : EndIf
  If FindString(f, "dotnet", 1) : ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i ShouldSkipExePath(fullPath.s, fileName.s)
  Protected p.s = LCase(fullPath)
  If ShouldSkipExe(fileName) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\_commonredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\commonredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\redist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\directx\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\dotnet\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\vcredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\vc_redist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\installers\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\installer\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\easyanticheat\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\battleye\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\punkbuster\\", 1) : ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i ShouldSkipDir(dirName.s)
  Protected d.s = LCase(dirName)
  If d = "steamapps" : ProcedureReturn 1 : EndIf
  If d = "userdata"  : ProcedureReturn 1 : EndIf
  If d = "appcache"  : ProcedureReturn 1 : EndIf
  If d = "config"    : ProcedureReturn 1 : EndIf
  If d = "dumps"     : ProcedureReturn 1 : EndIf
  If d = "logs"      : ProcedureReturn 1 : EndIf
  If d = "package"   : ProcedureReturn 1 : EndIf
  If d = "depotcache": ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i DirHasAnyFile(dir.s, pattern.s)
  If ExamineDirectory(#DIRID_ANYFILE_CHECK, dir, pattern)
    While NextDirectoryEntry(#DIRID_ANYFILE_CHECK)
      If DirectoryEntryType(#DIRID_ANYFILE_CHECK) = #PB_DirectoryEntry_File
        FinishDirectory(#DIRID_ANYFILE_CHECK)
        ProcedureReturn 1
      EndIf
    Wend
    FinishDirectory(#DIRID_ANYFILE_CHECK)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i LooksLikeSteamFolder(folder.s)
  Protected steamapps.s
  folder = EnsureTrailingSlash(folder)
  If FileSize(folder + "steam.exe") > 0
    ProcedureReturn 1
  EndIf
  steamapps = folder + "steamapps\\"
  If FileSize(steamapps) = -2
    If FileSize(steamapps + "libraryfolders.vdf") > 0 : ProcedureReturn 1 : EndIf
    If DirHasAnyFile(steamapps, "appmanifest_*.acf") : ProcedureReturn 1 : EndIf
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure ScanExeRecursive(dir.s, depth.i, List out.s(), dirId.i)
  Protected full.s, name.s
  If depth < 0 : ProcedureReturn : EndIf
  dir = EnsureTrailingSlash(dir)
  If ExamineDirectory(dirId, dir, "*")
    While NextDirectoryEntry(dirId)
      name = DirectoryEntryName(dirId)
      If name = "." Or name = ".." : Continue : EndIf
      full = dir + name
      If DirectoryEntryType(dirId) = #PB_DirectoryEntry_Directory
        If ShouldSkipDir(name) = 0 And LooksLikeSteamFolder(full) = 0
          ScanExeRecursive(full, depth - 1, out(), dirId + 1)
        EndIf
      ElseIf DirectoryEntryType(dirId) = #PB_DirectoryEntry_File
        If LCase(GetExtensionPart(name)) = "exe"
          If ShouldSkipExePath(full, name) = 0
            AddElement(out())
            out() = full
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(dirId)
  EndIf
EndProcedure

Procedure ImportFolderGames()
  Protected folder.s = PathRequester("Select folder to scan", "")
  If folder = "" : ProcedureReturn : EndIf
  LogLine("Folder import requested: " + CollapseBackslashes(folder))

  Protected looksSteam.i = LooksLikeSteamFolder(folder)
  Protected NewList exes.s()
  ScanExeRecursive(folder, #FOLDER_SCAN_DEPTH, exes(), #DIRID_FOLDER_SCAN_ROOT)

  Structure BestPick
    score.q
    path.s
  EndStructure

  Protected NewMap best.BestPick()
  Protected key.s, s.q
  ForEach exes()
    key = TopFolderKey(folder, exes())
    s = ScoreExeCandidate(folder, exes())
    If FindMapElement(best(), key) = 0
      best(key)\score = s
      best(key)\path = exes()
    ElseIf s > best()\score
      best()\score = s
      best()\path = exes()
    EndIf
  Next

  Protected added.i, before.i
  ForEach best()
    before = ListSize(Games())
    AddExeEntry(best()\path)
    If ListSize(Games()) > before
      added + 1
    EndIf
  Next

  If added
    SaveGames()
    RefreshList()
  EndIf
  LogLine("Folder import added=" + Str(added))
  If looksSteam
    MessageRequester(#APP_NAME, "Added " + Str(added) + " game(s) from folder." + #LF$ + #LF$ +
                     "Note: Steam install/library detected. Steam folders are skipped here; use 'Import Steam' for Steam titles.")
  Else
    MessageRequester(#APP_NAME, "Added " + Str(added) + " game(s) from folder.")
  EndIf
EndProcedure

Procedure SnapshotPids(Map pids.i())
  ClearMap(pids())
  Protected snap.i = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  Protected pe.OC_PROCESSENTRY32
  If snap = -1 : ProcedureReturn : EndIf
  pe\dwSize = SizeOf(OC_PROCESSENTRY32)
  If Process32First_(snap, @pe)
    Repeat
      pids(Str(pe\th32ProcessID)) = 1
    Until Process32Next_(snap, @pe) = 0
  EndIf
  CloseHandle_(snap)
EndProcedure

Procedure.s GetMainModulePath(pid.i)
  Protected snap.i = CreateToolhelp32Snapshot_(#TH32CS_SNAPMODULE | #TH32CS_SNAPMODULE32, pid)
  Protected me.OC_MODULEENTRY32
  Protected path.s = ""
  If snap = -1 : ProcedureReturn "" : EndIf
  me\dwSize = SizeOf(OC_MODULEENTRY32)
  If Module32First_(snap, @me)
    path = PeekS(@me\szExePath[0], -1)
  EndIf
  CloseHandle_(snap)
  ProcedureReturn path
EndProcedure

Procedure.i StartsWithNoCase(s.s, prefix.s)
  If prefix = "" : ProcedureReturn 0 : EndIf
  If Len(s) < Len(prefix) : ProcedureReturn 0 : EndIf
  If LCase(Left(s, Len(prefix))) = LCase(prefix)
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i FindNewProcessInFolder(gameRoot.s, Map baseline.i(), timeoutMs.i)
  Protected start.i = ElapsedMilliseconds()
  Protected NewMap cur.i()
  Protected key.s, pid.i, exe.s
  gameRoot = EnsureTrailingSlash(gameRoot)

  While ElapsedMilliseconds() - start < timeoutMs
    SnapshotPids(cur())
    ForEach cur()
      key = MapKey(cur())
      If FindMapElement(baseline(), key) = 0
        pid = Val(key)
        exe = GetMainModulePath(pid)
        If exe <> "" And StartsWithNoCase(exe, gameRoot)
          ProcedureReturn pid
        EndIf
      EndIf
    Next
    Delay(200)
  Wend

  ProcedureReturn 0
EndProcedure

Procedure LoadGames()
  ClearList(Games())

  If OpenPreferences(GamesIni)
    Protected count.i, i.i, g.GameEntry
    PreferenceGroup("meta")
    count = ReadPreferenceInteger("count", 0)

    For i = 0 To count - 1
      PreferenceGroup("game_" + Str(i))
      g\Name     = ReadPreferenceString("name", "")
      g\ExePath  = ReadPreferenceString("exe", "")
      g\Args     = ReadPreferenceString("args", "")
      g\WorkDir  = ReadPreferenceString("workdir", "")
      g\Priority = ReadPreferenceInteger("priority", 0)
      g\Affinity = ReadPreferenceQuad("affinity", 0)
      g\Services = ReadPreferenceString("services", "")
      g\LaunchMode = ReadPreferenceInteger("launchMode", 0)
      g\SteamAppId  = ReadPreferenceInteger("steamAppId", 0)
      g\SteamExe    = ReadPreferenceString("steamExe", "")
      g\SteamClientArgs = ReadPreferenceString("steamClientArgs", "")
      g\SteamGameArgs   = ReadPreferenceString("steamGameArgs", "")
      g\SteamDetectTimeoutMs = ReadPreferenceInteger("steamTimeoutMs", 60000)
      g\GameRoot    = ReadPreferenceString("gameRoot", "")
      g\PowerGuid   = ReadPreferenceString("powerGuid", "")
      If g\LaunchMode <> 1
        g\LaunchMode = 0
        g\SteamAppId = 0
        g\SteamExe = ""
        g\SteamClientArgs = ""
        g\SteamGameArgs = ""
        g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
        g\GameRoot = ""
      EndIf
      If g\LaunchMode = 1
        g\GameRoot = ""
        g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(g\SteamDetectTimeoutMs)
      EndIf
      If g\Name <> "" And g\ExePath <> ""
        AddElement(Games())
        Games() = g
      ElseIf g\Name <> "" And g\LaunchMode = 1 And g\SteamAppId > 0
        AddElement(Games())
        Games() = g
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveGames()
  If OpenOrCreatePreferences(GamesIni)
    LogLine("Saving games.ini; count=" + Str(ListSize(Games())))
    Protected i.i = 0
    PreferenceGroup("meta")
    WritePreferenceInteger("count", ListSize(Games()))

    ForEach Games()
      PreferenceGroup("game_" + Str(i))
      WritePreferenceString("name", Games()\Name)
      Protected cleanedExe.s = CollapseBackslashes(Games()\ExePath)
      WritePreferenceString("exe", cleanedExe)
      WritePreferenceString("args", Games()\Args)
      WritePreferenceString("workdir", CollapseBackslashes(Games()\WorkDir))
      WritePreferenceInteger("priority", Games()\Priority)
      WritePreferenceQuad("affinity", Games()\Affinity)
      WritePreferenceString("services", Games()\Services)
      WritePreferenceInteger("launchMode", Games()\LaunchMode)
      WritePreferenceInteger("steamAppId", Games()\SteamAppId)
      WritePreferenceString("steamExe", CollapseBackslashes(Games()\SteamExe))
      WritePreferenceString("steamClientArgs", Games()\SteamClientArgs)
      WritePreferenceString("steamGameArgs", Games()\SteamGameArgs)
      WritePreferenceInteger("steamTimeoutMs", Games()\SteamDetectTimeoutMs)
      WritePreferenceString("gameRoot", CollapseBackslashes(Games()\GameRoot))
      WritePreferenceString("powerGuid", Games()\PowerGuid)
      i + 1
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure.i SelectGameByIndex(idx.i, *out.GameEntry)
  Protected i.i = 0
  ForEach Games()
    If i = idx
      *out\Name     = Games()\Name
      *out\ExePath  = Games()\ExePath
      *out\Args     = Games()\Args
      *out\WorkDir  = Games()\WorkDir
      *out\Priority = Games()\Priority
      *out\Affinity = Games()\Affinity
      *out\Services = Games()\Services
      *out\LaunchMode = Games()\LaunchMode
      *out\SteamAppId  = Games()\SteamAppId
      *out\SteamExe    = Games()\SteamExe
      *out\SteamClientArgs = Games()\SteamClientArgs
      *out\SteamGameArgs   = Games()\SteamGameArgs
      *out\SteamDetectTimeoutMs = Games()\SteamDetectTimeoutMs
      *out\GameRoot    = Games()\GameRoot
      *out\PowerGuid   = Games()\PowerGuid
      ProcedureReturn 1
    EndIf
    i + 1
  Next
  ProcedureReturn 0
EndProcedure

Procedure AddGameSimple()
  Protected g.GameEntry
  g\Name = InputRequester(#APP_NAME, "Game name:", "")
  If g\Name = "" : ProcedureReturn : EndIf

  g\ExePath = OpenFileRequester("Select game exe", "", "Executables (*.exe)|*.exe|All files (*.*)|*.*", 0)
  If g\ExePath = "" : ProcedureReturn : EndIf
  If HasManualExe(g\ExePath)
    MessageRequester(#APP_NAME, "This executable is already in the list.")
    ProcedureReturn
  EndIf

  g\Args = InputRequester(#APP_NAME, "Launch arguments (optional):", "")
  g\WorkDir = GetPathPart(g\ExePath)
  g\Services = InputRequester(#APP_NAME, "Services to stop while boosting (comma-separated, optional):", "")
  g\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
  g\Affinity = 0
  g\LaunchMode = 0
  g\SteamAppId = 0
  g\SteamExe = ""
  g\SteamClientArgs = ""
  g\SteamGameArgs = ""
  g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
  g\GameRoot = ""
  g\PowerGuid = ""

  AddElement(Games())
  Games() = g
  SaveGames()
  RefreshList()
EndProcedure

Procedure RemoveGameByIndex(idx.i)
  Protected i.i = 0
  ForEach Games()
    If i = idx
      DeleteElement(Games())
      Break
    EndIf
    i + 1
  Next
  SaveGames()
  RefreshList()
EndProcedure
