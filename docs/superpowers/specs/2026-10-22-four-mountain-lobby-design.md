# Four-mountain expedition hall and movement redesign

Date: 2026-10-22. Status: owner approved the conversational design, with additional lobby art requirements; written specification awaiting owner review. No game implementation or publication is claimed.

## 1. Purpose and authority

Make movement comfortable immediately, replace the open mountain-foot fairground with an intriguing enclosed expedition hall, and offer four distinct, progressively challenging mountain adventures. The first arrival must feel richly authored and inviting. Mountain routes must feel alive, forested where appropriate, and genuinely vertical rather than long empty walks.

Source of owner choices: [quad.md](../../../quad.md), recorded from this chat's interview and design-review widgets. This specification supersedes older single-mountain, open-fairground, fixed-speed and earned-access-only requirements only where explicitly changed here. Existing banking, ownership, personal-home, commerce and creature protections otherwise carry forward. Numerical proposals below are not owner-selected balance values.

Questions must always use the pop-up widget and contain multiple questions per batch.

## 2. Approved experience

1. Spawn inside a massive circular hall with tall ceilings and an open central floor.
2. Move automatically at a comfortable faster lobby pace, with a matching running animation and no sprint button required.
3. See four enormous enchanted windows, one at each cardinal direction, showing animated mountain previews with distinct conditions.
4. Approach the departure map/gate beneath a window, inspect details, then explicitly confirm travel.
5. Arrive at that mountain's starting point or its saved unfinished camp. Encounter players belonging to the same lobby server population.
6. Explore, climb, collect and manage stamina. Mountain normal movement is modestly faster than the existing baseline; a sprint toggle consumes the same stamina as climbing.
7. Extract from designated camps or the summit, carrying unbanked finds to the lobby. Physically deposit them at the bank to make them permanent.
8. Earn further mountain access through summit and banked-collection milestones, or buy permanent early access. Visit personal habitats through the hall's home entrance.

## 3. Movement design

Approved: unlimited automatically faster lobby movement; slightly faster mountain normal movement; mountain sprint toggle sharing climbing stamina.

Initial tuning proposal: lobby 22 studs/second, mountain normal 16, mountain sprint 23. Current local `src/world/WorldConfig.luau` configures baseline 12. Proposed values require actual avatar-scale playtests and may change without changing the approved behavior. Sprint drain and recovery must be tuned with the existing climbing stamina system; do not introduce a second stamina bar.

The movement owner must arbitrate walking, sprinting, climbing, stagger, cinematics and other movement locks. Lobby speed must not override a lock. Sprint requires grounded movement; stop sprinting when climbing, extracting, entering menus that lock movement, losing stamina, or respawning. Exhaustion returns to normal walking and requires explicit retoggle to sprint. Normal walking does not drain sprint stamina. Climbing remains governed by its traversal controller.

Use a looped run animation at a playback rate appropriate to ground speed, with smooth blends to idle/walk and existing climb/jump/fall states. Validate avatar rigs before selecting or authoring an asset. An unavailable animation must fall back without breaking movement. Do not claim animation upload or published ownership before verifying it.

Desktop, touch and controller must expose an accessible sprint toggle outside the lobby with visible enabled/exhausted feedback. Server validates zone eligibility and movement limits; client input must not grant unrestricted speed. Reconcile the current bank minimum-travel checks with legitimate sprint and extraction transitions, rather than globally weakening them.

## 4. Lobby architecture and art direction

Owner requirement: cobblestone walls, a complementary floor, detailed decorations, plants, trees and vines; an aesthetically pleasing arrival that intrigues players. Blend grand expedition lodge with modern mountain observatory and a little fantasy. Decorative completeness is a requirement of the reviewed lobby, not an unspecified later pass.

Proposed composition: tall curved cobblestone walls supported by substantial timber ribs, dark metal window framing and a vaulted roof. Use large warm-gray flagstones underfoot with restrained circular stone inlays and timber thresholds. This is the selected design proposal for the owner's delegated floor choice. Avoid repeating busy cobblestone textures on every surface.

Four monumental windows dominate the north, east, south and west walls. Suggested mapping: north snow, east sunny, south rainforest, west volcanic. Cardinal assignment is a layout default, not a gameplay dependency. Each enchanted frame has restrained runes and subtle animated light; the preview supplies the main spectacle. Magical previews are intentionally independent from the mountain's current weather/time. Departure details clearly distinguish preview imagery from current conditions.

Planting and authored detail:

