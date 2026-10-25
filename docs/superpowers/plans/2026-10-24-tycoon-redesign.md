# Tycoon Redesign Implementation Plan

> Execution: superpowers:executing-plans, with test-driven development and a final independent review.

**Goal:** Implement user Q1–Q11 within the preserved eight-plot/six-kingdom integration.
**Architecture:** Pure Tycoon rules and config, versioned profile subrecord, existing correlated requests, owned-plot rendering and existing hub.
**Tech Stack:** Luau, Roblox, existing Rojo and Luau CLI.
**Spec:** design/tycoon-redesign.md

## Global constraints

110x120 internal grid; 2 to 8 habitats; one producing creature each; independent combat team; no resets/streaks; existing coins/store; preserve stored eggs; server authority; no invented assets.

## Review focus

Clock rollback and repeated catchup must not duplicate eggs. Full storage must not grow hidden backlog. Failed/uncertain save and session takeover must not overwrite another session. Rapid assign/upgrade cannot retroactively boost production. Mobile controls and visual pools must remain bounded as roster/plots grow.

### Task 1: Production and economy
- [x] Add failing mountain/tests/tycoon.luau against new shared Tycoon module.
- [x] Implement TycoonConfig and Tycoon: ensure, valid, settle, collect, bank, assign, upgrade, snapshot, cosmetic.
- [x] Test caps, conservation, matching/synergy, migrations, purchases, automation, malicious values and partition invariance. Expected: CLI passes.

### Task 2: Persistence and requests
- [x] Add profile and protocol/action regression tests first.
- [x] Integrate Profiles validation/migration/catchup and lease-safe save; route actions via UIRequests with owned-plot eligibility.
- [x] Main settles on server interval and publishes snapshots; old CollectIncome delegates to manual banking.
- [x] Expected: all original and added tests pass, no hatch/combat changes.

### Task 3: World and hub
- [x] Build additive TycoonWorld inside plot-local 110x120 with central spine and eight grid anchors; reuse creature art and palette.
- [x] Add pooled client conveyors and hub tabs for habitats, upgrades, automation and cosmetics.
- [x] Package a separate review by replacing script sources only in Review06. Verify exact Workspace/terrain preservation.
- [x] Compile all Luau, build source package, exercise Studio if safely available; record blockers honestly.

### Task 4: Review and handoff
- [x] Independent code review; fix consequential findings and run regression suite.
- [x] Update CLAUDE/master, report assumptions/changed files/test evidence, commit feature branch and provide review outputs.

## Execution ledger

Baseline 089c6a3 preserves local reviewed integration before changes. Task 1: pure rule regressions failed before implementation, then passed. Task 2: wire/migration/client regressions failed before implementation, then passed. Task 3: additive runtime world/hub and protected-world package verified; real-client normal production/bank loop completed. Task 4: independent review completed; adjacency and atomic-swap findings fixed with regression tests; full suite compiled and passed.

Rulings: preserve newer local Review06 dependencies rather than build from old main; retain 180x220 outer plots with internal110x120 grid; production assignment independent of combat membership; use documented provisional numeric balance; offline automation does not drain storage. Costs if wrong: integration/balance adjustment, no destructive world replacement. Public release, full eight-client, hosted save and premium art gates remain open as explicitly documented.

## Continuation — October 25, 2026
- Complete: deterministic economy/8-profile stress baseline, explicit upgrade benefits, bounded habitat/machine dressing and occupancy reset, isolated visual/persistence fixtures, fresh phone emulator and saved Review04 verification.
- Ruling: retain numeric balance pending human pacing; first20 coins9.1min with both starters/continuous banking. No live-data tests or publication.
- Evidence: design/tycoon-polish-2026-10-25.md and evidence/tycoon_2026-10-25/. Independent reviewer found no important regressions; suggested fixture setup assertions and clear/replacement coverage completed.
- Final:1,310 CLI checks/89 compiles;50 existing+80 tycoon memory checks;213 visual fixtures; six phone tabs checked. Graph refreshed CURRENT with explicit isolated-source exclusion. Eight actual clients/hosted saves/physical devices/premium visual acceptance remain open.
