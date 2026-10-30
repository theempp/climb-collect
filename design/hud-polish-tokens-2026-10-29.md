# HUD polish tokens (2026-10-29)

Atlas P1 for `design/hud-polish-build-plan-2026-10-29.md` (gaps A1–A10). No new design values: each one is a board value, an existing Theme/Motion token, or arithmetic on them (marked **est.**).
- **Why a separate file:** the Glassbloom intel (`Desktop\climb&collect\design\hud-glassbloom-intel.md`) sits outside this repo and is cited read-only by the home-base docs, so this addendum lives here.

**Sources**
| Key | File |
|---|---|
| `L###` | `Desktop\climb&collect\design\hud-board-v3\index.html` line |
| `GB:n` | the Glassbloom intel above, line n |
| `Th:n` / `Mo:n` / `Wi:n` / `Hud:n` / `Sh:n` / `UP:n` | `mountain/client/UI/Theme.luau`, `Motion.luau`, `Widgets.luau`, `Hud.luau`, `Shop.luau`, `mountain/shared/UIPresentation.luau` |
| `BP` | build plan §0 / Owner answers |

**Evidence check:** phone frames are 1.5 frame px per logical pt (2622 px / 3 = 874 pt).
- f_009: card 470–860 = 260 pt, which matches the 262 build.
- f_001: tabs are 50 frame px = 33 pt (h34) and the column 191 = 127 pt (128). Label text is left-aligned after a blank 29 px icon slot (R1).

## Proposed Theme additions (names only; every value is cited below)
Theme has no spacing table today (no `T.pad`). The builder adds a single geometry sub-table so callers write token references, not literals:
```
box={titlePill={h=36,padX=12,lipY=6,chestGap=6},
     tab={h=30,gap=5,padX=9,icon=22,iconGap=7,colMax=128},
     pcard={border=2,padY=10,padX=12,gap=10,meta=17,xpH=10,xpTop=4,xpBottom=3,sub=13,launch=42}}
```
Existing tokens are reused as-is: `T.r.btn` 16, `T.r[11]`, `T.r.glass` 18, `T.s.bold` 3, `T.s.thin` 1.5, `T.s.glass` 2, `T.t.menuTitle` 23, `T.t.tab` 13, `T.t.pcardMeta` 14, `T.t.smallHud` 11, `T.textDimT[3]`, `T.gradCta`, `T.gradGoldTitle`, `T.glowCta`, `T.glowGoldTitle`, `T.glowTabOn`, `T.lip`, `T.goldLip`, `T.goldTail`, `T.wellT.tab`, `T.night`.

## A1–A10

