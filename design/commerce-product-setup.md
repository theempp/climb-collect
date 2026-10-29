# Product setup and release checklist — not performed

Local implementation is approved. Product creation, publication, access changes, real purchases and release need separate authorization. No IDs have been invented; every platformId remains 0. Configure only verified IDs for the intended universe in `src/core/shared/CommerceConfig.luau` and sync the exact reviewed source.

| Stable offer ID | Roblox type | Intended default Robux | Benefit |
|---|---|---:|---|
| upgrade0 | Pass | 3 | 2× total earned coins |
| upgrade1 | Pass | 9 | 4× total earned coins |
| upgrade2 | Pass | 19 | 6× total earned coins |
| upgrade3 | Pass | 39 | 8× total earned coins |
| upgrade4 | Pass | 79 | 10× total earned coins |
| upgrade5 | Pass | 149 | 12× total earned coins |
| bundle | Pass | 19 | Lantern skin + camp banner |
| lantern | Pass | 19 | Lantern skin |
| banner | Pass | 19 | Camp banner |
| flag | Pass | 3 | Trail pennant |
| trail | Pass | 5 | Sparkle trail |
| coins100 | Developer product | 9 | Exactly 100 Cairn Coins |
| coins350 | Developer product | 25 | Exactly 350 Cairn Coins |
| coins900 | Developer product | 59 | Exactly 900 Cairn Coins |
| coins2000 | Developer product | 119 | Exactly 2,000 Cairn Coins |

The 1,500-coin lamp decoration has no Roblox listing. Training and functional home upgrades retain existing earned-currency costs.

Before enabling sales in a separately authorized test destination:

1. Verify universe, all 11 pass IDs and four developer-product IDs, ownership, sale status and intended default prices. Never substitute draft prices for unavailable Roblox metadata.
2. Verify actual player-visible prices, regional/pricing variations, native prompts, cancellation/reopen, purchase restrictions and any native Robux flow. Savings and pack-value labels are recomputed; the game never estimates a Robux balance or exact-shortfall top-up.
3. Test real server-side pass ownership delays, reconnect after success, receipt retries/concurrency, ambiguous DataStore writes, player departure/server shutdown, duplicate delivery after 96 unrelated transactions, and recoverable reveals. Validate two real clients, separate balances and a visitor's inability to install/equip a host's lamp.
4. Retest external upper-tier ownership: preserve pending ownership until contiguous prerequisites exist. Bundle/standalone benefits are unioned. The owner accepted the documented external-pass limitation: external Roblox checkout cannot enforce cross-pass prerequisites or prevent overlapping bundle charges. Unlist external storefront offers where supported and verify behavior; direct purchase paths remain a limitation. Do not claim platform-wide overlap-charge prevention.
5. Measure expected paid-ledger and pending-reveal growth against the 3.5 MB profile budget. Paid IDs must never be evicted. Require a tested atomic archival design before projected growth approaches the budget; separate non-atomic datastore writes are insufficient.
6. Test on actual phones/controllers and published-test multiplayer, including native cancellation while moving, modal focus return, safe traversal deferral, cosmetic restoration and reduced effects. Preserve terrain, protected creature work and the original concepts.

No release approval is implied by the local test results. The implementation handoff lists precisely which tests used doubles and which used one local player.
