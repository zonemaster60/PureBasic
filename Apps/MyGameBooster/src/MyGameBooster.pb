; PureBasic 6.30 x64 - Safe Game Booster (MVP)
; - Launch EXE directly or via Steam
; - Set priority + optional affinity
; - Per-game power mode with automatic restore after launch

EnableExplicit

#APP_NAME = "MyGameBooster"
#APP_MUTEX_NAME = #APP_NAME + "_mutex"

Procedure.s EnsureLogFolder(baseFolder.s)
  Protected folder.s = baseFolder

  If folder = ""
    ProcedureReturn ""
  EndIf

  If Right(folder, 1) <> "\\"
    folder + "\\"
  EndIf

  folder + "Logs\\"

  If FileSize(folder) <> -2
    CreateDirectory(folder)
  EndIf

  If FileSize(folder) = -2
    ProcedureReturn folder
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s EnsureDataFolder(baseFolder.s)
  Protected folder.s = baseFolder

  If folder = ""
    ProcedureReturn ""
  EndIf

  If Right(folder, 1) <> "\\"
    folder + "\\"
  EndIf

  If FileSize(folder) <> -2
    CreateDirectory(folder)
  EndIf

  If FileSize(folder) = -2
    ProcedureReturn folder
  EndIf

  ProcedureReturn ""
EndProcedure

Global DataDir.s, GamesIni.s, SessionIni.s, SettingsIni.s, ArtworkDir.s
DataDir = EnsureDataFolder(GetPathPart(ProgramFilename()) + "files\\")
If DataDir = ""
  DataDir = GetPathPart(ProgramFilename())
EndIf
GamesIni = DataDir + #APP_NAME + "_games.ini"
SessionIni = DataDir + #APP_NAME + "_session.ini"
SettingsIni = DataDir + #APP_NAME + "_settings.ini"
ArtworkDir = DataDir + "artwork\\"
Global LogPath.s
LogPath = EnsureLogFolder(DataDir) + #APP_NAME + ".log"
If LogPath = #APP_NAME + ".log"
  LogPath = DataDir + #APP_NAME + ".log"
EndIf

Global FontUI.i, FontTitle.i, FontSmall.i
Global MainStatusBar.i
Global version.s = "v1.0.1.3"
Global BrowseExePath.s, BeforeCount.i, LaunchUiPulse.i
Global LaunchStartedAt.q
Global FilterQuery.s, SortMode.i, LibraryView.i
Global DefaultPreset.i
Global ThumbnailSize.i = 48
Global RememberLastView.i = 1
Global HistoryDepth.i = 10
Global SteamExeArgs.s
Global UndoLabel.s, RedoLabel.s

Global hMutex.i

