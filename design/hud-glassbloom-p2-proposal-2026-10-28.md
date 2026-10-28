# Glassbloom P2 proposal (revised), 2026-10-28

> **Owner answers (popups, 2026-10-28) — all recommendations (a) chosen:** Q1 XP sources + curve approved (40L+20, cap L50, no level-up rewards). Q2 stolen secure = 0 XP, no species bonus (first-carrier regrab still pays). Q3 Robux-origin creatures earn 0 habitat/legacy coins and no kin bonus; bought/multiplied coins need a separate decision before any coin product goes live. Q4 Competition: 5 coin-paying wins per UTC day (practice + snapshot), trophies unchanged. Q5 Meadow Egg 2,500 coins, section-1 table, single buy, 24 unhatched cap; Candy Swirl 5,000 coins, board-card violet look, looks only. Q6 tiles: 'TRUE ODDS / Odds shown are the odds used' and 'FAIR PLAY / Robux creatures never battle or raid'; tile 2 unchanged. Q7 Robux eggs + Egg Luck show 'Odds TBD · Coming soon'. Q8 Robux creatures do not follow the player in P2.

This revises `evidence/hud_glassbloom_2026-10-27/p2_draft.md` and resolves all 40 challenges in `evidence/hud_glassbloom_2026-10-27/p2_map_and_challenges.json` (see the Appendix). Every number is **PROPOSED** until the owner approves it. No game code was changed. Branch `codex/hud-glassbloom` @ `5442a43`.

**Citation key.** Bare file names are under `mountain/`. `Main` means `mountain/server/Main.server.luau`. `plan` means `design/hud-glassbloom-build-plan-2026-10-27.md`. `board` means `climb&collect/design/hud-board-v3/index.html`. `intel` means `climb&collect/design/hud-glassbloom-intel.md`. `mem:overhaul` and `mem:hudrev` are the Claude memory files `overhaul-plan-decisions.md` and `hud-revision-decisions.md`. Owner rules: no paid power in raids or theft (`mem:overhaul:11`); odds shown = odds used (plan:250); Robux items stay disabled with product id 0, and there are no products and no live prices (plan:10).

**Baselines** (from P0, `design/hud-glassbloom-handoff-2026-10-27.md:11`; I re-ran rules 121, ui_protocol 42, egg_raids 21, bat_rules 27, ui_server 25 and ui_presentation 46, all PASS on 2026-10-28): run_persistence 28, run_ui_server 25, run_lifecycle 8, run_rules 23, ui_client_state 50, hud_layout 288, tycoon_requests 11.

---

## 1. Owner decisions needed (ranked)

The recommendation is listed first in each row. Q-numbers are new; D-numbers are the plan's items (plan:244-254).

| Q | Decision | Options (recommended first) | Blocks |
|---|---|---|---|
| **Q1** | Approve the XP sources (§2.1) and the curve (§2.2) | **(a) Approve.** Rest points 25×k; first engaged win 100×k; repeat win 10×k at 5/day; secure 10×k at 20/day; new species +50; Trial 150×k. Curve: need = 40L+20, total = 20(L²−1), cap L50 = 49,980. No level-up rewards. (b) Approve the draft's 50(L+1) curve instead (L2 is then not reliable in section 1). (c) Supply your own numbers. | T5, T6 |
| **Q2** | XP for securing a stolen creature (the thief secures it, `RunRules.luau:61`; `Bats.luau:87-90`) | **(a) None:** 0 secure XP and no species bonus when the run's first carrier is someone else. A regrab by the first carrier still pays. (b) Half secure XP and no species bonus. (c) Full XP (this rewards alt-farmed theft). | T5 |
| **Q3** | Robux → coins → raid-power leak. Habitat coins scale with rarity (`Tycoon.luau:43-44`; `TycoonConfig.luau:4`). Coins buy bat knockback and reach (`BatRules.luau:44-53`), Train (`UIRequests.luau:221-225`) and, after D7, Meadow Eggs | **(a) Robux-origin creatures may sit in habitats but earn 0 habitat coins and add no kin bonus** (`Tycoon.luau:32-45`), and they earn no legacy income (`Rules.luau:97`). Coin-origin creatures stay battle-eligible and count toward bat sets (D8 restricts only Robux; while all Robux is disabled, coins can only be earned). **Residual risk:** the board's Robux coin packs, 2× Coins, Coin Rush and Auto-Bank (board:635-637) stay at id 0. Before any of them goes live, you must decide whether bought or multiplied coins may buy bat levels, Train or eggs. If they can, `Screens.luau:548` and tile 2 become false. (b) Robux creatures produce at the Common rate. This leaks when habitats outnumber earned creatures (up to 8 slots, `Tycoon.luau:9`). (c) Accept the leak. This contradicts `mem:overhaul:11`. | T8, T9 |
| **Q4** | Coin farm in Competition before coins can buy creatures. Practice pays +35 coins every 120 s against a fixed L3 starter team (`Competition.luau:26-27,39-40`), about 1,050 coins/h once your team can win (about team level 5; scoring at `:16-20,35-38`). Snapshot wins against an alt's weak defense farm the same way (`:29-32`) | **(a) A daily cap of 5 coin-paying Competition wins** (practice and snapshot combined) per UTC day = 175 coins/day ≈ 2.7 Common-habitat-hours. Trophies are unchanged. (b) Practice pays 0 coins. (c) No cap. | T9 |
| **Q5** | **Meadow Egg:** price, and which odds table it rolls. **Candy Swirl:** price and look | **Meadow Egg (a):** 2,500 coins (board:638), rolling the real **section-1 table** (`Catalog.luau:34,36`, rolled by `Main:152-154`): Mossbun 20, Petalyn 20, Fernox 28, Bloomlet 18, Thorncub 10, Floramoth 4. By colour that is **Blue 68 / Gold 18 / Violet 10 / Prismatic 4** (intel:90-98). The board's 80/18/2/0 matches no table. The price is about 38 Common-habitat-hours: 66 coins/h each (`TycoonConfig.luau:4`, `Tycoon.luau:83`), so about 19 h with the 2 starting habitats (`Tycoon.luau:27`). Because a free section-1 raid (about 19 s, ESTIMATE) rolls the same table, the egg is a coin sink, not a power shortcut. Single buy only (the board's ×3 at board:511 stays disabled). Unhatched-egg cap 24. **Candy Swirl (a):** 5,000 coins (board:639). Atlas derives the bat barrel and trail from the card's violet rarity tokens (intel:96,364). "Pink swirl" (board:639) has no drawn reference, so either supply one or accept the card tokens. Looks only; stats are unchanged. (b) Lower either price. | T9, T10 |
| **Q6** | Replacement copy for promise tiles 1 and 3 (`Screens.luau:554`). Tile 2, "No power / Strength comes from play", stays unchanged | **(a)** Tile 1 (Egg icon): **"TRUE ODDS" / "Odds shown are the odds used"**. Tile 3 (Creature icon): **"FAIR PLAY" / "Robux creatures never battle or raid"** (PROPOSED). The overflow audit decides fit; "NO POWER" already fits (handoff:12). (b) Tile 3: "HOME ONLY" / "Robux creatures stay in your sanctuary". | T11 |
| **Q7** | Odds bars for the Robux eggs and Egg Luck. No code table matches the board's Mystery 70/22/7/1 or Golden 0/70/25/5 (board:638), and all sections share one weight row (`Catalog.luau:36`) | **(a) Show "Odds TBD · Coming soon" with no bars** until EggOdds holds a real table (buttons are already disabled, id 0). (b) Define real disabled tables in EggOdds now (new odds, needs approval). | P5 (T7 adds the stub) |
| **Q8** | May Robux creatures follow the player as cosmetic-only companions? Followers and MaxHealth both come from `p.team` (`Main:59-68`) | **(a) Not in P2.** Robux creatures never enter `p.team`. Revisit when Robux eggs ship, using a separate follower slot with no stat path. (b) Yes now: split followers from `battleTeam` (new save field and UI). | T8 |

