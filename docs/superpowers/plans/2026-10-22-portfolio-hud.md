# Player Portfolio and HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow the selected method and common protocol in the parent plan.

**Goal:** Ship public/private player portfolios and nearby clickable identity tags together with the bright illustrated HUD.

**Architecture:** Pure collection/achievement rules feed sanitized public snapshots; the owner receives separate private details. Client modules own visual presentation while existing CoreRequest/CoreState/CoreFx remain transport and Profile owns persistence. Current Collection/station features remain accessible.

**Tech Stack:** Luau modules, existing Species/codex/Profile, Roblox BillboardGui and screen UI, existing menu/input/settings contracts.

**Spec:** [Design sections 6–8](../../../design/lobby-portfolio-summit-design-2026-10-22.md); [parent protocol](2026-10-22-expedition-redesign.md).

## Global Constraints

- Tap/click within approximately 25 studs in the lobby or designated safe camps opens that player's public portfolio without a camera takeover.
- Counts are unique species permanently collected; mutations are separate; unsuccessful outcomes are omitted.
- One Shop HUD entry plus at most one contextual offer is visible; paid promotion is reduced during climbing.
- Landscape phones lead the design, followed by desktop and gamepad.

## Review Focus

Roster changes, public-data leakage, crowd selection, stale remote replies, and menu/traversal input conflicts have explicit checks below.

## Files and data contracts

Create shared `src/core/shared/{PortfolioRules,AchievementRules,ExpeditionUITheme}.luau`; server `src/core/server/PublicProfile.luau`; client `src/core/client/{ProfileUI,NameTags,ExpeditionHUD}.luau`; tests `src/core/server/PortfolioTests.luau` and `tools/portfolio_checks.luau`. Modify `Profile.luau`, `CommerceCosmetics.luau`, `CC_CoreService.server.luau`, `CC_CoreClient.client.luau`, and sync manifest. Starter-bundle config/listings stay disabled until contents/price are reviewed.

`PortfolioRules.summarize(data, roster) -> CollectionSummary`: `collected`, `obtainable`, `percent`, `byRarity[rarity]={collected,obtainable}`, `mutationCount`. Roster input explicitly carries collectible, obtainable, and replacement mapping facts; derive these from actual Species/roster data rather than infer from an ID prefix.

`AchievementRules.unlocked(summary, summitsByRoute, config) -> {[titleId]: true}`. Use provisional threshold config from the design; historical counts can unlock titles but never replay summit prizes.

Persist `data.portfolio={titleId:string, showcase:{string}, frameId:string}` with a maximum of three owned creature identity selections. Do not persist derived completion percentages. `PublicProfile.snapshot(subject) -> PublicCard` includes only identity, level/XP, title, summed historical summits/by-route, CollectionSummary, companion, selected creature display summaries, and equipped cosmetics. No cargo, transaction ledger, balances, failures, or private details.

Requests via CoreRequest: `profileInspect{subjectUserId,requestId}`, `profileSelectTitle{titleId}`, `profileSetShowcase{creatureIds}`, `profileSetFrame{frameId}`. Replies via CoreFx: `profileInspect{requestId,status,card?}`. `status` is `ok|unavailable|outOfRange|unsafe|rateLimited`; reject malformed IDs. Tags use bounded nearby identity summaries on `CoreState.playerTags`, separate from inspected cards. Owner receives `CoreState.profile` plus `profileDetails`; only owner gets details.

### Task 1: Authoritative collection summary and safe profile persistence

