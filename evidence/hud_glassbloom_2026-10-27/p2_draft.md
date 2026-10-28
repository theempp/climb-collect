# A) Player-XP proposal for owner review

Every number in this section is **PROPOSED** and needs owner approval (plan §11 D1: `design/hud-glassbloom-build-plan-2026-10-27.md:245`).

## A0. What the numbers are based on (verified in code)

**There is no player XP today.**
- Only creatures have XP. The creature curve is `level*40` per level, capped at 50 (`mountain/shared/Rules.luau:21-25`).
- New profiles have no player-level field (`Rules.luau:7`).

**Correction to plan §1 (`build-plan:15`).** There is no "section entry" award. Team XP fires on the first use of any of the 18 "Rest here" prompts. That is 3 per section, ids `k:entrance|recovery|guardian` (`mountain/world/FreeClimb.luau:12,107-110`; `mountain/server/Main.server.luau:227-230`).
- Landmark, Summit and Wild rewards can't be reached in FreeClimb (`Main.server.luau:13-16,236-261`).
- `Combat.startWild` is never called (`mountain/server/Combat.luau:61-68`).

**Pacing facts used below:**
- **Section shape:** each section is 200 studs deep and rises 64 (`FreeClimb.luau:7`).
- **Nests:** 2 per section, at `z-174` (`FreeClimb.luau:11`).
- **Exit:** at z=-166 (`FreeClimb.luau:5`).
- **Speed:** walk 16, sprint 27, carrying ×0.9 (`mountain/shared/MovementRules.luau:2-4`).
- **Eggs:** hits needed are 2+k at 0.45 s cadence; an egg rests 18 s after use (`mountain/shared/RaidConfig.luau:2,6`).
- **Section-1 loop:** about 35–45 s (strike, carry about 220 studs to the exit, walk back up). This is **an ESTIMATE, not measured**; the spec forbids setting trip targets before human timing (`docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md:84`).
- **Guardian respite:** 24 s between normal wins, so wins repeat (`RaidConfig.luau:6`; `mountain/shared/GuardianRules.luau:37-44`).
- **Secure:** each secure grants one creature. A retry with the same run id is deduped (`mountain/shared/RunRules.luau:64-75`).
- **Trial team XP** is granted when the reward is created, not when it is secured (`Combat.luau:171-180`). Player XP should not copy that.

## A1. XP sources

| Event | XP | Cap / cooldown / first-time rule | Anti-farm reason | Hook (file:line) |
|---|---|---|---|---|
| First use of a rest point | **20×k** | Once per rest-point id (18 in total), reusing the existing `first` flag | One-time. Fast travel grants nothing (`Main.server.luau:279-284`) | `Main.server.luau:227-230` |
| Egg secured (raid) | **10×k**, where k = the run's section (`RunRules.luau:61` keeps the section through theft) | Full XP for the first **20 secures per UTC day**, then 0. Only when `Run.secure` returns `'secured'`; `'already_secured'` gives 0 | A section-1 loop is about 40 s (estimate). Uncapped that is about 900 XP/h at k=1, and secure is unlimited (`RunRules.luau:64-75`). Scaling with k favours high sections | Inside the `P.transact` mutate at `mountain/server/EggRaids.luau:69` (read `draft.run` before `Run.secure` clears it, `RunRules.luau:74`) |
| New species secured | **+50** | Once per species not owned before this secure. Starters (mossbun/petalyn/fernox, `Rules.luau:8`) never qualify | Bounded: 33 non-starter species (`mountain/shared/Catalog.luau:31-40`) | Same mutate, `EggRaids.luau:69` |
| First normal Guardian win | **100×k** | Once per section: read `not p.wins[tostring(k)]` before `R.winGuardian` runs | One-time (wins flag, `Rules.luau:35`) | `Combat.luau:177`, for each eligible contributor (≥3% damage, `Combat.luau:162`) |
| Repeat normal Guardian win | **10×k** | **5 per UTC day** across all sections | Wins repeat every 24 s respite with no first-time flag (`GuardianRules.luau:37-44`; `Combat.luau:180`) | `Combat.luau:177` |
| Trial Guardian captured | **150×k** | Once per Guardian. Paid at **secure**, when `run.trial` is true (`RunRules.luau:68,71`), not at reward creation | Losing a trial run lets a player re-run the Trial (`Combat.luau:174`; captures are set only at secure) | Mutate at `EggRaids.luau:69` |
| **No XP** for: Train, bat upgrade, tycoon actions and upgrades, Competition, knock/theft/regrab, hatch, coin or Robux purchases, raid hazards, Studio aids | 0 | — | Coin→XP would make level purchasable and passive (`mountain/server/UIRequests.luau:221-225`; offline coins `mountain/shared/TycoonConfig.luau:3`). Competition practice can be farmed every 120 s (`mountain/server/Competition.luau:26-27,39`). Free tycoon actions repeat without limit (`mountain/shared/Tycoon.luau:101-123`). Theft can be farmed by alts (`mountain/server/Bats.luau:83-92`) | — |

