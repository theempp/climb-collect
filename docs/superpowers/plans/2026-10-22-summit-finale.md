# Summit Finale Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow the selected method and common protocol in the parent plan.

**Goal:** Finish each validated personal expedition with durable prizes, an exciting skippable helicopter cinematic, a winner's banner, and safe lobby return.

**Architecture:** Server-owned run evidence authorizes one Profile completion transaction. An immutable result drives the local cinematic and results UI independently of grant delivery. Durable monotonic completion markers survive receipt trimming; cargo remains unbanked and unchanged through extraction.

**Tech Stack:** Luau, existing CheckpointAPI and traversal events, Profile transactions, Roblox camera/animation/audio/streaming, shared menu and HUD controls.

**Spec:** [Design sections 9–12](../../../design/lobby-portfolio-summit-design-2026-10-22.md); [parent protocol](2026-10-22-expedition-redesign.md).

## Global Constraints

- Completion is individual. Other players continue their expeditions.
- A server-validated ascent reaching a safe true-peak arrival zone automatically starts the finale, only after grounded arrival and a safe release from climbing.
- Skip is always reachable by touch, keyboard, and gamepad.
- Extraction preserves cargo; it does not bank creatures or Heartstones, advance occupied home nests, or grant permanent collection credit.
- Starting another rewarded attempt requires a confirmed lobby return and fresh route validation. No additional daily summit reward cap was selected.
- Numerical reward balancing remains provisional and cannot silently become a finalized live economy.

## Review Focus

Teleporting between milestones, conflicting camp/home resume, lost-response replay after receipt trimming, cargo becoming permanent prematurely, and interrupted or simultaneous cinematics are pinned to tasks below.

## Files and contracts

Create shared `src/core/shared/{ExpeditionRunRules,SummitConfig}.luau`; server `src/core/server/{ExpeditionRun,SummitFinish,SummitTests}.luau`; client `src/core/client/{SummitCinematic,ResultsUI}.luau`; generator `src/world/SummitStage.luau`; harnesses `tools/{summit_checks,summit_finish_cli}.luau`. Modify Profile, Camps, Claims, Inventory, Bank, Traversal, CoreService, CoreClient, CheckpointService, sync manifest, and only the relevant reward configuration. Avoid broad refactors.

Persist under `data.expedition.summit`:

`{nextSeq:integer, completedThrough:integer, returnedThrough:integer, active:RunRecord?, pendingResult:ResultRecord?, acknowledgedSeq:integer}`. Use contiguous per-account sequences; explicitly retire abandoned sequences in a bounded monotonic manner. Do not keep an unbounded per-run ledger. At most one active run and one pending result exist; archive at most the last ten compact successful summaries for owner Details, with no full item blobs or mutation of lifetime totals. Preserve all unrelated existing expedition fields.

`RunRecord={seq,id,startedAt,lastObservedAt,phase,startRoute,currentRoute,mixedRoute,lastMilestone,routeEvidence,findTotals}`. `ResultRecord={id,seq,finishedAt,route,mixedRoute,elapsedSeconds,found,carried,newBankedSpecies,newUnbankedSpecies,rewards,nextMilestone,reviewEconomy}`; carried contains stable display summaries and identity references, never transfers ownership. Exact find classifications come from server-observed outcomes, not client inventory estimates.

`ExpeditionRun.begin(player,routeId)`, `.observe(player,evidence)`, `.recordDiscovery(player,event)`, `.eligible(player) -> {ok,reason?,run?}`, `.onLobbyReturn(player)`; evidence types are server-confirmed departure, ordered checkpoint, actual traversal section, movement continuity, home entry/return, and authorized travel. These methods are internal server APIs, not client RPCs.

`SummitFinish.tryFinish(player) -> {ok,pending?,reason?,result?}`, `.returnToCamp(player,resultId)`, `.acknowledge(player,resultId)`; handlers accept `summitReturn{resultId}`, `summitAcknowledge{resultId}`, `summitReplay{resultId}` for presentation only. No client grant or completion handler exists. `CoreState.summit={status,result?}` is durable presentation state; CoreFx can request opening but is not the source of truth.

