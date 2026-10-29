# V3 Ascent plan — taller mountain, 4 routes, hazards, checkpoints (written 2026-10-20, APPROVED 2026-10-20; P0–P3, P4a, P5 built as first drafts — see `design/v3-morning-report.md`)

Supersedes the unbuilt P3–P5 of `design/traversal-plan.md`. Reuses its tooling (see "Reuse"). Nothing here is built yet. All numbers are ESTIMATES/PROPOSED until measured. **LOCKED** = chosen by the user in the 2026-10-20 interview. **PROPOSED** = my derived detail.

## 1. Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Keep Ring Mountain + 5 named regions. Unique summit crown/spire (buttresses, fins, arch or notch) and taller, more dramatic massifs around it | LOCKED |
| 2 | Dry foothills band under Green Valley (scrub, dry grass, red-brown earth) where Foothold sits, then lush valley → forest → cliffs → ridge → snow/ice | LOCKED |
| 3 | Summit height **~3,200** (was 2,000). Playable footprint grows to suit; map size PROPOSED ~5,600×5,600 | LOCKED (height) / PROPOSED (footprint) |
| 4 | **4 routes**, each a fixed intensity; exposure and hazards also rise with altitude on every route. Easy route beginner-safe all the way; hard routes scary from the first third | LOCKED |
| 5 | Topology: routes **separate at the base, cross at the shared camps, merge near the summit** | LOCKED |
| 6 | All routes land in **25–30 min skilled** (hard routes shorter in walking but riskier). First-time ~60 min is measured on the easy route; hard-route novice time is not a target | LOCKED |
| 7 | Fall/hit cost: **stagger + fall-loss, no HP damage.** Fall = respawn at last checkpoint of that route; only unbanked cargo is at risk (LOCKED loss rule). No cargo exists yet, so for now a fall costs only the return walk | LOCKED |
| 8 | Checkpoints: 4 shared camps (full hubs) + a mini-checkpoint about every ~4 min of climbing per route (respawn only). Falls respawn at the last one reached **on that route** | LOCKED |
| 9 | Hazards: falling trees, rockfall, wind gusts, avalanche chutes. Crumbling ledges NOT chosen (parked, may revisit) | LOCKED |
| 10 | Punishment scales by route: easy = block/knock back, 3 s tells, no cargo loss; hard = knocked off to the previous catch point, 2 s tells, cargo risk applies; hardest = overlapping hazards at altitude | LOCKED |
| 11 | Foothold ~3× area, open plaza, **4 route gates** around it. Standouts: Route Board (relief model + gates), summit-view amphitheater spawn, landmark tower/waterfall mill, cable-car station | LOCKED |
| 12 | Cable car: **decorative landmark only** (station + visible cable toward Camp 1). Riding it up would break the downhill-only extraction rule; any function is OPEN | PROPOSED |
| 13 | Mobile first: prioritize best performance and best quality on mobile. Concrete budget (PROPOSED): 30 FPS floor on a mid-range phone, 60 on desktop | LOCKED (priority) / PROPOSED (numbers) |
| 14 | Guaranteed introductory Rare sits in a hidden nook on the first stretch of the easy route, also reachable from the base. Beginner protection (no cargo loss until the first Rare is banked) applies on every route. Hard routes are optional, marked with a warning sign | LOCKED |
| 15 | Full terrain regen OK. Take a checkpoint of the current build first | LOCKED |

### The 4 routes (PROPOSED character, names follow your suggestion minus Ancient Root Way)

| Route | Intensity | Character | Walk length / skilled time (ESTIMATE) | Hazards |
|---|---|---|---|---|
| **Shepherd's Road** | 2/10, forgiving to the summit | Wide switchbacking trail, fences, flowers, lanterns; widest margins even at altitude; the beginner/first-ascent route | ~19k studs walk (≈26 min) + ~2 min easy segments | Tree-fall (forest), light rockfall, mild gusts; long tells, knockback only |
| **Waterfall Stair** | 5/10 | Stone stairs and boardwalks climbing beside the falls and ancient forest ruins; the enchanted tree, root climbs, bounce caps | ~14k walk (≈19 min) + ~8 min segments | Tree-fall, rockfall gully, gusts; hits can knock you down one section |
| **Cliff Ledge Line** | 8/10 | Narrow 3–4 stud ledges hung off the mountainside, plank gaps, rope handrails, exposed drop on one side from the first third | ~11k walk (≈15 min) + ~12 min of gaps/hazard waits | Rockfall lanes, gusts that push toward the edge, avalanche chutes at altitude |
| **Spire Ridge** | 10/10, expert | Knife-edge ridge and rock fins toward the spire, ice footing at the top | ~9k walk (≈12.5 min) + ~15 min of obstacles/waits | All four, overlapping at altitude |

Intensity formula (PROPOSED): `exposure(route, y) = routeBase + altitudeRamp(y)`, capped at 10. Easy route's cap is lower (≈5) so it never becomes a hard route at altitude. Walk length uses the 12 studs/s pace; segment time uses the P1/P2 bot-measured model (a segment adds a few seconds when skilled, hazard waits add the rest).

