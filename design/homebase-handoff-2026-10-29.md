# Home-base build handoff — 2026-10-29

Plan: `design/homebase-build-plan-2026-10-29.md` (§6 owner answers). Branch `codex/homebase-c`. Evidence: `evidence/homebase_2026-10-29/`.

## Studio
- Copy `outputs/ClimbCollect.HomeBase.Review01.rbxl`, SHA256 `249a2786…e705a` verified; byte copy `outputs/ClimbCollect.HomeBase.Review01.base.rbxl` (read-only attribute, same hash). **Not saved since launch.**
- Launched with `RobloxStudioBeta.exe <abs path>` (own process). MCP id this launch: `c7a0a682-e3cc-46eb-be16-0add7d9ef30c` (`x.sh` updated). PlaceId 0, GameId 0, `StudioAids` attribute false, HttpEnabled false, one process for the file.
- Other window open: integration Glassbloom (`climb-collect-integration`, id `173421a6…`) — never focus, sync or save there.
- Focus for perf samples: `SetForegroundWindow` on the HomeBase PID only (PowerShell, Alt-key trick), foreground PID verified before sampling.

## P0 results (`p0/baseline.json`)
- Source drift: 63/63 match (`p0/drift.json`); `StudioTests` absent by design (sync SKIP).
- Suites 40/40 pass (`p0/suites.txt`).
- HUD (`p0/checks/`, `p6_checks.sh`): overflow 186 screens × 6 sizes 0 errors; state audit 0, coverage rest 10.9 / chase 10.4 %; rest 499, Shop 1,747; rest avg 16.6 / worst 20.2 ms, Shop worst 20.4 ms, 0 > 33 ms; 90 Robux buttons disabled, 0 unselectable; motion caps as P6; console clean.
- Place: edit descendants 15,526 (15,812 after HomeProtos); workspace edit 8,755, runtime 10,432; Sanctuary 2,780 (promenade 1,497, lodges 1,032, gate 151, plots 96). Per plot: folder 11 (runtime 142), lodge 128, other parts in rect 35–36. Plan's 13,707 figure is superseded by these numbers.
- Home views (`p0/home_views.json`, focused, desktop GPU ~1 ms): median 16.6–16.7 ms, p95 ≤ 18.1, worst ≤ 20.6, 222–525 draw calls, 335k–514k triangles. Not a device measurement.
- Emulator: edit viewport 750×401 (active; device id not readable by script).
- Protos (`p0/protos.json`) in `ServerStorage.HomeProtos`: Lantern 5 parts (placed scale 1.7), Tree 13 (2.2; two neighbour boughs trimmed), PlantingBed 11 (1.4), Boulder 1 (2.5), Divider_01 116, Lodge_01 126. Descriptor has sizes/offsets/colours/materials; divide sizes by `PlacedScale` for the original proto.
- New QA scripts: `tools/rmcp/qa/home_views.client.luau`, `tools/rmcp/qa/plot_counts.luau`.
