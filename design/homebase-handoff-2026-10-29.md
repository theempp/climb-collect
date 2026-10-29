# Home-base build handoff — 2026-10-29

Plan: `design/homebase-build-plan-2026-10-29.md` (§6 owner answers). Branch `codex/homebase-c`. Evidence: `evidence/homebase_2026-10-29/`.

## Studio
- Copy `outputs/ClimbCollect.HomeBase.Review01.rbxl`, SHA256 `249a2786…e705a` verified; byte copy `outputs/ClimbCollect.HomeBase.Review01.base.rbxl` (read-only attribute, same hash). **Not saved since launch.**
- Launched with `RobloxStudioBeta.exe <abs path>` (own process). MCP id this launch: `c7a0a682-e3cc-46eb-be16-0add7d9ef30c` (`x.sh` updated). PlaceId 0, GameId 0, `StudioAids` attribute false, HttpEnabled false, one process for the file.
- Other window open: integration Glassbloom (`climb-collect-integration`, id `173421a6…`) — never focus, sync or save there.
- Focus for perf samples: `SetForegroundWindow` on the HomeBase PID only (PowerShell, Alt-key trick), foreground PID verified before sampling.

## P0 results (`p0/baseline.json`)
- Source drift: 63/63 match (`p0/drift.json`); `StudioTests` absent by design (sync SKIP).
- Suites 40/40 pass (`p0/suites.txt`).
- HUD (`p0/checks/`, `p6_checks.sh`): overflow 186 screens × 6 sizes 0 errors; state audit 0, coverage rest 10.9 / chase 10.4 %; rest 499, Shop 1,747; rest avg 16.6 / worst 20.2 ms, Shop worst 20.4 ms, 0 > 33 ms; 90 Robux buttons disabled, 0 unselectable; motion caps as P6; console clean.
- Place: edit descendants 15,526 (15,812 after HomeProtos); workspace edit 8,755, runtime 10,432; Sanctuary 2,780 (promenade 1,497, lodges 1,032, gate 151, plots 96). Per plot: folder 11 (runtime 142), lodge 128, other parts in rect 35–36. Plan's 13,707 figure is superseded by these numbers.
- Home views (`p0/home_views.json`, focused, desktop GPU ~1 ms): median 16.6–16.7 ms, p95 ≤ 18.1, worst ≤ 20.6, 222–525 draw calls, 335k–514k triangles. Not a device measurement.
- Emulator: edit viewport 750×401 (active; device id not readable by script).
- Protos (`p0/protos.json`) in `ServerStorage.HomeProtos`: Lantern 5 parts (placed scale 1.7), Tree 13 (2.2; two neighbour boughs trimmed), PlantingBed 11 (1.4), Boulder 1 (2.5), Divider_01 116, Lodge_01 126. Descriptor has sizes/offsets/colours/materials; divide sizes by `PlacedScale` for the original proto.
- New QA scripts: `tools/rmcp/qa/home_views.client.luau`, `tools/rmcp/qa/plot_counts.luau`.

## P1 results (`p1/summary.json`), STOP 2 pending
- Commit `f666634`: `Competition.luau` deleted; `RegisterDefense`/`ChallengeDefense` removed from UIProtocol, ClientState, UIRequests (now "Unknown action."); Main drops the require, `competition=` and summit `trophies+=100` (coins stay); 'Competition' dais removed from `World.luau` (no baked dais existed in the place); Social hub = one Leaderboard tab (honest "coming soon" until P5/P6); Profile Trophies tile/banner → Rank from `ui.explorer`; Controller party re-render and challenge reveal removed; `partyInvites`/`defenses` capabilities removed; StudioTests defense checks dropped; tools `audit_saved.py`/`sync_edit.luau` no longer list Competition.
- Inert: `trophies`, `competitionAt` stay in `Rules.newProfile` and `Profiles.valid`. Kept: EggRaids, RaidConfig, RaidHazards, Guardians, Bats, Guardian co-op join. "shield" hits in code are UI shape images and a combat buff, not PvP shields.
- Suites 40/40 (ui_server 66, run_combat_raids 43; raid/bat/guardian suites unchanged). Grep: only the three new rejection assertions.
- Studio: `sync_hud.py <id> --changed 9e05af5` + `ServerStorage.MountainWorld.World` source (was equal to the pre-edit repo) + Competition module destroyed; drift 0. Overflow 174 screens × 6 sizes 0 errors; state audit 0; rest 499, Shop 1,747, worst 21.8 ms; console clean. StudioAids false, PlaceId 0. Copy **not saved**.
- Legacy repo: SUPERSEDED banner lines in 3 docs (no commits there); memory `release-decisions-2026-10-28` and vault Decisions marked superseded.
- **STOP 2 approved** (owner popup, 2026-10-29). **Saved** 22:03 (Ctrl+S via PowerShell foreground on PID 9788 only, title verified; PlaceId 0, StudioAids false, Http off, single process, viewport 750×401). SHA256 `02be7adf03be4dfdfdb4127f4dcde8129de426d9c141ea105bfd64e8b40e464c`, 1,474,979 bytes; base copy unchanged (`249a2786…`). Contains P1 build + `ServerStorage.HomeProtos` (binary strings are compressed, so not grep-verified; a cold-open check is still to do). Next: P2 server data/rules.