- Two or three substantial indoor trees in curved planted beds provide foreground framing without blocking windows or service signs. Use localized roof daylight to support their placement visually.
- Ferns, moss, broad-leaf plants and trailing vines soften stone, railings and selected structural joints. Keep vines away from readable signs and active entrances.
- Include crafted benches, expedition maps, climbing equipment, lanterns, crates, woven textiles and destination-specific displays. Props need believable supports and a deliberate composition; avoid uniform scatter.
- Use warm lantern light on gathering areas, softer daylight above planting, and controlled contrasting color from each mountain window. Prevent competing neon accents and excessive bloom.
- Localized leaf movement, dust/light accents, ambient building sounds and distant window-weather sounds add life. They must scale down on phones and honor reduced motion.

Spawn composition: frame a clear window view through foreground planting and structural depth. Players should immediately identify the departure areas and bank/shop signs. Keep a broad central circulation area open for the server population, companions and camera movement. The room may feel monumental without making services an exhausting walk.

Proposed service target: bank and shop within roughly 5–8 seconds of actual lobby walking from spawn; each departure clearly visible or reachable from the central circulation ring. Dimensions are determined by avatar-scale blocking and measured paths, not a fixed oversized radius.

Only bank, shop and departure areas occupy the main hall. Side entrances lead to homes, showcases and practice. The home entrance transports to the personal home/habitat area and returns to the same lobby. Do not move all player homes or a full practice circuit onto the main hall floor.

Lobby acceptance requires an authored ceiling, finished walls/floor, coherent lighting/materials, complete planting/props, readable entrances and views at normal player height. An empty shell, repeated pillars and four screens are insufficient. Capture spawn, each window, bank/shop, roof and side entrances on desktop and landscape phone. Check collisions, camera clipping and navigation through the furnished room.

## 5. Four mountain identities

| Mountain | Access and difficulty | Known-route ascent target | Authored character |
| --- | --- | --- | --- |
| Sunny alpine | Initially available; beginner but suspenseful | 15–20 min | Forested foothills, sunny clearings, waterfalls, rooted climbs, exposed overlooks; rework existing mountain |
| Rainforest | Initially available; beginner but suspenseful | 15–20 min | Dense canopy, wet rock, vine-framed paths, gorges, bridges, rain and guardian suspense |
| Volcanic | Earned first or paid permanent access; medium | 25–30 min | Forested approach where plausible, charred groves, basalt, ash, crater silhouettes and controlled lava-crossing hazards |
| Snow | Final earned or paid permanent access; hard, rarest finds | 35–45 min | Conifer lower slopes, ice faces, crevasses, exposed ridges and summit storms |

These are skilled/familiar-route design targets excluding collection detours, not verified timings. First-time players may take longer. Suspense combines climbing, weather and guardians; starting mountains teach safely before escalating.

Every mountain has a substantial, mostly unique creature collection. Design distinct species identities, habitats, Heartstone opportunities and biome-linked mutations; exact roster sizes and odds belong in later mountain specifications. Snow has the rarest discoveries, but beginner discoveries must remain appealing and useful. Preserve existing creature assets; new authoring must respect the protected creature project boundaries and its workflow.

Routes must gain height through authored rock climbs, ladders, traverses, ledges, crossings and rests. Create recurring views downward and changing elevation, not merely corridors painted onto slopes. Trees and living vegetation frame routes and discovery spaces without obscuring climb cues. Snow and volcanic areas use biome-appropriate life rather than implausible dense green canopy everywhere. Forest density must not mean impassable collision or unreadable navigation.

Full weather and day/night change on all four mountains while preserving biome identity. Proposed default: shared server time, with local mountain weather states/intensity; friends on the same mountain see consistent hazards. Use telegraphed weather effects, legible traversal cues at night, shelters/rests and scalable visual quality. Do not silently add warmth/oxygen survival meters. Weather changes the existing stamina/traversal challenge within each mountain's specification.

## 6. Progression, monetization and rewards

Sunny and rainforest access is free from the start. Earn volcanic, then snow, through summit achievements plus banked collection milestones with explicit progress indicators. Exact milestone counts require economy and playtime balancing, not invented final values in this spec.

Owner explicitly selected an alternative paid permanent early unlock, including access to the destination's rarer finds. This overrides prior restrictions for this exact model. Paid access grants entry, not summit completion, free creatures, guaranteed claims or automatic banking. A purchased snow unlock may bypass the ordinary earned access sequence; it does not grant volcanic access unless separately owned. This interpretation must be visible in product descriptions and reviewed with the written design.

Design a single access check combining earned access and verified permanent entitlement. Keep permanent access independent of current ascent state. Failed or pending verification must not charge twice, erase earned access, or claim a purchase succeeded. Reuse existing confirmed commerce ownership/grant patterns after source reconciliation.

Consider monetization during each design review: destination cosmetics, themed home decorations, gear appearance and previews near relevant services. Keep unlock progress and both access options clear; purchases remain intentional. Existing approved Exchange products retain their defined semantics; any change to boosts, odds or bundles requires an explicit product definition. Prices, listing creation, live purchase tests, publication and spending are outside this interview's authorization.

