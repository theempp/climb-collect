# Mountain quality overnight execution — October 26, 2026

Work in progress. No completion, owner aesthetic acceptance, physical device or hosted-save claim.

## Baseline and ownership

Isolated durable clone: `C:/Users/HOME!/Desktop/climb-collect-mountain-quality`, branch `codex/mountain-quality-overnight`, base `a3e896ad624d966c75f57a1c692b58c5f0ef63a0`. The source checkout was clean. Read-only chat inspection found completed sprint/entrance Review03 superseding the brief's historical Review02 pointer. Exact baseline SHA256: `af2c14388fc6be0b7b4739c94f7a5417780f3d271bad4f06037d045fc5cb4da5`.

Immutable local copy: `evidence/mountain_quality_2026-10-26/baseline/Review03.SprintEntrances.rbxl`. The original checkout and all of its Studio sessions are protected. Creature production under Documents/ClimbCollect-GuardianProduction is outside this scope.

Active generation: `Main.server.luau` calls `FreeClimb.build()` only if ImpossibleMountain is absent, then applies MountainEntrances. A baked review skips generation. Historical World/Relief/Polish/TraversalArt modules are inactive for FreeClimb and will remain so.

Editable scope: `mountain/world/FreeClimb.luau`, a mountain-only surface/art helper if needed, geometry regression tests and QA/package tooling. Preserve all server/client/shared modules, Art/CreatureDetails, MountainEntrances, Sanctuary, HUD, custody, guardian/Trial rules, movement values and all creature assets. Preserve exact entrance/egg/rest/altar/hazard anchors unless demonstrated geometry requires a documented shift. No global Lighting or Terrain material-color changes.

Editable region: six mountain section folders within the existing 344-stud playable width, 200-stud section depth and 64-stud rise. Baseline top surface ranges y16..400, z-210..-1410. Existing cliff silhouette envelopes remain the outer limit. Existing voxel terrain is preserved where possible; no regeneration of sanctuary or old terrain generators.

## Initial defects and direction

Source inspection: each section repeats one 344x~136 ramp, a flat terrace, box mass and eight edge blocks; vegetation is sparse and repeated, joins abrupt, straight painted lane dominates. Historical hazard evidence shows a walking-only sandstone notch trap escaped by jumping. Reproduce before fixing.

Improve all six physical surfaces before detail. Keep the central downhill corridor continuous, shape slower optional ascent lines and comfortable landings around it, compose natural strata and biome landmarks within existing silhouette bounds. Palette derives from current Catalog and the approved sculpted-fantasy brief. Decoration is noncolliding; collision should remain simple and explicit.

## Ledger and rulings

- Ruling: Use a full durable local clone of the verified active feature repository rather than a managed checkout of the navigation repo. The native worktree tool targets the older navigation repository; this prevents losing the sprint baseline and avoids the historical ephemeral-checkout losses. Cost: a separate local Git history/root to integrate explicitly later.
- Ruling: Execute the approved brief directly; no repeated brainstorming/phase approvals. This follows the user's execution request and overrides historical interview/stop instructions.
- Pre-flight: Task1 fixed captures/bounds/protection feed Tasks2–4; Task2 collision surfaces must stay clear after Task3 decoration; Task4 must package the baked final geometry, not merely patch sources into the baseline.

## Verification

Baseline: 75 runtime sources match the exact saved Review03; all25 regression suites and75 compiles pass (1,562 assertions), `baseline-regression.json` and `baseline/intake.json`. Source archive and exact terrain property hashes saved.

Studio startup resource limit: user explicitly authorized closing only verified historical reviews. Baseline01 and Review01 sources and eight geometry-class counts matched their saved files (excluding editor CoreGui); byte-hashed copies were made before closing those two processes. Geometry01 failed saved/live comparison and was left open. No current sprint or other active session was closed. Evidence: `historical-close-verification.json`. This comparison does not claim exhaustive unsaved property equality.

Baseline evidence now includes 20 fixed editor views (two whole-mountain and ascent/terrace/escape for each section), six Galaxy A06 landscape simulator views, seven matched desktop render samples, and protected scene snapshot SHA256 `ce158080eac8173b5857100eae6ae9d13aff77fd3bfb04bc6bdf4dc8c4a78f17`. Desktop baseline median frame times 16.62–16.72ms; widest view 122,270 triangles / 256 draw calls. These are Studio measurements, not physical-phone performance.

The first baseline walk attempt supplied the wrong height on an existing sanctuary terrace; this was a QA-target error, not a game defect. Corrected natural movement climbed three sections, entered the active sandstone notch and failed walking out at `(4168.06,205.08,-774.54)`. The exact catch-floor raycast shows a six-stud lip at z=-775. Retained `baseline-natural-walk.json`, `baseline-geometry-red.json`.

Iteration02: all six shaped shoulders and common rock/biome scenery installed. Actual collision audit 7,262 checks passed, including the catch recovery ramp; 98,981 pure surface samples passed. Protected anchors, scenery outside the section folders, sanctuary and Lighting compare exactly to baseline. Saved Working01 is a recovery checkpoint, pending natural traversal and final packaging/cold reopen. Original terrain has not been edited; native save serialization will be audited and restored from the immutable baseline if needed.

Graph status at intake: CURRENT, zero intended-input drift. Query also reported CURRENT this run, unlike the earlier planning discrepancy. Five unresolved links and old overview status heading remain. Graph covers navigation repo/vault only, not this isolated implementation.
