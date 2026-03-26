; -----------------------------
; GUI constants
; -----------------------------

Enumeration
  #Win
  #TrackACMax
  #TrackDCMax
  #TrackACMin
  #TrackDCMin
  #ComboACProfile
  #ComboDCProfile
  #ComboACBoost
  #ComboDCBoost
  #ComboACCooling
  #ComboDCCooling
  #ComboACASPM
  #ComboDCASPM

  #TxtACMaxVal
  #TxtDCMaxVal
  #TxtACMinVal
  #TxtDCMinVal
  #TxtACBoostVal
  #TxtDCBoostVal
  #TxtThermalHint
  #TxtTelemetrySummary
  #TxtTelemetryUpdated
  #TxtStatusSummary
  #EditStatusDetails
  #WinMini
  #TxtMiniTelemetry
  #TxtMiniThermal
  #TxtMiniProfile
  #TxtHeatAlertVal
  #TxtAutoSwitchVal
  #TxtAutoRestoreVal
  #TxtAutomationMode
  #TxtBenchmarkMode
  #BtnMiniToggleMain
  #BtnMiniApply
  #TrackHeatAlert
  #ChkHeatAlertPopup
  #ChkAutoThermalSwitch
  #ComboAutoSwitchProfile
  #TrackAutoSwitchDelay
  #ComboStartupMode
  #ChkAutoRestore
  #TrackAutoRestoreDelay
  #TrackAutoRestoreThreshold
  #CanvasMiniHistory
  #ComboCustomProfile
  #BtnSaveCustomProfile
  #BtnLoadCustomProfile
  #BtnBenchmarkMode
  #BtnExportProfile
  #BtnImportProfile
  #BtnMiniBattery
  #BtnMiniEco
  #BtnMiniQuiet
  #BtnMiniCool
  #BtnMiniBalanced
  #BtnMiniPerformance


  #ChkAutoApply
  #ChkLiveApply
  #ChkRunAtStartup
  #ChkUseTaskScheduler

  #BtnBatteryPreset
  #BtnApply
  #BtnEcoPreset
  #BtnQuietPreset
  #BtnCoolPreset
  #BtnBalancedPreset
  #BtnPerfPreset
  #BtnRestoreBalanced
EndEnumeration

Enumeration 1000
  #TimerTelemetry
EndEnumeration

Enumeration 1
  #TrayMain
EndEnumeration

Enumeration 100
  #MenuTrayShowHide
  #MenuTrayMiniDashboard
  #MenuTrayApply
  #MenuTrayRunAtStartup
  #MenuTrayUseTaskScheduler
  #MenuTrayStartupMain
  #MenuTrayStartupTray
  #MenuTrayStartupMini
  #MenuTrayStartupSilent
  #MenuTrayBattery
  #MenuTrayEco
  #MenuTrayQuiet
  #MenuTrayCool
  #MenuTrayBalanced
  #MenuTrayPerformance
  #MenuTrayRestoreBalanced
  #MenuTrayExit
EndEnumeration

; -----------------------------
; UI helpers
; -----------------------------

Procedure.i GetSelectedItemData(gadget.i, defaultValue.i = -1)
  Protected idx.i = GetGadgetState(gadget)
  If idx >= 0 And idx < CountGadgetItems(gadget)
    ProcedureReturn GetGadgetItemData(gadget, idx)
  EndIf
  ProcedureReturn defaultValue
EndProcedure
Procedure.i SetComboStateByData(gadget.i, value.i, defaultIndex.i = 0)
  Protected i.i
  For i = 0 To CountGadgetItems(gadget) - 1
    If GetGadgetItemData(gadget, i) = value
      SetGadgetState(gadget, i)
      ProcedureReturn #True
    EndIf
  Next

  If defaultIndex >= 0 And defaultIndex < CountGadgetItems(gadget)
    SetGadgetState(gadget, defaultIndex)
  EndIf
  ProcedureReturn #False
EndProcedure
Procedure AddComboItemWithData(gadget.i, label$, value.i)
  AddGadgetItem(gadget, -1, label$)
  SetGadgetItemData(gadget, CountGadgetItems(gadget) - 1, value)
