# Publish plan: first playable test version (drafted 2026-10-21; AWAITING the new chat's audit + your approval)

**Target (user, 2026-10-21):** a publishable build with **2 routes to the summit, fully complete and polished**; the other 2 trails visibly blocked (rope or fence + "Coming soon" sign). Private/friends playtest first. Order: publish path first, v5 after.
**Hide for the first publish:** shop / gear / Summit Points / O2 canister UI behind a flag (R1 stays OPEN).

## Decisions the new chat must settle first (popup, my recommendation first)
1. **Which 2 routes ship.** Recommend **Shepherd + Waterfall** (easy + moderate: tutorial pieces are pinned to Shepherd; best first-timer arc). Ledge + Spire become the "Coming soon" gates.
2. **Which route form ships.** Conflict flagged: polishing the current v4 routes and then rebuilding them as v5 spline trails doubles the work. Recommend building the two shipped routes **directly on the v5 spline kit (P1-P3 scope for Shepherd + Waterfall)** and treating Ledge/Spire v5 as post-publish. Alternative: ship v4 Shepherd + Waterfall polished, v5 later (faster, but throwaway).
3. Visibility: private place + friends/invite-only; testers count; mobile + desktop both.

## Phase A: audit and safety (no building)
- [ ] A1 Read `CLAUDE.md`, `master.md` §0.6-0.9, `design/v5-trails-and-mountain-plan.md`, `design/v5-ui-plan.md`, `design/v4-run2-log.md`, `evidence/v4_P3_report.md`; list claims vs reality.
- [ ] A2 Environment health: Studio MCP connected, correct place open (`ClimbAndCollect.rbxl`), `HttpEnabled` off, no stray second Studio, Edit mode, no leftover dialogs.
- [ ] A3 Source/Studio parity: checksum `src/**` vs Studio (core, runtime, world, tools); fix drift, never overwrite blindly.
- [ ] A4 Regression: A1 12/12, B checks 12/12, tutorial bot (target ~6 min BOT, Rare ~2:06), 0 stuck.
- [ ] A5 Perf: streamed instances at the 6 Stage-4 spots vs baseline (the +15 % cap), FPS, worst frame; confirm whether the +31-76 % stop from Run 2 still holds.
- [ ] A6 Repo hygiene: git has 2 commits and ~12 untracked `.rbxl` copies (hundreds of MB); decide: commit docs/src/tools, ignore `*.rbxl` + move backups to one archive folder, verified; keep <= 2 checkpoints in the place.
- [ ] A7 Cleanup candidates: V2 generators not in BuildAll, unused dev tools in the shipped place, `ServerStorage` dev folders, Studio-only DevBridge/DevRequest must be inert in a live server.
- [ ] A8 Checkpoint `PrePublish_<date>` + file copy before anything changes.
**Gate A:** written audit report; you approve the plan below.

## Phase B: publish plumbing (earliest; independent of route work)
- [ ] B1 Publish a **private** place (PlaceId != 0), register place/universe in notes (no secrets).
- [ ] B2 Real DataStore verification (currently UNVERIFIED): join, bank, leave, rejoin; session lock; store-down banner; run the A1 suite against the real store in a published test.
- [ ] B3 Live-server dev-tool strip verified (`tools/publish_strip.lua`): DevBridge/DevRequest/bots unreachable by players.
- [ ] B4 Studio settings audit: StreamingEnabled, Lighting tech, collision groups, FilteringEnabled defaults, `HttpEnabled` off, no leftover Allow API/HTTP.
- [ ] B5 Game metadata: name, description, thumbnail from an evidence shot (avoid branded/copyrighted terms), age/content questionnaire, private access list.
**Gate B:** private server works with real saves.

## Phase C: the two routes (form per decision 2)
- [ ] C1 Foothold + 4 gates: gates 3-4 blocked with rope/fence + "Coming soon" sign (no bypass: ±36-stud profile check + walk test); Route Board shows 2 live + 2 locked tiles.
- [ ] C2 Route 1 (Shepherd): hand-checked top to bottom, tutorial pieces intact, rests every ~4 min, camps, checkpoints, fall chain verified, hazards >= 2 s tell, ~60 min first-time target measured by a human.
- [ ] C3 Route 2 (Waterfall): same checks, moderate difficulty.
- [ ] C4 Shared merge + summit stair + summit moment (overlay, card, Photo).
- [ ] C5 Fog/cloud-sea reveal at the summit (P7 minimal: altitude fog bands + cloud sea); day/night cycle deferred unless cheap.
- [ ] C6 Mobile budget: instances <= baseline +15 %, 30 FPS floor on emulator, then on a real phone.
- [ ] C7 Visual polish pass per route: assets/materials only from `references/`; design-reviewer sweep with screenshots (desktop + phone aspect).
**Gate C:** bot run per route (labelled BOT), zero stuck, zero bypass, evidence folder, your review.

## Phase D: UI for the test build (client-only; `design/v5-ui-plan.md`)
- [ ] D1 U0 foundation: tokens (Atlas), `UILayout` (safe area/UIScale), component kit; resolve typeface OPEN.
- [ ] D2 U1: lean HUD, prompts, tutorial caption, banners, loss card, Route Board, Expedition panel, system chips.
- [ ] D3 U2 subset: rarity reveal + level-up + summit card + photo mode (hatch/collection grid if time).
- [ ] D4 R1 flag: shop/gear/Points/O2 UI hidden in the test build.
**Gate D:** 801x413 + 1920x1080 screenshots, 48 px targets, no overlaps.

## Phase E: playtest readiness
- [ ] E1 Full regression (A1, B checks, tutorial bot, route bots), perf spots, fall chain, co-op ping/pull-up smoke test with two clients.
- [ ] E2 Known-issues list for testers (what is stubbed: creature art stubs, no audio, etc.), in-game "Coming soon" copy checked (English only).
- [ ] E3 Feedback capture plan: what you want testers to answer (clarity of tutorial, route feel, falls fair?, performance, bugs); optional in-game feedback link outside Roblox.
- [ ] E4 Save + checkpoint `Publish1_<date>`, file copy, publish a version.
**Gate E:** you playtest it first; then invite testers.

## Post-publish (not in this milestone)
v5 Ledge + Spire, remaining v5 P6-P9 (mountain look, jackpot tiers, creature roster), sound sourcing, shop/gear decision (R1), day/night.

## Standing rules for every phase
Checkpoint + file copy before changes; one thing per `execute_luau` call; checksum after every sync; evidence in `evidence/publish_<phase>/`; Obsidian vault updated per milestone; never invent design values (references only); stop at each gate.
