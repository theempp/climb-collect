# Expedition hall + sunny slice — handoff

Build of the [approved plan](../docs/superpowers/plans/2026-10-23-lobby-sunny-slice.md). Worktree `C:\Users\HOME!\Desktop\climb&collect-lobby` (moved 2026-10-23 22:30, see below), branch `claude/lobby-sunny`. Review file `ClimbAndCollect.FourMountains.LobbySunny.Review.rbxl` there. Evidence: `evidence/lobby_sunny_2026-10-23/`. Updated after each phase; the newest phase is at the bottom.

## Session setup (2026-10-23 evening)

- The Studio from the planning chat (`3f15b0e6`) had closed by 18:05; only a Roblox Player and the crash handler were running. The review file was reopened with `RobloxStudioBeta.exe <file>` (never the taskbar). New Studio id `d7249d64`. Re-enumerate with `list_roblox_studios` every session.
- Local servers: `python -m http.server 8771 --bind 127.0.0.1` in the worktree root (sync), `python tools/lobby_bridge.py 8772` (evidence sink → `evidence/lobby_sunny_2026-10-23/`).

## Phase 0 — baseline (done)

`P0_baseline.json`. Sources 110/110 match Studio. The 7 protected groups are unchanged against the movement baseline (`tools/protected_compare.py`, `P0_protected_compare.json`). File SHA256 still `7737b1f8…`. HTTP off, walk 16, 2 checkpoints. Suites (Play Solo, mock store): Movement 10, Traversal 10, Expedition 15, A1 12, Summit 16, DailyPractice 19, all passing. Perf (desktop Studio, not a phone): Fairground spawn 60.8 FPS, worst 18.8 ms, 3,480 streamed World instances; Shepherd trailhead (route s=0 at −227, 48, 1812) 60.1 FPS, worst 18.8 ms, 3,507.

## Phase 1 — concept references (done, owner gate passed)

