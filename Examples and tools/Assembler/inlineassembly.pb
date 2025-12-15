DeclareModule MyModule
    LabelDeclareModule: ;Its name is mymodule.l_labeldeclaremodule:
    Declare Init()
  EndDeclareModule

  Module MyModule
    Procedure Init() 
      LabelModuleProcedure: ; Its name is mymodule.ll_init_labelmoduleprocedure: 
      Debug "InitFerrari()"  
    EndProcedure
  
    LabelModule1: ;Its name is mymodule.l_labelmodule1:
  EndModule

  Procedure Test (*Pointer, Variable)
    TokiSTART:  ;Its name is ll_test_tokistart:
  
    ! MOV dword [p.p_Pointer], 20
    ! MOV dword [p.v_Variable], 30
    Debug *Pointer  ;Its name is p.p_Pointer
    Debug Variable  ;Its name is p.v_Variable
  EndProcedure
  
  VAR=1                       ;Its name is v_VAR
  *Pointt=AllocateMemory(10)  ;Its name is p_Pointt
  
  MyModule::Init()
  Test(0,0)

  Label1: ;Its name is l_label1:
  
  !jmp l_labelend ; An instruction in assembler has to use the rules above. Here it's l_namelabel
  ;...
  LabelEnd: ;Its name is l_labelend:
; IDE Options = PureBasic 6.02 beta 2 LTS (Windows - x64)
; CursorPosition = 33
; FirstLine = 8
; Folding = -
; EnableXP
; DPIAware