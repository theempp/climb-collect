# Glassbloom HUD intel (atlas, P1, 2026-10-27; audit revision 2026-10-28)

> **STOP 1 approved by the owner (popup, 2026-10-28):** token set approved as written. Uploads: 11 PNGs (U1–U6, U8–U11; U7 fallback ring held back; one 20-ray image). Touch targets (G1): keep drawn sizes, invisible hit areas ≥ 44 px trimmed at the midpoint between close neighbours (side tabs 39, wrapped chips 33); audits check the hit areas. Timings (G4): board text wins (XP line 1.5 s, carry pop-up in at 0.35 s, rail label fades after 3 s); the CSS supplies easing shape only.

**Sources only:** board `design/hud-board-v3/index.html` (cited `L###`), `design/vfx-ui-intel-2026-10-27.md` (`I`), build plan `climb-collect-integration/design/hud-glassbloom-build-plan-2026-10-27.md` (`P§`), owner decision record `climb-collect-integration/design/hud-v2-handoff-2026-10-27.md` (`H`), and `Theme.luau` for legacy key names. Colours are exact CSS values, not image samples. Px values are the board's 844×390 frame (HUD scale M). **est.** = my own arithmetic from the CSS, not a value the board prints. Assets: 17 icons in `hud-board-v3/icons/` (bat, calendar, chest, climb, coin, creature, egg-cracked, egg, gear, gem, gift, heart, jump, map, padlock, scroll, sprint), which match `Theme.icons`. `bg/` (bg-mountain.jpg, bg-sanctuary.jpg) holds board backdrops only. The independent audit (`evidence/hud_glassbloom_2026-10-27/p1_intel_verification.json`, 81 issues) is dispositioned in §8.

**Conversions used throughout**
| CSS | Roblox |
|---|---|
| alpha `a` | `BackgroundTransparency`/`ImageTransparency`/`TextTransparency` = 1−a |
| `linear-gradient(θ)` | `UIGradient.Rotation` = θ−90 (180°→90, 90°→0, 100°→10, 110°→20, 135°→45) |
| `-webkit-text-stroke:N` + `paint-order:stroke fill` (L150, L163, L346) | `UIStroke` (Contextual) Thickness **N/2**: only the outer half shows |
| `border` with `box-sizing:border-box` (L4) | border sits **inside** the box. UIStroke draws outside the edge, so inset the frame by the thickness (or use an inner stroke position if the engine has one; verify P3). Containment measures the outer edge |
| pill height | line-height + 2×border when the height is auto. A `font:` shorthand with no `/lh` resets line-height to `normal` (≈1.2×, est.), not body's 1.5 (L5) |
| `box-shadow:0 0 Bpx [S] C` (outer glow) | **hollow** U1, size = element + 2(B+S), `SliceScale` = B/32, tint C. Spread S > 0 adds a UIStroke S in C. CSS never paints an outer shadow under the element, so the U1 centre is transparent |
| `box-shadow:0 Ypx 0 C` (lip) | opaque body: same-shape Frame behind, +Y. **Translucent body** (glass, bat orb, ghost, reveal cards): the lip Frame sits inside a ClipsDescendants holder spanning y H…H+Y, so it never shows through the body. Cost: the crescents beside rounded bottom corners above y=H are lost |
| `radial-gradient` inside a rect | U11 (linear falloff) inside a ClipsDescendants Frame |
| `border-radius:50%` | `UICorner` (0.5, 0) |
| `opacity` on a group | per-child transparency (recommended, no extra render cost) or `CanvasGroup.GroupTransparency` |
| Luau keys | dotted doc names become flat camelCase keys (`gold.hi` → `goldHi`, `glass.from` → `glassFrom`). Gradients get the prefix `grad` (`gradCta`), glows `glow` (`glowGlass`). Radii/strokes/text sizes live in sub-tables `r`, `s`, `t`. Doc token `ink` becomes Luau **`outline`** (see 1j) |

---

## 1. Theme tokens

### 1a. Colours
**Rule:** the board's token table (L566–575, headed "Value (est.)") conflicts with the CSS in four places: glass #2B1757 → #4B2A9A (L567), edge #6E45C8 (L568), "Reward gold" #FFD84A → #F59A00 (L572: no CSS gradient uses this pair; the gold title is #FFE07A → #F59A00, L214), and danger #FF4D7D as the edge vignette (L570; the CSS vignette is #FF3C78, L139). **The CSS wins**, the same rule as D12 (fonts, L575). The table-only hexes are listed under do-not-build.
| Token | Hex | Used for | Source |
|---|---|---|---|
| `pk` | #F46BC4 | action pink: XP fill, node on, toggle on, scrollbar, pink glows, lv badge | L3, L45, L105, L114 |
| `vi` | #A55BEA | action violet: second stop of every pink gradient | L3, L45 |
| `ctaHi` | #FF8FE0 | top stop of the CTA/orb/active-tab/seg gradients | L55–56, L184, L320 |
| `flare` | #7BD8FF | third ring stop; glow of the 2nd sparkle (`.d2`) | L3, L41, L49 |
| `sparkle.pink` | #F78AD0 | glow of sparkles 1 and 3 (default `.tw`; `.d3` only adds a delay) | L41, L548 |
| `text` | #FFFFFF | all HUD/menu text, focus ring | L35, L45, L48 |
| `ink` (Luau `outline`) | #150A33 | card outline, text shadow, reveal card outline | L3, L62, L200, L331 |
| `deep` | #2B1457 | ring inner disc, nodes, level hex | L50, L65, L104, L113, L284 |
| `night` | #0A0228 | wells, tracks, rows, tabs, lip shadow, FOREVER pill (rgba 10,2,40) | L47, L51, L183, L277, L311 |
| `night2` | #14063C | pills: rail label, distance, moment sub, ghost btn (rgba 20,6,60) | L57, L108, L128, L151 |
| `shade` | #14053C | menu tint end (rgba 20,5,60) | L47, L178 |
| `lip` | #5A2299 | CTA/orb lip, display text shadow, moment stroke | L55–56, L146, L150 |
| `lipDeep` | #3A0A6A | moment/reveal word drop | L150, L346 |
| `glass.from` | #8246DC | glass fill top (rgba 130,70,220) | L47 |
| `glass.to` | #32146E | glass fill bottom (rgba 50,20,110) | L47 |
| `glass.rim` | #FFD2FF | glass border (rgba 255,210,255) | L47 |
| `pinkText` | #FFD0F0 | banner kicker, section headers, reveal chance, 2nd halo | L145, L193, L335, L351 |
| `lavText` | #CBBCF2 | section-header note | L195 |
| `segText` | #CDBDF5 | segmented control off text | L320 |
| `togOff` | #8B7FB5 | toggle knob off | L322 |
| `danger` | #FF4D7D | red dot, X glow | L3, L115, L181 |
| `danger.rim` | #FF7AA0 | awake-pill border | L164 |
| `vignette` | #FF3C78 | chase edge glow (rgba 255,60,120) | L139 |
| `close.from` / `close.to` / `close.lip` | #FF7A9A / #D92B55 / #7A1030 | menu X | L181 |
| `run.top` / `run.mid` / `run.bot` | #FFFFFF / #FFD6EA / #FF5C9E | RUN! text gradient | L163 |
| `run.stroke` / `run.drop` / `run.glow` | #5A1050 / #3A0A36 / #FF3D85 | RUN! stroke, drop, glow (also the shock glow) | L163, L167 |
| `run.shock` | #FF7AB8 | shock ring | L167 |
| `run.awakeBg` | #3C061E | "IS AWAKE" pill (rgba 60,6,30) | L164 |
| `go` | #7BFFD0 | safe/secured: distance ring, edge-arrow rim, beacon, ladder progress, boost ring, Robux buy top | L3, L126–133, L248, L283 |
| `go2` | #2FAE8A | mint gradient bottom | L3, L123, L242 |
| `go.glow` | #5DFFC0 | sprint/buy glow, done rung (rgba 93,255,192) | L123, L242, L251, L282 |
| `go.lip` | #14664D | sprint/Robux lip + text shadow | L123, L242 |
| `go.ink` | #06281E | wallet "+" text, beacon label bg | L133, L221 |
| `go.text` | #EAFFF6 | edge arrow text | L129 |
| `gold` | #FFD84A | summit node, tag, FOREVER text, ready rung, reveal selector/halo | L3, L106, L231, L252, L333–334 |
| `gold.hi` | #FFE07A | gold title + coin buy top | L214, L245 |
| `gold.lo` | #F59A00 | gold title bottom | L214 |
| `gold.buyLo` | #F0A020 | coin buy bottom | L245 |
| `gold.lip` | #8C4A1C | gold lip and text shadow | L214, L245 |
| `gold.tail` | #B86A00 | ribbon tails | L216 |
| `gold.ink` | #4A230E | text on gold (tag, burst) | L231, L270 |
| `gold.text` | #FFE9A8 | coin-pack amount, reveal title | L266, L328 |
| `moment.text` | #FFE45C | moment / reveal word | L150, L346 |
| `rays.tint` | #FFD678 | panel and reveal rays (rgba 255,214,120) | L212, L327 |
| `rays.hero` | #FFE878 | hero rays (rgba 255,232,120) | L223 |
| `ribbon.from` / `ribbon.to` / `ribbon.ink` | #FF5C9E / #FFD84A / #3A0A36 | BEST VALUE ribbon | L268 |
| `holo` (7 stops) | #FF4D8D, #FFB52E, #FFF35C, #52E07A, #3FC8FF, #9A5CF0, #FF4D8D | hero border | L207 |
| `hero.from` / `hero.to` | #5A1EAA / #280C64 | hero inner; violet stop of the egg plinth | L222, L292 |
| `cpk.from` / `cpk.to` | #5A28A0 / #280C64 | coin pack | L262 |
| `ticket.from` / `ticket.to` | #FF8C3C / #6E1E8C | daily ticket | L256 |
| `mtint.from` / `mtint.to` | #3C1478 / #14053C | menu backdrop tint | L178 |
| `bat.fill` / `bat.lip` | #28105A / #1B0D45 | bat orb | L124 |
| `card.fallback` | #3A2A66 | unknown / locked card | L200, L205 |
| `card.glow` | #D49BFF | violet/prism card glow | L206 |
| `card.xpFull.from` / `.to` | #7BFFB0 / #35C27A | maxed card XP | L611 |
| `reveal.bgIn` / `reveal.bgOut` | #6A2AB0 / #1D0A45 | reveal backdrop | L326 |
| **Do not build: board token table only** | #2B1757, #4B2A9A, #6E45C8 | estimated table values, superseded by the CSS | L567–568 |
| **Do not build: page chrome / zones** | #0B1022, #121a36, #F2F5FF, #A3B0D2, #FFD23C, #FFC414, #05070F, #223363, #34467E, #141D3C, #CFD8F5, #2A3566, #1B2547, #263A74, #16473A, #4A3A12, #4A1222, #8E97B8, #5E6788, #C5C9D1 + rgba(170,175,185), #FF8AA0, #2A0010, #06122B, zone #7BD8FF fill, #DFE2E8, rgba(36,38,44), #E3E6EA, #30343C@.82 (Roblox placeholder), #FF6B88 (`--fail`), #C9B8F5 (`--lav`, defined, unused). The `--pass` variable is chrome, but its hex #5DFFC0 **is** the game token `go.glow` | L3, L9, L11, L20, L26–33, L45, L81–93, L360–364, L373, L587 |
| **Do not build: Before controls only** | #FF9BDD (`.dockb.on`), #8FB2FF (old gcard), #FF5082 (`.alert` glow; the alert chip merged into RUN!, L415) | L54, L58, L451, L488 |

### 1b. Rarity (6 tiers → 4 colours): owner decision
Tier → colour assignment: **owner decision, 2026-10-27** (H L9: "rarity = keep 6 tiers mapped to 4 colours (Common/Uncommon blue, Rare gold, Epic purple, Mythic/Legendary prismatic)"). The board's "6 tiers mapped to 4 colours" comes from L573 and EPIC = violet from L342 + L545–546. P2 check: the tier names must match the server roll table.
| Key | Tiers | `rc` (rim/glow/odds) | `rcg` gradient | Source |
|---|---|---|---|---|
| `rarity.blue` | Common, Uncommon | #6C8CF0 | 180°: #9FB6FF → #5B78E8 | L74, L613, H L9 |
| `rarity.gold` | Rare | #F7A21B | 180°: #FFD27A → #F0952A | L75, L613, H L9 |
| `rarity.violet` | Epic | #B06CF0 | 180°: #C99BFF → #8A4BE6 | L76, L613, H L9 |
| `rarity.prism` | Mythic, Legendary | #FFB8EA | 135° (Rot 45): #FF8FC0, #FFD27A, #7BD8FF, #B58CFF | L77, L613, H L9 |
Odds-bar labels: Blue / Gold / Violet / Prismatic (L613). The legacy `Theme.rarity` hexes are superseded (1j).

### 1c. Transparencies (CSS alpha → Roblox T)
| Token | α → T | Use | Source |
|---|---|---|---|
| `glass.fillT` | .55→**.45** (top), .62→**.38** (bottom) | UIGradient Transparency on the glass fill | L47 |
| `glass.rimT` | .55→.45 | glass UIStroke | L47 |
| `glass.hiT` | .35→.65 | 2 px top highlight | L47 |
| `glass.lipT` | .6→.4 | lip | L47 |
| `glass.glowT` | .35→.65 | pink outer glow | L47 |
| `ghost.T` | fill .7→.3 · rim .4→.6 · lip .7→.3 | ghost button | L57 |
| `well.T` | .5→.5 tab/chip · .45→.55 row · .55→.45 bst/scroll track/hlist · .6→.4 rung/seg · .65→.35 trail preview · .7→.3 xp/sl/tog/tm · .75→.25 FOREVER | `night` fills | L51, L183, L191, L197, L233, L235, L249, L277, L281, L298, L311, L315, L319, L321 |
| `pill.T` | .85→.15 rail label · .92→.08 distance · .8→.2 moment sub | `night2` pills | L108, L128, L151 |
| `pill.T` (other fills) | .78→.22 beacon label (`go.ink`) · .85→.15 awake (`run.awakeBg`) | coloured pills | L133, L164 |
| `dbtn.T` | fill .1→.9, rim .3→.7 | dock buttons | L111 |
| `ring.trackT` | .16→.84 XP · .2→.8 distance · .18→.82 boost | ring track | L112, L126, L283 |
| `dock.chaseT` | opacity .25 → group T **.75** | chase dock | L134 |
| `rail.idleT` | opacity .3 → group T **.7** | rail at rest | L101 |
| `text.dimT` | .95→.05 · .9→.1 · .85→.15 · .82→.18 · .75→.25 | secondary text (replaces the 500/600 weights) | L160, L174, L258, L260, L267, L276, L286, L306, L313 |
| `vignette.T` | .55→.45 at the colour end | chase glow | L139 |
| `tint.T` | .5→.5 → .75→.25 | menu tint | L178 |
| `rays.T` | .09→.91 panel · .24→.76 hero · .28→.72 reveal | rays image | L212, L223, L327 |
| `reveal.dimT` | opacity .12 → T **.88** on land | band, track, selector | L345 |

### 1d. Corner radii (UICorner offset). §2 cites board values; UICorner caps any radius ≥ h/2 to a pill
| Token | px | Elements | Source |
|---|---|---|---|
| `r.circle` | 50 % | orbs, dock buttons, gear, rings, nodes, X, porb, cpic, egg plinth (ellipse), shock, halos | L49, L55, L100, L104, L111, L126, L157, L167, L181, L274, L283, L292, L334 |
| `r.panel` | 22 | menu panel | L179 |
| `r.banner` | 24 | banner | L144 |
| `r.pill30` | 30 | dock, carry pop-up | L110, L156 |
| `r.hero` | 20 | hero outer, panel rays clip | L207, L211 |
| `r.glass` | 18 | glass default, coin pill, edge, pcard, egg card, reveal selector/card | L47, L98, L129, L170, L288, L333, L342 |
| `r.btn` | 16 | CTA, title, toast, wallet, rung, coin pack, hero inner, skin, toggle | L56, L141, L180, L219, L222, L249, L262, L297, L321 |
| `r.card` | 14 | creature card, ticket, row, reveal strip card | L200, L256, L311, L331 |
| `r.12` | 12 | chip, seg, trail preview, awake pill | L164, L197, L298, L319 |
| `r.11` | 11 | tab, rail label | L108, L183 |
| `r.10` | 10 | beacon label, list pill, moment sub, reveal rarity pill | L133, L151, L233, L351 |
| `r.9` | 9 | tag, timer pill | L231, L235 |
| `r.8` | 8 | distance pill, FOREVER | L128, L277 |
| `r.7` | 7 | lv badge, wallet "+" | L114, L221 |
| `r.6` | 6 | XP track, slider track, beacon pillar, streak | L51, L132, L300, L315 |
| `r.5` | 5 | XP fill, slider fill | L52, L316 |
| `r.4` | 4 | XP line, odds bar, scrollbar track/thumb | L116, L191–192, L308 |
| `r.3` | 3 | rail line | L102 |
| `r.2` | 2 | ladder track, odds legend swatch | L248, L310 |
| `r.shield` | 20 20 50 50 | pass card → 9-slice U3 | L273 |
| `r.roundTop` | 60 60 18 18 | boost card → 9-slice U4 | L281 |

### 1e. Stroke widths (UIStroke Thickness)
| Token | px | Elements | Source |
|---|---|---|---|
| `s.hair` | 1 | list pill, odds bar | L233, L308 |
| `s.thin` | 1.5 | dock button, tab, chip, XP/slider/seg/toggle, row, rung, bst, egg card, rail label, distance, beacon label, awake, lv | L51, L108, L111, L114, L128, L133, L164, L183, L197, L249, L281, L288, L311, L315, L319, L321 |
| `s.glass` | 2 | glass rim, nodes, dot, carry inner disc, buy, coin pack, wallet "+", ticket inset ring, ghost/pbtn/×3 (border-width override) | L47, L104, L115, L127, L221, L242, L246, L256, L262, L307 |
| `s.bold` | 3 | orb, CTA, X, card, carry pop-up, cpic, porb, egg, skin, pass, reveal strip card/band, 2nd reveal halo | L55, L56, L156, L157, L181, L200, L273, L274, L290, L297, L329, L331, L335 |
| `s.ring3` | 3 | ring thickness: dock XP ring, pcard ring | L49, L112 |
| `s.ring4` | 4 | ring thickness: carry distance ring, boost timer ring | L126, L283 |
| `s.reveal` | 5 | reveal selector, result card | L333, L342 |
| `s.ring6` | 6 | shock ring, 1st reveal halo | L167, L334 |
| `s.text` | 3 (CSS 6) · 4.5 (CSS 9) | moment and reveal word · RUN! | L150, L163, L346 |
| `s.focus` | 2 white, 2 px outside the control | focus ring on every button (gamepad selection) | L35 |

### 1f. Gradient stops (Luau `grad*`)
| Token | Rotation | Stops | Source |
|---|---|---|---|
| `glass` | 90 | #8246DC T.45 → #32146E T.38 | L47 |
| `cta` | 90 | #FF8FE0 → #A55BEA | L55–56, L184 (tab uses 0), L320 |
| `action` | 0 | #F46BC4 → #A55BEA | L52, L117, L316, L323 |
| `gloss` (overlay) | 90 | white T.5 at 0–.36, T1 from .38 (hard step) | L56, L214, L242 |
| `ring.conic` | — | #F46BC4 → #A55BEA → #7BD8FF → #F46BC4 (conic; a linear UIGradient on the stroke only approximates it) | L49 |
| `mint` | 90 | #7BFFD0 → #2FAE8A | L123, L221, L242 |
| `coinBuy` | 90 | #FFE07A → #F0A020 | L245 |
| `goldTitle` | 90 | #FFE07A → #F59A00 | L214 |
| `close` | 90 | #FF7A9A → #D92B55 | L181 |
| `run` | 90 | #FFFFFF 0 → #FFD6EA .38 → #FF5C9E 1 | L163 |
| `holo` | 20 | 7 stops evenly spaced, `background-size:240%`, repeating, animated to −240 % (L208). **Recipe (est., verify P3):** UIGradient can't tile, and an Offset beyond ±1 clamps to the end colour. Use an inner Frame 4.8× the hero width carrying two cycles (13 keypoints at i/12; ColorSequence allows ≤20), tween Position.X 0 → −2.4W over 5 s linear, then reset. Clip it with a CanvasGroup + UICorner 20 (rounded clipping to be verified). Rotation 20 is in normalised space, so on a 4.8×-wide frame the visual angle differs (verify) | L207–208 |
| `ribbon` | 0 | #FF5C9E → #FFD84A | L268 |
| `railLine` | 90 | white T.2 → T.8 | L102 |
| `beaconPillar` | 90 | #7BFFD0 T.05 → T1 | L132 |
| `hero` | 90 | #5A1EAA T.03 → #280C64 T.02, plus a gold radial T.65 at 16 %/60 % fading by 45 % (U11) | L222 |
| `cpk` | 90 | #5A28A0 T.15 → #280C64 T.08, plus a gold radial T.68 at 50 %/30 % fading by 60 % (U11) | L262 |
| `ticket` | 10 | #FF8C3C T.5 → #6E1E8C T.25 | L256 |
| `pass` | 90 | white T.86 → #14063C T.12 | L273 |
| `skin` | 90 | white T.9 → #0A0228 T.22 | L297 |
| `eggCard` | 90 | white T.92 → #0A0228 T.35 | L288 |
| `cpopOverlay` | 90 | white T.78 → #14063C T.45, over `rcg` | L156 |
| `mtint` | 90 | #3C1478 T.5 → #14053C T.25 | L178 |
| `cardXpFull` | 0 | #7BFFB0 → #35C27A | L611 |
| `shard` | 45 | #FFFFFF → #FFD84A | L338 |
| `revealPill` | 0 | #C99BFF → #8A4BE6 | L351 |
| `streak` | 0 | T1 → `rc` | L300 |
| `shine` | 0 | white T1 → T.25 → T1 | L243 |

