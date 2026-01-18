; ====================================================================
; Sound Effects Generator for Games
; PureBasic v6.30 Beta 6
; Creates WAV files with various game sound effects
; ====================================================================

EnableExplicit

#SAMPLE_RATE = 44100
#BITS_PER_SAMPLE = 16
#CHANNELS = 1
#APP_NAME = "Game_Sndfx_Gen"

Global version.s = "v1.0.0.0"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Structure WaveHeader
  chunkID.l
  chunkSize.l
  format.l
  subchunk1ID.l
  subchunk1Size.l
  audioFormat.w
  numChannels.w
  sampleRate.l
  byteRate.l
  blockAlign.w
  bitsPerSample.w
  subchunk2ID.l
  subchunk2Size.l
EndStructure

Structure SoundEffect
  List samples.f()
  duration.f
  name.s
EndStructure

Structure SoundParams
  duration.f
  frequency.f
  pitch.f
  speed.f
  attack.f
  decay.f
  sustain.f
  release.f
EndStructure

Declare StopPlayback()
Declare.i CreateWaveFile(filename.s, *effect.SoundEffect)
Declare GenerateExplosion(*effect.SoundEffect, *params.SoundParams)
Declare GenerateLaser(*effect.SoundEffect, *params.SoundParams)
Declare GenerateJump(*effect.SoundEffect, *params.SoundParams)
Declare GeneratePickup(*effect.SoundEffect, *params.SoundParams)
Declare GeneratePowerUp(*effect.SoundEffect, *params.SoundParams)
Declare GenerateHit(*effect.SoundEffect, *params.SoundParams)
Declare GenerateShoot(*effect.SoundEffect, *params.SoundParams)
Declare GenerateBeep(*effect.SoundEffect, *params.SoundParams)
Declare GenerateAlarm(*effect.SoundEffect, *params.SoundParams)
Declare GenerateCoin(*effect.SoundEffect, *params.SoundParams)
Declare GenerateFootstep(*effect.SoundEffect, *params.SoundParams)
Declare GenerateClick(*effect.SoundEffect, *params.SoundParams)
Declare GenerateWhoosh(*effect.SoundEffect, *params.SoundParams)
Declare GenerateBounce(*effect.SoundEffect, *params.SoundParams)
Declare GenerateGameOver(*effect.SoundEffect, *params.SoundParams)

; Exit procedure
Procedure ConfirmExit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If hMutex
      CloseHandle_(hMutex)
      hMutex = 0
    EndIf
    End
  EndIf
EndProcedure

Procedure.f Clamp(value.f, minVal.f, maxVal.f)
  If value < minVal
    ProcedureReturn minVal
  ElseIf value > maxVal
    ProcedureReturn maxVal
  Else
    ProcedureReturn value
  EndIf
EndProcedure

Procedure.f RandomFloat(min.f, max.f)
  ProcedureReturn min + (Random(10000) / 10000.0) * (max - min)
EndProcedure

Procedure.f Envelope(t.f, attack.f, decay.f, sustain.f, release.f, duration.f)
  Protected totalADR.f = attack + decay + release

  If duration <= 0.0
    ProcedureReturn 0.0
  EndIf

  ; Avoid division-by-zero when any segment is zero-length.
  If attack < 0.0 : attack = 0.0 : EndIf
  If decay < 0.0  : decay = 0.0  : EndIf
  If release < 0.0: release = 0.0: EndIf

  If totalADR > duration
    If totalADR > 0.0
      attack = attack / totalADR * duration * 0.9
      decay = decay / totalADR * duration * 0.9
      release = release / totalADR * duration * 0.9
    Else
      attack = 0.0
      decay = 0.0
      release = 0.0
    EndIf
  EndIf

  sustain = Clamp(sustain, 0.0, 1.0)

  If t < 0.0
    ProcedureReturn 0.0
  ElseIf t < attack
    If attack = 0.0
      ProcedureReturn 1.0
    EndIf
    ProcedureReturn t / attack
  ElseIf t < attack + decay
    If decay = 0.0
      ProcedureReturn sustain
    EndIf
    ProcedureReturn 1.0 - (1.0 - sustain) * ((t - attack) / decay)
  ElseIf t < duration - release
    ProcedureReturn sustain
  Else
    If release = 0.0
      ProcedureReturn 0.0
    EndIf
    ProcedureReturn sustain * (1.0 - (t - (duration - release)) / release)
  EndIf
EndProcedure

