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

#APP_NAME        = "PB_DNSJumperLike"
#EMAIL_NAME      = "zonemaster60@gmail.com"

Enumeration SysTray
  #SysTray
EndEnumeration

Enumeration MenuItems
  #Tray_Show
  #Tray_StartTest
  #Tray_ApplyBest
  #Tray_RunAtStartup
  #Tray_Exit
  #Tray_ProviderBase = 1000
EndEnumeration

Enumeration Gadgets
  #G_AdapterCombo
  #G_ReloadAdapters
  #G_TriesSpin
  #G_TimeoutSpin
  #G_Start
  #G_Stop
  #G_Apply
  #G_Progress
  #G_BestLabel
  #G_List
  #G_Status
  #G_Exit
EndEnumeration

Global version.s = "v1.0.0.0"

Global AppPath.s = GetPathPart(ProgramFilename())
If AppPath = "" : AppPath = GetCurrentDirectory() : EndIf
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    ; If already running, just exit silently instead of showing a message box
    ; This is better for startup/background apps
    CloseHandle_(hMutex)
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
  program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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
  Protected args.s = "/Query /TN " + #DQUOTE$ + #APP_NAME + #DQUOTE$
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", args) = 0)
EndProcedure

Procedure.i SetRunAtStartup(state.b)
  Protected taskName.s = #APP_NAME
  Protected exePath.s = ProgramFilename()
  Protected workDir.s = GetPathPart(exePath)
  Protected userSam.s = CurrentUserSam()
  
  If state
    ; Register-ScheduledTask via PowerShell for maximum reliability (bypass registry hurdles)
    Protected psCmd.s = "Register-ScheduledTask -TaskName '" + ReplaceString(taskName, "'", "''") + "' " +
                        "-Action (New-ScheduledTaskAction -Execute '" + ReplaceString(exePath, "'", "''") + "' -WorkingDirectory '" + ReplaceString(workDir, "'", "''") + "' -Argument '/TRAY') " +
                        "-Trigger (New-ScheduledTaskTrigger -AtLogOn -User '" + ReplaceString(userSam, "'", "''") + "') " +
                        "-Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) " +
                        "-Principal (New-ScheduledTaskPrincipal -UserId '" + ReplaceString(userSam, "'", "''") + "' -LogonType Interactive -RunLevel Highest) -Force"
    
    Protected args.s = "-NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + psCmd + #DQUOTE$
    ProcedureReturn Bool(RunAndCapture("powershell.exe", args) = 0)
  Else
    Protected delArgs.s = "/Delete /F /TN " + #DQUOTE$ + taskName + #DQUOTE$
    ProcedureReturn Bool(RunAndCapture("schtasks.exe", delArgs) = 0)
  EndIf
EndProcedure


; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
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

; QuoteArg(): Wraps a string in double quotes if it contains spaces.
Procedure.s QuoteArg(s.s)
  If FindString(s, " ")
    ProcedureReturn #DQUOTE$ + s + #DQUOTE$
  EndIf
  ProcedureReturn s
EndProcedure

