# D03 / E01 launch rules (owner decisions, 2026-10-28)

Decisions only; no code, platform setting or product was changed. Values marked PROVISIONAL need numbers/tuning later.

## D03 — competitive and retention rules
- **Rank/trophies:** monthly season with a soft reset (rank drops partway toward baseline); season rewards cosmetic titles/trophies. Exact reset fraction PROVISIONAL.
- **Practice battles:** small capped coin reward, no rank. Daily cap PROVISIONAL.
- **Offline raids:** defender loses only a small capped amount of coins. Creatures and eggs can never be taken. Cap PROVISIONAL.
- **Dailies:** one daily login claim (UTC reset) plus 3 quests; streak gives small cosmetic bonuses, no penalty for missing days.
- **Caeloryn (Sovereign of the Stars) abilities** (names from `mountain/shared/Catalog.luau`):
  1. Astral Lance (already designed).
  2. Gravity Choir: telegraphed pull-in zones; escape by dashing out or using a rope/ledge.
  3. Constellation Accord: star-connect puzzle; touch lit stars in order to break the boss shield.
  4. Celestial Dominion: enrage phase under 25% HP combining Lance, Gravity and Accord patterns faster with a clear tell; surviving it opens the capture window.
  Numbers/timings PROVISIONAL; needs implementation and a live Trial test.

## E01 — shop
- **Hard rule (owner):** nothing paid affects capture, combat, raid or rank outcomes.
- **Robux offers chosen:** cosmetics; noncompetitive convenience (extra incubator slot, backpack space, decor); egg skip / instant hatch; coin packs.
- **Activation:** Robux live at launch (all buttons currently disabled, product ids 0).

### Flags (owner was told; kept as chosen)
- Egg skip and coin packs conflict with the earned-egg loop and with checklist E01's "no pay-to-win" acceptance wording. They let players buy progression, though not outcomes. Revisit if playtest or Roblox review says otherwise; the owner may drop them without touching the rest of the shop.
- "Robux live at launch" requires E02 (server receipt/exactly-once entitlement) and E03 (real product ids) to be finished and tested in the private hosted beta first. It cannot happen before those. Spending/test purchases still need separate owner authorization.
