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

## P1 results (`p1/summary.json`), STOP 2 pending
- Commit `f666634`: `Competition.luau` deleted; `RegisterDefense`/`ChallengeDefense` removed from UIProtocol, ClientState, UIRequests (now "Unknown action."); Main drops the require, `competition=` and summit `trophies+=100` (coins stay); 'Competition' dais removed from `World.luau` (no baked dais existed in the place); Social hub = one Leaderboard tab (honest "coming soon" until P5/P6); Profile Trophies tile/banner → Rank from `ui.explorer`; Controller party re-render and challenge reveal removed; `partyInvites`/`defenses` capabilities removed; StudioTests defense checks dropped; tools `audit_saved.py`/`sync_edit.luau` no longer list Competition.
- Inert: `trophies`, `competitionAt` stay in `Rules.newProfile` and `Profiles.valid`. Kept: EggRaids, RaidConfig, RaidHazards, Guardians, Bats, Guardian co-op join. "shield" hits in code are UI shape images and a combat buff, not PvP shields.
- Suites 40/40 (ui_server 66, run_combat_raids 43; raid/bat/guardian suites unchanged). Grep: only the three new rejection assertions.
- Studio: `sync_hud.py <id> --changed 9e05af5` + `ServerStorage.MountainWorld.World` source (was equal to the pre-edit repo) + Competition module destroyed; drift 0. Overflow 174 screens × 6 sizes 0 errors; state audit 0; rest 499, Shop 1,747, worst 21.8 ms; console clean. StudioAids false, PlaceId 0. Copy **not saved**.
- Legacy repo: SUPERSEDED banner lines in 3 docs (no commits there); memory `release-decisions-2026-10-28` and vault Decisions marked superseded.
- **STOP 2 approved** (owner popup, 2026-10-29). **Saved** 22:03 (Ctrl+S via PowerShell foreground on PID 9788 only, title verified; PlaceId 0, StudioAids false, Http off, single process, viewport 750×401). SHA256 `02be7adf03be4dfdfdb4127f4dcde8129de426d9c141ea105bfd64e8b40e464c`, 1,474,979 bytes; base copy unchanged (`249a2786…`). Contains P1 build + `ServerStorage.HomeProtos` (binary strings are compressed, so not grep-verified; a cold-open check is still to do). Next: P2 server data/rules.

## P2 results (`p2/`), STOP 3 pending
- Cold open (`p2/coldopen_drift.json`): HomeBase was closed, relaunched with `RobloxStudioBeta.exe <abs path>` (PID 4744), MCP id `096c538f-48c2-402e-9278-00704bc725e2` (`x.sh` updated). Saved copy `02be7adf…` opens with `ServerStorage.HomeProtos` (6 protos), no Competition module, P1 protocol; PlaceId 0, StudioAids false, Http off; drift 62/63 (StudioTests absent by design). New tool `tools/rmcp/drift.py <id> [out]`.
- Commit `88eb572`. Schema + numbers + migration table: `design/homebase-schema-2026-10-29.md`. All numbers PROPOSED.
- Suites 42/42 (`p2/suites.txt`): new home_rules 91, home_profile 15; explorer_rules 115, egg_raids 36, tycoon 71, tycoon_economy 109, ui_protocol 126, ui_server 87, run_persistence 73. Mutations `tools/mutate_home.py`: 30/30 killed (`p2/mutation.json`).
- Studio: `sync_hud.py <id> --changed 9e05af5` (+HomeRules, +HomeTiers created); drift 64/65 (`p2/drift.json`). Live QA (`p2/live_qa.json`, `tools/rmcp/qa/home_p2_live.client.luau`, fresh profile rank 1 / 0 coins, plot 1): 13 refusals with the right message, place/inspect/clear commit, coins 0 -> 0; console 0 errors/warnings. HUD audits (`p2/checks/`): overflow 174 × 6 0, state 0, rest 499, Shop 1,747, rest worst 21.4 / Shop 20.9 ms. StudioAids false, PlaceId 0. **Copy not saved after P2.**
- Gotcha: the Bash tool unescapes `\` and `\n` inside heredocs; write patch scripts with Write, then run them.
- Not live-verified (needs coins/XP fixtures in Play): successful tier raise and prop buy, 7-8 refund on a real saved profile. Covered by run_persistence/ui_server.
- Open: no player notice for the 7-8 refund (P6); `TycoonWorld` still builds 8 habitat pads (P4 rewrite).
- **STOP 3 approved** (owner popup): all as built except **no daily secure-XP cap** (owner wants grind; monetisation later). `ExplorerRules.secureCountMax` bounds the daily counter only. 42/42 suites (explorer_rules 116), 31/31 mutants.
