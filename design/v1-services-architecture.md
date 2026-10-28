# v1 services — architecture and decision record (2026-10-28)

Scope: server/shared logic for E02, C01–C07, Caeloryn 2–4 and Q01. LOCKED rules come from `Desktop/climb&collect/design/v1-big-scope-design-decisions-2026-10-28.md`; every number is PROPOSED in `mountain/shared/V1Config.luau`.

## Decisions made in this build (routine, recorded here)

| # | Decision | Why |
|---|---|---|
| A1 | **Raid run authority = deterministic server simulation** (`OutpostSim`). The attacker submits a plan (creature per lane, optional ability second); the server simulates with a seed derived from the server-issued attack id, commits the outcome, and returns ≤60 replay events (≤20 s). | Async raids against offline snapshots need no live defender; nothing the client reports is trusted; replays come for free; fully CLI-testable. Real-time server-validated movement was rejected: costly, needs network tuning and still trusts more client input. |
| A2 | Base `codex/v1-services` on `7739ddc`, the commit Glassbloom branched from. | Smallest merge surface with the HUD branch. |
| A3 | Profile schema **3**: all v1 state under `profile.v1`; `V1Schema.migrate` runs after `RunRules.migrate`. Refuses (never clobbers) a profile with an unknown `v1` field or a future schema. | Older saves keep loading; one namespace limits merge conflicts. |
| A4 | Another player's **profile is never written**. Cross-player state lives in a separate per-player outpost record (`'o'..UserId`, DataStore `MountainEmpire_Outposts_v1`), changed only by atomic `update` with an attack lock (`lock.id`, 180 s) and idempotent attack ids. | Session-locked profiles cannot be safely written by another server. |
| A5 | **Outbox pattern** for credits into a profile (vault collect, raid loot, season rewards, paid-shield token use): the source record keeps the event; the profile applies it in `Profiles.transact` with a stable id remembered in `v1.applied` (ring 200). Reconciled on join and after each action. | Exactly-once across retries, crashes and server changes without two-store transactions. |
| A6 | Raid loot is credited **before** the attacker's pending marker clears; the target's `results` ring is the source of truth. | A failed save is retried instead of lost. |
| A7 | Vault = 10% of production rate as a **bonus** pool, capped at 4 h of that fill (150–2,500). The main wallet and production are untouched. Loot 20/35/50% by stars, daily loot cap 1,500. | LOCKED "capped vault coin only, never main wallet". |
| A8 | Shield 4 h after any completed attack; paid shield +4 h, one per UTC day, remaining total ≤ 8 h. Attacking does **not** break your shield. | Avoids punishing paid shields; PROPOSED. |
| A9 | 5 attacks/UTC day counted at start; revenge (24 h, single use) does not count; 3 free rerolls/day, then paid reroll tokens. | PROPOSED; no free reroll felt too harsh. |
| A10 | Matchmaking: trophy buckets of 100 (own ±2) from an index store, active within 14 days, plus friends; shielded/locked skipped; seeded bot outposts otherwise (half trophies, fixed small loot). | LOCKED bracket + friends + bots. |
| A11 | Weekly season = Monday 00:00 UTC; only played seasons earn a reward entry; soft reset ×0.5; rewards granted once on next join. | LOCKED; numbers PROPOSED. |
| A12 | Dailies: deterministic per (UserId, UTC day) quest pick → same quests on any server; 1 mountain + 1 home + 1 social; progress only from server hooks; claims are transactions with period ids. | LOCKED one reset, one claim per period. |
| A13 | Party: one-server registry; cross-server code join via MemoryStore directory + TeleportService (live-only adapters). Departed party re-opens only when every traveler is home. | Duo seated together; keeps the 2-min follow window. |
| A14 | Duo scaling: 2nd member ×1.5 Guardian / ×1.45 Trial health; strangers beyond two keep the legacy additive join health. | Tuning for 1–2 players (OPEN risk in decisions doc). |
| A15 | `ProcessReceipt` is owned by `V1Boot`. Unknown or id-0 products return `NotProcessedYet` (never granted). Checkout disabled: prompts are never sent. | E02 hard limits. |

## Data ownership

| Data | Where | Writer |
|---|---|---|
| Wallet, dailies, raid counters, receipts, titles | `profile.v1` (session-locked) | owning server; rewards via `Profiles.transact` |
| Outpost snapshot, vault, shield, trophies, season, log, revenge, results, transfers | outpost record `o<UserId>` | owner (own updates) or attacker (under lock, idempotent) |
| Matchmaking index | `MountainEmpire_OutpostIndex_v1` buckets `b<n>` | any server, bounded lists (60) |
| Leaderboard | `V1_Rank_<season>` OrderedDataStore | live only |
| Party | server memory; codes in MemoryStore (live) | owning server |
