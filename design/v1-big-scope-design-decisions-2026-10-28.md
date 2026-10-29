# v1 big-scope design decisions — 2026-10-28

Design only. No game, place, Studio, publishing or Robux changes. Source: owner popups in this chat. Vault: `Climb & Collect/Decisions.md`, `Open Questions.md`. HUD (Glassbloom) chat untouched.

Status key: **LOCKED** = owner picked it. **PROPOSED** = numbers/details I supplied, untested.

## Settled before this interview (LOCKED)
- Big public v1 (parties, raids, rankings, dailies, shop, full roster/Guardians); new dedicated universe; phone + desktop at launch; weekly ranking seasons.
- Private hosted alpha of Integrated Review06 + Glassbloom HUD comes first (DataStore/device unknowns).

## 1. Player-vs-player raids
| Topic | Decision | Status |
|---|---|---|
| Target | Separate **Defense Outpost** (fixed-slot walls/traps/gate) guarded by 3 stationed creatures. Home sanctuary is never attacked. | LOCKED |
| Building | Fixed-slot pieces unlocked by play; server-validated; saved as a versioned snapshot. | LOCKED (slots ~10, catalog PROPOSED) |
| Stakes | Trophies + coins from a capped **Outpost Vault** (fills from production). Never eggs, creatures, decor or main wallet. | LOCKED (fill rate, ≤10% hold, daily cap PROPOSED) |
| Protection | ~4h shield after being hit, 24h revenge, ~5 attacks/day. | LOCKED (numbers PROPOSED) |
| Matchmaking | Trophy bracket among players active in 14 days + friends; seeded bot outposts when population is low. | LOCKED |
| Defender view | Raid log, ~20s replay, one-tap revenge, defense report. | LOCKED |
| Eggs/creatures taken | Never in player raids. Mountain theft (bats, unsecured carry) stays the only theft. | LOCKED |
| Paid | Paid **re-rolls** and **capped shields** only (see §7). No paid slots, pieces or stats. Robux-egg creatures never join raids. | LOCKED |

Reconciliation: "theft impossible in the sanctuary" holds because raids hit the Outpost, not the plot. Paid shields are the single exception to "raids free of paid power".

## 2. Parties
- **Duo only (max 2)**. Owner overrode the recommended 4. Invite/friends/code; no open finder needed. LOCKED
- Ready-check portal into the same mountain instance; if one leaves, the other continues solo; late follow via "Join party" PROPOSED 2 min. LOCKED
- Co-op Guardians: each contributor gets own capture chance; normal wins give raid respite + companion XP to each; Trials give each contributor the collectible. LOCKED
- Risk: Guardian/Trial tuning must work for 1–2 players, not 4. OPEN

## 3. Dailies
- Login: **hard streak, resets to zero on a miss** (owner overrode recommended soft-fail). Track length PROPOSED 7 days. LOCKED
- Quests: 3 daily + 1 weekly from mountain/home/social pools; one free reroll each. LOCKED (pool PROPOSED)
- Reset: one global time, 00:00 UTC (also the weekly season boundary). LOCKED
- Rewards: coins, normal-egg tickets, cosmetics, capped XP/production boosts. No power, no rare-creature chances. LOCKED
- Flag: hard streak plus 00:00 UTC (8pm US Eastern) is harsh for casual and young players. No streak-saver decided.

## 4. Ranking, duels, practice
- Season end: tiered rewards (cosmetics/titles/badges/coin + egg tickets, granted once on next join) and soft trophy reset. LOCKED
- Friend challenges: live friendly outpost raid, no stakes, no rank, small cosmetic stat. LOCKED
- Practice: XP/tutorial credit only; no coins; no rank. LOCKED
- Existing numeric-UserId stat battle is replaced by the friendly raid. PROPOSED

## 5. Caeloryn
Ability 1 Astral Lance. Abilities 2–4 use the catalog names: Gravity Choir (control: pull/push), Constellation Accord (team shield), Celestial Dominion (ultimate: charged beam + star constructs). Roles LOCKED; tuning OPEN.

## 6. Devices and servers
- Phone + desktop; 30 FPS floor on a mid-tier phone, 60 on desktop; tablet best-effort; controller after launch. LOCKED
- Needs one real low-end Android/older iPhone test (owner devices are high-end). OPEN
- **MaxPlayers 8**, one home per player, duos seated together. LOCKED. Creator Hub setting for the new universe and real eight-client hosted test OPEN.

## 7. Shop (E01)
- Sells convenience, cosmetics, boosts, paid re-rolls, Robux eggs, plus **capped shields** (PROPOSED: one extra ~4h shield/day, total cap ~8h). No power items, no raid stat/slot/piece sales, no legacy multiplier passes. LOCKED
- Prices PROPOSED, untested: Starter Pack 199, 2x Coins 399, VIP 599, Summit Pass 449 R$. Re-roll and shield prices unset.
- Odds + pity counter shown on every paid random item before purchase. LOCKED
- Needs doc fix: Oct 27 wording "raids/theft stay free of paid power" must now say shields are the one exception.

## Open / still PROPOSED
Vault fill %/cap, shield length, attack cap, trophy bands, piece catalog, outpost run authority (real-time server-validated vs deterministic sim), profile schema version, quest pool, streak length, prices, Guardian scaling for duos, low-end device, hosted Max Players, ranking reward table.

## Recommended build order (checklist M2–M5)
1. **M2 sanctuary progression (S01–S05)** first: habitats, production, hatch, onboarding. Raids' Vault and Outpost depend on income and profile schema.
2. **E02 receipt service early** (from M5): exactly-once grants, needed by dailies tickets, shields, re-rolls and Robux eggs. Spend nothing until authorized.
3. **C07 dailies/quests**: smallest M4 item, shared reward pipeline, gives retention data in the private alpha.
4. **C01–C02 duo party + co-op Guardians**: reuse existing contribution tracking; add ready-check travel.
5. **C03 Outpost raids** (largest, riskiest): schema → piece catalog/builder → single-player practice runs → async attack + shield/revenge → vault. Prototype the run authority before UI.
6. **C05–C06 seasons, badges, titles**; **C04 friend raid** after C03.
7. **E01/E03** final offers and product IDs last, once what they sell exists.
8. M3 mountain/art and M6/M7 reliability run in parallel; private hosted alpha as early as M2 allows.

Do not skip: P0 data-integrity work (Q01) before raids go live, since raids create the first cross-player writes.
