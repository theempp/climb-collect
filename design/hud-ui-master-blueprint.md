# HUD & UI MASTER BLUEPRINT — CLIMB & COLLECT: MOUNTAIN EMPIRE
Version 1.0 | Approved interview Q1–Q28 | 2026-10-24 | Implementation handoff

## Authority and conflict handling
This document captures the user's latest *HUD/UI interview* decisions. It is authoritative for interface design and behavior. Existing `master.md`, `CLAUDE.md`, and other approved world/gameplay documents remain authoritative for their respective gameplay implementation, unless the user explicitly superseded them. **Important conflict:** the currently committed `master.md` describes an older V2 expedition loop (PREPARE/EXTRACT/BANK), while the latest interview explicitly specifies CLIMB → COLLECT → UPGRADE → UNLOCK → REPEAT, a compact six-kingdom mountain, three-creature teams, guardians, sanctuaries, and eight-player servers. Codex MUST inventory the actual implemented systems and report incompatible specifications; do not silently delete working expedition systems, reinterpret locked gameplay, or implement conflicting loops. Use the latest interview as the intended UI direction and request resolution for destructive or gameplay-changing conflicts. UI-only work can proceed safely while conflicts are documented.

### Status
- Q1–Q28: LOCKED by user.
- Implementation authorization: user requested implementation after this plan is committed; Codex may implement authorized UI and integrations, not invent missing gameplay.
- Concept boards: illustrative only, not production assets or exact specifications.
- Proposed numeric/color design tokens: adjustable during implementation if required for accessibility/Roblox compatibility.
- Do not claim any unverified gameplay system, Studio test, or performance measurement is complete.

## North star
Premium, playful, bold, mobile-first landscape Roblox simulator/adventure UI. One coherent navigation framework, clean world visibility, minimum clicks. Core loop: CLIMB → COLLECT → UPGRADE → UNLOCK → REPEAT. Preserve native Roblox joystick and jump, CoreGui/top-left menu safe areas, touch-friendly controls, and responsive tablet/desktop layouts. Avoid trading, additional currencies, speculative systems, pay-to-win, redundant menus.

## Locked decision register
| Q | Category | Choice |
|---|---|---|
|1|Overall style|B — Playful & Bold|
|2|HUD layout|E + B — collapsible left sidebar + bottom primary actions|
|3|Navigation|E — Smart Collapsible Sidebar|
|4|Top HUD widgets|B — timer/currency/quick info with safe margins|
|5|Creature slots and abilities|B + C — 3 slots, manual special buttons/cooldowns|
|6|Movement/climbing|B + D — native joystick/jump; contextual climb/interact|
|7|Mountain progress/quests|B + E — height and minimal objective tracker|
|8|Creature inventory|B + C + E — grid, team editor, rarity/filter tabs|
|9|Creature cards/evolution|A + B + D — rarity, stats, evolution showcase|
|10|Guardian combat|B + C + D — boss HP, phases, capture windows|
|11|Sanctuary tycoon|A + B + D — habitat/build/upgrade/placement/income/training|
|12|Upgrade/reward feedback|A + B + D + E — purchase, collection, notifications|
|13|World map/fast travel|A + B — six kingdoms, checkpoints|
|14|Shop/monetization|A + B + D + E — fair cosmetics/convenience|
|15|Player profile|E — integrated stats/achievements/titles|
|16|Quests/missions/dailies|B + D + E — integrated hub, minimal tracker, roadmap|
|17|Training/facilities|B + D + E — facility hub, in-world training, progress|
|18|Evolution/upgrades|B + D + E — integrated hub, in-world facility, timeline, reveal|
|19|Egg hatching/discovery|B + D + E — discovery hub, in-world hatching, reveal|
|20|Raids/competitive|B + C + D — hub, defenses, in-world interactions, trophies|
|21|Co-op guardian/parties|B + C + D — party hub/finder, portals, compact battle UI|
|22|Leaderboards/recognition|B + C + D — profile hub, collection, in-world displays|
|23|Loading/first impressions|D — cinematic loading, spawn directly into playable sanctuary; NO main menu or mandatory intro|
|24|Settings/accessibility|E + D — organized settings hub + compact quick settings|
|25|Onboarding|B + D — contextual in-world discovery and progressive hints|
|26|Notifications|E — toasts, contextual tooltips, major alerts, existing progress tracker|
|27|Animation/audio|E — polished feedback, subtle daily animations, cinematic milestones|
|28|Responsive/final integration|E — mobile-first responsive, collapsible, CoreGui-safe|

