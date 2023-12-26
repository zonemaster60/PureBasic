; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.04

XIncludeFile "Registry.pbi"
UseModule Registry

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

Define version.s = "0.1.0.7"
       bdate.s = "12/26/2023"
       filename.s = "HandyHDLED.icl"
       Multi_SZ_Str.s = GetCurrentDirectory()+"HandyHDLED.exe"
       
SystemPath.s=Space(255)
Result=GetSystemDirectory_(SystemPath.s,255)
Global hdh

;Procedure ScrollLock flashing
Procedure SetScrollLED(VKkey.l, bState.b)
  
  Dim keyState.b(256)
  GetKeyboardState_(@keyState(0))
  
  If (bState = #True And keyState(VKkey) = 0) Or (bState = #False And keyState(VKkey) = 1)
    keybd_event_(VKkey, 0, #KEYEVENTF_EXTENDEDKEY, 0)
    keybd_event_(VKkey, 0, #KEYEVENTF_EXTENDEDKEY + #KEYEVENTF_KEYUP, 0)
    keyState(VKkey) = bState
    SetKeyboardState_(@keyState(0))
  EndIf
  
EndProcedure     

Procedure OpenPhysDrive(CurrentDrive.l)
  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive),0,0,0,#OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

; exiting procedure
Procedure Exit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

; help procedure
Procedure Help()
  MessageRequester("Help", "1) Adding HandyHDLED to the Startup: Go to 'C:\"+#CRLF$+
                           "Users\<name>\AppData\Roaming\Microsoft\Windows"+#CRLF$+
                           "\Start Menu\Programs\Startup'. Create and copy"+#CRLF$+
                           "the shortcut to THIS folder for the easiest method."+#CRLF$+
                           "(You may have to modify the shortcut to point to"+#CRLF$+
                           "the location where you have HandyHDLED installed.)"+#CRLF$+#CRLF$+
                           "2) You can add HandyHDLED to Startup by right-clicking"+#CRLF$+
                           "the pop-up menu in the system tray and click 'Add->Startup'"+#CRLF$+
                           "or click 'Del<-Startup' to remove the startup entry."+#CRLF$+
                           "If you choose you may also do it manually by adding"+#CRLF$+
                           "the Key->Value='HandyHDLED' and the String->Value='C:\"+#CRLF$+
                           "<Folder>\HandyHDLED.exe' to 'HKLM\Software\Microsoft\"+#CRLF$+
                           "Windows\CurrentVersion\Run' by using a registry editor.", #PB_MessageRequester_Info | #PB_MessageRequester_Ok)
EndProcedure

; display drive information
Procedure ViewDriveInfo()
User.s=Space(255)
l.l=255
Result=GetComputerName_(User,@l)
Info.s
Info="ComputerName: "+Left(User,l)+Chr(13)

User.s=Space(255)
l.l=255
Result=GetUserName_(User,@l)
Info=Info+"User: "+LTrim(User)+Chr(13)

lpRootPathName.s="C:\"
pVolumeNameBuffer.s=Space(256)
nVolumeNameSize.l=256
lpVolumeSerialNumber.l
lpMaximumComponentLength.l
lpFileSystemFlags.l
lpFileSystemNameBuffer.s=Space(256)
nFileSystemNameSize.l=256

Result=GetVolumeInformation_(lpRootPathName,pVolumeNameBuffer,256,@lpVolumeSerialNumber,@lpMaximumComponentLength,@lpFileSystemFlags,lpFileSystemNameBuffer,256)

Info=Info + "DriveID="+Hex(lpVolumeSerialNumber)+Chr(13)
Info=Info + "VolumeName: "+LTrim(pVolumeNameBuffer) +Chr(13)
Info=Info + "FileSystem: "+LTrim(lpFileSystemNameBuffer)

MessageRequester("View DriveInfo",Info,#PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; display about dialog
Procedure About(version.s,bdate.s)
  MessageRequester("About", "HandyHDLED v"+version+" "+bdate+#CRLF$+
                            "Email: zonemaster@yahoo.com",#PB_MessageRequester_Ok | #PB_MessageRequester_Info)
EndProcedure

; adds a startup entry to windows registry
Procedure AddStartup(Multi_SZ_Str.s)
    WriteValue(#HKEY_LOCAL_MACHINE, "SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HandyHDLED", Multi_SZ_Str, #REG_SZ)
    MessageRequester("Info", "RegistryKey->'HandyHDLED' and RegistryValue->'"+#CRLF$+                        
                             Multi_SZ_Str+"' added to the Registry.", #PB_MessageRequester_Info | #PB_MessageRequester_Ok)
EndProcedure
  
; remove a startup entry from windows registry
Procedure DelStartup(Multi_SZ_Str.s)
    DeleteValue(#HKEY_LOCAL_MACHINE, "SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HandyHDLED")
    MessageRequester("Info", "RegistryKey->'HandyHDLED' and RegistryValue->'"+#CRLF$+                                                 
                             Multi_SZ_Str+"' removed from the Registry.", #PB_MessageRequester_Info | #PB_MessageRequester_Ok) 
EndProcedure
  
; Checks if there is a physical disk in the system 
If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
  End ; There is no exit from the program
EndIf

; check for existence of Library file
If ExamineDirectory(1, ".", filename) = 0
  ; file does not exist
  MessageRequester("Error","Required library file: "+filename+#CRLF$+
                           "not found or missing!",#PB_MessageRequester_Ok | #PB_MessageRequester_Error)
  End
EndIf

;Program icon in the taskbar is taken from the ICL
IdIcon1=ExtractIcon_(0, filename, 0)     
IdIcon2=ExtractIcon_(0, filename, 1)
IdIcon3=ExtractIcon_(0, filename, 2)

If FindWindow_(0,"HandyHDLED")
  MessageRequester("Info", "HandyHDLED is already running.",#PB_MessageRequester_Ok | #PB_MessageRequester_Info)
  End
EndIf  

dp.DISK_PERFORMANCE
     
Window_Form1=OpenWindow(0,80,80,100,100,"HandyHDLED",#PB_Window_Invisible)

; create the menu pop-up
CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Help")
MenuBar()
MenuItem(3, "Add->Startup")
MenuItem(4, "Del<-Startup")
MenuItem(5, "View DriveInfo")
MenuBar()
MenuItem(6, "Exit")
DisableMenuItem(0,4,1)

; add the items to the system tray
AddSysTrayIcon(1, WindowID(0),IdIcon3)
SysTrayIconToolTip(1, "HandyHDLED v"+version+" "+bdate)

Repeat
  
  EventID = WaitWindowEvent(10)
  Result=DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)

  ; When the duration of reading changes
  If dp\ReadTime <> OldReadTime.q ; When reading - flash LED display symbol
    OldReadTime = dp\ReadTime
    If Not flags
      SetScrollLED(#VK_SCROLL,#True)
      ChangeSysTrayIcon(1,IdIcon2)
      flags = #True
    EndIf
  Else
    If flags
      SetScrollLED(#VK_SCROLL,#False)
      ChangeSysTrayIcon(1,IdIcon1)
      flags = #Null
    EndIf
  EndIf
  
  ; When the duration of writing changes
  If dp\WriteTime<>OldWriteTime.q ; When writing - flash LED display symbol
    OldWriteTime= dp\WriteTime
    If Not flags
      SetScrollLED(#VK_SCROLL,#True)
      ChangeSysTrayIcon(1,IdIcon2)
      flags = #True
    EndIf
  Else
    If flags
      SetScrollLED(#VK_SCROLL,#False)   
      ChangeSysTrayIcon(1,IdIcon1)
      flags = #Null
    EndIf
  EndIf
  
  Delay (100)
  
  If ElapsedMilliseconds() > TimeOut
    If TimeOut
      SysTrayIconToolTip(1, "Read: " + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + "MB) | Write: " + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + "MB)")
    EndIf
    Count_Read = dp\ReadCount
    Count_Write = dp\WriteCount
    TimeOut = ElapsedMilliseconds() + 5000
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
        About(version.s,bdate.s)
      Case 2
        Help()
      Case 3  
        AddStartup(Multi_SZ_Str)
        DisableMenuItem(0,3,1)
        DisableMenuItem(0,4,0)
      Case 4
        DelStartup(Multi_SZ_Str)
        DisableMenuItem(0,3,0)
        DisableMenuItem(0,4,1)
      Case 5
        ViewDriveInfo()
      Case 6
        Exit()    
    EndSelect
  EndIf
  
  If EventID = #PB_Event_CloseWindow ; Exit the program
    Exit=1
  EndIf
  
Until Exit=1
SetScrollLED(#VK_SCROLL,#False) 

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 27
; FirstLine = 4
; Folding = --
; Optimizer
; EnableXP
; DPIAware
; UseIcon = HandyHDLED.ico
; Executable = ..\HandyHDLED.exe
; IncludeVersionInfo
; VersionField0 = 0.0.0.1
; VersionField1 = 0.1.0.7
; VersionField2 = ZoneSoft
; VersionField3 = HandyHDLED
; VersionField4 = v0.1.0.7
; VersionField5 = v0.0.0.1
; VersionField6 = Handy HardDrive LED
; VersionField7 = HandyHDLED
; VersionField8 = HandyHDLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60