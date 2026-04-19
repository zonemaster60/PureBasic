# AdventureGen: Procedural Adventure Builder
# Documentation - Arcane Edition

### 1. Overview
AdventureGen is a small, data-driven text adventure prototype. It builds a short world from theme data and lets you explore it in the console or export the currently selected setup as a standalone build.

### 2. Main Menu
- **[R] Random**: Starts an adventure using random values from the loaded theme data.
- **[W] Wizard**: Lets you choose the Theme, Setting, Culture, Landmark, Role, Goal, and Twist before the adventure begins.
- **[H] Help**: Displays this help file.
- **[E] Exit**: Leaves the application.

### 3. Adventure Commands
- **N, S, E, W**: Move between connected rooms.
- **LOOK** or **L**: Reprint the current room description, exits, and player status.
- **INV** or **STATUS**: Show the current role, theme, setting, health, mana, attack value, and full inventory details.
- **TAKE _item_** or **GET _item_**: Pick up a visible item in the current room.
- **USE _item_**: Activate an item you are carrying, such as the torch or a healing tonic.
- **EXAMINE _target_** or **X _target_**: Inspect an item or presence in detail.
- **ATTACK _target_** or **FIGHT _target_**: Attack a hostile presence in the current room.
- **HELP** or **?**: Show the in-game command summary.
- **EXIT**: Leave the current adventure and return to the main menu.

### 4. Builder-Only Command
- **BUILD**: Available only in the AdventureGen builder. It writes a temporary generated config include beside `main.pb`, compiles `My_Adventure.exe` with `pbcompiler`, and then removes the temporary build files.

### 5. World Generation Notes
- Each adventure creates a compact five-room layout centered on the selected landmark.
- Wizard mode uses the actual values loaded from `data\themes.csv`, including goals and twists.
- Some rooms may be dark, and the starter torch can be used to reveal details in those spaces.
- Rooms can now contain takeable items, healing supplies, and hostile presences that can be examined or fought.
- Defeating the guardian reveals a sigil; bring it back to the landmark and **USE** it there to win the adventure.

### 6. Technical Details
- **Primary source file**: `main.pb`
- **Embedded help file**: `HELP.md`
- **Theme data**: `data\themes.csv`
- **Support modules**: `app_core.pbi`, `app_helpers.pbi`, `app_content.pbi`, `app_world.pbi`, `app_export.pbi`, `app_ui.pbi`
- **Requirements**: PureBasic v6.30 (x64) and `pbcompiler` in your PATH if you want to use **BUILD**

### 7. Starting the Adventure
1. Run `AdventureGen.exe` or open `main.pb` in PureBasic.
2. Choose **[R]andom** for a quick run, or **[W]izard** to pick your own setup.
3. Use **HELP** during an adventure if you need the command list again; generated adventures do not include **BUILD**.
