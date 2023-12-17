Declare E_STREAM_LOAD_SPRITE(_void.i)
Declare E_ADD_FILE_TO_SECU_LIST(_void.s)
;pack/compressioins/security /system for release / ditribution
;part of the engine!

UseBriefLZPacker()  ;for packer operations
;UseZipPacker()

Structure pack_create_player_save
  pack_file_name.s
  pack_path.s
  pack_id.i
  pack_suffix.s
  EndStructure 

  
  
Structure unpack_player_save
  unpack_file_name.s
  unpack_path.s
  unpack_id.i
  unback_suffix.s
EndStructure 



Structure gfx_packer
  pack_file_name.s
  pack_file_path.s
  unpack_file_name.s
  unpack_file_path.s
  pack_file_id.i
  unpack_file_id.i
  *unpack_memory_location
  packer_file_suffix.s
  pack_file_ai42.s
EndStructure




  Global unpack_player_save.unpack_player_save
  Global pack_create_player_save.pack_create_player_save
  Global gfx_packer.gfx_packer
  
   pack_create_player_save\pack_suffix=".pck"
   
   
   
    Procedure E_GET_PACK_GFX_AND_REBUILD_DISTI(_gfx.s)
   ;try to rebuild corrupted gfx (some kind of copy protection...)

  EndProcedure

   

  Procedure E_GET_PACK_GFX_AND_CONVERT_DISTI(_gfx.s)
    ;encode the gfx (single gfx given by engine)
  
    
  EndProcedure
  
  
  Procedure E_GET_PACK_GFX_AND_CONVERT(_gfx.s)
    
    

    
  EndProcedure
  
  
  
  Procedure E_SEARCH_FILES_FOR_PACK()
    ;we go for the files and send them to the map creator! (#STREAM)
    
    
  EndProcedure
  
  
  
  
  
  
  
  
  Procedure E_PACK_CREATE_PLAYER_SAVE_PACK(_player_save_path.s)
    
    If e_engine\e_engine_create_distribution=#False
    ProcedureReturn #False  
    EndIf
    

     pack_create_player_save\pack_id=CreatePack(#PB_Any,_player_save_path.s+pack_create_player_save\pack_suffix,#PB_PackerPlugin_BriefLZ)
     
     If pack_create_player_save\pack_id=0
         ProcedureReturn #False
    EndIf
    
     AddPackFile(pack_create_player_save\pack_id,_player_save_path.s,GetFilePart(_player_save_path.s))
     ClosePack(pack_create_player_save\pack_id)
     DeleteFile(_player_save_path.s)
     ProcedureReturn #True
    
  EndProcedure 



  
  Procedure E_UNPACK_CREATE_PLAYER_SAVE(_player_save_path.s)
    
      If e_engine\e_engine_create_distribution=#False
    ProcedureReturn #False  
    EndIf
   
    pack_create_player_save\pack_id=OpenPack(#PB_Any,_player_save_path.s+pack_create_player_save\pack_suffix,#PB_PackerPlugin_BriefLZ)
    
    If pack_create_player_save\pack_id=0
    ProcedureReturn #False  
    EndIf
    
    If ExaminePack(pack_create_player_save\pack_id)
      
      While NextPackEntry(pack_create_player_save\pack_id)
        
        UncompressPackFile(pack_create_player_save\pack_id,_player_save_path.s)
      Wend
      
      
    EndIf
    
    
    ClosePack(pack_create_player_save\pack_id)
    ProcedureReturn #True
    
   
    
  EndProcedure
  





  Procedure E_PACK_CREATE_LOCATION_SAVE(_location_path.s)
    
      If e_engine\e_engine_create_distribution=#False
    ProcedureReturn #False  
    EndIf
    
   
    
     pack_create_player_save\pack_id=CreatePack(#PB_Any,_location_path.s+pack_create_player_save\pack_suffix,#PB_PackerPlugin_BriefLZ)
     
     If pack_create_player_save\pack_id=0
         ProcedureReturn #False
    EndIf
    
     AddPackFile(pack_create_player_save\pack_id,_location_path.s,GetFilePart(_location_path.s))
     ClosePack(pack_create_player_save\pack_id)
   
    DeleteFile(_location_path.s)
    
  EndProcedure
  
  
      
  Procedure E_UNPACK_CREATE_LOCATION_LOAD(_location_path.s)
    
    If e_engine\e_engine_create_distribution=#False
    ProcedureReturn #False  
    EndIf
    

    
    pack_create_player_save\pack_id=OpenPack(#PB_Any,_location_path.s+pack_create_player_save\pack_suffix,#PB_PackerPlugin_BriefLZ)
    
    If pack_create_player_save\pack_id=0
    ProcedureReturn #False  
    EndIf
    
    If ExaminePack(pack_create_player_save\pack_id)
      
      While NextPackEntry(pack_create_player_save\pack_id)
        
        UncompressPackFile(pack_create_player_save\pack_id,_location_path.s)
      Wend
      
      
    EndIf
    
    
    ClosePack(pack_create_player_save\pack_id)
    
    
   
    
  EndProcedure
  
    

Procedure E_DECRYPT_FOLDER(_temp.s)
  

  
EndProcedure




Procedure E_SET_UP_GAME_DIRECTORY(_temp.s)
  


EndProcedure


Procedure E_DECRYPT_ROOT_FOLDERS(_root.s)
  
  E_GET_PACK_GFX_AND_REBUILD_DISTI(_root.s)
  
  
EndProcedure

