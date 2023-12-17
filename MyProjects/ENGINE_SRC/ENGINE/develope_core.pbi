;developer core:
;here we add routines called from the engine, by developer input


Procedure E_DEVELOPE_NPC_TEXT_EDIT()
  
  ;use integrated windows editor to change / add NPC text interactive
  
  e_engine\e_external_tool_id=RunProgram("notepad.exe",GetFilePart(e_npc_debugging_dummy_text_var.s),e_engine\e_npc_text_path,#PB_Program_Write)
      If IsProgram(e_engine\e_external_tool_id)=0
    ProcedureReturn #False
  EndIf
  

  
EndProcedure


Procedure E_DEVELOPE_SCROLL_TEXT_EDIT()
  
  ;use integrated windows editor to change / add NPC text interactive
  
   Define _ok.i=0
  

  
  e_engine\e_external_tool_id=RunProgram("notepad.exe",GetFilePart(e_engine\e_scroll_text_source),e_engine\e_world_source,#PB_Program_Write)
      If IsProgram(e_engine\e_external_tool_id)=0
    ProcedureReturn #False
  EndIf
  

  
EndProcedure


Procedure E_DEVELOPE_WORLD_NAME_TEXT_EDIT()
  
  ;use integrated windows editor to change /  add world name interactive
  
  Define _ok.i=0
  
  e_engine\e_external_tool_id=0
  
  _ok.i=OpenFile(#PB_Any,e_engine\e_world_source+e_engine\e_actuall_world+"."+e_worldmap_name_suffix.s+e_engine\e_world_map_name_language_suffix)  ;create dummy if needed
  
  If IsFile(_ok.i)
        CloseFile(_ok.i)  
  EndIf
  
  
  e_engine\e_external_tool_id=RunProgram("notepad.exe",GetFilePart(e_world_info_system\world_info_system_map_name),e_engine\e_world_source,#PB_Program_Write)
  
  If IsProgram(e_engine\e_external_tool_id)=0
    ProcedureReturn #False
  EndIf


  
EndProcedure


Procedure E_DEVELOPE_WORLD_SILUETTE_FILE_EDIT()
  
  ;use integrated windows editor to change /  add world name interactive
  
  Define _ok.i=0
  
  e_engine\e_external_tool_id=0
  
  _ok.i=OpenFile(#PB_Any,e_engine\e_siluette_path)  ;create dummy if needed
  
  If IsFile(_ok.i)
        CloseFile(_ok.i)  
  EndIf
  
  
  e_engine\e_external_tool_id=RunProgram("notepad.exe",GetFilePart(e_engine\e_siluette_path),e_engine\e_world_source,#PB_Program_Write)
  
  If IsProgram(e_engine\e_external_tool_id)=0
    ProcedureReturn #False
  EndIf


  
EndProcedure

Procedure E_DEVELOPE_WORLD_PERMANENT_TEXT_EDIT()
  
  ;use integrated windows editor to change /  add world name interactive
  
  Define _ok.i=0
  
  e_engine\e_external_tool_id=0
  
  _ok.i=OpenFile(#PB_Any,e_engine\e_world_source+e_engine\e_actuall_world+"."+e_engine\e_world_map_head_suffix+e_engine\e_world_map_name_language_suffix)  ;create dummy if needed
  
  If IsFile(_ok.i)
        CloseFile(_ok.i)  
  EndIf
  
  
  e_engine\e_external_tool_id=RunProgram("notepad.exe",GetFilePart(e_engine\e_world_source+e_engine\e_actuall_world+"."+e_engine\e_world_map_head_suffix+e_engine\e_world_map_name_language_suffix),e_engine\e_world_source,#PB_Program_Write)
  
  If IsProgram(e_engine\e_external_tool_id)=0
    ProcedureReturn #False
  EndIf


  
EndProcedure