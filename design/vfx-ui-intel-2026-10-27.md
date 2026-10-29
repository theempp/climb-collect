# VFX + UI reference intel, merged (atlas, 2026-10-27)

**Sources:** `references/vfx-ui-2026-10-27/` (videos v1 to v6, contact sheets) and the owner's pasted Settings screenshot (image not on disk yet: save as `references/vfx-ui-2026-10-27/settings-purple.png`). Detail and cell citations: [A (v1-v3)](vfx-ui-intel-A-2026-10-27.md), [B (v4-v6)](vfx-ui-intel-B-2026-10-27.md), [C (screenshot)](vfx-ui-intel-C-settings-screenshot-2026-10-27.md). All hex values are eye estimates. Style and technique sources only; do-not-copy list is in B section 6.

## What each reference is good for
| Ref | What it is | Take from it |
|---|---|---|
| v1 | Neon cosmic mining game | Hue-coded stage cards with status chips, two-tier arrival name card, radial speed lines + FOV kick, skins panel |
| v2 | Loot reveal | Sunburst + vignette backdrop, slot carousel with a fixed gold selector and near-miss settle, count-up result card, hue-cycling luck badge |
| v3 | Plot shatter VFX | Charge, break into 8 to 16 shards, swirl, recolour with hot accent pieces, reform; ground ring + orbit streak telegraph |
| v4 | Winged ring creatures | Nested counter-rotating rings, sparse star sparkles, breathing aura; dark faction rig for guardians |
| v5 | Simulator UI | Overhanging icon ribbon + red X, lip buttons, claimed/ready/timer state ladder, Before-to-After panel, XP bar with rainbow marker, full reveal sequence |
| v6 | Shop | One holographic hero offer among flat siblings, tiered coin packs with growing pile icons, floating icon labels over stations |
| Screenshot | Violet glass Settings | Row pattern (icon tile, title, caption, control), glow on the active element, sparkle flares, player level card, Camera Shake toggle |

## Moment map for Climb & Collect
| Moment | Use | Length | Constraint |
|---|---|---|---|
| Egg break at the nest | v3 charge, shatter, recolour in the world, 0.3 s flash, rarity ring, name billboard. HUD stays | 1.5 to 2.5 s | Carrier is unsecured and can be stolen from, so no blocking modal |
| Rarity tiers (3-tier banners) | More shine = rarer: tier 1 billboard, tier 2 banner + burst, tier 3 flash + holo name + aura | per tier | Tier names and counts still undefined in any design doc |
| Hatch in the sanctuary | Full v5/v2 reveal: wash, name, chance, count-up, Collect (delayed) | 6 to 10 s | Safe zone only |
| Guardian wakes / chases | v3 ground-ring telegraph, v1 speed lines + FOV kick, v4 dark faction eyes | ring 1 s | First strike alerts the guardian |
| Section arrival | v1 two-tier name card + speed lines | 2 to 3 s | |
| Summit | v2 sunburst + v4 wide-macro-wide camera | 4 to 6 s | |
| Bank / secure | Rings lock into a halo, sparkle, count-up | 3 to 4 s | Exit permanently secures |
| Level-up | XP bar rainbow marker, numeral pop, white flash | 1.5 to 3 s | |
| Daily / shop | v5 tile ladder, v6 hero card and coin tiers, "best deal" only when true | UI | No paid power in raids/theft; odds on paid random items |
| Theft drop (3 s) | Pillar beam + countdown ring (recipe only; no reference shows it) | 3 s | |

## Top techniques, ranked by impact per mobile cost
1. Sunburst + dark vignette backdrop (v2). 2. Count-up result card with delayed CTA (v2). 3. Slot carousel with near-miss settle (v2). 4. Panel grammar: overhanging ribbon and X, lip buttons (v5). 5. Hero offer card (v6). 6. Radial speed lines + FOV kick (v1). 7. Ground ring + orbit streak telegraph (v3). 8. Two-tier name card (v1). 9. Charge-shatter-recolour (v3; keep at 60 pieces or fewer, no shadows). 10. Reward state ladder with Claim All (v5).
Also: floating icon labels over stations, Before-to-After panel, XP bar rainbow marker, star sparkles with breathing aura, nested eye rings with LOD.

## Mobile guardrails (recommended, unmeasured)
At most 6 live emitters and 300 particles; at most 80 anchored parts per effect, no shadows; Bloom plus one ColorCorrection pulse, Blur only for sub-second beats; one live ViewportFrame; effects run on the client from one RemoteEvent. A reduce-effects toggle (no shake, FOV kick or hue cycling) plus the Camera Shake setting. Owner phones are high-end iPhones and do not prove low-end Android.

## Open decisions
1. **Overall look.** Three new concepts are on the board (Glassbloom, Night Ascent, Golden Hoard). The approved HUD v2 is blue/yellow. Pending the owner's pick.
2. Is a carried rare's aura visible to thieves? (v4 aura vs theft rule.)
3. Short in-world reveal at the nest, full reveal in the sanctuary: two builds (recommended).
4. Banner tier definitions (sizes, durations).
5. Typeface per concept; Roblox built-ins only (Bangers, LuckiestGuy, FredokaOne, others to test).
6. Confirm settings screenshot file location.
