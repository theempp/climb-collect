# Expedition hall + sunny slice — scoped implementation plan

Date: 2026-10-23. Status: APPROVED by the owner in the widget (2026-10-23), to be built in a new chat. Nothing is built yet.
Spec: [four-mountain design](../specs/2026-10-22-four-mountain-lobby-design.md) §4, §7, §9 step 2. Owner choices: [quad.md](../../../quad.md).

## Owner choices for this phase (widget, 2026-10-23)

- **Hall site:** an isolated hall in its own space, away from the mountain. Departures teleport to the sunny trailhead. The old Fairground is archived to ServerStorage, not deleted.
- **Hall look:** generate concept references from the spec text first. They count as references only after the owner approves them in the widget.
- **Sunny slice:** Shepherd trailhead → Camp 1 only. The route above Camp 1 stays as it is, so the summit reset can be tested on a real ascent.
- **Window previews:** 3D dioramas behind enchanted glass. Rainforest, volcanic and snow show as Coming Soon.
- **Approval round:** plan approved; about 6 concept images on the connected image generator (credits OK); hall far off-map; ambient sound from the free Roblox Creator Store audio library (marketplace audio allowed for sound only).

## Workspace

- Worktree `C:\Users\HOME!\.codex\worktrees\movement-finish\climb&collect`, branch `claude/lobby-sunny` (off `claude/four-mountain-movement` @ `833bbce`). Existing dirty and untracked files are left unstaged.
- Review file `ClimbAndCollect.FourMountains.LobbySunny.Review.rbxl`. It is a byte copy of the movement review (SHA256 `7737b1f8…`). Studio `3f15b0e6`; Edit mode, HTTP off, walk 16, 2 checkpoints.
- Sync only through `tools/sync_core.luau` on 8771 (worktree root) in Edit mode, with checksums checked. After every save: restore SmoothGrid from `ClimbAndCollect.BeforeFairground.rbxl`, then verify on disk.

## Phase 0 — Baseline (before any change)

1. Checksum all manifest sources against Studio.
2. Hash the protected groups (`creatures/`, `CC_Creatures`, `CC_CreatureStage1` and the four other groups from the movement baseline) and the terrain.
3. Record instance counts and a perf sample at the Fairground spawn and Shepherd trailhead.
4. Run the existing suites (Movement, Traversal, Expedition, A1, Summit, DailyPractice) so later regressions are visible.

Evidence: `evidence/lobby_sunny_2026-10-23/P0_baseline.json`.

## Phase 1 — Concept references (owner gate)

1. Generate about 6 concepts (owner approved the credit spend) with the connected image generator, prompted only from spec §4 wording:
   - hall interior from the spawn
   - cobblestone wall with timber rib
   - flagstone floor with an inlay
   - an enchanted window above a departure area
   - a planted bed with a tree and vines
   - the bank and shop frontage
2. Show them to the owner in the widget. Each image is kept or rejected.
3. Copy the kept images into `references/lobby/` with a manifest (prompt, source and approval date).
4. The atlas step writes `design/hall-intel.md`. Every colour, material and density value cites one approved image. Anything that can't be traced is left out.

Gate: no hall art (Phase 5) starts before this exists. Phases 2–4 use neutral, untextured blockout parts.

## Phase 2 — Hall structure and service contract

1. Add a new generator, `src/world/ExpeditionHall.luau` → `Workspace.World.Hall`.
   - Location: an empty area outside the terrain (proposed: centre about (0, 400, 4200), more than 1,400 studs beyond the map edge).
   - Layout: a circular floor, curved walls and a roof shell.
   - Four window bays at N/E/S/W, each with a departure area. East = sunny.
   - Bank and shop off the central ring.
   - Three side entrances: Home, Showcase and Practice.
   - The broad central circulation ring stays open.
   - Size comes from measured walking: bank and shop should be 5–8 s from spawn at lobby speed 22, not from a fixed radius.
2. Keep the existing service contract.
   - `Anchors` gets the same 12 ServiceIds, plus `SafeBounds` and new `Depart_<mountain>` anchors.
   - Generalize `LobbyAnchors.resolve`/`contains` to look for the `Hall` root first. Then remove the hard-coded `Fairground` lookups in `Training`, `PublicProfile` and `Home`.
   - This keeps the lobby movement zone (run 22), bank validation, summit return, the home door, practice and Exchange displays working.
3. Side entrances:
   - Home uses the existing Home transport.
   - Practice teleports to the existing TrainingYard through `Traversal.travel`.
   - Showcase sends the player to the existing collection portfolio prompt for now.
   - Each return goes to the same hall.
4. Archive `Fairground`, `FairgroundFinish` and `CommerceDisplays` to `ServerStorage.BeforeHall`, then move the SpawnLocation into the hall. Mountain routes, gates, cabins and terrain are untouched.
5. Client lighting profile: the hall and the mountain swap local Lighting/Atmosphere on a zone change, because Lighting is global per client. The hall profile values come from Phase 1 intel. Until then the current Lighting is used.

## Phase 3 — Destinations, travel, extraction, saves

