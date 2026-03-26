EnsureAdmin()

gIniPath = GetPathPart(ProgramFilename()) + #APP_NAME + ".ini"
LogLine(#LOG_INFO, "iniPath=" + gIniPath)

; Quick probe (debug only): ensure powercfg is runnable and output capture works.
If gLogLevel = #LOG_DEBUG
  RunProgramCapture("powercfg", "/?")
  LogLine(#LOG_DEBUG, "powercfg probe exit=" + Str(gLastExitCode) + " outLen=" + Str(Len(gLastStdout)))
EndIf

StartSystemInfoUpdate(gIniPath)


Define applyDiag.ApplyDiagnostics
LoadAppSettings(gIniPath, @gSettings)

Define scheme$  = EnsureCustomScheme(#APP_NAME, gIniPath)
LogLine(#LOG_INFO, "Using scheme=" + scheme$)
gCurrentScheme = scheme$

; Ensure settings match what's currently in registry/INI (already done by LoadAppSettings)

Define useBoost.i = SupportsBoostModeSetting(scheme$)

LogLine(#LOG_INFO, "Supports boost setting=" + Str(useBoost))

Define useCooling.i = SupportsCoolingPolicySetting(scheme$)
LogLine(#LOG_INFO, "Supports cooling policy setting=" + Str(useCooling))
Define useASPM.i = SupportsASPMSetting(scheme$)
LogLine(#LOG_INFO, "Supports ASPM setting=" + Str(useASPM))

; Startup/background modes
If HasArg("--silent")
  LogLine(#LOG_INFO, "--silent requested; applying saved settings and exiting")
  If gSettings\AutoApply
    ApplySettings(scheme$, gSettings\ACMaxCPU, gSettings\DCMaxCPU, gSettings\ACMinCPU, gSettings\DCMinCPU,
                  gSettings\ACBoostMode, gSettings\DCBoostMode, useBoost,
                  gSettings\ACCoolingPolicy, gSettings\DCCoolingPolicy,
                  gSettings\ACASPMMode, gSettings\DCASPMMode)
  Else
    LogLine(#LOG_INFO, "AutoApply disabled; silent start exits without changing power settings")
  EndIf
  CloseHandle_(hMutex)
  End
EndIf

Define startInTray.i = HasArg("--tray")
Define startInMini.i = HasArg("--mini")


gUseBoost = useBoost
gUseCooling = useCooling
gUseASPM = useASPM
CreateApplicationWindows(scheme$, useBoost, useCooling, useASPM, @applyDiag)
ApplyStartupWindowMode(startInTray, startInMini)



Define ev, acBoostValue, dcBoostValue

Repeat
  ev = WaitWindowEvent()

  Select ev
    Case #PB_Event_Gadget
      HandleGadgetEvent(EventGadget(), scheme$, useBoost, useCooling, useASPM, @applyDiag)

    Case #PB_Event_Menu
      HandleMenuEvent(EventMenu(), @applyDiag)

    Case #PB_Event_Timer
      HandleTimerEvent(EventTimer())

    Case #PB_Event_SysTray
      HandleSysTrayEvent(EventType())

    Case #PB_Event_CloseWindow
      HandleCloseWindowEvent(EventWindow())

  EndSelect
ForEver
