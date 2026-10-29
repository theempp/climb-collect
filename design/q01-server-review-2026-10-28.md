# Q01 server adversarial review, 2026-10-28

Target: `Desktop/climb-collect-integration`, branch `codex/hud-glassbloom`. Read-only static review. Nothing was run, edited, staged or opened in Studio.

## Scope found

The live server is `mountain/server/*` plus `mountain/shared/*` (mapped by `mountain.project.json`). The `src/` tree is the older Fairground/CC_Core place. It is not in the project file, and it is missing Store, Bank, Inventory, Claims, Nests and Gear, so I did not treat it as the shipping server.

Client-reachable entry points in `mountain/`:
- `MountainRemotes.UIRequest` (`Main.server.luau:342`): correlated request ids, `UIRequests.process` + `UIProtocol.validate`, per-player ~8/s throttle (`minInterval .12`), result cache by id.
- `MountainRemotes.Request` (legacy, `Main.server.luau:347`): same dispatcher, `legacy:1` id. `Buy` and `Skin` are blocked on it (`UIProtocol.luau:89-90`).
- `MountainRemotes.SprintRequest` (`Movement.luau:38`): boolean only.
- `ProximityPromptService.PromptTriggered` (`Main.server.luau:287, 309`): server re-checks distance.
- No RemoteFunctions. No `ProcessReceipt`. HUD events (`hud`, `xp`) are server-to-client only.

Verified good (no finding):
- Prices, rewards and egg odds are all server-side. `Buy` takes only `{item, receipt}`; price and odds come from `ShopRules.catalog` and server `Random` (`UIRequests.luau:167-173`, `ShopRules.luau:41-65`).
- Coin purchase is one `P.transact` draft that commits atomically with the receipt. Coins can't go negative and the egg cap is checked before debit.
- Egg securing is idempotent through `securedRunIds` (`RunRules.luau:64-75`), and `P.transact` replays the same write id (`Profiles.luau:88-93`).
- Robux shop entries are `currency='robux', productId=0`, and `ShopRules.buy` refuses them (`ShopRules.luau:46`).
- Payload validation is strict for every action in `UIProtocol.validate`.
- Hatch and incubate time uses server `os.time()`.
- Player XP is derived from durable flags and capped.

## Findings

### F1. HIGH. Client-driven DataStore write/read amplification starves the whole server
Any client can spam actions that cause a DataStore call each time. The only limit is the 0.12 s UI interval. There is no per-player save throttle and no dedupe.
- `Settings` with an unchanged valid patch calls `P.setSettings`, which calls `P.save` every time (`UIRequests.luau:136-142`, `Profiles.luau:162-168`). Each call is one UpdateAsync.
- `Bat equip` of the already-equipped bat succeeds and calls `context.save` (`UIRequests.luau:144-151`). It spawns an unbounded queue of `P.save` threads (`Main.server.luau:322`).
- `RegisterDefense` has no cooldown. Each call is an UpdateAsync on the defense store (`Competition.luau:13-16`, `UIRequests.luau:289-295`).
- `ChallengeDefense` with a bad target does a `GetAsync` and returns before `competitionAt` is set (`Competition.luau:22-32`, cooldown only set at `:40`). So random UserIds spam reads unthrottled.
- `Store.luau:102-111` waits at most 10 s for budget and then fires anyway, so calls throttle and fail.

Scenario: one exploiter sends `Settings` or `RegisterDefense` in a loop. DataStore budgets are per server (roughly 60 + 10 per player per minute from memory; not verified here). Other players' autosaves, shop commits and secure-exit commits then fail (`commitPending` gives up after 3 attempts). Their profiles go `healthy=false`, which shows "Saving paused" and freezes progress actions. New joiners are kicked because `P.load` makes one attempt (`Main.server.luau:153-154`).

Also, a queued `P.save` that waits more than 12 s sets `s.healthy=false` (`Profiles.luau:134`). Flooding can therefore soft-lock the flooder's own profile until the next autosave.

Fix direction: skip the save when a setting or equip doesn't change anything. Add a per-player save debounce of a few seconds. Add a cooldown on `RegisterDefense`. Set the `ChallengeDefense` cooldown before any read. Coalesce `context.save` into a single dirty flag.

### F2. MEDIUM. Same-server fast rejoin can clear the lock and permanently block that session's saves
The lock owner is one constant per server: `game.JobId..GUID` (`Profiles.luau:172`). `P.load` accepts a lock whose owner equals the server (`:62`). `PlayerRemoving` starts `P.save(player, true)` (`Main.server.luau:167`), which writes `lock=nil` (`Profiles.luau:150`).

Scenario: the player leaves and rejoins this server while the release write is still queued. The causes are an autosave busy-wait of up to 12 s, retry waits of 1 s and 2 s, or a slow DataStore. The new `P.load` sees owner==server and takes the lock, loading the pre-release profile. Then the old release write lands: it overwrites the profile with the older snapshot and sets `lock=nil`. Every later save of the new session hits `not old.lock → return nil` (`Profiles.luau:148`), so it can never save again. Progress made in that session is lost, and the profile is frozen after the first failed autosave. I reasoned this from the code and did not reproduce it.

