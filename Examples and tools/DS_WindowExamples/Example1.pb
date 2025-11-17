;EXAMPLE 1

;Making a window application in PureBasic is easy, just need to understand
;a few easy concepts

;CONSTANTS:

;Constants are used to make readable a code
;Constants are preceded with # and are used to store numeric values so the code will
;be easier to read.
;In this example we create 2 constants to store the ID number that we will
;use for identify the gadgets or controls that we are going to use with our
;application.

#MyStringGadget = 1
#MyButton = 2

;The first step for creating a window in PureBasic is callig the
;OpenWindow() command and sending all the parameters required.
;In this case we give the number 0 as the identifier for our window
;we give the coordinates 100,150 for the left and top position
;of the window
;then give 450 as the Innerwitdh and 200 as innerheight

;The #PB_Window_SystemMenu flag is one of many available (check the help file
;to see the other flags available)
;and then we put the text that will have the window.

If OpenWindow(0, 100, 150, 450, 200, "Test", #PB_Window_SystemMenu)

;Now we will put the gadgets in the window
  StringGadget(#MyStringGadget, 50, 50, 350, 20, "")
  ButtonGadget(#MyButton, 200, 100, 50, 25, "Test")

;and now we will go to a loop to receive any user input
;in this case we will receive when a user pushes a button

  Repeat
    EventID = WaitWindowEvent();we get the windowevent

    Select EventID;we check which window event are we receiving
      Case #PB_Event_Gadget;in case its the event from our gadgets
        Select EventGadget()
          Case #MyButton ; the user click the button
            MessageRequester("button clicked", "hello world", 0)
            SetGadgetText(#MyStringGadget, "button clicked!!");Then we put a text into the string gadget
        EndSelect
    EndSelect

  Until EventID = #PB_Event_CloseWindow;loop until the user decide to close the window
EndIf
End


; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 30
; FirstLine = 28
; EnableXP
; DPIAware
