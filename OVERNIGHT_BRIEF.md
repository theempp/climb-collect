# OVERNIGHT BUILD BRIEF — first rough draft (approved 2026-10-20)

Read `CLAUDE.md` and `master.md` (esp. §0.5 V2) first. This brief only adds the unattended-run rules.

## Approved for this run
- Build order: Gate B mountain blockout → Gate C benchmark slice (Foothold + Green Valley → Camp 1) → Gate D regions (Forest → Cliffs → Storm Ridge → Summit) → Gate E full Foothold.
- **Gate C stop is overridden for tonight:** continue past it, but self-review with screenshots at each gate and save a checkpoint per gate. Revert to the pre-V2 rule (stop for approval) afterwards.
- Scope: world only (terrain, lighting, atmosphere, vegetation, landmarks, camps, Foothold, route layout). No gameplay systems, no persistence, no monetization.
- Bridge: **official Roblox Studio MCP**. Inspect its actual tool list first; never assume tools.
- Design source: region palettes and moods in `master.md` §3/§4. No `references/` folder exists; derive nothing from other projects. Anything untraceable to master.md gets deleted, not defended.

## Preflight (stop and report if any fails; do not improvise around it)
1. Studio MCP tools are present and one harmless call (e.g. read workspace) succeeds.
2. Confirm which place is open; ask the user's saved note, or create a checkpoint copy before the first write.
3. Confirm a way to run Luau (terrain `FillBlock`/`FillBall`/`WriteVoxels`) and a way to capture a viewport screenshot. If no screenshot tool, use computer-use screenshots of Studio only if granted; otherwise record that visual QA was not possible.

## Working rules
- Terrain lives in the place file, so write generator Luau as reusable modules, keep them in the place (ServerStorage/ReplicatedStorage) and mirror the source into the project folder (`src/`) so work is reproducible.
- Work region by region; after each, check: avatar-scale view, summit visibility, no floating parts, collision on paths/bridges, StreamingEnabled on, instance counts reasonable. Log screenshots and numbers in `CLAUDE.md` evidence table.
- Mobile/perf: budget by measuring (Studio stats), cap parts per streamed chunk, prefer terrain and reused instances over unique parts. Record actual numbers, never invented ones.
- Save a named checkpoint after each gate. Never overwrite a checkpoint.
- Do not publish the experience, do not change Roblox account/security settings, do not send anything externally.
- Honesty: mark anything visibly unfinished as unfinished in `master.md`; never mark a gate complete without evidence.

## Morning report (write to `CLAUDE.md` evidence log + a short summary)
What exists, per gate; screenshot paths; measured route heights/lengths and estimated climb times (computed from stud distances and 16 studs/s walk speed, labeled ESTIMATE); known gaps; what to approve next.
