; AdventureGen: The Arcane Edition (Standalone Build System)
; ==========================================================
; PureBasic v6.40 (x64) - Supports dynamic story generation and EXE export

EnableExplicit

XIncludeFile "config_defaults.pbi"
XIncludeFile "app_core.pbi"
XIncludeFile "app_helpers.pbi"
XIncludeFile "app_content.pbi"
XIncludeFile "app_world.pbi"
XIncludeFile "app_export.pbi"
XIncludeFile "app_ui.pbi"

Main()

DataSection
  ThemesStart: : IncludeBinary "data/themes.csv" : ThemesEnd:
  HelpStart: : IncludeBinary "HELP.md" : HelpEnd:
EndDataSection

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 13
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = main.ico
; Executable = ..\AdventureGen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = AdventureGen
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = An automated text adventure creator with theme
; VersionField7 = AdventureGen
; VersionField8 = AdventureGen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60