; Config/INI parsing and exclude state

Procedure ClearExcludes()
  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  ClearMap(ExcludeDirNames())
  ClearMap(ExcludeFileNames())
  ClearMap(ExcludePathPrefixes())
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
EndProcedure

Procedure.i IsExcludedFileName(fileName.s)
  Protected key.s = LCase(Trim(fileName))
  Protected found.i

  If key = "" : ProcedureReturn 0 : EndIf
  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  found = FindMapElement(ExcludeFileNames(), key)
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
  ProcedureReturn found
EndProcedure

Procedure.i IsExcludedPathPrefix(path.s)
  Protected normalized.s = LCase(NormalizePath(Trim(path)))
  Protected rootRelative.s
  Protected prefix.s
  Protected slashPos.i
  Protected found.i

  If normalized = ""
    ProcedureReturn 0
  EndIf

  rootRelative = normalized
  If FindString(normalized, ":\\", 1) = 2
    rootRelative = Mid(normalized, 3)
  ElseIf Left(normalized, 2) = "\\"
    slashPos = FindString(normalized, "\\", 3)
    If slashPos > 0
      slashPos = FindString(normalized, "\\", slashPos + 1)
      If slashPos > 0
        rootRelative = Mid(normalized, slashPos)
      EndIf
    EndIf
  EndIf

  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  ForEach ExcludePathPrefixes()
    prefix = MapKey(ExcludePathPrefixes())
    If Left(normalized, Len(prefix)) = prefix
      found = #True
      Break
    EndIf
    If Left(prefix, 1) = "\\" And Left(rootRelative, Len(prefix)) = prefix
      found = #True
      Break
    EndIf
  Next
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf

  ProcedureReturn found
EndProcedure

