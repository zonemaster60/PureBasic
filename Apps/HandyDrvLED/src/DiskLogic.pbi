; HandyDrvLED Disk Logic (Threaded)

Procedure.s FormatPdhError(status.l)
  Protected buf.s
  If status = 0 : ProcedureReturn "SUCCESS" : EndIf
  If PdhFormatErrorW
    buf = Space(512)
    If PdhFormatErrorW(status, @buf, 512) = 0
      buf = Trim(buf)
      If buf <> "" : ProcedureReturn buf + " (0x" + Hex(status & $FFFFFFFF) + ")" : EndIf
    EndIf
  EndIf
  ProcedureReturn "0x" + Hex(status & $FFFFFFFF)
EndProcedure

Procedure.s FormatRate(bytesPerSec.d)
  Protected value.d = bytesPerSec
  Protected unit.s = "B/s"
  If value >= 10240
    value / 1024.0 : unit = "KB/s"
    If value >= 10240
      value / 1024.0 : unit = "MB/s"
      If value >= 10240
        value / 1024.0 : unit = "GB/s"
      EndIf
    EndIf
  EndIf
  If unit = "B/s" : ProcedureReturn StrD(value, 0) + " " + unit : Else : ProcedureReturn StrD(value, 1) + " " + unit : EndIf
EndProcedure

