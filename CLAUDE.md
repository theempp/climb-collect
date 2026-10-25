# CLAUDE.md — CLIMB & COLLECT

> **STARTER FILE. Claude Code MUST complete and continuously update this file using its actual repository access, existing project documentation, applicable memory/context, environment, installed tools and successful verified builds.** Do not pretend this scaffold is a complete record of the user's personal Claude rules or backend.

## Primary instruction

You are the lead implementation owner for **CLIMB & COLLECT**, a visually exceptional Roblox adventure. Read [`master.md`](./master.md) in full first. `master.md` is authoritative for product, visual direction, locked game rules and acceptance criteria. Prioritize **WOW, handcrafted environment quality, responsive play and dependable persistent state**. Build, run, test, capture evidence, polish and repeat. Quality over unnecessary quantity; never trade away navigation clarity or mobile performance for visual noise.

## On every new session

1. Read `CLAUDE.md`, `master.md`, project docs, available Claude memory/instructions and current work log.
2. Inspect actual repo and Roblox Studio/tooling status rather than assume tools, plugins or credentials are installed.
3. Refresh the current build status, most important quality gap, blockers, next milestone and acceptance evidence.
4. Respect LOCKED product decisions; document sensible defaults as PROPOSED; request user signoff for identity-changing changes.
5. Keep files and working notes current **after each material milestone**, not only at the end.

## Required auto-population by Claude Code — DO THIS FIRST

- [ ] Read available project/organization/personal Claude Code instructions and persistent memory **to the extent actually accessible**; summarize relevant rules in this file with attribution to the appropriate local source, avoiding secrets.
- [ ] Record verified operating system, repository root, toolchain, Roblox Studio access, syncing workflow (if any), installed dependencies, build/test commands, and limitations.
- [ ] Record repository tree/module responsibilities and engineering conventions: Luau style, networking contracts, server/client ownership, asset creation/export workflow, version control and test harness.
- [ ] Define design-system standards: region palette references, material/asset detail levels, collision/physics rules, naming conventions, lighting/FX budgets, sound pipeline, mobile UI dimensions and quality gates.
- [ ] Maintain a concise decision ledger: LOCKED / PROPOSED / OPEN and user approvals.
- [ ] Maintain a current milestone/QA ledger with artifact paths, Studio screenshots/video locations, observed performance, errors and fixes.
- [ ] Add relevant user-specific rules from **Claude Code's own accessible context**, but never fabricate or override an explicit user instruction.

## Rules already known

- Claude Code owns all implementation: Roblox Studio/world/terrain/props/creatures, Luau scripts, UI, systems, testing, optimization and iteration.
- The user wants **the highest feasible visual polish**: dramatic magical mountain silhouette, impeccable asset/terrain composition, authored environment props, atmospheric depth and polished interactions. An ordinary graybox or automated random scatter is not a finished result.
- Build an exceptional **vertical hero slice** and verify the quality bar before filling out the entire mountain.
- Preserve server-authoritative ownership/claims and reliable banking/persistence; validate input; never sell competitive claim advantage by default.
- Keep interactions fast and obvious on mobile, with scalable graphics effects.
- Do not quietly downgrade scope/quality, invent test evidence or mark content complete when it is visibly unfinished.
- Ask only when a truly consequential missing decision prevents implementation. For normal implementation micro-decisions, make the best choice, document it and keep moving.
- Update BOTH this file (working process/verified repository facts) and `master.md` (product/design status and acceptance progress) as work advances.

## Project-specific agent context — Claude Code must fill

**Repo location:** `C:\Users\HOME!\Desktop\climb&collect` (not a git repo). Place file: `ClimbAndCollect.rbxl` in that folder (saved 2026-10-20; an earlier accidental save also exists at `Desktop\F1\circuit\island\v3\builds\climb&collect.rbxl`, an empty baseplate, left untouched).

