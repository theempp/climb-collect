# Mountain quality continuation — Review03, October 26, 2026

The continuation improves repeated planting, biome-specific ground accents, slope grounding and scenery cost across all six sections. It is a verified local improvement, not final aesthetic acceptance of the mountain. Broad ramp faces, rectangular terraces, repeated oval boulders and sparse vegetation still fall short of the sculpted-fantasy ambition. No purchase, publish, push, merge or combined-place replacement occurred.

## Current playable and comparison

- Playable: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review03.rbxl`
- SHA256: `eb77b97a1f69c4e24818196d60131c425e9413794bb939aa3983288fa8d44577`; 2,518,161 bytes; 9,226 saved instances.
- Gallery: `../evidence/mountain_quality_2026-10-26/review03-comparison.html`; matched Review01/Review03 overview, all-six ascent/terrace/descent and phone-simulator cameras.
- Evidence: `../evidence/mountain_quality_2026-10-26/review03-delivery-verification.json`, `review03-scene-audit.json`, `review03-file-integrity.json`, `review03-performance-comparison.json` and `review03-images.json`.
- Review01 remains unchanged at SHA256 `c3000ce9b6eb626098089719d5fa30503f7947aeb2252d6f151cb1ec0edee680`. Review02 and Review03.BeforePhysicsRestore are intermediate checkpoints, not the current delivery.

## What changed and why

Only MountainQuality.luau changes at runtime relative to aed37ea. MountainSurface and the existing FreeClimb hook remain unchanged. The full baseline integration scope remains two helpers plus that one hook. Version3 replaces five-legged repeated plants with low unequal sprays, agave leaves, amethyst shards, basalt scree and frost shards. Foreground placement uses clustered offsets instead of evenly spaced rows. Small flowers, foam, verge stones and succulents use simple geometry instead of many tiny spheres. Low outer-seam outcrops introduce neighboring rock palettes without obstructing the center escape, side routes or encounter apron.

An attempted angular replacement for the second rounded rock mass was rejected visually and reverted. Large rock silhouettes remain the previous rounded masses. This is a deliberate unresolved art limitation, not evidence that they are finished.

The independent reviewer found that smooth S.height samples differed from the visible triangular WalkSurface by about one stud at some new plants. The fix raycasts the actual generated WalkSurface and aligns/buries roots against its normal. The new scene grounding check failed before the fix and passes724 recovered plant-frame checks afterward, maximum error0.00005863 studs. The test was corrected to measure at the unburied contact point, avoiding false failures where a root offset crossed a triangle seam.

## Critical visual assessment

The original overall silhouette and Terrain are preserved. At a whole-mountain distance, the playable face still reads as six wide colored bands. The helper's shoulder profiles add local variation, but the long center stripe and terrace edges dominate. Adding more small props cannot solve that composition problem.

| Section | Current strength | Most important remaining weakness |
| --- | --- | --- |
| Blossom Gardens | Pink canopy landmarks, lower grouped leaves and a readable center climb. | Canopies look like flattened discs; planting is cleaner but insufficiently lush. Large blank slope patches remain. |
| Azure Falls | Teal vegetation and a clear waterfall landmark distinguish it from Blossom. | Water is still rigid transparent strips over repeated rounded masses; the waterfall lacks a convincing source and basin composition. |
| Sunstone Desert | Upright succulents and sparse agave suit a dry biome; sandstone recovery remains dependable. | Rounded rock stacks lack convincing erosion/strata; the terrace transition is abrupt. |
| Violet Crystals | Crystalline silhouette and purple accents are immediately distinct. | Large crystals remain regularly assembled rods/tips, with a repeated boulder-island arrangement and broad empty ground. |
| Inferno Heights | Dark basalt, small scree and restrained ember seams read clearly. | The layout resembles the other sections; ember strips and oval rocks do not yet form a convincing volcanic landform. |
| Astral Crown | Pale ground, frost shards and the crown arch provide a summit cue. | The arch is visibly assembled; small ground details disappear at phone scale and the summit needs stronger focal composition. |

Encounter sightlines remain open. The center downhill stripe is obvious and fast, but also looks engineered. The outer seam outcrops soften only the sides; they do not hide the rectangular middle terrace. Side-route footing, sandstone walking recovery and downhill movement passed physical traversal, not just geometry sampling. These results support retaining the tested collision for this pass; they do not close human pacing or aesthetic judgment.

The next substantial art work should compose larger asymmetrical rock shoulders and terrace-edge silhouettes across all six sections, with denser vegetation only where it improves composition and preserves sightlines. It should keep the existing outer silhouette and collision envelope unless a measured gameplay defect justifies a separate geometry change. Do not bury the center route under decorations to conceal its straightness.

## Performance evidence and its limits

The historical122,270→307,622 triangles /256→304 draw-call comparison was re-read, not treated as a current measurement. This continuation used a controlled same-process scenery swap: new→old→new, fixed Level10, FOV60, seven cameras,120 frames per camera, full residency on an unsaved fixture, and verified foreground focus. Streaming and quality settings were restored afterward.

For the final grounded version, overview opaque triangles are167,692 old versus122,806 in both new repeats:26.77% fewer. Mountain runtime part count is4,771→3,689 (1,082 fewer); baked mountain parts are4,667→3,585. All six section views also reduce opaque triangles. Draw calls are mixed: overview opaque draws36 old versus37/39 new, so there is no blanket draw-call optimization claim. Other views improve, stay level or rise by one.

Accepted desktop medians remain about16.6–16.8ms. This is a capped60Hz observation, not an FPS improvement. Terrain LOD still changed in some samples despite full residency, so totals with mismatched Terrain passes are excluded from the clean comparison. The matched overview old/new-B totals are243,930/199,044 with the same76,210 Terrain triangles, but the robust claim is the repeated opaque reduction. The earlier pre-grounding repeat and rejected background-throttled runs are retained separately. None is directly interchangeable with the historical wide-view camera/viewport. Physical-device GPU, memory, battery and thermal behavior remain unverified.

## Verification, preservation and failures

- Fresh full regression:26 suites,100,543 assertions,77 compiles pass.
- Final saved and cold-reopened mountain:3,585 exact BasePart records; all929 regional colliders match the previously tested layout; protected scene hash `37b24bd1f0831dafef6354b54d2b4e1229315a25e86ba69fe3b17047078e4101` and Lighting unchanged.
- Final cold geometry:9,546 checks pass. The count is lower than Review01's10,628 because1,082 decorative parts were removed; it is not a replacement count for the CLI surface suite.
- Final cold raid:120 steps pass, including natural climb, eight summit strikes, reveal/pickup, loaded24.3 speed, ownership3→4 only at physical exit, all-six hazards and sandstone walking-only recovery. Elapsed317.87s.
- Final cold traversal:165 steps pass in339.42s;12 actual Space down/200ms/up inputs each show takeoff, airborne motion and landing; normal16 walking /27 sprint and physical exit. Input trace and complete state logs are retained.
- Earlier nine multiplayer checks remain historical. Their relevant runtime and all929 colliders are unchanged, but this continuation does not claim a new multiplayer run.
- Final file has77 matching runtime sources, all70 exact Terrain property payloads, and no temporary QA scripts. Native save changed SmoothGrid and PhysicsGrid; the failed checkpoint/audit are retained. The final restoration changes those two payload chunks only and preserves all other1,618 chunks byte-for-byte, then the restored file is freshly opened and exercised.
- No other chat was messaged; protected Studio sessions and creature/sprint/home assets were not operated or edited. Fresh sprint authority recheck remains clean at a3e896ad624d966c75f57a1c692b58c5f0ef63a0.

Phone evidence is a Galaxy A06 landscape Studio camera simulation with matched viewports and requested scene residency, not a physical phone or a full thumbstick/encounter-UI acceptance test. The persistent map/creature panel occupies much of the middle of the phone frame, further limiting terrain readability; it was not changed because home/UI work is outside this continuation's runtime scope. Camera positioning alone does not put the character in that encounter's UI state. Owner art acceptance, physical devices, hosted persistence/network and integration into the latest combined place remain open.

The exact scoped integration instructions and current hashes are in `mountain-quality-integration.md` and `mountain-quality-manifest.json`. Original reports and their evidence remain historical. The navigation/vault freshness result is separately recorded in `review03-records-refresh.json`; graph freshness does not cover the isolated runtime source.
