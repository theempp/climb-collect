# Free-Climb Mountain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Execution occurs in the requested NEW chat, not the planning chat.

**Goal:** Deliver a separate playable local review of the approved six-section break/reveal/carry/escape mountain while preserving the integrated sanctuary, collection and tycoon.

**Architecture:** Start from the durable HUD clone and reconcile the later tycoon label correction in an isolated checkout. Separate pure custody/guardian rules from server services and client presentation; server-authored world metadata drives the six sections, pursuit boundaries and sanctuary exit. Keep existing profile identity and legacy egg support with a tested additive migration.

**Tech Stack:** Roblox Studio, Luau CLI, existing Python XML packaging/audit tools, existing HUD/remotes and session-locked Store adapter. Reuse installed tooling; no new service, paid generator or purchase.

**Spec:** `C:/Users/HOME!/Desktop/climb&collect/docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md` — approved October 25, 2026, including the connective proposals. Owner requested planning here and actual build in a new chat.

## Global Constraints

- All six sections attemptable from the start; no guardian-victory or collection access gate.
- First pickaxe strike alerts guardian; tap each strike; reveal on mountain; one carried creature; small-creature two-arm cradle.
- Permanent safety only at mountain exit into sanctuary; carry home afterward. Catch/serious fall/leave/reset forfeits unsecured run.
- Normal wins: brief public raid opening + companion XP; guardian returns. Harder Trial: portable guardian reward, capture recorded only on secure exit.
- Preserve owned creatures, production, currencies, legacy eggs/incubators, all historical places/art, and unrelated launch work.
- No tool shop, speed gate, new currency, theft, publication, purchases or production-store tests.
- No approved trip duration, strike count, chase speed, respite duration or hazard frequency. Centralize provisional tuning and label it honestly.
- No premium-art/human-fun/real-device/hosted-save acceptance from CLI or simulator evidence alone.

## Review Focus

1. Exit crossing racing death/disconnect/save failure must yield at most one reward and never acknowledge an unsaved ownership grant — Task 2.
2. Simultaneous egg strikes, death and target departure must not duplicate reveals, strand reservations or redirect danger onto bystanders — Tasks 3/4.
3. Normal battle/Trial/chase overlap must not immobilize the shared defender or permanently suppress danger — Task 4.
4. Malformed old profiles and repeat migration must preserve original data without duplicating entitlements — Task 2.
5. Phone input during menus/reveal/respawn must retain movement, sightlines and one HUD without double strikes — Tasks 3/6/7.

## Source and execution location

Planning/navigation repo: `C:/Users/HOME!/Desktop/climb&collect` (dirty; preserve it).

Preferred execution checkout: new durable sibling `C:/Users/HOME!/Desktop/climb-collect-free-climb-build`, branch `codex/free-climb-mountain`. Create only at execution time. If already present, inspect ownership/status and reuse only if suitable; never reset it. Follow isolation skill at execution time; a durable independent clone is preferred given recorded worktree losses. Do not create it from Desktop's old src.

HUD source: `C:/Users/HOME!/Documents/ClimbCollect-HUD-2026-10-25`, clean at `ddf870acf0cfacce465a2d6bbf75562defca6db4` when planned. Tycoon source: `C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/work/climb-collect`, clean at `3517d8a67b8e2b1d384102a3ae0a1999bd89e963`. Revalidate; do not overwrite newer work.

Place baseline: exact HUD recovery `C:/Users/HOME!/Documents/ClimbCollect-HUD-Recovery-2026-10-25/ClimbCollect.HUD.Complete.Review02.rbxlx`, SHA256 `b712e1654653519e1d060c05f5e976c2b6ca8737e3d5604ce7f88b5c802cf62b`. Ordinary HUD output has known hash drift. Tycoon Review06 SHA256 `3c45ca40a09af5d06ca1f5edc79aeff9ae8bd9f257287c9d53a7d7f0bae99ab6`; full paths/differences in `design/workspace-review-2026-10-25.md`.

All following paths are relative to the isolated execution checkout. Discover the installed Luau executable once and record its absolute path as `<LUAU>`; commands below use that verified executable. This placeholder is environment discovery, not a missing design choice.

## File responsibilities and contracts