---

## 2. Player-XP spec (all numbers PROPOSED, D1 plan:244)

### 2.0 Verified pacing facts (corrected)
| Fact | Value | Source |
|---|---|---|
| Built section shape | Original 200 deep × 64 rise, scaled by .85 → **170 deep, rise 54.4** | `FreeClimb.luau:7,118`; `CompactGeometry.luau:3,5`; `CompactMountain.luau:30-36` |
| Section-1 nests | z −357.9, y 70.4, x 4096±58 (x kept) | `FreeClimb.luau:11`; `CompactGeometry.luau:5,18`; `CompactMountain.luau:7-8` |
| Exit | One basin-wide exit at z −166, depth 18, unscaled | `HomeLayout.luau:7`; `HomePromenade.luau:96-97`; `CompactMountain.luau:39` |
| Carry to exit | **≈183 studs** to the exit face (192 to its centre) | derived from the rows above |
| Speeds | Carry sprint 27×.9 = 24.3; carry walk 14.4; Guardian 1 = 10.1 | `MovementRules.luau:2-4`; `RaidConfig.luau:6` |
| Breaking | 2+k hits at .45 s; egg rest 18 s from secure; 2 nests alternate, so no wait | `RaidConfig.luau:2,6`; `EggRaids.luau:14,72` |
| Section-1 loop | **≈18–20 s sprinting** (carry ≈8 s + climb ≈7 s + strike/pickup ≈2 s + commit ≈1 s), about 28 s walking. **ESTIMATE, not measured** | spec `docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md:84` forbids trip targets before human timing |
| Uncapped secure XP | ≈190 secures/h × 10 = **≈1,900 XP/h at k=1**, so the daily cap is required | the row above |
| Reachable XP events (FreeClimb) | Only Guardian, Trial, Checkpoint and Nest prompts exist when `world:GetAttribute('FreeClimbVersion')` is set. Discovery, Shortcut, Wild and Summit exist only in the legacy world | `FreeClimb.luau:89-114`; `World.luau:152-210`; `Main:21-25` |
| Rest points | 3 per section, 18 in total; the first trigger gives team XP. There is no "section entry" award (corrects plan:16) | `FreeClimb.luau:12,107-110`; `Main:226-230` |
| Wins | Repeatable after the 24 s respite; a starter team (48 atk/s) deals the 3% of a 1,250-HP Guardian in about 1 s | `GuardianRules.luau:37-44`; `RaidConfig.luau:6`; `Combat.luau:162,217-219` |
| Trial | Re-runnable until captured; Trial runs can't be dropped; team XP is paid at reward creation | `Combat.luau:38-40,174,180`; `RunRules.luau:38,55,71` |

### 2.1 Sources
**Design:** one-time XP is **derived on every read** from durable flags plus a species ledger. Only repeat XP is stored. This makes it idempotent by construction: there is no retroactive payout, rollbacks are safe, and the same award can't be paid by two code paths.

