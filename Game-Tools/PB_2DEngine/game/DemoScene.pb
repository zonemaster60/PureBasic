DeclareModule DemoScene
  Declare Load()
  Declare RenderUI()
  Declare Unload()
EndDeclareModule

Module DemoScene
  Procedure Load()
    Log::Info("DemoScene loaded")
  EndProcedure

  Procedure RenderUI()
    ; UI Rendering logic here
  EndProcedure

  Procedure Unload()
    Log::Info("DemoScene unloaded")
  EndProcedure
EndModule