| Gap | Value | Token | Source |
|---|---|---|---|
| **A1** Title pill height | **36** | `T.box.titlePill.h` | `.side .btn` h36 (L186), the next height down in the same `.btn` family as `.ttl` (L608: `class="btn ttl"`). The 42 (L180) is rejected because the owner asked for less vertical padding. |
| **A2** Title pill padX | **12** | `T.box.titlePill.padX` | `.buy` padX 12 (L242) and pbtn padX 12 (GB:356, L307): the `.btn`-family horizontal inset at a ~32–36 height. Width = `W.plateWidth(text, T.t.menuTitle, 12)` = textW + 24 + 2·`T.s.bold` (Wi:765-767). |
| **A3** Title text | **LG 23**, `T.fontDisplay` | `T.t.menuTitle` | L180, GB:244. Kept because the pill stays at 36, the threshold set by the plan. `W.fit` min 8 stays for long titles. |
| **A4** Straddle + look | Centre on the panel's top edge: AnchorPoint (.5,.5) at (.5,0,0,0), so top = −h/2 = **−18**. Unchanged: r16, stroke 3 white, gloss, glowCta, lip 6 `T.lip`, drop +2 `T.lip` | `T.r.btn`, `T.s.bold`, `T.gradGloss`, `T.gradCta`, `T.glowCta`, `T.lip`, `T.box.titlePill.lipY` | Rule: board top −21 = −42/2 (L180). Look: L56 (`.btn`), Wi:760-762. Content clearance is unchanged: panel padding-top 26 + border 2 (L179) ≥ 18 + lip 6 = 24. |
| **A4b** Dialogs (Q4) | Same pill on the Dialog's top edge. The first content row starts at **≥ 28** below the dialog top | same | 26 + 2 (L179, L47). Replaces the in-dialog title at y14 (Feedback:500). Style per dialog is O3. |
| **A5** Shop gold pill | Same geometry (h36, symmetric padX 12). Gold recipe: `T.gradGoldTitle`, `T.glowGoldTitle`, lip + drop `T.goldLip` | `T.box.titlePill` + gold tokens | L214, Sh:103. **The chest is Decor:** 50 px (L631), rot −10° (L215), centre 58 % of its height above the plate centre, so y = h/2 − 29 = **−11** (L215). x keeps the board's **6 px gap** between the chest's right edge and the text (board: text at 3+44 = 47, chest −9…41; L214/L215, **est.**), so x = (padX + `T.s.bold`) − 6 − 50 = **−41**. **Tails:** 24×30 `T.goldTail` at x −20 / right −20 (L216-218). **Text never moves:** `padL` is dropped. |
| **A6** Side tab | **h 30**, gap **5**, padX **9**, r11, stroke 1.5, FO **13**. Icon 22 + gap 7 + label laid out as **one group centred both ways** (icon width counted only when an icon is present). On/off states unchanged (gradCta Rot 0, stroke white T0, `glowTabOn`; off: `T.night` T.5, stroke white T.82) | `T.box.tab.*`, `T.r[11]`, `T.s.thin`, `T.t.tab`, `T.glowTabOn` | **Height 30** is the board's compact control height: B.toast h30 (L141), wallet h30 (L219), pbtn h30 (L307). The single tab height on the board is 34 (L183); the owner asked for "tighter". **Pitch** 35 (30+5, L182): hits trim to 35, which stays above the approved chip trim of 33 (GB:3, STOP 1 G1). Look: L183-184, Wi:846-857. |
| **A6b** Tab column | **One width for all hubs** = min(128, max over every built tab of (textW at `T.size(13)` + (22+7 if icon)) + 2·9 + 2·1.5), measured at runtime with TextService. **Est. ≈ 116** (icon tab "Collection" ≈ 62+29+21), so it stays ≤ 128 | `T.box.tab.colMax` | 128 = L179. A single global width keeps the content column from shifting between hubs. Fit, est. at FO 13 (no icon): inner 107 px; "Achievements" ≈ 84, "Accessibility"/"Convenience" ≈ 75–80. Large text (+2) still fits; `W.fit` is the backstop. The overflow audit confirms real widths. |
| **A7** Compact card | **h 71** = 2 + 10 + meta 17 + 4 + XP 10 + 3 + sub 13 + 10 + 2. **w 262** (same as expanded). Content inset x 14 (2+12); text/XP width = w − 28 = **234**. Meta FO 14 "Name · Lv N" (Hud:441). XP bar h10 (night T.3, stroke 1.5 white T.5, r6, fill gradAction). **Sub line** FO 11 at T.15 = **"N creatures · 0.03/s"**, with cash/s joined by " · " on the same line. Ring and creature icon removed (Q3); "summit reached" removed (owner: ONLY five items) | `T.box.pcard.*`, `T.r.glass`, `T.s.glass`, `T.t.pcardMeta`, `T.t.smallHud`, `T.textDimT[3]`, `T.wellT.xp` | Padding 10/12 r18 (L170), meta 14 (L173; line 17 = Hud:217), XP margins 4/3 (L606), XP bar (L51-52), sub 11 at .85 (L174; line 13 = normal 1.2×, GB:14). **Sub-line pattern:** board "12 creatures · 3 summits" (L606), so cash/s takes the board's second sub-line slot (same role, no new label). **Width 262:** no width jump on expand, so A9 is a pure height tween. Alternative: board w 230 (L170) for compact only. |
| **A8** Expanded card | **h 123** = compact content + gap **10** + launcher **42** + 10 + 2. Launcher at x 14, y = card top + 69. Five `dockButton` circles 42, gap `l.dockGap` (≥ 6). w = 2+12+5·42+4·dgap+12+2 (262 at dgap 6). **Same bottom as compact: H − 78** | `T.box.pcard.gap`, `.launch` | Gap 10 (L170). Launcher (Hud:220-224, UP:222). Bottom 78 (L170, UP:222): 10 above the dock top H−68 (UP:176). |
| **A9** Motion | `pcard.expand` = **`hero.mini` values**: tween .2 s, `ease='out'` (Quad Out), height both directions, bottom-anchored. `pcard.launcher` = show **`hero.fade`** (.2 s out, α 0→1), hide **`panel.close`** (.15 s linear, α 1→0), started with the height tween. First show keeps `pcard.open`. **Reduce effects / LOW: instant** (no `reducedFade`, so `M.to` = 0 s; `M.show` instant) | new tokens copying `Mo:92`, `Mo:93`, `Mo:90` | Owner §19: "hero mini .2 s", panel close .15 s fade (GB handoff L86). `pcard.open` (Mo:81). Reduced gate (Mo:160, :321, :339). Perf technique (clip vs glass size) is motion's call (BP R7). |
| **A10** Number format | Cash/s = `string.format('%.2f/s', rate)`: "0.03/s", "2.00/s", none producing = "0.00/s". Count = `tostring(n)..' creatures'` (Hud:444). Level "Name · Lv N" (Hud:441). No thousands separator: `P.comma` floors to integers (UP:291), and the late-game max is ≈ 2/s (`TycoonConfig.luau:4`) | — (copy, not a token) | Owner: 2 decimals, e.g. "0.03/s" (BP Q2). The `·` separator is from L606. Unit word: see O1. |

