EnableExplicit

#DEFAULT_LINES = 10
#CHUNK_SIZE    = 8192
#APP_NAME = "PB_Tails_GUI"

Global version.s ="v1.0.0.2"
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

Structure ReadContext
  useWinAPI.i
  file.i
  handle.i
  size.q
EndStructure

Structure DecodeState
  carryLen.i
  carry.a[4]
  stripPending.i
EndStructure

Structure IntResult
  value.i
EndStructure

Structure QuadResult
  value.q
EndStructure

Structure FloatResult
  value.f
EndStructure

Structure TailValidation
  ok.i
  status.s
EndStructure

Import "kernel32.lib"
  WinGetFullPathName(lpFileName, nBufferLength, lpBuffer, *lpFilePart) As "GetFullPathNameW"
EndImport

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
Global follow.FollowState
Global gLogEnabled.i
Global gLogPath.s
Global gLogFile.i = 0
Global gCapEnabled.i
Global gCapPath.s
Global gCapFile.i = 0
Global gWinLastSize.q
Global gPBLastSize.q
Global gLastReadPath.s

Procedure.s NormalizePath(p.s)
  ; Normalize relative paths and remove any ".\\" / "..\\" segments.
  Protected out.s = Space(#MAX_PATH)
  Protected r.i

  If p = "" : ProcedureReturn "" : EndIf

  r = WinGetFullPathName(p, #MAX_PATH, @out, 0)
  If r <= 0
    ProcedureReturn p
  EndIf
  If r > #MAX_PATH
    out = Space(r + 1)
    r = WinGetFullPathName(p, r + 1, @out, 0)
    If r <= 0
      ProcedureReturn p
    EndIf
  EndIf

  ProcedureReturn Left(out, r)
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
  
  FreeList(matches())
EndProcedure

XIncludeFile "PB_Tails_Engine.pbi"

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

#SW_SHOWNORMAL = 1

Procedure OpenHelpFile()
  Protected helpPath.s = AppPath + "files\" + #APP_NAME + "_Help.html"
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

Declare.s NormalizeLF(text.s)
Declare.s TailTextByLines(text.s, lineCount.i)
Declare.s TailTextByBytes(text.s, byteCount.q, encMode.i, stripBOM.i)

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
  Protected s.s = NormalizeLF(text)
  s = ReplaceString(s, Chr(10), Chr(13) + Chr(10))
  WriteString(gCapFile, s, #PB_UTF8)
EndProcedure

Procedure.s NormalizeLF(text.s)
  Protected s.s = ReplaceString(text, Chr(13) + Chr(10), Chr(10))
  ProcedureReturn ReplaceString(s, Chr(13), Chr(10))
EndProcedure

Procedure.s TailTextByLines(text.s, lineCount.i)
  Protected s.s = NormalizeLF(text)
  Protected scanEnd.i
  Protected pos.i
  Protected foundLines.i = 1
  Protected startPos.i = 1

  If lineCount <= 0 Or s = ""
    ProcedureReturn ""
  EndIf

  scanEnd = Len(s)
  If scanEnd > 0 And Right(s, 1) = Chr(10)
    scanEnd - 1
  EndIf

  If scanEnd <= 0
    ProcedureReturn s
  EndIf

  For pos = scanEnd To 1 Step -1
    If Mid(s, pos, 1) = Chr(10)
      foundLines + 1
      If foundLines > lineCount
        startPos = pos + 1
        Break
      EndIf
    EndIf
  Next

  ProcedureReturn Mid(s, startPos)
EndProcedure

Procedure.s TailTextByBytes(text.s, byteCount.q, encMode.i, stripBOM.i)
  Protected format.i
  Protected totalBytes.i
  Protected startOffset.i
  Protected *buf
  Protected out.s = ""

  If byteCount <= 0 Or text = ""
    ProcedureReturn ""
  EndIf

  Select encMode
    Case #ENC_ANSI
      format = #PB_Ascii
    Default
      format = #PB_UTF8
  EndSelect

  totalBytes = StringByteLength(text, format)
  If totalBytes <= 0
    ProcedureReturn ""
  EndIf

  If byteCount >= totalBytes
    out = text
  Else
    *buf = AllocateMemory(totalBytes)
    If *buf = 0
      ProcedureReturn ""
    EndIf

    PokeS(*buf, text, -1, format)
    startOffset = totalBytes - byteCount
    out = TailEngine_DecodeBytes(*buf + startOffset, byteCount, encMode)
    FreeMemory(*buf)
  EndIf

  If stripBOM And byteCount >= totalBytes
    out = TailEngine_StripUTF8BOM(out)
  EndIf

  ProcedureReturn out
EndProcedure

Procedure.i ShouldResetFollowByName(lastSize.q, curSize.q, offset.q)
  If curSize < offset
    ProcedureReturn #True
  EndIf
  If lastSize <> -1 And curSize < lastSize
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure AppendTextToEditor(gadget.i, text.s)
  Protected s.s = NormalizeLF(text)
  If s = "" : ProcedureReturn : EndIf

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

  Protected textLen.i = Len(s)
  Protected startPos.i = 1
  Protected i.i

  For i = 1 To textLen
    If Mid(s, i, 1) = Chr(10)
      AddGadgetItem(gadget, -1, Mid(s, startPos, i - startPos))
      startPos = i + 1
    EndIf
  Next

  If startPos <= textLen
    AddGadgetItem(gadget, -1, Mid(s, startPos))
  EndIf

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

Procedure.i TryParseNonNegativeInt(text.s, *result.IntResult)
  Protected s.s = Trim(text)
  Protected i.i

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    If FindString("0123456789", Mid(s, i, 1)) = 0
      ProcedureReturn #False
    EndIf
  Next

  *result\value = Val(s)
  ProcedureReturn #True
EndProcedure

Procedure.i TryParseByteCount(text.s, *result.QuadResult)
  Protected s.s = LCase(Trim(text))
  Protected lastChar.s
  Protected numPart.s
  Protected parsed.IntResult

  If s = ""
    ProcedureReturn #False
  EndIf

  lastChar = Right(s, 1)
  Select lastChar
    Case "b", "k", "m"
      numPart = Left(s, Len(s) - 1)
    Default
      numPart = s
      lastChar = ""
  EndSelect

  If TryParseNonNegativeInt(numPart, @parsed) = #False
    ProcedureReturn #False
  EndIf

  *result\value = parsed\value
  Select lastChar
    Case "b"
      *result\value * 512
    Case "k"
      *result\value * 1024
    Case "m"
      *result\value * 1024 * 1024
  EndSelect

  ProcedureReturn #True
EndProcedure

Procedure.i TryParsePositiveFloat(text.s, *result.FloatResult)
  Protected s.s = Trim(text)
  Protected i.i
  Protected dotCount.i = 0

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    Protected ch.s = Mid(s, i, 1)
    If ch = "."
      dotCount + 1
      If dotCount > 1
        ProcedureReturn #False
      EndIf
    ElseIf FindString("0123456789", ch) = 0
      ProcedureReturn #False
    EndIf
  Next

  *result\value = ValF(s)
  If *result\value <= 0.0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i ValidateRunOptions(*opt.Options, *validation.TailValidation)
  Protected parsedInt.IntResult
  Protected parsedBytes.QuadResult
  Protected parsedFloat.FloatResult

  *validation\ok = #False
  *validation\status = ""

  If GetGadgetState(#gModeBytes)
    If TryParseByteCount(GetGadgetText(#gBytes), @parsedBytes) = #False
      *validation\status = "Enter a valid byte count, for example 1024, 4k, or 1m"
      ProcedureReturn #False
    EndIf
    *opt\bytes = parsedBytes\value
    *opt\lines = 0
  Else
    If TryParseNonNegativeInt(GetGadgetText(#gLines), @parsedInt) = #False
      *validation\status = "Enter a valid non-negative line count"
      ProcedureReturn #False
    EndIf
    *opt\lines = parsedInt\value
    *opt\bytes = -1
  EndIf

  If TryParsePositiveFloat(GetGadgetText(#gSleep), @parsedFloat) = #False
    *validation\status = "Enter a valid sleep interval greater than 0"
    ProcedureReturn #False
  EndIf
  *opt\sleepInterval = parsedFloat\value

  *validation\ok = #True
  ProcedureReturn #True
EndProcedure

Procedure.i GetEncModeFromUI()
  Protected sel.i = GetGadgetState(#gEnc)
  Select sel
    Case 1 : ProcedureReturn #ENC_UTF8
    Case 2 : ProcedureReturn #ENC_ANSI
    Default : ProcedureReturn #ENC_AUTO
  EndSelect
EndProcedure

Procedure.q AppendFromOffsetToOutput(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i, useOEM.i)
  Protected size.q = TailEngine_AnyFileSize(FileName)
  Protected chunk.s
  Protected applyStrip.i

  If size < 0
    ProcedureReturn -1
  EndIf
  If StartOffset > size : StartOffset = size : EndIf

  applyStrip = Bool(stripBOM And firstRead And StartOffset = 0)
  chunk = TailEngine_ReadContextDecodeRange(FileName, StartOffset, size - StartOffset, encMode, applyStrip, #False)
  If useOEM
    chunk = TailEngine_ToOEMIfNeeded(chunk, #True)
  EndIf
  AppendTextToEditor(#gOutput, chunk)
  gLastReadPath = "pb"
  gPBLastSize = size
  ProcedureReturn size
EndProcedure

Procedure.q AppendFromOffsetToOutputWinAPI(FileName.s, StartOffset.q, encMode.i, stripBOM.i, firstRead.i, useOEM.i)
  Protected ctx.ReadContext
  Protected chunk.s
  Protected applyStrip.i

  gWinLastError = 0
  gWinLastBytes = 0
  If OpenReadContext(@ctx, FileName, #True) = #False Or ctx\useWinAPI = #False
    gWinLastError = GetLastError_()
    CloseReadContext(@ctx)
    ProcedureReturn -1
  EndIf

  If StartOffset > ctx\size : StartOffset = ctx\size : EndIf
  gWinLastSize = ctx\size
  CloseReadContext(@ctx)

  applyStrip = Bool(stripBOM And firstRead And StartOffset = 0)
  chunk = TailEngine_ReadContextDecodeRange(FileName, StartOffset, gWinLastSize - StartOffset, encMode, applyStrip, #True)
  If useOEM
    chunk = TailEngine_ToOEMIfNeeded(chunk, #True)
  EndIf
  AppendTextToEditor(#gOutput, chunk)
  gLastReadPath = "winapi"
  gWinLastBytes = gWinLastSize - StartOffset
  ProcedureReturn gWinLastSize
EndProcedure

Procedure RunTail()
  Protected opt.Options
  Protected validation.TailValidation
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

  gLastReadPath = ""
  gWinLastSize = 0
  gPBLastSize = 0

  If gLogEnabled
    LogLine("--- Run ---")
    LogLine("logPath=" + gLogPath)
    LogLine("capEnabled=" + Str(gCapEnabled) + " capPath=" + gCapPath)
  EndIf

  If ValidateRunOptions(@opt, @validation) = #False
    SetStatus(validation\status)
    If gLogEnabled
      LogLine("validationError=" + validation\status)
    EndIf
    ProcedureReturn
  EndIf

  opt\encMode = GetEncModeFromUI()
  opt\stripBOM = Bool(GetGadgetState(#gStripBOM))
  opt\useOEM = Bool(GetGadgetState(#gUseOEM))
  opt\verbose = Bool(GetGadgetState(#gVerbose))
  opt\quiet = Bool(GetGadgetState(#gQuiet))
  opt\follow = Bool(GetGadgetState(#gFollow))
  opt\followByName = Bool(GetGadgetState(#gFollowByName))
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
      out = TailTextByBytes(text, opt\bytes, opt\encMode, opt\stripBOM)
    Else
      out = TailTextByLines(text, opt\lines)
    EndIf
    AppendTextToEditor(#gOutput, out)
    SetStatus("Ready")
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
    If TailEngine_CanOpenForReadAny(fileName) = #False
      AppendTextToEditor(#gOutput, "Error: cannot read file: " + fileName + Chr(10))
      SetStatus("Unable to read: " + fileName)
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
      out = TailEngine_ReadLastNBytes(fileName, opt\bytes, opt\encMode, opt\stripBOM)
      If out = "" And opt\bytes > 0 And TailEngine_AnyFileSize(fileName) > 0
        out = TailEngine_ReadLastNBytesWinAPI(fileName, opt\bytes, opt\encMode, opt\stripBOM)
      EndIf
    Else
      out = TailEngine_ReadLastNLines(fileName, opt\lines, opt\encMode, opt\stripBOM)
      If out = "" And opt\lines > 0 And TailEngine_AnyFileSize(fileName) > 0
        out = TailEngine_ReadLastNLinesWinAPI(fileName, opt\lines, opt\encMode, opt\stripBOM)
      EndIf
    EndIf

    If gLogEnabled
      LogLine("tail file=" + fileName + " outChars=" + Str(Len(out)))
    EndIf

    If opt\useOEM
      out = TailEngine_ToOEMIfNeeded(out, #True)
    EndIf
    If out = "" And ((opt\bytes >= 0 And opt\bytes > 0) Or (opt\bytes < 0 And opt\lines > 0))
      If TailEngine_AnyFileSize(fileName) > 0
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
      follow\offset = TailEngine_WinFileSize(follow\fileName)
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
  Else
    SetStatus("Ready")
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
EndProcedure

Procedure FollowTick()
  If follow\active = #False : ProcedureReturn : EndIf

  Protected fileName.s = follow\fileName
  Protected curSize.q = TailEngine_AnyFileSize(fileName)
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
    If ShouldResetFollowByName(follow\lastSize, curSize, follow\offset)
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
  SetStatus("Added file: " + GetFilePart(f))
EndProcedure

Procedure AddFromPattern()
  Protected p.s = Trim(GetGadgetText(#gPattern))
  If p = ""
    SetStatus("Enter a file path or wildcard pattern")
    ProcedureReturn
  EndIf

  Protected opt.Options
  opt\fileCount = 0
  AddInputArg(@opt, p)
  Protected i.i
  Protected added.i = 0
  For i = 0 To opt\fileCount - 1
    AddGadgetItem(#gFiles, -1, opt\files[i])
    added + 1
  Next

  If added > 0
    SetStatus("Added " + Str(added) + " item(s)")
  Else
    SetStatus("No files matched: " + p)
  EndIf
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
  GadgetToolTip(#gFiles, "Double-click a file to open it")
  ButtonGadget(#gAdd, 520, 12, 120, 26, "Add file...")
  ButtonGadget(#gRemove, 520, 44, 120, 26, "Remove")
  ButtonGadget(#gClear, 520, 76, 120, 26, "Clear")
  ButtonGadget(#gHelp, 520, 108, 120, 26, "Help")
  StringGadget(#gPattern, 12, 188, 420, 24, "")
  GadgetToolTip(#gPattern, "Enter wildcards like C:\logs\*.log")
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
  SetGadgetState(#gEnc, 0)

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
          Case #gFiles
            If EventType() = #PB_EventType_LeftDoubleClick
              Define selItem.i = GetGadgetState(#gFiles)
              If selItem >= 0
                ShellExecute_(0, "open", GetGadgetItemText(#gFiles, selItem, 0), 0, 0, #SW_SHOWNORMAL)
              EndIf
            EndIf

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
              SetStatus("Removed selected file")
            EndIf

          Case #gClear
            ClearGadgetItems(#gFiles)
            SetStatus("Cleared file list")

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
; CursorPosition = 238
; FirstLine = 210
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_Tails_GUI.ico
; Executable = ..\PB_Tails_GUI.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = PB_Tails_GUI
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = An app to view the last few lines of a log file
; VersionField7 = PB_Tails_GUI
; VersionField8 = PB_Tails_GUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60