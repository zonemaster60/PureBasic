; Cleaner, monitor, snapshots, stress tools

;- Registry Cleaner

Procedure SendCleanerMsg(msg.s, windowID.i, editorID.i)
  PostEvent(#EVENT_CLEANER_MSG, windowID, 0, 0, UTF8(msg))
EndProcedure

Procedure CleanerThread(param.i)
  Protected *p.CleanerParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected wow64.i = *p\Wow64
  Protected isCleaning.i = *p\IsCleaning
  Protected ret.Registry::RegValue
  Protected i.i, count.i, valName.s, subKeyName.s, cleanedCount.i = 0
  
  SendCleanerMsg("--- Starting Registry Scan ---", *p\WindowID, *p\EditorID)
  
  ; MUI Cache Logic
  If *p\MuiCache
    Protected muiPath.s = "Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    count = Registry::CountSubValues(#HKEY_CURRENT_USER, muiPath, wow64, @ret)
    For i = count - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, muiPath, i, wow64, @ret)

      If valName <> "" And FindString(valName, ":\", 1)
        Protected filePath.s = valName
        If Left(filePath, 1) = "@" : filePath = Mid(filePath, 2) : EndIf
        If FindString(filePath, ",", 1) : filePath = StringField(filePath, 1, ",") : EndIf
        If FileSize(filePath) = -1
          If isCleaning
            SendCleanerMsg("[MUI] Deleting: " + valName, *p\WindowID, *p\EditorID)
            If Registry::DeleteValue(#HKEY_CURRENT_USER, muiPath, valName, wow64, @ret) : cleanedCount + 1 : EndIf
          Else
            SendCleanerMsg("[MUI] Broken Link: " + valName, *p\WindowID, *p\EditorID)
            cleanedCount + 1
          EndIf
        EndIf
      EndIf
    Next
  EndIf

  ; Installer Refs
  If *p\InstallerRefs
    Protected installPath.s = "Software\Microsoft\Windows\CurrentVersion\Installer\Folders"
    count = Registry::CountSubValues(#HKEY_CURRENT_USER, installPath, wow64, @ret)
    For i = count - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, installPath, i, wow64, @ret)
      If valName <> "" And FileSize(valName) = -1
        If isCleaning
          SendCleanerMsg("[Installer] Deleting: " + valName, *p\WindowID, *p\EditorID)
          If Registry::DeleteValue(#HKEY_CURRENT_USER, installPath, valName, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          SendCleanerMsg("[Installer] Missing Dir: " + valName, *p\WindowID, *p\EditorID)
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  
  ; File Associations
  If *p\FileAssoc
    Protected classesPath.s = "Software\Classes"
    Protected assocCount.i = Registry::CountSubKeys(#HKEY_CURRENT_USER, classesPath, wow64, @ret)
    For i = assocCount - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, classesPath, i, wow64, @ret)
      If Left(subKeyName, 1) = "."
        Protected progID.s = Registry::ReadValue(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, "", wow64, @ret)
        If progID <> ""
          ; Check if ProgID exists in HKCU or HKCR
          If Registry::KeyExists(#HKEY_CURRENT_USER, "Software\Classes\" + progID, wow64) = #False And
             Registry::KeyExists(#HKEY_CLASSES_ROOT, progID, wow64) = #False
            
            If isCleaning
              SendCleanerMsg("[Assoc] Deleting .ext: " + subKeyName, *p\WindowID, *p\EditorID)
              If Registry::DeleteKey(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, wow64, @ret) : cleanedCount + 1 : EndIf
            Else
              SendCleanerMsg("[Assoc] Broken .ext (" + subKeyName + ") -> " + progID, *p\WindowID, *p\EditorID)
              cleanedCount + 1
            EndIf
          EndIf
        EndIf
      EndIf
    Next
  EndIf
  
  ; Obsolete Software
  If *p\ObsoleteSw
    Protected uninstallPath.s = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    Protected uCount.i
    
    ; Scan HKLM (64-bit/Standard)
    uCount = Registry::CountSubKeys(#HKEY_LOCAL_MACHINE, uninstallPath, wow64, @ret)
    For i = uCount - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_LOCAL_MACHINE, uninstallPath, i, wow64, @ret)
      Protected fullUPath.s = uninstallPath + "\" + subKeyName
      Protected installLoc.s = Registry::ReadValue(#HKEY_LOCAL_MACHINE, fullUPath, "InstallLocation", wow64, @ret)
      If installLoc <> "" And FileSize(installLoc) = -1
        If isCleaning
          SendCleanerMsg("[Software] Deleting: " + subKeyName, *p\WindowID, *p\EditorID)
          If Registry::DeleteKey(#HKEY_LOCAL_MACHINE, fullUPath, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          SendCleanerMsg("[Software] Obsolete: " + subKeyName, *p\WindowID, *p\EditorID)
          cleanedCount + 1
        EndIf
      EndIf
    Next

    ; Scan HKLM (WOW6432Node if on 64-bit)
    If wow64
      Protected wowPath.s = "Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
      uCount = Registry::CountSubKeys(#HKEY_LOCAL_MACHINE, wowPath, wow64, @ret)
      For i = uCount - 1 To 0 Step -1
        If CleanerStopRequested : Break : EndIf
        subKeyName = Registry::ListSubKey(#HKEY_LOCAL_MACHINE, wowPath, i, wow64, @ret)
        Protected fullWPath.s = wowPath + "\" + subKeyName
        Protected wowInstallLoc.s = Registry::ReadValue(#HKEY_LOCAL_MACHINE, fullWPath, "InstallLocation", wow64, @ret)
        If wowInstallLoc <> "" And FileSize(wowInstallLoc) = -1
          If isCleaning
            SendCleanerMsg("[Software32] Deleting: " + subKeyName, *p\WindowID, *p\EditorID)
            If Registry::DeleteKey(#HKEY_LOCAL_MACHINE, fullWPath, wow64, @ret) : cleanedCount + 1 : EndIf
          Else
            SendCleanerMsg("[Software32] Obsolete: " + subKeyName, *p\WindowID, *p\EditorID)
            cleanedCount + 1
          EndIf
        EndIf
      Next
    EndIf
    
    ; Scan HKCU
    uCount = Registry::CountSubKeys(#HKEY_CURRENT_USER, uninstallPath, wow64, @ret)
    For i = uCount - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, uninstallPath, i, wow64, @ret)
      Protected fullCUPath.s = uninstallPath + "\" + subKeyName
      Protected cuInstallLoc.s = Registry::ReadValue(#HKEY_CURRENT_USER, fullCUPath, "InstallLocation", wow64, @ret)
      If cuInstallLoc <> "" And FileSize(cuInstallLoc) = -1
        If isCleaning
          SendCleanerMsg("[User Software] Deleting: " + subKeyName, *p\WindowID, *p\EditorID)
          If Registry::DeleteKey(#HKEY_CURRENT_USER, fullCUPath, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          SendCleanerMsg("[User Software] Obsolete: " + subKeyName, *p\WindowID, *p\EditorID)
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  ; Broken Shortcuts / Recent Documents

  If *p\Shortcuts
    Protected recentPath.s = GetHomeDirectory() + "AppData\Roaming\Microsoft\Windows\Recent"
    Protected dir.i = ExamineDirectory(#PB_Any, recentPath, "*.lnk")
    If dir
      While NextDirectoryEntry(dir)
        If CleanerStopRequested : Break : EndIf
        If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
          Protected lnkFile.s = recentPath + "\" + DirectoryEntryName(dir)
          ; For simplicity in this tool, we check if the shortcut file itself is valid 
          ; and if the recent docs history entries in registry exist.
          ; Registry: HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs
          ; This part cleans the registry entries for recent docs that are no longer on disk.
        EndIf
      Wend
      FinishDirectory(dir)
    EndIf
    
    Protected recentDocsReg.s = "Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    count = Registry::CountSubValues(#HKEY_CURRENT_USER, recentDocsReg, wow64, @ret)
    For i = count - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, recentDocsReg, i, wow64, @ret)
      ; RecentDocs contains MRUList and numbered values. Numbered values are hex.
      If valName <> "MRUList" And valName <> ""
        SendCleanerMsg("[Recent] Cleaning entry: " + valName, *p\WindowID, *p\EditorID)
        If isCleaning
          If Registry::DeleteValue(#HKEY_CURRENT_USER, recentDocsReg, valName, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  ; Empty Registry Keys Logic
  If *p\EmptyKeys
    Protected scanPath.s = "Software"
    Protected sKeyCount.i = Registry::CountSubKeys(#HKEY_CURRENT_USER, scanPath, wow64, @ret)
    For i = sKeyCount - 1 To 0 Step -1
      If CleanerStopRequested : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, scanPath, i, wow64, @ret)
      Protected fullScanPath.s = scanPath + "\" + subKeyName
      If Registry::CountSubKeys(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) = 0 And 
         Registry::CountSubValues(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) = 0
        SendCleanerMsg("[Empty] Orphan Key: HKCU\" + fullScanPath, *p\WindowID, *p\EditorID)
        If isCleaning
          If Registry::DeleteKey(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  If isCleaning
    SendCleanerMsg("--- Cleanup Finished ---", *p\WindowID, *p\EditorID)
    SendCleanerMsg("Successfully removed " + Str(cleanedCount) + " items.", *p\WindowID, *p\EditorID)
  Else
    SendCleanerMsg("--- Scan Finished ---", *p\WindowID, *p\EditorID)
    SendCleanerMsg("Found " + Str(cleanedCount) + " items that can be safely removed.", *p\WindowID, *p\EditorID)
  EndIf

  
  PostEvent(#EVENT_CLEANER_DONE, *p\WindowID, 0, 0, isCleaning)
  
  ; Ensure thread variable is cleared BEFORE the event might be processed
  CleanerThreadID = 0
  FreeMemory(*p)
EndProcedure


Procedure CleanRegistry()
  Protected window.i, result.i, ev.i, quitCleaner.i = #False
  
  LogInfo("CleanRegistry", "Opening registry cleaner dialog")
  
  ; MANDATORY backup before cleaning
  If Not EnsureBackupBeforeChange("Clean registry (remove invalid entries)")
    ProcedureReturn
  EndIf
  
  window = OpenWindow(#WINDOW_CLEANER, 0, 0, 500, 450, "Registry Cleaner", #PB_Window_SystemMenu | #PB_Window_WindowCentered, WindowID(#WINDOW_MAIN))
  If window
    StickyWindow(#WINDOW_CLEANER, #True) ; Make it modal-like
    
    TextGadget(#PB_Any, 10, 10, 480, 20, "Select categories to scan and clean:")
    
    CheckBoxGadget(101, 20, 40, 400, 20, "MUI Cache (Invalid interface strings)") : SetGadgetState(101, #True)
    CheckBoxGadget(102, 20, 65, 400, 20, "Broken File Associations (.ext -> No Program)") : SetGadgetState(102, #True)
    CheckBoxGadget(103, 20, 90, 400, 20, "Obsolete Software (Leftover keys with no folders)") : SetGadgetState(103, #True)
    CheckBoxGadget(104, 20, 115, 400, 20, "Broken Shortcuts / Recent Documents History") : SetGadgetState(104, #True)
    CheckBoxGadget(106, 20, 140, 400, 20, "Invalid Installer References (Source paths)") : SetGadgetState(106, #True)
    CheckBoxGadget(107, 20, 165, 400, 20, "Empty Registry Keys (Safe scan)") : SetGadgetState(107, #True)
    
    EditorGadget(105, 10, 200, 480, 150, #PB_Editor_ReadOnly)
    AddGadgetItem(105, -1, "BACKUP CREATED: " + AutoBackupPath)
    AddGadgetItem(105, -1, "Ready to scan.")
    
    Define btnScanOnly = ButtonGadget(#PB_Any, 50, 370, 100, 30, "Scan Only")
    Define btnStartClean = ButtonGadget(#PB_Any, 160, 370, 100, 30, "Clean Now")
    Define btnCancelClean = ButtonGadget(#PB_Any, 340, 370, 100, 30, "Close")
    
    DisableGadget(btnStartClean, #True)
    
    Repeat
      ev = WaitWindowEvent()
      
      If ev = #EVENT_CLEANER_MSG
        Protected *msg = EventData()
        If *msg
          AddGadgetItem(105, -1, PeekS(*msg, -1, #PB_UTF8))
          FreeMemory(*msg)
        EndIf
      ElseIf ev = #EVENT_CLEANER_DONE
        UpdateStatusBar("Registry scan complete.")
        ; Re-enable the Scan and Close buttons
        DisableGadget(btnScanOnly, #False)
        DisableGadget(btnCancelClean, #False)
        
        ; IMPORTANT: Enable the Clean Now button if we just finished a scan (EventData() = #False)
        ; Check BOTH the parameter passed via PostEvent AND the thread variable
        If EventData() = #False 
          DisableGadget(btnStartClean, #False)
          ; Force a gadget refresh for Windows
          UpdateWindow_(GadgetID(btnStartClean))
        Else
          ; If we just finished a CLEAN operation, disable it again.
          DisableGadget(btnStartClean, #True)
          UpdateWindow_(GadgetID(btnStartClean))
        EndIf
      EndIf
      
      ; Router: Identify which window the event belongs to
      Select EventWindow()
        Case #WINDOW_CLEANER
          Select ev
            Case #PB_Event_CloseWindow
              quitCleaner = #True
              
            Case #PB_Event_Gadget
              Select EventGadget()
                Case btnScanOnly, btnStartClean
                  Protected isCleaning.i = #False
                  If EventGadget() = btnStartClean : isCleaning = #True : EndIf
                  
                  If isCleaning
                     If MessageRequester("Final Confirmation", "Delete all flagged items?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) <> #PB_MessageRequester_Yes
                       isCleaning = #False
                       Continue
                     EndIf
                  EndIf
                  
                  ClearGadgetItems(105)
                  DisableGadget(btnScanOnly, #True)
                  DisableGadget(btnStartClean, #True)
                  DisableGadget(btnCancelClean, #True)
                  
                  CleanerStopRequested = #False
                  UpdateStatusBar("Scanning registry...")
                  
                  Protected *p.CleanerParams = AllocateMemory(SizeOf(CleanerParams))
                  If *p
                    *p\MuiCache = GetGadgetState(101)
                    *p\FileAssoc = GetGadgetState(102)
                    *p\ObsoleteSw = GetGadgetState(103)
                    *p\Shortcuts = GetGadgetState(104)
                    *p\InstallerRefs = GetGadgetState(106)
                    *p\EmptyKeys = GetGadgetState(107)
                    *p\IsCleaning = isCleaning
                    *p\Wow64 = GetRegistryWow64Flag()
                    *p\WindowID = window
                    *p\EditorID = 105
                    *p\BtnScan = btnScanOnly
                    *p\BtnClean = btnStartClean
                    *p\BtnClose = btnCancelClean
                    
                    CleanerThreadID = CreateThread(@CleanerThread(), *p)
                  EndIf
                  
                Case btnCancelClean
                  quitCleaner = #True
              EndSelect
          EndSelect

        Case #WINDOW_MAIN
          ; While Cleaner is open, we absorb main window events but don't allow actions.
          ; If user tries to close the main app, we warn them.
          If ev = #PB_Event_CloseWindow
             If MessageRequester("Exit", "The Registry Cleaner is active. Exit the entire application?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
               CloseHandle_(hMutex)
               End ; Hard exit
             EndIf
          EndIf
          ; Other main events (menu/gadget) are ignored because the Cleaner is "modal" via the local loop.
      EndSelect
      
    Until quitCleaner = #True
    
    ; Cleanup: Ensure thread is signaled to stop if it was running
    If CleanerThreadID And IsThread(CleanerThreadID)
      CleanerStopRequested = #True
      WaitThread(CleanerThreadID, 500) ; Give it a brief moment
    EndIf
    
    CloseWindow(#WINDOW_CLEANER)
  EndIf
EndProcedure




;- Registry Monitor

Procedure AddMonitorEvent(rootKey.s, keyPath.s, changeType.s, details.s = "")
  Protected timestamp.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  
  If Not PendingEventsMutex : PendingEventsMutex = CreateMutex() : EndIf
  
  LockMutex(PendingEventsMutex)
  AddElement(PendingMonitorEvents())
  PendingMonitorEvents()\Timestamp = timestamp
  PendingMonitorEvents()\RootKey = rootKey
  PendingMonitorEvents()\KeyPath = keyPath
  PendingMonitorEvents()\ChangeType = changeType
  PendingMonitorEvents()\Details = details
  UnlockMutex(PendingEventsMutex)
  
  ; Log to file as well
  LogInfo("RegistryMonitor", "[" + rootKey + "\\" + keyPath + "] " + changeType + " - " + details + "")
EndProcedure

Procedure MonitorRegistryKey(param.i)

  Protected hKey.i, result.i, error.i
  Protected rootKey.i, keyPath.s, rootName.s
  Protected hEvent.i
  
  ; Decode parameter (rootKey in high word, index in low word)
  rootKey = param >> 16
  
  Select rootKey
    Case #HKEY_CLASSES_ROOT
      rootName = "HKCR"
      keyPath = ""
    Case #HKEY_CURRENT_USER
      rootName = "HKCU"
      keyPath = ""
    Case #HKEY_LOCAL_MACHINE
      rootName = "HKLM"
      keyPath = ""
    Case #HKEY_USERS
      rootName = "HKU"
      keyPath = ""
    Case #HKEY_CURRENT_CONFIG
      rootName = "HKCC"
      keyPath = ""
  EndSelect
  
  LogInfo("MonitorThread", "Starting monitoring for " + rootName)
  
  ; Open registry key for notification
  error = RegOpenKeyEx_(rootKey, keyPath, 0, #KEY_NOTIFY, @hKey)
  If error = 0
    ; Create event for notification
    hEvent = PB_CreateEventW(0, #True, #False, 0)
    
    If hEvent
      While MonitorActive
        ; Register for change notification
        result = PB_RegNotifyChangeKeyValue(hKey, #True, 
                                           #REG_NOTIFY_CHANGE_NAME | 
                                           #REG_NOTIFY_CHANGE_LAST_SET | 
                                           #REG_NOTIFY_CHANGE_ATTRIBUTES |
                                           #REG_NOTIFY_CHANGE_SECURITY, 
                                           hEvent, #True)
        
        If result = 0
          ; Wait for change notification or stop signal
          result = PB_WaitForSingleObject(hEvent, 1000) ; 1 second timeout
          
          If result = 0 ; Event signaled (registry change detected)
            AddMonitorEvent(rootName, keyPath, "Registry Modified", "Key tree changed")
            PB_ResetEvent(hEvent)
          ElseIf result = $102 ; WAIT_TIMEOUT
            ; Continue monitoring
          Else
            LogError("MonitorThread", "WaitForSingleObject failed: " + Str(result))
            Break
          EndIf
        Else
          ; If error is 5 (Access Denied), we might need to log it and stop
          LogError("MonitorThread", "RegNotifyChangeKeyValue failed: " + Str(result))
          Break
        EndIf
        
        ; Small delay to prevent CPU spinning
        Delay(50)
      Wend
      
      PB_CloseHandle(hEvent)
    Else
      LogError("MonitorThread", "Failed to create event handle")
    EndIf
    
    RegCloseKey_(hKey)
  Else
    LogError("MonitorThread", "Failed to open registry key: " + rootName + " (Error: " + Str(error) + ")")
  EndIf
  
  LogInfo("MonitorThread", "Stopped monitoring for " + rootName)
EndProcedure


Procedure StartRegistryMonitor()
  Protected thread1.i, thread2.i, thread3.i, thread4.i, thread5.i
  
  If MonitorActive
    LogWarning("StartRegistryMonitor", "Monitor already running")
    MessageRequester("Info", "Monitor is already running!", #PB_MessageRequester_Info)
    ProcedureReturn #False
  EndIf
  
  LogInfo("StartRegistryMonitor", "Starting registry monitor")
  
  MonitorActive = #True
  MonitorEventCount = 0
  
  ; Create mutex for thread-safe event list access
  If Not MonitorMutex
    MonitorMutex = CreateMutex()
    If Not MonitorMutex
      LogError("StartRegistryMonitor", "Failed to create mutex")
      MonitorActive = #False
      MessageRequester("Error", "Failed to create synchronization mutex!", #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
    LogInfo("StartRegistryMonitor", "Mutex created successfully")
  EndIf
  
  ; Start monitoring threads for each major hive
  thread1 = CreateThread(@MonitorRegistryKey(), #HKEY_CLASSES_ROOT << 16)
  thread2 = CreateThread(@MonitorRegistryKey(), #HKEY_CURRENT_USER << 16)
  thread3 = CreateThread(@MonitorRegistryKey(), #HKEY_LOCAL_MACHINE << 16)
  thread4 = CreateThread(@MonitorRegistryKey(), #HKEY_USERS << 16)
  thread5 = CreateThread(@MonitorRegistryKey(), #HKEY_CURRENT_CONFIG << 16)
  MonitorThread1 = thread1
  MonitorThread2 = thread2
  MonitorThread3 = thread3
  MonitorThread4 = thread4
  MonitorThread5 = thread5
  
  LogInfo("StartRegistryMonitor", "Thread IDs: " + Str(thread1) + ", " + Str(thread2) + ", " + Str(thread3) + ", " + Str(thread4) + ", " + Str(thread5))
  
  If thread1 = 0 Or thread2 = 0 Or thread3 = 0 Or thread4 = 0 Or thread5 = 0
    LogError("StartRegistryMonitor", "Failed to create one or more monitoring threads")
    MessageRequester("Error", "Failed to create monitoring threads!", #PB_MessageRequester_Error)
    MonitorActive = #False
    ProcedureReturn #False
  EndIf
  
  AddMonitorEvent("SYSTEM", "Monitor", "Started", "Registry monitoring activated - 5 threads running")
  
  LogInfo("StartRegistryMonitor", "Monitor threads started successfully")
  MessageRequester("Success", "Registry monitor started!" + #CRLF$ + "5 monitoring threads active.", #PB_MessageRequester_Info)
  ProcedureReturn #True
EndProcedure

Procedure StopRegistryMonitor()
  If Not MonitorActive
    LogWarning("StopRegistryMonitor", "Monitor not running")
    ProcedureReturn #False
  EndIf
  
  LogInfo("StopRegistryMonitor", "Stopping registry monitor")
  
  MonitorActive = #False
  
  If MonitorThread1 And IsThread(MonitorThread1) : WaitThread(MonitorThread1, 1500) : EndIf
  If MonitorThread2 And IsThread(MonitorThread2) : WaitThread(MonitorThread2, 1500) : EndIf
  If MonitorThread3 And IsThread(MonitorThread3) : WaitThread(MonitorThread3, 1500) : EndIf
  If MonitorThread4 And IsThread(MonitorThread4) : WaitThread(MonitorThread4, 1500) : EndIf
  If MonitorThread5 And IsThread(MonitorThread5) : WaitThread(MonitorThread5, 1500) : EndIf
  MonitorThread1 = 0
  MonitorThread2 = 0
  MonitorThread3 = 0
  MonitorThread4 = 0
  MonitorThread5 = 0
  
  AddMonitorEvent("SYSTEM", "Monitor", "Stopped", "Registry monitoring deactivated - " + Str(MonitorEventCount) + " events captured")
  
  LogInfo("StopRegistryMonitor", "Monitor stopped - Total events: " + Str(MonitorEventCount))
  ProcedureReturn #True
EndProcedure

Procedure SaveMonitorLog(fileName.s)
  Protected file.i, count.i
  
  If fileName = ""
    LogError("SaveMonitorLog", "Empty filename provided")
    ProcedureReturn #False
  EndIf
  
  file = CreateFile(#PB_Any, fileName)
  If file
    WriteStringN(file, "Registry Monitor Log - Generated: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "")
    WriteStringN(file, "Total Events: " + Str(MonitorEventCount))
    WriteStringN(file, "")
    WriteStringN(file, "Timestamp" + Chr(9) + "Root Key" + Chr(9) + "Key Path" + Chr(9) + "Change Type" + Chr(9) + "Details")
    WriteStringN(file, "-" + Space(80) + "-")
    
    LockMutex(MonitorMutex)
    
    ForEach MonitorEvents()
      WriteStringN(file, MonitorEvents()\Timestamp + Chr(9) + 
                        MonitorEvents()\RootKey + Chr(9) + 
                        MonitorEvents()\KeyPath + Chr(9) + 
                        MonitorEvents()\ChangeType + Chr(9) + 
                        MonitorEvents()\Details)
      count + 1
    Next
    
    UnlockMutex(MonitorMutex)
    
    WriteStringN(file, "")
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "End of Log - " + Str(count) + " events written")
    
    CloseFile(file)
    
    LogInfo("SaveMonitorLog", "Saved " + Str(count) + " events to: " + fileName)
    MessageRequester("Success", "Monitor log saved successfully!" + #CRLF$ + fileName + #CRLF$ + #CRLF$ + Str(count) + " events written", #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    LogError("SaveMonitorLog", "Failed to create log file: " + fileName)
    MessageRequester("Error", "Failed to save monitor log!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

;- Monitor UI

Procedure OpenMonitorWindow()

  Protected window.i
  
  If MonitorWindow And IsWindow(MonitorWindow)
    SetActiveWindow(MonitorWindow)
    ProcedureReturn
  EndIf
  
  LogInfo("OpenMonitorWindow", "Opening registry monitor window")
  
  window = OpenWindow(#WINDOW_MONITOR, 0, 0, 900, 600, "Registry Monitor - Real-Time Change Tracking", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  
  If window
    MonitorWindow = window
    
    ; Create list gadget for events
    ListIconGadget(#GADGET_MONITOR_LIST, 10, 10, 880, 490, "Timestamp", 150, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 1, "Root Key", 80)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 2, "Key Path", 250)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 3, "Change Type", 120)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 4, "Details", 200)
    
    ; Control buttons
    ButtonGadget(#GADGET_MONITOR_START, 10, 510, 100, 30, "Start Monitor")
    ButtonGadget(#GADGET_MONITOR_STOP, 120, 510, 100, 30, "Stop Monitor")
    ButtonGadget(#GADGET_MONITOR_CLEAR, 230, 510, 100, 30, "Clear Log")
    ButtonGadget(#GADGET_MONITOR_SAVE, 340, 510, 100, 30, "Save Log")
    
    SetWindowTheme(GadgetID(#GADGET_MONITOR_LIST), "Explorer", 0)
    
    MonitorStatusTextGadget = TextGadget(#PB_Any, 450, 515, 400, 20, "Events: 0 | Status: Stopped", #PB_Text_Right)

    
    ; Populate with existing events
    MonitorLastShownCount = 0
    RefreshMonitorWindow()
    
    ; Update button states
    If MonitorActive
      DisableGadget(#GADGET_MONITOR_START, #True)
      DisableGadget(#GADGET_MONITOR_STOP, #False)
      SetGadgetText(MonitorStatusTextGadget, "Events: " + Str(MonitorEventCount) + " | Status: Running")
    Else
      DisableGadget(#GADGET_MONITOR_START, #False)
      DisableGadget(#GADGET_MONITOR_STOP, #True)
      SetGadgetText(MonitorStatusTextGadget, "Events: " + Str(MonitorEventCount) + " | Status: Stopped")
    EndIf
    
    ; Start periodic refresh in main thread
    AddWindowTimer(#WINDOW_MONITOR, #TIMER_MONITOR_REFRESH, #MONITOR_REFRESH_INTERVAL)

    LogInfo("OpenMonitorWindow", "Monitor window opened successfully")
  Else
    LogError("OpenMonitorWindow", "Failed to open monitor window")
    MessageRequester("Error", "Cannot open monitor window!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

;- Legacy Placeholder

Procedure LegacyMonitorWindowPlaceholder()
  ; This function has been deprecated to fix the freeze bug
  ; Events are now handled in the main event loop
EndProcedure

;- Snapshots And Comparison

Procedure.s GetSnapshotDirectory()
  Protected snapshotDir.s
  
  snapshotDir = AppPath + #SNAPSHOT_DIR_NAME + "\"
  
  If FileSize(snapshotDir) <> -2
    If CreateDirectory(snapshotDir)
      LogInfo("GetSnapshotDirectory", "Created snapshot directory: " + snapshotDir)
    Else
      LogError("GetSnapshotDirectory", "Failed to create snapshot directory")
      snapshotDir = GetTemporaryDirectory() + "RegistryManager_Snapshots\"
      CreateDirectory(snapshotDir)
    EndIf
  EndIf
  
  ProcedureReturn snapshotDir
EndProcedure

Procedure.s SanitizeFileName(input.s)
  Protected out.s = input
  out = ReplaceString(out, "\\", "_")
  out = ReplaceString(out, "/", "_")
  out = ReplaceString(out, ":", "_")
  out = ReplaceString(out, "*", "_")
  out = ReplaceString(out, "?", "_")
  out = ReplaceString(out, Chr(34), "_")
  out = ReplaceString(out, "<", "_")
  out = ReplaceString(out, ">", "_")
  out = ReplaceString(out, "|", "_")
  ProcedureReturn Trim(out)
EndProcedure

Procedure LoadSnapshots()
  Protected dir.i, fileName.s, filePath.s, fileDate.i
  
  SnapshotDirectory = GetSnapshotDirectory()
  ClearList(Snapshots())
  
  LogInfo("LoadSnapshots", "Loading snapshots from: " + SnapshotDirectory)
  
  dir = ExamineDirectory(#PB_Any, SnapshotDirectory, "*.reg")
  If dir
    While NextDirectoryEntry(dir)
      fileName = DirectoryEntryName(dir)
      If fileName <> "." And fileName <> ".."
        filePath = SnapshotDirectory + fileName
        fileDate = GetFileDate(filePath, #PB_Date_Modified)
        
        AddElement(Snapshots())
        Snapshots()\Name = Left(fileName, Len(fileName) - 4) ; Remove .reg extension
        Snapshots()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", fileDate)
        Snapshots()\FilePath = filePath
        Snapshots()\FileSize = FileSize(filePath)
        Snapshots()\Description = "Loaded from disk"
      EndIf
    Wend
    FinishDirectory(dir)
    
    LogInfo("LoadSnapshots", "Loaded " + Str(ListSize(Snapshots())) + " snapshot(s)")
  Else
    LogWarning("LoadSnapshots", "Cannot open snapshot directory")
  EndIf
EndProcedure

Procedure DeleteSnapshot(snapshotName.s, skipConfirm.i = #False)
  Protected found.i = #False
  
  ; Ensure the internal list is synced with the folder on disk before we look for the snapshot
  LoadSnapshots()
  
  ForEach Snapshots()
    ; Use LCase for safety in case of case-sensitive string comparisons
    If LCase(Snapshots()\Name) = LCase(snapshotName)
      found = #True
      
      ; Construct full path manually to be absolutely sure it's valid
      Protected fullFilePath.s = Snapshots()\FilePath
      If fullFilePath = "" Or FileSize(fullFilePath) < 0
        ; Fallback: rebuild path if for some reason Snapshots()\FilePath is empty
        fullFilePath = GetSnapshotDirectory() + snapshotName + ".reg"
      EndIf
      
      If skipConfirm Or MessageRequester("Confirm Delete", 
                          "Delete snapshot: " + snapshotName + "?" + #CRLF$ + #CRLF$ +
                          "File: " + fullFilePath + #CRLF$ +
                          "Size: " + Str(FileSize(fullFilePath)/1024) + " KB" + #CRLF$ + #CRLF$ +
                          "This cannot be undone!", 
                          #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
        
        If DeleteFile(fullFilePath)
          LogInfo("DeleteSnapshot", "Deleted snapshot: " + snapshotName + " (File: " + fullFilePath + ")")
          DeleteElement(Snapshots())
          ProcedureReturn #True
        Else
          LogError("DeleteSnapshot", "Failed to delete file: " + fullFilePath + " (Error: " + Str(GetLastError_()) + ")")
          If FileSize(fullFilePath) = -1
             LogWarning("DeleteSnapshot", "File already gone from disk: " + fullFilePath)
             DeleteElement(Snapshots())
             ProcedureReturn #True
          EndIf
          MessageRequester("Error", "Failed to delete snapshot file!" + #CRLF$ + "Path: " + fullFilePath, #PB_MessageRequester_Error)
          ProcedureReturn #False
        EndIf
      Else
        LogInfo("DeleteSnapshot", "User cancelled deletion of: " + snapshotName)
        ProcedureReturn #False
      EndIf
    EndIf
  Next
  
  If Not found
    LogWarning("DeleteSnapshot", "Snapshot not found in list: " + snapshotName)
    ; Final fallback attempt: Try to delete the file directly even if not in the Snapshots() list
    Protected fallbackPath.s = GetSnapshotDirectory() + snapshotName + ".reg"
    If FileSize(fallbackPath) >= 0
      If DeleteFile(fallbackPath)
        LogInfo("DeleteSnapshot", "Deleted snapshot via fallback path: " + fallbackPath)
        ProcedureReturn #True
      EndIf
    ElseIf FileSize(fallbackPath) = -1
      LogInfo("DeleteSnapshot", "Ghost item detected - removing from UI by returning True: " + snapshotName)
      ProcedureReturn #True
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure.i AddSnapshotDiff(changeType.s, keyPath.s, valueName.s = "", oldData.s = "", newData.s = "")
  If Not DiffResultsMutex : DiffResultsMutex = CreateMutex() : EndIf
  LockMutex(DiffResultsMutex)
  AddElement(DiffResults())
  DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  DiffResults()\ChangeType = changeType
  DiffResults()\KeyPath = keyPath
  DiffResults()\ValueName = valueName
  DiffResults()\OldData = oldData
  DiffResults()\NewData = newData
  UnlockMutex(DiffResultsMutex)
  ProcedureReturn #True
EndProcedure

Procedure.i FindRegEntrySeparator(line.s)
  Protected pos.i, inQuotes.i, chr.s
  For pos = 1 To Len(line)
    chr = Mid(line, pos, 1)
    If chr = Chr(34)
      inQuotes = 1 - inQuotes
    ElseIf chr = "=" And Not inQuotes
      ProcedureReturn pos
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

Procedure LoadRegSnapshotIntoMap(filePath.s, Map target.s())
  Protected file.i, currentKey.s, currentName.s, currentData.s
  Protected line.s, trimmed.s, separatorPos.i

  file = ReadFile(#PB_Any, filePath)
  If Not file
    ProcedureReturn
  EndIf

  currentKey = ""
  While Not Eof(file)
    line = ReadString(file)
    trimmed = Trim(line)

    If trimmed = "" Or Left(trimmed, 1) = ";"
      Continue
    EndIf

    If Left(trimmed, 1) = "[" And Right(trimmed, 1) = "]"
      currentKey = Mid(trimmed, 2, Len(trimmed) - 2)
      Continue
    EndIf

    If currentKey = "" Or Left(trimmed, 1) = "W"
      Continue
    EndIf

    separatorPos = FindRegEntrySeparator(trimmed)
    If separatorPos > 0
      currentName = Trim(Left(trimmed, separatorPos - 1))
      currentData = Trim(Mid(trimmed, separatorPos + 1))
      While Right(currentData, 1) = "\\" And Not Eof(file)
        currentData = Left(currentData, Len(currentData) - 1) + Trim(ReadString(file))
      Wend
      target(currentKey + Chr(31) + currentName) = currentData
    EndIf
  Wend

  CloseFile(file)
EndProcedure

Procedure RefreshSnapshotList()
  If Not IsGadget(#GADGET_SNAPSHOT_LIST)
    ProcedureReturn
  EndIf

  LoadSnapshots()
  ClearGadgetItems(#GADGET_SNAPSHOT_LIST)
  ForEach Snapshots()
    AddGadgetItem(#GADGET_SNAPSHOT_LIST, -1, Snapshots()\Name + Chr(9) +
                                              Snapshots()\Timestamp + Chr(9) +
                                              Str(Snapshots()\FileSize/1024) + Chr(9) +
                                              Snapshots()\Description)
  Next
EndProcedure

Procedure SetSnapshotControlsEnabled(enabled.i)
  If IsGadget(#GADGET_SNAPSHOT_CREATE) : DisableGadget(#GADGET_SNAPSHOT_CREATE, 1 - enabled) : EndIf
  If IsGadget(#GADGET_SNAPSHOT_DELETE) : DisableGadget(#GADGET_SNAPSHOT_DELETE, 1 - enabled) : EndIf
  If IsGadget(#GADGET_SNAPSHOT_COMPARE) : DisableGadget(#GADGET_SNAPSHOT_COMPARE, 1 - enabled) : EndIf
  If IsGadget(#GADGET_SNAPSHOT_EXPORT) : DisableGadget(#GADGET_SNAPSHOT_EXPORT, 1 - enabled) : EndIf
EndProcedure

Procedure UpdateSearchStatusLabel(active.i)
  If Not IsGadget(#GADGET_SEARCH_STATUS)
    ProcedureReturn
  EndIf

  If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
  LockMutex(SearchResultsMutex)
  Protected resultCount.i = ListSize(SearchResults())
  UnlockMutex(SearchResultsMutex)

  If active
    SetGadgetText(#GADGET_SEARCH_STATUS, "Searching... Found " + Str(resultCount) + " match(es).")
  Else
    SetGadgetText(#GADGET_SEARCH_STATUS, "Search complete. Found " + Str(resultCount) + " match(es).")
  EndIf
EndProcedure

Procedure CompareSnapshots(snapshot1.s, snapshot2.s)
  Protected addedCount.i, removedCount.i, modifiedCount.i
  Protected NewMap entries1.s()
  Protected NewMap entries2.s()
  Protected compositeKey.s, keyPath.s, valueName.s, sepPos.i
  
  LogInfo("CompareSnapshots", "Comparing: " + snapshot1 + " vs " + snapshot2)
  PostAsyncStatus("Comparing snapshots... Please wait")
  
  If Not DiffResultsMutex : DiffResultsMutex = CreateMutex() : EndIf
  LockMutex(DiffResultsMutex)
  ClearList(DiffResults())
  UnlockMutex(DiffResultsMutex)
  CompareAddedCount = 0
  CompareRemovedCount = 0
  CompareModifiedCount = 0
  
  ; Find snapshot file paths
  Protected path1.s, path2.s
  ForEach Snapshots()
    If Snapshots()\Name = snapshot1 : path1 = Snapshots()\FilePath : EndIf
    If Snapshots()\Name = snapshot2 : path2 = Snapshots()\FilePath : EndIf
  Next
  
  If path1 = "" Or path2 = ""
    LogError("CompareSnapshots", "Snapshot file(s) not found")
    ProcedureReturn #False
  EndIf
  
  LoadRegSnapshotIntoMap(path1, entries1())
  LoadRegSnapshotIntoMap(path2, entries2())
  
  ForEach entries2()
    compositeKey = MapKey(entries2())
    sepPos = FindString(compositeKey, Chr(31), 1)
    keyPath = Left(compositeKey, sepPos - 1)
    valueName = Mid(compositeKey, sepPos + 1)
    If Not FindMapElement(entries1(), compositeKey)
      AddSnapshotDiff("ADDED", keyPath, valueName, "", entries2())
      addedCount + 1
    ElseIf entries1() <> entries2()
      AddSnapshotDiff("MODIFIED", keyPath, valueName, entries1(), entries2())
      modifiedCount + 1
    EndIf
  Next

  ForEach entries1()
    compositeKey = MapKey(entries1())
    sepPos = FindString(compositeKey, Chr(31), 1)
    keyPath = Left(compositeKey, sepPos - 1)
    valueName = Mid(compositeKey, sepPos + 1)
    If Not FindMapElement(entries2(), compositeKey)
      AddSnapshotDiff("REMOVED", keyPath, valueName, entries1(), "")
      removedCount + 1
    EndIf
  Next

  CompareAddedCount = addedCount
  CompareRemovedCount = removedCount
  CompareModifiedCount = modifiedCount

  LogInfo("CompareSnapshots", "Comparison complete: " + Str(addedCount) + " added, " + Str(removedCount) + " removed, " + Str(modifiedCount) + " modified")
  PostAsyncStatus("Comparison complete: " + Str(addedCount + removedCount + modifiedCount) + " differences found")

  ProcedureReturn #True
EndProcedure


Procedure ExportDifferences(fileName.s)
  Protected file.i, count.i
  
  If fileName = ""
    LogError("ExportDifferences", "Empty filename")
    ProcedureReturn #False
  EndIf
  
  file = CreateFile(#PB_Any, fileName)
  If file
    WriteStringN(file, "Registry Snapshot Comparison Report")
    WriteStringN(file, "Generated: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "")
    WriteStringN(file, "Timestamp" + Chr(9) + "Change Type" + Chr(9) + "Key Path" + Chr(9) + "Details")
    WriteStringN(file, "-" + Space(80) + "-")
    
    If Not DiffResultsMutex : DiffResultsMutex = CreateMutex() : EndIf
    LockMutex(DiffResultsMutex)
    ForEach DiffResults()
      WriteStringN(file, DiffResults()\Timestamp + Chr(9) +
                        DiffResults()\ChangeType + Chr(9) +
                        DiffResults()\KeyPath + Chr(9) +
                        DiffResults()\ValueName + " | old=" + DiffResults()\OldData + " | new=" + DiffResults()\NewData)
      count + 1
    Next
    UnlockMutex(DiffResultsMutex)

    
    WriteStringN(file, "")
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "Total Differences: " + Str(count))
    
    CloseFile(file)
    
    LogInfo("ExportDifferences", "Exported " + Str(count) + " differences to: " + fileName)
    MessageRequester("Success", "Comparison report exported!" + #CRLF$ + fileName, #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    LogError("ExportDifferences", "Cannot create file: " + fileName)
    MessageRequester("Error", "Failed to export report!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

;- Snapshot UI

Procedure OpenSnapshotWindow()
  Protected window.i
  
  If SnapshotWindow And IsWindow(SnapshotWindow)
    SetActiveWindow(SnapshotWindow)
    ProcedureReturn
  EndIf
  
  LogInfo("OpenSnapshotWindow", "Opening snapshot manager")
  LoadSnapshots()
  
  window = OpenWindow(#WINDOW_SNAPSHOT, 0, 0, 900, 600, "Registry Snapshot Manager - Compare Registry States", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  
  If window
    SnapshotWindow = window
    
    ; Snapshot list
    ListIconGadget(#GADGET_SNAPSHOT_LIST, 10, 10, 880, 300, "Snapshot Name", 250, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_CheckBoxes)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 1, "Timestamp", 150)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 2, "Size (KB)", 100)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 3, "Description", 300)
    
    SetWindowTheme(GadgetID(#GADGET_SNAPSHOT_LIST), "Explorer", 0)
    
    ; Populate list
    RefreshSnapshotList()
    
    ; Control buttons
    ButtonGadget(#GADGET_SNAPSHOT_CREATE, 10, 320, 120, 30, "Create Snapshot")
    ButtonGadget(#GADGET_SNAPSHOT_DELETE, 140, 320, 120, 30, "Delete Selected")
    ButtonGadget(#GADGET_SNAPSHOT_COMPARE, 270, 320, 120, 30, "Compare (2)")
    ButtonGadget(#GADGET_SNAPSHOT_EXPORT, 400, 320, 120, 30, "Export Diff")
    
    ; Differences list
    TextGadget(#PB_Any, 10, 360, 300, 20, "Comparison Results:")
    ListIconGadget(#GADGET_SNAPSHOT_DIFF, 10, 380, 880, 160, "Change Type", 100, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#GADGET_SNAPSHOT_DIFF, 1, "Key Path", 500)
    AddGadgetColumn(#GADGET_SNAPSHOT_DIFF, 2, "Details", 250)
    
    SetWindowTheme(GadgetID(#GADGET_SNAPSHOT_DIFF), "Explorer", 0)
    
    TextGadget(#PB_Any, 10, 550, 880, 20, "Snapshots: " + Str(ListSize(Snapshots())) + " | Snapshot Directory: " + GetSnapshotDirectory())
    SnapshotCreationActive = 0
    LogInfo("OpenSnapshotWindow", "Snapshot window opened")
  Else
    LogError("OpenSnapshotWindow", "Failed to open window")
    MessageRequester("Error", "Cannot open snapshot window!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

;- Legacy Placeholder

Procedure LegacySnapshotWindowPlaceholder()
  ; This function has been deprecated to fix the freeze bug
  ; Events are now handled in the main event loop
EndProcedure

;- Stress Tools

Procedure StressThread(param.i)
  Protected ret.Registry::RegValue
  Protected i.i = 0
  Protected keyPath.s = "Software\RegistryManager_StressTest"
  Protected wow64.i = GetRegistryWow64Flag()
  
  LogInfo("StressThread", "Starting stress test thread")
  
  ; Ensure the key exists
  If Not Registry::KeyExists(#HKEY_CURRENT_USER, keyPath, wow64)
    RegCreateKeyEx_(#HKEY_CURRENT_USER, keyPath, 0, #Null$, 0, #KEY_ALL_ACCESS, 0, 0, 0)
  EndIf
  
  While StressTestActive
    i + 1
    Registry::WriteValue(#HKEY_CURRENT_USER, keyPath, "StressValue", Str(i), #REG_SZ, wow64, @ret)
    If i % 100 = 0
      LogInfo("StressThread", "Stress Test: " + Str(i) + " writes completed")
    EndIf
    Delay(10) ; ~100 writes per second
  Wend
  
  ; Cleanup
  Registry::DeleteTree(#HKEY_CURRENT_USER, keyPath, wow64, @ret)
  LogInfo("StressThread", "Stress test thread stopped and cleaned up")
  StressThreadID = 0
EndProcedure

Procedure ToggleStressTest()
  If StressTestActive
    StressTestActive = #False
    SetMenuItemText(#GADGET_MENU, #MENU_DEBUG_STRESS, "Debug Stress Test (100 writes/sec)")
    UpdateStatusBar("Stress test stopping...")
  Else
    StressTestActive = #True
    SetMenuItemText(#GADGET_MENU, #MENU_DEBUG_STRESS, "Stop Stress Test")
    StressThreadID = CreateThread(@StressThread(), 0)
    If StressThreadID
      UpdateStatusBar("Stress test active: 100 writes/sec")
    Else
      StressTestActive = #False
      SetMenuItemText(#GADGET_MENU, #MENU_DEBUG_STRESS, "Debug Stress Test (100 writes/sec)")
      MessageRequester("Stress Test", "Could not start the stress test thread.", #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