Procedure EnsurePdhInitialized()
  Protected status.l = -1
  Protected source.s = ""

  LockMutex(Mutex_DiskData)
  If UsePdh : UnlockMutex(Mutex_DiskData) : ProcedureReturn #True : EndIf
  PdhInitStage = "Opening library"
  
  PdhLib = OpenLibrary(#PB_Any, "pdh.dll")
  If PdhLib
    PdhOpenQueryW = GetFunction(PdhLib, "PdhOpenQueryW")
    PdhAddCounterW = GetFunction(PdhLib, "PdhAddCounterW")
    PdhAddEnglishCounterW = GetFunction(PdhLib, "PdhAddEnglishCounterW")
    PdhCollectQueryData = GetFunction(PdhLib, "PdhCollectQueryData")
    PdhGetFormattedCounterValue = GetFunction(PdhLib, "PdhGetFormattedCounterValue")
    PdhCloseQuery = GetFunction(PdhLib, "PdhCloseQuery")
    PdhFormatErrorW = GetFunction(PdhLib, "PdhFormatErrorW")
    
    If PdhOpenQueryW And PdhCollectQueryData And PdhGetFormattedCounterValue And PdhCloseQuery
      PdhInitStage = "Opening query"
      status = PdhOpenQueryW(0, 0, @PdhQuery)
      If status = 0
        If PdhAddEnglishCounterW
          PdhInitStage = "Adding physical counters"
          status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
          If status = 0
            status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
            If status = 0 : source = "PhysicalDisk(_Total)" : EndIf
          EndIf
          If status <> 0
            PdhInitStage = "Adding logical counters"
            status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
            If status = 0
              status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
              If status = 0 : source = "LogicalDisk(_Total)" : EndIf
            EndIf
          EndIf
        EndIf
        If status = 0
          PdhInitStage = "Priming query"
          status = PdhCollectQueryData(PdhQuery)
          If status = 0
            UsePdh = #True
            PdhCounterSource = source
            PdhInitStatus = status
            PdhInitStage = "Ready"
          EndIf
        EndIf
      EndIf
    Else
      PdhInitStage = "Missing PDH exports"
    EndIf
  Else
    PdhInitStage = "Unable to load pdh.dll"
  EndIf

  If Not UsePdh
    PdhInitStatus = status
    If PdhCounterSource = "" : PdhCounterSource = source : EndIf
  EndIf
  UnlockMutex(Mutex_DiskData)

  If UsePdh
    LogLine("PDH fallback initialized using " + PdhCounterSource, "PDH init ok")
  Else
    LogLine("PDH initialization failed at " + PdhInitStage + ": " + FormatPdhError(status), "PDH init fail")
  EndIf

  ProcedureReturn UsePdh
EndProcedure

Procedure PdhReadWriteActivity(*ReadBytesPerSec, *WriteBytesPerSec)
  Protected status.l
  Protected counterValue.PDH_FMT_COUNTERVALUE_DOUBLE
  
  If Not UsePdh Or PdhQuery = 0 : ProcedureReturn #False : EndIf
  
  status = PdhCollectQueryData(PdhQuery)
  PdhLastCollectStatus = status
  If status <> 0
    LogLine("PDH collect failed: " + FormatPdhError(status), "PDH collect fail")
    ProcedureReturn #False
  EndIf
  
  status = PdhGetFormattedCounterValue(PdhReadCounter, #PDH_FMT_DOUBLE, 0, @counterValue)
  PdhLastReadStatus = status
  If status = 0
    PokeD(*ReadBytesPerSec, counterValue\DoubleValue)
  Else
    LogLine("PDH read counter failed: " + FormatPdhError(status), "PDH read fail")
  EndIf
  
  status = PdhGetFormattedCounterValue(PdhWriteCounter, #PDH_FMT_DOUBLE, 0, @counterValue)
  PdhLastWriteStatus = status
  If status = 0
    PokeD(*WriteBytesPerSec, counterValue\DoubleValue)
  Else
    LogLine("PDH write counter failed: " + FormatPdhError(status), "PDH write fail")
  EndIf
  
  ProcedureReturn #True
EndProcedure

Procedure MonitorThread(unused.i)
  Protected dp.DISK_PERFORMANCE
  Protected OldReadCount.l, OldWriteCount.l, OldBytesRead.q, OldBytesWritten.q
  Protected Count_Read.l, Count_Write.l
  Protected lBytesReturned.l
  Protected ReadDetected.i, WriteDetected.i
  Protected readBps.d, writeBps.d
  Protected HoldReadUntil.q, HoldWriteUntil.q
  Protected IoctlBackoff.i
  Protected NextPdhSample.q = 0
  
  Repeat
    If QuitThread : Break : EndIf
    
    Protected Result.i = 0
    LockMutex(Mutex_DiskData)
    If Not (ForcePdhOnly Or DisableIoctlSession) And IoctlBackoff = 0
      Result = DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)
      If Not Result
        LastIoctlError = GetLastError_()
        If IoctlBackoffCycles > 0 : IoctlBackoff = IoctlBackoffCycles : EndIf
      Else
        LastIoctlError = 0
      EndIf
    EndIf
    UnlockMutex(Mutex_DiskData)
    
    If Result
      ReadDetected = Bool(dp\ReadCount <> OldReadCount Or dp\BytesRead <> OldBytesRead)
      WriteDetected = Bool(dp\WriteCount <> OldWriteCount Or dp\BytesWritten <> OldBytesWritten)
      OldReadCount = dp\ReadCount : OldWriteCount = dp\WriteCount
      OldBytesRead = dp\BytesRead : OldBytesWritten = dp\BytesWritten
      
      LockMutex(Mutex_DiskData)
      ; RED=Write, GREEN=Read, BLUE=Both, YELLOW=Idle
      ; IdIcon1=Write (RED), IdIcon2=Read (GREEN), IdIcon3=Both (BLUE), IdIcon4=Idle (YELLOW)
      If ReadDetected And WriteDetected : CurrentIconID = IdIcon3 : ElseIf WriteDetected : CurrentIconID = IdIcon1 : ElseIf ReadDetected : CurrentIconID = IdIcon2 : Else : CurrentIconID = IdIcon4 : EndIf
      CurrentTooltip = "RC/s: " + Str((dp\ReadCount - Count_Read)*10) + " | WC/s: " + Str((dp\WriteCount - Count_Write)*10)
      DisableIoctlSession = #False
      Count_Read = dp\ReadCount : Count_Write = dp\WriteCount
      UnlockMutex(Mutex_DiskData)
      PostEvent(#Event_UpdateTrayIcon)
    Else
      If IoctlBackoff > 0
        IoctlBackoff - 1
      ElseIf Not ForcePdhOnly And Not DisableIoctlSession
        LogLine("IOCTL_DISK_PERFORMANCE failed with Win32 error " + Str(LastIoctlError) + "; switching to PDH fallback", "IOCTL fail")
        LockMutex(Mutex_DiskData)
        DisableIoctlSession = #True
        UnlockMutex(Mutex_DiskData)
      EndIf

      ; Fallback to PDH
      If Not UsePdh : EnsurePdhInitialized() : EndIf
      
      If UsePdh
        If ElapsedMilliseconds() >= NextPdhSample
          NextPdhSample = ElapsedMilliseconds() + PdhSampleIntervalMs
          If PdhReadWriteActivity(@readBps, @writeBps)
            If readBps >= ActivityThresholdBps : HoldReadUntil = ElapsedMilliseconds() + ActivityHoldMs : EndIf
            If writeBps >= ActivityThresholdBps : HoldWriteUntil = ElapsedMilliseconds() + ActivityHoldMs : EndIf
            
            ReadDetected  = Bool(ElapsedMilliseconds() < HoldReadUntil)
            WriteDetected = Bool(ElapsedMilliseconds() < HoldWriteUntil)
            
            LockMutex(Mutex_DiskData)
            If ReadDetected And WriteDetected : CurrentIconID = IdIcon3 : ElseIf WriteDetected : CurrentIconID = IdIcon1 : ElseIf ReadDetected : CurrentIconID = IdIcon2 : Else : CurrentIconID = IdIcon4 : EndIf
            CurrentTooltip = "Read: " + FormatRate(readBps) + " | Write: " + FormatRate(writeBps)
            UnlockMutex(Mutex_DiskData)
            PostEvent(#Event_UpdateTrayIcon)
          EndIf
        EndIf
      Else
        LockMutex(Mutex_DiskData)
        CurrentIconID = IdIcon4
        CurrentTooltip = "Monitoring Idle (Error)"
        UnlockMutex(Mutex_DiskData)
        PostEvent(#Event_UpdateTrayIcon)
      EndIf
    EndIf
    
    Delay(UpdateIntervalMs)
  ForEver
EndProcedure