- Existing `mountain/shared/Rules.luau`: collection/team/economy, free access, legacy egg functions; delegate new-loop custody to `RunRules.luau`.
- New `mountain/shared/RunRules.luau`: pure schema migration, run transitions and idempotent ownership transaction preparation. `migrate(profile)->profile`; `strike(profile, egg, now)->boolean, reason`; `pickup(profile, runId)->boolean, reason`; `forfeit(profile, reason)->boolean`; `secure(profile, runId)->boolean, reason` operates on a transaction draft only.
- New `mountain/shared/RaidConfig.luau`: six hazard/guardian/egg tuning records, version and explicit provisional values; `section(k)->config`.
- New `mountain/shared/GuardianRules.luau`: pure shared guardian state machine. `new(k,now)->state`; `alert(state,userId,eggId,now)->state`; `step(state,observations,now)->state, effects`; `normalWin(state,contributors,now)->state, effects`.
- New `mountain/server/EggRaids.luau`: validated reservation/strike/pickup/forfeit/exit service. `new(context)->service`; service methods `strike(player,eggId)`, `pickup(player,runId)`, `forfeit(player,reason)`, `exit(player,runId)`, `remove(player)`, `tick(now)` return accepted boolean/reason where applicable.
- New `mountain/server/Guardians.luau`: shared defender motion, target selection and hazards; `new(context)->service` with `alert`, `tick`, `remove`, `normalWin`; consumes GuardianRules effects. Existing `Combat.luau` retains companion damage/mastery but adapts normal fights and separate Trial manifestation.
- Existing `Profiles.luau`: additive schema validation/migration and `transact(player, transactionId, mutate)->boolean, reason` for serialized, session-locked durable exit commits. `mutate(draft)` never touches live profile until commit succeeds.
- Existing `Main.server.luau`, `Journey.luau`, `UIRequests.luau`, `UIProtocol.luau`: wire services, deny unsafe travel, publish authoritative run/guardian state and outcomes.
- New `mountain/client/EggCarry.client.luau`: shell/reveal/carry/put-down presentation, no reward authority. Existing HUD/UI and CreatureMotion adapt contextual actions, legacy egg screens and carry poses.
- New `mountain/world/FreeClimb.luau`: six-section metadata/geometry, reachable rest points, egg anchors, escape lanes, guardian bounds and validated exit volumes. Existing World/Landmarks/TraversalArt/Polish call it only in the separate new review build.
- Packaging `mountain.project.json`, `mountain/tools/sync_edit.luau`, `prepare_review.py`, `package_hud.py`, `audit_saved.py`: register every added runtime source including nested UI; updated audits use new explicit topology instead of old fixed encounter/checkpoint counts.

## Task 1: Preserve and reconcile one current baseline

**Files:** existing `mountain/server/TycoonWorld.luau`; new `design/free-climb-build-log.md`, `evidence/free_climb_2026-10-25/baseline.json`.

**Consumes/produces:** exact source/place hashes above → isolated current integrated baseline plus reproducible test commands.

- [ ] Re-read startup/approved spec/this plan and current source instructions. Check graph freshness, enumerate Studio and protect unrelated sessions. Capture full Git status and source/place hashes; back up non-Git assets and verify the backup before any mutation.
- [ ] Create isolated durable checkout from HUD source, retain its newest HUD, and compare the seven normalized source differences against tycoon. Bring over only the verified later label correction and any genuinely required dependency; do not replace HUD with old tycoon UI.
- [ ] Run existing rules, journey, traversal, tycoon, UI suites with `<LUAU> mountain/tests/<suite>.luau`; use `python mountain/tests/run_ui_server.py` for its existing mocked service suite. Discover exact compile/fixture invocation from current reports and record it. Expected: baseline suites pass; preserve any pre-existing failure separately.
- [ ] Package a uniquely numbered integrated baseline from exact recovery and source, audit all runtime scripts and sanctuary preservation, cold-open it. Do not use old audit counts as redesign requirements. Commit only this task's intended files in isolated checkout.

## Task 2: Custody, migration and durable exit

**Files:** create RunRules and `mountain/tests/run_rules.luau`, `mountain/tests/run_persistence.luau`; modify Rules, Profiles, Store only where needed, StudioTests, UIProtocol.

**Interfaces:** profile schema 2 retains all schema-1 fields plus `run`, `legacyEntitlements`, bounded `securedRunIds`. Run: `{id,eggId,species,section,phase,hits,trial}`; phase breaking/revealed/carried. New runs expire/forfeit rather than enter legacy cargo recovery. Migration converts schema-1 cargo/recovery IDs into one-time secured legacy egg entitlements; preserves secured eggs/readiness/roster/captures/tycoon/settings. Migration runs once, before schema-2 validation.

