;
; HandyTheme_Reusable.pbi
; Standalone PureBasic theme helper for reuse in other projects.
;
; Basic usage:
;   IncludeFile "HandyTheme_Reusable.pbi"
;   Global AppTheme.HandyThemePalette
;   HandyThemeApplyPreset(@AppTheme, #HandyTheme_Dark)
;   HandyThemeApplyWindow(@AppTheme, #Window_Main)
;   HandyThemeApplyGadget(@AppTheme, #Gadget_Title, #True)
;
; For custom colors:
;   HandyThemePickColor(@AppTheme, #HandyTheme_ColorWindow)
;   HandyThemeApplyWindow(@AppTheme, #Window_Main)
;
; For preferences, call HandyThemeWritePreferences() while your preferences file is open,
; and call HandyThemeReadPreferences() after PreferenceGroup() is selected.
;

#HandyTheme_COLOR_WINDOW = 5
#HandyTheme_COLOR_WINDOWTEXT = 8
#HandyTheme_COLOR_HIGHLIGHT = 13
#HandyTheme_COLOR_BTNFACE = 15

Enumeration
  #HandyTheme_System
  #HandyTheme_Light
  #HandyTheme_Dark
  #HandyTheme_Blue
  #HandyTheme_Forest
  #HandyTheme_Custom
EndEnumeration

Enumeration
  #HandyTheme_ColorWindow
  #HandyTheme_ColorPanel
  #HandyTheme_ColorText
  #HandyTheme_ColorAccent
EndEnumeration

Structure HandyThemePalette
  preset.i
  windowColor.i
  panelColor.i
  textColor.i
  accentColor.i
EndStructure

Procedure.i HandyThemeSystemColor(index.i)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ProcedureReturn GetSysColor_(index)
  CompilerElse
    Select index
      Case #HandyTheme_COLOR_WINDOWTEXT
        ProcedureReturn RGB(32, 35, 39)
      Case #HandyTheme_COLOR_HIGHLIGHT
        ProcedureReturn RGB(0, 120, 215)
      Case #HandyTheme_COLOR_BTNFACE
        ProcedureReturn RGB(245, 247, 250)
      Default
        ProcedureReturn RGB(255, 255, 255)
    EndSelect
  CompilerEndIf
EndProcedure

Procedure HandyThemeApplyPreset(*theme.HandyThemePalette, preset.i)
  If *theme = 0
    ProcedureReturn
  EndIf

  *theme\preset = preset

  Select preset
    Case #HandyTheme_Light
      *theme\windowColor = RGB(245, 247, 250)
      *theme\panelColor = RGB(255, 255, 255)
      *theme\textColor = RGB(32, 35, 39)
      *theme\accentColor = RGB(0, 120, 215)

    Case #HandyTheme_Dark
      *theme\windowColor = RGB(32, 32, 36)
      *theme\panelColor = RGB(45, 45, 50)
      *theme\textColor = RGB(235, 235, 235)
      *theme\accentColor = RGB(86, 156, 214)

    Case #HandyTheme_Blue
      *theme\windowColor = RGB(225, 238, 252)
      *theme\panelColor = RGB(244, 249, 255)
      *theme\textColor = RGB(21, 45, 75)
      *theme\accentColor = RGB(0, 99, 177)

    Case #HandyTheme_Forest
      *theme\windowColor = RGB(226, 238, 225)
      *theme\panelColor = RGB(246, 250, 245)
      *theme\textColor = RGB(31, 57, 35)
      *theme\accentColor = RGB(47, 125, 64)

    Default
      *theme\preset = #HandyTheme_System
      *theme\windowColor = HandyThemeSystemColor(#HandyTheme_COLOR_BTNFACE)
      *theme\panelColor = HandyThemeSystemColor(#HandyTheme_COLOR_WINDOW)
      *theme\textColor = HandyThemeSystemColor(#HandyTheme_COLOR_WINDOWTEXT)
      *theme\accentColor = HandyThemeSystemColor(#HandyTheme_COLOR_HIGHLIGHT)
  EndSelect
EndProcedure

Procedure HandyThemeInitialize(*theme.HandyThemePalette)
  If *theme = 0
    ProcedureReturn
  EndIf

  If *theme\preset < #HandyTheme_System Or *theme\preset > #HandyTheme_Custom
    *theme\preset = #HandyTheme_System
  EndIf

  If *theme\preset <> #HandyTheme_Custom
    HandyThemeApplyPreset(*theme, *theme\preset)
  ElseIf *theme\windowColor = 0 And *theme\panelColor = 0 And *theme\textColor = 0 And *theme\accentColor = 0
    HandyThemeApplyPreset(*theme, #HandyTheme_System)
  EndIf
EndProcedure

Procedure HandyThemeApplyWindow(*theme.HandyThemePalette, window.i)
  If *theme And IsWindow(window)
    SetWindowColor(window, *theme\windowColor)
  EndIf
EndProcedure

Procedure HandyThemeApplyGadget(*theme.HandyThemePalette, gadget.i, useWindowBackground.i = #False)
  Protected backColor.i

  If *theme = 0 Or IsGadget(gadget) = 0
    ProcedureReturn
  EndIf

  If useWindowBackground
    backColor = *theme\windowColor
  Else
    backColor = *theme\panelColor
  EndIf

  SetGadgetColor(gadget, #PB_Gadget_BackColor, backColor)
  SetGadgetColor(gadget, #PB_Gadget_FrontColor, *theme\textColor)
EndProcedure

Procedure HandyThemeApplyProgress(*theme.HandyThemePalette, gadget.i)
  If *theme = 0 Or IsGadget(gadget) = 0
    ProcedureReturn
  EndIf

  SetGadgetColor(gadget, #PB_Gadget_BackColor, *theme\panelColor)
  SetGadgetColor(gadget, #PB_Gadget_FrontColor, *theme\accentColor)
EndProcedure

Procedure.i HandyThemePickColor(*theme.HandyThemePalette, colorKind.i)
  Protected currentColor.i
  Protected pickedColor.i

  If *theme = 0
    ProcedureReturn #False
  EndIf

  Select colorKind
    Case #HandyTheme_ColorWindow
      currentColor = *theme\windowColor
    Case #HandyTheme_ColorPanel
      currentColor = *theme\panelColor
    Case #HandyTheme_ColorText
      currentColor = *theme\textColor
    Default
      currentColor = *theme\accentColor
  EndSelect

  pickedColor = ColorRequester(currentColor)
  If pickedColor = -1
    ProcedureReturn #False
  EndIf

  *theme\preset = #HandyTheme_Custom
  Select colorKind
    Case #HandyTheme_ColorWindow
      *theme\windowColor = pickedColor
    Case #HandyTheme_ColorPanel
      *theme\panelColor = pickedColor
    Case #HandyTheme_ColorText
      *theme\textColor = pickedColor
    Default
      *theme\accentColor = pickedColor
  EndSelect

  ProcedureReturn #True
EndProcedure

Procedure HandyThemeReadPreferences(*theme.HandyThemePalette)
  If *theme = 0
    ProcedureReturn
  EndIf

  *theme\preset = ReadPreferenceInteger("ThemePreset", #HandyTheme_System)
  *theme\windowColor = ReadPreferenceInteger("ThemeWindowColor", 0)
  *theme\panelColor = ReadPreferenceInteger("ThemePanelColor", 0)
  *theme\textColor = ReadPreferenceInteger("ThemeTextColor", 0)
  *theme\accentColor = ReadPreferenceInteger("ThemeAccentColor", 0)
  HandyThemeInitialize(*theme)
EndProcedure

Procedure HandyThemeWritePreferences(*theme.HandyThemePalette)
  If *theme = 0
    ProcedureReturn
  EndIf

  WritePreferenceInteger("ThemePreset", *theme\preset)
  WritePreferenceInteger("ThemeWindowColor", *theme\windowColor)
  WritePreferenceInteger("ThemePanelColor", *theme\panelColor)
  WritePreferenceInteger("ThemeTextColor", *theme\textColor)
  WritePreferenceInteger("ThemeAccentColor", *theme\accentColor)
EndProcedure
