; Background indexing pipeline and worker coordination

Procedure.s DirectoryEntryLabel(path.s)
  Protected p.s = NormalizePath(path)
  Protected name.s

  If Right(p, 1) = "\" And Len(p) > 1
    p = Left(p, Len(p) - 1)
  EndIf

  If Len(p) = 2 And Right(p, 1) = ":"
    ProcedureReturn p
  EndIf

  name = GetFilePart(p)
  If name = ""
    ProcedureReturn p
  EndIf

  ProcedureReturn name
EndProcedure

Procedure AddProgressFiles(scannedFiles.q, matches.q)
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  FilesScanned + scannedFiles
  MatchesFound + matches
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure AddProgressDir()
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  DirsScanned + 1
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure SetProgressFolder(folder.s)
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  CurrentFolder = folder
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure EnqueueResult(path.s)
  If ResultMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ResultMutex)
  AddElement(PendingResults())
  PendingResults() = path
  UnlockMutex(ResultMutex)
EndProcedure

Procedure EnqueueResultsBatch(List batch.s())
  If ResultMutex = 0 Or ListSize(batch()) = 0
    ProcedureReturn
  EndIf

  LockMutex(ResultMutex)
  ForEach batch()
    AddElement(PendingResults())
    PendingResults() = batch()
  Next
  UnlockMutex(ResultMutex)
EndProcedure

Procedure.i PendingResultsCount()
  Protected count.i

  If ResultMutex = 0
    ProcedureReturn 0
  EndIf

  LockMutex(ResultMutex)
  count = ListSize(PendingResults())
  UnlockMutex(ResultMutex)
  ProcedureReturn count
EndProcedure

Procedure PushDirectory(dir.s)
  ; Expect normalized dirs with trailing backslash.
  LockMutex(ScanStateMutex)
  AddElement(DirQueue())
  DirQueue() = dir
  QueueCount + 1
  UnlockMutex(ScanStateMutex)

  ReleaseSemaphore_(DirQueueSem, 1, 0)
EndProcedure

Procedure.s PopDirectory()
  Protected dir.s

  LockMutex(ScanStateMutex)
  If FirstElement(DirQueue())
    dir = DirQueue()
    DeleteElement(DirQueue())
    QueueCount - 1
    ActiveDirCount + 1
  EndIf
  UnlockMutex(ScanStateMutex)

  ProcedureReturn dir
EndProcedure

Procedure MarkDirectoryDone()
  LockMutex(ScanStateMutex)
  If ActiveDirCount > 0
    ActiveDirCount - 1
  EndIf
  UnlockMutex(ScanStateMutex)
EndProcedure

Procedure SearchDirectoryWorker(dir.s, pattern.s, regexID.i, List localResults.s())
  ; Deprecated: kept for compatibility with older structure.
EndProcedure

Procedure.b IsReparsePoint(fullPath.s)
  Protected attrs.i = GetFileAttributes_(fullPath)
  If attrs = -1
    ProcedureReturn #False
  EndIf
  ProcedureReturn Bool(attrs & $400)
EndProcedure

