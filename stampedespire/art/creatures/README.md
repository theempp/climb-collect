# Zone-1 creatures (M8 prep, 2026-10-29)

These are Blender-only stand-ins built ahead of M8, so M8 only has to import them. Nothing has been uploaded or imported into Studio yet.
Source sheet: **Z1** = `concepts/2026-10-29/r2-zone1-taiga.png`, which lists exactly five "native mounts". Lateral widths come from **RR** = `r2-rider-roblox.png` (front view), the only frontal view in the r2 set.

**Budget (M7, `prototype/PERF-BUDGET.md`):** ≤3k tris and ≤24 bones per creature. Every species is under both limits; the elk is closest at 2,928 tris.

| Species | .blend | Tris | Bones | Size W×L×H (m) | Clips |
|---|---|---|---|---|---|
| Taiga Elk | `taiga_elk.blend` | 2,928 | 22 | 2.19 × 5.07 × 4.09 | gallop, idle, swap_jump, faceplant |
| Woolly Reindeer | `woolly_reindeer.blend` | 2,816 | 22 | 1.39 × 4.41 × 4.01 | gallop, idle, swap_jump, faceplant |
| Musk Ox Calfrunner | `musk_ox_calfrunner.blend` | 2,920 | 20 | 2.00 × 4.89 × 3.26 | gallop, idle, swap_jump, faceplant |
| Snowshoe Hare-Hound | `snowshoe_hare_hound.blend` | 2,664 | 22 | 1.15 × 4.54 × 3.65 | gallop, idle, swap_jump, faceplant |
| Pine Boar | `pine_boar.blend` | 2,808 | 22 | 1.64 × 4.76 × 3.21 | gallop, idle, swap_jump, faceplant |

Sizes are bounding boxes including antlers, ears and tail. The musk ox has 20 bones because it has no ear bones (its ears are hidden in the coat on Z1).

## What's in each .blend
- **Mesh:** one object named after the species, block-built (bevelled boxes and wedges, planar faces). One material uses a packed palette strip (`<species>_palette.png`, 8 px per swatch, Closest filtering). Each face's UV sits on one swatch, so the PNG holds the token hex exactly.
- **Rig:** an armature named `Rig`: root, hips, spine, chest, neck, head, tail_1–2, then upper/lower/foot for each leg (fl, fr, hl, hr), plus ear_l/ear_r. Each block is skinned 100% to one bone (rigid parts, joints hidden by overlap).
- **Clips:** Actions with a fake user, plus one muted NLA track per clip; `idle` is the active action. All clips run at 30 fps.

| Clip | Frames | Loop | Content |
|---|---|---|---|
| gallop | 0–24 | yes | transverse gallop, one suspension per stride, ears back |
| idle | 0–60 | yes | breathing, head sway, tail swish, ear flick at f30 |
| swap_jump | 0–20 | no | crouch, leap with tucked legs (apex f10), land; in place, so the game moves the lane |
| faceplant | 0–48 | no | forelegs buckle, nose into snow (f10–26), rump up, recover, head shake (D9) |

- **Axes and units:** metres, forward −Y, up +Z, origin on the ground under the torso centre. 1 A (avatar height) = 1.98 m, from Z1's "R15 AVATAR (6.5 FT)" label. M8 should rescale on import to match the in-game rider.

## Where each visual value comes from
- **Colours:** `creature_tokens.json`, sampled on Z1 by `art/tools/sample_creatures.py` (box, percentile and filter for each token). The same tokens are listed in `art/LOOKDEV.md` → "PROPOSED (M8 prep)". Coat faces are banded by height into shadow / mid / light, so the painted gradient is a 3-step ramp from that species' own coat box.
- **Proportions:** Z1 side views, measured against the avatar beside each animal (`SPECIES` table in `art/tools/build_creatures.py`): torso length, withers, rump and belly heights, head position and depth, leg positions, and tail and ear placement.
- **Widths:** RR front view of the elk mount. Chest width is 0.82 × torso depth, head width is 0.88 × head depth, and the leg centres sit 0.47 × chest width apart. These ratios are applied to all five species; it's the weakest trace, because no species has its own front view.
- **Features:** each comes from the sheet image or its caption.
  - Elk: "frost-tipped antlers"; the mane ruff is Z1 x 245–310.
  - Reindeer: "short antlers, sled-bell harness".
  - Musk ox: horn boss, long-hair skirt, frosted back.
  - Hare-hound: long ears, saddle and girth.
  - Boar: "frosted tusks", bristle ridge.
- **Shape (block-built restyle, 2026-10-29):** owner-approved style refs "Ride a Dino" and "Steal An Egg" (in-game look, style only; study and build rules in `STYLE-STUDY.md`, sources in `concepts/style-refs/SOURCES.md`). Proportions still come from Z1 and RR only.
  - Torso: 7 segments × 3 height layers of bevelled boxes on the Z1 back/belly line, plus a back-ridge strip; the coat ramp goes by layer.
  - Head: skull, muzzle, jaw, nose pad and brow blocks; eye block + catchlight per side. Legs: upper, lower, cannon, then a 2-toe hoof (hare: paw with 3 claw blocks).
  - Detail by part count: hanging square locks (elk mane, reindeer and hare throat ruffs, musk ox skirt and beard), frost tiles (ox, boar), boar bristle wedges, stepped-block antlers, horns and tusks; tack as flat blocks.
  - Bevel: 5% chamfer, 1 segment, applied in the build (export uses `use_mesh_modifiers=False`).
- **Left out (no traceable token):** dark noses (reindeer, hare); inner ears (hare); the reindeer's bell-strap studs; the musk ox's and boar's ear detail.

## Rebuild
```
python art/tools/sample_creatures.py
blender -b --factory-startup --python art/tools/build_creatures.py      # add: -- --only elk
blender -b --factory-startup --python art/tools/render_creatures.py   # per-pose renders
python art/tools/render_creatures.py                                  # assemble renders/<species>.png
```
Previews are in `renders/<species>.png` (idle 3/4 view, gallop f6, swap_jump f10, faceplant f12). The preview backdrop, ground and sun use the Z1 LOOKDEV tokens sky_horizon, snow_mid and sun_glow.

## Open for M8
- Re-check the budget against M7's numbers. The meshes have plenty of headroom if M7 allows more detail.
- The block restyle replaces the meshes already exported and imported in M6. Re-run `export_creatures.py`, re-import the 5 FBX with the 3D importer, then run `art/tools/studio/creatures.luau` and sync. Seat `up` changes (studs): elk 1.52→1.50, ox 3.54→3.51, hare 1.03→1.08, boar 2.83→2.41 (old bristle tufts sat on the seat); reindeer unchanged. Bone names and layout unchanged.
- Frost on the musk ox and boar shows up as smaller whole facets and frosted locks (boar crest, ox shoulder). Decide at the zone-1 creature sign-off.
- Face winding is outward on every face (checked with `recalc_face_normals`, 0 flips); earlier builds had all cap triangles inverted, which would have shown as holes on single-sided MeshParts.
