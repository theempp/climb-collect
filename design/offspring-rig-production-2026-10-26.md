# Offspring rig production — October 26, 2026

Owner authorized rigging/animation of all 25 offspring and isolated Studio tests with their 25 matching eggs. Preserve v002, originals, current game builds and catalog. No game publication or reward migration.

Working output: `C:/Users/HOME!/Documents/Codex/2026-10-26/offspring-rig-production/Collection-v003/`.
Plan: `docs/superpowers/plans/2026-10-26-offspring-rig-production.md`.

## Verified intake and first pass
Graph CURRENT at intake, zero input drift. External production and isolated mountain runtime are outside the graph's input scope. Hashes cover all 1,381 v002 files in `evidence/v002-hashes.json`; all 25 input pairs copied to v003. No v002 files intentionally changed.

First rig pass: all 25 have source rigs, three weighted LODs, Idle/Move/Reveal/Carried clips, FBX and GLB. 25 structural contracts and 150 fresh portable imports passed. This is NOT visual acceptance: five motion sheets revealed detached details and overlap-sensitive weight transfer. First-pass sheets/scripts preserved in `evidence/first-pass/`; corrections underway.

## Real Studio pilot and corrected assumptions
Separate `ClimbCollect.OffspringRig.Review01.rbxlx`, PlaceId 0, session `a30ab95d-af08-4999-bd8e-d9f99ae7fd03`. Existing mountain/home sessions untouched. Imported first-pass blossom rabbit: 14 bones, four local KeyframeSequences (Idle/Carried 2s, Move 1s, Reveal 1.5s). In Play, local Animator tracks load/play and sampled head/limb Bone.Transform values change. These are provisional art durations.

- Unchecking Upload to Roblox suppresses the model inventory upload, but does not suppress backing mesh/texture creation. Pilot mesh `74623102514645`, texture `102314327305080` were created by Studio. Asked owner for explicit remaining backing-asset permission; pending. No further asset imports while pending.
- FBX default import measures 100 times authoring units. Review Model scale .01 is illustrative; no game scale approved.
- Imported scene-origin PivotOffset rotates the model if reset indiscriminately. Review setup uses an upright mesh frame and bottom pivot.
- Imported KeyframeSequence top pose named Rig must be rebound to the actual MeshPart name for root bone motion. Limb/head channels played even before that repair.
- Blender GLB importer creates a bone custom-shape Icosphere; this is not a mesh in the GLB. Independent verification excludes only objects explicitly used as bone custom shapes.
- First-pass weight transfer by nearest source vertex crosses overlapping surfaces. Corrections preserve connected-part semantic identity and cranial/ornament attachments. Bone-local hop translation also needs conversion from world Z-up.

Still open: corrected all-species motion review, final reimport checks, remaining Studio imports/playback/hatches/carry/performance/emulation, upload permission, owner art acceptance and physical-device testing. No completed rig delivery claimed at this checkpoint.

## Local candidate milestone — 2026-10-26

Supersedes the local-work items in the preceding checkpoint. All25 corrected local rigs now have editable sources, 3 skinned LODs, four clips, FBX/GLB and 125 sampled pose renders. Five family sheets reviewed; focused corrections address cranial seams, pangolin nose, moth wing folding, amphibian/toad limbs and tails, ray ornaments, scorpion stinger and bone-local hop direction.

Final evidence in external `Collection-v003/evidence/`:
- `rig-roundtrip.json`: 150/150 fresh FBX/GLB imports pass, including linked atlas color/roughness, four clip names, normalized weights and sampled Move deformation.
- `saved-rig-portability.json`: all75 saved LOD Blender files contain packed linked color and roughness images.
- 25 rig contracts pass; attachment semantic tests pass. `input-preservation.json`: all1381 v002 files remain hash-identical.
- Five `*-motion.jpg` sheets cover125 sampled poses. These are sampled visual checks, not every-frame/angle acceptance.
- `studio-pilot.json`: actual first-pass rabbit import only. Saved local Review01 and PilotBoundBackup retain the corrected clip root binding. No final candidate/all-species Studio claim.

Independent read-only reviewer found two Important defects, both corrected: GLB material channel routing lost roughness on FBX export (regression test observed failing then passing); the first repair's unpacked absolute roughness image dependency was fixed by packing. Reviewer independently compared50 cross-LOD skeleton/clip combinations with zero differences, and all four rabbit clips against source bounds at seven frames in FBX/GLB (error <1e-6). No remaining Critical/Important source finding after repairs. Final full150import and75packed-blend checks passed after the repairs.

