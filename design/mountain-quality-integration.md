# Scoped mountain integration — local review only

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

The helper version is2 and repeated `apply` calls skip already upgraded regions. Requiring a modified ModuleScript in the same Studio session may use its cached module; replace/reload that ModuleScript or cold reopen before applying a new version.

Review output: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review01.rbxl`.
Evidence and exact acceptance limits: [morning report](mountain-quality-overnight-report.md).
