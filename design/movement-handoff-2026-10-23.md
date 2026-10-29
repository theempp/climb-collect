# Four-mountain movement — handoff 2026-10-23

Continues the [movement plan](../docs/superpowers/plans/2026-10-22-four-mountain-movement.md) where the Codex chat stopped.

## Where Codex stopped

Codex worked outside this folder, in `C:\Users\HOME!\.codex\worktrees\movement-finish\climb&collect`. Its first worktree was deleted during an owner cleanup; the surviving code is in `evidence/movement_2026-10-22/continuation-rescue/surviving-work-2329.zip` here. Its ledger (`.superpowers/sdd/2026-10-22-four-mountain-movement/progress.md` in the worktree) shows Task 1 committed (`18e4987`) and Tasks 2–3 integrated, with fixtures passing in a Studio opened from the deleted file. Live acceptance and all of Task 4 had not started. The movement-finish review file did not contain the movement code yet.

## Done in this pass

- Synced the 14 movement sources into Studio `ClimbAndCollect.FourMountains.Movement.Review.rbxl` (worktree root, Studio PID 40092). Checksums match. StarterPlayer fallback speed is 16.
- Fixed two issues found in live play. (1) Sprint cancelled itself within about 0.8 s on uneven or uphill ground, because Traversal's `grounded()` reads false when vertical velocity is above 7. There is now a 0.4 s airborne grace; jumps and longer air still clear sprint, and the lobby keeps 22 in the air. (2) The client no longer sends redundant "sprint off" requests on every jump input, which could use up the 10-per-second request cap.
- Live checks with real keyboard input: lobby run 22.4 studs/s with one run track; mountain walk 16.3; sprint 23.4 at 10 stamina/s; standing still keeps sprint on with no drain and 13/s recovery; exhaustion drops to walking, shows RECOVERING and does not resume on its own; emulated L3, button click and typing suppression work; menu lease holds; respawn is clean. Anti-cheat: a forged 72-stud teleport plus deposit is refused and the cargo kept; creeping at 40 studs/s is reset and quarantined while 20 studs/s passes; an honest walk-and-deposit works and a replayed transaction is not double-counted.
- Suites: CLI movement 22/22, traversal 14/14, access 11/11, summit 8/8, flight PASS, 110/110 compile. Studio: Movement 10, Traversal 10, Expedition 15, A1 12, Summit 16, DailyPractice 19. All seven protected groups are unchanged against the Task 1 baseline. Desktop 60 FPS, worst frame 20.9 ms.
- Commit `95ca6b3` on branch `claude/four-mountain-movement` (movement hunks only). Edits to never-tracked files (`CoreConfig`, `CC_AscentClient`, `traversal_rules_cli`) stay in the worktree.
- Evidence: worktree `evidence/movement_2026-10-22/live-acceptance.json` and `protected-verification.json`.

## Saved and copied (later on 2026-10-23)

- **Saved file:** `ClimbAndCollect.FourMountains.Movement.Review.rbxl` in the worktree, saved 10:09. The first save at 09:51 came from Studio `3d0bfced`, which still had Codex's pre-fix code. Both windows were then synced to the same 110 sources and checked against the protected baseline (7/7 unchanged) before the second save. Studio reserialized `Terrain.SmoothGrid`, so that one property was restored from `ClimbAndCollect.BeforeFairground.rbxl`; the pre-restore save is kept in the worktree evidence folder. Final SHA256 is `7737b1f84fa543781953ccf2407929c1f64b20ca9463de7071933873c34844cd`. On disk: 110/110 sources, terrain byte-exact against BeforeFairground and FinalCheck, HTTP off, walk 16. The file was verified on disk only; it has not been reopened in Studio. **Any later Studio save brings back the SmoothGrid drift**, so rerun the restore afterwards. Evidence commit is `ff6ee88`.
- **Main folder:** the 17 movement files were copied into this folder's `src/` and `tools/`, each keeping its existing line endings. The 10 originals were first checked identical to Codex's starting point, and they are backed up in `evidence/movement_2026-10-22/pre-copy-main-backup-2026-10-23.zip`. All 110 tracked sources here now match the worktree. From this folder, the CLI suites pass (movement 22, traversal 14, access 11, summit 8, flight) and 110/110 compile. Nothing was committed in this folder.

## Reopen and two-player check (2026-10-23)

- **Reopen:** both stale windows were closed without saving, and the file hash was unchanged. Opened fresh, the place shows 110/110 sources, the legacy controller disabled, HTTP off, walk 16 and 2 checkpoints.
- **Two players** (Studio Server & Clients test, local only):
  - Player2 sprinted on the mountain at 23 (stamina 97→46). At the same time Player1 ran in the lobby at 22 with stamina untouched, and LeftShift did nothing there. Player1 dropped to 16 when leaving the lobby.
  - Player1's client saw Player2's run animation.
  - At the same moment, Player1 walked to the bank and banked; a repeated deposit added nothing. Player2's forged teleport deposit was refused and its cargo kept, without affecting Player1.
  - Respawning Player2 left Player1 unaffected. Player2 later banked its kept cargo honestly. No console errors.
- Evidence: worktree `evidence/movement_2026-10-22/two-player-and-reopen.json` (commit on `claude/four-mountain-movement`).

## Not done / not verified

- Two players sprinting on the same stretch, climb or rope interaction between players, and real network latency.
- Not tested: a two-client test, physical phone or controller, Device Simulator layout, a real hazard hit, a live climb with half-spent stamina, live DataStore, and an independent review.
- Guardian stagger: nothing in current source emits `hit`, so `Movement`'s guardian lock and the removed AscentClient speed-restore path cannot be reached.
- Tuning values remain provisional.
