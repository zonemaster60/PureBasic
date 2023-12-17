;error handling for engine
;debug default message, during developement is used for  not defined error handling situations


Declare E_SAVE_RESPAWN_WORLD(_val.s)  ;use this for error handling (save map last position if game exits unexpected)
Declare.i E_CUSTOM_MSG_REQUESTER(_head.s,_body.s)
Declare E_GARBAGE_COLLECTOR()


Procedure E_CLEAN_UP()
  ;free all resurces save
  
  If FileSize(e_engine_core\core_start_identifier_location)>-1
     DeleteFile(e_engine_core\core_start_identifier_location) 
   EndIf
   DeleteDirectory(e_engine\e_temp_core,"",#PB_FileSystem_Recursive)
   E_GARBAGE_COLLECTOR()
 


EndProcedure


Procedure E_LOG_INIT()
  ;prepare the log file for the first start of the game
  ;clean it.
  ;we start with a fresh and clean logfile every engine start.
  
  Define _msg.b=0
  
  e_engine\e_log_file_id=CreateFile(#PB_Any,e_engine\e_log_file_path+".engine_log")
  
  If IsFile(e_engine\e_log_file_id)=0
    
    _msg.b=MessageRequester("ENGINE WARNING:  DEBUG: "," CAN NOT CREATE LOG FILE",#PB_MessageRequester_Ok )
    
  ProcedureReturn #False   
  EndIf
  
  WriteStringN(e_engine\e_log_file_id," ENGINE AND TOOLS BY DEUTSCHMANN WALTER (MARK DOWEN)")
  WriteStringN(e_engine\e_log_file_id," ENGINE DEBUGSYSTEM: LOGFILE CREATED: " +" DATE: "+FormatDate("%dd.%mm.%yyyy", Date())+"   "+FormatDate("%hh:%ii:%ss", Date()))
  WriteStringN(e_engine\e_log_file_id," LOG START:")
  
  CloseFile(e_engine\e_log_file_id)  ;all went right
  
EndProcedure

  
Procedure.b E_REBUILD_MISSING_SOUND_DATA(_object_missing_component.s)
  ;this is a very important routine, we can use this to keep origin SOUND/GFX folder up to date,
  ;how to: first copy all sounds in the defined SOUND_POOL
  ;if done delete all SOUNDS/GFX from origin SOUND/GFX folder 
  ;start the game and keep playing
  ;the engien will copy missing files if present in SOUNDPOOL into the origin soundfolder
  ;this feature is developer only, no  POOL is included in distributeable file
  
  Select GetExtensionPart(_object_missing_component.s)
      
    Case "ogg","wave","mp3"
      
      If CopyFile(e_engine\e_sound_pool_path+_object_missing_component.s,v_engine_sound_path.s+_object_missing_component.s)
        ProcedureReturn #True
      EndIf
      
  EndSelect
  
  
  ProcedureReturn #False
  
  
  
  
EndProcedure




Procedure E_LOG(_source_element.s,_object_internal_name.s,_object_missing_component.s)
  ;internal name = given name by AI42
  ;missing component = string/path of filename (sound file/gfx file)
  

  e_engine\e_error_count+1
  e_engine\e_log_file_id=OpenFile(#PB_Any,e_engine\e_log_file_path+".engine_log",#PB_File_SharedWrite|#PB_File_Append)
  
  Trim(_object_missing_component.s)
  
  If IsFile(e_engine\e_log_file_id)=0
    ProcedureReturn #False  ;keep it silent....no request here
  EndIf
  
 If  _source_element.s<>"LOG END"
  WriteStringN(e_engine\e_log_file_id,"PARENT ELEMENT: "+_source_element.s)
  WriteStringN(e_engine\e_log_file_id," OBJECT INTERNAL NAME: "+_object_internal_name.s)
  WriteStringN(e_engine\e_log_file_id," MISSING COMPONENT: "+_object_missing_component.s)

  
  Select E_REBUILD_MISSING_SOUND_DATA(_object_missing_component.s)
      
    Case #False
      WriteStringN(e_engine\e_log_file_id," REPAIR:FAILED")
      
    Case #True
      WriteStringN(e_engine\e_log_file_id," REPAIR:DONE")
      e_engine\e_error_count-1
  EndSelect
  
Else
  
  WriteStringN(e_engine\e_log_file_id," "+_source_element.s)
  
EndIf

  
  CloseFile(e_engine\e_log_file_id)
  
  
  
EndProcedure



Procedure E_ERROR_MAP(_void.i)
  Define _msg.b=#False
  
  
  Select _void.i
      
      Case #E_ERROR_MAP_NOT_FOUND
        
  If e_xbox_controller\xbox_joystick_present<>#True
                
   _msg.b=MessageRequester("ENGINE ERROR SOURCE:","                                           NO MAP DATA FOR MAP:                                          "+Chr(13)+e_engine\e_actuall_world,#PB_MessageRequester_Ok )
   e_engine\e_next_world="start.worldmap"
 Else
   
   E_CUSTOM_MSG_REQUESTER("ENGINE ERROR SOURCE:","NO MAP DATA FOR:  "+e_engine\e_actuall_world)
   e_engine\e_next_world="start.worldmap"
 EndIf

   
;    
;  Case #E_ERROR_GFX_NOT_FOUND
;    _msg.b=MessageRequester("ENGINE ERROR:"," MAP,GFX ERROR",#PB_MessageRequester_Ok )
;    End
   
 Case #E_ERROR_MAP_EMPTY
   
   ShowCursor_(#True) 
   
     _msg.b=MessageRequester("ENGINE ERROR:"," MAP "+Chr(13)+e_engine\e_actuall_world+Chr(13)+" IS EMTPY",#PB_MessageRequester_Ok )
     E_CLEAN_UP()
     End
 
   
  EndSelect
  
  
EndProcedure



; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 147
; FirstLine = 114
; Folding = -
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant