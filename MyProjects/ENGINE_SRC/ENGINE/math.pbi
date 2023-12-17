;basic inlcude for math operations:

Procedure E_MATH_CHECK_IF_INTEGER_DIVIDE_BY_TWO(_value.i)
  ;simple and fast check if a given number is a true number/2
  Define _result.i
  
  _result.i=_value.i/2
  
  _result.i=_result.i*2
  
  If _result.i<_value.i
    ;number is not integer dividable by two
    ProcedureReturn #False
  EndIf
  
  ;number is integer divideable by 2 without rest
  ProcedureReturn #True
  
EndProcedure




