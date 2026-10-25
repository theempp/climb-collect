# Local alpha integration review — October 24, 2026

Owner decisions: one place; **all three sanctuary gates enter Blossom**. The existing mountain profile remains the sole authority. See [the interface contract](integration-contract-2026-10-24.md).

The isolated branch is `codex/mountain-sanctuary-integration`, based on mountain commit `8d2d263` plus the hash-verified dirty Final56 snapshot. HUD runtime is selectively merged from `6019525`; its older baked world is not imported. No merge, push or Roblox publication has occurred. The original lobby remains separate.

Review artifact: `evidence/integration_2026-10-24/MountainEmpire.Alpha.Review06.rbxlx`, native-save SHA `78f2916fb646de4cbae0d7be16c9a2f84066bfe0a800ab8696cbcdf1b17ce409`. Open the baked review, not the Rojo source package: sanctuary terrain is baked, and a source-only build does not contain the sanctuary geometry.

## Implemented

- Eight server-owned plot reservations, guarded against stale connections; free-slot fallback and same-server preferred-slot reconnect. Ninth reservation refuses safely. No persisted plot migration.
- Spawn after `LoadCharacterAsync` completes so Roblox cannot overwrite the assigned plot position. Sanctuary death returns home; mountain checkpoint/cargo rules remain intact.
- Three proximity-checked Blossom gates; server-validated return to the player's own plot. Living, healthy-profile, safe-origin, destination eligibility and battle checks precede travel. Failed movement cannot extract cargo; successful travel uses existing extraction.
- Existing incubation, hatch, training and income eligibility recognizes the owned plot and the existing refuge. Small service markers open existing screens. Habitat/build/party/ranking/shop services remain unavailable.
- HUD context identifies the sanctuary and plot; return wording is updated. Final56 analytical mover velocity remains preserved.

## Verification evidence

- `cli-tests.txt`: 1,102 checks across rules, traversal, route geometry, HUD protocol/state/presentation, server actions, profile/combat adapters and new reservation/travel modules. `compile.txt`: all mountain Luau compiled; Rojo source-package build passed.
- `MountainEmpire.Alpha.Review04.verification.json`: 56 saved runtime/world sources match; all 19,914 mountain parts retain checked transforms, size, collision, anchoring, material and RGB color; all 3,731 sanctuary parts match after +4096 X translation. Duplicate sibling names are individually counted. Native packed-color alpha bytes are ignored; RGB is compared exactly. This is not an assertion of whole-world XML byte equivalence.
- `terrain-addition-audit.json`: native mountain-region SmoothGrid is byte-identical before/after sanctuary terrain paste, bounds (-704,-32,-704)–(640,1000,640), SHA `4791a39791694aa55fcc32e369f1e293d2e2c442dec0910d361ef63b17e67931`. Whole combined terrain differs because sanctuary terrain was added. Final56 global material colors remain in use.
- Original Final56 and Step3 hashes still match. Working03 was saved natively with the combined terrain and corrected spawn; Review04 was built from that saved file and opened in a separate Studio session.
- `ui-audit.json`: all 23 tabs navigated, zero checked text/touch-target errors at 1250×350 safe viewport, one HUD root and 117 descendants after closing. This is desktop-window evidence, not physical mobile input acceptance.
- `natural-loop-attempts.json`: first attempt verified fresh owned-plot spawn, walking to West gate, Blossom arrival and an earned wild egg; overly close encounter approach left the route and return failed. Cargo recovery activated after falling. No position, inventory, health or eligibility grants were used. This failed attempt remains evidence, not a completed natural-loop claim.

## Corrections and remaining acceptance

Read-only integration review found that nearby checkpoint origins did not require discovery. The integrated server now checks discovery and kingdom eligibility. It also identified a pre-existing respawn weakness during profile-save outages: a skipped delayed respawn has no automatic retry. That broader persistence recovery fix remains open; Studio memory tests do not prove hosted DataStore behavior.

Initial Main merge was retried after CRLF normalization; initial package XML declaration was corrected to UTF-8. Lune reported an unsupported global terrain property during export; only the script-free model and native TerrainRegion template were imported from that conversion. Native region audit independently verifies the mountain terrain.

The previously recovered HUD checkout disappeared externally during this run after its source had been copied. This task did not delete or archive it. Commit `6019525`, imported sources, the original recovery backup and integration checkpoints preserve the work; earlier recovery notes are historical, not proof that the recovered directory still exists.

D01 owner visual acceptance remains open, including the sanctuary's appearance under the shared terrain palette. Actual eight-client, physical devices, hosted rejoin/persistence and the full public-launch services remain open. This is a local integration review, not a public release candidate. Further live acceptance results are appended below.

## Live acceptance follow-up

`natural-loop-review04.json` passes fresh spawn, walking through West gate, normal wild encounter/egg, checkpoint extraction, correct plot return, existing incubation timer, free hatch and equip. Initial training was correctly unavailable with only 1 coin. In the same unreset profile, `natural-training-review04.json` walks through Center gate, earns the existing Blossom landmark reward, returns along the route, travels home and trains the hatched creature: 21→6 coins, level 3 after the existing +80 XP. Both runs use normal movement, prompt inputs and existing server requests; no position, health, inventory, coins or unlock grants. They are automated solo evidence, not human timing or physical-input tests. East has the same inspected prompt and server destination mapping; no distinct natural East-gate run is claimed.

`multiplayer-spawns.json`: three actual concurrent local clients received slots 1, 2 and 3, matching owner UserIds (-1,-2,-3), with each character within 3.2 studs of its saved spawn. All three had the HUD. `other-plot-denials.json`: Player1 walked to Player2's plot; training and home/locked-checkpoint travel were refused by the real server. Removing Player3 released Plot_03; same-UserId preferred-slot reuse and capacity exhaustion are covered by pure allocator checks, not a hosted reconnect claim.

Review05 removes the three temporary terrain-audit/template instances while preserving the entire baked Workspace. Its cleanup and verification JSON files pass the same 56-source/geometry checks, with no QA-named instances or TerrainRegion templates. It opened successfully and its smoke test shows one HUD, three gate prompts, and a natural owned-plot spawn; console contains only the normal ready line.

Review06 is a native XML Save As of clean Review05. Its source/geometry audit passes, and its entire combined SmoothGrid matches native Working03 exactly (SHA `a7b15d51688203161c0912343444c2422bb5d8dbf342690947d57e0e5c0670ba`), so the final save did not change terrain. The Review06 window was closed and its absence confirmed before reopening from disk. Original reviews remain preserved. Local three-client owner release was verified; an attempted additional late client did not join and is not counted as successful late-join acceptance.

`review06-reopen.json` confirms clean startup after reopening: slot 1, spawn distance 3.19 studs, one ready HUD and all three Enter Blossom prompts. Play was stopped after verification. Final review remains local; no QA scripts or terrain templates were added to it. The existing HUD's developer UIProbe hook is retained.

Recovery target: `C:/Users/HOME!/Documents/ClimbCollect-Recovery/integration-2026-10-24-checkpoint02`; its `manifest.json` records the verified copied files. This preserves the current mountain source/art, all integration artifacts/evidence, docs, a tracked diff and an all-refs Git bundle outside the ephemeral worktree. Original recovery `2026-10-24-030555Z` retains the historical input evidence.

Project/vault graph refreshed after the evidence-pointer and decision updates: 3,407 merged nodes / 6,046 edges / 108 cross-links, export `2026-10-24-234712`. Graph coverage remains the original project and vault, excluding isolated integration source. Final freshness check is recorded in `graph-status.txt`.
