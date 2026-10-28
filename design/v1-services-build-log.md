# v1 services build log

Worktree `Desktop/climb-collect-v1services`, branch `codex/v1-services` from `7739ddc` (codex/integration-review01 tip = Glassbloom's base). No push, no publish, all product ids 0.

| Date | Phase | Tests | Remaining |
|---|---|---|---|
| 2026-10-28 | 0 Baseline + schema 3 | Baseline before changes: 34/34 CLI suites, 94/94 compile (`python mountain/tools/run_all_tests.py`). After: schema 1→2→3 migration (`V1Schema`), `v1_schema` 34 checks; persistence suite updated to expect schema 3. | `UIPresentation.quest` checks `schema==2` (HUD-owned, requested change). |
| 2026-10-28 | 1 Receipts (E02) | `run_v1_services.py` 39 checks on real Profiles.transact: retry, outage, lost response, rejoin, server change, once-products, pass sync, disabled checkout. | Real MarketplaceService/receipts unverified (no products). |
