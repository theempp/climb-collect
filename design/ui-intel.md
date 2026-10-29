# UI intel (atlas, 2026-10-21)

Source: `references/ui/` only (76 files, 65 unique; see `design/references-ui-index.md` for filenames and flags). Nothing here comes from memory, other projects, or a house style. **OBSERVED** = visible in a pin; **INFERRED** = my reading. **All hex values are eyeballed estimates from displayed pixels, not sampled (about +-15% per channel).** Short ids: `f1v3_NN`, `rbx2_NN`, `rbx1_NN`, `mg_NN` as in the index. We take style qualities only; no assets, logos or names from BRANDED pins.

**Scope limit (OBSERVED):** the boards contain no in-world HUD (no stamina, altitude, prompts, compass, touch layout). This file covers popups, banners, cards, badges, FX only.

## (a) Palette groups per screen family

| Family | Role | Est. hex | Evidence | Tag |
|---|---|---|---|---|
| Level-up, burst style | bg (dark blue-teal, dimmed scene) | #1B3550 | f1v3_26 | OBSERVED |
| | banner fill (blue) | #2D9BFF | f1v3_26 | OBSERVED |
| | banner text/torn-paper edge | #FFFFFF | f1v3_26 | OBSERVED |
| | accent shard / confetti | #5FD3FF, #FFD84A | f1v3_26 | OBSERVED |
| Level-up, emblem style | bg (dark brown-black) | #231710 | rbx2_11, f1v3_23 | OBSERVED |
| | emblem gold / highlight | #F2B33D / #FFE08A | rbx2_11, f1v3_23 | OBSERVED |
| | gem accent (teal) | #3CC8B4 | f1v3_23 | OBSERVED |
| | tag (orange) | #E8742A | rbx2_11 ("BONUS") | OBSERVED |
| Season/rank "congratulation" | bg violet gradient | #5B2BD6 to #2A1370 | f1v3_05 | OBSERVED |
| | title gradient gold to peach | #F5B83A to #FFD9A0 | f1v3_05 | OBSERVED |
| | primary button (yellow) | #FFD91F | f1v3_05 | OBSERVED |
| Reward claimed | bg band dark violet with glow | #2A2160 | f1v3_01 | OBSERVED |
| | tile fill pastel pink | #F8D3E4 | f1v3_01 | OBSERVED |
| | title gradient lavender to cyan | #B9A4FF to #62C8FF | f1v3_01 | OBSERVED |
| Result banner | bg near-black | #0C0805 | f1v3_15 | OBSERVED |
| | ribbon orange-red / trophy gold | #E8502A / #E8A93A | f1v3_15 | OBSERVED |
| Card reveal (common to rare) | bg navy | #0E1A3A | f1v3_24 | OBSERVED |
| | card frame amber glow | #F2A33A | f1v3_24 | OBSERVED |
| | bg blue radial | #1D63C8 | f1v3_19, rbx1_12 | OBSERVED |
| Card back / hatch | bg dark, card violet, border white | #7A3BD1, #FFFFFF | f1v3_33 | OBSERVED |
| Vortex / jackpot bg | violet-pink radial | #7B2BE0, #E65CD0, #E6D8F0 | f1v3_16 | OBSERVED |
| Legendary lightning | bg black, arcs yellow | #FFE81A, #E8A020 | f1v3_25 | OBSERVED |
| Burst FX | bg brown, rays orange, flare gold, sparkle pink | #6B4A22, #FFA928, #FFD866, #F58FA8 | f1v3_18 | OBSERVED |
| Modal panel (navy) | frame/border | #14306E, #2E7BFF | f1v3_03 | OBSERVED |
| | title ribbon (red wood), close (ice-blue), CTA (green) | #C8402F, #CFE6FF, #22B14C | f1v3_03 | OBSERVED |
| Modal panel (blue premium) | panel / header / dark inset | #2F6FD8, #2A62C2, #14307A | f1v3_32 | OBSERVED |
| | close button (red) | #D63A3A | f1v3_32, rbx2_22 | OBSERVED |
| System banner | bands magenta / teal / orange, pale cyan | #D62B7A, #1FA3B5, #F2601F, #8FDCE0 | f1v3_11 | OBSERVED |
| Progress rails | gold fill on violet | #F2B52E on #5B2FA0 | f1v3_08, rbx2_09 | OBSERVED |
| | orange fill on dark purple | #F68B1F on #2A1450 | mg_03 | OBSERVED |
| Daily tiles (category-coded) | blue, pink, green, orange, purple, yellow | #4AA0F0, #F06BB4, #7FD04A, #F28C3A, #7A52D8, #F5C640 | f1v3_06 | OBSERVED |

**Dominant colour family by popup type (OBSERVED, count over cited files):**
- Level-up: two families only. Cool blue/white burst (f1v3_26) or warm gold on near-black (rbx2_11, f1v3_23).
- Reward / claim: violet-purple backdrops (f1v3_01, f1v3_16, f1v3_33, f1v3_05); the only exception is warm brown/amber burst (f1v3_18) and green burst for a gift (f1v3_29).
- Rarity/box ladder: blue, orange/gold, purple repeat across f1v3_17, rbx2_01, f1v3_28, rbx2_21.
- System/error banner: saturated tri-colour (magenta, teal, orange) with white ink (f1v3_11).
- Backgrounds are almost always dark or dimmed scene behind a bright panel (f1v3_01, 03, 26, 33). INFERRED: dark dim is the pin's way to isolate the panel from busy content.

## (b) Rarity ladder (5 tiers)

**OBSERVED ladders (each pin distinguishes tiers differently):**

| Pin | Tiers (low to high) | Distinguishing channel(s) |
|---|---|---|
| rbx1_01 (6 rosettes) | grey matte, green, gold flat; then blue, violet, orange-pink | Colour change, then **glow + ray burst + sparkles + wider ribbon** in the top row; all share star centre and scalloped ring |
| rbx2_23 (6 hex badges) | plain star hex; spiked; + leaf wreath; + gem; + wings; + crown and red ribbon with halo | **Silhouette complexity** only (one violet hue); every tier adds one ornament |
| rbx2_01 (4 card backs) | COMMON blue swirl; GOLDEN orange + sparkles; ROYAL violet + "R" + crown; JOKER rainbow gradient + crown | Colour, then crown motif, then **iridescent gradient** for top; captions state scarcity |
| f1v3_17 (3 boxes) | blue bg 1 star; orange bg 2 stars; violet bg 3 stars | **Star count (1/2/3) + backdrop colour + brighter glow** per step; same object |
| f1v3_28 (4 labelled cards) | UNCOMMON blue tab; RARE violet tab; EPIC orange tab | **Text tab colour** plus card border colour (violet/orange glow border on higher) |
| rbx2_24 (6 emblems) | silver diamond disc; violet gem; gold wings; blue crown; pink-red crown; iridescent winged crown | Material (silver, gold), then crown, then **prismatic** |
| rbx1_10 (3 gadget levels) | smooth green ring; spiked with sparks; spiked with glow aura | Silhouette spikiness + glow strength |
| rbx2_21 (3 boxes) | blue; violet; gold with crown | Colour + crown + guarantee ribbon; tied to price (excluded) |
| f1v3_21 (10 medals) | gold, red, green, blue, silver, bronze | Material/colour = category, not rank (no ladder) |
| rbx2_22, rbx1_12, f1v3_24 | text chip "COMMON", "Rare Card" | Text label only |

**Strongest ladder (INFERRED judgement):** combine rbx2_23 (ornament escalation) with rbx1_01 (glow and sparkle escalation), because they are the only two that give 5-6 clearly ordered steps without relying on colour alone. rbx2_01 and f1v3_17 give the best colour/backdrop pairing.

