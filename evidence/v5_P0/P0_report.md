# v5 P0 (Safety) report — 2026-10-21

All numbers: Studio desktop Play Solo, window focused (title bar clicked before each sample), vsync 60. Not phone numbers.

## Preflight
| Check | Result |
|---|---|
| `list_roblox_studios` | 1 instance, `ClimbAndCollect.rbxl` |
| `get_studio_state` | Edit |
| Studio vs `src/` checksums (64 files, CLAUDE.md method) | 62 match. **Drift in 2: `RouteKit`, `ClimbKit`.** Studio has the **pre-trim** code (rope post every ~9, rung every 4, piton every 12); `src/` has the trim round (18 / 8 / 24). Nothing newer exists only in Studio. |
| World state | Matches the pre-trim code: Ledge route kit 1,400 instances, Lines 1,958 (the P3 report's pre-trim numbers). So the open session = the 17:34 save; **the trim round exists only in `src/`** (it was never saved in the place). |
| Rebuild-order outputs present | Foothold (1,363), Camps 1-4 + Merge, Routes ×5 (Shepherd 3,960 / SummitStair 204 / Waterfall 328 / Ledge 1,400 / Spire 332), Hazards, Checkpoints (31), LedgeP1 (270), ShepherdP2 (49), Core props/spawns/nests (125), Lines (Ledge 441 / Spire 506 / Waterfall 1,007), TrainingYard (75). World total 10,658 (edit). `CC_Route` ×6 + `CC_Track` present. |
| HttpEnabled | false (also after each sync/diff call) |
| Vault / graphify files | not touched |

## Safety
- Checkpoint `C_2026-10-20_Stage1_01` removed from the place after verifying it is in `ClimbAndCollect.CheckpointArchive_2026-10-20.rbxl` (name and its `TakenAt` 2026-10-21T01:13:32Z found in the archive's property data; check script parses the binary chunks with `tools/rbxl_audit.py`).
- New checkpoint **`PreV5_2026-10-21`** (10,732 instances; terrain 1441×911×1441 cells; attribute `Note` records the pre-trim state). Place now holds 2: `PreP3_2026-10-21`, `PreV5_2026-10-21`.
- Saved with Studio visible (title-bar click, Ctrl+S): `ClimbAndCollect.rbxl` 19:43:42, 18,224,190 bytes. Copy **`ClimbAndCollect.PreV5.rbxl`** byte-identical (`cmp`), contains `PreV5_2026-10-21` and `PreP3_2026-10-21`, not the archived one.

## Baseline: streamed World instances (sets the +15 % budget)
Method: PerfProbe teleport, **12 s settle**, 10 s static sample, then a second count 8 s later (identical at every spot). Order low → high (fall detector).

| Spot | Position | World streamed | +15 % cap | FPS | p95 / worst ms | >33 ms | Draw calls | Stage 4 ref |
|---|---|---|---|---|---|---|---|---|
| Spawn | 0, 62, 2247 | **4,608** | 5,299 | 60.1 | 17.8 / 21.2 | 0 | 548 | 2,853 |
| Shepherd s 2500 | -1296, 248, 1726 | **4,623** | 5,316 | 60.1 | 17.7 / 19.3 | 0 | 65 | 3,548 |
| Camp 1 | 151, 515, 1502 | **5,431** | 6,246 | 60.4 | 17.7 / 19.2 | 0 | 134 | — |
| Camp 2 | 1394, 1064, -41 | **3,923** | 4,511 | 60.6 | 18.0 / 18.9 | 0 | 161 | — |
| Camp 3 | 44, 1684, -1063 | **4,353** | 5,006 | 60.1 | 17.9 / 18.6 | 0 | 76 | — |
| Merge (high, 2,567) | -155, 2567, 295 | **4,665** | 5,365 | 60.6 | 17.6 / 18.8 | 0 | 81 | — |

Client InstanceCount 55.2k–56.7k. Two samples (Shepherd, Camp 3) were first taken unfocused (15–22 FPS throttle, GPU 0 ms) and re-taken focused; the instance counts were identical both times.

**Caveat (budget decision):** this baseline is the **pre-trim** world and sits above the Stage 4 numbers (spawn +62 %, Shepherd s 2500 +30 %). It is the "current streamed baseline" the v5 plan names. PROPOSED: use it as the v5 cap, since P1–P5 replace the route kits that caused the overshoot. Stricter option: cap against Stage 4 (+15 % = spawn 3,281, Shepherd 4,080). Counts at spawn vary with settle time (P3 report saw 4,240–5,223); the fixed 12 s settle here repeated exactly.

## Regression (fresh playtests, open-session code = pre-trim generators; runtime/core code matches `src/`)
- **A1** persistence suite: **12/12 PASS** (in-memory store; real DataStore UNVERIFIED).
- **Tutorial bot** (speed 12, BOT): **6:07.7**, Rare at 2:06.3, 0 stuck, 0 hits, ends L2 (P3: 6:11.6; P2: 6:07.6).
- **B checks** (scripted client, real-time pack): **12/12 PASS**.
- Console: no errors (one MCP camera-reset notice).

## Open for P1
- Sync `RouteKit`/`ClimbKit` from `src/` before any rebuild (or drop them if the v5 spline kit replaces them). Until then Studio generators ≠ `src/` for these 2 files.
- Budget choice above (PROPOSED: this baseline).

No world, terrain or generator edits were made in P0.
