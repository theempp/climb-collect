# v4 P3 report (run 2, 2026-10-21) — first draft

All times BOT (route_climb_bot at walk 12, perfect input, Studio desktop Play Solo) unless labelled. Human, phone and multi-client numbers are UNVERIFIED.

## What was built
- **ClimbKit pitch stacks (terrain-first)** on every steep band of the three hard routes: Ledge forest (8 faces) + cliffs (9), Spire forest (10) + cliffs (14) + storm (13), Waterfall lip (6, ladders beside the falls) + forest (9) + cliffs (13) + storm (9). Features: rest ledges + checkpoints, sideways crossings, rockfall chutes, lunge bands (Ledge/Spire), ladders (Waterfall).
- **Hang line** (user choice "hang lines on own lane"): Ledge lip, s 3300–3850 — notched lane, climb down 50, 506-stud ledge 28 below the lane (72 % under a > 50° face), crossing + chute + rest, climb out. Spire: not built (its legs are knife-ridge crests with 30-deep couloirs both sides; a ledge would sit on a walkable couloir floor). See decision log.
- **Shepherd rework: NOT done beyond P2.** One-arm scramble stacks were built and removed (gentle arms: contour ledges ran inside the hillside, entries dropped 100 studs). Needs authored set pieces like P2.
- Terrain fixes found by the bots: heightfield pits/slots beside summit-approach hairpins (pit fill), Spire crest widened 5 → 7 (voxel rounding dropped walkers into couloirs), Camp 2 sign boards climbable, over-steep exit ramps (line ends moved), neighbouring stack boxes erasing each other (`BuildAll.allLines`).
- Controller fixes: ladder stand-off, mantle landing relative to the grabbed surface, descend grab hangs below the lip, leg clearance, diagonal push keeps vertical part at a side edge, crossings end where the floor returns, lunge band non-colliding.

## Segment results (last batch, after all fixes, 1 run each, BOT)
| Route / line | Time | Stuck | Notes |
|---|---|---|---|
| Ledge P1 | 71.0 s | 0 | |
| Ledge lip (hang) | 66.1 s | 0 | descend + crossing + chute + climb out |
| Ledge forest | 200.1 s | 0 | |
| Ledge cliffs | 268.4 s | 0 | after the crossing fix (3 crossings "traverse-landed") |
| Spire forest | 121.7 s | 0 | |
| Spire cliffs | 222.3 s | 0 | |
| Spire storm | 123.5 s | 0 | |
| Waterfall lip | 118.2 s | 0 | |
| Waterfall forest | 98.7 s | 0 | |
| Waterfall cliffs | 348.7 s | 0 | |
| Waterfall storm | 136.9 s | 0 | |

## Route totals (ESTIMATE = measured segments + walked trail at the 10.8 studs/s BOT average + summit stair 167 s BOT)
| Route | Total | On lines (hands-on share) | Full-run evidence |
|---|---|---|---|
| Waterfall | ~27.3 min | 703 s (43 %) | full BOT run reached s ~12,950 at 23:27 before the (since fixed) hairpin pit; consistent with the estimate |
| Ledge | ~27.6 min | 603 s (36 %) | no clean full run (segments only) |
| Spire | ~24.7 min | 468 s (32 %) | full run reached cliffs F1 at 12:19 (entry since fixed) |
| Shepherd | unchanged V3 + P2 (~26.6 min walk ESTIMATE) | P2 stretch only | tutorial untouched |

All three hard routes sit in the 25–30 min band by ESTIMATE; **hands-on share is 32–43 %, short of the ~75 % target** (lanes between bands are still walked).

## Not done / UNVERIFIED (honest list)
- 20 scripted runs per route: not done. Each line segment passed 1–4 times across batches (no clean full-route run).
- ±36 bypass profiles and physical no-climb bypass tests for the new stacks: not done. Known bypass: the Ledge hang line (gentle grass above the lane lets walkers go around the notches).
- Two-way (descend) test: descend grab verified on the hang entry face only.
- Checkpoint spacing: rests on every stack + RouteKit checkpoints; ~4 min spacing not re-measured.
- Waterfall/Ledge summit approach: steep inner drops at hairpins remain (players can fall ~25–45).

## Regression (after the full terrain rebuild)
- A1 persistence suite 12/12 (mock store; the new `gear` profile block loads on old profiles).
- B checks 12/12 (scripted client).
- Tutorial BOT 6:11.6 (was 6:07.6), 0 stuck, ends L2.

## Perf (PlaySolo, Studio desktop, focused, 10 s static, vsync 60)
| Spot | FPS | p95 / worst | >33 ms | World streamed | Stage 4 baseline |
|---|---|---|---|---|---|
| Spawn | 60.3 | 17.7 / 19.6 ms | 0 | 5,018 | 2,853 (**+76 %**) |
| Training Yard | 60.0 | 17.6 / 19.4 | 0 | 5,158 | — |
| Shepherd s 2500 | 60.7 | 17.8 / 21.8 | 0 | 4,639 | 3,548 (**+31 %**) |
| Ledge lip hang | 60.3 | 17.6 / 19.5 | 0 | 4,972 | — |
| Waterfall forest stack | 60.4 | 17.8 / 19.5 | 0 | 5,213 | — |
| Ledge cliffs stack | 60.2 | 17.7 / 18.9 | 0 | 3,875 | — |
| Spire storm stack | 60.2 | 17.8 / 19.5 | 0 | 4,002 | — |

At the Foothold the new streamed instances are mostly the route kits of the three hard routes (RouteKit, built for them for the first time in run 2: Ledge 559, Spire 167, Waterfall 151 near spawn), the line parts (Waterfall lip ladders 365) and the Training Yard (77). **This passes the +15 % per-location cap → brief §5 hard stop: P4 testing, P5 and P6 were not run.** Frame cost is unchanged on this desktop; phone cost UNVERIFIED.

## Evidence
- `evidence/v4_P3_Waterfall/P3W_01_lip_ladder_stack_beside_falls_{desktop,phone_aspect}.jpg` — honest read: reads as dark slate shelves on a grass slope, not yet "wet rock beside the falls" (art pass needed).
- `evidence/v4_P3_Ledge/P3L_90_rejected_hang_through_falls_first_site.jpg` (first hang site, rejected: ran through the falls' water).
- `evidence/v4_P4/P4_01_training_yard_first_draft_{desktop,phone_aspect}.jpg`.

## Trim round (user: "Trim route kits")
- Ledge fixed-rope runs: post every ~18 studs, one rope per post pair (Ledge kit 1,400 → 598 instances); ladder rungs every 8 studs; face pitons every 24 (all lines 1,958 → 1,741).
- Re-measured (PlaySolo, 6 s settle): spawn 4,240 (Stage 4: 2,853 → +49 %), Shepherd s 2500 4,439 (3,548 → +25 %). A longer settle at spawn streamed 5,223. Near spawn the run-2 additions are the hard-route kits (Ledge 293, Spire 167, Waterfall 142), Waterfall lip ladder parts (305) and the Training Yard (77); LedgeP1 (270) and ShepherdP2 date from Stage 5. The largest single block is the unchanged Shepherd kit (~2,000 streamed).
- **Still over the +15 % cap**, so the stop stands. Cheapest next cuts: cairns/lanterns of the three hard-route kits near the Foothold (models → terrain cairns), simpler ladder visuals on the Waterfall lip. The comparison itself is noisy (streamed counts move ~20 % with settle time); a fixed-settle re-baseline would help.
- The trims are in the open Studio session and in `src/`; the file on disk is the 17:34 save (Studio could not be brought to the front to save again — press Ctrl+S in Studio).
