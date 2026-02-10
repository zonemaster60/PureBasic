; UpdateRepair.pb (PureBasic 6.30, Windows)
; Windows Update repair tool (portable) for Windows 7 SP1 -> Windows 11 + Servers
; Features:
; - Selectable steps + Recommended preset
; - UAC elevation
; - Logs to UI + file next to EXE
; - Read-only WSUS/GPO + reboot-pending detection
; - Diagnostics bundle export to ZIP (event logs, WU logs, registry exports, summary)
; - CLI mode (/recommended, /run, /exportdiag, /quiet)

EnableExplicit
UseZipPacker()

; ----------------------------
; WinAPI imports / constants
; ----------------------------

#SERVICE_QUERY_STATUS   = $0004
#SERVICE_START          = $0010
#SERVICE_STOP           = $0020
#SERVICE_INTERROGATE    = $0080
#SC_MANAGER_CONNECT     = $0001

#SERVICE_CONTROL_STOP   = 1
#SERVICE_STOPPED        = 1
#SERVICE_START_PENDING  = 2
#SERVICE_STOP_PENDING   = 3
#SERVICE_RUNNING        = 4

#SERVICE_ACCEPT_STOP    = $00000001

#ERROR_SERVICE_DOES_NOT_EXIST = 1060

; Registry access
#HKEY_LOCAL_MACHINE     = $80000002
#HKEY_CURRENT_USER      = $80000001

; Back-compat aliases (used by this file)
#PB_Registry_HKLM       = #HKEY_LOCAL_MACHINE
#PB_Registry_HKCU       = #HKEY_CURRENT_USER

#KEY_QUERY_VALUE        = $0001
#KEY_ENUMERATE_SUB_KEYS = $0008
#KEY_NOTIFY             = $0010
#KEY_READ               = $20019
#KEY_WOW64_64KEY        = $0100
#KEY_WOW64_32KEY        = $0200

#REG_NONE               = 0
#REG_SZ                 = 1
#REG_EXPAND_SZ          = 2
#REG_DWORD              = 4

#APP_NAME = "WindowsUpdateRepair"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.0.0.0"

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Structure OSVERSIONINFOEXW
  dwOSVersionInfoSize.l
  dwMajorVersion.l
  dwMinorVersion.l
  dwBuildNumber.l
  dwPlatformId.l
  szCSDVersion.w[128]
  wServicePackMajor.w
  wServicePackMinor.w
  wSuiteMask.w
  wProductType.b
  wReserved.b
EndStructure

Structure SERVICE_STATUS_PROCESS
  dwServiceType.l
  dwCurrentState.l
  dwControlsAccepted.l
  dwWin32ExitCode.l
  dwServiceSpecificExitCode.l
  dwCheckPoint.l
  dwWaitHint.l
  dwProcessId.l
  dwServiceFlags.l
EndStructure

Structure SERVICE_STATUS_BASIC
  dwServiceType.l
  dwCurrentState.l
  dwControlsAccepted.l
  dwWin32ExitCode.l
  dwServiceSpecificExitCode.l
  dwCheckPoint.l
  dwWaitHint.l
EndStructure

Prototype.l RtlGetVersion(*osvi.OSVERSIONINFOEXW)

Import "advapi32.lib"
  ; Use integer pointers so we can pass 0 (NULL).
  OpenSCManagerW_(lpMachineName.i, lpDatabaseName.i, dwDesiredAccess.l) As "OpenSCManagerW"
  OpenServiceW_(hSCManager.i, lpServiceName.p-unicode, dwDesiredAccess.l) As "OpenServiceW"
  CloseServiceHandle_(hSCObject.i) As "CloseServiceHandle"
  ControlService_(hService.i, dwControl.l, *lpServiceStatus) As "ControlService"
  StartServiceW_(hService.i, dwNumServiceArgs.l, *lpServiceArgVectors) As "StartServiceW"
  QueryServiceStatusEx_(hService.i, InfoLevel.l, *lpBuffer, cbBufSize.l, *pcbBytesNeeded) As "QueryServiceStatusEx"
  GetLastError_() As "GetLastError"

  RegOpenKeyExW_(hKey.i, lpSubKey.p-unicode, ulOptions.l, samDesired.l, *phkResult) As "RegOpenKeyExW"
  RegQueryValueExW_(hKey.i, lpValueName.p-unicode, lpReserved.i, *lpType, *lpData, *lpcbData) As "RegQueryValueExW"
  RegCloseKey_(hKey.i) As "RegCloseKey"
EndImport

Import "kernel32.lib"
  GetCurrentProcess_() As "GetCurrentProcess"
  IsWow64Process_(hProcess.i, *Wow64) As "IsWow64Process"
  GetTickCount_() As "GetTickCount"
  Sleep_(dwMilliseconds.l) As "Sleep"
  MoveFileExW_(lpExistingFileName.p-unicode, lpNewFileName.p-unicode, dwFlags.l) As "MoveFileExW"
EndImport

#MOVEFILE_REPLACE_EXISTING   = 1
#MOVEFILE_DELAY_UNTIL_REBOOT = 4
#MOVEFILE_WRITE_THROUGH      = 8

Import "shell32.lib"
  ShellExecuteW_(hwnd.i, lpOperation.p-unicode, lpFile.p-unicode, lpParameters.p-unicode, lpDirectory.p-unicode, nShowCmd.l) As "ShellExecuteW"
EndImport

; ----------------------------
; Globals / logging
; ----------------------------

Global gLogFile.s
Global gMutex.i
Global NewList gPendingLog.s()
Global gWorkerThread.i
Global gIsRunning.i

Global gExportThread.i
Global gIsExporting.i
Global gLastDiagZip.s

Global gDryRun.i
Global gRebootAfter.i

; Remember service state so we can restore it
Structure RememberedService
  Name.s
  WasRunning.i
  Present.i
EndStructure

Global NewList gSvc.RememberedService()

Procedure.s NowStamp()
  ProcedureReturn FormatDate("%yyyy%mm%dd-%hh%ii%ss", Date())
EndProcedure

Procedure.s ExeDir()
  ProcedureReturn GetPathPart(ProgramFilename())
EndProcedure

Procedure.s Quote(s.s)
  ; Minimal quoting for command lines.
  If FindString(s, " ", 1) Or FindString(s, Chr(9), 1) Or FindString(s, Chr(34), 1)
    ; Avoid embedding quotes inside quotes. If callers pass quoted args, strip quotes.
    s = ReplaceString(s, Chr(34), "")
    ProcedureReturn Chr(34) + s + Chr(34)
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.s JoinParams()
  Protected i.i, s.s
  For i = 0 To CountProgramParameters() - 1
    If s <> "" : s + " " : EndIf
    s + Quote(ProgramParameter(i))
  Next
  ProcedureReturn s
EndProcedure

