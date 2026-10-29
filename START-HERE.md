# Climb & Collect — start here

Updated 2026-10-28. The full workspace map is **`C:\Users\HOME!\Desktop\ClimbCollect\README.md`** — read it first (live repos, branches, what is archived, what not to touch).

## Where the work is
- **Current build/line:** `Desktop\climb-collect-integration` (branch `codex/hud-glassbloom`, repo family `climb-collect-mountain-quality`). Latest place: `outputs\ClimbCollect.Glassbloom.Review01.rbxl`.
- **This folder (`Desktop\climb&collect`)** is the legacy repo: project docs (`CLAUDE.md`, `master.md`, `design/`, `docs/`), graphify tools, older `src/`. Do not implement current game changes in this repo's `src/`; use the live worktree.
- Older placed `.rbxl` checkpoints and evidence zips are in `Desktop\ClimbCollect\archive\legacy-repo-binaries\`.

## Read order for a new session
1. `CLAUDE.md` and `master.md` here, then the active worktree's `CLAUDE.md` and latest `design/*handoff*.md`.
2. Obsidian vault: `Documents\Obsidian Vault\Home.md`, then `Climb & Collect\` (Milestones, Decisions, Open Questions).
3. `python tools/graphify_refresh/status.py` (refresh if STALE), then query the graph; verify claims in source.

The previous long start page is preserved in git history (commit `28e3ce4`).
