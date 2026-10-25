# Mountain Empire HUD/UI implementation plan

> Execute continuously under the supplied autonomous authorization. Use focused independent implementation agents with disjoint files and a final independent review. No additional design or phase approval gates.

**Goal:** Implement the 28 approved HUD/UI decisions against the existing six-kingdom game, truthfully identifying absent gameplay.
**Spec:** `design/hud-ui-master-blueprint.md`, exact remote commit `23ee172ad8315238ed2c2039838dc139b2a80593`.
**Architecture:** Native Luau modules, one CoreUISafeInsets ScreenGui, shared components and feature hubs. Retain MountainRemotes.Event for state/combat/context. Add correlated intent acknowledgments without changing gameplay economics or world generation. UI snapshots enrich the existing profile; UI never awards anything.
**Tech stack:** Roblox/Luau, existing Rojo mapping, Luau CLI, Python XML package/audit, available Studio MCP.

## Global constraints
- Preserve native joystick/jump/CoreGui. No publication, platform purchases, unrelated world edits or changes to the concurrent mountain-art worktree.
- Exactly three creature slots; actual server team, special cooldowns, eggs, travel, income and capture state.
- One primary hub, nested detail back, explicit confirmation and dismissal; bounded connections and no per-frame screen reconstruction.
- Real readiness only. No main menu. Sanctuary spawn integration is blocked by the absent Phase 1 profile/gateway bridge; retain existing playable refuge/checkpoint behavior and disclose it.
- Missing habitat/build/placement, party invites, daily rewards, ranking service, badges/title equip and commerce backend remain explicit unavailable boundaries, never fabricated actions or data.
- No new gameplay currencies, rewards, capture limits or monetization rules.
- Concept boards are illustrative. Palette from blueprint, FredokaOne display/Gotham body, kingdom-colored mountain route motif; no remote assets required.

## Review focus
- Delayed/reordered/duplicate acknowledgments must never repeat a paid action or falsely report success.
- Short/notched landscape phones keep controls above native touch regions; menus scroll and text remains readable.
- Refreshes preserve selection, focus and scroll; no UI rebuild every timer tick.
- Capture replay, full incubators, unavailable stores, invalid targets and locked travel receive honest feedback.
- Load/respawn/disconnect, modal closure, reduced motion and save failure do not strand the player or bypass server authority.

## Task 0 — baseline and isolation
- [x] Original graph CURRENT; QUALITY_REPORT has one stale-heading review candidate, no broken edges.
- [x] Fetch remote; recover exact blueprint into new branch without changing dirty original checkout.
- [x] Isolated worktree from `codex/mountain-continuation` commit `8d2d263`; no active art edits imported.
- [x] Read full project/gameplay notes and document conflicts/capabilities.
- [x] Locate toolchain, run baseline rules/traversal and compile checks; record results.
- [x] Commit blueprint, plan, audit and baseline evidence.

## Task 1 — server intent boundary (agent; server files only)
**Files:** `mountain/server/Main.server.luau`, `Combat.luau`, `Profiles.luau`, new `UIRequests.luau`; new pure `mountain/shared/UIProtocol.luau`; tests `ui_protocol.luau` and server tests if useful.
**Consumes:** existing Rules, Combat, Competition, Profiles and world checks; existing Request remote remains backward compatible.
**Produces:** `MountainRemotes.UIRequest` RemoteEvent accepts `(id:string, action:string, payload:any)`; `MountainRemotes.UIResult` sends `{id,action,ok:boolean,message:string,data:any?}`. Duplicate id replays cached outcome without mutation; reject invalid/oversized ids and unknown actions; rate-limit, bound cache; pcall failures and busy/save-unavailable return failure. Authorized actions: State, Equip, Train, Specialize, Incubate, Hatch, Travel, CollectIncome, RegisterDefense, ChallengeDefense, Special, Dodge, Settings. A result only means success if its rule/service returned success. Return data for hatch/level/evolution feedback. Do not create new gameplay. Settings stores validated UI-only preferences with existing profile persistence.
**Snapshot:** existing state fields plus `ui={atRefuge:boolean,nearCheckpoint:boolean,serverClock:number,cooldowns:table,dodgeReadyAt:number,settings:table}`. cooldowns keys `creatureId:ability` values deadlines in workspace:GetServerTimeNow domain; dodge same domain. Snapshot `settings` defaults = `{reducedMotion=false,largeText=false,highContrast=false,simplifiedVFX=false,musicVolume=0.7,sfxVolume=0.8,hints=true}`. Enrich battle payload with kingdom, resolved, objective, members (array of `{userId,name}`), captureOwned; send false when wild encounter cancels. Preserve old data compatibility.
- [x] Test malformed intents, duplicate id, rejected intent, valid action results, bounded caches and preference validation RED → GREEN.
- [x] Add authoritative snapshot/acknowledgments using existing logic and preserve legacy remotes.
- [x] Run regression suites and compile; commit only owned files; write evidence report.

