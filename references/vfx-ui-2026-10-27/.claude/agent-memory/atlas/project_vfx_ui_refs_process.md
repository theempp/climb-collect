---
name: project-vfx-ui-refs-process
description: Where the 2026-10-27 VFX/UI reference sheets live, how to read them, and where Atlas intel files go in this project
metadata:
  type: project
---

Reference frames for the VFX/UI round live in `references/vfx-ui-2026-10-27/frames/v1..v6/sheet_NN.jpg` (4 cols x 2 rows, 360 px cells; fps v1 1, v2 1, v3 2, v4 1, v5 0.7, v6 2; README in frames/). Atlas intel files for this round go to `design/vfx-ui-intel-<letter>-2026-10-27.md` (A = v1-v3 done; C = settings screenshot, by another run).

**Why:** the invoking agent split the six videos across parallel Atlas runs and designated this output location instead of the default `design-intel/`.

**How to apply:** cite as `vN/sNN rR-cC (t=X s)` with t = cell index / fps. Intel C records an open palette conflict (approved HUD v2 blue/yellow candy vs violet/magenta/neon refs): keep it flagged as an owner decision, never resolve it silently.
