# Daily Practice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow the selected method and common protocol in the parent plan.

**Goal:** Add a visible multi-stage practice circuit with optional timing and a daily earned cosmetic milestone.

**Architecture:** Reuse the existing traversalSection validation signal for ordered completions. Separate free daily challenge participation from existing purchased permanent training lessons and stamina upgrades. Persist daily eligibility and cosmetic ownership through the same Profile transaction system.

**Tech Stack:** Luau, Training/Traversal modules, world practice generator, server clock, Profile transactions, shared HUD/station presentation.

**Spec:** [Design sections 5, 10–12](../../../design/lobby-portfolio-summit-design-2026-10-22.md); [parent protocol](2026-10-22-expedition-redesign.md).

## Global Constraints

- A compact multi-stage climbing circuit with optional timed runs, visible from the court.
- A rotating daily challenge progressing toward an earned cosmetic milestone. No paid entry.
- Numerical cosmetic milestone thresholds remain provisional; use the draft seven nonconsecutive daily stamps for local review.
- Preserve existing purchased training and progression; replay cannot repeatedly award economic benefits.

## Review Focus

Paid-lesson gates blocking free entry, day rollover during a run, forged section events, duplicate milestone delivery, and course return movement are exercised explicitly.

## Files and interfaces

Create `src/core/shared/DailyPracticeRules.luau`, `src/core/server/DailyPractice.luau`, `src/core/server/DailyPracticeTests.luau`, and `tools/daily_practice_checks.luau`. Modify `src/world/TrainingYard.luau`, `src/core/server/{Training,Traversal,Profile}.luau`, the runtime server/client integrations, and sync manifest. Use the lobby PracticeStart anchor instead of the old 380–470-stud site search.

Rules: `dayKey(epoch:number) -> integer` is `math.floor(epoch/86400)`; `descriptor(day:integer) -> {id,sections:{string},resetAt:number}` rotates through three tested ordered circuits: sections 1–2; sections 1–3; sections 1–2–3–2–3. Each section start requires a grounded approach from its designated connector, never teleport to the next section. Add connectors needed for the repeat circuit without reordering existing paid lesson definitions. Display the route before entry.

Service: `DailyPractice.init(ctx)`, `.state(player,state)`, `.onLeave(player)`, `.canUseSection(player,sectionId) -> boolean`. Only an active daily participant inside the practice course gets this temporary permission; it grants no permanent lesson unlock or stamina bonus. Integrate permission as an additional guarded branch in existing training/traversal eligibility.

Requests: `practiceDailyStart{timed:boolean}`, `practiceDailyCancel{}`; no client completion action. State: `dailyPractice={day,challengeId,sections,resetAt,stamps,milestoneTarget,milestoneOwned,active,timed,elapsed?,status}`. Persist `data.dailyPractice={lastCreditedDay=-1,stamps=0,milestoneGranted=false,bestByChallenge={}}`; cap best records to the three known challenge IDs. Interrupted attempts restart without a stamp; completed but uncertain transactions recover normally.

### Task 1: Course geometry, free participation, and optional timer

- [ ] Write DailyPracticeTests assertions: fresh player with only lesson 1 unlocked can enter the daily circuit free; daily permission does not unlock lesson 2 permanently or award its training bonus; out-of-order or out-of-course section completions cannot advance; cancellation revokes permission. Run red.
- [ ] Relocate the course to the reviewed lobby edge, preserve `World.TrainingYard.StartGate` compatibility for existing lesson UI, and add a distinct daily start interaction. Keep all stage entries/landings grounded, clear, and spectatable from the court. Connect to actual authored section IDs and return walkway.
- [ ] Implement server-owned active attempt with expected section index and timestamp; consume only the validated traversalSection signal while the player remains within course bounds. Reset on death, leaving the course, cancellation, or another training-mode start. Optional timed mode displays elapsed server time, with no economic speed bonus.
- [ ] Run rules/permission checks green, complete every daily circuit using actual traversal, and exercise all existing purchased lessons. Verify legitimate connectors and repeat sections can be completed; reject client-only completion messages.
- [ ] Commit geometry/rules/permission integration and record course visibility and traversal evidence.

### Task 2: Durable daily stamp and cosmetic milestone

- [ ] Write failing cases: completing twice in one UTC day grants one stamp; nonconsecutive days retain stamps; seventh stamp grants one cosmetic; repeated/recovered seventh completion grants no duplicate; failing before commit preserves prior state; lost response after commit/rejoin grants once; day rollover invalidates an unfinished old-day attempt and offers the new challenge without a stamp. Inject clock/store adapters.
- [ ] Implement `DailyPracticeRules.credit(data,day,config) -> {ok,reason?,stamps,milestoneGranted}` as the pure transaction transform. Require day equality at completion; transaction ID is `dailypractice:<userId>:<day>`, and persisted lastCreditedDay/milestoneGranted guard correctness after generic receipt trimming.
- [ ] Add a deterministic cosmetic ID `practice_pennant` to earned cosmetic configuration, not the paid catalogue. Grant ownership atomically with the seventh stamp. Stops at the milestone; future daily circuits remain playable without inventing further prizes. Treat this seven-stamp target as provisional review configuration.
- [ ] Integrate client challenge card with reset countdown, progress, replay state, and pending/confirmed save wording. Show progress in owner Details; public showcase can show the earned cosmetic when equipped. No shop action gates participation.
- [ ] Run DailyPracticeTests green plus Profile/Training/Commerce suites. Execute real course completion, duplicate replay, and reconnect checks. Commit schema, service, tests, and UI integration.

### Task 3: Saved review and device acceptance

- [ ] Run `require(game.ServerScriptService.CC_CoreServer.DailyPracticeTests).run()` and `require(game.ServerStorage.CC_DevTools.DailyPracticeChecks).run()`; register the latter as `tools/daily_practice_checks.luau`. Expected: all assertions pass; record actual case count.
- [ ] Inspect start/replay/return on landscape phones at largest text and gamepad; ensure timers do not overlap traversal controls and cancellation restores normal input.
- [ ] Save/reopen Practice review and run preservation verifier plus relevant parent regressions. Record actual multi-client spectator behavior where available; do not claim it from fixtures.
- [ ] Commit only affected sources/tests/docs and record remaining numerical balancing as provisional.
