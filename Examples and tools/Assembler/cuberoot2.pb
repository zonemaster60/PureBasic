;Cubic Root, Double Precision
;PB 5.21 LTS (x64)
;I use Heron: Loop {x = x * (((x * x * x) + 2 * a) / ((2 * x * x * x) + a))}

Test_Value.d = -12345.6789   ;Cubic_Root = -23,112042408247961097779983746659
Appr.d                       ;for all...

Procedure.d Cube_Root()
  !mov rax,[v_Test_Value]
  !mov rdx,7FFFFFFFFFFFFFFFh
  !and rax,rdx               ;approximation without sign
  ;now find a good approximation for the start-value; http://metamerist.com/cbrt/cbrt.htm - Kahan´s bit hack
  !mov [v_Appr],rax
  !movsd xmm0,[v_Appr]  
  !movsd xmm1,xmm0
  !lea rdx,[v_Appr]
  !mov rax,[rdx]
  !xor rdx,rdx
  !div qword[Value3]
  !add rax,[BitHack]
  !mov [v_Appr],rax
  !movsd xmm2,[v_Appr]

  !addsd xmm1,xmm1           ;xmm1=2*a=constant
  !mov ecx,2                 ;higher=more precision (if possible)
 !@@:  
  !movsd xmm3,xmm2
  !mulsd xmm3,xmm3
  !mulsd xmm3,xmm2           ;xmm3=x*x*x
  !movsd xmm4,xmm3 
  !addsd xmm4,xmm4           ;2*x*x*x
  !addsd xmm4,xmm0           ;xmm0=a
  !addsd xmm3,xmm1 
  !divsd xmm3,xmm4
  !mulsd xmm2,xmm3
  !dec ecx  
 !jnz @b  
  ;set sign (if Test_Value negativ)
  !test byte[v_Test_Value+7],80h
 !jz @f
  !mulsd xmm2,[Minus1]       ;restore sign
 !@@:
  !movsd qword[v_Appr],xmm2
  !fld qword[v_Appr]
 ProcedureReturn
  !Minus1:  dq -1.0 
  !BitHack: dq 3071306043645493248     ;715094163<<32, for Kahan´s bit hack; http://metamerist.com/cbrt/cbrt.htm
  !Value3:  dq 3
EndProcedure

TA = ElapsedMilliseconds()
For i = 1 To 10000000
  Cbrt.d = Cube_Root()
Next
TE = ElapsedMilliseconds() - TA
MessageRequester("Cubic Root (Double-Precision) with SSE2", StrD(Cbrt, 15) + #LFCR$ + Str(TE) + " ms for 10000000 Loops")
; IDE Options = PureBasic 6.11 LTS Beta 2 (Windows - x64)
; CursorPosition = 55
; Folding = -
; EnableXP
; DPIAware