### Task 1: Fresh-ascent identity and observed route evidence

- [ ] Audit the active saved sources for summit awards. Local search finds `gear.summits` storage/state and configured 60/140 rewards, but no ordinary summit increment/award path; do not assume there is an existing working grant. Identify and disable any additional live legacy award before connecting new completion.
- [ ] Write `ExpeditionRunRules` tests: no run before departure; grounded departure at an open route starts once; Ledge/Spire rejected; ordered camps and connecting traversal accepted; direct summit teleport rejected; skip from Camp1 to Camp4 rejected; fall/checkpoint respawn retains seq; main-lobby return retires attempt; personal-home visit preserves run/time; reconnect preserves valid run; starting at a high camp without recorded fresh ascent cannot earn a summit.
- [ ] Add server-side evidence observations to CheckpointService/Traversal with actual observed movement continuity. Camp order alone is insufficient: an authorized helicopter/home move, respawn, or shuttle must never count as ascending missing route segments. Export `ExpeditionRunRules.reduce(run,event,config)` and `eligible(run,arrival,config)` with explicit reasons; sample on the existing server movement cadence rather than add per-player frame loops.
- [ ] Build an ordered progress graph from existing open-route definitions and shared camps, with safe crossings at shared nodes. Keep route switching legal, marking mixedRoute=true; retain existing route/camp ownership. On rejoin validate against the saved last legitimate position; no client-submitted timestamp/position counts as evidence. Persist compact milestone progress through existing transaction coordination so another save cannot overwrite it.
- [ ] Pin time definition: wall-clock seconds from departure through arrival, including home/reconnect gaps. Reject nonfinite/backwards epochs. Record actual successful find grants and cargo transitions without double-counting recovered/swapped identities; Bank alone updates newBankedSpecies. For count uniqueness, use discovery identity credit already maintained by Profile rather than an unbounded second item ledger.
- [ ] Run `tools/.luau/luau.exe tools/summit_finish_cli.luau` red then green and Studio movement cases; existing traversal rules/access and Profile suites must pass. Register/commit scoped run modules and observations. No cinematic or prize grant yet.

### Task 2: Atomic summit completion and provisional rewards

- [ ] Write SummitTests with fake Store/clock: two arrival callbacks produce one increment; repeated zone entry produces no second prize; no valid ascent means no reward; lost response/rejoin recovers once; completion replay after general receipt trimming remains once; stale session cannot finish; new run requires returnedThrough; legacy counts preserved; no historical count issues new prizes.
- [ ] Add arrival zone as a nonintrusive stage on the true peak, preserving terrain/checkpoints and final obstacle. Require ground, living character, valid movement, complete run evidence, and no active climb/rope/flight/home state before freezing safe arrival. Missing arrival assets produce no economic grant until eligibility can be established.
- [ ] Implement pure `SummitFinish.completeData(data,run,config,now) -> ResultRecord` within Profile.transact. In the same candidate write: advance completedThrough, increment correct route lifetime count, grant coins/points, unlock first-title/cosmetic and later milestones, save immutable result and lobby return intent. A seq at or below completedThrough never mutates rewards; resolve the existing pending result or return alreadyCompleted. Keep markers across acknowledgment and generic receipt trimming.
- [ ] Local review config uses proposed 50 base coins + 100 first-ever bonus, 60 Summit Points + 140 once per first route, and cosmetics at 1/5/15/30. Read legacy first-route facts without fabricating old records. Exclude paid multipliers from summit coins and points. Mark `reviewEconomy=true`; no published release with provisional config. Exact cosmetic IDs are `summit_first`, `summit_5`, `summit_15`, `summit_30`; ownership integrates existing cosmetic equip rules.
- [ ] Assert before/after cargo identity list, lockers, bank/codex, and occupied-nest progress are identical. Carry summaries label unbanked findings; reward balances alone change. Pending save cannot report winner prizes as confirmed. Hold the player safely in the bounded finish state and recover the same transaction; no general invulnerability outside that state.
- [ ] Run SummitTests green, including uncertain-write recovery and sequence retirement; measure profile size with the ten-result bound. Run affected persistence/Commerce/Bank suites. Commit completion logic/config/tests separately from cinematic assets.

