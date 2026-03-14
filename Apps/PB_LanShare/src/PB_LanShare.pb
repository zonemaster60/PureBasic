EnableExplicit

#APP_NAME = "PB_LanShare"
#ProtocolMagic = $4C534831
#ProtocolMaxPayload = 1048576
#ChunkSize = 32768
#InvalidRelativePath = "<invalid>"
#DiscoveryScanBatch = 4
#DiscoveryTimeout = 120
#DiscoveryWaitStep = 10
#DiscoveryWaitLoops = 12
#DiscoveryWorkers = 24
#DefaultPort = 50505
#PortSearchStart = 50505
#PortSearchEnd = 50530

Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

#SettingsFile = "files\PB_LanShare.pref"

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf

Enumeration
  #WindowMain
  #WindowReceiver
  #WindowSettings
EndEnumeration

Enumeration 1
  #TrayMain
EndEnumeration

Enumeration 1
  #MenuTrayShow
  #MenuTrayScan
  #MenuTrayExit
  #MenuQueueUploadUp
  #MenuQueueUploadDown
  #MenuQueueUploadRemove
  #MenuQueueDownloadUp
  #MenuQueueDownloadDown
  #MenuQueueDownloadRemove
EndEnumeration

Enumeration 1
  #GadgetShareLabel
  #GadgetSharePath
  #GadgetShareBrowse
  #GadgetDownloadLabel
  #GadgetDownloadPath
  #GadgetDownloadBrowse
  #GadgetPortLabel
  #GadgetPort
  #GadgetServerToggle
  #GadgetServerStatus
  #GadgetLocalIPs
  #GadgetRemoteHostLabel
  #GadgetRemoteHost
  #GadgetScan
  #GadgetConnect
  #GadgetDisconnect
  #GadgetRefresh
  #GadgetParent
  #GadgetDiscoveryLabel
  #GadgetDiscovery
  #GadgetDiscoveryPeersOnly
  #GadgetCopyInfo
  #GadgetDetailsTitle
  #GadgetDetailsHost
  #GadgetDetailsType
  #GadgetDetailsPort
  #GadgetDetailsMac
  #GadgetDetailsVendor
  #GadgetDetailsState
  #GadgetQueueLabel
  #GadgetUploadQueue
  #GadgetUploadUp
  #GadgetUploadDown
  #GadgetUploadRemove
  #GadgetDownloadQueue
  #GadgetDownloadUp
  #GadgetDownloadDown
  #GadgetDownloadRemove
  #GadgetRemotePathLabel
  #GadgetRemotePath
  #GadgetUpload
  #GadgetDownload
  #GadgetPause
  #GadgetCancel
  #GadgetOverwriteLabel
  #GadgetOverwrite
  #GadgetRemoteList
  #GadgetProgressText
  #GadgetProgress
  #GadgetLog
  #GadgetHistory
  #GadgetQuickSendFiles
  #GadgetQuickSendFolder
  #GadgetQuickSettings
  #GadgetQuickExit
  #GadgetQuickUploads
  #GadgetQuickDownloads
  #GadgetReceiverList
  #GadgetReceiverSend
  #GadgetReceiverCancel
  #GadgetSettingsShare
  #GadgetSettingsShareBrowse
  #GadgetSettingsDownload
  #GadgetSettingsDownloadBrowse
  #GadgetSettingsPort
  #GadgetSettingsSave
  #GadgetSettingsCancel
EndEnumeration

Enumeration 1
  #FrameHello
  #FrameListRequest
  #FrameListBegin
  #FrameListItem
  #FrameListEnd
  #FrameDownloadRequest
  #FrameUploadBegin
  #FrameUploadReady
  #FrameFileBegin
  #FrameFileChunk
  #FrameFileEnd
  #FrameTreeRequest
  #FrameTreeBegin
  #FrameTreeItem
  #FrameTreeEnd
  #FrameCreateDir
  #FramePause
  #FrameResume
  #FrameCancel
  #FrameUploadVerify
  #FrameStatus
  #FrameError
EndEnumeration

Enumeration 0
  #TransferNone
  #TransferUpload
  #TransferDownload
EndEnumeration

Enumeration 1
  #TransferRowUpload
  #TransferRowDownload
EndEnumeration

Enumeration 0
  #OverwriteKeepBoth
  #OverwriteReplace
  #OverwriteSkip
  #OverwriteResume
EndEnumeration

Structure PeerState
  Connection.i
  IsOutgoing.i
  PeerName.s
  PeerHost.s
  RemoteShareName.s
  InputBuffer.i
  InputSize.i
  InputCapacity.i
  BuildingList.i
  CurrentRemotePath.s
  IsDiscovery.i
  SendMode.i
  SendFile.i
  SendTotal.q
  SendDone.q
  SendRelativePath.s
  SendModified.q
  SendChecksum.s
  ReceiveMode.i
  ReceiveFile.i
  ReceiveTotal.q
  ReceiveDone.q
  ReceiveRelativePath.s
  ReceiveFinalPath.s
  ReceiveModified.q
  ReceiveExpectedChecksum.s
  ReceiveActualChecksum.s
  WaitingUploadReady.i
  PendingLocalUploadPath.s
  PendingRemoteTargetDir.s
  PendingDownloadPath.s
  AwaitingTransferStatus.i
  AwaitingUploadVerify.i
  BuildingTree.i
  SendPaused.i
EndStructure

Structure BrowserEntry
  Name.s
  RelativePath.s
  IsDirectory.i
  Size.q
  Modified.q
EndStructure

Structure UploadItem
  LocalPath.s
  RemotePath.s
  IsDirectory.i
  RetryCount.i
EndStructure

Structure DownloadItem
  RemotePath.s
  RetryCount.i
EndStructure

Structure TransferRow
  Direction.i
  Key.s
  Peer.s
  FilePath.s
  Size.q
  Status.s
  Progress.i
EndStructure

Structure DiscoveryEntry
  Host.s
  Port.i
  Name.s
  Share.s
  LastSeen.q
  DeviceType.s
  IsLanShare.i
  MacAddress.s
  Vendor.s
  State.s
EndStructure

