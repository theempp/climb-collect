# v1 services — build report (2026-10-28)

Worktree `Desktop/climb-collect-v1services`, branch `codex/v1-services` (from `7739ddc`, the commit Glassbloom branched from). 10 commits, not pushed, not merged. Nothing was published, purchased, created on Creator Hub or saved over an existing place. No HUD/UI source changed. A dry-run merge with `codex/hud-glassbloom` (`git merge-tree`) is clean.

Related: [UI contract](v1-services-ui-contract.md) · [architecture + decisions](v1-services-architecture.md) · [build log](v1-services-build-log.md).

## What is built (server/shared Luau, ~1,950 new lines)

| Scope | Modules | State |
|---|---|---|
| 0 Schema | `V1Schema` (schema 3, `profile.v1`), `V1Wallet`, `V1Config` | Built + tested. 1→2→3 migration; refuses (never clobbers) unknown/future data. |
| E02 Receipts | `Receipts`, `MockMarketplace`, `V1Products` | Built + tested against a **mock** processor. Grant and receipt id commit in one `Profiles.transact`. Every product id is 0; checkout is disabled. |
| C07 Dailies | `Dailies` | Built + tested. Hard 7-day login streak, 3 daily (mountain/home/social) + 1 weekly, one free reroll each, 00:00 UTC / Monday resets, one claim per period across servers. |
| C01–C02 Duo party | `PartyRules`, `PartyService`, `CoopRules`, Combat edits | Built + tested. Max 2, invite/friend/code, ready-check portal, 2-min follow, leader handoff, disconnect recovery. Per-contributor wins/Trial rewards (existing logic, now with a hook) and duo health scaling. |
| C03 Outpost raids | `OutpostRules`, `OutpostSim`, `OutpostService` | Built + tested. 10 fixed slots, 12-piece play-unlocked catalog, 3 defenders, capped vault, async attack via deterministic server sim, 4 h shield, 24 h revenge, 5 attacks/day, bracket + friends matchmaking, seeded bots, raid log + ≤20 s replay, paid reroll/shield hooks, forfeit on abandon. |
| C05–C06 Seasons + recognition | `Seasons`, `Recognition` | Built + tested. Weekly seasons, soft reset, tier rewards once on next join, titles/badges/gallery data. |
| C04 Friend raids, practice | `OutpostService.friendly/practice` | Built + tested. No stakes, no rank; practice gives XP only. |
| Caeloryn 2–4 | `CaelorynAbilities`, Combat edits | Built + tested on the real Combat module: Gravity Choir (control), Constellation Accord (team shield, duo cap), Celestial Dominion (charged beam + 3 star constructs). |
| Wiring | `V1Protocol`, `V1Services`, `V1Boot`, small `Main.server`/`UIRequests` hooks | Compiles; tested end-to-end through the real request processor. **Not run in Studio.** |

## Tests

`python mountain/tools/run_all_tests.py` → **39/39 suites pass, 113/113 sources compile** (baseline before this work: 34/34, 94/94).

| New suite | Checks |
|---|---|
| `v1_schema.luau` | 34 |
| `v1_dailies.luau` | 48 |
| `v1_party.luau` | 48 |
| `v1_outpost_rules.luau` | 77 |
| `run_v1_services.py` (real Profiles/Store, Combat, UIRequests) | 194 |

Changed existing tests: `run_persistence.luau` now expects loads to migrate to schema 3; `service_harness.py` registers the new shared modules and `task.delay`.

## Q01 adversarial pass

My own suite (`06_q01`): 3,000 fuzzed requests through the real gateway (no throws, nothing unearned granted, profile stays valid), claim storms, cross-player isolation, UpdateAsync conflict retries, save outage during raid start, Robux creatures blocked through the gateway, bounded saved data.

An independent review then found 8 issues. All 8 were confirmed and fixed, with regression tests in `07_review_regressions`:
1. One client could spend the server's DataStore budget and starve profile saves. Fixed with per-action cooldowns, a 20 s outpost record cache, and a budget guard that gives profile saves priority.
2. Old vault transfers could re-credit after 200 newer credits pushed them out of the applied ring. Applied outbox entries are now pruned.
3. Revenge could chain forever and skip the attack cap. Revenge attacks now grant no counter-revenge, and revenge has its own cap of 3 per day.
4. Abandoning or leaving dodged the trophy loss, and the client could pre-run plans offline. Abandon, disconnect and expiry now count as a 0★ loss, and the sim seed includes a per-server secret.
5. Loot was reported as granted even when it wasn't saved. Results now carry a `saved` flag. If the pending marker fails to write, the attack is cancelled.
6. The Robux exclusion relied on an untagged field. It now uses an allowlist: no source (legacy) or `source='play'`.
7. Schema-3 quest text in `UIPresentation` is still wrong. That file belongs to the HUD chat, so this one is a request, not a fix.
8. Friendly raids had no limit. They are now capped at 10 per day.

