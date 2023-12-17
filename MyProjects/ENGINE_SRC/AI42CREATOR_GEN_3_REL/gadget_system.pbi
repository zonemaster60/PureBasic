
Procedure E_ADD_OBJECT_GADGET()
  Define _flip_flop.b=0
  Define _max_per_height.i=creator\creator_max_row ;give this to script is all works 
  Define _actual_height.i
  Define _next_row.i=0
  Define _next_collum.i=0
 creator\creator_color_object_key=RGB(50,50,50)
 creator\creator_color_object_key_text=RGB(255,255,255)
 creator\creator_color_object_value=RGB(100,100,100)
 creator\creator_color_object_value_text=RGB(255,255,255)
 
  global_gadget\base_id=global_gadget\id+1
  
  While global_gadget\id<creator\creator_max_text_gadget
    
    If AddElement(object_gadget())=0
      E_ERROR(#ERROR_OBJECT_GADGET)
      ProcedureReturn #False
    EndIf
    
    global_gadget\id+1
    
    object_gadget()\pos_x=creator\creator_text_gadget_w*_next_collum.i+creator\creator_text_gadget_offset_x
    object_gadget()\pos_y=creator\creator_text_gadget_h*_next_row.i+creator\creator_text_gadget_offset_x
    object_gadget()\w=creator\creator_text_gadget_w
    object_gadget()\h=creator\creator_text_gadget_h
    StringGadget(global_gadget\id,object_gadget()\pos_x,object_gadget()\pos_y,object_gadget()\w,object_gadget()\h,"",#PB_String_BorderLess )
    object_gadget()\id=global_gadget\id
    
    If IsGadget(object_gadget()\id)=0
      E_ERROR(#ERROR_OBJECT_GADGET)
      ProcedureReturn #False
    EndIf
    
 If _flip_flop=0
      SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,creator\creator_color_object_key)
      SetGadgetColor( global_gadget\id,#PB_Gadget_FrontColor,creator\creator_color_object_key_text)
      object_gadget()\type=#KEY
  EndIf
  
  If _flip_flop=1
    SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor, creator\creator_color_object_value)
    SetGadgetColor( global_gadget\id,#PB_Gadget_FrontColor, creator\creator_color_object_value_text)
    object_gadget()\type=#VALUE
 EndIf
    
    _flip_flop.b=1-_flip_flop.b
 
    _actual_height.i+1
    _next_row+1
    If _actual_height.i>=_max_per_height.i
       _actual_height.i=0
       _next_collum.i+1
       _next_row.i=0
    EndIf
    
  Wend
  
EndProcedure

Procedure E_ADD_SCROLL_AREA_GADGET()
  
  global_gadget\id=0
  global_gadget\pos_x=creator_window\window_x
  global_gadget\pos_x=creator_window\window_y
  global_gadget\w=creator_window\window_widht
  global_gadget\h=creator_window\window_height
  ScrollAreaGadget(global_gadget\id,global_gadget\pos_x,global_gadget\pos_y,WindowWidth(creator_window\window_id)-8,WindowHeight(creator_window\window_id)-32,global_gadget\w*16,global_gadget\h*16)
  
   If IsGadget(global_gadget\id)=0
     E_ERROR(#ERROR_PANEL_CREATE)
    ProcedureReturn #False
  EndIf
  E_ADD_OBJECT_GADGET()
  CloseGadgetList()
  
EndProcedure




; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 76
; FirstLine = 48
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