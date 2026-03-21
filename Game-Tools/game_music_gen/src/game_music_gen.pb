; ====================================================================
; Music Generator for Games (Chiptune / MIDI)
; PureBasic v6.x
; Generates simple chip-style loops and exports WAV and MIDI.
; ====================================================================

EnableExplicit

#SAMPLE_RATE = 44100
#BITS_PER_SAMPLE = 16
#CHANNELS = 1
#APP_NAME = "Game_Music_Gen"

Global version.s = "v1.0.0.2"
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

Structure MusicParams
  tempo.i        ; BPM
  bars.i
  stepsPerBar.i  ; 8, 16
  key.i          ; 0=C, 1=C#, ...
  scaleType.i    ; 0=major,1=minor
  seed.i

  sectionBars.i  ; bars per section (A/B)
  progression.i  ; 0=I-V-vi-IV, 1=I-IV-V-I, 2=ii-V-I-V
  drumPattern.i  ; 0=Simple, 1=Rock, 2=DnB
  drumNoiseTone.i ; 500..12000 Hz (noise filter cutoff)
  drumDecay.i     ; 10..120 (controls hat/snare decay)
  noiseMode.i     ; 0=Filtered, 1=NES short, 2=NES long
  noiseRate.i     ; 0..15 (NES period index)

  leadWave.i     ; 0=square,1=triangle,2=saw
  bassWave.i

  leadVol.f
  bassVol.f
  drumVol.f

  swing.i        ; 0..60 (%)
  echoMs.i       ; delay in ms
  echoMix.i      ; 0..100
EndStructure

Structure NoteEvent
  startStep.i
  lengthSteps.i
  midiNote.i
  velocity.i
  channel.i
EndStructure

Structure MusicClip
  List samples.f()
  duration.f
  name.s
  tempo.i

  List events.NoteEvent()
EndStructure

Enumeration
  #Window
  #ButtonGenerate
  #ButtonPlay
  #ButtonStop
  #ButtonSaveWav
  #ButtonSaveMidi

  #TextTempo
  #SpinTempo
  #TextBars
  #SpinBars
  #TextSteps
  #ComboSteps
  #TextKey
  #ComboKey
  #TextScale
  #ComboScale
  #TextSeed
  #SpinSeed
  #TextSectionBars
  #SpinSectionBars
  #TextProgression
  #ComboProgression
  #TextDrumPattern
  #ComboDrumPattern
  #TextDrumTone
  #SpinDrumTone
  #TextDrumDecay
  #SpinDrumDecay
  #TextNoiseMode
  #ComboNoiseMode
  #TextNoiseRate
  #SpinNoiseRate

  #FrameMix
  #TextLeadVol
  #SpinLeadVol
  #TextBassVol
  #SpinBassVol
  #TextDrumVol
  #SpinDrumVol

  #FrameSound
  #TextLeadWave
  #ComboLeadWave
  #TextBassWave
  #ComboBassWave
  #TextSwing
  #SpinSwing
  #TextEchoMs
  #SpinEchoMs
  #TextEchoMix
  #SpinEchoMix

  #TextStatus
EndEnumeration

Global.MusicParams params
Global.MusicClip currentMusic
Global sound = -1
Global tempSoundFile.s

Declare StopPlayback()
Declare CleanupAndExit()
Declare SetStatus(text.s)
Declare UpdateActionButtons(hasMusic.i, isPlaying.i)
Declare.i CreateWaveFile(filename.s, *clip.MusicClip)
Declare.i CreateMidiFile(filename.s, *clip.MusicClip)
Declare GenerateMusic(*clip.MusicClip, *params.MusicParams)
Declare GenerateCurrentMusic()
Declare PlayCurrentMusic()
Declare SaveCurrentWav()
Declare SaveCurrentMidi()
Declare OpenAppWindow()
Declare RunEventLoop()

Procedure CleanupAndExit()
  StopPlayback()

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf

  End
EndProcedure

Procedure ConfirmExit()
  Protected req.i = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If req = #PB_MessageRequester_Yes
    CleanupAndExit()
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

Procedure.f SoftClip(value.f, drive.f)
  drive = Clamp(drive, 0.0, 1.0)
  ProcedureReturn (value * (1.0 + drive)) / (1.0 + drive * Abs(value))
EndProcedure

