;------------------------------------------------------------------------------
; Sound / SFX system (extracted from pbzt.pb)
;------------------------------------------------------------------------------

Structure TSfxParams
  DurationMS.i
  WaveType.i   ; 0=square, 1=noise, 2=square+noise
  F0.f
  F1.f
  AttackMS.i
  DecayMS.i
  ReleaseMS.i
  Volume.f     ; 0..1
  NoiseMix.f   ; 0..1
  VibRate.f    ; Hz (0=off)
  VibDepth.f   ; 0..~0.05 (fractional, eg 0.012 = 1.2%)
EndStructure

; SFX kinds (used by PlaySfx/BuildSfxCache and in other includes).
Enumeration
  #Sfx_Step
  #Sfx_Treasure
  #Sfx_Key
  #Sfx_Door
  #Sfx_Hurt
  #Sfx_Exit
  #Sfx_Board
  #Sfx_Beep
EndEnumeration

Global SfxReady.b
Global Dim SfxSoundId.i(#Sfx_Beep)

;------------------------------------------------------------------------------
; Simple board music (tiny chiptune tracker)
;------------------------------------------------------------------------------

Global MusicReady.b
Global MusicSoundId.i
Global MusicStarted.b
Global MusicCurrentKey.s
Global MusicMasterVol.f = 0.25
Global MusicCurrentText.s

#SFX_BAKE_MASTER_VOL = 4.0

; Runtime SFX tuning (via F10 Sound Settings)
Global SfxMasterVol.f = 1.0
Global SfxPitchMul.f = 1.0
Global SfxNoiseMul.f = 1.0
Global SfxVibMul.f = 1.0

Declare StopBoardMusic()
Declare StartBoardMusic(TrackKey.s, TrackText.s)
Declare RefreshBoardMusicVolume()
Declare ApplySfxMasterVolume()

;------------------------------------------------------------------------------
; ClampF
; Purpose: Clamp a float to a min/max range.
;------------------------------------------------------------------------------

Procedure.f ClampF(Value.f, Min.f, Max.f)
  If Value < Min : ProcedureReturn Min : EndIf
  If Value > Max : ProcedureReturn Max : EndIf
  ProcedureReturn Value
EndProcedure

;------------------------------------------------------------------------------
; SfxEnvADR
; Purpose: Procedure: Sfx Env A D R.
;------------------------------------------------------------------------------

Procedure.f SfxEnvADR(tMS.i, totalMS.i, aMS.i, dMS.i, rMS.i)
  Protected t.f = tMS
  Protected total.f = totalMS
  Protected a.f = aMS
  Protected d.f = dMS
  Protected r.f = rMS

  If total <= 1.0 : ProcedureReturn 0.0 : EndIf
  If a < 1.0 : a = 1.0 : EndIf
  If d < 1.0 : d = 1.0 : EndIf
  If r < 1.0 : r = 1.0 : EndIf

  If t < a
    ProcedureReturn t / a
  ElseIf t < a + d
    ; exponential-ish decay from 1 -> 0.0001
    Protected x.f = (t - a) / d
    ProcedureReturn Pow(0.0001, x)
  ElseIf t < total
    ; release tail
    Protected rem.f = total - t
    Protected x2.f = 1.0 - (rem / r)
    x2 = ClampF(x2, 0.0, 1.0)
    ProcedureReturn Pow(0.0001, x2)
  EndIf

  ProcedureReturn 0.0
EndProcedure

;------------------------------------------------------------------------------
; GetSfxParams
; Purpose: Procedure: Get Sfx Params.
;------------------------------------------------------------------------------

Procedure GetSfxParams(Kind.i, *out.TSfxParams)
  ; Base defaults (before runtime tuning multipliers)
  *out\DurationMS = 120
  *out\WaveType   = 0
  *out\F0         = 440
  *out\F1         = 880
  *out\AttackMS   = 1
  *out\DecayMS    = 90
  *out\ReleaseMS  = 18
  *out\Volume     = 0.22
  *out\NoiseMix   = 0.30
  *out\VibRate    = 0.0
  *out\VibDepth   = 0.0

  Select Kind
    Case #Sfx_Step
      ; tiny "tap" so walking feels responsive but not annoying
      *out\DurationMS = 28
      *out\WaveType   = 0
      *out\F0 = 520 : *out\F1 = 520
      *out\AttackMS = 1 : *out\DecayMS = 18 : *out\ReleaseMS = 8
      *out\Volume = 0.10

    Case #Sfx_Treasure
      ; bright coin blip with a little shimmer
      *out\DurationMS = 95
      *out\WaveType   = 0
      *out\F0 = 1100 : *out\F1 = 2200
      *out\AttackMS = 1 : *out\DecayMS = 65 : *out\ReleaseMS = 12
      *out\VibRate = 24.0 : *out\VibDepth = 0.012
      *out\Volume = 0.22

    Case #Sfx_Key
      ; chirpy pickup
      *out\DurationMS = 85
      *out\WaveType   = 0
      *out\F0 = 900 : *out\F1 = 1500
      *out\AttackMS = 1 : *out\DecayMS = 55 : *out\ReleaseMS = 10
      *out\VibRate = 18.0 : *out\VibDepth = 0.010
      *out\Volume = 0.22

    Case #Sfx_Door
      ; thumpy door with a dash of noise
      *out\DurationMS = 190
      *out\WaveType   = 2
      *out\F0 = 220 : *out\F1 = 95
      *out\AttackMS = 1 : *out\DecayMS = 135 : *out\ReleaseMS = 25
      *out\NoiseMix = 0.33
      *out\VibRate = 8.0 : *out\VibDepth = 0.006
      *out\Volume = 0.20

    Case #Sfx_Hurt
      ; noisy punch
      *out\DurationMS = 85
      *out\WaveType   = 2
      *out\F0 = 260 : *out\F1 = 120
      *out\AttackMS = 1 : *out\DecayMS = 55 : *out\ReleaseMS = 12
      *out\NoiseMix = 0.60
      *out\Volume = 0.28

    Case #Sfx_Exit
      ; rising "whoosh" into the next board
      *out\DurationMS = 165
      *out\WaveType   = 0
      *out\F0 = 440 : *out\F1 = 880
      *out\AttackMS = 1 : *out\DecayMS = 120 : *out\ReleaseMS = 18
      *out\VibRate = 10.0 : *out\VibDepth = 0.006
      *out\Volume = 0.20

    Case #Sfx_Board
      ; short jingle-ish sweep
      *out\DurationMS = 135
      *out\WaveType   = 0
      *out\F0 = 350 : *out\F1 = 700
      *out\AttackMS = 1 : *out\DecayMS = 95 : *out\ReleaseMS = 16
      *out\VibRate = 12.0 : *out\VibDepth = 0.005
      *out\Volume = 0.17

    Case #Sfx_Beep
      ; UI beep
      *out\DurationMS = 75
      *out\WaveType   = 0
      *out\F0 = 660 : *out\F1 = 660
      *out\AttackMS = 1 : *out\DecayMS = 50 : *out\ReleaseMS = 12
      *out\VibRate = 14.0 : *out\VibDepth = 0.004
      *out\Volume = 0.18
  EndSelect

  ; Apply runtime tuning multipliers
  ; Master volume is applied at playback time via SoundVolume(), so we bake at 1.0 here.
  *out\Volume = ClampF(*out\Volume, 0.0, 1.0)
  *out\F0 = *out\F0 * ClampF(SfxPitchMul, 0.5, 2.0)
  *out\F1 = *out\F1 * ClampF(SfxPitchMul, 0.5, 2.0)
  *out\NoiseMix = ClampF(*out\NoiseMix * ClampF(SfxNoiseMul, 0.0, 2.0), 0.0, 1.0)
  *out\VibRate = *out\VibRate * ClampF(SfxVibMul, 0.0, 2.0)
  *out\VibDepth = ClampF(*out\VibDepth * ClampF(SfxVibMul, 0.0, 2.0), 0.0, 0.08)
EndProcedure

;------------------------------------------------------------------------------
; BuildSfxWavMemory
; Purpose: Procedure: Build Sfx Wav Memory.
;------------------------------------------------------------------------------

Procedure.i BuildSfxWavMemory(*p.TSfxParams, SampleRate.i = 44100)
  Protected bitsPerSample.i = 16
  Protected channels.i = 1
  Protected bytesPerSample.i = bitsPerSample / 8

  Protected totalSamples.i = (SampleRate * *p\DurationMS) / 1000
  If totalSamples < 1 : totalSamples = 1 : EndIf

  Protected dataBytes.i = totalSamples * channels * bytesPerSample
  Protected headerBytes.i = 44
  Protected wavBytes.i = headerBytes + dataBytes

  Protected *mem = AllocateMemory(wavBytes)
  If *mem = 0 : ProcedureReturn 0 : EndIf

  ; WAV header (PCM)
  PokeS(*mem + 0,  "RIFF", 4, #PB_Ascii)
  PokeL(*mem + 4,  wavBytes - 8)
  PokeS(*mem + 8,  "WAVE", 4, #PB_Ascii)

  PokeS(*mem + 12, "fmt ", 4, #PB_Ascii)
  PokeL(*mem + 16, 16)
  PokeW(*mem + 20, 1)
  PokeW(*mem + 22, channels)
  PokeL(*mem + 24, SampleRate)
  PokeL(*mem + 28, SampleRate * channels * bytesPerSample)
  PokeW(*mem + 32, channels * bytesPerSample)
  PokeW(*mem + 34, bitsPerSample)

  PokeS(*mem + 36, "data", 4, #PB_Ascii)
  PokeL(*mem + 40, dataBytes)

  Protected *pcm = *mem + headerBytes
  Protected.f phase = 0.0
  Protected.f vol.f = ClampF(*p\Volume, 0.0, 1.0)
  Protected.f noiseMix.f = ClampF(*p\NoiseMix, 0.0, 1.0)

  Protected lfsr.i = $ACE1
  Protected i.i

  For i = 0 To totalSamples - 1
    Protected tMS.i = (i * 1000) / SampleRate

    Protected.f ft = 0.0
    If totalSamples > 1
      ft = i / (totalSamples - 1.0)
    EndIf

    Protected.f baseFreq = *p\F0 + (*p\F1 - *p\F0) * ft
    If baseFreq < 1.0 : baseFreq = 1.0 : EndIf

    ; light vibrato for extra "feel"
    Protected.f freq = baseFreq
    If *p\VibRate > 0.0 And *p\VibDepth > 0.0
      Protected.f tSec = i / SampleRate
      Protected.f vib = Sin(2.0 * #PI * *p\VibRate * tSec)
      freq = baseFreq * (1.0 + ClampF(*p\VibDepth, 0.0, 0.08) * vib)
      If freq < 1.0 : freq = 1.0 : EndIf
    EndIf

    Protected.f env = SfxEnvADR(tMS, *p\DurationMS, *p\AttackMS, *p\DecayMS, *p\ReleaseMS)
    Protected.f amp = vol * env

    ; square wave
    phase + freq / SampleRate
    phase - Int(phase)

    Protected.f sq = -1.0
    If phase < 0.5 : sq = 1.0 : EndIf

    ; noise (simple LFSR)
    lfsr ! (-(lfsr & 1) & $B400)
    lfsr >> 1
    Protected.f nz = -1.0
    If (lfsr & 1) <> 0 : nz = 1.0 : EndIf

    Protected.f sample.f
    Select *p\WaveType
      Case 0
        sample = sq
      Case 1
        sample = nz
      Case 2
        sample = (sq * (1.0 - noiseMix)) + (nz * noiseMix)
    EndSelect

    Protected v.i = Int(sample * amp * 32767.0)
    If v > 32767 : v = 32767 : EndIf
    If v < -32768 : v = -32768 : EndIf

    PokeW(*pcm + i * 2, v)
  Next

  ProcedureReturn *mem
EndProcedure

;------------------------------------------------------------------------------
; FreeSfxSystem
; Purpose: Procedure: Free Sfx System.
;------------------------------------------------------------------------------

Procedure FreeSfxSystem()
  Protected i.i

  StopBoardMusic()
 
  For i = 0 To ArraySize(SfxSoundId())
    If SfxSoundId(i) <> 0
      FreeSound(SfxSoundId(i))
      SfxSoundId(i) = 0
    EndIf
  Next
 
  SfxReady = #False
EndProcedure

;------------------------------------------------------------------------------
; BuildSfxCache
; Purpose: Procedure: Build Sfx Cache.
;------------------------------------------------------------------------------

Procedure BuildSfxCache()
  Protected i.i
  Protected p.TSfxParams

  If SfxReady = 0
    ProcedureReturn
  EndIf

  ; Free any previously cached sounds before rebuilding
  For i = 0 To ArraySize(SfxSoundId())
    If SfxSoundId(i) <> 0
      FreeSound(SfxSoundId(i))
      SfxSoundId(i) = 0
    EndIf
  Next

  For i = 0 To ArraySize(SfxSoundId())
    GetSfxParams(i, @p)

    Protected *wav = BuildSfxWavMemory(@p)
    If *wav
      Protected wavBytes.i = 44 + ((44100 * p\DurationMS) / 1000) * 2
      SfxSoundId(i) = CatchSound(#PB_Any, *wav, wavBytes)
      FreeMemory(*wav)
    EndIf
  Next

  ApplySfxMasterVolume()
EndProcedure

Procedure ApplySfxMasterVolume()
  ; Apply master volume to cached sounds without rebuilding.
  ; PureBasic SoundVolume range is 0..100
  Protected vol.i = Int(ClampF(SfxMasterVol / #SFX_BAKE_MASTER_VOL, 0.0, 1.0) * 100.0)
  Protected i.i
  For i = 0 To ArraySize(SfxSoundId())
    If SfxSoundId(i) <> 0
      SoundVolume(SfxSoundId(i), vol)
    EndIf
  Next
EndProcedure

;------------------------------------------------------------------------------
; InitSfxSystem
; Purpose: Procedure: Init Sfx System.
;------------------------------------------------------------------------------

Procedure InitSfxSystem()
  SfxReady = #False

  ; InitSound can fail on some setups; we keep a beep fallback.
  If InitSound() = 0
    ProcedureReturn
  EndIf

  SfxReady = #True
  BuildSfxCache()
EndProcedure

;------------------------------------------------------------------------------
; PlaySfx
; Purpose: Procedure: Play Sfx.
;------------------------------------------------------------------------------

Procedure PlaySfx(Kind.i)
  If SfxReady And Kind >= 0 And Kind <= ArraySize(SfxSoundId()) And SfxSoundId(Kind) <> 0
    SoundVolume(SfxSoundId(Kind), Int(ClampF(SfxMasterVol / #SFX_BAKE_MASTER_VOL, 0.0, 1.0) * 100.0))
    PlaySound(SfxSoundId(Kind), #PB_Sound_MultiChannel)
    ProcedureReturn
  EndIf

  ; Fallback sound if audio init/loading failed.
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected ok.i
    Select Kind
      Case #Sfx_Step     : ok = Beep_(880, 35)
      Case #Sfx_Treasure : ok = Beep_(988, 90)
      Case #Sfx_Key      : ok = Beep_(1175, 90)
      Case #Sfx_Door     : ok = Beep_(392, 120)
      Case #Sfx_Hurt     : ok = Beep_(220, 140)
      Case #Sfx_Exit     : ok = Beep_(784, 140)
      Case #Sfx_Board    : ok = Beep_(523, 90)
      Case #Sfx_Beep     : ok = Beep_(660, 80)
    EndSelect

    If ok = 0
      MessageBeep_(0)
    EndIf
  CompilerElse
    Beep(600, 80)
  CompilerEndIf
EndProcedure

;------------------------------------------------------------------------------
; Music helpers
;------------------------------------------------------------------------------

Procedure StopBoardMusic()
  If MusicSoundId <> 0
    StopSound(MusicSoundId)
    FreeSound(MusicSoundId)
  EndIf

  MusicSoundId = 0
  MusicStarted = #False
  MusicCurrentKey = ""
  MusicCurrentText = ""
EndProcedure

Procedure.f NoteToFreq(NoteName.s)
  ; Accept: C4, C#4, Db4, A3, etc. Returns 0.0 for rest/invalid.
  Protected s.s = UCase(Trim(NoteName))
  If s = "" Or s = "-" : ProcedureReturn 0.0 : EndIf

  Protected noteChar.s = Left(s, 1)
  Protected acc.s
  Protected octave.i
  Protected semitoneFromC.i
  Protected n.i

  Select noteChar
    Case "C" : semitoneFromC = 0
    Case "D" : semitoneFromC = 2
    Case "E" : semitoneFromC = 4
    Case "F" : semitoneFromC = 5
    Case "G" : semitoneFromC = 7
    Case "A" : semitoneFromC = 9
    Case "B" : semitoneFromC = 11
    Default
      ProcedureReturn 0.0
  EndSelect

  acc = Mid(s, 2, 1)
  If acc = "#"
    semitoneFromC + 1
    octave = Val(Mid(s, 3))
  ElseIf acc = "B" ; flat
    semitoneFromC - 1
    octave = Val(Mid(s, 3))
  Else
    octave = Val(Mid(s, 2))
  EndIf

  ; MIDI note number (C4=60)
  n = (octave + 1) * 12 + semitoneFromC
  ; A4=69 -> 440 Hz
  ProcedureReturn 440.0 * Pow(2.0, (n - 69) / 12.0)
EndProcedure

Procedure.s MusicStripBars(line.s)
  ; Remove visual separators.
  ProcedureReturn ReplaceString(line, "|", " ")
EndProcedure

Procedure.i MusicTokenize(line.s, List outTokens.s())
  ClearList(outTokens())
  line = ReplaceString(MusicStripBars(Trim(line)), Chr(9), " ")
  While FindString(line, "  ", 1)
    line = ReplaceString(line, "  ", " ")
  Wend

  If line = "" : ProcedureReturn 0 : EndIf

  Protected i.i, cnt.i
  cnt = CountString(line, " ") + 1
  For i = 1 To cnt
    Protected tok.s = Trim(StringField(line, i, " "))
    If tok <> ""
      AddElement(outTokens())
      outTokens() = tok
    EndIf
  Next

  ProcedureReturn ListSize(outTokens())
EndProcedure

Procedure.i BuildMusicWavMemory(TrackText.s, *outBytes.Integer, SampleRate.i = 44100)
  ; Track format:
  ;   optional: T=140
  ;   SQ <notes...>
  ;   SQ2 <notes...>
  ;   DR <pattern...>  where 'x' = hit, '-' = rest

  *outBytes\i = 0
  TrackText = ReplaceString(TrackText, #CRLF$, #LF$)
  TrackText = ReplaceString(TrackText, #CR$, #LF$)
  If Trim(TrackText) = "" : ProcedureReturn 0 : EndIf

  Protected tempo.i = 120
  Protected stepsPerBeat.i = 4 ; 16th notes

  Protected NewList leadTokens.s()
  Protected NewList bassTokens.s()
  Protected NewList drumTokens.s()

  Protected lines.i = CountString(TrackText, #LF$) + 1
  Protected li.i
  For li = 1 To lines
    Protected line.s = Trim(StringField(TrackText, li, #LF$))
    If line = "" : Continue : EndIf

    If UCase(Left(line, 2)) = "T="
      tempo = Clamp(Val(Mid(line, 3)), 40, 400)
      Continue
    EndIf

    Protected up.s = UCase(line)
    If Left(up, 3) = "SQ "
      MusicTokenize(Mid(line, 4), leadTokens())
      Continue
    EndIf
    If Left(up, 4) = "SQ2 "
      MusicTokenize(Mid(line, 5), bassTokens())
      Continue
    EndIf
    If Left(up, 3) = "DR "
      MusicTokenize(Mid(line, 4), drumTokens())
      Continue
    EndIf
  Next

  Protected stepCount.i
  stepCount = ListSize(leadTokens())
  If ListSize(bassTokens()) > stepCount
    stepCount = ListSize(bassTokens())
  EndIf
  If ListSize(drumTokens()) > stepCount
    stepCount = ListSize(drumTokens())
  EndIf
  If stepCount <= 0 : ProcedureReturn 0 : EndIf

  Protected stepMS.f = (60000.0 / tempo) / stepsPerBeat
  Protected totalMS.i = Int(stepMS * stepCount)
  If totalMS < 50 : totalMS = 50 : EndIf

  Protected bitsPerSample.i = 16
  Protected channels.i = 1
  Protected bytesPerSample.i = bitsPerSample / 8
  Protected totalSamples.i = (SampleRate * totalMS) / 1000
  If totalSamples < 1 : totalSamples = 1 : EndIf

  Protected dataBytes.i = totalSamples * channels * bytesPerSample
  Protected wavBytes.i = 44 + dataBytes

  Protected *mem = AllocateMemory(wavBytes)
  If *mem = 0 : ProcedureReturn 0 : EndIf

  PokeS(*mem + 0,  "RIFF", 4, #PB_Ascii)
  PokeL(*mem + 4,  wavBytes - 8)
  PokeS(*mem + 8,  "WAVE", 4, #PB_Ascii)
  PokeS(*mem + 12, "fmt ", 4, #PB_Ascii)
  PokeL(*mem + 16, 16)
  PokeW(*mem + 20, 1)
  PokeW(*mem + 22, channels)
  PokeL(*mem + 24, SampleRate)
  PokeL(*mem + 28, SampleRate * channels * bytesPerSample)
  PokeW(*mem + 32, channels * bytesPerSample)
  PokeW(*mem + 34, bitsPerSample)
  PokeS(*mem + 36, "data", 4, #PB_Ascii)
  PokeL(*mem + 40, dataBytes)

  Protected *pcm = *mem + 44

  ; Pre-copy tokens into arrays for fast access.
  Protected Dim lead.s(stepCount - 1)
  Protected Dim bass.s(stepCount - 1)
  Protected Dim drum.s(stepCount - 1)

  Protected idx.i
  idx = 0
  ForEach leadTokens()
    If idx >= stepCount : Break : EndIf
    lead(idx) = leadTokens()
    idx + 1
  Next
  idx = 0
  ForEach bassTokens()
    If idx >= stepCount : Break : EndIf
    bass(idx) = bassTokens()
    idx + 1
  Next
  idx = 0
  ForEach drumTokens()
    If idx >= stepCount : Break : EndIf
    drum(idx) = drumTokens()
    idx + 1
  Next

  Protected leadPhase.f = 0.0
  Protected bassPhase.f = 0.0
  Protected lfsr.i = $ACE1

  Protected sampleIdx.i
  For sampleIdx = 0 To totalSamples - 1
    Protected tMS.f = (sampleIdx * 1000.0) / SampleRate
    Protected stepIdx.i = Int(tMS / stepMS)
    If stepIdx < 0 : stepIdx = 0 : EndIf
    If stepIdx >= stepCount : stepIdx = stepCount - 1 : EndIf
 
    Protected stepTMS.f = tMS - (stepIdx * stepMS)
    Protected env.f = 1.0


    ; Simple per-step envelope to avoid clicks.
    Protected a.f = 3.0
    Protected r.f = 18.0
    If stepTMS < a
      env = stepTMS / a
    ElseIf stepMS - stepTMS < r
      env = ClampF((stepMS - stepTMS) / r, 0.0, 1.0)
    EndIf

    Protected out.f = 0.0

    ; lead voice
    Protected lf.f = NoteToFreq(lead(stepIdx))
    If lf > 0.0
      leadPhase + lf / SampleRate
      leadPhase - Int(leadPhase)
      If leadPhase < 0.5
        out + 0.55
      Else
        out - 0.55
      EndIf
    EndIf

    ; bass/second voice
    Protected bf.f = NoteToFreq(bass(stepIdx))
    If bf > 0.0
      bassPhase + bf / SampleRate
      bassPhase - Int(bassPhase)
      If bassPhase < 0.5
        out + 0.35
      Else
        out - 0.35
      EndIf
    EndIf

    ; noise drum
    If UCase(drum(stepIdx)) = "X"
      lfsr ! (-(lfsr & 1) & $B400)
      lfsr >> 1
      Protected nz.f = -1.0
      If (lfsr & 1) <> 0 : nz = 1.0 : EndIf
      out + nz * 0.35
    EndIf

    out = out * env

    ; Music master is separate from SFX master.
    Protected v.f = out * ClampF(MusicMasterVol, 0.0, 1.0)
    Protected vi.i = Int(v * 32767.0)
    If vi > 32767 : vi = 32767 : EndIf
    If vi < -32768 : vi = -32768 : EndIf
    PokeW(*pcm + sampleIdx * 2, vi)
  Next

  *outBytes\i = wavBytes
  ProcedureReturn *mem
EndProcedure

Procedure StartBoardMusic(TrackKey.s, TrackText.s)
  MusicReady = SfxReady
  If MusicReady = 0
    StopBoardMusic()
    ProcedureReturn
  EndIf

  TrackKey = UCase(Trim(TrackKey))
  If TrackKey = "" : TrackKey = "(ANON)" : EndIf

  If MusicStarted And MusicCurrentKey = TrackKey And MusicCurrentText = TrackText
    ProcedureReturn
  EndIf

  StopBoardMusic()

  Protected bytes.Integer
  Protected *wav = BuildMusicWavMemory(TrackText, @bytes)
  If *wav = 0 Or bytes\i <= 0
    StopBoardMusic()
    ProcedureReturn
  EndIf

  MusicSoundId = CatchSound(#PB_Any, *wav, bytes\i)
  FreeMemory(*wav)

  If MusicSoundId
    SoundVolume(MusicSoundId, Int(ClampF(MusicMasterVol, 0.0, 1.0) * 100.0))
    PlaySound(MusicSoundId, #PB_Sound_Loop)
    MusicStarted = #True
    MusicCurrentKey = TrackKey
    MusicCurrentText = TrackText
  EndIf
EndProcedure

Procedure RefreshBoardMusicVolume()
  If MusicSoundId <> 0
    SoundVolume(MusicSoundId, Int(ClampF(MusicMasterVol, 0.0, 1.0) * 100.0))
  EndIf
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 36
; FirstLine = 704
; Folding = ---
; EnableXP
; DPIAware