Fix direction: make the lock owner per session (JobId + UserId + join counter), or have `join` wait for the previous session's release for the same UserId.

### F3. MEDIUM. Movement and fall protection trusts client-replicated state
`Main.server.luau:399-413`:
- The teleport-back check only fires when a move exceeds `max(22, elapsed*75)` per ~0.2 s tick. That is ~110 studs/s sustained, with no vertical or air-time bound.
- Fall loss uses `Humanoid.FloorMaterial` (`:404`), which the owning client reports. A client that reports grounded at all times resets `fallTop` every tick and avoids the 32-stud serious-fall egg loss (`RaidConfig seriousFall`).

Scenario: a flying or no-clip exploiter reaches any nest, strikes it (server `near` check passes because the position is the exploiter's), and carries a creature straight to a sanctuary exit. Difficulty and fall risk are bypassed. Economy impact is bounded by egg rest, per-day XP caps and the summit one-time reward. Standard Roblox ownership limits apply, but this is the main gameplay-integrity gap.

### F4. MEDIUM. A failed commit leaves the player frozen with a retry storm and no terminal "lost" state
`commitPending` retries 3 times and treats every failure alike, including a lost lock (`Profiles.luau:82-106`). Unlike the older `CC_Core`, there is no "lost" outcome, kick or release. While `s.pending` is set, `P.get` returns nil (`:79`) for all actions.

If the lease is lost (another server took over after 180 s, or F2 happened), the pending draft never commits. The player stays frozen but connected. `EggRaids.tick` re-runs `service.exit` every `saveRetrySeconds` (5 s) (`EggRaids.luau:130-134`). Each retry makes 3 UpdateAsync calls plus 3 s of waits. That adds to F1 load for as long as the player stays. Autosave also retries (`Main.server.luau:446-453`).

No duplication results, because the draft is discarded. The effect is availability plus extra DataStore traffic.

### F5. MEDIUM (latent, release-blocker before any product id is set). No server-side Robux receipt path
`W.buy` calls `PromptProductPurchase` and then runs `fn()` immediately (`Widgets.luau:750`), whatever the purchase outcome. `grep` finds no `ProcessReceipt`, game pass check or other grant path anywhere. Today it is inert: every Robux button is the disabled ghost (`productId=0`), and `ShopRules.buy` refuses Robux items (`ShopRules.luau:46`).

When a real `productId` is set, a player would be charged and receive nothing. If someone later wires a grant to the client callback, it would be free. A server `ProcessReceipt` is required before enabling any product, using `PurchaseId` idempotency and the same `P.transact` receipt pattern.

### F6. LOW. Competition result can be lost to a concurrent commit
`Competition.challenge` yields in `db:read` (`Competition.luau:30`) while holding `p`. If a secure-exit commit starts while it waits, `commitPending` later does `table.clear(s.p)` and refills it from a draft copied earlier (`Profiles.luau:100`). That erases the trophies, coins and cooldown set in between. The client is still told it won. It needs near-simultaneous refuge challenge and exit. It is the only in-place mutator I found that yields between reading and writing.

### F7. LOW. Load makes a single attempt and kicks
`Main.server.luau:153-154` kicks on any `P.load` failure, including a lock still held by the server a player just left (quick teleport or reconnect). There is no retry loop. The older `CC_Core` retried.

### F8. LOW. Request-driven server work with no cap
`Equip` rebuilds up to 3 companion models in the world per request (`UIRequests.luau:226-230`, `Main.server.luau:73-85`). `State` re-publishes the full profile each time. Both are bounded only by the 8/s throttle.

### Design notes (not vulnerabilities)
- Guardian damage is automatic for anyone in the arena. Trial "mastery" counts any non-hit pattern as a dodge (`Combat.luau:150-151`), so an idle player can pass.
- Eggs re-arm 18 s after securing, so creature farming is unbounded. Only XP is capped.
- `PutDown` replies "Creature safely in your collection" while only clearing visuals. No grant.
- A failing server-side `valid()` freezes a profile forever with no repair path.

## Not covered
- The `src/` tree (CC_CoreService, CC_CheckpointService, Camps, Home, Training, Traversal, Commerce*, PublicProfile and others). Only the `fellEv` handler was skimmed; it measures drops on the server. Bank, Inventory, Claims, Nests and the older Gear shop aren't in this worktree.
- All client code: `Widgets`, `Shop.luau`, `HudState`, `Controller`. I read only the receipt generation and retry logic in `ClientState` and `Shop.luau` (one GUID per tap, same id on retry, which is correct).
- The baked `.rbxl` files. The scripts embedded in `outputs/ClimbCollect.Glassbloom.Review01.rbxl` may differ from `mountain/` source.
- World, art and terrain code, Tycoon balance and economy tuning, `Bats` hit geometry, and the tests and tools folders.
- Any runtime behavior. The DataStore budget figures come from memory of the Roblox docs and are not checked. F2 and F6 are traced by reading the code, not reproduced.
