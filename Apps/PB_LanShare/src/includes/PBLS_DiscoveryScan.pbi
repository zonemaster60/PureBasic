; LAN scanning, discovery result collection, and remembered/live peer updates.

Procedure AddDiscoveryHost(Host$, Port.i, Name$, Share$)
  If Host$ = ""
    ProcedureReturn
  EndIf

  If FindMapElement(Discovery(), Host$) = 0
    AddMapElement(Discovery(), Host$)
    Discovery()\Host = Host$
  EndIf

  Discovery()\Port = Port
  Discovery()\Name = Name$
  Discovery()\Share = Share$
  Discovery()\LastSeen = Date()
  Discovery()\DeviceType = "Ready to receive"
  Discovery()\IsLanShare = #True
  Discovery()\State = "(live)"
  RefreshDiscoveryList()
EndProcedure

Procedure AddInventoryHost(Host$, Port.i, Name$, DeviceType$, MacAddress$, Vendor$)
  If Host$ = ""
    ProcedureReturn
  EndIf

  If FindMapElement(Discovery(), Host$) = 0
    AddMapElement(Discovery(), Host$)
    Discovery()\Host = Host$
  EndIf

  If Discovery()\IsLanShare = 0
    Discovery()\Port = Port
    Discovery()\Name = Name$
    Discovery()\Share = ""
    Discovery()\LastSeen = Date()
    Discovery()\DeviceType = DeviceType$
    Discovery()\MacAddress = MacAddress$
    Discovery()\Vendor = Vendor$
    Discovery()\State = ""
  EndIf
  RefreshDiscoveryList()
EndProcedure

Procedure QueueDiscoveryResult(Host$, Port.i, Name$, Share$)
  If ScanMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ScanMutex)
  AddElement(DiscoveryResults())
  DiscoveryResults()\Host = Host$
  DiscoveryResults()\Port = Port
  DiscoveryResults()\Name = Name$
  DiscoveryResults()\Share = Share$
  DiscoveryResults()\LastSeen = Date()
  DiscoveryResults()\DeviceType = "PB_LanShare"
  DiscoveryResults()\IsLanShare = #True
  UnlockMutex(ScanMutex)
EndProcedure

Procedure QueueInventoryResult(Host$, Port.i, Name$, DeviceType$, MacAddress$, Vendor$)
  If ScanMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ScanMutex)
  AddElement(DiscoveryResults())
  DiscoveryResults()\Host = Host$
  DiscoveryResults()\Port = Port
  DiscoveryResults()\Name = Name$
  DiscoveryResults()\Share = ""
  DiscoveryResults()\LastSeen = Date()
  DiscoveryResults()\DeviceType = DeviceType$
  DiscoveryResults()\IsLanShare = #False
  DiscoveryResults()\MacAddress = MacAddress$
  DiscoveryResults()\Vendor = Vendor$
  UnlockMutex(ScanMutex)
EndProcedure

Procedure FlushDiscoveryResults()
  If ScanMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ScanMutex)
  While FirstElement(DiscoveryResults())
    If DiscoveryResults()\IsLanShare
      AddDiscoveryHost(DiscoveryResults()\Host, DiscoveryResults()\Port, DiscoveryResults()\Name, DiscoveryResults()\Share)
    Else
      AddInventoryHost(DiscoveryResults()\Host, DiscoveryResults()\Port, DiscoveryResults()\Name, DiscoveryResults()\DeviceType, DiscoveryResults()\MacAddress, DiscoveryResults()\Vendor)
    EndIf
    DeleteElement(DiscoveryResults())
  Wend
  UnlockMutex(ScanMutex)
EndProcedure

Procedure ClearDiscoveryPeers()
  Protected Found.i

  Repeat
    Found = #False
    ForEach Peers()
      If Peers()\IsDiscovery
        CloseNetworkConnection(Peers()\Connection)
        FreePeerResources(@Peers())
        DeleteMapElement(Peers())
        Found = #True
        Break
      EndIf
    Next
  Until Found = #False
EndProcedure

