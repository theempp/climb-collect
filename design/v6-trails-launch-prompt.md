# Launch prompt: v6 trails rework (paste into a new chat)

Continue CLIMB & COLLECT. **Goal: completely redesign the Shepherd + Waterfall trails so they are thrilling, not a flat walk.** The v5 P1 attempt (2026-10-21) produced long contour ledges at a steady ~0.2-0.3 grade: the user's verdict is "boring and flat, you just walk in a straight line on flat ground". Do not polish it. Rethink it.

## Read first
`CLAUDE.md` (gotchas), `master.md` §0.9, `design/v5-trails-and-mountain-plan.md` (LOCKED decisions + round-3 set-piece table), `design/decision-log.md` (last 6 rows), `design/references-intel.md` + `references/` (the K2-style clips are the feel target), `design/v5-tokens.md`.

## User rules (LOCKED, 2026-10-21)
- **No railings** anywhere. Falling off and losing progress to the last checkpoint is the tension and the reason players come back (to reach the next checkpoint and find rarer creatures).
- **No plank / tread layer.** The trail is the mountain's own rock and earth. Ladders, ropes, log and rope bridges and boulder blocks are fine as set pieces.
- **Walking off an edge is a real fall** (no catch on walk-off edges). Climbing slips keep the catch window.
- **Much more elevation change, intensity and suspense.** "Change up the trails completely; add more adventure and thrill."
- Still LOCKED: 25-30 min skilled per route, Shepherd ~60 min first-time; tutorial beats, Rare nook, hollow + lip nests stay; Foothold + 4 gates (Ledge + Spire gated "Coming soon"); sparse fair hazards (>= 2 s tell); instance budget = P0 baseline +15 %; first publish = Shepherd + Waterfall, private, user only first.

## What must change (design direction, propose before building)
- Vertical first: the route should climb constantly and visibly: steep scrambles, rock steps you jump up, chimneys, short and tall ladders, fixed-rope pitches, exposed ridge crests, ledges that narrow and pinch, gaps to jump, descents into gullies and back up, false summits. Few stretches of plain walking; no stretch longer than ~20-30 s without a beat.
- Use the existing climb controller (`CC_ClimbClient`: marked faces = Asphalt terrain or `Climbable` parts, stamina, lunge, slip/catch, mantle) much more: hands-on climbing should be a large share of the route (v4 target was ~75 %).
- Real exposure: drops visible right beside the line, air under bridges, ridge crests with drops on both sides; checkpoints placed so a fall costs a meaningful but fair chunk (~1-4 min).
- Variety per route following the round-3 table (Shepherd: gullies, log/stone crossings, rope bridges, boulder stair in fog; Waterfall: wet slot canyon, falls ledges, root arches, ruin bridges, ladder faces).
- Ask the user ONE popup of key choices first (my recommendation first): e.g. how much hands-on climbing vs walking, jump-gaps yes/no, how punishing falls should be (checkpoint spacing), Shepherd difficulty vs the other routes.

## What exists you can reuse (all in `src/`, mirrored in Studio)
- `src/world/RouteSpline.luau` (data), `SplineGen.luau` (nodes → 2-stud samples; band nodes solve the contour; AUTO heights; ladder pieces incl. `inward` turns; cross-section stamp into the heightfield: ledge/slot/ridge/open/gap/log/stair, tread-priority, `SG.EDGE`/`SHOULDER`/`WALL_GAP`), `SplineKit.luau` (ladders with Climbable grip + rock face, rope/log bridges, clefts, rests, cairns, guide flags, CC_Track export for bots). `MountainGen.computeField({routes=true, v5=true, v4Keep={"Waterfall"}})`, `BuildAll.v5All(opts)` rebuilds the whole world in ~13 s in one call.
- Bot: `tools/route_climb_bot.luau` (`_G.CC_RBOT_CFG = { route, s0, s1 }`, poll `_G.CC_RBOT` with back-to-back ~29 s calls).
- Helpers I used: polar terrain map + route overlay (scratchpad `polarmap.py` / `v5plot.py`, sink on port 8768; recreate if gone).

## Lessons from this attempt (avoid repeating)
- Pure-terrain ledges: 4-stud voxels render a 5-wide ledge as ~6-8 studs with rounded, tilted edges; walkers slid off until the flat core was widened and the wall foot pulled back 1.5. Profile every narrow type with raycasts in a playtest.
- Ladder turns: the ledge must run ~6 studs past the foot; the rock face must stand ~3 behind the ladder plane (voxel bulge blocks the grab); the Climbable grip must end ~1 above the top or the mantle never fires; the spline must not curve through the top landing.
- Camps: the trail ran through the fire/bench ring; camp props now cluster on the side no trail uses (`RouteKit.camps`).
- Steady-grade contour ledges are exactly what reads as boring. Elevation should come in bursts (climbs, steps, scrambles), not a constant gentle ramp.

## State at handoff
Studio (`ClimbAndCollect.rbxl`, its own Studio window; another F1 session uses a second Studio, do not touch it) holds the unsaved v5 P1 prototype (v5 Shepherd terrain-only, v4 Waterfall, Ledge/Spire not built). **The file on disk is still the P0 save (19:43); nothing from P1 was saved, all of it is reproducible from `src/`.** Decide whether to keep this world or reload the file. Checkpoints in the place: `PreP3_2026-10-21`, `PreV5_2026-10-21`. No P1 checkpoint was taken. Evidence: `evidence/v5_P1/` (2 shots). The publish plumbing, fog pass and feel pass from the v5 run were not started.
