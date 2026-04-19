; HandyDrvLED UI Drives Window (DPI Aware)

Procedure UpdateDrivesList()
  Protected i.i, drives.s, mask.l, type.l
  Protected itemCount.i
  Protected fixed.i = GetGadgetState(#Gadget_Drives_Fixed)
  Protected removable.i = GetGadgetState(#Gadget_Drives_Removable)
  Protected network.i = GetGadgetState(#Gadget_Drives_Network)
  Protected cdrom.i = GetGadgetState(#Gadget_Drives_CdRom)
  Protected ramdisk.i = GetGadgetState(#Gadget_Drives_RamDisk)
  
  ClearGadgetItems(#Gadget_Drives_Combo)
  
  mask = GetLogicalDrives_()
  For i = 0 To 25
    If mask & (1 << i)
      drives = Chr(65 + i) + ":\"
      type = GetDriveType_(drives)
      Select type
        Case #DRIVE_FIXED : If fixed : AddGadgetItem(#Gadget_Drives_Combo, -1, drives) : itemCount + 1 : EndIf
        Case #DRIVE_REMOVABLE : If removable : AddGadgetItem(#Gadget_Drives_Combo, -1, drives) : itemCount + 1 : EndIf
        Case #DRIVE_REMOTE : If network : AddGadgetItem(#Gadget_Drives_Combo, -1, drives) : itemCount + 1 : EndIf
        Case #DRIVE_CDROM : If cdrom : AddGadgetItem(#Gadget_Drives_Combo, -1, drives) : itemCount + 1 : EndIf
        Case #DRIVE_RAMDISK : If ramdisk : AddGadgetItem(#Gadget_Drives_Combo, -1, drives) : itemCount + 1 : EndIf
      EndSelect
    EndIf
  Next

  If itemCount > 0
    SetGadgetState(#Gadget_Drives_Combo, 0)
  Else
    SetGadgetText(#Gadget_Drives_Editor, Lng\NoDrivesMatch)
  EndIf
EndProcedure

Procedure ShowDriveInfo(root.s)
  Protected free.q, total.q, freeUser.q
  Protected fsName.s = Space(256), volName.s = Space(256)
  Protected serial.l, maxLen.l, flags.l
  Protected info.s
  
  ClearGadgetItems(#Gadget_Drives_Editor)
  
  If GetDiskFreeSpaceEx_(root, @freeUser, @total, @free)
    info = Lng\Drive + ": " + root + #CRLF$
    If GetVolumeInformation_(root, @volName, 256, @serial, @maxLen, @flags, @fsName, 256)
      info + Lng\VolumeName + ": " + Trim(volName) + #CRLF$
      info + Lng\FileSystem + ": " + Trim(fsName) + #CRLF$
    EndIf
    info + Lng\Capacity + ": " + StrD(total / (1024*1024*1024.0), 2) + " GB" + #CRLF$
    info + Lng\Free + ": " + StrD(free / (1024*1024*1024.0), 2) + " GB" + #CRLF$
    info + Lng\Used + ": " + StrD((total - free) / (1024*1024*1024.0), 2) + " GB" + #CRLF$
    
    SetGadgetText(#Gadget_Drives_Editor, info)
  Else
    SetGadgetText(#Gadget_Drives_Editor, Lng\DriveInfoError + root)
  EndIf
EndProcedure

Procedure DrivesWindow(selectedRoot.s)
  Protected w.i, root.s = selectedRoot
  Protected ev.i, gid.i
  
  ; DPI Scaled dimensions
  Protected winW = DesktopScaledX(520), winH = DesktopScaledY(345)
  
  w = OpenWindow(#Window_Drives, 0, 0, winW, winH, Lng\Drives, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  ComboBoxGadget(#Gadget_Drives_Combo, DesktopScaledX(10), DesktopScaledY(10), DesktopScaledX(300), DesktopScaledY(25))
  ButtonGadget(#Gadget_Drives_Open, DesktopScaledX(320), DesktopScaledY(10), DesktopScaledX(60), DesktopScaledY(25), Lng\Open)
  ButtonGadget(#Gadget_Drives_Info, DesktopScaledX(385), DesktopScaledY(10), DesktopScaledX(60), DesktopScaledY(25), Lng\Info)
  ButtonGadget(#Gadget_Drives_Copy, DesktopScaledX(450), DesktopScaledY(10), DesktopScaledX(60), DesktopScaledY(25), Lng\Copy)
  
  CheckBoxGadget(#Gadget_Drives_Fixed, DesktopScaledX(10), DesktopScaledY(40), DesktopScaledX(90), DesktopScaledY(20), Lng\Fixed)
  CheckBoxGadget(#Gadget_Drives_Removable, DesktopScaledX(110), DesktopScaledY(40), DesktopScaledX(110), DesktopScaledY(20), Lng\Removable)
  CheckBoxGadget(#Gadget_Drives_Network, DesktopScaledX(230), DesktopScaledY(40), DesktopScaledX(90), DesktopScaledY(20), Lng\Network)
  CheckBoxGadget(#Gadget_Drives_CdRom, DesktopScaledX(330), DesktopScaledY(40), DesktopScaledX(80), DesktopScaledY(20), Lng\CdRom)
  CheckBoxGadget(#Gadget_Drives_RamDisk, DesktopScaledX(415), DesktopScaledY(40), DesktopScaledX(95), DesktopScaledY(20), Lng\RamDisk)
  
  SetGadgetState(#Gadget_Drives_Fixed, #PB_Checkbox_Checked)
  
  EditorGadget(#Gadget_Drives_Editor, DesktopScaledX(10), DesktopScaledY(65), DesktopScaledX(500), DesktopScaledY(240), #PB_Editor_ReadOnly)
  ButtonGadget(#Gadget_Drives_Close, DesktopScaledX(420), DesktopScaledY(310), DesktopScaledX(90), DesktopScaledY(25), Lng\Close)
  
  UpdateDrivesList()
  If root <> ""
    SetGadgetText(#Gadget_Drives_Combo, root)
    ShowDriveInfo(root)
  EndIf
  
  Repeat
    ev = WaitWindowEvent()
    If ev = #PB_Event_CloseWindow And EventWindow() = #Window_Drives : Break : EndIf
    If ev = #PB_Event_Gadget
      gid = EventGadget()
      Select gid
        Case #Gadget_Drives_Close : Break
        Case #Gadget_Drives_Fixed, #Gadget_Drives_Removable, #Gadget_Drives_Network, #Gadget_Drives_CdRom, #Gadget_Drives_RamDisk
          UpdateDrivesList()
          root = GetGadgetText(#Gadget_Drives_Combo)
          If root <> ""
            ShowDriveInfo(root)
          EndIf
        Case #Gadget_Drives_Info
          root = GetGadgetText(#Gadget_Drives_Combo)
          If root <> "" : ShowDriveInfo(root) : EndIf
        Case #Gadget_Drives_Open
          root = GetGadgetText(#Gadget_Drives_Combo)
          If root <> "" : RunProgram("explorer.exe", root, "") : EndIf
        Case #Gadget_Drives_Copy
          SetClipboardText(GetGadgetText(#Gadget_Drives_Editor))
      EndSelect
    EndIf
  ForEver
  CloseWindow(#Window_Drives)
EndProcedure
