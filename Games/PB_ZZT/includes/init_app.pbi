;------------------------------------------------------------------------------
; App init helpers (extracted from pbzt.pb)
;------------------------------------------------------------------------------

Procedure InitAppCore()
  If InitSprite() = 0 Or InitKeyboard() = 0
    MessageRequester(#APP_NAME, "InitSprite/InitKeyboard failed.")
    End
  EndIf

  InitSfxSystem()

  InitPrefsAndApply()

  InitVGAPalette()
  ResetRules()

  ; Apply loaded sound tuning to the generated SFX cache.
  If SfxReady
    BuildSfxCache()
  EndIf
EndProcedure