**Studio sync / run workflow:** No Rojo. Generator ModuleScripts in `ServerStorage.CC_Generators`, mirrored 1:1 in `src/world/*.luau` (15 modules since the traversal pass; checksum-verified after every edit). Edit the src file, apply the identical edit in Studio with `multi_edit`, then rebuild via `execute_luau` in separate calls: `B = require(ServerStorage.CC_Generators:Clone().BuildAll)` → `B.terrain(1)` → `B.terrain(2)` → `B.dressing()` → `B.authored()` → `B.regions()` → `B.traverse(1)` … `B.traverse(n)` (~15 s total; terrain(1) rebuilds `_G.CC_PATHS`, everything after depends on it). `B.traverse(n)` also applies the player settings (`WorldConfig.PLAYER`) and exports the route to `ReplicatedStorage.CC_Route`. It is idempotent on already-carved terrain, so a traverse-only change can be re-run without a full rebuild. Gully extents or depths that change need a full rebuild. For a whole-module rewrite: destroy the Studio module, then recreate it with `multi_edit` (className + full content), then checksum. File saves: Studio Ctrl+S via computer use, only after confirming the window title is `ClimbAndCollect.rbxl`.
- **Checksum method:** polynomial hash `h = (h*31 + byte) % (2^31-1)` over source with CRLF→LF, each line right-trimmed, whole string right-trimmed. Local: `python <scratchpad>/cksum.py src/world` (recreate it from this description if the scratchpad is gone). Studio: the same function in `execute_luau`.
- **Gotcha:** Studio `multi_edit` with `replace_all: true` reported success but did NOT apply (seen twice). Use explicit single edits, then checksum Studio vs src.
- **Gotcha:** right after `Terrain:WriteVoxels`/`FillBlock`, `workspace:Raycast` still sees the old terrain (physics lags). `Ctx:gorge` returns the floor function so pieces don't depend on raycasts.
- **Gotcha:** `FillBlock(Air)` with 4-stud columns leaves partly carved voxels (blobby overhangs). Carve with Read/WriteVoxels. Cut edges are quantized to ±2 studs, so exact edges come from parts (`Ctx:kerb`, climb-wall bodies placed inside the cut).
- **Gotcha:** MountainGen writes terrain as a **shell only ~10–12 studs thick** below the surface (void underneath). Any cut deeper than ~8 studs goes straight through it. `Ctx:gorge` rebuilds 14 studs of solid ground under the floor and an 8-stud solid band behind the cut faces.
- **Gotcha:** a cut narrower than the trail shoulder can leave a trail-level rim along it, which is a free bypass (found in 2c). Profile ±36 studs across every new cut (`terrain raycasts relative to trail height`) and widen it until the sides drop away or rise steeply.
- **Gotcha:** a client script setting `Humanoid.Jump = true` is overwritten by the default ControlModule. Bots must use `Humanoid:ChangeState(Jumping)`.
- **Gotcha:** an `execute_luau` call can report "Target is not reachable" even though the code ran (seen on `B.terrain(2)`). Verify the effect (terrain raycasts) before re-running.
- **Gotcha:** computer-use `open_application("Roblox Studio")` launches a SECOND Studio instance. To save, click the existing window's title bar (title must read `...ClimbAndCollect.rbxl - Roblox Studio`), press Ctrl+S, and verify the file mtime.
- **Measurement bots:** `tools/measure_bot.luau` (single segments) and `tools/push_bot.luau` (a whole push, background thread, poll `_G.CC_BOT`). Paste them into `execute_luau` on the Client during a playtest. They give BOT times (perfect input), not human times.
- **Gotcha:** `Attachment.WorldPosition` must be set after parenting, or it is stored as a local offset.
- **Gotcha:** Roblox renders a voxel column's surface ~1.6–2 studs above its filled height; `MountainGen` writes `h - 1.7` so the visible surface matches the heightfield (measured mean residual +0.3 studs).
- **Gotcha:** right after stopping a playtest, an edit-mode `screen_capture` can show terrain missing; re-capture.

**Available plugins / MCP / asset generators:** VERIFIED 2026-10-20: official Roblox Studio MCP connected (exposed twice, as `Roblox_Studio` and `roblox-studio`; both see the same single Studio instance). Tools: list_roblox_studios, get_studio_state, search_game_tree, inspect_instance, execute_luau, screen_capture, multi_edit, script_read/grep/search, start_stop_play, character_navigation, get_console_output, insert_asset, search_asset, generate_mesh/material/texture/procedural_model, segment_mesh, store_image, upload_image, user_keyboard_input, user_mouse_input, http_get, skill, subagent, wait_job_finished. Read-only `execute_luau` and `screen_capture` both returned successfully. No MCP tool saves the place to a file; file checkpoints need Studio's own Save.

**Memory / preexisting rules references:** User's global `~/.claude/CLAUDE.md`: concise output; decisions via the popup widget with a recommended option; no house style; design values only from this project's references (none exist, so `master.md` §3/§4 text is the only source, per `OVERNIGHT_BRIEF.md`); never transplant values from other projects; design memory is process-only. Project memory folder was empty at session start.

