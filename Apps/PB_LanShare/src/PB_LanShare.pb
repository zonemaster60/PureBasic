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
#RememberedPeerMaxAge = 1209600
#SkipDownloadCancelTag = "<skip-cancel>"

Global version.s = "v1.0.0.7"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

#SettingsFile = "PB_LanShare.pref"

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
Global DiscoveryEntryCount.i
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
Global QuitRequested.i
Global DisconnectAfterUploadQueue.i

Declare UpdateProgressUI()
Declare DiscoveryScanThread(*Value)
Declare AddLog(Message$)
Declare.s LegacySettingsPath()
Declare.s SettingsPath()
Declare.s FormatBytes(Value.q)

; Queue and transfer flow
Declare QueueUploadPathRecursive(LocalPath$, RemoteBase$)
Declare QueueUploadItem(LocalPath$, RemotePath$, IsDirectory.i)
Declare QueueDownloadItem(RemotePath$)
Declare QueueQuickSend(LocalPath$, IsDirectory.i)
Declare OpenQuickSendFiles()
Declare OpenQuickSendFolder()
Declare TryStartNextUpload()
Declare TryStartNextDownload()
Declare StartRemoteDownload(RelativePath$)
Declare QueueUploadsFromDrop(DroppedFiles$, RemoteBase$)
Declare UseSelectedReceiverIfAvailable()
Declare HandleUploadQueueFailure(Message$)
Declare HandleDownloadQueueFailure(Message$)
Declare RemoveCurrentUploadQueueItem()
Declare RemoveCurrentDownloadQueueItem()

; Discovery and UI
Declare RefreshDiscoveryList()
Declare UpdateDiscoveryDetails()
Declare RefreshTransferLists()
Declare RefreshQueueViews()
Declare AddHistory(Status$, Direction$, Item$, Details$)
Declare AddDiscoveryHost(Host$, Port.i, Name$, Share$)
Declare StartDiscoveryScan()
Declare ContinueDiscoveryScan()

; Remote session and frame handling
Declare RequestRemoteList(RelativePath$)
Declare ConnectRemote()
Declare DisconnectRemote()
Declare RemovePeer(Connection.i, CloseConnection.i)
Declare HandleTextFrame(*Peer.PeerState, FrameType.i, Payload$)
Declare HandleBinaryFrame(*Peer.PeerState, FrameType.i, *Payload, PayloadLength.i)

; Settings and server lifecycle
Declare SaveSettings()
Declare StartServer()
Declare StopServer()
Declare EnsureUsablePort(ShowLog.i)

UseSHA2Fingerprint()

Procedure.i IsValidRememberedPeer(Host$, Port.i, LastSeen.q)
  If Trim(Host$) = ""
    ProcedureReturn #False
  EndIf

  If Port < 1 Or Port > 65535
    ProcedureReturn #False
  EndIf

  If LastSeen > 0 And Date() - LastSeen > #RememberedPeerMaxAge
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    QuitRequested = #True
  EndIf
EndProcedure

