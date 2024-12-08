﻿;EXAMPLE 2

#StringGadget = 0
#Button = 1
#MyWindow = 0

If OpenWindow(#MyWindow, 100, 150, 450, 200, "", #PB_Window_SystemMenu)
  StringGadget(#StringGadget, 50, 50, 350, 20, "Type here!")
  Repeat
    EventID = WaitWindowEvent()

    Select EventID

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #StringGadget
            ;We can call window API just like a PureBasic command
            ;in this case this API will change the title of the window
            SetWindowText_(WindowID(0), GetGadgetText(#StringGadget))
        EndSelect

    EndSelect

  Until EventID = #PB_Event_CloseWindow
EndIf
End
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 6
; EnableXP
; DPIAware
