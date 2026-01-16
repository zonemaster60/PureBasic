;------------------------------------------------------------------------------
; Preferences (INI) (extracted from pbzt.pb)
;------------------------------------------------------------------------------

Procedure.s PrefGetPath()
  ; Store next to the running executable.
  Protected base.s = GetPathPart(ProgramFilename())
  ProcedureReturn base + #APP_NAME + ".ini"
EndProcedure

Procedure LoadPrefs()
  PrefPath = PrefGetPath()

  ; Defaults (keep in sync with globals' initial values)
  SfxMasterVol = 1.0
  SfxPitchMul  = 1.0
  SfxNoiseMul  = 1.0
  SfxVibMul    = 1.0
  MusicMasterVol = 0.25
  DebugOverlay = 0
  DebugWindowSizing = 0
  PrefLastWorldPath = ""
  PrefLevelsDir = ""
  PrefSaveDir = ""
  PrefQuickSaveSlot = 1

  ; Window prefs are optional; 0 means "unspecified".
  PrefWinX = 0
  PrefWinY = 0
  PrefWinW = 0
  PrefWinH = 0

  If FileSize(PrefPath) <= 0
    ProcedureReturn
  EndIf

  If OpenPreferences(PrefPath)
    PreferenceGroup("Sound")
    SfxMasterVol = ClampF(ReadPreferenceFloat("SfxMasterVol", SfxMasterVol), 0.0, 4.0)
    MusicMasterVol = ClampF(ReadPreferenceFloat("MusicMasterVol", MusicMasterVol), 0.0, 1.0)
    SfxPitchMul  = ClampF(ReadPreferenceFloat("SfxPitch", SfxPitchMul), 0.5, 2.0)
    SfxNoiseMul  = ClampF(ReadPreferenceFloat("SfxNoise", SfxNoiseMul), 0.0, 2.0)
    SfxVibMul    = ClampF(ReadPreferenceFloat("SfxVib", SfxVibMul), 0.0, 2.0)

    PreferenceGroup("Debug")
    DebugOverlay = Bool(ReadPreferenceInteger("Overlay", DebugOverlay) <> 0)
    DebugWindowSizing = Bool(ReadPreferenceInteger("WindowSizing", DebugWindowSizing) <> 0)

    PreferenceGroup("World")
    PrefLastWorldPath = ReadPreferenceString("LastWorldPath", "")
    PrefLevelsDir = ReadPreferenceString("LevelsDir", "")
    PrefSaveDir = ReadPreferenceString("SaveDir", "")
    PrefQuickSaveSlot = Clamp(ReadPreferenceInteger("QuickSaveSlot", PrefQuickSaveSlot), 1, 5)

    PreferenceGroup("Window")
    PrefWinX = ReadPreferenceInteger("X", 0)
    PrefWinY = ReadPreferenceInteger("Y", 0)
    PrefWinW = ReadPreferenceInteger("W", 0)
    PrefWinH = ReadPreferenceInteger("H", 0)

    ClosePreferences()
  EndIf
EndProcedure

Procedure SavePrefs()
  PrefPath = PrefGetPath()

  If CreatePreferences(PrefPath)
    PreferenceGroup("Sound")
    WritePreferenceFloat("SfxMasterVol", ClampF(SfxMasterVol, 0.0, 4.0))
    WritePreferenceFloat("MusicMasterVol", ClampF(MusicMasterVol, 0.0, 1.0))
    WritePreferenceFloat("SfxPitch", ClampF(SfxPitchMul, 0.5, 2.0))
    WritePreferenceFloat("SfxNoise", ClampF(SfxNoiseMul, 0.0, 2.0))
    WritePreferenceFloat("SfxVib", ClampF(SfxVibMul, 0.0, 2.0))

    PreferenceGroup("Debug")
    WritePreferenceInteger("Overlay", Bool(DebugOverlay <> 0))
    WritePreferenceInteger("WindowSizing", Bool(DebugWindowSizing <> 0))

    PreferenceGroup("World")
    WritePreferenceString("LastWorldPath", PrefLastWorldPath)
    WritePreferenceString("LevelsDir", PrefLevelsDir)
    WritePreferenceString("SaveDir", PrefSaveDir)
    WritePreferenceInteger("QuickSaveSlot", Clamp(PrefQuickSaveSlot, 1, 5))

    PreferenceGroup("Window")
    WritePreferenceInteger("X", PrefWinX)
    WritePreferenceInteger("Y", PrefWinY)
    WritePreferenceInteger("W", PrefWinW)
    WritePreferenceInteger("H", PrefWinH)

    ClosePreferences()
  EndIf
EndProcedure

Procedure InitPrefsAndApply()
  ; Resolve levels directory. When running from the IDE, ProgramFilename() can point
  ; to a build/temp folder that doesn't contain "levels".
  LevelsDir = GetPathPart(ProgramFilename()) + "levels" + #PS$
  If FileSize(LevelsDir) <> -2
    LevelsDir = MainSourceDir + "levels" + #PS$
  EndIf
  If FileSize(LevelsDir) = -2
    SetCurrentDirectory(GetPathPart(LevelsDir))
  Else
    LevelsDir = ""
  EndIf

  ; Load app-level preferences (sound/debug/last world).
  LoadPrefs()

  ; Ensure the INI exists even if user changes nothing.
  SavePrefs()
  If FileSize(PrefGetPath()) <= 0
    MessageRequester(#APP_NAME, "Could not create INI file at:" + #LF$ + PrefGetPath())
  EndIf

  ; If the INI specifies a valid levels directory, prefer it.
  If PrefLevelsDir <> "" And FileSize(PrefLevelsDir) = -2
    ; Ensure trailing path separator to match existing usage.
    If Right(PrefLevelsDir, 1) <> #PS$
      PrefLevelsDir + #PS$
    EndIf
    LevelsDir = PrefLevelsDir
    SetCurrentDirectory(GetPathPart(LevelsDir))
  Else
    PrefLevelsDir = LevelsDir
  EndIf
EndProcedure
