# Mountain quality morning report — October 26, 2026

All six sections have shaped side routes, rounded rock masses, vegetation and distinct biome landmarks within the existing mountain composition. The original center escape floor, section arrangement, terrain, gameplay anchors, sprint values, home base and creatures are preserved. The separate review passed a fresh-process cold reopen and natural summit raid/escape. Owner aesthetic, physical-device and hosted-save acceptance remain open.

## Open these

- Playable: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review01.rbxl`
- SHA256: `c3000ce9b6eb626098089719d5fa30503f7947aeb2252d6f151cb1ec0edee680` (2,517,708 bytes).
- Before/after viewer: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/evidence/mountain_quality_2026-10-26/comparison.html` — 26 matched pairs: two whole-mountain views, ascent/terrace/downhill views in each section, and six Samsung Galaxy A06 landscape simulator views.
- Contact sheet: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/evidence/mountain_quality_2026-10-26/six-biomes-after.jpg`.
- Scoped integration: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/design/mountain-quality-integration.md`; manifest: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/design/mountain-quality-manifest.json`.
- Durable checkout: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality`, branch `codex/mountain-quality-overnight`. No merge, push, purchase or publication.

Evidence filenames below are relative to `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/evidence/mountain_quality_2026-10-26/`.

## What changed

Each344-stud-wide section retains its200-stud depth and64-stud rise. Shaped shoulders provide varied climb grades and landings beside a continuous32-stud center escape. Decoration has no collision; explicit simple surfaces provide footing. A static sandstone catch ramp repairs the reproduced six-stud walking-only exit lip. Egg, guardian, hazard, rest, altar and entrance anchors were not moved.

| Section | Treatment |
| --- | --- |
| Blossom Gardens | Green shoulders, pink canopy groves, fern/flower patches and stone islands. |
| Azure Falls | Cool strata, teal planting, larger side cascade and pool. |
| Sunstone Desert | Sandstone fins and warm shelves, succulents, walking catch recovery. |
| Violet Crystals | Purple rock islands, grouped crystal spires and luminous blooms. |
| Inferno Heights | Basalt masses, ember seams and restrained dry planting. |
| Astral Crown | Pale snow-rock forms, side crown arch, crystals and stars. |

All six received the common geometry/art pass before the final foreground and landmark pass. Art remains stylized procedural geometry; it is not represented as owner-approved premium art. Original outer/rear terrain masses remain the silhouette authority.

Runtime scope: new `mountain/world/MountainSurface.luau`, new `mountain/world/MountainQuality.luau` (version2), and one call at the end of `FreeClimb.build()`. All server/client/shared modules, Art/CreatureDetails, MountainEntrances, movement, custody and home sources are identical to baseline. Tests and `quality_*` tools are development-only.

## Baseline and preservation

Read-only inspection found Review03.SprintEntrances / `a3e896ad624d966c75f57a1c692b58c5f0ef63a0` newer than the brief's historical Review02 pointer. Its75 sources matched the saved file. Immutable copy: `baseline/Review03.SprintEntrances.rbxl`, SHA256 `af2c14388fc6be0b7b4739c94f7a5417780f3d271bad4f06037d045fc5cb4da5`; source archive `baseline/source-a3e896a.zip`.

The delivered file has77 matching runtime sources and10,595 saved instances. All70 Terrain property payloads match baseline exactly; SmoothGrid SHA256 `75b1513b6b406a812de7456b01783f2b7882abf4b204bc196a66e2fe446255d5`. Native Studio saving changed terrain serialization; packaging restored baseline terrain and audited every property before the delivered file was cold-opened. Evidence: `final-file-integrity.json` and output-side audits.

Protected scene and Lighting match before/after/cold reopen. Protected canonical SHA256 `37b24bd1f0831dafef6354b54d2b4e1229315a25e86ba69fe3b17047078e4101`. An initial Windows-default text decoder produced a different hash; the QA loader now reads explicit UTF-8 and comparisons were recomputed. This was an evidence-decoding issue, not a game change. All4,667 mountain BasePart records match the intended final scene exactly after cold reopening, zero numeric drift: `cold-scene-identity.json`. No QA script is packaged.

Historical Baseline01, Review01 and Review02 were closed only after explicit owner permission, saved/live source and eight geometry-class count comparison, and hashed backups. This limited comparison does not claim exhaustive unsaved-property equality. Geometry01 failed comparison and was left open. Current sprint, creature and other chats' sessions were not changed.

