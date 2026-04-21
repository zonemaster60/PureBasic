Procedure CopyTuningSettings(*src.AppSettings, *dst.AppSettings)
  If *src = 0 Or *dst = 0
    ProcedureReturn
  EndIf

  *dst\ACProfile = *src\ACProfile
  *dst\DCProfile = *src\DCProfile
  *dst\ACMaxCPU = *src\ACMaxCPU
  *dst\DCMaxCPU = *src\DCMaxCPU
  *dst\ACMinCPU = *src\ACMinCPU
  *dst\DCMinCPU = *src\DCMinCPU
  *dst\ACBoostMode = *src\ACBoostMode
  *dst\DCBoostMode = *src\DCBoostMode
  *dst\ACCoolingPolicy = *src\ACCoolingPolicy
  *dst\DCCoolingPolicy = *src\DCCoolingPolicy
  *dst\ACASPMMode = *src\ACASPMMode
  *dst\DCASPMMode = *src\DCASPMMode
  *dst\BoostMode = *src\ACBoostMode
  *dst\CoolingPolicy = *src\ACCoolingPolicy
  *dst\ASPMMode = *src\ACASPMMode
EndProcedure

Procedure LoadCustomProfiles()
  Protected i.i
  Protected key$
  ClearList(gCustomProfiles())

  If OpenPreferences(gIniPath)
    PreferenceGroup("CustomProfiles")
    For i = 0 To #MAX_CUSTOM_PROFILES - 1
      key$ = "Profile" + Str(i) + "_Name"
      If ReadPreferenceString(key$, "") <> ""
        AddElement(gCustomProfiles())
        gCustomProfiles()\Name = ReadPreferenceString(key$, "")
        CopyStructure(@gSettings, @gCustomProfiles()\Settings, AppSettings)
        gCustomProfiles()\Settings\ACProfile = ReadPreferenceLong("Profile" + Str(i) + "_ACProfile", gSettings\ACProfile)
        gCustomProfiles()\Settings\DCProfile = ReadPreferenceLong("Profile" + Str(i) + "_DCProfile", gSettings\DCProfile)
        gCustomProfiles()\Settings\ACMaxCPU = ReadPreferenceLong("Profile" + Str(i) + "_ACMaxCPU", gSettings\ACMaxCPU)
        gCustomProfiles()\Settings\DCMaxCPU = ReadPreferenceLong("Profile" + Str(i) + "_DCMaxCPU", gSettings\DCMaxCPU)
        gCustomProfiles()\Settings\ACMinCPU = ReadPreferenceLong("Profile" + Str(i) + "_ACMinCPU", gSettings\ACMinCPU)
        gCustomProfiles()\Settings\DCMinCPU = ReadPreferenceLong("Profile" + Str(i) + "_DCMinCPU", gSettings\DCMinCPU)
        gCustomProfiles()\Settings\ACBoostMode = ReadPreferenceLong("Profile" + Str(i) + "_ACBoost", gSettings\ACBoostMode)
        gCustomProfiles()\Settings\DCBoostMode = ReadPreferenceLong("Profile" + Str(i) + "_DCBoost", gSettings\DCBoostMode)
        gCustomProfiles()\Settings\ACCoolingPolicy = ReadPreferenceLong("Profile" + Str(i) + "_ACCooling", gSettings\ACCoolingPolicy)
        gCustomProfiles()\Settings\DCCoolingPolicy = ReadPreferenceLong("Profile" + Str(i) + "_DCCooling", gSettings\DCCoolingPolicy)
        gCustomProfiles()\Settings\ACASPMMode = ReadPreferenceLong("Profile" + Str(i) + "_ACASPM", gSettings\ACASPMMode)
        gCustomProfiles()\Settings\DCASPMMode = ReadPreferenceLong("Profile" + Str(i) + "_DCASPM", gSettings\DCASPMMode)
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure
Procedure SaveCustomProfiles()
  Protected idx.i = 0
  Protected clearIdx.i

  If OpenPreferences(gIniPath)
    PreferenceGroup("CustomProfiles")
    ForEach gCustomProfiles()
      WritePreferenceString("Profile" + Str(idx) + "_Name", gCustomProfiles()\Name)
      WritePreferenceLong("Profile" + Str(idx) + "_ACProfile", gCustomProfiles()\Settings\ACProfile)
      WritePreferenceLong("Profile" + Str(idx) + "_DCProfile", gCustomProfiles()\Settings\DCProfile)
      WritePreferenceLong("Profile" + Str(idx) + "_ACMaxCPU", gCustomProfiles()\Settings\ACMaxCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_DCMaxCPU", gCustomProfiles()\Settings\DCMaxCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_ACMinCPU", gCustomProfiles()\Settings\ACMinCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_DCMinCPU", gCustomProfiles()\Settings\DCMinCPU)
      WritePreferenceLong("Profile" + Str(idx) + "_ACBoost", gCustomProfiles()\Settings\ACBoostMode)
      WritePreferenceLong("Profile" + Str(idx) + "_DCBoost", gCustomProfiles()\Settings\DCBoostMode)
      WritePreferenceLong("Profile" + Str(idx) + "_ACCooling", gCustomProfiles()\Settings\ACCoolingPolicy)
      WritePreferenceLong("Profile" + Str(idx) + "_DCCooling", gCustomProfiles()\Settings\DCCoolingPolicy)
      WritePreferenceLong("Profile" + Str(idx) + "_ACASPM", gCustomProfiles()\Settings\ACASPMMode)
      WritePreferenceLong("Profile" + Str(idx) + "_DCASPM", gCustomProfiles()\Settings\DCASPMMode)
      idx + 1
      If idx >= #MAX_CUSTOM_PROFILES : Break : EndIf
    Next

    For clearIdx = idx To #MAX_CUSTOM_PROFILES - 1
      WritePreferenceString("Profile" + Str(clearIdx) + "_Name", "")
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACProfile", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCProfile", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACMaxCPU", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCMaxCPU", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACMinCPU", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCMinCPU", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACBoost", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCBoost", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACCooling", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCCooling", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_ACASPM", 0)
      WritePreferenceLong("Profile" + Str(clearIdx) + "_DCASPM", 0)
    Next

    ClosePreferences()
  EndIf
EndProcedure
Procedure SaveCustomProfileFromCurrentUI()
  Protected name$ = InputRequester("Save Profile", "Enter a name for this profile", "My Custom Profile")
  If Trim(name$) = ""
    ProcedureReturn
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  AddElement(gCustomProfiles())
  gCustomProfiles()\Name = Trim(name$)
  CopyStructure(@gSettings, @gCustomProfiles()\Settings, AppSettings)
  CopyTuningSettings(@gSettings, @gCustomProfiles()\Settings)
  SaveCustomProfiles()
  RefreshCustomProfileCombo()
  ShowTrayNotification("Profile Saved", gCustomProfiles()\Name)
EndProcedure
Procedure LoadSelectedCustomProfile()
  Protected selected.i = GetGadgetState(#ComboCustomProfile)
  Protected idx.i = 0

  ForEach gCustomProfiles()
    If idx = selected
      CopyTuningSettings(@gCustomProfiles()\Settings, @gSettings)
      LoadSettingsIntoUI(@gSettings)
      SaveAppSettings(gIniPath, @gSettings)
      ShowTrayNotification("Profile Loaded", gCustomProfiles()\Name)
      ProcedureReturn
    EndIf
    idx + 1
  Next
EndProcedure
Procedure EnterBenchmarkMode()
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  CopyStructure(@gSettings, @gLastNonBenchmarkSettings, AppSettings)
  gSettings\BenchmarkModeEnabled = 1
  gSettings\BenchmarkModeEndsAt = Date() + #BENCHMARK_MODE_SECONDS
  SaveAppSettings(gIniPath, @gSettings)
  SetGadgetText(#TxtBenchmarkMode, "Benchmark mode active for 10 min")
  ShowTrayNotification("Benchmark Mode", "Automation paused for 10 minutes.")
EndProcedure
Procedure CheckBenchmarkMode()
  If gSettings\BenchmarkModeEnabled = 0
    ProcedureReturn
  EndIf

  If Date() >= gSettings\BenchmarkModeEndsAt
    gSettings\BenchmarkModeEnabled = 0
    CopyStructure(@gLastNonBenchmarkSettings, @gSettings, AppSettings)
    LoadSettingsIntoUI(@gSettings)
    SaveAppSettings(gIniPath, @gSettings)
    SetGadgetText(#TxtBenchmarkMode, "Benchmark mode inactive")
    ShowTrayNotification("Benchmark Mode", "Finished. Normal automation restored.")
  EndIf
EndProcedure
Procedure ApplyCurrentGadgetSettings(scheme$, useBoost.i, useCooling.i, useASPM.i, *diag.ApplyDiagnostics = 0)
  ApplySettings(scheme$, GetGadgetState(#TrackACMax), GetGadgetState(#TrackDCMax), GetGadgetState(#TrackACMin), GetGadgetState(#TrackDCMin),
                ACBoostArg(useBoost), DCBoostArg(useBoost), useBoost,
                ACCoolingPolicyArg(useCooling), DCCoolingPolicyArg(useCooling),
                ACASPMArg(useASPM), DCASPMArg(useASPM), *diag)
EndProcedure
Procedure LoadNamedPreset(profileId.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                      @acBoostValue, @dcBoostValue,
                      @acCoolingPolicy, @dcCoolingPolicy,
                      @acASPMValue, @dcASPMValue)
  LoadPreset(useBoost, useCooling, useASPM,
             acMax\i, dcMax\i, acMin\i, dcMin\i,
             acBoostValue\i, dcBoostValue\i,
             acCoolingPolicy\i, dcCoolingPolicy\i,
             acASPMValue\i, dcASPMValue\i)
  SetComboStateByData(#ComboACProfile, profileId, 0)
  SetComboStateByData(#ComboDCProfile, profileId, 0)
EndProcedure
Procedure ApplyLiveIfEnabled(scheme$, useBoost.i, useCooling.i, useASPM.i)
  Protected diag.ApplyDiagnostics
  If GetGadgetState(#ChkLiveApply)
    ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, @diag)
    If diag\Summary = ""
      diag\Summary = "Live apply complete."
    EndIf
    SetStatus("Status: " + diag\Summary, diag\Details)
  EndIf
EndProcedure
Procedure SaveCurrentUIToSettings(*settings.AppSettings, useBoost.i, useCooling.i, useASPM.i)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACMaxCPU = GetGadgetState(#TrackACMax)
  *settings\DCMaxCPU = GetGadgetState(#TrackDCMax)
  *settings\ACMinCPU = GetGadgetState(#TrackACMin)
  *settings\DCMinCPU = GetGadgetState(#TrackDCMin)
  *settings\ACProfile = GetSelectedItemData(#ComboACProfile, 0)
  *settings\DCProfile = GetSelectedItemData(#ComboDCProfile, 0)
  *settings\ACBoostMode = ACBoostArg(useBoost)
  *settings\DCBoostMode = DCBoostArg(useBoost)
  If useCooling
    *settings\ACCoolingPolicy = ACCoolingPolicyArg(useCooling)
    *settings\DCCoolingPolicy = DCCoolingPolicyArg(useCooling)
  EndIf
  *settings\ACASPMMode = ACASPMArg(useASPM)
  *settings\DCASPMMode = DCASPMArg(useASPM)
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  *settings\AutoApply = GetGadgetState(#ChkAutoApply)
  *settings\LiveApply = GetGadgetState(#ChkLiveApply)
  *settings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
  *settings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
  *settings\HeatAlertEnabled = GetGadgetState(#ChkHeatAlertPopup)
  *settings\HeatAlertThreshold = GetGadgetState(#TrackHeatAlert)
EndProcedure
Procedure UpdateTelemetryDisplay()
  Protected summary$
  Protected updated$
  Protected heatValue.d

  If gTelemetryAvailable = #False
    summary$ = "Live telemetry: unavailable"
    updated$ = "Built-in Windows counters not available on this system."
  ElseIf gTelemetry\ErrorText <> ""
    summary$ = "Live telemetry: " + gTelemetry\ErrorText
    updated$ = "Last checked: " + gTelemetry\LastUpdated
  Else
    If gTelemetry\CpuLoad = "" : gTelemetry\CpuLoad = "Unavailable" : EndIf
    If gTelemetry\ThermalC = "" : gTelemetry\ThermalC = "Unavailable" : EndIf
    If gTelemetry\PowerSource = "" : gTelemetry\PowerSource = "Unknown" : EndIf
    summary$ = "Live telemetry: CPU load " + gTelemetry\CpuLoad + "% | Thermal zone " + gTelemetry\ThermalC + " C | Power " + gTelemetry\PowerSource
    updated$ = "Updated at " + gTelemetry\LastUpdated + ". Thermal zone is firmware-reported and may be unavailable on some laptops."
  EndIf

  If IsGadget(#TxtTelemetrySummary)
    SetGadgetText(#TxtTelemetrySummary, summary$)
  EndIf
  If IsGadget(#TxtTelemetryUpdated)
    SetGadgetText(#TxtTelemetryUpdated, updated$)
  EndIf

  UpdateMiniDashboard()

  CheckBenchmarkMode()

  If gTelemetry\ThermalC <> "" And LCase(gTelemetry\ThermalC) <> "unavailable"
    heatValue = ValD(gTelemetry\ThermalC)
    If gHeatPopupEnabled And heatValue >= gHeatAlertThreshold And Date() - gLastHeatAlertTime > 300
      gLastHeatAlertTime = Date()
      ShowTrayNotification("Heat Alert", "Thermal zone reached " + StrD(heatValue, 1) + " C. Consider switching to Cool or Battery Saver.")
    EndIf
  EndIf

  MaybeAutoSwitchThermalProfile()
EndProcedure
Procedure ShowTrayNotification(title$, message$)
  If title$ = "" Or message$ = ""
    ProcedureReturn
  EndIf

  EnsureTrayIcon()

  If gTrayReady
    SysTrayIconToolTip(#TrayMain, title$ + ": " + message$)
  EndIf

  gLastApplyMessage = title$ + ": " + message$

  If title$ = "Heat Alert" And gMainWindowVisible = #False And gMiniWindowVisible = #False
    MessageRequester(title$, message$, #PB_MessageRequester_Warning)
  EndIf
EndProcedure
Procedure MaybeAutoSwitchThermalProfile()
  Protected heatValue.d
  Protected isBattery.i
  Protected switchEnabled.i, switchProfile.i, switchThreshold.i, switchSeconds.i
  Protected restoreEnabled.i, restoreThreshold.i, restoreSeconds.i

  If gSettings\BenchmarkModeEnabled
    ProcedureReturn
  EndIf

  If gTelemetry\ThermalC = "" Or LCase(gTelemetry\ThermalC) = "unavailable"
    gACAutoSwitchSince = 0 : gDCAutoSwitchSince = 0
    gACAutoRestoreSince = 0 : gDCAutoRestoreSince = 0
    ProcedureReturn
  EndIf

  heatValue = ValD(gTelemetry\ThermalC)
  isBattery = Bool(LCase(gTelemetry\PowerSource) = "battery")

  If isBattery
    switchEnabled = gSettings\DCAutoSwitchEnabled
    switchProfile = gSettings\DCAutoSwitchProfile
    switchThreshold = gSettings\DCAutoSwitchThreshold
    switchSeconds = gSettings\DCAutoSwitchSeconds
    restoreEnabled = gSettings\DCAutoRestoreEnabled
    restoreThreshold = gSettings\DCAutoRestoreThreshold
    restoreSeconds = gSettings\DCAutoRestoreSeconds
  Else
    switchEnabled = gSettings\ACAutoSwitchEnabled
    switchProfile = gSettings\ACAutoSwitchProfile
    switchThreshold = gSettings\ACAutoSwitchThreshold
    switchSeconds = gSettings\ACAutoSwitchSeconds
    restoreEnabled = gSettings\ACAutoRestoreEnabled
    restoreThreshold = gSettings\ACAutoRestoreThreshold
    restoreSeconds = gSettings\ACAutoRestoreSeconds
  EndIf

  If switchEnabled
    If heatValue >= switchThreshold
      If isBattery
        If gDCAutoSwitchSince = 0 : gDCAutoSwitchSince = Date() : EndIf
        If Date() - gDCAutoSwitchSince >= switchSeconds
          If gAutoSwitchedDCProfile = 0
            gLastManualDCProfile = gSettings\DCProfile
            gAutoSwitchedDCProfile = switchProfile
          EndIf
          ApplySingleModePresetAndRefresh(switchProfile, #True, "Auto Cooling")
          ShowTrayNotification("Auto Cooling", "Battery heat persisted. Switched DC to " + ProfileIdToName(switchProfile) + ".")
          gDCAutoSwitchSince = Date()
        EndIf
      Else
        If gACAutoSwitchSince = 0 : gACAutoSwitchSince = Date() : EndIf
        If Date() - gACAutoSwitchSince >= switchSeconds
          If gAutoSwitchedACProfile = 0
            gLastManualACProfile = gSettings\ACProfile
            gAutoSwitchedACProfile = switchProfile
          EndIf
          ApplySingleModePresetAndRefresh(switchProfile, #False, "Auto Cooling")
          ShowTrayNotification("Auto Cooling", "AC heat persisted. Switched AC to " + ProfileIdToName(switchProfile) + ".")
          gACAutoSwitchSince = Date()
        EndIf
      EndIf
    Else
      If isBattery : gDCAutoSwitchSince = 0 : Else : gACAutoSwitchSince = 0 : EndIf
    EndIf
  EndIf

  If restoreEnabled
    If heatValue <= restoreThreshold
      If isBattery And gAutoSwitchedDCProfile > 0
        If gDCAutoRestoreSince = 0 : gDCAutoRestoreSince = Date() : EndIf
        If Date() - gDCAutoRestoreSince >= restoreSeconds
          ApplySingleModePresetAndRefresh(gLastManualDCProfile, #True, "Auto Restore")
          ShowTrayNotification("Auto Restore", "Battery temperature recovered. Restored DC " + ProfileIdToName(gLastManualDCProfile) + ".")
          gAutoSwitchedDCProfile = 0
          gDCAutoRestoreSince = 0
        EndIf
      ElseIf isBattery = 0 And gAutoSwitchedACProfile > 0
        If gACAutoRestoreSince = 0 : gACAutoRestoreSince = Date() : EndIf
        If Date() - gACAutoRestoreSince >= restoreSeconds
          ApplySingleModePresetAndRefresh(gLastManualACProfile, #False, "Auto Restore")
          ShowTrayNotification("Auto Restore", "AC temperature recovered. Restored AC " + ProfileIdToName(gLastManualACProfile) + ".")
          gAutoSwitchedACProfile = 0
          gACAutoRestoreSince = 0
        EndIf
      EndIf
    Else
      If isBattery : gDCAutoRestoreSince = 0 : Else : gACAutoRestoreSince = 0 : EndIf
    EndIf
  EndIf
EndProcedure
Procedure SaveCurrentRuntimeSettings()
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
EndProcedure
Procedure ApplyAndPersistCurrentSettings(scheme$, useBoost.i, useCooling.i, useASPM.i, *diag.ApplyDiagnostics)
  ResetApplyDiagnostics(*diag)
  SaveCurrentRuntimeSettings()
  ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, *diag)

  If *diag
    SetStatus("Status: " + *diag\Summary, *diag\Details)
  EndIf
EndProcedure
Procedure ApplyPresetAndRefresh(profileId.i)
  Protected diag.ApplyDiagnostics

  If profileId <> gAutoThermalSwitchProfile Or gAutoSwitchedProfile = 0
    gLastManualProfile = profileId
  EndIf

  LoadNamedPreset(profileId, gUseBoost, gUseCooling, gUseASPM)
  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
  ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, @diag)
  SetStatus("Status: " + diag\Summary, diag\Details)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  ShowTrayNotification("Preset Applied", ProfileIdToName(profileId) + " preset is active.")
  RefreshMiniProfileBadge()
EndProcedure
Procedure ApplyPresetWithStatus(profileId.i, detail$)
  ApplyPresetAndRefresh(profileId)
  SetStatus("Status: Preset loaded", detail$)
EndProcedure
Procedure HandleApplyButton(scheme$, useBoost.i, useCooling.i, useASPM.i, *applyDiag.ApplyDiagnostics)
  Protected acMaxVal.i = GetGadgetState(#TrackACMax)
  Protected dcMaxVal.i = GetGadgetState(#TrackDCMax)
  Protected acMinVal.i = GetGadgetState(#TrackACMin)
  Protected dcMinVal.i = GetGadgetState(#TrackDCMin)
  Protected acBoostValue.i = ACBoostArg(useBoost)
  Protected dcBoostValue.i = DCBoostArg(useBoost)

  LogLine(#LOG_INFO, "Apply button clicked")
  UpdateDisplayedValues(useBoost, useCooling, useASPM)
  ApplyAndPersistCurrentSettings(scheme$, useBoost, useCooling, useASPM, *applyDiag)

  If *applyDiag\FailureCount = 0 And useBoost
    MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                             "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ +
                             "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                             "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                             "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                             "AC boost: " + BoostModeLabel(acBoostValue) + " (" + Str(acBoostValue) + ")" + #CRLF$ +
                             "DC boost: " + BoostModeLabel(dcBoostValue) + " (" + Str(dcBoostValue) + ")", #PB_MessageRequester_Info)
    ShowTrayNotification("Settings Applied", "Custom scheme updated successfully.")
  ElseIf *applyDiag\FailureCount = 0
    MessageRequester("Done", "Applied to custom scheme." + #CRLF$ +
                             "AC Max CPU: " + Str(acMaxVal) + "%" + #CRLF$ +
                             "DC Max CPU: " + Str(dcMaxVal) + "%" + #CRLF$ +
                             "AC Min CPU: " + Str(acMinVal) + "%" + #CRLF$ +
                             "DC Min CPU: " + Str(dcMinVal) + "%" + #CRLF$ +
                             "Boost mode is not available on this system.", #PB_MessageRequester_Info)
    ShowTrayNotification("Settings Applied", "Custom scheme updated successfully.")
  Else
    MessageRequester("Apply completed with errors", *applyDiag\Summary + #CRLF$ + #CRLF$ + *applyDiag\Details, #PB_MessageRequester_Warning)
    ShowTrayNotification("Apply Warning", *applyDiag\Summary)
  EndIf
EndProcedure
Procedure SetStartupModeFromTray(mode.i, comboDefaultIndex.i, notification$)
  gSettings\StartupMode = mode
  If IsGadget(#ComboStartupMode)
    SetComboStateByData(#ComboStartupMode, mode, comboDefaultIndex)
  EndIf
  SaveAppSettings(gIniPath, @gSettings)
  ShowTrayNotification("Startup Mode", notification$)
EndProcedure
Procedure HandleGadgetEvent(eventGadget.i, scheme$, useBoost.i, useCooling.i, useASPM.i, *applyDiag.ApplyDiagnostics)
  Protected isBatteryMode.i = AutomationIsBatteryMode()

  Select eventGadget
    Case #ChkAutoApply, #ChkLiveApply, #ChkRunAtStartup, #ChkUseTaskScheduler
      gSettings\AutoApply = GetGadgetState(#ChkAutoApply)
      gSettings\LiveApply = GetGadgetState(#ChkLiveApply)
      gSettings\RunAtStartup = GetGadgetState(#ChkRunAtStartup)
      gSettings\UseTaskScheduler = GetGadgetState(#ChkUseTaskScheduler)
      SaveAppSettings(gIniPath, @gSettings)

    Case #TrackHeatAlert
      gSettings\HeatAlertThreshold = GetGadgetState(#TrackHeatAlert)
      gHeatAlertThreshold = gSettings\HeatAlertThreshold
      SetGadgetText(#TxtHeatAlertVal, Str(gSettings\HeatAlertThreshold) + " C")
      ScheduleSettingsSave()

    Case #ChkHeatAlertPopup
      gSettings\HeatAlertEnabled = GetGadgetState(#ChkHeatAlertPopup)
      gHeatPopupEnabled = gSettings\HeatAlertEnabled
      SaveAppSettings(gIniPath, @gSettings)

    Case #ChkAutoThermalSwitch
      If isBatteryMode
        gSettings\DCAutoSwitchEnabled = GetGadgetState(#ChkAutoThermalSwitch)
      Else
        gSettings\ACAutoSwitchEnabled = GetGadgetState(#ChkAutoThermalSwitch)
      EndIf
      SaveAppSettings(gIniPath, @gSettings)

    Case #ComboAutoSwitchProfile
      If isBatteryMode
        gSettings\DCAutoSwitchProfile = GetSelectedItemData(#ComboAutoSwitchProfile, #PROFILE_COOL)
      Else
        gSettings\ACAutoSwitchProfile = GetSelectedItemData(#ComboAutoSwitchProfile, #PROFILE_COOL)
      EndIf
      SaveAppSettings(gIniPath, @gSettings)

    Case #TrackAutoSwitchDelay
      If isBatteryMode
        gSettings\DCAutoSwitchSeconds = GetGadgetState(#TrackAutoSwitchDelay)
        SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
      Else
        gSettings\ACAutoSwitchSeconds = GetGadgetState(#TrackAutoSwitchDelay)
        SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\ACAutoSwitchThreshold) + " C / " + Str(gSettings\ACAutoSwitchSeconds) + " sec")
      EndIf
      ScheduleSettingsSave()

    Case #ComboStartupMode
      gSettings\StartupMode = GetSelectedItemData(#ComboStartupMode, 0)
      SaveAppSettings(gIniPath, @gSettings)

    Case #ChkAutoRestore
      If isBatteryMode
        gSettings\DCAutoRestoreEnabled = GetGadgetState(#ChkAutoRestore)
      Else
        gSettings\ACAutoRestoreEnabled = GetGadgetState(#ChkAutoRestore)
      EndIf
      SaveAppSettings(gIniPath, @gSettings)

    Case #TrackAutoRestoreThreshold
      If isBatteryMode
        gSettings\DCAutoRestoreThreshold = GetGadgetState(#TrackAutoRestoreThreshold)
        SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
      Else
        gSettings\ACAutoRestoreThreshold = GetGadgetState(#TrackAutoRestoreThreshold)
        SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
      EndIf
      ScheduleSettingsSave()

    Case #TrackAutoRestoreDelay
      If isBatteryMode
        gSettings\DCAutoRestoreSeconds = GetGadgetState(#TrackAutoRestoreDelay)
        SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
      Else
        gSettings\ACAutoRestoreSeconds = GetGadgetState(#TrackAutoRestoreDelay)
        SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
      EndIf
      ScheduleSettingsSave()

    Case #BtnExportProfile
      ExportCurrentProfile()

    Case #BtnImportProfile
      ImportCoolingProfile()

    Case #BtnSaveCustomProfile
      SaveCustomProfileFromCurrentUI()

    Case #BtnLoadCustomProfile
      LoadSelectedCustomProfile()

    Case #BtnBenchmarkMode
      EnterBenchmarkMode()

    Case #TrackACMax, #TrackDCMax, #TrackACMin, #TrackDCMin, #ComboACBoost, #ComboDCBoost, #ComboACCooling, #ComboDCCooling, #ComboACASPM, #ComboDCASPM
      UpdateProfilesFromCurrentUI(@gSettings)
      SyncProfileCombosFromSettings(@gSettings)
      UpdateDisplayedValues(useBoost, useCooling, useASPM)
      ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

    Case #ComboACProfile
      gSettings\ACProfile = GetSelectedItemData(#ComboACProfile, 0)
      ApplyProfileSelectionToTracks(gSettings\ACProfile, #True, useBoost, useCooling, useASPM)
      SetStatus("Status: AC profile selected", ProfileIdToName(gSettings\ACProfile) + " loaded into the plugged-in sliders.")
      ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

    Case #ComboDCProfile
      gSettings\DCProfile = GetSelectedItemData(#ComboDCProfile, 0)
      If gSettings\DCProfile <= 0
        gSettings\DCProfile = #PROFILE_BALANCED
        SetComboStateByData(#ComboDCProfile, gSettings\DCProfile, 4)
      EndIf
      ApplyProfileSelectionToTracks(gSettings\DCProfile, #False, useBoost, useCooling, useASPM)
      SetStatus("Status: DC profile selected", ProfileIdToName(gSettings\DCProfile) + " loaded into the battery sliders.")
      ApplyLiveIfEnabled(scheme$, useBoost, useCooling, useASPM)

    Case #BtnBatteryPreset
      ApplyPresetWithStatus(#PROFILE_BATTERY_SAVER, "Battery Saver applied to both AC and DC sliders.")

    Case #BtnEcoPreset
      ApplyPresetWithStatus(#PROFILE_ECO, "Eco applied to both AC and DC sliders.")

    Case #BtnQuietPreset
      ApplyPresetWithStatus(#PROFILE_QUIET, "Quiet applied to both AC and DC sliders.")

    Case #BtnCoolPreset
      ApplyPresetWithStatus(#PROFILE_COOL, "Cool applied to both AC and DC sliders.")

    Case #BtnBalancedPreset
      ApplyPresetWithStatus(#PROFILE_BALANCED, "Balanced applied to both AC and DC sliders.")

    Case #BtnPerfPreset
      ApplyPresetWithStatus(#PROFILE_PERFORMANCE, "Performance applied to both AC and DC sliders.")

    Case #BtnRestoreBalanced
      RestoreBalanced()
      SetStatus("Status: Windows Balanced restored", "The default Windows Balanced scheme is active.")
      MessageRequester("Balanced restored", "Activated the default Windows Balanced plan." + #CRLF$ +
                                            "You can re-apply the custom scheme anytime with 'Apply now'.", #PB_MessageRequester_Info)

    Case #BtnApply
      HandleApplyButton(scheme$, useBoost, useCooling, useASPM, *applyDiag)

    Case #BtnMiniToggleMain
      ShowMainWindow(Bool(gMainWindowVisible = #False))

    Case #BtnMiniApply
      ApplyAndPersistCurrentSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, *applyDiag)
      ShowTrayNotification("Settings Applied", *applyDiag\Summary)

    Case #BtnMiniBattery
      ApplyPresetAndRefresh(#PROFILE_BATTERY_SAVER)

    Case #BtnMiniEco
      ApplyPresetAndRefresh(#PROFILE_ECO)

    Case #BtnMiniQuiet
      ApplyPresetAndRefresh(#PROFILE_QUIET)

    Case #BtnMiniCool
      ApplyPresetAndRefresh(#PROFILE_COOL)

    Case #BtnMiniBalanced
      ApplyPresetAndRefresh(#PROFILE_BALANCED)

    Case #BtnMiniPerformance
      ApplyPresetAndRefresh(#PROFILE_PERFORMANCE)
  EndSelect
EndProcedure
Procedure HandleMenuEvent(eventMenu.i, *applyDiag.ApplyDiagnostics)
  Select eventMenu
    Case #MenuTrayShowHide
      ShowMainWindow(Bool(gMainWindowVisible = #False))

    Case #MenuTrayMiniDashboard
      ShowMiniDashboard(Bool(gMiniWindowVisible = #False))

    Case #MenuTrayApply
      ApplyAndPersistCurrentSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM, *applyDiag)
      ShowTrayNotification("Settings Applied", *applyDiag\Summary)

    Case #MenuTrayRunAtStartup
      gSettings\RunAtStartup = Bool(gSettings\RunAtStartup = 0)
      If IsGadget(#ChkRunAtStartup)
        SetGadgetState(#ChkRunAtStartup, gSettings\RunAtStartup)
      EndIf
      SaveAppSettings(gIniPath, @gSettings)
      If gSettings\RunAtStartup
        ShowTrayNotification("Startup Enabled", "MyCPUCooler will run at logon.")
      Else
        ShowTrayNotification("Startup Disabled", "MyCPUCooler will not run at logon.")
      EndIf

    Case #MenuTrayUseTaskScheduler
      gSettings\UseTaskScheduler = Bool(gSettings\UseTaskScheduler = 0)
      If IsGadget(#ChkUseTaskScheduler)
        SetGadgetState(#ChkUseTaskScheduler, gSettings\UseTaskScheduler)
      EndIf
      SaveAppSettings(gIniPath, @gSettings)
      If gSettings\UseTaskScheduler
        ShowTrayNotification("Task Scheduler Enabled", "Startup will use Task Scheduler.")
      Else
        ShowTrayNotification("Run Key Enabled", "Startup will use the Run registry key.")
      EndIf

    Case #MenuTrayStartupMain
      SetStartupModeFromTray(0, 0, "Startup will open the main window.")

    Case #MenuTrayStartupTray
      SetStartupModeFromTray(1, 1, "Startup will open in the tray.")

    Case #MenuTrayStartupMini
      SetStartupModeFromTray(2, 2, "Startup will open the mini dashboard.")

    Case #MenuTrayStartupSilent
      SetStartupModeFromTray(3, 3, "Startup will silently apply and exit.")

    Case #MenuTrayBattery
      ApplyPresetAndRefresh(#PROFILE_BATTERY_SAVER)

    Case #MenuTrayEco
      ApplyPresetAndRefresh(#PROFILE_ECO)

    Case #MenuTrayQuiet
      ApplyPresetAndRefresh(#PROFILE_QUIET)

    Case #MenuTrayCool
      ApplyPresetAndRefresh(#PROFILE_COOL)

    Case #MenuTrayBalanced
      ApplyPresetAndRefresh(#PROFILE_BALANCED)

    Case #MenuTrayPerformance
      ApplyPresetAndRefresh(#PROFILE_PERFORMANCE)

    Case #MenuTrayRestoreBalanced
      RestoreBalanced()
      SetStatus("Status: Windows Balanced restored", "The default Windows Balanced scheme is active.")

    Case #MenuTrayShowLogPath
      MessageRequester("Log Path", "Log file (Logs folder):" + #CRLF$ + gLogPath, #PB_MessageRequester_Info)

    Case #MenuTrayExit
      CloseHandle_(hMutex)
      End
  EndSelect
EndProcedure
Procedure HandleTimerEvent(timerId.i)
  If timerId = #TimerTelemetry
    If gPendingSettingsSave And ElapsedMilliseconds() >= gPendingSettingsSaveAt
      FlushPendingSettingsSave()
    EndIf
    If gTelemetryBusy = #False
      StartTelemetryRefresh()
    EndIf
    UpdateTelemetryDisplay()
  EndIf
EndProcedure
Procedure HandleSysTrayEvent(eventType.i)
  If gTrayReady = 0
    ProcedureReturn
  EndIf

  Select eventType
    Case #PB_EventType_LeftDoubleClick
      ShowMainWindow(Bool(gMainWindowVisible = #False))
      If gMiniWindowVisible
        ShowMiniDashboard(#False)
      EndIf

    Case #PB_EventType_RightClick
      DisplayPopupMenu(#TrayMain, WindowID(#Win))
  EndSelect
EndProcedure
Procedure HandleCloseWindowEvent(eventWindow.i)
  LogLine(#LOG_INFO, "Close requested")

  If eventWindow = #WinMini
    ShowMiniDashboard(#False)
  Else
    If EnsureTrayIcon() = 0
      MessageRequester("Tray icon unavailable", "The tray icon could not be created, so the app will stay visible instead of hiding.", #PB_MessageRequester_Warning)
      ShowMainWindow(#True)
      ProcedureReturn
    EndIf
    ShowMainWindow(#False)
    SetStatus("Status: Minimized to tray", "Double-click the tray icon to re-open the window.")
  EndIf
EndProcedure
Procedure ApplySingleModePresetAndRefresh(profileId.i, isBattery.i, reason$ = "")
  If isBattery
    ApplyProfileSelectionToTracks(profileId, #False, gUseBoost, gUseCooling, gUseASPM)
    gSettings\DCProfile = profileId
  Else
    ApplyProfileSelectionToTracks(profileId, #True, gUseBoost, gUseCooling, gUseASPM)
    gSettings\ACProfile = profileId
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  SaveAppSettings(gIniPath, @gSettings)
  ApplyCurrentGadgetSettings(gCurrentScheme, gUseBoost, gUseCooling, gUseASPM)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  RefreshMiniProfileBadge()
  If reason$ <> ""
    If isBattery
      SetStatus("Status: " + reason$, ProfileIdToName(profileId) + " applied to battery mode.")
    Else
      SetStatus("Status: " + reason$, ProfileIdToName(profileId) + " applied to plugged-in mode.")
    EndIf
  EndIf
EndProcedure
Procedure ExportCurrentProfile()
  Protected path$ = SaveFileRequester("Export cooling profile", GetPathPart(ProgramFilename()) + "MyCPUCooler-profile.ini", "INI (*.ini)|*.ini", 0)

  If path$ = ""
    ProcedureReturn
  EndIf

  SaveCurrentUIToSettings(@gSettings, gUseBoost, gUseCooling, gUseASPM)
  If CreatePreferences(path$)
    PreferenceGroup("Profile")
    WritePreferenceString("Name", "Exported " + FormatDate("%yyyy-%mm-%dd %hh:%ii", Date()))
    WritePreferenceLong("AC_Profile", gSettings\ACProfile)
    WritePreferenceLong("DC_Profile", gSettings\DCProfile)
    WritePreferenceLong("AC_MaxCPU", gSettings\ACMaxCPU)
    WritePreferenceLong("DC_MaxCPU", gSettings\DCMaxCPU)
    WritePreferenceLong("AC_MinCPU", gSettings\ACMinCPU)
    WritePreferenceLong("DC_MinCPU", gSettings\DCMinCPU)
    WritePreferenceLong("AC_BoostMode", gSettings\ACBoostMode)
    WritePreferenceLong("DC_BoostMode", gSettings\DCBoostMode)
    WritePreferenceLong("AC_CoolingPolicy", gSettings\ACCoolingPolicy)
    WritePreferenceLong("DC_CoolingPolicy", gSettings\DCCoolingPolicy)
    WritePreferenceLong("AC_ASPMMode", gSettings\ACASPMMode)
    WritePreferenceLong("DC_ASPMMode", gSettings\DCASPMMode)
    ClosePreferences()
    ShowTrayNotification("Profile Exported", path$)
  EndIf
EndProcedure
Procedure ImportCoolingProfile()
  Protected path$ = OpenFileRequester("Import cooling profile", GetPathPart(ProgramFilename()), "INI (*.ini)|*.ini", 0)

  If path$ = ""
    ProcedureReturn
  EndIf

  If OpenPreferences(path$)
    PreferenceGroup("Profile")
    gSettings\ACProfile = ReadPreferenceLong("AC_Profile", gSettings\ACProfile)
    gSettings\DCProfile = ReadPreferenceLong("DC_Profile", gSettings\DCProfile)
    gSettings\ACMaxCPU = ReadPreferenceLong("AC_MaxCPU", gSettings\ACMaxCPU)
    gSettings\DCMaxCPU = ReadPreferenceLong("DC_MaxCPU", gSettings\DCMaxCPU)
    gSettings\ACMinCPU = ReadPreferenceLong("AC_MinCPU", gSettings\ACMinCPU)
    gSettings\DCMinCPU = ReadPreferenceLong("DC_MinCPU", gSettings\DCMinCPU)
    gSettings\ACBoostMode = ReadPreferenceLong("AC_BoostMode", gSettings\ACBoostMode)
    gSettings\DCBoostMode = ReadPreferenceLong("DC_BoostMode", gSettings\DCBoostMode)
    gSettings\ACCoolingPolicy = ReadPreferenceLong("AC_CoolingPolicy", gSettings\ACCoolingPolicy)
    gSettings\DCCoolingPolicy = ReadPreferenceLong("DC_CoolingPolicy", gSettings\DCCoolingPolicy)
    gSettings\ACASPMMode = ReadPreferenceLong("AC_ASPMMode", gSettings\ACASPMMode)
    gSettings\DCASPMMode = ReadPreferenceLong("DC_ASPMMode", gSettings\DCASPMMode)
    ClosePreferences()
    LoadSettingsIntoUI(@gSettings)
    SaveAppSettings(gIniPath, @gSettings)
    ShowTrayNotification("Profile Imported", path$)
  EndIf
EndProcedure
