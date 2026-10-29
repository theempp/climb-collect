# Live-ops tools plan (2026-10-28)

Design only. No game, Studio, Creator Hub or Robux change. Grep of `climb-collect-integration` finds no remote config, feature flags, kill switches or `MessagingService`; only `BindToClose` save handlers (`CC_CoreService.server.luau:450`, `mountain/server/Main.server.luau:454`). So all of this is new. Pairs with the [safety plan](safety-compliance-plan-2026-10-28.md) (kill switches) and the later funnels work.

## Goals
1. Turn a broken or risky feature off in under a minute, without republishing.
2. Tune numbers (rewards, ladder values, event bonuses) without a code push.
3. Tell players what is happening (maintenance, events) without free-text input from players.
4. Know when something is wrong before players tell us.

## 1. LiveConfig (one server module, the single source of truth)
- A server-only `LiveConfig` module holds the current flags and tunables. Everything else reads from it; no feature checks its own ad-hoc switch.
- **Storage:** one versioned key in a DataStore (config JSON, with a `version` number). Servers poll every 60 s and keep the last good copy if a fetch fails. Defaults in code are the safe fallback.
- **Instant push:** `MessagingService` broadcast tells running servers to reload at once (poll covers missed messages).
- **Validation:** every value range-checked on load (a typo cannot set coins to 1e9); an invalid config is rejected and the last good one stays.
- **Clients** receive only the flags they need through a replicated read-only folder or remote.

## 2. Flags (kill switches), PROPOSED list
| Flag | Turns off |
|---|---|
| `shop.enabled` | whole Robux shop (all prompts) |
| `shop.ladders` | coin and hatch ladders |
| `shop.eggs` | paid eggs and egg skip |
| `shop.cosmetics` | cosmetic purchases |
| `events.enabled` | live events and bonuses |
| `dailies.enabled` | login streak and quests |
| `season.enabled` | weekly season rewards |
| `party.enabled` | duo parties |
| `mountain.<kingdom>` | enter a specific kingdom (if a bug appears) |
| `guardian.<id>` | a single Guardian fight |
| `homebase.tiers` | tier upgrades |

Rules: a flag off must fail safely (no half-charged purchase, no lost progress); a disabled kingdom lets players leave, and returns anyone inside to the sanctuary. Never remove already-paid ladder or cosmetic benefits when only the *purchase* is off.

## 3. Tunables (server-side numbers, no republish)
Ladder multipliers and prices stay in code/product definitions, but these live in config: global coin and XP rate multiplier, hatch time floor (60 s), event multipliers (weekend bonus), daily reward values, global combined-multiplier cap, hourly income cap, per-hour purchase confirmation thresholds. Prices are tied to products, so changing them still needs a product edit.

## 4. Player-facing messages (preset only, no typing)
- A **banner system** with fixed message types: maintenance in X minutes, event live, new content, known issue. Text comes from config by key, translated/written by the owner, not typed by players.
- **Soft shutdown** for updates: Roblox migrates players to new servers when you publish; warn them with the banner first and save before closing (`BindToClose` already saves).

## 5. Feedback and bug button (no free text)
- Settings gets "Report a problem" with **preset categories** (cannot reach a kingdom, lost an egg, purchase issue, graphics/performance, other). Each tap logs one custom analytics event and attaches non-personal context (area, device class, build version).
- Players are pointed to Roblox's own report button for abuse. Do not cover or replace it.
- Optional later: a short preset "How was your session?" rating after a few sessions (events, no text).

## 6. Owner-side controls
Pick one (decision below):
- **A. Open Cloud script (Recommended):** a small local script run by the owner that writes the config key (API key in an env var, never in chat or files). Fast, no admin surface inside the game.
- **B. In-game admin panel** for the owner's UserId only. Convenient on phone but it is an exploit target; needs strict server checks.
Both write a change log (who, when, old/new) so a bad edit can be reverted by re-applying the previous version.

## 7. Monitoring and alerts
- Server error counts and script exceptions aggregated into custom analytics events (counts only, no text).
- Purchase health: purchase attempted vs. granted (should match). A gap raises a flag-check alert.
- Data health: profile save failures, retry counts, session-lock conflicts.
- Performance by device tier once the XR-class test exists.
- These feed the funnels step, which comes last.

## 8. Incident runbook (one page, to write with the owner)
1. Detect: dashboard anomaly, support report, or owner notices.
2. Contain: flip the relevant flag (shop first if money is involved).
3. Communicate: banner message.
4. Fix and verify on a private place, then publish.
5. Restore: re-enable flag; if data was affected, restore profiles from backup/restore tooling.
6. Record what happened in the vault Decisions/Open Questions.

## 9. Build order (after the merge settles)
1. `LiveConfig` + validation + defaults, with tests.
2. Wire kill switches to the shop first, then events, dailies, kingdoms.
3. Banner system and the problem-report button (HUD chat owns the Settings screen; coordinate).
4. Owner script (option A), change log.
5. Alerts (error counts, purchase health) alongside the funnels work.
6. Dry run on a private place: flip every flag, confirm safe behaviour.

## Open
1. Option A (script) or B (in-game panel) for owner controls. Recommendation: A.
2. Which flags matter most for launch day (suggest shop, ladders, eggs, each kingdom).
3. Exact banner message set and who writes them (owner).
4. Confirm DataStore budget use for config polling stays small (1 read/min/server is fine; verify against current limits).
