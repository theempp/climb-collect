# Cheap monetization ladders — spec (2026-10-28)

Design only. No game, place, product, Studio or Robux change. All product ids stay 0 and checkout disabled until the owner authorizes. Status: owner picks are LOCKED; numbers marked PROPOSED are mine and untested.

## Owner picks (LOCKED, this chat)
- Doubling-price ladders in the style of "Steal an Egg": start at 2 R$, price doubles each step.
- Two ladders: **coin income** and **egg hatch speed**. (Move speed and luck declined: they break "nothing paid affects capture/combat/rank".)
- Effect doubles each step. 10 steps from 2 R$ (2, 4, 8 ... 1,024 R$; 2,046 R$ total per ladder).
- Also design small cosmetics at 2-4 R$. Streak saver, coin gifts and tip not chosen.

> **APPROVED 2026-10-28 (owner):** coin ladder doubles to x32 then +8x flat; hatch ladder 5 steps with a 60 s floor. Open items 2-6 below still stand.

## Problem: 10 doublings of effect is 1,024x
Coin income at 1,024x breaks every coin sink (home tiers, habitats, decor). Hatch speed saturates after about 4-5 doublings because hatch time cannot go below zero. Owner chose doubling effect knowingly, so this is the recommended way to keep it:

| Ladder | Steps | Effect | Price | Cap rule (PROPOSED) |
|---|---|---|---|---|
| Coin income | 1-5 | x2, x4, x8, x16, x32 | 2, 4, 8, 16, 32 R$ | Doubling. |
| | 6-10 | +8x each: x40 ... x72 | 64 ... 1,024 R$ | Flat gains. Late steps are whale-priced vanity with limited economy impact. |
| Hatch speed | 1-5 | hatch time /2 each step | 2 ... 32 R$ | Floor: minimum incubation 60 s (PROPOSED). Steps beyond 5 add nothing, so this ladder stops at 5. |

If the owner wants a true 10-step doubling on coins, set a hard income cap per hour (server side) so the economy still holds. Flag: top tiers are 1,024 R$ one-offs, so confirm the rule on high single purchases before E03.

Net to the creator is about 70% of the price (Roblox takes 30%).

## Rules
- Fairness: affects only the buyer's own home production and incubation. No effect on capture, combat, mountain speed, raids or rank. Rank still gates home tiers (tier = rank AND coins), so coins cannot buy rank.
- Order: steps must be bought in order. The shop shows only the next step and its price.
- Server-authoritative: ladder level stored in the profile (`p.monet.ladders = {coin=n, hatch=n}`, PROPOSED schema); granted only through the exactly-once receipt service (E02). A second grant for the same receipt is a no-op.
- Products: Roblox sets one price per developer product, so each step is its own product: 10 coin + 5 hatch = 15 ladder products, plus cosmetics. Prices follow `2^step`.
- Not random: ladders need no odds disclosure. Paid eggs still do (see paid random items policy).
- Show the buyer the effect before purchase ("Coins x8 -> x16 for 16 R$").
- Do not stack with VIP / 2x Coins: show one combined multiplier, with a documented rule (PROPOSED: multiplicative, capped at a global max).

## Cheap cosmetics (2-4 R$)
Name tags, sparkle trails, small creature auras. Cosmetic only, no stats. List and art are OPEN.

## Open before build
1. Coin ladder: use the split (doubling then flat) above, or a hard income cap?
2. Global cap on the combined multiplier from ladders + VIP + 2x Coins.
3. Incubation floor value (60 s PROPOSED).
4. Cosmetic list and art.
5. Where the ladder lives in the Glassbloom Shop (HUD chat owns that screen; do not edit it from here).
6. Hosted test of receipts before any real Robux (E02/E03 order).

## Build order (after the other chat finishes merging)
Server ladder rules and tests with product ids 0 -> receipt wiring -> Shop UI step card -> Studio pass -> hosted alpha -> owner authorizes product creation.

## Resolved (owner popup, 2026-10-28)
- Open 1: split ladder (doubling to x32, then +8x flat to x72). Open 3: 60 s floor. (Both already approved above.)
- Open 2: combined multiplier is **additive** (ladder + VIP + 2x Coins), hard cap **x100**, value held in LiveConfig (`economy.coinMultCap`).
- Open 4: first cosmetic batch = sparkle trails, creature auras, preset name-tag styles (frame/colour only, no typed text). Egg skins later. Art still to make.
- Open 5: request to HUD chat: Shop **Boosts tab**, one step card per ladder showing only the next step. HUD chat builds it.
- Streak saver: owner wants one (prompt, 2026-10-28). Not yet specced; must not be pushed right after a streak break (safety plan s4).
- Still open: 6 (hosted receipt test before real Robux).

Launch blockers: [launch-readiness-checklist](launch-readiness-checklist-2026-10-28.md).
