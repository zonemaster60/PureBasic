;here is the input output stuff:

Declare E_CHECK_EVENT(void)

Procedure E_RESORT_DNA_FUNDAMENT()
  
ResetList(dna_fundament())
SortStructuredList(dna_fundament(), #PB_Sort_Ascending ,OffsetOf(dna_fundament\dna_string),TypeOf(dna_fundament\dna_string))  ;make an alphabetical order!
  
EndProcedure

Procedure E_SET_AI_GFX_VALUES()
  ;here we go for some infos needed by the mapcreator
  
  ;search for the full path info:
  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_source#")<>0
      SetGadgetText(global_gadget\id+1,GetPathPart(creator\creator_gfx_file_path))
      SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,RGB(32, 166, 25))  
      Break
    EndIf
    global_gadget\id+1
  Wend
    
   global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_file#")<>0
      SetGadgetText(global_gadget\id+1,creator\creator_gfx_file_part)
      SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,RGB(32, 166, 25))  
      Break
    EndIf
    global_gadget\id+1
  Wend
  
     global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_type#")<>0
      SetGadgetText(global_gadget\id+1,creator\creator_gfx_suffix)
      SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,RGB(32, 166, 25))  
      Break
    EndIf
    global_gadget\id+1
  Wend
  
EndProcedure

Procedure E_DRAW_GFX_NO_GFX()  
  
  If IsImage(creator\creator_gfx_id)
        FreeImage(creator\creator_gfx_id)
  EndIf
  
  SetWindowColor(creator_window\window_child_id, RGB(0,0,0)) 
  StartDrawing(WindowOutput(creator_window\window_child_id))
  Box(0,0,WindowWidth(creator_window\window_child_id)*DesktopResolutionX(),WindowHeight(creator_window\window_child_id)*DesktopResolutionY(),RGB(50,50,50))
  StopDrawing()
  
EndProcedure

Procedure E_DRAW_GFX_NOT_FOUND()
  
    SetWindowTitle(creator_window\window_child_id,"GFX: ")

  SetWindowColor(creator_window\window_child_id, RGB(0,0,0)) 
  StartDrawing(WindowOutput(creator_window\window_child_id))
  Box(0,0,WindowWidth(creator_window\window_child_id)*DesktopResolutionX(),WindowHeight(creator_window\window_child_id)*DesktopResolutionY(),RGB(50,50,50))
  StopDrawing()
  
EndProcedure

