; starcomm_galaxy.pbi
; Galaxy map: EntSymbol, ApplyGravityWell, HandleSun, RandomEmptyCell, GenerateCheatCode, CheckCheatCode, HandleArrival, ClearSectorMap, GenerateSectorMap, GenerateGalaxy, PrintCompassCell, PrintCompassRow, PrintMap, ScanGalaxy, ScanGalaxyLong
; XIncluded from starcomm.pb

Procedure.s EntSymbol(t.i)
  Select t
    Case #ENT_EMPTY  : ProcedureReturn "."
    Case #ENT_STAR   : ProcedureReturn "*"
    Case #ENT_PLANET : ProcedureReturn "O"
    Case #ENT_BASE   : ProcedureReturn "%"
    Case #ENT_ENEMY  : ProcedureReturn "E"
    Case #ENT_PIRATE : ProcedureReturn "P"
    Case #ENT_SHIPYARD: ProcedureReturn "+"
    Case #ENT_WORMHOLE: ProcedureReturn "#"
    Case #ENT_BLACKHOLE: ProcedureReturn "?"
    Case #ENT_SUN: ProcedureReturn "S"
    Case #ENT_DILITHIUM: ProcedureReturn "D"
    Case #ENT_ANOMALY: ProcedureReturn "A"
    Case #ENT_PLANETKILLER: ProcedureReturn "K"
    Case #ENT_REFINERY: ProcedureReturn "R"
    Case #ENT_HQ    : ProcedureReturn "$"
    Case #ENT_CARGO : ProcedureReturn "c"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Gravity well: when adjacent to a SUN or BLACKHOLE, may pull you onto it.
; Returns 1 if it moved the player and caller should re-process arrival.
Procedure.i ApplyGravityWell(*p.Ship)
  Protected dx.i, dy.i, nx.i, ny.i
  Protected foundSun.i = 0
  Protected foundBH.i = 0
  Protected sunX.i, sunY.i, bhX.i, bhY.i

  ; Only cardinal adjacency (1 move away)
  For dy = -1 To 1
    For dx = -1 To 1
      If Abs(dx) + Abs(dy) <> 1 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx < 0 Or nx >= #MAP_W Or ny < 0 Or ny >= #MAP_H
        Continue
      EndIf
      Select CurCell(nx, ny)\entType
        Case #ENT_SUN
          foundSun = 1 : sunX = nx : sunY = ny
        Case #ENT_BLACKHOLE
          foundBH = 1 : bhX = nx : bhY = ny
      EndSelect
    Next
  Next

  ; Prefer SUN pull over BLACKHOLE if both present.
  If foundSun
    If Random(99) < 85
      gx = sunX : gy = sunY
      LogLine("SUN: gravity well pulls you in!")
      PrintN("Warning: sun gravity well! Pulled into the sun.")
      ProcedureReturn 1
    EndIf
  ElseIf foundBH
    If Random(99) < 55
      gx = bhX : gy = bhY
      LogLine("BLACK HOLE: gravity well pulls you in!")
      PrintN("Warning: black hole gravity well! Pulled into the black hole.")
      ProcedureReturn 1
    EndIf
  EndIf

  ProcedureReturn 0
EndProcedure