### Task 3: Personal cinematic, results, and recoverable lobby return

**Consumes:** confirmed `CoreState.summit.result`, shared settings/menu coordinator, lobby Return anchor, and existing CheckpointAPI.AuthorizeMove.
**Produces:** local scene plus immutable result banner; repeat-safe server return and separate presentation acknowledgment.

- [ ] Author original summit marker/helicopter scene with four beats: 0–4 s mountain reveal; 4–8 s celebration/prize/approach; 8–13 s pickup; 13–18 s fly-away wide shot. Create an authored helicopter rig and boarding/winch animation; use verified usable audio assets and log their IDs/licensing. If sourcing is unavailable, report that specific polish gap instead of claiming a finished audio experience.
- [ ] Implement `SummitCinematic.play(result,settings) -> controller` exposing `skip()` and `destroy()`. Use local helicopter/avatar presentation clones so nearby players are not moved or hidden globally. Manage camera/input through one cleanup owner; always restore on skip, timeout, character death/respawn, disconnect, asset failure, or panel replacement. Preserve native camera state rather than assume one fixed post-scene camera.
- [ ] Add a 5-second asset-load timeout leading directly to the same result UI; default scene duration is 18 seconds. Reduced motion uses fixed shots/brief transition; Skip has visible touch target and keyboard/gamepad help. No paid offers interrupt the scene or results.
- [ ] Implement `ResultsUI.open(result)` showing route/mixed route, elapsed time, found/safely carried creatures, new banked versus unbanked species, confirmed prizes, and next cosmetic milestone. Back to Camp is the sole primary navigation action; replay is secondary and cannot grant. Pending confirmation uses a separate saving/retry presentation, never a confirmed prize banner.
- [ ] Implement return: verify pending resultId and session, persist returnedThrough/return intent, authorize movement to Return anchor, clear obsolete summit checkpoint for subsequent fall respawn, and acknowledge presentation only after successful arrival. If physical movement fails after commit, persisted intent retries at load. Repeated return requests are safe. Generic highest-camp resume must not override a committed finale return, including empty-cargo players; pending cargo/home recovery still resolves first.
- [ ] Write `SummitChecks.presentation()` asserting camera/control restoration on every exit, asset-timeout result fallback, duplicate effects ignored, and two finishers isolated. `SummitChecks.returnFlow()` asserts rejoin before/after return, return request replay, no auto-bank, and fresh-run eligibility only after lobby return. Run actual two-client finish presentations; clearly distinguish debug-triggered scenes from real validated ascents.
- [ ] Save/reopen Finale review; run all relevant parent suites, new suites, and preservation verifier. Complete at least one genuine validated ascent and physical bank-after-return; report full route playtest and device limitations honestly. Commit scoped modules/assets integration and final evidence ledger.

### Task 4: Economy and final experience review

- [ ] Compare provisional summit reward time-to-upgrade against current discovery/home economy and measured ascent duration. Present base and first-finish rewards, first-route bonus, title/cosmetic ladder, and multiplier exclusion together. No new paid completion advantage is introduced.
- [ ] Present cinematic capture, winner banner, first and repeat finish, skip/reduced-motion versions, return-to-bank flow, and verified recovery evidence. Keep numerical tuning provisional until owner confirms it; finalizing local art does not grant publishing permission.
- [ ] Record accepted values or pending balancing in the master/working handoffs. Supply last accepted review snapshot and matching source hash, with outstanding real-device/DataStore/platform tests listed explicitly.
