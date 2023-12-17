; ****************************************************************
; An investigation into using 'Waveform Audio' for Audio output,
; specifically to produce a stereo tone generator. Then I added
; a 'scope display and an input channel and it became a bit like
; Topsy and just grow'd!

; Status: Works and meets my needs.

; (C) Richard Leman 2013
; Free to copy, use or ignore entirely at your own risk.

; Rev 2.6 - 25th May 2013
; Improved : Single shot trigger .... STILL NOT PERFECT

; Rev 2.7 - (1238)
; Uses KnobGadget.pbi ... see 'Useful References' for source.

; Rev 2.8 - (1277)
; Added StringGadget()s for direct entry of frequencies. (For Slim)
; Freq and Offset StringGadgets() now read after Return is pressed

; --- FOR ANOTHER DAY (Maybe!)
; Better X scaling management
; Switch sampling rate 44100,96000,22k?
; Voltage calibration
; ****************************************************************

CompilerIf Not #PB_Compiler_Thread
  MessageRequester("WARNING!", "Set compiler options: 'Create threadsafe executable'",#PB_MessageRequester_Warning)
  End
CompilerEndIf

XIncludeFile "KnobGadgetDev06.pbi"

;{- Useful references 
; http://www.purebasic.fr/english/viewtopic.php?f=12&t=54793               ; KnobGadgets are here!
; http://msdn.microsoft.com/en-gb/library/windows/desktop/dd743833(v=vs.85).aspx
; http://www.ex-designz.net/apidetail.asp?api_id=531
; http://stilzchen.kfunigraz.ac.at/skripten/comput07/oszi_sound/Mod_sound.bas
;}
;{- Procedure declarations
Declare StartSoundOutput()
Declare StopSoundOutput()
Declare StartSoundInput()
Declare StopSoundInput()
Declare CalcWave(*SBuf,nSamples)
Declare ScopeRefresh(*z)
Declare ShowCursorReport()
Declare WinCallback(hwnd, uMsg, wParam, lParam)
Declare BuildScopeBackdrop(Bn)
;}

;{- Globals and constants
Enumeration  ; Windows, Menus, Gadgets, Hot keys
  ; WINDOWS
  #Win_SNDWin   = 100
  
  ;GADGETS
  #Gad_Backdrop   = 1000
  #Gad_SwitchOut
  #Gad_SwitchIn
  #Gad_TraceASwitch
  #Gad_TraceBSwitch
  #Gad_InvertA
  #Gad_InvertB
  #Gad_AddAB
  #Gad_Scope    
  #Gad_WavL    
  #Gad_WavR    
  #Gad_SwitchL 
  #Gad_SwitchR 
  #Gad_UserFA
  #Gad_UserFB
  
  ; KnobGadgets... Group together
  #Gad_FreqL   
  #Gad_FreqR
  #Gad_VolumeL  
  #Gad_VolumeR  
  
  #Gad_Lock     
  #Gad_LockOfs  
  #Gad_SwitchDF 
  #Gad_SwitchDP 
  #Gad_PlayWAV
  #Gad_CursTimeSwitch
  #Gad_CursVoltSwitch
  #Gad_CursResults
  #Gad_VoltRef
  #Gad_SS_Offset
  #Gad_SSArm
  #Gad_TriggerSelect
  #Gad_TrigSense
  #Gad_Spoof
  
  ; MENU ITEMS
  #Men_OutDevice1 = 2000
  #Men_InDevice1  = 2010
  
  ; Hot keys
  #Key_CntrlC     = 3000
  #Key_CntrlS
  #Key_CntrlP
  #Key_Return
EndEnumeration
Enumeration  ; Things that might be dragged on the 'scope display
  #DragNone
  #DragChanAY
  #DragChanBY
  #DragTime1
  #DragTime2
  #DragVolts1
  #DragVolts2
  #DragTrig
  #DragScreen
EndEnumeration
Enumeration  ; Trigger options
  #TraceA
  #TraceB
  #SingleShotA
  #SingleShotB
  #FreeRun
EndEnumeration

Global Dragging = #DragNone
Global DragX, DragY

Global SampleClock    = 44100 ; Sampling/Replay frequency in 'samples per second' 
Global BlockSize      = 4096  ; Number of samples in capture/play block 
Global BytesPerSample = 2     ; Number of bytes needed for each sample 
Global Channels       = 2     ; Number of channels, 1 for mono, 2 for stereo.
Global DevOut         = 1
Global DevIn          = 1
Global hWaveOut
Global hWaveIn
Global nBuf           = 16
Global LockLR, LockOffset
Global ScopeImage
Global La.f, Ra.f , DoDP, DoDF
Global hWAV

WAVPath$ = "C:\Temp\"

#PIx2 = 2*#PI
#Twiddle = 7  ; How close a click needs to be to a dragable line

; ========================================================
Global PlayFormat.WAVEFORMATEX
Global RecFormat.WAVEFORMATEX
Global MyOutDevs.WAVEOUTCAPS
Global MyInDevs.WAVEINCAPS
Global Dim outHdr.WAVEHDR(nBuf)
Global Dim inHdr.WAVEHDR(nBuf)
Global *InBufMem, *InBufMemEnd  ; Start and end of Input buffer
Global FreeRun = #False         ; Triggered display

Structure Draggable
  Time1X.i
  Time2X.i
  Volts1Y.i
  Volts2Y.i
  Trig.i
  TrigLineTimer.i
  
  ScreenDragX.i
  OldDragX.i
  ScreenDragTotal.i
  
  Volts1Yb4.i
  Volts2Yb4.i
  TrigYb4.i
EndStructure

Global Drag.Draggable

With Drag
  \Time1X    = 20
  \Time2X    = 40
  \Volts1Y   = 50
  \Volts2Y   = 100
  \Trig      = 50
  \TrigLineTimer = ElapsedMilliseconds() + 5000
EndWith 

Structure ScopeDisplay
  width.i
  height.i
  TimeCursorSwitch.i
  VoltsCursorSwitch.i
  PixPermSec.f
  PixPerVolt.f
  Mag.i
  VoltRefIndex.i
  VoltRefDisc$
  ShowInOut.i
  TraceASwitch.i
  TraceBSwitch.i
  Copy.i
  TriggerMode.i
  TriggerModeDisc$
  TrigLevel.w
  TrigSense.i
  
  YPosA.i
  YPosB.i
  SenseA.i
  SenseB.i
  APlusB.i
  
  SSBuffer.i        ; Address of circular store used for storing SS data
  SSBufSize.i       ; Size of SS buffer!
  SSBufferEnd.i     ; Address of end of SS data buffer
  SSMode.i          ; #True when user has selected single shot on ChanA or B.
  SSArm.i           ; #True when user has primed the single shot mode
  SSFired.i         ; #True after the single shot event has occured. Input now blocked.
  SSOffset.i        ; Offset from start of block after Single Shot trigger fired.
  SSPosSlider.i     ; Slider position relative to mid-position... scaled.
  
  DisplayP.i
  DisplayStart.i
  DisplayEnd.i
  DisplayTrig.i
  
EndStructure
Global Scope.ScopeDisplay

With Scope
  \width        = 512
  \height       = 256
  \TimeCursorSwitch.i  = #False
  \VoltsCursorSwitch.i = #False
  \PixPerVolt   = 50     ; This is arbitrary 
  \VoltRefIndex = 0
  \Mag          = 16     ; Actual value = \mag/16. \mag 1 => 256
  \VoltRefDisc$ = "ChanA (Red)|ChanB (Green)|Bottom|Centre|"
  \ShowInOut    = 1                ; 0=Input   1=Output
  \TrigLevel    = 0
  \TriggerMode  = #TraceA
  \TriggerModeDisc$ = "TraceA|TraceB|Single shot A|Single shot B|Free-run|"
  \TraceASwitch = #True
  \TraceBSwitch = #True
  \SSMode       = #False
  \SSArm        = #False
  \SenseA       = -1     ; True/Invert -1 / +1
  \SenseB       = -1
  \APlusB       = 0
  \TrigSense    = 1       ; Pos/Neg  +1 / -1
EndWith

Structure Waves
  WaveForm.i
  Frequency.i
  Volume.f
  Switch.i
  DatumImage.i
  ModMode.i
  ModDisc$
EndStructure
Global ChanA.Waves
Global ChanB.Waves

Enumeration
  #ModOff
  #ModAM 
  #ModFM 
EndEnumeration

; Initial signal generator frequencies etc
With ChanA                ; 300 Hz Sinewave on ChanA, On
  \Frequency = 300
  \Volume    = 0.3
  \Switch    = #True
  \WaveForm  = 0
  \ModMode   = #ModFM 
  \ModDisc$  = "CW|AM|FM|"
EndWith
With ChanB
  \Frequency = 2401      ; 2401 Hz Sinewave on ChanB, On
  \Volume    = 0.1
  \Switch    = #True
  \WaveForm  = 0
EndWith

LockLR     = #False       ; Option to lock ChanB frequency to ChanA
DoDF       = #True        ; When A&B frequencies are BOTH controlled by the ChanA channel there is an
DoDP       = #False       ; option for having a phase or frequency offset.

Global WinW = 760, WinH = 580
;}
;{- Build Control panel
BuildScopeBackdrop(1)     ; Display size Image() with grid

; Create two time cursors
Global CursorTime1 = CreateImage(#PB_Any,1,Scope\height)
StartDrawing(ImageOutput(CursorTime1))
For n = 0 To Scope\height Step 10
  For m = n To n+5
    Plot(0,m,#White)
  Next
Next
StopDrawing()
Global CursorTime2 = CopyImage(CursorTime1,#PB_Any)

; Create two volts cursors
Global CursorV1 = CreateImage(#PB_Any,Scope\width,1)
StartDrawing(ImageOutput(CursorV1))
  For n = 0 To Scope\width-6 Step 10
    For m = n To n+5  
      Plot(m,0,#White)
    Next
  Next
StopDrawing()

Global CursorV2 = CreateImage(#PB_Any,Scope\width,1)
StartDrawing(ImageOutput(CursorV2))
  For n = 5 To Scope\width-6 Step 10
    For m = n To n+5 
      Plot(m,0,#White)
    Next
  Next
StopDrawing()

; Dotted baselines for the two channels
ChanA\DatumImage  = CreateImage(#PB_Any,Scope\width,1)
StartDrawing(ImageOutput(ChanA\DatumImage))
  For n = 0 To Scope\width-6 Step 10
    For m = n To n+5  
      Plot(m,0,#Red)
    Next
  Next
StopDrawing()

ChanB\DatumImage = CreateImage(#PB_Any,Scope\width,1)
StartDrawing(ImageOutput(ChanB\DatumImage))
  For n = 0 To Scope\width-6 Step 10
    For m = n To n+5  
      Plot(m,0,#Green)
    Next
  Next
StopDrawing()

; Dotted line for trigger level
Global CursorTrig = CreateImage(#PB_Any,Scope\width,1)
StartDrawing(ImageOutput(CursorTrig))
  For n = 0 To Scope\width-6 Step 10
    For m = n To n+5  
      Plot(m,0,#Yellow)
    Next
  Next
StopDrawing()
  
; ====== Main Window, buttons etc. =======
OpenWindow(#Win_SNDWin,0,0,WinW,WinH,"Audio Generator and Monitor - R2.8 (C)2013 Richard Leman (G8CDD) ",#PB_Window_SystemMenu |#PB_Window_ScreenCentered)

; 'Scope display area
CanvasGadget(#Gad_Scope,10,10,Scope\width,Scope\height,#PB_Canvas_ClipMouse)
ScrollBarGadget(#Gad_SS_Offset,10,py+Scope\height+15,Scope\width,15,0,8191,1)

;{ Trigger controls
px = 530 : py = 2
FrameGadget(#PB_Any,px,py,220,135," Trigger ")

px + 10 : py + 20
TextGadget(#PB_Any,px,py,100,20,"Trig source", #PB_Text_Center)
ComboBoxGadget(#Gad_TriggerSelect,px,py+20,100,20)
CheckBoxGadget(#Gad_SSArm,        px,py+45,100,20,"Arm S/Shot")

px + 100
TextGadget(#PB_Any,px,py,100,20,"Sense", #PB_Text_Center)
ButtonGadget(#Gad_TrigSense,px+42,py+20,18,18,"+")

py + 70
; TextGadget(#PB_Any,px,py,200,20,"-    Trig Level    +", #PB_Text_Center)
; ScrollBarGadget(#Gad_TrigLevel,px,py+20,200,15,0,8192,4)

; Trigger mode options
For n = 1 To CountString(Scope\TriggerModeDisc$,"|")
  AddGadgetItem(#Gad_TriggerSelect,-1,StringField(Scope\TriggerModeDisc$,n,"|"))
Next
SetGadgetState(#Gad_TriggerSelect,#TraceA)
;}
;{ Trace management
px = 530 : py = 142
FrameGadget(#PB_Any,px,py,220,150," Trace Management ")

px + 10 : py + 20
TextGadget(#PB_Any,px,py,100,20,"Signal Source")
OptionGadget(#Gad_SwitchOut,px,py+20,80,18, "Audio Gen") 
OptionGadget(#Gad_SwitchIn, px+85,py+20,80,18, "External")
py + 45
TextGadget(#PB_Any,px,py,100,20,"Trace switches")
CheckBoxGadget(#Gad_TraceASwitch,px,py+20,80,18,"Trace 'A'")
CheckBoxGadget(#Gad_TraceBSwitch,px+85,py+20,80,18,"Trace 'B'")
py + 40
CheckBoxGadget(#Gad_InvertA,px,py,   80,18,"Invert 'A'")
CheckBoxGadget(#Gad_InvertB,px+85,py,80,18,"Invert 'B'")
CheckBoxGadget(#Gad_AddAB,  px,py+20,80,18,"A=A+B")
;}
;{ Audio Generator controls
px = 05 : py = 375 
FrameGadget(#PB_Any,px,py,WinW-10,185," Audio Generators ")

px + 5 : py +18 
TextGadget(#PB_Any,px, py,50,18,"Channel", #PB_Text_Center)
TextGadget(#PB_Any,px, py+20,50,20,"'A'",#PB_Text_Center)
TextGadget(#PB_Any,px, py+45,50,20,"'B'",#PB_Text_Center)

px + 45
TextGadget(#PB_Any,px, py,50,18,"On/Off", #PB_Text_Center)
CheckBoxGadget(#Gad_SwitchL,px+22,py+20, 15, 15, "",#PB_CheckBox_Right)
CheckBoxGadget(#Gad_SwitchR,px+22,py+45, 15, 15, "",#PB_CheckBox_Right)

px + 55
TextGadget(#PB_Any,px, py,80,18,"Waveform", #PB_Text_Center)
ComboBoxGadget(#Gad_WavL,px,py+20,80,20)
ComboBoxGadget(#Gad_WavR,px,py+45,80,20)

px + 85
SetKnobCaptionColour(#Black)

SetKnobDotColour(RGB(128,00,00))
SetKnobMultiTurn(10)
KnobGadget(#Gad_FreqL,   px,    py-10,  150,   "", 100,10000,#MULTITURN1 | #JAZZ_top)
TextGadget(#PB_Any,      px,    py+143,44,20,"Freq A",#PB_Text_Right)
StringGadget(#Gad_UserFA,px+52, py+141,46,20,"",#PB_String_Numeric)

KnobGadget(#Gad_VolumeL, px+320,py-5,100,"Level - A",0,100,#POTKNOB  | # JAZZ_top )

SetKnobDotColour(RGB(00,128,00))
KnobGadget(#Gad_FreqR,   px+155, py-10,150,"",100,10000,#MULTITURN1 | #JAZZ_top)
TextGadget(#PB_Any,      px+155, py+143,44,20,"Freq B",#PB_Text_Right)
StringGadget(#Gad_UserFB,px+212, py+141,46,20,"",#PB_String_Numeric)

KnobGadget(#Gad_VolumeR, px+425,py-5,100,"Level - B",0,100,#POTKNOB | # JAZZ_top )

px = 10 : py + 70 
TextGadget(#PB_Any,px,py,80,20,"Lock 'B' to 'A'",#PB_Text_Center)
CheckBoxGadget(#Gad_Lock, px+27,  py+20, 15,15,"" )

px + 80
TextGadget(#PB_Any        ,px,   py,   100,20, "Lock Offset",#PB_Text_Center)
StringGadget(#Gad_LockOfs, px+20,py+20,60, 20, "0", #PB_String_Numeric)
OptionGadget(#Gad_SwitchDF,px+20,py+45, 90,20, "Freq  (Hz)")
OptionGadget(#Gad_SwitchDP,px+20,py+70, 85,20, "Phase (Deg)")

px+450
ButtonGadget(#Gad_PlayWAV, px,py+70, 200,20, "Play WAV")

; Outgoing waveform choices
WaveType$ = "Sine|Square|Sawtooth|Noise|WAV File|"
For n = 1 To CountString(WaveType$,"|")
  AddGadgetItem(#Gad_WavL,-1,StringField(WaveType$,n,"|"))
  AddGadgetItem(#Gad_WavR,-1,StringField(WaveType$,n,"|"))
Next
;}
;{ Measurement cursors
px = 05 : py = 290 
FrameGadget(#PB_Any,px,py,455,75," Measurement Cursors ")

px + 5 : py +18 
TextGadget(#PB_Any,px, py,50,18,"Time", #PB_Text_Center)
CheckBoxGadget(#Gad_CursTimeSwitch,px+17 ,py+20, 15, 15, "")

px + 55
TextGadget(#PB_Any,px, py,50,18,"Volts", #PB_Text_Center)
CheckBoxGadget(#Gad_CursVoltSwitch,px+17,py+20, 15, 15, "")

px + 55
TextGadget(#PB_Any,px, py-8,230,18,"Measured Values", #PB_Text_Center)
EditorGadget(#Gad_CursResults,px, py+10, 230, 38, #PB_Editor_ReadOnly)
LoadFont(1,"Courier New",8) : SetGadgetFont(#Gad_CursResults,FontID(1))

px + 240
TextGadget(#PB_Any,px, py,90,18,"Volt Ref", #PB_Text_Center)
SpinGadget(#Gad_VoltRef,px,py+20,90,20,1,CountString(Scope\VoltRefDisc$,"|"),#PB_Spin_ReadOnly)

; Truly horrible...
TextGadget(#Gad_Spoof,1,1,1,1,"") : HideGadget(#Gad_Spoof,#True)
;}
;{ Hot keys to save display to clip/file/printer
AddKeyboardShortcut(#Win_SNDWin,#PB_Shortcut_Control | #PB_Shortcut_C,#Key_CntrlC)
AddKeyboardShortcut(#Win_SNDWin,#PB_Shortcut_Control | #PB_Shortcut_S,#Key_CntrlS)
AddKeyboardShortcut(#Win_SNDWin,#PB_Shortcut_Control | #PB_Shortcut_P,#Key_CntrlP)
AddKeyboardShortcut(#Win_SNDWin,#PB_Shortcut_Return,                  #Key_Return)
;}
;{ Set controls to match initial conditions etc.
SetKnobState(#Gad_FreqL,ChanA\Frequency)    : SetGadgetText(#Gad_UserFA,Str(ChanA\Frequency))
SetKnobState(#Gad_VolumeL,100*ChanA\Volume)
SetGadgetState(#Gad_SwitchL,ChanA\Switch)
SetGadgetState(#Gad_WavL,ChanA\WaveForm)

SetKnobState(#Gad_FreqR,ChanB\Frequency): SetGadgetText(#Gad_UserFB,Str(ChanB\Frequency))
SetKnobState(#Gad_VolumeR,100*ChanB\Volume)
SetGadgetState(#Gad_SwitchR,ChanB\Switch)
SetGadgetState(#Gad_WavR,ChanB\WaveForm)

SetGadgetState(#Gad_Lock,LockLR)
SetGadgetState(#Gad_SwitchDF,DoDF)
SetGadgetState(#Gad_SwitchDP,DoDP)

DisableGadget(#Gad_PlayWAV,#True)
;}
;{ Build a menu for some config items
CreateMenu(1,WindowID(#Win_SNDWin))

; Output device selection
OpenSubMenu("Sound Output Devices")
NumOutDevs = waveOutGetNumDevs_()
If NumOutDevs
  For n = 0 To NumOutDevs - 1
    If waveOutGetDevCaps_(n,@MyOutDevs,SizeOf(WAVEOUTCAPS)) = 0
      MenuItem(n + #Men_OutDevice1,PeekS(@MyOutDevs\szPname))
    EndIf
  Next
EndIf
CloseSubMenu()

; Input device selection
OpenSubMenu("Sound Input Devices")
NumInDevs = waveInGetNumDevs_()
If NumInDevs
  For n = 0 To NumInDevs - 1
    If waveInGetDevCaps_(n,@MyInDevs,SizeOf(WAVEINCAPS)) = 0
      MenuItem(n + #Men_InDevice1,PeekS(@MyInDevs\szPname))
    EndIf
  Next
EndIf
CloseSubMenu()
;}

; Set initial description for voltage cursor reference
Scope\VoltRefIndex = 0
SetGadgetText(#Gad_VoltRef,StringField(Scope\VoltRefDisc$,1+Scope\VoltRefIndex,"|"))
DisableGadget( #Gad_VoltRef,#True)

; Misc...
SetGadgetState(#Gad_SwitchOut,#True)                                 ; Initially the 'scope show the SigGen output
SetGadgetAttribute(#Gad_Scope,#PB_Canvas_Cursor,#PB_Cursor_Cross)    ; Cursor to be used when mouse over the Canvas
SetGadgetState(#Gad_SS_Offset,GetGadgetAttribute(#Gad_SS_Offset,#PB_ScrollBar_Maximum)>>1)
SetGadgetState(#Gad_TraceASwitch,#True)
SetGadgetState(#Gad_TraceBSwitch,#True)
;}
;}
;{- Preparation and startup
SetMenuItemState(1,#Men_OutDevice1,#True)
SetMenuItemState(1,#Men_InDevice1,#True)
DisableGadget(#Gad_SSArm,#True)
StartSoundOutput()
SetWindowCallback(@WinCallback())             ; Handles Scrollbars and Sound Output callback
StartSoundInput()
UseJPEGImageEncoder()
Drag\TrigLineTimer = ElapsedMilliseconds() + 5000
CreateThread(@ScopeRefresh(),1)
;}
;{- Dispatch
Finish = #False
Repeat
  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow              ;{/ Close windowS
      Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
      If Req = #PB_MessageRequester_Yes
        Finish = #True
        End
      EndIf
      ;}
    Case #PB_Event_Gadget                   ;{/ BUTTONS AND GADGETS
      Select EventGadget()
        Case #Gad_SwitchL                   ;{ Switch channel 'A' On/Off
          ChanA\Switch  = GetGadgetState(#Gad_SwitchL)
          ;}
        Case #Gad_SwitchR                   ;{ Switch channel 'B' On/Off
          ChanB\Switch = GetGadgetState(#Gad_SwitchR)
          ;}
        Case #Gad_TriggerSelect             ;{ Select Trigger mode
          Scope\TriggerMode = GetGadgetState(#Gad_TriggerSelect)
          
          If Scope\TriggerMode = #SingleShotA Or Scope\TriggerMode = #SingleShotB ; If a single shot mode has been selected,
            DisableGadget(#Gad_SSArm,#False) ; enable the 'Arm' button,
            SetGadgetState(#Gad_SSArm,#False); clear it, (waiting for user to set)
            Scope\SSArm = #False             ; clear the 'Arm' flag  
            Scope\SSFired = #False           ; the trigger is not 'Fired'.
            Scope\SSOffset = 0               ; Tidy, for debug!
          Else
            SetGadgetState(#Gad_SSArm,#False); Clear the 'Arm' button and
            DisableGadget(#Gad_SSArm,#True)  ; disable it.
            Scope\SSFired = #False           
          EndIf
          SetActiveGadget(#Gad_Spoof)        ; Remove focus???
          ;}
        Case #Gad_TrigSense                 ;{
          Scope\TrigSense * -1
          SetGadgetText(#Gad_TrigSense,Mid("- +",Scope\TrigSense + 2,1))
          ;}
        Case #Gad_SSArm                     ;{ Single shot Arm
          Scope\SSArm = GetGadgetState(#Gad_SSArm)
          Scope\SSFired = #False
          If Scope\SSArm
            FillMemory(*InBufMem,BlockSize * nBuf)
            FillMemory(Scope\SSBuffer,Scope\SSBufSize) 
            SetGadgetState(#Gad_SS_Offset,GetGadgetAttribute(#Gad_SS_Offset,#PB_ScrollBar_Maximum)>>1) ; Put scroll bar central
            StartDrawing(CanvasOutput(#Gad_Scope))   ; Clear display by overdrawing with backdrop grid
              DrawImage(ImageID(ScopeImage),0,0)
            StopDrawing()
          EndIf
          ;}
        Case #Gad_Lock                      ;{ Lock ChanB to ChanA channel
          LockLR = GetGadgetState(#Gad_Lock)
          DisableGadget(#Gad_FreqR,LockLR)  ; Prevent user access to 'B' channel freq
          DisableGadget(#Gad_UserFB,LockLR)
          If LockLR = #False
            ChanB\Frequency = GetKnobState(#Gad_FreqR)
          Else
            La.f = Ra.f
          EndIf
          ;}          
        Case #Gad_SwitchDF, #Gad_SwitchDP   ;{ Choose phase or frequency offset
          DoDF = GetGadgetState(#Gad_SwitchDF)    ; A flip-flop pair
          DoDP = DoFR ! 1
          ;}
        Case #Gad_TraceASwitch              ;{ Display switch Trace A
          Scope\TraceASwitch = GetGadgetState(#Gad_TraceASwitch)
          ;}
        Case #Gad_TraceBSwitch              ;{ Display switch Trace B
          Scope\TraceBSwitch = GetGadgetState(#Gad_TraceBSwitch)
          ;}
        Case #Gad_InvertA                   ;{ Invert Trace A / B
          Scope\SenseA = 2 * GetGadgetState(#Gad_InvertA) - 1
        Case #Gad_InvertB          
          Scope\SenseB = 2 * GetGadgetState(#Gad_InvertB) - 1
          ;}
        Case #Gad_AddAB                     ;{ Add traces (A=A+B)
          Scope\APlusB = GetGadgetState(#Gad_AddAB)
          ;}
        Case #Gad_WavL                      ;{ ChanA waveform selection
          ChanA\WaveForm = GetGadgetState(#Gad_WavL) ; Get selected waveform designator
          
          ; TEMPORARY: Sound file (must be WAV, 16 bit, mono, 44100, non-compressed
          If ChanA\WaveForm = 4 ; Choose file to be played...
            WAVFile$ = OpenFileRequester("Load a WAV File",WAVPath$,"WAV Files|*.WAV",0)
            If WAVFile$
              WAVPath$ = GetPathPart(WAVFile$)
              DisableGadget(#Gad_PlayWAV,#False)
              SetGadgetText(#Gad_PlayWAV,"Play<"+GetFilePart(WAVFile$)+">")
            EndIf
          EndIf
          SetActiveGadget(#Gad_Spoof) ; Remove focus
          ;}
        Case #Gad_WavR                      ;{ ChanB waveform selection
          ChanB\WaveForm = GetGadgetState(#Gad_WavR)
          SetActiveGadget(#Gad_Spoof) ; Remove focus???
          ;}
        Case #Gad_PlayWAV                   ;{ Kludge to start playing selected 16bit Mono 44.1K sample rate WAV file
          ; No header checks, no nuffin'...
          If IsFile(hWAV) : CloseFile(hWAV) : hWAV = 0 : EndIf ; Close a prior file.
          If WAVFile$                                          ; If filename defined,
            hWAV  = OpenFile(#PB_Any,WAVFile$)                 ; open the new file,
            FileSeek(hWAV,36)                                  ; Seek to <<normal>> start of data.
          EndIf
          ;}
        Case #Gad_CursTimeSwitch            ;{ Switch time cursors On / Off  
          Scope\TimeCursorSwitch = GetGadgetState(#Gad_CursTimeSwitch)
          ShowCursorReport()
          ;}
        Case #Gad_CursVoltSwitch            ;{ Switch volts cursors On/Off
          Scope\VoltsCursorSwitch = GetGadgetState(#Gad_CursVoltSwitch)
          ShowCursorReport()
          DisableGadget( #Gad_VoltRef,Scope\VoltsCursorSwitch ! 1)
          ;}
        Case #Gad_VoltRef                   ;{ Choose the zero datum for voltage cursors
          T = GetGadgetState(#Gad_VoltRef)  ; 1...n
          Scope\VoltRefIndex = T - 1
          SetGadgetText(#Gad_VoltRef,StringField(Scope\VoltRefDisc$,T,"|"))
          SetActiveGadget(#Gad_Spoof) ; Remove focus???
          ShowCursorReport()
          ;}
        Case #Gad_SwitchOut, #Gad_SwitchIn  ;{ Select display to show sig-gen or input
          Scope\ShowInOut = GetGadgetState(#Gad_SwitchOut)
          Scope\SSArm    = #False
          Scope\SSFired  = #False
          Scope\SSOffset = 0
          ;}
        Case #Gad_Scope                     ;{ Display Canvas Events
          Select EventType()
              ; Left mouse down over the display will be to select a feature for dragging.
              ; Some elasticity is provided so the user does not need to click directly
              ; on the line, if it is near enough the cursor jumps to the precise
              ; position of the line... which does NOT move until it is dragged.
              
            Case #PB_EventType_LeftButtonDown ;{ START dragging...
              DragX = GetGadgetAttribute(#Gad_Scope, #PB_Canvas_MouseX)
              DragY = GetGadgetAttribute(#Gad_Scope, #PB_Canvas_MouseY)
              
              ; Trigger line has priority
              If (Abs(DragY - Drag\Trig) < #Twiddle)                         ; Trigger threshold
                SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,DragX,Drag\Trig)
                Dragging = #DragTrig
              EndIf
              
              If Scope\VoltsCursorSwitch
                If (Not Dragging) And (Abs(DragY - Drag\Volts1Y) < #Twiddle) ; V1 cursor...
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,DragX,Drag\Volts1Y)
                  Dragging = #DragVolts1
                EndIf
                
                If (Not Dragging) And (Abs(DragY - Drag\Volts2Y) < #Twiddle) ; V2 cursor...
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,DragX,Drag\Volts2Y)
                  Dragging = #DragVolts2
                EndIf
              EndIf              
              
              If Scope\TraceASwitch                          
                If (Not Dragging) And Abs(DragY - Scope\YPosA) < #Twiddle    ; If close to baseline for ChanA waveform...
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,DragX,Scope\YPosA) ; snap mouse to the exact position...
                  Dragging = #DragChanAY                                     ; set flag specifying the cursor to be dragged.
                  Drag\Volts1Yb4 = Drag\Volts1Y - Scope\YPosA                ; Keep offset of Y datum from volts cursors so
                  Drag\Volts2Yb4 = Drag\Volts2Y - Scope\YPosA                ; they can be kept in sync...
                  Drag\TrigYb4   = Drag\Trig    - Scope\YPosA                ; and offset of the trigger line.
                EndIf
              EndIf
              
              If Scope\TraceBSwitch                         
                If (Not Dragging) And (Abs(DragY - Scope\YPosB) < #Twiddle)  ; ChanB channel...
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,DragX,Scope\YPosB)
                  Dragging = #DragChanBY
                  Drag\Volts1Yb4 = Drag\Volts1Y - Scope\YPosB              
                  Drag\Volts2Yb4 = Drag\Volts2Y - Scope\YPosB
                  Drag\TrigYb4   = Drag\Trig    - Scope\YPosB
                EndIf
              EndIf
              
              If Scope\TimeCursorSwitch
                If (Not Dragging) And (Abs(DragX - Drag\Time1X) < #Twiddle) ; T1 cursor....
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,Drag\Time1X,DragY)
                  Dragging = #DragTime1  
                EndIf
                
                If (Not Dragging) And (Abs(DragX - Drag\Time2X) < #Twiddle) ; T2 Cursor...
                  SetGadgetMouseXY(#Win_SNDWin,#Gad_Scope,Drag\Time2X,DragY)
                  Dragging = #DragTime2  
                EndIf
              EndIf
              
              If (Not Dragging) And Scope\SSFired                           ; Drag Screen...
                Dragging = #DragScreen
                Drag\ScreenDragX = DragX
                Drag\OldDragX    = DragX
              EndIf
               
              If Dragging : Beep_(5000,10) : EndIf
              
              ;}
            Case #PB_EventType_LeftButtonUp   ;{  FINISH dragging
              Dragging = #DragNone
              ;}
          EndSelect
          ;}
        Case #Gad_FreqL To #Gad_VolumeR     ;{ Frequency and Amplitude KnobGadgets()
           Select EventType()
           Case #PB_EventType_LeftButtonDown 
             KnobService(EventGadget())
              
            Case  #PB_EventType_MouseWheel          
              T = GetGadgetAttribute(EventGadget(),#PB_Canvas_WheelDelta)  ; Get mouse delta
              SetKnobState(EventGadget(),GetKnobState(EventGadget())+(T))  ; Apply it to Knob
              
          EndSelect  
          
          ;}
      EndSelect
      ;} 
    Case #PB_Event_Menu                     ;{/ MENU ITEMS AND HOT-KEYS
      T = EventMenu()
      Select T
          ; MENU ITEMS
        Case #Men_InDevice1 To #Men_InDevice1 + 9   ;{ Input device selection
          For n = #Men_InDevice1 To #Men_InDevice1 + 9        ; Clear all 'ticks'
            SetMenuItemState(1,n,#False)
          Next
          SetMenuItemState(1,T,#True)                         ; Set 'tick' to match selection
          DevIn = T - #Men_InDevice1 + 1                      ; Calc new number number
          StopSoundInput()                                    ; Close current input device 
          StartSoundInput()                                   ; Open New input device
          ;}
        Case #Men_OutDevice1 To #Men_OutDevice1 + 9 ;{ Output device selection
          For n = #Men_OutDevice1 To #Men_OutDevice1 + 9     
            SetMenuItemState(1,n,#False)
          Next
          SetMenuItemState(1,T,#True) 
          DevOut = T - #Men_OutDevice1 + 1  
          StopSoundOutput()        
          StartSoundOutput()   
          ;}
          
          ; HOT KEYS
        Case #Key_CntrlC ;{ Copy current display to the clipboard
          Beep_(5000,10)
          ClearClipboard()
          SetClipboardImage(Scope\Copy)
          ;}
        Case #Key_CntrlP ;{ Make a copy of the screen image and add some annotation
          
          Copy2 = CreateImage(#PB_Any,ImageWidth(Scope\Copy), 2*ImageHeight(Scope\Copy))
          LoadFont(1,"Courier New",12)
          StartDrawing(ImageOutput(Copy2))
            DrawingMode(#PB_2DDrawing_Default)
            DrawingFont(FontID(1))
            Box(0,0,ImageWidth(Copy2),ImageHeight(Copy2),#White) ; Make the backdrop white
            FrontColor(#Black)
            MessageRequester("test",Str(IsImage(Scope\Copy)))
            DrawImage(ImageID(Scope\Copy),0,25)                  ; Draw the 'scope display 
            DrawingMode(#PB_2DDrawing_Transparent)
            k$ = "AGMO Rev 2.3"                                  ; Draw the title
            dx = (ImageWidth(Copy2)-TextWidth(k$))/2
            DrawText(dx,2,k$)
            py = ImageHeight(Scope\Copy) + 35
            DrawText(20,py,"Fred")                               ; and some info...
          StopDrawing()
          FreeFont(1)
          SetClipboardImage(Copy2)
          
          ; Choose printer
          If PrintRequester()
            If StartPrinting("G8CDD")
              If StartDrawing(PrinterOutput())
                  DrawingMode(#PB_2DDrawing_Transparent)
                  DrawImage(ImageID(Copy2),0,330,PrinterPageWidth(),PrinterPageWidth())
                StopDrawing()
              EndIf
              StopPrinting()
            EndIf
          EndIf
          FreeImage(Copy2)
          ;}
        Case #Key_CntrlS ;{ Save the 'scope image as a BMP or JPG file.
          Beep_(5000,10)
          Copy2 = CopyImage(Scope\Copy,#PB_Any) ; Copy the image
          
          ; Path to working directory
          If Not Len(SavePathPart$)
            SavePathPart$="C:\Temp\"
          EndIf
          
          ; Ask user to provide the path+file name, ensure it has the proper extension and save the image
          File$ = SaveFileRequester("Provide the filename for the image save (BMP/JPG)",SavePathPart$,"Bitmap File (*.bmp)|*.bmp|JPEG File (*.jpg)|*.jpg",0)
          If File$
            k$=UCase(Right(File$,4))
            If k$<>".BMP" And k$<>".JPG"
              File$ + StringField(".BMP|.JPG",SelectedFilePattern()+1,"|")
            EndIf
            SavePathPart$ = GetPathPart(File$) 
            SaveImage(Copy2,File$,#PB_ImagePlugin_BMP)
          EndIf
          
          FreeImage(Copy2) ; Get rid of the copy
          ;}
        Case #Key_Return ;{ 'Return' key pressed over some StringGadgets() forces focus...
          ;                 to a spoof gadget. The string gadget is then read out, see
          ;                 #PB_EventType_LostFocus EventType().
          T = GetActiveGadget()
          If T=#Gad_LockOfs   Or T=#Gad_UserFA Or T=#Gad_UserFB
            SetActiveGadget(#Gad_Spoof) 
          EndIf
          
      EndSelect
      ;}
  EndSelect
  
  Select EventType()
      
    Case #PB_EventType_LostFocus                                ; If gadget contents were changed...
      Select EventGadget()
          
        Case #Gad_LockOfs                         
          LockOffset = Val(GetGadgetText(#Gad_LockOfs))         
          
        Case #Gad_UserFA
          T = Val(GetGadgetText(#Gad_UserFA))
          If T>= 100 And T<=10000
            ChanA\Frequency = T
            SetKnobState(#Gad_FreqL, T)
          EndIf
          
        Case #Gad_UserFB
          T = Val(GetGadgetText(#Gad_UserFB))
          If T>= 100 And T<=10000
            ChanB\Frequency = T
            SetKnobState(#Gad_FreqR, T)  
          EndIf
          
      EndSelect
  EndSelect
Until Finish
;}
;{- PackUpFallOut
StopSoundOutput()
StopSoundInput()
;}
End

Procedure WinCallback(hwnd, uMsg, wParam, lParam)            ;- Window callback to service scrollbar and sound output message
  Static T
  Static *PriorCopyPointer
  Select uMsg
    Case #PBM_KNOB
      Select lParam
        Case GadgetID(#Gad_FreqL)    : ChanA\Frequency = wParam  : SetGadgetText(#Gad_UserFA,Str(wParam)) ; Frequency value directly from control
        Case GadgetID(#Gad_FreqR)    : ChanB\Frequency = wParam  : SetGadgetText(#Gad_UserFB,Str(wParam))
        Case GadgetID(#Gad_VolumeL)  : ChanA\Volume    = wParam / 100       ; Scale volume over range 0 to 1. FLOAT
        Case GadgetID(#Gad_VolumeR)  : ChanB\Volume    = wParam / 100

      EndSelect
    Case #WM_HSCROLL            ;{ Two frequency, two amplitude controls and trigger adjustments
      Select lParam
        Case GadgetID(#Gad_SS_Offset): Scope\SSPosSlider = ((GetGadgetState(#Gad_SS_Offset)-4095)*4) ; Position the display origin.
      EndSelect
      ;}
    Case #MM_WOM_DONE           ;{ Sound output, a play buffer has been returned.
      *hWaveO.WAVEHDR = lParam                        ; lParam has the address of WAVEHDR
      *P    = *hWaveO\lpData                          ; Where to write NEW data
      CalcWave(*P,BlockSize>>2)                       ; ?/4 one WORD each ChanA and ChanB
      *hWaveO\dwBytesRecorded = BlockSize             ; Number of bytes written into buffer
      waveOutWrite_(hWaveOut,lParam, SizeOf(WAVEHDR)) ; Send to sound device => jack socket => cable =>
      
      If Scope\ShowInOut
        Scope\DisplayP     = *P
        Scope\DisplayStart = *P
        Scope\DisplayEnd   = *P+BlockSize-1

      EndIf
      ;}
    Case #MM_WIM_DATA           ;{ Sound input.
      *hWaveIn.WAVEHDR = lParam                       
      *P = *hWaveIn\lpData
      waveInAddBuffer_(wParam, lParam, SizeOf(WAVEHDR))
      
      ; Trace Freeze management
      If Scope\ShowInOut = 0                         ; If showing the INPUT...
        
        If Scope\SSFired = #True                     ; and single shot mode has fired (Set in ScopeRefresh())...
          ; Update 'frozen' display. (Done repeatidly so cursors etc move)
          T =  Scope\SSOffset +  Scope\SSPosSlider
          If T < 0 : T = Scope\SSBufSize + T : EndIf ; +T?  Yes, T is -ve
          Scope\DisplayP     = Scope\SSBuffer + T
          Scope\DisplayStart = Scope\SSBuffer
          Scope\DisplayEnd   = Scope\SSBufferEnd
        Else  
          ; Not 'fired', so we continue to store incoming data in the circular buffer
          *Q = Scope\SSBuffer + (*P - *InBufMem)     ; Calculate position to save data and...
          CopyMemory(*P,*Q, BlockSize)               ; copy input buffer to circular store,
          Scope\DisplayP     = *P
          Scope\DisplayStart = *P
          Scope\DisplayEnd   = *P + BlockSize - 1
          
          ; Keep storing data AFTER a trigger for half of the memory size
          ; (Scope\DisplayTrig is only set by single shot trigger event.)
          If Scope\DisplayTrig                       ; If triggered but not counted down half the buffers... 
            Scope\DisplayTrig - 1                    ; decrement buffer counter.
            If Scope\DisplayTrig < 1                 ; When all done,
              Scope\SSFired    = #True               ; set flag (which stops data capture),                   
              Scope\SSArm      = #False              ; disarm the trigger
              SetGadgetState(#Gad_SSArm,#False)      ; and set the 'Arm' button to match.
              Drag\ScreenDragTotal = 0
            EndIf
          EndIf
          
        EndIf
      EndIf
      ;}
    Case #WM_MOUSEWHEEL         ;{ MOUSE wheel, while mouse is over display
      MinDec = 1
      With Scope
        If \TriggerMode = #TraceA Or \TriggerMode = #TraceB Or \TriggerMode = #FreeRun : MinDec = 16 : EndIf
      EndWith
      MX.w = WindowMouseX(#Win_SNDWin)
      MY.w = WindowMouseY(#Win_SNDWin)
      If MX>GadgetX(#Gad_Scope) And MX<GadgetX(#Gad_Scope)+GadgetWidth(#Gad_Scope)
        With Scope
          If MY>GadgetY(#Gad_Scope) And MY<GadgetY(#Gad_Scope)+GadgetHeight(#Gad_Scope)
            If wParam>0 ; Increase
              \Mag << 1
              If \Mag > 256
                \Mag = 256
              Else
                Beep_(5000,10)
                ShowCursorReport()
              EndIf
            Else        ; Decrease
              \Mag >> 1
              If \Mag < MinDec
                \Mag = MinDec
              Else
                Beep_(5000,10)
                ShowCursorReport()
              EndIf
            EndIf
          EndIf
        EndWith
      EndIf
      ;}
  EndSelect
  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure
Procedure ScopeRefresh(*z)                                   ;- THREAD: Redraw the oscilloscope display
  EnableExplicit
  Protected LastVa.w, LastVb.w, STrig,Va.w, Vb.w,Ya.w,Yb.w,X,Y,n,vt.w, T,Sx.f, dx.f,*Bl
  Protected OldX.f, OldYa, OldYb
  Static CrsRep$,k$,Qt
  Protected Counter
  Protected *DisplayP, *DisplayStart, *DisplayEnd
  
  Delay(500) ; Wait for first time data to be ready
  
  Repeat
    
    ; Location of data to be displayed
    *DisplayP     = Scope\DisplayP      ; Start from this address
    *DisplayStart = Scope\DisplayStart  ; Beginning of buffer, needed if we wrap round.
    *DisplayEnd   = Scope\DisplayEnd    ; End of buffer, ditto.
    
    ; Derive Trigger level from the Trigger line and the current Trace datum.
    Select Scope\TriggerMode
      Case #TraceA,#SingleShotA : vt = (Scope\YPosA - Drag\Trig)<<8
      Case #TraceB,#SingleShotB : vt = (Scope\YPosB - Drag\Trig)<<8
    EndSelect
    STrig = 0                                               ; Default, do NOT sweep this time...
    
    ;{ DRAGGING: Adjust co-ords of any feature being dragged..
    If Dragging
      Y = WindowMouseY(#Win_SNDWin) - GadgetY(#Gad_Scope)
      X = WindowMouseX(#Win_SNDWin) - GadgetX(#Gad_Scope)
      Select Dragging 
        Case #DragChanAY
          Scope\YPosA   = Y                                 ; Red trace base line
          If Scope\VoltRefIndex = #TraceA
            Drag\Volts1Y = Y + Drag\Volts1Yb4
            Drag\Volts2Y = Y + Drag\Volts2Yb4
          EndIf
          If Scope\TriggerMode = #TraceA Or Scope\TriggerMode = #SingleShotA
            Drag\Trig    = Y + Drag\TrigYb4
          EndIf
          
        Case #DragChanBY
          Scope\YPosB   = Y                                 ; ... Green 
          If Scope\VoltRefIndex = #TraceB
            Drag\Volts1Y = Y + Drag\Volts1Yb4
            Drag\Volts2Y = Y + Drag\Volts2Yb4
          EndIf
          If Scope\TriggerMode = #TraceB Or Scope\TriggerMode = #SingleShotB
            Drag\Trig    = Y + Drag\TrigYb4
          EndIf
          
        Case #DragTime1  : Drag\Time1X = X  ; Time cursor T1 RJL
        Case #DragTime2  : Drag\Time2X = X  ; ... T2
        Case #DragVolts1 : Drag\Volts1Y= Y  ; Volts cursor V1
        Case #DragVolts2 : Drag\Volts2Y= Y  ; ... V2
        Case #DragTrig   : Drag\Trig   = Y  ; Trigger level
          Drag\TrigLineTimer = ElapsedMilliseconds() + 5000 ; Start Trig reference line timer
          
        Case #DragScreen                                    ; Screen Drag... unfinished.  RJL
          If X <> Drag\OldDragX And Scope\SSFired 
            Drag\ScreenDragTotal + (X - Drag\OldDragX)*4    ; *4? Two WORD values
          EndIf
          Drag\OldDragX = X
          
      EndSelect
      ShowCursorReport()                                    ; Update the report text
    EndIf
    ;}
    
    ; Free a previous Image() and make new copy of 'scope backdrop
    If Scope\Copy :  FreeImage(Scope\Copy) : Scope\Copy = 0 : EndIf
    Scope\Copy = CopyImage(ScopeImage,#PB_Any)     
    
    StartDrawing(ImageOutput(Scope\Copy))          ; Draw on the copy
      ;{ Draw cursor lines and annotation
      ; Show the two channel frequencies
      DrawText(8,8,Str(ChanA\Frequency)+" Hz",#Red) 
      DrawText(450,8,Str(ChanB\Frequency)+" Hz",#Green)
      
      ; X Scale
      If Scope\Mag = 16
        k$ = "X : 1 mSec/div"
      ElseIf Scope\Mag > 16
        k$ = "X : 1/"+Str(Scope\Mag >> 4) + " mSec/div"
      Else
        k$ = "X : "+Str(16/Scope\Mag)  + " mSec/div"
      EndIf
      DrawText(8,Scope\height - 18,k$)
      
      ; Draw the base lines (Zero volts) for each trace... dotted lines
      If Scope\TraceASwitch : DrawImage(ImageID(ChanA\DatumImage),0,Scope\YPosA): EndIf
      If Scope\TraceBSwitch : DrawImage(ImageID(ChanB\DatumImage),0,Scope\YPosB): EndIf
      
      ; Draw the time and voltage cursors... dotted lines 
      If  Scope\TimeCursorSwitch
        DrawImage(ImageID(CursorTime1),Drag\Time1X-1,0) : DrawText(Drag\Time1X+2,240,"T1")
        DrawImage(ImageID(CursorTime2),Drag\Time2X-1,0) : DrawText(Drag\Time2X+2,240,"T2") 
      EndIf
      
      If Scope\VoltsCursorSwitch
        DrawImage(ImageID(CursorV1),0,Drag\Volts1Y)     : DrawText(490,Drag\Volts1Y-18,"V1")
        DrawImage(ImageID(CursorV2),0,Drag\Volts2Y)     : DrawText(490,Drag\Volts2Y-18,"V2")
      EndIf
      
      ; Trigger level cursor / reminder blob
      If ElapsedMilliseconds() < Drag\TrigLineTimer 
        DrawImage(ImageID(CursorTrig),0,Drag\Trig)      : DrawText(480,Drag\Trig - 18,"Trig",#Yellow)
      Else
        Circle(0,Drag\Trig,2,#Yellow)
      EndIf
      ;}
      ;{ SS  Blue line trigger marker....
      *Bl = 0
      If Scope\SSFired
        *Bl = Scope\SSOffset + Scope\SSBuffer - 4
      EndIf
      ;}
      
      LastVa = $7FFF * Scope\TrigSense    ; Prime the 'scope trigger 
      LastVb = $7FFF * Scope\TrigSense        
      
      *DisplayP - Drag\ScreenDragTotal
      
      T = ElapsedMilliseconds() + 20
      Sx = 0    
      Repeat
        
        ; Display pointer rolled over...
        If *DisplayP >= *DisplayEnd 
          *DisplayP = *DisplayStart 
        EndIf
        
        ; Draw blue line
        If *DisplayP => *Bl
          LineXY(Sx,0,Sx,Scope\height,#Cyan)
          *Bl = Scope\SSBufferEnd +$10000
        EndIf
        
        ; Get the ChanA and ChanB signals
        Va = PeekW(*DisplayP) : *DisplayP + 2              
        Vb = PeekW(*DisplayP) : *DisplayP + 2
        
        ; TRIGGER: Detect signal crossing a trigger level....
        Select Scope\TriggerMode
          Case #FreeRun                                      ;{ Not waiting for trigger...
            STrig = #True                                    ;}
          Case #TraceA                                       ;{ Channel 'A' trigger
            If Scope\TrigSense = 1
              If (LastVa <= vt) And (Va > vt)                ; Moved +ve though trigger level...
                STrig = #True                                ; Set trigger flag...
              EndIf                    
            Else
              If (LastVa >= vt) And (Va < vt)                ; Moved -ve though trigger level...
                STrig = #True                                ; Set trigger flag...
              EndIf             
            EndIf
            LastVa = Va                                      ;} Keep current 'A' value 
          Case #TraceB                                       ;{ Channel 'B' trigger
            If Scope\TrigSense = 1
              If (LastVb <= vt) And (Vb > vt) 
                STrig = #True               
              EndIf                                
            Else
              If (LastVb >= vt) And (Vb < vt) 
                STrig = #True
              EndIf  
            EndIf
            LastVb = Vb                                      ;}                
          Case #SingleShotA                                  ;{ Waiting for 'A' storage trigger event...
            If Scope\SSArm And (Scope\SSFired = #False)      
              If (LastVa <= vt) And (Va > vt)                ; Triggered!
                If Not Scope\DisplayTrig                     ; If run-on buffer counter NOT primed...
                  Scope\SSOffset = *DisplayP - *InBufMem - 4 ; keep OFFSET of trigger event (from start of buffer memory),
                  Scope\DisplayTrig = (nBuf>>1)-1            ; prime counter of buffers to run-on on before stopping.
                EndIf
              EndIf 
              LastVa = Va
            Else
              STrig = #True
            EndIf
            ;}
          Case #SingleShotB                                  ;{...'B'
            If Scope\SSArm And (Scope\SSFired = #False)  
              If (LastVb <= vt) And (Vb > vt)
                If Not Scope\DisplayTrig                    
                  Scope\SSOffset = *DisplayP - *InBufMem - 4 
                  Scope\DisplayTrig = (nBuf>>1)-1          
                EndIf
              EndIf 
              LastVb = Vb
            Else
              STrig = #True
            EndIf
            ;}
        EndSelect
        
        ;{ Plot display points following trigger event
        If STrig
          If (Sx < Scope\width)
            Ya = (Int(Va)>>8)*Scope\SenseA               ; ChanA waveform
            Yb = (Int(Vb)>>8)*Scope\SenseB               ; ChanB
            If Scope\APlusB                              ; If A=A+B...
              Ya+Yb            
            EndIf
            Yb + Scope\YPosB                             ; Offset the ChanA waveform
            Ya + Scope\YPosA 
            If Sx > 0                                    ; After the first point...
              If Scope\TraceASwitch                      ; If showing Channel A...
                LineXY(OldX,OldYa,Sx,Ya,#Red)            ; join to previous point
              EndIf
              If Scope\TraceBSwitch                      ; If showing channel B...
                LineXY(OldX,OldYb,Sx,Yb,#Green)
              EndIf
            EndIf
            
            ; Keep values to become the previous, next time
            OldX  = Sx
            OldYa = Ya
            OldYb = Yb
            
            ; Increment X position 
            dx = (Scope\Mag / 16)
            Sx + dx
          EndIf
        EndIf
        ;}
        
      Until (Sx > 511) Or ElapsedMilliseconds() > T
      
    StopDrawing() 
    
    ; Update the display 
    StartDrawing(CanvasOutput(#Gad_Scope))   
    DrawImage(ImageID(Scope\Copy),0,0)
    StopDrawing()    
    Delay(5) ; Prevent resource hogging
    
ForEver

DisableExplicit
EndProcedure
Procedure StartSoundOutput()
  Protected T,i, *P
  Static *OutBufMem
  
  With PlayFormat
    \wFormatTag      = #WAVE_FORMAT_PCM
    \nChannels       = 2
    \wBitsPerSample  = 16
    \nSamplesPerSec  = SampleClock
    \nBlockAlign     = (\nChannels * \wBitsPerSample)/8 ; = 4
    \nAvgBytesPerSec = \nSamplesPerSec * \nBlockAlign   ; = 176400
  EndWith
  
  If *OutBufMem : FreeMemory(*OutBufMem) : EndIf                       ; Free a prior assignement
  *OutBufMem = AllocateMemory(BlockSize * nBuf)                        ; Reserve memory for all the buffers
  
  T =  waveOutOpen_(@hWaveOut, #WAVE_MAPPER+DevOut, @PlayFormat, WindowID(#Win_SNDWin), #True, #CALLBACK_WINDOW | #WAVE_FORMAT_DIRECT)
  If T = #MMSYSERR_NOERROR
    
    ; NOTE:  'n' contiguous buffers are more convenient to debug with.
    *P = *OutBufMem                                                    ; Pointer to start of memory
    For i = 0 To nBuf-1                                                ; For each buffer...
      outHdr(i)\lpData         = *P                                    ; start of buffer
      outHdr(i)\dwBufferLength = BlockSize                             ; size of buffer
      outHdr(i)\dwFlags        = 0
      outHdr(i)\dwLoops        = 0
      T | waveOutPrepareHeader_(hWaveOut, outHdr(i), SizeOf(WAVEHDR))  
      *P + BlockSize
    Next
    
    For i = 0 To nBuf-1
      PostMessage_(WindowID(#Win_SNDWin),#MM_WOM_DONE,0,outHdr(i))
    Next 
    
  EndIf
  
  ProcedureReturn T
  
EndProcedure
Procedure StopSoundOutput()
  waveOutReset_(hWaveOut)
  For i = 0 To nBuf - 1
    waveOutUnprepareHeader_(hWaveOut, outHdr(i), SizeOf(WAVEHDR))
  Next
  waveOutClose_(hWaveOut)
EndProcedure
Procedure StartSoundInput()
  Protected T, i, *P
  
  ; Could use PlayFormat... but they could be changed separately.
  With RecFormat 
    \wFormatTag      = #WAVE_FORMAT_PCM
    \nChannels       = 2
    \wBitsPerSample  = 16
    \nSamplesPerSec  = SampleClock                     ; = 44100
    \nBlockAlign     = (\nChannels * \wBitsPerSample)/8 ; = 4
    \nAvgBytesPerSec = \nSamplesPerSec * \nBlockAlign   ; = 176400
  EndWith
  
  ; Memory for incoming data blocks
  If *InBufMem : FreeMemory(*InBufMem) : EndIf
  *InBufMem = AllocateMemory(BlockSize * nBuf)        ; Reserve memory for ALL the input buffers
  *InBufMemEnd = *InBufMem + (BlockSize * nBuf) - 1
  
  ; Buffer for freeze store
  With Scope
    If \SSBuffer : FreeMemory(\SSBuffer) : EndIf
    \SSBufSize = BlockSize * nBuf
    \SSBuffer = AllocateMemory(\SSBufSize)
    \SSBufferEnd = \SSBuffer + \SSBufSize - 1
  EndWith
  
  T =  waveInOpen_(@hWaveIn, #WAVE_MAPPER+DevIn, @RecFormat,  WindowID(#Win_SNDWin), #Null, #CALLBACK_WINDOW | #WAVE_FORMAT_DIRECT)
  If T = #MMSYSERR_NOERROR
    *P = *InBufMem
    For i = 0 To nBuf-1
      inHdr(i)\lpData         = *P
      inHdr(i)\dwBufferLength = BlockSize
      T | waveInPrepareHeader_(hWaveIn, inHdr(i), SizeOf(WAVEHDR)) ; Note: inHdr(i) returns pointer to the i'th structure... not contents of first element
      T | waveInAddBuffer_(hWaveIn, inHdr(i), SizeOf(WAVEHDR))
      *P + BlockSize
    Next
    
    If waveInStart_(hWaveIn) = #MMSYSERR_NOERROR 
      ;SetTimer_(WindowID(#Win_SNDWin), 42, 5, 0); Why?
    EndIf
    
  EndIf
  ProcedureReturn T
EndProcedure
Procedure StopSoundInput()
  waveInReset_(hWaveIn)
  For i = 0 To nBuf - 1
    waveInUnprepareHeader_(hWaveIn, inHdr(i), SizeOf(WAVEHDR))
  Next
  waveInClose_(hWaveIn)
EndProcedure
Procedure ShowCursorReport()
  
  Protected CrsRep$ = "" ,F.f
  
  If  Scope\TimeCursorSwitch 
    
    F =  Scope\PixPermSec * (Scope\Mag/16)
    
    CrsRep$ + "T1=" + RSet(StrF(Drag\Time1X / F, 2),5," ") + " "
    CrsRep$ + "T2=" + RSet(StrF(Drag\Time2X / F, 2),5," ") + " "
    CrsRep$ + "dT=" + RSet(StrF((Drag\Time2X-Drag\Time1X) / F, 2),5," ") + " mSec" + Chr(10)
  EndIf
  
  If Scope\VoltsCursorSwitch 
    
    ; Select the reference location for the voltage cursors
    Select Scope\VoltRefIndex      ; 1 => 4  = "ChanA|ChanB|Bottom|Centre|"
      Case 1 : T = Scope\YPosA
      Case 2 : T = Scope\YPosB
      Case 3 : T = Scope\height
      Case 4 : T = Scope\height /2
    EndSelect
    
    ; Volts cursors...
    CrsRep$ + "V1=" + RSet(StrF((T - Drag\Volts1Y) / Scope\PixPerVolt,2),5," ") + " "
    CrsRep$ + "V2=" + RSet(StrF((T - Drag\Volts2Y) / Scope\PixPerVolt,2),5," ") + " "
    CrsRep$ + "dV=" + RSet(StrF((Drag\Volts2Y-Drag\Volts1Y) / Scope\PixPerVolt,2),5," ")
    
  EndIf
  SetGadgetText(#Gad_CursResults,CrsRep$)
  
EndProcedure
Procedure CalcWave(*SBuf,nSamples)                           ;- Calculate the waveform for ChanA / ChanB channels
  ; This routine  generates ChanA and ChanB waveforms.
  ; Both channels are phase continuous between multiple calls.
  ; ChanA and ChanB samples are interleaved and each sample is a WORD value. (L.w, R.w, L.w, R.w, L.w, R.w.... etc
  ; The receiving buffer MUST have a length that is a MULTIPLE of 4 
  
  Static Angle.f,Vl.f,Vr.f,Kl.f,Kr.f
  Protected *P, sample
  ;{ Calculate the frequency scaling factors - 
  Kl = ChanA\Frequency / ((SampleClock)/#PIx2)
  If LockLR                                  ; If channels are locked together, there are two lock modes...
    If DoDF                                  ; (1) With a user specified frequency offset...
      ChanB\Frequency = ChanA\Frequency + LockOffset
    Else                                     ; (2) With a phase offest...
      ChanB\Frequency = ChanA\Frequency
      Ra = La + ((LockOffset/360) * #PIx2)
    EndIf
    
  EndIf
  Kr = ChanB\Frequency /((SampleClock)/#PIx2)
  ;}
  ;{ Generate waveform data
  *P = *SBuf
  For sample = 0 To nSamples-1
    
    ; Derive ChanA channel waveform points.
    If ChanA\Switch                                           ; If ChanA channel is switched ON...
      Select ChanA\WaveForm
        Case 0
          Vl = Sin(La) * 32767 * ChanA\Volume 
        Case 1 : Vl = 32767 * ChanA\Volume                    ; Square
          If La > #PI : Vl = -Vl : EndIf 
        Case 2 : Vl = 32767 * ChanA\Volume * (La-#PI)/#PI     ; Sawtooth
        Case 3 : Vl = (Random(65535)-32768) *  ChanA\Volume   ; Noise
        Case 4                                               ; WAV file ~ Temporary
          If hWAV And Not Eof(hWAV)
            Vl = ReadWord(hWAV) *  ChanA\Volume 
          Else
            If hWAV : CloseFile(hWAV) : hWAV = 0 : EndIf
            Vl = 0
          EndIf
      EndSelect
      La + Kl                                                ; Calculate angle for next time
      If La > #PIx2 : La - #PIx2 : EndIf                     ; limit to 2*PI radians
    Else                                                     ; Not ON so point is zero
      Vl = 0
    EndIf
    PokeW(*P,Vl)                                             ; Put point in buffer
    *P + BytesPerSample                                      ; move buffer pointer to next ChanB sample
    
    ; Derive ChanB channel waveform point
    If ChanB\Switch
      Select ChanB\WaveForm
        Case 0 : Vr = Sin(Ra) * 32767 * ChanB\Volume         
        Case 1 : Vr = 32767 * ChanB\Volume
          If Ra > #PI : Vr = -Vr : EndIf                      
        Case 2 : Vr = 32767 * ChanB\Volume * (Ra-#PI)/#PI    
        Case 3 : Vr = (Random(65535)-32768) *  ChanB\Volume  
        Case 4 : ; Nothing!  
      EndSelect
      Ra + Kr
      If Ra > #PIx2 : Ra - #PIx2 : EndIf
    Else
      Vr = 0
    EndIf
    PokeW(*P,Vr)
    *P + BytesPerSample
    
  Next
  ;}
EndProcedure

Procedure BuildScopeBackdrop(Bn)                             ;- Create the backdrop for the 'scope with 1mSec grid lines

  If IsImage(ScopeImage) : FreeImage(ScopeImage) : EndIf
  
ScopeImage = CreateImage(#PB_Any,Scope\width,Scope\height)
Scope\PixPermSec =  Scope\width /(1000*BlockSize/(SampleClock*8)) ; Pixels per mSec

StartDrawing(ImageOutput(ScopeImage))
  FrontColor(RGB($70,$28,$A))
  F.f = Scope\PixPermSec
  X.f = 0
  While X <Scope\width
    LineXY(X,0,X,Scope\height-1) 
    X +  Scope\PixPermSec
  Wend
  
  Y.f = 0  ; Horizontal lines are purely cosmetic at present!
  T = Scope\height/2
  While Y < T
    LineXY(0,128-Y,Scope\width,Scope\height/2-Y)
    LineXY(0,128+Y,Scope\width,T+Y)
    Y +  Scope\PixPermSec
  Wend
  Scope\YPosB = Int(T + F.f)
  Scope\YPosA = Int(T - F.f)
StopDrawing()

EndProcedure
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 1231
; FirstLine = 1226
; Folding = ------------
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; Executable = ToneGenerator.exe