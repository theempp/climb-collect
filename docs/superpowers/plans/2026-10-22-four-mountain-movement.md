# Four-mountain movement implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver unlimited automatic lobby running and modestly faster mountain walking with an accessible sprint toggle that shares climbing stamina, without breaking movement locks, bank validation, or existing saves.

**Architecture:** Keep `Traversal.states[player].stamina` as the only stamina resource and its existing server update as the only stamina clock. A small movement service resolves server-observed zones, intent and locks, and supplies ground stamina and speed decisions to Traversal. A client adapter handles input, status and run animation; checkpoint validation consumes the server's approved movement limits.

**Tech Stack:** Existing Roblox/Luau services, CoreRequest router, ContextActionService, Animator, local Luau CLI, Studio MCP and the existing source-sync manifest. No Rojo or new package dependency.

**Spec:** [Approved four-mountain specification](../specs/2026-10-22-four-mountain-lobby-design.md), principally sections 3 and 9; approval recorded in `e126557`. This plan awaits review. It does not reactivate the old fairground plan.

## Global Constraints

- "Approved: unlimited automatically faster lobby movement; slightly faster mountain normal movement; mountain sprint toggle sharing climbing stamina."
- "Lobby speed must not override a lock."
- "Exhaustion returns to normal walking and requires explicit retoggle to sprint."
- "Normal walking does not drain sprint stamina. Climbing remains governed by its traversal controller."
- "An unavailable animation must fall back without breaking movement."
- "Server validates zone eligibility and movement limits; client input must not grant unrestricted speed."
- "Work in separate recoverable review files; do not publish over the private playtest during design work."
- Preserve terrain, original builds, `creatures/`, `CC_Creatures`, `CC_CreatureStage1`, other protected groups and the two-checkpoint limit. No publishing, product setup, access changes or spending.
- This phase changes movement only. The enclosed hall, destination travel/save migration, mountain access and new mountain production receive subsequent scoped plans in the approved order.

## Review Focus

1. A delayed unlock or input packet from an old character must not restore sprint or release a newer character's lock (Tasks 2–3).
2. Exhaustion, jump, climb, modal, extraction and zone changes must clear sprint intent; recovery or landing must not silently re-enable it (Tasks 1–3).
3. Repeated small unauthorized movements must not pass indefinitely merely because each fits a one-frame tolerance; legitimate running, knockback and downhill falls must remain usable (Task 2).
4. Stock animation may load late, be unavailable or differ by rig; movement and climb/fall animation must survive without duplicate run tracks (Task 3).
5. A bank request between movement samples, during extraction or during a pending save must not lose/duplicate cargo or accept a forged return (Tasks 2 and 4).

## Verified starting evidence and corrections

Read `evidence/movement_2026-10-22/planning-baseline.json` and `planning-checks.json` before execution.

- Branch at planning: `codex/expedition-fairground`, HEAD `e126557`, extensive pre-existing dirty/untracked work. Git is not a complete backup.
- `Fairground.Polished.FinalCheck.rbxl`: SHA256 `ea4b63e78c20f7b25ac8fcb90c1db1de248df339fd34d91fd35a50c02e5930bc`; all 104 current manifest source texts present; every terrain property matches `ClimbAndCollect.BeforeFairground.rbxl`. Binary text membership is not instance-path or protected-asset verification.
- `Fairground.Polished.Acceptance.rbxl` has different terrain serialization. Do not use it by filename alone. The older Exchange build is missing 46 current source versions; the publish copy intentionally lacks authoring/dev modules.
- All 104 local manifest sources compile. Existing CLI suites pass: traversal 14, route access 11, summit rules 8, and flight continuity. No new behavior has been implemented or runtime-tested.
- Studio enumeration exposed only two DRS Rush places. No Climb & Collect Studio state, avatar rig, animation playback or current device performance was inspected. Re-enumerate; never reuse historical instance IDs.
- `WorldConfig.PLAYER.walkSpeed` is 12. `Traversal` owns stamina, ground recovery 13/second, climb cost 2.5 per ordinary step, and authorized travel. Preserve these climb mechanics.
- `CC_AscentClient` still writes/restores `WalkSpeed` during guardian stagger. Summit saving anchors the root; presentation and menus use local attributes/input bindings. Coordinate these instead of restoring a cached speed.
- **Corrected assumption:** `CoreConfig.WALK_SPEED`, `TRAVEL_SLACK` and the bot-speed comment describe the retired per-item minimum travel-time bank check. Current `ctx.deposit` checks physical bank range, `Traversal.canBank`, `ValidateMovement`, pending loss/save state and an idempotent transaction. The active `TraversalRules.movementAllowed` uses a broad fixed 42-stud/second envelope. Do not weaken or resurrect the obsolete check.

