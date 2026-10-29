# v5 trails + mountain plan (interview 2026-10-21, rounds 1-2) — AWAITING APPROVAL, nothing built

Sources: user interview (round 1 in the launch prompt, round 2 here), `master.md` §0.6-0.8, `design/v4-*.md`, `design/references-intel.md`. Design values come from `references/` only; no palettes invented here. Another chat is rebuilding: **no world files touched.**
Legend: LOCKED = user answer · PROPOSED = my detail · OPEN = needs a decision.

## Audit notes
- `creatures/roster.json` and `src/core/shared/SpeciesRoster.luau` **do not exist yet** (Codex roster not delivered); only `Species.luau` stubs and `tools/roster_to_luau.py`. Jackpot tiers (phase 3) build on the stubs/id table.
- Code uses rarity names Common/Uncommon/Rare/Epic/**Legendary**; v5 renames the top tier to **Mythic** (touches `CoreConfig`, UI, saved-profile mapping).
- K2 public info is thin (true-scale terrain, long camp gaps, fixed ladders/ropes, route lights); the `references/` clips are the real source.

## Decisions ledger
**LOCKED**
1. Trails rebuilt natural, tense, suspenseful; **no straight switchbacks**; 4 routes kept, each distinct. ~85 % tight (2-5 stud, hugging walls/ledges/ridges), ~15 % open (camps, a few viewpoints). Narrow types: knife ridges/spines, ledges/wall paths, slot canyons/chimneys/cave tunnels, log/plank/rope bridges/stepping stones.
2. Terrain: re-carve around new route splines; keep base massif (silhouette, biomes, camps region, Foothold).
3. Route signatures: **Shepherd** = mix of gully with log/stone crossings and shepherd ledges + rope bridges (easy: wall on one side; **no rails**, user 2026-10-21, falls cost progress). **Waterfall** = wet slot canyon/falls ledges mixed with root arches + ruin bridges (moderate). **Ledge Line** = wall-hugging ledges + plank/rope gaps (hard). **Spire Ridge** = knife ridge + arch + ice spines (expert).
4. Time: **25-30 min skilled per route, Shepherd ~60 min first-time** (route length shrinks to compensate for slower tight play).
5. Fall rules: **same on all routes** (slip → catch window → fall to last checkpoint; no HP damage).
6. Hazards **sparse and fair**: ~1 per 60-90 s of path, ≥2 s tell, none on rest ledges. Types: rockfall lane, gusts, loose stone, thin ice (upper only).
7. Topology: separate at base, **cross at the 4 camps**, merge below the summit stair; **one-way rope descents** as shortcuts down.
8. Co-op: friend pull-up with rope; ping warnings (rockfall, thin ice, gusts).
9. Spawn silhouette: **single dominant crown with arch notch**, flanking horns, buttress ridges, haze layers in front, summit clear above haze. Features: **rock arch near crown, tall waterfall down the face, cave mouths + ancient ruins on flanks.** (Glacier/ice spires not chosen as separate features; Spire route still uses ice footing at top.)
10. Fog: clear summit view from spawn through light haze; fog thickens with height, **heavy mid-mountain right up to the last ~8 % (≥ ~2,950 of 3,200)**, which breaks clear above a **cloud sea** with harsh light + wind = the viral screenshot moment.
11. Mobile: authored instances at any spot ≤ current streamed baseline +15 %; merge props into unions; 30 FPS floor mid-range phone; fog via Atmosphere, no per-particle fog.
12. **Fixed:** tutorial beats, Rare nook, hollow nest, lip nest (trail between them may change). **Foothold + 4 gates stay; camps may shift along routes** (resume/checkpoint data remapped).
13. Jackpot (phase 3): rare nests/eggs spawn randomly (can skip rounds or chain), server-wide announcement + glow beacon; 5 tiers Common/Uncommon/Rare/Epic/Mythic; starting odds Mythic ~1/500, Epic ~1/60, Rare ~1/12 per nest roll, one tunable config table; Heartstone size/shape/glow scale with tier, per-creature shell pattern, Mythic massive with particles + light beam.
14. Build order: 1 Trails → 2 Mountain look + fog → 3 Jackpot + Heartstone tiers.

**PROPOSED**
- Fall threshold (one rule set): drop < ~15 studs onto a ledge = stagger; otherwise slide with ~1.5 s catch window; miss = last checkpoint. (Matches v4; to be tuned by bot + your runs.)
- Hazard mix: Shepherd = tree-fall + loose stone + light gusts; Waterfall = slippery ledge (longer slide), spray, rockfall in slots; Ledge = rockfall lanes, edge gusts, timed avalanche crossings high up; Spire = crosswind, thin ice, overlaps only near the top.
- Fog bands (of 3,200): thin to ~25 %, thickening 25-35 %, heavy 35-92 %, clear above ~92 %; cloud-sea top ~2,900-2,950. Exact densities set from references (img2 haze, old_c/old_e cloud sea) in phase 2.
- Heartstone visual per tier from existing tier tints (`CoreConfig.RARITY_TINT`) + shape/size/glow scale; new Mythic tint needs a reference or your word (OPEN-3).
- Rare-nest event: server rolls per nest respawn; announcement text/beacon colour by tier; Mythic beacon visible server-wide.

**OPEN**
1. Waterfall/Shepherd cave tunnels: dark interiors vs mobile cost; how many (suggest 1-2 per route).
2. Does the Mythic rename change yield/hatch tables (currently Legendary 150/h, 8 species)? And do all 5 tiers get world beacons (LOCKED earlier: only top tier)?
3. Mythic/Epic Heartstone colours and shell patterns (needs a `references/` image or your color words; none invented).
4. Zipline/rope-descent rules (carry cargo? cooldown?).
5. Real phone numbers (still emulation only).

## Round 3 (2026-10-21): feature sections (interview; AWAITING APPROVAL, nothing built)
Tags: OBSERVED = visible in the file; INFERRED = my reading. Colours/materials come from `references-intel.md` only; none invented.

### Feature-section table (LOCKED set = Core 8 + cloud-sea dome; night ridge joins in P7)
| # | Section | Reference | Route (count) | Altitude | Beat | Key elements (OBSERVED unless marked) |
|---|---|---|---|---|---|---|
| 1 | Log-over-Pond + pavilion rest | img5 | Shepherd ×1; Waterfall base pool ×1 | 5-15 % | calm / rest | mossy log ~1-1.5 avatar widths, shallow clear water (no drop), boulder steps, stilt pavilion |
| 2 | Mossy Cleft | img3 | Shepherd ×2; Waterfall slot tail ×1 | 10-35 % | enclosed, release | dirt strip 2-3 widths between mossy boulders, upright slabs partly blocking the line, no drop, tiny sky gap |
| 3 | Boulder Stair, twin ladders | img2 | Ledge ×1; Shepherd ×1 (fog-first) | 30-55 % | fog hides the drop | faceted block stack, plain ladder + rope ladder to one block, tan fog |
| 4 | Knife Ridge + Arch | img1 | Spire ×2 (low spur, crown approach); Ledge ×1 short | 55-85 % | peak tension | ridge top ~2 widths, sheer dark faces, natural arch in crest, peak dead ahead, light shafts + layered haze |
| 5 | Ladder Face, rope rails | img4 | Ledge ×2; Spire ×1; Waterfall upper ×1 (ice) | 60-88 % | tall climb | metal ladder + rope rails on snowy rock, orange rope arcs, wind-sculpted snow lip, overcast |
| 6 | Fixed-rope slope (lane) | new_v1, new_v2, old_b | Spire ×1; Ledge ×1 | 75-92 % | exposure | fixed orange rope, black rock ribs in snow, top-down camera; width reduced to a 3-5 stud lane (INFERRED adaptation; clips show open slopes) |
| 7 | Crevasse ladder | old_a f10 | Spire ×1; Waterfall ice groove ×1 | 70-90 % | ladder in ice | ladder against an ice wall; that it crosses a gap is INFERRED |
| 8 | Whiteout traverse | old_d, new_v2 f7-9, new_v3 f4 | Spire ×1; Ledge upper ×1 | 80-92 % | visibility only | whiteout grey, big flake sprites, rope-guided |
| 9 | Night/headlamp ridge | new_v2 f2, new_v3 f6 | added in P7 with the cycle | – | – | near-black, headlamp cone |
| 10 | Cloud-sea summit dome | old_c, old_e | merged summit stair | above 92 % | reveal | dome, cloud sea, harsh sun halo, multiple ropes, summit flags |

Per route: **6-7 set pieces** (~12-15 min), connected by tight spline trail. Shepherd stays gentle (sections 1, 2, one fog Boulder Stair, plus the locked railed ledges / rope bridges). Ladders and ropes never carry the whole route (INFERRED from references: connectors).

### Route sequences (C calm, T tension, R release; one wave per ~4 min rest)
- **Shepherd:** Pond (C) → Cleft (T) → railed ledge → Cleft (R) → rope bridge → Boulder Stair in fog (T) → merge.
- **Waterfall:** Pond → wet slot → Cleft tail → root/ruin bridge → Ladder Face (ice) → Crevasse ladder → merge.
- **Ledge:** Boulder Stair → plank gap → Ladder Face → short Knife Ridge → rope lane → tall Ladder Face → Whiteout → merge.
- **Spire:** Knife spur → ridge + arch → ice spines → Crevasse ladder → rope lane → Ladder Face → crown Knife Ridge → merge.
- Two **fog tears** per route (~45 % and ~75 %), right after a release beat, crown dead-centre as in img1. **Cloud-sea reveal:** fog peaks ~85-92 %; the last fixed ladder/rope climb (~20-30 s) exits into clear air, cloud sea, dome and flags.

### Round 3 decisions
**LOCKED**
15. Section set = Core 8 + cloud-sea dome; assignment = signature-owned (table); 6-7 set pieces per route.
16. Fixed-rope slope = roped lane 3-5 studs (keeps the 85 % tight rule).
17. Fog is allowed to hide the drop, but **the walkable line is always cued** (rope/flags/lit rock).
18. Rests: ~4 min apart; tent/pavilion refill stamina + checkpoint; cairn = checkpoint only; camps are the big rests. Pavilion low band only (img5); tents mid/high (new_v3 f4, old_a f3).
19. Ladders/ropes **pre-built and fixed**; ladders two-way, rope descents one-way shortcuts; usual 8-14 studs, one 30-40 stud per route; slip uses the locked fall rule (catch window, miss → last checkpoint). Co-op stays pull-up + pings.
20. Atmosphere: full effects on desktop, **auto-tiered down on mobile** (+15 % instance cap and 30 FPS floor stay binding, measured in P9). Light shafts, tan fog, flat overcast, spindrift/flake sprites per section as in the table.
21. Readability cues: orange fixed rope, small coloured flags (both OBSERVED), plus **cairns / glow cues (user-approved; NOT in references)**.
22. Art identity: **references-only colour supersedes master.md §1 "Enchanted Adventure" + C+D mood** (user confirmed). Atlas derives the palette from `references/`; no invented magical glow. §1 text itself not yet edited, see OPEN-6.
23. Day/night: **full cycle, phased into P7 with fog**; the night ridge ships then. Trails P1-P5 are built day-lit with headlamp-safe tells. Clock = **per-player** (user choice).
24. Exclusions: no chat, leaderboard, name tags, oxygen toggle, Points shop, quest NPC, avatar gear/outfits, Spanish text, handles/watermarks, "K2/14PEAKS" branding. Keep the altitude track with camp ticks (img2).
25. Wow views: two fog tears per route + camps; cloud-sea reveal via the last fixed climb out of fog.

**PROPOSED**
- Whiteout traverse = fixed local fog+flake zone with a rope lane (my default; user chose a full cycle, so a weather event layer can come later).
- Pavilion: wood, low band only (img5); Waterfall base pool reuses the log crossing.
- Cairn/glow cues use the rope/flag colours from `references-intel.md` §4, no new hues.

**OPEN**
1. Per-player clock side effects: co-op parties can see different light; jackpot beacon/announcement must be readable in any phase. Need: sync parties? cycle length? (my earlier recommendation was one server clock.)
2. Cycle length and night difficulty (visibility floor, headlamp item?).
3. Master §1 text edit (Enchanted Adventure / C+D) and the Foothold/lower-zone look under the new rule: needs Atlas pass on `references/` before any colour is set; low band references are only img3/img5.
4. Crevasse ladder: real gap crossing vs wall climb (the reference shows only the wall).
5. Cairn/glow cue look (no reference): needs your word or a new reference.
6. Whether Mythic/rarity beacon rules interact with night (visibility).
7. Phone numbers still emulation only.

## Phased plan (each phase: checkpoint + file copy, src↔Studio checksum, playtest, evidence `evidence/v5_P<n>/`, then STOP)
- **P0 Safety:** checkpoint `PreV5`, baseline streamed-instance counts at 6 spots (the +15 % budget), confirm the other rebuild chat's state.
- **P1 Spline route kit:** `RouteSpline` data (3D curves with width/exposure/type per segment) replacing switchback generation; carve + ledge/ridge/slot builders; checkpoint remap; tooling bots reuse climb controller. Prototype = one 60-90 s section per route type (ledge, ridge, slot, bridge).
- **P2 Shepherd** (tutorial pieces pinned) → **P3 Waterfall** → **P4 Ledge** → **P5 Spire**; camps nudged to spline ledges; crossings at camps; rope-descent shortcuts; hazards + pings; co-op pull-up.
- **P6 Mountain look:** sharpen crown + arch notch, waterfall down the face, caves/ruins; spawn-view check.
- **P7 Fog/cloud sea:** altitude fog bands, cloud sea, summit light/wind; measured mobile cost.
- **P8 Jackpot + Heartstone tiers:** Mythic rename, rarity config table, nest roller + announcement + beacon, tier visuals; creature roster integration when Codex delivers.
- **P9 Mobile pass + verification report.**

## Acceptance checks
(Offline gate for checks 1 and 4: `python tools/spline_audit.py routes.json`, added 2026-10-21; works on spline data before anything is carved. Tested on a synthetic sample only.)
1. Each route: ≥ 80 % of path length ≤ 5 studs wide (measured from spline data + ±36-stud profiles), open ground ≤ 15 %, no straight run > ~60 studs in a row on a switchback pattern.
2. Bot run per route 25-30 min skilled ESTIMATE (labelled BOT), 0 stuck; no free bypass in ±36-stud profiles.
3. Fall chain verified (stagger, catch, miss → checkpoint) on every narrow type.
4. Hazards: spacing 60-90 s, tell ≥ 2 s, none on rest ledges (data check).
5. Tutorial regression: `tutorial_bot` + B checks 12/12 + A1 12/12 still pass.
6. Perf: streamed instances ≤ baseline +15 % at 6 spots; 60 FPS desktop; emulation numbers labelled as emulation.
7. Spawn screenshot shows crown, arch notch, waterfall, haze; summit-break screenshot above cloud sea at avatar scale + phone aspect.
8. Jackpot: 100k-roll simulation matches configured odds within tolerance; announcement + beacon seen by a second client.

## UI round (2026-10-21, awaiting approval, nothing built)
See `design/v5-ui-plan.md` (+ `design/references-ui-index.md`, `design/ui-intel.md`). Client-only UI phases U0-U3 proposed beside P1-P9; OPEN risk R1 (shop/gear/Points/O2 UI vs Round 3 exclusions), typeface, per-screen colour mix.
