; Upload/download queues, transfer state changes, and frame-level transfer handlers.

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
  Protected PartialPath$
  Protected RelativePath$
  Protected ReceiveMode.i
  Protected ReceiveDone.q
  Protected ReceiveTotal.q

  ClearList(UploadQueue())
  ClearList(DownloadQueue())
  ForEach Peers()
    *Peer = @Peers()
    If *Peer\IsDiscovery = 0
      SendFrame(*Peer\Connection, #FrameCancel, 0, 0)
    EndIf
    PartialPath$ = *Peer\ReceiveFinalPath
    RelativePath$ = *Peer\ReceiveRelativePath
    ReceiveMode = *Peer\ReceiveMode
    ReceiveDone = *Peer\ReceiveDone
    ReceiveTotal = *Peer\ReceiveTotal
    ResetPeerTransferState(*Peer)
    If PartialPath$ <> "" And ReceiveMode <> #TransferNone And ReceiveDone < ReceiveTotal And FileSize(PartialPath$) >= 0
      DeleteFile(PartialPath$)
      If RelativePath$ <> ""
        If ReceiveMode = #TransferDownload
          AddHistory("Cancelled", "Download", RelativePath$, "Partial file removed")
        ElseIf ReceiveMode = #TransferUpload
          AddHistory("Cancelled", "Upload", RelativePath$, "Partial file removed")
        EndIf
      EndIf
    EndIf
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

Procedure RemoveCurrentUploadQueueItem()
  If ListSize(UploadQueue()) > 0
    FirstElement(UploadQueue())
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

Procedure RemoveCurrentDownloadQueueItem()
  If ListSize(DownloadQueue()) > 0
    FirstElement(DownloadQueue())
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

  If *Peer\SendPaused Or *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone Or *Peer\WaitingUploadReady Or *Peer\AwaitingTransferStatus Or *Peer\AwaitingUploadVerify Or *Peer\BuildingTree
    ProcedureReturn
  EndIf

  FirstElement(DownloadQueue())
  *Peer\PendingDownloadPath = DownloadQueue()\RemotePath
  Payload$ = DownloadQueue()\RemotePath + Chr(31) + Str(DownloadResumeOffset(DownloadQueue()\RemotePath))
  SendTextFrame(*Peer\Connection, #FrameDownloadRequest, Payload$)
  AddLog("Requested download: " + DownloadQueue()\RemotePath)
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
    If ActiveRemoteConnection = 0
      CurrentQueuedTargetHost$ = ""
      CurrentQueuedTargetPort = 0
      AddLog("Queued upload paused until a receiver is selected again")
      ProcedureReturn
    EndIf
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
  If UploadQueue()\IsDirectory
    If FileSize(UploadQueue()\LocalPath) <> -2
      AddLog("Skipped missing folder: " + UploadQueue()\LocalPath)
      DeleteElement(UploadQueue())
      TryStartNextUpload()
      ProcedureReturn
    EndIf

    *Peer\AwaitingTransferStatus = #True
    SendTextFrame(*Peer\Connection, #FrameCreateDir, UploadQueue()\RemotePath)
    AddLog("Creating remote folder: " + UploadQueue()\RemotePath)
    ProcedureReturn
  EndIf

  FileSizeValue = FileSize(UploadQueue()\LocalPath)
  If FileSizeValue < 0
    AddLog("Skipped missing file: " + UploadQueue()\LocalPath)
    DeleteElement(UploadQueue())
    TryStartNextUpload()
    ProcedureReturn
  EndIf

  Modified = GetFileDate(UploadQueue()\LocalPath, #PB_Date_Modified)
  *Peer\SendChecksum = FileSHA256(UploadQueue()\LocalPath)
  Payload$ = ParentRelativePath(UploadQueue()\RemotePath) + Chr(31) + GetFilePart(UploadQueue()\RemotePath) + Chr(31) + Str(FileSizeValue) + Chr(31) + Str(Modified) + Chr(31) + *Peer\SendChecksum

  *Peer\WaitingUploadReady = #True
  *Peer\PendingLocalUploadPath = UploadQueue()\LocalPath
  *Peer\PendingRemoteTargetDir = ParentRelativePath(UploadQueue()\RemotePath)
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

  If *Peer\SendMode <> #TransferNone Or *Peer\ReceiveMode <> #TransferNone Or *Peer\WaitingUploadReady Or *Peer\AwaitingTransferStatus Or *Peer\AwaitingUploadVerify Or *Peer\BuildingTree
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
  If EnsureDirectoryExists(ParentDir$) = 0
    SendError(*Peer\Connection, "Unable to create destination folder")
    ProcedureReturn
  EndIf

  LocalPath$ = ResolveTargetPath(LocalPath$, #False)
  If LocalPath$ = ""
    SendStatus(*Peer\Connection, "Skipped existing upload target: " + RelativePath$)
    ProcedureReturn
  EndIf

  FileHandle = CreateFile(#PB_Any, LocalPath$)
  *Peer\ReceiveDone = 0

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

Procedure AbortReceive(*Peer.PeerState, Message$)
  Protected FailedMode.i = *Peer\ReceiveMode
  Protected FailedRelative$ = *Peer\ReceiveRelativePath
  Protected FailedPath$ = *Peer\ReceiveFinalPath
  Protected FailedSize.q = *Peer\ReceiveTotal

  If FailedMode = #TransferNone
    ProcedureReturn
  EndIf

  If *Peer\ReceiveFile
    CloseFile(*Peer\ReceiveFile)
    *Peer\ReceiveFile = 0
  EndIf

  If FailedPath$ <> "" And FileSize(FailedPath$) >= 0
    DeleteFile(FailedPath$)
  EndIf

  ResetPeerTransferState(*Peer)
  SendFrame(*Peer\Connection, #FrameCancel, 0, 0)
  SendError(*Peer\Connection, Message$)
  AddLog(Message$)

  If FailedMode = #TransferDownload
    AddHistory("Failed", "Download", FailedRelative$, Message$)
    UpdateTransferRow(#TransferRowDownload, FailedRelative$, *Peer\PeerName, FailedRelative$, FailedSize, "Failed", 0)
    If *Peer\IsOutgoing And ListSize(DownloadQueue()) > 0
      HandleDownloadQueueFailure(Message$)
      TryStartNextDownload()
    EndIf
  ElseIf FailedMode = #TransferUpload
    AddHistory("Failed", "Upload", FailedRelative$, Message$)
    UpdateTransferRow(#TransferRowUpload, FailedRelative$, *Peer\PeerHost, FailedRelative$, FailedSize, "Failed", 0)
  EndIf

  UpdateProgressUI()
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
  Protected ReceiveMode.i = *Peer\ReceiveMode
  Protected ReceiveDone.q = *Peer\ReceiveDone
  Protected ReceiveTotal.q = *Peer\ReceiveTotal
  Protected RelativePath$ = *Peer\ReceiveRelativePath
  Protected FinalPath$ = *Peer\ReceiveFinalPath
  Protected Modified.q = *Peer\ReceiveModified
  Protected ChecksumOK.i = #True
  Protected SizeOK.i = Bool(ReceiveDone = ReceiveTotal)

  If *Peer\ReceiveFile
    CloseFile(*Peer\ReceiveFile)
    *Peer\ReceiveFile = 0
  EndIf

  If SizeOK And ReceiveMode = #TransferDownload And FinalPath$ <> ""
    *Peer\ReceiveActualChecksum = FileSHA256(FinalPath$)
    If *Peer\ReceiveExpectedChecksum <> "" And LCase(*Peer\ReceiveExpectedChecksum) <> LCase(*Peer\ReceiveActualChecksum)
      ChecksumOK = #False
    EndIf
  EndIf

  If ReceiveMode = #TransferDownload
    If SizeOK And ChecksumOK
      If Modified > 0
        SetFileDate(FinalPath$, #PB_Date_Modified, Modified)
      EndIf
      AddLog("Download complete: " + FinalPath$)
      AddHistory("OK", "Download", RelativePath$, "SHA-256 verified")
      UpdateTransferRow(#TransferRowDownload, RelativePath$, *Peer\PeerName, RelativePath$, ReceiveTotal, "Completed", 100)
    Else
      If FinalPath$ <> "" And FileSize(FinalPath$) >= 0
        DeleteFile(FinalPath$)
      EndIf
      If SizeOK
        AddLog("Checksum mismatch: " + FinalPath$)
        AddHistory("Failed", "Download", RelativePath$, "SHA-256 mismatch")
      Else
        AddLog("Incomplete download removed: " + RelativePath$)
        AddHistory("Failed", "Download", RelativePath$, "Transfer ended before all bytes arrived")
      EndIf
      UpdateTransferRow(#TransferRowDownload, RelativePath$, *Peer\PeerName, RelativePath$, ReceiveTotal, "Failed", 0)
    EndIf
    RequestRemoteList(*Peer\CurrentRemotePath)
    If *Peer\IsOutgoing And ListSize(DownloadQueue()) > 0
      If SizeOK And ChecksumOK
        RemoveCurrentDownloadQueueItem()
      Else
        HandleDownloadQueueFailure("Download failed integrity check: " + RelativePath$)
      EndIf
      TryStartNextDownload()
    EndIf
  ElseIf ReceiveMode = #TransferUpload
    If SizeOK And FinalPath$ <> ""
      *Peer\ReceiveActualChecksum = FileSHA256(FinalPath$)
    EndIf
    If SizeOK And *Peer\ReceiveExpectedChecksum <> "" And LCase(*Peer\ReceiveExpectedChecksum) = LCase(*Peer\ReceiveActualChecksum)
      If Modified > 0
        SetFileDate(FinalPath$, #PB_Date_Modified, Modified)
      EndIf
      AddLog("Upload saved to share: " + RelativePath$)
      AddHistory("OK", "Upload", RelativePath$, "Remote SHA-256 verified")
      UpdateTransferRow(#TransferRowUpload, RelativePath$, *Peer\PeerHost, RelativePath$, ReceiveTotal, "Completed", 100)
      SendTextFrame(*Peer\Connection, #FrameUploadVerify, RelativePath$ + Chr(31) + *Peer\ReceiveActualChecksum)
    Else
      If FinalPath$ <> "" And FileSize(FinalPath$) >= 0
        DeleteFile(FinalPath$)
      EndIf
      If SizeOK
        AddLog("Upload checksum mismatch on remote side: " + RelativePath$)
        AddHistory("Failed", "Upload", RelativePath$, "Remote SHA-256 mismatch")
        SendError(*Peer\Connection, "Upload checksum mismatch: " + RelativePath$)
      Else
        AddLog("Incomplete upload removed: " + RelativePath$)
        AddHistory("Failed", "Upload", RelativePath$, "Transfer ended before all bytes arrived")
        SendError(*Peer\Connection, "Upload ended before all bytes arrived: " + RelativePath$)
      EndIf
      UpdateTransferRow(#TransferRowUpload, RelativePath$, *Peer\PeerHost, RelativePath$, ReceiveTotal, "Failed", 0)
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
        *Peer\SendDone = 0
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
      If EnsureDirectoryExists(ParentDir$) = 0
        SendError(*Peer\Connection, "Could not create local download folder")
        ProcedureReturn
      EndIf
      LocalTarget$ = ResolveTargetPath(LocalTarget$, #True)
      If LocalTarget$ = ""
        If *Peer\IsOutgoing And ListSize(DownloadQueue()) > 0
          AddHistory("Skipped", "Download", RelativePath$, "Existing file kept")
          RemoveCurrentDownloadQueueItem()
          *Peer\PendingDownloadPath = #SkipDownloadCancelTag
          *Peer\AwaitingTransferStatus = #True
          SendFrame(*Peer\Connection, #FrameCancel, 0, 0)
        EndIf
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
          If EnsureDirectoryExists(LocalTarget$) = 0
            AddLog("Could not create local folder: " + LocalTarget$)
          EndIf
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
          If EnsureDirectoryExists(LocalTarget$)
            SendStatus(*Peer\Connection, "Created folder: " + RelativePath$)
          Else
            SendError(*Peer\Connection, "Unable to create folder: " + RelativePath$)
          EndIf
        Else
          SendError(*Peer\Connection, "Invalid folder path: " + RelativePath$)
        EndIf
      Else
        SendError(*Peer\Connection, "Invalid folder path")
      EndIf

    Case #FrameUploadVerify
      RelativePath$ = NormalizeRelativePath(StringField(Payload$, 1, Chr(31)))
      SavedRelative$ = StringField(Payload$, 2, Chr(31))
      If *Peer\AwaitingUploadVerify
        *Peer\AwaitingUploadVerify = #False
        *Peer\AwaitingTransferStatus = #False
        If LCase(SavedRelative$) = LCase(*Peer\SendChecksum)
          AddLog("Upload verified by remote host: " + RelativePath$)
          AddHistory("OK", "Upload", RelativePath$, "End-to-end SHA-256 verified")
          UpdateTransferRow(#TransferRowUpload, RelativePath$, *Peer\PeerHost, *Peer\PendingLocalUploadPath, *Peer\SendTotal, "Completed", 100)
          RemoveCurrentUploadQueueItem()
        Else
          AddLog("Upload verification failed: " + RelativePath$)
          AddHistory("Failed", "Upload", RelativePath$, "End-to-end SHA-256 mismatch")
          UpdateTransferRow(#TransferRowUpload, RelativePath$, *Peer\PeerHost, *Peer\PendingLocalUploadPath, *Peer\SendTotal, "Failed", 0)
          HandleUploadQueueFailure("Upload verification failed: " + RelativePath$)
        EndIf
        ResetPeerTransferState(*Peer)
        RequestRemoteList(*Peer\CurrentRemotePath)
        TryStartNextUpload()
      EndIf

    Case #FramePause
      *Peer\SendPaused = #True

    Case #FrameResume
      *Peer\SendPaused = #False

    Case #FrameCancel
      RelativePath$ = *Peer\ReceiveRelativePath
      LocalTarget$ = *Peer\ReceiveFinalPath
      EntrySize = *Peer\ReceiveDone
      EntryModified = *Peer\ReceiveTotal
      IsDirectory = *Peer\ReceiveMode
      SavedRelative$ = *Peer\SendRelativePath
      EntryName$ = SavedRelative$
      If EntryName$ = ""
        EntryName$ = *Peer\PendingDownloadPath
      EndIf
      ResetPeerTransferState(*Peer)
      If LocalTarget$ <> "" And IsDirectory <> #TransferNone And FileSize(LocalTarget$) >= 0
        DeleteFile(LocalTarget$)
        If RelativePath$ <> ""
          If IsDirectory = #TransferDownload
            AddHistory("Cancelled", "Download", RelativePath$, "Remote canceled transfer; partial file removed")
          ElseIf IsDirectory = #TransferUpload
            AddHistory("Cancelled", "Upload", RelativePath$, "Remote canceled transfer; partial file removed")
          EndIf
        EndIf
      EndIf
      If EntryName$ <> "" And EntryName$ <> #SkipDownloadCancelTag
        SendStatus(*Peer\Connection, "Transfer canceled: " + EntryName$)
      EndIf
      If *Peer\IsOutgoing
        If SavedRelative$ <> "" And ListSize(UploadQueue()) > 0
          HandleUploadQueueFailure("Remote canceled upload: " + SavedRelative$)
          TryStartNextUpload()
        ElseIf RelativePath$ <> "" And ListSize(DownloadQueue()) > 0
          HandleDownloadQueueFailure("Remote canceled download: " + RelativePath$)
          TryStartNextDownload()
        EndIf
      EndIf

    Case #FrameFileEnd
      FinalizeReceivedFile(*Peer)

    Case #FrameStatus
      AddLog(Payload$)
      If *Peer\IsOutgoing And *Peer\PendingDownloadPath = #SkipDownloadCancelTag And Left(Payload$, 18) = "Transfer canceled: "
        *Peer\PendingDownloadPath = ""
        *Peer\AwaitingTransferStatus = #False
        TryStartNextDownload()
      EndIf
      If *Peer\IsOutgoing And *Peer\WaitingUploadReady
        *Peer\WaitingUploadReady = #False
        RemoveCurrentUploadQueueItem()
        RequestRemoteList(*Peer\CurrentRemotePath)
        TryStartNextUpload()
      EndIf
      If *Peer\IsOutgoing And *Peer\AwaitingTransferStatus
        *Peer\AwaitingTransferStatus = #False
        If Left(Payload$, 16) = "Created folder: "
          RemoveCurrentUploadQueueItem()
          RequestRemoteList(*Peer\CurrentRemotePath)
          TryStartNextUpload()
        ElseIf *Peer\AwaitingUploadVerify = 0
          RequestRemoteList(*Peer\CurrentRemotePath)
          TryStartNextUpload()
        EndIf
      EndIf
      If ActiveRemoteConnection And ListSize(UploadQueue()) = 0 And CurrentQueuedTargetHost$ <> ""
        CurrentQueuedTargetHost$ = ""
        CurrentQueuedTargetPort = 0
        DisconnectAfterUploadQueue = #True
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
        ElseIf *Peer\AwaitingTransferStatus And *Peer\AwaitingUploadVerify = 0
          *Peer\AwaitingTransferStatus = #False
          HandleUploadQueueFailure("Upload folder failed: " + Payload$)
          TryStartNextUpload()
        ElseIf *Peer\SendMode = #TransferUpload Or *Peer\AwaitingUploadVerify
          HandleUploadQueueFailure("Upload failed: " + Payload$)
          ResetPeerTransferState(*Peer)
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
  Protected Remaining.q
  Protected BytesWritten.i

  If FrameType = #FrameFileChunk And PayloadLength > 0
    If *Peer\ReceiveMode <> #TransferNone And *Peer\ReceiveFile
      Remaining = *Peer\ReceiveTotal - *Peer\ReceiveDone
      If Remaining < PayloadLength
        AbortReceive(*Peer, "Transfer exceeded the announced file size: " + *Peer\ReceiveRelativePath)
        ProcedureReturn
      EndIf

      BytesWritten = WriteData(*Peer\ReceiveFile, *Payload, PayloadLength)
      If BytesWritten <> PayloadLength
        AbortReceive(*Peer, "Failed to write received data: " + *Peer\ReceiveRelativePath)
        ProcedureReturn
      EndIf

      *Peer\ReceiveDone + PayloadLength
      UpdateProgressUI()
    EndIf
  EndIf
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
    Else
      FreeMemory(*Buffer)
      RemovePeer(*Peer\Connection, #True)
      ProcedureReturn
    EndIf
  Else
    FreeMemory(*Buffer)
    RemovePeer(*Peer\Connection, #True)
    ProcedureReturn
  EndIf
  FreeMemory(*Buffer)

  UpdateProgressUI()
EndProcedure
