# Home-base Review02 — report (October 27, 2026)

Follow-up pass on Review01 (`design/homebase-rebuild-review01-report.md`). Stopped for the owner's review. No push, no publish.

## File status — NOT SAVED YET
`outputs/ClimbCollect.HomeBase.Review02.rbxl` does not exist yet. The Review01 window in Studio holds the Review02 state (Review01 + the changed sources synced over the Studio MCP, 97/97 match, Play-checked), unsaved. No MCP tool saves or publishes, and computer use for Studio was declined twice, so saving needs the owner at the computer: File → Save to File As → `outputs/ClimbCollect.HomeBase.Review02.rbxl` (never Ctrl+S: that overwrites Review01). If Studio closes first, reopen Review01 and re-sync: `python tools/rmcp/sync_homebase.py <studio id> TycoonWorld TycoonFeel CreatureMotion HomeAmbience`, then `compare_sources.py`.
Review01 (`4ef76009…27f96`) and Review06 are untouched. Branch `codex/homebase-rebuild`; commits `a4e0e71` (tags, creature life, ambience), `a708238` (sound), plus this report.

## Phone publish — owner-approved, pending
Owner chose (popup, 2026-10-27): publish **home base Review02 alone** (current in-game HUD, not HUD v2) to a **new private experience** ("Climb & Collect – Home Review", owner's account, Team Create off, Data Sharing off, phone enabled). Publish copy: `ReplicatedStorage.StudioAids=false`, `StudioTests` removed, saved locally first. Blocked on the same Studio-click permission; nothing was published.

## 1. Play-through and bugs
Play Solo in Studio, natural spawn at home 1, ordinary player requests only (no profile or position fixtures). Probes: `mountain/tools/promenade_raid.client.luau`, new `mountain/tools/homebase_systems.client.luau`.

| System | Result |
|---|---|
| Raid → reveal → pickup → carry down all 6 sections → secure at the gate | pass (122/122 checks, incl. "reveal is not ownership", "physical exit secures exactly one") |
| Six raid hazards: real damage, survival, walk-only escape | pass |
| Tycoon: assign, timed production (1 egg ≈ 1 min), collect, bank → coins | pass |
| Upgrade with too few coins / malformed path | correctly refused |
| `Home` showcase (creature on display) | pass |
| `Home` decor in a display slot | correctly refused |
| `Home` buy/place/clear decor | **not exercised**: a fresh profile has 1–4 coins, cheapest item is 40 |
| `Inspect` own habitat, display, empty plot | pass (species · level · eggs/hour; "That home is empty.") |
| Bat swing (miss), immediate re-swing refused by cooldown | pass |
| HUD ScreenGui present, console | pass, 0 errors/warnings |

**Bugs found and fixed**
1. Tycoon tags stacked and cluttered (8 two-line habitat tags + 3 machine tags + bank per plot). Fixed, see §2.
2. Wandering creatures could walk through the habitat's stock-egg pile (caught by a new layout test before shipping). Wander box tightened; `home_layout` now checks it (324 checks).

**Rough edges noted, not changed**
- A re-swing inside the bat cooldown answers "Action rejected." (generic). A clearer message belongs with the HUD/bat owner.
- Probe-only issues (request-id reuse, firing faster than the 0.12 s request spacing) were the probe's, not the game's; the server's replay and rate protection behaved correctly.

## 2. Tycoon tags (`server/TycoonWorld.luau`, `client/TycoonFeel.client.luau`)
- Every tag is one line, 150×26, rounded, e.g. `Mossbun · 2/30 eggs`, `Habitat 3 · locked`, `Processor · running`, `Production bank`.
- Each carries a `TagPriority` (full store 4 › bank 3 › active habitat 2 › machine 1 › locked/empty 0). Machine tags sit above the arch and appear within 18 studs only.
- Client declutter (5 Hz): nearest/highest-priority tags win; any tag whose screen box overlaps an accepted one is hidden; at most 12 on screen. Evidence `evidence/homebase_review02_2026-10-27/01–03`.

## 3. UI
HUD sources belong to the HUD v2 chat (`codex/hud-v2`); none were edited. Requests were left in the shared session-notes folder (`homebase-review02-ui-handoff.md`): a Home/decor screen (server actions already tested), Inspect as a card instead of a toast, and FYI on the `TycoonTag` declutter.

## 4. Creature life (`client/TycoonFeel.client.luau`, `client/CreatureMotion.client.luau`)
Habitat creatures get a small brain: pick a spot inside their pad (wander box from the server), turn toward it, walk with a gait (stepping bob, roll, alternating feet, faster tail), then idle — look around, sniff, hop, settle. A player within 9 studs gets a turn-and-hop greeting (every 8 s max). Floating species hover instead of stepping. Display creatures idle in place. Reduced motion / simplified VFX: static pose. Measured: a habitat Mossbun moved 3–9 studs in 10 s; the display Fernox stayed put.

## 5. Life across the home base (`client/HomeAmbience.client.luau`, new)
- 10 butterflies (kingdom accent wings), 5 ground birds that hop, peck and fly off when you come within 10 studs, 16 fireflies after dusk, soft lantern flicker, swaying pennants and wind-chime tubes.
- Sound (owner-picked, Pro Sound Effects, free): Wind Chimes 2 `9120750072` on each placed Wind Chime (within 50 studs), Bird Flying 1 `9113443901` when a bird takes off, Crickets Canyon 1 `9112764040` after dusk. Chimes and crickets follow "Music & ambience", take-off follows "Sound effects". The existing day bird loop (HUD controller) is unchanged.
- All client-local, anchored, non-colliding, non-queryable; one `BulkMoveTo` per tick at 30 Hz; only inside the sanctuary.
- **Performance (home 1 production view, Play Solo, desktop):** median 16.9 ms, p95 18.1 ms, max 20.7 ms (Review01: median 16.6, p95 ≤ 18.3). Vsync-bound in both.

## Verified
- CLI: **36 suites pass** (incl. `home_layout` 324, `home_decor`, `home_requests`, tycoon economy/progression/requests, bat rules, rules, UI protocol). `combat_raids.luau` and `run_persistence.luau` run inside their Python harnesses (`run_combat_raids.py`, `run_persistence.py`), both pass.
- `compare_sources.py`: Review01 differed from the branch in exactly the 4 changed files; after sync **97/97 match** (adds `HomeAmbience`).
- Play checks above, run twice (once in the coldcheck copy, once in the Review01 window used for Review02).
- Sound (Play, Review01 window): crickets silent by day, loaded and playing at night (vol 0.13 at default settings); chime sound loaded and playing next to a tagged part (local test part, removed); bird take-off played when the character walked up to a bird. Console 0 errors/warnings; no QA leftovers in Edit.

## Not verified (honest)
- **Bat theft** (knock + 3 s scramble + grab) needs two clients; not re-run this pass. `bat_rules` CLI passes.
- **Incubate / hatch**: a fresh profile has no eggs, so the loop wasn't exercised in Play.
- Decor buy/place/clear in Play (coins), and therefore wind chimes on a real placed item (tested on a local tagged part).
- Real phones, hosted servers, 8 occupied homes, live DataStore. Human pacing.
- `StudioAids` still unset; set it to false before any publish. Combined publish with HUD v2 Review03 still needs owner approval and a confirmed target place.
