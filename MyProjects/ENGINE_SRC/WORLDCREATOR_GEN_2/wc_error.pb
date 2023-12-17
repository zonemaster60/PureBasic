;handles all errors/warnings ....

Declare WC_SET_RESOURCE()
Declare WC_GARBAGE_COLLECTOR()  
Declare WC_SET_DEFAULT_MENU_STATE_ON_START()

Procedure WC_ERROR(_type.l,_txt.s)
  
  Define _requester_info.b
  
  Select _type.l
      
    Case #WC_ERROR_FILE_NOT_FOUND
      
      _requester_info.b=MessageRequester("Error","File "+" "+_txt.s+" not found"+Chr(13)+" Continue EXE?", #PB_MessageRequester_YesNo)
            
      Select _requester_info.b
          
        Case  #PB_MessageRequester_Yes    
          ProcedureReturn #False
        Case  #PB_MessageRequester_No 
          
          End
      
      EndSelect
   
    Case #WC_ERROR_ASK_UPDATE_ASSET_DIRECTORY
      
      _requester_info.b=MessageRequester("WARNING",_txt.s, #PB_MessageRequester_Ok)
      
    Case #WC_CAN_ON_NOT_CREATE_ASSET_WINDOW
      
       _requester_info.b=MessageRequester("Error",_txt.s, #PB_MessageRequester_Ok)
      
         End
      
    Case #WC_ERROR_CAN_NOT_CREATE_MENU
      
       _requester_info.b=MessageRequester("Error",_txt.s, #PB_MessageRequester_Ok)
      
         End
      
       Case #WC_ERROR_NEED_SOURCE
         
         _requester_info.b=MessageRequester("WARNING:",_txt.s, #PB_MessageRequester_YesNo)
         
         If _requester_info.b=#PB_MessageRequester_No
           End
                
         EndIf
         
        Case #WC_ERROR_CAN_NOT_CREATE_OBJECT
          
                    _requester_info.b=MessageRequester("FATAL ERROR:",_txt.s, #PB_MessageRequester_Ok)
                    WC_SET_RESOURCE()
                    If wc_ignore_map_error.b=#False
                        End
                    EndIf         
                    
                  Case #WC_ERROR_CAN_NOT_ADD_OBJECT
                    
                    _requester_info.b=MessageRequester("WARNING:",_txt.s, #PB_MessageRequester_YesNo)
                    
                    If _requester_info.b= #PB_MessageRequester_No 
                      End
                      
                    EndIf
                    
                  Case #WC_ERROR_NOT_SAVED_CONTENT_WILL_BE_LOST
                    
                    _requester_info.b=MessageRequester("WARNING:",_txt.s, #PB_MessageRequester_YesNo) 
                    
                    If  _requester_info.b=#PB_MessageRequester_Yes
                      WC_GARBAGE_COLLECTOR()  
                      WC_SET_DEFAULT_MENU_STATE_ON_START()
                     EndIf
                     
                   Case #WC_ERROR_DELPOINTER_MISSING
                      _requester_info.b=MessageRequester("ERROR:",_txt.s, #PB_MessageRequester_Ok) 
                      End
                      
                    Case #WC_CAN_NOT_LOAD_ASSET_OBJECT
                      
                      _requester_info.b=MessageRequester("ERROR:",_txt.s+Chr(13)+" Continue?", #PB_MessageRequester_YesNo) 
                                       
                    If _requester_info.b= #PB_MessageRequester_No 
                      End
                      
                    EndIf
                       
  EndSelect
  
  EndProcedure


; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 91
; FirstLine = 69
; Folding = -
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger