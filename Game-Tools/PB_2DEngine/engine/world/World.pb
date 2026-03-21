XIncludeFile "../core/Log.pb"

DeclareModule World
  Declare Init()
  Declare Update(dt.f)
  Declare Render(alpha.f)
  Declare Shutdown()
EndDeclareModule

Module World
  Procedure Init()
    Log::Info("World initialized")
  EndProcedure

  Procedure Update(dt.f)
    ; Update logic here
  EndProcedure

  Procedure Render(alpha.f)
    ; Render world here
  EndProcedure

  Procedure Shutdown()
    Log::Info("World shut down")
  EndProcedure
EndModule
