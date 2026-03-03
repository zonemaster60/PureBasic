; starcomm_sound.pbi
; Sound system: InitSounds, PlaySoundFX, all PlayXxx() wrappers, PlaySoundEffect
; XIncluded from starcomm.pb

Declare StartEngineLoop()
Declare StopEngineLoop()

Procedure InitSounds()
  If gSoundInitialized = 1 : ProcedureReturn : EndIf
  
  InitSound()
  
  Protected altPath.s = AppPath + "sounds" + #PS$
  
  SoundPhaser = LoadSound(#PB_Any, altPath + "phaser.wav")
  SoundTorpedo = LoadSound(#PB_Any, altPath + "torpedo.wav")
  SoundDisruptor = LoadSound(#PB_Any, altPath + "disruptor.wav")
  SoundExplode = LoadSound(#PB_Any, altPath + "explode.wav")
  SoundEngine = LoadSound(#PB_Any, altPath + "engines.wav")
  SoundDock = LoadSound(#PB_Any, altPath + "dock.wav")
  SoundAlarm = LoadSound(#PB_Any, altPath + "alarm.wav")
  SoundWarp = LoadSound(#PB_Any, altPath + "warp.wav")
  SoundScan = LoadSound(#PB_Any, altPath + "scan.wav")
  SoundRadio = LoadSound(#PB_Any, altPath + "radio.wav")
  SoundPress = LoadSound(#PB_Any, altPath + "press.wav")
  SoundSelect = LoadSound(#PB_Any, altPath + "select.wav")
  SoundEngage = LoadSound(#PB_Any, altPath + "engage.wav")
  SoundClapping = LoadSound(#PB_Any, altPath + "clapping.wav")
  
  gSoundInitialized = 1
EndProcedure

Procedure PlaySoundFX(id.i)
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If id = 0 : ProcedureReturn : EndIf
  If IsSound(id)
    Delay(10)
    PlaySound(id)
  EndIf
EndProcedure

; All sound implementations using wav files
Procedure PlayComputerBeep()
  PlaySoundFX(SoundPress)
  Delay(50)
  PlaySoundFX(SoundSelect)
EndProcedure

Procedure PlayLogBeep()
  PlaySoundFX(SoundPress)
EndProcedure

Procedure PlayErrorBeep()
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayPhaserSound()
  PlaySoundFX(SoundPhaser)
EndProcedure

Procedure PlayTorpedoSound()
  PlaySoundFX(SoundTorpedo)
EndProcedure

Procedure PlayDisruptorSound()
  PlaySoundFX(SoundDisruptor)
EndProcedure

Procedure PlayImpactSound()
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayTransportSound()
  PlaySoundFX(SoundRadio)
  Delay(40)
  PlaySoundFX(SoundScan)
EndProcedure

Procedure PlayMiningSound()
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayRedAlert()
  PlaySoundFX(SoundAlarm)
  Delay(100)
  PlaySoundFX(SoundAlarm)
  Delay(100)
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayWeldingSound()
  PlaySoundFX(SoundRadio)
  Delay(30)
  PlaySoundFX(SoundRadio)
  Delay(30)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayDockingSound()
  PlaySoundFX(SoundDock)
EndProcedure

Procedure PlayUndockingSound()
  PlaySoundFX(SoundDock)
  Delay(100)
  PlaySoundFX(SoundEngine)
EndProcedure

Procedure PlayExplosionSound()
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayProbeSound()
  PlaySoundFX(SoundScan)
EndProcedure

Procedure PlayTractorBeamSound()
  PlaySoundFX(SoundRadio)
  Delay(40)
  PlaySoundFX(SoundScan)
  Delay(40)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayCommunicationSound()
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayCrewChatterSound()
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayPlanetKillerSound()
  PlaySoundFX(SoundAlarm)
  Delay(50)
  PlaySoundFX(SoundScan)
  Delay(50)
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayPlanetKillerAttackSound()
  PlaySoundFX(SoundExplode)
  Delay(80)
  PlaySoundFX(SoundExplode)
  Delay(80)
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayEngineSound()
  ; Engine loop now handles all engine sounds
  Global gDocked
  If gDocked = 0
    StartEngineLoop()
  EndIf
EndProcedure

Procedure StartEngineLoop()
  Global gDocked
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If gDocked = 1 : ProcedureReturn : EndIf
  If gEngineLoopChannel > 0
    ProcedureReturn
  EndIf
  If SoundEngine And IsSound(SoundEngine)
    gEngineLoopChannel = PlaySound(SoundEngine, #PB_Sound_Loop)
    If gEngineLoopChannel = 0
      gEngineLoopChannel = -1
    EndIf
  EndIf
EndProcedure

Procedure StopEngineLoop()
  If gEngineLoopChannel > 0
    StopSound(gEngineLoopChannel)
  EndIf
  gEngineLoopChannel = -1
EndProcedure

Procedure PlayAmbientChatter()
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If Random(100) < 15 : PlaySoundFX(SoundRadio) : EndIf
EndProcedure

Procedure PlayBeepTest()
  PlaySoundFX(SoundSelect)
  Delay(100)
  PlaySoundFX(SoundEngage)
  Delay(100)
  PlaySoundFX(SoundPress)
EndProcedure

Procedure PlaySoundEffect(n.s)
  Select UCase(n)
    Case "COMPUTER": PlayComputerBeep()
    Case "LOG": PlayLogBeep()
    Case "ERROR": PlayErrorBeep()
    Case "PHASER": PlayPhaserSound()
    Case "TORPEDO": PlayTorpedoSound()
    Case "IMPACT": PlayImpactSound()
    Case "TRANSPORT": PlayTransportSound()
    Case "MINING": PlayMiningSound()
    Case "REDALERT": PlayRedAlert()
    Case "WELDING": PlayWeldingSound()
    Case "DOCKING": PlayDockingSound()
    Case "UNDOCKING": PlayUndockingSound()
    Case "EXPLOSION": PlayExplosionSound()
    Case "PROBE": PlayProbeSound()
    Case "TRACTOR": PlayTractorBeamSound()
    Case "COMM": PlayCommunicationSound()
    Case "CHATTER": PlayCrewChatterSound()
    Case "PLANETKILLER": PlayPlanetKillerSound()
    Case "PKATTACK": PlayPlanetKillerAttackSound()
    Case "ENGINE": PlayEngineSound()
  EndSelect
EndProcedure
