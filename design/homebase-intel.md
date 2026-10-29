# Home-base intel (atlas, 2026-10-28)

Scope: per-player home base (layout C, ~80x100 plots, cross-shaped commons). Build worktree `homebase-c`.
Rule: every value cites a file+line or a reference image. Untraceable = not written; listed in G.

**Source keys**
| Key | File |
|---|---|
| `PROM` | `C:\Users\HOME!\Desktop\climb-collect-integration\mountain\world\HomePromenade.luau` |
| `LAY` | `...\climb-collect-integration\mountain\shared\HomeLayout.luau` |
| `TYC` | `...\climb-collect-integration\mountain\server\TycoonWorld.luau` |
| `SANC` | `...\climb-collect-integration\mountain\server\Sanctuary.luau` |
| `CAT` | `...\climb-collect-integration\mountain\shared\Catalog.luau` |
| `RPT` | `...\climb-collect-integration\design\homebase-promenade-review01-report.md` |
| `INT` | `C:\Users\HOME!\Desktop\climb&collect\design\homebase-redesign-interview-2026-10-29.md` |
| `LAKE` | `...\climb&collect\design\lake-world-and-vfx-reference-analysis-2026-10-29.md` |
| `GB` | `...\climb&collect\design\hud-glassbloom-intel.md` (read §1 and §2 only) |
| `IMG02/03/04` | `...\climb&collect\references\lake-world\02-base-upgrade-sequence.jpg`, `03-card-reveal-vfx.jpg`, `04-portal-vortex-vfx.jpg` |

**Finding.** `design/world-tokens.md` (both copies; the integration copy was not byte-compared, but its header matches) is PROPOSED mountain-biome text derived from master.md. It has no sanctuary, lodge or gateway value (0 matches). It is **not** used here. The real sanctuary tokens live in `PROM` lines 9-14 ("sampled from the Review02 sanctuary").

---
## A. Material + colour tokens in use

### A1. Sanctuary / gateway (`PROM:10-13`, RGB exact from code)
| Token | RGB | Material(s) as used | Where used (line) |
|---|---|---|---|
| dryStone | 125,139,139 | Cobblestone | plot front wall 159, gate tower shaft 204, lintel 233, wing walls 225 |
| stoneCoping | 185,193,178 | Slate | wall coping 160, channel coping 126/128, pool coping 140, capitals 209, wing coping 226 |
| cedar | 98,68,43 | Wood | entry posts/beam 161-165, gate inlay 206, entablature 232, braces 241, endposts 227 |
| pierFoot | 73,91,99 | Slate | channel bed/foundation 112-113, pool basin 137, gate pier foot 203 |
| tealCornice | 46,94,99 | Slate (Wedge for roofs) | entry cap 167, gate roofs 211/237, cornice 234, lantern cap 219 |
| brass | 173,139,75 | Metal | entry inlay 166, gate inlays 207/213/235/244, lantern base 217, conveyor guides 132 |
| crest | 105,201,211 | Neon | gateway crest 238 |
| lanternGlass | 255,221,155 | Neon + PointLight (Range 22, Brightness 1.4, same colour) | gate lanterns 218-220 |
| meadow | 90,135,82 | Grass | basin ground 106, ground plugs 115-116 |
| approach | 179,174,151 | Cobblestone | walking lanes 123, forecourt 117, plaza 135-136 |
| pale | 215,208,174 | Slate | lane kerb 124 |
| plotFloor / plotEdge | 126,157,132 / 214,223,208 | not used in `PROM` code paths read (declared at line 12) | only declared; floor/edge parts are baked in the place file, see G1 |
| water (Azure) | 83,153,159 | Glass, Transparency .25, CanCollide false, CanQuery false | channel 129-130, pool 138. Value = `CAT:4` (`kingdoms[2].color`, "Azure Falls"), pulled at `PROM:13` |

Geometry/finish rules in the same file: parts are Anchored, CanTouch false, Top/Bottom surface Smooth (`PROM:18`). Channel bed is Slate 1 thick, ground level `groundY`=16 (`LAY:4`).

