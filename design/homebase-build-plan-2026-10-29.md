# Home-base build plan (layout C + tier-up VFX) — 2026-10-29

PLAN ONLY. No code, Studio, publish, product or Robux change. Owner popup answers are authority; numbers marked PROPOSED are mine and need approval at the named STOP.
Worktree `C:\Users\HOME!\Desktop\ClimbCollect\game\homebase-c`, branch `codex/homebase-c` from `codex/hud-glassbloom` `9e05af5`. Studio copy `outputs/ClimbCollect.HomeBase.Review01.rbxl`, SHA256 `249a2786f622d0cb31e34dcb71d16fbfbbeb03e02062d9d3fd0ab8cb542e705a` at start (= Glassbloom P6 save, handoff:96).
Inputs: `homebase-intel.md` (atlas, G1-G10), interview + build prompt + lake/VFX analysis + core-loop spec (legacy repo `design/`), Glassbloom handoff. Paths below are relative to `homebase-c` unless stated.
Tags: [arch] [atlas] [CB]=component-builder [motion] [DR]=design-reviewer [main]=build session inline (server/data/tests have no specialist; global rule: do inline or ask).

---
## 1. Current-state findings (file:line)

**Layout / world**
- `mountain/shared/HomeLayout.luau:4-5` plot 140x180, groundY 16, promenade 70 (channel 12 + 2 lanes 29), escape 32, `firstZ=-148`, `floorName='Plot_140x180'`. `:7` gate x4096 z-166, opening 150, towers 26x24x72. `:10-15` contents: tycoon grid 97 wide x 114.5 deep (`tycoonHalfX 48.5`, z -54.5..60 around z-16), spawn (0,-83), Incubator (-14,-83), Training (14,-83), lodge 35x30 + overhang 5.75 at z64. `:17-18` `rowPitch=148`, `southZ=436`. `:20-28` 8 plots, odd west / even east, uniform pitch. `:42-50` `span()` and `inSanctuary()` derive from plot depth.
- `mountain/tests/home_layout.luau` (105 checks per interview:49): 8 homes `:6`, footprint 140x180 `:13`, promenade edge `:16`, gate clearance `:18`, row spacing `:22`, gate distance < 722 and <= 560 `:24`, side length 584 `:27`, lanes `:29-31`, contents fit with margin 2 and clearance 3 `:34-44`.
- `mountain/world/HomePromenade.luau`: version guard `:41`, asserts old `Plot_180x220` `:42`, refits plots `:59-85` (spawn looks at the gate `:82`), clears old row `:88-97`, channel/lanes/forecourt `:99-132` (forecourt only ~6 deep: `pz0 = gate.z+12+6`), pool plaza `:134-141`, lanterns `:143-152`, plot fronts `:154-169`, dividers `:171-188`, **destroys the prototype source (`boundaries`, `env`) `:189-190`** so lantern/tree/bed/boulder survive only as clones inside v1 folders; gate `:199-248`; berm terrain keyed to `L.span()` `:267-283`, box x3600-4600, z-208..820 `:283`.
- `mountain/server/TycoonWorld.luau:21-114`: 8 habitats (`:30`), pad 36x20 `:33`, spine 10x100 `:26`, machines `:54`, bank at z+56 `:46`, legacy billboards 160x42 GothamMedium `:14-19`, creature scale .65 `:78`. Declares 110x120 grid `:1,25` (HomeLayout says 97x114.5).
- `mountain/server/Sanctuary.luau:12` looks up the floor by `L.floorName`; `:60-72` Incubator/Training markers 3x3 from `L.contents.services`; `:30-34` `ownsPosition` = inside the floor box (works unchanged for 80x100).

**Data**
- `mountain/shared/Tycoon.luau:9` `valid`: version 1, `slots` 2..8, exactly 8 habitats; `:26` ensure builds 8; `:127` `min(8,...)`. `TycoonConfig.luau:6` six `habitats` costs (2 -> 8), `:7` habitat level max 4.
- `mountain/server/Profiles.luau:20-54` `valid` (schema 1|2); `:23` requires numeric `trophies`, `competitionAt`; `:25` tycoon invalid = load refused (fail closed, store untouched); `:28` explorer type-only; `:64-70` load pipeline (migrate -> stripRobux -> Explorer.ensure -> tycoon settle); `:107` `P.transact` (durable-before-reply).
- Rank XP **already exists**: `mountain/shared/ExplorerRules.luau` (L = 40L+20, cap 49,980, L50; `:71-89` award). Secure XP today = `10*section`, 20 secures/day (`:4,81`), paid at `mountain/server/EggRaids.luau:76` only to the first carrier; the exit emits `present 'safe'` and `hud 'xp' {amount,source,level}` (`:84-85`). The arrival pop-up needs no new server event, only a client consumer.
- Rarity table exists: `TycoonConfig.luau:4` (Common..Legendary); Legendary is never an egg (`Profiles.luau:42`).

