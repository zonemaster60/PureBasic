; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.11

#IOCTL_DISK_PERFORMANCE=$70020

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

Procedure GetDiskFreeSpace(drive$)
  SetErrorMode_(#SEM_FAILCRITICALERRORS)
  GetDiskFreeSpaceEx_(@drive$, HDAvailableSpace(), HDCapacity(), HDFreeSpace())
  SetErrorMode_(0)
EndProcedure

Define drv.i
Define drv$ = Chr(drv)+":\"
Define version.s = " v0.1.4.9 (20240617)"

If ExamineDirectory(0, "IconLibs\", "*.icl")
  Define numicl.i = 0
  While NextDirectoryEntry(0)
    numicl + 1
  Wend
  If numicl = 0 : numicl = 1 : EndIf
  FinishDirectory(0)
EndIf

flag1.i = Random(numicl, 1)
If flag1 < 1 : flag1 = 1 : EndIf
iconlib.s = "IconLibs\HandyHDLED." + flag1 + ".icl"
IdIcon1=ExtractIcon_(0, iconlib, 0)     
IdIcon2=ExtractIcon_(0, iconlib, 1)
IdIcon3=ExtractIcon_(0, iconlib, 2)
IdIcon4=ExtractIcon_(0, iconlib, 3)

mTime.i = 3000 ; 5000     
SystemPath.s = Space(255)
Result = GetSystemDirectory_(SystemPath.s, 255)
Global hdh

Procedure OpenPhysDrive(CurrentDrive.l)
  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive), 0, 0, 0, #OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

; exit procedure
Procedure Exit()
  Req=MessageRequester("Warning", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

; help procedure
Procedure Help(numicl.i)
  MessageRequester("Help", "-> Adding HandyHDLED to the Startup: Create a" + #CRLF$ +
                           "shortcut of 'HandyHDLED.exe' and copy it to the" + #CRLF$ +
                           "C:\Users\<name>\AppData\Roaming\Microsoft\Windows" + #CRLF$ +
                           "\Start Menu\Programs\Startup' folder is the easiest." + #CRLF$ + #CRLF$ +
                           "-> You can select 'DriveInfo', 'Explore', or 'IconSet' by" + #CRLF$ +
                           "right-clicking the icon in the system tray and selecting it." + #CRLF$ + #CRLF$ +
                           "-> Custom Icon Sets now included (" + Str(numicl) + " total). A random" + #CRLF$ +
                           "icon set will be selected each time the app is started.", #PB_MessageRequester_Info)
EndProcedure

; display drive information
Procedure DriveInfo(lpRootPathName.s)
  
Info.s
pVolumeNameBuffer.s=Space(256)
nVolumeNameSize.l=256
lpVolumeSerialNumber.l
lpMaximumComponentLength.l
lpFileSystemFlags.l
lpFileSystemNameBuffer.s = Space(256)
nFileSystemNameSize.l=256
  
Result = GetVolumeInformation_(lpRootPathName, pVolumeNameBuffer, 256, @lpVolumeSerialNumber, @lpMaximumComponentLength, @lpFileSystemFlags, lpFileSystemNameBuffer, 256)

GetDiskFreeSpace(lpRootPathName)
Info=Info + "Capacity: " + Str(HDCapacity(0)/1024/1024/1024)+" GB" + Chr(13)
Info=Info + "Used: " + Str((HDCapacity(0)-HDFreeSpace(0))/1024/1024/1024)+" GB" + Chr(13)
Info=Info + "Free: " + Str(HDFreeSpace(0)/1024/1024/1024)+ " GB" + Chr(13)
Info=Info + "VolumeName: " + LTrim(pVolumeNameBuffer) + Chr(13)
Info=Info + "VolumeID: " + Hex(lpVolumeSerialNumber) + Chr(13)
Info=Info + "FileSystem: " + LTrim(lpFileSystemNameBuffer)

MessageRequester("DriveInfo For " + lpRootPathName, Info, #PB_MessageRequester_Info)
EndProcedure

; display about dialog
Procedure About(version.s, flag1.i, numicl.i)
  MessageRequester("About", "HandyHDLED" + version + #CRLF$ +
                            "Email: zonemaster@yahoo.com" + #CRLF$ +
                            "Custom Icon Set #" + Str(flag1) + " of " + Str(numicl), #PB_MessageRequester_Info)
EndProcedure

; Checks if there is a physical disk in the system 
If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
  MessageRequester("Error", "Unable to open drive!", #PB_MessageRequester_Error)
  End
EndIf

; check for existence of Library file
If ExamineDirectory(1, ".", iconlib) = 0
  ; file does not exist
  MessageRequester("Error", iconlib + " not found or missing!", #PB_MessageRequester_Error)
  FinishDirectory(1)
  End
EndIf

; Check for running instance
If FindWindow_(0, "HandyHDLED")
  MessageRequester("Info", "HandyHDLED is already running.", #PB_MessageRequester_Info)
  End
EndIf  

dp.DISK_PERFORMANCE
Window_Form1=OpenWindow(0, 80, 80, 100, 100, "HandyHDLED", #PB_Window_Invisible)

; create the menu pop-up
CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Help")
MenuBar()
MenuItem(3, "DriveInfo")
MenuItem(4, "Explore")
MenuItem(5, "IconSet")
MenuBar()
MenuItem(6, "Exit")

; add the items to the system tray
AddSysTrayIcon(1, WindowID(0), IdIcon3)
SysTrayIconToolTip(1, "HandyHDLED" + version)

Repeat
  
  EventID = WaitWindowEvent(10)
  Result=DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)

  ; When the duration of reading changes
  If dp\ReadTime <> OldReadTime.q ; When reading - flash LED display symbol
    OldReadTime = dp\ReadTime
    If Not flags
      ChangeSysTrayIcon(1, IdIcon1)
      flags = #True
    Else
      ChangeSysTrayIcon(1, IdIcon4)
      flags = #False
    EndIf
  Else
    If flags
      ChangeSysTrayIcon(1, IdIcon2)
      flags = #Null
    Else
      ChangeSysTrayIcon(1, IdIcon4)
      flags = #False
    EndIf
  EndIf
  
  ; When the duration of writing changes
  If dp\WriteTime<>OldWriteTime.q ; When writing - flash LED display symbol
    OldWriteTime= dp\WriteTime
    If Not flags
      ChangeSysTrayIcon(1, IdIcon1)
      flags = #True
    Else
      ChangeSysTrayIcon(1, IdIcon4)
      flags = #False
    EndIf
  Else
    If flags
      ChangeSysTrayIcon(1, IdIcon2)
      flags = #Null
    Else
      ChangeSysTrayIcon(1, IdIcon4)
      flags = #False
    EndIf
  EndIf
  
  Delay (100)
  
  If ElapsedMilliseconds() > TimeOut
    If TimeOut
      SysTrayIconToolTip(1, "Read: " + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + " MB) | Write: " + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + " MB)")
    EndIf
    Count_Read = dp\ReadCount
    Count_Write = dp\WriteCount
    TimeOut = ElapsedMilliseconds() + mTime
  EndIf
  
  If EventID = #PB_Event_SysTray
    Select EventType()
      Case #PB_EventType_RightClick ; Process the right mouse button
        DisplayPopupMenu(0, WindowID(0)) ; Show the popup menu
    EndSelect
  EndIf
  
  If EventID = #PB_Event_Menu
    Select EventMenu()
      Case 1
        About(version, flag1, numicl)
      Case 2
        Help(numicl)
      Case 3
        For drv = 65 To 90 : drv$ = Chr(drv) + ":\"
          If GetDriveType_(drv$) = #DRIVE_FIXED : DriveInfo(drv$) : EndIf
        Next
      Case 4
        For drv = 65 To 90 : drv$ = Chr(drv) + ":\"
          If GetDriveType_(drv$) = #DRIVE_FIXED : RunProgram("file://" + drv$) : EndIf
        Next
      Case 5
        flag1 = Random(numicl, 1)
        If flag1 < 1 : flag1 = 1 : EndIf
        iconlib = "IconLibs\HandyHDLED." + flag1 + ".icl"
        IdIcon1=ExtractIcon_(0, iconlib, 0)     
        IdIcon2=ExtractIcon_(0, iconlib, 1)
        IdIcon3=ExtractIcon_(0, iconlib, 2)
        IdIcon4=ExtractIcon_(0, iconlib, 3)
        Delay(10)
      Case 6
        Exit()    
    EndSelect
  EndIf
  
  If EventID = #PB_Event_CloseWindow ; Exit the program
    Exit = 1
  EndIf
  
Until Exit = 1

; IDE Options = PureBasic 6.30 beta 4 (Windows - x64)
; CursorPosition = 44
; FirstLine = 44
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = HandyHDLED.ico
; Executable = D:\Apps\HandyHDLED.exe
; IncludeVersionInfo
; VersionField0 = 0,0,0,1
; VersionField1 = 0,1,4,9
; VersionField2 = ZoneSoft
; VersionField3 = HandyHDLED
; VersionField4 = v0.1.4.9
; VersionField5 = v0.0.0.1
; VersionField6 = Handy HardDrive LED
; VersionField7 = HandyHDLED
; VersionField8 = HandyHDLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60