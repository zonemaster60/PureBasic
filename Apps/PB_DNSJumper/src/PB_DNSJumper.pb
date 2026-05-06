; DnsJumperLite.pb - PureBasic v6.30 - Windows 11 x64
; Speedtests DNS resolvers (UDP/53 DNS query RTT) and applies best DNS on selected adapter.

EnableExplicit

; ----------------------------
; WinSock (IPv4 UDP) Constants & Structures
; ----------------------------
#AF_INET     = 2
#SOCK_DGRAM  = 2
#IPPROTO_UDP = 17

#SOL_SOCKET  = $FFFF
#SO_RCVTIMEO = $1006

#APP_NAME        = "PB_DNSJumper"
#EMAIL_NAME      = "zonemaster60@gmail.com"
#WORKER_EXIT_WAIT_MS           = 10000
Global version.s = "v1.0.0.8"

Global AppPath.s = GetPathPart(ProgramFilename())
If AppPath = "" : AppPath = GetCurrentDirectory() : EndIf
SetCurrentDirectory(AppPath)

Global LogPath.s
Global LogMutex.i
Global SettingsPath.s

Procedure.s ResolveSettingsPath()
  ProcedureReturn AppPath + #APP_NAME + ".ini"
EndProcedure

Procedure.s EnsureLogFolder(baseFolder.s)
  Protected folder.s = baseFolder

  If folder = ""
    ProcedureReturn ""
  EndIf

  If Right(folder, 1) <> "\"
    folder + "\"
  EndIf

  folder + "Logs\"

  If FileSize(folder) <> -2
    CreateDirectory(folder)
  EndIf

  If FileSize(folder) = -2
    ProcedureReturn folder
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s ResolveLogPath()
  Protected logFolder.s = EnsureLogFolder(AppPath)

  If logFolder <> ""
    ProcedureReturn logFolder + #APP_NAME + ".log"
  EndIf

  ProcedureReturn AppPath + #APP_NAME + ".log"
EndProcedure