**What "Outpost / raids / party / seasons / shields" is in code (grep, 0 hits for "Outpost" in any code or homebase-c doc)**
- Outpost, vault, shields, revenge, friend raid, weekly seasons, party portal, duo seating are **design-doc only** (legacy `design/v1-big-scope-design-decisions-2026-10-28.md:14,16,23,34,62,65-67`; `design/publishing-checklist.md:66-70`; `core-loop-upgrade-spec-2026-10-28.md:27,50`).
- The only shipped PvP-ish code is the async defense/challenge system: `mountain/server/Competition.luau` (all), `UIRequests.luau:289-308`, `UIProtocol.luau:3,91,93` (`RegisterDefense`, `ChallengeDefense`), `Main.server.luau:8,320`, `Screens.luau:15-17,621-662,681,709`, `Controller.luau:162,172`, `ClientState.luau:7`, `Profiles.luau:23`, `Rules.luau:7` (trophies, competitionAt), `Main.server.luau:280` (summit +100 trophies), `Main.server.luau:282` + `world/World.luau:243` ('Competition' service dais), `UIPresentation.luau:88,93` (trophies text, `partyInvites`), `StudioTests.luau:50`.
- **Do not remove**: `EggRaids.luau`, `RaidConfig`, `RaidHazards`, `Guardians`, `Bats`, `raid_events`, `egg_raids`, `raid_hazards`, `run_raid_events.py`. "Raid" in this repo means mountain egg raids and bat theft, which stay. Removal is by exact file/symbol list below, never a regex on "raid".
- Nearby-join Guardian co-op (`UIPresentation.luau:86`) is not a party feature; see Q12.

**Motion / UI**
- `mountain/client/UI/Motion.luau` is GUI-only (alpha/scale/x/y/rot on GuiObjects, Tween-based, `:36` tokens, `:114` CAPS holo 1/shine 3/idle 6, `:129-133` gates `reduced()`/`noRays()`, `effectsTier` steps {0,.5,1} `UIProtocol.luau:6`). It has no world-space (Part) support. World VFX therefore need new `kind='world'` tokens + a small driver (see P7). Rule from Glassbloom: TweenService only inside Motion.luau for UI.
- HUD glass/pill/banner/toast/ladder recipes are in `hud-glassbloom-intel.md` (intel rows 313-365); billboards still legacy (`TycoonWorld.luau:14-19`).

---
## 2. Layout C numbers (PROPOSED unless marked) and fit

Frame: world X axis = vertical street axis `4096` (unchanged). Mountain gate stays at z -166 (Q4). Plot-local: X across frontage (-40..40), Z depth (-50 = street front, +50 = rear). Test margin 2 (usable X +-38, Z -48..48), clearance 3 between top-level rects.

| Item | Value |
|---|---|
| Plot | 80 frontage x 100 deep (`plotWidth 80`, `plotDepth 100`), `floorName 'Plot_80x100'` |
| Vertical street V | 70 (unchanged: lanes 29 + channel 12) so lanterns, kerb, channel code reuse |
| Gate plaza | 40 deep (z -154..-114), 110 wide (existing forecourt width), arrival trigger = existing gate exit box |
| Blocks | 2 plots (80 + 16 shared garden strip + 80 = 176) per side per half; 4 blocks |
| Rows (frontage z) | r1 -114..-34 (c -74), strip -34..-18, r2 -18..62 (c 22); **H street 56** 62..118 (c 90); r3 118..198 (c 158), strip 198..214, r4 214..294 (c 254). `southZ = 294` |
| Plot centre x | 4096 +-(35+50) = 4011 / 4181; yaw +-90 as today; odd west, even east; plots 1-2 nearest gate |
| H street arms | 56 wide (lanes 22 + channel 12 + 22), x +-35..+-195; pool 26x26 at the crossing (0,90); crossing plaza 70x56 |
| End plazas | W x-195..-135 collection hall + leaderboard; E x135..195 lake portal; each 60x56 |
| Basin | **kept at old extents** (half-width 215, ground to z 512): terrain berms are already written and cannot be cleanly un-written (`HomePromenade.luau:259-283`). New layout uses the north 448 studs of 590; leftover south = planted meadow + existing pool plaza moves to `southZ+40` (Q5) |
| Walk | farthest spawn (plot 8, local (0,-40)) to gate: dx 45, dz 420 = **422 studs** (limit 560, old 722). Spawn faces the street axis |

Plot-local fit (centre x,z / size w x d; "ok" = margin >= 2 and clearance >= 3 to others):