Camps (PROPOSED): same 4 camps + summit, re-spaced on the taller mountain at roughly 15/32/50/70/100% of height; every route passes or touches each camp, and a camp is where players may switch routes. Routes **merge on the final approach** into the summit crown. Ring trails and caves/hidden region (Glacier Caves / Sky Garden) stay in the plan but are out of this scope.

## 2. Conflicts with LOCKED items and how they are handled

1. **"Early segments stay forgiving" / §6 "forgiving early failures" vs "hard routes scary from the first third".** Resolved by decision 4/14: forgiveness lives in the easy route; hard routes are optional, marked, and carry the beginner protection exception. If you want hard routes to be selectable only after one summit, say so (OPEN).
2. **Guaranteed Rare within 5 minutes.** Decision 14 resolves it. §8's older "guided ascent into the forest" is replaced by "first stretch of Shepherd's Road".
3. **25–30 min skilled with a 60% taller mountain.** Only holds if walk length rises ~0 on hard routes and the easy route spends its time on a long gentle road. Phase P2 measures this on the new terrain before anything is built on it. If a route can't hit the band, I will say so rather than stretch it.
4. **"Same route can be taken up or down" (§4).** Hanging ledges and chutes must stay traversable downward; ledge sections will be designed two-way. Hazards fire both ways.
5. **"No sudden undodgeable loss" (§6).** All hazards get a ≥2 s tell with sound off, a dodge/shelter position, and a fixed learnable cycle.
6. **Green Valley as "hub/base perimeter at lowest elevation" (§4).** The foothills band now sits below it; Foothold moves into the foothills. Green Valley keeps its mood, waterfall settlement and first overlook. Needs your sign-off when you read this.
7. **Design values.** The new foothills/dry biome needs colors. `references/` is still empty and `master.md` §3 has no dry-ground palette. Per your global rule I will not invent one: **I need one reference image (or your color words) for the dry foothills before P1 terrain materials**. Also still no warning color for hazard tells; tells use motion/particles in existing tokens.

## 3. Reuse vs. rebuild

- **Reuse:** `TraverseKit` builders (climb frame, bounce cap, kerbed gully, stones), `Ctx:gorge`/`Ctx:kerb` cut logic and its 6 gotchas, `MountainGen` voxel writer and surface offset fix, bot tools (`measure_bot`, `push_bot`), checksum method, region dressing rules (`ValleyDress`/`RegionDress`), `Kit` props and CSG prototypes, `LightingSetup`, `BuildAll` stepping, player settings (WalkSpeed 12, MaxSlope 45).
- **Rebuild:** `MountainGen` heightfield/profile and path generation, camp/feature pads, `SliceBuild`/`ForestBuild`/`CliffBuild`/`HighBuild`/`FootholdBuild` placements, `TraverseP1`/`P2` re-placed along the new routes and **re-measured** (P1/P2 bot times become the baseline models, not carried-over numbers).
- **New:** `RouteNet` (4 route paths, merge points, checkpoint list as data), `HazardKit` + server hazard Script and client gust/knockback LocalScript, `CheckpointService` (server respawn rule per route), `FootholdV3`, `TrailStyle` (route-specific shoulders, ledges, rope rails).

## 4. Phased plan and checklist

