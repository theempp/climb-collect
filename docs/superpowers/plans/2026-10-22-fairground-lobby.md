# Expedition Fairground Lobby Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow the selected method and common protocol in the parent plan.

**Goal:** Replace the central Foothold with a compact, colorful court that keeps all core services usable.

**Architecture:** Build only the central authored lobby and introduce explicit service anchors. Adapt existing consumers to those anchors while preserving legacy fallback paths during migration. Keep mountain terrain, route entries, checkpoints, and off-map personal homes intact.

**Tech Stack:** Studio/Luau, existing world Kit, generators, prompts, Camps, Home, Commerce, Training, and saved-place verification tools.

**Spec:** [Design sections 4–6, 11–12](../../../design/lobby-portfolio-summit-design-2026-10-22.md); [parent protocol](2026-10-22-expedition-redesign.md).

## Global Constraints

- Main services approximately 5–8 seconds' walking distance from spawn; direct physical mountain connection; mountain and climb entrance visible immediately.
- Work in a separate local review place, replacing the central Foothold while preserving mountain routes, personal-home systems, and protected creature assets.
- Do not regenerate mountain terrain. No publication or paid checkout.

## Review Focus

Old path assumptions, unreachable prompts, arrival collisions, reconnect precedence, and 30-player crowd readability are tested below.

## Files and interfaces

Create `src/world/FairgroundLobby.luau`: `build(kit, placement) -> {root: Model, anchors: Folder}`; placement contains surveyed `origin: CFrame`, fixed route-entry transforms, and terrain-safe build bounds. Create `src/core/server/LobbyAnchors.luau`: `resolve(world) -> AnchorSet`, `contains(position: Vector3) -> boolean`; required anchors are Spawn, Bank, Return, HomeDoor, PracticeStart, Collection, RouteBoard, and Exchange_Bundle/Flag/Trail/Next/Coins. Return typed BaseParts or an explicit missing-anchor error, never silently guess.

`World.Fairground.Anchors` is the stable contract. Add per-anchor `ServiceId` attributes and a `SafeBounds` part. HomeDoor carries the existing validated `CabinSlot=1` convention; preserve visit-directory behavior. Existing mountain route entry parts remain authoritative; connecting walkways do not relocate those entries.

Modify only as needed: `src/world/BuildAll.luau`, `src/core/server/{Camps,Home,CommerceDisplays,Discovery,Training,Tutorial}.luau`, `src/core/shared/CoreConfig.luau`, `src/runtime/CC_CoreService.server.luau`, `tools/sync_core.luau`. Keep FootholdV3 available for the backup build; do not call its terrain/build path as part of migration. Tests: `tools/lobby_checks.luau`; verifier: `tools/verify_fairground.py`.

### Task 1: Survey, anchor contract, and playable blockout

- [ ] Execute parent baseline/backup protocol. Inventory actual references to Foothold.Core.Campfire, ProvisionsMarket, PlayerCabin doors, SpawnLocation, FOOTHOLD_SAFE, TrainingYard, route gates, tutorial waypoints, and commerce plinths. Record consumers and exact existing prompt responsibilities in phase-1 evidence.
- [ ] Write `LobbyChecks.anchors()` with assertions: each required ServiceId appears once; missing Bank returns a named error; repeated resolve returns the same live parts; legacy-only baseline resolves existing bank/home/shop correctly. Run in disposable Studio Play; expect failure before the new resolver exists.
- [ ] Implement resolver and bounded generator. Build a parts-only blockout on existing safe ground with open center, mountain-facing spawn, Exchange on the right, practice on the left, and bank-adjacent return. Preserve old structures in the backup, removing only inventoried central structures from the review scene.
- [ ] Run anchor checks green; walk from spawn to every main service using actual movement, record path lengths/times and mountain sightline. Adjust until each required service is reachable within eight seconds without sprinting and the layout feels close to the selected five-to-eight-second target. Closer services are acceptable; do not introduce detours to force a minimum.
- [ ] Commit only generator/resolver/test/manifest changes after inspecting the staged diff. Save the blockout review checkpoint and capture a top view, spawn view, and phone view.

### Task 2: Reconnect all services and safe arrival

**Consumes:** `LobbyAnchors.resolve(world)` and `contains(position)`.
**Produces:** existing bank/home/commerce/practice prompts at new anchors; return destination `anchors.Return.CFrame`; source-independent service lookup for later plans.

- [ ] Write `LobbyChecks.services()` asserting bank proximity succeeds only at Bank; remote banking fails; Exchange builds five displays without the old four-stall assertion; home entry/return uses HomeDoor; practice prompt binds PracticeStart; tutorial objective points at Bank; guardian-safe checks cover the court but not arbitrary mountain space. Run red against the old path dependencies.
- [ ] Adapt service consumers to anchors, with legacy fallback only when the new root is absent. Replace CommerceDisplays' stall-count assertion and old bank offsets. Make world-display rebuild idempotent and disconnect old prompt connections before rebinding. Keep actual product offer IDs/ownership unchanged.
- [ ] Write and run arrival-priority regressions: pending economic recovery first; completed-summit return when introduced later; existing cargo/home return; active camp resume; otherwise lobby spawn. At this phase preserve existing active camp/cargo resumes; ordinary fresh players use the lobby. No reconnect may silently erase an active ascent or cargo.
- [ ] Connect new SpawnLocation and server-authorized Return movement without changing mountain checkpoint positions or invoking automatic banking. Run service checks green plus affected bank, home, training, commerce, and traversal suites. Exercise one genuine prompted action per service.
- [ ] Commit scoped changes and save/reopen the functional lobby. Require empty new console errors and recorded cargo/home identity preservation before art replacement.

### Task 3: Final fairground art and physical acceptance

- [ ] Replace blockout landmarks with authored expedition stalls, oversized equipment, pennants, flowers/crystal accents, banking landmark, home entrance, collection stage, and visible practice frontage. Use a warm base with turquoise/purple highlights; keep route silhouettes and labels distinguishable by shape as well as color.
- [ ] Add bounded attraction animation with reduced-motion fallback. Keep decorative collisions disabled and traversal/service geometry separate. Use streaming-safe groups and avoid globally replicating elaborate cosmetic previews for every player.
- [ ] Inspect 844×390, 667×375, and the existing Galaxy A06 safe viewport with largest text, plus desktop. Walk every path with the camera at ordinary player height. Verify storefronts are inspectable without obstructing the mountain view or spawning inside crowds.
- [ ] Run `LobbyChecks.crowd(30)` using explicitly labeled fixtures for path/camera stress, then actual multi-client service and home-return checks where available. Record frame timings against the same baseline route; resolve regressions before adding detail. Fixtures do not establish 30 real clients' network performance.
- [ ] Run saved-place verifier against BeforeFairground, reopen saved milestone, recapture source checksums and service smoke. Commit authored sources and evidence ledger; present the lobby review checkpoint before calling this phase accepted.
