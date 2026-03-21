; ====================================================================
; UI and Event Loop for Game_Music_Gen
; ====================================================================

Procedure OpenAppWindow()
  If OpenWindow(#Window, 0, 0, 820, 660, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)

    TextGadget(#PB_Any, 10, 10, 340, 20, "Chiptune-style loop generator (WAV + MIDI)")

    TextGadget(#TextTempo, 10, 45, 220, 20, "Tempo (60-200 BPM):")
    SpinGadget(#SpinTempo, 10, 65, 220, 25, 60, 200, #PB_Spin_Numeric)
    SetGadgetState(#SpinTempo, 120)

    TextGadget(#TextBars, 250, 45, 220, 20, "Bars (1-16):")
    SpinGadget(#SpinBars, 250, 65, 220, 25, 1, 16, #PB_Spin_Numeric)
    SetGadgetState(#SpinBars, 4)

    TextGadget(#TextSteps, 490, 45, 220, 20, "Steps per bar:")
    ComboBoxGadget(#ComboSteps, 490, 65, 120, 25)
    AddGadgetItem(#ComboSteps, -1, "8")
    AddGadgetItem(#ComboSteps, -1, "16")
    SetGadgetState(#ComboSteps, 1)

    TextGadget(#TextKey, 10, 105, 220, 20, "Key:")
    ComboBoxGadget(#ComboKey, 10, 125, 220, 25)
    AddGadgetItem(#ComboKey, -1, "C")
    AddGadgetItem(#ComboKey, -1, "C#")
    AddGadgetItem(#ComboKey, -1, "D")
    AddGadgetItem(#ComboKey, -1, "D#")
    AddGadgetItem(#ComboKey, -1, "E")
    AddGadgetItem(#ComboKey, -1, "F")
    AddGadgetItem(#ComboKey, -1, "F#")
    AddGadgetItem(#ComboKey, -1, "G")
    AddGadgetItem(#ComboKey, -1, "G#")
    AddGadgetItem(#ComboKey, -1, "A")
    AddGadgetItem(#ComboKey, -1, "A#")
    AddGadgetItem(#ComboKey, -1, "B")
    SetGadgetState(#ComboKey, 0)

    TextGadget(#TextScale, 250, 105, 220, 20, "Scale:")
    ComboBoxGadget(#ComboScale, 250, 125, 220, 25)
    AddGadgetItem(#ComboScale, -1, "Major")
    AddGadgetItem(#ComboScale, -1, "Minor")
    SetGadgetState(#ComboScale, 0)

    TextGadget(#TextSeed, 490, 105, 120, 20, "Seed (0=random):")
    SpinGadget(#SpinSeed, 490, 125, 120, 25, 0, 999999, #PB_Spin_Numeric)
    SetGadgetState(#SpinSeed, 0)

    TextGadget(#TextSectionBars, 630, 105, 180, 20, "Section bars (A/B):")
    SpinGadget(#SpinSectionBars, 630, 125, 80, 25, 1, 16, #PB_Spin_Numeric)
    SetGadgetState(#SpinSectionBars, 4)

    TextGadget(#TextProgression, 720, 105, 90, 20, "Prog:")
    ComboBoxGadget(#ComboProgression, 720, 125, 90, 25)
    AddGadgetItem(#ComboProgression, -1, "I-V-vi-IV")
    AddGadgetItem(#ComboProgression, -1, "I-IV-V-I")
    AddGadgetItem(#ComboProgression, -1, "ii-V-I-V")
    SetGadgetState(#ComboProgression, 0)

    TextGadget(#TextDrumPattern, 10, 150, 160, 20, "Drum pattern:")
    ComboBoxGadget(#ComboDrumPattern, 10, 170, 150, 25)
    AddGadgetItem(#ComboDrumPattern, -1, "Simple")
    AddGadgetItem(#ComboDrumPattern, -1, "Rock")
    AddGadgetItem(#ComboDrumPattern, -1, "DnB")
    SetGadgetState(#ComboDrumPattern, 1)

    TextGadget(#TextDrumTone, 170, 150, 110, 20, "Noise tone (Hz):")
    SpinGadget(#SpinDrumTone, 170, 170, 120, 25, 500, 12000, #PB_Spin_Numeric)
    SetGadgetState(#SpinDrumTone, 9000)

    TextGadget(#TextDrumDecay, 300, 150, 120, 20, "Drum decay (10-120):")
    SpinGadget(#SpinDrumDecay, 300, 170, 120, 25, 10, 120, #PB_Spin_Numeric)
    SetGadgetState(#SpinDrumDecay, 45)

    TextGadget(#TextNoiseMode, 430, 150, 120, 20, "Noise mode:")
    ComboBoxGadget(#ComboNoiseMode, 430, 170, 120, 25)
    AddGadgetItem(#ComboNoiseMode, -1, "Filtered")
    AddGadgetItem(#ComboNoiseMode, -1, "NES short")
    AddGadgetItem(#ComboNoiseMode, -1, "NES long")
    SetGadgetState(#ComboNoiseMode, 1)

    TextGadget(#TextNoiseRate, 560, 150, 170, 20, "NES rate (0-15):")
    SpinGadget(#SpinNoiseRate, 560, 170, 90, 25, 0, 15, #PB_Spin_Numeric)
    SetGadgetState(#SpinNoiseRate, 4)

    FrameGadget(#FrameSound, 10, 200, 800, 120, "Sound")

    TextGadget(#TextLeadWave, 20, 225, 120, 20, "Lead wave:")
    ComboBoxGadget(#ComboLeadWave, 20, 245, 140, 25)
    AddGadgetItem(#ComboLeadWave, -1, "Square")
    AddGadgetItem(#ComboLeadWave, -1, "Triangle")
    AddGadgetItem(#ComboLeadWave, -1, "Saw")
    SetGadgetState(#ComboLeadWave, 0)

    TextGadget(#TextBassWave, 180, 225, 120, 20, "Bass wave:")
    ComboBoxGadget(#ComboBassWave, 180, 245, 140, 25)
    AddGadgetItem(#ComboBassWave, -1, "Square")
    AddGadgetItem(#ComboBassWave, -1, "Triangle")
    AddGadgetItem(#ComboBassWave, -1, "Saw")
    SetGadgetState(#ComboBassWave, 1)

    TextGadget(#TextSwing, 340, 225, 140, 20, "Swing (0-60%):")
    SpinGadget(#SpinSwing, 340, 245, 120, 25, 0, 60, #PB_Spin_Numeric)
    SetGadgetState(#SpinSwing, 0)

    TextGadget(#TextEchoMs, 490, 225, 120, 20, "Echo delay (ms):")
    SpinGadget(#SpinEchoMs, 490, 245, 120, 25, 0, 1000, #PB_Spin_Numeric)
    SetGadgetState(#SpinEchoMs, 0)

    TextGadget(#TextEchoMix, 630, 225, 160, 20, "Echo mix (0-100):")
    SpinGadget(#SpinEchoMix, 630, 245, 120, 25, 0, 100, #PB_Spin_Numeric)
    SetGadgetState(#SpinEchoMix, 0)

    FrameGadget(#FrameMix, 10, 335, 800, 120, "Mix")

    TextGadget(#TextLeadVol, 20, 360, 160, 20, "Lead volume (0-100):")
    SpinGadget(#SpinLeadVol, 20, 380, 120, 25, 0, 100, #PB_Spin_Numeric)
    SetGadgetState(#SpinLeadVol, 70)

    TextGadget(#TextBassVol, 180, 360, 160, 20, "Bass volume (0-100):")
    SpinGadget(#SpinBassVol, 180, 380, 120, 25, 0, 100, #PB_Spin_Numeric)
    SetGadgetState(#SpinBassVol, 60)

    TextGadget(#TextDrumVol, 340, 360, 160, 20, "Drum volume (0-100):")
    SpinGadget(#SpinDrumVol, 340, 380, 120, 25, 0, 100, #PB_Spin_Numeric)
    SetGadgetState(#SpinDrumVol, 40)

    ButtonGadget(#ButtonGenerate, 10, 475, 800, 40, "Generate Music Loop")

    ButtonGadget(#ButtonPlay, 10, 530, 180, 35, "Play")
    ButtonGadget(#ButtonStop, 200, 530, 180, 35, "Stop")
    ButtonGadget(#ButtonSaveWav, 390, 530, 200, 35, "Save WAV")
    ButtonGadget(#ButtonSaveMidi, 600, 530, 210, 35, "Save MIDI")

    FrameGadget(#PB_Any, 10, 575, 800, 65, "Status")
    TextGadget(#TextStatus, 20, 595, 780, 40, "Ready. Click Generate to create a loop.")

    UpdateActionButtons(#False, #False)
    
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure RunEventLoop()
  Define event.i
  Repeat
    event = WaitWindowEvent()

    Select event
      Case #PB_Event_CloseWindow
        ConfirmExit()

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ButtonGenerate
            GenerateCurrentMusic()

          Case #ButtonPlay
            PlayCurrentMusic()

          Case #ButtonStop
            StopPlayback()

          Case #ButtonSaveWav
            SaveCurrentWav()

          Case #ButtonSaveMidi
            SaveCurrentMidi()
        EndSelect
    EndSelect
  ForEver
EndProcedure