Procedure LogLine(line.s)
  Protected fh.i
  line = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + " | " + line

  fh = OpenFile(#PB_Any, gLogFile)
  If fh
    FileSeek(fh, Lof(fh))
    WriteStringN(fh, line, #PB_UTF8)
    CloseFile(fh)
  EndIf

  LockMutex(gMutex)
  AddElement(gPendingLog())
  gPendingLog() = line
  UnlockMutex(gMutex)
EndProcedure

; ----------------------------
; OS / elevation helpers
; ----------------------------

Procedure.i Is64BitOS()
  Protected wow64.l
  If SizeOf(Integer) = 8
    ProcedureReturn #True
  EndIf
  If IsWow64Process_(GetCurrentProcess_(), @wow64)
    ProcedureReturn Bool(wow64 <> 0)
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.s SystemToolPath(toolName.s)
  Protected winDir.s = GetEnvironmentVariable("WINDIR")
  If winDir = "" : winDir = "C:\Windows" : EndIf

  ; 32-bit process on 64-bit OS: use Sysnative to reach 64-bit System32 tools
  If SizeOf(Integer) = 4 And Is64BitOS()
    ProcedureReturn winDir + "\Sysnative\" + toolName
  Else
    ProcedureReturn winDir + "\System32\" + toolName
  EndIf
EndProcedure

Procedure.i IsAdmin()
  ; Simple: try opening SCM connect only; if it fails often indicates not elevated.
  ; (Not perfect, but works well for this tool.)
  Protected hSCM.i = OpenSCManagerW_(0, 0, #SC_MANAGER_CONNECT)
  If hSCM
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure RelaunchElevatedIfNeeded()
  If IsAdmin() : ProcedureReturn : EndIf
  ; Pass only args, not full command line.
  ShellExecuteW_(0, "runas", ProgramFilename(), JoinParams(), ExeDir(), 1)
  End
EndProcedure

Procedure.i GetWindowsVersion(*major.Integer, *minor.Integer, *build.Integer, *spMajor.Integer)
  Protected osvi.OSVERSIONINFOEXW
  Protected rtl.RtlGetVersion
  Protected ntdll.i = OpenLibrary(#PB_Any, "ntdll.dll")
  If ntdll = 0 : ProcedureReturn #False : EndIf

  rtl = GetFunction(ntdll, "RtlGetVersion")
  If rtl = 0 : CloseLibrary(ntdll) : ProcedureReturn #False : EndIf

  osvi\dwOSVersionInfoSize = SizeOf(OSVERSIONINFOEXW)
  If rtl(@osvi) <> 0
    CloseLibrary(ntdll)
    ProcedureReturn #False
  EndIf

  *major\i = osvi\dwMajorVersion
  *minor\i = osvi\dwMinorVersion
  *build\i = osvi\dwBuildNumber
  *spMajor\i = osvi\wServicePackMajor
  CloseLibrary(ntdll)
  ProcedureReturn #True
EndProcedure

Procedure.i IsWin10OrLater()
  Protected maj.i, min.i, bld.i, sp.i
  If GetWindowsVersion(@maj, @min, @bld, @sp) = 0 : ProcedureReturn #False : EndIf
  If maj >= 10 : ProcedureReturn #True : EndIf
  ProcedureReturn #False
EndProcedure

Procedure.s OsLabel()
  Protected maj.i, min.i, bld.i, sp.i
  If GetWindowsVersion(@maj, @min, @bld, @sp) = 0
    ProcedureReturn "Unknown"
  EndIf
  ProcedureReturn "Version " + Str(maj) + "." + Str(min) + " (Build " + Str(bld) + "), SP " + Str(sp)
EndProcedure

; ----------------------------
; Command runner (captures output)
; ----------------------------

Procedure.i RunAndLog(exePath.s, args.s, workDir.s="")
  Protected p.i, line.s
  LogLine("RUN: " + Quote(exePath) + " " + args)

  If gDryRun
    LogLine("DRYRUN: command not executed.")
    ProcedureReturn #True
  EndIf

  p = RunProgram(exePath, args, workDir, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
  If p = 0
    LogLine("ERROR: failed to start process.")
    ProcedureReturn #False
  EndIf

  While ProgramRunning(p)
    While AvailableProgramOutput(p)
      line = ReadProgramString(p)
      If line <> "" : LogLine(line) : EndIf
    Wend
    While AvailableProgramOutput(p)
      line = ReadProgramString(p, #PB_Program_Error)
      If line <> "" : LogLine("ERR: " + line) : EndIf
    Wend
    Sleep_(30)
  Wend

  While AvailableProgramOutput(p)
    line = ReadProgramString(p)
    If line <> "" : LogLine(line) : EndIf
  Wend
  While AvailableProgramOutput(p)
    line = ReadProgramString(p, #PB_Program_Error)
    If line <> "" : LogLine("ERR: " + line) : EndIf
  Wend

  LogLine("EXITCODE: " + Str(ProgramExitCode(p)))
  CloseProgram(p)
  ProcedureReturn #True
EndProcedure

; ----------------------------
; Service control (SCM)
; ----------------------------

Procedure.i ServiceExists(hSCM.i, name.s)
  Protected hSvc.i = OpenServiceW_(hSCM, name, #SERVICE_QUERY_STATUS)
  If hSvc
    CloseServiceHandle_(hSvc)
    ProcedureReturn #True
  EndIf
  If GetLastError_() = #ERROR_SERVICE_DOES_NOT_EXIST
    ProcedureReturn #False
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i QueryServiceState(hSvc.i)
  Protected ssp.SERVICE_STATUS_PROCESS
  Protected need.l
  If QueryServiceStatusEx_(hSvc, 0, @ssp, SizeOf(SERVICE_STATUS_PROCESS), @need) = 0
    ProcedureReturn -1
  EndIf
  ProcedureReturn ssp\dwCurrentState
EndProcedure

Procedure.s SystemFolderPath(folderName.s)
  ; Like SystemToolPath(), but for directories/files under the real System32.
  ; On 64-bit OS, 32-bit processes get redirected from System32 -> SysWOW64.
  ; Sysnative bypasses redirection and points at the real System32.
  Protected winDir.s = GetEnvironmentVariable("WINDIR")
  If winDir = "" : winDir = "C:\Windows" : EndIf

  If SizeOf(Integer) = 4 And Is64BitOS()
    ProcedureReturn winDir + "\Sysnative\" + folderName
  Else
    ProcedureReturn winDir + "\System32\" + folderName
  EndIf
EndProcedure

Procedure.i QueryServiceStatusProcess(hSvc.i, *ssp.SERVICE_STATUS_PROCESS)
  Protected need.l
  If QueryServiceStatusEx_(hSvc, 0, *ssp, SizeOf(SERVICE_STATUS_PROCESS), @need) = 0
    ProcedureReturn #False
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure.i WaitServiceState(hSvc.i, desiredState.i, timeoutMs.i)
  Protected start.l = GetTickCount_()
  Protected st.i, last.i = -999
  Repeat
    st = QueryServiceState(hSvc)
    If st = -1
      LogLine("ERROR: QueryServiceStatusEx failed while waiting. LastError=" + Str(GetLastError_()))
      ProcedureReturn #False
    EndIf
    If st = desiredState : ProcedureReturn #True : EndIf
    If st <> last
      LogLine("Service state now: " + Str(st))
      last = st
    EndIf
    Sleep_(150)
  Until (GetTickCount_() - start) > timeoutMs
  ProcedureReturn #False
EndProcedure

Procedure.i StopServiceByName(name.s, timeoutMs.i=25000)
  Protected hSCM.i, hSvc.i, st.i
  Protected ssp.SERVICE_STATUS_PROCESS
  Protected ss.SERVICE_STATUS_BASIC
  Protected err.l

  hSCM = OpenSCManagerW_(0, 0, #SC_MANAGER_CONNECT)
  If hSCM = 0
    LogLine("ERROR: OpenSCManager failed.")
    ProcedureReturn #False
  EndIf

  If ServiceExists(hSCM, name) = 0
    LogLine("SKIP: service not present: " + name)
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  If gDryRun
    LogLine("DRYRUN: would stop service: " + name)
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  hSvc = OpenServiceW_(hSCM, name, #SERVICE_STOP | #SERVICE_QUERY_STATUS | #SERVICE_INTERROGATE)
  If hSvc = 0
    LogLine("ERROR: OpenService failed: " + name + " LastError=" + Str(GetLastError_()))
    CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  If QueryServiceStatusProcess(hSvc, @ssp) = 0
    LogLine("ERROR: QueryServiceStatusEx failed: " + name + " LastError=" + Str(GetLastError_()))
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  st = ssp\dwCurrentState
  If st = #SERVICE_STOPPED
    LogLine("OK: already stopped: " + name)
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  If (ssp\dwControlsAccepted & #SERVICE_ACCEPT_STOP) = 0 And st <> #SERVICE_STOP_PENDING
    LogLine("WARN: service does not accept STOP control right now: " + name + " state=" + Str(st) + " controlsAccepted=" + Str(ssp\dwControlsAccepted))
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  If st = #SERVICE_STOP_PENDING
    LogLine("Service already stopping: " + name + " waitHintMs=" + Str(ssp\dwWaitHint))
  EndIf

  LogLine("Stopping service: " + name)
  If ControlService_(hSvc, #SERVICE_CONTROL_STOP, @ss) = 0
    err = GetLastError_()
    ; If it's already stopping/stopped, treat as ok and wait.
    If err <> 0
      LogLine("WARN: ControlService(STOP) failed: " + name + " LastError=" + Str(err))
    EndIf

    ; Common on Win11: cryptsvc may refuse STOP while busy.
    ; If STOP is not accepted right now, don't wait the full timeout.
    If err = 1051 Or err = 1061
      LogLine("WARN: service did not accept STOP right now: " + name + " (continuing best-effort repairs)")
      CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
      ProcedureReturn #False
    EndIf
  EndIf
  If WaitServiceState(hSvc, #SERVICE_STOPPED, timeoutMs) = 0
    LogLine("WARN: stop timeout: " + name)
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  LogLine("OK: stopped: " + name)
  CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
  ProcedureReturn #True
EndProcedure

Procedure.i StartServiceByName(name.s, timeoutMs.i=25000)
  Protected hSCM.i, hSvc.i, st.i

  hSCM = OpenSCManagerW_(0, 0, #SC_MANAGER_CONNECT)
  If hSCM = 0
    LogLine("ERROR: OpenSCManager failed.")
    ProcedureReturn #False
  EndIf

  If ServiceExists(hSCM, name) = 0
    LogLine("SKIP: service not present: " + name)
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  If gDryRun
    LogLine("DRYRUN: would start service: " + name)
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  hSvc = OpenServiceW_(hSCM, name, #SERVICE_START | #SERVICE_QUERY_STATUS)
  If hSvc = 0
    LogLine("ERROR: OpenService failed: " + name + " LastError=" + Str(GetLastError_()))
    CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  st = QueryServiceState(hSvc)
  If st = #SERVICE_RUNNING
    LogLine("OK: already running: " + name)
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf

  LogLine("Starting service: " + name)
  If StartServiceW_(hSvc, 0, 0) = 0
    LogLine("WARN: StartService returned failure: " + name + " LastError=" + Str(GetLastError_()))
  EndIf

  If WaitServiceState(hSvc, #SERVICE_RUNNING, timeoutMs) = 0
    LogLine("WARN: start timeout: " + name)
    CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
    ProcedureReturn #False
  EndIf

  LogLine("OK: started: " + name)
  CloseServiceHandle_(hSvc) : CloseServiceHandle_(hSCM)
  ProcedureReturn #True
EndProcedure

Procedure.i GetServiceStateByName(name.s)
  Protected hSCM.i, hSvc.i, st.i = -1
  hSCM = OpenSCManagerW_(0, 0, #SC_MANAGER_CONNECT)
  If hSCM = 0 : ProcedureReturn -1 : EndIf
  If ServiceExists(hSCM, name) = 0
    CloseServiceHandle_(hSCM)
    ProcedureReturn -2 ; not present
  EndIf
  hSvc = OpenServiceW_(hSCM, name, #SERVICE_QUERY_STATUS)
  If hSvc
    st = QueryServiceState(hSvc)
    CloseServiceHandle_(hSvc)
  EndIf
  CloseServiceHandle_(hSCM)
  ProcedureReturn st
EndProcedure

Procedure.s ServiceStateLabel(st.i)
  Select st
    Case #SERVICE_STOPPED : ProcedureReturn "Stopped"
    Case #SERVICE_START_PENDING : ProcedureReturn "StartPending"
    Case #SERVICE_STOP_PENDING : ProcedureReturn "StopPending"
    Case #SERVICE_RUNNING : ProcedureReturn "Running"
    Case -2 : ProcedureReturn "NotPresent"
    Default : ProcedureReturn "Unknown(" + Str(st) + ")"
  EndSelect
EndProcedure

Procedure.i IsServiceRunningLikeState(st.i)
  ProcedureReturn Bool(st = #SERVICE_RUNNING Or st = #SERVICE_START_PENDING)
EndProcedure

Procedure RememberServiceState(name.s)
  Protected st.i
  AddElement(gSvc())
  gSvc()\Name = name
  st = GetServiceStateByName(name)
  If st = -2
    gSvc()\Present = #False
    gSvc()\WasRunning = #False
  Else
    gSvc()\Present = #True
    gSvc()\WasRunning = IsServiceRunningLikeState(st)
  EndIf
EndProcedure

Procedure RememberDefaultServices()
  ClearList(gSvc())
  RememberServiceState("wuauserv")
  RememberServiceState("bits")
  RememberServiceState("cryptsvc")
  RememberServiceState("msiserver")
  RememberServiceState("UsoSvc")
  RememberServiceState("DoSvc")
EndProcedure

Procedure.i WasServiceRunning(name.s)
  ForEach gSvc()
    If gSvc()\Name = name
      ProcedureReturn Bool(gSvc()\Present And gSvc()\WasRunning)
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

; ----------------------------
; Cache reset (rename folders)
; ----------------------------

Procedure.i TryRenameDirWithRebootFallback(src.s, dst.s, retries.i=20, delayMs.i=250, allowRebootFallback.i=#True)
  ; Return values:
  ;  1 = renamed now
  ;  0 = scheduled on reboot
  ; -1 = failed
  Protected i.i, err.l

  ; Source missing: treat as success.
  If FileSize(src) <> -2
    ProcedureReturn 1
  EndIf

  For i = 1 To retries
    If MoveFileExW_(src, dst, #MOVEFILE_WRITE_THROUGH)
      ProcedureReturn 1
    EndIf
    err = GetLastError_()
    If i = 1 Or i = retries
      LogLine("WARN: rename attempt failed: " + src + " -> " + dst + " LastError=" + Str(err))
    EndIf
    Sleep_(delayMs)
  Next

  If allowRebootFallback
    If MoveFileExW_(src, dst, #MOVEFILE_DELAY_UNTIL_REBOOT)
      LogLine("WARN: rename scheduled on reboot: " + src + " -> " + dst)
      ProcedureReturn 0
    EndIf
    err = GetLastError_()
    LogLine("ERROR: failed to schedule rename on reboot: " + src + " -> " + dst + " LastError=" + Str(err))
  EndIf

  ProcedureReturn -1
EndProcedure

Procedure.i ResetWindowsUpdateCaches()
  Protected winDir.s = GetEnvironmentVariable("WINDIR")
  Protected ts.s = NowStamp()
  Protected sd.s, sdBak.s, cr.s, crBak.s
  Protected r.i, rebootNeeded.i

  If winDir = "" : winDir = "C:\Windows" : EndIf

  sd = winDir + "\SoftwareDistribution"
  sdBak = winDir + "\SoftwareDistribution.bak." + ts
  cr = SystemFolderPath("catroot2")
  crBak = cr + ".bak." + ts

  LogLine("Resetting Windows Update caches (rename).")

  If gDryRun
    LogLine("DRYRUN: would rename: " + sd + " -> " + sdBak)
    LogLine("DRYRUN: would rename: " + cr + " -> " + crBak)
    ProcedureReturn #True
  EndIf

  ; Ensure services that lock these folders are stopped (even if user didn't run the Stop step).
  ; Important: stop update-related services BEFORE cryptsvc to avoid dependent-service blocks.
  If GetServiceStateByName("wuauserv") = #SERVICE_RUNNING
    LogLine("wuauserv is running; stopping it for cache reset.")
    StopServiceByName("wuauserv", 60000)
  EndIf
  If GetServiceStateByName("bits") = #SERVICE_RUNNING
    LogLine("bits is running; stopping it for cache reset.")
    StopServiceByName("bits", 60000)
  EndIf
  If GetServiceStateByName("cryptsvc") = #SERVICE_RUNNING
    LogLine("cryptsvc is running; stopping it for catroot2 rename.")
    StopServiceByName("cryptsvc", 120000)
  EndIf

  r = TryRenameDirWithRebootFallback(sd, sdBak, 20, 250, #True)
  If r = -1
    LogLine("ERROR: failed to rename: " + sd)
    ProcedureReturn #False
  ElseIf r = 0
    rebootNeeded = #True
  EndIf

  ; catroot2 often releases locks slowly; retry longer.
  r = TryRenameDirWithRebootFallback(cr, crBak, 60, 500, #True)
  If r = -1
    LogLine("ERROR: failed to rename: " + cr)
    ProcedureReturn #False
  ElseIf r = 0
    rebootNeeded = #True
  EndIf

  If rebootNeeded
    LogLine("OK: cache reset scheduled. Reboot is required to complete folder renames.")
  Else
    LogLine("OK: cache reset done.")
  EndIf
  ProcedureReturn #True
EndProcedure

; ----------------------------
; Registry helpers (read-only policy detection)
; ----------------------------

Procedure.i RegKeyExists(hive.l, subkey.s)
  Protected hKey.i, rc.l
  Protected sam.l = #KEY_READ

  ; Prefer 64-bit view on 64-bit OS.
  If Is64BitOS()
    rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_64KEY, @hKey)
    If rc <> 0
      rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_32KEY, @hKey)
    EndIf
  Else
    rc = RegOpenKeyExW_(hive, subkey, 0, sam, @hKey)
  EndIf

  If rc = 0 And hKey
    RegCloseKey_(hKey)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.s RegReadStr(hive.l, subkey.s, valueName.s)
  Protected hKey.i, rc.l, t.l, cb.l
  Protected *buf, s.s = ""

  If Is64BitOS()
    rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_64KEY, @hKey)
    If rc <> 0
      rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_32KEY, @hKey)
    EndIf
  Else
    rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ, @hKey)
  EndIf

  If rc <> 0 Or hKey = 0
    ProcedureReturn ""
  EndIf

  cb = 0
  rc = RegQueryValueExW_(hKey, valueName, 0, @t, 0, @cb)
  If rc = 0 And cb > 0 And (t = #REG_SZ Or t = #REG_EXPAND_SZ)
    *buf = AllocateMemory(cb)
    If *buf
      If RegQueryValueExW_(hKey, valueName, 0, @t, *buf, @cb) = 0
        s = PeekS(*buf, -1, #PB_Unicode)
      EndIf
      FreeMemory(*buf)
    EndIf
  EndIf

  RegCloseKey_(hKey)
  ProcedureReturn s
EndProcedure

Procedure.i RegReadDword(hive.l, subkey.s, valueName.s, defaultVal.i=-1)
  Protected hKey.i, rc.l, t.l, cb.l
  Protected v.l

  If Is64BitOS()
    rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_64KEY, @hKey)
    If rc <> 0
      rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ | #KEY_WOW64_32KEY, @hKey)
    EndIf
  Else
    rc = RegOpenKeyExW_(hive, subkey, 0, #KEY_READ, @hKey)
  EndIf

  If rc <> 0 Or hKey = 0
    ProcedureReturn defaultVal
  EndIf

  cb = SizeOf(Long)
  v = 0
  rc = RegQueryValueExW_(hKey, valueName, 0, @t, @v, @cb)
  RegCloseKey_(hKey)

  If rc = 0 And t = #REG_DWORD
    ProcedureReturn v
  EndIf
  ProcedureReturn defaultVal
EndProcedure

Procedure LogPolicyAndHealth()
  Protected baseWU.s = "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
  Protected baseAU.s = baseWU + "\AU"
  Protected wsus.s, wustat.s
  Protected useWsus.i, noAuto.i, auOpt.i, disAcc.i, noInternet.i

  LogLine("System: " + OsLabel() + " | ProcBits=" + Str(SizeOf(Integer)*8) + " | OS64=" + Str(Is64BitOS()))

  wsus = RegReadStr(#PB_Registry_HKLM, baseWU, "WUServer")
  wustat = RegReadStr(#PB_Registry_HKLM, baseWU, "WUStatusServer")
  useWsus = RegReadDword(#PB_Registry_HKLM, baseAU, "UseWUServer", -1)
  noAuto = RegReadDword(#PB_Registry_HKLM, baseAU, "NoAutoUpdate", -1)
  auOpt = RegReadDword(#PB_Registry_HKLM, baseAU, "AUOptions", -1)
  disAcc = RegReadDword(#PB_Registry_HKLM, baseWU, "DisableWindowsUpdateAccess", -1)
  noInternet = RegReadDword(#PB_Registry_HKLM, baseWU, "DoNotConnectToWindowsUpdateInternetLocations", -1)

  If wsus <> "" Or wustat <> "" Or useWsus <> -1 Or noAuto <> -1 Or auOpt <> -1 Or disAcc <> -1 Or noInternet <> -1
    LogLine("Policies detected (WSUS/GPO may control updates).")
    If wsus <> "" : LogLine("Policy WUServer: " + wsus) : EndIf
    If wustat <> "" : LogLine("Policy WUStatusServer: " + wustat) : EndIf
    If useWsus <> -1 : LogLine("Policy UseWUServer: " + Str(useWsus)) : EndIf
    If noAuto <> -1 : LogLine("Policy NoAutoUpdate: " + Str(noAuto)) : EndIf
    If auOpt <> -1 : LogLine("Policy AUOptions: " + Str(auOpt)) : EndIf
    If disAcc <> -1 : LogLine("Policy DisableWindowsUpdateAccess: " + Str(disAcc)) : EndIf
    If noInternet <> -1 : LogLine("Policy DoNotConnectToWindowsUpdateInternetLocations: " + Str(noInternet)) : EndIf
  Else
    LogLine("No Windows Update policy values detected (best effort check).")
  EndIf

  ; Reboot pending checks
  If RegKeyExists(#PB_Registry_HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") Or
     RegKeyExists(#PB_Registry_HKLM, "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
    LogLine("Reboot pending: YES (CBS/WU key present).")
  Else
    LogLine("Reboot pending: not detected (CBS/WU).")
  EndIf
EndProcedure

; ----------------------------
; Diagnostics bundle (folder + zip)
; ----------------------------

Procedure.i EnsureDir(path.s)
  If FileSize(path) = -2 : ProcedureReturn #True : EndIf
  ProcedureReturn CreateDirectory(path)
EndProcedure

Procedure.i WriteTextFile(path.s, content.s)
  Protected f.i = CreateFile(#PB_Any, path)
  If f = 0 : ProcedureReturn #False : EndIf
  WriteString(f, content, #PB_UTF8)
  CloseFile(f)
  ProcedureReturn #True
EndProcedure

Procedure.i CopyIfExists(src.s, dst.s)
  If FileSize(src) >= 0
    CopyFile(src, dst)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure AddFolderToZip(pack.i, folder.s, relBase.s)
  Protected dir.i, name.s, full.s, rel.s
  dir = ExamineDirectory(#PB_Any, folder, "*")
  If dir = 0 : ProcedureReturn : EndIf

  While NextDirectoryEntry(dir)
    name = DirectoryEntryName(dir)
    If name = "." Or name = ".." : Continue : EndIf
    full = folder + "\" + name
    rel = relBase + "/" + name
    If DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
      AddFolderToZip(pack, full, rel)
    Else
      AddPackFile(pack, full, rel)
    EndIf
  Wend
  FinishDirectory(dir)
EndProcedure

Procedure.i ExportDiagnosticsZip()
  Protected ts.s = NowStamp()
  Protected baseDir.s = ExeDir()
  Protected diagDir.s = baseDir + "Diag-" + ts
  Protected zipPath.s = baseDir + "Diag-" + ts + ".zip"
  Protected winDir.s = GetEnvironmentVariable("WINDIR")
  Protected report.s, f.s
  Protected wevtutil.s, regexe.s, ps.s
  Protected pack.i

  If winDir = "" : winDir = "C:\Windows" : EndIf

  If EnsureDir(diagDir) = 0
    LogLine("ERROR: failed to create diagnostics folder: " + diagDir)
    ProcedureReturn #False
  EndIf

  LogLine("Diagnostics: collecting into: " + diagDir)

  ; Diagnostics are allowed in dry-run mode (collection-only / read-only).

  ; Summary report
  report = "UpdateRepair diagnostics" + #CRLF$ +
           "Timestamp: " + ts + #CRLF$ +
           "OS: " + OsLabel() + #CRLF$ +
           "ProcessBits: " + Str(SizeOf(Integer)*8) + #CRLF$ +
           "OS64: " + Str(Is64BitOS()) + #CRLF$ +
           "LogFile: " + gLogFile + #CRLF$ + #CRLF$ +
           "Service states:" + #CRLF$ +
           "wuauserv=" + ServiceStateLabel(GetServiceStateByName("wuauserv")) + #CRLF$ +
           "bits=" + ServiceStateLabel(GetServiceStateByName("bits")) + #CRLF$ +
           "cryptsvc=" + ServiceStateLabel(GetServiceStateByName("cryptsvc")) + #CRLF$ +
           "msiserver=" + ServiceStateLabel(GetServiceStateByName("msiserver")) + #CRLF$ +
           "UsoSvc=" + ServiceStateLabel(GetServiceStateByName("UsoSvc")) + #CRLF$ +
           "DoSvc=" + ServiceStateLabel(GetServiceStateByName("DoSvc")) + #CRLF$ + #CRLF$
  WriteTextFile(diagDir + "\summary.txt", report)

  ; Copy our main log
  CopyIfExists(gLogFile, diagDir + "\UpdateRepair.log")

  ; WindowsUpdate.log
  If IsWin10OrLater()
    ; Try generate via PowerShell Get-WindowsUpdateLog (best effort)
    ps = SystemToolPath("WindowsPowerShell\v1.0\powershell.exe")
    If FileSize(ps) >= 0
      LogLine("Diagnostics: generating WindowsUpdate.log (Win10+).")
      RunAndLog(ps, "-NoProfile -ExecutionPolicy Bypass -Command " +
                    Quote("Get-WindowsUpdateLog -LogPath " + diagDir + "\WindowsUpdate.log"))
    EndIf
  Else
    CopyIfExists(winDir + "\WindowsUpdate.log", diagDir + "\WindowsUpdate.log")
  EndIf

  ; Export key policy registry areas (best effort)
  regexe = SystemToolPath("reg.exe")
  If FileSize(regexe) >= 0
    LogLine("Diagnostics: exporting policy registry keys.")
    RunAndLog(regexe, "export " + Quote("HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate") + " " + Quote(diagDir + "\policy-wu.reg") + " /y")
    RunAndLog(regexe, "export " + Quote("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate") + " " + Quote(diagDir + "\current-wu.reg") + " /y")
  EndIf

  ; Export event logs (EVTX) via wevtutil (Vista+)
  wevtutil = SystemToolPath("wevtutil.exe")
  If FileSize(wevtutil) >= 0
    LogLine("Diagnostics: exporting event logs (best effort).")
    RunAndLog(wevtutil, "epl " + Quote("System") + " " + Quote(diagDir + "\System.evtx") + " /ow:true")
    RunAndLog(wevtutil, "epl " + Quote("Application") + " " + Quote(diagDir + "\Application.evtx") + " /ow:true")
    RunAndLog(wevtutil, "epl " + Quote("Setup") + " " + Quote(diagDir + "\Setup.evtx") + " /ow:true")
    ; Windows Update client operational log (may not exist/enabled on all SKUs)
    RunAndLog(wevtutil, "epl " + Quote("Microsoft-Windows-WindowsUpdateClient/Operational") + " " + Quote(diagDir + "\WindowsUpdateClient-Operational.evtx") + " /ow:true")
  Else
    LogLine("Diagnostics: SKIP wevtutil (not found).")
  EndIf

  ; Zip it
  LogLine("Diagnostics: packaging ZIP: " + zipPath)
  pack = CreatePack(#PB_Any, zipPath, #PB_PackerPlugin_Zip)
  If pack = 0
    LogLine("ERROR: failed to create zip: " + zipPath)
    ProcedureReturn #False
  EndIf

  AddFolderToZip(pack, diagDir, "Diag-" + ts)
  ClosePack(pack)

  gLastDiagZip = zipPath
  LogLine("Diagnostics: done: " + zipPath)
  ProcedureReturn #True
EndProcedure

Procedure ExportThread(*dummy)
  gIsExporting = #True
  LogLine("=== Start Diagnostics Export ===")
  ExportDiagnosticsZip()
  LogLine("=== End Diagnostics Export ===")
  gIsExporting = #False
EndProcedure

; ----------------------------
; Steps / worker thread
; ----------------------------

Enumeration Steps
  #Step_StopServices
  #Step_ResetCaches
  #Step_StartServices
  #Step_RunDISM
  #Step_RunSFC
  #Step_ResetWinHTTP
  #Step_ResetWinsock
  #Step_FlushDNS
  #Step_LogPolicyAndHealth
EndEnumeration

Global Dim gSelectedStep.i(#Step_LogPolicyAndHealth)

Procedure StopUpdateServices()
  RememberDefaultServices()
  LogLine("Service snapshot captured. Will restore prior running state when done.")

  ; Stop only what was running (safe + avoids changing intentional state)
  ; Order: stop orchestrators first, then WU/BITS, then crypto/installer.
  If WasServiceRunning("UsoSvc")    : StopServiceByName("UsoSvc")    : EndIf
  If WasServiceRunning("DoSvc")     : StopServiceByName("DoSvc")     : EndIf
  If WasServiceRunning("wuauserv")  : StopServiceByName("wuauserv")  : EndIf
  If WasServiceRunning("bits")      : StopServiceByName("bits")      : EndIf
  If WasServiceRunning("cryptsvc")  : StopServiceByName("cryptsvc")  : EndIf
  If WasServiceRunning("msiserver") : StopServiceByName("msiserver") : EndIf
EndProcedure

Procedure StartUpdateServices()
  If ListSize(gSvc()) = 0
    LogLine("WARN: no captured service state; not restoring services. Run Stop step first.")
    ProcedureReturn
  EndIf

  ; Start only what was running before (ordered)
  If WasServiceRunning("cryptsvc")  : StartServiceByName("cryptsvc")  : EndIf
  If WasServiceRunning("msiserver") : StartServiceByName("msiserver") : EndIf
  If WasServiceRunning("bits")      : StartServiceByName("bits")      : EndIf
  If WasServiceRunning("wuauserv")  : StartServiceByName("wuauserv")  : EndIf
  If WasServiceRunning("DoSvc")     : StartServiceByName("DoSvc")     : EndIf
  If WasServiceRunning("UsoSvc")    : StartServiceByName("UsoSvc")    : EndIf
EndProcedure

Procedure Worker(*dummy)
  Protected dism.s, sfc.s, netsh.s, ipconfig.s
  Protected shutdownExe.s

  gIsRunning = #True
  LogLine("=== Start Repair ===")

  If gSelectedStep(#Step_LogPolicyAndHealth)
    LogPolicyAndHealth()
  EndIf

  If gSelectedStep(#Step_StopServices)
    StopUpdateServices()
  EndIf

  If gSelectedStep(#Step_ResetCaches)
    ResetWindowsUpdateCaches()
  EndIf

  If gSelectedStep(#Step_RunDISM)
    If IsWin10OrLater()
      dism = SystemToolPath("dism.exe")
      RunAndLog(dism, "/Online /Cleanup-Image /RestoreHealth")
    Else
      LogLine("SKIP: DISM /RestoreHealth not enabled for this OS preset.")
    EndIf
  EndIf

  If gSelectedStep(#Step_RunSFC)
    sfc = SystemToolPath("sfc.exe")
    RunAndLog(sfc, "/scannow")
  EndIf

  If gSelectedStep(#Step_ResetWinHTTP)
    netsh = SystemToolPath("netsh.exe")
    RunAndLog(netsh, "winhttp reset proxy")
  EndIf

  If gSelectedStep(#Step_ResetWinsock)
    netsh = SystemToolPath("netsh.exe")
    RunAndLog(netsh, "winsock reset")
  EndIf

  If gSelectedStep(#Step_FlushDNS)
    ipconfig = SystemToolPath("ipconfig.exe")
    RunAndLog(ipconfig, "/flushdns")
  EndIf

  ; Restore services at the end (after repairs)
  If gSelectedStep(#Step_StartServices)
    StartUpdateServices()
  EndIf

  LogLine("=== End Repair ===")

  If gRebootAfter
    If gDryRun
      LogLine("DRYRUN: reboot requested but skipped.")
    Else
      shutdownExe = SystemToolPath("shutdown.exe")
      LogLine("Reboot requested. System will reboot in 10 seconds.")
      RunAndLog(shutdownExe, "/r /t 10 /c " + Quote(#APP_NAME + ": reboot requested"))
    EndIf
  EndIf

  gIsRunning = #False
EndProcedure

; ----------------------------
; CLI mode
; ----------------------------

Procedure.s Lower(s.s) : ProcedureReturn LCase(s) : EndProcedure

Procedure.i StepIdFromToken(tok.s)
  tok = Lower(Trim(tok))
  Select tok
    Case "stop"        : ProcedureReturn #Step_StopServices
    Case "caches"      : ProcedureReturn #Step_ResetCaches
    Case "start"       : ProcedureReturn #Step_StartServices
    Case "dism"        : ProcedureReturn #Step_RunDISM
    Case "sfc"         : ProcedureReturn #Step_RunSFC
    Case "winhttp"     : ProcedureReturn #Step_ResetWinHTTP
    Case "winsock"     : ProcedureReturn #Step_ResetWinsock
    Case "dns"         : ProcedureReturn #Step_FlushDNS
    Case "policy"      : ProcedureReturn #Step_LogPolicyAndHealth
  EndSelect
  ProcedureReturn -1
EndProcedure

Procedure ApplyRecommendedPresetToArray()
  gSelectedStep(#Step_LogPolicyAndHealth) = #True
  gSelectedStep(#Step_StopServices) = #True
  gSelectedStep(#Step_ResetCaches) = #True
  gSelectedStep(#Step_StartServices) = #True
  gRebootAfter = #False
  gSelectedStep(#Step_RunSFC) = #True
  If IsWin10OrLater()
    gSelectedStep(#Step_RunDISM) = #True
  Else
    gSelectedStep(#Step_RunDISM) = #False
  EndIf
  gSelectedStep(#Step_ResetWinHTTP) = #False
  gSelectedStep(#Step_ResetWinsock) = #False
  gSelectedStep(#Step_FlushDNS) = #False
EndProcedure

Procedure.i ParseCliAndMaybeRun()
  Protected i.i, p.s, cmd.s, arg.s, quiet.i, doRun.i, doDiag.i
  Protected steps.s, tok.s, stepId.i, n.i
  Protected count.i = CountProgramParameters()

  If count = 0 : ProcedureReturn #False : EndIf

  ; defaults
  For i = 0 To ArraySize(gSelectedStep())
    gSelectedStep(i) = #False
  Next

  For i = 0 To count-1
    p = ProgramParameter(i)
    If Left(Lower(p), 1) = "/" Or Left(Lower(p), 1) = "-"
      cmd = Lower(Mid(p, 2))
    Else
      cmd = Lower(p)
    EndIf

    Select cmd
      Case "quiet"
        quiet = #True

      Case "dryrun"
        gDryRun = #True

      Case "reboot"
        gRebootAfter = #True

      Case "recommended"
        ApplyRecommendedPresetToArray()
        doRun = #True

      Case "run"
        If i+1 < count
          steps = ProgramParameter(i+1)
          i + 1
          For n = 0 To ArraySize(gSelectedStep())
            gSelectedStep(n) = #False
          Next
          ; always include policy snapshot unless user didn't ask
          gSelectedStep(#Step_LogPolicyAndHealth) = #True
          While Len(steps) > 0
            tok = StringField(steps, 1, ",")
            stepId = StepIdFromToken(tok)
            If stepId >= 0
              gSelectedStep(stepId) = #True
            EndIf
            steps = RemoveString(steps, tok, #PB_String_CaseSensitive, 1, 1)
            steps = Trim(RemoveString(steps, ",", #PB_String_CaseSensitive, 1, 1))
          Wend
          doRun = #True
        EndIf

      Case "exportdiag"
        doDiag = #True
    EndSelect
  Next

  If quiet = 0
    ; If not quiet, still allow GUI to open even after CLI parsing unless we actually run/export.
  EndIf

  If doRun
    RelaunchElevatedIfNeeded()
    LogLine("CLI: starting repair.")
    Worker(0)
  EndIf

  If doDiag
    RelaunchElevatedIfNeeded()
    LogLine("CLI: exporting diagnostics.")
    ExportDiagnosticsZip()
  EndIf

  If doRun Or doDiag
    End
  EndIf

  ProcedureReturn #False
EndProcedure

; ----------------------------
; GUI
; ----------------------------

Enumeration Gadgets
  #Win
  #ChkDryRun
  #ChkReboot
  #ChkPolicy
  #ChkStop
  #ChkCaches
  #ChkStart
  #ChkDISM
  #ChkSFC
  #ChkWinHTTP
  #ChkWinsock
  #ChkDNS
  #BtnRecommended
  #BtnRun
  #BtnExport
  #BtnClear
  #EdLog
  #Timer
EndEnumeration

Procedure ApplyRecommendedPresetUI()
  SetGadgetState(#ChkPolicy, 1)
  SetGadgetState(#ChkStop, 1)
  SetGadgetState(#ChkCaches, 1)
  SetGadgetState(#ChkStart, 1)
  SetGadgetState(#ChkReboot, 0)

  If IsWin10OrLater()
    SetGadgetState(#ChkDISM, 1)
  Else
    SetGadgetState(#ChkDISM, 0)
  EndIf

  SetGadgetState(#ChkSFC, 1)
  SetGadgetState(#ChkWinHTTP, 0)
  SetGadgetState(#ChkWinsock, 0)
  SetGadgetState(#ChkDNS, 0)
EndProcedure

Procedure SyncSelectedStepsFromUI()
  gDryRun = Bool(GetGadgetState(#ChkDryRun) <> 0)
  gRebootAfter = Bool(GetGadgetState(#ChkReboot) <> 0)
  gSelectedStep(#Step_LogPolicyAndHealth) = Bool(GetGadgetState(#ChkPolicy) <> 0)
  gSelectedStep(#Step_StopServices)  = Bool(GetGadgetState(#ChkStop) <> 0)
  gSelectedStep(#Step_ResetCaches)   = Bool(GetGadgetState(#ChkCaches) <> 0)
  gSelectedStep(#Step_StartServices) = Bool(GetGadgetState(#ChkStart) <> 0)
  gSelectedStep(#Step_RunDISM)       = Bool(GetGadgetState(#ChkDISM) <> 0)
  gSelectedStep(#Step_RunSFC)        = Bool(GetGadgetState(#ChkSFC) <> 0)
  gSelectedStep(#Step_ResetWinHTTP)  = Bool(GetGadgetState(#ChkWinHTTP) <> 0)
  gSelectedStep(#Step_ResetWinsock)  = Bool(GetGadgetState(#ChkWinsock) <> 0)
  gSelectedStep(#Step_FlushDNS)      = Bool(GetGadgetState(#ChkDNS) <> 0)
EndProcedure

Procedure DrainLogToUI()
  Protected text.s
  LockMutex(gMutex)
  While FirstElement(gPendingLog())
    text = gPendingLog()
    DeleteElement(gPendingLog())
    SetGadgetText(#EdLog, GetGadgetText(#EdLog) + text + #CRLF$)
  Wend
  UnlockMutex(gMutex)
EndProcedure

Procedure SetUiEnabled(enabled.i)
  DisableGadget(#ChkDryRun,  Bool(enabled=0))
  DisableGadget(#ChkReboot,  Bool(enabled=0))
  DisableGadget(#ChkPolicy,  Bool(enabled=0))
  DisableGadget(#ChkStop,    Bool(enabled=0))
  DisableGadget(#ChkCaches,  Bool(enabled=0))
  DisableGadget(#ChkStart,   Bool(enabled=0))
  DisableGadget(#ChkDISM,    Bool(enabled=0))
  DisableGadget(#ChkSFC,     Bool(enabled=0))
  DisableGadget(#ChkWinHTTP, Bool(enabled=0))
  DisableGadget(#ChkWinsock, Bool(enabled=0))
  DisableGadget(#ChkDNS,     Bool(enabled=0))

  DisableGadget(#BtnRecommended, Bool(enabled=0))
  DisableGadget(#BtnRun,         Bool(enabled=0))
  DisableGadget(#BtnExport,      Bool(enabled=0))
  DisableGadget(#BtnClear,       Bool(enabled=0))
EndProcedure

; ----------------------------
; Main
; ----------------------------

gMutex = CreateMutex()
gLogFile = ExeDir() + #APP_NAME + "-" + NowStamp() + ".log"

; CLI early-exit if requested
ParseCliAndMaybeRun()

RelaunchElevatedIfNeeded()

OpenWindow(#Win, 0, 0, 900, 660, #APP_NAME + " - " + version, #PB_Window_MinimizeGadget | #PB_Window_SystemMenu |
                                                                 #PB_Window_ScreenCentered)

TextGadget(#PB_Any, 16, 14, 700, 20, "Selectable repair steps + diagnostics export. Log is saved next to the EXE.")

CheckBoxGadget(#ChkDryRun,  500, 44, 240, 22, "Simulation (no changes)")
CheckBoxGadget(#ChkReboot,  500, 234, 240, 22, "Reboot after repair (10s)")
CheckBoxGadget(#ChkPolicy,  16, 44, 450, 22, "Log policy/WSUS + reboot-pending checks (read-only)")
CheckBoxGadget(#ChkStop,    16, 72, 450, 22, "Stop update services (wuauserv, bits, cryptsvc, msiserver, UsoSvc, DoSvc)")
CheckBoxGadget(#ChkCaches,  16, 100, 450, 22, "Reset update caches (rename SoftwareDistribution + catroot2)")
CheckBoxGadget(#ChkStart,   16, 128, 450, 22, "Restore previously-running update services")
CheckBoxGadget(#ChkDISM,    16, 156, 450, 22, "Run DISM /RestoreHealth (Win10/11 + Server 2016+)")
CheckBoxGadget(#ChkSFC,     16, 184, 450, 22, "Run SFC /scannow")
CheckBoxGadget(#ChkWinHTTP, 16, 212, 450, 22, "Reset WinHTTP proxy (netsh winhttp reset proxy)")
CheckBoxGadget(#ChkWinsock, 16, 240, 450, 22, "Reset Winsock (netsh winsock reset)")
CheckBoxGadget(#ChkDNS,     16, 268, 450, 22, "Flush DNS (ipconfig /flushdns)")

ButtonGadget(#BtnRecommended, 500, 72, 240, 34, "Recommended Repair")
ButtonGadget(#BtnRun,         500, 114, 240, 34, "Run Selected")
ButtonGadget(#BtnExport,      500, 156, 240, 34, "Export Diagnostics (.zip)")
ButtonGadget(#BtnClear,       500, 198, 240, 34, "Clear Log")

EditorGadget(#EdLog, 16, 310, 868, 330)
SetGadgetText(#EdLog, "Log file: " + gLogFile + #CRLF$ + "OS: " + OsLabel() + #CRLF$)

If IsWin10OrLater() = 0
  DisableGadget(#ChkDISM, 1)
EndIf

ApplyRecommendedPresetUI()
AddWindowTimer(#Win, #Timer, 150)

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_Timer
      DrainLogToUI()
      If gIsRunning Or gIsExporting
        SetUiEnabled(#False)
      Else
        SetUiEnabled(#True)
        If IsWin10OrLater() = 0
          DisableGadget(#ChkDISM, 1)
        EndIf
      EndIf

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #ChkDryRun
          gDryRun = Bool(GetGadgetState(#ChkDryRun) <> 0)
          If gDryRun
            LogLine("Simulation enabled (no changes will be made).")
          Else
            LogLine("Simulation disabled (repairs will make changes).")
          EndIf

        Case #ChkStop
          ; If user stops services, default to restoring them afterwards.
          If GetGadgetState(#ChkStop)
            SetGadgetState(#ChkStart, 1)
          EndIf

        Case #BtnRecommended
          ApplyRecommendedPresetUI()

        Case #BtnClear
          SetGadgetText(#EdLog, "Log file: " + gLogFile + #CRLF$ + "OS: " + OsLabel() + #CRLF$)

        Case #BtnRun
          If gIsRunning = 0 And gIsExporting = 0
            SyncSelectedStepsFromUI()
            LogLine("Selected steps: policy=" + Str(gSelectedStep(#Step_LogPolicyAndHealth)) +
                    ", stop=" + Str(gSelectedStep(#Step_StopServices)) +
                    ", caches=" + Str(gSelectedStep(#Step_ResetCaches)) +
                    ", start=" + Str(gSelectedStep(#Step_StartServices)) +
                    ", dism=" + Str(gSelectedStep(#Step_RunDISM)) +
                    ", sfc=" + Str(gSelectedStep(#Step_RunSFC)) +
                    ", winhttp=" + Str(gSelectedStep(#Step_ResetWinHTTP)) +
                    ", winsock=" + Str(gSelectedStep(#Step_ResetWinsock)) +
                    ", dns=" + Str(gSelectedStep(#Step_FlushDNS)))
            gWorkerThread = CreateThread(@Worker(), 0)
          EndIf

        Case #BtnExport
          If gIsRunning = 0 And gIsExporting = 0
            gExportThread = CreateThread(@ExportThread(), 0)
          EndIf
      EndSelect

    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 51
; FirstLine = 36
; Folding = ---------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = WindowsUpdateRepair.ico
; Executable = ..\WindowsUpdateRepair.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = UpdateRepairPortable
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Windows Update Repair Tool
; VersionField7 = UpdateRepairPortable
; VersionField8 = UpdateRepairPortable.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