## World and gameplay context (integration targets, NOT proof of implementation)
Eight players; eight horizontal sanctuary plots of 110x120 studs; three centered monumental mountain gates; bright Alpine Modern × Enchanted Fantasy environment. One compact, richly detailed mountain with six kingdoms, terraces, checkpoints, fast travel and secrets: Blossom Gardens/Floravelle, Azure Falls/Aquarune, Sunstone Desert/Zenthari, Violet Crystals/Veylith, Inferno Heights/Pyralune, Astral Crown/Caeloryn. Three active creatures, automatic basic attacks and manual specials; wild encounters/eggs, XP/training/evolution; huge boss-form guardians, collectible oversized guardian forms; one capture per legendary, replayable trials. Classic upgrade tycoon: habitats, passive income, building upgrades, creature placement and training. Cooperative exploration/boss fights, offline raids and friend challenges, rankings/trophies/badges/titles. Monetization: cosmetics and noncompetitive convenience only.

## Proposed design system (not locked literal pixel specs)
Palette: deep navy #0B1730, panel blue #142C52, sky blue #21B8FF, royal blue #3478F6, reward gold #FFC247, success green #42D979, epic purple #A36BFF, alert coral #FF665F. Strong contrast; readable Roblox-compatible rounded bold headings and sans body; responsive 4/8/12/16/24/32 design-spacing reference; generous touch targets; rounded cards/pills, restrained glow, unified iconography. Color cannot be the sole indicator of rarity, status or danger. Bind actual rarity tiers, currency names, icons and stats from game data; concept-art coin/gem counts are NOT specifications.

## HUD layout and behavior
Use native Roblox inset/safe-area APIs and test actual CoreGui overlap; never place custom top-left widgets on Roblox menu or top bar. Default joystick bottom left, default jump right remain functional; custom special ability buttons must not obstruct jump, climb or interaction. Top safe-area widgets: timer/currency/quick status. Left: smart collapsible sidebar, no duplication with bottom primary-action bar. Center: preserve world visibility. Right/top: compact quest and mountain-height progress. Bottom center: 3 active creature slots and clear cooldown states. Contextual climb/interact appears only when eligible.
States: exploration normal; sanctuary contextual management; combat prioritize boss/team/cooldowns and suppress distractions; modal menus one primary hub at a time; major reveal skippable when lengthy and never incorrectly advances server state. Hide irrelevant widgets automatically. Support controller/keyboard where existing infrastructure permits.