Rulings: review scale and durations remain illustrative, because owner approval is absent; production use would require retuning. Headless/local verification cannot substitute for actual Studio, so remaining platform work stays incomplete. Existing v002 art is retained; salamander dorsal flames already float above its tail in the baseline and remain an owner-art question.

Deferred minor review findings: the automated verifier evaluates Move rather than every clip/frame (rabbit has independent four-clip spot checks); inherited salamander dorsal flame placement; review carry helper is a single placement and must be called repeatedly for a moving character. These are not completed gameplay integration.

Open gate: owner permission for remaining Roblox mesh/texture backing assets. Then import all25 final creatures and25 matching eggs, test hatch/carry/skinning/materials, measure concurrent playback and phone emulation. Owner aesthetics, final scale/timings and physical-device testing remain separate. No game publication, catalog migration or existing-place changes. Prepared75 uniquely named FBX inputs live in `studio-import/`; preparation made no uploads.

## Authorized Studio continuation — 2026-10-26
Owner explicitly approved creation of the remaining Roblox test backing assets. Import batch uses OffspringReview_NoModelUpload preset: model Upload disabled, Add to Workspace enabled, anchored. All75 prepared FBX files queued in the isolated review place; no further permission gate for these test assets. Platform QA underway.

## All-species Studio milestone — 2026-10-26

Owner approved backing mesh/texture creation; that gate is resolved. All75 inputs imported in the isolated review:25 creatures atLOD0,25 intact eggs,25 split hatches. All100 MeshParts have SurfaceAppearance color and roughness maps. No published game, model inventory upload, marketplace listing or production catalog change.

Actual Play checks pass for all100 clips: nonzero loaded length, playing state and changing Bone.Transform rotation matrices. Studio removes zero-weight bones from nine species. Crab and beetle Carried originally animated only unweighted heads; added .012-radian Body breathing in their editable source/three LODs and equivalent local Studio keyframes. Fresh150 FBX/GLB imports and75 packed-texture saved blends pass after repair. Small-angle ToAxisAngle checks missed subtle motion; matrix-component comparison corrects the test. Animator automatically scales FBX pose translation with Model scale.

All25 hatch adapters use the saved source frame/hinge audit converted from Z-up to Y-up. Closed bounds differ from intact eggs by at most .016978 illustrative studs; bases stay fixed; lids move; resets are exact. Evidence: external Collection-v003/evidence/studio-hatch.json, studio-import.json, studio-playback.json and carried-breathing-repair.json.

Carry findings: all25 collision/touch/query flags disabled; moving avatar follow error below1e-6 studs over121 rendered frames and7.62studs travel. Authoring scale is not carry-fit acceptance: conservative rest bounds overlap the custom avatar. A centered1.8stud-longest-bound review candidate still intersects head bounds for rabbit,hare,owl,lynx,ram and orchid bird. This is a documented final scale/offset/avatar coverage gate; rest bounds are not exact animated vertex clearance. The demo updates the carried model every frame, resolving the old helper's one-placement limitation.

Foreground desktop Studio with25 animatedLOD0 creatures and all eggs:120 samples,mean16.663ms,p95 17.763ms; stopped mean16.671ms. Fixed view approximately774k rendered triangles including shadows and113drawcalls. Prior background sample was15FPS throttled and is not usable as performance evidence. Physical phone performance and production LOD thresholds remain open.

iPhone17Pro and GalaxyA06 landscape emulation inspected. Review controls provide selection,clips,hatch,carry and collection view; actual selection/hatch/carry clicks verified. Removed phone touch movement overlay that covered the All button. Galaxy viewport705x338, all six controls fit; console empty. Studio restored to default viewport after tests. Evidence: studio-phone-rabbit-hatch.png, studio-phone-carry.png, studio-galaxy-a06.png.

Saved final local place: C:/Users/HOME!/Documents/Codex/2026-10-26/offspring-rig-production/ClimbCollect.OffspringRig.Review02.rbxl. Earlier pilot files preserved. All1381 v002 input hashes still match. README-RIGS.txt and rig-manifest.json supersede earlier pending-permission/pilot-only status.

