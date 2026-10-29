# Home-base style pass: phased build proposal (PLAN ONLY, not approved)

Inputs: `homebase-style-decisions-2026-10-28.md`, `homebase-world-style-intel.md` (atlas, open items F1-F17). Folds into P4 and later. Each phase ends in a STOP with captures and waits for owner approval. Pipeline per phase: architect, atlas, component-builder, motion, design-reviewer (only the relevant ones). No publishing, products or Robux; this branch's Studio copy only.

| Phase | Work | Agents | STOP shows |
|---|---|---|---|
| S0 | Owner answers to atlas conflicts F1-F9 (rank colour bands, gate height, house footprint, perf number, round plaza, fence colours, sign plaque, tier-2 name). Draft aura-multiplier numbers on paper (no code). | architect | Decision popup + numbers sheet |
| S1 | Plan structure: per-plot part budget table, `HomeTiers` role/name migration (`azureWater` etc.), module layout for a world-style token module, test list. Final atlas pass 3 with S0 answers. | architect, atlas | Written plan + final tokens |
| S2 | Kit: token module, prop prototypes in `ServerStorage` (globe lamp, pill sign, round-post fence, coin prop, flora set 10-14 types). Studio contact sheet. | component-builder | Prop sheet captures, part counts |
| S3 | P4 plot build, Tier 1 (Hut): 6-habitat yard, pens, decor stands, coin props, lawn/path. Replaces the TycoonWorld 8-pad build. | component-builder | Plot captures (desktop + phone aspect), counts vs budget |
| S4 | Houses Tier 2-4 (Cottage, Manor, Palace) + banner + aura ring (look only) + tier-up swirl recolour on the new colours. | component-builder, motion | Per-tier captures, swirl capture |
| S5 | Gate, commons landmarks (board, shrine, pool fountain, round plazas), walkway pavers + glow, lamps, signs, speed-lane strips, flora variety. | component-builder | Street and gate captures |
| S6 | Motion: gate bob/spin/sparkles/arrival burst, globe pulse, own-crest bob, near-player gating, Reduce effects/LOW paths; all through `Motion.luau` tokens. | motion | Caps check, motion off/on captures |
| S7 | Aura-ring coin multiplier: owner approves numbers first, then server-authoritative rules + tests (rank AND coins tier rule, secure XP unaffected unless approved). | architect, component-builder | Numbers table, test results, mutation check |
| S8 | Review: design-reviewer against tokens; 8-client phone emulator perf (median 60 FPS), overflow/state audits, drift check. Save copy only on your OK. | design-reviewer | Review report, perf numbers |
| S9 | Mountain dressing (camps, signs, lamps, route props) as its own atlas pass; terrain, routes, collision untouched; before/after captures. | atlas, component-builder, design-reviewer | Before/after captures, collision unchanged check |

S0 answers so far (owner, 2026-10-28): rank colour = 4 bands at levels 5/15/30; gate about 1.4x (about 100 studs); house footprint 12-13% (35x35 slot), tiers grow upward; per-plot budget 750 x 1.25 = about 937. Still open for S0: round plaza inside the square, fence pastel colours, sign plaque, tier-2 name, path-glow/speed-lane/door/roof colours (atlas F6-F8, F2).

Not in scope: mount/hoverboard (own feature; paths stay ride-wide), lake world, Robux/products.
Dependencies: S3 needs S2; S4-S5 need S3; S6 needs S4-S5; S7 can run after S1 in parallel but ships last; S9 after S8.