### A2. Habitat / production props (`TYC`)
| Part | RGB | Material | Line |
|---|---|---|---|
| ConveyorSpine | 40,62,65 | Metal | 26 |
| SpineTrim | 114,203,177 | Neon | 28 |
| Habitat pad | 85,123,100 | Grass | 33 |
| Habitat rim, posts, back rail | 219,189,122 | Wood | 34, 38, 40 |
| Feeder branch, storage track | = spine colour (40,62,65) | Metal | 35, 41 |
| Storage fill | rim colour; full = 255,211,103 | Neon | 42, 91 |
| ProductionBank | 219,189,122 (recoloured to kingdom accent at runtime, 70) | Metal | 46 |
| BankPlinth / DepositSlot | spine colour | Slate / Metal | 50-51 |
| Machines (Processor, Sorter, Collector) | 82,104,114 | Metal | 54 |
| Machine status light | bank colour | Neon | 58 |
| Runtime accent (rims, posts, bank, machines, fill) | `CAT` kingdom `accent` by cosmetic index: blossom 243,170,205; azure 100,222,233; sunstone 255,211,103; violet 200,157,255; inferno 255,151,69; astral 153,198,255 | n/a | `TYC:69, 84-98`; `CAT:3-8` |
| Plot service markers | Incubator 133,187,177; Training 204,168,105 | Wood | `SANC:65-66` |
| World label (legacy) | bg 24,40,48 @ T.25, text 245,240,218, GothamMedium 14, 160x42, MaxDistance 45 | n/a | `TYC:15-18` |

Flag: the legacy label font/colours differ from Glassbloom (A3). Decision for owner/builder: migrate billboards to Glassbloom (recommended, single UI family; cost = rework of 8x(6+3+1) labels) or keep legacy in-world.

### A3. Lodge
Lodge geometry sits in the baked place (`EnchantedAlpineLodges/Lodge_0i`, moved by name at `PROM:69`). Its colours/materials are not in any source file read. Cedar, brass, dry-stone and lantern glass above are the only traceable lodge-family values (the interview names them, `INT` line 34). See G1.

### A4. Glassbloom tokens for in-world billboards, arrival pop-up, notice board (`GB` §1, hex exact from board CSS)
| Role | Token | Value | GB line |
|---|---|---|---|
| Text | text | #FFFFFF | 35 |
| Text outline/shadow | ink (Luau `outline`) | #150A33 | 36 |
| Action | pk / vi | #F46BC4 / #A55BEA | 30 / 31 |
| Glass panel | glass.from / to / rim | #8246DC / #32146E / #FFD2FF, fillT .45/.38, rimT .45 | 43-45, 103-105 |
| Kicker / header text | pinkText | #FFD0F0 | 46 |
| Safe / secured | go, go.ink, go.glow | #7BFFD0, #06281E, #5DFFC0 | 58, 62, 60 |
| Coins / XP gain | gold, gold.text, moment.text | #FFD84A, #FFE9A8, #FFE45C | 64, 71, 72 |
| Rarity (rim/glow) | blue / gold / violet / prism | #6C8CF0 / #F7A21B / #B06CF0 / #FFB8EA | 94-97 |
| Display face | LuckiestGuy | titles, prices, reveal word | 227 |
| Body face | FredokaOne | all body text | 229 |
| In-world label size | `t.beacon` 12 FO, scope W (billboard, never HUD-scaled) | | 256 |
| Components to reuse | `W.glass` 313, `W.pill` 320, `B.beacon` (BillboardGui, "SAFE GATE · 84 m") 336, `B.toast` 337, `B.bnr` banner 338, `B.cpop` carry pop-up 340, `ladder` (4 rungs, claimed/ready/locked) 358, `row()` 365 | | |

---
## B. Plot inventory (target ~80x100, `INT:13,53`; current plot 140x180, `LAY:4`)

