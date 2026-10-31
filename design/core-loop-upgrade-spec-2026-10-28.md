# Core loop upgrade spec (design only) — 2026-10-28

> **SUPERSEDED in part 2026-10-29**: duo partner / party assist, Defense Outpost raids, shields and seasons are removed by the home-base redesign. Mountain egg raids, bat theft, Grip and the lake loop are unaffected. Plan: `C:/Users/HOME!/Desktop/ClimbCollect/game/homebase-c/design/homebase-build-plan-2026-10-29.md`.

No code, Studio, product or publish changes. Owner popup answers 2026-10-28 are authority. Numbers marked PROPOSED are untested.

## 1. One sentence
Hold on to a wild creature on a dangerous mountain, carry it home past guardians and thieves, then ride your strongest companions as your Grip grows to catch rarer ones.

## 2. Loop (new beats in **bold**)
1. Train **Grip** at home (Training Beast).
2. Climb to a nest, crack the egg (pickaxe taps; first strike alerts the guardian).
3. **Hold-on catch**: the creature bolts, you cling on until the catch meter fills.
4. Carry the creature (one at a time, stealable, lost on serious fall). Optionally **ride a secured creature** to move faster.
5. Mountain exit secures it permanently; place it at home; it produces eggs and coins.
6. Spend coins on habitats, bats, bag **and Grip**; raise **Luck**.
7. **Lake**: cast for eggs when you want a calm session.
8. Rank up: new mount tier, visible look, harder catches.

## 3. Grip (new stat, owner answers)
- Separate from climbing stamina; the existing single stamina pool and movement tuning stay untouched.
- Every catchable creature has a **Required Grip**. Grip >= Required lets you attempt the hold-on; below it, a locked "Need Grip N" prompt shows. Grip also caps which creatures you can ride (mount tier = creature Required Grip <= your Grip).
- Training Beast at the home plot: **coins buy Grip levels** (steep cost curve, PROPOSED) **plus a workout bonus** (short track run at home, once per day, adds a Grip bonus). No Grip is gained by running it for free beyond that bonus.
- Server-authoritative: Grip lives in the profile (new versioned field); client never sets it.

## 4. Hold-on catch
- After the final egg strike the creature bolts along a short path; the player auto-clings (touch: hold one big button; desktop: hold E). Catch meter fills while holding; it drains when the creature bucks (telegraphed beats, 0.4 s warning).
- Fail (meter empty or knocked off by a bat): **shake-off retry**. The creature stays catchable, one retry while the guardian closes in (owner). A second failure lets it escape and the nest closes.
- Bats can still hit during the hold-on (owner did not choose shielding). Duo partner may assist: partner's contact adds a small catch bonus (PROPOSED).
- Phone floor: one-thumb input, no precision timing, 30 FPS safe, large hit area (>= 44 px).

## 5. Mounts
- Owner: **ride a secured creature, carry the new one.** A fresh catch is carried or leashed and stays stealable; mounts are safe.
- While carrying an unsecured creature you cannot ride (PROPOSED), so riding is a trip to and from the mountain, not a carry-theft escape.
- Mount speed, size and a short boost scale with creature rarity and level, capped by your Grip (Section 3). Riders can be bat-knocked off (dismount, brief stun); they never lose the mount creature.
- Flying creatures are **fly-by catch targets only** (owner): rare overhead passes you must time a hold-on for; mounts stay ground-only, so route design is unchanged.
- Visible hook: a ridden mount shows rank crest, aura and saddle cosmetics to other players.

## 6. Lake egg-fishing + Luck
- A calm lake kingdom near the sanctuary. Cast, wait, pull when the bar hits the zone; eggs rather than fish.
- **Guardian shark only** (owner): no player-vs-player batting at the lake. A shark telegraphs, then lunges at the catch; dodge/escape-tap saves it, otherwise the egg is lost.
- Luck stat improves rarity odds of fished eggs; coin upgrade levels (PROPOSED, capped). Farther water = rarer eggs, shark closer and faster.
- Fished eggs use the existing break/reveal/carry/secure rules.
- Odds shown before any paid random purchase (existing rule).

## 7. Rank progression
Rank changes, visibly: mount tier cap (via Grip tiers), run speed tier, aura/title/bat look, catch-meter tolerance. Not chosen: home/outpost scaling by rank, mount-gated sections, fusion. Sections stay freely enterable (existing decision).

## 8. Money (LOCKED by owner 2026-10-28)
- Paid items: cosmetics (auras, saddles, skins) and **temporary Grip boosts**.
- Paid Grip boosts are **temporary** and **capped below the top two tiers**: a boost can never lift effective Grip into the top two catch/ride tiers. **Coin Grip is the only permanent path.**
- Deliberate exception to the 2026-10-28 launch rule "nothing paid affects capture/combat/raid/rank": Grip gates capture and mount tier, so a capped, temporary paid boost does affect low/mid-tier capture. Raids, combat and rank stay free of paid power; Robux-egg creatures still never join raids.
- Boost duration, strength, stacking, price and cap value are PROPOSED and open; limits shown in the shop before purchase.
- No Robux spend, product ids, pricing or publish authorised.

## 9. Open, decide before build
1. Paid Grip boost duration, strength, stacking and price (cap rule is locked).
2. Required Grip numbers per species/tier; Grip curve and coin costs; workout reward size.
3. Luck curve and cap; lake zone count and shark difficulty; reuse of existing egg catalog or lake-only species.
4. Carry-while-riding rule (PROPOSED: not allowed).
5. Mount speed numbers and bat-knock-off tuning; phone 30 FPS with mounts and 8 players.
6. Whether fliers need new animation rigs (shared rigs per body type is existing plan).
7. Profile schema bump (Grip, Luck, lake state); migration of existing saves.

## 10. Suggested order (PROPOSED)
Grip + Training Beast -> hold-on catch -> mounts -> Luck + lake -> rank visuals. Needs hosted phone testing after each; real DataStore and device behaviour still unverified in the build.

## References
Ride a Dino beginner guide (stamina/Grip, jump-on catch, fuse): https://bloxodes.com/articles/ride-a-dino-beginner-guide. Pull a Lucky Fish overview: https://games.gg/news/pull-a-lucky-fish-codes-july-2026-reel-in-free-rewards/. Prior decisions: memory `core-loop-upgrade-direction-2026-10-28`, `egg-loop-decisions`, `release-decisions-2026-10-28`.
