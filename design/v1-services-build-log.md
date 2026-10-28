# v1 services build log

Worktree `Desktop/climb-collect-v1services`, branch `codex/v1-services` from `7739ddc` (codex/integration-review01 tip = Glassbloom's base). No push, no publish, all product ids 0.

| Date | Phase | Tests | Remaining |
|---|---|---|---|
| 2026-10-28 | 0 Baseline + schema 3 | Baseline before changes: 34/34 CLI suites, 94/94 compile (`python mountain/tools/run_all_tests.py`). After: schema 1→2→3 migration (`V1Schema`), `v1_schema` 34 checks; persistence suite updated to expect schema 3. | `UIPresentation.quest` checks `schema==2` (HUD-owned, requested change). |
| 2026-10-28 | 1 Receipts (E02) | `run_v1_services.py` 39 checks on real Profiles.transact: retry, outage, lost response, rejoin, server change, once-products, pass sync, disabled checkout. | Real MarketplaceService/receipts unverified (no products). |
| 2026-10-28 | 2 Dailies (C07) | `v1_dailies` 48 checks: hard streak, 00:00 UTC/Monday resets, deterministic quests, 1 reroll, server-only progress, claim once. | Quest pool/rewards PROPOSED. |
| 2026-10-28 | 3 Duo party + co-op (C01-C02) | `v1_party` 48 checks: max 2, invite/friend/code, ready-check travel, follow window, leader handoff, disconnect, cross-server code teleport (mock). Co-op per-contributor wins/Trials in `05_coop`. | MemoryStore/Teleport adapters live-only, unverified. |
| 2026-10-28 | 4 Outpost raids (C03) | `v1_outpost_rules` 77 checks; `03_outposts` on real Profiles: locks, vault outbox, loot caps, shields, revenge, daily cap, replay protection, crash recovery, lock expiry. Run authority = deterministic server sim (architecture A1). | Balance untested; leaderboard/DataStore live-only. |
| 2026-10-28 | 5-6 Seasons, recognition, friend raids (C04-C06) | Season rollover/soft reset/rewards once on next join; titles/badges (ids 0); friendly raid no stakes; practice XP only. | Badge ids 0 (stubs); display copy is HUD's. |
| 2026-10-28 | 7 Caeloryn 2-4 + duo scaling | `05_coop` on real Combat: Gravity Choir control, Constellation Accord team shield (duo cap), Celestial Dominion beam + constructs; duo health ×1.5/×1.45. | Tuning PROPOSED; no Studio feel test. |
| 2026-10-28 | Integration | `V1Boot` + small `Main.server` hooks; `04_orchestrator` end-to-end through UIRequests + V1Protocol. | **No Studio run**: only free Studio instance had no place open; opening one needs GUI next to the HUD chat's live session. Packager cannot add new modules to a baked file. |