- [ ] Add failing tests: `all_six_open_without_wins`, `one_run_only`, `reveal_is_not_ownership`, `catch_fall_leave_reset_forfeit`, `exit_once`, `trial_capture_only_on_exit`, `lost_trial_can_retry`, `legacy_migration_twice_no_duplicates`, `invalid_profile_no_overwrite`.
- [ ] Run `<LUAU> mountain/tests/run_rules.luau`; expect new assertions fail on old gated/cargo behavior. Implement pure functions/contracts above; keep legacy incubation callable and production eggs separate.
- [ ] Add transaction tests: `exit_disconnect_race`, `failed_save_no_safe_ack`, `retry_same_exit_once`, `concurrent_tycoon_mutation_preserved`, `stale_session_cannot_commit`. Implement Profiles.transact using existing Store lock/write-id mechanics, serialized against saves and profile mutations. Return Safe only after durable success; on failure retain a pending secure transaction under retry/protected-exit presentation rather than lose or duplicate reward. Reject new risky actions until resolved.
- [ ] Run new suites, old rules/tycoon/UI suites and Studio memory-store tests; expected all preserved behavior passes except deliberately replaced access/cargo assertions updated to new approved rules. Commit.

## Task 3: Egg strike, reservation and physical carry

**Files:** create EggRaids, RaidConfig, EggCarry, `mountain/tests/egg_raids.luau`; modify Main, UIProtocol, UIRequests, HUD client/UI Controller/Screens and CreatureMotion; register sources in packaging manifests.

**Interfaces:** validated egg IDs resolve to server section/position/species; each accepted tap increments server strike work once at configured cadence. First strike calls Guardians.alert. Published run contains immutable server runId/phase/species; pickup/exit requests reference it, never supply reward species.

- [ ] Add failing assertions for remote distance/cadence/spam, two players same egg, two eggs same player, post-death delayed pickup, foreign runId, abandoned reveal cleanup, no double reward on replay, full hands, menu/respawn double taps.
- [ ] Run `<LUAU> mountain/tests/egg_raids.luau`, confirm failures, then implement validation and reservation cleanup. Respawn/reset/disconnect routes call one forfeit path.
- [ ] Implement one-tap strikes, crack/chip feedback, fast interruptible reveal/pickup and two-arm small-creature carry. Large species get portable species-appropriate collectible presentation; preserve adult/boss sources. No new generated assets in the planning chat; in build reuse/refine approved project assets and record any art shortfall.
- [ ] Run suite and actual keyboard + touch-simulator strike/reveal/pickup/carry run; verify no reveal animation traps player while guardian advances, and no equipped-companion/carry collision. Commit.

## Task 4: Mobile guardians, optional combat and Trials

**Files:** create GuardianRules, Guardians, `mountain/tests/guardian_rules.luau`; modify Combat, Main, Catalog/RaidConfig and combat UI.

**Interfaces:** GuardianRules states defending/approaching/pursuing/resting; active threat IDs require accepted strike or deliberate combat. New alerts prioritize actively breaking eggs; deterministic proximity tie-break and stable target dwell. Bounded handoff removes distant/dead/left targets. NormalWin emits eligible-XP and finite public-respite effects once. Trial manifestation is separate; success creates EggRaids reserved reward, not permanent capture.

- [ ] Add failing tests: first accepted strike alerts, multi-egg priority, unrelated bystander excluded, target leaves/dies, no lower-section auto-aggro, timeout returns defense, normal win XP contributors once, respite ends/nonstacking, Trial leaves defender active, repeat secured capture denied, lost Trial reward retry allowed.
- [ ] Run `<LUAU> mountain/tests/guardian_rules.luau`, expect fail; implement state machine and companion-combat adaptation without immobilizing defender at altar. Preserve progressive combat difficulty and distinct guardian anatomy/identity.
- [ ] Verify two actual clients breaking different eggs and fighting concurrently; late join must see same guardian state, no unrelated damage/retarget. Capture normal victory/respite/return and Trial carry-to-exit. Run existing combat/UI regressions; commit.

## Task 5: Six-section open mountain and authored dangers

**Files:** create FreeClimb and `mountain/tests/free_climb_geometry.luau`; modify World, Landmarks, TraversalArt, Polish, Traversal, RaidConfig and new-review geometry only.

**Interfaces:** FreeClimb exports metadata `{sections,eggs,restPoints,guardianBounds,exitVolumes}` consumed by services; section IDs 1–6 preserve Catalog mapping. Exit volumes are sanctuary-facing reachable paths, not broad proximity bubbles overlapping mountain.

