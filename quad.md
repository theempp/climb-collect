# Climb & Collect — interview decisions

## 2026-10-22 — owner instructions

- Always ask the owner questions through the pop-up question widget, with selectable options where useful. Do not put interview questions in ordinary chat text.
- Always ask multiple questions together in each interview batch; never one at a time (owner follow-up).
- Lobby movement: automatically move faster, with an appropriate running animation; no sprint activation required.
- Mountain/route movement: increase default movement speed a little above the existing pace and provide a sprint toggle.
- Mountain sprinting uses the same stamina pool as climbing (owner selected). Lobby running is unlimited and consumes no stamina.
- Exact speeds, stamina drain/recovery rates, and animation details remain undecided. These are design requirements, not implemented behavior.

## Lobby and destination brief

- Owner-selected architecture: a blend of grand expedition lodge and modern mountain observatory, with a small amount of fantasy expedition hall. Interpretation for design review: warm timber/stone and lighting, sweeping glass/metal framing, subtle magical accents. Exact composition remains to be designed.

- Replace the open base at the foot of the mountain with an enclosed main lobby for each server.
- A massive circular open interior with tall ceilings and four massive wide windows, one each facing north, south, east, and west.
- Each window shows a different mountain destination/route. Players teleport to their chosen mountain.
- Owner-selected departure interaction: a departure area beneath each window; approach a map or gate, view destination details, then explicitly confirm travel.
- Owner-requested environments: snowy mountain, rainy/scary rainforest mountain, bright sunny mountain.
- Fourth environment: volcanic mountain (owner selected). Desert was an earlier assistant suggestion and was not selected.
- Mountain multiplayer: players encounter others from their current lobby server; friends may split up and reunite in that lobby. Technical topology remains to be designed.
- Access/progression: two of four mountains available initially, both beginner-accessible but intense and suspenseful like the original mountain concept. Earn the third (medium difficulty), then the fourth (hard difficulty). The last mountain should be difficult to unlock and contain the rarest creatures/Heartstones, supporting long-term progression and return play. Exact biome assignments and unlock criteria remain open.
- Route art/traversal: more trees, forest immersion and living environmental elements; reduce empty open space. Emphasize real elevation changes and creative, distinctive climbs instead of basic flat routes. Apply biome-appropriate vegetation and life; volcanic treatment remains to be designed.
- Owner wants monetization considered throughout design, including mountain unlocking, and existing offers reviewed for opportunities. Selected paid access is recorded below; prices and additional reward advantages remain unselected.
- Owner-selected lobby services: only bank, shop and departure areas inside the main hall. Homes, showcases and practice connect through side exits/entrances.
- A home entrance in the hall transports players to their personal home/habitat area and returns them to the same lobby. Treat it as a side entrance rather than placing homes on the main hall floor.
- Weather: full weather and day/night changes on every mountain, preserving each biome's identity. Signature window previews versus live conditions and shared weather timing remain to be designed.

## Progression and paid access — owner selections, 2026-10-22

- Sunny and rainforest mountains are the two initially accessible beginner destinations.
- Volcanic is the medium mountain earned first; snow is the final hard mountain with the rarest finds.
- Earned permanent access uses expedition milestones combining summit achievements and banked collection milestones, with visible progress. Numerical requirements remain open.
- Offer paid permanent early access as an alternative to earning the unlock, including access to the destination's rarer finds. This is an explicit owner-selected design override to earlier earned-access-only assumptions; no product prices, listings, purchases, publishing or spending are authorized by this design selection.

Evidence: owner's design interview messages in this chat on 2026-10-22. No game code or Studio changes have been made for this redesign.

## Expedition travel and pacing — owner selections, 2026-10-22

- Known-route ascent targets, excluding collection detours: sunny/rainforest 15–20 minutes, volcanic 25–30 minutes, snow 35–45 minutes. These are design targets requiring playtest measurement, not verified timings.
- Designated extraction points at camps and summit teleport players to the lobby with cargo still unbanked; physical banking after arrival makes finds permanent.
- Save each mountain's highest reached camp independently. Players can switch mountains and resume each from its saved camp; the completed-summit reset is specified below. Cross-session persistence must be included in the design and verified during implementation.
- Owner-selected summit reset: after completing a summit and returning to the lobby, reset that mountain's saved ascent/camps. Permanent unlocks, collections and achievements persist; another summit requires a fresh climb. Other mountains' unfinished ascents retain their own saved camps.

## Mountain presentation and reuse — owner selections, 2026-10-22

- Four magical viewing windows: visibly enchanted frames display animated mountain previews with independent conditions. These are previews rather than a commitment to live destination-weather views.
- Rework the existing mountain into sunny alpine, preserving useful climbs and gameplay systems while adding denser forests and elevation variety.
- Author rainforest, volcanic and snow mountains separately; do not simply recolor the existing terrain into four copies.

## Collections, suspense and delivery — owner selections, 2026-10-22

- Mostly unique collections per mountain: every destination has its own substantial creature roster. Exact species counts, assets, Heartstone tables and odds remain design/tuning work.
- Suspense combines exposed climbing, crossings, biome/weather hazards and guardian encounters, with gentler introductions on the starting mountains.
- Delivery sequence: movement first; then lobby plus playable sunny slice for review; then complete rainforest, volcanic and snow in order. This selects review sequence, not publication authorization.
- Assistant proposed a shared lobby with four distinct mountain regions to support simultaneous exploration by the same server population. Exact streaming/topology and performance feasibility remain to be validated; this is not an implemented architecture.

## Conversational design review — 2026-10-22

- Owner approved lobby direction, expedition structure and delivery sequence for the written specification.
- Additional lobby requirement: cobblestone walls and an author-selected complementary floor; detailed decorations, plants, trees and vines. Focus on a visually intriguing, aesthetically pleasing first arrival without repeated prompting for basic detail.
- Written specification: `docs/superpowers/specs/2026-10-22-four-mountain-lobby-design.md`. Written review pending; game implementation has not started.
