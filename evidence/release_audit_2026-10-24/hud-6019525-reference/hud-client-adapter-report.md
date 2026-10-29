# HUD client adapter and presentation evidence — 2026-10-24

Task 2 implements `mountain/client/UI/ClientState.luau` and `mountain/shared/UIPresentation.luau`. Source and pure CLI evidence establish the adapter behavior; this report makes no Studio/device/performance claim. No world, gameplay values, persistence namespace, Studio instance or platform product changed in this task.

## Client interface

`ClientState.new(remotes)` returns a store with `profile`, `battle` (false when no encounter), `status` (`loading`, `ready`, `error`), `pending`, and `lastResult`. Methods use colon calls:

- `store:subscribe(fn(kind, payload)) -> disconnectFn`: register before the first State request. Every subscriber owns its disconnect function.
- `store:request(action, payload, callback?) -> id?`: a successful send registration returns a GUID session token followed by a monotonically increasing sequence, such as `session-guid:1`; unavailable/duplicate action calls return nil.
- `store:retry(id) -> boolean`: only a timed out unresolved request can retry. It reuses the original ID, action and a private copy of the original payload. Mutating public `pending[id].payload` cannot change the retry.
- `store:now()`: integer server epoch estimate for incubation/recovery, anchored to snapshot `serverNow`.
- `store:clock()`: synchronized workspace clock for specials/dodge. Latest authoritative `ui.serverClock` or context clock provides a fallback.
- `store:destroy()`: cancels outstanding timers, disconnects remote/folder signals, clears listeners and histories; later sends are inert.

An optional second constructor argument supplies scheduler/time/token dependencies for deterministic CLI execution. Normal Roblox clients pass only the remote Folder. This adds no test-only store methods.

`pending[id]` has `{id,action,payload,status,sentAt,attempts,message?}`. `status` is `pending` or `timeout`. The eight-second timeout retains the action lock and the original intent. There are no automatic mutation retries. `lastResult` is a matched authoritative `{id,action,ok,message,data?}`. A late success/rejection reconciles the timeout and clears its lock; duplicate/malformed/mismatched results do not trigger callbacks/reveals. A result never directly changes wallet, creatures or team; these wait for the server snapshot. Completed correlation history is bounded to 64 entries; unresolved entries are bounded by one per permitted action.

Events: `state` (raw profile snapshot), `battle` (snapshot or false), `open`, `toast`, `save`, `pending`, `result`, `timeout`, and the coordinated `context` extension. Context merges authoritative fields into `profile.ui` and emits `context`; it cannot make an absent profile ready. `pending` emits the visible entry on send/timeout, and `{id,action,status='complete'}` when resolved. Callbacks receive the authoritative final result once, including rejection. Timeout has its own event and does not synthesize a final callback.

Missing Event/UIRequest/UIResult exposes an unavailable/error state and never falls back to the uncorrelated legacy mutation remote. Folder ChildAdded/ChildRemoved signals permit delayed remotes and reconnection. First State is requested only after a UI listener is registered. State success alone is insufficient for readiness: an actual profile snapshot is required.

## Presentation interface

- `filterCreatures(profile,query,rarity,sort)` returns a new ordered array of actual creature records without modifying the source array. Search is case insensitive across name/rarity/element/role/id; rarity accepts `All`/nil; sort accepts `Name`, `Level`, `Rarity`, `Team` (case insensitive). Level and rarity sort descending; team sort preserves equipped slot order.
- `creature(c)` returns exactly the planned keys: `name,rarity,element,role,stage,attack,health,xpRequired,abilityNames`. Attack/health come from `Rules.stats`, stages from `Rules.stage`, XP requirements from the existing 40 × level rule (zero at cap). Guardian names come from Catalog abilities; companions show the effect their existing Combat role implements. Unknown records show unknown identity and zero stats.
- `quest(profile)` derives the next undiscovered kingdom entrance, actual Guardian win, or summit objective from `discoveries` and `wins`. It invents no claimable quest rewards.
- `capabilities()` maps feature names to `{status,reason}`. Connected: inventory/training/evolution/eggs/income/travel/combat/coop/defenses/settings. Read-only: profile/quests. Unavailable: sanctuary (Phase 1 bridge), habitats, partyInvites, dailyRewards, rankings, badges, titles, shop. These flags describe service existence, never player eligibility.
- `remaining(deadline,now)` clamps/rounds up finite seconds, returning zero for absent/nonfinite data; `formatTime(seconds)` formats M:SS or H:MM:SS.
- `layout(width,height,largeText)` consumes the actual safe-area content size, returning `compact,phone,sidebarWidth,hubWidth,hubHeight,columns,teamWidth,teamBottom,actionBottom`. At 667 × 339 with default text it returns a 643 × 315 hub, 300-wide centered team, bottom offsets 12/112. This reserves the landscape native touch corners geometrically; actual GUI/native-control overlap remains a Studio acceptance task. Portrait raises center controls above touch regions. Large text reduces grid density.

## Verification

Luau tools were verified in the original checkout: `C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe` and `luau-compile.exe`. Both new suites were first run against empty module tables and failed on the missing expected interface, then passed against implementation. The context extension was separately RED/GREEN (missing authoritative merge).

Fresh combined command:

```powershell
& 'C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe' mountain/tests/rules.luau mountain/tests/traversal.luau mountain/tests/ui_presentation.luau mountain/tests/ui_client_state.luau mountain/tests/ui_protocol.luau mountain/tests/ui_server.luau
& 'C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau-compile.exe' --null mountain/shared/UIPresentation.luau mountain/client/UI/ClientState.luau mountain/tests/ui_presentation.luau mountain/tests/ui_client_state.luau
git diff --check
```

Results: 120 rules checks, 131 traversal checks, 39 presentation checks, 48 adapter checks, 39 protocol/request checks, 17 server action checks; all passed. Four owned Luau files compile; whitespace check passed. An earlier compiler invocation incorrectly supplied `null` as a filename and failed after compiling the sources; corrected `--null` invocation passed.

The adapter harness replaces only Roblox signal/transport/scheduler boundaries. It exercises real adapter code and a real `UIRequests` + `Rules` training transaction: drop the server reply after spending 15 from 100 coins, wait eight seconds, retry the same ID, confirm cached result with balance still 85. Other checks cover malformed/duplicate/wrong-action results, transport exception, late rejection/success, delayed remotes, connection loss/restoration, exact private retry payload, no optimistic wallet changes, context clock merge, callback/subscription cleanup and bounded completed history. Presentation tests include 667×339, 812×339, tablet, desktop and portrait safe-area bounds.

The isolated worktree has no `tools/graphify_refresh/status.py`; its local freshness command failed with file-not-found. The coordinator verified the original repository graph CURRENT at start. That does not index these new isolated modules; current source is authoritative here. No vault note was changed by this delegated task; the coordinator owns milestone/vault/export integration.
