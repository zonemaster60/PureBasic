;this includes:
;all routines with dynamic text 
;format:
;#+keyword#

;example: to insert "goldvalue" (10) into text:
;you have #goldvalue# gold



Procedure.s E_INTERPRETER_SET_ANSWER(_keyword.s)
  
 Define  _return_value.s=" ENGINE INTERPRETER: VALUE NOT DEFINED " 
 

 
 Select _keyword.s
     
   Case "GOLD_PLAYER"
     _return_value.s=Str(player_statistics\player_gold)
     
     Case "GOLD_CHAMBER"
        _return_value.s=Str(player_statistics\player_gold_in_chamber)
       
     Case "GOLD_NEED"
       _return_value.s=Str(world_object()\object_need_gold)
       
     Case "CHAR_NAME"
       _return_value.s=player_statistics\player_name
       If Len(_return_value.s)<1
       _return_value.s="Thorin"  
       EndIf
       
       
     Case "WORLD_NAME"
       _return_value.s=e_world_info_system\world_info_system_map_screen_name
     
 EndSelect
 
  
 ProcedureReturn _return_value.s 
  
  
  
EndProcedure


Procedure.s  E_INTERPRETER_GET_KEYWORD(_text.s)
  Define _left_part.s=""
  Define _right_part.s=""
  Define _context.s=""
  Define _find_start.i=0
  Define _find_end.i=0
  Define _new_text.s=""
  
  _find_start.i=FindString(_text.s,e_engine\e_interpreter_trigger_string.s)
  _find_end.i=FindString(_text.s,e_engine\e_interpreter_trigger_string.s,_find_start.i+1)
  
  _left_part.s=Mid(_text.s,0,_find_start.i-1)
  _right_part.s=Mid(_text.s,_find_end.i+1)
  _context.s=Mid(_text.s,_find_start.i+1,_find_end.i-_find_start.i-1)
  
  If _find_start.i>0 And _find_end>0
    _new_text.s=_left_part.s+E_INTERPRETER_SET_ANSWER(_context.s)+_right_part.s
    ProcedureReturn _new_text.s
    
  EndIf
  
  
  ProcedureReturn _text.s ;nothing changed
  
  
EndProcedure
