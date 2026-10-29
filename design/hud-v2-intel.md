# HUD v2 — design intelligence (atlas, 2026-10-27)

**Source:** only `references/ui/pinterest-2026-10-27/` (47 pins, all read) + layout target `climb-collect-integration/evidence/hud_eb_2026-10-26/approved-layout-reference.png` (layout only, not style). Paths below are relative to the pins folder; `layout` = the approved layout image.
**Scope:** HUD + hub panels for v2. For HUD v2 this file replaces the HUD parts of `design/ui-intel.md` (v5 refs). Nothing here was merged into that file.
**Accuracy:** I had no pixel sampler, so every hex is an **eye estimate from a JPEG (est.)**. Check each one with an eyedropper on the cited file before the 9-slice art is made. Sizes are **ratios measured in the ref × 390** (the short side of an 844×390 safe area). They are not measured in Studio.

**Excluded (do not use):** `robloxf1-v2/01` (wuxia skill bars), `/03` (dark-neon Taiso cards), `/12` and `/17` (F1/Pirelli), `/09` (dark lightning card, except as a reveal-burst idea). Scene-only pins with no UI: `cc2/02`, `cc2/04`, `cc/01`, `finale-f1/12`. `robloxf1-v2/24` (casino) is used only for the UNLOCKED! banner.
**Index errors in the gap analysis:** `robloxf1-v2/01` is the wuxia bars, not cards. `/11` and `/22` are cartoon game screens, not excluded styles. `/12` is Pirelli. The exclusions above are the corrected list.

---

## 1. Palette tokens (all est.)

| Token | Hex | Role | Source |
|---|---|---|---|
| `cta.base` | #FFC414 | Primary CTA face (yellow) | finale-f1/07 (step 2), cc2/05 "Primary", robloxf1-v2/04 FIGHT! |
| `cta.shade` | #F29A00 | Lower face / gradient end | finale-f1/07 (step 3) |
| `cta.lip` | #8C4A1C | Yellow-button lip (brown, hue-shifted) | finale-f1/07 |
| `cta.ink` | #4A230E | Yellow-button outline + label stroke | finale-f1/07 |
| `ok.base` | #3FC53A | Confirm face (PLAY/YES/CONTINUE) | finale-f1/01, finale-f1/02, robloxf1-v2/24 LET'S COLLECT |
| `ok.lip` | #23892A | Confirm lip | finale-f1/01 |
| `no.base` | #EC3B4E | Danger/NO face | finale-f1/01 NO |
| `no.lip` | #A61E33 | Danger lip | finale-f1/01 |
| `close.base` | #E43A36 | Red close-X square | cc/03, robloxf1-v2/18 |
| `alert.dot` | #EE3A48 | Notification dot (alert) | finale-f1/03 Mission "2", layout |
| `alert.dot.alt` | #F2467C | Pink variant of the dot | robloxf1-v2/04 |
| `ready.dot` | #48C83C | Count badge for "ready / claimable" | finale-f1/03 Heroes "1" |
| `alt.base` | #3D8EF2 | Secondary blue button | finale-f1/01 refresh |
| `tert.base` | #C66CF2 | Tertiary purple button | cc2/05 "Tertiary" |
| `off.base` | #AEB6C0 | Disabled/locked button | finale-f1/01 blank, cc2/05 locked |
| `panel.blue` | #2E6FE2 | Main panel / screen fill | finale-f1/03, finale-f1/08 |
| `panel.navy` | #1B2B5A | Inset, header strips, bar tracks, pills | finale-f1/03 card header bars, robloxf1-v2/16 timer pill |
| `panel.purple` | #7A3EE2 | Reward/rare panel fill | cc/05, robloxf1-v2/07 MEGA BOX |
| `panel.row` | #D5E0F3 | Light stat row inside a panel | cc/03 / robloxf1-v2/19 stat rows |
| `ink` | #14203F | Universal outline + text stroke | finale-f1/01 tile outlines, finale-f1/08 cards |
| `text` | #FFFFFF | All labels on colour | everywhere |
| `text.dark` | #1C1E3C | Label on yellow CTA (alt.) | robloxf1-v2/04 FIGHT!, robloxf1-v2/14 UPGRADE |
| `text.gold` | #FFD23C | Highlight numbers / "MAX" | cc/03 "Cycles 2", finale-f1/08 MAX! bar |
| `bar.fill` | #3BB6F0 | Progress fill (in progress) | finale-f1/03 "9/50" bars |
| `bar.ready` | #5CCB3A | Progress fill (ready to upgrade) | finale-f1/03 "Lv.9 Upgrade" |
| `bar.max` | #F6C02A | Progress fill (maxed) | finale-f1/03 / finale-f1/08 "MAX" |
| `coin` | #FFC72C (rim #E59410) | Coin currency | finale-f1/08, cc2/01 coin |
| `gem` | #B23DE8 | Premium gem (purple) | finale-f1/03, finale-f1/08, layout |
| `heart` | #E8323C | Heart/health | cc2/01, finale-f1/01 MINI BUNDLE |
| `plus` | #45C43A | "+" tile on currency pills | robloxf1-v2/08 |

