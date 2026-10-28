# Glassbloom HUD handoff — 2026-10-27

Plan: `design/hud-glassbloom-build-plan-2026-10-27.md` (§11 owner answers override §9). Branch `codex/hud-glassbloom` from `codex/hud-v2` `f6da03b`.

## Studio
- Copy: `outputs/ClimbCollect.Glassbloom.Review01.rbxl`, byte copy of HUDv2 Review01 (SHA256 `2a3bff90…6343` verified before and after copy). **Not saved since copy.**
- Opened in a fresh Studio window by launching `RobloxStudioBeta.exe <path>` (no taskbar). MCP id this launch: `6ca0e676-3401-41ad-a8ac-fc402096a2e5` (`x.sh` updated). PlaceId 0, GameId 0. The window remembered the iPhone 16 Pro emulator (safe root 750×343).
- Never Ctrl+S in the window linked to PlaceId `112921656767061` or the PhoneCandidate place. Assert `game.PlaceId==0` and `StudioAids==false` before any save.

## P0 results (`evidence/hud_glassbloom_2026-10-27/p0/baseline.json`)
- Tests: hud_layout 288, ui_presentation 46, ui_client_state 50, ui_protocol 42, ui_server 25 (+ py 25), rules 121, bat_rules 27, egg_raids 21 — all pass. Runner: `C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe mountain/tests/<name>.luau`.
- Overflow audit, 6 sizes (749×330, 844×390, 932×430, 1024×700, 1180×780, 1600×860): 162 screens, 1 error (844×390 Shop/Convenience "No paid odds" tile title — removed by D8). Prepend `SIZES={...}` to the audit to set sizes.
- State audit (rest): 3 pre-existing errors (AddCoins < 44 px; Slot1 and Context over the dynamic-thumbstick zone).
- HUD descendants: rest 631 (budget +15 % = 726), Shop open 1034. Perf (emulator view, desktop GPU, 10 s): rest avg 16.6 / worst 20.0 ms, Shop open avg 16.6 / worst 18.9 ms, 0 frames > 33 ms.
- `UserGameSettings` quality and mouse sensitivity are not writable (RobloxScript capability) → Graphics = own effects tier, no Camera speed row.
- UIGradient under UIStroke rotates with a hard step → ring technique viable; half-clip angles still to tune in P3.
- `sync_hud.py` now creates missing modules (ModuleScript, LocalScript for `*.client.luau`) and skips repo files not written yet.