1. Shared `DestinationCatalog`: id, name, difficulty, preview text, `available`, and spawn/camp anchors.
   - Sunny is live.
   - Rainforest, volcanic and snow are `preview` only. They cannot be departed to and show no paid offer.
2. Server `Travel`:
   - The departure prompt opens a panel showing details, the "preview, not live conditions" note, a saved camp if there is one, and Confirm.
   - On Confirm, the server checks the catalogue id, availability/access, alive and grounded, and that no travel is in flight (one per player).
   - It then calls `Traversal.travel` to the trailhead or the saved sunny camp.
   - A client-sent position is never trusted.
3. Extraction prompt at Camp 1 (the only sunny camp in this slice). The existing summit return is kept.
   - Both return the player to `Return` next to the bank with the cargo unchanged and unbanked.
   - Duplicate requests are serialized.
4. Profile, schema +1 with a migration:
   - Add `expedition.mountains.sunny = {highestCamp, ascentSeq, summitCompletedThrough}`, migrated from the existing top-level `highestCamp`.
   - The existing `expedition.summit` run state is kept.
   - After summit completion and return, the summit reset clears only sunny's camps and run. Collection, achievements and access stay.
   - It shares one transaction with the award, so a reconnect can't replay it.
5. Tests:
   - CLI rule tests for catalogue access, travel serialization and the reset.
   - A Studio suite for duplicate departures, a locked or unknown id, extraction cargo kept unbanked, resume at the saved camp, reset after summit, and rejoin with the mock store (labelled mock, not a DataStore test).
   - All existing suites must still pass.

## Phase 4 — Sunny slice: trailhead → Camp 1

1. Parts and vegetation only, with no terrain regeneration. Small local terrain edits are made only after a probe, with a terrain-region backup.
2. Add, along the Shepherd trailhead → Camp 1 stretch:
   - denser forest groves that frame the trail
   - two sunny clearings
   - two new authored climbs (rooted rock / ladder), with rests
   - one exposed overlook with a view down
   - existing waterfall sightlines kept where the route passes them
3. A sunny arrival point at the trailhead, as the safe departure landing.
4. Checks:
   - Collision clearance along the trail; no readable climb cue is hidden by foliage.
   - Bypass profile ±36 across the new climbs.
   - A bot walk with 0 stuck, then a real-input walk.
   - Hands-on % and the measured time for this stretch, reported against the 15–20 min whole-route target (pro-rata, labelled ESTIMATE).

## Phase 5 — Hall art pass (needs Phase 1 intel)

1. Finished walls, ribs, vaulted roof, window frames with restrained runes, floor and inlays.
2. Planting: 2–3 indoor trees in planted beds, ferns, moss, vines.
3. Props: benches, maps, climbing gear, lanterns, crates, textiles and destination displays.
4. Lighting: warm lanterns over gathering areas and softer roof daylight over the planting.
5. Four dioramas with their own light and weather particles, plus a reduced-motion and phone quality tier.
6. Ambient sound (hall room tone, distant per-window weather) from the free Roblox Creator Store audio library, which the owner approved. Record each asset id in `design/hall-intel.md`. No marketplace models or meshes.

## Phase 6 — Verification and evidence

1. Real keyboard and mouse input on desktop.
2. Landscape phone in Device Simulator: departure panel, prompts and touch sprint button.
3. Captures, desktop and phone: spawn, each window, bank/shop, roof, side entrances, trailhead and the slice.
4. Collision, camera-clipping and navigation checks through the furnished hall.
5. Perf: FPS, worst frame and streamed instances in the hall, at the trailhead and at the worst slice vista, compared with Phase 0.
6. Full loop:
   - spawn → depart → climb → Camp 1 extract → bank
   - rejoin → resume at Camp 1
   - summit → return → sunny reset
7. Two clients: split, extract and reunite.
8. Save → SmoothGrid restore → disk verification (hash, sources, terrain, 7 protected groups, HTTP off, 2 checkpoints) → reopen check.
9. Docs after each phase: handoff, CLAUDE.md, master.md, vault and graph status.

## Not in this phase

- Rainforest, volcanic and snow content beyond their previews.
- Paid access and products, weather and day/night.
- New creature species.
- Sunny above Camp 1.
- Physical devices and live DataStore. These stay listed as unverified.
- Publishing.

## Self-review

- Spec coverage of §9 step 2: hall ✓, sunny slice ✓, departure and extraction ✓, physical bank ✓, unfinished camp save ✓, completed-ascent reset ✓, return-and-rejoin loop ✓, detailed lobby visuals ✓ (Phase 5/6).
- Risks:
  1. `Fairground` is hard-coded in 4 server modules plus the anchor contract. All are found by grep and covered in Phase 2.
  2. Lighting is global, so the hall's look needs the client profile swap.
  3. Moving the spawn changes the tutorial start. Tutorial beats that assume the Foothold need a check in Phase 2.
  4. Concept generation spends credits on the connected image service (approved for about 6 images).
- Uncertain: the proposed hall coordinates must clear StreamingEnabled target radius so the mountain is not loaded while players are in the hall. This is measured in Phase 2.
