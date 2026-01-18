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
Declare.i CreateWaveFile(filename.s, *clip.MusicClip)
Declare.i CreateMidiFile(filename.s, *clip.MusicClip)
Declare GenerateMusic(*clip.MusicClip, *params.MusicParams)

Procedure ConfirmExit()
  Protected req.i = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If req = #PB_MessageRequester_Yes
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

Procedure.i NesNoisePeriodSamples(rate.i)
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

Procedure AddMidiEvent(List out.a(), delta.i, status.a, d1.a, d2.a)
  ; VLQ delta
  Protected tmp.l
  Protected b.a

  tmp = delta & $0FFFFFFF

  ; Write into a small stack then flush reversed
  Dim bytes.a(4)
  Protected count.i = 0

  Repeat
    bytes(count) = tmp & $7F
    tmp >> 7
    count + 1
  Until tmp = 0 Or count = 4

  Protected i.i
  For i = count - 1 To 0 Step -1
    b = bytes(i)
    If i <> 0
      b | $80
    EndIf
    AddElement(out())
    out() = b
  Next

  AddElement(out()) : out() = status
  AddElement(out()) : out() = d1
  AddElement(out()) : out() = d2
EndProcedure

Procedure.i CreateMidiFile(filename.s, *clip.MusicClip)
  ; Type 0 MIDI file, 1 track, ticksPerQuarter=480
  Protected file.i
  Protected ticksPerQuarter.i = 480
  Protected tempoBpm.i = ClampI(*clip\tempo, 30, 300)
  Protected usPerQuarter.l = 60000000 / tempoBpm

  Protected stepLenTicks.i

  If *clip\tempo <= 0 Or ListSize(*clip\events()) = 0
    ProcedureReturn #False
  EndIf

  ; We store events in "steps" where 1 step is a 16th note.
  stepLenTicks = ticksPerQuarter / 4

  NewList track.a()

  ; Tempo meta event at time 0
  AddElement(track()) : track() = 0 ; delta 0
  AddElement(track()) : track() = $FF
  AddElement(track()) : track() = $51
  AddElement(track()) : track() = 3
  AddElement(track()) : track() = (usPerQuarter >> 16) & $FF
  AddElement(track()) : track() = (usPerQuarter >> 8) & $FF
  AddElement(track()) : track() = usPerQuarter & $FF

  ; Collect note on/off as step-based events, then sort by tick.
  Structure MidiMsg
    tick.i
    status.a
    d1.a
    d2.a
  EndStructure

  NewList msgs.MidiMsg()

  Protected e.NoteEvent
  ForEach *clip\events()
    e = *clip\events()

    AddElement(msgs())
    msgs()\tick = e\startStep * stepLenTicks
    msgs()\status = $90 | (e\channel & $0F)
    msgs()\d1 = e\midiNote & $7F
    msgs()\d2 = e\velocity & $7F

    AddElement(msgs())
    msgs()\tick = (e\startStep + e\lengthSteps) * stepLenTicks
    msgs()\status = $80 | (e\channel & $0F)
    msgs()\d1 = e\midiNote & $7F
    msgs()\d2 = 0
  Next

  SortStructuredList(msgs(), #PB_Sort_Ascending, OffsetOf(MidiMsg\tick), TypeOf(MidiMsg\tick))

  Protected lastTick.i = 0
  ForEach msgs()
    AddMidiEvent(track(), msgs()\tick - lastTick, msgs()\status, msgs()\d1, msgs()\d2)
    lastTick = msgs()\tick
  Next

  ; End of track
  AddElement(track()) : track() = 0
  AddElement(track()) : track() = $FF
  AddElement(track()) : track() = $2F
  AddElement(track()) : track() = 0

  file = CreateFile(#PB_Any, filename)
  If file = 0
    ProcedureReturn #False
  EndIf

  ; Header chunk
  WriteString(file, "MThd", #PB_Ascii)
  WriteLong(file, 6)
  WriteWord(file, 0) ; format 0
  WriteWord(file, 1) ; one track
  WriteWord(file, ticksPerQuarter)

  ; Track chunk
  WriteString(file, "MTrk", #PB_Ascii)
  WriteLong(file, ListSize(track()))
  ForEach track()
    WriteByte(file, track())
  Next

  CloseFile(file)
  ProcedureReturn #True
EndProcedure

Procedure.i CreateWaveFile(filename.s, *clip.MusicClip)
  Protected file.i
  Protected.WaveHeader header
  Protected.w sample16
  Protected numSamples.i = ListSize(*clip\samples())
  Protected dataSize.i = numSamples * (#BITS_PER_SAMPLE / 8)
  Protected scaled.f

  If numSamples <= 0
    ProcedureReturn #False
  EndIf

  header\chunkID = $46464952 ; RIFF
  header\chunkSize = 36 + dataSize
  header\format = $45564157 ; WAVE
  header\subchunk1ID = $20746D66 ; fmt 
  header\subchunk1Size = 16
  header\audioFormat = 1
  header\numChannels = #CHANNELS
  header\sampleRate = #SAMPLE_RATE
  header\byteRate = #SAMPLE_RATE * #CHANNELS * #BITS_PER_SAMPLE / 8
  header\blockAlign = #CHANNELS * #BITS_PER_SAMPLE / 8
  header\bitsPerSample = #BITS_PER_SAMPLE
  header\subchunk2ID = $61746164 ; data
  header\subchunk2Size = dataSize

  file = CreateFile(#PB_Any, filename)
  If file = 0
    ProcedureReturn #False
  EndIf

  WriteData(file, @header, SizeOf(WaveHeader))

  ForEach *clip\samples()
    scaled = Clamp(*clip\samples(), -1.0, 1.0) * 32767.0
    sample16 = Round(scaled, #PB_Round_Nearest)
    WriteWord(file, sample16)
  Next

  CloseFile(file)
  ProcedureReturn #True
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
EndProcedure

Procedure PlayCurrentMusic()
  Protected tempFile.s

  tempFile = GetTemporaryDirectory() + #APP_NAME + "_" + Str(Date()) + "_" + Str(Random(1000000)) + ".wav"

  StopPlayback()

  If CreateWaveFile(tempFile, @currentMusic)
    sound = LoadSound(#PB_Any, tempFile)
    If sound >= 0
      tempSoundFile = tempFile
      PlaySound(sound)
      SetGadgetText(#TextStatus, "Playing: " + currentMusic\name)
    Else
      DeleteFile(tempFile)
      SetGadgetText(#TextStatus, "Error: failed to load sound")
    EndIf
  Else
    SetGadgetText(#TextStatus, "Error: failed to create WAV")
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

      ; Clamp in case bars < 1 (safety)
      For i = 0 To 15
        If (s + i) >= totalSteps16
          Break
        EndIf
      Next
    EndIf

    ; Build a chord triad degrees from chord root.
    Protected rootDeg.i = chordDeg(bar)
    Protected thirdDeg.i = (rootDeg + 2) % 7
    Protected fifthDeg.i = (rootDeg + 4) % 7

    ; Lead: pick chord tones on strong steps, passing tones otherwise.
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

    Protected leadLen.i = 1
    If Random(100) < 15
      leadLen = 2
    EndIf

    Protected leadMidi.i = 60 + *params\key + ScaleInterval(*params\scaleType, curLeadDeg)
    AddElement(*clip\events())
    *clip\events()\startStep = s
    *clip\events()\lengthSteps = leadLen
    *clip\events()\midiNote = leadMidi
    *clip\events()\velocity = 92
    *clip\events()\channel = leadChannel

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

    ; Convert step -> bar
    Protected bar2.i = curStep / 16
    Protected stepInBar2.i = curStep % 16

    Protected rootDeg2.i = chordDeg(bar2)
    Protected thirdDeg2.i = (rootDeg2 + 2) % 7
    Protected fifthDeg2.i = (rootDeg2 + 4) % 7

    ; Lead pitch like MIDI schedule (approx)
    Protected leadDeg.i
    leadDeg = curLeadDeg
    If stepInBar2 % 4 = 0
      leadDeg = rootDeg2
    EndIf

    leadNote = 60 + *params\key + ScaleInterval(*params\scaleType, leadDeg)
    leadHz = MidiNoteToHz(leadNote)

    leadEnv = 1.0
    If tInStep < 0.05
      leadEnv = tInStep / 0.05
    ElseIf tInStep > 0.85
      leadEnv = Clamp(1.0 - (tInStep - 0.85) / 0.15, 0.0, 1.0)
    EndIf

    ; Swing: nudge phase slightly on offbeats (audible groove)
    Protected swingPhaseOffset.f = 0.0
    If (curStep % 2) = 1
      swingPhaseOffset = swingAmt * 0.02
    EndIf

    leadPhase + (leadHz / #SAMPLE_RATE) * (1.0 + swingPhaseOffset)

    ; Bass on beats
    bassEnv = 0.0
    If stepInBar2 % 4 = 0
      bassNote = 36 + *params\key + ScaleInterval(*params\scaleType, rootDeg2)
      If stepInBar2 = 8 And Random(100) < 60
        bassNote = 36 + *params\key + ScaleInterval(*params\scaleType, fifthDeg2)
      EndIf

      bassHz = MidiNoteToHz(bassNote)
      bassPhase + bassHz / #SAMPLE_RATE

      bassEnv = 1.0
      If tInStep < 0.08
        bassEnv = tInStep / 0.08
      ElseIf tInStep > 0.7
        bassEnv = Clamp(1.0 - (tInStep - 0.7) / 0.3, 0.0, 1.0)
      EndIf
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

    Protected lead.f = WaveSample(*params\leadWave, leadPhase) * leadEnv
    Protected bass.f = WaveSample(*params\bassWave, bassPhase) * bassEnv

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

    mix = Clamp(mix, -1.0, 1.0)

    AddElement(*clip\samples())
    *clip\samples() = mix
  Next
EndProcedure

Procedure GenerateCurrentMusic()
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

  SetGadgetText(#TextStatus, "Generating music...")

  GenerateMusic(@currentMusic, @params)

  SetGadgetText(#TextStatus, "Generated loop: " + StrF(currentMusic\duration, 2) + "s, " + Str(ListSize(currentMusic\samples())) + " samples")

  DisableGadget(#ButtonPlay, #False)
  DisableGadget(#ButtonStop, #False)
  DisableGadget(#ButtonSaveWav, #False)
  DisableGadget(#ButtonSaveMidi, #False)
EndProcedure

Procedure SaveCurrentWav()
  Protected filename.s = SaveFileRequester("Save Music WAV", "music_loop.wav", "Wave Files (*.wav)|*.wav", 0)
  If filename
    If CreateWaveFile(filename, @currentMusic)
      SetGadgetText(#TextStatus, "Saved WAV: " + filename)
    Else
      SetGadgetText(#TextStatus, "Error: failed to save WAV")
    EndIf
  EndIf
EndProcedure

Procedure SaveCurrentMidi()
  Protected filename.s = SaveFileRequester("Save Music MIDI", "music_loop.mid", "MIDI Files (*.mid)|*.mid", 0)
  If filename
    If CreateMidiFile(filename, @currentMusic)
      SetGadgetText(#TextStatus, "Saved MIDI: " + filename)
    Else
      SetGadgetText(#TextStatus, "Error: failed to save MIDI")
    EndIf
  EndIf
EndProcedure

If InitSound()
  OpenWindow(#Window, 0, 0, 820, 660, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)

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

  DisableGadget(#ButtonPlay, #True)
  DisableGadget(#ButtonStop, #True)
  DisableGadget(#ButtonSaveWav, #True)
  DisableGadget(#ButtonSaveMidi, #True)

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

  StopPlayback()
Else
  MessageRequester("Error", "Failed to initialize sound system!", #PB_MessageRequester_Error)
EndIf

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 1110
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = game_music_gen.ico
; Executable = ..\Game_Music_Gen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = Game_Music_Gen
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = A configurable game music generator
; VersionField7 = Game_Music_Gen
; VersionField8 = Game_Music_Gen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60