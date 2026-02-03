EnableExplicit

#DEFAULT_LINES = 10
#CHUNK_SIZE    = 8192
#APP_NAME = "PB_Tails_GUI"

Global version.s ="v1.0.0.0"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Enumeration
  #ENC_AUTO = 0
  #ENC_UTF8
  #ENC_ANSI
EndEnumeration

Structure Options
  lines.i
  bytes.q
  follow.i
  followByName.i
  files.s[100]  ; Support up to 100 files
  fileCount.i
  encMode.i
  useOEM.i
  stripBOM.i
  verbose.i
  quiet.i
  sleepInterval.f
  useStdin.i
EndStructure

Import "kernel32.lib"
  GetConsoleProcessList(*ProcessList, ProcessCount)
  WinGetStdHandle(nStdHandle) As "GetStdHandle"
  WinReadFile(hFile, *Buffer, nNumberOfBytesToRead, *lpNumberOfBytesRead, *lpOverlapped) As "ReadFile"
  WinWriteFile(hFile, *Buffer, nNumberOfBytesToWrite, *lpNumberOfBytesWritten, *lpOverlapped) As "WriteFile"
  WinGetFullPathName(lpFileName, nBufferLength, lpBuffer, *lpFilePart) As "GetFullPathNameW"
EndImport

#STD_INPUT_HANDLE = -10
#STD_OUTPUT_HANDLE = -11

