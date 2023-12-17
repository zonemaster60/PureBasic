;http://pbasic.spb.ru/phpBB2/viewtopic.php?t=1066
; Author: kvitaliy 2010
; PureBasic v 4.4

#IOCTL_DISK_PERFORMANCE=$70020;

Structure DISK_PERFORMANCE
  BytesRead.q;
  BytesWritten.q;
  ReadTime.q;
  WriteTime.q;
  IdleTime.q;
  ReadCount.l;
  WriteCount.l;
  QueueDepth.l;
  SplitCount.l;
  QueryTime.l;
  StorageDeviceNumber.l;
  StorageManagerName.l[8];
EndStructure
SystemPath.s=Space(255)
Result=GetSystemDirectory_(SystemPath.s,255)
Global hdh
;Procedure ScrollLock-blinken
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

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

   ;Prüft, ob eine physische Festplatte im System nach 0 (neben 1 Disc, etc.) 
If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
  End ; es gibt keinen Ausstieg aus dem Programm-CD
EndIf
   ; Programm-Icon in der Taskleiste wird aus der System-DLL übernommen
IdIcon1=ExtractIcon_(0,SystemPath+"\SetupAPI.dll",29)     
IdIcon2=ExtractIcon_(0,SystemPath+"\SetupAPI.dll",8)   
   
dp.DISK_PERFORMANCE
     
Window_Form1=OpenWindow(0,80,80,100,100,"HDD Activity LED",#PB_Window_Invisible)

CreatePopupMenu(0)
MenuItem(1, "About")
MenuItem(2, "Exit")

AddSysTrayIcon(1, WindowID(0),IdIcon2) ;
SysTrayIconToolTip(1, "HDD Activity LED")

Repeat
  
  EventID = WaitWindowEvent(10)
  
  Result=DeviceIoControl_(hdh, #IOCTL_DISK_PERFORMANCE, 0, 0, @dp, SizeOf(DISK_PERFORMANCE), @lBytesReturned, 0);

  ; Wenn sich Dauer des Lesen verändert
  If dp\ReadTime <> OldReadTime.q; Wenn gelesen wird - LED-Anzeige-Symbol blinken lassen
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
  
  ; Wenn sich Dauer des Screiben verändert
  If dp\WriteTime<>OldWriteTime.q ;Wenn geschrieben wird - LED-Anzeige-Symbol blinken lassen
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
      SysTrayIconToolTip(1, "HDD Monitor R:" + Str((dp\ReadCount - Count_Read)*12) + " (" + StrU(dp\BytesRead/$100000, #PB_Quad) + "MB) | W:" + Str((dp\WriteCount - Count_Write)*12) + " (" + StrU(dp\BytesWritten/$100000, #PB_Quad) + "MB) [Req/min]")
    EndIf
    Count_Read = dp\ReadCount
    Count_Write = dp\WriteCount
    TimeOut = ElapsedMilliseconds() + 5000
  EndIf
  
  If EventID = #PB_Event_SysTray
    Select EventType()
      Case #PB_EventType_RightClick ;Die Verarbeitung der rechten Maustaste
        DisplayPopupMenu(0, WindowID(0)) ;zeige Popup-Menü
    EndSelect
  EndIf
  
  If EventID = #PB_Event_Menu
    Select EventMenu()
      Case 2
        JustExit()
      Case 1
        MessageRequester("About", "HDD Activity LED", #PB_MessageRequester_Ok | #PB_MessageRequester_Info)
    EndSelect
  EndIf
  If EventID = #PB_Event_CloseWindow  ; Beenden Sie das Programm
    Exit=1
  EndIf
  
Until Exit=1
SetScrollLED(#VK_SCROLL,#False) 

; IDE Options = PureBasic 6.03 beta 9 LTS (Windows - x64)
; CursorPosition = 55
; FirstLine = 41
; Folding = -
; EnableXP
; DPIAware