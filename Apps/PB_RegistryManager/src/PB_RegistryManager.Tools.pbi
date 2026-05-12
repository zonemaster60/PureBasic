; Cleaner, monitor, snapshots, stress tools

;- Registry Cleaner

Procedure SendCleanerMsg(msg.s, windowID.i, editorID.i)
  If editorID And IsGadget(editorID)
    AddGadgetItem(editorID, -1, msg)
    SetGadgetState(editorID, CountGadgetItems(editorID) - 1)
    UpdateWindow_(GadgetID(editorID))
  EndIf
  LogInfo("RegistryCleaner", msg)
EndProcedure

Procedure.i ProcessCleanerUi(windowID.i, editorID.i, btnCancel.i)
  Protected ev.i

  While WindowEvent()
    ev = Event()

    Select EventWindow()
      Case #WINDOW_CLEANER
        Select ev
          Case #PB_Event_CloseWindow
            CleanerStopRequested = #True

          Case #PB_Event_Gadget
            If EventGadget() = btnCancel And Not CleanerStopRequested
              CleanerStopRequested = #True
              DisableGadget(btnCancel, #True)
              UpdateStatusBar("Stopping registry scan...")
              If editorID And IsGadget(editorID)
                AddGadgetItem(editorID, -1, "Stop requested. Waiting for current section to finish...")
                SetGadgetState(editorID, CountGadgetItems(editorID) - 1)
                UpdateWindow_(GadgetID(editorID))
              EndIf
            EndIf
        EndSelect

      Case #WINDOW_MAIN
        If ev = #PB_Event_CloseWindow
          MessageRequester("Exit", "The Registry Cleaner is active. Close the cleaner first.", #PB_MessageRequester_Info)
        EndIf
    EndSelect
  Wend

  ProcedureReturn CleanerStopRequested
EndProcedure

Procedure.s ReadUninstallLocation(topKey.i, keyPath.s, wow64.i)
  Protected samDesired.i = #KEY_READ
  Protected hKey.i = 0
  Protected valueType.l = 0
  Protected dataSize.l = 0
  Protected *buffer = 0
  Protected result.s = ""

  If wow64
    samDesired | #KEY_WOW64_32KEY
  Else
    samDesired | #KEY_WOW64_64KEY
  EndIf

  If RegOpenKeyEx_(topKey, keyPath, 0, samDesired, @hKey) <> 0 Or hKey = 0
    ProcedureReturn ""
  EndIf

  If RegQueryValueEx_(hKey, "InstallLocation", 0, @valueType, 0, @dataSize) = 0
    If (valueType = #REG_SZ Or valueType = #REG_EXPAND_SZ) And dataSize >= 0
      *buffer = AllocateMemory(dataSize + SizeOf(Character))
      If *buffer
        FillMemory(*buffer, dataSize + SizeOf(Character), 0)
        If RegQueryValueEx_(hKey, "InstallLocation", 0, @valueType, *buffer, @dataSize) = 0
          If valueType = #REG_EXPAND_SZ
            Protected expandedChars.l = ExpandEnvironmentStrings_(*buffer, 0, 0)
            If expandedChars > 0
              Protected *expanded = AllocateMemory(expandedChars * SizeOf(Character))
              If *expanded
                If ExpandEnvironmentStrings_(*buffer, *expanded, expandedChars)
                  result = PeekS(*expanded)
                EndIf
                FreeMemory(*expanded)
              EndIf
            EndIf
          Else
            result = PeekS(*buffer)
          EndIf
        EndIf
        FreeMemory(*buffer)
      EndIf
    EndIf
  EndIf

  RegCloseKey_(hKey)
  ProcedureReturn result
EndProcedure

Procedure RunCleanerScan(*p.CleanerParams)
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected windowID.i = *p\WindowID
  Protected editorID.i = *p\EditorID
  Protected btnCancel.i = *p\BtnClose
  Protected muiCache.i = *p\MuiCache
  Protected installerRefs.i = *p\InstallerRefs
  Protected fileAssoc.i = *p\FileAssoc
  Protected obsoleteSw.i = *p\ObsoleteSw
  Protected shortcuts.i = *p\Shortcuts
  Protected emptyKeys.i = *p\EmptyKeys
  Protected wow64.i = *p\Wow64
  Protected isCleaning.i = *p\IsCleaning
  Protected ret.Registry::RegValue
  Protected i.i, count.i, valName.s, subKeyName.s, cleanedCount.i = 0

  If Not IsWindow(windowID)
    ProcedureReturn
  EndIf
  
  SendCleanerMsg("--- Starting Registry Scan ---", windowID, editorID)
  ProcessCleanerUi(windowID, editorID, btnCancel)
  
  If Not CleanerStopRequested And muiCache
    SendCleanerMsg("Scanning MUI Cache...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected muiPath.s = "Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    count = Registry::CountSubValues(#HKEY_CURRENT_USER, muiPath, wow64, @ret)
    For i = count - 1 To 0 Step -1
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, muiPath, i, wow64, @ret)

      If valName <> "" And FindString(valName, ":\", 1)
        Protected filePath.s = valName
        If Left(filePath, 1) = "@" : filePath = Mid(filePath, 2) : EndIf
        If FindString(filePath, ",", 1) : filePath = StringField(filePath, 1, ",") : EndIf
        If FileSize(filePath) = -1
          If isCleaning
            SendCleanerMsg("[MUI] Deleting: " + valName, windowID, editorID)
            If Registry::DeleteValue(#HKEY_CURRENT_USER, muiPath, valName, wow64, @ret) : cleanedCount + 1 : EndIf
          Else
            SendCleanerMsg("[MUI] Broken Link: " + valName, windowID, editorID)
            cleanedCount + 1
          EndIf
        EndIf
      EndIf
    Next
  EndIf

  If Not CleanerStopRequested And installerRefs
    SendCleanerMsg("Scanning installer references...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected installPath.s = "Software\Microsoft\Windows\CurrentVersion\Installer\Folders"
    count = Registry::CountSubValues(#HKEY_CURRENT_USER, installPath, wow64, @ret)
    For i = count - 1 To 0 Step -1
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, installPath, i, wow64, @ret)
      If valName <> "" And FileSize(valName) = -1
        If isCleaning
          SendCleanerMsg("[Installer] Deleting: " + valName, windowID, editorID)
          If Registry::DeleteValue(#HKEY_CURRENT_USER, installPath, valName, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          SendCleanerMsg("[Installer] Missing Dir: " + valName, windowID, editorID)
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  If Not CleanerStopRequested And fileAssoc
    SendCleanerMsg("Scanning file associations...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected classesPath.s = "Software\Classes"
    Protected assocCount.i = Registry::CountSubKeys(#HKEY_CURRENT_USER, classesPath, wow64, @ret)
    For i = assocCount - 1 To 0 Step -1
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, classesPath, i, wow64, @ret)
      If Left(subKeyName, 1) = "."
        Protected progID.s = Registry::ReadValue(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, "", wow64, @ret)
        If progID <> ""
          ; Check if ProgID exists in HKCU or HKCR
          If Registry::KeyExists(#HKEY_CURRENT_USER, "Software\Classes\" + progID, wow64) = #False And
             Registry::KeyExists(#HKEY_CLASSES_ROOT, progID, wow64) = #False
            
            If isCleaning
              SendCleanerMsg("[Assoc] Deleting .ext: " + subKeyName, windowID, editorID)
              If Registry::DeleteKey(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, wow64, @ret) : cleanedCount + 1 : EndIf
            Else
              SendCleanerMsg("[Assoc] Broken .ext (" + subKeyName + ") -> " + progID, windowID, editorID)
              cleanedCount + 1
            EndIf
          EndIf
        EndIf
      EndIf
    Next
  EndIf
  
  If Not CleanerStopRequested And obsoleteSw
    SendCleanerMsg("Scanning uninstall entries...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected uninstallPath.s = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    Protected uCount.i
    
    ; Scan HKLM (64-bit/Standard)
    uCount = Registry::CountSubKeys(#HKEY_LOCAL_MACHINE, uninstallPath, wow64, @ret)
    For i = uCount - 1 To 0 Step -1
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_LOCAL_MACHINE, uninstallPath, i, wow64, @ret)
      Protected fullUPath.s = uninstallPath + "\" + subKeyName
      Protected installLoc.s = ReadUninstallLocation(#HKEY_LOCAL_MACHINE, fullUPath, wow64)
      If installLoc <> "" And FileSize(installLoc) = -1
        If isCleaning
          SendCleanerMsg("[Software] Deleting: " + subKeyName, windowID, editorID)
          If Registry::DeleteKey(#HKEY_LOCAL_MACHINE, fullUPath, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          SendCleanerMsg("[Software] Obsolete: " + subKeyName, windowID, editorID)
          cleanedCount + 1
        EndIf
      EndIf
    Next

    ; Scan HKLM (WOW6432Node if on 64-bit)
    If Not CleanerStopRequested And wow64
      Protected wowPath.s = "Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
      uCount = Registry::CountSubKeys(#HKEY_LOCAL_MACHINE, wowPath, wow64, @ret)
      For i = uCount - 1 To 0 Step -1
        If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
        subKeyName = Registry::ListSubKey(#HKEY_LOCAL_MACHINE, wowPath, i, wow64, @ret)
        Protected fullWPath.s = wowPath + "\" + subKeyName
        Protected wowInstallLoc.s = ReadUninstallLocation(#HKEY_LOCAL_MACHINE, fullWPath, wow64)
        If wowInstallLoc <> "" And FileSize(wowInstallLoc) = -1
          If isCleaning
            SendCleanerMsg("[Software32] Deleting: " + subKeyName, windowID, editorID)
            If Registry::DeleteKey(#HKEY_LOCAL_MACHINE, fullWPath, wow64, @ret) : cleanedCount + 1 : EndIf
          Else
            SendCleanerMsg("[Software32] Obsolete: " + subKeyName, windowID, editorID)
            cleanedCount + 1
          EndIf
        EndIf
      Next
    EndIf
    
    ; Scan HKCU
    If Not CleanerStopRequested
      uCount = Registry::CountSubKeys(#HKEY_CURRENT_USER, uninstallPath, wow64, @ret)
      For i = uCount - 1 To 0 Step -1
        If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
        subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, uninstallPath, i, wow64, @ret)
        Protected fullCUPath.s = uninstallPath + "\" + subKeyName
        Protected cuInstallLoc.s = ReadUninstallLocation(#HKEY_CURRENT_USER, fullCUPath, wow64)
        If cuInstallLoc <> "" And FileSize(cuInstallLoc) = -1
          If isCleaning
            SendCleanerMsg("[User Software] Deleting: " + subKeyName, windowID, editorID)
            If Registry::DeleteKey(#HKEY_CURRENT_USER, fullCUPath, wow64, @ret) : cleanedCount + 1 : EndIf
          Else
            SendCleanerMsg("[User Software] Obsolete: " + subKeyName, windowID, editorID)
            cleanedCount + 1
          EndIf
        EndIf
      Next
    EndIf
  EndIf

  If Not CleanerStopRequested And shortcuts
    SendCleanerMsg("Scanning recent documents...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected recentPath.s = GetHomeDirectory() + "AppData\Roaming\Microsoft\Windows\Recent"
    Protected dir.i = ExamineDirectory(#PB_Any, recentPath, "*.lnk")
    If dir
      While NextDirectoryEntry(dir)
        If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
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
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      valName = Registry::ListSubValue(#HKEY_CURRENT_USER, recentDocsReg, i, wow64, @ret)
      ; RecentDocs contains MRUList and numbered values. Numbered values are hex.
      If valName <> "MRUList" And valName <> ""
        SendCleanerMsg("[Recent] Cleaning entry: " + valName, windowID, editorID)
        If isCleaning
          If Registry::DeleteValue(#HKEY_CURRENT_USER, recentDocsReg, valName, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  If Not CleanerStopRequested And emptyKeys
    SendCleanerMsg("Scanning empty keys...", windowID, editorID)
    ProcessCleanerUi(windowID, editorID, btnCancel)
    Protected scanPath.s = "Software"
    Protected sKeyCount.i = Registry::CountSubKeys(#HKEY_CURRENT_USER, scanPath, wow64, @ret)
    For i = sKeyCount - 1 To 0 Step -1
      If ProcessCleanerUi(windowID, editorID, btnCancel) : Break : EndIf
      subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, scanPath, i, wow64, @ret)
      Protected fullScanPath.s = scanPath + "\" + subKeyName
      If Registry::CountSubKeys(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) = 0 And 
         Registry::CountSubValues(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) = 0
        SendCleanerMsg("[Empty] Orphan Key: HKCU\" + fullScanPath, windowID, editorID)
        If isCleaning
          If Registry::DeleteKey(#HKEY_CURRENT_USER, fullScanPath, wow64, @ret) : cleanedCount + 1 : EndIf
        Else
          cleanedCount + 1
        EndIf
      EndIf
    Next
  EndIf

  If CleanerStopRequested
    SendCleanerMsg("--- Scan Stopped ---", windowID, editorID)
  ElseIf isCleaning
    SendCleanerMsg("--- Cleanup Finished ---", windowID, editorID)
    SendCleanerMsg("Successfully removed " + Str(cleanedCount) + " items.", windowID, editorID)
  Else
    SendCleanerMsg("--- Scan Finished ---", windowID, editorID)
    SendCleanerMsg("Found " + Str(cleanedCount) + " items that can be safely removed.", windowID, editorID)
  EndIf
EndProcedure


Procedure CleanRegistry()
  Protected window.i, result.i, ev.i, quitCleaner.i = #False
  
  LogInfo("CleanRegistry", "Opening registry cleaner dialog")
  
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
    If AutoBackupPath <> ""
      AddGadgetItem(105, -1, "Last backup: " + AutoBackupPath)
    EndIf
    AddGadgetItem(105, -1, "Ready to scan. A safety backup will be created before cleaning.")
    
    Define btnScanOnly = ButtonGadget(#PB_Any, 50, 370, 100, 30, "Scan Only")
    Define btnStartClean = ButtonGadget(#PB_Any, 160, 370, 100, 30, "Clean Now")
    Define btnCancelClean = ButtonGadget(#PB_Any, 340, 370, 100, 30, "Close")
    
    DisableGadget(btnStartClean, #True)
    
    Repeat
      ev = WaitWindowEvent()
      
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

                      If Not EnsureBackupBeforeChange("Clean registry (remove invalid entries)")
                        Continue
                      EndIf
                  EndIf
                  
                  ClearGadgetItems(105)
                  DisableGadget(btnScanOnly, #True)
                  DisableGadget(btnStartClean, #True)
                  DisableGadget(btnCancelClean, #False)
                  SetGadgetText(btnCancelClean, "Stop")

                  CleanerStopRequested = #False
                  UpdateStatusBar("Scanning registry...")
                  AddGadgetItem(105, -1, "Starting scan...")
                  
                  Protected scanParams.CleanerParams
                  scanParams\MuiCache = GetGadgetState(101)
                  scanParams\FileAssoc = GetGadgetState(102)
                  scanParams\ObsoleteSw = GetGadgetState(103)
                  scanParams\Shortcuts = GetGadgetState(104)
                  scanParams\InstallerRefs = GetGadgetState(106)
                  scanParams\EmptyKeys = GetGadgetState(107)
                  scanParams\IsCleaning = isCleaning
                  scanParams\Wow64 = GetRegistryWow64Flag()
                  scanParams\WindowID = #WINDOW_CLEANER
                  scanParams\EditorID = 105
                  scanParams\BtnClose = btnCancelClean

                  RunCleanerScan(@scanParams)

                  DisableGadget(btnScanOnly, #False)
                  DisableGadget(btnCancelClean, #False)
                  SetGadgetText(btnCancelClean, "Close")
                  If CleanerStopRequested Or isCleaning
                    DisableGadget(btnStartClean, #True)
                  Else
                    DisableGadget(btnStartClean, #False)
                  EndIf
                  UpdateStatusBar("Registry scan complete.")
                  
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
    
    CloseWindow(#WINDOW_CLEANER)
  EndIf
EndProcedure




;- Disk Cleaner

Structure DiskCleanerRule
  Id.s
  Label.s
  BasePath.s
  Pattern.s
  Recursive.i
  MinAgeDays.i
  AggressiveOnly.i
EndStructure

Structure DiskCleanerResult
  RuleLabel.s
  FilePath.s
  Size.q
  IsDirectory.i
  Selected.i
EndStructure

Global NewList DiskCleanerRules.DiskCleanerRule()
Global NewList DiskCleanerResults.DiskCleanerResult()

Procedure.s FormatBytes(size.q)
  Protected value.d = size
  Protected suffix.s = " B"

  If value >= 1024
    value / 1024
    suffix = " KB"
  EndIf
  If value >= 1024
    value / 1024
    suffix = " MB"
  EndIf
  If value >= 1024
    value / 1024
    suffix = " GB"
  EndIf

  If suffix = " B"
    ProcedureReturn Str(size) + suffix
  EndIf

  ProcedureReturn StrD(value, 2) + suffix
EndProcedure

Procedure.q GetDirectorySize(path.s)
  Protected total.q = 0
  Protected dir.i = ExamineDirectory(#PB_Any, path, "*")
  Protected childPath.s

  If dir
    While NextDirectoryEntry(dir)
      If DirectoryEntryName(dir) = "." Or DirectoryEntryName(dir) = ".."
        Continue
      EndIf

      childPath = path
      If Right(childPath, 1) <> "\"
        childPath + "\"
      EndIf
      childPath + DirectoryEntryName(dir)

      If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
        total + DirectoryEntrySize(dir)
      ElseIf DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
        total + GetDirectorySize(childPath)
      EndIf
    Wend
    FinishDirectory(dir)
  EndIf

  ProcedureReturn total
EndProcedure

Procedure.q GetPathAgeDays(path.s)
  Protected modified.i = GetFileDate(path, #PB_Date_Modified)
  If modified <= 0
    ProcedureReturn 999999
  EndIf
  ProcedureReturn (Date() - modified) / 86400
EndProcedure

Procedure AddDiskCleanerRule(id.s, label.s, basePath.s, pattern.s = "*", recursive.i = #True, minAgeDays.i = 0, aggressiveOnly.i = #False)
  If basePath = ""
    ProcedureReturn
  EndIf

  AddElement(DiskCleanerRules())
  DiskCleanerRules()\Id = id
  DiskCleanerRules()\Label = label
  DiskCleanerRules()\BasePath = basePath
  DiskCleanerRules()\Pattern = pattern
  DiskCleanerRules()\Recursive = recursive
  DiskCleanerRules()\MinAgeDays = minAgeDays
  DiskCleanerRules()\AggressiveOnly = aggressiveOnly
EndProcedure

Procedure AddDiskCleanerProfileRules(idPrefix.s, labelPrefix.s, profilesPath.s, relativePath.s, pattern.s = "*", recursive.i = #True, minAgeDays.i = 1, aggressiveOnly.i = #False)
  Protected dir.i
  Protected profileName.s
  Protected targetPath.s

  If FileSize(profilesPath) <> -2
    ProcedureReturn
  EndIf

  dir = ExamineDirectory(#PB_Any, profilesPath, "*")
  If dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    If DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
      profileName = DirectoryEntryName(dir)
      If profileName <> "." And profileName <> ".."
        targetPath = profilesPath
        If Right(targetPath, 1) <> "\"
          targetPath + "\"
        EndIf
        targetPath + profileName
        If relativePath <> ""
          targetPath + "\" + relativePath
        EndIf
        AddDiskCleanerRule(idPrefix + "-" + profileName, labelPrefix + " (" + profileName + ")", targetPath, pattern, recursive, minAgeDays, aggressiveOnly)
      EndIf
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure AddDiskCleanerResult(ruleLabel.s, filePath.s, size.q, isDirectory.i)
  AddElement(DiskCleanerResults())
  DiskCleanerResults()\RuleLabel = ruleLabel
  DiskCleanerResults()\FilePath = filePath
  DiskCleanerResults()\Size = size
  DiskCleanerResults()\IsDirectory = isDirectory
  DiskCleanerResults()\Selected = #True
EndProcedure

Procedure ScanDiskCleanerPath(ruleLabel.s, basePath.s, pattern.s, recursive.i, minAgeDays.i)
  Protected dir.i = ExamineDirectory(#PB_Any, basePath, pattern)
  Protected entryPath.s
  Protected ageDays.q

  If FileSize(basePath) <> -2 Or dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    If DirectoryEntryName(dir) = "." Or DirectoryEntryName(dir) = ".."
      Continue
    EndIf

    entryPath = basePath
    If Right(entryPath, 1) <> "\"
      entryPath + "\"
    EndIf
    entryPath + DirectoryEntryName(dir)

    If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
      ageDays = GetPathAgeDays(entryPath)
      If ageDays >= minAgeDays
        AddDiskCleanerResult(ruleLabel, entryPath, DirectoryEntrySize(dir), #False)
      EndIf
    ElseIf recursive And DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
      ScanDiskCleanerPath(ruleLabel, entryPath, pattern, recursive, minAgeDays)
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure InitDiskCleanerRules(profileMode.i)
  Protected localAppData.s = GetEnvironmentVariable("LOCALAPPDATA")
  Protected roamingAppData.s = GetEnvironmentVariable("APPDATA")
  Protected windowsDir.s = GetEnvironmentVariable("WINDIR")
  Protected programData.s = GetEnvironmentVariable("PROGRAMDATA")
  Protected userTemp.s = GetTemporaryDirectory()
  Protected userHome.s = GetHomeDirectory()
  Protected programFilesX86.s = GetEnvironmentVariable("ProgramFiles(x86)")

  ClearList(DiskCleanerRules())

  AddDiskCleanerRule("win-temp", "Windows Temp", windowsDir + "\Temp", "*", #True, 1)
  AddDiskCleanerRule("user-temp", "User Temp", userTemp, "*", #True, 1)
  AddDiskCleanerRule("crash-dumps", "Crash Dumps", localAppData + "\CrashDumps", "*.dmp", #True, 1)
  AddDiskCleanerRule("wer-user", "Windows Error Reports (User)", localAppData + "\Microsoft\Windows\WER", "*", #True, 1)
  AddDiskCleanerRule("wer-system", "Windows Error Reports (System)", programData + "\Microsoft\Windows\WER", "*", #True, 1)
  AddDiskCleanerProfileRules("chrome-cache", "Google Chrome Cache", localAppData + "\Google\Chrome\User Data", "Cache", "*", #True, 1)
  AddDiskCleanerProfileRules("chrome-code", "Google Chrome Code Cache", localAppData + "\Google\Chrome\User Data", "Code Cache", "*", #True, 1)
  AddDiskCleanerProfileRules("edge-cache", "Microsoft Edge Cache", localAppData + "\Microsoft\Edge\User Data", "Cache", "*", #True, 1)
  AddDiskCleanerProfileRules("edge-code", "Microsoft Edge Code Cache", localAppData + "\Microsoft\Edge\User Data", "Code Cache", "*", #True, 1)
  AddDiskCleanerProfileRules("firefox-cache", "Firefox Cache", localAppData + "\Mozilla\Firefox\Profiles", "cache2\entries", "*", #True, 1)
  AddDiskCleanerRule("discord-cache", "Discord Cache", roamingAppData + "\discord\Cache", "*", #True, 1)
  AddDiskCleanerRule("discord-code", "Discord Code Cache", roamingAppData + "\discord\Code Cache", "*", #True, 1)
  AddDiskCleanerRule("teams-logs", "Microsoft Teams Logs", roamingAppData + "\Microsoft\Teams", "*.log", #True, 3)
  AddDiskCleanerRule("steam-logs", "Steam Logs", programFilesX86 + "\Steam\logs", "*.log", #True, 7)
  AddDiskCleanerRule("steam-dumps", "Steam Dumps", programFilesX86 + "\Steam\dumps", "*.dmp", #True, 1)
  AddDiskCleanerRule("pb-logs", "PureBasic Logs", userHome + "Documents\PureBasic", "*.log", #True, 7)
  AddDiskCleanerRule("pb-dumps", "PureBasic Dumps", userHome + "Documents\PureBasic", "*.dmp", #True, 1)
  AddDiskCleanerRule("adobe-logs", "Adobe Logs", localAppData + "\Adobe", "*.log", #True, 7)
  AddDiskCleanerRule("7zip-temp", "7-Zip Temp", userTemp, "7z*.tmp", #True, 1)
  AddDiskCleanerRule("office-cache", "Microsoft Office Cache", localAppData + "\Microsoft\Office\16.0\OfficeFileCache", "*", #True, 7)
  AddDiskCleanerRule("powershell-history", "PowerShell Transcripts", userHome + "Documents\PowerShell_transcript", "*.txt", #True, 30)

  If profileMode
    AddDiskCleanerProfileRules("chrome-gpu", "Google Chrome GPU Cache", localAppData + "\Google\Chrome\User Data", "GPUCache", "*", #True, 1, #True)
    AddDiskCleanerProfileRules("edge-gpu", "Microsoft Edge GPU Cache", localAppData + "\Microsoft\Edge\User Data", "GPUCache", "*", #True, 1, #True)
    AddDiskCleanerRule("nvidia-dx", "NVIDIA DX Cache", localAppData + "\NVIDIA\DXCache", "*", #True, 2, #True)
    AddDiskCleanerRule("nvidia-gl", "NVIDIA GL Cache", localAppData + "\NVIDIA\GLCache", "*", #True, 2, #True)
    AddDiskCleanerRule("unity-logs", "Unity Logs", localAppData + "\Unity", "*.log", #True, 7, #True)
    AddDiskCleanerRule("obs-logs", "OBS Logs", roamingAppData + "\obs-studio\logs", "*.txt", #True, 7, #True)
    AddDiskCleanerRule("obs-crashes", "OBS Crashes", roamingAppData + "\obs-studio\crashes", "*", #True, 1, #True)
    AddDiskCleanerRule("blender-temp", "Blender Temp", localAppData + "\Temp\Blender", "*", #True, 1, #True)
    AddDiskCleanerRule("vs-code-logs", "VS Code Logs", roamingAppData + "\Code\logs", "*", #True, 3, #True)
    AddDiskCleanerRule("vlc-art", "VLC Art Cache", roamingAppData + "\vlc\art", "*", #True, 7, #True)
    AddDiskCleanerRule("epic-logs", "Epic Games Launcher Logs", localAppData + "\EpicGamesLauncher\Saved\Logs", "*.log", #True, 7, #True)
    AddDiskCleanerRule("epic-webcache", "Epic Games Web Cache", localAppData + "\EpicGamesLauncher\Saved\webcache", "*", #True, 3, #True)
    AddDiskCleanerRule("battle-net-cache", "Battle.net Cache", programData + "\Battle.net\Cache", "*", #True, 3, #True)
    AddDiskCleanerRule("java-cache", "Java Deployment Cache", localAppData + "Low\Sun\Java\Deployment\cache", "*", #True, 7, #True)
  EndIf
EndProcedure

Procedure RefreshDiskCleanerRuleList(ruleList.i, profileMode.i)
  If Not IsGadget(ruleList)
    ProcedureReturn
  EndIf

  InitDiskCleanerRules(profileMode)
  ClearGadgetItems(ruleList)
  ForEach DiskCleanerRules()
    AddGadgetItem(ruleList, -1, DiskCleanerRules()\Label + Chr(10) + DiskCleanerRules()\BasePath, 0, #PB_ListIcon_Checked)
  Next
EndProcedure

Procedure RefreshDiskCleanerResults(listGadget.i, statusGadget.i)
  Protected totalCount.i = 0
  Protected totalSize.q = 0
  Protected itemState.i

  ClearGadgetItems(listGadget)
  ForEach DiskCleanerResults()
    If DiskCleanerResults()\Selected
      totalCount + 1
      totalSize + DiskCleanerResults()\Size
      itemState = #PB_ListIcon_Checked
    Else
      itemState = 0
    EndIf
    AddGadgetItem(listGadget, -1, DiskCleanerResults()\RuleLabel + Chr(10) + DiskCleanerResults()\FilePath + Chr(10) + FormatBytes(DiskCleanerResults()\Size), 0, itemState)
  Next

  SetGadgetText(statusGadget, Str(totalCount) + " item(s), " + FormatBytes(totalSize) + " recoverable")
EndProcedure

Procedure ScanDiskCleaner(listGadget.i, statusGadget.i, ruleList.i, profileMode.i)
  Protected categoryIndex.i = 0

  ClearList(DiskCleanerResults())
  InitDiskCleanerRules(profileMode)

  ForEach DiskCleanerRules()
    If GetGadgetItemState(ruleList, categoryIndex) & #PB_ListIcon_Checked
      ScanDiskCleanerPath(DiskCleanerRules()\Label, DiskCleanerRules()\BasePath, DiskCleanerRules()\Pattern, DiskCleanerRules()\Recursive, DiskCleanerRules()\MinAgeDays)
    EndIf
    categoryIndex + 1
  Next

  RefreshDiskCleanerResults(listGadget, statusGadget)
EndProcedure

Procedure SyncDiskCleanerSelection(listGadget.i)
  Protected itemIndex.i = 0

  ForEach DiskCleanerResults()
    DiskCleanerResults()\Selected = Bool(GetGadgetItemState(listGadget, itemIndex) & #PB_ListIcon_Checked)
    itemIndex + 1
  Next
EndProcedure

Procedure SetDiskCleanerSelection(listGadget.i, mode.i)
  Protected itemIndex.i = 0
  Protected currentChecked.i

  ForEach DiskCleanerResults()
    Select mode
      Case 0
        DiskCleanerResults()\Selected = #False
      Case 1
        DiskCleanerResults()\Selected = #True
      Default
        currentChecked = Bool(GetGadgetItemState(listGadget, itemIndex) & #PB_ListIcon_Checked)
        DiskCleanerResults()\Selected = 1 - currentChecked
    EndSelect
    itemIndex + 1
  Next
EndProcedure

Procedure.s GetDiskCleanerCategorySummary()
  Protected summary.s = ""
  NewMap countByCategory.i()
  NewMap sizeByCategory.q()

  ForEach DiskCleanerResults()
    If DiskCleanerResults()\Selected
      countByCategory(DiskCleanerResults()\RuleLabel) + 1
      sizeByCategory(DiskCleanerResults()\RuleLabel) + DiskCleanerResults()\Size
    EndIf
  Next

  ForEach countByCategory()
    If summary <> ""
      summary + #CRLF$
    EndIf
    summary + MapKey(countByCategory()) + ": " + Str(countByCategory()) + " item(s), " + FormatBytes(sizeByCategory(MapKey(countByCategory())))
  Next

  If summary = ""
    summary = "No selected items."
  EndIf

  ProcedureReturn summary
EndProcedure

Procedure CleanDiskCleanerResults()
  Protected cleanedCount.i = 0
  Protected cleanedSize.q = 0

  ForEach DiskCleanerResults()
    If Not DiskCleanerResults()\Selected
      Continue
    EndIf

    If DiskCleanerResults()\IsDirectory
      If DeleteDirectory(DiskCleanerResults()\FilePath, "*", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
        cleanedCount + 1
        cleanedSize + DiskCleanerResults()\Size
      EndIf
    Else
      If DeleteFile(DiskCleanerResults()\FilePath, #PB_FileSystem_Force)
        cleanedCount + 1
        cleanedSize + DiskCleanerResults()\Size
      EndIf
    EndIf
  Next

  MessageRequester("Disk Cleaner", "Removed " + Str(cleanedCount) + " item(s) and freed " + FormatBytes(cleanedSize) + ".", #PB_MessageRequester_Info)
EndProcedure

Procedure OpenDiskCleaner()
  Protected window.i
  Protected ruleList.i
  Protected list.i
  Protected btnScan.i
  Protected btnClean.i
  Protected btnClose.i
  Protected btnSelectAll.i
  Protected btnSelectNone.i
  Protected btnInvert.i
  Protected btnSummary.i
  Protected optSafe.i
  Protected optAggressive.i
  Protected statusText.i
  Protected categoryIndex.i
  Protected ev.i

  If IsWindow(#WINDOW_DISK_CLEANER)
    StickyWindow(#WINDOW_DISK_CLEANER, #True)
    ProcedureReturn
  EndIf

  InitDiskCleanerRules(#False)

  window = OpenWindow(#WINDOW_DISK_CLEANER, 0, 0, 860, 620, "Disk Cleaner", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  If window = 0
    MessageRequester("Error", "Cannot open disk cleaner window!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  StickyWindow(#WINDOW_DISK_CLEANER, #True)
  TextGadget(#PB_Any, 10, 10, 820, 20, "CCleaner-style disk cleanup using explicit app rules. Review the list before deleting.")
  optSafe = OptionGadget(#PB_Any, 10, 35, 90, 20, "Safe")
  optAggressive = OptionGadget(#PB_Any, 110, 35, 110, 20, "Aggressive")
  SetGadgetState(optSafe, #True)

  ruleList = ListIconGadget(#PB_Any, 10, 65, 840, 165, "Rule", 260, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_CheckBoxes)
  AddGadgetColumn(ruleList, 1, "Path", 560)
  SetWindowTheme(GadgetID(ruleList), "Explorer", 0)
  RefreshDiskCleanerRuleList(ruleList, #False)

  list = ListIconGadget(#PB_Any, 10, 250, 840, 300, "Category", 220, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_CheckBoxes)
  AddGadgetColumn(list, 1, "Path", 500)
  AddGadgetColumn(list, 2, "Size", 100)
  SetWindowTheme(GadgetID(list), "Explorer", 0)

  statusText = TextGadget(#PB_Any, 10, 565, 550, 20, "Ready to scan.")
  btnSelectAll = ButtonGadget(#PB_Any, 10, 585, 80, 25, "All")
  btnSelectNone = ButtonGadget(#PB_Any, 100, 585, 80, 25, "None")
  btnInvert = ButtonGadget(#PB_Any, 190, 585, 80, 25, "Invert")
  btnSummary = ButtonGadget(#PB_Any, 280, 585, 90, 25, "Summary")
  btnScan = ButtonGadget(#PB_Any, 570, 555, 90, 30, "Scan")
  btnClean = ButtonGadget(#PB_Any, 670, 555, 90, 30, "Clean")
  btnClose = ButtonGadget(#PB_Any, 770, 555, 80, 30, "Close")
  DisableGadget(btnClean, #True)

  Repeat
    ev = WaitWindowEvent()

    Select ev
      Case #PB_Event_CloseWindow
        If EventWindow() = #WINDOW_DISK_CLEANER
          Break
        EndIf

      Case #PB_Event_SizeWindow
        If EventWindow() = #WINDOW_DISK_CLEANER
          ResizeGadget(ruleList, 10, 65, WindowWidth(#WINDOW_DISK_CLEANER) - 20, 165)
          ResizeGadget(list, 10, 250, WindowWidth(#WINDOW_DISK_CLEANER) - 20, WindowHeight(#WINDOW_DISK_CLEANER) - 320)
          ResizeGadget(statusText, 10, WindowHeight(#WINDOW_DISK_CLEANER) - 55, WindowWidth(#WINDOW_DISK_CLEANER) - 300, 20)
          ResizeGadget(btnSelectAll, 10, WindowHeight(#WINDOW_DISK_CLEANER) - 30, 80, 25)
          ResizeGadget(btnSelectNone, 100, WindowHeight(#WINDOW_DISK_CLEANER) - 30, 80, 25)
          ResizeGadget(btnInvert, 190, WindowHeight(#WINDOW_DISK_CLEANER) - 30, 80, 25)
          ResizeGadget(btnSummary, 280, WindowHeight(#WINDOW_DISK_CLEANER) - 30, 90, 25)
          ResizeGadget(btnScan, WindowWidth(#WINDOW_DISK_CLEANER) - 285, WindowHeight(#WINDOW_DISK_CLEANER) - 55, 90, 30)
          ResizeGadget(btnClean, WindowWidth(#WINDOW_DISK_CLEANER) - 185, WindowHeight(#WINDOW_DISK_CLEANER) - 55, 90, 30)
          ResizeGadget(btnClose, WindowWidth(#WINDOW_DISK_CLEANER) - 85, WindowHeight(#WINDOW_DISK_CLEANER) - 55, 75, 30)
        EndIf

      Case #PB_Event_Gadget
        If EventWindow() = #WINDOW_DISK_CLEANER
          Select EventGadget()
            Case btnScan
              UpdateStatusBar("Scanning disk cleaner rules...")
              ScanDiskCleaner(list, statusText, ruleList, GetGadgetState(optAggressive))
              DisableGadget(btnClean, Bool(ListSize(DiskCleanerResults()) = 0))
              UpdateStatusBar("Disk cleaner scan complete.")

            Case btnClean
              SyncDiskCleanerSelection(list)
              If ListSize(DiskCleanerResults()) = 0
                MessageRequester("Disk Cleaner", "Nothing to clean. Run a scan first.", #PB_MessageRequester_Info)
              ElseIf MessageRequester("Confirm Cleanup", "Delete all listed files?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                CleanDiskCleanerResults()
                ClearList(DiskCleanerResults())
                RefreshDiskCleanerResults(list, statusText)
                DisableGadget(btnClean, #True)
                UpdateStatusBar("Disk cleaner cleanup complete.")
              EndIf

            Case optSafe, optAggressive
              RefreshDiskCleanerRuleList(ruleList, GetGadgetState(optAggressive))
              ClearList(DiskCleanerResults())
              RefreshDiskCleanerResults(list, statusText)
              DisableGadget(btnClean, #True)

            Case btnSelectAll
              SetDiskCleanerSelection(list, 1)
              RefreshDiskCleanerResults(list, statusText)

            Case btnSelectNone
              SetDiskCleanerSelection(list, 0)
              RefreshDiskCleanerResults(list, statusText)

            Case btnInvert
              SetDiskCleanerSelection(list, 2)
              RefreshDiskCleanerResults(list, statusText)

            Case btnSummary
              SyncDiskCleanerSelection(list)
              RefreshDiskCleanerResults(list, statusText)
              MessageRequester("Disk Cleaner Summary", GetDiskCleanerCategorySummary(), #PB_MessageRequester_Info)

            Case btnClose
              Break
          EndSelect
        EndIf
    EndSelect
  ForEver

  CloseWindow(#WINDOW_DISK_CLEANER)
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
      snapshotDir = GetTemporaryDirectory() + "PB_RegistryManager_Snapshots\"
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
  Protected keyPath.s = "Software\PB_RegistryManager_StressTest"
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


; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 677
; FirstLine = 674
; Folding = -----
; EnableXP
; DPIAware