| # | Event | XP | Rule | Stored as | Hook |
|---|---|---|---|---|---|
| X1 | First use of a rest point | **25×k** | One per id matching `^[1-6]:(entrance\|recovery\|guardian)$` (18 ids). Legacy ids are ignored (`Main:237,260`) | derived from `p.discoveries` (`Main:227-228`) | no award code; `hud xp` event at `Main:230` |
| X2 | First engaged normal win in section k | **100×k** | Contributor (`Combat.luau:162`) **and engaged**: dodges+hits ≥ **2** in that battle (`Combat.luau:148-150`; a pattern every 5 s, `:235`). The win and unlock flags are unchanged | `explorer.won[k]` (set-only) | `Combat.luau:177`, before `R.winGuardian` |
| X3 | Repeat engaged normal win | **10×k** | **5 per UTC day** across all sections; same engagement test | `repeatXp`, `repeats` | `Combat.luau:177` |
| X4 | Raid secure (not Trial, not stolen) | **10×k**, k = `run.section` (`RunRules.luau:61`) | **20 per UTC day**; only when reason is `'secured'` (`RunRules.luau:74`); `'already_secured'` gives 0 | `repeatXp`, `secures` | secure mutate `EggRaids.luau:69`; read `draft.run` before `Run.secure` clears it (`RunRules.luau:74`) |
| X5 | New species on that secure | **+50** | **Non-Legendary, non-starter** (`Rules.luau:8`). Paid on the first insert into the ledger, never on "not currently owned". Pool 33 (`Catalog.luau:31-40`) | `explorer.species[id]=true` | same mutate |
| X6 | Trial Guardian secured | **150×k** | Once per Guardian. **Pays only this row**: no X4, no X5, no daily-cap slot | derived from `p.captures` (`RunRules.luau:71`) | none needed |
| X7 | Stolen secure (first carrier ≠ securer) | **0** (Q2) | `run.firstCarrier` (§3 C4) | — | same mutate |
| X0 | Train, bat upgrade, tycoon, Competition, knock/theft/regrab, hatch, any coin or Robux purchase, hazards, Studio aids | 0 | Coin→XP would make level purchasable (`UIRequests.luau:221-225`); practice is farmable (`Competition.luau:39`); tycoon actions repeat (`Tycoon.luau:101-123`) | — | — |

**One-time pool:** 1,575 (X1) + 2,100 (X2) + 3,150 (X6) + 1,650 (X5) = **8,475**.
**Add rule (total):** `ExplorerRules.award(p,kind,k,today)` is pcall-wrapped. It normalizes `explorer` first, clamps every field, never errors and never returns false. In the secure mutate the result is ignored, and the mutate returns `Run.secure`'s result unchanged (`Profiles.luau:102-103`; `EggRaids.luau:50,64-70,118-124`).

### 2.2 Curve
- **XP from L to L+1 = 40L + 20.** **Total to reach L = 20(L²−1).** Cap **L50 = 49,980**.
- It has the same 40-per-level slope as the creature curve (`Rules.luau:23`), plus a 20 offset so that L2 costs 60.
- **L2 in section 1:** any of these reaches 60: all 3 rest points (75); 2 rests + 1 secure (60); 1 rest + 4 secures (65); or the first section-1 win (100). It does not depend on species luck (68% of section-1 rolls are starters, `Catalog.luau:36`).

| L | Next | Total | L | Next | Total | L | Next | Total |
|---|---|---|---|---|---|---|---|---|
| 1 | 60 | 0 | 11 | 460 | 2,400 | 21 | 860 | 8,800 |
| 2 | 100 | 60 | 12 | 500 | 2,860 | 22 | 900 | 9,660 |
| 3 | 140 | 160 | 13 | 540 | 3,360 | 23 | 940 | 10,560 |
| 4 | 180 | 300 | 14 | 580 | 3,900 | 24 | 980 | 11,500 |
| 5 | 220 | 480 | 15 | 620 | 4,480 | 25 | 1,020 | 12,480 |
| 6 | 260 | 700 | 16 | 660 | 5,100 | 26 | 1,060 | 13,500 |
| 7 | 300 | 960 | 17 | 700 | 5,760 | 27 | 1,100 | 14,560 |
| 8 | 340 | 1,260 | 18 | 740 | 6,460 | 28 | 1,140 | 15,660 |
| 9 | 380 | 1,600 | 19 | 780 | 7,200 | 29 | 1,180 | 16,800 |
| 10 | 420 | 1,980 | 20 | 820 | 7,980 | 30 | 1,220 | 17,980 |

### 2.3 Expected levels (all ESTIMATES; no human timing exists)
| Milestone | XP | Level |
|---|---|---|
| First section-1 visit: 3 rests + 2 secures | 75+20 = 95 | **L2** |
| …plus the first section-1 win | 195 | L3 |
| First ascent: 18 rests + 1 secure per section (210) + about 5.3 new species (32% in section 1, 100% on the first secure in sections 2–6, `Catalog.luau:36`) | ≈2,050 | **L10** |
| Full summit: the above + 6 first wins | ≈4,150 | **L14** |
| All one-time content + about 150 secures to complete 33 species (Mythic weight 4, `Catalog.luau:36`; at most 20 paid per day, average k≈3.5) | 8,475 + ≈5,250 | **≈L26** |
| One week at an ASSUMED 1 h/day, reaching the caps at k≈3 (750/day) plus ≈5,600 one-time | ≈10,850 | **≈L23** |
| Maximum repeat XP per day at k=6: 20×60 + 5×60 | 1,500 | L50 takes at least 28 days after all one-time content |

