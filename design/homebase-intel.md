# Home-base intel — v2 (atlas pass 2, 2026-10-29)

Scope: per-player home base, layout C (8 plots 80 frontage x 100 deep, cross-shaped commons). Build worktree `homebase-c`.
Rule: every value cites a file+line, a `PROTO:` descriptor entry or a reference image. Untraceable = not written; listed in G.
Changelog: v1 2026-10-28 (code tokens, VFX beats, gaps G1-G10). v2 2026-10-29: source keys re-keyed to homebase-c and line numbers re-checked; A3 lodge + new A5 protos (G1), A6 tier roles (G5), A7 decor props, A8 billboard migration (G9), C1 commons tokens (G6), C2 UI recipes (G8), F perf budgets (G7); G statuses updated.

**Source keys** (homebase-c = `C:\Users\HOME!\Desktop\ClimbCollect\game\homebase-c`; legacy = `C:\Users\HOME!\Desktop\climb&collect`)
| Key | File |
|---|---|
| `PROM` | homebase-c `mountain\world\HomePromenade.luau` |
| `LAY` | homebase-c `mountain\shared\HomeLayout.luau` |
| `TYC` | homebase-c `mountain\server\TycoonWorld.luau` |
| `SANC` | homebase-c `mountain\server\Sanctuary.luau` |
| `CAT` | homebase-c `mountain\shared\Catalog.luau` |
| `HT` | homebase-c `mountain\shared\HomeTiers.luau` |
| `HR` | homebase-c `mountain\shared\HomeRules.luau` |
| `MOT` | homebase-c `mountain\client\UI\Motion.luau` |
| `UIR` | homebase-c `mountain\server\UIRequests.luau` |
| `PLAN` | homebase-c `design\homebase-build-plan-2026-10-29.md` |
| `SCH` | homebase-c `design\homebase-schema-2026-10-29.md` |
| `RPT` | homebase-c `design\homebase-promenade-review01-report.md` |
| `PROTO:<proto>.<part>` | homebase-c `evidence\homebase_2026-10-29\p0\protos.json` (Studio descriptor of `ServerStorage.HomeProtos`, P0 task 6) |
| `INT` | legacy `design\homebase-redesign-interview-2026-10-29.md` |
| `LAKE` | legacy `design\lake-world-and-vfx-reference-analysis-2026-10-29.md` |
| `GB` | legacy `design\hud-glassbloom-intel.md` (read-only; §1-§6 read for v2) |
| `IMG02/03/04` | legacy `references\lake-world\02-base-upgrade-sequence.jpg`, `03-card-reveal-vfx.jpg`, `04-portal-vortex-vfx.jpg` |

Line check v1 -> homebase-c: `PROM`, `LAY`, `TYC`, `SANC`, `CAT`, `GB` §1-§2 lines unchanged. Moved: `UIR` egg cap 177 -> **178**, hatch 232-244 -> **271-283**, train 262/268 -> **291-307**; `Tycoon.luau:9` -> **:18**; `MOT` caps 129 -> **114**, `reduced()` 146 -> **129-131**, spin title 526 -> **98** (token) / **518**.

**Finding (v1, kept).** `design/world-tokens.md` is PROPOSED mountain text with no sanctuary value; not used. Sanctuary tokens = `PROM:9-14` + harvested protos (A5).

---
## A. Material + colour tokens

### A1. Sanctuary / gateway (`PROM:10-13`, RGB exact from code)
| Token | RGB / hex | Material(s) as used | Where used (line) |
|---|---|---|---|
| dryStone | 125,139,139 / #7D8B8B | Cobblestone (walls); Slate (post foot 162, `PROTO:Lantern.LanternPlinth`) | plot front wall 159, tower shaft 204, lintel 233, wing walls 225 |
| stoneCoping | 185,193,178 / #B9C1B2 | Slate | wall coping 160, channel coping 126/128, pool coping 140, capitals 209, wing coping 226 |
| cedar | 98,68,43 / #62442B | Wood | entry posts/beam 161-165, gate inlay 206, entablature 232, braces 241, endposts 227 |
| pierFoot | 73,91,99 / #495B63 | Slate | channel bed/foundation 112-113, pool basin 137, gate pier foot 203 |
| tealCornice | 46,94,99 / #2E5E63 | Slate (WedgePart roofs) | entry cap 167, gate roofs 211/237, cornice 234, lantern cap 219 |
| brass | 173,139,75 / #AD8B4B | Metal | entry inlay 166, gate inlays 207/213/235/244, lantern base 217, conveyor guides 132 |
| crest | 105,201,211 / #69C9D3 | Neon | gateway crest 238 (9x9x0.6, rotated 45°, brass frame 11x11x0.4 at 239) |
| lanternGlass | 255,221,155 / #FFDD9B | Neon + PointLight (Range 22, Brightness 1.4, same colour) | gate lanterns 218-220 |
| meadow | 90,135,82 / #5A8752 | Grass | basin ground 106, ground plugs 115-116 |
| approach | 179,174,151 / #B3AE97 | Cobblestone | lanes 123, forecourt 117, plaza 135-136 |
| pale | 215,208,174 / #D7D0AE | Slate | lane kerb 124 |
| plotFloor / plotEdge | 126,157,132 / #7E9D84 · 214,223,208 / #D6DFD0 | declared only (line 12); floor/edge parts are baked, not harvested | G1 |
| water (Azure) | 83,153,159 / #53999F | Glass, Transparency .25, CanCollide false, CanQuery false | channel 129-130, pool 138. Value = `CAT:4` (`kingdoms[2].color`, Azure Falls) via `PROM:13` |

