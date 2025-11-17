;Cubic Root, Single Precision
;PB 5.21 LTS (x64)
;I use Heron: Loop {x = x * (((x * x * x) + 2 * a) / ((2 * x * x * x) + a))}

Test_Value.f = -12345.6789   ;Cubic_Root = -23,112042408247961097779983746659
Appr.f                       ;for all...

Procedure.f Cube_Root()
  !mov eax,[v_Test_Value]
  !and eax,7FFFFFFFh         ;approximation without sign
  ;now find a good approximation for the start-value; http://metamerist.com/cbrt/cbrt.htm - Kahan´s bit hack
  !mov [v_Appr],eax
  !movss xmm0,[v_Appr]  
  !movss xmm1,xmm0
  !lea rdx,[v_Appr]
  !mov eax,[rdx]
  !xor edx,edx
  !div dword[Value3]
  !add eax,[BitHack]
  !mov [v_Appr],eax
  !movss xmm2,[v_Appr]

  !addss xmm1,xmm1           ;xmm1=2*a=constant
  !mov ecx,2                 ;higher=more precision (if possible)
 !@@:  
  !movss xmm3,xmm2
  !mulss xmm3,xmm3
  !mulss xmm3,xmm2           ;xmm3=x*x*x
  !movss xmm4,xmm3 
  !addss xmm4,xmm4           ;2*x*x*x
  !addss xmm4,xmm0           ;xmm0=a 
  !addss xmm3,xmm1 
  !divss xmm3,xmm4
  !mulss xmm2,xmm3
  !dec ecx  
 !jnz @b  
  ;set sign (if Test_Value negativ)
  !test byte[v_Test_Value+3],80h
 !jz @f
  !mulss xmm2,[Minus1]       ;restore sign
 !@@:
  !movss dword[v_Appr],xmm2
  !fld dword[v_Appr]
 ProcedureReturn
  !Minus1:  dd -1.0 
  !BitHack: dd 709921077     ;for Kahan´s bit hack; http://metamerist.com/cbrt/cbrt.htm
  !Value3:  dd 3
EndProcedure

TA = ElapsedMilliseconds()
For i = 1 To 10000000
  Cbrt.f = Cube_Root()
Next
TE = ElapsedMilliseconds() - TA
MessageRequester("Cubic Root (Single-Precision) with SSE", StrF(Cbrt, 7) + #LFCR$ + Str(TE) + " ms for 10000000 Loops") 

; IDE Options = PureBasic 6.11 LTS Beta 2 (Windows - x64)
; CursorPosition = 55
; Folding = -
; EnableXP
; DPIAware