# Stampede Spire grey-box: ride/swap test log (2026-10-29)

Place: `Documents\StampedeSpire\StampedeSpire.Greybox.rbxl` (SHA256 8ab271c3…3abf, PlaceId 0, not published, HttpEnabled off).
Source (mirrored 1:1 in Studio):
- `src/SS_Config.luau` → ReplicatedStorage.SS_Config (all tunables)
- `src/SS_Track.server.luau` → ServerScriptService.SS_Track (builds the lane strip at runtime)
- `src/SS_Ride.client.luau` → StarterPlayerScripts.SS_Ride (herd, ride, swap, fail, input, UI)

Sync: serve `src/` (`python -m http.server 8797 --bind 127.0.0.1 --directory src`), then in Edit set HttpEnabled on, `GetAsync` each file into `.Source`, and set it off again in the same call.

## What it does
- One 5-lane strip, 1,500 studs long at a 10° slope. 30 block creatures (6 per lane) run uphill and wrap to the bottom.
- Speed = (22 + 0.012 × distance) × zone step (×1 / ×1.25 / ×1.55 at the 500 and 1,000 borders).
- Ride: R15 seat pose with a forward lean and reins arms. Creatures in swap range (40 studs) get a yellow outline.
- Swap: click or tap a creature (a tap within 80 px of an in-range creature also counts). Surfer stance with a wobble for 0.6 s, then a shrinking ring over the target. Press with a click/tap, Space, gamepad A or the touch jump button.
- Success: a jump arc onto the target. Fail (wrong timing or no press): faceplant, then you are dropped 30 studs back down the lane on foot. The next creature that passes in your lane picks you up.

## BOT / self-checks (Studio Play Solo, desktop)
| Check | Result |
|---|---|
| Speed table: 0→22, 499→28.0, 500→35.0 (step), 999→42.5, 1000→52.7 (step), 1499→62.0 st/s | PASS |
| Auto-mount at spawn → `ride` | PASS |
| 5 swaps pressed at the ideal time (0.933 s into the ring) | 5/5 success, back to `ride` |
| Early press (0.2 s) | fail:timing → faceplant → free |
| Late press (1.3 s) | fail:timing |
| No press | fail:timeout |
| Remount after the 3 fails | 3/3 picked up by a passing creature; last wait 8.1 s from faceplant |
| Real mouse click on a highlighted creature (computer use) | swap started, ring shown |
| Real Space key | registered; it came late because of screenshot latency → faceplant (correct for that timing) |
| Console errors | none |

Screenshots: `evidence/01–07`. Use 04 and 06 for the ring: the MCP `screen_capture` does not draw BillboardGuis, so the ring only appears in desktop screenshots.

## Not verified / known limits
- No touch-device or Device Simulator test. The touch code path is the same InputBegan handler as mouse clicks, plus JumpRequest for the jump button.
- No human timing feel test. The success window is ±0.28 ring scale, about ±0.13 s.
- The herd is simulated on the client only (Play Solo prototype, no multiplayer replication).
- Creatures in the same lane can overlap (no separation). Remount waits can reach ~8 s, depending on lane gaps.
- Poses are rough: legs sit inside the block body.

## Gotchas found
- The new avatar joints are `AnimationConstraint`, not `Motor6D`. Both expose `.Transform`, so both are collected.
- Pose `Transform` must be written in `PreSimulation`. The Animator overwrites values written in RenderStepped.
- A BillboardGui parented inside a ScreenGui does not render. Parent it to PlayerGui.
- `open_application("Roblox Studio")` starts a second Studio. Focus the existing window by its title bar instead.

---

# Milestone 2: full 4-zone blockout (2026-10-29)

Owner decisions (popup): full 4-zone blockout next; **a mount carries you across zone borders** (swaps optional); **lanes narrow, same count**; **1,000 studs per zone**.

Place saved to the same path (SHA256 d5673f6e…, HttpEnabled off). New source file:
- `src/SS_Path.luau` → ReplicatedStorage.SS_Path (path math: per-zone slope, lane width ramp, speed, world↔d projection)

## What changed
- Mountain = 4 zones × 1,000 studs = 4,000. Slope per zone 10° / 13° / 16° / 20°; lane width 12 / 10 / 8.5 / 7 studs (5 lanes), ramping in over the last 40 studs before each border. Walls and lane lines follow the taper.
- Speed = (22 + 0.005 × d) × zone step (×1 / ×1.25 / ×1.55 / ×1.85) × species tier (zone 4: Ram/Antelope ×1.05, Kirin ×1.1).
- Herd: 5 creatures per lane per zone (100 total), each zone's 5 approved species mixed across lanes, with name tags. Unridden creatures wrap to the start of their own zone; the one you ride carries on up the mountain.
- Summit at 4,000: "SUMMIT!" for 2.5 s, then you're sent back to the foothills onto a zone-1 creature.
- Placeholder colours (ground per zone, body per species) and body sizes are sampled from the approved r2 sheets; everything is in `SS_Config` (`Zones`, `Species`).

## BOT / self-checks (Studio Play Solo, desktop, command bar in Client context)
| Check | Result |
|---|---|
| Speed/lane table: 0→22.0 (lane 12), 999→27.0 (10.0 after ramp), 1000→33.8, 1999→40.0 (8.5), 2000→49.6, 2999→57.3 (7.0), 3000→68.5, 3999→77.7 (7.0) st/s | PASS (matches formula) |
| Species per zone (herdInfo): zone 1 = Elk/Reindeer/Musk Ox/Hare/Boar, zone 2 = Ibex/Chamois/Takin/Moose/Saiga, zone 3 = Yak/Rhino-Goat/Bison/Gazelle/Ashmane, zone 4 = Ram/Antelope/Hart/Kirin/Starfrost Ox, 5 each (one ridden Boar counted in zone 2) | PASS |
| Carry-on across borders 1000 / 2000 / 3000 (riding a zone-1 Pine Boar) | 3/3: zone advanced, same mount, still `ride` |
| Ideal-time swap at 150 / 1300 / 2300 / 3300 | 4/4 success, mounted the local species (Pine Boar, Glacier Chamois, Basalt Rhino-Goat, Skyhorn Antelope) |
| Early press (0.2 s) at 1500 (zone 2) and 3400 (zone 4, 7-stud lanes) | 2/2 fail:timing → faceplant → remount in 1.9 s both times |
| Summit (teleport 3985) | `summit` state, summits=1; 4 s later riding a zone-1 Taiga Elk at d≈303 |
| Unattended ride from the bottom | carried passively through all 4 zones to the summit, then reset (seen during the run) |
| Console errors | none seen |

Screenshots: `evidence/08-zone1-taiga.jpg`, `09-zone2-crevasse.jpg`, `10-zone3-obsidian.jpg`, `11-zone4-aurora-narrow.jpg` (desktop captures, name tags visible).

## Not verified / known limits
- Still no touch/Device Simulator or human feel test.
- Herd still client-only; no wind gusts or rarity yet.
- Zone joins are hard kinks (slope changes instantly at the border); creatures and rider snap pitch there.
- Out-of-zone creatures you leave behind teleport back to their zone start when they pass their zone end (visible pop).
- Same-lane overlap is still possible; tags can overlap when creatures bunch.

## Gotchas found
- This session had no Roblox Studio MCP; Studio was driven by computer use through the command bar. The command bar shows a "Dangerous Command Detected" prompt for HttpService code (choose Continue, not Always Continue). Code that never touches HttpService (BOT checks) runs without it.
- The command bar runs in the Client context during Play Solo, so the client-only `SS_Debug` BindableFunction is reachable from it.

---

# Milestone 3: Blender mountain, art pass (2026-10-29, overnight)

Owner-approved polished rough draft of the full mountain (environment only). Place saved to the same path (SHA256 b6e5d79abd74c009…, HttpEnabled off), with a backup of M2 at `StampedeSpire.Greybox.pre-mountain.rbxl`. Full write-up: `MORNING-REPORT.md`. Look-dev: `art/LOOKDEV.md`.