### 1g. Glows (hollow U1: tint, T, blur B, spread S)
| Token | Colour | T | B | Source |
|---|---|---|---|---|
| `glow.glass` | #F46BC4 | .65 | 18 | L47 |
| `glow.cta` | #F46BC4 | .3 | 18 | L56 |
| `glow.orb` | #F46BC4 | .2 | 20 | L55 |
| `glow.bat` | #F46BC4 | .4 | 12 | L124 |
| `glow.sprint` | #5DFFC0 | 0 | 14 | L123 |
| `glow.buyRobux` / `glow.buyCoin` | #5DFFC0 / #FFD84A | .5 | 12 | L242, L245 |
| `glow.pbtn` | #F46BC4 | .5 | 10 | L307 (overridden by the ghost on its only instance, see pbtn) |
| `glow.portrait` | #7BFFD0 | .45 | 14 | L126 |
| `glow.beacon` | #7BFFD0 | .2 | 18 | L132 |
| `glow.x` | #FF4D7D | 0 | 12 | L181 |
| `glow.tabOn` | #F46BC4 | .4 | 12 | L184 |
| `glow.shop` | #FFD84A | .65 | 26 | L210 |
| `glow.goldTitle` | #FFD84A | .3 | 18 | L214 |
| `glow.rarity` | `rc` | 0 | 26 pop-up · 14 cpic/pass · 16 porb · 20 egg · 12 skin · 10 streak | L156, L157, L273, L274, L290, L297, L300 |
| `glow.ready` / `glow.best` | #FFD84A | .45 / .3 | 14 / 16 | L252, L263 |
| `glow.boostOn` | #5DFFC0 | .55 | 14 | L282 |
| `glow.cardRare` | #D49BFF | 0 | 14, S 2 | L206 |
| `glow.hero` | #FFFFFF | .55 | 18 | L207 |
| `glow.moment` | #F46BC4 | 0 | 18 (drop-shadow on text → optional U1 behind) | L150 |
| `glow.run` | #FF3D85 | 0 | 26 (drop-shadow on text → optional U1 behind) | L163 |
| `glow.shock` | #FF3D85 | 0 | 20 outer. The inset 20 glow is not ported | L167 |
| `glow.sparkle` | #F78AD0 (1, 3) / #7BD8FF (2) | 0 | 8 | L41, L548 |
| `glow.revealSel` | #FFD84A | 0 | 18 outer. The inset 12 @ .5 is not ported | L333 |
| `glow.halo` | #FFD84A | 0 | 24 | L334 |
| `glow.revealCard` | #FFD84A | .15 | 34, S 8 | L342 |
| `glow.revealTitle` | #F46BC4 | 0 | 16 (text-shadow → optional U1) | L328 |
| `glow.heroTitle` | #FFD84A | .45 | 14 (text-shadow → optional U1) | L230 |
| Text-shadow glows below 16 (`.tx` pink 8, L48; cpt white .4 14, L159) | — | — | not ported (W.text) | L48, L159 |

### 1h. Fonts (Luau `fontDisplay`, `fontBody`. **Never** use legacy `T.display`, which is FredokaOne)
| Role | Board face (CSS) | Roblox | Notes | Source |
|---|---|---|---|---|
| `font.display` "LG" | Luckiest Guy 400 | `Font.fromName("LuckiestGuy")` / `Enum.Font.LuckiestGuy` | exact family. Titles, banner, moment, RUN!, reveal word/title/name, menu title, ticket/coin-pack/pass/egg names, prices. **Creature-card, boost and skin names are body** (L203, L285, L304) | L3, L146, L150, L163, L230, L257, L266, L275, L293, L328, L346, L350 |
| `font.cta` "LG" | Luckiest Guy (`.btn` uses `--display`) | LuckiestGuy | D12: follow the CSS. Board token row L575 says "Bangers (CTA labels)" | L56, P§11 |
| `font.body` "FO" | Fredoka 500/600/700 (variable) | `Font.fromName("FredokaOne")` / `Enum.Font.FredokaOne` | single weight: 500/600/700 collapse, so contrast comes from size and `text.dimT` | L1, L3, L45 |
| — | Bangers | `Enum.Font.Bangers` exists | **board chrome only** (`.kick`, L11). Not used in game | L3, L11 |
| — | system-ui fallbacks | none | not needed | L3 |
| Tracking (`letter-spacing` .02–.3em) | kickers, pills, titles | **no Roblox equivalent known** | gap G16 | L56, L145, L158, L159, L163, L164, L193, L195, L231, L268, L277, L328, L350 |
| `tabular-nums` | coin, wallet, timers, pct | none for FredokaOne | gap G17 | L98, L219, L235, L254, L318 |

### 1i. Text sizes (px at scale M = board). Scope **H** = under the HUD root: S/L = M × `hud.scaleS`/`hud.scaleL` (G2), one UIScale on the HUD root (P§7). **Mn/R/W** = menu, reveal, billboard: M only, never HUD-scaled. Large text applies everywhere via `T.size` (P§7)
| Role key | M px | Face | Scope | Source |
|---|---|---|---|---|
| `t.run` | 104 | LG | H | L163 |
| `t.moment` · `t.revealWord` | 64 · 62 | LG | H · R | L150, L346 |
| `t.carryName` · `t.revealTitle` | 30 · 30 (26 landed) | LG | H · R | L159, L328, L356 |
| `t.bannerTitle` | 28 | LG | H | L146 |
| `t.heroTitle` | 24 (mini 18) | LG | Mn | L230, L240 |
| `t.revealCta` | 24 | LG | R | L353 |
| `t.menuTitle` | 23 | LG | Mn | L180 |
| `t.revealName` | 22 | LG | R | L350 |
| `t.btn` · `t.heroBuy` | 20 · 20 | LG | Mn | L56, L236 |
| `t.coinPack` | 19 | LG | Mn | L266 |
| `t.ticketTitle` | 18 | LG | Mn | L257 |
| `t.btnSide` · `t.buy` · `t.eggName` | 16 | LG | Mn | L186, L242, L293 |
| `t.buy3` · `t.pbtn` · `t.passName` | 15 | LG | Mn | L246, L275, L307 |
| `t.claim` | 13 | LG | Mn | L255 |
| `t.coin` | 15 | FO | H | L98 |
| `t.pcardMeta` · `t.rowTitle` · `t.revealChance` | 14 | FO | H · Mn · R | L173, L312, L351 |
| `t.toast` · `t.edge` · `t.awake` · `t.momentSub` | 13 | FO | H | L129, L141, L151, L164 |
| `t.tab` · `t.wallet` · `t.bstName` · `t.skinName` · `t.lvh` | 13 | FO | Mn | L65, L183, L219, L285, L304 |
| `t.beacon` | 12 | FO | W | L133 |
| `t.chip` · `t.seg` · `t.pct` · `t.cardName` | 12 | FO | Mn | L197, L203, L318, L319 |
| `t.railLabel` · `t.carryHint` | 11.5 | FO | H | L108, L160 |
| `t.smallHud` (banner kicker, carry kicker, distance, pcard sub) | 11 | FO | H | L128, L145, L158, L174 |
| `t.small` (sh, list, timer, rung, ticket desc, was-price, pass desc, ba, note, odds legend, burst, row desc) | 11 | FO | Mn | L193, L233, L235, L254, L258, L260, L270, L276, L278, L306, L309, L313 |
| `t.micro` (coins label, bst/skin desc) | 10.5 | FO | Mn | L267, L286, L305 |
| `t.lv` | 10 | FO | H | L114 |
| `t.tag` · `t.ribbon` | 10 | FO | Mn | L231, L268 |
| `t.forever` | 9.5 | FO | Mn | L277 |
| `t.close` · `t.plus` · `t.cardArt` · `t.eggQ` | 20 · 15 · 30 · 30 | FO/FO/FO/LG | Mn | L181, L221, L201, L290 |
Fractional sizes (11.5, 10.5, 9.5): verify how Roblox renders them in P3. Large text: the board has only the toggle (L644), no increment. The legacy `T.size` (+2) path stays per P§7; it is not a board value.

