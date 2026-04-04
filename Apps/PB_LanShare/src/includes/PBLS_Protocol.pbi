; Protocol framing, serialization, and inbound peer buffer parsing.

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
  Protected NewCapacity.i
  Protected *NewBuffer

  If Length <= 0
    ProcedureReturn
  EndIf

  Needed = *Peer\InputSize + Length
  If Needed > *Peer\InputCapacity
    If Needed > #ProtocolMaxPayload + 16
      RemovePeer(*Peer\Connection, #True)
      ProcedureReturn
    EndIf

    NewCapacity = Needed + 65536
    If *Peer\InputBuffer
      *NewBuffer = ReAllocateMemory(*Peer\InputBuffer, NewCapacity)
    Else
      *NewBuffer = AllocateMemory(NewCapacity)
    EndIf

    If *NewBuffer = 0
      RemovePeer(*Peer\Connection, #True)
      ProcedureReturn
    EndIf

    *Peer\InputBuffer = *NewBuffer
    *Peer\InputCapacity = NewCapacity
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
    If *Peer\InputBuffer = 0
      *Peer\InputSize = 0
      *Peer\InputCapacity = 0
      ProcedureReturn
    EndIf

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
    If FindMapElement(Peers(), Str(*Peer\Connection)) = 0
      ProcedureReturn
    EndIf

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
  Protected Connection.i

  If *Buffer = 0
    ProcedureReturn
  EndIf

  Connection = *Peer\Connection

  Repeat
    Received = ReceiveNetworkData(*Peer\Connection, *Buffer, #ChunkSize)
    If Received > 0
      AppendPeerBuffer(*Peer, *Buffer, Received)
      If FindMapElement(Peers(), Str(Connection)) = 0
        FreeMemory(*Buffer)
        ProcedureReturn
      EndIf
    EndIf
  Until Received <> #ChunkSize

  FreeMemory(*Buffer)
  ParsePeerBuffer(*Peer)
EndProcedure
