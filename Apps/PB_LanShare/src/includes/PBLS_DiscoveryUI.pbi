; Discovery list, quick-send UI, tray helpers, and runtime-facing UI updates.

Procedure RefreshDiscoveryList()
  Protected Display$
  Protected Index.i
  Protected TypeText$
  Protected PortText$
  Protected SelectedHost$
  Protected SelectedIndex.i = -1

  If PreferredReceiverHost$ <> ""
    SelectedHost$ = PreferredReceiverHost$
  Else
    SelectedIndex = GetGadgetState(#GadgetDiscovery)
    If SelectedIndex >= 0 And SelectedIndex <= ArraySize(DiscoveryEntryHost$())
      SelectedHost$ = DiscoveryEntryHost$(SelectedIndex)
    EndIf
  EndIf

  ClearGadgetItems(#GadgetDiscovery)
  If MapSize(Discovery()) <= 0
    ReDim DiscoveryEntryHost$(0)
    ReDim DiscoveryEntryPort(0)
    ReDim DiscoveryEntryIsLanShare(0)
    DiscoveryEntryCount = 0
    ProcedureReturn
  EndIf

  ReDim DiscoveryEntryHost$(MapSize(Discovery()) - 1)
  ReDim DiscoveryEntryPort(MapSize(Discovery()) - 1)
  ReDim DiscoveryEntryIsLanShare(MapSize(Discovery()) - 1)
  Index = 0
  ForEach Discovery()
    If DiscoveryFilterPeersOnly And Discovery()\IsLanShare = 0
      Continue
    EndIf

    If Discovery()\Name <> ""
      Display$ = Discovery()\Name + " (" + Discovery()\Host + ")"
    Else
      Display$ = Discovery()\Host
    EndIf

    TypeText$ = Discovery()\DeviceType
    If Discovery()\State <> ""
      TypeText$ + " " + Discovery()\State
    EndIf

    If Discovery()\Port > 0
      PortText$ = Str(Discovery()\Port)
    Else
      PortText$ = "-"
    EndIf

    AddGadgetItem(#GadgetDiscovery, -1, Display$ + Chr(10) + TypeText$ + Chr(10) + PortText$)
    DiscoveryEntryHost$(Index) = Discovery()\Host
    DiscoveryEntryPort(Index) = Discovery()\Port
    DiscoveryEntryIsLanShare(Index) = Discovery()\IsLanShare
    If SelectedHost$ <> "" And Discovery()\Host = SelectedHost$
      SelectedIndex = Index
    EndIf
    Index + 1
  Next

  If Index = 0
    ReDim DiscoveryEntryHost$(0)
    ReDim DiscoveryEntryPort(0)
    ReDim DiscoveryEntryIsLanShare(0)
    DiscoveryEntryCount = 0
  Else
    ReDim DiscoveryEntryHost$(Index - 1)
    ReDim DiscoveryEntryPort(Index - 1)
    ReDim DiscoveryEntryIsLanShare(Index - 1)
    DiscoveryEntryCount = Index
    If SelectedIndex >= 0 And SelectedIndex < DiscoveryEntryCount
      SetGadgetState(#GadgetDiscovery, SelectedIndex)
    EndIf
  EndIf
EndProcedure

Procedure UpdateDiscoveryDetails()
  Protected Index.i = GetGadgetState(#GadgetDiscovery)
  Protected Host$

  If Index < 0 Or Index >= DiscoveryEntryCount
    SetGadgetText(#GadgetDetailsTitle, "Device Details")
    SetGadgetText(#GadgetDetailsHost, "Host: -")
    SetGadgetText(#GadgetDetailsType, "Type: -")
    SetGadgetText(#GadgetDetailsPort, "Port: -")
    SetGadgetText(#GadgetDetailsMac, "MAC: -")
    SetGadgetText(#GadgetDetailsVendor, "Vendor: -")
    SetGadgetText(#GadgetDetailsState, "State: -")
    ProcedureReturn
  EndIf

  Host$ = DiscoveryEntryHost$(Index)
  If FindMapElement(Discovery(), Host$)
    SetGadgetText(#GadgetDetailsTitle, "Device Details")
    SetGadgetText(#GadgetDetailsHost, "Host: " + Discovery()\Host)
    SetGadgetText(#GadgetDetailsType, "Type: " + Discovery()\DeviceType)
    If Discovery()\Port > 0
      SetGadgetText(#GadgetDetailsPort, "Port: " + Str(Discovery()\Port))
    Else
      SetGadgetText(#GadgetDetailsPort, "Port: -")
    EndIf
    If Discovery()\MacAddress <> ""
      SetGadgetText(#GadgetDetailsMac, "MAC: " + Discovery()\MacAddress)
    Else
      SetGadgetText(#GadgetDetailsMac, "MAC: -")
    EndIf
    If Discovery()\Vendor <> ""
      SetGadgetText(#GadgetDetailsVendor, "Vendor: " + Discovery()\Vendor)
    Else
      SetGadgetText(#GadgetDetailsVendor, "Vendor: -")
    EndIf
    If Discovery()\State <> ""
      SetGadgetText(#GadgetDetailsState, "State: " + Discovery()\State)
    Else
      SetGadgetText(#GadgetDetailsState, "State: live network host")
    EndIf
  EndIf
EndProcedure

Procedure CopyConnectionInfo()
  Protected Index.i = GetGadgetState(#GadgetDiscovery)
  Protected Text$

  If Index < 0 Or Index >= DiscoveryEntryCount
    Text$ = "Host=" + GetGadgetText(#GadgetRemoteHost) + "; Port=" + GetGadgetText(#GadgetPort)
  Else
    Text$ = "Host=" + DiscoveryEntryHost$(Index) + "; Port=" + Str(DiscoveryEntryPort(Index))
  EndIf

  SetClipboardText(Text$)
  AddLog("Copied connection info to clipboard")
EndProcedure

Procedure RefreshTransferLists()
  Protected UploadText$
  Protected DownloadText$

  ClearGadgetItems(#GadgetQuickUploads)
  ClearGadgetItems(#GadgetQuickDownloads)

  ForEach Transfers()
    If Transfers()\Direction = #TransferRowUpload
      UploadText$ = Transfers()\Peer + Chr(10) + Transfers()\FilePath + Chr(10) + FormatBytes(Transfers()\Size) + Chr(10) + Transfers()\Status + Chr(10) + Str(Transfers()\Progress) + "%"
      AddGadgetItem(#GadgetQuickUploads, -1, UploadText$)
    ElseIf Transfers()\Direction = #TransferRowDownload
      DownloadText$ = Transfers()\Peer + Chr(10) + Transfers()\FilePath + Chr(10) + FormatBytes(Transfers()\Size) + Chr(10) + Transfers()\Status + Chr(10) + Str(Transfers()\Progress) + "%"
      AddGadgetItem(#GadgetQuickDownloads, -1, DownloadText$)
    EndIf
  Next

  If CountGadgetItems(#GadgetQuickUploads) = 0
    AddGadgetItem(#GadgetQuickUploads, -1, "-" + Chr(10) + "No outgoing transfers yet" + Chr(10) + "-" + Chr(10) + "Ready" + Chr(10) + "0%")
  EndIf
  If CountGadgetItems(#GadgetQuickDownloads) = 0
    AddGadgetItem(#GadgetQuickDownloads, -1, "-" + Chr(10) + "No incoming transfers yet" + Chr(10) + "-" + Chr(10) + "Ready" + Chr(10) + "0%")
  EndIf
EndProcedure

Procedure UpdateTransferRow(Direction.i, Key$, Peer$, FilePath$, Size.q, Status$, Progress.i)
  If Peer$ = ""
    Peer$ = "Waiting..."
  EndIf

  ForEach Transfers()
    If Transfers()\Direction = Direction And Transfers()\Key = Key$
      Transfers()\Peer = Peer$
      Transfers()\FilePath = FilePath$
      Transfers()\Size = Size
      Transfers()\Status = Status$
      Transfers()\Progress = Progress
      RefreshTransferLists()
      ProcedureReturn
    EndIf
  Next

  AddElement(Transfers())
  Transfers()\Direction = Direction
  Transfers()\Key = Key$
  Transfers()\Peer = Peer$
  Transfers()\FilePath = FilePath$
  Transfers()\Size = Size
  Transfers()\Status = Status$
  Transfers()\Progress = Progress
  RefreshTransferLists()
EndProcedure

Procedure RemoveTransferRow(Direction.i, Key$)
  ForEach Transfers()
    If Transfers()\Direction = Direction And Transfers()\Key = Key$
      DeleteElement(Transfers())
      Break
    EndIf
  Next
  RefreshTransferLists()
EndProcedure

Procedure OpenSettingsWindow()
  If IsWindow(#WindowSettings)
    SetGadgetText(#GadgetSettingsDownload, DownloadPath$)
    SetGadgetText(#GadgetSettingsPort, GetGadgetText(#GadgetPort))
    HideWindow(#WindowSettings, #False)
    SetActiveWindow(#WindowSettings)
    ProcedureReturn
  EndIf

  OpenWindow(#WindowSettings, 0, 0, 520, 170, "Settings", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  TextGadget(#PB_Any, 16, 24, 100, 20, "Downloads")
  StringGadget(#GadgetSettingsDownload, 120, 20, 300, 24, DownloadPath$)
  ButtonGadget(#GadgetSettingsDownloadBrowse, 430, 20, 70, 24, "Browse")
  TextGadget(#PB_Any, 16, 64, 100, 20, "TCP Port")
  StringGadget(#GadgetSettingsPort, 120, 60, 120, 24, GetGadgetText(#GadgetPort), #PB_String_Numeric)
  ButtonGadget(#GadgetSettingsSave, 300, 112, 90, 28, "Save")
  ButtonGadget(#GadgetSettingsCancel, 400, 112, 90, 28, "Close")
EndProcedure

Procedure.i UseSelectedReceiverIfAvailable()
  Protected DiscoveryIndex.i = GetGadgetState(#GadgetDiscovery)

  If DiscoveryIndex >= 0 And DiscoveryIndex < DiscoveryEntryCount
    If DiscoveryEntryIsLanShare(DiscoveryIndex) And DiscoveryEntryPort(DiscoveryIndex) > 0
      PreferredReceiverHost$ = DiscoveryEntryHost$(DiscoveryIndex)
      PreferredReceiverPort = DiscoveryEntryPort(DiscoveryIndex)
      PreferredReceiverIsLanShare = DiscoveryEntryIsLanShare(DiscoveryIndex)
      CurrentQueuedTargetHost$ = PreferredReceiverHost$
      CurrentQueuedTargetPort = PreferredReceiverPort
      SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
      SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
      ProcedureReturn #True
    EndIf
  EndIf

  If PreferredReceiverHost$ <> "" And PreferredReceiverIsLanShare And PreferredReceiverPort > 0
    CurrentQueuedTargetHost$ = PreferredReceiverHost$
    CurrentQueuedTargetPort = PreferredReceiverPort
    SetGadgetText(#GadgetRemoteHost, CurrentQueuedTargetHost$)
    SetGadgetText(#GadgetPort, Str(CurrentQueuedTargetPort))
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure OpenQuickSendFiles()
  Protected File$

  File$ = OpenFileRequester("Choose files to send", "", "All files (*.*)|*.*", 0, #PB_Requester_MultiSelection)
  If File$ = ""
    ProcedureReturn
  EndIf

  ClearList(UploadQueue())
  While File$ <> ""
    If FileSize(File$) >= 0
      QueueUploadItem(File$, GetFilePart(File$), #False)
    EndIf
    File$ = NextSelectedFileName()
  Wend
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
EndProcedure

Procedure OpenQuickSendFolder()
  Protected Folder$

  Folder$ = PathRequester("Choose a folder to send", SharePath$)
  If Folder$
    QueueQuickSend(Folder$, #True)
  EndIf
EndProcedure

Procedure QueueQuickSend(LocalPath$, IsDirectory.i)
  If FileSize(LocalPath$) = -1
    ProcedureReturn
  EndIf

  ClearList(UploadQueue())
  CurrentQueuedTargetHost$ = ""
  CurrentQueuedTargetPort = 0
  ClearList(Transfers())
  RefreshTransferLists()
  If IsDirectory
    QueueUploadPathRecursive(TrimTrailingSlash(LocalPath$), "")
  Else
    QueueUploadItem(LocalPath$, GetFilePart(LocalPath$), #False)
  EndIf
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
EndProcedure

Procedure ApplySimpleLayout()
  HideGadget(#GadgetShareLabel, #True)
  HideGadget(#GadgetShareBrowse, #True)
  HideGadget(#GadgetDownloadLabel, #True)
  HideGadget(#GadgetDownloadBrowse, #True)
  HideGadget(#GadgetPortLabel, #True)
  HideGadget(#GadgetServerToggle, #True)
  HideGadget(#GadgetRemoteHostLabel, #True)
  HideGadget(#GadgetConnect, #True)
  HideGadget(#GadgetDisconnect, #True)
  HideGadget(#GadgetRefresh, #True)
  HideGadget(#GadgetParent, #True)
  HideGadget(#GadgetOverwriteLabel, #True)
  HideGadget(#GadgetUpload, #True)
  HideGadget(#GadgetDownload, #True)
  HideGadget(#GadgetRemotePathLabel, #True)
  HideGadget(#GadgetRemotePath, #True)
  HideGadget(#GadgetRemoteList, #True)
  HideGadget(#GadgetHistory, #True)
  HideGadget(#GadgetLog, #True)
  HideGadget(#GadgetUploadQueue, #True)
  HideGadget(#GadgetUploadUp, #True)
  HideGadget(#GadgetUploadDown, #True)
  HideGadget(#GadgetUploadRemove, #True)
  HideGadget(#GadgetDownloadQueue, #True)
  HideGadget(#GadgetDownloadUp, #True)
  HideGadget(#GadgetDownloadDown, #True)
  HideGadget(#GadgetDownloadRemove, #True)

  ResizeGadget(#GadgetServerStatus, 20, 112, 930, 22)
  ResizeGadget(#GadgetLocalIPs, 20, 136, 930, 22)
  ResizeGadget(#GadgetDiscoveryLabel, 20, 170, 160, 20)
  ResizeGadget(#GadgetDiscoveryPeersOnly, 180, 168, 120, 20)
  ResizeGadget(#GadgetCopyInfo, 308, 164, 100, 28)
  ResizeGadget(#GadgetDiscovery, 20, 198, 430, 140)
  ResizeGadget(#GadgetDetailsTitle, 474, 170, 160, 20)
  ResizeGadget(#GadgetDetailsHost, 474, 198, 460, 18)
  ResizeGadget(#GadgetDetailsType, 474, 220, 460, 18)
  ResizeGadget(#GadgetDetailsPort, 474, 242, 460, 18)
  ResizeGadget(#GadgetDetailsMac, 474, 264, 460, 18)
  ResizeGadget(#GadgetDetailsVendor, 474, 286, 460, 18)
  ResizeGadget(#GadgetDetailsState, 474, 308, 460, 18)
  ResizeGadget(#GadgetQueueLabel, 20, 356, 160, 20)
  ResizeGadget(#GadgetQuickUploads, 20, 382, 930, 110)
  ResizeGadget(#GadgetQuickDownloads, 20, 526, 930, 110)
  ResizeGadget(#GadgetProgressText, 20, 648, 930, 18)
  ResizeGadget(#GadgetProgress, 20, 670, 930, 16)
EndProcedure

Procedure RefreshQueueViews()
  Protected Text$

  ClearGadgetItems(#GadgetUploadQueue)
  ForEach UploadQueue()
    If UploadQueue()\IsDirectory
      Text$ = "DIR  " + UploadQueue()\RemotePath
    Else
      Text$ = "FILE " + UploadQueue()\RemotePath
    EndIf
    AddGadgetItem(#GadgetUploadQueue, -1, Text$)
  Next

  ClearGadgetItems(#GadgetDownloadQueue)
  ForEach DownloadQueue()
    AddGadgetItem(#GadgetDownloadQueue, -1, DownloadQueue()\RemotePath)
  Next
EndProcedure

Procedure MoveSelectedUpload(Delta.i)
  Protected Index.i = GetGadgetState(#GadgetUploadQueue)
  Protected Target.i = Index + Delta
  Protected Position.i
  Protected Temp.UploadItem

  If Index < 0 Or Target < 0 Or Target >= ListSize(UploadQueue())
    ProcedureReturn
  EndIf

  Position = 0
  ForEach UploadQueue()
    If Position = Index
      CopyStructure(@UploadQueue(), @Temp, UploadItem)
      DeleteElement(UploadQueue())
      Break
    EndIf
    Position + 1
  Next

  Position = 0
  ForEach UploadQueue()
    If Position = Target
      InsertElement(UploadQueue())
      CopyStructure(@Temp, @UploadQueue(), UploadItem)
      RefreshQueueViews()
      SetGadgetState(#GadgetUploadQueue, Target)
      ProcedureReturn
    EndIf
    Position + 1
  Next

  LastElement(UploadQueue())
  AddElement(UploadQueue())
  CopyStructure(@Temp, @UploadQueue(), UploadItem)
  RefreshQueueViews()
  SetGadgetState(#GadgetUploadQueue, ListSize(UploadQueue()) - 1)
EndProcedure

Procedure RemoveSelectedUpload()
  Protected Index.i = GetGadgetState(#GadgetUploadQueue)
  Protected Position.i

  If Index < 0
    ProcedureReturn
  EndIf

  Position = 0
  ForEach UploadQueue()
    If Position = Index
      DeleteElement(UploadQueue())
      Break
    EndIf
    Position + 1
  Next
  RefreshQueueViews()
EndProcedure

Procedure MoveSelectedDownload(Delta.i)
  Protected Index.i = GetGadgetState(#GadgetDownloadQueue)
  Protected Target.i = Index + Delta
  Protected Position.i
  Protected Temp.DownloadItem

  If Index < 0 Or Target < 0 Or Target >= ListSize(DownloadQueue())
    ProcedureReturn
  EndIf

  Position = 0
  ForEach DownloadQueue()
    If Position = Index
      CopyStructure(@DownloadQueue(), @Temp, DownloadItem)
      DeleteElement(DownloadQueue())
      Break
    EndIf
    Position + 1
  Next

  Position = 0
  ForEach DownloadQueue()
    If Position = Target
      InsertElement(DownloadQueue())
      CopyStructure(@Temp, @DownloadQueue(), DownloadItem)
      RefreshQueueViews()
      SetGadgetState(#GadgetDownloadQueue, Target)
      ProcedureReturn
    EndIf
    Position + 1
  Next

  LastElement(DownloadQueue())
  AddElement(DownloadQueue())
  CopyStructure(@Temp, @DownloadQueue(), DownloadItem)
  RefreshQueueViews()
  SetGadgetState(#GadgetDownloadQueue, ListSize(DownloadQueue()) - 1)
EndProcedure

Procedure RemoveSelectedDownload()
  Protected Index.i = GetGadgetState(#GadgetDownloadQueue)
  Protected Position.i

  If Index < 0
    ProcedureReturn
  EndIf

  Position = 0
  ForEach DownloadQueue()
    If Position = Index
      DeleteElement(DownloadQueue())
      Break
    EndIf
    Position + 1
  Next
  RefreshQueueViews()
EndProcedure

Procedure ShowFirstRunHelp()
  Protected Help$

  If FirstRunShown
    ProcedureReturn
  EndIf

  If FileSize(SettingsPath()) <> -1 Or FileSize(LegacySettingsPath()) <> -1
    ProcedureReturn
  EndIf

  Help$ = "Welcome to PB_LanShare." + #CRLF$ + #CRLF$
  Help$ + "Simple use:" + #CRLF$
  Help$ + "1. Open PB_LanShare on both laptops." + #CRLF$
  Help$ + "2. Click Find Receivers." + #CRLF$
  Help$ + "3. Click Send Files or Send Folder." + #CRLF$
  Help$ + "4. Pick a receiver in Available Receivers and the transfer starts." + #CRLF$ + #CRLF$
  Help$ + "Use Settings only if you want to change folders or the port."

  MessageRequester(#APP_NAME, Help$, #PB_MessageRequester_Info)
  FirstRunShown = #True
EndProcedure

Procedure CreateTraySupport()
  TrayImage = LoadImage(#PB_Any, AppPath + "files\PB_LanShare.ico")
  If TrayImage = 0
    TrayImage = LoadImage(#PB_Any, AppPath + "src\PB_LanShare.ico")
  EndIf
  If TrayImage
    If AddSysTrayIcon(#TrayMain, WindowID(#WindowMain), ImageID(TrayImage))
      TrayAvailable = #True
    EndIf
  Else
    CreateImage(999, 16, 16, 32, RGB(40, 130, 220))
    If IsImage(999)
      If AddSysTrayIcon(#TrayMain, WindowID(#WindowMain), ImageID(999))
        TrayAvailable = #True
      EndIf
    EndIf
  EndIf

  If TrayAvailable And IsSysTrayIcon(#TrayMain)
    CreatePopupMenu(#TrayMain)
    MenuItem(#MenuTrayShow, "Show / Restore")
    MenuItem(#MenuTrayScan, "Find Receivers")
    MenuBar()
    MenuItem(#MenuTrayExit, "Exit")
    SysTrayIconMenu(#TrayMain, MenuID(#TrayMain))
  EndIf
EndProcedure

Procedure RestoreMainWindow()
  HideWindow(#WindowMain, #False, #PB_Window_ScreenCentered)
  SetActiveWindow(#WindowMain)
EndProcedure

Procedure MinimizeToTray()
  If TrayAvailable
    HideWindow(#WindowMain, #True)
    AddLog("Minimized to tray")
  EndIf
EndProcedure
