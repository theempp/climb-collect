# Scoped mountain integration — local review only

## Review05 landscape continuation — October 26, 2026

The latest owner direction extends the surrounding mountain/hills through all six sections and around the summit, superseding the earlier outer-silhouette restriction. Review05 adds **baked Terrain only** relative to Review04/e33a61a. The77 current runtime sources, six historical sources,3964 mountain parts,996 collider transforms/effective physics, anchors, protected scene and Lighting remain unchanged. MountainQuality stays version4; the baked root additionally records LandscapeContinuationVersion1.

Current local review: `outputs/ClimbCollect.MountainQuality.Review05.rbxl`. Its current hash and validation are in `mountain-quality-manifest.json` and [Review05 report](mountain-quality-review05-report.md). Review01/03/04 remain immutable. Review04's manifest is archived separately.

For later integration, **do not copy this older complete place over the current combined game**. On a new saved copy of that combined game, reconcile its terrain, region bounds and current source first. The edit-time recipe is `mountain/tools/quality_landscape_bake.luau`: run the returned chunk with stages1,2,3 in that order, followed by `quality_landscape_reconcile.luau` with the decoded `evidence/mountain_quality_2026-10-26/review05-recipe-correction.json`. This final guarded correction records native occupancy/material remnants of the original authoring experiments; it validates every expected source cell before writing. The complete recipe exactly reproduces Review05 on Review04. Do not blindly apply the correction to a newer combined terrain: a precondition mismatch requires reconciliation against that newer authority. It requires a baked FreeClimbVersion1/MountainQualityVersion4 root, and must not run during Play. Default stage3 repeats the final profile and is idempotent on this delivered terrain. This tool is not a runtime module or automatic startup hook. Preserve the integration copy's own baseline and compare its protected voxels before/after.

Write bounds: x3392..4800, y−64..800, z−1840..−208, in32-stud z slices at4-stud resolution. The playable corridor x3920..4272 is excluded for z≥−1412; behind the summit the cap may span the center. Only greater occupancy is written; existing nonempty-cell material is retained. No terrain is cleared. The natural landscape outside the tested face is scenery; this does not promise new seamless routes across every hill. Revalidate route-edge approaches and summit views on the combined place.

**The older blanket70-payload preservation/restoration instructions below apply to the prior art-only passes, not this intentional landscape edit.** Review05 retains its new Materials/PhysicsGrid/SmoothGrid serialization. Never restore its entire Terrain from Review04 or an older authority: that would erase the requested mountain continuation. Compare the intended terrain spatially after native save/cold reopen, alongside exact protected scene/source checks. Current evidence includes exact run-length voxel comparison in the documented sanctuary, playable corridor and legacy mountain domains.

The remainder records the earlier runtime-helper integration and remains relevant when reconciling those helpers.

Authority: `a3e896ad624d966c75f57a1c692b58c5f0ef63a0` and the saved Review03.SprintEntrances baseline. This upgrade is isolated on `codex/mountain-quality-overnight` in `C:/Users/HOME!/Desktop/climb-collect-mountain-quality`. Do not replace a newer combined place with this review.

Runtime scope is exactly three files:

| File | Integration |
| --- | --- |
| `mountain/world/MountainSurface.luau` | New deterministic height profiles and sandstone catch recovery coordinates. |
| `mountain/world/MountainQuality.luau` | New versioned, in-place mountain-only geometry and scenery pass. |
| `mountain/world/FreeClimb.luau` | One call to `require(script.Parent.MountainQuality).apply(root)` immediately before the final return in `build()`. |

No server, client, shared, creature-art, movement, home-base or entrance sources changed. All tests and `quality_*` tools are development evidence only. Never insert them as runtime scripts.

1. Make a new saved copy of the **current combined place** and preserve its terrain and protected scene. Inspect the current source and anchors before applying this older review's mountain pass. Reconcile conflicts if another chat has since changed mountain bounds or section names.
2. Add the two helpers beside `ServerStorage.MountainWorld.FreeClimb`. Apply the single build hook by context; do not copy the entire older FreeClimb file over newer work.
3. For an already baked mountain, call `require(game.ServerStorage.MountainWorld.MountainQuality).apply(workspace.ImpossibleMountain)` once in Edit on the new integration copy. A baked root bypasses `FreeClimb.build()` in Main. **Do not destroy the mountain root or run FreeClimb.build() to upgrade it**: the historical generator clears terrain and recreates gameplay anchors.
4. Preconditions: `FreeClimbVersion == 1`, six Catalog-named section folders, original section entry `(4096,16+64*(k-1),-210-200*(k-1))`, 344-stud face width, 120-stud climb followed by 80-stud terrace. Downhill center width32, eggs at x4038/4154, hazards at x4168. The helper removes only old regional BrokenCliff/MineralCluster/Grown_* dressing and its own previous MountainQuality folder. Review those names if later art has reused them.
5. Check all three runtime-source hashes against `mountain-quality-manifest.json`. Re-run geometry, full CLI regressions, natural carrying/escape, two-client mountain checks, and protected-scene comparison in the combined place. Preserve all70 Terrain property payloads from that integration copy's own authority, not this review's older baseline.
6. Save a new numbered combined review, audit native terrain serialization, cold reopen and play it. Integration into another chat's source/session, publishing and hosted saves were not performed here.

The current helper version is4. Repeated `apply` calls skip already upgraded regions. Apply it to the baked root while that root is in Workspace: plant grounding raycasts its generated WalkSurface. Requiring a modified ModuleScript in the same Studio session may use its cached module; replace/reload that ModuleScript or cold reopen before applying a new version. Review02 was an intermediate v3 candidate with continuous-height planting; when deliberately upgrading that intermediate candidate, clear only its six regional MountainQualityVersion attributes before the one in-place apply. Review01 uses v2 and upgrades normally. Do not reset version attributes on a newer, independently modified combined mountain without reconciling its source.

Current output: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review04.rbxl`.
SHA256: `b0ae05855a36c6623b5cb8cd7bcae8f7cb90bdbcf4f75bfe9cd249c7529129e3`.
Current evidence and acceptance limits: [continuation report](mountain-quality-review04-report.md). Run `python mountain/tools/quality_review04_delivery.py delivery` for this handoff. The historical `quality_delivery_check.py` intentionally remains bound to Review01; it is not a current-source verifier.

Review01 is preserved, with its original manifest archived as `mountain-quality-manifest-review01.json`. Native saves can rewrite both SmoothGrid and PhysicsGrid without an intentional Terrain edit. `restore_terrain_payloads.py` creates a NEW file, restoring every differing Terrain payload from an explicitly chosen authority and verifying that all other chunks are byte-identical. Never use this review's older terrain checkpoint for a newer combined place. Preserve failed checkpoints and cold reopen the restored file.


Review04 changes only MountainQuality relative to Review03. The v4 CSG prototype is prepared before destructive replacement; failure leaves existing regions intact. Its Rock ascent and Ground/biome lane physical properties reproduce Review03 while preserving existing custom properties. Revalidate effective physics against the current combined authority, including any MaterialService overrides; do not infer it from collider transforms. This local review has996 verified mountain colliders. Review04 native save also rewrote Terrain Materials in addition to SmoothGrid/PhysicsGrid; all70 payloads must still be checked. Review03 and its manifest remain archived and immutable.