## Concrete provisional tuning and behavior

These are implementation defaults delegated by the approved spec, subject to measured feel tests: lobby 22, mountain normal 16, mountain sprint 23 studs/second; sprint drain 10 stamina/second; existing ground recovery 13/second; sprint restart threshold 15; animation blend 0.15 seconds. Keep climb costs/recovery and max-stamina progression unchanged. Home courts use normal 16, with no sprint; practice uses mountain sprint rules when grounded, while climbing still takes precedence.

Sprint intent can be enabled while stationary on eligible ground; drain starts only with server-observed horizontal motion above 0.75 studs/second. Idle intent costs nothing and permits existing ground recovery. Jump/airborne, climbing, travel, modal suppression, stagger, death, respawn and entering/exiting the lobby clear intent. Exhaustion stays visibly exhausted until stamina reaches 15, then reads "Sprint off" until a new input. No new resource bar.

Resolve the current lobby through `LobbyAnchors.contains(root.Position, workspace.World)` and home through server-owned `CC_HomeVisit`; missing bounds fail closed to normal mountain pace, never unlimited lobby running. The next hall phase replaces the bounds provider while retaining this contract. Do not infer lobby from altitude, camera or client attributes.

## File map

| File | Responsibility |
| --- | --- |
| New `src/core/shared/MovementConfig.luau` | Tuning values, input names, blend and bounded validation tolerances |
| New `src/core/shared/MovementRules.luau` | Pure mode/intent/stamina policy and rolling horizontal distance budget |
| New `src/core/server/Movement.luau` | Server zone/lock/intent adapter; speed authority; no second stamina loop |
| New `src/core/client/MovementClient.luau` | Input, sprint status and bounded run-animation lifecycle |
| Modify `src/core/server/Traversal.luau` | Invoke movement policy in existing tick; retain sole stamina state |
| Modify `src/runtime/CC_CoreService.server.luau` | Initialize Movement before Traversal; retire misleading bot-speed comments |
| Modify `src/runtime/CC_CheckpointService.server.luau`, `src/core/shared/TraversalRules.luau` | Approved speed envelope and rolling ground budget; keep fall/travel safeguards |
| Modify `src/runtime/CC_CoreClient.client.luau`, `CC_AscentClient.client.luau` | Mount client adapter and replace cached stagger speed restoration |
| Modify `src/world/WorldConfig.luau`, `src/core/shared/CoreConfig.luau` | Normal baseline 16; mark obsolete bank constants accurately without affecting guardian tuning |
| Modify `tools/sync_core.luau` | Register new modules and tests in the existing tree |
| New `tools/movement_rules_cli.luau`, `src/core/server/MovementTests.luau`, `tools/movement_checks.luau` | Pure checks, isolated server fixtures and live review probes |

Do not change `Bank`, `Cargo`, `Profile`, creature assets, terrain generators or reward formulas unless a demonstrated movement regression requires a separately recorded minimal fix.

## Task 1: Preserve a review baseline and define executable movement policy

**Files:** Create MovementConfig, MovementRules and `tools/movement_rules_cli.luau`; create phase evidence under `evidence/movement_2026-10-22/`. No product source is edited before the plan review.

**Interfaces:**

- `MovementRules.step(intent, sample, dt, config) -> result`, all plain tables. `intent={requested:boolean, exhausted:boolean}`. `sample={zone:"lobby"|"mountain"|"home", mode:string, alive:boolean, grounded:boolean, moving:boolean, locked:boolean, stamina:number, maxStamina:number}`. Result is `{requested, exhausted, sprinting, walkSpeed, stamina}`; no mutation of input tables.
- `MovementRules.advanceBudget(credit:number, elapsed:number, speed:number, distance:number, config) -> (newCredit:number, allowed:boolean)`. Reject non-finite/negative inputs. Token bucket capacity 8 studs; accrue at approved speed × 1.25 per second, capped to capacity, subtract observed horizontal distance. Do not refill on a rejection.
- Config keys: `lobbySpeed=22`, `walkSpeed=16`, `sprintSpeed=23`, `sprintDrain=10`, `groundRegen=13`, `restartStamina=15`, `motionThreshold=0.75`, `blendSeconds=0.15`, `distanceBurst=8`, `distanceSlack=1.25`.