Global ServerID.i
Global ServerRunning.i
Global ActiveRemoteConnection.i
Global HostName$
Global SharePath$
Global DownloadPath$
Global Dim RemoteEntryPath$(0)
Global Dim RemoteEntryIsDirectory.i(0)
Global Dim DiscoveryEntryHost$(0)
Global Dim DiscoveryEntryPort.i(0)
Global Dim DiscoveryEntryIsLanShare.i(0)
Global DiscoveryFilterPeersOnly.i
Global NewMap Peers.PeerState()
Global NewList BrowserEntries.BrowserEntry()
Global NewList UploadQueue.UploadItem()
Global NewList DownloadQueue.DownloadItem()
Global NewList Transfers.TransferRow()
Global NewMap Discovery.DiscoveryEntry()
Global NewList DiscoveryResults.DiscoveryEntry()
Global NewList ScanTargets.s()
Global ScanActive.i
Global TransfersPaused.i
Global ScanMutex.i
Global Dim ScanThreadID.i(#DiscoveryWorkers - 1)
Global ScanThreadCount.i
Global ScanWorkerRunning.i
Global ScanCancel.i
Global TrayAvailable.i
Global FirstRunShown.i
Global TrayImage.i
Global AutoDisconnectAfterSend.i
Global AutoScanNext.i
Global CurrentQueuedTargetHost$
Global CurrentQueuedTargetPort.i
Global PreferredReceiverHost$
Global PreferredReceiverPort.i
Global PreferredReceiverIsLanShare.i

Declare UpdateProgressUI()
Declare DiscoveryScanThread(*Value)
Declare AddLog(Message$)
Declare.s SettingsPath()
Declare.s FormatBytes(Value.q)
Declare QueueUploadPathRecursive(LocalPath$, RemoteBase$)
Declare QueueUploadItem(LocalPath$, RemotePath$, IsDirectory.i)
Declare QueueQuickSend(LocalPath$, IsDirectory.i)
Declare OpenQuickSendFiles()
Declare OpenQuickSendFolder()
Declare StartDiscoveryScan()
Declare TryStartNextUpload()
Declare ConnectRemote()
Declare DisconnectRemote()
Declare SaveSettings()
Declare StartServer()
Declare StopServer()
Declare EnsureUsablePort(ShowLog.i)

UseSHA2Fingerprint()

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure.s TrimTrailingSlash(Path$)
  Protected Result$ = Path$

  While Len(Result$) > 1 And (Right(Result$, 1) = "\\" Or Right(Result$, 1) = "/")
    If Len(Result$) = 3 And Mid(Result$, 2, 1) = ":"
      Break
    EndIf
    Result$ = Left(Result$, Len(Result$) - 1)
  Wend

  ProcedureReturn Result$
EndProcedure

Procedure EnsureDirectoryExists(DirPath$)
  Protected Normalized$ = TrimTrailingSlash(DirPath$)
  Protected Parent$

  If Normalized$ = ""
    ProcedureReturn
  EndIf

  If FileSize(Normalized$) = -2
    ProcedureReturn
  EndIf

  If Len(Normalized$) <= 3 And Mid(Normalized$, 2, 1) = ":"
    ProcedureReturn
  EndIf

  Parent$ = TrimTrailingSlash(GetPathPart(Normalized$))
  If Parent$ <> "" And Parent$ <> Normalized$
    EnsureDirectoryExists(Parent$)
  EndIf

  CreateDirectory(Normalized$)
EndProcedure

Procedure.s NormalizeRelativePath(RelativePath$)
  Protected Working$ = ReplaceString(Trim(RelativePath$), "\\", "/")
  Protected Count.i
  Protected Depth.i
  Protected Part$
  Protected Index.i
  Protected Result$
  Protected Dim Segments$(0)

  While Left(Working$, 1) = "/"
    Working$ = Mid(Working$, 2)
  Wend

  While FindString(Working$, "//", 1)
    Working$ = ReplaceString(Working$, "//", "/")
  Wend

  If FindString(Working$, ":", 1)
    ProcedureReturn #InvalidRelativePath
  EndIf

  If Working$ = ""
    ProcedureReturn ""
  EndIf

  Count = CountString(Working$, "/") + 1
  ReDim Segments$(Count)

  For Index = 1 To Count
    Part$ = StringField(Working$, Index, "/")
    If Part$ <> "" And Part$ <> "."
      If Part$ = ".."
        If Depth = 0
          ProcedureReturn #InvalidRelativePath
        EndIf
        Depth - 1
      Else
        Depth + 1
        Segments$(Depth) = Part$
      EndIf
    EndIf
  Next

  For Index = 1 To Depth
    If Result$ <> ""
      Result$ + "/"
    EndIf
    Result$ + Segments$(Index)
  Next

  ProcedureReturn Result$
EndProcedure

Procedure.s JoinRelativePath(BasePath$, ChildName$)
  Protected Base$ = NormalizeRelativePath(BasePath$)
  Protected Child$ = NormalizeRelativePath(ChildName$)

  If Base$ = #InvalidRelativePath Or Child$ = #InvalidRelativePath
    ProcedureReturn #InvalidRelativePath
  EndIf

  If Base$ = ""
    ProcedureReturn Child$
  EndIf

  If Child$ = ""
    ProcedureReturn Base$
  EndIf

  ProcedureReturn Base$ + "/" + Child$
EndProcedure

Procedure.s ParentRelativePath(RelativePath$)
  Protected Normalized$ = NormalizeRelativePath(RelativePath$)
  Protected Count.i
  Protected Index.i
  Protected Result$

  If Normalized$ = #InvalidRelativePath Or Normalized$ = ""
    ProcedureReturn ""
  EndIf

  Count = CountString(Normalized$, "/") + 1
  If Count <= 1
    ProcedureReturn ""
  EndIf

  For Index = 1 To Count - 1
    If Result$ <> ""
      Result$ + "/"
    EndIf
    Result$ + StringField(Normalized$, Index, "/")
  Next

  ProcedureReturn Result$
EndProcedure

Procedure.s ResolveSharePath(RelativePath$)
  Protected Normalized$ = NormalizeRelativePath(RelativePath$)
  Protected Base$ = TrimTrailingSlash(SharePath$)

  If Normalized$ = #InvalidRelativePath
    ProcedureReturn ""
  EndIf

  If Normalized$ = ""
    ProcedureReturn Base$
  EndIf

  ProcedureReturn Base$ + "\\" + ReplaceString(Normalized$, "/", "\\")
EndProcedure

Procedure.s ResolveDownloadPath(RelativePath$)
  Protected Normalized$ = NormalizeRelativePath(RelativePath$)
  Protected Base$ = TrimTrailingSlash(DownloadPath$)

  If Normalized$ = #InvalidRelativePath Or Normalized$ = ""
    ProcedureReturn ""
  EndIf

  ProcedureReturn Base$ + "\\" + ReplaceString(Normalized$, "/", "\\")
EndProcedure

Procedure.s MakeUniqueFilePath(TargetPath$)
  Protected Directory$ = GetPathPart(TargetPath$)
  Protected FileName$ = GetFilePart(TargetPath$)
  Protected Extension$ = GetExtensionPart(TargetPath$)
  Protected Stem$ = FileName$
  Protected Candidate$
  Protected Index.i

  If FileSize(TargetPath$) = -1
    ProcedureReturn TargetPath$
  EndIf

  If Extension$ <> "" And Len(FileName$) > Len(Extension$) + 1
    Stem$ = Left(FileName$, Len(FileName$) - Len(Extension$) - 1)
  EndIf

  For Index = 1 To 9999
    Candidate$ = Directory$ + Stem$ + " (" + Str(Index) + ")"
    If Extension$ <> ""
      Candidate$ + "." + Extension$
    EndIf

    If FileSize(Candidate$) = -1
      ProcedureReturn Candidate$
    EndIf
  Next

  ProcedureReturn Directory$ + Stem$ + "_" + FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
EndProcedure

Procedure OverwriteMode()
  ProcedureReturn GetGadgetState(#GadgetOverwrite)
EndProcedure

Procedure.s ResolveTargetPath(TargetPath$, AllowResume.i)
  Protected Mode.i = OverwriteMode()

  If FileSize(TargetPath$) = -1
    ProcedureReturn TargetPath$
  EndIf

  Select Mode
    Case #OverwriteReplace
      DeleteFile(TargetPath$)
      ProcedureReturn TargetPath$

    Case #OverwriteSkip
      ProcedureReturn ""

    Case #OverwriteResume
      If AllowResume
        ProcedureReturn TargetPath$
      EndIf
      ProcedureReturn MakeUniqueFilePath(TargetPath$)

    Default
      ProcedureReturn MakeUniqueFilePath(TargetPath$)
  EndSelect
EndProcedure

Procedure.s FileSHA256(FilePath$)
  ProcedureReturn FileFingerprint(FilePath$, #PB_Cipher_SHA2, 256)
EndProcedure

Procedure.s ResolveMacAddress(Host$)
  Protected Program.i
  Protected Output$
  Protected Line$
  Protected MacAddress$
  Protected CleanLine$

  Program = RunProgram("cmd", "/c arp -a " + Host$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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
  EndIf

  While Output$ <> ""
    Line$ = Trim(StringField(Output$, 1, Chr(10)))
    If FindString(Line$, Host$, 1)
      CleanLine$ = ReplaceString(Line$, Chr(9), " ")
      While FindString(CleanLine$, "  ", 1)
        CleanLine$ = ReplaceString(CleanLine$, "  ", " ")
      Wend
      MacAddress$ = StringField(CleanLine$, 2, " ")
      Break
    EndIf
    If FindString(Output$, Chr(10), 1)
      Output$ = Mid(Output$, FindString(Output$, Chr(10), 1) + 1)
    Else
      Output$ = ""
    EndIf
  Wend

  ProcedureReturn UCase(MacAddress$)
EndProcedure

Procedure.s ResolveVendor(MacAddress$)
  Protected Prefix$ = ReplaceString(UCase(MacAddress$), "-", "")

  If Len(Prefix$) < 6
    ProcedureReturn ""
  EndIf

  Prefix$ = Left(Prefix$, 6)
  Select Prefix$
    Case "001A11", "3CD92B", "FCA667"
      ProcedureReturn "HP"
    Case "B827EB", "D83ADD", "E45F01"
      ProcedureReturn "Raspberry Pi"
    Case "DCA632", "F4F5D8", "7CFADF"
      ProcedureReturn "Samsung"
    Case "ACBC32", "3C2EF9", "8C8590"
      ProcedureReturn "LG"
    Case "F0D1A9", "BC1401", "4C3275"
      ProcedureReturn "Apple"
    Case "00155D", "000C29", "005056"
      ProcedureReturn "VM/Virtual NIC"
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.s ResolveHostName(Host$)
  Protected Program.i
  Protected Output$
  Protected Line$
  Protected Name$
  Protected StartPos.i
  Protected EndPos.i

  Program = RunProgram("cmd", "/c nslookup " + Host$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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
  EndIf

  While Output$ <> ""
    Line$ = Trim(StringField(Output$, 1, Chr(10)))
    If LCase(Left(Line$, 5)) = "name:"
      Name$ = Trim(Mid(Line$, 6))
      If Name$ <> ""
        ProcedureReturn Name$
      EndIf
    EndIf
    If FindString(Output$, Chr(10), 1)
      Output$ = Mid(Output$, FindString(Output$, Chr(10), 1) + 1)
    Else
      Output$ = ""
    EndIf
  Wend

  Output$ = ""
  Program = RunProgram("cmd", "/c nbtstat -A " + Host$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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
  EndIf

  While Output$ <> ""
    Line$ = Trim(StringField(Output$, 1, Chr(10)))
    If FindString(LCase(Line$), "unique", 1) And FindString(Line$, "<00>", 1)
      StartPos = 1
      EndPos = FindString(Line$, "<00>", 1)
      If EndPos > StartPos
        Name$ = Trim(Left(Line$, EndPos - 1))
        If Name$ <> "" And FindString(Name$, "MAC Address", 1) = 0
          ProcedureReturn Name$
        EndIf
      EndIf
    EndIf
    If FindString(Output$, Chr(10), 1)
      Output$ = Mid(Output$, FindString(Output$, Chr(10), 1) + 1)
    Else
      Output$ = ""
    EndIf
  Wend

  ProcedureReturn Host$
EndProcedure

Procedure.s RunHiddenCommand(Command$)
  Protected Program.i
  Protected Output$

  Program = RunProgram("cmd", "/c " + Command$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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
  EndIf

  ProcedureReturn Output$
EndProcedure

Procedure.s PortConflictDetails(Port.i)
  Protected Netstat$
  Protected Line$
  Protected Pid$
  Protected TaskInfo$
  Protected ProcessName$
  Protected Fields.i

  Netstat$ = RunHiddenCommand("netstat -ano -p tcp | findstr LISTENING | findstr :" + Str(Port))
  While Netstat$ <> ""
    Line$ = Trim(StringField(Netstat$, 1, Chr(10)))
    If FindString(Line$, ":" + Str(Port), 1)
      While FindString(Line$, "  ", 1)
        Line$ = ReplaceString(Line$, "  ", " ")
      Wend
      Fields = CountString(Line$, " ") + 1
      If Fields >= 5
        Pid$ = StringField(Line$, Fields, " ")
        TaskInfo$ = RunHiddenCommand("tasklist /FI " + Chr(34) + "PID eq " + Pid$ + Chr(34) + " /FO CSV /NH")
        If Left(TaskInfo$, 1) = Chr(34)
          ProcessName$ = StringField(TaskInfo$, 1, ",")
          ProcessName$ = RemoveString(ProcessName$, Chr(34))
          If ProcessName$ <> "" And FindString(ProcessName$, "No tasks", 1) = 0
            ProcedureReturn ProcessName$ + " (PID " + Pid$ + ")"
          EndIf
        EndIf
        ProcedureReturn "PID " + Pid$
      EndIf
    EndIf
    If FindString(Netstat$, Chr(10), 1)
      Netstat$ = Mid(Netstat$, FindString(Netstat$, Chr(10), 1) + 1)
    Else
      Netstat$ = ""
    EndIf
  Wend

  ProcedureReturn ""
EndProcedure

Procedure.i HostRespondsToPing(Host$)
  Protected Output$

  Output$ = LCase(RunHiddenCommand("ping -n 1 -w 700 " + Host$))
  If FindString(Output$, "ttl=", 1) Or FindString(Output$, "bytes=", 1)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i IsPortBindable(Port.i)
  Protected TestServer.i

  If Port <= 0
    ProcedureReturn #False
  EndIf

  TestServer = CreateNetworkServer(#PB_Any, Port)
  If TestServer
    CloseNetworkServer(TestServer)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i FindOpenPort(StartPort.i, EndPort.i)
  Protected Port.i

  For Port = StartPort To EndPort
    If IsPortBindable(Port)
      ProcedureReturn Port
    EndIf
  Next

  ProcedureReturn 0
EndProcedure

Procedure EnsureUsablePort(ShowLog.i)
  Protected RequestedPort.i = Val(GetGadgetText(#GadgetPort))
  Protected OpenPort.i
  Protected Conflict$

  If RequestedPort <= 0
    RequestedPort = #DefaultPort
  EndIf

  If IsPortBindable(RequestedPort)
    SetGadgetText(#GadgetPort, Str(RequestedPort))
    ProcedureReturn
  EndIf

  Conflict$ = PortConflictDetails(RequestedPort)
  OpenPort = FindOpenPort(#PortSearchStart, #PortSearchEnd)
  If OpenPort = 0
    OpenPort = FindOpenPort(40000, 40100)
  EndIf

  If OpenPort > 0
    SetGadgetText(#GadgetPort, Str(OpenPort))
    If ShowLog
      If Conflict$ <> ""
        AddLog("Port " + Str(RequestedPort) + " is busy: " + Conflict$)
      Else
        AddLog("Port " + Str(RequestedPort) + " is busy")
      EndIf
      AddLog("Switched to open port " + Str(OpenPort))
    EndIf
  EndIf
EndProcedure

Procedure RefreshDiscoveryList()
  Protected Display$
  Protected Index.i
  Protected TypeText$
  Protected PortText$
  Protected SelectedHost$
  Protected SelectedIndex.i = -1

  If PreferredReceiverHost$ <> ""
    SelectedHost$ = PreferredReceiverHost$
  Else
    SelectedIndex = GetGadgetState(#GadgetDiscovery)
    If SelectedIndex >= 0 And SelectedIndex <= ArraySize(DiscoveryEntryHost$())
      SelectedHost$ = DiscoveryEntryHost$(SelectedIndex)
    EndIf
  EndIf

  ClearGadgetItems(#GadgetDiscovery)
  If MapSize(Discovery()) <= 0
    ReDim DiscoveryEntryHost$(0)
    ReDim DiscoveryEntryPort(0)
    ReDim DiscoveryEntryIsLanShare(0)
    ProcedureReturn
  EndIf

  ReDim DiscoveryEntryHost$(MapSize(Discovery()) - 1)
  ReDim DiscoveryEntryPort(MapSize(Discovery()) - 1)
  ReDim DiscoveryEntryIsLanShare(MapSize(Discovery()) - 1)
  Index = 0
  ForEach Discovery()
    If DiscoveryFilterPeersOnly And Discovery()\IsLanShare = 0
      Continue
    EndIf

    If Discovery()\Name <> ""
      Display$ = Discovery()\Name + " (" + Discovery()\Host + ")"
    Else
      Display$ = Discovery()\Host
    EndIf

    TypeText$ = Discovery()\DeviceType
    If Discovery()\State <> ""
      TypeText$ + " " + Discovery()\State
    EndIf

    If Discovery()\Port > 0
      PortText$ = Str(Discovery()\Port)
    Else
      PortText$ = "-"
    EndIf

    AddGadgetItem(#GadgetDiscovery, -1, Display$ + Chr(10) + TypeText$ + Chr(10) + PortText$)
    DiscoveryEntryHost$(Index) = Discovery()\Host
    DiscoveryEntryPort(Index) = Discovery()\Port
    DiscoveryEntryIsLanShare(Index) = Discovery()\IsLanShare
    If SelectedHost$ <> "" And Discovery()\Host = SelectedHost$
      SelectedIndex = Index
    EndIf
    Index + 1
  Next

  If Index = 0
    ReDim DiscoveryEntryHost$(0)
    ReDim DiscoveryEntryPort(0)
    ReDim DiscoveryEntryIsLanShare(0)
  Else
    ReDim DiscoveryEntryHost$(Index - 1)
    ReDim DiscoveryEntryPort(Index - 1)
    ReDim DiscoveryEntryIsLanShare(Index - 1)
    If SelectedIndex >= 0 And SelectedIndex <= ArraySize(DiscoveryEntryHost$())
      SetGadgetState(#GadgetDiscovery, SelectedIndex)
    EndIf
  EndIf
EndProcedure

Procedure UpdateDiscoveryDetails()
  Protected Index.i = GetGadgetState(#GadgetDiscovery)
  Protected Host$

  If Index < 0 Or Index > ArraySize(DiscoveryEntryHost$())
    SetGadgetText(#GadgetDetailsTitle, "Device Details")
    SetGadgetText(#GadgetDetailsHost, "Host: -")
    SetGadgetText(#GadgetDetailsType, "Type: -")
    SetGadgetText(#GadgetDetailsPort, "Port: -")
    SetGadgetText(#GadgetDetailsMac, "MAC: -")
    SetGadgetText(#GadgetDetailsVendor, "Vendor: -")
    SetGadgetText(#GadgetDetailsState, "State: -")
    ProcedureReturn
  EndIf

  Host$ = DiscoveryEntryHost$(Index)
  If FindMapElement(Discovery(), Host$)
    SetGadgetText(#GadgetDetailsTitle, "Device Details")
    SetGadgetText(#GadgetDetailsHost, "Host: " + Discovery()\Host)
    SetGadgetText(#GadgetDetailsType, "Type: " + Discovery()\DeviceType)
    If Discovery()\Port > 0
      SetGadgetText(#GadgetDetailsPort, "Port: " + Str(Discovery()\Port))
    Else
      SetGadgetText(#GadgetDetailsPort, "Port: -")
    EndIf
    If Discovery()\MacAddress <> ""
      SetGadgetText(#GadgetDetailsMac, "MAC: " + Discovery()\MacAddress)
    Else
      SetGadgetText(#GadgetDetailsMac, "MAC: -")
    EndIf
    If Discovery()\Vendor <> ""
      SetGadgetText(#GadgetDetailsVendor, "Vendor: " + Discovery()\Vendor)
    Else
      SetGadgetText(#GadgetDetailsVendor, "Vendor: -")
    EndIf
    If Discovery()\State <> ""
      SetGadgetText(#GadgetDetailsState, "State: " + Discovery()\State)
    Else
      SetGadgetText(#GadgetDetailsState, "State: live network host")
    EndIf
  EndIf
EndProcedure

Procedure CopyConnectionInfo()
  Protected Index.i = GetGadgetState(#GadgetDiscovery)
  Protected Text$

  If Index < 0 Or Index > ArraySize(DiscoveryEntryHost$())
    Text$ = "Host=" + GetGadgetText(#GadgetRemoteHost) + "; Port=" + GetGadgetText(#GadgetPort)
  Else
    Text$ = "Host=" + DiscoveryEntryHost$(Index) + "; Port=" + Str(DiscoveryEntryPort(Index))
  EndIf

  SetClipboardText(Text$)
  AddLog("Copied connection info to clipboard")
EndProcedure

Procedure RefreshTransferLists()
  Protected UploadText$
  Protected DownloadText$

  ClearGadgetItems(#GadgetQuickUploads)
  ClearGadgetItems(#GadgetQuickDownloads)

  ForEach Transfers()
    If Transfers()\Direction = #TransferRowUpload
      UploadText$ = Transfers()\Peer + Chr(10) + Transfers()\FilePath + Chr(10) + FormatBytes(Transfers()\Size) + Chr(10) + Transfers()\Status + Chr(10) + Str(Transfers()\Progress) + "%"
      AddGadgetItem(#GadgetQuickUploads, -1, UploadText$)
    ElseIf Transfers()\Direction = #TransferRowDownload
      DownloadText$ = Transfers()\Peer + Chr(10) + Transfers()\FilePath + Chr(10) + FormatBytes(Transfers()\Size) + Chr(10) + Transfers()\Status + Chr(10) + Str(Transfers()\Progress) + "%"
      AddGadgetItem(#GadgetQuickDownloads, -1, DownloadText$)
    EndIf
  Next

  If CountGadgetItems(#GadgetQuickUploads) = 0
    AddGadgetItem(#GadgetQuickUploads, -1, "-" + Chr(10) + "No outgoing transfers yet" + Chr(10) + "-" + Chr(10) + "Ready" + Chr(10) + "0%")
  EndIf
  If CountGadgetItems(#GadgetQuickDownloads) = 0
    AddGadgetItem(#GadgetQuickDownloads, -1, "-" + Chr(10) + "No incoming transfers yet" + Chr(10) + "-" + Chr(10) + "Ready" + Chr(10) + "0%")
  EndIf
EndProcedure

Procedure UpdateTransferRow(Direction.i, Key$, Peer$, FilePath$, Size.q, Status$, Progress.i)
  If Peer$ = ""
    Peer$ = "Waiting..."
  EndIf

  ForEach Transfers()
    If Transfers()\Direction = Direction And Transfers()\Key = Key$
      Transfers()\Peer = Peer$
      Transfers()\FilePath = FilePath$
      Transfers()\Size = Size
      Transfers()\Status = Status$
      Transfers()\Progress = Progress
      RefreshTransferLists()
      ProcedureReturn
    EndIf
  Next

  AddElement(Transfers())
  Transfers()\Direction = Direction
  Transfers()\Key = Key$
  Transfers()\Peer = Peer$
  Transfers()\FilePath = FilePath$
  Transfers()\Size = Size
  Transfers()\Status = Status$
  Transfers()\Progress = Progress
  RefreshTransferLists()
EndProcedure

Procedure RemoveTransferRow(Direction.i, Key$)
  ForEach Transfers()
    If Transfers()\Direction = Direction And Transfers()\Key = Key$
      DeleteElement(Transfers())
      Break
    EndIf
  Next
  RefreshTransferLists()
EndProcedure

Procedure OpenSettingsWindow()
  If IsWindow(#WindowSettings)
    SetGadgetText(#GadgetSettingsDownload, DownloadPath$)
    SetGadgetText(#GadgetSettingsPort, GetGadgetText(#GadgetPort))
    HideWindow(#WindowSettings, #False)
    SetActiveWindow(#WindowSettings)
    ProcedureReturn
  EndIf

  OpenWindow(#WindowSettings, 0, 0, 520, 170, "Settings", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  TextGadget(#PB_Any, 16, 24, 100, 20, "Downloads")
  StringGadget(#GadgetSettingsDownload, 120, 20, 300, 24, DownloadPath$)
  ButtonGadget(#GadgetSettingsDownloadBrowse, 430, 20, 70, 24, "Browse")
  TextGadget(#PB_Any, 16, 64, 100, 20, "TCP Port")
  StringGadget(#GadgetSettingsPort, 120, 60, 120, 24, GetGadgetText(#GadgetPort), #PB_String_Numeric)
  ButtonGadget(#GadgetSettingsSave, 300, 112, 90, 28, "Save")
  ButtonGadget(#GadgetSettingsCancel, 400, 112, 90, 28, "Close")
EndProcedure

Procedure OpenReceiverWindow()
  Protected Text$
  Protected Count.i
  Protected SelectedIndex.i = -1
  Protected TargetHost$

  If IsWindow(#WindowReceiver) = 0
    OpenWindow(#WindowReceiver, 0, 0, 460, 340, "Choose Receiver", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#PB_Any, 16, 14, 240, 20, "Pick a receiver for this transfer")
    ListIconGadget(#GadgetReceiverList, 16, 40, 428, 240, "Receiver", 240, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
    AddGadgetColumn(#GadgetReceiverList, 1, "Status", 110)
    AddGadgetColumn(#GadgetReceiverList, 2, "Port", 55)
    ButtonGadget(#GadgetReceiverCancel, 220, 274, 86, 28, "Cancel")
    ButtonGadget(#GadgetReceiverSend, 318, 274, 86, 28, "Send")
  Else
    HideWindow(#WindowReceiver, #False)
  EndIf

  TargetHost$ = PreferredReceiverHost$
  If TargetHost$ = ""
    TargetHost$ = CurrentQueuedTargetHost$
  EndIf

  ClearGadgetItems(#GadgetReceiverList)
  ForEach Discovery()
    If Discovery()\IsLanShare
      Text$ = Discovery()\Host
      If Discovery()\Name <> ""
        Text$ = Discovery()\Name + " (" + Discovery()\Host + ")"
      EndIf
      AddGadgetItem(#GadgetReceiverList, -1, Text$ + Chr(10) + Discovery()\State + Chr(10) + Str(Discovery()\Port))
      If TargetHost$ <> "" And Discovery()\Host = TargetHost$
        SelectedIndex = Count
      EndIf
      Count + 1
    EndIf
  Next

  If Count = 0
    StartDiscoveryScan()
    AddLog("No receivers in memory yet. Scanning now...")
  EndIf

  If Count = 1
    SetGadgetState(#GadgetReceiverList, 0)
  ElseIf SelectedIndex >= 0
    SetGadgetState(#GadgetReceiverList, SelectedIndex)
  EndIf
  SetActiveWindow(#WindowReceiver)
EndProcedure

Procedure.i UseSelectedReceiverIfAvailable()
  Protected DiscoveryIndex.i = GetGadgetState(#GadgetDiscovery)

  If DiscoveryIndex >= 0 And DiscoveryIndex <= ArraySize(DiscoveryEntryHost$())
    If DiscoveryEntryIsLanShare(DiscoveryIndex) = 0 Or DiscoveryEntryPort(DiscoveryIndex) <= 0
      MessageRequester(#APP_NAME, "Select a receiver from the list first.")
      ProcedureReturn #False
    EndIf

    PreferredReceiverHost$ = DiscoveryEntryHost$(DiscoveryIndex)
    PreferredReceiverPort = DiscoveryEntryPort(DiscoveryIndex)
    PreferredReceiverIsLanShare = DiscoveryEntryIsLanShare(DiscoveryIndex)
    CurrentQueuedTargetHost$ = PreferredReceiverHost$
    CurrentQueuedTargetPort = PreferredReceiverPort
    SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
    SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
    ProcedureReturn #True
  EndIf

  If PreferredReceiverHost$ <> "" And PreferredReceiverIsLanShare And PreferredReceiverPort > 0
    CurrentQueuedTargetHost$ = PreferredReceiverHost$
    CurrentQueuedTargetPort = PreferredReceiverPort
    SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
    SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure OpenQuickSendFiles()
  Protected File$

  File$ = OpenFileRequester("Choose files to send", "", "All files (*.*)|*.*", 0, #PB_Requester_MultiSelection)
  If File$ = ""
    ProcedureReturn
  EndIf

  ClearList(UploadQueue())
  While File$ <> ""
    If FileSize(File$) >= 0
      QueueUploadItem(File$, GetFilePart(File$), #False)
    EndIf
    File$ = NextSelectedFileName()
  Wend
  If UseSelectedReceiverIfAvailable()
    ConnectRemote()
    UpdateTransferRow(#TransferRowUpload, "queued-send", CurrentQueuedTargetHost$, "Preparing transfer", 0, "Connecting", 0)
    TryStartNextUpload()
  Else
    OpenReceiverWindow()
  EndIf
EndProcedure

Procedure OpenQuickSendFolder()
  Protected Folder$

  Folder$ = PathRequester("Choose a folder to send", SharePath$)
  If Folder$
    QueueQuickSend(Folder$, #True)
  EndIf
EndProcedure

Procedure QueueQuickSend(LocalPath$, IsDirectory.i)
  If FileSize(LocalPath$) = -1
    ProcedureReturn
  EndIf

  ClearList(UploadQueue())
  CurrentQueuedTargetHost$ = ""
  CurrentQueuedTargetPort = 0
  ClearList(Transfers())
  RefreshTransferLists()
  If IsDirectory
    QueueUploadPathRecursive(TrimTrailingSlash(LocalPath$), "")
  Else
    QueueUploadItem(LocalPath$, GetFilePart(LocalPath$), #False)
  EndIf
  If UseSelectedReceiverIfAvailable()
    ConnectRemote()
    UpdateTransferRow(#TransferRowUpload, "queued-send", CurrentQueuedTargetHost$, "Preparing transfer", 0, "Connecting", 0)
    TryStartNextUpload()
  Else
    OpenReceiverWindow()
  EndIf
EndProcedure

Procedure ApplySimpleLayout()
  HideGadget(#GadgetShareLabel, #True)
  HideGadget(#GadgetShareBrowse, #True)
  HideGadget(#GadgetDownloadLabel, #True)
  HideGadget(#GadgetDownloadBrowse, #True)
  HideGadget(#GadgetPortLabel, #True)
  HideGadget(#GadgetServerToggle, #True)
  HideGadget(#GadgetRemoteHostLabel, #True)
  HideGadget(#GadgetConnect, #True)
  HideGadget(#GadgetDisconnect, #True)
  HideGadget(#GadgetRefresh, #True)
  HideGadget(#GadgetParent, #True)
  HideGadget(#GadgetOverwriteLabel, #True)
  HideGadget(#GadgetUpload, #True)
  HideGadget(#GadgetDownload, #True)
  HideGadget(#GadgetRemotePathLabel, #True)
  HideGadget(#GadgetRemotePath, #True)
  HideGadget(#GadgetRemoteList, #True)
  HideGadget(#GadgetHistory, #True)
  HideGadget(#GadgetLog, #True)
  HideGadget(#GadgetUploadQueue, #True)
  HideGadget(#GadgetUploadUp, #True)
  HideGadget(#GadgetUploadDown, #True)
  HideGadget(#GadgetUploadRemove, #True)
  HideGadget(#GadgetDownloadQueue, #True)
  HideGadget(#GadgetDownloadUp, #True)
  HideGadget(#GadgetDownloadDown, #True)
  HideGadget(#GadgetDownloadRemove, #True)

  ResizeGadget(#GadgetServerStatus, 20, 112, 930, 22)
  ResizeGadget(#GadgetLocalIPs, 20, 136, 930, 22)
  ResizeGadget(#GadgetDiscoveryLabel, 20, 170, 160, 20)
  ResizeGadget(#GadgetDiscoveryPeersOnly, 180, 168, 120, 20)
  ResizeGadget(#GadgetCopyInfo, 308, 164, 100, 28)
  ResizeGadget(#GadgetDiscovery, 20, 198, 430, 140)
  ResizeGadget(#GadgetDetailsTitle, 474, 170, 160, 20)
  ResizeGadget(#GadgetDetailsHost, 474, 198, 460, 18)
  ResizeGadget(#GadgetDetailsType, 474, 220, 460, 18)
  ResizeGadget(#GadgetDetailsPort, 474, 242, 460, 18)
  ResizeGadget(#GadgetDetailsMac, 474, 264, 460, 18)
  ResizeGadget(#GadgetDetailsVendor, 474, 286, 460, 18)
  ResizeGadget(#GadgetDetailsState, 474, 308, 460, 18)
  ResizeGadget(#GadgetQueueLabel, 20, 356, 160, 20)
  ResizeGadget(#GadgetQuickUploads, 20, 382, 930, 110)
  ResizeGadget(#GadgetQuickDownloads, 20, 526, 930, 110)
  ResizeGadget(#GadgetProgressText, 20, 648, 930, 18)
  ResizeGadget(#GadgetProgress, 20, 670, 930, 16)
EndProcedure

Procedure RefreshQueueViews()
  Protected Text$

  ClearGadgetItems(#GadgetUploadQueue)
  ForEach UploadQueue()
    If UploadQueue()\IsDirectory
      Text$ = "DIR  " + UploadQueue()\RemotePath
    Else
      Text$ = "FILE " + UploadQueue()\RemotePath
    EndIf
    AddGadgetItem(#GadgetUploadQueue, -1, Text$)
  Next

  ClearGadgetItems(#GadgetDownloadQueue)
  ForEach DownloadQueue()
    AddGadgetItem(#GadgetDownloadQueue, -1, DownloadQueue()\RemotePath)
  Next
EndProcedure

Procedure MoveSelectedUpload(Delta.i)
  Protected Index.i = GetGadgetState(#GadgetUploadQueue)
  Protected Target.i = Index + Delta
  Protected Position.i
  Protected Temp.UploadItem

  If Index < 0 Or Target < 0 Or Target >= ListSize(UploadQueue())
    ProcedureReturn
  EndIf

  Position = 0
  ForEach UploadQueue()
    If Position = Index
      CopyStructure(@UploadQueue(), @Temp, UploadItem)
      DeleteElement(UploadQueue())
      Break
    EndIf
    Position + 1
  Next

  Position = 0
  ForEach UploadQueue()
    If Position = Target
      InsertElement(UploadQueue())
      CopyStructure(@Temp, @UploadQueue(), UploadItem)
      RefreshQueueViews()
      SetGadgetState(#GadgetUploadQueue, Target)
      ProcedureReturn
    EndIf
    Position + 1
  Next

  LastElement(UploadQueue())
  AddElement(UploadQueue())
  CopyStructure(@Temp, @UploadQueue(), UploadItem)
  RefreshQueueViews()
  SetGadgetState(#GadgetUploadQueue, ListSize(UploadQueue()) - 1)
EndProcedure

Procedure RemoveSelectedUpload()
  Protected Index.i = GetGadgetState(#GadgetUploadQueue)
  Protected Position.i

  If Index < 0
    ProcedureReturn
  EndIf

  Position = 0
  ForEach UploadQueue()
    If Position = Index
      DeleteElement(UploadQueue())
      Break
    EndIf
    Position + 1
  Next
  RefreshQueueViews()
EndProcedure

Procedure MoveSelectedDownload(Delta.i)
  Protected Index.i = GetGadgetState(#GadgetDownloadQueue)
  Protected Target.i = Index + Delta
  Protected Position.i
  Protected Temp.DownloadItem

  If Index < 0 Or Target < 0 Or Target >= ListSize(DownloadQueue())
    ProcedureReturn
  EndIf

  Position = 0
  ForEach DownloadQueue()
    If Position = Index
      CopyStructure(@DownloadQueue(), @Temp, DownloadItem)
      DeleteElement(DownloadQueue())
      Break
    EndIf
    Position + 1
  Next

  Position = 0
  ForEach DownloadQueue()
    If Position = Target
      InsertElement(DownloadQueue())
      CopyStructure(@Temp, @DownloadQueue(), DownloadItem)
      RefreshQueueViews()
      SetGadgetState(#GadgetDownloadQueue, Target)
      ProcedureReturn
    EndIf
    Position + 1
  Next

  LastElement(DownloadQueue())
  AddElement(DownloadQueue())
  CopyStructure(@Temp, @DownloadQueue(), DownloadItem)
  RefreshQueueViews()
  SetGadgetState(#GadgetDownloadQueue, ListSize(DownloadQueue()) - 1)
EndProcedure

Procedure RemoveSelectedDownload()
  Protected Index.i = GetGadgetState(#GadgetDownloadQueue)
  Protected Position.i

  If Index < 0
    ProcedureReturn
  EndIf

  Position = 0
  ForEach DownloadQueue()
    If Position = Index
      DeleteElement(DownloadQueue())
      Break
    EndIf
    Position + 1
  Next
  RefreshQueueViews()
EndProcedure

Procedure ShowFirstRunHelp()
  Protected Help$

  If FirstRunShown
    ProcedureReturn
  EndIf

  If FileSize(SettingsPath()) <> -1
    ProcedureReturn
  EndIf

  Help$ = "Welcome to PB_LanShare." + #CRLF$ + #CRLF$
  Help$ + "Simple use:" + #CRLF$
  Help$ + "1. Open PB_LanShare on both laptops." + #CRLF$
  Help$ + "2. Click Find Receivers." + #CRLF$
  Help$ + "3. Click Send Files or Send Folder." + #CRLF$
  Help$ + "4. Pick the receiver and the transfer starts." + #CRLF$ + #CRLF$
  Help$ + "Use Settings only if you want to change folders or the port."

  MessageRequester(#APP_NAME, Help$, #PB_MessageRequester_Info)
  FirstRunShown = #True
EndProcedure

Procedure CreateTraySupport()
  TrayImage = LoadImage(#PB_Any, AppPath + "files\PB_LanShare.ico")
  If TrayImage = 0
    TrayImage = LoadImage(#PB_Any, AppPath + "src\PB_LanShare.ico")
  EndIf
  If TrayImage
    If AddSysTrayIcon(#TrayMain, WindowID(#WindowMain), ImageID(TrayImage))
      TrayAvailable = #True
    EndIf
  Else
    CreateImage(999, 16, 16, 32, RGB(40, 130, 220))
    If IsImage(999)
      If AddSysTrayIcon(#TrayMain, WindowID(#WindowMain), ImageID(999))
        TrayAvailable = #True
      EndIf
    EndIf
  EndIf

  If TrayAvailable And IsSysTrayIcon(#TrayMain)
    CreatePopupMenu(#TrayMain)
    MenuItem(#MenuTrayShow, "Show / Restore")
    MenuItem(#MenuTrayScan, "Find Receivers")
    MenuBar()
    MenuItem(#MenuTrayExit, "Exit")
    SysTrayIconMenu(#TrayMain, MenuID(#TrayMain))
  EndIf
EndProcedure

Procedure RestoreMainWindow()
  HideWindow(#WindowMain, #False, #PB_Window_ScreenCentered)
  SetActiveWindow(#WindowMain)
EndProcedure

Procedure MinimizeToTray()
  If TrayAvailable
    HideWindow(#WindowMain, #True)
    AddLog("Minimized to tray")
  EndIf
EndProcedure

Procedure AddHistory(Status$, Direction$, Item$, Details$)
  Protected Line$ = FormatDate("%hh:%ii:%ss", Date()) + Chr(10) + Status$ + Chr(10) + Direction$ + Chr(10) + Item$ + Chr(10) + Details$

  AddGadgetItem(#GadgetHistory, -1, Line$)
  If CountGadgetItems(#GadgetHistory) > 300
    RemoveGadgetItem(#GadgetHistory, 0)
  EndIf
EndProcedure

Procedure.s SettingsPath()
  ProcedureReturn GetCurrentDirectory() + #SettingsFile
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(SettingsPath())
    PreferenceGroup("LanShare")
    DownloadPath$ = TrimTrailingSlash(ReadPreferenceString("DownloadPath", DownloadPath$))
    PreferenceGroup("RememberedPeers")
    ExaminePreferenceKeys()
    While NextPreferenceKey()
      AddMapElement(Discovery(), PreferenceKeyName())
      Discovery()\Host = PreferenceKeyName()
      Discovery()\Port = Val(StringField(PreferenceKeyValue(), 1, "|"))
      Discovery()\Name = StringField(PreferenceKeyValue(), 2, "|")
      Discovery()\DeviceType = "Ready to receive"
      Discovery()\IsLanShare = #True
      Discovery()\State = "(remembered)"
    Wend
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveSettings()
  Protected PeerValue$

  If CreatePreferences(SettingsPath())
    PreferenceGroup("LanShare")
    WritePreferenceString("DownloadPath", DownloadPath$)
    WritePreferenceString("Port", GetGadgetText(#GadgetPort))
    WritePreferenceString("RemoteHost", GetGadgetText(#GadgetRemoteHost))
    WritePreferenceLong("OverwriteMode", GetGadgetState(#GadgetOverwrite))

    PreferenceGroup("RememberedPeers")
    ForEach Discovery()
      If Discovery()\IsLanShare
        PeerValue$ = Str(Discovery()\Port) + "|" + Discovery()\Name
        WritePreferenceString(Discovery()\Host, PeerValue$)
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure ApplyLoadedSettingsToUI()
  Protected SavedPort$

  If OpenPreferences(SettingsPath())
    PreferenceGroup("LanShare")
    SavedPort$ = ReadPreferenceString("Port", Str(#DefaultPort))
    SetGadgetText(#GadgetPort, SavedPort$)
    SetGadgetText(#GadgetRemoteHost, ReadPreferenceString("RemoteHost", ""))
    SetGadgetState(#GadgetOverwrite, ReadPreferenceLong("OverwriteMode", #OverwriteKeepBoth))
    ClosePreferences()
  Else
    SetGadgetText(#GadgetPort, Str(#DefaultPort))
  EndIf

  EnsureUsablePort(#False)
  SetGadgetState(#GadgetDiscoveryPeersOnly, #PB_Checkbox_Unchecked)
  DiscoveryFilterPeersOnly = #False
  RefreshDiscoveryList()
  UpdateDiscoveryDetails()
EndProcedure

Procedure.s FormatBytes(Value.q)
  Protected Size.d = Value
  Protected Unit$ = "B"

  If Size >= 1024
    Size / 1024
    Unit$ = "KB"
  EndIf
  If Size >= 1024
    Size / 1024
    Unit$ = "MB"
  EndIf
  If Size >= 1024
    Size / 1024
    Unit$ = "GB"
  EndIf

  If Unit$ = "B"
    ProcedureReturn Str(Value) + " B"
  EndIf

  ProcedureReturn StrD(Size, 1) + " " + Unit$
EndProcedure

Procedure.s TimestampText(Value.q)
  If Value <= 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii", Value)
EndProcedure

Procedure AddLog(Message$)
  Protected Line$ = FormatDate("%hh:%ii:%ss", Date()) + "  " + Message$

  AddGadgetItem(#GadgetLog, -1, Line$)
  If CountGadgetItems(#GadgetLog) > 500
    RemoveGadgetItem(#GadgetLog, 0)
  EndIf
  SetGadgetState(#GadgetLog, CountGadgetItems(#GadgetLog) - 1)
EndProcedure

Procedure.i GetPeer(Connection.i)
  If FindMapElement(Peers(), Str(Connection))
    ProcedureReturn @Peers()
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure ClearBrowser()
  ClearList(BrowserEntries())
  ClearGadgetItems(#GadgetRemoteList)
  ReDim RemoteEntryPath$(0)
  ReDim RemoteEntryIsDirectory(0)
  SetGadgetText(#GadgetRemotePath, "/")
EndProcedure

Procedure RefreshBrowserGadget()
  Protected ItemCount.i = ListSize(BrowserEntries())
  Protected Index.i
  Protected ItemText$

  ClearGadgetItems(#GadgetRemoteList)

  If ItemCount <= 0
    ReDim RemoteEntryPath$(0)
    ReDim RemoteEntryIsDirectory(0)
    ProcedureReturn
  EndIf

  ReDim RemoteEntryPath$(ItemCount - 1)
  ReDim RemoteEntryIsDirectory(ItemCount - 1)

  Index = 0
  ForEach BrowserEntries()
    ItemText$ = BrowserEntries()\Name + Chr(10)
    If BrowserEntries()\IsDirectory
      ItemText$ + "Folder"
    Else
      ItemText$ + FormatBytes(BrowserEntries()\Size)
    EndIf
    ItemText$ + Chr(10) + TimestampText(BrowserEntries()\Modified)
    ItemText$ + Chr(10) + BrowserEntries()\RelativePath

    AddGadgetItem(#GadgetRemoteList, -1, ItemText$)
    RemoteEntryPath$(Index) = BrowserEntries()\RelativePath
    RemoteEntryIsDirectory(Index) = BrowserEntries()\IsDirectory
    Index + 1
  Next
EndProcedure

Procedure.s BuildShareName()
  ProcedureReturn HostName$
EndProcedure

Procedure.s BuildHelloPayload()
  ProcedureReturn HostName$ + Chr(31) + BuildShareName() + Chr(31) + version
EndProcedure

Procedure.s PayloadToString(*Payload, PayloadLength.i)
  Protected *Copy
  Protected Result$

  If PayloadLength <= 0 Or *Payload = 0
    ProcedureReturn ""
  EndIf

  *Copy = AllocateMemory(PayloadLength + 1)
  If *Copy = 0
    ProcedureReturn ""
  EndIf

  CopyMemory(*Payload, *Copy, PayloadLength)
  PokeA(*Copy + PayloadLength, 0)
  Result$ = PeekS(*Copy, -1, #PB_UTF8)
  FreeMemory(*Copy)

  ProcedureReturn Result$
EndProcedure

Procedure.i SendAll(Connection.i, *Buffer, Length.i)
  Protected Sent.i
  Protected Total.i

  While Total < Length
    Sent = SendNetworkData(Connection, *Buffer + Total, Length - Total)
    If Sent <= 0
      ProcedureReturn #False
    EndIf
    Total + Sent
  Wend

  ProcedureReturn #True
EndProcedure

Procedure.i SendFrame(Connection.i, FrameType.i, *Payload, PayloadLength.i)
  Protected TotalLength.i = 16 + PayloadLength
  Protected *Buffer
  Protected Result.i

  If PayloadLength < 0 Or PayloadLength > #ProtocolMaxPayload
    ProcedureReturn #False
  EndIf

  *Buffer = AllocateMemory(TotalLength)
  If *Buffer = 0
    ProcedureReturn #False
  EndIf

  PokeL(*Buffer, #ProtocolMagic)
  PokeL(*Buffer + 4, FrameType)
  PokeQ(*Buffer + 8, PayloadLength)
  If PayloadLength > 0 And *Payload
    CopyMemory(*Payload, *Buffer + 16, PayloadLength)
  EndIf

  Result = SendAll(Connection, *Buffer, TotalLength)
  FreeMemory(*Buffer)
  ProcedureReturn Result
EndProcedure

Procedure.i SendTextFrame(Connection.i, FrameType.i, Text$)
  Protected *Utf8
  Protected Length.i
  Protected Result.i

  *Utf8 = UTF8(Text$)
  If *Utf8 = 0
    ProcedureReturn #False
  EndIf

  Length = MemorySize(*Utf8) - 1
  If Length < 0
    Length = 0
  EndIf

  Result = SendFrame(Connection, FrameType, *Utf8, Length)
  FreeMemory(*Utf8)
  ProcedureReturn Result
EndProcedure

Procedure SendStatus(Connection.i, Message$)
  SendTextFrame(Connection, #FrameStatus, Message$)
EndProcedure

Procedure SendError(Connection.i, Message$)
  SendTextFrame(Connection, #FrameError, Message$)
EndProcedure

Procedure AppendPeerBuffer(*Peer.PeerState, *Data, Length.i)
  Protected Needed.i

  If Length <= 0
    ProcedureReturn
  EndIf

  Needed = *Peer\InputSize + Length
  If Needed > *Peer\InputCapacity
    If Needed > #ProtocolMaxPayload + 16
      ProcedureReturn
    EndIf

    *Peer\InputCapacity = Needed + 65536
    If *Peer\InputBuffer
      *Peer\InputBuffer = ReAllocateMemory(*Peer\InputBuffer, *Peer\InputCapacity)
    Else
      *Peer\InputBuffer = AllocateMemory(*Peer\InputCapacity)
    EndIf
  EndIf

  If *Peer\InputBuffer
    CopyMemory(*Data, *Peer\InputBuffer + *Peer\InputSize, Length)
    *Peer\InputSize + Length
  EndIf
EndProcedure

Procedure FreePeerResources(*Peer.PeerState)
  If *Peer\SendFile
    CloseFile(*Peer\SendFile)
    *Peer\SendFile = 0
  EndIf

  If *Peer\ReceiveFile
    CloseFile(*Peer\ReceiveFile)
    *Peer\ReceiveFile = 0
  EndIf

  If *Peer\InputBuffer
    FreeMemory(*Peer\InputBuffer)
    *Peer\InputBuffer = 0
  EndIf

  *Peer\InputSize = 0
  *Peer\InputCapacity = 0
EndProcedure

Procedure ResetPeerTransferState(*Peer.PeerState)
  If *Peer\SendFile
    CloseFile(*Peer\SendFile)
    *Peer\SendFile = 0
  EndIf
  If *Peer\ReceiveFile
    CloseFile(*Peer\ReceiveFile)
    *Peer\ReceiveFile = 0
  EndIf

  *Peer\SendMode = #TransferNone
  *Peer\SendTotal = 0
  *Peer\SendDone = 0
  *Peer\SendRelativePath = ""
  *Peer\SendModified = 0
  *Peer\SendChecksum = ""
  *Peer\ReceiveMode = #TransferNone
  *Peer\ReceiveTotal = 0
  *Peer\ReceiveDone = 0
  *Peer\ReceiveRelativePath = ""
  *Peer\ReceiveFinalPath = ""
  *Peer\ReceiveModified = 0
  *Peer\ReceiveExpectedChecksum = ""
  *Peer\ReceiveActualChecksum = ""
  *Peer\WaitingUploadReady = 0
  *Peer\PendingLocalUploadPath = ""
  *Peer\PendingRemoteTargetDir = ""
  *Peer\PendingDownloadPath = ""
  *Peer\AwaitingTransferStatus = 0
  *Peer\AwaitingUploadVerify = 0
  *Peer\BuildingTree = 0
  *Peer\SendPaused = 0
EndProcedure

Procedure PauseAllTransfers()
  Protected *Peer.PeerState

  TransfersPaused = #True
  ForEach Peers()
    *Peer = @Peers()
    *Peer\SendPaused = #True
    If *Peer\IsDiscovery = 0
      SendFrame(*Peer\Connection, #FramePause, 0, 0)
    EndIf
  Next
  SetGadgetText(#GadgetPause, "Resume")
  AddLog("Transfers paused")
  UpdateProgressUI()
EndProcedure

Procedure ResumeAllTransfers()
  Protected *Peer.PeerState

  TransfersPaused = #False
  ForEach Peers()
    *Peer = @Peers()
    *Peer\SendPaused = #False
    If *Peer\IsDiscovery = 0
      SendFrame(*Peer\Connection, #FrameResume, 0, 0)
    EndIf
  Next
  SetGadgetText(#GadgetPause, "Pause")
  AddLog("Transfers resumed")
  UpdateProgressUI()
EndProcedure

Procedure CancelQueuedTransfers()
  Protected *Peer.PeerState

  ClearList(UploadQueue())
  ClearList(DownloadQueue())
  ForEach Peers()
    *Peer = @Peers()
    If *Peer\IsDiscovery = 0
      SendFrame(*Peer\Connection, #FrameCancel, 0, 0)
    EndIf
    If *Peer\SendFile
      CloseFile(*Peer\SendFile)
      *Peer\SendFile = 0
    EndIf
    If *Peer\ReceiveFile
      CloseFile(*Peer\ReceiveFile)
      *Peer\ReceiveFile = 0
    EndIf
    *Peer\SendMode = #TransferNone
    *Peer\ReceiveMode = #TransferNone
    *Peer\WaitingUploadReady = 0
    *Peer\AwaitingTransferStatus = 0
    *Peer\BuildingTree = 0
    *Peer\SendPaused = 0
  Next
  TransfersPaused = #False
  SetGadgetText(#GadgetPause, "Pause")
  SetGadgetText(#GadgetProgressText, "Cancelled")
  SetGadgetState(#GadgetProgress, 0)
  AddLog("Transfers cancelled")
  AddHistory("Cancelled", "Session", "Queued transfers", "User cancelled transfers")
EndProcedure

Procedure QueueUploadItem(LocalPath$, RemotePath$, IsDirectory.i)
  AddElement(UploadQueue())
  UploadQueue()\LocalPath = LocalPath$
  UploadQueue()\RemotePath = RemotePath$
  UploadQueue()\IsDirectory = IsDirectory
  UploadQueue()\RetryCount = 0
  RefreshQueueViews()
EndProcedure

Procedure QueueDownloadItem(RemotePath$)
  AddElement(DownloadQueue())
  DownloadQueue()\RemotePath = NormalizeRelativePath(RemotePath$)
  DownloadQueue()\RetryCount = 0
  RefreshQueueViews()
EndProcedure

Procedure HandleUploadQueueFailure(Message$)
  If ListSize(UploadQueue()) <= 0
    AddLog(Message$)
    ProcedureReturn
  EndIf

  FirstElement(UploadQueue())
  If UploadQueue()\RetryCount < 2
    UploadQueue()\RetryCount + 1
    AddLog(Message$ + " - retry " + Str(UploadQueue()\RetryCount))
    AddHistory("Retry", "Upload", UploadQueue()\RemotePath, Message$)
  Else
    AddLog(Message$ + " - giving up")
    AddHistory("Failed", "Upload", UploadQueue()\RemotePath, Message$)
    DeleteElement(UploadQueue())
  EndIf
EndProcedure

Procedure HandleDownloadQueueFailure(Message$)
  If ListSize(DownloadQueue()) <= 0
    AddLog(Message$)
    ProcedureReturn
  EndIf

  FirstElement(DownloadQueue())
  If DownloadQueue()\RetryCount < 2
    DownloadQueue()\RetryCount + 1
    AddLog(Message$ + " - retry " + Str(DownloadQueue()\RetryCount))
    AddHistory("Retry", "Download", DownloadQueue()\RemotePath, Message$)
  Else
    AddLog(Message$ + " - giving up")
    AddHistory("Failed", "Download", DownloadQueue()\RemotePath, Message$)
    DeleteElement(DownloadQueue())
  EndIf
EndProcedure

Procedure.q DownloadResumeOffset(RemotePath$)
  Protected LocalPath$ = ResolveDownloadPath(RemotePath$)
  Protected ExistingSize.q

  If OverwriteMode() <> #OverwriteResume
    ProcedureReturn 0
  EndIf

  ExistingSize = FileSize(LocalPath$)
  If ExistingSize > 0
    ProcedureReturn ExistingSize
  EndIf

  ProcedureReturn 0
EndProcedure

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

  If Host$ = ""
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

Procedure.s RelativePathFromBase(BasePath$, FullPath$)
  Protected Base$ = TrimTrailingSlash(BasePath$)
  Protected Full$ = TrimTrailingSlash(FullPath$)

  If Left(Full$, Len(Base$)) <> Base$
    ProcedureReturn NormalizeRelativePath(GetFilePart(Full$))
  EndIf

  Full$ = Mid(Full$, Len(Base$) + 2)
  ProcedureReturn NormalizeRelativePath(ReplaceString(Full$, "\\", "/"))
EndProcedure

Procedure QueueUploadPathRecursive(LocalPath$, RemoteBase$)
  Protected EntryName$
  Protected LocalChild$
  Protected RemotePath$
  Protected Directory.i

  If FileSize(LocalPath$) = -2
    RemotePath$ = JoinRelativePath(RemoteBase$, GetFilePart(TrimTrailingSlash(LocalPath$)))
    If RemotePath$ <> #InvalidRelativePath And RemotePath$ <> ""
      QueueUploadItem(LocalPath$, RemotePath$, #True)
      Directory = ExamineDirectory(#PB_Any, LocalPath$, "*")
      If Directory
        While NextDirectoryEntry(Directory)
          EntryName$ = DirectoryEntryName(Directory)
          If EntryName$ <> "." And EntryName$ <> ".."
            LocalChild$ = TrimTrailingSlash(LocalPath$) + "\\" + EntryName$
            QueueUploadPathRecursive(LocalChild$, RemotePath$)
          EndIf
        Wend
        FinishDirectory(Directory)
      EndIf
    EndIf
  ElseIf FileSize(LocalPath$) >= 0
    RemotePath$ = JoinRelativePath(RemoteBase$, GetFilePart(LocalPath$))
    If RemotePath$ <> #InvalidRelativePath And RemotePath$ <> ""
      QueueUploadItem(LocalPath$, RemotePath$, #False)
    EndIf
  EndIf
EndProcedure

Procedure QueueUploadsFromDrop(DroppedFiles$, RemoteBase$)
  Protected Item$
  Protected Count.i

  While DroppedFiles$ <> ""
    Item$ = StringField(DroppedFiles$, 1, Chr(10))
    If Item$ <> ""
      QueueUploadPathRecursive(Item$, RemoteBase$)
      Count + 1
    EndIf
    If FindString(DroppedFiles$, Chr(10), 1)
      DroppedFiles$ = Mid(DroppedFiles$, FindString(DroppedFiles$, Chr(10), 1) + 1)
    Else
      DroppedFiles$ = ""
    EndIf
  Wend

  If Count > 0
    AddLog("Queued dropped file/folder item(s): " + Str(Count))
    RefreshQueueViews()
  EndIf
EndProcedure

Procedure SendTreeRecursive(Connection.i, RelativePath$)
  Protected LocalPath$ = ResolveSharePath(RelativePath$)
  Protected Directory.i
  Protected EntryName$
  Protected ChildRelative$
  Protected ChildPath$
  Protected EntryType.i
  Protected Payload$

  If LocalPath$ = "" Or FileSize(LocalPath$) <> -2
    ProcedureReturn
  EndIf

  Directory = ExamineDirectory(#PB_Any, LocalPath$, "*")
  If Directory
    While NextDirectoryEntry(Directory)
      EntryName$ = DirectoryEntryName(Directory)
      If EntryName$ <> "." And EntryName$ <> ".."
        ChildRelative$ = JoinRelativePath(RelativePath$, EntryName$)
        ChildPath$ = LocalPath$ + "\\" + EntryName$
        EntryType = DirectoryEntryType(Directory)
        If EntryType = #PB_DirectoryEntry_Directory
          Payload$ = "1" + Chr(31) + ChildRelative$ + Chr(31) + "0" + Chr(31) + Str(GetFileDate(ChildPath$, #PB_Date_Modified))
          SendTextFrame(Connection, #FrameTreeItem, Payload$)
          SendTreeRecursive(Connection, ChildRelative$)
        Else
          Payload$ = "0" + Chr(31) + ChildRelative$ + Chr(31) + Str(FileSize(ChildPath$)) + Chr(31) + Str(GetFileDate(ChildPath$, #PB_Date_Modified))
          SendTextFrame(Connection, #FrameTreeItem, Payload$)
        EndIf
      EndIf
    Wend
    FinishDirectory(Directory)
  EndIf
EndProcedure

Procedure TryStartNextDownload()
  Protected *Peer.PeerState
  Protected Payload$

  If TransfersPaused Or ActiveRemoteConnection = 0 Or ListSize(DownloadQueue()) = 0
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ProcedureReturn
  EndIf

  If *Peer\SendPaused Or *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone Or *Peer\WaitingUploadReady Or *Peer\BuildingTree
    ProcedureReturn
  EndIf

  FirstElement(DownloadQueue())
  *Peer\PendingDownloadPath = DownloadQueue()\RemotePath
  Payload$ = DownloadQueue()\RemotePath + Chr(31) + Str(DownloadResumeOffset(DownloadQueue()\RemotePath))
  SendTextFrame(*Peer\Connection, #FrameDownloadRequest, Payload$)
  AddLog("Requested download: " + DownloadQueue()\RemotePath)
EndProcedure

Procedure RemovePeer(Connection.i, CloseConnection.i)
  Protected *Peer.PeerState = GetPeer(Connection)

  If *Peer = 0
    ProcedureReturn
  EndIf

  If CloseConnection
    CloseNetworkConnection(Connection)
  EndIf

  If ActiveRemoteConnection = Connection
    ActiveRemoteConnection = 0
    ClearBrowser()
    SetGadgetText(#GadgetServerStatus, "Remote connection closed")
  EndIf

  FreePeerResources(*Peer)
  DeleteMapElement(Peers())
EndProcedure

Procedure UpdateProgressUI()
  Protected *Peer.PeerState
  Protected Percent.i
  Protected Message$ = "Idle"

  SetGadgetState(#GadgetProgress, 0)

  If ActiveRemoteConnection = 0
    SetGadgetText(#GadgetProgressText, Message$)
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    SetGadgetText(#GadgetProgressText, Message$)
    ProcedureReturn
  EndIf

  If *Peer\ReceiveMode <> #TransferNone And *Peer\ReceiveTotal > 0
    Percent = Int((*Peer\ReceiveDone * 1000) / *Peer\ReceiveTotal)
    SetGadgetState(#GadgetProgress, Percent)
    If *Peer\ReceiveMode = #TransferDownload
      Message$ = "Downloading " + GetFilePart(*Peer\ReceiveFinalPath) + "  " + FormatBytes(*Peer\ReceiveDone) + " / " + FormatBytes(*Peer\ReceiveTotal)
      UpdateTransferRow(#TransferRowDownload, *Peer\ReceiveRelativePath, *Peer\PeerName, *Peer\ReceiveRelativePath, *Peer\ReceiveTotal, "Transferring", Percent / 10)
    Else
      Message$ = "Receiving upload  " + FormatBytes(*Peer\ReceiveDone) + " / " + FormatBytes(*Peer\ReceiveTotal)
    EndIf
  ElseIf *Peer\SendMode <> #TransferNone And *Peer\SendTotal > 0
    Percent = Int((*Peer\SendDone * 1000) / *Peer\SendTotal)
    SetGadgetState(#GadgetProgress, Percent)
    If *Peer\SendMode = #TransferUpload
      Message$ = "Uploading " + GetFilePart(*Peer\PendingLocalUploadPath) + "  " + FormatBytes(*Peer\SendDone) + " / " + FormatBytes(*Peer\SendTotal)
      UpdateTransferRow(#TransferRowUpload, *Peer\SendRelativePath, *Peer\PeerHost, *Peer\PendingLocalUploadPath, *Peer\SendTotal, "Transferring", Percent / 10)
    Else
      Message$ = "Sending " + GetFilePart(*Peer\SendRelativePath) + "  " + FormatBytes(*Peer\SendDone) + " / " + FormatBytes(*Peer\SendTotal)
    EndIf
  ElseIf *Peer\WaitingUploadReady
    Message$ = "Waiting for remote upload slot"
  ElseIf TransfersPaused Or *Peer\SendPaused
    Message$ = "Paused"
  EndIf

  SetGadgetText(#GadgetProgressText, Message$)
EndProcedure

Procedure UpdateServerStatus()
  Protected Status$

  If ServerRunning
    Status$ = "Ready to receive on port " + GetGadgetText(#GadgetPort)
    SetGadgetText(#GadgetServerToggle, "Stop Server")
  Else
    Status$ = "Receiver is offline"
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

Procedure RequestRemoteList(RelativePath$)
  Protected *Peer.PeerState
  Protected Normalized$

  If ActiveRemoteConnection = 0
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ProcedureReturn
  EndIf

  Normalized$ = NormalizeRelativePath(RelativePath$)
  If Normalized$ = #InvalidRelativePath
    AddLog("Rejected invalid remote path request")
    ProcedureReturn
  EndIf

  *Peer\CurrentRemotePath = Normalized$
  SendTextFrame(*Peer\Connection, #FrameListRequest, Normalized$)
  SetGadgetText(#GadgetRemotePath, "/" + Normalized$)
  If Normalized$ = ""
    SetGadgetText(#GadgetRemotePath, "/")
  EndIf
EndProcedure

Procedure QueueUploads(RemoteDir$)
  Protected Pattern$ = "All files (*.*)|*.*"
  Protected File$
  Protected Count.i

  File$ = OpenFileRequester("Select files to upload", "", Pattern$, 0, #PB_Requester_MultiSelection)
  If File$ = ""
    ProcedureReturn
  EndIf

  While File$ <> ""
    If FileSize(File$) >= 0
      QueueUploadItem(File$, JoinRelativePath(RemoteDir$, GetFilePart(File$)), #False)
      Count + 1
    EndIf
    File$ = NextSelectedFileName()
  Wend

  If Count > 0
    AddLog("Queued " + Str(Count) + " file(s) for upload")
  EndIf
EndProcedure

Procedure TryStartNextUpload()
  Protected *Peer.PeerState
  Protected FileSizeValue.q
  Protected Modified.q
  Protected Payload$

  If ActiveRemoteConnection = 0 And CurrentQueuedTargetHost$ <> "" And CurrentQueuedTargetPort > 0
    SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
    SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
    ConnectRemote()
  EndIf

  If TransfersPaused Or ActiveRemoteConnection = 0 Or ListSize(UploadQueue()) = 0
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ProcedureReturn
  EndIf

  If *Peer\SendPaused Or *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone Or *Peer\WaitingUploadReady Or *Peer\AwaitingTransferStatus
    ProcedureReturn
  EndIf

  FirstElement(UploadQueue())
  FileSizeValue = FileSize(UploadQueue()\LocalPath)
  If FileSizeValue < 0
    AddLog("Skipped missing file: " + UploadQueue()\LocalPath)
    DeleteElement(UploadQueue())
    TryStartNextUpload()
    ProcedureReturn
  EndIf

  If UploadQueue()\IsDirectory
    SendTextFrame(*Peer\Connection, #FrameCreateDir, UploadQueue()\RemotePath)
    AddLog("Creating remote folder: " + UploadQueue()\RemotePath)
    DeleteElement(UploadQueue())
    TryStartNextUpload()
    ProcedureReturn
  EndIf

  Modified = GetFileDate(UploadQueue()\LocalPath, #PB_Date_Modified)
  Payload$ = ParentRelativePath(UploadQueue()\RemotePath) + Chr(31) + GetFilePart(UploadQueue()\RemotePath) + Chr(31) + Str(FileSizeValue) + Chr(31) + Str(Modified) + Chr(31) + *Peer\SendChecksum

  *Peer\WaitingUploadReady = #True
  *Peer\PendingLocalUploadPath = UploadQueue()\LocalPath
  *Peer\PendingRemoteTargetDir = ParentRelativePath(UploadQueue()\RemotePath)
  *Peer\SendChecksum = FileSHA256(UploadQueue()\LocalPath)
  SendTextFrame(*Peer\Connection, #FrameUploadBegin, Payload$)
  UpdateProgressUI()
EndProcedure

Procedure StartRemoteDownload(RelativePath$)
  Protected *Peer.PeerState
  Protected Normalized$ = NormalizeRelativePath(RelativePath$)
  Protected Index.i

  If ActiveRemoteConnection = 0 Or Normalized$ = #InvalidRelativePath Or Normalized$ = ""
    ProcedureReturn
  EndIf

  *Peer = GetPeer(ActiveRemoteConnection)
  If *Peer = 0
    ProcedureReturn
  EndIf

  If *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone Or *Peer\WaitingUploadReady
    AddLog("Transfer busy, wait for the current job to finish")
    ProcedureReturn
  EndIf

  Index = GetGadgetState(#GadgetRemoteList)
  If Index >= 0 And Index <= ArraySize(RemoteEntryIsDirectory()) And RemoteEntryIsDirectory(Index)
    SendTextFrame(*Peer\Connection, #FrameTreeRequest, Normalized$)
    *Peer\BuildingTree = #True
    AddLog("Requested recursive folder download: " + Normalized$)
  Else
    QueueDownloadItem(Normalized$)
    TryStartNextDownload()
  EndIf
EndProcedure

Procedure HandleListSend(Connection.i, RelativePath$)
  Protected LocalPath$ = ResolveSharePath(RelativePath$)
  Protected Directory.i
  Protected EntryName$
  Protected EntryRelative$
  Protected EntryPath$
  Protected EntryType.i
  Protected Size.q
  Protected Modified.q
  Protected Payload$

  If LocalPath$ = "" Or FileSize(LocalPath$) <> -2
    SendError(Connection, "Folder not found")
    ProcedureReturn
  EndIf

  SendTextFrame(Connection, #FrameListBegin, RelativePath$ + Chr(31) + BuildShareName())

  Directory = ExamineDirectory(#PB_Any, LocalPath$, "*")
  If Directory
    While NextDirectoryEntry(Directory)
      EntryName$ = DirectoryEntryName(Directory)
      If EntryName$ <> "." And EntryName$ <> ".."
        EntryType = DirectoryEntryType(Directory)
        EntryRelative$ = JoinRelativePath(RelativePath$, EntryName$)
        EntryPath$ = LocalPath$ + "\\" + EntryName$
        If EntryType = #PB_DirectoryEntry_File
          Size = FileSize(EntryPath$)
        Else
          Size = 0
        EndIf
        Modified = GetFileDate(EntryPath$, #PB_Date_Modified)
        Payload$ = Str(Bool(EntryType = #PB_DirectoryEntry_Directory)) + Chr(31) + EntryName$ + Chr(31) + EntryRelative$ + Chr(31) + Str(Size) + Chr(31) + Str(Modified)
        SendTextFrame(Connection, #FrameListItem, Payload$)
      EndIf
    Wend
    FinishDirectory(Directory)
  EndIf

  SendTextFrame(Connection, #FrameListEnd, RelativePath$)
EndProcedure

Procedure StartSendingFile(*Peer.PeerState, RelativePath$)
  Protected LocalPath$ = ResolveSharePath(RelativePath$)
  Protected Payload$
  Protected ResumeOffset.q

  If LocalPath$ = "" Or FileSize(LocalPath$) < 0
    SendError(*Peer\Connection, "File not found")
    ProcedureReturn
  EndIf

  If *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone
    SendError(*Peer\Connection, "Connection is busy")
    ProcedureReturn
  EndIf

  If FileSize(LocalPath$) = -2
    SendTextFrame(*Peer\Connection, #FrameTreeBegin, RelativePath$)
    SendTreeRecursive(*Peer\Connection, RelativePath$)
    SendTextFrame(*Peer\Connection, #FrameTreeEnd, RelativePath$)
    ProcedureReturn
  EndIf

  *Peer\SendFile = ReadFile(#PB_Any, LocalPath$, #PB_File_SharedRead)
  If *Peer\SendFile = 0
    SendError(*Peer\Connection, "Failed to open file for reading")
    ProcedureReturn
  EndIf

  ResumeOffset = Val(StringField(*Peer\PendingDownloadPath, 2, Chr(31)))
  If ResumeOffset > 0 And ResumeOffset < FileSize(LocalPath$)
    FileSeek(*Peer\SendFile, ResumeOffset)
  Else
    ResumeOffset = 0
  EndIf

  *Peer\SendMode = #TransferDownload
  *Peer\SendRelativePath = RelativePath$
  *Peer\SendTotal = FileSize(LocalPath$)
  *Peer\SendDone = ResumeOffset
  *Peer\SendModified = GetFileDate(LocalPath$, #PB_Date_Modified)
  *Peer\SendChecksum = FileSHA256(LocalPath$)
  Payload$ = RelativePath$ + Chr(31) + Str(*Peer\SendTotal) + Chr(31) + Str(*Peer\SendModified) + Chr(31) + Str(ResumeOffset) + Chr(31) + *Peer\SendChecksum
  SendTextFrame(*Peer\Connection, #FrameFileBegin, Payload$)
EndProcedure

Procedure StartReceivingUpload(*Peer.PeerState, TargetDir$, FileName$, Size.q, Modified.q)
  Protected RelativePath$
  Protected LocalPath$
  Protected ParentDir$
  Protected FileHandle.i
  Protected ExistingSize.q

  If *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone
    SendError(*Peer\Connection, "Connection is busy")
    ProcedureReturn
  EndIf

  RelativePath$ = JoinRelativePath(TargetDir$, FileName$)
  If RelativePath$ = #InvalidRelativePath Or RelativePath$ = ""
    SendError(*Peer\Connection, "Invalid upload target")
    ProcedureReturn
  EndIf

  LocalPath$ = ResolveSharePath(RelativePath$)
  If LocalPath$ = ""
    SendError(*Peer\Connection, "Upload target rejected")
    ProcedureReturn
  EndIf

  ParentDir$ = GetPathPart(LocalPath$)
  EnsureDirectoryExists(ParentDir$)

  ExistingSize = FileSize(LocalPath$)
  LocalPath$ = ResolveTargetPath(LocalPath$, #True)
  If LocalPath$ = ""
    SendStatus(*Peer\Connection, "Skipped existing upload target: " + RelativePath$)
    ProcedureReturn
  EndIf

  If ExistingSize >= 0 And OverwriteMode() = #OverwriteResume And ExistingSize < Size
    FileHandle = OpenFile(#PB_Any, LocalPath$)
    If FileHandle
      FileSeek(FileHandle, ExistingSize)
      *Peer\ReceiveDone = ExistingSize
    EndIf
  Else
    FileHandle = CreateFile(#PB_Any, LocalPath$)
    *Peer\ReceiveDone = 0
  EndIf

  If FileHandle = 0
    SendError(*Peer\Connection, "Unable to create destination file")
    ProcedureReturn
  EndIf

  *Peer\ReceiveFile = FileHandle
  *Peer\ReceiveMode = #TransferUpload
  *Peer\ReceiveRelativePath = NormalizeRelativePath(ReplaceString(Mid(LocalPath$, Len(TrimTrailingSlash(SharePath$)) + 2), "\\", "/"))
  *Peer\ReceiveFinalPath = LocalPath$
  *Peer\ReceiveTotal = Size
  *Peer\ReceiveModified = Modified
  *Peer\ReceiveExpectedChecksum = ""
  SendTextFrame(*Peer\Connection, #FrameUploadReady, *Peer\ReceiveRelativePath)
  AddLog("Receiving upload from " + *Peer\PeerHost + ": " + *Peer\ReceiveRelativePath)
EndProcedure

Procedure HandleHello(*Peer.PeerState, Payload$)
  Protected RemoteName$ = StringField(Payload$, 1, Chr(31))
  Protected ShareName$ = StringField(Payload$, 2, Chr(31))

  If RemoteName$ <> ""
    *Peer\PeerName = RemoteName$
  EndIf
  If ShareName$ <> ""
    *Peer\RemoteShareName = ShareName$
  EndIf

  If *Peer\IsOutgoing
    AddLog("Connected to " + *Peer\PeerName + " | Share: " + *Peer\RemoteShareName)
  Else
    AddLog("Incoming connection from " + *Peer\PeerName + " (" + *Peer\PeerHost + ")")
  EndIf
EndProcedure

Procedure FinalizeReceivedFile(*Peer.PeerState)
  Protected ChecksumOK.i = #True

  If *Peer\ReceiveFile
    CloseFile(*Peer\ReceiveFile)
    *Peer\ReceiveFile = 0
  EndIf

  If *Peer\ReceiveMode = #TransferDownload And *Peer\ReceiveFinalPath <> ""
    *Peer\ReceiveActualChecksum = FileSHA256(*Peer\ReceiveFinalPath)
    If *Peer\ReceiveExpectedChecksum <> "" And LCase(*Peer\ReceiveExpectedChecksum) <> LCase(*Peer\ReceiveActualChecksum)
      ChecksumOK = #False
    EndIf
  EndIf

  If *Peer\ReceiveMode = #TransferDownload
    If ChecksumOK
      AddLog("Download complete: " + *Peer\ReceiveFinalPath)
      AddHistory("OK", "Download", *Peer\ReceiveRelativePath, "SHA-256 verified")
      UpdateTransferRow(#TransferRowDownload, *Peer\ReceiveRelativePath, *Peer\PeerName, *Peer\ReceiveRelativePath, *Peer\ReceiveTotal, "Completed", 100)
    Else
      AddLog("Checksum mismatch: " + *Peer\ReceiveFinalPath)
      AddHistory("Failed", "Download", *Peer\ReceiveRelativePath, "SHA-256 mismatch")
      UpdateTransferRow(#TransferRowDownload, *Peer\ReceiveRelativePath, *Peer\PeerName, *Peer\ReceiveRelativePath, *Peer\ReceiveTotal, "Failed", 0)
    EndIf
    RequestRemoteList(*Peer\CurrentRemotePath)
    If *Peer\IsOutgoing And ListSize(DownloadQueue()) > 0
      FirstElement(DownloadQueue())
      DeleteElement(DownloadQueue())
      TryStartNextDownload()
    EndIf
  ElseIf *Peer\ReceiveMode = #TransferUpload
    *Peer\ReceiveActualChecksum = FileSHA256(*Peer\ReceiveFinalPath)
    If *Peer\ReceiveExpectedChecksum <> "" And LCase(*Peer\ReceiveExpectedChecksum) = LCase(*Peer\ReceiveActualChecksum)
      AddLog("Upload saved to share: " + *Peer\ReceiveRelativePath)
      AddHistory("OK", "Upload", *Peer\ReceiveRelativePath, "Remote SHA-256 verified")
      UpdateTransferRow(#TransferRowUpload, *Peer\ReceiveRelativePath, *Peer\PeerHost, *Peer\ReceiveRelativePath, *Peer\ReceiveTotal, "Completed", 100)
      SendTextFrame(*Peer\Connection, #FrameUploadVerify, *Peer\ReceiveRelativePath + Chr(31) + *Peer\ReceiveActualChecksum)
    Else
      AddLog("Upload checksum mismatch on remote side: " + *Peer\ReceiveRelativePath)
      AddHistory("Failed", "Upload", *Peer\ReceiveRelativePath, "Remote SHA-256 mismatch")
      UpdateTransferRow(#TransferRowUpload, *Peer\ReceiveRelativePath, *Peer\PeerHost, *Peer\ReceiveRelativePath, *Peer\ReceiveTotal, "Failed", 0)
      SendError(*Peer\Connection, "Upload checksum mismatch: " + *Peer\ReceiveRelativePath)
    EndIf
  EndIf

  *Peer\ReceiveMode = #TransferNone
  *Peer\ReceiveTotal = 0
  *Peer\ReceiveDone = 0
  *Peer\ReceiveRelativePath = ""
  *Peer\ReceiveFinalPath = ""
  *Peer\ReceiveModified = 0
  *Peer\ReceiveExpectedChecksum = ""
  *Peer\ReceiveActualChecksum = ""
  UpdateProgressUI()
EndProcedure

Procedure HandleTextFrame(*Peer.PeerState, FrameType.i, Payload$)
  Protected RelativePath$
  Protected EntryName$
  Protected EntrySize.q
  Protected EntryModified.q
  Protected IsDirectory.i
  Protected LocalTarget$
  Protected ParentDir$
  Protected FileHandle.i
  Protected UploadFileSize.q
  Protected UploadModified.q
  Protected SavedRelative$

  Select FrameType
    Case #FrameHello
      HandleHello(*Peer, Payload$)
      If *Peer\IsDiscovery
        AddDiscoveryHost(*Peer\PeerHost, Val(GetGadgetText(#GadgetPort)), *Peer\PeerName, *Peer\RemoteShareName)
        RemovePeer(*Peer\Connection, #True)
        ProcedureReturn
      EndIf

    Case #FrameListRequest
      HandleListSend(*Peer\Connection, NormalizeRelativePath(Payload$))

    Case #FrameListBegin
      *Peer\BuildingList = #True
      *Peer\CurrentRemotePath = NormalizeRelativePath(StringField(Payload$, 1, Chr(31)))
      *Peer\RemoteShareName = StringField(Payload$, 2, Chr(31))
      ClearList(BrowserEntries())
      SetGadgetText(#GadgetRemotePath, "/" + *Peer\CurrentRemotePath)
      If *Peer\CurrentRemotePath = ""
        SetGadgetText(#GadgetRemotePath, "/")
      EndIf

    Case #FrameListItem
      If *Peer\IsOutgoing And *Peer\BuildingList
        AddElement(BrowserEntries())
        IsDirectory = Val(StringField(Payload$, 1, Chr(31)))
        EntryName$ = StringField(Payload$, 2, Chr(31))
        RelativePath$ = NormalizeRelativePath(StringField(Payload$, 3, Chr(31)))
        EntrySize = Val(StringField(Payload$, 4, Chr(31)))
        EntryModified = Val(StringField(Payload$, 5, Chr(31)))

        BrowserEntries()\Name = EntryName$
        BrowserEntries()\RelativePath = RelativePath$
        BrowserEntries()\IsDirectory = IsDirectory
        BrowserEntries()\Size = EntrySize
        BrowserEntries()\Modified = EntryModified
      EndIf

    Case #FrameListEnd
      If *Peer\IsOutgoing
        *Peer\BuildingList = #False
        RefreshBrowserGadget()
      EndIf

    Case #FrameDownloadRequest
      *Peer\PendingDownloadPath = Payload$
      StartSendingFile(*Peer, NormalizeRelativePath(StringField(Payload$, 1, Chr(31))))

    Case #FrameTreeRequest
      *Peer\BuildingTree = #False
      SendTextFrame(*Peer\Connection, #FrameTreeBegin, NormalizeRelativePath(Payload$))
      SendTreeRecursive(*Peer\Connection, NormalizeRelativePath(Payload$))
      SendTextFrame(*Peer\Connection, #FrameTreeEnd, NormalizeRelativePath(Payload$))

    Case #FrameUploadBegin
      RelativePath$ = NormalizeRelativePath(StringField(Payload$, 1, Chr(31)))
      EntryName$ = GetFilePart(StringField(Payload$, 2, Chr(31)))
      UploadFileSize = Val(StringField(Payload$, 3, Chr(31)))
      UploadModified = Val(StringField(Payload$, 4, Chr(31)))
      StartReceivingUpload(*Peer, RelativePath$, EntryName$, UploadFileSize, UploadModified)
      *Peer\ReceiveExpectedChecksum = StringField(Payload$, 5, Chr(31))

    Case #FrameUploadReady
      If *Peer\WaitingUploadReady
        *Peer\SendFile = ReadFile(#PB_Any, *Peer\PendingLocalUploadPath, #PB_File_SharedRead)
        If *Peer\SendFile = 0
          *Peer\WaitingUploadReady = #False
          SendError(*Peer\Connection, "Local file could not be opened")
          HandleUploadQueueFailure("Upload failed to open local file: " + *Peer\PendingLocalUploadPath)
          TryStartNextUpload()
          ProcedureReturn
        EndIf

        *Peer\SendMode = #TransferUpload
        *Peer\SendRelativePath = NormalizeRelativePath(Payload$)
        *Peer\SendTotal = FileSize(*Peer\PendingLocalUploadPath)
        If OverwriteMode() = #OverwriteResume And FileSize(*Peer\PendingLocalUploadPath) > 0
          *Peer\SendDone = 0
        Else
          *Peer\SendDone = 0
        EndIf
        *Peer\SendModified = GetFileDate(*Peer\PendingLocalUploadPath, #PB_Date_Modified)
        *Peer\WaitingUploadReady = #False
        *Peer\AwaitingTransferStatus = #True
        *Peer\AwaitingUploadVerify = #True
        AddLog("Uploading to remote share: " + *Peer\SendRelativePath)
      EndIf

    Case #FrameFileBegin
      RelativePath$ = NormalizeRelativePath(StringField(Payload$, 1, Chr(31)))
      EntrySize = Val(StringField(Payload$, 2, Chr(31)))
      EntryModified = Val(StringField(Payload$, 3, Chr(31)))
      *Peer\ReceiveExpectedChecksum = StringField(Payload$, 5, Chr(31))
      LocalTarget$ = ResolveDownloadPath(RelativePath$)
      If LocalTarget$ = ""
        SendError(*Peer\Connection, "Invalid local download path")
        ProcedureReturn
      EndIf

      ParentDir$ = GetPathPart(LocalTarget$)
      EnsureDirectoryExists(ParentDir$)
      LocalTarget$ = ResolveTargetPath(LocalTarget$, #True)
      If LocalTarget$ = ""
        SendStatus(*Peer\Connection, "Skipped existing download target: " + RelativePath$)
        ProcedureReturn
      EndIf

      If FileSize(LocalTarget$) >= 0 And OverwriteMode() = #OverwriteResume And FileSize(LocalTarget$) < EntrySize
        FileHandle = OpenFile(#PB_Any, LocalTarget$)
        If FileHandle
          FileSeek(FileHandle, FileSize(LocalTarget$))
        EndIf
      Else
        FileHandle = CreateFile(#PB_Any, LocalTarget$)
      EndIf
      If FileHandle = 0
        SendError(*Peer\Connection, "Could not create local download file")
        ProcedureReturn
      EndIf

      *Peer\ReceiveFile = FileHandle
      *Peer\ReceiveMode = #TransferDownload
      *Peer\ReceiveRelativePath = RelativePath$
      *Peer\ReceiveFinalPath = LocalTarget$
      *Peer\ReceiveTotal = EntrySize
      If OverwriteMode() = #OverwriteResume And FileSize(LocalTarget$) >= 0 And FileSize(LocalTarget$) < EntrySize
        *Peer\ReceiveDone = FileSize(LocalTarget$)
      Else
        *Peer\ReceiveDone = 0
      EndIf
      *Peer\ReceiveModified = EntryModified
      *Peer\ReceiveActualChecksum = ""
      AddLog("Downloading to " + LocalTarget$)

    Case #FrameTreeBegin
      *Peer\BuildingTree = #True
      AddLog("Building recursive download list for: " + NormalizeRelativePath(Payload$))

    Case #FrameTreeItem
      IsDirectory = Val(StringField(Payload$, 1, Chr(31)))
      RelativePath$ = NormalizeRelativePath(StringField(Payload$, 2, Chr(31)))
      LocalTarget$ = ResolveDownloadPath(RelativePath$)
      If IsDirectory
        If LocalTarget$ <> ""
          EnsureDirectoryExists(LocalTarget$)
        EndIf
      Else
        QueueDownloadItem(RelativePath$)
      EndIf

    Case #FrameTreeEnd
      *Peer\BuildingTree = #False
      TryStartNextDownload()

    Case #FrameCreateDir
      RelativePath$ = NormalizeRelativePath(Payload$)
      If RelativePath$ <> #InvalidRelativePath And RelativePath$ <> ""
        LocalTarget$ = ResolveSharePath(RelativePath$)
        If LocalTarget$ <> ""
          EnsureDirectoryExists(LocalTarget$)
          SendStatus(*Peer\Connection, "Created folder: " + RelativePath$)
        EndIf
      EndIf

    Case #FrameUploadVerify
      RelativePath$ = NormalizeRelativePath(StringField(Payload$, 1, Chr(31)))
      SavedRelative$ = StringField(Payload$, 2, Chr(31))
      If *Peer\AwaitingUploadVerify
        *Peer\AwaitingUploadVerify = #False
        If LCase(SavedRelative$) = LCase(*Peer\SendChecksum)
          AddLog("Upload verified by remote host: " + RelativePath$)
          AddHistory("OK", "Upload", RelativePath$, "End-to-end SHA-256 verified")
        Else
          AddLog("Upload verification failed: " + RelativePath$)
          AddHistory("Failed", "Upload", RelativePath$, "End-to-end SHA-256 mismatch")
        EndIf
      EndIf

    Case #FramePause
      *Peer\SendPaused = #True

    Case #FrameResume
      *Peer\SendPaused = #False

    Case #FrameCancel
      If *Peer\SendFile
        CloseFile(*Peer\SendFile)
        *Peer\SendFile = 0
      EndIf
      If *Peer\ReceiveFile
        CloseFile(*Peer\ReceiveFile)
        *Peer\ReceiveFile = 0
      EndIf
      *Peer\SendMode = #TransferNone
      *Peer\ReceiveMode = #TransferNone
      *Peer\WaitingUploadReady = 0
      *Peer\AwaitingTransferStatus = 0
      *Peer\BuildingTree = 0

    Case #FrameFileEnd
      FinalizeReceivedFile(*Peer)
      If *Peer\IsOutgoing And ListSize(UploadQueue()) > 0
        FirstElement(UploadQueue())
        DeleteElement(UploadQueue())
        TryStartNextUpload()
      EndIf

    Case #FrameStatus
      AddLog(Payload$)
      If *Peer\IsOutgoing And *Peer\AwaitingTransferStatus
        *Peer\AwaitingTransferStatus = #False
        If *Peer\AwaitingUploadVerify = 0
          RequestRemoteList(*Peer\CurrentRemotePath)
          If ListSize(UploadQueue()) > 0
            FirstElement(UploadQueue())
            DeleteElement(UploadQueue())
            TryStartNextUpload()
          EndIf
        EndIf
      EndIf
      If ActiveRemoteConnection And ListSize(UploadQueue()) = 0 And CurrentQueuedTargetHost$ <> ""
        CurrentQueuedTargetHost$ = ""
        CurrentQueuedTargetPort = 0
        DisconnectRemote()
      EndIf

    Case #FrameError
      AddLog("Remote error: " + Payload$)
      If *Peer\IsOutgoing
        If *Peer\BuildingTree
          *Peer\BuildingTree = #False
        EndIf
        If *Peer\WaitingUploadReady And ListSize(UploadQueue()) > 0
          *Peer\WaitingUploadReady = #False
          HandleUploadQueueFailure("Upload queue item failed")
          TryStartNextUpload()
        ElseIf ListSize(DownloadQueue()) > 0
          HandleDownloadQueueFailure("Download queue item failed")
          TryStartNextDownload()
        EndIf
        *Peer\AwaitingTransferStatus = #False
      EndIf
  EndSelect

  UpdateProgressUI()
EndProcedure

Procedure HandleBinaryFrame(*Peer.PeerState, FrameType.i, *Payload, PayloadLength.i)
  If FrameType = #FrameFileChunk And PayloadLength > 0
    If *Peer\ReceiveMode <> #TransferNone And *Peer\ReceiveFile
      WriteData(*Peer\ReceiveFile, *Payload, PayloadLength)
      *Peer\ReceiveDone + PayloadLength
      UpdateProgressUI()
    EndIf
  EndIf
EndProcedure

Procedure ProcessFrame(*Peer.PeerState, FrameType.i, *Payload, PayloadLength.i)
  Protected PayloadText$

  Select FrameType
    Case #FrameFileChunk
      HandleBinaryFrame(*Peer, FrameType, *Payload, PayloadLength)

    Default
      PayloadText$ = PayloadToString(*Payload, PayloadLength)
      HandleTextFrame(*Peer, FrameType, PayloadText$)
  EndSelect
EndProcedure

Procedure ParsePeerBuffer(*Peer.PeerState)
  Protected FrameType.i
  Protected PayloadLength.i
  Protected Consumed.i
  Protected Remaining.i

  While *Peer\InputSize >= 16
    If PeekL(*Peer\InputBuffer) <> #ProtocolMagic
      AddLog("Protocol error from " + *Peer\PeerHost)
      RemovePeer(*Peer\Connection, #True)
      ProcedureReturn
    EndIf

    FrameType = PeekL(*Peer\InputBuffer + 4)
    PayloadLength = PeekQ(*Peer\InputBuffer + 8)
    If PayloadLength < 0 Or PayloadLength > #ProtocolMaxPayload
      AddLog("Rejected oversized frame from " + *Peer\PeerHost)
      RemovePeer(*Peer\Connection, #True)
      ProcedureReturn
    EndIf

    Consumed = 16 + PayloadLength
    If *Peer\InputSize < Consumed
      Break
    EndIf

    ProcessFrame(*Peer, FrameType, *Peer\InputBuffer + 16, PayloadLength)

    Remaining = *Peer\InputSize - Consumed
    If Remaining > 0
      MoveMemory(*Peer\InputBuffer + Consumed, *Peer\InputBuffer, Remaining)
    EndIf
    *Peer\InputSize = Remaining
  Wend
EndProcedure

Procedure ReceivePeerData(*Peer.PeerState)
  Protected *Buffer = AllocateMemory(#ChunkSize)
  Protected Received.i

  If *Buffer = 0
    ProcedureReturn
  EndIf

  Repeat
    Received = ReceiveNetworkData(*Peer\Connection, *Buffer, #ChunkSize)
    If Received > 0
      AppendPeerBuffer(*Peer, *Buffer, Received)
    EndIf
  Until Received <> #ChunkSize

  FreeMemory(*Buffer)
  ParsePeerBuffer(*Peer)
EndProcedure

Procedure PumpOutgoingTransfer(*Peer.PeerState)
  Protected *Buffer
  Protected ToRead.i
  Protected BytesRead.i

  If TransfersPaused Or *Peer\SendPaused Or *Peer\SendMode = #TransferNone Or *Peer\SendFile = 0
    ProcedureReturn
  EndIf

  If *Peer\SendDone >= *Peer\SendTotal
    CloseFile(*Peer\SendFile)
    *Peer\SendFile = 0
    SendFrame(*Peer\Connection, #FrameFileEnd, 0, 0)
    *Peer\SendMode = #TransferNone
    *Peer\SendTotal = 0
    *Peer\SendDone = 0
    If *Peer\IsOutgoing = 0
      SendStatus(*Peer\Connection, "Download complete: " + *Peer\SendRelativePath)
    EndIf
    *Peer\SendRelativePath = ""
    UpdateProgressUI()
    ProcedureReturn
  EndIf

  ToRead = #ChunkSize
  If *Peer\SendTotal - *Peer\SendDone < ToRead
    ToRead = *Peer\SendTotal - *Peer\SendDone
  EndIf

  *Buffer = AllocateMemory(ToRead)
  If *Buffer = 0
    ProcedureReturn
  EndIf

  BytesRead = ReadData(*Peer\SendFile, *Buffer, ToRead)
  If BytesRead > 0
    If SendFrame(*Peer\Connection, #FrameFileChunk, *Buffer, BytesRead)
      *Peer\SendDone + BytesRead
    EndIf
  EndIf
  FreeMemory(*Buffer)

  UpdateProgressUI()
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

  DownloadPath$ = TrimTrailingSlash(GetGadgetText(#GadgetDownloadPath))
  SharePath$ = DownloadPath$
  EnsureDirectoryExists(DownloadPath$)

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
  AddLog("Connected to receiver " + Host$ + ":" + Str(Port))
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

Procedure HandleRemoteDoubleClick()
  Protected Index.i = GetGadgetState(#GadgetRemoteList)
  Protected RelativePath$

  If Index < 0 Or Index > ArraySize(RemoteEntryPath$())
    ProcedureReturn
  EndIf

  RelativePath$ = RemoteEntryPath$(Index)
  If RemoteEntryIsDirectory(Index)
    RequestRemoteList(RelativePath$)
  Else
    StartRemoteDownload(RelativePath$)
  EndIf
EndProcedure

Procedure HandleDownloadButton()
  If SelectedRemoteItemPath() = ""
    MessageRequester(#APP_NAME, "Select a remote file first.")
    ProcedureReturn
  EndIf

  StartRemoteDownload(SelectedRemoteItemPath())
EndProcedure

Procedure OpenMainWindow()
  OpenWindow(#WindowMain, 0, 0, 980, 700, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)

  StringGadget(#GadgetSharePath, 0, 0, 0, 0, "")
  StringGadget(#GadgetDownloadPath, 0, 0, 0, 0, "")
  StringGadget(#GadgetPort, 0, 0, 0, 0, "50505", #PB_String_Numeric)
  StringGadget(#GadgetRemoteHost, 0, 0, 0, 0, "")
  ComboBoxGadget(#GadgetOverwrite, 0, 0, 0, 0)
  AddGadgetItem(#GadgetOverwrite, -1, "Keep both")
  AddGadgetItem(#GadgetOverwrite, -1, "Replace")
  AddGadgetItem(#GadgetOverwrite, -1, "Skip")
  AddGadgetItem(#GadgetOverwrite, -1, "Resume if partial")
  SetGadgetState(#GadgetOverwrite, #OverwriteKeepBoth)

  TextGadget(#GadgetShareLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetShareBrowse, 0, 0, 0, 0, "")
  TextGadget(#GadgetDownloadLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadBrowse, 0, 0, 0, 0, "")
  TextGadget(#GadgetPortLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetServerToggle, 0, 0, 0, 0, "")
  TextGadget(#GadgetRemoteHostLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetConnect, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDisconnect, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetRefresh, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetParent, 0, 0, 0, 0, "")
  TextGadget(#GadgetOverwriteLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUpload, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownload, 0, 0, 0, 0, "")
  TextGadget(#GadgetRemotePathLabel, 0, 0, 0, 0, "")
  StringGadget(#GadgetRemotePath, 0, 0, 0, 0, "/", #PB_String_ReadOnly)
  ListViewGadget(#GadgetUploadQueue, 0, 0, 0, 0)
  ButtonGadget(#GadgetUploadUp, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUploadDown, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUploadRemove, 0, 0, 0, 0, "")
  ListViewGadget(#GadgetDownloadQueue, 0, 0, 0, 0)
  ButtonGadget(#GadgetDownloadUp, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadDown, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadRemove, 0, 0, 0, 0, "")
  ListIconGadget(#GadgetRemoteList, 0, 0, 0, 0, "", 10)
  ListIconGadget(#GadgetHistory, 0, 0, 0, 0, "", 10)
  EditorGadget(#GadgetLog, 0, 0, 0, 0, #PB_Editor_ReadOnly)
  HideGadget(#GadgetSharePath, #True)
  HideGadget(#GadgetDownloadPath, #True)
  HideGadget(#GadgetPort, #True)
  HideGadget(#GadgetRemoteHost, #True)
  HideGadget(#GadgetOverwrite, #True)

  TextGadget(#PB_Any, 20, 18, 300, 28, "LAN Share")
  ButtonGadget(#GadgetQuickSendFiles, 20, 58, 180, 42, "Send Files")
  ButtonGadget(#GadgetQuickSendFolder, 214, 58, 180, 42, "Send Folder")
  ButtonGadget(#GadgetScan, 408, 58, 140, 42, "Find Receivers")
  ButtonGadget(#GadgetQuickSettings, 562, 58, 110, 42, "Settings")
  ButtonGadget(#GadgetPause, 686, 58, 90, 42, "Pause")
  ButtonGadget(#GadgetCancel, 790, 58, 90, 42, "Cancel")
  ButtonGadget(#GadgetQuickExit, 894, 58, 56, 42, "Exit")

  TextGadget(#GadgetServerStatus, 20, 112, 930, 22, "Ready to receive")
  TextGadget(#GadgetLocalIPs, 20, 136, 930, 22, "")
  TextGadget(#GadgetDiscoveryLabel, 20, 170, 160, 20, "Available Receivers")
  CheckBoxGadget(#GadgetDiscoveryPeersOnly, 180, 168, 120, 20, "Peers only")
  ButtonGadget(#GadgetCopyInfo, 308, 164, 100, 28, "Copy Info")
  ListIconGadget(#GadgetDiscovery, 20, 198, 430, 140, "Receiver", 230, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetDiscovery, 1, "Type", 130)
  AddGadgetColumn(#GadgetDiscovery, 2, "Port", 60)

  TextGadget(#GadgetDetailsTitle, 474, 170, 160, 20, "Selected Receiver")
  TextGadget(#GadgetDetailsHost, 474, 198, 460, 18, "Host: -")
  TextGadget(#GadgetDetailsType, 474, 220, 460, 18, "Type: -")
  TextGadget(#GadgetDetailsPort, 474, 242, 460, 18, "Port: -")
  TextGadget(#GadgetDetailsMac, 474, 264, 460, 18, "MAC: -")
  TextGadget(#GadgetDetailsVendor, 474, 286, 460, 18, "Vendor: -")
  TextGadget(#GadgetDetailsState, 474, 308, 460, 18, "State: -")

  TextGadget(#GadgetQueueLabel, 20, 356, 200, 20, "Transfers")
  ListIconGadget(#GadgetQuickUploads, 20, 382, 930, 110, "Peer", 140, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetQuickUploads, 1, "File path", 420)
  AddGadgetColumn(#GadgetQuickUploads, 2, "Size", 90)
  AddGadgetColumn(#GadgetQuickUploads, 3, "Status", 120)
  AddGadgetColumn(#GadgetQuickUploads, 4, "Progress", 120)
  TextGadget(#PB_Any, 20, 500, 160, 20, "Incoming / Downloads")
  ListIconGadget(#GadgetQuickDownloads, 20, 526, 930, 110, "Peer", 140, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetQuickDownloads, 1, "File path", 420)
  AddGadgetColumn(#GadgetQuickDownloads, 2, "Size", 90)
  AddGadgetColumn(#GadgetQuickDownloads, 3, "Status", 120)
  AddGadgetColumn(#GadgetQuickDownloads, 4, "Progress", 120)
  TextGadget(#GadgetProgressText, 20, 648, 930, 18, "Idle")
  ProgressBarGadget(#GadgetProgress, 20, 670, 930, 16, 0, 1000)

  ApplySimpleLayout()
  RefreshTransferLists()
  SetGadgetColor(#GadgetQuickUploads, #PB_Gadget_BackColor, RGB(248, 250, 252))
  SetGadgetColor(#GadgetQuickDownloads, #PB_Gadget_BackColor, RGB(248, 250, 252))
  EnableWindowDrop(#WindowMain, #PB_Drop_Files, #PB_Drag_Copy)
EndProcedure

Procedure MainLoop()
  Protected Event.i
  Protected Quit.i
  Protected ChosenPath$
  Protected Dropped$
  Protected DiscoveryIndex.i

  Repeat
    Event = WaitWindowEvent(10)

    Select Event
      Case #PB_Event_CloseWindow
        If EventWindow() = #WindowMain
          MinimizeToTray()
          If TrayAvailable = 0
            Quit = #True
            Exit()
          EndIf
        ElseIf EventWindow() = #WindowReceiver
          HideWindow(#WindowReceiver, #True)
        ElseIf EventWindow() = #WindowSettings
          HideWindow(#WindowSettings, #True)
        EndIf

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #GadgetQuickSendFiles
            OpenQuickSendFiles()

          Case #GadgetQuickSendFolder
            OpenQuickSendFolder()

          Case #GadgetQuickSettings
            OpenSettingsWindow()

          Case #GadgetQuickExit
            Quit = #True
            
          Case #GadgetScan
            StartDiscoveryScan()

          Case #GadgetPause
            If TransfersPaused
              ResumeAllTransfers()
            Else
              PauseAllTransfers()
            EndIf

          Case #GadgetCancel
            CancelQueuedTransfers()

          Case #GadgetDiscoveryPeersOnly
            DiscoveryFilterPeersOnly = Bool(GetGadgetState(#GadgetDiscoveryPeersOnly) = #PB_Checkbox_Checked)
            RefreshDiscoveryList()
            UpdateDiscoveryDetails()

          Case #GadgetCopyInfo
            CopyConnectionInfo()

          Case #GadgetDiscovery
            UpdateDiscoveryDetails()
            DiscoveryIndex = GetGadgetState(#GadgetDiscovery)
            If DiscoveryIndex >= 0 And DiscoveryIndex <= ArraySize(DiscoveryEntryHost$())
              PreferredReceiverHost$ = DiscoveryEntryHost$(DiscoveryIndex)
              PreferredReceiverPort = DiscoveryEntryPort(DiscoveryIndex)
              PreferredReceiverIsLanShare = DiscoveryEntryIsLanShare(DiscoveryIndex)
            EndIf
            If EventType() = #PB_EventType_LeftDoubleClick
              If DiscoveryIndex >= 0 And DiscoveryIndex <= ArraySize(DiscoveryEntryHost$())
                SetGadgetText(#GadgetRemoteHost, DiscoveryEntryHost$(DiscoveryIndex))
                If DiscoveryEntryPort(DiscoveryIndex) > 0 And DiscoveryEntryIsLanShare(DiscoveryIndex)
                  SetGadgetText(#GadgetPort, Str(DiscoveryEntryPort(DiscoveryIndex)))
                  ConnectRemote()
                Else
                  AddLog("Selected generic LAN device: " + DiscoveryEntryHost$(DiscoveryIndex))
                EndIf
              EndIf
            EndIf

          Case #GadgetReceiverCancel
            If IsWindow(#WindowReceiver)
              HideWindow(#WindowReceiver, #True)
            EndIf

          Case #GadgetReceiverSend
            DiscoveryIndex = GetGadgetState(#GadgetReceiverList)
            If DiscoveryIndex >= 0
              ForEach Discovery()
                If Discovery()\IsLanShare
                  If Discovery()\Name + " (" + Discovery()\Host + ")" = GetGadgetItemText(#GadgetReceiverList, DiscoveryIndex, 0) Or Discovery()\Host = GetGadgetItemText(#GadgetReceiverList, DiscoveryIndex, 0)
                    CurrentQueuedTargetHost$ = Discovery()\Host
                    CurrentQueuedTargetPort = Discovery()\Port
                    PreferredReceiverHost$ = Discovery()\Host
                    PreferredReceiverPort = Discovery()\Port
                    PreferredReceiverIsLanShare = #True
                    Break
                  EndIf
                EndIf
              Next
              SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
              SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
              If IsWindow(#WindowReceiver)
                HideWindow(#WindowReceiver, #True)
              EndIf
              ConnectRemote()
              UpdateTransferRow(#TransferRowUpload, "queued-send", CurrentQueuedTargetHost$, "Preparing transfer", 0, "Connecting", 0)
              TryStartNextUpload()
            Else
              MessageRequester(#APP_NAME, "Select a receiver first.")
            EndIf

          Case #GadgetSettingsShareBrowse
          Case #GadgetSettingsDownloadBrowse
            ChosenPath$ = PathRequester("Choose the download folder", GetGadgetText(#GadgetSettingsDownload))
            If ChosenPath$
              SetGadgetText(#GadgetSettingsDownload, TrimTrailingSlash(ChosenPath$))
            EndIf

          Case #GadgetSettingsSave
            DownloadPath$ = TrimTrailingSlash(GetGadgetText(#GadgetSettingsDownload))
            SetGadgetText(#GadgetDownloadPath, DownloadPath$)
            SetGadgetText(#GadgetPort, GetGadgetText(#GadgetSettingsPort))
            SaveSettings()
            EnsureUsablePort(#True)
            If ServerRunning
              StopServer()
              StartServer()
            EndIf
            If IsWindow(#WindowSettings)
              HideWindow(#WindowSettings, #True)
            EndIf

          Case #GadgetSettingsCancel
            If IsWindow(#WindowSettings)
              HideWindow(#WindowSettings, #True)
            EndIf

        EndSelect

      Case #PB_Event_GadgetDrop
        If EventDropType() = #PB_Drop_Files
          Dropped$ = EventDropFiles()
          ClearList(UploadQueue())
          ClearList(Transfers())
          RefreshTransferLists()
          QueueUploadsFromDrop(Dropped$, "")
          OpenReceiverWindow()
        EndIf

      Case #PB_Event_SysTray
        If EventGadget() = #TrayMain And EventType() = #PB_EventType_LeftDoubleClick
          RestoreMainWindow()
        EndIf

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MenuTrayShow
            RestoreMainWindow()
          Case #MenuTrayScan
            RestoreMainWindow()
            StartDiscoveryScan()
          Case #MenuTrayExit
            Quit = #True
            Exit()
        EndSelect
    EndSelect

    PollNetwork()
    ContinueDiscoveryScan()
    TryStartNextUpload()
    TryStartNextDownload()
  Until Quit
EndProcedure

Procedure InitDefaults()
  HostName$ = Trim(GetEnvironmentVariable("COMPUTERNAME"))
  If HostName$ = ""
    HostName$ = "My_LAN_PC"
  EndIf

  DownloadPath$ = TrimTrailingSlash(GetHomeDirectory() + "Downloads\\LANShareDownloads")
  SharePath$ = DownloadPath$
  LoadSettings()
  SharePath$ = DownloadPath$
  EnsureDirectoryExists(DownloadPath$)
  TransfersPaused = #False
  ScanMutex = CreateMutex()
EndProcedure

InitDefaults()
OpenMainWindow()
CreateTraySupport()
SetGadgetText(#GadgetSharePath, DownloadPath$)
SetGadgetText(#GadgetDownloadPath, DownloadPath$)
ApplyLoadedSettingsToUI()
ShowFirstRunHelp()
RefreshLocalIPs()
UpdateServerStatus()
EnsureUsablePort(#True)
StartServer()
AddLog("LanShare is ready")
AddLog("Download folder: " + DownloadPath$)
MainLoop()
SaveSettings()
ScanCancel = #True
If TrayAvailable
  RemoveSysTrayIcon(#TrayMain)
EndIf
DisconnectRemote()
StopServer()

ForEach Peers()
  FreePeerResources(@Peers())
Next

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 16
; Folding = ---------------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = PB_LanShare.ico
; Executable = ..\PB_LanShare.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = PB_LanShare
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = A LAN file sharing / file transfer app.
; VersionField7 = PB_LanShare
; VersionField8 = PB_LanShare.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60