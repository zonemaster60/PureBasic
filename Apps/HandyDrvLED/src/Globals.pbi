; HandyDrvLED Globals & Constants

#APP_NAME = "HandyDrvLED"
Global version.s = "v1.0.3.3"
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
#LOG_MAX_BYTES = 524288
#LOG_MAX_SEGMENTS_PER_DAY = 20
#LOG_RETENTION_DAYS = 14
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
Global IniPath.s = AppPath + #APP_NAME + ".ini"
Global LogBase.s = AppPath + #APP_NAME
Global LogPath.s = LogBase + ".log"
Global LogCurrentDate.s = ""
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
Global PdhLastCollectStatus.l
Global PdhLastReadStatus.l
Global PdhLastWriteStatus.l

; Prototypes
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

Procedure LogLine(message.s, key.s = "")
  Protected k.s = key : If k = "" : k = message : EndIf
  Protected now.i = ElapsedMilliseconds()
  LockMutex(Mutex_DiskData)
  If FindMapElement(LogLastTime(), k) : If now - LogLastTime() < #LOG_THROTTLE_MS : UnlockMutex(Mutex_DiskData) : ProcedureReturn : EndIf : EndIf
  LogLastTime(k) = now
  UnlockMutex(Mutex_DiskData)

  Protected today.s = FormatDate("%yyyy-%mm-%dd", Date())
  Protected stamp.s = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date())
  Protected target.s = LogBase + "." + today + ".log"
  Protected fh.i
  
  ; Check retention (once per hour or simple check)
  Static lastRetentionCheck.i
  If now - lastRetentionCheck > 3600000 ; 1 hour
    lastRetentionCheck = now
    If ExamineDirectory(1, AppPath, #APP_NAME + ".*.log")
      Protected cutoff.i = AddDate(Date(), #PB_Date_Day, -#LOG_RETENTION_DAYS)
      While NextDirectoryEntry(1)
        Protected entryName.s = DirectoryEntryName(1)
        Protected entryDate.s = StringField(entryName, 2, ".") ; Format: HandyDrvLED.yyyy-mm-dd.log
        If Len(entryDate) = 10
          Protected fileTime.i = ParseDate("%yyyy-%mm-%dd", entryDate)
          If fileTime < cutoff
            DeleteFile(AppPath + entryName)
          EndIf
        EndIf
      Wend
      FinishDirectory(1)
    EndIf
  EndIf

  ; Write log with size-based segmenting
  Protected segment.i = 0
  Protected actualTarget.s = target
  While FileSize(actualTarget) >= #LOG_MAX_BYTES
    segment + 1
    actualTarget = LogBase + "." + today + "." + Str(segment) + ".log"
    If segment >= #LOG_MAX_SEGMENTS_PER_DAY : Break : EndIf
  Wend

  fh = OpenFile(#PB_Any, actualTarget)
  If fh
    FileSeek(fh, Lof(fh))
    WriteStringN(fh, stamp + " | " + message)
    CloseFile(fh)
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

Procedure.i CountIconLibraries()
  Protected count.i = 0
  If ExamineDirectory(0, "IconLibs\", "*.icl")
    While NextDirectoryEntry(0) : count + 1 : Wend
    FinishDirectory(0)
  EndIf
  If count = 0 : count = 1 : EndIf
  ProcedureReturn count
EndProcedure

Procedure.i LoadIconSet(iconSetNumber.i)
  Protected iconlib.s = "IconLibs\" + #APP_NAME + "." + iconSetNumber + ".icl"
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
  If MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
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
    ShellExecute_(0, "runas", ProgramFilename(), "--installstartup --user " + QuoteArgument(targetUserSam), "", #SW_SHOWNORMAL)
    ProcedureReturn #True
  EndIf
  ProcedureReturn InstallStartupTask(targetUserSam)
EndProcedure

Procedure About(icon1.i)
  MessageRequester("About", #APP_NAME + " - " + version + #LF$ +
                            "Thank you for using this free tool!" + #LF$ +
                            "-----------------------------------" + #LF$ +
                            "Contact: " + #EMAIL_NAME + #LF$ +
                            "Website: https://github.com/zonemaster60" + #LF$ +
                            "Using IconSet: " + Str(icon1), #PB_MessageRequester_Info)
EndProcedure

Procedure Help()
  Protected helpText.s

  helpText = #APP_NAME + " Help" + #LF$ +
             "Tray icon:" + #LF$ +
             "  - Right-click for options." + #LF$ +
             "  - Colors: RED=Write, GREEN=Read, BLUE=Both, YELLOW=Idle" + #LF$ + #LF$ +
             "Activity detection:" + #LF$ +
             "  - Uses IOCTL_DISK_PERFORMANCE or PDH fallback." + #LF$ + #LF$ +
             "Tray menu:" + #LF$ +
             "  - About: Version info." + #LF$ +
             "  - Drive(s): Open drive browser." + #LF$ +
             "  - Diagnostics: IOCTL/PDH status." + #LF$ +
             "  - Reload/Edit settings: Manage config." + #LF$ +
             "  - Start with Windows: Toggle auto-start." + #LF$ + #LF$ +
             "Drive(s) window:" + #LF$ +
             "  - View capacity, free space, and filesystem info." + #LF$ +
             "  - Supports Fixed, Removable, Network, CDROM, RAMDisk." + #LF$ + #LF$ +
             "Config: HandyDrvLED.ini"

  MessageRequester("Help", helpText, #PB_MessageRequester_Info)
EndProcedure

Procedure EditSettings()
  Protected changed.i = #False
  Protected newUpdateInterval.s, newTooltipInterval.s, newThreshold.s, newHoldMs.s
  Protected newPdhSample.s, newIoctlBackoff.s, newStartRandom.s, newDefaultIconSet.s, newForcePdhOnly.s

  ; UpdateIntervalMs
  newUpdateInterval = InputRequester("Edit Settings", "UpdateIntervalMs (10..2000) (current: " + Str(UpdateIntervalMs) + "):", Str(UpdateIntervalMs))
  If newUpdateInterval <> ""
    Protected vUpdate.i = ClampI(Val(newUpdateInterval), 10, 2000)
    If vUpdate <> UpdateIntervalMs : UpdateIntervalMs = vUpdate : changed = #True : EndIf
  EndIf

  ; TooltipUpdateIntervalMs
  newTooltipInterval = InputRequester("Edit Settings", "TooltipUpdateIntervalMs (250..30000) (current: " + Str(TooltipUpdateIntervalMs) + "):", Str(TooltipUpdateIntervalMs))
  If newTooltipInterval <> ""
    Protected vTip.i = ClampI(Val(newTooltipInterval), 250, 30000)
    If vTip <> TooltipUpdateIntervalMs : TooltipUpdateIntervalMs = vTip : changed = #True : EndIf
  EndIf

  ; ActivityThresholdBps
  newThreshold = InputRequester("Edit Settings", "ActivityThresholdBps (0..1GB/s) (current: " + StrD(ActivityThresholdBps, 0) + "):", StrD(ActivityThresholdBps, 0))
  If newThreshold <> ""
    Protected vThresh.d = ClampD(ValD(newThreshold), 0.0, 1024.0 * 1024.0 * 1024.0)
    If vThresh <> ActivityThresholdBps : ActivityThresholdBps = vThresh : changed = #True : EndIf
  EndIf

  ; ActivityHoldMs
  newHoldMs = InputRequester("Edit Settings", "ActivityHoldMs (0..5000) (current: " + Str(ActivityHoldMs) + "):", Str(ActivityHoldMs))
  If newHoldMs <> ""
    Protected vHold.i = ClampI(Val(newHoldMs), 0, 5000)
    If vHold <> ActivityHoldMs : ActivityHoldMs = vHold : changed = #True : EndIf
  EndIf

  ; PdhSampleIntervalMs
  newPdhSample = InputRequester("Edit Settings", "PdhSampleIntervalMs (50..5000) (current: " + Str(PdhSampleIntervalMs) + "):", Str(PdhSampleIntervalMs))
  If newPdhSample <> ""
    Protected vPdh.i = ClampI(Val(newPdhSample), 50, 5000)
    If vPdh <> PdhSampleIntervalMs : PdhSampleIntervalMs = vPdh : changed = #True : EndIf
  EndIf

  ; IoctlBackoffCycles
  newIoctlBackoff = InputRequester("Edit Settings", "IoctlBackoffCycles (0..1000) (current: " + Str(IoctlBackoffCycles) + "):", Str(IoctlBackoffCycles))
  If newIoctlBackoff <> ""
    Protected vIoctl.i = ClampI(Val(newIoctlBackoff), 0, 1000)
    If vIoctl <> IoctlBackoffCycles : IoctlBackoffCycles = vIoctl : changed = #True : EndIf
  EndIf

  ; StartWithRandomIconSet
  newStartRandom = InputRequester("Edit Settings", "StartWithRandomIconSet (0/1) (current: " + Str(StartWithRandomIconSet) + "):", Str(StartWithRandomIconSet))
  If newStartRandom <> ""
    Protected vRand.i = Val(newStartRandom)
    If vRand = 0 Or vRand = 1
      If vRand <> StartWithRandomIconSet : StartWithRandomIconSet = vRand : changed = #True : EndIf
    EndIf
  EndIf

  ; DefaultIconSet
  newDefaultIconSet = InputRequester("Edit Settings", "DefaultIconSet (>=1) (current: " + Str(DefaultIconSet) + "):", Str(DefaultIconSet))
  If newDefaultIconSet <> "" And Val(newDefaultIconSet) > 0
    Protected vDef.i = Val(newDefaultIconSet)
    If vDef < 1 : vDef = 1 : EndIf
    If vDef <> DefaultIconSet : DefaultIconSet = vDef : changed = #True : EndIf
  EndIf

  ; ForcePdhOnlyDefault
  newForcePdhOnly = InputRequester("Edit Settings", "ForcePdhOnly (0/1) (current: " + Str(ForcePdhOnlyDefault) + "):", Str(ForcePdhOnlyDefault))
  If newForcePdhOnly <> ""
    Protected vForce.i = Val(newForcePdhOnly)
    If vForce = 0 Or vForce = 1
      If vForce <> ForcePdhOnlyDefault : ForcePdhOnlyDefault = vForce : changed = #True : EndIf
    EndIf
  EndIf

  If changed
    SaveSettings()
    MessageRequester("Settings Saved", "Settings have been saved successfully.", #PB_MessageRequester_Info)
  EndIf
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 3
; Folding = -----
; EnableXP
; DPIAware
; Executable = ..\HandyDrvLED.exe