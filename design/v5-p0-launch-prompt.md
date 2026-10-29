Start v5 P0 (Safety) for CLIMB & COLLECT. User approved the v5 plan on 2026-10-21 (`design/v5-trails-and-mountain-plan.md`): build order 1 Trails, 2 Mountain look + fog, 3 Jackpot. The previous rebuild chat is finished. Run P0 only, then STOP and report.

Read first: `CLAUDE.md`, `master.md` (§0.6-0.9), the v5 plan (phases, acceptance checks), `design/v4-run2-log.md`, `evidence/v4_P3_report.md`. Obsidian: read `Home.md` and the Climb & Collect overview.

Preflight (do not skip):
1. `list_roblox_studios` must show `ClimbAndCollect.rbxl`; `get_studio_state` must be Edit mode. Never click a Roblox icon on the taskbar.
2. Studio session vs disk: the open session may hold unsaved work from the last handover (trim round, P4 code). Checksum Studio modules against `src/` (method in CLAUDE.md) and report any drift before changing anything. Do not overwrite unsaved Studio-only work.
3. `ServerStorage.CC_Checkpoints` holds 2 (`C_2026-10-20_Stage1_01`, `PreP3_2026-10-21`); the rule is max 2. Archive the older one to a verified `.rbxl` before taking a new one.
4. Another session ("Graphify vault merge", same folder) may be running; touch no vault/graphify files.

P0 tasks:
- Take checkpoint `PreV5_<date>` and a file copy `ClimbAndCollect.PreV5.rbxl` (save only with Studio visible: title-bar click, Ctrl+S, check mtime).
- Baseline streamed World instance counts at 6 spots (spawn, Shepherd s2500, Camp 1, Camp 2, Camp 3, a high spot) with the perf probe, desktop playtest, title bar clicked before each sample. This sets the +15 % instance budget.
- Confirm the rebuild state: place file mtime, run the standard rebuild order check, tutorial bot + B checks 12/12 + A1 12/12 still pass.
- Write `evidence/v5_P0/P0_report.md`; update `CLAUDE.md` ledger and the Obsidian milestone.

Rules: no world or terrain edits, no new generators in P0. Design values only from `references/`. Ask nothing that has a sensible default; document defaults as PROPOSED. If Studio is not connected, stop and say so.
