; starcomm_undo.pbi
; Undo system: SaveUndoState, RestoreUndoState
; XIncluded from starcomm.pb

Procedure SaveUndoState(fuel.i, hull.i, shields.i, credits.i, ore.i, dilithium.i, mapX.i, mapY.i, x.i, y.i, mode.i, iron.i, aluminum.i, copper.i, tin.i, bronze.i)
  gUndoFuel = fuel
  gUndoHull = hull
  gUndoShields = shields
  gUndoCredits = credits
  gUndoOre = ore
  gUndoDilithium = dilithium
  gUndoMapX = mapX
  gUndoMapY = mapY
  gUndoX = x
  gUndoY = y
  gUndoMode = mode
  gUndoIron = iron
  gUndoAluminum = aluminum
  gUndoCopper = copper
  gUndoTin = tin
  gUndoBronze = bronze
  gUndoAvailable = 1
EndProcedure

Procedure RestoreUndoState(*fuel.Integer, *hull.Integer, *shields.Integer, *credits.Integer, *ore.Integer, *dilithium.Integer, *mapX.Integer, *mapY.Integer, *x.Integer, *y.Integer, *mode.Integer, *iron.Integer, *aluminum.Integer, *copper.Integer, *tin.Integer, *bronze.Integer)
  If gUndoAvailable = 0
    ProcedureReturn 0
  EndIf
  *fuel\i = gUndoFuel
  *hull\i = gUndoHull
  *shields\i = gUndoShields
  *credits\i = gUndoCredits
  *ore\i = gUndoOre
  *dilithium\i = gUndoDilithium
  *mapX\i = gUndoMapX
  *mapY\i = gUndoMapY
  *x\i = gUndoX
  *y\i = gUndoY
  *mode\i = gUndoMode
  *iron\i = gUndoIron
  *aluminum\i = gUndoAluminum
  *copper\i = gUndoCopper
  *tin\i = gUndoTin
  *bronze\i = gUndoBronze
  gUndoAvailable = 0
  ProcedureReturn 1
EndProcedure