| Component | Position / size | Verdict |
|---|---|---|
| Front wall + entry frame | z -50..-47.2; gap 18; posts +-18; beam 38.5 | ok (generator already scales by `plotWidth`, `:159-168`) |
| Spawn | (0,-40) 6x6 | ok |
| Habitat yard (6) | 3 cols x 2 rows, pad 15x12 / rim 16x13, centres x -18,0,18, z -23.5 / -0.5; yard x -26..26, z -30..6 | **fits only after re-size** (old pad 36x20 cannot; 2 cols of 36 + 10 spine = 82 > 80) |
| Creature on pad | scale .65 at a 15x12 pad | **UNKNOWN**: needs per-species display-scale cap so bounds <= 11 wide (bounds not in source) |
| Conveyor spine | E-W, 6 wide, z -15..-9, x -26..26 (was 10 x 100 N-S) | ok; "eggs roll to the bank" kept, belt now 52 long |
| Bank + plinth | bank 12x6, plinth 14x8 at (31,-12): x 24..38, z -16..-8 | tight (1 stud to rims, plinth touches x 38 limit); joined to spine on purpose |
| Machines x3 (Processor/Sorter/Collector) | on spine at x -18,0,18, body 5 along x by 4 across; arch 8; pillars at +-3.2 | **tight** (1.2 studs to rims); needs arch/pillar re-proportion (old pillars +-3.8 would clip) |
| Lodge | 35x35.75 (incl. overhang at rear), centre (0,27): x -17.5..17.5, z 12..47.75 | ok (0.25 spare); interior/body colours = G1 |
| Hatchery | dais 14x14 at (-29,26): x -36..-22, z 19..33; Incubator marker 3x3 at centre | ok; hatch stage rings (r ~8) extend over lodge/yard as non-colliding VFX only |
| Training Beast pen | 14x14 at (29,26): x 22..36, z 19..33 | ok |
| Daily workout track | only 16x4 straight at x 22..38, z 40..44 (behind pen) | **does not fit as a run (>= 24)**; reserve the rear-east strip; Grip not built yet (Q8) |
| Stable | = the habitat row (creatures stand on pads, static poses); no footprint | ok if Q9 confirmed |
| Decor slots x14 | 3x3 pedestals: front row 6 at z -44.5, x +-14,+-22,+-30; west strip 5 at x -33, z -26,-17,-8,1,9; east strip 3 at x 33, z -27,1,9 | ok at 3x3 only (4x4 does not fit); **old planting beds at +-26 (`:168`) collide with front slots: move to wall corners / strip** |
| Shared garden strip | 16 x 100 between paired plots (beds, trees, boulder from harvested protos) | ok (outside plot rects) |
| Area | covered ~3,800 of 8,000 (48 %) | walkable remainder ok |

Not fitting without a decision: workout track (Q8), 4x4 decor, creature scale on small pads. Everything else fits with the sizes above.

Tier looks: same footprint, material/role swaps and added trim only (no growth in extent). Roles from intel A1 (atlas to confirm): T1 Dry-stone Yard = dryStone + stoneCoping + meadow; T2 Cedar Cloister = + cedar + pierFoot; T3 Brass & Lantern = + brass + lanternGlass + tealCornice; T4 Azure Terrace = + Azure water (`CAT:4`) + crest. No violet/neon from the reference.

Budgets (PROPOSED, P0 measures baseline first; StreamingEnabled is off so all 8 plots are resident): per owned plot <= 750 instances incl. creatures and billboards (est.: habitats 80, creatures 150, spine/bank/machines 40, hatchery 40, Beast 60, decor 110, lodge 126, frame/walls/garden 80, billboards 60); commons <= 1,500; net place <= baseline 13,707 + 4,000 (phone-candidate doc `:34`); draw calls <= 700 in any home view (measured 132-454, RPT:40); billboards <= 12 per plot, MaxDistance 45, Glassbloom tokens (G9 resolved: migrate). Unowned plots render shell only. VFX cube pool (shared, one effect at a time): effectsTier 1 = 48 cubes + 10 orbs, 0.5 = 24 + 5, 0 or Reduce effects = none, .15 s crossfade; hatch pool 16/8/0; portal rings 8/4/0 within 60 studs; non-owners see <= 50 % and only within 150 studs. Cubes: Anchored, no collide/touch/query/shadow, one `BulkMoveTo` per frame, no per-cube Tween.

---
## 3. Phases

Order: P0 -> P8. Within a phase, specialist order is architect -> atlas -> component-builder -> motion -> design-reviewer; [main] does server/data/tests. Component-builder stops if atlas has no intel for the screen. Every STOP: build session reports evidence, owner approves in a popup (recommendation first), then advance.

