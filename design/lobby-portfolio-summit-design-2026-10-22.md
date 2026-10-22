# Expedition Fairground, Player Portfolio, and Summit Finale

Date: 2026-10-22. Status: design direction and detailed implementation plan approved by the owner in this chat; implementation has not started. Numerical reward balancing remains provisional. The saved new-chat continuation prompt specifies native implementation and a final independent review. Resume from [the handoff](fairground-resume-handoff-2026-10-22.md).

## 1. Purpose and decision status

Create an exciting, colorful, compact social home for CLIMB & COLLECT, with clear shopping opportunities, visible player achievement, and a summit finale worth pursuing. Landscape phones lead the design, followed by desktop and gamepad.

The three interview rounds in this chat establish the owner-selected requirements below. Dimensions, layouts, art details, module boundaries, reward values, and milestone thresholds explicitly called proposals are design recommendations awaiting review. This document is a design brief and phased delivery outline, not an executable implementation plan.

Owner-selected delivery order: rebuild the lobby first, then deliver the portfolio and HUD together. The summit finale is a connected subsystem to deliver after those foundations. Work in a separate local review place, replacing the central Foothold while preserving mountain routes, personal-home systems, and protected creature assets. Publication, product listings, live purchases, and spending are outside this work.

## 2. Reference analysis and its limits

Inputs: the supplied DUCK DUCK (TAG) screen recording, approximately 61 seconds, and portfolio screenshot, now preserved in [the project-local reference package](../references/duck-duck-tag-2026-10-22/README.md). Visual review used frames sampled every three seconds; audio was not evaluated. Timestamps below are approximate.

| Reference observation | Design implication |
| --- | --- |
| Opening 0–9 seconds: players occupy an open central court; rewards, shops, and leaderboards face inward around its edge. | Concentrate useful services around a shared gathering space; make destinations visible without a long walk. |
| Buildings, oversized props, seasonal dressing, and a mushroom kiosk frame the court. | Use memorable silhouettes and a contained composition, with an open movement center. |
| Bright icons, thick contrasting borders, prominent numbers, and colored categories repeat across menus. | Build one recognizable illustrated interface system with strong hierarchy. |
| Around 15–21 seconds: daily, weekly, and achievement panels show tasks and rewards. | Make the daily practice challenge and earned cosmetic progress understandable. |
| Around 24–39 seconds: customization gives the character a large preview; empty categories lead toward shopping. | Show the player what a cosmetic changes before presenting its offer. |
| Around 45–56 seconds: featured goods, passes, currency packs, and item categories are connected. | Preserve the existing Exchange catalogue while improving discovery and previewing. |
| Final seconds and screenshot: avatar, identity, level/XP, three headline stats, and equipped items form a profile card. | Give players an immediate achievement summary and a recognizable personal showcase. |

The recording does not establish actual conversion rates, measured lobby dimensions, complete spawn behavior, or retention effects. Compactness and monetization effectiveness remain hypotheses to validate in our game. Use original mountain art, names, shapes, and assets within the requested closely related visual treatment.

## 3. Selected direction and alternatives

Recommended: an expedition fairground surrounding a compact court, with the mountain ahead, an Exchange beside the natural circulation path, and a visible practice circuit on the outer edge. It supports the selected energy and shopping goals without extending mandatory service walks.

Alternative: an alpine village offers stronger expedition atmosphere but less of the selected fairground energy. Alternative: a creature sanctuary emphasizes collections but makes the practice and expedition theme less immediate. The owner's fairground selection is the direction developed here.

## 4. Lobby layout

Requirements: main services approximately 5–8 seconds' walking distance from spawn; direct physical mountain connection; mountain and climb entrance visible immediately. Banking, Exchange, home access, collection showcase, and route information occupy the central area. Practice is nearby and visible, with optional exploration beyond.

Proposed arrangement, oriented from the spawn camera:

```text
                    MOUNTAIN / EXISTING ROUTES
                        Clear climb approach
                    Route information / gates

      PRACTICE CIRCUIT                         EXCHANGE
      daily challenge                         cosmetic previews
      visible start                           featured set

      COLLECTION       OPEN SOCIAL COURT      BANK / RETURN
      player showcases                        helicopter return

                     SPAWN / MOUNTAIN VIEW
                       Nearby home entrance
```

This diagram expresses adjacency, not a final footprint. Final coordinates require Studio measurements of the existing terrain, route entries, bank interaction, spawn camera, and home-door contracts. At the documented baseline walking speed of 12 studs/second, 5–8 seconds corresponds to roughly 60–96 studs of actual path travel. Re-measure actual speed and routes before accepting those distances; the radius alone is not proof.

Keep the center open for a 30-player server, companions, and camera movement. Favor a shallow branching loop over corridors or queues. Provide clear pedestrian access around all displays. The return pad sits beside banking with a safe, unobstructed arrival position, outside the spawn crowd.

