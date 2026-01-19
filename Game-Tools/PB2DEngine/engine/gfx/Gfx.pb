EnableExplicit

XIncludeFile "../core/Log.pb"

DeclareModule Gfx
  Declare.i Init(title.s, width.i, height.i)
  Declare.i InitHeadless(width.i, height.i)
  Declare Shutdown()

  Declare BeginFrame()
  Declare EndFrame()

  Declare.i GetScreenWidth()
  Declare.i GetScreenHeight()

  Declare.i WindowClosed()
EndDeclareModule

Module Gfx
  Global g_window.i
  Global g_width.i
  Global g_height.i
  Global g_closed.i
  Global g_headless.i

  Procedure.i Init(title.s, width.i, height.i)
    If InitSprite() = 0 Or InitKeyboard() = 0 Or InitMouse() = 0
      Log::Error("InitSprite/Keyboard/Mouse failed")
      ProcedureReturn #False
    EndIf

    g_headless = #False
    g_closed = #False

    g_width = width
    g_height = height

    g_window = OpenWindow(#PB_Any, 0, 0, width, height, title, #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
    If g_window = 0
      Log::Error("OpenWindow failed")
      ProcedureReturn #False
    EndIf

    If OpenWindowedScreen(WindowID(g_window), 0, 0, width, height, #False, 0, 0) = 0
      Log::Error("OpenWindowedScreen failed")
      CloseWindow(g_window)
      g_window = 0
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndProcedure

  Procedure.i InitHeadless(width.i, height.i)
    g_headless = #True
    g_width = width
    g_height = height
    g_window = 0
    g_closed = #False
    ProcedureReturn #True
  EndProcedure

  Procedure Shutdown()
    If g_headless
      ProcedureReturn
    EndIf

    If IsWindow(g_window)
      CloseWindow(g_window)
    EndIf
  EndProcedure

  Procedure BeginFrame()
    If g_headless
      ProcedureReturn
    EndIf
    ClearScreen(RGB(20, 20, 24))
  EndProcedure

  Procedure EndFrame()
    If g_headless
      ProcedureReturn
    EndIf

    FlipBuffers()

    If IsWindow(g_window)
      Repeat
        Protected ev = WindowEvent()
        If ev = 0
          Break
        EndIf
        If ev = #PB_Event_CloseWindow
          g_closed = #True
        ElseIf ev = #PB_Event_SizeWindow
          ; NOTE: PB windowed screen doesn't automatically resize backbuffer.
          ; For v0.1 keep logical size constant; render scaling is a later feature.
        EndIf
      ForEver
    EndIf
  EndProcedure

  Procedure.i GetScreenWidth()
    ProcedureReturn g_width
  EndProcedure

  Procedure.i GetScreenHeight()
    ProcedureReturn g_height
  EndProcedure

  Procedure.i WindowClosed()
    ProcedureReturn g_closed
  EndProcedure
EndModule
