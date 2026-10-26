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

The current helper version is4. Repeated `apply` calls skip already upgraded regions. Apply it to the baked root while that root is in Workspace: plant grounding raycasts its generated WalkSurface. Requiring a modified ModuleScript in the same Studio session may use its cached module; replace/reload that ModuleScript or cold reopen before applying a new version. Review02 was an intermediate v3 candidate with continuous-height planting; when deliberately upgrading that intermediate candidate, clear only its six regional MountainQualityVersion attributes before the one in-place apply. Review01 uses v2 and upgrades normally. Do not reset version attributes on a newer, independently modified combined mountain without reconciling its source.

Current output: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review04.rbxl`.
SHA256: `b0ae05855a36c6623b5cb8cd7bcae8f7cb90bdbcf4f75bfe9cd249c7529129e3`.
Current evidence and acceptance limits: [continuation report](mountain-quality-review04-report.md). Run `python mountain/tools/quality_review04_delivery.py delivery` for this handoff. The historical `quality_delivery_check.py` intentionally remains bound to Review01; it is not a current-source verifier.

Review01 is preserved, with its original manifest archived as `mountain-quality-manifest-review01.json`. Native saves can rewrite both SmoothGrid and PhysicsGrid without an intentional Terrain edit. `restore_terrain_payloads.py` creates a NEW file, restoring every differing Terrain payload from an explicitly chosen authority and verifying that all other chunks are byte-identical. Never use this review's older terrain checkpoint for a newer combined place. Preserve failed checkpoints and cold reopen the restored file.


Review04 changes only MountainQuality relative to Review03. The v4 CSG prototype is prepared before destructive replacement; failure leaves existing regions intact. Its Rock ascent and Ground/biome lane physical properties reproduce Review03 while preserving existing custom properties. Revalidate effective physics against the current combined authority, including any MaterialService overrides; do not infer it from collider transforms. This local review has996 verified mountain colliders. Review04 native save also rewrote Terrain Materials in addition to SmoothGrid/PhysicsGrid; all70 payloads must still be checked. Review03 and its manifest remain archived and immutable.
