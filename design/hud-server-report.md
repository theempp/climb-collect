# HUD server boundary evidence - 2026-10-24

Task 1 only, isolated `codex/mountain-hud-ui` worktree. No Studio writes, world generation, terrain/art changes, publication, purchases or gateway integration were performed by this agent. `mountain/shared/Rules.luau`, Catalog, Competition and Store remain unchanged. Existing costs, XP, capture rules, incubation, travel gates and encounter calculations remain authoritative.

## Context and conflict audit

Read the implementation plan, complete HUD blueprint, CLAUDE.md and master.md; read vault Home, project overview, Decisions, Milestones and Open Questions. The older master still describes the five-region expedition/Foothold model, while this isolated source implements six kingdoms, refuge, three-slot teams and normal/Trial Guardians. This task enriches that implemented game's interface and preserves its rules; it does not implement the conflicting older loop. Sanctuary spawn still lacks the Phase 1 profile/gateway bridge. Habitat/build/placement, party invitations, daily rewards, ranking/badges/title services and shop checkout have no new server action or fabricated data. Competition is the existing saved-defense service, including its explicitly labeled practice target 0.

Original checkout graph status returned CURRENT, zero intended-input drift on 2026-10-24. Query `Mountain profile persistence UI` returned older original-checkout files, so exact claims were verified in current isolated source. The isolated worktree has no graphify_refresh tools/graph files; the original graph does not cover these new isolated sources. Original QUALITY_REPORT has zero broken edges and one historical overview-heading review candidate. No retrieval implementation changed and no benchmark/re-export was performed by this agent. The parent integration should append the final milestone pointer to the Climb & Collect vault and recheck original graph freshness after its documentation changes.

## Wire contract

- `MountainRemotes.UIRequest:FireServer(id, action, payload)`.
- `MountainRemotes.UIResult` delivers `{id:string,action:string,ok:boolean,message:string,data:any?}`.
- Legacy `Request` and existing `Event` remain supported. Both request routes call the same dispatcher/rules. Correlated yielding actions hold the same busy lock checked by legacy requests and proximity prompts.
- IDs are `<token>:<positive sequence>`, at most 64 bytes. Token is 1-48 ASCII letters/digits/underscore/hyphen; sequence is 1-15 digits, without leading zeros. Client uses GUID token plus increasing sequence.
- Cache retains 128 outcomes per connected player, with at most four client tokens. Duplicate cached ID replays its original outcome even if the resent action/payload differs. A duplicate still in flight emits no second terminal response; the original request eventually responds. Evicted or reordered lower IDs reject without execution using each token's retained high-water sequence. A fifth token rejects until reconnect. Disconnect clears this session state. This is connection-scoped idempotency, not cross-server durable receipt storage.
- New valid intents are limited to one per 0.12 seconds. Busy, rate-limited, invalid-payload, unavailable-profile and service-error outcomes are failures. Completed failures are cached; an explicit fresh attempt uses a new ID. Invalid/oversized IDs reject before allocation; oversized ID/action echoes are blank to bound response size.
- Handler exceptions are caught, clear the busy lock and cache failure. As in the existing services, this is not a rollback transaction: an exception after a mutation can leave changed authoritative state, so the error explicitly instructs refresh and the same ID cannot mutate again.

## Exact actions and results

| Action | Payload | Success data / validation |
|---|---|---|
| State | nil | Sends existing Event `state`; ack alone is not a profile. Works before movement safety if profile is healthy. |
| Equip | dense array of 1-3 distinct creature ID strings | `{team}`; existing ownership/team rules. Three available slots remain unchanged. |
| Train | creature ID string | `{creature,previousLevel,previousStage,stage,xp=80,cost=15}`; refuge, ownership, level<50 and balance checks. |
| Specialize | `{id,choice}` | `{creature}`; existing level 25/permanent Power/Guard/Vitality rules. |
| Incubate | egg ID string | `{egg}` including `readyAt`; refuge and existing three-incubator/timestamp rules. |
| Hatch | egg ID string | `{creature}` is the exact newly awarded record; refuge and existing timestamp/ownership rules; replay rejects. |
| Travel | destination string (`refuge` or checkpoint ID) | `{destination}`; origin proximity, discovered checkpoint and kingdom gates; no cargo extraction on rejected destination. |
| CollectIncome | nil | `{coins}` is actual settled amount; refuge required. Zero collected is an honest successful settlement. |
| RegisterDefense | nil | Existing service boolean; refuge required, unavailable store returns failure. |
| ChallengeDefense | finite integral UserId (0 allowed) | Existing `{won,rounds,trophies,opponent,practice}` result; refuge, cooldown and target checks remain in Competition. A completed loss is a successful challenge request. |
| Special | `{slot=1..3,ability=1..4?}` | Actual Combat boolean, no invented success. Missing ability retains service default. |
| Dodge | nil | Actual Combat boolean; successful legacy `dodge` event retained. |
| Settings | partial preference table | `{settings}` only after existing profile save succeeds. UI only; valid during character loading. Failed save rejects, marks profile unhealthy and emits save failure. |

