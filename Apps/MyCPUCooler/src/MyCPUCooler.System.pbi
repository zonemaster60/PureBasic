; MyCPUCooler.pb
; Small Windows 11 power-plan tuner focused on lowering temps
; (No third-party “optimizers”; uses powercfg)

; -----------------------------
; Windows powercfg GUID constants
; -----------------------------

#SUB_PROCESSOR$      = "54533251-82be-4824-96c1-47b60b740d00"
#SET_MAX_PROC_STATE$ = "bc5038f7-23e0-4960-96da-33abaf5935ec"
#SET_BOOST_MODE$     = "be337238-0d82-4146-a960-4f3749d470c7"
#SET_SYS_COOLING_POLICY$ = "94d3a615-a899-4ac5-ae2b-e4d8f634367f"
#SET_MIN_PROC_STATE$ = "893dee8e-2bef-41e0-89c6-b55d0929964c"
#SCHEME_BALANCED$    = "381b4222-f694-41f0-9685-ff5bb260df2e"
#SUB_PCIE$           = "ee12f483-ad20-4395-8360-3116c4296227"
#SET_ASPM$           = "ee12f483-ad20-4395-8360-3116c4296228"


; boost mode values (not all systems expose/honor these)
#BOOST_DISABLED    = 0
#BOOST_ENABLED     = 1
#BOOST_AGGRESSIVE  = 2
#BOOST_EFFICIENT   = 3
#BOOST_EFFICIENT_AGGRESSIVE = 4

Enumeration 1
  #PROFILE_BATTERY_SAVER
  #PROFILE_ECO
  #PROFILE_QUIET
  #PROFILE_COOL
  #PROFILE_BALANCED
  #PROFILE_PERFORMANCE
EndEnumeration

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.0.0.8"

; Registry base key (HKCU)
#APP_NAME = "MyCPUCooler"
#REG_BASE$ = "Software\" + #APP_NAME
#HISTORY_POINTS = 36
#MAX_CUSTOM_PROFILES = 12
#BENCHMARK_MODE_SECONDS = 600
#TELEMETRY_INTERVAL_MS = 7000
#THERMAL_REFRESH_SECONDS = 30

#NIM_MODIFY = 1
#NIF_INFO = $10
#NIIF_INFO = $1

Structure LiveTelemetry
  CpuLoad.s
  ThermalC.s
  PowerSource.s
  LastUpdated.s
  ErrorText.s
EndStructure

Structure FileTimeCompat
  dwLowDateTime.l
  dwHighDateTime.l
EndStructure

Structure SystemPowerStatusCompat
  ACLineStatus.b
  BatteryFlag.b
  BatteryLifePercent.b
  Reserved1.b
  BatteryLifeTime.l
  BatteryFullLifeTime.l
EndStructure

Procedure.q FileTimeToQuad(*value.FileTimeCompat)
  Protected high.q
  Protected low.q

  If *value = 0
    ProcedureReturn 0
  EndIf

  high = *value\dwHighDateTime & $FFFFFFFF
  low = *value\dwLowDateTime & $FFFFFFFF
  ProcedureReturn (high * 4294967296) + low
EndProcedure

Structure AppSettings
  SchemeGuid.s
  ACMaxCPU.i
  DCMaxCPU.i
  ACMinCPU.i
  DCMinCPU.i
  ACProfile.i
  DCProfile.i
  BoostMode.i
  CoolingPolicy.i
  ASPMMode.i
  ACBoostMode.i
  DCBoostMode.i
  ACCoolingPolicy.i
  DCCoolingPolicy.i
  ACASPMMode.i
  DCASPMMode.i
  AutoApply.i
  LiveApply.i
  RunAtStartup.i
  UseTaskScheduler.i
  HeatAlertEnabled.i
  HeatAlertThreshold.i
  AutoThermalSwitchEnabled.i
  AutoThermalSwitchProfile.i
  AutoThermalSwitchSeconds.i
  StartupMode.i
  AutoRestoreEnabled.i
  AutoRestoreThreshold.i
  AutoRestoreSeconds.i
  ACAutoSwitchEnabled.i
  DCAutoSwitchEnabled.i
  ACAutoSwitchProfile.i
  DCAutoSwitchProfile.i
  ACAutoSwitchThreshold.i
  DCAutoSwitchThreshold.i
  ACAutoSwitchSeconds.i
  DCAutoSwitchSeconds.i
  ACAutoRestoreEnabled.i
  DCAutoRestoreEnabled.i
  ACAutoRestoreThreshold.i
  DCAutoRestoreThreshold.i
  ACAutoRestoreSeconds.i
  DCAutoRestoreSeconds.i
  BenchmarkModeEnabled.i
  BenchmarkModeEndsAt.i
EndStructure

Structure CustomProfile
  Name.s
  Settings.AppSettings
EndStructure

; -----------------------------
; Logging + diagnostics
; -----------------------------

Enumeration 1
  #LOG_ERROR
  #LOG_WARN
  #LOG_INFO
  #LOG_DEBUG
EndEnumeration

Global gLogEnabled.i = #True
Global gLogLevel.i = #LOG_INFO
Global gLogPath.s = ""
Global gLastWin32Error.i
Global gLastStdout.s
Global gLastStderr.s

