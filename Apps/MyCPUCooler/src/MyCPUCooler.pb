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
Global version.s = "v1.0.0.4"

; Registry base key (HKCU)
#APP_NAME = "MyCPUCooler"
#REG_BASE$ = "Software\" + #APP_NAME

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

; Minimal registry constants (avoid PB version differences)
#HKEY_CURRENT_USER = $80000001
#KEY_READ  = $20019
#KEY_WRITE = $20006
#REG_SZ = 1
#REG_EXPAND_SZ = 2
#REG_DWORD = 4

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
  AutoApply.i
  LiveApply.i
  RunAtStartup.i
  UseTaskScheduler.i
EndStructure


; Forward declarations (used before definitions)
Declare LoadAppSettings(iniPath$, *settings.AppSettings)
Declare SaveAppSettings(iniPath$, *settings.AppSettings)
Declare UpdateDisplayedValues(useBoost.i)
Declare SetStatus(summary$, detail$ = "")
Declare LoadPreset(useBoost.i, useCooling.i, acMax.i, dcMax.i, acMin.i, dcMin.i, boostValue.i, coolingPolicy.i, aspmValue.i)

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

Procedure LoadProfileDefaults(profileId.i, *acMax.Integer, *dcMax.Integer, *acMin.Integer, *dcMin.Integer, *boostValue.Integer, *coolingPolicy.Integer, *aspmValue.Integer)
  If *acMax = 0 Or *dcMax = 0 Or *acMin = 0 Or *dcMin = 0 Or *boostValue = 0 Or *coolingPolicy = 0 Or *aspmValue = 0
    ProcedureReturn
  EndIf

  Select profileId
    Case #PROFILE_BATTERY_SAVER
      *acMax\i = 65 : *dcMax\i = 50 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_DISABLED : *coolingPolicy\i = 1 : *aspmValue\i = 2
    Case #PROFILE_ECO
      *acMax\i = 75 : *dcMax\i = 60 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_DISABLED : *coolingPolicy\i = 1 : *aspmValue\i = 2
    Case #PROFILE_QUIET
      *acMax\i = 85 : *dcMax\i = 70 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_DISABLED : *coolingPolicy\i = 1 : *aspmValue\i = 2
    Case #PROFILE_BALANCED
      *acMax\i = 100 : *dcMax\i = 85 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_EFFICIENT : *coolingPolicy\i = 0 : *aspmValue\i = 1
    Case #PROFILE_PERFORMANCE
      *acMax\i = 100 : *dcMax\i = 100 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_EFFICIENT_AGGRESSIVE : *coolingPolicy\i = 0 : *aspmValue\i = 0
    Default
      *acMax\i = 99 : *dcMax\i = 80 : *acMin\i = 5 : *dcMin\i = 5 : *boostValue\i = #BOOST_DISABLED : *coolingPolicy\i = 1 : *aspmValue\i = 2
  EndSelect
EndProcedure

Procedure ApplyProfileToSettings(profileId.i, *settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected boostValue.Integer, coolingPolicy.Integer, aspmValue.Integer

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin, @boostValue, @coolingPolicy, @aspmValue)
  *settings\ACMaxCPU = acMax\i
  *settings\DCMaxCPU = dcMax\i
  *settings\ACMinCPU = acMin\i
  *settings\DCMinCPU = dcMin\i
  *settings\BoostMode = boostValue\i
  *settings\CoolingPolicy = coolingPolicy\i
  *settings\ASPMMode = aspmValue\i
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

