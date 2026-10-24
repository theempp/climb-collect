# Impossible Mountain build — 2026-10-24

Latest authority: the owner's complete mountain request, preserved at mountain/REQUEST.txt on branch feature/six-kingdom-mountain-first-draft. It supersedes older mountain layouts. Phase 1 remains protected and awaits its separate review.

## Isolation and baseline
Original checkout: C:/Users/HOME!/Desktop/climb&collect, branch codex/expedition-fairground, baseline e126557, substantial existing dirty/untracked work left intact. Implementation worktree: C:/Users/HOME!/.codex/worktrees/six-kingdom-mountain/climb&collect. No merge/push/publication.
Phase 1 Step3 review backed up byte-for-byte in evidence/mountain_2026-10-24/Phase1.Preserved.rbxl. Thirty existing place hashes recorded in protected-before.json. No Phase 1 gateway coordinates assigned.

## Current implementation
New deterministic continuous mountain, six elevation kingdoms, twelve side branches, eighteen landmark identities, six arenas, eighteen checkpoints, 24 climbing ladders, moving optional platforms, timed hazards, shortcuts, server-validated fast travel. New roster has 36 regular species and six Guardians with modular original draft geometry. Separate profiles implement three unsecured egg slots, extraction, recovery, timestamp incubation/free hatch, three-creature teams, level cap 50, evolution15/35, specialization25, sanctuary income/training, normal/Trial separation and single permanent captures. Async defense snapshot competition runs without an online defender. Refuge is an integration fixture; final Phase1 sanctuary is untouched.

## Verified milestone
- Luau CLI: 120 rules checks pass (including malformed team payload rejection, income carry and Trial mastery gates).
- Studio: 50 isolated memory-store/snapshot checks pass. Save failure, lock contention, offline timestamps, profile replay and delayed autosave/leave race checked. The new delayed-save regression failed before the fix and passed afterward. Not live DataStore networking.
- Natural spawn to Blossom pre-Guardian approach: 43/43 walking/climbing targets, 163.342s, no position/progression injection. Evidence natural-blossom-ascent.json.
- Natural arena approach and normal Floravelle victory: next kingdom unlocked and 80 coins awarded. Separate natural Legendary Trial: guaranteed Floravelle capture. Evidence natural-floravelle-victory.json and natural-floravelle-trial.json.
- Runtime loads without console errors in this test. Full mountain traversal is still in progress; do not infer its completion.

## Corrected assumptions and fixes
Rojo executable is installed (7.6.1); the default shim has no project manifest, so the verified direct executable is used. Older notes saying no Rojo are historical. Main old world/profile/roster code is incompatible with new design; only the store adapter was reused in a separate namespace. Studio MCP require caches are VM-local, so live tests use actual game scripts/inputs or explicitly isolated test profiles.
Initial smooth cone was rejected visually and replaced by irregular heightfield terrain. First walk found a buried access connector and blocked ladder headroom; repaired before successful natural ascent. Review found summit ceiling/carve bugs, trial early-kill issue, unvalidated team dictionary keys, fractional income loss, recovery reconstruction, Guard specialization and HUD overlap/timers; fixes implemented and applicable tests recorded.

## Remaining acceptance limits
Procedural art is first draft, not premium final mesh/animation quality. Complete full-mountain ascent/side-branch verification, final save/reopen source and terrain audit, mobile/eight-client performance, live DataStore save/rejoin and user playtesting remain. Ascent target18–25min is not yet established. The request ends after Caeloryn ability1; other three names/effects are provisional. Final gateway integration awaits Phase1 acceptance and coordinates.

This record will be updated after the final save and checks.
