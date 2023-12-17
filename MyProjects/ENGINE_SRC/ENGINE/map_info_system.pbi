;here  we handle all the stuff for map info system
;output map name and other relevant infos for the player



Procedure  E_GET_MAP_NAME()
  Define _ok.i=0
  Define _dummy.s=""
  
  If Len(e_engine\e_next_world)<1 ;Or Len(e_worldmap_name_suffix.s)<1
    ProcedureReturn #False  
  EndIf
  

;we use the same suffix for npc and world map name /language
 
  e_world_info_system\world_info_system_map_name=e_engine\e_world_source+e_engine\e_actuall_world+"."+e_worldmap_name_suffix.s+e_engine\e_world_map_name_language_suffix
  
  _ok.i=ReadFile(#PB_Any,e_world_info_system\world_info_system_map_name)
  
;   If IsFile(_ok.i)=0
;     e_world_info_system\world_info_system_map_name=e_engine\e_world_source+e_engine\e_actuall_world+"."+e_worldmap_name_suffix.s  ;no language suffix = english
;      _ok.i=ReadFile(#PB_Any,e_world_info_system\world_info_system_map_name)
; 
; EndIf

If IsFile(_ok.i)=0
  
  e_world_info_system\world_info_system_map_name=""
  e_world_info_system\world_info_system_map_name=e_engine\e_world_source+e_engine\e_actuall_world+"."+e_worldmap_name_suffix.s
  _ok.i=ReadFile(#PB_Any,e_world_info_system\world_info_system_map_name)
  
  If IsFile(_ok.i)=0
 
    ProcedureReturn #False 
    
  EndIf
  
EndIf

While Not Eof(_ok.i)
  _dummy.s=ReadString(_ok.i)
  Select _dummy.s
    Case "#X#"
      e_world_info_system\world_info_system_map_name_pos_x=Val(ReadString(_ok.i))
    Case "#Y#"
      
      e_world_info_system\world_info_system_map_name_pos_y=Val(ReadString(_ok.i))
    Case "#NAME#"
      e_world_info_system\world_info_system_map_screen_name=ReadString(_ok.i)
    Case "#R#"
      
      e_world_info_system\rgb_r_map=Val(ReadString(_ok.i))
    Case "#G#"
      e_world_info_system\rgb_g_map=Val(ReadString(_ok.i)) 
    Case "#B#"
      
      e_world_info_system\rgb_b_map=Val(ReadString(_ok.i))  
  EndSelect
  
  
Wend

CloseFile(_ok.i)
    

EndProcedure

Procedure  E_GET_MAP_SCREEN_NAME()
  
  Define _ok.i=0
  Define _dummy.s=""
  
  If Len(e_engine\e_next_world)<1 ;Or Len(e_worldmap_name_suffix.s)<1
    ProcedureReturn #False  
  EndIf
  

;we use the same suffix for npc and world map name /language
 
  e_world_info_system\world_info_system_permanent_text=e_engine\e_world_source+e_engine\e_actuall_world+"."+e_engine\e_world_map_head_suffix+e_engine\e_world_map_name_language_suffix
  
  _ok.i=ReadFile(#PB_Any,e_world_info_system\world_info_system_permanent_text)
  
  If IsFile(_ok.i)=0
    e_world_info_system\world_info_system_permanent_text=e_engine\e_world_source+e_engine\e_actuall_world+"."+e_engine\e_world_map_head_suffix ;no language suffix = english =default
     _ok.i=ReadFile(#PB_Any,e_world_info_system\world_info_system_permanent_text)

EndIf

If IsFile(_ok.i)=0
e_world_info_system\world_info_system_permanent_text=""
ProcedureReturn #False  
EndIf


While Not Eof(_ok.i)
  _dummy.s=ReadString(_ok.i)
  
  Select _dummy.s
    Case "#HEAD#"
      e_world_info_system\world_info_system_permanent_text=ReadString(_ok.i)
    Case "#X#"
      
      e_world_info_system\world_info_system_permanent_text_x=ValF(ReadString(_ok.i)) 
    Case "#Y#"
      e_world_info_system\world_info_system_permanent_text_y=ValF(ReadString(_ok.i))
    Case "#R#"
      e_world_info_system\rgb_r=Val(ReadString(_ok.i))
    Case "#G#"
      e_world_info_system\rgb_g=Val(ReadString(_ok.i))
    Case "#B#"
      
      e_world_info_system\rgb_b=Val(ReadString(_ok.i))
  EndSelect
  
  
  
Wend

CloseFile(_ok.i)
    

EndProcedure



; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 21
; Folding = -
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant