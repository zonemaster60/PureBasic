EnableExplicit

XIncludeFile "../core/Log.pb"

DeclareModule Audio
  Declare.i Init()
  Declare Shutdown()

  Declare.i LoadSfx(filename.s)
  Declare PlaySfx(soundId.i)
EndDeclareModule

Module Audio
  Procedure.i Init()
    If InitSound() = 0
      Log::Warn("InitSound failed")
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure Shutdown()
    ; PureBasic cleans up on exit; keep placeholder.
  EndProcedure

  Procedure.i LoadSfx(filename.s)
    Protected id = LoadSound(#PB_Any, filename)
    If id = 0
      Log::Warn("Failed to load sound: " + filename)
    EndIf
    ProcedureReturn id
  EndProcedure

  Procedure PlaySfx(soundId.i)
    If soundId <> 0
      PlaySound(soundId)
    EndIf
  EndProcedure
EndModule
