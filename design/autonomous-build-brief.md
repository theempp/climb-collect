# CLIMB & COLLECT — Autonomous build brief (DRAFT, 2026-10-20)

**Status:** DRAFT. Not yet runnable: §0 authorization is OPEN and the routes interview (§8) is pending. Do not launch until both are closed.
**Legend:** LOCKED = user answer in `core-loop-plan.md` / `v4-climb-concept.md` / `master.md` §1 · PROPOSED = my default, agent may change and log it · OPEN = needs the user · ESTIMATE = not measured.
**Facts vs interpretation:** facts cite a source file; anything else is marked PROPOSED/ESTIMATE. Design values come only from user answers, docs or verified facts (no house style).

## 0. Autonomy authorization (OPEN, user must confirm before launch)
| Item | Value |
|---|---|
| Unattended run authorized? | **OPEN.** `CLAUDE.md` says stop for approval at each gate; this run needs an explicit override like `OVERNIGHT_BRIEF.md` had. Not given yet. |
| Run length | PROPOSED: up to ~6 h, one phase-group per run, hard stop at the end of the group. |
| Checkpoints | PROPOSED: before each phase, `ServerStorage.CC_Checkpoints/<Phase>_<date>` + a file copy `ClimbAndCollect.<Phase>.rbxl`. Never overwrite an existing checkpoint. |
| Agent may decide (log as PROPOSED) | numbers inside §3 ranges, naming, layouts of new UI, species look details, tuning, bug fixes, internal architecture. |
| Must wait for user | anything LOCKED, monetization, changing the Foothold layout, deleting content, identity-changing look changes, spending/publishing/uploading to Roblox, any real-device claim. |
| Evidence rule | Never invent test evidence; never mark unfinished content complete; label bot times BOT, emulation as emulation, numbers not measured as ESTIMATE. |

## 1. Final scope (core loop), LOCKED unless marked
Climb routes -> discover (commons, hidden Rares, nests) -> hold-claim or net -> take Heartstone from a guarded per-player nest -> guardians chase/escalate -> bank at the Foothold -> Heartstone ripens in real time (Common 5 min / Rare 30 min / Legendary 4 h) -> creature joins a habitat and yields Cairn Coins (8 h offline cap, 2x if collected within 1 h) -> upgrades (habitat slots, cabin, tents, nets, cosmetics) -> repeat via weather mutations, legendary events, daily goal (non-punishing streak).
Locked numbers: 5 rarity tiers · yield/h 1/3/10/35/150 · duplicate 25% · mutation +50% · backpack 4->12 (levels 2-7 +1 each, two codex milestones +1 each) · 9 levels · 4 habitats x 6 slots · 40 regional species + 3 weather-linked Legendaries (43, PROPOSED split) · 8 Legendaries total · net 3 tiers · tents 3 tiers (locker 1->3, refill speed, small safe-radius) · weather: dynamic, tiered, fallback presets only if 30 FPS breaks.
Out of scope: monetization, PvP/theft, co-op raids, leaderboards, Training Yard (later annex), routes redesign (waits for §8).

