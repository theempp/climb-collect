# Approved tycoon redesign: implementation contract

User Q1–Q11 on October 24, 2026 is authority. Prior chat exposes option letters but not its assistant design text. This implementation preserves the local Review06 integration and does not publish or replace the user's open places.

## Audit and approach

GitHub main 23ee172 is world-generation history. HUD branch 6019525 has the relevant six-kingdom gameplay. Local integration worktree f520 adds eight owned plots and newer mountain source; its source was copied without modifying it, SHA256 recorded in tycoon-baseline-manifest.json, and committed separately. Baseline: 1,102 CLI checks pass. Review06 is the baked geometry source. Profiles use MountainEmpire_FirstDraft_v1, schema 1, coins, creatures, team, cargo and eggs. Store supports UpdateAsync, budget waits, retries via Profiles, and Studio memory fault injection. Current passive income pays for all creatures, with no habitat or production storage. HUD has unavailable habitat/build cards. Sanctuary has 180x220 outer plots; the requested 110x120 tycoon grid fits inside, preserving lodge and spawn.

Extend the existing profile with a versioned tycoon subrecord and existing request protocol. Avoid a parallel currency/store or rewriting mountain gameplay. Use the baked integration's plot transforms, not new global coordinates. Source-only builds still require baked Sanctuary geometry. Do not import or modify terrain. Changes to passive income are intentional; combat, hatchable eggs, travel, six kingdoms and eight-slot allocator are preserved.

## Builder defaults (provisional balancing, not new approved design)

- Hybrid production: timed regular eggs plus a predictable bonus-value egg every tenth production. All stored eggs have integer count and value, separate from hatchable eggs/cargo. No random paid odds.
- Two unlocked habitats, eight maximum. One distinct owned creature per habitat. Production assignments are independent of combat team: assignment never removes or equips a companion. Habitat kingdom matching gives 5%; same-kingdom neighbors give up to 10%. Rarity affects rate/value modestly. Exact rate/cost tables live in TycoonConfig and require economy playtesting.
- Batch collect from one or all habitats into a finite upgradeable bag; manual banking on owned plot. Bank/upgrade transitions never yield. Currency and egg removal save together. No streaks or prestige.
- Offline cap eight hours and per-habitat storage. Offline automation deliberately does not bank or drain storage, so cap cannot be bypassed. Timestamp advances even when full; fractional progress below one egg retained, blocked whole production discarded. Existing stored eggs are never expired or clamped away. No offline award on first migration. Existing coins remain unchanged; old unpaid passive income settles once before migration.
- Linear paths: habitat slots, each habitat level, production, storage, egg bag, banking, automation. Automation sequence: conveyor routing, processor (+5% on newly produced egg value using saved fractional carry), sorter (high value collection priority), collectors, automatic banking. Advanced automation requires production/storage/banking progression. Banking bonus maximum 10%; processor maximum 5%.
- Cosmetic choices use existing kingdom palette colors, no new external asset IDs. Conveyors are client-only pooled anchored visual eggs, never physical economy objects. Reduced VFX/motion, distance culling and capped egg count.
- Hub exposes totals/capacities, rates, per-habitat assign/unassign/swap via owned roster, type/level, costs/prerequisites, automation and cosmetics. Existing training/incubation stays available.

## Safety and acceptance

Validate all remote payloads, ownership, integer slots/levels, price from server config, living safe character and owned-plot proximity. Reuse correlated request deduplication and rate limits. Validate persisted tycoon records fail-closed (never silently replace malformed records); migration is idempotent. UpdateAsync snapshots persist coins, eggs and timestamp atomically, with session ownership and lease validity. Test full storage, future/old timestamps, frequent settlement, ownership, swaps, replay, upgrades, offline limits, DataStore failures and rejoin. No live DataStore or physical-device performance claim without corresponding tests.
