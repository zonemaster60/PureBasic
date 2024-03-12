;PB4.00
;20061127, now works with unicode executables

Declare createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
Declare.s getSpecialFolder(id)

Procedure.s getSpecialFolder(id)
  Protected path.s, *ItemId.ITEMIDLIST
 
  *itemId = #Null
  If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
    path = Space(#MAX_PATH)
    If SHGetPathFromIDList_(*itemId, @path)
      If Right(path, 1) <> "\"
        path + "\"
      EndIf
      ProcedureReturn path
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
  ;obj - path to the exe that is linked to, lnk - link name, dir - working
  ;directory, icon - path to the icon file, index - icon index in iconfile
  Protected hRes.l, mem.s, ppf.IPersistFile
  CompilerIf #PB_Compiler_Unicode
    Protected psl.IShellLinkW
  CompilerElse
    Protected psl.IShellLinkA
  CompilerEndIf

  ;make shure COM is active
  CoInitialize_(0)
  hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)

  If hRes = 0
    psl\SetPath(Obj)
    psl\SetArguments(arg)
    psl\SetDescription(desc)
    psl\SetWorkingDirectory(dir)
    psl\SetIconLocation(icon, index)
    ;query IShellLink for the IPersistFile interface for saving the
    ;link in persistent storage
    hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)

    If hRes = 0
      ;CompilerIf #PB_Compiler_Unicode
        ;save the link
        hRes = ppf\Save(lnk, #True)
;       CompilerElse
;         ;ensure that the string is ansi unicode
;         mem = Space(#MAX_PATH)
;         MultiByteToWideChar_(#CP_ACP, 0, lnk, -1, mem, #MAX_PATH)
;         ;save the link
;         hRes = ppf\Save(mem, #True)
;       CompilerEndIf
      ppf\Release()
    EndIf
    psl\Release()
  EndIf

  ;shut down COM
  CoUninitialize_()

  DataSection
    CLSID_ShellLink:
    Data.l $00021401
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IShellLink:
    CompilerIf #PB_Compiler_Unicode
      Data.l $000214F9
    CompilerElse
      Data.l $000214EE
    CompilerEndIf
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IPersistFile:
    Data.l $0000010b
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
  EndDataSection
  ProcedureReturn hRes
EndProcedure

#CSIDL_WINDOWS = $24
#CSIDL_DESKTOPDIRECTORY = $10

Global obj.s, obj2.s, lnk.s, lnk2.s

obj = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyDrvLED\HandyDrvLED.exe"
obj2 = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyDrvLED"
lnk = getSpecialFolder(#CSIDL_ALTSTARTUP)
lnk2 = getSpecialFolder(#CSIDL_DESKTOPDIRECTORY)

; check for existence of desktop link
If FileSize(lnk2 + "HandyDrvLED.lnk") = -1
  If createShellLink(obj, lnk2 + "HandyDrvLED.lnk", "", "Start HandyDrvLED", obj2, obj, 0) = 0
    MessageRequester("Info", "A Desktop link was created.", #PB_MessageRequester_Info)
  EndIf
EndIf

If FileSize(lnk + "HandyDrvLED.lnk") = -1
; check for existence of startup link
  If createShellLink(obj, lnk + "HandyDrvLED.lnk", "", "HandyDrvLED startup link", obj2, obj, 0) = 0
    MessageRequester("Info", "A Startup link was created.", #PB_MessageRequester_Info)
  EndIf
EndIf

; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.10

#IOCTL_DISK_PERFORMANCE = $70020

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
drv$ = Chr(drv) + ":\"
flag.i = 0
numicl.i = 0
mTime.i = 4000 ; 4 secs - was 5000
version.s = " v0.0.1.8 (20241302)"
Global hdh

If ExamineDirectory(0, "IconLibs\", "*.icl")
  While NextDirectoryEntry(0)
    numicl + 1
  Wend
  If numicl = 0 : numicl = 1 : EndIf
  FinishDirectory(0)
EndIf

flag1.i = Random(numicl, 1)
If flag1 < 1 : flag1 = 1 : EndIf
iconlib.s = "IconLibs\HandyDrvLED." + flag1 + ".icl"
IdIcon1=ExtractIcon_(0, iconlib, 0)     
IdIcon2=ExtractIcon_(0, iconlib, 1)
IdIcon3=ExtractIcon_(0, iconlib, 2)
IdIcon4=ExtractIcon_(0, iconlib, 3)

; create physical drive
Procedure OpenPhysDrive(CurrentDrive.l)
  hdh = CreateFile_("\\.\PhysicalDrive" + Str(CurrentDrive), 0, 0, 0, #OPEN_EXISTING, 0, 0)
  ProcedureReturn hdh
EndProcedure

; exit procedure
Procedure Exit()
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

; help procedure
Procedure Help()
  MessageRequester("Help", "-> Adding HandyDrvLED to the Startup: Create a" + #CRLF$ +
                           "shortcut of 'HandyDrvLED.exe' and copy it to the" + #CRLF$ +
                           "C:\Users\<name>\AppData\Roaming\Microsoft\Windows" + #CRLF$ +
                           "\Start Menu\Programs\Startup' folder is the easiest." + #CRLF$ + #CRLF$+
                           "-> You can select 'Explore', 'DriveInfo', or 'IconSet' by " + #CRLF$ +
                           "right-clicking the icon in the system tray and selecting it." + #CRLF$ + #CRLF$+
                           "-> Icon Sets can now be included. A random icon set" + #CRLF$ +
                           "will be loaded each time the program is initialized." + #CRLF$ + #CRLF$ +
                           "Icon Legend:" + #CRLF$ +
                           " RED=Write,GREEN=Read,BLUE=System,YELLOW=Idle", #PB_MessageRequester_Info)
EndProcedure

; display drive information
Procedure DriveInfo(lpRootPathName.s)
  
Info.s
pVolumeNameBuffer.s = Space(256)
nVolumeNameSize.l = 256
lpVolumeSerialNumber.l
lpMaximumComponentLength.l
lpFileSystemFlags.l
lpFileSystemNameBuffer.s = Space(256)
nFileSystemNameSize.l = 256
  
Result = GetVolumeInformation_(lpRootPathName, pVolumeNameBuffer, 256, @lpVolumeSerialNumber, @lpMaximumComponentLength, @lpFileSystemFlags, lpFileSystemNameBuffer, 256)

GetDiskFreeSpace(lpRootPathName.s)
Info = Info + "Capacity: " + Str(HDCapacity(0)/1024/1024/1024) + " GB" + Chr(13)
Info = Info + "Used: " + Str((HDCapacity(0)-HDFreeSpace(0))/1024/1024/1024) + " GB" +Chr(13)
Info = Info + "Free: " + Str(HDFreeSpace(0)/1024/1024/1024) + " GB" + Chr(13)
Info = Info + "VolumeName: " + LTrim(pVolumeNameBuffer) + Chr(13)
Info = Info + "VolumeID: " + Hex(lpVolumeSerialNumber) + Chr(13)
Info = Info + "FileSystem: " + LTrim(lpFileSystemNameBuffer)

MessageRequester("DriveInfo For " + lpRootPathName, Info, #PB_MessageRequester_Info)
EndProcedure

; display about dialog
Procedure About(version.s)
  MessageRequester("About", "Handy Drive LED" + version + #CRLF$ +
                            "Email: zonemaster@yahoo.com", #PB_MessageRequester_Info)
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

; check for running instance
If FindWindow_(0, "HandyDrvLED")
  MessageRequester("Info", "HandyDrvLED is already running.", #PB_MessageRequester_Info)
  End
EndIf  

dp.DISK_PERFORMANCE
Window_Form1 = OpenWindow(0, 80, 80, 100, 100, "HandyDrvLED", #PB_Window_Invisible)

; create the menu pop-up
CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Help")
MenuBar()
MenuItem(3, "Explore")
MenuItem(4, "DriveInfo")
MenuItem(5, "IconSet")
MenuBar()
MenuItem(6, "Exit")

; add the items to the system tray
AddSysTrayIcon(1, WindowID(0), IdIcon3)
SysTrayIconToolTip(1, "Handy Drive LED" + version)
Delay(mTime/2)

Repeat
  
  EventID = WaitWindowEvent(10)
  Result = DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0)

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
  If dp\WriteTime <> OldWriteTime.q ; When writing - flash LED display symbol
    OldWriteTime = dp\WriteTime
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
      SysTrayIconToolTip(1, "RC: " + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + " MB) | WC: " + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + " MB) | IS=#"+flag1)
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
        About(version)
      Case 2
        Help()
      Case 3
        For drv = 65 To 90 : drv$ = Chr(drv) + ":\"
          If GetDriveType_(drv$) = #DRIVE_FIXED : EndIf
          If drv$ = "C:\" : RunProgram("file://" + drv$) : EndIf
        Next
      Case 4
        For drv = 65 To 90 : drv$ = Chr(drv) + ":\"
          If GetDriveType_(drv$) = #DRIVE_FIXED
            DriveInfo(drv$)
            Req = MessageRequester("Next", "Go on to the next drive?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
            If Req = #PB_MessageRequester_No
              Goto OuttaHere1
            EndIf
          EndIf
        Next
        OuttaHere1:
      Case 5
        ChangeSysTrayIcon(1, IdIcon3)
        SysTrayIconToolTip(1, "Handy Drive LED" + version)
        Delay(mTime/2)
        flag1 = Random(numicl, 1)
        If flag1 < 1 : flag1 = 1 : EndIf
        iconlib = "IconLibs\HandyDrvLED." + flag1 + ".icl"
        IdIcon1=ExtractIcon_(0, iconlib, 0)     
        IdIcon2=ExtractIcon_(0, iconlib, 1)
        IdIcon3=ExtractIcon_(0, iconlib, 2)
        IdIcon4=ExtractIcon_(0, iconlib, 3)
        ChangeSysTrayIcon(1, IdIcon3)
        SysTrayIconToolTip(1, "Changing to Icon Set #" + flag1)
        Delay(mTime/2)
      Case 6
        Exit()    
    EndSelect
  EndIf
  
  If EventID = #PB_Event_CloseWindow ; Exit the program
    Exit = 1
  EndIf
  
Until Exit = 1

; IDE Options = PureBasic 6.10 beta 6 (Windows - x64)
; CursorPosition = 146
; FirstLine = 132
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = HandyDrvLED.ico
; Executable = HandyDrvLED.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 0,0,0,1
; VersionField1 = 0,0,1,8
; VersionField2 = ZoneSoft
; VersionField3 = HandyDrvLED
; VersionField4 = v0.0.1.8
; VersionField5 = v0.0.0.1
; VersionField6 = Handy Drive LED
; VersionField7 = HandyDrvLED
; VersionField8 = HandyDrvLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60