; Log rotation (size-based)
Global gLogRotateEnabled.i = #True
Global gLogRotateMaxBytes.q = 1024 * 1024 ; 1 MiB
Global gLogRotateKeep.i = 3
Global gTelemetry.LiveTelemetry
Global gTelemetryThread.i
Global gTelemetryBusy.i
Global gTelemetryAvailable.i = #True
Global gLastCpuIdleTime.q
Global gLastCpuKernelTime.q
Global gLastCpuUserTime.q
Global gCpuTimesReady.i
Global gLastThermalRefreshTime.i
Global gCachedThermalC.s = "Unavailable"
Global gMainWindowVisible.i = #True
Global gMiniWindowVisible.i
Global gCurrentScheme.s
Global gUseBoost.i
Global gUseCooling.i
Global gUseASPM.i
Global gIniPath.s
Global gTrayImage.i
Global gTrayReady.i
Global gLastHeatAlertTime.i
Global gHeatAlertThreshold.d = 80.0
Global gLastApplyMessage.s
Global gHeatPopupEnabled.i = #True
Global gAutoThermalSwitchEnabled.i
Global gAutoThermalSwitchProfile.i = #PROFILE_COOL
Global gAutoThermalSwitchSeconds.i = 30
Global gThermalOverThresholdSince.i
Global gAutoRestoreEnabled.i
Global gAutoRestoreThreshold.d = 70.0
Global gAutoRestoreSeconds.i = 45
Global gThermalBelowRestoreSince.i
Global gLastManualProfile.i
Global gAutoSwitchedProfile.i
Global gACAutoSwitchSince.i
Global gDCAutoSwitchSince.i
Global gACAutoRestoreSince.i
Global gDCAutoRestoreSince.i
Global gLastManualACProfile.i
Global gLastManualDCProfile.i
Global gAutoSwitchedACProfile.i
Global gAutoSwitchedDCProfile.i
Global gPendingSettingsSave.i
Global gPendingSettingsSaveAt.i
Global Dim gThermalHistory.i(#HISTORY_POINTS - 1)
Global Dim gCpuLoadHistory.i(#HISTORY_POINTS - 1)
Global gHistoryCount.i
Global NewList gCustomProfiles.CustomProfile()
Global gLastNonBenchmarkSettings.AppSettings

Procedure.b HasArg(arg$)
  Protected i
  For i = 1 To CountProgramParameters()
    If LCase(ProgramParameter(i - 1)) = LCase(arg$)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Procedure.s GetArgValue(key$)
  ; Supports: --key=value  OR  --key value
  Protected i, p$, k$ = LCase(key$)
  For i = 1 To CountProgramParameters()
    p$ = ProgramParameter(i - 1)

    If LCase(Left(p$, Len(k$) + 1)) = k$ + "="
      ProcedureReturn Mid(p$, Len(k$) + 2)
    EndIf

    If LCase(p$) = k$
      If i < CountProgramParameters()
        ProcedureReturn ProgramParameter(i)
      EndIf
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure.s WinErrorMessage(err.i)
  ; Human-readable Win32 error text (best-effort)
  #FORMAT_MESSAGE_ALLOCATE_BUFFER = $00000100
  #FORMAT_MESSAGE_FROM_SYSTEM     = $00001000
  #FORMAT_MESSAGE_IGNORE_INSERTS  = $00000200

  Protected *buf
  Protected flags = #FORMAT_MESSAGE_ALLOCATE_BUFFER | #FORMAT_MESSAGE_FROM_SYSTEM | #FORMAT_MESSAGE_IGNORE_INSERTS

  If err = 0
    ProcedureReturn ""
  EndIf

  If FormatMessage_(flags, 0, err, 0, @*buf, 0, 0) = 0 Or *buf = 0
    ProcedureReturn "Win32 error " + Str(err)
  EndIf

  Protected msg$ = Trim(PeekS(*buf, -1, #PB_Unicode))
  LocalFree_(*buf)

  If msg$ = ""
    ProcedureReturn "Win32 error " + Str(err)
  EndIf

  ProcedureReturn msg$ + " (" + Str(err) + ")"
EndProcedure

Procedure.s FormatLogLevel(level.i)
  Select level
    Case #LOG_ERROR : ProcedureReturn "ERROR"
    Case #LOG_WARN  : ProcedureReturn "WARN"
    Case #LOG_INFO  : ProcedureReturn "INFO"
    Case #LOG_DEBUG : ProcedureReturn "DEBUG"
  EndSelect
  ProcedureReturn "INFO"
EndProcedure

Procedure LogWriteRaw(line$)
  If gLogEnabled = #False Or gLogPath = ""
    ProcedureReturn
  EndIf

  Protected f = OpenFile(#PB_Any, gLogPath)
  If f = 0
    f = CreateFile(#PB_Any, gLogPath)
  EndIf
  If f
    FileSeek(f, Lof(f))
    WriteStringN(f, line$)
    CloseFile(f)
  EndIf
EndProcedure

Procedure LogLine(level.i, msg$)
  If gLogEnabled = #False
    ProcedureReturn
  EndIf
 
  If level > gLogLevel
    ProcedureReturn
  EndIf
 
  Protected ts$ = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  LogWriteRaw(ts$ + " [" + FormatLogLevel(level) + "] " + msg$)
EndProcedure

Procedure LogRotateIfNeeded()
  If gLogEnabled = #False Or gLogRotateEnabled = #False Or gLogPath = ""
    ProcedureReturn
  EndIf

  If gLogRotateKeep < 1 Or gLogRotateMaxBytes < 1
    ProcedureReturn
  EndIf

  Protected size.q = FileSize(gLogPath)
  If size < 0
    ProcedureReturn
  EndIf

  If size <= gLogRotateMaxBytes
    ProcedureReturn
  EndIf

  Protected i.i
  Protected src$
  Protected dst$

  ; Delete oldest backup first
  dst$ = gLogPath + "." + Str(gLogRotateKeep)
  If FileSize(dst$) >= 0
    DeleteFile(dst$)
  EndIf

  ; Shift backups up: .2 -> .3, .1 -> .2, ...
  For i = gLogRotateKeep - 1 To 1 Step -1
    src$ = gLogPath + "." + Str(i)
    If FileSize(src$) >= 0
      RenameFile(src$, gLogPath + "." + Str(i + 1))
    EndIf
  Next

  ; Move current log to .1
  RenameFile(gLogPath, gLogPath + ".1")
EndProcedure

Procedure.s EnsureLogFolder(baseFolder$)
  Protected folder$ = baseFolder$

  If folder$ = ""
    ProcedureReturn ""
  EndIf

  If Right(folder$, 1) <> "\"
    folder$ + "\"
  EndIf

  folder$ + "Logs\"

  If FileSize(folder$) <> -2
    CreateDirectory(folder$)
  EndIf

  If FileSize(folder$) = -2
    ProcedureReturn folder$
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure LogInit()
  ; Default log location: in Logs next to the exe (Logs\MyCPUCooler.log)
  ; Can be overridden with: --logfile <path>  (or --logfile=<path>)
  gLogPath = GetArgValue("--logfile")
  If gLogPath = ""
    Protected logFolder$ = EnsureLogFolder(GetPathPart(ProgramFilename()))
    If logFolder$ <> ""
      gLogPath = logFolder$ + #APP_NAME + ".log"
    Else
      gLogPath = GetPathPart(ProgramFilename()) + #APP_NAME + ".log"
    EndIf
  EndIf

  If HasArg("--nolog")
    gLogEnabled = #False
  EndIf

  ; Rotation controls
  If HasArg("--norotate")
    gLogRotateEnabled = #False
  EndIf

  Protected keep$ = GetArgValue("--logkeep")
  If keep$ <> ""
    gLogRotateKeep = Val(keep$)
  EndIf

  Protected maxKb$ = GetArgValue("--logmaxkb")
  If maxKb$ <> ""
    gLogRotateMaxBytes = Val(maxKb$) * 1024
  EndIf
 
  If HasArg("--debug") Or HasArg("--verbose")
    gLogLevel = #LOG_DEBUG
  EndIf

  LogRotateIfNeeded()
 
  LogLine(#LOG_INFO, "--- start " + #APP_NAME + " " + version + " ---")
  LogLine(#LOG_INFO, "exe=" + ProgramFilename())
  LogLine(#LOG_INFO, "cwd=" + GetCurrentDirectory())
EndProcedure

; Prevent multiple instances (don't rely on window title text)
LogInit()
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex = 0
  gLastWin32Error = GetLastError_()
  LogLine(#LOG_ERROR, "CreateMutex failed: " + WinErrorMessage(gLastWin32Error))
EndIf
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  LogLine(#LOG_WARN, "Already running; exiting")
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; Exit confirmation
Procedure.b ConfirmExit()
  Protected req.i
  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(req = #PB_MessageRequester_Yes)
EndProcedure

Procedure.s CurrentUserAccount()
  Protected user$ = GetEnvironmentVariable("USERNAME")
  Protected domain$ = GetEnvironmentVariable("USERDOMAIN")

  If domain$ <> "" And user$ <> ""
    ProcedureReturn domain$ + "\\" + user$
  EndIf

  ProcedureReturn user$
EndProcedure

Procedure.s StartupCommandLine(*settings.AppSettings)
  Protected args$ = "--tray"

  If *settings = 0
    ProcedureReturn Chr(34) + ProgramFilename() + Chr(34) + " --tray"
  EndIf

  Select *settings\StartupMode
    Case 0
      args$ = ""
    Case 1
      args$ = "--tray"
    Case 2
      args$ = "--mini"
    Case 3
      args$ = "--silent"
  EndSelect

  If args$ = ""
    ProcedureReturn Chr(34) + ProgramFilename() + Chr(34)
  EndIf

  ProcedureReturn Chr(34) + ProgramFilename() + Chr(34) + " " + args$
EndProcedure

; Minimal registry constants (avoid PB version differences)
#HKEY_CURRENT_USER = $80000001
#KEY_READ  = $20019
#KEY_WRITE = $20006
#REG_SZ = 1
#REG_EXPAND_SZ = 2
#REG_DWORD = 4

Global gSettings.AppSettings

; Forward declarations (used before definitions)
Declare LoadAppSettings(iniPath$, *settings.AppSettings)
Declare SaveAppSettings(iniPath$, *settings.AppSettings)
Declare UpdateDisplayedValues(useBoost.i, useCooling.i, useASPM.i)
Declare SetStatus(summary$, detail$ = "")
Declare LoadPreset(useBoost.i, useCooling.i, useASPM.i, acMax.i, dcMax.i, acMin.i, dcMin.i, acBoostValue.i, dcBoostValue.i, acCoolingPolicy.i, dcCoolingPolicy.i, acASPMValue.i, dcASPMValue.i)
Declare SaveCurrentUIToSettings(*settings.AppSettings, useBoost.i, useCooling.i, useASPM.i)
Declare UpdateTelemetryDisplay()
Declare.i EnsureTrayIcon()
Declare UpdateTrayMenuState()
Declare ShowTrayNotification(title$, message$)
Declare UpdateMiniDashboard()
Declare RefreshMiniProfileBadge()
Declare MaybeAutoSwitchThermalProfile()
Declare ApplyPresetAndRefresh(profileId.i)
Declare ShowMiniDashboard(showWindow.i)
Declare DrawMiniHistory()
Declare UpdateAutomationDisplay()
Declare LoadSettingsIntoUI(*settings.AppSettings)
Declare ApplySingleModePresetAndRefresh(profileId.i, isBattery.i, reason$ = "")
Declare ExportCurrentProfile()
Declare ImportCoolingProfile()
Declare LoadCustomProfiles()
Declare SaveCustomProfiles()
Declare RefreshCustomProfileCombo()
Declare SaveCustomProfileFromCurrentUI()
Declare LoadSelectedCustomProfile()
Declare EnterBenchmarkMode()
Declare CheckBenchmarkMode()
Declare ApplyCurrentGadgetSettings(scheme$, useBoost.i, useCooling.i, useASPM.i, *diag.ApplyDiagnostics = 0)
Declare ScheduleSettingsSave(delayMs.i = 350)
Declare FlushPendingSettingsSave()

; -----------------------------
; Windows registry helpers (HKCU)
; -----------------------------

Prototype.l ProtoRegCreateKeyExW(hKey.i, lpSubKey.p-unicode, Reserved.l, lpClass.i, dwOptions.l, samDesired.l, lpSecurityAttributes.i, phkResult.i, lpdwDisposition.i)
Prototype.l ProtoRegOpenKeyExW(hKey.i, lpSubKey.p-unicode, ulOptions.l, samDesired.l, phkResult.i)
Prototype.l ProtoRegSetValueExW(hKey.i, lpValueName.p-unicode, Reserved.l, dwType.l, lpData.i, cbData.l)
Prototype.l ProtoRegQueryValueExW(hKey.i, lpValueName.p-unicode, lpReserved.i, lpType.i, lpData.i, lpcbData.i)
Prototype.l ProtoRegDeleteValueW(hKey.i, lpValueName.p-unicode)
Prototype.l ProtoRegCloseKey(hKey.i)

Global gAdvapi32.i
Global RegCreateKeyExW.ProtoRegCreateKeyExW
Global RegOpenKeyExW.ProtoRegOpenKeyExW
Global RegSetValueExW.ProtoRegSetValueExW
Global RegQueryValueExW.ProtoRegQueryValueExW
Global RegDeleteValueW.ProtoRegDeleteValueW
Global RegCloseKey.ProtoRegCloseKey

Procedure SetupAdvapi32()
  If gAdvapi32
    ProcedureReturn
  EndIf

  gAdvapi32 = OpenLibrary(#PB_Any, "advapi32.dll")
  If gAdvapi32
    RegCreateKeyExW = GetFunction(gAdvapi32, "RegCreateKeyExW")
    RegOpenKeyExW   = GetFunction(gAdvapi32, "RegOpenKeyExW")
    RegSetValueExW  = GetFunction(gAdvapi32, "RegSetValueExW")
    RegQueryValueExW = GetFunction(gAdvapi32, "RegQueryValueExW")
    RegDeleteValueW = GetFunction(gAdvapi32, "RegDeleteValueW")
    RegCloseKey     = GetFunction(gAdvapi32, "RegCloseKey")
  EndIf
EndProcedure

Procedure EnsureAdvapi32()
  SetupAdvapi32()
  If gAdvapi32 = 0 Or RegCreateKeyExW = 0 Or RegOpenKeyExW = 0 Or RegSetValueExW = 0 Or RegQueryValueExW = 0 Or RegDeleteValueW = 0 Or RegCloseKey = 0
    LogLine(#LOG_ERROR, "Failed to load required functions from advapi32.dll")
    MessageRequester("Error", "Failed to load required functions from advapi32.dll.", #PB_MessageRequester_Error)
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure.i RegWriteString(subKey$, valueName$, value$)
  EnsureAdvapi32()

  Protected hKey.i, disp.l
  If RegCreateKeyExW(#HKEY_CURRENT_USER, subKey$, 0, 0, 0, #KEY_WRITE, 0, @hKey, @disp) <> 0
    ProcedureReturn #False
  EndIf

  Protected bytes = (Len(value$) + 1) * SizeOf(Character)
  Protected ok = Bool(RegSetValueExW(hKey, valueName$, 0, #REG_SZ, @value$, bytes) = 0)
  RegCloseKey(hKey)
  ProcedureReturn ok
EndProcedure

Procedure.i RegWriteDword(subKey$, valueName$, value.i)
  EnsureAdvapi32()

  Protected hKey.i, disp.l
  If RegCreateKeyExW(#HKEY_CURRENT_USER, subKey$, 0, 0, 0, #KEY_WRITE, 0, @hKey, @disp) <> 0
    ProcedureReturn #False
  EndIf

  Protected v.l = value
  Protected ok = Bool(RegSetValueExW(hKey, valueName$, 0, #REG_DWORD, @v, SizeOf(Long)) = 0)
  RegCloseKey(hKey)
  ProcedureReturn ok
EndProcedure

Procedure.s RegReadString(subKey$, valueName$, defaultValue$ = "")
  EnsureAdvapi32()

  Protected hKey.i
  If RegOpenKeyExW(#HKEY_CURRENT_USER, subKey$, 0, #KEY_READ, @hKey) <> 0
    ProcedureReturn defaultValue$
  EndIf

  Protected typ.l, bytes.l
  If RegQueryValueExW(hKey, valueName$, 0, @typ, 0, @bytes) <> 0 Or bytes <= 0
    RegCloseKey(hKey)
    ProcedureReturn defaultValue$
  EndIf

  Protected *buf = AllocateMemory(bytes)
  If *buf = 0
    RegCloseKey(hKey)
    ProcedureReturn defaultValue$
  EndIf

  If RegQueryValueExW(hKey, valueName$, 0, @typ, *buf, @bytes) <> 0
    FreeMemory(*buf)
    RegCloseKey(hKey)
    ProcedureReturn defaultValue$
  EndIf

  Protected result$ = PeekS(*buf, -1, #PB_Unicode)
  FreeMemory(*buf)
  RegCloseKey(hKey)

  If typ <> #REG_SZ And typ <> #REG_EXPAND_SZ
    ProcedureReturn defaultValue$
  EndIf

  ProcedureReturn result$
EndProcedure

Procedure.i RegReadDword(subKey$, valueName$, defaultValue.i)
  EnsureAdvapi32()

  Protected hKey.i
  If RegOpenKeyExW(#HKEY_CURRENT_USER, subKey$, 0, #KEY_READ, @hKey) <> 0
    ProcedureReturn defaultValue
  EndIf

  Protected typ.l, bytes.l = SizeOf(Long), v.l
  If RegQueryValueExW(hKey, valueName$, 0, @typ, @v, @bytes) <> 0 Or typ <> #REG_DWORD
    RegCloseKey(hKey)
    ProcedureReturn defaultValue
  EndIf

  RegCloseKey(hKey)
  ProcedureReturn v
EndProcedure

Procedure.i RegDeleteValue(subKey$, valueName$)
  EnsureAdvapi32()

  Protected hKey.i
  If RegOpenKeyExW(#HKEY_CURRENT_USER, subKey$, 0, #KEY_WRITE, @hKey) <> 0
    ProcedureReturn #False
  EndIf

  Protected ok = Bool(RegDeleteValueW(hKey, valueName$) = 0)
  RegCloseKey(hKey)
  ProcedureReturn ok
EndProcedure

; -----------------------------
; Simple admin check + elevation
; -----------------------------
; Uses shell32.dll via dynamic loading to avoid linker issues.

Prototype.i ProtoIsUserAnAdmin()
Prototype.i ProtoShellExecuteW(hwnd.i, lpOperation.p-unicode, lpFile.p-unicode, lpParameters.p-unicode, lpDirectory.p-unicode, nShowCmd.i)
Prototype.i ProtoGetSystemTimes(*lpIdleTime.FileTimeCompat, *lpKernelTime.FileTimeCompat, *lpUserTime.FileTimeCompat)
Prototype.i ProtoGetSystemPowerStatus(*lpSystemPowerStatus.SystemPowerStatusCompat)

Global gShell32.i
Global IsUserAnAdmin.ProtoIsUserAnAdmin
Global ShellExecuteW.ProtoShellExecuteW
Global gKernel32.i
Global GetSystemTimesAPI.ProtoGetSystemTimes
Global GetSystemPowerStatusAPI.ProtoGetSystemPowerStatus

Procedure SetupShell32()
  If gShell32
    ProcedureReturn
  EndIf

  gShell32 = OpenLibrary(#PB_Any, "shell32.dll")
  If gShell32
    IsUserAnAdmin = GetFunction(gShell32, "IsUserAnAdmin")
    ShellExecuteW = GetFunction(gShell32, "ShellExecuteW")
  EndIf
EndProcedure

Procedure SetupKernel32()
  If gKernel32
    ProcedureReturn
  EndIf

  gKernel32 = OpenLibrary(#PB_Any, "kernel32.dll")
  If gKernel32
    GetSystemTimesAPI = GetFunction(gKernel32, "GetSystemTimes")
    GetSystemPowerStatusAPI = GetFunction(gKernel32, "GetSystemPowerStatus")
  EndIf
EndProcedure

Procedure EnsureKernel32Telemetry()
  SetupKernel32()
  If gKernel32 = 0 Or GetSystemTimesAPI = 0 Or GetSystemPowerStatusAPI = 0
    gTelemetryAvailable = #False
  EndIf
EndProcedure

Procedure EnsureAdmin()
  SetupShell32()
  If IsUserAnAdmin = 0 Or ShellExecuteW = 0
    LogLine(#LOG_ERROR, "Failed to load required functions from shell32.dll")
    MessageRequester("Error", "Failed to load required functions from shell32.dll.", #PB_MessageRequester_Error)
    CloseHandle_(hMutex)
    End
  EndIf

  If IsUserAnAdmin() = 0
    Protected exe$ = ProgramFilename()
    LogLine(#LOG_WARN, "Not elevated; requesting UAC via ShellExecute runas")
    ShellExecuteW(0, "runas", exe$, "", GetPathPart(exe$), 1)
    CloseHandle_(hMutex)
    End
  EndIf

  LogLine(#LOG_INFO, "Running elevated")
EndProcedure

; -----------------------------
; command helpers
; -----------------------------

Global gLastExitCode.i

Structure ProgramCaptureResult
  ExitCode.i
  Win32Error.i
EndStructure

Procedure.s RunProgramCaptureEx(program$, args$, *result.ProgramCaptureResult)
  Protected exitCode.i = -1
  Protected win32Error.i = 0
  Protected stdout$ = ""

  LogLine(#LOG_DEBUG, "exec: " + program$ + " " + args$)

  ; Use cmd.exe to redirect stderr to stdout so we can always capture output.
  ; Important: cmd quoting must be: /S /C ""program" args 2>&1"
  Protected cmdArgs$ = "/S /C " + Chr(34) + Chr(34) + program$ + Chr(34) + " " + args$ + " 2>&1" + Chr(34)
  LogLine(#LOG_DEBUG, "cmd.exe args: " + cmdArgs$)

  Protected flags = #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read
  Protected prog = RunProgram("cmd.exe", cmdArgs$, "", flags)
  If prog = 0
    win32Error = GetLastError_()
    LogLine(#LOG_ERROR, "failed to start: " + program$ + " err=" + WinErrorMessage(win32Error))
    If *result
      *result\ExitCode = -1
      *result\Win32Error = win32Error
    EndIf
    ProcedureReturn ""
  EndIf

  While ProgramRunning(prog)
    While AvailableProgramOutput(prog)
      stdout$ + ReadProgramString(prog) + #LF$
    Wend
    Delay(5)
  Wend

  While AvailableProgramOutput(prog)
    stdout$ + ReadProgramString(prog) + #LF$
  Wend

  exitCode = ProgramExitCode(prog)
  CloseProgram(prog)

  If exitCode <> 0
    LogLine(#LOG_WARN, "exit=" + Str(exitCode) + " cmd=" + program$ + " " + args$)
  Else
    LogLine(#LOG_DEBUG, "ok exit=0")
  EndIf

  If *result
    *result\ExitCode = exitCode
    *result\Win32Error = win32Error
  EndIf

  ProcedureReturn stdout$
EndProcedure

Procedure.s RunProgramCapture(program$, args$)
  ; Captures combined stdout+stderr (2>&1) into gLastStdout.
  ; Note: this PB build doesn't expose separate stderr read APIs.
  Protected result.ProgramCaptureResult

  gLastExitCode = -1
  gLastWin32Error = 0
  gLastStdout = RunProgramCaptureEx(program$, args$, @result)
  gLastStderr = ""
  gLastExitCode = result\ExitCode
  gLastWin32Error = result\Win32Error

  ProcedureReturn gLastStdout
EndProcedure

Procedure.s RunPowerCfg(args$)
  Protected out$ = RunProgramCapture("powercfg", args$)
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "powercfg failed: args='" + args$ + "' exit=" + Str(gLastExitCode))
    If gLastStdout <> "" : LogLine(#LOG_ERROR, "output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
  EndIf
  ProcedureReturn out$
EndProcedure

Procedure.s ExtractGuidAfter(text$, marker$)
  Protected p = FindString(text$, marker$, 1)
  If p = 0 : ProcedureReturn "" : EndIf

  Protected rest$ = Mid(text$, p + Len(marker$))
  rest$ = Trim(rest$)

  ; GUID is the first token
  Protected spacePos = FindString(rest$, " ", 1)
  If spacePos > 0
    ProcedureReturn Trim(Left(rest$, spacePos - 1))
  EndIf

  ProcedureReturn Trim(rest$)
EndProcedure

Procedure.s TrimSchemeGuidFromDuplicateOutput(text$)
  ; Example output:
  ; "Power Scheme GUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  (Name)"
  ProcedureReturn ExtractGuidAfter(text$, "GUID:")
EndProcedure

Procedure.i SchemeExists(scheme$)
  scheme$ = Trim(scheme$)
  If scheme$ = ""
    ProcedureReturn #False
  EndIf

  Protected out$ = RunPowerCfg("-list")
  If gLastExitCode <> 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(FindString(LCase(out$), LCase(scheme$), 1) > 0)
EndProcedure

Procedure.s EnsureCustomScheme(customName$, iniPath$)
  Protected scheme$ = ""

  LogLine(#LOG_INFO, "Ensuring custom power scheme for '" + customName$ + "'")

  ; Prefer registry-stored SchemeGuid if present
  scheme$ = RegReadString(#REG_BASE$ + "\\Settings", "SchemeGuid", "")

  ; Backward compatible INI location
  If scheme$ = "" And OpenPreferences(iniPath$)
    PreferenceGroup("Settings")
    scheme$ = ReadPreferenceString("SchemeGuid", "")
    ClosePreferences()
  EndIf

  If scheme$ <> "" And SchemeExists(scheme$)
    ProcedureReturn scheme$
  EndIf

  If scheme$ <> ""
    LogLine(#LOG_WARN, "Stored custom scheme not found; recreating")
    scheme$ = ""
  EndIf

  ; Duplicate Balanced scheme
  Protected out$ = RunPowerCfg("-duplicatescheme " + #SCHEME_BALANCED$)
  scheme$ = TrimSchemeGuidFromDuplicateOutput(out$)

  If scheme$ = "" Or gLastExitCode <> 0
    LogLine(#LOG_ERROR, "Failed to duplicate Balanced scheme. exit=" + Str(gLastExitCode))
    If gLastStdout <> "" : LogLine(#LOG_ERROR, "stdout: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
    If gLastStderr <> "" : LogLine(#LOG_ERROR, "stderr: " + ReplaceString(Trim(gLastStderr), #CRLF$, " | ")) : EndIf

    MessageRequester("Error", "Couldn't create a custom power scheme." + #CRLF$ +
                              "Exit code: " + Str(gLastExitCode) + #CRLF$ +
                              "Output: " + out$, #PB_MessageRequester_Error)
    CloseHandle_(hMutex)
    End
  EndIf

  LogLine(#LOG_INFO, "Created custom scheme GUID=" + scheme$)

  ; Rename it for clarity
  RunPowerCfg("-changename " + scheme$ + " " + Chr(34) + customName$ + Chr(34))

  ; Save scheme GUID so we reuse the same plan later
  Protected settings.AppSettings
  LoadAppSettings(iniPath$, @settings)
  settings\SchemeGuid = scheme$
  SaveAppSettings(iniPath$, @settings)

  ProcedureReturn scheme$
EndProcedure

Procedure.i SupportsBoostModeSetting(scheme$)
  ; Prefer a deterministic check: query just that setting.
  ; If the setting is unsupported/hidden, powercfg typically returns non-zero.
  Protected out$ = RunPowerCfg("-q " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$)

  If gLastExitCode <> 0
    ProcedureReturn #False
  EndIf

  ; Also require the GUID to appear in output (language-independent)
  If FindString(out$, #SET_BOOST_MODE$, 1) = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i SupportsCoolingPolicySetting(scheme$)
  Protected out$ = RunPowerCfg("-q " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$)
  If gLastExitCode <> 0
    ProcedureReturn #False
  EndIf

  If FindString(out$, #SET_SYS_COOLING_POLICY$, 1) = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i SupportsASPMSetting(scheme$)
  Protected out$ = RunPowerCfg("-q " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$)
  If gLastExitCode <> 0
    ProcedureReturn #False
  EndIf

  If FindString(out$, #SET_ASPM$, 1) = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i ClampPercent(value.i, minValue.i = 1, maxValue.i = 100)
  If value < minValue
    ProcedureReturn minValue
  EndIf
  If value > maxValue
    ProcedureReturn maxValue
  EndIf
  ProcedureReturn value
EndProcedure

Procedure.i ProfileNameToId(name$)
  Select LCase(Trim(name$))
    Case "battery saver", "max battery saver", "battery"
      ProcedureReturn #PROFILE_BATTERY_SAVER
    Case "eco"
      ProcedureReturn #PROFILE_ECO
    Case "quiet"
      ProcedureReturn #PROFILE_QUIET
    Case "cool"
      ProcedureReturn #PROFILE_COOL
    Case "balanced"
      ProcedureReturn #PROFILE_BALANCED
    Case "performance", "perf"
      ProcedureReturn #PROFILE_PERFORMANCE
  EndSelect

  ProcedureReturn #PROFILE_COOL
EndProcedure

Procedure.s ProfileIdToName(profileId.i)
  Select profileId
    Case #PROFILE_BATTERY_SAVER
      ProcedureReturn "Battery Saver"
    Case #PROFILE_ECO
      ProcedureReturn "Eco"
    Case #PROFILE_QUIET
      ProcedureReturn "Quiet"
    Case #PROFILE_COOL
      ProcedureReturn "Cool"
    Case #PROFILE_BALANCED
      ProcedureReturn "Balanced"
    Case #PROFILE_PERFORMANCE
      ProcedureReturn "Performance"
  EndSelect

  ProcedureReturn "Cool"
EndProcedure

Procedure LoadProfileDefaults(profileId.i, *acMax.Integer, *dcMax.Integer, *acMin.Integer, *dcMin.Integer,
                              *acBoostValue.Integer, *dcBoostValue.Integer,
                              *acCoolingPolicy.Integer, *dcCoolingPolicy.Integer,
                              *acASPMValue.Integer, *dcASPMValue.Integer)
  If *acMax = 0 Or *dcMax = 0 Or *acMin = 0 Or *dcMin = 0 Or
     *acBoostValue = 0 Or *dcBoostValue = 0 Or
     *acCoolingPolicy = 0 Or *dcCoolingPolicy = 0 Or
     *acASPMValue = 0 Or *dcASPMValue = 0
    ProcedureReturn
  EndIf

  Select profileId
    Case #PROFILE_BATTERY_SAVER
      *acMax\i = 65 : *dcMax\i = 50 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_DISABLED : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 1 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 2 : *dcASPMValue\i = 2
    Case #PROFILE_ECO
      *acMax\i = 75 : *dcMax\i = 60 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_DISABLED : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 1 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 2 : *dcASPMValue\i = 2
    Case #PROFILE_QUIET
      *acMax\i = 85 : *dcMax\i = 70 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_DISABLED : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 1 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 2 : *dcASPMValue\i = 2
    Case #PROFILE_COOL
      *acMax\i = 99 : *dcMax\i = 80 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_DISABLED : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 0 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 1 : *dcASPMValue\i = 2
    Case #PROFILE_BALANCED
      *acMax\i = 100 : *dcMax\i = 85 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_EFFICIENT : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 0 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 1 : *dcASPMValue\i = 2
    Case #PROFILE_PERFORMANCE
      *acMax\i = 100 : *dcMax\i = 100 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_EFFICIENT_AGGRESSIVE : *dcBoostValue\i = #BOOST_EFFICIENT
      *acCoolingPolicy\i = 0 : *dcCoolingPolicy\i = 0
      *acASPMValue\i = 0 : *dcASPMValue\i = 1
    Default
      *acMax\i = 99 : *dcMax\i = 80 : *acMin\i = 5 : *dcMin\i = 5
      *acBoostValue\i = #BOOST_DISABLED : *dcBoostValue\i = #BOOST_DISABLED
      *acCoolingPolicy\i = 0 : *dcCoolingPolicy\i = 1
      *acASPMValue\i = 1 : *dcASPMValue\i = 2
  EndSelect
EndProcedure

Procedure ApplyProfileToSettings(profileId.i, *settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                      @acBoostValue, @dcBoostValue,
                      @acCoolingPolicy, @dcCoolingPolicy,
                      @acASPMValue, @dcASPMValue)
  *settings\ACMaxCPU = acMax\i
  *settings\DCMaxCPU = dcMax\i
  *settings\ACMinCPU = acMin\i
  *settings\DCMinCPU = dcMin\i
  *settings\ACBoostMode = acBoostValue\i
  *settings\DCBoostMode = dcBoostValue\i
  *settings\ACCoolingPolicy = acCoolingPolicy\i
  *settings\DCCoolingPolicy = dcCoolingPolicy\i
  *settings\ACASPMMode = acASPMValue\i
  *settings\DCASPMMode = dcASPMValue\i
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
EndProcedure

Structure ApplyDiagnostics
  SuccessCount.i
  FailureCount.i
  Summary.s
  Details.s
EndStructure

#VERIFY_NOT_FOUND = -2147483647

Procedure AppendDiagnosticDetail(*diag.ApplyDiagnostics, line$)
  If *diag = 0 Or line$ = ""
    ProcedureReturn
  EndIf

  If *diag\Details <> ""
    *diag\Details + #CRLF$
  EndIf
  *diag\Details + line$
EndProcedure

Procedure AddApplyResult(*diag.ApplyDiagnostics, success.i, label$, details$ = "")
  If *diag = 0
    ProcedureReturn
  EndIf

  If success
    *diag\SuccessCount + 1
  Else
    *diag\FailureCount + 1
    If details$ = ""
      AppendDiagnosticDetail(*diag, label$)
    Else
      AppendDiagnosticDetail(*diag, label$ + ": " + details$)
    EndIf
  EndIf
EndProcedure

Procedure.i ParsePowerCfgCurrentValue(text$, isAC.i)
  Protected marker$
  Protected p.i
  Protected line$
  Protected value$

  If isAC
    marker$ = "Current AC Power Setting Index:"
  Else
    marker$ = "Current DC Power Setting Index:"
  EndIf

  p = FindString(text$, marker$, 1)
  If p = 0
    ProcedureReturn #VERIFY_NOT_FOUND
  EndIf

  line$ = StringField(Mid(text$, p), 1, #LF$)
  value$ = Trim(RemoveString(line$, marker$))
  value$ = RemoveString(value$, "0x")
  value$ = RemoveString(value$, "0X")
  value$ = Trim(value$)
  If value$ = ""
    ProcedureReturn #VERIFY_NOT_FOUND
  EndIf

  ProcedureReturn Val("$" + value$)
EndProcedure

Procedure.i ReadCurrentSettingValue(scheme$, subgroup$, setting$, isAC.i)
  Protected out$ = RunPowerCfg("-q " + scheme$ + " " + subgroup$ + " " + setting$)
  If gLastExitCode <> 0
    ProcedureReturn #VERIFY_NOT_FOUND
  EndIf

  ProcedureReturn ParsePowerCfgCurrentValue(out$, isAC)
EndProcedure

Procedure VerifyAppliedSettings(scheme$, acMax.i, dcMax.i, acMin.i, dcMin.i,
                                acBoostValue.i, dcBoostValue.i, useBoost.i,
                                acCoolingPolicy.i, dcCoolingPolicy.i,
                                acASPMValue.i, dcASPMValue.i,
                                *diag.ApplyDiagnostics)
  Protected actualValue.i
  Protected mismatches.i

  actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_MAX_PROC_STATE$, #True)
  If actualValue = #VERIFY_NOT_FOUND
    AppendDiagnosticDetail(*diag, "Verify AC max CPU: unable to read back current value")
    mismatches + 1
  ElseIf actualValue <> ClampPercent(acMax)
    AppendDiagnosticDetail(*diag, "Verify AC max CPU: expected " + Str(ClampPercent(acMax)) + ", got " + Str(actualValue))
    mismatches + 1
  EndIf

  actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_MAX_PROC_STATE$, #False)
  If actualValue = #VERIFY_NOT_FOUND
    AppendDiagnosticDetail(*diag, "Verify DC max CPU: unable to read back current value")
    mismatches + 1
  ElseIf actualValue <> ClampPercent(dcMax)
    AppendDiagnosticDetail(*diag, "Verify DC max CPU: expected " + Str(ClampPercent(dcMax)) + ", got " + Str(actualValue))
    mismatches + 1
  EndIf

  actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_MIN_PROC_STATE$, #True)
  If actualValue = #VERIFY_NOT_FOUND
    AppendDiagnosticDetail(*diag, "Verify AC min CPU: unable to read back current value")
    mismatches + 1
  ElseIf actualValue <> ClampPercent(acMin)
    AppendDiagnosticDetail(*diag, "Verify AC min CPU: expected " + Str(ClampPercent(acMin)) + ", got " + Str(actualValue))
    mismatches + 1
  EndIf

  actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_MIN_PROC_STATE$, #False)
  If actualValue = #VERIFY_NOT_FOUND
    AppendDiagnosticDetail(*diag, "Verify DC min CPU: unable to read back current value")
    mismatches + 1
  ElseIf actualValue <> ClampPercent(dcMin)
    AppendDiagnosticDetail(*diag, "Verify DC min CPU: expected " + Str(ClampPercent(dcMin)) + ", got " + Str(actualValue))
    mismatches + 1
  EndIf

  If useBoost
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_BOOST_MODE$, #True)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify AC boost mode: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> acBoostValue
      AppendDiagnosticDetail(*diag, "Verify AC boost mode: expected " + Str(acBoostValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf

    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_BOOST_MODE$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC boost mode: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> dcBoostValue
      AppendDiagnosticDetail(*diag, "Verify DC boost mode: expected " + Str(dcBoostValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If acCoolingPolicy >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_SYS_COOLING_POLICY$, #True)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify AC cooling policy: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> acCoolingPolicy
      AppendDiagnosticDetail(*diag, "Verify AC cooling policy: expected " + Str(acCoolingPolicy) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If dcCoolingPolicy >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_SYS_COOLING_POLICY$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC cooling policy: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> dcCoolingPolicy
      AppendDiagnosticDetail(*diag, "Verify DC cooling policy: expected " + Str(dcCoolingPolicy) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If acASPMValue >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PCIE$, #SET_ASPM$, #True)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify AC ASPM: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> acASPMValue
      AppendDiagnosticDetail(*diag, "Verify AC ASPM: expected " + Str(acASPMValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If dcASPMValue >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PCIE$, #SET_ASPM$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC ASPM: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> dcASPMValue
      AppendDiagnosticDetail(*diag, "Verify DC ASPM: expected " + Str(dcASPMValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If *diag
    If mismatches = 0
      If *diag\Details <> ""
        AppendDiagnosticDetail(*diag, "Verification: settings read back correctly.")
      Else
        *diag\Details = "Verification: settings read back correctly."
      EndIf
    ElseIf *diag\FailureCount = 0
      *diag\FailureCount = mismatches
      *diag\Summary = "Applied, but verification found mismatches."
    EndIf
  EndIf
EndProcedure

Procedure.i RunPowerCfgStep(*diag.ApplyDiagnostics, label$, args$)
  Protected out$ = RunPowerCfg(args$)
  Protected success.i = Bool(gLastExitCode = 0)
  Protected details$ = ReplaceString(Trim(out$), #CRLF$, " | ")
  If success = #False And details$ = ""
    details$ = WinErrorMessage(gLastWin32Error)
  EndIf
  AddApplyResult(*diag, success, label$, details$)
  ProcedureReturn success
EndProcedure


Procedure ApplySettings(scheme$, acMax.i, dcMax.i, acMin.i, dcMin.i,
                        acBoostValue.i, dcBoostValue.i, useBoost.i,
                        acCoolingPolicy.i, dcCoolingPolicy.i,
                        acASPMValue.i, dcASPMValue.i,
                        *diag.ApplyDiagnostics = 0)
  LogLine(#LOG_INFO, "ApplySettings scheme=" + scheme$ +
                     " acMax=" + Str(acMax) + " dcMax=" + Str(dcMax) +
                     " acMin=" + Str(acMin) + " dcMin=" + Str(dcMin) +
                     " acBoost=" + Str(acBoostValue) + " dcBoost=" + Str(dcBoostValue) + " useBoost=" + Str(useBoost) +
                     " acCooling=" + Str(acCoolingPolicy) + " dcCooling=" + Str(dcCoolingPolicy) +
                     " acASPM=" + Str(acASPMValue) + " dcASPM=" + Str(dcASPMValue))

  ; clamp
  acMax = ClampPercent(acMax)
  dcMax = ClampPercent(dcMax)
  acMin = ClampPercent(acMin)
  dcMin = ClampPercent(dcMin)
  If acMin > acMax : acMin = acMax : EndIf
  If dcMin > dcMax : dcMin = dcMax : EndIf

  RunPowerCfgStep(*diag, "Set AC max CPU", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MAX_PROC_STATE$ + " " + Str(acMax))
  RunPowerCfgStep(*diag, "Set DC max CPU", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MAX_PROC_STATE$ + " " + Str(dcMax))
  RunPowerCfgStep(*diag, "Set AC min CPU", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MIN_PROC_STATE$ + " " + Str(acMin))
  RunPowerCfgStep(*diag, "Set DC min CPU", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MIN_PROC_STATE$ + " " + Str(dcMin))

  If useBoost
    RunPowerCfgStep(*diag, "Set AC boost mode", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(acBoostValue))
    RunPowerCfgStep(*diag, "Set DC boost mode", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(dcBoostValue))
  EndIf


  ; Cooling policy (0=Active (fan first), 1=Passive (throttle first))
  If acCoolingPolicy >= 0
    If acCoolingPolicy <> 0 And acCoolingPolicy <> 1
      acCoolingPolicy = 0
    EndIf
    RunPowerCfgStep(*diag, "Set AC cooling policy", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(acCoolingPolicy))
  EndIf
  If dcCoolingPolicy >= 0
    If dcCoolingPolicy <> 0 And dcCoolingPolicy <> 1
      dcCoolingPolicy = 1
    EndIf
    RunPowerCfgStep(*diag, "Set DC cooling policy", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(dcCoolingPolicy))
  EndIf

  ; ASPM (0=Off, 1=Moderate, 2=Maximum)
  If acASPMValue >= 0
    If acASPMValue > 2
      acASPMValue = 2
    EndIf
    RunPowerCfgStep(*diag, "Set AC ASPM", "-setacvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(acASPMValue))
  EndIf
  If dcASPMValue >= 0
    If dcASPMValue > 2
      dcASPMValue = 2
    EndIf
    RunPowerCfgStep(*diag, "Set DC ASPM", "-setdcvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(dcASPMValue))
  EndIf

  ; activate scheme
  RunPowerCfgStep(*diag, "Activate power scheme", "-S " + scheme$)
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "Failed to activate scheme. exit=" + Str(gLastExitCode))
  EndIf

  VerifyAppliedSettings(scheme$, acMax, dcMax, acMin, dcMin,
                        acBoostValue, dcBoostValue, useBoost,
                        acCoolingPolicy, dcCoolingPolicy,
                        acASPMValue, dcASPMValue,
                        *diag)

  If *diag
    If *diag\FailureCount = 0
      *diag\Summary = "Applied successfully."
    ElseIf *diag\SuccessCount = 0
      *diag\Summary = "Apply failed."
    Else
      *diag\Summary = "Applied with some errors."
    EndIf
  EndIf
EndProcedure

Procedure RestoreBalanced()
  LogLine(#LOG_INFO, "Restoring Windows Balanced plan")
  RunPowerCfg("-S " + #SCHEME_BALANCED$)
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "Failed to restore Balanced. exit=" + Str(gLastExitCode))
  EndIf
EndProcedure

Procedure RefreshTelemetryThread(*unused)
  Protected idle.FileTimeCompat
  Protected kernel.FileTimeCompat
  Protected user.FileTimeCompat
  Protected cpuIdle.q
  Protected cpuKernel.q
  Protected cpuUser.q
  Protected totalDelta.q
  Protected idleDelta.q
  Protected cpuLoad.d
  Protected powerStatus.SystemPowerStatusCompat
  Protected ps$
  Protected result.ProgramCaptureResult
  Protected out$
  Protected thermalLine$
  Protected thermalPos.i

  gTelemetry\ErrorText = ""
  EnsureKernel32Telemetry()

  If GetSystemTimesAPI And GetSystemTimesAPI(@idle, @kernel, @user)
    cpuIdle = FileTimeToQuad(@idle)
    cpuKernel = FileTimeToQuad(@kernel)
    cpuUser = FileTimeToQuad(@user)

    If gCpuTimesReady
      totalDelta = (cpuKernel - gLastCpuKernelTime) + (cpuUser - gLastCpuUserTime)
      idleDelta = cpuIdle - gLastCpuIdleTime
      If totalDelta > 0
        cpuLoad = 100.0 - ((idleDelta * 100.0) / totalDelta)
        If cpuLoad < 0.0 : cpuLoad = 0.0 : EndIf
        If cpuLoad > 100.0 : cpuLoad = 100.0 : EndIf
        gTelemetry\CpuLoad = StrD(cpuLoad, 1)
      EndIf
    ElseIf gTelemetry\CpuLoad = ""
      gTelemetry\CpuLoad = "0.0"
    EndIf

    gLastCpuIdleTime = cpuIdle
    gLastCpuKernelTime = cpuKernel
    gLastCpuUserTime = cpuUser
    gCpuTimesReady = #True
  Else
    gTelemetry\CpuLoad = "Unavailable"
  EndIf

  If GetSystemPowerStatusAPI And GetSystemPowerStatusAPI(@powerStatus)
    Select powerStatus\ACLineStatus
      Case 0
        gTelemetry\PowerSource = "Battery"
      Case 1
        If (powerStatus\BatteryFlag & 8) <> 0
          gTelemetry\PowerSource = "Charging"
        Else
          gTelemetry\PowerSource = "AC"
        EndIf
      Default
        gTelemetry\PowerSource = "Unknown"
    EndSelect
  Else
    gTelemetry\PowerSource = "Unknown"
  EndIf

  If gLastThermalRefreshTime = 0 Or Date() - gLastThermalRefreshTime >= #THERMAL_REFRESH_SECONDS
    ps$ = "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) +
          "$tz=Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | Select-Object -First 1;" +
          "$temp='Unavailable';" +
          "if($tz -and $tz.CurrentTemperature){$temp=[math]::Round(($tz.CurrentTemperature / 10) - 273.15,1)};" +
          "Write-Output ('ThermalC=' + $temp)" + Chr(34)

    out$ = RunProgramCaptureEx("powershell.exe", ps$, @result)
    thermalLine$ = ""
    thermalPos = FindString(out$, "ThermalC=", 1)
    If thermalPos > 0
      thermalLine$ = Trim(StringField(Mid(out$, thermalPos), 1, #LF$))
      gCachedThermalC = Trim(Mid(thermalLine$, Len("ThermalC=") + 1))
      If gCachedThermalC = ""
        gCachedThermalC = "Unavailable"
      EndIf
    ElseIf result\ExitCode <> 0
      LogLine(#LOG_WARN, "Thermal telemetry refresh failed exit=" + Str(result\ExitCode))
    EndIf
    gLastThermalRefreshTime = Date()
  EndIf

  gTelemetry\ThermalC = gCachedThermalC
  gTelemetry\LastUpdated = FormatDate("%hh:%ii:%ss", Date())
  gTelemetryBusy = #False
EndProcedure

Procedure StartTelemetryRefresh()
  If gTelemetryBusy
    ProcedureReturn
  EndIf

  gTelemetryBusy = #True
  gTelemetryThread = CreateThread(@RefreshTelemetryThread(), 0)
  If gTelemetryThread = 0
    gTelemetryBusy = #False
    gTelemetry\ErrorText = "Telemetry unavailable"
    LogLine(#LOG_WARN, "Failed to create telemetry thread")
  EndIf
EndProcedure


; -----------------------------
; Preferences + system info
; -----------------------------


Procedure.s IniEscape(value$)
  value$ = ReplaceString(value$, #CRLF$, " ")
  value$ = ReplaceString(value$, #CR$, " ")
  value$ = ReplaceString(value$, #LF$, " ")
  ProcedureReturn Trim(value$)
EndProcedure

Structure SystemInfoData
  cpu.s
  memBytes.s
  osCaption.s
  osArch.s
  osBuild.s
  osVer.s
  lastUpdated.s
  iniPath.s
EndStructure

Global gSysInfoData.SystemInfoData

Procedure SaveSystemInfoThread(*data.SystemInfoData)
  ; Use CIM via PowerShell; print as key=value for easy parsing.
  LogLine(#LOG_INFO, "Collecting system info via PowerShell (threaded)")
  Protected ps$ = "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) +
                  "$cpu=(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name);" +
                  "$mem=(Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory);" +
                  "$os=(Get-CimInstance Win32_OperatingSystem);" +
                  "$arch=$os.OSArchitecture;" +
                  "$caption=$os.Caption;" +
                  "$build=$os.BuildNumber;" +
                  "$ver=$os.Version;" +
                  "Write-Output ('CPU=' + $cpu);" +
                  "Write-Output ('MemoryBytes=' + $mem);" +
                  "Write-Output ('OSCaption=' + $caption);" +
                  "Write-Output ('OSArchitecture=' + $arch);" +
                  "Write-Output ('OSBuild=' + $build);" +
                  "Write-Output ('OSVersion=' + $ver)" + Chr(34)

  Protected result.ProgramCaptureResult
  Protected out$ = RunProgramCaptureEx("powershell.exe", ps$, @result)
  If result\ExitCode <> 0
    LogLine(#LOG_WARN, "PowerShell system info exit=" + Str(result\ExitCode))
    If out$ <> "" : LogLine(#LOG_WARN, "output: " + ReplaceString(Trim(out$), #CRLF$, " | ")) : EndIf
  EndIf

  Protected i, line$, k$, v$
  Protected lines = CountString(out$, #LF$) + 1

  For i = 1 To lines
    line$ = Trim(StringField(out$, i, #LF$))
    If line$ = "" : Continue : EndIf

    k$ = StringField(line$, 1, "=")
    v$ = ""
    If FindString(line$, "=", 1)
      v$ = Mid(line$, FindString(line$, "=", 1) + 1)
    EndIf

    Select LCase(k$)
      Case "cpu"            : *data\cpu = v$
      Case "memorybytes"    : *data\memBytes = v$
      Case "oscaption"      : *data\osCaption = v$
      Case "osarchitecture" : *data\osArch = v$
      Case "osbuild"        : *data\osBuild = v$
      Case "osversion"      : *data\osVer = v$
    EndSelect
  Next

  *data\lastUpdated = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date())

  ; Save to HKCU registry (primary)
  Protected sysKey$ = #REG_BASE$ + "\\SystemInfo"
  RegWriteString(sysKey$, "CPU", IniEscape(*data\cpu))
  RegWriteString(sysKey$, "MemoryBytes", IniEscape(*data\memBytes))
  RegWriteString(sysKey$, "OSCaption", IniEscape(*data\osCaption))
  RegWriteString(sysKey$, "OSArchitecture", IniEscape(*data\osArch))
  RegWriteString(sysKey$, "OSBuild", IniEscape(*data\osBuild))
  RegWriteString(sysKey$, "OSVersion", IniEscape(*data\osVer))
  RegWriteString(sysKey$, "LastUpdated", *data\lastUpdated)

  ; Also write to INI for easy viewing/backup
  If OpenPreferences(*data\iniPath)
    PreferenceGroup("SystemInfo")
    WritePreferenceString("CPU", IniEscape(*data\cpu))
    WritePreferenceString("MemoryBytes", IniEscape(*data\memBytes))
    WritePreferenceString("OSCaption", IniEscape(*data\osCaption))
    WritePreferenceString("OSArchitecture", IniEscape(*data\osArch))
    WritePreferenceString("OSBuild", IniEscape(*data\osBuild))
    WritePreferenceString("OSVersion", IniEscape(*data\osVer))
    WritePreferenceString("LastUpdated", *data\lastUpdated)
    ClosePreferences()
  EndIf
  LogLine(#LOG_INFO, "System info collection complete")
EndProcedure

Procedure StartSystemInfoUpdate(iniPath$)
  gSysInfoData\iniPath = iniPath$
  CreateThread(@SaveSystemInfoThread(), @gSysInfoData)
EndProcedure

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 36
; Folding = ---------
; EnableXP
; DPIAware