;EXAMPLE 4

#StringGadget = 0
#Button = 1
#MyWindow = 0


Procedure Button_Click()
;Now we will make the string gadget appear when the button is clicked
StringGadget(#StringGadget, 50, 50, 350, 20, "When the button is clicked, then I appear!!")
EndProcedure

If OpenWindow(#MyWindow, 100, 150, 450, 200, "", #PB_Window_SystemMenu)
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
