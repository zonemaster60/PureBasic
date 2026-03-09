# AdventureGen: Procedural Adventure Builder
## PureBasic v6.30 (x64) Documentation - Arcane Edition

### 1. Overview
AdventureGen is a small, data-driven text adventure prototype. It builds a short world from theme data and lets you explore it in the console or export the currently selected setup as a standalone build.

### 2. Main Menu
- **[R] Random**: Starts an adventure using random values from the loaded theme data.
- **[W] Wizard**: Lets you choose the Theme, Setting, Culture, Landmark, and Role before the adventure begins.
- **[H] Help**: Displays this help file.
- **[E] Exit**: Leaves the application.

### 3. Adventure Commands
- **N, S, E, W**: Move between connected rooms.
- **LOOK** or **L**: Reprint the current room description, exits, and player status.
- **INV** or **STATUS**: Show the current role, theme, setting, health, mana, and inventory count.
- **HELP** or **?**: Show the in-game command summary.
- **BUILD**: Write the current selection into the project's `src\current_config.pbi` and attempt to compile `GeneratedAdventure.exe` with `pbcompiler`.
- **EXIT**: Leave the current adventure and return to the main menu.

### 4. World Generation Notes
- Each adventure creates a compact five-room layout centered on the selected landmark.
- Wizard mode now uses the actual values loaded from `data\themes.csv`.
- Some rooms may be dark, but the current prototype does not yet include torch or combat systems.

### 5. Technical Details
- **Primary source file**: `main.pb`
- **Embedded help file**: `HELP.md`
- **Theme data**: `data\themes.csv`
- **Requirements**: PureBasic v6.30 (x64) and `pbcompiler` in your PATH if you want to use **BUILD**

### 6. Starting the Adventure
1. Run `AdventureGen.exe` or open `main.pb` in PureBasic.
2. Choose **[R]andom** for a quick run, or **[W]izard** to pick your own setup.
3. Use **HELP** during an adventure if you need the command list again.
