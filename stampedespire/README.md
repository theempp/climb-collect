# Stampede Spire: repo snapshot (2026-10-30)

Full copy of `C:\Users\HOME!\Documents\StampedeSpire\` as of 2026-10-30. The Documents folder is the working location; this folder is the versioned copy. If they differ, the newer file wins; re-sync with robocopy before committing.

**Read first:** `MASTER-PLAN.md` (locked 2026-10-30; it wins over any other note). Then `prototype/MORNING-REPORT.md`, `prototype/FINISH-PLAN.md`, `art/LOOKDEV.md`.

## Layout
| Path | What |
|---|---|
| `MASTER-PLAN.md` | Merge plan: Spire + Climb & Collect home base, phases, decisions M1-M4 |
| `prototype/src/` | Spire Luau scripts (`SS_*`), byte-identical to Studio |
| `prototype/*.md`, `sim/`, `evidence/`, `snapshots/` | Plans, perf budget, herd sim, test log, evidence, script snapshots |
| `art/LOOKDEV.md` | Per-zone palette/lighting sheet; the only source of visual values |
| `art/tools/`, `art/blender/` | Python/Blender build scripts and `.blend` files (`.blend1` are Blender autosave backups) |
| `art/export/` | FBX exports, atlas, manifests (`ss_manifest.json`) |
| `art/creatures/` | Creature species brief, style study, renders |
| `concepts/` | Concept art (2026-10-29, r3 biomes) and `style-refs/` |
| `*.rbxl` | Studio place checkpoints; `StampedeSpire.Greybox.rbxl` is current, `pre-*` are backups, `Sections.rbxl` is the sections place |

## Merge target
Merged game goes in the local worktree `Desktop\ClimbCollect\game\spire-merge` (branch `codex/spire-merge`, cut from `codex/homebase-c`). That line is local only (not on GitHub). See `Desktop\ClimbCollect\README.md` for the workspace map.

## Rules carried over
Never overwrite an existing review file (add `ReviewNN`). Never publish or spend Robux without a fresh OK. Every visual value traces to `references/` or `art/LOOKDEV.md`. `src/` must match Studio byte for byte.

Note: the importer uploaded mesh/texture assets to the owner's Roblox account (see MORNING-REPORT decision 1).
