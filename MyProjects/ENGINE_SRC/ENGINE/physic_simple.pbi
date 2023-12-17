;some simple physics...





Procedure E_RIGIT_ONE_WAY_COLLISION()
  ;if rigit values?
  
  If world_object()\object_use_physic_loop=#True
    ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_did_collision=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_physic_collision=#False
    ProcedureReturn #False  
  EndIf
  
  
  
  
  If world_object()\object_move_x>0
    world_object()\object_move_x-world_object()\object_rigit_collision_x
    If world_object()\object_rigit_collision_x>0
      world_object()\object_rotate-world_object()\object_rigit_rotate
      world_object()\object_rotate_left+world_object()\object_rigit_rotate
      world_object()\object_rotate_right-world_object()\object_rigit_rotate
    EndIf
    
    
  EndIf
  If world_object()\object_move_y>0
    world_object()\object_move_y-world_object()\object_rigit_collision_y
    If world_object()\object_rigit_collision_y>0
      world_object()\object_rotate-world_object()\object_rigit_rotate
      world_object()\object_rotate_left+world_object()\object_rigit_rotate
      world_object()\object_rotate_right-world_object()\object_rigit_rotate
    EndIf
    
  EndIf
  
EndProcedure


Procedure E_RIGIT_LOOP_COLLISION()
  ;flip_flop physics
  
  
  If world_object()\object_use_physic_loop=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_did_collision=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_physic_collision=#False
  ProcedureReturn #False  
  EndIf
  
  
  world_object()\object_move_x-world_object()\object_rigit_collision_x
  world_object()\object_rotate-world_object()\object_rigit_rotate
  world_object()\object_rotate_left+world_object()\object_rigit_rotate
  world_object()\object_rotate_right-world_object()\object_rigit_rotate
  world_object()\object_move_y-world_object()\object_rigit_collision_y
  world_object()\object_rotate-world_object()\object_rigit_rotate
  world_object()\object_rotate_left+world_object()\object_rigit_rotate
  world_object()\object_rotate_right-world_object()\object_rigit_rotate
  

  
EndProcedure


Procedure E_RIGIT_LOOP_NO_COLLISION()
  ;flip_flop physics
  
  
  If world_object()\object_use_physic_loop=#False
  ProcedureReturn #False  
  EndIf
  
 If  world_object()\object_use_physic_no_collision=#False
  ProcedureReturn #False  
  EndIf
  
  world_object()\object_move_x-world_object()\object_rigit_collision_x
  world_object()\object_rotate-world_object()\object_rigit_rotate
  world_object()\object_rotate_left+world_object()\object_rigit_rotate
  world_object()\object_rotate_right-world_object()\object_rigit_rotate
  world_object()\object_move_y-world_object()\object_rigit_collision_y
  world_object()\object_rotate-world_object()\object_rigit_rotate
  world_object()\object_rotate_left+world_object()\object_rigit_rotate
  world_object()\object_rotate_right-world_object()\object_rigit_rotate
  

  
EndProcedure


Procedure E_RIGIT_ONE_WAY_NO_COLLISION()
  ;if rigit values?
  
  If world_object()\object_use_physic_loop=#True
    ProcedureReturn #False  
  EndIf
  
  If  world_object()\object_use_physic_no_collision=#False
  ProcedureReturn #False  
  EndIf
  
  
  
  
  
  If world_object()\object_move_x>0
    world_object()\object_move_x-world_object()\object_rigit_collision_x
    If world_object()\object_rigit_collision_x>0
      world_object()\object_rotate-world_object()\object_rigit_rotate
      world_object()\object_rotate_left+world_object()\object_rigit_rotate
      world_object()\object_rotate_right-world_object()\object_rigit_rotate
    EndIf
    
    
  EndIf
  If world_object()\object_move_y>0
    world_object()\object_move_y-world_object()\object_rigit_collision_y
    If world_object()\object_rigit_collision_y>0
      world_object()\object_rotate-world_object()\object_rigit_rotate
      world_object()\object_rotate_left+world_object()\object_rigit_rotate
      world_object()\object_rotate_right-world_object()\object_rigit_rotate
    EndIf
    
  EndIf
  
EndProcedure


Procedure E_PHYSIC_SIMPLE()
  
  E_RIGIT_ONE_WAY_COLLISION()
  E_RIGIT_ONE_WAY_NO_COLLISION()
  E_RIGIT_LOOP_COLLISION()
  E_RIGIT_LOOP_NO_COLLISION()
  
  
EndProcedure