Art proposal: warm orange/gold expedition structures, saturated turquoise route accents, purple creature/crystal highlights, colorful pennants, oversized climbing equipment, and restrained animated attractions. Preserve mountain silhouette visibility. Motion emphasizes selected landmarks, not every prop. Reduced-motion settings substitute static states. Do not use generic repetitive scatter as finished dressing.

## 5. Practice and daily activity

Owner selected a compact multi-stage climbing circuit with optional timed runs, visible from the court, and a rotating daily challenge progressing toward an earned cosmetic milestone. No paid entry.

Proposal: use a nearby compact folded route with distinct traversal stages and a start/finish area visible to spectators. Keep the full activity outside the mandatory service loop. Reuse the existing training system's completion rules rather than create a second inconsistent tutorial.

Daily rotation proposal: a deterministic challenge from a finite tested pool, changing at 00:00 UTC with a visible reset time. One milestone stamp per account per day; replay remains available for practice. Seven stamps award one practice cosmetic, with no consecutive-day requirement or missed-day reset. Server validates ordered stages and elapsed time; optional records award no repeat economic benefit. These schedule and milestone values are proposals.

## 6. Monetization and player flow

Retain the approved Exchange multipliers, exact coin packs, and cosmetics. Put previewable merchandise near natural stops: preparing to climb, returning to bank, and viewing player showcases. The compact Exchange offers visible product examples and clear details. One Shop HUD entry plus at most one contextual offer is visible; paid promotion is reduced during climbing. No store overlays during the summit cinematic or winner's banner.

New concept: a permanent Expedition Starter cosmetic set. Proposed contents: a coordinated expedition pennant, lantern casing, and overhead name-tag frame. Reuse the existing cosmetic ownership/equip model where possible. The frame is decorative; level and earned rank remain readable and unchanged in meaning. It grants no species completion credit, summit count, rank qualification, or Summit Points. Review contents, overlap with Camp Glow, partial ownership behavior, and price before implementation.

Only show countdowns for genuine scheduled events or offers. Do not invent scarcity for a permanent set. Preserve dynamic platform prices and confirmed-grant purchase handling. All existing zero product IDs remain disabled in local review. Real listing and price setup require separate launch work.

Success signals proposal: time to first climb, service travel time, relevant preview opens, shop opens from previews, and successful return-to-bank flow. In a future authorized live test, compare conversion and early-session exits together. No revenue claim follows from this reference analysis.

## 7. HUD visual system

Owner selected a close visual treatment to the reference: chunky panels, bright colors, oversized icons. Use original expedition artwork with thick light outlines, dark contrasting text outlines, bold legible display typography, and generous touch spacing.

Proposed layout: top contains compact progression, stamina, altitude, and cargo status; a short side rail exposes Profile, Collection/Expedition, and Shop. Maintain native Roblox top-bar safe space and existing movement/jump/traversal areas. Tutorial guidance, uncertain-save status, and actionable safety information outrank contextual offers. Preserve the existing settings and input contracts.

Menus share a strong frame, clear header, persistent close action, and scrolling content. Keep primary targets at least the existing 48–50-pixel menu standard where feasible; test shortest supported landscape phones and largest text. Avoid uniformly shrinking the interface to fit. Reuse the existing prioritized notice queue. Gamepad focus must reach every action and return predictably after closing.

## 8. Name tags and portfolio

Every player has an overhead tag containing display name, a level badge, and one equipped earned achievement title. Titles derive from summit and collection milestones; level is independent. Paid frames never imply earned achievement.

Tags appear for nearby on-screen players, become smaller at medium range, and disappear behind solid obstacles. Proposal: full detail within 25 studs, simplified noninteractive detail from 25–60 studs, hidden beyond 60 studs. The player's own tag can be locally suppressed to avoid camera obstruction; the Profile button remains available. Specific ranges and self-tag presentation are review proposals.

Tap/click within approximately 25 studs in the lobby or designated safe camps opens that player's public portfolio without a camera takeover. A focused gamepad interaction offers the same action. Tags must not compete with traversal prompts. Prioritize the nearest/focused tag in a crowd and keep its hit area usable on phones. Server rechecks subject presence, range, and safe-zone eligibility before returning a public snapshot. Return a clear unavailable state if the player leaves.

Public card:

- Identity: avatar, display name, username, level/XP, equipped earned title.
- Headline: lifetime summits reached, unique species permanently collected, current collection completion.
- Rarity: unique permanently collected species and obtainable total for Common, Uncommon, Rare, Epic, Legendary.
- Showcase: equipped companion, three owner-selected creatures, and equipped cosmetics.
- Successful records: summits by route and earned milestones.

