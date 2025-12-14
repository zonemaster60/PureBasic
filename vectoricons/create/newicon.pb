; PB 5.40+, cross-platform

EnableExplicit

XIncludeFile "../vectoricons.pbi"

#Background = #PB_Image_Transparent
; #Background = $00FFFF              ; Use this (yellow) or any other RGB color for debugging,
                                     ; so that you can see the borders of your icon.

Macro StartVectorIconOutput (_file_, _img_, _size_)
   VDraw::StartNewVectorImage(_img_, _size_, _size_, 32, #Background)
EndMacro


;----------------------------------------------------------------------------------
; Use the following procedure as template for your own icon procedure.

Procedure.i MyIcon (file$, img.i, size.i, color.i)
   ; in : file$: name of SVG file which is to be created (only supported on Linux),
   ;             or "" for creating an image in memory
   ;      img  : number of the image which is to be created, or #PB_Any
   ;      size : width and height (number of pixels)
   ;      color: foreground color
   ; out: return value: if img = #Pb_Any --> number of the created image,
   ;                    on error --> 0
   ; [by <your name>]
   Protected ret.i, hw.d, d.d
   
   hw = size / 14.0
   d = size / 10.0
   
   ret = StartVectorIconOutput(file$, img, size)
   
   If ret
      MovePathCursor(     hw, hw+d)
      AddPathLine   (size-hw, size-hw)
      AddPathLine   (   hw+d, hw)
      ClosePath()
      
      MovePathCursor(3.0*hw  , size-hw-d)
      AddPathLine   ( size-hw, 3.0*hw)
      AddPathLine   (3.0*hw+d, size-hw)
      ClosePath()
      
      VectorSourceColor(color)
      StrokePath(2.0 * hw, #PB_Path_RoundCorner)
      
      StopVectorDrawing()
   EndIf
   
   ProcedureReturn ret
EndProcedure
;----------------------------------------------------------------------------------


Procedure ShowIcons (sizes$="16,24,32,48,256")
   Protected.i iconCount, img, size, offset, btnExit, winWidth, winHeight, height=0
   
   iconCount = CountString(sizes$, ",") + 1
   
   ; -- Create icons
   For img = 0 To iconCount-1
      size = Val(StringField(sizes$, img+1, ","))
      MyIcon("", img, size, VectorIcons::#VI_GuardsmanRed)
   Next
   
   ; -- Open main window
   For img = 0 To iconCount-1
      winWidth + ImageWidth(img) + 20
      If height < ImageHeight(img)
         height = ImageHeight(img)
      EndIf   
   Next   
   
   winHeight = height + 70
   
   If OpenWindow(0, 0, 0, winWidth, winHeight, "My icon",
                 #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered) = 0
      MessageRequester("Fatal error", "Can't open main window.")
      End
   EndIf   
   
   offset = 10
   For img = 0 To iconCount-1
      ImageGadget(#PB_Any, offset, 10, ImageWidth(img), ImageHeight(img), ImageID(img))
      offset + ImageWidth(img) + 20
   Next
   
   btnExit = ButtonGadget(#PB_Any, winWidth-70, winHeight-40, 60, 30, "Exit")
   
   ; -- Event loop
   Repeat
      Select WaitWindowEvent()
         Case #PB_Event_Gadget
            Select EventGadget()
               Case btnExit
                  Break
            EndSelect
            
         Case #PB_Event_CloseWindow
            Break
      EndSelect
   ForEver
EndProcedure


ShowIcons()

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; Folding = -
; EnableXP
; EnableUser
; DisableDebugger
; EnableExeConstant
; EnableUnicode