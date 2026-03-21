DeclareModule Audio
  Declare.i Init()
  Declare Shutdown()
EndDeclareModule

Module Audio
  Procedure.i Init()
    If InitSound() = 0
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure Shutdown()
    ; Clean up sounds here if needed
  EndProcedure
EndModule