**Code style and modules (`src/world/`):** Luau, tabs, StyLua-like formatting, `--!native` on the heavy generator. `WorldConfig` (all layout numbers and material colors) · `MountainGen` (heightfield, paths, water, materials, voxel writer, `heightAt`) · `LightingSetup` · `Kit` (prop builders + CSG prototypes in `ServerStorage.CC_Prototypes`) · `BlockoutBuild` (Gate B placeholders, now all replaced) · `ValleyDress` / `RegionDress` (rule-based vegetation) · `SliceBuild` (Green Valley/Camp 1) · `ForestBuild` · `CliffBuild` · `HighBuild` (Storm Ridge + Summit) · `FootholdBuild` (core + districts) · `BuildAll` (ordered rebuild). World output lives under `Workspace.World.Regions.<Region>.{Vegetation,Authored}` and `...Foothold.{Core,Districts}`. Every color in code is a `Kit.COL` token traced in `design/world-tokens.md`.

**Asset production and visual QA:** All geometry is procedural/parametric from code (no marketplace assets, no generated meshes yet). Plants are CSG unions (1–2 instances each). Per gate: avatar-scale and aerial `screen_capture`s saved to `evidence/gate<X>/` (rejected iterations kept with a `9x_rejected` prefix), self-review against `master.md` §3, fix, re-capture.

**Performance targets / device test matrix:** No device targets set yet (OPEN). Measured only in Studio desktop playtests (vsync-capped 60 FPS): spawn 60 FPS / worst frame 18 ms; dense forest 60 / 18.6 ms; summit 60 / 18.3 ms. Whole world 37.9k instances (20.0k unions, 4.2k parts, 73 lights, 33 emitters/beams), StreamingEnabled on, ~9.9k–21.5k world instances streamed at a time. **No mobile or low-end measurement has been done.**