- Six concepts generated from spec §4 wording only (GPT Image 2.5, 2k, 2.75 credits each, 16.5 total).
- Owner kept **C1** hall from spawn, **C3** floor + inlay and **C4** window + departure, and rejected C2, C5 and C6. Rulings: C4's runes are toned down; any element in a kept image may be used.
- Kept files are in `references/lobby/` with `manifest.json` (prompts, job ids, SHA256). Rejected files stay in `evidence/…/concepts/` as evidence only.
- [`design/hall-intel.md`](hall-intel.md): every token cites a measured sample (`tools/hall_sample.py` → `hall_samples.json`, boxes in source pixels). Part colour = the "lit" median. Signs use `Enum.Font.Garamond` (PROPOSED: closest Roblox serif to C1's lettering).
- No approved image exists for the rainforest or volcanic previews, the side-entrance interiors or the hall exterior. Those stay neutral.

## Phases 2–3 — hall structure, service contract, travel (code done, Studio UNSAVED)

- New: `HallConfig`, `DestinationCatalog`, `MountainProgress`, `TravelRules` (shared), `Travel` + `TravelTests` (server), `DepartureUI` (client), generators `ExpeditionHall` (stages shell, services) and `SunnySlice` (stage arrival). Hall at (0, 40, 4400), radius 118, windows E sunny / N snow / W volcanic / S rainforest, bank NW, shop SW, home/showcase/practice side entrances.
- Generalized `LobbyAnchors` (Hall first); removed Fairground lookups in Camps, Traversal, Training, DailyPractice, Home, PublicProfile, CommerceDisplays. Profile v4 (`expedition.mountains.sunny`, migrated from `highestCamp`). Extraction parks the ascent; resume at a saved camp continues it; summit award resets sunny camps in the same transaction. Tutorial beats point at the hall/extraction posts. Fall without checkpoint → sunny arrival. Weather client blends to the hall lighting profile.
- Proposed (owner to confirm): an extraction waystone at the trailhead arrival as well as Camp 1, so new players can bank their first finds.
- In Studio (unsaved): hall shell+services built, `Expeditions.Sunny` arrival + 2 waystones, Fairground/FairgroundFinish/CommerceDisplays moved to `ServerStorage.BeforeHall`, spawn in the hall. Sources 119/119 match.
- Tests: CLI travel 33/33 + existing CLI suites green; Studio TravelTests 16/16 twice in a row; Movement 10, Traversal 10, Expedition 15, A1 12, Summit 16, Daily 19 (all mock store, not DataStore).
- Next: save the place (Ctrl+S, then SmoothGrid restore + disk verify), Phase 4 sunny slice dressing, Phase 5 hall art/dioramas/audio, Phase 6 verification. Not done: real-input walk, phone, two clients, perf of the new hall.

## Worktree move (2026-10-23 22:30)

An outside cleanup (likely a Codex session started 22:06) removed part of `.codex\worktrees\movement-finish` at ~22:16: its `.git` link, CLAUDE.md, .gitignore and the saved review .rbxl. It stopped at the .rbxl.lock Studio held. The owner chose a new worktree outside .codex: `C:\Users\HOME!\Desktop\climb&collect-lobby`. Uncommitted work was copied over; the review file was rebuilt byte-exact (SHA `493d402b…`) from `evidence/.../P3save.BeforeTerrainRestore.rbxl` plus the SmoothGrid restore. Full copy of the damaged tree: `Desktop\climb&collect-lobby-sunny-backup-2026-10-23`. Servers: 8771 = new worktree root; evidence sink `python tools/lobby_bridge.py 8776` (8772 is taken by a DRS Rush server; leave it alone). New tools: `tools/restore_review_terrain.py <base> <review> <evidence> <tag>`, `tools/verify_review.py <base> <review> <out.json>`; `fairground_preservation.luau` takes a port argument and skips `Sunny:*` defs.

## Phase 3 save and owner decisions (2026-10-23)

- Saved 22:00, SmoothGrid restored, disk-verified (`P3_saved_verification.json`).
- Owner (widget): extraction waystone at **Camp 1 only** (trailhead waystone removed; catalog, tests and tutorial line updated); keep Garamond for signs.

## Phase 4: sunny slice (done, saved 2026-10-24 01:32)

- `src/world/SunnyDress.luau` via `SunnySlice.build(stage)`: `groves` (227 faceted spruces in 10 route bands), `clearings` (A s520, B s800: tufts, boulders, fallen log, seat, a 10-spruce ring each), `overlook` (rock slab 14 studs out over the steepest drop at s1100, no railing), `climbs`: rooted rockfall s1190 (18 studs, 6 holds) and rock step s1462 (rooted pitch 12 + ladder pitch 15, rest ledge between). Decks run on until the trail rises to meet them. Defs `Sunny:Rockfall`, `Sunny:StepA`, `Sunny:StepB` (route Shepherd, clip required). Slice = 1,117 instances.
- Tokens: hall-intel "Sunny slice" (C4 preview).
- Checks (`tools/sunny_checks.luau`, `P4_checks_final.json`): trail sweep 0 blocked; 0 trunks within 7 studs of any route; 0 low canopy over the trail; all 15 holds visible, no canopy in front; 0 jump perches (jump 7.2); 0 existing parts enclosed; no walkable terrain beside either climb body (+-36 profiles in the file).
- BOT (`tools/sunny_slice_bot.luau`, `P4_bot_runs.json`): trailhead -> Camp 1 **148.1 s**, 0 stuck, 0 falls, 3/3 climbs clipped, hands-on 9.2 s (6 %), Camp 1 checkpoint set.
- Real keyboard input (W, F, Q/R; camera aimed by script): s1150 -> both climbs -> Camp 1 checkpoint. Not a timing run.
- Timing vs the 15-20 min route target (ESTIMATE): this stretch is 11 % of Shepherd's length and the first of 5 legs (4 camps + summit), so its pro-rata share is 1.7-4 min. BOT 2.5 min at walk 16 without sprint; first-time human time not measured.
- Waterfall: no sightline exists on this stretch (terrain blocks it); reported, not faked.
- Saved, SmoothGrid restored, disk-verified (`P4_saved_verification.json`, SHA `833e75f2…`); 7/7 protected groups unchanged (`P4_protected_compare.json`). Captures: `evidence/.../captures/`.
- Open: the dry red/yellow terrain colours clash with C4's green meadows; fixing that needs Terrain material colours, which the owner's rule forbids. Raised with the owner.

## Phase 5: hall art pass (done, saved 2026-10-24 10:43)

- `src/world/HallArt.luau` via `ExpeditionHall.build(stage)`: `light`, `planting`, `props`, `dioramas`, `audio` (details and tokens in hall-intel "Phase 5 art pass" and "Audio"). Client `src/core/client/HallMotion.luau`, mounted at the top of `CC_CoreClient`. Hall now 2,424 instances.
- Fixes found by captures and the walk check: hall Ambient raised to the C1 sunlit-floor sample, Atmosphere density 0 (fog hid the far window from spawn); spawn moved from x -88 to -66 (the default camera sat inside the volcanic map table); enchanted glass is SmoothPlastic (Glass hid transparent parts behind it); the tree trunk union no longer collides (its Box collision walled off the bed); HallMotion re-applies sound/particle state after streaming brings parts in; glazed crown replaces the top two plank rings.
- Checks: `tools/hall_walk_check.luau` (`P5_hall_walk.json`): 9/9 legs from spawn, 0 stuck; bank 3.3 s, shop 2.6 s at lobby speed 22 (target 5-8 s), departures 1.4-7.6 s, side doors 9-10 s. Reduced motion: 0/42 animated, 0 emitters (normal: 42/42, 2). Sounds load and play only inside the hall.
- Perf (desktop Studio, Play Solo, focused; not a phone): hall spawn 60.0 FPS, worst 19.6 ms, 3,595 streamed World instances (P0 Fairground spawn 60.8 / 18.8 / 3,480); trailhead 60.0 / 18.5 / 3,822 (P0 60.1 / 18.8 / 3,507, +9 %); slice overlook view 60.0 / 18.8 / 3,731.
- Captures: `captures/P5_*` (spawn, sunny/snow/volcanic windows, bank, shop, roof, side entrances, beds, lounge, slice overlook; rejected iterations P5_9x).
- Saved, SmoothGrid restored, disk-verified (`P5_saved_verification.json`, SHA `a87edfa0…`), 7/7 protected unchanged (`P5_protected_compare.json`).
- Not done in Phase 5: C1's upper gallery/telescope; audio not auditioned by ear; phone tier not yet seen in Device Simulator (Phase 6).

## Phase 6: verification (2026-10-24)

- Suites (Play Solo, mock store, not DataStore): Travel 16/16, Movement 10/10, Traversal 10/10 (60 sections incl. the 3 Sunny climbs), Expedition 15/15, Summit 16/16, DailyPractice 19/19, A1 12/12. CLI: travel 33, movement 22, summit run 8 + flight, traversal access 11, traversal 14.
- Full loop (`P6_loop.json`), real keyboard/mouse where stated: spawn → departure (W, E, mouse click Confirm) → trailhead; 2 dev-granted creatures; BOT to Camp 1 (148.3 s, 0 stuck); Camp 1 extraction (real E hold) → hall Return with cargo unbanked; bank (real E hold) → bank 2; mock rejoin kept bank/highest camp/parked ascent; Resume (real click) → Camp 1. **Summit → return → sunny reset was not re-run genuinely**: the BOT cannot descend the 27-stud drop before `Shepherd:P1483` on the untouched upper route; that step is covered only by TravelTests/SummitTests fixtures (genuine ascent last verified 2026-10-22).
- Bugs found and fixed: (1) `DepartureUI` left keyboard selection on a button after closing, so UI navigation swallowed W/A/S/D after departing; now gamepad-only and cleared on close (re-verified: W moves the avatar after a real departure). (2) `MovementClient`: on landscape-phone viewports the touch sprint toggle sat under the PROFILE/SHOP stack; now bottom edge left of the jump button, hidden while climbing (captures P6_90 → P6_04).
- Landscape phone (Studio device emulation, iPhone 17 Pro): hall spawn, departure panel (Confirm by touch press) and trailhead HUD captured. The emulator reports a keyboard and quality can't be forced from scripts, so the phone tier (particles off) is **not** verified live.
- Two clients (`P6_two_clients.json`, Studio Server and Clients + Add Clients ×2): simultaneous departure, split (one extracts while the other stays on the mountain), second extraction, both see each other in the hall.
- Perf: see Phase 5 (hall 60 / 19.6 ms / 3,595; trailhead 60 / 18.5 / 3,822; slice view 60 / 18.8 / 3,731; desktop only).
- Final save 11:08, SmoothGrid restored, disk-verified (`P6_saved_verification.json`, SHA `737364cc…`), 7/7 protected unchanged (`P6_protected_compare.json`). Reopen check (`P6_reopen_check.json`, `P6_reopen_protected_compare.json`): reopened in a fresh Studio, 125/125 sources, HTTP off at open, hall 2,416 / slice 1,117 instances, 3 Sunny defs, 2 checkpoints, 7/7 protected unchanged; file hash still `737364cc…`.
- Still open: physical phone/controller, real DataStore and same-account reconnect, genuine summit+reset on this build, audio listening pass, terrain colour clash (owner kept terrain), HUD region label reads "Dry Foothills" inside the hall, C1 upper gallery not built, sunny slice hands-on only ~6 %.
