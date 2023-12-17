;Disk Performance, Windows Only
;coded by S.Rings, june 2010
;needs admin rights

#IOCTL_DISK_PERFORMANCE = $70020

Structure DISK_PERFORMANCE   
    BytesRead.q   ;The number of bytes Read.
    BytesWritten.q        ; The number of bytes written.
    ReadTime.q            ; The time it takes to complete a read.
    WriteTime.q           ; The time it takes to complete a write.
    IdleTime.q            ; The idle time.
    ReadCount.l           ; The number of read operations.
    WriteCount.l         ; The number of write operations.
    QueueDepth.l          ; The depth of the queue.
   
    SplitCount.l          ; The cumulative count of I/Os that are associated I/Os.
                          ; An associated I/O is a fragmented I/O, where multiple I/Os
                          ; to a disk are required to fulfill the original logical I/O request.
                          ; The most common example of this scenario is a file that is fragmented
                          ; on a disk. The multiple I/Os are counted ;split I/O counts.
                         
    QueryTime.q           ; The system time stamp when a query for this structure is returned.
                          ; Use this member to synchronize between the file system driver and a caller.
    StorageDeviceNumber.l ; The unique number for a device that identifies it to the storage manager
                           ; that is indicated in the StorageManagerName member.
    StorageManagerName.q  ;String * 8  The name of the storage manager that controls this device.
                                      ; Examples of storage managers are "PhysDisk," "FTDISK," and "DMIO".
    ReadCount2.l          ;Long ' \
    WriteCount2.l         ;Long ' | Non documentés correctement. Sur MSDN, ces trois valeurs manquent
    QueueDepth2.l         ;Long ' /
EndStructure

Procedure GetDrivePerformence(Drive.s, *Result.DISK_PERFORMANCE)
 
 hDrive = CreateFile_(Drive, #GENERIC_READ | #GENERIC_WRITE, #FILE_SHARE_READ | #FILE_SHARE_WRITE, 0, #OPEN_EXISTING, 0,  0)
 If hDrive <> #INVALID_HANDLE_VALUE
   Ret = DeviceIoControl_(hDrive, #IOCTL_DISK_PERFORMANCE, 0, 0, *Result, 88, @DummyReturnedBytes, 0)
   
   CloseHandle_(hDrive)
   ProcedureReturn ret
   
 Else
   Debug "cannot open device= " + drive
   ProcedureReturn -1
 EndIf
EndProcedure

;list some available drives
Mem = AllocateMemory(256 * SizeOf(Character))
res = GetLogicalDriveStrings_(256 * SizeOf(Character), mem)
For I=0 To 255
  If PeekC(mem + (i * SizeOf(Character))) = 0
    PokeC(mem + (i * SizeOf(Character)), 32)
  EndIf
Next 
Debug PeekS(mem, res)

Drive.s="\\.\Physicaldrive0";Hardisk 0
Drive.s="\\.\IO" ; ???
Drive.s="\\.\Ndis" ;Network ?
Drive.s="\\.\c:"

;scan 10 seconds your drive performance
For I=1 To 10
 res=GetDrivePerformence(Drive.s,P1.DISK_PERFORMANCE)
 If res<1 :   End: EndIf 
 Delay(1000);wait 1 second
 GetDrivePerformence(Drive.s,P2.DISK_PERFORMANCE)
 
 QueryTime.q= p2\QueryTime - p1\QueryTime
 BytesRead.q = p2\BytesRead - p1\BytesRead
 ReadCount.q = p2\ReadCount - p1\ReadCount
 Byteswritten.q = p2\BytesWritten - p1\BytesWritten
 WriteCount.q = p2\WriteCount - p1\WriteCount

 Idletime.q = p2\IdleTime - p1\IdleTime
 dQueryTime.d=QueryTime/(10000000)
 Activity.d=(QueryTime - Idletime)/ QueryTime *100
 ;Storage.q=p2\StorageManagerName
 Debug "Reading  =" + StrU(BytesRead,#PB_Quad)  + ":" + StrU(ReadCount,#PB_Quad)   
 Debug "Writing  =" + StrU(BytesWritten,#PB_Quad)  + ":" + StrU(WriteCount,#PB_Quad)   
 Debug "Activity =" + StrD(Activity,3) + "%"
Next
; IDE Options = PureBasic 6.03 beta 9 LTS (Windows - x64)
; CursorPosition = 56
; FirstLine = 6
; Folding = -
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware