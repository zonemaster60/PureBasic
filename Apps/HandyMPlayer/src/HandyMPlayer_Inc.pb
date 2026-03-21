;
; Handy Media Player - Constants & Structures
;

#WindowWidth = 365
#WindowHeight = 70
#APP_NAME = "HandyMPlayer"
#EMAIL_NAME = "zonemaster60@gmail.com"

#Window_Main = 0
#Window_Video = 1

#Gadget_Progress = 0

Enumeration
  #MovieState_Ready
  #MovieState_Playing
  #MovieState_Paused
  #MovieState_Stopped
EndEnumeration

Enumeration
  #Command_Load
  #Command_Exit
  #Command_PlayPause
  #Command_Stop
  #Command_Pause
  #Command_VolumeFull
  #Command_VolumeHalf
  #Command_VolumeMute
  #Command_BalanceCenter
  #Command_BalanceLeft
  #Command_BalanceRight
  #Command_Help
  #Command_SizeDefault
  #Command_SizeX1
  #Command_SizeX2
  #Command_About
EndEnumeration

#LayoutPadding = 5
#ProgressBarHeight = 15
#ProgressBarLeft = 10
#ProgressBarRightMargin = 10

#ProgressScaleMax = 10000

; WinAPI Constants (if not already defined in PB)
#GWL_STYLE = -16
#WS_CHILD = $40000000
#WS_CLIPCHILDREN = $02000000
#WS_CLIPSIBLINGS = $04000000
#SWP_NOMOVE = $0002
#SWP_NOSIZE = $0001
#SWP_NOZORDER = $0004
#SWP_FRAMECHANGED = $0020
#HWND_TOP = 0
#HWND_BOTTOM = 1
#SWP_NOACTIVATE = $0010

Structure WinPOINT
  x.l
  y.l
EndStructure

Structure WinRECT
  left.l
  top.l
  right.l
  bottom.l
EndStructure
