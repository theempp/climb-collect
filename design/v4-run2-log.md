# v4 Run 2 working log (P1/P2 fixes -> P3 -> P4 -> P5 -> P6), started 2026-10-21 ~08:40
Durable notes so the run survives context summaries. Short; decisions go to `decision-log.md`.

## Status
- 09:02 preflight OK (49/49 checksums), checkpoint PreP3 + file PreP3.rbxl. Currency: Both (coins + Summit Points), prices 150-1,200.

## Design notes (P3)
- P1/P2 self-review fixes done (de-striped faces, longer knife-ridge, pebble tell, P2 band rock-toned).
- P3 design: hard routes keep V3 lanes; each switchback band climb (WorldConfig route `lines`) is unstamped and rebuilt as a ClimbKit pitch stack. TERRAIN-FIRST (part-built stacks broke the +15% cap): tier ledges = terrain (route material), marked faces = terrain Asphalt (CoreConfig.CLIMB.terrainMaterial; Pavement rendered as brick paving, rejected). Parts only for cues/hazards/zones.
- Gotchas found: field contour is 0.5-2 studs inward of rendered rock (bias 1.5); Air carves overlapping the floor's top voxel lower the floor (start carves at the next voxel boundary); no head-room carve near faces (shaves the proud face front); terrain ledges round off ~4 studs at the outer edge (ledge block 12.5 deep, walking line wall+3); StreamingEnabled: audits must stand near the segment.
- Tools: tools/route_climb_bot.luau (cfg: seg / s0-s1 / fromLabel / audit="*" / verbose), CC_Track.<route> JSON from ClimbKit:export().
- (P3, ~later) User chose "hang lines on own lane" for the hands-on gap. Ledge: P1 + forest + cliffs stacks; storm + spire legs stay V3 causeways (logged). Spire: forest/cliffs/storm stacks (limestone ledges, lunge bands). Waterfall: lip(beside falls)/forest/cliffs/storm ladder stacks on slate (wet) ledges, one traverse (rope-slope) on the lip.
- Full Ledge rebuilt with hw 4.5 benches (full terrain rebuild done; RouteKit run for Ledge/Spire/Waterfall the first time: bridges, ramps, rails, mini-checkpoints).
- Key controller changes: terrain marked material (Asphalt), descend grab, pull-away threshold -0.55 + 0.4 s grace after grab, detach reasons on CC_DetachWhy.
- Bot (tools/route_climb_bot.luau): fall rule = server rule; traverse input projected on the track's face normal; re-centres on approach point.
- Ledge partial timing (BOT, run 2): P1 done 80 s; forest stack 198 s; leg pieces in the 26-min range (full clean run still pending).

## P3 fixes (run 2, after the context summary)
- Waterfall: ladder grips stood inside rock bulges -> ladders at front + 3.6; mantle lands 3-5 studs in from the grabbed surface; diagonal push at a grip edge keeps the vertical part; bot steers to ladder centre.
- A front-of-face Air carve punched holes in ledge floors: removed. Real cause of the cliffs holes: per-route builds rewrite boxes that overlap other routes' stacks -> `B.allLines()` (rewrite all boxes, then build all). Always use allLines after a stack change.
- Exit ramps: Waterfall forest (46 deg) and Spire storm (52 deg) line ends moved down (WorldConfig pads; field recomputed with `Gen.computeField({routes=true})` + `writeBox` of both stretches, then `B.player()`, `B.route(...)`, `B.allLines()`).
- Last-face landing: pad from the face front back to rT-12, rock above it cleared, ramp junction opened (Waterfall storm exit rib).
- Camp 2 signpost boards were a climbable ladder on the Waterfall line -> boards CanCollide false (Kit.sign + existing 46 boards).
- Crossing ends: step-off probe 5 studs deep for sideways moves (Waterfall cliffs chute 5).
- Segment results (BOT, Studio desktop): Waterfall lip 6 faces 0 stuck (exit stall fixed), forest 7 faces, cliffs 13 faces 214 s from chute 5, storm 9 faces + exit 33 s from F9.

## P4 code (written in parallel, synced)
- Server: Gear (shop/kit/canister/points), Coop (climb-state mirror, Hand up prompt, party ropes), Training (yard laps), Weather (schedule, dev action `weather`). Profile `gear` block (sanitize keeps old profiles valid). CoreService module list extended.
- Client: CoreClient shop card (scrolling list) + O2 button + points in HUD; ClimbClient kit/thin-air/canister/rope/rescue/training max; CC_WeatherClient (tiers).
- World: TrainingYard at (-367, 50, 2062), 63 parts (`B.trainingYard()`).

## Stop (17:35)
- Perf pass after P3: 60 FPS everywhere (desktop) but World streamed +31–76 % vs Stage 4 → brief §5 hard stop. Saved 17:34 + `ClimbAndCollect.P3stop.rbxl`. Report `evidence/v4_P3_report.md`.
- Next (user): instance budget (cut Ledge/Spire/Waterfall RouteKit rope runs + ladder rungs, or raise the cap), Shepherd rework, P4 tests (shop UI, canister, rescue needs 2 clients, Training lap, weather cost in emulation), P5/P6.
- 18:10 handover to another session; see CLAUDE.md HANDOVER note (trims unsaved in Studio).