Procedure WriteDefaultExcludesIni(filePath.s)
  Protected f.i

  EnsureParentDirectoryForFile(filePath)

  f = CreateFile(#PB_Any, filePath)
  If f = 0
    ProcedureReturn
  EndIf

  WriteStringN(f, "; HandySearch configuration")
  WriteStringN(f, "; Lines are matched case-insensitively against the base name.")
  WriteStringN(f, ";")
  WriteStringN(f, "; Sections:")
  WriteStringN(f, ";   [App]         - UI behavior")
  WriteStringN(f, ";   [Index]       - index/database")
  WriteStringN(f, ";   [Search]      - query behavior")
  WriteStringN(f, ";   [Performance] - performance tuning")
  WriteStringN(f, ";   [ExcludeDirs]  - folder names to skip")
  WriteStringN(f, ";   [ExcludeFiles] - file names to skip")
  WriteStringN(f, ";   [ExcludePaths] - full path prefixes to skip")
  WriteStringN(f, "")

  WriteStringN(f, "[App]")
  WriteStringN(f, "; StartMinimized=1 starts hidden in the tray")
  WriteStringN(f, "StartMinimized=0")
  WriteStringN(f, "; CloseToTray=1 makes the X button hide to tray")
  WriteStringN(f, "CloseToTray=1")
  WriteStringN(f, "; MinimizeToTray=1 hides when minimized")
  WriteStringN(f, "MinimizeToTray=1")
  WriteStringN(f, "; RunAtStartup=1 registers a Task Scheduler logon task")
  WriteStringN(f, "RunAtStartup=0")
  WriteStringN(f, "; AutoStartIndex=1 starts indexing on launch")
  WriteStringN(f, "AutoStartIndex=0")
  WriteStringN(f, "; LiveMatchFullPath=1 makes live streamed results match full paths")
  WriteStringN(f, "LiveMatchFullPath=1")
  WriteStringN(f, "")

  WriteStringN(f, "[Index]")
  WriteStringN(f, "; DbPath is relative to the EXE folder if not absolute")
  WriteStringN(f, "DbPath=HandySearch.db")
  WriteStringN(f, "")

  WriteStringN(f, "[Search]")
  WriteStringN(f, "MaxResults=10000")
  WriteStringN(f, "DebounceMS=120")
  WriteStringN(f, "")

  WriteStringN(f, "[Performance]")
  WriteStringN(f, "; Threads=0 means auto (2x CPU, max 32)")
  WriteStringN(f, "Threads=0")
  WriteStringN(f, "; BatchSize controls how many results are queued per lock")
  WriteStringN(f, "BatchSize=200")
  WriteStringN(f, "")

  WriteStringN(f, "[ExcludeDirs]")
  WriteStringN(f, "programdata")
  WriteStringN(f, "$recycle.bin")
  WriteStringN(f, "system volume information")
  WriteStringN(f, "windows")
  WriteStringN(f, "")

  WriteStringN(f, "[ExcludeFiles]")
  WriteStringN(f, "desktop.ini")
  WriteStringN(f, "pagefile.sys")
  WriteStringN(f, "swapfile.sys")
  WriteStringN(f, "hiberfil.sys")
  WriteStringN(f, "dumpstack.log.tmp")
  WriteStringN(f, "memory.dmp")
  WriteStringN(f, "")

  WriteStringN(f, "[ExcludePaths]")
  WriteStringN(f, "; Skip very noisy or virtual system locations by full prefix.")
  WriteStringN(f, "; Entries starting with \\ apply from any drive root.")
  WriteStringN(f, "$extend")
  WriteStringN(f, "\$extend")
  WriteStringN(f, "config.msi")
  WriteStringN(f, "\config.msi")
  WriteStringN(f, "msocache")
  WriteStringN(f, "\msocache")

  CloseFile(f)
EndProcedure

Procedure ClampConfigValues()
  If ConfigThreadCount < 0
    ConfigThreadCount = 0
  EndIf

  If ConfigBatchSize < 10
    ConfigBatchSize = 10
  EndIf
  If ConfigBatchSize > 5000
    ConfigBatchSize = 5000
  EndIf

  If SearchMaxResults < 100
    SearchMaxResults = 100
  EndIf
  If SearchMaxResults > 200000
    SearchMaxResults = 200000
  EndIf

  If SearchDebounceMS < 0
    SearchDebounceMS = 0
  EndIf
  If SearchDebounceMS > 5000
    SearchDebounceMS = 5000
  EndIf

  If Trim(IndexDbPath) = ""
    IndexDbPath = "HandySearch.db"
  EndIf
EndProcedure

Procedure LoadExcludesIni(filePath.s)
  Protected line.s, section.s, item.s
  Protected pos.i, f.i
  Protected key.s, value.s
  Protected vLower.s
  Protected normalizedPath.s
  Protected appDataLower.s
  Protected localAppDataLower.s
  Protected tempLower.s

  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  ClearMap(ExcludeDirNames())
  ClearMap(ExcludeFileNames())
  ClearMap(ExcludePathPrefixes())

  If FileSize(filePath) < 0
    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    WriteDefaultExcludesIni(filePath)
    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  EndIf

  f = ReadFile(#PB_Any, filePath)
  If f = 0
    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    ProcedureReturn
  EndIf

  section = ""
  While Eof(f) = 0
    line = Trim(ReadString(f))

    If line = "" : Continue : EndIf
    If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

    pos = FindString(line, ";", 1)
    If pos > 0
      line = Trim(Left(line, pos - 1))
    EndIf
    If line = "" : Continue : EndIf

    If Left(line, 1) = "[" And Right(line, 1) = "]"
      section = LCase(Trim(Mid(line, 2, Len(line) - 2)))
      Continue
    EndIf

    pos = FindString(line, "=", 1)
    If pos > 0
      key = LCase(Trim(Left(line, pos - 1)))
      value = Trim(Mid(line, pos + 1))
    Else
      key = ""
      value = Trim(line)
    EndIf

    If value = ""
      If section <> "excludedirs" And section <> "excludedir" And section <> "excludefiles" And section <> "excludefile"
        Continue
      EndIf
    EndIf

    Select section
      Case "app"
        Select key
          Case "startminimized"
            AppStartMinimized = Val(value)
          Case "closetotray"
            AppCloseToTray = Val(value)
          Case "minimizetotray"
            AppMinimizeToTray = Val(value)
          Case "runatstartup"
            AppRunAtStartup = Val(value)
          Case "autostartindex"
            AppAutoStartIndex = Val(value)
          Case "livematchfullpath"
            LiveMatchFullPath = Val(value)
        EndSelect

      Case "index"
        Select key
          Case "dbpath"
            IndexDbPath = value
        EndSelect

      Case "search"
        Select key
          Case "maxresults"
            SearchMaxResults = Val(value)
          Case "debouncems"
            SearchDebounceMS = Val(value)
        EndSelect

      Case "performance"
        Select key
          Case "threads"
            ConfigThreadCount = Val(value)
          Case "batchsize"
            ConfigBatchSize = Val(value)
        EndSelect

      Case "excludedirs", "excludedir"
        item = ""
        If key <> ""
          vLower = LCase(Trim(value))
          Select vLower
            Case "", "1", "true", "yes", "on"
              item = key
            Case "0", "false", "no", "off"
              item = ""
            Default
              item = value
          EndSelect
        Else
          item = value
        EndIf

        item = LCase(Trim(item))
        If item <> ""
          ExcludeDirNames(item) = 1
        EndIf

      Case "excludefiles", "excludefile"
        item = ""
        If key <> ""
          vLower = LCase(Trim(value))
          Select vLower
            Case "", "1", "true", "yes", "on"
              item = key
            Case "0", "false", "no", "off"
              item = ""
            Default
              item = value
          EndSelect
        Else
          item = value
        EndIf

        item = LCase(Trim(item))
        If item <> ""
          ExcludeFileNames(item) = 1
        EndIf

      Case "excludepaths", "excludepath"
        item = ""
        If key <> ""
          vLower = LCase(Trim(value))
          Select vLower
            Case "", "1", "true", "yes", "on"
              item = key
            Case "0", "false", "no", "off"
              item = ""
            Default
              item = value
          EndSelect
        Else
          item = value
        EndIf

        normalizedPath = LCase(NormalizePath(Trim(item)))
        If normalizedPath <> ""
          If Left(normalizedPath, 1) <> "\" And FindString(normalizedPath, ":\", 1) = 0 And Left(normalizedPath, 2) <> "\\"
            normalizedPath = "\" + normalizedPath
          EndIf
          ExcludePathPrefixes(normalizedPath) = 1
        EndIf
    EndSelect
  Wend

  CloseFile(f)

  appDataLower = LCase(NormalizePath(GetEnvironmentVariable("APPDATA")))
  If appDataLower <> ""
    If Right(appDataLower, 1) <> "\" : appDataLower + "\" : EndIf
    ExcludePathPrefixes(appDataLower + "microsoft\search\") = 1
  EndIf

  localAppDataLower = LCase(NormalizePath(GetEnvironmentVariable("LOCALAPPDATA")))
  If localAppDataLower <> ""
    If Right(localAppDataLower, 1) <> "\" : localAppDataLower + "\" : EndIf
    ExcludePathPrefixes(localAppDataLower + "microsoft\windows\temporary internet files\") = 1
  EndIf

  tempLower = LCase(NormalizePath(GetEnvironmentVariable("TEMP")))
  If tempLower <> ""
    If Right(tempLower, 1) <> "\" : tempLower + "\" : EndIf
    ExcludePathPrefixes(tempLower) = 1
  EndIf

  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
  ClampConfigValues()
EndProcedure

Procedure SaveIniKey(filePath.s, sectionName.s, keyName.s, value.s)
  EnsureParentDirectoryForFile(filePath)

  If FileSize(filePath) < 0
    WriteDefaultExcludesIni(filePath)
  EndIf

  If FileSize(filePath) < 0
    ProcedureReturn
  EndIf

  ; In PureBasic, CreatePreferences overwrites the file entirely.
  ; OpenPreferences is required to update an existing file.
  If OpenPreferences(filePath)
    PreferenceGroup(sectionName)
    WritePreferenceString(keyName, value)

    ; Ensure Exclude sections remain present and populated.
    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf

    PreferenceGroup("ExcludeDirs")
    ForEach ExcludeDirNames()
      WritePreferenceString(MapKey(ExcludeDirNames()), "")
    Next

    PreferenceGroup("ExcludeFiles")
    ForEach ExcludeFileNames()
      WritePreferenceString(MapKey(ExcludeFileNames()), "")
    Next

    PreferenceGroup("ExcludePaths")
    ForEach ExcludePathPrefixes()
      WritePreferenceString(MapKey(ExcludePathPrefixes()), "")
    Next

    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf

    ClosePreferences()
    LoadExcludesIni(filePath)
  EndIf
EndProcedure

Procedure.i IsExcludedDirName(dirName.s)
  Protected key.s = LCase(Trim(dirName))
  Protected found.i

  If key = "" : ProcedureReturn 0 : EndIf
  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  found = FindMapElement(ExcludeDirNames(), key)
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
  ProcedureReturn found
EndProcedure

Procedure.s GetConfigPath()
  Protected candidate.s
  Protected f.i

  If ConfigIniPath <> ""
    ProcedureReturn ConfigIniPath
  EndIf

  candidate = AppPath + #INI_FILE
  If FileSize(candidate) >= 0
    ConfigIniPath = candidate
    ProcedureReturn ConfigIniPath
  EndIf

  If EnsureParentDirectoryForFile(candidate)
    f = CreateFile(#PB_Any, candidate)
    If f
      CloseFile(f)
      DeleteFile(candidate)
      ConfigIniPath = candidate
      ProcedureReturn ConfigIniPath
    EndIf
  EndIf

  candidate = GetWritableAppDataFolder() + #INI_FILE
  EnsureParentDirectoryForFile(candidate)
  ConfigIniPath = candidate
  ProcedureReturn ConfigIniPath
EndProcedure
