# HUD v2 — reference analysis (2026-10-27)

**Why:** after a phone test, the owner rejected the live E+B HUD as "super basic, super sloppy", not the look of a viral Roblox game. The approved mockup (`climb-collect-integration/evidence/hud_eb_2026-10-26/approved-layout-reference.png`) was never achieved: the build used flat dark panels with text labels.

**Sources:** owner's public Pinterest boards (enzomarin708), all pins downloaded 2026-10-27 to `references/ui/pinterest-2026-10-27/`: `cc2/` (5), `cc/` (5), `finale-f1/` (13), `robloxf1-v2/` (24 of 25; one pin had no still image). The Steal an Egg / Break and Steal an Egg web search gave text only, no usable in-game captures.

## What every board agrees on (the gap vs. our build)

| Trait | References | Our live HUD |
|---|---|---|
| **Illustrated 3D icons** on every button (chest, egg, map, gear, gem, coin) | cc2/01 icon sheet, finale-f1/01, robloxf1-v2/08 | Flat glyphs / text only |
| **Chunky "candy" buttons**: thick dark outline, base colour, darker bottom lip (fake depth), top highlight band, white heavy-italic label with dark stroke | finale-f1/07 (5-step build), finale-f1/02 CONTINUE, cc2/05 button row | Flat rounded rectangles |
| **Saturated, high-contrast colour**: yellow/orange primary CTA, green confirm, purple/blue panels, pink/red alerts | all four boards | Muted navy/teal |
| **Heavy display type**: chunky rounded or bold-italic, always stroked or shadowed | cc/02, finale-f1/02, robloxf1-v2/06 | Thin plain sans |
| **Currency pills**: big icon overlapping the pill, number, green "+" | cc2/03, finale-f1/03, robloxf1-v2/08 | Small text counter |
| **Collectible cards**: rarity-coloured frame, level badge in the corner, progress bar "9/50", name banner | finale-f1/03, finale-f1/09/11, robloxf1-v2/01, /14 | Small creature tiles |
| **Red notification dots** with counts on buttons | finale-f1/03, robloxf1-v2/08, /04 | None |
| **Reward moments**: rays, sparkle bursts, "LEVEL UP" and "UNLOCKED!" banners, rank badges in tiers | finale-f1/02, robloxf1-v2/02, /05, /20, /23, /24 | None |
| **Panels**: coloured header ribbon plus a close X in a red square | cc/03, robloxf1-v2/07, /18 | Plain dark boxes |
| **Daily, streak and objective strips** with a progress track and reward nodes | robloxf1-v2/13, /16, /18 | None |

## What to leave out
- F1 and Pirelli tyre infographics, the dark-neon "Taiso" cards and wuxia skill bars (robloxf1-v2/03, /11, /17, /22). They belong to the owner's F1 project, not this game. Use them only for the rule "big number + bold label" in the stats.
- Casino styling (robloxf1-v2/24): use it only for the "UNLOCKED!" reward banner idea.

## Proposed next steps (not started)
1. **atlas** turns these pins into `design/hud-v2-intel.md`: palette sampled from the pins, the button recipe, type, and the badge/card specs. No invented values.
2. Owner approves 2–3 mock HUD screens built from that intel, using the actual game screens (sanctuary, mountain, carry).
3. Then build: icon art (generated or authored, approved first), a 9-slice button kit, and a re-skin of `MountainHUD` and the eight hubs on a copy. Run the device audit, then publish only with approval.
4. Still owed: in-game screenshots of Steal an Egg / Break and Steal an Egg, if the owner wants them as direct references.
