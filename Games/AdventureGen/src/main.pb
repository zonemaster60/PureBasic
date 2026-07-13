; AdventureGen: The Arcane Edition (Standalone Build System)
; ==========================================================
; PureBasic v6.40 (x64) - Supports dynamic story generation and EXE export

EnableExplicit

XIncludeFile "includes\config_defaults.pbi"
XIncludeFile "includes\app_core.pbi"
XIncludeFile "includes\app_helpers.pbi"
XIncludeFile "includes\app_content.pbi"
XIncludeFile "includes\app_world.pbi"
XIncludeFile "includes\app_export.pbi"
XIncludeFile "includes\app_ui.pbi"

Main()

DataSection
  ThemesStart: : IncludeBinary "data/themes.csv" : ThemesEnd:
  HelpStart: : IncludeBinary "HELP.md" : HelpEnd:
EndDataSection

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 12
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = main.ico
; Executable = ..\AdventureGen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = AdventureGen
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = An automated text adventure creator with theme
; VersionField7 = AdventureGen
; VersionField8 = AdventureGen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60