**INFERRED mapping to Common / Uncommon / Rare / Epic / Mythic:**

| Tier | Frame | Colour family (est.) | Stars | Glow | Ribbon / badge shape | Primary evidence |
|---|---|---|---|---|---|---|
| Common | flat single border, no ornament | grey-blue #8F9AB5 or blue #3E7BD8 | 1 | none | plain hex/disc, no ribbon | rbx2_23[1], rbx1_01 grey, rbx2_01 COMMON, f1v3_17 left |
| Uncommon | + small leaf/scallop trim | green #2FBF8A | 1-2 | none or faint | scalloped disc, short ribbon | rbx1_01 green, rbx2_23[3] |
| Rare | + gem, brighter border | blue #3A8CFF with soft glow | 2 | soft | gem centre | rbx1_01 blue glow, rbx2_23[4], f1v3_28 RARE tag |
| Epic | + wings/spikes, strong coloured glow, sparkles | violet #8A4CE0 or orange-gold #F2A33A | 3 | strong, rays | winged, long forked ribbon | f1v3_17 right, rbx1_01 violet, rbx2_24 [3,5] |
| Mythic | crown + wings, iridescent/rainbow or full-gold, particle halo | prismatic gradient or gold #F2B33D to pink | 3 + crown | rays + sparkles + lightning/vortex bg | crown + wings + ribbon | rbx2_01 JOKER, rbx2_24 [6], rbx1_01 [6], f1v3_25 |

**Conflicts inside the evidence (not resolved here):** violet is the TOP tier in f1v3_17, rbx2_01, rbx2_23 but only RARE in f1v3_28 and mid-ladder in rbx1_01; orange/gold is the tier above violet in f1v3_28 (EPIC) but below violet in rbx2_01 (GOLDEN < ROYAL). The pins agree on channels (ornament, glow, star count) but **not on colour order**. A colour order must be a user decision.

## (c) Panel and frame anatomy