## OPEN (owner / reviewer)
| # | Item | Options (recommended first) |
|---|---|---|
| O1 | "0.03/s" has no unit. The coin icon is dropped from the card and every image is blank on device (R1). | (a) **"0.03 coins/s"**: owner format plus the unit word; (b) "0.03/s" exactly as given. |
| O2 | A6 height: the board has a single tab height (34). 30 is borrowed from other compact controls. | (a) **30** (pitch 35); (b) 27 = chip h27 + chip gap 6 (L196-197), which gives pitch 33, equal to the approved chip trim; (c) keep 34 and only centre and tighten the width. |
| O3 | Dialog pill style. F:reveal currently uses a gold title (Feedback:514, earlier owner decision); F:confirm is plain. | (a) **confirm = default cta; reward = gold recipe without chest and tails** (those are Shop decor, L215-218); (b) default cta for both. |
| O4 | With the chest moved out (A5), the left tail (−20…4) sits fully under the chest. On the board, about 8 px of it showed. | (a) **keep both tails at the board x** (left one hidden); (b) drop the left tail; (c) keep the right tail only. Board y: top 14 on the 42 plate (L216) = 2 px below the bottom. On 36 use **top = h − 28 = 8** (keeps that 2 px, **est.**) or the literal 14 (hangs 8 px). |
| O5 | The card is 6 px right of the dock axis: x = W/2 − 125 (UP:222, board artefact G23 from the 230 card). `CENTRED` in `_sa.luau` is only an exemption list, not a centring check. | (a) **centre on the dock axis: x = W/2 − w/2** (dock AP .5, L110); (b) leave as built. |
| O6 | A1: LG 23 in 36 gives a text/height ratio of .64, above any board button (max .59 claim 13/22, L255). | (a) **36 / 23**, reviewer checks optical centring at P4; (b) 42 / 23 (L180), tightening padX only. |

## Owner answers to the open items (2026-10-29)
1. Rate label: **"0.03 coins/s"** (format `%.2f coins/s`), bottom line "N creatures · 0.03 coins/s".
2. Side tab: **height 30, gap 5** (tap areas trim to 35).
3. Title pill: **height 36** (padX 12, text `T.t.menuTitle` 23); reviewer checks optical centring.
4. Dialog pill: **pink for confirm dialogs, gold without chest/tails for reward dialogs**.
5. Shop tails: **keep both** at ±20, top 8 (left one sits under the chest).
6. Card: **centre on the dock axis** (remove the 6 px offset).