Every phase: rebuild in order → checksum src vs Studio → playtest → screenshots in `evidence/v3_P<n>/` (rejected kept with `9x_`) → checkpoint `V3_P<n>_<date>` → save. **Mandatory stops for your approval: after P1 (silhouette and biome look) and after P4a (Shepherd's Road complete) before the other three routes are built.**

### P0 — Safety and baseline (small)
- Checkpoint `PreV3_2026-10-20` in `ServerStorage.CC_Checkpoints` and a file copy `ClimbAndCollect.PreV3.rbxl` (name PROPOSED). Log the P2 row in CLAUDE.md (only P1 is logged there now).
- Record current budgets: instance count and streamed instances at 3 spots (baseline for mobile budget).
- **Accept:** checkpoint exists, file copy opens, baseline numbers recorded. **Method:** inspect ServerStorage; `Stats` counts via `execute_luau`.

### P1 — Terrain v3: silhouette + biome bands
- New radial/angular height model to ~3,200: spire crown with buttresses, fins, an arch or notch; taller massifs around it; dry foothills → Green Valley → forest → cliffs → ridge → snow/ice material bands by altitude and slope. Gullies and cuts only where routes need them (done later).
- **Accept:** (a) summit y 3,150–3,250; (b) silhouette from Foothold, a valley overlook, and an aerial reads as unique (crown has ≥3 distinct features: buttress, fin, arch/notch); (c) biome progression readable by color alone from the aerial; (d) terrain memory/instance count within the P0 baseline ×1.6; (e) no floating voxels, no void under the shell (§gotchas). **Method:** raycast height sampling over a grid; 3 named screenshots; Stats numbers. **Self-review vs. master.md §3 and the dry-foothill reference.** STOP for approval.

### P2 — Route network on the new terrain (data only, no art)
- `RouteNet`: 4 route paths with merge points, camp pads, checkpoint positions (one per ~4 min of the route's own skilled time), catch points; ring trails retained from the old model where reusable.
- **Accept:** per-route skilled time ESTIMATE (walk length ÷ 12 + segment model) in 25–30 min; no grade over 45° on the walk sections of Shepherd's Road (<25° mean); every route checkpoint spacing 3–5 min; routes meet at the 4 camps and merge before the crown; each route visible from the base. **Method:** generator output table; `push_bot` on the walk sections only. If any route can't hit the band, report and ask.

### P3 — Foothold v3 (home base)
- ~3× area on the dry foothills: summit-view amphitheater spawn, central plaza, Route Board relief model, 4 trailhead gates styled to route, landmark tower/waterfall mill, cable-car station (decorative), Hall of Wonders, Gear Forge, Market, Garage + ATV start, Base Pad, Hatchery, cabin terraces.
- **Accept:** spawn camera frames the summit + at least 2 gates; all 4 gates identifiable by silhouette; plaza ≥3× old footprint; every service reachable on foot ≤60 s from spawn; no collision snags walking the plaza at avatar scale; instance budget for the base stated and within the mobile budget. **Method:** screenshots at avatar scale and aerial; `push_bot` spawn→each gate; Stats.

### P4 — Routes, one at a time (4a, 4b, 4c, 4d)
Order: **4a Shepherd's Road → STOP → 4b Waterfall Stair → 4c Cliff Ledge Line → 4d Spire Ridge.** Each: trail carving and style (shoulders, stairs, ledges, rope rails), the camp links, checkpoints with respawn markers, route sign/difficulty marker, route-specific segments (reusing P1/P2 TraverseKit verbs; new verbs: ledge walk, plank gap, fin walk, ice ledge).
- **Accept per route:** bot run completes start→summit (perfect input) with times logged per push; skilled ESTIMATE 25–30 min; every segment has a catch/return and worst-case return walk ≤ the route's checkpoint spacing; ledge width (hard routes) 3–4 studs, gaps ≤ 4.5 studs (P3–P4 rule) / ≤ 5 (upper) at WalkSpeed 12; no free bypass found by sampling ±36 studs; easy route has no gap > 3 and no drop that can leave the route. **Method:** `push_bot`, terrain profiles, screenshots, checkpoint respawn tested by forcing a fall.

### P5 — Hazards and checkpoint runtime
- `HazardKit` + server Script (trees, rockfall, avalanche) and client LocalScript (gust, knockback); `CheckpointService`.
- **Accept:** each hazard has ≥2 s tell (hard) / 3 s (easy) readable with sound off, fixed cycle, a dodge position, hit = stagger/knockback per decision 10; hazards inactive beyond ~250 studs of any player (server cost); active hazard count ≤ budget (PROPOSED: ≤12 simultaneous cycles per server region); falling off any route respawns at the last reached checkpoint of that route, camps respawn all routes; simulated multi-client (2 clients) does not duplicate events. **Method:** playtest with bots; server tick time and script activity (MicroProfiler/`Stats`); logs.

### P6 — Art and mobile pass
- Biome dressing on new terrain (dry scrub/grass, lush, forest, cliff, ridge, snow), trail style polish, lighting/fog per biome, route-colored wayfinding (gold rope per your fixed-rope rule), summit glimpses re-audited (route sightline check as in the morning report).
- **Accept:** each region passes master.md §3 self-review with screenshots at avatar scale and phone aspect; glimpse sampling per route reported; mobile budget (decision 13) measured: Studio mobile emulation FPS/frame time at 6 reference viewpoints (spawn, Camp 1, forest, ledge route, ridge, summit), instance counts streamed, memory. **Honest limit:** Studio emulation is not a device; real mid-range phone numbers need your phone, so those stay UNVERIFIED until you run it.

### P7 — Verification and report
- Re-measure all 4 routes end to end (bot times, labeled as bot times), the P1/P2 re-measure, checkpoint/hazard tests, perf table; update CLAUDE.md log and master.md; list gaps. STOP for review.

## 5. Risks (honest)
- Taller terrain + 4 routes + hazards raises instance/streaming load; mobile may force fewer trees/props, so we budget in P1 and re-check each phase.
- Bot times are perfect-input times; skilled-human and novice times need your runs.
- Expert routes in a 30-min band means mostly obstacle time, so tuning will iterate.
- Hanging-ledge physics (MaxSlope 45, voxel edge quantization ±2 studs) needs part-built ledges, not terrain edges.
- Terrain regen invalidates all placements; every module is re-run in order.

## 6. Still OPEN (will ask when reached, not now)
Cable-car function, whether hard routes are selectable only after a summit, the dry-foothill palette source, mini-checkpoint art, map footprint, hidden-region placement on the new mountain, whether Root Way content (enchanted tree, root climbs) lives on Waterfall Stair as proposed.