### P0 Safety, baseline, Studio launch  [main]
Tasks
1. Git: confirm branch `codex/homebase-c` at `9e05af5`, clean except this plan; never touch `climb-collect-integration` (uncommitted P7) or legacy `climb&collect` code.
2. SHA256 the Studio copy; must equal the hash above. Copy it byte-identical to `outputs/ClimbCollect.HomeBase.Review01.base.rbxl` (read-only baseline).
3. Studio launch (never the taskbar or an installer): `python tools/rmcp/rmcp.py call list_roblox_studios {}`; if the copy is not open, run `RobloxStudioBeta.exe <abs path to HomeBase.Review01.rbxl>`, re-list, write the new id into `tools/rmcp/x.sh`. Assert in Studio: `game.PlaceId==0`, `GameId==0`, `ReplicatedStorage.StudioAids` false, HttpEnabled false, title contains `HomeBase.Review01`, one process for that file. Other windows (Glassbloom, DRS Rush, PlaceId 112921656767061, PhoneCandidate) are never focused for save.
4. Source reconcile: `python tools/rmcp/sync_hud.py <id> --dry --changed 9e05af5`, then per-source checksum repo vs Studio (all `mountain/{server,shared,client}`); expect 0 drift, else stop.
5. Baseline: `bash tools/run_all_tests.sh` (Glassbloom P6 recorded 40/40; record today's count), overflow audit 186 screens x 6 sizes, state audit, HUD rest descendants (499), place instance count, per-plot subtree counts, draw calls and 10 s frame samples at 8 home views (focus the title bar first; discard samples with GPU ~ 0), emulator iPhone 16 Pro.
6. Harvest prototypes before any teardown: clone lantern, tree, planting bed, boulder, lodge reference from `Sanctuary.HomePromenade` (`Lanterns`, `Dividers`, `PlotFronts`) into `ServerStorage.HomeProtos` and dump a descriptor JSON (part names, sizes, colours, materials). This also answers G1 for all baked parts.
7. Write `design/homebase-handoff-2026-10-29.md` (running log) and the evidence dir `evidence/homebase_2026-10-29/`.
Done: baseline JSON + counts committed; budgets above restated with measured numbers.
**STOP 1** Evidence: hash match, Studio id/PlaceId/StudioAids assertions, 0 source drift, baseline test/audit/perf JSON, protos harvested. Owner approves: measured baseline, the instance/draw-call/cube budgets, and answers to Q1-Q6, Q10 (they block P1-P3).

### P1 Removal: Outpost-family, raids-PvP, party, seasons, shields  [main]
Code (exact):
- Delete `mountain/server/Competition.luau`.
- `mountain/shared/UIProtocol.luau:3,91,93` drop `RegisterDefense`, `ChallengeDefense`; `mountain/client/UI/ClientState.luau:7` same.
- `mountain/server/UIRequests.luau:289-308` remove both branches; `Main.server.luau:8,320` drop require and `competition=`; `:280` remove `p.trophies+=100` (coins stay); `:282` and `world/World.luau:243` drop the 'Competition' service/dais.
- UI: `Screens.luau` remove Social tabs `Party/Challenges/Defense` (`:15`), aliases (`:16-17`), party block (`:621-632`), defense blocks (`:650-662`), trophy tiles (`:681,709` -> rank/XP, from `Explorer.summary`); `Controller.luau:162,172` and `hubNames`/dock `Social` per Q3; `UIPresentation.luau:88` text, `:93` delete `partyInvites`.
- Schema: **keep** `trophies` and `competitionAt` in `Rules.newProfile` and `Profiles.valid` (`:23`) as inert numbers for now (old builds require them); stop reading/writing them. Retire them in a later step once a tolerant build exists (T0 lesson, handoff:28).
- `mountain/server/StudioTests.luau:50` drop the Competition check.
Tests (exact): `tests/ui_server.luau:12,20,122-123`, `tests/ui_protocol.luau:10`, `tests/ui_presentation.luau:49`, `tests/combat_raids.luau:98-131` (Competition snapshot/Q4 coin-win cases only; keep the Robux-origin cases above it) and `tests/run_combat_raids.py:4` (no longer loads Competition), plus `service_harness.py` and `run_ui_server.py` references found by test run. Replace the ui_protocol/ui_server assertions with "removed action is rejected as Unknown action".
Docs (legacy repo, banner "SUPERSEDED 2026-10-29" only, no rewrites; needs Q17): `design/v1-big-scope-design-decisions-2026-10-28.md:14,16,23,34,62,65-67`, `design/publishing-checklist.md:66-70` (C01-C05; add the seasons/titles item if present), `design/core-loop-upgrade-spec-2026-10-28.md:27,50`; memory `release-decisions-2026-10-28.md` and the Obsidian Climb & Collect decisions note (orchestrator updates vault). Dailies copy and shop: no shield items exist in code; just ensure Shop/Quests copy never mentions shields or seasons (grep `Shop.luau`, `Screens.luau`).
Done: `rg -i "ChallengeDefense|RegisterDefense|Competition|partyInvites|'Party'"` in `mountain/` = 0 (excluding `evidence/`); all suites green with the removals; overflow audit 0 errors; EggRaids/Bats/Guardians suites unchanged.
**STOP 2** Evidence: diff list, grep = 0, suites (count and names), overflow/state audit, Studio sync of the changed set, console clean, screenshot of the hub list. Owner approves: the removal list (incl. Q2 Competition, Q3 Social hub fate) and doc banners.

### P2 Server data and rules (tier, decor, rank XP, rarity XP)  [main]
Design
- New shared pure modules (CLI-testable): `mountain/shared/HomeRules.luau`, `HomeTiers.luau` (4 tiers: name, role tokens, habitat-level cap, usable decor slots, rank threshold). Rank XP stays in `p.explorer` (no new rank subrecord: Q-note below).
- `p.home = {v=1, tier=1..4, decor={[1..14]={kind='creature',id=string}}}`; one creature may stand in only one place (habitat or display); id must be owned. Props kind accepted only if Q6 later adds a catalog (list empty).
- PROPOSED numbers (approve at STOP 3): tier thresholds by rank level L5 / L15 / L30 (XP 480 / 4,480 / 17,980); habitat comfort cap 1/2/3/4; usable decor slots 4/7/10/14; tier-up itself costs no coins, the upgrades it unlocks still do.
- Secure XP by rarity (replaces `10*section`, `ExplorerRules.award` secure branch): Common 6, Uncommon 12, Rare 30, Epic 70, Mythic 150; Legendary n/a (Trial capture XP stays derived). Keep: first carrier only, 20 secures/day, species ledger +50, Robux-origin earns 0. Max 1,400 XP/day (all Epic). Stored `repeatXp` is unchanged in shape, so no profile migration for XP.
- Habitats 6: keep `tycoon.version=1` and the 8-entry array (rollback-safe); cap `slots` at 6 in rules/UI, drop the last two `habitats` costs (750, 1200). Load migration (same write as load, `Profiles.load`): creatures in habitats 7-8 are unassigned (kept in collection), stored eggs there move to the bag/bank path, refund of spent module coins is PROPOSED (Q10).
- Fail closed: `Home.valid` strict; `Profiles.valid` refuses a profile whose `home` is malformed or `v` is newer than known (store untouched, same as tycoon `:25`); absent `home` is seeded by `Home.ensure` (tier 1, no decor). Tier-up and decor writes go through `P.transact` and the client effect fires only after the commit. Client never sends tier or XP.
- New actions (UIProtocol strict validators, correlated ids, `atHome` required): `Home{op='tier'}`, `Home{op='place',slot,id}`, `Home{op='clear',slot}`, `Inspect{plot,kind,index}` (any player, read-only snapshot of a displayed creature: species, level, rarity, owner name; rate-limited; never exposes inventory). Tier-up also enforced server-side against `Explorer.summary(p).level`.
- Events: server publishes `ui.home` (tier, caps, decor) in `s.ui`; reuse existing `hud 'safe'`/`'xp'` for the arrival pop-up.
Tests (new): `tests/home_rules.luau` (tier gates, thresholds, caps, decor ownership/uniqueness/slot bounds/replay), `tests/home_profile.luau` (valid/ensure/future-version refusal/malformed refusal/migration incl. 7-8 habitats/old profile with no `home`), extend `tests/explorer_rules.luau` (rarity table, cap, stolen = 0, Robux = 0), `tests/ui_protocol.luau`, `tests/ui_server.luau`, `tycoon*.luau` (6-slot cap), `run_persistence` (transact failure leaves tier unchanged). Mutation-check the new gates.
Done: all suites green; new suite counts recorded; sync to Studio via `sync_hud.py <id> --changed 9e05af5`; live QA: refusals correct, no debit, console clean.
**STOP 3** Evidence: suite list with counts, schema doc (`design/homebase-schema-2026-10-29.md`), migration table, live refusal log. Owner approves: tier trigger (Q1), all PROPOSED numbers above, Q6/Q10 outcomes, fail-closed behaviour.

### P3 Layout C geometry, HomeLayout rewrite, checks  [atlas] -> [CB] -> [main]
Order: atlas pass 2 first.
1. [atlas] extend `homebase-intel.md`: sample the harvested protos (G1), confirm tier role table (G5, owner names fixed), commons item tokens (G6 sizes in section 2 become the brief), Glassbloom board/shrine/pop-up recipes from the unread intel §3+ (G8), billboard migration spec (G9), resolve G7 with the 60 FPS owner choice. Deliver `design/homebase-intel.md` v2. Gaps stay listed, nothing invented.
2. [main] rewrite `HomeLayout.luau`: `plotWidth 80`, `plotDepth 100`, `strip 16`, `gatePlaza 40`, `crossWidth 56`, explicit `rows` z-centres (no uniform `rowPitch`), `basin` constants for `span()`/terrain, `commons` rects, `contents` per section 2, `floorName 'Plot_80x100'`; keep `toWorld/facing/extent/gateDistance` API. Rewrite `tests/home_layout.luau` (~110-130 checks): footprints, promenade edge, strip 16 between paired plots, H street 56 between r2/r3, symmetry, gate clearance >= plaza, farthest walk <= 560 (expect 422), arms/commons inside basin, commons rects clear of plots, every plot-local rect fits (margin 2, clearance 3, documented exceptions), 6 habitats pairwise clear, 14 decor slots unique and inside, spawn faces the street, region of `inSanctuary` still covers commons. Update `tests/run_context.py:6-22` and `tools/promenade_scene_check.luau`, `tools/promenade_walk.client.luau`.
3. [CB] generator `mountain/world/HomeCommons.luau` (v2 of `HomePromenade`, `PromenadeVersion=2`): tear down v1 (`Sanctuary.HomePromenade`, resize floors to `Plot_80x100`, accept the existing `Plot_140x180` name), rebuild ground, streets, channel + crossing pool, gate plaza, lanterns, plot shells (floor, front wall/frame, side walls, garden strips from `HomeProtos`), move `Lodge_0i` models by name into the new frames, spawn facing the street. Grey-box only: no habitats, no commons props yet. Keep terrain and gate untouched (basin kept).
4. [main] `Sanctuary.luau` services from new `contents`; sync; walk test 8 plots (natural spawn -> gate, avatar legs as in `tools/promenade_walk.client.luau`).
Done: layout tests green, scene check green, 8 spawns reach the gate, no part outside the basin, instance count within budget, console clean.
**STOP 4** Evidence: layout test output, scene check, walk JSON (8 legs), top-down + 3 avatar-height captures of each street and one shared garden, instance/draw-call delta vs P0. Owner approves: the grey-box layout (feel of cross, widths, walk time), Q4/Q5 resolved as built.

### P4 Plot build  [CB] (after STOP 4; atlas intel v2 required)
Order inside the phase: habitats + production -> hatchery -> Training Beast -> decor slots -> tier looks. One task at a time, Studio capture each.
1. Rewrite `TycoonWorld.luau` to the 6-habitat yard (section 2 sizes), E-W spine, bank, 3 resized machines, themed habitat set per kingdom accent (existing `CAT` accents), creatures standing static, display-scale cap; billboards migrated to Glassbloom tokens (`W.glass`/`W.pill` recipes, `t.beacon` 12 FO, <= 12 per plot).
2. Hatchery: dais + Incubator pedestal + stage anchor (empty ring/cube anchor parts for P7), prompt wiring to `Incubate/Hatch` (`UIRequests.luau:232-244`) unchanged.
3. Training Beast: model + pen + prompt that opens the existing Train tab (`Train` 15 coins, +80 XP, `UIRequests.luau:252-268`); Grip is not built (Q8): prompt shows no Grip stat.
4. 14 decor pedestals from `HomeRules` slot table; locked slots visibly capped by tier; creature display uses static pose; visitor Inspect prompt on habitats/displays.
5. Tier looks: `HomeTiers` role tables drive 4 part sets tagged `TierPart`; only the current tier exists in the world (built on demand); server `SetAttribute('Tier')`.
6. Spawn facing the street; lodge and entry unchanged.
Done: owner/visitor checks in a 2-client Studio session (owner works, visitor only inspects), per-plot instances <= budget, creature bounds inside pad, all 4 tiers capture-able via a Studio-only dev action (stripped from release), prompts reachable, console clean.
**STOP 5** Evidence: per-tier plot captures (4), habitat/hatchery/Beast/decor captures, instance + draw-call table per plot, 2-client log. Owner approves: plot look per tier, display scale, Q8/Q9/Q13 outcomes.

### P5 Commons build  [CB]
Tasks (one at a time): gate plaza (paving, lanterns, arrival marker line) -> crossing plaza (pool, notice board frame, streak shrine) -> W end plaza (collection hall + leaderboard stand) -> E end plaza (lake portal frame: static, prompt says the lake opens later) -> arm alleys and plot side walls -> south meadow. Reuse existing materials only (intel A1); hall/shrine/portal forms need atlas rows (G6) before building. Leaderboard shows this server's players by `Explorer.xp` (Q11).
Done: commons <= 1,500 instances, all prompts work, no walkable gap/trap, 8-client spawn flow still reaches the gate, console clean.
**STOP 6** Evidence: captures per commons item at avatar height, walk legs plot -> each item, instance delta. Owner approves: commons look/placement and what the portal and hall do for now.

### P6 UI  [atlas] -> [CB]
Atlas rows first (arrival pop-up, board, shrine, billboards, inspect card, tier-up button) from Glassbloom intel; then component-builder one screen at a time using existing kit (`W.glass`, `W.pill`, banner/toast/moment, `ladder`, `row`):
1. Arrival pop-up: queued in `Feedback` tier-2/3 moment from `hud 'safe'` + `'xp'` (species, rarity, +XP, level bar, coins per Q7); 44 px Continue; no gameplay lock.
2. Notice board panel (dailies from mountain/lake/home quests only; existing Quests data) and streak shrine (ladder of days, claimed/ready/locked).
3. Plot panel in the Sanctuary hub: tier card (requirement, "Raise plot" button), habitat level cap, decor slot list with place/clear.
4. Visitor inspect card (read-only).
5. Social hub per Q3 (leaderboard tab), Profile rank text.
6. World billboards (Glassbloom).
Done: overflow audit 6 sizes 0 errors over the new screens, state audit 0, 44 px hit areas, HUD rest descendants <= 726, Shop open unchanged, console clean, every new button selectable (gamepad).
**STOP 7** Evidence: screen captures at 844x411 custom device + 749x330, audit JSONs, descendants count. Owner approves: screen copy and layouts.

### P7 Motion  [motion]
All timing through `Motion.luau`; no TweenService outside it. Tasks:
1. Add world tokens to `Motion.luau` (`kind='world'`: `tier.up`, `hatch.stage`, `portal.open`, data from intel D/E/D2 beat sheets: tier-up 1.0 s anticipation, 1.5-2.5 deconstruct, 2.5-4.5 swirl, 4.5-5.0 contract, 5.0-6.0 reconstruct, hold to 6.5) plus `M.worldCaps()` returning cube/orb/ring caps by `effectsTier` and 0 under `reduced()`.
2. New client driver `mountain/client/WorldFx.client.luau`: one shared capped pool, one Heartbeat step + `BulkMoveTo`, rings via thin Parts, skippable (tap/Esc/Skip), ends within effect time, camera untouched.
3. Tier-up: server commits tier -> event -> client hides old `TierPart`s locally, swirl recolours old -> new tier tokens inside the swirl, server swaps parts at a fixed delay (~3.0 s) independent of the client, client reveals; other clients within 150 studs get the 50 % version, others just see the swap.
4. Hatch stage: charge-up, orbit rings, flash, halo scaled by rarity (common fast), confetti scaled; Glassbloom strip stays the UI.
5. Portal: idle static, open effect on approach (<= 60 studs), 1 portal loop cap.
6. Arrival pop-up and panel transitions as UI tokens (existing patterns).
Done: loops at rest 0 (world fx idle = none), Reduce effects and LOW: no cubes/rings, instant or .15 s crossfade, skip works mid-effect, cube pool never exceeds cap (stats probe), frame sample during effect: median holds, worst <= 33 ms on emulator, no gameplay lock.
**STOP 8** Evidence: frame-sequence sheets of tier-up (4 transitions), hatch (Common and Epic), portal; Reduce/LOW sheets; pool/caps probe; perf samples. Owner approves: motion as captured; owner VFX references (Q16) compared.

### P8 Review and QA  [DR] + [main]
1. [DR] read-only review against intel v2 and the two design docs: palette traceability (every value cited or deleted), readability at phone size, tier legibility, commons hierarchy, motion restraint. Findings returned as a list; fixes go back through component-builder/motion, then re-review.
2. [main] QA: full suite run; overflow and state audits; phone emulator (iPhone 16 Pro + custom 844x411); perf at 8 owned plots: median frame 16.7 ms (60 FPS) on the emulator, no frame > 33 ms outside VFX, instance and draw-call budgets, memory sample; 2-client and, if hardware allows, 4- and 8-client sessions (`tools` multi-client pattern; mark UNVERIFIED if not run); persistence mock-store paths (real DataStore stays UNVERIFIED); regression of mountain flow (secure -> arrival pop-up -> habitat assign -> production -> bank) via natural movement; removed-feature grep = 0.
3. Save: see section 6, then SHA256 and commit; handoff doc.
**STOP 9** Evidence: DR report, QA JSONs, perf table, hash + save record, open-risk list. Owner approves: Review01 as the home-base milestone (still local, unpublished); decides next build (forest world / sky menu / Grip).

---
## 4. Specialist routing (first to last)
architect (this plan) -> atlas (P3 pass 2, P6 rows) -> [main] P0-P2 (no specialist) -> component-builder (P3 generator, P4, P5, P6) -> motion (P7) -> design-reviewer (P8) -> [main] QA/save. Atlas must precede every component-builder task that introduces a design value. Design-reviewer is read-only and runs last.

---
## 5. Open owner questions (ask in popups; recommendation first)
| # | Question | Recommended | Blocks |
|---|---|---|---|
| Q1 | What triggers a plot tier: rank level, coins, or both? | Rank level (L5/L15/L30, free), coins only for the upgrades it unlocks | P2 |
| Q2 | Remove the shipped async Defense/Challenge system (`Competition.luau`, trophies) as the "Outpost/raids" code? Outpost itself is not in code. | Yes, remove entirely | P1 |
| Q3 | Social hub after Party/Challenges/Defense go: delete, or keep one Leaderboard tab? | Keep hub with Leaderboard only | P1, P6 |
| Q4 | Concept says gate at the "south end"; in the world the gate must stay at the mountain end (z -166, terrain/exits baked). Confirm. | Confirm: gate stays | P3 |
| Q5 | Keep the old basin footprint and leave the unused south ~142 studs as planted meadow, or shrink the basin? | Keep (terrain already written) | P3 |
| Q6 | What fills the 14 decor slots: owned creatures only, or also coin-bought props (needs a catalog and prices)? | Creatures only in this build | P2, P4 |
| Q7 | Arrival pop-up "coins": no direct coin grant exists. Show XP + level + pending bank/income instead? | Yes, no new coin source | P6 |
| Q8 | Training Beast: structure + existing Train action now, Grip stat and workout track later (Grip numbers are open in the core-loop spec)? | Yes | P4 |
| Q9 | Stable = the habitat row (no separate building)? | Yes | P4 |
| Q10 | Players with habitat modules 7-8: unassign creatures and refund the spent coins (750/1200)? | Yes, refund | P2 |
| Q11 | Leaderboard: this server's players only (global needs OrderedDataStore and a published place)? | Server-local now | P5, P6 |
| Q12 | Nearby-join Guardian co-op (`UIPresentation.luau:86`) stays? Party removal does not touch it. | Keep | none |
| Q13 | Keep the 3 automation machines (resized) or cut them? | Keep resized | P4 |
| Q14 | 60 FPS median on a phone can only be proxied by the desktop emulator; physical iPhone test stays open. Accept? | Accept, test on device later | P8 |
| Q15 | Approve PROPOSED numbers: tier thresholds, caps, slot unlocks, rarity XP, budgets. | Approve at STOP 3 / STOP 1 | P2 |
| Q16 | Any further owner VFX references for tier-up beyond `references/lake-world/02-04`? | No, use 02-04 | P7 |
| Q17 | OK to add "SUPERSEDED" banners to docs in the legacy repo (it has uncommitted work on another branch)? | Yes, banner lines only | P1 |
Also noted: rank XP needs no new subrecord because `p.explorer` already is rank XP (Glassbloom P2). The owner's "rank XP subrecord" is satisfied by changing the secure formula.

---
## 6. Risks and rules
- **Other work**: `climb-collect-integration` has uncommitted P7 work: read only, never edit, never sync from it. Legacy `Desktop\climb&collect` is on `codex/expedition-fairground` with untracked files: no code edits, doc banners only with Q17, no commits there. Two other Studio windows may be open; focus only the HomeBase window.
- **Studio save rules**: save only the HomeBase copy; before Ctrl+S assert `PlaceId==0`, `StudioAids==false`, HttpEnabled off, emulator back on iPhone 16 Pro, single Studio process, title `...ClimbCollect.HomeBase.Review01.rbxl`; computer use (Roblox Studio full + File Explorer click-only) has been denied at save time before, so request it again at the save step and keep everything reproducible via `sync_hud.py <id> --changed 9e05af5`. Never Ctrl+S in the base place, PhoneCandidate or any published place; never the taskbar. Record SHA256 after each save.
- **Prototype loss** (`HomePromenade.luau:189-190`): harvest in P0 or v2 cannot rebuild lantern/tree/bed/boulder.
- **Terrain/basin**: v1 berms are written against the old span and cannot be un-written; basin stays, contents shrink.
- **Forward/backward compatibility**: new `home` key is ignored by older `valid` (it checks listed keys only), but tycoon stays v1/8 entries and `trophies`/`competitionAt` stay present. Release order (T0 lesson): a tolerant build ships before one that depends on new keys. No publishing is authorised here.
- **"raid" collisions**: delete by symbol list only (section 3 P1).
- **Motion**: GUI-only today; world fx need new tokens + driver; keep caps, Reduce effects, LOW and skip or the phone floor breaks.
- **Perf**: StreamingEnabled off, 8 plots resident; billboards, creatures (bounds unknown) and cubes are the swing factors; measure after each phase, not only at P8.
- **Unknowns**: lodge interior and baked colours (G1, answered by harvest), real DataStore behaviour (mock only), physical phone FPS, 8-client hardware, creature display bounds.
- **Visitors**: Inspect is a new unauthenticated-read surface: strict validator, rate limit, only displayed creatures, no inventory or coins.
- **Tier swap race**: server swap time must not depend on the client; a skipped or disconnected client must still end in the correct tier look.
- Hard rules: no publishing, products or Robux; design values only from project references (intel A1/A4); phone 44 px targets; ask decisions in popups, concise.

## 7. Hand-off: first task for the build session
P0 task 1-3: verify branch `codex/homebase-c` at `9e05af5`, compute SHA256 of `outputs/ClimbCollect.HomeBase.Review01.rbxl` (expect `249a2786...e705a`), launch or attach the Studio window for that exact file, and assert `PlaceId==0`, `StudioAids==false`, HttpEnabled off. Write the result to `evidence/homebase_2026-10-29/p0/launch.json`, then continue with P0 tasks 4-7. Do not start P1 before STOP 1.

## 6. Owner answers (popups, 2026-10-29, before STOP 0)
- Tiers: 4 (Dry-stone Yard, Cedar Cloister, Brass & Lantern, Azure Terrace); tier only unlocks the right to buy upgrades (habitat level cap + usable decor slots); phone target 60 FPS median; billboards migrate to Glassbloom.
- Q1: tier needs rank level AND coins (thresholds/fees PROPOSED, tune at STOP 3).
- Q2/Q3: remove Competition.luau + trophies and Party/Challenge/Defense tabs; keep Social hub with Leaderboard only.
- Q6: decor slots take owned creatures AND coin-bought props. **New work:** prop catalog, prices, per-tier availability, save subrecord entries; propose list at P2 for owner approval (no Robux; coin only).
- Q10: habitat modules 7-8: unassign creatures and refund spent coins.
- Not yet answered: Q4, Q5, Q7-Q9, Q11-Q17 (plan recommendations stand unless the owner overrides at STOP 0).
- STOP 0 approved (owner prompt, 2026-10-29); Q17 approved by default.

## 7. Progress
- **P0 done (2026-10-29), STOP 1 pending.** Hash match, Studio id `c7a0a682…`, PlaceId 0 / StudioAids false / Http off, 0 drift, 40/40 suites, HUD audits = P6, protos in `ServerStorage.HomeProtos`. Measured baseline (supersedes the §2 figures): place 15,812 edit (workspace runtime 10,432), 8 home views median 16.6-16.7 ms / p95 <= 18.1 / 222-525 draw calls. Restated budgets: net place <= 15,812 + 4,000; draw calls <= 700; per plot <= 750. Details: `design/homebase-handoff-2026-10-29.md`.
- STOP 1 approved (owner popup, 2026-10-29): baseline + budgets; Q4 gate stays; Q5 basin kept; save deferred to after P1.
- **P1 done (2026-10-29), STOP 2 pending.** `f666634`: Competition/defense/party removed, Social = Leaderboard, trophy UI -> rank; 40/40 suites; overflow 174x6 and state audit 0; synced, drift 0; legacy banners added. Copy not saved yet.
- STOP 2 approved (owner popup); copy saved after P1: SHA256 02be7adf...464c (1,474,979 bytes). Next: P2.
- **P2 done (2026-10-29), STOP 3 pending.** `88eb572`: `HomeTiers`/`HomeRules`, `p.home` v1 {tier, decor, stock}; tier = rank AND coins (L5/15/30, 1,000/5,000/15,000 PROPOSED); comfort cap 1-4, usable slots 4/7/10/14; 6 coin props 150-2,500 (PROPOSED); secure XP by rarity; 6 habitats, 7-8 refunded on load; Home/Inspect actions; fail closed. 42/42 suites, 30/30 mutants, live refusals no debit, console clean, HUD audits 0. Schema: `design/homebase-schema-2026-10-29.md`. Copy not saved since P1.
- **STOP 3 approved** (owner popup, 2026-10-29): tiers, props, rarity XP, 7-8 migration and fail-closed load as built; **secure daily cap removed** (owner wants grind). 42/42 suites, 31/31 mutants. Copy saved after P2: SHA256 4017297b...98f8 (1,479,481 bytes). Next: P3 (atlas pass 2 first).