; Returns 1 if the sun effect triggers and caller should stop further processing.
Procedure.i HandleSun(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_SUN
    ProcedureReturn 0
  EndIf

  *p\hull = 0
  *p\shields = 0
  LogLine("SUN: your ship was incinerated!")
  PrintN("You are consumed by the sun. Ship incinerated.")
  ProcedureReturn 1
EndProcedure

Procedure.i RandomEmptyCell(mapX.i, mapY.i, *outX.Integer, *outY.Integer)
  Protected tries.i, x.i, y.i
  For tries = 1 To 400
    x = Random(#MAP_W - 1)
    y = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, x, y)\entType = #ENT_EMPTY
      *outX\i = x
      *outY\i = y
      ProcedureReturn 1
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

;==============================================================================
; GenerateCheatCode()
; Generates a new random 4-digit cheat code every 10 turns.
; Called from game loop to refresh the code periodically.
;==============================================================================
Procedure GenerateCheatCode()
  ; Generate new code every 10 turns
  If gGameTurn > 0 And gGameTurn % 10 = 0
    gCheatCode = Str(Random(8) + 1) + Str(Random(9)) + Str(Random(9)) + Str(Random(9))
    gCheatCodeTurn = gGameTurn
  EndIf
EndProcedure

;==============================================================================
; CheckCheatCode(code.s)
; Checks if entered code matches current cheat code.
; Returns 1 if valid, 0 if invalid.
;==============================================================================
Procedure.i CheckCheatCode(code.s)
  If code = gCheatCode And gCheatCode <> ""
    gCheatsUnlocked = 1
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

; Returns 1 if it moved the player (teleport/scramble) and caller should stop further processing.
Procedure.i HandleArrival(*p.Ship)
  Protected t.i = CurCell(gx, gy)\entType
  Protected mx.i, my.i, nx.i, ny.i

  If t = #ENT_WORMHOLE
    If *p\fuel > 0 : *p\fuel - 1 : EndIf
    mx = Random(#GALAXY_W - 1)
    my = Random(#GALAXY_H - 1)
    If RandomEmptyCell(mx, my, @nx, @ny)
      gMapX = mx : gMapY = my
      gx = nx : gy = ny
      LogLine("WORMHOLE: transit to Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
      PrintN("Wormhole transit! New location: Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
      ProcedureReturn 1
    EndIf
  ElseIf t = #ENT_BLACKHOLE
    Protected r.i = Random(99)
    If r < 40
      ; Random relocation
      mx = Random(#GALAXY_W - 1)
      my = Random(#GALAXY_H - 1)
      If RandomEmptyCell(mx, my, @nx, @ny)
        gMapX = mx : gMapY = my
        gx = nx : gy = ny
        LogLine("BLACK HOLE: spacetime shear - displaced.")
        PrintN("Black hole encounter! Spacetime shear displaces you.")
        ProcedureReturn 1
      EndIf
    ElseIf r < 85
      ; Severe damage
      Protected dmg.i = 60 + Random(60)
      ApplyDamage(*p, dmg)
      LogLine("BLACK HOLE: tidal forces hit for " + Str(dmg) + "!")
      PrintN("Black hole tidal forces hit for " + Str(dmg) + ".")

      ; Scramble to a nearby sector if possible
      Protected tries.i
      For tries = 1 To 25
        nx = gx + (Random(2) - 1)
        ny = gy + (Random(2) - 1)
        If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
          If CurCell(nx, ny)\entType = #ENT_EMPTY
            gx = nx : gy = ny
            ProcedureReturn 1
          EndIf
        EndIf
      Next
    Else
      ; Destroyed
      *p\hull = 0
      *p\shields = 0
      LogLine("BLACK HOLE: your ship was lost!")
      PrintN("The black hole consumes your ship. Ship lost.")
      ProcedureReturn 0
    EndIf
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure ClearSectorMap(mapX.i, mapY.i)
  Protected x.i, y.i
  For y = 0 To #MAP_H - 1
    For x = 0 To #MAP_W - 1
      gGalaxy(mapX, mapY, x, y)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, x, y)\name = ""
      gGalaxy(mapX, mapY, x, y)\richness = 0
      gGalaxy(mapX, mapY, x, y)\enemyLevel = 0
    Next
  Next
EndProcedure

;==============================================================================
; GenerateSectorMap(mapX.i, mapY.i)
; Generates contents for a single sector within a galaxy.
; Parameters:
;   mapX - Galaxy X coordinate (0-3)
;   mapY - Galaxy Y coordinate (0-3)
; 
; Populates the 8x8 sector with random entities based on probability:
;   - Empty space (.)
;   - Stars (*)
;   - Planets (O)
;   - Dilithium asteroids (D) with richness 1-10
;   - Anomalies (A)
;   - Enemy spawns based on player progress/difficulty
;==============================================================================
Procedure GenerateSectorMap(mapX.i, mapY.i)
  ; Deterministic-ish per map for variety
  Protected x.i
  Protected sx.i, sy.i, px.i, py.i, bx.i, by.i, ex.i, ey.i
  Protected isHQ.i = 0
  If mapX = #GALAXY_W / 2 And mapY = #GALAXY_H / 2
    isHQ = 1
  EndIf
  ClearSectorMap(mapX, mapY)

  ; SUN (usually near center)
  If Random(99) < 80
    Protected cx.i = #MAP_W / 2
    Protected cy.i = #MAP_H / 2
    Protected triesSun.i
    For triesSun = 1 To 12
      sx = ClampInt(cx + (Random(2) - 1), 0, #MAP_W - 1)
      sy = ClampInt(cy + (Random(2) - 1), 0, #MAP_H - 1)
      If gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_EMPTY
        gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_SUN
        gGalaxy(mapX, mapY, sx, sy)\name = "Sun"
        Break
      EndIf
    Next
  EndIf

  ; Stars (obstacles)
  For x = 1 To 8 + Random(4)
    sx = Random(#MAP_W - 1)
    sy = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_STAR
      gGalaxy(mapX, mapY, sx, sy)\name = "Star"
    EndIf
  Next

  ; Planets (mining)
  For x = 1 To 6 + Random(5)
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_PLANET
      gGalaxy(mapX, mapY, px, py)\name = "Planet-" + Str(mapX) + "-" + Str(mapY) + ":" + Str(px) + "-" + Str(py)
      gGalaxy(mapX, mapY, px, py)\richness = 5 + Random(25)
    EndIf
  Next

  ; Starbases (rare)
  If Random(99) < 22
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_BASE
      gGalaxy(mapX, mapY, bx, by)\name = "Starbase-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf

  ; Shipyards (very rare)
  If Random(99) < 10
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_SHIPYARD
      gGalaxy(mapX, mapY, bx, by)\name = "Shipyard-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf
  
  ; Refineries (rare)
  If Random(99) < 8
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_REFINERY
      gGalaxy(mapX, mapY, bx, by)\name = "Refinery-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf

  ; Enemies
  Protected enemyCount.i = 4 + Random(6)
  If isHQ : enemyCount = 1 + Random(1) : EndIf
  For x = 1 To enemyCount
    ex = Random(#MAP_W - 1)
    ey = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_ENEMY
      gGalaxy(mapX, mapY, ex, ey)\name = "Raider"
      gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1 + Random(3) + (mapX + mapY) / 6
      If isHQ : gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1 : EndIf
      If gGalaxy(mapX, mapY, ex, ey)\enemyLevel < 1
        gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1
      EndIf
    EndIf
  Next

  ; Wormholes (rare)
  If Random(99) < 12
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_WORMHOLE
      gGalaxy(mapX, mapY, px, py)\name = "Wormhole"
    EndIf
  EndIf

  ; Black holes (very rare)
  If Random(99) < 6
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_BLACKHOLE
      gGalaxy(mapX, mapY, px, py)\name = "Black hole"
    EndIf
  EndIf

  ; Dilithium crystals (rare, valuable for power)
  If Random(99) < 8
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_DILITHIUM
      gGalaxy(mapX, mapY, px, py)\name = "Dilithium Cluster"
      gGalaxy(mapX, mapY, px, py)\richness = 3 + Random(8)
    EndIf
  EndIf

  ; Anomalies (rare, random effects)
  If Random(99) < 5
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_ANOMALY
      gGalaxy(mapX, mapY, px, py)\name = "Spatial Anomaly"
    EndIf
  EndIf

  ; Planet Killers (very rare - less than 1% chance)
  If Random(99) < 1
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_PLANETKILLER
      gGalaxy(mapX, mapY, px, py)\name = "Planet Killer"
      gGalaxy(mapX, mapY, px, py)\enemyLevel = 5 + Random(10)  ; very high level
    EndIf
  EndIf
EndProcedure

;==============================================================================
; GenerateGalaxy()
; Creates the entire game universe - all galaxies, sectors, and entities.
; 
; What it generates for each galaxy (4x4 grid):
;   - 8x8 sector grid per galaxy
;   - Random stars (*), planets (O), dilithium (D), anomalies (A)
;   - Starbases (%) at random locations
;   - Shipyards (+) at random locations
;   - Wormholes (#) and black holes (?) in some galaxies
;   - Enemy spawns based on difficulty level
;   - Refineries (R) in random locations
;
; Probability distribution:
;   - Stars: ~15% of sectors
;   - Planets: ~10% of sectors
;   - Dilithium: ~8% of sectors (richness varies)
;   - Anomalies: ~3% of sectors
;   - Starbases: 1-2 per galaxy
;   - Shipyards: 1 per galaxy
;   - Wormholes: 0-2 per galaxy
;   - Black holes: 0-1 per galaxy
;==============================================================================
Procedure GenerateGalaxy()
  Protected mx.i, my.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      GenerateSectorMap(mx, my)
    Next
  Next

  ; Place Starcomm HQ at galaxy center sector
  Protected hqSectorX.i = #GALAXY_W / 2
  Protected hqSectorY.i = #GALAXY_H / 2
  Protected hqCellX.i   = -1
  Protected hqCellY.i   = -1
  Protected hqScanX.i, hqScanY.i

  ; Find a random empty cell in the center sector for HQ
  For hqScanY = 0 To #MAP_H - 1
    For hqScanX = 0 To #MAP_W - 1
      If gGalaxy(hqSectorX, hqSectorY, hqScanX, hqScanY)\entType = #ENT_EMPTY
        If Random(3) = 0 Or hqCellX = -1
          hqCellX = hqScanX
          hqCellY = hqScanY
        EndIf
      EndIf
    Next
  Next

  ; Fallback: force cell (1,1) if nothing found
  If hqCellX = -1
    hqCellX = 1 : hqCellY = 1
    gGalaxy(hqSectorX, hqSectorY, hqCellX, hqCellY)\entType = #ENT_EMPTY
  EndIf

  gGalaxy(hqSectorX, hqSectorY, hqCellX, hqCellY)\entType = #ENT_HQ
  gGalaxy(hqSectorX, hqSectorY, hqCellX, hqCellY)\name    = "Starcomm HQ"

  ; Store HQ coordinates globally
  gHQMapX = hqSectorX
  gHQMapY = hqSectorY
  gHQX    = hqCellX
  gHQY    = hqCellY

  ; Player starts at Starcomm HQ
  gMapX = gHQMapX
  gMapY = gHQMapY
  gx    = gHQX
  gy    = gHQY
EndProcedure

;==============================================================================
; PrintMap()
; Displays the dual-panel galaxy/sector display.
; 
; Left panel (8x8): Current sector view
;   - Shows entities in current sector
;   - @ = Player, E = Enemy, P = Pirate, O = Planet
;   - * = Star, D = Dilithium, A = Anomaly
;   - % = Starbase, + = Shipyard, R = Refinery
;   - # = Wormhole, ? = Black Hole, S = Sun
;
; Right panel (4x4): Galaxy overview
;   - Shows which galaxies have been visited
;   - X = Current galaxy, M = Mission galaxy
;   - ! = Mission target location
;   - . = Unexplored galaxy
;==============================================================================

;==============================================================================
; PrintCompassRow(compassRow) — prints one row of the 3×3 compass rose.
; Row 0: 315 0 45   Row 1: 270 + 90   Row 2: 225 180 135
; Active heading is highlighted in yellow.  gLastHeading = -1 means no highlight.
; Each cell is 4 chars wide (constant width even when highlighted):
;   prints a right-aligned 3-digit (or 1-2 digit) number plus a trailing space
;==============================================================================
Procedure PrintCompassCell(label.s, heading.i)
  ; 4-char fixed-width cell; highlight uses color only (no brackets)
  If label = "+"
    Print(" +  ")
    ProcedureReturn
  EndIf

  ; Pad numeric headings to 3 digits (e.g. 0 -> 000, 45 -> 045)
  Protected core.s = RSet(label, 3, "0")

  If gLastHeading >= 0 And heading >= 0 And heading = gLastHeading
    ConsoleColor(#C_DARKCYAN, #C_BLACK)
    Print(core + " ")
    ResetColor()
  Else
    Print(core + " ")
  EndIf
EndProcedure

Procedure PrintCompassRow(compassRow.i)
  Protected c0.s, c1.s, c2.s
  Protected h0.i, h1.i, h2.i

  Select compassRow
    Case 0 : c0 = "315" : h0 = 315 : c1 = "0"   : h1 = 0   : c2 = "45"  : h2 = 45
    Case 1 : c0 = "270" : h0 = 270 : c1 = "+"   : h1 = -1  : c2 = "90"  : h2 = 90  ; h1=-1: center never highlights
    Case 2 : c0 = "225" : h0 = 225 : c1 = "180" : h1 = 180 : c2 = "135" : h2 = 135
    Default : ProcedureReturn  ; guard against out-of-range row
  EndSelect

  Print("  ")  ; separator from galaxy map

  PrintCompassCell(c0, h0)
  Print(" ")
  PrintCompassCell(c1, h1)
  Print(" ")
  PrintCompassCell(c2, h2)
EndProcedure

Procedure PrintMap()
  Protected x.i, row.i
  Protected maxRows.i = #MAP_H
  If #GALAXY_H > maxRows : maxRows = #GALAXY_H : EndIf

  PrintDivider()
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("Sector ")
  ResetColor()
  Print("(" + Str(gx) + "," + Str(gy) + ")")
  Print("        ")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("Galaxy ")
  ResetColor()
  PrintN("(" + Str(gMapX) + "," + Str(gMapY) + ") of " + Str(#GALAXY_W) + "x" + Str(#GALAXY_H))

  ; Axis labels
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("   ")
  For x = 0 To #MAP_W - 1
    Print(Str(x) + " ")
  Next
  Print("   ")
  Print("   ")
  For x = 0 To #GALAXY_W - 1
    Print(Str(x) + " ")
  Next
  ResetColor()
  PrintN("")

  For row = 0 To maxRows - 1
    ; Sector map (left)
    If row < #MAP_H
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print(" " + Str(row) + " ")
      ResetColor()
      For x = 0 To #MAP_W - 1
        If x = gx And row = gy
          ; Show base/yard symbol if player is docked there
          If CurCell(gx, gy)\entType = #ENT_BASE
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            Print("% ")
          ElseIf CurCell(gx, gy)\entType = #ENT_HQ
            ConsoleColor(#C_YELLOW, #C_BLACK)
            Print("$ ")
          ElseIf CurCell(gx, gy)\entType = #ENT_SHIPYARD
            ConsoleColor(#C_GREEN, #C_BLACK)
            Print("+ ")
          Else
            ConsoleColor(#C_WHITE, #C_BLACK)
            Print("@ ")
          EndIf
          ResetColor()
        Else
          ; Mission bookmark in this map
          If gMission\type <> #MIS_NONE And gMission\destEntType <> #ENT_EMPTY
            If gMapX = gMission\destMapX And gMapY = gMission\destMapY And x = gMission\destX And row = gMission\destY
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("! ")
              ResetColor()
              Continue
            EndIf
          EndIf

          ; Check for pirate ships (show as 'P')
          If CurCell(x, row)\entType = #ENT_PIRATE Or FindString(LCase(CurCell(x, row)\name), "pirate") > 0
            ConsoleColor(#C_LIGHTRED, #C_BLACK)
            Print("P ")
          Else
            SetColorForEnt(CurCell(x, row)\entType)
            Print(EntSymbol(CurCell(x, row)\entType) + " ")
          EndIf
          ResetColor()
        EndIf
      Next
    Else
      Print("   ")
      Print(Space(#MAP_W * 2))
    EndIf

    Print("   ")

    ; Galaxy map (right)
    If row < #GALAXY_H
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print(" " + Str(row) + " ")
      ResetColor()
      For x = 0 To #GALAXY_W - 1
        ; HQ marker - always visible on galaxy map
        If x = gHQMapX And row = gHQMapY
          ConsoleColor(#C_YELLOW, #C_BLACK)
          If x = gMapX And row = gMapY
            Print("X ")
          Else
            Print("$ ")
          EndIf
          ResetColor()
          Continue
        EndIf
        ; Bookmark the mission target map
        If gMission\type <> #MIS_NONE And gMission\destEntType <> #ENT_EMPTY
          If x = gMission\destMapX And row = gMission\destMapY
            If x = gMapX And row = gMapY
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("X ")
              ResetColor()
              Continue
            Else
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("M ")
              ResetColor()
              Continue
            EndIf
          EndIf
        EndIf

        If x = gMapX And row = gMapY
          ConsoleColor(#C_WHITE, #C_BLACK)
          Print("X ")
          ResetColor()
        Else
          ConsoleColor(#C_DARKGRAY, #C_BLACK)
          Print(". ")
          ResetColor()
        EndIf
      Next
    EndIf

    ; Compass rose: append to the right of galaxy map rows 0-2
    If row <= 2
      PrintCompassRow(row)
    EndIf

    PrintN("")
  Next

  PrintLegendLine("Legend: ")
  Print("Galaxy: ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("$") : ResetColor() : Print("=StarComm HQ ")
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("X") : ResetColor() : Print("=Current map ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("M") : ResetColor() : Print("=Mission map ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("!") : ResetColor() : PrintN("=Mission target")
  PrintDivider()
EndProcedure

Procedure ScanGalaxy()
  Protected dx.i, dy.i, nx.i, ny.i
  PrintDivider()
  PrintN("Local Scan:")
  
  ; Show current sector
  If CurCell(gx, gy)\entType <> #ENT_EMPTY
    Print("  CURRENT (")
    Print(Str(gx) + "," + Str(gy) + ") ")
    SetColorForEnt(CurCell(gx, gy)\entType)
    Print(EntSymbol(CurCell(gx, gy)\entType))
    ResetColor()
    PrintN(" " + CurCell(gx, gy)\name)
    
    ; Show anomaly details if on one
    If CurCell(gx, gy)\entType = #ENT_ANOMALY
      Protected anomalyRoll.i = Random(99)
      If anomalyRoll < 40
        PrintN("  Ion storm detected - shields will be reduced when entering")
      ElseIf anomalyRoll < 70
        PrintN("  Radiation detected - crew effectiveness reduced")
      Else
        PrintN("  Readings indicate a stable anomaly")
      EndIf
    EndIf
  EndIf

  ; Mission: survey completes when you scan at the destination planet
  If gMission\active And gMission\type = #MIS_SURVEY
    If gMapX = gMission\destMapX And gMapY = gMission\destMapY And gx = gMission\destX And gy = gMission\destY
      gCredits + gMission\rewardCredits
      gTotalCreditsEarned + gMission\rewardCredits
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintDivider()
      PrintN("*** MISSION COMPLETE: Survey finished! (+" + Str(gMission\rewardCredits) + " credits) ***")
      PrintDivider()
      ResetColor()
      LogLine("MISSION COMPLETE: survey (+" + Str(gMission\rewardCredits) + " credits)")
      ClearStructure(@gMission, Mission)
      gMission\type = #MIS_NONE
      gTotalMissions + 1
    EndIf
  EndIf

  For dy = -1 To 1
    For dx = -1 To 1
      If dx = 0 And dy = 0 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
        If CurCell(nx, ny)\entType <> #ENT_EMPTY
          Print("  (" + Str(nx) + "," + Str(ny) + ") ")
          SetColorForEnt(CurCell(nx, ny)\entType)
          Print(EntSymbol(CurCell(nx, ny)\entType))
          ResetColor()
          If CurCell(nx, ny)\entType = #ENT_ENEMY Or CurCell(nx, ny)\entType = #ENT_PIRATE
            Protected scanLvl.i  = CurCell(nx, ny)\enemyLevel
            Protected scanThreat.s
            If scanLvl <= 2 : scanThreat = "Minor"
            ElseIf scanLvl <= 4 : scanThreat = "Moderate"
            ElseIf scanLvl <= 6 : scanThreat = "Serious"
            ElseIf scanLvl <= 8 : scanThreat = "Severe"
            Else : scanThreat = "Critical"
            EndIf
            PrintN(" " + CurCell(nx, ny)\name + " [Lvl " + Str(scanLvl) + " - " + scanThreat + "]")
          Else
            PrintN(" " + CurCell(nx, ny)\name)
          EndIf
        EndIf
      EndIf
    Next
  Next
  PrintDivider()
EndProcedure

Procedure ScanGalaxyLong()
  Protected dx.i, dy.i, nx.i, ny.i, range.i = 2
  PrintDivider()
  PrintN("Long Range Scan (2 sector range):")
  
  ; Show current sector
  If CurCell(gx, gy)\entType <> #ENT_EMPTY
    Print("  CURRENT (")
    Print(Str(gx) + "," + Str(gy) + ") ")
    SetColorForEnt(CurCell(gx, gy)\entType)
    Print(EntSymbol(CurCell(gx, gy)\entType))
    ResetColor()
    PrintN(" " + CurCell(gx, gy)\name)
  EndIf

  For dy = -range To range
    For dx = -range To range
      If dx = 0 And dy = 0 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
        If CurCell(nx, ny)\entType <> #ENT_EMPTY
          Print("  (" + Str(nx) + "," + Str(ny) + ") ")
          SetColorForEnt(CurCell(nx, ny)\entType)
          Print(EntSymbol(CurCell(nx, ny)\entType))
          ResetColor()
          If CurCell(nx, ny)\entType = #ENT_ENEMY Or CurCell(nx, ny)\entType = #ENT_PIRATE
            Protected lscanLvl.i  = CurCell(nx, ny)\enemyLevel
            Protected lscanThreat.s
            If lscanLvl <= 2 : lscanThreat = "Minor"
            ElseIf lscanLvl <= 4 : lscanThreat = "Moderate"
            ElseIf lscanLvl <= 6 : lscanThreat = "Serious"
            ElseIf lscanLvl <= 8 : lscanThreat = "Severe"
            Else : lscanThreat = "Critical"
            EndIf
            PrintN(" " + CurCell(nx, ny)\name + " [Lvl " + Str(lscanLvl) + " - " + lscanThreat + "]")
          Else
            PrintN(" " + CurCell(nx, ny)\name)
          EndIf
        EndIf
      EndIf
    Next
  Next
  PrintDivider()
EndProcedure
