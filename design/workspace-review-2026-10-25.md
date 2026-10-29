# Workspace review and owner playtest guide

Updated October 25, 2026 (America/New_York). This is the current navigation and review record. Historical reports remain intact. No game code, place contents, publishing settings, purchases or existing folders were changed during organization.

## What happened across the recent chats

| Work | What exists | Evidence and acceptance |
|---|---|---|
| Mountain and sanctuary integration | Final56 six-kingdom mountain + Step3 eight-plot sanctuary + recovered HUD; one place, three gates into Blossom; existing mountain profile authoritative | Earlier integration report: 1,102 checks; natural egg → secure → home → incubate → hatch → equip loop and three-client plot ownership. Durable copies now live in both feature clones below. Original f520 path is historical/missing. |
| Tycoon | Two starter habitats expanding to eight; assignment/swap, production eggs, storage, batch collect/bank, upgrades, five automation stages, offline cap and six-tab management hub | Review06; recorded 1,344 CLI checks/90 compiles, actual eight-client natural play, late join/replacement and synthetic capacity tests. Final label correction followed the eight-client run; fresh cold-start subsequently verified. Human pacing, premium art and hosted same-account saves remain open. |
| HUD | Locked Playful & Bold Q1–Q28 presentation; eight hubs/26 tabs; creature silhouettes, combat-only Dodge, clearer capabilities/disabled actions, free palettes, refresh/focus/action-lock fixes | Review02; recorded 1,316 checks/90 compiles, four simulator large-text matrix, real assignment/production bank input, fresh reopen. Physical phone acceptance remains open. Missing services are explicitly unavailable. |
| Guardians | Five measured 3D silhouette studies; multiple AI base trials; Veylith Blender v003–v006 feather/face/talon refinement, six prisms and 31-bone gentle-idle source proof | v006 source/GLB roundtrip: 122 meshes/363,634 triangles. Work in progress, not runtime-ready; no accepted finished boss/adult pair. Optimization, bakes, folding, adult collectible and Studio acceptance remain open. |
| Older builds | Fairground, four-mountain movement and hall/sunny slice | Historical alternatives/checkpoints. Keep accessible; do not confuse with the six-kingdom Mountain Empire candidate. |

Test counts above summarize earlier evidence, not new test runs in this organization pass.

## Open these reviews

**HUD and general loop review:** [exact verified HUD recovery copy](C:/Users/HOME!/Documents/ClimbCollect-HUD-Recovery-2026-10-25/ClimbCollect.HUD.Complete.Review02.rbxlx). SHA256 `b712e1654653519e1d060c05f5e976c2b6ca8737e3d5604ce7f88b5c802cf62b`. Source: `C:/Users/HOME!/Documents/ClimbCollect-HUD-2026-10-25`, branch `codex/hud-completion`, current inspected HEAD `ddf870a`, implementation `5831582`. Full walkthrough: that clone's `design/hud-completion-report-2026-10-25.md`.

**Newest tycoon review:** [Tycoon Review06](C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/outputs/ClimbCollect.Tycoon.Review06.rbxlx). SHA256 `3c45ca40a09af5d06ca1f5edc79aeff9ae8bd9f257287c9d53a7d7f0bae99ab6`. Source: sibling `work/climb-collect`, branch `codex/tycoon-redesign`, current inspected HEAD `3517d8a`, runtime `904ff3b`. Full matrix: source `design/tycoon-overnight-2026-10-25.md`. Connected Studio at review time: Review06, Edit mode.

**Important artifact drift:** the HUD clone's `outputs/ClimbCollect.HUD.Complete.Review02.rbxlx` currently hashes to `5993f0d8ef117c32378c47324f60f026499088b91c42fc298616e6e80c82618b`, differing from its audit/report. Fresh disk inspection finds all 30 runtime sources matching and no changed script source relative to recovery. Workspace/terrain service tree is unchanged after XML parsing; four other service trees differ. Preserve both files and use the exact recovery copy for the previously recorded artifact. Do not silently overwrite either or describe the changed file as identical.

## One candidate still needs consolidation

Both feature reviews contain the integrated world. Neither contains all latest work from the other branch. Normalized source comparison finds seven differences: HUD Controller, Screens, TycoonHub, Widgets, UIPresentation, ui_presentation test, plus TycoonWorld's later label fix. The shared ancestor is `913a0cc`. A next integration should combine the HUD changes with the later tycoon label correction, rerun relevant checks, package a newly numbered review and verify its disk/reopen/world parity. Do not merge entire old Desktop `src/` or regenerate baked terrain as cleanup.

Fresh evidence: `evidence/workspace_review_2026-10-25/artifact-audit.json`; reproducible read-only audit: `python tools/workspace_review_audit.py`. All three audited artifacts match 30 runtime source files in their respective clones. This is disk validation, not fresh gameplay acceptance.

## Owner review checklist

Use HUD recovery for UI/general loop, then Tycoon Review06 specifically for latest habitat labels.

- [ ] Fresh Play: spawn on your own plot; one HUD; menus close without swallowing movement.
- [ ] Settings: Large Text, High Contrast and Reduced Motion; inspect all hubs and native control space.
- [ ] Sanctuary → Habitats: assign both starters, wait for production, collect a batch, bank it; inspect labels and machine/upgrade explanations.
- [ ] Enter Blossom through a gate. Follow flags; inspect climb readability, camera, jumps, collision and checkpoint placement.
- [ ] Find/earn a hatchable egg, secure at checkpoint, return to your plot, incubate, hatch, equip and train. Production eggs are a separate non-hatchable currency loop.
- [ ] Fall with unsecured cargo; inspect recovery clarity. Do not test destructive production-data scenarios.
- [ ] Visit all six kingdoms and optional branches; mark confusing turns, repetitive terrain, bad sightlines and awkward escape paths.
- [ ] Record a short screen capture and note build name, location, expected result, actual result and severity for each issue.