| Component | Existing size / pos (plot-local) | Source | Status |
|---|---|---|---|
| Plot floor | 140x2x180 now; owner target ~80x100 | `LAY:4`, `PROM:83`; `INT:13` | resize |
| Spawn | 6x6 at x0, z-83 (front), faces the gate | `LAY:12`; `PROM:82` | keep; relocate for 80x100 |
| Lodge | 35 W x 30 D, overhang 5.75, at x0 z64 (rear) | `LAY:14` | keep size; height/colour GAP G1 |
| Habitat (x6 target; code builds 8) | pad 36x0.5x20; rim 37x0.2x21; 4 posts 0.9x2.4x0.9 at ±17,±9; back rail 34x0.6x0.6; storage track 28x0.25x0.8; feeder 7x0.25x3 | `TYC:30-45` | 6 per `INT:53`. Code loop and schema allow 2-8 (`TYC:30`; `Tycoon.luau:9`) |
| Habitat grid | cols x±30, rows z -44 + 28k (k0..3); creature at pad +2 up, scale .65 | `TYC:31, 78` | needs re-layout (G2) |
| Conveyor spine | 10x0.4x100 + 2 trims 0.3x0.25x100 at ±5.2 | `TYC:26-28` | `INT` lists "eggs roll to the bank"; spine length does not fit 100 depth (G2) |
| Production bank | 12x3x6 at z+56 (tycoon-local), plinth 14x0.6x8, slot 7x0.15x1.2; prompt "Manage / collect / bank" | `TYC:46-51` | keep |
| Machines x3 | 4x3x5 body, pillars 1.2x5x2 at ±3.8, arch 9x1x2, status 5x0.2x0.25; z -30/-2/26 | `TYC:54-58` | keep or cut (owner) |
| Hatchery (Incubator marker) | 3x2x3 at x-14, z-83; prompt "Incubate / hatch" | `LAY:13`; `SANC:63-68` | marker only; "big hatch moment" structure GAP G3 |
| Training Beast / Grip | Training marker 3x2x3 at x14, z-83; prompt "Train companions"; train = 15 coins, +80 XP | `LAY:13`; `SANC:68`; `UIRequests.luau:262,268` | marker only; Beast model, Grip, daily workout GAP G3 |
| Mount stable | none | n/a | GAP G3 |
| Decor slots x14 | none | `INT:25` | GAP G4 |
| Plot front | dry-stone wall 2.2 high x2.8 deep each side of an 18-stud entry gap; entry posts 1.4x11x1.4 at ±18; beam 38.5x1.2x1.6 at y11.6; brass inlay 30x0.3x1.7; cap 40x0.5x2.4 at y12.45; corner endposts 0.9x4.4x0.9; planting beds either side | `PROM:154-169` | keep as plot identity |
| Dividers | boundary hedge art, trimmed to depth, tree at promenade end (scale 1.9) | `PROM:171-188` | keep |
| Egg storage cap | 24 eggs | `UIRequests.luau:177` | rule, not geometry |
| Per-plot habitat slots | Tycoon schema `slots` integer 2..8 | `Tycoon.luau:9` | schema change for 6 (open item `INT:49`) |

Arithmetic check (derived): 2 habitat columns of 36 + 10 spine = 82 > 80 plot width, so the current grid cannot be scaled in. `INT:49` already says re-layout, not scale-down.

---
## C. Commons components

| Component | What existing source gives | Source |
|---|---|---|
| Commons street | promenade 70 wide: 2 lanes of 29 (Cobblestone `approach`) + 12 channel; kerb 1.5x1.1; escape rule 32 | `LAY:5`; `PROM:121-127` |
| Channel (Azure) | 12-wide bed, 10 wide x0.2 water, coping 1x1.4, brass guide strips at ±2.5 (conveyor-ready, no gameplay) | `PROM:112, 126-132`; `RPT:25` |
| Gate plaza | `ForecourtPaving` (promenade+40 = 110 wide x1) at the gate; gate opening 150, towers 26x24x72; Enter-Blossom prompt at gate z+16 | `PROM:117, 198-248`; `LAY:6`; `SANC:18-21` |
| XP arrival moment | no world geometry. UI: banner `B.bnr` / toast `B.toast` / `B.cpop` styles; SAFE GATE beacon billboard at the exit | `GB:336-340`; rows 62, 64, 71 |
| Garden strips | planting-bed prototype (`PlantingSoil`, `AlpineBlossom`, `AlpineLeaf`), `PineBough`/`CedarTrunk` tree, `WeatheredBoulder`, dividers; south garden trees x4, beds x4, boulders x4 | `PROM:47-50, 171-196` (part names; their colours are baked, G1) |
| South garden / pool | pool basin 26x1x26, water 24x0.2x24, plaza paving 42x1x35 (x2) + 26x1x9, coping 1.4 high | `PROM:133-141` |
| Lanterns | Cedar post + brass base + warm glass + cap (clone, scale 1.7), at both lane edges every plot front and divider | `PROM:142-152` |
| Notice board | none in code. Panel recipe `W.glass` + `row()`; daily quest source = mountain/lake/home quests (`INT:57`) | `GB:313, 365` |
| Streak shrine | none. UI analogue: `ladder` rungs with claimed/ready/locked states | `GB:358` |
| Lake portal | none in code. Role from refs: ring opens, swirl above, stacked helical rings column (IMG04, `LAKE` §4); "stone frame filled with light" readable through fog (`LAKE` §1, text only, frame 01 not re-viewed here) | IMG04; `LAKE:11-14,43-44` |
| Collection hall / leaderboard | none. Reuses existing Collection menu UI (P5) for content; hall geometry GAP | `INT:24`; `GB:350` |
| Visitor inspect | read-only tap on creatures/displays | `INT:30` |