The board's "Lv 48" (board:596,606) is placeholder art, not a target.

### 2.4 Save fields (additive; schema stays 2)
`p.explorer = {v=1, repeatXp=0, day=0, secures=0, repeats=0, species={}, won={}}`

| Field | Meaning | Normalized bound |
|---|---|---|
| `repeatXp` | Sum of X3+X4 | integer ≥0; derived + repeat ≤ 49,980 |
| `day` | `floor(os.time()/86400)` UTC | **Monotonic.** Reset only when `today > day`; never decreases; on load, if `day > today+1`, set it to today |
| `secures`, `repeats` | Today's counters | integers 0..cap |
| `species` | `{[speciesId]=true}`, non-Legendary, non-starter | unknown ids and non-`true` values are dropped |
| `won` | `{['1'..'6']=true}` | other keys are dropped |

- **Default:** `R.newProfile` (`Rules.luau:7`).
- **Validation:** `Profiles.valid` checks `p.explorer==nil or type(p.explorer)=='table'` **only**. It never goes into the required lists (`Profiles.luau:20-21`), because valid runs pre-migration (`:53`) and before every save (`:124`) or transaction (`:103`). A rejection would kick the player (`Main:136`) or freeze their saves. All bounds are enforced by `ExplorerRules.normalize`.

### 2.5 Migration
- **Where:** `ExplorerRules.ensure(p,today)` runs in the load transform after `Custody.migrate` (`Profiles.luau:56`), so the result persists in the same write (`:59`).
- **When:** each field is seeded only when it is absent. If `species` is nil, seed it from owned creatures with `origin==nil`, non-Legendary and non-starter. Every pre-P2 creature is earned, because nothing sets `origin` today; the producers are `Rules.luau:8,33,60` and `RunRules.luau:70`. If `won` is nil, seed it from `p.wins`.
- **Nothing else migrates.** X1 and X6 are derived. The transform can run twice on a conflict (`Store.luau:64-65`) and stays idempotent.
- **Rollback:** older builds keep the unknown top-level key, because valid is a whitelist (`Profiles.luau:18-48`) and saves snapshot the whole `s.p` (`:125`). Discoveries, wins and captures earned on an old build still count (they are derived). Species and engaged wins earned on an old build are only missed until the next qualifying event. Nothing is paid twice.

### 2.6 Client read path
- **Server:** `publish` adds `s.ui.explorer = ExplorerRules.summary(p)` → `{xp, level, into, need, cap}` (`Main:95`). This is one shared pure function, so the client never re-derives the value.
- **Event:** an additive `hud` kind `xp{amount,source,level}` is emitted at X1 (`Main:230`), X2/X3 (`Combat.luau:177`) and X4/X5/X6 (after `EggRaids.luau:71` succeeds), so that toasts can name the source.
- **HudState:** diffs `ui.explorer.xp/level` to drive the XP line and the level-up moment (intel:330,425,434), the dock badge and ring (intel:329), and the player card "Player · Lv n" (intel:343). No level-up rewards (Q1).

---

## 3. Rule and save changes required by P2

This replaces the draft's "rules unchanged" note (challenge 9). **Unchanged:** raid outcomes, theft knockback and timings, Guardian AI, win and unlock flags, Trial rules, creature-XP sources, schema 2, product ids (all 0), and no MarketplaceService. The draft's **pre-save team strip is dropped**: the Equip rejection plus the load strip are enough.

