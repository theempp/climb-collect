# v4 routes plan (2026-10-20) — APPROVED 2026-10-20 for P0-P2 (user), nothing built yet

Sources: `design/references-intel.md` (Stage 1), `design/v4-climb-concept.md` (LOCKED #1-19 unchanged), interview answers below. **No LOCKED item is changed.** Cost figures are ESTIMATES (not measured).

## Interview answers (this stage; LOCKED-ref, user answers)
1. Fall 2 clip dropped; plank walkways/hanging bridges are optional set pieces only, justified by your answers, not a clip.
2. Hard routes = **mix**: knife-ridge crest sections (img1 read) + ladders over grooves/crevasses + rope-guided steep slopes between.
3. Shepherd's Road: **keep tutorial beats 4-5 and the Rare nook where they are; rework the trail around them.**
4. Avalanche chutes = **timed crossing between two safe ledges.**
5. Descent on Ledge/Spire: **same line back down**; falls still go to the last checkpoint; players pass through each other on faces/ledges (LOCKED #15).
6. Waterfall Stair: stairs/ladders beside the falls, wet-rock ledges, **one** rope-slope crossing.
7. Atmosphere: **static** fog + light shafts + cloud layer in the prototype; dynamic weather only after a mobile cost test.
8. Order: **performance (Stages 3-4) before any v4 build.**

## Numbered plan
**0. Gate (now):** Stages 3-4 (perf diagnosis, fixes, B-polish) finish first. Checkpoint `PreV4_<date>` + file copy before v4 starts. No v4 build until you approve this plan after Stage 4.

**1. Terrain changes (P1-P3 of the concept, per route, only where needed)**
- Cliff Ledge Line: re-sculpt flanks into 2-4 stud strata ledges and a face band; ridge-crest sections 2-3 avatar-widths wide with sheer drops either side. Cut/stamp edges verified with ±36-stud profiles (no free bypass).
- Spire Ridge: sharpen the crest into a knife ridge with one natural rock arch window (img1 landmark), ladder pitches at notches.
- Waterfall Stair: stair flights + ladder pitches beside the existing falls; wet-rock ledge band; one rope-slope crossing.
- Crown Gate arch and summit stair stay; shared summit merge stays.
- Terrain stays a shell ~10-12 studs thick: faces are authored rock assemblies in front of terrain, not deep cuts (known gotcha).

**2. Route changes**
- All hard/moderate routes lose the wide stamped trail; the route is the rock's natural line, marked by world cues (ropes, pitons, cairns, lanterns, glowing flags at turns; Guide pulse button; HUD arrow) per LOCKED #3-4.
- Hands-on share targets: Shepherd ~25%, Waterfall ~50%, Ledge/Spire ~75% (PROPOSED). 25-30 min skilled kept (LOCKED #16), measured by bot, then by your runs.
- Rest ledges every 20-40 s on hard faces, 60 s+ on easy routes; checkpoints ~4 min (unchanged).
- Hazards stay as LOCKED: rockfall lanes with tells, gusts, falling trees (lower routes); avalanche = timed crossing (answer 4).

**3. Shepherd's Road and the tutorial**
- Beats 1-9, the hollow nest, the Rare nook rope and the lip nest keep their positions; only the trail between them changes (rope scramble, railed ledge, one view-down moment).
- After the rework: re-run `tutorial_bot`, B checks, A1 suite; timing may shift, so beats get re-timed (still lengthened toward ~10 min in Stage 4).
- Rework comes last in P3 order, after the hard routes prove the controller.

**4. Atmosphere (static first)**
- Prototype: depth fog, light-shaft effect on one hero view, cloud layer below the ledge route for exposure. Dynamic weather/night/whiteout: separate gate after a measured mobile test (phone numbers, not emulation, if you can supply them).

**5. Build order (each phase: checkpoint, src↔Studio checksum, playtest, evidence `evidence/v4_P<n>/`, then STOP)**
- P1 Prototype: Cliff Ledge Line first section (~60-90 s BOT), acceptance 1-7 from `v4-climb-concept.md` §7.
- P2 Tune from your feedback, then one Shepherd "gentle but alive" section.
- P3 Ledge full → Spire → Waterfall → Shepherd rework.
- P4 systems (kit, shop, canister, rescue, Training Yard annex, dynamic weather). P5 polish + mobile pass. P6 verify/report.

**6. Cost (ESTIMATE)**
- P1 ~1 long session; P2 ~half; P3 ~1 session per route (4); P4-P6 ~3-4. Instance cost: hard faces add authored parts/CSG; budget set from the Stage 3 baseline, so each phase must not raise streamed instances at its location above that baseline by more than a figure you approve.
- Biggest risks: climb controller feel on mobile (unmeasured), dynamic weather cost, `generate_mesh` quality for hero rock (UNVERIFIED).

**7. Doc changes only on approval:** `master.md` (route form, climb state, guidance layers, canister, shop, Training Yard, weather), `v4-climb-concept.md` §2 (remove Fall 2 evidence).

## Still OPEN
Gear shop currency/prices (references show "Points", evidence only); stamina numbers (set in P1); first-Rare nook behaviour if Shepherd's line moves; mobile device targets; dry-foothill palette reference.
