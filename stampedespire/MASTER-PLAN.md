# Stampede Spire + Climb & Collect: merge master plan (locked 2026-10-30)

One document. If a chat, note or plan disagrees with this, this wins. Update it, don't fork it.

## Goal
One Roblox place: the home base (tycoon, habitats, creature showcases, Glassbloom HUD, saves) with the giant 10-section Spire replacing the old mountain. Ends in a polished, fully working build for the owner to playtest and review.

## Decisions (owner, 2026-10-30)
| # | Decision |
|---|---|
| M1 | **Base = main game** (HomeBase PhonePublish02 line, branch `codex/homebase-c`). The Spire is added to it. Home base is not ported into the Spire place. |
| M2 | **Loop: Spire runs earn eggs.** Ride up, swap mounts, earn section medals + coins. Medals/checkpoints give eggs of that biome; eggs hatch at home into creatures that live in habitats and earn coins. Old on-foot raid, guardian, bat and theft systems are retired for this build. |
| M3 | **No combined playtest build until all 10 biomes are finished.** (Owner chose this over a greybox alpha.) Integration plumbing is still built in parallel (Phase 3) so the merge is not a surprise at the end. |
| M4 | Carry-over rules: never overwrite an existing review file (add `ReviewNN`); never publish or spend Robux without a fresh OK; every visual value traces to `references/` / `art/LOOKDEV.md`; `src/` == Studio byte for byte. |