- [ ] **Step 1: Capture isolation evidence.** Follow using-git-worktrees at execution time. Preserve the actual dirty/untracked source in a verified archive and starting status before isolation; a worktree from HEAD alone is insufficient. Prefer a separate complete execution snapshot/worktree with explicitly copied required untracked source and binaries. Copy the verified FinalCheck to `ClimbAndCollect.FourMountains.Movement.Review.rbxl` without overwriting an existing file. Record both hashes. Re-enumerate Studio and open that local copy; inspect Edit state, PlaceId, script paths/Disabled values, rig settings, terrain and protected group baselines before sync. Keep the original file intact.
- [ ] **Step 2: Write failing pure tests.** Name cases `lobby_unlimited`, `mountain_walk_recovers`, `moving_sprint_drains_shared_pool`, `idle_intent_no_drain`, `exhaustion_requires_retoggle`, `locks_win`, `jump_climb_travel_clear_intent`, `home_no_sprint`, `invalid_numbers_reject`, `budget_rejects_sustained_overspeed`. Example numeric assertions: starting at 50, one grounded moving sprint second yields 40 at speed 23; one walking second yields 63 at 16; lobby running never drains; empty stamina yields speed 16 and requested=false. Modes climb/rope/hanging/flight/travel preserve incoming stamina and produce no ground run speed; locked/dead speed is 0. Clamp stamina to maximum after max changes. A normal grounded sample gets the normal speed even while airborne afterward, but no sprint drain/recovery in air.
- [ ] **Step 3: Run `tools/.luau/luau.exe tools/movement_rules_cli.luau`.** Expect a missing module failure before implementation.
- [ ] **Step 4: Implement the two pure functions and config.** Precedence is dead/lock, traversal control, lobby, home, mountain sprint/walk. For non-ground traversal set WalkSpeed 0; fall/jump uses 16 and clears sprint. Clamp negative/oversized dt to 0–0.2 in production integration; tests may accumulate multiple ticks to assert one-second totals.
- [ ] **Step 5: Run the CLI again.** Require every named case to pass; add sequence assertions for several seconds of 23-speed movement passing and sustained 60-speed ground movement exhausting the budget despite individually small steps. Store output and commit only this task's new modules/tests and scoped evidence.

## Task 2: Integrate authority, shared stamina and bank-safe movement validation

**Files:** Create `src/core/server/Movement.luau` and `MovementTests.luau`; modify Traversal, CoreService, CheckpointService, TraversalRules, WorldConfig, CoreConfig, sync manifest and existing traversal CLI as needed for the new limit argument.

**Interfaces:**

- `Movement.init(ctx)`, `onCharacter(player,character)`, `onLeave(player)`, `state(player,snapshot)` follow existing service conventions.
- `Movement.step(player, traversalState, dt, now, grounded) -> result` consumes Task 1 policy, applies the server's WalkSpeed, stores only intent/lock metadata, and returns result. Traversal assigns `s.stamina=result.stamina` once for ground/fall; climb/rope/hanging keep their existing resource paths. Invoke policy before the travel early return too, so travel clears sprint immediately.
- `Movement.lock(player, key:string, duration:number?) -> token:number`; `unlock(player,key,token)` releases only the matching character-generation token. Nil duration is server-only; untrusted UI suppression has a renewable 1.5-second lease. `Movement.cancel(player)` clears sprint without refilling stamina.
- `Movement.approvedSpeed(player) -> number` reports server policy, never client Humanoid.WalkSpeed. `TraversalRules.movementAllowed(horizontal,upward,elapsed,approvedSpeed?)` retains legacy callers with 16 as the default. The checkpoint service owns the rolling distance credit and updates it exactly once per sampled segment, including synchronous bank validation.
- CoreRequest action `movement` accepts `{action="sprint", enabled:boolean, generation:number, seq:number}` or `{action="suppress", enabled:boolean, generation:number, seq:number}` only. Server publishes character `CC_MovementGeneration`, `CC_MovementZone`, `CC_Sprinting`, `CC_SprintAvailable`, `CC_SprintExhausted`, `CC_MoveSpeed`. Drop stale generation/sequence and malformed payloads; use existing router limits plus a per-player movement request cap of 10/second. No request accepts positions, speed, stamina or zone.

