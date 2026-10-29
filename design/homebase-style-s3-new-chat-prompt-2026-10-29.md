Climb & Collect: home-base world style, S3 (Tier 1 Hut plot build)

Context
- Worktree C:\Users\HOME!\Desktop\ClimbCollect\game\homebase-c, branch codex/homebase-c. Read: design/homebase-style-decisions-2026-10-28.md (LOCKED + S0/S1/S2 answers), design/homebase-style-s1-plan-2026-10-29.md (§1 budgets, §3 modules, §4 S3 tests), design/homebase-world-style-intel.md (pass 3), design/homebase-handoff-2026-10-29.md, memory home base style/tiers.
- S2 kit (WorldStyle.luau, WorldKit.luau, HomeTiers rename, kit_sheet QA, chunk pass, 7 unions, 72 parts) is uncommitted: commit it first, then delete Workspace.KitSheet in Studio.
- Studio: copy outputs/ClimbCollect.HomeBase.Review01.rbxl (last save f07e5019…baf0, not saved since). Re-list studios and update tools/rmcp/x.sh with the new id. Never touch the Glassbloom integration window or the base copy.

Work (S3)
1. component-builder: rewrite TycoonWorld's 8-pad build into the Tier 1 Hut plot from WorldKit only: 6 habitat pens (fence tints S0.6, glass plaque + pill sign), 14 decor stands (empty = gold coin marker + price pill; bought = catalog prop), max 6 creatures shown on stands, lawn/patches, lilac pavers with pink inlay + thin flare path glow, kerbs, 4 globe lamps (every 3rd pink). Hut house in the 35x35 slot if ready, else keep the lodge. Enable TycoonWorld in world_style_lint.
2. Checks: 45+ suites, lint, plot_counts per item vs S1 §1 (plot <= 937), scene check, walk 8/8, 2-client owner/visitor, home_views perf (median <= 16.7 ms, draw calls <= 700), drift 0, console clean, StudioAids false, PlaceId 0.
3. STOP: captures of all 8 plots + yard close-ups at desktop 16:9 and phone (device emulator if possible), plus a count table. Wait for my approval before S4.

Rules: values only from the intel/decisions; ask via popup (max 4, recommendation first) if something can't be traced. No Robux, products, publishing, mount or lake. Don't save the copy without my OK; don't switch branches, stash or reset. Short messages; update vault + memory after the milestone (process only).
