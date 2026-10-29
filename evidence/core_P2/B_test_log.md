# Run 1 · B Core loop (Green Valley) — test log (2026-10-20)

All runs: Studio Play Solo on desktop (not a phone, not a device), in-memory store, stub creature visuals (Codex art pending). BOT = perfect input via `tools/tutorial_bot.luau` (Humanoid:MoveTo + real ProximityPrompt holds, so every claim passes the server's hold/range/stagger validation). Human times were **not measured**.

## 1. Full tutorial, timing run (WalkSpeed 12 = BOT time)
| Beat (brief §3.6) | BOT time | Brief target (PROPOSED) |
|---|---|---|
| 2 first common claimed | 0:12.1 | 0:45 |
| 3 first bank (plaza campfire) | 0:20.5 | 2:00 |
| 4 rope climbed (Shepherd's Road s≈840, 15.2-stud rope) | 2:02.4 | 3:00 |
| 5 **Rare claimed (guardian-free nook)** | **2:06.3** | **≤ 5:00 (LOCKED)** |
| 6 pup netted (cloth net, 1.5 s hold) | 2:24.9 | 6:30 |
| 7 Heartstone taken (sneaked while the guardian walked its ring) | 2:58.4 | — |
| 8 Heartstone banked (starts ripening, 5:00 timer) | 4:42.6 | 8:30 |
| 9→10 cliffhanger played, tutorial done | 4:49.3 | ~10:00 |
Result: 0 stuck, 0 guardian hits, final step 10, backpack empty, 1 Heartstone ripening, level 4.

**Honest read:** at bot pace the whole onboarding is ~4:50, about half the ~10-min target; a first-time player is slower (looking around, finding the rope, timing the guardian), but no human run was made, so the human time is **UNMEASURED** (ESTIMATE: roughly 7–10 min). The Rare-by-5-min rule has 2:54 of slack at bot pace.

## 2. Scripted-client checks (`tools/b_checks.luau`, Studio dev hooks for setup only)
```
[PASS] no item shake before the first bank — real guardian hit, pack 1 -> 1, no drop pack, toast 'Beginner protection: nothing was shaken loose. Bank once to make finds permanent.'
[PASS] hit after first bank shakes the most valuable item — shaken Rare, pack window 179 s, still carrying 1
[PASS] drop pack recoverable for 3 min (real time) — recovered with 20 s left; carrying 2, packs 0
[PASS] unrecovered pack expires after 3 min with a loss message (simulated clock +185 s) — packs 0, toast 'Your drop pack faded. Lost: Stub Uncommon 1 (Uncommon).'
[PASS] fall after the first bank: respawn at checkpoint + 1 item to a pack — real 140-stud fall, respawn y 513 (Camp 1), shaken Uncommon, carrying 1, packs 1
[PASS] Camp Locker store + take (1 slot at tent tier 1) — opened, stored, taken back
[PASS] resume at the highest reached camp — highestCamp 1, spawn 0 studs from Camp 1, Foothold offer shown
[PASS] 'Start at the Foothold' (empty pack, first 60 s) — 0 studs from the Foothold spawn
[PASS] full backpack refuses a claim without loss — toast 'Backpack full (4/4). Bank at the Foothold campfire.', pack 4/4
[PASS] disconnect: unbanked items to a pack + 'last trip' notice — packs 1, carrying 0, toast 'Last trip: 2 unbanked finds stayed in a drop pack (3 min) when you left.'
```
First pass had 2 FAILs, both test-setup bugs (kept for honesty): the recovery check walked back into the guardian's territory and got hit a second time (a real design property: packs lie where you were hit); the fall check's own pre-positioning teleport dropped 28 studs and counted as a fall. Fixed the checks (wait for the guardian to be away; ground-snap before the drop), re-ran checks 2 and 4: PASS.

## 3. Stuck-state batch (20 runs, WalkSpeed 36 — stuck check only, times not comparable)
See §5 (superseded attempts) and §6 (final batch: 20/20 complete, 0 stuck).

## 3b. Performance (Studio desktop Play Solo, vsync-capped; NOT mobile, NOT a device)
| Where | Client avg FPS | Worst frame | Frames > 33 ms | World streamed | Notes |
|---|---|---|---|---|---|
| A0 baseline, spawn (no core loop) | 60.0 | 17.9 ms | — | 2,581 | before Run 1 |
| B, bot playing at the hollow nest (guardian active), 20 s | 60.0 | 20.2 ms | 0 | 3,698 (Core 335) | different spot than the baseline |
Server: Heartbeat 60.0 Hz, worst 19.8 ms over 15 s with 1 player + 1 guardian; core-loop instances on the server ≈ 328 (Creatures 181, NestLive 30, Nests 36, Spawns 30, Props 24, Guardians 11, DropPacks 16). Mobile-emulation FPS: see §6.

## 4. Iterations and defects found by the bot (rejected iterations kept)
- `91_rejected_bot_stuck_gate_mound.jpg`: straight-line path from the campfire ran onto a mound beside the Shepherd's Road gate (the gate opens west, reached from the north-east). Bot path fixed; humans steer around it.
- Tutorial guardian too harsh for a first encounter: the bot was hit before it could net the pup (`B_03_loss_card_guardian_hit.jpg` shows the loss card working). Fixes (PROPOSED, logged): facing cone + "checks its nest" pauses so sneaking is possible; tutorial nest senses ×0.6; pup moved outside the patrol ring; hide spot moved off the approach path.
- Tutorial soft-lock risk: taking the Heartstone before netting the pup left step 6 incomplete. Step 6 now completes on either.
- ProximityPrompts show only when on screen; the bot's trailing camera hid them (bot aims the camera now; players look where they walk).
- Cliffhanger camera started at the head and the character blocked the shot; it now looks from above/ahead of the character.
- HUD zone names used a radius band ("Green Valley" at the foothills gate); now altitude bands like the terrain.
- XP pacing (flag, not changed): netting the Epic pup in the tutorial gives 500 XP (250 × first-of-species ×2), so a new player ends the tutorial at level 4 (7 slots). Brief §3.1 numbers are PROPOSED; "L2 ~10 min" does not hold. Tune in Phase G.

## 5. Stuck-state batch results
Superseded batches (kept for honesty): (a) first 20-run batch stopped after 3 runs: run 2 (deliberate hit) got stuck twice on its way home because its straight line ran into the hide-spot boulders (bot pathing; fixed by routing home north of the nest); (b) second batch stopped after 3 clean runs because the B review fixes changed the code under test. The final batch below ran on the final code.

(final batch: see §6)

## 6. Final code: re-run of everything after the B review fixes
- A1 suite: 12 pass, 0 fail.
- B scripted checks: 10/10 PASS (pack recovered in real time with 7 s left this time).
- New review checks (live): instant teleport-home bank → find held in the backpack ("Some finds can't be banked yet…"), banked normally after the walking time; reset with 2 unbanked items after the first bank → carrying 0, 1 pack with both items, loss card "You respawned: your cargo stayed behind."
- Timing run (WalkSpeed 12, BOT): common 0:12.3 · bank 0:20.7 · rope 2:02.8 · **Rare 2:06.6** · pup 2:25.1 · Heartstone 2:55.1 · Heartstone banked 4:38.3 · **done 4:45.0**; 0 stuck, 0 hits, final step 10. (One earlier final-code timing run got stuck on its last leg home: the bot's new route ended on Cabin 4's terrace; bot route fixed, re-run above.)
- **20-run batch (WalkSpeed 36 = stuck check only; even runs walk into the guardian on purpose): 20/20 complete, 0 stuck, 0 incomplete.** 10 deliberate guardian hits, every drop pack recovered, every run reached step 10 (Heartstone banked + cliffhanger). Run totals (s, h = deliberate-hit run): 1:110 2:139h 3:132 4:138h 5:113 6:139h 7:110 8:137h 9:111 10:145h 11:130 12:138h 13:131 14:138h 15:110 16:139h 17:110 18:138h 19:111 20:137h.
  - A third batch attempt before this one ended run 2 at step 8: after its deliberate hit the bot walked back into the guardian's area for the pack, was hit again and left the Heartstone in a pack, so the tutorial correctly waited (not a soft-lock: the step completes when that pack is recovered or expires). The bot now recovers packs only while the guardian is away and goes back for a shaken Heartstone, as a player would.

## 7. Phone simulation (Studio Device Simulator, iPhone XR landscape; desktop GPU, NOT a device)
- Viewport 801×413, touch controls on. 15 s at spawn: **60 FPS avg, worst frame 19.0 ms (emulation)**.
- `B_06_phone_iPhoneXR_sim_hud_marker.jpg`: HUD below the Roblox top-bar buttons and clear of the notch, one-line companion with the 48-px Skip, objective ◆ marker above the first common, thumbstick/jump unobstructed.
- Found and fixed during the phone check (rejected captures kept): `93_rejected_phone_marker_missing.jpg` — the objective marker's BillboardGui sat inside the ScreenGui and never rendered (now parented to its client-side anchor part; note: Studio's `screen_capture` tool does not draw it, the real screen does); `94_rejected_phone_loading_banner_stuck.jpg` — a startup race: when `PlayerAdded` fired after the startup sweep had already loaded the player, the handler reset the save state to "loading" and cleared the backpack, leaving banking paused for the session. One guarded join path now serves both.
- After those fixes, on the final code: A1 12/12, B checks 10/10 (pack recovered with 13 s left), timing run **4:47.9 BOT, Rare 2:06.2, 0 stuck, 0 hits** (under the phone simulator).

## 8. Stage 4 B-polish re-run (2026-10-20, 22:30–22:55, final B-polish code; Studio desktop Play Solo, NOT a phone)
Changes under test: XP 10/20/40/80/300 ×1.5 first-of-species; tutorial Rare protected until banked once; beats 9 (two outskirts finds) + 10 (bank them), cliffhanger 11, done 12; live-server dev-tool strip; cliffhanger FOV auto (8–24); lip-nest access stairs.
- **A1 suite: 12 pass, 0 fail** (in-memory mock; real DataStore UNVERIFIED).
- **B scripted checks: 12/12 PASS** (10 earlier checks + 11 "tutorial Rare protected until banked once" + 12 "tutorial Rare shakes normally after it was banked once"); drop pack recovered in real time with 24 s left. (Check 9 failed once in the previous chat from its own setup — the bank travel-time check refused an instant teleport bank; fixed with a clock offset in the check, not in the game.)
- **Timing run (WalkSpeed 12, BOT):** common 0:12.2 · bank 0:20.7 · rope 2:02.3 · **Rare 2:06.4** · pup 2:24.9 · Heartstone 2:55.5 · Heartstone banked 4:39.0 · outskirts finds 5:24.5 · bank 6:02.1 · **done 6:08.6**; 0 stuck, 0 hits, final step 12, **level 2, 220 XP** (was L4). Human time **UNMEASURED** (ESTIMATE ~8–12 min for a first-time player; target ~10 min).
- **Lip nest on foot (BOT, speed 36 road leg = stuck check; descent at 12 = BOT time):** Shepherd's Road gate → s 5559: 159.7 s, 0 stuck; s 5559 → lower shelf → two timber stairs → nest: **20.8 s BOT, 0 stuck, 0 falls**. The first access (a 29-stud fixed rope + plank from a side bench) was replaced: the bench is reachable only over a 7-stud step and its edge drops into the valley (the bot fell off it twice: real falls, respawned at the checkpoint).
- **Cliffhanger (beat 11, FOV auto):** `B_07_cliffhanger_lip_guardian_desktop.jpg` (from the plaza campfire, 524 studs from the nest; guardian + crystals + lip framed, FOV clamped 8–24) and `B_08_..._phone_aspect.jpg` = centre crop of the same frame at 19.5:9 (same vertical FOV = what a landscape phone shows; HUD scale is the desktop's, not a phone's). Captured by replaying the real beat (Studio-only dev action `cliffhanger`: same guardian watch + fx) and screenshotting the Studio window, so no MCP client call could reset the camera. HUD in the shot shows step 2 (the replay doesn't change steps). `B_09_lip_stairs_edit_view.jpg`: the upper stair from the lower shelf (edit view).
- **Perf pass:** `evidence/perf_P1/perf_after.md` (5 spots, 60 FPS, worst ≤ 27.9 ms, 0 frames > 33 ms).
