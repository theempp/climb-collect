# v6 trails: beat chains (2026-10-21/22)

Why: the v5 P1 contour ledges (steady ~0.2-0.3 grade on gentle slopes) read as "boring and flat" (user). v6 rebuilds the
trails as **beat chains**. First slice = Shepherd Camp 1 -> Camp 2, then STOP for the user's playtest before rolling the
recipe out to the rest of Shepherd and to Waterfall.

## User decisions (popup 2026-10-21, all LOCKED)
- Hands-on share: **Shepherd ~35 %, Waterfall ~55 %**.
- **Jump gaps yes**: short (3-5 studs), readable, over real drops; a miss is a real fall.
- **Fall cost scales with height**: ~1.5 min lost low, ~3-4 min near the top.
- First slice: **Shepherd Camp 1 -> Camp 2**, final quality, then STOP.
- Still LOCKED from the brief: no railings, no plank/tread layer, walk-off = real fall, 25-30 min skilled per route,
  tutorial beats / Rare nook / nests fixed, instance budget = P0 +15 %, sparse fair hazards.

## The recipe (code: `SplineGen`, `SplineKit`, `RouteSpline`, `tools/route_climb_bot.luau`)
- Height comes in **bursts**: vertical pieces between near-level ledges. Pieces (foot node + synthetic top `run` ahead,
  `rise` up or down): `ladder`, `pitch` (marked Asphalt rock face, fixed-rope cue), `chimney` (marked face 2.5 back in a
  10-wide recess cut into the cliff), `steps` (rock blocks to jump up / step down; the terrain under them is the lower
  end's height).
- Segment types: `jump` (gap open in the heightfield + rock lips), `traverse` (open gap + marked slab on the inner
  side + fixed rope), `ford` (stepping stones), `rim` / `path` (tread only, never fills a drop beside it), plus v5 types.
- **Exposure is real terrain**: band tiers are contour ledges cut into the existing ~300-stud forest band (80 deg), so
  the drop below every ledge is the cliff itself. Node `drop` deepens the outer cut, `cut` sets how deep a tier sits.
- **Enforced obstacles on open ground** come from terrain the player can't walk around: `S.GORGES` carves a creek into
  a 30-45-stud gorge from the falls slot head to the band foot; the only crossing is the route's (steps down, stones,
  pitch up). Flavour beats on open meadow (clefts, overlook) are not enforced.
- Inward pieces on a band land on the upper ledge's own contour (`cut` nodes; run capped at minRun + 5).
- Bot track per piece (walk / climb / jump nodes); the bot logs face time (strict hands-on) and segment time.

## Slice layout (Shepherd leg 2, `RouteSpline` "leg 2 (v6 beat chain)")
Camp 1 -> mossy cleft -> shelf path -> cleft 2 -> falls overlook (slot head) -> gorge west rim (exposed) -> rock steps
down the gorge wall -> stepping stones -> pitch up the far wall -> east-bank ledge with two rock-step pieces -> band foot
(cairn checkpoint) -> 10 eastward tiers up the band: pitch 24, jump gap, ladder 16, pinch ledge, rope bridge, chimney
28, tent rest (checkpoint), hand traverse, rock steps 16, jump gap, pinch, **tall ladder 38**, rope bridge, cairn
(checkpoint), pitch 30, pitch 28, rock steps 18, **top-out pitch 38** -> viewpoint -> cleft -> Camp 2.
Checkpoints: Camp 1, band foot, band tent, L5 cairn, Camp 2 (gaps ~1-2 min BOT).

## Measured (desktop Studio, BOT = perfect input)
- Camp 1 -> Camp 2: **257.3 s BOT** (repeat of 258.0), 0 stuck, 0 falls, 22 jumps, 9 grabs. Leg length 2,708 studs
  (v5: 3,865). Climb rise on pieces 168 studs of ~550.
- Hands-on: **face time 30 s = 12 %** (strict), **time inside beat segments 68 s = 26 %**. Below the 35 % target (see
  open items).
- Fall chain: walk-off above the tent -> respawn at the tent checkpoint (verified).
- Bypass: gorge cross attempts at 8 points all drop 29-46 (real falls) after the fix; the band is cliff on both ends.
- Instances (streamed World, 12 s settle): Camp 1 2,731 (cap 6,246), band tent 2,466, Camp 2 1,642 (cap 4,511);
  60 FPS, worst 19.4-24.1 ms. Shepherd folder 589 instances (v5: 582).

## Open items (honest)
1. Hands-on below 35 %: options are more and taller faces on the band, slower climb speed (7 -> ~5 studs/s), hands-on
   beats on the lower shelf. Needs your feel test first.
2. **Tutorial regression (OPEN, likely from v5 P1 leg 1, not v6):** tutorial bot 488.8 s, L1, Rare nook rope + pup net
   fail (P0: 6:07.7, L2). Leg-1 nodes are untouched by v6; the nook stretch got a ledge wall + hairpin in v5 P1 and the
   bot's waypoints are v4 positions. Not proven (SplineGen has no git history). Fix in the leg-1 rework.
3. Visual: tall ladder half hidden in its recess; rock-step blocks are plain boxes; gorge stream too thin to render;
   pitch faces are Asphalt-tinted blocks. Lower shelf is ~70 s of flavour beats (not enforced).
4. Not done: hazards on leg 2, fog, two-client test, phone/human timing, Waterfall rework, Shepherd legs 1/3/4/5.

## Next (after your playtest)
Roll the recipe to Shepherd legs 3-5 and leg 1 (tutorial-safe), then Waterfall (creek slot canyon above the falls +
falls-side ledges, ~55 % hands-on).
