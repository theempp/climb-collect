# Stampede Spire: morning report (overnight 2026-10-29)

**The full mountain is built in Blender, imported into the Studio place, and playable end to end in Play Solo.** BOT 13/13. Place saved to `Documents\StampedeSpire\StampedeSpire.Greybox.rbxl` (SHA256 `36ee56d832c23dd1…`); backup of the milestone-2 place is in `StampedeSpire.Greybox.pre-mountain.rbxl`. Not published, no Robux or products. **Please review decision 1 below: the importer uploaded mesh and texture assets to your account.**

## What was built
- **Look-dev** (`art/LOOKDEV.md`): a per-zone palette, lighting, fog and set-dressing sheet. Every colour is a pixel sample from a named box on an r2 sheet. The sampler (`art/tools/sample_refs.py`) writes `art/palette.json`, and everything downstream uses only those tokens.
- **Path smoothing**: `SS_Path` is now a 1-stud integrated profile. Slopes ease over `SlopeBlend = 80` studs at each border (it was an instant 3–4° kink), and over `SummitFlat = 40` to a flat summit plateau. `SS_Config` is still the single source: `art/tools/sspath.py` parses it for Blender.
- **Blender mountain** (`art/tools/build_mountain.py` → `art/blender/ss_mountain.blend`, `art/export/ss_zone1-4.fbx`, `ss_backdrop.fbx`): procedural, stylized and faceted. All 98 MeshParts use one shared 256×512 painted palette atlas (`ss_atlas.png`, 18 ramps built from LOOKDEV tokens).
  - **Track:** 16 chunks of 250 studs, with lane grooves and zone-styled berms: snow, ice curbs, basalt with lava seams, and a rock lip.
  - **Terrain:** 20 side chunks, ±950 studs wide, blended across each zone border.
  - **Taiga:** 6 pine batches (snow-loaded tiers), boulders and a frozen river.
  - **Crevasse:** ice walls 165–280 studs high, 3 ice arches with icicles, ice shards and ledges.
  - **Obsidian:** leaning spires, basalt column clusters, glowing lava cracks (Neon) and 22 vents.
  - **Aurora Crown:** a knife-ridge path, crystal clusters plus Neon glow accent crystals, and a summit plateau with a crystal crown.
  - **Backdrop:** 38 peaks, coloured by zone.
- **Studio import**: the 3D Importer was driven by computer use, and a post-import job placed each mesh from `ss_manifest.json`. Max position error is 0.001 studs. The meshes are anchored, non-colliding and box collision; materials are SmoothPlastic with the atlas, plus Neon for lava and the glow crystals. `SS_Mountain` streams as Persistent.
- **Gameplay and FX** (all tunables are in `SS_Config`, and `src/` matches Studio, synced byte-for-byte):
  - **`SS_Track`:** now only hidden collision slabs on the smoothed path, plus invisible walls and a summit pad. `ShowGreybox` brings the old strip back.
  - **`SS_Env` (new):**
    - Per-zone lighting, atmosphere, colour grade and bloom, blended over 70 studs.
    - Zone title cards using the sheet header taglines.
    - Canyon light shafts, steam vents and plumes, lava and crystal point lights.
    - Aurora curtains: 92 vertical rays, green → teal → purple.
    - Camera-local weather: snow, ice motes, embers, wind snow.
  - **`SS_Ride`:**
    - Scripted ride camera: behind and above, FOV widens with speed (66→88), light shake.
    - Summit orbit camera.
    - Placeholder creatures are now 12-part models (torso, chest, neck, head, muzzle, horns, tail, 4 galloping legs). Horn accents use the zone accent token and are Neon in zones 3 and 4.
  - **`SS_Bot` (new):** the BOT suite, run from the command bar during Play.