## 2. Phase order (each: checkpoint first, evidence in `evidence/core_P<n>/`, rejected iterations kept with `9x_` prefix)
| Phase | Tasks | Acceptance (all measured, labeled honestly) | Evidence |
|---|---|---|---|
| **A0 Safety** | checkpoint + file copy; baseline instances/FPS; apply approved edits to `master.md` (Heartstone, tents, net, amended #5) and `CLAUDE.md`. | Docs consistent; no LOCKED text erased. | diff notes, baseline numbers |
| **A1 Data + persistence** | `Profile` module (schema §3.9), idempotent bank, Heartstone timers, autosave/retry/migration, session lock. | Rejoin test keeps bank; double-deposit yields once; DataStore failure path shows safe message; Heartstone completes after simulated offline gap. | scripted test log, Studio output |
| **B Core loop (Green Valley)** | claim system (hold, net), backpack, bank at Foothold, one nest + one guardian species (gentle), chase/stagger/drop pack, tent safe zone + locker, resume at highest camp, onboarding (§3.6). | Full 10-min tutorial run by bot + scripted client; Rare by min 5 (BOT time); drop pack recoverable 3 min; no item shake before first bank; 0 stuck states in 20 runs. | screenshots (avatar scale + phone aspect), bot times, FPS emu |
| **C Creature library** | Spike: 3 species at quality bar (try `generate_mesh`, procedural CSG, Blender if connected; pick by looks, never assume). Then batch to 43 as a prebuilt library in `ServerStorage.CC_Creatures` with one shared animation set (idle, move, react, claimed) and a data table (§3.2). | Spike reviewed by user before the batch (STOP point); every species has silhouette distinct in 1-colour test; instance cost per species logged. | contact sheet, per-species cost table |
| **D Tycoon + base** | Heartstone Hatchery reskin (layout frozen), habitats with roaming (contained path, cap 6 active movers/yard), yield + offline + 2x bonus UX, cabin upgrades, display plinths, visit-a-friend. | Yield math matches table within rounding; offline cap enforced; visit flow works with 2 clients; yard FPS cost logged. | tests, screenshots |
| **E Depth** | regions 2-3+ guardians and scaling, rarity tiers/visuals, ATV/helicopter extraction, tent upgrades, net tiers. | Scaling table (§3.3) implemented; extraction tested; fairness rules (§3.3) verified by scripted cases. | tests, captures |
| **F Return hooks** | weather system (tiered), mutations, daily goal/streak, legendary events, social flex. | Weather cost logged per tier on emulation; event first-claim race passes 2-client test; streak pauses not resets. | cost table, test log |
| **G Tune + polish** | economy from playtest logs, UI polish, sound/VFX pass, mobile budgets, report. | 30 FPS floor on Studio mobile emulation (UNVERIFIED on a device); gaps listed. | report |

Routes redesign (V4 climb controller, narrow ledges, summit gauntlet) is a separate track after §8 and is not part of A-G unless the user adds it.

## 3. PROPOSED defaults (agent may adjust within range, log each change)
**3.1 XP/levels:** XP on bank: Common 10, Uncommon 25, Rare 80, Epic 250, Legendary 1000; first-of-species x2. Cumulative XP to L2..L9: 100, 250, 500, 900, 1500, 2400, 3800, 6000. Targets: L2 ~10 min, L9 ~15-20 h (ESTIMATE). Stamina capacity +8% and recovery +6% per level (soft cap).
**3.2 Species rules (per region):** 3 Common (ground/ambient, easy sightlines), 2 Uncommon (ecology-linked), 1 Rare (hidden nook), 1 Epic (the guardian's pup), 1 regional Legendary. Each: distinct silhouette, 1 personality read from ears/tail/idle, ecology (perched, hopping, floating, hiding) that hints where to find it. Weather-linked Legendaries: Storm, Aurora Night, Snow-whiteout. Names/looks written in Phase C from region mood in `master.md` §4 only.
**3.3 Guardians:** states Patrol -> Alert (tell ≥1.5 s, visible/audio) -> Chase -> LoseYou (3 s search) -> Retreat to nest. Per region (1-2 species, random traits per encounter): speed 0.5x-1.1x of WalkSpeed 12 in R1, up to ~1.15x by R5; sense range 25-90 studs; size 0.8-1.4x; one weakness (e.g. light, height, water). Escalation: +10% sense/speed per region step and per nest value tier. Hit = stagger 1.2 s + one unbanked item into the drop pack (not in R1 before first bank). Fairness (mobile): never chase faster than 1.15x run speed; always a tell; stagger invulnerability 2 s; guardians stop at tent radius and at hide spots' line-of-sight break; a nest guardian never respawns on top of the player.
**3.4 Nests/Heartstone:** per-player instanced, 2-3 per region, ~10 min respawn. Nest = crystal cluster + guardian; hold-claim 3 s (longer by tier) while guardian is Alert-free or distracted. Heartstone glows (others see value), 2 slots, shows ripen tier. Full bag: prompt, claim refuses without loss. Disconnect: carried Heartstones follow the unbanked rule (go to drop pack for 3 min server-side, else lost). Death/fall: normal fall-loss; held Heartstone is the item most likely shaken (rule: guardians shake the highest-value unbanked item first). Legendary Heartstone: server-wide first-claim only; losers get a memento.
**3.5 Tycoon:** habitats are fenced yards with the creature roaming a contained path; display plinths in the Hall. Cabin upgrades: 3 tiers (visual + 2 habitat slots each). Visit: join a friend's cabin as read-only guest, can emote and view displays. Hatchery: crystal cradles reuse the egg layout.
**3.6 Onboarding (~10 min, diegetic, companion NPC with 1-line prompts, skippable on return):** 1 spawn vista + move hint (0:00) · 2 common nearby, hold-claim (0:45) · 3 walk to Foothold, bank (2:00) · 4 short rope climb (3:00) · 5 Shepherd's Road Rare nook, guardian-free, Rare by 5:00 · 6 gentle guardian pup + cloth net (6:30) · 7 Heartstone starts ripening in cabin (8:30) · 8 cliffhanger ~10:00: ripen timer + silhouette of a bigger guardian higher up. Companion: small glow-wisp, silent but expressive (PROPOSED; avoids text walls).
**3.7 Return hooks:** daily goal = 1 random objective per day (e.g. bank 3 species); streak pauses on a miss. Weather rotation: 1 weather per ~20 real min with 2 min blend; forecast on the Route Board. Legendary event: announced 5 min ahead with map ping; first claim wins; consolation memento. Offline-yield UX: welcome-back card with coins, time away, and the 2x timer.
**3.8 UI (mobile):** HUD = zone name, backpack count, stamina, objective arrow, alert icon; codex and collection screens on demand; loss message lists what was lost/kept and the recovery timer; tap targets ≥ 48 px; safe-area insets. Sound/VFX priority: claim feedback > guardian tell > weather ambience > everything else.
**3.9 Persistence schema (v1):** `Profile{version, coins, xp, level, slots, bank{creatureId, species, rarity, mutation, acquiredAt}[], codex{speciesId=count}, heartstones[{id, tier, mutation, startedAt, readyAt}], habitats[{id, slots[]}], tents{camp=tier}, highestCamp, dailyGoal{day, id, done}, streak, lastSeen, cosmetics[]}`. Server-authoritative; deposits idempotent by transaction id; Heartstone completion computed from `os.time()` vs `readyAt`; autosave 60 s + on leave; retry with backoff; session lock.
**3.10 Anti-exploit:** server validates claim distance, hold time, nest ownership, backpack capacity, rarity; clients never send rarity/yield; rate-limit remotes; nest and event state server-owned.
**3.11 Performance:** target 30 FPS floor on Studio mobile emulation (UNVERIFIED on device), 60 desktop; creature budget ≤ 2k parts/CSG instances per visible region ESTIMATE; weather FX tiers: Low (lighting blend only), Mid (+ precipitation sheet), High (+ lightning, whiteout, foliage wind).

## 4. Frozen vs improvable
**Frozen:** Foothold layout and 4 gates; Ring Mountain identity, 5 regions, 4 route names/intensity ladder; LOCKED rules; existing checkpoint/hazard runtime API (extend, do not rewrite).
**Improvable:** Hatchery skin, camp builds -> tents, creatures, UI, lighting/weather, vegetation, route cues, props.

## 5. Stop conditions (hard)
- Any LOCKED rule would be violated; any phase's acceptance fails twice after fixes; data-loss path found; FPS floor missed with no cheaper fix; Studio MCP disconnected or wrong place open; a spend/publish/upload step is required; a required decision is not in §0/§3 or LOCKED docs.
- On stop: write a status note, checkpoint, do not continue to the next phase.

## 6. Decision log template (append to `design/decision-log.md`)
`| Date | Phase | Decision | Why | Status (PROPOSED/LOCKED-ref) | Evidence |`

## 7. Launch prompt (use only after §0 and §8 are closed)
```
You are the unattended build agent for CLIMB & COLLECT. Read CLAUDE.md, master.md (§0, §0.5, §0.6, §1, §5-§9), design/core-loop-plan.md and design/autonomous-build-brief.md in full. The user has authorized this unattended run for phases <LIST> only, overriding CLAUDE.md's per-gate stop for this run (record the exact authorization in the decision log). Do not ask questions.
Rules: never change LOCKED items; take a checkpoint (ServerStorage.CC_Checkpoints + file copy) before each phase; work phase by phase in brief §2 order; meet each phase's acceptance with measured, honestly labeled evidence in evidence/core_P<n>/ (BOT times labeled BOT, emulation labeled emulation, unmeasured numbers labeled ESTIMATE); never invent evidence or mark unfinished content complete; log every autonomous decision in design/decision-log.md as PROPOSED; respect frozen vs improvable (brief §4); stop on any brief §5 condition. Design values come only from the docs; no house style. Update CLAUDE.md and master.md after each phase. At the end write design/core-run-report.md (done / not done / blockers / next) and stop.
```

## 8. Pending before launch
1. Routes/trails/suspense/summit-gauntlet interview (next chat). Must reconcile with LOCKED 25-30 min, beginner protection, fall rules and V4 climb concept.
2. User confirms §0 authorization, run length and phases.
3. User confirms the 43-creature split (§1) and §3 defaults, or edits them.
