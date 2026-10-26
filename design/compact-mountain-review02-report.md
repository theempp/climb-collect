# Compact mountain Review02 — delivery report (October 26, 2026)

Local review build for the approved compact-mountain plan (`climb&collect/docs/superpowers/plans/2026-10-26-compact-mountain-rebuild.md`). Stopped for the owner's visual and hands-on review. No publish, push or merge.

## Open this file

`C:/Users/HOME!/Desktop/climb-collect-mountain-quality/outputs/ClimbCollect.CompactMountain.Review02.rbxl`
SHA256 `3c26ed681697e76349ad0095f52fa311a8b129798b2ba0f698e717cda4bbb9e9` (1,115,854 bytes). Branch `codex/compact-mountain-review`, based on `b97ddc0`. Work is uncommitted.

Press Play. A short loading screen ("Preparing the mountain…") clears once the scene and assets are ready, then you spawn at home.

`Review01` was saved before the egg-clearance fix and is kept only as a record. `Review06`, `Build01` and `Baseline` are unchanged.

## Before → after (provisional .85 scale; owner did not pick these numbers)

| Measure | Review06 | Review02 |
|---|---|---|
| Mountain width / depth (native terrain) | 2176 / 1632 | 1848 / 1388 |
| Occupied terrain cells | 11,278,814 | 6,930,560 |
| Route depth / rise | 1200 / 384 | 1020 / 326.4 |
| Scripted center climb (ordinary walking) | 80.4 s | 68.4 s (−15 %) |
| Sections | 6 | 6 |

Unchanged in size: avatars, guardians, nests, altars, checkpoint pads, hazards (32 × 22), the 32-wide escape lanes, homes and frontage, and the ±58 egg spacing. Instance streaming is off, so the whole mountain and its scenery stay loaded.

## Verified on Review02 (local Studio)

- 29 CLI suites and 83/83 compilations pass. All 83 runtime sources baked into the file match the repo, and no QA fixtures were saved.
- Cold reopen: voxels match the pre-save fingerprint exactly for the compact bake, sanctuary and legacy mountain. The clearance fix persisted.
- 1,867/1,867 scene checks: six sections, continuous ground, grades, hazard anchors and clearances, escape widths, egg clearance, 5,384 scenery parts and 996 colliders kept, home footprints unchanged.
- Cold start: ready in 2.09 s. Earlier Review01 tests also showed Retry recovering from an injected timeout and from an asset failure.
- **Summit raid retest, 120/120 checks:** strikes, reveal, pickup, guardian escape, six-section cargo descent and sanctuary securing all passed, plus all six hazards. This is the step that failed in Review01. Evidence: `evidence/compact_mountain_2026-10-26/raid-retest-passed.json`.
- **Walk/jump/sprint, 165/165 legs:** 12 real Space-key jumps, every section up and down, and the physical exit (`walk-jump-retest-passed.json`).
- **Death/respawn lifecycle passed.** The altitude atmosphere reset cleanly (`performance-visible-final.json`).
- **Performance from all 8 homes** (focused Studio window, desktop GPU): about 60 FPS, p95 ≤ 18.0 ms, 461–862 draw calls, 668k–722k triangles. This supersedes the earlier probes that lost focus or had the wrong camera.

## Measured conflict: low graphics quality

Seen from home 1, scenery depends on the graphics quality level:

| Quality level | Triangles drawn | Terrain triangles | What you see |
|---|---|---|---|
| 1–3 | ~17k–19k | 0 | No mountain visible |
| 5–10 | ~36k–65k | 6k–21k | Low-detail mountain silhouette, distant trees and rocks missing |
| 13+ | ~555k–604k | ~73k | Full mountain and scenery |

This is Roblox's own draw distance and level of detail at low quality. It is not a loading problem: everything stays loaded at every level, and the game has no supported way to override it. Phones running on automatic graphics often use low levels, so "the full mountain from every home" is only guaranteed at mid-to-high quality. It needs an owner decision and a check on real devices.

## Still open

- Owner visual and hands-on review: compactness, pacing, and whether .85 is the right scale.
- Physical phone and tablet testing. Phone layout was only seen in the emulator; tablet was not checked.
- Hosted multiplayer and late join, real DataStore saves, and the combined HUD/tycoon candidate.
- Studio memory (3.0–8.3 GB for the whole process) is not a device memory figure.

## Owner test checklist

1. Open Review02 and press Play. Is the loading screen brief, and is the full mountain visible from your home?
2. Walk to the mountain. Does it still look like the same mountain, only more compact?
3. Climb all six sections. Do they feel slightly shorter but still roomy?
4. Strike a summit egg, carry the creature down, and confirm the sanctuary exit secures it.
5. Try a low graphics setting (Esc › Settings › Graphics) and check how the home view looks to you.
