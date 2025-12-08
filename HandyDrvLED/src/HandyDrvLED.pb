; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.21
; Improved version with bug fixes and optimizations

#IOCTL_DISK_PERFORMANCE = $70020

; Constants for better readability
#ICON_WRITE = 1
#ICON_READ = 2  
#ICON_SYSTEM = 3
#ICON_IDLE = 4
#UPDATE_INTERVAL = 100
#TOOLTIP_UPDATE_INTERVAL = 2500

Structure DISK_PERFORMANCE
  BytesRead.q
  BytesWritten.q
  ReadTime.q
  WriteTime.q
  IdleTime.q
  ReadCount.l
  WriteCount.l
  QueueDepth.l
  SplitCount.l
  QueryTime.l
  StorageDeviceNumber.l
  StorageManagerName.l[8]
EndStructure

Global Dim HDAvailableSpace.q(0)
Global Dim HDCapacity.q(0)
Global Dim HDFreeSpace.q(0)
Global hdh, IdIcon1, IdIcon2, IdIcon3, IdIcon4

Procedure GetDiskFreeSpace(drive$)
  SetErrorMode_(#SEM_FAILCRITICALERRORS)
  GetDiskFreeSpaceEx_(@drive$, HDAvailableSpace(), HDCapacity(), HDFreeSpace())
  SetErrorMode_(0)
EndProcedure

; Improved icon loading with error checking
Procedure LoadIconSet(iconSetNumber.i)
  Protected iconlib.s = "IconLibs\HandyDrvLED." + iconSetNumber + ".icl"
  
  ; Check if icon library exists
  If FileSize(iconlib) = -1
    MessageRequester("Error", "Icon library " + iconlib + " not found!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  
  ; Load icons
  IdIcon1 = ExtractIcon_(0, iconlib, 0)     
  IdIcon2 = ExtractIcon_(0, iconlib, 1)
  IdIcon3 = ExtractIcon_(0, iconlib, 2)
  IdIcon4 = ExtractIcon_(0, iconlib, 3)
  
  ; Verify icons loaded successfully
  If IdIcon1 = 0 Or IdIcon2 = 0 Or IdIcon3 = 0 Or IdIcon4 = 0
    MessageRequester("Error", "Failed to load icons from " + iconlib, #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
EndProcedure

; Count available icon libraries
Procedure CountIconLibraries()
  Protected count.i = 0
  
  If ExamineDirectory(0, "IconLibs\", "*.icl")
    While NextDirectoryEntry(0)
      count + 1
    Wend
    FinishDirectory(0)
  EndIf
  
  If count = 0 : count = 1 : EndIf
  ProcedureReturn count
EndProcedure

; Create physical drive handle
Procedure OpenPhysDrive(CurrentDrive.l)
  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive), 0, 0, 0, #OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

; Cleanup procedure
Procedure Cleanup()
  If hdh And hdh <> #INVALID_HANDLE_VALUE
    CloseHandle_(hdh)
  EndIf
  RemoveSysTrayIcon(1)
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    Cleanup()
    End
  EndIf
EndProcedure

; Help procedure
Procedure Help()
  MessageRequester("Help", "-> You can select 'Explore', 'DriveInfo', or 'IconSet' by " + #CRLF$ +
                           "right-clicking the icon in the system tray and selecting it." + #CRLF$ + #CRLF$+
                           "-> Icon Sets can now be included. A random icon set" + #CRLF$ +
                           "will be loaded each time the program is initialized." + #CRLF$ + #CRLF$ +
                           "Icon Legend:" + #CRLF$ +
                           " RED=Write, GREEN=Read, BLUE=System, YELLOW=Idle", #PB_MessageRequester_Info)
EndProcedure

; Display drive information
Procedure DriveInfo(lpRootPathName.s)
  Protected Info.s
  Protected pVolumeNameBuffer.s = Space(256)
  Protected nVolumeNameSize.l = 256
  Protected lpVolumeSerialNumber.l
  Protected lpMaximumComponentLength.l
  Protected lpFileSystemFlags.l
  Protected lpFileSystemNameBuffer.s = Space(256)
  Protected nFileSystemNameSize.l = 256
  Protected Result.i
  
  Result = GetVolumeInformation_(lpRootPathName, pVolumeNameBuffer, 256, @lpVolumeSerialNumber, @lpMaximumComponentLength, @lpFileSystemFlags, lpFileSystemNameBuffer, 256)

  GetDiskFreeSpace(lpRootPathName)
  Info = Info + "Capacity: " + Str(HDCapacity(0)/1024/1024/1024) + " GB" + Chr(13)
  Info = Info + "Used: " + Str((HDCapacity(0)-HDFreeSpace(0))/1024/1024/1024) + " GB" + Chr(13)
  Info = Info + "Free: " + Str(HDFreeSpace(0)/1024/1024/1024) + " GB" + Chr(13)
  Info = Info + "VolumeName: " + LTrim(pVolumeNameBuffer) + Chr(13)
  Info = Info + "VolumeID: " + Hex(lpVolumeSerialNumber) + Chr(13)
  Info = Info + "FileSystem: " + LTrim(lpFileSystemNameBuffer)

  MessageRequester("DriveInfo For " + lpRootPathName, Info, #PB_MessageRequester_Info)
EndProcedure

; Display about dialog
Procedure About(icon1.i, version.s)
  MessageRequester("About", "Handy Drive LED" + version + #CRLF$ +
                            "Using Custom (IconSet) IS:" + icon1 + #CRLF$ +
                            "Email: zonemaster@yahoo.com", #PB_MessageRequester_Info)
EndProcedure

; Main program starts here
Define drv.i
Define numicl.i = 0
Define mTime.f = #TOOLTIP_UPDATE_INTERVAL ; 2.5 secs
Define version.s = " v0.0.2.3 (20250709)" ; Fixed date format
Define icon1.i
Define dp.DISK_PERFORMANCE
Define Window_Form1.i
Define EventID.i, Result.i, lBytesReturned.l
Define OldReadTime.q, OldWriteTime.q
Define flags.i = #False
Define TimeOut.i, Count_Read.l, Count_Write.l
Define Exit.i = 0
Define Req.i
Define ActivityDetected.i
drv$ = Chr(drv) + ":\"

; Count available icon libraries
numicl = CountIconLibraries()

; Select random icon set
icon1 = Random(numicl, 1)
If icon1 < 1 : icon1 = 1 : EndIf

; Load initial icon set
If Not LoadIconSet(icon1)
  MessageRequester("Error", "Failed to load initial icon set!", #PB_MessageRequester_Error)
  End
EndIf

; Checks if there is a physical disk in the system 
If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
  MessageRequester("Error", "Unable to open drive!", #PB_MessageRequester_Error)
  End
EndIf

; Check for running instance
If FindWindow_(0, "HandyDrvLED")
  MessageRequester("Info", "HandyDrvLED is already running.", #PB_MessageRequester_Info)
  End
EndIf  

; Create main window (invisible)
Window_Form1 = OpenWindow(0, 80, 80, 100, 100, "HandyDrvLED", #PB_Window_Invisible)

; Create the menu pop-up
CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Help")
MenuBar()
MenuItem(3, "Explore")
MenuItem(4, "DriveInfo")
MenuItem(5, "IconSet")
MenuBar()
MenuItem(6, "Exit")

; Add the items to the system tray
AddSysTrayIcon(1, WindowID(0), IdIcon3)
SysTrayIconToolTip(1, "Handy Drive LED" + version)
Delay(mTime/2)

; Main program loop
Repeat
  
  EventID = WaitWindowEvent(10)
  Result = DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)

  ; Improved activity detection - no more duplicate code
  ActivityDetected = #False

  ; Check for read activity
  If dp\ReadTime <> OldReadTime
    OldReadTime = dp\ReadTime
    ActivityDetected = #True
  EndIf

  ; Check for write activity  
  If dp\WriteTime <> OldWriteTime
    OldWriteTime = dp\WriteTime
    ActivityDetected = #True
  EndIf

  ; Update icon based on activity
  If ActivityDetected
    If Not flags
      ChangeSysTrayIcon(1, IdIcon1) ; Activity icon (red for write, green for read)
      flags = #True
    Else
      ChangeSysTrayIcon(1, IdIcon2) ; Alternate activity icon
      flags = #False
    EndIf
  Else
    ChangeSysTrayIcon(1, IdIcon4) ; Idle icon (yellow)
    flags = #False
  EndIf
  
  Delay(#UPDATE_INTERVAL)
  
  ; Update tooltip with statistics
  If ElapsedMilliseconds() > TimeOut
    If TimeOut
      SysTrayIconToolTip(1, "RC: " + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + " MB) | WC: " + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + " MB) | IS:"+icon1)
    EndIf
    Count_Read = dp\ReadCount
    Count_Write = dp\WriteCount
    TimeOut = ElapsedMilliseconds() + mTime
  EndIf
  
  ; Handle system tray events
  If EventID = #PB_Event_SysTray
    Select EventType()
      Case #PB_EventType_RightClick ; Process the right mouse button
        DisplayPopupMenu(0, WindowID(0)) ; Show the popup menu
    EndSelect
  EndIf
  
  ; Handle menu events
  If EventID = #PB_Event_Menu
    Select EventMenu()
      Case 1 ; About
        About(icon1, version)
        
      Case 2 ; Help
        Help()
        
      Case 3 ; Explore - Fixed to properly open C: drive
        For drv = 65 To 90 
        drv$ = Chr(drv) + ":\"
        If GetDriveType_(drv$) = #DRIVE_FIXED
          ShellExecute_(0, "open", drv$, "", "", #SW_SHOWNORMAL)
          Break
        EndIf
        Next
               
      Case 4 ; DriveInfo - Improved to handle all drives properly
        For drv = 65 To 90 
          drv$ = Chr(drv) + ":\"
          If GetDriveType_(drv$) = #DRIVE_FIXED
            DriveInfo(drv$)
            If drv < 90 ; Don't ask after the last drive
              Req = MessageRequester("Next", "Go on to the next drive?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
              If Req = #PB_MessageRequester_No
                Break
              EndIf
            EndIf
          EndIf
        Next
        
      Case 5 ; IconSet - Change to random icon set
        ChangeSysTrayIcon(1, IdIcon3)
        SysTrayIconToolTip(1, "Handy Drive LED" + version)
        Delay(mTime/2)
        
        ; Select new random icon set
        icon1 = Random(numicl, 1)
        If icon1 < 1 : icon1 = 1 : EndIf
        
        ; Load new icon set
        If LoadIconSet(icon1)
          ChangeSysTrayIcon(1, IdIcon3)
          SysTrayIconToolTip(1, "Changing to (IconSet) IS:" + icon1)
          Delay(mTime/2)
        Else
          MessageRequester("Error", "Failed to load icon set " + icon1, #PB_MessageRequester_Error)
        EndIf
        
      Case 6 ; Exit
        Exit()    
    EndSelect
  EndIf
  
  ; Handle window close event
  If EventID = #PB_Event_CloseWindow
    Exit = 1
  EndIf
  
Until Exit = 1

; Cleanup before exit
Cleanup()
; IDE Options = PureBasic 6.30 beta 4 (Windows - x64)
; CursorPosition = 40
; FirstLine = 51
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = HandyDrvLED.ico
; Executable = ..\HandyDrvLED.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 0,0,2,3
; VersionField2 = ZoneSoft
; VersionField3 = HandyDrvLED
; VersionField4 = 0.0.2.3
; VersionField5 = 1.0.0.0
; VersionField6 = Handy Drive LED
; VersionField7 = HandyDrvLED
; VersionField8 = HandyDrvLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60