## Navigation and complete screen inventory
One shared UI root, layered navigation stack, modal host, toast host, tooltip host, cinematic overlay. Reuse existing architecture if viable.
1. Main gameplay HUD and collapsible sidebar/bottom primary action bar.
2. Creature inventory grid, rarity/filter/sort, detail cards, 3-creature team editor.
3. Creature stats, XP, abilities, training and evolution requirements.
4. Training/facility management with in-world contextual interactions and progress.
5. Evolution/upgrades hub with timeline, costs, server-confirmed reveal.
6. Egg discovery/hatching hub, in-world hatchery, reveal and ownership updates.
7. Sanctuary build/upgrade/habitat placement, income collection and creature placement.
8. World map, six kingdom statuses, height, checkpoints, validated fast travel.
9. Quests/progression hub, active objective and eligible daily rewards (only if backend exists).
10. Guardian boss HUD: HP/phases/mechanics/ability cooldown/capture window/trial status.
11. Legendary Trials entry/status; capture history and eligibility.
12. Party finder/invites/member readiness, cooperative boss progress.
13. Competitive hub: raid entry, defenses, trophy/rank progress, friend challenges.
14. Player profile, statistics, achievements, badges, trophy gallery, titles.
15. In-world ranking/trophy displays, server-fed and readable.
16. Shop for approved cosmetics and convenience, verified entitlements.
17. Full settings hub and quick-settings overlay.
18. Cinematic loading with logo/mountain imagery/accurate loading feedback → direct spawn.
19. In-world contextual onboarding objectives/hints, no forced slideshow.
20. Notifications: low-priority toasts, nearby tooltips, major milestone alerts, quest progress reuse.

### Navigation rules
Single primary hub at a time; nested detail pages use Back; blocking modal has explicit dismissal/confirmation; menu closures restore focus and interaction. Don't duplicate systems in multiple independent menus. Don't render fake data as actual player state.

## Detailed behavior and service integration contracts
Codex must audit real existing remotes/modules and adapt, never assume names. Create typed adapter boundaries for: PlayerProfile, Currency/Wallet, Inventory, Team, CreatureStats, Egg/Hatch, Training, Evolution, Sanctuary/Habitat, Quests, KingdomProgress, Checkpoints/Travel, Combat/Guardian, CaptureTrials, Parties, Raids, Rankings/Recognition, Shop/Entitlements, Settings. Distinguish real connected, read-only, unavailable, and simulated test-only states. Missing dependency: render truthful unavailable state and document blocker; don't silently create a new major gameplay system.

For each mutating action: client requests intent; server validates identity, ownership, permissions, proximity where needed, resources, limits, cooldown, progression and idempotency; server performs transaction; client displays pending state and success only after authoritative confirmation. Handle timeout, rejection, duplicate tap, stale state, disconnect, and retries. Keep server ownership of currency, rewards, inventory, upgrades, capture limits, raid results, checkpoint unlocks and purchase entitlements. Rate-limit network actions; never trust client-provided costs or reward amounts.

Specific:
- Creature slots: exactly 3 active; basic attacks automatic; specials manual with server-backed cooldown.
- Guardian capture: one success per guardian; replay trials not repeat captures; server checks phase/eligibility.
- Sanctuary: show actual costs/income/upgrades; no client-authoritative collection.
- Map: locked destinations cannot fast travel; checkpoints reflect real server progression.
- Parties: invitations/readiness and membership server verified.
- Recognition: ranks/trophies from authoritative data; no new currencies.
- Shop: platform receipt/entitlement validation; no pay-to-win.
- Onboarding: first objective tied to existing actions, nonblocking; contextual hints and dismissal state.
- Loading: only show percentage when measurable; otherwise indeterminate progress, handle failures and retries; direct spawn into actual world.

## Responsive/accessibility
Test short/wide phone landscape, notched phone, tablet, desktop and relevant Roblox scaling. Use relative anchors, constraints, UIScale/layout primitives, automatic text sizing bounds and scrolling. Test safe-area insets with top bar, menu, native controls, keyboard and orientation. Maintain touch targets roughly 44–48 logical pixels equivalent when feasible; no horizontal clipping, unreadable tiny text, overlapping interact/ability controls. Accessibility: text size/contrast options where supported, reduced motion, simplified VFX, separate music/SFX volumes, readable icon+label status, sound-independent cues. Settings must persist if existing settings persistence supports it; otherwise disclose gap.