Commons = cross-shaped street (`INT:34`), not built; the only street in code is the single 70-wide promenade.

---
## D. Tier-up VFX beat sheet (IMG02, 18 frames at ~0.5 s/frame, derived from `LAKE:23-30` about 8.8 s total; +-0.5 s)

| Beat | t (s) | Frames | What is seen (roles, not hex) |
|---|---|---|---|
| 1 Idle | 0-1.0 | 1-2 | old-tier plot (rail fence + flat ground tile) static; a few thin white ring lines begin to circle it |
| 2 Anticipation | 1.0-1.5 | 3 | ring lines grow into a wider orbit ring around the footprint, one ring on the ground |
| 3 Deconstruct | 1.5-2.5 | 4-5 | fence rails and ground pieces break into cubes keeping their old-tier colours (wood role, ground role) and lift; ground shockwave ring expands; rings thicken |
| 4 Swirl (colour shift) | 2.5-4.5 | 6-9 | cubes form a donut cloud around the footprint (hole visible by f8); colour passes old -> new tier while the old model is hidden; discrete cubes carry a bright accent glow (about 8-12 orbs); thin light streaks; 2-3 concentric rings pulse on the ground |
| 5 Contract | 4.5-5.0 | 10-11 | cloud contracts toward the centre, shrinks, new floor already visible underneath |
| 6 Reconstruct | 5.0-6.0 | 11-13 | new-tier fence and floor present; remaining cubes settle; rings thin and fade |
| 7 Hold | 6.0-8.8 | 14-18 | static new tier; a faint ring line lingers then clears |

Rules from the frames: recolour happens inside the swirl, never as a pop; four distinct beats (anticipation, burst, swirl, settle); the sky/ground in IMG02 is a default baseplate and is not reference.
Implementation shape stated in `LAKE:34`: server sets tier, client plays from a capped cube pool, cap per quality tier, 0 under Reduce effects with a short crossfade, skippable, no gameplay lock longer than the effect.
Do **not** copy the reference's violet/neon new-tier look. Tier colours/themes are open (`INT:55`, G5).
Shared ring/swirl kit with the lake portal (IMG04) and hatch rings: `LAKE:44`.

### D2. Lake portal activation (IMG04, 20 frames at ~1 s/frame, effect ~8 s looped, `LAKE:42-44`)
| Beat | t (s) | Frames | Role |
|---|---|---|---|
| Empty | 0-4 | 1-4 | nothing but the scene |
| Ring opens | 4-5 | 5 | flat layered ring (several thin concentric bands) appears at height |
| Cloud grows | 5-8 | 6-8 | soft smoke/cloud swirl builds above the ring, rotating |
| Ring column | 8-10 | 8-9 | column of stacked thin rings descends through the centre |
| Hold | 10-18 | 11-19 | cloud + ring column + glow held, slow rotation |
| Cut | end | 10, 20 | hard cut to black |

---
## E. Hatch moment beat sheet (IMG03, 20 frames at ~0.55 s/frame, about 11 s, `LAKE:36-39`)

| Beat | t (s) | Frames | What is seen | Our mapping |
|---|---|---|---|---|
| 1 Charge-up | 0-1 | 1 | dark screen, small droplet shape, dim | egg shake/drop; world dims |
| 2 Orbit | 1-3.5 | 2-5 | box at centre wrapped by 2-3 large orbit rings (tilted), cube debris, vertical light shafts | rings + cube debris around egg; same kit as tier-up |
| 3 Flash | 3.5-4 | 6 | full white flash | flash, skippable |
| 4 Reveal + carousel | 4-7 | 7-13 | item appears, fans into a row of 3D cards turning around a vertical axis | not needed; our reveal = species reveal strip |
| 5 Pick | 7-8 | 14-15 | chosen item centred, others exit sideways; item turns edge-on | hold on creature |
| 6 Halo | 8.5-9.5 | 16-17 | ring halo (one broad, one tight, contrasting) around the item | halo rings, scale with rarity |
| 7 Confetti | 9.5-10 | 18 | confetti falls above | rarity-scaled |
| 8 Rarity + stars | 10-11 | 19-20 | rarity line above, star rating pops to the side, star colour steps up | rarity word + pill |