The total one-time pool is **8,160 XP**: rest points 1,260, first wins 2,100, trials 3,150, new species 33×50 = 1,650.

## A2. Level curve

- XP from level L to L+1 = **50×(L+1)**.
- Cumulative XP to reach level L = **25×(L−1)×(L+2)**.
- Level cap **50**, the same as the creature cap (`Catalog.luau:37`). Reaching L50 takes 63,700 XP.
- It uses the same linear-step shape as the creature curve (`Rules.luau:23`).
- The first level arrives within section 1: 3 rest points (60) plus a first secure (10+50).

| L | To next | Total to reach | L | To next | Total to reach | L | To next | Total to reach |
|---|---|---|---|---|---|---|---|---|
| 1 | 100 | 0 | 11 | 600 | 3,250 | 21 | 1,100 | 11,500 |
| 2 | 150 | 100 | 12 | 650 | 3,850 | 22 | 1,150 | 12,600 |
| 3 | 200 | 250 | 13 | 700 | 4,500 | 23 | 1,200 | 13,750 |
| 4 | 250 | 450 | 14 | 750 | 5,200 | 24 | 1,250 | 14,950 |
| 5 | 300 | 700 | 15 | 800 | 5,950 | 25 | 1,300 | 16,200 |
| 6 | 350 | 1,000 | 16 | 850 | 6,750 | 26 | 1,350 | 17,500 |
| 7 | 400 | 1,350 | 17 | 900 | 7,600 | 27 | 1,400 | 18,850 |
| 8 | 450 | 1,750 | 18 | 950 | 8,500 | 28 | 1,450 | 20,250 |
| 9 | 500 | 2,200 | 19 | 1,000 | 9,450 | 29 | 1,500 | 21,700 |
| 10 | 550 | 2,700 | 20 | 1,050 | 10,450 | 30 | 1,550 | 23,200 |

## A3. Expected levels (ESTIMATES, no human timing exists)

| Milestone | XP | Level |
|---|---|---|
| First ascent: all 18 rest points, about 1 section-1 secure on the way | 1,260 + 60 ≈ 1,320 | **L6** |
| Full summit: all rest points, all 6 first normal wins, about 6 secures, about 6 new species | 1,260 + 2,100 + about 210 + 300 ≈ 3,870 | **L12** |
| All one-time content plus about 150 secures to collect 33 species (Mythic weight is 4/100, `Catalog.luau:36`) | 8,160 + about 5,250 | **about L22** |
| One week at an ASSUMED 1 h/day: about 15 secures and 3 repeat wins per day at k≈3, plus about 5,900 one-time | about 5,900 + 7×540 ≈ 9,700 | **about L19** |

The most XP a day can give from repeats is 20×60 + 5×60 = 1,500 (at k=6). That means L50 takes at least about 37 days even at the cap. The board's "Lv 48" (`climb&collect/design/hud-board-v3/index.html:596,606`) is placeholder art, not a target.

## A4. Save fields (additive; schema stays 2)

`p.explorer = {v=1, xp=0, day=0, secures=0, repeats=0}`. All fields are integers:
- `xp`: cumulative total, clamped at 63,700.
- `day`: `floor(os.time()/86400)`.
- `secures`: full-XP secures today.
- `repeats`: repeat Guardian wins today.

Steps:
- **Default:** add to `R.newProfile` (`Rules.luau:7`).
- **Validation:** add an optional block in `Profiles.valid`, written as `p.explorer==nil or …` (pattern at `mountain/server/Profiles.luau:23-28`). It rejects only non-table, non-integer, NaN or negative values. It must **never** go into the required lists at `Profiles.luau:20-21`: `valid` runs on the old save before migration (`Profiles.luau:53`), so a required field would lock out every existing save (`Main.server.luau:136`).
- **Upper bound:** enforce it by clamping in the add function, not by rejecting in `valid`. A stricter validator freezes saves (`Profiles.luau:124-126,142`).

