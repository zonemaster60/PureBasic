; GUI construction, layout, and shared UI shell state

Procedure SyncUiState()
  Protected pauseText.s = "Pause"

  If IndexingPaused
    pauseText = "Resume"
  EndIf

  If IsMenu(#Menu_Main)
    SetMenuItemState(#Menu_Main, #Menu_View_Compact, AppCompactMode)
    SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
    SetMenuItemState(#Menu_Main, #Menu_App_RunAtStartup, Bool(AppRunAtStartup))
    SetMenuItemText(#Menu_Main, #Menu_Index_PauseResume, pauseText)
  EndIf

  If IsMenu(#Menu_TrayPopup)
    SetMenuItemState(#Menu_TrayPopup, #Menu_Tray_RunAtStartup, Bool(AppRunAtStartup))
    SetMenuItemText(#Menu_TrayPopup, #Menu_Tray_PauseResume, pauseText)
  EndIf
EndProcedure

Procedure UpdateStartupMenuState()
  SyncUiState()
EndProcedure

Procedure UpdateControlStates()
  ; Only call this on the main (GUI) thread.
  DisableGadget(#Gadget_SearchBar, #False)
  SyncUiState()
EndProcedure

Procedure RequestUiStateSync()
  PendingUiStateSync = #True
EndProcedure

Procedure.i GetFileIconIndex(path.s)
  Protected shinfo.SHFILEINFO
  Protected ext.s = GetExtensionPart(path)
  Protected isDir.i = Bool(FileSize(path) = -2)
  Protected key.s = LCase(ext)
  Protected cached.i
  Protected flags.i = $100 | $1 | $10
  Protected attr.i = 0
  Protected img.i
  Protected hdc.i

  If isDir : key = "_DIR_" : EndIf
  If key = "" : key = "_FILE_" : EndIf

  LockMutex(IconMutex)
  If FindMapElement(IconCache(), key)
    cached = IconCache()
    UnlockMutex(IconMutex)
    ProcedureReturn cached
  EndIf

  If isDir
    attr = $10
  Else
    attr = $80
  EndIf

  If SHGetFileInfo_(path, attr, @shinfo, SizeOf(SHFILEINFO), flags)
    If shinfo\hIcon
      img = CreateImage(#PB_Any, 16, 16, 32, #PB_Image_Transparent)
      If img
        hdc = StartDrawing(ImageOutput(img))
        If hdc
          DrawIconEx_(hdc, 0, 0, shinfo\hIcon, 16, 16, 0, 0, 3)
          StopDrawing()
        EndIf
        DestroyIcon_(shinfo\hIcon)
        IconCache(key) = img
        UnlockMutex(IconMutex)
        ProcedureReturn img
      EndIf
      DestroyIcon_(shinfo\hIcon)
    EndIf
  EndIf

  UnlockMutex(IconMutex)
  ProcedureReturn 0
EndProcedure

Procedure ResizeMainWindow()
  If IsWindow(#Window_Main) = 0
    ProcedureReturn
  EndIf

  Protected w.i = WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  Protected h.i = WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)
  Protected margin.i
  Protected searchH.i
  Protected listTop.i
  Protected listH.i
  Protected statusH.i = 0
  Protected usableW.i

  If AppCompactMode
    margin = 6
    searchH = 22
  Else
    margin = 10
    searchH = 25
  EndIf

  listTop = margin + searchH + 5

  statusH = StatusBarHeight(#StatusBar_Main)
  If statusH <= 0
    Structure HS_RECT
      left.l
      top.l
      right.l
      bottom.l
    EndStructure
    Protected r.HS_RECT
    Protected hStatus.i = StatusBarID(#StatusBar_Main)
    If hStatus And GetWindowRect_(hStatus, @r)
      statusH = r\bottom - r\top
    EndIf
  EndIf
  If statusH < 0 : statusH = 0 : EndIf

  listH = h - listTop - margin - statusH
  If listH < 50 : listH = 50 : EndIf

  usableW = w - margin * 2
  If usableW < 50 : usableW = 50 : EndIf

  ResizeGadget(#Gadget_SearchBar, margin, margin, usableW, searchH)
  ResizeGadget(#Gadget_ResultsList, margin, listTop, usableW, listH)
EndProcedure

Procedure SetCompactMode(enable.i)
  If AppCompactMode = Bool(enable)
    ProcedureReturn
  EndIf

  AppCompactMode = Bool(enable)

  If AppCompactMode
    CompactSavedX = WindowX(#Window_Main)
    CompactSavedY = WindowY(#Window_Main)
    CompactSavedW = WindowWidth(#Window_Main)
    CompactSavedH = WindowHeight(#Window_Main)
    ResizeWindow(#Window_Main, #PB_Ignore, #PB_Ignore, 640, 380)
  Else
    If CompactSavedW > 0 And CompactSavedH > 0
      ResizeWindow(#Window_Main, CompactSavedX, CompactSavedY, CompactSavedW, CompactSavedH)
    EndIf
  EndIf

  If IsMenu(#Menu_Main)
    SetMenuItemState(#Menu_Main, #Menu_View_Compact, AppCompactMode)
    SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
  EndIf

  ResizeMainWindow()
EndProcedure

Procedure InitGUI()
  OpenWindow(#Window_Main, 100, 100, 800, 600, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget |
                                                                        #PB_Window_ScreenCentered | #PB_Window_SizeGadget)

  WindowBounds(#Window_Main, 420, 220, #PB_Ignore, #PB_Ignore)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Return, #Menu_StartSearchShortcut)

  CreateMenu(#Menu_Main, WindowID(#Window_Main))
  MenuTitle("File")
  MenuItem(#Menu_File_Exit, "Exit")
  MenuTitle("Index")
  MenuItem(#Menu_Index_StartResume, "Start/Resume")
  MenuItem(#Menu_Index_Rebuild, "Rebuild")
  MenuItem(#Menu_Index_PauseResume, "Pause")
  MenuItem(#Menu_Index_Stop, "Stop")
  MenuTitle("View")
  MenuItem(#Menu_View_Compact, "Compact mode")
  MenuItem(#Menu_View_LiveMatchFullPath, "Live match full path")
  MenuTitle("App")
  MenuItem(#Menu_App_RunAtStartup, "Run at startup")
  MenuItem(#Menu_App_EditExcludes, "Edit excludes")
  SetMenuItemState(#Menu_Main, #Menu_App_RunAtStartup, Bool(AppRunAtStartup))
  MenuTitle("Tools")
  MenuItem(#Menu_Tools_Settings, "Settings")
  MenuItem(#Menu_Tools_OpenIni, "Open INI")
  MenuItem(#Menu_Tools_Web, "Web")
  MenuTitle("Help")
  MenuItem(#Menu_Help_About, "About")

  StringGadget(#Gadget_SearchBar, 10, 10, 780, 25, "*.*")
  ListViewGadget(#Gadget_ResultsList, 10, 40, 780, 510)

  If IsGadget(#Gadget_ResultsList) : FreeGadget(#Gadget_ResultsList) : EndIf
  ListIconGadget(#Gadget_ResultsList, 10, 40, 780, 510, "Path", 1000, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
  SendMessage_(GadgetID(#Gadget_ResultsList), #LVM_SETCOLUMNWIDTH, 0, #LVSCW_AUTOSIZE_USEHEADER)

  StringGadget(#Gadget_FolderPath, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_BrowseButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_AboutButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_ExitButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_StartButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_StopButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_ConfigButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_WebButton, 0, 0, 0, 0, "")
  HideGadget(#Gadget_FolderPath, 1)
  HideGadget(#Gadget_BrowseButton, 1)
  HideGadget(#Gadget_AboutButton, 1)
  HideGadget(#Gadget_ExitButton, 1)
  HideGadget(#Gadget_StartButton, 1)
  HideGadget(#Gadget_StopButton, 1)
  HideGadget(#Gadget_ConfigButton, 1)
  HideGadget(#Gadget_WebButton, 1)

  CreatePopupMenu(#Menu_ResultsPopup)
  MenuItem(#Menu_OpenFile, "Open")
  MenuItem(#Menu_OpenFolder, "Open containing folder")

  CreatePopupMenu(#Menu_TrayPopup)
  MenuItem(#Menu_Tray_ShowHide, "Show/Hide")
  MenuItem(#Menu_Tray_RebuildIndex, "Rebuild index (clears DB)")
  MenuItem(#Menu_Tray_OpenDbFolder, "Open DB folder")
  MenuItem(#Menu_Tray_ShowIndexedCount, "Show indexed count")
  MenuItem(#Menu_Tray_ShowDbPath, "Show DB path")
  MenuItem(#Menu_Tray_Diagnostics, "Diagnostics")
  MenuItem(#Menu_Tray_OpenCrashLog, "Open crash log (Logs folder)")
  MenuItem(#Menu_Tray_PauseResume, "Pause")
  MenuBar()
  MenuItem(#Menu_Tray_RunAtStartup, "Run at startup")
  SetMenuItemState(#Menu_TrayPopup, #Menu_Tray_RunAtStartup, Bool(AppRunAtStartup))
  MenuItem(#Menu_Tray_Settings, "Settings")
  MenuBar()
  MenuItem(#Menu_Tray_Exit, "Exit")

  CreateStatusBar(#StatusBar_Main, WindowID(#Window_Main))
  AddStatusBarField(540)
  AddStatusBarField(#PB_Ignore)
  StatusBarText(#StatusBar_Main, 0, "Idle")
  StatusBarText(#StatusBar_Main, 1, "")

  AddWindowTimer(#Window_Main, #Timer_PumpResults, 50)
  ResizeMainWindow()

  Protected trayImage.i
  Protected trayIcon.i
  Protected appExe.s

  TrayIconHandle = 0
  trayImage = LoadImage(#PB_Any, "HandySearch.ico")

  If trayImage
    trayIcon = ImageID(trayImage)
  Else
    appExe = ProgramFilename()
    If appExe <> ""
      Protected smallIcon.i
      Protected largeIcon.i
      If ExtractIconEx_(appExe, 0, @largeIcon, @smallIcon, 1) > 0
        If smallIcon
          TrayIconHandle = smallIcon
        ElseIf largeIcon
          TrayIconHandle = largeIcon
        EndIf
      EndIf
      If largeIcon And largeIcon <> TrayIconHandle : DestroyIcon_(largeIcon) : EndIf
      If smallIcon And smallIcon <> TrayIconHandle : DestroyIcon_(smallIcon) : EndIf
    EndIf
  EndIf

  If TrayIconHandle
    AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), TrayIconHandle)
  ElseIf trayImage
    AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), trayIcon)
  Else
    trayImage = CreateImage(#PB_Any, 16, 16)
    If trayImage
      StartDrawing(ImageOutput(trayImage))
      Box(0, 0, 16, 16, RGB(10, 120, 220))
      StopDrawing()
      AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), ImageID(trayImage))
    EndIf
  EndIf

  UpdateControlStates()
EndProcedure

Procedure ToggleMainWindow()
  If IsWindowVisible_(WindowID(#Window_Main))
    HideWindow(#Window_Main, 1)
  Else
    HideWindow(#Window_Main, 0)
    SetWindowState(#Window_Main, #PB_Window_Normal)
    SetActiveWindow(#Window_Main)
  EndIf
EndProcedure
