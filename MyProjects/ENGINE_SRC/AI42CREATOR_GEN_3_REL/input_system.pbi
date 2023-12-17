;here we have some usefull routines to control / interact with the gadgets
; some sort of search/check out objects with similar object_names

Procedure E_HIGHLIGHT_OBJECTS_IN_TOUCH(_selected_gadget.i)
  ;this routine will try to show you all objects with similar entries/names:
  
  Define _search_for.s=""
  Define _find.i=0
  
If FindString(GetGadgetText(_selected_gadget.i),creator\creator_object_key_word)=0 ;init search only if global keyword for the object is found in gadgettext
  ProcedureReturn #False   
EndIf

E_SAVE_AUTO_FOR_HIGHLIGHT_FUNCTION()

 _find.i=FindString(GetGadgetText(_selected_gadget.i),creator\creator_object_key_word)
 _search_for.s=Mid(GetGadgetText(_selected_gadget.i),Len(creator\creator_object_key_word),creator\creator_search_size)

  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),_search_for.s)>0
      SetGadgetColor(global_gadget\id,#PB_Gadget_BackColor,RGB(233, 115, 21))
    EndIf
       
    global_gadget\id+1
  Wend
  
  EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 27
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0