Procedure E_DRAW_HIT_BOX()
  Define _search_for.s=""
  
  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    _search_for.s=Left(GetGadgetText(global_gadget\id),FindString(GetGadgetText(global_gadget\id),".")-1)
    
    Select _search_for.s
        
      Case "object_hit_box_w"
        
        global_gadget\id+1  ;no check here..... too lacy, must be valid or die!
        show_hit_box\hit_box_w=ValF(GetGadgetText(global_gadget\id))
        
      Case "object_hit_box_h"
        global_gadget\id+1  
        show_hit_box\hit_box_h=ValF(GetGadgetText(global_gadget\id))
        
      Case "object_hit_box_x"
        global_gadget\id+1 
        show_hit_box\hit_box_x=ValF(GetGadgetText(global_gadget\id))
        
      Case "object_hit_box_y"
        global_gadget\id+1 
        show_hit_box\hit_box_y=ValF(GetGadgetText(global_gadget\id))
        
    EndSelect
        
  global_gadget\id+1  
  Wend
  
  If show_hit_box\hit_box_w<1
    show_hit_box\hit_box_w=ImageWidth(creator\creator_gfx_id)
    
  EndIf
  
  If show_hit_box\hit_box_h<1
    show_hit_box\hit_box_h=ImageHeight(creator\creator_gfx_id)
  EndIf
  
  StartDrawing(WindowOutput(creator_window\window_child_id))
  DrawingMode(#PB_2DDrawing_Outlined)
  Box(show_hit_box\hit_box_x,show_hit_box\hit_box_y,show_hit_box\hit_box_w,show_hit_box\hit_box_h,RGB(255,0,0))
  StopDrawing()
  
EndProcedure

Procedure E_DRAW_GFX()
  SetWindowColor(creator_window\window_child_id, RGB(50,50,50)) 
  StartDrawing(WindowOutput(creator_window\window_child_id))
  Box(0,0,WindowWidth(creator_window\window_child_id)*DesktopResolutionX(),WindowHeight(creator_window\window_child_id)*DesktopResolutionY(),RGB(50,50,50))
  If IsImage(creator\creator_gfx_id)
    DrawAlphaImage(ImageID(creator\creator_gfx_id),0,0)
  Else
    StopDrawing()
    E_DRAW_GFX_NOT_FOUND()
    ProcedureReturn #False
  EndIf
  StopDrawing()
  E_DRAW_HIT_BOX()
  
EndProcedure

Procedure E_SET_GFX()
  
  creator\creator_gfx_file_path=OpenFileRequester("SET GFX",creator\creator_gfx_file_path,"PNG (*.png)|*.png|BMP (*.bmp)|*.bmp|GIF (*.gif)|all (*.*)|*.*",0)
  If Len(creator\creator_gfx_file_path)=0
  ProcedureReturn #False  
  EndIf
  
  If IsImage(creator\creator_gfx_id)
     FreeImage(creator\creator_gfx_id)
   EndIf

  creator\creator_gfx_id=LoadImage(#PB_Any,creator\creator_gfx_file_path,#PB_Sprite_AlphaBlending)
  
  If IsImage(creator\creator_gfx_id)=0
    E_ERROR(#WARNING_CANNOT_LOAD_GFX)
    E_DRAW_GFX_NOT_FOUND()
  ProcedureReturn #False  
  EndIf
  
  creator\creator_gfx_file_part=GetFilePart(creator\creator_gfx_file_path,#PB_FileSystem_NoExtension)
  creator\creator_gfx_suffix=GetExtensionPart(creator\creator_gfx_file_path)
  creator\creator_gfx_file_path=GetPathPart(creator\creator_gfx_file_path)
  E_DRAW_GFX()
  SetActiveWindow(creator_window\window_child_id)
  E_SET_AI_GFX_VALUES()
  creator\creator_last_file=GetPathPart(creator\creator_gfx_file_path)+creator\creator_gfx_file_part+"."+creator\creator_dna_file_suffix
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna))
  SetWindowTitle(creator_window\window_child_id,"GFX: "+creator\creator_gfx_file_part+"."+creator\creator_gfx_suffix+"  "+Str(ImageWidth(creator\creator_gfx_id))+" W  "+Str(ImageHeight(creator\creator_gfx_id))+" H")
EndProcedure

Procedure E_SET_GFX_NO_REQUEST()
    
  If Len(creator\creator_gfx_file_path)=0
  ProcedureReturn #False  
  EndIf 
  
  If IsImage((creator\creator_gfx_id))
     FreeImage((creator\creator_gfx_id))
  EndIf

  creator\creator_gfx_id=LoadImage(#PB_Any,creator\creator_gfx_file_path,#PB_Sprite_AlphaBlending)
  
  If IsImage(creator\creator_gfx_id)=0
     E_ERROR(#WARNING_CANNOT_LOAD_GFX)
  ProcedureReturn #False  
  EndIf
  
  E_DRAW_GFX()
  SetActiveWindow(creator_window\window_child_id)
  E_SET_AI_GFX_VALUES()
  creator\creator_last_file=GetPathPart(creator\creator_gfx_file_path)+creator\creator_gfx_file_part+"."+creator\creator_dna_file_suffix
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna))
  SetWindowTitle(creator_window\window_child_id,"GFX: "+creator\creator_gfx_file_part+"."+creator\creator_gfx_suffix+"  "+Str(ImageWidth(creator\creator_gfx_id))+" W   "+Str(ImageHeight(creator\creator_gfx_id))+" H")

EndProcedure

Procedure E_GET_GFX_OUT_OF_DNA()
  
    global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_source#")<>0
      ;creator\creator_gfx_file_path=GetPathPart(GetGadgetText(global_gadget\id+1))
      Break
    EndIf
    global_gadget\id+1
  Wend
   
   global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_file#")<>0
      creator\creator_gfx_file_part=GetGadgetText(global_gadget\id+1)
      Break
    EndIf
    global_gadget\id+1
  Wend
  
     global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),"object_type#")<>0
       creator\creator_gfx_suffix=GetGadgetText(global_gadget\id+1)
      Break
    EndIf
    global_gadget\id+1
  Wend 
  
  creator\creator_gfx_file_path+creator\creator_gfx_file_part+"."+creator\creator_gfx_suffix
  