- [ ] **Step 1: Write failing `MovementTests.run()` fixtures.** Assert one pool after sprint→clip→step, no regen while sprinting, normal regen after cancel, new character cancels old requests, overlapping lock tokens cannot unlock each other, max-stamina changes clamp, no speed advantage from forged zone/stamina/speed values, and state resets on leave. Use fresh fake contexts/actors or pure fixtures; never mutate the active player's profile for unit tests.
- [ ] **Step 2: Run fixtures on the identified local Studio review server.** Expect failures for missing Movement; capture that failure before integration.
- [ ] **Step 3: Integrate the service.** Initialize it before Traversal; no independent stamina Heartbeat. Read server root position and observed velocity/delta for zone and movement. Consume `hit` through the existing event bus with the configured stagger duration. Respect dead, root.Anchored, PlatformStand, travel, held traversal, `CC_SummitSaving` and leased modal suppression. Clear sprint at travel/begin/leave/respawn boundaries, not just on the next snapshot. Set fallback StarterPlayer speed to 16 in the review copy, without running a world builder.
- [ ] **Step 4: Update active movement validation.** Use approved speed with the existing broad single-sample sanity check capped by elapsed time, and the new rolling ground budget to reject sustained excess. Preserve the existing vertical fall limit behavior and server-only AuthorizeMove receipt. Validate synchronously before bank/checkpoint acceptance; consume each interval once so repeated bank requests do not double-charge movement distance. Authorized travel resets the baseline/budget, never grants cargo or deposits it. Preserve eight-second invalid-movement quarantine. During existing airborne/knockback/traversal modes retain their current bounded motion checks; never treat a client-provided mode as an exemption. Record the remaining airborne enforcement limits rather than claiming general exploit prevention.
- [ ] **Step 5: Add adversarial bank fixtures to MovementTests.** Test valid 16/22/23 movement followed by a physical bank request; forged 80-stud teleport before the next heartbeat; repeated small 60-speed steps; unauthorized direct bank call; same-tick duplicate validation; authorized shuttle/summitReturn retaining cargo until deposit; ordinary downhill fall still applying its cargo outcome; pending-save retry and duplicate deposit preserving identities/counts. Include zone boundary crossing without a free budget refill and server-authorized travel without a false speed rejection.
- [ ] **Step 6: Run MovementTests, traversal CLI, existing TraversalTests and ExpeditionTests.** Require all assertions pass and capture output. Check `rg -n 'WalkSpeed|WALK_SPEED|TRAVEL_SLACK|devSpeed' src` for remaining owners and obsolete references; change misleading comments, retain unrelated guardian speeds. Compile changed files with `tools/.luau/luau-compile.exe --null <file>`. Commit only scoped changes; don't stage other dirty work.

## Task 3: Add accessible toggle, feedback and run animation

**Files:** Create `src/core/client/MovementClient.luau`; modify CoreClient, AscentClient and sync manifest. Preserve `CC_ClimbClient`'s higher-priority climb track.

**Interfaces:** `MovementClient.mount({parent:ScreenGui, request:function, blocked:function}) -> {destroy:function, suppress:function}`. Mount once from CoreClient. `blocked()` covers existing menu/summit presentation, focused TextBox and loss of window focus. Local suppression sinks character inputs and requests only lower authority via the server lease; it never grants speed or sets stamina.

- [ ] **Step 1: Add failing live acceptance cases to `tools/movement_checks.luau`.** Export `run(options) -> report` with explicitly separate `fixtures` and `observations`; record original character/speed/stamina and cleanup. Cases: keyboard LeftShift toggle, controller ButtonL3 toggle (R3 remains inspect), touch Activated toggle, typing/focus suppression, exhaustion status, death/respawn cleanup, menu/guardian overlap, and delayed animation creation. Fixture calls do not count as real device input.
- [ ] **Step 2: Run baseline checks before adding the adapter.** Confirm missing toggle/feedback, then capture current avatar `RigType`, Animate.run/walk/climb assets and actual Animator tracks. Do not invent an animation ID or assume ownership.
- [ ] **Step 3: Implement input and feedback.** Use ContextActionService Begin only; input priority below summit/menu bindings. Send explicit desired state with generation and monotonic seq, not a blind server flip. Add a selectable 64×56 minimum target above the phone jump area, move upward when traversal controls are visible, respect safe insets and existing text scale. Labels: "SPRINT OFF", "SPRINT ON", "RECOVERING"; hide in lobby/home and suspend while blocked. Stamina stays in the existing bar. Clear input on jump, lost focus, character removal and modal open; closing a modal never resumes sprint automatically. The server acknowledgement drives the final status.
- [ ] **Step 4: Replace AscentClient's cached WalkSpeed restore.** Route guardian suppression through the adapter/server lease and preserve existing knockback. Keep locks keyed to the character generation; an older timer cannot release a new lock. Do not alter hazard damage or cargo outcomes.
- [ ] **Step 5: Implement animation lifecycle.** Prefer the current rig's existing loaded Animate.run Animation, then its walk animation as fallback, preserving Animate's idle/jump/fall control. Load at most one looped Movement-priority track per character; blend 0.15 seconds and scale playback by measured horizontal speed/reference 16, clamped 0.5–1.8. Play only for moving grounded lobby run or mountain sprint; stop during idle, airborne, climb, locks and death. If asset loading fails or remains zero-length for two seconds, stop/destroy the added track and retain stock animation; retry only on a new character or changed asset. Cache discovery, avoid loading every frame. Do not claim upload or ownership. Verify both R6 and R15 if enabled; unsupported rigs retain stock behavior.
- [ ] **Step 6: Verify actual keyboard/mouse, Device Simulator touch and emulated controller events, plus tracked animation start/stop/playback.** Record physical controller/phone as unverified unless actually used. Check max text scale and no overlap on landscape phone, pressed keys across modal close, fast double toggles, streamed character assets, unavailable asset fallback and respawn with no duplicate bindings/tracks. Compile changed files and commit scoped work.

