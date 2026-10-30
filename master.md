# CLIMB & COLLECT — MASTER BUILD SPECIFICATION

**Version:** 2.1 (V2 expedition redesign approved 2026-10-20) | **Status:** Implementation-authoritative for approved decisions; incomplete areas explicitly marked PROPOSED/TBD. Where §0.5 (V2) conflicts with older text below, §0.5 wins; superseded lines are marked.

> This is the canonical GAME PRODUCT and CREATIVE specification. `CLAUDE.md` is the canonical agent/project working agreement. Never silently reinterpret a LOCKED item. The quality target is a premium, instantly impressive Roblox adventure, not a functional but visually empty prototype.

## 0. North star

**Fantasy:** Climb one extraordinary magical mountain, discover and first-claim delightful rare creatures, survive the risky return, permanently bank discoveries, and showcase an evolving collection at a personal cabin.

**Loop (V2):** PREPARE → CLIMB → DISCOVER → COLLECT → PUSH HIGHER or EXTRACT → BANK → UPGRADE → REPEAT. *(Supersedes: CLIMB → DISCOVER → CLAIM → ESCAPE → BANK → COLLECT → REPEAT.)*

**Experience pillars:** (1) WOW at first sight and with every new region; (2) immediately legible, satisfying mobile-first actions; (3) rewarding discovery/rarity and social anticipation; (4) meaningful but approachable traversal risk; (5) visible, persistent collections; (6) responsive performance and fair play. Build for a breakout-scale ambition, but **800k CCU is an aspiration, not a performance promise**.

**Quality mandate:** Prioritize visual cohesion, rich hand-crafted composition, purposeful detail, environmental storytelling, lighting, animation, audio and tactile feedback. No rushed final geometry, repetitive asset scattering, obvious placeholders, broken clipping, generic flat terrain, or feature sprawl. Detail must support navigation and gameplay readability. Maintain quality on lower-end mobile hardware with appropriate LOD, culling, texture budgets, and effects scaling.

## 0.5 V2 Expedition Redesign (approved 2026-10-20)

