# Home-base world style intel (atlas pass 3, 2026-10-29)

Extends the Glassbloom HUD intel to a solid, candy-glass world. Nothing built. Branch `codex/homebase-c`.

**Pass 4 (2026-10-29):** B10 Hatchery + Training Beast added (closes `HI:G3` forms, see G13); D hatchery/Beast rows updated.

**Pass 3 changes**
- F1-F9 closed with the owner S0 answers (`S0.n`); REC removed from every row the owner fixed.
- "Cottage" tier renamed **Villa** everywhere; "cottage" kept only for the base silhouette (`DEC:#5`).
- Path glow and speed lane now share flare #7BD8FF: geometric split proposed (B9, REC).
- Gate B2 recomputed for ~100 studs; houses re-fit to the 35x35 slot, growing upward (B1).
- C cites real `Motion.luau` lines; D totals against 937 per plot; E rewritten from current mountain source (provisional, live audit before S9).

**Cite keys**
| Key | File |
|---|---|
| `DEC:#n` | `design/homebase-style-decisions-2026-10-28.md`, owner decision n (authoritative) |
| `S0.n` | same file, "S0 answers" table row n (authoritative, overrides REC) |
| `GB:n` | `climb&collect/design/hud-glassbloom-intel.md` line n (the ONLY colour/glow/radius source) |
| `HI:<sec>` | `design/homebase-intel.md` v2 section (layout, protos, perf; alpine palette retired for restyled parts) |
| `SCH:n` / `PLAN:n` | `design/homebase-schema-2026-10-29.md` / `design/homebase-build-plan-2026-10-29.md` line n |
| `MOT:n` | `mountain/client/UI/Motion.luau` line n (verified by the orchestrator 2026-10-29) |
| `ME:n` / `WD:n` / `LM:n` | `mountain/world/MountainEntrances.luau` / `World.luau` / `Landmarks.luau` line n |

**Conventions.** Hex = exact CSS value from `GB`, not an image sample. Role assignment is a REC unless `DEC`/`S0` fixes it. Dimensions are PROPOSED geometry unless a plan/decision line is cited. Rules: no outline/lip/inverted hull (`DEC:#3`), SmoothPlastic bodies, Neon trims/windows/crests, Glass T.25 on few accents (`DEC:#4`), no textures, max 1 PointLight per house, Neon instead (`DEC:#20`). Alpine palette (`HI:A1`) and `HI:A5` baked proto colours are **not used** on restyled parts.

---
## A. Palette-to-world role map