- [ ] Add failing geometry checks for all sections accessible without wins, clear egg approach, reachable return/rest points, intended escape landings, boundary non-overlap, guardian bounds and no sanctuary hazard damage. Run `<LUAU> mountain/tests/free_climb_geometry.luau` to expose old topology assumptions.
- [ ] Author the open-face climb/downhill lanes with distinct sightlines, six landmarks and few readable hazards: root sweep, water pulse, crumbling sandstone, prism crossing, fire vents, gravity pulse. Keep safe gaps, alternate crossing lines and intentional landing distances. Reuse protected source/art; change only new review geometry/terrain with explicit new terrain authority.
- [ ] Verify Blossom complete polished loop first, then carry its readability/interaction standard through the other five. Internal checkpoints allow iteration; they are not six new design-approval interviews. Preserve all old places rather than destructively converting them.
- [ ] Run geometric checks plus uninterrupted natural ascent/descent for each section, capturing real avatar-scale egg/guardian/exit views. Old obby/mover loops may remain archived; they are not mandatory new-loop stages. Commit.

## Task 6: Safe return, travel and integrated home experience

**Files:** modify Journey, Main, Sanctuary, UIRequests, UIProtocol, UI Screens/Controller; new `mountain/tests/run_journey.luau`; keep Tycoon services intact.

**Interfaces:** travel with a live unsecured run returns `abandon_confirmation_required` without moving/secure. An accepted abandon confirmation forfeits first, then requests ordinary travel with fresh origin validation. Cancel keeps run. Exit invokes EggRaids.exit/Profiles.transact; post-exit travel/placement reads secured roster ID.

- [ ] Add failing assertions: checkpoint never secures, denied shortcut never moves, confirmation cancel retains run, accepted abandon loses only unsecured, guardian cannot cross exit, exit then disconnect preserves roster, placement after reconnect grants nothing twice, legacy hatch/production banking unchanged.
- [ ] Run `<LUAU> mountain/tests/run_journey.luau`, confirm fails; wire actual travel and exit paths, remove old auto-extract/checkpoint secure for new runs and old victory gating labels. Keep legacy entitlement hatch screens explicit.
- [ ] Verify natural mountain → exit Safe → carry home → place → habitat assignment/production loop; normal reset/leave before exit forfeits, after exit preserves. Record simulated reconnect separately from real hosted persistence. Commit.

## Task 7: Package, regression, multiplayer and handoff

**Files:** packaging/audit tools/manifests, `mountain/tools/free_climb_acceptance.client.luau`, `design/free-climb-build-report.md`, evidence folder and unique `outputs/ClimbCollect.FreeClimb.ReviewNN.rbxlx`.

- [ ] Extend saved audit to every runtime module/UI file, six new section metadata, no temporary QA scripts, explicit approved terrain authority and unchanged sanctuary/protected-asset hashes. Preserve old audit capabilities instead of weakening preservation checks to make new world pass.
- [ ] Run new and existing affected suites/compiles, package using guarded tools to a new filename, save, close only the newly created review session, reopen and confirm source/world/terrain parity and clean startup. Rojo source build alone does not prove baked place parity.
- [ ] Run two-client contention/failure matrix and eight-client local smoke where tooling supports it; validate phone landscape/native controls/large text/reduced motion, one HUD after respawn and carried-model camera clearance. Record unavailable physical/hosted tests honestly.
- [ ] Capture representative strike/reveal/cradle/run/put-down motion and all six danger encounters. Measure human timing only if actually performed; no acceptance target invented from demo numbers. Separate functional local review from premium art and phone acceptance.
- [ ] Use independent final code review, resolve actionable findings, rerun affected checks and commit intended files only. No merge/push/publication required. Update project/vault pointers with hashes/results/remaining gaps; refresh graph and report coverage limits.

## Self-review and completion boundary

Coverage: spec loop/custody/migration → Tasks 2/3/6; all six geometry/hazards → Task 5; shared combat/Trial → Task 4; presentation/mobile/source consolidation/preservation → Tasks 1/3/7. All five Review Focus cases have named tests. Interfaces use RunRules, EggRaids, Guardians and Profiles.transact consistently. Numeric tuning remains centralized and provisional; source functions are planned interfaces, not claims they already exist.

Finish with a playable, numbered local review and clear test/report evidence. Owner aesthetic acceptance, physical devices, hosted saves and exact rollout migration verification may remain explicit external gates; do not call the game released or publish to close them.

## New-chat execution handoff

Read `design/free-climb-build-handoff-2026-10-25.md`, this plan and approved spec. The user chose execution in a NEW chat and no generation/build in the planning chat. Start with a concise plan review so the owner can confirm this concrete task sequence, then execute natively using executing-plans in the isolated current-source checkout. Do not reopen settled design questions. Do not request approval for routine reversible implementation choices; ask only for a material change outside the approved spec. Do not publish, purchase, replace source places or touch DRS Rush.