Finish rules: Anchored, CanTouch false, Top/Bottom Smooth (`PROM:18`). Ground level `groundY` 16 (`LAY:4`).
Cross-check: protos match A1 exactly for dryStone, stoneCoping, cedar, brass, lanternGlass, tealCornice (A5).

### A2. Habitat / production props (`TYC`) — unchanged from v1, lines verified
| Part | RGB | Material | Line |
|---|---|---|---|
| ConveyorSpine | 40,62,65 | Metal | 26 |
| SpineTrim | 114,203,177 | Neon | 28 |
| Habitat pad | 85,123,100 | Grass | 33 |
| Habitat rim, posts, back rail | 219,189,122 | Wood | 34, 38, 40 |
| Feeder, storage track | spine colour | Metal | 35, 41 |
| Storage fill | rim colour; full = 255,211,103 | Neon | 42, 91 |
| ProductionBank | 219,189,122 (kingdom accent at runtime, 70) | Metal | 46 |
| BankPlinth / DepositSlot | spine colour | Slate / Metal | 50-51 |
| Machines | 82,104,114 | Metal | 54 |
| Machine status light | bank colour | Neon | 58 |
| Runtime accent | `CAT:3-8` accents: blossom 243,170,205; azure 100,222,233; sunstone 255,211,103; violet 200,157,255; inferno 255,151,69; astral 153,198,255 | — | `TYC:69, 84-98` |
| Service markers | Incubator 133,187,177; Training 204,168,105 | Wood | `SANC:65-66` |
| World label (legacy) | see A8 | — | `TYC:14-19` |