Procedure.s TrimTrailingSlash(Path$)
  Protected Result$ = Path$

  While Len(Result$) > 1 And (Right(Result$, 1) = "\" Or Right(Result$, 1) = "/")
    If Len(Result$) = 3 And Mid(Result$, 2, 1) = ":"
      Break
    EndIf
    Result$ = Left(Result$, Len(Result$) - 1)
  Wend

  ProcedureReturn Result$
EndProcedure

Procedure.i EnsureDirectoryExists(DirPath$)
  Protected Normalized$ = TrimTrailingSlash(DirPath$)
  Protected Parent$

  If Normalized$ = ""
    ProcedureReturn #False
  EndIf

  If FileSize(Normalized$) = -2
    ProcedureReturn #True
  EndIf

  If Len(Normalized$) <= 3 And Mid(Normalized$, 2, 1) = ":"
    ProcedureReturn Bool(FileSize(Normalized$) = -2)
  EndIf

  Parent$ = TrimTrailingSlash(GetPathPart(Normalized$))
  If Parent$ <> "" And Parent$ <> Normalized$
    If EnsureDirectoryExists(Parent$) = 0
      ProcedureReturn #False
    EndIf
  EndIf

  If CreateDirectory(Normalized$) = 0 And FileSize(Normalized$) <> -2
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(FileSize(Normalized$) = -2)
EndProcedure

Procedure.i IsAbsolutePath(Path$)
  Protected Text$ = Trim(Path$)

  If Len(Text$) >= 3 And Mid(Text$, 2, 1) = ":" And (Mid(Text$, 3, 1) = "\" Or Mid(Text$, 3, 1) = "/")
    ProcedureReturn #True
  EndIf

  If Left(Text$, 2) = "\\" Or Left(Text$, 2) = "//"
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i IsUsableTransferDirectory(DirPath$)
  Protected Normalized$ = TrimTrailingSlash(DirPath$)

  If Normalized$ = "" Or IsAbsolutePath(Normalized$) = 0
    ProcedureReturn #False
  EndIf

  If EnsureDirectoryExists(Normalized$) = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(FileSize(Normalized$) = -2)
EndProcedure

Procedure.s NormalizeRelativePath(RelativePath$)
  Protected Working$ = ReplaceString(Trim(RelativePath$), "\", "/")
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

  If Normalized$ = #InvalidRelativePath Or Base$ = "" Or IsAbsolutePath(Base$) = 0
    ProcedureReturn ""
  EndIf

  If Normalized$ = ""
    ProcedureReturn Base$
  EndIf

  ProcedureReturn Base$ + "\" + ReplaceString(Normalized$, "/", "\")
EndProcedure

Procedure.s ResolveDownloadPath(RelativePath$)
  Protected Normalized$ = NormalizeRelativePath(RelativePath$)
  Protected Base$ = TrimTrailingSlash(DownloadPath$)

  If Normalized$ = #InvalidRelativePath Or Normalized$ = "" Or Base$ = "" Or IsAbsolutePath(Base$) = 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn Base$ + "\" + ReplaceString(Normalized$, "/", "\")
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

  ProcedureReturn Directory$ + Stem$ + "_" + FormatDate("[%yyyy-%mm-%dd]-[%hh:%ii:%ss]", Date())
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

Procedure.i IsSafeHostToken(Host$)
  Protected Text$ = Trim(Host$)
  Protected Index.i
  Protected Char$ 

  If Text$ = ""
    ProcedureReturn #False
  EndIf

  For Index = 1 To Len(Text$)
    Char$ = Mid(Text$, Index, 1)
    If FindString("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-", Char$, 1) = 0
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.s ResolveMacAddress(Host$)
  Protected Program.i
  Protected Output$
  Protected Line$
  Protected MacAddress$
  Protected CleanLine$

  If IsSafeHostToken(Host$) = 0
    ProcedureReturn ""
  EndIf

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

  If IsSafeHostToken(Host$) = 0
    ProcedureReturn Host$
  EndIf

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

  If IsSafeHostToken(Host$) = 0
    ProcedureReturn #False
  EndIf

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

XIncludeFile "includes\PBLS_DiscoveryUI.pbi"
XIncludeFile "includes\PBLS_Settings.pbi"

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

XIncludeFile "includes\PBLS_Protocol.pbi"

XIncludeFile "includes\PBLS_Transfers.pbi"

XIncludeFile "includes\PBLS_DiscoveryScan.pbi"

XIncludeFile "includes\PBLS_Network.pbi"

XIncludeFile "includes\PBLS_Runtime.pbi"

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
While ScanWorkerRunning > 0
  Delay(10)
Wend
If TrayAvailable
  RemoveSysTrayIcon(#TrayMain)
EndIf
DisconnectRemote()
StopServer()

While MapSize(Peers()) > 0
  ForEach Peers()
    RemovePeer(Peers()\Connection, #True)
    Break
  Next
Wend

If hMutex
  CloseHandle_(hMutex)
  hMutex = 0
EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 18
; FirstLine = 5
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = PB_LanShare.ico
; Executable = ..\PB_LanShare.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,7
; VersionField1 = 1,0,0,7
; VersionField2 = ZoneSoft
; VersionField3 = PB_LanShare
; VersionField4 = 1.0.0.7
; VersionField5 = 1.0.0.7
; VersionField6 = A LAN file sharing / file transfer app.
; VersionField7 = PB_LanShare
; VersionField8 = PB_LanShare.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60