### 1j. Legacy `Theme.luau` key → new token (aliases, P§3)
**Name clashes.** Legacy `card`, `gold`, `close` and `ink` are Color3 values and `cta` is a table, so a Luau key can't also be a sub-table. The camelCase rule (`goldHi`, `cardFallback`, `closeFrom`, `gradCta`) resolves this, and every legacy key below stays as a flat alias. `T.ink` stays **white** (legacy meaning = `text`). The doc's `ink` (#150A33) becomes Luau `outline`. `T.display` stays FredokaOne for legacy callers, and new code uses `fontDisplay` / `fontBody`. `T.rarity[tierName]` stays (= `rc` of the mapped colour), and the new colours go in `T.rarityColor.<blue|gold|violet|prism> = {rc, from, to}`.
| Legacy | → | Note |
|---|---|---|
| `navy` | `deep` | |
| `panel`, `panelBlue` | `glassFrom` | |
| `panelPurple` | `glassTo` | |
| `card` | `cardFallback` | Color3 alias |
| `sky` | `flare` | |
| `blue` | `rarityColor.blue.rc` | |
| `gold`, `coin`, `bar.max` | `gold` | Color3, value → #FFD84A |
| `green`, `readyDot`, `plus` | `go` | |
| `purple`, `gem` | `vi` | |
| `tert` | `rarityColor.violet.rc` | role guess; check call sites |
| `coral`, `alertDot`, `heart` | `danger` | |
| `ink` | `text` (#FFFFFF) | legacy meaning kept |
| `line`, `outline` | `outline` (#150A33) | doc token `ink` |
| `muted` | `lavText` | |
| `row` | `night` + `well.T` .55 | was a light fill, now dark. `textDark` callers flip to white |
| `textDark`, `cta.ink` | `text` | Glassbloom text is white on CTA and rows |
| `cta.base` / `cta.shade` / `cta.lip` | `ctaHi` / `vi` / `lip` | `cta` stays a legacy table; new gradient = `gradCta` |
| `ok.base` / `ok.lip` | `go` / `go.lip` (`goLip`) | |
| `no.base` / `no.lip` / `close` | `closeFrom` / `closeLip` / `closeTo` | `close` stays a Color3 alias |
| `alt` | `night2` (ghost) | |
| `off` | `togOff` | |
| `bar.fill` / `bar.ready` | `gradAction` / `gradCardXpFull` | |
| `label`, `title` | `fontDisplay` (LuckiestGuy) | `label` was Bangers; D12 changes it |
| `display`, `body`, `bold` | FredokaOne (= `fontBody`) | `display` keeps its legacy value |
| `rarity.*`, `prismatic` | §1b map | |
| `icons` | unchanged | |

---

## 2. Component map (Roblox primitives; board px)
**HUD states** (F builders, L625–628; bg images are board-only)
| State | Builders | Source |
|---|---|---|
| rest | rail, tr, dock, orbs(bat) (+ toast/banner/moment replays on the board) | L625 |
| carry | beacon, rail, tr, dock, orbs(bat), carry portrait, carry pop-up | L626 |
| chase | vignette, rail, tr, dock(chase), orbs(bat), carry portrait, edge arrow, RUN! | L627 |
| sanctuary | tr, dock, orbs(**no bat**), player card, toast. **No rail** | L432, L628 |

**Shared recipes**
| Recipe | Primitives | Source |
|---|---|---|
| `W.glass` | Frame (white, BT 0) + UIGradient `glass` + UICorner (`r.glass` unless noted) + UIStroke 2 `glass.rim` T.45 + highlight Frame 2 px at y 2, x from r to W−r, white T.65 + **clipped lip** (translucent body; strip y H…H+5) `night` T.4 + optional hollow `glow.glass`. **No blur.** The inset bottom shade (L47 `0 -10px 20px`) is not ported (recommended; it's a 40 % shade over the dark end stop). About 8 instances | L47, P§2 |
| `W.glass` variants | shop: rim `gold` T.2, `glow.shop` · banner: rim white · edge: rim `go` | L129, L144, L210 |
| `W.ring(d, t, fill, trackT, inner)` | The ring occupies the outer t px **inside** d (L112, L126). Track: circle Frame **(d−2t)** centred + outer UIStroke t (white, trackT). Progress: two half-clip Frames (d/2 × d, ClipsDescendants), each holding a centred (d−2t) circle Frame with an outer UIStroke t in `fill`, and a UIGradient under the stroke with a hard Transparency step {0:0, .5:0, .501:1, 1:1}, Rotation 0→180 per half (P0 verified). Inner disc (d−2t). Alternative: d×d circles with an Inner stroke position, if P3 verifies one | L112–113, L126–127, L283–284, P§2 |
| `W.orb` | circle Frame + UIGradient (`cta`/`mint`) + UIStroke 3 white + full lip Frame (opaque body) + hollow glow + **gloss** U8 + icon ImageLabel. `gloss=false` and a clipped lip for flat translucent orbs (bat) | L55, L123, L124 |
| `W.cta` | Frame r16 + UIGradient `cta` + gloss overlay Frame (same radius, UIGradient `gloss`) + UIStroke 3 white + lip `lip` 6 + `glow.cta` + TextLabel LG 20, drop label +2 y `lip` | L56 |
| `W.ghost` | Frame `night2` T.3, **UIStroke 2** white T.6 (both board instances override border-width to 2: ×3 L246, Reset L307), clipped lip `night` T.3 5 | L57, L246, L307, L618, L646 |
| `W.text` (.tx) | white TextLabel + drop label 0 2 `ink` T.2. The pink 8 px text glow can't be ported. Recommended: drop labels on display text only (≤6 on screen per P§2) and a 1 px `ink` T.2 UIStroke on body text. Cost: an outline instead of a downward shadow | L48, P§2 |
| `W.pill(h, padX, fill, T, stroke)` | Frame (UICorner = board radius) + UIStroke + UIPadding + TextLabel. h = line-height + 2×border | L108, L114, L128, L133 |
| focus | `GuiObject.SelectionImageObject` or a UIStroke Frame 2 px outside: 2 white (`s.focus`) | L35 |

**HUD builders (`B.*`)**
| Builder | Anchor / position (844×390) | Size | Primitives & parts | Source |
|---|---|---|---|---|
| `B.tr` coin + gear | AP(1,0), (1,−12, 0,7) | h 44. Box ≈155×44 **est.** | UIListLayout H, gap 8, right. **Coin pill**: `W.glass` h 34 r18 (pill), UIPadding L38 R14, value FO 15. Coin icon 40 at x −2, centred y. **Gear**: `W.glass` circle 44, icon 26 | L97–100, L594 |
| `B.rail` altitude rail | (0,14, 0,70), bottom at 48 % + 10 from the screen bottom | w 22 (h 122.8 at 844, 91.6 at 749) | container group T.7 idle. Line Frame x9, inset 4 top/bottom, w 4 r3, `railLine`. Nodes: UIListLayout V, VerticalFlex SpaceBetween. **Node** 12 circle `deep` + UIStroke 2 white. On: `pk` + glow 10. Summit: 15 `gold`. D10: 6 section nodes + 1 summit. Hidden in the sanctuary | L101–106, L432, L628, P§11 D10 |
| rail label (transient) | (0,42, .26,20) | **h 25** (22+3) | `W.pill`(25, 9, `night2`, .15, 1.5 `pk`), r11, FO 11.5, "Checkpoint 2 · 320 m" | L108, L595 |
| `B.dock` | AP(.5,1), (.5,0, 1,−10) | 250×58 **est.** (5 btn). Chase: 154×58 **est.** | `W.glass` r30, UIPadding 6, UIListLayout H gap 6. **Btn** 42 circle white T.9 + UIStroke 1.5 white T.7. Icons 28: creature, map, chest, calendar, scroll (Creatures, Map, Shop, Daily, Quests). **Creatures** = `W.ring(42,3,pk,.84,deep)` + **lv badge** pill h 16 (13+3), bottom −5 centred, `pk`, stroke 1.5 white, FO 10, r7. **Daily dot** 13 circle `danger` + stroke 2 white at (−2,−2) top-right. **Chase**: buttons 4–5 hidden, group T.75 | L110–115, L134–135, L596 |
| XP line (transient) | AP(.5,1), (.5,0, 1,−72) | 236×6 | track Frame **r4** (pill) `night` T.3, fill Frame `action` | L116–117 |
| `B.orbs` jump | — | — | **not built** (D5: native jump). The board orb at right 16 / bottom 16, 70×70, is the reference obstacle | L122, P§11 D5 |
| sprint orb | AP(1,1), (1,−96, 1,−20) | 54 | `W.orb` `mint` + gloss, `glow.sprint`, lip `go.lip` 5, icon 32 | L123, L597 |
| bat orb | AP(1,1), (1,−20, 1,−96) | 52 | `W.orb` **flat, no gloss** (L124 replaces the L55 background), `bat.fill` T.22, `glow.bat`, clipped lip `bat.lip` 4, icon 30. Hidden in the sanctuary | L124, L597, L628 |
| `B.cp` carry portrait | AP(0,1), (.5,134, 1,−10) | 52×62 | `W.ring(52,4,go,.8,·)` + `glow.portrait`. Inner disc: UIGradient `rcg` + UIStroke 2 white, icon 34. Distance pill h 19 (16+3), bottom-centre, padX 7, `night2` T.08, stroke 1.5 `go`, FO 11, r8, "84 m" | L125–128, L598 |
| `B.edge` edge arrow | AP(1,0), (1,−8, .36,0) | h 36, w ≈100 **est.** | `W.glass` r18, rim `go`, UIPadding L6 R11, gap 3. Chevron 18×18: two rotated 3 px Frames with round caps (SVG `M6 3l6 6-6 6`, L589). FO 13 `go.text`, "Safe 84 m". 10 Hz update | L129, L589, L599, P§2 |
| `B.beacon` | BillboardGui AlwaysOnTop on the nearest SanctuaryExit | 124×150 at board scale | pillar Frame x56 y26 w12 r6, `beaconPillar`, `glow.beacon`. Label pill h 23 (20+3), padX 10, `go.ink` T.22, stroke 1.5 `go`, FO 12, r10, "SAFE GATE · 84 m" | L131–133, L600, P§2 |
| `B.toast` (tier 1) | AP(1,0), (1,−12, 0,60) | h 30 | `W.glass` r16 (pill), UIPadding L6 R12, gap 6, coin icon 24, FO 13 | L141, L601 |
| `B.bnr` (tier 2) | AP(.5,0), (.5,0, 0,62) | h ≈59 **est.** (kicker line-height normal) | `W.glass` r24, rim white, UIPadding 6/28/8. Kicker FO 11 `pinkText`. Title LG 28 + drop 3 `lip` (+ pink 16 text glow, not ported) | L144–146, L602 |
| `B.moment` (tier 3) | full width, top .30 | — | title LG 64 `moment.text`, UIStroke 3 `lip`, drop 5 `lipDeep`, `glow.moment` (optional U1). Sub pill padding 2/12 r10 `night2` T.2 FO 13, 8 below | L149–151, L603 |
| `B.cpop` carry pop-up (tier-2 slot) | AP(.5,0), (.5,0, 0,60) | h 78 **est.** | pill r30, UIPadding 7/24/7/7, gap 12. Fill UIGradient `rcg` + overlay Frame `cpopOverlay`, UIStroke 3 white, `glow.rarity` 26, lip `night` T.4 5 (body opaque). **Portrait** 58 circle `rcg` + gloss U8 (T.2), stroke 3 white, glow 14, icon 42. Text: kicker FO 11 + drop 1 `ink` T.2 · name LG 30 + drop 3 `ink` T.15 · hint FO 11.5 T.05 | L155–160, L604, L683 |
| `B.run` RUN! (tier-2 danger) | full width, top .19 | — | TextLabel LG 104 + UIGradient `run` (fill) + UIStroke 4.5 `run.stroke` + drop label +8 `run.drop` + `glow.run` (optional U1). Awake pill h 27 (24+3), padX 14, r12, `run.awakeBg` T.15, stroke 1.5 `danger.rim`, FO 13, 6 below. **Shock** 180 circle UIStroke 6 `run.shock` + `glow.shock`, centred at top .22, Decor | L162–167, L605 |
| chase vignette | full screen, Decor, no input | — | 4 edge Frames with linear gradients (P§2): colour `vignette`, depth **14.6 % of W (left/right) and H (top/bottom)**, T 1 at the inner edge → **.77** at the screen edge (α .23 = the CSS value at the edge midpoints) **est. from L139 geometry**. The CSS corners reach α .55; overlapping frames give ≈.41 | L139 |
| `B.pcard` player card / launcher | (.5,−125, 1,−78), AP(0,1) | w 230 | `W.glass` r18, padding 10/12, gap 10. Ring 48 (t3, `ring.conic`) icon 32. Meta FO 14 "Player · Lv 48", XP bar h 10 (margin 4/3), sub FO 11 T.15 "12 creatures · 3 summits". Launcher buttons (D2) are gap G7 | L170–174, L606, P§11 D2 |

**Menu builders**
| Builder | Primitives & sizes | Source |
|---|---|---|
| `panel()` | Backdrop: tint Frame `mtint` (no image blur; the live world shows through). **Panel** `W.glass` r22 at (0,24, 0,66), size (1,−48, 1,−76). UIPadding 26/12/12/12. Two columns: side 128 fixed + gap 12 + scroll area. **Title** (Overhang) `W.cta` h 42, padX 20, LG 23, centred, top −21. **X** (Overhang) 36 circle `close` gradient, stroke 3 white, `glow.x`, lip `close.lip` 3, "×" FO 20, at top −13 / right −10 | L177–181, L608 |
| `tabs()` | UIListLayout V gap 5. **Tab** h 34 r11, padX 9, gap 7, icon 22, FO 13, `night` T.5, stroke 1.5 white T.82. On: UIGradient `cta` Rot 0, stroke white, `glow.tabOn`. Spacer flex. Footer CTA h 36 LG 16. Section-jump highlight follows scroll (L660) | L182–186, L609, L660 |
| per-menu content | **Collection** "Creatures 7/36": tabs All/Team/Index/Evolve = creature/heart/scroll/egg-cracked, footer "Equip team". Chips All 16 · Owned 7 · Missing 9 · Rarity ↓. 16 cards (7 owned, 5 ???, 4 locked; names are examples). **Shop** "Shop" + chest 50: tabs Featured/Coins/Passes/Eggs/Skins = gift/coin/gem/egg/bat (Coins/Passes/Eggs/Skins jump to their sections). Section order: hero → Free gifts ("one every 15 min") → Daily deal ("new one in …") → Coins → Passes → Boosts → Eggs → Bat skins → note. **Settings**: tabs Audio/Graphics/HUD/Controls/Account (no icons), each jumping to its section. Rows per L642–646. **Tab sync:** a tab is active once its section's offsetTop − (hero ? 60 : 10) ≤ scroll, and the last tab is active at the end. **Jump:** scroll to section offsetTop − (hero ? 64 : 4) | L596, L629–646, L660, L662 |
| scroll area | ScrollingFrame, ScrollingDirection Y, AutomaticCanvasSize Y, UIPadding 3/10/14/3, ScrollBarThickness 6, thumb `pk` (solid, P§2). Track: Frame `night` T.45 behind the bar, r4 (L191). Bottom fade: overlay 36 px gradient to the panel tint, hidden at the end (L188–189). Section header: FO 11 `pinkText`, uppercase, margin 14 top / 7 bottom (first 2), right note FO 11 `lavText` | L188–195, P§2 |
| chips | UIListLayout H Wraps, gap 6, bottom margin 8. **Chip** h 27 (24+3), padX 10, r12, FO 12, `night` T.5, stroke 1.5 white T.78. On: `pk` T.65, stroke white, **no glow** | L196–198 |
| `card()` | Grid: UIPadding 3. Columns n = ⌊(W+10)/106⌋, cell = (W−10(n−1))/n, with W = scroll content width − 6 (auto-fill min 96, gap 10). Card r14, UIStroke 3 `ink` + outer ring 2 white T.7 (extra Frame; one stroke per object). Fill `rcg`. Art h 62 + highlight (U11 white T.4 at 50 %/42 %, clipped by the art Frame), icon 52. Name band `ink` T.38, padding 3/7/6, gap 3, FO 12, XP h 7 (`action`, full = `cardXpFull`). **Level hex** 28 at (5,5) `deep`, FO 13 (shape G12). Unknown: `card.fallback` + "?" FO 30 / padlock 38 (filters G13). Violet/prism: `glow.cardRare` + ring white T.4 | L199–206, L610–612 |
| hero (Starter Pack) | Sits **above** the ScrollingFrame (P§2). Outer r20, padding 4, `holo` recipe (1f), `glow.hero`, lip `night` T.3 5. Inner r16, padding 10/12, 3 cols gap 12, `hero` gradient + gold radial (U11). Rays U2 at (−70,−110), 280 px, `rays.hero` T.76 (Decor). Art: egg 56 + coin 36 + chest 36, overlap −12. Title LG 24 + drop 3 `lip` (+ `glow.heroTitle`). Tag "ONE TIME" pill h 18, padX 8, r9, `gold` / `gold.ink` FO 10. List pills **h 22** (20+2), padX 8, r10, FO 11, `night` T.45, stroke 1 white T.75, gap 4/6. Timer pill h 18, padX 8, r9, `night` T.3, FO 11. Buy h 40 padX 16 LG 20. **Mini** (CanvasPosition.Y > 8): hide list, timer, extra art and rays; art 30, padding 5/10, title 18, buy h 32 / 16 | L207, L222–241, L632, L659 |
| `buy()` | `W.cta` shape: h 32, padX 12, LG 16, stroke 2. Robux = `mint`, `glow.buyRobux`, lip `go.lip` 4. Coins = `coinBuy`, `glow.buyCoin`, lip `gold.lip`. **Shine**: Frame 28 % wide, **120 % tall** (top/bottom −10 %), rotated 20° (≈ skew −20°), `shine` gradient, clipped by the button (rect clip only; it pokes into the rounded corners). ×3 = ghost h 32 padX 9 LG 15 stroke 2. Claim = coin h 22 padX 10 LG 13. Robux id 0 → disabled (G15) | L242–246, L255, L614 |
| pbtn (Reset) | `W.ghost` h 30, padX 12, LG 15, stroke 2. On its only instance the ghost box-shadow wins (`.g .btn.ghost` beats `.g .pbtn` on specificity), so it has **no pink glow/lip**. The `glow.pbtn` / lip `lip` 4 values (L307) have no rendered instance | L57, L307, L646 |
| note | FO 11 T.15, top margin 10, last item in the shop scroll | L306, L639 |
| ladder (free gifts) | 4 equal columns, gap 8. Track Frame 4 px r2 at y 32, x 10–90 %, hard step `go` → white T.8. **Rung** r16, padding 6/4/8, gap 4, `night` T.4, stroke 1.5 white T.8. Icon well 48 circle white T.9, icon 34 (ready 38): gift, coin, gift, chest. Done: group T.35, well `go.glow` T.75, label "Claimed". Ready: stroke `gold`, `glow.ready`, well U11 gold (T.35), pulse, Claim button. Locked: timer label. Label FO 11 h 18 | L247–255, L633 |
| ticket (daily deal) | U5 fill (`ticket` gradient) + U10 ring (`gold` T.25). 3 cols gap 12, padding 10/20. Trail preview 76×54. Title LG 18 + drop 2 `lip`. Desc FO 11 T.1. Was-price FO 11 RichText `<s>` T.25 + buy | L256–260, L299, L634 |
| `cpk()` coin packs | UIListLayout H, VerticalAlignment Bottom, gap 8, columns from min 104 (a grid can't bottom-align). Heights 112/122/132/150. Card r16, padding 8/6/10, gap 3, stroke 2 `gold` T.45, `cpk` gradient + gold radial. Best: stroke white, `glow.best`. Pile h 46: 1–4 coin icons 34, overlap −17. Amount LG 19 `gold.text` + drop 2 `lip`. "coins" FO 10.5 T.15. Ribbon: full-bleed top, h 18, `ribbon` gradient, FO 10 `ribbon.ink`. **Burst** 40: 3 `gold` squares rotated 0/30/60 (12 points, P§2; inner/outer ratio .71 vs the board's ≈.77), label FO 11 `gold.ink` rotated −12, top 4 (24 with ribbon), right 4 | L261–271, L615, L635 |
| `pass()` | Grid min 122, gap 10. Card U3 fill (`pass` gradient) + U9 outline (`rc`). Padding 12/8/18, gap 4, hollow `glow.rarity` 14. Orb 58 `rcg` + gloss U8 (T.25) + stroke 3 white + glow 16, icon 36. FOREVER pill h 16, padX 7, r8, `night` T.25, FO 9.5 `gold`. Name LG 15 + drop 2 `lip`. Desc FO 11 T.1. Before/after FO 11, after value in `go` | L272–279, L616, L636 |
| `bst()` | Grid min 112, gap 10. Card U4 fill (`night` T.45) + U9b outline (white T.8). Padding 10/6/12, gap 4. On: outline `go`, `glow.boostOn`. Timer `W.ring(62,4,go,.82,deep)`, icon 32 (no highlight). Name FO 13. Desc FO 10.5 T.15 | L280–286, L617 |
| `egg()` | Grid min 150, gap 10. Card r18, padding 8/8/12, gap 5, `eggCard`, stroke 1.5 white T.8. Pedestal 96×92: existing `egg` icon at 62×78 + "?" LG 30 + drop 2 `ink` T.3 (P§2). Plinth 88×20 ellipse: gold centre α .7 → `hero.from` α .6 at 60 % → transparent at 72 %. Two U11 layers (violet T.4 full size under gold T.3 at ≈60 % size, **est. approximation**). Name LG 16 + drop 2 `lip`. Odds bar h 8 r4, stroke 1 white T.6, segments in `rc` colours by %. Legend FO 11, swatch 8 r2. Buttons row gap 6: buy + ×3 | L287–295, L308–310, L618 |
| `skin()` | Grid min 112, gap 10. Card r16, padding 8/8/10, gap 4, stroke 3 `rc`, `skin` gradient, hollow `glow.rarity` 12. Trail preview h 54 r12 `night` T.35, ClipsDescendants. Streak h 10, 70 % wide, r6, `streak` gradient + glow `rc` 10 (Decor). Bat icon 38. Name FO 13. Desc FO 10.5 T.15 | L296–305, L619 |
| `row()` | 2 cols (1fr / auto) gap 12, padding 8/12, r14, `night` T.55, stroke 1.5 white T.82, bottom margin 7. Title FO 14. Desc FO 11 T.18. Controls gap 8 | L311–314, L620 |
| `sl()` | Track 120×10 r6 `night` T.3, stroke 1.5 white T.5. Fill `action` r5. Knob 16 white + glow `pk` 8. Value FO 12, w 34, right-aligned | L315–318, L621 |
| `seg()` | r12 `night` T.4, stroke 1.5 white T.75. Option padding 6/11, FO 12 `segText`, h ≈27 **est.** (line-height normal), container ≈30 **est.** On: `cta` gradient, white text. Rect clipping can't round the end options, so the first and last on-state fills get their own UICorner 12 (square inner corners via an extra Frame). Deviation from L319 `overflow:hidden` | L319–320, L623 |
| `tog()` | 54×28 r16 (pill) `night` T.3, stroke 1.5 white T.7. Knob 20 at (3,3) `togOff`. On: `action`, knob x 29 white | L321–323, L622 |
| wallet (Overhang) | top −15, right 40, h 30, `W.glass` r16 (pill), padding L30 R4, gap 6, FO 13, coin icon 34 at −4. "+" 22 r7 `mint`, stroke 2 white, FO 15 `go.ink`, jumps to Coins | L219–221, L640 |
| shop panel | `panel` with the shop glass variant + rays U2 (`rays.tint` T.91, Decor) clipped to the panel + gold title (`goldTitle`, lip/drop `gold.lip`, `glow.goldTitle`, left padding 44, chest icon 50 at x −12 rotated −10°) + tails U6 (24×30 at top 14, x −20 / right −20, behind) | L210–218, L631, L640 |
| reveal strip | Backdrop `reveal.bgOut` Frame + U11 tinted `reveal.bgIn` centred at 50 %/48 %, diameter ≈702 at 844×390 (75 % of the farthest-corner distance 468, **est.**). Sun U2 `rays.tint` T.72. Title LG 30 `gold.text` at top 20 + drop 3 `lip` + `glow.revealTitle` (26 once landed). Band y 92 h 130 `night2` T.38, top and bottom lines 3 white T.45. Track y 104: **20 cards** 96×108 at pitch 108 (colour sequence L731, mostly blue; icons alternate creature/egg), r14, stroke 3 `ink`, clipped lip 4 `ink`, inner ring 2 white T.65, rarity fill → T.2, icon 68. **Lands on index 14**, at track x = W/2 − (14·108 + 54) (L733, centre 422 at 844). Selector 120×150 centred x, y 82, stroke 5 `gold`, r18, `glow.revealSel`. Halos 180×190 centred x, y 62: stroke 6 `gold` + `glow.halo` / stroke 3 `pinkText`. Shards 46×56 at (W/2, 150) (shape G12). Result card 140×170 centred, y 70, stroke 5 white, `rcg`, `glow.revealCard`, icon 96, rotation −3. Word LG 62 at y 238 (jumps to 226 at named, no transition). Name LG 22 at y 302 + drop 2 `lip`. Chance FO 14 `pinkText` at y 330, with rarity pill `revealPill` and XP in `go`. Collect `W.cta` 190×46 LG 24, right inset 34, y 316. Sparkles: 2 Frames each (P§2) at 34/28/22 + `glow.sparkle`. On land: band/track/selector → T.88 | L326–356, L538–548, L731–738 |
| Not to build | `.navb`, `.gcard`, `.dockb`, `.node`, `.rail`, `.vigp` (old vignette), `.shim` + `@keyframes shim` (old XP bar), `.alert` (alert chip, merged into RUN!), the old inline orbs (82 px jump etc.). These are the "Before" controls only | L53–54, L58, L60–62, L66–71, L441–495 |

---

## 3. Containment rules (port of `checkHud`/`checkMenu`, L676–707; P§5)
**Zones** (full-screen coordinates, ScreenInsets None):
| Zone | Rule | Source |
|---|---|---|
| S | whole screen | L693 |
| C core | x < max(116, TopbarInset.Min.X), y < max(56, TopbarInset.Max.Y). Board placeholders: 2×44 at (12,7), gap 8 | L80–81, L86, L693, P§5 |
| top band | x ≥ 116, y < 58 (our row). Nothing else above y 66 on the left | L88, L396 |
| T thumbstick | x < .30W, y > .52H | L90, L693 |
| M keep-clear | x .28W–.72W, y .24H–.70H | L92, L693 |
| native TouchGui jump + thumbstick rects | obstacles too | P§5 |
| Tolerance | .75 px on every inside/overlap test. Text clip = overflow > 1 px | L678–679, L694 |

| Size | T (x0–x1, y0–y1) | M (x0–x1, y0–y1) |
|---|---|---|
| 749×330 | 0–224.7, 171.6–330 | 209.7–539.3, 79.2–231.0 |
| 844×390 | 0–253.2, 202.8–390 | 236.3–607.7, 93.6–273.0 |
| 932×430 | 0–279.6, 223.6–430 | 261.0–671.0, 103.2–301.0 |
| 1024×700 | 0–307.2, 364–700 | 286.7–737.3, 168.0–490.0 |
| 1180×780 | 0–354.0, 405.6–780 | 330.4–849.6, 187.2–546.0 |
| 1600×860 | 0–480.0, 447.2–860 | 448.0–1152.0, 206.4–602.0 |

| Class | Rule | Source |
|---|---|---|
| Permanent (`data-hud`): coin+gear, rail, dock, sprint, bat, carry portrait, edge arrow, pick-up orb (D4) | inside S. No overlap with C, T, M or another permanent (a parent containing a child is OK) | L697–699 |
| Transient (`data-transient`): toast, banner, moment, carry pop-up, XP line, rail label, RUN!, player card | inside S, clear of C. May cross T and M. No input on the mountain | L697, L532, P§5 |
| World / untagged | beacon (`data-world`, L600), plus the untagged vignette (L627) and shock ring (L605). Not checked (the L696 selector covers only `[data-hud],[data-transient]`) and excluded from coverage | L439, L600, L605, L627, L696 |
| Menu | panel inside S and clear of C. Every element inside the panel, except **Overhang** (title, X, wallet = `data-straddle`), which must stay inside S and clear of C. ScrollingFrame children must fit its width. No horizontal canvas. **Decor** (`data-deco`: panel rays L640, hero rays L632, trail streaks L619/L634) is exempt | L608, L632, L634, L640, L701–706, P§5 |
| Reveal strip | no board containment check (not in `runAll`, L711–715). Sparkles there are not covered | L711–715 |
| Text | `TextFits`, no ellipsis clip | L694, P§5 |
| Touch targets | ≥ 44 px (P§5). **Conflict with the board:** dock btn 42, hero buy 40 (mini 32), side CTA 36, X 36, tab 34, buy 32, pbtn 30, toggle 28, chip 27, seg option ≈27 **est.**, claim 22, wallet "+" 22, slider knob 16. Recommended: keep the visual sizes and add transparent hit Frames ≥ 44 that don't count toward coverage. **Overlaps at 44:** dock fits (pitch 48 → 4 px gap). Side tabs overlap 5 px (pitch 39). Wrapped chip rows overlap 11 px (pitch 33). Seg options are adjacent with no gap, so any option narrower than 44 overlaps its neighbour. Owner call, G1 | L110–111, L181–183, L186, L196–197, L221, L236, L241–242, L255, L307, L315–322, P§5 |
| Sizes | 749×330, 844×390, 932×430 (board) + 1024×700, 1180×780, 1600×860 | L582, P§5 |

**Coverage metric:** the union area of the permanent boxes on a 2 px grid (floor the start, ceil the end), as % of the screen at 844×390. Roblox buttons, vignette, beacons and messages are excluded (L439, L692). **Measured by running the board in a browser at 844×390** (coordinator, 2026-10-28). Board self-check: **21/21 PASS, both controls fail** (L711–721).
| State | Measured | Gate |
|---|---|---|
| Rest | **10.6 %** | ≤ 11.6 % (board + 1 pt, P§4) |
| Carrying | **11.6 %** | — |
| Chase | **11.1 %** (supersedes the plan's 11.0 %) | ≤ 12 % (P§4) |
| Sanctuary | **9.0 %** | — |
| Old chase (control) | **24.7 %** | — |
Note: D5 removes the custom jump orb, so the native jump rect replaces the 70² box in the Roblox measurement.

---

## 4. Message tier map
**Slots:** tier 1 = under the coin pill, AP(1,0), (1,−12, 0,60). Tier 2 = top band below Roblox's row, centred, top 60–62. RUN! uses top .19. Tier 3 = centre, top .30. **Rules:** nothing takes input on the mountain. A new tier-2 banner replaces the one showing (this covers carry pop-up vs RUN!: the newer one wins). Toasts queue. In the sanctuary, tier 3 waits for Collect (L528–532).
| Event | Tier | Slot / visual | Duration | Source |
|---|---|---|---|---|
| coin gain | 1 | toast, coin icon 24 | 1.5 s | L528, L141–143, L601 |
| XP gain | 1 | toast + XP line flash above the dock | toast 1.5 s · line **1.6 s CSS vs 1.5 s board text** (G4) | L118–121, L412, L528 |
| small pickup | 1 | toast | 1.5 s | L528 |
| unknown legacy toast text | 1 | toast | 1.5 s | P§8.6 |
| carry | 2 | carry pop-up "CARRYING / NAME / Get it to the safe gate", rarity-tinted, shrinks into the portrait | 2.5 s (see `carry.pop`, G4) | L398, L434, L604, L683–686 |
| regrab | 2 | carry pop-up "GOT IT BACK / NAME / Run it to the safe gate" | 2.5 s | L434, L683 |
| alert{guardian, section} | 2 (danger) | RUN! + "<GUARDIAN> IS AWAKE" + shock ring. Then vignette on, dock → chase (3 btn, T.75) | 1.5 s (`run.slam`; vignette persists) | L399, L415, L529, L605 |
| section change | 2 | banner "SECTION n / <name>" | 2.5 s | L529, L602 |
| safe (secured) | 2 | banner "secured" (named in the tier table, **not drawn**). Dock restores | 2.5 s | L414, L529 (G5) |
| checkpoint | — (rail) | rail brightens + rail label "Checkpoint n · h m". Not a tier message | idle fade after 3 s (board text). The demo loop holds 1.4 s (G4) | L107–109, L416, L595 |
| level up | 3 | moment | mountain 2.5 s, sanctuary waits for Collect | L530 |
| summit | 3 | moment "SUMMIT! / Section 6 cleared · time" | 2.5 s | L530, L603 |
| hatch | 3 (sanctuary) | reveal strip, Collect CTA | lands 3.5 s, CTA 5.7 s (§6) | L530, L537, L738 |
| knocked | **gap** | — | — | G5 |
| lost | **gap** | — | — | G5 |
| calm | **gap** (state: what ends the vignette and chase dock other than reaching safety) | — | — | L414, G5 |
| purchase (coin, D7) | **gap** | — | — | G5 |

---

## 5. Upload sheet (white PNGs for tinting; 2× masters use `SliceScale` .5)
| # | Name | px | Shape (from the CSS) | SliceCenter | Use |
|---|---|---|---|---|---|
| U1 | `glow` (hollow) | 128×128 | outer-only Gaussian edge: α(r) = 0 for r < 32, then .5·erfc((r−32)/(16√2)), so .5 at r 32 and ≈.02 at r 64. This is a CSS `box-shadow` blur B = 2σ across the shape edge (L47, L55), never painted under the element | Rect(63,63,65,65), transparent centre. SliceScale = B/32. Size = element + 2(B+S) | every box-shadow glow (1g). On circles with d > 2B the hollow corners have radius B, so the glow weakens at the diagonals by up to (d/2−B)(√2−1) px (**est.** deviation; orb 70/B 20 → ≈6 px) |
| U2 | `rays` | 512×512 | 20 wedges, 8° on / 10° off (hero rays L223). α fade baked from the L223 mask: opaque to r .141·(size/2), 0 at r .919·(size/2) | none (rotated) | hero (280 px), panel (size ≈ panel diagonal ÷ .919), reveal sun (≈1224 px at 844). **Conflict:** panel and reveal rays use 7°/9° (L212, L327), which is 22.5 per turn and leaves a seam. Recommended: one 20-ray PNG. Cost: panel/reveal rays 12 % wider spaced, and panel rays fade toward the panel ends (CSS L212 has no mask). Upside: the fade hides Roblox's rect-only clipping at the panel's rounded corners. Alternative: an extra unmasked `rays.flat` |
| U3 | `shield.fill` | 256×256 | rounded rect, TL/TR r 40, BL/BR r 100 (2× of L273 `20px 20px 50px 50px`) | Rect(100,40,156,156) | pass card fill. Min display 100×70 |
| U4 | `roundtop.fill` | 256×256 | TL/TR r 120, BL/BR r 36 (2× of L281 `60px 60px 18px 18px`) | Rect(120,120,136,220) | boost card. Below 120 px wide, SliceScale = W/240 (this matches CSS radius clamping; the board's min is 112, L280) |
| U5 | `ticket.fill` | 128×148 | 2× of a 74 px tall ticket (trail 54 + padding 2×10, L256/L299): corner r 28, half-circle notches r 18 centred on the left and right edge midpoints (L256 mask `circle 9px at 0 50%`/`100% 50%`) | Rect(32,0,96,148) (horizontal 3-slice) | ticket fill. Notches stretch if the height changes (large text) |
| U6 | `ribbon.tail` | 48×60 | polygon (0,0),(48,0),(48,60),(0,60),(20,30), the 2× of L217. Right tail = **Rotation 180** (equals L218 exactly) | none | gold title tails, tint `gold.tail`, shown at 24×30 |
| U7 | `ring.fallback` | 128×128 | annulus, outer r 64, thickness 8 (`.bring` 4/62, L283) | none | **hold**: only if the UIStroke ring fails in production (P0 passed). Displayed thickness: 3.25 vs 4 on the 52 px carry ring (L126; error .75 px), 2.63 vs 3 on the 42 px XP ring (L112), 3.0 vs 3 on the 48 px pcard ring (L49/L172), 3.88 vs 4 on the 62 px boost ring (L283) |
| U8 | `gloss.orb` | 128×128 | the L55 radial (centre 50 %/28 %, linear fade to 0 at 52 % of the farthest-corner radius = .456d), **pre-clipped to the circle**, baked at peak α **1** | none | ImageTransparency per use: orb/sprint .4 (L55, L123), porb .25 (L274), cpic .2 (L157). Deviation: porb (30 %, fade .516d) and cpic (35 %, fade .508d) highlights are drawn ≈11–13 % wider and lower than the PNG. The boost ring has no highlight (L283–284) |
| U9 | `shield.line` | 256×256 | U3 outline only, stroke 6 (2× of 3) | same as U3 | pass rim in `rc` |
| U9b | `roundtop.line` | 256×256 | U4 outline, stroke 3 (2× of 1.5) | same as U4 | boost rim |
| U10 | `ticket.line` | 128×148 | inset ring 4 (2× of 2), cut by the notches, not following them (L256 mask cuts the inset shadow) | same as U5 | ticket gold ring |
| U11 | `radial` | 128×128 | white disc, α linear 1 at the centre → 0 at r 64 (CSS radial gradients interpolate linearly between stops) | none (stretched) | radial backgrounds inside rect-clipped frames: card art (L201), hero radial (L222), cpk radial (L262), ready rung well (L253), egg plinth (L292), reveal backdrop (L326) |
**Count vs D9 "~7":** **12 PNGs specified, 11 to upload (U7 held).**
- U8: Roblox can't clip a highlight to a circle.
- U9, U9b, U10: the pass, boost and ticket fills are translucent (α .14–.88), so a tinted copy behind them would bleed the border colour through, and UIStroke follows the frame rect, not the image shape.
- U11: the hollow U1 can't also serve linear radial fills.

Cost: 4 uploads beyond the original 7, still no Robux. Alternative: keep 7 by making the fills opaque, which means guessed composite colours that don't trace to the board. **Owner decides at STOP 1.**

---

## 6. Motion tokens (names, durations, board easings, amplitudes; Motion owns the implementation)
| Token | Duration | Easing (board) | Amplitude | Source |
|---|---|---|---|---|
| `toast` | 1.5 s (in to 15 %, out from 78 %) | ease-out | in y −8 → 0; out x +16 | L142–143 |
| `banner` | 2.5 s (overshoot at 10 %, settled 16 %, out from 84 %) | ease-out | y −30, scale .8 → 1.05 → 1; out y −30 | L147–148 |
| `banner.danger` | = `run.slam` + `run.awake` + `run.shock` (RUN! is the danger banner, L415) | ease-in-out | see run.* | L165–168, L415, L529 |
| `moment` | 2.5 s (12 %, 18 %, out from 82 %) | ease-out | scale 2.4 → .94 → 1; out 1.08 | L152–153 |
| `carry.pop` | 2.5 s. Whole-timeline `easing:'ease-out'` (effect-level), so the keys **render** at ≈.15 / .22 / 1.54 / 1.93 / 2.5 s (offsets .1/.14/.8/.92/1). The prose says "in at 0.35 s" (= linear .14·2.5): conflict, G4 | ease-out (whole timeline) | y −24 scale .5 → 1.08 → 1; hold; .55 of the path at scale .45 (α .9) → portrait centre, scale .12, α 0 | L434, L686 |
| `carry.portraitIn` | 2.6 s total, linear keys: pop at 2.34 s → 1.3 at 2.496 s → 1 at 2.6 s | — | scale 0 → 1.3 → 1 | L687 |
| `carry.iconTwist` | 2.5 s, settles by .45 s (linear keys .1/.18) | — | rot −14° scale .7 → 8° 1.15 → 0° 1 | L688 |
| `run.slam` | 1.5 s (keys .1/.25/.4/.5/.65/.8/.95/1.3/1.5 s) | ease-in-out | scale 3.4 rot −8° → .86/2° → 1.1/−1.5° → 1; shake ±4 x / ±2 y, ±1°; out scale 1.12 | L165, L399 |
| `run.awake` | in .3–.5 s, out 1.3–1.5 s | ease-in-out | y +8 → 0 | L166 |
| `run.shock` | .25–1.0 s | ease-out | scale .2 → 2.6, α .9 → 0 | L168 |
| `vignette.pulse` | 1.1 s loop | ease-in-out | α 1 ↔ .45 | L69, L139 |
| `pulse` (ready rung) | 1.2 s loop | ease-in-out | scale 1.08, α .85 | L39, L253 |
| `dock.chaseFade` | .2 s | CSS default | → group T.75 | L134 |
| `dock.tapRestore` | 3 s hold | — | all 5 buttons | L414, L670 |
| `rail.idle` | fade to T.7 after 3 s | — | — | L416 |
| `rail.bright` | ramp .49 s, hold 1.4 s, fade .56 s (7 s demo loop) | ease-in-out | group T .7 → 0 → .7 | L107 |
| `rail.label` | same window | ease-in-out | x −6 → 0 | L109 |
| `xpLine` | 1.6 s CSS / 1.5 s text (G4) | ease-out | fill 54 % → 62 % between 15 % and 60 % | L118–121, L412 |
| `edge.nudge` | 1 s loop | ease-in-out | x −4 | L130 |
| `pcard.open` | .2 s | ease-out | **rendered** from (−115, +40), α 0. The x comes from the dock's `translate(-50%)` keyframe reused on a card with no base transform (board artefact). Intended x is G23 | L138, L170–171 |
| `tog.knob` | .15 s | CSS default | x 3 → 29 | L322 |
| `rays.panel` · `rays.hero` · `rays.reveal` | 40 s · 24 s · 26 s loop | linear | 360° | L212, L223, L327 |
| `holo` | 5 s loop | linear | one cycle (−240 %) | L207–208 |
| `buy.shine` | 3.2 s loop (sweep in the last 38 %) | ease-in-out | x −40 % → 130 % | L243–244 |
| `bob` · `bob.pass` | 2.4 s (2nd item delayed .5 s) · 2.6 s | ease-in-out | y −5 | L225–227, L274 |
| `burst.wob` | 2 s loop | ease-in-out | scale 1.07 | L269–271 |
| `egg.wobble` | 2.8 s loop | ease-in-out | rot −7° / 6° / −3° at 76/82/88 % | L290–291 |
| `trail.streak` · `trail.swing` | 1.4 s loops | linear · ease-in-out | x −80 % → 130 % · rot −18° | L300–303 |
| `sparkle` | 2.2 s loop, delays .7 / 1.3 s | ease-in-out | scale .4 → 1, rot 0 → 45°, α .4 → 1 | L41–42 |
| `reveal.spin` | 3.4 s | cubic-bezier(.14,.64,.2,1) | track to index 14 | L733, L737 |
| `reveal.landed` | at **3.5 s**: zero point for halo/shard/cardIn/dim/slam. Title → "RARE PULL!" and 30 → 26 px, instant | — | — | L356, L738 |
| `reveal.halo` | 1.1 s from landed (2nd ring +.12 s) | ease-out | scale .4 → 2.8, α 1 → 0 | L336–337 |
| `reveal.shard` | .9 s from landed | ease-out | 5 shards to (dx,dy,rot) = (−260,−80,−200°), (260,−60,240°), (−180,110,160°), (200,120,−140°), (0,−130,90°), scale .6, α 0 | L339–341 |
| `reveal.cardIn` | .5 s, delay .15 s from landed | cubic-bezier(.2,1.4,.4,1) | scale .3 rot −8° → 1, −3° | L342–344 |
| `reveal.dim` | .4 s from landed | CSS default | → T.88 | L345 |
| `reveal.slam` | .4 s, delay .3 s from landed | cubic-bezier(.2,1.5,.4,1) | scale 2.6 → 1 | L346–348 |
| `reveal.name` · `reveal.cta` | .4 s, at 4.3 s · 5.7 s. Word jumps 238 → 226 at 4.3 s, instant | CSS default | name/chance y +10 → 0; CTA y +12 scale .9 → 1 | L349, L353, L355, L738 |
| Reduce effects | setting scope "No FOV kick, hue cycling or flashes" (L643; I L35 adds no shake). Motion rule: loops stop, transitions ≤ .15 s fade or instant (P6). L36 is the page's OS media query (supporting evidence only) | — | — | L36, L643, I L35, P§4 P6 |

---

## 7. Open gaps (not filled)
| # | Gap |
|---|---|
| G1 | 44 px touch targets vs the board's smaller controls (§3), plus the tab/chip/seg hit overlaps. Hit-area approach needs approval |
| G2 | HUD scale S and L factors (the board only shows the S/M/L control, L644). Large-text increment not on the board |
| G3 | **Closed 2026-10-28.** Coverage measured in a board run (§3) |
| G4 | Timing conflicts: XP line 1.6 s CSS vs 1.5 s text. Rail idle 3 s text vs 1.4 s demo hold. Carry pop-up rendered keys (≈.15/.22/1.54/1.93 s, whole-timeline ease-out) vs the prose "in at 0.35 s" |
| G5 | Events without a board visual: knocked, lost, calm (what ends the vignette/chase dock), coin purchase result, the secured banner (named but not drawn). Tier collisions still open: tier-3 queueing, toast queue cap, whether RUN! may replace a carry pop-up mid-shrink |
| G6 | Battle HUD (D3): special orbs in the dock slot, Dodge in the bat slot, Ability chip, boss bar in the tier-2 band. No geometry on the board |
| G7 | Player-card launcher buttons (D2) and the carry-portrait tap detail (L434). Not drawn |
| G8 | "Pick up" orb (D4) above the bat orb: size and offset not drawn |
| G9 | Rail with 7 nodes (D10): at 749×330 the rail is 91.6 px tall vs 87 px of nodes (≈0.8 px gaps). Layout not drawn. Checkpoint display for 18 checkpoints not defined |
| G10 | Native jump (D5): the rect varies by device. Sprint/bat offsets were placed against the board's 70 px orb and need a re-check against the native rect |
| G11 | Radial highlights clipped to circles need U8 (pending the D9 amendment) |
| G12 | Shapes with no primitive and no upload: level hexagon (L65), reveal shards (L338). The board egg shape (L290) is replaced by the icon per P§2, so how the egg shows rarity (icon tint vs glow only) is undefined |
| G13 | CSS filters have no Roblox equivalent: unknown-card grayscale/brightness (L205), menu backdrop blur/brightness/saturate (L177) |
| G14 | Large screens (1024×700+) were never drawn. Insets are extrapolated, and no panel max width is defined |
| G15 | Disabled Robux button ("Coming soon", P§0), coin-purchase confirm and insufficient-funds states: none drawn. (Focus ring is defined by L35, see `s.focus`) |
| G16 | Letter-spacing (.02–.3em) has no known Roblox equivalent |
| G17 | `tabular-nums` (coin, wallet, timers): FredokaOne digits may jitter |
| G18 | Notch safe areas: board frames are full-screen and model no landscape notch insets |
| G19 | Beacon distance scaling, the edge arrow's show/hide threshold, hero-mini transition, tab scroll tween, panel open/close: no durations on the board |
| G20 | **Closed.** Rarity mapping is an owner decision (H L9). Tier names to be checked against the server roll table in P2 |
| G21 | **Closed.** Board token table vs CSS: the CSS wins (1a rule) |
| G22 | Robux price label: the board uses the text "R$". Whether to use a Robux glyph is undefined |
| G23 | Player-card open motion: the board renders an x slide (−115) that is an artefact of a reused keyframe. Intended motion (y only, or y + x) is undefined |

---

## 8. Audit disposition (p1_intel_verification.json, 81 issues; docLine = original doc line)
Each fix below was re-checked against the cited board line before it was applied. **81 fixed, 0 rejected.** Three auditor details were corrected while fixing (#10, #28, #59).
| # | docLine | Token | Result |
|---|---|---|---|
| 1 | 129 | r.4 | fixed: scrollbar radius cited L191–192 |
| 2 | 129 | r.4 (XP line) | fixed: XP line track r4 |
| 3 | 128 | r.* small radii | fixed: added r.5 (L52, L316), r.3 (L102), r.2 (L248, L310) |
| 4 | 114 | r.circle | fixed: added L104, L157, L292 (+L126, L167, L283, L334). Dropped L53–54 |
| 5 | 137 | s.thin | fixed: added L108, L133, L164 |
| 6 | 138 | s.glass | fixed: added L221 |
| 7 | 139 | s.bold | fixed: added cpic L157, porb L274, egg L290 |
| 8 | 141 | ring thickness | fixed: s.ring3 (L49, L112), s.ring4 (L126, L283). 2nd halo (L335) under s.bold |
| 9 | 101 | pill.T / well.T | fixed: beacon .78, awake .85, trail .65, ghost.T (L57) |
| 10 | 277 | W.ghost stroke | fixed: stroke 2. Correction: ×3 (L618, `buy3` L246) is a second ghost instance, also border-width 2 |
| 11 | 26 | ctaHi | fixed: cited L55–56, L184, L320. #FF9BDD listed as do-not-build |
| 12 | 27 | flare / sparkle | fixed: `sparkle.pink` #F78AD0 (L41) for sparkles 1 and 3 |
| 13 | 36 | glass vs token table | fixed: 1a rule (CSS wins), table hexes listed as do-not-build |
| 14 | 80 | board-only #5DFFC0 | fixed: #5DFFC0 identified as `go.glow`, only `--pass` is chrome |
| 15 | 83 | rarity provisional | fixed: owner decision cited (H L9) |
| 16 | 359 | dock hit overlap | fixed: dock fits (pitch 48). Tabs, chips and seg named as the real overlaps |
| 17 | 359 | seg ≈33 | fixed: option ≈27, container ≈30 est. (line-height normal) |
| 18 | 359 | hero buy 40 | fixed: added (L236, L241) |
| 19 | 359 | chip citation | fixed: added L196–197 (+L236, L241, L319–320) |
| 20 | 336 | core placeholders | fixed: cited L80–81 |
| 21 | 356 | data-world | fixed: only the beacon is tagged. Vignette and shock are untagged, excluded via the L696 selector |
| 22 | 148 | cta gradient citation | fixed: L55–56, L184, L320 |
| 23 | 187 | glow.chip | fixed: deleted (L198 has no shadow) |
| 24 | 157 | holo | fixed: two-cycle inner-Frame recipe, est./verify P3 |
| 25 | 174 | missing glows | fixed: revealSel, halo, shock, streak, sparkle (+ revealCard, moment, run, titles) |
| 26 | 199 | font.display roles | fixed: card, boost and skin names are body |
| 27 | 207 | 1i scaling | fixed: Scope column. S/L applies to HUD-root roles only |
| 28 | 229 | t.small / L174 | fixed: pcard sub added (t.smallHud). Correction: L174 was already cited under text.dimT |
| 29 | 204 | tracking citation | fixed: added L159, L163, L195 |
| 30 | 236 | legacy clashes | fixed: camelCase key rule, `outline` for ink, legacy aliases kept, `fontDisplay` |
| 31 | 272 | glass lip/glow bleed | fixed: clipped lip for translucent bodies, hollow U1 |
| 32 | 274 | W.ring size | fixed: (d−2t) circles with outer stroke t |
| 33 | 286 | rail label h | fixed: h 25 |
| 34 | 311 | hero list pill | fixed: h 22, padX 8, FO 11, r10 |
| 35 | 284 | clamped radii | fixed: §2 cites board radii (18/16/16/16/4); 1d header notes the pill cap |
| 36 | 291 | bat gloss | fixed: flat, no gloss |
| 37 | 322 | seg corner clip | fixed: UICorner on end on-states, deviation noted |
| 38 | 299 | shock glow | fixed: `glow.shock` B20, inset not ported |
| 39 | 297 | moment glow | fixed: `glow.moment` optional U1 |
| 40 | 326 | rvcard spread | fixed: `glow.revealCard` B34 S8 |
| 41 | 319 | streak glow | fixed: glow `rc` 10 |
| 42 | 399 | U1 profile | fixed: baked erfc profile, disc-blur claim removed |
| 43 | 399 | U1 translucent bleed | fixed: hollow outer-only U1 |
| 44 | 405 | U7 error | fixed: up to .75 px (carry ring) |
| 45 | 406 | U8 | fixed: bring removed, sprint added, peak α 1 with per-use T |
| 46 | 421 | carry.pop | fixed: rendered times + G4 conflict |
| 47 | 436 | pcard.open | fixed: rendered (−115, +40) recorded, G23 |
| 48 | 419 | banner.danger | fixed: = run.* tokens, removed from G4 |
| 49 | 464 | G5 carry vs RUN! | fixed: covered by L532 replace rule, narrowed |
| 50 | 453 | Reduce effects | fixed: L643, I L35, P6. L36 supporting only |
| 51 | 480 | G21 hex | fixed: #2B1757 (G21 closed by the 1a rule) |
| 52 | 474 | G15 focus | fixed: `s.focus` (L35), G15 narrowed |
| 53 | 447 | reveal landed | fixed: `reveal.landed` 3.5 s, title 26 instant, word jump at 4.3 s |
| 54 | 428 | pulse | fixed: ready rung only. `.alert` moved to not-to-build |
| 55 | 480 | G21 (dup) | fixed (see 51) |
| 56 | 187 | glow.chip (dup) | fixed (see 23) |
| 57 | 101 | forever pill | fixed: moved to well.T (`night`) |
| 58 | 288 | XP line radius (dup) | fixed (see 2) |
| 59 | 312 | buy shine | fixed: T1 → T.25 → T1. Correction: top/bottom −10 % gives **120 %** height, not 110 % |
| 60 | 26 | ctaHi (dup) | fixed (see 11) |
| 61 | 129 | r.4 scrollbar (dup) | fixed (see 1) |
| 62 | 365 | chase coverage | fixed: measured 11.1 % (board run) |
| 63 | 419 | banner.danger (dup) | fixed (see 48) |
| 64 | 318 | egg plinth | fixed: violet stop, two U11 layers, est. |
| 65 | 310 | card grid | fixed: UIPadding 3, W = content − 6 |
| 66 | 222 | pbtn | fixed: pbtn row, ghost override noted |
| 67 | 229 | .note | fixed: note row |
| 68 | 285 | HUD states | fixed: state → builder table. Rail hidden in the sanctuary |
| 69 | 299 | glows not ported (dup) | fixed (see 25, 38, 41) |
| 70 | 311 | display-text drops | fixed: drops on hero title, coin pack, pass/egg name, reveal title/name |
| 71 | 446 | reveal timeline (dup) | fixed (see 53) |
| 72 | 326 | reveal strip data | fixed: 20 cards, index 14, alternating icons, T.88 dim |
| 73 | 414 | motion amplitudes | fixed: amplitude column |
| 74 | 436 | pcard (dup) | fixed (see 47) |
| 75 | 80 | board-only list | fixed: all chrome, zone and old-control hexes listed |
| 76 | 445 | sparkle (dup) | fixed (see 12) |
| 77 | 327 | not to build | fixed: added .vigp, .shim, .alert |
| 78 | 307 | menu content map | fixed: per-menu table, icon ids, section order, sync offsets |
| 79 | 406 | U8 (dup) | fixed (see 45) |
| 80 | 357 | Decor | fixed: data-deco list only. Reveal has no check |
| 81 | 120 | r.btn convention | fixed (see 35) |