Full plan: `C:\Users\HOME!\.claude\plans\pasted-content-id-9805-climb-hazy-wolf.md`. Reference inspiration: K2 Climbing Simulation (observed from public sources plus the user's six clips, reviewed 2026-10-20, see "Clip observations" below). Do not copy K2.

**User-approved decisions:** (1) expedition-length mountain (§1 duration); (2) partial fall-loss baseline **plus** Camp Lockers and recoverable drop pack; (3) survival = **stamina + warmth only, no oxygen meter**; (4) extraction launch scope = **ATV + helicopter first**; snowmobile/sled later. **Defaults applied, not asked (PROPOSED):** creature trading deferred to a later phase. ffmpeg was installed at the user's request (pip `imageio-ffmpeg`, session scratchpad only, not in the project).

### Clip observations (six TikTok clips, 19–66 s; OBSERVED vs. design implication)
Method and limits: 9 frames sampled every 4 s per clip as contact sheets; no audio; creator captions are claims, not measurements. Five clips are K2 Climbing Simulation; clip 1 (20 s) shows rocky sandstone/forest terrain with a "You caused a rockslide!" notice, a red vehicle on a ledge and a character clinging to a cliff, and I could not confirm it is K2.

| Observed | Implication for us (PROPOSED) |
|---|---|
| Summit run captioned "took me 50 min"; another "2 hours" on the Polish route. Summit card: "SUMMIT REACHED! 8611 METERS +110 POINTS" (route variants give different points, e.g. +70). | Supports the ~60 min first-ascent target; reward a summit with a moment plus a named record, not only points. |
| Multiple named routes (Abruzzi main route sign at base; Polish route to Camp 2). | Branching routes are a proven replay lever; ours need distinct scenery and risk, not just different paths. |
| Fixed-rope lines (red/orange/blue) run along the route; teams visibly roped together; ladders span ice crevasses. | Visible route rope = wayfinding and co-op identity. Reuse as party-colored lines. |
| Camp names float as world labels on distant peaks; signpost at base; prayer flags at base and summit. | Distant camp beacons work. Keep them in the world, not the HUD. |
| Dense HUD panel (oxygen toggle, wind, altitude m, direction, coordinates, time, bars, hotbar, "Summits: N" counter). Text is tiny at phone width. | Our HUD stays minimal: stamina, warmth, carry slots, objective pointer. Keep a simple persistent stat (like a summit count). |
| Terrain is mostly white snow and rock; whiteout frames are near-featureless. | Our biome variety and landmarks are a differentiator; whiteout must keep route lights and silhouettes readable. |
| Clip hooks are falls ("broke the sound barrier"), summit reveals above a cloud sea, group vista photos. | Engineer clip moments: legendary reveal, helicopter landing-zone defense, avalanche-chute dash, base-pad banking ritual. |
| Gear is visible on the avatar (down suit, crampons, ice axe, backpack, headlamp/glow stick at night). | Equipment should read on the avatar so progression is visible to others. |
| No creatures, collection or banking anywhere in the clips. | Confirms the open space; collection meta is our core difference. |

**Vision:** expedition-scale creature collecting on one enchanted ring mountain. Tension: carry unbanked finds onward or extract home.

**Mountain (PROPOSED):** ~4,000×4,000 studs, ~2,000 studs vertical. *(Built 2026-10-20: 4,800×4,800-stud map, playable mountain ≈3,400 studs across, summit at y=2,000.)* Camps: 1 Meadow Lodge (Green Valley), 2 Rootgate (Whispering Forest), 3 Chasm Hut (Broken Cliffs), 4 Stormwatch (Storm Ridge), then Frozen Summit; plus a hidden region (Glacier Caves / Sky Garden). Camps = respawn, campfire, Camp Locker (1–3 safe slots), social hub. Each push adds one new traversal verb. Hazards telegraphed (wind, whiteout, rockfall, avalanche).

**Creatures (PROPOSED):** rarity rises with altitude but every zone keeps commons, a hidden Rare and weather mutations. Eggs take 2 slots and hatch at base; creatures 1 slot. Backpack 4 → ~12. First server-wide claim of a legendary earns a plaque/tag; no PvP. Summit: 3–5 summit-only legendaries.

**Extraction (PROPOSED):** one-way downhill only. ATV trails at low camps; helicopter from a ridge landing zone (~80% elevation) after a beacon is raised on the way up and a free regenerating **Flight Token** is spent; hold the zone 60–90 s while weather builds; storms ground it. Helicopter seats 4; Rescue Flare for stranded teammates. Arrival at the base pad auto-banks. Vehicle cargo strain risks only unbanked cargo. Tokens are never sold; monetization stays cosmetic (vehicle skins OK).

**Home base "Foothold" (name PROPOSED):** Expedition Hall, Gear Forge, Provisions Market, Garage, helicopter pad, terraced cabins with roaming habitats, Hatchery, campfire plaza, Hall of Wonders; summit-view plaza as the first-screenshot moment.

**Build gates (V2):** A tooling audit → B mountain blockout → **C benchmark slice (Foothold + Valley→Camp 1, final fidelity; stop for user approval)** → D region-by-region scale-up → E full Foothold → later separately approved gameplay systems. Gate 1 of §11 is superseded by Gate C.

### Build status after the overnight run (2026-10-20, not yet reviewed by the user)
All of the following is **first-draft world art, NOT final fidelity and NOT approved**. Evidence: `evidence/gateB…gateE/`; measurements and gaps: `CLAUDE.md` "Morning report".
- **Gate A** done (tooling verified). **Gate B** done (procedural mountain, route, rings, water, chasm). **Gate C** built as a first draft: it does **not** yet meet "final fidelity", so Gate C is **not passed**. **Gates D and E** built as first drafts on top of an unapproved Gate C (the brief's one-night override); they will need rework once the Gate C look is approved.
- Built (PROPOSED names/placements): camps 1 Meadow Lodge, 2 Rootgate, 3 Chasm Hut, 4 Stormwatch (each with lodge/hut, Camp Locker prop, campfire, beacon, sign); Falls Overlook; Enchanted Tree with root arch; forest ruins; Monumental Chasm Bridge; Wind-Scarred Ruin with lightning spire; Crown Observatory; helicopter LZ (~77% height); Foothold with summit-view terrace spawn, campfire plaza, Expedition Hall, Hall of Wonders, Gear Forge, Provisions Market, Garage + ATV trail start, Base Pad, Hatchery, 9 terraced cabins with habitat yards.
- **Route vs. LOCKED duration:** main route 16,887 studs, 2,386 studs of ascent, ESTIMATE 17.6 min pure walking (pushes 2.4–4.3 min) vs. the 25–30 min skilled / 10–15 min-per-push target. Needs a design decision on how to close the gap (OPEN).
- Not built yet: caves, hidden region, risky shortcuts, weather, audio, creatures, any gameplay system.
- Design source: `design/world-tokens.md` (every color traced to §3/§4 wording; PROPOSED).

### Traversal pass (user-approved 2026-10-20)
Plan: `design/traversal-plan.md`. Approved: close the gap mainly with traversal on the existing route, one new verb per push (P1 climb, P2 bounce/platform, P3 fixed rope + rockfall, P4 brace against gusts, P5 ice footing + avalanche), difficulty rising with altitude.
- **The "10–15 min per push" target applies to first-time players.** Skilled players ≈ 5–6 min per push (25–30 min total). This is the only reading consistent with both LOCKED totals.
- **Expedition pace:** `CharacterWalkSpeed` 16 → **12**. Measured physics: native climbing runs at 70% of walk speed (11.2 studs/s at 16), and skilled players cross obbies at close to walking speed, so segments alone add only ~1–2.5 min. At 12, pure walking is ≈23.5 min.
- **Slope limit:** `CharacterMaxSlopeAngle` 89° → **45°**. Measured: at 89° every steep band can be walked straight up. At 45°, 50° ramps block the character even with jumping, and the route's steepest grade is 38.7°.
- **No easy lines.** Every segment uses catch-and-retry only.
- **Hazard hits knock you back only** (no health loss) until the fall-loss system exists.

## 0.6 V3 Ascent redesign (user interview 2026-10-20; plan awaiting approval, nothing built)

Plan, checklist and measurement methods: `design/v3-ascent-plan.md`. **Supersedes** the unbuilt P3–P5 of the traversal pass, the "Mountain (PROPOSED)" 2,000-stud summit in §0.5, and "No easy lines" (the easy route is forgiving by design). P1/P2 verbs and measurements are re-done on the new terrain.

**LOCKED (user choices):** keep Ring Mountain + 5 regions with a unique summit crown (buttresses, fins, arch or notch) and taller massifs · dry foothills band under Green Valley where Foothold sits, then valley → forest → cliffs → ridge → snow/ice · summit **~3,200** · **4 routes** (Shepherd's Road easy, Waterfall Stair moderate, Cliff Ledge Line hard, hanging off the mountainside, Spire Ridge expert), fixed intensity per route plus rising exposure with altitude · routes separate at base, cross at the shared camps, merge near the summit · every route 25–30 min skilled (first-time ~60 min measured on the easy route) · fall/hit = stagger + fall-loss of unbanked cargo only, no HP damage · checkpoints = 4 camps + a mini-checkpoint ~every 4 min per route · hazards: falling trees, rockfall, wind gusts, avalanche chutes (crumbling ledges not chosen), telegraphed and fair, punishment scales by route · Foothold ~3× area, open plaza, 4 route gates, Route Board, summit-view amphitheater spawn, landmark tower/waterfall mill, cable-car station · mobile-first: best performance and quality on mobile · guaranteed introductory Rare on the first stretch of the easy route, beginner protection on every route.

**PROPOSED:** map footprint ~5,600²; camps at ~15/32/50/70/100% of height; cable car decorative only; mobile budget 30 FPS floor on a mid-range phone, 60 desktop; per-route times/lengths and hazard counts in the plan; dry-foothill palette needs a reference (none exists, will ask).

**Conflicts flagged:** forgiving early segments vs scary hard routes (resolved by route-based intensity), guaranteed Rare placement (resolved), 25–30 min band on a taller mountain (measured in plan phase P2 before building), Green Valley "lowest elevation base" (foothills now below it, §4 text superseded where it conflicts). §8's "guided ascent into the forest" for the first Rare is replaced by the easy route's first stretch.

## 1. Decision ledger — LOCKED by user

- **Art identity:** Colorful stylized magical fantasy; **Enchanted Adventure** base treatment (vibrant stylized nature, magical lighting, glowing details, rich readable environments).
- **Regional mood:** Explicit user selection **C + D blend** — **Enchanted Fantasy × Epic & Mystical**. Lower zones are welcoming/vibrant, upper zones more cinematic/mysterious; never turn the whole game grim, muddy or photoreal.
- **World silhouette:** **Ring Mountain** — one iconic central summit with interconnected surrounding routes and multiple vantage points.
- **Region arrangement:** **Interconnected Vertical Ring** — five elevation regions joined by circular traversal trails, caves, alternate routes and vertical shortcuts; direct and looping climbs both viable.
- **Five regions (names and concept):** Green Valley, Whispering Forest, Broken Cliffs, Storm Ridge, Frozen Summit.
- **Mountain traversal duration (V2, user-approved 2026-10-20):** skilled direct route ~**25–30 min**, first-time ascent ~**60 min** over several sessions, built from 10–15 min "pushes" between camps; timings must be measured and tuned. *(Supersedes the original 5–10 min target.)*
- **Climbing:** Hybrid adventure traversal + skill-based obby segments; easy to learn, difficult to master.
- **Movement tools:** Run, jump, climb; unlock ropes, gliders and other traversal equipment.
- **Creatures:** Species, rarity tiers, mutations and variants; common natural spawns, rares in hidden locations, legendaries in competitive server-wide discovery events, secret weather-linked mutations.
- **Claiming:** Approach and **hold** to claim; no stealing and no conventional PvP.
- **Inventory:** Limited backpack slots; earn more capacity through progression.
- **Risk:** Falls cause **partial loss of unbanked creatures**, not collection already banked; earned protection for valuable finds; beginner onboarding protection. V2 adds (approved) Camp Lockers and a 3-min recoverable drop pack on top of this baseline.
- **Banking:** Return to bank/unload finds at personal base, making them permanent.
- **Bases:** Customizable cabins with outdoor roaming creature habitats and displays.
- **Progression:** Exploration levels, earned equipment upgrades, collection milestones.
- **Multiplayer:** Shared world, first-claim competition, cooperative climbing, rescue assists and expeditions; no player-killing, damage PvP, eating or stealing each other's creatures.
- **Onboarding:** Immediate common creature discoveries and **a guaranteed introductory Rare within five minutes**.
- **Retention:** World events, rotating mutations, collection milestones, seasonal additions.
- **Approved monetization:** Cosmetics, cabin decorations, appearance and visual effects. Other monetization is **not approved**; do not add pay-to-win shortcuts or paid rare/legendary odds by default.

## 2. Design status and authority

**LOCKED:** All items in §1 and the core fantasy/loop.

**PROPOSED build defaults (Claude Code can execute provisionally, document and refine with tests):** Visual compositions and palette families below; travel-route naming; initial zone landmark candidates; initial species and content counts; rarity color treatments; UI layout; implementation technology. They are NOT retroactive user approvals.

**OPEN — get decisions only if identity-changing, otherwise apply reasoned defaults:** Exact species roster, rarity thresholds/drop/spawn rates, event cadence, rescue rules, stamina vs no stamina, fall severity and protection values, bank placement/return flow, currency/economy balance, monetization expansion, cabin modules, precise first-10-min pacing, persistent progression thresholds, seasonal roadmap. For any such defaults, record rationale and proposed status; do not assert LOCKED.

**Conflict handling:** Explicit user LOCKED decisions > this spec's proposed details > `CLAUDE.md` workflow defaults > implementation preference. If a genuine collision arises, pause the affected design and ask; keep building independent tasks.

## 3. Art direction / non-negotiable WOW

### Visual language
- Stylized high-quality sculpted shapes, readable silhouettes, rich materials without noisy realism. Curved organic topography combined with authored rock strata, sculpted tree trunks, bold flora and controlled crystalline magical structures.
- **Lower half:** golden daylight, lush saturated greens, layered flower fields, clear turquoise falls, soft volumetric-looking mist (cheap implementation), inviting warm civilization.
- **Mid mountain:** deep forest teal, amber lanterns, floating particles, iridescent mushrooms, ancient stone ruins, glowing roots; dramatic cliff scale and atmospheric depth.
- **High mountain:** deep cobalt, storm violet, electric cyan, moonlight, dramatic clouds, glowing runes and icy crystal facets. Preserve bright traversal contrast and legibility at all times.
- Material variety: ground paths, lichen-covered rock, fractured cliff rock, wet stone, timber, moss, leaves, water, crystal, ice/snow, ruin masonry. Prevent texture tiling and abrupt material seams; use trim/decals/details judiciously.
- Strong composition at every bend: foreground frame → navigable middle-ground objective → distant aspirational landmark. Repeated summit glimpses provide orientation and motivation.
- Magical effects used as focal accents, not everywhere. Rare and legendary visuals must immediately read as special, even on reduced graphics quality.

### Production detail standard
- Every major trail should have authored shoulders, landmarks, plants, rocks, signs/wayfinding, ambient motion and a reason to stop and look.
- Every bridge/rope/rail/stair must have believable attachments, collision, safe jumps, functioning connections, shadows/occlusion and readable edges.
- Waterfalls have source, descent, splash pool/mist and acoustic placement; avoid floating water or bad intersections.
- Caves have distinctive entrances, readable traversal, sound/lighting transitions and at least one purpose (secret, shortcut or species habitat).
- Each region has a hero vista, one recognizable signature landmark, several discovery nooks, a traversal set piece and hidden reward space.
- Choose view angles and silhouette before micro-detail. Validate in **Roblox Studio at actual avatar scale**, from the default camera, and on phone aspect ratios.
- Avoid visual noise around collectible silhouettes, paths, interaction prompts and edge hazards.

## 4. Mountain architecture and navigation

**Overall:** One mountainous play space, central Frozen Summit visible frequently, several circumferential trails stitched to steep elevation climbs. Primary route is safe/readable; alternative routes provide speed, secrecy or technical challenge. Players should be able to tell which region they are in by terrain, color and landmark alone.

**World topology (PROPOSED):** Green Valley hub/base perimeter at lowest elevation. Whispering Forest is a looping woodland ring with branching grotto network. Broken Cliffs introduce exposed vertical climbs and scenic rope bridges. Storm Ridge forms upper windblown ring with alternate sheltered tunnels. Frozen Summit is apex with dramatic payoff, panoramas and elevated-risk rare opportunities. Different aspects of the rings overlap visually; avoid 5 disconnected linear boxes.

**Navigation specification:**
- Main readable ascent, at least one intermediate loop or branch per region, and at least one risky shortcut in advanced regions (counts provisional).
- The same route can be taken upward or downward where possible; gliders and ropes provide intentional escape value, never accidentally bypass all risk.
- Place visual beacons at meaningful route junctions. From each main junction, camera should reveal next objective or conspicuous wayfinding.
- Distinct safe platforms/landings, no unavoidable physics glitches, checkpoint/recovery design that respects carrying risk.
- Test solo novices, experienced speed climbers and co-op parties. Time ascent and evacuation independently.

### Region briefs (creative direction; micro-elements PROPOSED)

| Region | Mood & palette | Signature landmark | Traverse & encounter promise |
|---|---|---|---|
| Green Valley | Golden daylight, meadow emerald, turquoise | Waterfall-side settlement and first panoramic overlook | Gentle terrain, tutorial climb, first friendly creature, personal cabin reveal |
| Whispering Forest | Emerald/teal shadows, warm lantern gold, luminous indigo | Enormous enchanted tree / root arch | Hidden side-paths, soft platforming, woodland grottos, secret rares |
| Broken Cliffs | Sandstone amber, charcoal slate, bright sky blue | Monumental bridge spanning an exposed chasm | Vertical scrambles, careful footing, caves/ledges, rescue moments |
| Storm Ridge | Storm blue, electric violet, cyan | Wind-scarred ruin with magical lightning focal point | Gusts, reduced visibility, sheltered alternatives, weather-mutated spawns |
| Frozen Summit | Luminous ice blue, deep sapphire, aurora purple | Crown-like crystalline summit observatory | Expert climbing payoff, exceptional vista, high-stakes events and descent |

Design the silhouette so the lower valley can see upper-region silhouettes, while visibility in individual regions varies with conditions. The mountain should feel big and magnificent despite short skilled-route duration: use vertical framing, atmospheric perspective, switchbacks and layered overlooks, not merely artificially stretched walking distance.

## 5. Creatures and collection

**Creatures:** Endearing original silhouettes, varied body proportions, easily distinguishable shape language and motion. Each species should communicate a simple personality through ears/tails/eyes/idle movement; avoid cosmetic recolors being mistaken for different species. Environment-specific ecology and behaviors (perched, hopping, floating, hiding) signal where to discover them.

**Rarity visualization:** Readability first: silhouette, idle animation, distinct particle treatment, subtle audio cue, collectible card and rarity border. Use color in combination with labels/shapes so color-blind players are not disadvantaged. Avoid overpowering bloom or expensive constant effects.

**Spawn model (LOCKED behavior, parameters TBD):** Commons appear naturally, rares in hidden spots, legendaries via announced server-wide event + competitive first claim, mutations during unusual weather. Authoritative server adjudication, fair proximity validation, claim race handling, spawn state replication and anti-exploit protections are required.

**Claim loop:** Detect creature → move into safe interaction radius → visible hold progress → server confirms claim → satisfying character/creature VFX, SFX and inventory update. Make interruption/cancel, competing claimants, full bag, disconnect, lag, despawn and falling during a claim deterministic.

**Carrier risk:** All carried creatures remain **unbanked** until deposited; partial-loss events target only unbanked contents under documented rules; rare protection is earned, not a purchase advantage. Distinct UI for protected/unprotected cargo and strong warnings before high-risk jumps; never silently delete possessions.

**Collection:** Durable unique ownership records, species/variant/mutation attribution, acquisition source/time where appropriate, visible codex milestones, duplicate handling and exhibition at player habitats. Exact collection economy TBD.

## 6. Traversal and gameplay feel

- Quick responsive avatar acceleration and landings; predictable jump and climb arcs, forgiving early failures and advanced mastery on optional paths.
- Traversal interactions must not depend on pixel-perfect mouse targeting; mobile camera, hold prompts, ropes and gliders should be ergonomic.
- Equipment enhances route choices rather than simply inflating character stats. Progression should create meaningful revisit opportunities for earlier regions.
- Weather meaningfully changes visibility, safe routes, traversal and mutation discoveries. Telegraphed, readable hazards, modest audiovisual effects scaling, no sudden undodgeable loss.
- Multiplayer assists create hero moments without letting players abuse rescue mechanics to grief or bypass the full economy.
- Failure feedback: camera/audio cue, reason for loss, clear list of what was lost/retained, accessible return route, newcomer shielding.

## 7. Cabins, habitats and social experience

- A readable base/cabin for each player, accessible from the valley hub, with obvious bank interaction. Persist cabin placements and collection displays separately from carried, unbanked creatures.
- Exterior exhibits visibly showcase rare species and mutations. Roaming creatures need contained, performant pathing, animation variation and non-overlapping safe zones.
- Social interactions: visit friends, inspect exhibits, celebrate legendary finds, co-op expedition grouping and rescue moments. No direct theft or destructive PvP.
- Visual customization must use modular art sets and reasonable decoration bounds; remote purchases or placement requests server-validated.

## 8. Mobile-first UX / onboarding

**Priority:** A first-time player must understand **climb, find, claim, return, bank** without reading paragraphs. The first minutes should look like the polished game, not a tutorial staging area.

**Suggested first 5 minutes (PROPOSED pacing; Rare by 5 minutes LOCKED):**
1. Spawn at a stunning valley vista with a clearly animated common creature nearby.
2. On-screen camera/move hint; low-friction first hold-to-claim, instant collection feedback.
3. Show backpack count and a visible route marker to nearby cabin/bank.
4. Deposit first creature, watch it appear in habitat with celebratory feedback.
5. Guided short ascent into forest secret leading to guaranteed introductory Rare **before minute 5**, even if player has slow movement; no player competition may steal this guaranteed tutorial Rare.
6. Introduce partial cargo risk *after* protected beginner phase; unlock progression promise and next mountain landmark.

**HUD:** Minimal thumb-friendly controls; objective pointer, zone name, carried capacity, rare-event alert, equipment context affordance. Codex/cabins on demand, not persistent intrusive overlays. Check phone-safe inset, large tap targets, low-text localization readiness, icon+text semantics, graphics tier scaling, controller/keyboard compatibility.

## 9. Economy, retention, monetization guardrails

- Progression must be earned and player-friendly. Explore collection milestones, levels and equipment upgrades; tune through playtesting, not arbitrary endless grind.
- Daily and weekly reasons to return must emphasize changing discovery experiences, not coercion. World event announcements need enough warning for distributed players to converge fairly.
- Approved monetization only: avatar/gear aesthetics, cabin decorations, visual effects and similar noncompetitive customization. Do not sell better creature odds, exclusive power, immunity from lost cargo or guaranteed first claim without explicit review.
- No dependence on speculative success or engagement numbers. Instrument honest onboarding completion, first bank, first Rare, return rate, session enjoyment and technical stability.

## 10. Engineering / Claude Code execution requirements

Implementation owner: **Claude Code** (including Roblox Studio integration, procedural/manual geometry, assets, scripts, UI, test, build automation). Claude Code must inspect repository, Roblox Studio linkage, toolchain, existing project assets, permissions and persistent backend BEFORE choosing architecture. It must document actual setup in `CLAUDE.md`; no invented installed packages/credentials.

Suggested system boundaries: World/Regions, Terrain & Asset Pipeline, Weather, Creature Catalog/Spawn/Claim, Carry & Fall, Banking/Persistence, Progression/Equipment, Cabins/Habitats, Parties/Social, Events, UI/Input/Accessibility, Telemetry/Diagnostics, Anti-exploit and Testing. Favor modular server-authoritative state transitions for ownership and rewards. Never trust client claims of spawn, rarity, claim success, or inventory mutation.

**Persistence:** server-side durable store, session consistency, autosave/retry logic, idempotent deposit operations, safe shutdown, migration/version scheme and graceful failure behavior. Avoid data loss or duplicate rewards under rejoin, double-click, disconnect, race conditions or DataStore failures. Respect platform limits.

**Performance:** Profile worst-case camera views at dense valley, crystal-lit caves, VFX-heavy legendary events, crowded summit and creature-rich cabin habitats. Define measurable budgets based on actual test target devices/hardware; render-tier fallbacks for particles, dynamic light, foliage, shadows, ambient animation and effects. No blanket visual degradation when a localized optimization works.

**QA:** Automated tests where feasible plus recorded Roblox Studio/client checks. Multi-client race tests for claim ownership, fall during hold, inventory full, deposition interrupted, weather transition, co-op rescue, glider clipping, data reload, server shutdown and economy integrity. Test on real or emulated mobile/desktop/controller. Capture representative screenshots and video clips as visual acceptance evidence.

## 11. Milestone strategy — LOOK AMAZING EARLY

**Gate 0: Read the rules.** Audit repository and tools; populate `CLAUDE.md` from actual Claude context and project state; create decision ledger, asset plan and QA matrix. No speculative claims about backend.

**Gate 1: Vertical hero slice.** Build **one production-quality playable vista** spanning Green Valley → entrance of Whispering Forest: beautiful terrain silhouette, authored waterfall, bridge/path/vegetation, lighting, fog, high-quality materials, one polished creature, hold-to-claim, carry, bank, cabin display and mobile HUD. Present screenshots/video and actual Studio test evidence before scaling the same art standard to entire mountain.

**Gate 2: Traversable complete Ring Mountain.** Establish coherent five-region topology, summit visibility, accurate scale, safe baseline ascent/return route, planned branches/shortcuts, traversal metrics. Graybox MAY exist internally for blocking, but may not be presented as finished visuals.

**Gate 3: Regional polish.** Fully art-direct each zone's signature vista, traversals, audio, caves, bridges, waterfalls, weather effects and rare discovery habitats; no unpolished region accepted as complete.

**Gate 4: Reliable game loop.** Build server-authoritative spawns/claims, backpack, fall loss/protection, banking, persistence, equipment, events and fair multiplayer interactions. End-to-end loop works across rejoins.

**Gate 5: Onboarding, social and economy.** Finish guaranteed Rare, collection showcase, cabin customization, rescue/parties, retention content and permitted cosmetics.

**Gate 6: Full QA, profiling, visual art pass, ship readiness.** Audit every navigable map element, every major camera vista and key interaction; fix edge cases and performance regressions. Record unresolved items honestly.

*Claude Code may adjust implementation order to preserve early vertical-slice WOW and technical feasibility, but must not downgrade end-quality or silently cut LOCKED gameplay.*

## 12. Acceptance gates

- [ ] First playable camera view is visually memorable: deliberate composition, regional identity, summit focal point, no unfinished geometry visible.
- [ ] Green Valley through Frozen Summit feel like **one cohesive mountain** with readable circumferential/vertical shortcuts and differentiated landmark silhouettes.
- [ ] Skilled-player summit runs measured within the V2 ~25–30-minute band via intended routes; first-time ascent ~60 min; each camp-to-camp push 10–15 min; novice route playable without repeated unclear failures.
- [ ] Full claim → carry → escape → bank → exhibit loop works reliably and survives session transitions.
- [ ] Common spawn / hidden Rare / competitive event Legendary / weather mutation flows all implemented and validated.
- [ ] Guaranteed first Rare by 5 minutes measured in beginner usability tests.
- [ ] Falls cause bounded partial loss of **unbanked** creatures only, with clear feedback and correctly earned protection.
- [ ] No stealing/PvP, no exploit granting free ownership, no duplicate banking or data loss on tested failure cases.
- [ ] Mobile touch interactions work and important silhouettes/prompts remain legible across graphics tiers.
- [ ] Every region passes visual walk-through checks: landscapes, foliage, bridges, waterfalls, caves, props, collision, effects, ambient audio, discovery hiding spots, routes.
- [ ] Measured multiplayer stress and graphics performance; document device profiles and actual observations, not invented targets.
- [ ] Allowed monetization only; no mechanics that sell claim advantage or protected rarities.

## 13. How to maintain this file

Claude Code must update implementation plan, milestone evidence, decisions, revised budgets and verified acceptance results here without erasing the original approved user constraints. Explicitly tag new author-proposed content **PROPOSED** until approved; tag objective test outcomes **VERIFIED** only with evidence. Keep `CLAUDE.md` focused on agent instructions, workflow, actual toolchain, repo layout and conventions. Link between files; do not duplicate conflicting rules.


## Fairground redesign local review — 2026-10-22

All four implementation phases are saved in `Fairground.Finale.Review.rbxl` (identical working copy: `ClimbAndCollect.Fairground.Review.rbxl`). Final integration source: `ffb15a2`; phase commits: `be2f7aa`, `877be3f`, `92b2f4a`, `ff1f1d5`. Read [the implementation handoff](design/fairground-implementation-handoff-2026-10-22.md) before continuing. Reopened binary verification passed for 101 sources, exact terrain and protected assets. Independent code review findings are resolved. Genuine whole-ascent acceptance remains incomplete at a preserved Shepherd terrain overhang; real multiplayer, physical phone/controller and DataStore networking remain unverified. Do not treat injected summit eligibility or profile release/reload fixtures as these tests. No publishing or commerce activation occurred. Starting dirty/untracked work is recoverable in the local starting-source archive; Git alone is not the whole project.


## Fairground polish acceptance — 2026-10-22

Supersedes earlier incomplete-ascent status: a genuine natural-spawn ascent completed all four camps and sixteen traversal sections without position or eligibility injection. Diagnostic stops, backtracking and live route repairs mean the recorded 32m54s is not a speed benchmark. One summit awarded 150 coins, 200 points and First Light Pennant; duplicate calls awarded nothing. Actual mouse return reached the bank and acknowledged result 1. Final `Fairground.Polished.Acceptance.rbxl` was reopened: 104 sources match/compile, terrain exact, seven protected groups unchanged, no QA agents, HTTP off. Actual two-client checks passed 16/16 before final terrace/stair changes. Physical devices, live DataStore networking and same-account reconnect remain unverified. Details: `design/fairground-polish-handoff-2026-10-22.md`. No publishing or spending.


## Mountain HUD/UI isolated implementation — 2026-10-24

VERIFIED in `codex/mountain-hud-ui`: approved 28-question blueprint recovered from `23ee172`; eight hubs/23 tabs, authoritative intents, settings and responsive HUD committed at `5e67fc2`. Read [the implementation report](design/hud-ui-implementation-report.md) for the baked review, 419 CLI/service checks, 50 isolated Studio checks and four device-emulator presets. Original expedition/profile rules are preserved. Direct sanctuary bridge, habitat/build/placement, party lifecycle, rankings and commerce remain blocked by missing services; physical device/live persistence/eight-client acceptance is unverified. Concurrent mountain art revisions are not automatically included. The original graph excludes this worktree source.

## Tycoon Q1–Q11 implementation review — October 24–25, 2026

Current user-approved redesign supersedes old passive collection income for migrated mountain profiles: 2–8 assigned habitats, production eggs distinct from hatchable eggs, batch collection and bag, manual banking through five automation stages, capped stored offline output, modest rarity/adjacency/upgrade bonuses, no streaks or resets. Existing eight-player sanctuary integration and six kingdoms are preserved. The 110x120 production grid fits inside each unchanged outer plot. See design/tycoon-redesign.md (balance assumptions) and design/tycoon-implementation-report.md (verification and limitations). Runtime implementation is a local review build; premium visual acceptance, live DataStore, eight-client and physical-device acceptance remain open.

## Tycoon readability and economy baseline — October 25, 2026
VERIFIED: restrained habitat/machine framing, visible storage fill/FULL status, clear-on-vacancy visuals and next-upgrade benefit text. Fresh tests and Review04 world-preservation audit: design/tycoon-polish-2026-10-25.md. PROVISIONAL economy unchanged: two starter producers save first20 coins in9.1 simulated minutes with continuous banking; full late-game/human balance is not accepted. Eight real clients, hosted saves and physical phones remain unverified; no merge or publish.


## Sprint and direct entrances — October 26, 2026

Owner-authorized local review: C:/Users/HOME!/Desktop/climb-collect-free-climb-build/outputs/ClimbCollect.FreeClimb.Review03.SprintEntrances.rbxl, SHA256 af2c14388fc6be0b7b4739c94f7a5417780f3d271bad4f06037d045fc5cb4da5. Sprint16/27, cargo0.9 provisional; two extra wide side approaches/physical exits, eight180x220 plots unchanged. Fresh1,562 checks/25 suites/75 compiles, exact75-source cold-open, loaded two-arm run and west physical-exit ownership plus both outer-plot walks verified. All70 terrain properties restored equal Review02 after detected Studio SmoothGrid drift. Review02 unchanged. Full evidence/limits: isolated design/sprint-entrances-review-2026-10-26.md and evidence/sprint_entrances_2026-10-26/. Actual touch/hosted saves/human pacing/published animation permission/new multiplayer sprint matrix remain open. Graph excludes isolated source. No publishing or unrelated place changes.

## HUD polish — October 29, 2026
Status: owner plan tasks 1–6 BUILT and Studio-verified at phone sizes (i16p, i16pm, 844×411); task 7 Studio-side DONE, physical phone NOT re-checked (needs owner-approved republish). Locked by owner: health bar removed; compact profile card = name, level, XP, creatures, coins/s (sanctuary only; expanded reveals the five launcher circles; closes on tap again / outside / any page). Open: every image icon renders blank on the phone (asset delivery; owner checking the dashboard). See `design/homebase-handoff-2026-10-29.md` § HUD polish.