## Verification

| Check | Result/evidence |
| --- | --- |
| Current regression | 26 suites,100,543 assertions,77 compiles pass. `final-regression.json`. |
| Actual cold geometry | 10,628 clearance/slope/seam/footprint checks pass. `cold-geometry.json`. |
| All-six natural traversal | 165 steps in331.10s: west ascent, east descent,12 ordinary jumps, sprint both ways, physical exit. `natural-traversal.json`. Final art retains all929 tested colliders exactly: `final-collision-preservation.json`. |
| Exact cold review raid | 120 steps in330.27s pass: natural home/west entrance, six climbs, eight summit strikes, reveal without early ownership, pickup, loaded sprint24.3, physical exit ownership3→4, all six hazard escapes. Sandstone recovery needs no jump. `cold-raid-and-hazards.json`. No position/health/inventory/progression injection in this solo run. |
| Two local clients | 9/9 pass: two side-route climbs, distinct egg raids, shared guardian target, two physical cargo exits owning exactly once, one winner for a contested egg. `multiplayer-final.json`. Setup anchors/positions characters in bounded steps to mountain entry, then unanchors before ordinary movement/remotes on changed routes. It does not establish multiplayer home approach or hosted persistence. |
| Phone simulator | Samsung Galaxy A06 landscape705×338, touch enabled, one HUD, six sections/bounds,18 checkpoints, three exits. `cold-phone-acceptance.json` and six matched image pairs. At home the first client-only probe saw17 unstreamed checkpoints while the server had18; after traversal the client passed18. |
| Cold identity/console | 77 source matches, preserved scene/terrain, no packaged QA. `cold-source-parity.json`, `cold-console.json`. Console contains the retained initial streamed-checkpoint QA assertion, not a new game-script error. |

Retained failures include the original sandstone walking trap, an idle post-reveal raid that correctly lost cargo, and earlier multiplayer fixtures that cut across raised home edges or were rejected by the existing movement validator. QA changes never alter home geometry, encounter rules or movement. The simulator is reset to the default viewport after testing.

Reproduce from the durable checkout:

```powershell
python mountain/tools/quality_session.py regression --name final-regression
python mountain/tools/quality_verify_place.py outputs/ClimbCollect.MountainQuality.Review01.rbxl
python mountain/tools/quality_delivery_check.py
```

Studio probes live under `mountain/tools/quality_*`. Use an isolated review, remove multiplayer injections and restore HttpEnabled afterward; never save fixtures into the deliverable.

## Performance and limits

Matched desktop samples use1365×768 and120 RenderStepped frames/view. Baseline medians16.62–16.72ms; final16.56–16.68ms. Baseline p95≤17.94ms; final≤18.25ms. Whole-view observed render cost grows122,270→307,622 triangles and256→304 draw calls. Saved instance count grows6,071→10,595. Detail is materially more expensive even though these desktop samples remain near60fps.

`performance-comparison.json` contains all seven pairs. A repeat supports regional frame timing; its incompletely streamed whole view is excluded. A client-only tiny-mesh experiment was rejected because background throttling/streaming confounded measurement and was never saved. Render counts depend on residency and are not guaranteed full-scene budgets. Physical low-end phone/GPU/memory acceptance remains required. Six simulated phone views establish layout/readability evidence only; the existing HUD occupies much of the small landscape viewport.

No hosted save, physical-device, real-network-latency or owner aesthetic acceptance is claimed. Human pacing, art polish and combined-place integration remain review gates. This review does not incorporate later creature/home changes.

## Integration and records

Apply the three-file manifest in place on a saved copy of the latest combined place. Do not replace another chat's place with this older snapshot. Do not destroy the root or run the old generator to upgrade it: `FreeClimb.build()` clears terrain, and baked roots normally bypass it. Preserve that copy's own terrain authority and re-run acceptance.

Project/vault record and graph refresh results: `records-refresh.json`. Graph coverage is the navigation repo/vault, not this isolated implementation. Existing unresolved graph candidates remain explicit.

## Execution rulings

1. Use a durable clone of the newer active feature repository rather than a managed worktree of the older navigation repository. This protects the sprint baseline; cost is explicit later integration across roots.
2. Execute the approved brief without repeating interviews or phase approvals, as requested. Cost is that final aesthetic acceptance remains the owner's review gate.

Independent branch review and any deferred findings: `final-review.md` in the evidence folder.
