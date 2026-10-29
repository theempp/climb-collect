# Paired collection polish implementation plan

**Goal:** Enhance all 25 offspring and species eggs in a preserved, versioned local collection.
**Spec:** The October 26 owner request and continuation handoff authorize production across all five families; species identities and optional fox/hare status remain. Originals, game catalogs, runtime and published assets stay preserved.
**Architecture:** Copy existing Blender builders into an external Collection-v002 source folder, refine geometry and materials, build smooth species eggs with hatch components, derive atlas-mapped reduced runtime candidates and verify saved files independently.
**Tech stack:** Local Blender 5.2, Python, Pillow. No paid generation.

- [x] Intake: inspect collection/family renders, source and manifests; hash all original deliverables.
- [x] Offspring: refine body continuity, faces and species-specific anatomy/ornament; render front/threequarter views of every animal.
- [x] Eggs: seamless intact shell, integrated species motifs, deliberate jagged hatch split and local opening preview; render every egg.
- [x] Runtime preparation: single-material UV color atlas, triangulated lower-detail mesh candidates, FBX and GLB exports, separate conservative collision proxy and attachment metadata. Modeling units remain illustrative.
- [x] Review: inspect all paired family sheets and selected full-resolution renders; repair visible problems and rerender affected assets.
- [x] Verification: reopen saved sources, reimport runtime exports; check finite geometry, bounds, UVs, material/image embedding, triangle budgets, animation coverage where present, preservation hashes and archive CRC.
- [x] Delivery: five paired sheets, complete ZIP, evidence and honest readiness README; append project/vault milestone and refresh graph.

Review focus: accidental source overwrite; loss of species identity; eye/ornament floating; runtime colors unlike source; thin/degenerate geometry; unsupported claim of in-game readiness. Atlas UVs are palette sampling, not unique paintable unwraps. Creature deformation rigs/locomotion and Studio/device acceptance remain separate gates unless implemented and verified in this pass.

Execution: directly authorized local production, no repeated design interview. New external version provides isolation; no game branch changes needed. Technical defaults are author choices, not approved game balance. Source polygons can overlap as editable assemblies; collision proxies never substitute for gameplay acceptance.