Procedure IndexDirectoryWorker(dir.s, List batch.IndexRecord())
  Protected dirID.i, entryName.s, fullpath.s
  Protected localFiles.q
  Protected retryCount.i
  Protected parentDir.s
  Protected canonical.s

  If WorkStop Or StopSearch
    ProcedureReturn
  EndIf

  If Right(dir, 1) <> "\"
    dir = dir + "\"
  EndIf

  If IsExcludedPathPrefix(dir)
    ProcedureReturn
  EndIf

  parentDir = GetPathPart(Left(dir, Len(dir) - 1))
  SetProgressFolder(dir)
  AddProgressDir()

  canonical = LCase(NormalizePath(dir))
  LockMutex(VisitedFoldersMutex)
  If FindMapElement(VisitedFolders(), canonical)
    UnlockMutex(VisitedFoldersMutex)
    ProcedureReturn
  EndIf
  VisitedFolders(canonical) = 1
  UnlockMutex(VisitedFoldersMutex)

  If parentDir = ""
    AddElement(batch())
    batch()\Path = dir
    batch()\Name = DirectoryEntryLabel(dir)
    batch()\Dir = parentDir
    batch()\Size = 0
    batch()\MTime = 0
    batch()\IsDir = 1
    batch()\ScanId = CurrentScanId
  EndIf

  Repeat
    dirID = ExamineDirectory(#PB_Any, dir, "*")
    If dirID = 0
      If retryCount < 2 And (WorkStop = 0 And StopSearch = 0)
        LogLine("Retrying directory access: " + dir)
        Delay(50)
        retryCount + 1
        Continue
      Else
        LogLine("Skipping directory (access denied/not found): " + dir)
        ProcedureReturn
      EndIf
    EndIf
    Break
  Until #True

  While NextDirectoryEntry(dirID)
    If WorkStop Or StopSearch : Break : EndIf

    entryName = DirectoryEntryName(dirID)
    If entryName = "." Or entryName = ".."
      Continue
    EndIf

    fullpath = dir + entryName

    Select DirectoryEntryType(dirID)
      Case #PB_DirectoryEntry_File
        localFiles + 1
        If IsExcludedFileName(entryName) = 0
          AddElement(batch())
          batch()\Path = fullpath
          batch()\Name = entryName
          batch()\Dir = dir
          batch()\Size = DirectoryEntrySize(dirID)
          batch()\MTime = DirectoryEntryDate(dirID, #PB_Date_Modified)
          batch()\IsDir = 0
          batch()\ScanId = CurrentScanId
        EndIf

        If localFiles % 100 = 0
          AddProgressFiles(100, 0)
          localFiles - 100
        EndIf

      Case #PB_DirectoryEntry_Directory
        If IsExcludedDirName(entryName) = 0
          If IsExcludedPathPrefix(fullpath + "\")
            Continue
          EndIf

          AddElement(batch())
          batch()\Path = fullpath + "\"
          batch()\Name = entryName
          batch()\Dir = dir
          batch()\Size = 0
          batch()\MTime = DirectoryEntryDate(dirID, #PB_Date_Modified)
          batch()\IsDir = 1
          batch()\ScanId = CurrentScanId

          If IsReparsePoint(fullpath) = 0
            PushDirectory(fullpath + "\")
          EndIf
        EndIf
    EndSelect
  Wend

  FinishDirectory(dirID)

  If localFiles
    AddProgressFiles(localFiles, 0)
  EndIf
EndProcedure

Procedure DbWriterThreadProc(dummy.i)
  Protected NewList localQueue.IndexRecord()

  While DbWriterStop = 0
    If WaitForSingleObject_(DbWriterQueueSem, 1000) = #WAIT_TIMEOUT
      If DbWriterStop : Break : EndIf
      Continue
    EndIf

    LockMutex(DbWriterQueueMutex)
    If ListSize(DbWriterQueue()) > 0
      ForEach DbWriterQueue()
        AddElement(localQueue())
        localQueue() = DbWriterQueue()
      Next
      ClearList(DbWriterQueue())
    EndIf
    UnlockMutex(DbWriterQueueMutex)

    If ListSize(localQueue()) > 0
      FlushIndexBatchToDb(localQueue())
      ClearList(localQueue())
    EndIf

    Delay(10)
  Wend
EndProcedure

Procedure FlushIndexBatchToDb(List batch.IndexRecord())
  Protected sql.s
  Protected values.s
  Protected cnt.i
  Protected rowCount.i
  Protected NewList pathsForUi.s()

  If IndexDbId = 0 Or DbMutex = 0
    ClearList(batch())
    ProcedureReturn
  EndIf

  rowCount = ListSize(batch())
  If rowCount = 0
    ProcedureReturn
  EndIf

  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "BEGIN TRANSACTION;")

  cnt = 0
  values = ""
  ForEach batch()
    If values <> "" : values + "," : EndIf
    values + "('" + DbEscape(batch()\Path) + "','" + DbEscape(batch()\Name) + "','" + DbEscape(batch()\Dir) + "'," +
              Str(batch()\Size) + "," + Str(batch()\MTime) + "," + Str(Bool(batch()\IsDir)) + "," + Str(batch()\ScanId) + ")"

    AddElement(pathsForUi())
    pathsForUi() = batch()\Path

    IndexTotalFiles + 1
    cnt + 1

    If cnt >= 500
      sql = "INSERT OR REPLACE INTO files(path,name,dir,size,mtime,is_dir,scan_id) VALUES" + values + ";"
      DatabaseUpdate(IndexDbId, sql)
      values = ""
      cnt = 0
    EndIf
  Next

  If values <> ""
    sql = "INSERT OR REPLACE INTO files(path,name,dir,size,mtime,is_dir,scan_id) VALUES" + values + ";"
    DatabaseUpdate(IndexDbId, sql)
  EndIf

  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','" + Str(IndexTotalFiles) + "');")
  DatabaseUpdate(IndexDbId, "COMMIT;")
  UnlockMutex(DbMutex)

  EnqueueResultsBatch(pathsForUi())
  ClearList(batch())
EndProcedure

Procedure EnqueueDbBatch(List batch.IndexRecord())
  If DbWriterQueueMutex = 0 Or DbWriterQueueSem = 0
    ProcedureReturn
  EndIf

  LockMutex(DbWriterQueueMutex)
  ForEach batch()
    AddElement(DbWriterQueue())
    DbWriterQueue() = batch()
  Next
  UnlockMutex(DbWriterQueueMutex)

  ReleaseSemaphore_(DbWriterQueueSem, 1, 0)
EndProcedure

Procedure WorkerThreadProc(*params.WorkerParams)
  Protected dir.s
  Protected NewList batch.IndexRecord()

  While WorkStop = 0 And StopSearch = 0
    If IndexingPaused And IndexPauseEvent
      WaitForSingleObject_(IndexPauseEvent, 200)
      Continue
    EndIf

    If PendingResultsCount() > 10000
      Delay(100)
      Continue
    EndIf

    If WaitForSingleObject_(DirQueueSem, 200) = #WAIT_TIMEOUT
      LockMutex(ScanStateMutex)
      If QueueCount = 0 And ActiveDirCount = 0
        UnlockMutex(ScanStateMutex)
        Break
      EndIf
      UnlockMutex(ScanStateMutex)
      Continue
    EndIf

    If WorkStop Or StopSearch
      Break
    EndIf

    dir = PopDirectory()
    If dir = ""
      Continue
    EndIf

    IndexDirectoryWorker(dir, batch())
    If ListSize(batch()) >= ConfigBatchSize
      EnqueueDbBatch(batch())
      ClearList(batch())
    EndIf

    MarkDirectoryDone()
    Delay(1)
  Wend

  If ListSize(batch()) > 0
    EnqueueDbBatch(batch())
    ClearList(batch())
  EndIf
EndProcedure

Procedure.i GetCpuCount()
  Protected cpu.i = Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS"))
  If cpu < 1
    cpu = 4
  EndIf
  ProcedureReturn cpu
EndProcedure

Procedure GetAllIndexableDriveRoots(List roots.s())
  ; GetLogicalDriveStrings_ returns a MULTI_SZ in TCHARs (Unicode on modern PB).
  Protected bufChars.i = 4096
  Protected *buf
  Protected posChars.i
  Protected drive.s
  Protected dt.i
  Protected probe.i

  ClearList(roots())

  *buf = AllocateMemory(bufChars * SizeOf(Character))
  If *buf = 0
    ProcedureReturn
  EndIf

  If GetLogicalDriveStrings_(bufChars, *buf) = 0
    FreeMemory(*buf)
    ProcedureReturn
  EndIf

  posChars = 0
  While PeekS(*buf + posChars * SizeOf(Character), -1) <> ""
    drive = PeekS(*buf + posChars * SizeOf(Character), -1)
    posChars + Len(drive) + 1

    dt = GetDriveType_(drive)
    Select dt
      Case 2, 3, 6
        probe = ExamineDirectory(#PB_Any, drive, "*")
        If probe
          FinishDirectory(probe)
          AddElement(roots())
          roots() = drive
        EndIf
    EndSelect
  Wend

  FreeMemory(*buf)
EndProcedure

Procedure StartIndexingAllFixedDrives()
  Protected i.i
  Protected NewList roots.s()
  Protected *wparams.WorkerParams
  Protected fallbackRoot.s

  LockMutex(VisitedFoldersMutex)
  ClearMap(VisitedFolders())
  UnlockMutex(VisitedFoldersMutex)

  StopSearch = 0
  WorkStop = 0
  IndexTotalFiles = 0
  CurrentScanId = Date()
  WorkerCount = -1

  DbWriterStop = 0
  If DbWriterQueueMutex = 0 : DbWriterQueueMutex = CreateMutex() : EndIf
  If DbWriterQueueSem = 0 : DbWriterQueueSem = CreateSemaphore_(0, 0, 2147483647, 0) : EndIf
  If IsThread(DbWriterThread) = 0
    DbWriterThread = CreateThread(@DbWriterThreadProc(), 0)
  EndIf

  If IndexPauseEvent = 0
    IndexPauseEvent = CreateEvent_(0, 1, 1, 0)
  Else
    SetEvent_(IndexPauseEvent)
  EndIf
  IndexingPaused = 0

  If ProgressMutex
    LockMutex(ProgressMutex)
    CurrentFolder = ""
    FilesScanned = 0
    DirsScanned = 0
    MatchesFound = 0
    UnlockMutex(ProgressMutex)
  EndIf

  If ScanStateMutex = 0
    ScanStateMutex = CreateMutex()
  EndIf
  If DirQueueSem = 0
    DirQueueSem = CreateSemaphore_(0, 0, 2147483647, 0)
  EndIf

  LockMutex(ScanStateMutex)
  ClearList(DirQueue())
  QueueCount = 0
  ActiveDirCount = 0
  UnlockMutex(ScanStateMutex)

  GetAllIndexableDriveRoots(roots())
  If ListSize(roots()) = 0
    fallbackRoot = GetPathPart(AppPath)
    If FindString(fallbackRoot, ":\", 1) = 0
      fallbackRoot = "C:\"
    EndIf
    AddElement(roots()) : roots() = fallbackRoot
  EndIf

  ForEach roots()
    PushDirectory(roots())
  Next

  WorkerCount = ConfigThreadCount
  If WorkerCount <= 0
    WorkerCount = GetCpuCount() * 2
    If WorkerCount < 2
      WorkerCount = 4
    EndIf
    If WorkerCount > 32
      WorkerCount = 32
    EndIf
  Else
    If WorkerCount < 1
      WorkerCount = 1
    EndIf
    If WorkerCount > 64
      WorkerCount = 64
    EndIf
  EndIf

  IndexingActive = 1

  ReDim WorkerThreads(WorkerCount - 1)
  *wparams = AllocateStructure(WorkerParams)
  If *wparams
    *wparams\Dummy = 0
  EndIf

  For i = 0 To WorkerCount - 1
    WorkerThreads(i) = CreateThread(@WorkerThreadProc(), *wparams)
    If WorkerThreads(i)
      SetThreadPriority_(ThreadID(WorkerThreads(i)), -1)
    EndIf
  Next

  For i = 0 To WorkerCount - 1
    If WorkerThreads(i)
      WaitThread(WorkerThreads(i))
      WorkerThreads(i) = 0
    EndIf
  Next

  If *wparams
    FreeStructure(*wparams)
  EndIf

  DbWriterStop = 1
  If DbWriterQueueSem
    ReleaseSemaphore_(DbWriterQueueSem, 1, 0)
  EndIf
  If IsThread(DbWriterThread)
    WaitThread(DbWriterThread)
    DbWriterThread = 0
  EndIf

  If StopSearch = 0 And WorkStop = 0
    FinalizeCompletedScan()
  EndIf

  If ResultMutex
    LockMutex(ResultMutex)
    ClearList(PendingResults())
    UnlockMutex(ResultMutex)
  EndIf

  IndexingActive = 0
  RequestUiStateSync()
EndProcedure

Procedure SearchThreadProc(*params.SearchParams)
  ; Legacy entrypoint name: now runs indexing.
  StartIndexingAllFixedDrives()
  If *params
    FreeStructure(*params)
  EndIf
EndProcedure
