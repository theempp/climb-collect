# Run 1 · A0 Safety — baseline (2026-10-20)

Folder mapping for Run 1: `core_P0` = A0, `core_P1` = A1, `core_P2` = B.

## Preflight (read-only)
- Studio MCP connected, open place `game.Name = ClimbAndCollect.rbxl`, `PlaceId = 0` (unpublished, real DataStore not testable), read-only `execute_luau` OK.
- 11 checkpoints existed; no `ServerStorage.CC_Creatures`; no `creatures/` folder; one server script (`CC_CheckpointService`); client scripts `CC_AscentClient`, `CC_TraverseClient` (V2, still enabled).

## Checkpoint + file copy
- `ServerStorage.CC_Checkpoints/A0_2026-10-20` (6,067 instances: whole-map TerrainRegion 1441×911×1441 cells, World, SpawnLocation, Lighting, CC_Generators, CC_Route, runtime script copies disabled). Tool: `tools/checkpoint.luau`.
- File copy `ClimbAndCollect.A0.rbxl` = the user's on-disk save from 14:47 (56.5 MB, valid `<roblox!` header).

## Incident (logged, recovered, no data loss)
While trying to bring Studio forward for Ctrl+S, a click on a taskbar icon started `RobloxStudioInstaller.exe`, which closed the running Studio (MCP disconnected, a §5 condition). Recovery: the new Studio offered Studio's own auto-recovery file (16:40:28, written after the A0 checkpoint). Verified via MCP that it held the A0 checkpoint and the unchanged World (6,027 instances), saved it over `ClimbAndCollect.rbxl` (62.3 MB, 16:45:10), closed it, reopened `ClimbAndCollect.rbxl` from disk and re-ran preflight: `game.Name = ClimbAndCollect.rbxl`, A0 checkpoint present, World 6,027. Backups kept: `ClimbAndCollect.A0.rbxl` (14:47 save) and the auto-recovery copy in the session scratchpad. Rule added to `CLAUDE.md`: never click Studio's taskbar icons.

## Baseline numbers (Studio desktop playtest, Play Solo, vsync-capped; not mobile, not a device)
| Where | Avg FPS | Worst frame | World instances streamed | Client InstanceCount |
|---|---|---|---|---|
| Spawn (Foothold amphitheater) | 60.0 | 17.9 ms | 2,581 | 51,544 |

Edit-mode World: 6,027 instances. Studio memory figure (14.9 GB) aggregates every datamodel in the process; not a device number.

## Doc edits (A0)
`master.md`: new §0.7 Core loop (LOCKED items from `design/core-loop-plan.md`); in-place superseded notes on §0.5 eggs → Heartstone, camps → tents, Hatchery → Heartstone Hatchery, §1 Claiming + net. No LOCKED text removed (verified by diff, see `A0_doc_diff_check.md`).
