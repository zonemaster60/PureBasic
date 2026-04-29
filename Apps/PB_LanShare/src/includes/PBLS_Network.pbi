; Server/client connection lifecycle, polling, and remote session helpers.

Procedure RemovePeer(Connection.i, CloseConnection.i)
  Protected *Peer.PeerState = GetPeer(Connection)
  Protected ReceiveMode.i
  Protected SendMode.i
  Protected ReceivePath$
  Protected ReceiveFinalPath$
  Protected ReceiveDone.q
  Protected ReceiveTotal.q
  Protected SendPath$
  Protected PendingLocalUploadPath$
  Protected AwaitingTransferStatus.i
  Protected AwaitingUploadVerify.i
  Protected WaitingUploadReady.i

  If *Peer = 0
    ProcedureReturn
  EndIf

  ReceiveMode = *Peer\ReceiveMode
  SendMode = *Peer\SendMode
  ReceivePath$ = *Peer\ReceiveRelativePath
  ReceiveFinalPath$ = *Peer\ReceiveFinalPath
  ReceiveDone = *Peer\ReceiveDone
  ReceiveTotal = *Peer\ReceiveTotal
  SendPath$ = *Peer\SendRelativePath
  PendingLocalUploadPath$ = *Peer\PendingLocalUploadPath
  AwaitingTransferStatus = *Peer\AwaitingTransferStatus
  AwaitingUploadVerify = *Peer\AwaitingUploadVerify
  WaitingUploadReady = *Peer\WaitingUploadReady

  If CloseConnection
    CloseNetworkConnection(Connection)
  EndIf

  If ActiveRemoteConnection = Connection
    ActiveRemoteConnection = 0
    ClearBrowser()
    SetGadgetText(#GadgetServerStatus, "Remote connection closed")
  EndIf

  FreePeerResources(*Peer)

  If ReceiveMode <> #TransferNone And ReceiveFinalPath$ <> "" And FileSize(ReceiveFinalPath$) >= 0
    DeleteFile(ReceiveFinalPath$)
  EndIf

  If *Peer\IsOutgoing
    If ReceiveMode = #TransferDownload And ReceivePath$ <> ""
      AddHistory("Failed", "Download", ReceivePath$, "Connection closed before transfer completed")
      HandleDownloadQueueFailure("Download interrupted: " + ReceivePath$)
    ElseIf (SendMode = #TransferUpload Or WaitingUploadReady Or AwaitingUploadVerify Or AwaitingTransferStatus) And (SendPath$ <> "" Or PendingLocalUploadPath$ <> "")
      If SendPath$ = ""
        SendPath$ = GetFilePart(PendingLocalUploadPath$)
      EndIf
      AddHistory("Failed", "Upload", SendPath$, "Connection closed before transfer completed")
      HandleUploadQueueFailure("Upload interrupted: " + SendPath$)
    EndIf
  ElseIf ReceiveMode = #TransferUpload And ReceivePath$ <> ""
    AddHistory("Failed", "Upload", ReceivePath$, "Sender disconnected before transfer completed")
  EndIf

  DeleteMapElement(Peers())
EndProcedure

Procedure UpdateServerStatus()
  Protected Status$

  If ServerRunning
    Status$ = "Ready to receive on port " + GetGadgetText(#GadgetPort)
    SetGadgetText(#GadgetServerToggle, "Stop Server")
  Else
    Status$ = "Ready to receive is offline"
    SetGadgetText(#GadgetServerToggle, "Start Server")
  EndIf

  SetGadgetText(#GadgetServerStatus, Status$)
EndProcedure

Procedure.s LocalIPSummary()
  Protected Summary$
  Protected IP.i

  If ExamineIPAddresses()
    Repeat
      IP = NextIPAddress()
      If IP
        If Summary$ <> ""
          Summary$ + "   "
        EndIf
        Summary$ + IPString(IP)
      EndIf
    Until IP = 0
  EndIf

  If Summary$ = ""
    Summary$ = "No IPv4 addresses detected"
  EndIf

  ProcedureReturn Summary$
EndProcedure

Procedure RefreshLocalIPs()
  SetGadgetText(#GadgetLocalIPs, "This PC: " + HostName$ + " | LAN IPs: " + LocalIPSummary())
EndProcedure

Procedure StartServer()
  Protected Port.i = Val(GetGadgetText(#GadgetPort))
  Protected Conflict$
  Protected AlternatePort.i

  If ServerRunning
    ProcedureReturn
  EndIf

  If Port <= 0
    MessageRequester(#APP_NAME, "Enter a valid TCP port.")
    ProcedureReturn
  EndIf

  SharePath$ = TrimTrailingSlash(GetGadgetText(#GadgetSharePath))
  DownloadPath$ = TrimTrailingSlash(GetGadgetText(#GadgetDownloadPath))
  If SharePath$ = ""
    SharePath$ = DownloadPath$
  EndIf
  If IsUsableTransferDirectory(DownloadPath$) = 0
    MessageRequester(#APP_NAME, "Choose a valid absolute download folder before starting the server.")
    ProcedureReturn
  EndIf

  If IsUsableTransferDirectory(SharePath$) = 0
    MessageRequester(#APP_NAME, "Choose a valid absolute share folder before starting the server.")
    ProcedureReturn
  EndIf

  If IsPortBindable(Port) = 0
    Conflict$ = PortConflictDetails(Port)
    AlternatePort = FindOpenPort(#PortSearchStart, #PortSearchEnd)
    If AlternatePort = 0
      AlternatePort = FindOpenPort(40000, 40100)
    EndIf

    If AlternatePort > 0
      SetGadgetText(#GadgetPort, Str(AlternatePort))
      AddLog("Requested port " + Str(Port) + " is unavailable")
      If Conflict$ <> ""
        AddLog("Port owner: " + Conflict$)
      EndIf
      AddLog("Trying alternate port " + Str(AlternatePort))
      Port = AlternatePort
    Else
      If Conflict$ <> ""
        MessageRequester(#APP_NAME, "Unable to start the server on port " + Str(Port) + ". In use by " + Conflict$ + ".")
      Else
        MessageRequester(#APP_NAME, "Unable to start the server on port " + Str(Port) + ".")
      EndIf
      ProcedureReturn
    EndIf
  EndIf

  ServerID = CreateNetworkServer(#PB_Any, Port)
  If ServerID
    ServerRunning = #True
    AddLog("Server started on port " + Str(Port))
  Else
    Conflict$ = PortConflictDetails(Port)
    If Conflict$ <> ""
      MessageRequester(#APP_NAME, "Unable to start the server on port " + Str(Port) + ". In use by " + Conflict$ + ".")
    Else
      MessageRequester(#APP_NAME, "Unable to start the server on port " + Str(Port) + ".")
    EndIf
  EndIf

  UpdateServerStatus()
EndProcedure

Procedure StopServer()
  If ServerRunning
    CloseNetworkServer(ServerID)
    ServerRunning = #False
    ServerID = 0
    AddLog("Server stopped")
  EndIf
  UpdateServerStatus()
EndProcedure

Procedure ConnectRemote()
  Protected Host$ = Trim(GetGadgetText(#GadgetRemoteHost))
  Protected Port.i = Val(GetGadgetText(#GadgetPort))
  Protected Connection.i
  Protected *Peer.PeerState
  Protected PingOK.i

  If Host$ = ""
    MessageRequester(#APP_NAME, "Enter the remote host or IP address.")
    ProcedureReturn
  EndIf

  If IsSafeHostToken(Host$) = 0
    MessageRequester(#APP_NAME, "Enter a valid host name or IPv4 address.")
    ProcedureReturn
  EndIf

  If ActiveRemoteConnection
    RemovePeer(ActiveRemoteConnection, #True)
  EndIf

  PingOK = HostRespondsToPing(Host$)
  If PingOK = 0
    AddLog("Host did not answer ping: " + Host$)
  EndIf

  Connection = OpenNetworkConnection(Host$, Port, #PB_Network_TCP, 5000)
  If Connection = 0
    If PingOK
      MessageRequester(#APP_NAME, "Could not connect to " + Host$ + ":" + Str(Port) + ". The host is reachable, but PB_LanShare may not be listening on that port.")
    Else
      MessageRequester(#APP_NAME, "Could not connect to " + Host$ + ":" + Str(Port) + ". The host may be offline, on a different network, or blocking the port.")
    EndIf
    ProcedureReturn
  EndIf

  AddMapElement(Peers(), Str(Connection))
  *Peer = @Peers()
  ResetPeerTransferState(*Peer)
  *Peer\Connection = Connection
  *Peer\IsOutgoing = #True
  *Peer\IsDiscovery = #False
  *Peer\PeerHost = Host$
  ActiveRemoteConnection = Connection

  ClearBrowser()
  SendTextFrame(Connection, #FrameHello, BuildHelloPayload())
  RequestRemoteList("")
  AddLog("Connected to selected receiver " + Host$ + ":" + Str(Port))
  UpdateProgressUI()
EndProcedure

Procedure DisconnectRemote()
  If ActiveRemoteConnection
    AddLog("Disconnected remote session")
    RemovePeer(ActiveRemoteConnection, #True)
    ActiveRemoteConnection = 0
    ClearBrowser()
  EndIf
  UpdateProgressUI()
EndProcedure

Procedure HandleIncomingConnections()
  Protected Event.i
  Protected Connection.i
  Protected IP.i
  Protected *Peer.PeerState

  If ServerRunning = 0
    ProcedureReturn
  EndIf

  Repeat
    Event = NetworkServerEvent(ServerID)
    If Event = #PB_NetworkEvent_None
      Break
    EndIf

    Connection = EventClient()
    Select Event
      Case #PB_NetworkEvent_Connect
        AddMapElement(Peers(), Str(Connection))
        *Peer = @Peers()
        ResetPeerTransferState(*Peer)
        *Peer\Connection = Connection
        *Peer\IsOutgoing = #False
        *Peer\IsDiscovery = #False
        IP = GetClientIP(Connection)
        *Peer\PeerHost = IPString(IP)
        SendTextFrame(Connection, #FrameHello, BuildHelloPayload())
        AddLog("Client connected: " + *Peer\PeerHost)

      Case #PB_NetworkEvent_Data
        *Peer = GetPeer(Connection)
        If *Peer
          ReceivePeerData(*Peer)
        EndIf

      Case #PB_NetworkEvent_Disconnect
        AddLog("Client disconnected: " + Str(Connection))
        RemovePeer(Connection, #False)
    EndSelect
  ForEver
EndProcedure

Procedure HandleOutgoingConnectionEvents()
  Protected *Peer.PeerState
  Protected Event.i

  If ActiveRemoteConnection = 0
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ActiveRemoteConnection = 0
    ProcedureReturn
  EndIf

  Repeat
    Event = NetworkClientEvent(*Peer\Connection)
    Select Event
      Case #PB_NetworkEvent_Data
        ReceivePeerData(*Peer)
        *Peer = GetPeer(ActiveRemoteConnection)
        If *Peer = 0
          ActiveRemoteConnection = 0
          Break
        EndIf

      Case #PB_NetworkEvent_Disconnect
        AddLog("Remote host disconnected")
        RemovePeer(*Peer\Connection, #False)
        ActiveRemoteConnection = 0
        Break

      Default
        Break
    EndSelect
  ForEver
EndProcedure

Procedure PumpTransfers()
  ForEach Peers()
    PumpOutgoingTransfer(@Peers())
  Next
EndProcedure

Procedure PollNetwork()
  HandleIncomingConnections()
  HandleOutgoingConnectionEvents()
  If DisconnectAfterUploadQueue And ActiveRemoteConnection
    DisconnectAfterUploadQueue = #False
    DisconnectRemote()
  EndIf
  PumpTransfers()
EndProcedure

Procedure.s ActiveRemotePath()
  Protected *Peer.PeerState

  If ActiveRemoteConnection = 0
    ProcedureReturn ""
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn *Peer\CurrentRemotePath
EndProcedure

Procedure.s SelectedRemoteItemPath()
  Protected Index.i = GetGadgetState(#GadgetRemoteList)

  If Index < 0 Or Index > ArraySize(RemoteEntryPath$())
    ProcedureReturn ""
  EndIf

  ProcedureReturn RemoteEntryPath$(Index)
EndProcedure