New or changed source (mirrored 1:1 in Studio):
- `src/SS_Path.luau`: smoothed profile (`SlopeBlend` 80, `SummitFlat` 40) in a 1-stud table. Python twin: `art/tools/sspath.py`.
- `src/SS_Track.server.luau`: collision only (hidden slabs on the path, walls, summit pad); `ShowGreybox` restores the strip.
- `src/SS_Env.client.luau` (new): zone lighting blend, title cards, shafts/steam/lava and crystal lights/aurora, weather.
- `src/SS_Ride.client.luau`: scripted ride and summit camera, 12-part galloping placeholder creatures.
- `src/SS_Markers.luau` (generated by the Blender build), `src/SS_Bot.luau` (BOT suite).
- Art pipeline: `art/tools/build_mountain.py` → `art/blender/ss_mountain.blend`, `art/export/*.fbx`, `ss_manifest.json`. Studio jobs live in `art/tools/studio/` and run through the one-line runner (`RUNNER.txt`, dev bridge `art/tools/ss_devserver.py` on 127.0.0.1:8798).

## BOT / self-checks (Play Solo, desktop, `require(game.ReplicatedStorage.SS_Bot)()`)
| Check | Result |
|---|---|
| Path smoothness: joins 0.075°/stud (M2 had a 3–4° step), summit ease 0.75°/stud, step error 0.0002 | PASS |
| Speed/lane table (same formula as M2) | PASS |
| Species per zone 5/5 ×4 | PASS |
| Carry-on 1→2, 2→3, 3→4 | 3/3 |
| Ideal swaps at 150/1300/2300/3300 | 4/4 |
| Early press at 1500/3400 → faceplant → stand on hidden collision (3.0/2.9 above track) → remount 8.3/6.7 s (final run 9.1/5.3 s) | 2/2 |
| Summit → back to a zone-1 creature | PASS |
| Mesh placement vs. manifest (post-import job) | 98/98, max error 0.001 studs |
| Device Simulator (phone landscape) | layout OK (touch controls, title card); FPS not measured |
| Perf (desktop Studio) | 60 FPS cap, worst frame 18–19 ms; 255.1k tris in 98 MeshParts; MeshParts 34 MB, textures 56 MB |
| Final state re-run (after glow accents, materials, tag distance) | 13/13 |

Screenshots: `evidence/12–31`.

## Not verified / known limits
- Real phone performance; human feel test; multiplayer.
- Zone 4 is monotone blue; the aurora is a camera-locked sky layer; terrain edge at ±950 studs is sometimes visible from the summit orbit.

## Gotchas found
- Studio's 3D Importer turns Blender FBX (forward -Z, up Y) 180° about Y (X and Z negated). Pre-flip X/Z on export. Blender metres also come in at ×100 unless you export with `global_scale=0.01`.
- Beams are culled once an attachment is ~2,048 studs from the camera.
- StreamingEnabled (on by default) culled far meshes: set the art model's `ModelStreamingMode` to Persistent.
- The Dangerous Command dialog can appear 3–5 s after Run. Wait for it before clicking Continue.
- `workspace.StreamingTargetRadius` can't be read from the command bar.
- A NaN camera CFrame (division by zero) silently freezes the camera.

## Milestone 3b: zone 4 contrast pass (2026-10-29, morning)
Place SHA256 36ee56d832c23dd1…. The crystal facets were re-shaded (UV only) and the glow shards added on the lip; 4 meshes were re-imported by patch (max position error 0.001). Z4 lighting: ClockTime 18.6, Outdoor = crystal_glint, Contrast 0.25, Saturation −0.2, Brightness 2.4. Summit orbit radius 230 / height 115.

| Check | Result |
|---|---|
| BOT suite | 13/13 (remounts 4.3 / 10.4 s) |
| Aurora on a normal ride 2850 → zone 4 | visible on arrival (evidence/34, 35) |
| Summit orbit clears the crown | yes (evidence/36) |

