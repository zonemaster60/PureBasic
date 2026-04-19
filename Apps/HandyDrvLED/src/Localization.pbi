; HandyDrvLED Localization

Structure AppStrings
  AppName.s
  InfoTitle.s
  ErrorTitle.s
  About.s
  Help.s
  Drives.s
  Diagnostics.s
  Reload.s
  Edit.s
  Startup.s
  Logging.s
  PdhOnly.s
  Exit.s
  ExitPrompt.s
  Enabled.s
  Disabled.s
  Capacity.s
  Used.s
  Free.s
  VolumeName.s
  VolumeID.s
  FileSystem.s
  Drive.s
  Open.s
  Info.s
  Copy.s
  Close.s
  Fixed.s
  Removable.s
  Network.s
  CdRom.s
  RamDisk.s
  NoDrivesMatch.s
  DriveInfoError.s
  StartupEnable.s
  StartupDisable.s
  LoggingEnable.s
  LoggingDisable.s
  StartingMonitor.s
  PdhFallbackActive.s
  AlreadyRunning.s
  StartupInstallError.s
  StartupRemoveError.s
  StartupChangeError.s
  StartupChangePending.s
  EditSettingsTitle.s
  MonitoringTitle.s
  UpdateIntervalLabel.s
  TooltipIntervalLabel.s
  ActivityThresholdLabel.s
  ActivityHoldLabel.s
  PdhSampleIntervalLabel.s
  IoctlBackoffLabel.s
  StartupIconsTitle.s
  DefaultIconSetLabel.s
  StartRandomIconSetLabel.s
  ForcePdhDefaultLabel.s
  EnableLoggingLabel.s
  EnableLogRotationLabel.s
  RotateKeepFilesLabel.s
  RotateMaxKbLabel.s
  Ok.s
  Cancel.s
  SettingsSavedTitle.s
  SettingsSavedMessage.s
  KeepLabel.s
  MaxKbLabel.s
  AboutTitle.s
  AboutUpdateInterval.s
  AboutPdhFallbackDefault.s
  AboutLogRotation.s
  AboutIniFile.s
  Contact.s
  Website.s
  UsingIconSet.s
  HelpTitle.s
  HelpTrayIconTitle.s
  HelpTrayIconLine1.s
  HelpTrayIconLine2.s
  HelpLoggingTitle.s
  HelpLoggingLine1.s
  HelpLoggingLine2.s
  HelpLoggingLine3.s
  HelpLoggingLine4.s
  HelpActivityTitle.s
  HelpActivityLine1.s
  HelpTrayMenuTitle.s
  HelpTrayMenuLine1.s
  HelpTrayMenuLine2.s
  HelpTrayMenuLine3.s
  HelpTrayMenuLine4.s
  HelpTrayMenuLine5.s
  HelpTrayMenuLine6.s
  HelpDrivesTitle.s
  HelpDrivesLine1.s
  HelpDrivesLine2.s
  HelpConfigLabel.s
  DiagIoctlLastError.s
  DiagRawDriveDisabled.s
  DiagForcePdhActive.s
  DiagPdhInitialized.s
  DiagPdhQueryHandle.s
  DiagPdhInitStage.s
  DiagPdhCounterSource.s
  DiagPdhInitStatus.s
  DiagPdhCollectStatus.s
  DiagPdhReadStatus.s
  DiagPdhWriteStatus.s
  DiagLogFile.s
  DiagLogRotation.s
EndStructure

Global Lng.AppStrings

