# CLIMB & COLLECT — Core loop plan (interview 2026-10-20; rounds 1-3 resolved, nothing built)

**Legend:** **LOCKED** = chosen by you · **PROPOSED** = my detail, unapproved · **OPEN** = undecided · **ESTIMATE** = not measured.
**Sources:** your interview answers, `master.md` §0.5/§0.6/§1/§5–§9, `design/v4-climb-concept.md`. Design values come only from these. Monetization is DEFERRED to its own interview (assumed list: cosmetics, decorations, effects; no pay-to-win).

## 1. Reference game (Steal a Brainrot / Steal an Egg)
- **Verified:** nothing. I did no research and have not played either. All reference facts below are *your* descriptions.
- **Your description (unverified by me):** a speed-up loop, a chasing boss/guard, stealing from guarded or other players' spots, a tycoon base, and guards that get progressively more intense.
- **Interpretation (mine):** we take each feature's *purpose* (tension while carrying value, a base that pays you, a reason to return), not its skin or content.

## 2. Loop mapped to the four reference features
| Step | What happens here | Reference feature it serves |
|---|---|---|
| PREPARE | Check route board, weather forecast, stamina/net kit, resume camp | Speed (kit) |
| CLIMB | Run/climb routes; stamina and levels shape reach, WalkSpeed stays 12 | Speed |
| DISCOVER | Commons, hidden Rares, nests with guardians | Stealing |
| COLLECT | Hold-claim creatures; **take a Heartstone** from a nest; **net** a guardian pup | Stealing |
| PUSH / EXTRACT | Carry on (Heartstone glows, guardians escalate) or ATV/helicopter home | Chasing boss |
| BANK | Deposit at Foothold; finds become permanent; Heartstone starts ripening | Tycoon |
| UPGRADE | Habitat slots, cabin, tents, nets, cosmetics; ripened creature joins a habitat and yields | Tycoon |
| REPEAT | Offline yield, rotating mutations, legendary events, daily goal | Tycoon / retention |

## 3. Decisions
### LOCKED (by you)
1. **Stealing:** NPC-guarded nests + server-wide first-claim races for legendaries. No PvP, no player theft.
2. **Chaser:** Mountain Guardians, 1–2 species per region, random traits per encounter (speed, senses, size, weakness). A hit staggers and shakes one unbanked item into the 3-min recoverable drop pack.
3. **Guardian scaling:** progressively scarier **by region/altitude and by nest value** (richer Heartstones wake tougher guardians).
4. **Nests:** 2–3 per region, **per-player instanced**, ~10 min respawn. Legendaries stay server-wide first-claim.
5. **Speed progression:** stamina capacity and recovery only (soft caps). WalkSpeed stays 12. Levels gate backpack slots and stamina only.
6. **Heartstone** replaces the egg: aurora-crystal core from a guarded nest, 2 carry slots, glows (others see cargo value), ripens over real time at the base into a creature; the weather where it was taken sets its mutation. **Ripen time:** Common 5 min, Rare 30 min, Legendary 4 h.
7. **Tycoon:** habitat yield, small trickle, **8 h offline cap**, collect bonus **2x if collected within 1 h**. Currency buys habitat slots, cabin upgrades, tent upgrades, cosmetics and decorations. It does NOT buy creatures or Heartstones.
8. **Structure:** the Foothold is the only place finds become permanent. Camps are checkpoints and become **tents**, visually distinct, realistic-but-unique.
9. **Tents offer:** respawn, stamina refill, Camp Locker (1–3 slots, as LOCKED in V2), **social hub**, and **per-tent upgrades bought with currency**.
10. **Resume:** start a session at your **highest reached camp**. The full ascent remains the loop; no short-run mode.
11. **Getting home:** **ATV from low camps and helicopter from the ridge LZ** (V2 LOCKED). Walking down is the free baseline.
12. **Anti-grind:** few meaningful tiers plus collection milestones; rotating weather mutations as the new-content lever.
13. **Return hooks:** offline yield + collect bonus, rotating weather mutations, server-wide legendary events, daily expedition goal with a non-punishing streak.
14. **Social:** visit/flex cabins; shareable moments (summit reveal, legendary claim announcement, guardian-escape photo). No co-op raids or leaderboards in v1.
15. **Onboarding:** diegetic guided run with a companion NPC and short prompts (no text paragraphs; skippable on return). Intro Rare = **guardian-free Rare nook on Shepherd's Road** (by minute 5). **Cliffhanger at ~min 10:** Heartstone ripening timer in the cabin + a rare guardian's silhouette guarding a nest higher up.
16. **Monetization:** deferred.