**Rarity ladder.** `robloxf1-v2/06` is the only pin that labels its tiers: COMMON, GOLDEN, ROYAL, JOKER. `robloxf1-v2/05` adds silver and prismatic badge tiers.

| Tier (ref name) | Frame hex | Treatment | Source |
|---|---|---|---|
| Base (silver) | #B9C3D2 | Flat metal | robloxf1-v2/05 tier 1 |
| Common | #3A8BEE | Flat blue | robloxf1-v2/06 COMMON, finale-f1/10 blue frames |
| Golden | #F7A21B | Orange-gold | robloxf1-v2/06 GOLDEN, finale-f1/10 orange frames |
| Royal | #8A4BE6 | Purple + sparkles | robloxf1-v2/06 ROYAL, finale-f1/10 wolf |
| Joker / legendary | gradient #FF5FA0 → #FFC93C → #4FD8F0 → #9A5CF0 | Rainbow rim + sparkles | robloxf1-v2/06 JOKER, robloxf1-v2/05 tier 6 |

**Owner decision:** how many rarity tiers the game uses and which name goes with each colour. The pins give colour order only.

## 2. Button recipe ("candy" button)

The layer order comes from finale-f1/07, which shows it built in five steps. Proportions are from finale-f1/01.

| # | Layer | Spec | Source |
|---|---|---|---|
| 1 | Outline | `ink` (brown `cta.ink` on yellow), ≈5 % of total height, min 2 px | finale-f1/01, finale-f1/07 step 1 |
| 2 | Lip (bottom slab) | Same shape, shifted down. Depth 13–16 % of total height. Colour = base about 35–45 % darker; on yellow it shifts to brown | finale-f1/01, finale-f1/07 step 2 |
| 3 | Face | Base colour, vertical gradient base → `*.shade` toward the bottom | finale-f1/07 step 3 |
| 4 | Light rim | Thin lighter line along the face's bottom edge | finale-f1/07 step 4 |
| 5 | Highlight | Lighter band over the top ≈40 % of the face, plus a small gloss blob near the top-right | finale-f1/01, cc2/05, finale-f1/07 step 5 |
| opt | Diagonal stripes | Faint lighter 45° stripes on the face (CTA only) | finale-f1/07 |
| 6 | Label | White, heavy, all caps, `ink` stroke, plus a 1–2 px drop extrusion in the stroke colour | finale-f1/07, finale-f1/01, finale-f1/02 |

**Corner radius:** ≈20 % of height on wide buttons (finale-f1/01) and ≈25 % on CTAs (finale-f1/07, cc2/05).

**Phone sizes (offset px, 844×390):**

| Button | Size | Derived from |
|---|---|---|
| Large CTA | 52 h × ~136 w | robloxf1-v2/04 FIGHT! 55/414 h, w ≈ 2.6 h |
| Small CTA / pill button | 34 h | cc/02 LEVEL UP 30/339 |
| Square icon tile | 56 × 56 | robloxf1-v2/04 SHOP 60/414; finale-f1/03 nav 60/420 |
| Close X | 28 × 28 | robloxf1-v2/18 ≈ 32/552 h (scaled up for touch, est.) |

**States:**

| State | Spec | Source |
|---|---|---|
| Rest | All layers | Pins above |
| Pressed | Face moves down by the lip depth and the lip collapses to 0 | Your spec, consistent with the lip build. Not observed (stills only) |
| Disabled | `off.base` face, padlock glyph, no highlight | cc2/05 locked secondary |

## 3. Typography

