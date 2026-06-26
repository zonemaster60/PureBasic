# PureBasic Ogre 3D Chess

Standalone PureBasic 6.40 x64 source for a 3D chess game using the built-in Ogre renderer.

## Run

1. Open `PB_3DChess.pb` in the PureBasic 6.40 x64 IDE.
2. Ensure the subsystem is the default Ogre/Engine3D setup.
3. Compile and run.

## Controls

- Arrow keys: move the board cursor
- Enter or Space: select a white piece, then select its destination
- Backspace: cancel selection
- N: new game
- Escape: quit

## Gameplay

- Player 1 controls white.
- Player 2 is an AI controlling black.
- The move validator supports normal moves, captures, promotion to queen, castling, en passant, check, checkmate, and stalemate.
- The AI is intentionally lightweight: it evaluates legal black moves using material, center control, and check pressure.