| Element | OBSERVED | Tag / pins |
|---|---|---|
| Corner radius | Two families: (1) rounded ~8-12% of short side on soft modals (f1v3_32, rbx2_22, f1v3_03 has notched/clipped corners); (2) chamfered 45 degree cuts on sci-fi panels (f1v3_05, rbx2_19, f1v3_20) | OBSERVED |
| Border layers | Panels use 2-3 layers: dark outer line, bright coloured mid band, thin light inner line (f1v3_03 navy / bright blue / light blue; f1v3_24 dark / amber / light) | OBSERVED |
| Header ribbon | A ribbon or plate straddles the top edge: red wooden strip with two round studs (f1v3_03), torn-paper tilted band (f1v3_11), orange ribbon with leaf sprigs (f1v3_15), dark inset title bar (f1v3_32) | OBSERVED |
| Header over panel | Mascot or hero overlaps top edge of the panel (f1v3_32, f1v3_03 ears) | OBSERVED |
| Close button | Square or round, top-right corner, overlapping the frame: red with white X (f1v3_32, rbx2_22, rbx2_08), ice-blue X (f1v3_03), plain grey X (f1v3_07, f1v3_08) | OBSERVED |
| Button shapes | Pill/capsule green or yellow with white bold label (f1v3_03 START, f1v3_07 LET'S COLLECT); chamfered parallelogram yellow (f1v3_05, rbx2_14); rounded rectangle with chunky bottom lip for depth (f1v3_30, f1v3_32) | OBSERVED |
| Primary vs secondary | Primary is saturated green or yellow; secondary is dark slate or blue-grey (f1v3_11 ACTIVATE/CANCEL; f1v3_13) | OBSERVED |
| Outer strokes | Dark outer outline on lettering and icons, 2-4% of height, often followed by a white inner stroke (f1v3_07, f1v3_30, rbx1_10) | OBSERVED |
| Drop shadow | Hard bottom lip (darker same-hue band under tiles/buttons, f1v3_06, f1v3_30) and soft dark shadow under panels (f1v3_03, f1v3_32) | OBSERVED |
| Inner highlight | Glossy top-edge white highlight on buttons, tiles, medals | OBSERVED (f1v3_03, f1v3_06, f1v3_21) |
| Backgrounds | (1) dimmed live scene (f1v3_01, 03, 26, 33); (2) dark gradient with faint tiled icon pattern (f1v3_19, rbx1_12, f1v3_09); (3) radial rays (f1v3_26, f1v3_33 card, f1v3_18); (4) fine dot/halftone texture (f1v3_05, f1v3_11); (5) confetti/sparkle flecks (f1v3_01, f1v3_26) | OBSERVED |
| Title bars | Full-width tilted or straight band behind the headline (f1v3_01 dark band with edge lines, f1v3_11 torn bands) | OBSERVED |
| Chips | Small pill labels for rarity/type/time with dark fill and light text (rbx2_22, f1v3_24 COMMON, f1v3_32 timer) | OBSERVED |
| "NEW" marker | Starburst/rotated tag top-left of card or tile (f1v3_24, f1v3_01) | OBSERVED |

## (d) Lettering (describing, not naming faces)

| Use | OBSERVED qualities | Pins |
|---|---|---|
| Hero headline ("UNLOCKED!", "REWARD CLAIMED", "LEVEL UP") | Very heavy weight, wide rounded forms, strong italic or skew (about 8-12 degrees), thick dark outline plus white inner stroke, vertical colour gradient (white to lilac, gold to orange), glossy highlight band across the top third, upper case | f1v3_07, f1v3_01, f1v3_26 |
| Title on dark ("CONGRATULATION") | Heavy-bold, upright, slightly condensed, geometric squared-off curves; gold gradient fill; upper case; letterspacing slightly wide | f1v3_05, rbx2_11 |
| Hero name ("BONAPARTE") | Extra-heavy italic with soft outer glow; very large (about 20% of height); mixed upper | rbx2_14 |
| Card/item names | Rounded sans, bold, white with dark outline; mixed case ("Bana Bana Spell", "Priestess") | f1v3_24, rbx1_12 |
| Numerals | Chunky, high contrast with dark outline; counts sit beside or on icons; "x3"-style multipliers | f1v3_01, rbx1_12, f1v3_28 |
| Small labels | Plain bold sans, small caps/upper, white on dark chips | rbx2_22, f1v3_32 |
| Ornament numerals ("72", "3") | Embossed gold numerals inside the emblem, heavy, centred | f1v3_23, rbx2_11 |

INFERRED: two lettering voices coexist: playful chunky italic (headlines) and clean heavy geometric (titles on dark). No pin mixes more than these two per screen.

## (e) Reveal / motion anatomy (INFERRED from still frames; no motion is shown)

| Reveal | Sequence the stills suggest | Pins |
|---|---|---|
| Claim / reward | (1) dim scene behind; (2) horizontal band cuts across screen; (3) headline lands (scale-in); (4) item tiles appear in a row (NEW tags pop); (5) "Tap to continue" idles | f1v3_01 |
| Level-up | (1) dark radial rays pulse out from centre; (2) tilted torn banner with number slams in; (3) star shard and confetti fly out; (4) rays and confetti persist | f1v3_26 |
| Level-up, emblem | (1) rune ring draws; (2) wings spread; (3) number settles; (4) reward slots slide in below with glow borders; (5) bonus tag | f1v3_23, rbx2_11 |
| Burst | Central flare, long thin streaks radiating, 4-point sparkles drifting, then card appears from corner | f1v3_18 |
| Box/card reveal | Backdrop colour and star count rise (1 to 2 to 3 stars) before the box opens; then card back glows violet with sunburst, flips to face; name and rarity chip fade in; "SKIP" corner button | f1v3_17, f1v3_33, f1v3_24 |
| Chest reveal | Rays from the chest, card icon with "x3" and "Upgrade available!" fades up above it, "Press to continue..." blinks | rbx1_12 |
| Jackpot | Lightning arcs and ember particles wrap the card; vortex background pulses toward the viewer | f1v3_25, f1v3_16 |
| Count-up | Not observable; numbers sit with coin/gem icons (f1v3_01). INFERRED only | |
| Ribbon unfurl | Torn-paper banners (f1v3_11) and ribbon-with-leaves (f1v3_15) are consistent with a slide/scale unfurl; not observable | |

## (f) Layout rules

| Rule | OBSERVED | Tag |
|---|---|---|
| Hero in centre | Emblem, card or box is dead centre, 30-45% of height (f1v3_05, 23, 17, 33, rbx1_12) | OBSERVED |
| Vertical stack | Headline top, hero middle, rewards row below, one CTA at bottom | OBSERVED (f1v3_05, rbx2_11, f1v3_30) |
| Safe margins | Content kept 5-8% from edges; close button sits inside the top-right margin; CTA sits ~8-12% above the bottom edge | OBSERVED (estimates) |
| Reward rows | 3-5 tiles in a single row, equal size, quantity on or under tile (f1v3_01, rbx2_11) | OBSERVED |
| Portrait vs landscape | Reveal and celebration screens are mostly landscape (16:9, 2:1): f1v3_01, 05, 15, 23, 24, rbx2_11. Portrait is used for offers, tracks and mobile lobbies: f1v3_03, 30, 31, 32, mg_03 | OBSERVED |
| Text amount | Reveal screens carry 2-4 text elements total (headline, one sub-line, quantities, CTA). Dense screens (stats, shop) are separate screens | OBSERVED (f1v3_05, 24, rbx1_12 vs rbx2_14, rbx2_22) |
| Tap-to-dismiss | "Tap to continue", "Press to continue...", "TAP TO CLOSE", "NEXT", "OK", "SKIP" | OBSERVED |
| Left/right tabs | Detail screens put tabs on the right edge (rbx2_14) or top of panel (rbx2_22) | OBSERVED |

## (g) Component map to C&C screens

| C&C screen | Closest pins | What transfers (INFERRED) | Status |
|---|---|---|---|
| Checkpoint / camp banner | f1v3_11 (torn-paper band + mascot), f1v3_26 (tilted banner), f1v3_15 | Wide tilted band across screen, one line of text, 2 s dwell | Partial: no pin shows a location/checkpoint banner |
| Summit-reached banner | f1v3_05, f1v3_15, f1v3_23, rbx2_11 | Centre emblem, headline above, one CTA; gold-on-dark | Supported |
| Level-up | f1v3_26, f1v3_23, rbx2_11, f1v3_22 | Number in tilted banner or winged hex; reward tiles below; XP bar form | Supported |
| Claim / catch reveal | f1v3_01, f1v3_24, rbx1_12, f1v3_29, f1v3_18 | Burst, card with name + rarity chip, quantity tiles | Supported |
| Rarity reveal incl. Rare/Mythic jackpot | f1v3_17, f1v3_33, f1v3_25, f1v3_16, rbx2_01, rbx1_04 | Backdrop and star count escalate; lightning/vortex at the top | Supported |
| Hatch | f1v3_16 (vortex), f1v3_33 (card back), f1v3_17 (box) | Pre-reveal object shakes, backdrop shifts; no pin shows an egg or creature emerging | **Partial: NO REFERENCE for an egg/hatch object** |
| Collection (Hall of Wonders) cards | f1v3_24, f1v3_19, rbx2_01, rbx2_22, rbx2_14, f1v3_02, f1v3_27 (form) | Portrait card: frame, art window, name, rarity chip, level/progress bar; detail view with stat rows and tabs | Supported (cards); grid count form in rbx2_10 and mg_04 ("68/106", "15/18 Collected") |
| Backpack-full / bank confirm | f1v3_03 (modal anatomy only) | Generic modal shell with CTA | **NO REFERENCE** (no inventory, capacity or deposit pin) |
| Fall-loss card | f1v3_11 ("CONNECTION LOST" band) as nearest failure state | Torn band, warm contrast colour, two buttons | **NO REFERENCE** for loss/penalty tone |
| Route-board tiles | rbx2_19 (3 coloured chamfered cards with ENTER), f1v3_06 (colour-coded tiles), f1v3_03 (stage modal), rbx2_09 (progress rail) | Colour-coded tile per route, one CTA per tile, progress rail with checks | Supported (form only) |
| Badges / medals for milestones | f1v3_21, rbx1_01, rbx2_23, rbx2_24, f1v3_05, f1v3_08 (rail form) | Rosettes by category; escalating hex badges by rank | Supported |
| In-world HUD (stamina, altitude, prompts, compass, touch layout) | none | none | **NO REFERENCE** (stated in the index) |
| Camp / Foothold services menus | rbx2_19 (cards), f1v3_03 | Tile menu | Weak |

## (h) Conflicts and tensions (listed, not resolved)

| # | The UI boards show | Other project references show | Why it pulls apart |
|---|---|---|---|
| 1 | Saturated, glossy casual-mobile palettes: violet, magenta, cyan, lime, orange (OBSERVED across the boards) | Grounded, desaturated alpine/overcast footage (see `design/references-intel.md`, `references/images`, `references/frames`) | Different saturation and value structure; no pin bridges them |
| 2 | Dark navy/violet backdrops and neon-glow edges (f1v3_05, rbx2_19, f1v3_33) | Pale snow, grey rock, white-out contrast (K2 frames) | Opposite background value and temperature |
| 3 | Heavy outlines, skewed italic display type with gloss gradients | Real-footage captions and plain HUD text in the K2 frames | Cartoon vs documentary voice |
| 4 | Confetti, rays, lightning, vortex FX at high density | Restrained, mostly still frames; blizzard/whiteout and quiet camps | Spectacle level and pacing differ |
| 5 | User-locked "references-only colour": every hex must come from a reference | These boards ARE references (user-confirmed), but they disagree on hue order (see (b)) and on mood with the K2 images | The lock does not say which board wins for colour; user decision |
| 6 | Rarity colours (blue, green, violet, orange, rainbow) are the pins' primary tier signal | Alpine palette has few saturated colours; adopting the ladder colours adds a family not in the K2 frames | Colour-as-tier vs lock; ornament-as-tier (rbx2_23) avoids the problem but is less readable at small size |
| 7 | Reveal screens are full-screen takeovers (f1v3_01, 05, 16, 33) | K2-style footage keeps the world visible; summit banner in `old_c` is a small overlay | Takeover vs overlay; affects pacing on summit and checkpoint events |
| 8 | Many pins monetise (pass, VIP, spin, price) | Locked rules forbid these | Many of the strongest-looking pins carry excluded features; only form is usable |
| 9 | Portrait phone layouts dominate (offers, tracks) | C&C is mobile-first, but reveal pins are landscape | INFERRED: orientation of reveals needs a decision |
| 10 | Text on pins is in many languages (Russian, Chinese, German, Portuguese, Japanese, Ukrainian, Vietnamese, Spanish) | Locked: no Spanish text | Only English text can transfer; copy must be written fresh |

## What could not be determined

- Exact hex values (no sampling), exact corner radii and stroke widths in pixels, and actual typeface identities (not named by design).
- Any motion timing, easing, or sequence ordering: stills only.
- How any pin scales on a small phone (pins are screenshots at varied resolutions, 384 to 1536 px wide).
- Colour order of the rarity ladder (conflict in (b)).
- Egg/hatch, backpack, bank, fall-loss and in-world HUD treatments (no pins).