Studio memory sessions do not prove durable saves. A phone cannot play these local files directly: a selected combined candidate must be published to an authorized private test environment, followed by access/capacity and hosted save/rejoin checks. The old Fairground published place is not this candidate. Final destination/publication decision remains open.

## What remains before a polished phone candidate

1. Consolidate the two feature branches into one recoverable, freshly verified review.
2. Review the egg loop with the owner: preserve mountain egg extraction/home hatch, break shells on the mountain and carry creatures, or a hybrid. No change is selected yet. Current owned creatures/eggs are protected from player theft; adding player theft would change the approved rules and needs an explicit decision.
3. Produce one complete quality sample: shell materials/cracks/impact response, hatch anticipation/reveal, physical carry pose, escape readability, and a creature with idle/walk/run/turn/reaction animations. Then apply the accepted standard to the roster. Existing portraits and gentle articulation do not satisfy this target.
4. Review mountain routes visually and in human play; improve biome identity, terrain silhouette, surface detail, side discoveries, traversal variety, retreat paths and phone camera clearance based on findings.
5. Measure human first-session pacing and acquisition/economy, rather than treating simulations as player timing.
6. Establish the isolated private phone candidate; validate hosted saves/rejoin, app suspension/network interruption and real iPhone touch/safe-area/performance/heat behavior. Lower-end device coverage remains separate.

Full public launch additionally retains the approved advanced scope: party/invites/readiness, daily rewards/quests service, live raids/friend matching, rankings, badges/titles, approved paid catalog/receipts/entitlements and full multiplayer/performance acceptance. These must not be quietly dropped to call a phone candidate a complete public release.

## Mountain review order and current construction

Current source: durable HUD clone `mountain/shared/Catalog.luau` and `mountain/world/World.luau`; final route evidence: mountain continuation `evidence/mountain_2026-10-24/natural54-kingdom1.jpg` through `natural54-kingdom6.jpg`, plus `natural56-reopen.json`. Captures predate HUD/tycoon changes and show the preserved mountain, not a new redesign.

| Kingdom | Existing visual identity | Review focus / proposed identity, not accepted new mechanics |
|---|---|---|
| Blossom Gardens | Green rock, pink trees, garden ruins | First-time route clarity, sheltered garden paths, root climbs, approachable egg escape |
| Azure Falls | Water, cyan accents, falls/grotto/ferns | Waterfall sightlines, wet ledges, readable crossings and return paths |
| Sunstone Desert | Sandstone, gold, oasis/solar ruins | Arches and shade, crumbling sandstone readability, desert silhouette |
| Violet Crystals | Purple rock/crystal, mirror observatory | Crystal canyon identity, clean footing among prisms, avoid visual clutter |
| Inferno Heights | Basalt, orange accents, forge/temple | Lava/fire contrast, hazard tells, safe retreat ledges |
| Astral Crown | Pale summit, cosmic accents, star garden | Skyline and verticality, readable platform landing/return, summit payoff |

These are six sequential kingdoms around one mountain, not the historical four-route design. Each currently shares a contour-trail structure with entrance/mid/guardian checkpoints, two discoveries/nests, guardian arena, and a mover/reward/puzzle challenge. Sunstone additionally defines crumbling sandstone. Natural automated solo traversal covered all six Guardians, six mover loops, twelve branches and summit; it did not establish human fun, final art quality, all Trials or physical-device acceptance. Distinct biome names do not prove distinct traversal mechanics.

## Reference and decision queue

Owner follow-up choices now recorded in [egg and creature review](egg-creature-review-2026-10-25.md): break/reveal on mountain then carry creature home, sculpted-fantasy art, two-arm cradle for small creatures. Other rules remain open. New concept boards live in `references/egg-creature-review-2026-10-25/`; no code/place changes.

Owner references: [Steal An Egg by and Collect Rare Pets](https://www.roblox.com/games/107778070777162/Steal-An-Egg), [Break and Steal an Egg by ILGames x Eggs](https://www.roblox.com/games/114326934417838/Break-and-Steal-an-Egg). Confirm exact references before relying on lookalike games. Official listings and available screenshots were located; exact animation timing has not been verified from in-game footage. Review motion examples against actual gameplay before adopting timings. Proposed visual studies are illustrative, not captured footage or production assets.

Discussion order: egg/break/escape sequence → creature form and movement → Blossom route → remaining five kingdoms → sanctuary/economy pacing → phone acceptance. Each decision should carry visual alternatives and an explicit owner choice.

## Organization and graph scope

This Desktop repo is the navigation/history/graph home; the durable feature clones are current implementation sources. `START-HERE.md` is the current entry point for owner, Codex and Claude Code. Historical root place files and dirty source are preserved. Physical folder cleanup is not complete and should follow a preservation manifest and source consolidation rather than mass moves/deletions.

Graph was CURRENT at start, zero intended-input drift. It covers this original repo and selected vault notes, not the durable feature clone contents. Check freshness again after records change. One historical overview-heading review candidate existed; current status is now linked from the vault without removing historical notes. Final graph status is recorded in `evidence/workspace_review_2026-10-25/graph-final-status.txt`.
