;------------------------------------------------------------------------------
; Help dialog (extracted from pbzt.pb)
;------------------------------------------------------------------------------

Procedure OpenHelpDialog(EditModeHelp.b)
  Protected ev.i, gid.i
  Protected content.s
  Protected wTitle.s

  Protected scriptHelp.s
  scriptHelp = "Object Scripts (simple ZZT-ish):" + #LF$ +
               "  Objects can have little scripts." + #LF$ +
               "  A script is just lines of text." + #LF$ +
               "  Lines that start with ':' are labels (names)." + #LF$ +
               "  Lines that start with '#' are commands (actions)." + #LF$ + #LF$ +
               "When does a script run?" + #LF$ +
               "  - If you walk into an object (or bump it) it can run :TOUCH." + #LF$ +
               "  - Some objects can also run on their own over time." + #LF$ + #LF$ +
               "Tiny example (copy into an object):" + #LF$ +
               "  :TOUCH" + #LF$ +
               "  #SAY Hello!" + #LF$ +
               "  #END" + #LF$ + #LF$ +
               "Commands you can use:" + #LF$ +
               "  #SAY text                 Say something (shows at bottom)." + #LF$ +
               "  #SCROLL text              Show a message box (pause)." + #LF$ +
               "  #SETFUEL TORCH|LANTERN n  Set light fuel (0..max)." + #LF$ +
               "  #IFFUEL TORCH|LANTERN n label   If fuel >= n, goto label." + #LF$ +
               "  #GIVECKEY 1|2|3|4 [n]      Add colored keys (default 1)." + #LF$ +
               "  #TAKECKEY 1|2|3|4 [n]      Remove colored keys (default 1)." + #LF$ +
               "  #IFCKEY 1|2|3|4 n label    If colored keys >= n, goto label." + #LF$ +
               "  #GOTO label               Jump to another label." + #LF$ +
               "  #END                      Stop the script." + #LF$ +
               "  #WAIT n                   Wait n ticks." + #LF$ +
               "  #IFTOUCH label            If player is next to me, goto label." + #LF$ +
               "  #IFCONTACT label          If player is on my tile, goto label." + #LF$ +
               "  #IFRAND pct label         Random chance (pct 0..100)." + #LF$ +
               "  #IFSCORE n label          If Score >= n, goto label." + #LF$ +
               "  #IFKEYS n label           If Keys >= n, goto label." + #LF$ +
               "  #IFHEALTH n label         If Health >= n, goto label." + #LF$ +
               "  #SETFLAG name             Remember something (flag = ON)." + #LF$ +
               "  #CLEARFLAG name           Forget something (flag = OFF)." + #LF$ +
               "  #TOGGLEFLAG name          Flip a flag ON/OFF." + #LF$ +
               "  #IFFLAG name label        If flag is ON, goto label." + #LF$ +
               "  #IFNOTFLAG name label     If flag is OFF, goto label." + #LF$ +
               "  #GIVEITEM name [count]    Add an item to inventory." + #LF$ +
               "  #TAKEITEM name [count]    Remove items (min 0)." + #LF$ +
               "  #IFITEM name [count] label If you have items, goto label." + #LF$ +
               "  #GIVE SCORE|KEYS|HEALTH n Add points/keys/HP." + #LF$ +
               "  #TAKE SCORE|KEYS|HEALTH n Remove points/keys/HP." + #LF$ +
               "  #SET x y char             Change a map tile at x,y." + #LF$ +
               "  #SETCOLOR x y color       Change the color at x,y (0..255)." + #LF$ +
               "  #CHAR char                Change this object's letter." + #LF$ +
               "  #COLOR color              Change this object's color." + #LF$ +
               "  #SOLID 0|1                1=block player, 0=walk through." + #LF$ +
               "  #BOARD n                  Go to board n." + #LF$ +
               "  #WALK N|S|E|W             Move object one step." + #LF$ +
               "  #EXITN/#EXITS/#EXITW/#EXITE n  Set edge exit board." + #LF$

  If EditModeHelp
    wTitle = #APP_NAME + " Help (Editor)"
    content = ""
    content + #APP_NAME + " Editor Help:" + #LF$
    content + #LF$
    content + "Quick start (make your first tiny level):" + #LF$
    content + "  1) Press F8 to make a new board." + #LF$
    content + "  2) Press Tab until Brush:# then draw walls with Space." + #LF$
    content + "  3) Press Tab until Brush:. then draw floor." + #LF$
    content + "  4) Press Tab until Brush:@ then Space to set the player start." + #LF$
    content + "  5) Press F5 to save. Press F2 to play!" + #LF$
    content + #LF$
    content + "1) Moving the cursor" + #LF$
    content + "  - Arrow keys move the yellow box (the cursor)." + #LF$
    content + "  - Hold Shift + arrows to move faster." + #LF$
    content + #LF$
    content + "2) Placing (drawing) tiles" + #LF$
    content + "  - Press Tab to pick what you want to draw." + #LF$
    content + "    Look at the bottom line: it shows Brush:<letter>." + #LF$
    content + "  - Press Space or Enter to draw that tile at the cursor." + #LF$
    content + "  - Press Delete to erase (it becomes a space)." + #LF$
    content + "  - Tile colors:" + #LF$
    content + "      [ / ] = change brush color (0..255)" + #LF$
    content + "      C     = pick brush color from tile under cursor" + #LF$
    content + #LF$
    content + "3) Boards (rooms)" + #LF$
    content + "  - F6 = previous board, F7 = next board." + #LF$
    content + "  - F8 = make a brand new board." + #LF$
    content + "  - Shift+F1 = Board Settings:" + #LF$
    content + "      Name = what the board is called" + #LF$
    content + "      StartX/StartY = where the player starts" + #LF$
    content + "  - Ctrl+M = Board Music editor:" + #LF$
    content + "      Compose -> opens Song Composer (smart generation + presets)." + #LF$
    content + "      Apply+Save -> writes music to this board and saves the .txt (if the world was already saved)." + #LF$
    content + "      Dark room = if ON, the room is dark" + #LF$
    content + "                and you need a torch/lantern to see" + #LF$
    content + "      ExitN/S/W/E = which board you go to when" + #LF$
    content + "                  you push into the border wall" + #LF$
    content + "                  (-1 means no exit)" + #LF$
    content + #LF$
    content + "4) Settings" + #LF$
    content + "  - F10 = Sound Settings:" + #LF$
    content + "      SFX Master Volume = how loud sound effects are (0.00..4.00)" + #LF$
    content + "      Music Volume      = how loud board music is (0.00..1.00)" + #LF$
    content + "      Pitch/Noise/Vibrato = tweak sound style" + #LF$
    content + "      Saved in " + #APP_NAME + ".ini under [Sound]: SfxMasterVol, MusicMasterVol" + #LF$
    content + "  - Shift+F10 = World Settings:" + #LF$
    content + "      Name = world name" + #LF$
    content + "      Start board = which board you start on" + #LF$
    content + "      ! markers one-shot = if ON, a hint disappears after" + #LF$
    content + "                          you step on it once" + #LF$
    content + "  - F11 = quick toggle for ! hint one-shot/repeat." + #LF$
    content + #LF$
    content + "5) Save / load" + #LF$
    content + "  World files (.txt):" + #LF$
    content + "    - Press F5 to choose a .txt file and save the world." + #LF$
    content + "      Tip: save often while editing." + #LF$
    content + "    - Press F9 to load a world .txt file." + #LF$
    content + "  Editor autosave:" + #LF$
    content + "    - While in the editor, PBZT writes pbzt_editor_autosave.txt every few minutes." + #LF$
    content + "    - It also writes pbzt_editor_autosave.txt when you leave the editor or exit." + #LF$
    content + "    - To recover: press Shift+F9 to load pbzt_editor_autosave.txt." + #LF$
    content + "      (Or press F9 and choose it manually.)" + #LF$
    content + "  Savegames (.sav.txt):" + #LF$
    content + "    - Default folder: 'saves' next to the executable." + #LF$
    content + "      (Config: " + #APP_NAME + ".ini -> [World] SaveDir=... )" + #LF$
    content + "    - (in game) F5 = quicksave (to slot 1..5)" + #LF$
    content + "    - (in game) F9 = quickload (from slot 1..5)" + #LF$
    content + "    - (in game) Ctrl+F5 = next quicksave slot" + #LF$
    content + "    - (in game) Ctrl+F9 = previous quicksave slot" + #LF$
    content + "    - (in game) Shift+F5 = save game..." + #LF$
    content + "    - (in game) Shift+F9 = load game..." + #LF$
    content + #LF$
    content + "6) Objects (things on top of tiles)" + #LF$
    content + "  - Objects are different from tiles." + #LF$
    content + "    They sit ON TOP of the map and can have scripts." + #LF$
    content + "  - F3 = edit/create an object at the cursor." + #LF$
    content + "  - F4 = delete the object at the cursor." + #LF$
    content + "  - Painting 'E' makes an enemy OBJECT (not a tile)." + #LF$
    content + "  - Painting '@' sets the player start spot." + #LF$
    content + #LF$
    content + "Tip: doors, keys, levers" + #LF$
    content + "  - h is a health pickup (walk on it to gain +1 HP)." + #LF$
    content + "  - D doors use + keys." + #LF$
    content + "  - A/B/C/F doors use 1/2/3/4 keys." + #LF$
    content + "  - L toggles nearby d/o lever-doors only." + #LF$
    content + #LF$
    content + "7) Passages (P tile teleports)" + #LF$
    content + "  - First, draw a real P TILE using the brush + Space." + #LF$
    content + "  - Move cursor onto the P tile." + #LF$
    content + "  - Press Shift+F3 to set where it teleports you." + #LF$
    content + #LF$
    content + "Other" + #LF$
    content + "  - F1 = this help" + #LF$
    content + "  - F12 = debug overlay (extra info)" + #LF$
    content + "  - Shift+F12 = debug window sizing" + #LF$
    content + "  - Ctrl+S = save preferences (" + #APP_NAME + ".ini)" + #LF$
    content + "  - Ctrl+L = reload preferences (" + #APP_NAME + ".ini)" + #LF$
    content + "  - Ctrl+T = run startup self-test (shows errors if something is wrong)" + #LF$
    content + "  - Ctrl+M = board music editor (composer + auto-save)" + #LF$
    content + "  INI keys: [Sound] SfxMasterVol, MusicMasterVol, SfxPitch, SfxNoise, SfxVib" + #LF$
    content + "  - F2 = back to game" + #LF$
    content + "  - Esc = quit" + #LF$ + #LF$
    content + "Common Problems (and fixes):" + #LF$
    content + "  - I cannot place a tile:" + #LF$
    content + "      Press Tab to pick a brush, then Space/Enter to draw." + #LF$
    content + "  - I can't find the brush I want (like P):" + #LF$
    content + "      Keep pressing Tab. It cycles through ALL brush letters." + #LF$
    content + "  - I pressed Delete and it did not remove a letter:" + #LF$
    content + "      Delete only erases the MAP TILE." + #LF$
    content + "      If it is an OBJECT, press F4 to delete the object." + #LF$
    content + "  - Shift+F3 says I'm not on a P tile, but I see 'P':" + #LF$
    content + "      You might be seeing a P OBJECT on top of the map." + #LF$
    content + "      Try F4 to delete the object, then paint a real P tile." + #LF$
    content + "  - My passage does nothing / says not configured:" + #LF$
    content + "      Put the cursor on the P tile and press Shift+F3." + #LF$
    content + "  - My passage sends me to the wrong place:" + #LF$
    content + "      Check Shift+F3: 'Use board start' makes it go to the board's StartX/StartY." + #LF$
    content + "      If that is OFF, then it uses DestX and DestY." + #LF$
    content + "  - I can't move to another board:" + #LF$
    content + "      Make exits in Board Settings (Shift+F1) or use a P passage." + #LF$
    content + "      Exits only work if you bump the BORDER wall (edge of the map)." + #LF$
    content + "  - Help key (F1) seems stuck:" + #LF$
    content + "      Close the help window, then press and release F1 again." + #LF$ + #LF$
    content + scriptHelp
  Else
    wTitle = #APP_NAME + " Help (Game)"
    content = ""
    content + #APP_NAME + " Game Help:" + #LF$
    content + #LF$
    content + "1) Moving" + #LF$
    content + "  - Arrow keys = walk" + #LF$
    content + "  - Hold Shift + arrows = run (move faster)" + #LF$
    content + #LF$
    content + "2) Important keys" + #LF$
    content + "  - F1 = help" + #LF$
    content + "  - F2 = editor (build your own levels)" + #LF$
    content + "  - F5 = quicksave (to slot 1..5)" + #LF$
    content + "  - F9 = quickload (from slot 1..5)" + #LF$
    content + "  - Ctrl+F5 = next quicksave slot" + #LF$
    content + "  - Ctrl+F9 = previous quicksave slot" + #LF$
    content + "  - Shift+F5 = save game..." + #LF$
    content + "  - Shift+F9 = load game..." + #LF$
    content + "  - R  = restart this world" + #LF$
    content + "  - PgUp / PgDn = change to another world file" + #LF$
    content + "  - Esc = quit" + #LF$
    content + "  - (in editor) F10 = Sound Settings (music + SFX volume)" + #LF$
    content + "  - (in editor) Ctrl+M = Board Music editor (composer + auto-save)" + #LF$
    content + #LF$
    content + "3) What the symbols mean" + #LF$
    content + "  .  floor (you can walk)" + #LF$
    content + "     space is also empty floor" + #LF$
    content + "  #  wall (you cannot walk through)" + #LF$
    content + "  $  treasure (walk on it to collect +10 score)" + #LF$
    content + "  +  key (walk on it to collect +1 key)" + #LF$
    content + "  D  door (needs a + key; walk into it to open)" + #LF$
    content + "  1  colored key #1 (opens door A)" + #LF$
    content + "  2  colored key #2 (opens door B)" + #LF$
    content + "  3  colored key #3 (opens door C)" + #LF$
    content + "  4  colored key #4 (opens door F)" + #LF$
    content + "  A/B/C/F  colored doors (need matching 1/2/3/4 key)" + #LF$
    content + "  L  lever (toggles nearby lever-doors d/o)" + #LF$
    content + "  d  lever-door (closed)" + #LF$
    content + "  o  lever-door (open)" + #LF$
    content + "  t  torch pickup (lets you see in dark rooms)" + #LF$
    content + "  T  lantern pickup (bigger light, lasts longer)" + #LF$
    content + "  h  health pickup (+1 HP when you step on it)" + #LF$
    content + "  ~  hazard (hurts you: -1 HP when you step on it)" + #LF$
    content + "  w  water object (solid; bump = :TOUCH and you can fish next to it)" + #LF$
    content + "  =  bridge object (walkable; place it over water)" + #LF$
    content + "  ^  exit (can move to the next board)" + #LF$
    content + "  E  enemy (bump into it to defeat it; +25 score)" + #LF$
    content + #LF$
    content + "Key / door rules:" + #LF$
    content + #LF$
    content + "  - + keys only open D doors." + #LF$
    content + "  - 1/2/3/4 keys only open A/B/C/F doors." + #LF$
    content + "  - Levers (L) only toggle lever-doors (d/o)." + #LF$
    content + #LF$
    content + "4) Special tiles" + #LF$
    content + "  !  hint marker:" + #LF$
    content + "     When you step on !, it shows a message." + #LF$
    content + "     The message is written on the map to the RIGHT of !" + #LF$
    content + "     until '.' or '#' reaches it." + #LF$
    content + "     Some worlds make hints disappear after you use them." + #LF$
    content + #LF$
    content + "  P  passage (teleporter):" + #LF$
    content + "     When you step on P, it can teleport you." + #LF$
    content + "     If it says 'not configured', open the editor (F2)" + #LF$
    content + "     and set it up with Shift+F3." + #LF$
    content + #LF$
    content + "  Dark rooms and light:" + #LF$
    content + "     Some rooms are dark (the editor can mark a board as Dark room)." + #LF$
    content + "     In dark rooms you can only see near the player." + #LF$
    content + "     Walk onto a torch (t) or lantern (T) to pick it up." + #LF$
    content + "     Light is automatic while you have fuel." + #LF$
    content + "     Fuel goes down when you move in dark rooms." + #LF$
    content + #LF$
    content + "Extra" + #LF$
    content + "  - F = fish (when standing next to water)" + #LF$
    content + "        (may catch: fish, treasure, boots...)" + #LF$
    content + "  - F12 = debug overlay (extra info)" + #LF$
    content + "  - Shift+F12 = debug window sizing" + #LF$
    content + "  - Ctrl+S = save preferences (" + #APP_NAME + ".ini)" + #LF$
    content + "  - Ctrl+L = reload preferences (" + #APP_NAME + ".ini)" + #LF$
    content + "  - Ctrl+T = run startup self-test (shows errors if something is wrong)" + #LF$
    content + "  - Ctrl+M = board music editor (composer + auto-save)" + #LF$
    content + "  INI keys: [Sound] SfxMasterVol, MusicMasterVol, SfxPitch, SfxNoise, SfxVib" + #LF$ + #LF$
    content + "Common Problems (and fixes):" + #LF$
    content + "  - The door (D) will not open:" + #LF$
    content + "      You need at least 1 + key. Walk on +, then bump the D door." + #LF$
    content + "  - The colored door (A/B/C/F) will not open:" + #LF$
    content + "      You need the matching colored key (1->A, 2->B, 3->C, 4->F)." + #LF$
    content + "  - The lever door (d) will not open:" + #LF$
    content + "      Levers only work on lever-doors: step on L next to d to toggle it." + #LF$
    content + "  - I am losing health / I keep dying:" + #LF$
    content + "      Watch out for ~ hazards. Each step on ~ hurts you (-1 HP)." + #LF$
    content + "      If you run (Shift+arrows), it is easier to step on hazards by accident." + #LF$
    content + "  - The exit (^) does not change boards:" + #LF$
    content + "      Some worlds only have 1 board. Exits only matter if there is another board." + #LF$
    content + "  - I pushed into the border but nothing happened:" + #LF$
    content + "      The world needs exits set in Board Settings (editor: Shift+F1)." + #LF$
    content + "  - Passage (P) does nothing / says not configured:" + #LF$
    content + "      The level maker must set it up in the editor with Shift+F3." + #LF$
    content + "  - A passage (P) sends me to the wrong place:" + #LF$
    content + "      It may be set to 'Use board start' (so you appear at that board's start)." + #LF$
    content + "      Or it may have a destination X,Y. Ask the level maker to check Shift+F3." + #LF$ + #LF$
    content + scriptHelp
  EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  OpenWindow(#Win_Help, 0, 0, 520, 420, wTitle, #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
  EditorGadget(#Gad_HelpText, 10, 10, 500, 360)
  SetGadgetText(#Gad_HelpText, content)
  SetGadgetAttribute(#Gad_HelpText, #PB_Editor_ReadOnly, 1)

  ButtonGadget(#Gad_HelpClose, 420, 380, 90, 30, "Close")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        If gid = #Gad_HelpClose
          Break
        EndIf
    EndSelect
  ForEver

  SavePrefs()
  CloseWindow(#Win_Help)
  RefocusMainWindow()
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 265
; FirstLine = 288
; Folding = -
; EnableXP
; DPIAware