| Use | Traits seen | Roblox font | Why | Source |
|---|---|---|---|---|
| **Display + all labels (recommended)** | Rounded geometric heavy caps, soft terminals, wide | `Enum.Font.FredokaOne` | Closest built-in match to the rounded heavy caps | cc/02 ALYSA / LEVEL UP, finale-f1/02 WILD STICKER / CONTINUE, robloxf1-v2/06 CARD TYPES, finale-f1/01 PLAY/YES |
| Title alt (comic) | Chunky, slightly irregular, bouncy baseline | `Enum.Font.LuckiestGuy` | Matches the Supercell-style comic heads | cc/03 Knight, cc/05 ARCHER, robloxf1-v2/18 TAGESSERIE |
| CTA alt (italic) | Heavy, condensed, forward-slanted | `Enum.Font.Bangers` (slanted comic). GothamBlack is upright only (est.; italic Gotham via FontFace needs a Studio check) | Matches the slanted CTA labels | robloxf1-v2/04 FIGHT!, robloxf1-v2/14 UPGRADE, robloxf1-v2/11 SIGUIENTE, finale-f1/07 CANCEL |
| Small numbers / names | Bold rounded sans, white, thin dark stroke | FredokaOne | Same family as the labels | finale-f1/03 "9/50", "Shuri" |

**Conflict:** the pins show both upright-rounded and italic-heavy labels.
- **Recommendation:** FredokaOne everywhere, with LuckiestGuy only for big reward titles.
- **Cost:** the FIGHT!-style forward lean is lost on CTAs.

**UIStroke:**

| Text | Stroke | Source |
|---|---|---|
| Labels | ≈12–15 % of cap height (≈2 px at 14–16 px text, 3 px at 20–24 px), `ink`; `cta.ink` on yellow | finale-f1/07, finale-f1/01 |
| Display titles | Thicker (≈4 px at 40 px), plus a gradient fill (white → pale or yellow → orange) | finale-f1/02, robloxf1-v2/06 |

## 4. Component specs

| Component | Anatomy | Source |
|---|---|---|
| **Currency pill** | `panel.navy` pill, fully rounded, ~24 px h. Icon ≈1.25× the pill height overlaps the left end. White FredokaOne number with stroke. Green `plus` rounded-square tile at the right end, white "+" | cc/02 (25/339), finale-f1/03 (icon overflow), robloxf1-v2/08 (green +), layout |
| **Icon button + dot** | 56 px square tile: base colour + lip + `ink` outline, illustrated 3D icon filling ~80 %, optional label beneath inside the tile. Dot 18 px circle (`alert.dot`, white count, 2 px white or ink ring) overlapping the top-right corner by ~⅓. Use `ready.dot` for claimable | finale-f1/01 top tiles, robloxf1-v2/04 SHOP + dot, finale-f1/03 nav badges, layout |
| **Creature card** | Rarity-colour frame with rounded corners (~6 % of width) and an `ink` outline. Level badge (hex or shield, `panel.navy` or tier colour, white number) at the top-left. Progress bar `bar.*` on a `panel.navy` track with "n/max" text. Optional star row. Name at the bottom in white stroked caps on a darker band of the frame colour | finale-f1/03, finale-f1/08, finale-f1/10 |
| **HUD creature slot** (bottom centre) | Rounded-square portrait ≈0.8× the icon tile (~46 px), rarity-colour fill, numbered circle badge at the bottom centre | layout E |
| **Panel** | `panel.blue` body, radius ~3 % of width, `ink` outline, light `panel.row` stat rows. Header is either a tab ribbon (lighter blue tab, white label) or a title overlapping the top edge. Red square close-X (`close.base`, white X, `ink` outline) straddles the top-right corner | cc/03, robloxf1-v2/18, robloxf1-v2/07 |
| **Ribbon (header)** | Flat band with folded tails (orange) or a straight band (pink), white caps label | finale-f1/01 SHOP / orange ribbon |
| **Quest / objective card** | `panel.navy` card, illustrated icon at the left, white title, progress bar below with "n/max". For multi-step quests: a track with reward icons above check nodes (green check in a white circle) | layout (Reach the Summit), robloxf1-v2/16 |
| **Reward banner** | Centred title on a burst of rays. LEVEL UP uses a white skewed slab with a coloured word, plus star and confetti. UNLOCKED! uses huge pale text with a purple stroke on a `panel.purple` card, with a green small CTA under it. Level-badge variant: hex number with wings over a row of reward tiles | robloxf1-v2/02, robloxf1-v2/24, robloxf1-v2/23 |
| **Daily-streak strip** | Track with gift nodes at milestones (7/14/21/28) and a "n/28" pill. Below it, rounded day tiles (radius ~20 %) in rotating colours, with the final day double-wide in gold. Current/claimed day uses a light fill + reward art. Alt: calendar icon with a big streak number + a row of blue reward cards + a timer pill | robloxf1-v2/13, robloxf1-v2/18 |

