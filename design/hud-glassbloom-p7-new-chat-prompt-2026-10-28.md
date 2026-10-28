You are continuing the approved Glassbloom HUD for Climb & Collect in Roblox. Work in `C:\Users\HOME!\Desktop\climb-collect-integration`, branch `codex/hud-glassbloom` (HEAD after `392b8d0`). P0–P6 are done and approved (STOP 4 approved 2026-10-28). Your job is **P7: design review → fixes → evidence → close-out**, then STOP 4-final for owner sign-off. Work continuously; make implementation micro-decisions yourself and record them in the handoff.

READ FIRST
- Handoff: `design/hud-glassbloom-handoff-2026-10-27.md` (Studio notes, P3–P6 results, gotchas, open risks).
- Plan: `design/hud-glassbloom-build-plan-2026-10-27.md` §4 P7, §5 containment, §6 budget, §7 stability; owner answers §11–§20 override §9.
- Intel (only token source): `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md`. Board: `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html`.
- Motion: `mountain/client/UI/Motion.luau` + brief `design/hud-glassbloom-p6-motion-brief.md`.
- Memory: hud-revision-decisions, overhaul-plan-decisions, egg-loop-decisions.

STUDIO SETUP
- Copy `outputs/ClimbCollect.Glassbloom.Review01.rbxl` = the P6 save, SHA256 `249a2786f622d0cb31e34dcb71d16fbfbbeb03e02062d9d3fd0ab8cb542e705a`. Check it.
- `python tools/rmcp/rmcp.py call list_roblox_studios {}`; last id `ddacece4-fc9d-476d-af20-a9f4545fd711` (ids change per launch). If gone, launch `RobloxStudioBeta.exe <path>` (never the taskbar), assert `game.PlaceId==0`, update the id in `tools/rmcp/x.sh`.
- Sync in Edit mode: `python tools/rmcp/sync_hud.py <id> --changed f6da03b`.
- Never Ctrl+S in: the window linked to PlaceId 112921656767061, PhoneCandidate02, the base place.
- QA: `tools/run_all_tests.sh` (40 suites, fail=0); `tools/rmcp/p6_checks.sh <id> <outdir>` (overflow 6 sizes, state audit, perf/counts, P5 checks, P6 motion budget + Reduce effects/LOW gates, console; StudioAids on→off); `capture_hubs.py`, `capture_shop.py`, `capture_motion.py` (+ `REDUCED=1`) and `motion_sheet.py` for evidence. UIProbe (StudioAids only): open/close/tab/detail/hudState/reveal/motionStats/motionScale/motionDemo/motionPrefs. 844-wide captures: device `GB_844x411` + ActualResolution; restore `iphone_16_pro` + ScaleToPhysicalSize after.

DO NOW: P7
1. design-reviewer (read-only) reviews the build against the board, state by state (rest/carry/regrab/chase/sanctuary/battle) × 3 phone sizes, every hub tab, the Shop scroll states, the hatch reveal, and the motion contact sheets (`evidence/hud_glassbloom_2026-10-27/p6/stop4/`). Give it fresh captures and the intel; findings come back ranked.
2. Route each finding to its owner one task at a time (component-builder for layout/style, motion for timing, inline for wiring), verify each in Studio. Any product/design decision not covered by intel or §11–§20: ask in the popup, recommendation first.
3. Evidence in `evidence/hud_glassbloom_2026-10-27/final/`: each state × 3 sizes, each hub tab, audit JSON (overflow + state), test counts, perf JSON, Reduce effects captures, gamepad focus capture.
4. All checks green again (P6 numbers or better; Shop open within +1 ms of no-motion).
5. Save the copy (computer use: Roblox Studio + File Explorer click-only; title `…ClimbCollect.Glassbloom.Review01.rbxl - Roblox Studio`, single Studio process, PlaceId 0, StudioAids false, emulator iphone_16_pro), record SHA256, commit.
6. Close-out docs: handoff, plan, `C:\Users\HOME!\Desktop\climb&collect\CLAUDE.md` Glassbloom note, Obsidian `Climb & Collect/Milestones.md` + `Decisions.md` (+ `Roblox Shared/` gotchas), memory `hud-revision-decisions` (process only).
7. STOP: final sign-off in the popup with short evidence. Publishing is not in scope.

Open items carried: deep Shop refresh builds every section at once (~55 ms one-off, P5 risk, untouched); shards (G12) not built; `OffspringPresentation.client.luau` (3D egg lid, pre-existing) still uses TweenService outside the UI.

HARD RULES
- No publishing, product creation, live prices or Robux spending; every Robux button stays disabled with product id 0.
- Never save over the base place, PhoneCandidate02 or any published place; never save with StudioAids true.
- No new uploads without owner OK. Containment must pass at all 6 sizes.
- Ask every decision in the popup widget, recommendation first.
- P2 release order still holds: a build with T0 (`f92575b`) must be live before any build that writes the new pref keys.
