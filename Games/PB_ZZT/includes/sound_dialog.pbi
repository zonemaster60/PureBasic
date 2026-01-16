;------------------------------------------------------------------------------
; Sound settings dialog (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; UpdateSoundValueLabels
; Purpose: Procedure: Update Sound Value Labels.
;------------------------------------------------------------------------------

#SFX_REBUILD_MIN_INTERVAL_MS = 60
#SFX_REBUILD_DEBOUNCE_MS = 140
#PREFS_AUTOSAVE_DEBOUNCE_MS = 450

Procedure UpdateSoundValueLabels()
  If IsGadget(#Gad_SoundMasterVolVal)
    SetGadgetText(#Gad_SoundMasterVolVal, StrF(SfxMasterVol, 2))
  EndIf
  If IsGadget(#Gad_SoundMusicVolVal)
    SetGadgetText(#Gad_SoundMusicVolVal, StrF(MusicMasterVol, 2))
  EndIf
  If IsGadget(#Gad_SoundPitchVal)
    SetGadgetText(#Gad_SoundPitchVal, StrF(SfxPitchMul, 2))
  EndIf
  If IsGadget(#Gad_SoundNoiseVal)
    SetGadgetText(#Gad_SoundNoiseVal, StrF(SfxNoiseMul, 2))
  EndIf
  If IsGadget(#Gad_SoundVibVal)
    SetGadgetText(#Gad_SoundVibVal, StrF(SfxVibMul, 2))
  EndIf
EndProcedure

;------------------------------------------------------------------------------
; OpenSoundDialog
; Purpose: Procedure: Open Sound Dialog.
;------------------------------------------------------------------------------

Procedure OpenSoundDialog()
  Protected ev.i, gid.i, evType.i
  Protected updating.b
  Protected win.i

  ; INI persistence (write a bit after user stops moving sliders)
  Protected prefsDirty.b
  Protected lastPrefsChangeMS.i

  ; Dragging sliders can generate a lot of change events; rebuilding the
  ; entire SFX cache on every tick causes audible stutter. Debounce/restrict
  ; rebuild work while still keeping values responsive.
  Protected lastSfxRebuildMS.i
  Protected lastSfxChangeMS.i
  Protected pendingSfxRebuild.b
  Protected pendingSfxRebuildNeedsSfx.b

  DisableWindow(0, 1)
  ResetKeyLatches()

  win = OpenWindow(#PB_Any, 0, 0, 520, 300, "Sound Settings (INI: " + GetFilePart(PrefGetPath()) + ")", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
  If win = 0
    DisableWindow(0, 0)
    MessageRequester(#APP_NAME, "Failed To open Sound Settings window.")
    ProcedureReturn
  EndIf
  SetActiveWindow(win)

  ; Create fixed-ID gadgets first to avoid #PB_Any ID collisions.
  TrackBarGadget(#Gad_SoundMasterVol, 220, 8, 240, 24, 0, 400)
  TextGadget(#Gad_SoundMasterVolVal, 470, 10, 40, 20, "")

  TrackBarGadget(#Gad_SoundMusicVol, 220, 44, 240, 24, 0, 100)
  TextGadget(#Gad_SoundMusicVolVal, 470, 46, 40, 20, "")

  TrackBarGadget(#Gad_SoundPitch, 220, 80, 240, 24, 50, 200)
  TextGadget(#Gad_SoundPitchVal, 470, 82, 40, 20, "")

  TrackBarGadget(#Gad_SoundNoise, 220, 116, 240, 24, 0, 200)
  TextGadget(#Gad_SoundNoiseVal, 470, 118, 40, 20, "")

  TrackBarGadget(#Gad_SoundVib, 220, 152, 240, 24, 0, 200)
  TextGadget(#Gad_SoundVibVal, 470, 154, 40, 20, "")

  ButtonGadget(#Gad_SoundPreview, 220, 260, 70, 30, "Beep")
  ButtonGadget(#Gad_SoundPreviewStep, 295, 260, 70, 30, "Step")
  ButtonGadget(#Gad_SoundPreviewCoin, 370, 260, 70, 30, "Coin")
  ButtonGadget(#Gad_SoundPreviewDoor, 445, 260, 70, 30, "Door")
  ButtonGadget(#Gad_SoundPreviewHurt, 220, 228, 70, 30, "Hurt")

  ButtonGadget(#Gad_SoundReset, 370, 228, 70, 30, "Reset")
  ButtonGadget(#Gad_SoundClose, 445, 228, 70, 30, "Close")

  ; Labels and tips can use #PB_Any safely now.
  TextGadget(#PB_Any, 10, 10, 200, 20, "SFX Master Volume")
  TextGadget(#PB_Any, 10, 46, 200, 20, "Music Volume")
  TextGadget(#PB_Any, 10, 82, 200, 20, "SFX Pitch")
  TextGadget(#PB_Any, 10, 118, 200, 20, "SFX Noise")
  TextGadget(#PB_Any, 10, 154, 200, 20, "SFX Vibrato")
  TextGadget(#PB_Any, 10, 188, 490, 60, "Tip: Volume sliders are instant.\nPitch/Noise/Vibrato rebuild the SFX cache.\nPreview plays: beep / step / coin / door / hurt")

  ; initialize slider positions from globals
  updating = #True
  SetGadgetState(#Gad_SoundMasterVol, Int(ClampF(SfxMasterVol, 0.0, 4.0) * 100.0))
  SetGadgetState(#Gad_SoundMusicVol, Int(ClampF(MusicMasterVol, 0.0, 1.0) * 100.0))
  SetGadgetState(#Gad_SoundPitch, Int(ClampF(SfxPitchMul, 0.5, 2.0) * 100.0))
  SetGadgetState(#Gad_SoundNoise, Int(ClampF(SfxNoiseMul, 0.0, 2.0) * 100.0))
  SetGadgetState(#Gad_SoundVib, Int(ClampF(SfxVibMul, 0.0, 2.0) * 100.0))
  updating = #False
  UpdateSoundValueLabels()

  Repeat
    ev = WaitWindowEvent(16)

     ; Handle any pending, debounced rebuild in idle time.
     If pendingSfxRebuild
       If ElapsedMilliseconds() - lastSfxChangeMS >= #SFX_REBUILD_DEBOUNCE_MS
         If pendingSfxRebuildNeedsSfx And SfxReady
           BuildSfxCache()
         EndIf
         lastSfxRebuildMS = ElapsedMilliseconds()
         pendingSfxRebuild = #False
         pendingSfxRebuildNeedsSfx = #False
       EndIf
     EndIf

     ; Auto-save prefs a short time after last change.
     If prefsDirty
       If ElapsedMilliseconds() - lastPrefsChangeMS >= #PREFS_AUTOSAVE_DEBOUNCE_MS
         SavePrefs()
         prefsDirty = #False
       EndIf
     EndIf

     ; Keep master volumes applied (cheap).
     ApplySfxMasterVolume()
     RefreshBoardMusicVolume()

    Select ev
      Case 0
        ; idle tick

      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        evType = EventType()
        Select gid
          Case #Gad_SoundClose
            Break

          Case #Gad_SoundPreview
            PlaySfx(#Sfx_Beep)
          Case #Gad_SoundPreviewStep
            PlaySfx(#Sfx_Step)
          Case #Gad_SoundPreviewCoin
            PlaySfx(#Sfx_Treasure)
          Case #Gad_SoundPreviewDoor
            PlaySfx(#Sfx_Door)
          Case #Gad_SoundPreviewHurt
            PlaySfx(#Sfx_Hurt)

          Case #Gad_SoundReset
            updating = #True
            SfxMasterVol = 1.0
            MusicMasterVol = 0.25
            SfxPitchMul  = 1.0
            SfxNoiseMul  = 1.0
            SfxVibMul    = 1.0
            SetGadgetState(#Gad_SoundMasterVol, 100)
            SetGadgetState(#Gad_SoundMusicVol, 25)
            SetGadgetState(#Gad_SoundPitch, 100)
            SetGadgetState(#Gad_SoundNoise, 100)
            SetGadgetState(#Gad_SoundVib, 100)
            updating = #False
            UpdateSoundValueLabels()

            ; Reset is a one-shot action; rebuild immediately.
            pendingSfxRebuild = #False
            pendingSfxRebuildNeedsSfx = #False
            prefsDirty = #True
            lastPrefsChangeMS = ElapsedMilliseconds()
            If SfxReady
              BuildSfxCache()
            EndIf
            lastSfxRebuildMS = ElapsedMilliseconds()
            ApplySfxMasterVolume()
            RefreshBoardMusicVolume()
            PlaySfx(#Sfx_Beep)

          Case #Gad_SoundMasterVol, #Gad_SoundMusicVol, #Gad_SoundPitch, #Gad_SoundNoise, #Gad_SoundVib
            If updating = 0
              Protected changedGadget.i = gid

              SfxMasterVol = GetGadgetState(#Gad_SoundMasterVol) / 100.0
              MusicMasterVol = GetGadgetState(#Gad_SoundMusicVol) / 100.0
              SfxPitchMul  = GetGadgetState(#Gad_SoundPitch) / 100.0
              SfxNoiseMul  = GetGadgetState(#Gad_SoundNoise) / 100.0
              SfxVibMul    = GetGadgetState(#Gad_SoundVib) / 100.0
              UpdateSoundValueLabels()

              prefsDirty = #True
              lastPrefsChangeMS = ElapsedMilliseconds()

               ; Apply volumes instantly (no rebuild).
               ApplySfxMasterVolume()
               RefreshBoardMusicVolume()

               ; Only rebuild SFX cache when synthesis parameters change.
               If changedGadget = #Gad_SoundPitch Or changedGadget = #Gad_SoundNoise Or changedGadget = #Gad_SoundVib
                 lastSfxChangeMS = ElapsedMilliseconds()
                 pendingSfxRebuildNeedsSfx = #True

                 If SfxReady
                   If evType = #PB_EventType_Change
                     If ElapsedMilliseconds() - lastSfxRebuildMS >= #SFX_REBUILD_MIN_INTERVAL_MS
                       BuildSfxCache()
                       lastSfxRebuildMS = ElapsedMilliseconds()
                       pendingSfxRebuild = #False
                       pendingSfxRebuildNeedsSfx = #False
                     Else
                       pendingSfxRebuild = #True
                     EndIf
                   Else
                     BuildSfxCache()
                     lastSfxRebuildMS = ElapsedMilliseconds()
                     pendingSfxRebuild = #False
                     pendingSfxRebuildNeedsSfx = #False
                   EndIf
                 Else
                   pendingSfxRebuild = #True
                 EndIf
               Else
                 pendingSfxRebuild = #False
                 pendingSfxRebuildNeedsSfx = #False
               EndIf
            EndIf
        EndSelect
    EndSelect
  ForEver

  ; Ensure the last slider position is applied before closing.
  If pendingSfxRebuild
    If pendingSfxRebuildNeedsSfx And SfxReady
      BuildSfxCache()
    EndIf
  EndIf

  ; Ensure prefs are flushed on exit even if user closes quickly.
  If prefsDirty
    SavePrefs()
  EndIf

  CloseWindow(win)
  DisableWindow(0, 0)
  RefocusMainWindow()
EndProcedure