Existing implementation to keep (`LAKE:39`: Glassbloom strip stays the UI, this is the world stage): server `Hatch`/`Incubate` actions return a creature (`UIRequests.luau:232-244`, "A new companion hatched!"); client tier-3 moment `kind='hatch'` with Collect CTA, strip of 20 cards landing on index 14, selector, halos, sparkles, result card, word LG 62, name LG 22, chance FO 14 (`design/hud-glassbloom-p5-reveal-brief.md:6-15`; `GB:371`). Rule: common stays fast, higher rarity = more rings and longer hold (`LAKE:39`). Loop spin title varies by tier ("SOMETHING (RARE) IS COMING...", `Motion.luau:526`).

---
## F. Perf constraints stated in repo docs
| Constraint | Value | Source | Status |
|---|---|---|---|
| Phone floor | 30 FPS on mid-range phone, 60 desktop | `design/v3-ascent-plan.md:21` | PROPOSED numbers, LOCKED priority |
| Floor verification | 30 FPS on Studio mobile emulation, UNVERIFIED on device | `design/autonomous-build-brief.md:32, 47` | |
| Phone targets | 60 FPS median at home/gate/mid-mountain/nest, no stall > 100 ms, memory <= 1.5 GB, join <= 15 s | `design/phone-candidate-2026-10-26.md:62-70` | PROPOSED; conflicts with the 30 FPS floor, owner to pick one (G7) |
| Measured home base (desktop, focused) | median 16.5-16.7 ms, p95 <= 18.1 ms, 132-454 draw calls, all 8 home views | `RPT:40` | measured |
| Creature budget | <= 2k parts/CSG instances per visible region | `autonomous-build-brief.md:47` | ESTIMATE |
| Streaming | `StreamingEnabled` off (all 8 plots resident for every client) | `design/compact-mountain-integration.md:13`; `phone-candidate-2026-10-26.md:59` | per-plot instance count multiplies by 8 |
| Shop open on phone emulator | no frame > 33 ms | `design/hud-glassbloom-build-plan-2026-10-27.md:191` | gate |
| Low-end Android | unproven; `effectsTier` LOW = reduce effects + no rays is the safety valve | same, line 191 | |
| Reduce effects | stops loops; transitions <= 0.15 s fades or instant | same, line 157; `Motion.luau:146` | applies to world VFX too (recommended) |
| UI loop caps | holo 1, shine 3, idle 6 per open menu | `Motion.luau:129` | UI only |
| Glass layering | ~5 instances per glass panel; watch descendant budget | `build-plan:203` | applies to world billboards |
| Whole-place count | 13,707 instances (phone candidate 01) | `phone-candidate-2026-10-26.md:34` | baseline before home rebuild |

---
## G. GAPS (ask owner) — no source, nothing invented
| # | Gap | Needed for |
|---|---|---|
| G1 | Lodge body colours/materials and the colours of baked parts (plotFloor/plotEdge use, lantern post, planting soil, blossom, leaf, trunk, bough, boulder). They exist only in the saved place, not in source. Option: sample the baked Review01 copy `climb-collect-mountain-quality/outputs/ClimbCollect.HomePromenade.Review01.rbxl` in Studio | lodge, garden, lanterns |
| G2 | 80x100 re-layout: where the 6 habitats, spine, bank, 3 machines, hatchery, Beast, stable, 14 slots go. Existing grid is 110x120 and cannot be scaled in. Machines: keep 3 or cut? | plot plan |
| G3 | Sizes/models for Hatchery structure, Training Beast + Grip, daily workout area, mount stable (only 3x3 markers exist) | plot components |
| G4 | Decor/display slot footprint, pedestal shape, which are visitor-inspectable | 14 slots |
| G5 | Plot tier themes (count and look) and per-tier colour roles. Owner asked for proposals. None exist in any source, so none are given. Reference IMG02's violet/neon is not a project value | tier-up |
| G6 | Cross-shaped commons dimensions (street widths, plaza size, block gaps) and geometry for notice board, streak shrine, lake portal frame, collection hall, leaderboard | commons |
| G7 | Phone target conflict: 30 FPS floor (v3 plan, build brief) vs 60 FPS median (phone-candidate doc). Also no per-plot or commons instance budget and no world-VFX cube cap per quality tier (the numbers `LAKE:34` promises) | perf |
| G8 | Arrival pop-up content layout (XP, coins, etc.) and notice-board/streak UI panels: GB has banner/toast/ladder/row recipes but no spec for these screens. Section §3+ of GB (lines 379-626, containment and motion tokens) not read for this pass | UI |
| G9 | Billboard style: keep legacy `TYC:15-18` label or migrate to Glassbloom (A2 flag) | billboards |
| G10 | Timings are +-0.5 s from 1-2 fps contact sheets; no audio analysed; portal "stone frame" described from `LAKE` text only, frame 01 not re-viewed | VFX |