| World role | Token | Hex | Material | Source |
|---|---|---|---|---|
| Lawn | go2 | #2FAE8A | SmoothPlastic slab | `DEC:#13`, `GB:59` |
| Lawn light patches | go | #7BFFD0 | SmoothPlastic, flat low discs | `DEC:#13`, `GB:58` |
| Paver (lane, plaza, whole crossing square) | lavText | #CBBCF2 | SmoothPlastic | `DEC:#13`, `S0.5`, `GB:47` |
| Paver centre inlay | pk | #F46BC4 | SmoothPlastic | `DEC:#13`, `S0.9` |
| Path glow strip | flare | #7BD8FF | **Neon** | `S0.9` (geometry B9 REC) |
| Speed-lane strip | flare | #7BD8FF | **Neon** | `S0.10` (geometry B9 REC) |
| Kerb / basin lip | lip | #5A2299 | SmoothPlastic | `DEC:#13`, `GB:41` |
| House body T1 Hut | rarity.blue rc | #6C8CF0 | SmoothPlastic | `DEC:#6`, `S0.8`, `GB:94` |
| House body T2 Villa | rarity.gold rc | #F7A21B | SmoothPlastic | `DEC:#6`, `S0.8`, `GB:95` |
| House body T3 Manor | rarity.violet rc | #B06CF0 | SmoothPlastic | `DEC:#6`, `S0.8`, `GB:96` |
| House body T4 Palace | rarity.prism rc | #FFB8EA | SmoothPlastic | `DEC:#6`, `S0.8`, `GB:97` |
| Roof (tier `rcg` bottom stop) | T1 #5B78E8 · T2 #F0952A · T3 #8A4BE6 | | SmoothPlastic | `S0.12`, `GB:94-96` |
| Roof ridge cap (`rcg` top stop) | T1 #9FB6FF · T2 #FFD27A · T3 #C99BFF | | SmoothPlastic | `S0.12`, `GB:94-96` |
| T4 roof: 4 prism bands cycled per tile ring | #FF8FC0, #FFD27A, #7BD8FF, #B58CFF | | SmoothPlastic | `S0.12`, `GB:97` |
| Door (arched, oversized) | deep | #2B1457 | SmoothPlastic | `S0.11`, `GB:37` |
| Door frame arch | glass.rim | #FFD2FF | SmoothPlastic | `S0.11`, `GB:45` |
| Windows (round portholes) glass | lanternGlass warm | #FFDD9B | **Neon** | `DEC:#14` names the value; window use REC |
| Porthole rim | ctaHi | #FF8FE0 | SmoothPlastic | REC, `GB:32` |
| Chimney body / crest gem | body = roof colour; gem = tier rc | per tier | gem **Neon** | `DEC:#5`, REC colour |
| Gate arch body | vi | #A55BEA | SmoothPlastic | REC, `GB:31` |
| Gate arch base / trim edge | lip | #5A2299 | SmoothPlastic | REC |
| Gate arch inner glow trim | ctaHi | #FF8FE0 | **Neon** | REC |
| Gate crest gem | ctaHi (idle) · burst mint go | #FF8FE0 · #7BFFD0 | **Neon** | `DEC:#12` (burst), REC (idle) |
| Gate sparkles | sparkle.pink x2 · flare x1 | #F78AD0 · #7BD8FF | **Neon** | `DEC:#12`, `GB:33-34, 216` |
| Banner pole | vi | #A55BEA | SmoothPlastic | REC |
| Banner cloth + tip + aura ring | rank band: L<5 #6C8CF0 · 5-14 #F7A21B · 15-29 #B06CF0 · 30+ #FFB8EA | | cloth SmoothPlastic, tip + ring Neon | `DEC:#8`, `S0.1` |
| Globe lamp pole | vi | #A55BEA | SmoothPlastic | `DEC:#14`, `GB:31` |
| Globe lamp collar / foot | lip | #5A2299 | SmoothPlastic | REC |
| Globe | warm #FFDD9B, or pink tint #F78AD0 | | **Neon** | `DEC:#14`; pink hex REC `GB:34` |
| Pill sign body | night2 | #14063C | billboard Frame (T.15) | `DEC:#14`, `HI:A8`, `GB:39, 328` |
| Pill sign text / stroke | text · pk 1.5 | #FFFFFF · #F46BC4 | FredokaOne 12 | `DEC:#14`, `GB:35, 256, 328` |
| Habitat plaque (behind the pill) | glass.from | #8246DC, **Glass T.25** | Glass Part on a post | `S0.7`, `GB:43` |
| Pen fence post + rail, floor tint | one per habitat: #FFD0F0, #CBBCF2, #9FB6FF, #FFD27A, #C99BFF, #7BFFD0 | | SmoothPlastic | `S0.6`, `GB:46-47, 58, 94-96` |
| Coin prop body | gold | #FFD84A | SmoothPlastic, rim **Neon** gold.hi #FFE07A | `DEC:#17`, `GB:64-65` |
| Coin prop glow halo (optional) | #FFD84A T.5 | | Neon ball, CanCollide false | `GB:200` analog |
| Coin price pill | night2 + gold stroke 1.5 | #14063C / #FFD84A | billboard | `DEC:#17`, REC stroke (`HI:A8`) |
| Water (pool, channels) | flare, Glass T.25 | #7BD8FF | Glass | `DEC:#19`, `DEC:#4` |
| Fountain gem | flare | #7BD8FF | **Neon** | `DEC:#19` |
| Streak shrine flame gem | pk, ember tip gold | #F46BC4 / #FFD84A | **Neon** | `DEC:#19`; colours REC |
| Board panel | glass.from, Glass T.25; frame lip | #8246DC / #5A2299 | Glass / SmoothPlastic | `DEC:#19`, REC |
| Plaza disc / inlay ring | lavText / pk | #CBBCF2 / #F46BC4 | SmoothPlastic / **Neon** | `DEC:#19`, `S0.5` |
| Secured / safe beacon | go | #7BFFD0 | **Neon** | `GB:58, 132` |

Pen tint-to-habitat assignment (which of the six goes where) is REC: follow habitat order 1-6 as listed.
Gloss: GUI `gloss` / `glass.fillT` (`GB:103`) have no solid analog; gloss in world = SmoothPlastic only.
Fonts: display LuckiestGuy (`GB:227`), body FredokaOne (`GB:229`); in-world label `t.beacon` 12 FO (`GB:256`).

