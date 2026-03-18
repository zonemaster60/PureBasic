; PureBasic 6.30 x64 - Safe Game Booster (MVP)
; - Launch EXE directly or via Steam
; - Set priority + optional affinity
; - Always switch to High performance while boosting and restore after

EnableExplicit

#APP_NAME = "SafeGameBooster"
#APP_MUTEX_NAME = #APP_NAME + "_mutex"

Global DataDir.s, GamesIni.s, SessionIni.s
DataDir = GetPathPart(ProgramFilename())
GamesIni = DataDir + "games.ini"
SessionIni = DataDir + "session.ini"
Global LogPath.s
LogPath = DataDir + #APP_NAME + ".log"

Global FontUI.i, FontTitle.i, FontSmall.i
Global MainStatusBar.i
Global version.s = "v1.0.0.4"
Global BrowseExePath.s, BeforeCount.i, LaunchUiPulse.i

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

#DIRID_STEAM_MANIFESTS = 1
#DIRID_FOLDER_SCAN_ROOT = 2
#DIRID_ANYFILE_CHECK = 10
#FOLDER_SCAN_DEPTH = 3

#TH32CS_SNAPPROCESS  = $00000002
#TH32CS_SNAPMODULE   = $00000008
#TH32CS_SNAPMODULE32 = $00000010

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
  SteamClientArgs.s
  SteamGameArgs.s
  SteamDetectTimeoutMs.i
  GameRoot.s
EndStructure

Structure OC_TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

Structure BoostSessionContext
  PrevPowerGuid.s
  DidSwitchPower.i
  StoppedServices.s
EndStructure

Structure ServiceInfo
  Name.s
  DisplayName.s
  Status.s
  StartType.s
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

Global NewList Games.GameEntry()
Global LaunchActive.i, LaunchState.i, AppQuitting.i
Global LaunchGame.GameEntry
Global LaunchCtx.BoostSessionContext
Global LaunchProcess.i, LaunchDetectDeadline.i
Global LaunchOrigPriority.l
Global LaunchProcessAffinity.q, LaunchSystemAffinity.q
Global LaunchGotAffinity.i
Global LaunchGameRoot.s
Global NewMap LaunchBaseline.i()

Enumeration Gadgets
  #G_List
  #G_Title
  #G_Subtitle
  #G_LaunchState
  #G_CancelWait
  #G_Edit
  #G_Launch
EndEnumeration

Enumeration Menus
  #Menu_Main
EndEnumeration

Enumeration MenuItems
  #MI_File_Add
  #MI_File_BrowseExe
  #MI_File_AddFolder
  #MI_File_ImportSteam
  #MI_File_Exit
  #MI_Game_Run
  #MI_Game_Edit
  #MI_Game_Remove
  #MI_Game_OpenFolder
  #MI_Tools_ViewLog
  #MI_Help_Help
  #MI_Help_About
EndEnumeration

XIncludeFile "SafeGameBooster.Declarations.pbi"
XIncludeFile "SafeGameBooster.Core.pbi"
XIncludeFile "SafeGameBooster.SteamServices.pbi"
XIncludeFile "SafeGameBooster.Games.pbi"
XIncludeFile "SafeGameBooster.App.pbi"

EnsureElevatedOrRelaunch()
AcquireSingleInstanceMutex()
RestoreIfDirtySession()
LoadGames()
InitFonts()
RunApplication()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 19
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = SafeGameBooster.ico
; Executable = ..\SafeGameBooster.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = SafeGameBooster
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = A Safe Game Booster made with PureBasic
; VersionField7 = SafeGameBooster
; VersionField8 = SafeGameBooster.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60