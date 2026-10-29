# V3 Ascent — run report (2026-10-20, ~12:20–14:30)

Everything below is a **first draft, awaiting your review**. The two approval stops (after P1, after P4a) were
overridden for this run only and replaced by the written self-reviews in §3. Measurements say how they were
taken; bot times are **bot times** (perfect input); nothing here was measured on a phone.

## 0. Key screenshots (open these first)

| What | File |
|---|---|
| Aerial, biome bands, crown, foothill lake | `evidence/v3_P1/P1_01_aerial_biome_bands.jpg` |
| Crown: ice spire, basalt fins/buttresses, Stormhorn | `evidence/v3_P1/P1_02_crown_fins_buttresses_stormhorn.jpg` |
| Spawn view from the amphitheater (summit horn visible) | `evidence/v3_P3/P3_01_spawn_view_summit.jpg` |
| Foothold layout from above | `evidence/v3_P3/P3_03_foothold_aerial.jpg` |
| Two of the four gates (Ledge frame + rope, Spire monoliths) | `evidence/v3_P3/P3_02_gates_ledge_spire.jpg` |
| Routes stamped into the terrain | `evidence/v3_P2/P2_01_aerial_routes_stamped.jpg` |
| Camp 1 Meadow Lodge on Shepherd's Road | `evidence/v3_P4a/P4a_02_camp1_meadow_lodge.jpg` |
| Summit stair, fixed rope, Crown Gate arch | `evidence/v3_P4a/P4a_01_summit_stair_crown_gate_rope.jpg` |

Rejected iterations are kept as `9x_rejected_*` in each folder.

## 1. What is built, per phase (checkpoints in `ServerStorage.CC_Checkpoints`)

| Phase | Built | Checkpoint |
|---|---|---|
| P0 | Safety copy of the V2 world + `ClimbAndCollect.PreV3.rbxl`; V2 sources in `src_legacy_v2/`; baseline numbers | `PreV3_2026-10-20` |
| P1 | New terrain: 5,600-stud map, summit crown (twin horns + notch, 3 basalt fins, 4 buttress arêtes, Crown Gate voxel arch), 4 ridge massifs, altitude biome bands incl. dry foothills, falls off the Green Valley lip into a foothill gorge, foothill lake | `V3_P1_2026-10-20` |
| P2 | `RouteNet` in the generator: 4 routes + shared summit stair stamped into the terrain (Shepherd wide trail, Waterfall stairs, Ledge narrow benches that only cut on the drop side, Spire knife-edge crest), camps as pads, checkpoints placed by skilled time | `V3_P2_2026-10-20` |
| P3 | `FootholdV3`: amphitheater spawn (6 tiers), plaza r 125, Route Board (stepped relief + 1–4 pips), 4 route-styled gates (×1.6), Lookout Tower, cable-car station + cables + 2 pylons (decorative), Hall of Wonders, Gear Forge, Market, Garage + ATV trail, Base Pad, Hatchery, 9 cabins with yards | `V3_P3_2026-10-20` (also contains the P4a build) |
| P4a | Shepherd's Road: 4 camps + Crown Approach merge (lodge, fire, locker, beacon, route signpost), 1 bridge, 73 fence runs on drop sides, 120 lanterns (every third lit), 13 ramps, 4 checkpoint markers; summit stair with 79 stone ramp slabs, fixed ropes, cairns | see §2 |
| P5 | `CC_CheckpointService` (server) + `CC_AscentClient` (client): checkpoints, fall respawn, 4 Shepherd hazards (2 tree-falls, 1 rockfall, 1 gust zone with windbreaks) | see §2 |
| P4b–d, P6, P7 | **Not built** (data + terrain only for Waterfall, Ledge, Spire; hazard specs written in `RouteKit.HAZ`, not placed) | — |

## 2. Acceptance results

Method key: **RC** = raycast/terrain query in edit mode; **GEN** = generator output (`_G.CC_PATHS`);
**PT** = Studio desktop playtest (one client); **BOT** = scripted character in a playtest (perfect input).

