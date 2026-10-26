# Compact mountain execution — October 26, 2026

Approved plan: original navigation checkout `docs/superpowers/plans/2026-10-26-compact-mountain-rebuild.md`. Work stays in this isolated implementation clone, on `codex/compact-mountain-review`, based on clean `b97ddc0`. Review06 hash verified `bff89f92041687ddfc1cb815a728a1adeef9ca34939324b450cf9217917b09be`.

## Baseline evidence

Fresh 27 CLI suites and 79 compilations passed (`evidence/mountain_quality_2026-10-26/compact-baseline-regression.json`). Separate baseline copy, ordinary Humanoid movement: center ascent 80.431 seconds, six sections, all 30 approach/ascent targets passed (`evidence/compact_mountain_2026-10-26/baseline-walk.json`). This is a scripted natural movement timing, not human first-play timing. At home, 3648 mountain parts resident versus 5384 authored parts; Studio client memory 2829.69 MB. Runtime summit count 5488 includes added runtime objects, so it is not a static before/after geometry comparison.

## Implementation decisions and corrections

- Ruling: use provisional ground/landscape scale .85 about entrance (4096,16,-210), retaining full-size actors, nests, checkpoint pads, altars and animated hazards; restore center lane width to 32. Homes, frontage and sanctuary exits remain unchanged. Route changes from 1200 depth / 384 rise to 1020 / 326.4. Cost if wrong: owner may prefer a different compactness/pacing; hands-on acceptance is open.
- Ruling: disable instance streaming in this local review to make the actual native terrain and complete scenery resident. No proxy landscape or visual replacements. Cost if wrong: whole-place residency may exceed low-end device budgets; report measured Studio memory and leave real-device acceptance open.
- Corrected assumption: Review05/06 recipe bounds x3392..4800 describe that art pass, not the entire mountain. An initial diagnostic pass exposed unscaled outer terrain. Preserved as Build01, not a delivery candidate. Corrected terrain pass starts from another exact Review06 copy and covers x2800..5400, y-256..1024, z-2048..-208, excluding sanctuary and original mountain near origin. Full-residency baseline itself shows a separate original mountain near origin; it is protected historical terrain, not newly generated scenery.
- Studio instance limit prevented additional windows; only this chat's failed launches were terminated. The first saved diagnostic session was closed. Owner Review06 and unrelated sessions remain untouched.

## Verified progress and open failure

Corrected native bake: 11,278,814 → 6,930,560 occupied cells, width 2176 → 1848, depth 1632 → 1388. Ordinary center ascent 80.431 → 68.380 seconds. Initial saved compact Review01 cold reopened with 83 runtime sources matching, 89 total sources, no QA fixtures, 1855 scene checks passing, and exact pre-save/cold terrain equality. Sanctuary and legacy native terrain remain exact; sanctuary assets and lighting remain exact. The broader historical `protected` snapshot includes intentionally changed mountain anchors and landscape, so its whole-object equality assertion does not apply to this rebuild.

Cold startup readiness: 2.213 seconds in local Studio. Injected missing dependency timed out with Retry; supplying it and clicking Retry recovered. Injected missing asset produced an asset failure; removing it and clicking Retry recovered. Phone emulator layout inspected. Physical devices remain untested.

Fresh raid reached the summit, completed eight strikes, revealed/picked up the creature and verified 24.3 cargo sprint speed, then failed during guardian escape. Evidence: `evidence/compact_mountain_2026-10-26/raid-first-failure.json`. The reduced egg lateral spacing shortened the guardian approach. Added a failing ±58 clearance regression, restored original egg lateral spacing in source and QA paths; 29 CLI suites and 83 runtime compilations now pass. This correction still needs Studio application and live retesting. The currently saved initial compact Review01 predates it and is NOT ready for owner acceptance.

Performance evidence audit: initial external-camera probe exists; later standalone probe recorded wrong actual positions because Studio resets camera type after tool calls. The probe now binds after the camera and records camera error. A hidden-window run returned implausibly small render counts, so it is not valid home-view performance evidence. Repeat with a visible review window; do not promote `performance-final.json` (wrong camera) as final.

Studio instance limit blocked reopening an interactive review after the cold check; another chat acquired the freed slot. Only this chat's verified processes were closed. Asked owner to close one unused Studio while preserving Review06 Play; other chats' Studio processes remain untouched.

## Outstanding (superseded October 26 evening — see Review02 report)

Apply clearance correction in Studio; repeat raid/cargo/hazards, walk/jumps, lifecycle, tablet/low-quality layout and visible-window performance; save/cold verify corrected delivery; finish report, independent review follow-up and backed-up navigation/vault updates. Physical hardware and hosted multiplayer remain unavailable locally and must not be represented as verified.

## Review02 delivered — October 26, 2026 (Claude continuation)

Clearance-corrected session verified (83/83 Studio sources = repo), then saved as `outputs/ClimbCollect.CompactMountain.Review02.rbxl` (SHA256 `3c26ed68…bbb9e9`). Raid/cargo/hazard retest 120/120, walk/jump/sprint 165/165 with 12 real Space jumps, lifecycle pass, focused 8-home performance ~60 FPS. Cold reopen: exact voxel fingerprint, 1,867 scene checks, 2.09 s arrival. Low graphics levels (1–10) cull most distant mountain/scenery from home; engine LOD, reported as an owner decision. Report: `design/compact-mountain-review02-report.md`.
