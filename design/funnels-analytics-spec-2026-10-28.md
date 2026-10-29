# Funnels + analytics spec (2026-10-28)

Design only. No code, Studio or Creator Hub change. **Roblox `AnalyticsService` only** (owner-approved): no external backend, no personal data, no player-typed text (preset names only). Build after the merge settles; hook calls land in files other chats own, so they go in last.

## Platform limits (from Roblox docs/DevForum; verify on Creator Hub before coding)
- Custom events: up to **100** distinct events; up to **3 custom fields**, **8,000** value combinations across them per experience, then grouped as "Other".
- Economy events: up to **20** transaction types per experience.
- Funnels: up to **10** funnel tabs; one-time funnels exist for once-per-user conversions.
- Charts can lag **up to 24 h**; the **View Events** button on the Economy, Funnel and Custom pages shows recent events near real time (use it to test).
- Events roll off after 90 days with no data. Reserved field names (currency, funnel_name, event_name) can be dropped.
- Global rate limit **120 + 20 x CCU requests/min** (verified on [event types](https://create.roblox.com/docs/production/analytics/event-types)); limits reset daily. Batch and aggregate, never log per frame. Economy: 10 resource types, transactionType values beyond 20 and itemSku beyond 100 go to "Other". Funnels: 10, up to 100 steps; only the 10 most recent funnelSessionIds per user per funnel are tracked; steps expire after 180 days idle.
- Signatures (verified, [AnalyticsService](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService)):
  `LogOnboardingFunnelStepEvent(player, step, stepName, customFields?)`;
  `LogFunnelStepEvent(player, funnelName, funnelSessionId, step, stepName, customFields?)`;
  `LogProgressionStartEvent/CompleteEvent/FailEvent(player, pathName, level, levelName, customFields?)`;
  `LogCustomEvent(player, eventName, value?, customFields?)`;
  `LogEconomyEvent(player, flowType, currencyType, amount, endingBalance, transactionType, itemSku, customFields?)`.
  F1 uses the onboarding call; F8 kingdom progression can use progression events instead of a funnel.

## Questions the data must answer
1. **Where do players leave, and why?** Onboarding drop-off, last area/action before quitting, deaths/falls per section, device class.
2. **How long do they play?** Session length, sessions per day, time to first meaningful action (built-in dashboard plus our `session_end`).
3. **What keeps them playing?** Which loop drives each session (climb, hatch, home base, shop, dailies), return after streak events, first-week milestones.
4. **Is money healthy?** Shop views -> purchases, ladder step-ups, what players buy first, coin sources vs sinks.
5. **Is the game healthy?** Errors, save failures, purchase mismatches, performance by device.

Built in already (no code): retention D1/D7/D30, playtime, sessions, DAU, concurrents, device/country, crash rate.

## Rules
- One `Analytics` module (server and client halves) wrapping every call: pcall, rate-limited, batched, safe if `AnalyticsService` errors. Gameplay never waits on it.
- Field values come from fixed enums (never raw player strings). Fields: **F1 = area/kingdom**, **F2 = device class** (phone, desktop), **F3 = context** (cause, rarity, category, tier). Combinations stay far below 8,000.
- Server logs anything money- or progress-related. Client logs UI views only.
- Tag a `build` value on key events so changes between versions can be compared.
- No UserIds, names or free text in fields. Nothing about a player's identity is stored outside Roblox's own analytics.
- Studio/private-place events may not reflect real data: test with View Events, then ignore pre-launch numbers.

## Funnels (10, the maximum)
| # | Funnel | Steps |
|---|---|---|
| F1 | **Onboarding** (one-time) | join -> first move -> first climb input -> egg spotted -> egg grabbed -> egg banked -> first hatch -> first rank-up -> returned (session 2) |
| F2 | **Egg run** (recurring) | egg spotted -> grabbed -> carried past hazard -> banked (alt exits as events: lost to fall, to theft, to Guardian) |
| F3 | **Guardian fight** | engaged -> telegraph survived -> won -> captured/reward claimed |
| F4 | **Home base** | first sanctuary visit -> first habitat placed -> first creature placed -> first tier-up |
| F5 | **Shop** | shop opened -> item viewed -> prompt shown -> purchase confirmed -> grant verified |
| F6 | **Ladder** | ladder seen -> step 1 bought -> step 2 -> step 3 -> step 5 -> step 6+ (one funnel per ladder via F3 context) |
| F7 | **Daily loop** | login -> reward claimed -> quest done -> streak day 3 -> streak day 7 |
| F8 | **Kingdom progression** (one-time) | first entry to each kingdom 1-6, then summit |
| F9 | **Hatch value** | egg obtained -> incubation started -> hatch completed -> creature placed/used |
| F10 | **Week one return** | session on D0 -> D1 -> D3 -> D7 (supplements built-in retention with our own milestones) |

## Economy events (<= 20 transaction types)
Currency: Coins. **Sources:** quest, daily, bank, hatch, summit, ladder-boost income. **Sinks:** tier-up, habitat, decor, egg ticket, hatch skip (if coin-priced), cosmetic. Aggregate per interval to stay inside rate limits. Robux revenue is already in Roblox's dashboard; log `purchase_attempt/granted/failed` as custom events to reconcile.

## Custom events (about 35 of 100)
- **Session:** `session_start` (build, F2), `session_end` (F3 = reason: quit/idle/fall/died/disconnect; F1 = last area), `area_enter`, `loading_time`.
- **Progress:** `egg_grabbed`, `egg_banked`, `egg_lost` (F3 = fall/theft/guardian), `fall` (F1 = section), `hatch` (F3 = rarity), `rank_up`, `tier_up`, `guardian_result` (F3 = win/loss/flee).
- **Retention drivers:** `daily_claim`, `quest_complete`, `streak_broken`, `streak_saved`, `banner_seen`.
- **Money:** `shop_open`, `shop_view` (F3 = category), `purchase_attempt`, `purchase_granted`, `purchase_failed`, `ladder_step` (F3 = ladder + step).
- **Friction:** `problem_report` (F3 = category, from the preset button), `settings_changed` (F3 = setting), `error_count` (aggregated), `save_fail`, `save_retry`.
- **Health:** `perf_sample` every 60 s (frame-time bucket, memory bucket, F2).
- **Ops:** `alert` (F3 = alert id) when the in-game guards below trigger; `flag_changed` when LiveConfig changes (ties config edits to metric shifts).

## Alerts (no native alerting assumed; tell me if Roblox adds some)
1. **In-game guards (automatic, server):**
   - Purchase mismatch (attempted vs granted beyond a small tolerance) over a rolling window -> log `alert`, flip `shop.ladders` off (LiveConfig), show the banner. Flip back only by the owner.
   - Save failure rate spike -> log `alert`, pause risky writes.
   - Error rate spike per server -> log `alert`.
2. **Daily dashboard review (owner or me, 5 min):** a fixed checklist, run after launch day and each morning:
   - Crash rate and error trend
   - F1 step drop-offs vs yesterday
   - Purchase attempted vs granted
   - D1 retention and average session length
   - Any `alert` events
3. **Weekly review:** top 3 funnel drop-offs, top `session_end` reasons, ladder and shop conversion, plus one decision (fix, tune, or leave).
If you want push-style alerts later, that needs an outside service and breaks the AnalyticsService-only rule: a separate decision.

## Reading the data (rules of thumb, not targets)
- First look at **F1**: the largest single drop between adjacent steps is the first fix.
- `session_end` reasons by area show where players quit and in what state (fell, idle, or quit while safe).
- Compare **phone vs desktop** for every funnel; phone drop-offs usually point to controls, performance or HUD.
- Sessions that never reach the first bank are onboarding failures, not retention failures.
- Do not set numeric targets until the first few hundred real sessions; benchmarks for this genre are not something I have verified.

## Soft-launch gates (use the same data)
Friends -> small group -> public. Each step needs: no unexplained `alert` events, crash rate in an acceptable range you set, purchase mismatch at zero, and F1 completion that is not collapsing on a specific step. Numeric thresholds are set after the first friends session, not guessed now.

## Reuse for future games
Keep `Analytics` in a shared module with a game-agnostic core (session, funnel wrapper, economy aggregator, perf sampler, alert guard) plus a per-game event list file. Same field scheme (area, device, context) and the same weekly review checklist.

## Test plan
1. Studio/private place: fire every event once; confirm in View Events; confirm field values stay enum-only.
2. Rate-limit test: simulate 8 players over 30 minutes; check dropped-event symptoms.
3. Fault test: make `AnalyticsService` error; gameplay must not hiccup.
4. Hosted alpha with friends, then review F1 and `session_end` before widening.

## Build order (after the merge)
1. `Analytics` module with batching, enums, pcall, `build` tag; tests.
2. Session, perf, error, save events (no gameplay file edits needed).
3. F1 onboarding, F2 egg run and economy events (hook calls into Bank, Inventory, Progression).
4. Shop funnels and ladder events together with the monetization build.
5. Alerts/guards with LiveConfig.
6. Dashboards and the daily/weekly checklist.

## Open
1. Confirm exact AnalyticsService funnel/progression signatures and current rate limits from the reference.
2. Who owns the daily review: owner or a scheduled task (Roblox login is needed to read the dashboard, so I cannot do it unattended).
3. Final event names/enums reviewed by the owner before hooks are written.

## Resolved (2026-10-28)
- Open 1 closed: signatures and limits verified above.
- Weekly seasons were dropped for v1 (2026-10-29): `season.enabled` and any season event go; F7 keeps login/quest/streak. Party/duo events are not logged.

Launch blockers: [launch-readiness-checklist](launch-readiness-checklist-2026-10-28.md).
