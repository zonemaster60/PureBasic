; ====================================
; Name:    KnobGadget
; Version: 1.02
; Author:  RichardL
; Date:    5th June 2013
; OS:      Windows
; PB ver.: 5.11
; License: Free
; ====================================
;{ Release info...
; 0.90 First release version

; 0.91 Added poor man's anti-aliasing to backdrop
;      Improved Font specification
;      Improved radial markers... rather nice!
;      Added flag bit to control 'heat ring'
;      Demo includes slaving two knobs.

; 0.92 4th June 2013 
;      Added 'jazzy' knob top with control bit in flag
;      Added frame option with control bit in flag
;      Added frame border options
;      Improved scaling and caption positioning4

; 1.00 5th June 2013
;      Modified control range. Knob 300 degrees = 16383 'clicks'
;      Demo shows how to apply small steps with MouseWheel
;        Mouse wheel UP   - Fine adjust 1 clicks per mouse increment
;        Mouse wheel DOWN - COARSE adjust 20 clicks per mouse increment

;      Now code is an IncludeFile() (=.PBI) but the demo code is automatically
;      compiled if this file is compiled on its own for testing, thanks to
;                 <<< CompilerIf #PB_Compiler_IsMainFile >>>

; 1.01 23rd June 2013 (505)
;      Fixed benign bug with \KnobRate
;      Added flag bit and code to create a borderless version
;      Modified demo to show all flag options
;      Code version 05 as I'm changing the input syntax and other things 
;      to allow Max and Min like a ScrollBar().
;      Added #MultiTurn1 flag. Knob goes round with mouse but 'span'
;      is spread over 'N' revolutions.

; 1.02 8th July 2013 (542)
;     Added #SWITCHKNOB - Knob clicks to one of 'N' positions.
;     Added #PLAINKKNOB - No Graduations or RING_Heat... good for SWITCH version.

; Things to do someday...
;      Caption update so knob value can be shown... in user units.
;      MULTITURN2 style of knob
;}
;{ Useful references
; http://msdn.microsoft.com/en-us/library/windows/desktop/ms644931(v=vs.85).aspx
; http://www.purebasic.fr/english/viewtopic.php?f=12&T=54117&p=409390&hilit=Meter+Gadget#p409390
;}
;{ Procedure declarations
Declare SetKnobState(gadNum,Value.F=0) ; Value 0 to 16383
Declare GetKnobState(gadNum)
;}
;{ Structures, constants etc
Enumeration ; Flag constants
  
  #POTKNOB      = %000000001
  #MULTITURN1   = %000000010 ; ** See note
  #MULTITURN2   = %000000100 ; ** See note
  #SWITCHKNOB   = %000001000
  #PLAINKKNOB   = %000010000  
  
  #RING_Heat    = %000100000
  #FRAME_Switch = %001000000
  #JAZZ_top     = %010000000
  #BORDER       = %100000000
  
EndEnumeration
; Where N is the 'gearing rate'
; ** MULTITURN1 - Knob tracks mouse and value increase by 1/Number of turns
;    MULTITURN2 - Knob rotates at Rate/N

Structure KNOBTYPE
  width.i               ; Knob gadget width - INSIDE FRAME
  height.i              ; knob height
  KnobImage.i           ; Image that has the knob background.. NOT the pointer
  CanvasID.i            ; Gadget number
  CentreX.i             ; Knob co-ords within the gadget
  CentreY.i
  BackColour.i  
  FrameColourInner.i
  FrameColourOuter.i
  KnobRad.i             ; Radius of knob
  KnobColour.i
  ScaleColour.i         ; Radial lines around knob
  Caption.s             ; Knob caption
  CaptionColour.i       ; and the colour
  DotColour.i           ; The 'pointer' dot and line on top of knob
  LastDotX.i            ; Position of dot 
  LastDotY.i
  Position.F            ; Knob value, returned with GetKnobState(GadNum) or via callback
  Gate.i
  KnobMin.i
  KnobMax.i
  KnobRate.F
  KnobTurns.i
  LastF.F
  flags.i               ; Bitwise option flags...
  CaptionFont.s         ; Use this font for knob caption
  CaptionFontHt.i       ; with this height.
EndStructure

Structure KNOBDEFAULTS
  KnobMax.i 
  KnobMin.i
  KnobRate.F
  KnobTurns.i
  BackColour.i
  ScaleColour.i
  KnobColour.i
  DotColour.i
  CaptionColour.i
  CaptionFont.s
  CaptionFontHt.i
  Caption.s
  FrameColourInner.i
  FrameColourOuter.i
EndStructure

#PBM_KNOB = #WM_APP + 1 ; Application specific callback value
#Scale = 3              ; Scaling factor for the 'poor man's anti-aliasing)

Global KnobDefaults.KNOBDEFAULTS
Global Dim Knob.KNOBTYPE(1)
Global NewList KnobList.i()

; Default knob parameters... 
; SOME may be adjusted BEFORE a knob is created.

With KnobDefaults
  ; These values can be programmed directly or with the procedures
  ; provided.
  \BackColour    = GetSysColor_(#COLOR_BTNFACE) ; Background
  \ScaleColour   = #Black                       ; Scale
  \KnobColour    = #Black                       ; Knob body
  \DotColour     = #Red                         ; Dot and line
  \CaptionColour = #Cyan                        ; Caption
  \FrameColourInner = #Green                    ; Frame 1
  \FrameColourOuter = #White                    ; Frame 2
  \CaptionFont   = "CourierNew"                 ; Caption font
  \CaptionFontHt = 12                           ; Caption font size
  \KnobTurns     = 1                            ; Rotations for for multi-turn
  \Caption       = "Test Knob"
  
  ; Leave alone...
  \KnobMin       = 0
  \KnobMax       = 16383
  \KnobRate      = (\KnobMax - \KnobMin)/300
  
EndWith
;}
Procedure SetGadgetMouseXY(Win,Gadget,MX,MY)
  ; http://msdn.microsoft.com/en-us/library/windows/desktop/ms633516(v=vs.85).aspx
  
  ; Position mouse pointer at specified co-ordinated within a gadget
  Static OldWin = -1
  Static XFix
  Static YFix
   
  ; Get the corrections needed to take account of borders, titles and menus
  If  Win <> OldWin
    
    wi.WINDOWINFO\cbSize = SizeOf(wi)
    GetWindowInfo_(WindowID(Win),wi)
    
    ; Get width of border + title + Menu
    YFix = wi\rcClient\top - wi\rcWindow\top
    XFix = wi\cxWindowBorders
    
    OldWin = Win
  EndIf
  
  MX + WindowX(Win)+GadgetX(Gadget) + XFix
  MY + WindowY(Win)+GadgetY(Gadget) + YFix     
  SetCursorPos_(MX,MY)
  
EndProcedure

Procedure SetKnobBackgroundColour(C = $808080)
  KnobDefaults\BackColour = C
EndProcedure

Procedure SetKnobScaleColour(C = #Black)
  KnobDefaults\ScaleColour = C
EndProcedure

Procedure SetKnobColour(C = #Black)
  Shared KnobDefaults
  KnobDefaults\KnobColour = C
EndProcedure

Procedure SetKnobDotColour(C = #Red)
  KnobDefaults\DotColour = C 
EndProcedure

Procedure SetKnobCaptionColour(C = #Cyan)
  KnobDefaults\CaptionColour = C
EndProcedure

Procedure SetKnobCaptionFont(S.s,ch.i)
  KnobDefaults\CaptionFont   = S
  KnobDefaults\CaptionFontHt = ch
EndProcedure

Procedure SetKnobFrameColours(i.i,o.i)
  KnobDefaults\FrameColourInner  = i
  KnobDefaults\FrameColourOuter  = o
EndProcedure

Procedure SetKnobMultiTurn(i.i)
  KnobDefaults\KnobTurns = i
EndProcedure

Procedure SetKnobState(gadNum,Value.F=0) ; Value in range KnobMin to KnobMax
  Protected n,T,X,Y,Index.i = 0, Result.i = 0
  
  ; Locate specified knob in list
  n=1 : Index = 0
  ForEach KnobList()
    If KnobList() = gadNum
      Index = n    ; 1...
      Break
    EndIf
    n+1
  Next 
  
  If Index = 0
    ProcedureReturn #False
  EndIf  
  
  With Knob(Index)
    ; Check for out-of-range values
    If Value < \KnobMin : Value = \KnobMin : EndIf
    If Value > \KnobMax : Value = \KnobMax : EndIf 
    
    ; Save the user provided value for this knob
    \Position = Value 
    
    ; Send callback message
    SendMessage_(WindowID(GetActiveWindow()),#PBM_KNOB,Value,GadgetID(gadNum))
    
    ; Re-draw the knob cap and pointer
    ; Convert user value to first circle degrees (This works for single
    ; and multi-turn pots.)
    Value - \KnobMin
    Value / \KnobRate                            ; 0..3x0 degrees
    While Value > 360 : Value - 360 : Wend       ; '%' cannot be used with FLOAT values
    
    ; Angle of pointer 
    If \flags & #MULTITURN1
      T = Value + 180
      T = 360-T
    Else
      T = -(Value + 30) 
    EndIf
     
    If StartDrawing(CanvasOutput(\CanvasID))
        DrawImage(ImageID(\KnobImage),0,0)       ; Draw the knob backdrop
        
        X = \CentreX + (\KnobRad*Sin(Radian(T))) ; End of pointer X
        Y = \CentreY + (\KnobRad*Cos(Radian(T))) ; End of pointer Y
        
        If \flags & #JAZZ_top 
          ; Draw jazzy knob top and pointer
          DrawingMode(#PB_2DDrawing_Gradient)      
          BackColor(\KnobColour)
          FrontColor(\DotColour)
          ConicalGradient(\CentreX,\CentreY, T-90)     
          Circle(\CentreX,\CentreY,\KnobRad)
          Circle(X,Y,\KnobRad>>3,\DotColour)     ; Pointer dot
        Else  
          ; Draw standard knob top with line and pointer dot
          LineXY(\CentreX,\CentreY,X,Y,\DotColour)
          Circle(X,Y,\KnobRad>>3,\DotColour)
        EndIf
        
        ; Draw dynamic caption on SWITCH... 
        ; (Will need FONT data)
        If \flags & #SWITCHKNOB
          If FindString(\Caption,"|")
            DrawingMode(#PB_2DDrawing_Transparent)
            k$ = StringField(\Caption,\Position-\KnobMin+1,"|")
            DrawText((\width-TextWidth(k$))/2,\width-8,k$,\CaptionColour)
          EndIf
        EndIf
        
        ; Keep pointer position etc for readout / next time
        \LastDotX = X : \LastDotY = Y
               
        Result = #True
      StopDrawing()
       
    EndIf
  EndWith
   
  ProcedureReturn Result
EndProcedure

Procedure GetKnobState(gadNum)
  Protected n,Result
  n=1
  ForEach KnobList()
    If KnobList() = gadNum
      Result = Knob(n)\Position
      Break
    EndIf
    n+1
  Next
  ProcedureReturn Result
EndProcedure

Procedure KnobService(Gad)
  ; Here because the user pressed left mouse button while over a KnobGadget()
  Protected n.i, Index.i, X.i, Y.i, F.F, dx.F, dy.F,T.i, dF.F,  Span.i, MyFont
  Static S.F 
  
  ; Search list for the KnobGadget() 
  n=1 : Index = 0
  ForEach KnobList()
    If KnobList() = Gad
      Index = n         ; 1...
      Break
    EndIf
    n+1
  Next
  If Index = 0
    ProcedureReturn #False
  EndIf
  
  ; Mini event manager - Just while dragging the knob pointer
  With Knob(Index)
    ; Move mouse pointer to last position used. (This prevents the knob
    ; from jumping to a random place when the mouse button is first pressed.)
    SetGadgetMouseXY(GetActiveWindow(),\CanvasID,\LastDotX,\LastDotY)
    
    Repeat
      WaitWindowEvent(20)
      
      ; Finish when user releases the mouse button
      If EventType() = #PB_EventType_LeftButtonUp
        Break 
      EndIf
      
      X = GetGadgetAttribute(Gad,#PB_Canvas_MouseX)
      Y = GetGadgetAttribute(Gad,#PB_Canvas_MouseY)
      
      If X 
        ; Correct X and Y for framed version of knob
        If (\flags & #BORDER )
          Y -2  : X - 2 
        EndIf
        
        ; Calculate angle of mouse relative to knob centre in Degrees
        dx = X - \CentreX 
        dy = Y - \CentreY
        F  = Degree(ATan2(dx,dy))
        If     \flags & (#POTKNOB | #SWITCHKNOB) ;{ Potentiometer and Switch knobs
          If F < 0 : F = 360 + F : EndIf
          F + 240                  ; Offset because pot's '0' is not at cardinal point
          If F>360 : F-360 : EndIf ; Circular wrap around?
          If F>302 : F=0   : EndIf ; Potentiometers have 300 degree travel.
          
          ; Convert degrees of rotation to User value
          F * \KnobRate
          F + \KnobMin
          
          ; Limit the range
          If F < \KnobMin : F = \KnobMin : EndIf
          If F > \KnobMax : F = \KnobMax : EndIf
         
          ; Limit steps size and also force dead-band at bottom. Neat :-)
          If Abs(F - \Position) < (60 * \KnobRate)
            SetKnobState(Gad, Round (F,#PB_Round_Nearest))
          EndIf
          ;}
        ElseIf \flags & #MULTITURN1  ;{ MULTITURN1 - Knob tracks mouse and value increase by 1/\Turns
          ; (There must be a neater way!!!)
          
          F + 90                                    ; Move '0' to top.
          If F < 0 : F=360+F : EndIf                ; Roll-over correction
          
          ; Calculate knob revolution... so far
          Span = (\KnobMax  - \KnobMin)/ \KnobTurns ; Clicks per revolution
          Turn = Int((\Position - \KnobMin)/Span)   ; Completed turns of knob 
          
          ; Detect mouse passing through 'Top Dead Centre' (=TDC) and adjust 'Turns'
          S = F -\LastF                             ; Movement since last time
          \LastF = F
          
          If Abs(S) > 320                           ; 0=>360 or 360=>0
            ; Manage TDC transitions for first, last and in-between turns.
            ; (\Gate: 0 = free to move up or down, -1 = Jammed at min, +1 = Jammed at max)
            Select \Gate
              Case 1 ; Can only decrease...
                If Sign(S) <> -1
                  Turn = \KnobTurns - 1
                  F    = 359
                  \Gate = 0
                EndIf
              Case -1 ; Can only increase...
                If Sign(S) <> 1
                  Turn = 0
                  F    = 1
                  \Gate = 0
                EndIf
              Case 0 ; Can move up or down...
                If Sign(S)=  1 And Turn = 0            :\Gate = -1: EndIf ; Reached min?
                If Sign(S)= -1 And Turn = \KnobTurns-1 :\Gate =  1: EndIf ; Reached max?
                If \Gate  = 0 : Turn - Sign(S) : EndIf                    ; Free to move...
            EndSelect
          EndIf 
          
          ; Convert knob angle to control clicks and update display
          If \Gate = 0
            F * \KnobRate                           ; Degrees => 'Clicks'
            F + (Turn * Span)                       ; Add 'Clicks' for turns 
            F + \KnobMin       
            SetKnobState(Gad,Round(F,#PB_Round_Nearest))
          EndIf
          ;}
        EndIf
        
      EndIf
    ForEver
  EndWith
EndProcedure
Procedure KnobGadget(gadNum.i, X.i, Y.i, Size.i,Caption.s = "", KnobMin.i= 0, KnobMax.i = 10000, flags.i = 0)
   
  Protected Result.i, w.i, h.i, dx.F, dy.F, cx.F, cy.F
  Static KnobCount = 1
  
  w = Size
  h = Size 
  If Caption
    h + KnobDefaults\CaptionFontHt+2
  EndIf
 
  T = #PB_Canvas_ClipMouse|#PB_Canvas_Keyboard|#PB_Canvas_DrawFocus
  If (flags & #BORDER) 
    T | #PB_Canvas_Border
  EndIf
  
  Result = CanvasGadget(gadNum, X, Y, w, h,T)
  
  If Result <> 0
    
    If gadNum = #PB_Any : gadNum = Result : EndIf
    If KnobCount > 1 : ReDim Knob(KnobCount) : EndIf
     
    With Knob(KnobCount)
      \CanvasID = gadNum
      \width  = w 
      \height = h 
      If (flags & #BORDER)
        \width - 4  : \height - 4
      EndIf   
      
      \KnobImage = CreateImage(#PB_Any,\width*#Scale,\height*#Scale)
      \CentreX  = \width >> 1
      \CentreY  = \width >> 1  
      
      \KnobRad  = \width >> 2
      If flags & #PLAINKKNOB
        \KnobRad  = \width>>1 - \width>>3
      EndIf
       
      \Caption  = Caption
      \flags    = flags
      \KnobMin  = KnobMin 
      \KnobMax  = KnobMax
      \Position = KnobMin
      
      If \flags & #MULTITURN1
        \KnobTurns = KnobDefaults\KnobTurns
        \KnobRate  = (\KnobMax - \KnobMin) / (360 * \KnobTurns) ; 'Clicks' per degree
      ElseIf \flags & #SWITCHKNOB
        \KnobTurns = 1
        \KnobRate  = (\KnobMax - \KnobMin) / 300 ; 'Clicks' per SWITCH STEP
      Else
        \KnobTurns = 1 ; Pots and switches always 1
        \KnobRate   = (\KnobMax - \KnobMin) / 300
      EndIf
      
      \KnobColour       = KnobDefaults\KnobColour
      \BackColour       = KnobDefaults\BackColour
      \ScaleColour      = KnobDefaults\ScaleColour
      \CaptionColour    = KnobDefaults\CaptionColour
      \CaptionFont      = KnobDefaults\CaptionFont
      \CaptionFontHt    = KnobDefaults\CaptionFontHt
      \DotColour        = KnobDefaults\DotColour
      \FrameColourInner = KnobDefaults\FrameColourInner
      \FrameColourOuter = KnobDefaults\FrameColourOuter
      
      MyFont = LoadFont(#PB_Any,\CaptionFont,\CaptionFontHt * #Scale)
      
      StartDrawing(ImageOutput(\KnobImage))
        DrawingFont(FontID(MyFont))
        
        ; Backdrop
        Box(0,0,\width*#Scale,\height*#Scale,\BackColour)
        
        ; Optional border
        If flags & #FRAME_Switch
          n = 1 : R = 12
          RoundBox(n*#Scale, n*#Scale,(\width-(2*n))*#Scale,(\height-(2*n))*#Scale,R*#Scale,R*#Scale,\FrameColourInner)
          n = 4 : R = 09
          RoundBox(n*#Scale, n*#Scale,(\width-(2*n))*#Scale,(\height-(2*n))*#Scale,R*#Scale,R*#Scale,\FrameColourOuter)
          n = 7 : R = 06
          RoundBox(n*#Scale, n*#Scale,(\width-(2*n))*#Scale,(\height-(2*n))*#Scale,R*#Scale,R*#Scale,\BackColour)
        EndIf
        
        ; Radial markers 
        If Not(flags & #PLAINKKNOB)
          R = (\width>>1 - \width>>4 ) * #Scale          ; Radius of marker lines
          A = 30
          B = 330
          S = 30
          
          If flags & #MULTITURN1 : B = 360 : EndIf
          
          If flags & #SWITCHKNOB
            A = 30
            B = 330
            S = (B - A) / (\KnobMax - \KnobMin)
          EndIf
          
          T = A
          Repeat
            X     = \CentreX*#Scale + (R*Sin(Radian(T))) ; End of pointer X
            Y     = \CentreY*#Scale + (R*Cos(Radian(T))) ; End of pointer Y
            cx    = \CentreX*#Scale                     
            cy    = \CentreY*#Scale                     
            
            ; Draw several adjacent lines to create a single thick one.
            For n = -5 To 5
              dx = n * Cos(Radian(T)) : dy = n * Sin(Radian(T))
              LineXY(cx+dx, cy-dy, X+dx, Y-dy, \ScaleColour)
            Next
            
            T + S
          Until T > B
        EndIf  
        
        ; Optional coloured ring around the knob
        If flags & #RING_Heat
          DrawingMode(#PB_2DDrawing_Gradient)  
          BackColor( $000000)
          GradientColor(0.2,#Black)
          GradientColor(0.5, $00FFFF)
          FrontColor($0000FF)
          
          ConicalGradient(\CentreX*#Scale,\CentreY*#Scale, 300)     
          Circle(\CentreX*#Scale,\CentreY*#Scale,(\KnobRad+\width>>4-1)*#Scale)
          DrawingMode(#PB_2DDrawing_Default )
        Else
          ; Normal - just clear the radial markers
          Circle(\CentreX*#Scale,\CentreY*#Scale,(\KnobRad+\width>>4-1)*#Scale,\BackColour)
        EndIf
        
        ; Draw the top of the knob
        Circle(\CentreX*#Scale,\CentreY*#Scale,\KnobRad*#Scale,\KnobColour)
        
        ; Draw the caption
        DrawingFont(FontID(MyFont))
        DrawingMode(#PB_2DDrawing_Transparent)
        If Not(\flags & #SWITCHKNOB And CountString(\Caption,"|"))
          X = (#Scale*\width - TextWidth(\Caption))/2
          DrawText(X,#Scale*(\width-12),\Caption,\CaptionColour)
        EndIf
        
      StopDrawing()
      FreeFont(MyFont)
      
      ResizeImage(\KnobImage,\width,\height)
      
      StartDrawing(CanvasOutput(\CanvasID))
        DrawImage(ImageID(\KnobImage),0,0)
      StopDrawing() 
      SetGadgetAttribute(\CanvasID,#PB_Canvas_Cursor,#PB_Cursor_Hand)
    
    EndWith
    
    AddElement(KnobList())
    KnobList() = gadNum
    SetKnobState(gadNum,0)
    
    KnobCount + 1
    
  EndIf
  
  ProcedureReturn gadNum
EndProcedure

CompilerIf #PB_Compiler_IsMainFile
  ; *************************************
  ;            Test code
  ;{ *************************************
  Enumeration 1000 ; Define Window, gadget numbers etc...
    #Win_Main
    
    #Gad_Knob1    ; It is helpful to have the knobes grouped
    #Gad_Knob2    ; together
    #Gad_Knob3
    
    #Gad_Knob4
    #Gad_Knob5
    #Gad_Knob6
    #Gad_Knob7
    #Gad_Knob8
    #Gad_Knob9
    #Gad_Knob10
    #Gad_Knob11
    #Gad_Knob12
    #Gad_Knob13
    #Gad_Knob14
    
    #Gad_Text1
    #Gad_Text2
    #Gad_Text3
    #Gad_Text4
    #Gad_Text5
    
    ; More here
  EndEnumeration
  Procedure WinCallback(hwnd, uMsg, wParam, lParam) ; Standard PB Windows callback...
    
    Select uMsg  
     
      Case #PBM_KNOB   ; Receiving Knob() messages in 'real time'
        Select lParam
          Case GadgetID(#Gad_Knob1) : SetGadgetText(#Gad_Text1, "Knob1 = "+Str(wParam))
          Case GadgetID(#Gad_Knob2) : SetGadgetText(#Gad_Text2, "Knob2 = "+Str(wParam))
          Case GadgetID(#Gad_Knob3) : SetGadgetText(#Gad_Text3, "Knob3 = "+Str(wParam))
          Case GadgetID(#Gad_Knob12): SetGadgetText(#Gad_Text4, "Knob4 = "+Str(wParam))
          Case GadgetID(#Gad_Knob14): SetGadgetText(#Gad_Text5, "Switch 14 = "+Str(wParam))
                       
          ; Good place to check Get/SetKnobState()  
           Case GadgetID(#Gad_Knob4) : SetKnobState(#Gad_Knob8,GetKnobState(#Gad_Knob4)) ; Slave two knobs... one way, 4=>8
        EndSelect
        
        ; etc
        ; etc
        
    EndSelect
    
    ProcedureReturn #PB_ProcessPureBasicEvents 
    
  EndProcedure
  
  OpenWindow(#Win_Main,0,0,900,450,"Knob test Rev 1.02",#PB_Window_ScreenCentered|#PB_Window_SystemMenu)
  
  ; User defined default values
  SetKnobScaleColour(#White)
  SetKnobColour(#Black)
  SetKnobDotColour(#Red)
  SetKnobCaptionColour(#White)
  SetKnobCaptionFont("CourierNew",18)
  
  ; *************** Create Knobs ****************
  ; Change values BEFORE creating a Knob
  SetKnobDotColour(#Red)
  KnobGadget(#Gad_Knob1,40,20,150,"TREBLE",0,1000,#POTKNOB | #RING_Heat | #FRAME_Switch) ; Frame and HeatRing
  SetKnobState(#Gad_Knob1,50)
  
  SetKnobScaleColour(#Black)
  SetKnobDotColour(#White)
  SetKnobCaptionColour(#Blue)
  KnobGadget(#Gad_Knob2,195,20,150,"BASS",0,10000,#POTKNOB | %110000000)
  
  SetKnobScaleColour(#Yellow)
  SetKnobDotColour(#Blue)
  SetKnobColour(#Cyan)
  SetKnobCaptionColour(#Red)
  KnobGadget(#Gad_Knob3,350,20,150,"VOLUME",1,42,#POTKNOB | %011100000) 
  
  SetKnobScaleColour(#Black)
  SetKnobDotColour(#White)
  SetKnobColour(#Black)
  SetKnobMultiTurn(4)
  KnobGadget(#Gad_Knob12,510,20,200,"MultiTurn (4T)",100,10000,#MULTITURN1 | %110000000)
  SetKnobState(#Gad_Knob12,1000)
  
  SetKnobDotColour(#Yellow)
  SetKnobCaptionColour(#Blue)
  KnobGadget(#Gad_Knob14,720,20,150,"160M|80M|40M|20M|15M|10M|6M|x7|x8|x9|",10,17,#SWITCHKNOB | #JAZZ_top)
  
  SetKnobDotColour(#White)
  SetKnobCaptionFont("CourierNew",12)
  SetKnobCaptionColour(#White)
  SetKnobBackgroundColour($FFAA55)
  KnobGadget(#Gad_Knob4, 10 ,280,100,"Channel 1",0,10000,#POTKNOB | 8<<5)
  KnobGadget(#Gad_Knob5, 110,280,100,"Channel 2",0,10000,#POTKNOB | 9<<5) 
  KnobGadget(#Gad_Knob6, 220,280,100,"Channel 3",0,10000,#POTKNOB | 2<<5) 
  KnobGadget(#Gad_Knob7, 320,280,100,"Channel 4",0,10000,#POTKNOB | 3<<5) 
  
  SetKnobScaleColour(#Black)
  
  KnobGadget(#Gad_Knob8, 430,280,100,"Channel 5",0,10000,#POTKNOB | 4<<5) 
  KnobGadget(#Gad_Knob9, 530,280,100,"Channel 6",0,10000,#POTKNOB | 5<<5)
  KnobGadget(#Gad_Knob10,640,280,100,"Channel 7",0,10000,#POTKNOB | 6<<5) 
  KnobGadget(#Gad_Knob11,740,280,100,"Channel 8",0,10000,#POTKNOB | 7<<5)
  
  DisableGadget(#Gad_Knob8,#True)
  ; ******************************************** 
  
  ; To show knob values returned from Window callback
  TextGadget(#Gad_Text1,40, 200,150,20,"",#PB_Text_Center)
  TextGadget(#Gad_Text2,190,200,150,20,"",#PB_Text_Center)
  TextGadget(#Gad_Text3,340,200,160,20,"",#PB_Text_Center)
  TextGadget(#Gad_Text4,510,250,200,20,"",#PB_Text_Center)
  TextGadget(#Gad_Text5,720,195,150,15,"",#PB_Text_Center)
  
  ; Optional: Callabck to receive 'real-time' knob messages
  SetWindowCallback(@WinCallback())    
  
  ; Dispatch
  WheelRate.i = 1
  Repeat
    Select WaitWindowEvent(10)
      Case #PB_Event_CloseWindow
        Break
        
      Case #PB_Event_Gadget
        Select EventGadget()
            
            ; KnobGadget() all grouped in order to make coding much easier
          Case #Gad_Knob1 To #Gad_Knob14 
           
            Select EventType()
                
              Case #PB_EventType_LeftButtonDown 
                KnobService(EventGadget())
                
              Case  #PB_EventType_MouseWheel          
                T = GetGadgetAttribute(EventGadget(),#PB_Canvas_WheelDelta)            ; Get mouse delta
                If EventGadget() = #Gad_Knob14 : WheelRate = 1 : EndIf
                SetKnobState(EventGadget(),GetKnobState(EventGadget())+(T * WheelRate))  ; Apply it to Knob
                
              Case #PB_EventType_MiddleButtonDown : WheelRate = 50
              Case #PB_EventType_MiddleButtonUp   : WheelRate = 1
                
            EndSelect
        EndSelect
    EndSelect
    
  ForEver
  ;}
CompilerEndIf

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 753
; FirstLine = 720
; Folding = ----
; EnableXP
; DPIAware