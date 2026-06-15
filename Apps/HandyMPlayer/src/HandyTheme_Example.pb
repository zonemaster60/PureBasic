;
; HandyTheme_Example.pb
; Minimal example for HandyTheme_Reusable.pbi.
;

EnableExplicit

IncludeFile "HandyTheme_Reusable.pbi"

Enumeration
  #Window_Main
EndEnumeration

Enumeration
  #Gadget_Title
  #Gadget_Info
  #Gadget_Progress
  #Gadget_System
  #Gadget_Light
  #Gadget_Dark
  #Gadget_Blue
  #Gadget_Forest
  #Gadget_WindowColor
  #Gadget_PanelColor
  #Gadget_TextColor
  #Gadget_AccentColor
EndEnumeration

Global AppTheme.HandyThemePalette

Procedure ApplyThemeToExample()
  HandyThemeApplyWindow(@AppTheme, #Window_Main)
  HandyThemeApplyGadget(@AppTheme, #Gadget_Title, #True)
  HandyThemeApplyGadget(@AppTheme, #Gadget_Info)
  HandyThemeApplyProgress(@AppTheme, #Gadget_Progress)
EndProcedure

HandyThemeApplyPreset(@AppTheme, #HandyTheme_System)

If OpenWindow(#Window_Main, 0, 0, 520, 260, "Theme Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  TextGadget(#Gadget_Title, 10, 10, 500, 24, "Reusable PureBasic Theme Example")
  EditorGadget(#Gadget_Info, 10, 42, 500, 80, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetText(#Gadget_Info, "Choose a preset or use the color buttons. Native Windows buttons may stay system-themed, but windows, text/editor/list surfaces, and progress accents update.")
  ProgressBarGadget(#Gadget_Progress, 10, 132, 500, 20, 0, 100)
  SetGadgetState(#Gadget_Progress, 65)

  ButtonGadget(#Gadget_System, 10, 170, 80, 28, "System")
  ButtonGadget(#Gadget_Light, 95, 170, 80, 28, "Light")
  ButtonGadget(#Gadget_Dark, 180, 170, 80, 28, "Dark")
  ButtonGadget(#Gadget_Blue, 265, 170, 80, 28, "Blue")
  ButtonGadget(#Gadget_Forest, 350, 170, 80, 28, "Forest")

  ButtonGadget(#Gadget_WindowColor, 10, 210, 110, 28, "Window Color")
  ButtonGadget(#Gadget_PanelColor, 125, 210, 110, 28, "Panel Color")
  ButtonGadget(#Gadget_TextColor, 240, 210, 110, 28, "Text Color")
  ButtonGadget(#Gadget_AccentColor, 355, 210, 110, 28, "Accent Color")

  ApplyThemeToExample()

  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Gadget_System
            HandyThemeApplyPreset(@AppTheme, #HandyTheme_System)
          Case #Gadget_Light
            HandyThemeApplyPreset(@AppTheme, #HandyTheme_Light)
          Case #Gadget_Dark
            HandyThemeApplyPreset(@AppTheme, #HandyTheme_Dark)
          Case #Gadget_Blue
            HandyThemeApplyPreset(@AppTheme, #HandyTheme_Blue)
          Case #Gadget_Forest
            HandyThemeApplyPreset(@AppTheme, #HandyTheme_Forest)
          Case #Gadget_WindowColor
            HandyThemePickColor(@AppTheme, #HandyTheme_ColorWindow)
          Case #Gadget_PanelColor
            HandyThemePickColor(@AppTheme, #HandyTheme_ColorPanel)
          Case #Gadget_TextColor
            HandyThemePickColor(@AppTheme, #HandyTheme_ColorText)
          Case #Gadget_AccentColor
            HandyThemePickColor(@AppTheme, #HandyTheme_ColorAccent)
        EndSelect
        ApplyThemeToExample()
    EndSelect
  ForEver
EndIf
