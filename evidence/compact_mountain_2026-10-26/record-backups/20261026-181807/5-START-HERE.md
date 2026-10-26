# Climb & Collect — start here

Updated October 25, 2026 (America/New_York).

**Latest:** owner approved the complete free-climb mountain design and requested the actual build in a new chat, with planning only here. [Build handoff](design/free-climb-build-handoff-2026-10-25.md) → [seven-task implementation plan](docs/superpowers/plans/2026-10-25-free-climb-mountain.md). This supersedes pending-draft-review snapshots below. No game/place changes in this planning continuation.

**An integrated local game exists.** Last night's HUD and tycoon improvements are in two separate review branches. They still need combining into one phone candidate. The old statement that integration has never happened is superseded.

## Review, test, and find the work

**Active design continuation:** [finish the sectioned free-climb mountain](design/free-climb-mountain-handoff-2026-10-25.md). Open face with distinct sections, progressively tougher guardian fights/pursuits, some hazards, first-strike guardian approach, free climbing into all sections from the start and permanent safety at the sanctuary exit. Owner wants Steal an Egg + Break and Steal an Egg as close concept references, with thoughtful improvements, and requested a new chat to finish the review. No rebuild yet.

1. [Current workspace review and owner test checklist](design/workspace-review-2026-10-25.md) — what changed, exact builds/source locations, remaining work, mountain review and reference questions.
2. [HUD review — exact recovery copy](C:/Users/HOME!/Documents/ClimbCollect-HUD-Recovery-2026-10-25/ClimbCollect.HUD.Complete.Review02.rbxlx) — newest HUD on the integrated mountain/sanctuary/tycoon baseline.
3. [Tycoon Review06](C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/outputs/ClimbCollect.Tycoon.Review06.rbxlx) — latest tycoon labels and local multiplayer evidence; currently connected Studio at audit time.
4. [Full public-launch checklist](design/publishing-checklist.md) — retained full scope; apply the October 25 status overlay below before treating older unchecked items as unbuilt.
5. [Fresh artifact/source audit](evidence/workspace_review_2026-10-25/artifact-audit.json) — exact hashes and branch differences; disk checks, not a fresh playtest.

## Current source map

| Location | Role |
|---|---|
| This Desktop repo | Navigation, project history, older source and graph tools. Preserve its dirty/untracked work. |
| `Documents/ClimbCollect-HUD-2026-10-25` | Durable HUD implementation, branch `codex/hud-completion`. |
| `Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/work/climb-collect` | Durable tycoon implementation, branch `codex/tycoon-redesign`. |
| `Desktop/climb-collect-mountain-continuation` | Final56 mountain source, geometry and natural traversal evidence. |
| `Documents/ClimbCollect-GuardianProduction/2026-10-25` | Guardian studies and Veylith Blender work in progress. |
| `Desktop/climb&collect-lobby` | Separate historical hall/sunny design. |

Do not implement current Mountain Empire changes into this repo's older `src/` merely because it is the chat's working directory. Read the selected feature clone and its instructions first. Both feature clones were clean at audit time.

## Current acceptance

Latest owner design choices: mountain egg breaking/reveal → creature carried home; sculpted-fantasy creature art; two-arm cradle for small creatures. [Decision review and visual boards](design/egg-creature-review-2026-10-25.md). Discussion only; implementation and detailed custody/failure rules are pending.

Implemented and previously tested: one-place sanctuary/mountain integration, core egg/incubate/hatch/equip loop, habitats/production/banking/upgrades/automation and responsive HUD. Actual eight-client tycoon and late-join tests are recorded; physical device acceptance is not.

Still open: combined latest candidate, owner art/route review, polished egg/carry/hatch and creature animations, guardian production assets, human timing/economy, authorized private hosted candidate and save/rejoin testing, real phones/performance, plus remaining full-launch services. Exact scope and evidence: current review above.

**Artifact caution:** the HUD clone's ordinary Review02 output no longer matches its report hash. Its runtime source still matches; use the exact recovery copy linked above for the previously verified artifact. Preserve both pending reconciliation.

## Working rules

Read `CLAUDE.md`, `master.md`, relevant vault notes and the current review. Start with `python tools/graphify_refresh/status.py`; refresh if STALE. CURRENT covers intended inputs in this original repo/vault and does not cover isolated feature source. Use graph discovery, then verify current files.

No historical places, dirty files, backups or Studio sessions were deleted or moved in this organization pass. Prior start page preserved at `evidence/workspace_review_2026-10-25/note-backups/START-HERE.2026-10-24.md`.
