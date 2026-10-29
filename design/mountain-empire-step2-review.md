# Mountain Empire Step 2 — eight lodge review

2026-10-24. Built within the owner's explicitly authorized Step 2 scope; STOP for owner visual review. No next phase is authorized by this record.

## Authority and preserved layout
Owner accepted the enlarged Step 1 layout and requested eight finished Enchanted Alpine starter lodge exteriors. Latest dimensions in design/mountain-empire-step1-revision2.md override the original phase blueprint: eight 180 × 220 plots, seven 8-stud buffers, total frontage 1496, 60-stud front walking space. Lodge footprint centers remain X=-658,-470,-282,-94,94,282,470,658 at Z200, within 35 × 30 each, facing negative Z. Three centered gates, terrace and ramps are unchanged.

Architecture choices made within delegated scope: exposed cedar/timber, stone plinths and chimney, tall glass panels, layered teal slate roofs with brass seams, braced covered porches, hanging crest and two small enchanted lanterns. Same geometry on all eight estates, numbered 01–08. Open 5.8-wide × 9-high entrances and empty walkable shells; no interior facilities, gameplay or landscaping added. These visual choices await owner acceptance.

## Saved artifacts
- Review: redesign/step2/MountainEmpire.Step2.Lodges.Review.rbxl
- Matching final checkpoint: redesign/step2/MountainEmpire.Step2.Lodges.Checkpoint.rbxl
- Both 77,292 bytes; SHA256 51c65eb2e6eddb94473e46b2d25d9631b912259f599b8313566d9d3d0234b597.
- Unmodified starting checkpoint: redesign/step2/MountainEmpire.Step2.BeforeLodges.Checkpoint.rbxl, SHA256 0739107ebf395d077f4733d8410b23ce99d3cb080c3fa504ade5d79338f7daba.
- Build source: redesign/step2/build-lodges.luau. Guarded against running twice. Only run on a separately saved copy of the enlarged Step 1 place. Never run old seed, final-massing or revision2 resize on this file.
- Evidence: lodge-player-level.jpg (close front view), aerial.jpg (all eight), aerial-clear.jpg (higher overview), lodge-rear-clear.jpg (side/rear). lodge-rear-detail.jpg is an occluded preliminary camera view retained as history.
- Verification: geometry-audit.json, avatar-walk.json, saved-file-audit.json, verify-lodges.luau and audit_saved.py in redesign/step2.
- Studio window was verified by its full path; MCP instance c8636028-dbe5-4739-bafb-cd6a41faa663 still reports the historical Blockout name. Re-enumerate before future work. Other Studio instances were left alone.

## Verified evidence
- Eight models, 126 anchored primitive parts each; 1,008 added parts. Total 1,171 includes 163 original parts. Forty lodge marker parts remain hidden and non-colliding; all 123 other original layout parts match their starting CFrame, size, color, material, collision and transparency.
- All 8,064 lodge part corners fit inside each authorized footprint. Overall visible geometry bounds approximately 34.1 × 23.18 × 29.65; footprint reference remains centered Z200.
- Eight plot dimension/location assertions; 240 avatar-sized entrance clearance and floor samples; 380 front walking surface raycasts passed.
- Corrected test assumption: existing front walking surface is Y0.16, not Y0. The initially failed assertion was corrected against observed unchanged source geometry; no layout edit was needed.
- Actual R15 avatar from natural Plot07 spawn completed six MoveTo legs: approach → steps → doorway → interior → doorway → courtyard. No teleport/position injection. This tests one physical lodge traversal; all eight identical layouts have static clearance checks.
- Zero LuaSourceContainers in Edit mode. No gameplay scripts, particle emitters or dynamic lights were added. Only decorative SurfaceGui estate numbers. No publishing.
- Saved binary audit confirms 1,121 Parts + 42 WedgeParts + 8 SpawnLocations, eight Lodge names, eight CrestHangers, zero scripts. Streaming enabled.
- Final review/checkpoint hashes match. All 29 original root place hashes match the recorded baseline. Original Step1 review/final checkpoint and revision2 review/checkpoint match their documented hashes.
- Verification skill applied. Saved file checked through binary parsing; no reopen test claimed.

## Limits and next gate
STOP for owner visual review of these eight lodges. General landscaping, finished gates/mountain and future gameplay remain deferred. Physical mobile, controller, eight-client performance and human usability remain unverified; no new performance measurement claimed. Local Players.MaxPlayers still reads 12; intended hosted capacity 8 remains unresolved and was not changed through publication.

The scene retains the approved enlarged blockout surroundings, intentionally unfinished outside the lodge scope. The long outer-plot journey to central gates is unchanged.


## Owner acceptance — 2026-10-24
Owner said "Looks good" for the eight lodges and explicitly requested a new chat for controlled Step3 environment work. This supersedes the pending lodge-review status above. Step3 evidence and its separate stop gate: design/mountain-empire-step3-review.md.
