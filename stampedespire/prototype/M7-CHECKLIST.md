# M7 real-phone test: checklist (prepared 2026-10-30, P4; prep done 2026-10-30, test not started)

Needs the owner's phone and **one private, unlisted publish that the owner clicks** (SECTIONS-PLAN S11 / STREAMING Q1). Nothing has been published.

## Before the publish (Claude, in Studio, on the owner's OK)
1. **Done (2026-10-30):** Workspace streaming per STREAMING-PLAN §2: `StreamingEnabled` true, `ModelStreamingBehavior` Improved (was Default), `StreamingMinRadius` 128 (was 64), `StreamingTargetRadius` 1024, `StreamOutBehavior` Opportunistic, `StreamingIntegrityMode` PauseOutsideLoadedArea (the last three were already set). Set in the Properties panel: in Studio 0.745 these are not readable/writable from the command bar.
2. **Done:** full BOT 41/41 on that config (Studio in front for all samples), place saved, SHA 67bffaef….
3. **Done:** per-section perf recorder `SS_Perf` (`C.Perf.Enabled` true for M7; set false after M7). At the summit: one `PERFREC` line per section in the client log and a card under the hint line (tap X to close). BOT 8e checks the card layout.

## The owner runs
1. Studio (Sections place) → File → Publish to Roblox → **new** experience, private / unlisted. Click Publish yourself.
2. On the phone (Roblox app, same account): join the private experience. Graphics quality on **Automatic** (record what it settles to).
3. Ride bottom to summit once, playing normally (swap when you like), ~7 min. Then one more run without swapping.
4. After each run: screenshot the perf card at the summit (it stays until you tap X; "TELEPORTED" in its title means the run is not clean). Then open the Developer Console (`/console` in chat) → Memory tab, screenshot; Log tab → filter `PERFREC`, screenshot (the per-section memory tags are only in those lines).
5. Note by feel: stutters (where), heat/battery, any pause or "loading" stall, creatures popping in, text too small.

## Record (per section, both runs)
| What | How | Budget to set from it |
|---|---|---|
| FPS avg and 1% low | recorder (RenderStepped frame times, per section) | LOD / draw distance (M7 goal) |
| Worst frame (ms) and where | recorder | spikes on jumps / summit reset (B9) |
| Memory total + tags (GraphicsMeshParts, GraphicsTexture, Instances, PhysicsCollision) | `Stats:GetMemoryUsageMbForTag` in the recorder; console screenshot | StreamingTargetRadius raise (Q8), creature tri/bone budget (M8) |
| Live creatures (max) and streamed parts | recorder | Herd sizes (P4 raised s5-s10; live max ~64 in the sim) |
| Pauses / stream stalls | recorder (gameplay-paused events if readable), owner's notes | integrity mode, prefetch lead |
| Device, OS, quality level | owner | |

## After
TEST-LOG "M7" entry (the numbers, place SHA, published place id), PERF-BUDGET.md budgets, and the owner decides the LOD / streaming radius / herd caps.