Known residuals (accepted, documented): free reroll, practice and friendly counters change the profile directly. A crash before autosave can restore one of these counters but grants nothing. Loot from a bot raid that is waiting on a failed save is lost only if the server crashes before the next save.

## Only mock / stub / unverified

- **Studio not run.** The only free Studio instance had no place open. Opening a Review06 copy needs GUI clicks next to the HUD chat's live Glassbloom session, so I didn't do it. The packager can't add new ModuleScripts to a baked file. Remaining Studio checks are listed below.
- Receipts: mock processor only, product ids 0, checkout disabled, prices PROPOSED or unset.
- Live-only adapters, untested: outpost/index DataStores, `V1_Rank_<season>` OrderedDataStore, MemoryStore party codes, TeleportService cross-server join, BadgeService (ids 0, calls skipped), `GetFriendsAsync`, DataStore budget guard.
- Balance: every number is PROPOSED (vault, loot, trophies, sim stats, quest pool, season tiers, duo multipliers, Caeloryn values). The sim scales sensibly against the starter outpost (level-1 team 0★, level-50 team 3★) but has had no player test.
- Boost effects: production and XP boosts are granted, stored and capped, but nothing uses them yet. They still need to be hooked into the tycoon settle and XP awards.
- Egg tickets are granted and stored, but nothing redeems them yet. Redemption is excluded from raids until reviewed.

## Remaining Studio checks (in a new copy, e.g. `ClimbCollect.V1Services.Review01.rbxl`)

1. Sync the branch sources and confirm Play starts with `V1_Request/V1_Result/V1_Event` present and no errors.
2. Join: `v1_state` arrives, streak 1, 3 quests. Claim the login reward, strike an egg and confirm `daily` progress.
3. Outpost: state, set slot, set defenders, collect, a bot raid with replay events.
4. Two clients: party invite → ready check → both reach the Blossom entrance; late follow; leave mid-expedition.
5. Duo Guardian fight: health ×1.5, both get respite and XP; Caeloryn abilities 2–4 feel test.
6. Stop/Play persistence is memory-only (PlaceId 0); a hosted test is needed for the real DataStore.

## UI contract summary

Three remotes: `V1_Request` (`id, action, payload`), `V1_Result`, `V1_Event`. Requests use the same `token:seq` ids as UIRequest, with strict payload validation. There are 24 actions (daily, shop, party, outpost, raid, season, title) and 7 push kinds. Shapes and error codes are in the contract. The profile now has `schema=3` and a read-only `profile.v1` subtree.

## Requests for the HUD chat (from the contract)

1. `UIPresentation.quest`: change `profile.schema==2` to `>=2`.
2. Player-XP: if it adds profile fields, make them schema 4 chained after `V1Schema.migrate`, or put them in a namespaced table.
3. D7 coin purchases must not set `ProcessReceipt`. Stamp `source='play'` on earned creatures and `source='robux'` on Robux-egg creatures, and enforce the battle-team rule server-side.
4. Wire the dailies UI, including copy explaining the hard streak and the reset time.
5. Provide all display copy and art (only ids are supplied).
6. Hide the legacy `ChallengeDefense` once `Raid_Friendly` is wired.
7. Show odds + pity before any future paid random item. Warn players before they leave a started raid.

## Recommended integration order

1. Land the HUD branch's P2 server additions first (typed `hud` events), then merge `codex/v1-services`. The dry run is already clean. Rerun `run_all_tests.py`.
2. Apply HUD request 1 (one token) in the same merge.
3. If the player-XP schema is ready, chain it as schema 4 after `V1Schema` and rerun `run_persistence.py` and `run_v1_services.py`.
4. Studio pass in a new copy (checks above). Then wire HUD screens to the contract one area at a time: dailies, outpost/raids, party, seasons/titles, shop.
5. Private hosted alpha for the DataStore, MemoryStore, Teleport and budget-guard behaviour. Only after that, create product ids and enable checkout, once spending is authorized.
