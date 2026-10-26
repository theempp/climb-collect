# Compact mountain rebuild — approved plan and execution handoff

Approved by the owner on October 26, 2026. Execute in a new chat; stop when a separate review build is ready for the owner to test. No repeat design interview is needed.

## Goal and approved design

Make the Review06 mountain noticeably smaller and more compact while preserving its recognizable mountain design, six sections, scenery direction and route variety. The climb should be slightly shorter. From every home plot, players should see the complete mountain, including distant trees, rocks and route scenery, immediately after a brief initial loading screen. Materials should look consistent during approach and ascent. Support phones, tablets and computers equally.

Recommended and approved approach: rebuild the mountain at a compact scale while retaining comfortable avatar-sized paths, jumps and encounters. Uniform scaling risks shrinking gameplay clearances; loading-only fixes do not address the owner's size concern. Preserve the altitude atmosphere, recalibrating its altitude profile for the new mountain. Preserve home plots and existing gameplay contracts; do not infer permission to resize homes or replace game systems.

Exact dimensions, reduction percentages and loading duration were not selected. Measure the baseline and choose documented provisional values that meet the approved direction. Do not describe these implementation choices as owner-selected values. Full scenery residency has memory/rendering costs; investigate and report measured conflicts before compromising the requested view. A loading screen alone is insufficient. Engine graphics quality and device limitations must be distinguished from avoidable pop-in; no promise of identical rendering on every device.

## Authoritative starting point

- Implementation checkout: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality`.
- Last verified branch: `codex/mountain-quality-overnight`; commit `b97ddc0`. Checkout was clean during this handoff.
- Baseline: `outputs/ClimbCollect.MountainQuality.Review06.rbxl`.
- Expected SHA256: `bff89f92041687ddfc1cb815a728a1adeef9ca34939324b450cf9217917b09be`.
- Read `design/mountain-quality-review06-report.md`, `design/mountain-quality-integration.md`, and `evidence/mountain_quality_2026-10-26/review06-comparison.html` in that checkout.
- The original project `C:/Users/HOME!/Desktop/climb&collect` supplies navigation and records; its older `src` is not the Review06 implementation.
- Read applicable AGENTS instructions, CLAUDE.md, master.md and required vault notes. Use supported graph status/refresh/query workflow. The graph excludes isolated implementation source; inspect it directly.
- The owner may still have Review06 Play running. Leave that session and all unrelated Studio places untouched. Enumerate Studio before every target selection; use a separate review copy/session for this build. Historical Studio ID is not authority.

## Execution tasks

- [ ] **1. Establish baseline and safe working state.** Verify source revision, file hash and current changes; preserve existing work and immutable Review06. Use an isolated branch/checkout as appropriate. Measure mountain bounds, all home-plot sightlines, natural climb duration, startup readiness, visible pop-in, instance/geometry cost and client memory. Separate terrain LOD, instance streaming, asset loading and atmospheric visibility causes. Record comparable camera/device/settings conditions.
- [ ] **2. Rebuild compact geometry.** Inspect `mountain/world/FreeClimb.luau`, `MountainQuality.luau`, `MountainSurface.luau`, `NaturalRidges.luau`, `MountainEntrances.luau`, `mountain/shared/RaidConfig.luau` and the Review06 integration recipe before selecting exact edits. Reduce overall bulk and excess spacing without uniformly shrinking player clearances. Keep six sections and characteristic scenery; adapt routes, entrances, encounters, hazard bounds, checkpoints and altitude-dependent systems together. Record resulting dimensions and climb-duration comparison.
- [ ] **3. Make arrival complete and stable.** Audit actual place streaming settings and startup/asset paths before selecting residency policy. Add a brief readiness-driven loading screen, with honest progress and bounded failure/retry behavior rather than an arbitrary delay or infinite wait. Ensure required mountain geometry/scenery/assets are ready from every home plot and remain available during normal play. Optimize scene organization and rendering cost without silently substituting simplified distant scenery for the approved full-detail requirement.
- [ ] **4. Preserve appearance and gameplay.** Recalibrate `mountain/client/AltitudeAtmosphere.client.luau` and its shared profile as necessary. Keep consistent materials and smooth atmosphere. Validate physical clearances, walk/jump traversal, all sections, guardians/hazards, cargo recovery and sanctuary securing, death/respawn and multiplayer residency. Existing tests under `mountain/tests/` and Review06 QA runners are starting points, not proof for changed geometry. Add focused regressions for new geometry/loading contracts; do not blindly retain exact old transform assertions.
- [ ] **5. Verify saved delivery.** Save as a separately named compact-mountain review file, cold reopen, verify baked source and intended terrain, hash it, and rerun relevant gameplay/loading checks. Capture matched home-plot/approach/ascent/summit images and performance evidence under consistent settings. Test cold join, slow/failed asset readiness, respawn, late join and repeated traversal. Check phone/tablet layouts and low graphics; label simulation separately from physical hardware. Actual device acceptance remains open until tested.
- [ ] **6. Deliver and stop.** Produce a report with exact file path/hash, startup instructions, before/after size and timing, evidence, remaining limitations and owner testing checklist. Update project and backed-up vault records with concise evidence pointers; refresh and report graph drift. Stop for the owner's visual and hands-on review. Do not begin a further polish round.

## Review acceptance and boundaries

The owner should immediately recognize a more compact version of the mountain they liked. All six sections remain playable; the climb is only slightly shorter. The full mountain and scenery are visible from home base after loading, with no obvious staged mountain reveal during ascent. Materials remain visually coherent. Device performance and loading claims require measurements; unresolved hardware tests are explicitly open.

This is local rebuild authorization only. No publish, push, merge, production-data work, unrelated Studio changes, new creature-art replacement or later polishing pass. Preserve protected creatures, home assets, ownership/persistence contracts and other chats' work. If another chat has advanced the baseline, reconcile before editing rather than overwriting it.

## Evidence at handoff

October 26, 2026: supported graph status was CURRENT with zero intended-input drift before saving this plan; isolated implementation checkout was clean. Review06 report documents fresh local gameplay tests, but physical devices, fresh multiplayer and owner aesthetic acceptance remain open. Those historical checks do not prove this rebuild.