## Milestone 3c: terrain borders + skirts (2026-10-29, late morning)
Place SHA256 5c96ad64fc0e6a68…. Height-only border blend (s-dependent width), rock skirts on every exposed edge, `Z1_StartDeck`, props grounded on the built mesh (BVH ray-cast), and far-field paint taken from quad normals. 42 meshes were re-imported by patch (max position error 0.001; postimport's 141/99 count is the patch meshes counted twice, and a dedupe check found 99 unique).

| Check | Result |
|---|---|
| BOT suite | 13/13, 60 fps, 115 meshparts (evidence/42) |
| Border step, width-averaged over 80 studs | B1 189→62, B2 154→49, B3 293→79 studs |
| Prop base vs built terrain | all classes within ±1 stud. Was: pines up to +14.7/−17.5, crystals ±44, Neon accents 63 fully floating |
| Zone-4 crystals on zone-3 paint | 28 → 0 (base-vertex ray) |
| Far-field paint on quad diagonals | 0 in all zones (was 57% of the zone-1 boundary) |
| Track + backdrop meshes | byte-identical (random sequence preserved) |
| Limits | max 9,000 tris, 1,829 studs |
| Ride views 2960 / 500 / start / 3700 | no wall ahead, crystals grounded (evidence/38–41) |

**Not verified:** a real phone. Prop footprints were not checked for downhill overhang; only bases and whole-prop floating were measured.

**Gotcha:** ground props on the built mesh, never the analytic height. Far terrain columns are 50–130 studs apart, so the triangulated surface misses ridges the height function has.


## Milestone 4: phone UI + ride camera (2026-10-29, afternoon; src only)
Place SHA256 6afe610a2bb388dd…. No assets uploaded. `src/` synced byte-for-byte (SYNC SS_Config=10884 … SS_Ride=… SS_Bot=…); integrity job `art/tools/studio/check.luau`: 99 MeshParts, Workspace = Camera, SS_Mountain, Terrain.
- **Debug readout** off by default (`SS_Config.Ui.DebugHud = false`).
- **Hint** is one short line at the top under the top bar (60 % wide, text 11–20 px), off the lanes. The **title card** (`SS_Env`) now starts below the hint line (both measured from the same top-bar inset), so they can't overlap.
- **Name tags:** at most `Ui.TagMax` = 4 (swappable creatures first, then nearest). A tag that would overlap a placed tag is lifted above it; tags fade from 45 to 70 studs; tags never sit on the hint or on a showing title card; the ridden creature's tag is hidden.
- **Ride-camera occlusion:** a creature the camera would be inside (box + 1.5 studs) is hidden; one between the camera and the rider fades to 0.75 (`Cam.FadeMargin/FadeAlpha/HideMargin/FadeSpeed`).
- **Camera vs mountain** (meshes use box collision, so checked offline): `art/tools/cam_clearance.py` runs the ride-camera rule on the built Blender meshes, every 4 studs × 5 lanes × lag 0/6/12 studs (15,015 samples): 0 within 2 studs of a mesh, 0 with the rider hidden, min clearance 10.0 studs (the track). Summit orbit: 360 samples, min clearance 89.7.

| Check (Play Solo; `require(game.ReplicatedStorage.SS_Bot)()`) | Desktop 3434×1027 | Device Simulator iPhone XR landscape 801×413 |
|---|---|---|
| 1–13 (path, speed/lane, species, carry-on ×3, swaps ×4, fails ×2, summit) | PASS | PASS |
| 14 ui: debug hud off, hint/title overlap, hint in the top 25 % | PASS (hint 6–32, title 41–235) | PASS (hint 6–32, title 42–113) |
| 15 tags+camera, every frame for 3 s per zone, entering each zone across its border (title card up) | PASS 720 frames: max tags 3, overlaps 0, cam inside creature 0, creature blocking rider 0 | PASS 720 frames: max 4, overlaps 0, tags on hint/title 0, inside 0, blocking 0 |
| 16 occlusion probe (camera lowered to Up 4; creature parked at the camera → hide, mid-way → fade) | PASS 1.00 / 0.75 / 1.00 / 0.75 | PASS same |
| Perf | 60 fps, worst frame 18 ms | 60 fps, worst 22 ms |
| Console errors (client LogService) | — | 0 |

Screenshots: `evidence/46` (BOT desktop), `47–51` (phone: zone 1–4 title cards + summit), `52` (phone BOT output).

**Not verified:** a real phone or touch input (M7). Server-side log history was not read (client only). Tag readability on a real phone screen.

**Seen, left for M6 (D5 review):** the zone-1 title (#E9EAF0 on a bright snow sky) is hard to read on phone (evidence/47); the zone-3 lava ribbon is very bright beside the camera (evidence/49).

**Gotchas:**
- The command bar is now a multi-line editor: **Ctrl+Enter** runs it (Enter adds a line). The Run button is at the far right of the bar.
- Clicking the Studio window while the desktop shell is frontmost is blocked for computer use; a click-only "File Explorer" grant lets you click Studio's title bar to refocus it.
- Device Simulator can only be toggled in Edit (Test menu → Device Simulator).
- In-game raycasts can't check the camera against the mountain (box collision); use `cam_clearance.py` in Blender.

## Milestone 5: gentle plan-view bends (2026-10-29, afternoon)
Owner check-in (popup, after Blender top/chase/ride previews `evidence/53–55`): **gentle S, ±10°** approved. Place SHA256 7eb6d676c11a1859…; backup of M4 at `StampedeSpire.Greybox.pre-bends.rbxl`.
- `SS_Config.Bends`: +10° at d 700 (600 studs), −20° at 2000 (760), +10° at 3300 (600). Heading never exceeds ±10°; max sideways swing 197 studs; the summit ends 4 studs off the old line; tightest radius 1,451 studs (> the ±950 terrain + skirts, so nothing folds).
- **How:** the mountain is still authored straight; `sspath.warp` bends it at export (`ssblend.build`), and `SS_Path.warp/unwarp` does the same at runtime (`surf`, `project`). Lanes, herd, camera, collision slabs, walls and FX markers all go through `surf`/markers, so they follow. Backdrop peaks move rigidly with the warp of their centre (no deformation). Because heights are untouched and everything warps together, the 3c guarantees (border blend, props grounded ±1 stud, skirts on every edge) carry over unchanged.
- **Re-import:** 61 zone meshes in one `ss_patch.fbx` (61 private mesh uploads + 1 atlas texture; ids in `art/export/asset_ids_m5.tsv`). The 38 backdrop meshes were moved by `postimport` (26 by up to 506 studs), no upload. Postimport re-run: 99/99, max position error 0.001, 0 fixed. Totals unchanged: 99 meshes, 264,690 tris, largest 9,000 tris.
- Camera clearance on the bent build (`cam_clearance.py`): 15,015 samples, 0 near/blocked, min 9.99 studs.

| Check | Result |
|---|---|
| bends: Luau `surf` vs the Python warp (`SS_Markers.PathCheck`, 129 points) | 0.0003 studs |
| lane-centre error on the curve (project(surf(d, laneX)), every 10 studs × 5 lanes) | 0.0002 |
| herd in lanes (1,000 body samples) | max off-centre 0.000 studs |
| Full suite | **18/18** twice in a row (`evidence/57`, `61`), 60 fps |

Ride shots through the bends: `evidence/58–60`.

**Harness fix (not a bend bug):** the first two bent runs were 17/18 — once no creature drifted into swap range within the wait (d=1500, then d=150), once a single 6.5-stud standing sample at d=3400 (a 4-trial probe there read 2.9–3.0). With 5 creatures 200 studs apart per lane, a teleported mount has ~5–9 % odds of nothing in range for 10 s, so M4's clean runs were partly luck. `trySwap` now teleports beside the nearest creature in another lane when nothing is in range; the standing height is the settled minimum of 5 samples (the max is reported).

**Not verified:** real phone; the ride feel of the bends (they read clearly from above, subtly from the ride camera).

## Milestone 6: visual polish + zone sign-offs (2026-10-29, evening)
Place SHA256 4cf152eb66787936…; backup of M5 at `StampedeSpire.Greybox.pre-m6.rbxl`. `src/` synced byte-for-byte (SYNC SS_Config=… SS_Env=… SS_Ride=…, each equal to the file size).
- **Meshes:** 32 rebuilt meshes (skirt ledges, basalt masses, zone-1 far columns halved, decks) in `ss_patch.fbx`. Prep removed the 32 old parts; import with Insert Using Scene Position; postimport run 1 = 131/99 (the known double count of a fresh patch), dedupe check 99 unique / 0 dups, run 2 = **99/99, max position error 0.001, 0 fixed**.
- **Env (synced before this session):** title strokes, Z2 shafts fade 30–90 studs from the camera, taller aurora, Z3 Glare 0.5 / Bloom 0.6, Z4 Density 0.25.
- **Z4 sky:** the 3 skybox images (make_sky.py) loaded Failure in Play for ~4.5 h after upload; re-importing them as textures on 3 quads (`art/tools/make_sky_fbx.py`) returned the same ids, which then loaded Success. Still black at ClockTime 18.6: Roblox darkens any skybox after sunset (also with the default sky, evidence/66–67). Clock 17.8 adds an untraceable pink sun band (68). **Z4 now Clock 13, Brightness 0.6** → navy sky (69–70). Haze density 0.45/0.6 tested for the summit and rejected (dark navy wall).
- **Aurora:** purple only at faded ray tops washed out under additive overlap; now green→purple across the span (`AuroraPurpleSide`, `AuroraPurpleFrom`, `AuroraTopOpacity`) (77).
- **Summit orbit:** started at a random angle (`os.clock()`), so the 4 s hold often faced zone 3's dark terrain and the z3_far peaks 16/17/19. The arc is now centred on the downhill side, looking up past the crown (78). No mesh repaint needed.

| Check | Result |
|---|---|
| BOT after import (evidence/62) | 18/18 |
| BOT after Z4 clock (71) and after aurora + summit (79) | 18/18, 18/18 |
| Perf, Studio focused, Z4 (72) | 59 fps, worst 18 ms |
| Sign-off sheets (r2 header vs in game) | Z1 73, Z2 74, Z3 75 approved; Z4 76 → fixes → 80 approved |

**Gotcha:** BOT's PERF line reads 15 fps whenever Studio is not the foreground window (background throttle). The C&C Studio took focus during three runs; the focused measurement is the valid one.
**Gotcha:** Roblox skyboxes go black after sunset; a night zone needs a day ClockTime with low Brightness.
**Uploads (D1):** 32 meshes (ss_patch) — ids in `art/export/asset_ids_m6.tsv` (with the 32 M5 ids they replaced); 3 sky images 107253105174203 / 133457787937137 / 75604857964706 (in use); 3 sky quad meshes (ss_sky, removed after reading ids); 1 duplicate image z4b_up via Asset Manager (unused, id not shown). The 32 replaced M5 mesh ids are now unused (D4).
**Not verified:** real phone (M7 deferred by the owner).

## Milestone 8 (part 1): herd pop-back + same-lane overlap (2026-10-29, evening; src only)
Place SHA256 228834cd50b9c6ee…. `src/` synced (SS_Config=13140, SS_Ride=29248, SS_Bot=15240 = file sizes). No uploads.
- **Pop-back:** an unridden creature past its zone end recycles only once it is `RecycleAhead` 250 studs ahead of the rider or behind it; until then it runs on into the next zone. A recycle that would land within `RecycleClear` 120 of the rider lands 120 behind it (just below the zone start if needed). Zone-4 creatures fade out over the last `SummitFade` 40 studs and recycle only when faded.
- **Overlap:** creatures in a lane keep `LaneGap` 14 studs nose-to-tail; followers wait, a ridden or swap-target creature pushes its leader. The BOT occlusion probe creature is exempt.
- **BOT 19/19** (new check: `herd: 297 recycles, 0 in view; min same-lane gap 14.0 studs`, evidence/81). Earlier tries: 18 in view (landing clamped to the zone start), then 4 (forced recycle after a fixed overrun), then 9 (zone-4 summit recycles), each fixed as above.
**Not verified:** how a long overrun into the next zone reads to a player (species of zone k seen in zone k+1 for a few seconds).

## Milestone 8 (part 2): zone-1 skinned creatures + aimed slow-motion leap (2026-10-29, evening)
Place SHA256 7a113f468d8e5372…. `src/` synced (SS_Config=14598, SS_Ride=40430, SS_Bot=15275 = file sizes).
- **Creatures (owner: rework detail, then import):** 5 zone-1 species rebuilt at 2,182–2,956 tris, 20–22 bones (`art/creatures/README.md`; a subagent also fixed inward-wound caps). `art/tools/export_creatures.py` exports each as one FBX (mesh + rig, the 4 clips end to end on one timeline; 1 A = 1.98 m = 5.2 studs) plus `art/export/creatures/clips.json` (clip ranges, seat). Imported with the 3D importer (heads face −Z, no flip). `art/tools/studio/creatures.luau` files them in `ReplicatedStorage.SS_Creatures` and splits each imported KeyframeSequence (ServerStorage.RBX_ANIMSAVES) into gallop/idle/swap_jump/faceplant.
- **In game:** `Species.Model` picks the skinned creature; gallop plays through an Animator at a rate matched to ground speed (`GallopClip`); the rider sits on the back above the spine bone. Clips are registered locally with `AnimationClipProvider:RegisterAnimationClip`, which only works in Studio; uploading the clips (D9) comes after the zone-1 sign-off. Only gallop is wired so far.
- **Leap (owner request: "Ride a Dino"-style aimed slow-motion jump; owner chose "ring sets power, then aimed leap" and strong ~0.3× slow motion):** I could not verify that game's exact behaviour from written sources, so this is our own version. Ring accuracy → power → flight time 1.1–1.6 game s. The world (herd and gallop clips) eases to 0.3× in the air and back just before landing (max 1.4 real s). The rider flies in path space under gravity 70; mouse / touch steers toward the pointed spot (clamped to the track; a spot near a creature's back snaps onto it); without pointer input it homes on the picked creature. Land on any back → mount with dip, puff in the zone weather colour and camera shake; hit the snow → faceplant. Chase camera turns toward the aim, FOV +14° in slow motion, trail in the zone weather colour. Tunables: `SS_Config.Leap`.
- **Same-lane gap with longer meshes:** pushes from the ridden creature now propagate up the chain (first run with meshes had 5.7-stud gap).

| Check | Result |
|---|---|
| BOT with zone-1 meshes (evidence/82) | 19/19 |
| BOT with the leap (91) | 19/19, 60 fps worst 19 ms; swaps 4/4 land via the leap |
| Scripted leap, no pointer (85–86) | ~20-stud arc, lands on a musk ox |
| Leap steered left with the mouse (87–89) | lands on the Woolly Reindeer in the left lane, `success` |
| Before the track clamp (90) | steering at empty snow left the track → faceplant; fixed by the clamp |

**Uploads (D1):** 5 creature meshes + their palette textures + 5 model assets (ids not listed yet). No Animation uploads yet.
**Not verified:** touch steering on a phone; how the leap feels to a human (only scripted/mouse tests); the other 3 clips in game.

## Milestone 8 (part 3): owner playtest changes, auto-landing leap, varied herd, flyers (2026-10-29, night)
Place SHA256 8f60ab72427639cb…. `src/` synced byte for byte (SYNC SS_Config=18403 SS_Path=6081 SS_Markers=15388 SS_Timeline=7866 SS_Track=2582 SS_Ride=44671 SS_Env=14463 SS_Bot=17176 = file sizes). No uploads.
Owner feedback (AskUserQuestion): the leap should land almost automatically once you're on a good line ("like Ride a Dino"), with aiming/camera and landing/miss changes. Also wanted: many animals across the mountain, some very fast and some slow, bigger and rarer ones, and birds/dragons to stand apart from Ride a Dino. Decisions: **full auto-target**; flyers **rideable (glide-leap) + 5 rare, hard-to-get rideable flyers near the top only**; rare/big = **speed + score bonus**; build **behaviour first, greybox**.
- **Auto-target leap:** the aim always locks the creature whose back is nearest the pointer's spot (never the one you left, within 2× SwapRange ahead). In the last `Leap.Magnet` 0.45 game s the flight bends onto its back and lands at the planned time, so every leap lands. A miss can only happen with no target at all.
- **Speed tiers:** each zone now has fast (1.45–1.5×) and slow (0.75–0.85×) species. A blocked faster creature pulls out into a free neighbouring lane, easing across at `PassEase`, retrying every `PassRetry`, so runners pass you. Without this, slow leaders made convoys, and the first run had a 31.5 s remount wait (BOT FAIL).
- **New greybox species (spawn by `Weight`):** a big rare runner per zone (Score ×3), a common rideable flyer per zone (Fly 14–16 studs), and 5 rare flyers in zones 3–4 only (Cinder Wyvern, Lava Drake, Aurora Dragon, Starwing Drake, Crystal Phoenix; Weight 0.12, Score ×5, speed 1.6–1.8). Colours are LOOKDEV tokens (hex noted in SS_Config). Flyers flap greybox wings, glide on a slow swell, keep their own air-layer lane gap and are never remount targets. Riding one lifts the camera. Leaping off one uses `Leap.Glide` 0.5 gravity.
- **Score:** points per stud ridden × the mount's Score (top-right label, `×N` when on a big/rare mount).
- **BOT changes:** the species check counts only common species (Weight ≥ 1; extras are chance spawns), and "herd in lanes" skips creatures mid lane-change (`Passing` attribute).

| Check | Result |
|---|---|
| BOT run 1 (before lane overtaking) | 18/19: fail at 1500 remount 31.5 s (convoy behind a slow leader) |
| BOT run 2 (with overtaking; includes the other session's SS_Timeline + new timeline check) | **19/20**: all of mine pass. Swaps 4/4 incl. one onto a flyer (Crevasse Gull-Kite), remount 6.9 s / 2.7 s, herd 424 recycles 0 in view, min gap 14.0. **FAIL `timeline`** (z1 0.134/0.125 … z4 0.900/0.875), owned by session "Mountain concept expansion and progression" |
| PERF in run 2 | 15 fps: invalid, because Climb & Collect took the foreground mid-run (known throttle). Focused re-run still needed |

**Concurrency:** another session (Mountain concept expansion, P0 timeline HUD) edited SS_Ride/SS_Config/SS_Env/SS_Bot and sync.luau in the same minutes. Both change sets are on disk together, and Studio is shared, so runs must be serialized.
**Not verified:** how auto-target, flyers and score feel to a human; flyer/rare spawn odds over a long session; phone touch; a focused PERF reading.

## P0: progress timeline HUD verified (2026-10-29, late)
Place SHA256 2c0674bafb7f87a5…. `src/` synced byte for byte (SYNC SS_Config=18403 SS_Path=6081 SS_Markers=15388 SS_Timeline=7935 SS_Track=2582 SS_Ride=44836 SS_Env=14463 SS_Bot=17508 = file sizes). No uploads.
- **9b fix:** the check compared the marker with `S().d` read after the pixels; it now reads the marker and the timeline's own drawn distance in one frame (`SS_Debug "timeline"` → `p, d`) and checks geometry (pixels vs p, 0.01) and mapping (p vs d, 0.02) separately. `SS_Timeline:progress()` returns `p, lastD`.

| Check | Result |
|---|---|
| BOT run 1 (phone simulator 750x401) | **20/20** |
| BOT run 2 | **20/20** |
| 8 ui | timeline y 6-42, hint y 46-72, title y 82-150, no overlap |
| 9b timeline | z1 0.130/0.130/0.130 … z4 0.892/0.892/0.892; lit 0-3 and full 0-3 per zone; mount icon present in all 4 |
| PERF | 15 fps both runs: invalid, the Claude desktop window held the foreground (throttle) |

**Not verified:** focused PERF; the strip at full resolution on the phone simulator (only a small capture under the BOT log); a real phone.

## P1: 10 sections in the Sections copy (2026-10-29, late)
Place `StampedeSpire.Sections.rbxl` SHA256 ba061e88ec779552…, a copy of the P0 place with `SS_Mountain` parked in ServerStorage (`art/tools/studio/hideart.luau`) and `ShowGreybox = true`. `StampedeSpire.Greybox.rbxl` is untouched at P0 (2c0674ba…); its source is in `prototype/snapshots/src-p0-2c0674ba/`. `src/` synced byte for byte into the Sections copy (SYNC SS_Config=27526 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=44841 SS_Env=14837 SS_Bot=18438). No Roblox uploads.
- **Sections:** 10 zones, one biome each (owner order), Speed 22 -> 78 (x1.151 per section), 40 s each at tier 1, 17,960 studs, rise ~4,875. New biome looks and 30 greybox species from the approved r3 sheets via new LOOKDEV sections (`art/tools/sample_r3.py`, `art/palette_r3.json`).
- **Speed model:** `BaseSpeed` / `SpeedPerStud` / `SpeedMul` removed; `P.speedAt` = the section's `Speed`, eased in from the one below over `SpeedRamp` 40 studs.
- **Bends:** 6 (heading within ±8°, min radius 2,626, sideways drift -40..340). `art/tools/pathcheck.py` rewrites only `SS_Markers.PathCheck` (546 points) from `sspath`.
- **Cards:** "SECTION k / 10" above the biome name. **Fixes:** weather emitters now sum the weights of all sections sharing a type (before, the last one won); marker FX skipped while ShowGreybox (they belong to the old mountain); camera shake uses section 1's speed.

| Check | Result |
|---|---|
| BOT (phone simulator, Studio focused) | **27/27** |
| sections | 10, 17,960 studs, 400 s; every section 40 s (±10% allowed) |
| speed/lane | enter at the speed below, Speed from +40 studs to the end, rising every section; lanes never widen |
| species | 5/5 commons in all 10 |
| carry-on | all 9 borders on the same mount |
| swaps | 4/4 (sections 1, 4, 7, 10; Aurora Hart at 78 st/s) |
| fail -> remount | sections 3 and 10: 11.5 s / 2.0 s |
| timeline | 10 segments, z10 0.957/0.955/0.955, lit 0-9 |
| PERF | 53 fps, worst frame 89 ms, 3,152 parts |

**Not verified:** pace by feel (P4); how the 6 new biomes' judgement light values look (no art yet, greybox only); upper sections are sparser (5 creatures per lane per section over up to 3,120 studs) until the P2 herd pool; worst frame 89 ms may be the long-teleport spikes.

## P2: rider-relative herd pool (2026-10-29, night)
Place `StampedeSpire.Sections.rbxl` SHA256 fa1b57ebfea727fa…. `src/` synced byte for byte (SYNC SS_Config=28369 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=57125 SS_Env=14837 SS_Bot=20786). No uploads.
- **Pool** (`SS_Ride` "Herd pool", `SS_Config.Pool`): every biome's creatures are built once at load and parked (25 commons + 2 per extra species). Only biomes overlapping the window [rider-150, rider+700] are live, with a quota proportional to their overlap (about 25 in all, also across a border). Out of view = outside 120 behind / 250 ahead of the rider. Out-of-view creatures that leave the window, their biome or the quota are parked (ahead: faded out first). Refill picks species by weight (extras x zone `Rare`, commons balanced). Slow creatures respawn far ahead (from 300 studs, the far 250 of the window first) for the rider to catch; faster ones respawn behind and overtake. Only the rider's own biome respawns behind, and it may start up to 150 below its start. On foot, the rider's lane is tried first. Respawns fade in over 1 s. A rider move over 40 studs in one frame (debug teleport, summit reset) re-lays the window; frozen on the summit; the foothills reset runs at the top of the next frame.
- **Review:** a 3-critic design critique and a 3-lens code review with adversarial verification (two workflows) found and fixed: summit `startJump(nil)`; no remount near the bottom of section 1; the new section empty after a border; border density doubling; rares fixed per creature; pop-in at 250 studs; lazy-creation hitches; stale mount/leap after a respawn; top-up stalls near a biome end; uncatchable next-biome runners; flyer layers (`fly > 0` is one lane layer, as in the solver); probe speed overwrite; one-frame stale CFrames on the summit reset; and a `seenRecycles` counter that could never fire (now a camera test: park or respawn on screen within 300 studs, off for 1.5 s after a jump).

| Check | Result |
|---|---|
| BOT run 1 | 29/30: 10b 16 on-screen events (BOT nudges under the 200-stud jump), gap 8.9 |
| BOT run 2 | 29/30: 0 in view; gap 11.1 = a probe artifact (2nd probe picked a new creature) |
| BOT run 3 | **30/30** |
| species | 5/5 in all 10 (visiting each section) |
| fail -> remount | d 60: 4.7 s; Starts[4]+40: 4.0 s; Starts[3]+400: 7.8 s; Starts[10]+400: 2.2 s |
| herd (whole run) | 1,524 respawns, 0 on screen, min same-lane gap 14.0 |
| pool (ride across 3->4, 6->7, 9->10) | live <= 31/31/32, biomes <= 2, mismatch 0, ahead >= 7, native 69% / 64% / 67%, 0 on screen |
| PERF | run 1: 60 fps, worst 16 ms, 769 parts (P1: 3,152); runs 2-3: 15 fps (Studio not in front) |

**Not verified:** pop-in at 300-700 studs through each biome's haze (1 s fade); free camera turned downhill while on foot; skinned gallop after reparent (only zone 1 has meshes); phone perf.

## P3: progression, checkpoints + saving (2026-10-29, night)
Place `StampedeSpire.Sections.rbxl` SHA256 a16bd69a263260d9…. `src/` synced byte for byte (SYNC SS_Config=30704 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=59122 SS_Env=14837 SS_Bot=27369 SS_Shop=5605 SS_Progress=12407 SS_Save=4777). No uploads, nothing published.
- **Owner decisions:** every run starts at the bottom (join, summit, reset). A checkpoint (section end) only lights its node and counts toward the best section. Coins save all the time; a summit is an ascent (+100 coins). P3 scope: save + coins + ascent + upgrade shop (wider ring, steady stance). Medals and the Herd Journal are deferred. Score trust: the server caps the score (the owner was unsure; this was the recommended option).
- **Server** (`SS_Save` Script + `SS_Progress` module in ServerScriptService): the profile `{v, coins, ascents, best, score, upgrades}` uses DataStore `SS_Progress_v1`, with an in-memory JSON store when the place is unpublished (Studio uses that now). Autosave every 60 s when dirty, plus on leave and on BindToClose. A failed load never overwrites the save.
- **Validator:** the client reports `(d, cumulative score)` every 1 s. A run is valid if it starts within 300 studs of the bottom and stays inside a speed budget: herd speed x the fastest tier x (1+jitter) + leap steering, x1.2, banked over 2 s. A drop of more than 200 studs starts a new run; a faceplant does not. Accepted score is at most forward studs x the best species Score x 1.05, so rare mounts still pay. Coins = score x 0.01.
- **Client:** coin line and SHOP button under the score; the panel uses the zone's TitleStroke/TitleColor tokens (evidence/92). Upgrade levels set `SuccessWindow` (+0.04/level), `StanceTime` (-0.08) and `WobbleAmp` (-2). Prices are placeholders for P4.

| Check | Result |
|---|---|
| BOT (phone simulator 750x401) | **36/36** (P2's 30 + 6 new) |
| 12a progress self-test | 9/9: legit tier 1 (10 checkpoints, 1 ascent, exact coins), fastest rare flyer, faceplants + jitter, teleport, 3x speed hack, 20x score inflation (capped), high start / summit reset, migration, buy |
| 12b live reports | store memory, run valid, reported +81.0 = accepted +81.0, coins +1 |
| 12c shop | Ring 50 + Stance 40, coins 1000 -> 910, client tunables follow, broke -> "coins", maxed -> "max" |
| 12d save/load | memory store round trip equal (best 7, ascents 2, Ring 2, Stance 1); client restored; fixture back |
| 8c shop ui | coins x 681-736, button x 654-738 y 126-154, panel 320x190 fits, no clashes |
| 12e live anti-cheat | BOT teleports + summit earned no checkpoint or ascent (run invalid: start) |
| PERF | 15 fps (Studio lost the foreground mid-run, throttled): not a valid number |

**Not verified:** the real DataStore (needs a published place; the adapter code path is untested); a real rejoin across servers (the memory store lasts one server session); PERF with Studio focused; whether a creature name tag can sit over the coin line (one did in a capture; check 9 measures tags vs the old HUD only). Gotcha: the computer-use `type` action sends long text via the clipboard ("Typed (via clipboard)"), so the "type, don't paste" rule cannot be fully kept; the commands ran correctly. The first runner line raises a "Dangerous Command Detected" (HttpService) dialog in a fresh Studio: Continue once.

## P2b: herd-pool fixes from the herd sim (2026-10-29, night)
Source: the parallel session's model `HERD-SIM.md` (a model, not a playtest). Place `StampedeSpire.Sections.rbxl` SHA256 1f02a101d7090c0e…. `src/` synced byte for byte (SYNC SS_Config=31437 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=60782 SS_Env=14837 SS_Bot=31557 SS_Shop=5605 SS_Progress=12407 SS_Save=4777). The Greybox place is unchanged (2c0674ba…). No uploads.
- **Fixes** (`SS_Ride` pool + lane solver, tunables in `SS_Config`):
  - **Yield:** a creature pushed by your mount steps into a free lane, and anything faster pulls out from behind it, so convoys can't form.
  - **Stragglers tire:** past its own biome an unridden creature eases to `Pool.Tire` 0.3x its tier at 0.5x/s, drops behind you and recycles there.
  - `RecycleClear` 120 -> 60.
  - `FrontBand` 250 -> 400 (= Ahead - ViewDist).
  - Per-section herd size `Zones[k].Herd` 8,7,6,6,5,5,5,5,4,4.
  - A swap target is no longer held still in the lane solver (it waits behind the mount and is pushed ahead of it), which fixes the 6.6-stud overlap.
  - The run starts at d 5-30 (before: the lowest creature of a uniform re-lay, often 100-250 up).
- **Tire 0.3, not the sim's 0.7:** at 0.7 a steady tier-1 rider still had native 15-35% at +250 and up to 6 biomes in the model. At 0.3: native >= 51% at +250 in every section, <= 3 biomes, no-target 10%, live max 54, 0 in BOT view, total 400 s (`sim/herdsim.py run --policy normal --seeds 4 --yield --straggler-drop 0.3 --recycle-clear 60 --front-band 400 --per-lane-sec 8,7,6,6,5,5,5,5,4,4`). The swap-target and start fixes are not in the model.
- **BOT:**
  - New **10d continuous ride**: teleport once to section 2 +300, then ride with no teleport and no swap to section 4 +300.
  - 10c cap = the larger live-biome quota + 15. Biomes limited to <= 2 out of view (sim: up to 4 overall). Ahead >= 2.
  - Fail -> remount must be <= 15 s.

| Check (run 1, phone simulator) | Result |
|---|---|
| BOT | **36/37**: 10c failed only on its old "ahead >= 4" (6->7 had 2); threshold now 2 per the sim, re-run pending |
| 10d continuous ride 2->4 | PASS, 55 s: live <= 43 (cap 50), stragglers avg 7% / max 25%, biomes <= 2, far <= 2, mismatch 0, native s2 100%, s3 87% (+250: 100%), s4 52% (+250: 100%), in view 0, min gap 14.0, ahead >= 2 (mean 9.6), no target 14% (longest 4.5 s) |
| 10c pool 3->4 / 6->7 / 9->10 | live <= 33 / 29 / 22 (cap 45), far biomes <= 2/1/1, mismatch 0, native 100% x3, in view 0 |
| 10b herd | 1,899 respawns, 0 in view, min same-lane gap 14.7 |
| fail -> remount | 4.7 / 4.4 / 3.4 / 1.8 s |
| summit | back on a creature at d=47 |
| PERF | 15 fps (Studio not the real foreground window): not valid |
| BOT run 2 (synced SS_Bot=31386; Studio unfocused, the other session's window was in front) | **36/37**: 10d failed only on no-target **19%** (then limit 15%), longest gap 6.0 s. Everything else passed: 10c 3->4 / 6->7 / 9->10 live <= 33 / 28 / 22 (cap 45), ahead >= 7 / 10 / 10, native 100% x3; 10d live <= 40 (cap 50), stragglers avg 8% / max 24%, native s3 89% s4 61% (+250: 100%), in view 0, gap 14.0, ahead >= 5 (mean 10.8); herd 1,683 respawns, 0 in view, gap 14.6; remounts 4.3 / 1.9 / 2.3 / 3.5 s; summit back on a creature at d=32 |
| 10d no-target recalibrated (synced and saved; BOT not re-run with it) | the sim's 15% is for a player who swaps. The sim's never-swapping rider (`--policy none`, same fix set) gets 20% / 22% in sections 2 / 3 with p95 gaps of 11-13 s. The BOT never swaps and measured 14% / 19% with longest gaps of 4.5 / 6.0 s. **New limit: share <= 25%, longest <= 12 s**; both runs pass it. Not re-run a third time. |

**Not verified:** no-target 14-19% on the continuous ride is close to the 15% limit; real fog distance (ViewDist / RecycleAhead stay 300 / 250); how tired stragglers read visually as they slow down; perf of up to ~55 live creatures on a phone.

## P4 start: BOT re-run, focused PERF, decisions (2026-10-29, late night)
Place `StampedeSpire.Sections.rbxl` SHA256 ebaba86b8e1fd259…. `src/` synced byte for byte (SYNC SS_Config=31437 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=61142 SS_Env=14837 SS_Bot=34061 SS_Shop=5605 SS_Progress=12407 SS_Save=4777). Greybox unchanged (2c0674ba…). No uploads, nothing published.
- **Owner decisions** recorded as SECTIONS-PLAN S10-S12 (dragon Weight, r3 extras deferred to M9, economy kept, **medals + Herd Journal in P4**, STREAMING Q1-Q8, species Q1-Q7).
- **Rare flyers Weight 0.12 -> 0.05** (all 5: Cinder Wyvern, Lava Drake, Aurora Dragon, Starwing Drake, Crystal Phoenix; `sim/herdsim.py` mirrored). Sim, 4 seeds, P2b fix set: rare flyers seen per run 7.2 -> 3.2.
- **10b herd-gap fix (BOT):** the check sampled while the last occlusion probe was still parked; the lane solver skips clamping behind the probe, so a follower sat at the probe 5.7-7.7 studs behind the mount (reproduced twice). New debug action `probeOff`; BOT releases the probe before 10b. Now 14.0 (PASS, x2).
- **BOT `("ride")` mode:** 10d + PERF only (~90 s), so a run fits inside a focused window. 10d and PERF move to module-level functions; a run under 30 fps is reported `SKIP … throttled` (10d) or flagged (PERF) instead of counted.
- **10d recalibrated (owner):** "ahead >= 2" replaced by **empty-ahead <= 10% of the ride and <= 8 s at a stretch** (mean >= 5 kept). The P2b sim itself gives min 0 in s2-s10 (never-swapping rider: empty up to 5.7%, longest 6.7 s; `--policy none`, both Weights).
- **10d mount held at tier 1** (`mountSpd` debug action): the BOT rode whatever it had (Musk Ox 0.75 -> 111 s, s4 native +250 18%); the sim's limits are for tier 1 (sim `--policy slow` 0.8: s4 @+250 34%).

| Run | Result |
|---|---|
| Full BOT x4 (phone sim) | 35/37, 35/37, **36/37**, **36/37**: after the probe fix only 10d fails. Focus: the C&C Studio (8444) or the Claude app took the foreground mid-run in every full run (22:31, 22:41, 22:45), so those 10d / PERF numbers are not valid |
| **PERF, focused** (ride mode, Sections foreground the whole run) | **60 fps, worst frame 18-19 ms**, 791 parts (17 meshparts), Studio total 3.5-3.9 GB (x2) |
| 10d focused, tier 1 (ride mode, 75 s) | **FAIL** on native only: s4 avg 7% / +250 12% (limit 30%); s3 83% / 80%; live <= 45 (cap 50), stragglers avg 12%, biomes <= 2, in view 0, gap 13.8, empty ahead 7% longest 3.2 s, no target 0% |
| 10d focused, earlier (Taiga Elk, no tier pin) | FAIL only on the old ahead >= 2 (ahead 0, mean 8.0); s4 native 42% / 80% |

**Open:** 10d s4 native at +250 swings 12-100% between runs (P2b: 100%, 100%; tonight 80%, 18%, 12%) while the sim (tier 1) gives 51%. Not yet explained: the Studio pool vs the model differ at the s3->s4 border. 10d stays red until that is understood (not re-tuned). P4 fog / visible-distance measurement not started. Gotchas: the command bar is multi-line (Enter adds a line; **Ctrl+Enter runs**); computer-use `type` pastes via the clipboard, so a clipboard change at that moment pastes the wrong text (it happened once: prose went in and failed as a syntax error, no effect). Verify the command bar text by zoom before Ctrl+Enter. The first Sections Studio (PID 28124) exited without a crash record at ~22:20 (no unsaved work); reopened as PID 34180.

## P4: 10d s4 native swing explained, Tire 0.3 -> 0.15 (2026-10-29, late night; src + sim only, not yet in Studio)
- **Not a Studio-vs-sim divergence.** The sim's "s4 @+250 51%" was a mean pooled over seeds; the BOT takes the **minimum** over +250..300 in one run. The sim's per-run minimum (12 seeds, P2b set, Tire 0.3) ranges 0-100% in s4 (tier-1 policy: 0, 14, 20, 29, 33 … 67; never-swapping: 0, 20, 22, 33 … 100), so the Studio's 12% / 18% / 80% / 100% fit that spread.
- **Cause:** every non-native in view there is a tired s3 creature (0.3x), mostly a fast species (spd 1.1-1.6) that was spawned behind as an overtaker. It needs ~25 s to cross the view at tier 1 (~1,000 studs), so it crosses the border in view, tires, and drifts back. At 0.3x it leaves the back of the view right around the time the rider reaches +250, so the reading flips between 0 and 100%.
- **Rejected:** "no rear spawn unless it can pass before the biome ends": worst run s4 33%, but no-target 11% -> 32% (p95 20 s), fades in view 474 -> 788 per run.
- **Taken: `Pool.Tire` 0.15** (sim, 12 seeds, both policies): worst-run native at +250 is 67% in every section (0.3: 0%; 0.2: 0% in s9; 0.1: 83%, but stragglers almost stop). No-target 12% / 9%, swap chances 38.2 / 31.5 per min, live max 54, fades 495 / 487 per run, total 378.6 / 390.7 s: all unchanged from 0.3. The 10d limit (30%) is not loosened.
- **Studio/sim divergence fixed:** `SS_Ride` kept a tiring creature's reduced speed after you mounted it (the sim resets it). Now a mount or swap target always runs at its own tier. The BOT's `mountSpd` sets `spd0` too (otherwise the reset would undo the tier-1 pin).
- **Sim:** the tire rate runs in game time (as in `SS_Ride`); the summary prints the worst run's minimum native at +250 (the BOT's statistic).
- **Pending:** sync (`SS_Config` 31671, `SS_Ride` 61295; `src/` != Studio until then), then BOT `("ride")` focused, then full BOT. How 0.15x stragglers look on screen is not verified.

## P4: Tire 0.15 + lane-solver stale-lead fix in Studio (2026-10-29, late night)
Place `StampedeSpire.Sections.rbxl` SHA256 b886f6a10db4f34c…. `src/` synced byte for byte (SYNC SS_Config=31671 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=61490 SS_Env=14837 SS_Bot=34061 SS_Shop=5605 SS_Progress=12407 SS_Save=4777). Greybox unchanged (2c0674ba…). No uploads, nothing published.
- **Lane-solver fix (`SS_Ride` + sim):** the follower pass clamped each creature behind `l[i-1]` even when that one had just pulled out into another lane, dragging it back into the gap (Studio 13.4-13.8 behind the mount; the unpatched sim 11.9-13.3). Now it clamps behind the nearest one still in the lane. Sim min gap: 14.0 in most sections. A rarer case is left: a creature that pulls into a lane whose chain was already pushed this frame (sim 13.0-13.7 in a few sections).
- **Owner (P4):** Tire stays 0.15. 10d's empty-ahead limit (10%) stays and stays red: the fix belongs to P4's fog measurement (ViewDist / RecycleAhead decide how close ahead natives spawn). The 10% was taken from a pooled sim share; per run (sim, 10d window, 16 seeds) Tire 0.15 gives up to 21% / 8.4 s, Tire 0.3 up to 9% / 6.6 s.

| Run (Studio in front the whole time) | Result |
|---|---|
| BOT ride, after Tire 0.15 | 10d: native s3 100% / s4 100% at +250 (was 12-18%); fail only on min gap 13.4 (Crevasse Ibex ahead of the mount) -> lane-solver fix |
| BOT ride, after the solver fix | 10d: gap 14.0, native 100% / 100% at +250; fail only on empty ahead 11% (longest 5.6 s). PERF 60 fps, worst 19 ms |
| **Full BOT** | **36/37**: only 10d fails (empty ahead 15%, longest 6.7 s; limit 10% / 8 s). Herd gap 14.0, pool 3->4 / 6->7 / 9->10 native 100% x3, in view 0. **PERF 60 fps, worst frame 18 ms**, 791 parts, Studio 3.3 GB |

## P4: fog measurement, re-measure and far fade (2026-10-29 late night - 2026-10-30)
Tool: `art/tools/fogmeasure.py` (capture + analyse) with BOT mode `SS_Bot("fog")`: per section the mount is held mid-section (camera at Cam.Fov 66), herd / HUD / particles / the rider are hidden, and the section's 5 common species stand one per lane at 75..1500 studs, shown and hidden in turn; the sampler pairs the frames (code square + magenta corners) and measures the peak Weber luminance contrast each creature adds inside its projected rect, against a hidden-frame noise floor. **Readable = >= 4 px tall and >= 5% contrast (owner).**
- **First pass (invalid, do not use):** Size boxes instead of the real models, the rider in front of the lane-3 target, and Studio lost the foreground ~52 s in. A throttled background Studio draws less far, which looked like "0% from 500 studs" in s3-s10. Its 350/400 table went into src for a few hours and was then replaced. Found by the review workflow below.
- **Re-measure (valid: real creature models via the new SS_Ride debug action `fogTargets`, rider hidden, Studio in front for all 245 samples):**

| Sec | atm density / haze | peak contrast at 300 / 450 / 600 / 900 | readable, tier-1 ride FOV | readable, FOV 66 (on foot / slow mounts) |
|---|---|---|---|---|
| 1 | 0.30 / 1.40 | 91 / 87 / 81 / 61% | 700 | 800 |
| 2 | 0.45 / 2.60 | 54 / 20 / 6 / 2% | 600 | 600 |
| 3 | 0.42 / 2.20 | 55 / 32 / 21 / 6% | 600 | 700 |
| 4 | 0.40 / 2.00 | 58 / 43 / 33 / 11% | 600 | 700 |
| 5 | 0.35 / 1.80 | 60 / 52 / 30 / 8% | 550 | 600 |
| 6 | 0.45 / 2.60 | >100 / >100 / 11 / 23% | 550 | 700 |
| 7 | 0.40 / 2.00 | 74 / 51 / 22 / 17% | 550 | 600 |
| 8 | 0.28 / 1.20 | 71 / 68 / 57 / 36% | 550 | 600 |
| 9 | 0.30 / 1.60 | >100 at all four | 450 | 600 |
| 10 | 0.25 / 1.00 | >100 at all four (near-black sky) | 500 | 600 |

- **Conclusion:** the Atmosphere is not what ends visibility on the phone (only s2 fades out, ~6% at 600); creature size is. Heights come from model bounding boxes, so horns count (slightly generous). Spawning ahead past these distances fails 10d in 6-14/16 sim runs at any Ahead.
- **Owner (P4):** keep spawning ahead at **ViewDist 350** and **fade respawns ahead in (and out) over `Pool.FarFade` 2 s** instead of thicker fog or a bigger herd. `Pool.Readable` = the ride-FOV column. BOT 10b / 10d now also require **0 fast pops** (a fade-in quicker than FarFade inside Readable). FarFade 2, not 3: at 3 s the slower fade-outs kept up to 62 live (10d cap 60) in 2/48 sim runs.
- **Pool changes in the same pass:** `Pool.Ahead` 700 -> 500 (owner) -> **420** (after the leaving fix below: 500 failed 2/48, 420 0/48, empty 0%); 10d live cap **quota + 25** (owner; was + 15); on-foot quota fix (stragglers past their biome don't fill its quota while the rider is on foot: sim casual rider went from 4/8 runs stuck 60 s to 0); over-quota excess fades out only the excess, and a cancelled fade-out eases back over FarFade (it snapped back in 0.3 s inside Readable, ~9 times per 10d ride in the sim); the mount's push now runs after the follower pass, over creatures still in the lane (its gap holds at frame end).
- **Sim** (`prototype/sim/herdsim.py`): new `ten-d` command = the BOT's 10d per run, defaults = src (`--p2` = old pool). Final: **0/48 runs fail** (worst empty 0%, no target 9%, live 59 / 60, 0 in view, 0 fast pops); P2 pool 11/16. Full ride, 8 seeds: every policy summits, no stuck, remount <= 7.5 s, live max 57-67.

## P4: medals, Herd Journal, rider feed, glow, pace, prices (2026-10-30)
Place `StampedeSpire.Sections.rbxl` SHA256 c942e383b27374fe…. `src/` synced byte for byte (SYNC SS_Config=36247 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=71295 SS_Env=14837 SS_Bot=43634 SS_Shop=5605 SS_Journal=10678 SS_Progress=18885 SS_Save=6100 SS_Stream=5129). Greybox unchanged (2c0674ba…). No uploads, nothing published.
- **Owner decisions:** medals by section time (GOLD <= 30 s, SILVER <= 40 s, BRONZE = finished), drawn as 1-3 pips in the section's TitleColor (no new colours); Journal = one page per section, locked until reached, species + swatch + ridden count, ??? if never ridden, best time + medal; in-range **glow** (Highlight + PointLight, pulsing, section Accent; s8 uses its TitleColor #C3EBFD because its Accent is a dark horn colour) replaces the untraced gold SelectionBox; **Herd s5-s10 -> 6,6,6,6,5,5** (the upper road looked empty on the tour); **shop prices x2** (Ring 100..1800, Stance 80..1500: first upgrade after one run, the whole shop after ~24 runs / ~2.6 h at ~280 coins per tier-1 run, sim).
- **Server:** `SS_Progress` profile v2 (`medals`, `times`, `ridden`; v1 migrates), section times from interpolated d = 0 / border crossings on valid runs only, Ridden reports queued and credited at the next report (within 300 studs, sections k-1..k+1); `SS_Save` Ridden remote and a flagged spawn report (d -30 at summit reset / respawn starts a new run; may skip MinReportGap once per 3 s); `SS_Stream` (new): 4 Hz rider feed, focus part as ReplicationFocus after the first feed, prefetch 6 s ahead at a client-clock speed, `Prepare(d)` before the summit reset and debug teleports, respawn re-focus with a 1 s hold against stale feeds.
- **Client:** `SS_Journal` (new): JOURNAL button under SHOP, two-column panel under the hint line, medal toast under the buttons.
- **Review:** two adversarial review workflows (5 reviewers + 2 skeptics per finding each; 98 agents). Round 1: 16 confirmed (incl. the invalid fog pass, respawn focus, dropped first ridden mount, short section-1 time, glow strobing, uncoloured JOURNAL button). Round 2 on the fixes: 14 confirmed (incl. a restart exemption that doubled a coin-farm loop, the Journal running past the GUI bottom, snap-back fades, the follower/push order). All fixed; refuted ones dropped.

| Check (phone simulator 750x401, Studio in front for every frame-timed run) | Result |
|---|---|
| BOT ride, final | 10d PASS: live <= 54 (cap 60), empty 0%, no target 5%, in view 0, fast pops 0, min gap 14.0. PERF **60 fps, worst frame 18 ms**, 791 parts |
| Full BOT before the round-2 fixes | 40/40 (journal ui, S1, S3, medals 10/10, journal ridden 11/11 in the self-test) |
| **Full BOT, final** | **40/40** (Studio in front for all 331 samples): 10d live <= 56 (cap 60), fast pops 0, gap 14.0; herd 2,069 respawns, 0 in view, 0 fast pops; journal ui panel y 76-270 of the 343 px GUI area; S1 max 27 studs; self-test 11/11 |
| S1 / S3 (rider feed) | focus within 14-25 studs of the client d (limit 50) after the summit reset and 5 teleports incl. s10; a slab under the rider after every jump, prepare <= 0.07 s (Play Solo) |

**Not verified:** a live server (feed latency, DataStore, stale feeds after a real respawn); the far fade-in by eye on a phone; the Journal panel on a real phone; Studio-only perf (M7 next, `M7-CHECKLIST.md`). No uploads, nothing published.

## P4: M7 prep: streaming settings + perf recorder (2026-10-30)
Place `StampedeSpire.Sections.rbxl` SHA256 67bffaeffa70a47a…. `src/` synced byte for byte (SYNC SS_Config=36839 SS_Path=6340 SS_Markers=43659 SS_Timeline=7935 SS_Track=2582 SS_Ride=72057 SS_Env=14837 SS_Bot=44622 SS_Shop=5605 SS_Journal=10678 SS_Perf=9854 SS_Progress=18885 SS_Save=6100 SS_Stream=5129). Greybox unchanged (2c0674ba…). No uploads, nothing published.
- **Workspace streaming (STREAMING-PLAN §2):** ModelStreamingBehavior Default -> **Improved**, StreamingMinRadius 64 -> **128**; StreamingTargetRadius 1024, StreamOutBehavior Opportunistic, StreamingIntegrityMode PauseOutsideLoadedArea were already set; StreamingEnabled true. Gotcha: in Studio 0.745 only `StreamingEnabled` is visible to the command bar ("not a valid member of Workspace" for the other five), so they were set in the Properties panel (filter "stream").
- **Perf recorder `SS_Perf` (new, client; `C.Perf` Enabled true for M7, MemEvery 1; `C.Ui.Perf` Width 360 / Row 18 / Text 12):** per section from raw RenderStepped dt: FPS avg, 1% low (mean of the slowest 1%), worst frame + d + state; every 1 s: Stats total + GraphicsMeshParts / GraphicsTexture / Instances / PhysicsCollision (max), live creatures (max), BaseParts in workspace (counted incrementally), gameplay pauses (LocalPlayer.GameplayPaused is readable in Play Solo). A teleport (> Stream.JumpStuds in one frame) marks the run TELEPORTED. At the summit: `PERFREC` lines (client log) + a card under the hint line (summit section's TitleStroke backing at Timeline.Back / TitleColor outline, section numbers in each section's TitleColor, white GothamBold), closed by X. **BOT 8e:** the card filled with the widest values fits the GUI area below the hint, clears SHOP / JOURNAL, no cell text cut.
- Sections Studio PID 29952 exited at ~12:00 with no crash record (place on disk was clean, c942e383); reopened as **PID 35344**. Studio shows "Restart to update".

| Check (phone simulator 750x401, Studio in front for every frame-timed run) | Result |
|---|---|
| BOT ride | 10d PASS: live <= 56 (cap 60), empty 0%, no target 0%, in view 0, fast pops 0, gap 14.0. PERF **60 fps, worst 18 ms**, 792 parts (107/107 samples PID 35344) |
| **Full BOT** | **41/41** (337/337 samples PID 35344 through the result): perf card x 195-555 y 76-330 of 343, no clash, no cut cells; S1 max 12 studs, S3 prepare <= 0.06 s; herd 2,020 respawns, 0 in view, 0 fast pops; 10d live <= 48. PERF 60 fps / 19 ms, 890 parts |
| Recorder during the full BOT (TELEPORTED run, not clean) | fps 59.8-60 all sections; 1% low 36.5 (s1) / 44-52.4; worst 135 ms at d 684 (s1, ride) else 19-23 ms; **1 pause in s1** (PauseOutsideLoadedArea fired once in Play Solo, during the teleport-heavy part); live <= 45; parts 988-1,236; mem tags mesh 4 / tex 36-38 / inst 105 / phys 0 MB |

**Note:** Studio total memory now reads 8.6-8.9 GB (P4 runs before: 3.3-3.9 GB) in the freshly reopened Studio; the tags are unchanged (tex 30-44, inst 104-105 MB), so it is Studio's own process, not the place. **Not verified:** the card and PERFREC lines on a real phone; whether the s1 pause recurs on a clean ride. Next: M7 (owner's phone + one private unlisted publish the owner clicks, `M7-CHECKLIST.md`).