## A5. Migration (recommend: retroactive for one-time milestones only)

- **Where:** in the load transform, after `Custody.migrate` (`Profiles.luau:56`). Call `Explorer.ensure(p)` so the result persists in the same write (`Profiles.luau:59`).
- **When it runs:** only when `explorer` is nil or `v` is missing.
- **Retroactive XP, one-time milestones only:**
  - 20k for each discovery id matching `^[1-6]:(entrance|recovery|guardian)$`. Legacy ids such as `k:branchN` and `summit` are ignored (`Main.server.luau:237,260`).
  - 100k for each `wins[k]`.
  - 150k for each `captures[guardianId]`.
  - 50 for each distinct owned non-Legendary, non-starter species.
- **No retroactive XP for repeatable events.** `securedRunIds` keeps only the last 128 and has no section (`RunRules.luau:72-73`).
- **Why this is safe:** the function is deterministic and guarded by `v`, so it is safe when the transform runs twice on a conflict (`mountain/server/Store.luau:64-65`).

## A6. Level-up rewards

**None proposed.** No owner decision grants one. **OPEN:** the level-up moment exists only as a tier-3 presentation (`climb&collect/design/hud-glassbloom-intel.md:434`).

## A7. Where the client reads it

- `publish` sends a clone of the whole profile (`Main.server.luau:92,96`), so `state.explorer` arrives automatically.
- A pure shared `ExplorerRules.level(xp)` returns `{level, into, need, pct}`. It is used by `HudState` and `UIPresentation`.
- Display targets:
  - lv badge plus ring on the Creatures dock button (`intel.md:329`);
  - "Player · Lv n" plus XP bar on the player card (`intel.md:343`);
  - the XP line and level-up moment, driven by the `HudState` XP diff (`build-plan:91`; `intel.md:330,425,434`).
- **Optional additive** `hud` kind `xp{amount,source,level}`, so toasts can name the source.

---

# B) P2 implementation tasks (dependency order)

Baselines, all PASS: run_persistence 28, run_ui_server 25, run_lifecycle 8, run_rules 23, rules 121, ui_protocol 42, ui_presentation 46, ui_client_state 50, hud_layout 288, bat_rules 27, egg_raids 21, tycoon_requests 11.

**Scope note.** §3 limits P2 server edits to Main, CarryVisuals, Bats and Guardians, with "No rule changes" (`build-plan:59`). D1, D7 and D8 (`build-plan:245,251-252`) add edits to Profiles, UIRequests, EggRaids, Combat, Competition, Rules, BatRules and UIProtocol. Raid and theft rules stay unchanged. The only save-rule changes are the additive optional fields.

**T1 · Sync path for server/shared code**
- **Files:** `tools/rmcp/sync_hud.py`.
- **Why:** FILES lists only UI/shared HUD modules (`sync_hud.py:8-22`), and the class choice is ModuleScript or LocalScript only (`sync_hud.py:36`).
- **Work:** add `mountain/server/*.luau` → `ServerScriptService.MountainServer.*` (`mountain.project.json:8`). Add `Main.server.luau` as a **Script**. Add `Rules`, `RunRules`, `BatRules`, `Catalog` and the new shared modules → `ReplicatedStorage.MountainShared.*` (`mountain.project.json:6`).
- **Done:** a dry run lists every target; Studio and repo checksums match after sync; `game.PlaceId==0` is asserted first (`build-plan:7-8`).

**T2 · New prefs**
- **Files:** `mountain/shared/UIProtocol.luau:4,20-36`.
- **Work:** add defaults (owner decision O11) for `cameraShake` (bool), `altitudeRail` (bool), `hudScale`, `effectsTier` and `sprintMode`. The last three use 0/.5/1, enforced by a **per-key** value set at lines 25 and 32. The volume rows step by 0.25 (`mountain/client/UI/Screens.luau:592`), so the global 0–1 rule must stay unchanged.
- **Tests:** `ui_protocol.luau` (defaults; enum accepts 0/.5/1 and rejects .25; volume still accepts .25/.75); `run_ui_server.py` (a legacy profile without the new keys loads; new keys persist).
- **Done:** tests pass and saved .25/.75 volumes survive.

