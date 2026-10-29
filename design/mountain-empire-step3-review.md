# Mountain Empire Step 3 — environment review

2026-10-24. The owner accepted Step 2's eight lodges ("Looks good") and authorized this separate controlled environment step in a new chat. That acceptance supersedes Step 2's historical pending-review wording. **Step 3 is now saved for visual review; STOP.** No further step is authorized by this record.

## Scope and preservation

Added seven segmented natural boundaries within the existing 8-stud buffers, planted retaining terraces, 96 stylized pines, boulders, small Alpine flowerbeds and lanterns, two static stepped waterfall accents, timber/teal/brass gateway detailing and a sculpted snow-tipped terrain vista. Daylight remains bright and readable. Decorative foliage, cladding and water are non-colliding; boundary stone segments are collidable. Water is static decorative geometry, without animation/audio. The mountain is scenery, without progression or authored traversal.

Eight owner-approved 126-part lodges remain unchanged. Eight plots remain 180 × 220, centers X=-658,-470,-282,-94,94,282,470,658, seven buffers 8, frontage 1496. Rear lodge footprints remain 35 × 30 centered Z200 facing negative Z. The 60-stud front walking surface, terrace Y16, ramps, stairs and three-gate alignment are preserved. No shared facilities, creatures, habitats, gameplay, commerce or publication were added.

## Saved files and reproducibility

- Review: `redesign/step3/MountainEmpire.Step3.Environment.Review.rbxl`.
- Matching final checkpoint: `redesign/step3/MountainEmpire.Step3.Environment.Checkpoint.rbxl`.
- Both 420,269 bytes; SHA256 `4f0a0176c718aeb35ad8852927d6ff599ce2f1de78d701f3ec6bdfd888e088af`.
- Pre-build checkpoint: `redesign/step3/MountainEmpire.Step3.BeforeEnvironment.Checkpoint.rbxl`, exact approved Step 2 bytes/hash `51c65eb2e6eddb94473e46b2d25d9631b912259f599b8313566d9d3d0234b597`.
- Reproduce on a fresh, separately saved Step 2 copy, in order: `build-environment.luau`, `refine-vista.luau`, `polish-waterfalls.luau`. Never run the old Step1/resize/Step2 generators on approved places. Build scripts are local source only; none are stored in the place.
- `verify-environment.luau` uses the protected-part baseline created by the build in that Edit session. The checks cover geometry, material, color, transparency, collisions, query/touch flags, anchoring and reflectance.

## Verified evidence

- `geometry-audit.json`: 1,133 original protected parts unchanged; 8 plot assertions; 240 entrance clearance/floor samples; 648 open courtyard clearance/floor samples; 1,125 front walking-surface/clearance samples; 72 gate passage/floor samples. Front walking surface is Y0.16. All passed after final art corrections.
- `avatar-walk.json`: 13/13 actual natural-spawn R15 MoveTo legs passed from Plot07 through courtyard/front walk, west ramp/gate, center gate/stairs, east ramp/gate. No position injection or teleport. This is automated physical navigation, not human usability acceptance.
- Desktop RenderStepped sample during initial courtyard walking: 902 frames / 15.0327 seconds, average 60.002 FPS, worst 21.482 ms. Taken before final non-colliding pine orientation/water-sheet corrections; no post-correction performance measurement claimed. No physical mobile/controller/eight-client certification.
- Final scene: 3,731 anchored BaseParts, zero LuaSourceContainers, zero added dynamic lights or particle emitters. Streaming remains enabled. Terrain is generated in 544 yielding chunks outside the approved courtyard/front-walk area.
- `saved-file-audit.json` / `audit_saved.py`: saved binary parses, final part count and eight lodge/crest names present, old mountain massing absent, terrain SmoothGrid payload present, zero scripts, review/checkpoint byte-identical. All 29 original root place files, original Step1 review/checkpoint, enlarged Step1 review/checkpoint and approved Step2 review/checkpoint hash-unchanged. No reopen verification claimed.
- Studio was re-enumerated; full window path verified before Save As and final Save. Target MCP id `c8636028-dbe5-4739-bafb-cd6a41faa663` still reports its historical Blockout name. Other Studio instances were left untouched. HTTP disabled before save.
- Screenshots: `aerial.jpg`, `gateway-player-level.jpg`, `lodge-and-boundary.jpg`, `buffer-detail.jpg`, `terrace-waterfall.jpg` in `redesign/step3`.

## Corrections and remaining limits

Visual inspection rejected preliminary wedge mountain masses in favor of continuous terrain. CornerWedge bough orientation required a net +90° local rotation, now reflected in reproducible source. Cascade sheets were moved in front of retaining faces and connected to pools. The first final save shortcut was not delivered because user input changed focus; the binary audit correctly detected the unchanged Step2-size file. After refreshing/activating the verified window and saving, the audit passed at 420,269 bytes.

Local Players.MaxPlayers still reads 12. Intended hosted capacity 8 remains unresolved; no publication was used to change it. Long outer-plot travel remains as documented in the enlarged-layout review. The open courtyards intentionally remain empty for future construction. Owner visual acceptance of this environment is pending. **STOP for review; do not automatically proceed.**

Graph status was CURRENT at session start. Project/vault pointers are updated; run the standard freshness status after this record's final refresh to establish current drift.
