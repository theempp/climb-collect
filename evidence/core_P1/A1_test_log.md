# Run 1 · A1 Data + persistence — test log (2026-10-20)

Store used: **in-memory mock** (`Store.memory`, values round-trip through JSON like a DataStore). The place is unpublished (`PlaceId = 0`), so **real DataStore behavior is UNVERIFIED**; `Store.datastore` is written against the documented UpdateAsync/GetAsync API but has never run.

## 1. Scripted suite (`ServerScriptService.CC_CoreServer.Tests.runA1()`, Server datamodel, Studio Play Solo)
Two `Profile` services sharing one backend stand in for two game servers; `Clock.offset` simulates time away.
```
A1 persistence tests: 8 pass, 0 fail (store = in-memory mock; real DataStore UNVERIFIED)
[PASS] rejoin keeps bank (same server and another server)
    same server: bank 2->2 coins 11->11 xp 180->180 heartstones 1
    other server: bank 2 coins 11
[PASS] double deposit yields once
    r1 creatures 2 coins 4 | r2 dup true creatures 0 | r3 creatures 0
    concurrent: 3 + 0 = 3 (expected 3); bank 5
[PASS] store failure: load refused safely, data untouched, retries on save
    load while down -> session false reason store; stored bank 1 -> 1
    release with 2 transient failures -> true (update calls 9, failed 5)
[PASS] Heartstone completes after a simulated offline gap
    gap 100 s: 0 ripe, 200 s left | gap 400 s: 1 ripe -> stub_uncommon_1 (Uncommon); second pass 0; heartstones left 0
[PASS] session lock: live lock blocks a second server, release unblocks
    second server while locked -> locked
[PASS] session lock: stale lock is taken over; the old server can't overwrite
    B stole lock true; A save -> false (lost); stored bank 2 (expected 2: A's 1st + B's)
[PASS] migration + sanitize keep valid data and quarantine junk
    version 1 coins 0 xp 120 level 2 bank 1 quarantine 3 heartstones 0
[PASS] UpdateAsync retry semantics: transform runs twice, result applied once
    bank 1, lock nil, saves 1
```

## 2. Live session (the real Play Solo player, through `ServerStorage.CC_DevBridge`, Studio-only)
"Rejoin" = the real leave path (`release`, pending-release on failure) followed by the real join path (`loadLoop`), inside one Play Solo session; a real second join from a new client is not possible in Play Solo.
```
1 start: save=ok session=35c7a41a bank=0 hs=0 coins=0 xp=0 pack=0/4
  deposit -> creatures 2 heartstones 1 coins 11
2 banked: save=ok session=35c7a41a bank=2 hs=1 coins=11 xp=180 pack=0/5
  rejoin (release ok) -> true
3 after rejoin: save=ok session=d57a2091 bank=2 hs=1 coins=11 xp=180 pack=0/5
  same tx twice: first 1 creature(s), second 0 (dup true)
4 after double: save=ok session=d57a2091 bank=3 hs=1 coins=14 xp=230 pack=0/5
  rejoin with store down on join -> released true
  'unavailable' shown after 3.1 s
  deposit while down -> ok false reason unavailable
5 store down: save=unavailable session=nil bank=nil hs=nil coins=nil xp=nil pack=1/4
store restored: 'ok' after 1.6 s (retry cycle 15 s)
6 reconnected: save=ok session=294ffd0c bank=3 hs=1 coins=14 pack=1/5 clock+0
  deposit of the item kept while down -> creatures 1
7 banked: save=ok session=294ffd0c bank=4 hs=1 coins=15 pack=0/5 clock+0
  rejoin after 400 s offline -> released true
8 after offline gap: save=ok session=f696dbac bank=5 hs=0 coins=15 pack=0/5 clock+400
```
Screens: `A1_01_store_failure_safe_message.jpg` (persistent banner + one toast; the backpack item stays), `A1_02_reconnect_and_offline_ripen.jpg` ("Saving reconnected", the kept item banked, "1 Heartstone ripened while you were away"). Rejected: `91_rejected_store_failure_ui_overlap.jpg` (first UI: toasts overflowed a narrow window and covered the HUD; fixed with a left column + bottom toasts + fixed text sizes + dedupe).

## Acceptance (brief §2 A1)
| Check | Result |
|---|---|
| Rejoin test keeps bank | PASS (suite + live; mock store) |
| Double-deposit yields once | PASS (same tx replay, second press, forged re-add of the same uids, concurrent deposits) |
| DataStore failure path shows a safe message | PASS (mock failure; banner "Saving paused…", deposit refused, items kept, auto-reconnect) |
| Heartstone completes after a simulated offline gap | PASS (Clock offset 400 s > 300 s Common ripen; idempotent second pass) |
| Real DataStore | **UNVERIFIED** (needs a published place + Studio API access or a live server) |

## Defect found and fixed during A1
- The dev "rejoin" first bypassed the real leave path: a failed release left this server blocked by its own lock for up to `lockTTL`. Fixed by routing dev rejoins through the real `release`/`loadLoop` (pending-release reuse on the same server).
- Load retry tightened: 2 quick attempts per call, then the safe banner while retrying every 15 s (before: ~31 s of "Loading" before any message).

## Update after the adversarial review
Suite extended to 12 cases (4 regression tests for the review fixes): **12 pass, 0 fail**. Live flow re-run on the patched service: rejoin keeps bank, same-tx double deposit yields once, store-down join shows the banner (3.1 s) and refuses deposits, store back → ok (15.1 s, next retry), offline 400 s → Heartstone ripened. Details: `A1_review.md`.
