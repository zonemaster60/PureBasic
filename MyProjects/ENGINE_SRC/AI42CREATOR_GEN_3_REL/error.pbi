;here we go for the errors

Procedure.i E_ERROR(_value.i)
  Define _requester_answer.i=0
  
  Select  _value.i
      
    Case #ERROR_INI_FILE
      
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i),"No Ini File"+Chr(13)+"inifile  "+creator\creator_ini_file+" must be in the same directory as the creator",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      End
           
    Case #ERROR_WINDOW_MAIN
      
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i),"Can not open main window",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      End
      
    Case #WARNING_QUIT
      
      _requester_answer.i=MessageRequester("WARNING  #"+Str(_value.i),"Quit?  All unsaved progress gets lost",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo )
      
      If _requester_answer.i=#PB_MessageRequester_Yes
        creator\creator_signal=#E_END
      EndIf
            
    Case #ERROR_PANEL_ADD
      _requester_answer.i=MessageRequester("WARNING   #"+Str(_value.i),"Can not add panel",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
      
    Case #ERROR_PANEL_CREATE
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i),"Can not create panel",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      End
      
    Case #ERROR_CREATE_MENU
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i),"Can not create menu",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      End
      
    Case #ERROR_MENU_INI_FILE
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i)," Menu ini missing",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      End
      
    Case #ERROR_OBJECT_GADGET
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i)," Can not add object gadget",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
      
    Case #WARNING_ABOUT
      _requester_answer.i=MessageRequester("About   #"+Str(_value.i)," AI42  BUILD: "+Str(#pb_editor_buildcount)+Chr(13)+" (c) Deutschmann Walter",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
      
    Case #WARNING_DEFAULT_AI_MISSING
      _requester_answer.i=MessageRequester("Warning   #"+Str(_value.i)," Missing  default AI42 file",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
      
    Case #ERROR_CAN_NOT_OPEN_FILE
      _requester_answer.i=MessageRequester("ERROR   #"+Str(_value.i)," Can not open file",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
      
    Case #WARNING_DNA
      _requester_answer.i=MessageRequester("Warning   #"+Str(_value.i)," No DNA library",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
      
    Case #WARNING_DEFAULT_FILE_SAVED
      _requester_answer.i=MessageRequester("Info   #"+Str(_value.i)," Default DNA created",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
      
    Case #WARNING_DEFAULT_FILE_LOADED
      _requester_answer.i=MessageRequester("Info   #"+Str(_value.i)," Default DNA loaded",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
      
    Case #WARNING_DNA_SAVE
      _requester_answer.i=MessageRequester("Warning  #"+Str(_value.i)," No Fundament DNA",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
      
    Case #WARNING_DNA_SAVE_FUNDAMENT
       _requester_answer.i=MessageRequester("Warning  #"+Str(_value.i)," Can not save DNA fundament",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
       
     Case #WARNING_DNA_LOAD_FUNDAMENT
       _requester_answer.i=MessageRequester("Warning  #"+Str(_value.i)," Can not load DNA fundament",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
       
     Case #WARNING_FILE_MISSING
        _requester_answer.i=MessageRequester("Warning  #"+Str(_value.i)," File: "+creator\creator_last_file+ " missing",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
        
      Case #INFO_FILE_LOAD_OK
        _requester_answer.i=MessageRequester("Info  #"+Str(_value.i)," File: "+creator\creator_last_file+ " load success",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
        
      Case #ERROR_CAN_NOT_CREATE_FILE
        
         _requester_answer.i=MessageRequester("Error  #"+Str(_value.i)," File: "+creator\creator_last_file+ " NOT created",#PB_MessageRequester_Error|#PB_MessageRequester_Ok )
       Case  #INFO_FILE_SAVED
         _requester_answer.i=MessageRequester("Info #"+Str(_value.i)," File: "+creator\creator_last_file+ " created",#PB_MessageRequester_Info|#PB_MessageRequester_Ok )
         
       Case #WARNING_WINDOW_CHILD
         _requester_answer.i=MessageRequester("Warning #"+Str(_value.i)," Can not create GFX Window"+Chr(13)+" AI42 will go on without GFX window",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
         
       Case #WARNING_CANNOT_LOAD_GFX
         _requester_answer.i=MessageRequester("Warning #"+Str(_value.i)," Can not load GFX:"+creator\creator_gfx_file_path+Chr(13),#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
         
       Case #WARNING_NO_VALID_DNA_FILE
          _requester_answer.i=MessageRequester("Warning #"+Str(_value.i)," DNA file not valid, need:("+creator\creator_dna_file_suffix+")"+Chr(13),#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
          
        Case #WARNING_YES_NO
          _requester_answer.i=MessageRequester("Warning #"+Str(_value.i)," Save this DNA as default?"+Chr(13)+" Existing default file will be overwritten!",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo )
          ProcedureReturn _requester_answer.i
                   
        Case #WARNING_AUTO_AI_DONE
          _requester_answer.i=MessageRequester("Warning  #"+Str(_value.i),"Auto (Emtpy) DNA42 is set to objects without DNA",#PB_MessageRequester_Warning|#PB_MessageRequester_Ok )
          
        Case #WARNING_AUTO_AI_SET_YES_NO
          _requester_answer.i=MessageRequester("Warning #"+Str(_value.i),"Set all not defined objects with actual DNA?"+Chr(13)+" ************  TAKE A LOOK AT THE ACTUAL DNA *********",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo )
          ProcedureReturn _requester_answer.i    
      EndSelect 
  
EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 101
; FirstLine = 80
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