; ExecPowerShell(): Executes a PowerShell command and returns its UTF-8 output.
Procedure.s ExecPowerShell(cmd.s)
  Protected psCmd.s
  ; Force UTF-8 output so ReadProgramString(#PB_UTF8) works reliably.
  psCmd = "[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new(); $OutputEncoding=[System.Text.UTF8Encoding]::new(); " + cmd

  Protected out.s = ""
  Protected p = RunProgram("powershell.exe",
                           "-NoLogo -NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + psCmd + #DQUOTE$,
                           "",
                           #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If p
    While ProgramRunning(p)
      If AvailableProgramOutput(p)
        out + ReadProgramString(p, #PB_UTF8) + #CRLF$
      Else
        Delay(1)
      EndIf
    Wend
    ; Drain remaining output
    While AvailableProgramOutput(p)
      out + ReadProgramString(p, #PB_UTF8) + #CRLF$
    Wend
    CloseProgram(p)
  EndIf
  ProcedureReturn out
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
  Protected pExe.s = GetPathPart(ProgramFilename()) + #APP_NAME + "_servers.json"
  Protected pCwd.s = GetCurrentDirectory() + #APP_NAME + "_servers.json"
  Protected pSrc.s = #PB_Compiler_FilePath + #APP_NAME + "_servers.json"

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

Procedure.d DnsRTTms(serverIP.s, domain.s, timeoutMs.l, *stopFlag.Long)
  ; Returns RTT (ms) or -1 on failure/stop.
  If *stopFlag And *stopFlag\l <> 0
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

  If *stopFlag And *stopFlag\l <> 0
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

Global gMutex.i
Global NewList gQueue.BenchResult()
Global gStopFlag.l
Global gWorkerRunning.l
Global gWorkerDone.l
Global gWorkerTotalSteps.l
Global gWorkerStepsDone.l

Global gTries.l = 3
Global gTimeoutMs.l = 800
Global gDomains.s = "example.com|cloudflare.com|google.com|wikipedia.org|github.com"
Global gProvidersFile.s = "dns_servers.json"
Global gLoadedProviders.i
Global gProvidersFromFile.l
Global gCurrentTest.s

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

  If json = 0 : ProcedureReturn 0 : EndIf

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
  ProcedureReturn count

EndProcedure

Procedure.d MedianFromArray(Array a.d(1), n.l)
  If n <= 0 : ProcedureReturn 1e30 : EndIf
  SortArray(a(), #PB_Sort_Ascending)
  If (n % 2) = 1
    ProcedureReturn a(n/2)
  Else
    ProcedureReturn (a(n/2 - 1) + a(n/2)) / 2.0
  EndIf
EndProcedure

Procedure.d P90FromArray(Array a.d(1), n.l)
  If n <= 0 : ProcedureReturn 1e30 : EndIf
  SortArray(a(), #PB_Sort_Ascending)
  Protected k.d = (n - 1) * 0.90
  Protected f.l = Int(k)
  Protected c.l = f + 1
  If c >= n : c = n - 1 : EndIf
  If f = c : ProcedureReturn a(f) : EndIf
  ProcedureReturn a(f) + (a(c) - a(f)) * (k - f)
EndProcedure

Procedure BenchOne(providerName.s, ip.s, tries.l, timeoutMs.l, domains.s, *stopFlag.Long)
  Protected domainCount = CountString(domains, "|") + 1
  Protected total.l = tries * domainCount
  Protected ok.l = 0

  Dim samples.d(total - 1)
  Protected si.l = 0

  Protected pass, i, d.s
  For pass = 1 To tries
    For i = 1 To domainCount
      If *stopFlag And *stopFlag\l <> 0
        ProcedureReturn
      EndIf
      d = StringField(domains, i, "|")
      Protected rtt.d = DnsRTTms(ip, d, timeoutMs, *stopFlag)
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
    med = MedianFromArray(samples(), ok)
    p90 = P90FromArray(samples(), ok)
    SortArray(samples(), #PB_Sort_Ascending)
    best = samples(0)
  Else
    med = 1e30 : p90 = 1e30 : best = 1e30
  EndIf

  Protected success.d = ok / (total * 1.0)
  Protected score.d = (1.0 - success) * 10000.0 + med

  LockMutex(gMutex)
  AddElement(gQueue())
  gQueue()\provider = providerName
  gQueue()\ip = ip
  gQueue()\ok = ok
  gQueue()\total = total
  gQueue()\median = med
  gQueue()\p90 = p90
  gQueue()\best = best
  gQueue()\score = score
  UnlockMutex(gMutex)
EndProcedure

Procedure WorkerThread(*dummy)

  Protected wsa.DNSJ_WSAData
  If WSAStartup($0202, @wsa) <> 0
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
  
  ForEach Providers()
    AddElement(localProviders())
    localProviders() = Providers()
  Next

  UnlockMutex(gMutex)

  ForEach localProviders()
    If gStopFlag <> 0 : Break : EndIf
    LockMutex(gMutex)
    gCurrentTest = "Testing: " + localProviders()\name + "  " + localProviders()\ip1
    UnlockMutex(gMutex)
    BenchOne(localProviders()\name, localProviders()\ip1, gTries, gTimeoutMs, gDomains, @gStopFlag)

    If gStopFlag <> 0 : Break : EndIf
    LockMutex(gMutex)
    gCurrentTest = "Testing: " + localProviders()\name + "  " + localProviders()\ip2
    UnlockMutex(gMutex)
    BenchOne(localProviders()\name, localProviders()\ip2, gTries, gTimeoutMs, gDomains, @gStopFlag)
  Next

  WSACleanup()
  LockMutex(gMutex)
  gWorkerDone = 1
  gWorkerRunning = 0
  gCurrentTest = ""
  UnlockMutex(gMutex)

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

Procedure ApplyProviderByName(name.s, adapter.s)
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

  If dns1 <> "" And dns2 <> ""
    Protected psCmd.s = "Set-DnsClientServerAddress -InterfaceAlias " + QuotePS(adapter) + " -ServerAddresses @(" + QuotePS(dns1) + "," + QuotePS(dns2) + "); Register-DnsClient"
    ExecPowerShell(psCmd)
  EndIf
EndProcedure

Procedure.b IsRunAtStartup()
  ProcedureReturn IsInStartup()
EndProcedure

Procedure UpdateTrayMenu()
  If CreatePopupMenu(0)
    MenuItem(#Tray_Show, "Show / Hide GUI")
    MenuBar()
    
    MenuItem(#Tray_RunAtStartup, "Run at Startup")
    If IsRunAtStartup()
      SetMenuItemState(0, #Tray_RunAtStartup, #True)
    EndIf
    MenuBar()

    LockMutex(gMutex)
    Protected isRunning = gWorkerRunning
    If isRunning
      MenuItem(#G_Stop, "Stop Testing")
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

Procedure LoadAdapters(combo.i)
  ClearGadgetItems(combo)
  ; Prefer physical hardware interfaces (Wi-Fi/Ethernet) and only those that are currently Up.
  ; We still return the interface Alias (Name) since Apply uses -InterfaceAlias.
  Protected out.s = ExecPowerShell("Get-NetAdapter | Where-Object { $_.HardwareInterface -eq $true -and $_.Status -eq 'Up' } | Select-Object -ExpandProperty Name | Sort-Object -Unique")
  Protected i, line.s, n = CountString(out, #CRLF$) + 1
  For i = 1 To n
    line = Trim(StringField(out, i, #CRLF$))
    If line <> ""
      AddGadgetItem(combo, -1, line)
    EndIf
  Next
  ; Fallback: if nothing is Up (e.g., disconnected Ethernet), show physical adapters regardless of status.
  If CountGadgetItems(combo) = 0
    out = ExecPowerShell("Get-NetAdapter | Where-Object { $_.HardwareInterface -eq $true } | Select-Object -ExpandProperty Name | Sort-Object -Unique")
    n = CountString(out, #CRLF$) + 1
    For i = 1 To n
      line = Trim(StringField(out, i, #CRLF$))
      If line <> ""
        AddGadgetItem(combo, -1, line)
      EndIf
    Next
  EndIf
  If CountGadgetItems(combo) > 0
    SetGadgetState(combo, 0)
  EndIf
EndProcedure

Procedure ApplyBest(adapter.s)
  ; apply best provider pair using PowerShell
  If ListSize(Results()) = 0 : ProcedureReturn : EndIf

  ; find best by score
  Protected bestScore.d = 1e30
  Protected bestProvider.s = ""
  ForEach Results()
    If Results()\score < bestScore
      bestScore = Results()\score
      bestProvider = Results()\provider
    EndIf
  Next

  If bestProvider = "" : ProcedureReturn : EndIf

  Protected dns1.s = ""
  Protected dns2.s = ""
  LockMutex(gMutex)
  ForEach Providers()
    If Providers()\name = bestProvider
      dns1 = Providers()\ip1
      dns2 = Providers()\ip2
      Break
    EndIf
  Next
  UnlockMutex(gMutex)

  If dns1 = "" Or dns2 = "" : ProcedureReturn : EndIf

  ; Using -PassThru and Register-DnsClient to force Windows to acknowledge the change immediately
  Protected psCmd.s = "Set-DnsClientServerAddress -InterfaceAlias " + QuotePS(adapter) + " -ServerAddresses @(" + QuotePS(dns1) + "," + QuotePS(dns2) + "); Register-DnsClient"
  ExecPowerShell(psCmd)
EndProcedure

; ----------------------------
; UI
; ----------------------------

Enumeration Windows
  #WinMain
EndEnumeration


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
  AddProvider("Cloudflare",    "1.1.1.1",         "1.0.0.1")
  AddProvider("Google",        "8.8.8.8",         "8.8.4.4")
  AddProvider("Quad9",         "9.9.9.9",         "149.112.112.112")
  AddProvider("OpenDNS",       "208.67.222.222",  "208.67.220.220")
  AddProvider("AdGuard",       "94.140.14.14",    "94.140.15.15")
  AddProvider("CleanBrowsing", "185.228.168.9",   "185.228.169.9")
  AddProvider("Neustar",       "64.6.64.6",       "64.6.65.6")
  AddProvider("Level3",        "4.2.2.1",         "4.2.2.2")
EndIf


  If OpenWindow(#WinMain, 0, 0, 920, 560, #APP_NAME + version + " - Windows 11", #PB_Window_SystemMenu | #PB_Window_ScreenCentered |
                                                                                         #PB_Window_MinimizeGadget | #PB_Window_Invisible)

  TextGadget(#PB_Any, 14, 14, 70, 20, "Adapter:")
  ComboBoxGadget(#G_AdapterCombo, 80, 10, 280, 26)
  ButtonGadget(#G_ReloadAdapters, 370, 10, 90, 26, "Reload")

  TextGadget(#PB_Any, 480, 14, 40, 20, "Tries:")
  SpinGadget(#G_TriesSpin, 525, 10, 60, 26, 1, 10, #PB_Spin_Numeric)
  SetGadgetState(#G_TriesSpin, gTries)

  TextGadget(#PB_Any, 600, 14, 88, 20, "Timeout ms:")
  SpinGadget(#G_TimeoutSpin, 688, 10, 80, 26, 100, 5000, #PB_Spin_Numeric)
  SetGadgetState(#G_TimeoutSpin, gTimeoutMs)

  ButtonGadget(#G_Start, 780, 10, 60, 26, "Test")
  ButtonGadget(#G_Stop, 845, 10, 60, 26, "Stop")

  ProgressBarGadget(#G_Progress, 14, 44, 891, 18, 0, 100)
  TextGadget(#G_BestLabel, 14, 70, 650, 22, "Best: (none)")
  ButtonGadget(#G_Apply, 780, 66, 75, 26, "Apply Best")
  ButtonGadget(#G_Exit, 865, 66, 40, 26, "Exit")


  ListIconGadget(#G_List, 14, 102, 891, 395, "Rank", 55, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  AddGadgetColumn(#G_List, 1, "Provider", 150)
  AddGadgetColumn(#G_List, 2, "Server", 155)
  AddGadgetColumn(#G_List, 3, "Success", 90)
  AddGadgetColumn(#G_List, 4, "Median (ms)", 100)
  AddGadgetColumn(#G_List, 5, "P90 (ms)", 90)
  AddGadgetColumn(#G_List, 6, "Best (ms)", 90)

  TextGadget(#G_Status, 14, 510, 891, 20, "Ready.")

  LoadAdapters(#G_AdapterCombo)

  If gProvidersFromFile
    SetGadgetText(#G_Status, "Loaded " + Str(gLoadedProviders) + " DNS providers from: " + gProvidersFile)
  Else
    SetGadgetText(#G_Status, "Loaded " + Str(gLoadedProviders) + " DNS providers (defaults); expected file: " + gProvidersFile)
  EndIf

  ; SysTray
  Define hIcon = ExtractIcon_(GetModuleHandle_(0), ProgramFilename(), 0)
  If hIcon
    AddSysTrayIcon(#SysTray, WindowID(#WinMain), hIcon)
    SysTrayIconToolTip(#SysTray, #APP_NAME)
  EndIf

  ; Populate list with initial provider information

  ForEach Providers()
    Define itemLine.s = "" + Chr(10) + Providers()\name + Chr(10) + Providers()\ip1 + " / " + Providers()\ip2 + Chr(10) + "0%" + Chr(10) + "-" + Chr(10) + "-" + Chr(10) + "-"
    AddGadgetItem(#G_List, -1, itemLine)
  Next

  AddWindowTimer(#WinMain, 1, 100)
  DisableGadget(#G_Stop, #True)
  
  ; Handle command line parameters (e.g., from startup shortcut)
  Define startToTray.b = #False
  Define cmdIdx.l = 1
  While cmdIdx <= CountProgramParameters()
    If UCase(ProgramParameter(cmdIdx-1)) = "/TRAY"
      startToTray = #True
    EndIf
    cmdIdx + 1
  Wend

  If startToTray
    HideWindow(#WinMain, #True)
  Else
    HideWindow(#WinMain, #False)
  EndIf
  
  Define quitApp = #False

  Repeat
    Define ev = WaitWindowEvent(20)
    
    If ev = #PB_Event_SysTray
      If EventType() = #PB_EventType_LeftDoubleClick
        If IsWindowVisible_(WindowID(#WinMain)) And GetWindowState(#WinMain) <> #PB_Window_Minimize
          HideWindow(#WinMain, #True)
        Else
          HideWindow(#WinMain, #False)
          SetWindowState(#WinMain, #PB_Window_Normal)
          SetForegroundWindow_(WindowID(#WinMain))
        EndIf
      ElseIf EventType() = #PB_EventType_RightClick
        UpdateTrayMenu()
        DisplayPopupMenu(0, WindowID(#WinMain))
      EndIf
    EndIf
    
    If ev = #PB_Event_Menu
      Select EventMenu()
        Case #Tray_Show
          If IsWindowVisible_(WindowID(#WinMain)) And GetWindowState(#WinMain) <> #PB_Window_Minimize
            HideWindow(#WinMain, #True)
          Else
            HideWindow(#WinMain, #False)
            SetWindowState(#WinMain, #PB_Window_Normal)
            SetForegroundWindow_(WindowID(#WinMain))
          EndIf
          
        Case #Tray_StartTest
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Start)
          
        Case #Tray_ApplyBest
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Apply)
          
        Case #Tray_RunAtStartup
          SetRunAtStartup(Bool(Not IsRunAtStartup()))
          UpdateTrayMenu() ; Refresh menu state immediately

          
        Case #Tray_Exit
          If MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
            quitApp = #True
          EndIf
          
        Case #G_Stop
          PostEvent(#PB_Event_Gadget, #WinMain, #G_Stop)
          
        Default
          If EventMenu() >= #Tray_ProviderBase
            Define pIdx = EventMenu() - #Tray_ProviderBase
            LockMutex(gMutex)
            If SelectElement(Providers(), pIdx)
              Define pName.s = Providers()\name
              UnlockMutex(gMutex)
              Define adapter.s = GetGadgetText(#G_AdapterCombo)
              If adapter <> ""
                SetGadgetText(#G_Status, "Applying " + pName + " from tray...")
                ApplyProviderByName(pName, adapter)
                SetGadgetText(#G_Status, pName + " applied.")
              EndIf
            Else
              UnlockMutex(gMutex)
            EndIf
          EndIf
      EndSelect
    EndIf

    If ev = #PB_Event_MinimizeWindow
      HideWindow(#WinMain, #True)
    EndIf

    If ev = #PB_Event_CloseWindow
      HideWindow(#WinMain, #True)
    EndIf

    If ev = #PB_Event_Gadget
      Select EventGadget()
        Case #G_Exit
          If MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
            quitApp = #True
          EndIf

        Case #G_ReloadAdapters
          LoadAdapters(#G_AdapterCombo)
          SetGadgetText(#G_Status, "Adapters reloaded.")

        Case #G_Start
          ClearList(Results())
          ClearGadgetItems(#G_List)
          SetGadgetText(#G_BestLabel, "Best: (running...)")
          SetGadgetText(#G_Status, "Testing DNS servers...")

          gTries = GetGadgetState(#G_TriesSpin)
          gTimeoutMs = GetGadgetState(#G_TimeoutSpin)

          LockMutex(gMutex)
          gStopFlag = 0
          gWorkerRunning = 1
          gWorkerDone = 0
          gWorkerStepsDone = 0
          ; steps = (providers * 2 IPs) * (tries * domains)
          Define domainCount = CountString(gDomains, "|") + 1
          gWorkerTotalSteps = ListSize(Providers()) * 2 * gTries * domainCount
          UnlockMutex(gMutex)

          ; Disable relevant UI elements during testing
          DisableGadget(#G_Start, #True)
          DisableGadget(#G_Stop, #False)
          DisableGadget(#G_Apply, #True)
          DisableGadget(#G_ReloadAdapters, #True)
          DisableGadget(#G_AdapterCombo, #True)
          DisableGadget(#G_TriesSpin, #True)
          DisableGadget(#G_TimeoutSpin, #True)
          DisableGadget(#G_Exit, #True)
          SetGadgetState(#G_Progress, 0)

          CreateThread(@WorkerThread(), 0)

        Case #G_Stop
          LockMutex(gMutex)
          gStopFlag = 1
          UnlockMutex(gMutex)
          SetGadgetText(#G_Status, "Stopping...")
          ; Note: Re-enabling happens in the timer event when gWorkerRunning becomes 0

        Case #G_Apply
          Define adapter.s = GetGadgetText(#G_AdapterCombo)
          If adapter = ""
            MessageRequester("Apply Best", "Select an adapter first.")
          Else
            ; Get current best from Results (first element after RefreshListIcon sorts it)
            Define bestName.s = ""
            LockMutex(gMutex)
            If ListSize(Results()) > 0
              FirstElement(Results())
              bestName = Results()\provider
            EndIf
            UnlockMutex(gMutex)

            If bestName <> ""
              SetGadgetText(#G_Status, "Applying best: " + bestName + " (requires Administrator)...")
              ApplyBest(adapter)
              SetGadgetText(#G_Status, "Best DNS (" + bestName + ") applied. Check status as Administrator.")
            Else
              MessageRequester("Apply Best", "Run the test first to find the best provider.")
            EndIf
          EndIf
      EndSelect
    EndIf

    If ev = #PB_Event_Timer
      DrainQueueAndUpdateUI(#G_List, #G_BestLabel)
      LockMutex(gMutex)
      Define running = gWorkerRunning
      Define done = gWorkerDone
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
        DisableGadget(#G_Start, #False)
        DisableGadget(#G_Stop, #True)
        DisableGadget(#G_Apply, #False)
        DisableGadget(#G_ReloadAdapters, #False)
        DisableGadget(#G_AdapterCombo, #False)
        DisableGadget(#G_TriesSpin, #False)
        DisableGadget(#G_TimeoutSpin, #False)
        DisableGadget(#G_Exit, #False)
        SetGadgetText(#G_Status, "Done. (Apply requires Administrator)")
        
        ; Show notification when benchmark finishes
        SysTrayIconToolTip(#SysTray, #APP_NAME + " - Benchmark Complete")
        
        LockMutex(gMutex)
        gWorkerDone = 0
        UnlockMutex(gMutex)
      EndIf
    EndIf


  Until quitApp = #True
  CloseHandle_(hMutex)
  End
EndIf


; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 15
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_DNSJumperLike.ico
; Executable = ..\PB_DNSJumperLike.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = PB_DNSJumperLike
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = An automatic DNS changer similar to DNSJumper
; VersionField7 = PB_DNSJumperLike
; VersionField8 = PB_DNSJumperLike.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60