| C | Change | Type | Required by | Where |
|---|---|---|---|---|
| C1 | **Saved-settings validator ignores unknown keys.** Known keys keep type and 0–1 checks; out-of-enum saved values are snapped on load; the patch path stays strict. **Ships before any build that writes new keys** | save rule | D11 (plan:254) prerequisite; lockout at `UIProtocol.luau:30-33` via `Profiles.luau:24,53` → `Main:136` | `UIProtocol.luau:20-36`, `Profiles.luau:24` |
| C2 | 5 new prefs: `cameraShake` (default true), `altitudeRail` (true), `hudScale` 0/.5/1 (.5), `effectsTier` 0/.5/1 (1), `sprintMode` **0=HOLD / 1=TOGGLE, default 1** (board:643-645). Enums are per-key on the patch path only; volumes keep the global 0–1 rule | save | D11 | `UIProtocol.luau:4,30-34` |
| C3 | `p.explorer`, awards X1–X6, daily caps | save + XP rule | D1, Q1 | §2 |
| C4 | `run.firstCarrier` (userId): set at first pickup, copied into the drop snapshot and by `Run.receive` | run data (no outcome change) | Q2 | `EggRaids.luau:46,78-83`; `RunRules.luau:56,61` |
| C5 | Engagement gate for **player XP only** | XP rule | D1, Q1 | `Combat.luau:168-180` |
| C6 | `origin` (`nil`=earned, `'coin'`, `'robux'`) on eggs and creatures. `R.hatch` copies it; every producer is listed in T8 | save | D7 (plan:250), D8 (plan:251) | `Rules.luau:60` |
| C7 | `R.equip` rejects `origin=='robux'` | rule | D8 | `Rules.luau:62-67` |
| C8 | Load strips Robux ids from `p.team`, then **refills the removed slots** with the highest-level battle-eligible creatures. The team never ends up empty (`Profiles.luau:35`; `Rules.luau:63`) | save normalize | D8 | `Profiles.luau:56-62` |
| C9 | `R.battleTeam(p)` used in every stat consumer (defense in depth) | rule | D8 | `Combat.luau:16,22,75,180,200`; `Main:60,68,230`; `Competition.luau:9` |
| C10 | **Mandatory:** `BatRules.setProgress` excludes Robux (sets unlock knockback 55+8k and reach 7+.5k) | theft rule | D8 + `mem:overhaul:11` | `BatRules.luau:10,22-31` |
| C11 | Robux creatures: `T.rate` returns 0, they add no kin bonus, and they are excluded from `settleIncome` | economy | Q3 | `Tycoon.luau:32-45`; `Rules.luau:97` |
| C12 | **Hard rule:** Buy and Skin are allowed only when in the sanctuary (`home.inSanctuary`), `p.run==nil`, not `inBattle`, and nothing is pending | rule | plan:94 (pending freezes `P.get`, `Profiles.luau:66`) | `UIRequests.luau` new branch; context gets `inSanctuary` and `inBattle` (`Main:300-305`) |
| C13 | Movement correction runs whenever a **session** exists, not only when `P.get` succeeds. Fall, void and exit checks still need `p` | anti-cheat | plan:94 | `Main:377-381,388` |
| C14 | `p.receipts`: a dense array capped at **64** with FIFO removal; the receipt is pre-checked against the live profile **before** transact; the mutate returns `false,'duplicate'`; a **2 s** per-player Buy cooldown | save | D7 | `RunRules.luau:72-73` pattern; `UIRequests.luau:17` |
| C15 | The Meadow Egg grants `{id='e'..serial, species=EggOdds.pick(1,r), origin='coin'}` into `p.eggs`; unhatched-egg cap **24** | save rule | D7, Q5 | `Rules.luau:50-61` (today `p.eggs` is uncapped; at most 3 incubate) |
| C16 | `p.cosmetics={skins={}, batSkin=nil}` (not under `p.bats`, which `BatRules.normalize` rebuilds, `BatRules.luau:14-20`; `Main:91`); the Skin action | save | D7, Q5 | new |
| C17 | `p.competition={day,wins}` with a cap of **5** coin-paying wins per day (monotonic day) | economy | Q4 | `Competition.luau:39-40` |
| C18 | Bats grab and auto-return **consume the drop before `adopt`**, restore it on failure, and emit events after the clear | theft impl (same behaviour) | plan:60 (T3 adds work inside that window) | `Bats.luau:83-89,99-104` |
| C19 | `EggOdds` replaces the local `roll`, with identical results | rule (identical) | D7 "odds shown = odds used" | `Main:151-154` |
| C20 | Typed `hud` events; `calm` on **every** threat removal; `context.exits` and `section` | protocol, additive | plan:89-91 | §4 T3/T4 |
| C21 | New actions `Buy` and `Skin`; the shop capability becomes `partial` | protocol | D7 | `UIProtocol.luau:3`; `ClientState.luau:6-7`; `UIPresentation.luau:98` |

Not changed: **Train and Specialize on Robux creatures stay allowed.** They have no effect in raids: tycoon output ignores level and specialization (`Tycoon.luau:32-45`), and only visual stage changes (`Rules.luau:13`).

---

## 4. P2 task list (dependency order)

Gates: **ungated** tasks follow plan §11–12 directly. Gated tasks start only after the owner answers.

