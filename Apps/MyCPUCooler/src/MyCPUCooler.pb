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
#SET_MIN_PROC_STATE$ = "893df05b-2057-4611-9126-1b0c369936d0"
#SCHEME_BALANCED$    = "381b4222-f694-41f0-9685-ff5bb260df2e"
#SUB_PCIE$           = "ee12f483-ad20-4395-8360-3116c4296227"
#SET_ASPM$           = "ee12f483-ad20-4395-8360-3116c4296228"


; boost mode values (not all systems expose/honor these)
#BOOST_DISABLED    = 0
#BOOST_AGGRESSIVE  = 2
#BOOST_EFFICIENT   = 3

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.0.0.2"

; Registry base key (HKCU)
#APP_NAME = "MyCPUCooler"
#EMAIL_NAME = "zonemaster60@gmail.com"

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

Procedure.s RunProgramCapture(program$, args$)
  ; Captures combined stdout+stderr (2>&1) into gLastStdout.
  ; Note: this PB build doesn't expose separate stderr read APIs.
  gLastExitCode = -1
  gLastWin32Error = 0
  gLastStdout = ""
  gLastStderr = ""

  LogLine(#LOG_DEBUG, "exec: " + program$ + " " + args$)

  ; Use cmd.exe to redirect stderr to stdout so we can always capture output.
  ; Important: cmd quoting must be: /S /C ""program" args 2>&1"
  Protected cmdArgs$ = "/S /C " + Chr(34) + Chr(34) + program$ + Chr(34) + " " + args$ + " 2>&1" + Chr(34)
  LogLine(#LOG_DEBUG, "cmd.exe args: " + cmdArgs$)

  Protected flags = #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read
  Protected prog = RunProgram("cmd.exe", cmdArgs$, "", flags)
  If prog = 0
    gLastWin32Error = GetLastError_()
    LogLine(#LOG_ERROR, "failed to start: " + program$ + " err=" + WinErrorMessage(gLastWin32Error))
    ProcedureReturn ""
  EndIf

  While ProgramRunning(prog)
    While AvailableProgramOutput(prog)
      gLastStdout + ReadProgramString(prog) + #LF$
    Wend
    Delay(5)
  Wend

  While AvailableProgramOutput(prog)
    gLastStdout + ReadProgramString(prog) + #LF$
  Wend

  gLastExitCode = ProgramExitCode(prog)
  CloseProgram(prog)

  If gLastExitCode <> 0
    LogLine(#LOG_WARN, "exit=" + Str(gLastExitCode) + " cmd=" + program$ + " " + args$)
  Else
    LogLine(#LOG_DEBUG, "ok exit=0")
  EndIf

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

  If scheme$ <> ""
    ProcedureReturn scheme$
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


Procedure ApplySettings(scheme$, acMax.i, dcMax.i, acMin.i, dcMin.i, boostValue.i, useBoost.i, coolingPolicy.i, aspmValue.i)
  LogLine(#LOG_INFO, "ApplySettings scheme=" + scheme$ +
                     " acMax=" + Str(acMax) + " dcMax=" + Str(dcMax) +
                     " acMin=" + Str(acMin) + " dcMin=" + Str(dcMin) +
                     " boost=" + Str(boostValue) + " useBoost=" + Str(useBoost) +
                     " coolingPolicy=" + Str(coolingPolicy) +
                     " aspm=" + Str(aspmValue))

  ; clamp
  If acMax < 1 : acMax = 1 : EndIf
  If acMax > 100 : acMax = 100 : EndIf
  If dcMax < 1 : dcMax = 1 : EndIf
  If dcMax > 100 : dcMax = 100 : EndIf
  If acMin < 1 : acMin = 1 : EndIf
  If acMin > 100 : acMin = 100 : EndIf
  If dcMin < 1 : dcMin = 1 : EndIf
  If dcMin > 100 : dcMin = 100 : EndIf
  If acMin > acMax : acMin = acMax : EndIf
  If dcMin > dcMax : dcMin = dcMax : EndIf

  RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MAX_PROC_STATE$ + " " + Str(acMax))
  RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MAX_PROC_STATE$ + " " + Str(dcMax))
  RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MIN_PROC_STATE$ + " " + Str(acMin))
  RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_MIN_PROC_STATE$ + " " + Str(dcMin))

  If useBoost
    RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(boostValue))
    RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_BOOST_MODE$ + " " + Str(boostValue))
  EndIf


  ; Cooling policy (0=Active (fan first), 1=Passive (throttle first))
  If coolingPolicy >= 0
    If coolingPolicy <> 0 And coolingPolicy <> 1
      coolingPolicy = 0
    EndIf
    RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
    RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
  EndIf

  ; ASPM (0=Off, 1=Moderate, 2=Maximum)
  If aspmValue >= 0
    RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(aspmValue))
    RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PCIE$ + " " + #SET_ASPM$ + " " + Str(aspmValue))
  EndIf



  ; Cooling policy (0=Active (fan first), 1=Passive (throttle first))
  If coolingPolicy >= 0
    If coolingPolicy <> 0 And coolingPolicy <> 1
      coolingPolicy = 0
    EndIf
    RunPowerCfg("-setacvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
    RunPowerCfg("-setdcvalueindex " + scheme$ + " " + #SUB_PROCESSOR$ + " " + #SET_SYS_COOLING_POLICY$ + " " + Str(coolingPolicy))
  EndIf

  ; activate scheme
  RunPowerCfg("-S " + scheme$)
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "Failed to activate scheme. exit=" + Str(gLastExitCode))
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

  Protected out$ = RunProgramCapture("powershell.exe", ps$)
  If gLastExitCode <> 0
    LogLine(#LOG_WARN, "PowerShell system info exit=" + Str(gLastExitCode))
    If gLastStdout <> "" : LogLine(#LOG_WARN, "output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
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
  *settings\ACMaxCPU = 99
  *settings\DCMaxCPU = 85
  *settings\ACMinCPU = 5
  *settings\DCMinCPU = 5
  *settings\BoostMode = #BOOST_DISABLED
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
  #ComboBoost
  #ComboCooling
  #ComboASPM

  #TxtACMaxVal
  #TxtDCMaxVal
  #TxtACMinVal
  #TxtDCMinVal
  #TxtBoostVal


  #ChkAutoApply
  #ChkLiveApply
  #ChkRunAtStartup
  #ChkUseTaskScheduler

  #BtnApply
  #BtnCoolPreset
  #BtnBalancedPreset
  #BtnPerfPreset
  #BtnRestoreBalanced
EndEnumeration

; -----------------------------
; UI helpers
; -----------------------------

Procedure.i CoolingPolicyArg(useCooling.i)
  If useCooling
    Protected idx.i = GetGadgetState(#ComboCooling)
    ProcedureReturn GetGadgetItemData(#ComboCooling, idx)
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i ASPMArg()
  Protected idx.i = GetGadgetState(#ComboASPM)
  If idx >= 0
    ProcedureReturn GetGadgetItemData(#ComboASPM, idx)
  EndIf
  ProcedureReturn -1
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
    Protected idx.i = GetGadgetState(#ComboBoost)
    Protected boostValue.i = GetGadgetItemData(#ComboBoost, idx)
    SetGadgetText(#TxtBoostVal, "Value: " + Str(boostValue))
  Else
    SetGadgetText(#TxtBoostVal, "Value: N/A")
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
LoadAppSettings(iniPath$, @settings)

Define scheme$  = EnsureCustomScheme(#APP_NAME, iniPath$)
LogLine(#LOG_INFO, "Using scheme=" + scheme$)

; Ensure settings match what's currently in registry/INI (already done by LoadAppSettings)

Define useBoost.i = SupportsBoostModeSetting(scheme$)

LogLine(#LOG_INFO, "Supports boost setting=" + Str(useBoost))

Define useCooling.i = SupportsCoolingPolicySetting(scheme$)
LogLine(#LOG_INFO, "Supports cooling policy setting=" + Str(useCooling))

; If launched in silent mode (Startup), apply saved settings and exit (no UI)
If HasArg("--silent")
  LogLine(#LOG_INFO, "--silent requested; applying saved settings and exiting")
  If useCooling
    ApplySettings(scheme$, settings\ACMaxCPU, settings\DCMaxCPU, settings\ACMinCPU, settings\DCMinCPU, settings\BoostMode, useBoost, settings\CoolingPolicy, settings\ASPMMode)
  Else
    ApplySettings(scheme$, settings\ACMaxCPU, settings\DCMaxCPU, settings\ACMinCPU, settings\DCMinCPU, settings\BoostMode, useBoost, -1, settings\ASPMMode)
  EndIf
  CloseHandle_(hMutex)
  End
EndIf


OpenWindow(#Win, 0, 0, 500, 620, #APP_NAME + " - " + version + " (powercfg)", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
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

TextGadget(#PB_Any, 15, 300, 70, 20, "Boost mode:")
TextGadget(#TxtBoostVal, 15, 345, 250, 20, "")
ComboBoxGadget(#ComboBoost, 15, 320, 250, 25)

TextGadget(#PB_Any, 275, 300, 210, 20, "Cooling policy:")
ComboBoxGadget(#ComboCooling, 275, 320, 210, 25)

TextGadget(#PB_Any, 15, 370, 210, 20, "Link State Power Mgmt (ASPM):")
ComboBoxGadget(#ComboASPM, 15, 390, 470, 25)
AddGadgetItem(#ComboASPM, -1, "Off (performance)")
SetGadgetItemData(#ComboASPM, 0, 0)
AddGadgetItem(#ComboASPM, -1, "Moderate Power Savings")
SetGadgetItemData(#ComboASPM, 1, 1)
AddGadgetItem(#ComboASPM, -1, "Maximum Power Savings")
SetGadgetItemData(#ComboASPM, 2, 2)
Select settings\ASPMMode
  Case 0 : SetGadgetState(#ComboASPM, 0)
  Case 1 : SetGadgetState(#ComboASPM, 1)
  Case 2 : SetGadgetState(#ComboASPM, 2)
  Default : SetGadgetState(#ComboASPM, 1)
EndSelect

AddGadgetItem(#ComboCooling, -1, "Active (fan first)")
SetGadgetItemData(#ComboCooling, 0, 0)
AddGadgetItem(#ComboCooling, -1, "Passive (throttle first)")
SetGadgetItemData(#ComboCooling, 1, 1)
AddGadgetItem(#ComboBoost, -1, "Disabled (coolest)")
SetGadgetItemData(#ComboBoost, 0, #BOOST_DISABLED)
AddGadgetItem(#ComboBoost, -1, "Efficient Enabled (middle)")
SetGadgetItemData(#ComboBoost, 1, #BOOST_EFFICIENT)
AddGadgetItem(#ComboBoost, -1, "Aggressive (hottest)")
SetGadgetItemData(#ComboBoost, 2, #BOOST_AGGRESSIVE)

; select current boost
Select settings\BoostMode
  Case #BOOST_DISABLED
    SetGadgetState(#ComboBoost, 0)
  Case #BOOST_EFFICIENT
    SetGadgetState(#ComboBoost, 1)
  Default
    SetGadgetState(#ComboBoost, 2)
EndSelect

; select cooling policy
If settings\CoolingPolicy = 1
  SetGadgetState(#ComboCooling, 1)
Else
  SetGadgetState(#ComboCooling, 0)
EndIf

If useBoost = #False
  DisableGadget(#ComboBoost, #True)
  TextGadget(#PB_Any, 90, 300, 210, 20, "(Not supported on this system)")
EndIf

If useCooling = #False
  DisableGadget(#ComboCooling, #True)
EndIf

CheckBoxGadget(#ChkAutoApply, 15, 530, 250, 20, "Auto apply saved settings on startup")
SetGadgetState(#ChkAutoApply, settings\AutoApply)

CheckBoxGadget(#ChkLiveApply, 275, 530, 210, 20, "Live apply while adjusting")
SetGadgetState(#ChkLiveApply, settings\LiveApply)

CheckBoxGadget(#ChkRunAtStartup, 15, 555, 470, 20, "Run at Windows startup (applies settings silently)")
SetGadgetState(#ChkRunAtStartup, settings\RunAtStartup)

CheckBoxGadget(#ChkUseTaskScheduler, 15, 575, 470, 20, "Use Task Scheduler (no UAC prompt at login)")
SetGadgetState(#ChkUseTaskScheduler, settings\UseTaskScheduler)

ButtonGadget(#BtnApply, 15, 430, 470, 28, "Apply now")

UpdateDisplayedValues(useBoost)

ButtonGadget(#BtnCoolPreset, 15, 465, 150, 28, "Cool preset")
ButtonGadget(#BtnBalancedPreset, 175, 465, 150, 28, "Balanced preset")
ButtonGadget(#BtnPerfPreset, 335, 465, 150, 28, "Performance preset")

ButtonGadget(#BtnRestoreBalanced, 15, 497, 470, 25, "Restore Windows Balanced plan (activate default)")

; Apply on startup if enabled
If settings\AutoApply
  LogLine(#LOG_INFO, "AutoApply enabled; applying on startup")
  ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), settings\BoostMode, useBoost, CoolingPolicyArg(useCooling), ASPMArg())
Else
  LogLine(#LOG_INFO, "AutoApply disabled")
EndIf



Define ev, boostIndex, boostValue
Define liveBoostValue.i, liveIdx.i
Define presetBoostValue0.i, presetIdx0.i
Define presetBoostValue1.i, presetIdx1.i
Define presetBoostValue2.i, presetIdx2.i

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
          UpdateDisplayedValues(useBoost)
          If GetGadgetState(#ChkLiveApply)
            liveBoostValue = #BOOST_DISABLED
            If useBoost
              liveIdx = GetGadgetState(#ComboBoost)
              liveBoostValue = GetGadgetItemData(#ComboBoost, liveIdx)
            EndIf
            ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), liveBoostValue, useBoost, CoolingPolicyArg(useCooling), ASPMArg())
          EndIf

        Case #BtnCoolPreset
          ; Recommended for GF63 i5-11400H
          SetGadgetState(#TrackACMax, 99)
          SetGadgetState(#TrackDCMax, 80)
          SetGadgetState(#TrackACMin, 5)
          SetGadgetState(#TrackDCMin, 5)
          If useBoost : SetGadgetState(#ComboBoost, 0) : EndIf
          SetGadgetState(#ComboCooling, 1)
          SetGadgetState(#ComboASPM, 2)
          UpdateDisplayedValues(useBoost)

          If GetGadgetState(#ChkLiveApply)
            presetBoostValue0 = #BOOST_DISABLED
            If useBoost
              presetIdx0 = GetGadgetState(#ComboBoost)
              presetBoostValue0 = GetGadgetItemData(#ComboBoost, presetIdx0)
            EndIf
            ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), presetBoostValue0, useBoost, CoolingPolicyArg(useCooling), ASPMArg())
          EndIf

        Case #BtnBalancedPreset
          SetGadgetState(#TrackACMax, 100)
          SetGadgetState(#TrackDCMax, 85)
          SetGadgetState(#TrackACMin, 5)
          SetGadgetState(#TrackDCMin, 5)
          If useBoost : SetGadgetState(#ComboBoost, 1) : EndIf
          SetGadgetState(#ComboCooling, 0)
          SetGadgetState(#ComboASPM, 1)
          UpdateDisplayedValues(useBoost)

          If GetGadgetState(#ChkLiveApply)
            presetBoostValue1 = #BOOST_DISABLED
            If useBoost
              presetIdx1 = GetGadgetState(#ComboBoost)
              presetBoostValue1 = GetGadgetItemData(#ComboBoost, presetIdx1)
            EndIf
            ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), presetBoostValue1, useBoost, CoolingPolicyArg(useCooling), ASPMArg())
          EndIf

        Case #BtnPerfPreset
          SetGadgetState(#TrackACMax, 100)
          SetGadgetState(#TrackDCMax, 100)
          SetGadgetState(#TrackACMin, 5)
          SetGadgetState(#TrackDCMin, 5)
          If useBoost : SetGadgetState(#ComboBoost, 2) : EndIf
          SetGadgetState(#ComboCooling, 0)
          SetGadgetState(#ComboASPM, 0)
          UpdateDisplayedValues(useBoost)

          If GetGadgetState(#ChkLiveApply)
            presetBoostValue2 = #BOOST_DISABLED
            If useBoost
              presetIdx2 = GetGadgetState(#ComboBoost)
              presetBoostValue2 = GetGadgetItemData(#ComboBoost, presetIdx2)
            EndIf
            ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin), presetBoostValue2, useBoost, CoolingPolicyArg(useCooling), ASPMArg())
          EndIf

        Case #BtnRestoreBalanced
          RestoreBalanced()
          MessageRequester("Balanced restored", "Activated the default Windows Balanced plan." + #CRLF$ + 
                                                "You can re-apply the custom scheme anytime With 'Apply now'.", #PB_MessageRequester_Info)

Case #BtnApply
  LogLine(#LOG_INFO, "Apply button clicked")
  Define acMaxVal = GetGadgetState(#TrackACMax)
  Define dcMaxVal = GetGadgetState(#TrackDCMax)
  Define acMinVal = GetGadgetState(#TrackACMin)
  Define dcMinVal = GetGadgetState(#TrackDCMin)


          boostValue = #BOOST_DISABLED
          If useBoost
            boostIndex = GetGadgetState(#ComboBoost)
            boostValue = GetGadgetItemData(#ComboBoost, boostIndex)
          EndIf

          UpdateDisplayedValues(useBoost)

          ; save (registry primary, INI backup)
          settings\ACMaxCPU = acMaxVal
          settings\DCMaxCPU = dcMaxVal
          settings\ACMinCPU = acMinVal
          settings\DCMinCPU = dcMinVal
          settings\BoostMode = boostValue
          If useCooling
            settings\CoolingPolicy = CoolingPolicyArg(useCooling)
          EndIf
          settings\ASPMMode = ASPMArg()
          settings\AutoApply = GetGadgetState(#ChkAutoApply)
          settings\LiveApply = GetGadgetState(#ChkLiveApply)
          settings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
          settings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
          SaveAppSettings(iniPath$, @settings)

          ApplySettings(scheme$, acMaxVal, dcMaxVal, acMinVal, dcMinVal, boostValue, useBoost, CoolingPolicyArg(useCooling), ASPMArg())

          If useBoost
            MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                                     "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ + 
                                     "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                                     "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                                     "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                                     "Boost mode value: " + Str(boostValue), #PB_MessageRequester_Info)
          Else
            MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                                     "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ + 
                                     "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                                     "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                                     "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                                     "Boost mode is Not available on this system.", #PB_MessageRequester_Info)
          EndIf

      EndSelect

Case #PB_Event_CloseWindow
  LogLine(#LOG_INFO, "Close requested")
  ConfirmExit()
  LogLine(#LOG_INFO, "Exiting")
  CloseHandle_(hMutex)
  End

  EndSelect
ForEver

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 27
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = MyCPUCooler.ico
; Executable = ..\MyCPUCooler.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = MyCPUCooler
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Chooses the coolest powerplan
; VersionField7 = MyCPUCooler
; VersionField8 = MyCPUCooler.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60