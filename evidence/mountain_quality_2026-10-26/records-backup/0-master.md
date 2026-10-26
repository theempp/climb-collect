# CLIMB & COLLECT — MASTER BUILD SPECIFICATION

> October 25, 2026 complete free-climb design APPROVED as planning basis, including its carry/travel/shared-guardian/Trial-custody proposals. Owner requested no generation/build in this chat and a separate actual-build chat. [Approved spec](docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md), [implementation plan](docs/superpowers/plans/2026-10-25-free-climb-mountain.md), [handoff](design/free-climb-build-handoff-2026-10-25.md). Numbers remain provisional; publication not authorized.

> October 25, 2026 section decision: owner explicitly retained all six existing sections with simpler layouts and a distinct danger in each. Coherent [free-climb design draft](docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md) is ready for review; carry/travel/shared-guardian/Trial-custody proposals are not yet approved. No rebuild or trip duration approved.

> October 25, 2026 recovery decision: guardian catch or serious drop-causing fall loses the unsecured creature; retry an egg. Already secured creatures remain safe. No recovery-pack window in the intended new loop. Exact failure thresholds, respawn and disconnect/travel rules remain open. [Evidence](design/mountain-simplification-review-2026-10-25.md). Design only.

> October 25, 2026 combat design decision: owner selected a brief raid opening plus companion XP for optional normal guardian wins, with harder Trials earning the guardian collectible. Guardians return to defense; no permanent danger removal or access gate. Exact tuning and Trial custody remain open. [Decision evidence](design/mountain-simplification-review-2026-10-25.md). Design only.

> Latest section-access decision, October 25, 2026: players may climb into all mountain sections from the start. Increasing guardian combat/pursuit difficulty and hazards provide the practical barrier; no mandatory guardian victory or collection milestone for access. Keep different sections. Steal an Egg and Break and Steal an Egg are the requested close concept references, with thoughtful improvements. No trip duration or rebuild approved. [Finish-design handoff](design/free-climb-mountain-handoff-2026-10-25.md).

> October 25, 2026 mountain design continuation: owner selected an open mountain face with visible eggs and a direct downhill escape, guardian pursuit plus a few hazards, and guardian approach triggered by the first pickaxe strike. Owner clarified that different sections remain, with guardians progressively more aggressive and harder to beat. Exact section count/mapping, combat/escape rules, pacing and recovery remain open; no trip-duration range selected. Mountain exit into sanctuary permanently secures the creature, then carry home. Existing builds stay preserved. Design only, no rebuild approval: [decision record](design/mountain-simplification-review-2026-10-25.md).

> October 25, 2026 current-status overlay: [START-HERE.md](START-HERE.md) and [workspace review](design/workspace-review-2026-10-25.md) supersede older integration/feature status below. One-place integration, tycoon and newest HUD exist in durable feature clones; latest changes are not yet combined. Exact HUD recovery copy retains recorded hash; ordinary Review02 has artifact drift with matching runtime scripts. Tycoon Review06 cold-start and eight-client evidence are recorded; premium art, phone and hosted saves remain open. Existing design requirements remain unless explicitly superseded by an owner decision.

> Recovery update, 2026-10-24: W01/W02 complete. Full mountain backup and independent restore verified; HUD recovered clean at `6019525` in `.codex/worktrees/mountain-hud-recovered/climb&collect`. Earlier missing-checkout/session statements below are historical. [Recovery record](design/workspace-recovery-2026-10-24.md). Integration remains pending.

## Current release plan and design reconciliation — 2026-10-24

The owner explicitly chose **the full Mountain Empire vision before public release, including advanced services**. Follow [the project overview](START-HERE.md), [publishing checklist](design/publishing-checklist.md), and [workspace/evidence audit](design/project-audit-2026-10-24.md). This adds a current status index without erasing the historical decisions below.

Current product authority: enlarged eight-plot sanctuary (180 × 220 plots, Step2 lodges accepted, Step3 environment awaiting visual review), one six-kingdom Impossible Mountain with approved natural-route redesign, and locked Q1–Q28 HUD blueprint. The old V2/Expedition/Fairground/four-mountain layouts and their economy/private publication are separate history, not instructions to combine them into the new game. Current mountain schema 1 is separate from legacy profiles; new monetization is approved cosmetics/noncompetitive convenience, not an automatic import of Foothold Exchange offers.

No combined release candidate exists. Sanctuary is script-free; Final56 lacks the new HUD/sanctuary integration; HUD draft PR #1 uses older ArtPassVerified world geometry. Missing habitats/build services, parties, full raids/friend challenges, rankings/badges/titles, daily rewards and shop backend are **required launch work**, alongside art acceptance, hosted persistence, multiplayer and real-device testing. Six normal Guardians/mover loops/twelve branches have recorded full automated solo evidence; all Trials and shortcut travel must be reaccepted on the final integrated geometry. No readiness percentage or launch date is asserted.

Next proposed milestone: one recoverable integrated local alpha. Owner phone test candidates are iPhone 16 Pro and reported iPhone 18 Pro Max; no physical test is claimed. Exact verified results, current workspace discrepancy, decision queue and acceptance gates are in the linked checklist/audit. Planning does not authorize publishing, merging or new game implementation.


## Expedition hall + sunny slice — plan approved, 2026-10-23

The scoped [lobby + sunny slice plan](docs/superpowers/plans/2026-10-23-lobby-sunny-slice.md) is approved. Owner choices:
- an isolated enclosed hall far off-map (old Fairground archived)
- the hall look comes from generated concept references that the owner approves first
- the sunny slice is Shepherd trailhead → Camp 1
- window previews are 3D dioramas, with three Coming Soon destinations
- ambient sound may use free Creator Store audio

The build runs in a new chat. Nothing is built or verified yet.

## Four-mountain movement — integrated and live-checked, 2026-10-23