## P2 results (`p2/`), STOP 3 pending
- Cold open (`p2/coldopen_drift.json`): HomeBase was closed, relaunched with `RobloxStudioBeta.exe <abs path>` (PID 4744), MCP id `096c538f-48c2-402e-9278-00704bc725e2` (`x.sh` updated). Saved copy `02be7adf…` opens with `ServerStorage.HomeProtos` (6 protos), no Competition module, P1 protocol; PlaceId 0, StudioAids false, Http off; drift 62/63 (StudioTests absent by design). New tool `tools/rmcp/drift.py <id> [out]`.
- Commit `88eb572`. Schema + numbers + migration table: `design/homebase-schema-2026-10-29.md`. All numbers PROPOSED.
- Suites 42/42 (`p2/suites.txt`): new home_rules 91, home_profile 15; explorer_rules 115, egg_raids 36, tycoon 71, tycoon_economy 109, ui_protocol 126, ui_server 87, run_persistence 73. Mutations `tools/mutate_home.py`: 30/30 killed (`p2/mutation.json`).
- Studio: `sync_hud.py <id> --changed 9e05af5` (+HomeRules, +HomeTiers created); drift 64/65 (`p2/drift.json`). Live QA (`p2/live_qa.json`, `tools/rmcp/qa/home_p2_live.client.luau`, fresh profile rank 1 / 0 coins, plot 1): 13 refusals with the right message, place/inspect/clear commit, coins 0 -> 0; console 0 errors/warnings. HUD audits (`p2/checks/`): overflow 174 × 6 0, state 0, rest 499, Shop 1,747, rest worst 21.4 / Shop 20.9 ms. StudioAids false, PlaceId 0. **Copy not saved after P2.**
- Gotcha: the Bash tool unescapes `\` and `\n` inside heredocs; write patch scripts with Write, then run them.
- Not live-verified (needs coins/XP fixtures in Play): successful tier raise and prop buy, 7-8 refund on a real saved profile. Covered by run_persistence/ui_server.
- Open: no player notice for the 7-8 refund (P6); `TycoonWorld` still builds 8 habitat pads (P4 rewrite).
- **STOP 3 approved** (owner popup): all as built except **no daily secure-XP cap** (owner wants grind; monetisation later). `ExplorerRules.secureCountMax` bounds the daily counter only. 42/42 suites (explorer_rules 116), 31/31 mutants.
- **Saved** 22:35 after STOP 3 (PowerShell foreground on PID 4744 only, title verified; PlaceId 0, StudioAids false, Http off; Glassbloom PID 2060 untouched). SHA256 `4017297bff61e2374eb345f92c490ab4ad699b13d32440667c6b5730932d98f8`, 1,479,481 bytes; base copy unchanged (`249a2786…`). Contains the P2 build (HomeRules/HomeTiers). Next: P3 layout C (atlas pass 2 → HomeLayout rewrite → grey-box generator).
- New-chat prompt for P3: `design/homebase-p3-new-chat-prompt-2026-10-29.md`.

## P3 results (`p3/summary.json`), STOP 4 pending
- Studio relaunched (HomeBase was closed): id `88277537…`, then **22:51 an external `RobloxStudioInstaller.exe` ran and crashed (WER), closing both Studio windows** (incl. integration Glassbloom, never touched here). HomeBase hash unchanged; relaunched, id `2b170ad3-ccbf-4036-910c-158f7a568684` (`x.sh`). PlaceId 0, StudioAids false, Http off.
- Atlas intel v2 `5002538`: protos A5, tier roles A6, prop scales A7, billboard map A8, commons C1, UI recipes C2. Open: plot floor/edge tokens (baked plotFloor #7E9D84 / plotEdge #D6DFD0 match K, measured in Studio), hedge prop scale, basin form (G11), pedestal, five commons forms, screen layouts. Contradictions for STOP 5: `HomeTiers` `azureWater` vs K `water`; T1 entry frame already uses cedar/brass/teal (tier swap scope = swapped parts only, recommended); per-plot 750 x 8 + 1,500 > +4,000 net only works because v1 parts are replaced.
- `HomeLayout` v2 `5785a99`: rows -74/22/158/254, strip 16, H street 62..118, southZ 294, poolZ 334, basin kept (span unchanged, half 215, south 436). Contents per plan §2 (workout reserve shrunk to 14 wide: side wall at x 37.2..40). Tests 230 checks.
- `HomeCommons` `3fdae1f`: v1 promenade (1,463 parts) replaced by 761; `apply(s,w,{rebuild=true})` rebuilds in Edit without moving plots twice. Main requires HomeCommons (no-op at v2). Pushed by hand to `ServerStorage.MountainWorld.HomeCommons`; HomePromenade module still present (unused).
- Change vs plan §2: channels stop at the crossing plaza edges; the 26x26 pool sits alone in a paved 70x56 square (otherwise the V channel splits west/east with no crossing).
- Evidence `p3/`: home_layout.txt, scene_check.json, walk.json, home_views.json, plot_counts.json, drift.json, console_play.txt, captures/01-08, suites.txt (42/42).
- Perf gotcha: the Claude app retakes focus mid-sample; a PowerShell background job re-focusing the HomeBase PID every 0.5 s during the call works (views 5-7 still show a few throttle frames at p95).
- **STOP 4 approved** (owner popup): layout as built, paved crossing kept. **Saved** 23:15 (PowerShell foreground on PID 33312 only, title verified; PlaceId 0, StudioAids false, Http off, not running, one process). SHA256 `829a5a9c1e1d97cf21167d78dc71564769e5b9640801e71efacdbad253270b79`, 1,483,149 bytes; base copy unchanged (`249a2786…`). Contains HomeCommons v2 + `ServerStorage.MountainWorld.HomeCommons`. Next: P4 plot build (TycoonWorld rewrite to the 6-habitat yard first).

## Glassbloom P7 merged (2026-10-28)
- Merge `e124b97` of `codex/hud-glassbloom` `e6695c1` (P7 sign-off). Conflicts: `Screens.luau` social() kept P1 Leaderboard-only (P7 edits there touched only removed tabs); `x.sh` kept local id. Suites 43/43 (+ motion_band).
- Synced into `outputs/ClimbCollect.HomeBase.Review01.rbxl` (PlaceId 0, opened from the P3 save 829a5a9c…): overflow 174 screens × 6 sizes 0 errors, state audit 0, p7_centre intrusion 0 (all four moments), p7_insets pass, tab sync pass, console errors 0. Evidence `evidence/homebase_2026-10-29/p7merge/`. StudioAids back off, HTTP off. **Copy saved after the P7 merge (owner OK), SHA256 f07e5019…baf0** (1,494,973 bytes, 23:29); base copy unchanged (249a2786…705a).

## S2/S3 Studio sync + checks (2026-10-29, P4 start)
- Relaunched HomeBase from the P7 save (f07e5019…baf0), MCP id `63f33fc1-a0a8-4547-badb-4c7cb9d6c65c` (`x.sh`). Other window: StampedeSpire (another project), untouched.
- `sync_hud.py --changed 04b444a`: S2/S3 sources in (WorldStyle, WorldKit, WorldPill(s), TycoonWorld, HomeTiers, TycoonConveyors). Drift 107/108 (StudioTests absent by design). Suites 46/46, world_style_lint 0.
- Play: yards build on all 8 plots, 310 instances / 207 parts / 10 billboards per plot (owned plot 322/219), cap 937. HUD: overflow 174×6 0, state 0, rest 527 (≤ 726), Shop 1,808, worst 24.1 ms, 0 > 33 ms, console 0. Captures `evidence/homebase_2026-10-29/p4/captures/01-03`.
- Seen in captures (owner review): owner price pills overlap at close range; old cedar entry frame still in front of the yard.
- P4 remaining: hatchery + Training Beast (atlas G3 pass first), tier looks (= S4 houses), 2-client owner/visitor, walk 8/8. Copy **not saved**.

## P4 steps 2-3: hatchery + Training Beast (2026-10-29)
- Atlas pass 4: intel §B10 (G3/G13 closed). Owner: Beast = violet candy statue, eggs shown on the 3 cradles now (decisions doc "P4 G3 answers").
- Source (uncommitted): `TycoonWorld.luau` (hatchery dais/pedestal/3 cradles/rings/gems + 5 `HatchStage` anchors; Beast pen + statue + collider; incubating eggs ≤ 3 on cradles, tinted by the Theme rarity map via the tier body tokens, rebuilt only when the egg set changes); `Sanctuary.luau` (service markers invisible, `RequiresLineOfSight=false`); `HomeLayout.luau` service `y` (Incubator 6, Training 6; B10's 10 left the Train prompt 12.2 studs away from the pen gate).
- Play: per plot 369 instances (owned 381), hatchery 27, Beast 32, billboards 10. Egg QA on an off-map stub plot: 3 incubating eggs on cradles 1-3 (#6c8cf0 / #f7a21b / #ffb8ea), un-incubated egg excluded, no rebuild on repeat update. Walk: Incubate prompt at 11.2, Train at 11.8 studs. Suites 46/46, lint 0, drift 107/108, overflow 174×6 0, state 0, rest 527, worst 22.8 ms, console 0. Captures `p4/captures/04-06`.
- Open: eggs are spheres (Ball can't be egg-shaped; two Balls = +1 part each, owner call); dais step-up walkability not tested; tier looks = S4 houses; 2-client owner/visitor; walk 8/8. Copy **not saved**.
- Saved 2026-10-29 17:16 (owner OK): `outputs/ClimbCollect.HomeBase.Review01.rbxl` SHA256 bc2c3c8de2434656035206657301ff62ca01319e21f1ce6f78760c581a47224b (PlaceId 0, StudioAids off, Http off, not published).

## S4 tier houses (look only, 2026-10-29)
- Atlas pass 5: intel §B11 (HomeSlot dais d 31 at (0,30) + 2 steps + banner + aura ring r 17.5; Hut/Villa/Manor/Palace recipes); G9 closed (r 19 -> 17.5), G14 closed (baked lodge footprint parts are Transparency 1 / no collide), G15 OPEN (owner: Palace narrower, taller heights, Hut on the big dais).
- Source (uncommitted): `WorldKit.luau` (`homeSlot/house/banner/auraRing/setRank/houseTiers`), `TycoonWorld.luau` (HomeSlot + House per plot, baked `Lodge_0i` destroyed at runtime, house rebuilt only on tier change, rank recolours in place, unowned = dimmed Hut without banner/ring), `WorldStyle.luau` caps, `world_style.luau` test; Studio-only `ServerStorage.HomeDevTier:Invoke(slot, tier|nil, rank|nil)` (display override attrs `DevTier`/`DevRank`, created only when `studioAids()`); `tools/rmcp/capture_tiers.py`.
- Studio (Play): House parts Hut 18 / Villa 39 / Manor 51 / Palace 58 + HomeSlot 8 (caps 40/65/105/157); plot BaseParts 310 -> 350 at Palace; bounds x within +-17.3, z 16..42, tops 19.9 / 28.5 / 37.2 / 42.8; 0 lights, 0 colliding Neon; swap up, down and clear leave no orphans. Suites 46/46, lint 0, drift 107/108, overflow 174x6 0, state 0, rest 527, worst 22.4 ms, console 0, StudioAids off. Captures `p4/s4/` (front + high per tier, phone crops, `sheet_tiers.png`).
- Not done: tier-up swirl + Reduce crossfade (motion, after owner OK on looks); 2-client owner/visitor; walk 8/8; dais step-up walk. Edit-mode tools `plot_counts.luau` / `promenade_scene_check.luau` still index the lodge (error if run in Play). Copy not saved since bc2c3c8d.

## S4 tier-up swirl (motion, 2026-10-29) — owner approved, committed
- S4 houses committed `630351e` (owner approved the looks).
- Server (`TycoonWorld.setHome`): a raise on a shown plot sets plot attrs `TierUpFrom/To/At` (server time) and swaps the House after `WorldStyle.tierUpSwap` = 3.0 s (÷ QA MotionTimeScale when StudioAids). Tier down / clear / first show swap at once. Bug found in capture and fixed: the delayed swap re-entered the raise branch and looped (now `setHome(plot,true)`).
- Client: `Motion.tokens['world.tierup']` (kind 'world'; beats, caps, shape), `M.worldCaps`, `M.speed`, `M.eased`; new `mountain/client/WorldFx.client.luau` (one pool `workspace.WorldFxPool`, 48 cubes + 10 orbs + 3 ring adornments, one BulkMoveTo per frame, RenderStepped only while running). Own plot full, visitors within 150 half, Reduce = .15 s fade.
- Verified in Studio (Play, copy reopened from bc2c3c8d + synced, 108/109 match): 3 raises + Reduce + visitor sheets in `evidence/homebase_2026-10-29/p4/s4/swirl/` (pool 48/10/3, visitor 24/5/3, Reduce 0); at rest 0 active, no connection; Hut→Palace swirl median 16.7 ms, worst 18.9, 0 > 33 ms; p3 checks overflow 174×6 0, state 0, shop worst 21.1, console 0; suites 46/46, lint 5 files 0.
- PROPOSED (not traced, approve at STOP 8): every `shape` value, beat easings, orb colour = tier gem, rings are CylinderHandleAdornments (no Material). Owner approved the swirl as captured; grey mid-pass fixed (HSV blend, hue the short way round; sheets re-captured). Not built: skip (tap/Esc), plan P7 step 2. `tools/rmcp/capture_swirl.py` added.
- Copy not saved since bc2c3c8d (StudioAids off, Edit mode).