; WinAPI file access (for logs that PureBasic can't open while being written)
#GENERIC_READ = $80000000
#FILE_SHARE_READ   = 1
#FILE_SHARE_WRITE  = 2
#FILE_SHARE_DELETE = 4
#OPEN_EXISTING = 3
#FILE_ATTRIBUTE_NORMAL = $80
#INVALID_HANDLE_VALUE = -1
#FILE_BEGIN = 0

; ListBox messages for ListViewGadget (Windows)
#LB_GETCOUNT = $018B
#LB_GETTOPINDEX = $018E
#LB_SETTOPINDEX = $0197
#LB_GETITEMHEIGHT = $01A1

Global gWinLastError.l
Global gWinLastBytes.q

Procedure.i WinOpenForRead(FileName.s)
  ; Use maximal share flags so we can read files that are actively written.
  ProcedureReturn CreateFile_(@FileName, #GENERIC_READ, #FILE_SHARE_READ | #FILE_SHARE_WRITE | #FILE_SHARE_DELETE, 0, #OPEN_EXISTING, #FILE_ATTRIBUTE_NORMAL, 0)
EndProcedure

Procedure.q WinFileSize(FileName.s)
  Protected h.i = WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn -1
  EndIf

  Protected size.q
  If GetFileSizeEx_(h, @size) = 0
    CloseHandle_(h)
    ProcedureReturn -1
  EndIf

  CloseHandle_(h)
  ProcedureReturn size
EndProcedure

Procedure.q AnyFileSize(FileName.s)
  Protected s.q = FileSize(FileName)
  If s < 0
    s = WinFileSize(FileName)
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.i CanOpenForReadWinAPI(FileName.s)
  Protected h.i = WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn #False
  EndIf
  CloseHandle_(h)
  ProcedureReturn #True
EndProcedure

Procedure.i OpenForRead(FileName.s)
  ; Try normal open first, then shared-read (needed for many Windows logs).
  Protected f.i = ReadFile(#PB_Any, FileName)
  If f = 0
    f = ReadFile(#PB_Any, FileName, #PB_File_SharedRead)
  EndIf
  ProcedureReturn f
EndProcedure

Procedure.i CanOpenForRead(FileName.s)
  Protected f.i = OpenForRead(FileName)
  If f = 0 : ProcedureReturn #False : EndIf
  CloseFile(f)
  ProcedureReturn #True
EndProcedure

Procedure.i CanOpenForReadAny(FileName.s)
  If CanOpenForRead(FileName)
    ProcedureReturn #True
  EndIf
  ProcedureReturn CanOpenForReadWinAPI(FileName)
EndProcedure

Procedure.s NormalizePath(p.s)
  ; Normalize relative paths and remove any ".\\" / "..\\" segments.
  Protected bufLen.i = 512
  Protected out.s
  Protected r.i

  If p = "" : ProcedureReturn "" : EndIf

  out = Space(bufLen)
  r = WinGetFullPathName(p, bufLen, @out, 0)
  If r <= 0
    ProcedureReturn p
  EndIf
  If r > bufLen
    bufLen = r + 1
    out = Space(bufLen)
    r = WinGetFullPathName(p, bufLen, @out, 0)
    If r <= 0
      ProcedureReturn p
    EndIf
  EndIf

  ProcedureReturn Left(out, r)
EndProcedure

Procedure WriteBytesToStdout(*buf, size.q)
  Protected hOut.i = WinGetStdHandle(#STD_OUTPUT_HANDLE)
  Protected written.l
  Protected offset.q = 0
  Protected toWrite.l

  If size <= 0 Or *buf = 0
    ProcedureReturn
  EndIf

  While offset < size
    toWrite = size - offset
    If toWrite > 1073741824 : toWrite = 1073741824 : EndIf
    If WinWriteFile(hOut, *buf + offset, toWrite, @written, 0) = 0
      Break
    EndIf
    If written <= 0
      Break
    EndIf
    offset + written
  Wend
EndProcedure

Procedure PrintLastNBytesRaw(FileName.s, Bytes.q, stripBOM.i)
  Protected file = OpenForRead(FileName)
  Protected size.q, start.q
  Protected bufSize.i, *buf, bytesRead.i
  Protected firstChunk.i = #True

  If file = 0
    ProcedureReturn
  EndIf

  size = Lof(file)
  If Bytes <= 0
    CloseFile(file)
    ProcedureReturn
  EndIf

  If Bytes > size : Bytes = size : EndIf
  start = size - Bytes
  If start < 0 : start = 0 : EndIf

  FileSeek(file, start)

  While Bytes > 0
    bufSize = #CHUNK_SIZE
    If Bytes < bufSize : bufSize = Bytes : EndIf

    *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    bytesRead = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    If stripBOM And firstChunk And start = 0 And bytesRead >= 3
      If PeekA(*buf + 0) = $EF And PeekA(*buf + 1) = $BB And PeekA(*buf + 2) = $BF
        If bytesRead > 3
          WriteBytesToStdout(*buf + 3, bytesRead - 3)
        EndIf
      Else
        WriteBytesToStdout(*buf, bytesRead)
      EndIf
    Else
      WriteBytesToStdout(*buf, bytesRead)
    EndIf

    firstChunk = #False
    FreeMemory(*buf)
    Bytes - bytesRead
  Wend

  CloseFile(file)
EndProcedure

Procedure AddInputFile(*opt.Options, fileName.s)
  If *opt\fileCount >= 100
    ProcedureReturn
  EndIf
  *opt\files[*opt\fileCount] = NormalizePath(fileName)
  *opt\fileCount + 1
EndProcedure

Procedure AddInputArg(*opt.Options, arg.s)
  ; Expand wildcards on Windows (cmd.exe does not expand * / ?)
  Protected dir.s, mask.s
  Protected found.i = 0
  NewList matches.s()

  If FindString(arg, "*") Or FindString(arg, "?")
    dir = GetPathPart(arg)
    mask = GetFilePart(arg)
    If dir = "" : dir = ".\\" : EndIf
    Protected d.i = ExamineDirectory(#PB_Any, dir, mask)
    If d
      While NextDirectoryEntry(d)
        If DirectoryEntryType(d) = #PB_DirectoryEntry_File
          AddElement(matches())
          matches() = dir + DirectoryEntryName(d)
          found + 1
        EndIf
      Wend
      FinishDirectory(d)
    EndIf

    If found > 0
      SortList(matches(), #PB_Sort_Ascending)
      ForEach matches()
        AddInputFile(*opt, matches())
      Next
    Else
      ; If nothing matched, keep the literal pattern (matches typical cmd behavior)
      AddInputFile(*opt, arg)
    EndIf
  Else
    AddInputFile(*opt, arg)
  EndIf
EndProcedure

Procedure.i ShouldPause()
  ; If there's only 1 process attached to this console, we're likely launched
  ; by double-click (a new console created for the app). If there are 2+, a
  ; parent console (cmd/powershell) exists and we should not pause.
  Dim processes.l(1)
  Protected count.l = GetConsoleProcessList(@processes(0), ArraySize(processes()))
  If count <= 1
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.q ParseByteSuffix(value.s)
  Protected len.i = Len(value)
  Protected suffix.s = ""
  Protected numStr.s = value
  Protected num.q = 0
  
  If len > 1
    suffix.s = LCase(Right(value, 1))
    If suffix.s = "b" Or suffix.s = "k" Or suffix.s = "m"
      numStr = Left(value, len - 1)
    Else
      suffix.s = ""
    EndIf
  EndIf
  
  num = Val(numStr)
  
  Select suffix.s
    Case "b"
      ProcedureReturn num * 512
    Case "k"
      ProcedureReturn num * 1024
    Case "m"
      ProcedureReturn num * 1024 * 1024
    Default
      ProcedureReturn num
  EndSelect
EndProcedure

Procedure.i ParseArgs(*opt.Options)
  Protected i, argc = CountProgramParameters()
  Protected p.s, v.s

  *opt\lines   = #DEFAULT_LINES
  *opt\bytes   = -1
  *opt\follow  = #False
  *opt\followByName = #False
  *opt\fileCount = 0
  *opt\encMode = #ENC_AUTO
  *opt\useOEM  = #False
  *opt\stripBOM = #False
  *opt\verbose = #False
  *opt\quiet   = #False
  *opt\sleepInterval = 0.2
  *opt\useStdin = #False

  i = 0
  While i < argc
    p = ProgramParameter(i)

    If p = "-n"
      If i + 1 >= argc : ProcedureReturn #False : EndIf
      *opt\lines = Val(ProgramParameter(i + 1))
      If *opt\lines < 0 : *opt\lines = 0 : EndIf
      i + 2
      Continue

    ElseIf Left(p, 3) = "-n="
      *opt\lines = Val(Mid(p, 4))
      If *opt\lines < 0 : *opt\lines = 0 : EndIf
      i + 1
      Continue

    ElseIf p = "-f"
      *opt\follow = #True
      i + 1
      Continue

    ElseIf p = "-F"
      *opt\follow = #True
      *opt\followByName = #True
      i + 1
      Continue

    ElseIf p = "-c"
      If i + 1 >= argc : ProcedureReturn #False : EndIf
      *opt\bytes = ParseByteSuffix(ProgramParameter(i + 1))
      If *opt\bytes < 0 : *opt\bytes = 0 : EndIf
      i + 2
      Continue

    ElseIf Left(p, 3) = "-c="
      *opt\bytes = ParseByteSuffix(Mid(p, 4))
      If *opt\bytes < 0 : *opt\bytes = 0 : EndIf
      i + 1
      Continue

    ElseIf p = "-w"
      *opt\useOEM = #True
      i + 1
      Continue

    ElseIf p = "--strip-bom"
      *opt\stripBOM = #True
      i + 1
      Continue

    ElseIf p = "-v" Or p = "--verbose"
      ; GNU tail behavior: last header flag wins
      *opt\verbose = #True
      *opt\quiet = #False
      i + 1
      Continue

    ElseIf p = "-q" Or p = "--quiet" Or p = "--silent"
      ; GNU tail behavior: last header flag wins
      *opt\quiet = #True
      *opt\verbose = #False
      i + 1
      Continue

    ElseIf p = "-s"
      If i + 1 >= argc : ProcedureReturn #False : EndIf
      *opt\sleepInterval = ValF(ProgramParameter(i + 1))
      If *opt\sleepInterval <= 0 : *opt\sleepInterval = 0.2 : EndIf
      i + 2
      Continue

    ElseIf Left(p, 3) = "-s="
      *opt\sleepInterval = ValF(Mid(p, 4))
      If *opt\sleepInterval <= 0 : *opt\sleepInterval = 0.2 : EndIf
      i + 1
      Continue

    ElseIf p = "-e"
      If i + 1 >= argc : ProcedureReturn #False : EndIf
      v = LCase(ProgramParameter(i + 1))
      If v = "auto"
        *opt\encMode = #ENC_AUTO
      ElseIf v = "utf8" Or v = "utf-8"
        *opt\encMode = #ENC_UTF8
      ElseIf v = "ansi"
        *opt\encMode = #ENC_ANSI
      Else
        ProcedureReturn #False
      EndIf
      i + 2
      Continue

    ElseIf Left(p, 3) = "-e="
      v = LCase(Mid(p, 4))
      If v = "auto"
        *opt\encMode = #ENC_AUTO
      ElseIf v = "utf8" Or v = "utf-8"
        *opt\encMode = #ENC_UTF8
      ElseIf v = "ansi"
        *opt\encMode = #ENC_ANSI
      Else
        ProcedureReturn #False
      EndIf
      i + 1
      Continue

    ElseIf p = "-"
      *opt\useStdin = #True
      i + 1
      Continue

    ElseIf Left(p, 1) = "-"
      ProcedureReturn #False

    Else
      AddInputArg(*opt, p)
      i + 1
      Continue
    EndIf
  Wend

  ; If no files and no stdin, show usage
  If *opt\fileCount = 0 And *opt\useStdin = #False
    ProcedureReturn #False
  EndIf

  ; If -c is used, ignore -n.
  If *opt\bytes >= 0
    *opt\lines = 0
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i IsValidUTF8(*buf, size.i)
  ; Minimal UTF-8 validation (good enough to distinguish most ANSI logs from UTF-8)
  Protected i.i = 0
  Protected b.a, need.i

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
      ; allow partial multibyte at buffer end
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

Procedure.s DecodeBytes(*buf, size.i, encMode.i)
  Select encMode
    Case #ENC_UTF8
      ProcedureReturn PeekS(*buf, size, #PB_UTF8)
    Case #ENC_ANSI
      ProcedureReturn PeekS(*buf, size, #PB_Ascii)
    Default
      ; In auto mode, avoid chunk-boundary false negatives by only rejecting
      ; when the byte sequence is clearly invalid.
      If IsValidUTF8(*buf, size)
        ProcedureReturn PeekS(*buf, size, #PB_UTF8)
      Else
        ProcedureReturn PeekS(*buf, size, #PB_Ascii)
      EndIf
  EndSelect
EndProcedure

Procedure.s StripUTF8BOM(s.s)
  ; Remove U+FEFF if it exists at the very beginning of the string
  If Len(s) > 0
    If Asc(Left(s, 1)) = $FEFF
      ProcedureReturn Mid(s, 2)
    EndIf
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.s ToOEMIfNeeded(s.s, useOEM.i)
  If useOEM = #False
    ProcedureReturn s
  EndIf

  ; Convert Unicode string to OEM code page for cmd.exe readability.
  ; CharToOem_ expects source + destination buffers.
  Protected src.s = s
  Protected *out = AllocateMemory((Len(src) + 1) * SizeOf(Character))
  If *out = 0
    ProcedureReturn s
  EndIf

  CharToOem_(@src, *out)

  Protected result.s = PeekS(*out, -1, #PB_Ascii)
  FreeMemory(*out)
  ProcedureReturn result
EndProcedure

Procedure.s ReadFromStdin(Lines.i, Bytes.q, encMode.i, stripBOM.i)
  ; Read stdin using WinAPI so EOF works for pipes/redirection.
  Protected hIn.i = WinGetStdHandle(#STD_INPUT_HANDLE)
  Protected chunkSize.i = #CHUNK_SIZE
  Protected *chunk = AllocateMemory(chunkSize)
  Protected bytesRead.l

  If *chunk = 0
    ProcedureReturn ""
  EndIf

  Protected result.s = ""

  If Bytes >= 0
    If Bytes <= 0
      While WinReadFile(hIn, *chunk, chunkSize, @bytesRead, 0) And bytesRead > 0
      Wend
      FreeMemory(*chunk)
      ProcedureReturn ""
    EndIf

    If Bytes > 100000000 : Bytes = 100000000 : EndIf

    Protected *ring = AllocateMemory(Bytes)
    If *ring = 0
      While WinReadFile(hIn, *chunk, chunkSize, @bytesRead, 0) And bytesRead > 0
      Wend
      FreeMemory(*chunk)
      ProcedureReturn ""
    EndIf

    Protected writePos.q = 0
    Protected fill.q = 0

    While WinReadFile(hIn, *chunk, chunkSize, @bytesRead, 0) And bytesRead > 0
      Protected copyPos.q = 0
      While copyPos < bytesRead
        Protected space.q = Bytes - writePos
        Protected toCopy.q = bytesRead - copyPos
        If toCopy > space : toCopy = space : EndIf
        CopyMemory(*chunk + copyPos, *ring + writePos, toCopy)
        writePos + toCopy
        If writePos >= Bytes : writePos = 0 : EndIf
        copyPos + toCopy
      Wend

      fill + bytesRead
      If fill > Bytes : fill = Bytes : EndIf
    Wend

    Protected *outBuf = AllocateMemory(fill)
    If *outBuf
      Protected startPos.q
      If fill < Bytes
        startPos = 0
      Else
        startPos = writePos
      EndIf

      Protected firstPart.q = Bytes - startPos
      If firstPart > fill : firstPart = fill : EndIf
      CopyMemory(*ring + startPos, *outBuf, firstPart)
      If firstPart < fill
        CopyMemory(*ring, *outBuf + firstPart, fill - firstPart)
      EndIf

      result = DecodeBytes(*outBuf, fill, encMode)
      FreeMemory(*outBuf)
    EndIf

    FreeMemory(*ring)
  Else
    If Lines <= 0
      While WinReadFile(hIn, *chunk, chunkSize, @bytesRead, 0) And bytesRead > 0
      Wend
      FreeMemory(*chunk)
      ProcedureReturn ""
    EndIf

    Protected keep.i = Lines
    If keep > 100000 : keep = 100000 : EndIf

    Dim ringLines.s(keep - 1)
    Protected idx.i = 0
    Protected count.i = 0

    Protected *lineBuf = AllocateMemory(#CHUNK_SIZE)
    Protected lineLen.i = 0
    Protected lineCap.i = #CHUNK_SIZE

    If *lineBuf = 0
      FreeMemory(*chunk)
      ProcedureReturn ""
    EndIf

    While WinReadFile(hIn, *chunk, chunkSize, @bytesRead, 0) And bytesRead > 0
      Protected b.i
      For b = 0 To bytesRead - 1
        Protected ch.a = PeekA(*chunk + b)
        If ch = 10
          ; finalize line
          Protected l.i = lineLen
          If l > 0 And PeekA(*lineBuf + l - 1) = 13
            l - 1
          EndIf
          ringLines(idx) = DecodeBytes(*lineBuf, l, encMode)
          idx + 1
          If idx >= keep : idx = 0 : EndIf
          If count < keep : count + 1 : EndIf
          lineLen = 0
        Else
          If lineLen + 1 > lineCap
            lineCap + #CHUNK_SIZE
            *lineBuf = ReAllocateMemory(*lineBuf, lineCap)
            If *lineBuf = 0
              FreeMemory(*chunk)
              ProcedureReturn ""
            EndIf
          EndIf
          PokeA(*lineBuf + lineLen, ch)
          lineLen + 1
        EndIf
      Next
    Wend

    ; final partial line (no trailing LF)
    If lineLen > 0
      ringLines(idx) = DecodeBytes(*lineBuf, lineLen, encMode)
      idx + 1
      If idx >= keep : idx = 0 : EndIf
      If count < keep : count + 1 : EndIf
    EndIf

    FreeMemory(*lineBuf)

    Protected start.i
    If count < keep
      start = 0
    Else
      start = idx
    EndIf

    Protected j.i, k.i
    For j = 0 To count - 1
      k = start + j
      While k >= keep : k - keep : Wend
      result + ringLines(k) + Chr(13) + Chr(10)
    Next
  EndIf

  FreeMemory(*chunk)

  If stripBOM
    result = StripUTF8BOM(result)
  EndIf

  ProcedureReturn result
EndProcedure

Procedure.s ReadLastNLines(FileName.s, Lines.i, encMode.i, stripBOM.i)
  ; Byte-based scan for LF so line counting is not impacted by decoding.
  Protected file
  Protected size.q, pos.q
  Protected bufSize.i, *buf, bytesRead.i
  Protected lfCount.i = 0
  Protected needLF.i
  Protected startOffset.q = 0
  Protected lastByte.a
  Protected s.s = ""
  Protected toRead.q

  If Lines <= 0 : ProcedureReturn "" : EndIf

  file = OpenForRead(FileName)
  If file = 0 : ProcedureReturn "" : EndIf

  size = Lof(file)
  If size <= 0
    CloseFile(file)
    ProcedureReturn ""
  EndIf

  ; If file ends with LF, we need one extra LF to get N full lines.
  needLF = Lines
  FileSeek(file, size - 1)
  If ReadData(file, @lastByte, 1) = 1
    If lastByte = 10
      needLF + 1
    EndIf
  EndIf

  pos = size
  While pos > 0 And lfCount < needLF
    bufSize = #CHUNK_SIZE
    If pos < bufSize : bufSize = pos : EndIf

    pos - bufSize
    FileSeek(file, pos)

    *buf = AllocateMemory(bufSize)
    If *buf = 0
      Break
    EndIf

    bytesRead = ReadData(file, *buf, bufSize)
    If bytesRead > 0
      Protected i.i
      For i = bytesRead - 1 To 0 Step -1
        If PeekA(*buf + i) = 10
          lfCount + 1
          If lfCount >= needLF
            startOffset = pos + i + 1
            Break
          EndIf
        EndIf
      Next
    EndIf

    FreeMemory(*buf)

    If lfCount >= needLF
      Break
    EndIf
  Wend

  If startOffset < 0 : startOffset = 0 : EndIf
  If startOffset > size : startOffset = size : EndIf

  FileSeek(file, startOffset)
  toRead = size - startOffset

  While toRead > 0
    bufSize = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    bytesRead = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    s + DecodeBytes(*buf, bytesRead, encMode)
    FreeMemory(*buf)
    toRead - bytesRead
  Wend

  CloseFile(file)

  If stripBOM And startOffset = 0
    s = StripUTF8BOM(s)
  EndIf

  ProcedureReturn s
EndProcedure

Procedure.s ReadLastNBytes(FileName.s, Bytes.q, encMode.i, stripBOM.i)
  Protected file = OpenForRead(FileName)
  Protected size.q, start.q
  Protected bufSize.i, *buf, bytesRead.i
  Protected s.s

  If file = 0
    ProcedureReturn ""
  EndIf

  size = Lof(file)
  If Bytes < 0 : Bytes = 0 : EndIf
  If Bytes > size : Bytes = size : EndIf
  start = size - Bytes

  FileSeek(file, start)

  While Bytes > 0
    bufSize = #CHUNK_SIZE
    If Bytes < bufSize : bufSize = Bytes : EndIf

    *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    bytesRead = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    s + DecodeBytes(*buf, bytesRead, encMode)

    FreeMemory(*buf)
    Bytes - bytesRead
  Wend

  CloseFile(file)

  If stripBOM
    s = StripUTF8BOM(s)
  EndIf

  ProcedureReturn s
EndProcedure

Procedure.q PrintFromOffset(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i, useOEM.i)
  ; Note: decoding per-chunk can mis-detect UTF-8 if a multibyte sequence is split.
  ; The UTF-8 validator allows partial sequences at the end of a chunk to reduce this.
  Protected file = OpenForRead(FileName)
  Protected size.q, toRead.q
  Protected bufSize.i, *buf, bytesRead.i
  Protected s.s

  If file = 0
    ProcedureReturn StartOffset
  EndIf

  size = Lof(file)
  If StartOffset > size : StartOffset = size : EndIf

  FileSeek(file, StartOffset)
  toRead = size - StartOffset

  While toRead > 0
    bufSize = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    bytesRead = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    s = DecodeBytes(*buf, bytesRead, encMode)

    If stripBOM And firstRead And StartOffset = 0
      s = StripUTF8BOM(s)
    EndIf

    If useOEM
      s = ToOEMIfNeeded(s, #True)
    EndIf

    Print(s)

    FreeMemory(*buf)
    StartOffset + bytesRead
    toRead - bytesRead
  Wend

  CloseFile(file)
  ProcedureReturn StartOffset
EndProcedure

Procedure PrintFileHeader(fileName.s)
  PrintN("==> " + fileName + " <==")
EndProcedure

Procedure FollowFile(FileName.s, StartOffset.q, encMode.i, stripBOM.i, useOEM.i, sleepInterval.f)
  Protected offset.q = StartOffset
  Protected curSize.q
  Protected firstRead.i = #True

  While #True
    Protected delayMs.i = Int(sleepInterval * 1000.0)
    If delayMs < 1 : delayMs = 200 : EndIf
    Delay(delayMs)

    curSize = FileSize(FileName)
    If curSize < 0
      Continue
    EndIf

    If curSize < offset
      offset = 0
      firstRead = #True
    EndIf

    If curSize > offset
      offset = PrintFromOffset(FileName, offset, encMode, stripBOM, firstRead, useOEM)
      firstRead = #False
    EndIf
  Wend
EndProcedure

Procedure FollowFileByName(FileName.s, encMode.i, stripBOM.i, useOEM.i, sleepInterval.f)
  ; Similar to GNU tail -F: keep trying to open by name, reopen if replaced.
  Protected lastSize.q = -1
  Protected lastStamp.q = -1
  Protected offset.q = 0
  Protected firstRead.i = #True

  While #True
    Protected delayMs.i = Int(sleepInterval * 1000.0)
    If delayMs < 1 : delayMs = 200 : EndIf
    Delay(delayMs)

    Protected curSize.q = FileSize(FileName)
    If curSize < 0
      ; file missing temporarily
      lastSize = -1
      lastStamp = -1
      offset = 0
      firstRead = #True
      Continue
    EndIf

    ; If file changed (best-effort): size dropped or timestamp changed.
    Protected curStamp.q = GetFileDate(FileName, #PB_Date_Modified)
    If lastStamp <> -1 And curStamp <> lastStamp
      offset = 0
      firstRead = #True
    ElseIf lastSize <> -1 And curSize < offset
      offset = 0
      firstRead = #True
    EndIf

    lastSize = curSize
    lastStamp = curStamp

    If curSize > offset
      offset = PrintFromOffset(FileName, offset, encMode, stripBOM, firstRead, useOEM)
      firstRead = #False
    EndIf
  Wend
EndProcedure

; ---------------- GUI ----------------

Enumeration Gadgets
  #gFiles
  #gAdd
  #gRemove
  #gClear
  #gHelp
  #gPattern
  #gAddPattern
  #gSourceFiles
  #gSourcePaste
  #gPaste
  #gModeLines
  #gModeBytes
  #gLines
  #gBytes
  #gEnc
  #gStripBOM
  #gUseOEM
  #gVerbose
  #gQuiet
  #gFollow
  #gFollowByName
  #gSleep
  #gDebugLog
  #gDebugLogPath
  #gDebugLogBrowse
  #gCaptureText
  #gCapturePath
  #gCaptureBrowse
  #gRun
  #gStop
  #gOutput
  #gStatus
EndEnumeration

Structure FollowState
  active.i
  fileName.s
  offset.q
  lastSize.q
  lastStamp.q
  firstRead.i
  followByName.i
  encMode.i
  stripBOM.i
  useOEM.i
EndStructure

Global follow.FollowState

Global gLogEnabled.i
Global gLogPath.s
Global gLogFile.i = 0

Global gCapEnabled.i
Global gCapPath.s
Global gCapFile.i = 0

Global gLogSessionActive.i

Global gWinLastSize.q
Global gPBLastSize.q
Global gLastReadPath.s

#SW_SHOWNORMAL = 1

Procedure OpenHelpFile()
  Protected helpPath.s = AppPath + "pb_tails_gui_help.html"
  If FileSize(helpPath) < 0
    MessageRequester(#APP_NAME, "Help file not found:" + Chr(10) + helpPath)
    ProcedureReturn
  EndIf

  ; Open in default browser.
  ShellExecute_(0, "open", helpPath, 0, 0, #SW_SHOWNORMAL)
EndProcedure

Procedure LogClose()
  If gLogFile
    CloseFile(gLogFile)
    gLogFile = 0
  EndIf
EndProcedure

Procedure LogOpenIfNeeded()
  If gLogEnabled = #False
    ProcedureReturn
  EndIf

  If gLogFile
    ProcedureReturn
  EndIf

  If gLogPath = ""
    gLogPath = GetTemporaryDirectory() + "pb_tails_gui.debug.log"
  EndIf

  gLogFile = OpenFile(#PB_Any, gLogPath, #PB_File_Append)
EndProcedure

Procedure LogLine(msg.s)
  If gLogEnabled = #False
    ProcedureReturn
  EndIf

  LogOpenIfNeeded()
  If gLogFile = 0
    ProcedureReturn
  EndIf

  Protected ts.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  WriteStringN(gLogFile, ts + " | " + msg, #PB_UTF8)
EndProcedure

Procedure CapClose()
  If gCapFile
    CloseFile(gCapFile)
    gCapFile = 0
  EndIf
EndProcedure

Procedure CapOpenIfNeeded()
  If gCapEnabled = #False
    ProcedureReturn
  EndIf

  If gCapFile
    ProcedureReturn
  EndIf

  If gCapPath = ""
    gCapPath = GetTemporaryDirectory() + "pb_tails_gui.capture.txt"
  EndIf

  gCapFile = OpenFile(#PB_Any, gCapPath, #PB_File_Append)
EndProcedure

Procedure CapWriteText(text.s)
  If gCapEnabled = #False
    ProcedureReturn
  EndIf
  If text = ""
    ProcedureReturn
  EndIf

  CapOpenIfNeeded()
  If gCapFile = 0
    ProcedureReturn
  EndIf

  ; Keep capture file readable in Windows editors.
  Protected s.s = ReplaceString(text, Chr(13) + Chr(10), Chr(10))
  s = ReplaceString(s, Chr(13), Chr(10))
  s = ReplaceString(s, Chr(10), Chr(13) + Chr(10))
  WriteString(gCapFile, s, #PB_UTF8)
EndProcedure

Procedure AppendTextToEditor(gadget.i, text.s)
  Protected s.s = text
  If s = "" : ProcedureReturn : EndIf

  s = ReplaceString(s, Chr(13) + Chr(10), Chr(10))
  s = ReplaceString(s, Chr(13), Chr(10))

  ; If the user is already at the bottom, keep the view pinned.
  Protected hWnd.i = GadgetID(gadget)
  Protected cntBefore.i = SendMessage_(hWnd, #LB_GETCOUNT, 0, 0)
  Protected pinToBottom.i = #True
  If cntBefore > 0
    Protected topBefore.i = SendMessage_(hWnd, #LB_GETTOPINDEX, 0, 0)
    Protected itemH.i = SendMessage_(hWnd, #LB_GETITEMHEIGHT, 0, 0)
    If itemH <= 0 : itemH = 1 : EndIf
    Protected page.i = GadgetHeight(gadget) / itemH
    If page < 1 : page = 1 : EndIf
    If topBefore + page < cntBefore - 1
      pinToBottom = #False
    EndIf
  EndIf

  Protected lines.i = CountString(s, Chr(10))
  Protected i.i
  Protected part.s

  For i = 1 To lines + 1
    part = StringField(s, i, Chr(10))
    AddGadgetItem(gadget, -1, part)
  Next

  If pinToBottom
    Protected cntAfter.i = SendMessage_(hWnd, #LB_GETCOUNT, 0, 0)
    If cntAfter > 0
      Protected last.i = cntAfter - 1
      SetGadgetState(gadget, last)

      ; Try to keep last item near the bottom of the viewport.
      Protected itemH2.i = SendMessage_(hWnd, #LB_GETITEMHEIGHT, 0, 0)
      If itemH2 <= 0 : itemH2 = 1 : EndIf
      Protected page2.i = GadgetHeight(gadget) / itemH2
      If page2 < 1 : page2 = 1 : EndIf
      Protected newTop.i = last - page2 + 1
      If newTop < 0 : newTop = 0 : EndIf
      SendMessage_(hWnd, #LB_SETTOPINDEX, newTop, 0)
    EndIf
  EndIf

  ; Optional raw capture of what we display.
  CapWriteText(text)
EndProcedure

Procedure ClearOutput()
  ClearGadgetItems(#gOutput)
EndProcedure

Procedure SetStatus(msg.s)
  SetGadgetText(#gStatus, msg)
EndProcedure

Procedure.i GetEncModeFromUI()
  Protected sel.i = GetGadgetState(#gEnc)
  Select sel
    Case 1 : ProcedureReturn #ENC_UTF8
    Case 2 : ProcedureReturn #ENC_ANSI
    Default : ProcedureReturn #ENC_AUTO
  EndSelect
EndProcedure

Procedure.f GetSleepIntervalFromUI()
  Protected s.s = Trim(GetGadgetText(#gSleep))
  Protected v.f = ValF(s)
  If v <= 0.0 : v = 0.2 : EndIf
  ProcedureReturn v
EndProcedure

Procedure.s ReadFromOffsetToString(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i)
  Protected file = OpenForRead(FileName)
  If file = 0
    ProcedureReturn ""
  EndIf

  Protected size.q = Lof(file)
  If StartOffset > size : StartOffset = size : EndIf
  FileSeek(file, StartOffset)
  Protected toRead.q = size - StartOffset
  Protected out.s = ""

  While toRead > 0
    Protected bufSize.i = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    Protected *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    Protected bytesRead.i = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected s.s = DecodeBytes(*buf, bytesRead, encMode)
    If stripBOM And firstRead And StartOffset = 0
      s = StripUTF8BOM(s)
    EndIf

    out + s
    FreeMemory(*buf)
    StartOffset + bytesRead
    toRead - bytesRead
    firstRead = #False
  Wend

  CloseFile(file)
  ProcedureReturn out
EndProcedure


Procedure.q AppendFromOffsetToOutput(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i, useOEM.i)
  ; Reads from StartOffset to EOF, appends to GUI output, returns new offset.
  ; Returns -1 if the file could not be opened.
  Protected file.i = OpenForRead(FileName)
  If file = 0
    ProcedureReturn -1
  EndIf

  Protected size.q = Lof(file)
  gPBLastSize = size
  If StartOffset > size : StartOffset = size : EndIf
  FileSeek(file, StartOffset)
  Protected toRead.q = size - StartOffset

  While toRead > 0
    Protected bufSize.i = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    Protected *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    Protected bytesRead.i = ReadData(file, *buf, bufSize)
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected chunk.s = DecodeBytes(*buf, bytesRead, encMode)
    If stripBOM And firstRead And StartOffset = 0
      chunk = StripUTF8BOM(chunk)
    EndIf
    If useOEM
      chunk = ToOEMIfNeeded(chunk, #True)
    EndIf
    AppendTextToEditor(#gOutput, chunk)
    gLastReadPath = "pb"

    FreeMemory(*buf)
    StartOffset + bytesRead
    toRead - bytesRead
    firstRead = #False
  Wend

  CloseFile(file)
  ProcedureReturn StartOffset
EndProcedure

Procedure.q AppendFromOffsetToOutputWinAPI(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i, useOEM.i)
  ; WinAPI version that can read many "locked" Windows logs.
  gWinLastError = 0
  gWinLastBytes = 0

  Protected h.i = WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    gWinLastError = GetLastError_()
    ProcedureReturn -1
  EndIf

  Protected size.q
  If GetFileSizeEx_(h, @size) = 0
    gWinLastError = GetLastError_()
    CloseHandle_(h)
    ProcedureReturn -1
  EndIf

  gWinLastSize = size

  If StartOffset > size : StartOffset = size : EndIf

  Protected newPos.q
  If SetFilePointerEx_(h, StartOffset, @newPos, #FILE_BEGIN) = 0
    gWinLastError = GetLastError_()
    CloseHandle_(h)
    ProcedureReturn -1
  EndIf

  Protected toRead.q = size - StartOffset
  While toRead > 0
    Protected bufSize.i = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    Protected *buf = AllocateMemory(bufSize)
    If *buf = 0
      Break
    EndIf

    Protected bytesRead.l
    If ReadFile_(h, *buf, bufSize, @bytesRead, 0) = 0
      gWinLastError = GetLastError_()
      FreeMemory(*buf)
      CloseHandle_(h)
      ProcedureReturn -1
    EndIf

    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected chunk.s = DecodeBytes(*buf, bytesRead, encMode)
    If stripBOM And firstRead And StartOffset = 0
      chunk = StripUTF8BOM(chunk)
    EndIf
    If useOEM
      chunk = ToOEMIfNeeded(chunk, #True)
    EndIf
    AppendTextToEditor(#gOutput, chunk)
    gLastReadPath = "winapi"

    FreeMemory(*buf)
    StartOffset + bytesRead
    toRead - bytesRead
    firstRead = #False
    gWinLastBytes + bytesRead
  Wend

  CloseHandle_(h)
  ProcedureReturn StartOffset
EndProcedure

Procedure.s ReadLastNBytesWinAPI(FileName.s, Bytes.q, encMode.i, stripBOM.i)
  Protected h.i = WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn ""
  EndIf

  Protected size.q
  If GetFileSizeEx_(h, @size) = 0
    CloseHandle_(h)
    ProcedureReturn ""
  EndIf

  If Bytes < 0 : Bytes = 0 : EndIf
  If Bytes > size : Bytes = size : EndIf
  Protected start.q = size - Bytes
  If start < 0 : start = 0 : EndIf

  Protected out.s = ""
  Protected newPos.q
  If SetFilePointerEx_(h, start, @newPos, #FILE_BEGIN) = 0
    CloseHandle_(h)
    ProcedureReturn ""
  EndIf

  Protected toRead.q = size - start
  Protected firstRead.i = #True
  While toRead > 0
    Protected bufSize.i = #CHUNK_SIZE
    If toRead < bufSize : bufSize = toRead : EndIf

    Protected *buf = AllocateMemory(bufSize)
    If *buf = 0 : Break : EndIf

    Protected bytesRead.l
    If ReadFile_(h, *buf, bufSize, @bytesRead, 0) = 0
      FreeMemory(*buf)
      Break
    EndIf
    If bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected s.s = DecodeBytes(*buf, bytesRead, encMode)
    If stripBOM And firstRead And start = 0
      s = StripUTF8BOM(s)
    EndIf
    out + s

    FreeMemory(*buf)
    toRead - bytesRead
    firstRead = #False
  Wend

  CloseHandle_(h)
  ProcedureReturn out
EndProcedure

Procedure.s ReadLastNLinesWinAPI(FileName.s, Lines.i, encMode.i, stripBOM.i)
  If Lines <= 0 : ProcedureReturn "" : EndIf

  Protected h.i = WinOpenForRead(FileName)
  If h = #INVALID_HANDLE_VALUE
    ProcedureReturn ""
  EndIf

  Protected size.q
  If GetFileSizeEx_(h, @size) = 0
    CloseHandle_(h)
    ProcedureReturn ""
  EndIf
  If size <= 0
    CloseHandle_(h)
    ProcedureReturn ""
  EndIf

  Protected needLF.i = Lines
  Protected lastByte.a
  Protected newPos.q
  If SetFilePointerEx_(h, size - 1, @newPos, #FILE_BEGIN) <> 0
    Protected br.l
    If ReadFile_(h, @lastByte, 1, @br, 0) <> 0 And br = 1
      If lastByte = 10
        needLF + 1
      EndIf
    EndIf
  EndIf

  Protected pos.q = size
  Protected lfCount.i = 0
  Protected startOffset.q = 0

  While pos > 0 And lfCount < needLF
    Protected bufSize.i = #CHUNK_SIZE
    If pos < bufSize : bufSize = pos : EndIf
    pos - bufSize

    Protected *buf = AllocateMemory(bufSize)
    If *buf = 0
      Break
    EndIf

    If SetFilePointerEx_(h, pos, @newPos, #FILE_BEGIN) = 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected bytesRead.l
    If ReadFile_(h, *buf, bufSize, @bytesRead, 0) = 0 Or bytesRead <= 0
      FreeMemory(*buf)
      Break
    EndIf

    Protected i.i
    For i = bytesRead - 1 To 0 Step -1
      If PeekA(*buf + i) = 10
        lfCount + 1
        If lfCount >= needLF
          startOffset = pos + i + 1
          Break
        EndIf
      EndIf
    Next

    FreeMemory(*buf)

    If lfCount >= needLF
      Break
    EndIf
  Wend

  If startOffset < 0 : startOffset = 0 : EndIf
  If startOffset > size : startOffset = size : EndIf

  Protected out.s = ""
  If SetFilePointerEx_(h, startOffset, @newPos, #FILE_BEGIN) = 0
    CloseHandle_(h)
    ProcedureReturn ""
  EndIf

  Protected toRead.q = size - startOffset
  Protected firstRead.i = #True
  While toRead > 0
    Protected bufSize2.i = #CHUNK_SIZE
    If toRead < bufSize2 : bufSize2 = toRead : EndIf

    Protected *buf2 = AllocateMemory(bufSize2)
    If *buf2 = 0 : Break : EndIf

    Protected bytesRead2.l
    If ReadFile_(h, *buf2, bufSize2, @bytesRead2, 0) = 0 Or bytesRead2 <= 0
      FreeMemory(*buf2)
      Break
    EndIf

    Protected s2.s = DecodeBytes(*buf2, bytesRead2, encMode)
    If stripBOM And firstRead And startOffset = 0
      s2 = StripUTF8BOM(s2)
    EndIf
    out + s2

    FreeMemory(*buf2)
    toRead - bytesRead2
    firstRead = #False
  Wend

  CloseHandle_(h)
  ProcedureReturn out
EndProcedure

Procedure RunTail()
  Protected opt.Options
  Protected i.i
  Protected fileName.s
  Protected out.s
  Protected shouldPrintHeader.i
  Protected totalInputs.i

  ClearOutput()
  SetStatus("")

  gLogEnabled = Bool(GetGadgetState(#gDebugLog))
  gLogPath = Trim(GetGadgetText(#gDebugLogPath))
  gCapEnabled = Bool(GetGadgetState(#gCaptureText))
  gCapPath = Trim(GetGadgetText(#gCapturePath))

  gLogSessionActive = #True
  gLastReadPath = ""
  gWinLastSize = 0
  gPBLastSize = 0

  If gLogEnabled
    LogLine("--- Run ---")
    LogLine("logPath=" + gLogPath)
    LogLine("capEnabled=" + Str(gCapEnabled) + " capPath=" + gCapPath)
  EndIf

  opt\lines = Val(Trim(GetGadgetText(#gLines)))
  If opt\lines < 0 : opt\lines = 0 : EndIf

  opt\bytes = -1
  If GetGadgetState(#gModeBytes)
    opt\bytes = ParseByteSuffix(Trim(GetGadgetText(#gBytes)))
    If opt\bytes < 0 : opt\bytes = 0 : EndIf
    opt\lines = 0
  EndIf

  opt\encMode = GetEncModeFromUI()
  opt\stripBOM = Bool(GetGadgetState(#gStripBOM))
  opt\useOEM = Bool(GetGadgetState(#gUseOEM))
  opt\verbose = Bool(GetGadgetState(#gVerbose))
  opt\quiet = Bool(GetGadgetState(#gQuiet))
  opt\follow = Bool(GetGadgetState(#gFollow))
  opt\followByName = Bool(GetGadgetState(#gFollowByName))
  opt\sleepInterval = GetSleepIntervalFromUI()

  If gLogEnabled
    If opt\bytes >= 0
      LogLine("mode=bytes")
    Else
      LogLine("mode=lines")
    EndIf
    LogLine("lines=" + Str(opt\lines) + " bytes=" + Str(opt\bytes) + " follow=" + Str(opt\follow) + " followByName=" + Str(opt\followByName))
    LogLine("encMode=" + Str(opt\encMode) + " stripBOM=" + Str(opt\stripBOM) + " useOEM=" + Str(opt\useOEM) + " sleep=" + StrF(opt\sleepInterval))
  EndIf

  If opt\quiet
    opt\verbose = #False
    SetGadgetState(#gVerbose, 0)
  EndIf
  If opt\verbose
    opt\quiet = #False
    SetGadgetState(#gQuiet, 0)
  EndIf

  Protected usingPaste.i = Bool(GetGadgetState(#gSourcePaste))

  If usingPaste
    Protected text.s = GetGadgetText(#gPaste)
    If opt\bytes >= 0
      If opt\bytes = 0
        out = ""
      Else
        out = Right(text, opt\bytes)
      EndIf
    Else
      Protected tmp.s = ReplaceString(text, Chr(13) + Chr(10), Chr(10))
      tmp = ReplaceString(tmp, Chr(13), Chr(10))
      Protected lines.i = CountString(tmp, Chr(10))
      If Right(tmp, 1) = Chr(10) : lines - 1 : EndIf
      Protected start.i = lines - opt\lines + 1
      If start < 1 : start = 1 : EndIf
      out = ""
      Protected j.i
      For j = start To lines
        out + StringField(tmp, j, Chr(10)) + Chr(10)
      Next
    EndIf
    AppendTextToEditor(#gOutput, out)
    If gLogEnabled
      LogLine("source=paste bytesOut=" + Str(Len(out)))
    EndIf
    ProcedureReturn
  EndIf

  opt\fileCount = CountGadgetItems(#gFiles)
  If opt\fileCount <= 0
    SetStatus("Add at least one file")
    ProcedureReturn
  EndIf

  If opt\fileCount > 100 : opt\fileCount = 100 : EndIf
  For i = 0 To opt\fileCount - 1
    opt\files[i] = GetGadgetItemText(#gFiles, i, 0)
  Next

  If gLogEnabled
    LogLine("inputs=" + Str(opt\fileCount))
    For i = 0 To opt\fileCount - 1
      LogLine("file=" + opt\files[i])
    Next
  EndIf

  totalInputs = opt\fileCount
  If opt\quiet
    shouldPrintHeader = #False
  ElseIf opt\verbose
    shouldPrintHeader = #True
  ElseIf totalInputs > 1
    shouldPrintHeader = #True
  Else
    shouldPrintHeader = #False
  EndIf

  For i = 0 To opt\fileCount - 1
    fileName = opt\files[i]
    If CanOpenForReadAny(fileName) = #False
      AppendTextToEditor(#gOutput, "Error: cannot read file (locked?): " + fileName + Chr(10))
      If gLogEnabled
        LogLine("cannotOpen=" + fileName)
      EndIf
      Continue
    EndIf

    If shouldPrintHeader
      If i > 0
        AppendTextToEditor(#gOutput, Chr(10))
      EndIf
      AppendTextToEditor(#gOutput, "==> " + fileName + " <==" + Chr(10))
    EndIf

    If opt\bytes >= 0
      ; GUI displays text; use decoded output.
      out = ReadLastNBytes(fileName, opt\bytes, opt\encMode, opt\stripBOM)
      If out = "" And opt\bytes > 0 And AnyFileSize(fileName) > 0
        out = ReadLastNBytesWinAPI(fileName, opt\bytes, opt\encMode, opt\stripBOM)
      EndIf
    Else
      out = ReadLastNLines(fileName, opt\lines, opt\encMode, opt\stripBOM)
      If out = "" And opt\lines > 0 And AnyFileSize(fileName) > 0
        out = ReadLastNLinesWinAPI(fileName, opt\lines, opt\encMode, opt\stripBOM)
      EndIf
    EndIf

    If gLogEnabled
      LogLine("tail file=" + fileName + " outChars=" + Str(Len(out)))
    EndIf

    If opt\useOEM
      out = ToOEMIfNeeded(out, #True)
    EndIf
    If out = "" And ((opt\bytes >= 0 And opt\bytes > 0) Or (opt\bytes < 0 And opt\lines > 0))
      If AnyFileSize(fileName) > 0
        AppendTextToEditor(#gOutput, "(no output decoded; try encoding utf8/ansi)" + Chr(10))
      EndIf
    Else
      AppendTextToEditor(#gOutput, out)
    EndIf
  Next

  ; Follow mode (single file only)
  If opt\follow And opt\fileCount = 1
    follow\active = #True
    follow\fileName = opt\files[0]
    follow\followByName = opt\followByName
    follow\encMode = opt\encMode
    follow\stripBOM = opt\stripBOM
    follow\useOEM = opt\useOEM
    follow\firstRead = #True
    follow\lastSize = -1
    follow\lastStamp = -1
    follow\offset = FileSize(follow\fileName)
    If follow\offset < 0
      follow\offset = WinFileSize(follow\fileName)
    EndIf
    If follow\offset < 0 : follow\offset = 0 : EndIf

    If gLogEnabled
      LogLine("followStart offset=" + Str(follow\offset))
    EndIf

    Protected ms.i = Int(opt\sleepInterval * 1000.0)
    If ms < 50 : ms = 50 : EndIf
    AddWindowTimer(0, 1, ms)
    DisableGadget(#gRun, #True)
    DisableGadget(#gStop, #False)
    SetStatus("Following: " + follow\fileName)
  EndIf
EndProcedure

Procedure StopFollow()
  follow\active = #False
  RemoveWindowTimer(0, 1)
  DisableGadget(#gRun, #False)
  DisableGadget(#gStop, #True)
  SetStatus("Stopped")

  If gLogEnabled
    LogLine("--- Stop ---")
  EndIf
  LogClose()
  CapClose()
  gLogSessionActive = #False
EndProcedure

Procedure FollowTick()
  If follow\active = #False : ProcedureReturn : EndIf

  Protected fileName.s = follow\fileName
  Protected curSize.q = AnyFileSize(fileName)
  Protected curStamp.q = GetFileDate(fileName, #PB_Date_Modified)

  If curSize < 0
    If follow\followByName
      follow\lastSize = -1
      follow\lastStamp = -1
      follow\offset = 0
      follow\firstRead = #True
      ProcedureReturn
    Else
      ProcedureReturn
    EndIf
  EndIf

  If follow\followByName
    If follow\lastStamp <> -1 And curStamp <> follow\lastStamp
      follow\offset = 0
      follow\firstRead = #True
    ElseIf follow\lastSize <> -1 And curSize < follow\offset
      follow\offset = 0
      follow\firstRead = #True
    EndIf
    follow\lastSize = curSize
    follow\lastStamp = curStamp
  Else
    If curSize < follow\offset
      follow\offset = 0
      follow\firstRead = #True
    EndIf
  EndIf

  If curSize > follow\offset
    Protected newOffset.q = AppendFromOffsetToOutputWinAPI(fileName, follow\offset, follow\encMode, follow\stripBOM, follow\firstRead, follow\useOEM)
    If newOffset < 0
      newOffset = AppendFromOffsetToOutput(fileName, follow\offset, follow\encMode, follow\stripBOM, follow\firstRead, follow\useOEM)
    EndIf
    If newOffset >= 0
      If gLogEnabled
        If gLastReadPath = "winapi"
          LogLine("tick path=winapi bytes=" + Str(newOffset - follow\offset) + " offset=" + Str(newOffset) + " size=" + Str(gWinLastSize) + " diskSize=" + Str(curSize))
        ElseIf gLastReadPath = "pb"
          LogLine("tick path=pb bytes=" + Str(newOffset - follow\offset) + " offset=" + Str(newOffset) + " size=" + Str(gPBLastSize) + " diskSize=" + Str(curSize))
        Else
          LogLine("tick path=? bytes=" + Str(newOffset - follow\offset) + " offset=" + Str(newOffset) + " diskSize=" + Str(curSize))
        EndIf
      EndIf
      follow\offset = newOffset
      follow\firstRead = #False
      SetStatus("Following: " + follow\fileName)
    Else
      If gLogEnabled
        LogLine("tick locked offset=" + Str(follow\offset) + " diskSize=" + Str(curSize) + " winerr=" + Str(gWinLastError))
      EndIf
      If gWinLastError <> 0
        SetStatus("Following (locked, retrying, winerr=" + Str(gWinLastError) + "): " + follow\fileName)
      Else
        SetStatus("Following (locked, retrying): " + follow\fileName)
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure AddFilesFromRequester()
  Protected f.s = OpenFileRequester("Choose a file", "", "Log files|*.log;*.txt|All files|*.*", 0)
  If f = "" : ProcedureReturn : EndIf
  AddGadgetItem(#gFiles, -1, NormalizePath(f))
EndProcedure

Procedure AddFromPattern()
  Protected p.s = Trim(GetGadgetText(#gPattern))
  If p = "" : ProcedureReturn : EndIf

  Protected opt.Options
  opt\fileCount = 0
  AddInputArg(@opt, p)
  Protected i.i
  For i = 0 To opt\fileCount - 1
    AddGadgetItem(#gFiles, -1, opt\files[i])
  Next
EndProcedure

Procedure UpdateSourceUI()
  Protected usingPaste.i = Bool(GetGadgetState(#gSourcePaste))
  DisableGadget(#gFiles, usingPaste)
  DisableGadget(#gAdd, usingPaste)
  DisableGadget(#gRemove, usingPaste)
  DisableGadget(#gClear, usingPaste)
  DisableGadget(#gPattern, usingPaste)
  DisableGadget(#gAddPattern, usingPaste)
  DisableGadget(#gPaste, Bool(GetGadgetState(#gSourceFiles)))
EndProcedure

Procedure BrowseDebugLogPath()
  Protected p.s = SaveFileRequester("Save debug log", gLogPath, "Log (*.log)|*.log|Text (*.txt)|*.txt|All files|*.*", 0)
  If p = "" : ProcedureReturn : EndIf
  SetGadgetText(#gDebugLogPath, p)
EndProcedure

Procedure BrowseCapturePath()
  Protected p.s = SaveFileRequester("Save captured output", gCapPath, "Text (*.txt)|*.txt|Log (*.log)|*.log|All files|*.*", 0)
  If p = "" : ProcedureReturn : EndIf
  SetGadgetText(#gCapturePath, p)
EndProcedure

If OpenWindow(0, 0, 0, 1020, 695, #APP_NAME + " " + version, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget |
                                                             #PB_Window_ScreenCentered)
  ; Left: file inputs
  ListIconGadget(#gFiles, 12, 12, 500, 170, "Input files", 460, #PB_ListIcon_FullRowSelect)
  ButtonGadget(#gAdd, 520, 12, 120, 26, "Add file...")
  ButtonGadget(#gRemove, 520, 44, 120, 26, "Remove")
  ButtonGadget(#gClear, 520, 76, 120, 26, "Clear")
  ButtonGadget(#gHelp, 520, 108, 120, 26, "Help")
  StringGadget(#gPattern, 12, 188, 420, 24, "")
  ButtonGadget(#gAddPattern, 440, 188, 120, 24, "Add pattern")

  ; Source
  FrameGadget(#PB_Any, 12, 222, 628, 70, "Input source")
  OptionGadget(#gSourceFiles, 24, 246, 140, 20, "Files")
  OptionGadget(#gSourcePaste, 180, 246, 200, 20, "Paste text")
  SetGadgetState(#gSourceFiles, 1)

  EditorGadget(#gPaste, 12, 300, 628, 120)
  SetGadgetText(#gPaste, "")

  ; Options
  FrameGadget(#PB_Any, 660, 12, 348, 408, "Options")
  OptionGadget(#gModeLines, 672, 40, 120, 20, "Last lines")
  OptionGadget(#gModeBytes, 672, 66, 120, 20, "Last bytes")
  SetGadgetState(#gModeLines, 1)
  StringGadget(#gLines, 804, 38, 80, 22, Str(#DEFAULT_LINES))
  StringGadget(#gBytes, 804, 64, 120, 22, "1024")

  TextGadget(#PB_Any, 672, 98, 120, 18, "Encoding")
  ComboBoxGadget(#gEnc, 804, 96, 120, 22)
  AddGadgetItem(#gEnc, -1, "auto")
  AddGadgetItem(#gEnc, -1, "utf8")
  AddGadgetItem(#gEnc, -1, "ansi")
  SetGadgetState(#gEnc, 1)

  CheckBoxGadget(#gStripBOM, 672, 130, 260, 20, "Strip UTF-8 BOM")
  SetGadgetState(#gStripBOM, #True)
  CheckBoxGadget(#gUseOEM, 672, 154, 260, 20, "OEM output (cmd.exe)")
  DisableGadget(#gUseOEM, #True)

  CheckBoxGadget(#gVerbose, 672, 186, 150, 20, "Verbose headers")
  CheckBoxGadget(#gQuiet, 832, 186, 150, 20, "Quiet headers")

  CheckBoxGadget(#gFollow, 672, 218, 120, 20, "Follow (-f)")
  SetGadgetState(#gFollow, #True)
  CheckBoxGadget(#gFollowByName, 804, 218, 150, 20, "Follow by name (-F)")
  TextGadget(#PB_Any, 672, 248, 120, 18, "Sleep (sec)")
  StringGadget(#gSleep, 804, 246, 120, 22, "0.2")

  CheckBoxGadget(#gDebugLog, 672, 270, 120, 20, "Debug log")
  StringGadget(#gDebugLogPath, 804, 268, 160, 22, "")
  ButtonGadget(#gDebugLogBrowse, 968, 268, 28, 22, "...")

  CheckBoxGadget(#gCaptureText, 672, 292, 120, 20, "Capture")
  StringGadget(#gCapturePath, 804, 290, 160, 22, "")
  ButtonGadget(#gCaptureBrowse, 968, 290, 28, 22, "...")

  ButtonGadget(#gRun, 672, 316, 120, 28, "Run")
  ButtonGadget(#gStop, 804, 316, 120, 28, "Stop")
  DisableGadget(#gStop, #True)

  ; Output
  FrameGadget(#PB_Any, 12, 432, 996, 250, "Output")
  ListViewGadget(#gOutput, 24, 456, 972, 214)

  TextGadget(#gStatus, 12, 690, 996, 18, "")

  UpdateSourceUI()

  Repeat
    Define ev.i = WaitWindowEvent()
    Define gad.i = EventGadget()

    Select ev
      Case #PB_Event_CloseWindow
        StopFollow()
        Exit()

      Case #PB_Event_Timer
        If EventTimer() = 1
          FollowTick()
        EndIf

      Case #PB_Event_Gadget
        Select gad
          Case #gAdd
            AddFilesFromRequester()

          Case #gAddPattern
            AddFromPattern()

          Case #gDebugLogBrowse
            BrowseDebugLogPath()

          Case #gCaptureBrowse
            BrowseCapturePath()

          Case #gRemove
            Define sel.i = GetGadgetState(#gFiles)
            If sel >= 0
              RemoveGadgetItem(#gFiles, sel)
            EndIf

          Case #gClear
            ClearGadgetItems(#gFiles)

          Case #gHelp
            OpenHelpFile()

          Case #gSourceFiles, #gSourcePaste
            UpdateSourceUI()

          Case #gVerbose
            If GetGadgetState(#gVerbose)
              SetGadgetState(#gQuiet, 0)
            EndIf

          Case #gQuiet
            If GetGadgetState(#gQuiet)
              SetGadgetState(#gVerbose, 0)
            EndIf

          Case #gFollow
            If GetGadgetState(#gFollow) = 0
              SetGadgetState(#gFollowByName, 0)
            EndIf

          Case #gFollowByName
            If GetGadgetState(#gFollowByName)
              SetGadgetState(#gFollow, 1)
            EndIf

          Case #gRun
            StopFollow()
            RunTail()

          Case #gStop
            StopFollow()
        EndSelect

      Case #PB_Event_SizeWindow
        Define w.i = WindowWidth(0)
        Define h.i = WindowHeight(0)

        ; Layout notes:
        ; - Keep a fixed-width options panel on the right (348px + margins)
        ; - Resize the left panel to fill remaining space
        Define margin.i = 12
        Define gap.i = 12
        Define rightW.i = 348
        Define btnW.i = 120
        Define innerGap.i = 8

        Define leftX.i = margin
        Define rightReserved.i = margin + rightW + margin
        Define leftW.i = w - leftX - gap - rightReserved
        If leftW < 360 : leftW = 360 : EndIf

        Define listW.i = leftW - btnW - innerGap
        If listW < 200 : listW = 200 : EndIf
        Define btnX.i = leftX + listW + innerGap

        ResizeGadget(#gFiles, leftX, 12, listW, 170)
        ResizeGadget(#gAdd, btnX, 12, btnW, 26)
        ResizeGadget(#gRemove, btnX, 44, btnW, 26)
        ResizeGadget(#gClear, btnX, 76, btnW, 26)
        ResizeGadget(#gHelp, btnX, 108, btnW, 26)

        Define patW.i = leftW - btnW - innerGap
        If patW < 200 : patW = 200 : EndIf
        ResizeGadget(#gPattern, leftX, 188, patW, 24)
        ResizeGadget(#gAddPattern, leftX + patW + innerGap, 188, btnW, 24)

        ResizeGadget(#gPaste, leftX, 300, leftW, 120)

        ResizeGadget(#gOutput, 24, 456, w - 48, h - 456 - 50)
        ResizeGadget(#gStatus, 12, h - 28, w - 24, 18)
    EndSelect
  ForEver
EndIf

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 4
; Folding = ---------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_Tails_GUI.ico
; Executable = ..\PB_Tails_GUI.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = pb_tails
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = view the last few lines of a log file
; VersionField7 = pb_tails
; VersionField8 = pb_tails.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60