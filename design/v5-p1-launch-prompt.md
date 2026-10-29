Continue CLIMB & COLLECT: v5 rebuild toward a first publishable, functionality-first build. v5 P0 is DONE (2026-10-21, `evidence/v5_P0/P0_report.md`). Priority now = **functionality and feel**. UI polish, shop, gear, Summit Points, O2 and monetization are OUT of scope (hide them behind a flag; they get their own rounds later).

Read first: `CLAUDE.md` (current milestone + gotchas), `master.md` §0.6-0.9, `design/v5-trails-and-mountain-plan.md` (LOCKED decisions, phases, acceptance checks), `design/publish-plan.md`, `evidence/v5_P0/P0_report.md`, `design/decision-log.md` (last rows). Obsidian: `Home.md` + the Climb & Collect overview.

Preflight (do not skip): `list_roblox_studios` shows `ClimbAndCollect.rbxl`, Edit mode; checksum Studio vs `src/` (expect drift only in RouteKit/ClimbKit: Studio = pre-trim, `src/` = trimmed); never click a Roblox taskbar icon; HttpEnabled off after every sync; max 2 checkpoints in the place (archive older to a verified .rbxl first). Another session may touch the Obsidian vault/graphify: don't touch those files beyond milestone lines.

Decisions to settle first in ONE popup (my recommendation first), then proceed without stopping between phases unless a hard stop hits:
1. Instance budget: P0 baseline +15 % (spawn 5,299 · Shepherd s2500 5,316 · Camp 1 6,246 · Camp 2 4,511 · Camp 3 5,006 · Merge 5,365) — recommended — vs Stage 4 +15 %.
2. First publish scope: Shepherd + Waterfall built directly on the v5 spline kit (recommended); Ledge + Spire gated "Coming soon" (no bypass).
3. Private place / friends-only playtest first.

Authorization for this run (unattended, in order, per-phase checkpoint + file copy + checksum + evidence `evidence/v5_P<n>/` + CLAUDE.md/Obsidian update after each):
- **P1 spline route kit**: `RouteSpline` data (width/exposure/type per segment), carve + ledge/ridge/slot/bridge builders, checkpoint remap, 60-90 s prototype per type; `python tools/spline_audit.py` passes acceptance checks 1 + 4. Sync RouteKit/ClimbKit from `src/` or retire them.
- **P2 Shepherd** (tutorial beats, Rare nook, hollow + lip nests pinned) and **P3 Waterfall**: set pieces per the round-3 table, rests ~4 min, camps on spline ledges, crossings at camps, rope-descent shortcuts, sparse fair hazards (≥2 s tell), co-op pull-up + pings, fall chain on every narrow type. Gate Ledge + Spire at the Foothold.
- **Minimal P7**: altitude fog bands + cloud-sea break at the summit (Atmosphere, no per-particle fog); day/night deferred.
- **Publish plumbing** (publish-plan Phase B): private publish, real DataStore verification (A1 against the real store), dev-tool strip verified live, settings audit. Publishing the place = ask me first in the popup before the actual publish click.
- Feel pass: climb controller, camera, stamina, slip/catch, jump, ladders, mobile touch (Device Simulator) — tune from bot + emulator evidence, document numbers.
Acceptance per route: BOT run 25-30 min skilled ESTIMATE, 0 stuck, 0 bypass (±36-stud profiles + physical walk test), tutorial bot + B checks 12/12 + A1 12/12, instances ≤ budget at the 6 spots, 60 FPS desktop, emulation labelled.

Hard stops (stop + report): Studio disconnected/unrecoverable, instance budget exceeded after one fix attempt, a LOCKED decision would have to change, data-loss risk to saves, anything needing a design value not traceable to `references/` (ask; never invent). Never fake evidence; label BOT vs human vs emulation. End with a report: what works, what's verified, what's not, and what I should playtest myself.