### A3. Lodge (`PROTO:Lodge_01`, harvested from `EnchantedAlpineLodges.Lodge_01`, placedScale 1)
126 BaseParts (palette sum; descriptor `count` 128 = 2 non-part descendants, type not recorded). Bounds **34.10 W x 23.18 H x 29.65 D** (fits `LAY:14` 35x30). Hex exact from descriptor.
| Colour (RGB) | Material | Parts (count) | Total |
|---|---|---|---|
| #5B3925 (91,57,37) | Wood | fascia 4, eave rail 2, lintel 1, eave beams 2, timber posts 4, gable kingpost 2 / rafter 4 / strut 4 / tie 2, porch column 2 / knee brace 2 / side rail 2, roof underlay 2, side timber pier 6, sills 6 | 45 |
| #B9924E (185,146,78) | Metal | column collar 2, crest hanger 1 / mount 4, fascia inlay 4, lantern cap 4, ridge cap 1, roof standing seam 10 | 26 |
| #203739 (32,55,57) | Metal | estate number 1, mullions 8, lantern backplate 2, window transom 2 | 13 |
| #274D4E (39,77,78) | Slate | RoofCourse_0..5 (2 each) | 12 |
| #A3DDDD (163,221,221) | Glass | front glazing 2, gable glass 4, side glazing 4 | 10 |
| #85908F (133,144,143) | Cobblestone | chimney 1, front plinth 2, porch pier 2, side stone base 2 | 7 |
| #85908F | Slate | entry steps 3, stone foundation 1 | 4 |
| #9C6D42 (156,109,66) | WoodPlanks | porch deck 1, rear timber wall 1, side upper band 2 | 4 |
| #8AEDD9 (138,237,217) | Neon | AlpineCrest 1, EnchantedLantern 2 | 3 |
| #203739 | Slate | chimney crown | 1 |
| #203739 | SmoothPlastic | chimney top | 1 |
Note: lodge values are their own family. They do **not** equal A1 (brass #B9924E vs #AD8B4B, timber #5B3925 vs cedar #62442B, stone #85908F vs #7D8B8B, roof #274D4E vs tealCornice #2E5E63, crest #8AEDD9 vs #69C9D3), although `PROM:3` says its colours are copied from lodge art. Use lodge values only on the lodge.

### A4. Glassbloom tokens (`GB` §1, hex exact from board CSS) — lines verified
| Role | Token | Value | GB line |
|---|---|---|---|
| Text | text | #FFFFFF | 35 |
| Text outline/shadow | ink (Luau `outline`) | #150A33 | 36 |
| Pill fill (neutral) | night2 | #14063C | 39 |
| Action | pk / vi | #F46BC4 / #A55BEA | 30 / 31 |
| Glass panel | glass.from / to / rim | #8246DC / #32146E / #FFD2FF, fillT .45/.38, rimT .45 | 43-45, 103-104 |
| Kicker / header | pinkText | #FFD0F0 | 46 |
| Safe / secured | go, go.ink, go.glow | #7BFFD0, #06281E, #5DFFC0 | 58, 62, 60 |
| Coins / XP | gold, gold.text, moment.text | #FFD84A, #FFE9A8, #FFE45C | 64, 71, 72 |
| Rarity rim | blue / gold / violet / prism | #6C8CF0 / #F7A21B / #B06CF0 / #FFB8EA | 94-97 |
| Faces | LuckiestGuy (display) / FredokaOne (body) | | 227 / 229 |
| In-world label | `t.beacon` 12 FO, scope W (never HUD-scaled) | | 256 |

### A5. Harvested prototypes (`PROTO:`; original size = placed size / placedScale; hex exact from descriptor)
**Lantern** (placedScale 1.7, 5 harvested; bounds original 2 x 7.0 x 2, placed 3.4 x 11.9 x 3.4)
| Part | Original size | Placed size | Offset y (orig) | Hex | Material | Token |
|---|---|---|---|---|---|---|
| LanternPlinth | 2 x 1 x 2 | 3.4 x 1.7 x 3.4 | 0.5 | #7D8B8B | Slate | dryStone |
| CedarLanternPost | 0.5 x 5 x 0.5 | 0.85 x 8.5 x 0.85 | 3.0 | #62442B | Wood | cedar |
| BrassLanternBase | 1.7 x 0.3 x 1.7 | 2.89 x 0.51 x 2.89 | 5.3 | #AD8B4B | Metal | brass |
| WarmLanternGlass | 1.1 x 1.2 x 1.1 | 1.87 x 2.04 x 1.87 | 6.0 | #FFDD9B | Neon | lanternGlass |
| LanternCap | 2 x 0.4 x 2 | 3.4 x 0.68 x 3.4 | 6.8 | #2E5E63 | Slate | tealCornice |
No light recorded (descriptor lists parts only); the gate lantern PointLight is `PROM:220`.

**Tree** (placedScale 2.2, 13 harvested; "2 neighbour boughs removed"; bounds original ≈ 6.4 x 13.43 x 6.4 **est.**: bough rotations not in descriptor)
| Part | n | Original size | Offset (orig x,y,z) | Hex | Material / class |
|---|---|---|---|---|---|
| CedarTrunk | 1 | 0.768 x 9.45 x 0.768 | 0, 4.725, 0 | #62442B (cedar) | Wood / Part |
| PineBough low | 4 | 3.2 x 5.805 x 3.2 | ±1.6, 4.185, ±1.6 | #275B49 | Grass / CornerWedgePart |
| PineBough mid | 4 | 2.496 x 5.805 x 2.496 | ±1.248, 7.358, ±1.248 | #397155 | Grass / CornerWedgePart |
| PineBough top | 4 | 1.792 x 5.805 x 1.792 | ±0.896, 10.53, ±0.896 | #275B49 | Grass / CornerWedgePart |

**PlantingBed** (placedScale 1.4, 11 harvested; bounds original 3 x 1.45 x 6)
| Part | n | Original size | Offset y | Hex | Material |
|---|---|---|---|---|---|
| PlantingSoil | 1 | 3 x 0.24 x 6 | 0.12 | #474230 | Ground |
| AlpineLeaf | 5 | 0.28 x 1.1 x 0.28 | 0.6 | #397155 | Grass |
| AlpineBlossom cream | 3 | 0.65 x 0.5 x 0.65 | 1.2 | #EEDC9D | SmoothPlastic |
| AlpineBlossom lilac | 2 | 0.65 x 0.5 x 0.65 | 1.2 | #B69BD5 | SmoothPlastic |
Leaves sit at x ±0.89, z ±1.85 (orig), inside the soil.

**Boulder** (placedScale 2.5, 1 harvested): WeatheredBoulder, original **2.7 x 1.701 x 2.214** (placed 6.75 x 4.25 x 5.54), offset y 0.486, #707F81, Rock.

**Divider_01** (placedScale 1; 116 BaseParts, 118 descendants; bounds 12.16 x 26.28 x 177.43; palette only, no per-part sizes)
| Part name | Hex | Material | n |
|---|---|---|---|
| PineBough | #275B49 / #397155 | Grass | 32 / 16 |
| AlpineLeaf | #397155 | Grass | 20 |
| AlpineBlossom | #EEDC9D / #B69BD5 | SmoothPlastic | 12 / 8 |
| TimberEndpost | #62442B (cedar) | Wood | 7 |
| CedarTrunk | #62442B | Wood | 4 |
| PlantingSoil | #474230 | Ground | 4 |
| DryStoneSegment | #7D8B8B (dryStone) | Cobblestone | 3 |
| StoneCoping | #B9C1B2 (stoneCoping) | Slate | 3 |
| WeatheredBoulder | #707F81 | Rock | 2 |
| Lantern set (plinth, post, base, glass, cap) | as Lantern | as Lantern | 1 each |

**New proto-only tokens** (not in `PROM`): soil #474230 (71,66,48) Ground · leaf #397155 (57,113,85) Grass · boughDark #275B49 (39,91,73) Grass · blossomCream #EEDC9D (238,220,157) · blossomLilac #B69BD5 (182,155,213) SmoothPlastic · boulder #707F81 (112,127,129) Rock. blossomLilac is a baked planting value, not a tier colour.

### A6. Tier role table (G5; names owner-fixed, `PLAN:221`; roles = `HT:6-9` = `PLAN:74`, identical order)
| Tier | Name | Cumulative roles | Added roles: recipe in source | Status |
|---|---|---|---|---|
| T1 | Dry-stone Yard | dryStone, stoneCoping, meadow | dryStone: FrontDryStone `PROM:159` (Cobblestone), EntryPostFoot `:162` (Slate), `PROTO:Divider_01.DryStoneSegment`. stoneCoping: FrontCoping `:160`, `PROTO:Divider_01.StoneCoping`. meadow: BasinGround `:106` (ground slab only) | meadow has no plot-part recipe (plot floor is plotFloor, G1) |
| T2 | Cedar Cloister | + cedar, pierFoot | cedar: EntryPost/Beam/CornerEndpost `:161-165`, `PROTO:Lantern.CedarLanternPost`, `PROTO:Divider_01.TimberEndpost`. pierFoot: ChannelBed `:112`, PoolBasin `:137`, PierFoot `:203` | pierFoot: **name only at plot scale** (commons/gate recipes) |
| T3 | Brass & Lantern | + brass, lanternGlass, tealCornice | brass: EntryBrassInlay `:166`, `PROTO:Lantern.BrassLanternBase`. lanternGlass: `PROTO:Lantern.WarmLanternGlass`, gate glass + PointLight `:218-220`. tealCornice: EntryCap `:167`, `PROTO:Lantern.LanternCap` | recipes exist |
| T4 | Azure Terrace | + azureWater, crest | azureWater = A1 `water` (`CAT:4`), channel/pool `:129-130, 138`. crest: GatewayCrest + CrestFrame `:238-239` | both **name only at plot scale** (gate/commons recipes) |
Rules: no violet/neon from IMG02. crest is Neon in code (`PROM:238`), so it stays; IMG02's violet look does not. Swirl recolour (D beat 4) goes old-tier roles -> new-tier roles.
Conflicts: (1) `HT:9` names the role `azureWater`, `PROM:13` names it `water`: alias needed. (2) The current entry frame (`PROM:161-167`) already shows cedar, brass and tealCornice at T1, and the lodge (A3, unchanged per `PLAN` P4.6) shows its timber/brass/roof at every tier. Recommended: roles govern only the `TierPart` set (`PLAN` P4.5); entry frame + lodge stay constant. Cost: T1 is not purely dry-stone. Alternative: strip the T1 entry frame to dryStone/stoneCoping. Owner/architect decision.

### A7. Decor props on a 3x3 stand (`SCH:28-35`, `HT:13-20`; stand 3x3 `PLAN:68`). Scale s = 3 / largest original footprint side; fit to exactly 3 (any margin is a builder call)
| Prop | Form source | Original bounds W x H x D | Arithmetic | Size at s | Colours |
|---|---|---|---|---|---|
| boulder | `PROTO:Boulder` | 2.7 x 1.701 x 2.214 | s = 3/2.7 = **1.111** (axis-aligned). If yawed like `PROM:196`: diagonal √(2.7²+2.214²) = 3.492, s = 3/3.492 = **0.859** | 3.0 x 1.89 x 2.46 (yawed: 2.32 x 1.46 x 1.90) | #707F81 Rock |
| bed | `PROTO:PlantingBed` | 3 x 1.45 x 6 | s = 3/6 = **0.5** (placed 1.4 = 4.2 x 8.4 does not fit) | 1.5 x 0.73 x 3; leaves 0.14 thick | soil #474230 Ground, leaf #397155 Grass, blossom #EEDC9D / #B69BD5 SmoothPlastic |
| hedge | `PROTO:Divider_01` "trimmed" (`SCH:32`) | per-part geometry not in descriptor | not derivable | OPEN (G1) | palette A5 Divider_01 |
| lantern | `PROTO:Lantern` | 2 x 7.0 x 2 | s = 3/2 = **1.5** (placed 1.7 = 3.4 does not fit) | 3 x 10.5 x 3 | dryStone, cedar, brass, lanternGlass, tealCornice (A5) |
| sapling | `PROTO:Tree` | ≈ 6.4 x 13.43 x 6.4 **est.** | s = 3/6.4 = **0.469** | 3 x 6.30 x 3; trunk 0.36 | cedar #62442B, #275B49, #397155 |
| basin | no proto (`HT:19` proto nil) | — | — | form OPEN | water #53999F Glass T.25, no collide/query (`PROM:129-130, 138`, `CAT:4`). Pool recipe `PROM:137-140`: basin 26x1x26 pierFoot Slate, water 24x0.2x24 (1 inset per side) at y -0.5, coping stoneCoping Slate 1.4 high x 2 wide, inflow edge skipped. Straight scaling 3/26 = 0.115 gives water 0.023 thick: degenerate, so no scaled form is given |
| pedestal (stand) | `PLAN:68` 3x3 only | — | — | material, height, shape OPEN. Nearest existing block: EntryPostFoot 2.4 x 1.2 x 2.4 dryStone Slate (`PROM:162`), not a decision | — |

### A8. Billboard migration (G9: owner chose Glassbloom, `PLAN:221`)
| Property | Legacy (`TYC:14-19`) | Glassbloom target | Source |
|---|---|---|---|
| Container | BillboardGui 160x42 px fixed | size to the pill: h = line-height + 2 x border (`W.pill`); beacon label h 23 | `GB:320, 336` |
| MaxDistance | 45 | 45 | `TYC:15`; `PLAN:76` |
| AlwaysOnTop | unset (false) | keep false; only the safe-gate beacon is AlwaysOnTop | `GB:336` |
| Offset | StudsOffset (0,3,0) or creature height + 2 | keep | `TYC:16, 80-81` |
| Fill (neutral) | 24,40,48 at T.25 | `night2` #14063C T.15 (rail-label pill: `W.pill(25, 9, night2, .15, 1.5 pk)`, r11) | `GB:39, 110, 328` |
| Fill (safe/ready) | — | `go.ink` #06281E T.22, stroke 1.5 `go`, r10, padX 10 (beacon label) | `GB:62, 111, 336` |
| Stroke | none | 1.5 (`s.thin`) | `GB:151` |
| Text | 245,240,218 | `text` #FFFFFF + 1 px `outline` #150A33 T.2 UIStroke | `GB:35-36, 319` |
| Font | GothamMedium 14 | FredokaOne 12 (`t.beacon`, scope W) | `GB:229, 256` |
| FULL state | "· FULL" text + fill Neon 255,211,103 | recommended: `gold` #FFD84A on the pill stroke (ready-rung analogue) | `TYC:91, 94`; `GB:64, 358` |
| Locked state | "· locked" text | recommended: `text.dimT` on the text | `TYC:93, 97`; `GB:116` |
| Two-line labels | TextWrapped (name + eggs) | pill is single-line; 2-line layout not specified | `TYC:18, 93`; G9 PARTIAL |
| Instances / label | 2 | 6 (Gui, Frame, UICorner, UIStroke, UIPadding, TextLabel) + 1 text stroke = 7 | `GB:319-320` |
| Budget | 12 per plot today (8 habitats + bank + 3 machines, `TYC:44, 49, 60`) | <= 12 per plot; at 6 habitats = 10 labels = 60-70 instances (`PLAN:76` estimated 60) | `PLAN:76` |
No `W.glass` on billboards (about 8 instances each, `GB:313`).

---
## B. Plot inventory (current code; target sizes/positions are `PLAN:52-70`)
| Component | Current size / pos (plot-local) | Source | v2 note |
|---|---|---|---|
| Plot floor | 140x2x180; target 80x100 `Plot_80x100` | `LAY:4`, `PROM:83`; `PLAN:41` | floor colour G1 |
| Spawn | 6x6 at (0,-83); target (0,-40) | `LAY:12`; `PLAN:57` | |
| Lodge | 35x30, overhang 5.75 at z64; target centre (0,27) | `LAY:14`; `PLAN:63` | **height 23.18, colours A3** |
| Habitat (6) | pad 36x0.5x20 etc.; target pad 15x12 / rim 16x13 | `TYC:30-45`; `PLAN:58` | creature scale on small pad UNKNOWN (`PLAN:59`) |
| Conveyor spine | 10x0.4x100; target E-W 6 wide x 52 | `TYC:26-28`; `PLAN:60` | |
| Production bank | 12x3x6, plinth 14x0.6x8 | `TYC:46-51`; `PLAN:61` | |
| Machines x3 | 4x3x5, pillars ±3.8 | `TYC:54-58`; `PLAN:62` | re-proportion |
| Hatchery | marker 3x2x3; target dais 14x14 at (-29,26) | `SANC:60-72`; `PLAN:64` | form G3 |
| Training Beast | marker 3x2x3; target pen 14x14 at (29,26); train 15 coins +80 XP | `SANC:68`; `UIR:291-307`; `PLAN:65` | form G3 |
| Decor slots x14 | 3x3 pedestals | `PLAN:68` | A7; pedestal G4 |
| Plot front | wall 2.2 x 2.8; entry posts 1.4x11x1.4 at ±18; beam 38.5; inlay 30; cap 40 | `PROM:154-169` | scales with `plotWidth` (`:158-159`) |
| Dividers | boundary hedge, tree at street end (scale 1.9) | `PROM:171-188` | per-part geometry G1 |
| Egg storage cap | 24 | `UIR:178` | rule |
| Habitat slots | schema 2..8, rules cap 6 | `Tycoon.luau:18`; `HR:9, 49-59` | |

---
## C. Commons

### C1. Commons item tokens (G6; sizes = `PLAN:42-49`, the brief)
| Item | Size (`PLAN`) | Material / colour role | Source |
|---|---|---|---|
| Gate plaza | 40 deep (z -154..-114) x 110 wide | paving approach Cobblestone | `PLAN:43`; `PROM:117` |
| V street | 70 = lanes 29 + channel 12 + 29 | lanes approach Cobblestone; kerb 1.5 x 1.1 pale Slate; channel coping 1 x 1.4 stoneCoping Slate; bed pierFoot Slate 1 thick; water 10 wide x 0.2 Azure Glass T.25; brass guides 0.3 x 0.12 at ±2.5 | `PLAN:42`; `PROM:112, 123-132` |
| H street arms | 56 = lanes 22 + channel 12 + 22, x ±35..±195 | same recipe as V street | `PLAN:47`; `PROM:123-132` |
| Crossing pool | 26 x 26 | basin pierFoot Slate, water Azure Glass T.25, coping stoneCoping 1.4 high (inflow edges open) | `PLAN:47`; `PROM:137-140` |
| Crossing plaza | 70 x 56 | paving approach Cobblestone | `PLAN:47`; `PROM:135-136` |
| W end plaza | 60 x 56 (x -195..-135) | paving approach Cobblestone | `PLAN:48`; `PROM:135` |
| E end plaza | 60 x 56 (x 135..195) | paving approach Cobblestone | `PLAN:48`; `PROM:135` |
| Shared garden strip | 16 x 100 | ground meadow Grass; contents `PROTO:PlantingBed`, `PROTO:Tree`, `PROTO:Boulder` | `PLAN:69`; `PROM:106`; A5 |
| Lanterns | `PROTO:Lantern` at 1.7, lane edge inset 3 | A5 Lantern | `PROM:148` |
| Plot side walls | — (size not in plan) | reuse front wall: dryStone Cobblestone 2.2 x 2.8 + coping stoneCoping 0.3 x 3.2 | `PROM:159-160` (reuse proposal) |
| South meadow | leftover basin south of `southZ` 294 | meadow Grass | `PLAN:45, 49`; `PROM:106` |
| Notice board | form OPEN | — | G6 |
| Streak shrine | form OPEN | — | G6 |
| Lake portal frame | form OPEN ("stone frame filled with light", `LAKE` text only); VFX roles IMG04 / D2 | — | G6, G10 |
| Collection hall | form OPEN | — | G6 |
| Leaderboard stand | form OPEN | — | G6 |
| Arrival marker line | form OPEN (`PLAN` P5) | — | G6 |
Notes: gate plaza 110 sits inside the 150 gate opening (`LAY:7`), 20 unpaved each side, as in v1. All commons <= 1,500 instances (F).

### C2. UI recipes for home screens (G8; from `GB` §2-§6)
| Screen | Recipe (cited) | Not specified (gap) |
|---|---|---|
| Notice board panel | `panel()` (tint `mtint`, `W.glass` r22, title `W.cta` LG 23, X) `GB:348`; scroll area + section header FO 11 `pinkText` `GB:351`; quest line = `row()` (FO 14 title, FO 11 T.18 desc) `GB:365`; claim = coin `buy` h 22 LG 13 `GB:355`; reset timer = timer pill h 18 r9 `night` T.3 FO 11 `GB:354`; Menu containment `GB:402`; hits >= 44 `GB:405` | quest row progress display; panel open/close durations (`GB:533` G19) |
| Streak shrine | `ladder` (4 equal cols, track 4 px `go` -> white T.8, rung r16 `night` T.4, done/ready/locked, label FO 11) `GB:358`; ready `pulse` 1.2 s `GB:482`; `glow.ready` `GB:209`; Reduce effects stops loops `GB:508` | streak longer than 4 rungs (wrap/scroll), per-day icons |
| Arrival pop-up | sanctuary tier 3 waits for Collect `GB:421, 434`; `B.moment` (LG 64 `moment.text`, stroke 3 `lip`, drop 5 `lipDeep`, sub pill `night2` T.2 FO 13) `GB:339`; XP bar h 10 `GB:343` with `action` gradient `GB:166`; rarity pill `revealPill` / r10 `GB:188, 135`; Continue `W.cta` `GB:317` + 44 hit `GB:405`; motion `moment` 2.5 s `GB:474`; XP toast tier 1 `GB:425` | composite layout (species, rarity, +XP, level bar); "secured" banner named, not drawn (`GB:432`, GB G5); coins line (`PLAN` Q7) |
| Visitor inspect card | `card()` (r14, stroke 3 `ink`, `rcg` fill, name band, XP h 7) `GB:353`; rarity `GB:94-97`; meta FO 14 / sub FO 11 T.15 `GB:343`; fields species/name/rarity/level/owner `SCH:67` | card layout and anchor (screen vs world), close rule, level hexagon shape (GB G12) |
| Tier-up button | coin `buy()` (`coinBuy` #FFE07A -> #F0A020, `glow.buyCoin`, lip `gold.lip`, h 32 LG 16) `GB:355`; or `W.cta` `GB:317`; requirement text `row()` desc `GB:365`; reasons `rank`/`coins` `SCH:68` | disabled / insufficient-funds states (`GB:529` G15) |

---
## D. Tier-up VFX beat sheet (IMG02, 18 frames ~0.5 s/frame, `LAKE:23-30`, about 8.8 s; ±0.5 s) — unchanged
| Beat | t (s) | Frames | What is seen (roles, not hex) |
|---|---|---|---|
| 1 Idle | 0-1.0 | 1-2 | old-tier plot static; thin white ring lines begin to circle it |
| 2 Anticipation | 1.0-1.5 | 3 | ring lines grow into a wider orbit ring on the ground |
| 3 Deconstruct | 1.5-2.5 | 4-5 | fence/ground break into cubes keeping old-tier colours and lift; shockwave ring; rings thicken |
| 4 Swirl (colour shift) | 2.5-4.5 | 6-9 | donut cube cloud; colour passes old -> new tier while the old model is hidden; ~8-12 glowing orbs; 2-3 ground rings pulse |
| 5 Contract | 4.5-5.0 | 10-11 | cloud contracts; new floor visible |
| 6 Reconstruct | 5.0-6.0 | 11-13 | new tier present; cubes settle; rings fade |
| 7 Hold | 6.0-8.8 | 14-18 | static new tier; faint ring clears |
Rules: recolour inside the swirl, never a pop; IMG02 sky/ground is a baseplate, not reference; no IMG02 violet/neon. Tier roles = A6. Shape per `LAKE:34`; caps F. Shared kit with portal/hatch (`LAKE:44`).

### D2. Lake portal activation (IMG04, 20 frames ~1 s/frame, `LAKE:42-44`) — unchanged
| Beat | t (s) | Frames | Role |
|---|---|---|---|
| Empty | 0-4 | 1-4 | scene only |
| Ring opens | 4-5 | 5 | flat layered ring at height |
| Cloud grows | 5-8 | 6-8 | rotating smoke swirl above the ring |
| Ring column | 8-10 | 8-9 | stacked thin rings descend |
| Hold | 10-18 | 11-19 | slow rotation |
| Cut | end | 10, 20 | hard cut |

---
## E. Hatch moment beat sheet (IMG03, 20 frames ~0.55 s/frame, about 11 s, `LAKE:36-39`) — unchanged
| Beat | t (s) | Frames | Seen | Our mapping |
|---|---|---|---|---|
| 1 Charge-up | 0-1 | 1 | dark, small droplet | egg shake; world dims |
| 2 Orbit | 1-3.5 | 2-5 | 2-3 tilted orbit rings, cube debris, light shafts | rings + cubes, tier-up kit |
| 3 Flash | 3.5-4 | 6 | white flash | skippable |
| 4 Reveal + carousel | 4-7 | 7-13 | 3D card carousel | not needed (reveal strip) |
| 5 Pick | 7-8 | 14-15 | item centred | hold on creature |
| 6 Halo | 8.5-9.5 | 16-17 | broad + tight halo | rarity-scaled |
| 7 Confetti | 9.5-10 | 18 | confetti | rarity-scaled |
| 8 Rarity + stars | 10-11 | 19-20 | rarity line, stars | rarity word + pill |
Keep: server `Incubate`/`Hatch` (`UIR:271-283`, "A new companion hatched!"); client reveal strip (`GB:371`; `design/hud-glassbloom-p5-reveal-brief.md:6-15` in the integration repo); spin title by rarity (`MOT:98, 518`). Common fast, higher rarity longer (`LAKE:39`).

---
## F. Perf budgets (G7 resolved: owner chose 60 FPS median on phone, `PLAN:221`)
| Constraint | Value | Source |
|---|---|---|
| Phone target | 60 FPS median; proxied on the emulator (physical iPhone later, `PLAN` Q14); P8 gate: median 16.7 ms on emulator, no frame > 33 ms outside VFX | `PLAN:171, 196, 221` |
| Superseded | 30 FPS floor (`design/v3-ascent-plan.md:21`, legacy) | owner choice above |
| Measured baseline (P0) | place 15,812 edit (workspace 10,432); 8 home views median 16.6-16.7 ms, p95 <= 18.1, 222-525 draw calls | `PLAN:230` (earlier 132-454, `RPT:40`) |
| Net place | <= 15,812 + 4,000 = **19,812** | `PLAN:230` |
| Per plot | <= 750 instances incl. creatures and billboards (estimate breakdown at `PLAN:76`) | `PLAN:76, 230` |
| Commons | <= 1,500 | `PLAN:76` |
| Draw calls | <= 700 in any home view | `PLAN:230` |
| Billboards | <= 12 per plot, MaxDistance 45 (A8) | `PLAN:76` |
| VFX cube pool | effectsTier 1 = 48 cubes + 10 orbs; 0.5 = 24 + 5; 0 or Reduce = none (0.15 s crossfade). Hatch 16/8/0; portal rings 8/4/0 within 60 studs; non-owners <= 50 % within 150 studs. Cubes Anchored, no collide/touch/query/shadow, one `BulkMoveTo` per frame, no per-cube tween | `PLAN:76` |
| effectsTier steps | {0, .5, 1} | `UIProtocol.luau:6` (`PLAN:31`) |
| Reduce / LOW gates | `M.reduced()`, `M.noRays()` | `MOT:129-133` |
| UI loop caps | holo 1, shine 3, idle 6 per open menu | `MOT:114` |
| Streaming | off: all 8 plots resident | `PLAN:76` |
| Glass layering | ~5 instances per glass panel | `design/hud-glassbloom-build-plan-2026-10-27.md:203` |
Arithmetic check: 8 x 750 + 1,500 = 7,500 resident home content vs a +4,000 net allowance. Consistent only if >= 3,500 existing instances are replaced (current per-plot subtree counts are in the P0 handoff, not read here). Flag for STOP 4.

---
## G. GAPS — nothing invented
| # | Gap | Status |
|---|---|---|
| G1 | Baked colours | **PARTIAL.** CLOSED for lantern, tree, planting bed, boulder, divider palette, lodge (A3, A5). OPEN: plotFloor/plotEdge use (floor, `PlotEdge`/`FrontEdge`/`RearEdge`, `RearLodgeFootprint_35x30`, `LodgeFootprintEdge` not harvested, `PROM:71-78`); Divider_01 per-part sizes/offsets (needed for the hedge prop); the 2 non-part descendants in Lodge_01/Divider_01 (lights?); bough rotations (tree bounds est.) |
| G2 | 80x100 re-layout | **PARTIAL.** Sizes/positions in `PLAN:52-70` (PROPOSED, STOP 4). Open: creature display-scale cap (`PLAN:59`), workout track (`PLAN:66`, Q8) |
| G3 | Hatchery / Beast / stable forms | **See world-style intel B10 / G13 (closed 2026-10-29).** Was PARTIAL. Footprints 14x14 (`PLAN:64-65`); stable = habitat row (`PLAN:67`, Q9). Models, materials OPEN |
| G4 | Decor slot | **PARTIAL.** 3x3 x 14 positions (`PLAN:68`); props A7; inspectable = habitats + decor (`SCH:67`). Pedestal material/height/shape OPEN |
| G5 | Tier roles | **CLOSED** (A6) for role mapping. Open inside it: `azureWater`/`water` alias; T1-vs-entry-frame scope decision; pierFoot, azureWater, crest have no plot-part recipe |
| G6 | Commons | **PARTIAL.** Sizes + materials CLOSED (C1). Forms OPEN: notice board, streak shrine, portal frame, collection hall, leaderboard stand, arrival marker line, plot side-wall length |
| G7 | Perf target and budgets | **CLOSED** (F). Open: per-plot vs net arithmetic check |
| G8 | Home UI recipes | **PARTIAL.** Recipes CLOSED (C2). Screen layouts OPEN (arrival composite, quest row, >4 streak, inspect card, disabled tier button) |
| G9 | Billboards | **PARTIAL.** Decision + token map CLOSED (A8). Open: 2-line label layout; FULL/locked styling marked recommended |
| G10 | VFX timing ±0.5 s from contact sheets; no audio; portal frame described from `LAKE` text only | **OPEN** |
| G11 | Basin prop form at 3x3 (no proto; scaled pool degenerate) | **OPEN** (new) |