Procedure DiscoverFromHost(Host$, Port.i)
  Protected Connection.i
  Protected PayloadLength.i
  Protected *Buffer
  Protected Received.i
  Protected Magic.i
  Protected FrameType.i
  Protected Payload$
  Protected PeerName$
  Protected ShareName$
  Protected WaitCount.i

  If Host$ = "" Or Host$ = "127.0.0.1"
    ProcedureReturn
  EndIf

  Connection = OpenNetworkConnection(Host$, Port, #PB_Network_TCP, #DiscoveryTimeout)
  If Connection
    SendTextFrame(Connection, #FrameHello, BuildHelloPayload())
    *Buffer = AllocateMemory(4096)
    If *Buffer
      Repeat
        Delay(#DiscoveryWaitStep)
        Received = ReceiveNetworkData(Connection, *Buffer, 4096)
        WaitCount + 1
      Until Received > 0 Or WaitCount >= #DiscoveryWaitLoops Or ScanCancel
      If Received >= 16
        Magic = PeekL(*Buffer)
        FrameType = PeekL(*Buffer + 4)
        PayloadLength = PeekQ(*Buffer + 8)
        If Magic = #ProtocolMagic And FrameType = #FrameHello And PayloadLength > 0 And PayloadLength <= Received - 16
          Payload$ = PayloadToString(*Buffer + 16, PayloadLength)
          PeerName$ = StringField(Payload$, 1, Chr(31))
          ShareName$ = StringField(Payload$, 2, Chr(31))
          QueueDiscoveryResult(Host$, Port, PeerName$, ShareName$)
        EndIf
      EndIf
      FreeMemory(*Buffer)
    EndIf
    CloseNetworkConnection(Connection)
  EndIf
EndProcedure

Procedure ProbeInventoryHost(Host$, Port.i)
  Protected Program.i
  Protected Output$
  Protected Name$
  Protected MacAddress$
  Protected Vendor$

  If Host$ = "" Or IsSafeHostToken(Host$) = 0
    ProcedureReturn
  EndIf

  Program = RunProgram("cmd", "/c ping -n 1 -w 120 " + Host$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If Program
    While ProgramRunning(Program)
      Delay(5)
      While AvailableProgramOutput(Program)
        Output$ + ReadProgramString(Program) + Chr(10)
      Wend
    Wend
    While AvailableProgramOutput(Program)
      Output$ + ReadProgramString(Program) + Chr(10)
    Wend
    CloseProgram(Program)

    If FindString(LCase(Output$), "ttl=", 1) Or FindString(LCase(Output$), "bytes=", 1)
      Name$ = ResolveHostName(Host$)
      MacAddress$ = ResolveMacAddress(Host$)
      Vendor$ = ResolveVendor(MacAddress$)
      QueueInventoryResult(Host$, Port, Name$, "Reachable host", MacAddress$, Vendor$)
    EndIf
  EndIf
EndProcedure

Procedure BuildScanTargets()
  Protected IP.i
  Protected Current$
  Protected Prefix$
  Protected Index.i
  Protected Added.i
  Protected NewHost$
  Protected Existing.i

  ClearList(ScanTargets())
  If ExamineIPAddresses()
    Repeat
      IP = NextIPAddress()
      If IP
        Current$ = IPString(IP)
        Prefix$ = StringField(Current$, 1, ".") + "." + StringField(Current$, 2, ".") + "." + StringField(Current$, 3, ".") + "."
        For Index = 1 To 254
          NewHost$ = Prefix$ + Str(Index)
          If NewHost$ <> Current$
            Existing = #False
            ForEach ScanTargets()
              If ScanTargets() = NewHost$
                Existing = #True
                Break
              EndIf
            Next
            If Existing = #False
              AddElement(ScanTargets())
              ScanTargets() = NewHost$
              Added + 1
            EndIf
          EndIf
        Next
      EndIf
    Until IP = 0
  EndIf

  If Added = 0
    AddElement(ScanTargets())
    ScanTargets() = "127.0.0.1"
  EndIf
EndProcedure

Procedure ContinueDiscoveryScan()
  FlushDiscoveryResults()

  If ScanActive And ScanWorkerRunning = 0
    ScanActive = 0
    AddLog("Receiver search finished. Found " + Str(MapSize(Discovery())) + " known device(s).")
    SetGadgetText(#GadgetScan, "Find Receivers")
  EndIf
EndProcedure

Procedure StartDiscoveryScan()
  Protected Port.i = Val(GetGadgetText(#GadgetPort))
  Protected Index.i

  If ScanActive
    ScanCancel = #True
    AddLog("Stopping receiver search...")
    SetGadgetText(#GadgetScan, "Find Receivers")
    ProcedureReturn
  EndIf

  ClearDiscoveryPeers()
  ForEach Discovery()
    If Discovery()\IsLanShare
      Discovery()\State = "(remembered)"
    EndIf
  Next
  RefreshDiscoveryList()
  BuildScanTargets()
  ClearList(DiscoveryResults())
  ScanCancel = #False
  ScanActive = #True
  ScanWorkerRunning = #DiscoveryWorkers
  ScanThreadCount = #DiscoveryWorkers
  SetGadgetText(#GadgetScan, "Stop Search")
  For Index = 0 To #DiscoveryWorkers - 1
    ScanThreadID(Index) = CreateThread(@DiscoveryScanThread(), Port)
  Next
  AddLog("Searching local network for receivers on port " + Str(Port) + "...")
  AddLog("Reachable devices are listed as generic hosts; PB_LanShare peers are tagged separately.")
EndProcedure

Procedure DiscoveryScanThread(*Value)
  Protected Port.i = *Value
  Protected Host$

  While ScanCancel = 0
    LockMutex(ScanMutex)
    If ListSize(ScanTargets()) > 0
      FirstElement(ScanTargets())
      Host$ = ScanTargets()
      DeleteElement(ScanTargets())
    Else
      Host$ = ""
    EndIf
    UnlockMutex(ScanMutex)

    If Host$ = ""
      Break
    EndIf

    ProbeInventoryHost(Host$, Port)
    DiscoverFromHost(Host$, Port)
  Wend

  LockMutex(ScanMutex)
  ScanWorkerRunning - 1
  UnlockMutex(ScanMutex)
EndProcedure
