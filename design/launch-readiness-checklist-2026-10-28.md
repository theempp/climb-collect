# Launch readiness checklist (2026-10-28)

One ordered list of what blocks a **public** launch. Owners: **O** = owner, **C** = Claude (this docs line), **HUD/HB/INT** = the HUD, home-base and integration chats. Nothing here authorizes publishing, products or Robux. Details live in the linked plans.

## Blockers, in order
| # | Item | Owner | Depends on | Source |
|---|---|---|---|---|
| 1 | Merge settles: Glassbloom HUD + home-base + audio-swap into one build | INT/HUD/HB | — | CLAUDE.md |
| 2 | Confirm `OpponentId` TextBox gone in merged build (present on hud-glassbloom, absent on homebase-c) | INT, C verifies | 1 | [safety](safety-compliance-plan-2026-10-28.md) |
| 3 | Build `Analytics`, `LiveConfig`, `Sfx` as standalone modules + tests in a new worktree | C | O says merge done | [funnels](funnels-analytics-spec-2026-10-28.md), [live-ops](live-ops-tools-plan-2026-10-28.md), [audio](audio-juice-plan-2026-10-28.md) |
| 4 | Hook calls into gameplay/HUD files (Bank, Inventory, Shop, Settings) | C with HUD chat | 3 + O approval | same |
| 5 | Kill switches wired: shop, ladders, eggs, cosmetics, each kingdom; dry run on private place | C | 3, 4 | live-ops |
| 6 | PolicyService gate + odds screen for paid eggs; restricted/eligible tests | C/HUD | 1 | safety |
| 7 | Ladder server rules (ids 0), additive multiplier cap x100, exactly-once receipts; Shop Boosts step card | C, HUD | 1, 5 | [ladders](cheap-monetization-ladders-spec-2026-10-28.md) |
| 8 | Hosted private alpha: receipts tested, real DataStore save/reload, 8-client test, phone (iPhone 16 Pro / 18 Pro Max) | O + C | 1-7 | [publishing-checklist](publishing-checklist.md) |
| 9 | First creature: owner sets `ROBLOX_API_KEY`/`ROBLOX_USER_ID`, authorizes one upload; Studio import + phone check | O, C | — | [launch assets](launch-assets-plan-2026-10-28.md) |
| 10 | Tier 1 sounds sourced (Creator Store shortlist), owner audition, ids logged in G05 manifest | C, O | 3 | audio |
| 11 | Icon (from captures, hero shortlist of 3) + 5-6 thumbnails 1920x1080 + copy without seasons/party | C, O picks | 1, 9 | launch assets |
| 12 | Maturity & Compliance Questionnaire answered accurately (aim Mild) | O | 1 | safety |
| 13 | Owner creates products and sets real ids; checkout enabled; Open Cloud config script + change log | O, C | 8 | ladders, live-ops |
| 14 | Incident runbook signed off; daily 5-min dashboard review owner chosen | O | 5 | live-ops, funnels |
| 15 | Soft launch: friends -> small group -> public, gated on alerts, crash rate, purchase mismatch 0, F1 not collapsing | O | all | funnels |
| 16 | Re-check Roblox policy pages the week of launch | C | — | safety |

## After launch (not blockers)
Select audience application (250 engaged plays in 60 days + review); streak saver spec; egg-skin cosmetics; player-typed text with filtering; trailer.