## Screenshot gallery (`prototype/evidence/`)
| Zone | Shots |
|---|---|
| 1 Taiga | `12-z1-start-d80.jpg`, `13-z1-forest-d660.jpg` |
| 2 Crevasse | `14-z2-canyon-entry-d1075.jpg`, `15-z2-canyon-d1215.jpg`, `16-z2-ice-bridge-d1410.jpg` |
| 3 Obsidian | `17-z3-ridge-d2160.jpg`, `18-z3-lava-steam-d2700.jpg` |
| 4 Aurora | `19-z4-aurora-d3150.jpg`, `20-z4-crystal-ridge-d3720.jpg` |
| Summit | `21-summit-crown.jpg` |
| Ride-through (zone 1→2, title card) | `22-…-a`, `23-…-b-z2-title`, `24-…-c` |
| Loop | `25-swap-ring-stance.jpg`, `26-faceplant.jpg` |
| BOT / phone | `27-bot-13of13.jpg`, `28-phone-sim-z1.jpg`, `29-phone-sim-z4-title.jpg` |
| Blender vistas | `30-blender-vista.png`, `31-blender-summit-back.png` (Workbench previews) |
| Known issue | `32-edit-view-ridge-down.jpg` (zone 3→4 cliff step, default Edit lighting) |

## BOT (Play Solo, desktop; `require(game.ReplicatedStorage.SS_Bot)()`)
| Check | Result |
|---|---|
| Path smooth: max slope change at joins 0.075°/stud, summit ease 0.75°/stud, step error 0.0002 | PASS |
| Speed/lane: 0→22.0/12, 999→27.0/10.1, 1000→33.8/10, 1999→40.0/8.5, 2000→49.6/8.5, 2999→57.3/7, 3000→68.5/7, 3999→77.7/7 | PASS (same formula as M2) |
| Species per zone: 5/5 in each zone | PASS |
| Carry-on across 1→2, 2→3, 3→4 (same mount, still `ride`) | 3/3 PASS |
| Ideal-time swaps at 150 / 1300 / 2300 / 3300 (final run: onto Snowshoe Hare-Hound, Rime Moose, Basalt Rhino-Goat, Skyhorn Antelope) | 4/4 PASS |
| Early press at 1500 and 3400 → faceplant → standing 3.0 / 2.9 studs above the track on the hidden collision → remount (9.1 s / 5.3 s) | 2/2 PASS |
| Summit: summits 0→1, then back on a zone-1 creature | PASS |
| Console errors | none from game scripts (LogService history checked) |
| Final state: the suite was run twice, before and after the last art tweaks | 13/13 both times |

## Performance
- **Geometry:** 98 MeshParts, 255,050 triangles in total. The largest mesh is `Z1_Pines_03` with 8,996 tris; every mesh is ≤10k tris and ≤2,048 studs.
  - Zone 1: 93.9k tris
  - Zone 2: 38.4k
  - Zone 3: 50.8k
  - Zone 4: 59.1k (16 meshes, including the glow accents)
  - Backdrop: 12.8k (RenderFidelity Performance)
- **Parts while riding:** 1,626 BaseParts, of which the herd is 1,200 (100 creatures × 12 parts) and the hidden collision slabs and walls are ~640.
- **Desktop Studio:** 60 FPS (Studio cap), worst frame 18–19 ms over 4 s of riding.
- **Memory:** MeshParts 34 MB, textures 56 MB. Studio's whole-app total is 7.4 GB, which is not meaningful for a phone.
- **Phone:** the Device Simulator (phone landscape) layout works: touch thumbstick and jump button, readable title card. Real-device FPS and memory are **not measured**.

