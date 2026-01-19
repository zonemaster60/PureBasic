EnableExplicit

DeclareModule Vec2
  Structure T
    x.f
    y.f
  EndStructure

  Declare Make(*out.T, x.f, y.f)
  Declare Add(*out.T, *a.T, *b.T)
  Declare Scale(*out.T, *v.T, s.f)
EndDeclareModule

Module Vec2
  Procedure Make(*out.T, x.f, y.f)
    *out\x = x
    *out\y = y
  EndProcedure

  Procedure Add(*out.T, *a.T, *b.T)
    *out\x = *a\x + *b\x
    *out\y = *a\y + *b\y
  EndProcedure

  Procedure Scale(*out.T, *v.T, s.f)
    *out\x = *v\x * s
    *out\y = *v\y * s
  EndProcedure
EndModule
