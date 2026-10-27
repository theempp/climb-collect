# Home-base promenade Review01 — delivery report (October 26, 2026)

Local review build of the approved plan `climb&collect/docs/superpowers/plans/2026-10-26-homebase-promenade-rebuild.md`. Stopped for the owner's review. No publish, push or merge.

## Open this file

`C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.HomePromenade.Review01.rbxl`
SHA256 `e7e5cb7c4a1dfa99b2211be454bf212033385bd2d8f17a85abcabc66420454a4` (1,154,074 bytes). Branch `codex/homebase-promenade`, based on `187ac03`. Review02 is unchanged.

Press Play. You spawn at home 1 on the promenade edge, facing the gate and the mountain.

## What changed

| | Review02 row | Review01 promenade |
|---|---|---|
| Layout | 8 plots in one 1,496-stud row, 3 gates | 4 homes each side of a 70-wide promenade, 1 grand gate at the mountain end |
| Plot | 180 × 220 | 140 × 180, front faces the promenade |
| Side length | 1,496 | 584 (4 × 140 + 3 × 8 buffers) |
| Farthest spawn → gate (straight line) | ~722 walked | 534 |
| Walk home → past gate, speed 16 | ~45 s farthest | 8 s (homes 1–2) to 36 s (homes 7–8) |
| Ground level | 0, with steps up to the 16 terrace | 16 throughout, level with the mountain entrance; steps/terrace removed |

- **Plots (Phase 2).** Slots alternate west/east from the gate, so the first players get the closest homes. Inside each plot: spawn and the Incubator/Training markers at the front, the tycoon grid behind them, the existing lodge at the rear. Tycoon progression and saves are unchanged (only its position changed).
- **Gate (Phase 4).** One gate: two 72-high towers, a 150-wide by 50-high opening, cedar entablature, crest, lanterns, and wing walls into the berms. It is the only exit. The center `SanctuaryExit` trigger now spans the whole basin on the gate line, so every return crosses it. The west/east side exits and approaches (22 parts) are removed. `nearGate`/Enter Blossom uses the gate.
- **Promenade (Phase 5).** Two 29-wide cobble lanes, plus a 12-wide center channel with water, a flat bed, coping and brass guide strips. The channel is shaped so a conveyor could be fitted later, but it has **no conveyor gameplay**. Lanterns line both lanes. Each plot has a dry-stone front wall with a cedar-and-brass entry frame. Planted dividers between homes reuse the old boundary hedges. A south garden has a pool, trees and beds.
- **Terrain (Phase 3).** Rolling planted berms enclose the basin and step down to the mountain's own toe behind the gate wings. They are written only inside the home-base box (z ≥ −208). The 4,352 original mountain-edge cells in that box are protected and unchanged.
- Every colour and material is copied from existing sanctuary, lodge or gateway parts, or from the Catalog's Azure water colour. No new palette.

Source: `mountain/shared/HomeLayout.luau` (all numbers), `mountain/world/HomePromenade.luau` (version-gated rebuild + berms), `Sanctuary.luau`/`TycoonWorld.luau` read the layout, `Main` applies it before the old frontage builder (which now skips promenade builds). Tools: `promenade_sync/bake/scene_check.luau`, `promenade_raid/walk.client.luau`, `promenade_manifest.py`, `promenade_session.py`.

## Verified (local Studio). Evidence: `evidence/homebase_promenade_2026-10-26/`

- **CLI:** 30 suites (29 existing + new `home_layout`, 105 checks for spacing, facing, overlaps, buffers, contents fit and gate distance) and 85/85 compiles pass. Baseline before changes: 29 suites, 83 compiles.
- **Saved file:** 85/85 runtime sources match the repo, no historical drift, no QA fixtures (`ClimbCollect.HomePromenade.Review01.integrity.json`).
- **Scene checks:** 403/403 promenade checks before save and after cold reopen. Covered: plots, poses, lodges, spawns facing the gate, plot surfaces, continuous lanes, a clear gate opening and the single exit. The compact-mountain scene check passed 1,857/1,859 lines. Its two misses are the expected counts: 5,384→5,362 parts and 996→978 colliders, from the removed side approaches and exits.
- **Terrain:** legacy, playable and landscape fingerprint domains are row-for-row identical to Review02, and the protected cells inside the box match Review02 exactly. After cold reopen, every domain equals the pre-save fingerprint.
- **Raid return through the new gate, 122/122:** home → promenade → gate → summit strike ×8 → reveal → pickup → six-section cargo descent → still carrying at the gate → returning through the gate secures exactly one creature (3→4) → all six hazards (`raid-return-through-gate.json`).
- **8-home walks, 121/121 legs at walking speed** (`walk-eight-homes.json`). Only home 1 is a natural spawn, because Play Solo has one player. The walker reached homes 2–8 by walking (no teleports) to each spawn through its front opening, then went home → past the gate → home.
- **Cold Play:** spawn at home 1, 25 sanctuary prompts, no errors or warnings.
- **Performance, focused window, all 8 home views:** median 16.5–16.7 ms (about 60 FPS), p95 ≤ 18.1 ms, 132–454 draw calls (`performance-eight-homes.json`). A first unfocused run (15 FPS throttle) was discarded. Triangle counts vary with Automatic quality, so they don't compare directly to Review02.
- **Screenshots:** `aerial.jpg`, `avenue-view.jpg`, `gate-frames-mountain.jpg`, plus `before-aerial-review02.jpg`.

## Deviations from the plan's provisional geometry

- The plan put one side at 592; it is actually 584, because 4 plots × 148 counts one buffer too many.
- The lanes are 29 wide, as approved, but the plan's note that they are "wider than the 32-wide escape rule" is wrong: 29 < 32. The combined walking width is 58, and the gate opening is 150.
- To get the ~520 home-to-gate distance, the avenue had to start right at the gate. So the whole home base now sits at y16 (level with the mountain entrance), and the old terrace, steps and ramps were removed. Measured: farthest spawn is 534 studs from the gate in a straight line, and 36 s to walk past it.
- Spawns moved to the plot front (local z −83) so homes open onto the promenade. The lodge stays at the rear.

## Still open

- Owner visual and hands-on review: plot size, promenade width, the gate's scale, and the berm look. Art is a procedural first pass.
- Natural spawns at homes 2–8 need a multi-client test; hosted 8-player, late join, DataStore and real devices are untested.
- Low graphics quality culling of the distant mountain (Review02 finding) has not been rechecked here.
- Conveyor gameplay is not built (only the channel bed, by design).

## Owner test checklist

1. Open Review01 and press Play. Do you spawn facing the gate with the mountain framed beyond it?
2. Walk the promenade. Does the 4 + 4 layout and garden channel feel right? Are the plots big enough?
3. Walk through the gate to the mountain and back. Is it clearly the one way in and out?
4. Strike an egg, carry the creature home through the gate, and confirm it secures.
