; SQLite database open/init/rebuild/count logic

Procedure.s DbEscape(text.s)
  ; SQLite uses single quotes, escaped as doubled single quotes.
  ProcedureReturn ReplaceString(text, "'", "''")
EndProcedure

Procedure.i DatabaseColumnExists(tableName.s, columnName.s)
  Protected found.i

  If IndexDbId = 0
    ProcedureReturn #False
  EndIf

  If DatabaseQuery(IndexDbId, "PRAGMA table_info(" + tableName + ");")
    While NextDatabaseRow(IndexDbId)
      If LCase(GetDatabaseString(IndexDbId, 1)) = LCase(columnName)
        found = #True
        Break
      EndIf
    Wend
    FinishDatabaseQuery(IndexDbId)
  EndIf

  ProcedureReturn found
EndProcedure

Procedure.q GetIndexedCountFromDbSlow()
  Protected sql.s
  Protected cnt.q

  If IndexDbId = 0
    ProcedureReturn 0
  EndIf

  LockMutex(DbMutex)
  sql = "SELECT COUNT(*) FROM files;"
  If DatabaseQuery(IndexDbId, sql)
    If NextDatabaseRow(IndexDbId)
      cnt = GetDatabaseQuad(IndexDbId, 0)
    EndIf
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  ProcedureReturn cnt
EndProcedure

Procedure.q GetIndexedCountFast()
  ; Prefer a maintained meta counter; fall back to COUNT(*) if missing.
  Protected now.q = ElapsedMilliseconds()
  Protected cnt.q = -1

  If CachedIndexedCount >= 0 And (now - CachedIndexedCountAtMS) < 5000
    ProcedureReturn CachedIndexedCount
  EndIf

  If IndexDbId = 0
    ProcedureReturn 0
  EndIf

  LockMutex(DbMutex)
  If DatabaseQuery(IndexDbId, "SELECT value FROM meta WHERE key='indexed_count' LIMIT 1;")
    If NextDatabaseRow(IndexDbId)
      cnt = Val(GetDatabaseString(IndexDbId, 0))
    EndIf
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  If cnt < 0
    cnt = GetIndexedCountFromDbSlow()
    If IndexDbId And DbMutex
      LockMutex(DbMutex)
      DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','" + Str(cnt) + "');")
      UnlockMutex(DbMutex)
    EndIf
  EndIf

  CachedIndexedCount = cnt
  CachedIndexedCountAtMS = now
  ProcedureReturn cnt
EndProcedure

