EnableExplicit

XIncludeFile "../engine/gfx/Gfx.pb"
XIncludeFile "../engine/world/World.pb"

DeclareModule DemoScene
  Declare Load()
  Declare RenderUI()
  Declare Unload()
EndDeclareModule

Module DemoScene
  Global g_loaded.i = #False

  Procedure Load()
    If g_loaded
      ProcedureReturn
    EndIf

    g_loaded = #True
    Log::Info("DemoScene loaded")
  EndProcedure

  Procedure RenderUI()
    If g_loaded = #False
      ProcedureReturn
    EndIf

    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      If Gfx::Headless() Or Gfx::Ready() = #False
        ProcedureReturn
      EndIf

      If StartDrawing(ScreenOutput())
        Protected selectedId.i = World::SelectedEntity()
        Protected selectedName.s = World::EntityName(selectedId)

        DrawingMode(#PB_2DDrawing_Transparent)
        DrawText(12, 12, "PB_2DEngine Demo")
        DrawText(12, 30, "Entities: " + Str(World::EntityCount()))
        DrawText(12, 48, "Camera: follows player")
        DrawText(12, 66, "Mouse: Left click retargets player")
        DrawText(12, 84, "E spawn, F save scene")
        DrawText(12, 102, "R/V master volume up/down")
        DrawText(12, 120, "Right click selects, drag moves")
        If selectedId
          DrawText(12, 138, "Selected: " + selectedName + " (#" + Str(selectedId) + ")")
        Else
          DrawText(12, 138, "Selected: none")
        EndIf
        DrawText(12, 156, "Input: Esc quits")
        StopDrawing()
      EndIf
    CompilerEndIf
  EndProcedure

  Procedure Unload()
    If g_loaded = #False
      ProcedureReturn
    EndIf

    g_loaded = #False
    Log::Info("DemoScene unloaded")
  EndProcedure
EndModule
