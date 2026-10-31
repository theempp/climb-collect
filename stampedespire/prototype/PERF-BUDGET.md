# Stampede Spire: performance budget (M7, provisional)

**Status:** provisional. The owner deferred the real-phone test (2026-10-29) because it needs a private publish. These numbers come from the build stats and Studio/Device Simulator runs, not a phone. Re-check them on a real phone before release; the Definition-of-Done phone box stays open until then.

## What the place carries now (M6)
| Item | Value |
|---|---|
| Mountain MeshParts | 99 (61 zone `Automatic`, 38 backdrop `Performance`) |
| Mountain tris | 277,918 (Z1 107,638 · Z2 40,117 · Z3 53,757 · Z4 63,562 · backdrop 12,844) |
| Largest part | 9,000 tris, 1,829 studs |
| Herd | 100 creatures (5 lanes × `HerdPerLane` 5 × 4 zones), placeholder blocks |
| Studio, focused, Z4 | 59 fps, worst frame 18 ms (evidence/72) |
| Device Simulator iPhone XR (M4) | 60 fps, worst 22 ms (desktop GPU, so only a layout/logic check) |

## Budget
| Area | Budget | Why |
|---|---|---|
| Mountain | keep ≤ 300k tris, ≤ 10k per part; zone meshes `Automatic` fidelity, backdrop `Performance`, `SS_Mountain` streaming `Persistent` | already met; Roblox LODs `Automatic` parts by distance |
| Creature mesh (M8) | **≤ 3,000 tris** at full detail, one skinned MeshPart body (+ rider seat attachment) | 25 creatures in view × 3k ≈ 75k tris, a quarter of the mountain |
| Creature rig (M8) | **≤ 24 bones** (spine 4, neck/head 3, 4 legs × 3, tail 2, ears/horns ≤ 3) | gallop/idle/jump/faceplant clips stay cheap on phone |
| Creature texture | one shared creature palette atlas (like `ss_atlas.png`), no per-species textures | one texture upload, one material |
| Herd in workspace | 100 creatures; animate only creatures within 250 studs of the camera, others play no clip | keeps the Animator cost to the ~25 near the rider |
| Effects | aurora 138 beams, weather one emitter per kind (rates in `SS_Config.Fx.WeatherRate`) | unchanged from M6 |

## To verify on a real phone (when the owner allows a private publish)
- Sustained fps and memory per zone, 60 s each, with the M8 creatures in.
- If below 30 fps sustained: first drop `HerdPerLane` to 4, then the far zone-1 pines, then creature tris to 2k.