## P1 results (atlas)
- Intel: `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md` (623 lines, 8 sections). Every value is cited to a board line; the board's estimated token table (L566–575) loses to the CSS (same rule as D12).
- Independent audit (7 agents, about 1,290 values): 81 issues (`evidence/hud_glassbloom_2026-10-27/p1_intel_verification.json`); atlas re-checked and fixed all 81, 0 rejected (doc §8).
- Board self-check run in a browser at 844×390: 21/21 PASS, both controls fail. Permanent HUD coverage: rest 10.6 %, carrying 11.6 %, chase 11.1 % (the plan's 11.0 % is superseded), sanctuary 9.0 %, old chase 24.7 %.
- Open for STOP 1: upload set 11 vs the approved ~7; drawn controls under 44 px (proposal: invisible 44 px hit areas); timing conflicts between the board text and the CSS (XP line, carry pop-up entry, rail hold); gaps G1–G23.
- **STOP 1 approved (2026-10-28):** tokens as written; 11 uploads; hidden 44 px hit areas; board-text timings. See plan §12.
- **P2 decisions approved (2026-10-28):** player XP (40L+20, cap 50, daily caps), stolen secure 0 XP, Robux creatures earn 0 coins, Competition 5 coin wins/day, Meadow Egg 2,500 (section-1 table), Candy Swirl 5,000 (board look), TRUE ODDS / FAIR PLAY tiles, Robux odds 'TBD'. Spec: `design/hud-glassbloom-p2-proposal-2026-10-28.md`.

## P2 release order (T0 / C1)
- **A build containing T0 (`f92575b`, lenient `savedSettings`) must be live before any build that writes the new pref keys (T2 `b680955` onward).** Pre-T0 builds validate saved settings strictly and refuse (kick) any profile holding an unknown key. Publish a T0-only build first; the P2 branch carries T0 and T2 together.
- Mitigation in P2: defaults are never stored. `p.settings` keeps only keys a player set (plus a newer build's unknown keys, preserved). A player who never changes a new pref still loads on a pre-T0 build; one who did set `cameraShake`/`altitudeRail`/`hudScale`/`effectsTier`/`sprintMode` does not. Roll back only to a T0-or-later build.

## P2 results (2026-10-28)
- Built T0–T11 in dependency order (commits `f92575b`…`3f52379`), T1 sync tool `a938b73`, review fixes `ba3a393`. 3 adversarial reviewers found 5 minor issues; all fixed with tests (mutation-checked).
- New shared modules: `ExplorerRules`, `EggOdds`, `ShopRules`, `HudState`. Server: typed `hud` events (carry/regrab/knocked/lost/safe/alert/calm), `ui.exits` + `ui.section`, player XP (`ui.explorer`), Buy/Skin actions behind the sanctuary/no-run/no-battle/no-pending gate, Robux-origin enforcement (equip, battleTeam, load strip+refill, bat sets, 0 coins), Competition 5 coin wins/day, lenient saved settings + 5 new prefs.
- Suites (all pass): 40 suites incl. new explorer_rules 111, shop_rules 234, hud_state 101, run_context 39, run_raid_events 33, run_origin_gates 8; rules 170, egg_raids 36, ui_protocol 95, ui_server 67, run_persistence 61, run_ui_server 55, run_combat_raids 58.
- Studio: synced with `python tools/rmcp/sync_hud.py <id> --changed 760510f` (27 sources, 4 created; StudioTests skipped). Live QA `evidence/hud_glassbloom_2026-10-27/p2_live_qa.json`: refusals correct, no debit, console clean. Overflow audit 6 sizes, 162 screens, **0 errors**. StudioAids reset false; copy **not saved** (all state reproducible from the repo).
- Not live-verified (needs coins/fixtures): successful buy, XP awards, hud events, Robux enforcement. Covered by the integration suites above.
- Next: P3 kit (component-builder): Theme → atlas tokens, `W.ring` spike, the 11 PNG uploads (Asset Manager, owner account), kit + reskin, then P4 → STOP. New-chat prompt: `design/hud-glassbloom-p3-new-chat-prompt-2026-10-28.md`.

## P3 progress (2026-10-28)
- Studio: same window, MCP id `6ca0e676-3401-41ad-a8ac-fc402096a2e5`, PlaceId 0; copy on disk still `2a3bff90…6343` at start.
- T1 Theme (`7858718`): intel §1 tokens, legacy aliases per §1j. Builder notes: hero/cpk "gold radial" uses `gold` #FFD84A (intel names no hex); holo/conic/shine stops evenly spaced (CSS default).
- Masters (`f7c75a6`): `tools/render_glassbloom_masters.py` → `design/glassbloom-masters/` (11 white PNGs, 4× supersampled).
- Uploads (`5780f60`): computer use was denied, so the Asset Manager route was unavailable. `upload_image` refuses local paths but accepts `http://127.0.0.1:8765/<file>` (temporary `python -m http.server` in the masters folder). Same owner account (creator 11718983250, same as the 17 icons), type Image, no Robux. Asset names are auto ("Assistant_<hash>.png"), so ids are mapped by upload path and verified by `EditableImage` size + mean alpha vs each master (`evidence/hud_glassbloom_2026-10-27/p3/uploads_verify.json`).
- Ring spike PASS (`p3/ring_spike_01*.png`): 0/25/50/75/100 % (+10/60/90) at 42/52/48/62. Math: HalfR Rotation = min(p,.5)·360, HalfL = 180+max(p−.5,0)·360, stroke gradient {0:0,.5:0,.501:1,1:1}. At p ≥ 1 draw a full circle (hairline seams at 12/6 o'clock otherwise). U7 stays held.
- **G15 owner answers:** Robux buys go through Roblox's `PromptProductPurchase`, whose native flow tops up Robux when short (inert while product ids are 0; disabled "Coming soon" uses ghost tokens). Coin buys are two-tap (CONFIRM for 3 s); short on coins → the tap scrolls the Shop to Coins and the label reads "Need N".
- Save: owner will grant computer use on retry for the Ctrl+S step.
- Kit (`020a734`, fix `d548711`) + reskin (`d548711`): legacy widgets restyled in place (signatures/names kept); Screens panel frame = mtint shade, glass r22 hub (shop variant), cta-plate title, `W.closeX` (44 hit / 36 drawn), `W.tabButton` (44 hit / 34 drawn); Controller strokes honour `BaseTransparency`.
- **Gotcha (engine):** setting `TextWrapped=false` after `TextScaled=true` clears TextScaled; `TextScaled=true` forces wrap on. `W.fit` sets wrap first. Side effect: single long words in tiny buttons can break mid-word (Mountain › Map "UNDISCOVERE D") → fix in P5.
- **Gotcha:** a ScreenGui made with `Instance.new` defaults to Global ZIndexBehavior; kit layers at Z ≤ 0 then draw behind the parent. MountainHUD is Sibling.
- Lips, drop labels and glows are tagged `Decor`; the overflow audit's text-overlap check now skips Decor (same rule as containment).
- Reskin caveats (builder): chips lose semantic red/green; tiles/spotlights lose per-hub colours; `tert` = Epic violet; collection cards still get Screens:281's grey gradient multiply; active-tab glow clipped by the 48 px Tabs frame. All P5 items.
- **P3 checks** (`p3/checks3/`): 40/40 suites; overflow 162 screens × 6 sizes **0 errors**; HUD rest 610 (≤ 726); Shop open 1000; Shop 10 s avg 16.6 / worst 22.0 ms, 0 > 33 ms; console clean; TweenService 0 in every touched file. Hub captures `p3/hubs/` (29), sheet `p3/hubs_sheet.png`. Driver: `tools/rmcp/p3_checks.sh <id> <out>`; all suites: `tools/run_all_tests.sh`.
- **Saved** 2026-10-28 12:06: Ctrl+S on the Glassbloom window only (title verified, PlaceId 0, StudioAids false). SHA256 `f67f0edfe328741724f8bb1ccb28720b967e33a021d0b5751af97280402e6f0a`, 1,418,092 bytes. Computer use: Roblox Studio (full) + File Explorer (click-only, to focus the title bar).

## P4 results (2026-10-28) — STOP 2 pending
- Built `2618725` (+ native-corner fix): `client/UI/Hud.luau` states rest/carry/regrab/chase/sanctuary/battle; `Feedback` = 3-tier host (its tween removed); Controller = wiring only (drift deleted: AddCoins, Journey, QuestTracker, timer, Menu/Navigation, quick tiles, old battle panel); Sprint orb kit look + `sprintMode`; `P.hudLayout` rewritten, `P.hudScale`, `P.nativeRect`; UIProbe `hudState(name|'live')`.
- **Fix (main session):** native TouchGui controls are measured from the gui's screen corner (`P.nativeRect`, jump bottom-right, sticks bottom-left) in Controller, Sprint and the state audit. Before it, a resized audit root put the real 750-px jump mid-root and pushed the sprint orb onto the carry portrait at 844×390 (3 false errors). Test added (ui_presentation 50).
- Checks `p4/checks2/`: 40/40 suites (hud_layout 69,601, hud_state 102); overflow 162 screens × 6 sizes 0 errors; state audit 5 states × 3 sizes **0 errors**; coverage 844×390 rest **10.9 %** (≤ 11.6), chase **10.4 %** (≤ 12); HUD rest 499 (≤ 726), Shop 889; Shop worst 19.5 ms, 0 > 33 ms; console clean; TweenService 0 in touched files.
- STOP 2 captures `p4/stop2/` (custom device GB_844x411 at ActualResolution → 844×411 frame, 841×388 viewport; Studio cannot emulate a bare 844×390 root). Emulator restored to iPhone 16 Pro / ScaleToPhysicalSize; StudioAids false. **Copy not saved after P4** (on disk = P3 save f67f0edf…).
- Builder GAPs used kit fallbacks (lv badge padX, pick-up/Dodge icons, orb disabled/sprint-on looks, boss track, pcard ring values, level-up copy, toast padding, tier-3 FIFO, beacon fixed size/right-edge arrow). Open owner call: hit areas at HUD scale S (dock pitch 48×.85 = 40.8 < 44); L capped at width ÷ 672 (1.11 on 749-wide).
- Behaviour changes: dock Creatures opens the player card (M/Tab still opens Creatures); Slot1–3 only in battle; Context = pick-up only; coin pill → Shop, gear → Settings›Quick; Daily → Shop first tab until P5; toasts 1.5 s; HUD layer Z30 above menus, HUD pieces hide while a hub is open.
- **STOP 2 approved** (owner popup). Scale-S pitch rule applied (`P.hudLayout` dgap, portrait follows the dock, test floor 44 at every scale); re-checked `p4/checks3/`: 40/40, overflow 0, state audit 0, coverage 10.9/10.4 %, rest 499, Shop worst 21.9 ms. Next: P5 hubs + shop (component-builder), then P6 motion. Copy on disk is still the P3 save.