Procedure AcquireSingleInstanceMutex()
  hMutex = CreateMutex_(0, 1, #APP_MUTEX_NAME)
  If hMutex = 0
    MessageRequester(#APP_NAME, "Failed to initialize the single-instance guard.", #PB_MessageRequester_Error)
    End
  EndIf

  If GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    hMutex = 0
    End
  EndIf
EndProcedure

; ---------- Windows constants ----------

#NORMAL_PRIORITY_CLASS      = $00000020
#BELOW_NORMAL_PRIORITY_CLASS= $00004000
#ABOVE_NORMAL_PRIORITY_CLASS= $00008000
#HIGH_PRIORITY_CLASS        = $00000080

CompilerIf Defined(PROCESS_QUERY_LIMITED_INFORMATION, #PB_Constant) = 0
  #PROCESS_QUERY_LIMITED_INFORMATION = $1000
CompilerEndIf

#WAIT_OBJECT_0 = 0

#TOKEN_QUERY = $0008
#TokenElevation = 20

#HKEY_CURRENT_USER  = $80000001
#HKEY_LOCAL_MACHINE = $80000002
#KEY_READ           = $20019
#REG_SZ             = 1
#REG_EXPAND_SZ      = 2

#POWERMODE_KEEP     = 0
#POWERMODE_HIGH     = 1
#POWERMODE_ULTIMATE = 2

#PRESET_SAFE       = 0
#PRESET_BALANCED   = 1
#PRESET_AGGRESSIVE = 2

#SORT_NAME_ASC      = 0
#SORT_LAST_PLAYED   = 1
#SORT_RUNS_DESC     = 2

#LIBRARY_ALL        = 0
#LIBRARY_STEAM      = 1
#LIBRARY_EXE        = 2
#LIBRARY_RECENT     = 3
#LIBRARY_MOSTPLAYED = 4
#LIBRARY_TAGGED     = 5

#LAUNCHMODE_EXE       = 0
#LAUNCHMODE_STEAM     = 1

DefaultPreset = #PRESET_BALANCED

#POWER_GUID_HIGH     = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
#POWER_GUID_ULTIMATE = "e9a42b02-d5df-448d-aa00-03f14749eb61"
#POWER_GUID_BALANCED = "381b4222-f694-41f0-9685-ff5bb260df2e"
#POWER_GUID_SAVER    = "a1841308-3541-4fab-bc81-f71556f20b4a"

#DIRID_STEAM_MANIFESTS = 1
#DIRID_FOLDER_SCAN_ROOT = 2
#DIRID_ANYFILE_CHECK = 10
#FOLDER_SCAN_DEPTH = 3

#TH32CS_SNAPPROCESS  = $00000002
#TH32CS_SNAPMODULE   = $00000008
#TH32CS_SNAPMODULE32 = $00000010

#LVM_FIRST   = $1000
#LVM_HITTEST = #LVM_FIRST + 18

#PRIVATE_DROP_GAME = 1001
#TRAYICON_MAIN    = 1

Structure GameEntry
  Name.s
  ExePath.s
  Args.s
  WorkDir.s
  Priority.l
  Affinity.q
  Services.s
  LaunchMode.i
  SteamAppId.i
  SteamExe.s
  SteamGameArgs.s
  SteamDetectTimeoutMs.i
  GameRoot.s
  Preset.i
  PowerMode.i
  OptimizeBackground.i
  Notes.s
  Tags.s
  LaunchCount.i
  LastPlayed.q
  LastDurationSec.i
EndStructure

Structure OC_TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

Structure OC_FILETIME
  dwLowDateTime.l
  dwHighDateTime.l
EndStructure

Structure OC_MEMORYSTATUSEX
  dwLength.l
  dwMemoryLoad.l
  ullTotalPhys.q
  ullAvailPhys.q
  ullTotalPageFile.q
  ullAvailPageFile.q
  ullTotalVirtual.q
  ullAvailVirtual.q
  ullAvailExtendedVirtual.q
EndStructure

Structure BoostSessionContext
  PrevPowerGuid.s
  AppliedPowerGuid.s
  DidSwitchPower.i
  StoppedServices.s
EndStructure

Structure ServiceInfo
  Name.s
  DisplayName.s
  Status.s
  StartType.s
EndStructure

Structure GameViewRow
  SourceIndex.i
  Name.s
  LaunchCount.i
  LastPlayed.q
  ItemText.s
EndStructure

Structure OC_PROCESSENTRY32
  dwSize.l
  cntUsage.l
  th32ProcessID.l
  th32DefaultHeapID.i
  th32ModuleID.l
  cntThreads.l
  th32ParentProcessID.l
  pcPriClassBase.l
  dwFlags.l
  szExeFile.u[#MAX_PATH]
EndStructure

Structure OC_MODULEENTRY32
  dwSize.l
  th32ModuleID.l
  th32ProcessID.l
  GlblcntUsage.l
  ProccntUsage.l
  modBaseAddr.i
  modBaseSize.l
  hModule.i
  szModule.u[256]
  szExePath.u[#MAX_PATH]
EndStructure

Structure OC_POINT
  x.l
  y.l
EndStructure

Structure OC_LVHITTESTINFO
  pt.OC_POINT
  flags.l
  iItem.l
  iSubItem.l
EndStructure

Global NewList Games.GameEntry()
Global LaunchActive.i, LaunchState.i, AppQuitting.i
Global LaunchGame.GameEntry
Global LaunchCtx.BoostSessionContext
Global LaunchProcess.i, LaunchDetectDeadline.i
Global LaunchOrigPriority.l
Global LaunchProcessAffinity.q, LaunchSystemAffinity.q
Global LaunchGotAffinity.i
Global LaunchStartRecorded.i
Global TrayIconImage.i, TrayIconVisible.i, LaunchTrayHidden.i
Global DragGameIndex.i = -1
Global LaunchGameRoot.s
Global NewMap LaunchBaseline.i()
Global NewMap LaunchTunedPriority.l()
Global NewMap LaunchTunedName.s()
Global NewList VisibleGameIndex.i()
Global NewMap GameThumbnail.i()
Global NewList UndoStates.s()
Global NewList UndoLabels.s()
Global NewList RedoStates.s()
Global NewList RedoLabels.s()
Global NewList HistoryActions.s()

Enumeration Gadgets
  #G_List
  #G_Title
  #G_Subtitle
  #G_Tool_Add
  #G_Tool_BrowseExe
  #G_Tool_AddFolder
  #G_Tool_ImportSteamGame
  #G_Library
  #G_Filter
  #G_Sort
  #G_LaunchState
  #G_CancelWait
  #G_OpenFolder
  #G_MoveUp
  #G_MoveDown
  #G_Remove
  #G_Edit
  #G_Launch
EndEnumeration

Enumeration Menus
  #Menu_Main
  #Menu_Tray
EndEnumeration

Enumeration MenuItems
  #MI_File_Add
  #MI_File_BrowseExe
  #MI_File_AddFolder
  #MI_File_ImportSteamGame
  #MI_File_ImportProfiles
  #MI_File_ExportProfiles
  #MI_File_CreateSnapshot
  #MI_File_RestoreSnapshot
  #MI_File_Undo
  #MI_File_Redo
  #MI_File_Exit
  #MI_Tray_ShowHide
  #MI_Tray_RunRecent
  #MI_Tray_Exit
  #MI_Game_Run
  #MI_Game_Edit
  #MI_Game_MoveUp
  #MI_Game_MoveDown
  #MI_Game_Remove
  #MI_Game_OpenFolder
  #MI_Tools_ViewLog
  #MI_Tools_Diagnostics
  #MI_Tools_History
  #MI_Tools_Settings
  #MI_Help_Help
  #MI_Help_About
EndEnumeration

XIncludeFile "MyGameBooster.Declarations.pbi"
XIncludeFile "MyGameBooster.Core.pbi"
XIncludeFile "MyGameBooster.SteamServices.pbi"
XIncludeFile "MyGameBooster.Games.pbi"
XIncludeFile "MyGameBooster.App.pbi"

UseJPEGImageDecoder()
UseJPEGImageEncoder()
UsePNGImageDecoder()
UsePNGImageEncoder()
EnsureElevatedOrRelaunch()
AcquireSingleInstanceMutex()
RestoreIfDirtySession()
LoadSettings()
LoadGames()
InitFonts()
RunApplication()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 73
; FirstLine = 42
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = MyGameBooster.ico
; Executable = ..\MyGameBooster.exe
; IncludeVersionInfo
; VersionField0 = 1,0,1,3
; VersionField1 = 1,0,1,3
; VersionField2 = ZoneSoft
; VersionField3 = MyGameBooster
; VersionField4 = 1.0.1.3
; VersionField5 = 1.0.1.3
; VersionField6 = A Game Booster for boosting your games
; VersionField7 = MyGameBooster
; VersionField8 = MyGameBooster.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60