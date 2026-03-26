MyCPUCooler

Small Windows power-plan tuner for lowering CPU temperatures with built-in `powercfg` settings.

What it does

- Creates and reuses a custom Windows power plan.
- Tunes CPU max/min state for both AC and battery.
- Exposes separate AC and battery boost modes when supported.
- Exposes separate AC and battery cooling policy when supported.
- Exposes separate AC and battery PCIe Link State Power Management (ASPM) when supported.
- Can apply settings on startup with silent mode.
- Verifies applied values by reading them back from `powercfg`.
- Estimates a simple thermal score so you can see whether a profile is cooling-focused or performance-focused.
- Shows live built-in telemetry for CPU load, reported thermal zone temperature, and current power source.
- Adds a system tray icon with quick preset switching, apply, restore, and show/hide controls.
- Shows tray balloon notifications when settings are applied and when the reported thermal zone gets too hot.
- Includes a compact mini dashboard for quick telemetry and one-click preset changes.
- Lets you configure the heat alert threshold and turn popup heat warnings on or off.
- Can auto-switch to a cooler preset if high heat persists for a configurable duration.
- Lets startup open the main window, stay in tray, or open the mini dashboard.
- Can restore the previous manual preset automatically after temperatures cool down.
- Shows a compact recent-history graph for thermal and CPU load data in the mini dashboard.
- Supports separate AC and battery auto-cooling/restore behavior.
- Can export and import named cooling profiles as `.ini` files.
- Supports in-app custom profile slots for saving and reloading favorite tuning sets.
- Includes a temporary benchmark mode that pauses automation and restores normal behavior afterward.

Presets

- `Battery Saver`: strongest cooling and battery bias. Good for light work on battery.
- `Eco`: lower heat with better responsiveness than Battery Saver.
- `Quiet`: keeps heat and fan noise down for browsing, office work, and streaming.
- `Cool`: strong cooling without feeling too limited. Good default for hot laptops.
- `Balanced`: closer to normal Windows behavior with moderate savings.
- `Performance`: hottest preset. Best only when you need full speed.

AC/DC split tuning

- You can now tune plugged-in and battery behavior independently for boost, cooling policy, and ASPM.
- This makes it easier to run a cooler AC setup while still keeping battery mode more conservative.
- The UI shows a thermal posture hint and score so you can compare profiles faster.
- The tray icon lets you keep the app running without leaving the full window open.
- The mini dashboard gives you a lightweight control surface for `Cool`, `Balanced`, `Performance`, and quick apply.
- The mini dashboard now includes `Battery`, `Eco`, `Quiet`, `Cool`, `Balanced`, and `Performance`, plus an AC/DC profile badge.
- The mini dashboard also controls auto-cooling profile selection, delay timing, and startup mode.
- The mini dashboard now includes a thermal/load history graph and automatic restore-after-cooldown controls.
- The mini dashboard adapts its automation controls to the current power source so AC and battery can behave differently.
- The mini dashboard also acts as the final control hub for custom slots, benchmark mode, import/export, telemetry history, and automation tuning.

Recommended defaults

- Thin gaming or creator laptops: `Cool` on AC, `Eco` or `Quiet` on DC.
- Older or heat-limited laptops: `Quiet` on AC, `Battery Saver` on DC.
- General office laptops: `Balanced` on AC, `Eco` on DC.

Practical notes

- Setting AC max CPU to `99%` often disables turbo boost on many Intel systems and can cut temperatures a lot.
- Some systems hide or ignore boost, cooling policy, or ASPM settings. The app disables unsupported controls.
- Thermal zone temperature comes from firmware via Windows WMI and may be missing or imperfect on some laptops.
- `Passive` cooling policy means throttle first, fan later.
- `Active` cooling policy means fan first, throttle later.

Startup behavior

- `--silent` applies saved settings only when Auto Apply is enabled.
- Task Scheduler mode avoids a UAC prompt at login.

Typical safe starting point

- AC profile: `Cool`
- DC profile: `Eco`
- AC boost: `Disabled`
- DC boost: `Disabled`
- AC cooling policy: `Active` if you want fan-first cooling, `Passive` if you want the lowest heat output
- DC cooling policy: `Passive`
- AC ASPM: `Moderate Power Savings`
- DC ASPM: `Maximum Power Savings` if supported

Files

- Main source: `src/MyCPUCooler.pb`
- Include layout:
  - `src/MyCPUCooler.System.pbi` for low-level Windows, telemetry, registry, process, and shared app state helpers
  - `src/MyCPUCooler.Settings.pbi` for default settings, load/save, normalization, and startup registration
  - `src/MyCPUCooler.UI.Layout.pbi` for gadget enums, layout helpers, tray helpers, and window construction
  - `src/MyCPUCooler.UI.Actions.pbi` for UI actions, event handlers, preset application, and automation behavior
  - `src/MyCPUCooler.Runtime.pbi` for app startup and the main event loop
- Output executable configured in source IDE options: `MyCPUCooler.exe`
