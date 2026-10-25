# Climb & Collect tycoon implementation report

## Delivery

Feature branch: `codex/tycoon-redesign`, based on published HUD commit `6019525`, followed by preservation commit `089c6a3` for the newer local Review06 integration source. The original local integration and mountain continuation checkouts were not edited. No merge to main or Roblox publication.

Playable local artifact: `ClimbCollect.Tycoon.Review03.rbxlx` in this chat's outputs. Open it in Studio and press Play; assign a starter creature under Sanctuary → Habitats. Approximately one minute later, collect production eggs and bank them. Studio intentionally uses memory profiles, which reset on Stop. `Tycoon.SourcePackage.rbxlx` is a source package, NOT the baked playable world; it requires the existing Sanctuary geometry.

Review03 SHA256: `6b9d5d71a0a10802ce1ca7171a9717dc9ba460201ac82f982f847f203718d051`.

## Implemented scope

| Requirement | Implementation |
|---|---|
| Q1 | Timed production plus a bonus-value egg every tenth produced egg; rarity-based rate/value |
| Q2 | Collect one habitat or all in batches; separate upgradeable production egg bag; manual banking |
| Q3 | Saved settlement timestamp, eight-hour cap, habitat storage caps, no stored-egg expiration; offline automation cannot bypass storage |
| Q4 | Habitat levels, kingdom attunement and capped adjacent-grid synergy |
| Q5 | Production eggs convert to existing coins; banking bonus up to 10%, processor 5%; no streaks |
| Q6 | Linear habitat, production, storage, bag, banking and automation paths; explicit advanced prerequisites |
| Q7 | Central conveyor and eight modular grid locations inside a 110x120 production area within each existing 180x220 outer plot |
| Q8 | Five automation stages: routing, processor, sorter, collector, automated bank; bounded client visual pool, culling, reduced-motion/VFX support |
| Q9 | Two initially unlocked habitats, maximum eight; one distinct owned producer each; combat team independent |
| Q10 | Overview, habitats, owned roster with assignment/unassignment/atomic swapping, attunement, upgrades, automation, cosmetics and existing facilities |
| Q11 | No prestige/reset mechanics; expansion and six free kingdom palettes stay within the current plot |

This is a functional review implementation using existing creature art, kingdom colors and HUD components. Premium visual acceptance is not asserted from compile/test results. No external asset IDs, paid products or missing media were invented.

## Architecture and persistence

Authoritative pure transitions live in `Tycoon.luau`; centralized provisional balance in `TycoonConfig.luau`. The existing profile retains schema 1 and gains a versioned `tycoon` subrecord. Existing coins, creatures, team, hatchable eggs/cargo, progression, settings and namespace remain in use. First migration settles the previous capped passive income once, then initializes empty production storage; subsequent income calls cannot continue minting legacy passive coins.

Migration and offline catchup occur inside the existing UpdateAsync load transformation. Repeated callback execution starts from durable input and never duplicates grants. Malformed/newer tycoon records fail closed instead of being reset. Counts above current storage capacity remain intact. Currency, egg bag, habitat storage and timestamp save in one record.

Save changes validate the complete profile, reject expired/stolen leases, and acknowledge the same write ID after a lost successful-write response, including release. Production is settled by the tick/actions, not invisibly inside save; `lastAt` means last settlement, and rejoin accounts for the remaining interval. Existing retry, budget waiting, autosave and shutdown paths remain. Abrupt server failure can still lose progress since the last successful autosave, as with the existing profile architecture. Request success means accepted in server memory; the existing save status indicates persistence health.

Correlated request deduplication/rate limiting is reused. Payloads cannot include price, reward, rarity or egg quantity. All mutations require a healthy profile, safe living character and the owner's plot. Only the server evaluates costs, prerequisites, IDs and unlocked slots. Automatic production continues while exploring; offline catchup never automatically drains habitat storage.

Conveyors use at most 24 local sample eggs, 12 on touch devices, with 220-stud/view culling and 30 Hz updates. They have no touch/collision/query authority. Production messages contain bounded tycoon state and coins only, and are sent on material changes rather than repeating the whole collection every tick.

## Changed files

New runtime modules:
- `mountain/shared/TycoonConfig.luau`: rates, limits, prices, automation stages and cosmetics.
- `mountain/shared/Tycoon.luau`: validation, migration, production, collect/bank, assignment/swap, attunement/upgrades and snapshots.
- `mountain/server/TycoonWorld.luau`: additive grid, reused creature display and machine status.
- `mountain/client/TycoonConveyors.client.luau`: bounded cosmetic conveyor pool.
- `mountain/client/UI/TycoonHub.luau`: complete sanctuary management screens.

