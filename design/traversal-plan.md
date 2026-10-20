# Traversal plan — closing the route-time gap (APPROVED 2026-10-20, with amendments)

> **Amendments after approval (user-approved, 2026-10-20).** A measured playtest showed native climbing at 11.2 studs/s and skilled obby runs at close to walking speed, so the per-segment "Added" times below were too high. Realistically each segment adds about 3–20 s for a skilled player. Fixes: WalkSpeed 16 → 12 (pure walking ≈ 23.5 min) and slope limit 89° → 45°. At WalkSpeed 12 the maximum jump is ≈ 6.5 studs long and 7.2 high, so gaps are capped at **3 studs in P1–P2, 4.5 in P3–P4 and 5 in P5**. Every segment is measured and the measured numbers replace these estimates in `CLAUDE.md`.

Source data: `_G.CC_PATHS` in `ClimbAndCollect.rbxl` (main route 5,635 points, ~3 studs apart; `i` = point index, `s` = studs from the Foothold gate). All times are **ESTIMATES** until measured in play.

## Reading of the targets (needs confirmation)
5 pushes × 10–15 min = 50–75 min, which matches the ~60 min **first ascent**, not the 25–30 min **skilled** run. So: skilled ≈ 5–6 min per push, first-timers ≈ 10–15 min per push.

## Rules for every segment
- On the main route; the trail runs through it (no free bypass for skilled players).
- A fall lands on a catch shelf or the trail below, never below the previous camp. Worst-case walk back shown per segment.
- No fall damage or cargo loss exists yet. Hazards only knock back/push. Fall-loss arrives with gameplay systems.
- Difficulty (1–10) rises with altitude. P1–P2: gaps ≤ 5 studs, platforms ≥ 8×8, falls ≤ 14 studs. P3–P5: gaps up to 8 studs, platforms ≥ 5×5.
- Hazards run on fixed, learnable cycles with a ≥ 2 s visual tell. No audio yet, so the tell must read with sound off.
- Mobile: climbing uses Roblox's native climb (walk into the surface, no button). Jumps use the jump button only. No pixel-precise aiming, no swing ropes. Every segment is checked from the default camera.
- Colors only from `design/world-tokens.md`. Fixed ropes use `lanternGold` (wayfinding). Tells use motion and particles in existing tokens. There is no warning color in the tokens; adding one would need your approval.
- Fixed ropes are world fixtures (K2-style fixed lines). The LOCKED "unlock ropes, gliders" equipment comes later and should open optional shortcuts, never be required.

## Per push