Procedure.i ClampI(value.i, minVal.i, maxVal.i)
  If value < minVal
    ProcedureReturn minVal
  ElseIf value > maxVal
    ProcedureReturn maxVal
  Else
    ProcedureReturn value
  EndIf
EndProcedure

Procedure.f RandomFloat(min.f, max.f)
  ProcedureReturn min + (Random(1000000) / 1000000.0) * (max - min)
EndProcedure

Procedure.f MidiNoteToHz(midiNote.i)
  ProcedureReturn 440.0 * Pow(2.0, (midiNote - 69) / 12.0)
EndProcedure

Procedure.f WaveSample(waveType.i, phase.f)
  Protected p.f = phase - Int(phase)
  Select waveType
    Case 0 ; square
      If p < 0.5 : ProcedureReturn 1.0 : Else : ProcedureReturn -1.0 : EndIf
    Case 1 ; triangle
      If p < 0.5
        ProcedureReturn (p * 4.0) - 1.0
      Else
        ProcedureReturn 3.0 - (p * 4.0)
      EndIf
    Case 2 ; saw
      ProcedureReturn (p * 2.0) - 1.0
  EndSelect
  ProcedureReturn Sin(2.0 * #PI * p)
EndProcedure

Structure Adsr
  attack.f
  decay.f
  sustain.f
  release.f
EndStructure

Procedure.f GetAdsr(time.f, duration.f, *adsr.Adsr)
  Protected t.f
  If *adsr\attack <= 0.0
    If time <= 0.0
      ProcedureReturn 1.0
    EndIf
  ElseIf time < *adsr\attack
    ProcedureReturn time / *adsr\attack
  ElseIf time < *adsr\attack + *adsr\decay
    If *adsr\decay <= 0.0
      ProcedureReturn *adsr\sustain
    EndIf
    t = (time - *adsr\attack) / *adsr\decay
    ProcedureReturn 1.0 - t * (1.0 - *adsr\sustain)
  ElseIf time < duration - *adsr\release
    ProcedureReturn *adsr\sustain
  ElseIf time < duration
    If *adsr\release <= 0.0
      ProcedureReturn 0.0
    EndIf
    t = (time - (duration - *adsr\release)) / *adsr\release
    ProcedureReturn *adsr\sustain * (1.0 - t)
  Else
    ProcedureReturn 0.0
  EndIf
EndProcedure

Procedure.f OnePoleLPF(in.f, *state.Float, cutoffHz.f)
  ; Tiny helper to smooth drum noise.
  Protected rc.f, dt.f, alpha.f
  dt = 1.0 / #SAMPLE_RATE
  cutoffHz = Clamp(cutoffHz, 20.0, 20000.0)
  rc = 1.0 / (2.0 * #PI * cutoffHz)
  alpha = dt / (rc + dt)
  *state\f + alpha * (in - *state\f)
  ProcedureReturn *state\f
EndProcedure

Procedure SetStatus(text.s)
  If IsGadget(#TextStatus)
    SetGadgetText(#TextStatus, text)
  EndIf
EndProcedure

Procedure UpdateActionButtons(hasMusic.i, isPlaying.i)
  If IsGadget(#ButtonPlay)
    DisableGadget(#ButtonPlay, Bool(hasMusic = 0 Or isPlaying <> 0))
  EndIf

  If IsGadget(#ButtonStop)
    DisableGadget(#ButtonStop, Bool(isPlaying = 0))
  EndIf

  If IsGadget(#ButtonSaveWav)
    DisableGadget(#ButtonSaveWav, Bool(hasMusic = 0))
  EndIf

  If IsGadget(#ButtonSaveMidi)
    DisableGadget(#ButtonSaveMidi, Bool(hasMusic = 0))
  EndIf
EndProcedure

IncludeFile "includes/midi_gen.pbi"
IncludeFile "includes/wave_gen.pbi"
IncludeFile "includes/ui_gen.pbi"

Structure FilterState
  v0.f
  v1.f
  v2.f
EndStructure

Procedure.f StateVariableFilter(*state.FilterState, in.f, cutoffHz.f, resonance.f)
  ; Simple State Variable Filter (SVF)
  ; cutoffHz: 20 to 20000
  ; resonance: 0.0 to 1.0 (0.0 = no resonance, 1.0 = self-oscillation)
  
  cutoffHz = Clamp(cutoffHz, 20.0, (#SAMPLE_RATE / 2.0) - 100.0)
  resonance = Clamp(resonance, 0.0, 0.99)

  Protected f.f = 2.0 * Sin(#PI * cutoffHz / #SAMPLE_RATE)
  Protected q.f = 2.0 * (1.0 - resonance)
  
  *state\v0 = in
  *state\v1 = *state\v1 + f * *state\v2
  *state\v2 = *state\v2 + f * (*state\v0 - *state\v1 - q * *state\v2)
  
  ProcedureReturn *state\v1 ; Lowpass output
EndProcedure

Procedure.f NesNoisePeriodSamples(rate.i)
  ; Approximates NES noise timer periods mapped to samples at 44.1kHz.
  ; NES periods are in APU ticks; this is a musical approximation.
  Dim periods.i(16)
  periods(0)=4  : periods(1)=8  : periods(2)=16 : periods(3)=32
  periods(4)=64 : periods(5)=96 : periods(6)=128: periods(7)=160
  periods(8)=202: periods(9)=254: periods(10)=380: periods(11)=508
  periods(12)=762: periods(13)=1016: periods(14)=2034: periods(15)=4068

  rate = ClampI(rate, 0, 15)

  ; Convert a notional NES period to samples. Tuned so rate 4 feels like a hat.
  Protected samples.i = Round(periods(rate) * (#SAMPLE_RATE / 8000.0), #PB_Round_Nearest)
  If samples < 1
    samples = 1
  EndIf
  ProcedureReturn samples
EndProcedure

Procedure.f NesNoiseSample(*lfsr.Long, shortMode.i, *hold.Float, *counter.Long, periodSamples.i)
  ; NES-like 15-bit LFSR noise with rate/hold.
  Protected feedback.i
  Protected bitA.i
  Protected tapBit.i

  If periodSamples < 1
    periodSamples = 1
  EndIf

  If *counter\l <= 0
    bitA = *lfsr\l & 1

    If shortMode
      tapBit = (*lfsr\l >> 6) & 1
    Else
      tapBit = (*lfsr\l >> 1) & 1
    EndIf

    feedback = bitA ! tapBit
    *lfsr\l = (*lfsr\l >> 1) | (feedback << 14)

    If bitA = 0
      *hold\f = 1.0
    Else
      *hold\f = -1.0
    EndIf

    *counter\l = periodSamples
  EndIf

  *counter\l - 1
  ProcedureReturn *hold\f
EndProcedure

Procedure StopPlayback()
  Protected hasMusic.i

  If sound >= 0
    StopSound(sound)
    FreeSound(sound)
    sound = -1
  EndIf

  If tempSoundFile
    DeleteFile(tempSoundFile)
    tempSoundFile = ""
  EndIf

  hasMusic = Bool(ListSize(currentMusic\samples()) > 0)
  UpdateActionButtons(hasMusic, #False)
  SetStatus("Stopped")
EndProcedure

Procedure PlayCurrentMusic()
  Protected tempFile.s

  If ListSize(currentMusic\samples()) <= 0
    UpdateActionButtons(#False, #False)
    SetStatus("Generate a loop first")
    ProcedureReturn
  EndIf

  tempFile = GetTemporaryDirectory() + #APP_NAME + "_" + Str(Date()) + "_" + Str(Random(1000000)) + ".wav"

  StopPlayback()

  If CreateWaveFile(tempFile, @currentMusic)
    sound = LoadSound(#PB_Any, tempFile)
    If sound >= 0
      tempSoundFile = tempFile
      PlaySound(sound)
      UpdateActionButtons(#True, #True)
      SetStatus("Playing: " + currentMusic\name)
    Else
      DeleteFile(tempFile)
      UpdateActionButtons(#True, #False)
      SetStatus("Error: failed to load sound")
    EndIf
  Else
    UpdateActionButtons(#True, #False)
    SetStatus("Error: failed to create WAV")
  EndIf
EndProcedure

Procedure.i ScaleInterval(scaleType.i, degree.i)
  ; degree 0..6
  Dim major.i(7)
  Dim minor.i(7)

  major(0)=0 : major(1)=2 : major(2)=4 : major(3)=5 : major(4)=7 : major(5)=9 : major(6)=11
  minor(0)=0 : minor(1)=2 : minor(2)=3 : minor(3)=5 : minor(4)=7 : minor(5)=8 : minor(6)=10

  degree = degree % 7
  If scaleType = 1
    ProcedureReturn minor(degree)
  EndIf
  ProcedureReturn major(degree)
EndProcedure

Procedure.i ProgressionDegree(prog.i, barIndex.i)
  ; Returns a scale degree (0..6) for the bar.
  Select prog
    Case 0 ; I - V - vi - IV
      Select barIndex % 4
        Case 0 : ProcedureReturn 0
        Case 1 : ProcedureReturn 4
        Case 2 : ProcedureReturn 5
        Case 3 : ProcedureReturn 3
      EndSelect
    Case 1 ; I - IV - V - I
      Select barIndex % 4
        Case 0 : ProcedureReturn 0
        Case 1 : ProcedureReturn 3
        Case 2 : ProcedureReturn 4
        Case 3 : ProcedureReturn 0
      EndSelect
    Case 2 ; ii - V - I - V
      Select barIndex % 4
        Case 0 : ProcedureReturn 1
        Case 1 : ProcedureReturn 4
        Case 2 : ProcedureReturn 0
        Case 3 : ProcedureReturn 4
      EndSelect
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure GenerateMusic(*clip.MusicClip, *params.MusicParams)
  Protected stepsPerBar.i
  Protected noteGridStep.i
  Protected totalBars.i
  Protected totalSteps16.i
  Protected secondsPerBeat.f
  Protected secondsPerStep16.f
  Protected totalSeconds.f
  Protected totalSamples.i

  Protected i.i, s.i

  Protected leadPhase.f = 0.0
  Protected bassPhase.f = 0.0

  Protected leadNote.i
  Protected bassNote.i
  Protected leadHz.f
  Protected bassHz.f

  Protected leadEnv.f, bassEnv.f
  Protected tInStep.f

  Protected swingAmt.f

  Protected noise.f
  Protected kickEnv.f, snareEnv.f, hatEnv.f
  Protected kickAccent.f, snareAccent.f, hatAccent.f

  Protected lpState.Float
  Protected lfsr.Long
  Protected noiseHold.Float
  Protected noiseCounter.Long
  Protected leadFilter.FilterState
  Protected bassFilter.FilterState

  ClearList(*clip\samples())
  ClearList(*clip\events())

  If *params\seed <> 0
    RandomSeed(*params\seed)
  Else
    RandomSeed(Date())
  EndIf

  lfsr\l = $7FFF
  noiseHold\f = 1.0
  noiseCounter\l = 0

  stepsPerBar = *params\stepsPerBar
  If stepsPerBar <> 8 And stepsPerBar <> 16
    stepsPerBar = 16
  EndIf

  ; Internally we schedule notes in 16th-note steps for MIDI.
  totalBars = ClampI(*params\bars, 1, 64)
  totalSteps16 = totalBars * 16

  *clip\tempo = ClampI(*params\tempo, 30, 300)
  secondsPerBeat = 60.0 / *clip\tempo
  secondsPerStep16 = secondsPerBeat / 4.0

  swingAmt = ClampI(*params\swing, 0, 60) / 100.0

  totalSeconds = totalSteps16 * secondsPerStep16
  totalSamples = Round(totalSeconds * #SAMPLE_RATE, #PB_Round_Down)

  *clip\duration = totalSeconds
  *clip\name = "Chiptune Loop"

  ; Determine chord degrees per bar, with a simple A/B section shift.
  Protected sectionBars.i = ClampI(*params\sectionBars, 1, 16)

  Dim chordDeg.i(totalBars-1)
  For i = 0 To totalBars - 1
    chordDeg(i) = ProgressionDegree(*params\progression, i)

    ; Section B: nudge harmony (relative minor / etc.)
    If (i / sectionBars) % 2 = 1
      If chordDeg(i) = 0
        chordDeg(i) = 5
      ElseIf chordDeg(i) = 5
        chordDeg(i) = 3
      EndIf
    EndIf
  Next

  ; Generate lead & bass note events (in 16th steps).
  Protected leadChannel.i = 0
  Protected bassChannel.i = 1

  Protected curLeadDeg.i = Random(6)
  Dim leadStepMidi.i(totalSteps16-1)
  Dim leadStepStart.i(totalSteps16-1)
  Dim leadStepLen.i(totalSteps16-1)
  Dim bassStepMidi.i(totalSteps16-1)
  Dim bassStepStart.i(totalSteps16-1)
  Dim bassStepLen.i(totalSteps16-1)

  noteGridStep = 16 / stepsPerBar
  If noteGridStep < 1
    noteGridStep = 1
  EndIf

  For i = 0 To totalSteps16 - 1
    leadStepMidi(i) = -1
    leadStepStart(i) = 0
    leadStepLen(i) = 0
    bassStepMidi(i) = -1
    bassStepStart(i) = 0
    bassStepLen(i) = 0
  Next

  ; Drum pattern schedule (velocities 0..127) and MIDI events (channel 9)
  Dim kickVel.i(totalSteps16-1)
  Dim snareVel.i(totalSteps16-1)
  Dim hatVel.i(totalSteps16-1)
  Dim hatOpen.i(totalSteps16-1) ; 0=closed, 1=open

  For i = 0 To totalSteps16-1
    kickVel(i) = 0
    snareVel(i) = 0
    hatVel(i) = 0
    hatOpen(i) = 0
  Next

  For s = 0 To totalSteps16 - 1
    Protected bar.i = s / 16
    Protected stepInBar.i = s % 16

    ; Fill drum pattern at the start of each bar
    If stepInBar = 0
      Protected fillChance.i = 0
      If (bar % sectionBars) = sectionBars - 1
        fillChance = 35 ; add a bit of fill at section boundary
      EndIf

      Select *params\drumPattern
        Case 0 ; Simple
          kickVel(s + 0)  = 110
          kickVel(s + 8)  = 95
          snareVel(s + 4) = 105
          snareVel(s + 12)= 100

          ; hats: offbeat 8ths (occasional open hat on last offbeat)
          For i = 0 To 15 Step 2
            hatVel(s + i + 1) = 70
            hatOpen(s + i + 1) = 0
          Next
          If Random(100) < 40
            hatOpen(s + 15) = 1
            hatVel(s + 15) = 85
          EndIf

        Case 1 ; Rock
          kickVel(s + 0)  = 115
          kickVel(s + 6)  = 90
          kickVel(s + 10) = 95

          snareVel(s + 4)  = 115
          snareVel(s + 12) = 112

          ; hats: straight 8ths with accent (open hat on bar end sometimes)
          For i = 0 To 15 Step 2
            hatVel(s + i) = 55
            hatOpen(s + i) = 0
            hatVel(s + i + 1) = 72
            hatOpen(s + i + 1) = 0
          Next
          If Random(100) < 35
            hatOpen(s + 15) = 1
            hatVel(s + 15) = 90
          EndIf

        Case 2 ; DnB-ish
          kickVel(s + 0)  = 120
          kickVel(s + 7)  = 85
          kickVel(s + 10) = 95

          snareVel(s + 4)  = 120
          snareVel(s + 12) = 118

          ; hats: 16ths with alternating accents + occasional open hat
          For i = 0 To 15
            If (i % 2) = 0
              hatVel(s + i) = 60
            Else
              hatVel(s + i) = 85
            EndIf
            hatOpen(s + i) = 0
          Next
          If Random(100) < 45
            hatOpen(s + 14) = 1
            hatVel(s + 14) = 95
          EndIf
      EndSelect

      ; Fills: add a few extra hits on last beat
      If Random(100) < fillChance
        snareVel(s + 14) = 90
        snareVel(s + 15) = 95
        hatVel(s + 14) = 95
        hatVel(s + 15) = 95
        hatOpen(s + 14) = 0
        hatOpen(s + 15) = 1
        If Random(100) < 50
          kickVel(s + 15) = 85
        EndIf
      EndIf

    EndIf

    ; Build a chord triad degrees from chord root.
    Protected rootDeg.i = chordDeg(bar)
    Protected thirdDeg.i = (rootDeg + 2) % 7
    Protected fifthDeg.i = (rootDeg + 4) % 7

    ; Lead: follow the selected note grid while still exporting 16th-note MIDI.
    If stepInBar % noteGridStep = 0
      If stepInBar % 4 = 0
        Select Random(2)
          Case 0 : curLeadDeg = rootDeg
          Case 1 : curLeadDeg = thirdDeg
          Case 2 : curLeadDeg = fifthDeg
        EndSelect
      Else
        If Random(100) < 20
          curLeadDeg = (curLeadDeg + Random(2) - 1 + 7) % 7
        EndIf
        If Random(100) < 20
          curLeadDeg = fifthDeg
        EndIf
      EndIf

      Protected leadLen.i = noteGridStep
      If Random(100) < 15
        leadLen = noteGridStep * 2
      EndIf
      leadLen = ClampI(leadLen, noteGridStep, 16 - stepInBar)
      If s + leadLen > totalSteps16
        leadLen = totalSteps16 - s
      EndIf

      Protected leadMidi.i = 60 + *params\key + ScaleInterval(*params\scaleType, curLeadDeg)
      AddElement(*clip\events())
      *clip\events()\startStep = s
      *clip\events()\lengthSteps = leadLen
      *clip\events()\midiNote = leadMidi
      *clip\events()\velocity = 92
      *clip\events()\channel = leadChannel

      For i = 0 To leadLen - 1
        leadStepMidi(s + i) = leadMidi
        leadStepStart(s + i) = s
        leadStepLen(s + i) = leadLen
      Next
    EndIf

    ; Bass: hit on beats (0,4,8,12) with root/fifth pattern.
    If stepInBar % 4 = 0
      Protected bassDeg.i = rootDeg
      If stepInBar = 8 And Random(100) < 60
        bassDeg = fifthDeg
      EndIf

      Protected bassMidi.i = 36 + *params\key + ScaleInterval(*params\scaleType, bassDeg)
      AddElement(*clip\events())
      *clip\events()\startStep = s
      *clip\events()\lengthSteps = 4
      *clip\events()\midiNote = bassMidi
      *clip\events()\velocity = 80
      *clip\events()\channel = bassChannel

      For i = 0 To 3
        bassStepMidi(s + i) = bassMidi
        bassStepStart(s + i) = s
        bassStepLen(s + i) = 4
      Next
    EndIf
  Next

  ; Add drum MIDI events (channel 10 = channel index 9)
  Protected drumChannel.i = 9
  For s = 0 To totalSteps16 - 1
    If kickVel(s) > 0
      AddElement(*clip\events())
      *clip\events()\startStep = s
      *clip\events()\lengthSteps = 1
      *clip\events()\midiNote = 36 ; kick
      *clip\events()\velocity = ClampI(kickVel(s), 1, 127)
      *clip\events()\channel = drumChannel
    EndIf

    If snareVel(s) > 0
      AddElement(*clip\events())
      *clip\events()\startStep = s
      *clip\events()\lengthSteps = 1
      *clip\events()\midiNote = 38 ; snare
      *clip\events()\velocity = ClampI(snareVel(s), 1, 127)
      *clip\events()\channel = drumChannel
    EndIf

    If hatVel(s) > 0
      AddElement(*clip\events())
      *clip\events()\startStep = s
      *clip\events()\lengthSteps = 1
      If hatOpen(s)
        *clip\events()\midiNote = 46 ; open hat
      Else
        *clip\events()\midiNote = 42 ; closed hat
      EndIf
      *clip\events()\velocity = ClampI(hatVel(s), 1, 127)
      *clip\events()\channel = drumChannel
    EndIf
  Next

  ; Render audio from step schedule.
  Protected curStep.i = 0
  Protected stepSamples.i = Round(secondsPerStep16 * #SAMPLE_RATE, #PB_Round_Down)

  ; Echo ring buffer
  Protected echoDelaySamples.i = Round(ClampI(*params\echoMs, 0, 1000) / 1000.0 * #SAMPLE_RATE, #PB_Round_Nearest)
  Protected echoMix.f = ClampI(*params\echoMix, 0, 100) / 100.0
  If echoDelaySamples < 1 Or echoMix <= 0.0
    echoDelaySamples = 0
    echoMix = 0.0
  EndIf

  Dim echo.f(0)
  Protected echoIndex.i = 0
  If echoDelaySamples > 0
    ReDim echo(echoDelaySamples-1)
  EndIf

  For i = 0 To totalSamples - 1
    ; step index from sample
    curStep = i / stepSamples
    If curStep > totalSteps16 - 1
      curStep = totalSteps16 - 1
    EndIf

    tInStep = (i - (curStep * stepSamples)) / stepSamples
    tInStep = Clamp(tInStep, 0.0, 1.0)

    Protected leadAdsr.Adsr
    leadAdsr\attack = 0.01
    leadAdsr\decay = 0.05
    leadAdsr\sustain = 0.6
    leadAdsr\release = 0.05
    leadEnv = 0.0

    If leadStepMidi(curStep) >= 0
      Protected leadStartStep.i = leadStepStart(curStep)
      Protected leadLengthSteps.i = leadStepLen(curStep)
      Protected leadTime.f = ((curStep - leadStartStep) + tInStep) * secondsPerStep16
      Protected leadDuration.f = leadLengthSteps * secondsPerStep16

      leadNote = leadStepMidi(curStep)
      leadHz = MidiNoteToHz(leadNote)
      leadEnv = GetAdsr(leadTime, leadDuration, @leadAdsr)
    EndIf

    ; Swing: nudge phase slightly on offbeats (audible groove)
    Protected swingPhaseOffset.f = 0.0
    If (curStep % 2) = 1
      swingPhaseOffset = swingAmt * 0.02
    EndIf

    If leadEnv > 0.0
      leadPhase + (leadHz / #SAMPLE_RATE) * (1.0 + swingPhaseOffset)
    EndIf

    ; Resonance Filter for Lead
    Protected leadCutoff.f = 2000.0 + (leadEnv * 5000.0) ; Envelope follow for cutoff
    Protected lead.f = 0.0
    If leadEnv > 0.0
      lead = WaveSample(*params\leadWave, leadPhase) * leadEnv
      lead = StateVariableFilter(@leadFilter, lead, leadCutoff, 0.3)
    EndIf

    ; Bass follows the generated event schedule.
    bassEnv = 0.0
    If bassStepMidi(curStep) >= 0
      Protected bassStartStep.i = bassStepStart(curStep)
      Protected bassLengthSteps.i = bassStepLen(curStep)
      Protected bassTime.f = ((curStep - bassStartStep) + tInStep) * secondsPerStep16
      Protected bassDuration.f = bassLengthSteps * secondsPerStep16
      Protected bassAdsr.Adsr

      bassAdsr\attack = 0.01
      bassAdsr\decay = 0.06
      bassAdsr\sustain = 0.75
      bassAdsr\release = 0.08

      bassNote = bassStepMidi(curStep)
      bassHz = MidiNoteToHz(bassNote)
      bassPhase + bassHz / #SAMPLE_RATE
      bassEnv = GetAdsr(bassTime, bassDuration, @bassAdsr)
    EndIf

    ; Drums (envelopes + accents from pattern)
    kickEnv = 0.0
    snareEnv = 0.0
    hatEnv = 0.0

    kickAccent = kickVel(curStep) / 127.0
    snareAccent = snareVel(curStep) / 127.0
    hatAccent = hatVel(curStep) / 127.0

    If kickAccent > 0.0
      kickEnv = Exp(-tInStep * 10.0) * (0.6 + 0.7 * kickAccent)
    EndIf

    Protected drumDecayFactor.f = ClampI(*params\drumDecay, 10, 120) / 45.0

    If snareAccent > 0.0
      snareEnv = Exp(-tInStep * (14.0 / drumDecayFactor)) * (0.5 + 0.8 * snareAccent)
    EndIf

    If hatAccent > 0.0
      hatEnv = Exp(-tInStep * (40.0 / drumDecayFactor)) * (0.3 + 0.9 * hatAccent)
    EndIf

    Select ClampI(*params\noiseMode, 0, 2)
      Case 0
        noise = RandomFloat(-1.0, 1.0)
        noise = OnePoleLPF(noise, @lpState, ClampI(*params\drumNoiseTone, 500, 12000))
      Case 1
        noise = NesNoiseSample(@lfsr, #True, @noiseHold, @noiseCounter, NesNoisePeriodSamples(*params\noiseRate))
      Case 2
        noise = NesNoiseSample(@lfsr, #False, @noiseHold, @noiseCounter, NesNoisePeriodSamples(*params\noiseRate))
    EndSelect

    Protected kick.f = Sin(2.0 * #PI * (55.0 * (1.0 - tInStep * 0.5)) * (i / #SAMPLE_RATE)) * kickEnv
    Protected snare.f = noise * snareEnv
    Protected hat.f = noise * hatEnv

    Protected bass.f = WaveSample(*params\bassWave, bassPhase) * bassEnv
    If bassEnv > 0.0
      bass = StateVariableFilter(@bassFilter, bass, 180.0 + (bassEnv * 900.0), 0.1)
    EndIf

    Protected mix.f
    mix = lead * *params\leadVol + bass * *params\bassVol + (kick + snare + hat) * *params\drumVol

    ; Echo (simple feedback-less delay)
    If echoDelaySamples > 0
      Protected delayed.f = echo(echoIndex)
      echo(echoIndex) = mix
      echoIndex + 1
      If echoIndex >= echoDelaySamples
        echoIndex = 0
      EndIf
      mix = mix * (1.0 - echoMix) + delayed * echoMix
    EndIf

    mix = SoftClip(mix, 0.35)
    mix = Clamp(mix, -1.0, 1.0)

    AddElement(*clip\samples())
    *clip\samples() = mix
  Next
EndProcedure

Procedure GenerateCurrentMusic()
  Protected hasMusic.i

  StopPlayback()

  params\tempo = GetGadgetState(#SpinTempo)
  params\bars = GetGadgetState(#SpinBars)

  params\stepsPerBar = Val(GetGadgetText(#ComboSteps))
  params\key = GetGadgetState(#ComboKey)
  params\scaleType = GetGadgetState(#ComboScale)
  params\seed = GetGadgetState(#SpinSeed)

  params\leadWave = GetGadgetState(#ComboLeadWave)
  params\bassWave = GetGadgetState(#ComboBassWave)

  params\leadVol = GetGadgetState(#SpinLeadVol) / 100.0
  params\bassVol = GetGadgetState(#SpinBassVol) / 100.0
  params\drumVol = GetGadgetState(#SpinDrumVol) / 100.0

  params\swing = GetGadgetState(#SpinSwing)
  params\echoMs = GetGadgetState(#SpinEchoMs)
  params\echoMix = GetGadgetState(#SpinEchoMix)

  params\sectionBars = GetGadgetState(#SpinSectionBars)
  params\progression = GetGadgetState(#ComboProgression)
  params\drumPattern = GetGadgetState(#ComboDrumPattern)
  params\drumNoiseTone = GetGadgetState(#SpinDrumTone)
  params\drumDecay = GetGadgetState(#SpinDrumDecay)
  params\noiseMode = GetGadgetState(#ComboNoiseMode)
  params\noiseRate = GetGadgetState(#SpinNoiseRate)

  SetStatus("Generating music...")

  GenerateMusic(@currentMusic, @params)

  hasMusic = Bool(ListSize(currentMusic\samples()) > 0)
  UpdateActionButtons(hasMusic, #False)

  If hasMusic
    SetStatus("Generated loop: " + StrF(currentMusic\duration, 2) + "s, " + Str(ListSize(currentMusic\samples())) + " samples")
  Else
    SetStatus("Error: generation produced no audio")
  EndIf
EndProcedure

Procedure SaveCurrentWav()
  Protected filename.s = SaveFileRequester("Save Music WAV", "music_loop.wav", "Wave Files (*.wav)|*.wav", 0)
  If filename
    If CreateWaveFile(filename, @currentMusic)
      SetStatus("Saved WAV: " + filename)
    Else
      SetStatus("Error: failed to save WAV")
    EndIf
  EndIf
EndProcedure

Procedure SaveCurrentMidi()
  Protected filename.s = SaveFileRequester("Save Music MIDI", "music_loop.mid", "MIDI Files (*.mid)|*.mid", 0)
  If filename
    If CreateMidiFile(filename, @currentMusic)
      SetStatus("Saved MIDI: " + filename)
    Else
      SetStatus("Error: failed to save MIDI")
    EndIf
  EndIf
EndProcedure

If InitSound()
  If OpenAppWindow()
    RunEventLoop()
  EndIf
  StopPlayback()
Else
  MessageRequester("Error", "Failed to initialize sound system!", #PB_MessageRequester_Error)
EndIf

If hMutex
  CloseHandle_(hMutex)
  hMutex = 0
EndIf

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 13
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = game_music_gen.ico
; Executable = ..\Game_Music_Gen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = Game_Music_Gen
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = A configurable game music generator
; VersionField7 = Game_Music_Gen
; VersionField8 = Game_Music_Gen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60