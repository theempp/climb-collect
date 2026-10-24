# Impossible Mountain first draft

Open ../evidence/mountain_2026-10-24/ImpossibleMountain.VerifiedTraversal.rbxlx in Roblox Studio and press Play. The saved place contains baked terrain plus its generator and gameplay source. It is separate from Phase 1. The authoritative recovered worktree is C:/Users/HOME!/Desktop/climb-collect-mountain-continuation on codex/mountain-continuation. FirstDraft, Traversal and ContinuationFinal remain earlier checkpoints. See CONTINUATION.md for recovery history and current evidence.

## Play

Start at the Expedition Refuge. Follow the flags and climb the ladders. Hold E or tap proximity prompts to rest/extract, investigate nests, fight creatures, and challenge Guardians. Normal Guardian victories unlock the next kingdom. A separate altar begins each Legendary Trial; mastery guarantees its one permanent capture.

Use 1, 2, 3 or the onscreen Special buttons for your equipped companions. Q or Dodge grants a short invulnerability window. A1–A4 cycles the selected collectible Guardian ability. Collection equips up to three companions. Travel works at discovered checkpoints and the refuge. Eggs must be extracted before free incubation/hatching at the refuge. Common eggs take 30 seconds; the other durations are shown in the UI. Training, income and defense snapshots are available at refuge stations. Competition accepts another player's UserId; 0 is explicitly labeled practice.

Studio uses an isolated in-memory profile and resets on Stop. Published games use MountainEmpire_FirstDraft_v1 with session locking; live persistence has not been certified. Do not point this schema at legacy player data.

## Source and integration

mountain.project.json maps only this implementation. A Rojo build creates a source package which generates the mountain on first run; it is not a replacement for the baked review file. tools/sync_edit.luau is the guarded local source sync used in the isolated review Studio. tools/audit_saved.py verifies the baked XML place against the runtime source files and rejects temporary QA scripts.

ServerStorage.MountainGateway is a server-only BindableFunction created at runtime. Invoke it with a loaded Player to enter the expedition refuge. Final Phase 1 gateway coordinates and sanctuary layout were intentionally not guessed; its protected place is unchanged. Integrating the mountain into Phase 1 requires accepted Phase 1 coordinates and a reviewed profile bridge.

## Verification and limitations

See BUILD-REPORT.md and ../evidence/mountain_2026-10-24 for exact results, failures, corrections and remaining acceptance work. StudioTests.run() tests isolated memory stores and snapshots. tests/rules.luau runs with the Luau CLI. Neither substitutes for a published multiplayer/DataStore test. Art is original procedural draft geometry and still requires the premium art/animation pass.
