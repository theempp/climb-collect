# Mountain Empire — Step 1 review

2026-10-24. STOPPED after full-server spatial blockout. No approval for Step 2 is implied.

Authority: GitHub `theempp/climb-collect`, approved `design/phase1-multiplayer-environment.md` (blob `8e1c1c238e9df763e0ccc91b1248dead26a1a631`) and the user's narrower Step 1 request. The older lobby/four-mountain plans do not govern this separate redesign.

## Review files

- `redesign/step1/MountainEmpire.Step1.Review.rbxl`: final Studio-saved binary, 67,698 bytes.
- `redesign/step1/MountainEmpire.Step1.FinalCheckpoint.rbxl`: identical final checkpoint.
- SHA256 for both: `e9b6773cbae26848e0592c0c862d00f28d2af690dcfcac7bcda3364cacc315ff`.
- `redesign/step1/aerial.jpg`, `player-level.jpg`, `gates.jpg`: actual Studio captures.
- Seed XML and its checkpoint remain intact. `tools/mountain_empire_step1.py` creates the seed only; `redesign/step1/final-massing.luau` records the final Studio refinement. Do not rerun that refinement on the final place (not idempotent).

## Verified geometry

172 anchored primitive parts, no gameplay scripts. Eight level 110×120 plots at X=-413,-295,-177,-59,59,177,295,413; Z=0..120, walking surface Y=0. Seven 8-stud buffers; total frontage936. Rear lodge footprints35×30, centered Z100, left as footprint markers deliberately. Courtyards remain open.

Three accessible gate structures centered as a group at X=-72,0,72, Z=-91. Overall widths45/60/45; clear openings35/50/35. Gate terrace walking surface Y16. Two20-stud-wide ramps rise16 over48 horizontal studs (18.435 degrees). Central40-stud-wide stair has32 risers of0.5 and treads1.5. Essential12-wide access lanes connect fronts to ramps; no social promenade/plaza or extra facilities. Basin terraces and mountain masses are blockout geometry only, not finished landscaping.

## Evidence and limits

Studio dimension assertions passed:8 plots,7 buffers,172 parts,0 scripts,PlaceId0. Saved binary audit confirms154 Parts+8 SpawnLocations+10 WedgeParts and streaming enabled. All29 preexisting root `.rbxl` hashes match their recorded starting values. Existing lobby play session and original places were not modified.

Actual standard-avatar navigation from natural spawn reached the access lane, east ramp and gate. Further movement checks passed central stairs down/up, central gate, west gate terrace and west ramp descent:13 successful MoveTo legs, no position injection. Evidence: `redesign/step1/nav-evidence.json` and `extra-evidence.json`. This is automated movement, not human usability or eight-client testing.

Foreground Studio300-frame sample:59.997FPS average,18.346ms worst,5.000seconds (`foreground-performance.json`). Earlier hidden/background Studio sample was15FPS /68.595ms worst and is retained in `extra-evidence.json`; it is not a physical-device result. No claim of mobile certification or8-client stress testing.

**Capacity limitation:** local Roblox `Players.MaxPlayers` reads12 and is read-only through scripting; the attempted seed XML setting did not establish8. The spatial target is8 plots/spawns and `Workspace.IntendedServerCapacity=8`. Hosted server capacity still needs configuration when separately authorized; no publication or cloud changes were made. The game is unpublished,PlaceId0.

**Travel tradeoff for review:** along the marked access route, plot front to nearest gate is approximately107,199,317,435 studs from inner to outer pairs (6.7,12.4,19.8,27.2seconds at16 studs/sec). From spawn near the rear, add roughly4.75seconds. These are geometric estimates, not timed human runs. The long horizontal row and centered gates inherently make outer plots farther away.

Independent read-only review found no blocking geometry or scope defect, and emphasized capacity, travel distance and device testing limitations. It reviewed the earlier background performance evidence; the later foreground result above is separately recorded.

## Next gate

User visual review of Step1 only. Detailed architecture, landscaping, gameplay and publishing remain unstarted. Review the outer-plot travel distances and scale before authorizing any next step.