Payload strings are nonempty and at most 80 bytes. Unexpected table keys, dictionary/sparse teams, duplicates, wrong types, nonfinite/NaN numbers and unsupported actions reject before dispatch. Settings defaults: `{reducedMotion=false,largeText=false,highContrast=false,simplifiedVFX=false,musicVolume=0.7,sfxVolume=0.8,hints=true}`. Booleans require booleans; volumes require finite numbers in [0,1]. Partial patches merge current validated values/defaults. Old profiles with no settings remain valid and acquire defaults on load; settings persist in the existing schema/store, with no new gameplay data or currency.

## State and battle enrichment

Existing profile state fields remain. `state.ui` contains `atRefuge:boolean`, `nearCheckpoint:boolean`, `serverClock:number`, `cooldowns:table`, `dodgeReadyAt:number`, `settings:table`. Cooldown map keys are `creatureId:ability`; active deadlines and dodge readiness use `workspace:GetServerTimeNow()` domain, converted from existing os.clock calculations. Missing expired cooldown means ready. Dodge readiness preserves the existing .65-second active window plus 3-second recovery. Death preserves existing special cooldowns; disconnect cleans only the leaving player's special records.

New Event `context` sends changed `{atRefuge,nearCheckpoint,serverClock}` at bounded roughly half-second checks; ClientState merges these into an existing profile.ui. This avoids full inventory/profile resends while walking between facilities. Context does not establish profile readiness.

Guardian battle retains prior fields and adds `kingdom`, `resolved`, `objective:boolean`, `objectiveText`, sorted `members={{userId,name}}`, `captureOwned:boolean`. Wild payload includes kingdom/resolved/objective/members/captureOwned with truthful wild values. Wild cancellation now sends Event `battle`, false; removal also clears client battle state. These additions do not implement party membership/invitations beyond actual encounter participants.

## Verification

Used existing official Luau CLI binaries at `C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe` and `luau-compile.exe`; nothing downloaded. RED observed for missing UIProtocol, missing dispatcher, missing shared busy lock, and duplicate-in-flight terminal failure; implementations then passed the corresponding tests.

Executed every present `mountain/tests/*.luau` suite together:

- Rules: 120 checks pass.
- Traversal: 131 checks pass.
- ClientState (other agent): 48 checks pass.
- UIPresentation (other agent): 39 checks pass.
- UIProtocol/UIRequests: 39 checks pass, including malformed/NaN payloads, unknown actions, duplicate paid Train, payload-collision replay, unavailable save, busy/rate limit, bounded cache eviction/high-water protection, token bounds, exceptions, disconnect cleanup and yielding duplicate handling.
- Dispatcher with actual Rules: 25 checks pass, including paid training/level results, insufficient funds, proximity, max level, exact hatch award, early/replayed hatch, full incubators, equip/specialization, income, locked travel and failing combat/defense services.
- `python mountain/tests/run_ui_server.py`: 17 checks pass executing actual Profiles, Store and Combat sources inside local service adapters. Covers settings save/release/reload, invalid/NaN settings, failed persistence health freeze/recovery, legacy profile migration, cooldown conversion/isolation, death versus disconnect cleanup and wild cancellation.
- All 49 current mountain Luau files compile; `git diff --check` passes. Parent may add further files after this count.

`run_ui_server.py` supplies HttpService-style recursive data copying, RunService studio mode and synchronous task adapters; it does not exercise Roblox JSON serialization, network ordering, real DataStore latency, Studio geometry, native controls or live multiplayer. This agent did not run StudioTests or claim any Studio/physical-device acceptance. Final integrated Studio, persistence/network and UI tests remain the parent task's responsibility.