Procedure VerifyAppliedSettings(scheme$, acMax.i, dcMax.i, acMin.i, dcMin.i, boostValue.i, useBoost.i, coolingPolicy.i, aspmValue.i, *diag.ApplyDiagnostics)
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
    ElseIf actualValue <> boostValue
      AppendDiagnosticDetail(*diag, "Verify AC boost mode: expected " + Str(boostValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf

    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_BOOST_MODE$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC boost mode: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> boostValue
      AppendDiagnosticDetail(*diag, "Verify DC boost mode: expected " + Str(boostValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If coolingPolicy >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_SYS_COOLING_POLICY$, #True)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify AC cooling policy: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> coolingPolicy
      AppendDiagnosticDetail(*diag, "Verify AC cooling policy: expected " + Str(coolingPolicy) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf

    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PROCESSOR$, #SET_SYS_COOLING_POLICY$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC cooling policy: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> coolingPolicy
      AppendDiagnosticDetail(*diag, "Verify DC cooling policy: expected " + Str(coolingPolicy) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf
  EndIf

  If aspmValue >= 0
    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PCIE$, #SET_ASPM$, #True)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify AC ASPM: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> aspmValue
      AppendDiagnosticDetail(*diag, "Verify AC ASPM: expected " + Str(aspmValue) + ", got " + Str(actualValue))
      mismatches + 1
    EndIf

    actualValue = ReadCurrentSettingValue(scheme$, #SUB_PCIE$, #SET_ASPM$, #False)
    If actualValue = #VERIFY_NOT_FOUND
      AppendDiagnosticDetail(*diag, "Verify DC ASPM: unable to read back current value")
      mismatches + 1
    ElseIf actualValue <> aspmValue
      AppendDiagnosticDetail(*diag, "Verify DC ASPM: expected " + Str(aspmValue) + ", got " + Str(actualValue))
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


Procedure ApplySettings(scheme$, acMax.i, dcMax.i, acMin.i, dcMin.i, boostValue.i, useBoost.i, coolingPolicy.i, aspmValue.i, *diag.ApplyDiagnostics = 0)
  LogLine(#LOG_INFO, "ApplySettings scheme=" + scheme$ +
                     " acMax=" + Str(acMax) + " dcMax=" + Str(dcMax) +
                     " acMin=" + Str(acMin) + " dcMin=" + Str(dcMin) +
                     " boost=" + Str(boostValue) + " useBoost=" + Str(useBoost) +
                     " coolingPolicy=" + Str(coolingPolicy) +
                     " aspm=" + Str(aspmValue))

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
    RunPowerCfgStep(*diag, "Set AC boost mode", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(boostValue))
    RunPowerCfgStep(*diag, "Set DC boost mode", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(boostValue))
  EndIf


  ; Cooling policy (0=Active (fan first), 1=Passive (throttle first))
  If coolingPolicy >= 0
    If coolingPolicy <> 0 And coolingPolicy <> 1
      coolingPolicy = 0
    EndIf
    RunPowerCfgStep(*diag, "Set AC cooling policy", "-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
    RunPowerCfgStep(*diag, "Set DC cooling policy", "-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
  EndIf

  ; ASPM (0=Off, 1=Moderate, 2=Maximum)
  If aspmValue >= 0
    If aspmValue > 2
      aspmValue = 2
    EndIf
    RunPowerCfgStep(*diag, "Set AC ASPM", "-setacvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(aspmValue))
    RunPowerCfgStep(*diag, "Set DC ASPM", "-setdcvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(aspmValue))
  EndIf

  ; activate scheme
  RunPowerCfgStep(*diag, "Activate power scheme", "-S " + scheme$)
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "Failed to activate scheme. exit=" + Str(gLastExitCode))
  EndIf

  VerifyAppliedSettings(scheme$, acMax, dcMax, acMin, dcMin, boostValue, useBoost, coolingPolicy, aspmValue, *diag)

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
  *settings\CoolingPolicy = 0 ; 0=Active (fan first), 1=Passive (throttle first)
  *settings\ASPMMode = 1 ; 0=Off, 1=Moderate, 2=Max
  *settings\AutoApply = 1
  *settings\LiveApply = 0
  *settings\RunAtStartup = 0
  *settings\UseTaskScheduler = 1
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
  *settings\AutoApply  = RegReadDword(settingsKey$, "AutoApply", *settings\AutoApply)
  *settings\LiveApply  = RegReadDword(settingsKey$, "LiveApply", *settings\LiveApply)
  *settings\RunAtStartup     = RegReadDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  *settings\UseTaskScheduler = RegReadDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)

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
      *settings\AutoApply    = ReadPreferenceLong("AutoApply", *settings\AutoApply)
      *settings\LiveApply    = ReadPreferenceLong("LiveApply", *settings\LiveApply)
      *settings\RunAtStartup     = ReadPreferenceLong("RunAtStartup", *settings\RunAtStartup)
      *settings\UseTaskScheduler = ReadPreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
      ClosePreferences()
    EndIf
  EndIf

  *settings\ACMaxCPU = ClampPercent(*settings\ACMaxCPU, 5, 100)
  *settings\DCMaxCPU = ClampPercent(*settings\DCMaxCPU, 5, 100)
  *settings\ACMinCPU = ClampPercent(*settings\ACMinCPU, 1, 100)
  *settings\DCMinCPU = ClampPercent(*settings\DCMinCPU, 1, 100)
  If *settings\ACMinCPU > *settings\ACMaxCPU : *settings\ACMinCPU = *settings\ACMaxCPU : EndIf
  If *settings\DCMinCPU > *settings\DCMaxCPU : *settings\DCMinCPU = *settings\DCMaxCPU : EndIf
  If *settings\CoolingPolicy <> 0 And *settings\CoolingPolicy <> 1 : *settings\CoolingPolicy = 0 : EndIf
  If *settings\ASPMMode < 0 Or *settings\ASPMMode > 2 : *settings\ASPMMode = 1 : EndIf
EndProcedure


Procedure SaveAppSettings(iniPath$, *settings.AppSettings)
  ; Persist app settings
  LogLine(#LOG_INFO, "SaveAppSettings" +
                     " acMax=" + Str(*settings\ACMaxCPU) + " dcMax=" + Str(*settings\DCMaxCPU) +
                     " acMin=" + Str(*settings\ACMinCPU) + " dcMin=" + Str(*settings\DCMinCPU) +
                     " boost=" + Str(*settings\BoostMode) + " coolingPolicy=" + Str(*settings\CoolingPolicy) +
                     " aspm=" + Str(*settings\ASPMMode) +
                     " autoApply=" + Str(*settings\AutoApply) + " liveApply=" + Str(*settings\LiveApply) +
                     " runAtStartup=" + Str(*settings\RunAtStartup) + " useTaskScheduler=" + Str(*settings\UseTaskScheduler))
  Protected settingsKey$ = #REG_BASE$ + "\\Settings"
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
  RegWriteDword(settingsKey$, "AutoApply", *settings\AutoApply)
  RegWriteDword(settingsKey$, "LiveApply", *settings\LiveApply)
  RegWriteDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  RegWriteDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)

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
    WritePreferenceLong("AutoApply", *settings\AutoApply)

    WritePreferenceLong("LiveApply", *settings\LiveApply)
    WritePreferenceLong("RunAtStartup", *settings\RunAtStartup)
    WritePreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
    ClosePreferences()
  EndIf

  ; Startup integration (Run key or Task Scheduler)
  Protected runValue$ = Chr(34) + ProgramFilename() + Chr(34) + " --silent"

  Protected runKey$ = "Software\\Microsoft\\Windows\\CurrentVersion\\Run"
  If *settings\RunAtStartup And *settings\UseTaskScheduler = 0
    RegWriteString(runKey$, #APP_NAME, runValue$)
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
                                     " /SC ONLOGON /RL HIGHEST /TR " + Chr(34) + runValue$ + Chr(34))
      If gLastExitCode <> 0
        LogLine(#LOG_ERROR, "schtasks create failed exit=" + Str(gLastExitCode))
        If gLastStdout <> "" : LogLine(#LOG_ERROR, "output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
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
  #ComboBoost
  #ComboCooling
  #ComboASPM

  #TxtACMaxVal
  #TxtDCMaxVal
  #TxtACMinVal
  #TxtDCMinVal
  #TxtBoostVal
  #TxtStatusSummary
  #EditStatusDetails


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

Procedure PopulateBoostCombo()
  AddComboItemWithData(#ComboBoost, "Disabled (coolest)", #BOOST_DISABLED)
  AddComboItemWithData(#ComboBoost, "Enabled (default)", #BOOST_ENABLED)
  AddComboItemWithData(#ComboBoost, "Efficient Enabled (cooler)", #BOOST_EFFICIENT)
  AddComboItemWithData(#ComboBoost, "Efficient Aggressive (warm)", #BOOST_EFFICIENT_AGGRESSIVE)
  AddComboItemWithData(#ComboBoost, "Aggressive (hottest)", #BOOST_AGGRESSIVE)
EndProcedure

Procedure PopulateCoolingCombo()
  AddComboItemWithData(#ComboCooling, "Active (fan first)", 0)
  AddComboItemWithData(#ComboCooling, "Passive (throttle first)", 1)
EndProcedure

Procedure PopulateASPMCombo()
  AddComboItemWithData(#ComboASPM, "Off (performance)", 0)
  AddComboItemWithData(#ComboASPM, "Moderate Power Savings", 1)
  AddComboItemWithData(#ComboASPM, "Maximum Power Savings", 2)
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
  Protected boostValue.Integer, coolingPolicy.Integer, aspmValue.Integer
  Protected profileId.i

  *settings\ACProfile = 0
  *settings\DCProfile = 0

  For profileId = #PROFILE_BATTERY_SAVER To #PROFILE_PERFORMANCE
    LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin, @boostValue, @coolingPolicy, @aspmValue)
    If *settings\ACMaxCPU = acMax\i And *settings\ACMinCPU = acMin\i
      *settings\ACProfile = profileId
    EndIf
    If *settings\DCMaxCPU = dcMax\i And *settings\DCMinCPU = dcMin\i
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
  UpdateProfilesFromCurrentSettings(*settings)
EndProcedure

Procedure SyncProfileCombosFromSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If *settings\ACProfile > 0
    SetComboStateByData(#ComboACProfile, *settings\ACProfile, 0)
  ElseIf IsGadget(#ComboACProfile)
    SetGadgetState(#ComboACProfile, -1)
  EndIf

  If *settings\DCProfile > 0
    SetComboStateByData(#ComboDCProfile, *settings\DCProfile, 0)
  ElseIf IsGadget(#ComboDCProfile)
    SetGadgetState(#ComboDCProfile, -1)
  EndIf
EndProcedure

Procedure ApplyProfileSelectionToTracks(profileId.i, isAC.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected boostValue.Integer, coolingPolicy.Integer, aspmValue.Integer

  If profileId < #PROFILE_BATTERY_SAVER Or profileId > #PROFILE_PERFORMANCE
    ProcedureReturn
  EndIf

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin, @boostValue, @coolingPolicy, @aspmValue)

  If isAC
    SetGadgetState(#TrackACMax, acMax\i)
    SetGadgetState(#TrackACMin, acMin\i)
  Else
    SetGadgetState(#TrackDCMax, dcMax\i)
    SetGadgetState(#TrackDCMin, dcMin\i)
  EndIf

  If useBoost
    SetComboStateByData(#ComboBoost, boostValue\i, 0)
  EndIf
  If useCooling
    SetComboStateByData(#ComboCooling, coolingPolicy\i, 0)
  EndIf
  If useASPM
    SetComboStateByData(#ComboASPM, aspmValue\i, 1)
  EndIf

  UpdateDisplayedValues(useBoost)
EndProcedure

Procedure.i CoolingPolicyArg(useCooling.i)
  If useCooling
    ProcedureReturn GetSelectedItemData(#ComboCooling, 0)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i ASPMArg()
  ProcedureReturn GetSelectedItemData(#ComboASPM, 1)
EndProcedure

Procedure.i ASPMArgIfSupported(useASPM.i)
  If useASPM
    ProcedureReturn ASPMArg()
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i BoostArg(useBoost.i)
  If useBoost
    ProcedureReturn GetSelectedItemData(#ComboBoost, #BOOST_DISABLED)
  EndIf
  ProcedureReturn #BOOST_DISABLED
EndProcedure

Procedure ApplyCurrentGadgetSettings(scheme$, useBoost.i, useCooling.i, useASPM.i, *diag.ApplyDiagnostics = 0)
  ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), BoostArg(useBoost), useBoost, CoolingPolicyArg(useCooling), ASPMArgIfSupported(useASPM), *diag)
EndProcedure

Procedure LoadNamedPreset(profileId.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected boostValue.Integer, coolingPolicy.Integer, aspmValue.Integer

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin, @boostValue, @coolingPolicy, @aspmValue)
  LoadPreset(useBoost, useCooling, acMax\i, dcMax\i, acMin\i, dcMin\i, boostValue\i, coolingPolicy\i, aspmValue\i)
  SetComboStateByData(#ComboACProfile, profileId, 0)
  SetComboStateByData(#ComboDCProfile, profileId, 0)
EndProcedure

Procedure.i ASPMValueForApply(savedValue.i, useASPM.i)
  If useASPM
    ProcedureReturn savedValue
  EndIf
  ProcedureReturn -1
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
  *settings\BoostMode = BoostArg(useBoost)
  If useCooling
    *settings\CoolingPolicy = CoolingPolicyArg(useCooling)
  EndIf
  *settings\ASPMMode = ASPMArgIfSupported(useASPM)
  *settings\AutoApply = GetGadgetState(#ChkAutoApply)
  *settings\LiveApply = GetGadgetState(#ChkLiveApply)
  *settings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
  *settings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
EndProcedure

Procedure LoadPreset(useBoost.i, useCooling.i, acMax.i, dcMax.i, acMin.i, dcMin.i, boostValue.i, coolingPolicy.i, aspmValue.i)
  SetGadgetState(#TrackACMax, acMax)
  SetGadgetState(#TrackDCMax, dcMax)
  SetGadgetState(#TrackACMin, acMin)
  SetGadgetState(#TrackDCMin, dcMin)

  If useBoost
    SetComboStateByData(#ComboBoost, boostValue, 0)
  EndIf

  If useCooling
    SetComboStateByData(#ComboCooling, coolingPolicy, 0)
  EndIf

  SetComboStateByData(#ComboASPM, aspmValue, 1)
  UpdateDisplayedValues(useBoost)
EndProcedure

Procedure UpdateDisplayedValues(useBoost.i)
  Protected acMax.i = GetGadgetState(#TrackACMax)
  Protected dcMax.i = GetGadgetState(#TrackDCMax)
  Protected acMin.i = GetGadgetState(#TrackACMin)
  Protected dcMin.i = GetGadgetState(#TrackDCMin)

  SetGadgetText(#TxtACMaxVal, Str(acMax) + "%")
  SetGadgetText(#TxtDCMaxVal, Str(dcMax) + "%")
  SetGadgetText(#TxtACMinVal, Str(acMin) + "%")
  SetGadgetText(#TxtDCMinVal, Str(dcMin) + "%")

  If useBoost
    Protected boostValue.i = BoostArg(useBoost)
    SetGadgetText(#TxtBoostVal, "Selected: " + BoostModeLabel(boostValue) + " (" + Str(boostValue) + ")")
  Else
    SetGadgetText(#TxtBoostVal, "Selected: N/A")
  EndIf
EndProcedure


EnsureAdmin()

Define iniPath$ = GetPathPart(ProgramFilename()) + #APP_NAME + ".ini"
LogLine(#LOG_INFO, "iniPath=" + iniPath$)

; Quick probe (debug only): ensure powercfg is runnable and output capture works.
If gLogLevel = #LOG_DEBUG
  RunProgramCapture("powercfg", "/?")
  LogLine(#LOG_DEBUG, "powercfg probe exit=" + Str(gLastExitCode) + " outLen=" + Str(Len(gLastStdout)))
EndIf

StartSystemInfoUpdate(iniPath$)


Define settings.AppSettings
Define applyDiag.ApplyDiagnostics
LoadAppSettings(iniPath$, @settings)

Define scheme$  = EnsureCustomScheme(#APP_NAME, iniPath$)
LogLine(#LOG_INFO, "Using scheme=" + scheme$)

; Ensure settings match what's currently in registry/INI (already done by LoadAppSettings)

Define useBoost.i = SupportsBoostModeSetting(scheme$)

LogLine(#LOG_INFO, "Supports boost setting=" + Str(useBoost))

Define useCooling.i = SupportsCoolingPolicySetting(scheme$)
LogLine(#LOG_INFO, "Supports cooling policy setting=" + Str(useCooling))
Define useASPM.i = SupportsASPMSetting(scheme$)
LogLine(#LOG_INFO, "Supports ASPM setting=" + Str(useASPM))

; If launched in silent mode (Startup), apply saved settings and exit (no UI)
If HasArg("--silent")
  LogLine(#LOG_INFO, "--silent requested; applying saved settings and exiting")
  If settings\AutoApply
    If useCooling
      ApplySettings(scheme$, settings\ACMaxCPU, settings\DCMaxCPU, settings\ACMinCPU, settings\DCMinCPU, settings\BoostMode, useBoost, settings\CoolingPolicy, ASPMValueForApply(settings\ASPMMode, useASPM))
    Else
      ApplySettings(scheme$, settings\ACMaxCPU, settings\DCMaxCPU, settings\ACMinCPU, settings\DCMinCPU, settings\BoostMode, useBoost, -1, ASPMArgIfSupported(useASPM))
    EndIf
  Else
    LogLine(#LOG_INFO, "AutoApply disabled; silent start exits without changing power settings")
  EndIf
  CloseHandle_(hMutex)
  End
EndIf


OpenWindow(#Win, 0, 0, 500, 790, #APP_NAME + " - " + version + " (powercfg)", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
LogLine(#LOG_INFO, "UI started")

TextGadget(#PB_Any, 15, 15, 470, 20, "Custom power scheme: " + scheme$)

TextGadget(#PB_Any, 15, 45, 470, 20, "Tip: Setting AC Max CPU to 99% usually prevents Turbo Boost and drops temps.")

TextGadget(#PB_Any, 15, 80, 220, 20, "AC (Plugged in) Max CPU %")
TextGadget(#TxtACMaxVal, 440, 80, 45, 20, "")
TrackBarGadget(#TrackACMax, 15, 100, 470, 25, 5, 100)
SetGadgetState(#TrackACMax, settings\ACMaxCPU)

TextGadget(#PB_Any, 15, 135, 220, 20, "DC (Battery) Max CPU %")
TextGadget(#TxtDCMaxVal, 440, 135, 45, 20, "")
TrackBarGadget(#TrackDCMax, 15, 155, 470, 25, 5, 100)
SetGadgetState(#TrackDCMax, settings\DCMaxCPU)

TextGadget(#PB_Any, 15, 190, 220, 20, "AC (Plugged in) Min CPU %")
TextGadget(#TxtACMinVal, 440, 190, 45, 20, "")
TrackBarGadget(#TrackACMin, 15, 210, 470, 25, 1, 100)
SetGadgetState(#TrackACMin, settings\ACMinCPU)

TextGadget(#PB_Any, 15, 245, 220, 20, "DC (Battery) Min CPU %")
TextGadget(#TxtDCMinVal, 440, 245, 45, 20, "")
TrackBarGadget(#TrackDCMin, 15, 265, 470, 25, 1, 100)
SetGadgetState(#TrackDCMin, settings\DCMinCPU)

TextGadget(#PB_Any, 15, 300, 95, 20, "AC profile:")
ComboBoxGadget(#ComboACProfile, 15, 320, 220, 25)

TextGadget(#PB_Any, 265, 300, 95, 20, "DC profile:")
ComboBoxGadget(#ComboDCProfile, 265, 320, 220, 25)

TextGadget(#PB_Any, 15, 355, 70, 20, "Boost mode:")
TextGadget(#TxtBoostVal, 15, 400, 250, 20, "")
ComboBoxGadget(#ComboBoost, 15, 375, 250, 25)

TextGadget(#PB_Any, 275, 355, 210, 20, "Cooling policy:")
ComboBoxGadget(#ComboCooling, 275, 375, 210, 25)

TextGadget(#PB_Any, 15, 425, 210, 20, "Link State Power Mgmt (ASPM):")
ComboBoxGadget(#ComboASPM, 15, 445, 470, 25)
PopulateASPMCombo()
PopulateCoolingCombo()
PopulateBoostCombo()
PopulateProfileCombo(#ComboACProfile)
PopulateProfileCombo(#ComboDCProfile)

SetComboStateByData(#ComboBoost, settings\BoostMode, 0)
SetComboStateByData(#ComboCooling, settings\CoolingPolicy, 0)
SetComboStateByData(#ComboASPM, settings\ASPMMode, 1)
UpdateProfilesFromCurrentUI(@settings)
SyncProfileCombosFromSettings(@settings)

If useBoost = #False
  DisableGadget(#ComboBoost, #True)
  TextGadget(#PB_Any, 90, 355, 210, 20, "(Not supported on this system)")
EndIf

If useCooling = #False
  DisableGadget(#ComboCooling, #True)
EndIf

If useASPM = #False
  DisableGadget(#ComboASPM, #True)
EndIf

CheckBoxGadget(#ChkAutoApply, 15, 650, 250, 20, "Auto apply saved settings on startup")
SetGadgetState(#ChkAutoApply, settings\AutoApply)

CheckBoxGadget(#ChkLiveApply, 275, 650, 210, 20, "Live apply while adjusting")
SetGadgetState(#ChkLiveApply, settings\LiveApply)

CheckBoxGadget(#ChkRunAtStartup, 15, 675, 470, 20, "Run at Windows startup (applies settings silently)")
SetGadgetState(#ChkRunAtStartup, settings\RunAtStartup)

CheckBoxGadget(#ChkUseTaskScheduler, 15, 695, 470, 20, "Use Task Scheduler (no UAC prompt at login)")
SetGadgetState(#ChkUseTaskScheduler, settings\UseTaskScheduler)

ButtonGadget(#BtnApply, 15, 485, 470, 28, "Apply now")

UpdateDisplayedValues(useBoost)

ButtonGadget(#BtnBatteryPreset, 15, 520, 150, 28, "Battery")
ButtonGadget(#BtnEcoPreset, 175, 520, 150, 28, "Eco")
ButtonGadget(#BtnQuietPreset, 335, 520, 150, 28, "Quiet")
ButtonGadget(#BtnCoolPreset, 15, 555, 150, 28, "Cool")
ButtonGadget(#BtnBalancedPreset, 175, 555, 150, 28, "Balanced")
ButtonGadget(#BtnPerfPreset, 335, 555, 150, 28, "Performance")

TextGadget(#TxtStatusSummary, 15, 595, 470, 20, "Status: Ready")
EditorGadget(#EditStatusDetails, 15, 620, 470, 24)
DisableGadget(#EditStatusDetails, #True)
SetStatus("Status: Ready", "Waiting for changes.")

ButtonGadget(#BtnRestoreBalanced, 15, 730, 470, 25, "Restore Windows Balanced plan (activate default)")

; Apply on startup if enabled
If settings\AutoApply
  LogLine(#LOG_INFO, "AutoApply enabled; applying on startup")
  applyDiag\SuccessCount = 0
  applyDiag\FailureCount = 0
  applyDiag\Summary = ""
  applyDiag\Details = ""
  ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), settings\BoostMode, useBoost, CoolingPolicyArg(useCooling), ASPMArgIfSupported(useASPM), @applyDiag)
  SetStatus("Status: " + applyDiag\Summary, applyDiag\Details)
Else
  LogLine(#LOG_INFO, "AutoApply disabled")
EndIf



Define ev, boostValue

Repeat
  ev = WaitWindowEvent()

  Select ev
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #ChkAutoApply, #ChkLiveApply, #ChkRunAtStartup, #ChkUseTaskScheduler
          settings\AutoApply = GetGadgetState(#ChkAutoApply)
          settings\LiveApply = GetGadgetState(#ChkLiveApply)
          settings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
          settings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
          SaveAppSettings(iniPath$, @settings)

        Case #TrackACMax, #TrackDCMax, #TrackACMin, #TrackDCMin, #ComboBoost, #ComboCooling, #ComboASPM
          UpdateProfilesFromCurrentUI(@settings)
          SyncProfileCombosFromSettings(@settings)
          UpdateDisplayedValues(useBoost)
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #ComboACProfile
          settings\ACProfile = GetSelectedItemData(#ComboACProfile, 0)
          ApplyProfileSelectionToTracks(settings\ACProfile, #True, useBoost, useCooling, useASPM)
          SetStatus("Status: AC profile selected", ProfileIdToName(settings\ACProfile) + " loaded into the plugged-in sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #ComboDCProfile
          settings\DCProfile = GetSelectedItemData(#ComboDCProfile, 0)
          ApplyProfileSelectionToTracks(settings\DCProfile, #False, useBoost, useCooling, useASPM)
          SetStatus("Status: DC profile selected", ProfileIdToName(settings\DCProfile) + " loaded into the battery sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnBatteryPreset
          LoadNamedPreset(#PROFILE_BATTERY_SAVER, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Battery Saver applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnEcoPreset
          LoadNamedPreset(#PROFILE_ECO, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Eco applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnQuietPreset
          LoadNamedPreset(#PROFILE_QUIET, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Quiet applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnCoolPreset
          LoadNamedPreset(#PROFILE_COOL, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Cool applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnBalancedPreset
          LoadNamedPreset(#PROFILE_BALANCED, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Balanced applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

        Case #BtnPerfPreset
          LoadNamedPreset(#PROFILE_PERFORMANCE, useBoost, useCooling, useASPM)
          SetStatus("Status: Preset loaded", "Performance applied to both AC and DC sliders.")
          ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

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

          boostValue = BoostArg(useBoost)

          UpdateDisplayedValues(useBoost)

          SaveCurrentUIToSettings(@settings, useBoost, useCooling, useASPM)
          SaveAppSettings(iniPath$, @settings)

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
                                     "Boost mode: " + BoostModeLabel(boostValue) + " (" + Str(boostValue) + ")", #PB_MessageRequester_Info)
          ElseIf applyDiag\FailureCount = 0
            MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                                     "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ +
                                     "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                                     "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                                     "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                                     "Boost mode is not available on this system.", #PB_MessageRequester_Info)
          Else
            MessageRequester("Apply completed with errors", applyDiag\Summary + #CRLF$ + #CRLF$ + applyDiag\Details, #PB_MessageRequester_Warning)
          EndIf

      EndSelect

    Case #PB_Event_CloseWindow
      LogLine(#LOG_INFO, "Close requested")
      If ConfirmExit()
        LogLine(#LOG_INFO, "Exiting")
        CloseHandle_(hMutex)
        End
      EndIf
      LogLine(#LOG_INFO, "Exit cancelled")

  EndSelect
ForEver

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 38
; FirstLine = 21
; Folding = ------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = MyCPUCooler.ico
; Executable = ..\MyCPUCooler.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = MyCPUCooler
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Chooses the coolest powerplan
; VersionField7 = MyCPUCooler
; VersionField8 = MyCPUCooler.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60