Procedure LoadLanguage(lang.s = "EN")
  Select UCase(lang)
    Case "EN"
      Lng\AppName = "HandyDrvLED"
      Lng\InfoTitle = "Info"
      Lng\ErrorTitle = "Error"
      Lng\About = "About"
      Lng\Help = "Help"
      Lng\Drives = "Drive(s)"
      Lng\Diagnostics = "Diagnostics"
      Lng\Reload = "Reload Settings"
      Lng\Edit = "Edit Settings"
      Lng\Startup = "Run at Startup"
      Lng\Logging = "Logging"
      Lng\PdhOnly = "Use PDH only"
      Lng\Exit = "Exit"
      Lng\ExitPrompt = "Do you want to exit now?"
      Lng\Enabled = "Enabled"
      Lng\Disabled = "Disabled"
      Lng\Capacity = "Capacity"
      Lng\Used = "Used"
      Lng\Free = "Free"
      Lng\VolumeName = "VolumeName"
      Lng\VolumeID = "VolumeID"
      Lng\FileSystem = "FileSystem"
      Lng\Drive = "Drive"
      Lng\Open = "Open"
      Lng\Info = "Info"
      Lng\Copy = "Copy"
      Lng\Close = "Close"
      Lng\Fixed = "Fixed"
      Lng\Removable = "Removable"
      Lng\Network = "Network"
      Lng\CdRom = "CD-ROM"
      Lng\RamDisk = "RAM Disk"
      Lng\NoDrivesMatch = "No drives match the current filters."
      Lng\DriveInfoError = "Could not retrieve info for "
      Lng\StartupEnable = "Enable Run at Startup"
      Lng\StartupDisable = "Disable Run at Startup"
      Lng\LoggingEnable = "Enable Logging"
      Lng\LoggingDisable = "Disable Logging"
      Lng\StartingMonitor = "Starting monitor..."
      Lng\PdhFallbackActive = "PDH fallback active (physical drive access denied)"
      Lng\AlreadyRunning = "HandyDrvLED is already running."
      Lng\StartupInstallError = "Unable to install startup task."
      Lng\StartupRemoveError = "Unable to remove startup task."
      Lng\StartupChangeError = "Unable to change startup setting."
      Lng\StartupChangePending = "The startup change request was launched, but completion could not be confirmed yet."
      Lng\EditSettingsTitle = "Edit Settings"
      Lng\MonitoringTitle = "Monitoring"
      Lng\UpdateIntervalLabel = "Update Interval (ms):"
      Lng\TooltipIntervalLabel = "Tooltip Interval (ms):"
      Lng\ActivityThresholdLabel = "Activity Threshold Bps:"
      Lng\ActivityHoldLabel = "Activity Hold (ms):"
      Lng\PdhSampleIntervalLabel = "PDH Sample Interval (ms):"
      Lng\IoctlBackoffLabel = "IOCTL Backoff Cycles:"
      Lng\StartupIconsTitle = "Startup and Icons"
      Lng\DefaultIconSetLabel = "Default Icon Set:"
      Lng\StartRandomIconSetLabel = "Start with Random Icon Set"
      Lng\ForcePdhDefaultLabel = "Use PDH Only by Default"
      Lng\EnableLoggingLabel = "Enable Logging"
      Lng\EnableLogRotationLabel = "Enable Log Rotation"
      Lng\RotateKeepFilesLabel = "Rotate Keep Files:"
      Lng\RotateMaxKbLabel = "Rotate Max KB:"
      Lng\Ok = "OK"
      Lng\Cancel = "Cancel"
      Lng\SettingsSavedTitle = "Settings Saved"
      Lng\SettingsSavedMessage = "Settings have been saved successfully."
      Lng\KeepLabel = "keep"
      Lng\MaxKbLabel = "maxKB"
      Lng\AboutTitle = "About"
      Lng\AboutUpdateInterval = "Update interval"
      Lng\AboutPdhFallbackDefault = "PDH fallback default"
      Lng\AboutLogRotation = "Log rotation"
      Lng\AboutIniFile = "INI file"
      Lng\Contact = "Contact"
      Lng\Website = "Website"
      Lng\UsingIconSet = "Using IconSet"
      Lng\HelpTitle = "Help"
      Lng\HelpTrayIconTitle = "Tray icon"
      Lng\HelpTrayIconLine1 = "Right-click for options."
      Lng\HelpTrayIconLine2 = "Colors: RED=Write, GREEN=Read, BLUE=Both, YELLOW=Idle"
      Lng\HelpLoggingTitle = "Logging"
      Lng\HelpLoggingLine1 = "Logging can be enabled or disabled from the tray menu."
      Lng\HelpLoggingLine2 = "Writes to HandyDrvLED.log in Logs\\ next to the EXE when writable."
      Lng\HelpLoggingLine3 = "Rotates to HandyDrvLED.log.1, .2, .3 based on size."
      Lng\HelpLoggingLine4 = "Settings are stored in HandyDrvLED.ini."
      Lng\HelpActivityTitle = "Activity detection"
      Lng\HelpActivityLine1 = "Uses IOCTL_DISK_PERFORMANCE or PDH fallback."
      Lng\HelpTrayMenuTitle = "Tray menu"
      Lng\HelpTrayMenuLine1 = "About: Version info."
      Lng\HelpTrayMenuLine2 = "Drive(s): Open drive browser."
      Lng\HelpTrayMenuLine3 = "Diagnostics: IOCTL/PDH status."
      Lng\HelpTrayMenuLine4 = "Reload Settings/Edit Settings: Manage config."
      Lng\HelpTrayMenuLine5 = "Run at Startup: Toggle auto-start."
      Lng\HelpTrayMenuLine6 = "Logging: Enable or disable logging."
      Lng\HelpDrivesTitle = "Drive(s) window"
      Lng\HelpDrivesLine1 = "View capacity, free space, and filesystem info."
      Lng\HelpDrivesLine2 = "Supports Fixed, Removable, Network, CD-ROM, RAM Disk."
      Lng\HelpConfigLabel = "Config"
      Lng\DiagIoctlLastError = "IOCTL Last Error"
      Lng\DiagRawDriveDisabled = "Raw Drive Disabled"
      Lng\DiagForcePdhActive = "Force PDH Active"
      Lng\DiagPdhInitialized = "PDH Initialized"
      Lng\DiagPdhQueryHandle = "PDH Query Handle"
      Lng\DiagPdhInitStage = "PDH Init Stage"
      Lng\DiagPdhCounterSource = "PDH Counter Source"
      Lng\DiagPdhInitStatus = "PDH Init Status"
      Lng\DiagPdhCollectStatus = "PDH Collect Status"
      Lng\DiagPdhReadStatus = "PDH Read Status"
      Lng\DiagPdhWriteStatus = "PDH Write Status"
      Lng\DiagLogFile = "Log File"
      Lng\DiagLogRotation = "Log Rotation"
    ; Add more languages here
  EndSelect
EndProcedure

LoadLanguage() ; Default to English
