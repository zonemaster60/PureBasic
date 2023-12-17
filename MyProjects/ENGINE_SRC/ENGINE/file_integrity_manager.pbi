;programming and idea: Deutschmann Walter, all rights reserved
;this is the data heard of the engine
;every start it will check if there is gfx not used/not in maps and remove this
;to keep a clean directory for base files
;this does not check for anim/icons ore other file resources, just for the base gfx which is used to build the world

Declare E_LOG(s0.s,s1.s,s2.s)





Procedure E_CHECK_CORE_INTEGRITY()
  
  ;this is a very core core!!!
  
  Define _msg.b
  Define _file.i=0
  
  If FileSize(e_engine_core\core_start_identifier_location)>-1
    _msg.b=MessageRequester("ENGINE BUILD "+e_version_info\version_info_text,"Can not create engine instance!"+Chr(13)+"Check if an instance is already running,"+Chr(13)+" Force Clean Up?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Error)
    
    If _msg.b=#PB_MessageRequester_Yes
      DeleteFile(e_engine_core\core_start_identifier_location) 
    Else
      End
      
    EndIf
    
    _msg.b=MessageRequester("ENGINE BUILD "+e_version_info\version_info_text,"Please (Re)Start Game!",#PB_MessageRequester_Ok)
    
    End
    
  EndIf
  
  _file.i=CreateFile(#PB_Any,e_engine_core\core_start_identifier_location)
  
  If IsFile(_file.i)  ;did it!
    CloseFile(_file.i)
  EndIf
 
  
EndProcedure










Procedure E_CHECK_MAP_FOR_DATA_PARSER()
  
  Define _file_id.i=0
  
  If ListSize(pool_map())<1
    E_LOG(e_engine\e_engine_source_element,"MAP LISTSIZE="+Str(ListSize(pool_map())),"NO VALID MAP")
  ProcedureReturn #False  
  EndIf
  

  
EndProcedure




