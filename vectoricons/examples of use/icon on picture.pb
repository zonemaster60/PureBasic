; PB 5.42 LTS

EnableExplicit

XIncludeFile "../vectoricons.pbi"

; Images
Enumeration
   #ImgCheeseCakes
   #ImgCoffee
EndEnumeration

UseJPEGImageDecoder()
Define.i width, height

If LoadImage(#ImgCheeseCakes, "cheesecakes.jpg") = 0
   MessageRequester("Error", "Couldn't load image.")
   End
EndIf

width  = ImageWidth(#ImgCheeseCakes)
height = ImageHeight(#ImgCheeseCakes)

; -- In order to create an image in memory, pass "" as first
;    parameter to the icon procedure of your choice.
;    The second parameter can be an image number or #PB_Any.

If VectorIcons::HotDrink("", #ImgCoffee, 0.25*height, VectorIcons::#CSS_Black) And
   StartDrawing(ImageOutput(#ImgCheeseCakes))
   
   ; Draw the icon on the background picture
   ; (the background of the icon itself is transparent):
   DrawingMode(#PB_2DDrawing_AlphaBlend)
   DrawImage(ImageID(#ImgCoffee), 0.80*width, 0.75*height)
   
   StopDrawing()
EndIf

If OpenWindow(0, 0, 0, width, height, "Demo") = 0
   MessageRequester("Error", "Couldn't open main window.")
   End   
EndIf
ImageGadget(0, 0, 0, width, height, ImageID(#ImgCheeseCakes))

Repeat
Until WaitWindowEvent() = #PB_Event_CloseWindow

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; EnableUnicode
; EnableXP
; EnableUser