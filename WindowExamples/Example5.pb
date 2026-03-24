;EXAMPLE 5

#StringGadget = 0
#Button = 1
#MyWindow = 0

Global Num.l ; see what we do with this number

Procedure Button_Click()
If Num = 0
  HideGadget(#StringGadget, 1)
  Num = 1
Else
  HideGadget(#StringGadget, 0)
  Num = 0
EndIf

EndProcedure

If OpenWindow(#MyWindow, 100, 150, 450, 200, "", #PB_Window_SystemMenu)
  StringGadget(#StringGadget, 30, 50, 390, 20, "Click the button once to hide me, and twice to make me appear again!")
  ButtonGadget(#Button, 180, 100, 70, 25, "Click Here")
  Repeat
    EventID = WaitWindowEvent()

    Select EventID

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Button
            ;When the gadget receives the event then call a procedure
            Button_Click()
        EndSelect

    EndSelect

  Until EventID = #PB_Event_CloseWindow
EndIf
End

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; Folding = -
; EnableXP
; DPIAware