---
## B. Part / material recipes

Parts = BaseParts, Anchored, CanTouch false (`HI:A1`). Rounded forms: Cylinder and Ball only (no MeshPart, no textures). Shared per house: banner 3, aura ring 2, porch steps 2.

### B1. Houses (35x35 slot at (0,27), tiers grow upward; `S0.3`, `PLAN:63-65`)
Every tier fits body d + 2x overhang <= 35. Only the current tier's house exists per plot (`DEC:#6, #20`). Heights PROPOSED.
| Tier | Silhouette | Body d x h | Roof / top height | Parts (est.) |
|---|---|---|---|---|
| T1 Hut | Squat round hut, huge soft dome-thatch roof (2 stacked flat cylinders + ridge cap), short chimney | 16 x 8 | overhang +4, top ~16 | body 2, base 1, roof 6, door 4, porthole 2, chimney 3, steps 2, banner 3, ring 2 = **~28** |
| T2 Villa | Fat gabled cottage body, thick gabled roof, side lean-to wing, dormer; 2 storeys | 22 x 14 | overhang +4, top ~24 | body 3, wing 3, roof 10, dormer 4, door 5, portholes 6, chimney 3, steps 2, trim 6, banner 3, ring 2 = **~50** |
| T3 Manor | Gabled body + round tower (d 9) on the slot's inner edge, bay bulge | 26 x 18, tower top ~32 | overhang +4 (34 total) | body 4, wing 4, tower 8, roofs 16, chimneys 6, door 6, portholes 8, trim 12, steps 4, banner 3, ring 2 = **~85** |
| T4 Palace | Round keep (d 24) + 2 tucked turrets (d 8 at +-13.5, extent 35), 3 banded domes, crest spire | keep 24 x 22, turrets top ~30, spire top ~40 | overhang +4 on keep (32) | keep 4, turrets 16, domes 21, bands 12, spire + gem 4, door 8, portholes 10, trim 14, steps 8, banner 3, ring 2 = **~110-140** |
No per-house cap now; the limit is the plot (937, `S0.4`). Light: 0 PointLights default; 1 at the door if used (range 22 / brightness 1.4, `HI:A1`).

### B2. Gate arch (commons, ~100 studs; `S0.2`, today towers 26x24x72 `PLAN:12`)
Keeps today's opening 150 (`PLAN:12`). PROPOSED: 2 pillars (cylinders d 10, h 25) + half-ring of radius 75 springing at y 25 -> apex **100**; arc length ~236 split into 13 rotated block segments (~18 long, section 10 x 8) + 13 Neon ctaHi inner trim segments (w 1.2) + base lips 2 + floating crest gem 1 (centre y ~108, d 6) + 2 flanking lantern pillars (globe lamp scaled x3, h ~27, 3 parts each) + name pill (billboard + Glass plaque 3 parts). = **~44 parts**, + 3 sparkle parts. 0 PointLights (today 2-3, `HI:A1` 218-220); Neon replaces them. Apex clearance vs plots 1-2 nearest the gate: check silhouettes in the P-capture (OPEN G3).

### B3. Globe lamp
Violet pole cylinder (d 0.9, h 9) 1, lip collar/foot 2, ctaHi ring 1, Neon globe Ball d 2.4 1 = **5 parts**, 0 lights. Lane-edge inset 3 (`PLAN:42`).

### B4. Pill sign (world)
Billboard per `HI:A8`: 7 instances, night2 T.15, stroke pk 1.5, r11, FO 12, MaxDistance 45, <= 12 per plot. Habitat variant (`S0.7`): same pill + Glass T.25 #8246DC plaque on a post (3 parts) behind it.

### B5. Pen + fence (per habitat)
Pad 15x12, rim 16x13 (`PLAN:58`). Tint floor 1; round posts (d 0.8, h 3.2) 6; Ball caps 4; rails (d 0.5) 3 sides, front open 4; plaque 3 = **~17 parts + 1 billboard**; x6 = 102.

### B6. Coin prop
Stand: lavText cylinder d 3 h 0.6 + lip ring = 2. Coin: gold Cylinder d 2.2 x 0.8, Neon gold.hi rim, optional T.5 halo = 3. Price pill billboard 7 instances. **~5 parts + 7 instances.** OPEN G2: token vs the six catalog props.