Procedure GenerateExplosion(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, noise, envelope
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Explosion"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    envelope = Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    
    noise = RandomFloat(-1.0, 1.0)
    frequency = 50.0 * *params\pitch * Exp(-t * 3.0)
    
    amplitude = noise * envelope * Exp(-t * 2.0)
    amplitude = Clamp(amplitude, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateLaser(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, currentFreq, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Laser"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    currentFreq = *params\frequency * *params\pitch * (1.0 - t / *params\duration * 0.8)
    phase = 2.0 * #PI * currentFreq * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.7, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateJump(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Jump"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (200.0 + (t / *params\duration) * 400.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.6, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GeneratePickup(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Pickup"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (400.0 + Sin(t * 40.0) * 200.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.5, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GeneratePowerUp(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase, envelope
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "PowerUp"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (200.0 + (t / *params\duration) * 800.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    envelope = Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    
    amplitude = (Sin(phase) + Sin(phase * 1.5) * 0.5) * envelope
    amplitude = Clamp(amplitude * 0.5, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateHit(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, noise
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Hit"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    noise = RandomFloat(-1.0, 1.0)
    
    amplitude = noise * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.8, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateShoot(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase, noise
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Shoot"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = 150.0 * *params\pitch * Exp(-t * 8.0)
    phase = 2.0 * #PI * frequency * t
    noise = RandomFloat(-0.3, 0.3)
    
    amplitude = (Sin(phase) + noise) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.7, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateBeep(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, phase, envelope
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Beep"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    phase = 2.0 * #PI * *params\frequency * *params\pitch * t
    envelope = Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    
    amplitude = Sin(phase) * envelope
    amplitude = Clamp(amplitude * 0.5, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateAlarm(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Alarm"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (600.0 + Sin(t * 8.0) * 200.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration) * 0.6
    amplitude = Clamp(amplitude, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateCoin(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Coin"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (900.0 + Sin(t * 50.0) * 100.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.5, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateFootstep(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, noise, lowFreq, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Footstep"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    noise = RandomFloat(-0.5, 0.5)
    lowFreq = 80.0 * *params\pitch
    phase = 2.0 * #PI * lowFreq * t
    
    amplitude = (Sin(phase) * 0.5 + noise * 0.5) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.6, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateClick(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, noise
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Click"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    noise = RandomFloat(-1.0, 1.0)
    
    amplitude = noise * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.4, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateWhoosh(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, noise, envelope
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Whoosh"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    noise = RandomFloat(-1.0, 1.0)
    envelope = Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    
    amplitude = noise * envelope * 0.5
    amplitude = Clamp(amplitude, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateBounce(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "Bounce"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = 300.0 * *params\pitch * Exp(-t * 5.0)
    phase = 2.0 * #PI * frequency * t
    
    amplitude = Sin(phase) * Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    amplitude = Clamp(amplitude * 0.6, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure GenerateGameOver(*effect.SoundEffect, *params.SoundParams)
  Protected samples.i = Round(#SAMPLE_RATE * *params\duration / *params\speed, #PB_Round_Down)
  Protected.f t, amplitude, frequency, phase, envelope
  Protected i.i
  
  *effect\duration = *params\duration
  *effect\name = "GameOver"
  ClearList(*effect\samples())
  
  For i = 0 To samples - 1
    t = (i / #SAMPLE_RATE) * *params\speed
    frequency = (300.0 - (t / *params\duration) * 200.0) * *params\pitch
    phase = 2.0 * #PI * frequency * t
    envelope = Envelope(t, *params\attack, *params\decay, *params\sustain, *params\release, *params\duration)
    
    amplitude = Sin(phase) * envelope
    amplitude = Clamp(amplitude * 0.6, -1.0, 1.0)
    
    AddElement(*effect\samples())
    *effect\samples() = amplitude
  Next
EndProcedure

Procedure.i CreateWaveFile(filename.s, *effect.SoundEffect)
  Protected file
  Protected.WaveHeader header
  Protected.w sample16
  Protected numSamples = ListSize(*effect\samples())
  Protected dataSize = numSamples * (#BITS_PER_SAMPLE / 8)
  Protected.f scaled

  If numSamples <= 0
    ProcedureReturn #False
  EndIf

  header\chunkID = $46464952 ; "RIFF"
  header\chunkSize = 36 + dataSize
  header\format = $45564157 ; "WAVE"
  header\subchunk1ID = $20746D66 ; "fmt "
  header\subchunk1Size = 16
  header\audioFormat = 1
  header\numChannels = #CHANNELS
  header\sampleRate = #SAMPLE_RATE
  header\byteRate = #SAMPLE_RATE * #CHANNELS * #BITS_PER_SAMPLE / 8
  header\blockAlign = #CHANNELS * #BITS_PER_SAMPLE / 8
  header\bitsPerSample = #BITS_PER_SAMPLE
  header\subchunk2ID = $61746164 ; "data"
  header\subchunk2Size = dataSize

  file = CreateFile(#PB_Any, filename)
  If file
    WriteData(file, @header, SizeOf(WaveHeader))

    ForEach *effect\samples()
      scaled = Clamp(*effect\samples(), -1.0, 1.0) * 32767.0
      sample16 = Round(scaled, #PB_Round_Nearest)
      WriteWord(file, sample16)
    Next

    CloseFile(file)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

; ====================================================================
; GUI Section
; ====================================================================

Enumeration
  #Window
  #ListEffect
  #ButtonGenerate
  #ButtonSave
  #ButtonPlay
  #ButtonStop
  #TextDuration
  #SpinDuration
  #TextFrequency
  #SpinFrequency
  #TextFreqLabel
  #TextPitch
  #SpinPitch
  #TextSpeed
  #SpinSpeed
  #TextAttack
  #SpinAttack
  #TextDecay
  #SpinDecay
  #TextSustain
  #SpinSustain
  #TextRelease
  #SpinRelease
  #TextStatus
EndEnumeration

Global.SoundEffect currentEffect
Global.SoundParams params
Global sound = -1
Global tempSoundFile.s

Procedure UpdateControls()
  Protected selectedItem = GetGadgetState(#ListEffect)
  Protected showFrequency = #False
  Protected hideFrequency
  
  If selectedItem >= 0
    DisableGadget(#ButtonGenerate, #False)
    
    Select selectedItem
      Case 1, 7 ; Laser, Beep
        showFrequency = #True
    EndSelect
    
    If showFrequency
      hideFrequency = #False
    Else
      hideFrequency = #True
    EndIf
    
    HideGadget(#TextFrequency, hideFrequency)
    HideGadget(#SpinFrequency, hideFrequency)
    HideGadget(#TextFreqLabel, hideFrequency)
  Else
    DisableGadget(#ButtonGenerate, #True)
  EndIf
  
  If ListSize(currentEffect\samples()) > 0
    DisableGadget(#ButtonSave, #False)
    DisableGadget(#ButtonPlay, #False)
    DisableGadget(#ButtonStop, #False)
  Else
    DisableGadget(#ButtonSave, #True)
    DisableGadget(#ButtonPlay, #True)
    DisableGadget(#ButtonStop, #True)
  EndIf
EndProcedure

Procedure GenerateCurrentEffect()
  Protected selectedItem = GetGadgetState(#ListEffect)

  params\duration = GetGadgetState(#SpinDuration) / 100.0
  params\frequency = GetGadgetState(#SpinFrequency)
  params\pitch = GetGadgetState(#SpinPitch) / 100.0
  params\speed = GetGadgetState(#SpinSpeed) / 100.0
  params\attack = GetGadgetState(#SpinAttack) / 1000.0
  params\decay = GetGadgetState(#SpinDecay) / 1000.0
  params\sustain = GetGadgetState(#SpinSustain) / 100.0
  params\release = GetGadgetState(#SpinRelease) / 1000.0

  ; Defensive validation (don’t rely only on gadget min/max).
  params\duration = Clamp(params\duration, 0.01, 60.0)
  params\pitch = Clamp(params\pitch, 0.01, 10.0)
  params\speed = Clamp(params\speed, 0.01, 10.0)
  params\sustain = Clamp(params\sustain, 0.0, 1.0)

  params\attack = Clamp(params\attack, 0.0, params\duration)
  params\decay = Clamp(params\decay, 0.0, params\duration)
  params\release = Clamp(params\release, 0.0, params\duration)
  
  StopPlayback()
  
  SetGadgetText(#TextStatus, "Generating sound effect...")
  
  Select selectedItem
    Case 0
      GenerateExplosion(@currentEffect, @params)
    Case 1
      GenerateLaser(@currentEffect, @params)
    Case 2
      GenerateJump(@currentEffect, @params)
    Case 3
      GeneratePickup(@currentEffect, @params)
    Case 4
      GeneratePowerUp(@currentEffect, @params)
    Case 5
      GenerateHit(@currentEffect, @params)
    Case 6
      GenerateShoot(@currentEffect, @params)
    Case 7
      GenerateBeep(@currentEffect, @params)
    Case 8
      GenerateAlarm(@currentEffect, @params)
    Case 9
      GenerateCoin(@currentEffect, @params)
    Case 10
      GenerateFootstep(@currentEffect, @params)
    Case 11
      GenerateClick(@currentEffect, @params)
    Case 12
      GenerateWhoosh(@currentEffect, @params)
    Case 13
      GenerateBounce(@currentEffect, @params)
    Case 14
      GenerateGameOver(@currentEffect, @params)
  EndSelect
  
  SetGadgetText(#TextStatus, "Generated: " + currentEffect\name + " (" + StrF(currentEffect\duration, 2) + "s, " + Str(ListSize(currentEffect\samples())) + " samples)")
  UpdateControls()
EndProcedure

Procedure SaveCurrentEffect()
  Protected filename.s = SaveFileRequester("Save Sound Effect", "sound_effect.wav", "Wave Files (*.wav)|*.wav", 0)
  
  If filename
    If CreateWaveFile(filename, @currentEffect)
      SetGadgetText(#TextStatus, "Saved: " + filename)
      MessageRequester("Success", "Sound effect saved successfully!", #PB_MessageRequester_Ok)
    Else
      SetGadgetText(#TextStatus, "Error: Failed to save file")
      MessageRequester("Error", "Failed to save sound effect!", #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure StopPlayback()
  If sound >= 0
    StopSound(sound)
    FreeSound(sound)
    sound = -1
  EndIf

  If tempSoundFile
    DeleteFile(tempSoundFile)
    tempSoundFile = ""
  EndIf

  SetGadgetText(#TextStatus, "Stopped")
  UpdateControls()
EndProcedure

Procedure PlayCurrentEffect()
  Protected tempFile.s

  tempFile = GetTemporaryDirectory() + #APP_NAME + "_" + Str(Date()) + "_" + Str(Random(1000000)) + ".wav"

  ; Free prior sound + remove the previous temp file.
  StopPlayback()

  If CreateWaveFile(tempFile, @currentEffect)
    sound = LoadSound(#PB_Any, tempFile)
    If sound >= 0
      tempSoundFile = tempFile
      PlaySound(sound)
      SetGadgetText(#TextStatus, "Playing: " + currentEffect\name)
    Else
      DeleteFile(tempFile)
      SetGadgetText(#TextStatus, "Error: Failed to load sound")
    EndIf
  EndIf
EndProcedure

; ====================================================================
; Main Program
; ====================================================================

If InitSound()
  
  OpenWindow(#Window, 0, 0, 800, 600, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
  
  TextGadget(#PB_Any, 10, 10, 200, 20, "Select Sound Effect:")
  ListIconGadget(#ListEffect, 10, 30, 280, 480, "Effect", 250, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
  
  AddGadgetItem(#ListEffect, -1, "Explosion")
  AddGadgetItem(#ListEffect, -1, "Laser")
  AddGadgetItem(#ListEffect, -1, "Jump")
  AddGadgetItem(#ListEffect, -1, "Pickup")
  AddGadgetItem(#ListEffect, -1, "Power Up")
  AddGadgetItem(#ListEffect, -1, "Hit")
  AddGadgetItem(#ListEffect, -1, "Shoot")
  AddGadgetItem(#ListEffect, -1, "Beep")
  AddGadgetItem(#ListEffect, -1, "Alarm")
  AddGadgetItem(#ListEffect, -1, "Coin")
  AddGadgetItem(#ListEffect, -1, "Footstep")
  AddGadgetItem(#ListEffect, -1, "Click")
  AddGadgetItem(#ListEffect, -1, "Whoosh")
  AddGadgetItem(#ListEffect, -1, "Bounce")
  AddGadgetItem(#ListEffect, -1, "Game Over")
  
  TextGadget(#TextDuration, 310, 30, 230, 20, "Duration (0.05-5.0s):")
  SpinGadget(#SpinDuration, 310, 50, 230, 25, 5, 500, #PB_Spin_Numeric)
  SetGadgetState(#SpinDuration, 50)
  TextGadget(#PB_Any, 550, 50, 50, 25, "x0.01s")
  
  TextGadget(#TextFrequency, 310, 85, 230, 20, "Frequency (100-2000 Hz):")
  SpinGadget(#SpinFrequency, 310, 105, 230, 25, 100, 2000, #PB_Spin_Numeric)
  SetGadgetState(#SpinFrequency, 440)
  TextGadget(#TextFreqLabel, 550, 105, 50, 25, "Hz")
  HideGadget(#TextFrequency, #True)
  HideGadget(#SpinFrequency, #True)
  HideGadget(#TextFreqLabel, #True)
  
  TextGadget(#TextPitch, 310, 140, 230, 20, "Pitch (0.5-2.0x):")
  SpinGadget(#SpinPitch, 310, 160, 230, 25, 50, 200, #PB_Spin_Numeric)
  SetGadgetState(#SpinPitch, 100)
  TextGadget(#PB_Any, 550, 160, 50, 25, "x0.01")
  
  TextGadget(#TextSpeed, 310, 195, 230, 20, "Speed (0.5-2.0x):")
  SpinGadget(#SpinSpeed, 310, 215, 230, 25, 50, 200, #PB_Spin_Numeric)
  SetGadgetState(#SpinSpeed, 100)
  TextGadget(#PB_Any, 550, 215, 50, 25, "x0.01")
  
  FrameGadget(#PB_Any, 300, 250, 490, 160, "ADSR Envelope")
  
  TextGadget(#TextAttack, 310, 275, 220, 20, "Attack (0-500ms):")
  SpinGadget(#SpinAttack, 310, 295, 220, 25, 0, 500, #PB_Spin_Numeric)
  SetGadgetState(#SpinAttack, 10)
  TextGadget(#PB_Any, 540, 295, 50, 25, "ms")
  
  TextGadget(#TextDecay, 310, 330, 220, 20, "Decay (0-500ms):")
  SpinGadget(#SpinDecay, 310, 350, 220, 25, 0, 500, #PB_Spin_Numeric)
  SetGadgetState(#SpinDecay, 50)
  TextGadget(#PB_Any, 540, 350, 50, 25, "ms")
  
  TextGadget(#TextSustain, 560, 275, 200, 20, "Sustain (0-100%):")
  SpinGadget(#SpinSustain, 560, 295, 200, 25, 0, 100, #PB_Spin_Numeric)
  SetGadgetState(#SpinSustain, 70)
  TextGadget(#PB_Any, 770, 295, 20, 25, "%")
  
  TextGadget(#TextRelease, 560, 330, 200, 20, "Release (0-1000ms):")
  SpinGadget(#SpinRelease, 560, 350, 200, 25, 0, 1000, #PB_Spin_Numeric)
  SetGadgetState(#SpinRelease, 100)
  TextGadget(#PB_Any, 770, 350, 20, 25, "ms")
  
  ButtonGadget(#ButtonGenerate, 310, 425, 470, 35, "Generate Sound Effect")
  ButtonGadget(#ButtonPlay, 310, 470, 150, 35, "Play")
  ButtonGadget(#ButtonStop, 470, 470, 70, 35, "Stop")
  ButtonGadget(#ButtonSave, 550, 470, 230, 35, "Save WAV File")
  
  FrameGadget(#PB_Any, 10, 520, 770, 70, "Status")
  TextGadget(#TextStatus, 20, 545, 750, 40, "Ready. Select a sound effect and adjust parameters, then click Generate.")
  
  DisableGadget(#ButtonGenerate, #True)
  DisableGadget(#ButtonSave, #True)
  DisableGadget(#ButtonPlay, #True)
  DisableGadget(#ButtonStop, #True)
  
  Define event
  
  Repeat
    event = WaitWindowEvent()
    
    Select event
      Case #PB_Event_CloseWindow
        ConfirmExit()
        
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ListEffect
            UpdateControls()
            
          Case #ButtonGenerate
            GenerateCurrentEffect()
            
          Case #ButtonSave
            SaveCurrentEffect()
            
          Case #ButtonPlay
            PlayCurrentEffect()

          Case #ButtonStop
            StopPlayback()
        EndSelect
    EndSelect
  ForEver
  
  StopPlayback()
  
Else
  MessageRequester("Error", "Failed to initialize sound system!", #PB_MessageRequester_Error)
EndIf

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 11
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = game_sndfx_gen.ico
; Executable = ..\Game_Sndfx_Gen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = Game_Sndfx_Gen
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = A configurable Sound Effects generator
; VersionField7 = Game_Sndfx_Gen
; VersionField8 = Game_Sndfx_Gen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60