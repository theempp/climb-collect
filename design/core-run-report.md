# CLIMB & COLLECT — Run 1 report (A0 + A1 + B), 2026-10-20

Unattended backend/systems run, authorized in `design/autonomous-build-brief.md` §0 for A0, A1 and B only. **Stopped after B as instructed; D, E, F and C (creatures, Codex's track) were not started.** All decisions made on my own are in `design/decision-log.md` as PROPOSED. Evidence: `evidence/core_P0` (A0), `core_P1` (A1), `core_P2` (B).

Labels: BOT = perfect-input bot time; emulation = Studio emulation; ESTIMATE = not measured; UNVERIFIED = could not be tested here. Everything was measured in Studio Play Solo on a desktop, never on a phone.

## Done

### A0 Safety
- Checkpoints `A0_2026-10-20`, `A1_2026-10-20`, `B_2026-10-20` in `ServerStorage.CC_Checkpoints` (tool: `tools/checkpoint.luau`, refuses to overwrite) and file copies `ClimbAndCollect.A0.rbxl` (your 14:47 save), `.A1.rbxl`, `.B.rbxl`.
- Baseline (desktop Play Solo, spawn): 60 FPS (vsync cap), worst frame 17.9 ms, 2,581 World instances streamed, 51.5k client instances.
- `master.md` §0.7 Core loop (LOCKED items from `core-loop-plan.md`) + in-place "superseded" notes (egg → Heartstone, camps → tents, Hatchery → Heartstone Hatchery, net on Claiming, amended #5). Diff check: no LOCKED text removed.

### A1 Data + persistence (VERIFIED on the in-memory mock only)
- Store adapter: real DataStore (`Store.datastore`, used only when the place is published) + in-memory mock with failure injection. **Real DataStore: UNVERIFIED.**
- Profile schema v1 (brief §3.9) + logged extensions (`lockers`, `tx`, `flags`, `timers`, `lastTrip`, `stats`, `quarantine`, Heartstone `species/region`); sanitize keeps valid data and quarantines junk (never deletes); version migration chain; a newer-schema profile is never downgraded by an older server.
- Session lock with stale-lock takeover and an ownership check on every save (a stale server can never overwrite); autosave 60 s (retry every 15 s while failing), release on leave with backoff + 5-min background retry, `BindToClose` releases every owned session.
- Idempotent bank (transaction ids + creature ids), Heartstone ripening from server timestamps (works offline), safe "Saving paused…" banner with banking paused while the store fails.
- Acceptance: 12/12 scripted tests PASS; live checks PASS — rejoin keeps the bank, a doubled deposit yields once, store failure shows the safe message (3.1 s) and refuses deposits without losing items, a Heartstone completes after a simulated 400-s offline gap.
- Adversarial review (4 lenses + refutation): 12 distinct defects fixed, 1 high (shutdown did not wait for in-flight leave saves). `evidence/core_P1/A1_review.md`.

### B Core loop (Green Valley) — built as a first draft
- Hold-claim with server-side hold/range/stagger validation; backpack 4 → 12 by level and codex milestones (Heartstone 2 slots); bank at the plaza campfire (no new geometry; Foothold layout untouched).
- Species referenced only by id through one table (`ReplicatedStorage.CC_Core.Species`), 43 stub entries + 5 guardian stubs; spawns query by region + rarity + ecology, so Codex's roster replaces stubs without code changes; `Visuals` clones `ServerStorage.CC_Creatures/<id>` read-only when it exists (it doesn't yet). The server owns rarity, yield and mutation.
- Region 1 content: 25 common/uncommon spawn points on Shepherd's Road + 3 on the Foothold outskirts; guardian-free Rare nook up a 15-stud fixed rope (s≈840); tutorial "hollow" nest (gentle guardian, pup + cloth net, Common Heartstone, hide spot); cliffhanger "lip nest" (Rare tier, bigger guardian) on the valley lip above the plaza.
- Guardian: Patrol (walks its ring, pauses to check the nest) → Alert (1.6 s "!" tell) → Chase → hit = stagger 1.2 s + one unbanked item to the drop pack → Retreat; LoseYou when line of sight breaks, out of range, in a safe zone or past the leash; 0.55–0.7× WalkSpeed in Region 1, never above 1.15×.
- Drop pack: 3 min, owner-only recovery, then a loss message; fall loss (1 item, detected server-side) after the first bank; a reset/death with cargo leaves all of it in a pack where it happened; disconnect → pack + "last trip" notice; no loss of any kind before the first bank (beginner protection).
- Tents (functional): guardian-free radius around Camps 1–4 and the Foothold; Camp Locker (1 slot at tier 1) persisted in the profile; highest camp tracked; resume at the highest camp with a 60-s "Start at the Foothold" offer while the backpack is empty.
- Onboarding: 9 beats with a companion glow-wisp, one-line prompts + 48-px Skip, objective marker + edge arrow (a live drop pack outranks it), Heartstone ripen timer, cliffhanger camera on the lip guardian.
- Adversarial review of the B code (4 lenses + refutation): 15 confirmed findings (~11 distinct) fixed, incl. 1 high (a reset was a free teleport home with the cargo → cargo now stays in a pack where you died), a bank travel-time check against teleport-home banking, server-side fall detection, a save right after each deposit, per-player guardian visibility + 20 Hz replication. `evidence/core_P2/B_review.md`. Everything below was re-run on the fixed code.
- Acceptance results (final code):
  - **Full tutorial by bot: PASS — 4:47.9 BOT, 0 stuck, 0 hits; Rare at 2:06.2 BOT (≤ 5:00)** on the final code (other runs: 4:45.0 / Rare 2:06.6 after the review; 4:49.3 / Rare 2:06.3 before it).
  - **Drop pack recoverable for 3 min: PASS** (real time; recovered with 20 s left, and 7 s left on the final-code run; expiry message checked with a simulated clock).
  - **No item shake before the first bank: PASS** (real guardian hit, nothing shaken, beginner-protection toast).
  - **0 stuck states in 20 runs: PASS — 20/20 complete, 0 stuck, 0 incomplete** (WalkSpeed 36 as a stuck check; 10 runs walked into the guardian on purpose and recovered every pack). Earlier attempts that hit bot-pathing problems are kept in `B_test_log.md` §5–6.
  - Also PASS: hit shakes the most valuable item, fall loss + respawn at the checkpoint, Camp Locker, resume, full-backpack refusal, disconnect pack.

## Not done / partial (honest)
- **Real DataStore** never ran (place unpublished). Everything persistence-related is proven on the mock only.
- **Human tutorial time unmeasured.** At bot pace the onboarding is ~4:45–4:50, about half the ~10-min target (ESTIMATE for a first-time player: 7–10 min). Needs your playtest.
- **Phone:** no device test. Studio Device Simulator (iPhone XR landscape, desktop GPU): 60 FPS, worst frame 19.0 ms at spawn (emulation); layout checked at phone aspect (`B_06_…jpg`). The phone check found and fixed two bugs (objective marker never rendered; a startup race that could leave banking paused). Real-phone FPS: UNVERIFIED.
- **Camps still look like lodges.** The tent safe zone and locker work, but the LOCKED "camps become tents" reskin (archive the lodges) was not built (art, not systems).
- **Creature visuals are stubs** (plain balls + rarity pips; guardian ball + facing marker) by contract until Codex delivers `ServerStorage.CC_Creatures` / `creatures/roster.json`.
- **Net tiers:** only cloth is live; rope (level 4, coins) and aurora-thread (Region 3 pup) exist as data only.
- **Not exercised:** two-client races (competing claim on one common, legendary first-claim) — Play Solo has one client; claims resolve first-valid-wins on the server but this was not tested with two players. Mutation is always empty (no weather system until Phase F). Hatched creatures go into the bank, not into habitats (Phase D). No audio (no sound pipeline yet).
- **Lip nest reachability** by a player on foot was not walked; it serves as the cliffhanger and later goal.
- **XP pacing:** the tutorial ends at level 4 because the Epic pup is worth 500 XP (brief numbers). Flagged for Phase G tuning, not changed.

## Blockers / things only you can do
1. Publish the place (or give a published test place) to verify the real DataStore path — publishing is a §5 stop for me.
2. Play the tutorial yourself (and on a phone) to get human times and a device FPS number.
3. Decide on the tutorial length (it is short at bot pace) and the XP pacing.
4. Review the first-draft placements (rope nook, hollow nest, lip nest) and the stub look of guardians/creatures until Codex's library lands.
5. Confirm the incident handling in A0 (a taskbar click closed Studio; I restored it from Studio's auto-recovery file with no data loss and continued instead of stopping — see the decision log).

## Next (each needs its own authorization)
- **D Tycoon + base:** habitats with yield/offline cap/2× bonus, Heartstone Hatchery reskin, cabin upgrades, displays, visit-a-friend.
- **E Depth:** regions 2–3 guardians and scaling, rarity visuals, ATV/helicopter extraction, tent upgrades, net tiers.
- **F Return hooks:** weather + mutations, legendary events, daily goal/streak.
- **C (Codex):** creature library; wiring is ready (species ids, `CC_Creatures` lookup, roster `replaces` mapping; `tools/roster_to_luau.py` turns `creatures/roster.json` into the `Species.Roster` module).
- Tent reskin of Camps 1–4 (archive lodges) when an art pass is approved.

## Stage 3–4 addendum (2026-10-20 evening): performance + B-polish
- **Load time cause found and fixed:** 15 whole-map checkpoints inside the place (88% of the file, 96% of instances). 14 moved to `ClimbAndCollect.CheckpointArchive_2026-10-20.rbxl` (verified). File 84.8 → 18.0 MB; Play → playable 19.9 s → 6.1–6.5 s; play memory 13.3 → 9.8 GB (Studio desktop Play Solo). Frames were already vsync-bound here and stay so: 5 spots 60 FPS, worst 27.9 ms, 0 frames > 33 ms. Phone numbers UNVERIFIED. Details: `evidence/perf_P1/perf_report.md`, `perf_after.md`.
- **B-polish:** XP re-paced (tutorial ends L2, 220 XP); tutorial Rare protected until banked once; tutorial lengthened with an outskirts claim + bank loop (BOT 6:08.6, Rare 2:06.4; human time UNMEASURED); lip nest reachable on foot via two timber stairs (20.8 s BOT from the road); cliffhanger FOV auto + captures `B_07/B_08`; dev tools stripped on live servers + `tools/publish_strip.luau`; brief §5 self-recovery rule. A1 12/12, B checks 12/12. Not fixed (your call): low-quality view distance hides the mountain, streaming settings, Foothold draw calls, post-effect tiers.