Movement phase built, saved in the Codex worktree review file and copied into this folder's `src/`: lobby run 22, mountain walk 16, sprint toggle 23 sharing climb stamina (10/s, retoggle after exhaustion), bank-safe speed validation. Desktop live checks and all suites pass. The saved file is verified on disk and on reopen. A two-player local test passed. Phone and controller testing remains. See [movement handoff](design/movement-handoff-2026-10-23.md). Values are provisional tuning.

## Expedition hall + sunny slice — built and verified for review, 2026-10-24

Phases 0–6 are done in worktree `Desktop\climb&collect-lobby` (branch `claude/lobby-sunny`); review file `ClimbAndCollect.FourMountains.LobbySunny.Review.rbxl` (SHA `737364cc…`, reopened clean). Owner rulings this build: Camp 1-only extraction waystone, Garamond signs, slice terrain colours kept as they are.
- **Hall**: finished interior (glazed crown, rib lanterns, roof daylight, three planted trees with ferns and vines, banners, benches, lounge, stocked bank/shop) and four dioramas behind the enchanted glass: sunny (C4) and snow (C1) live previews, rainforest and volcanic as neutral silhouettes. Shimmer, cloud, aurora, leaf sway, particles and free Creator Store ambience, with reduced-motion and phone tiers. Bank 3.3 s and shop 2.6 s from spawn at lobby speed.
- **Sunny slice** (trailhead → Camp 1, parts only): 227 faceted spruces, two clearings, an exposed rock overlook, a rooted rockfall (18 studs) and a two-pitch rock step with a ladder. BOT 148 s to Camp 1, 0 stuck; no bypass, perches or blocked trail. No waterfall is visible from this stretch.
- **Verified** (desktop Studio, mock store): all suites; real keyboard/mouse depart → Camp 1 extract → bank → rejoin → resume; two clients split and reunite; landscape-phone emulation of the hall, departure panel and HUD; 60 FPS in the hall, at the trailhead and over the slice. Two bugs fixed (keys swallowed after departing; phone sprint toggle hidden).
- **Not verified**: physical devices, real DataStore/reconnect, a genuine summit + reset on this build (fixtures only), phone tier live, audio by ear. The slice's dry terrain colours don't match C4. Details: [handoff](design/lobby-sunny-handoff-2026-10-23.md).

Earlier note: plan approved; build ran first in the Codex worktree (`claude/lobby-sunny`). Owner kept hall concepts C1 (hall from spawn), C3 (floor + inlay) and C4 (window + departure); C2/C5/C6 rejected. Hall design values now come only from `references/lobby/` via `design/hall-intel.md` (worktree). Rune glow toned down by owner ruling. Rainforest/volcanic previews have no approved image and stay neutral. Status per phase: [handoff](design/lobby-sunny-handoff-2026-10-23.md).

## Four-mountain movement plan — 2026-10-22

The approved written design now has a scoped [movement implementation plan](docs/superpowers/plans/2026-10-22-four-mountain-movement.md), pending plan review/execution choice. This is planning only: no movement or new world implementation is claimed. Provisional tuning begins at lobby 22 / mountain normal 16 / sprint 23 studs per second, with shared climb stamina and explicit lock/input/animation/bank validation. Baseline and existing-code checks: [planning audit](design/movement-planning-audit-2026-10-22.md). The approved sequence remains movement, detailed hall plus sunny slice, rainforest, volcanic, snow.

## Active enclosed-lobby redesign interview — 2026-10-22

Written specification review PASSED: owner approved both sections 1–4 and 5–10 and requested a new chat for the actual build. Continue with scoped movement implementation planning; do not reopen design choices. This supersedes earlier pending-review snapshots below. No game implementation was performed in the interview chat.

Conversational design review passed. Owner requires cobblestone lobby walls, complementary floor, authored decorations, plants, trees and vines; arrival visual detail is an acceptance requirement. Read [the written four-mountain design](docs/superpowers/specs/2026-10-22-four-mountain-lobby-design.md), awaiting written review, before implementation planning. Earlier interview snapshots below are historical; `quad.md` and that specification contain the consolidated direction.

Interview continuation: mostly unique substantial creature collections per mountain; climbing/weather/guardian suspense; movement first, then lobby + sunny slice for review, then rainforest/volcanic/snow. Enchanted animated preview windows, essential services inside and home/showcase/practice side entrances, full biome-preserving weather/day-night changes. Camp/summit extraction returns unbanked cargo; save unfinished camps per mountain, reset that mountain after completed summit and return. Ascent targets: sunny/rainforest 15–20 min, volcanic 25–30, snow 35–45; unmeasured. Reuse existing mountain for sunny, author other mountains separately. Full decisions: `quad.md`. Written redesign specification and implementation remain pending.

Latest owner selections: sunny + rainforest start accessible, volcanic is medium, snow is final/hard with the rarest finds. Earned mountain unlocks combine summit and banked-collection milestones with visible progress. Owner explicitly selected paid permanent early access as an alternative, including access to rarer finds; this supersedes conflicting historical restrictions for this exact access model. Prices/requirements and platform setup remain undecided; no release action is authorized by the interview. See `quad.md`.

Owner selected volcanic as the fourth biome. Two beginner but suspenseful mountains start accessible; the medium and then hard mountains are earned, with the hardest containing the rarest creatures/Heartstones. Exact biome assignments and unlocking requirements remain open. Routes should have denser biome-appropriate life/trees and substantial elevation changes rather than empty flat walking. Players stay with their current lobby server population. Monetization must be considered throughout design; exact paid progression/access model is not yet selected. See `quad.md` for the active interview record.

Owner follow-up: mountain sprinting consumes the same stamina pool as climbing; lobby running is unlimited. Numerical movement and stamina tuning remain open. Latest interview decisions are maintained in `quad.md`.

