EnableExplicit

XIncludeFile "../math/Vec2.pb"
XIncludeFile "../core/Log.pb"

DeclareModule World
  Declare Init()
  Declare Shutdown()

  Declare.i CreateGameEntity()

  Declare SetTransform(entity.i, *position.Vec2::T)
  Declare SetVelocity(entity.i, *velocity.Vec2::T)

  Declare Update(dt.f)
  Declare Render(alpha.f)

  Declare.i GetPlayerEntity()
EndDeclareModule

Module World
  Structure Transform
    pos.Vec2::T
  EndStructure

  Structure Velocity
    vel.Vec2::T
  EndStructure

  Global g_nextEntity.i = 1
  Global NewMap g_alive.i()

  Global NewMap g_transform.Transform()
  Global NewMap g_velocity.Velocity()

  Global g_player.i

  Procedure Init()
    ClearMap(g_alive())
    ClearMap(g_transform())
    ClearMap(g_velocity())
    g_nextEntity = 1
    g_player = 0
  EndProcedure

  Procedure Shutdown()
    ClearMap(g_alive())
    ClearMap(g_transform())
    ClearMap(g_velocity())
  EndProcedure

  Procedure.i CreateGameEntity()
    Protected id = g_nextEntity
    g_nextEntity + 1

    g_alive(Str(id)) = #True
    ProcedureReturn id
  EndProcedure

  Procedure SetTransform(entity.i, *position.Vec2::T)
    If *position
      g_transform(Str(entity))\pos\x = *position\x
      g_transform(Str(entity))\pos\y = *position\y
    EndIf
  EndProcedure

  Procedure SetVelocity(entity.i, *velocity.Vec2::T)
    If *velocity
      g_velocity(Str(entity))\vel\x = *velocity\x
      g_velocity(Str(entity))\vel\y = *velocity\y
    EndIf
  EndProcedure

  Procedure Update(dt.f)
    ForEach g_velocity()
      Protected entity = Val(MapKey(g_velocity()))
      If FindMapElement(g_transform(), Str(entity))
        Protected delta.Vec2::T
        Vec2::Scale(@delta, @g_velocity()\vel, dt)
        Vec2::Add(@g_transform()\pos, @g_transform()\pos, @delta)
      EndIf
    Next
  EndProcedure

  Procedure Render(alpha.f)
    ; v0.1: simple placeholder. Rendering implemented in DemoScene for now.
  EndProcedure

  Procedure.i GetPlayerEntity()
    ProcedureReturn g_player
  EndProcedure
EndModule
