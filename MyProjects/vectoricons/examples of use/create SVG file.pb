; PB 5.42 LTS

CompilerIf #PB_Compiler_OS <> #PB_OS_Linux
   MessageRequester("Error", "Creating SVG files is supported by PureBasic only on Linux.")
   
CompilerElse   
   
   EnableExplicit
   
   XIncludeFile "../vectoricons.pbi"
   
   Define msg$, file$ = "watch.svg"
   
   ; -- In order to save an icon to an SVG file, pass a valid file name
   ;    as first parameter to the icon procedure of your choice.
   ;    The second parameter will then be ignored.
   
   If VectorIcons::Watch(file$, 0, 256, VectorIcons::#CSS_RoyalBlue,
                         VectorIcons::#CSS_Black, VectorIcons::#CSS_White)
      msg$ = "Icon file '" + file$ + "' created."
   Else
      msg$ = "Couldn't create icon file '" + file$ + "'."
   EndIf
   
   MessageRequester("Result", msg$)
   
CompilerEndIf

; IDE Options = PureBasic 5.51 (Windows - x64)
; Folding = -
; EnableXP
; EnableUser
; EnableExeConstant
; EnableUnicode