### B7. Flora and decor (12; each <= 8 parts; catalog maps in bold `SCH:28-35`)
| # | Type | Build | Parts | Colours (all `GB`) | Slot map |
|---|---|---|---|---|---|
| 1 | Lollipop tree | trunk + Ball canopy + 2 swirl bands | 4 | trunk lavText, canopy go2/pk, bands ctaHi | tree |
| 2 | Swirl-pop tree | trunk + 3 tilted cylinders | 5 | pk / vi / ctaHi | tree |
| 3 | Cloud tree | trunk + 3 Balls | 4 | go / go2 | **sapling** (T3) |
| 4 | Gumdrop bush | 2-3 flattened Balls | 3 | rcg tops | bush |
| 5 | Puff hedge | 4 Balls on a lip base | 5 | go2, go tips | **hedge** (T2) |
| 6 | Candy boulder | 2 flattened Balls | 2 | lavText, pinkText | **boulder** (T1) |
| 7 | Bloom bed | lip bed + 5 flower Balls on stems | 8 | stems go2, petals pk / gold / flare | **bed** (T1) |
| 8 | Mushroom puff | stem + cap Ball | 2 | pinkText cap, text stem | filler |
| 9 | Crystal gem cluster | 3 Neon tilted cylinders | 3 | flare, pk, go | filler |
| 10 | Daisy patch | 3 discs on stems | 6 | text, gold centre | filler |
| 11 | Globe lamp (B3) | B3 | 5 | A | **lantern** (T2) |
| 12 | Gem basin | lip basin + Glass water + gem | 4 | lip, flare | **basin** (T4) |
Replaces `HomeProtos` alpine clones (`HI:A5`). Flora list itself awaits owner OK (`DEC` Open).

### B8. Commons landmarks
| Landmark | Recipe | Parts (est.) |
|---|---|---|
| Notice board | lip post + Glass T.25 panel + lip frame 4 + Neon crest gem + header pill | ~9 |
| Streak shrine | 3 tiered cylinders (lavText, vi, lip) + 4 Neon pegs + flame gem | ~12 |
| Pool fountain | lip basin + coping + Glass water (flare T.25) + pedestal + Neon gem + 3 spout orbs | ~9 |
| Plaza disc | lavText disc d <= 54 + pk Neon inlay ring + lip edge ring, inside the paved square (70x56), square all lavText | 3 per plaza (`S0.5`, `PLAN:47, 237`) |
| Gate | B2 | ~44 |
| Path glow + speed lane | B9 | ~93 |

### B9. Path glow vs speed lane (same flare #7BD8FF; REC, dimensions PROPOSED)
| | Path glow (`S0.9`) | Speed lane (`S0.10`) |
|---|---|---|
| Where | every walkway incl. plot front paths | V street (z -154..294, 448 long) and H arms (x +-35..+-195) only (`PLAN:42-47`) |
| Placement (positions superseded by S1 plan §5: lane 5-8 from coping, glow 1 inside outer kerb) | **edges**: 1 line per lane at the outer kerb, inset 0.5 inside the lip | **centre** of each lane, clear of the pk inlay by >= 2 |
| Width / height | 0.6 wide, flush (0.1 proud) | 3 wide, flush (0.1 proud) |
| Pattern | **continuous**, broken only at plot entries and crossings | **dashed**: 12 on / 8 off (pitch 20), no chevrons |
| Parts | 1 per straight run: ~16 commons + 2 per plot | V 2 lanes x 22 + H 4 arm-lanes x 8 = **~77** |
| Motion | static | static until the mount ships (then mount-owned) |
Readable rule: thin + continuous + edge = "walkway"; wide + dashed + centre = "fast lane". No new token. CanCollide false, CanQuery false, no width taken from lanes 29 / 22 (`PLAN:42, 47`).

### B10. Hatchery and Training Beast (G3, pass 4 2026-10-29)
Closes `HI:G3` forms. Footprints `PLAN:64-65`; P4 scope `PLAN:134-135`. **No new token**: every colour is an existing `WorldStyle.color` key (A row / `S3` cited). Role assignment = REC; all sizes and offsets = **PROPOSED**. Coordinates plot-local, y = 0 at floor top, -Z = toward the yard. All parts plain (no unions), Anchored, CanTouch false. 0 PointLights, 0 new loops (`DEC:#18`), 0 billboards.

