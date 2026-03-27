; HandyDrvLED Localization

Structure AppStrings
  AppName.s
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
  Capacity.s
  Used.s
  Free.s
  VolumeName.s
  VolumeID.s
  FileSystem.s
  Open.s
  Info.s
  Copy.s
  Close.s
EndStructure

Global Lng.AppStrings

Procedure LoadLanguage(lang.s = "EN")
  Select UCase(lang)
    Case "EN"
      Lng\AppName = "HandyDrvLED"
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
      Lng\Capacity = "Capacity"
      Lng\Used = "Used"
      Lng\Free = "Free"
      Lng\VolumeName = "VolumeName"
      Lng\VolumeID = "VolumeID"
      Lng\FileSystem = "FileSystem"
      Lng\Open = "Open"
      Lng\Info = "Info"
      Lng\Copy = "Copy"
      Lng\Close = "Close"
    ; Add more languages here
  EndSelect
EndProcedure

LoadLanguage() ; Default to English