**Known blockers:** None open. (Resolved 2026-10-20: first preflight found only another project's place open; user opened a new baseplate, saved to `ClimbAndCollect.rbxl`, preflight passed.) Limits: `Lighting.Technology` and `Terrain.Decoration` are not accessible from the MCP's script context.

**Checkpoints:** in-place snapshots in `ServerStorage.CC_Checkpoints/<Gate>_<date>` (TerrainRegion of the whole map + World clone + Lighting clone + generator modules). Never overwrite an existing checkpoint folder.

**V2 redesign (approved 2026-10-20):** expedition mountain + Foothold home base; see `master.md` §0.5. Ordering: terrain/world quality first, gameplay systems in later approved phases. Specialist agent pipeline from the user's global CLAUDE.md applies where relevant, with design values derived only from this project's `references/` (none exists yet; ask before inventing).

**Overnight run (user-approved 2026-10-20):** see `OVERNIGHT_BRIEF.md`. Studio bridge = official Roblox Studio MCP; Gate C approval-stop overridden for that run only, with per-gate self-review and checkpoints. Audit facts: Roblox Studio installed and was running; Rokit shim present but **no tools installed (Rojo not set up)**; no Roblox MCP was connected in the Claude session when audited; no `references/` folder.

**V3 Ascent redesign (interview 2026-10-20):** decisions in `master.md` §0.6, phased plan and checklist in `design/v3-ascent-plan.md`. Summary: summit ~3,200; 4 routes (Shepherd's Road, Waterfall Stair, Cliff Ledge Line, Spire Ridge) separate at base, cross at camps, merge near summit; all 25–30 min skilled; stagger + fall-loss, no HP damage; camps + ~4-min mini-checkpoints; trees/rockfall/gusts/avalanche; Foothold ~3× with 4 gates; mobile-first. **STATE: planning done, NOTHING BUILT, STOP for user approval of the plan.** Before P1: take checkpoint `PreV3_2026-10-20` and a file copy; ask for the dry-foothill palette reference (`references/` is empty; do not invent). Note: the P2 traversal row is missing from the log below (src has TraverseP2); add it in P0.

**Current milestone and next action (V3 plan approval pending; older text below is the pre-V3 history):** Overnight run finished 2026-10-20 03:12: Gates B–E exist as a **first draft** (see morning report below). The Gate C override applied to that run only, so we are back to the pre-V2 rule: **stop for user review/approval** before more world work. Next: user reviews `evidence/` + plays the place, then picks priorities (likely: art pass on the benchmark slice, real assets/meshes, mobile perf measurement).
The user's six K2 clips were reviewed 2026-10-20 (contact-sheet frames, ffmpeg via pip `imageio-ffmpeg` in the session scratchpad only); observations are in `master.md` §0.5.

## Working evidence log

| Date | Milestone / change | Evidence (file or test) | Status | Follow-up |
|---|---|---|---|---|
| 2026-10-20 | **Traversal P1** (Foothold → Camp 1, verb: climb). 1a Meadow Boulder Hop (s1182–1238): kerbed 6-deep gully, 5 stones. 1b Shepherd's Step (s1804–1896): cut lane, framed climbs of 8 + 12 studs. 1c Lookout Rocks (s2635–2703): kerbed 7-deep gully, stones → framed climb → stones down. Frame climbs back out of both gullies. Player settings WalkSpeed 12 / MaxSlope 45 (approved). Fixed: the Foothold gate sign stood on the trail centerline (SliceBuild). | `evidence/traverseP1/T1_01–03` (avatar scale), `T1_90/91` = rejected (FillBlock carve, brook pane). Checkpoint `Traverse_P1_2026-10-20`; file 24.8 MB. **BOT measurements (perfect input, not human):** full push 313.9 s raw, 4 bot-only stucks (gate sign, now fixed; Meadow Bridge arch ×3, a bot height-tolerance artifact; the bridge was walked separately and is fine), corrected ≈ **281 s = 4.7 min** (pure walking at 12 = 278 s; at the old 16 = 3.5 min). Segments add for the bot: 1a +0.2 s, 1b +2.5 s, 1c +1.3 s (two identical runs). Walk-arounds: pathfinding found paths around all 3, but walking them with the 45° limit stalled every time. | DONE as first draft (P1) | Climb walls are plain rock blocks and the return-climb caps read as benches (art pass). No human, mobile or novice timing yet. |
| 2026-10-20 | V2 concept research + redesign approved; docs reconciled | `master.md` §0.5; plan file | DONE (docs only, nothing built) | Gate A audit |
| 2026-10-20 | Overnight preflight: Studio MCP tools, read, execute_luau, screen_capture | Tool results in session; see Known blockers | FAILED at place check (wrong place open) | User opens a CLIMB & COLLECT place; rerun preflight |
| 2026-10-20 | Preflight rerun on new place | `ClimbAndCollect.rbxl`; Studio id e92bfe36 | PASSED | — |
| 2026-10-20 | Gate E full Foothold (first draft): Hall of Wonders (columned stone hall, 8 empty display plinths), Gear Forge (hearth + anvil), Provisions Market (4 stalls), Garage + ATV trail start, Base Pad (helipad, landing lights, windsock), Hatchery (round nursery, 4 eggs), 9 terraced player cabins with fenced habitat yards, painted paths, shade trees/flower beds. Also: terrain surface-offset fix (whole world rebuilt), last placeholder bridge replaced (cliff ledge bridge), stair flights lifted 0.7 studs | `evidence/gateE/E01–E07*.jpg` (E90 = rejected, pad buried before the fix); checkpoint `GateE_FullFoothold_2026-10-20` (taken before the stair lift); file 21.2 MB. Playtest: walked the Chasm Bridge end to end and the summit stairs to the crown (y≈2010), full health both, 60 FPS at summit | DONE as first draft; NOT final art | Districts are empty shells (no interiors/NPCs/systems); cabin/habitat art is basic |
| 2026-10-20 | Gate D regions (first draft): Whispering Forest (≈4.6k trees, 240 mushroom clusters, Enchanted Tree ~190 studs tall with root arch over the trail and indigo glow roots, 3 ancient ruins, Camp 2 Rootgate lodge + root arch gate, 16 route lanterns, creek footbridge); Broken Cliffs (pines, dead trees, sandstone outcrops, Monumental Chasm Bridge with stone towers + suspension cables, Camp 3 Chasm Hut, 10 ledge fence runs); Storm Ridge (snow pines, dead trees, aurora crystals, Wind-Scarred Ruin with rune obelisk + lightning beam to the RuinTooth peak, Camp 4 Stormwatch tower + windbreaks, 38 cairns, 19 ridge fence runs); Frozen Summit (ice/aurora crystals, 16 summit stair flights, Crown Observatory with crystal blade crown, helicopter LZ pad) | `evidence/gateD/D01–D11*.jpg` (D90 = rejected); checkpoint `GateD_Regions_2026-10-20`; file 17.6 MB. Whole map 36.7k instances (19.9k unions, 3.3k parts, 51 lights). Playtest (Studio desktop): 60 FPS (vsync cap) at forest/giant tree, worst frame 18.6 ms, 21.5k world instances streamed | DONE as first draft; NOT final art | Not walk-tested above Camp 1; stair/bridge collision above Camp 1 unverified in play; no caves, no hidden region yet |
| 2026-10-20 | Gate C benchmark slice (first draft): Green Valley dressing (≈2.75k trees, 4.4k flower patches, 600 bushes, 530 terrain rock outcrops; groves/flower-field masks, clearings for landmark sightlines), Camp 1 Meadow Lodge (lodge, locker, campfire, beacon, fence, woodpile, crates), falls FX + Falls Hut/dock, 11 band stair flights, Meadow Bridge + valley-ring bridge, Falls Overlook deck, signs, route lanterns, Foothold core (summit-view terrace + spawn, campfire plaza, Expedition Hall, cobbled avenue) | `evidence/gateC/C01–C09*.jpg` (C90–C92 = rejected iterations/kit test); checkpoint `GateC_BenchmarkSlice_2026-10-20`; file 12.0 MB. Playtest (Studio desktop, not mobile): 60 FPS avg (vsync cap), worst frame 18 ms at spawn, 9.9k world instances streamed in; character walked spawn → Camp 1 in 12 pathfinding hops, arrived at full health | DONE as first draft; NOT final art (see gaps) | Waterfall flow beams not visible in edit captures (unverified at runtime); rim mountains read as grey low-poly; Foothold mostly empty until Gate E |
| 2026-10-20 | Gate B mountain blockout: procedural heightfield (4800×4800 studs, summit 2000), main route + 5 ring trails + overlook spur, camp/feature pads, lake, river, creek, waterfall, chasm, lighting baseline, 6 placeholder bridges, 4 camp beacons | `evidence/gateB/B01–B07*.jpg` (B01–B02 = rejected first iteration); checkpoint `GateB_Blockout_2026-10-20`; file 7.05 MB | DONE (blockout quality, not final art) | Route measurements below; summit-glimpse gap in upper pushes |

## Morning report — overnight run 2026-10-20 (01:30–03:12)

**What exists.** One saved place, `ClimbAndCollect.rbxl` (21.2 MB), with the whole mountain as a first draft: Foothold home base → Green Valley → Whispering Forest → Broken Cliffs → Storm Ridge → Frozen Summit, 4 camps, all signature landmarks from `master.md` §4, every placeholder replaced by an authored build. 4 checkpoints in `ServerStorage.CC_Checkpoints` (B, C, D, E). Fully reproducible from `src/world/` via `BuildAll`.

**Route measurements** (main route, from the generator's path data; times are ESTIMATES = distance ÷ 16 studs/s walk speed, no stamina/stops/climbing):

| Push | Length | Height | Ascent / descent | Walk time (ESTIMATE) |
|---|---|---|---|---|
| Foothold gate → Camp 1 Meadow Lodge | 3,337 studs | 33 → 218 | 199 / 14 | 3.5 min |
| Camp 1 → Camp 2 Rootgate | 4,092 | 218 → 456 | 305 / 67 | 4.3 min |
| Camp 2 → Camp 3 Chasm Hut | 3,486 | 456 → 916 | 600 / 139 | 3.6 min |
| Camp 3 → Camp 4 Stormwatch | 3,714 | 916 → 1,422 | 640 / 135 | 3.9 min |
| Camp 4 → Frozen Summit crown | 2,257 | 1,422 → 2,000 | 642 / 64 | 2.4 min |
| **Total** | **16,887** | **33 → 2,000** | **2,386 ascent** | **17.6 min** |

Spawn → trail gate is 160 studs. Ring loops: Valley 10,713 (11.2 min), Forest 6,963 (7.3), Cliff shelf 4,869 (5.1), Ruin shelf 3,216 (3.3), Storm shelf 2,118 (2.2). 37.8% of the route is steeper than 25% (stair sections reach 62–80%).

**Versus the V2 targets (LOCKED: skilled ~25–30 min, first ascent ~60 min, pushes 10–15 min):** pure walking is 17.6 min with 2.4–4.3 min pushes, so the route is **shorter than the target before any traversal verbs, obstacles, hazards or detours exist**. Closing the gap is a design decision (longer route vs. obby/climb segments vs. hazards), not something I tuned silently.

**Verified in play (Studio desktop only):** spawn → Camp 1 walked; Chasm Bridge crossed; summit stairs climbed to the crown. Camp 1 → Camp 3 and Camp 3 → summit spiral were not walked end to end.

**Known gaps (honest):**
- Art is first-draft procedural primitives everywhere; nothing is final art. The rim mountains read as grey low-poly; tree/rock silhouettes are simple; buildings are kit-bashed boxes with no interiors.
- Summit glimpses (terrain-only raycasts to the crown, trees not counted; sampled every 60 studs): Push 1 55/56, Push 2 18/69, Push 3 4/59, Push 4 3/63, final spiral 1/38 (upper spire face 14/38). Visible from Foothold; blocked from Camps 1–3; Camp 4 sees the upper spire. `master.md` §3 asks for repeated glimpses, so the upper pushes need sightline work.
- The waterfall flow ribbons are subtle; the falls read mainly as a turquoise water sheet.
- No caves, no hidden region (Glacier Caves / Sky Garden), no alternate risky shortcuts beyond the rings, no weather, no audio.
- No mobile, low-end or multi-player performance measurement.
- No gameplay systems (by design for this run).
- Fonts on signs use FredokaOne as a provisional choice; `master.md` names no typeface (OPEN).

**What to approve next:** (1) the mountain layout + route length vs. the 25–30 min target, and how to close the gap; (2) the benchmark slice's look before any art pass scales to other regions; (3) whether to bring in real meshes/assets (and from where) instead of primitives; (4) device targets for performance work.

## Edit policy

Keep this document clear and concise but accurate. Add sections when real project context requires them. For important workflow rules, record source/rationale. Keep an immutable history or commit trail for major changes. Don't erase user's locked constraints or store passwords, tokens, private credentials or personally sensitive information in repository docs.


## Fairground redesign local review — 2026-10-22

All four implementation phases are saved in `Fairground.Finale.Review.rbxl` (identical working copy: `ClimbAndCollect.Fairground.Review.rbxl`). Final integration source: `ffb15a2`; phase commits: `be2f7aa`, `877be3f`, `92b2f4a`, `ff1f1d5`. Read [the implementation handoff](design/fairground-implementation-handoff-2026-10-22.md) before continuing. Reopened binary verification passed for 101 sources, exact terrain and protected assets. Independent code review findings are resolved. Genuine whole-ascent acceptance remains incomplete at a preserved Shepherd terrain overhang; real multiplayer, physical phone/controller and DataStore networking remain unverified. Do not treat injected summit eligibility or profile release/reload fixtures as these tests. No publishing or commerce activation occurred. Starting dirty/untracked work is recoverable in the local starting-source archive; Git alone is not the whole project.


## Fairground polish acceptance — 2026-10-22

Supersedes earlier incomplete-ascent status: a genuine natural-spawn ascent completed all four camps and sixteen traversal sections without position or eligibility injection. Diagnostic stops, backtracking and live route repairs mean the recorded 32m54s is not a speed benchmark. One summit awarded 150 coins, 200 points and First Light Pennant; duplicate calls awarded nothing. Actual mouse return reached the bank and acknowledged result 1. Final `Fairground.Polished.Acceptance.rbxl` was reopened: 104 sources match/compile, terrain exact, seven protected groups unchanged, no QA agents, HTTP off. Actual two-client checks passed 16/16 before final terrace/stair changes. Physical devices, live DataStore networking and same-account reconnect remain unverified. Details: `design/fairground-polish-handoff-2026-10-22.md`. No publishing or spending.


## Mountain HUD/UI isolated implementation — 2026-10-24

VERIFIED in `codex/mountain-hud-ui`: approved 28-question blueprint recovered from `23ee172`; eight hubs/23 tabs, authoritative intents, settings and responsive HUD committed at `5e67fc2`. Read [the implementation report](design/hud-ui-implementation-report.md) for the baked review, 419 CLI/service checks, 50 isolated Studio checks and four device-emulator presets. Original expedition/profile rules are preserved. Direct sanctuary bridge, habitat/build/placement, party lifecycle, rankings and commerce remain blocked by missing services; physical device/live persistence/eight-client acceptance is unverified. Concurrent mountain art revisions are not automatically included. The original graph excludes this worktree source.