## 7. Travel, saves and completed-ascent lifecycle

Maintain independent mountain progress: access state, current ascent identifier, highest eligible camp, ordered traversal progress and summit completion state. Rejoining must preserve unfinished ascents subject to verified durable saves; do not confuse Studio memory-store tests with account persistence.

Server validates departure eligibility and access, selects an authored safe arrival, and commits travel state. Serialize requests to avoid duplicate departures or extraction rewards. Locked/incomplete destinations must not be reachable by client-supplied identifiers. During staged development, show incomplete destinations honestly as previews/coming soon; do not offer live paid access to unavailable content.

Camp/summit extraction returns cargo unchanged and unbanked to a safe lobby return point near the physical bank. Reconcile legitimate extraction with travel validation. Do not use extraction to silently deposit or duplicate inventory. Existing loss/locker rules remain unless a later specification changes them.

Save unfinished progress independently when switching mountains. After summit completion and return, reset only the completed mountain's ascent/camps; retain permanent achievements, access, collection and other mountains' progress. Summit awards are idempotent by player/mountain/ascent. Commit completion and its reset so reconnects cannot repeat an award or resume a rewarded ascent at its final camp. Preserve any pending bank result/cargo through failure recovery.

## 8. Architecture and source boundaries

Recommended implementation approach: keep the lobby and spatially isolated mountain regions within the same server/place with streaming and local weather rendering. This best matches simultaneous exploration and same-lobby reunions. Four fully loaded high-detail mountains are not an acceptable assumption: prototype streaming, terrain footprints and phone memory before committing full terrain production.

Alternatives considered: linked reserved destination servers preserve identities but complicate routing/reunions and persistent handoffs; one swapped active mountain reduces world cost but prevents simultaneous different-mountain expeditions. If same-place scale fails measured device budgets, present the reserved-server fallback and its experience impact before changing topology.

Proposed responsibilities (names are conceptual, not claims that modules exist):

- Movement coordinator: speed modes, sprint input, shared stamina integration and animation transitions.
- Destination catalogue: identity, access, spawns/camps, weather profile and preview metadata.
- Expedition state service: ascent progress, summit validation/reset and persistence migration.
- Travel service: validated departure/extraction and safe arrival; preserves cargo.
- Mountain access service: earned milestones plus permanent verified entitlements.
- Lobby/preview presentation: authored geometry, services, enchanted vistas and scalable animation.
- Weather presentation/service: shared authoritative state with region-local effects.

Verify current source before assigning final files. Known integration points include `src/world/WorldConfig.luau`, `src/world/FairgroundLobby.luau`, `src/core/shared/CoreConfig.luau`, `src/core/shared/TraversalConfig.luau`, `src/core/server/Profile.luau`, `src/core/server/Cargo.luau`, and the current movement/traversal/commerce scripts. Avoid parallel systems with conflicting ownership of speed, stamina, banking or profiles.

## 9. Scoped delivery and verification

This is an umbrella design, not a single implementation task. Prepare scoped plans in the approved order:

1. Movement: reconcile source/live baseline, implement lobby auto-run and mountain shared-stamina sprint; verify real input, animation, locks, exhaustion, respawn, speed bounds and legitimate bank travel.
2. Lobby and sunny slice: build a finished representative hall and sunny vertical slice, with departure/extraction, physical bank, unfinished camp save and completed-ascent reset. Validate a return-and-rejoin loop and inspect detailed lobby visuals before scaling.
3. Rainforest: complete the second initial destination with a unique roster, hazards and full route at the target pacing.
4. Volcanic: medium mountain, earned access milestones and inactive/testable paid-access integration until separately authorized platform setup.
5. Snow: hardest mountain, rarest collection, final progression tuning and full-system QA.

Verify critical multiplayer cases with players splitting across destinations, extracting, visiting homes and reuniting. Test simultaneous travel, duplicate summit/extraction requests, failed saves, entitlement checks and reconnection around every state transition. Profile the furnished lobby and worst destination vistas on landscape phone emulation, then physical target devices when available. Record actual frame/memory/loading observations; set budgets from measured targets during the first slice.

Preserve the existing review build, terrain starting evidence, protected creatures and original source. Work in separate recoverable review files; do not publish over the private playtest during design work. Record each phase's evidence, corrected assumptions and unresolved issues in repo records and concise vault pointers. Check graph freshness after documentation changes.

## 10. Specification boundaries

Ready for owner review: the experience, art direction, access model, progression lifecycle and phased acceptance above. Implementation planning starts after written-spec review. Exact geometry, new species rosters, tuning, milestone counts, paid product prices/IDs, final animation asset, device budgets and detailed mountain obstacle sequences are delegated work in the scoped plans with clearly labeled proposals and evidence. They are not claims of completed work or reasons to reopen already selected product decisions.