Procedure LogLine(msg.s)
  Protected f.i
  Protected line.s

  If LogPath = ""
    LogPath = ResolveLogPath()
  EndIf

  If LogPath = ""
    ProcedureReturn
  EndIf

  If LogMutex = 0
    LogMutex = CreateMutex()
  EndIf

  line = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + " | " + msg

  LockMutex(LogMutex)
  If FileSize(LogPath) >= 0
    f = OpenFile(#PB_Any, LogPath)
    If f
      FileSeek(f, Lof(f))
    EndIf
  Else
    f = CreateFile(#PB_Any, LogPath)
  EndIf

  If f
    WriteStringN(f, line, #PB_UTF8)
    CloseFile(f)
  EndIf
  UnlockMutex(LogMutex)
EndProcedure

Procedure InitLogging()
  LogPath = ResolveLogPath()
  If LogMutex = 0
    LogMutex = CreateMutex()
  EndIf
  LogLine("=== START " + #APP_NAME + " " + version + " ===")
  LogLine("Exe: " + ProgramFilename())
  LogLine("Cwd: " + GetCurrentDirectory())
  LogLine("Log: " + LogPath)
EndProcedure

Procedure CloseLogging()
  If LogPath <> ""
    LogLine("=== EXIT " + #APP_NAME + " ===")
  EndIf
EndProcedure

Procedure OpenLog(showError.i = #True)
  If LogPath = ""
    LogPath = ResolveLogPath()
  EndIf

  If LogPath = ""
    If showError
      MessageRequester("Log", "Log path is not available.", #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  If FileSize(LogPath) < 0
    LogLine("Log created")
  EndIf

  If RunProgram(LogPath, "", "", #PB_Program_Open) = 0 And showError
    MessageRequester("Log", "Could not open log file:" + #CRLF$ + LogPath, #PB_MessageRequester_Error)
  EndIf
EndProcedure

InitLogging()

Enumeration SysTray
  #SysTray
EndEnumeration

Enumeration MenuItems
  #Tray_Show
  #Tray_OpenLog
  #Tray_StartTest
  #Tray_ApplyBest
  #Tray_RunAtStartup
  #Tray_StopTest
  #Tray_Exit
  #Tray_ProviderBase = 1000
EndEnumeration

Enumeration Gadgets
  #G_AdapterCombo
  #G_ReloadAdapters
  #G_TriesSpin
  #G_TimeoutSpin
  #G_AutoStartSpin
  #G_TrayRescanCombo
  #G_StartToTrayCheck
  #G_AutoApplyCheck
  #G_Start
  #G_Stop
  #G_Apply
  #G_Progress
  #G_BestLabel
  #G_List
  #G_Status
  #G_Exit
EndEnumeration

Enumeration Windows
  #WinMain
EndEnumeration

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    ; If already running, just exit silently instead of showing a message box
    ; This is better for startup/background apps
    LogLine("Another instance is already running; exiting")
    CloseHandle_(hMutex)
    CloseLogging()
    End
  EndIf


Structure DNSJ_WSAData
  wVersion.w
  wHighVersion.w
  szDescription.a[257]
  szSystemStatus.a[129]
  iMaxSockets.w
  iMaxUdpDg.w
  lpVendorInfo.i
EndStructure

Structure DNSJ_in_addr
  S_addr.l
EndStructure

Structure DNSJ_sockaddr_in
  sin_family.w
  sin_port.w
  sin_addr.DNSJ_in_addr
  sin_zero.a[8]
EndStructure

; ----------------------------
; WinSock Imports
; ----------------------------
Import "ws2_32.lib"
  WSAStartup(wVersionRequested.w, *lpWSAData.DNSJ_WSAData)
  WSACleanup()
  socket(af.l, type.l, protocol.l)
  closesocket(s.l)
  inet_pton(af.l, *src, *dst)
  sendto(s.l, *buf, len.l, flags.l, *to, tolen.l)
  recvfrom(s.l, *buf, len.l, flags.l, *from, *fromlen)
  setsockopt(s.l, level.l, optname.l, *optval, optlen.l)
EndImport

Import "kernel32.lib"
  QueryPerformanceCounter(*lpPerformanceCount.Quad)
  QueryPerformanceFrequency(*lpFrequency.Quad)
  GetEnvironmentVariableW(*lpName, *lpBuffer, nSize.l)
EndImport

Global gMutex.i
Global gStopFlag.l
Global gWorkerRunning.l
Global gWorkerDone.l
Global gWorkerTotalSteps.l
Global gWorkerStepsDone.l
Global gLastPowerShellOutput.s
Global gLastPowerShellExitCode.l = -1
Global gWorkerCancelled.b = #False
Global gWorkerThread.i

; ----------------------------
; Helper Procedures
; ----------------------------

Procedure.s GetEnvVar(name.s)
  Protected buf.s = Space(1024)
  Protected rc.l = GetEnvironmentVariableW(@name, @buf, 1024)
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

Procedure.i RunAndCapture(exe.s, args.s)
  Protected program.i, exitCode.i = -1
  LogLine("Run: " + exe + " " + args)
  program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program = 0
    LogLine("Failed to start: " + exe)
    ProcedureReturn -1
  EndIf
  While ProgramRunning(program)
    While AvailableProgramOutput(program) : ReadProgramString(program) : Wend
    Delay(5)
  Wend
  exitCode = ProgramExitCode(program)
  CloseProgram(program)
  LogLine("Exit code: " + Str(exitCode) + " | " + exe)
  ProcedureReturn exitCode
EndProcedure

Declare.s LastPowerShellMessage()
Declare.s FmtMS(x.d)
Declare.b ApplyProviderByName(name.s, adapter.s)
Declare.b ApplyBest(adapter.s)

Procedure.i IsInStartup()
  Protected args.s = "/Query /TN " + #DQUOTE$ + #APP_NAME + #DQUOTE$
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", args) = 0)
EndProcedure

Procedure.i SetRunAtStartup(state.b)
  Protected taskName.s = #APP_NAME
  Protected exePath.s = ProgramFilename()
  Protected workDir.s = GetPathPart(exePath)
  Protected userSam.s = CurrentUserSam()
  
  If state
    LogLine("Enabling run at startup")
    ; Register-ScheduledTask via PowerShell for maximum reliability (bypass registry hurdles)
    Protected psCmd.s = "Register-ScheduledTask -TaskName '" + ReplaceString(taskName, "'", "''") + "' " +
                        "-Action (New-ScheduledTaskAction -Execute '" + ReplaceString(exePath, "'", "''") + "' -WorkingDirectory '" + ReplaceString(workDir, "'", "''") + "' -Argument '/TRAY') " +
                        "-Trigger (New-ScheduledTaskTrigger -AtLogOn -User '" + ReplaceString(userSam, "'", "''") + "') " +
                        "-Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) " +
                        "-Principal (New-ScheduledTaskPrincipal -UserId '" + ReplaceString(userSam, "'", "''") + "' -LogonType Interactive -RunLevel Highest) -Force"
    
    Protected args.s = "-NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + psCmd + #DQUOTE$
    ProcedureReturn Bool(RunAndCapture("powershell.exe", args) = 0)
  Else
    LogLine("Disabling run at startup")
    Protected delArgs.s = "/Delete /F /TN " + #DQUOTE$ + taskName + #DQUOTE$
    ProcedureReturn Bool(RunAndCapture("schtasks.exe", delArgs) = 0)
  EndIf
EndProcedure

Procedure.w htons(v.w)
  ProcedureReturn ((v & $FF) << 8) | ((v >> 8) & $FF)
EndProcedure

Procedure.w ntohs(v.w)
  ProcedureReturn htons(v)
EndProcedure

; QuotePS(): Escapes single quotes for PowerShell commands.
Procedure.s QuotePS(s.s)
  ProcedureReturn "'" + ReplaceString(s, "'", "''") + "'"
EndProcedure

Procedure.s RunProgramCaptureUtf8(exe.s, args.s, *exitCode.Integer)
  Protected out.s = ""
  Protected program.i = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)

  If program = 0
    If *exitCode
      *exitCode\i = -1
    EndIf
    ProcedureReturn ""
  EndIf

  While ProgramRunning(program)
    Protected sawData.b = #False
    Protected errLine.s

    While AvailableProgramOutput(program)
      out + ReadProgramString(program, #PB_UTF8) + #CRLF$
      sawData = #True
    Wend

    Repeat
      errLine = ReadProgramError(program, #PB_UTF8)
      If errLine = "" : Break : EndIf
      out + errLine + #CRLF$
      sawData = #True
    ForEver

    If sawData = #False
      Delay(1)
    EndIf
  Wend

  While AvailableProgramOutput(program)
    out + ReadProgramString(program, #PB_UTF8) + #CRLF$
  Wend

  Repeat
    errLine = ReadProgramError(program, #PB_UTF8)
    If errLine = "" : Break : EndIf
    out + errLine + #CRLF$
  ForEver

  If *exitCode
    *exitCode\i = ProgramExitCode(program)
  EndIf

  CloseProgram(program)
  ProcedureReturn out
EndProcedure

; ExecPowerShell(): Executes a PowerShell command and returns success/failure.
Procedure.i ExecPowerShell(cmd.s)
  Protected psCmd.s
  Protected exitCode.Integer

  ; Force UTF-8 output so ReadProgramString(#PB_UTF8) works reliably.
  psCmd = "[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new(); $OutputEncoding=[System.Text.UTF8Encoding]::new(); $ErrorActionPreference='Stop'; try { " + cmd + " } catch { $_ | Out-String -Width 4096 | Write-Error; exit 1 }"

  gLastPowerShellOutput = RunProgramCaptureUtf8("powershell.exe",
                                                "-NoLogo -NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + psCmd + #DQUOTE$,
                                                @exitCode)
  gLastPowerShellExitCode = exitCode\i

  If exitCode\i = 0
    LogLine("PowerShell succeeded")
  Else
    LogLine("PowerShell failed: " + LastPowerShellMessage())
  EndIf

  ProcedureReturn Bool(exitCode\i = 0)
EndProcedure

Procedure.s LastPowerShellMessage()
  Protected msg.s = Trim(gLastPowerShellOutput)

  If msg <> ""
    ProcedureReturn msg
  EndIf

  If gLastPowerShellExitCode >= 0
    ProcedureReturn "PowerShell exit code: " + Str(gLastPowerShellExitCode)
  EndIf

  ProcedureReturn "PowerShell could not be started."
EndProcedure

Procedure.i AllocAsciiZ(s.s)
  Protected n = Len(s)
  Protected *m = AllocateMemory(n + 1)
  If *m
    PokeS(*m, s, -1, #PB_Ascii)
  EndIf
  ProcedureReturn *m
EndProcedure

Procedure.s ResolveProvidersFile()
  ; Prefer dns_servers.json next to the EXE; fallback to current directory; then source directory (IDE/dev builds).
  Protected pExe.s = GetPathPart(ProgramFilename()) + "files\" + #APP_NAME + "_servers.json"
  Protected pCwd.s = GetCurrentDirectory() + "files\" + #APP_NAME + "_servers.json"
  Protected pSrc.s = #PB_Compiler_FilePath + "files\" + #APP_NAME + "_servers.json"

  If FileSize(pExe) > 0 : ProcedureReturn pExe : EndIf
  If FileSize(pCwd) > 0 : ProcedureReturn pCwd : EndIf
  If FileSize(pSrc) > 0 : ProcedureReturn pSrc : EndIf

  ProcedureReturn pExe
EndProcedure

; ----------------------------
; DNS query (A) build/parse
; ----------------------------

Procedure.i BuildDnsQuery(domain.s, txid.w, *outLen.Integer)
  If domain = "" : ProcedureReturn 0 : EndIf

  Protected qnameLen = 1
  Protected partsCount = CountString(domain, ".") + 1
  Protected i, part.s

  For i = 1 To partsCount
    part = StringField(domain, i, ".")
    If Len(part) > 63 : ProcedureReturn 0 : EndIf ; DNS labels max 63 chars
    qnameLen + 1 + Len(part)
  Next

  If qnameLen > 255 : ProcedureReturn 0 : EndIf ; DNS qname max 255 chars

  Protected totalLen = 12 + qnameLen + 4
  Protected *buf = AllocateMemory(totalLen)
  If *buf = 0
    *outLen\i = 0
    ProcedureReturn 0
  EndIf

  Protected o = 0
  PokeW(*buf + o, htons(txid))  : o + 2          ; ID
  PokeW(*buf + o, htons($0100)) : o + 2          ; Flags: RD
  PokeW(*buf + o, htons(1))     : o + 2          ; QDCOUNT
  PokeW(*buf + o, 0)            : o + 2          ; ANCOUNT
  PokeW(*buf + o, 0)            : o + 2          ; NSCOUNT
  PokeW(*buf + o, 0)            : o + 2          ; ARCOUNT

  For i = 1 To partsCount
    part = StringField(domain, i, ".")
    PokeA(*buf + o, Len(part)) : o + 1
    PokeS(*buf + o, part, Len(part), #PB_Ascii) : o + Len(part)
  Next
  PokeA(*buf + o, 0) : o + 1

  PokeW(*buf + o, htons(1)) : o + 2              ; QTYPE=A
  PokeW(*buf + o, htons(1)) : o + 2              ; QCLASS=IN

  *outLen\i = totalLen
  ProcedureReturn *buf
EndProcedure

Procedure.b ValidDnsResponse(*resp, respLen.l, txid.w)
  If respLen < 12 : ProcedureReturn #False : EndIf
  
  Protected rid.w = ntohs(PeekW(*resp + 0))
  If rid <> txid : ProcedureReturn #False : EndIf

  Protected flags.w = ntohs(PeekW(*resp + 2))
  Protected qr = (flags >> 15) & 1  ; Check QR bit
  Protected rcode = flags & $000F

  If qr <> 1 : ProcedureReturn #False : EndIf ; Must be a response
  If rcode <> 0 : ProcedureReturn #False : EndIf ; Must be NOERROR
  
  ; Check QDCOUNT (at least 1)
  Protected qdcount.w = ntohs(PeekW(*resp + 4))
  If qdcount < 1 : ProcedureReturn #False : EndIf

  ProcedureReturn #True
EndProcedure

Procedure.b WorkerStopRequested()
  Protected stopRequested.b

  LockMutex(gMutex)
  stopRequested = Bool(gStopFlag <> 0)
  UnlockMutex(gMutex)

  ProcedureReturn stopRequested
EndProcedure

Procedure RequestWorkerStop()
  LockMutex(gMutex)
  gStopFlag = 1
  UnlockMutex(gMutex)
EndProcedure

Procedure.b WaitForWorkerStop(timeoutMs.l)
  Protected startTime.l = ElapsedMilliseconds()
  Protected running.l

  Repeat
    LockMutex(gMutex)
    running = gWorkerRunning
    UnlockMutex(gMutex)

    If running = 0
      ProcedureReturn #True
    EndIf

    Delay(10)
  Until timeoutMs >= 0 And ElapsedMilliseconds() - startTime >= timeoutMs

  ProcedureReturn #False
EndProcedure

Procedure.d DnsRTTms(serverIP.s, domain.s, timeoutMs.l)
  ; Returns RTT (ms) or -1 on failure/stop.
  If WorkerStopRequested()
    ProcedureReturn -1.0
  EndIf

  Static freq.q = 0
  If freq = 0
    QueryPerformanceFrequency(@freq)
  EndIf

  Protected s = socket(#AF_INET, #SOCK_DGRAM, #IPPROTO_UDP)
  If s = -1 : ProcedureReturn -1.0 : EndIf

  Protected timeoutOpt.l = timeoutMs
  setsockopt(s, #SOL_SOCKET, #SO_RCVTIMEO, @timeoutOpt, SizeOf(Long))

  Protected addr.DNSJ_sockaddr_in
  addr\sin_family = #AF_INET
  addr\sin_port = htons(53)

  Protected *ipA = AllocAsciiZ(serverIP)
  If *ipA = 0
    closesocket(s)
    ProcedureReturn -1.0
  EndIf
  Protected okPton = inet_pton(#AF_INET, *ipA, @addr\sin_addr)
  FreeMemory(*ipA)
  If okPton <> 1
    closesocket(s)
    ProcedureReturn -1.0
  EndIf

  Protected txid.w = Random($FFFF)
  Protected outLen.Integer
  Protected *q = BuildDnsQuery(domain, txid, @outLen)
  If *q = 0
    closesocket(s)
    ProcedureReturn -1.0
  EndIf

  Protected t0.q, t1.q
  QueryPerformanceCounter(@t0)
  Protected sent = sendto(s, *q, outLen\i, 0, @addr, SizeOf(DNSJ_sockaddr_in))
  FreeMemory(*q)
  If sent <= 0
    closesocket(s)
    ProcedureReturn -1.0
  EndIf

  Protected *buf = AllocateMemory(2048)
  If *buf = 0
    closesocket(s)
    ProcedureReturn -1.0
  EndIf

  Protected from.DNSJ_sockaddr_in
  Protected fromLen.l = SizeOf(DNSJ_sockaddr_in)
  Protected got = recvfrom(s, *buf, 2048, 0, @from, @fromLen)
  QueryPerformanceCounter(@t1)

  Protected ok.b = #False
  If got > 0
    ok = ValidDnsResponse(*buf, got, txid)
  EndIf

  FreeMemory(*buf)
  closesocket(s)

  If WorkerStopRequested()
    ProcedureReturn -1.0
  EndIf

  If ok = #False
    ProcedureReturn -1.0
  EndIf

  ProcedureReturn ((t1 - t0) * 1000.0) / freq
EndProcedure

; ----------------------------
; Benchmark model
; ----------------------------

Structure Provider
  name.s
  ip1.s
  ip2.s
EndStructure

Structure BenchResult
  provider.s
  ip.s
  ok.l
  total.l
  median.d
  p90.d
  best.d
  score.d
EndStructure

Global NewList Providers.Provider()
Global NewList Results.BenchResult()
Global NewList gQueue.BenchResult()

Global gTries.l = 3
Global gTimeoutMs.l = 800
Global gDomains.s = "example.com|cloudflare.com|google.com|wikipedia.org|github.com"
Global gProvidersFile.s = "dns_servers.json"
Global gLoadedProviders.i
Global gProvidersFromFile.l
Global gCurrentTest.s
Global gAutoStartDone.b = #False
Global gQueueApplied.b = #False
Global gAutoRunPending.b = #False
Global gCurrentRunAuto.b = #False
Global gStartTime.q = ElapsedMilliseconds()
Global gStartToTray.b = #False
Global gTrayIconReady.b = #False
Global gAutoStartDelaySec.l = 90
Global gTrayRescanHours.l = 4
Global gLastTrayRescanTick.q = ElapsedMilliseconds()
Global gAutoApplyAfterBenchmark.b = #True
Global gPreferredAdapter.s = ""

Procedure.i TrayRescanSelectionFromHours(hours.l)
  Select hours
    Case 2
      ProcedureReturn 0
    Case 4
      ProcedureReturn 1
    Case 8
      ProcedureReturn 2
    Case 12
      ProcedureReturn 3
  EndSelect

  ProcedureReturn 1
EndProcedure

Procedure LoadSettings()
  If SettingsPath = ""
    SettingsPath = ResolveSettingsPath()
  EndIf

  If OpenPreferences(SettingsPath)
    PreferenceGroup("General")
    gTries = ReadPreferenceLong("Tries", gTries)
    gTimeoutMs = ReadPreferenceLong("TimeoutMs", gTimeoutMs)
    gAutoStartDelaySec = ReadPreferenceLong("AutoStartDelaySec", gAutoStartDelaySec)
    gTrayRescanHours = ReadPreferenceLong("TrayRescanHours", gTrayRescanHours)
    gStartToTray = ReadPreferenceLong("StartToTray", gStartToTray)
    gAutoApplyAfterBenchmark = ReadPreferenceLong("AutoApplyAfterBenchmark", gAutoApplyAfterBenchmark)
    gPreferredAdapter = ReadPreferenceString("PreferredAdapter", gPreferredAdapter)
    ClosePreferences()
  EndIf

  If gTries < 1 : gTries = 1 : EndIf
  If gTries > 10 : gTries = 10 : EndIf
  If gTimeoutMs < 100 : gTimeoutMs = 100 : EndIf
  If gTimeoutMs > 5000 : gTimeoutMs = 5000 : EndIf
  If gAutoStartDelaySec < 0 : gAutoStartDelaySec = 0 : EndIf
  If gAutoStartDelaySec > 3600 : gAutoStartDelaySec = 3600 : EndIf

  Select gTrayRescanHours
    Case 2, 4, 8, 12
    Default
      gTrayRescanHours = 4
  EndSelect

  gStartToTray = Bool(gStartToTray)
  gAutoApplyAfterBenchmark = Bool(gAutoApplyAfterBenchmark)
EndProcedure

Procedure SaveSettings()
  If SettingsPath = ""
    SettingsPath = ResolveSettingsPath()
  EndIf

  If CreatePreferences(SettingsPath)
    PreferenceGroup("General")
    WritePreferenceLong("Tries", gTries)
    WritePreferenceLong("TimeoutMs", gTimeoutMs)
    WritePreferenceLong("AutoStartDelaySec", gAutoStartDelaySec)
    WritePreferenceLong("TrayRescanHours", gTrayRescanHours)
    WritePreferenceLong("StartToTray", gStartToTray)
    WritePreferenceLong("AutoApplyAfterBenchmark", gAutoApplyAfterBenchmark)
    WritePreferenceString("PreferredAdapter", gPreferredAdapter)
    ClosePreferences()
  Else
    LogLine("Failed to save settings: " + SettingsPath)
  EndIf
EndProcedure

Procedure AddProvider(name.s, ip1.s, ip2.s)
  AddElement(Providers())
  Providers()\name = name
  Providers()\ip1 = ip1
  Providers()\ip2 = ip2
EndProcedure

Procedure.b IsIPv4(ip.s)

  ip = Trim(ip)
  If CountString(ip, ".") <> 3 : ProcedureReturn #False : EndIf

  Protected i, c, part.s, n.l
  For i = 1 To 4
    part = StringField(ip, i, ".")
    If part = "" : ProcedureReturn #False : EndIf
    For c = 1 To Len(part)
      Protected ch = Asc(Mid(part, c, 1))
      If ch < 48 Or ch > 57 : ProcedureReturn #False : EndIf
    Next
    n = Val(part)
    If n < 0 Or n > 255 : ProcedureReturn #False : EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i LoadProvidersFromJsonFile(filePath.s)

  ; JSON formats supported:
  ; 1) { "providers": [ {"name":...,"primary":...,"secondary":...}, ... ] }
  ; 2) [ {"name":...,"primary":...,"secondary":...}, ... ]

  ClearList(Providers())

  Protected count.i = 0
  Protected json = LoadJSON(#PB_Any, filePath)

  If json = 0
    LogLine("Failed to load providers JSON: " + filePath)
    ProcedureReturn 0
  EndIf

  Protected root = JSONValue(json)
  Protected arr

  If JSONType(root) = #PB_JSON_Array
    arr = root
  ElseIf JSONType(root) = #PB_JSON_Object
    arr = GetJSONMember(root, "providers")
  EndIf

  If arr And JSONType(arr) = #PB_JSON_Array
    Protected i
    For i = 0 To JSONArraySize(arr) - 1
      Protected obj = GetJSONElement(arr, i)
      If obj = 0 Or JSONType(obj) <> #PB_JSON_Object : Continue : EndIf
      Protected nameV = GetJSONMember(obj, "name")
      Protected pV = GetJSONMember(obj, "primary")
      If pV = 0 : pV = GetJSONMember(obj, "ip1") : EndIf
      Protected sV = GetJSONMember(obj, "secondary")
      If sV = 0 : sV = GetJSONMember(obj, "ip2") : EndIf
      
      Protected name.s = Trim(GetJSONString(nameV))
      Protected ip1.s  = Trim(GetJSONString(pV))
      Protected ip2.s  = Trim(GetJSONString(sV))

      If ip2 = "" : ip2 = ip1 : EndIf
      If name = "" Or ip1 = "" : Continue : EndIf
      If IsIPv4(ip1) = #False Or IsIPv4(ip2) = #False : Continue : EndIf

      AddProvider(name, ip1, ip2)
      count + 1
    Next
  EndIf
  
  FreeJSON(json)
  LogLine("Loaded providers from file: " + filePath + " | count=" + Str(count))
  ProcedureReturn count

EndProcedure

Procedure.d MedianFromSortedArray(Array a.d(1), n.l)
  If n <= 0 : ProcedureReturn 1e30 : EndIf
  If (n % 2) = 1
    ProcedureReturn a(n/2)
  Else
    ProcedureReturn (a(n/2 - 1) + a(n/2)) / 2.0
  EndIf
EndProcedure

Procedure.d P90FromSortedArray(Array a.d(1), n.l)
  If n <= 0 : ProcedureReturn 1e30 : EndIf
  Protected k.d = (n - 1) * 0.90
  Protected f.l = Int(k)
  Protected c.l = f + 1
  If c >= n : c = n - 1 : EndIf
  If f = c : ProcedureReturn a(f) : EndIf
  ProcedureReturn a(f) + (a(c) - a(f)) * (k - f)
EndProcedure

Procedure BenchProvider(providerName.s, ip1.s, ip2.s, tries.l, timeoutMs.l, domains.s)
  Protected domainCount = CountString(domains, "|") + 1
  Protected total.l = tries * domainCount * 2
  Protected ok.l = 0

  Dim samples.d(total - 1)
  Protected si.l = 0

  Protected pass, i, d.s, rtt.d
  LogLine("Benchmarking provider: " + providerName + " | " + ip1 + " / " + ip2)
  For pass = 1 To tries
    For i = 1 To domainCount
      If WorkerStopRequested()
        ProcedureReturn
      EndIf

      d = StringField(domains, i, "|")

      rtt = DnsRTTms(ip1, d, timeoutMs)
      If rtt >= 0
        samples(si) = rtt
        si + 1
        ok + 1
      EndIf

      LockMutex(gMutex)
      gWorkerStepsDone + 1
      UnlockMutex(gMutex)

      If WorkerStopRequested()
        ProcedureReturn
      EndIf

      rtt = DnsRTTms(ip2, d, timeoutMs)
      If rtt >= 0
        samples(si) = rtt
        si + 1
        ok + 1
      EndIf

      LockMutex(gMutex)
      gWorkerStepsDone + 1
      UnlockMutex(gMutex)
    Next
  Next

  Protected med.d, p90.d, best.d
  If ok > 0
    ReDim samples(ok - 1)
    SortArray(samples(), #PB_Sort_Ascending)
    med = MedianFromSortedArray(samples(), ok)
    p90 = P90FromSortedArray(samples(), ok)
    best = samples(0)
  Else
    med = 1e30 : p90 = 1e30 : best = 1e30
  EndIf

  Protected success.d = ok / (total * 1.0)
  Protected score.d = (1.0 - success) * 10000.0 + med

  LockMutex(gMutex)
  AddElement(gQueue())
  gQueue()\provider = providerName
  gQueue()\ip = ip1 + " / " + ip2
  gQueue()\ok = ok
  gQueue()\total = total
  gQueue()\median = med
  gQueue()\p90 = p90
  gQueue()\best = best
  gQueue()\score = score
  UnlockMutex(gMutex)
  LogLine("Benchmark result: " + providerName + " | ok=" + Str(ok) + "/" + Str(total) + " | median=" + FmtMS(med) + " ms | best=" + FmtMS(best) + " ms")
EndProcedure

Procedure WorkerThread(*dummy)
  Protected tries.l
  Protected timeoutMs.l
  Protected domains.s
  Protected wsa.DNSJ_WSAData
  LogLine("Worker thread started")
  If WSAStartup($0202, @wsa) <> 0
    LogLine("WSAStartup failed")
    LockMutex(gMutex)
    gWorkerDone = 1
    gWorkerRunning = 0
    UnlockMutex(gMutex)
    ProcedureReturn
  EndIf

  ; Copy global Providers() list to a thread-local list.
  ; PureBasic lists share a single internal cursor; UI code also iterates Providers().

  Protected NewList localProviders.Provider()
  LockMutex(gMutex)
  tries = gTries
  timeoutMs = gTimeoutMs
  domains = gDomains
  
  ForEach Providers()
    AddElement(localProviders())
    localProviders() = Providers()
  Next

  UnlockMutex(gMutex)

  ForEach localProviders()
    If WorkerStopRequested() : Break : EndIf
    LockMutex(gMutex)
    gCurrentTest = "Testing: " + localProviders()\name + "  [" + localProviders()\ip1 + ", " + localProviders()\ip2 + "]"
    UnlockMutex(gMutex)
    BenchProvider(localProviders()\name, localProviders()\ip1, localProviders()\ip2, tries, timeoutMs, domains)
  Next

  WSACleanup()
  LockMutex(gMutex)
  gWorkerDone = 1
  gWorkerRunning = 0
  gCurrentTest = ""
  UnlockMutex(gMutex)
  LogLine("Worker thread finished")

EndProcedure

Procedure.s FmtMS(x.d)
  If x >= 1e29 : ProcedureReturn "inf" : EndIf
  ProcedureReturn StrD(x, 1)
EndProcedure

Procedure.s FmtPct(ok.l, total.l)
  If total <= 0 : ProcedureReturn "0.0%" : EndIf
  ProcedureReturn StrD((ok * 100.0) / total, 1) + "%"
EndProcedure

Procedure RefreshListIcon(listGadget.i, bestLabelGadget.i)
  ; Sort Results list by score and rebuild UI
  SortStructuredList(Results(), #PB_Sort_Ascending, OffsetOf(BenchResult\score), TypeOf(BenchResult\score))

  SendMessage_(GadgetID(listGadget), #WM_SETREDRAW, #False, 0)
  ClearGadgetItems(listGadget)

  Protected rank = 1
  ForEach Results()
    Protected line.s
    line = Str(rank) + Chr(10) + Results()\provider + Chr(10) + Results()\ip + Chr(10) + FmtPct(Results()\ok, Results()\total) + Chr(10) + FmtMS(Results()\median) + Chr(10) + FmtMS(Results()\p90) + Chr(10) + FmtMS(Results()\best)
    AddGadgetItem(listGadget, -1, line)
    rank + 1
  Next
  SendMessage_(GadgetID(listGadget), #WM_SETREDRAW, #True, 0)

  If ListSize(Results()) > 0
    FirstElement(Results())
    ; Determine provider pair for display (ip1, ip2)
    Protected p1.s = Results()\ip
    Protected p2.s = Results()\ip
    LockMutex(gMutex)
    ForEach Providers()
      If Providers()\name = Results()\provider
        p1 = Providers()\ip1
        p2 = Providers()\ip2
        Break
      EndIf
    Next
    UnlockMutex(gMutex)
    SetGadgetText(bestLabelGadget, "Best: " + Results()\provider + "  [" + p1 + ", " + p2 + "]")
    SysTrayIconToolTip(#SysTray, #APP_NAME + " - Best: " + Results()\provider + " (" + FmtMS(Results()\median) + "ms)")
  Else
    SetGadgetText(bestLabelGadget, "Best: (none)")
    SysTrayIconToolTip(#SysTray, #APP_NAME)
  EndIf
EndProcedure

Procedure.s GetProviderPair(name.s)
  Protected dns1.s = ""
  Protected dns2.s = ""

  LockMutex(gMutex)
  ForEach Providers()
    If Providers()\name = name
      dns1 = Providers()\ip1
      dns2 = Providers()\ip2
      Break
    EndIf
  Next
  UnlockMutex(gMutex)

  If dns1 = "" Or dns2 = ""
    ProcedureReturn ""
  EndIf

  ProcedureReturn dns1 + "|" + dns2
EndProcedure

Procedure.s ProviderListLine(rank.i, providerName.s, providerIP.s, successText.s, medianText.s, p90Text.s, bestText.s)
  ProcedureReturn Str(rank) + Chr(10) + providerName + Chr(10) + providerIP + Chr(10) + successText + Chr(10) + medianText + Chr(10) + p90Text + Chr(10) + bestText
EndProcedure

Procedure PopulateProviderList(listGadget.i)
  ClearGadgetItems(listGadget)

  ForEach Providers()
    AddGadgetItem(listGadget, -1, ProviderListLine(0, Providers()\name, Providers()\ip1 + " / " + Providers()\ip2, "0%", "-", "-", "-"))
  Next
EndProcedure

Procedure SetBenchmarkUiState(isRunning.i)
  DisableGadget(#G_Start, Bool(isRunning))
  DisableGadget(#G_Stop, Bool(Not isRunning))
  DisableGadget(#G_Apply, Bool(isRunning Or ListSize(Results()) = 0))
  DisableGadget(#G_ReloadAdapters, Bool(isRunning))
  DisableGadget(#G_AdapterCombo, Bool(isRunning))
  DisableGadget(#G_TriesSpin, Bool(isRunning))
  DisableGadget(#G_TimeoutSpin, Bool(isRunning))
  DisableGadget(#G_AutoStartSpin, Bool(isRunning))
  DisableGadget(#G_TrayRescanCombo, Bool(isRunning))
  DisableGadget(#G_Exit, Bool(isRunning))
EndProcedure

Procedure ShowMainWindow(show.i)
  HideWindow(#WinMain, Bool(Not show))
  If show
    SetWindowState(#WinMain, #PB_Window_Normal)
    SetForegroundWindow_(WindowID(#WinMain))
  Else
    gLastTrayRescanTick = ElapsedMilliseconds()
  EndIf
EndProcedure

Procedure ToggleMainWindow()
  If IsWindowVisible_(WindowID(#WinMain)) And GetWindowState(#WinMain) <> #PB_Window_Minimize
    ShowMainWindow(#False)
  Else
    ShowMainWindow(#True)
  EndIf
EndProcedure

Procedure.b ConfirmExit()
  ProcedureReturn Bool(MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes)
EndProcedure

Procedure.b MainWindowVisible()
  ProcedureReturn Bool(IsWindowVisible_(WindowID(#WinMain)) And GetWindowState(#WinMain) <> #PB_Window_Minimize)
EndProcedure

Procedure.l TrayRescanHours()
  Protected selection = GetGadgetState(#G_TrayRescanCombo)

  Select selection
    Case 0
      ProcedureReturn 2
    Case 1
      ProcedureReturn 4
    Case 2
      ProcedureReturn 8
    Case 3
      ProcedureReturn 12
  EndSelect

  ProcedureReturn 0
EndProcedure

Procedure SyncSettingsFromUi()
  gTries = GetGadgetState(#G_TriesSpin)
  gTimeoutMs = GetGadgetState(#G_TimeoutSpin)
  gAutoStartDelaySec = GetGadgetState(#G_AutoStartSpin)
  gTrayRescanHours = TrayRescanHours()
  gStartToTray = Bool(GetGadgetState(#G_StartToTrayCheck))
  gAutoApplyAfterBenchmark = Bool(GetGadgetState(#G_AutoApplyCheck))
  gPreferredAdapter = GetGadgetText(#G_AdapterCombo)
EndProcedure

Procedure.s FirstResultProviderName()
  Protected providerName.s = ""

  LockMutex(gMutex)
  If ListSize(Results()) > 0
    FirstElement(Results())
    providerName = Results()\provider
  EndIf
  UnlockMutex(gMutex)

  ProcedureReturn providerName
EndProcedure

Procedure.b ApplyProviderWithFeedback(providerName.s, adapter.s, pendingText.s, successText.s, failureText.s, dialogTitle.s)
  SetGadgetText(#G_Status, pendingText)
  If ApplyProviderByName(providerName, adapter)
    SetGadgetText(#G_Status, successText)
    ProcedureReturn #True
  EndIf

  SetGadgetText(#G_Status, failureText)
  MessageRequester(dialogTitle, failureText + #CRLF$ + #CRLF$ + LastPowerShellMessage())
  ProcedureReturn #False
EndProcedure

Procedure.b ApplyBestWithFeedback(adapter.s, providerName.s, dialogTitle.s)
  If providerName = ""
    MessageRequester(dialogTitle, "Run the test first to find the best provider.")
    ProcedureReturn #False
  EndIf

  SetGadgetText(#G_Status, "Applying best: " + providerName + " (requires Administrator)...")
  If ApplyBest(adapter)
    SetGadgetText(#G_Status, "Best DNS (" + providerName + ") applied.")
    LogLine("Best provider applied: " + providerName)
    ProcedureReturn #True
  EndIf

  SetGadgetText(#G_Status, "Failed to apply best DNS (" + providerName + ").")
  MessageRequester(dialogTitle, "Failed to apply best DNS (" + providerName + ")." + #CRLF$ + #CRLF$ + LastPowerShellMessage())
  ProcedureReturn #False
EndProcedure

Procedure.b StartBenchmarkRun()
  LogLine("Benchmark started")
  ClearList(Results())
  PopulateProviderList(#G_List)
  SetGadgetText(#G_BestLabel, "Best: (running...)")
  SetGadgetText(#G_Status, "Testing DNS servers...")

  gTries = GetGadgetState(#G_TriesSpin)
  gTimeoutMs = GetGadgetState(#G_TimeoutSpin)
  gAutoStartDelaySec = GetGadgetState(#G_AutoStartSpin)
  gTrayRescanHours = TrayRescanHours()

  LockMutex(gMutex)
  gStopFlag = 0
  gWorkerRunning = 1
  gWorkerDone = 0
  gWorkerCancelled = 0
  gQueueApplied = #False
  gCurrentRunAuto = gAutoRunPending
  gAutoRunPending = #False
  gWorkerStepsDone = 0
  ClearList(gQueue())
  ; steps = (providers * 2 IPs) * (tries * domains)
  Protected domainCount = CountString(gDomains, "|") + 1
  gWorkerTotalSteps = ListSize(Providers()) * 2 * gTries * domainCount
  UnlockMutex(gMutex)

  SetBenchmarkUiState(#True)
  SetGadgetState(#G_Progress, 0)

  gWorkerThread = CreateThread(@WorkerThread(), 0)
  If gWorkerThread = 0
    LogLine("Failed to create worker thread")
    LockMutex(gMutex)
    gWorkerRunning = 0
    gWorkerDone = 0
    gCurrentRunAuto = #False
    UnlockMutex(gMutex)
    SetBenchmarkUiState(#False)
    SetGadgetState(#G_Progress, 0)
    SetGadgetText(#G_Status, "Failed to start benchmark thread.")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure FinishBenchmarkRun(wasCancelled.i)
  SetBenchmarkUiState(#False)
  If wasCancelled
    SetGadgetText(#G_Status, "Stopped.")
    LogLine("Benchmark stopped")
    SysTrayIconToolTip(#SysTray, #APP_NAME + " - Benchmark Stopped")
  Else
    SetGadgetText(#G_Status, "Done. (Apply requires Administrator)")
    LogLine("Benchmark completed")
    SysTrayIconToolTip(#SysTray, #APP_NAME + " - Benchmark Complete")
  EndIf

  LockMutex(gMutex)
  gWorkerDone = 0
  gCurrentRunAuto = #False
  gWorkerThread = 0
  UnlockMutex(gMutex)
EndProcedure

Procedure.b AutoApplyBestProvider(adapter.s)
  If adapter = ""
    LogLine("Auto-apply skipped: no adapter selected")
    ProcedureReturn #False
  EndIf

  If FirstResultProviderName() = ""
    LogLine("Auto-apply skipped: no benchmark result available")
    ProcedureReturn #False
  EndIf

  SetGadgetText(#G_Status, "Auto-Applying best DNS...")
  If ApplyBest(adapter)
    SetGadgetText(#G_Status, "Auto-Apply complete.")
    SysTrayIconToolTip(#SysTray, #APP_NAME + " - Auto-Apply Complete")
    LogLine("Auto-apply completed")
    ProcedureReturn #True
  EndIf

  SetGadgetText(#G_Status, "Auto-Apply failed.")
  LogLine("Auto-apply failed: " + LastPowerShellMessage())
  MessageRequester("Auto-Apply", "Failed to apply the best DNS automatically." + #CRLF$ + #CRLF$ + LastPowerShellMessage())
  ProcedureReturn #False
EndProcedure

Procedure.b ApplyDnsServers(adapter.s, dns1.s, dns2.s)
  If adapter = "" Or dns1 = "" Or dns2 = ""
    gLastPowerShellOutput = "DNS server pair is incomplete."
    gLastPowerShellExitCode = -1
    LogLine("Apply DNS skipped due to incomplete server pair")
    ProcedureReturn #False
  EndIf

  LogLine("Applying DNS servers to adapter '" + adapter + "': " + dns1 + ", " + dns2)
  Protected psCmd.s = "Set-DnsClientServerAddress -InterfaceAlias " + QuotePS(adapter) + " -ServerAddresses @(" + QuotePS(dns1) + "," + QuotePS(dns2) + ") -ErrorAction Stop; Register-DnsClient -ErrorAction Stop"
  If ExecPowerShell(psCmd)
    LogLine("DNS apply succeeded for adapter '" + adapter + "'")
    ProcedureReturn #True
  EndIf

  LogLine("DNS apply failed for adapter '" + adapter + "': " + LastPowerShellMessage())
  ProcedureReturn #False
EndProcedure

Procedure.b ApplyProviderByName(name.s, adapter.s)
  Protected pair.s = GetProviderPair(name)
  If pair = ""
    gLastPowerShellOutput = "DNS provider not found: " + name
    gLastPowerShellExitCode = -1
    LogLine("DNS provider not found: " + name)
    ProcedureReturn #False
  EndIf

  LogLine("Applying provider by name: " + name)
  ProcedureReturn ApplyDnsServers(adapter, StringField(pair, 1, "|"), StringField(pair, 2, "|"))
EndProcedure

Procedure.b IsRunAtStartup()
  ProcedureReturn IsInStartup()
EndProcedure

Procedure UpdateTrayMenu()
  If CreatePopupMenu(0)
    MenuItem(#Tray_Show, "Show / Hide GUI")
    MenuItem(#Tray_OpenLog, "Open Log (Logs folder)")
    MenuBar()
    
    MenuItem(#Tray_RunAtStartup, "Run at Startup")
    If IsRunAtStartup()
      SetMenuItemState(0, #Tray_RunAtStartup, #True)
    EndIf
    MenuBar()

    LockMutex(gMutex)
    Protected isRunning = gWorkerRunning
    If isRunning
      MenuItem(#Tray_StopTest, "Stop Testing")
    Else
      MenuItem(#Tray_StartTest, "Start Benchmark")
    EndIf
    
    If ListSize(Results()) > 0 And isRunning = #False
      FirstElement(Results())
      MenuItem(#Tray_ApplyBest, "Apply Best: " + Results()\provider)
    EndIf
    UnlockMutex(gMutex)
    
    MenuBar()
    OpenSubMenu("DNS Providers")

    LockMutex(gMutex)
    Protected i = 0
    ForEach Providers()
      MenuItem(#Tray_ProviderBase + i, Providers()\name)
      i + 1
    Next
    UnlockMutex(gMutex)
    CloseSubMenu()
    
    MenuBar()
    MenuItem(#Tray_Exit, "Exit")
  EndIf
EndProcedure

Procedure DrainQueueAndUpdateUI(listGadget.i, bestLabelGadget.i)
  Protected updated = 0
  LockMutex(gMutex)
  ForEach gQueue()
    AddElement(Results())
    Results() = gQueue()
    updated = 1
  Next
  ClearList(gQueue())
  UnlockMutex(gMutex)

  If updated
    RefreshListIcon(listGadget, bestLabelGadget)
  EndIf
EndProcedure

Procedure.s GetAdapterListPowerShell(requireUp.i)
  Protected filterNetAdapter.s
  Protected filterLegacy.s

  If requireUp
    filterNetAdapter = "$_.HardwareInterface -eq $true -and $_.Status -eq 'Up'"
    filterLegacy = "$_.PhysicalAdapter -eq $true -and $_.NetConnectionID -and $_.NetConnectionStatus -eq 2"
  Else
    filterNetAdapter = "$_.HardwareInterface -eq $true"
    filterLegacy = "$_.PhysicalAdapter -eq $true -and $_.NetConnectionID"
  EndIf

  ProcedureReturn "try { Get-NetAdapter | Where-Object { " + filterNetAdapter + " } | Select-Object -ExpandProperty Name | Sort-Object -Unique } catch { try { Get-CimInstance Win32_NetworkAdapter -ErrorAction Stop | Where-Object { " + filterLegacy + " } | Select-Object -ExpandProperty NetConnectionID | Sort-Object -Unique } catch { Get-WmiObject Win32_NetworkAdapter -ErrorAction Stop | Where-Object { " + filterLegacy + " } | Select-Object -ExpandProperty NetConnectionID | Sort-Object -Unique } }"
EndProcedure

Procedure LoadAdapters(combo.i)
  ClearGadgetItems(combo)
  ; Prefer physical hardware interfaces (Wi-Fi/Ethernet) and only those that are currently Up.
  ; We still return the interface Alias (Name) since Apply uses -InterfaceAlias.
  Protected out.s = ""
  Protected seen.s = #LF$
  If ExecPowerShell(GetAdapterListPowerShell(#True))
    out = gLastPowerShellOutput
  EndIf
  Protected i, line.s, n = CountString(out, #CRLF$) + 1
  For i = 1 To n
    line = Trim(StringField(out, i, #CRLF$))
    If line <> ""
      If FindString(seen, #LF$ + LCase(line) + #LF$, 1) = 0
        AddGadgetItem(combo, -1, line)
        seen + LCase(line) + #LF$
      EndIf
    EndIf
  Next
  ; Fallback: if nothing is Up (e.g., disconnected Ethernet), show physical adapters regardless of status.
  If CountGadgetItems(combo) = 0
    out = ""
    If ExecPowerShell(GetAdapterListPowerShell(#False))
      out = gLastPowerShellOutput
      n = CountString(out, #CRLF$) + 1
      For i = 1 To n
        line = Trim(StringField(out, i, #CRLF$))
        If line <> ""
          If FindString(seen, #LF$ + LCase(line) + #LF$, 1) = 0
            AddGadgetItem(combo, -1, line)
            seen + LCase(line) + #LF$
          EndIf
        EndIf
      Next
    EndIf
  EndIf
  If CountGadgetItems(combo) > 0
    Protected selectedIndex = -1
    If gPreferredAdapter <> ""
      For i = 0 To CountGadgetItems(combo) - 1
        If GetGadgetItemText(combo, i) = gPreferredAdapter
          selectedIndex = i
          Break
        EndIf
      Next
    EndIf

    If selectedIndex >= 0
      SetGadgetState(combo, selectedIndex)
    Else
      SetGadgetState(combo, 0)
    EndIf
  EndIf
EndProcedure

Procedure.s GetBestProviderName()
  If ListSize(Results()) = 0 : ProcedureReturn "" : EndIf

  ; find best by score
  Protected bestScore.d = 1e30
  Protected bestProvider.s = ""
  ForEach Results()
    If Results()\score < bestScore
      bestScore = Results()\score
      bestProvider = Results()\provider
    EndIf
  Next

  ProcedureReturn bestProvider
EndProcedure

Procedure.b ApplyBest(adapter.s)
  Protected bestProvider.s = GetBestProviderName()
  If bestProvider = "" : ProcedureReturn #False : EndIf

  ProcedureReturn ApplyProviderByName(bestProvider, adapter)
EndProcedure

; ----------------------------
; UI
; ----------------------------

gMutex = CreateMutex()

; Providers (IPv4)

Define providersPath.s = ResolveProvidersFile()
gProvidersFile = providersPath
gLoadedProviders = LoadProvidersFromJsonFile(providersPath)

If gLoadedProviders > 0
  gLoadedProviders = ListSize(Providers())
EndIf

gProvidersFromFile = Bool(gLoadedProviders > 0)
If gLoadedProviders = 0
  LogLine("Using built-in default DNS providers")
  AddProvider("Cloudflare",    "1.1.1.1",         "1.0.0.1")
  AddProvider("Google",        "8.8.8.8",         "8.8.4.4")
  AddProvider("Quad9",         "9.9.9.9",         "149.112.112.112")
  AddProvider("OpenDNS",       "208.67.222.222",  "208.67.220.220")
  AddProvider("AdGuard",       "94.140.14.14",    "94.140.15.15")
  AddProvider("CleanBrowsing", "185.228.168.9",   "185.228.169.9")
  AddProvider("Neustar",       "64.6.64.6",       "64.6.65.6")
  AddProvider("Level3",        "4.2.2.1",         "4.2.2.2")
EndIf

SettingsPath = ResolveSettingsPath()
LoadSettings()
LogLine("Settings: " + SettingsPath)

LogLine("Provider source: " + gProvidersFile)
LogLine("Provider count: " + Str(ListSize(Providers())))

  If OpenWindow(#WinMain, 0, 0, 920, 560, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered |
                                                                                         #PB_Window_MinimizeGadget | #PB_Window_Invisible)

  TextGadget(#PB_Any, 14, 14, 70, 20, "Adapter:")
  ComboBoxGadget(#G_AdapterCombo, 80, 10, 280, 26)
  ButtonGadget(#G_ReloadAdapters, 370, 10, 90, 26, "Reload")

  TextGadget(#PB_Any, 480, 14, 40, 20, "Tries:")
  SpinGadget(#G_TriesSpin, 525, 10, 60, 26, 1, 10, #PB_Spin_Numeric)
  SetGadgetState(#G_TriesSpin, gTries)

  TextGadget(#PB_Any, 595, 14, 88, 20, "Timeout ms:")
  SpinGadget(#G_TimeoutSpin, 680, 10, 70, 26, 100, 5000, #PB_Spin_Numeric)
  SetGadgetState(#G_TimeoutSpin, gTimeoutMs)

  TextGadget(#PB_Any, 760, 14, 68, 20, "Auto s:")
  SpinGadget(#G_AutoStartSpin, 815, 10, 55, 26, 0, 3600, #PB_Spin_Numeric)
  SetGadgetState(#G_AutoStartSpin, gAutoStartDelaySec)

  TextGadget(#PB_Any, 560, 70, 85, 20, "Rescan:")
  ComboBoxGadget(#G_TrayRescanCombo, 608, 66, 70, 26)
  AddGadgetItem(#G_TrayRescanCombo, -1, "2h")
  AddGadgetItem(#G_TrayRescanCombo, -1, "4h")
  AddGadgetItem(#G_TrayRescanCombo, -1, "8h")
  AddGadgetItem(#G_TrayRescanCombo, -1, "12h")
  SetGadgetState(#G_TrayRescanCombo, TrayRescanSelectionFromHours(gTrayRescanHours))

  CheckBoxGadget(#G_StartToTrayCheck, 690, 68, 95, 22, "Start in tray")
  SetGadgetState(#G_StartToTrayCheck, gStartToTray)
  CheckBoxGadget(#G_AutoApplyCheck, 790, 68, 120, 22, "Auto-apply best")
  SetGadgetState(#G_AutoApplyCheck, gAutoApplyAfterBenchmark)

  ButtonGadget(#G_Start, 14, 66, 60, 26, "Test")
  ButtonGadget(#G_Stop, 79, 66, 60, 26, "Stop")

  ProgressBarGadget(#G_Progress, 14, 44, 891, 18, 0, 100)
  TextGadget(#G_BestLabel, 150, 70, 395, 22, "Best: (none)")
  ButtonGadget(#G_Apply, 790, 96, 75, 26, "Apply Best")
  ButtonGadget(#G_Exit, 870, 96, 40, 26, "Exit")

  ListIconGadget(#G_List, 14, 130, 891, 367, "Rank", 55, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(#G_List, 1, "Provider", 150)
  AddGadgetColumn(#G_List, 2, "Server", 155)
  AddGadgetColumn(#G_List, 3, "Success", 90)
  AddGadgetColumn(#G_List, 4, "Median (ms)", 100)
  AddGadgetColumn(#G_List, 5, "P90 (ms)", 90)
  AddGadgetColumn(#G_List, 6, "Best (ms)", 90)

  TextGadget(#G_Status, 14, 510, 891, 20, "Ready. Log: " + LogPath)

  LoadAdapters(#G_AdapterCombo)
  LogLine("Adapters loaded: " + Str(CountGadgetItems(#G_AdapterCombo)))

  If gProvidersFromFile
    SetGadgetText(#G_Status, "Loaded " + Str(gLoadedProviders) + " DNS providers from: " + gProvidersFile)
  Else
    SetGadgetText(#G_Status, "Loaded " + Str(gLoadedProviders) + " DNS providers (defaults); expected file: " + gProvidersFile)
  EndIf

  GadgetToolTip(#G_Status, LogPath)

  ; SysTray
  Define hIcon = ExtractIcon_(GetModuleHandle_(0), ProgramFilename(), 0)
  If hIcon
    gTrayIconReady = Bool(AddSysTrayIcon(#SysTray, WindowID(#WinMain), hIcon))
    If gTrayIconReady
      SysTrayIconToolTip(#SysTray, #APP_NAME)
      LogLine("Tray icon created")
    Else
      LogLine("Failed to add tray icon")
    EndIf
  Else
    LogLine("Failed to extract tray icon from executable")
  EndIf

  ; Populate list with initial provider information
  PopulateProviderList(#G_List)

  AddWindowTimer(#WinMain, 1, 100)
  DisableGadget(#G_Stop, #True)
  
  ; Handle command line parameters (e.g., from startup shortcut)
  Define startToTrayNow.b = gStartToTray
  Define cmdIdx.l = 1
  While cmdIdx <= CountProgramParameters()
    If UCase(ProgramParameter(cmdIdx-1)) = "/TRAY"
      startToTrayNow = #True
    EndIf
    cmdIdx + 1
  Wend

  If startToTrayNow And gTrayIconReady
    ShowMainWindow(#False)
  Else
    If startToTrayNow And gTrayIconReady = #False
      LogLine("/TRAY requested but tray icon is unavailable; showing main window instead")
    EndIf
    ShowMainWindow(#True)
  EndIf
  
  Define quitApp = #False

  Repeat
    Define ev = WaitWindowEvent(20)
    
    gTrayRescanHours = TrayRescanHours()

    ; Auto-start benchmark logic (delay in seconds; 0 disables auto-start)
    gAutoStartDelaySec = GetGadgetState(#G_AutoStartSpin)
    If gAutoStartDone = #False And gWorkerRunning = 0 And gAutoStartDelaySec > 0
      If ElapsedMilliseconds() - gStartTime > (gAutoStartDelaySec * 1000)
        ; Check if we have an adapter
        If GetGadgetText(#G_AdapterCombo) <> ""
          ; Mark as done immediately so we don't re-trigger
          gAutoStartDone = #True
          gAutoRunPending = #True
          LogLine("Automatic benchmark triggered after " + Str(gAutoStartDelaySec) + " seconds")
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Start)
          SetGadgetText(#G_Status, "Automatic benchmark triggered (" + Str(gAutoStartDelaySec) + "s timer)...")
        EndIf
      EndIf
    EndIf

    ; Periodic tray-only rescan. This only runs while the app is hidden to tray.
    If gWorkerRunning = 0 And MainWindowVisible() = #False And gTrayRescanHours > 0
      If ElapsedMilliseconds() - gLastTrayRescanTick > (gTrayRescanHours * 60 * 60 * 1000)
        If GetGadgetText(#G_AdapterCombo) <> ""
          gLastTrayRescanTick = ElapsedMilliseconds()
          LogLine("Tray rescan triggered after " + Str(gTrayRescanHours) + " hours")
          SetGadgetText(#G_Status, "Tray rescan triggered (" + Str(gTrayRescanHours) + "h interval)...")
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Start)
        EndIf
      EndIf
    EndIf
    
    If ev = #PB_Event_SysTray
      If EventType() = #PB_EventType_LeftDoubleClick
        ToggleMainWindow()
      ElseIf EventType() = #PB_EventType_RightClick
        UpdateTrayMenu()
        DisplayPopupMenu(0, WindowID(#WinMain))
      EndIf
    EndIf
    
    If ev = #PB_Event_Menu
      Select EventMenu()
        Case #Tray_Show
          ToggleMainWindow()
          
        Case #Tray_StartTest
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Start)

        Case #Tray_OpenLog
          OpenLog()
          
        Case #Tray_ApplyBest
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Apply)
          
        Case #Tray_RunAtStartup
          SetRunAtStartup(Bool(Not IsRunAtStartup()))
          LogLine("Run at startup state changed to: " + Str(IsRunAtStartup()))
          UpdateTrayMenu() ; Refresh menu state immediately

        Case #Tray_StopTest
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Stop)
          
        Case #Tray_Exit
          If ConfirmExit()
            quitApp = #True
          EndIf

        Default
          If EventMenu() >= #Tray_ProviderBase
            Define pIdx = EventMenu() - #Tray_ProviderBase
            LockMutex(gMutex)
            If SelectElement(Providers(), pIdx)
              Define pName.s = Providers()\name
              UnlockMutex(gMutex)
              Define adapter.s = GetGadgetText(#G_AdapterCombo)
              If adapter <> ""
                If ApplyProviderWithFeedback(pName, adapter, "Applying " + pName + " from tray...", pName + " applied.", "Failed to apply " + pName + ".", "Apply DNS")
                  LogLine("Provider applied from tray: " + pName)
                EndIf
              EndIf
            Else
              UnlockMutex(gMutex)
            EndIf
          EndIf
      EndSelect
    EndIf

    If ev = #PB_Event_MinimizeWindow
      ShowMainWindow(#False)
    EndIf

    If ev = #PB_Event_CloseWindow
      ShowMainWindow(#False)
    EndIf

    If ev = #PB_Event_Gadget
      Select EventGadget()
        Case #G_Exit
          If ConfirmExit()
            LogLine("Exit requested from button")
            quitApp = #True
          EndIf

        Case #G_ReloadAdapters
          SyncSettingsFromUi()
          SaveSettings()
          LoadAdapters(#G_AdapterCombo)
          LogLine("Adapters reloaded; count=" + Str(CountGadgetItems(#G_AdapterCombo)))
          SetGadgetText(#G_Status, "Adapters reloaded.")

        Case #G_Start
          SyncSettingsFromUi()
          SaveSettings()
          StartBenchmarkRun()

        Case #G_Stop
          LockMutex(gMutex)
          gWorkerCancelled = 1
          UnlockMutex(gMutex)
          RequestWorkerStop()
          LogLine("Benchmark stop requested")
          SetGadgetText(#G_Status, "Stopping...")
          ; Note: Re-enabling happens in the timer event when gWorkerRunning becomes 0

        Case #G_Apply
          SyncSettingsFromUi()
          SaveSettings()
          Define adapter.s = GetGadgetText(#G_AdapterCombo)
          If adapter = ""
            MessageRequester("Apply Best", "Select an adapter first.")
          Else
            Define bestName.s = FirstResultProviderName()
            ApplyBestWithFeedback(adapter, bestName, "Apply Best")
          EndIf

        Case #G_TriesSpin, #G_TimeoutSpin, #G_AutoStartSpin, #G_TrayRescanCombo, #G_StartToTrayCheck, #G_AutoApplyCheck, #G_AdapterCombo
          SyncSettingsFromUi()
          SaveSettings()
      EndSelect
    EndIf

    If ev = #PB_Event_Timer
      DrainQueueAndUpdateUI(#G_List, #G_BestLabel)
      LockMutex(gMutex)
      Define running = gWorkerRunning
      Define done = gWorkerDone
      Define wasCancelled = gWorkerCancelled
      Define stepsDone = gWorkerStepsDone
      Define totalSteps = gWorkerTotalSteps
      UnlockMutex(gMutex)
      
      If running
        LockMutex(gMutex)
        If gCurrentTest <> ""
          SetGadgetText(#G_Status, gCurrentTest)
        EndIf
        UnlockMutex(gMutex)
      EndIf

      If totalSteps > 0
        Define pct = Int((stepsDone * 100.0) / totalSteps)
        SetGadgetState(#G_Progress, pct)
        If running
          SysTrayIconToolTip(#SysTray, #APP_NAME + " - Testing... " + Str(pct) + "%")
        EndIf
      Else
        SetGadgetState(#G_Progress, 0)
      EndIf

      If done And running = 0
        FinishBenchmarkRun(wasCancelled)

        ; Apply the current best DNS after any successful benchmark run when enabled.
        If gAutoApplyAfterBenchmark And gQueueApplied = #False And wasCancelled = #False
          gQueueApplied = #True
          Define adapter.s = GetGadgetText(#G_AdapterCombo)
          AutoApplyBestProvider(adapter)
        EndIf
      EndIf
    EndIf

  Until quitApp = #True
    SyncSettingsFromUi()
    SaveSettings()
    RequestWorkerStop()
    WaitForWorkerStop(#WORKER_EXIT_WAIT_MS)
    CloseHandle_(hMutex)
    CloseLogging()
    End
EndIf
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 18
; Folding = -----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_DNSJumper.ico
; Executable = ..\PB_DNSJumper.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,8
; VersionField1 = 1,0,0,8
; VersionField2 = ZoneSoft
; VersionField3 = PB_DNSJumper
; VersionField4 = 1.0.0.8
; VersionField5 = 1.0.0.8
; VersionField6 = An automatic DNS changer similar to DNSJumper
; VersionField7 = PB_DNSJumper
; VersionField8 = PB_DNSJumper.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60