### P1 — terrain
| Criterion | Result | Method |
|---|---|---|
| (a) summit 3,150–3,250 | **PASS** — highest point 3,248.5 (east horn); summit pad in the notch 3,170 | RC grid over the crown (4-stud spacing) |
| (b) unique silhouette, ≥3 crown features | **PASS (first draft)** — twin horns + notch, 3 basalt fins, 4 buttress arêtes, Crown Gate arch, satellite Stormhorn | screenshots P1_01/02, P4a_01. The arch reads as a boulder from below |
| (c) biome progression readable by color from the aerial | **PASS** — dry straw/red-brown ring → greens → sandstone → storm blue → ice | P1_01 |
| (d) terrain/instance within P0 ×1.6 | **PASS for instances** (World 6.4k vs 37.9k in V2). Terrain memory **not comparable**: Studio's memory tags sum edit + server + client + checkpoint TerrainRegions in one process | `Stats` |
| (e) no holes / floating voxels | **PASS** — 19,321 grid rays, 0 misses; surface vs heightfield mean +1.1 studs | RC |
| Self-review vs §3 | Silhouette and color identity work; **gaps**: steep grass bands render grey (grass side texture), the cliff band still reads as a drum, no vegetation yet, spire faces blotchy in shadow | screenshots |

### P2 — route network (data + stamped trails)
| Route | Walk length incl. shared stair (GEN) | Walk @12 | Skilled ESTIMATE (walk + PROPOSED segment min) | Checkpoints (incl. camps) | Gaps (min, ESTIMATE) | Max grade |
|---|---|---|---|---|---|---|
| Shepherd's Road | 19,130 | 26.6 min | **28.6** (+2) | 8 | 2.6–4.1 | 0.28 (15.6°) |
| Waterfall Stair | 12,919 | 17.9 min | **25.9** (+8) | 7 | 2.7–4.3 | 0.45 |
| Cliff Ledge Line | 12,762 | 17.7 min | **28.7** (+11) | 7 | 2.8–4.9 | 0.45 |
| Spire Ridge | 11,411 | 15.8 min | **28.8** (+13) | 7 | 2.9–4.7 | 0.80 (built ramps) |

- **25–30 min band: PASS as ESTIMATE only.** Shepherd needs no obstacles to be in band (walking alone is 26.6 min). The other three depend on obstacle/hazard minutes that P4b–d have not built yet; until then they are 16–18 min walks.
- **Checkpoint spacing 3–5 min: PARTIAL** — every gap ≤ 5 min (rule: fewest checkpoints with no gap over 5 min); several gaps are 2.6–2.9 min (shorter = safer for players).
- **Shepherd grade < 45° on walk sections, mean < 25°: PASS** (max 15.6°).
- **Routes meet at the 4 camps and merge before the crown: PASS** (all four pinned to the camp pads and the Crown Approach pad, re 335, y ≈ 2,560).
- **Each route visible from the base: PASS (partial views)** — share of route samples in line of sight from the amphitheater eye point: Shepherd 10 %, Waterfall 24 %, Spire 18 %, Ledge 23 % (RC). The summit horn is visible from every Foothold eye point tested (3/3); the lower crown is hidden behind the spire's own face.
- Lane layout: routes fan out from each camp and only converge near the next camp (the climb-first route keeps the inner lane). Remaining close pairs (< 40 studs apart) all within ~250 studs of a camp.
- Bridges needed (crossings found by the generator): Shepherd 1 (creek, built), Waterfall 1, Ledge 3 (creek at the falls lip, chasm, one dip), Spire 1 — only Shepherd's is built.

### P3 — Foothold v3
| Criterion | Result | Method |
|---|---|---|
| Spawn camera frames the summit + ≥2 gates | **PARTIAL** — summit horn in frame (P3_01); the gates are behind/below the default upward view from the amphitheater top | screenshot |
| 4 gates identifiable by silhouette | **PASS (first draft)** — wide timber arch + flower boxes / round stone arch + banner / narrow timber frame + gold rope + cairn / dark monolith pair + ice crystal; 1–4 pips; warning sign text on the two hard routes | P3_02 (two shown) |
| Plaza ≥ 3× old footprint | **PASS** — cobbled plaza r 125 vs V2 cobble core r 70 (3.2×) | GEN/paint |
| Every service ≤ 60 s on foot from spawn | **PASS by distance** — straight-line 119–509 studs = 10–42 s at 12 studs/s (flat pad, no obstacles between) | RC distances; not bot-walked |
| No collision snags walking the plaza | **NOT TESTED** by walking | — |
| Instance budget stated | Foothold 1,363 instances (whole World 6,395) | `GetDescendants` |

