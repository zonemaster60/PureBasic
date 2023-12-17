;@title DocMaker Demo
;@author Marcus 'MAC' Röckendorf
;@version 1.0

;@ This is a program for demonstration purposes. It doesn't make any sense.

;----------------------------------------
;- ENUMERATIONS
;----------------------------------------

;- Mathematical functions

Enumeration
  ;@name Mathematical functions
  ;@ The constants here define several different mathematical functions.
  #Math_Addition                          ; Defines an addition
  #Math_Substraction                      ; Defines a subtraction
  #Math_Multiplication                    ; Defines a multiplication
  #Math_Division                          ; Defines a division
EndEnumeration

;----------------------------------------
;- PROCEDURES
;----------------------------------------

Procedure DocMakerTest(SomeText.s, Value.i=0)
  ;@ This is a procedure to test DocMaker's functionality. The image is a picture of Looky Lindwurm, the star of the upcoming 3D point&click adventure game "Wormventures - Barrier 51". It is just here to show the inclusion of images into the documentation.

  ;@param SomeText Some text to give to the procedure.
  ;@param Value A value to give the procedure as a parameter. <i>(optional)</i>

  ;@return This procedure returns nothing.
  
  ;@image Looky_2.png

  Debug "The text: "+SomeText
  Debug "Given Value: "+Value
EndProcedure

;----------------------------------------
;@chapter Math functions
;@ This chapter contains mathematical functions. Chapters can be switched with the <b>chapter</b> tag.

Procedure Addition(Value1.i, Value2.i)
  ;@ This procedure adds the given values and returns the result.
  
  ;@param Value1 The first value to process.
  ;@param Value2 The second value to process.
  
  ;@return The procedure returns the sum of the given values.
  
  ;@link proc Subtraction()
  ;@link proc Multiplication()
  ;@link proc Division()
  
  ;@code Debug Addition(12, 5)
  ;@code ; Will print 17 to the console
  
  ProcedureReturn Value1 + Value2
EndProcedure

Procedure Subtraction(Value1.i, Value2.i)
  ;@ This procedure subtracts the given values and returns the result.
  
  ;@param Value1 The first value to process.
  ;@param Value2 The second value to process.
  
  ;@return The procedure returns the difference of the given values.
  
  ;@link proc Addition()
  ;@link proc Multiplication()
  ;@link proc Division()
  
  ;@code Debug Subtraction(12, 5)
  ;@code ; Will print 7 to the console

  ProcedureReturn Value1 - Value2
EndProcedure

Procedure Multiplication(Value1.i, Value2.i)
  ;@ This procedure multiplicates the given values and returns the result.
  
  ;@param Value1 The first value to process.
  ;@param Value2 The second value to process.
  
  ;@return The procedure returns the product of the given values.
  
  ;@link proc Addition()
  ;@link proc Subtraction()
  ;@link proc Division()
  
  ;@code Debug Multiplication(12, 5)
  ;@code ; Will print 60 to the console

  ProcedureReturn Value1 * Value2
EndProcedure

Procedure Division(Value1.i, Value2.i)
  ;@ This procedure divides the given values and returns the result.
  
  ;@param Value1 The first value to process.
  ;@param Value2 The second value to process.
  
  ;@return The procedure returns the division of the given values.
  
  ;@link proc Addition()
  ;@link proc Subtraction()
  ;@link proc Multiplication()
  
  ;@code Debug Division(60, 5)
  ;@code ; Will print 12 to the console

  ProcedureReturn Value1 / Value2
EndProcedure


; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 28
; Folding = -
; EnableXP