## Task 2 — client adapter and pure presentation (independent agent)
**Files:** new `mountain/client/UI/ClientState.luau`, `mountain/shared/UIPresentation.luau`, tests `ui_presentation.luau`, `ui_client_state.luau` where appropriate.
**Consumes:** Task 1 protocol above (immutable); Catalog/Rules; no dependency on UI visual code.
**Produces:** `ClientState.new(remotes)` → store with fields `profile`, `battle`, `status`, `pending`, `lastResult`; methods `subscribe(fn(kind,payload)) -> disconnectFn`, `request(action,payload,callback?) -> id?`, `retry(id) -> boolean`, `now() -> server os.time estimate`, `clock() -> synchronized server clock`, `destroy()`. Listen Event kinds state/battle/open/toast/save and UIResult; retain exact id+intent for manual timeout retry, only one outstanding request per action, 8s timeout, no automatic retries of mutations. `status` loading/ready/error; no initial State until listener registered; events propagate `pending`, `result`, `timeout`, `state`, `battle`, `open`, `toast`, `save`. Publish authoritative successes only. No local success/reward mutation. Missing UIRequest/UIResult produces truthful unavailable/error. A late result reconciles a timeout. Bounded completed history and cleanup. State request must still work when remotes appear late.
**UIPresentation API:** `filterCreatures(profile,query,rarity,sort)` array of creatures (never mutate profile); `creature(c)` returns `{name,rarity,element,role,stage,attack,health,xpRequired,abilityNames}`; `quest(profile)` returns `{title,detail,progress,total}` derived from existing discoveries/wins; `capabilities()` table map feature→`{status,reason}`; `remaining(deadline,now)` clamped integer seconds; `formatTime(seconds)`; `layout(width,height,largeText)` returns `{compact,phone,sidebarWidth,hubWidth,hubHeight,columns,teamWidth,teamBottom,actionBottom}`. Do not assume fabricated records. Settings may be absent in old profiles.
- [x] Test timer clamping, search/sort/team and quest derivation, unavailable capabilities, narrow landscape bounds RED → GREEN.
- [x] Implement adapter lifecycle and timeout/retry/late-result matching; test with minimal signal/time harness where feasible.
- [x] Run regression/compile; commit only owned files; write report with interface details.

## Task 3 — foundation and gameplay HUD (primary)
**Files:** `mountain/client/UI/Theme.luau`, `Widgets.luau`, `Feedback.luau`, `Screens.luau`, replace `HUD.client.luau`.
**Consumes:** ClientState and UIPresentation APIs above; actual Catalog and Rules; task 1 signals.
**Produces:** CoreGui-safe single root; nonduplicated collapsible sidebar; top coin/session/save widgets; compact height/quest; team and manual specials; battle/capture/trial status; contextual bottom action and original proximity prompts; loading/error/retry until profile AND character ready; no Play button.
- [x] Write Studio behavioral QA scripts for root uniqueness, control bounds, hub navigation and native-control preservation, initially fail against old HUD.
- [x] Implement reusable theme/buttons/cards/tabs/progress/modal/toasts/tooltip/loading/reveal; scalable fixed minimum touch height.
- [x] Render events only; update clock/cooldowns/height at bounded frequency without full rebuild.
- [x] Compile and build source package; commit.

## Task 4 — all feature hubs (primary)
- [x] Creatures: inventory grid with search/filter/sort, detail/stats, team editing, training and evolution timeline/specialization confirmation.
- [x] Discovery: carried/secured eggs, real incubation timing, free hatch and confirmed reveal.
- [x] Sanctuary: income, training/facility and explicit disabled habitat/build/placement boundaries.
- [x] Mountain: six-kingdom map/cards, 18 checkpoint statuses, validated travel, progression journal/trial eligibility and quest roadmap.
- [x] Social: active co-op encounter members, clear party invite unavailable; defense registration and target challenge plus result; raid boundary; profile achievements/collection/trophies and unavailable rankings/badges/title services.
- [x] Shop: approved categories but no fabricated products; unavailable checkout; no legacy pay-to-win/access integration.
- [x] Settings and quick settings: server-stored preferences, reduced motion/text/contrast/VFX/music/SFX/hints; progressive hints, sound-independent notifications.
- [x] Navigation preserves meaningful selections and scroll; pending/errors/timeouts support retry and close; no disabled-looking controls that still fire.
- [x] Compile/test, inspect, fix and commit recoverable feature groups.

## Task 5 — Studio QA, packaging and documentation
- [x] Build a separately named baked review by replacing only runtime UI/server source in a preserved mountain review XML; compare all non-source world payloads and terrain; original artifacts untouched.
- [x] Open own review Studio, verify sources and run desktop plus short/wide/notched/tablet UI bounds and actual click tests; no active art Studio mutation.
- [x] Exercise pending/rejected/duplicate intents, team, hatch/training, travel, combat and menus with clearly labeled test fixtures where unavoidable. Preserve natural-play evidence separately.
- [x] Measure UI instance stability; document cleanup review and unavailable physical frame/connection profiling honestly (emulator != physical mobile).
- [x] Final independent whole-branch review, repair defects, rerun applicable checks.
- [x] Screen-by-screen status, blockers/conflicts, exact tests/measurements, review instructions and playtest checklist in `design/hud-ui-implementation-report.md`; update CLAUDE/master, append vault pointers, graph freshness check/refresh.
- [x] Commit all task changes; no publish or merge into active branches.

## Final execution status

Completed the applicable UI/integration tasks. Checked items include an explicit unavailable boundary where the approved blueprint prohibits inventing missing gameplay. See `design/hud-ui-implementation-report.md` for all 28 decisions, phase status, actual test results, missing services and remaining hardware/live-service acceptance. No FPS or physical touch claim.
