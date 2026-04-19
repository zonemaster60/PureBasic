; HandyDrvLED Globals & Constants

#APP_NAME = "HandyDrvLED"
Global version.s = "v1.0.3.7"
#EMAIL_NAME = "zonemaster60@gmail.com"

#IOCTL_DISK_PERFORMANCE = $70020
#UPDATE_INTERVAL = 100
#TOOLTIP_UPDATE_INTERVAL = 2500
#ACTIVITY_THRESHOLD_BYTES_PER_SEC = 4096
#ACTIVITY_HOLD_MS = 300
#PDH_SAMPLE_INTERVAL_MS = 200
#IOCTL_BACKOFF_CYCLES = 50
#PDH_FMT_DOUBLE = $00000200
#STARTUP_TASK_NAME = "HandyDrvLED"

; Windows constants
CompilerIf Not Defined(GENERIC_READ, #PB_Constant)
  #GENERIC_READ = $80000000
CompilerEndIf
CompilerIf Not Defined(FILE_SHARE_READ, #PB_Constant)
  #FILE_SHARE_READ = 1
CompilerEndIf
CompilerIf Not Defined(FILE_SHARE_WRITE, #PB_Constant)
  #FILE_SHARE_WRITE = 2
CompilerEndIf

; Logging Constants
#LOG_FILE = "HandyDrvLED.log"
#LOG_THROTTLE_MS = 5000

Enumeration Windows
  #Window_Main
  #Window_Drives
EndEnumeration

Enumeration Menus
  #Menu_Main
EndEnumeration

Enumeration MenuItems
  #MenuItem_About = 1
  #MenuItem_Help
  #MenuItem_Drives
  #MenuItem_Exit = 6
  #MenuItem_Startup
  #MenuItem_LogToggle
  #MenuItem_Diagnostics
  #MenuItem_ForcePdh
  #MenuItem_Reload
  #MenuItem_Edit
EndEnumeration

Enumeration Gadgets
  #Gadget_Drives_Combo = 1
  #Gadget_Drives_Open
  #Gadget_Drives_Info
  #Gadget_Drives_Editor
  #Gadget_Drives_Close
  #Gadget_Drives_Copy
  #Gadget_Drives_Removable
  #Gadget_Drives_Network
  #Gadget_Drives_Fixed
  #Gadget_Drives_CdRom
  #Gadget_Drives_RamDisk
EndEnumeration

; Custom Events for Thread Communication
Enumeration #PB_Event_FirstCustomValue
  #Event_UpdateTrayIcon
  #Event_UpdateTooltip
EndEnumeration

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

Structure PDH_FMT_COUNTERVALUE_DOUBLE
  CStatus.l
  Padding.l
  DoubleValue.d
EndStructure

#TOKEN_QUERY = $0008
#TokenElevation = 20

Structure TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

; Global Variables
Global AppPath.s = GetPathPart(ProgramFilename())
Global IniPath.s = AppPath + "files\" + #APP_NAME + ".ini"
Global IconLibDir.s = AppPath + "IconLibs\"
Global LogDir.s = ""
Global LogBase.s = ""
Global LogPath.s = ""
Global LogCurrentDate.s = ""
Global LoggingEnabled.i = #True
Global LogRotateEnabled.i = #True
Global LogRotateMaxBytes.q = 1024 * 1024
Global LogRotateKeep.i = 3
Global NewMap LogLastTime.i()

Global hMutex.i, hdh, IdIcon1, IdIcon2, IdIcon3, IdIcon4
Global StartupEnabled.i, numicl.i, icon1.i
Global UpdateIntervalMs.i = #UPDATE_INTERVAL
Global TooltipUpdateIntervalMs.i = #TOOLTIP_UPDATE_INTERVAL
Global ActivityThresholdBps.d = #ACTIVITY_THRESHOLD_BYTES_PER_SEC
Global ActivityHoldMs.i = #ACTIVITY_HOLD_MS
Global PdhSampleIntervalMs.i = #PDH_SAMPLE_INTERVAL_MS
Global IoctlBackoffCycles.i = #IOCTL_BACKOFF_CYCLES
Global StartWithRandomIconSet.i = 1
Global DefaultIconSet.i = 1
Global ForcePdhOnlyDefault.i = 0

; Thread Safety
Global Mutex_DiskData = CreateMutex()
Global LogMutex = CreateMutex()
Global Thread_Monitor.i
Global QuitThread.i = #False

; Monitoring State (Shared between thread and UI)
Global CurrentIconID.i
Global CurrentTooltip.s
Global LastIoctlError.l
Global DisableIoctlSession.i
Global ForcePdhOnly.i
Global PdhInitStatus.l
Global PdhInitStage.s
Global PdhCounterSource.s
Global UsePdh.i
Global PdhQuery.i
Global PdhInitAttempted.i
Global PdhLastCollectStatus.l
Global PdhLastReadStatus.l
Global PdhLastWriteStatus.l

; Prototypes
Declare.s FormatPdhError(status.l)

Prototype.l PdhOpenQueryW(szDataSource.i, dwUserData.i, *phQuery)
Prototype.l PdhAddCounterW(hQuery.i, szFullCounterPath.i, dwUserData.i, *phCounter)
Prototype.l PdhAddEnglishCounterW(hQuery.i, szFullCounterPath.i, dwUserData.i, *phCounter)
Prototype.l PdhCollectQueryData(hQuery.i)
Prototype.l PdhFormatErrorW(pdhStatus.l, *buffer, bufferSize.l)
Prototype.l PdhGetFormattedCounterValue(hCounter.i, dwFormat.l, *lpdwType, *pValue)
Prototype.l PdhCloseQuery(hQuery.i)

Global PdhOpenQueryW.PdhOpenQueryW
Global PdhAddCounterW.PdhAddCounterW
Global PdhAddEnglishCounterW.PdhAddEnglishCounterW
Global PdhCollectQueryData.PdhCollectQueryData
Global PdhGetFormattedCounterValue.PdhGetFormattedCounterValue
Global PdhCloseQuery.PdhCloseQuery
Global PdhFormatErrorW.PdhFormatErrorW

Global PdhLib.i, PdhReadCounter.i, PdhWriteCounter.i, PdhPrimed.i

; MPR/Network
Prototype.l WNetOpenEnumW(dwScope.l, dwType.l, dwUsage.l, *lpNetResource, *lphEnum)
Prototype.l WNetEnumResourceW(hEnum.i, *lpcCount, *lpBuffer, *lpBufferSize)
Prototype.l WNetCloseEnum(hEnum.i)
Global MprLib.i
Global WNetOpenEnumW.WNetOpenEnumW
Global WNetEnumResourceW.WNetEnumResourceW
Global WNetCloseEnum.WNetCloseEnum

; Helper Procedures
Procedure.i ClampI(value.i, minValue.i, maxValue.i)
  If value < minValue : ProcedureReturn minValue : EndIf
  If value > maxValue : ProcedureReturn maxValue : EndIf
  ProcedureReturn value
EndProcedure

Procedure.d ClampD(value.d, minValue.d, maxValue.d)
  If value < minValue : ProcedureReturn minValue : EndIf
  If value > maxValue : ProcedureReturn maxValue : EndIf
  ProcedureReturn value
EndProcedure

Procedure.s EnsureTrailingBackslash(path.s)
  If path = "" : ProcedureReturn "" : EndIf
  If Right(path, 1) <> "\" And Right(path, 1) <> "/" : path + "\" : EndIf
  ProcedureReturn path
EndProcedure

Procedure EnsureParentDirectory(filePath.s)
  Protected dir.s = GetPathPart(filePath)
  If dir <> "" And FileSize(dir) <> -2
    CreateDirectory(dir)
  EndIf
EndProcedure

Procedure.s ResolveWritableLogDir()
  Protected dir.s
  Protected probe.s
  Protected fh.i

  dir = EnsureTrailingBackslash(AppPath) + "Logs\"
  If FileSize(dir) <> -2
    CreateDirectory(dir)
  EndIf

  probe = dir + ".write-test"
  fh = CreateFile(#PB_Any, probe)
  If fh
    CloseFile(fh)
    DeleteFile(probe)
    ProcedureReturn dir
  EndIf

  dir = EnsureTrailingBackslash(GetTemporaryDirectory()) + #APP_NAME + "\"
  If FileSize(dir) <> -2
    CreateDirectory(dir)
  EndIf
  ProcedureReturn dir
EndProcedure

Procedure EnsureLogTarget()
  LockMutex(Mutex_DiskData)
  If LogDir = ""
    LogDir = ResolveWritableLogDir()
    LogBase = LogDir + #APP_NAME
    LogPath = LogDir + #LOG_FILE
  ElseIf LogPath = ""
    LogPath = LogDir + #LOG_FILE
  EndIf
  UnlockMutex(Mutex_DiskData)
EndProcedure

Procedure UpdateStartupMenuLabel()
  If StartupEnabled
    SetMenuItemText(#Menu_Main, #MenuItem_Startup, Lng\StartupDisable)
  Else
    SetMenuItemText(#Menu_Main, #MenuItem_Startup, Lng\StartupEnable)
  EndIf
EndProcedure

Procedure UpdateLogMenuLabel()
  If LoggingEnabled
    SetMenuItemText(#Menu_Main, #MenuItem_LogToggle, Lng\LoggingDisable)
  Else
    SetMenuItemText(#Menu_Main, #MenuItem_LogToggle, Lng\LoggingEnable)
  EndIf
EndProcedure

Procedure.s EnabledStateText(value.i)
  If value
    ProcedureReturn Lng\Enabled
  EndIf

  ProcedureReturn Lng\Disabled
EndProcedure

Procedure.s FormatKeepAndMaxKb(keepFiles.i, maxKb.q)
  ProcedureReturn Lng\KeepLabel + "=" + Str(keepFiles) + " " + Lng\MaxKbLabel + "=" + Str(maxKb)
EndProcedure

Procedure.s BuildAboutText(iconSet.i)
  Protected logState.s = EnabledStateText(LoggingEnabled)
  Protected rotateState.s = EnabledStateText(LogRotateEnabled)

  ProcedureReturn #APP_NAME + " - " + version + #CRLF$ +
                  Lng\AboutUpdateInterval + ": " + Str(UpdateIntervalMs) + " ms" + #CRLF$ +
                  Lng\AboutPdhFallbackDefault + ": " + Str(ForcePdhOnlyDefault) + #CRLF$ +
                  Lng\Logging + ": " + logState + #CRLF$ +
                  Lng\AboutLogRotation + ": " + rotateState + " " + FormatKeepAndMaxKb(LogRotateKeep, LogRotateMaxBytes / 1024) + #CRLF$ +
                  Lng\AboutIniFile + ": files\" + #APP_NAME + ".ini" + #CRLF$ +
                  Lng\Contact + ": " + #EMAIL_NAME + #CRLF$ +
                  Lng\Website + ": https://github.com/zonemaster60" + #CRLF$ +
                  Lng\UsingIconSet + ": " + Str(iconSet)
EndProcedure

Procedure.s BuildHelpText()
  ProcedureReturn #APP_NAME + " " + Lng\HelpTitle + #LF$ +
                  Lng\HelpTrayIconTitle + ":" + #LF$ +
                  "  - " + Lng\HelpTrayIconLine1 + #LF$ +
                  "  - " + Lng\HelpTrayIconLine2 + #LF$ + #LF$ +
                  Lng\HelpLoggingTitle + ":" + #LF$ +
                  "  - " + Lng\HelpLoggingLine1 + #LF$ +
                  "  - " + Lng\HelpLoggingLine2 + #LF$ +
                  "  - " + Lng\HelpLoggingLine3 + #LF$ +
                  "  - " + Lng\HelpLoggingLine4 + #LF$ + #LF$ +
                  Lng\HelpActivityTitle + ":" + #LF$ +
                  "  - " + Lng\HelpActivityLine1 + #LF$ + #LF$ +
                  Lng\HelpTrayMenuTitle + ":" + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine1 + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine2 + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine3 + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine4 + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine5 + #LF$ +
                  "  - " + Lng\HelpTrayMenuLine6 + #LF$ + #LF$ +
                  Lng\HelpDrivesTitle + ":" + #LF$ +
                  "  - " + Lng\HelpDrivesLine1 + #LF$ +
                  "  - " + Lng\HelpDrivesLine2 + #LF$ + #LF$ +
                  Lng\HelpConfigLabel + ": files\HandyDrvLED.ini"
EndProcedure

Procedure.s BuildDiagnosticsText(ioErr.l, rawDisabled.i, forceP.i, useP.i, qry.i, pdhStage.s, pdhSource.s, pdhInit.l, pdhCollect.l, pdhRead.l, pdhWrite.l, logFile.s)
  ProcedureReturn Lng\DiagIoctlLastError + ": " + Str(ioErr) + #CRLF$ +
                  Lng\DiagRawDriveDisabled + ": " + Str(rawDisabled) + #CRLF$ +
                  Lng\DiagForcePdhActive + ": " + Str(forceP) + #CRLF$ +
                  Lng\DiagPdhInitialized + ": " + Str(useP) + #CRLF$ +
                  Lng\DiagPdhQueryHandle + ": " + Str(qry) + #CRLF$ +
                  Lng\DiagPdhInitStage + ": " + pdhStage + #CRLF$ +
                  Lng\DiagPdhCounterSource + ": " + pdhSource + #CRLF$ +
                  Lng\DiagPdhInitStatus + ": " + FormatPdhError(pdhInit) + #CRLF$ +
                  Lng\DiagPdhCollectStatus + ": " + FormatPdhError(pdhCollect) + #CRLF$ +
                  Lng\DiagPdhReadStatus + ": " + FormatPdhError(pdhRead) + #CRLF$ +
                  Lng\DiagPdhWriteStatus + ": " + FormatPdhError(pdhWrite) + #CRLF$ +
                  Lng\Logging + ": " + EnabledStateText(LoggingEnabled) + #CRLF$ +
                  Lng\DiagLogFile + ": " + logFile + #CRLF$ +
                  Lng\DiagLogRotation + ": " + EnabledStateText(LogRotateEnabled) + " " + FormatKeepAndMaxKb(LogRotateKeep, LogRotateMaxBytes / 1024)
EndProcedure

Procedure LogRotateIfNeeded()
  If LoggingEnabled = #False Or LogRotateEnabled = #False
    ProcedureReturn
  EndIf

  EnsureLogTarget()
  If LogPath = ""
    ProcedureReturn
  EndIf

  If LogRotateKeep < 1 Or LogRotateMaxBytes < 1
    ProcedureReturn
  EndIf

  LockMutex(LogMutex)

  Protected size.q = FileSize(LogPath)
  If size < 0 Or size <= LogRotateMaxBytes
    UnlockMutex(LogMutex)
    ProcedureReturn
  EndIf

  Protected i.i
  Protected src.s
  Protected dst.s

  dst = LogPath + "." + Str(LogRotateKeep)
  If FileSize(dst) >= 0
    DeleteFile(dst)
  EndIf

  For i = LogRotateKeep - 1 To 1 Step -1
    src = LogPath + "." + Str(i)
    If FileSize(src) >= 0
      RenameFile(src, LogPath + "." + Str(i + 1))
    EndIf
  Next

  RenameFile(LogPath, LogPath + ".1")
  UnlockMutex(LogMutex)
EndProcedure

Procedure LogMessage(message.s)
  If LoggingEnabled = #False
    ProcedureReturn
  EndIf

  EnsureLogTarget()
  If LogPath = ""
    ProcedureReturn
  EndIf

  LogRotateIfNeeded()

  LockMutex(LogMutex)
  Protected fh.i = OpenFile(#PB_Any, LogPath, #PB_File_SharedRead | #PB_File_SharedWrite)
  If fh = 0
    fh = CreateFile(#PB_Any, LogPath)
  EndIf

  If fh
    FileSeek(fh, Lof(fh))
    WriteStringN(fh, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + message)
    CloseFile(fh)
  EndIf
  UnlockMutex(LogMutex)
EndProcedure

Procedure LogLine(message.s, key.s = "")
  Protected k.s = key : If k = "" : k = message : EndIf
  Protected now.i = ElapsedMilliseconds()

  LockMutex(Mutex_DiskData)
  If FindMapElement(LogLastTime(), k) : If now - LogLastTime() < #LOG_THROTTLE_MS : UnlockMutex(Mutex_DiskData) : ProcedureReturn : EndIf : EndIf
  LogLastTime(k) = now
  UnlockMutex(Mutex_DiskData)

  LogMessage(message)
EndProcedure

Procedure.b OpenOrCreateSettingsPreferences(iniFile.s)
  EnsureParentDirectory(iniFile)

  If FileSize(iniFile) >= 0
    If OpenPreferences(iniFile)
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn Bool(CreatePreferences(iniFile))
EndProcedure

Procedure LoadSettings()
  LoggingEnabled = #True
  LogRotateEnabled = #True
  LogRotateMaxBytes = 1024 * 1024
  LogRotateKeep = 3

  EnsureParentDirectory(IniPath)

  If OpenPreferences(IniPath)
    PreferenceGroup("General")
    UpdateIntervalMs = ReadPreferenceInteger("UpdateIntervalMs", UpdateIntervalMs)
    TooltipUpdateIntervalMs = ReadPreferenceInteger("TooltipUpdateIntervalMs", TooltipUpdateIntervalMs)
    StartWithRandomIconSet = ReadPreferenceInteger("StartWithRandomIconSet", StartWithRandomIconSet)
    DefaultIconSet = ReadPreferenceInteger("DefaultIconSet", DefaultIconSet)
    LoggingEnabled = ReadPreferenceInteger("LoggingEnabled", LoggingEnabled)
    If LoggingEnabled <> 0 And LoggingEnabled <> 1
      LoggingEnabled = #True
    EndIf
    LogRotateEnabled = ReadPreferenceInteger("LogRotateEnabled", LogRotateEnabled)
    If LogRotateEnabled <> 0 And LogRotateEnabled <> 1
      LogRotateEnabled = #True
    EndIf
    LogRotateKeep = ReadPreferenceInteger("LogRotateKeep", LogRotateKeep)
    If LogRotateKeep < 1 : LogRotateKeep = 1 : EndIf
    Protected maxKb.i = ReadPreferenceInteger("LogRotateMaxKB", LogRotateMaxBytes / 1024)
    If maxKb < 1 : maxKb = 1 : EndIf
    LogRotateMaxBytes = maxKb * 1024
    PreferenceGroup("Detection")
    ActivityThresholdBps = ValD(ReadPreferenceString("ActivityThresholdBps", StrD(ActivityThresholdBps, 0)))
    ActivityHoldMs = ReadPreferenceInteger("ActivityHoldMs", ActivityHoldMs)
    PdhSampleIntervalMs = ReadPreferenceInteger("PdhSampleIntervalMs", PdhSampleIntervalMs)
    IoctlBackoffCycles = ReadPreferenceInteger("IoctlBackoffCycles", IoctlBackoffCycles)
    ForcePdhOnlyDefault = ReadPreferenceInteger("ForcePdhOnly", ForcePdhOnlyDefault)
    ClosePreferences()
  Else
    If CreatePreferences(IniPath)
      PreferenceComment("HandyDrvLED settings")
      PreferenceGroup("General")
      WritePreferenceInteger("UpdateIntervalMs", UpdateIntervalMs)
      WritePreferenceInteger("TooltipUpdateIntervalMs", TooltipUpdateIntervalMs)
      WritePreferenceInteger("StartWithRandomIconSet", StartWithRandomIconSet)
      WritePreferenceInteger("DefaultIconSet", DefaultIconSet)
      WritePreferenceInteger("LoggingEnabled", LoggingEnabled)
      WritePreferenceInteger("LogRotateEnabled", LogRotateEnabled)
      WritePreferenceInteger("LogRotateKeep", LogRotateKeep)
      WritePreferenceInteger("LogRotateMaxKB", LogRotateMaxBytes / 1024)
      PreferenceGroup("Detection")
      WritePreferenceString("ActivityThresholdBps", StrD(ActivityThresholdBps, 0))
      WritePreferenceInteger("ActivityHoldMs", ActivityHoldMs)
      WritePreferenceInteger("PdhSampleIntervalMs", PdhSampleIntervalMs)
      WritePreferenceInteger("IoctlBackoffCycles", IoctlBackoffCycles)
      WritePreferenceInteger("ForcePdhOnly", ForcePdhOnlyDefault)
      ClosePreferences()
    EndIf
  EndIf
  ; Basic sanity clamps
  UpdateIntervalMs = ClampI(UpdateIntervalMs, 10, 2000)
  TooltipUpdateIntervalMs = ClampI(TooltipUpdateIntervalMs, 250, 30000)
  ActivityHoldMs = ClampI(ActivityHoldMs, 0, 5000)
  PdhSampleIntervalMs = ClampI(PdhSampleIntervalMs, 50, 5000)
  IoctlBackoffCycles = ClampI(IoctlBackoffCycles, 0, 1000)
  ActivityThresholdBps = ClampD(ActivityThresholdBps, 0.0, 1024.0 * 1024.0 * 1024.0)
EndProcedure

Procedure SaveSettings()
  If OpenOrCreateSettingsPreferences(IniPath)
    PreferenceComment("HandyDrvLED settings")
    PreferenceGroup("General")
    WritePreferenceInteger("UpdateIntervalMs", UpdateIntervalMs)
    WritePreferenceInteger("TooltipUpdateIntervalMs", TooltipUpdateIntervalMs)
    WritePreferenceInteger("StartWithRandomIconSet", StartWithRandomIconSet)
    WritePreferenceInteger("DefaultIconSet", DefaultIconSet)
    WritePreferenceInteger("LoggingEnabled", LoggingEnabled)
    WritePreferenceInteger("LogRotateEnabled", LogRotateEnabled)
    WritePreferenceInteger("LogRotateKeep", LogRotateKeep)
    WritePreferenceInteger("LogRotateMaxKB", LogRotateMaxBytes / 1024)
    PreferenceGroup("Detection")
    WritePreferenceString("ActivityThresholdBps", StrD(ActivityThresholdBps, 0))
    WritePreferenceInteger("ActivityHoldMs", ActivityHoldMs)
    WritePreferenceInteger("PdhSampleIntervalMs", PdhSampleIntervalMs)
    WritePreferenceInteger("IoctlBackoffCycles", IoctlBackoffCycles)
    WritePreferenceInteger("ForcePdhOnly", ForcePdhOnlyDefault)
    ClosePreferences()
  EndIf
EndProcedure

Procedure.i CountIconLibraries()
  Protected count.i = 0
  If ExamineDirectory(0, IconLibDir, "*.icl")
    While NextDirectoryEntry(0) : count + 1 : Wend
    FinishDirectory(0)
  EndIf
  If count = 0 : count = 1 : EndIf
  ProcedureReturn count
EndProcedure

Procedure.i LoadIconSet(iconSetNumber.i)
  Protected iconlib.s = IconLibDir + #APP_NAME + "." + iconSetNumber + ".icl"
  If FileSize(iconlib) = -1 : ProcedureReturn #False : EndIf
  If IdIcon1 : DestroyIcon_(IdIcon1) : EndIf
  If IdIcon2 : DestroyIcon_(IdIcon2) : EndIf
  If IdIcon3 : DestroyIcon_(IdIcon3) : EndIf
  If IdIcon4 : DestroyIcon_(IdIcon4) : EndIf
  ; Icon Index mapping: 0=Write (Red), 1=Read (Green), 2=Both (Blue), 3=Idle (Yellow)
  IdIcon1 = ExtractIcon_(0, iconlib, 0) ; Write
  IdIcon2 = ExtractIcon_(0, iconlib, 1) ; Read
  IdIcon3 = ExtractIcon_(0, iconlib, 2) ; Both
  IdIcon4 = ExtractIcon_(0, iconlib, 3) ; Idle
  ProcedureReturn Bool(IdIcon1 And IdIcon2 And IdIcon3 And IdIcon4)
EndProcedure

Procedure OpenPhysDrive(CurrentDrive.l)
  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive), #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

Procedure Cleanup()
  If hdh And hdh <> #INVALID_HANDLE_VALUE : CloseHandle_(hdh) : EndIf
  If PdhQuery And PdhCloseQuery : PdhCloseQuery(PdhQuery) : EndIf
  If PdhLib : CloseLibrary(PdhLib) : EndIf
  If MprLib : CloseLibrary(MprLib) : EndIf
  If IdIcon1 : DestroyIcon_(IdIcon1) : EndIf
  If IdIcon2 : DestroyIcon_(IdIcon2) : EndIf
  If IdIcon3 : DestroyIcon_(IdIcon3) : EndIf
  If IdIcon4 : DestroyIcon_(IdIcon4) : EndIf
  If hMutex : CloseHandle_(hMutex) : EndIf
  RemoveSysTrayIcon(1)
EndProcedure

Procedure.i Exit()
  If MessageRequester(Lng\Exit, Lng\ExitPrompt, #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
    LogMessage("Program exiting")
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.s QuoteArgument(text.s)
  Protected q.s = Chr(34)
  If FindString(text, q, 1)
    text = ReplaceString(text, q, "\\" + q)
  EndIf
  ProcedureReturn q + text + q
EndProcedure

Procedure.s PsEscapeSingleQuotes(text.s)
  ProcedureReturn ReplaceString(text, "'", "''")
EndProcedure

Procedure.s GetEnvVar(name.s)
  Protected buf.s = Space(512)
  Protected rc.l
  rc = GetEnvironmentVariable_(@name, @buf, 512)
  If rc > 0 : ProcedureReturn Left(buf, rc) : EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s CurrentUserSam()
  Protected user.s = Trim(GetEnvVar("USERNAME"))
  Protected domain.s = Trim(GetEnvVar("USERDOMAIN"))
  If user = "" : ProcedureReturn "" : EndIf
  If domain <> "" : ProcedureReturn domain + "\\" + user : EndIf
  ProcedureReturn user
EndProcedure

Procedure.i IsProcessElevated()
  Protected hToken.i, elev.TOKEN_ELEVATION, cb.l
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken) = 0 : ProcedureReturn #False : EndIf
  cb = SizeOf(TOKEN_ELEVATION)
  If GetTokenInformation_(hToken, #TokenElevation, @elev, cb, @cb) = 0
    CloseHandle_(hToken) : ProcedureReturn #False
  EndIf
  CloseHandle_(hToken)
  ProcedureReturn Bool(elev\TokenIsElevated)
EndProcedure

Procedure.i RunAndCapture(exe.s, args.s)
  Protected out.s, program.i, exitCode.i = -1
  program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
  If program = 0 : ProcedureReturn -1 : EndIf
  While ProgramRunning(program)
    While AvailableProgramOutput(program) : ReadProgramString(program) : Wend
    Delay(5)
  Wend
  exitCode = ProgramExitCode(program)
  CloseProgram(program)
  ProcedureReturn exitCode
EndProcedure

Procedure.i IsInStartup()
  Protected tn.s = #STARTUP_TASK_NAME
  Protected args.s = "/Query /TN " + QuoteArgument(tn)
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", args) = 0)
EndProcedure

Procedure.i InstallStartupTask(userSamOverride.s = "")
  Protected taskName.s = #STARTUP_TASK_NAME
  Protected exePath.s = ProgramFilename()
  Protected workDir.s = GetPathPart(exePath)
  Protected userSam.s = Trim(userSamOverride)
  If userSam = "" : userSam = CurrentUserSam() : EndIf
  If userSam = "" : ProcedureReturn #False : EndIf

  Protected psCmd.s = "Register-ScheduledTask -TaskName '" + PsEscapeSingleQuotes(taskName) + "' " +
                      "-Action (New-ScheduledTaskAction -Execute '" + PsEscapeSingleQuotes(exePath) + "' -WorkingDirectory '" + PsEscapeSingleQuotes(workDir) + "') " +
                      "-Trigger (New-ScheduledTaskTrigger -AtLogOn -User '" + PsEscapeSingleQuotes(userSam) + "') " +
                      "-Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew) " +
                      "-Principal (New-ScheduledTaskPrincipal -UserId '" + PsEscapeSingleQuotes(userSam) + "' -LogonType Interactive -RunLevel Highest) -Force"
  
  Protected args.s = "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + psCmd + Chr(34)
  ProcedureReturn Bool(RunAndCapture("powershell.exe", args) = 0)
EndProcedure

Procedure.i RemoveFromStartup()
  Protected args.s = "/Delete /F /TN " + QuoteArgument(#STARTUP_TASK_NAME)
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", args) = 0)
EndProcedure

Procedure.i AddToStartup(targetUserSam.s = "")
  If Not IsProcessElevated()
    If ShellExecute_(0, "runas", ProgramFilename(), "--installstartup --user " + QuoteArgument(targetUserSam), "", #SW_SHOWNORMAL) > 32
      ProcedureReturn -1
    EndIf
    ProcedureReturn #False
  EndIf
  ProcedureReturn InstallStartupTask(targetUserSam)
EndProcedure

Procedure About(icon1.i)
  MessageRequester(Lng\AboutTitle + " " + #APP_NAME, BuildAboutText(icon1), #PB_MessageRequester_Info)
EndProcedure

Procedure Help()
  MessageRequester(Lng\Help, BuildHelpText(), #PB_MessageRequester_Info)
EndProcedure

Procedure EditSettings()
  Protected w = 410
  Protected h = 540
  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, Lng\EditSettingsTitle, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If win = 0 : ProcedureReturn : EndIf

  Protected ly = 15
  TextGadget(#PB_Any, 15, ly, 365, 20, Lng\MonitoringTitle)
  ly + 25
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\UpdateIntervalLabel)
  Protected gadUpdate = StringGadget(#PB_Any, 210, ly, 170, 20, Str(UpdateIntervalMs), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\TooltipIntervalLabel)
  Protected gadTooltip = StringGadget(#PB_Any, 210, ly, 170, 20, Str(TooltipUpdateIntervalMs), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\ActivityThresholdLabel)
  Protected gadThreshold = StringGadget(#PB_Any, 210, ly, 170, 20, StrD(ActivityThresholdBps, 0))

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\ActivityHoldLabel)
  Protected gadHold = StringGadget(#PB_Any, 210, ly, 170, 20, Str(ActivityHoldMs), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\PdhSampleIntervalLabel)
  Protected gadPdh = StringGadget(#PB_Any, 210, ly, 170, 20, Str(PdhSampleIntervalMs), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\IoctlBackoffLabel)
  Protected gadIoctl = StringGadget(#PB_Any, 210, ly, 170, 20, Str(IoctlBackoffCycles), #PB_String_Numeric)

  ly + 40
  TextGadget(#PB_Any, 15, ly, 365, 20, Lng\StartupIconsTitle)
  ly + 25
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\DefaultIconSetLabel)
  Protected gadDefaultIcon = StringGadget(#PB_Any, 210, ly, 170, 20, Str(DefaultIconSet), #PB_String_Numeric)

  ly + 30
  Protected gadStartRandom = CheckBoxGadget(#PB_Any, 15, ly, 365, 20, Lng\StartRandomIconSetLabel)
  SetGadgetState(gadStartRandom, StartWithRandomIconSet)

  ly + 30
  Protected gadForcePdh = CheckBoxGadget(#PB_Any, 15, ly, 365, 20, Lng\ForcePdhDefaultLabel)
  SetGadgetState(gadForcePdh, ForcePdhOnlyDefault)

  ly + 40
  TextGadget(#PB_Any, 15, ly, 365, 20, Lng\Logging)
  ly + 25
  Protected gadLogging = CheckBoxGadget(#PB_Any, 15, ly, 365, 20, Lng\EnableLoggingLabel)
  SetGadgetState(gadLogging, LoggingEnabled)

  ly + 30
  Protected gadRotate = CheckBoxGadget(#PB_Any, 15, ly, 365, 20, Lng\EnableLogRotationLabel)
  SetGadgetState(gadRotate, LogRotateEnabled)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\RotateKeepFilesLabel)
  Protected gadRotateKeep = StringGadget(#PB_Any, 210, ly, 170, 20, Str(LogRotateKeep), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 170, 20, Lng\RotateMaxKbLabel)
  Protected gadRotateMax = StringGadget(#PB_Any, 210, ly, 170, 20, Str(LogRotateMaxBytes / 1024), #PB_String_Numeric)

  ly + 50
  Protected gadOk = ButtonGadget(#PB_Any, w - 180, h - 42, 80, 26, Lng\Ok)
  Protected gadCancel = ButtonGadget(#PB_Any, w - 92, h - 42, 80, 26, Lng\Cancel)

  Protected changed.i = #False
  Protected done.i = #False
  Repeat
    Protected ev = WaitWindowEvent()
    If ev = #PB_Event_CloseWindow
      done = #True
    ElseIf ev = #PB_Event_Gadget
      Protected g = EventGadget()
      If g = gadOk
        Protected oldLoggingEnabled.i = LoggingEnabled

        Protected vUpdate.i = ClampI(Val(GetGadgetText(gadUpdate)), 10, 2000)
        If vUpdate <> UpdateIntervalMs : UpdateIntervalMs = vUpdate : changed = #True : EndIf

        Protected vTip.i = ClampI(Val(GetGadgetText(gadTooltip)), 250, 30000)
        If vTip <> TooltipUpdateIntervalMs : TooltipUpdateIntervalMs = vTip : changed = #True : EndIf

        Protected vThresh.d = ClampD(ValD(GetGadgetText(gadThreshold)), 0.0, 1024.0 * 1024.0 * 1024.0)
        If vThresh <> ActivityThresholdBps : ActivityThresholdBps = vThresh : changed = #True : EndIf

        Protected vHold.i = ClampI(Val(GetGadgetText(gadHold)), 0, 5000)
        If vHold <> ActivityHoldMs : ActivityHoldMs = vHold : changed = #True : EndIf

        Protected vPdh.i = ClampI(Val(GetGadgetText(gadPdh)), 50, 5000)
        If vPdh <> PdhSampleIntervalMs : PdhSampleIntervalMs = vPdh : changed = #True : EndIf

        Protected vIoctl.i = ClampI(Val(GetGadgetText(gadIoctl)), 0, 1000)
        If vIoctl <> IoctlBackoffCycles : IoctlBackoffCycles = vIoctl : changed = #True : EndIf

        Protected vDef.i = ClampI(Val(GetGadgetText(gadDefaultIcon)), 1, 9999)
        If vDef <> DefaultIconSet : DefaultIconSet = vDef : changed = #True : EndIf

        Protected vRandom.i = Bool(GetGadgetState(gadStartRandom) <> 0)
        If vRandom <> StartWithRandomIconSet : StartWithRandomIconSet = vRandom : changed = #True : EndIf

        Protected vForce.i = Bool(GetGadgetState(gadForcePdh) <> 0)
        If vForce <> ForcePdhOnlyDefault : ForcePdhOnlyDefault = vForce : changed = #True : EndIf

        Protected vLogging.i = Bool(GetGadgetState(gadLogging) <> 0)
        If vLogging <> LoggingEnabled : LoggingEnabled = vLogging : changed = #True : EndIf

        Protected vRotate.i = Bool(GetGadgetState(gadRotate) <> 0)
        If vRotate <> LogRotateEnabled : LogRotateEnabled = vRotate : changed = #True : EndIf

        Protected vRotateKeep.i = ClampI(Val(GetGadgetText(gadRotateKeep)), 1, 9999)
        If vRotateKeep <> LogRotateKeep : LogRotateKeep = vRotateKeep : changed = #True : EndIf

        Protected vRotateMax.i = ClampI(Val(GetGadgetText(gadRotateMax)), 1, 1048576)
        If (vRotateMax * 1024) <> LogRotateMaxBytes : LogRotateMaxBytes = vRotateMax * 1024 : changed = #True : EndIf

        If changed
          SaveSettings()
          ForcePdhOnly = ForcePdhOnlyDefault
          UpdateLogMenuLabel()
          SetMenuItemState(#Menu_Main, #MenuItem_ForcePdh, ForcePdhOnly)
          If LoggingEnabled
            If oldLoggingEnabled = #False
              LogMessage("Logging ENABLED via settings dialog")
            EndIf
            LogMessage("Settings updated via dialog")
          EndIf
          MessageRequester(Lng\SettingsSavedTitle, Lng\SettingsSavedMessage, #PB_MessageRequester_Info)
        EndIf
        done = #True
      ElseIf g = gadCancel
        done = #True
      EndIf
    EndIf
  Until done

  CloseWindow(win)
EndProcedure

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 3
; Folding = ------
; EnableXP
; DPIAware
; Executable = ..\HandyDrvLED.exe