**Existing service markers** (`Sanctuary.luau:60-70`): `IncubatorService` / `TrainingService`, 3x2x3 at y 1, Wood + baked colours (`SANC:65-66`, violates `DEC:#4`). Keep each part as the prompt host (name + `Service` / `SanctuarySlot` attributes unchanged) but set Transparency 1, CastShadow false. Both sit inside a collider below, so the prompt needs `RequiresLineOfSight=false` or the marker moved to the y given below. Prompt keeps ActionText, ObjectText, MaxActivationDistance 12, HoldDuration .2 (`SANC:68-69`) and the `Incubate`/`Hatch` and `Train` wiring (`UIR:271-307`). The Beast prompt shows no Grip (`PLAN:135`, Q8).

**Hatchery** (dais 14x14 at (-29, 26), x -36..-22, z 19..33)
| Part | Form, size | Offset (x, y-centre, z) | Key (hex) | Material | Collide |
|---|---|---|---|---|---|
| Dais lip | Cyl d 13.4 h .5 | (-29, .25, 26) | kerb (#5A2299) | SmoothPlastic | yes |
| Dais inlay ring | Cyl d 12.4 h .75; shows as a .4 ring under the disc | (-29, .375, 26) | plazaRing (#F46BC4) | Neon | yes |
| Dais disc | Cyl d 11.6 h .8 (top .8) | (-29, .4, 26) | plazaDisc (#CBBCF2) | SmoothPlastic | yes |
| Pedestal foot | Cyl d 5 h .8 | (-29, 1.2, 26) | lip (#5A2299) | SmoothPlastic | yes |
| Pedestal column | Cyl d 3.2 h 2.4 | (-29, 2.8, 26) | vi (#A55BEA) | SmoothPlastic | yes |
| Pedestal tray | Cyl d 5.4 h .8 (top 4.8) | (-29, 4.4, 26) | lavText (#CBBCF2) | SmoothPlastic | yes |
| Egg cradle x3 (one per incubator, `UIR:277` "all three") | Cyl d 2 h .6 at r 1.5 on the tray, angles -90 (front, -Z) / 30 / 150 deg | y 5.1 | lip (#5A2299) | SmoothPlastic | no |
| Cradle status ring x3 | Cyl d 2.3 h .2, under each cradle (.15 rim shows) | y 4.9 | ctaHi (#FF8FE0) | Neon | no |
| Gem cluster x2 (`Kit.gemCluster`, B7 #9, 3 parts each) | as kit | (-34.6, 0, 31.6), (-23.4, 0, 31.6) | flare / pk / go | Neon | no |
| Prompt host | existing marker | (-29, 6, 26) if moved | — | Transparency 1 | no |
Source: dais = B8 plaza disc recipe scaled (`S0.5`); foot/column/tray = bank lip plinth + machine vi (`S3`); status Neon = machine status ctaHi (`S3`); clusters = approved B7 (`S2`). Steps .5 -> .75 -> .8 are walkable. Status ring stays static in P4; state colour switching is P7 (not in C).

**Hatch stage anchors for P7** (5 parts, all Size .2, Transparency 1, CanCollide / CanQuery / CanTouch false, CastShadow false; folder `HatchStage`)
| Anchor | CFrame (plot-local) | Attribute | Use (`HI:E`, `LAKE:36-39`) |
|---|---|---|---|
| `StageCentre` | (-29, 7, 26) | `RingRadius`=8 (`PLAN:64`) | halo, flash, confetti origin (beats 3, 6, 7) |
| `Ring1` | centre * rotX 20 deg | `Ring`=1 | orbit ring (beat 2) |
| `Ring2` | centre * rotZ -25 deg | `Ring`=2 | orbit ring |
| `Ring3` | centre * rotX 55 deg * rotY 45 deg | `Ring`=3 | orbit ring; lowest point y ~.4 (clears dais top .4 at r 8, ring is VFX only) |
| `CubeOrigin` | (-29, 5.4, 26) (tray / cradle top) | — | cube debris + egg shake (beats 1-2); P7 offsets to the hatching cradle |
Ring tilts PROPOSED. r 8 spans x -37..-21, z 18..34: inside the plot, clear of the lodge (x >= -17.5) and habitat yard (z <= 6), so nothing overlaps (`PLAN:64` allowed it as VFX). Cube pool 16/8/0 and rings per rarity stay in `Motion.luau` (`HI:F`, `LAKE:38`), not in the anchors.

**Training Beast pen** (14x14 at (29, 26), x 22..36, z 19..33; B5 geometry built with `Kit.part`, since `Kit.fence` only takes pen tints 1-6)
| Part | Form, size | Offset (x, y-centre, z) | Key (hex) | Material | Collide |
|---|---|---|---|---|---|
| Pen floor | Block 12 x .2 x 12 | (29, .1, 26) | paver (#CBBCF2) | SmoothPlastic | yes |
| Post x6 | Cyl d 1.5 h 3.2; corners +-6, gate posts x 29+-2 at z 20 (4 open, -Z) | y 1.6 | vi (#A55BEA) | SmoothPlastic | yes |
| Cap x4 | Ball d 2 on corners (extent +-7, inside 14) | y 3.6 | ctaHi (#FF8FE0) | SmoothPlastic | no |
| Rail x3 | TiltCyl d 1; back (len 12), left/right (len 12) | y 2.24 | vi (#A55BEA) | SmoothPlastic | yes |
| Beast plinth | Cyl d 7 h .8 (top 1.0) | (29, .6, 27) | lip (#5A2299) | SmoothPlastic | yes |
| Leg x4 | Cyl d 1.6 h 2 at x 29+-1.4, z 27+-1.5 | y 2.0 | vi | SmoothPlastic | no |
| Body | Ball d 5 | (29, 5.0, 26.8) | vi | SmoothPlastic | no |
| Rump | Ball d 4.4 | (29, 4.6, 28.6) | vi | SmoothPlastic | no |
| Head | Ball d 3.6 | (29, 6.8, 24.6) | vi | SmoothPlastic | no |
| Muzzle | Ball d 2.2 | (29, 6.2, 23.3) | lavText (#CBBCF2) | SmoothPlastic | no |
| Eye x2 | Ball d .7 | (29+-.75, 7.3, 23.0) | door (#2B1457) | SmoothPlastic | no |
| Horn x2 | TiltCyl d .8 len 1.8, tipped out 25 deg | (29+-1.1, 8.5, 24.8) | pinkText (#FFD0F0) | SmoothPlastic | no |
| Collar | TiltCyl d 3.8 len .5, axis along Z | (29, 6.1, 25.6) | ctaHi (#FF8FE0) | Neon | no |
| Beast collider | Block 4.6 x 8.4 x 8, Transparency 1, CanQuery true | (29, 5.2, 26.6) | — | — | yes |
| Prompt host | existing marker | (29, 10, 26) if moved | — | Transparency 1 | no |
Beast: static chunky quadruped statue facing -Z, top ~9.4 (~1.9x a 5-stud avatar, `DEC:#2`), rump 0.7 clear of the back rail, muzzle 1.9 behind the gate line. Body pieces may be unioned per colour (`S2`); the plain collider then blocks. Source: posts/rails vi = lamp pole + machine body (`DEC:#14`, `S3`); caps ctaHi = lamp ring (B3); plinth lip = bank plinth (`S3`); eyes deep = door (`S0.11`); horns pinkText (B7 #6/#8); collar Neon ctaHi = machine status (`S3`). No Grip meter, workout track or Grip sign (`PLAN:66, 135`).

**Counts vs budget** (parts + prompt; + 1-2 Model containers each)
| Item | Parts | Instances | Budget / cap (`PLAN:76`) |
|---|---|---|---|
| Hatchery | dais 3 + pedestal 3 + cradles 3 + rings 3 + clusters 6 + anchors 5 + marker 1 = 24 | ~27 | 40 / 45 |
| Beast + pen | pen 14 + beast 14 + collider 1 + marker 1 = 30 (body union: ~24) | ~33 | 60 / 65 |
| Billboards | 0 + 0 | plot stays **10** of 12 | `S0.4`, B4 |

---
## C. Motion / ambience tokens (world)

`Motion.luau` has **no world kind**; every world token below needs a new small driver (`PLAN:160`) that reuses the gates and caps, steps one Heartbeat + `BulkMoveTo` (`PLAN:160-161`).
- Caps: `CAPS={holo=1,shine=3,idle=6}` per open menu, rays 1 per token (`MOT:129`).
- Gates: `M.reduced()` = reducedMotion / simplifiedVFX / effectsTier==0 / player attrs (`MOT:144`); `M.noRays()` = effectsTier==0 (`MOT:148`); effectsTier {0,.5,1} = LOW/MED/HIGH.
- Reduce effects: loops stop, transitions <= .15 s fade or instant (`GB:508`). `DEC:#18`: only gate, globes, own crest gem and a few sparkles near the player animate.

| Token | Timing | Amplitude | Cap | Source |
|---|---|---|---|---|
| `world.gem.spin` (gate gem) | 24 s / 360 deg linear | 360 deg | 1 (rays slot) | `rays.hero` 24 s `MOT:96`; `DEC:#12`; off when `M.noRays()` |
| `world.gem.bob` (gate gem, own crest gem) | 1.2 s reversing (2.4 s cycle) | GUI y -5 px; world **REC +-0.4 stud** (OPEN G4) | gate + own plot | `MOT:101` |
| `world.sparkle` x3 at gate | 1.1 s reversing, delays 0 / .7 / 1.3 s | scale .4 -> 1, rot 0 -> 45, alpha .4 -> 1; pink, flare, pink | 3 | `MOT:109`; `DEC:#12`, `GB:216` |
| `world.globe.pulse` | .6 s reversing | scale 1.08, alpha .85 | globes within 60 studs, max 4 | `MOT:108`; 60 = `PLAN:76` analog |
| `world.crest.pulse` (own crest) | .6 s reversing | as above | 1 | `MOT:108` |
| `world.gate.arrive` | halo 1.1 s ease-out scale .4 -> 2.8, alpha 1 -> 0; shards .9 s | mint #7BFFD0 pillar flash; pink/flare burst | 1 burst; shards 8 / 4 / 0 at tier 1 / .5 / 0 | `MOT:119-120`; `DEC:#12`; sync `moment` 2.5 s `GB:474` |
| `world.tierup` swirl | 1.0 anticipation, 1.5-2.5 deconstruct, 2.5-4.5 swirl, 4.5-5.0 contract, 5.0-6.0 reconstruct, hold 6.5 | cubes lerp old rc -> new rc; T4 cycles 4 prism stops | 48 + 10 / 24 + 5 / 0; non-owners <= 50 % within 150; Reduce = .15 s crossfade | `DEC:#6`; `PLAN:160, 76`, `HI:D` |
| `world.aura` ring | static, alpha 1 -> .6 once on arrival | | 0 loops | REC |
| `world.far` | all off beyond 60 studs; non-owner plots static | | | `DEC:#18, #20`, `PLAN:76` |
Gate loop count in range: spin 1 + bob 1 + sparkles 3 + 2 lantern pulses = 7 vs idle cap 6 (`MOT:129`). REC: fold the 2 lantern pulses into one shared tween -> 6. Whether the menu idle cap governs the world is OPEN (G4).

---
## D. Perf budget (est. unless cited)

Limits: per plot **<= 937** incl. creatures and billboards (`S0.4`, 750 x 1.25), commons <= 1,500, draw calls <= 700, billboards <= 12 per plot MaxDistance 45, net place <= 15,812 + 4,000 (`PLAN:76, 230`; `HI:F`).
| Plot item | `PLAN:76` today | Restyle est. |
|---|---|---|
| Habitats (6) | 80 | 102 (B5) |
| Creatures | 150 | 150 |
| Spine / bank / machines | 40 | 40 (unrestyled, OPEN G5) |
| Hatchery | 40 | ~27 (B10) |
| Training Beast | 60 | ~33 (B10) |
| Decor 14 slots | 110 | ~98 |
| House | 126 (lodge) | 28 / 50 / 85 / <=140 |
| Banner + aura ring | 0 | 5 |
| Frame / walls / garden | 80 | 80 |
| Globe lamps (4) | in frame | 20 |
| Path glow (B9) | 0 | 2 |
| Billboards (10) | 60 | 70 |
| **Total (Palace)** | **746** | **~765** (B10 -40), headroom ~170 under 937 |
Commons: gate 44 + sparkles 3 + board 9 + shrine 12 + fountain 9 + plaza discs (4) 12 + speed lane ~77 + path glow ~16 = **~182** + commons lamps (count TBD, 5 each), inside 1,500. Lights: 0 default, <= 1 per house. Neon glow needs bloom, which the MCP cannot read: verify on the phone/emulator (G6).

---
## E. Mountain prop restyle map — PROVISIONAL, needs a live Studio audit before S9

From current source (`mountain/world/*.luau`), not Studio. The six-kingdom MountainQuality world has **no** RouteKit camps, lodges, 120 route lanterns or fence runs (older V3 build; dropped). Rule (`DEC:#21`): restyle colour/material of decorative parts only; keep Size, CFrame, CanCollide, CanQuery of anything on the player path.
| Source prop | Today | Restyle | Tokens | Status |
|---|---|---|---|---|
| `EntranceLantern` posts (3x14x3, both sides) | `green` rgb(153,234,182) (`ME:21, 76`) | globe-lamp look: vi post, Neon warm globe on top (no size change) | vi, #FFDD9B | REC |
| `SafeReturnLine` (Neon, 48x.15x2) | `green` Neon (`ME:74`) | Neon go — "safe" semantics | go #7BFFD0 | REC, `GB:58, 132` |
| Entrance `Wayfinder` posts (3x12x3) | `green` (`ME:80`) | lip post + pill sign billboard | lip, B4 | REC |
| `GateFlankUpper` parts | adjusted in place (`ME:37`) | vi body, Neon ctaHi trim | vi, ctaHi | REC; geometry untouched |
| Route `Wayfinder` posts (.6x4x.6, Wood, kingdom rock) (`WD:102`) | kingdom rock colour | **keep** unless audit shows they are decor only; they read as kingdom route language | | OPEN |
| `SectionWayfinder` (FreeClimb, Marble accent) | kingdom accent | same as above | | OPEN |
| `_Signature` models, one per kingdom (`LM:4`) | kingdom art | **out of scope** by default (landmark identity, kingdom palette) | | OPEN — owner call |
| `ClimbingRope` links (`WD:98`), `TraversalArt` rope ladders + labels | functional | **off-limits** (traversal) | | — |
Not restyled: terrain, kingdom planting (`MountainQuality`, `Polish`), routes, collision.

---
## F. Closed in pass 3
| # | Item | Closed by |
|---|---|---|
| F1 | Rank colour | `S0.1` 4 bands (A) |
| F2 | Tier names | `S0.8` Hut / Villa / Manor / Palace |
| F3 | Gate height | `S0.2` ~100 (B2) |
| F4 | House footprint | `S0.3` 35x35 slot, grow upward (B1) |
| F5 | Perf cap | `S0.4` 937 per plot (D) |
| F6 | Plaza | `S0.5` disc in the lilac square (B8) |
| F7 | Pen pastels | `S0.6` (A) |
| F8 | Path glow, speed lane, door, roof | `S0.9-S0.12` (A, B9) |
| F9 | Habitat sign | `S0.7` (B4) |
| F16 | Speed-lane width vs lanes | B9: strips only, no lane width taken |
| F14 | Mountain prop list | partly: E rebuilt from source; live audit still required (G7) |

## G. Still OPEN
| # | Item | Evidence |
|---|---|---|
| G1 | Pink globe tint #F78AD0 vs warm only; porthole rim, gate body/trim/idle gem, banner pole, chimney gem, shrine flame, board frame, coin pill stroke are still REC | `DEC:#14`; A |
| G2 | "Coin props": gold token vs the six catalog props (was F11) | `DEC:#17` |
| G3 | Gate apex (100) vs plots 1-2 silhouette; B2 proportions PROPOSED | `S0.2`, `PLAN:12` |
| G4 | World bob in studs, 60-stud cutoff, and whether the menu idle cap 6 governs the world (was F12) | `MOT:101, 129` |
| G5 | Spine / bank / machines not restyled | `PLAN:60-62` |
| G6 | Neon glow needs bloom (unreadable via MCP); fallback T.5 halo Ball (was F13) | CLAUDE.md gotcha |
| G7 | E is provisional: live Studio audit of mountain decor before S9; `_Signature` and route wayfinders scope | `DEC:#21` |
| G8 | Non-uniform Ball / unions for soft bevels; union colliders become invisible walls (was F10) | `DEC:#2, #4` |
| G9 | Aura ring r 19 vs 35x35 slot and hatchery at x >= 22 (was F15) | `PLAN:63-65` |
| G10 | Rank coin multiplier numbers + STOP before code (was F17) | `DEC:#9` |
| G11 | Terrain Grass beside the #2FAE8A lawn slab may clash; terrain out of scope | `HI:A1`, `DEC:#21` |
| G12 | Flora/decor list (B7) awaits owner OK | `DEC` Open |
| G13 | Hatchery / Training Beast forms (`HI:G3`) | **CLOSED 2026-10-29 (owner):** (a) candy statue, (b) eggs shown on cradles in P4, (c) keep vi. Was open: (a) Beast = violet candy statue vs a roster creature model; (b) show incubating eggs on the 3 cradles in P4 (needs egg models) or empty cradles until P7; (c) Beast vi body sits in the gate/lamp/machine violet family, OK or use another existing key. Hatch ring / halo colours = P7 atlas row |
