; PB 5.42 LTS

EnableExplicit

XIncludeFile "../vectoricons.pbi"

; Images
Enumeration
   #ImgWatch
EndEnumeration

UsePNGImageEncoder()
Define msg$, file$ = "watch.png"

msg$ = "Couldn't create icon file '" + file$ + "'."

; -- In order to create an image in memory, pass "" as first
;    parameter to the icon procedure of your choice.
;    The second parameter can be an image number or #PB_Any.

If VectorIcons::Watch("", #ImgWatch, 256, VectorIcons::#CSS_RoyalBlue,
                      VectorIcons::#CSS_Black, VectorIcons::#CSS_White)
   If SaveImage(#ImgWatch, file$, #PB_ImagePlugin_PNG)
      FreeImage(#ImgWatch)
      msg$ = "Icon file '" + file$ + "' created."
   EndIf   
EndIf

MessageRequester("Result", msg$)

; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; EnableUnicode
; EnableXP
; EnableUser