Modified runtime integration:
- `mountain/shared/Rules.luau`, `UIProtocol.luau`: shared rules export, disable legacy income after migration, strict request schema.
- `mountain/server/Profiles.luau`, `UIRequests.luau`, `Main.server.luau`, `Sanctuary.luau`: persistence, dispatch, owned-plot service, periodic settlement and rendering.
- `mountain/client/UI/ClientState.luau`, `Controller.luau`, `Screens.luau`: correlated tycoon intents, compact updates and hub routing.

Tests: new `mountain/tests/tycoon.luau`, `tycoon_requests.luau`; expanded `ui_client_state.luau`, `run_ui_server.py`. Plans/specs, baseline SHA manifest, this report and evidence accompany them. The separate baseline commit preserves 43 files from the existing integration, including its unchanged world-source dependencies; these are prerequisite recovery, not a tycoon world rewrite.

## Verification

- Baseline: 1,102 CLI checks passed before changes.
- Final CLI suites: 1,181 checks (58 tycoon rules, 11 tycoon requests, 50 client state, 25 profile/combat adapter checks plus all existing rules/traversal/UI/journey/reservation suites).
- All 88 mountain Luau files compile. Rojo 7.6.1 source package builds.
- Studio memory suite: 50 checks passed, including contention, failed/uncertain saves, serialization repair, slow-save release, reconnect, eggs, Guardian captures and defense snapshots.
- Real Studio client: assigned starter creature → naturally timed egg → batch collect → manual bank for one coin → duplicate banking ID leaves balance unchanged. No currency/egg/time grants used in this loop.
- Real server requests: two assignments and atomic swap accepted; team stayed `c1,c2,c3`; unaffordable upgrade, locked third habitat and injected `coins` field rejected.
- All six hub tabs opened without runtime errors. iPhone 17 Pro landscape simulator: no checked description clipping or controls below 44x44; no physical mobile performance claim. Studio viewport restored afterward.
- Packaging: all 30 runtime sources match disk. Entire baked Workspace (including terrain), ServerStorage, Lighting and all other protected service trees match Review06 under XML serialization hashing. Tycoon geometry is additive at runtime.
- Independent reviewer found adjacency and atomic-swap gaps; both fixed and regression-tested. Conveyor stage visibility corrected. Final author review added compact update coverage and a save/tick notification regression.

Evidence: `evidence/tycoon_2026-10-24/`, and the adjacent `ClimbCollect.Tycoon.Review03.audit.json` output. Reproduce CLI with all `mountain/tests/*.luau` and `python mountain/tests/run_ui_server.py`; set `LUAU_CLI` for a different Luau executable location. Repackage using existing `mountain/tools/package_hud.py BASELINE OUTPUT` (never the same path).

## Assumptions and remaining acceptance

Detailed prior ChatGPT assistant responses were unavailable; Q1–Q11 in the current user request are the controlling brief. Exact hybrid cadence, costs, rates and thresholds are provisional builder choices, documented in `design/tycoon-redesign.md`. Production assignment can coexist with combat-team membership, because the systems are independent. Existing outer plots were retained; the requested size applies to the internal production footprint. Initial cosmetics are free palettes, not invented purchased assets.

Still unverified: published DataStore permissions/budgets and cross-server failure behavior, eight simultaneous live clients, real low-end phones, full economy pacing, and premium art/VFX owner approval. Existing unrelated limitations (including respawn recovery during a save outage) remain in the integration report. No public-release or zero-loss guarantee is made.

## Final disk reopen and small-phone input

Review03 reopened from its saved disk file and started cleanly. At iPhone 7 landscape (666x374 viewport), all six tabs had zero checked clipped description labels or buttons below44x44; the client pool contained exactly12 cosmetic eggs. Actual mouse/touch-emulator input opened Habitat1’s roster and assigned Mossbun; the server-confirmed button changed to Assigned here and disabled. Console contained only the normal ready line. Device simulation was reset to default and Play stopped. Evidence: final-reopen-phone.json.

Implementation commit: febf6cf82b65e1ed2b977ba03cf9555013009084. The branch was pushed and remote SHA matched; the final documentation/evidence commit follows it.
