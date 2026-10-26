# Sprint and mountain entrances implementation plan

> Execution: native implementation, authorized by the owner in the originating chat. No repeated design interview. Use executing-plans, test-driven-development and verification-before-completion.

**Goal:** Make travel faster and more direct while preserving every 180x220 home plot and physical-exit ownership.

**Architecture:** Server-owned movement policy accepts boolean sprint intent, applies walk16/sprint27 and a provisional 0.9 carry multiplier. Desktop holds Shift; a mobile toggle uses the same remote. A movement-priority running clip leaves the existing two-arm carry override intact. Add two side openings and broad frontage ramps; exits share z=-166 and contiguous coverage across the mountain face.

**Spec:** Owner-approved handoff in this chat, October26,2026. All numeric values remain provisional. No stamina addition, paid assets, publication or original-place changes.

**Approaches considered:** Keep central gates and only raise speed (does not solve outer-plot travel); move/shrink plots (violates owner constraint); widen frontage with left/center/right physical approaches (selected scope).

**Files:** shared/MovementRules, server/Movement, client/Sprint, world/MountainEntrances; Main integrates services. Existing EggCarry retains final shoulder authority. New review copy preserves Review02.

## Review focus

- Malformed/spammed sprint requests cannot set arbitrary speed; release/focus loss/death clears intent.
- Cargo pickup, loss and put-down immediately recalculate speed; secured cargo still weighs the same.
- Run tracks stop airborne/idle/seated and on respawn; carrying arms remain posed.
- Side exits grant ownership once at the same boundary; no earlier banking on approach.
- Plot sizes/transforms and protected unrelated places remain unchanged; wide paths clear existing terrace collision.

## Tasks

- [x] 1. Add failing policy/service tests for four speeds, boolean validation, request pacing, dead/seated state, carry changes and reset. Run RED, implement MovementRules/Movement and Main integration; run GREEN plus custody/lifecycle regression.
- [x] 2. Implement Shift hold, visible mobile toggle, focus/respawn cleanup and running track; verify actual keyboard and simulator mouse input, running animation and cargo shoulders.
- [x] 3. Add idempotent entrance builder with broad frontage ramps, two side cuts/openings and contiguous safe exit volumes. Verify unchanged plots and walk routes from both outer plots, including loaded return through each side exit.
- [x] 4. Save a new Review03, cold-open, compile and compare runtime sources, inspect console and exclusions. Record evidence and limitations, append vault pointers, refresh graph/status; leave Review03 visible in Edit ready for Play.

## Execution ledger

Baseline clean at c1c288c; Review02 expected hash6b0773db... Graph CURRENT; isolated source outside graph. Lifecycle8 pass. Initial free-climb test command used a nonexistent filename; no test was executed by that command, corrected after enumerating tests. Existing durable feature checkout reused; no extra worktree or unrelated session mutation.

Final evidence: design/sprint-entrances-review-2026-10-26.md. Returned side-ramp seam fixed by RED/GREEN; AnimationConstraint carry guard fixed by RED/GREEN; rapid repress fixed after independent review. Final artifact terrain restored to Review02 and cold-open verified.
