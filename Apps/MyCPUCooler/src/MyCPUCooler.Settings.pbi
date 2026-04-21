Procedure.s SettingsRegistryKey()
  ProcedureReturn #REG_BASE$ + "\\Settings"
EndProcedure

Procedure.s RunRegistryKey()
  ProcedureReturn "Software\\Microsoft\\Windows\\CurrentVersion\\Run"
EndProcedure

Procedure InitDefaultSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACProfile = #PROFILE_COOL
  *settings\DCProfile = #PROFILE_BALANCED
  ApplyProfileToSettings(#PROFILE_COOL, *settings)
  *settings\DCMaxCPU = 85
  *settings\AutoApply = 1
  *settings\LiveApply = 0
  *settings\RunAtStartup = 0
  *settings\UseTaskScheduler = 1
  *settings\HeatAlertEnabled = 1
  *settings\HeatAlertThreshold = 80
  *settings\AutoThermalSwitchEnabled = 0
  *settings\AutoThermalSwitchProfile = #PROFILE_COOL
  *settings\AutoThermalSwitchSeconds = 30
  *settings\StartupMode = 0
  *settings\AutoRestoreEnabled = 1
  *settings\AutoRestoreThreshold = 70
  *settings\AutoRestoreSeconds = 45
  *settings\ACAutoSwitchEnabled = 0
  *settings\DCAutoSwitchEnabled = 1
  *settings\ACAutoSwitchProfile = #PROFILE_QUIET
  *settings\DCAutoSwitchProfile = #PROFILE_BATTERY_SAVER
  *settings\ACAutoSwitchThreshold = 85
  *settings\DCAutoSwitchThreshold = 80
  *settings\ACAutoSwitchSeconds = 30
  *settings\DCAutoSwitchSeconds = 20
  *settings\ACAutoRestoreEnabled = 1
  *settings\DCAutoRestoreEnabled = 1
  *settings\ACAutoRestoreThreshold = 72
  *settings\DCAutoRestoreThreshold = 68
  *settings\ACAutoRestoreSeconds = 45
  *settings\DCAutoRestoreSeconds = 60
  *settings\SchemeGuid = ""
EndProcedure

Procedure LoadSettingsFromRegistry(settingsKey$, *settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\SchemeGuid = RegReadString(settingsKey$, "SchemeGuid", *settings\SchemeGuid)
  *settings\ACMaxCPU   = RegReadDword(settingsKey$, "AC_MaxCPU", *settings\ACMaxCPU)
  *settings\DCMaxCPU   = RegReadDword(settingsKey$, "DC_MaxCPU", *settings\DCMaxCPU)
  *settings\ACMinCPU   = RegReadDword(settingsKey$, "AC_MinCPU", *settings\ACMinCPU)
  *settings\DCMinCPU   = RegReadDword(settingsKey$, "DC_MinCPU", *settings\DCMinCPU)
  *settings\ACProfile  = RegReadDword(settingsKey$, "AC_Profile", *settings\ACProfile)
  *settings\DCProfile  = RegReadDword(settingsKey$, "DC_Profile", *settings\DCProfile)
  *settings\BoostMode  = RegReadDword(settingsKey$, "BoostMode", *settings\BoostMode)
  *settings\CoolingPolicy = RegReadDword(settingsKey$, "CoolingPolicy", *settings\CoolingPolicy)
  *settings\ASPMMode   = RegReadDword(settingsKey$, "ASPMMode", *settings\ASPMMode)
  *settings\ACBoostMode = RegReadDword(settingsKey$, "AC_BoostMode", *settings\BoostMode)
  *settings\DCBoostMode = RegReadDword(settingsKey$, "DC_BoostMode", *settings\BoostMode)
  *settings\ACCoolingPolicy = RegReadDword(settingsKey$, "AC_CoolingPolicy", *settings\CoolingPolicy)
  *settings\DCCoolingPolicy = RegReadDword(settingsKey$, "DC_CoolingPolicy", *settings\CoolingPolicy)
  *settings\ACASPMMode = RegReadDword(settingsKey$, "AC_ASPMMode", *settings\ASPMMode)
  *settings\DCASPMMode = RegReadDword(settingsKey$, "DC_ASPMMode", *settings\ASPMMode)
  *settings\AutoApply  = RegReadDword(settingsKey$, "AutoApply", *settings\AutoApply)
  *settings\LiveApply  = RegReadDword(settingsKey$, "LiveApply", *settings\LiveApply)
  *settings\RunAtStartup     = RegReadDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  *settings\UseTaskScheduler = RegReadDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)
  *settings\HeatAlertEnabled = RegReadDword(settingsKey$, "HeatAlertEnabled", *settings\HeatAlertEnabled)
  *settings\HeatAlertThreshold = RegReadDword(settingsKey$, "HeatAlertThreshold", *settings\HeatAlertThreshold)
  *settings\AutoThermalSwitchEnabled = RegReadDword(settingsKey$, "AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
  *settings\AutoThermalSwitchProfile = RegReadDword(settingsKey$, "AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
  *settings\AutoThermalSwitchSeconds = RegReadDword(settingsKey$, "AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
  *settings\StartupMode = RegReadDword(settingsKey$, "StartupMode", *settings\StartupMode)
  *settings\AutoRestoreEnabled = RegReadDword(settingsKey$, "AutoRestoreEnabled", *settings\AutoRestoreEnabled)
  *settings\AutoRestoreThreshold = RegReadDword(settingsKey$, "AutoRestoreThreshold", *settings\AutoRestoreThreshold)
  *settings\AutoRestoreSeconds = RegReadDword(settingsKey$, "AutoRestoreSeconds", *settings\AutoRestoreSeconds)
  *settings\ACAutoSwitchEnabled = RegReadDword(settingsKey$, "ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
  *settings\DCAutoSwitchEnabled = RegReadDword(settingsKey$, "DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
  *settings\ACAutoSwitchProfile = RegReadDword(settingsKey$, "ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
  *settings\DCAutoSwitchProfile = RegReadDword(settingsKey$, "DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
  *settings\ACAutoSwitchThreshold = RegReadDword(settingsKey$, "ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
  *settings\DCAutoSwitchThreshold = RegReadDword(settingsKey$, "DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
  *settings\ACAutoSwitchSeconds = RegReadDword(settingsKey$, "ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
  *settings\DCAutoSwitchSeconds = RegReadDword(settingsKey$, "DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
  *settings\ACAutoRestoreEnabled = RegReadDword(settingsKey$, "ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
  *settings\DCAutoRestoreEnabled = RegReadDword(settingsKey$, "DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
  *settings\ACAutoRestoreThreshold = RegReadDword(settingsKey$, "ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
  *settings\DCAutoRestoreThreshold = RegReadDword(settingsKey$, "DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
  *settings\ACAutoRestoreSeconds = RegReadDword(settingsKey$, "ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
  *settings\DCAutoRestoreSeconds = RegReadDword(settingsKey$, "DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
  *settings\BenchmarkModeEnabled = RegReadDword(settingsKey$, "BenchmarkModeEnabled", *settings\BenchmarkModeEnabled)
  *settings\BenchmarkModeEndsAt = RegReadDword(settingsKey$, "BenchmarkModeEndsAt", *settings\BenchmarkModeEndsAt)
EndProcedure

Procedure LoadSettingsFromIni(iniPath$, *settings.AppSettings)
  If *settings = 0 Or FileSize(iniPath$) < 0
    ProcedureReturn
  EndIf

  If OpenPreferences(iniPath$)
    PreferenceGroup("Settings")
    *settings\SchemeGuid = ReadPreferenceString("SchemeGuid", *settings\SchemeGuid)
    *settings\ACMaxCPU   = ReadPreferenceLong("AC_MaxCPU", *settings\ACMaxCPU)
    *settings\DCMaxCPU   = ReadPreferenceLong("DC_MaxCPU", *settings\DCMaxCPU)
    *settings\ACMinCPU   = ReadPreferenceLong("AC_MinCPU", *settings\ACMinCPU)
    *settings\DCMinCPU   = ReadPreferenceLong("DC_MinCPU", *settings\DCMinCPU)
    *settings\ACProfile  = ProfileNameToId(ReadPreferenceString("AC_Profile", ProfileIdToName(*settings\ACProfile)))
    *settings\DCProfile  = ProfileNameToId(ReadPreferenceString("DC_Profile", ProfileIdToName(*settings\DCProfile)))
    *settings\BoostMode    = ReadPreferenceLong("BoostMode", *settings\BoostMode)
    *settings\CoolingPolicy = ReadPreferenceLong("CoolingPolicy", *settings\CoolingPolicy)
    *settings\ASPMMode     = ReadPreferenceLong("ASPMMode", *settings\ASPMMode)
    *settings\ACBoostMode = ReadPreferenceLong("AC_BoostMode", *settings\BoostMode)
    *settings\DCBoostMode = ReadPreferenceLong("DC_BoostMode", *settings\BoostMode)
    *settings\ACCoolingPolicy = ReadPreferenceLong("AC_CoolingPolicy", *settings\CoolingPolicy)
    *settings\DCCoolingPolicy = ReadPreferenceLong("DC_CoolingPolicy", *settings\CoolingPolicy)
    *settings\ACASPMMode = ReadPreferenceLong("AC_ASPMMode", *settings\ASPMMode)
    *settings\DCASPMMode = ReadPreferenceLong("DC_ASPMMode", *settings\ASPMMode)
    *settings\AutoApply    = ReadPreferenceLong("AutoApply", *settings\AutoApply)
    *settings\LiveApply    = ReadPreferenceLong("LiveApply", *settings\LiveApply)
    *settings\RunAtStartup     = ReadPreferenceLong("RunAtStartup", *settings\RunAtStartup)
    *settings\UseTaskScheduler = ReadPreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
    *settings\HeatAlertEnabled = ReadPreferenceLong("HeatAlertEnabled", *settings\HeatAlertEnabled)
    *settings\HeatAlertThreshold = ReadPreferenceLong("HeatAlertThreshold", *settings\HeatAlertThreshold)
    *settings\AutoThermalSwitchEnabled = ReadPreferenceLong("AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
    *settings\AutoThermalSwitchProfile = ReadPreferenceLong("AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
    *settings\AutoThermalSwitchSeconds = ReadPreferenceLong("AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
    *settings\StartupMode = ReadPreferenceLong("StartupMode", *settings\StartupMode)
    *settings\AutoRestoreEnabled = ReadPreferenceLong("AutoRestoreEnabled", *settings\AutoRestoreEnabled)
    *settings\AutoRestoreThreshold = ReadPreferenceLong("AutoRestoreThreshold", *settings\AutoRestoreThreshold)
    *settings\AutoRestoreSeconds = ReadPreferenceLong("AutoRestoreSeconds", *settings\AutoRestoreSeconds)
    *settings\ACAutoSwitchEnabled = ReadPreferenceLong("ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
    *settings\DCAutoSwitchEnabled = ReadPreferenceLong("DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
    *settings\ACAutoSwitchProfile = ReadPreferenceLong("ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
    *settings\DCAutoSwitchProfile = ReadPreferenceLong("DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
    *settings\ACAutoSwitchThreshold = ReadPreferenceLong("ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
    *settings\DCAutoSwitchThreshold = ReadPreferenceLong("DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
    *settings\ACAutoSwitchSeconds = ReadPreferenceLong("ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
    *settings\DCAutoSwitchSeconds = ReadPreferenceLong("DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
    *settings\ACAutoRestoreEnabled = ReadPreferenceLong("ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
    *settings\DCAutoRestoreEnabled = ReadPreferenceLong("DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
    *settings\ACAutoRestoreThreshold = ReadPreferenceLong("ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
    *settings\DCAutoRestoreThreshold = ReadPreferenceLong("DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
    *settings\ACAutoRestoreSeconds = ReadPreferenceLong("ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
    *settings\DCAutoRestoreSeconds = ReadPreferenceLong("DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
    *settings\BenchmarkModeEnabled = ReadPreferenceLong("BenchmarkModeEnabled", *settings\BenchmarkModeEnabled)
    *settings\BenchmarkModeEndsAt = ReadPreferenceLong("BenchmarkModeEndsAt", *settings\BenchmarkModeEndsAt)
    ClosePreferences()
  EndIf
EndProcedure

Procedure NormalizeAppSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACMaxCPU = ClampPercent(*settings\ACMaxCPU, 5, 100)
  *settings\DCMaxCPU = ClampPercent(*settings\DCMaxCPU, 5, 100)
  *settings\ACMinCPU = ClampPercent(*settings\ACMinCPU, 1, 100)
  *settings\DCMinCPU = ClampPercent(*settings\DCMinCPU, 1, 100)
  If *settings\ACMinCPU > *settings\ACMaxCPU : *settings\ACMinCPU = *settings\ACMaxCPU : EndIf
  If *settings\DCMinCPU > *settings\DCMaxCPU : *settings\DCMinCPU = *settings\DCMaxCPU : EndIf
  If *settings\ACCoolingPolicy <> 0 And *settings\ACCoolingPolicy <> 1 : *settings\ACCoolingPolicy = 0 : EndIf
  If *settings\DCCoolingPolicy <> 0 And *settings\DCCoolingPolicy <> 1 : *settings\DCCoolingPolicy = 1 : EndIf
  If *settings\ACASPMMode < 0 Or *settings\ACASPMMode > 2 : *settings\ACASPMMode = 1 : EndIf
  If *settings\DCASPMMode < 0 Or *settings\DCASPMMode > 2 : *settings\DCASPMMode = 2 : EndIf
  If *settings\ACBoostMode < #BOOST_DISABLED Or *settings\ACBoostMode > #BOOST_EFFICIENT_AGGRESSIVE : *settings\ACBoostMode = #BOOST_DISABLED : EndIf
  If *settings\DCBoostMode < #BOOST_DISABLED Or *settings\DCBoostMode > #BOOST_EFFICIENT_AGGRESSIVE : *settings\DCBoostMode = #BOOST_DISABLED : EndIf
  If *settings\HeatAlertThreshold < 60 : *settings\HeatAlertThreshold = 60 : EndIf
  If *settings\HeatAlertThreshold > 100 : *settings\HeatAlertThreshold = 100 : EndIf
  If *settings\AutoThermalSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\AutoThermalSwitchProfile > #PROFILE_PERFORMANCE : *settings\AutoThermalSwitchProfile = #PROFILE_COOL : EndIf
  If *settings\AutoThermalSwitchSeconds < 10 : *settings\AutoThermalSwitchSeconds = 10 : EndIf
  If *settings\AutoThermalSwitchSeconds > 120 : *settings\AutoThermalSwitchSeconds = 120 : EndIf
  If *settings\StartupMode < 0 Or *settings\StartupMode > 3 : *settings\StartupMode = 0 : EndIf
  If *settings\AutoRestoreThreshold < 50 : *settings\AutoRestoreThreshold = 50 : EndIf
  If *settings\AutoRestoreThreshold > 95 : *settings\AutoRestoreThreshold = 95 : EndIf
  If *settings\AutoRestoreSeconds < 15 : *settings\AutoRestoreSeconds = 15 : EndIf
  If *settings\AutoRestoreSeconds > 180 : *settings\AutoRestoreSeconds = 180 : EndIf
  If *settings\ACAutoSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\ACAutoSwitchProfile > #PROFILE_PERFORMANCE : *settings\ACAutoSwitchProfile = #PROFILE_QUIET : EndIf
  If *settings\DCAutoSwitchProfile < #PROFILE_BATTERY_SAVER Or *settings\DCAutoSwitchProfile > #PROFILE_PERFORMANCE : *settings\DCAutoSwitchProfile = #PROFILE_BATTERY_SAVER : EndIf
  If *settings\ACAutoSwitchThreshold < 60 : *settings\ACAutoSwitchThreshold = 60 : EndIf
  If *settings\ACAutoSwitchThreshold > 100 : *settings\ACAutoSwitchThreshold = 100 : EndIf
  If *settings\DCAutoSwitchThreshold < 60 : *settings\DCAutoSwitchThreshold = 60 : EndIf
  If *settings\DCAutoSwitchThreshold > 100 : *settings\DCAutoSwitchThreshold = 100 : EndIf
  If *settings\ACAutoSwitchSeconds < 10 : *settings\ACAutoSwitchSeconds = 10 : EndIf
  If *settings\ACAutoSwitchSeconds > 180 : *settings\ACAutoSwitchSeconds = 180 : EndIf
  If *settings\DCAutoSwitchSeconds < 10 : *settings\DCAutoSwitchSeconds = 10 : EndIf
  If *settings\DCAutoSwitchSeconds > 180 : *settings\DCAutoSwitchSeconds = 180 : EndIf
  If *settings\ACAutoRestoreThreshold < 50 : *settings\ACAutoRestoreThreshold = 50 : EndIf
  If *settings\ACAutoRestoreThreshold > 95 : *settings\ACAutoRestoreThreshold = 95 : EndIf
  If *settings\DCAutoRestoreThreshold < 50 : *settings\DCAutoRestoreThreshold = 50 : EndIf
  If *settings\DCAutoRestoreThreshold > 95 : *settings\DCAutoRestoreThreshold = 95 : EndIf
  If *settings\ACAutoRestoreSeconds < 15 : *settings\ACAutoRestoreSeconds = 15 : EndIf
  If *settings\ACAutoRestoreSeconds > 240 : *settings\ACAutoRestoreSeconds = 240 : EndIf
  If *settings\DCAutoRestoreSeconds < 15 : *settings\DCAutoRestoreSeconds = 15 : EndIf
  If *settings\DCAutoRestoreSeconds > 240 : *settings\DCAutoRestoreSeconds = 240 : EndIf
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
EndProcedure

Procedure WriteSettingsToRegistry(settingsKey$, *settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  RegWriteString(settingsKey$, "SchemeGuid", *settings\SchemeGuid)
  RegWriteDword(settingsKey$, "AC_MaxCPU", *settings\ACMaxCPU)
  RegWriteDword(settingsKey$, "DC_MaxCPU", *settings\DCMaxCPU)
  RegWriteDword(settingsKey$, "AC_MinCPU", *settings\ACMinCPU)
  RegWriteDword(settingsKey$, "DC_MinCPU", *settings\DCMinCPU)
  RegWriteDword(settingsKey$, "AC_Profile", *settings\ACProfile)
  RegWriteDword(settingsKey$, "DC_Profile", *settings\DCProfile)
  RegWriteDword(settingsKey$, "BoostMode", *settings\BoostMode)
  RegWriteDword(settingsKey$, "CoolingPolicy", *settings\CoolingPolicy)
  RegWriteDword(settingsKey$, "ASPMMode", *settings\ASPMMode)
  RegWriteDword(settingsKey$, "AC_BoostMode", *settings\ACBoostMode)
  RegWriteDword(settingsKey$, "DC_BoostMode", *settings\DCBoostMode)
  RegWriteDword(settingsKey$, "AC_CoolingPolicy", *settings\ACCoolingPolicy)
  RegWriteDword(settingsKey$, "DC_CoolingPolicy", *settings\DCCoolingPolicy)
  RegWriteDword(settingsKey$, "AC_ASPMMode", *settings\ACASPMMode)
  RegWriteDword(settingsKey$, "DC_ASPMMode", *settings\DCASPMMode)
  RegWriteDword(settingsKey$, "AutoApply", *settings\AutoApply)
  RegWriteDword(settingsKey$, "LiveApply", *settings\LiveApply)
  RegWriteDword(settingsKey$, "RunAtStartup", *settings\RunAtStartup)
  RegWriteDword(settingsKey$, "UseTaskScheduler", *settings\UseTaskScheduler)
  RegWriteDword(settingsKey$, "HeatAlertEnabled", *settings\HeatAlertEnabled)
  RegWriteDword(settingsKey$, "HeatAlertThreshold", *settings\HeatAlertThreshold)
  RegWriteDword(settingsKey$, "AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
  RegWriteDword(settingsKey$, "AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
  RegWriteDword(settingsKey$, "AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
  RegWriteDword(settingsKey$, "StartupMode", *settings\StartupMode)
  RegWriteDword(settingsKey$, "AutoRestoreEnabled", *settings\AutoRestoreEnabled)
  RegWriteDword(settingsKey$, "AutoRestoreThreshold", *settings\AutoRestoreThreshold)
  RegWriteDword(settingsKey$, "AutoRestoreSeconds", *settings\AutoRestoreSeconds)
  RegWriteDword(settingsKey$, "ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
  RegWriteDword(settingsKey$, "DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
  RegWriteDword(settingsKey$, "ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
  RegWriteDword(settingsKey$, "DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
  RegWriteDword(settingsKey$, "ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
  RegWriteDword(settingsKey$, "DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
  RegWriteDword(settingsKey$, "ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
  RegWriteDword(settingsKey$, "DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
  RegWriteDword(settingsKey$, "ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
  RegWriteDword(settingsKey$, "DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
  RegWriteDword(settingsKey$, "ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
  RegWriteDword(settingsKey$, "DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
  RegWriteDword(settingsKey$, "ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
  RegWriteDword(settingsKey$, "DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
  RegWriteDword(settingsKey$, "BenchmarkModeEnabled", *settings\BenchmarkModeEnabled)
  RegWriteDword(settingsKey$, "BenchmarkModeEndsAt", *settings\BenchmarkModeEndsAt)
EndProcedure

Procedure WriteSettingsToIni(iniPath$, *settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If OpenPreferences(iniPath$)
    PreferenceGroup("Settings")
    WritePreferenceString("SchemeGuid", *settings\SchemeGuid)
    WritePreferenceLong("AC_MaxCPU", *settings\ACMaxCPU)
    WritePreferenceLong("DC_MaxCPU", *settings\DCMaxCPU)
    WritePreferenceLong("AC_MinCPU", *settings\ACMinCPU)
    WritePreferenceLong("DC_MinCPU", *settings\DCMinCPU)
    WritePreferenceString("AC_Profile", ProfileIdToName(*settings\ACProfile))
    WritePreferenceString("DC_Profile", ProfileIdToName(*settings\DCProfile))
    WritePreferenceLong("BoostMode", *settings\BoostMode)
    WritePreferenceLong("CoolingPolicy", *settings\CoolingPolicy)
    WritePreferenceLong("ASPMMode", *settings\ASPMMode)
    WritePreferenceLong("AC_BoostMode", *settings\ACBoostMode)
    WritePreferenceLong("DC_BoostMode", *settings\DCBoostMode)
    WritePreferenceLong("AC_CoolingPolicy", *settings\ACCoolingPolicy)
    WritePreferenceLong("DC_CoolingPolicy", *settings\DCCoolingPolicy)
    WritePreferenceLong("AC_ASPMMode", *settings\ACASPMMode)
    WritePreferenceLong("DC_ASPMMode", *settings\DCASPMMode)
    WritePreferenceLong("AutoApply", *settings\AutoApply)
    WritePreferenceLong("LiveApply", *settings\LiveApply)
    WritePreferenceLong("RunAtStartup", *settings\RunAtStartup)
    WritePreferenceLong("UseTaskScheduler", *settings\UseTaskScheduler)
    WritePreferenceLong("HeatAlertEnabled", *settings\HeatAlertEnabled)
    WritePreferenceLong("HeatAlertThreshold", *settings\HeatAlertThreshold)
    WritePreferenceLong("AutoThermalSwitchEnabled", *settings\AutoThermalSwitchEnabled)
    WritePreferenceLong("AutoThermalSwitchProfile", *settings\AutoThermalSwitchProfile)
    WritePreferenceLong("AutoThermalSwitchSeconds", *settings\AutoThermalSwitchSeconds)
    WritePreferenceLong("StartupMode", *settings\StartupMode)
    WritePreferenceLong("AutoRestoreEnabled", *settings\AutoRestoreEnabled)
    WritePreferenceLong("AutoRestoreThreshold", *settings\AutoRestoreThreshold)
    WritePreferenceLong("AutoRestoreSeconds", *settings\AutoRestoreSeconds)
    WritePreferenceLong("ACAutoSwitchEnabled", *settings\ACAutoSwitchEnabled)
    WritePreferenceLong("DCAutoSwitchEnabled", *settings\DCAutoSwitchEnabled)
    WritePreferenceLong("ACAutoSwitchProfile", *settings\ACAutoSwitchProfile)
    WritePreferenceLong("DCAutoSwitchProfile", *settings\DCAutoSwitchProfile)
    WritePreferenceLong("ACAutoSwitchThreshold", *settings\ACAutoSwitchThreshold)
    WritePreferenceLong("DCAutoSwitchThreshold", *settings\DCAutoSwitchThreshold)
    WritePreferenceLong("ACAutoSwitchSeconds", *settings\ACAutoSwitchSeconds)
    WritePreferenceLong("DCAutoSwitchSeconds", *settings\DCAutoSwitchSeconds)
    WritePreferenceLong("ACAutoRestoreEnabled", *settings\ACAutoRestoreEnabled)
    WritePreferenceLong("DCAutoRestoreEnabled", *settings\DCAutoRestoreEnabled)
    WritePreferenceLong("ACAutoRestoreThreshold", *settings\ACAutoRestoreThreshold)
    WritePreferenceLong("DCAutoRestoreThreshold", *settings\DCAutoRestoreThreshold)
    WritePreferenceLong("ACAutoRestoreSeconds", *settings\ACAutoRestoreSeconds)
    WritePreferenceLong("DCAutoRestoreSeconds", *settings\DCAutoRestoreSeconds)
    WritePreferenceLong("BenchmarkModeEnabled", *settings\BenchmarkModeEnabled)
    WritePreferenceLong("BenchmarkModeEndsAt", *settings\BenchmarkModeEndsAt)
    ClosePreferences()
  EndIf
EndProcedure

Procedure DeleteScheduledStartupTask(taskName$)
  RunProgramCapture("schtasks.exe", "/Delete /F /TN " + Chr(34) + taskName$ + Chr(34))
EndProcedure

Procedure CreateScheduledStartupTask(taskName$, userAccount$, runValue$, workDir$)
  LogLine(#LOG_INFO, "Creating scheduled task: " + taskName$)
  RunProgramCapture("schtasks.exe", "/Create /F /TN " + Chr(34) + taskName$ + Chr(34) +
                                 " /SC ONLOGON /RL HIGHEST /RU " + Chr(34) + userAccount$ + Chr(34) +
                                 " /TR " + Chr(34) + runValue$ + Chr(34) +
                                 " /IT")
  If gLastExitCode <> 0
    LogLine(#LOG_ERROR, "schtasks create failed exit=" + Str(gLastExitCode))
    If gLastStdout <> "" : LogLine(#LOG_ERROR, "output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
    LogLine(#LOG_INFO, "Retrying scheduled task with cmd wrapper")
    RunProgramCapture("schtasks.exe", "/Create /F /TN " + Chr(34) + taskName$ + Chr(34) +
                                   " /SC ONLOGON /RL HIGHEST /RU " + Chr(34) + userAccount$ + Chr(34) +
                                   " /TR " + Chr(34) + "cmd.exe /c cd /d " + workDir$ + " && " + runValue$ + Chr(34) +
                                   " /IT")
    If gLastExitCode <> 0 And gLastStdout <> "" : LogLine(#LOG_ERROR, "retry output: " + ReplaceString(Trim(gLastStdout), #CRLF$, " | ")) : EndIf
  EndIf
EndProcedure

Procedure UpdateStartupRegistration(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  Protected runValue$ = StartupCommandLine(*settings)
  Protected workDir$ = Chr(34) + GetPathPart(ProgramFilename()) + Chr(34)
  Protected userAccount$ = CurrentUserAccount()
  Protected runKey$ = RunRegistryKey()
  Protected taskName$ = #APP_NAME

  If *settings\RunAtStartup And *settings\UseTaskScheduler = 0
    RegWriteString(runKey$, #APP_NAME, runValue$)
    LogLine(#LOG_INFO, "Run key updated: " + runValue$)
  Else
    RegDeleteValue(runKey$, #APP_NAME)
  EndIf

  If *settings\UseTaskScheduler
    If *settings\RunAtStartup
      CreateScheduledStartupTask(taskName$, userAccount$, runValue$, workDir$)
    Else
      LogLine(#LOG_INFO, "Deleting scheduled task: " + taskName$)
      DeleteScheduledStartupTask(taskName$)
      If gLastExitCode <> 0
        LogLine(#LOG_WARN, "schtasks delete exit=" + Str(gLastExitCode))
      EndIf
    EndIf
  Else
    LogLine(#LOG_INFO, "Task Scheduler disabled; ensuring task removed: " + taskName$)
    DeleteScheduledStartupTask(taskName$)
    If gLastExitCode <> 0
      LogLine(#LOG_DEBUG, "schtasks delete (cleanup) exit=" + Str(gLastExitCode))
    EndIf
  EndIf
EndProcedure


Procedure LoadAppSettings(iniPath$, *settings.AppSettings)
  Protected settingsKey$ = SettingsRegistryKey()

  InitDefaultSettings(*settings)
  LoadSettingsFromRegistry(settingsKey$, *settings)

  If *settings\SchemeGuid = ""
    LoadSettingsFromIni(iniPath$, *settings)
  EndIf

  NormalizeAppSettings(*settings)
EndProcedure


Procedure SaveAppSettings(iniPath$, *settings.AppSettings)
  ; Persist app settings
  LogLine(#LOG_INFO, "SaveAppSettings" +
                      " acMax=" + Str(*settings\ACMaxCPU) + " dcMax=" + Str(*settings\DCMaxCPU) +
                      " acMin=" + Str(*settings\ACMinCPU) + " dcMin=" + Str(*settings\DCMinCPU) +
                      " acBoost=" + Str(*settings\ACBoostMode) + " dcBoost=" + Str(*settings\DCBoostMode) +
                      " acCooling=" + Str(*settings\ACCoolingPolicy) + " dcCooling=" + Str(*settings\DCCoolingPolicy) +
                      " acASPM=" + Str(*settings\ACASPMMode) + " dcASPM=" + Str(*settings\DCASPMMode) +
                      " autoApply=" + Str(*settings\AutoApply) + " liveApply=" + Str(*settings\LiveApply) +
                      " runAtStartup=" + Str(*settings\RunAtStartup) + " useTaskScheduler=" + Str(*settings\UseTaskScheduler) +
                      " heatAlertEnabled=" + Str(*settings\HeatAlertEnabled) + " heatAlertThreshold=" + Str(*settings\HeatAlertThreshold) +
                      " autoSwitchEnabled=" + Str(*settings\AutoThermalSwitchEnabled) + " autoSwitchProfile=" + Str(*settings\AutoThermalSwitchProfile) +
                      " autoSwitchSeconds=" + Str(*settings\AutoThermalSwitchSeconds) + " startupMode=" + Str(*settings\StartupMode) +
                      " autoRestoreEnabled=" + Str(*settings\AutoRestoreEnabled) + " autoRestoreThreshold=" + Str(*settings\AutoRestoreThreshold) +
                      " autoRestoreSeconds=" + Str(*settings\AutoRestoreSeconds) +
                      " acAutoSwitchProfile=" + Str(*settings\ACAutoSwitchProfile) + " dcAutoSwitchProfile=" + Str(*settings\DCAutoSwitchProfile) +
                      " acAutoSwitchThreshold=" + Str(*settings\ACAutoSwitchThreshold) + " dcAutoSwitchThreshold=" + Str(*settings\DCAutoSwitchThreshold))
  Protected settingsKey$ = SettingsRegistryKey()
  gPendingSettingsSave = #False
  gPendingSettingsSaveAt = 0
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  WriteSettingsToRegistry(settingsKey$, *settings)
  WriteSettingsToIni(iniPath$, *settings)
  UpdateStartupRegistration(*settings)
EndProcedure