**T3 · Typed `hud` events** (all existing toasts stay)
- **Helper:** `hud(player,kind,data)` after `Main.server.luau:40`, sent on the existing Event remote.
- **Emit points:**

| Kind | Where | Notes |
|---|---|---|
| `carry` | `CarryVisuals.luau:69-72` | Only when `run.stolenFrom==nil` |
| `carry{stolen=true}` (thief) | `Bats.luau:89` | |
| `regrab` | `Bats.luau:89` when the grabber is the original carrier | |
| `regrab{auto=true}` | `Bats.luau:101` | |
| `knocked` | `Bats.luau:78` | `expiresAt` uses `GetServerTimeNow`, because `drop.expires` is server `os.clock` (`Bats.luau:76`) |
| `lost` | `CarryVisuals.luau:44` (with reason) | |
| `lost{stolen}` | `Bats.luau:90` | |
| `lost{escaped}` | `Bats.luau:102` | |
| `safe` | `CarryVisuals.luau:74-76` | |
| `alert{guardian,guardianId,section,sectionName}` | the `warning` callback, `Main.server.luau:193` | Pass `eggId` through `Guardians.luau:15`; battle joins alert with nil (`Combat.luau:58`) |
| `calm` | new callback | Diff `state.threats` before and after `Rules.step` (`Guardians.luau:41`) and in `normalWin` (`Guardians.luau:19-22`) |

- **Client:** add `'hud'` to the forwarded kinds (`mountain/client/UI/ClientState.luau:64`).
- **Tests:** `ui_client_state.luau` (hud forwarded, near lines 91-97); `combat_raids`/`egg_raids` (one event per transition; no double `carry`+`regrab` from `EggRaids.luau:91`); the existing toast strings are unchanged (tools record them: `mountain/tools/compact_raid.client.luau:7`).
- **Done:** all suites pass; toasts are byte-identical.

**T4 · `context.exits`**
- **Files:** `Main.server.luau`.
- **Work:** build `{cframe,size}` for each child of `SanctuaryExits` once, after line 16. Add it to `state.ui` (line 95) and to context (line 374), but **not** to the diff at line 373. ClientState merges and keeps it (`ClientState.luau:58-63`).
- **Done:** a late joiner receives exits; the count matches the folder (1 with Promenade, `mountain/world/HomePromenade.luau:93-97`).

**T5 · Player XP** (implement only after the owner approves §A)
- **New `mountain/shared/ExplorerRules.luau`:** curve, `add` with clamp, UTC-day reset, award table, `ensure` for retroactive XP.
- **Edits:**
  - `Rules.luau:7` default;
  - `Profiles.luau:23-28` optional validation, and line 56 `ensure`;
  - `Main.server.luau:230` rest point;
  - `Combat.luau:177` first/repeat Guardian win;
  - `EggRaids.luau:69` secure, new species and trial, inside the mutate.
- **Harness:** add the module to `mountain/tests/service_harness.py:30-43`.
- **Tests:**
  - new `tests/explorer_rules.luau`: table values for L1–30, clamp, day rollover, caps, `ensure` idempotent and ignoring legacy ids;
  - `egg_raids`: secure awards once; `already_secured` gives 0; trial XP only at secure;
  - `combat_raids`: first win once; repeat cap 5;
  - `run_persistence`/`run_ui_server.py`: legacy profile gains retroactive XP and persists; malformed `explorer` fails closed with no overwrite;
  - `StudioTests.luau`: real JSON round trip.
- **Done:** all suites pass, and the HUD reads the level.

**T6 · `HudState.luau` + `tests/hud_state.luau`** (needs T3–T5 shapes)
- **Pure functions:**
  - state rest/carry/chase/sanctuary/battle;
  - carry start (phase becomes `carried` with a new run id);
  - regrab (`stolenFrom` equals my previous run id, `RunRules.luau:61`);
  - chase on/off from `alert`/`calm`;
  - section change, preferring the server section over the client X/Z test (`mountain/client/UI/Controller.luau:301-308` vs `Main.server.luau:182-186`);
  - checkpoint change;
  - creature-XP and explorer-XP diffs;
  - sanctuary flag;
  - legacy-toast tier map, defaulting to tier 1 (`build-plan:206`).
- **Sync:** already in the manifest (`sync_hud.py:21`).
- **Done:** hud_state tests pass (`build-plan:94`).

