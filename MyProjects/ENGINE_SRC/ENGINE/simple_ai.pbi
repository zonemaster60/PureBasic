;here we have some routines for simple ai handling, just a try...


Structure ai_brain
  object_pos_x.f
  object_pos_y.f
  object_set_to_fade_out.b
   
EndStructure

Global ai_brain.ai_brain

Procedure E_AI_RESET()
  ;here we set global ai to default (usually when new map is loaded)
  ai_brain\object_set_to_fade_out=#False ;default!
  
EndProcedure



Procedure E_AI_INIT_GET_SPAWN_POSITION()
  ;check if object is spawn position: (simple for now, first object found is defined)
  
  If world_object()\object_is_spawn_destination=#False
  ProcedureReturn #False  
  EndIf
  
  If ai_brain\object_pos_x<>0 And ai_brain\object_pos_y<>0
  ProcedureReturn #False  
  EndIf
  
    If world_object()\object_random_spawn_destination>0
    
    If Random(world_object()\object_random_spawn_destination)=1
    ai_brain\object_pos_x=world_object()\object_x
    ai_brain\object_pos_y=world_object()\object_y
    EndIf
    
    ProcedureReturn #False
  EndIf

  
  
    ai_brain\object_pos_x=world_object()\object_x
    ai_brain\object_pos_y=world_object()\object_y

  
  
EndProcedure

  

Procedure E_AI_SPAWN_OBJECT_DESTINATION_ON_INTERNAL()
  
  ;here we try to use some simple and maybe complex ai situations

  
  If world_object()\object_use_spawn_destination=#False
    ProcedureReturn #False  
  EndIf
  
  
  Select world_object()\object_internal_name
      
    Case "#LITTLE_DEVIL_BOSS"
      
      If e_engine\e_count_active_boos_guards<1
         world_object()\object_did_spawn=#False  ;we can spawn
         ProcedureReturn #False
      EndIf
        
  
      
      ;now the little devil may teleport:
      If world_object()\object_did_spawn=#True  ;do not spawn after spawn!
        ai_brain\object_pos_x=0
        ai_brain\object_pos_y=0
      ProcedureReturn #False  
      EndIf
      
     If ai_brain\object_pos_x<>0 And ai_brain\object_pos_y<>0
      world_object()\object_did_spawn=#True
      world_object()\object_x=ai_brain\object_pos_x
      world_object()\object_y=ai_brain\object_pos_y
    EndIf
    
      
      
  EndSelect
  
    
  
EndProcedure


Procedure E_AI_CHANGE_OBJECT_STATUS_TO_FADE_OUT()
  
   
  ;search for object_to activade fade out!
  ;first we have to define an object which is a trigger for this!
  ;if we got an object on screen which is a trigger we set ai_brain\object_set_to_fade_out=#true  
  ;if we find an object which is defined as set to fade out oun trigger we will start :
  
  If world_object()\object_set_fade_out_on_ai=#True
    ai_brain\object_set_to_fade_out=#True
    ;switch off!
    world_object()\object_set_fade_out_on_ai=#False
  EndIf
  
  If ai_brain\object_set_to_fade_out=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_activate_fade_out_on_ai=#False
    ProcedureReturn #False
  EndIf
  
  
  ; switch it off:
   world_object()\object_activate_fade_out_on_ai=#False
   
   ;this block is hardcoded for debug,develope, (will be outsourced to script)
   
   ;here are the new/additional settings added to the object:
   world_object()\object_fade_out_per_tick=0.5
   world_object()\object_use_fade=#True 
   world_object()\object_remove_after_fade_out=#True
   world_object()\object_use_indexer=#True
 
  
  
EndProcedure

  


  