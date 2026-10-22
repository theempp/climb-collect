# Expedition Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for the saved native-execution continuation. Steps use checkbox (`- [ ]`) syntax for tracking. Owner design and plan review are complete; the continuation prompt specifies native implementation and a final independent review. Read the resume handoff before execution.

**Goal:** Deliver the approved compact expedition fairground, player identity/HUD, daily practice, and individual summit finale in staged local review builds.

**Architecture:** Four linked implementation plans isolate world replacement, player presentation, practice rewards, and durable expedition completion. Preserve the existing Profile transaction owner, banking rules, traversal controller, Commerce service, and personal-home system. New modules use the existing `init(ctx)`, `state(player, snapshot)`, lifecycle hooks, and `ctx.handlers` pattern rather than introduce a second network framework.

**Tech Stack:** Roblox Studio, Luau, existing Studio MCP/sync tools, local Python saved-place verification, existing Luau CLI test tools. No Rojo or new product dependencies.

**Spec:** [Approved design](../../../design/lobby-portfolio-summit-design-2026-10-22.md).

## Global Constraints

- Main services approximately 5–8 seconds' walking distance from spawn; direct physical mountain connection; mountain and climb entrance visible immediately.
- Landscape phones lead the design, followed by desktop and gamepad.
- Work in a separate local review place, replacing the central Foothold while preserving mountain routes, personal-home systems, and protected creature assets.
- Publication, product listings, live purchases, and spending are outside this work.
- One Shop HUD entry plus at most one contextual offer is visible; paid promotion is reduced during climbing.
- Extraction preserves cargo; it does not bank creatures or Heartstones, advance occupied home nests, or grant permanent collection credit.
- Reward amounts, title thresholds, and cosmetic milestone thresholds are review configuration, not finalized economy decisions.

## Review Focus

1. Hard-coded old world paths silently disabling bank/shop/home prompts: lobby Tasks 1–2 audit and replace them.
2. Pending cargo or home return being overridden by a generic spawn: lobby Task 2 and finale Task 3 test movement precedence.
3. Retired/unreleased species and mutations corrupting completion: portfolio Task 1 tests denominator and mappings.
4. Daily rewards and summit grants replaying after uncertain saves: practice Task 2 and finale Task 2 test lost-response recovery.
5. Local cinematics trapping input or affecting another player: finale Task 3 tests skip, timeout, respawn, and simultaneous finishers.

## Order and independent deliverables

| Order | Plan | Playable checkpoint | Dependencies |
| --- | --- | --- | --- |
| 1 | [Lobby](2026-10-22-fairground-lobby.md) | New court with functioning bank, Exchange, home entrance, route access, and practice site | Existing Commerce review baseline |
| 2 | [Portfolio and HUD](2026-10-22-portfolio-hud.md) | Public/private profiles, tags, earned titles, cohesive bright HUD | Lobby anchor and safe-zone contracts |
| 3 | [Daily practice](2026-10-22-daily-practice.md) | Validated multi-stage circuit, optional timing, daily earned cosmetic | Lobby site and portfolio milestone display |
| 4 | [Summit finale](2026-10-22-summit-finale.md) | Validated finish, recoverable rewards, helicopter scene, results, lobby return | Lobby return anchor and HUD presentation contracts |

Practice geometry may be authored during lobby work, but daily progression and grants stay in the practice plan. Summit tracking is not retroactively fabricated; portfolio can show preserved historical counts before the new finale is connected.

## Common development and evidence protocol