**T7 · Shared odds (behaviour-identical refactor)**
- **New `mountain/shared/EggOdds.luau`:**
  - `table(k)` from Catalog weights (`Catalog.luau:34,36`);
  - `pick(k,r)` for r in [0,100);
  - `byColour(k)` = Blue 68 / Gold 18 / Violet 10 / Prismatic 4, using the owner mapping (`intel.md:90-98`).
- **Edit:** `Main.server.luau:151-154` keeps `rng` and calls `EggOdds.pick`.
- **Tests:** `rules.luau` (a grid of r values gives the same species as the old loop; colour sums equal the shown percentages; 100k picks within tolerance).
- **Done:** egg_raids still 21/21.

**T8 · Robux origin tag + server enforcement** (before T9, so grants carry tags)
- **Field:** `origin` on eggs and creatures: nil = earned, `'coin'`, `'robux'`. Only `'robux'` is restricted.
- **Carry the tag:** `R.hatch` copies `origin` (`Rules.luau:60`).
- **Helpers:** `R.battleEligible(c)` and `R.battleTeam(p)`.
- **Enforcement points:**
  1. `R.equip` rejects Robux ids (`Rules.luau:62-67`).
  2. Load strips Robux ids from `p.team` after migration (`Profiles.luau:56`), and the same strip runs before each save. **Do not** add the rule to `valid()`: it runs pre-migration at `Profiles.luau:53`, so a hard rule there would kick the player (`Main.server.luau:136`).
  3. Use `battleTeam` in: `Combat.luau:16,22` (power/guard), `:75` (specials), `:180` (XP), `:200` (wild XP); `Main.server.luau:56-69` (MaxHealth/companions), `:230,238` (rest/landmark XP); `Competition.luau:9` (defense and attack snapshots).
  4. Bat sets: exclude Robux creatures in `BatRules.setProgress` (`mountain/shared/BatRules.luau:24`), pending O8.
  5. Train/Specialize: optionally block (O9; `UIRequests.luau:205-227`).
- **Producer:** `ShopRules.grantRobuxEgg` is used **only in tests**. Product ids stay 0, and no MarketplaceService is added (`build-plan:10`).
- **Tests:**
  - `rules` (hatch copies origin; equip rejects);
  - `ui_server` (Equip rejected with a message);
  - `combat_raids` (an injected Robux team member adds no power or XP);
  - `run_persistence` (a saved team holding a Robux id loads stripped, no kick, no overwrite failure);
  - `bat_rules`;
  - Competition snapshot excludes them.
- **Done:** all paths filtered, and every listed consumer is grep-verified.

**T9 · Coin purchases (Meadow Egg)** (needs T7, T8)
- **New `mountain/shared/ShopRules.luau`:** catalog `{id, kind, currency, price, section, productId=0}`.
  - `buy(p,item,receipt,now,r)` checks the receipt ledger first. If the receipt is already in the ledger it returns true with no debit and no grant.
  - It then validates the item and currency (Robux → `unavailable`), coins ≥ price and the egg cap (O6). It debits and grants an egg `{id=e<serial>, species=EggOdds.pick(section,r), origin='coin'}` into `p.eggs`, then appends the receipt.
- **Receipt ledger:** `p.receipts` is a dense array of id strings, capped at 64 with FIFO removal, like `RunRules.luau:72-73`. Validation is optional and nil-tolerant.
- **`UIProtocol.luau:3`:** new action `Buy {item, receipt}`, where the receipt matches `^[%w%-]+$` and is 8–64 characters long. Refuse it when the id is `legacy:1`, because the legacy remote has no reply cache (`Main.server.luau:326-331`). Add `Buy` to the client allowlist too (`ClientState.luau:6-7`).
- **`UIRequests.luau`:** new branch after the safe gate (`:139`, pending O13). Compute r outside, then call `P.transact(player,'buy:'..receipt, mutate)`.
  - The mutate runs once per transaction id (`Profiles.luau:99-104`).
  - On `busy`/`save_pending`, the client retries with a **new request id and the same receipt**. The same transaction id then resumes the pending commit (`Profiles.luau:97,111-113`). This is needed because `process` caches the first failure per request id (`UIRequests.luau:37,55-61`), and the handler never receives the request id (`UIRequests.luau:83`).
