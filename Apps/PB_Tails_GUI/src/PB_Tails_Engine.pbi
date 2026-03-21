; Shared tail/read engine for PB_Tails_GUI.
; Keeps file access, decoding, and tail helpers out of the GUI source.

Procedure.i TailEngine_WinOpenForRead(FileName.s)
  ProcedureReturn CreateFile_(@FileName, #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE | #FILE_SHARE_DELETE, 0, #OPEN_EXISTING, #FILE_ATTRIBUTE_NORMAL, 0)
EndProcedure

Procedure.q TailEngine_WinFileSize(FileName.s)
  Protected h.i = TailEngine_WinOpenForRead(FileName)
  Protected size.q

  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn -1
  EndIf
  If GetFileSizeEx_(h, @size) = 0
    CloseHandle_(h)
    ProcedureReturn -1
  EndIf

  CloseHandle_(h)
  ProcedureReturn size
EndProcedure

Procedure.q TailEngine_AnyFileSize(FileName.s)
  Protected s.q = FileSize(FileName)
  If s < 0
    s = TailEngine_WinFileSize(FileName)
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.i TailEngine_CanOpenForReadWinAPI(FileName.s)
  Protected h.i = TailEngine_WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn #False
  EndIf
  CloseHandle_(h)
  ProcedureReturn #True
EndProcedure

Procedure.i TailEngine_OpenForRead(FileName.s)
  Protected f.i = ReadFile(#PB_Any, FileName)
  If f = 0
    f = ReadFile(#PB_Any, FileName, #PB_File_SharedRead)
  EndIf
  ProcedureReturn f
EndProcedure

Procedure.i TailEngine_CanOpenForRead(FileName.s)
  Protected f.i = TailEngine_OpenForRead(FileName)
  If f = 0 : ProcedureReturn #False : EndIf
  CloseFile(f)
  ProcedureReturn #True
EndProcedure

Procedure.i TailEngine_CanOpenForReadAny(FileName.s)
  If TailEngine_CanOpenForRead(FileName)
    ProcedureReturn #True
  EndIf
  ProcedureReturn TailEngine_CanOpenForReadWinAPI(FileName)
EndProcedure

Procedure.i IsValidUTF8(*buf, size.i)
  Protected i.i = 0
  Protected b.a
  Protected need.i

  While i < size
    b = PeekA(*buf + i)
    If b < $80
      i + 1
      Continue
    EndIf

    If b < $C2
      ProcedureReturn #False
    ElseIf b < $E0
      need = 1
    ElseIf b < $F0
      need = 2
    ElseIf b < $F5
      need = 3
    Else
      ProcedureReturn #False
    EndIf

    If i + need >= size
      ProcedureReturn #True
    EndIf

    Protected j.i
    For j = 1 To need
      Protected c.a = PeekA(*buf + i + j)
      If (c & $C0) <> $80
        ProcedureReturn #False
      EndIf
    Next

    i + need + 1
  Wend

  ProcedureReturn #True
EndProcedure

Procedure.i UTF8CharLength(firstByte.i)
  If firstByte < $80
    ProcedureReturn 1
  ElseIf firstByte >= $C2 And firstByte < $E0
    ProcedureReturn 2
  ElseIf firstByte >= $E0 And firstByte < $F0
    ProcedureReturn 3
  ElseIf firstByte >= $F0 And firstByte < $F5
    ProcedureReturn 4
  EndIf
  ProcedureReturn 1
EndProcedure

Procedure.i UTF8TrailingBytesToHold(*buf, size.i)
  Protected hold.i = 0
  Protected i.i
  Protected need.i

  If size <= 0
    ProcedureReturn 0
  EndIf

  For i = size - 1 To 0 Step -1
    Protected b.i = PeekA(*buf + i) & $FF
    If b < $80
      ProcedureReturn 0
    EndIf
    If (b & $C0) = $80
      hold + 1
      If hold >= 3
        ProcedureReturn hold
      EndIf
      Continue
    EndIf

    need = UTF8CharLength(b) - 1
    If need > hold
      ProcedureReturn hold + 1
    EndIf
    ProcedureReturn 0
  Next

  If hold > size
    hold = size
  EndIf
  ProcedureReturn hold
EndProcedure

Procedure.i AdjustUTF8StartOffset(*buf, size.i, startOffset.i)
  Protected offset.i = startOffset
  Protected i.i
  Protected lead.i
  Protected need.i
  Protected cont.i

  If offset <= 0 Or offset >= size
    ProcedureReturn startOffset
  EndIf
  If (PeekA(*buf + offset) & $C0) <> $80
    ProcedureReturn offset
  EndIf

  For i = offset - 1 To 0 Step -1
    lead = PeekA(*buf + i) & $FF
    If (lead & $C0) = $80
      Continue
    EndIf

    need = UTF8CharLength(lead)
    cont = offset - i - 1
    If need > 1 And cont < need - 1
      ProcedureReturn offset + (need - 1 - cont)
    EndIf
    ProcedureReturn offset
  Next

  ProcedureReturn offset
EndProcedure

Procedure.q AdjustUTF8StartOffsetForFile(FileName.s, fileSize.q, startOffset.q, preferWinAPI.i)
  Protected checkStart.q
  Protected bytesToRead.i
  Protected localOffset.i
  Protected *buf
  Protected bytesRead.i
  Protected adjusted.i
  Protected file.i
  Protected h.i
  Protected newPos.q

  If startOffset <= 0 Or startOffset >= fileSize
    ProcedureReturn startOffset
  EndIf

  checkStart = startOffset - 3
  If checkStart < 0 : checkStart = 0 : EndIf
  bytesToRead = fileSize - checkStart
  If bytesToRead > 7 : bytesToRead = 7 : EndIf
  localOffset = startOffset - checkStart

  *buf = AllocateMemory(bytesToRead)
  If *buf = 0
    ProcedureReturn startOffset
  EndIf

  If preferWinAPI
    h = TailEngine_WinOpenForRead(FileName)
    If h = #INVALID_HANDLE_VALUE
      FreeMemory(*buf)
      ProcedureReturn startOffset
    EndIf
    If SetFilePointerEx_(h, checkStart, @newPos, #FILE_BEGIN) = 0
      CloseHandle_(h)
      FreeMemory(*buf)
      ProcedureReturn startOffset
    EndIf

    Protected br.l
    If ReadFile_(h, *buf, bytesToRead, @br, 0) = 0
      CloseHandle_(h)
      FreeMemory(*buf)
      ProcedureReturn startOffset
    EndIf
    bytesRead = br
    CloseHandle_(h)
  Else
    file = TailEngine_OpenForRead(FileName)
    If file = 0
      FreeMemory(*buf)
      ProcedureReturn startOffset
    EndIf
    FileSeek(file, checkStart)
    bytesRead = ReadData(file, *buf, bytesToRead)
    CloseFile(file)
  EndIf

  If bytesRead <= localOffset
    FreeMemory(*buf)
    ProcedureReturn startOffset
  EndIf

  adjusted = AdjustUTF8StartOffset(*buf, bytesRead, localOffset)
  FreeMemory(*buf)
  ProcedureReturn checkStart + adjusted
EndProcedure

Procedure.s TailEngine_DecodeBytes(*buf, size.i, encMode.i)
  Select encMode
    Case #ENC_UTF8
      ProcedureReturn PeekS(*buf, size, #PB_UTF8)
    Case #ENC_ANSI
      ProcedureReturn PeekS(*buf, size, #PB_Ascii)
    Default
      If IsValidUTF8(*buf, size)
        ProcedureReturn PeekS(*buf, size, #PB_UTF8)
      EndIf
      ProcedureReturn PeekS(*buf, size, #PB_Ascii)
  EndSelect
EndProcedure

Procedure.s TailEngine_StripUTF8BOM(s.s)
  If Len(s) > 0
    If Asc(Left(s, 1)) = $FEFF
      ProcedureReturn Mid(s, 2)
    EndIf
  EndIf
  ProcedureReturn s
EndProcedure

Procedure DecodeStateInit(*state.DecodeState, stripBOM.i)
  *state\carryLen = 0
  *state\stripPending = stripBOM
EndProcedure

Procedure.s DecodeChunkSafe(*state.DecodeState, *buf, size.i, encMode.i)
  Protected out.s = ""
  Protected *work
  Protected total.i = size + *state\carryLen
  Protected hold.i = 0
  Protected decodeBytes.i

  If size <= 0 And *state\carryLen <= 0
    ProcedureReturn ""
  EndIf

  *work = AllocateMemory(total)
  If *work = 0
    ProcedureReturn ""
  EndIf
  If *state\carryLen > 0
    CopyMemory(@*state\carry[0], *work, *state\carryLen)
  EndIf
  If size > 0
    CopyMemory(*buf, *work + *state\carryLen, size)
  EndIf

  Select encMode
    Case #ENC_UTF8
      hold = UTF8TrailingBytesToHold(*work, total)
    Case #ENC_AUTO
      If IsValidUTF8(*work, total)
        hold = UTF8TrailingBytesToHold(*work, total)
      EndIf
  EndSelect

  decodeBytes = total - hold
  If decodeBytes > 0
    out = TailEngine_DecodeBytes(*work, decodeBytes, encMode)
    If *state\stripPending
      out = TailEngine_StripUTF8BOM(out)
      *state\stripPending = #False
    EndIf
  EndIf

  *state\carryLen = hold
  If hold > 0
    CopyMemory(*work + decodeBytes, @*state\carry[0], hold)
  EndIf

  FreeMemory(*work)
  ProcedureReturn out
EndProcedure

Procedure.s DecodeStateFlush(*state.DecodeState, encMode.i)
  Protected out.s = ""

  If *state\carryLen > 0
    out = TailEngine_DecodeBytes(@*state\carry[0], *state\carryLen, encMode)
    *state\carryLen = 0
  EndIf
  If *state\stripPending
    out = TailEngine_StripUTF8BOM(out)
    *state\stripPending = #False
  EndIf

  ProcedureReturn out
EndProcedure

Procedure.s TailEngine_ToOEMIfNeeded(s.s, useOEM.i)
  Protected src.s
  Protected *out
  Protected result.s

  If useOEM = #False
    ProcedureReturn s
  EndIf

  src = s
  *out = AllocateMemory((Len(src) + 1) * SizeOf(Character))
  If *out = 0
    ProcedureReturn s
  EndIf

  CharToOem_(@src, *out)
  result = PeekS(*out, -1, #PB_Ascii)
  FreeMemory(*out)
  ProcedureReturn result
EndProcedure

Procedure.i OpenReadContext(*ctx.ReadContext, FileName.s, preferWinAPI.i)
  *ctx\useWinAPI = #False
  *ctx\file = 0
  *ctx\handle = 0
  *ctx\size = -1

  If preferWinAPI
    *ctx\handle = TailEngine_WinOpenForRead(FileName)
    If *ctx\handle <> #INVALID_HANDLE_VALUE
      If GetFileSizeEx_(*ctx\handle, @*ctx\size)
        *ctx\useWinAPI = #True
        ProcedureReturn #True
      EndIf
      CloseHandle_(*ctx\handle)
      *ctx\handle = 0
    EndIf
  EndIf

  *ctx\file = TailEngine_OpenForRead(FileName)
  If *ctx\file = 0
    ProcedureReturn #False
  EndIf

  *ctx\size = Lof(*ctx\file)
  ProcedureReturn #True
EndProcedure

Procedure CloseReadContext(*ctx.ReadContext)
  If *ctx\useWinAPI
    If *ctx\handle And *ctx\handle <> #INVALID_HANDLE_VALUE
      CloseHandle_(*ctx\handle)
    EndIf
  ElseIf *ctx\file
    CloseFile(*ctx\file)
  EndIf

  *ctx\useWinAPI = #False
  *ctx\file = 0
  *ctx\handle = 0
  *ctx\size = -1
EndProcedure

Procedure.i ReadContextSeek(*ctx.ReadContext, offset.q)
  If *ctx\useWinAPI
    Protected newPos.q
    ProcedureReturn SetFilePointerEx_(*ctx\handle, offset, @newPos, #FILE_BEGIN)
  EndIf

  FileSeek(*ctx\file, offset)
  ProcedureReturn #True
EndProcedure

Procedure.i ReadContextRead(*ctx.ReadContext, *buf, bytesToRead.i)
  If *ctx\useWinAPI
    Protected bytesRead.l
    If ReadFile_(*ctx\handle, *buf, bytesToRead, @bytesRead, 0) = 0
      gWinLastError = GetLastError_()
      ProcedureReturn -1
    EndIf
    gWinLastBytes + bytesRead
    ProcedureReturn bytesRead
  EndIf

  ProcedureReturn ReadData(*ctx\file, *buf, bytesToRead)
EndProcedure

Procedure.s TailEngine_ReadContextDecodeRange(FileName.s, startOffset.q, byteCount.q, encMode.i, stripBOM.i, preferWinAPI.i)
  Protected ctx.ReadContext
  Protected *buf
  Protected bufSize.i
  Protected bytesRead.i
  Protected toRead.q
  Protected out.s = ""
  Protected dec.DecodeState
  Protected applyStrip.i

  If OpenReadContext(@ctx, FileName, preferWinAPI) = #False
    ProcedureReturn ""
  EndIf

  If startOffset < 0 : startOffset = 0 : EndIf
  If startOffset > ctx\size : startOffset = ctx\size : EndIf
  If byteCount < 0 Or startOffset + byteCount > ctx\size
    byteCount = ctx\size - startOffset
  EndIf
  If ReadContextSeek(@ctx, startOffset) = 0
    CloseReadContext(@ctx)
    ProcedureReturn ""
  EndIf

  applyStrip = Bool(stripBOM And startOffset = 0)
  DecodeStateInit(@dec, applyStrip)
  toRead = byteCount
  *buf = AllocateMemory(#CHUNK_SIZE + 8)
  If *buf = 0
    CloseReadContext(@ctx)
    ProcedureReturn ""
  EndIf

  While toRead > 0
    bufSize = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf
    bytesRead = ReadContextRead(@ctx, *buf, bufSize)
    If bytesRead <= 0
      Break
    EndIf
    out + DecodeChunkSafe(@dec, *buf, bytesRead, encMode)
    toRead - bytesRead
  Wend

  out + DecodeStateFlush(@dec, encMode)
  FreeMemory(*buf)

  If ctx\useWinAPI
    gWinLastSize = ctx\size
  Else
    gPBLastSize = ctx\size
  EndIf

  CloseReadContext(@ctx)
  ProcedureReturn out
EndProcedure

Procedure.q ReadContextScanLastLines(FileName.s, Lines.i, preferWinAPI.i)
  Protected ctx.ReadContext
  Protected *buf
  Protected pos.q
  Protected startOffset.q = 0
  Protected needLF.i
  Protected lfCount.i = 0
  Protected bufSize.i
  Protected bytesRead.i
  Protected lastByte.a
  Protected i.i

  If Lines <= 0
    ProcedureReturn 0
  EndIf
  If OpenReadContext(@ctx, FileName, preferWinAPI) = #False
    ProcedureReturn -1
  EndIf
  If ctx\size <= 0
    CloseReadContext(@ctx)
    ProcedureReturn 0
  EndIf

  needLF = Lines
  If ReadContextSeek(@ctx, ctx\size - 1)
    If ReadContextRead(@ctx, @lastByte, 1) = 1 And lastByte = 10
      needLF + 1
    EndIf
  EndIf

  *buf = AllocateMemory(#CHUNK_SIZE)
  If *buf = 0
    CloseReadContext(@ctx)
    ProcedureReturn 0
  EndIf

  pos = ctx\size
  While pos > 0 And lfCount < needLF
    bufSize = #CHUNK_SIZE
    If pos < bufSize : bufSize = pos : EndIf
    pos - bufSize

    If ReadContextSeek(@ctx, pos) = 0
      Break
    EndIf
    bytesRead = ReadContextRead(@ctx, *buf, bufSize)
    If bytesRead <= 0
      Break
    EndIf

    For i = bytesRead - 1 To 0 Step -1
      If PeekA(*buf + i) = 10
        lfCount + 1
        If lfCount >= needLF
          startOffset = pos + i + 1
          Break
        EndIf
      EndIf
    Next
  Wend

  FreeMemory(*buf)
  CloseReadContext(@ctx)
  ProcedureReturn startOffset
EndProcedure

Procedure.s TailEngine_ReadLastNLines(FileName.s, Lines.i, encMode.i, stripBOM.i)
  Protected startOffset.q

  If Lines <= 0 : ProcedureReturn "" : EndIf
  startOffset = ReadContextScanLastLines(FileName, Lines, #False)
  If startOffset < 0 : ProcedureReturn "" : EndIf
  ProcedureReturn TailEngine_ReadContextDecodeRange(FileName, startOffset, -1, encMode, stripBOM, #False)
EndProcedure

Procedure.s TailEngine_ReadLastNBytes(FileName.s, Bytes.q, encMode.i, stripBOM.i)
  Protected size.q = TailEngine_AnyFileSize(FileName)
  Protected start.q

  If size < 0
    ProcedureReturn ""
  EndIf
  If Bytes < 0 : Bytes = 0 : EndIf
  If Bytes > size : Bytes = size : EndIf
  start = size - Bytes
  If encMode <> #ENC_ANSI
    start = AdjustUTF8StartOffsetForFile(FileName, size, start, #False)
  EndIf
  ProcedureReturn TailEngine_ReadContextDecodeRange(FileName, start, size - start, encMode, stripBOM, #False)
EndProcedure

Procedure.s TailEngine_ReadLastNBytesWinAPI(FileName.s, Bytes.q, encMode.i, stripBOM.i)
  Protected size.q = TailEngine_WinFileSize(FileName)
  Protected start.q

  If size < 0
    ProcedureReturn ""
  EndIf
  If Bytes < 0 : Bytes = 0 : EndIf
  If Bytes > size : Bytes = size : EndIf
  start = size - Bytes
  If encMode <> #ENC_ANSI
    start = AdjustUTF8StartOffsetForFile(FileName, size, start, #True)
  EndIf
  ProcedureReturn TailEngine_ReadContextDecodeRange(FileName, start, size - start, encMode, stripBOM, #True)
EndProcedure

Procedure.s TailEngine_ReadLastNLinesWinAPI(FileName.s, Lines.i, encMode.i, stripBOM.i)
  Protected startOffset.q

  If Lines <= 0 : ProcedureReturn "" : EndIf
  startOffset = ReadContextScanLastLines(FileName, Lines, #True)
  If startOffset < 0 : ProcedureReturn "" : EndIf
  ProcedureReturn TailEngine_ReadContextDecodeRange(FileName, startOffset, -1, encMode, stripBOM, #True)
EndProcedure
