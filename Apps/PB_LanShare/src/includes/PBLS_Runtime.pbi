; Main window creation, event loop, and app bootstrap/runtime control flow.

Procedure HandleRemoteDoubleClick()
  Protected Index.i = GetGadgetState(#GadgetRemoteList)
  Protected RelativePath$

  If Index < 0 Or Index > ArraySize(RemoteEntryPath$())
    ProcedureReturn
  EndIf

  RelativePath$ = RemoteEntryPath$(Index)
  If RemoteEntryIsDirectory(Index)
    RequestRemoteList(RelativePath$)
  Else
    StartRemoteDownload(RelativePath$)
  EndIf
EndProcedure

Procedure HandleDownloadButton()
  If SelectedRemoteItemPath() = ""
    MessageRequester(#APP_NAME, "Select a remote file first.")
    ProcedureReturn
  EndIf

  StartRemoteDownload(SelectedRemoteItemPath())
EndProcedure

Procedure OpenMainWindow()
  OpenWindow(#WindowMain, 0, 0, 980, 700, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)

  StringGadget(#GadgetSharePath, 0, 0, 0, 0, "")
  StringGadget(#GadgetDownloadPath, 0, 0, 0, 0, "")
  StringGadget(#GadgetPort, 0, 0, 0, 0, "50505", #PB_String_Numeric)
  StringGadget(#GadgetRemoteHost, 0, 0, 0, 0, "")
  ComboBoxGadget(#GadgetOverwrite, 0, 0, 0, 0)
  AddGadgetItem(#GadgetOverwrite, -1, "Keep both")
  AddGadgetItem(#GadgetOverwrite, -1, "Replace")
  AddGadgetItem(#GadgetOverwrite, -1, "Skip")
  AddGadgetItem(#GadgetOverwrite, -1, "Resume if partial")
  SetGadgetState(#GadgetOverwrite, #OverwriteKeepBoth)

  TextGadget(#GadgetShareLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetShareBrowse, 0, 0, 0, 0, "")
  TextGadget(#GadgetDownloadLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadBrowse, 0, 0, 0, 0, "")
  TextGadget(#GadgetPortLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetServerToggle, 0, 0, 0, 0, "")
  TextGadget(#GadgetRemoteHostLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetConnect, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDisconnect, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetRefresh, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetParent, 0, 0, 0, 0, "")
  TextGadget(#GadgetOverwriteLabel, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUpload, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownload, 0, 0, 0, 0, "")
  TextGadget(#GadgetRemotePathLabel, 0, 0, 0, 0, "")
  StringGadget(#GadgetRemotePath, 0, 0, 0, 0, "/", #PB_String_ReadOnly)
  ListViewGadget(#GadgetUploadQueue, 0, 0, 0, 0)
  ButtonGadget(#GadgetUploadUp, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUploadDown, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetUploadRemove, 0, 0, 0, 0, "")
  ListViewGadget(#GadgetDownloadQueue, 0, 0, 0, 0)
  ButtonGadget(#GadgetDownloadUp, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadDown, 0, 0, 0, 0, "")
  ButtonGadget(#GadgetDownloadRemove, 0, 0, 0, 0, "")
  ListIconGadget(#GadgetRemoteList, 0, 0, 0, 0, "", 10)
  ListIconGadget(#GadgetHistory, 0, 0, 0, 0, "", 10)
  EditorGadget(#GadgetLog, 0, 0, 0, 0, #PB_Editor_ReadOnly)
  HideGadget(#GadgetSharePath, #True)
  HideGadget(#GadgetDownloadPath, #True)
  HideGadget(#GadgetPort, #True)
  HideGadget(#GadgetRemoteHost, #True)
  HideGadget(#GadgetOverwrite, #True)

  TextGadget(#PB_Any, 20, 18, 300, 28, "LAN Share")
  ButtonGadget(#GadgetQuickSendFiles, 20, 58, 180, 42, "Send Files")
  ButtonGadget(#GadgetQuickSendFolder, 214, 58, 180, 42, "Send Folder")
  ButtonGadget(#GadgetScan, 408, 58, 140, 42, "Find Receivers")
  ButtonGadget(#GadgetQuickSettings, 562, 58, 110, 42, "Settings")
  ButtonGadget(#GadgetPause, 686, 58, 90, 42, "Pause")
  ButtonGadget(#GadgetCancel, 790, 58, 90, 42, "Cancel")
  ButtonGadget(#GadgetQuickExit, 894, 58, 56, 42, "Exit")

  TextGadget(#GadgetServerStatus, 20, 112, 930, 22, "Ready to receive")
  TextGadget(#GadgetLocalIPs, 20, 136, 930, 22, "")
  TextGadget(#GadgetDiscoveryLabel, 20, 170, 160, 20, "Available Receivers")
  CheckBoxGadget(#GadgetDiscoveryPeersOnly, 180, 168, 120, 20, "Peers only")
  ButtonGadget(#GadgetCopyInfo, 308, 164, 100, 28, "Copy Info")
  ListIconGadget(#GadgetDiscovery, 20, 198, 430, 140, "Device", 230, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetDiscovery, 1, "Type", 130)
  AddGadgetColumn(#GadgetDiscovery, 2, "Port", 60)

  TextGadget(#GadgetDetailsTitle, 474, 170, 160, 20, "Selected Device")
  TextGadget(#GadgetDetailsHost, 474, 198, 460, 18, "Host: -")
  TextGadget(#GadgetDetailsType, 474, 220, 460, 18, "Type: -")
  TextGadget(#GadgetDetailsPort, 474, 242, 460, 18, "Port: -")
  TextGadget(#GadgetDetailsMac, 474, 264, 460, 18, "MAC: -")
  TextGadget(#GadgetDetailsVendor, 474, 286, 460, 18, "Vendor: -")
  TextGadget(#GadgetDetailsState, 474, 308, 460, 18, "State: -")

  TextGadget(#GadgetQueueLabel, 20, 356, 200, 20, "Transfers")
  ListIconGadget(#GadgetQuickUploads, 20, 382, 930, 110, "Receiver", 140, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetQuickUploads, 1, "File path", 420)
  AddGadgetColumn(#GadgetQuickUploads, 2, "Size", 90)
  AddGadgetColumn(#GadgetQuickUploads, 3, "Status", 120)
  AddGadgetColumn(#GadgetQuickUploads, 4, "Progress", 120)
  TextGadget(#PB_Any, 20, 500, 160, 20, "Incoming / Downloads")
  ListIconGadget(#GadgetQuickDownloads, 20, 526, 930, 110, "Sender", 140, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#GadgetQuickDownloads, 1, "File path", 420)
  AddGadgetColumn(#GadgetQuickDownloads, 2, "Size", 90)
  AddGadgetColumn(#GadgetQuickDownloads, 3, "Status", 120)
  AddGadgetColumn(#GadgetQuickDownloads, 4, "Progress", 120)
  TextGadget(#GadgetProgressText, 20, 648, 930, 18, "Idle")
  ProgressBarGadget(#GadgetProgress, 20, 670, 930, 16, 0, 1000)

  ApplySimpleLayout()
  RefreshTransferLists()
  SetGadgetColor(#GadgetQuickUploads, #PB_Gadget_BackColor, RGB(248, 250, 252))
  SetGadgetColor(#GadgetQuickDownloads, #PB_Gadget_BackColor, RGB(248, 250, 252))
  EnableWindowDrop(#WindowMain, #PB_Drop_Files, #PB_Drag_Copy)
EndProcedure

Procedure MainLoop()
  Protected Event.i
  Protected Quit.i
  Protected ChosenPath$
  Protected Dropped$
  Protected DiscoveryIndex.i
  Protected *SelectedPeer.PeerState

  Repeat
    Event = WaitWindowEvent(10)

    Select Event
      Case #PB_Event_CloseWindow
        If EventWindow() = #WindowMain
          MinimizeToTray()
          If TrayAvailable = 0
            Exit()
            If QuitRequested
              Quit = #True
            EndIf
          EndIf
        ElseIf EventWindow() = #WindowSettings
          HideWindow(#WindowSettings, #True)
        EndIf

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #GadgetQuickSendFiles
            OpenQuickSendFiles()

          Case #GadgetQuickSendFolder
            OpenQuickSendFolder()

          Case #GadgetQuickSettings
            OpenSettingsWindow()

          Case #GadgetQuickExit
            Exit()
            If QuitRequested
              Quit = #True
            EndIf

          Case #GadgetScan
            StartDiscoveryScan()

          Case #GadgetPause
            If TransfersPaused
              ResumeAllTransfers()
            Else
              PauseAllTransfers()
            EndIf

          Case #GadgetCancel
            CancelQueuedTransfers()

          Case #GadgetDiscoveryPeersOnly
            DiscoveryFilterPeersOnly = Bool(GetGadgetState(#GadgetDiscoveryPeersOnly) = #PB_Checkbox_Checked)
            RefreshDiscoveryList()
            UpdateDiscoveryDetails()

          Case #GadgetCopyInfo
            CopyConnectionInfo()

          Case #GadgetDiscovery
            UpdateDiscoveryDetails()
            DiscoveryIndex = GetGadgetState(#GadgetDiscovery)
            If DiscoveryIndex >= 0 And DiscoveryIndex < DiscoveryEntryCount And DiscoveryEntryIsLanShare(DiscoveryIndex)
              PreferredReceiverHost$ = DiscoveryEntryHost$(DiscoveryIndex)
              PreferredReceiverPort = DiscoveryEntryPort(DiscoveryIndex)
              PreferredReceiverIsLanShare = DiscoveryEntryIsLanShare(DiscoveryIndex)
              CurrentQueuedTargetHost$ = PreferredReceiverHost$
              CurrentQueuedTargetPort = PreferredReceiverPort
              SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
              SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
              If ListSize(UploadQueue()) > 0
                *SelectedPeer = GetPeer(ActiveRemoteConnection)
                If ActiveRemoteConnection = 0 Or *SelectedPeer = 0 Or LCase(*SelectedPeer\PeerHost) <> LCase(CurrentQueuedTargetHost$)
                  DisconnectAfterUploadQueue = #False
                  ConnectRemote()
                EndIf
                If ActiveRemoteConnection
                  UpdateTransferRow(#TransferRowUpload, "queued-send", CurrentQueuedTargetHost$, "Preparing transfer", 0, "Connecting", 0)
                  TryStartNextUpload()
                EndIf
              EndIf
            EndIf
            If EventType() = #PB_EventType_LeftDoubleClick
              If DiscoveryIndex >= 0 And DiscoveryIndex < DiscoveryEntryCount
                If DiscoveryEntryPort(DiscoveryIndex) > 0 And DiscoveryEntryIsLanShare(DiscoveryIndex)
                  If ListSize(UploadQueue()) = 0
                    SetGadgetText(#GadgetRemoteHost, DiscoveryEntryHost$(DiscoveryIndex))
                    SetGadgetText(#GadgetPort, Str(DiscoveryEntryPort(DiscoveryIndex)))
                    ConnectRemote()
                  EndIf
                Else
                  AddLog("Selected generic LAN device: " + DiscoveryEntryHost$(DiscoveryIndex))
                EndIf
              EndIf
            EndIf

          Case #GadgetSettingsShareBrowse
          Case #GadgetSettingsDownloadBrowse
            ChosenPath$ = PathRequester("Choose the download folder", GetGadgetText(#GadgetSettingsDownload))
            If ChosenPath$
              SetGadgetText(#GadgetSettingsDownload, TrimTrailingSlash(ChosenPath$))
            EndIf

          Case #GadgetSettingsSave
            DownloadPath$ = TrimTrailingSlash(GetGadgetText(#GadgetSettingsDownload))
            SetGadgetText(#GadgetDownloadPath, DownloadPath$)
            SetGadgetText(#GadgetPort, GetGadgetText(#GadgetSettingsPort))
            SaveSettings()
            EnsureUsablePort(#True)
            If ServerRunning
              StopServer()
              StartServer()
            EndIf
            If IsWindow(#WindowSettings)
              HideWindow(#WindowSettings, #True)
            EndIf

          Case #GadgetSettingsCancel
            If IsWindow(#WindowSettings)
              HideWindow(#WindowSettings, #True)
            EndIf

        EndSelect

      Case #PB_Event_GadgetDrop
        If EventDropType() = #PB_Drop_Files
          Dropped$ = EventDropFiles()
          ClearList(UploadQueue())
          ClearList(Transfers())
          RefreshTransferLists()
          QueueUploadsFromDrop(Dropped$, "")
          If UseSelectedReceiverIfAvailable()
            ConnectRemote()
            UpdateTransferRow(#TransferRowUpload, "queued-send", CurrentQueuedTargetHost$, "Preparing transfer", 0, "Connecting", 0)
            TryStartNextUpload()
          Else
            If ScanActive = 0
              StartDiscoveryScan()
              AddLog("No receiver selected. Scanning now...")
            Else
              AddLog("Select a receiver from Available Receivers to start the transfer")
            EndIf
            SetActiveWindow(#WindowMain)
          EndIf
        EndIf

      Case #PB_Event_SysTray
        If EventGadget() = #TrayMain And EventType() = #PB_EventType_LeftDoubleClick
          RestoreMainWindow()
        EndIf

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MenuTrayShow
            RestoreMainWindow()
          Case #MenuTrayScan
            RestoreMainWindow()
            StartDiscoveryScan()
          Case #MenuTrayExit
            Exit()
            If QuitRequested
              Quit = #True
            EndIf
        EndSelect
    EndSelect

    PollNetwork()
    ContinueDiscoveryScan()
    TryStartNextUpload()
    TryStartNextDownload()
  Until Quit
EndProcedure

Procedure InitDefaults()
  HostName$ = Trim(GetEnvironmentVariable("COMPUTERNAME"))
  If HostName$ = ""
    HostName$ = "My_LAN_PC"
  EndIf

  DownloadPath$ = TrimTrailingSlash(GetHomeDirectory() + "Downloads\LANShareDownloads")
  SharePath$ = DownloadPath$
  LoadSettings()
  If IsUsableTransferDirectory(DownloadPath$) = 0
    DownloadPath$ = TrimTrailingSlash(GetHomeDirectory() + "Downloads\LANShareDownloads")
  EndIf
  SharePath$ = DownloadPath$
  If IsUsableTransferDirectory(DownloadPath$) = 0
    MessageRequester(#APP_NAME, "PB_LanShare could not create the default download folder. Please check your permissions.")
  EndIf
  TransfersPaused = #False
  ScanMutex = CreateMutex()
EndProcedure
