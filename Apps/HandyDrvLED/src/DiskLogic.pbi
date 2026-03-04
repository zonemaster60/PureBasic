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
    if value >= 10240
      value / 1024.0 : unit = "MB/s"
      if value >= 10240
        value / 1024.0 : unit = "GB/s"
      EndIf
    EndIf
  EndIf
  If unit = "B/s" : ProcedureReturn StrD(value, 0) + " " + unit : Else : ProcedureReturn StrD(value, 1) + " " + unit : EndIf
EndProcedure

Procedure EnsurePdhInitialized()
  LockMutex(Mutex_DiskData)
  If UsePdh : UnlockMutex(Mutex_DiskData) : ProcedureReturn #True : EndIf
  
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
      If PdhOpenQueryW(0, 0, @PdhQuery) = 0
        Protected status.l = -1
        If PdhAddEnglishCounterW
          status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
          If status = 0
            status = PdhAddEnglishCounterW(PdhQuery, @"\PhysicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
          EndIf
          If status <> 0
            status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Read Bytes/sec", 0, @PdhReadCounter)
            If status = 0
              status = PdhAddEnglishCounterW(PdhQuery, @"\LogicalDisk(_Total)\Disk Write Bytes/sec", 0, @PdhWriteCounter)
            EndIf
          EndIf
        EndIf
        If status = 0 
          PdhCollectQueryData(PdhQuery) ; Prime
          UsePdh = #True 
        EndIf
      EndIf
    EndIf
  EndIf
  UnlockMutex(Mutex_DiskData)
  ProcedureReturn UsePdh
EndProcedure

Procedure PdhReadWriteActivity(*ReadBytesPerSec, *WriteBytesPerSec)
  Protected status.l
  Protected counterValue.PDH_FMT_COUNTERVALUE_DOUBLE
  
  If Not UsePdh Or PdhQuery = 0 : ProcedureReturn #False : EndIf
  
  status = PdhCollectQueryData(PdhQuery)
  If status <> 0 : ProcedureReturn #False : EndIf
  
  If PdhGetFormattedCounterValue(PdhReadCounter, #PDH_FMT_DOUBLE, 0, @counterValue) = 0
    PokeD(*ReadBytesPerSec, counterValue\DoubleValue)
  EndIf
  
  If PdhGetFormattedCounterValue(PdhWriteCounter, #PDH_FMT_DOUBLE, 0, @counterValue) = 0
    PokeD(*WriteBytesPerSec, counterValue\DoubleValue)
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
      If Not Result : LastIoctlError = GetLastError_() : EndIf
    EndIf
    UnlockMutex(Mutex_DiskData)
    
    If Result
      ReadDetected = Bool(dp\ReadCount <> OldReadCount Or dp\BytesRead <> OldBytesRead)
      WriteDetected = Bool(dp\WriteCount <> OldWriteCount Or dp\BytesWritten <> OldBytesWritten)
      OldReadCount = dp\ReadCount : OldWriteCount = dp\WriteCount
      OldBytesRead = dp\BytesRead : OldBytesWritten = dp\BytesWritten
      
      LockMutex(Mutex_DiskData)
      If ReadDetected And WriteDetected : CurrentIconID = IdIcon3 : ElseIf WriteDetected : CurrentIconID = IdIcon1 : ElseIf ReadDetected : CurrentIconID = IdIcon2 : Else : CurrentIconID = IdIcon4 : EndIf
      CurrentTooltip = "RC/s: " + Str((dp\ReadCount - Count_Read)*10) + " | WC/s: " + Str((dp\WriteCount - Count_Write)*10)
      Count_Read = dp\ReadCount : Count_Write = dp\WriteCount
      UnlockMutex(Mutex_DiskData)
      PostEvent(#Event_UpdateTrayIcon)
    Else
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
