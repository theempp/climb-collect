# Home-base world style: S1 structure plan (2026-10-29)

PLAN ONLY (architect). No feature code. Branch `codex/homebase-c`. Authority: `homebase-style-decisions-2026-10-28.md` (DEC #n, S0.n wins over DEC where they differ). Colour values are cited from `homebase-world-style-intel.md` (INT) only. Numbers marked PROPOSED need the owner at the named STOP.

Supersessions to carry forward: tier 2 = **Villa** (S0.8; DEC #7 and INT B1 still say Cottage), gate ~100 studs (S0.2, not INT B2's "2x"), path glow = flare #7BD8FF (S0.9, not INT A's pk REC), per plot 937 (S0.4).

---
## 1. Part budgets

Basis: BaseParts + billboard instances, runtime, current tier only (DEC #6). "Today" = P3 build (`homebase-handoff` P0/P3: per plot lodge 128 + shell ~36 + folder 11; TycoonWorld builds nothing in P3). Target = INT B/D estimate. Cap = hard per-item limit the S3/S4 count script enforces.

### 1a. Per plot (cap 937)
| Item | Today | Target | Cap | Note |
|---|---|---|---|---|
| Shell: floor, front wall/entry frame, side walls | ~36 | 40 | 50 | round posts replace blocks, same runs |
| Ground: lawn slab, light patches, yard path + flare glow | in shell | 20 | 30 | slabs, not per-paver parts |
| House (one tier) | 128 (lodge) | Hut 28 · Villa 50 · Manor 85 · Palace ≤130 | 157 | INT B1; Palace cap = lodge x1.25 |
| Banner + aura ring | 0 | 5 | 6 | INT B1 shared extras |
| Habitats x6 (pad, tint floor, round-post fence, plaque) | 0 | 102 | 110 | INT B5 (17 each) |
| Creatures in habitats (6) | 0 | 150 | 150 | PLAN:76 est (~25 each), measure in S3 |
| Spine + bank + 3 machines | 0 | 40 | 45 | restyle = colour/material swap |
| Hatchery | 0 | 40 | 45 | |
| Training Beast + pen | 0 | 60 | 65 | |
| Globe lamps x4 | 0 | 20 | 25 | INT B3 (5 each), 0 lights |
| Yard flora (non-slot) | 0 | 24 | 30 | PROPOSED share for DEC #16 |
| Decor stands x14 | 0 | 28 | 28 | INT B6 stand 2 |
| Decor contents (props) | 0 | ~70 (avg 5) | 84 (6 each) | INT B7 ≤ 8, catalog items ≤ 6 |
| Billboards (≤ 12 x 7 instances) | 0 | 70 | 84 | INT B4; MaxDistance 45 |
| **Total (Palace, 14 props)** | **~175** | **~800** | **909** | 28 under 937 |

**Breaks the cap:** decor slots holding **creatures** (Q6 allows it). 14 displayed creatures at ~25 = 350 vs 70 for props: ~1,080 at target. See risk R1.

### 1b. Commons, gate, place
| Scope | Today | Target | Cap | Note |
|---|---|---|---|---|
| Commons (HomeCommons v2) | 776 | ~1,100 | 1,500 | restyle in place ~850, + board 9, shrine 12, fountain 9, 5 plaza discs x3, path glow ~40, speed-lane dashes ~70-140; trees 13 parts -> lollipop 4 saves ~9 each |
| Gate (`GrandGate` model) | 151 | ~45 (+3 sparkles) | 200 | INT B2 at ~100 studs; 0 PointLights |
| Net place (edit descendants) | 15,095 (P3) | — | 19,812 (15,812 + 4,000, P0) | edit = unowned shells, passes |
| Net place, runtime, 8 owned Palace plots | ~9,700 est | +~5,200 | **undefined** | 8 x (800-175) + ~325 commons - 106 gate exceeds the +4,000 head-room. R1 |

Lights: 0 default, ≤ 1 PointLight per house (door), 0 in commons/gate. Draw calls ≤ 700 per home view (unchanged).

---
## 2. HomeTiers migration

### 2a. Tiers (names display-only)
| Tier | Old name | New name | `style` key | Visual roles (WorldStyle role keys; replaces alpine `roles`) |
|---|---|---|---|---|
| 1 | Dry-stone Yard | Hut | `hut` | `house.hut`: body rarity.blue #6C8CF0, roof #5B78E8, ridge #9FB6FF, gem #6C8CF0, door #2B1457, doorArch #FFD2FF, porthole #FFDD9B Neon, rim #FF8FE0 |
| 2 | Cedar Cloister | Villa | `villa` | `house.villa`: body #F7A21B, roof #F0952A, ridge #FFD27A, gem #F7A21B, + dormer |
| 3 | Brass & Lantern | Manor | `manor` | `house.manor`: body #B06CF0, roof #8A4BE6, ridge #C99BFF, gem #B06CF0, + tower |
| 4 | Azure Terrace | Palace | `palace` | `house.palace`: body #FFB8EA, roof cycles #FF8FC0/#FFD27A/#7BD8FF/#B58CFF, ridge #FFD27A, + turrets, spire gem |

- Shape change: `roles={...}` (cumulative alpine list) becomes `style='hut'` (one key into `WorldStyle.tier`). Only the house changes per tier (DEC #6); yard, lawn, pens are tier-independent. Whether anything else grows per tier is OPEN (R6), default: house only.
- `rank`, `fee`, `habitatCap`, `usable` unchanged (STOP 3 approved).

### 2b. Decor display names (PROPOSED, owner OK at S2 STOP)
| id (stable) | Old name | New name | New form (INT B7) | `proto` -> kit builder |
|---|---|---|---|---|
| boulder | Weathered boulder | Candy boulder | #6, 2 parts | `Kit.boulder` |
| bed | Alpine planting bed | Bloom bed | #7, 8 parts | `Kit.bloomBed` |
| hedge | Hedge planter | Puff hedge | #5, 5 parts | `Kit.puffHedge` |
| lantern | Cedar lantern | Globe lamp | #11, 5 parts | `Kit.globeLamp` |
| sapling | Pine sapling | Cloud tree | #3, 4 parts | `Kit.cloudTree` |
| basin | Azure basin | Gem basin | #12, 4 parts | `Kit.gemBasin` (closes G11) |

### 2c. Saved profiles
Not affected. `p.home` stores `tier` (integer) and prop **ids** in `decor[*].id` and `stock` keys (schema §p.home); names and roles are never saved. Ids stay `boulder/bed/hedge/lantern/sapling/basin`; `home.v` stays 1; no migration, no rollback risk (an older build shows old names only).

### 2d. Code/test updates
| File | Change |
|---|---|
| `shared/HomeTiers.luau` | names, `roles` -> `style`, prop names, `proto` -> kit builder name |
| `shared/Tycoon.luau:156` | none (reads `.name`); message becomes "Raise your plot to Villa" |
| `tests/home_rules.luau:13` | expected names Hut/Villa/Manor/Palace |
| `tests/home_rules.luau:15` | drop `#roles` growth check; add: every `style` exists in `WorldStyle.tier`, 4 distinct |
| `tests/home_rules.luau:72,77` | 'Palace', 'Gem basin' |
| `tests/tycoon.luau:42`, `tests/ui_server.luau:151,175` | 'Villa' in messages |
| `tests/service_harness.py:32-44` | inject `WorldStyle` if HomeTiers requires it (avoid: HomeTiers holds only the key string, no require) |
| `tools/mutate_home.py` | no pattern changes needed (no name strings); add 3 mutants: tier style swapped, rank band 5->6, band 30->29 (caught by `world_style.luau`) |

---
## 3. Module layout

| Module | Location (repo -> Studio) | Role |
|---|---|---|
| `WorldStyle.luau` | `mountain/shared/` -> `ReplicatedStorage.MountainShared.WorldStyle` | the one world token table; pure data (RGB triples, no Color3) so CLI tests read it, like `HomeLayout` |
| `WorldKit.luau` | `mountain/world/` -> `ServerStorage.MountainWorld.WorldKit` | prop builders (prototypes as code); returns Models with `Parts` attribute |
| `HomeTiers.luau` | unchanged location | tier data + `style` key only |
| `WorldFx.client.luau` | `mountain/client/` | the one world-motion driver (S6; tier-up pool from plan P7 joins it) |
| `Motion.luau` | unchanged | gains `M.world` sub-table + `M.worldCaps()`; GUI engine untouched |

### 3a. `WorldStyle` structure
```
S.color   = { lawn, lawnLight, paver, inlay, pathGlow, kerb, door, doorArch, porthole, portholeRim, gateBody, gateTrim,
              gateGlow, gemIdle, gemBurst, sparklePink, sparkleFlare, lampPole, lampCollar, globeWarm, globePink,
              signNight, signText, signStroke, plaque, coin, coinRim, water, fountainGem, flame, ember, speedLane, ... }  -- INT A rows, {r,g,b}
S.pens    = { 6 tints, S0.6 order }
S.material= { body='SmoothPlastic', trim='Neon', accent='Glass' };  S.glassT = .25
S.rank    = { {min=1,key='blue'}, {min=5,key='gold'}, {min=15,key='violet'}, {min=30,key='prism'} }  -- S0.1; S.rankBand(level)
S.tier    = { hut={body,roof,ridge,gem}, villa=..., manor=..., palace={body,roofBands={4},ridge,gem} }  -- 2a
S.caps    = { plot=937, commons=1500, gate=200, house={hut=40,villa=65,manor=105,palace=157}, kit={...}, billboards=12, houseLights=1 }
S.fonts   = { display='LuckiestGuy', body='FredokaOne' }
```
Rules: every value has an INT row citation in a comment; no other world module may contain a colour literal (lint test, section 4). `S.rgb(key)` helper lives in WorldKit (Roblox side), not in the pure module.

### 3b. Prototype kit
- **Builders, not baked protos.** Every form is Cylinder/Ball/Block parts from code (INT B), so the kit is reproducible from source; this avoids the v1 proto-loss trap (`HomePromenade.luau:189-190`). `ServerStorage.HomeProtos` (alpine) stays until S5 removes its last consumer (HomeCommons gardens/lanterns), then is deleted at S8 with owner OK.
- API: `Kit.<item>(parent, cframe, opts) -> Model` (`globeLamp, pillSign, plaque, fence, coinMarker, boulder, bloomBed, puffHedge, cloudTree, lollipopTree, swirlTree, gumdrop, mushroom, gemCluster, daisy, gemBasin, house(tierKey), banner(rank), auraRing(rank), gateArch, board, shrine, fountain, plazaDisc`). Each sets `Parts` and the `WorldMotion=<token>` tag/attribute on animated pieces; anchored, CanTouch false, CanCollide only where INT B says.
- Consumers: `TycoonWorld` (habitats, pens, spine, bank, lamps, decor stands and contents, billboards) and a new house slot in it (tier house built on `Tier` attribute change, replaces `Lodge_0i`; no server code reads lodges, grep 0). `HomeCommons` replaces its local `K` table with `WorldStyle` and its `proto()` calls with Kit builders; `GrandGate` is rebuilt by HomeCommons under the **same model name** (Sanctuary.luau:21 parents the exit marker to it).

### 3c. World-motion driver (S6)
- Tokens in `Motion.luau` as `M.world = { gemSpin, gemBob, sparkle, globePulse, crestPulse, gateArrive, tierUp }` (INT C values). Kept out of `M.tokens` so GUI loops, stats, `CAPS` and the `motion_band` suite never see them.
- `M.worldCaps()` -> `{gate=6, globe=4, crest=1, burstShards=8}` at effectsTier 1, `{gate=3, globe=2, crest=1, burstShards=4}` at .5, all 0 when `M.reduced()` or `M.noRays()` (PROPOSED; INT C/F12). GUI `CAPS={holo=1,shine=3,idle=6}` unchanged and separate.
- `WorldFx`: one Heartbeat connection, connected only while ≥ 1 world loop is in range or a one-shot plays. Candidates via CollectionService tag `WorldMotion`; distance re-check every .25 s from the camera focus, **60 studs**; crest only where plot `OwnerUserId == LocalPlayer`. Moves by stored base CFrame + offset through one `workspace:BulkMoveTo` per frame; pulse by Transparency only (no Size per frame). Leaving range or a gate flip restores the base pose the same frame. No TweenService.
- Reduced / LOW: no loops, parts sit at the builder's static pose; gate arrival = .15 s mint fade on the pillar only (no shards). MED: halved caps. Arrival burst triggered from the existing `hud 'safe'` consumer (no new server event). Server never animates; all moving parts CanCollide false.

---
## 4. Tests per phase

Always: `bash tools/run_all_tests.sh` (43 suites at merge), drift 0 after sync, console clean, StudioAids false, PlaceId 0. Captures: desktop 16:9 + phone aspect (custom 844x411 and emulator iPhone 16 Pro), avatar height + top-down.

| Phase | CLI | Studio QA | Captures / counts |
|---|---|---|---|
| S2 kit | new `world_style.luau` (every token = INT hex, rank bands 4/5, 14/15, 29/30, 4 tier keys resolve, caps sum ≤ 937); new `world_style_lint.py` (no `Color3.fromRGB`/hex literal in TycoonWorld, HomeCommons, WorldKit); updated home_rules/tycoon/ui_server; mutate_home 34/34 | `tools/rmcp/qa/kit_sheet.luau`: builds every Kit item in a temp folder; per-item parts ≤ `S.caps.kit`, materials ⊂ {SmoothPlastic, Neon, Glass}, Glass T = .25, 0 lights, 0 textures/MeshParts | contact sheet, both aspects; kit count JSON |
| S3 plot T1 | home_layout 230 green; tycoon*, run_persistence unchanged | `plot_counts.luau` extended per item vs 1a caps; scene check; walk 8/8; 2-client owner/visitor; creature bounds inside 15x12 pad | 8 plots, yard close-ups; count table; home_views perf (median ≤ 16.7 ms, draw calls ≤ 700) |
| S4 houses | — | Studio-only dev tier action (stripped from release); house bounds ⊂ lodge rect 35x35.75; ring r ≤ 19 clear of hatchery/pen; ≤ 1 PointLight; tier swap leaves no orphan parts | 4 tiers x 2 aspects; swirl frames (4 transitions); Reduce crossfade |
| S5 commons | layout tests unchanged | scene check; commons ≤ 1,500, gate ≤ 200; billboards ≤ 12/plot; walk legs plot -> each landmark; gate marker still under `GrandGate` | street, crossing, gate, glow/lane separation close-up |
| S6 motion | motion_band + hud suites unchanged | caps probe: world loops ≤ `worldCaps()` per tier, 0 at rest beyond 60, 0 when reduced; overflow 174x6, state audit 0, Shop open delta ≤ +1 ms | on/off frame sheets; perf during arrival burst (worst ≤ 33 ms) |
| S7 aura | new `aura_rules.luau`; extend ui_server, run_persistence; mutants (below) | live: bank payout at each band | numbers table + sim output |
| S8 review | full run | 8-client emulator perf, overflow/state, drift, token trace (DR) | DR report |
| S9 mountain | route_geometry, traversal, free_climb_geometry, quality_geometry, compact_geometry unchanged | read-only prop audit first; collider snapshot (Size, CFrame, CanCollide, CanQuery of every path part) hash before == after | before/after per camp |

### S7 multiplier test shape (numbers later)
- Pure `mountain/shared/AuraRules.luau`: `band(level)` reuses `WorldStyle.rank` thresholds; `multiplier(band)` from a table; `apply(coins, level)` floors, clamps at `maxCoins`.
- CLI: each band edge; level from `ExplorerRules.summary` only; applied once at the server coin commit (`P.transact`), replay pays nothing more; client payload with a multiplier field refused by UIProtocol; secure XP unchanged; tier fee and prop prices never multiplied; Robux-origin income rule per owner.
- Mutants (add to `mutate_home.py`): skip apply; apply twice; band edge off by one; accept client multiplier; multiply XP; multiply a debit.
- `tools/sim_aura.py`: coins/hour and time-to-Villa/Manor/Palace per band vs the 1,000/5,000/15,000 fees; output table for the S7 STOP.

---
## 5. Speed lane vs path glow (S0.9 + S0.10)

Both are flare #7BD8FF Neon, and INT A makes the channel water and fountain gem flare too: four flare elements on one street would read as one. PROPOSED separation by geometry only (lane 29, measured from the channel coping outward; H arms scale to 22):

| Element | Form | Position |
|---|---|---|
| Channel water | Glass T.25 sheet, 12 wide | centre (unchanged) |
| Speed lane | **dashed** 3-wide flush Neon, 12 on / 8 off (atlas B9 pitch) | 5-8 from coping, vertical street + H arms only |
| Paver inlay | continuous 0.8 pink #F46BC4 Neon | lane centre (14.5) |
| Path glow | **continuous** 0.5 flush Neon | 1 inside the outer (plot-side) kerb; also plot entry paths and plazas |

Reconciled with atlas B9 (orchestrator, 2026-10-29): positions here win, dash pitch from B9.

Rule: dashed + wide = lane, continuous + thin = walkway edge, ≥ 6 studs apart, never side by side. Fallback if the S5 capture still reads as one: drop path glow on the street where lanes run and keep it on entries and plazas.

---
## 6. Risks / open items for the owner
| # | Item | Recommendation |
|---|---|---|
| R1 | Budget: (a) creatures on decor stands push a plot to ~1,080 (> 937); (b) 8 owned Palace plots add ~5,200 at runtime vs the +4,000 head-room, which was measured as edit descendants. | Cap displayed creatures at 6 per plot (or a smaller display scale), measure in S3; set an explicit runtime cap for the 8-owner case at STOP |
| R2 | Billboards: 6 habitat signs + bank + 3 machines + hatchery + Beast = 12 already; decor price pills (DEC #17) would exceed 12. | Price pills client-side for the owner only, nearest 4 |
| R3 | Four flare elements on the street (section 5). | Approve the geometric split; judge at S5 capture |
| R4 | Neon glow depends on bloom, which the MCP cannot read; Glass T.25 water over terrain may look grey. | Emulator + phone check at S5/S8 |
| R5 | `M.world` inside Motion.luau risks GUI regressions. | Separate sub-table, motion_band + overflow audits in S6 |
| R6 | Per tier, does anything beyond the house change (yard lamps, fence trim)? INT/DEC say house only. Also confirm decor names 2b and the aura coin sources for S7 (bank only?). | House only; names as 2b; aura applies to production bank payouts only |

## 7. Hand-off
Atlas pass 3 first (S1): rewrite INT B1/A with Villa, gate ~100, path glow flare, the section 5 geometry and the `S.caps.kit` per item. Then the **first Component Builder task (S2.1)**: create `mountain/shared/WorldStyle.luau` per section 3a by transcribing atlas pass 3 values only (each with its INT row comment), plus `mountain/tests/world_style.luau`; no other file. [main] follows with the HomeTiers migration (section 2d), then S2.2 WorldKit builders + kit sheet.