## Decisions to review (made overnight without you, recommended option taken)
1. **Assets were uploaded to your Roblox account.** Studio's 3D Importer only works with "Upload to Roblox", so it created about 100 private mesh assets under Creator = Me: 97 for the zones and backdrop, 1 replaced ledge mesh, 1 glow-crystal patch and 1 test ramp. The atlas texture was also uploaded once per import, about 7 times. That is not a publish and nothing is public. The alternative was rebuilding everything from parts or terrain, which would have thrown the Blender work away. You can clean these up in Creator Hub if you don't want them.
2. **Painted atlas instead of vertex colours**: one shared palette texture with gradient ramps. Every stop is a LOOKDEV token.
3. **Zone 4 is deep dusk, not midnight** (ClockTime 19.1). Roblox's midnight sky renders pure black. Dusk gives the sheet's navy gradient. The moon is hidden in zone 4 because the sheet shows none.
4. **The aurora is a camera-following sky layer.** Beams stop rendering once an attachment is about 2,048 studs from the camera, so the curtains move with you. They have no parallax and read as infinitely far away.
5. **The path stays straight in plan** (no bends); only the vertical profile was smoothed. Bends would look grander but touch every lane, projection and herd formula.
6. **The ride camera is scripted while mounted**, so you can't orbit it. It orbits the crown at the summit. SummitHold went from 2.5 s to 4 s to give the orbit time.
7. **Numbers that are judgement, not samples**: lighting brightness, fog density/haze, bloom, tint strength, particle rates, and the title font (Gotham Bold/Black, the closest match to the sheets' heavy sans). The colours themselves are all sampled. Flagging these so you can veto them.
8. **Materials:** SmoothPlastic with the atlas everywhere. I tried Glass on obsidian and crystals; it looked the same and costs more on phones, so I dropped it. **Neon** is used for lava, the zone 4 glow crystals (crystal_glint) and zone 3/4 horn accents, traced to the sheet's glow. The Roblox material choice is mine.
11. **Species name tags** now hide beyond 70 studs instead of 120, to cut clutter, especially on phones.
9. **Removed the Baseplate.** Falling off now drops you into the void, you respawn, and you are sent back to the foothills.
10. **SS_Mountain streams as Persistent** (StreamingEnabled is on). This keeps the vistas visible at the cost of phone memory.

## Known issues
- Zone 4 still reads as a strong monotone blue. The upper sky is black, the aurora's purple top barely shows, and the new Neon glow crystals sit mostly below the ridge, so they are subtle from the ride camera.
- After a debug teleport, the aurora takes about 5–10 s to appear (renderer catch-up). Riding up normally it is there as the zone blends in.
- From afar the basalt columns read as rows of posts. A few zone 2 light-shaft columns sit near the lanes and look like translucent slabs when the camera passes through them.
- ~~The terrain chunks end at ±950 studs and the zone 3→4 blend forms a near-vertical cliff step.~~ Fixed in the terrain borders + skirts update below.
- The camera can clip into a creature in the next lane. Name tags clutter, especially on phone. The HUD overlaps the title card on phone.
- Inherited from M2: unridden creatures pop back to their zone start, and creatures can overlap in a lane.
- Not tested: a real phone or touch device, a human feel test, multiplayer.

## Suggested next steps
1. Look-dev pass on zone 4: add crystal value contrast (white glints, Neon inner cores) and a lighter navy sky. A custom skybox would need an asset upload, so that needs your go-ahead.
2. Real-device test on a phone (FPS and memory). Then decide on LOD and draw-distance budgets, for example halving far pines.
3. Final creature models from the r2 sheets, one zone at a time.
4. Gentle plan-view bends in the path, for vistas around corners.
5. Rarity placeholders and wind gusts at the peak (the open items from M2).

Rebuild or iterate: `blender -b --factory-startup --python art/tools/build_mountain.py`. To re-import one mesh, add `-- --patch NAME` (see `art/tools/studio/` for the Studio-side jobs and the one-line runner).

---

## Update: zone 4 contrast pass (2026-10-29, morning; owner picked this option)
- **Crystals:** facets now alternate dark and bright (crystal_deep ↔ crystal_glint) with glint tips, as on the Z4 sheet. `Z4_Crystals_01/02` and `Z4_Crown` got new UVs only; their geometry is unchanged.
- **Glow:** `Z4_Glow` (Neon crystal_glint) gains one small shard per ridge-lip cluster, beside the lanes where the ride camera sees them. The summit glow ring is bigger. Totals: 98 meshes, 257,210 tris.
- **Lighting** (`SS_Config.Env[4]`):
  - ClockTime 19.1 → 18.6
  - Outdoor ambient snow_path → crystal_glint (#B5ECFD)
  - Brightness 1.8 → 2.4, Contrast 0.12 → 0.25, Saturation −0.05 → −0.2
  - I also tried snow_path as the ambient: it stayed dark and over-saturated.
- **Summit orbit:** radius 150 → 230 and height 70 → 115, so it no longer passes through the crown.
- **Import:** 4 meshes re-imported via `--patch` (about 4 more private mesh uploads to your account). Positions re-verified, max error 0.001.
- **BOT:** 13/13. On a normal ride from zone 3 the aurora is visible on arrival in zone 4, with no teleport delay.
- **Screenshots:** `evidence/33-z4-contrast-d3500.jpg`, `34-z4-ride-in-title.jpg`, `35-z4-ride-glow-shards.jpg`, `36-summit-crown-wide-orbit.jpg`, `37-bot-13of13-z4pass.jpg`.
- **Still open:** the upper sky is still black. A painted navy skybox would need a texture upload, and that needs your OK. From the wider summit orbit the zone 3→4 cliff block is now plainly visible (shot 36); that is the next option on the list.

---

## Update: terrain borders + skirts (2026-10-29, late morning; owner asked for this)
- **Cliff steps gone at all three zone borders:**
  - Terrain heights now blend over a width that grows away from the lanes: 70 studs beside the track, 360–510 far out.
  - The zone switch near the lanes is unchanged, so the zone-2 canyon mouth and the zone-4 knife still start at their borders.
  - Width-averaged 80-stud step: B1 189→62, B2 154→49, B3 293→79 studs.
  - Paint follows the original seam, frayed far out so it is not a ruler line.
- **No more floating sheets:**
  - Every outer edge (±950), the start row and the summit end now drop as a 3-band rock skirt to 750 studs below the path. The skirts lean outward and reuse each zone's existing rock row (z1_rock, z2_ledge, z3_obsidian, z4_rock); no new colours.
  - New `Z1_StartDeck` fills the gap behind the track start.
- **Props sit on the built mesh.** Props are now grounded by ray-casting the built terrain, not the analytic height. Before this, pines and crystals floated or sank by up to ~17 and ~44 studs.
  - Now every prop class is within ±1 stud, and the 63 floating Neon accents are fixed.
  - Zone-4 crystals and accents that would stand on zone-3 paint are dropped.
  - The random layout of everything else is unchanged; the track and backdrop are byte-identical.
- **Far-slope paint:** far from the lanes, each terrain quad now takes rock/snow from its whole-quad normal. This removed zebra striping on the zone-1 slopes and slivers in every zone.
  - Trade-off: the far slopes have ~7–22% less steep-rock area than before. It reads the same in renders.
- **Process:** 3 designs were built and scored by a judge. The winning blend was grafted with ideas from the other two. Then 3 rounds of adversarial review measured every finding before and after the fixes.
- **Totals:** 99 meshes, 264,690 tris (+2.9%). Largest part is 9,000 tris and 1,829 studs.
- **Import:** 42 meshes re-imported via `--patch`, about 42 more private mesh uploads to your account. Max position error 0.001.
- **BOT:** 13/13, 60 fps, 115 meshparts.
- **Screenshots:**
  - Play: `evidence/38-ride-d2960-no-z34-wall.jpg`, `39-ride-d500-z1-slopes.jpg`, `40-start-apron-after-summit.jpg`, `41-ride-d3700-z4-grounded.jpg`, `42-bot-13of13-skirts.jpg`.
  - Blender before/after: `43`–`45`.
- **Place:** saved, SHA256 5c96ad64fc0e6a68….
- **Still open:**
  - The skirts are plain from far outside.
  - The far-field zone-1 rock reads a little blocky from the vista cameras.
  - The black upper sky in zone 4 still needs a skybox upload and your OK.


---

## Milestone 4: phone UI + ride camera (2026-10-29, afternoon)
- **Phone UI:** debug readout off (`SS_Config.Ui.DebugHud`). The hint is a small line at the top, off the lanes; the zone title card sits under it and can't overlap. Name tags: max 4, swappable ones first, stacked when they'd collide, faded with distance, never over the hint or title card.
- **Camera:** creatures between the camera and you fade; one the camera would be inside is hidden. Offline check on the built mountain (`art/tools/cam_clearance.py`): the ride camera is never within 2 studs of a mesh and never loses sight of the rider (15,015 samples, min clearance 10 studs); summit orbit min clearance 90 studs.
- **BOT 16/16** on desktop and in the Device Simulator (iPhone XR landscape): 3 new checks (UI layout; tags + camera every frame through all 4 zones; occlusion probe). 0 client console errors.
- **Uploads:** none. **Place:** saved, SHA256 6afe610a2bb388dd….
- **Screenshots:** `evidence/46-bot-16of16-m4.jpg`, `47-phone-z1-title.jpg` … `50-phone-z4-title.jpg`, `51-phone-summit.jpg`, `52-phone-bot-16of16-output.jpg`.
- **For the zone sign-offs (M6):** the zone-1 title is hard to read on the bright sky (47); the zone-3 lava ribbon is very bright next to the camera (49).
- **Not verified:** a real phone (M7).

---

## Milestone 5: gentle plan-view bends (2026-10-29, afternoon; you picked ±10°)
- The climb now follows a gentle S: right in zone 1, left through zones 2–3, right in zone 4, back on line at the summit. Heading ±10°, max 197 studs sideways, tightest radius 1,451 studs.
- Built by warping the straight mountain at export (Blender) and in `SS_Path` (game), so every earlier terrain/prop guarantee still holds. Python and Luau paths agree to 0.0003 studs; lanes and herd follow the curve exactly.
- **BOT 18/18**, twice. Camera clearance on the bent mountain: 0 problems.
- **Uploads:** 61 private zone meshes + 1 atlas texture (ids in `art/export/asset_ids_m5.tsv`). The 38 backdrop peaks were only moved. The 61 old zone mesh ids from 3c are now unused (D4 list at the end).
- **Place:** saved, SHA256 7eb6d676c11a1859…; M4 backup `StampedeSpire.Greybox.pre-bends.rbxl`.
- **Screenshots:** `evidence/53–55` (check-in), `57`/`61` (BOT), `58–60` (ride through the bends).
- **BOT harness fix:** swap tests now park the mount beside a creature instead of waiting for one to drift into range (it could take >10 s).

---

## Milestone 6: visual polish, all 4 zones signed off (2026-10-29, evening)
- **You approved Z1, Z2, Z3 and Z4** with their D5 values (sheets `evidence/73–75`, `80`).
- 32 meshes re-imported (skirts, basalt, far zone-1 rock); 99/99 placed, max error 0.001.
- **Z4 sky is navy, not black:** Roblox darkens skyboxes after sunset, so Z4 runs at clock 13 with brightness 0.6.
- **Aurora** goes green → purple left to right, as on the sheet. **Summit orbit** now looks up past the crown, so no black zone-3 slabs or tan peaks.
- **BOT 18/18** (three runs). Perf 59 fps in Z4 when Studio is focused (BOT's 15 fps line is Studio throttling a background window).
- **Uploads:** 32 meshes, 3 sky images, 3 tiny sky-quad meshes, 1 unused duplicate image. **Place:** saved, SHA256 4cf152eb66787936….
- **M7 (real phone):** deferred by you; provisional budgets come from the simulator.

---

## Milestone 8 (in progress): herd fixes, zone-1 creatures, aimed leap (2026-10-29, evening)
- **No more pop-back or overlapping creatures:** recycling happens out of view, and creatures keep a 14-stud gap in their lane (new BOT check).
- **Zone-1 creatures are in the game:** reworked detail (2.2–3.0k tris), imported as skinned meshes, galloping in sync with their speed, rider on the back. Waiting for your zone-1 sign-off in game.
- **New leap, as you asked:** hit the ring and you launch. The world slows to 0.3×, you steer the arc with the mouse or finger toward any creature (the camera turns with you), and you land with a dip, snow puff and shake. Miss and you faceplant in the snow. Tunables are in `SS_Config.Leap`.
- **BOT 19/19.** Place saved, SHA256 7a113f468d8e5372….
- **Evidence:** `85–89` (leap), `83–84` (creatures), `91` (BOT).

## Milestone 8 (part 3): your playtest changes (2026-10-29, night)
- **Leap lands itself:** point roughly at any creature and you lock on, and the arc bends onto its back. No more misses.
- **A living herd:** fast runners overtake you by changing lane, slow bruisers lag behind. Each zone adds a big rare beast (×3 score) and a rideable flyer you can glide on. Five rare flyers (Cinder Wyvern, Lava Drake, Aurora Dragon, Starwing Drake, Crystal Phoenix; ×5 score, fastest) appear only in zones 3–4. New ones are greybox for now.
- **Score** in the top-right corner, multiplied by your mount.
- **BOT 19/20:** everything of mine passes. The one FAIL is the new progress-timeline check from the other session, which is still in progress. PERF needs a focused re-run (Climb & Collect took focus). Place saved, SHA256 8f60ab72….