Remaining acceptance: owner aesthetics, inherited salamander dorsal flames, final game scale/clip timing/carry fit, physical device performance, separately uploaded Studio LOD1/2 and production catalog/saved-species integration. Those are not implied by this isolated LOD0 test milestone. Current sources and evidence remain authoritative; external assets are outside graph input scope.

## Saved delivery verification — 2026-10-26

Final Review02 cold-reopened after the clip-selection UI correction:75 models,100 clips,100 mesh parts with color/roughness;100 actual Play clip tests and25 hatch tests pass again; console empty. Studio automatically migrated Compatibility lighting to Voxel on reopen; saved the migrated local revision and repeated timing: animated mean16.671ms,p95 17.526ms,stopped mean16.669ms. Opaque pass stays764862triangles/104drawcalls; total/shadow/postprocess counts vary by frame. Evidence: studio-cold-reopen.json and studio-performance-final.json. Actual Clip then Next control test retained Move and loaded the rabbit's1second playing track.

Final place SHA256: dc19fcea61439d7d1732af4bdf1b6c3f9c225f1dfc03d5bd5f4b1075e75040a1;3,415,080bytes. Original pilot, earlier backup and final backup preserved. Package includes the place at studio-review/ClimbCollect.OffspringRig.Review02.rbxl.

External Collection-v003-studio-tested.zip:1,945files,409,674,321bytes,CRC PASS,SHA256 d3c120737e1e543f0bea38cff8bac57bad69babedc06dd2e67f67b881f5377c2. Evidence: parent studio-tested-archive-verification.json. Source rig contracts and1381 v002 hashes rechecked at delivery. Original local-candidates archive preserved. Vault milestone/open-question notes appended after backup in record-backups/studio-tested-20261026. Isolated production/test scope delivered; listed final game/art/device acceptance remains open.




## Supported carry revision — 2026-10-26

New external Collection-v004 and ClimbCollect.OffspringRig.CarryReview03.rbxl replace only the isolated carry preview. Preserves authored origin;25 species poses/scales, sampled underside palm contacts, avatar hand spacing, analytic R15 arm joints and torso following. Tall silhouettes recline; flame-moth Carried wings fold further in source/all3 LOD FBX+GLB and saved Studio keyframes. Next/Previous retain carry; View cycles four angles; release/respawn clean up. Unreachable or incomplete avatars reject before mutation. No production catalog/runtime or other Studio place was changed.

Verified:25 species x4 avatar configurations (custom at0.8/1/1.2 plus stock block R15),25 animated LOD0 samples each, zero inset-OBB intersection candidates and reach errors. All species inspected front/side in41 saved PNGs. Cold-reopened movement test passes25 unique species with Carried playing, horizontal travel/speed, reversal and jump ascent; max palm-target error0.00006513studs. Cold100 clips and25 hatches pass; actual Carry/Next/View/release controls and respawn cleanup pass; console empty. Saved adapter/profiles/player/25 surface modules match local source. Moth6 fresh exports and4 source-loop checks pass;25 rig contracts pass. Independent review important findings repaired.

Evidence: C:/Users/HOME!/Documents/Codex/2026-10-26/offspring-rig-production/Collection-v004/evidence/carry-fit/delivery-verification.json, cold-movement-runtime.json, cold-source-parity.json, ColdPlayback.json, ColdHatch.json, respawn-cleanup.json, independent-review.json and final recheck-* clearance reports. Saved place3,504,544bytes SHA25618714520b91dc4df800bc8d6ff38d420ceb426fc8611b7db5d630c1e1fa10b8f; backup/package copy identical. All1381 v002 hashes and original Review02/v003 archive hashes match.

Corrected assumptions: fixed longest-bound shrinking and generic offsets do not establish support. Require-cache replacement and competing fitting callbacks invalidated early audit runs; final recheck files use fresh modules and one fitter per avatar. Movement checks now use timed paths after default controls, assert horizontal travel/jump ascent, and avoid the display area; early failed harness runs are not acceptance evidence.

Scope limits: sampled animated vertices vs .025*ratio inset avatar boxes plus visual review are not continuous triangle-level proof or all-body/accessory support. R15 only; tiny breathing contact gaps remain possible. Inherited salamander dorsal flames, owner art/scale/timing acceptance, physical-device performance, production integration and other avatar proportions remain open. Prior v003 provisional carry overlap findings are superseded only for these tested configurations. External assets remain outside graph input scope.