## 5. Motion cues (stills only, so all are implied)

| Cue | Source |
|---|---|
| Radial rays + confetti behind level-up | robloxf1-v2/02 |
| Coloured side glows + rays + sparkle stars behind a card reveal | finale-f1/02 |
| Gold particle drift + NEW stamps on reveal | finale-f1/05 |
| Swirl ring + flying cards on unlock | robloxf1-v2/24 |

Bounce and scale-pop timings cannot be seen in stills. Motion owns them; none are specified here.

## 6. Roblox mapping

| Need | Primitive |
|---|---|
| Outline | `UIStroke` (ApplyStrokeMode Border), thickness ≈5 % of height |
| Lip | Second Frame behind the face, offset +lip px, darker colour, same `UICorner` |
| Face gradient + highlight band | `UIGradient` (Rotation 90, base → shade), plus a child Frame at the top 40 % with a white `UIGradient` transparency ramp |
| Stripes, gloss blob, ribbon tails, hex/shield badges, rarity rainbow rim, rays/sparkles | `ImageLabel` (9-slice `SliceCenter` for stretchable frames) |
| Text stroke | `UIStroke` on TextLabel (ApplyStrokeMode Contextual). Use a duplicate offset label for the drop extrusion |
| Pills / dots | `UICorner` CornerRadius = UDim(0.5, 0) |
| Card/panel corners | `UICorner` (scale per the table above) |

**Icon art to produce:** illustrated 3D style, chunky forms, soft top light, saturated (cc2/01, cc2/05, finale-f1/01). Approve before the build.

1. Chest / shop stall
2. Egg (+ cracked variant)
3. Creature portraits (per species)
4. Map / mountain
5. Gear / settings
6. Coin
7. Gem
8. Heart
9. Sprint (running figure)
10. Climb (hand) and jump (up arrow)
11. Bat
12. Quest scroll
13. Calendar / daily
14. Gift
15. Padlock

## Identity (recommendation, not observed)
The pins give a genre-standard kit. To make it read as Climb & Collect:
- illustrated **mountain/egg/creature** icons in place of generic chest/sword art;
- **rarity** shown on the creature slots during play, not only in menus.

Both are owner decisions to confirm with the mocks.

## Open conflicts for the owner
1. **Label face:** FredokaOne upright (rec.) vs italic CTA. Cost: less energy on CTAs.
2. **Panel base:** blue (rec.; finale-f1/03, cc/03) vs purple (cc/05, robloxf1-v2/07). Rec. purple only for rare/reward moments. Cost: a less "premium" everyday look.
3. **Outline ink:** universal navy `ink` (rec.; finale-f1/01) vs a per-colour dark outline (finale-f1/07 brown). Rec. navy everywhere except the yellow CTA.
4. **Card colour:** rarity colour (rec.; robloxf1-v2/06, finale-f1/10) vs per-creature colour (finale-f1/03). Cost: lower per-species variety.
5. **Rarity tier count and names:** not given by the pins.

## Owner decisions (2026-10-27, popup after mocks)
- Mocks `design/hud-v2-mocks/mock-1..4` **approved**; build approved (icon set first, then re-skin on a copy; no publish without approval).
- Label font: **slanted comic (Bangers)** for button/CTA labels, overriding the FredokaOne rec. Numbers/small text still FredokaOne; LuckiestGuy for reward titles.
- Panels: blue everyday, purple for reward/rare moments.
- Creature cards: coloured by rarity. Tier count/names still open.
- **Icon set approved 2026-10-27:** 17 transparent 512 PNGs in `design/hud-v2-icons/` (Higgsfield GPT Image 2.5 high, style refs cc2/01 + finale-f1/01, ~25.5 credits; raw 1024 in `raw/`, sheet via `build_sheet.py`). Not uploaded to Roblox.