The dedicated Profile HUD button opens the owner's card with an additional Details tab and a link into Collection. Details may show successful route records, collection/mutation progress, lifetime banked totals, title criteria, and milestone progress. Falls, lost cargo, and unsuccessful outcomes are omitted from portfolio views. Existing internal gameplay records need not be erased.

Count a species once across duplicates and mutations after permanent collection. Keep mutation progress separate. Newly carried finds are not permanent collection credit. Completion uses the current obtainable collectible roster, excludes guardians and unreleased species, and labels that denominator. Previously collected retired species remain in history but do not inflate the current-roster numerator. New additions can lower the current completion percentage; explain this in Details. Apply existing retired-species mappings before counting.

Showcase selections must be ownership-validated; resolve invalid/retired selections safely. Public replies contain only public identity, progress, showcase, and cosmetics, not the full profile, economic ledger, cargo, or private metadata. Cache bounded snapshots and rate-limit inspection; do not replicate every player's full collection continuously.

Earned-title proposals: First Ascent at one valid summit; Peak Regular at five; Summit Veteran at twenty-five; Field Researcher at 25% obtainable species; Master Naturalist at 75%. Titles are selectable after unlocking. Names and thresholds require review and do not retroactively assert trustworthy run-time records.

## 9. Summit finale and reward rules

Completion is individual. Other players continue their expeditions. A server-validated ascent reaching a safe true-peak arrival zone automatically starts the finale, only after grounded arrival and a safe release from climbing. No trigger radius may pull a player past the final challenge. Re-entering the zone cannot finish the same run twice.

Proposed cinematic storyboard, 15–20 seconds total:

| Time | Shot and purpose |
| --- | --- |
| 0–4 s | Camera rises from the climber to reveal the summit crown and the mountain below; brief anticipation before the victory beat. |
| 4–8 s | Player celebrates beside the summit marker; title/prize reveal and helicopter approach establish the payoff. |
| 8–13 s | Helicopter reaches a safe pickup position; a short boarding or winch animation places the player aboard. |
| 13–18 s | Helicopter banks away into the distance; wide mountain vista resolves into the winner's banner. |

Use authored animation and camera work, audio contrast, rotor buildup, and a clear musical victory beat. Asset selection/licensing is implementation work; no audio asset is claimed available. The cinematic is personal and cannot move or hide other players globally. Skip is always reachable by touch, keyboard, and gamepad. Reduced motion replaces sweeping cameras with gentle fixed shots or a brief still presentation. Failure or streaming timeout restores camera/input and presents the result; rewards do not depend on animation playback.

Every valid fresh ascent grants coins and earned Summit Points, with progress toward exclusive earned cosmetics. First-ever completion adds an exclusive earned title, cosmetic, and enhanced reward. No prize requires a purchase.

Economy proposal: retain the current configured 60 Summit Points and first-route bonus of 140 once confirmed against the active award path; move that award into one completion transaction instead of layering a duplicate award. Initial coin proposal: 50 base coins and a one-time 100-coin first-ever bonus. Proposed summit cosmetics at 1, 5, 15, and 30 lifetime completions. Exact values need economy review against current banking rewards and 60/180/420 home upgrades. These are proposals, not approved prices or implemented grants. Apply no paid multiplier to earned Summit Points. Proposed summit coin rewards also remain outside existing discovery/home multiplier scope; show that clearly before purchase if introduced.

The winner's banner shows route/summit, run time, creatures encountered/collected and safely carried, newly banked species versus new species still in cargo, confirmed prizes, and next cosmetic milestone. Label carried finds as unbanked. The run log must distinguish encounters from successful collection; do not invent historical detail missing from telemetry.

Back to Camp returns the player to the new main lobby beside banking and the collection showcase. Extraction preserves cargo; it does not bank creatures or Heartstones, advance occupied home nests, or grant permanent collection credit. Those remain the physical bank transaction's responsibility.

## 10. Expedition identity, persistence, and recovery

Proposed run states: Lobby Ready → Active Ascent → Finish Pending → Finish Committed → Cinematic/Results → Return Pending → Lobby Ready. One server-issued run identity binds route evidence, timestamps, discoveries, and completion. Run start occurs on valid departure through an open route's entrance, not merely spawning or opening a menu.

Ordinary falls/checkpoint respawns do not create a fresh rewarded ascent. Camp shuttles, home visits, reconnects, and route crossings need explicit state transitions. Proposal: a return to the main lobby retires the active attempt, while home visits preserve it. A fresh ascent from the lobby must collect ordered server-validated route evidence. Route crossings at shared camps remain allowed; report the finish route and mixed-route status rather than claim a route-specific speed record without sufficient evidence.

Proposed run time is wall-clock time from departure through confirmed summit arrival, including reconnect gaps and home visits; show it as expedition time rather than a competitive speedrun record. Missing legacy telemetry appears unavailable. Existing summit counts remain historical totals; do not manufacture old prize claims or detailed runs from those totals.

