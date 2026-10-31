# Creature style study: "Ride a Dino" + "Steal An Egg" (2026-10-29)
Owner decisions (2026-10-29):
- The two games are **style-only** refs (shape language, detail and poly density, shading/material). Species, colours and proportions stay traced to r2 (Z1/RR).
- Creatures follow the games' shading, as a creature-only exception to the faceted-world fidelity rule.
- Follow the **in-game block-built** look, not the smooth promo thumbnails.
- Eyes: dark eyes **sampled from Z1**, with a catchlight sampled from Z1 frost.

Sources: `concepts/style-refs/SOURCES.md`.

## Findings
| Aspect | Ride a Dino (in-game) | Steal An Egg (in-game) | Note |
|---|---|---|---|
| Construction | creatures assembled from many box and wedge parts (voxel/brick feel); mammoth = stacked blocks, tusks = stepped blocks | same block-assembly; pets are bevelled cubes; T-rex = boxy segments | thumbnails of both are smooth promo renders, not the game look |
| Silhouette | chunky, oversized blocky head and feet, thick legs, short necks | chunky; big square heads; stubby legs | readable at ride distance |
| Detail | detail comes from **part count** (spikes, plates, toes, teeth as small blocks), not from mesh smoothness | same; stripes as separate bands | |
| Shading | planar faces, smooth lighting (no faceted noise); hard 90° edges, small bevels | slightly bevelled edges catch a highlight | no outlines in-game (thumb outlines are promo-only) |
| Colour | flat colour per part; 2–3 tones per creature; darker feet/claws | bold alternating colour **bands** across segments | |
| Eyes/face | small square eyes, often glowing on rare tiers; block teeth | cartoon eye: iris + pupil, or glowing squares | |
| Accessories | saddles and reins as thin flat blocks/straps | crowns, leaves as blocks | |
| Animation | stiff part-rigid swing (blocks rotate whole), big bob, exaggerated stride | — | rigid per-part skinning is in-style |

## Build rules (for `art/tools/build_creatures.py`)
1. **Block assembly:** every body region is a bevelled box or wedge (torso as 3–5 box segments following the Z1 back line, head as box skull + box muzzle, legs as box upper/lower/foot). No ring-lofts.
2. **Rigid skinning:** each block is weighted 100% to one bone (joints are hidden by overlap), matching the games' part-rigid motion.
3. **Bevel:** a small chamfer on every box edge (≈4% of its smallest side) for the edge highlight; faces stay planar and the shading reads smooth.
4. **Chunk:** silhouettes stay on the Z1 measurements; chunkiness comes from boxes filling the measured envelope (no proportion exaggeration, per the owner).
5. **Detail by parts:** coat shag, mane, skirt and bristle as stacks of small offset blocks; antlers, horns and tusks as stepped block segments; hooves as a darker block with a toe split.
6. **Colour by part:** each block takes one token. The coat ramp (shadow/mid/light) goes by block height band, giving the games' banded read with r2 colours only.
7. **Eyes:** a small square eye block per side (Z1-sampled dark) with a smaller catchlight block (Z1 frost/antler-light token).
8. **Budget:** within M7 (`prototype/PERF-BUDGET.md`): ≤3k tris and ≤24 bones. Same bone names and the 4 clips.