### P4a — Shepherd's Road (complete and walkable end to end: **PASS with 2 known stuck spots**)
| Criterion | Result | Method |
|---|---|---|
| Bot completes start → summit | **PASS** — Foothold gate → Camps 1–4 → Crown Approach → summit stair → summit trigger reached (`CC_Checkpoint = "Summit"`) | BOT, walkability pass at WalkSpeed 36, 6-stud targets |
| Stuck / off-trail | Road: **2 stucks** (s ≈ 7,586 at a hairpin drop on the forest band; s ≈ 17,126 at a ramp + fence post on the spire flank), **0 off-trail drops** (a pre-fence run had 1 fall at s ≈ 11,432). Summit stair: **1 stuck** at walk speed after the fix (before: 4 stucks + an endless fall loop) | BOT |
| Bot time | Road **≈ 26.4 min BOT ESTIMATE** (528 s at 36 studs/s scaled to 12; wall time is unreliable because Studio throttles the client when unfocused); summit stair **167 s BOT at WalkSpeed 12** incl. 1 stuck timeout. Pure walk from length: 25.1 + 1.5 min | BOT / GEN |
| Skilled 25–30 min | **PASS as ESTIMATE** (26.6 min walk + 2 min PROPOSED segments = 28.6) | GEN |
| Easy route: no gap > 3, no drop that can leave the route | **PARTIAL** — no gaps exist (no jump segments yet); fences on 73 drop-side runs, but the s ≈ 7,586 hairpin still lets a player step off to the leg below | BOT + RC |
| Bypass sampling ±36 studs | **NOT DONE** (no obstacle segments on Shepherd yet) | — |
| Checkpoint respawn by forcing a fall | **PASS** — character dropped 167 studs off Camp 1's edge → respawned 2 studs from Camp 1, `CC_Falls = 1` | PT scripted |

### P5 — hazards + checkpoint runtime (Shepherd only)
| Criterion | Result | Method |
|---|---|---|
| Tell ≥ 3 s (easy), readable without sound | **PASS** — tree-falls and rockfall hit only after the 3 s tell (hits at phase 3.50, 3.79, 3.72 s); tells = tree shake + pulsing slate shadow strip on the trail, dust at the rockfall top, whipping flags for gusts | PT scripted, standing in the hit zone for a full cycle |
| Fixed learnable cycle | **PASS** — phase = (server time + offset) mod period (10–14 s) | code |
| Dodge/shelter position | **PASS** — gust: no push behind a windbreak vs ~4.5 studs exposed; rockfall alcove wall 16 studs before the lane; the tree-fall strip shows where the trunk lands | PT scripted |
| Hit = stagger/knockback, no HP | **PASS** — knockback 6–11 studs + 0.45 s PlatformStand; no damage code exists | PT |
| Inactive beyond ~250 studs; server cost | **PASS by design** — hazards run only on clients within 250 studs; the server does no hazard work | code |
| ≤ 12 simultaneous cycles per region | **PASS** — 4 hazards placed | count |
| Fall → last checkpoint of that route; camps for all routes | **PASS (single client)** — see P4a; camps are `Route = "*"` triggers | PT |
| 2 clients, no duplicate events | **NOT TESTED** (one Studio client); by design each client handles only its own character | — |
| Waterfall / Ledge / Spire hazards | **NOT PLACED** (specs incl. avalanche chutes in `RouteKit.HAZ`) | — |

### Instances / performance (Studio **desktop** playtest, one client; **no mobile emulation run; real device UNVERIFIED**)
| Spot | Streamed World instances | FPS (vsync cap) | Worst frame | Client InstanceCount |
|---|---|---|---|---|
| Spawn (amphitheater) | 2,572 | 60 | 18.9 ms | 51.5k |
| Camp 1 | 2,699 | 60 | 18.4 ms | 51.7k |
| Camp 2 | 2,010 | 60 | 18.2 ms | 51.0k |
| Camp 4 | 1,804 | 60 | 18.4 ms | 50.8k |
| Summit | 1,755 | 60 | 19.1 ms | 50.7k |
| P0 baseline (V2 world) | 19.8–20.7k | 60 | 18.3–18.5 ms | 68.7–69.7k |

