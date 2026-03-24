EnableExplicit

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
Global version.s = "v1.0.0.5"

; Registry base key (HKCU)
#APP_NAME = "MyCPUCooler"
#REG_BASE$ = "Software\" + #APP_NAME
#HISTORY_POINTS = 36
#MAX_CUSTOM_PROFILES = 12
#BENCHMARK_MODE_SECONDS = 600

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
Global gACAUtoSwitchSince.i
Global gDCAUtoSwitchSince.i
Global gACAutoRestoreSince.i
Global gDCAutoRestoreSince.i
Global gLastManualACProfile.i
Global gLastManualDCProfile.i
Global gAutoSwitchedACProfile.i
Global gAutoSwitchedDCProfile.i
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

Procedure LogInit()
  ; Default log location: next to the exe (MyCPUCooler.log)
  ; Can be overridden with: --logfile <path>  (or --logfile=<path>)
  gLogPath = GetArgValue("--logfile")
  If gLogPath = ""
    gLogPath = GetPathPart(ProgramFilename()) + #APP_NAME + ".log"
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

Global gShell32.i
Global IsUserAnAdmin.ProtoIsUserAnAdmin
Global ShellExecuteW.ProtoShellExecuteW

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
  Protected ps$ = "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) +
                  "$cpu=(Get-Counter '\Processor Information(_Total)\\% Processor Utility' -ErrorAction SilentlyContinue).CounterSamples | Select-Object -First 1 -ExpandProperty CookedValue;" +
                  "if($null -eq $cpu){$cpu=(Get-Counter '\Processor(_Total)\\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples | Select-Object -First 1 -ExpandProperty CookedValue};" +
                  "$tz=Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue | Select-Object -First 1;" +
                  "$power=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1;" +
                  "$temp='Unavailable';" +
                  "if($tz -and $tz.CurrentTemperature){$temp=[math]::Round(($tz.CurrentTemperature / 10) - 273.15,1)};" +
                  "$source='AC';" +
                  "if($power){if($power.BatteryStatus -in 1,4,5,11){$source='Battery'}elseif($power.BatteryStatus -in 2,6,7,8,9){$source='Charging'}};" +
                  "if($null -eq $cpu){$cpu='Unavailable'}else{$cpu=[math]::Round($cpu,1)};" +
                  "Write-Output ('CpuLoad=' + $cpu);" +
                  "Write-Output ('ThermalC=' + $temp);" +
                  "Write-Output ('PowerSource=' + $source)" + Chr(34)

  Protected result.ProgramCaptureResult
  Protected out$ = RunProgramCaptureEx("powershell.exe", ps$, @result)
  Protected i.i
  Protected line$
  Protected key$
  Protected value$
  Protected lines.i = CountString(out$, #LF$) + 1

  gTelemetry\ErrorText = ""
  If result\ExitCode <> 0
    gTelemetry\ErrorText = "Telemetry unavailable"
    LogLine(#LOG_WARN, "Telemetry refresh failed exit=" + Str(result\ExitCode))
  EndIf

  For i = 1 To lines
    line$ = Trim(StringField(out$, i, #LF$))
    If line$ = "" Or FindString(line$, "=", 1) = 0
      Continue
    EndIf

    key$ = StringField(line$, 1, "=")
    value$ = Mid(line$, FindString(line$, "=", 1) + 1)

    Select LCase(key$)
      Case "cpuload"
        gTelemetry\CpuLoad = value$
      Case "thermalc"
        gTelemetry\ThermalC = value$
      Case "powersource"
        gTelemetry\PowerSource = value$
    EndSelect
  Next

  gTelemetry\LastUpdated = FormatDate("%hh:%ii:%ss", Date())
  gTelemetryBusy = #False
EndProcedure

Procedure StartTelemetryRefresh()
  If gTelemetryBusy
    ProcedureReturn
  EndIf

  gTelemetryBusy = #True
  gTelemetryThread = CreateThread(@RefreshTelemetryThread(), 0)
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


Procedure LoadAppSettings(iniPath$, *settings.AppSettings)
  ; defaults tuned for thin Intel H laptops (like GF63)
  *settings\ACProfile = #PROFILE_COOL
  *settings\DCProfile = #PROFILE_BALANCED
  ApplyProfileToSettings(#PROFILE_COOL, *settings)
  *settings\DCMaxCPU = 85
  *settings\AutoApply = 1
  *settings\LiveApply = 0
  *settings\RunAtStartup = 0
  *settings\UseTaskScheduler = 1
  *settings\HeatAlertEnabled = 1
  *settings\HeatAlertThreshold = 80
  *settings\AutoThermalSwitchEnabled = 0
  *settings\AutoThermalSwitchProfile = #PROFILE_COOL
  *settings\AutoThermalSwitchSeconds = 30
  *settings\StartupMode = 0
  *settings\AutoRestoreEnabled = 1
  *settings\AutoRestoreThreshold = 70
  *settings\AutoRestoreSeconds = 45
  *settings\ACAutoSwitchEnabled = 0
  *settings\DCAutoSwitchEnabled = 1
  *settings\ACAutoSwitchProfile = #PROFILE_QUIET
  *settings\DCAutoSwitchProfile = #PROFILE_BATTERY_SAVER
  *settings\ACAutoSwitchThreshold = 85
  *settings\DCAutoSwitchThreshold = 80
  *settings\ACAutoSwitchSeconds = 30
  *settings\DCAutoSwitchSeconds = 20
  *settings\ACAutoRestoreEnabled = 1
  *settings\DCAutoRestoreEnabled = 1
  *settings\ACAutoRestoreThreshold = 72
  *settings\DCAutoRestoreThreshold = 68
  *settings\ACAutoRestoreSeconds = 45
  *settings\DCAutoRestoreSeconds = 60
  *settings\SchemeGuid = ""

  ; Registry first
  Protected settingsKey$ = #REG_BASE$ + "\\Settings"
  *settings\SchemeGuid = RegReadString(settingsKey$, "SchemeGuid", *settings\SchemeGuid)
  *settings\ACMaxCPU   = RegReadDword(settingsKey$, "AC_MaxCPU", *settings\ACMaxCPU)
  *settings\DCMaxCPU   = RegReadDword(settingsKey$, "DC_MaxCPU", *settings\DCMaxCPU)
  *settings\ACMinCPU   = RegReadDword(settingsKey$, "AC_MinCPU", *settings\ACMinCPU)
  *settings\DCMinCPU   = RegReadDword(settingsKey$, "DC_MinCPU", *settings\DCMinCPU)
  *settings\ACProfile  = RegReadDword(settingsKey$, "AC_Profile", *settings\ACProfile)
  *settings\DCProfile  = RegReadDword(settingsKey$, "DC_Profile", *settings\DCProfile)
  *settings\BoostMode  = RegReadDword(settingsKey$, "BoostMode", *settings\BoostMode)
  *settings\CoolingPolicy = RegReadDword(settingsKey$, "CoolingPolicy", *settings\CoolingPolicy)
  *settings\ASPMMode   = RegReadDword(settingsKey$, "ASPMMode", *settings\ASPMMode)
  *settings\ACBoostMode = RegReadDword(settingsKey$, "AC_BoostMode", *settings\BoostMode)
  *settings\DCBoostMode = RegReadDword(settingsKey$, "DC_BoostMode", *settings\BoostMode)
  *settings\ACCoolingPolicy = RegReadDword(settingsKey$, "AC_CoolingPolicy", *settings\CoolingPolicy)
  *settings\DCCoolingPolicy = RegReadDword(settingsKey$, "DC_CoolingPolicy", *settings\CoolingPolicy)
  *settings\ACASPMMode = RegReadDword(settingsKey$, "AC_ASPMMode", *settings\ASPMMode)
  *settings\DCASPMMode = RegReadDword(settingsKey$, "DC_ASPMMode", *settings\ASPMMode)
  *settings\AutoApply  = RegReadDword(settingsKey$, "AutoApply", *settings\AutoApply)
  *settings\LiveApply  = RegReadDword(settingsKey$, "LiveApply", *settings\LiveApply)
  *settings\RunAtStartup     = RegReadDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  *settings\UseTaskScheduler = RegReadDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)
  *settings\HeatAlertEnabled = RegReadDword(settingsKey$, "HeatAlertEnabled", *settings\HeatAlertEnabled)
  *settings\HeatAlertThreshold = RegReadDword(settingsKey$, "HeatAlertThreshold", *settings\HeatAlertThreshold)
  *settings\AutoThermalSwitchEnabled = RegReadDword(settingsKey$, "AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
  *settings\AutoThermalSwitchProfile = RegReadDword(settingsKey$, "AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
  *settings\AutoThermalSwitchSeconds = RegReadDword(settingsKey$, "AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
  *settings\StartupMode = RegReadDword(settingsKey$, "StartupMode", *settings\StartupMode)
  *settings\AutoRestoreEnabled = RegReadDword(settingsKey$, "AutoRestoreEnabled", *settings\AutoRestoreEnabled)
  *settings\AutoRestoreThreshold = RegReadDword(settingsKey$, "AutoRestoreThreshold", *settings\AutoRestoreThreshold)
  *settings\AutoRestoreSeconds = RegReadDword(settingsKey$, "AutoRestoreSeconds", *settings\AutoRestoreSeconds)
  *settings\ACAutoSwitchEnabled = RegReadDword(settingsKey$, "ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
  *settings\DCAutoSwitchEnabled = RegReadDword(settingsKey$, "DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
  *settings\ACAutoSwitchProfile = RegReadDword(settingsKey$, "ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
  *settings\DCAutoSwitchProfile = RegReadDword(settingsKey$, "DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
  *settings\ACAutoSwitchThreshold = RegReadDword(settingsKey$, "ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
  *settings\DCAutoSwitchThreshold = RegReadDword(settingsKey$, "DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
  *settings\ACAutoSwitchSeconds = RegReadDword(settingsKey$, "ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
  *settings\DCAutoSwitchSeconds = RegReadDword(settingsKey$, "DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
  *settings\ACAutoRestoreEnabled = RegReadDword(settingsKey$, "ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
  *settings\DCAutoRestoreEnabled = RegReadDword(settingsKey$, "DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
  *settings\ACAutoRestoreThreshold = RegReadDword(settingsKey$, "ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
  *settings\DCAutoRestoreThreshold = RegReadDword(settingsKey$, "DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
  *settings\ACAutoRestoreSeconds = RegReadDword(settingsKey$, "ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
  *settings\DCAutoRestoreSeconds = RegReadDword(settingsKey$, "DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)

  ; INI fallback (older versions)
  If *settings\SchemeGuid = "" And FileSize(iniPath$) >= 0
    If OpenPreferences(iniPath$)
      PreferenceGroup("Settings")
      *settings\SchemeGuid = ReadPreferenceString("SchemeGuid", *settings\SchemeGuid)
      *settings\ACMaxCPU   = ReadPreferenceLong("AC_MaxCPU", *settings\ACMaxCPU)
      *settings\DCMaxCPU   = ReadPreferenceLong("DC_MaxCPU", *settings\DCMaxCPU)
      *settings\ACMinCPU   = ReadPreferenceLong("AC_MinCPU", *settings\ACMinCPU)
      *settings\DCMinCPU   = ReadPreferenceLong("DC_MinCPU", *settings\DCMinCPU)
      *settings\ACProfile  = ProfileNameToId(ReadPreferenceString("AC_Profile", ProfileIdToName(*settings\ACProfile)))
      *settings\DCProfile  = ProfileNameToId(ReadPreferenceString("DC_Profile", ProfileIdToName(*settings\DCProfile)))
      *settings\BoostMode    = ReadPreferenceLong("BoostMode", *settings\BoostMode)
      *settings\CoolingPolicy = ReadPreferenceLong("CoolingPolicy", *settings\CoolingPolicy)
      *settings\ASPMMode     = ReadPreferenceLong("ASPMMode", *settings\ASPMMode)
      *settings\ACBoostMode = ReadPreferenceLong("AC_BoostMode", *settings\BoostMode)
      *settings\DCBoostMode = ReadPreferenceLong("DC_BoostMode", *settings\BoostMode)
      *settings\ACCoolingPolicy = ReadPreferenceLong("AC_CoolingPolicy", *settings\CoolingPolicy)
      *settings\DCCoolingPolicy = ReadPreferenceLong("DC_CoolingPolicy", *settings\CoolingPolicy)
      *settings\ACASPMMode = ReadPreferenceLong("AC_ASPMMode", *settings\ASPMMode)
      *settings\DCASPMMode = ReadPreferenceLong("DC_ASPMMode", *settings\ASPMMode)
      *settings\AutoApply    = ReadPreferenceLong("AutoApply", *settings\AutoApply)
      *settings\LiveApply    = ReadPreferenceLong("LiveApply", *settings\LiveApply)
      *settings\RunAtStartup     = ReadPreferenceLong("RunAtStartup", *settings\RunAtStartup)
      *settings\UseTaskScheduler = ReadPreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
      *settings\HeatAlertEnabled = ReadPreferenceLong("HeatAlertEnabled", *settings\HeatAlertEnabled)
      *settings\HeatAlertThreshold = ReadPreferenceLong("HeatAlertThreshold", *settings\HeatAlertThreshold)
      *settings\AutoThermalSwitchEnabled = ReadPreferenceLong("AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
      *settings\AutoThermalSwitchProfile = ReadPreferenceLong("AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
      *settings\AutoThermalSwitchSeconds = ReadPreferenceLong("AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
      *settings\StartupMode = ReadPreferenceLong("StartupMode", *settings\StartupMode)
      *settings\AutoRestoreEnabled = ReadPreferenceLong("AutoRestoreEnabled", *settings\AutoRestoreEnabled)
      *settings\AutoRestoreThreshold = ReadPreferenceLong("AutoRestoreThreshold", *settings\AutoRestoreThreshold)
      *settings\AutoRestoreSeconds = ReadPreferenceLong("AutoRestoreSeconds", *settings\AutoRestoreSeconds)
      *settings\ACAutoSwitchEnabled = ReadPreferenceLong("ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
      *settings\DCAutoSwitchEnabled = ReadPreferenceLong("DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
      *settings\ACAutoSwitchProfile = ReadPreferenceLong("ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
      *settings\DCAutoSwitchProfile = ReadPreferenceLong("DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
      *settings\ACAutoSwitchThreshold = ReadPreferenceLong("ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
      *settings\DCAutoSwitchThreshold = ReadPreferenceLong("DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
      *settings\ACAutoSwitchSeconds = ReadPreferenceLong("ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
      *settings\DCAutoSwitchSeconds = ReadPreferenceLong("DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
      *settings\ACAutoRestoreEnabled = ReadPreferenceLong("ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
      *settings\DCAutoRestoreEnabled = ReadPreferenceLong("DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
      *settings\ACAutoRestoreThreshold = ReadPreferenceLong("ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
      *settings\DCAutoRestoreThreshold = ReadPreferenceLong("DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
      *settings\ACAutoRestoreSeconds = ReadPreferenceLong("ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
      *settings\DCAutoRestoreSeconds = ReadPreferenceLong("DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
      ClosePreferences()
    EndIf
  EndIf

  *settings\ACMaxCPU = ClampPercent(*settings\ACMaxCPU, 5, 100)
  *settings\DCMaxCPU = ClampPercent(*settings\DCMaxCPU, 5, 100)
  *settings\ACMinCPU = ClampPercent(*settings\ACMinCPU, 1, 100)
  *settings\DCMinCPU = ClampPercent(*settings\DCMinCPU, 1, 100)
  If *settings\ACMinCPU > *settings\ACMaxCPU : *settings\ACMinCPU = *settings\ACMaxCPU : EndIf
  If *settings\DCMinCPU > *settings\DCMaxCPU : *settings\DCMinCPU = *settings\DCMaxCPU : EndIf
  If *settings\ACCoolingPolicy <> 0 And *settings\ACCoolingPolicy <> 1 : *settings\ACCoolingPolicy = 0 : EndIf
  If *settings\DCCoolingPolicy <> 0 And *settings\DCCoolingPolicy <> 1 : *settings\DCCoolingPolicy = 1 : EndIf
  If *settings\ACASPMMode < 0 Or *settings\ACASPMMode > 2 : *settings\ACASPMMode = 1 : EndIf
  If *settings\DCASPMMode < 0 Or *settings\DCASPMMode > 2 : *settings\DCASPMMode = 2 : EndIf
  If *settings\ACBoostMode < #BOOST_DISABLED Or *settings\ACBoostMode > #BOOST_EFFICIENT_AGGRESSIVE : *settings\ACBoostMode = #BOOST_DISABLED : EndIf
  If *settings\DCBoostMode < #BOOST_DISABLED Or *settings\DCBoostMode > #BOOST_EFFICIENT_AGGRESSIVE : *settings\DCBoostMode = #BOOST_DISABLED : EndIf
  If *settings\HeatAlertThreshold < 60 : *settings\HeatAlertThreshold = 60 : EndIf
  If *settings\HeatAlertThreshold > 100 : *settings\HeatAlertThreshold = 100 : EndIf
  If *settings\AutoThermalSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\AutoThermalSwitchProfile > #PROFILE_PERFORMANCE : *settings\AutoThermalSwitchProfile = #PROFILE_COOL : EndIf
  If *settings\AutoThermalSwitchSeconds < 10 : *settings\AutoThermalSwitchSeconds = 10 : EndIf
  If *settings\AutoThermalSwitchSeconds > 120 : *settings\AutoThermalSwitchSeconds = 120 : EndIf
  If *settings\StartupMode < 0 Or *settings\StartupMode > 3 : *settings\StartupMode = 0 : EndIf
  If *settings\AutoRestoreThreshold < 50 : *settings\AutoRestoreThreshold = 50 : EndIf
  If *settings\AutoRestoreThreshold > 95 : *settings\AutoRestoreThreshold = 95 : EndIf
  If *settings\AutoRestoreSeconds < 15 : *settings\AutoRestoreSeconds = 15 : EndIf
  If *settings\AutoRestoreSeconds > 180 : *settings\AutoRestoreSeconds = 180 : EndIf
  If *settings\ACAutoSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\ACAutoSwitchProfile > #PROFILE_PERFORMANCE : *settings\ACAutoSwitchProfile = #PROFILE_QUIET : EndIf
  If *settings\DCAutoSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\DCAutoSwitchProfile > #PROFILE_PERFORMANCE : *settings\DCAutoSwitchProfile = #PROFILE_BATTERY_SAVER : EndIf
  If *settings\ACAutoSwitchThreshold < 60 : *settings\ACAutoSwitchThreshold = 60 : EndIf
  If *settings\ACAutoSwitchThreshold > 100 : *settings\ACAutoSwitchThreshold = 100 : EndIf
  If *settings\DCAutoSwitchThreshold < 60 : *settings\DCAutoSwitchThreshold = 60 : EndIf
  If *settings\DCAutoSwitchThreshold > 100 : *settings\DCAutoSwitchThreshold = 100 : EndIf
  If *settings\ACAutoSwitchSeconds < 10 : *settings\ACAutoSwitchSeconds = 10 : EndIf
  If *settings\ACAutoSwitchSeconds > 180 : *settings\ACAutoSwitchSeconds = 180 : EndIf
  If *settings\DCAutoSwitchSeconds < 10 : *settings\DCAutoSwitchSeconds = 10 : EndIf
  If *settings\DCAutoSwitchSeconds > 180 : *settings\DCAutoSwitchSeconds = 180 : EndIf
  If *settings\ACAutoRestoreThreshold < 50 : *settings\ACAutoRestoreThreshold = 50 : EndIf
  If *settings\ACAutoRestoreThreshold > 95 : *settings\ACAutoRestoreThreshold = 95 : EndIf
  If *settings\DCAutoRestoreThreshold < 50 : *settings\DCAutoRestoreThreshold = 50 : EndIf
  If *settings\DCAutoRestoreThreshold > 95 : *settings\DCAutoRestoreThreshold = 95 : EndIf
  If *settings\ACAutoRestoreSeconds < 15 : *settings\ACAutoRestoreSeconds = 15 : EndIf
  If *settings\ACAutoRestoreSeconds > 240 : *settings\ACAutoRestoreSeconds = 240 : EndIf
  If *settings\DCAutoRestoreSeconds < 15 : *settings\DCAutoRestoreSeconds = 15 : EndIf
  If *settings\DCAutoRestoreSeconds > 240 : *settings\DCAutoRestoreSeconds = 240 : EndIf
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
EndProcedure


Procedure SaveAppSettings(iniPath$, *settings.AppSettings)
  ; Persist app settings
  LogLine(#LOG_INFO, "SaveAppSettings" +
                      " acMax=" + Str(*settings\ACMaxCPU) + " dcMax=" + Str(*settings\DCMaxCPU) +
                      " acMin=" + Str(*settings\ACMinCPU) + " dcMin=" + Str(*settings\DCMinCPU) +
                      " acBoost=" + Str(*settings\ACBoostMode) + " dcBoost=" + Str(*settings\DCBoostMode) +
                      " acCooling=" + Str(*settings\ACCoolingPolicy) + " dcCooling=" + Str(*settings\DCCoolingPolicy) +
                      " acASPM=" + Str(*settings\ACASPMMode) + " dcASPM=" + Str(*settings\DCASPMMode) +
                      " autoApply=" + Str(*settings\AutoApply) + " liveApply=" + Str(*settings\LiveApply) +
                      " runAtStartup=" + Str(*settings\RunAtStartup) + " useTaskScheduler=" + Str(*settings\UseTaskScheduler) +
                      " heatAlertEnabled=" + Str(*settings\HeatAlertEnabled) + " heatAlertThreshold=" + Str(*settings\HeatAlertThreshold) +
                      " autoSwitchEnabled=" + Str(*settings\AutoThermalSwitchEnabled) + " autoSwitchProfile=" + Str(*settings\AutoThermalSwitchProfile) +
                      " autoSwitchSeconds=" + Str(*settings\AutoThermalSwitchSeconds) + " startupMode=" + Str(*settings\StartupMode) +
                      " autoRestoreEnabled=" + Str(*settings\AutoRestoreEnabled) + " autoRestoreThreshold=" + Str(*settings\AutoRestoreThreshold) +
                      " autoRestoreSeconds=" + Str(*settings\AutoRestoreSeconds) +
                      " acAutoSwitchProfile=" + Str(*settings\ACAutoSwitchProfile) + " dcAutoSwitchProfile=" + Str(*settings\DCAutoSwitchProfile) +
                      " acAutoSwitchThreshold=" + Str(*settings\ACAutoSwitchThreshold) + " dcAutoSwitchThreshold=" + Str(*settings\DCAutoSwitchThreshold))
  Protected settingsKey$ = #REG_BASE$ + "\\Settings"
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  RegWriteString(settingsKey$, "SchemeGuid", *settings\SchemeGuid)
  RegWriteDword(settingsKey$, "AC_MaxCPU", *settings\ACMaxCPU)
  RegWriteDword(settingsKey$, "DC_MaxCPU", *settings\DCMaxCPU)
  RegWriteDword(settingsKey$, "AC_MinCPU", *settings\ACMinCPU)
  RegWriteDword(settingsKey$, "DC_MinCPU", *settings\DCMinCPU)
  RegWriteDword(settingsKey$, "AC_Profile", *settings\ACProfile)
  RegWriteDword(settingsKey$, "DC_Profile", *settings\DCProfile)
  RegWriteDword(settingsKey$, "BoostMode", *settings\BoostMode)
  RegWriteDword(settingsKey$, "CoolingPolicy", *settings\CoolingPolicy)
  RegWriteDword(settingsKey$, "ASPMMode", *settings\ASPMMode)
  RegWriteDword(settingsKey$, "AC_BoostMode", *settings\ACBoostMode)
  RegWriteDword(settingsKey$, "DC_BoostMode", *settings\DCBoostMode)
  RegWriteDword(settingsKey$, "AC_CoolingPolicy", *settings\ACCoolingPolicy)
  RegWriteDword(settingsKey$, "DC_CoolingPolicy", *settings\DCCoolingPolicy)
  RegWriteDword(settingsKey$, "AC_ASPMMode", *settings\ACASPMMode)
  RegWriteDword(settingsKey$, "DC_ASPMMode", *settings\DCASPMMode)
  RegWriteDword(settingsKey$, "AutoApply", *settings\AutoApply)
  RegWriteDword(settingsKey$, "LiveApply", *settings\LiveApply)
  RegWriteDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  RegWriteDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)
  RegWriteDword(settingsKey$, "HeatAlertEnabled", *settings\HeatAlertEnabled)
  RegWriteDword(settingsKey$, "HeatAlertThreshold", *settings\HeatAlertThreshold)
  RegWriteDword(settingsKey$, "AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
  RegWriteDword(settingsKey$, "AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
  RegWriteDword(settingsKey$, "AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
  RegWriteDword(settingsKey$, "StartupMode", *settings\StartupMode)
  RegWriteDword(settingsKey$, "AutoRestoreEnabled", *settings\AutoRestoreEnabled)
  RegWriteDword(settingsKey$, "AutoRestoreThreshold", *settings\AutoRestoreThreshold)
  RegWriteDword(settingsKey$, "AutoRestoreSeconds", *settings\AutoRestoreSeconds)
  RegWriteDword(settingsKey$, "ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
  RegWriteDword(settingsKey$, "DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
  RegWriteDword(settingsKey$, "ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
  RegWriteDword(settingsKey$, "DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
  RegWriteDword(settingsKey$, "ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
  RegWriteDword(settingsKey$, "DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
  RegWriteDword(settingsKey$, "ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
  RegWriteDword(settingsKey$, "DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
  RegWriteDword(settingsKey$, "ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
  RegWriteDword(settingsKey$, "DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
  RegWriteDword(settingsKey$, "ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
  RegWriteDword(settingsKey$, "DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
  RegWriteDword(settingsKey$, "ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
  RegWriteDword(settingsKey$, "DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)

  If OpenPreferences(iniPath$)
    PreferenceGroup("Settings")
    WritePreferenceString("SchemeGuid", *settings\SchemeGuid)
    WritePreferenceLong("AC_MaxCPU", *settings\ACMaxCPU)
    WritePreferenceLong("DC_MaxCPU", *settings\DCMaxCPU)
    WritePreferenceLong("AC_MinCPU", *settings\ACMinCPU)
    WritePreferenceLong("DC_MinCPU", *settings\DCMinCPU)
    WritePreferenceString("AC_Profile", ProfileIdToName(*settings\ACProfile))
    WritePreferenceString("DC_Profile", ProfileIdToName(*settings\DCProfile))
    WritePreferenceLong("BoostMode", *settings\BoostMode)
    WritePreferenceLong("CoolingPolicy", *settings\CoolingPolicy)
    WritePreferenceLong("ASPMMode", *settings\ASPMMode)
    WritePreferenceLong("AC_BoostMode", *settings\ACBoostMode)
    WritePreferenceLong("DC_BoostMode", *settings\DCBoostMode)
    WritePreferenceLong("AC_CoolingPolicy", *settings\ACCoolingPolicy)
    WritePreferenceLong("DC_CoolingPolicy", *settings\DCCoolingPolicy)
    WritePreferenceLong("AC_ASPMMode", *settings\ACASPMMode)
    WritePreferenceLong("DC_ASPMMode", *settings\DCASPMMode)
    WritePreferenceLong("AutoApply", *settings\AutoApply)

    WritePreferenceLong("LiveApply", *settings\LiveApply)
    WritePreferenceLong("RunAtStartup", *settings\RunAtStartup)
    WritePreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
    WritePreferenceLong("HeatAlertEnabled", *settings\HeatAlertEnabled)
    WritePreferenceLong("HeatAlertThreshold", *settings\HeatAlertThreshold)
    WritePreferenceLong("AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
    WritePreferenceLong("AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
    WritePreferenceLong("AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
    WritePreferenceLong("StartupMode", *settings\StartupMode)
    WritePreferenceLong("AutoRestoreEnabled", *settings\AutoRestoreEnabled)
    WritePreferenceLong("AutoRestoreThreshold", *settings\AutoRestoreThreshold)
    WritePreferenceLong("AutoRestoreSeconds", *settings\AutoRestoreSeconds)
    WritePreferenceLong("ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
    WritePreferenceLong("DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
    WritePreferenceLong("ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
    WritePreferenceLong("DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
    WritePreferenceLong("ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
    WritePreferenceLong("DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
    WritePreferenceLong("ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
    WritePreferenceLong("DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
    WritePreferenceLong("ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
    WritePreferenceLong("DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
    WritePreferenceLong("ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
    WritePreferenceLong("DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
    WritePreferenceLong("ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
    WritePreferenceLong("DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
    ClosePreferences()
  EndIf

  ; Startup integration (Run key or Task Scheduler)
  Protected runValue$ = StartupCommandLine(*settings)
  Protected workDir$ = Chr(34) + GetPathPart(ProgramFilename()) + Chr(34)
  Protected userAccount$ = CurrentUserAccount()

  Protected runKey$ = "Software\\Microsoft\\Windows\\CurrentVersion\\Run"
  If *settings\RunAtStartup And *settings\UseTaskScheduler = 0
    RegWriteString(runKey$, #APP_NAME, runValue$)
    LogLine(#LOG_INFO, "Run key updated: " + runValue$)
  Else
    RegDeleteValue(runKey$, #APP_NAME)
  EndIf

  Protected taskName$ = #APP_NAME
  If *settings\UseTaskScheduler
    ; Create/remove scheduled task so it can run elevated without a UAC prompt.
    ; NOTE: Creating the task typically requires admin once.

    If *settings\RunAtStartup
      LogLine(#LOG_INFO, "Creating scheduled task: " + taskName$)
      RunProgramCapture("schtasks.exe", "/Create /F /TN " + Chr(34) + taskName$ + Chr(34) +
                                     " /SC ONLOGON /RL HIGHEST /RU " + Chr(34) + userAccount$ + Chr(34) +
                                     " /TR " + Chr(34) + runValue$ + Chr(34) +
                                     " /IT")
      If gLastExitCode <> 0
        LogLine(#LOG_ERROR, "schtasks create failed exit=" + Str(gLastExitCode))
        If gLastStdout <> "" : LogLine(#LOG_ERROR, "output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
        LogLine(#LOG_INFO, "Retrying scheduled task with cmd wrapper")
        RunProgramCapture("schtasks.exe", "/Create /F /TN " + Chr(34) + taskName$ + Chr(34) +
                                       " /SC ONLOGON /RL HIGHEST /RU " + Chr(34) + userAccount$ + Chr(34) +
                                       " /TR " + Chr(34) + "cmd.exe /c cd /d " + workDir$ + " && " + runValue$ + Chr(34) +
                                       " /IT")
        If gLastExitCode <> 0 And gLastStdout <> "" : LogLine(#LOG_ERROR, "retry output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
      EndIf
    Else
      LogLine(#LOG_INFO, "Deleting scheduled task: " + taskName$)
      RunProgramCapture("schtasks.exe", "/Delete /F /TN " + Chr(34) + taskName$ + Chr(34))
      If gLastExitCode <> 0
        LogLine(#LOG_WARN, "schtasks delete exit=" + Str(gLastExitCode))
      EndIf
    EndIf
  Else
    ; If switching away from Task Scheduler, remove any existing task.
    LogLine(#LOG_INFO, "Task Scheduler disabled; ensuring task removed: " + taskName$)
    RunProgramCapture("schtasks.exe", "/Delete /F /TN " + Chr(34) + taskName$ + Chr(34))
    If gLastExitCode <> 0
      LogLine(#LOG_DEBUG, "schtasks delete (cleanup) exit=" + Str(gLastExitCode))
    EndIf
  EndIf
EndProcedure

; -----------------------------
; GUI constants
; -----------------------------

Enumeration
  #Win
  #TrackACMax
  #TrackDCMax
  #TrackACMin
  #TrackDCMin
  #ComboACProfile
  #ComboDCProfile
  #ComboACBoost
  #ComboDCBoost
  #ComboACCooling
  #ComboDCCooling
  #ComboACASPM
  #ComboDCASPM

  #TxtACMaxVal
  #TxtDCMaxVal
  #TxtACMinVal
  #TxtDCMinVal
  #TxtACBoostVal
  #TxtDCBoostVal
  #TxtThermalHint
  #TxtTelemetrySummary
  #TxtTelemetryUpdated
  #TxtStatusSummary
  #EditStatusDetails
  #WinMini
  #TxtMiniTelemetry
  #TxtMiniThermal
  #TxtMiniProfile
  #TxtHeatAlertVal
  #TxtAutoSwitchVal
  #TxtAutoRestoreVal
  #TxtAutomationMode
  #TxtBenchmarkMode
  #BtnMiniToggleMain
  #BtnMiniApply
  #TrackHeatAlert
  #ChkHeatAlertPopup
  #ChkAutoThermalSwitch
  #ComboAutoSwitchProfile
  #TrackAutoSwitchDelay
  #ComboStartupMode
  #ChkAutoRestore
  #TrackAutoRestoreDelay
  #TrackAutoRestoreThreshold
  #CanvasMiniHistory
  #ComboCustomProfile
  #BtnSaveCustomProfile
  #BtnLoadCustomProfile
  #BtnBenchmarkMode
  #BtnExportProfile
  #BtnImportProfile
  #BtnMiniBattery
  #BtnMiniEco
  #BtnMiniQuiet
  #BtnMiniCool
  #BtnMiniBalanced
  #BtnMiniPerformance


  #ChkAutoApply
  #ChkLiveApply
  #ChkRunAtStartup
  #ChkUseTaskScheduler

  #BtnBatteryPreset
  #BtnApply
  #BtnEcoPreset
  #BtnQuietPreset
  #BtnCoolPreset
  #BtnBalancedPreset
  #BtnPerfPreset
  #BtnRestoreBalanced
EndEnumeration

Enumeration 1000
  #TimerTelemetry
EndEnumeration

Enumeration 1
  #TrayMain
EndEnumeration

Enumeration 100
  #MenuTrayShowHide
  #MenuTrayMiniDashboard
  #MenuTrayApply
  #MenuTrayRunAtStartup
  #MenuTrayUseTaskScheduler
  #MenuTrayStartupMain
  #MenuTrayStartupTray
  #MenuTrayStartupMini
  #MenuTrayStartupSilent
  #MenuTrayBattery
  #MenuTrayEco
  #MenuTrayQuiet
  #MenuTrayCool
  #MenuTrayBalanced
  #MenuTrayPerformance
  #MenuTrayRestoreBalanced
  #MenuTrayExit
EndEnumeration

; -----------------------------
; UI helpers
; -----------------------------

Procedure.i GetSelectedItemData(gadget.i, defaultValue.i = -1)
  Protected idx.i = GetGadgetState(gadget)
  If idx >= 0 And idx < CountGadgetItems(gadget)
    ProcedureReturn GetGadgetItemData(gadget, idx)
  EndIf
  ProcedureReturn defaultValue
EndProcedure

Procedure.i SetComboStateByData(gadget.i, value.i, defaultIndex.i = 0)
  Protected i.i
  For i = 0 To CountGadgetItems(gadget) - 1
    If GetGadgetItemData(gadget, i) = value
      SetGadgetState(gadget, i)
      ProcedureReturn #True
    EndIf
  Next

  If defaultIndex >= 0 And defaultIndex < CountGadgetItems(gadget)
    SetGadgetState(gadget, defaultIndex)
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure AddComboItemWithData(gadget.i, label$, value.i)
  AddGadgetItem(gadget, -1, label$)
  SetGadgetItemData(gadget, CountGadgetItems(gadget) - 1, value)
EndProcedure

Procedure PopulateProfileCombo(gadget.i)
  AddComboItemWithData(gadget, "Battery Saver", #PROFILE_BATTERY_SAVER)
  AddComboItemWithData(gadget, "Eco", #PROFILE_ECO)
  AddComboItemWithData(gadget, "Quiet", #PROFILE_QUIET)
  AddComboItemWithData(gadget, "Cool", #PROFILE_COOL)
  AddComboItemWithData(gadget, "Balanced", #PROFILE_BALANCED)
  AddComboItemWithData(gadget, "Performance", #PROFILE_PERFORMANCE)
EndProcedure

Procedure PopulatePresetOnlyProfileCombo(gadget.i)
  AddComboItemWithData(gadget, "Battery Saver", #PROFILE_BATTERY_SAVER)
  AddComboItemWithData(gadget, "Eco", #PROFILE_ECO)
  AddComboItemWithData(gadget, "Quiet", #PROFILE_QUIET)
  AddComboItemWithData(gadget, "Cool", #PROFILE_COOL)
  AddComboItemWithData(gadget, "Balanced", #PROFILE_BALANCED)
  AddComboItemWithData(gadget, "Performance", #PROFILE_PERFORMANCE)
EndProcedure

Procedure PopulateStartupModeCombo(gadget.i)
  AddComboItemWithData(gadget, "Open main window", 0)
  AddComboItemWithData(gadget, "Start in tray", 1)
  AddComboItemWithData(gadget, "Open mini dashboard", 2)
  AddComboItemWithData(gadget, "Silent apply and exit", 3)
EndProcedure

Procedure.i EnsureTrayIcon()
  If gTrayReady
    ProcedureReturn #True
  EndIf

  If gTrayImage = 0 And FileSize(GetPathPart(ProgramFilename()) + "files\MyCPUCooler.ico") >= 0
    gTrayImage = LoadImage(#PB_Any, GetPathPart(ProgramFilename()) + "files\MyCPUCooler.ico")
  EndIf

  If gTrayImage = 0
    gTrayImage = CreateImage(#PB_Any, 16, 16, 32, RGB(30, 36, 44))
    If gTrayImage And StartDrawing(ImageOutput(gTrayImage))
      Box(0, 0, 16, 16, RGB(30, 36, 44))
      Circle(8, 8, 6, RGB(96, 190, 120))
      Box(7, 3, 2, 10, RGB(220, 245, 230))
      Box(4, 7, 8, 2, RGB(220, 245, 230))
      StopDrawing()
    EndIf
  EndIf

  If gTrayImage
    gTrayReady = AddSysTrayIcon(#TrayMain, WindowID(#Win), ImageID(gTrayImage))
    If gTrayReady
      SysTrayIconToolTip(#TrayMain, #APP_NAME + " - cooling controls")
    EndIf
  EndIf

  ProcedureReturn gTrayReady
EndProcedure

Procedure RefreshCustomProfileCombo()
  Protected idx.i = 0

  If IsGadget(#ComboCustomProfile) = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#ComboCustomProfile)
  ForEach gCustomProfiles()
    AddGadgetItem(#ComboCustomProfile, -1, gCustomProfiles()\Name)
    SetGadgetItemData(#ComboCustomProfile, idx, idx)
    idx + 1
  Next
EndProcedure

Procedure LoadCustomProfiles()
  Protected i.i
  Protected key$
  ClearList(gCustomProfiles())

  If OpenPreferences(gIniPath)
    PreferenceGroup("CustomProfiles")
    For i = 0 To #MAX_CUSTOM_PROFILES - 1
      key$ = "Profile" + Str(i) + "_Name"
      If ReadPreferenceString(key$, "") <> ""
        AddElement(gCustomProfiles())
        gCustomProfiles()\Name = ReadPreferenceString(key$, "")
        gCustomProfiles()\Settings\ACProfile = ReadPreferenceLong("Profile" + Str(i) + "_ACProfile", gSettings\ACProfile)
        gCustomProfiles()\Settings\DCProfile = ReadPreferenceLong("Profile" + Str(i) + "_DCProfile", gSettings\DCProfile)
        gCustomProfiles()\Settings\ACMaxCPU = ReadPreferenceLong("Profile" + Str(i) + "_ACMaxCPU", gSettings\ACMaxCPU)
        gCustomProfiles()\Settings\DCMaxCPU = ReadPreferenceLong("Profile" + Str(i) + "_DCMaxCPU", gSettings\DCMaxCPU)
        gCustomProfiles()\Settings\ACMinCPU = ReadPreferenceLong("Profile" + Str(i) + "_ACMinCPU", gSettings\ACMinCPU)
        gCustomProfiles()\Settings\DCMinCPU = ReadPreferenceLong("Profile" + Str(i) + "_DCMinCPU", gSettings\DCMinCPU)
        gCustomProfiles()\Settings\ACBoostMode = ReadPreferenceLong("Profile" + Str(i) + "_ACBoost", gSettings\ACBoostMode)
        gCustomProfiles()\Settings\DCBoostMode = ReadPreferenceLong("Profile" + Str(i) + "_DCBoost", gSettings\DCBoostMode)
        gCustomProfiles()\Settings\ACCoolingPolicy = ReadPreferenceLong("Profile" + Str(i) + "_ACCooling", gSettings\ACCoolingPolicy)
        gCustomProfiles()\Settings\DCCoolingPolicy = ReadPreferenceLong("Profile" + Str(i) + "_DCCooling", gSettings\DCCoolingPolicy)
        gCustomProfiles()\Settings\ACASPMMode = ReadPreferenceLong("Profile" + Str(i) + "_ACASPM", gSettings\ACASPMMode)
        gCustomProfiles()\Settings\DCASPMMode = ReadPreferenceLong("Profile" + Str(i) + "_DCASPM", gSettings\DCASPMMode)
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveCustomProfiles()
  Protected idx.i = 0

  If OpenPreferences(gIniPath)
    PreferenceGroup("CustomProfiles")
    ForEach gCustomProfiles()
      WritePreferenceString("Profile" + Str(idx) + "_Name", gCustomProfiles()\Name)
      WritePreferenceLong("Profile" + Str(idx) + "_ACProfile", gCustomProfiles()\Settings\ACProfile)
      WritePreferenceLong("Profile" + Str(idx) + "_DCProfile", gCustomProfiles()\Settings\DCProfile)
      WritePreferenceLong("Profile" + Str(idx) + "_ACMaxCPU", gCustomProfiles()\Settings\ACMaxCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_DCMaxCPU", gCustomProfiles()\Settings\DCMaxCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_ACMinCPU", gCustomProfiles()\Settings\ACMinCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_DCMinCPU", gCustomProfiles()\Settings\DCMinCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_ACBoost", gCustomProfiles()\Settings\ACBoostMode)
      WritePreferenceLong("Profile" + Str(idx) + "_DCBoost", gCustomProfiles()\Settings\DCBoostMode)
      WritePreferenceLong("Profile" + Str(idx) + "_ACCooling", gCustomProfiles()\Settings\ACCoolingPolicy)
      WritePreferenceLong("Profile" + Str(idx) + "_DCCooling", gCustomProfiles()\Settings\DCCoolingPolicy)
      WritePreferenceLong("Profile" + Str(idx) + "_ACASPM", gCustomProfiles()\Settings\ACASPMMode)
      WritePreferenceLong("Profile" + Str(idx) + "_DCASPM", gCustomProfiles()\Settings\DCASPMMode)
      idx + 1
      If idx >= #MAX_CUSTOM_PROFILES : Break : EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveCustomProfileFromCurrentUI()
  Protected name$ = InputRequester("Save Profile", "Enter a name for this profile", "My Custom Profile")
  If Trim(name$) = ""
    ProcedureReturn
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  AddElement(gCustomProfiles())
  gCustomProfiles()\Name = Trim(name$)
  CopyStructure(@gSettings, @gCustomProfiles()\Settings, AppSettings)
  SaveCustomProfiles()
  RefreshCustomProfileCombo()
  ShowTrayNotification("Profile Saved", gCustomProfiles()\Name)
EndProcedure

Procedure LoadSelectedCustomProfile()
  Protected selected.i = GetGadgetState(#ComboCustomProfile)
  Protected idx.i = 0

  ForEach gCustomProfiles()
    If idx = selected
      CopyStructure(@gCustomProfiles()\Settings, @gSettings, AppSettings)
      LoadSettingsIntoUI(@gSettings)
      SaveAppSettings(gIniPath, @gSettings)
      ShowTrayNotification("Profile Loaded", gCustomProfiles()\Name)
      ProcedureReturn
    EndIf
    idx + 1
  Next
EndProcedure

Procedure EnterBenchmarkMode()
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  CopyStructure(@gSettings, @gLastNonBenchmarkSettings, AppSettings)
  gSettings\BenchmarkModeEnabled = 1
  gSettings\BenchmarkModeEndsAt = Date() + #BENCHMARK_MODE_SECONDS
  SaveAppSettings(gIniPath, @gSettings)
  SetGadgetText(#TxtBenchmarkMode, "Benchmark mode active for 10 min")
  ShowTrayNotification("Benchmark Mode", "Automation paused for 10 minutes.")
EndProcedure

Procedure CheckBenchmarkMode()
  If gSettings\BenchmarkModeEnabled = 0
    ProcedureReturn
  EndIf

  If Date() >= gSettings\BenchmarkModeEndsAt
    gSettings\BenchmarkModeEnabled = 0
    CopyStructure(@gLastNonBenchmarkSettings, @gSettings, AppSettings)
    LoadSettingsIntoUI(@gSettings)
    SaveAppSettings(gIniPath, @gSettings)
    SetGadgetText(#TxtBenchmarkMode, "Benchmark mode inactive")
    ShowTrayNotification("Benchmark Mode", "Finished. Normal automation restored.")
  EndIf
EndProcedure

Procedure UpdateAutomationDisplay()
  Protected powerMode$ = "AC"
  Protected switchProfile$ = ProfileIdToName(gSettings\ACAutoSwitchProfile)
  Protected restoreText$ = "Restore " + Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec"

  If LCase(gTelemetry\PowerSource) = "battery"
    powerMode$ = "Battery"
    switchProfile$ = ProfileIdToName(gSettings\DCAutoSwitchProfile)
    restoreText$ = "Restore " + Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec"
    SetComboStateByData(#ComboAutoSwitchProfile, gSettings\DCAutoSwitchProfile, 0)
    SetGadgetState(#TrackAutoSwitchDelay, gSettings\DCAutoSwitchSeconds)
    SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
    SetGadgetState(#TrackAutoRestoreThreshold, gSettings\DCAutoRestoreThreshold)
    SetGadgetState(#TrackAutoRestoreDelay, gSettings\DCAutoRestoreSeconds)
    SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
    SetGadgetState(#ChkAutoThermalSwitch, gSettings\DCAutoSwitchEnabled)
    SetGadgetState(#ChkAutoRestore, gSettings\DCAutoRestoreEnabled)
  Else
    SetComboStateByData(#ComboAutoSwitchProfile, gSettings\ACAutoSwitchProfile, 0)
    SetGadgetState(#TrackAutoSwitchDelay, gSettings\ACAutoSwitchSeconds)
    SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\ACAutoSwitchThreshold) + " C / " + Str(gSettings\ACAutoSwitchSeconds) + " sec")
    SetGadgetState(#TrackAutoRestoreThreshold, gSettings\ACAutoRestoreThreshold)
    SetGadgetState(#TrackAutoRestoreDelay, gSettings\ACAutoRestoreSeconds)
    SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
    SetGadgetState(#ChkAutoThermalSwitch, gSettings\ACAutoSwitchEnabled)
    SetGadgetState(#ChkAutoRestore, gSettings\ACAutoRestoreEnabled)
  EndIf

  If IsGadget(#TxtAutomationMode)
    SetGadgetText(#TxtAutomationMode, powerMode$ + " automation -> " + switchProfile$ + " | " + restoreText$)
  EndIf
EndProcedure

Procedure PopulateBoostCombo()
  AddComboItemWithData(#ComboACBoost, "Disabled (coolest)", #BOOST_DISABLED)
  AddComboItemWithData(#ComboACBoost, "Enabled (default)", #BOOST_ENABLED)
  AddComboItemWithData(#ComboACBoost, "Efficient Enabled (cooler)", #BOOST_EFFICIENT)
  AddComboItemWithData(#ComboACBoost, "Efficient Aggressive (warm)", #BOOST_EFFICIENT_AGGRESSIVE)
  AddComboItemWithData(#ComboACBoost, "Aggressive (hottest)", #BOOST_AGGRESSIVE)
  AddComboItemWithData(#ComboDCBoost, "Disabled (coolest)", #BOOST_DISABLED)
  AddComboItemWithData(#ComboDCBoost, "Enabled (default)", #BOOST_ENABLED)
  AddComboItemWithData(#ComboDCBoost, "Efficient Enabled (cooler)", #BOOST_EFFICIENT)
  AddComboItemWithData(#ComboDCBoost, "Efficient Aggressive (warm)", #BOOST_EFFICIENT_AGGRESSIVE)
  AddComboItemWithData(#ComboDCBoost, "Aggressive (hottest)", #BOOST_AGGRESSIVE)
EndProcedure

Procedure PopulateCoolingCombo()
  AddComboItemWithData(#ComboACCooling, "Active (fan first)", 0)
  AddComboItemWithData(#ComboACCooling, "Passive (throttle first)", 1)
  AddComboItemWithData(#ComboDCCooling, "Active (fan first)", 0)
  AddComboItemWithData(#ComboDCCooling, "Passive (throttle first)", 1)
EndProcedure

Procedure PopulateASPMCombo()
  AddComboItemWithData(#ComboACASPM, "Off (performance)", 0)
  AddComboItemWithData(#ComboACASPM, "Moderate Power Savings", 1)
  AddComboItemWithData(#ComboACASPM, "Maximum Power Savings", 2)
  AddComboItemWithData(#ComboDCASPM, "Off (performance)", 0)
  AddComboItemWithData(#ComboDCASPM, "Moderate Power Savings", 1)
  AddComboItemWithData(#ComboDCASPM, "Maximum Power Savings", 2)
EndProcedure

Procedure.s BoostModeLabel(boostValue.i)
  Select boostValue
    Case #BOOST_DISABLED
      ProcedureReturn "Disabled"
    Case #BOOST_ENABLED
      ProcedureReturn "Enabled"
    Case #BOOST_EFFICIENT
      ProcedureReturn "Efficient Enabled"
    Case #BOOST_EFFICIENT_AGGRESSIVE
      ProcedureReturn "Efficient Aggressive"
    Case #BOOST_AGGRESSIVE
      ProcedureReturn "Aggressive"
  EndSelect

  ProcedureReturn "Custom"
EndProcedure

Procedure.s CoolingPolicyLabel(value.i)
  Select value
    Case 0
      ProcedureReturn "Active"
    Case 1
      ProcedureReturn "Passive"
  EndSelect
  ProcedureReturn "Custom"
EndProcedure

Procedure.s ASPMLabel(value.i)
  Select value
    Case 0
      ProcedureReturn "Off"
    Case 1
      ProcedureReturn "Moderate"
    Case 2
      ProcedureReturn "Maximum"
  EndSelect
  ProcedureReturn "Custom"
EndProcedure

Procedure.i ThermalScore(acMax.i, dcMax.i, acBoost.i, dcBoost.i, acCooling.i, dcCooling.i, acASPM.i, dcASPM.i)
  Protected score.i = 100

  score - ((100 - ClampPercent(acMax, 5, 100)) / 2)
  score - ((100 - ClampPercent(dcMax, 5, 100)) / 2)
  score - (acBoost * 8)
  score - (dcBoost * 6)
  score - (acCooling * 6)
  score - (dcCooling * 8)
  score - (acASPM * 2)
  score - (dcASPM * 3)

  If score < 0 : score = 0 : EndIf
  If score > 100 : score = 100 : EndIf
  ProcedureReturn score
EndProcedure

Procedure.s ThermalHintText(score.i)
  If score >= 88
    ProcedureReturn "Thermal posture: Maximum cooling. Strong throttling, best for hot rooms and gaming laptops."
  ElseIf score >= 72
    ProcedureReturn "Thermal posture: Cool and quiet. Good for long sessions with lower surface temps."
  ElseIf score >= 55
    ProcedureReturn "Thermal posture: Balanced. Good mix of temperature control and responsiveness."
  ElseIf score >= 38
    ProcedureReturn "Thermal posture: Performance leaning. Expect more heat under sustained load."
  EndIf

  ProcedureReturn "Thermal posture: Max performance. Fastest, but likely the hottest setting."
EndProcedure

Procedure SetStatus(summary$, detail$ = "")
  If IsGadget(#TxtStatusSummary)
    SetGadgetText(#TxtStatusSummary, summary$)
  EndIf
  If IsGadget(#EditStatusDetails)
    SetGadgetText(#EditStatusDetails, detail$)
  EndIf
EndProcedure

Procedure UpdateProfilesFromCurrentSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer
  Protected profileId.i

  *settings\ACProfile = 0
  *settings\DCProfile = 0

  For profileId = #PROFILE_BATTERY_SAVER To #PROFILE_PERFORMANCE
    LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                        @acBoostValue, @dcBoostValue,
                        @acCoolingPolicy, @dcCoolingPolicy,
                        @acASPMValue, @dcASPMValue)
    If *settings\ACMaxCPU = acMax\i And *settings\ACMinCPU = acMin\i And *settings\ACBoostMode = acBoostValue\i And *settings\ACCoolingPolicy = acCoolingPolicy\i And *settings\ACASPMMode = acASPMValue\i
      *settings\ACProfile = profileId
    EndIf
    If *settings\DCMaxCPU = dcMax\i And *settings\DCMinCPU = dcMin\i And *settings\DCBoostMode = dcBoostValue\i And *settings\DCCoolingPolicy = dcCoolingPolicy\i And *settings\DCASPMMode = dcASPMValue\i
      *settings\DCProfile = profileId
    EndIf
  Next
EndProcedure

Procedure UpdateProfilesFromCurrentUI(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACMaxCPU = GetGadgetState(#TrackACMax)
  *settings\DCMaxCPU = GetGadgetState(#TrackDCMax)
  *settings\ACMinCPU = GetGadgetState(#TrackACMin)
  *settings\DCMinCPU = GetGadgetState(#TrackDCMin)
  *settings\ACBoostMode = GetSelectedItemData(#ComboACBoost, #BOOST_DISABLED)
  *settings\DCBoostMode = GetSelectedItemData(#ComboDCBoost, #BOOST_DISABLED)
  *settings\ACCoolingPolicy = GetSelectedItemData(#ComboACCooling, 0)
  *settings\DCCoolingPolicy = GetSelectedItemData(#ComboDCCooling, 1)
  *settings\ACASPMMode = GetSelectedItemData(#ComboACASPM, 1)
  *settings\DCASPMMode = GetSelectedItemData(#ComboDCASPM, 2)
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  UpdateProfilesFromCurrentSettings(*settings)
EndProcedure

Procedure SyncProfileCombosFromSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If *settings\ACProfile <= 0
    *settings\ACProfile = #PROFILE_COOL
  EndIf
  If *settings\DCProfile <= 0
    *settings\DCProfile = #PROFILE_BALANCED
  EndIf

  If IsGadget(#ComboACProfile)
    SetComboStateByData(#ComboACProfile, *settings\ACProfile, 0)
  EndIf

  If IsGadget(#ComboDCProfile)
    SetComboStateByData(#ComboDCProfile, *settings\DCProfile, 4)
  EndIf
EndProcedure

Procedure ApplyProfileSelectionToTracks(profileId.i, isAC.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer

  If profileId < #PROFILE_BATTERY_SAVER Or profileId > #PROFILE_PERFORMANCE
    ProcedureReturn
  EndIf

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                      @acBoostValue, @dcBoostValue,
                      @acCoolingPolicy, @dcCoolingPolicy,
                      @acASPMValue, @dcASPMValue)

  If isAC
    SetGadgetState(#TrackACMax, acMax\i)
    SetGadgetState(#TrackACMin, acMin\i)
    If useBoost
      SetComboStateByData(#ComboACBoost, acBoostValue\i, 0)
    EndIf
    If useCooling
      SetComboStateByData(#ComboACCooling, acCoolingPolicy\i, 0)
    EndIf
    If useASPM
      SetComboStateByData(#ComboACASPM, acASPMValue\i, 1)
    EndIf
  Else
    SetGadgetState(#TrackDCMax, dcMax\i)
    SetGadgetState(#TrackDCMin, dcMin\i)
    If useBoost
      SetComboStateByData(#ComboDCBoost, dcBoostValue\i, 0)
    EndIf
    If useCooling
      SetComboStateByData(#ComboDCCooling, dcCoolingPolicy\i, 0)
    EndIf
    If useASPM
      SetComboStateByData(#ComboDCASPM, dcASPMValue\i, 1)
    EndIf
  EndIf

  UpdateDisplayedValues(useBoost, useCooling, useASPM)
EndProcedure

Procedure.i ACCoolingPolicyArg(useCooling.i)
  If useCooling
    ProcedureReturn GetSelectedItemData(#ComboACCooling, 0)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i DCCoolingPolicyArg(useCooling.i)
  If useCooling
    ProcedureReturn GetSelectedItemData(#ComboDCCooling, 1)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i ACASPMArg(useASPM.i)
  If useASPM
    ProcedureReturn GetSelectedItemData(#ComboACASPM, 1)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i DCASPMArg(useASPM.i)
  If useASPM
    ProcedureReturn GetSelectedItemData(#ComboDCASPM, 2)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i ACBoostArg(useBoost.i)
  If useBoost
    ProcedureReturn GetSelectedItemData(#ComboACBoost, #BOOST_DISABLED)
  EndIf
  ProcedureReturn #BOOST_DISABLED
EndProcedure

Procedure.i DCBoostArg(useBoost.i)
  If useBoost
    ProcedureReturn GetSelectedItemData(#ComboDCBoost, #BOOST_DISABLED)
  EndIf
  ProcedureReturn #BOOST_DISABLED
EndProcedure

Procedure ApplyCurrentGadgetSettings(scheme$, useBoost.i, useCooling.i, useASPM.i, *diag.ApplyDiagnostics = 0)
  ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin),
                ACBoostArg(useBoost), DCBoostArg(useBoost), useBoost,
                ACCoolingPolicyArg(useCooling), DCCoolingPolicyArg(useCooling),
                ACASPMArg(useASPM), DCASPMArg(useASPM), *diag)
EndProcedure

Procedure LoadNamedPreset(profileId.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                      @acBoostValue, @dcBoostValue,
                      @acCoolingPolicy, @dcCoolingPolicy,
                      @acASPMValue, @dcASPMValue)
  LoadPreset(useBoost, useCooling, useASPM,
             acMax\i, dcMax\i, acMin\i, dcMin\i,
             acBoostValue\i, dcBoostValue\i,
             acCoolingPolicy\i, dcCoolingPolicy\i,
             acASPMValue\i, dcASPMValue\i)
  SetComboStateByData(#ComboACProfile, profileId, 0)
  SetComboStateByData(#ComboDCProfile, profileId, 0)
EndProcedure

Procedure ApplyLiveIfEnabled(scheme$, useBoost.i, useCooling.i, useASPM.i)
  Protected diag.ApplyDiagnostics
  If GetGadgetState(#ChkLiveApply)
    ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, @diag)
    If diag\Summary = ""
      diag\Summary = "Live apply complete."
    EndIf
    SetStatus("Status: " + diag\Summary, diag\Details)
  EndIf
EndProcedure

Procedure SaveCurrentUIToSettings(*settings.AppSettings, useBoost.i, useCooling.i, useASPM.i)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACMaxCPU = GetGadgetState(#TrackACMax)
  *settings\DCMaxCPU = GetGadgetState(#TrackDCMax)
  *settings\ACMinCPU = GetGadgetState(#TrackACMin)
  *settings\DCMinCPU = GetGadgetState(#TrackDCMin)
  *settings\ACProfile = GetSelectedItemData(#ComboACProfile, 0)
  *settings\DCProfile = GetSelectedItemData(#ComboDCProfile, 0)
  *settings\ACBoostMode = ACBoostArg(useBoost)
  *settings\DCBoostMode = DCBoostArg(useBoost)
  If useCooling
    *settings\ACCoolingPolicy = ACCoolingPolicyArg(useCooling)
    *settings\DCCoolingPolicy = DCCoolingPolicyArg(useCooling)
  EndIf
  *settings\ACASPMMode = ACASPMArg(useASPM)
  *settings\DCASPMMode = DCASPMArg(useASPM)
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  *settings\AutoApply = GetGadgetState(#ChkAutoApply)
  *settings\LiveApply = GetGadgetState(#ChkLiveApply)
  *settings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
  *settings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
  *settings\HeatAlertEnabled = GetGadgetState(#ChkHeatAlertPopup)
  *settings\HeatAlertThreshold = GetGadgetState(#TrackHeatAlert)
EndProcedure

Procedure LoadPreset(useBoost.i, useCooling.i, useASPM.i,
                     acMax.i, dcMax.i, acMin.i, dcMin.i,
                     acBoostValue.i, dcBoostValue.i,
                     acCoolingPolicy.i, dcCoolingPolicy.i,
                     acASPMValue.i, dcASPMValue.i)
  SetGadgetState(#TrackACMax, acMax)
  SetGadgetState(#TrackDCMax, dcMax)
  SetGadgetState(#TrackACMin, acMin)
  SetGadgetState(#TrackDCMin, dcMin)

  If useBoost
    SetComboStateByData(#ComboACBoost, acBoostValue, 0)
    SetComboStateByData(#ComboDCBoost, dcBoostValue, 0)
  EndIf

  If useCooling
    SetComboStateByData(#ComboACCooling, acCoolingPolicy, 0)
    SetComboStateByData(#ComboDCCooling, dcCoolingPolicy, 0)
  EndIf

  If useASPM
    SetComboStateByData(#ComboACASPM, acASPMValue, 1)
    SetComboStateByData(#ComboDCASPM, dcASPMValue, 1)
  EndIf
  UpdateDisplayedValues(useBoost, useCooling, useASPM)
EndProcedure

Procedure UpdateDisplayedValues(useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.i = GetGadgetState(#TrackACMax)
  Protected dcMax.i = GetGadgetState(#TrackDCMax)
  Protected acMin.i = GetGadgetState(#TrackACMin)
  Protected dcMin.i = GetGadgetState(#TrackDCMin)
  Protected acBoostValue.i
  Protected dcBoostValue.i
  Protected acCoolingValue.i
  Protected dcCoolingValue.i
  Protected acASPMValue.i
  Protected dcASPMValue.i
  Protected score.i

  SetGadgetText(#TxtACMaxVal, Str(acMax) + "%")
  SetGadgetText(#TxtDCMaxVal, Str(dcMax) + "%")
  SetGadgetText(#TxtACMinVal, Str(acMin) + "%")
  SetGadgetText(#TxtDCMinVal, Str(dcMin) + "%")

  If useBoost
    acBoostValue = ACBoostArg(useBoost)
    dcBoostValue = DCBoostArg(useBoost)
    SetGadgetText(#TxtACBoostVal, "AC boost: " + BoostModeLabel(acBoostValue) + " (" + Str(acBoostValue) + ")")
    SetGadgetText(#TxtDCBoostVal, "DC boost: " + BoostModeLabel(dcBoostValue) + " (" + Str(dcBoostValue) + ")")
  Else
    acBoostValue = #BOOST_DISABLED
    dcBoostValue = #BOOST_DISABLED
    SetGadgetText(#TxtACBoostVal, "AC boost: N/A")
    SetGadgetText(#TxtDCBoostVal, "DC boost: N/A")
  EndIf

  If useCooling
    acCoolingValue = ACCoolingPolicyArg(useCooling)
    dcCoolingValue = DCCoolingPolicyArg(useCooling)
  Else
    acCoolingValue = 0
    dcCoolingValue = 0
  EndIf

  If useASPM
    acASPMValue = ACASPMArg(useASPM)
    dcASPMValue = DCASPMArg(useASPM)
  Else
    acASPMValue = 1
    dcASPMValue = 1
  EndIf

  score = ThermalScore(acMax, dcMax, acBoostValue, dcBoostValue, acCoolingValue, dcCoolingValue, acASPMValue, dcASPMValue)
  SetGadgetText(#TxtThermalHint, ThermalHintText(score) + " Thermal score: " + Str(score) + "/100. AC " + CoolingPolicyLabel(acCoolingValue) + ", DC " + CoolingPolicyLabel(dcCoolingValue) + ", AC ASPM " + ASPMLabel(acASPMValue) + ", DC ASPM " + ASPMLabel(dcASPMValue) + ".")
EndProcedure

Procedure UpdateTelemetryDisplay()
  Protected summary$
  Protected updated$
  Protected heatValue.d

  If gTelemetryAvailable = #False
    summary$ = "Live telemetry: unavailable"
    updated$ = "Built-in Windows counters not available on this system."
  ElseIf gTelemetry\ErrorText <> ""
    summary$ = "Live telemetry: " + gTelemetry\ErrorText
    updated$ = "Last checked: " + gTelemetry\LastUpdated
  Else
    If gTelemetry\CpuLoad = "" : gTelemetry\CpuLoad = "Unavailable" : EndIf
    If gTelemetry\ThermalC = "" : gTelemetry\ThermalC = "Unavailable" : EndIf
    If gTelemetry\PowerSource = "" : gTelemetry\PowerSource = "Unknown" : EndIf
    summary$ = "Live telemetry: CPU load " + gTelemetry\CpuLoad + "% | Thermal zone " + gTelemetry\ThermalC + " C | Power " + gTelemetry\PowerSource
    updated$ = "Updated at " + gTelemetry\LastUpdated + ". Thermal zone is firmware-reported and may be unavailable on some laptops."
  EndIf

  If IsGadget(#TxtTelemetrySummary)
    SetGadgetText(#TxtTelemetrySummary, summary$)
  EndIf
  If IsGadget(#TxtTelemetryUpdated)
    SetGadgetText(#TxtTelemetryUpdated, updated$)
  EndIf

  UpdateMiniDashboard()

  CheckBenchmarkMode()

  If gTelemetry\ThermalC <> "" And LCase(gTelemetry\ThermalC) <> "unavailable"
    heatValue = ValD(gTelemetry\ThermalC)
    If gHeatPopupEnabled And heatValue >= gHeatAlertThreshold And Date() - gLastHeatAlertTime > 300
      gLastHeatAlertTime = Date()
      ShowTrayNotification("Heat Alert", "Thermal zone reached " + StrD(heatValue, 1) + " C. Consider switching to Cool or Battery Saver.")
    EndIf
  EndIf

  MaybeAutoSwitchThermalProfile()
EndProcedure

Procedure ShowTrayNotification(title$, message$)
  If title$ = "" Or message$ = ""
    ProcedureReturn
  EndIf

  EnsureTrayIcon()

  If gTrayReady
    SysTrayIconToolTip(#TrayMain, title$ + ": " + message$)
  EndIf

  gLastApplyMessage = title$ + ": " + message$

  If title$ = "Heat Alert" And gMainWindowVisible = #False And gMiniWindowVisible = #False
    MessageRequester(title$, message$, #PB_MessageRequester_Warning)
  EndIf
EndProcedure

Procedure UpdateMiniDashboard()
  Protected thermalText$
  Protected loadText$
  Protected idx.i

  If IsWindow(#WinMini) = 0
    ProcedureReturn
  EndIf

  loadText$ = gTelemetry\CpuLoad
  If loadText$ = "" : loadText$ = "Unavailable" : EndIf
  thermalText$ = gTelemetry\ThermalC
  If thermalText$ = "" : thermalText$ = "Unavailable" : EndIf

  If gTelemetry\ThermalC <> "" And LCase(gTelemetry\ThermalC) <> "unavailable"
    For idx = 0 To #HISTORY_POINTS - 2
      gThermalHistory(idx) = gThermalHistory(idx + 1)
      gCpuLoadHistory(idx) = gCpuLoadHistory(idx + 1)
    Next
    gThermalHistory(#HISTORY_POINTS - 1) = Val(gTelemetry\ThermalC)
    gCpuLoadHistory(#HISTORY_POINTS - 1) = Val(gTelemetry\CpuLoad)
    If gHistoryCount < #HISTORY_POINTS
      gHistoryCount + 1
    EndIf
  EndIf

  SetGadgetText(#TxtMiniTelemetry, "CPU " + loadText$ + "% | " + gTelemetry\PowerSource)
  SetGadgetText(#TxtMiniThermal, "Thermal zone " + thermalText$ + " C | " + gTelemetry\LastUpdated)
  RefreshMiniProfileBadge()
  UpdateAutomationDisplay()
  DrawMiniHistory()
EndProcedure

Procedure RefreshMiniProfileBadge()
  Protected acProfile$ = "Custom"
  Protected dcProfile$ = "Custom"

  If gSettings\ACProfile > 0
    acProfile$ = ProfileIdToName(gSettings\ACProfile)
  EndIf
  If gSettings\DCProfile > 0
    dcProfile$ = ProfileIdToName(gSettings\DCProfile)
  EndIf

  If IsGadget(#TxtMiniProfile)
    SetGadgetText(#TxtMiniProfile, "AC " + acProfile$ + " | DC " + dcProfile$)
  EndIf
EndProcedure

Procedure MaybeAutoSwitchThermalProfile()
  Protected heatValue.d
  Protected isBattery.i
  Protected switchEnabled.i, switchProfile.i, switchThreshold.i, switchSeconds.i
  Protected restoreEnabled.i, restoreThreshold.i, restoreSeconds.i

  If gSettings\BenchmarkModeEnabled
    ProcedureReturn
  EndIf

  If gTelemetry\ThermalC = "" Or LCase(gTelemetry\ThermalC) = "unavailable"
    gACAUtoSwitchSince = 0 : gDCAUtoSwitchSince = 0
    gACAutoRestoreSince = 0 : gDCAutoRestoreSince = 0
    ProcedureReturn
  EndIf

  heatValue = ValD(gTelemetry\ThermalC)
  isBattery = Bool(LCase(gTelemetry\PowerSource) = "battery")

  If isBattery
    switchEnabled = gSettings\DCAutoSwitchEnabled
    switchProfile = gSettings\DCAutoSwitchProfile
    switchThreshold = gSettings\DCAutoSwitchThreshold
    switchSeconds = gSettings\DCAutoSwitchSeconds
    restoreEnabled = gSettings\DCAutoRestoreEnabled
    restoreThreshold = gSettings\DCAutoRestoreThreshold
    restoreSeconds = gSettings\DCAutoRestoreSeconds
  Else
    switchEnabled = gSettings\ACAutoSwitchEnabled
    switchProfile = gSettings\ACAutoSwitchProfile
    switchThreshold = gSettings\ACAutoSwitchThreshold
    switchSeconds = gSettings\ACAutoSwitchSeconds
    restoreEnabled = gSettings\ACAutoRestoreEnabled
    restoreThreshold = gSettings\ACAutoRestoreThreshold
    restoreSeconds = gSettings\ACAutoRestoreSeconds
  EndIf

  If switchEnabled
    If heatValue >= switchThreshold
      If isBattery
        If gDCAUtoSwitchSince = 0 : gDCAUtoSwitchSince = Date() : EndIf
        If Date() - gDCAUtoSwitchSince >= switchSeconds
          If gAutoSwitchedDCProfile = 0
            gLastManualDCProfile = gSettings\DCProfile
            gAutoSwitchedDCProfile = switchProfile
          EndIf
          ApplySingleModePresetAndRefresh(switchProfile, #True, "Auto Cooling")
          ShowTrayNotification("Auto Cooling", "Battery heat persisted. Switched DC to " + ProfileIdToName(switchProfile) + ".")
          gDCAUtoSwitchSince = Date()
        EndIf
      Else
        If gACAUtoSwitchSince = 0 : gACAUtoSwitchSince = Date() : EndIf
        If Date() - gACAUtoSwitchSince >= switchSeconds
          If gAutoSwitchedACProfile = 0
            gLastManualACProfile = gSettings\ACProfile
            gAutoSwitchedACProfile = switchProfile
          EndIf
          ApplySingleModePresetAndRefresh(switchProfile, #False, "Auto Cooling")
          ShowTrayNotification("Auto Cooling", "AC heat persisted. Switched AC to " + ProfileIdToName(switchProfile) + ".")
          gACAUtoSwitchSince = Date()
        EndIf
      EndIf
    Else
      If isBattery : gDCAUtoSwitchSince = 0 : Else : gACAUtoSwitchSince = 0 : EndIf
    EndIf
  EndIf

  If restoreEnabled
    If heatValue <= restoreThreshold
      If isBattery And gAutoSwitchedDCProfile > 0
        If gDCAutoRestoreSince = 0 : gDCAutoRestoreSince = Date() : EndIf
        If Date() - gDCAutoRestoreSince >= restoreSeconds
          ApplySingleModePresetAndRefresh(gLastManualDCProfile, #True, "Auto Restore")
          ShowTrayNotification("Auto Restore", "Battery temperature recovered. Restored DC " + ProfileIdToName(gLastManualDCProfile) + ".")
          gAutoSwitchedDCProfile = 0
          gDCAutoRestoreSince = 0
        EndIf
      ElseIf isBattery = 0 And gAutoSwitchedACProfile > 0
        If gACAutoRestoreSince = 0 : gACAutoRestoreSince = Date() : EndIf
        If Date() - gACAutoRestoreSince >= restoreSeconds
          ApplySingleModePresetAndRefresh(gLastManualACProfile, #False, "Auto Restore")
          ShowTrayNotification("Auto Restore", "AC temperature recovered. Restored AC " + ProfileIdToName(gLastManualACProfile) + ".")
          gAutoSwitchedACProfile = 0
          gACAutoRestoreSince = 0
        EndIf
      EndIf
    Else
      If isBattery : gDCAutoRestoreSince = 0 : Else : gACAutoRestoreSince = 0 : EndIf
    EndIf
  EndIf
EndProcedure

Procedure DrawMiniHistory()
  Protected w.i, h.i, i.i, x1.i, y1.i, x2.i, y2.i

  If StartDrawing(CanvasOutput(#CanvasMiniHistory)) = 0
    ProcedureReturn
  EndIf

  w = OutputWidth()
  h = OutputHeight()
  Box(0, 0, w, h, RGB(18, 23, 29))
  Box(0, h / 2, w, 1, RGB(45, 55, 66))

  If gHistoryCount > 1
    For i = #HISTORY_POINTS - gHistoryCount To #HISTORY_POINTS - 2
      x1 = (i - (#HISTORY_POINTS - gHistoryCount)) * (w - 1) / (gHistoryCount - 1)
      x2 = (i + 1 - (#HISTORY_POINTS - gHistoryCount)) * (w - 1) / (gHistoryCount - 1)
      y1 = h - (gThermalHistory(i) * (h - 1) / 100)
      y2 = h - (gThermalHistory(i + 1) * (h - 1) / 100)
      LineXY(x1, y1, x2, y2, RGB(255, 120, 80))
      y1 = h - (gCpuLoadHistory(i) * (h - 1) / 100)
      y2 = h - (gCpuLoadHistory(i + 1) * (h - 1) / 100)
      LineXY(x1, y1, x2, y2, RGB(90, 180, 255))
    Next
  EndIf

  DrawText(8, 8, "Temp", RGB(255, 120, 80), RGB(18, 23, 29))
  DrawText(52, 8, "Load", RGB(90, 180, 255), RGB(18, 23, 29))
  StopDrawing()
EndProcedure

Procedure ShowMainWindow(showWindow.i)
  If showWindow
    EnsureTrayIcon()
    HideWindow(#Win, #False)
    SetActiveWindow(#Win)
    gMainWindowVisible = #True
  Else
    EnsureTrayIcon()
    HideWindow(#Win, #True)
    gMainWindowVisible = #False
  EndIf
  UpdateTrayMenuState()
EndProcedure

Procedure ShowMiniDashboard(showWindow.i)
  If showWindow
    EnsureTrayIcon()
    HideWindow(#WinMini, #False)
    SetActiveWindow(#WinMini)
    gMiniWindowVisible = #True
  Else
    EnsureTrayIcon()
    HideWindow(#WinMini, #True)
    gMiniWindowVisible = #False
  EndIf
  UpdateTrayMenuState()
EndProcedure

Procedure UpdateTrayMenuState()
  EnsureTrayIcon()

  If IsMenu(#TrayMain)
    SetMenuItemState(#TrayMain, #MenuTrayRunAtStartup, gSettings\RunAtStartup)
    SetMenuItemState(#TrayMain, #MenuTrayUseTaskScheduler, gSettings\UseTaskScheduler)
    SetMenuItemState(#TrayMain, #MenuTrayStartupMain, Bool(gSettings\StartupMode = 0))
    SetMenuItemState(#TrayMain, #MenuTrayStartupTray, Bool(gSettings\StartupMode = 1))
    SetMenuItemState(#TrayMain, #MenuTrayStartupMini, Bool(gSettings\StartupMode = 2))
    SetMenuItemState(#TrayMain, #MenuTrayStartupSilent, Bool(gSettings\StartupMode = 3))
    DisableMenuItem(#TrayMain, #MenuTrayUseTaskScheduler, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupMain, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupTray, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupMini, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupSilent, Bool(gSettings\RunAtStartup = 0))
  EndIf

  If gTrayReady
    If gMainWindowVisible
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - main window open | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - main window open")
      EndIf
    ElseIf gMiniWindowVisible
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - mini dashboard open | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - mini dashboard open")
      EndIf
    Else
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - running in tray | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - running in tray")
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure ApplyPresetAndRefresh(profileId.i)
  Protected diag.ApplyDiagnostics

  If profileId <> gAutoThermalSwitchProfile Or gAutoSwitchedProfile = 0
    gLastManualProfile = profileId
  EndIf

  LoadNamedPreset(profileId, gUseBoost, gUseCooling, gUseASPM)
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
  ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, @diag)
  SetStatus("Status: " + diag\Summary, diag\Details)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  ShowTrayNotification("Preset Applied", ProfileIdToName(profileId) + " preset is active.")
  RefreshMiniProfileBadge()
EndProcedure

Procedure ApplySingleModePresetAndRefresh(profileId.i, isBattery.i, reason$ = "")
  If isBattery
    ApplyProfileSelectionToTracks(profileId, #False, gUseBoost, gUseCooling, gUseASPM)
    gSettings\DCProfile = profileId
  Else
    ApplyProfileSelectionToTracks(profileId, #True, gUseBoost, gUseCooling, gUseASPM)
    gSettings\ACProfile = profileId
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
  ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  RefreshMiniProfileBadge()
  If reason$ <> ""
    If isBattery
      SetStatus("Status: " + reason$, ProfileIdToName(profileId) + " applied to battery mode.")
    Else
      SetStatus("Status: " + reason$, ProfileIdToName(profileId) + " applied to plugged-in mode.")
    EndIf
  EndIf
EndProcedure

Procedure LoadSettingsIntoUI(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If *settings\ACProfile <= 0 : *settings\ACProfile = #PROFILE_COOL : EndIf
  If *settings\DCProfile <= 0 : *settings\DCProfile = #PROFILE_BALANCED : EndIf

  SetGadgetState(#TrackACMax, *settings\ACMaxCPU)
  SetGadgetState(#TrackDCMax, *settings\DCMaxCPU)
  SetGadgetState(#TrackACMin, *settings\ACMinCPU)
  SetGadgetState(#TrackDCMin, *settings\DCMinCPU)
  SetComboStateByData(#ComboACProfile, *settings\ACProfile, 0)
  SetComboStateByData(#ComboDCProfile, *settings\DCProfile, 0)
  SetComboStateByData(#ComboACBoost, *settings\ACBoostMode, 0)
  SetComboStateByData(#ComboDCBoost, *settings\DCBoostMode, 0)
  SetComboStateByData(#ComboACCooling, *settings\ACCoolingPolicy, 0)
  SetComboStateByData(#ComboDCCooling, *settings\DCCoolingPolicy, 1)
  SetComboStateByData(#ComboACASPM, *settings\ACASPMMode, 1)
  SetComboStateByData(#ComboDCASPM, *settings\DCASPMMode, 1)
  SetGadgetState(#ChkAutoApply, *settings\AutoApply)
  SetGadgetState(#ChkLiveApply, *settings\LiveApply)
  SetGadgetState(#ChkRunAtStartup, *settings\RunAtStartup)
  SetGadgetState(#ChkUseTaskScheduler, *settings\UseTaskScheduler)
  SetGadgetState(#TrackHeatAlert, *settings\HeatAlertThreshold)
  SetGadgetText(#TxtHeatAlertVal, Str(*settings\HeatAlertThreshold) + " C")
  SetGadgetState(#ChkHeatAlertPopup, *settings\HeatAlertEnabled)
  SetGadgetState(#ChkAutoThermalSwitch, *settings\DCAutoSwitchEnabled)
  SetComboStateByData(#ComboAutoSwitchProfile, *settings\DCAutoSwitchProfile, 0)
  SetGadgetState(#TrackAutoSwitchDelay, *settings\DCAutoSwitchSeconds)
  SetGadgetText(#TxtAutoSwitchVal, Str(*settings\DCAutoSwitchThreshold) + " C / " + Str(*settings\DCAutoSwitchSeconds) + " sec")
  SetGadgetState(#ChkAutoRestore, *settings\DCAutoRestoreEnabled)
  SetGadgetState(#TrackAutoRestoreThreshold, *settings\DCAutoRestoreThreshold)
  SetGadgetState(#TrackAutoRestoreDelay, *settings\DCAutoRestoreSeconds)
  SetGadgetText(#TxtAutoRestoreVal, Str(*settings\DCAutoRestoreThreshold) + " C / " + Str(*settings\DCAutoRestoreSeconds) + " sec")
  SetComboStateByData(#ComboStartupMode, *settings\StartupMode, 0)
  UpdateProfilesFromCurrentUI(*settings)
  SyncProfileCombosFromSettings(*settings)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  UpdateAutomationDisplay()
EndProcedure

Procedure ExportCurrentProfile()
  Protected path$ = SaveFileRequester("Export cooling profile", GetPathPart(ProgramFilename()) + "MyCPUCooler-profile.ini", "INI (*.ini)|*.ini", 0)

  If path$ = ""
    ProcedureReturn
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  If CreatePreferences(path$)
    PreferenceGroup("Profile")
    WritePreferenceString("Name", "Exported " + FormatDate("%yyyy-%mm-%dd %hh:%ii", Date()))
    WritePreferenceLong("AC_Profile", gSettings\ACProfile)
    WritePreferenceLong("DC_Profile", gSettings\DCProfile)
    WritePreferenceLong("AC_MaxCPU", gSettings\ACMaxCPU)
    WritePreferenceLong("DC_MaxCPU", gSettings\DCMaxCPU)
    WritePreferenceLong("AC_MinCPU", gSettings\ACMinCPU)
    WritePreferenceLong("DC_MinCPU", gSettings\DCMinCPU)
    WritePreferenceLong("AC_BoostMode", gSettings\ACBoostMode)
    WritePreferenceLong("DC_BoostMode", gSettings\DCBoostMode)
    WritePreferenceLong("AC_CoolingPolicy", gSettings\ACCoolingPolicy)
    WritePreferenceLong("DC_CoolingPolicy", gSettings\DCCoolingPolicy)
    WritePreferenceLong("AC_ASPMMode", gSettings\ACASPMMode)
    WritePreferenceLong("DC_ASPMMode", gSettings\DCASPMMode)
    ClosePreferences()
    ShowTrayNotification("Profile Exported", path$)
  EndIf
EndProcedure

Procedure ImportCoolingProfile()
  Protected path$ = OpenFileRequester("Import cooling profile", GetPathPart(ProgramFilename()), "INI (*.ini)|*.ini", 0)

  If path$ = ""
    ProcedureReturn
  EndIf

  If OpenPreferences(path$)
    PreferenceGroup("Profile")
    gSettings\ACProfile = ReadPreferenceLong("AC_Profile", gSettings\ACProfile)
    gSettings\DCProfile = ReadPreferenceLong("DC_Profile", gSettings\DCProfile)
    gSettings\ACMaxCPU = ReadPreferenceLong("AC_MaxCPU", gSettings\ACMaxCPU)
    gSettings\DCMaxCPU = ReadPreferenceLong("DC_MaxCPU", gSettings\DCMaxCPU)
    gSettings\ACMinCPU = ReadPreferenceLong("AC_MinCPU", gSettings\ACMinCPU)
    gSettings\DCMinCPU = ReadPreferenceLong("DC_MinCPU", gSettings\DCMinCPU)
    gSettings\ACBoostMode = ReadPreferenceLong("AC_BoostMode", gSettings\ACBoostMode)
    gSettings\DCBoostMode = ReadPreferenceLong("DC_BoostMode", gSettings\DCBoostMode)
    gSettings\ACCoolingPolicy = ReadPreferenceLong("AC_CoolingPolicy", gSettings\ACCoolingPolicy)
    gSettings\DCCoolingPolicy = ReadPreferenceLong("DC_CoolingPolicy", gSettings\DCCoolingPolicy)
    gSettings\ACASPMMode = ReadPreferenceLong("AC_ASPMMode", gSettings\ACASPMMode)
    gSettings\DCASPMMode = ReadPreferenceLong("DC_ASPMMode", gSettings\DCASPMMode)
    ClosePreferences()
    LoadSettingsIntoUI(@gSettings)
    SaveAppSettings(gIniPath, @gSettings)
    ShowTrayNotification("Profile Imported", path$)
  EndIf
EndProcedure

Macro SaveCurrentRuntimeSettings()
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
EndMacro


EnsureAdmin()

gIniPath = GetPathPart(ProgramFilename()) + #APP_NAME + ".ini"
LogLine(#LOG_INFO, "iniPath=" + gIniPath)

; Quick probe (debug only): ensure powercfg is runnable and output capture works.
If gLogLevel = #LOG_DEBUG
  RunProgramCapture("powercfg", "/?")
  LogLine(#LOG_DEBUG, "powercfg probe exit=" + Str(gLastExitCode) + " outLen=" + Str(Len(gLastStdout)))
EndIf

StartSystemInfoUpdate(gIniPath)


Define applyDiag.ApplyDiagnostics
LoadAppSettings(gIniPath, @gSettings)

Define scheme$  = EnsureCustomScheme(#APP_NAME, gIniPath)
LogLine(#LOG_INFO, "Using scheme=" + scheme$)
gCurrentScheme = scheme$

; Ensure settings match what's currently in registry/INI (already done by LoadAppSettings)

Define useBoost.i = SupportsBoostModeSetting(scheme$)

LogLine(#LOG_INFO, "Supports boost setting=" + Str(useBoost))

Define useCooling.i = SupportsCoolingPolicySetting(scheme$)
LogLine(#LOG_INFO, "Supports cooling policy setting=" + Str(useCooling))
Define useASPM.i = SupportsASPMSetting(scheme$)
LogLine(#LOG_INFO, "Supports ASPM setting=" + Str(useASPM))

; Startup/background modes
If HasArg("--silent")
  LogLine(#LOG_INFO, "--silent requested; applying saved settings and exiting")
  If gSettings\AutoApply
    ApplySettings(scheme$, gSettings\ACMaxCPU, gSettings\DCMaxCPU, gSettings\ACMinCPU, gSettings\DCMinCPU,
                  gSettings\ACBoostMode, gSettings\DCBoostMode, useBoost,
                  gSettings\ACCoolingPolicy, gSettings\DCCoolingPolicy,
                  gSettings\ACASPMMode, gSettings\DCASPMMode)
  Else
    LogLine(#LOG_INFO, "AutoApply disabled; silent start exits without changing power settings")
  EndIf
  CloseHandle_(hMutex)
  End
EndIf

Define startInTray.i = HasArg("--tray")
Define startInMini.i = HasArg("--mini")


OpenWindow(#Win, 0, 0, 900, 830, #APP_NAME + " - " + version + " (powercfg)", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
LogLine(#LOG_INFO, "UI started")
gUseBoost = useBoost
gUseCooling = useCooling
gUseASPM = useASPM

OpenWindow(#WinMini, 0, 0, 290, 140, #APP_NAME + " Mini", #PB_Window_SystemMenu | #PB_Window_Tool | #PB_Window_ScreenCentered)
HideWindow(#WinMini, #True)
UseGadgetList(WindowID(#WinMini))
ResizeWindow(#WinMini, #PB_Ignore, #PB_Ignore, 360, 530)
TextGadget(#TxtMiniTelemetry, 12, 12, 336, 20, "CPU -- | --")
TextGadget(#TxtMiniThermal, 12, 34, 336, 20, "Thermal zone --")
TextGadget(#TxtMiniProfile, 12, 56, 336, 20, "AC -- | DC --")
TextGadget(#TxtAutomationMode, 12, 76, 336, 18, "AC automation -> Quiet | Restore 72 C / 45 sec")
CanvasGadget(#CanvasMiniHistory, 12, 96, 336, 76)
TextGadget(#TxtBenchmarkMode, 12, 178, 336, 18, "Benchmark mode inactive")
TextGadget(#PB_Any, 12, 200, 170, 18, "Heat alert threshold")
TextGadget(#TxtHeatAlertVal, 294, 200, 54, 18, "80 C")
TrackBarGadget(#TrackHeatAlert, 12, 218, 336, 22, 60, 100)
CheckBoxGadget(#ChkHeatAlertPopup, 12, 244, 200, 20, "Enable heat popup alerts")
CheckBoxGadget(#ChkAutoThermalSwitch, 12, 268, 210, 20, "Auto switch when heat persists")
ComboBoxGadget(#ComboAutoSwitchProfile, 12, 292, 164, 24)
TextGadget(#TxtAutoSwitchVal, 248, 294, 100, 18, "80 C / 30 sec")
TrackBarGadget(#TrackAutoSwitchDelay, 184, 292, 164, 22, 10, 120)
CheckBoxGadget(#ChkAutoRestore, 12, 322, 210, 20, "Restore after cooldown")
TextGadget(#TxtAutoRestoreVal, 248, 324, 100, 18, "70 C / 45 sec")
TrackBarGadget(#TrackAutoRestoreThreshold, 12, 344, 164, 22, 50, 95)
TrackBarGadget(#TrackAutoRestoreDelay, 184, 344, 164, 22, 15, 180)
ButtonGadget(#BtnSaveCustomProfile, 12, 374, 108, 24, "Save Slot")
ButtonGadget(#BtnLoadCustomProfile, 126, 374, 108, 24, "Load Slot")
ButtonGadget(#BtnBenchmarkMode, 240, 374, 108, 24, "Benchmark")
ButtonGadget(#BtnExportProfile, 12, 404, 108, 24, "Export")
ButtonGadget(#BtnImportProfile, 126, 404, 108, 24, "Import")
ComboBoxGadget(#ComboCustomProfile, 240, 404, 108, 24)
TextGadget(#PB_Any, 12, 434, 120, 18, "Startup mode")
ComboBoxGadget(#ComboStartupMode, 132, 430, 216, 24)
ButtonGadget(#BtnMiniToggleMain, 12, 462, 108, 26, "Show Main")
ButtonGadget(#BtnMiniApply, 126, 462, 108, 26, "Apply")
ButtonGadget(#BtnMiniBattery, 240, 462, 108, 26, "Battery")
ButtonGadget(#BtnMiniEco, 12, 494, 62, 26, "Eco")
ButtonGadget(#BtnMiniQuiet, 82, 494, 62, 26, "Quiet")
ButtonGadget(#BtnMiniCool, 152, 494, 62, 26, "Cool")
ButtonGadget(#BtnMiniBalanced, 222, 494, 62, 26, "Balanced")
ButtonGadget(#BtnMiniPerformance, 292, 494, 56, 26, "Perf")

UseGadgetList(WindowID(#Win))

TextGadget(#PB_Any, 15, 15, 870, 20, "Custom power scheme: " + scheme$)

TextGadget(#PB_Any, 15, 42, 870, 20, "Tune AC and battery behavior separately to keep laptops cooler than one-size-fits-all presets.")

TextGadget(#PB_Any, 15, 78, 250, 20, "AC (Plugged in) Max CPU %")
TextGadget(#TxtACMaxVal, 840, 78, 45, 20, "")
TrackBarGadget(#TrackACMax, 15, 98, 870, 25, 5, 100)
SetGadgetState(#TrackACMax, gSettings\ACMaxCPU)

TextGadget(#PB_Any, 15, 133, 250, 20, "DC (Battery) Max CPU %")
TextGadget(#TxtDCMaxVal, 840, 133, 45, 20, "")
TrackBarGadget(#TrackDCMax, 15, 153, 870, 25, 5, 100)
SetGadgetState(#TrackDCMax, gSettings\DCMaxCPU)

TextGadget(#PB_Any, 15, 188, 250, 20, "AC (Plugged in) Min CPU %")
TextGadget(#TxtACMinVal, 840, 188, 45, 20, "")
TrackBarGadget(#TrackACMin, 15, 208, 870, 25, 1, 100)
SetGadgetState(#TrackACMin, gSettings\ACMinCPU)

TextGadget(#PB_Any, 15, 243, 250, 20, "DC (Battery) Min CPU %")
TextGadget(#TxtDCMinVal, 840, 243, 45, 20, "")
TrackBarGadget(#TrackDCMin, 15, 263, 870, 25, 1, 100)
SetGadgetState(#TrackDCMin, gSettings\DCMinCPU)

TextGadget(#PB_Any, 15, 305, 120, 20, "AC profile:")
ComboBoxGadget(#ComboACProfile, 15, 325, 425, 25)

TextGadget(#PB_Any, 460, 305, 120, 20, "DC profile:")
ComboBoxGadget(#ComboDCProfile, 460, 325, 425, 25)

TextGadget(#PB_Any, 15, 365, 250, 20, "AC boost mode:")
ComboBoxGadget(#ComboACBoost, 15, 385, 425, 25)
TextGadget(#TxtACBoostVal, 15, 412, 425, 20, "")

TextGadget(#PB_Any, 460, 365, 250, 20, "DC boost mode:")
ComboBoxGadget(#ComboDCBoost, 460, 385, 425, 25)
TextGadget(#TxtDCBoostVal, 460, 412, 425, 20, "")

TextGadget(#PB_Any, 15, 445, 250, 20, "AC cooling policy:")
ComboBoxGadget(#ComboACCooling, 15, 465, 425, 25)

TextGadget(#PB_Any, 460, 445, 250, 20, "DC cooling policy:")
ComboBoxGadget(#ComboDCCooling, 460, 465, 425, 25)

TextGadget(#PB_Any, 15, 505, 250, 20, "AC Link State Power Mgmt (ASPM):")
ComboBoxGadget(#ComboACASPM, 15, 525, 425, 25)

TextGadget(#PB_Any, 460, 505, 250, 20, "DC Link State Power Mgmt (ASPM):")
ComboBoxGadget(#ComboDCASPM, 460, 525, 425, 25)

TextGadget(#TxtThermalHint, 15, 565, 870, 28, "")
TextGadget(#TxtTelemetrySummary, 15, 596, 870, 18, "Live telemetry: starting...")
TextGadget(#TxtTelemetryUpdated, 15, 616, 870, 18, "Waiting for first refresh.")

PopulateASPMCombo()
PopulateCoolingCombo()
PopulateBoostCombo()
PopulateProfileCombo(#ComboACProfile)
PopulateProfileCombo(#ComboDCProfile)
PopulatePresetOnlyProfileCombo(#ComboAutoSwitchProfile)
PopulateStartupModeCombo(#ComboStartupMode)
LoadCustomProfiles()
RefreshCustomProfileCombo()

SetComboStateByData(#ComboACBoost, gSettings\ACBoostMode, 0)
SetComboStateByData(#ComboDCBoost, gSettings\DCBoostMode, 0)
SetComboStateByData(#ComboACCooling, gSettings\ACCoolingPolicy, 0)
SetComboStateByData(#ComboDCCooling, gSettings\DCCoolingPolicy, 1)
SetComboStateByData(#ComboACASPM, gSettings\ACASPMMode, 1)
SetComboStateByData(#ComboDCASPM, gSettings\DCASPMMode, 1)
UpdateProfilesFromCurrentUI(@gSettings)
SyncProfileCombosFromSettings(@gSettings)

If useBoost = #False
  DisableGadget(#ComboACBoost, #True)
  DisableGadget(#ComboDCBoost, #True)
  SetGadgetText(#TxtACBoostVal, "AC boost: Not supported on this system")
  SetGadgetText(#TxtDCBoostVal, "DC boost: Not supported on this system")
EndIf

If useCooling = #False
  DisableGadget(#ComboACCooling, #True)
  DisableGadget(#ComboDCCooling, #True)
EndIf

If useASPM = #False
  DisableGadget(#ComboACASPM, #True)
  DisableGadget(#ComboDCASPM, #True)
EndIf

CheckBoxGadget(#ChkAutoApply, 15, 650, 425, 20, "Auto apply saved settings on startup")
SetGadgetState(#ChkAutoApply, gSettings\AutoApply)

CheckBoxGadget(#ChkLiveApply, 460, 650, 425, 20, "Live apply while adjusting")
SetGadgetState(#ChkLiveApply, gSettings\LiveApply)

CheckBoxGadget(#ChkRunAtStartup, 15, 674, 425, 20, "Run at Windows startup (applies settings silently)")
SetGadgetState(#ChkRunAtStartup, gSettings\RunAtStartup)

CheckBoxGadget(#ChkUseTaskScheduler, 460, 674, 425, 20, "Use Task Scheduler (no UAC prompt at login)")
SetGadgetState(#ChkUseTaskScheduler, gSettings\UseTaskScheduler)
SetGadgetState(#TrackHeatAlert, gSettings\HeatAlertThreshold)
SetGadgetText(#TxtHeatAlertVal, Str(gSettings\HeatAlertThreshold) + " C")
SetGadgetState(#ChkHeatAlertPopup, gSettings\HeatAlertEnabled)
gHeatAlertThreshold = gSettings\HeatAlertThreshold
gHeatPopupEnabled = gSettings\HeatAlertEnabled
SetGadgetState(#ChkAutoThermalSwitch, gSettings\AutoThermalSwitchEnabled)
SetComboStateByData(#ComboAutoSwitchProfile, gSettings\DCAutoSwitchProfile, 3)
SetGadgetState(#TrackAutoSwitchDelay, gSettings\DCAutoSwitchSeconds)
SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
SetComboStateByData(#ComboStartupMode, gSettings\StartupMode, 0)
SetGadgetState(#ChkAutoRestore, gSettings\AutoRestoreEnabled)
SetGadgetState(#TrackAutoRestoreThreshold, gSettings\DCAutoRestoreThreshold)
SetGadgetState(#TrackAutoRestoreDelay, gSettings\DCAutoRestoreSeconds)
SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
SetGadgetText(#TxtBenchmarkMode, "Benchmark mode inactive")
gAutoThermalSwitchEnabled = gSettings\AutoThermalSwitchEnabled
gAutoThermalSwitchProfile = gSettings\AutoThermalSwitchProfile
gAutoThermalSwitchSeconds = gSettings\AutoThermalSwitchSeconds
gAutoRestoreEnabled = gSettings\AutoRestoreEnabled
gAutoRestoreThreshold = gSettings\AutoRestoreThreshold
gAutoRestoreSeconds = gSettings\AutoRestoreSeconds

ButtonGadget(#BtnApply, 15, 700, 870, 28, "Apply now")

UpdateDisplayedValues(useBoost, useCooling, useASPM)
UpdateTelemetryDisplay()
EnsureTrayIcon()
If CreatePopupMenu(#TrayMain)
  MenuItem(#MenuTrayShowHide, "Toggle Window")
  MenuItem(#MenuTrayMiniDashboard, "Mini Dashboard")
  MenuItem(#MenuTrayApply, "Apply Current Settings")
  MenuBar()
  MenuItem(#MenuTrayRunAtStartup, "Run At Startup")
  MenuItem(#MenuTrayUseTaskScheduler, "Use Task Scheduler")
  MenuItem(#MenuTrayStartupMain, "Startup: Main Window")
  MenuItem(#MenuTrayStartupTray, "Startup: Tray")
  MenuItem(#MenuTrayStartupMini, "Startup: Mini Dashboard")
  MenuItem(#MenuTrayStartupSilent, "Startup: Silent Apply")
  MenuBar()
  MenuItem(#MenuTrayBattery, "Battery Preset")
  MenuItem(#MenuTrayEco, "Eco Preset")
  MenuItem(#MenuTrayQuiet, "Quiet Preset")
  MenuItem(#MenuTrayCool, "Cool Preset")
  MenuItem(#MenuTrayBalanced, "Balanced Preset")
  MenuItem(#MenuTrayPerformance, "Performance Preset")
  MenuBar()
  MenuItem(#MenuTrayRestoreBalanced, "Restore Windows Balanced")
  MenuBar()
  MenuItem(#MenuTrayExit, "Exit")
EndIf
AddWindowTimer(#Win, #TimerTelemetry, 7000)
StartTelemetryRefresh()
UpdateTrayMenuState()
RefreshMiniProfileBadge()

ButtonGadget(#BtnBatteryPreset, 15, 738, 140, 26, "Battery")
ButtonGadget(#BtnEcoPreset, 160, 738, 140, 26, "Eco")
ButtonGadget(#BtnQuietPreset, 305, 738, 140, 26, "Quiet")
ButtonGadget(#BtnCoolPreset, 450, 738, 140, 26, "Cool")
ButtonGadget(#BtnBalancedPreset, 595, 738, 140, 26, "Balanced")
ButtonGadget(#BtnPerfPreset, 740, 738, 145, 26, "Performance")

TextGadget(#TxtStatusSummary, 15, 770, 870, 18, "Status: Ready")
EditorGadget(#EditStatusDetails, 15, 790, 870, 18)
DisableGadget(#EditStatusDetails, #True)
SetStatus("Status: Ready", "Waiting for changes.")

ButtonGadget(#BtnRestoreBalanced, 15, 810, 870, 18, "Restore Windows Balanced plan (activate default)")

; Apply on startup if enabled
If gSettings\AutoApply
  LogLine(#LOG_INFO, "AutoApply enabled; applying on startup")
  applyDiag\SuccessCount = 0
  applyDiag\FailureCount = 0
  applyDiag\Summary = ""
  applyDiag\Details = ""
  ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, @applyDiag)
  SetStatus("Status: " + applyDiag\Summary, applyDiag\Details)
Else
  LogLine(#LOG_INFO, "AutoApply disabled")
EndIf

UpdateTrayMenuState()

Select gSettings\StartupMode
  Case 1
    ShowMainWindow(#False)
  Case 2
    ShowMainWindow(#False)
    ShowMiniDashboard(#True)
EndSelect

If startInTray
  ShowMainWindow(#False)
  ShowMiniDashboard(#False)
ElseIf startInMini
  ShowMainWindow(#False)
  ShowMiniDashboard(#True)
EndIf



Define ev, acBoostValue, dcBoostValue

Repeat
  ev = WaitWindowEvent()

  Select ev
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #ChkAutoApply, #ChkLiveApply, #ChkRunAtStartup, #ChkUseTaskScheduler
          gSettings\AutoApply = GetGadgetState(#ChkAutoApply)
          gSettings\LiveApply = GetGadgetState(#ChkLiveApply)
          gSettings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
          gSettings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
          SaveAppSettings(gIniPath, @gSettings)

        Case #TrackHeatAlert
          gSettings\HeatAlertThreshold = GetGadgetState(#TrackHeatAlert)
          gHeatAlertThreshold = gSettings\HeatAlertThreshold
          SetGadgetText(#TxtHeatAlertVal, Str(gSettings\HeatAlertThreshold) + " C")
          SaveAppSettings(gIniPath, @gSettings)

        Case #ChkHeatAlertPopup
          gSettings\HeatAlertEnabled = GetGadgetState(#ChkHeatAlertPopup)
          gHeatPopupEnabled = gSettings\HeatAlertEnabled
          SaveAppSettings(gIniPath, @gSettings)

        Case #ChkAutoThermalSwitch
          gSettings\AutoThermalSwitchEnabled = GetGadgetState(#ChkAutoThermalSwitch)
          gAutoThermalSwitchEnabled = gSettings\AutoThermalSwitchEnabled
          SaveAppSettings(gIniPath, @gSettings)

        Case #ComboAutoSwitchProfile
          gSettings\AutoThermalSwitchProfile = GetSelectedItemData(#ComboAutoSwitchProfile, #PROFILE_COOL)
          gAutoThermalSwitchProfile = gSettings\AutoThermalSwitchProfile
          SaveAppSettings(gIniPath, @gSettings)

        Case #TrackAutoSwitchDelay
          If LCase(gTelemetry\PowerSource) = "battery"
            gSettings\DCAutoSwitchSeconds = GetGadgetState(#TrackAutoSwitchDelay)
            SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
          Else
            gSettings\ACAutoSwitchSeconds = GetGadgetState(#TrackAutoSwitchDelay)
            SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\ACAutoSwitchThreshold) + " C / " + Str(gSettings\ACAutoSwitchSeconds) + " sec")
          EndIf
          SaveAppSettings(gIniPath, @gSettings)

        Case #ComboStartupMode
          gSettings\StartupMode = GetSelectedItemData(#ComboStartupMode, 0)
          SaveAppSettings(gIniPath, @gSettings)

        Case #ChkAutoRestore
          gSettings\AutoRestoreEnabled = GetGadgetState(#ChkAutoRestore)
          gAutoRestoreEnabled = gSettings\AutoRestoreEnabled
          SaveAppSettings(gIniPath, @gSettings)

        Case #TrackAutoRestoreThreshold
          If LCase(gTelemetry\PowerSource) = "battery"
            gSettings\DCAutoRestoreThreshold = GetGadgetState(#TrackAutoRestoreThreshold)
            SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
          Else
            gSettings\ACAutoRestoreThreshold = GetGadgetState(#TrackAutoRestoreThreshold)
            SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
          EndIf
          SaveAppSettings(gIniPath, @gSettings)

        Case #TrackAutoRestoreDelay
          If LCase(gTelemetry\PowerSource) = "battery"
            gSettings\DCAutoRestoreSeconds = GetGadgetState(#TrackAutoRestoreDelay)
            SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
          Else
            gSettings\ACAutoRestoreSeconds = GetGadgetState(#TrackAutoRestoreDelay)
            SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
          EndIf
          SaveAppSettings(gIniPath, @gSettings)

        Case #BtnExportProfile
          ExportCurrentProfile()

        Case #BtnImportProfile
          ImportCoolingProfile()

        Case #BtnSaveCustomProfile
          SaveCustomProfileFromCurrentUI()

        Case #BtnLoadCustomProfile
          LoadSelectedCustomProfile()

        Case #BtnBenchmarkMode
          EnterBenchmarkMode()

        Case #TrackACMax, #TrackDCMax, #TrackACMin, #TrackDCMin, #ComboACBoost, #ComboDCBoost, #ComboACCooling, #ComboDCCooling, #ComboACASPM, #ComboDCASPM
          UpdateProfilesFromCurrentUI(@gSettings)
          SyncProfileCombosFromSettings(@gSettings)
          UpdateDisplayedValues(useBoost, useCooling, useASPM)
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #ComboACProfile
          gSettings\ACProfile = GetSelectedItemData(#ComboACProfile, 0)
          ApplyProfileSelectionToTracks(gSettings\ACProfile, #True, useBoost, useCooling, useASPM)
          SetStatus("Status: AC profile selected", ProfileIdToName(gSettings\ACProfile) + " loaded into the plugged-in sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #ComboDCProfile
          gSettings\DCProfile = GetSelectedItemData(#ComboDCProfile, 0)
          If gSettings\DCProfile <= 0
            gSettings\DCProfile = #PROFILE_BALANCED
            SetComboStateByData(#ComboDCProfile, gSettings\DCProfile, 4)
          EndIf
          ApplyProfileSelectionToTracks(gSettings\DCProfile, #False, useBoost, useCooling, useASPM)
          SetStatus("Status: DC profile selected", ProfileIdToName(gSettings\DCProfile) + " loaded into the battery sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnBatteryPreset
          ApplyPresetAndRefresh(#PROFILE_BATTERY_SAVER)
          SetStatus("Status: Preset loaded", "Battery Saver applied to both AC and DC sliders.")

        Case #BtnEcoPreset
          ApplyPresetAndRefresh(#PROFILE_ECO)
          SetStatus("Status: Preset loaded", "Eco applied to both AC and DC sliders.")

        Case #BtnQuietPreset
          ApplyPresetAndRefresh(#PROFILE_QUIET)
          SetStatus("Status: Preset loaded", "Quiet applied to both AC and DC sliders.")

        Case #BtnCoolPreset
          ApplyPresetAndRefresh(#PROFILE_COOL)
          SetStatus("Status: Preset loaded", "Cool applied to both AC and DC sliders.")

        Case #BtnBalancedPreset
          ApplyPresetAndRefresh(#PROFILE_BALANCED)
          SetStatus("Status: Preset loaded", "Balanced applied to both AC and DC sliders.")

        Case #BtnPerfPreset
          ApplyPresetAndRefresh(#PROFILE_PERFORMANCE)
          SetStatus("Status: Preset loaded", "Performance applied to both AC and DC sliders.")

        Case #BtnRestoreBalanced
          RestoreBalanced()
          SetStatus("Status: Windows Balanced restored", "The default Windows Balanced scheme is active.")
          MessageRequester("Balanced restored", "Activated the default Windows Balanced plan." + #CRLF$ + 
                                                "You can re-apply the custom scheme anytime With 'Apply now'.", #PB_MessageRequester_Info)

        Case #BtnApply
          LogLine(#LOG_INFO, "Apply button clicked")
          Define acMaxVal = GetGadgetState(#TrackACMax)
          Define dcMaxVal = GetGadgetState(#TrackDCMax)
          Define acMinVal = GetGadgetState(#TrackACMin)
          Define dcMinVal = GetGadgetState(#TrackDCMin)

          acBoostValue = ACBoostArg(useBoost)
          dcBoostValue = DCBoostArg(useBoost)

          UpdateDisplayedValues(useBoost, useCooling, useASPM)

          SaveCurrentUIToSettings(@gSettings, useBoost, useCooling, useASPM)
          SaveAppSettings(gIniPath, @gSettings)

          applyDiag\SuccessCount = 0
          applyDiag\FailureCount = 0
          applyDiag\Summary = ""
          applyDiag\Details = ""
          ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, @applyDiag)
          SetStatus("Status: " + applyDiag\Summary, applyDiag\Details)

          If applyDiag\FailureCount = 0 And useBoost
            MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                                     "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ +
                                     "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                                     "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                                     "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                                     "AC boost: " + BoostModeLabel(acBoostValue) + " (" + Str(acBoostValue) + ")" + #CRLF$ +
                                     "DC boost: " + BoostModeLabel(dcBoostValue) + " (" + Str(dcBoostValue) + ")", #PB_MessageRequester_Info)
            ShowTrayNotification("Settings Applied", "Custom scheme updated successfully.")
          ElseIf applyDiag\FailureCount = 0
            MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                                     "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ +
                                     "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                                     "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                                     "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                                     "Boost mode is not available on this system.", #PB_MessageRequester_Info)
            ShowTrayNotification("Settings Applied", "Custom scheme updated successfully.")
          Else
            MessageRequester("Apply completed with errors", applyDiag\Summary + #CRLF$ + #CRLF$ + applyDiag\Details, #PB_MessageRequester_Warning)
            ShowTrayNotification("Apply Warning", applyDiag\Summary)
          EndIf

        Case #BtnMiniToggleMain
          ShowMainWindow(Bool(gMainWindowVisible = #False))

        Case #BtnMiniApply
          applyDiag\SuccessCount = 0
          applyDiag\FailureCount = 0
          applyDiag\Summary = ""
          applyDiag\Details = ""
          SaveCurrentRuntimeSettings()
          ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, @applyDiag)
          SetStatus("Status: " + applyDiag\Summary, applyDiag\Details)
          ShowTrayNotification("Settings Applied", applyDiag\Summary)

        Case #BtnMiniBattery
          ApplyPresetAndRefresh(#PROFILE_BATTERY_SAVER)

        Case #BtnMiniEco
          ApplyPresetAndRefresh(#PROFILE_ECO)

        Case #BtnMiniQuiet
          ApplyPresetAndRefresh(#PROFILE_QUIET)

        Case #BtnMiniCool
          ApplyPresetAndRefresh(#PROFILE_COOL)

        Case #BtnMiniBalanced
          ApplyPresetAndRefresh(#PROFILE_BALANCED)

        Case #BtnMiniPerformance
          ApplyPresetAndRefresh(#PROFILE_PERFORMANCE)

      EndSelect

    Case #PB_Event_Menu
      Select EventMenu()
        Case #MenuTrayShowHide
          ShowMainWindow(Bool(gMainWindowVisible = #False))

        Case #MenuTrayMiniDashboard
          ShowMiniDashboard(Bool(gMiniWindowVisible = #False))

        Case #MenuTrayApply
          applyDiag\SuccessCount = 0
          applyDiag\FailureCount = 0
          applyDiag\Summary = ""
          applyDiag\Details = ""
          SaveCurrentRuntimeSettings()
          ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, @applyDiag)
          SetStatus("Status: " + applyDiag\Summary, applyDiag\Details)
          ShowTrayNotification("Settings Applied", applyDiag\Summary)

        Case #MenuTrayRunAtStartup
          gSettings\RunAtStartup = Bool(gSettings\RunAtStartup = 0)
          If IsGadget(#ChkRunAtStartup)
            SetGadgetState(#ChkRunAtStartup, gSettings\RunAtStartup)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          If gSettings\RunAtStartup
            ShowTrayNotification("Startup Enabled", "MyCPUCooler will run at logon.")
          Else
            ShowTrayNotification("Startup Disabled", "MyCPUCooler will not run at logon.")
          EndIf

        Case #MenuTrayUseTaskScheduler
          gSettings\UseTaskScheduler = Bool(gSettings\UseTaskScheduler = 0)
          If IsGadget(#ChkUseTaskScheduler)
            SetGadgetState(#ChkUseTaskScheduler, gSettings\UseTaskScheduler)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          If gSettings\UseTaskScheduler
            ShowTrayNotification("Task Scheduler Enabled", "Startup will use Task Scheduler.")
          Else
            ShowTrayNotification("Run Key Enabled", "Startup will use the Run registry key.")
          EndIf

        Case #MenuTrayStartupMain
          gSettings\StartupMode = 0
          If IsGadget(#ComboStartupMode)
            SetComboStateByData(#ComboStartupMode, 0, 0)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          ShowTrayNotification("Startup Mode", "Startup will open the main window.")

        Case #MenuTrayStartupTray
          gSettings\StartupMode = 1
          If IsGadget(#ComboStartupMode)
            SetComboStateByData(#ComboStartupMode, 1, 1)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          ShowTrayNotification("Startup Mode", "Startup will open in the tray.")

        Case #MenuTrayStartupMini
          gSettings\StartupMode = 2
          If IsGadget(#ComboStartupMode)
            SetComboStateByData(#ComboStartupMode, 2, 2)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          ShowTrayNotification("Startup Mode", "Startup will open the mini dashboard.")

        Case #MenuTrayStartupSilent
          gSettings\StartupMode = 3
          If IsGadget(#ComboStartupMode)
            SetComboStateByData(#ComboStartupMode, 3, 3)
          EndIf
          SaveAppSettings(gIniPath, @gSettings)
          ShowTrayNotification("Startup Mode", "Startup will silently apply and exit.")

        Case #MenuTrayBattery
          ApplyPresetAndRefresh(#PROFILE_BATTERY_SAVER)

        Case #MenuTrayEco
          ApplyPresetAndRefresh(#PROFILE_ECO)

        Case #MenuTrayQuiet
          ApplyPresetAndRefresh(#PROFILE_QUIET)

        Case #MenuTrayCool
          ApplyPresetAndRefresh(#PROFILE_COOL)

        Case #MenuTrayBalanced
          ApplyPresetAndRefresh(#PROFILE_BALANCED)

        Case #MenuTrayPerformance
          ApplyPresetAndRefresh(#PROFILE_PERFORMANCE)

        Case #MenuTrayRestoreBalanced
          RestoreBalanced()
          SetStatus("Status: Windows Balanced restored", "The default Windows Balanced scheme is active.")

        Case #MenuTrayExit
          CloseHandle_(hMutex)
          End
      EndSelect

    Case #PB_Event_Timer
      If EventTimer() = #TimerTelemetry
        If gTelemetryBusy = #False
          StartTelemetryRefresh()
        EndIf
        UpdateTelemetryDisplay()
      EndIf

    Case #PB_Event_SysTray
      If gTrayReady = 0
        Continue
      EndIf
      Select EventType()
        Case #PB_EventType_LeftDoubleClick
          ShowMainWindow(Bool(gMainWindowVisible = #False))
          If gMiniWindowVisible
            ShowMiniDashboard(#False)
          EndIf

        Case #PB_EventType_RightClick
          DisplayPopupMenu(#TrayMain, WindowID(#Win))
      EndSelect

    Case #PB_Event_CloseWindow
      LogLine(#LOG_INFO, "Close requested")
      If EventWindow() = #WinMini
        ShowMiniDashboard(#False)
      Else
        If EnsureTrayIcon() = 0
          MessageRequester("Tray icon unavailable", "The tray icon could not be created, so the app will stay visible instead of hiding.", #PB_MessageRequester_Warning)
          ShowMainWindow(#True)
          Continue
        EndIf
        ShowMainWindow(#False)
        SetStatus("Status: Minimized to tray", "Double-click the tray icon to re-open the window.")
      EndIf

  EndSelect
ForEver

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 3040
; FirstLine = 3037
; Folding = ------------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = MyCPUCooler.ico
; Executable = ..\MyCPUCooler.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = MyCPUCooler
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = Chooses the coolest powerplan
; VersionField7 = MyCPUCooler
; VersionField8 = MyCPUCooler.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60