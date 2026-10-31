# Home-base redesign interview (design only) — 2026-10-29

No game, Studio, code, publish or Robux changes. Owner popup answers are authority. Implementation happens later in one build.

## Current home (summary)
140x180 plots (plan 100x130) on a 4+4 promenade, one gate. Plot: lodge, spawn, Incubator/Training markers, 8-habitat tycoon grid (timed eggs, bonus every 10th, storage, bag, bank, 5-step automation, 8 h offline cap). Weak: untextured parts, production reads as menus, plot has no identity, no rank/progress presence, only Mossbun art finished.

## Decisions (owner)
| Topic | Decision |
|---|---|
| Feel | Showpiece + working tycoon |
| Social | Full social hub |
| Plot size | ~80x100 plus shared commons (supersedes 100x130) |
| Layout | **C. Duo cloisters** (picked from 3 new concepts) |
| Training Beast / Grip, daily workout | In each plot |
| Mount stable | In plot, creatures stand at habitats |
| Hatchery | In plot, big hatch moment |
| Lake | Separate lake kingdom via portal (portal in commons) |
| Defense Outpost / player raids | **Removed completely** (trophies, vault, shields, revenge, friend raids go). Mountain bat theft and guardians stay |
| Rank | XP overall. On crossing the gate with a secured creature, an arrival pop-up announces XP, coins, etc. |
| Shop | UI-only, openable anywhere |
| Dailies | Notice board in commons + streak shrine |
| Decor | 14 fixed decor/display slots, server-validated, versioned save |
| Commons contents | Gate plaza + XP arrival moment, notice board + streak shrine, lake portal + party/duo portal, collection hall/leaderboard |
| Growth | Plot physically/visually grows by tiers; tier only unlocks the ability to upgrade, coins still required. Owner will send VFX/animation references for upgrades |
| Production look | Creature stands in themed habitat, eggs roll to the bank |
| Spawn | In own plot facing the commons |
| Style source | Existing sanctuary/lodge values + Glassbloom HUD intel (no new palette) |
| Visitors | Walk in, tap creatures/displays to inspect (read-only) |
| Creature presence | Static display poses |
| Phone | One-tap context buttons, 44 px targets, camera-friendly compact plot |

## Chosen layout: C. Duo cloisters
Four blocks of two homes (each ~80x100) share a garden strip; a cross-shaped commons street separates blocks; commons plaza at the crossing; one gate at the south end of the vertical street. Duo partners seat in the same block. Look: cloister walls, planted dividers, water channelled along the cross; materials only from existing sanctuary/lodge/gateway values (cobble, cedar, brass, dry-stone, lantern glass, Azure water).

Rejected: A Horseshoe court, B Ring village.

## Proposals not yet confirmed
- XP per secured creature scales with rarity so low-tier catches cannot be farmed for rank.
- Weekly seasons: unresolved now Outpost is gone (rank from XP; leaderboard in collection hall).

## Open / consequences to resolve before build
1. Owner VFX references for tier upgrades.
2. Remove Outpost from v1 scope docs (big-scope decisions 2026-10-28 section 1, shop shields, friend raid, vault) and from checklist C03/C04; dailies and shop shield items need replacements.
3. Duo-only party matches block seating; non-duo late joins need a rule.
4. 8 habitats + machines + bank + hatchery + Training Beast + 14 decor slots in 80x100 needs a re-layout, not a scale-down; decide habitat count/tiers.
5. Atlas pass on home references before art; static creature poses mean no roaming animation work.
6. Profile schema: decor, tier, rank XP subrecords (versioned, fail closed).
7. Reconcile with HomeLayout.luau (promenade 4+4) and its 105 checks at build time.

## Follow-up decisions (owner, 2026-10-29, same chat after the reference videos)
- First build: home base + tier-up VFX. Forest fishing world and sky menu come after, on the same VFX kit.
- Habitats: 6 per plot (supersedes 8) plus growth tiers; fits machines, bank, hatchery, Training Beast, 14 decor slots in ~80x100.
- Plot tiers: owner wants me to propose the themes (count and looks open until picked).
- XP per secured creature scales with rarity (numbers tuned later).
- Weekly seasons dropped for v1 (rank + leaderboard only).
- Shop shields removed; dailies use mountain, lake and home quests only.
- **Duo/party feature removed for now** (owner: "why do we have it? remove it"). Origin: the 2026-10-28 party decision (co-op Guardians, ready-check party portal, duo seating). Consequences: no party portal, Guardians tuned for solo, no partner catch assist, no duo seating rule. Layout C stays as four blocks of two neighbouring homes with a shared garden; its "Duo" name is now just a layout label (my inference, owner may rename).
- Base for the build: Integrated Review06 + Glassbloom HUD copy, in a new Studio copy; never the original or published place.
- Forest world: forest-fitting water guardian, 3-4 connected clearings, constant misty dusk; sky menu for Shop + Upgrade only. See `lake-world-and-vfx-reference-analysis-2026-10-29.md`.

Closed open items: 3 (duo rule moot), 4 (6 habitats). Still open: tier themes (I propose), XP numbers, doc updates for v1 scope/checklist (also remove party C01/C02, seasons C05), Atlas pass, schema, HomeLayout.luau reconciliation.