- [ ] Write PortfolioTests cases: two banked copies of one species count once; mutations do not add species; unbanked cargo adds zero; guardian/unreleased species absent from denominator; retired mappings deduplicate; a new obtainable species changes denominator; empty roster yields 0/0 without NaN; removed showcase ownership is cleared; historical summits do not issue prizes. Run suite red before modules exist.
- [ ] Implement the two pure rule modules and Profile default/sanitization with bounded title/frame strings, at most three distinct ownership-validated selections, and migration that preserves all prior profile fields. Read current codex/provenance contracts before choosing history counts.
- [ ] Implement owner-only transactional selection handlers. Unlock checks and cosmetic ownership checks run inside the transaction transform; stale clients cannot equip newly lost/unowned items. Preserve one equipped companion from the existing home system rather than invent another companion state.
- [ ] Run `require(game.ServerScriptService.CC_CoreServer.PortfolioTests).run()` green, plus existing Profile/Expedition/Commerce suites. Compare sanitization round trips on old and new profiles.
- [ ] Commit rules, schema, handlers, tests, and registrations; do not include unrelated dirty files.

### Task 2: Public inspection and overhead tags

- [ ] Write `PortfolioChecks.inspection()` covering both players in safe zones, 25-stud boundary, distance beyond 25, one player on an unsafe route, subject leaving during request, stale requestId response, malformed payload, and public snapshot key whitelist. Add a per-requester token bucket of four inspections with one token replenished each second; assert excess requests receive rateLimited and do not read another profile repeatedly.
- [ ] Implement server inspection using loaded sessions only. Require both viewer and subject to be in designated safe ground, within 25 studs, and alive. Cache card revisions for at most two seconds with immediate invalidation on selection/progression changes; never cache authorization. Tags contain only currently relevant nearby players within 60 studs.
- [ ] Implement `NameTags.mount({state,request,menu,input,settings}) -> controller` with `update(state)` and `destroy()`. Display full name/level/title at ≤25 studs, simplified at 25–60, hide beyond/behind geometry. Player's own tag is locally hidden by default; own Profile button is always available. Add nearest-target gamepad focus and usable touch hit areas; never select through opaque geometry.
- [ ] Run checks green and actual two-client inspection. Test overlapping tags, scrolling menus, subject respawn, streaming out/in, and failed requests. Late responses for a previous subject must not replace the active card. Destroy connections/instances on leave.
- [ ] Commit server/client/tag contracts and record real-client versus fixture results separately.

### Task 3: Portfolio and coordinated HUD presentation

- [ ] Implement `ProfileUI.mount(deps) -> controller` exposing `open(card, details?)`, `updateOwner(state)`, `close()`, `destroy()`; use avatar/name/XP header, three headline cards, rarity strip, and selected showcase. Owner-only Details has successful records and Collection link. No falls/losses in either view.
- [ ] Implement `ExpeditionHUD.mount(deps)` and theme tokens; migrate HUD-only construction out of the runtime client. Keep stamina, altitude, cargo, save status, tutorial, Collection, Routes, Settings, bank retry, and station flows. Provide distinct Profile and Shop icons with text labels and keep native top-bar/control safe areas.
- [ ] Adapt CommerceUI presentation to the same header/button tokens without changing its transaction behavior. Suppress contextual offers while climbing, cinematic/results, or higher-priority save guidance is active. Provide exactly one offer slot; do not stack promotional badges.
- [ ] Write `PortfolioChecks.layout()` asserting required buttons reachable, minimum target bounds, no text clipping/overflow at largest text, predictable gamepad focus, B/Escape closes without triggering traversal release, and reduced motion. Run on desktop and the three parent phone sizes; inspect screenshots as well as bounds.
- [ ] Verify unlock/selection/respawn/rejoin behavior; save/reopen Profile review; run affected existing UI/commerce/cargo checks and saved-place verifier; commit scoped changes and capture the full portfolio/HUD review.

### Task 4: Starter set review prototype

- [ ] Build preview-only coordinated pennant, lantern casing, and decorative tag frame using original art, with no checkout or new platform IDs. Compare overlap with Camp Glow; show what existing owners would receive.
- [ ] Present exact proposed contents and price for later approval. Existing approved offers remain available in local disabled-checkout form. Do not block the portfolio release on new bundle pricing, and do not activate an unapproved offer.
- [ ] Record assets, preview evidence, and pending economic decision; commit preview sources separately from public purchase configuration.
