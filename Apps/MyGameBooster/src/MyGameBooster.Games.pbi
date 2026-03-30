; Game import, persistence, and process discovery.

Procedure.i HasManualExe(exePath.s)
  If exePath = "" : ProcedureReturn 0 : EndIf
  ForEach Games()
    If Games()\LaunchMode = #LAUNCHMODE_EXE And Games()\ExePath <> ""
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
  ge\LaunchMode = #LAUNCHMODE_EXE
  ge\SteamAppId = 0
  ge\SteamExe = ""
  ge\SteamGameArgs = ""
  ge\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
  ge\GameRoot = ""
  ApplyPresetDefaults(@ge, DefaultPreset)
  ge\Notes = ""
  ge\Tags = "manual"
  ge\LaunchCount = 0
  ge\LastPlayed = 0
  ge\LastDurationSec = 0

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
                     "Note: Steam install/library detected. Steam folders are skipped here; use 'Import Steam Game' for Steam titles.")
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

Procedure.i FindNewProcessInFolderOnce(gameRoot.s, Map baseline.i())
  Protected NewMap cur.i()
  Protected key.s, pid.i, exe.s
  gameRoot = EnsureTrailingSlash(gameRoot)

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

  ProcedureReturn 0
EndProcedure

Procedure.s GuessGameExeFromRoot(gameRoot.s)
  Protected NewList candidates.s()
  Protected bestPath.s
  Protected bestScore.q, score.q

  gameRoot = EnsureTrailingSlash(gameRoot)
  If gameRoot = "" Or FileSize(gameRoot) <> -2
    ProcedureReturn ""
  EndIf

  ScanExeRecursive(gameRoot, #FOLDER_SCAN_DEPTH, candidates(), #DIRID_FOLDER_SCAN_ROOT)
  ForEach candidates()
    score = ScoreExeCandidate(gameRoot, candidates())
    If bestPath = "" Or score > bestScore
      bestScore = score
      bestPath = candidates()
    EndIf
  Next

  ProcedureReturn bestPath
EndProcedure

Procedure.i FindSteamGameProcessOnce(preferredExe.s, gameRoot.s, Map baseline.i())
  Protected NewMap cur.i()
  Protected key.s, pid.i, exe.s
  Protected preferredLower.s = LCase(CollapseBackslashes(preferredExe))
  Protected gameRootLower.s = LCase(EnsureTrailingSlash(CollapseBackslashes(gameRoot)))
  Protected rootMatchPid.i
  Protected existingPreferredPid.i
  Protected existingRootPid.i

  SnapshotPids(cur())
  ForEach cur()
    key = MapKey(cur())
    pid = Val(key)
    exe = CollapseBackslashes(GetMainModulePath(pid))
    If exe = ""
      Continue
    EndIf

    If preferredLower <> "" And LCase(exe) = preferredLower
      If FindMapElement(baseline(), key) = 0
        ProcedureReturn pid
      EndIf
      If existingPreferredPid = 0
        existingPreferredPid = pid
      EndIf
    EndIf

    If gameRootLower <> "" And StartsWithNoCase(exe, gameRootLower)
      If FindMapElement(baseline(), key) = 0
        rootMatchPid = pid
        If preferredLower = "" Or FindString(LCase(GetFilePart(exe)), "launcher", 1) = 0
          ProcedureReturn pid
        EndIf
      ElseIf existingRootPid = 0
        existingRootPid = pid
      EndIf
    EndIf
  Next

  If rootMatchPid
    ProcedureReturn rootMatchPid
  EndIf
  If existingPreferredPid
    ProcedureReturn existingPreferredPid
  EndIf
  If existingRootPid
    ProcedureReturn existingRootPid
  EndIf

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
        g\SteamGameArgs   = ReadPreferenceString("steamGameArgs", "")
        g\SteamDetectTimeoutMs = ReadPreferenceInteger("steamTimeoutMs", 60000)
       g\GameRoot    = ReadPreferenceString("gameRoot", "")
       g\Preset      = ReadPreferenceInteger("preset", #PRESET_BALANCED)
       g\PowerMode   = ReadPreferenceInteger("powerMode", #POWERMODE_HIGH)
       g\OptimizeBackground = ReadPreferenceInteger("optimizeBackground", 1)
       g\Notes = ReadPreferenceString("notes", "")
       g\Tags = ReadPreferenceString("tags", "")
       g\LaunchCount = ReadPreferenceInteger("launchCount", 0)
       g\LastPlayed  = ReadPreferenceQuad("lastPlayed", 0)
       g\LastDurationSec = ReadPreferenceInteger("lastDurationSec", 0)
        If g\LaunchMode < #LAUNCHMODE_EXE Or g\LaunchMode > #LAUNCHMODE_STEAM
          g\LaunchMode = #LAUNCHMODE_EXE
        EndIf
        If g\LaunchMode = #LAUNCHMODE_EXE
          g\SteamAppId = 0
          g\SteamExe = ""
          g\SteamGameArgs = ""
          g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
          g\GameRoot = ""
        ElseIf g\LaunchMode = #LAUNCHMODE_STEAM
          g\GameRoot = ""
          g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(g\SteamDetectTimeoutMs)
        EndIf
       If g\Preset < #PRESET_SAFE Or g\Preset > #PRESET_AGGRESSIVE
         g\Preset = #PRESET_BALANCED
       EndIf
       If g\PowerMode < #POWERMODE_KEEP Or g\PowerMode > #POWERMODE_ULTIMATE
         g\PowerMode = #POWERMODE_HIGH
       EndIf
       g\OptimizeBackground = Bool(g\OptimizeBackground)
      If g\Name <> "" And g\ExePath <> ""
        AddElement(Games())
        Games() = g
      ElseIf g\Name <> "" And g\LaunchMode = #LAUNCHMODE_STEAM And g\SteamAppId > 0
        AddElement(Games())
        Games() = g
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveGames()
  If OpenOrCreatePreferences(GamesIni)
    LogLine("Saving MyGameBooster_games.ini; count=" + Str(ListSize(Games())))
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
       WritePreferenceString("steamGameArgs", Games()\SteamGameArgs)
        WritePreferenceInteger("steamTimeoutMs", Games()\SteamDetectTimeoutMs)
       WritePreferenceString("gameRoot", CollapseBackslashes(Games()\GameRoot))
       WritePreferenceInteger("preset", Games()\Preset)
       WritePreferenceInteger("powerMode", Games()\PowerMode)
       WritePreferenceInteger("optimizeBackground", Games()\OptimizeBackground)
       WritePreferenceString("notes", Games()\Notes)
       WritePreferenceString("tags", Games()\Tags)
       WritePreferenceInteger("launchCount", Games()\LaunchCount)
       WritePreferenceQuad("lastPlayed", Games()\LastPlayed)
       WritePreferenceInteger("lastDurationSec", Games()\LastDurationSec)
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
      *out\SteamGameArgs   = Games()\SteamGameArgs
      *out\SteamDetectTimeoutMs = Games()\SteamDetectTimeoutMs
      *out\GameRoot    = Games()\GameRoot
      *out\Preset      = Games()\Preset
      *out\PowerMode   = Games()\PowerMode
      *out\OptimizeBackground = Games()\OptimizeBackground
      *out\Notes       = Games()\Notes
      *out\Tags        = Games()\Tags
      *out\LaunchCount = Games()\LaunchCount
      *out\LastPlayed  = Games()\LastPlayed
      *out\LastDurationSec = Games()\LastDurationSec
      ProcedureReturn 1
    EndIf
    i + 1
  Next
  ProcedureReturn 0
EndProcedure

Procedure.i MoveGameByIndex(idx.i, direction.i)
  If direction <> -1 And direction <> 1
    ProcedureReturn 0
  EndIf
  ProcedureReturn MoveGameToIndex(idx, idx + direction)
EndProcedure

Procedure.i MoveGameToIndex(fromIdx.i, toIdx.i)
  Protected count.i = ListSize(Games())
  Protected moved.GameEntry
  Protected cur.GameEntry
  Protected i.i
  Protected inserted.i
  Protected NewList reordered.GameEntry()

  If fromIdx < 0 Or fromIdx >= count
    ProcedureReturn 0
  EndIf
  If toIdx < 0
    toIdx = 0
  EndIf
  If toIdx >= count
    toIdx = count - 1
  EndIf
  If fromIdx = toIdx
    ProcedureReturn 0
  EndIf
  If SelectGameByIndex(fromIdx, @moved) = 0
    ProcedureReturn 0
  EndIf

  For i = 0 To count - 1
    If i = fromIdx
      Continue
    EndIf

    If fromIdx > toIdx And i = toIdx
      AddElement(reordered())
      reordered() = moved
      inserted = 1
    EndIf

    If SelectGameByIndex(i, @cur)
      AddElement(reordered())
      reordered() = cur
    EndIf

    If fromIdx < toIdx And i = toIdx
      AddElement(reordered())
      reordered() = moved
      inserted = 1
    EndIf
  Next

  If inserted = 0
    AddElement(reordered())
    reordered() = moved
  EndIf

  ClearList(Games())
  ForEach reordered()
    AddElement(Games())
    Games() = reordered()
  Next

  SaveGames()
  RefreshList()
  ProcedureReturn 1
EndProcedure

Procedure.i ListIndexFromCursor(listGadget.i)
  Protected ht.OC_LVHITTESTINFO

  If IsGadget(listGadget) = 0
    ProcedureReturn -1
  EndIf

  GetCursorPos_(@ht\pt)
  ScreenToClient_(GadgetID(listGadget), @ht\pt)
  ProcedureReturn SendMessage_(GadgetID(listGadget), #LVM_HITTEST, 0, @ht)
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
  g\LaunchMode = #LAUNCHMODE_EXE
  g\SteamAppId = 0
  g\SteamExe = ""
  g\Tags = "manual"
  g\SteamGameArgs = ""
  g\SteamDetectTimeoutMs = ClampSteamDetectTimeout(60000)
  g\GameRoot = ""
  ApplyPresetDefaults(@g, DefaultPreset)
  g\Notes = ""
  g\LaunchCount = 0
  g\LastPlayed = 0
  g\LastDurationSec = 0

  AddElement(Games())
  Games() = g
  SaveGames()
  RefreshList()
EndProcedure

Procedure ApplyPresetDefaults(*g.GameEntry, preset.i)
  *g\Preset = preset
  Select preset
    Case #PRESET_SAFE
      *g\Priority = #NORMAL_PRIORITY_CLASS
      *g\PowerMode = #POWERMODE_KEEP
      *g\OptimizeBackground = 0
    Case #PRESET_AGGRESSIVE
      *g\Priority = #HIGH_PRIORITY_CLASS
      *g\PowerMode = #POWERMODE_ULTIMATE
      *g\OptimizeBackground = 1
    Default
      *g\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
      *g\PowerMode = #POWERMODE_HIGH
      *g\OptimizeBackground = 1
  EndSelect
EndProcedure

Procedure.i MatchesFilter(*g.GameEntry, query.s)
  Protected haystack.s
  query = LCase(Trim(query))
  If query = ""
    ProcedureReturn 1
  EndIf
  haystack = LCase(*g\Name + " " + *g\ExePath + " " + *g\Tags + " " + *g\Notes)
  If *g\LaunchMode = #LAUNCHMODE_STEAM
    haystack + " steam appid " + Str(*g\SteamAppId)
  EndIf
  ProcedureReturn Bool(FindString(haystack, query, 1) > 0)
EndProcedure

Procedure CompareGames(*a.GameEntry, *b.GameEntry, sortMode.i)
  Select sortMode
    Case #SORT_LAST_PLAYED
      If *a\LastPlayed < *b\LastPlayed : ProcedureReturn 1 : EndIf
      If *a\LastPlayed > *b\LastPlayed : ProcedureReturn -1 : EndIf
    Case #SORT_RUNS_DESC
      If *a\LaunchCount < *b\LaunchCount : ProcedureReturn 1 : EndIf
      If *a\LaunchCount > *b\LaunchCount : ProcedureReturn -1 : EndIf
  EndSelect
  If LCase(*a\Name) > LCase(*b\Name) : ProcedureReturn 1 : EndIf
  If LCase(*a\Name) < LCase(*b\Name) : ProcedureReturn -1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i MatchesLibraryView(*g.GameEntry, view.i)
  Select view
    Case #LIBRARY_STEAM
      ProcedureReturn Bool(*g\LaunchMode = #LAUNCHMODE_STEAM)
    Case #LIBRARY_EXE
      ProcedureReturn Bool(*g\LaunchMode = #LAUNCHMODE_EXE)
    Case #LIBRARY_RECENT
      ProcedureReturn Bool(*g\LastPlayed > 0)
    Case #LIBRARY_MOSTPLAYED
      ProcedureReturn Bool(*g\LaunchCount > 0)
    Case #LIBRARY_TAGGED
      ProcedureReturn Bool(Trim(*g\Tags) <> "")
  EndSelect
  ProcedureReturn 1
EndProcedure

Procedure.s GameIdentity(*g.GameEntry)
  If *g\LaunchMode = #LAUNCHMODE_STEAM
    ProcedureReturn "steam:" + Str(*g\SteamAppId)
  EndIf
  ProcedureReturn "exe:" + LCase(CollapseBackslashes(*g\ExePath))
EndProcedure

Procedure.i MergeOrAddGame(*g.GameEntry)
  Protected identity.s = GameIdentity(*g)

  ForEach Games()
    If GameIdentity(@Games()) = identity
      Games()\LaunchMode = *g\LaunchMode
      Games()\SteamAppId = *g\SteamAppId
      If *g\ExePath <> "" : Games()\ExePath = *g\ExePath : EndIf
      If *g\Name <> "" : Games()\Name = *g\Name : EndIf
      If *g\Args <> "" : Games()\Args = *g\Args : EndIf
      If *g\WorkDir <> "" : Games()\WorkDir = *g\WorkDir : EndIf
      If *g\SteamExe <> "" : Games()\SteamExe = *g\SteamExe : EndIf
      If *g\SteamGameArgs <> "" : Games()\SteamGameArgs = *g\SteamGameArgs : EndIf
      If *g\GameRoot <> "" : Games()\GameRoot = *g\GameRoot : EndIf
      Games()\Priority = *g\Priority
      Games()\Affinity = *g\Affinity
      Games()\Services = *g\Services
      Games()\Preset = *g\Preset
      Games()\PowerMode = *g\PowerMode
      Games()\OptimizeBackground = *g\OptimizeBackground
      Games()\Notes = *g\Notes
      Games()\Tags = *g\Tags
      If *g\LaunchCount > Games()\LaunchCount : Games()\LaunchCount = *g\LaunchCount : EndIf
      If *g\LastPlayed > Games()\LastPlayed : Games()\LastPlayed = *g\LastPlayed : EndIf
      If *g\LastDurationSec > 0 : Games()\LastDurationSec = *g\LastDurationSec : EndIf
      ProcedureReturn 2
    EndIf
  Next

  AddElement(Games())
  Games()\Name = *g\Name
  Games()\ExePath = *g\ExePath
  Games()\Args = *g\Args
  Games()\WorkDir = *g\WorkDir
  Games()\Priority = *g\Priority
  Games()\Affinity = *g\Affinity
  Games()\Services = *g\Services
  Games()\LaunchMode = *g\LaunchMode
  Games()\SteamAppId = *g\SteamAppId
  Games()\SteamExe = *g\SteamExe
  Games()\SteamGameArgs = *g\SteamGameArgs
  Games()\SteamDetectTimeoutMs = *g\SteamDetectTimeoutMs
  Games()\GameRoot = *g\GameRoot
  Games()\Preset = *g\Preset
  Games()\PowerMode = *g\PowerMode
  Games()\OptimizeBackground = *g\OptimizeBackground
  Games()\Notes = *g\Notes
  Games()\Tags = *g\Tags
  Games()\LaunchCount = *g\LaunchCount
  Games()\LastPlayed = *g\LastPlayed
  Games()\LastDurationSec = *g\LastDurationSec
  ProcedureReturn 1
EndProcedure

Procedure ExportGamesProfile()
  Protected filePath.s, f.i, i.i
  filePath = SaveFileRequester("Export profile", "MyGameBooster_Profile.ini", "INI files (*.ini)|*.ini|All files (*.*)|*.*", 0)
  If filePath = "" : ProcedureReturn : EndIf

  f = CreatePreferences(filePath)
  If f = 0
    MessageRequester(#APP_NAME, "Could not create export file.")
    ProcedureReturn
  EndIf

  PreferenceGroup("meta")
  WritePreferenceInteger("count", ListSize(Games()))
  i = 0
  ForEach Games()
    PreferenceGroup("game_" + Str(i))
    WritePreferenceString("name", Games()\Name)
    WritePreferenceString("exe", Games()\ExePath)
    WritePreferenceString("args", Games()\Args)
    WritePreferenceString("workdir", Games()\WorkDir)
    WritePreferenceInteger("priority", Games()\Priority)
    WritePreferenceQuad("affinity", Games()\Affinity)
    WritePreferenceString("services", Games()\Services)
    WritePreferenceInteger("launchMode", Games()\LaunchMode)
    WritePreferenceInteger("steamAppId", Games()\SteamAppId)
    WritePreferenceString("steamExe", Games()\SteamExe)
    WritePreferenceString("steamGameArgs", Games()\SteamGameArgs)
    WritePreferenceInteger("steamTimeoutMs", Games()\SteamDetectTimeoutMs)
    WritePreferenceString("gameRoot", Games()\GameRoot)
    WritePreferenceInteger("preset", Games()\Preset)
    WritePreferenceInteger("powerMode", Games()\PowerMode)
    WritePreferenceInteger("optimizeBackground", Games()\OptimizeBackground)
    WritePreferenceString("notes", Games()\Notes)
    WritePreferenceString("tags", Games()\Tags)
    WritePreferenceInteger("launchCount", Games()\LaunchCount)
    WritePreferenceQuad("lastPlayed", Games()\LastPlayed)
    WritePreferenceInteger("lastDurationSec", Games()\LastDurationSec)
    i + 1
  Next
  ClosePreferences()
  AddHistoryEntry("Exported profiles to " + GetFilePart(filePath))
  MessageRequester(#APP_NAME, "Exported " + Str(i) + " game profile(s).")
EndProcedure

Procedure ImportGamesProfile()
  Protected filePath.s, count.i, i.i
  Protected g.GameEntry
  Protected imported.i, merged.i

  filePath = OpenFileRequester("Import profile", "", "INI files (*.ini)|*.ini|All files (*.*)|*.*", 0)
  If filePath = "" : ProcedureReturn : EndIf
  If OpenPreferences(filePath) = 0
    MessageRequester(#APP_NAME, "Could not read import file.")
    ProcedureReturn
  EndIf

  PreferenceGroup("meta")
  count = ReadPreferenceInteger("count", 0)
  For i = 0 To count - 1
    PreferenceGroup("game_" + Str(i))
    g\Name = ReadPreferenceString("name", "")
    g\ExePath = ReadPreferenceString("exe", "")
    g\Args = ReadPreferenceString("args", "")
    g\WorkDir = ReadPreferenceString("workdir", "")
    g\Priority = ReadPreferenceInteger("priority", #ABOVE_NORMAL_PRIORITY_CLASS)
    g\Affinity = ReadPreferenceQuad("affinity", 0)
    g\Services = ReadPreferenceString("services", "")
    g\LaunchMode = ReadPreferenceInteger("launchMode", 0)
    g\SteamAppId = ReadPreferenceInteger("steamAppId", 0)
    g\SteamExe = ReadPreferenceString("steamExe", "")
    g\SteamGameArgs = ReadPreferenceString("steamGameArgs", "")
    g\SteamDetectTimeoutMs = ReadPreferenceInteger("steamTimeoutMs", 60000)
    g\GameRoot = ReadPreferenceString("gameRoot", "")
    g\Preset = ReadPreferenceInteger("preset", #PRESET_BALANCED)
    g\PowerMode = ReadPreferenceInteger("powerMode", #POWERMODE_HIGH)
    g\OptimizeBackground = ReadPreferenceInteger("optimizeBackground", 1)
    g\Notes = ReadPreferenceString("notes", "")
    g\Tags = ReadPreferenceString("tags", "")
    g\LaunchCount = ReadPreferenceInteger("launchCount", 0)
    g\LastPlayed = ReadPreferenceQuad("lastPlayed", 0)
    g\LastDurationSec = ReadPreferenceInteger("lastDurationSec", 0)

    If g\Name <> ""
      Select MergeOrAddGame(@g)
        Case 1
          imported + 1
        Case 2
          merged + 1
      EndSelect
    EndIf
  Next
  ClosePreferences()

  If imported > 0 Or merged > 0
    SaveGames()
    RefreshList()
  EndIf
  AddHistoryEntry("Imported profiles from " + GetFilePart(filePath) + " | new=" + Str(imported) + " merged=" + Str(merged))
  MessageRequester(#APP_NAME, "Imported " + Str(imported) + " and merged " + Str(merged) + " game profile(s).")
EndProcedure

Procedure CreateProfileSnapshot()
  Protected filePath.s
  filePath = SaveFileRequester("Create snapshot", "MyGameBooster_Snapshot.ini", "INI files (*.ini)|*.ini|All files (*.*)|*.*", 0)
  If filePath = "" : ProcedureReturn : EndIf
  SaveGames()
  If CopyFile_(GamesIni, filePath, #False)
    AddHistoryEntry("Created snapshot " + GetFilePart(filePath))
    MessageRequester(#APP_NAME, "Snapshot created successfully from:" + #LF$ + GamesIni)
  Else
    MessageRequester(#APP_NAME, "Failed to create snapshot.")
  EndIf
EndProcedure

Procedure RestoreProfileSnapshot()
  Protected filePath.s
  filePath = OpenFileRequester("Restore snapshot", "", "INI files (*.ini)|*.ini|All files (*.*)|*.*", 0)
  If filePath = "" : ProcedureReturn : EndIf
  If MessageRequester(#APP_NAME, "Restore this snapshot and replace the current game library at:" + #LF$ + GamesIni, #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) <> #PB_MessageRequester_Yes
    ProcedureReturn
  EndIf
  If CopyFile_(filePath, GamesIni, #False)
    LoadGames()
    RefreshList()
    AddHistoryEntry("Restored snapshot " + GetFilePart(filePath))
    MessageRequester(#APP_NAME, "Snapshot restored successfully to:" + #LF$ + GamesIni)
  Else
    MessageRequester(#APP_NAME, "Failed to restore snapshot.")
  EndIf
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

Procedure RecordLaunchStart(*g.GameEntry)
  Protected dirty.i
  Protected identity.s = GameIdentity(*g)

  If *g\LaunchMode = #LAUNCHMODE_STEAM And *g\ExePath <> ""
    If *g\GameRoot <> "" And StartsWithNoCase(*g\ExePath, *g\GameRoot) = 0
      *g\GameRoot = GetPathPart(*g\ExePath)
    EndIf
  EndIf

  ForEach Games()
    If GameIdentity(@Games()) = identity
      If *g\ExePath <> "" : Games()\ExePath = *g\ExePath : EndIf
      If *g\GameRoot <> "" : Games()\GameRoot = *g\GameRoot : EndIf
      Games()\LaunchCount + 1
      Games()\LastPlayed = Date()
      *g\LaunchCount = Games()\LaunchCount
      *g\LastPlayed = Games()\LastPlayed
      dirty = 1
      Break
    EndIf
  Next

  If dirty
    SaveGames()
    RefreshList()
  EndIf
EndProcedure

Procedure RecordLaunchResult(*g.GameEntry, durationSec.i)
  Protected dirty.i
  Protected identity.s = GameIdentity(*g)

  ForEach Games()
    If GameIdentity(@Games()) = identity
      Games()\LastDurationSec = durationSec
      *g\LastDurationSec = durationSec
      dirty = 1
      Break
    EndIf
  Next

  If dirty
    SaveGames()
    RefreshList()
  EndIf
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 381
; FirstLine = 387
; Folding = -------
; EnableXP
; DPIAware
