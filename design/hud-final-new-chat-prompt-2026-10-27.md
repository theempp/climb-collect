You are continuing the Climb & Collect HUD redesign. Do NOT edit game code or Studio yet. The job is a revised HUD/UI CONCEPT (animated HTML artifact), then stop for my approval.

READ FIRST
- Memory: overhaul-plan-decisions.md, egg-loop-decisions.md.
- design/vfx-ui-intel-2026-10-27.md (merged references), design/hud-v2-intel.md (approved v2 tokens), design/hud-v2-publish-2026-10-27.md.
- Current concept board (the one I am correcting): https://claude.ai/artifact/AnNnRCZqNRybd77HdoMbzE, source at design/hud-final-direction-2026-10-27.html. Icons: design/hud-v2-icons/. Backgrounds: design/hud-v2-mocks/bg-*.jpg.
- Real HUD code (for later, read-only now): C:\Users\HOME!\Desktop\climb-collect-integration, branch codex/hud-v2, mountain/client/UI/*, mountain/shared/UIPresentation.luau (hudLayout, topbar handling), mountain/tools/hud_overflow_audit.client.luau.

LOCKED LOOK: Glassbloom (frosted violet glass, pink-violet action gradient, floating dock, sparkle) plus Golden Hoard's slamming RUN! text and reward-strip reveal. Keep tokens and fonts from the current board. No fake near-miss in reveals; odds shown on paid random items.

WHAT I WANT FIXED / ADDED
1. Roblox's default top-left buttons. Draw them in every mock frame as neutral grey placeholders labelled "Roblox core buttons" (menu, chat; about 44 px row, top-left, inside GuiService.TopbarInset). Nothing of ours may overlap or crowd that area, and the layout must work with them present.
2. Open up screen space. Aim for the HUD to use as little of the screen as possible during the chase. Show a before/after area comparison. Keep the bottom-left thumb zone and centre clear.
3. Replace the long "Carry Mossbun home" widget with a ONE-TIME pop-up animation (2.5 s, tier 2 banner, rarity-coloured): "CARRYING MOSSBUN" with the creature icon, then it shrinks away. After that, show only something tiny and useful (see ideas below). Also show the re-announcement when a stolen creature is picked back up.
4. Everything inside popups must fit inside the panel: no card, row or button hanging off the bottom or sides (the Collection frame currently overflows: second row of cards ends below the panel). Build the mock content with real flex/grid layout and scroll containers, not absolute pixel positions, and add a JS containment check to the page that asserts every child is inside its panel and prints PASS/FAIL per screen. Test at 3 phone sizes (e.g. 749x330, 844x390, 932x430).
5. Shop and Settings pages must scroll. Keep the side tabs fixed; the right content is a styled ScrollingFrame with a visible scrollbar, a fade hint at the bottom edge, section headers, and a sticky hero card (Starter Pack) in the shop. Collection scrolls too when it has more cards than fit.

MY IDEAS TO EVALUATE (pick the best, say why, drop what does not work)
- Top row: only the coin pill and settings gear on the right. Level/XP leaves the permanent HUD; show it as a thin XP line above the dock and as the avatar ring on the Creatures dock button; full player card only on tap.
- Carry state after the pop-up: a small round creature portrait (about 44 px) with a distance ring, sitting just above the dock; tap to expand. Also a world beacon and floating distance label over the safe gate, plus an edge arrow when the gate is off screen. So no wide widget at all.
- During a chase the dock fades to about 25 percent and shrinks to 3 buttons; it returns on tap or when safe. The alert chip becomes a 1.5 s banner, then the pink edge vignette alone carries the danger.
- Altitude rail: thin, left edge below the Roblox buttons, fades to 30 percent after 3 s, brightens at checkpoints.
- One message system: tier 1 toast, tier 2 banner, tier 3 moment, all non-blocking in the mountain.
- Add a "HUD at rest" frame, a "carrying" frame, a "chase" frame and a "sanctuary" frame so I can compare space use.

DELIVERABLE
Publish ONE updated artifact (new version of the same concept board is fine): Roblox core buttons visible, the four HUD states, the carry pop-up animation with replay, fixed Collection, scrollable Shop and Settings, containment PASS table, and a short list of what you changed and what you rejected from my ideas. Then ask me to approve or change via a popup. Do not build in Studio, publish a place, or touch products or Robux without asking.