Atomically commit the run's finished marker, summit count, prize grants, milestone unlocks, immutable result snapshot, and pending-result identity through the existing session-owned Profile transaction path. Client messages cannot award completion. A dedicated durable completion fact survives general receipt trimming. Replays, repeated contacts, skipped scenes, and reconnects all resolve to the same result and reward.

If a save is uncertain, show a clear confirmation-pending state and recover the same transaction. Do not present prizes as earned before commit. Protect the safely arrived player from incidental cinematic movement/hazards while resolving; this cannot grant a general cargo-immunity exploit outside the controlled finish state. On a confirmed finish, record a durable return destination so reconnect does not strand the player at the peak or inside a cinematic scene.

After a committed finish, animation is client presentation. Persist result acknowledgment separately from economic completion. An unfinished result can reopen on rejoin; Back to Camp is repeat-safe. Starting another rewarded attempt requires a confirmed lobby return and fresh route validation. No additional daily summit reward cap was selected.

## 11. Integration boundaries

Existing foundations inspected: Profile carries bank/codex/stats, gear.summits, and expedition state; Species supplies rarity and roster metadata; Gear exposes current summits; the runtime client owns Expedition UI; Commerce supplies confirmed ownership and price behavior. Current summit award ownership and ascent validation require a dedicated source audit before implementation.

Proposed focused modules: LobbyBuild for central-world geometry/anchors; PublicProfile for sanitized snapshots; AchievementRules for pure title/milestone rules; ProfileUI and NameTags for presentation; ExpeditionRun for ascent evidence and run facts; SummitFinish for atomic completion and recovery; SummitCinematic and ResultsUI for local presentation; DailyPractice for daily eligibility. Names are provisional; use existing module boundaries where they fit. Keep new behavior out of an ever-growing monolithic runtime client.

World edits affect authored lobby structures and specifically reviewed approach geometry. Do not regenerate mountain terrain, alter route progression, open Coming Soon routes, or modify protected creature assets. Preserve server-authoritative banking, home ownership, settings, traversal controls, and existing Commerce grants. This lobby request does not authorize unrelated mountain expansion.

## 12. Delivery outline and review evidence

1. Lobby: survey/backup the current local review build; create a blockout with exact service anchors and spawn view; verify walking times and preserve route/home/bank contracts; replace the central art with the fairground composition; verify on phones and desktop. Present visual evidence before treating it as final.
2. Portfolio and HUD together: implement authoritative summaries, earned title selection and validated showcases, nearby name-tag inspection, public/private screens, and the coordinated bright HUD. Preserve existing Collection and station functionality. Add the starter cosmetic proposal only after contents and price review.
3. Practice and daily challenge: integrate the nearby multi-stage circuit and daily cosmetic progression using actual validated completions. This can share lobby geometry work, but persistent challenge rewards receive their own checks.
4. Summit finale: audit/replace existing summit grants, implement fresh-ascent validation and durable results, create the personal helicopter cinematic, deliver the winner's banner and bank-adjacent return flow.

Acceptance evidence required:

- Spawn camera clearly frames mountain/entrance; every core service fits the agreed measured 5–8-second travel target; a full-server crowd does not block access.
- Before/after lobby views and landscape-phone captures at shortest supported sizes and largest text; usable controls, no overlapping prompts, readable text, and correct gamepad focus.
- Actual two-client tag inspection: distance, occlusion, departure, safe-zone restrictions, selection in a crowd, paid frame versus earned title, and no private data disclosure.
- Unique-species/rarity counts survive duplicate banking, mutations, roster additions, retirement mappings, and rejoin; unbanked cargo never increases permanent completion.
- Daily challenge rejects forged/out-of-order completion and duplicate stamps, handles daily boundaries, and awards its milestone once.
- Valid peak arrival awards once; direct teleport/reentry without ascent evidence awards nothing; camp respawn cannot manufacture a new run.
- Save failure before commit, lost response after commit, reconnect, receipt trimming, scene skip/failure, and repeated Back to Camp cannot duplicate or lose a confirmed result.
- Two players can finish independently; no one else's camera or movement is taken over. Camera/input restore after all exit paths.
- Cargo identities survive extraction unchanged; only physical banking grants collection credit and relevant home-nest progress.
- Relevant existing persistence, traversal, home, and Commerce checks continue to pass. Real DataStore, device, and multiplayer limits remain explicitly reported where unavailable.

## 13. Next review

The owner approved the design direction and subsequently approved the detailed implementation plans. Numerical reward balancing remains provisional. The next step is implementation preflight through the saved continuation prompt; do not repeat the completed design/plan approval cycle. No implementation completion is claimed. See the resume handoff for the final approval record and remaining content/price boundaries.