## Source of truth (one place each)
| What | Where |
|---|---|
| Spire art, creatures, concepts, Blender tools | `Documents\StampedeSpire\` (`art/`, `concepts/`) |
| Spire scripts (pre-merge) | `Documents\StampedeSpire\prototype\src\` |
| Merged game | NEW worktree `Desktop\ClimbCollect\game\spire-merge`, branch `codex/spire-merge` cut from `codex/homebase-c` |
| Status log | Obsidian `Climb & Collect/` (Milestones, Decisions, Open Questions) |

Rule: **one chat per phase, one phase at a time per file set.** No more jumping between chats mid-phase.

## Phases

### Phase 0: freeze and organize (small)
- Record the base commit/hash of `codex/homebase-c` and the Sections place (SHA 67bffaef…). Back both up.
- Create the `codex/spire-merge` worktree. Copy nothing yet.
- Close or park side chats (Pit Wall, audio, v1-services) so the merge branch has one writer.
- Done when: both baselines hashed and backed up, branch exists, this plan is in the vault.

### Phase 1: fix the phone bug + load time (Spire only; do first)
Symptom (owner phone test): spawns mid-track, no creatures running, one animal hovering still; slow load, quality low.
Likely causes (hypotheses, not verified; none of this has run on a live server or a phone yet):
1. **Streaming never followed the rider.** The client anchors the rider and moves it by CFrame, so the server may not stream ground ahead (STREAMING-PLAN B3/B4). The herd is client-made and placed analytically, so it can sit over ground that hasn't streamed in: a creature floating in the air (B5).
2. **Spawn/checkpoint or stream-pause.** Every run should start at the bottom (S9); starting mid-track points at a restore or a `PauseOutsideLoadedArea` stall.
3. **Load weight.** Roughly 100 uploaded meshes plus a large atlas, Persistent far shell, and no preload gate.
Steps:
- Reproduce without the phone: Studio local server + client (not Play Solo), which is the first live-server test of `SS_Stream`.
- Run `M7-CHECKLIST.md` on the phone (owner clicks one private, unlisted publish). Get the `/console` log and the PERFREC lines.
- Fix the root cause; add a BOT check that the herd and ground exist under the rider after a server-side join.
- Set budgets (PROPOSED: join to playable under 10 s, 30 FPS floor on the owner's phone, memory below the device limit), then cut: preload gate + loading card, tile streaming, far-fade, RenderFidelity, texture size.
- Done when: owner phone ride bottom to summit is clean, creatures run, budgets met and recorded in `PERF-BUDGET.md`.

### Phase 2: finish the Spire art and creatures (long pole; runs in parallel with Phase 3)
Order from `SECTIONS-PLAN` P5/P6 and `FINISH-PLAN` M8-M10:
- Rebuild art for the 4 signed-off biomes on the new 10-section path (the old art is built for 4 x 1,000 and does not line up).
- Build the 6 new biomes (sheets approved): Rime Fog Forest, Ice Cave Labyrinth, Hot Spring Terraces, Storm Peaks, Wind-Carved Spires, Cloud Sea Ridge.
- 512-stud Atomic tiles, Z origin shift (floats degrade past 16k studs), per-tile FX.
- Creatures: 20 species plus 30 for the new biomes, skinned meshes and clips, rarity tiers, 4 weather mythics, wind gusts at the peak.
- Sign-off per biome (side-by-side with its sheet) before moving on.
- Pipeline per biome: atlas (tokens) -> component/art build -> motion -> design-reviewer.
- Done when: all 10 biomes and species signed off, BOT passing, phone budget still met.

### Phase 3: integration plumbing (parallel to Phase 2, not for playtest)
Work in `codex/spire-merge`. Spire may be greybox here; this phase proves the wiring.
1. **Import** the Spire scripts as a namespaced module set (`SS_*`) beside the home base services. No name collisions.
2. **Place the mountain.** Home base sits near the origin at y16, the Spire starts at the origin and climbs -Z. Decide one offset (use the Spire's Z origin shift) and put the grand gate at the Spire start apron.
3. **Retire the old mountain** in the merge branch only: terrain chunks, colliders, guardians, raid, bat and theft code, their remotes and tests. Keep protected-file hashes of what is removed.
4. **Saves.** Fold `SS_Progress_v1` (coins, ascents, best, upgrades, medals, journal) into the main profile as a versioned `spire` section. Fail closed on load errors.
5. **Egg bridge (M2).** Server-validated: section medal and checkpoint events grant eggs by biome. Numbers PROPOSED, see below.
6. **Controls and camera.** Hand-off between home-base movement and the scripted ride camera at the gate, summit return and respawn.
7. **HUD.** Spire UI (timeline, shop, journal, perf card) restyled into Glassbloom tokens; one HUD, nothing overlapping on phone.
8. **Workspace streaming settings** and the server rider feed carried over and checked against the home base.
9. **Tests.** Port the Spire BOT next to the 46 home-base suites; all green in one place.
- Done when: a greybox merged build passes all suites and a two-client Studio run (join, ride, summit, egg, hatch, habitat, save and reload).

### Phase 4: combined polish and test (after 2 and 3 land)
- Swap the final art into the merged place; re-run BOT, suites, two-client and the phone M7 on the merged build.
- Economy pass (coins per ride vs habitat income, egg rates). Audio pass. Design-reviewer on every screen. Fix list from review.
- Done when: owner phone playthrough of the full loop is clean, with no console errors and `src/` == Studio.

### Phase 5: release candidate
- Saved final place + SHA, report, list of unused asset IDs (D4), Obsidian milestone.
- Owner playtests and reviews. Publishing and any Robux items stay separate owner decisions.

## Proposed numbers (not approved)
- Eggs: 1 egg per section medal tier earned for the first time (bronze/silver/gold), plus a bonus egg at the summit. Egg rarity from the biome's species list and `Rare`.
- Spire coins convert 1:1 into main coins until balance testing says otherwise.
- Budgets in Phase 1 above.

## Risks
- **Biggest:** Phase 2 art is large (6 biomes, about 50 species). With M3, nothing combined is playable until it finishes. Mitigation: Phase 3 proves the wiring early; Phase 1 gives a real phone check on the Spire alone.
- Streaming on a live server is unproven (the likely phone bug). Phase 1 settles it before more art is built on it.
- Studio instance limit and shared Studio sessions: serialize runs.
- Studio saves can drift terrain data; the old mountain terrain is being removed, so check what a save rewrites.
- Tier-1 section times are a baseline; slow mounts run about 33% longer.

## Next action
Phase 0, then Phase 1 in a fresh chat. Phase 1 needs the owner's phone and one private publish click.

## Phase 0 result (2026-10-30)
- Backups + hashes: `Desktop\ClimbCollect\archive\merge-baselines-2026-10-30\` (`HASHES.txt`, git bundle of `codex/homebase-c`, Spire `src/` copy).
- Main-game base: `codex/homebase-c` at `d80dc7f` (HUD polish); `PhonePublish02.rbxl` SHA 0ddde11c… matches it.
- Spire base: `StampedeSpire.Sections.rbxl` SHA 67bffaef…, Greybox 2c0674ba…
- Merge worktree: `Desktop\ClimbCollect\game\spire-merge`, branch `codex/spire-merge` from `d80dc7f`, clean.
- Open: `PhonePublish01.rbxl` was re-saved 2026-10-30 1:46 PM (SHA ce3f2af2…), newer than 02. Backed up; not used as base.
- Not done: side chats (Pit Wall, audio, v1-services) are still the owner's to close; I can't close them.

## Phase 1 log (2026-10-30)
Code read only; nothing run, nothing changed in `src/`.
**Lead (not verified):** `SS_Ride.client.luau` builds the herd at load. Skinned creatures call `makeMeshCreature` (l.91-113), which parents the model to `SS_Herd` (l.97) and then calls `AnimationClipProvider:RegisterAnimationClip(KeyframeSequence)` (l.84) and `LoadAnimation` (l.102) with no pcall. The code comment says the clip ids are for "Studio test sessions"; uploaded ids were deferred to sign-off, and no animation asset id exists in `src/`. If that call errors in a published client, the script dies mid-build:
- one creature stays parented at its template position = the floating animal that doesn't move;
- the pool never fills, so `sendToFoothills` (l.1271-1283) returns false forever ("nothing placed yet") and the rider stays where the character spawned = mid-track, no creatures, nothing to do.
This matches all three symptoms. Roblox docs checked: `RegisterAnimationClip` page gives no live-game behavior, so it is unconfirmed.
**Other suspects, lower:** streaming focus not following the rider (STREAMING-PLAN B3/B4); `SS_Stream` never run on a live server.
**Evidence needed:** the phone `/console` Log tab, red error lines near join (client script name + line). One screenshot decides it.
**Fix if confirmed:** upload the gallop clips as private Animation assets (FINISH-PLAN D1 allows it), use their `rbxassetid` ids; wrap clip load in pcall so a bad clip degrades to a procedural gallop instead of killing the herd; add a visible on-screen error/diagnostic line.

### Phase 1 result: root cause CONFIRMED (2026-10-30)
- Owner published the **Greybox** file (placeid 88100507828614, 4 old zones), not the 10-section Sections place. Joined it on this PC; the desktop client log shows: `Usage error: RegisterAnimationClip can only be called in Studio` at `SS_Ride` line 72 (clipId) <- 89 (makeMeshCreature) <- 109 (makeCreature) <- 190 (pool build). That kills the herd build: one creature stays parented at its template spot (the floating animal), the pool never fills, `sendToFoothills` waits forever. Same code is in the Sections line (`prototype/src`).
- **Code fix written in `prototype/src` (NOT yet in Studio, not republished, not tested in Studio):** `clipId` uses `C.ClipAssets[model][clip]` if set, calls `RegisterAnimationClip` only in Studio (in a pcall), else returns nil; `makeMeshCreature` wraps `LoadAnimation` in a pcall and builds the creature anyway (rigid mesh with a bob, `c.skinned = true`); `SS_Config.ClipAssets = {}` added.
- **Still needed:** (1) sync the two scripts into the Sections place in Studio, run BOT; (2) upload the gallop clips as private Animation assets and fill `ClipAssets` (real leg animation on phones); (3) republish the Sections place privately for the phone test (owner clicks Publish).

### Phase 1: fix synced into Studio (2026-10-30, 2:32 PM)
- Dev server started (`art/tools/ss_devserver.py`), Sections place opened, `task.luau` sync run via the command bar (needed one Continue on the HttpService prompt). Devserver log: `SS_Config=37019 SS_Ride=72988`, equal to the files on disk.
- Play Solo (phone emulator): rider on a creature, herd running, no script errors in the log.
- Saved: `StampedeSpire.Sections.rbxl` SHA256 e5fd622fad4abc71… (previous 67bffaef… backed up in `Desktop\ClimbCollect\archive\merge-baselines-2026-10-30\`).
- **Not proven:** the fixed branch only runs outside Studio, so Studio can't test it. Proof needs a private publish + a real client join (owner clicks Publish; I join and read the client log).
- Still open: upload gallop clips as private Animation assets and fill `ClipAssets`; load-time/memory work from the M7 phone numbers.

### Phase 1: gallop clips uploaded (2026-10-30, 2:40 PM)
Five private Animation assets uploaded to the owner account (Creator = Me, via Explorer > Save / Export > Save to Roblox; not published). Wired into `SS_Config.ClipAssets`; synced to Studio (SS_Config=37400); Play Solo ok, herd runs, no errors.
| Model | Asset id |
|---|---|
| taiga_elk | 133688782933288 |
| woolly_reindeer | 72537654229111 |
| musk_ox_calfrunner | 82163452524648 |
| snowshoe_hare_hound | 128318368515536 |
| pine_boar | 70586627577149 |
Titles: "SS gallop <model>". Only `gallop` is used by the game; idle/swap_jump/faceplant clips were not uploaded. Creator Hub cleanup list (D4): these 5 are in use.
Next: private publish (owner) -> I join and read the client log to prove the fix on a real client.

### Phase 1: fix VERIFIED on a live client (2026-10-30, 2:52 PM)
- Owner published the Sections place privately: PlaceId **71842667276442**, UniverseId 10773861929 (Studio log). Saved file SHA 30ddbba1… is what was published.
- Joined on this PC (desktop client, 3440x1440, quality 10). Client log: **0** `can only be called in Studio` errors, 0 `CreatorError` lines. The in-game perf recorder reported `run 1 clean` through all 10 sections: 60 FPS, 1% low 50-53, worst frame 19-26 ms, pauses 0, live creatures 45-60, parts 555-1,071, no teleport. (Recorder `mem` readings of about 2.1 GB are total client memory on desktop; texture 47 MB, mesh 2 MB.)
- Streaming held on a live server for a full ride, so the B3/B4 suspicion did not show up on desktop.
- **Not yet proven:** the owner's phone (the original symptom). Desktop has no load-time or memory pressure like a phone.
- Minor: `SS_Perf` logs "Memory tracking is currently disabled" about 350 times per run in a live client (harmless; fix with a `Stats.MemoryTrackingEnabled` check, or turn the recorder off after M7).
- Stale: the Greybox publish (PlaceId 88100507828614) is the old 4-zone build; leave or delete in Creator Hub.

### Phase 1: load-time work, step 1 (2026-10-30, 3:10 PM)
Code (synced, Studio Play ok, saved; **not yet republished**, owner clicks Publish):
- **Staged herd build** (`SS_Ride`): biomes 1-2 (79 creatures) built before the ride, the other 252 built in the background, 4 ms of work a frame (`C.Pool.EagerZones`, `BuildSliceMs`).
- **`LOADREC` log lines** (client log / phone `/console`): eager build time, background build time, "playable" time, `game.IsLoaded`, content queue.
- `SS_Perf`: turns on `Stats.MemoryTrackingEnabled` and skips memory reads when it is off (stops the ~350 warnings; fixes the bogus "mem" total).
Desktop Studio numbers: eager 25 ms; background 1.5 s; playable 1.6 s after script start. **The herd build was never the desktop bottleneck** (about 0.1 s in one go), so on a phone expect a small gain at most. The real phone cost is probably asset download/decode and memory, which only a phone run can show.
Studio-only noise: `DataStoreService: StudioAccessToApisNotAllowed` now appears because the place is published (Studio cannot reach DataStore); harmless in a live client.
Next: owner republishes, retests on phone, sends `/console` Log (LOADREC + PERFREC) and a stopwatch time from tapping Play to being on a creature.
- **Save note:** after the first publish, Studio's File menu has no local "Save" (only Save to Roblox / Publish / Download a Copy), so `StampedeSpire.Sections.rbxl` on disk is still the 2:36 PM state (SHA 30ddbba1…, with ClipAssets, before the staged herd build). `prototype/src/` is current and equals Studio. Take a local copy with File > Download a Copy when needed.

### Phase 1: load-time win 2 (2026-10-30, 3:10 PM): 97% fewer replicated instances
- Census (`art/tools/studio/census.luau`, read-only): ReplicatedStorage held **18,930** instances; **18,921** were `SS_Creatures`, almost all raw animation KeyframeSequences (5 models x 4 clips, about 3,700 each). Every client downloaded them at join, and the game only plays the uploaded gallop assets.
- Fix: `SS_Creatures.Clips` moved to `ServerStorage.SS_CreatureClips` (`moveclips.luau`; `creatures.luau` import job now writes there; `SS_Ride` Studio fallback guarded). ReplicatedStorage is now **496**. Play Solo: herd runs on the uploaded clips, no clip failures, LOADREC playable 1.6 s.
- Not republished yet. Not measured on a phone.
- Remaining candidates (need phone numbers first): texture memory (47 MB per PERFREC: skybox faces + atlas?), 2,760 collision slabs streamed to clients, far-fade and Persistent shells once art returns.

### Phase 1: load-time sweep, what is NOT a win (2026-10-30, 3:25 PM)
- Textures: our only uploaded textures in the current place are the zone-4 skybox faces, 512x512 each (about 170 KB files). The 47 MB texture figure is engine/default (sky, avatar, UI, shadows), not ours. No action.
- Place file is 0.54 MB; client scripts, lighting and herd build total about 1.6 s on desktop. Code-side wins are exhausted until a phone run says otherwise.
- The 100 uploaded art meshes and the atlas are parked in ServerStorage.SS_Mountain_Parked (ShowGreybox), so they do not load today. **They will when art returns (Phase 2): budget for tile streaming (STREAMING-PLAN) and re-measure on the phone at that point.**
- Open, needs a design decision: a custom loading card (SECTIONS-PLAN S11 says yes). Every colour/type value must trace to `art/LOOKDEV.md` / `palette.json`, so it needs an Atlas/approval pass; not built.
- Open: `C.Perf.Enabled` stays on until M7 is done, then set false.

## Loading card plan (2026-10-30; owner decisions L1-L2)
| # | Decision |
|---|---|
| L1 | Card shows the name "STAMPEDE SPIRE" (working title, confirm), the Zone 1 tagline, and a thin progress bar driven by **real** steps. |
| L2 | If loading has not finished after **20 s**: show a plain error line, write it to the log, then drop the card so the player gets control. Never trap a player behind it. |
Values: only existing tokens. Backing = Zone 1 `TitleStroke` #2E3C4E, text and bar = `TitleColor` #E9EAF0, tagline = Zone 1 `Tagline`, font = the title-card font already in use (Gotham, flagged in D5 for sign-off), fade = `TitleFade` 0.5 s. Anything not traceable to these is not added.

**Parts**
1. `ReplicatedFirst.SS_Loading` (LocalScript): `RemoveDefaultLoadingScreen()`, builds the card at once, safe-area / IgnoreGuiInset so it covers the phone topbar, sits above every other GUI.
2. Real steps (each 0.25 of the bar): (a) game loaded, (b) the 5 uploaded gallop clips + 5 creature meshes preloaded (`ContentProvider:PreloadAsync`), (c) first two biomes' herd built, (d) ground around the spawn streamed (`SS_Remotes.Prepare(-30)` result). `SS_Ride` publishes readiness through attributes (`SS_Ready_*`) on ReplicatedStorage; `SS_Loading` only reads them.
3. Exit when all four are done **and** the rider is mounted (the existing LOADREC "playable" moment), fade out over 0.5 s, then destroy. 20 s timeout per L2 with the error line (the failing step named).
4. Respawn / summit reset must not bring the card back (first load only).

**Pipeline (global rule order)**
architect (this plan) -> atlas (confirm token mapping from LOOKDEV/palette; 1 page of intel in the project) -> component-builder (SS_Loading + readiness attributes in SS_Ride/SS_Stream) -> motion (fade only, uses TitleFade) -> design-reviewer (phone-emulator screenshots, reads against the Zone 1 sheet).

**Checks (BOT additions)**: card exists within 0.2 s of start; covers the full screen at 3 phone sizes; bar reaches 100% only after the four steps; gone within 1 s of playable; timeout path shows the error line and removes the card (simulated by blocking a step); no card after respawn.

**Open for you (not blocking):** confirm "STAMPEDE SPIRE" as the displayed name; Gotham font sign-off (D5).

### Loading card built (2026-10-30, 3:57 PM)
- New `prototype/src/SS_Loading.client.luau` (ReplicatedFirst), `SS_Config.Loading`, readiness attributes `SS_PoolReady` / `SS_Playable` set by `SS_Ride`, `task.luau` sync map updated. Synced to Studio (SS_Loading=6309, SS_Config=38113, SS_Ride=75324).
- Studio Play Solo, phone emulator (iPhone 16 Pro landscape): card shows STAMPEDE SPIRE, the zone-1 tagline and the bar on the zone-1 backing; steps log as `LOADREC card: <step> done`. Normal run: all 4 steps done at 1.15 s, card closed at 1.77 s. Stall test (a debug flag held the ground step): bar stopped at 3/4, at 20 s it logged `stalled after 20 s, missing ground` and dropped the card.
- Not done: BOT checks are not added to `SS_Bot` yet (the plan's list was run by hand); only one phone size seen; design-reviewer pass; the error line text was not captured on screen (it shows 2.5 s); not republished; no phone run. Name "STAMPEDE SPIRE" and the Gotham fonts still need owner sign-off.