| T | Task · files | Tests | Done | Gate |
|---|---|---|---|---|
| **T0** | **Settings validator relax (C1)** · `UIProtocol.luau` (new lenient `savedSettings`), `Profiles.luau:24` | ui_protocol: a saved table with an unknown key passes and a patch with one is rejected; run_persistence: a profile holding an unknown settings key loads, no kick, no overwrite | Passes; noted in the handoff that a build containing T0 must be live before any build that writes new keys | — |
| **T1** | Sync path · `tools/rmcp/sync_hud.py:8-22,36` (only UI and shared HUD modules today; ModuleScript or LocalScript only): add `mountain/server/*.luau` → `ServerScriptService.MountainServer.*` (`mountain.project.json:8`), `*.server.luau` as **Script**, plus Rules, RunRules, BatRules, Catalog, Tycoon and the new shared modules (`:6`) | Dry run lists every target | Studio and repo checksums match; `game.PlaceId==0` asserted first (plan:7-8) | — |
| **T2** | New prefs (C2) · `UIProtocol.luau:4,20-36` | ui_protocol: defaults; hudScale and effectsTier accept 0/.5/1 and reject .25; sprintMode accepts 0/1 and rejects .5; volumes accept .25/.7/.75/.8/.95/1 (`UIProtocol.luau:4`; `Screens.luau:592` gives .7→.95→1→0); run_ui_server: a legacy profile without the keys loads; .7/.8/.95 volumes round-trip | Passes | after T0 |
| **T3** | Typed `hud` events (C18, C20) · helper after `Main:40`; emitters: `carry` (`CarryVisuals.luau:69-72`, when `stolenFrom==nil`); `carry{stolen}` and `regrab` (`Bats.luau:89`, emitted **after** the drop is consumed); `regrab{auto}` (`:101`); `knocked{expiresAt}` using `GetServerTimeNow` (`:76-78`); `lost` (`CarryVisuals.luau:44`; `Bats.luau:90,102`); `safe` (`CarryVisuals.luau:74-76`); `alert{guardian,guardianId,section,sectionName}` from the `Main:193` warning (pass eggId via `Guardians.luau:15`; battle joins send nil, `Combat.luau:58`); **`calm` from `service.remove` when a threat existed** (`Guardians.luau:23-25`, called at `Main:125,145,197`), plus the step diff (`:41`) and `normalWin` (`:19-22`). Client: add `'hud'` at `ClientState.luau:64` | ui_client_state: hud is forwarded; combat_raids: alert→catch→calm once, alert→death→calm, alert→leave, normalWin→calm per threatened user; egg_raids/bats: **two grabs of one drop in the same frame → exactly one carrier**; no double carry+regrab (`EggRaids.luau:91`); toasts byte-identical (`tools/compact_raid.client.luau:7`) | All suites pass | — |
| **T4** | `context.exits` and **server section** · `Main.server.luau`: exits `{cframe,size}` built once after `:16`; `sectionOf(position)` uses the GuardianBounds boxes (as in `:182-186`; nil outside them). Add both to `state.ui` (`:95`) and context (`:374`); **add `section` to the diff at `:373`** | A late joiner receives exits (1 with the Promenade, `HomePromenade.luau:93-97`); a section change sends context | Passes | — |
| **T5** | **Player XP** (C3–C5) · new `shared/ExplorerRules.luau` (curve, derived one-time XP, total `award`, monotonic day, `normalize`, `ensure`, `summary`); `Rules.luau:7`; `Profiles.luau:20-28` (type-only check), `:56` ensure; `Combat.luau:177` (engagement); `EggRaids.luau:69` (pcall award; branch on `draft.run.trial` and firstCarrier); `EggRaids.luau:46,78-83` and `RunRules.luau:56,61` (firstCarrier); `Main:95` summary; harness `tests/service_harness.py:30-43` | new `explorer_rules.luau`: L1–30 table, `level(59)=1`, `level(60)=2`, cap; legacy ids ignored; day D+1→D→D+1 resets once; far-future day clamped; caps 20/5; malformed explorer (string, NaN, negative, bad ids) is normalized without error; ledger first-insert only (remove, re-secure → no second +50); Legendary is never in the ledger; coin- or Robux-origin creatures are excluded from the seed. egg_raids: secure +10k once; `already_secured` gives 0; **Trial pays only 150k** (no counter, no species); stolen gives 0; first-carrier regrab pays; **malformed `draft.explorer` still secures exactly once**; the 21st secure of the day gives 0. combat_raids: engaged first win → `won[k]` and 100k once; a leech (<2 resolved patterns) still gets the `wins` flag but 0 XP; repeat cap 5. run_persistence/run_ui_server: a legacy profile is seeded and persisted; `explorer="junk"` loads. StudioTests: JSON round trip | All pass; the HUD reads `ui.explorer` | **Q1, Q2** |
| **T6** | `shared/HudState.luau` + `tests/hud_state.luau` · rest/carry/chase/sanctuary/battle; carry start; regrab (`stolenFrom` = my previous run id, `RunRules.luau:61`); chase from `alert`/`calm`; **section from server `ui.section`/context** (client X/Z test `Controller.luau:302-305` only as a fallback); checkpoint; creature-XP and explorer-XP diffs; legacy-toast tier map defaulting to tier 1 (plan:205) | hud_state | Passes (plan:94) | after T3–T5 (explorer parts need Q1) |
| **T7** | `shared/EggOdds.luau` (C19) · `table(k)` from `Catalog.luau:34,36`; `pick(k,r)` for r in [0,100); `byColour(k)`; `display(itemId)` returns nil for Robux items (→ "Odds TBD · Coming soon", Q7); `Main:151-154` keeps `rng` and calls `pick` | rules: an r grid at .5 steps gives the old loop's species; colour sums 68/18/10/4; 100k picks within ±1 pt; **shown = used** for every displayed item | egg_raids still 21/21 | — (the display stub follows Q7) |
| **T8** | **Origin + enforcement** (C6–C11) · `Rules.luau:60` (hatch copies), `:62-67` (equip), `R.battleTeam`; `Profiles.luau:56-62` (strip + refill; moves any Robux egg found in cargo or recovery back to `p.eggs`); C9 consumers; `BatRules.luau:24`; `Tycoon.luau:32-45`, `Rules.luau:97`. **Producers** (property-tested to copy origin from their source): `Rules.luau:8` (starters, nil), `:33` (schema-1 Trial, nil), `:60` (hatch, copies the egg's origin), `RunRules.luau:70` (secure, nil: runs come only from nests, drops and Trials), ShopRules (egg, `'coin'`). Egg movers keep fields: `Rules.luau:45-48,73-84`; `RunRules.luau:29,32`. **No Robux grant function**: tests insert fixtures directly | rules: hatch copies origin; equip rejects; property test across all producers. ui_server: Equip rejected with a message. combat_raids: an injected Robux id adds no power, guard or XP. run_persistence: an all-Robux team loads stripped and refilled, no kick. bat_rules: Robux excluded from sets. tycoon: a Robux creature in a habitat adds 0 coins and no kin bonus. Competition snapshot excludes Robux. **Grep gates:** no production `origin='robux'`; `table.insert(%w+.creatures` only at the four producer lines | All consumers filtered and grep-verified | C6–C10 ungated (D8); C11 **Q3**; followers **Q8** |
| **T9** | **Coin purchase: Meadow Egg** (C12–C15, C17, C21) · new `shared/ShopRules.luau` (catalog `{id,kind,currency,price,section,productId=0}`). `buy` validates the item and currency (Robux → `unavailable`), coins ≥ price and the egg cap, then debits, grants and appends the receipt; a duplicate receipt returns `false,'duplicate'`. `UIProtocol.luau:3`: `Buy{item,receipt}`, receipt `^[%w%-]+$` 8–64 characters, refused on `legacy:1` (`Main:326-331`); allowlist `ClientState.luau:6-7`. `UIRequests.luau`: C12 gate → 2 s cooldown → **receipt pre-check on the live `p` (no write)** → `P.transact(player,'buy:'..receipt,mutate)`. **Retry:** a failed commit leaves `pending`, so `P.get` is nil and requests are refused (`Profiles.luau:66,90`; `UIRequests.luau:77,117-119`). Autosave (`Main:422-426`) or release (`Main:149`) commits it via `Profiles.luau:122`, and the client shows the purchase once `receipts` contains it. The mutate runs **once per pending draft**, not per id (`Profiles.luau:88,99-104`). `Main:377-388` (C13). `Competition.luau:39-40` (C17). `UIPresentation.luau:98` → partial; ×3 stays disabled | new `shop_rules.luau`: exact debit; insufficient coins change nothing; unknown item; Robux rejected; duplicate; FIFO 64; cap 24; roll via EggOdds. run_persistence/run_ui_server: **N replays of one receipt → `store.calls.update` increases by exactly 1**; **the same receipt after a successful commit → no write, returns ok**; `failNext=3` → `save_pending` → autosave commits exactly one debit and grant; `failAfterCommit` replay is single. **The gate refuses Buy while `p.run.phase=='carried'`, in battle, outside the sanctuary, or with a pending transaction**; a teleport during pending is corrected. competition: the 6th coin win of the day pays 0 coins. ui_protocol: Buy/Skin validation, legacy refusal. ui_server: the Buy branch **plus the Bat action through the dispatcher** (no test exists today). ui_presentation:49 updated. StudioTests: JSON | Coins and eggs stay durable after a forced failure | **Q3, Q4, Q5**; needs T7, T8. Until then, tests use a test-only catalog and the shipped catalog keeps Buy disabled |
| **T10** | **Candy Swirl** (C16) · `p.cosmetics`; `valid` checks types only; load drops unknown skin ids; bought via T9 (an owned skin is refused with no debit); `Skin{op='equip'\|'clear',id}` behind the C12 gate; look override in `Bats.luau:12-28` (stats still from `BatRules`) | shop_rules, ui_protocol, ui_server, run_ui_server (a legacy profile without `cosmetics` loads; ownership persists); bat_rules (`normalize` leaves `p.cosmetics` alone) | The equipped skin shows; knockback and reach unchanged | **Q5**; needs T9 |
| **T11** | Promise tiles 1 and 3 · `Screens.luau:554`. Tile 2 is unchanged. Re-check `:548` against Q3 | Overflow audit at 6 sizes | 0 errors (the only P0 error, handoff:12) | **Q6** |
| **T12** | Regression + Studio · all suites; T1 sync to the Glassbloom copy; play-test Buy (refused while carrying), hatch, Equip rejection, the XP line and level-up; record hashes and evidence | — | plan:94 criteria; existing toasts still fire | after all of the above |

---

## 5. Appendix: challenge disposition

Lenses: O = owner rules, C = code correctness, E = exploitability. **40 fixed, 0 rejected.** Two keep only part of the reviewer's fix (#31, #37); the reasons are in their rows.

| # | Lens | Problem (short) | Verified at | Disposition |
|---|---|---|---|---|
| 1 | O | Bat-set exclusion shown as an open question (O8) | `BatRules.luau:10,22-31` | Fixed: C10 mandatory; O8 removed; Train/Specialize allowed as having no raid effect (§3 note) |
| 2 | O | Robux→coins→power, O10 | `Tycoon.luau:43-44`; `BatRules.luau:44-53`; board:635-637 | Fixed: Q3 (merged with #35) |
| 3 | O | A Buy mid-carry gives theft and loss immunity | `Profiles.luau:66`; `Bats.luau:74-75`; `Main:44,197,369-390` | Fixed: C12 hard rule + carried-run test |
| 4 | O | Robux-egg and Egg Luck odds have no table | `Catalog.luau:34,36`; board:637-638 | Fixed: Q7 + T7 `display` stub + shown=used test |
| 5 | O | The copy dropped tile 2 | `Screens.luau:554`; plan:251 | Fixed: Q6 replaces tiles 1 and 3 only; `:548` re-checked under Q3 |
| 6 | O | Live `grantRobuxEgg` | plan:10 | Fixed: no grant function; fixtures; grep gate (T8) |
| 7 | O | T9/T10 not gated | plan:10; `mem:hudrev:15` | Fixed: gated on Q3–Q5; test-only catalog |
| 8 | O | The thief earns secure XP | `RunRules.luau:56,61`; `Bats.luau:87-90` | Fixed: Q2 + C4 firstCarrier |
| 9 | O | "Rules unchanged" was inaccurate | `Profiles.luau:24,124`; `Combat.luau:16,22,75` | Fixed: §3 explicit list; pre-save strip dropped |
| 10 | O | New keys before the validator decision | `UIProtocol.luau:30-33`; `Profiles.luau:24,53`; `Main:136` | Fixed: T0 (C1) before T2 |
| 11 | O | sprintMode had 3 values | board:645 | Fixed: HOLD/TOGGLE, default TOGGLE |
| 12 | O | Robux followers decided silently | `Main:59-68` | Fixed: Q8 |
| 13 | O | Migration paid species of any origin | `Rules.luau:60` | Fixed: the ledger seeds only `origin==nil`; test |
| 14 | O | Plan citations off by one | plan:16,60,89,205,244,250,251 | Fixed: all citations in this doc use those lines |
| 15 | C | The retry can't reach transact | `Profiles.luau:66,90,122`; `UIRequests.luau:77,117-119`; `Main:149,422-426` | Fixed: autosave/release commits; receipt-safe replay; `failNext=3` test |
| 16 | C | "Mutate runs once per id" was false | `Profiles.luau:88,99-104` | Fixed: reworded; post-commit replay test |
| 17 | C | L2 did not arrive in section 1 | `Catalog.luau:11,36`; `Rules.luau:8` | Fixed: curve 40L+20, rest points 25×k |
| 18 | C | Pre-compact geometry | `CompactGeometry.luau:3,5`; `CompactMountain.luau:30-39` | Fixed: §2.0 (170/54.4, carry ≈183, loop ≈18–20 s, ≈1,900 XP/h) |
| 19 | C | No server section reaches the client | `Main:95,182-186,374` | Fixed: T4 adds section to ui, context and the diff |
| 20 | C | calm missed on catch, death and leave | `Guardians.luau:23-25`; `Main:125,145,197` | Fixed: T3 emits in `service.remove`; test |
| 21 | C | Legendary and Trial got new-species XP | `EggRaids.luau:96-99`; `RunRules.luau:68-71` | Fixed: X5 non-Legendary; X6 pays only its own row |
| 22 | C | Plan citations (duplicate of #14) | as #14 | Fixed (same correction) |
| 23 | C | Wrong citation for "landmarks unreachable" | `FreeClimb.luau:89-114`; `World.luau:152-210`; `Main:21-25` | Fixed: §2.0 with the FreeClimbVersion condition |
| 24 | C | Trial re-run citation | `Combat.luau:38-40`; `RunRules.luau:38,71` | Fixed: §2.0 |
| 25 | C | The strip can empty the team | `Profiles.luau:35`; `Rules.luau:63` | Fixed: C8 refill + all-Robux test |
| 26 | C | Habitat coin math | `TycoonConfig.luau:4`; `Tycoon.luau:27,30,67,83` | Fixed: 66/h, ≈38 habitat-hours (Q5) |
| 27 | C | Volume test values | `UIProtocol.luau:4`; `Screens.luau:592` | Fixed: tests use .7/.8/.95; enums per key on the patch path |
| 28 | C | Tycoon rate overstated | `Tycoon.luau:42-44` | Fixed: "ignores level and specialization" (§3 note) |
| 29 | E | A duplicate receipt still writes | `Profiles.luau:99-113`; `Store.luau:102-111`; `UIRequests.luau:17,37` | Fixed: C14 pre-check, `false,'duplicate'`, 2 s cooldown, update-count test |
| 30 | E | Pending suspends anti-cheat | `Main:369,377-391`; `Guardians.luau:33-34`; `Combat.luau:162` | Fixed: C12 gate + C13 correction keyed on the session |
| 31 | E | An XP failure soft-locks custody | `Profiles.luau:102-103`; `EggRaids.luau:50,64-70,118-124` | Fixed: total pcall add, type-only valid, malformed-explorer test. **Not adopted:** a bounded give-up on the exit retry, because it would strand a secured creature |
| 32 | E | Species pool and ownership-based check | `RunRules.luau:68-71`; `Catalog.luau:50` | Fixed: first-insert ledger; pool 33; same rule in the seed |
| 33 | E | Two pay paths and rollback | `Main:21-25,226-230`; `Profiles.luau:18-48` | Fixed: one-time XP derived; only repeat XP stored |
| 34 | E | Day rollover unspecified | `Main:381`; `MovementRules.luau:2-4` | Fixed: monotonic day, clamp, D+1→D→D+1 test |
| 35 | E | Robux laundering through the tycoon | `Tycoon.luau:32-45`; `Rules.luau:93-99` | Fixed: Q3(a), C11 + test |
| 36 | E | Practice coin farm | `Competition.luau:21-27,39-40`; `UIRequests.luau:256-266` | Fixed: Q4 cap of 5/day, widened to snapshot wins (alts, `Competition.luau:29-32`) |
| 37 | E | The origin tag fails open | `RunRules.luau:29,32,70`; `Rules.luau:8,33,45-48,60,73-84` | Fixed: producers listed, property tests, grep gates. **Replaced** "reject in `Profiles.valid`" with load normalization, because valid runs pre-migration and a rejection kicks the player (`Profiles.luau:53`; `Main:136`) |
| 38 | E | A Trial secure paid three rows | `RunRules.luau:64-74`; `EggRaids.luau:69` | Fixed: branch on `run.trial`; tests for both branches |
| 39 | E | The drop is consumed after adopt | `Bats.luau:83-89,101`; `EggRaids.luau:85-93` | Fixed: C18 + a same-frame double-grab test |
| 40 | E | Guardian XP can be leeched | `Combat.luau:50,162,217-219`; `RaidConfig.luau:6` | Fixed: engagement ≥2 resolved patterns for player XP only (X2, X3) |
