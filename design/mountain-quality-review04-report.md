# Mountain quality — Review04, October 26, 2026

Review04 replaces repeated oval rock stacks with asymmetric textured cut faces, adds fuller branching canopies and clustered understory, reshapes mineral growth, and gives each of the six sections larger authored landmarks. The outer terrain silhouette and tested collision are preserved. This is a local art improvement with explicit remaining aesthetic and hardware limits; no publication, purchase, merge or push occurred.

Playable: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.MountainQuality.Review04.rbxl`.
SHA256: `b0ae05855a36c6623b5cb8cd7bcae8f7cb90bdbcf4f75bfe9cd249c7529129e3`.
Gallery: [26 matched pairs](../evidence/mountain_quality_2026-10-26/review04-comparison.html).
Audit: `python mountain/tools/quality_review04_delivery.py delivery`.

## What changed

Only `mountain/world/MountainQuality.luau` changes runtime behavior relative to Review03/e22b924. Version4 prepares one local CSG rock prototype, then clones it for tilted masses, fractures, shelves and crown stones. Primitive inputs produce local PartOperations; no external meshes, uploads or purchases are used. CSG preparation happens before any region is replaced, and temporary inputs are cleaned on failure.

| Section | Review04 work | Remaining visual limit |
| --- | --- | --- |
| Blossom Gardens | Fuller five-cloud branching crowns, unequal planted beds, understory, broad hewn shoulder. | Much of the middle slope is still bare; canopies remain stylized lobes. |
| Azure Falls | Exposed waterfall lip, perched source, paired water curtains, rimmed basin and foam; clear foreground. | Falls are best seen obliquely; water remains static stylized geometry. |
| Sunstone Desert | Laterally stacked erosion layers and a broad opposing sandstone shoulder. | Large regular terrace and upright succulent silhouettes remain. |
| Violet Crystals | Paired tapered facets meeting at a ridge, restrained veins and a clustered geode base. | Broad purple slope still dominates; crystal grouping is stylized. |
| Inferno Heights | Leaning basalt fins, talus and asymmetric dark shoulders around restrained seams. | Large flat bands still read more engineered than volcanic. |
| Astral Crown | Five hewn crown stones around a luminous crystal, low snowy foreground. | Foreground left rocks partly hide the focal opening from the ascent camera. |

Noise-based surface color replaces cell-by-cell checker variation. Ascent/escape colors share the surrounding biome instead of a strongly contrasting strip. A straight lane seam and six broad colored bands remain; diagonal outer shelves do not conceal the long middle terrace boundaries. A proposed banded soil blend was rendered, rejected and reverted (`review04-rejected-banded-soil.jpg`). A rounded Head-mesh rock experiment was also rejected. No final owner aesthetic acceptance is implied.

## Physics and preservation

The independent review caught a real mistake: visual Material changes also changed default route physics. The corrected audit reproduced26 physical-property mismatches before the fix. Version4 now keeps Review03 Rock properties for OpenAscent and Ground/biome properties for DownhillLane, retaining any existing custom properties. This handles both a v3 baked upgrade and a fresh generation. All996 mountain colliders, including929 regional colliders, retain their transforms and effective physical properties. Surface color changes alone were not sufficient evidence of physics preservation.

Cold-open evidence verifies3,964 exact mountain BasePart records (379 more than Review03),9,925 scene checks,792 grounded planting contacts (maximum error0.00005863 studs), unchanged protected scene and Lighting,77 source matches and all70 original Terrain payloads. Exact saved Review03 text was extracted from its binary Text properties:58 current label instances match. Historical MCP snapshots had corrupted Unicode bullets/arrows; the audit validates current labels against that binary authority before excluding Text from the old snapshot comparison. It does not normalize actual scene errors away.

Native save changed Materials, PhysicsGrid and SmoothGrid despite no intentional Terrain edit. The final file restores these three payloads from the immutable Review03 authority; all other1,697 chunks remain byte-identical to the native checkpoint. Both native checkpoint and terrain audit remain available. The final restored file was cold opened, including visible CSG faces, and the full scene/physics checks rerun.

Review01 and Review03 remain unchanged. No protected runtime, creature art, sprint, home-base, custody or entrance source changed. The runtime package's integration scope remains the two helpers and one FreeClimb build hook established earlier. Never destroy the baked root or invoke FreeClimb.build to upgrade: it clears Terrain. Apply only to a separately saved current combined place after reconciling newer source and preserving that copy's own terrain authority.

## Cost and phone readability

Controlled same-process foreground new-old-new scenery swap: Level10, FOV60, seven cameras,120 frames per view, full residency. Overview opaque triangles122,806→209,598 in both repeats, a70.67% increase. Overview opaque draws36→34, but section draw counts are mixed. Runtime mountain parts3,689→4,068. Desktop medians16.52–16.73ms are capped near60Hz; this is not a hardware performance approval or an FPS improvement. Terrain LOD differs across some samples, so opaque geometry is compared separately. A background-throttled sample is retained and rejected. This art pass trades geometry cost for larger, less repetitive forms.

Twenty current-session desktop before/after camera pairs cover the whole mountain and all-six ascent, terrace and escape views. Six further pairs use Samsung Galaxy A06 landscape Studio simulation (game LandscapeSensor), terrain-only editor views without live UI. They show improved rock silhouettes but sparse central areas and smaller plants disappearing at phone scale. A failed orientation-before-device call was corrected; final phone images have verified sub900-pixel width. Studio was reset to its default viewport. An additional live-UI phone capture retains the unchanged map/creature panel, which covers much of the center; camera movement alone does not place the avatar in that encounter. Physical phone/GPU/memory/battery and live thumbstick/encounter UI acceptance remain unverified.

## Validation status

Fresh26 CLI suites /100,543 assertions and77 compiles pass. Cold scene and physics audits pass. Fresh cold gameplay passed120 raid/cargo/exit/hazard steps in321.03s and165 natural all-six walk/sprint steps in330.63s with12 real keyboard jumps showing takeoff, airborne motion and landing. The full delivery audit passes. Historical nine multiplayer checks were not rerun; unchanged multiplayer runtime/collision is recorded, not substituted for a fresh test.

Independent review findings, failures, fixes and exact evidence paths are in the [ledger](mountain-quality-review04-ledger.md). Owner aesthetic/human pacing, physical hardware, hosted persistence/network and integration into the latest combined place remain open. Navigation/vault graph freshness is tracked separately and does not cover this isolated runtime checkout.


Retained test-runner failures: the first traversal stopped at step74 because the external runner missed Space between monitoring batches; its target was reached but no jump state occurred. Continuous monitoring completed165 steps/12 jumps, but the detailed-log export exceeded a tool argument limit. A further full continuous run passed and its complete59KB log was saved in bounded chunks before stopping Play. No game behavior changed to pass these tests.


Records were byte-backed up before five append-only updates. Supported graph refresh completed with a verified full vault backup and versioned export2026-10-26-125813; final status CURRENT with zero intended-input drift. Retrieval benchmark recall@8=1.0, MRR=.75, unchanged. Existing unresolved graph review candidates remain in QUALITY_REPORT. Exact status/coverage and quality report: evidence/mountain_quality_2026-10-26/review04-records-refresh.json.
