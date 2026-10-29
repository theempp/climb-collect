# Launch assets plan (2026-10-28)

Design only. Nothing captured, generated, uploaded or entered in Creator Hub. Extends [publish-prep §5](publish-prep-2026-10-28.md).

## Rules
- **No inherited look.** `design/climb-collect-experience-icon-2026-10-22.png` is Fairground-era: do not reuse. All colour, type and style come from this project's own references (`references/`, Glassbloom intel `design/hud-glassbloom-intel.md`, creature concept boards). Nothing carried from other games.
- **Honest claims only.** Show only what ships in the launch build. Never show disabled features (raids, rankings, shop items not live). No performance claims (30 FPS is unverified). Paid items: don't imply free; paid eggs show odds in-game.
- **Capture from the final build** (after P6 motion and merge), on a real-looking character, StudioAids off, so UI and creatures match launch.
- Roblox reviews icon/thumbnails before they go live: allow lead time.

## Specs to confirm on create.roblox.com before upload
Third-party sources (not the official page, which my search did not return) say: icon square, at least 512x512, shown as small as 150 px and 50 px; thumbnails 1920x1080 (16:9); keep key content away from the bottom edge (player-count overlay); PNG/JPG; keep each under 3 MB. Verify all of these on the live Creator Hub page.

## 1. Icon
- One clear subject readable at 50 px: a creature (or egg + creature) against the mountain silhouette. No text beyond, at most, the title if it stays legible tiny; no UI.
- Make 3 variants for the Creator Hub A/B (Roblox supports testing): egg-focus, creature-focus, mountain-climber-focus.
- Hero creature choice depends on art: only creatures that exist as uploaded, phone-ready meshes count. Until the creature pipeline ships a test creature, the icon is blocked.

## 2. Thumbnails (aim for 5-6, all real gameplay)
1. **Hero:** player on a cliff ledge, summit visible, creature companion beside them.
2. **The catch:** egg strike moment with Guardian telegraph in frame.
3. **Hatch reveal:** rare creature pop-in on the reveal strip.
4. **Home base:** sanctuary with several habitats and creatures.
5. **Collection:** the Collection screen with a full, varied grid.
6. **Multiplayer:** 2-8 players near the same camp or hub (once the eight-client test exists).
Lower third kept clear; one focal point per image; legible at feed size.

## 3. Trailer (20-30 s, optional but strong for discovery)
Shots, in order: summit wide -> climb (rope/ledge) -> egg spotted -> Guardian telegraph -> grab and run -> bank -> hatch reveal -> sanctuary pan -> title card. Capture with Studio camera paths at 60 FPS on desktop; no fake UI. Audio from the licensed shortlist once chosen; trailer needs the Tier 1 sounds from the [audio plan](audio-juice-plan-2026-10-28.md) to feel finished.

## 4. Copy (drafts; owner edits)
**Title:** Climb & Collect

**Short:** Climb the Impossible Mountain, find hidden nests, hatch creatures and build a sanctuary for your collection.

**Description (draft):**
Climb the Impossible Mountain. Spot hidden nests, grab an egg and get it back to safety before a Guardian or a thief takes it. Hatch your finds, build habitats in your own sanctuary and fill your collection with creatures.

- Six kingdoms, each with its own dangers and a Guardian to face
- Hatch creatures of different rarities and grow your sanctuary
- Daily quests and a weekly season
- Play on phone or PC, with up to 8 players per server

Some items are available for Robux. Paid eggs show their odds before you buy.

(Remove any bullet for a feature that is not live at launch. "Weekly season" and "daily quests" depend on what ships. "Phone or PC" depends on the device evidence.)

**Tags/genre:** adventure, collecting, pets, climbing. Final tags chosen in Creator Hub.

## 5. Production steps
1. Wait for the merge and final HUD; take a dedicated capture build copy.
2. Owner picks hero creature and mood from approved references.
3. Capture stills and trailer clips; I list and rank candidates, owner chooses.
4. Make icon variants and thumbnails; check at 150 px and 50 px.
5. Upload on a private place first; submit for review; allow lead time.
6. Update copy to match what actually shipped on launch day.

## Open
1. Which creature is the hero (depends on first uploaded creature).
2. Trailer: yes/no and length.
3. Who produces final key art: me from captures, or an outside artist for the icon (best ROI for click-through).
4. Official specs check on Creator Hub.

## Verified specs (create.roblox.com, checked 2026-10-28)
- Icon: square, **at least 512x512**; preview at ~150x150. Must pass moderation before others see it. Upload: Creator Dashboard > game > Configurations > Places > start place > Icon. Format and file-size limit not stated on the page. ([game icons](https://create.roblox.com/docs/production/promotion/game-icons))
- Thumbnails: **16:9, ideally 1920x1080**. ([thumbnails](https://create.roblox.com/docs/production/promotion/thumbnails)) The 3 MB and 50 px figures are third-party only.

## Resolved (owner popup, 2026-10-28)
- Icon made **by me from game captures** (no outside artist for now).
- Hero creature: I shortlist 3 after the first test upload passes Studio import + phone check; owner picks from captures.
- Copy fixes needed: remove "weekly season" (dropped for v1, 2026-10-29) and duo/party mentions; keep "up to 8 players" only if hosted MaxPlayers 8 is set.
- Creature readiness (read-only check 2026-10-28): 43 GLBs in `creatures/build/out/` (~2.5-3k tris, 16 parts, flat colours, budget 3,500); `asset_ids.json` absent, so **none uploaded**; `ROBLOX_API_KEY`/`ROBLOX_USER_ID` not set in shell, User or Machine env. Studio import, scale and phone perf unverified. A phone-ready test creature cannot ship until the owner sets the env vars and authorizes one upload, then a Studio + phone check. `creatures/` is also uncommitted in this repo.

Launch blockers: [launch-readiness-checklist](launch-readiness-checklist-2026-10-28.md).