Latest owner brief and decision record: [quad.md](quad.md). Selected movement: automatically faster in the lobby; slightly faster normal movement on mountains/routes plus a sprint toggle. This supersedes the historical fixed WalkSpeed 12 requirement for the redesign; exact values and stamina behavior remain open. Owner requests an enclosed circular high-ceiling lobby with four cardinal windows previewing distinct mountain destinations reached by teleport. Snow, rainy/scary rainforest and sunny environments are requested; the fourth is undecided. Architecture and delivery scope are still being interviewed, not implemented or release-approved.

## Approved redesign direction — 2026-10-22, implementation planning only

Owner-approved direction: a compact, colorful expedition fairground with core services approximately 5–8 seconds from spawn; close visual treatment to DUCK DUCK (TAG)'s chunky bright HUD using original mountain art; public/private portfolios and nearby clickable name/level/earned-title tags; daily free practice challenge; individual safe-peak cinematic with helicopter extraction and winner's banner. Summit extraction keeps cargo unbanked until the physical lobby bank. Build lobby first, then portfolio/HUD together. Numerical rewards remain provisional. See [the approved design](design/lobby-portfolio-summit-design-2026-10-22.md) and [implementation plans](docs/superpowers/plans/2026-10-22-expedition-redesign.md). The owner subsequently approved the implementation plan and requested a new-chat continuation; start at [the resume handoff](design/fairground-resume-handoff-2026-10-22.md), which links the saved prompt and project-local recording/screenshot. These features are not claimed implemented. Preserve mountain routes and personal homes, use a separate local review build, and retain existing publication/platform limitations.

## Approved Foothold Exchange override — 2026-10-22

The user approved local integration of [Foothold Exchange](design/cc-foothold-exchange/ROBLOX-INTEGRATION-PLAN.md), superseding the historical “monetization postponed/cosmetics only” restriction for these exact offers. The [implementation handoff](design/commerce-handoff-2026-10-22.md) records the local review build and remaining release tests. Six next-only total multipliers (2× through 12×) affect bank discovery coins and home income, with old-rate settlement before changes. Purchased coin packs never multiply. Summit Points stay earned-only. Camp Glow and individual cosmetics share canonical ownership; the 1,500-coin lamp is a separate decoration. Existing home costs, traversal, terrain and protected creatures remain preserved. External-pass limitations were accepted; listing/publication/purchase/release authorization was not granted. The V6P1 human-playtest/world-expansion boundary remains unchanged.

## Current product override — Expedition implementation, 2026-10-22

The user's [full implementation request](evidence/expedition_2026-10-22/request.txt) supersedes conflicting historical survival, commerce, extraction and incubation decisions below. Stamina is the only survival resource; shops/monetization are postponed. Shepherd and Waterfall launch; Ledge and Spire remain Coming Soon. Authored alternating holds, protected-climb harnesses, shared ropes, intentional camp-jump parachuting and physical camp shuttle/lockers form the expedition loop. Two manually occupied home nests use newly banked discovery progress, with deliberate hatching, limited earning spaces and capped offline income. The new Expedition interface and physical home management are integrated.

Current implementation and verification: [Expedition handoff](design/expedition-handoff-2026-10-22.md). This work preserves the existing world and protected creature project. V6P1 remains a first-draft Shepherd Camp1→2 world slice: further world expansion still requires the owner's human playtest approval. Automated checks do not grant that approval.

**Version:** 2.2 (V2 expedition redesign approved 2026-10-20; core loop §0.7 applied 2026-10-20) | **Status:** Implementation-authoritative for approved decisions; incomplete areas explicitly marked PROPOSED/TBD. Where §0.5 (V2) conflicts with older text below, §0.5 wins; superseded lines are marked.

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

**Mountain (PROPOSED):** ~4,000×4,000 studs, ~2,000 studs vertical. *(Built 2026-10-20: 4,800×4,800-stud map, playable mountain ≈3,400 studs across, summit at y=2,000.)* Camps: 1 Meadow Lodge (Green Valley), 2 Rootgate (Whispering Forest), 3 Chasm Hut (Broken Cliffs), 4 Stormwatch (Storm Ridge), then Frozen Summit; plus a hidden region (Glacier Caves / Sky Garden). Camps = respawn, campfire, Camp Locker (1–3 safe slots), social hub. *(2026-10-20, §0.7: Camps 1–4 become **tents**; lodges/huts/tower are archived, not deleted.)* Each push adds one new traversal verb. Hazards telegraphed (wind, whiteout, rockfall, avalanche).

**Creatures (PROPOSED):** rarity rises with altitude but every zone keeps commons, a hidden Rare and weather mutations. Eggs take 2 slots and hatch at base; creatures 1 slot. *(Superseded 2026-10-20 by §0.7: the egg is replaced by the **Heartstone**, 2 slots, ripens at base.)* Backpack 4 → ~12. First server-wide claim of a legendary earns a plaque/tag; no PvP. Summit: 3–5 summit-only legendaries.

**Extraction (PROPOSED):** one-way downhill only. ATV trails at low camps; helicopter from a ridge landing zone (~80% elevation) after a beacon is raised on the way up and a free regenerating **Flight Token** is spent; hold the zone 60–90 s while weather builds; storms ground it. Helicopter seats 4; Rescue Flare for stranded teammates. Arrival at the base pad auto-banks. Vehicle cargo strain risks only unbanked cargo. Tokens are never sold; monetization stays cosmetic (vehicle skins OK).

**Home base "Foothold" (name PROPOSED):** Expedition Hall, Gear Forge, Provisions Market, Garage, helicopter pad, terraced cabins with roaming habitats, Hatchery, campfire plaza, Hall of Wonders; summit-view plaza as the first-screenshot moment. *(2026-10-20, §0.7: Hatchery becomes the **Heartstone Hatchery** with crystal cradles; layout frozen.)*

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

