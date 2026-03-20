MyCPUCooler

Small Windows power-plan tuner for lowering CPU temperatures with built-in `powercfg` settings.

What it does

- Creates and reuses a custom Windows power plan.
- Tunes CPU max/min state for both AC and battery.
- Exposes processor boost modes when supported.
- Exposes system cooling policy when supported.
- Exposes PCIe Link State Power Management (ASPM) when supported.
- Can apply settings on startup with silent mode.
- Verifies applied values by reading them back from `powercfg`.

Presets

- `Battery Saver`: strongest cooling and battery bias. Good for light work on battery.
- `Eco`: lower heat with better responsiveness than Battery Saver.
- `Quiet`: keeps heat and fan noise down for browsing, office work, and streaming.
- `Cool`: strong cooling without feeling too limited. Good default for hot laptops.
- `Balanced`: closer to normal Windows behavior with moderate savings.
- `Performance`: hottest preset. Best only when you need full speed.

Recommended defaults

- Thin gaming or creator laptops: `Cool` on AC, `Eco` or `Quiet` on DC.
- Older or heat-limited laptops: `Quiet` on AC, `Battery Saver` on DC.
- General office laptops: `Balanced` on AC, `Eco` on DC.

Practical notes

- Setting AC max CPU to `99%` often disables turbo boost on many Intel systems and can cut temperatures a lot.
- Some systems hide or ignore boost, cooling policy, or ASPM settings. The app disables unsupported controls.
- `Passive` cooling policy means throttle first, fan later.
- `Active` cooling policy means fan first, throttle later.

Startup behavior

- `--silent` applies saved settings only when Auto Apply is enabled.
- Task Scheduler mode avoids a UAC prompt at login.

Typical safe starting point

- AC profile: `Cool`
- DC profile: `Eco`
- Boost: `Disabled` or `Efficient Enabled`
- Cooling policy: `Passive` if you want lower heat, `Active` if you prefer fan-first behavior
- ASPM: `Maximum Power Savings` if supported

Files

- Main source: `src/MyCPUCooler.pb`
- Output executable configured in source IDE options: `MyCPUCooler.exe`
