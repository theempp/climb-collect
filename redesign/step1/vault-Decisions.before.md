# Decisions — Climb & Collect
Full ledger: repo `design/decision-log.md`. Log only the ones worth recalling here.

- 2026-10-22 #decision Owner approved conversational four-mountain design plus detailed cobblestone/planting lobby requirement. Written specification saved in repo `docs/superpowers/specs/2026-10-22-four-mountain-lobby-design.md`, with decisions in `quad.md`. Written review and implementation plan remain pending; no game code changed.

- 2026-10-22 #decision Interview complete enough for design review: mostly unique mountain rosters; climb/weather/guardian suspense; movement then lobby+sunny slice, followed by rainforest/volcanic/snow. Animated enchanted previews, independent unfinished camp saves with completed-summit reset, physical bank after extraction; timing targets and full owner responses in repo `quad.md` / `master.md`. No implementation or measured new-route timing claimed; design review pending.

- 2026-10-22 #decision Owner selected sunny/rainforest initially available, volcanic medium, snow final/hard. Earned access combines summit and banked-collection milestones; paid permanent early access is an explicit alternative including rarer-find access. Exact thresholds/prices/platform setup remain open. Evidence: widget selections in repo `quad.md`, reflected in `master.md`; design only.

- 2026-10-22 #decision Four-mountain interview: volcanic fourth biome; two suspenseful beginner destinations initially available, earned medium then hard destination with rarest finds; denser living/elevation-focused routes; same-lobby multiplayer. Monetization is a design priority; exact paid unlock rules remain open. Evidence: owner widget responses recorded in repo `quad.md` and `master.md`. No implementation claimed.

- 2026-10-22 #decision Movement interview follow-up: mountain sprinting shares climbing stamina; lobby running is unlimited. Owner selected the shared-pool option in the question widget. Numerical tuning remains open; repo `quad.md` records the decision.

- 2026-10-22 #decision Owner playtest interview: automatic faster lobby movement; slightly faster default mountain pace with a sprint toggle. Enclosed circular lobby and four teleport-selected mountain environments are under design. Exact speeds, stamina, fourth environment and architecture remain open. Evidence/decision record: repo `quad.md`; questions must use the pop-up widget. No implementation claimed.

- #decision Summit ~3,200 studs; 4 routes, 25–30 min skilled; stagger + fall-loss, no HP damage.
- #decision Server-authoritative claims/banking; never sell competitive claim advantage.
- #decision Max 2 checkpoints kept in the place; older go to an archive .rbxl.

- 2026-10-21 v5 round 3: feature sections = Core 8 + cloud-sea dome (6-7 per route, signature-owned); fixed pre-built ladders/ropes; references-only colour supersedes master §1 Enchanted look; day/night cycle phased into P7 with per-player clock (my advice was a server clock). Plan: design/v5-trails-and-mountain-plan.md. Nothing built.
- 2026-10-21 v5 UI round: Pinterest boards (user-confirmed) drive popups/reveals; HUD layout from K2 clips; ornament-led rarity; tiered reveals; landscape phone-first; lean HUD; tabbed Expedition panel; summit card + photo mode. User KEPT shop/gear/Points/O2 UI against Round 3 exclusions (my advice: exclude) = OPEN risk. Plan: design/v5-ui-plan.md. Nothing built.
- 2026-10-21 #decision Graphify scope: project code+docs, src_legacy_v2 (tagged legacy), creatures/ code only (Codex-owned, read-only); no references/ or images; vault export is hubs + index + canvas only, never one note per node; no git hook, nothing committed.
- 2026-10-21 #decision v6 trails = beat chains (height in bursts, real cliff exposure, enforced terrain obstacles). Popup: Shepherd 35 % / Waterfall 55 % hands-on, short jump gaps over real drops, fall cost scales with height, first slice Shepherd Camp 1 -> Camp 2. Plan: design/v6-trails-plan.md.
- 2026-10-22 #decision Graphify refresh keeps curated labels and MountainGen repairs, reads creatures code only, excludes DRS Rush and generated assets, makes a verified vault ZIP before writes, and publishes versioned hubs/index/canvas without replacing handwritten notes. Evidence: repo `design/graphify-refresh-2026-10-22.md`.

- 2026-10-22 #decision Correction to historical pending-design notes: full written four-mountain design was approved (repo commit `e126557`). The new movement implementation plan now awaits its own review. Active bank validation uses Traversal/CheckpointService, not the retired minimum-travel formula; verified evidence in repo `design/movement-planning-audit-2026-10-22.md`.
- 2026-10-23 #decision Sprint survives brief floor loss (<= 0.4 s, provisional); jumps and longer air still clear it. Reason: Traversal grounded() is false above 7 studs/s upward, which cancelled uphill sprint. Repo `design/movement-handoff-2026-10-23.md`.

- 2026-10-23 #decision Lobby+sunny slice plan approved: isolated off-map hall (Fairground archived), ~6 generated concept refs owner-approved before hall art, slice = Shepherd trailhead -> Camp 1, 3D diorama previews, free Creator Store audio for ambience only. Repo `docs/superpowers/plans/2026-10-23-lobby-sunny-slice.md`.

- 2026-10-23 #decision Hall references = C1 hall from spawn, C3 floor + inlay, C4 window + departure (C2/C5/C6 rejected). Runes toned down; any element in a kept image may be used. Rainforest/volcanic previews have no reference yet. Repo worktree `references/lobby/manifest.json`, `design/hall-intel.md`.