EndProcedure

Procedure E_DNA_BASE_SAFE_SORTED()
  ;this routine sets the fundament for keywords (dna) used in the DNA systen,
  ;only keywords registred in this file will be used (DNA file only fills with DNA found in the fundament)
  Define  _file_id.i=0
  
  If ListSize(dna_fundament())<1
    E_ERROR(#WARNING_DNA_SAVE)
  ProcedureReturn #False  
  EndIf
  
  _file_id.i=CreateFile(#PB_Any,creator\creator_default_object_file+".fundament")
  
  If IsFile(_file_id.i)=0
    E_ERROR(#WARNING_DNA_SAVE_FUNDAMENT)
  ProcedureReturn #False   
EndIf

E_RESORT_DNA_FUNDAMENT()

ForEach dna_fundament()
  
WriteStringN(_file_id.i,dna_fundament()\dna_string)  
  
Next

  CloseFile(_file_id.i)  
  
EndProcedure

Procedure E_DNA_BASE_LOAD()
  ;this is always active if something changed, so we have allway the actuall version of the DNA
  
  Define  _file_id.i=0
  Define _dummy.s=""
  
 _file_id.i=ReadFile(#PB_Any,creator\creator_default_object_file+".fundament")
  If IsFile(_file_id.i)=0
   E_ERROR(#WARNING_DNA) 
  ProcedureReturn #False  
EndIf

;here we go:

If ListSize(dna_fundament())>0
ClearList(dna_fundament())  
EndIf

While Not Eof(_file_id)
  
  _dummy.s=Trim(ReadString(_file_id.i))
  
  If FindString(_dummy.s,creator\creator_object_key_word)<>0
  
  If AddElement(dna_fundament())=0
    E_ERROR(#WARNING_DNA) 
  EndIf
  
  dna_fundament()\dna_string=_dummy.s
    
EndIf  
  
Wend
CloseFile(_file_id.i)
E_RESORT_DNA_FUNDAMENT()

EndProcedure

Procedure E_RESET_GADGET_COLORS()
  ;bevor we load a new we go this way:
  
  Define _flip_flop.b=0
  
  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
  
   If _flip_flop=0
      SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,creator\creator_color_object_key)
      SetGadgetColor( global_gadget\id,#PB_Gadget_FrontColor,creator\creator_color_object_key_text)
      
      If IsGadget(global_gadget\id+1)
        If  Len(GetGadgetText(global_gadget\id+1))>0
           SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,RGB(32, 166, 25))  
        EndIf
        
        EndIf
            
  EndIf
  
  If _flip_flop=1
    SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,creator\creator_color_object_value)
    SetGadgetColor( global_gadget\id,#PB_Gadget_FrontColor,creator\creator_color_object_key_text)
  EndIf
    
  _flip_flop.b=1-_flip_flop.b
  
  global_gadget\id+1
Wend

EndProcedure

Procedure E_RESET_GADGET_KEY_VALUES()
  
  global_gadget\id=global_gadget\base_id
   
  While IsGadget(global_gadget\id)
    SetGadgetText(global_gadget\id,"") 
   global_gadget\id+1 
  Wend

EndProcedure

; Procedure E_GET_GFX()
;   
;   ;here we go threw the gadget texts and get the values:
;   
;   global_gadget\id=global_gadget\base_id
;  
;   While IsGadget(global_gadget\id)
; 
;     If IsGadget(global_gadget\id)
;        If FindString(Trim(GetGadgetText(global_gadget\id)),"object_type#")<>0
;          creator\creator_gfx_suffix="."+GetGadgetText(global_gadget\id+1)
;          creator\creator_gfx_file_path=GetFilePart(creator\creator_last_file,#PB_FileSystem_NoExtension)+creator\creator_gfx_suffix
;         ProcedureReturn #False ;got it
;       EndIf      
;       
;     EndIf
;     
;     global_gadget\id+1
;     
;   Wend
;   
; EndProcedure

Procedure E_PARSE_AI42_LOAD_MULTISCAN(_file.s)
  
  Define _found.b=#False
  Define _file_id.i=0
  Define _dummy.s=""
  Define _inject.s=""
   
 If ListSize(dna_fundament())<1  
   E_ERROR(#WARNING_DNA_LOAD_FUNDAMENT)
   ProcedureReturn #False
 EndIf
 
 global_gadget\id=global_gadget\base_id
 
 E_RESORT_DNA_FUNDAMENT()
 
 ResetList(dna_fundament())
 
 ForEach dna_fundament()
   
 _file_id.i=ReadFile(#PB_Any,_file.s)
 
If IsFile(_file_id.i)=0
   E_ERROR(#WARNING_FILE_MISSING)
   ProcedureReturn #False
EndIf

    _inject.s=""
    _found.b=#False  ;we did not found a match

  While Not Eof(_file_id.i)

    _dummy.s=Trim(ReadString(_file_id.i))
       
   If FindString(_dummy.s,creator\creator_object_key_word)<>0  ;is there the right string-part of the DNA key ?
     _inject.s=Trim(dna_fundament()\dna_string) 
     
    If _dummy.s=Trim(dna_fundament()\dna_string)  ;does the _dummy_ meet the DNA sequence?
      
      _found.b=#True  ;we got a match
      _inject.s=""
      
    If IsGadget(global_gadget\id)
      SetGadgetText(global_gadget\id,_dummy.s)  ;first (key)
     creator\creator_objects_in_dna+1
     EndIf
    
    global_gadget\id+1
         
    If IsGadget(global_gadget\id)
      SetGadgetText(global_gadget\id,ReadString(_file_id))  ;value
    EndIf
    
    If Len(GetGadgetText(global_gadget\id))>0
        SetGadgetColor( global_gadget\id-1,#PB_Gadget_BackColor,RGB(32, 166, 25))  
      EndIf

    global_gadget\id+1
    
    FileSeek(_file_id.i, Lof(_file_id.i))  ;we got what we want...for now....jump out, start new...
  
  EndIf
  
EndIf
  
Wend
  
CloseFile(_file_id.i)

;If no object in the DNA file does match, we use this Default object, so we make sure To use a valid DNA Structure, With supported entries onlys

If _found.b=#False And Len(_inject.s)>0
  Debug _inject.s
  
  If IsGadget(global_gadget\id)
    SetGadgetText(global_gadget\id,_inject.s)  ;first (key)
    creator\creator_objects_in_dna+1  
  EndIf
  
  global_gadget\id+1
  
  If IsGadget(global_gadget\id)
    SetGadgetText(global_gadget\id,"")  ;first (key)
  EndIf
  global_gadget\id+1
  
EndIf
  
Next

EndProcedure

Procedure E_PARSE_AI42_DEFAULT_MULTISCAN()
  
  Define _file_id.i=0
  Define _dummy.s=""
  
 If ListSize(dna_fundament())<1  
   E_ERROR(#WARNING_DNA_LOAD_FUNDAMENT)
   ProcedureReturn #False
 EndIf

 global_gadget\id=global_gadget\base_id
 
E_RESORT_DNA_FUNDAMENT()
ResetList(dna_fundament())

 ForEach dna_fundament()
   
    _file_id.i=ReadFile(#PB_Any,creator\creator_default_object_file)
 
 If IsFile(_file_id.i)=0
   E_ERROR(#WARNING_DEFAULT_AI_MISSING)
     ProcedureReturn #False
EndIf

  While Not Eof(_file_id.i)
       
    _dummy.s=Trim(ReadString(_file_id.i))
    
    If FindString(_dummy.s,creator\creator_object_key_word)<>0

    If _dummy.s=dna_fundament()\dna_string  
    
    If IsGadget(global_gadget\id)
      SetGadgetText(global_gadget\id,_dummy.s)  ;first (key)
     creator\creator_objects_in_dna+1
     EndIf
    
    global_gadget\id+1
          
    If IsGadget(global_gadget\id)
      SetGadgetText(global_gadget\id,ReadString(_file_id))  ;value
    EndIf
    
    If FindString(GetGadgetText(global_gadget\id),"#")
        SetGadgetColor( global_gadget\id,#PB_Gadget_BackColor,RGB(32, 166, 25))  ;for some important keys
    EndIf
         
    If Len(GetGadgetText(global_gadget\id))>0
       SetGadgetColor( global_gadget\id-1,#PB_Gadget_BackColor,RGB(79, 191, 221))  
    EndIf
         
   global_gadget\id+1  
  EndIf
EndIf
  
  Wend
  
  CloseFile(_file_id.i)
  
Next

  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna))
  
EndProcedure

Procedure E_SAVE_AI_FILE_FOR_NONE_DNA_OBJECTS(_ai42_file_to_search.s,_ai42_object_name.s,_ai42_object_extension.s)
  
  ;this is a very special routine, to patch setup objects without DNA,give them default DNA data:
  
  Define _file_id.i=0
    
  If Len(_ai42_file_to_search.s)<1
    E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
    ProcedureReturn #False  
  EndIf
  
  _file_id.i=CreateFile(#PB_Any,_ai42_file_to_search.s)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
    ProcedureReturn #False
  EndIf
  creator\creator_objects_in_dna=0
  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
      
    WriteStringN(_file_id.i,GetGadgetText(global_gadget\id))
    
    If FindString(GetGadgetText(global_gadget\id),"object_file#")  
      global_gadget\id+1
      WriteStringN(_file_id.i,_ai42_object_name.s)
    EndIf
    
    If FindString(GetGadgetText(global_gadget\id), "object_source#")
      global_gadget\id+1
      WriteStringN(_file_id.i,GetPathPart(_ai42_file_to_search.s))
    EndIf
    
    If FindString(GetGadgetText(global_gadget\id),"object_type#")
      global_gadget\id+1
      WriteStringN(_file_id.i,_ai42_object_extension.s)
    EndIf
    
    global_gadget\id+1
  Wend
  
  CloseFile(_file_id.i)
  
EndProcedure

Procedure E_SAVE_AI_FILE(_file.s)
    
  Define _file_id.i=0
  
  If Len(_file.s)<1
  E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
  ProcedureReturn #False  
  EndIf
  
  _file_id.i=CreateFile(#PB_Any,_file.s)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
    ProcedureReturn #False
  EndIf
creator\creator_objects_in_dna=0
global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If  FindString(GetGadgetText(global_gadget\id),creator\creator_object_key_word)<>0
      
      If IsGadget(global_gadget\id+1)
      
        If Len(GetGadgetText(global_gadget\id+1))>0
      WriteStringN(_file_id.i,GetGadgetText(global_gadget\id))
      WriteStringN(_file_id.i,GetGadgetText(global_gadget\id+1))
    EndIf
    
  EndIf
EndIf
  
    global_gadget\id+1
  Wend
   
  CloseFile(_file_id.i)
  
EndProcedure

; Procedure orig_E_SAVE_AI_FILE(_file.s);keep this! /remove if all tests work
;   
;   
;   Define _file_id.i=0
;   
;   If Len(_file.s)<1
;   E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
;   ProcedureReturn #False  
;   EndIf
;   
;   _file_id.i=CreateFile(#PB_Any,_file.s)
;   
;   If IsFile(_file_id.i)=0
;     E_ERROR(#ERROR_CAN_NOT_CREATE_FILE)
;     ProcedureReturn #False
;   EndIf
; creator\creator_objects_in_dna=0
; global_gadget\id=global_gadget\base_id
;   
;   While IsGadget(global_gadget\id)
;     
;          WriteStringN(_file_id.i,GetGadgetText(global_gadget\id))
;    
;     global_gadget\id+1
;   Wend
;     
;   CloseFile(_file_id.i)
;  
; EndProcedure

Procedure E_SAVE_DEFAULT_AI_FILE(_default_ai42.s)
   
  Define _file_id.i=0
  
  _file_id.i=CreateFile(#PB_Any,_default_ai42.s)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#WARNING_DEFAULT_AI_MISSING)
    ProcedureReturn #False
  EndIf

  ClearList(dna_fundament())
  global_gadget\id=global_gadget\base_id
  
  While IsGadget(global_gadget\id)
    
    If FindString(GetGadgetText(global_gadget\id),creator\creator_object_key_word)<>0
      WriteStringN(_file_id.i,GetGadgetText(global_gadget\id))
      
      If AddElement(dna_fundament())
        dna_fundament()\dna_string=GetGadgetText(global_gadget\id)
      EndIf
      
    Else
      WriteStringN(_file_id.i,"")  ;default file does not have any value entries, only keywords!
    EndIf
    
    global_gadget\id+1
  Wend
   
  CloseFile(_file_id.i)
  
  E_DNA_BASE_SAFE_SORTED()
  E_DNA_BASE_LOAD()
  creator\creator_objects_in_dna=0
  E_RESET_GADGET_KEY_VALUES()
  E_RESET_GADGET_COLORS()
  E_PARSE_AI42_DEFAULT_MULTISCAN()
  E_ERROR(#WARNING_DEFAULT_FILE_SAVED)
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)
EndProcedure

Procedure E_LOAD_DEFAULT_AI_FILE(_default_ai42.s)
  
  Define _file_id.i=0
   
   E_DNA_BASE_LOAD()
  
  _file_id.i=ReadFile(#PB_Any,_default_ai42.s)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#WARNING_DEFAULT_AI_MISSING)
    ProcedureReturn #False
  EndIf
  
  CloseFile(_file_id.i)
  creator\creator_last_file=_default_ai42.s
  creator\creator_gfx_file_path=""
  creator\creator_objects_in_dna=0
  E_RESET_GADGET_KEY_VALUES()
  E_RESET_GADGET_COLORS()
  E_PARSE_AI42_DEFAULT_MULTISCAN()
  E_ERROR(#WARNING_DEFAULT_FILE_LOADED)
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)
EndProcedure

Procedure E_LOAD_REQUEST()
 
  Define _file_id.i=0
  Define _dummy.s=""
  _dummy.s=OpenFileRequester("Load AI42",creator\creator_last_file,"*",0)
    
  If Len(_dummy.s)=0
  ProcedureReturn #False  
  EndIf
  
  creator\creator_last_file=_dummy.s
  
 _file_id.i=ReadFile(#PB_Any,creator\creator_last_file)
  
 If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_CAN_NOT_OPEN_FILE)
  ProcedureReturn #False  
EndIf

CloseFile(_file_id.i)

If GetExtensionPart(creator\creator_last_file)<>creator\creator_dna_file_suffix
  E_ERROR(#WARNING_NO_VALID_DNA_FILE)
  ProcedureReturn #False
EndIf

  creator\creator_gfx_file_path=GetPathPart(creator\creator_last_file)
  creator\creator_objects_in_dna=0
  E_RESET_GADGET_COLORS()
  E_RESET_GADGET_KEY_VALUES()
  E_PARSE_AI42_LOAD_MULTISCAN(creator\creator_last_file)
  E_GET_GFX_OUT_OF_DNA()
  E_SET_GFX_NO_REQUEST()
  E_RESET_GADGET_COLORS()
  E_ERROR(#INFO_FILE_LOAD_OK)
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)

EndProcedure


Procedure E_SAVE_REQUEST()
  
  Define _file_id.i=0
  Define _dummy.s=""
  
  _dummy.s=SaveFileRequester("Save AI42",creator\creator_last_file,creator\creator_dna_file_suffix,0)
  
  If Len(_dummy.s)=0
  ProcedureReturn #False  
  EndIf
  
  creator\creator_last_file=_dummy.s
  
  E_SAVE_AI_FILE(creator\creator_last_file)
  E_RESET_GADGET_COLORS()
  E_RESET_GADGET_KEY_VALUES()
  E_PARSE_AI42_LOAD_MULTISCAN(creator\creator_last_file)
  
  E_ERROR( #INFO_FILE_SAVED)
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)
    
EndProcedure

Procedure E_LOAD_COMPLETE_STACK(_dummy.s)
  
  Define _file_id.i=0
  
  creator\creator_last_file=_dummy.s
  
 _file_id.i=ReadFile(#PB_Any,creator\creator_last_file)
  
 If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_CAN_NOT_OPEN_FILE)
  ProcedureReturn #False  
EndIf

CloseFile(_file_id.i)

If GetExtensionPart(creator\creator_last_file)<>creator\creator_dna_file_suffix
  E_ERROR(#WARNING_NO_VALID_DNA_FILE)
  ProcedureReturn #False
EndIf

  creator\creator_gfx_file_path=GetPathPart(creator\creator_last_file)
  creator\creator_objects_in_dna=0
  E_RESET_GADGET_COLORS()
  E_RESET_GADGET_KEY_VALUES()
  E_PARSE_AI42_LOAD_MULTISCAN(creator\creator_last_file)
  E_GET_GFX_OUT_OF_DNA()
  E_SET_GFX_NO_REQUEST()
  E_RESET_GADGET_COLORS()
  ;E_ERROR(#INFO_FILE_LOAD_OK)
  ;SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)

EndProcedure

Procedure E_SAVE_STACK(_dummy.s)
  
  creator\creator_last_file=_dummy.s
  Define _file_id.i=0
  E_SAVE_AI_FILE(creator\creator_last_file)
  E_RESET_GADGET_COLORS()
  E_RESET_GADGET_KEY_VALUES()
  E_PARSE_AI42_LOAD_MULTISCAN(creator\creator_last_file)
    
EndProcedure


Procedure E_SAVE_NO_REQUEST()
  
  Define _file_id.i=0
  E_SAVE_AI_FILE(creator\creator_last_file)
  E_RESET_GADGET_COLORS()
  E_RESET_GADGET_KEY_VALUES()
  E_PARSE_AI42_LOAD_MULTISCAN(creator\creator_last_file)
  
  E_ERROR( #INFO_FILE_SAVED)
  SetWindowTitle(creator_window\window_id,creator_window\window_title+" "+creator\creator_last_file+"  DNA SIZE: "+Str(creator\creator_objects_in_dna)+ " GFX: "+creator\creator_gfx_file_path)
   
EndProcedure


Procedure E_SAVE_AUTO_FOR_HIGHLIGHT_FUNCTION()
  ;this is called by E_HIGHLIGHT_OBJECTS_IN_TOUCH() if we click into an object dna gadget, to higlight similar descriptions
  ;so we save the actual state and show right coloring of the gadgets (actual coloring and find coloring)
  
  If Len(creator\creator_last_file)<1
     ProcedureReturn #False  
  EndIf
  
  E_RESET_GADGET_COLORS()
  
EndProcedure

Procedure E_ACTIVATE_NOT_ACTIVATED_DNA()
  
  If Len(creator\creator_last_file)<1
     ProcedureReturn #False  
  EndIf
  E_SAVE_AI_FILE(creator\creator_last_file)
  
EndProcedure

Procedure E_SET_DIRECTORY_WHERE_NON_ACTIVATED()
  
  Define _dir_id.i=0
  Define _file_extension.s=""
  Define _default_file.s=""
  Define _def_ai42.i=0
  Define _ai42_file_location_part.s=""
  Define _ai42_file_extension_part.s=""
  Define _ai42_file_to_search.s=""
  Define _ai42_file_part.s=""
  Define _ai42_object_name.s=""
  Define _ai42_object_extension.s=""
  Define _ai42_object_path_location.s=""

 _default_file.s=OpenFileRequester("Autocheck For Not Activated DNA",_default_file.s,"GFX (*.png)|*.png|(*jpg)|*.jpg|(*tiff)|*.tiff",0)

If Len(_default_file.s)<1
    ProcedureReturn #False
EndIf

    _file_extension.s=GetExtensionPart(_default_file.s)
  
  ;for now e work with "png" only....
  ;we create a default ai42 file so we can use the data without manual ai42 setting at first time.....
  
    _dir_id.i= ExamineDirectory(#PB_Any,GetPathPart(_default_file.s),"*."+_file_extension.s)
    _ai42_file_location_part.s=GetPathPart(_default_file.s)
    _ai42_file_extension_part.s=creator\creator_dna_file_suffix
    _ai42_object_path_location.s=_ai42_file_location_part.s
    _ai42_object_extension.s=_file_extension.s
    
    If _dir_id.i=0
      _default_file.s=""

    ProcedureReturn #False
    EndIf
    
    While NextDirectoryEntry(_dir_id.i)
      
      If DirectoryEntryType(_dir_id.i)=#PB_DirectoryEntry_File
        _ai42_file_to_search.s=_ai42_file_location_part.s+DirectoryEntryName(_dir_id.i)
        _ai42_file_part.s=GetFilePart( _ai42_file_to_search.s,#PB_FileSystem_NoExtension)
        _ai42_file_to_search.s=_ai42_file_location_part.s+_ai42_file_part.s+"."+creator\creator_dna_file_suffix
        _ai42_object_name.s=_ai42_file_part.s
      EndIf
        
      _def_ai42.i=ReadFile(#PB_Any,_ai42_file_to_search.s)
      
      If IsFile(_def_ai42.i)
      
        CloseFile(_def_ai42.i)  
        
      Else
        
        E_SAVE_AI_FILE_FOR_NONE_DNA_OBJECTS(_ai42_file_to_search.s,_ai42_object_name.s,_ai42_object_extension.s)
        
      EndIf
      
    Wend
  
    FinishDirectory(_dir_id.i)
    
    E_ERROR(#WARNING_AUTO_AI_DONE)
    
    E_LOAD_DEFAULT_AI_FILE(creator\creator_default_object_file)  ; keep default database valid!
    
EndProcedure

Procedure E_STACK_SAVE_LOAD_SCANNER()
  ;with this entry we scan the ai42 and renew them to shorter file
  
  Define _dir_id.i=0
  Define _ok.i=0
  Define _path.s=""

  _ok.i=MessageRequester("WARNING! THIS IS A SERVICE DEVELOPER FUNCTION"," THIS WILL SCAN THE AI42 DIRECTORY AND REPLACE ALL AI42 WITH OPTIMIZED AI42!",#PB_MessageRequester_Info|#PB_MessageRequester_YesNo)
  
  Select _ok.i
      
    Case #PB_MessageRequester_No
      
      ProcedureReturn #False
               
  EndSelect
  
_path.s=OpenFileRequester("SELECT_DIRECTORY:THIS WILL SCAN THE AI42 DIRECTORY AND REPLACE ALL AI42 With OPTIMIZED AI42!",creator\creator_last_file,creator\creator_dna_file_suffix,0)
  
_path.s=GetPathPart(_path.s)
  
_dir_id.i= ExamineDirectory(#PB_Any,_path.s,"*."+creator\creator_dna_file_suffix)

If _dir_id.i=0
  ProcedureReturn #False  
EndIf
  
  While NextDirectoryEntry(_dir_id.i)
      
    If DirectoryEntryType(_dir_id.i)=#PB_DirectoryEntry_File
      
      creator\creator_last_file=_path.s+DirectoryEntryName(_dir_id.i)
      
      E_LOAD_COMPLETE_STACK(creator\creator_last_file)
      E_SAVE_STACK(creator\creator_last_file)
 creator_window\window_event=WaitWindowEvent(1)
  
  If creator_window\window_event
    E_CHECK_EVENT(creator_window\window_event)
  EndIf
        
    EndIf
    
    Wend
      
    _ok.i=MessageRequester("Ai42 RENEW DONE!"," ! ",#PB_MessageRequester_Info|#PB_MessageRequester_Ok)
  
EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 969
; FirstLine = 945
; Folding = -----
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