# Home-base promenade rebuild — plan (2026-10-26, APPROVED by owner 2026-10-26)

Run this in a new Claude Code chat. Local review only: no publishing, pushing or merging.

## Goal
Replace the 1,496-stud horizontal row of 8 home plots and the 3 gates (`ThreeGates_NoGameplay`) with one straight avenue. It has 4 homes on each side and a central garden promenade leading to one large mountain gate. The compact mountain (Review02) stays exactly as it is.

## Owner decisions (2026-10-26)
| Topic | Choice |
|---|---|
| Layout | 4 homes on the left, 4 on the right, facing each other across the promenade |
| Plot size | Shrink from 180×220 to about **140×180**, with the tycoon contents refit inside each plot |
| Gate | One huge gate at the end of the avenue nearest the mountain, with the mountain framed beyond it |
| Promenade | A garden promenade with a decorative center channel shaped so a conveyor can be added later. **No conveyor gameplay yet.** |

## Reference read: Steal an Egg / Break and Steal an Egg
These notes come from general knowledge of the genre. I did not check live gameplay, so treat them as unverified.
- Bases sit on both sides of one shared central lane, so every player passes every base. That gives social visibility and makes "show-off" cosmetics worth having.
- The lane is the single spine, so it's always obvious where to go.
- Bases are short and wide on the lane side, with the valuables near the front so they can be seen.
- Our changes from that template:
  - Garden art instead of a flat road.
  - The mountain is the destination at the end of the spine, not a conveyor.
  - Secured creatures stay protected; no base-raiding is added.

## Proposed geometry (provisional, check in Phase 1)
- Avenue axis points straight at the mountain center line (X 4096 in the compact build). The gate end faces the mountain entrance.
- Plots are 140 wide along the avenue and 180 deep, with 8-stud buffers. One side is 4 × 148 ≈ **592 studs long**, versus 1,496 now.
- Promenade is about 70 wide: a 12-wide center channel and two 29-wide walking lanes (wider than the 32-wide escape-lane rule needs for the return trip).
- Farthest home front to gate: about 520 studs (~33 s at 16 studs/s). Today it's about 722 studs (~45 s).
- Spawns stay at each home. The 60-stud front walking space is replaced by the promenade.

## Phases (each stops on a failure)
0. **Baseline.** Branch `codex/homebase-promenade` from `187ac03` in `Desktop/climb-collect-mountain-quality`. Copy Review02 to `ClimbCollect.HomePromenade.Review01.rbxl`. Confirm 83/83 sources and the 29 suites pass.
1. **Layout data.** Add a `HomeLayout` module in shared with the plot transforms, promenade bounds and gate pose. `Sanctuary.luau`, `TycoonWorld` and the allocator read from it. Replace the hard-coded `plots[4].floor.Position.X+94` center and the `ThreeGates_NoGameplay` lookups. Add CLI tests for spacing, facing, overlaps and gate distance.
2. **Plot refit to 140×180.** Re-place the habitats, conveyors, services, the two service markers, the spawn and the lodge so all fit with clearance. Assert footprints in the tests, and keep tycoon progression and save data unchanged.
3. **Terrain and landscape.** Remove the old row, the 3 gates and their gate landscapes (`*GateLandscape`, `GateFlankUpper`). Flatten and blend the avenue basin into the compact mountain foothills. Keep the mountain's voxel fingerprint unchanged outside the home-base box.
4. **Single grand gate.** Build one large gate at the avenue's mountain end. It's the only sanctuary/secure boundary, so `nearGate` and the safe-exit trigger move here. Repeat the raid return test: carrying cargo through the gate secures exactly one creature.
5. **Promenade art.** Paving, a center water channel shaped as a future conveyor bed, lanterns, planting and plot-front frames. All colours and materials come from the project's existing world tokens; no new palette.
6. **Verify.** Scene checks, cold reopen and fingerprint, 8 natural-spawn walks from home to gate and back, the full summit raid return through the new gate, the 8-home performance pass (focused window), and screenshots: aerial, avenue view and the gate framing the mountain.
7. **Report and stop.** Write `design/homebase-promenade-review01-report.md` and update START-HERE, the vault Milestones/Decisions, and the graph refresh. Commit locally only.

## Open (not in this rebuild)
- Conveyor eggs as gameplay (low-tier only, if approved later).
- Low graphics-level visibility of the mountain from home (Review02 finding).
- Real devices, hosted 8-player play, DataStore.

## Paste into the new chat
> Read `docs/superpowers/plans/2026-10-26-homebase-promenade-rebuild.md` in `Desktop/climb&collect` and carry it out in `Desktop/climb-collect-mountain-quality`, phase by phase. Local only: no push, publish or merge. Stop at the Phase 7 report for my review.