## Motion, feedback and performance
Everyday tap/hover/upgrade/toast: quick, low-cost, responsive; major hatching/evolution/guardian/kingdom milestones: cinematic but skippable and not state-authoritative. Reduced-motion variant disables excessive movement/flashes. Prioritize 60 FPS target on capable mobile devices without claiming benchmark success; profile representative low-end devices and document actual results. Avoid per-frame expensive GUI rebuilds, uncontrolled tweens/connections, memory leaks, excessive transparency layers, excessive simultaneous sounds/particles, and duplicate screen instances. Pool/reuse common components, clean subscriptions, debounce UI inputs while awaiting server results.

## Suggested Luau architecture (adapt to repository)
- Shared UI theme/tokens and responsive breakpoint/safe-area utilities.
- Reusable Button, IconButton, Panel, Modal, TabBar, Card, StatRow, ProgressBar, CurrencyDisplay, CreatureSlot, CreatureCard, Tooltip, Toast, RewardReveal, LoadingOverlay.
- UI controller/router, screen registry, modal/toast manager, animation/audio feedback service, accessibility/preferences controller.
- Thin view-model/adapters subscribing to actual gameplay service state, with explicit lifecycle cleanup.
- Feature modules for each hub; consistent naming, types and testable pure helpers.
No framework migration unless clearly justified by current repo. Follow Rojo/Wally/Roblox Studio workflows actually present.

## Delivery phases (continue until all authorized work is done)
0. Read CLAUDE.md, master.md, existing phase docs, this blueprint, repo tree and git status; document conflicts, services, actual toolchain, test access and baseline.
1. Design tokens, UI root/router, responsive/safe-area utilities, reusable components and lifecycle tests.
2. Core HUD, navigation, creature team/abilities, quest/height widgets, cinematic loading/direct spawn.
3. Creature inventory/details/training/evolution/eggs; connect actual services.
4. Sanctuary, map/fast travel, quest/progression and Guardian combat/capture/trials.
5. Party/co-op, raids/recognition/profile and shop.
6. Settings/accessibility, onboarding, notifications, motion/audio and responsive polish.
7. End-to-end integration, error handling, regression, mobile/desktop QA, performance, bug fixing and report.
Commit each recoverable phase; do not mix unrelated world/gameplay rewrites. Prefer working branch/PR when repo conventions require. Keep documentation and status ledger current.

## Acceptance gates
- All 28 selections reflected in implemented UI and all screen inventory entries accounted for as functional or explicitly blocked by absent backend.
- Direct loading-to-sanctuary, no forced main menu/onboarding.
- CoreGui/menu/joystick/jump unobstructed at tested device sizes.
- Three creature slots, manual specials and cooldowns reflect real state.
- Every visible action either works against authorized server validation or is clearly disabled with reason; no deceptive fake success.
- Six kingdoms and guardian names correct; capture limit respected.
- Sanctuary purchase/income, quest, fast travel, party/raid and shop pathways protected server-side.
- One coherent navigation and readable mobile typography; no duplicate modal stacking.
- Notifications priority, sound/motion settings, reduced-motion behavior verified.
- Tests/build/static analysis pass where tooling exists; Studio playtest evidence only if Studio available.
- Document tested devices, screenshots/video paths if captured, measurements if actually recorded, commits, unresolved blockers and manual playtest checklist.

## Definition of 100% for Codex
100% means all **authorized UI scope** is implemented, integrated, reviewed and verified as far as available tools permit, with honest disclosure of dependencies and tests not runnable. It does NOT authorize inventing new gameplay, overwriting conflicting locked systems, fabricating tests, or claiming a Studio playtest that never happened. Work autonomously through phases, self-review and fix issues, and stop only on genuine external blockers or completed verified scope; report any blockers precisely.

## Required final report
Commit/branch/PR links; changed files and architecture; screen-by-screen status (integrated/blocked); services wired and validation points; tests executed/results; device and performance evidence; unresolved specification conflicts; limitations; step-by-step Roblox Studio playtesting checklist; prioritized remaining issues. Keep user-facing summary concise but evidence-based.
