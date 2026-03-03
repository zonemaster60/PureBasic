; starcomm_tactical.pbi
; Tactical arena display: PrintArenaTactical, ArenaPositions, PrintArenaFrame, TacticalFxPhaser, TacticalFxTorpedo
; XIncluded from starcomm.pb

Procedure PrintArenaTactical(*p.Ship, *e.Ship, *cs.CombatState)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(*cs\range, @posP, @posE, @interior)
  PrintN("")
  PrintArenaFrame(posP\i, posE\i, -1, "", 0, 0, *cs, *e)
EndProcedure

Procedure ArenaPositions(range.i, *posP.Integer, *posE.Integer, *interior.Integer)
  Protected aw.i = 33
  Protected interior.i = aw - 2
  Protected scaleMax.i = 40
  Protected r.i = ClampInt(range, 1, scaleMax)

  Protected posP.i = 2
  Protected posE.i = posP + 2 + Int(r * (interior - 6) / scaleMax)
  posE = ClampInt(posE, posP + 2, interior - 3)

  *posP\i = posP
  *posE\i = posE
  *interior\i = interior
EndProcedure

Procedure PrintArenaFrame(posP.i, posE.i, fxPos.i, fxChar.s, beam.i, attackerIsEnemy.i, *cs.CombatState = 0, *e.Ship = 0)
  ; Draws a 5-row arena with optional effect: either a beam line or a single character.
  ; attackerIsEnemy: 0 = player, 1 = enemy
  ; Player phaser: cyan '=' | Player torpedo: yellow '*'
  ; Enemy disruptor: red '-' | Enemy torpedo: green '*'
  ; Fleet ships: '>' for player fleet (white=idle, yellow=attacking, red=hit)
  ;              '<' for enemy fleet (white=idle, yellow=attacking, red=hit)
  ; Pirate ships: 'P' instead of 'E'
  Protected aw.i = 33
  Protected interior.i = aw - 2
  Protected rowMid.i = 2
  
  Protected pFleetOffset.i = 3  ; Distance from player ship to first fleet ship
  Protected eFleetOffset.i = 3  ; Distance from enemy ship to first fleet ship (to the left)
  
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Arena")
  PrintN("+" + LSet("", aw - 2, "-") + "+")
  ResetColor()

  Protected y.i, x.i
  For y = 0 To 4
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    Print("|")
    ResetColor()

    For x = 0 To interior - 1
      Protected isFleetPos.i = 0
      
      ; Player fleet formation:
      ; ..3.1..   Ship 1: front above  (y=1, x=posP)
      ; ..5.@..   Ship 2: front below  (y=3, x=posP)
      ; ..4.2..   Ship 3: back above   (y=1, x=posP-2, behind ship 1)
      ;           Ship 4: back below   (y=3, x=posP-2, behind ship 2)
      ;           Ship 5: back middle  (y=2, x=posP-2, behind @)
      If gPlayerFleetCount > 0
        Protected pfi.i
        For pfi = 1 To gPlayerFleetCount
          Protected pfY.i, pfX.i
          Select pfi
            Case 1
              pfY = 1        ; front above
              pfX = posP
            Case 2
              pfY = 3        ; front below
              pfX = posP
            Case 3
              pfY = 1        ; back above (behind ship 1)
              pfX = posP - 2
            Case 4
              pfY = 3        ; back below (behind ship 2)
              pfX = posP - 2
            Case 5
              pfY = 2        ; back middle (behind @)
              pfX = posP - 2
          EndSelect
          If pfX < posE - 2 And y = pfY And x = pfX
            If *cs And ((*cs\pFleetHit & (1 << (pfi - 1))) <> 0)
              ConsoleColor(#C_RED, #C_DARKGRAY)
              Print(Str(pfi))
            ElseIf *cs And ((*cs\pFleetAttack & (1 << (pfi - 1))) <> 0)
              ConsoleColor(#C_YELLOW, #C_DARKGRAY)
              Print(Str(pfi))
            Else
              ConsoleColor(#C_WHITE, #C_BLACK)
              Print(Str(pfi))
            EndIf
            ResetColor()
            isFleetPos = 1
            Break
          EndIf
        Next
      EndIf
      
      ; Enemy fleet formation:
      ; ..1.3..   Ship 1: front above  (y=1, x=posE)
      ; ..E.5..   Ship 2: front below  (y=3, x=posE)
      ; ..2.4..   Ship 3: back above   (y=1, x=posE+2, behind ship 1)
      ;           Ship 4: back below   (y=3, x=posE+2, behind ship 2)
      ;           Ship 5: back middle  (y=2, x=posE+2, behind E)
      If isFleetPos = 0 And gEnemyFleetCount > 0
        Protected efi.i
        For efi = 1 To gEnemyFleetCount
          Protected efY.i, efX.i
          Select efi
            Case 1
              efY = 1        ; front above
              efX = posE
            Case 2
              efY = 3        ; front below
              efX = posE
            Case 3
              efY = 1        ; back above (behind ship 1)
              efX = posE + 2
            Case 4
              efY = 3        ; back below (behind ship 2)
              efX = posE + 2
            Case 5
              efY = 2        ; back middle (behind E)
              efX = posE + 2
          EndSelect
          If efX > posP + 2 And y = efY And x = efX
            If *cs And ((*cs\eFleetHit & (1 << (efi - 1))) <> 0)
              ConsoleColor(#C_RED, #C_DARKGRAY)
              Print(Str(efi))
            ElseIf *cs And ((*cs\eFleetAttack & (1 << (efi - 1))) <> 0)
              ConsoleColor(#C_YELLOW, #C_DARKGRAY)
              Print(Str(efi))
            Else
              ConsoleColor(#C_WHITE, #C_BLACK)
              Print(Str(efi))
            EndIf
            ResetColor()
            isFleetPos = 1
            Break
          EndIf
        Next
      EndIf
      
      If isFleetPos = 1
        Continue
      EndIf

      If y = rowMid And beam And x > posP And x < posE
        ; Beam: cyan '=' for player, red '-' for enemy
        If attackerIsEnemy = 0
          ConsoleColor(#C_CYAN, #C_BLACK)
          Print("=")
        Else
          ConsoleColor(#C_RED, #C_BLACK)
          Print("-")
        EndIf
        ResetColor()
        Continue
      EndIf

      If y = rowMid And fxPos >= 0 And x = fxPos
        ; Torpedo: yellow '*' for player, green '*' for enemy
        If attackerIsEnemy = 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
        Else
          ConsoleColor(#C_GREEN, #C_BLACK)
        EndIf
        Print(fxChar)
        ResetColor()
        Continue
      EndIf

      If y = rowMid And x = posP
        ConsoleColor(#C_WHITE, #C_BLACK)
        Print("@")
        ResetColor()
      ElseIf y = rowMid And x = posE
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        ; Check if enemy is a pirate or planet killer using stored flag
        If gEnemyIsPirate = 1
          Print("P")
        ElseIf gEnemyIsPlanetKiller = 1
          Print("K")
        Else
          Print("E")
        EndIf
        ResetColor()
      Else
        ConsoleColor(#C_DARKGRAY, #C_BLACK)
        Print(".")
        ResetColor()
      EndIf
    Next

    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    PrintN("|")
    ResetColor()
  Next

  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("+" + LSet("", aw - 2, "-") + "+")
  ResetColor()
EndProcedure

Procedure TacticalFxPhaser(range.i, attackerIsEnemy.i)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(range, @posP, @posE, @interior)
  ; Beam frame
  PrintArenaFrame(posP\i, posE\i, -1, "", 1, attackerIsEnemy, 0)
EndProcedure

Procedure TacticalFxTorpedo(range.i, attackerIsEnemy.i)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(range, @posP, @posE, @interior)
  Protected fromPos.i = posP\i
  Protected toPos.i = posE\i
  If attackerIsEnemy
    fromPos = posE\i
    toPos = posP\i
  EndIf

  ; Single-frame projectile marker roughly mid-flight.
  Protected fx.i = (fromPos + toPos) / 2
  If fx = fromPos : fx + 1 : EndIf
  If fx = toPos : fx - 1 : EndIf
  PrintArenaFrame(posP\i, posE\i, fx, "*", 0, attackerIsEnemy, 0)
EndProcedure
