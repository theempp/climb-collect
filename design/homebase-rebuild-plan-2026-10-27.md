# Home-base rebuild/refine plan (October 27, 2026)

Planning only. No game, place or source changes were made. Owner answers come from the 2026-10-27 popups.

## Where to build
Source of truth is the integrated candidate, not this Desktop `src/`:
`C:/Users/HOME!/Desktop/climb-collect-integration`, branch `codex/integration-review01`, baseline `ClimbCollect.Integrated.Review06.rbxl` (SHA256 `b4a79184…ba295`). The HUD/visual chat is separately editing UI sources in `mountain/client/UI/`. Do not touch `Theme`, `Widgets`, `Screens`, `Controller`, `UIPresentation` or `Sprint`. `TycoonHub.luau` changes only if it needs a new request, and must be coordinated.

## Owner decisions (locked 2026-10-27)
| Topic | Choice |
|---|---|
| Home feel | Personalised showcase + free-build hybrid, compact and reasonably sized |
| Free placement | **Decor and displays only.** The production layout (habitat slots, spine, machines, bank) stays fixed and auto-routed |
| Plot size | About **100×130** (today 140×180) |
| Visiting | Anyone can walk into any plot, look and tap to inspect. Visitors cannot collect, bank or change anything |
| Priorities | All four: plot + promenade visuals, tycoon production feel, economy/progression, creature presentation at home |
| Scope | One big pass, reviewed once at the end (with internal saved checkpoints) |

Needs a later decision, not blocking: how many decor slots, how decor is unlocked (coins vs section/index rewards), and whether decor saves into the profile schema.

## How it works today (reference for the builder)
- Layout numbers: `mountain/shared/HomeLayout.luau` (8 plots, 4 per side of a 70-wide promenade, one gate at z -166, ground y 16). Tycoon grid 97 wide × ~115 deep inside the plot.
- Plot services: `mountain/server/Sanctuary.luau` (spawn, Incubator and Training 3-stud markers, Enter Blossom gate prompt, plot allocator `SanctuarySessions`).
- Tycoon rules: `mountain/shared/Tycoon.luau` + `TycoonConfig.luau` (per-habitat rate/value, kingdom bonus, bonus egg every 10th, storage, bag, bank, 5-step automation, 8 h offline cap, linear upgrade costs). Visuals: `mountain/server/TycoonWorld.luau` (untextured parts) and `mountain/client/TycoonConveyors.client.luau` (client-only pooled eggs).
- Geometry: `mountain/world/HomePromenade.luau`. Plots are baked in the .rbxl. Source-only builds still need the baked Sanctuary geometry.
- Creature art: only Mossbun (Blossom Rabbit) is finished. 35 others are procedural.
- Existing design contract: `design/tycoon-redesign.md`. The rules below must be preserved.

## Do-not-break list
1. Server-authoritative economy, request dedupe and rate limits, fail-closed profile validation.
2. The raid → carry → secure-at-gate → incubate loop and bat theft. Theft stays impossible in the sanctuary.
3. Terrain outside the home-base box (z ≥ -208). The 4,352 protected cells there must stay identical.
4. The one-gate exit and the single `SanctuaryExit` trigger.
5. No paid advantages. Raid-only/Trial creatures keep their rules.
6. Design values come only from this project's `references/`. If home references are missing, ask. Never reuse values from other games.

## Work packages (one pass, internal checkpoints)
Save each checkpoint as its own file; do not overwrite earlier ones.

**P0 Baseline.** Open Review06 cold, run the existing suites (home layout 105, tycoon economy 125, scene check 403) and record numbers. Preserve the baseline file. Run the Atlas step on `references/` for the home area before any art decision.

**P1 Plot + promenade visuals.** Shrink plots to about 100×130 and update `HomeLayout.luau` and its tests first. Re-pack the 4+4 layout and shorten the promenade/gate distance (the plan must re-check the 534-stud walk and the 150-stud gate opening). Rework the plot: planting, materials, lodge, fences, lighting, entry frames, the channel/water, the berms. Keep the part budget and mobile frame time (median ≤ ~16.7 ms, 8 homes).

**P2 Showcase + decor.** Fixed set of decor/display slots per plot (trophy shelves, creature displays, kingdom skins). Server-validated placement, saved in the profile as a versioned subrecord. Decor slots must not overlap the fixed production layout.

**P3 Tycoon production feel.** Animated habitats, visible egg production, egg travel on the conveyors, juicy collect and bank moments, machine animation for Processor/Sorter/Collector, full-habitat feedback. Visual-only: no economy changes in this package. Reduced-motion and distance culling stay.

**P4 Visiting.** Read-only inspection: tap a habitat or display to see species, level and rate. Server returns a minimal snapshot for non-owners. Nothing mutating is exposed to visitors. Verify with two clients.

**P5 Economy and progression.** Re-balance with the smaller plot: upgrade curves, offline cap, bonus egg rhythm, bat costs, decor unlock sinks. Provisional numbers in `TycoonConfig.luau` only. Document each change; run the economy suite and add checks for any new rule.

**P6 Creature presentation at home.** Hatch moment at the incubator, idle presence in habitats, creatures wandering or posing near their habitat. Mossbun is the only finished creature, so use the same animation pipeline (`author_offspring_clips.luau`). Other species stay procedural unless art exists.

**P7 Verification and review file.** All suites, compile check, cold reopen, natural-spawn walk for all 8 homes, two-client visit test, perf at all 8 homes, phone emulator views. Save a distinct `ClimbCollect.HomeBase.Review01.rbxl`, write a report, then stop for the owner.

## Honest risks
- One big pass plus four priorities plus visiting is a lot. The internal checkpoints exist so one failed package does not lose the others.
- Shrinking the plot compresses the production grid: 8 habitats, the spine, 3 machines and a bank fit in about 100×130 only with a re-layout, not a scale-down.
- Real phones, hosted 8-player, DataStore and late join stay unverified unless separately tested.
- Free-placement decor adds a saved record and a validation surface. Keep the schema versioned and fail closed.
- Another chat is editing the HUD. Merge conflicts in UI files are likely if you touch them.