- [ ] At execution start read `CLAUDE.md`, `master.md`, the approved design, relevant handoffs, and applicable skills. Inspect attached worktrees and actual Studio instances. Preserve the dirty working tree; no reset/clean or broad staging.
- [ ] Isolate execution using the worktree skill while preserving all relevant uncommitted/untracked baseline sources; a plain checkout of HEAD omits much of this project. If copying a baseline is needed, inventory and hash it before editing. Do not treat the historical instance IDs as current.
- [ ] Start from `ClimbAndCollect.FootholdExchange.Review.rbxl`, reconcile embedded/live/local sources in Edit mode, and create `ClimbAndCollect.BeforeFairground.rbxl` plus a source/terrain/protected-assets manifest. Use `ClimbAndCollect.Fairground.Review.rbxl` for the new build.
- [ ] Register new modules in `tools/sync_core.luau`; new shared modules go to `ReplicatedStorage.CC_Core`, client modules to its `Client` folder, server modules to `ServerScriptService.CC_CoreServer`, generators to `ServerStorage.CC_Generators`, and Studio harnesses to `ServerStorage.CC_DevTools`.
- [ ] For each behavior task, write the specified failing regression, run it red, implement, rerun green, then run affected existing suites. Art/layout tasks use visual and interaction evidence rather than tests mirroring geometry implementation.
- [ ] For each saved phase create evidence under `evidence/fairground_2026-10-22/phase-N/`, including screenshots, test output, source checksums, preservation report, and known limitations. Create `tools/verify_fairground.py BASELINE REVIEW` using existing saved-place readers; require all registered sources to match, protected assets unchanged, no unintended route/checkpoint edits, and exact Terrain properties unchanged. If Studio reserializes terrain, use the existing restoration technique only against the checked baseline and reverify.
- [ ] Sync only changed, reviewed files in Edit mode; verify checksums; always restore HTTP off. Never run a whole-world generator to update the lobby. Save and reopen each milestone before accepting it.
- [ ] After each task commit only its named sources/tests/docs, checking staged diff first. Save the binary checkpoint and record its hash without broadly staging pre-existing binary work. Update `CLAUDE.md`, `master.md`, and the evidence ledger at each material phase.

## Existing verification commands

Planning-source finding: saved summit counters and configured reward values exist, but local source search did not identify an ordinary summit award/increment path. The finale plan audits the actual live/saved build before deciding whether to replace or introduce that path. Storage fields alone do not prove functioning summit completion.

Run the affected subset, then the full baseline once at final integration:

```powershell
python tools/verify_commerce.py ClimbAndCollect.FootholdExchange.Review.rbxl
python tools/training_regression.py
python tools/cargo_visibility_regression.py
tools/.luau/luau.exe tools/traversal_rules_cli.luau
tools/.luau/luau.exe tools/traversal_access_cli.luau
```

The first command verifies the old baseline; the new review file uses the new fairground verifier because world paths intentionally change. In disposable Studio Server Play, run `require(game.ServerScriptService.CC_CoreServer.Tests).runA1()`, `ExpeditionTests.run()`, `TraversalTests.run()`, and `require(game.ServerStorage.CC_DevTools.CommerceChecks).run()` through their actual modules. Expected: all cases pass, zero new runtime console errors, HTTP off after sync. Record actual counts; historical counts are not future results.

## Rollback and acceptance

- [ ] Phase snapshots: `Fairground.Lobby.Review.rbxl`, `Fairground.Profile.Review.rbxl`, `Fairground.Practice.Review.rbxl`, and `Fairground.Finale.Review.rbxl`, each with matching source checkpoint hashes.
- [ ] Roll back by reopening the last accepted snapshot with its matching sources; do not re-run destructive generators over a mixed-version scene.
- [ ] Owner reviews lobby views and measured paths before accepting final lobby art. Later phases preserve that accepted composition unless a demonstrated interaction problem requires revision.
- [ ] Final human checks cover real devices/controllers, actual two-client inspection/extraction, full ascent feel, and cinematic pacing. Scripted checks and phone emulation are labeled as such.
- [ ] Real persistence, platform pricing, and paid purchase flows remain release checks requiring an authorized published destination; never publish as a workaround.

## Review status

Execution record, 2026-10-22: all four phases are implemented in the saved and reopened `Fairground.Finale.Review.rbxl`; final integration commit `ffb15a2`. Read [the implementation handoff](../../../design/fairground-implementation-handoff-2026-10-22.md) for checkpoint hashes, independent review and actual evidence. The 101-source saved-place check and terrain/protected-asset preservation pass. Acceptance is not fully closed: the genuine ascent stopped at a preserved Shepherd terrain overhang; actual multiplayer, physical-device/controller and networked DataStore checks remain outstanding. Historical checklist items above are the protocol, not a blanket assertion that every acceptance test passed.

Design direction and implementation plan approved by the owner in this chat. The owner requested a new-chat continuation prompt to continue and finish execution; that prompt specifies native implementation with a final independent review. Numerical balancing stays provisional in local review, with no live economy rollout. Start from [the resume handoff](../../../design/fairground-resume-handoff-2026-10-22.md), which records final approvals, project-local media references, and the exact resume point.