Procedure.b RebuildIndexDatabase()
  ; Rebuild is implemented by recreating the SQLite file instead of VACUUM,
  ; which can fail/crash on some setups (WAL/journal/locking edge cases).
  Protected dbPath.s
  Protected ok.i

  If DbMutex = 0
    DbMutex = CreateMutex()
  EndIf

  dbPath = ResolveDbPath(IndexDbPath)
  LogLine("RebuildIndexDatabase dbPath=" + dbPath)
  If dbPath = ""
    MessageRequester(#APP_NAME, "Rebuild failed: DB path is empty.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  If IndexDbId
    LockMutex(DbMutex)
    CloseDatabase(IndexDbId)
    IndexDbId = 0
    UnlockMutex(DbMutex)
  EndIf

  If FileSize(dbPath) >= 0
    DeleteFile(dbPath)
  EndIf
  If FileSize(dbPath + "-wal") >= 0
    DeleteFile(dbPath + "-wal")
  EndIf
  If FileSize(dbPath + "-shm") >= 0
    DeleteFile(dbPath + "-shm")
  EndIf

  InitDatabase()
  ok = Bool(IndexDbId <> 0)
  If ok = 0
    MessageRequester(#APP_NAME, "Rebuild failed: could not open index database:" + #CRLF$ + dbPath + #CRLF$ + DatabaseError(), #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "DELETE FROM files;")
  DatabaseUpdate(IndexDbId, "DELETE FROM meta WHERE key='last_scan_id';")
  UnlockMutex(DbMutex)

  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','0');")
  UnlockMutex(DbMutex)

  IndexTotalFiles = 0
  CachedIndexedCount = 0
  CachedIndexedCountAtMS = ElapsedMilliseconds()
  ProcedureReturn #True
EndProcedure

Procedure FinalizeCompletedScan()
  If IndexDbId = 0 Or DbMutex = 0 Or CurrentScanId <= 0
    ProcedureReturn
  EndIf

  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "BEGIN TRANSACTION;")
  DatabaseUpdate(IndexDbId, "DELETE FROM files WHERE scan_id <> " + Str(CurrentScanId) + ";")
  If DatabaseQuery(IndexDbId, "SELECT COUNT(*) FROM files;")
    If NextDatabaseRow(IndexDbId)
      IndexTotalFiles = GetDatabaseQuad(IndexDbId, 0)
    EndIf
    FinishDatabaseQuery(IndexDbId)
  EndIf
  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','" + Str(IndexTotalFiles) + "');")
  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('last_scan_id','" + Str(CurrentScanId) + "');")
  DatabaseUpdate(IndexDbId, "COMMIT;")
  UnlockMutex(DbMutex)

  CachedIndexedCount = IndexTotalFiles
  CachedIndexedCountAtMS = ElapsedMilliseconds()
EndProcedure

Procedure.s ResolveDbPath(dbPath.s)
  Protected p.s = Trim(dbPath)
  Protected candidate.s
  Protected f.i

  If p = ""
    p = "HandySearch.db"
  EndIf

  If FindString(p, ":\", 1) = 0 And Left(p, 2) <> "\\"
    p = AppPath + p
  EndIf

  If FileSize(p) < 0
    EnsureParentDirectoryForFile(p)
    f = CreateFile(#PB_Any, p)
    If f
      CloseFile(f)
      DeleteFile(p)
    Else
      candidate = GetWritableAppDataFolder() + "HandySearch.db"
      EnsureParentDirectoryForFile(candidate)
      p = candidate
    EndIf
  EndIf

  ProcedureReturn p
EndProcedure

Procedure InitDatabase()
  Protected dbPath.s
  Protected folder.s
  Protected f.i

  dbPath = ResolveDbPath(IndexDbPath)
  LogLine("RebuildIndexDatabase dbPath=" + dbPath)
  folder = GetPathPart(dbPath)
  If folder <> "" And FileSize(folder) <> -2
    EnsureDirectoryTree(folder)
  EndIf

  If UseSQLiteDatabase() = 0
    MessageRequester(#APP_NAME, "SQLite database support is not available.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  IndexDbId = OpenDatabase(#PB_Any, dbPath, "", "", #PB_Database_SQLite)
  If IndexDbId = 0 And FileSize(dbPath) < 0
    f = CreateFile(#PB_Any, dbPath)
    If f
      CloseFile(f)
      IndexDbId = OpenDatabase(#PB_Any, dbPath, "", "", #PB_Database_SQLite)
    EndIf
  EndIf
  If IndexDbId = 0
    MessageRequester(#APP_NAME, "Failed to open index database: " + dbPath + #CRLF$ +
                                " " + DatabaseError(), #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "PRAGMA journal_mode=WAL;")
  DatabaseUpdate(IndexDbId, "PRAGMA synchronous=NORMAL;")
  DatabaseUpdate(IndexDbId, "PRAGMA temp_store=MEMORY;")
  DatabaseUpdate(IndexDbId, "PRAGMA mmap_size=268435456;")
  DatabaseUpdate(IndexDbId, "PRAGMA cache_size=-200000;")
  DatabaseUpdate(IndexDbId, "CREATE TABLE IF NOT EXISTS files(path TEXT PRIMARY KEY, name TEXT, dir TEXT, size INTEGER, mtime INTEGER, is_dir INTEGER NOT NULL DEFAULT 0, scan_id INTEGER NOT NULL DEFAULT 0);")
  If DatabaseColumnExists("files", "is_dir") = 0
    DatabaseUpdate(IndexDbId, "ALTER TABLE files ADD COLUMN is_dir INTEGER NOT NULL DEFAULT 0;")
  EndIf
  If DatabaseColumnExists("files", "scan_id") = 0
    DatabaseUpdate(IndexDbId, "ALTER TABLE files ADD COLUMN scan_id INTEGER NOT NULL DEFAULT 0;")
  EndIf
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_name ON files(name);")
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_dir ON files(dir);")
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_is_dir ON files(is_dir);")
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_scan_id ON files(scan_id);")
  DatabaseUpdate(IndexDbId, "CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);")
  UnlockMutex(DbMutex)
EndProcedure
