;some evetns, yes we have some....

Procedure T_EVENTS(_void.i)
  ;work with the window events
  
  Select _void.i
      
    Case #PB_Event_MoveWindow
      T_ARCADE_FRAME()
      
  EndSelect
  
  
  EndProcedure