## 0.6 V3 Ascent redesign (user interview 2026-10-20; plan APPROVED 2026-10-20, build in progress)

Plan, checklist and measurement methods: `design/v3-ascent-plan.md`. **Supersedes** the unbuilt P3–P5 of the traversal pass, the "Mountain (PROPOSED)" 2,000-stud summit in §0.5, and "No easy lines" (the easy route is forgiving by design). P1/P2 verbs and measurements are re-done on the new terrain.

**LOCKED (user choices):** keep Ring Mountain + 5 regions with a unique summit crown (buttresses, fins, arch or notch) and taller massifs · dry foothills band under Green Valley where Foothold sits, then valley → forest → cliffs → ridge → snow/ice · summit **~3,200** · **4 routes** (Shepherd's Road easy, Waterfall Stair moderate, Cliff Ledge Line hard, hanging off the mountainside, Spire Ridge expert), fixed intensity per route plus rising exposure with altitude · routes separate at base, cross at the shared camps, merge near the summit · every route 25–30 min skilled (first-time ~60 min measured on the easy route) · fall/hit = stagger + fall-loss of unbanked cargo only, no HP damage · checkpoints = 4 camps + a mini-checkpoint ~every 4 min per route · hazards: falling trees, rockfall, wind gusts, avalanche chutes (crumbling ledges not chosen), telegraphed and fair, punishment scales by route · Foothold ~3× area, open plaza, 4 route gates, Route Board, summit-view amphitheater spawn, landmark tower/waterfall mill, cable-car station · mobile-first: best performance and quality on mobile · guaranteed introductory Rare on the first stretch of the easy route, beginner protection on every route.

**PROPOSED:** map footprint ~5,600²; camps at ~15/32/50/70/100% of height; cable car decorative only; mobile budget 30 FPS floor on a mid-range phone, 60 desktop; per-route times/lengths and hazard counts in the plan; dry-foothill palette needs a reference (none exists, will ask).

**Build status (run of 2026-10-20 afternoon; everything is a FIRST DRAFT, awaiting user review; the P1/P4a approval stops were overridden for this run only, replaced by written self-reviews):**
- **P0 DONE:** checkpoint `PreV3_2026-10-20` + file `ClimbAndCollect.PreV3.rbxl`; baseline numbers in `CLAUDE.md`.
- **P1 DONE (first draft):** 5,600-stud map, summit crown highest point **3,248.5 (VERIFIED, raycast)**, twin horns + notch, 3 basalt fins, 4 buttress arêtes, Crown Gate arch, satellite massifs; biome bands by altitude incl. dry foothills. Camps at 16/33/52/70 % of height (VERIFIED). Dry-foothill colors PROPOSED from the interview words only (`design/world-tokens.md`). Self-review and evidence: `design/v3-morning-report.md`, `evidence/v3_P1/`.
- *(Route form superseded 2026-10-20 by §0.8: hard/moderate routes follow the rock's natural line, not stamped trails.)* **P2 DONE (data + stamped trails):** 4 routes + shared summit stair; walk lengths incl. stair Shepherd 19,130 / Waterfall 12,919 / Ledge 12,762 / Spire 11,411 studs (GEN, VERIFIED as data); skilled times 28.6 / 25.9 / 28.7 / 28.8 min are ESTIMATES (walk ÷ 12 + PROPOSED obstacle minutes not yet built for the last three).
- **P3 DONE (first draft):** Foothold v3 (amphitheater spawn, plaza, Route Board, 4 gates, tower, decorative cable car, all districts, 9 cabins).
- **P4a + P5 DONE for Shepherd's Road only (first draft):** camps, bridge, fences, lanterns, checkpoints, 4 hazards, summit stair ramps; runtime checkpoint/fall-respawn + client hazards. **VERIFIED in Studio:** bot reached the summit trigger (2 stuck spots logged), forced fall respawned at Camp 1, hazards hit only after their 3 s tells. Not built: P4b–d, P6 (vegetation, mobile emulation), P7.
- PROPOSED changes made during the run: map footprint 5,600 (as planned); Foothold pad moved to re 2,370 so the summit horn clears the valley lip from spawn; falls now drop off the Green Valley lip into a foothill gorge (lip 402 → pool 104); route identity colors = existing tokens (Shepherd meadow, Waterfall turquoise, Ledge sandstone, Spire ice) + 1–4 intensity pips.

**Conflicts flagged:** forgiving early segments vs scary hard routes (resolved by route-based intensity), guaranteed Rare placement (resolved), 25–30 min band on a taller mountain (measured in plan phase P2 before building), Green Valley "lowest elevation base" (foothills now below it, §4 text superseded where it conflicts). §8's "guided ascent into the forest" for the first Rare is replaced by the easy route's first stretch.

## 0.7 Core loop (user interview 2026-10-20, LOCKED; applied to this file in Run 1 phase A0)

Sources: `design/core-loop-plan.md` (LOCKED answers, conflicts resolved), `design/autonomous-build-brief.md` (§1 scope LOCKED, §3 defaults PROPOSED), `design/decision-log.md`. Where this section conflicts with §0.5/§0.6 text, this section wins; superseded lines are marked in place, nothing LOCKED was deleted.

**LOCKED (user):**
- **Loop:** climb → discover (commons, hidden Rares, nests) → hold-claim or net → take a Heartstone from a guarded per-player nest → guardians chase and escalate → bank at the Foothold (the only place finds become permanent) → Heartstone ripens in real time → creature joins a habitat and yields Cairn Coins → upgrades → repeat via weather mutations, legendary events, daily goal.
- **Heartstone replaces the egg:** aurora-crystal core from a guarded nest, 2 carry slots, glows (others see cargo value), ripens at base in real time (Common 5 min, Rare 30 min, Legendary 4 h); the weather where it was taken sets its mutation. Ripening is server timestamps on the profile, computed on load, works offline. Hatchery → Heartstone Hatchery (crystal cradles), layout frozen.
- **Net:** second claim verb beside hold-to-claim, guardian pups only. 3 tiers (cloth free; rope for Cairn Coins at level 4; aurora-thread from a Region 3 pup) set throw range and interaction time, never guardian power. One pup per guardian per cooldown.
- **Camps become tents** (Camps 1–4), visually distinct, realistic-but-unique: respawn, stamina refill, Camp Locker (1–3 slots), social hub, per-tent upgrades (locker 1→3, refill speed, a **small** guardian-free radius; no other effect). Lodges/huts/tower archived, not deleted. Foothold + 4 gates stay as built. Camps are guardian-free; hide spots on routes break line of sight.
- **Guardians:** Mountain Guardians, 1–2 species per region, random traits per encounter (speed, senses, size, weakness), scarier by region/altitude and by nest value. A hit staggers and shakes one unbanked item into the 3-min recoverable drop pack. **Gentle Green Valley:** Region 1 guardians and intro nooks slow, short-sensed, no item shake until the first bank; scaling starts above Camp 1.
- **Nests:** 2–3 per region, per-player instanced, ~10 min respawn. Legendaries stay server-wide first-claim; no PvP, no player theft.
- **Speed:** WalkSpeed stays 12; progression = stamina capacity and recovery (soft caps). **LOCKED #5 amended:** backpack slots come from levels (L2–7 +1 each) and two major codex milestones (+1 each); total 4→12. Levels 8–9 are stamina only. Heartstone 2 slots, start stays 4 slots; the tutorial Rare is a normal 1-slot creature.
- **Tycoon:** Cairn Coins (sources: habitat yield, banking, daily goal, milestones). Yield/h Common 1 / Uncommon 3 / Rare 10 / Epic 35 / Legendary 150; duplicate 25% (full milestone credit); mutation +50%; 8 h offline cap; 2× collect bonus within 1 h (reward only). 4 habitats × 6 slots (start 1 × 3). Currency buys habitat slots, cabin, tent upgrades, cosmetics, decorations; never creatures or Heartstones.
- **Resume** at the highest reached camp; the full ascent remains the loop (no short-run mode). Getting home: ATV from low camps, helicopter from the ridge LZ, walking down is free.
- **Rarity:** 5 tiers; card border shape + 1–5 pips carry rarity, colour secondary; only Legendary gets a world beam. 8 species per region × 5 = 40 (+3 weather-linked Legendaries = 43, split PROPOSED); 8 Legendaries; 6 weathers = 6 mutations.
- **Onboarding:** diegetic guided run with a companion and short prompts, skippable on return; guardian-free Rare nook on Shepherd's Road by minute 5; cliffhanger ~min 10 (ripen timer + a rare guardian's silhouette higher up).
- **Out of scope v1:** monetization (deferred), PvP/theft, co-op raids, leaderboards, Training Yard (later annex), routes redesign (separate track, `design/v4-climb-concept.md`; now §0.8).

**Build split:** creatures (Phase C) are built by Codex in a separate chat; species are referenced only by snake_case id through one species table; the server owns rarity, yield and mutation.

**Run 1 status (A0 + A1 + B, unattended, authorized 2026-10-20):** see `design/core-run-report.md` and the `CLAUDE.md` evidence log. Real DataStore behavior is **UNVERIFIED** (place unpublished, `PlaceId = 0`); persistence is tested through an in-memory store adapter.
- **A0 DONE:** checkpoint + file copy, baseline (desktop Play Solo: 60 FPS vsync, worst 17.9 ms, 2,581 World instances streamed at spawn), this section.
- **A1 DONE on the mock store (VERIFIED in Studio, mock only):** server-authoritative profile v1 (brief §3.9 + logged extensions), session lock, autosave/retry/release/shutdown, idempotent bank, Heartstone ripening from server timestamps (works offline), safe "saving paused" message; 12/12 scripted tests + live checks; adversarial review fixed 12 defects (`evidence/core_P1/`).
- **B (Green Valley core loop) — built, first draft (PROPOSED placements, stub creature visuals pending Codex):** hold-claim (server-validated holds), backpack (4 slots, Heartstone 2), bank at the plaza campfire, Rare nook up a short fixed rope on Shepherd's Road, tutorial "hollow" nest (cloth net on the pup, Heartstone, gentle guardian with tell / chase / hide-spot line-of-sight / leash), drop pack (3 min, owner-only), fall loss after the first bank, tent safe zones + Camp Locker (camps still look like lodges; tent reskin not built), resume at the highest camp, 9-beat onboarding with companion wisp, objective marker and cliffhanger. Measured (Studio desktop Play Solo, BOT = perfect input): full onboarding **4:48 BOT**, guaranteed Rare at **2:06 BOT** (LOCKED ≤ 5:00), 0 stuck/0 hits on the timing run, 20/20 clean bot runs; 10/10 scripted-client checks (no item shake before the first bank, drop pack recoverable for 3 min, fall loss, locker, resume, full bag, disconnect); 60 FPS (vsync) with worst frame 20.2 ms near the nest. **Human time UNMEASURED** (at bot pace the onboarding is about half the ~10-min target). An adversarial review fixed 15 findings (incl. reset-as-teleport-home and teleport-banking). Details: `CLAUDE.md` B row, `evidence/core_P2/`, `design/core-run-report.md`.

- **Stage 3–4 (2026-10-20, PROPOSED changes, measured in Studio desktop only):** load-time fix (checkpoints out of the place: Play → playable 19.9 → ~6 s, file 85 → 18 MB); B-polish: tutorial ends at L2, tutorial Rare protected until banked once, outskirts claim + bank beats (BOT 6:09, Rare 2:06), lip nest reachable on foot (two timber stairs), cliffhanger auto-FOV, live-server dev-tool strip. A1 12/12, B checks 12/12, 5-spot perf pass 60 FPS / 0 frames > 33 ms. Phone and human times UNVERIFIED. See `evidence/perf_P1/perf_after.md`, `evidence/core_P2/B_test_log.md` §8.

## 0.8 v4 Routes and climbing (concept + plan APPROVED 2026-10-20; applied in Stage 5)

Sources: `design/v4-climb-concept.md` (LOCKED #1-19), `design/v4-plan.md` (interview answers 1-8, approved for P0-P2), `design/references-intel.md`. Where this section conflicts with §0.6 or §3, this section wins; superseded lines are marked in place.

**LOCKED (user):**
- **Route form:** the hard and moderate routes follow the rock's natural line (faces, ledges, ropes, ladders, knife-ridge crests), not wide stamped trails. Hard routes = a mix of knife-ridge crests, ladders over grooves/crevasses and rope-guided steep slopes. Hands-on share: Shepherd ~25 % ("gentle but alive": rope scrambles, railed ledges, one real view-down moment), Ledge/Spire ~75 %. 25-30 min skilled per route stays. Descent on Ledge/Spire = the same line back down. Shepherd keeps tutorial beats 4-5 and the Rare nook where they are. Avalanche chutes = timed crossing between two safe ledges. Waterfall Stair = stairs/ladders beside the falls, wet-rock ledges, one rope-slope crossing. Foothold + 4 gates stay as built.
- **Climb state:** custom climb on **marked climbable faces** with **stamina** (resolves §2's "stamina vs no stamina": stamina, yes). Mobile: stick + **auto-grab** when pushed into a marked face + **Jump = lunge**; optional release only. Out of stamina or a slip = slide with a **catch window**; a missed catch = drop to the **last checkpoint** (decision 8 unchanged), no HP damage, unbanked cargo follows the locked loss rule. Players pass through each other on faces and marked ledges. Camera auto-frames the drop while climbing; the player can override. Rest ledges refill stamina fast.
- **Guidance, 3 layers:** (a) glowing flags/cairns at every turn, always on; (b) a Guide button that pulses a mote trail to the next marker; (c) HUD objective arrow to the next camp. No continuous glowing line by default.
- **Oxygen:** an optional **canister consumable, no oxygen meter** (the V2 "no oxygen meter" approval holds).
- **Equipment + shop:** a small earned kit plus a K2-style gear shop (cosmetic helmets, outfits, goggles) as a UI on the existing Market/Forge; currency and prices OPEN.
- **Training Yard:** stamina training minigame as a **new annex outside the frozen Foothold**, later (P4), capped gains.
- **Weather:** dynamic day/night + weather with mobile quality tiers, **only after a measured mobile cost test**; the prototype uses **static** fog + light shafts + a cloud layer.
- **Order:** performance (Stages 3-4) before any v4 build; P1 = Cliff Ledge Line first section at hero quality; P2 = tune, then one Shepherd section; P3+ needs new approval.

**PROPOSED (details, `v4-climb-concept.md` §3):** controller on authored rock-face assemblies tagged climbable; stamina ~25-35 s of continuous climbing per bar, refill ~5-8 s on a ledge; catch window ~1.5-2 s; drops under ~15 studs onto a ledge = stagger only; camera via `Humanoid.CameraOffset` + FOV tween (no custom camera module); kit = ice axe, crampons, headlamp, oxygen canister.

**Build status (2026-10-21, first drafts, awaiting your review; P3 not started):**
- **P0 DONE:** checkpoint `PreV4_2026-10-20` + `ClimbAndCollect.PreV4.rbxl`.
- **P1 DONE (first draft):** Cliff Ledge Line first section (`LedgeP1`) + climb controller (`CC_ClimbClient`). BOT: Ledge gate → exit 80.5 s; 20/20 scripted runs clean; keyboard and Device-Simulator touch verified; slip/catch/miss/respawn verified; no walking/jumping bypass found; emulation 60 FPS. Two-client test and human feel UNVERIFIED. `evidence/v4_P1/P1_report.md`.
- **P2 DONE (first draft):** P1 cliff repainted to rock; one Shepherd "gentle but alive" stretch (railed ledge, roped scramble, lookout view-down) at s≈1390–1500, tutorial untouched. Tutorial 6:07.6 BOT (Rare 2:06.5), B checks 12/12, A1 12/12, perf 60 FPS everywhere (desktop). `evidence/v4_P2/P2_report.md`.
- **P3 FIRST DRAFT, run 2 STOPPED at the instance cap (2026-10-21):** pitch stacks (marked rock faces, tier ledges, ladders, crossings, rockfall chutes, lunge bands, rests) on every steep band of Ledge, Spire and Waterfall, plus one Ledge "hang line" below its own lane (user choice; a walkable detour around it remains). All 11 lines pass BOT; route totals ~25–28 min ESTIMATE; **hands-on 32–43 %, below the ~75 % LOCKED target**; Shepherd rework not done beyond P2. Streamed instances +31–76 % over Stage 4 → hard stop; P4 systems (gear shop with Cairn Coins + Summit Points, kit, oxygen canister without meter, rescue + party ropes, Training Yard annex, day/night + weather tiers) are coded but untested. `evidence/v4_P3_report.md`.

## 0.9 v5 Trails and mountain (interview 2026-10-21; plan APPROVED 2026-10-21, build order Trails → Mountain look + fog → Jackpot; P0 safety + baseline done, `evidence/v5_P0/P0_report.md`)

Plan: `design/v5-trails-and-mountain-plan.md`. LOCKED: natural spline trails (~85 % tight 2-5 studs, ~15 % open), 4 routes with distinct signatures, 25-30 min skilled, same fall rules everywhere, sparse fair hazards, co-op pull-up + pings, rope-descent shortcuts, single crown with arch notch + waterfall + caves/ruins, heavy mid-mountain fog breaking above a cloud sea in the last ~8 % of height, rare-nest jackpot with 5 tiers (top tier renamed Mythic). Foothold + gates and tutorial pieces stay; camps may shift. Supersedes the v4 route-form details only where they conflict.

**Round 3 (2026-10-21, awaiting approval, nothing built):** feature sections (Core 8 + cloud-sea dome; 6-7 set pieces per route; table in `design/v5-trails-and-mountain-plan.md`); pre-built fixed ladders/ropes; stamina rests ~4 min; mobile-tiered effects; **references-only colour supersedes §1 Enchanted Adventure (user-confirmed, §1 text not yet edited)**; day/night cycle phased into P7, per-player clock.

**v6 trails (2026-10-21/22, user popup):** v5 P1 contour ledges rejected as flat. Trails are now beat chains (vertical pieces between near-level ledges, real cliff exposure, enforced obstacles from terrain). LOCKED: Shepherd ~35 % / Waterfall ~55 % hands-on, short jump gaps over real drops, fall cost scales with height, first slice Shepherd Camp 1 -> Camp 2. **Slice built (first draft), STOPPED for playtest:** 257 s BOT, hands-on 12-26 % (below target), tutorial regression on leg 1 OPEN. `design/v6-trails-plan.md`.

**UI round (2026-10-21, awaiting approval, nothing built):** `design/v5-ui-plan.md`. Boards (user-supplied Pinterest, user-confirmed) drive popups/reveals; HUD layout from K2 clips; ornament-led rarity; tiered reveals; landscape phone-first. OPEN: R1 shop/gear/Points/O2 UI kept against Round 3 exclusions, typeface, colour mix.

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
- **Claiming:** Approach and **hold** to claim; no stealing and no conventional PvP. *(2026-10-20, user-locked addition, §0.7: the **net** is a second claim verb, guardian pups only.)*
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

**OPEN — get decisions only if identity-changing, otherwise apply reasoned defaults:** Exact species roster, rarity thresholds/drop/spawn rates, event cadence, rescue rules, stamina vs no stamina *(decided 2026-10-20, §0.8: stamina)*, fall severity and protection values, bank placement/return flow, currency/economy balance, monetization expansion, cabin modules, precise first-10-min pacing, persistent progression thresholds, seasonal roadmap. For any such defaults, record rationale and proposed status; do not assert LOCKED.

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
- Every major trail should have authored shoulders, landmarks, plants, rocks, signs/wayfinding, ambient motion and a reason to stop and look. *(Scoped 2026-10-20 by §0.8: shoulders and signs apply to the easy route and camps; hard routes are marked by world cues — ropes, pitons, cairns, lanterns, glowing flags — on the rock's natural line.)*
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
- Weather meaningfully changes visibility, safe routes, traversal and mutation discoveries *(§0.8: static atmosphere first; dynamic day/night + weather only after a measured mobile cost test, with quality tiers)*. Telegraphed, readable hazards, modest audiovisual effects scaling, no sudden undodgeable loss.
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

## Private playtest status — 2026-10-22

**VERIFIED publication:** the Fairground polish review build was published to a new private, phone-enabled Climb & Collect test experience (PlaceId `134979185642785`). The verified source, strip, terrain check, access scope, and outstanding device/live-save checks are recorded in `design/phone-playtest-publish-2026-10-22.md`. This is a review milestone, not full release acceptance. The first human phone run and live save/rejoin test are next.

## Mountain Empire Step 1 — 2026-10-24
The new approved design/phase1-multiplayer-environment.md governs the separate redesign. Step1 spatial blockout is saved for review, not final art:8 plots110x120, buffers8, rear lodge footprints35x30, centered gates45/60/45, terrace+16. Evidence, checkpoints, travel-distance tradeoff and capacity/device limitations: design/mountain-empire-step1-review.md. STOP before detailed architecture, landscaping, gameplay or publishing.


## Mountain Empire size amendment — 2026-10-24
Owner selected180x220 plots and60 studs of front walking space, superseding earlier110x120 footprints for the new revision. Eight plots now total1496 frontage with8-stud buffers. Verified revision saved separately; design/mountain-empire-step1-revision2.md records evidence and longer outer-plot travel. Still blockout only.



## Mountain Empire Step 2 — lodge review, 2026-10-24
Eight Enchanted Alpine lodge exteriors now occupy the approved rear 35 × 30 footprints. Enlarged plots, buffers, front walking space, gates and ramps remain intact. Timber/stone/glass, layered teal roofs, brass details and restrained magical entrance accents are built for visual review. Verification and saved artifacts: design/mountain-empire-step2-review.md. Step2 is complete for review, not owner-approved art or full Phase1 acceptance. STOP; no next phase, gameplay or publishing.

## Mountain Empire Step 3 — environment review, 2026-10-24
Owner visually accepted Step2's eight lodges and authorized this controlled environment pass. Natural buffer boundaries, planted retaining terraces, pines/rocks/flowers/lanterns, static waterfall accents, detailed three gates and a sculpted Alpine vista are saved separately. Enlarged plots, lodges and access remain unchanged. Evidence and exact checkpoint: design/mountain-empire-step3-review.md. Step3 awaits visual approval; STOP. No gameplay, progression, facilities or publishing added.


## Impossible Mountain autonomous build — 2026-10-24
New six-kingdom design is being implemented in an isolated worktree/branch; Phase1 remains unchanged. Verified rules, memory-store tests, natural Blossom ascent and Floravelle normal/Trial victories: [build record](design/mountain-empire-six-kingdom-build-2026-10-24.md). Full mountain traversal and final saved-artifact acceptance are still pending; do not claim production readiness.


## Impossible Mountain saved milestone — 2026-10-24
The isolated six-kingdom review is saved, source-audited, closed/reopened and startup-tested. All six normal gates and summit were earned through natural movement, with one preserved Violet landing failure and repair. Final tests: 120 rules checks, 50 Studio memory/snapshot checks, earned egg extraction/incubation/free phone hatch, and 294 saved-route footing samples. All 30 protected place files remain unchanged. This is a playable systems milestone, not acceptance of premium art or 75% production readiness. Final report, artifact location, evidence and remaining work: `design/mountain-empire-six-kingdom-build-2026-10-24.md`. Code remains in the attached feature/six-kingdom-mountain-first-draft worktree; no merge/push/publication.

2026-10-24 art/motion milestone: isolated continuation worktree has ArtPassVerified.rbxlx; 18 matching sources, exact terrain, 726 colliders/107 prompts/30 protected files preserved, six Guardian motion checks pass. See design/mountain-empire-six-kingdom-build-2026-10-24.md and continuation mountain/ART-PASS.md. Premium art and broader acceptance remain open; worktree code is outside graph coverage.

2026-10-24 Mountain environment Review10 checkpoint: see design/mountain-empire-six-kingdom-build-2026-10-24.md for preserved terrain experiment, twelve branch rewards, actual Azure rope, and unresolved platform/premium-art scope. No publication or integration.

2026-10-24 Mountain Review16 art study saved/reopened: original 726 collider records/107 prompts/30 protected files retained, 96 intentional support facets added, 28 sources checked. Fresh Blossom arrival and resumed garden footing/combat-boundary/return checks recorded; original-column approach failure retained. Premium art and Astral platform landing remain incomplete. Evidence and exact scope: design/mountain-empire-six-kingdom-build-2026-10-24.md and continuation mountain/ENVIRONMENT-PASS.md. Graph coverage remains original project/vault only.

2026-10-24 Mountain latest art checkpoint: Review19 saved/reopened (SHA06ac761d), 30 matching sources, 48 compile /120 rules /131 traversal, 54 support and231 boundary samples. Exact Strata15 terrain restored after a retained unexpected-save drift; original726 collider records/107 prompts/30 files preserved plus96 explicit supports. Evidence: design/mountain-empire-six-kingdom-build-2026-10-24.md. Premium art and Astral/platform acceptance remain incomplete; no publication or integration.

- 2026-10-24: Mountain continuation Review32 saved/reopened, all6 platform loops + normal wins + summit verified across interrupted solo runs;150ms Astral/Violet repeats pass. Exact scope, preserved failures and hashes: design/mountain-empire-six-kingdom-build-2026-10-24.md and continuation mountain/ENVIRONMENT-PASS.md. Premium art still unresolved; Shoulder29 is intended terrain authority. No Phase1/lobby changes or publishing.


## Guardian asset production — 2026-10-25
Approved production started; actual Veylith Blender/rig/baked-color/FBX/GLB technical trials saved, but the visual benchmark failed after refinement. No finished Guardian pair accepted and no gameplay/Studio-place changes. Specialist-quality route recommended before expanding to other five. Evidence, owner and exact limitations: [production record](design/guardian-production-2026-10-25.md).

2026-10-25 Guardian AI-first trial: actual generated eagle mesh refined in Blender; technical export/reimport verified, premium art benchmark still failed. Owner requires AI-base exploration before artist. Evidence and tool/access limitations: design/guardian-production-2026-10-25.md. No gameplay, balance or acquisition changes.


## HUD review verified — 2026-10-25
Playful & Bold HUD completion review is baked/reopened with preserved world, 1,316 CLI checks and four-device simulator evidence. Source/action/Q1–Q28 details and explicit service/hardware blockers: `design/hud-completion-2026-10-25.md`. Durable implementation lives at `C:/Users/HOME!/Documents/ClimbCollect-HUD-2026-10-25`, not Desktop src; graph excludes that source.


2026-10-25 Guardian v012 continuation: actual feather/face refinement, bone-only wing fold/unfold and a distinct adult folded-rest source are saved and freshly GLB-reimport verified. Each167 meshes/349,936 triangles/31 bones/six independent prisms; source weights/finite/manifold checks pass. Earlier generated torso replaced. Runtime topology/bakes, feather/fold-clearance polish, full clips, scale and Roblox/device acceptance remain open. No finished premium/runtime pair claimed. Exact evidence: `design/guardian-production-2026-10-25.md`; external `Documents/ClimbCollect-GuardianProduction/2026-10-25/veylith-blender-refinement/v012-reopen-roundtrip.json` and `v012-review.html`. No generation retry, paid tool, Studio edit or publication.


- 2026-10-25 Guardian roster v004: owner authorized batch production of all five remaining Guardians, superseding Veylith-first sequencing only. Ten actual boss/adult source forms are now authored and freshly Blender/GLB verified (1,112 meshes/554,920 source triangles/230 bones; max2 normalized influences). Still early SOURCE WIP, premium/runtime acceptance open. Current regular catalog36 + Guardians6 differs from historical43, whose Blender/GLB folders already exist; preserve/reconcile, do not blindly rebuild. Evidence: design/guardian-production-2026-10-25.md; external Documents/ClimbCollect-GuardianProduction/2026-10-25/roster-production/guardian-roster-v004-review.html and creature-roster-inventory.json.


- 2026-10-25 Guardian roster v008: refined all five boss/adult pairs with sculpted faces/anatomy, swept ornaments, hewn golem volumes and curved flame wings. Fresh ten-source/GLB/combined checks pass (1,240 meshes/1,010,132 source triangles/230 bones); targeted wing-tip isolation and otter portable color checks pass. Still source WIP below boards, not runtime-ready; full art/motion/topology/bakes/scale/clearance/Roblox/device gates open. Evidence and corrected assumptions: design/guardian-production-2026-10-25.md; external Documents/ClimbCollect-GuardianProduction/2026-10-25/roster-production/guardian-roster-v008-review.html. v004 hashes unchanged.
