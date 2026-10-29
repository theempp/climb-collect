# Climb & Collect â€” project overview

Updated **October 24, 2026 (America/New_York)**. Public-release target: **the full Mountain Empire vision**, including advanced services, as confirmed by the owner in the organization chat. Private tests are intermediate milestones. This audit authorizes documentation and planning; it does not authorize implementation, merging, publishing, purchases or cleanup.

We have a playable six-kingdom mountain, a separate sanctuary environment, and a separate responsive HUD. **There is no verified combined release candidate yet.**

## Use these three documents

1. [Publishing checklist](design/publishing-checklist.md) â€” ordered work, dependencies, acceptance criteria and who does what.
2. [Project audit and workspace map](design/project-audit-2026-10-24.md) â€” current builds, branches, evidence, historical work and unresolved decisions.
3. This overview â€” the short starting point for each session. `CLAUDE.md`, `master.md` and the vault retain the detailed project history.

## What exists today

| Piece | Verified progress | Still needed |
|---|---|---|
| Sanctuary | Eight enlarged plots and owner-approved lodges; Step 3 landscaping saved and geometry/navigation checked | Owner review of Step 3; reopen check; plot ownership, spawning, habitats/building, facilities and mountain connection |
| Impossible Mountain | Six kingdoms, 36 regular species plus six Guardians, combat/Trials, eggs, progression, checkpoints and revised natural routes | Owner art acceptance, integrated HUD, complete acceptance on final geometry, balancing, human timing, multiplayer and device tests |
| HUD | Eight hubs / 23 tabs; real actions for existing services; responsive emulator checks; [draft PR #1](https://github.com/theempp/climb-collect/pull/1) | Integrate latest mountain/sanctuary, implement unavailable services and test on hardware |
| Persistence | Session locks, retries, mutation freeze and memory-store tests | Unified sanctuary/mountain data contract and hosted save/rejoin/failure tests |
| Social, competition and shop | Encounter participation, defense snapshots, practice battles, UI surfaces | Parties/finder/readiness, full offline raids and friend challenges, rankings/badges/titles, daily rewards, catalog/receipts/entitlements |

The current intended loop is **spawn in sanctuary â†’ prepare a three-creature team â†’ climb/discover/fight â†’ secure eggs â†’ return/incubate/hatch â†’ place/train/upgrade â†’ earn income â†’ unlock harder kingdoms**, with the approved social and competitive systems. The sanctuary portions of that loop are unfinished.

## Current build entry points

- **Latest mountain:** [Final56](C:/Users/HOME!/Desktop/climb-collect-mountain-continuation/evidence/mountain_2026-10-24/ImpossibleMountain.Natural.Final56.rbxlx). Code lives in `C:/Users/HOME!/Desktop/climb-collect-mountain-continuation`; important later work is uncommitted.
- **Sanctuary:** [Step 3 review](redesign/step3/MountainEmpire.Step3.Environment.Review.rbxl). This contains environment only, with zero scripts.
- **HUD:** recovered clean at `6019525` in `C:/Users/HOME!/.codex/worktrees/mountain-hud-recovered/climb&collect` (detached HEAD). [Recovery record](design/workspace-recovery-2026-10-24.md).
- **Older hall/sunny build:** `C:/Users/HOME!/Desktop/climb&collect-lobby`. Preserve as a separate historical design; do not merge its game loop wholesale into Mountain Empire.
- **Older published test:** Place `134979185642785`, universe `10772485116`. This is the Fairground private playtest recorded on October 22, not the Mountain Empire release. Its current dashboard configuration was not re-audited.

## Next milestone

**M1 â€” one recoverable, integrated local alpha.** Preservation and HUD recovery are complete: 4,952 files backed up, independent restore verified, clean HUD checkout recovered. Review the sanctuary and mountain visuals, settle the gateway/profile contract, then combine the three pieces in a new review place. Acceptance: a fresh player spawns on their assigned plot, reaches Blossom, earns and extracts an egg, returns to the correct plot, incubates/hatches, and sees the correct HUD state. Save/reopen must reproduce the exact result. Live persistence and the remaining full-launch services have later gates.

This is a milestone proposal for future work, not a claim it has been built. The [checklist](design/publishing-checklist.md) starts with the preservation and decision steps that make it safe to execute.

## Working rules

- Follow checklist IDs in order; complete an item only with a dated result and evidence path. Implementation, automated verification and owner acceptance are different states.
- Start each session with graph freshness, then inspect the actual relevant checkout. CURRENT covers the original checkout/vault, not the isolated continuation or HUD source.
- Preserve dirty files, review artifacts, failed experiments and all Studio sessions. No folders need moving or deleting for this plan.
- Keep the full launch scope intact. Optional later work means expansion beyond the approved vision, not quietly deferring its unfinished features.
- Initial human device testers: owner on **iPhone 16 Pro**; girlfriend on **iPhone 18 Pro Max** (owner-reported model; confirm exact hardware/OS at test time). Controller availability, tablet/Android coverage and the eight-player test roster remain open.

## Verification from this audit

Fresh source checks passed: **120 rules + 131 traversal + 657 route geometry**, all **80 mountain Luau files compile**, and Final56 matches **44 current saved sources** and its intended terrain payload. Sanctuary, Final56 and hall/sunny hashes match their reports. Prior Studio evidence was inspected, not rerun; none of these checks certifies a combined game or physical device performance.

Evidence: [audit inventory](evidence/release_audit_2026-10-24/inventory.json), [fresh checks](evidence/release_audit_2026-10-24/fresh-checks.json), [Studio inventory](evidence/release_audit_2026-10-24/studio-inventory.json). Graph final status is recorded separately in the audit evidence folder after documentation/vault refresh.