| Push (walk now) | New verb | Segment | Where (i / s / y) | Added (skilled) | Diff | Fallback / return | Mobile read |
|---|---|---|---|---|---|---|---|
| **P1** Foothold → C1 (3.5 min) | **Climb** (tutorial) | 1a Meadow Boulder Hop — **as built:** s1182–1238 (i395), moved into a pinch point (both sides > 45°) | i233–267 / s696–798 / y47–56 | +20 s | 1 | Built: 6-deep gully between stone kerbs, 5 mossy stones (gaps 2–2.5); fall = gully floor, frame climb back to the start lip | Wide flat stones, path-colored tops |
| | | 1b Shepherd's Step — **as built:** s1804–1896 (i603–630) | i600–629 / s1797–1884 / y104–126 | +30 s | 2 | Built: the trail sinks into a cut lane, two framed climbs (8 + 12 studs); no failure state | Frame faces the trail; walk into it to climb |
| | | 1c ~~Falls Spray Rocks~~ → **Lookout Rocks, as built:** s2635–2703 (i880), relocated because the route passes ~90 studs from the falls pool | i1040–1090 / s3115–3265 / y≈214 | +40 s | 3 | Built: 7-deep gully, stones → slab → 8-stud framed climb onto a high rock → two stones down → lip; fall = gully floor, frame climb back | Climb frame visible from the lip |
| **P2** C1 → C2 (4.3 min) | **Bounce / platform** | 2a Falls-side Root Stair — **as built:** s3611–3726 | i1174–1250 / s3517–3750 / y238–300 | +30 s | 3 | Built: cut lane beside the falls; 10 stumps and stones rising ~29 studs (gaps 3); fall = the lane floor, which ramps back to the start | Stumps step up toward the trail |
| | | 2b Bounce-cap Grove — **as built:** s4905–4970 (pinch i1632–1686) | i1530–1600 / s4582–4792 / y376–384 | +35 s | 4 | Built: 14-deep kerbed gully; 2 glowing caps stand 3.5 above the floor and launch 20 studs onto two fallen logs at trail+3; fall = floor beside a cap, one jump to retry | Caps glow indigo/turquoise; landing on one is the input |
| | | 2c ~~Root Arch Crossing~~ → **Rootway Hollow, as built:** s5499–5606 (pinch i1826–1944), relocated: the Giant Tree pad is flat and open (no containment) and the root arch spans *across* the trail | i2030–2090 / s6082–6262 / y427–441 | +45 s | 5 | Built: hollow deepening to 12–22 below the trail; stumps, a cap launching onto a stone shelf, stones, an 8-stud root climb, stumps down to the far kerb; fall = hollow floor, walk back to the start | Root climb with an indigo glow vein |
| **P3** C2 → C3 (3.6 min) | **Fixed rope** + rockfall | 3a Sandstone Rope Pitch | i2744–2859 / s8224–8569 / y498–601 | +40 s | 5 | Two vertical rope pitches with a rest ledge. Fall ≤ 18 studs to the pitch start or the rest ledge | Rope = climbable strip, high contrast on sandstone |
| | | 3b Rope Ledge Traverse | i2985–3181 / s8947–9534 / y612–788 | +45 s | 6 | 4-stud ledge with rope handrail, plank gaps of 3–6 studs. Fall = switchback below, ≤ 25 s back | Handrail rope marks the edge |
| | | 3c Rockfall Gully | i3209–3353 / s9616–10048 / y788–918 | +50 s (incl. waiting) | 6 | Boulders roll down marked lanes every 9 s, after a 2 s tell (dust, pebbles, shadow ring). Overhang alcoves every ~25 studs. Hit = knocked back to the previous alcove | Lanes are visible ruts; alcoves are lit |
| **P4** C3 → C4 (3.9 min) | **Brace** (gust timing) | 4a Gale Switchbacks | i3736–3913 / s11197–11727 / y896–953 | +40 s | 6 | Gusts every 8 s (2 s tell: streaks, flags whip), outward push. Low edge wall on the first switchback. Fall = switchback below, ≤ 15 s | Windbreaks = obvious stone shelters |
| | | 4b Rune Pillar Stair | i4182–4321 / s12531–12948 / y1064–1188 | +50 s | 7 | Basalt pillar jumps (gaps 6–8 studs, 5×5 tops) with rope climbs between tiers, under gusts. Catch ledge under each tier | Rune glow on the next pillar |
| | | 4c Knife-Edge Ridge | i4604–4675 / s13797–14010 / y1277–1341 | +35 s | 7 | Exposed ridge walk under gusts. **Sheltered tunnel alongside, ~25 s slower**, is the safe line (master.md §4) | Tunnel mouth is lit |
| **P5** C4 → Summit (2.4 min) | **Ice footing** + avalanche | 5a Crevasse Ladders | i5022–5112 / s15049–15319 / y1443–1446 | +35 s | 7 | 3 ladder bridges (2.5 studs wide) plus one down-and-up ladder. Fall = crevasse floor, ice-step exit in ~30 s | Rungs read against the ice |
| | | 5b Avalanche Chutes | i5123–5220 / s15352–15643 / y1448–1536 | +55 s (incl. waiting) | 8 | 3 chutes, slides every 12 s after a 3 s tell (snow puff at the top, ground shake). Crystal alcoves between chutes. Hit = pushed to the spiral loop below, ~45 s lost | Chute lanes carved and bare |
| | | 5c Crown Ice Wall | i5590–5635 / s16650–16887 / y≈1925–2000 | +60 s | 9 | Last ~75 studs: 3 ice-wall pitches with crystal holds, slick ledges between. Rest ledges catch; worst drop ≤ 30 studs | Summit crown overhead the whole time |

## Time ESTIMATE (skilled = walk + segments; first-timer = walk × 1.3 + segment time × 3 for retries and hesitation; no discovery stops)

| Push | Walk now | Added | Skilled ESTIMATE | First-timer ESTIMATE |
|---|---|---|---|---|
| P1 | 3.5 | +1.5 | 5.0 | 9 |
| P2 | 4.3 | +1.8 | 6.1 | 11 |
| P3 | 3.6 | +2.3 | 5.9 | 11 |
| P4 | 3.9 | +2.1 | 6.0 | 11 |
| P5 | 2.4 | +2.5 | 4.9 | 11 |
| **Total** (+0.2 spawn → gate) | 17.6 | +10.2 | **≈28 min** | **≈54 min** |

Creature discovery, camps and stamina/warmth later add first-timer time, which moves 54 toward the 60 min target.

## Build approach
- `src/world/TraverseKit.luau`: shared builders (climb frame, fixed rope, ladder, bounce cap, ice ledge, catch shelf, alcove, segment start/end timing triggers).
- `src/world/TraverseP1.luau` … `TraverseP5.luau`: one module per push, placed by route index from `_G.CC_PATHS`.
- Terrain re-profiling (e.g. turning a ramp into a step) goes into a `C.TRAVERSE` height-override table in `WorldConfig`, used by `MountainGen`. The world stays reproducible, and each push needs a full rebuild.
- `BuildAll`: new `B.traverse(n)` step after `B.regions()`.
- Runtime (first runtime code in the place): hazard cycles in one server Script. Bounce caps, gust push and knockback in one client LocalScript, because character physics is client-owned. No rewards involved, so nothing to trust from the client yet.
- Per push: rebuild → checksum src vs Studio → playtest → screenshots in `evidence/traverseP<n>/` → new checkpoint `Traverse_P<n>_<date>` → Ctrl+S.

## Measurement limits (honest)
`character_navigation` uses pathfinding. It can walk and climb trusses, but it cannot reliably time bounce caps, gust windows or ladders. Where it fails I'll drive the character with keyboard input in play mode. Those are bot times, not skilled-human times. Real skilled and novice numbers need your own runs.