- **Capabilities:** shop becomes partial (`mountain/shared/UIPresentation.luau:98`; test `ui_presentation.luau:49`).
- **Tests:**
  - new `tests/shop_rules.luau`: exact debit; insufficient coins changes nothing; unknown item; Robux rejected; same receipt never double-grants; FIFO eviction; egg cap; roll uses `EggOdds`;
  - `run_persistence`/`run_ui_server.py`: `failNext`/`failAfterCommit` (`Store.luau:19-31`) give exactly one debit+grant after retry; a pending buy blocks other transaction ids;
  - `ui_protocol`: Buy validation, legacy refusal, replay returns the cached result;
  - `ui_server`: Buy branch, plus the **Bat action through the dispatcher** (no regression test exists today);
  - `StudioTests`: real JSON round trip.
- **Done:** all pass; coins and eggs are durable after a forced save failure.

**T10 · Candy Swirl skin** (needs T9)
- **Storage:** `p.cosmetics = {skins={[id]=true}, batSkin=id|nil}`. **Not** under `p.bats`, because `BatRules.normalize` rebuilds that table and drops extra keys (`BatRules.luau:14-20`; it runs at `Main.server.luau:91`).
- **Validation and load:** `valid` checks types only. Load normalization drops unknown skin ids instead of rejecting them, which avoids the settings-style lockout (`Profiles.luau:24`).
- **Buy:** goes through T9 (an already-owned skin is refused with no debit).
- **New action `Skin {op='equip'|'clear', id}`.**
- **Look:** an override in `Bats.luau:12-28` changes the look only; stats still come from the BatRules definition.
- **Tests:** `shop_rules`, `ui_protocol`, `ui_server`, `run_ui_server.py` (a legacy profile without `cosmetics` loads; ownership persists); `bat_rules` (normalize leaves `p.cosmetics` alone).
- **Done:** an equipped skin shows on the bat; knockback and reach are unchanged.

**T11 · Replace "No paid odds / No capture edge"**
- **Where:** the promise tiles at `Screens.luau:551-560` (copy at :554). This is the only P0 overflow error (`design/hud-glassbloom-handoff-2026-10-27.md:12`).
- **New copy (PROPOSED):** "Odds shown are odds used", "Robux creatures: sanctuary/tycoon only", "Never in battle or raids".
- **Done:** overflow audit shows 0 errors; the full shop body follows in P5 (`build-plan:126`).

**T12 · Regression + Studio**
- **Work:** run every suite; sync (T1) to the Glassbloom copy; play-test buy, hatch, equip-reject and the XP line; record hashes and evidence.
- **Done:** criteria at `build-plan:94`; existing toasts still fire.

## Owner decisions still missing

| # | Decision | Recommendation |
|---|---|---|
| O1 | Approve the §A numbers: sources, 50×(L+1) curve, cap 50, daily caps 20 secures / 5 repeats | Approve as proposed |
| O2 | Retroactive XP for one-time milestones | Yes |
| O3 | Level-up rewards | None for now |
| O4 | **Meadow Egg price** | Board 2,500 coins is a proposal (`index.html:638`). One Common habitat makes 60 coins/h (`TycoonConfig.luau:4`), so that is about 42 single-habitat hours. Owner to confirm or lower |
| O5 | **Which odds table the Meadow Egg uses** | Section-1 real table, 68/18/10/4 (D7 says "real odds table", `build-plan:251`). The board's 80/18/2/0 does not match any table in code |
| O6 | Grant form for the Meadow Egg | An egg into the existing incubate/hatch flow (`Rules.luau:50-61`), plus a cap on unhatched eggs (24) |
| O7 | **Candy Swirl price and in-world bat look** | Board 5,000 coins (`index.html:639`). Only the card is drawn, so atlas must supply the colours |
| O8 | Robux creatures counting toward bat index sets | No (counting them gives raid knockback and reach) |
| O9 | Robux creatures and Train/Specialize | Block (tycoon rate depends only on rarity, `Tycoon.luau:32-45`) |
| O10 | Coin-egg creatures battle-eligible | Yes (D8 restricts only Robux) |
| O11 | New pref defaults and `sprintMode` meaning | `cameraShake` true, `hudScale` .5, `altitudeRail` true, `effectsTier` 1, `sprintMode` 0 = today's device behaviour |
| O12 | Saved unknown settings keys lock out older builds (`Profiles.luau:24`) | Relax to type-check plus normalize, or accept no-rollback |
| O13 | Buying allowed mid-chase or mid-battle | After the safe gate; block in battle |
| O14 | The board's ×3 buy button (`index.html:618`) | Disabled in P2 |