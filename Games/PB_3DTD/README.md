# 3D Tower Defense

This workspace includes a self-contained PureBasic 6.30 x64 tower defense game built with the built-in OGRE-backed `Engine3D` library.

Files:

- `PB_3DTD.pb` - main entry point, globals, declarations, and main loop
- `td_ui.pbi` - sidebar UI, overlays, sounds, and gadget handling
- `td_scene.pbi` - path/grid helpers, materials, meshes, and scene setup
- `td_towers.pbi` - tower selection, stats, build, upgrade, and sell logic
- `td_combat.pbi` - enemies, projectiles, damage, combat effects, and waves
- `td_input.pbi` - hover logic and keyboard/mouse input handling

How to run:

1. Open `PB_3DTD.pb` in PureBasic 6.30 x64.
2. Compile for 64-bit on Windows.
3. Keep all `.pbi` include files in the same folder as `PB_3DTD.pb`.
4. Make sure the standard PureBasic `Engine3D` runtime is available from your normal PureBasic installation.

Game overview:

- 3D tower defense played on a fixed lane map.
- Warm-toned path tiles show the enemy route; lighter tiles are buildable.
- A start screen, end-state overlay, wave forecast panel, and right-side control UI are included.
- The codebase is split into small include modules so UI, combat, towers, scene setup, and input are easier to extend.
- The game now includes multiple playable level layouts with different routes and wave identities.

Architecture:

- `PB_3DTD.pb` defines shared constants, enums, structures, globals, procedure declarations, include links, and the main loop.
- `td_scene.pbi` owns the board, path, materials, meshes, and 3D scene bootstrap.
- `td_ui.pbi` owns sidebar text/buttons, overlays, restart flow, and simple sound hooks.
- `td_towers.pbi` owns tower definitions, selection, costs, upgrades, selling, and build visuals.
- `td_combat.pbi` owns enemy spawning, projectile travel, damage, hit effects, and wave progression.
- `td_input.pbi` owns hover detection, board clicks, keyboard shortcuts, and mouse input.

How to add a new tower:

1. Add a new `#TowerType_*` value in `PB_3DTD.pb`.
2. Add cost/name handling in `TowerBaseCost()` and `TowerName()` in `td_scene.pbi`.
3. Add stats in `ConfigureTowerStats()` in `td_towers.pbi`.
4. Add build visuals in `BuildTower()` in `td_towers.pbi`.
5. Add projectile visuals/behavior in `SpawnProjectile()` and, if needed, targeting logic in `UpdateTowers()` in `td_combat.pbi`.
6. Add UI/button/shortcut wiring in `td_ui.pbi` and `td_input.pbi`.
7. Add any tower-specific sound or muzzle-flash behavior in `td_ui.pbi` or `td_combat.pbi`.

Balancing tips:

- `range` controls board coverage; small increases have a large impact on path uptime.
- `fireDelay` is one of the strongest tuning knobs because it changes both burst feel and sustained DPS.
- `damage` should be tuned together with `fireDelay`; compare towers by rough DPS, not single-shot value alone.
- `projectileSpeed` changes how reliable a tower feels against fast enemies, especially swarms and late runners.
- `splash` heavily increases crowd control value and should usually be paired with slower reloads or higher cost.
- `slowPower` is a movement multiplier, so lower values mean stronger slows.
- `slowTime` controls how consistently a control tower can lock lanes when several enemies stack up.
- `cost` should reflect the earliest wave where a tower becomes efficient, not just its max-upgrade strength.
- Test balance with both manual early-wave launches and normal pacing, since economy timing changes tower value a lot.

Controls:

- Left click a buildable tile to place the currently selected tower.
- Left click an existing tower to inspect it and show its range.
- Right click to cancel build mode.
- `Enter` places on the currently hovered tile.
- `1` selects `Pulse`.
- `2` selects `Cannon`.
- `3` selects `Frost`.
- `4` selects `Beam`.
- `5` selects `Mortar`.
- `6` selects `Sky`.
- `Space` launches the next wave early.
- `T` cycles the selected tower's targeting mode.
- `U` upgrades the selected tower.
- `S` sells the selected tower.
- `Esc` quits.
- `F1` toggles the debug panel.
- On the start overlay, use the level button or `Left` / `Right` arrows to cycle levels before the run begins.

Tower roster:

- `Pulse` - balanced rapid fire single-target tower.
- `Cannon` - slower heavy hitter with splash damage.
- `Frost` - fast control tower that slows enemies.
- `Beam` - short-range, very fast single-target pressure tower.
- `Mortar` - long-range artillery tower with strong splash.
- `Sky` - fast anti-air interceptor with long reach.

Enemy roster:

- `Runner` - basic fast target.
- `Brute` - slower, tougher frontline unit.
- `Swarm` - smaller, faster, lower-health enemy.
- `Shield` - mid-speed enemy with a damage-absorbing shield layer.
- `Splitter` - breaks into swarms when destroyed.
- `Glider` - flying enemy that only anti-air towers can hit.
- `Leech` - regenerates health over time and resists the strongest slows.
- `Siege` - very heavy assault unit that deals major core damage if it slips through.
- `Overseer` - alternate late boss that shields escorts, deploys support units, and surges forward.
- `Boss` - large high-health threat with rotating surge, shield, and support abilities on boss waves.

Included gameplay systems:

- 6 level layouts: `Foundry Bend`, `Cross Current`, `Granite Spiral`, `Red Mesa`, `Split Exchange`, and `Iron Ladder`
- 6 tower classes: Pulse, Cannon, Frost, Beam, Mortar, Sky
- 10 enemy classes: Runner, Brute, Swarm, Shield, Splitter, Glider, Leech, Siege, Overseer, Boss
- varied enemy silhouettes and accent colors for stronger readability
- cone, sphere, cube, and cylinder-based enemy/tower forms for more visual variety
- tower targeting modes: `First`, `Nearest`, and `Strongest`
- anti-air rules: `Pulse`, `Beam`, and `Sky` can hit flying enemies
- simple damage-over-time burn effect on `Pulse`
- boss abilities that alternate between speed surges, shield pulses, and support swarm releases
- a second boss archetype with escort shielding, support deployment, and command surges
- level-specific wave mixes so each arena emphasizes different enemy pressure patterns
- floating ambient scene particles and level props for more atmosphere
- 12-wave progression with boss waves
- challenge modifiers: `Standard`, `Frugal`, `Blitz`, and `Iron Core`
- simple progression save file in `progress.cfg` tracking best wave, cleared level, and total victories
- upgrades, selling, cash economy, lives, pacing, pause, and speed control
- early wave launch bonus
- restart flow, polished title/menu overlay, and victory/defeat overlay
- sidebar wave forecast for the upcoming enemy mix
- pre-placement ghost range preview for the currently selected tower
- tower specials at higher levels, including pulse burst, frost nova, mortar chill, and twin sky shots
- hit flashes, muzzle flashes, floating health bars, and simple built-in Windows sound hooks
- fully procedural visuals using only built-in PureBasic 3D primitives and materials

Debug tools:

- Press `F1` to show or hide the in-game debug panel.
- `G` adds `100` gold.
- `N` forces the next wave immediately when possible.
- `L` repairs the core by `5` lives.
- `K` clears all active enemies.
- The same actions are also available as small buttons in the debug panel.

Balance config:

- The game creates `PB_3DTD/balance.cfg` automatically if it does not exist.
- You can tune global balance values there without editing source.
- Supported keys:
  - `tower_damage_scale`
  - `tower_range_scale`
  - `enemy_health_scale`
  - `enemy_speed_scale`
  - `burn_scale`

Notes:

- Sounds use built-in Windows system sound aliases through `PlaySound_()`, so they may vary with the local Windows sound theme.
- The project does not depend on external art or audio assets.
