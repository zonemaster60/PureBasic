; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.30 (x64)
; Improved version with bug fixes and optimizations

#IOCTL_DISK_PERFORMANCE = $70020

; Windows constants (guarded in case PB defines them)
CompilerIf Not Defined(GENERIC_READ, #PB_Constant)
  #GENERIC_READ = $80000000
CompilerEndIf
CompilerIf Not Defined(FILE_SHARE_READ, #PB_Constant)
  #FILE_SHARE_READ = 1
CompilerEndIf
CompilerIf Not Defined(FILE_SHARE_WRITE, #PB_Constant)
  #FILE_SHARE_WRITE = 2
CompilerEndIf

#STARTUP_TASK_NAME = "HandyDrvLED"

; Constants for better readability
#ICON_WRITE = 1
#ICON_READ = 2
#ICON_SYSTEM = 3
#ICON_IDLE = 4
#UPDATE_INTERVAL = 100
#TOOLTIP_UPDATE_INTERVAL = 2500

; Activity detection thresholds
#ACTIVITY_THRESHOLD_BYTES_PER_SEC = 4096

; PDH counters are not very granular; hold activity briefly
#ACTIVITY_HOLD_MS = 300

; Sample PDH at a stable interval (too fast can look "steppy")
#PDH_SAMPLE_INTERVAL_MS = 200

; When PDH works, avoid hammering IOCTL_DISK_PERFORMANCE
#IOCTL_BACKOFF_CYCLES = 50

; PDH formatting constants
#PDH_FMT_DOUBLE = $00000200

#EMAIL_NAME = "zonemaster60@gmail.com"
#APP_NAME = "HandyDrvLED"
Global version.s = "v1.0.3.0"

Global AppPath.s = GetPathPart(ProgramFilename())
Global IniPath.s = AppPath + #APP_NAME + ".ini"
Global LogBase.s = AppPath + #APP_NAME
Global LogPath.s = LogBase + ".log"
SetCurrentDirectory(AppPath)

; Logging
#LOG_MAX_BYTES = 524288 ; size-rotate within a day
#LOG_MAX_SEGMENTS_PER_DAY = 20
#LOG_RETENTION_DAYS = 14
#LOG_THROTTLE_MS = 5000

Global LogCurrentDate.s = ""
Global NewMap LogLastTime.i()

Declare LogLine(message.s, key.s = "")

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
Define actualStartup.i = #True
If CountProgramParameters() > 0
  If LCase(ProgramParameter(0)) = "--installstartup" Or LCase(ProgramParameter(0)) = "--removestartup"
    actualStartup = #False
  EndIf
EndIf

hMutex = CreateMutex_(0, actualStartup, #APP_NAME + "_mutex")
If actualStartup And hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  LogLine("Already running; exiting.", "single_instance")
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Structure DISK_PERFORMANCE
  BytesRead.q
  BytesWritten.q
  ReadTime.q
  WriteTime.q
  IdleTime.q
  ReadCount.l
  WriteCount.l
  QueueDepth.l
  SplitCount.l
  QueryTime.q
  StorageDeviceNumber.l
  StorageManagerName.w[8]
EndStructure

Global Dim HDAvailableSpace.q(0)
Global Dim HDCapacity.q(0)
Global Dim HDFreeSpace.q(0)
Global hdh, IdIcon1, IdIcon2, IdIcon3, IdIcon4
Global StartupEnabled.i

; Runtime-configurable settings (loaded from INI)
Global UpdateIntervalMs.i = #UPDATE_INTERVAL
Global TooltipUpdateIntervalMs.i = #TOOLTIP_UPDATE_INTERVAL
Global ActivityThresholdBps.d = #ACTIVITY_THRESHOLD_BYTES_PER_SEC
Global ActivityHoldMs.i = #ACTIVITY_HOLD_MS
Global PdhSampleIntervalMs.i = #PDH_SAMPLE_INTERVAL_MS
Global IoctlBackoffCycles.i = #IOCTL_BACKOFF_CYCLES
Global StartWithRandomIconSet.i = 1
Global DefaultIconSet.i = 1
Global ForcePdhOnlyDefault.i = 0

; PDH fallback (used when IOCTL_DISK_PERFORMANCE is unsupported)
Prototype.l PdhOpenQueryW(szDataSource.i, dwUserData.i, *phQuery)
Prototype.l PdhAddCounterW(hQuery.i, szFullCounterPath.i, dwUserData.i, *phCounter)

; WNet (UNC share enumeration)
CompilerIf Not Defined(RESOURCE_CONNECTED, #PB_Constant)
  #RESOURCE_CONNECTED = 1
CompilerEndIf
CompilerIf Not Defined(RESOURCE_REMEMBERED, #PB_Constant)
  #RESOURCE_REMEMBERED = 3
CompilerEndIf
CompilerIf Not Defined(RESOURCETYPE_DISK, #PB_Constant)
  #RESOURCETYPE_DISK = 1
CompilerEndIf
CompilerIf Not Defined(NO_ERROR, #PB_Constant)
  #NO_ERROR = 0
CompilerEndIf
CompilerIf Not Defined(ERROR_NO_MORE_ITEMS, #PB_Constant)
  #ERROR_NO_MORE_ITEMS = 259
CompilerEndIf
CompilerIf Not Defined(ERROR_MORE_DATA, #PB_Constant)
  #ERROR_MORE_DATA = 234
CompilerEndIf
CompilerIf Not Defined(ERROR_INSUFFICIENT_BUFFER, #PB_Constant)
  #ERROR_INSUFFICIENT_BUFFER = 122
CompilerEndIf

CompilerIf Not Defined(NETRESOURCE, #PB_Structure)
  Structure NETRESOURCE
    dwScope.l
    dwType.l
    dwDisplayType.l
    dwUsage.l
    lpLocalName.i
    lpRemoteName.i
    lpComment.i
    lpProvider.i
  EndStructure
CompilerEndIf

Prototype.l WNetOpenEnumW(dwScope.l, dwType.l, dwUsage.l, *lpNetResource, *lphEnum)
Prototype.l WNetEnumResourceW(hEnum.i, *lpcCount, *lpBuffer, *lpBufferSize)
Prototype.l WNetCloseEnum(hEnum.i)
Prototype.l PdhAddEnglishCounterW(hQuery.i, szFullCounterPath.i, dwUserData.i, *phCounter)
Prototype.l PdhCollectQueryData(hQuery.i)
Prototype.l PdhFormatErrorW(pdhStatus.l, *buffer, bufferSize.l)

Structure PDH_FMT_COUNTERVALUE_DOUBLE
  CStatus.l
  Padding.l
  DoubleValue.d
EndStructure
Prototype.l PdhGetFormattedCounterValue(hCounter.i, dwFormat.l, *lpdwType, *pValue)
Prototype.l PdhCloseQuery(hQuery.i)

Global PdhLib.i
Global PdhQuery.i
Global PdhReadCounter.i
Global PdhWriteCounter.i
Global PdhPrimed.i
Global UsePdh.i
Global PdhInitStatus.l
Global PdhInitStage.s
Global PdhCounterSource.s
Global PdhLastCollectStatus.l
Global PdhLastReadStatus.l
Global PdhLastWriteStatus.l
Global PdhOpenQueryW.PdhOpenQueryW
Global PdhAddCounterW.PdhAddCounterW
Global PdhAddEnglishCounterW.PdhAddEnglishCounterW
Global PdhCollectQueryData.PdhCollectQueryData
Global PdhGetFormattedCounterValue.PdhGetFormattedCounterValue
Global PdhCloseQuery.PdhCloseQuery
Global PdhFormatErrorW.PdhFormatErrorW

Global MprLib.i
Global WNetOpenEnumW.WNetOpenEnumW
Global WNetEnumResourceW.WNetEnumResourceW
Global WNetCloseEnum.WNetCloseEnum

Procedure EnsureMprInitialized()
  If MprLib
    ProcedureReturn #True
  EndIf

  MprLib = OpenLibrary(#PB_Any, "mpr.dll")
  If MprLib = 0
    ProcedureReturn #False
  EndIf

  WNetOpenEnumW = GetFunction(MprLib, "WNetOpenEnumW")
  WNetEnumResourceW = GetFunction(MprLib, "WNetEnumResourceW")
  WNetCloseEnum = GetFunction(MprLib, "WNetCloseEnum")

  If Not (WNetOpenEnumW And WNetEnumResourceW And WNetCloseEnum)
    CloseLibrary(MprLib)
    MprLib = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure
 
 
Procedure GetDiskFreeSpace(drive$)
  ; Ensure callers never see stale values if the API fails
  HDAvailableSpace(0) = 0
  HDCapacity(0) = 0
  HDFreeSpace(0) = 0

  SetErrorMode_(#SEM_FAILCRITICALERRORS)
  If GetDiskFreeSpaceEx_(@drive$, HDAvailableSpace(), HDCapacity(), HDFreeSpace()) = 0
    LogLine("GetDiskFreeSpaceEx failed for " + drive$ + " GetLastError=" + Str(GetLastError_()), "diskfree_" + UCase(Left(drive$, 2)))
  EndIf
  SetErrorMode_(0)
EndProcedure

; Improved icon loading with error checking
Procedure LoadIconSet(iconSetNumber.i)
  Protected iconlib.s = "IconLibs\" + #APP_NAME + "." + iconSetNumber + ".icl"
  
  ; Check if icon library exists
  If FileSize(iconlib) = -1
    MessageRequester("Error", "Icon library " + iconlib + " not found!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  
  ; Free any previous icons to avoid leaking handles
  If IdIcon1 : DestroyIcon_(IdIcon1) : IdIcon1 = 0 : EndIf
  If IdIcon2 : DestroyIcon_(IdIcon2) : IdIcon2 = 0 : EndIf
  If IdIcon3 : DestroyIcon_(IdIcon3) : IdIcon3 = 0 : EndIf
  If IdIcon4 : DestroyIcon_(IdIcon4) : IdIcon4 = 0 : EndIf

  ; Load icons
  IdIcon1 = ExtractIcon_(0, iconlib, 0) ; write
  IdIcon2 = ExtractIcon_(0, iconlib, 1) ; read
  IdIcon3 = ExtractIcon_(0, iconlib, 2) ; read+write/system
  IdIcon4 = ExtractIcon_(0, iconlib, 3) ; idle
  
  ; Verify icons loaded successfully
  If IdIcon1 = 0 Or IdIcon2 = 0 Or IdIcon3 = 0 Or IdIcon4 = 0
    MessageRequester("Error", "Failed to load icons from " + iconlib, #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

; Count available icon libraries
Procedure CountIconLibraries()
  Protected count.i = 0
  
  If ExamineDirectory(0, "IconLibs\", "*.icl")
    While NextDirectoryEntry(0)
      count + 1
    Wend
    FinishDirectory(0)
  EndIf
  
  If count = 0 : count = 1 : EndIf
ProcedureReturn count
EndProcedure

Procedure ClampI(value.i, minValue.i, maxValue.i)
  If value < minValue : ProcedureReturn minValue : EndIf
  If value > maxValue : ProcedureReturn maxValue : EndIf
  ProcedureReturn value
EndProcedure

Procedure.d ClampD(value.d, minValue.d, maxValue.d)
  If value < minValue : ProcedureReturn minValue : EndIf
  If value > maxValue : ProcedureReturn maxValue : EndIf
  ProcedureReturn value
EndProcedure

Declare.s FormatRate(bytesPerSec.d)

Procedure SaveSettings()
  If CreatePreferences(IniPath)
    PreferenceComment("HandyDrvLED settings")

    PreferenceGroup("General")
    WritePreferenceInteger("UpdateIntervalMs", UpdateIntervalMs)
    WritePreferenceInteger("TooltipUpdateIntervalMs", TooltipUpdateIntervalMs)
    WritePreferenceInteger("StartWithRandomIconSet", StartWithRandomIconSet)
    WritePreferenceInteger("DefaultIconSet", DefaultIconSet)

    PreferenceGroup("Detection")
    WritePreferenceString("ActivityThresholdBps", StrD(ActivityThresholdBps, 0))
    WritePreferenceInteger("ActivityHoldMs", ActivityHoldMs)
    WritePreferenceInteger("PdhSampleIntervalMs", PdhSampleIntervalMs)
    WritePreferenceInteger("IoctlBackoffCycles", IoctlBackoffCycles)
    WritePreferenceInteger("ForcePdhOnly", ForcePdhOnlyDefault)

    ClosePreferences()
  EndIf
EndProcedure

Procedure.s SettingsSummary()
  Protected s.s
  s = "INI: " + IniPath + #CRLF$ +
      "UpdateIntervalMs: " + Str(UpdateIntervalMs) + #CRLF$ +
      "TooltipUpdateIntervalMs: " + Str(TooltipUpdateIntervalMs) + #CRLF$ +
      "ActivityThresholdBps: " + StrD(ActivityThresholdBps, 0) + " (" + FormatRate(ActivityThresholdBps) + ")" + #CRLF$ +
      "ActivityHoldMs: " + Str(ActivityHoldMs) + #CRLF$ +
      "PdhSampleIntervalMs: " + Str(PdhSampleIntervalMs) + #CRLF$ +
      "IoctlBackoffCycles: " + Str(IoctlBackoffCycles) + #CRLF$ +
      "StartWithRandomIconSet: " + Str(StartWithRandomIconSet) + #CRLF$ +
      "DefaultIconSet: " + Str(DefaultIconSet) + #CRLF$ +
      "ForcePdhOnly: " + Str(ForcePdhOnlyDefault)
  ProcedureReturn s
EndProcedure

Procedure EditSettings()
  Protected changed.i = #False

  Protected newUpdateInterval.s
  Protected newTooltipInterval.s
  Protected newThreshold.s
  Protected newHoldMs.s
  Protected newPdhSample.s
  Protected newIoctlBackoff.s
  Protected newStartRandom.s
  Protected newDefaultIconSet.s
  Protected newForcePdhOnly.s

  ; UpdateIntervalMs
  newUpdateInterval = InputRequester("Edit Settings", "UpdateIntervalMs (10..2000) (current: " + Str(UpdateIntervalMs) + "):", Str(UpdateIntervalMs))
  If newUpdateInterval <> ""
    Protected vUpdate.i = ClampI(Val(newUpdateInterval), 10, 2000)
    If vUpdate <> UpdateIntervalMs
      UpdateIntervalMs = vUpdate
      changed = #True
    EndIf
  EndIf

  ; TooltipUpdateIntervalMs
  newTooltipInterval = InputRequester("Edit Settings", "TooltipUpdateIntervalMs (250..30000) (current: " + Str(TooltipUpdateIntervalMs) + "):", Str(TooltipUpdateIntervalMs))
  If newTooltipInterval <> ""
    Protected vTip.i = ClampI(Val(newTooltipInterval), 250, 30000)
    If vTip <> TooltipUpdateIntervalMs
      TooltipUpdateIntervalMs = vTip
      changed = #True
    EndIf
  EndIf

  ; ActivityThresholdBps
  newThreshold = InputRequester("Edit Settings", "ActivityThresholdBps (0..1GB/s) (current: " + StrD(ActivityThresholdBps, 0) + "):", StrD(ActivityThresholdBps, 0))
  If newThreshold <> ""
    Protected vThresh.d = ClampD(ValD(newThreshold), 0.0, 1024.0 * 1024.0 * 1024.0)
    If vThresh <> ActivityThresholdBps
      ActivityThresholdBps = vThresh
      changed = #True
    EndIf
  EndIf

  ; ActivityHoldMs
  newHoldMs = InputRequester("Edit Settings", "ActivityHoldMs (0..5000) (current: " + Str(ActivityHoldMs) + "):", Str(ActivityHoldMs))
  If newHoldMs <> ""
    Protected vHold.i = ClampI(Val(newHoldMs), 0, 5000)
    If vHold <> ActivityHoldMs
      ActivityHoldMs = vHold
      changed = #True
    EndIf
  EndIf

  ; PdhSampleIntervalMs
  newPdhSample = InputRequester("Edit Settings", "PdhSampleIntervalMs (50..5000) (current: " + Str(PdhSampleIntervalMs) + "):", Str(PdhSampleIntervalMs))
  If newPdhSample <> ""
    Protected vPdh.i = ClampI(Val(newPdhSample), 50, 5000)
    If vPdh <> PdhSampleIntervalMs
      PdhSampleIntervalMs = vPdh
      changed = #True
    EndIf
  EndIf

  ; IoctlBackoffCycles
  newIoctlBackoff = InputRequester("Edit Settings", "IoctlBackoffCycles (0..1000) (current: " + Str(IoctlBackoffCycles) + "):", Str(IoctlBackoffCycles))
  If newIoctlBackoff <> ""
    Protected vIoctl.i = ClampI(Val(newIoctlBackoff), 0, 1000)
    If vIoctl <> IoctlBackoffCycles
      IoctlBackoffCycles = vIoctl
      changed = #True
    EndIf
  EndIf

  ; StartWithRandomIconSet
  newStartRandom = InputRequester("Edit Settings", "StartWithRandomIconSet (0/1) (current: " + Str(StartWithRandomIconSet) + "):", Str(StartWithRandomIconSet))
  If newStartRandom <> ""
    Protected vRand.i = Val(newStartRandom)
    If vRand = 0 Or vRand = 1
      If vRand <> StartWithRandomIconSet
        StartWithRandomIconSet = vRand
        changed = #True
      EndIf
    EndIf
  EndIf

  ; DefaultIconSet
  newDefaultIconSet = InputRequester("Edit Settings", "DefaultIconSet (>=1) (current: " + Str(DefaultIconSet) + "):", Str(DefaultIconSet))
  If newDefaultIconSet <> "" And Val(newDefaultIconSet) > 0
    Protected vDef.i = Val(newDefaultIconSet)
    If vDef < 1 : vDef = 1 : EndIf
    If vDef <> DefaultIconSet
      DefaultIconSet = vDef
      changed = #True
    EndIf
  EndIf

  ; ForcePdhOnlyDefault
  newForcePdhOnly = InputRequester("Edit Settings", "ForcePdhOnly (0/1) (current: " + Str(ForcePdhOnlyDefault) + "):", Str(ForcePdhOnlyDefault))
  If newForcePdhOnly <> ""
    Protected vForce.i = Val(newForcePdhOnly)
    If vForce = 0 Or vForce = 1
      If vForce <> ForcePdhOnlyDefault
        ForcePdhOnlyDefault = vForce
        changed = #True
      EndIf
    EndIf
  EndIf

  If changed
    SaveSettings()
    MessageRequester("Settings Saved", "Settings have been saved successfully.", #PB_MessageRequester_Info)
  EndIf
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(IniPath)
    PreferenceGroup("General")
    UpdateIntervalMs = ReadPreferenceInteger("UpdateIntervalMs", UpdateIntervalMs)
    TooltipUpdateIntervalMs = ReadPreferenceInteger("TooltipUpdateIntervalMs", TooltipUpdateIntervalMs)
    StartWithRandomIconSet = ReadPreferenceInteger("StartWithRandomIconSet", StartWithRandomIconSet)
    DefaultIconSet = ReadPreferenceInteger("DefaultIconSet", DefaultIconSet)

    PreferenceGroup("Detection")
    ActivityThresholdBps = ValD(ReadPreferenceString("ActivityThresholdBps", StrD(ActivityThresholdBps, 0)))
    ActivityHoldMs = ReadPreferenceInteger("ActivityHoldMs", ActivityHoldMs)
    PdhSampleIntervalMs = ReadPreferenceInteger("PdhSampleIntervalMs", PdhSampleIntervalMs)
    IoctlBackoffCycles = ReadPreferenceInteger("IoctlBackoffCycles", IoctlBackoffCycles)
    ForcePdhOnlyDefault = ReadPreferenceInteger("ForcePdhOnly", ForcePdhOnlyDefault)

    ClosePreferences()
  Else
    ; Create the INI with defaults on first run
    SaveSettings()
  EndIf

  ; Basic sanity clamps
  UpdateIntervalMs = ClampI(UpdateIntervalMs, 10, 2000)
  TooltipUpdateIntervalMs = ClampI(TooltipUpdateIntervalMs, 250, 30000)
  ActivityHoldMs = ClampI(ActivityHoldMs, 0, 5000)
  PdhSampleIntervalMs = ClampI(PdhSampleIntervalMs, 50, 5000)
  IoctlBackoffCycles = ClampI(IoctlBackoffCycles, 0, 1000)
  ActivityThresholdBps = ClampD(ActivityThresholdBps, 0.0, 1024.0 * 1024.0 * 1024.0)

  If DefaultIconSet < 1 : DefaultIconSet = 1 : EndIf
EndProcedure

; PDH fallback helpers
Procedure PurgeOldDailyLogs()
  Protected cutoff.i = Date() - (#LOG_RETENTION_DAYS * 24 * 60 * 60)
  Protected dir.i
  Protected name.s
  Protected rest.s
  Protected logPos.i
  Protected head.s
  Protected dateStr.s
  Protected year.i, month.i, day.i
  Protected fileDate.i
  Protected ok.i

  ; Delete dated logs older than retention:
  ;   HandyDrvLED.YYYY-MM-DD.log
  ;   HandyDrvLED.YYYY-MM-DD.log.N
  ;   HandyDrvLED.legacy.YYYY-MM-DD.log(.N)
  dir = ExamineDirectory(#PB_Any, AppPath, #APP_NAME + ".*.log*")
  If dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
      name = DirectoryEntryName(dir)
      If Left(name, Len(#APP_NAME) + 1) = #APP_NAME + "."
        rest = Mid(name, Len(#APP_NAME) + 2)
        logPos = FindString(rest, ".log", 1)
        If logPos > 0
          head = Left(rest, logPos - 1)

          dateStr = ""
          If Left(head, 7) = "legacy." And Len(head) >= 17
            dateStr = Mid(head, 8, 10)
          ElseIf Len(head) >= 10
            dateStr = Left(head, 10)
          EndIf

          ok = #False
          If Len(dateStr) = 10 And Mid(dateStr, 5, 1) = "-" And Mid(dateStr, 8, 1) = "-"
            ok = #True
            ; YYYYMMDD digits
            If FindString("0123456789", Mid(dateStr, 1, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 2, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 3, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 4, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 6, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 7, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 9, 1), 1) = 0 : ok = #False : EndIf
            If FindString("0123456789", Mid(dateStr, 10, 1), 1) = 0 : ok = #False : EndIf
          EndIf

          If ok
            year = Val(Left(dateStr, 4))
            month = Val(Mid(dateStr, 6, 2))
            day = Val(Right(dateStr, 2))
            If year > 0 And month >= 1 And month <= 12 And day >= 1 And day <= 31
              fileDate = Date(year, month, day, 0, 0, 0)
              If fileDate < cutoff
                DeleteFile(AppPath + name)
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure EnsureDailyLog()
  Protected today.s = FormatDate("[%yy-%mm-%dd]", Date())
  Protected target.s
  Protected legacy.s
  Protected legacyTarget.s
  Protected idx.i

  If LogCurrentDate = today And LogPath <> ""
    ProcedureReturn
  EndIf

  LogCurrentDate = today
  target = LogBase + "." + today + ".log"

  ; Migrate legacy single-file log (from older versions) once.
  legacy = LogBase + ".log"
  If legacy <> target And FileSize(legacy) >= 0
    legacyTarget = LogBase + ".legacy." + today + ".log"
    idx = 1
    While FileSize(legacyTarget) >= 0
      idx + 1
      legacyTarget = LogBase + ".legacy." + today + ".log." + Str(idx)
    Wend
    RenameFile(legacy, legacyTarget)
  EndIf

  LogPath = target
  PurgeOldDailyLogs()
EndProcedure

Procedure RotateLogsIfNeeded()
  Protected seg.i
  Protected sTo.s

  EnsureDailyLog()

  If FileSize(LogPath) < #LOG_MAX_BYTES Or FileSize(LogPath) = -1
    ProcedureReturn
  EndIf

  ; Size-rotate inside the same day: .log -> .log.1 -> .log.2 ...
  ; If we hit the maximum segment count, keep the newest and drop the oldest.
  If FileSize(LogPath + "." + Str(#LOG_MAX_SEGMENTS_PER_DAY)) >= 0
    DeleteFile(LogPath + "." + Str(#LOG_MAX_SEGMENTS_PER_DAY))
  EndIf

  For seg = #LOG_MAX_SEGMENTS_PER_DAY - 1 To 1 Step -1
    If FileSize(LogPath + "." + Str(seg)) >= 0
      CopyFile(LogPath + "." + Str(seg), LogPath + "." + Str(seg + 1))
      DeleteFile(LogPath + "." + Str(seg))
    EndIf
  Next

  sTo = LogPath + ".1"
  CopyFile(LogPath, sTo)
  DeleteFile(LogPath)
EndProcedure

Procedure LogLine(message.s, key.s = "")
  Protected k.s = key
  Protected now.i = ElapsedMilliseconds()
  Protected stamp.s
  Protected fh.i

  If k = "" : k = message : EndIf

  If FindMapElement(LogLastTime(), k)
    If now - LogLastTime() < #LOG_THROTTLE_MS
      ProcedureReturn
    EndIf
  EndIf

  LogLastTime(k) = now

  EnsureDailyLog()
  RotateLogsIfNeeded()

  stamp = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date())
  fh = OpenFile(#PB_Any, LogPath)
  If fh
    FileSeek(fh, Lof(fh))
    WriteStringN(fh, stamp + " | " + message)
    CloseFile(fh)
  EndIf
EndProcedure

Procedure.s FormatPdhError(status.l)
  Protected buf.s
  If status = 0
    ProcedureReturn "SUCCESS"
  EndIf

  ; PDH error codes are not standard Win32 GetLastError codes.
  If PdhFormatErrorW
    buf = Space(512)
    If PdhFormatErrorW(status, @buf, 512) = 0
      buf = Trim(buf)
      If buf <> ""
        ProcedureReturn buf + " (0x" + Hex(status & $FFFFFFFF) + ")"
      EndIf
    EndIf
  EndIf

  ProcedureReturn "0x" + Hex(status & $FFFFFFFF)
EndProcedure

Procedure.s FormatRate(bytesPerSec.d)
  Protected value.d = bytesPerSec
  Protected unit.s = "B/s"

  If value >= 10240
    value = value / 1024.0
    unit = "KB/s"
    If value >= 10240
      value = value / 1024.0
      unit = "MB/s"
      If value >= 10240
        value = value / 1024.0
        unit = "GB/s"
      EndIf
    EndIf
  EndIf

  ; No decimals for B/s, 1 decimal for KB/MB
  If unit = "B/s"
    ProcedureReturn StrD(value, 0) + " " + unit
  Else
    ProcedureReturn StrD(value, 1) + " " + unit
  EndIf
EndProcedure

Procedure EnsurePdhInitialized()
  Protected status.l

  If UsePdh
    ProcedureReturn #True
  EndIf

  PdhInitStatus = 0
  PdhInitStage = ""
  PdhCounterSource = ""
  PdhLastCollectStatus = 0
  PdhLastReadStatus = 0
  PdhLastWriteStatus = 0

  PdhLib = OpenLibrary(#PB_Any, "pdh.dll")
  If PdhLib = 0
    PdhInitStage = "OpenLibrary(pdh.dll)"
    PdhInitStatus = -1
    PdhCounterSource = "pdh.dll missing"
    LogLine("PDH init failed at " + PdhInitStage + " status=" + Str(PdhInitStatus) + " source=" + PdhCounterSource, "pdh_init")
    ProcedureReturn #False
  EndIf

  PdhOpenQueryW = GetFunction(PdhLib, "PdhOpenQueryW")
  PdhAddCounterW = GetFunction(PdhLib, "PdhAddCounterW")
  PdhAddEnglishCounterW = GetFunction(PdhLib, "PdhAddEnglishCounterW")
  PdhCollectQueryData = GetFunction(PdhLib, "PdhCollectQueryData")
  PdhGetFormattedCounterValue = GetFunction(PdhLib, "PdhGetFormattedCounterValue")
  PdhCloseQuery = GetFunction(PdhLib, "PdhCloseQuery")
  PdhFormatErrorW = GetFunction(PdhLib, "PdhFormatErrorW")

  If Not (PdhOpenQueryW And PdhCollectQueryData And PdhGetFormattedCounterValue And PdhCloseQuery)
    PdhInitStage = "GetFunction(pdh exports)"
    PdhInitStatus = -2
    PdhCounterSource = "pdh exports missing"
    LogLine("PDH init failed at " + PdhInitStage + " status=" + Str(PdhInitStatus) + " source=" + PdhCounterSource, "pdh_init")
    CloseLibrary(PdhLib)
    PdhLib = 0
    ProcedureReturn #False
  EndIf

  PdhInitStage = "PdhOpenQueryW"
  status = PdhOpenQueryW(0, 0, @PdhQuery)
  If status <> 0
    PdhInitStatus = status
    LogLine("PDH init failed at " + PdhInitStage + " status=" + FormatPdhError(PdhInitStatus), "pdh_init")
    CloseLibrary(PdhLib)
    PdhLib = 0
    PdhQuery = 0
    ProcedureReturn #False
  EndIf

  ; Try PhysicalDisk(_Total) first, then LogicalDisk(_Total) as fallback.
  ; Prefer English counter names (works on localized Windows too).
  status = -1

  If PdhAddEnglishCounterW
    PdhInitStage = "PdhAddEnglishCounterW(Read)"
    status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
    PdhCounterSource = "PhysicalDisk(_Total)"
    If status = 0
      PdhInitStage = "PdhAddEnglishCounterW(Write)"
      status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
    EndIf

    If status <> 0
      PdhInitStage = "PdhAddEnglishCounterW(Read)"
      status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
      PdhCounterSource = "LogicalDisk(_Total)"
      If status = 0
        PdhInitStage = "PdhAddEnglishCounterW(Write)"
        status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
      EndIf
    EndIf
  Else
    PdhInitStage = "PdhAddCounterW(Read)"
    status = PdhAddCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
    PdhCounterSource = "PhysicalDisk(_Total)"
    If status = 0
      PdhInitStage = "PdhAddCounterW(Write)"
      status = PdhAddCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
    EndIf

    If status <> 0
      PdhInitStage = "PdhAddCounterW(Read)"
      status = PdhAddCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
      PdhCounterSource = "LogicalDisk(_Total)"
      If status = 0
        PdhInitStage = "PdhAddCounterW(Write)"
        status = PdhAddCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
      EndIf
    EndIf
  EndIf

  If status <> 0
    PdhInitStatus = status
    LogLine("PDH init failed at " + PdhInitStage + " status=" + FormatPdhError(PdhInitStatus) + " source=" + PdhCounterSource, "pdh_init")
    PdhCloseQuery(PdhQuery)
    PdhQuery = 0
    CloseLibrary(PdhLib)
    PdhLib = 0
    ProcedureReturn #False
  EndIf

  ; Prime the counters
  PdhInitStage = "PdhCollectQueryData(prime)"
  status = PdhCollectQueryData(PdhQuery)
  If status <> 0
    PdhInitStatus = status
    LogLine("PDH init failed at " + PdhInitStage + " status=" + FormatPdhError(PdhInitStatus) + " source=" + PdhCounterSource, "pdh_init")
    PdhCloseQuery(PdhQuery)
    PdhQuery = 0
    CloseLibrary(PdhLib)
    PdhLib = 0
    ProcedureReturn #False
  EndIf

  PdhPrimed = 1
  UsePdh = 1
  ProcedureReturn #True
EndProcedure

Procedure PdhReadWriteActivity(*ReadBytesPerSec, *WriteBytesPerSec)
  Protected status.l
  Protected counterValue.PDH_FMT_COUNTERVALUE_DOUBLE

  If Not UsePdh Or PdhQuery = 0
    ProcedureReturn #False
  EndIf

  status = PdhCollectQueryData(PdhQuery)
  PdhLastCollectStatus = status
  If status <> 0
    LogLine("PDH collect failed: " + FormatPdhError(status), "pdh_collect")
    PokeD(*ReadBytesPerSec, 0.0)
    PokeD(*WriteBytesPerSec, 0.0)
    ProcedureReturn #False
  EndIf

  status = PdhGetFormattedCounterValue(PdhReadCounter, #PDH_FMT_DOUBLE, 0, @counterValue)
  PdhLastReadStatus = status
  If status = 0
    PokeD(*ReadBytesPerSec, counterValue\DoubleValue)
  Else
    LogLine("PDH read format failed: " + FormatPdhError(status), "pdh_read")
    PokeD(*ReadBytesPerSec, 0.0)
  EndIf

  status = PdhGetFormattedCounterValue(PdhWriteCounter, #PDH_FMT_DOUBLE, 0, @counterValue)
  PdhLastWriteStatus = status
  If status = 0
    PokeD(*WriteBytesPerSec, counterValue\DoubleValue)
  Else
    LogLine("PDH write format failed: " + FormatPdhError(status), "pdh_write")
    PokeD(*WriteBytesPerSec, 0.0)
  EndIf

  ProcedureReturn #True
EndProcedure

; --- Task Scheduler startup helpers (mirrors ClearRam fixes) ---

#TOKEN_QUERY = $0008
#TokenElevation = 20

Structure TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

Declare.i IsInStartup()
Declare.i InstallStartupTask(userSamOverride.s = "")
Declare.i AddToStartup(targetUserSam.s = "")
Declare.i RemoveFromStartup()

Procedure.s QuoteArgument(text.s)
  Protected q.s = Chr(34)
  If FindString(text, q, 1)
    text = ReplaceString(text, q, "\\" + q)
  EndIf
  ProcedureReturn q + text + q
EndProcedure

Procedure.s PsEscapeSingleQuotes(text.s)
  ; PowerShell single-quoted string escape
  ProcedureReturn ReplaceString(text, "'", "''")
EndProcedure

Procedure.s GetEnvVar(name.s)
  Protected buf.s = Space(512)
  Protected rc.l

  rc = GetEnvironmentVariable_(@name, @buf, 512)
  If rc > 0
    ProcedureReturn Left(buf, rc)
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s CurrentUserSam()
  Protected user.s = Trim(GetEnvVar("USERNAME"))
  Protected domain.s = Trim(GetEnvVar("USERDOMAIN"))

  If user = ""
    ProcedureReturn ""
  EndIf

  If domain <> ""
    ProcedureReturn domain + "\\" + user
  EndIf

  ProcedureReturn user
EndProcedure

Procedure.s StartupInstallPowerShellArgs(userSamOverride.s = "")
  Protected taskName.s = #STARTUP_TASK_NAME
  Protected exePath.s = ProgramFilename()
  Protected workDir.s = GetPathPart(exePath)
  Protected userSam.s = Trim(userSamOverride)

  If userSam = ""
    userSam = CurrentUserSam()
  EndIf

  If userSam = ""
    LogLine("Unable to resolve current user (USERNAME/USERDOMAIN).", "startup_ps")
    ProcedureReturn ""
  EndIf

  ; Match ClearRam.pb behavior: Register-ScheduledTask with Interactive logon
  ; so the tray icon starts after the user logs on.
  Protected psTaskName.s = PsEscapeSingleQuotes(taskName)
  Protected psExe.s = PsEscapeSingleQuotes(exePath)
  Protected psWorkDir.s = PsEscapeSingleQuotes(workDir)
  Protected psUser.s = PsEscapeSingleQuotes(userSam)

  Protected psCmd.s
  psCmd = "try {" +
          " $ErrorActionPreference='Stop';" +
          " $taskName='" + psTaskName + "';" +
          " $exe='" + psExe + "';" +
          " $wd='" + psWorkDir + "';" +
          " $user='" + psUser + "';" +
          " if ($user -eq '') { throw 'Unable to determine user for scheduled task.' };" +
          " $action=New-ScheduledTaskAction -Execute $exe -WorkingDirectory $wd;" +
          " $trigger=New-ScheduledTaskTrigger -AtLogOn -User $user;" +
          " $trigger.Delay='PT1M';" +
          " $settings=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew;" +
          " $principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest;" +
          " Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null;" +
          " Write-Output ('OK: task created/updated: ' + $taskName);" +
          "} catch {" +
          " Write-Output ('ERROR: ' + $_.Exception.Message);" +
          " if ($_.ScriptStackTrace) { Write-Output $_.ScriptStackTrace };" +
          " exit 1" +
          "}"

  ProcedureReturn "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + psCmd + Chr(34)
EndProcedure


Procedure.i IsProcessElevated()
  Protected hToken.i
  Protected elev.TOKEN_ELEVATION
  Protected cb.l

  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken) = 0
    ProcedureReturn #False
  EndIf

  cb = SizeOf(TOKEN_ELEVATION)
  If GetTokenInformation_(hToken, #TokenElevation, @elev, cb, @cb) = 0
    CloseHandle_(hToken)
    ProcedureReturn #False
  EndIf

  CloseHandle_(hToken)
  ProcedureReturn Bool(elev\TokenIsElevated)
EndProcedure

Procedure.i RelaunchSelfElevated(extraArgs.s)
  Protected params.s = Trim(extraArgs)
  If params <> "" : params = " " + params : EndIf

  LogLine("RelaunchSelfElevated: " + ProgramFilename() + params, "startup_elevate")
  ShellExecute_(0, "runas", ProgramFilename(), params, "", #SW_SHOWNORMAL)
  ProcedureReturn #True
EndProcedure

Procedure.s FindCmdArgValue(name.s)
  Protected i.i
  Protected key.s = LCase(name)

  For i = 0 To CountProgramParameters() - 1
    If LCase(ProgramParameter(i)) = key
      If i + 1 <= CountProgramParameters() - 1
        ProcedureReturn ProgramParameter(i + 1)
      EndIf
      ProcedureReturn ""
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure.i RunAndCapture(exe.s, args.s)
  Protected out.s
  Protected program.i
  Protected exitCode.i = -1
  Protected stamp.s = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date())
  Protected runKey.s = "run_" + LCase(exe) + "_" + stamp
  Protected exitKey.s = "exit_" + LCase(exe) + "_" + stamp
  Protected outKey.s = "out_" + LCase(exe) + "_" + stamp

  LogLine("RUN: " + exe + " " + args, runKey)

  ; Avoid cmd.exe wrapper (faster) and capture both stdout+stderr.
  program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
  If program = 0
    LogLine("RunProgram failed for: " + exe + " GetLastError=" + Str(GetLastError_()), "run_fail")
    ProcedureReturn -1
  EndIf

  While ProgramRunning(program)
    While AvailableProgramOutput(program)
      out + ReadProgramString(program) + #CRLF$
    Wend
    While AvailableProgramOutput(program)
      out + ReadProgramString(program, #PB_Program_Error) + #CRLF$
    Wend
    Delay(5)
  Wend

  ; Drain remaining output
  While AvailableProgramOutput(program)
    out + ReadProgramString(program) + #CRLF$
  Wend
  While AvailableProgramOutput(program)
    out + ReadProgramString(program, #PB_Program_Error) + #CRLF$
  Wend

  exitCode = ProgramExitCode(program)
  CloseProgram(program)

  LogLine("EXITCODE: " + Str(exitCode), exitKey)
  If Trim(out) <> ""
    LogLine("OUTPUT: " + ReplaceString(Trim(out), #CRLF$, " | "), outKey)
  Else
    LogLine("OUTPUT: (none)", outKey)
  EndIf

  ProcedureReturn exitCode
EndProcedure

Procedure.i InstallStartupTask(userSamOverride.s = "")
  Protected psArgs.s = StartupInstallPowerShellArgs(userSamOverride)
  If psArgs = ""
    ProcedureReturn #False
  EndIf

  Protected rc.i = RunAndCapture("powershell.exe", psArgs)
  ProcedureReturn Bool(rc = 0)
EndProcedure

Procedure.s StartupRemoveSchTasksArgs()
  Protected tn.s = #STARTUP_TASK_NAME
  ProcedureReturn "/Delete /F /TN " + QuoteArgument(tn)
EndProcedure

Procedure.i AddToStartup(targetUserSam.s = "")
  Protected userSam.s = Trim(targetUserSam)
  If userSam = ""
    userSam = CurrentUserSam()
  EndIf

  If Not IsProcessElevated()
    ; Pass the original user through UAC so the elevated helper creates
    ; the task for the interactive user, not the admin account.
    RelaunchSelfElevated("--installstartup --user " + QuoteArgument(userSam))
    ProcedureReturn #True
  EndIf

  If IsInStartup()
    LogLine("Startup task already present.", "startup_install")
  EndIf

  ProcedureReturn InstallStartupTask(userSam)
EndProcedure

Procedure.i RemoveFromStartup()
  If Not IsProcessElevated()
    RelaunchSelfElevated("--removestartup")
    ProcedureReturn #True
  EndIf

  Protected args.s = StartupRemoveSchTasksArgs()
  Protected rc.i = RunAndCapture("schtasks.exe", args)
  ProcedureReturn Bool(rc = 0)
EndProcedure

Procedure.i IsInStartup()
  ; Fast check via schtasks query (non-zero if missing)
  Protected tn.s = #STARTUP_TASK_NAME

  Protected args.s = "/Query /TN " + QuoteArgument(tn)
  Protected rc.i = RunAndCapture("schtasks.exe", args)

  ProcedureReturn Bool(rc = 0)
EndProcedure

; Create physical drive handle (shared read/write access)
Procedure OpenPhysDrive(CurrentDrive.l)
  Protected access.l = #GENERIC_READ
  Protected share.l = #FILE_SHARE_READ | #FILE_SHARE_WRITE

  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive), access, share, 0, #OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

; Cleanup procedure
Procedure Cleanup()
  If hdh And hdh <> #INVALID_HANDLE_VALUE
    CloseHandle_(hdh)
  EndIf

  If PdhQuery And PdhCloseQuery
    PdhCloseQuery(PdhQuery)
    PdhQuery = 0
  EndIf
    If PdhLib
      CloseLibrary(PdhLib)
      PdhLib = 0
    EndIf

    If MprLib
      CloseLibrary(MprLib)
      MprLib = 0
    EndIf

  If IdIcon1 : DestroyIcon_(IdIcon1) : EndIf
  If IdIcon2 : DestroyIcon_(IdIcon2) : EndIf
  If IdIcon3 : DestroyIcon_(IdIcon3) : EndIf
  If IdIcon4 : DestroyIcon_(IdIcon4) : EndIf

  If hMutex
    CloseHandle_(hMutex)
  EndIf

  RemoveSysTrayIcon(1)
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    Cleanup()
    End
  EndIf
EndProcedure

; Help procedure
Procedure Help()
  Protected helpText.s

  helpText = #APP_NAME + " Help" + #CRLF$ +
             "Tray icon:" + #CRLF$ +
             "  - Right-click the tray icon for options." + #CRLF$ +
             "  - Colors: RED=Write, GREEN=Read, BLUE=Read+Write, YELLOW=Idle" + #CRLF$ +
             "Disk activity detection:" + #CRLF$ +
             "  - Uses IOCTL_DISK_PERFORMANCE when available." + #CRLF$ +
             "  - Automatically falls back to PDH counters if IOCTL is unsupported." + #CRLF$ +
             "  - If IOCTL fails with error 122, IOCTL is disabled for the remainder of the session." + #CRLF$ +
             "Tray menu options:" + #CRLF$ +
             "  - About: version/contact info." + #CRLF$ +
             "  - Help: this window." + #CRLF$ +
             "  - Drive(s): open the drive/share browser window." + #CRLF$ +
             "  - Diagnostics: shows IOCTL/PDH status and last errors." + #CRLF$ +
             "  - Reload settings: re-reads HandyDrvLED.ini and applies changes." + #CRLF$ +
             "  - Edit settings: edit values (writes INI)." + #CRLF$ +
              "  - Start with Windows: toggles auto-start (Task Scheduler)." + #CRLF$ +
             "  - Use PDH only: forces PDH counters and skips IOCTL." + #CRLF$ +
             "  - Exit: quit the program." + #CRLF$ +
             "Drive(s) window:" + #CRLF$ +
             "  - Shows drive letters with label + filesystem (ex: C:\ (Label) [NTFS])." + #CRLF$ +
             "  - Filters: Fixed, Removable, Network, CDROM, RAMDisk." + #CRLF$ +
             "  - Network includes mapped drives and UNC shares (\\server\\share) when available." + #CRLF$ +
             "  - Open: opens the selected root in Explorer." + #CRLF$ +
             "  - Info: shows volume + size/free info (UNC shares show only the path)." + #CRLF$ +
             "  - Copy: copies the displayed info text (or the UNC path for shares)." + #CRLF$ +
             "Settings + logs:" + #CRLF$ +
             "  - Config file: HandyDrvLED.ini (same folder as the EXE)." + #CRLF$ +
             "  - Logs are written next to the EXE and rotate daily (with size-based segments)." + #CRLF$ +
             "HandyDrvLED.ini keys:" + #CRLF$ +
             "  [General]" + #CRLF$ +
             "    UpdateIntervalMs (10..2000): main loop delay." + #CRLF$ +
             "    TooltipUpdateIntervalMs (250..30000): tooltip refresh period." + #CRLF$ +
             "    StartWithRandomIconSet (0/1): randomize icon set on start." + #CRLF$ +
             "    DefaultIconSet (>=1): icon set when random is off." + #CRLF$ +
             "  [Detection]" + #CRLF$ +
             "    ActivityThresholdBps (0..1GB/s): bytes/sec threshold for PDH activity." + #CRLF$ +
             "    ActivityHoldMs (0..5000): hold activity indicator this long." + #CRLF$ +
             "    PdhSampleIntervalMs (50..5000): PDH sampling cadence." + #CRLF$ +
             "    IoctlBackoffCycles (0..1000): skip IOCTL polls after PDH works." + #CRLF$ +
             "    ForcePdhOnly (0/1): start in PDH-only mode."

  MessageRequester("Help", helpText, #PB_MessageRequester_Info)
EndProcedure

; Build drive information text
Procedure.s DriveInfoText(lpRootPathName.s)
  Protected info.s
  Protected pVolumeNameBuffer.s = Space(256)
  Protected lpVolumeSerialNumber.l
  Protected lpMaximumComponentLength.l
  Protected lpFileSystemFlags.l
  Protected lpFileSystemNameBuffer.s = Space(256)
  Protected root.s = lpRootPathName
  Protected okVol.i

  If Right(root, 1) <> "\" : root + "\" : EndIf

  SetErrorMode_(#SEM_FAILCRITICALERRORS)
  okVol = GetVolumeInformation_(root, pVolumeNameBuffer, 256, @lpVolumeSerialNumber, @lpMaximumComponentLength, @lpFileSystemFlags, lpFileSystemNameBuffer, 256)
  If Not okVol
    LogLine("GetVolumeInformation failed for " + root + " GetLastError=" + Str(GetLastError_()), "volinfo_" + UCase(Left(root, 2)))
  EndIf
  SetErrorMode_(0)

  GetDiskFreeSpace(root)

  If HDCapacity(0) > 0
    info + "Capacity: " + Str(HDCapacity(0)/1024/1024/1024) + " GB" + #CRLF$
    info + "Used: " + Str((HDCapacity(0)-HDFreeSpace(0))/1024/1024/1024) + " GB" + #CRLF$
    info + "Free: " + Str(HDFreeSpace(0)/1024/1024/1024) + " GB" + #CRLF$
  Else
    info + "Capacity: (unavailable)" + #CRLF$
    info + "Used: (unavailable)" + #CRLF$
    info + "Free: (unavailable)" + #CRLF$
  EndIf

  If okVol
    info + "VolumeName: " + Trim(pVolumeNameBuffer) + #CRLF$
    info + "VolumeID: " + Hex(lpVolumeSerialNumber) + #CRLF$
    info + "FileSystem: " + Trim(lpFileSystemNameBuffer)
  Else
    info + "VolumeName: (unavailable)" + #CRLF$
    info + "VolumeID: (unavailable)" + #CRLF$
    info + "FileSystem: (unavailable)"
  EndIf

  ProcedureReturn info
EndProcedure

Procedure.s DriveDisplayText(root.s)
  Protected volName.s = Space(256)
  Protected fsName.s = Space(256)
  Protected serial.l, maxComp.l, flags.l
  Protected okVol.i
  Protected display.s
  Protected normRoot.s = root

  If normRoot = "" : ProcedureReturn "" : EndIf

  ; UNC shares: display as \server\share
  If Left(normRoot, 2) = "\\"
    ProcedureReturn normRoot
  EndIf

  If Right(normRoot, 1) <> "\" : normRoot + "\" : EndIf

  display = UCase(Left(normRoot, 3))

  SetErrorMode_(#SEM_FAILCRITICALERRORS)
  okVol = GetVolumeInformation_(normRoot, volName, 256, @serial, @maxComp, @flags, fsName, 256)
  If Not okVol
    LogLine("GetVolumeInformation failed for " + normRoot + " GetLastError=" + Str(GetLastError_()), "volinfo_" + UCase(Left(normRoot, 2)))
  EndIf
  SetErrorMode_(0)

  If okVol
    If Trim(volName) <> ""
      display + " (" + Trim(volName) + ")"
    EndIf

    If Trim(fsName) <> ""
      display + " [" + Trim(fsName) + "]"
    EndIf
  Else
    display + " (unavailable)"
  EndIf

  ProcedureReturn display
EndProcedure

Procedure.i DriveTypeAllowed(driveType.i, includeFixed.i, includeRemovable.i, includeNetwork.i, includeCdRom.i, includeRamDisk.i)
  Select driveType
    Case #DRIVE_FIXED
      ProcedureReturn includeFixed
    Case #DRIVE_REMOVABLE
      ProcedureReturn includeRemovable
    Case #DRIVE_REMOTE
      ProcedureReturn includeNetwork
    Case #DRIVE_CDROM
      ProcedureReturn includeCdRom
    Case #DRIVE_RAMDISK
      ProcedureReturn includeRamDisk
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure PopulateDriveCombo(comboId.i, selectedRoot.s, includeFixed.i, includeRemovable.i, includeNetwork.i, includeCdRom.i, includeRamDisk.i)
  Protected drv.i, itemRoot.s, display.s, selectedIndex.i = -1
  Protected wantRoot.s = selectedRoot
  Protected hEnum.i, status.l, count.l, bufSize.l
  Protected *buffer
  Protected *nr.NETRESOURCE
  Protected remote.s
  Protected item.i

  If wantRoot <> ""
    If Left(wantRoot, 2) <> "\\" And Right(wantRoot, 1) <> "\" : wantRoot + "\" : EndIf
  EndIf

  ClearGadgetItems(comboId)

  ; Drive letters (fixed/removable/mapped network/cdrom/ramdisk)
  For drv = 65 To 90
    itemRoot = Chr(drv) + ":\"
    If DriveTypeAllowed(GetDriveType_(itemRoot), includeFixed, includeRemovable, includeNetwork, includeCdRom, includeRamDisk)
      display = DriveDisplayText(itemRoot)
      If display <> ""
        AddGadgetItem(comboId, -1, display)
        If wantRoot <> "" And UCase(Left(wantRoot, 3)) = UCase(Left(itemRoot, 3))
          selectedIndex = CountGadgetItems(comboId) - 1
        EndIf
      EndIf
    EndIf
  Next

  ; UNC shares (when Network is enabled): enumerate connected/remembered disk resources
  If includeNetwork And EnsureMprInitialized()
    NewMap seenShare.i()

    For drv = 0 To 1
      If drv = 0
        status = WNetOpenEnumW(#RESOURCE_CONNECTED, #RESOURCETYPE_DISK, 0, 0, @hEnum)
      Else
        status = WNetOpenEnumW(#RESOURCE_REMEMBERED, #RESOURCETYPE_DISK, 0, 0, @hEnum)
      EndIf

      If status = #NO_ERROR And hEnum
        bufSize = 16384
        *buffer = AllocateMemory(bufSize)
        If *buffer
          Repeat
            count = -1
            FillMemory(*buffer, bufSize, 0)
            status = WNetEnumResourceW(hEnum, @count, *buffer, @bufSize)

            If status = #ERROR_MORE_DATA
              FreeMemory(*buffer)
              *buffer = AllocateMemory(bufSize)
              If *buffer = 0
                status = -1
              EndIf
            EndIf

            If status <> #NO_ERROR
              Continue
            EndIf

            If status = #NO_ERROR
              For item = 0 To count - 1
                *nr = *buffer + (item * SizeOf(NETRESOURCE))
                If *nr\lpRemoteName
                  remote = PeekS(*nr\lpRemoteName)
                  If remote <> "" And Left(remote, 2) = "\\"
                    If Not FindMapElement(seenShare(), LCase(remote))
                      seenShare(LCase(remote)) = 1
                      AddGadgetItem(comboId, -1, remote)

                      If wantRoot <> "" And Left(wantRoot, 2) = "\\" And LCase(wantRoot) = LCase(remote)
                        selectedIndex = CountGadgetItems(comboId) - 1
                      EndIf
                    EndIf
                  EndIf
                EndIf
              Next
            EndIf

          Until status <> #NO_ERROR

          FreeMemory(*buffer)
        EndIf

        WNetCloseEnum(hEnum)
      EndIf
    Next
  EndIf

  If selectedIndex >= 0
    SetGadgetState(comboId, selectedIndex)
  ElseIf CountGadgetItems(comboId) > 0
    SetGadgetState(comboId, 0)
  EndIf
EndProcedure

Procedure.s SelectedRootFromCombo(comboId.i)
  Protected t.s = GetGadgetText(comboId)

  If Left(t, 2) = "\\"
    ProcedureReturn t
  EndIf

  If Len(t) >= 3
    ProcedureReturn UCase(Left(t, 3))
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure ShowDriveInfo(root.s)
  If Left(root, 2) = "\\"
    MessageRequester("Network Share", root, #PB_MessageRequester_Info)
  Else
    MessageRequester("DriveInfo For " + root, DriveInfoText(root), #PB_MessageRequester_Info)
  EndIf
EndProcedure

Procedure.s FirstFixedDriveRoot()
  Protected drv.i, root.s
  For drv = 65 To 90
    root = Chr(drv) + ":\"
    If GetDriveType_(root) = #DRIVE_FIXED
      ProcedureReturn root
    EndIf
  Next
  ProcedureReturn "C:\"
EndProcedure

Procedure DrivesWindow(selectedRoot.s)
  Protected w.i, root.s = selectedRoot
  Protected includeFixed.i = #True
  Protected includeRemovable.i = #False
  Protected includeNetwork.i = #False
  Protected includeCdRom.i = #False
  Protected includeRamDisk.i = #False
  Protected ev.i, gid.i

  If root = "" : root = FirstFixedDriveRoot() : EndIf

  w = OpenWindow(#PB_Any, 0, 0, 520, 345, "Drive(s)", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  ComboBoxGadget(1, 10, 10, 300, 25)
  ButtonGadget(2, 320, 10, 60, 25, "Open")
  ButtonGadget(3, 385, 10, 60, 25, "Info")
  ButtonGadget(6, 450, 10, 60, 25, "Copy")

  CheckBoxGadget(9, 10, 40, 90, 20, "Fixed")
  SetGadgetState(9, includeFixed)
  CheckBoxGadget(7, 110, 40, 110, 20, "Removable")
  CheckBoxGadget(8, 230, 40, 90, 20, "Network")
  CheckBoxGadget(10, 330, 40, 80, 20, "CDROM")
  CheckBoxGadget(11, 415, 40, 95, 20, "RAMDisk")

  EditorGadget(4, 10, 65, 500, 240, #PB_Editor_ReadOnly)
  ButtonGadget(5, 420, 310, 90, 25, "Close")

  ; Populate drives
  PopulateDriveCombo(1, root, includeFixed, includeRemovable, includeNetwork, includeCdRom, includeRamDisk)

  ; Show initial info
  root = SelectedRootFromCombo(1)
  If root <> ""
    If Left(root, 2) = "\\"
      SetGadgetText(4, "Network share: " + root)
    Else
      SetGadgetText(4, DriveInfoText(root))
    EndIf
  Else
    SetGadgetText(4, "")
  EndIf

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        Exit()

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case 1 ; combobox change
            root = SelectedRootFromCombo(1)
            If root <> ""
              If Left(root, 2) = "\\"
                SetGadgetText(4, "Network share: " + root)
              Else
                SetGadgetText(4, DriveInfoText(root))
              EndIf
            Else
              SetGadgetText(4, "")
            EndIf

          Case 2 ; Open
            root = SelectedRootFromCombo(1)
            If root <> "" : ShellExecute_(0, "open", root, "", "", #SW_SHOWNORMAL) : EndIf

          Case 3 ; Info
            root = SelectedRootFromCombo(1)
            If root <> "" : ShowDriveInfo(root) : EndIf

          Case 6 ; Copy
            root = SelectedRootFromCombo(1)
            If root <> ""
              If Left(root, 2) = "\\"
                SetClipboardText(root)
              ElseIf GetGadgetText(4) <> ""
                SetClipboardText(GetGadgetText(4))
              Else
                SetClipboardText(DriveInfoText(root))
              EndIf
            EndIf

          Case 7, 8, 9, 10, 11 ; filter toggles
            includeFixed = Bool(GetGadgetState(9))
            includeRemovable = Bool(GetGadgetState(7))
            includeNetwork = Bool(GetGadgetState(8))
            includeCdRom = Bool(GetGadgetState(10))
            includeRamDisk = Bool(GetGadgetState(11))
            root = SelectedRootFromCombo(1)
            PopulateDriveCombo(1, root, includeFixed, includeRemovable, includeNetwork, includeCdRom, includeRamDisk)
            root = SelectedRootFromCombo(1)
            If root <> ""
              If Left(root, 2) = "\\"
                SetGadgetText(4, "Network share: " + root)
              Else
                SetGadgetText(4, DriveInfoText(root))
              EndIf
            Else
              SetGadgetText(4, "")
            EndIf

          Case 5 ; Close
            Exit()
            
        EndSelect
    EndSelect
  ForEver

  CloseWindow(w)
EndProcedure

; Display about dialog
Procedure About(icon1.i)
  MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                            "Thank you for using this free tool!" + #CRLF$ +
                            "-----------------------------------" + #CRLF$ +
                            "Contact: " + #EMAIL_NAME + #CRLF$ +
                            "Website: https://github.com/zonemaster60" + #CRLF$ +
                            "Startup enabled: " + Str(StartupEnabled) + #CRLF$ +
                            "Using Custom IconSet: " + Str(icon1), #PB_MessageRequester_Info)
EndProcedure

; Main program starts here
Define drv.i
Define drv$
Define numicl.i = 0
Define mTime.f
Define icon1.i
Define dp.DISK_PERFORMANCE
Define Window_Form1.i
Define EventID.i, Result.i, lBytesReturned.l
Define OldReadCount.l, OldWriteCount.l
Define OldBytesRead.q, OldBytesWritten.q
Define TimeOut.i, Count_Read.l, Count_Write.l
Define ErrorTimeOut.i
Define LastIoctlError.l
Define ForcePdhOnly.i = 0
Define DisableIoctlSession.i = 0
Define IoctlBackoff.i = 0
Define Exit.i = 0
Define Req.i
Define ReadDetected.i, WriteDetected.i
Define readBps.d, writeBps.d
Define NextPdhSample.i = 0
Define HoldReadUntil.i = 0
Define HoldWriteUntil.i = 0

LoadSettings()

; Helper-modes for startup task management
If CountProgramParameters() > 0
  Select LCase(ProgramParameter(0))
    Case "--installstartup"
      Define targetUser.s = FindCmdArgValue("--user")
      If AddToStartup(targetUser)
        LogLine("Startup task installed/updated.", "startup_helper")
      Else
        LogLine("Startup task install failed.", "startup_helper")
      EndIf
      End

    Case "--removestartup"
      If RemoveFromStartup()
        LogLine("Startup task removed.", "startup_helper")
      Else
        LogLine("Startup task remove failed.", "startup_helper")
      EndIf
      End
  EndSelect
EndIf

mTime = TooltipUpdateIntervalMs

; Count available icon libraries
numicl = CountIconLibraries()

; Select icon set (random by default)
If StartWithRandomIconSet
  icon1 = Random(numicl, 1)
Else
  icon1 = DefaultIconSet
EndIf
icon1 = ClampI(icon1, 1, numicl)

ForcePdhOnly = Bool(ForcePdhOnlyDefault)

; Load initial icon set
If Not LoadIconSet(icon1)
  LogLine("Failed to load initial icon set; icon1=" + Str(icon1))
  MessageRequester("Error", "Failed to load initial icon set!", #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

; Checks if there is a physical disk in the system
If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
  LogLine("OpenPhysDrive(0) failed; GetLastError=" + Str(GetLastError_()), "open_phys_drive")
  MessageRequester("Error", "Unable to open drive!", #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

; Create main window (invisible)
Window_Form1 = OpenWindow(0, 80, 80, 100, 100, #APP_NAME, #PB_Window_Invisible)

; Create the menu pop-up
CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Help")
MenuBar()
MenuItem(3, "Drive(s)")
MenuItem(8, "Diagnostics")
MenuItem(10, "Reload settings")
MenuItem(11, "Edit settings")
MenuBar()
MenuItem(7, "Start with Windows")
MenuItem(9, "Use PDH only")
MenuBar()
MenuItem(6, "Exit")

; Add the items to the system tray
AddSysTrayIcon(1, WindowID(0), IdIcon3)
SysTrayIconToolTip(1, #APP_NAME + " " + version)

StartupEnabled = IsInStartup()
SetMenuItemState(0, 7, StartupEnabled)
SetMenuItemState(0, 9, ForcePdhOnly)

Delay(mTime/2)

; Main program loop
Repeat
  EventID = WaitWindowEvent(10)

  ; Handle system tray events
  If EventID = #PB_Event_SysTray
    Select EventType()
      Case #PB_EventType_RightClick
        DisplayPopupMenu(0, WindowID(0))
    EndSelect
  EndIf

  ; Handle menu events
  If EventID = #PB_Event_Menu
    Select EventMenu()
      Case 1 ; About
        About(icon1)

      Case 2 ; Help
        Help()

      Case 3 ; Explore
        DrivesWindow("")

       Case 7 ; Start with Windows
         StartupEnabled ! 1

          If StartupEnabled
            Result = AddToStartup(CurrentUserSam())
          Else
            Result = RemoveFromStartup()
          EndIf


         If Result

           SetMenuItemState(0, 7, StartupEnabled)
           SysTrayIconToolTip(1, #APP_NAME + " " + version + " | Startup: " + Str(StartupEnabled))
         Else
           StartupEnabled = IsInStartup()
           SetMenuItemState(0, 7, StartupEnabled)
           LogLine("Startup task change failed; taskPresent=" + Str(StartupEnabled), "startup_toggle")
           MessageRequester("Error", "Unable to change startup setting.", #PB_MessageRequester_Error)
         EndIf


      Case 8 ; Diagnostics
        MessageRequester("Diagnostics", "IOCTL GetLastError(): " + Str(LastIoctlError) + #CRLF$ +
                                     "Disable IOCTL session: " + Str(DisableIoctlSession) + #CRLF$ +
                                     "Force PDH only: " + Str(ForcePdhOnly) + #CRLF$ +
                                     "PDH init stage: " + PdhInitStage + #CRLF$ +
                                     "PDH init status: " + FormatPdhError(PdhInitStatus) + #CRLF$ +
                                     "PDH source: " + PdhCounterSource + #CRLF$ +
                                     "UsePdh: " + Str(UsePdh) + #CRLF$ +
                                     "PDH query: " + Str(PdhQuery) + #CRLF$ +
                                     "PDH collect: " + FormatPdhError(PdhLastCollectStatus) + #CRLF$ +
                                     "PDH read: " + FormatPdhError(PdhLastReadStatus) + #CRLF$ +
                                     "PDH write: " + FormatPdhError(PdhLastWriteStatus), #PB_MessageRequester_Info)

      Case 10 ; Reload settings
        LoadSettings()
        mTime = TooltipUpdateIntervalMs

        ; Apply settings that map to current UI state.
        ForcePdhOnly = Bool(ForcePdhOnlyDefault)
        SetMenuItemState(0, 9, ForcePdhOnly)
        If ForcePdhOnly
          LogLine("Mode set via reload: PDH only", "mode_change")
        Else
          LogLine("Mode set via reload: Auto", "mode_change")
        EndIf

        ; Reset timers so changes take effect immediately.
        DisableIoctlSession = 0
        IoctlBackoff = 0
        LastIoctlError = 0
        NextPdhSample = 0
        HoldReadUntil = 0
        HoldWriteUntil = 0

        ; Optionally apply icon set choice immediately.
        If StartWithRandomIconSet
          icon1 = Random(numicl, 1)
        Else
          icon1 = DefaultIconSet
        EndIf
        icon1 = ClampI(icon1, 1, numicl)
        LoadIconSet(icon1)

        ; Tray tooltips are length-limited; keep this very short.
        SysTrayIconToolTip(1, "Cfg reloaded")
        MessageRequester("Settings", SettingsSummary(), #PB_MessageRequester_Info)

      Case 11 ; Edit settings
        EditSettings()

      Case 9 ; Use PDH only
        ForcePdhOnly ! 1
        ForcePdhOnlyDefault = ForcePdhOnly
        SaveSettings()
        SetMenuItemState(0, 9, ForcePdhOnly)

        ; Reset state so behavior changes immediately.
        DisableIoctlSession = 0
        IoctlBackoff = 0
        LastIoctlError = 0
        NextPdhSample = 0
        HoldReadUntil = 0
        HoldWriteUntil = 0

        If ForcePdhOnly
          LogLine("Mode toggled: PDH only", "mode_change")
        Else
          LogLine("Mode toggled: Auto", "mode_change")
        EndIf

        If ForcePdhOnly
          SysTrayIconToolTip(1, #APP_NAME + " " + version + " | Mode: PDH only")
        Else
          SysTrayIconToolTip(1, #APP_NAME + " " + version + " | Mode: Auto")
        EndIf

      Case 6 ; Exit
        Exit()
    EndSelect
  EndIf

  ; Handle window close event
  If EventID = #PB_Event_CloseWindow
    Exit = 1
  EndIf

  ; On systems where IOCTL_DISK_PERFORMANCE is unsupported, prefer PDH (or allow forcing PDH only).
  If ForcePdhOnly Or DisableIoctlSession
    Result = 0
    LastIoctlError = 0
  ElseIf UsePdh And IoctlBackoff > 0
    IoctlBackoff - 1
    Result = 0
  Else
    ; Poll disk statistics (can fail on some systems/drivers)
    Result = DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)
  EndIf

  If Result = 0
    If Not (ForcePdhOnly Or DisableIoctlSession) And (Not UsePdh Or IoctlBackoff = 0)
      LastIoctlError = GetLastError_()
      If LastIoctlError = #ERROR_INSUFFICIENT_BUFFER
        DisableIoctlSession = 1
        ; Use a shared key so rapid mode changes can't interleave-spam different IOCTL messages.
        LogLine("IOCTL_DISK_PERFORMANCE failed (122 ERROR_INSUFFICIENT_BUFFER); disabling IOCTL for this session.", "ioctl_fail")
      Else
        LogLine("IOCTL_DISK_PERFORMANCE failed; GetLastError=" + Str(LastIoctlError), "ioctl_fail")
      EndIf
    EndIf


    ; Fallback to PDH counters on Win11/storage stacks where IOCTL is unsupported.
    If DisableIoctlSession Or Not UsePdh
      UsePdh = EnsurePdhInitialized()
      If Not UsePdh
        LogLine("PDH init unavailable; stage=" + PdhInitStage + " status=" + FormatPdhError(PdhInitStatus) + " source=" + PdhCounterSource, "pdh_init")
      EndIf
    EndIf


    If UsePdh
      ; Once PDH works, back off IOCTL calls (it can be expensive/noisy on some stacks).
      If Not ForcePdhOnly
        IoctlBackoff = IoctlBackoffCycles
      EndIf

      ; PDH values update on an interval; sample at a stable cadence and
      ; hold the "LED" briefly so short bursts are visible.
      If ElapsedMilliseconds() >= NextPdhSample
        NextPdhSample = ElapsedMilliseconds() + PdhSampleIntervalMs

        If PdhReadWriteActivity(@readBps, @writeBps)
          If readBps >= ActivityThresholdBps
            HoldReadUntil = ElapsedMilliseconds() + ActivityHoldMs
          EndIf
          If writeBps >= ActivityThresholdBps
            HoldWriteUntil = ElapsedMilliseconds() + ActivityHoldMs
          EndIf

          ReadDetected  = Bool(ElapsedMilliseconds() < HoldReadUntil)
          WriteDetected = Bool(ElapsedMilliseconds() < HoldWriteUntil)

          If ReadDetected And WriteDetected
            ChangeSysTrayIcon(1, IdIcon3)
          ElseIf WriteDetected
            ChangeSysTrayIcon(1, IdIcon1)
          ElseIf ReadDetected
            ChangeSysTrayIcon(1, IdIcon2)
          Else
            ChangeSysTrayIcon(1, IdIcon4)
          EndIf

          If ElapsedMilliseconds() > TimeOut
       If TimeOut
         SysTrayIconToolTip(1, "Read: " + FormatRate(readBps) + " | Write: " + FormatRate(writeBps) + " | Startup: " + Str(StartupEnabled) + " | IS: " + Str(icon1))
       EndIf

            TimeOut = ElapsedMilliseconds() + mTime
          EndIf
        EndIf
      EndIf
    Else
      ; PDH failed too
      If Not ForcePdhOnly
        LastIoctlError = GetLastError_()
      EndIf
      LogLine("IO activity read failed. IOCTL=" + Str(LastIoctlError) + " PDH=" + FormatPdhError(PdhInitStatus) + " stage=" + PdhInitStage + " source=" + PdhCounterSource, "io_activity_failed")

      ChangeSysTrayIcon(1, IdIcon4) ; idle (yellow)
      If ElapsedMilliseconds() > ErrorTimeOut
        SysTrayIconToolTip(1, "IOCTL=" + Str(LastIoctlError) + " PDH=" + FormatPdhError(PdhInitStatus))
        ErrorTimeOut = ElapsedMilliseconds() + mTime
      EndIf
    EndIf
  Else
    ; Detect if the counters increased since last poll
    ReadDetected  = Bool(dp\ReadCount  <> OldReadCount Or dp\BytesRead     <> OldBytesRead)
    WriteDetected = Bool(dp\WriteCount <> OldWriteCount Or dp\BytesWritten <> OldBytesWritten)

    OldReadCount = dp\ReadCount
    OldWriteCount = dp\WriteCount
    OldBytesRead = dp\BytesRead
    OldBytesWritten = dp\BytesWritten

    ; Update icon based on activity
    If ReadDetected And WriteDetected
      ChangeSysTrayIcon(1, IdIcon3) ; both (blue)
    ElseIf WriteDetected
      ChangeSysTrayIcon(1, IdIcon1) ; write (red)
    ElseIf ReadDetected
      ChangeSysTrayIcon(1, IdIcon2) ; read (green)
    Else
      ChangeSysTrayIcon(1, IdIcon4) ; idle (yellow)
    EndIf

    ; Update tooltip with statistics
    If ElapsedMilliseconds() > TimeOut
      If TimeOut
        SysTrayIconToolTip(1, "RC/s: " + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + " MB) | WC/s: " + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + " MB) | Startup:" + Str(StartupEnabled) + " | IS:" + Str(icon1))
      EndIf
      Count_Read = dp\ReadCount
      Count_Write = dp\WriteCount
      TimeOut = ElapsedMilliseconds() + mTime
    EndIf
  EndIf

  Delay(UpdateIntervalMs)

Until Exit = 1

; Cleanup before exit
Cleanup()
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 45
; FirstLine = 27
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyDrvLED.ico
; Executable = ..\HandyDrvLED.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,3,0
; VersionField1 = 1,0,3,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyDrvLED
; VersionField4 = 1.0.3.0
; VersionField5 = 1.0.3.0
; VersionField6 = Monitors your disk read / write access
; VersionField7 = HandyDrvLED
; VersionField8 = HandyDrvLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60