# Expedition implementation plan — 2026-10-22

Goal: a saved, integrated player-feature build on the actual V6P1 world, ready for the owner's review.

Authority: the user's full pasted request (copied to evidence/expedition_2026-10-22/request.txt) supersedes obsolete oxygen, commerce, timer and world-expansion assumptions. Internal design/implementation review gates are explicitly preapproved. Human approval of V6P1 world expansion is NOT granted.

Architecture: retain existing source→localhost→Studio synchronization and modular CC_CoreService hook/event router. Server owns item identity, transactions, traversal state and rewards. Add a durable candidate/receipt transaction boundary, a single authored-hold traversal controller, home management, and one Expedition UI. Never regenerate terrain for this work.

Constraints: protect creatures/, ServerStorage.CC_Creatures and Workspace.CC_CreatureStage1; preserve all five regions and four route identities; Ledge/Spire unavailable; no public publish or permissions changes; <=2 in-place checkpoints. Work in existing checkout because the live Studio server serves this exact directory and the substantial finished rebuild is mostly untracked. Recoverability uses a verified .rbxl copy and source zip rather than a stale Git checkout.

## Baseline
- Correct Studio b87eac59-ff9d-48d7-adbd-be508b7b072a, ClimbAndCollect.rbxl, Edit, PlaceId/GameId 0, MaxPlayers 30.
- 55 sources compared equal to local. Legacy CC_TraverseClient maps to TraverseClient.client.luau; preserve source and retire competing runtime.
- World 4,379 descendants; protected creature folders 179 and 186 descendants.
- Two checkpoints: PreP3_2026-10-21 and PreV5_2026-10-21. Do not add another in-place checkpoint.
- ClimbAndCollect.PreExpedition.rbxl SHA256 F0F819420E283ABB8D84068227DC97C9D4EFC4108180B425B4D259A0B9345AB8 equals working saved file and V6P1. starting-source.zip preserves source/tools/docs.
- V6P1 is a first-draft Shepherd Camp1→2 beat-chain slice. Existing tutorial regression and below-target hands-on share are recorded. Expansion beyond this slice remains human-gated.
- Perf caps (World streamed after 12s): spawn5299, Shepherd2500=5316, Camp1=6246, Camp2=4511, Camp3=5006, merge5365. Desktop numbers never represent real phones.

## Tasks and ownership
- [x] Persistence/home agent: Store/Profile/Inventory/Bank/Progression, new Home/HomeConfig, tests. Durable transaction with idempotent receipt; persistent cargo; conservative timer migration; two manual nests progress only on first expedition credit; limited displayed earning assignments, manual Equip Best, income settlement/cap. Personal courts via physical existing cabin portals support capacity30 without terrain changes, visitors read-only, return to same entrance.
- [x] Traversal agent: Traversal/TraversalConfig/TraversalRules, ClimbClient, CheckpointService, Ascent integration, Coop, authored metadata tool/tests. Alternating visible holds, fork choices, assistance, harness for climb slips only, safe ropes, actual icy surface/dark gear, intentional launch parachute, authorized travel and gate validation. Existing route geometry retained.
- [x] UI agent: CC_CoreClient. Expedition Backpack/Collection/Routes/Settings, persistent stamina/altitude/capacity/level/XP, phone safe inset and 48px+ targets, keyboard/controller/touch, station sheets, status/retry, safe queued feedback, accessibility.
- [x] Root integration: CC_CoreService, Camps, Claims, Nests, DropPacks, Tutorial, Gear, Training, CoreConfig and sync tools. Durable swaps/lockers/falls/recovery/disconnect, shuttle to entrance without banking, solo noncombat distraction, provenance/memories/viewpoints, finite practice progression, obsolete purchases/O2 removal.
- [x] Root verification: compile and module tests, live Studio complete loop, adversarial remotes/transactions, route/gate/traversal checks, desktop/touch simulation/controller input, profile/performance capture. Fix failures, final code review and saved source/place reconciliation.

## Shared interfaces
- profiles:transact(session, txId, transform(candidate)) returns {ok,reason?,pending?,dup?,...result}; transform has no yields/side effects. session.owner=profiles. profiles:recover(session) resumes uncertain same-tx commit. Economic handlers block pending/busy. candidate.cargo stores exact item records; Inv.bind(uid,session) reads current session data.
- Traversal.travel(plr,pos,kind) authorizes server moves and resets fall tracking. traversalSection(plr,sectionId,route) validates practice. Character attrs CC_TraversalState/CC_Stamina/CC_HoldId/CC_SectionId/CC_NextHand; player CC_StaminaMax.
- Settings defaults textScale=1, reducedMotion=false, timingAssist=true, headlampMode=auto; settingsSet{key,value}; CC_TextScale/CC_ReducedMotion/CC_TimingAssist/CC_HeadlampMode.
- Home actions nestPlace/nestRemove/nestHatch/homeAssign/homeEquipBest/homeCollect/homeUpgrade/homeFavorite/homePet/homeCompanion/homeClose; st.home station ownership plus collection snapshot. Ownership-sensitive actions require physical owner station.
- swapOffer={token,item,sourceName,expiresAt}, swapConfirm{token,uid}, swapLeave{token}. Server retains/revalidates offered object and exact replacement UID.
- st.bank={status,message,retryable}; bankRetry{} only near bank. st.travelOffer={camp,label,available}; shuttle{} only at camp.

## Risk checks
1. Save commits then errors: no success until reconciliation, duplicate receipt cannot duplicate awards.
2. Save fails before commit, crash/rejoin: inventory ownership remains in one durable location.
3. New banked stone/self-hatch/reclaim: cannot create adventure credit; both previously occupied nests progress exactly once.
4. Walkoff vs intentional jump vs climb slip: only the correct protection applies; flight/travel cannot grant checkpoints or gated route entry.
5. Visitors, remote position spoofs, concurrent swaps, exhausted ropes: no ownership changes or unsafe forced occupant deletion.

## Execution record
- Implementation, integration, regression fixes, Studio/source reconciliation and local saving complete. Open ClimbAndCollect.Expedition.rbxl; see expedition-handoff-2026-10-22.md for exact results and manual limitations.
- 57/57 live section checks passed after repairing one existing-terrain landing. Final gate returns, immediate reentry, bank failure/retry/rejoin, ordinary fall/recovery and phone touch settings passed. Compilation63/63; Studio suites12+15+10.
- Remaining device/multiclient/real-DataStore and human route-feel checks are explicitly unverified, not approvals. World expansion remains human-gated.
- Real DataStore network validation is unavailable at PlaceId0 without publishing, which is prohibited. Exercise memory adapter failures and report this limit explicitly.