## Task 4: Validate, save and hand off the movement review

**Files:** `tools/movement_checks.luau`; phase evidence and project/vault records. Any minimal fix returns to the owning task's failing/passing test cycle.

- [ ] **Step 1: Sync only reconciled changed sources into the selected Edit DataModel.** Register modules under `ReplicatedStorage.CC_Core`, client module under `CC_Core.Client`, server modules under `ServerScriptService.CC_CoreServer`, probe under `CC_DevTools`. Compare saved source content and instance paths; restore HttpEnabled=false after sync. Never regenerate terrain/authoring data just to change speed.
- [ ] **Step 2: Play real traversal and banking.** Walk/run from natural spawn, cross lobby bounds, toggle sprint on the existing open mountain route, clip a climb with partially spent stamina, recover, jump, take a guardian/hazard hit, use a camp return, physically bank, and exercise summit presentation/return via a labeled fixture. Keep fixture evidence distinct from a genuine ascent. Test interrupted/failed save and reload with existing memory-store hooks; explicitly distinguish these from live DataStore/rejoin. No live-service publication is authorized.
- [ ] **Step 3: Run a two-client review.** One player stays in lobby while another sprints/climbs; confirm independent stamina/intents, visible animation, travel/bank outcomes and clean respawn. Capture CPU/frame/memory observations in the same focused desktop and landscape-emulator scenes before/after; investigate a sustained regression over 10% with repeated equal-condition samples. This is a regression trigger, not a claimed phone budget. Physical phone review and four-mountain multiplayer remain future checks.
- [ ] **Step 4: Run the relevant regression set once after fixes.** CLI: movement, traversal_rules, traversal_access, summit_finish, summit_flight. Studio: MovementTests.run(), TraversalTests.run(), ExpeditionTests.run(), Tests.runA1(), SummitTests.run(), DailyPracticeTests.run(). Capture counts and failures; no fabricated passing count. Compile every current manifest entry. Broaden tests only if an integration change warrants it.
- [ ] **Step 5: Save and reopen `ClimbAndCollect.FourMountains.Movement.Review.rbxl`.** Verify source content AND target paths, disabled legacy controller, HTTP off, no temporary agents/probes that auto-run, exact original terrain serialization and protected groups against Task 1 baseline. Back up any save before correcting serialization drift. Hash the reopened final file and record its source archive/commit. Run a brief reopened input/animation/bank smoke test.
- [ ] **Step 6: Review and record.** Use the selected execution workflow's independent review, address actionable findings and rerun only affected checks. Update CLAUDE/master with verified movement result, tuning, evidence, corrected assumptions and remaining physical-device/live-save limits; append concise pointers to Climb & Collect vault notes. Run graph status → refresh if stale → status. Commit only scoped work. Present the local review and actual test limits before starting the separately planned lobby/sunny slice.

## Self-review and execution handoff

Coverage checked: all section 3 movement requirements have tasks, including input, asset fallback, locks and bank reconciliation. Section 9's preservation/evidence boundary is in Tasks 1 and 4. Section 4–8 world production, per-mountain persistence and access are intentionally deferred to the next scoped plans, not omitted from the overall approved project.

Interface check: Traversal remains the resource owner; Movement has no stamina store/clock; client has no speed grant; checkpoint remains the bank validation boundary. Token generations cover stale character callbacks and rolling credit covers small repeated movement abuse. No asset ownership, physical device performance or current Studio state is assumed.

Recommendation: **Native execution with final independent review**, because the four tasks share the same traversal, input and validation state. The native choice on the earlier fairground plan is historical; this new plan's review/execution choice will be captured together in the required multi-question widget. Until then, product source and Studio remain unchanged.