Edit-mode World total: **6,390 instances** (V2: 37,910). V3 has **no vegetation yet**, so these numbers are far lighter than final art; the PROPOSED mobile budget (30 FPS floor) is untested.

## 3. Self-reviews at the overridden stops (master.md §3)

**After P1:** the silhouette reads as one unique mountain (ice spire with twin horns, dark fins, a satellite horn) and the biome bands read by color alone. Rejected and fixed during the run: concentric layer cake (91–92), smooth cone spire with leopard texture (93), arch-as-dent (94), a 300-stud rock wall hiding the summit from spawn (95), grey steep bands from deep-rock voxels (96). Still failing §3: steep grass faces render grey (Roblox grass side texture), the Broken Cliffs band reads as a drum, no foreground framing or vegetation, spire faces blotchy in shadow.

**After P4a:** Shepherd's Road is continuous, fenced on drop sides, lit, signed at every camp, with 4 checkpoints and 4 telegraphed hazards; the summit stair is walkable on built ramps under the Crown Gate. Still failing §3: trail shoulders are bare (no authored plants/rocks), forest trail contrast is weak (brown on teal), camps are generic lodge kits, and the Crown Gate reads as a boulder from below.

## 4. Known gaps (honest)
- **The place file on disk is the P1 state (saved 12:52).** A Windows "Textinputhost" window stayed in front of Studio and blocked the Ctrl+S click; access to it was denied. Everything later is in the open Studio session (checkpoints `V3_P2`, `V3_P3`, `V3_P4a_P5` live inside the unsaved place) and is reproducible from `src/` with the BuildAll order in `CLAUDE.md`. **Please press Ctrl+S in the ClimbAndCollect window.**
- Waterfall Stair, Cliff Ledge Line and Spire Ridge exist only as stamped terrain trails: no bridges (1 + 3 + 1 crossings need them), no segments, no hazards, no checkpoint markers. Their 25–30 min estimates depend on ~8–13 min of obstacle time that isn't built.
- No vegetation (P6 not started); no Guaranteed Rare nook; no hidden region; no ring trails.
- No mobile emulation, no multi-client test, no human timing.
- Shepherd: 2 bot stuck spots (s ≈ 7,586 hairpin; s ≈ 17,126 spire flank).
- V2 generator modules stay in `ServerStorage.CC_Generators` but are not called; the V2 `CC_TraverseClient` LocalScript is still in StarterPlayerScripts (harmless).

## 5. Decisions I made (all PROPOSED, please review)
1. Map 5,600²; **Foothold moved to re 2,370** so the summit horn clears the valley lip from spawn.
2. **Dry-foothill colors from your words only**: dryGrass 192,166,96 (terrain Salt), redEarth 150,82,54 (terrain Mud), scrub 118,126,70; in `WorldConfig`, swappable.
3. Camps at 16/33/52/70 % of height; all routes merge at "Crown Approach" (re 335, y ≈ 2,560), then share a 1,059-stud spiral **summit stair** that passes under the **Crown Gate** arch.
4. **Lane rule** for separation (the route that climbs a band first keeps the inner lane), so routes fan out from camps instead of running as parallel lanes.
5. The falls drop off the Green Valley lip into a foothill gorge; the lake moved into the foothills.
6. Route identity = existing tokens (Shepherd meadow, Waterfall turquoise, Ledge sandstone, Spire ice) + 1–4 pips + sign text; no new warning color (tells use motion and slate shadow strips).
7. Hazards are client-side and time-synced (zero server cost); fall = drop > 24 studs → last checkpoint; Shepherd gust is mild (7 studs/s, slower than walking).
8. Checkpoint rule: fewest checkpoints with no gap over 5 min (some gaps 2.6–2.9 min).
9. Cable car: decorative station, cables, 2 pylons, gondola, "closed" sign.
10. Sync method: localhost fetch into `.Source` with `HttpEnabled` switched on and off inside the same call.

## 6. What to approve next
1. The P1 silhouette/biome look (P1_01–03) and the dry-foothill colors, or send a reference image.
2. The 4-route layout and lane rule (P2_01, table in §2).
3. Foothold v3 layout (P3_01–03), especially the spawn view.
4. Go-ahead for P4b–d (Waterfall, Ledge, Spire: bridges, segments, hazards) and P6 (vegetation + mobile emulation pass).