### PROPOSED (by me)
- **Tutorial beats (~10 min):** (1) move + find a common, (2) hold-claim, (3) bank at the Foothold, (4) climb a short rope, (5) Rare nook, (6) a beginner-safe guardian + net, (7) Heartstone starts ripening, then the cliffhanger.
- **Net:** 3 tiers (cloth, rope, aurora-thread); tier sets throw range and interaction time, not guardian power. Pup capture is one per guardian per cooldown.
- **Rarity:** 4–5 tiers (Common, Uncommon, Rare, Epic, Legendary). Yield scales with rarity and species variety, not duplicates; duplicates give a small yield and count toward milestones.
- **Daily yield cap** and non-punishing streak (miss a day: streak pauses, no loss).
- **Level thresholds, slot growth (4→~12), habitat count and yield numbers:** to be set in tuning, not guessed here.

## 4. Sign-offs (RESOLVED 2026-10-20, LOCKED)
- **Net = a second claim verb** beside hold-to-claim. Works on guardian pups only (see §5 #9). 3 tiers (cloth / rope / aurora-thread) set throw range and interaction time, never guardian power. Cloth free; rope bought with Cairn Coins at level 4; aurora-thread earned from a Region 3 pup. One pup per guardian per cooldown.
- **Heartstone replaces the egg.** `master.md` §0.5 "Eggs" text becomes Heartstone. Hatchery reskinned as the Heartstone Hatchery (crystal cradles), layout frozen.
- **Camps become tents** (Camps 1-4). Built lodges/huts/tower are archived, not deleted. Foothold and the 4 gates stay.
- **Guardian hit shakes one unbanked item** into the 3-min drop pack (already in §3 #2); still unbanked cargo only.

## 5. Conflicts (RESOLVED 2026-10-20, LOCKED)
| # | Conflict | Resolution |
|---|---|---|
| 1 | Beginner protection vs scarier guardians | **Gentle Green Valley:** Region 1 guardians and intro nooks slow, short-sensed, no item shake until first bank. Scaling starts above Camp 1. |
| 2 | Resume vs full ascent | Skilled 25-30 min = full Foothold-to-summit run (record measure). Resume only skips what you already climbed. First ascent ~60 min over sessions. |
| 3 | Passive yield vs no-grind | Small trickle, 8 h offline cap, 2x bonus within 1 h is a reward only, streak pauses and never resets. Daily yield cap NOT adopted (open to tuning). |
| 4 | Tent upgrades vs Camp Locker | Tent tier raises locker 1->3, stamina refill speed, and a **small** guardian-free radius widening. No other effect. |
| 5 | Heartstone 2 slots vs 4-slot start | Keep 4 start slots; tutorial Rare is a normal 1-slot creature. |
| 6 | Hide spots vs camps | Camps are guardian-free; separate hide spots on routes break line of sight. |
| 7 | Dynamic weather vs 30 FPS floor | **Dynamic, quality-tiered.** Cheap lighting blend always on; particles, lightning, whiteout, foliage wind scale by tier. Prototype logs mobile-emulation cost; hourly scheduled presets only if 30 FPS breaks. Quality is engineered within the budget, not downgraded by default. |
| 8 | Ripening persistence | Server timestamps on the profile (start time, tier, mutation); completion computed on load, works offline. |
| 9 | Milestone slots vs LOCKED #5 | **LOCKED #5 amended:** slots come from levels and major codex milestones, total cap stays 4->12. |

## 6. Economy and content (rounds 2-3)
**LOCKED**
- **Currency:** Cairn Coins. Sources: habitat yield, banking, daily goal, milestones.
- **Habitats:** 4 habitats x up to 6 slots (start 1 habitat / 3 slots) = 24 displayed max in v1.
- **Backpack/levels:** 9 levels (8 level-ups). Slots 4->12; levels 2-7 give +1 each (to 10); two major codex milestones give the last +2. Levels 8-9 are stamina only.
- **Yield per hour:** Common 1 / Uncommon 3 / Rare 10 / Epic 35 / Legendary 150. Duplicate = 25% yield, full milestone credit. Mutation +50%.
- **Net tiers, tent tiers (3 per tent, price rising with altitude):** as §4.
- **Milestone rewards:** titles, badges, cosmetics, coins, and the two slot milestones.
- **Rarity:** 5 tiers (Common, Uncommon, Rare, Epic, Legendary); card border shape + 1-5 pips carry rarity, colour secondary; particle richness rises per tier; only Legendary gets a world beam.
- **Roster:** 8 species per region x 5 regions = 40, built as a **pre-made asset library** then wired in (see brief Phase C).
- **Legendaries:** 8 total (5 regional + 3 weather-linked), server-wide announced first-claim.
- **Mutations:** one weather = one mutation, 6 weathers (Clear, Rain, Fog, Storm, Snow, Aurora Night). Names/looks derived from each weather's own visuals.

**PROPOSED (mine, unapproved; set in the brief)**
- 40 regional species = 3 Common, 2 Uncommon, 1 Rare (nook), 1 Epic (guardian pup), 1 Legendary slot (regional) per region; the 3 weather-linked Legendaries are extra, so 43 creatures. (Resolves "8 per region" vs "8 legendaries"; confirm.)
- XP, level thresholds, prices, guardian trait ranges, nest/Heartstone flow, onboarding script, UI, schema: see `autonomous-build-brief.md` §3.

## 7. Still OPEN
- **Routes, trail narrowness, suspense and the summit gauntlet ("impossible final stretch" as the V1 viral loop):** next interview (prompt delivered in chat). May conflict with LOCKED 25-30 min, beginner protection and fall rules; flagged there.
- Legendary first-claim only vs also instanced (brief proposes first-claim only).
- Mobile device targets (Studio emulation is not a phone).
- Autonomous-run authorization, run length, stop conditions (brief §0, must be confirmed).
- Monetization (separate interview).

## 8. Feature priority
**Needed for a fun first playable loop (P1):** hold-claim commons and Rares, backpack slots, banking at the Foothold, Heartstone ripening, Rare nook, one nest + one guardian species (Green Valley) with chase, stagger, drop pack, camp tent safe zone, 1 camp locker, resume at highest camp, diegetic onboarding with cliffhanger.
**Next (P2):** net and pup capture, habitat yield + offline cap + collect bonus, ATV/helicopter extraction, region-scaling guardians, rarity tiers.
**Later (P3+):** per-tent upgrades, weather mutations, server-wide legendary events, daily goal and streak, social flex/visit, cosmetics shop, Training Yard.

## 9. Phased outline (each phase: checkpoint first, evidence in `evidence/core_P<n>/`, then STOP for review)
- **P0 Docs/safety:** apply approved edits to `master.md` and `CLAUDE.md`; checkpoint.
- **P1 First playable loop:** persistence (profile, bank, Heartstone timers), claim system, one Green Valley nest and guardian, chase + drop pack, tent safe zone, onboarding. Accept: full 10-min tutorial run measured on Studio mobile emulation, honestly labeled.
- **P2 Depth:** net, yield/offline, extraction, scaling guardians for regions 2–3, rarity tiers.
- **P3 Return hooks:** weather mutations (after cost check), legendary events, daily goal, social features.
- **P4 Tune and polish:** economy numbers from playtests, mobile budgets. Monetization interview happens separately before any store work.

**STOP. Next: routes interview, then confirm the autonomy authorization in `autonomous-build-brief.md`.**