EndProcedure
Procedure PopulateProfileCombo(gadget.i)
  AddComboItemWithData(gadget, "Battery Saver", #PROFILE_BATTERY_SAVER)
  AddComboItemWithData(gadget, "Eco", #PROFILE_ECO)
  AddComboItemWithData(gadget, "Quiet", #PROFILE_QUIET)
  AddComboItemWithData(gadget, "Cool", #PROFILE_COOL)
  AddComboItemWithData(gadget, "Balanced", #PROFILE_BALANCED)
  AddComboItemWithData(gadget, "Performance", #PROFILE_PERFORMANCE)
EndProcedure
Procedure PopulatePresetOnlyProfileCombo(gadget.i)
  AddComboItemWithData(gadget, "Battery Saver", #PROFILE_BATTERY_SAVER)
  AddComboItemWithData(gadget, "Eco", #PROFILE_ECO)
  AddComboItemWithData(gadget, "Quiet", #PROFILE_QUIET)
  AddComboItemWithData(gadget, "Cool", #PROFILE_COOL)
  AddComboItemWithData(gadget, "Balanced", #PROFILE_BALANCED)
  AddComboItemWithData(gadget, "Performance", #PROFILE_PERFORMANCE)
EndProcedure
Procedure PopulateStartupModeCombo(gadget.i)
  AddComboItemWithData(gadget, "Open main window", 0)
  AddComboItemWithData(gadget, "Start in tray", 1)
  AddComboItemWithData(gadget, "Open mini dashboard", 2)
  AddComboItemWithData(gadget, "Silent apply and exit", 3)
EndProcedure
Procedure.i EnsureTrayIcon()
  If gTrayReady
    ProcedureReturn #True
  EndIf

  If gTrayImage = 0 And FileSize(GetPathPart(ProgramFilename()) + "files\MyCPUCooler.ico") >= 0
    gTrayImage = LoadImage(#PB_Any, GetPathPart(ProgramFilename()) + "files\MyCPUCooler.ico")
  EndIf

  If gTrayImage = 0
    gTrayImage = CreateImage(#PB_Any, 16, 16, 32, RGB(30, 36, 44))
    If gTrayImage And StartDrawing(ImageOutput(gTrayImage))
      Box(0, 0, 16, 16, RGB(30, 36, 44))
      Circle(8, 8, 6, RGB(96, 190, 120))
      Box(7, 3, 2, 10, RGB(220, 245, 230))
      Box(4, 7, 8, 2, RGB(220, 245, 230))
      StopDrawing()
    EndIf
  EndIf

  If gTrayImage
    gTrayReady = AddSysTrayIcon(#TrayMain, WindowID(#Win), ImageID(gTrayImage))
    If gTrayReady
      SysTrayIconToolTip(#TrayMain, #APP_NAME + " - cooling controls")
    EndIf
  EndIf

  ProcedureReturn gTrayReady
EndProcedure
Procedure RefreshCustomProfileCombo()
  Protected idx.i = 0

  If IsGadget(#ComboCustomProfile) = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#ComboCustomProfile)
  ForEach gCustomProfiles()
    AddGadgetItem(#ComboCustomProfile, -1, gCustomProfiles()\Name)
    SetGadgetItemData(#ComboCustomProfile, idx, idx)
    idx + 1
  Next
EndProcedure
Procedure UpdateAutomationDisplay()
  Protected powerMode$ = "AC"
  Protected switchProfile$ = ProfileIdToName(gSettings\ACAutoSwitchProfile)
  Protected restoreText$ = "Restore " + Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec"

  If LCase(gTelemetry\PowerSource) = "battery"
    powerMode$ = "Battery"
    switchProfile$ = ProfileIdToName(gSettings\DCAutoSwitchProfile)
    restoreText$ = "Restore " + Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec"
    SetComboStateByData(#ComboAutoSwitchProfile, gSettings\DCAutoSwitchProfile, 0)
    SetGadgetState(#TrackAutoSwitchDelay, gSettings\DCAutoSwitchSeconds)
    SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
    SetGadgetState(#TrackAutoRestoreThreshold, gSettings\DCAutoRestoreThreshold)
    SetGadgetState(#TrackAutoRestoreDelay, gSettings\DCAutoRestoreSeconds)
    SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
    SetGadgetState(#ChkAutoThermalSwitch, gSettings\DCAutoSwitchEnabled)
    SetGadgetState(#ChkAutoRestore, gSettings\DCAutoRestoreEnabled)
  Else
    SetComboStateByData(#ComboAutoSwitchProfile, gSettings\ACAutoSwitchProfile, 0)
    SetGadgetState(#TrackAutoSwitchDelay, gSettings\ACAutoSwitchSeconds)
    SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\ACAutoSwitchThreshold) + " C / " + Str(gSettings\ACAutoSwitchSeconds) + " sec")
    SetGadgetState(#TrackAutoRestoreThreshold, gSettings\ACAutoRestoreThreshold)
    SetGadgetState(#TrackAutoRestoreDelay, gSettings\ACAutoRestoreSeconds)
    SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\ACAutoRestoreThreshold) + " C / " + Str(gSettings\ACAutoRestoreSeconds) + " sec")
    SetGadgetState(#ChkAutoThermalSwitch, gSettings\ACAutoSwitchEnabled)
    SetGadgetState(#ChkAutoRestore, gSettings\ACAutoRestoreEnabled)
  EndIf

  If IsGadget(#TxtAutomationMode)
    SetGadgetText(#TxtAutomationMode, powerMode$ + " automation -> " + switchProfile$ + " | " + restoreText$)
  EndIf
EndProcedure
Procedure PopulateBoostCombo()
  AddComboItemWithData(#ComboACBoost, "Disabled (coolest)", #BOOST_DISABLED)
  AddComboItemWithData(#ComboACBoost, "Enabled (default)", #BOOST_ENABLED)
  AddComboItemWithData(#ComboACBoost, "Efficient Enabled (cooler)", #BOOST_EFFICIENT)
  AddComboItemWithData(#ComboACBoost, "Efficient Aggressive (warm)", #BOOST_EFFICIENT_AGGRESSIVE)
  AddComboItemWithData(#ComboACBoost, "Aggressive (hottest)", #BOOST_AGGRESSIVE)
  AddComboItemWithData(#ComboDCBoost, "Disabled (coolest)", #BOOST_DISABLED)
  AddComboItemWithData(#ComboDCBoost, "Enabled (default)", #BOOST_ENABLED)
  AddComboItemWithData(#ComboDCBoost, "Efficient Enabled (cooler)", #BOOST_EFFICIENT)
  AddComboItemWithData(#ComboDCBoost, "Efficient Aggressive (warm)", #BOOST_EFFICIENT_AGGRESSIVE)
  AddComboItemWithData(#ComboDCBoost, "Aggressive (hottest)", #BOOST_AGGRESSIVE)
EndProcedure
Procedure PopulateCoolingCombo()
  AddComboItemWithData(#ComboACCooling, "Active (fan first)", 0)
  AddComboItemWithData(#ComboACCooling, "Passive (throttle first)", 1)
  AddComboItemWithData(#ComboDCCooling, "Active (fan first)", 0)
  AddComboItemWithData(#ComboDCCooling, "Passive (throttle first)", 1)
EndProcedure
Procedure PopulateASPMCombo()
  AddComboItemWithData(#ComboACASPM, "Off (performance)", 0)
  AddComboItemWithData(#ComboACASPM, "Moderate Power Savings", 1)
  AddComboItemWithData(#ComboACASPM, "Maximum Power Savings", 2)
  AddComboItemWithData(#ComboDCASPM, "Off (performance)", 0)
  AddComboItemWithData(#ComboDCASPM, "Moderate Power Savings", 1)
  AddComboItemWithData(#ComboDCASPM, "Maximum Power Savings", 2)
EndProcedure
Procedure.s BoostModeLabel(boostValue.i)
  Select boostValue
    Case #BOOST_DISABLED
      ProcedureReturn "Disabled"
    Case #BOOST_ENABLED
      ProcedureReturn "Enabled"
    Case #BOOST_EFFICIENT
      ProcedureReturn "Efficient Enabled"
    Case #BOOST_EFFICIENT_AGGRESSIVE
      ProcedureReturn "Efficient Aggressive"
    Case #BOOST_AGGRESSIVE
      ProcedureReturn "Aggressive"
  EndSelect

  ProcedureReturn "Custom"
EndProcedure
Procedure.s CoolingPolicyLabel(value.i)
  Select value
    Case 0
      ProcedureReturn "Active"
    Case 1
      ProcedureReturn "Passive"
  EndSelect
  ProcedureReturn "Custom"
EndProcedure
Procedure.s ASPMLabel(value.i)
  Select value
    Case 0
      ProcedureReturn "Off"
    Case 1
      ProcedureReturn "Moderate"
    Case 2
      ProcedureReturn "Maximum"
  EndSelect
  ProcedureReturn "Custom"
EndProcedure
Procedure.i ThermalScore(acMax.i, dcMax.i, acBoost.i, dcBoost.i, acCooling.i, dcCooling.i, acASPM.i, dcASPM.i)
  Protected score.i = 100

  score - ((100 - ClampPercent(acMax, 5, 100)) / 2)
  score - ((100 - ClampPercent(dcMax, 5, 100)) / 2)
  score - (acBoost * 8)
  score - (dcBoost * 6)
  score - (acCooling * 6)
  score - (dcCooling * 8)
  score - (acASPM * 2)
  score - (dcASPM * 3)

  If score < 0 : score = 0 : EndIf
  If score > 100 : score = 100 : EndIf
  ProcedureReturn score
EndProcedure
Procedure.s ThermalHintText(score.i)
  If score >= 88
    ProcedureReturn "Thermal posture: Maximum cooling. Strong throttling, best for hot rooms and gaming laptops."
  ElseIf score >= 72
    ProcedureReturn "Thermal posture: Cool and quiet. Good for long sessions with lower surface temps."
  ElseIf score >= 55
    ProcedureReturn "Thermal posture: Balanced. Good mix of temperature control and responsiveness."
  ElseIf score >= 38
    ProcedureReturn "Thermal posture: Performance leaning. Expect more heat under sustained load."
  EndIf

  ProcedureReturn "Thermal posture: Max performance. Fastest, but likely the hottest setting."
EndProcedure
Procedure SetStatus(summary$, detail$ = "")
  If IsGadget(#TxtStatusSummary)
    SetGadgetText(#TxtStatusSummary, summary$)
  EndIf
  If IsGadget(#EditStatusDetails)
    SetGadgetText(#EditStatusDetails, detail$)
  EndIf
EndProcedure
Procedure UpdateProfilesFromCurrentSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer
  Protected profileId.i

  *settings\ACProfile = 0
  *settings\DCProfile = 0

  For profileId = #PROFILE_BATTERY_SAVER To #PROFILE_PERFORMANCE
    LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                        @acBoostValue, @dcBoostValue,
                        @acCoolingPolicy, @dcCoolingPolicy,
                        @acASPMValue, @dcASPMValue)
    If *settings\ACMaxCPU = acMax\i And *settings\ACMinCPU = acMin\i And *settings\ACBoostMode = acBoostValue\i And *settings\ACCoolingPolicy = acCoolingPolicy\i And *settings\ACASPMMode = acASPMValue\i
      *settings\ACProfile = profileId
    EndIf
    If *settings\DCMaxCPU = dcMax\i And *settings\DCMinCPU = dcMin\i And *settings\DCBoostMode = dcBoostValue\i And *settings\DCCoolingPolicy = dcCoolingPolicy\i And *settings\DCASPMMode = dcASPMValue\i
      *settings\DCProfile = profileId
    EndIf
  Next
EndProcedure
Procedure UpdateProfilesFromCurrentUI(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  *settings\ACMaxCPU = GetGadgetState(#TrackACMax)
  *settings\DCMaxCPU = GetGadgetState(#TrackDCMax)
  *settings\ACMinCPU = GetGadgetState(#TrackACMin)
  *settings\DCMinCPU = GetGadgetState(#TrackDCMin)
  *settings\ACBoostMode = GetSelectedItemData(#ComboACBoost, #BOOST_DISABLED)
  *settings\DCBoostMode = GetSelectedItemData(#ComboDCBoost, #BOOST_DISABLED)
  *settings\ACCoolingPolicy = GetSelectedItemData(#ComboACCooling, 0)
  *settings\DCCoolingPolicy = GetSelectedItemData(#ComboDCCooling, 1)
  *settings\ACASPMMode = GetSelectedItemData(#ComboACASPM, 1)
  *settings\DCASPMMode = GetSelectedItemData(#ComboDCASPM, 2)
  *settings\BoostMode = *settings\ACBoostMode
  *settings\CoolingPolicy = *settings\ACCoolingPolicy
  *settings\ASPMMode = *settings\ACASPMMode
  UpdateProfilesFromCurrentSettings(*settings)
EndProcedure
Procedure SyncProfileCombosFromSettings(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If *settings\ACProfile <= 0
    *settings\ACProfile = #PROFILE_COOL
  EndIf
  If *settings\DCProfile <= 0
    *settings\DCProfile = #PROFILE_BALANCED
  EndIf

  If IsGadget(#ComboACProfile)
    SetComboStateByData(#ComboACProfile, *settings\ACProfile, 0)
  EndIf

  If IsGadget(#ComboDCProfile)
    SetComboStateByData(#ComboDCProfile, *settings\DCProfile, 4)
  EndIf
EndProcedure
Procedure ApplyProfileSelectionToTracks(profileId.i, isAC.i, useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.Integer, dcMax.Integer, acMin.Integer, dcMin.Integer
  Protected acBoostValue.Integer, dcBoostValue.Integer
  Protected acCoolingPolicy.Integer, dcCoolingPolicy.Integer
  Protected acASPMValue.Integer, dcASPMValue.Integer

  If profileId < #PROFILE_BATTERY_SAVER Or profileId > #PROFILE_PERFORMANCE
    ProcedureReturn
  EndIf

  LoadProfileDefaults(profileId, @acMax, @dcMax, @acMin, @dcMin,
                      @acBoostValue, @dcBoostValue,
                      @acCoolingPolicy, @dcCoolingPolicy,
                      @acASPMValue, @dcASPMValue)

  If isAC
    SetGadgetState(#TrackACMax, acMax\i)
    SetGadgetState(#TrackACMin, acMin\i)
    If useBoost
      SetComboStateByData(#ComboACBoost, acBoostValue\i, 0)
    EndIf
    If useCooling
      SetComboStateByData(#ComboACCooling, acCoolingPolicy\i, 0)
    EndIf
    If useASPM
      SetComboStateByData(#ComboACASPM, acASPMValue\i, 1)
    EndIf
  Else
    SetGadgetState(#TrackDCMax, dcMax\i)
    SetGadgetState(#TrackDCMin, dcMin\i)
    If useBoost
      SetComboStateByData(#ComboDCBoost, dcBoostValue\i, 0)
    EndIf
    If useCooling
      SetComboStateByData(#ComboDCCooling, dcCoolingPolicy\i, 0)
    EndIf
    If useASPM
      SetComboStateByData(#ComboDCASPM, dcASPMValue\i, 1)
    EndIf
  EndIf

  UpdateDisplayedValues(useBoost, useCooling, useASPM)
EndProcedure
Procedure.i ACCoolingPolicyArg(useCooling.i)
  If useCooling
    ProcedureReturn GetSelectedItemData(#ComboACCooling, 0)
  EndIf
  ProcedureReturn -1
EndProcedure
Procedure.i DCCoolingPolicyArg(useCooling.i)
  If useCooling
    ProcedureReturn GetSelectedItemData(#ComboDCCooling, 1)
  EndIf
  ProcedureReturn -1
EndProcedure
Procedure.i ACASPMArg(useASPM.i)
  If useASPM
    ProcedureReturn GetSelectedItemData(#ComboACASPM, 1)
  EndIf
  ProcedureReturn -1
EndProcedure
Procedure.i DCASPMArg(useASPM.i)
  If useASPM
    ProcedureReturn GetSelectedItemData(#ComboDCASPM, 2)
  EndIf
  ProcedureReturn -1
EndProcedure
Procedure.i ACBoostArg(useBoost.i)
  If useBoost
    ProcedureReturn GetSelectedItemData(#ComboACBoost, #BOOST_DISABLED)
  EndIf
  ProcedureReturn #BOOST_DISABLED
EndProcedure
Procedure.i DCBoostArg(useBoost.i)
  If useBoost
    ProcedureReturn GetSelectedItemData(#ComboDCBoost, #BOOST_DISABLED)
  EndIf
  ProcedureReturn #BOOST_DISABLED
EndProcedure
Procedure LoadPreset(useBoost.i, useCooling.i, useASPM.i,
                     acMax.i, dcMax.i, acMin.i, dcMin.i,
                     acBoostValue.i, dcBoostValue.i,
                     acCoolingPolicy.i, dcCoolingPolicy.i,
                     acASPMValue.i, dcASPMValue.i)
  SetGadgetState(#TrackACMax, acMax)
  SetGadgetState(#TrackDCMax, dcMax)
  SetGadgetState(#TrackACMin, acMin)
  SetGadgetState(#TrackDCMin, dcMin)

  If useBoost
    SetComboStateByData(#ComboACBoost, acBoostValue, 0)
    SetComboStateByData(#ComboDCBoost, dcBoostValue, 0)
  EndIf

  If useCooling
    SetComboStateByData(#ComboACCooling, acCoolingPolicy, 0)
    SetComboStateByData(#ComboDCCooling, dcCoolingPolicy, 0)
  EndIf

  If useASPM
    SetComboStateByData(#ComboACASPM, acASPMValue, 1)
    SetComboStateByData(#ComboDCASPM, dcASPMValue, 1)
  EndIf
  UpdateDisplayedValues(useBoost, useCooling, useASPM)
EndProcedure
Procedure UpdateDisplayedValues(useBoost.i, useCooling.i, useASPM.i)
  Protected acMax.i = GetGadgetState(#TrackACMax)
  Protected dcMax.i = GetGadgetState(#TrackDCMax)
  Protected acMin.i = GetGadgetState(#TrackACMin)
  Protected dcMin.i = GetGadgetState(#TrackDCMin)
  Protected acBoostValue.i
  Protected dcBoostValue.i
  Protected acCoolingValue.i
  Protected dcCoolingValue.i
  Protected acASPMValue.i
  Protected dcASPMValue.i
  Protected score.i

  SetGadgetText(#TxtACMaxVal, Str(acMax) + "%")
  SetGadgetText(#TxtDCMaxVal, Str(dcMax) + "%")
  SetGadgetText(#TxtACMinVal, Str(acMin) + "%")
  SetGadgetText(#TxtDCMinVal, Str(dcMin) + "%")

  If useBoost
    acBoostValue = ACBoostArg(useBoost)
    dcBoostValue = DCBoostArg(useBoost)
    SetGadgetText(#TxtACBoostVal, "AC boost: " + BoostModeLabel(acBoostValue) + " (" + Str(acBoostValue) + ")")
    SetGadgetText(#TxtDCBoostVal, "DC boost: " + BoostModeLabel(dcBoostValue) + " (" + Str(dcBoostValue) + ")")
  Else
    acBoostValue = #BOOST_DISABLED
    dcBoostValue = #BOOST_DISABLED
    SetGadgetText(#TxtACBoostVal, "AC boost: N/A")
    SetGadgetText(#TxtDCBoostVal, "DC boost: N/A")
  EndIf

  If useCooling
    acCoolingValue = ACCoolingPolicyArg(useCooling)
    dcCoolingValue = DCCoolingPolicyArg(useCooling)
  Else
    acCoolingValue = 0
    dcCoolingValue = 0
  EndIf

  If useASPM
    acASPMValue = ACASPMArg(useASPM)
    dcASPMValue = DCASPMArg(useASPM)
  Else
    acASPMValue = 1
    dcASPMValue = 1
  EndIf

  score = ThermalScore(acMax, dcMax, acBoostValue, dcBoostValue, acCoolingValue, dcCoolingValue, acASPMValue, dcASPMValue)
  SetGadgetText(#TxtThermalHint, ThermalHintText(score) + " Thermal score: " + Str(score) + "/100. AC " + CoolingPolicyLabel(acCoolingValue) + ", DC " + CoolingPolicyLabel(dcCoolingValue) + ", AC ASPM " + ASPMLabel(acASPMValue) + ", DC ASPM " + ASPMLabel(dcASPMValue) + ".")
EndProcedure
Procedure UpdateMiniDashboard()
  Protected thermalText$
  Protected loadText$
  Protected idx.i

  If IsWindow(#WinMini) = 0
    ProcedureReturn
  EndIf

  loadText$ = gTelemetry\CpuLoad
  If loadText$ = "" : loadText$ = "Unavailable" : EndIf
  thermalText$ = gTelemetry\ThermalC
  If thermalText$ = "" : thermalText$ = "Unavailable" : EndIf

  If gTelemetry\ThermalC <> "" And LCase(gTelemetry\ThermalC) <> "unavailable"
    For idx = 0 To #HISTORY_POINTS - 2
      gThermalHistory(idx) = gThermalHistory(idx + 1)
      gCpuLoadHistory(idx) = gCpuLoadHistory(idx + 1)
    Next
    gThermalHistory(#HISTORY_POINTS - 1) = Val(gTelemetry\ThermalC)
    gCpuLoadHistory(#HISTORY_POINTS - 1) = Val(gTelemetry\CpuLoad)
    If gHistoryCount < #HISTORY_POINTS
      gHistoryCount + 1
    EndIf
  EndIf

  SetGadgetText(#TxtMiniTelemetry, "CPU " + loadText$ + "% | " + gTelemetry\PowerSource)
  SetGadgetText(#TxtMiniThermal, "Thermal zone " + thermalText$ + " C | " + gTelemetry\LastUpdated)
  RefreshMiniProfileBadge()
  UpdateAutomationDisplay()
  DrawMiniHistory()
EndProcedure
Procedure RefreshMiniProfileBadge()
  Protected acProfile$ = "Custom"
  Protected dcProfile$ = "Custom"

  If gSettings\ACProfile > 0
    acProfile$ = ProfileIdToName(gSettings\ACProfile)
  EndIf
  If gSettings\DCProfile > 0
    dcProfile$ = ProfileIdToName(gSettings\DCProfile)
  EndIf

  If IsGadget(#TxtMiniProfile)
    SetGadgetText(#TxtMiniProfile, "AC " + acProfile$ + " | DC " + dcProfile$)
  EndIf
EndProcedure
Procedure DrawMiniHistory()
  Protected w.i, h.i, i.i, x1.i, y1.i, x2.i, y2.i

  If StartDrawing(CanvasOutput(#CanvasMiniHistory)) = 0
    ProcedureReturn
  EndIf

  w = OutputWidth()
  h = OutputHeight()
  Box(0, 0, w, h, RGB(18, 23, 29))
  Box(0, h / 2, w, 1, RGB(45, 55, 66))

  If gHistoryCount > 1
    For i = #HISTORY_POINTS - gHistoryCount To #HISTORY_POINTS - 2
      x1 = (i - (#HISTORY_POINTS - gHistoryCount)) * (w - 1) / (gHistoryCount - 1)
      x2 = (i + 1 - (#HISTORY_POINTS - gHistoryCount)) * (w - 1) / (gHistoryCount - 1)
      y1 = h - (gThermalHistory(i) * (h - 1) / 100)
      y2 = h - (gThermalHistory(i + 1) * (h - 1) / 100)
      LineXY(x1, y1, x2, y2, RGB(255, 120, 80))
      y1 = h - (gCpuLoadHistory(i) * (h - 1) / 100)
      y2 = h - (gCpuLoadHistory(i + 1) * (h - 1) / 100)
      LineXY(x1, y1, x2, y2, RGB(90, 180, 255))
    Next
  EndIf

  DrawText(8, 8, "Temp", RGB(255, 120, 80), RGB(18, 23, 29))
  DrawText(52, 8, "Load", RGB(90, 180, 255), RGB(18, 23, 29))
  StopDrawing()
EndProcedure
Procedure ShowMainWindow(showWindow.i)
  If showWindow
    EnsureTrayIcon()
    HideWindow(#Win, #False)
    SetActiveWindow(#Win)
    gMainWindowVisible = #True
  Else
    EnsureTrayIcon()
    HideWindow(#Win, #True)
    gMainWindowVisible = #False
  EndIf
  UpdateTrayMenuState()
EndProcedure
Procedure ShowMiniDashboard(showWindow.i)
  If showWindow
    EnsureTrayIcon()
    HideWindow(#WinMini, #False)
    SetActiveWindow(#WinMini)
    gMiniWindowVisible = #True
  Else
    EnsureTrayIcon()
    HideWindow(#WinMini, #True)
    gMiniWindowVisible = #False
  EndIf
  UpdateTrayMenuState()
EndProcedure
Procedure UpdateTrayMenuState()
  EnsureTrayIcon()

  If IsMenu(#TrayMain)
    SetMenuItemState(#TrayMain, #MenuTrayRunAtStartup, gSettings\RunAtStartup)
    SetMenuItemState(#TrayMain, #MenuTrayUseTaskScheduler, gSettings\UseTaskScheduler)
    SetMenuItemState(#TrayMain, #MenuTrayStartupMain, Bool(gSettings\StartupMode = 0))
    SetMenuItemState(#TrayMain, #MenuTrayStartupTray, Bool(gSettings\StartupMode = 1))
    SetMenuItemState(#TrayMain, #MenuTrayStartupMini, Bool(gSettings\StartupMode = 2))
    SetMenuItemState(#TrayMain, #MenuTrayStartupSilent, Bool(gSettings\StartupMode = 3))
    DisableMenuItem(#TrayMain, #MenuTrayUseTaskScheduler, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupMain, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupTray, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupMini, Bool(gSettings\RunAtStartup = 0))
    DisableMenuItem(#TrayMain, #MenuTrayStartupSilent, Bool(gSettings\RunAtStartup = 0))
  EndIf

  If gTrayReady
    If gMainWindowVisible
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - main window open | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - main window open")
      EndIf
    ElseIf gMiniWindowVisible
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - mini dashboard open | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - mini dashboard open")
      EndIf
    Else
      If gLastApplyMessage <> ""
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - running in tray | " + gLastApplyMessage)
      Else
        SysTrayIconToolTip(#TrayMain, #APP_NAME + " - running in tray")
      EndIf
    EndIf
  EndIf
EndProcedure
Procedure ResetApplyDiagnostics(*diag.ApplyDiagnostics)
  If *diag = 0
    ProcedureReturn
  EndIf

  *diag\SuccessCount = 0
  *diag\FailureCount = 0
  *diag\Summary = ""
  *diag\Details = ""
EndProcedure
Procedure CreateTrayPopupMenu()
  If CreatePopupMenu(#TrayMain)
    MenuItem(#MenuTrayShowHide, "Toggle Window")
    MenuItem(#MenuTrayMiniDashboard, "Mini Dashboard")
    MenuItem(#MenuTrayApply, "Apply Current Settings")
    MenuBar()
    MenuItem(#MenuTrayRunAtStartup, "Run At Startup")
    MenuItem(#MenuTrayUseTaskScheduler, "Use Task Scheduler")
    MenuItem(#MenuTrayStartupMain, "Startup: Main Window")
    MenuItem(#MenuTrayStartupTray, "Startup: Tray")
    MenuItem(#MenuTrayStartupMini, "Startup: Mini Dashboard")
    MenuItem(#MenuTrayStartupSilent, "Startup: Silent Apply")
    MenuBar()
    MenuItem(#MenuTrayBattery, "Battery Preset")
    MenuItem(#MenuTrayEco, "Eco Preset")
    MenuItem(#MenuTrayQuiet, "Quiet Preset")
    MenuItem(#MenuTrayCool, "Cool Preset")
    MenuItem(#MenuTrayBalanced, "Balanced Preset")
    MenuItem(#MenuTrayPerformance, "Performance Preset")
    MenuBar()
    MenuItem(#MenuTrayRestoreBalanced, "Restore Windows Balanced")
    MenuBar()
    MenuItem(#MenuTrayExit, "Exit")
  EndIf
EndProcedure
Procedure CreateApplicationWindows(scheme$, useBoost.i, useCooling.i, useASPM.i, *applyDiag.ApplyDiagnostics)
  OpenWindow(#Win, 0, 0, 900, 830, #APP_NAME + " - " + version + " (powercfg)", #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
  LogLine(#LOG_INFO, "UI started")

  OpenWindow(#WinMini, 0, 0, 290, 140, #APP_NAME + " Mini", #PB_Window_SystemMenu | #PB_Window_Tool | #PB_Window_ScreenCentered)
  HideWindow(#WinMini, #True)
  UseGadgetList(WindowID(#WinMini))
  ResizeWindow(#WinMini, #PB_Ignore, #PB_Ignore, 360, 530)
  TextGadget(#TxtMiniTelemetry, 12, 12, 336, 20, "CPU -- | --")
  TextGadget(#TxtMiniThermal, 12, 34, 336, 20, "Thermal zone --")
  TextGadget(#TxtMiniProfile, 12, 56, 336, 20, "AC -- | DC --")
  TextGadget(#TxtAutomationMode, 12, 76, 336, 18, "AC automation -> Quiet | Restore 72 C / 45 sec")
  CanvasGadget(#CanvasMiniHistory, 12, 96, 336, 76)
  TextGadget(#TxtBenchmarkMode, 12, 178, 336, 18, "Benchmark mode inactive")
  TextGadget(#PB_Any, 12, 200, 170, 18, "Heat alert threshold")
  TextGadget(#TxtHeatAlertVal, 294, 200, 54, 18, "80 C")
  TrackBarGadget(#TrackHeatAlert, 12, 218, 336, 22, 60, 100)
  CheckBoxGadget(#ChkHeatAlertPopup, 12, 244, 200, 20, "Enable heat popup alerts")
  CheckBoxGadget(#ChkAutoThermalSwitch, 12, 268, 210, 20, "Auto switch when heat persists")
  ComboBoxGadget(#ComboAutoSwitchProfile, 12, 292, 164, 24)
  TextGadget(#TxtAutoSwitchVal, 248, 294, 100, 18, "80 C / 30 sec")
  TrackBarGadget(#TrackAutoSwitchDelay, 184, 292, 164, 22, 10, 120)
  CheckBoxGadget(#ChkAutoRestore, 12, 322, 210, 20, "Restore after cooldown")
  TextGadget(#TxtAutoRestoreVal, 248, 324, 100, 18, "70 C / 45 sec")
  TrackBarGadget(#TrackAutoRestoreThreshold, 12, 344, 164, 22, 50, 95)
  TrackBarGadget(#TrackAutoRestoreDelay, 184, 344, 164, 22, 15, 180)
  ButtonGadget(#BtnSaveCustomProfile, 12, 374, 108, 24, "Save Slot")
  ButtonGadget(#BtnLoadCustomProfile, 126, 374, 108, 24, "Load Slot")
  ButtonGadget(#BtnBenchmarkMode, 240, 374, 108, 24, "Benchmark")
  ButtonGadget(#BtnExportProfile, 12, 404, 108, 24, "Export")
  ButtonGadget(#BtnImportProfile, 126, 404, 108, 24, "Import")
  ComboBoxGadget(#ComboCustomProfile, 240, 404, 108, 24)
  TextGadget(#PB_Any, 12, 434, 120, 18, "Startup mode")
  ComboBoxGadget(#ComboStartupMode, 132, 430, 216, 24)
  ButtonGadget(#BtnMiniToggleMain, 12, 462, 108, 26, "Show Main")
  ButtonGadget(#BtnMiniApply, 126, 462, 108, 26, "Apply")
  ButtonGadget(#BtnMiniBattery, 240, 462, 108, 26, "Battery")
  ButtonGadget(#BtnMiniEco, 12, 494, 62, 26, "Eco")
  ButtonGadget(#BtnMiniQuiet, 82, 494, 62, 26, "Quiet")
  ButtonGadget(#BtnMiniCool, 152, 494, 62, 26, "Cool")
  ButtonGadget(#BtnMiniBalanced, 222, 494, 62, 26, "Balanced")
  ButtonGadget(#BtnMiniPerformance, 292, 494, 56, 26, "Perf")

  UseGadgetList(WindowID(#Win))

  TextGadget(#PB_Any, 15, 15, 870, 20, "Custom power scheme: " + scheme$)
  TextGadget(#PB_Any, 15, 42, 870, 20, "Tune AC and battery behavior separately to keep laptops cooler than one-size-fits-all presets.")
  TextGadget(#PB_Any, 15, 78, 250, 20, "AC (Plugged in) Max CPU %")
  TextGadget(#TxtACMaxVal, 840, 78, 45, 20, "")
  TrackBarGadget(#TrackACMax, 15, 98, 870, 25, 5, 100)
  SetGadgetState(#TrackACMax, gSettings\ACMaxCPU)
  TextGadget(#PB_Any, 15, 133, 250, 20, "DC (Battery) Max CPU %")
  TextGadget(#TxtDCMaxVal, 840, 133, 45, 20, "")
  TrackBarGadget(#TrackDCMax, 15, 153, 870, 25, 5, 100)
  SetGadgetState(#TrackDCMax, gSettings\DCMaxCPU)
  TextGadget(#PB_Any, 15, 188, 250, 20, "AC (Plugged in) Min CPU %")
  TextGadget(#TxtACMinVal, 840, 188, 45, 20, "")
  TrackBarGadget(#TrackACMin, 15, 208, 870, 25, 1, 100)
  SetGadgetState(#TrackACMin, gSettings\ACMinCPU)
  TextGadget(#PB_Any, 15, 243, 250, 20, "DC (Battery) Min CPU %")
  TextGadget(#TxtDCMinVal, 840, 243, 45, 20, "")
  TrackBarGadget(#TrackDCMin, 15, 263, 870, 25, 1, 100)
  SetGadgetState(#TrackDCMin, gSettings\DCMinCPU)
  TextGadget(#PB_Any, 15, 305, 120, 20, "AC profile:")
  ComboBoxGadget(#ComboACProfile, 15, 325, 425, 25)
  TextGadget(#PB_Any, 460, 305, 120, 20, "DC profile:")
  ComboBoxGadget(#ComboDCProfile, 460, 325, 425, 25)
  TextGadget(#PB_Any, 15, 365, 250, 20, "AC boost mode:")
  ComboBoxGadget(#ComboACBoost, 15, 385, 425, 25)
  TextGadget(#TxtACBoostVal, 15, 412, 425, 20, "")
  TextGadget(#PB_Any, 460, 365, 250, 20, "DC boost mode:")
  ComboBoxGadget(#ComboDCBoost, 460, 385, 425, 25)
  TextGadget(#TxtDCBoostVal, 460, 412, 425, 20, "")
  TextGadget(#PB_Any, 15, 445, 250, 20, "AC cooling policy:")
  ComboBoxGadget(#ComboACCooling, 15, 465, 425, 25)
  TextGadget(#PB_Any, 460, 445, 250, 20, "DC cooling policy:")
  ComboBoxGadget(#ComboDCCooling, 460, 465, 425, 25)
  TextGadget(#PB_Any, 15, 505, 250, 20, "AC Link State Power Mgmt (ASPM):")
  ComboBoxGadget(#ComboACASPM, 15, 525, 425, 25)
  TextGadget(#PB_Any, 460, 505, 250, 20, "DC Link State Power Mgmt (ASPM):")
  ComboBoxGadget(#ComboDCASPM, 460, 525, 425, 25)
  TextGadget(#TxtThermalHint, 15, 565, 870, 28, "")
  TextGadget(#TxtTelemetrySummary, 15, 596, 870, 18, "Live telemetry: starting...")
  TextGadget(#TxtTelemetryUpdated, 15, 616, 870, 18, "Waiting for first refresh.")

  PopulateASPMCombo()
  PopulateCoolingCombo()
  PopulateBoostCombo()
  PopulateProfileCombo(#ComboACProfile)
  PopulateProfileCombo(#ComboDCProfile)
  PopulatePresetOnlyProfileCombo(#ComboAutoSwitchProfile)
  PopulateStartupModeCombo(#ComboStartupMode)
  LoadCustomProfiles()
  RefreshCustomProfileCombo()
  SetComboStateByData(#ComboACBoost, gSettings\ACBoostMode, 0)
  SetComboStateByData(#ComboDCBoost, gSettings\DCBoostMode, 0)
  SetComboStateByData(#ComboACCooling, gSettings\ACCoolingPolicy, 0)
  SetComboStateByData(#ComboDCCooling, gSettings\DCCoolingPolicy, 1)
  SetComboStateByData(#ComboACASPM, gSettings\ACASPMMode, 1)
  SetComboStateByData(#ComboDCASPM, gSettings\DCASPMMode, 1)
  UpdateProfilesFromCurrentUI(@gSettings)
  SyncProfileCombosFromSettings(@gSettings)

  If useBoost = #False
    DisableGadget(#ComboACBoost, #True)
    DisableGadget(#ComboDCBoost, #True)
    SetGadgetText(#TxtACBoostVal, "AC boost: Not supported on this system")
    SetGadgetText(#TxtDCBoostVal, "DC boost: Not supported on this system")
  EndIf

  If useCooling = #False
    DisableGadget(#ComboACCooling, #True)
    DisableGadget(#ComboDCCooling, #True)
  EndIf

  If useASPM = #False
    DisableGadget(#ComboACASPM, #True)
    DisableGadget(#ComboDCASPM, #True)
  EndIf

  CheckBoxGadget(#ChkAutoApply, 15, 650, 425, 20, "Auto apply saved settings on startup")
  SetGadgetState(#ChkAutoApply, gSettings\AutoApply)
  CheckBoxGadget(#ChkLiveApply, 460, 650, 425, 20, "Live apply while adjusting")
  SetGadgetState(#ChkLiveApply, gSettings\LiveApply)
  CheckBoxGadget(#ChkRunAtStartup, 15, 674, 425, 20, "Run at Windows startup (applies settings silently)")
  SetGadgetState(#ChkRunAtStartup, gSettings\RunAtStartup)
  CheckBoxGadget(#ChkUseTaskScheduler, 460, 674, 425, 20, "Use Task Scheduler (no UAC prompt at login)")
  SetGadgetState(#ChkUseTaskScheduler, gSettings\UseTaskScheduler)
  SetGadgetState(#TrackHeatAlert, gSettings\HeatAlertThreshold)
  SetGadgetText(#TxtHeatAlertVal, Str(gSettings\HeatAlertThreshold) + " C")
  SetGadgetState(#ChkHeatAlertPopup, gSettings\HeatAlertEnabled)
  gHeatAlertThreshold = gSettings\HeatAlertThreshold
  gHeatPopupEnabled = gSettings\HeatAlertEnabled
  SetGadgetState(#ChkAutoThermalSwitch, gSettings\AutoThermalSwitchEnabled)
  SetComboStateByData(#ComboAutoSwitchProfile, gSettings\DCAutoSwitchProfile, 3)
  SetGadgetState(#TrackAutoSwitchDelay, gSettings\DCAutoSwitchSeconds)
  SetGadgetText(#TxtAutoSwitchVal, Str(gSettings\DCAutoSwitchThreshold) + " C / " + Str(gSettings\DCAutoSwitchSeconds) + " sec")
  SetComboStateByData(#ComboStartupMode, gSettings\StartupMode, 0)
  SetGadgetState(#ChkAutoRestore, gSettings\AutoRestoreEnabled)
  SetGadgetState(#TrackAutoRestoreThreshold, gSettings\DCAutoRestoreThreshold)
  SetGadgetState(#TrackAutoRestoreDelay, gSettings\DCAutoRestoreSeconds)
  SetGadgetText(#TxtAutoRestoreVal, Str(gSettings\DCAutoRestoreThreshold) + " C / " + Str(gSettings\DCAutoRestoreSeconds) + " sec")
  SetGadgetText(#TxtBenchmarkMode, "Benchmark mode inactive")
  gAutoThermalSwitchEnabled = gSettings\AutoThermalSwitchEnabled
  gAutoThermalSwitchProfile = gSettings\AutoThermalSwitchProfile
  gAutoThermalSwitchSeconds = gSettings\AutoThermalSwitchSeconds
  gAutoRestoreEnabled = gSettings\AutoRestoreEnabled
  gAutoRestoreThreshold = gSettings\AutoRestoreThreshold
  gAutoRestoreSeconds = gSettings\AutoRestoreSeconds

  ButtonGadget(#BtnApply, 15, 700, 870, 28, "Apply now")
  UpdateDisplayedValues(useBoost, useCooling, useASPM)
  UpdateTelemetryDisplay()
  EnsureTrayIcon()
  CreateTrayPopupMenu()
  AddWindowTimer(#Win, #TimerTelemetry, 7000)
  StartTelemetryRefresh()
  UpdateTrayMenuState()
  RefreshMiniProfileBadge()
  ButtonGadget(#BtnBatteryPreset, 15, 738, 140, 26, "Battery")
  ButtonGadget(#BtnEcoPreset, 160, 738, 140, 26, "Eco")
  ButtonGadget(#BtnQuietPreset, 305, 738, 140, 26, "Quiet")
  ButtonGadget(#BtnCoolPreset, 450, 738, 140, 26, "Cool")
  ButtonGadget(#BtnBalancedPreset, 595, 738, 140, 26, "Balanced")
  ButtonGadget(#BtnPerfPreset, 740, 738, 145, 26, "Performance")
  TextGadget(#TxtStatusSummary, 15, 770, 870, 18, "Status: Ready")
  EditorGadget(#EditStatusDetails, 15, 790, 870, 18)
  DisableGadget(#EditStatusDetails, #True)
  SetStatus("Status: Ready", "Waiting for changes.")
  ButtonGadget(#BtnRestoreBalanced, 15, 810, 870, 18, "Restore Windows Balanced plan (activate default)")

  If gSettings\AutoApply
    LogLine(#LOG_INFO, "AutoApply enabled; applying on startup")
    ResetApplyDiagnostics(*applyDiag)
    ApplyCurrentGadgetSettings(scheme$, useBoost, useCooling, useASPM, *applyDiag)
    SetStatus("Status: " + *applyDiag\Summary, *applyDiag\Details)
  Else
    LogLine(#LOG_INFO, "AutoApply disabled")
  EndIf

  UpdateTrayMenuState()
EndProcedure
Procedure ApplyStartupWindowMode(startInTray.i, startInMini.i)
  Select gSettings\StartupMode
    Case 1
      ShowMainWindow(#False)
    Case 2
      ShowMainWindow(#False)
      ShowMiniDashboard(#True)
  EndSelect

  If startInTray
    ShowMainWindow(#False)
    ShowMiniDashboard(#False)
  ElseIf startInMini
    ShowMainWindow(#False)
    ShowMiniDashboard(#True)
  EndIf
EndProcedure
Procedure LoadSettingsIntoUI(*settings.AppSettings)
  If *settings = 0
    ProcedureReturn
  EndIf

  If *settings\ACProfile <= 0 : *settings\ACProfile = #PROFILE_COOL : EndIf
  If *settings\DCProfile <= 0 : *settings\DCProfile = #PROFILE_BALANCED : EndIf

  SetGadgetState(#TrackACMax, *settings\ACMaxCPU)
  SetGadgetState(#TrackDCMax, *settings\DCMaxCPU)
  SetGadgetState(#TrackACMin, *settings\ACMinCPU)
  SetGadgetState(#TrackDCMin, *settings\DCMinCPU)
  SetComboStateByData(#ComboACProfile, *settings\ACProfile, 0)
  SetComboStateByData(#ComboDCProfile, *settings\DCProfile, 0)
  SetComboStateByData(#ComboACBoost, *settings\ACBoostMode, 0)
  SetComboStateByData(#ComboDCBoost, *settings\DCBoostMode, 0)
  SetComboStateByData(#ComboACCooling, *settings\ACCoolingPolicy, 0)
  SetComboStateByData(#ComboDCCooling, *settings\DCCoolingPolicy, 1)
  SetComboStateByData(#ComboACASPM, *settings\ACASPMMode, 1)
  SetComboStateByData(#ComboDCASPM, *settings\DCASPMMode, 1)
  SetGadgetState(#ChkAutoApply, *settings\AutoApply)
  SetGadgetState(#ChkLiveApply, *settings\LiveApply)
  SetGadgetState(#ChkRunAtStartup, *settings\RunAtStartup)
  SetGadgetState(#ChkUseTaskScheduler, *settings\UseTaskScheduler)
  SetGadgetState(#TrackHeatAlert, *settings\HeatAlertThreshold)
  SetGadgetText(#TxtHeatAlertVal, Str(*settings\HeatAlertThreshold) + " C")
  SetGadgetState(#ChkHeatAlertPopup, *settings\HeatAlertEnabled)
  SetGadgetState(#ChkAutoThermalSwitch, *settings\DCAutoSwitchEnabled)
  SetComboStateByData(#ComboAutoSwitchProfile, *settings\DCAutoSwitchProfile, 0)
  SetGadgetState(#TrackAutoSwitchDelay, *settings\DCAutoSwitchSeconds)
  SetGadgetText(#TxtAutoSwitchVal, Str(*settings\DCAutoSwitchThreshold) + " C / " + Str(*settings\DCAutoSwitchSeconds) + " sec")
  SetGadgetState(#ChkAutoRestore, *settings\DCAutoRestoreEnabled)
  SetGadgetState(#TrackAutoRestoreThreshold, *settings\DCAutoRestoreThreshold)
  SetGadgetState(#TrackAutoRestoreDelay, *settings\DCAutoRestoreSeconds)
  SetGadgetText(#TxtAutoRestoreVal, Str(*settings\DCAutoRestoreThreshold) + " C / " + Str(*settings\DCAutoRestoreSeconds) + " sec")
  SetComboStateByData(#ComboStartupMode, *settings\StartupMode, 0)
  UpdateProfilesFromCurrentUI(*settings)
  SyncProfileCombosFromSettings(*settings)
  UpdateDisplayedValues(gUseBoost, gUseCooling, gUseASPM)
  UpdateAutomationDisplay()
EndProcedure
