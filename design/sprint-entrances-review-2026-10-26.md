# Sprint and mountain entrances — October 26, 2026

Delivered artifact: **outputs/ClimbCollect.FreeClimb.Review03.SprintEntrances.rbxl**, SHA256 `af2c14388fc6be0b7b4739c94f7a5417780f3d271bad4f06037d045fc5cb4da5`. Open this exact file and press Play. Plain Review03 and Working are intermediate Studio saves with detected terrain drift; do not use those for acceptance. Review02 remains hash `6b0773dbc75ffb4c15caf22196229c67d55d0ecce60d32b5a9e6658d9660ba72`.

Owner authorized sprint, proper running animation, slight cargo penalty, and wide/direct mountain approaches while preserving every home plot. No design interview was repeated. No publication, purchase, unrelated-place change or production-data access occurred.

## Behavior and provisional tuning

- Desktop holds either Shift; mobile has a100x50 toggle above the jump area. Focus loss, typing, death and respawn clear intent. Server selects speed from boolean intent and cargo state: walk16, sprint27; carrying14.4/24.3. No new stamina mechanic.
- R15 uses Roblox run clip507767714 at Movement priority with speed-adjusted cadence. Existing two-arm carry posing follows animation evaluation; it now supports Motor6D and the current AnimationConstraint rig. R6 uses its standard locomotion clip at sprint cadence; actual R6 visual acceptance remains open.
- Two broad frontage slopes and48-stud diagonal paths link the outer frontage to side entrances atx3960/4232. Center access stays. Side landings, green return lines and lantern signs mark the boundary. Inner ends of upper retaining masses are trimmed;240 decorative parts per side were cleared as whole planted columns for road clearance. No plot/lodge resize or move.
- Side exit volumes meet the center exit on the existingz=-166 plane. Custody/securing/raid code is unchanged. Side ramps reach height28 atz=-182 before the retaining wall starts atz=-178, making the return walkable without jumping.

## Verified evidence

All evidence is in `evidence/sprint_entrances_2026-10-26/`.

- `regression.json`: **1,562 checks /25 suites /75 runtime compiles**, zero failures. Original custody/persistence/combat/hazard/tycoon/UI coverage plus new movement policy/authority, entrance geometry and old/current carry joint tests.
- `west-first-attempt.json`: natural spawn atplot1 through all seven approach legs to a Blossom egg, speed27. Initial return exposed a3.5-stud terrace step. A failing regression reproduced it; corrected v2 reaches terrace height before the wall. Early cooldown/catch failures are retained, not counted as successful custody evidence.
- `west-cargo-return.json`: actual strikes/reveal/pickup and ordinary physical return at24.3; no teleport or creature grant. Roster remains3 atz=-181.88 with a carried run, becomes4 only after crossing toz=-151.51, then the run is gone and cosmetic cargo remains. Pursuit escaped; earlier delayed attempts demonstrated catch still forfeits unsecured cargo.
- `east-outer-plot.json`: continuous physical walk across the frontage toplot8, then plot8→slope→east entrance→mountain→return. All ten legs pass carrying the already secured creature, speed24.3/health198.95. No position injection or duplicate ownership on this return.
- `mobile-carry-pose.json`: iPhone17Pro landscape simulation, full-weight .65-second running clip at1.215 rate, both exact shoulder carry matrices and horizontal velocity magnitude24.3. Actual simulator mouse click displayed SPRINT ON and applied14.4→24.3. Animation/movement sampling used keyboard input inside the simulator; physical touch/thumbstick acceptance is not claimed.
- `cold-open-source-world.json`: exact delivered file freshly opened,75 disk/source matches, eight180x2x220 floors at their original transforms, three exits/version2, no saved QA, HTTP off.
- `cold-open-desktop-input.json`: actual Shift+W16→27, run length.65/weight1, velocity(0,0,-27); release16, one HUD and one sprint GUI. Fresh console contains only normal readiness output.
- `hazard-sprint.json`: natural sprint approach on the delivered file and a timed root-hazard crossing at27. That crossing took no damage; remaining through a complete quiet/warning/active cycle caused net health loss10.97 despite regeneration. Sprint does not grant hazard immunity. This single-section check does not establish all-six balance acceptance.
- Independent review found rapid release/repress could drop the latest press. Regression failed before the fix and passed after accepting changed boolean intent while pacing duplicates. Final independent movement14/carry8/entrances19 checks pass; no remaining important finding.

## Preservation and corrected assumptions

No Terrain API was called for this feature, but Studio save changed SmoothGrid bytes. `preservation.json` retains that failed comparison. `restore_binary_terrain.py` restores exactly that one payload from Review02, preserving the other1,619 chunks. The guarded packager then preserves all1,617 non-Source chunks of the restored baked scene and matches75 sources. `final-preservation.json` proves all70 Terrain properties equal Review02; SmoothGrid payload SHA256 `75b1513b6b406a812de7456b01783f2b7882abf4b204bc196a66e2fe446255d5`.

Corrected assumptions: current R15 joints are AnimationConstraints, which the former Motor6D-only pose skipped; inbound walkability does not prove return walkability; duplicate-input pacing must not drop changed intent. Official joint migration reference retrieved this session: https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint.md.

## Remaining acceptance

Speed/guardian/hazard/pacing values remain provisional for owner play. No human comfort/balance or premium-art acceptance claimed. Physical phones/touch/performance, published animation permission, R6 visuals, hosted persistence and a new multiplayer sprint matrix remain open. Earlier Review02 eight-client coverage is historical, not a new sprint matrix. Local progress resets on Stop.

Graph coverage remains the original navigation repository/vault and excludes this isolated source. Final freshness result is recorded after the project/vault pointers are refreshed.

Final graph/vault freshness: CURRENT with zero intended-input drift after refresh. Verified backup Documents/vault-backup-graphify-2026-10-26-004039.zip, versioned export004039; final status3,590 merged nodes/6,266 edges. Benchmark recall@8=1.0/MRR0.75. Five existing unresolved links and an old overview status heading remain quality candidates; isolated implementation source remains outside graph coverage.
