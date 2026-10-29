# VFX/UI intel A: references v1, v2, v3 (owner, 2026-10-27)

**Source:** `references/vfx-ui-2026-10-27/frames/{v1,v2,v3}/sheet_*.jpg` + `frames/README.md`. Videos in `videos/v1-v3.mov` (not decoded; no ffmpeg run). Style/technique source only: no text, names, logos or layouts are to be copied 1:1. Audio was not analysed (frames only).

## 0. Reading conventions

| Item | Rule |
|---|---|
| Time | t = cell index / fps. Index = (sheet-1)x8 + (row-1)x4 + (col-1). fps: v1 = 1, v2 = 1, v3 = 2 (README). Cells are sample points: uncertainty +-1 s (v1, v2), +-0.5 s (v3). Durations from neighbouring samples are bounds, not measurements. |
| Citation | `vN/sNN rR-cC (t=X s)` |
| Colour | Eye-estimates, marked (est.). Cells are 360 px wide lossy video. v1 is a phone filming a curved monitor (hue, gamma, bloom and perspective are all distorted). v2 is a Studio screen-recording whose game viewport is only about 22% of the frame area (est.: about 330 x 155 px inside a 360 x 640 cell), so most UI text is unreadable. Sample real pixels from the .mov before any asset is made. |
| Tags | OBS = seen in frames. REC = my recommendation, not observed. n/r = not resolvable at this resolution. |
| Hue policy | Hexes below document how colour *roles* work in each reference. They are not Climb & Collect tokens. C&C hues come from the owner's chosen palette (see conflict below). |

### Corrections to the brief (what the frames actually show)

| Brief said | Frames show |
|---|---|
| v3 plot swirls into a dark purple/black vortex with expanding white rings | A torus/donut ring of cubes (hole visible in the middle, v3/s01 r2-c2 to s02 r1-c1), not a black vortex. It then re-forms as the same plot re-skinned in dark purple/neon-blue (v3/s02 r1-c3 to r1-c4). It is a transformation/upgrade effect. White rings are 2-3 thin flat ellipses on the ground. From cell widths (est., low confidence): span about equals the plot at t=1.0, about 1.3x the plot at t=2.0-3.0 (one expand over about 1 s), holds to t=4.0, contracts by t=4.5. So "expanding rings" = one short expand, hold, contract; not a repeating pulse. |
| v1 = map/travel panel + warp cinematic | Also contains a third UI: a "Pickaxe Skins" collection/roll panel (v1/s02 r2-c3 to s03 r2-c3, t=14-22). |
| v2 = CAUGHT card, then carousel | It is a loop: CAUGHT card (t=0-2) -> carousel (t=3-10) -> CAUGHT card again with mutated result (t=11-14) -> back to world (t=15). |

### Conflict to flag to the owner (not decided here)

| Side A | Side B | Cost |
|---|---|---|
| Approved HUD v2: blue panels, yellow CTAs, Bangers labels (per `design/vfx-ui-intel-C-settings-screenshot-2026-10-27.md`) | v1/v2/v3 lean violet/magenta/neon + gold | REC: take the *techniques* (structure, timing, layering) and keep hue per moment from the owner's palette. If the whole game flips to violet-neon, HUD v2 must be re-skinned. |

### Pass 2 (2026-10-27): all 8 sheets re-read against pass 1; corrections made

| Change | Why |
|---|---|
| v2 viewport share 40-50% to about 22% of frame area | Measured from cell geometry: the game viewport is about 330 x 155 px of 360 x 640 |
| v1 scroll rests by t=3 (not t=4); panel hold 3-5 s (not ">= 4 s"); 11 stage cards | t=3 and t=4 frames are identical; 4 samples bound a duration, they do not prove 4 s |
| v1 skin-preview cycle: 9 samples = 6 distinct skins, about 1-1.5 s each, 4th tile not caught | Counted tile labels in the preview pane per sample |
| v3 ring: expand-hold-contract with estimated spans | Compared ring width to plot width across cells; low confidence, +-0.5 s |
| Added v2 layout table, v3 audio row, CanvasGroup and ViewportFrame cost caveats | Spec asks for layout/spacing; two Roblox cost claims were unverified |
| Monetisation lines now cite the owner's 2026-10-27 stance (odds shown on paid random items; no paid power in raids/theft) | Pass 1 called it undecided |
| Unchanged and re-verified | v2 LUCK hue order (purple, yellow, cyan, pink, green, purple, yellow, cyan, pink); carousel has landed on the "Galaxy" tile by t=6 (t=6 and t=7 identical); "Collect" absent t=12, present t=13; v1 title card present t=5-6, gone t=7; v3 shatter between t=1.0 and 1.5; reform between t=5.0 and 5.5; static camera |

Not resolvable from the sheets (do not guess): all small UI copy, odds percentages, price lines, ray-rotation speed (v2), particle counts per frame, audio, whether any post-FX (bloom, colour-correction) is real or camera/monitor artefact in v1.

---

## V1. Neon cosmic mining game (TikTok, monitor-filmed, ~23 s, 1 fps, 3 sheets)

### 1.1 What it is / why it feels premium

One line: mine-game travel menu -> "VOID ABYSS / NOW ARRIVING" mine-cart warp cinematic -> arrival -> pickaxe-skin collection panel.

| # | The move (OBS) | Evidence |
|---|---|---|
| 1 | One hue family (violet/magenta + white) rules panels, particles, props and text, so nothing fights. | s01 r2-c2..c4, s02 r1-c1 |
| 2 | The transition is *in-world*: a cart on rails through a tunnel of nested neon frames, not an abstract overlay. Arrival is a ride, then a hard stop in a lit station. | s01 r2-c2 to s02 r2-c2 |
| 3 | Title card is minimal: no panel, two-tier text (big name + small tracked sub-label), glow only. | s01 r2-c2, r2-c3 |
| 4 | Three particle classes at three scales (white dots, magenta shards/hearts, flat neon rings) give depth cheaply. | s01 r2-c3 |
| 5 | Destination list = poster wall: each stage is a hue-coded illustrated card, so the menu reads as content, not a list. | s01 r1-c3, r1-c4 |
| 6 | Panels are layered candy: dark outer line, bright frame, header bar with pills, overhanging red close. | s01 r1-c2; s03 r1-c1 |
| 7 | Shop preview is a staged diorama (disc platform, coloured backdrop, per-item ground FX), so selecting an item *is* a mini reveal. | s03 r1-c2, r1-c3, r1-c4 |

### 1.2 UI anatomy

#### Palette tokens (est.)

| Token | Hex (est.) | Role | Cell |
|---|---|---|---|
| v1.void-blue | #2A14D6 (est.) | warp base / scene bg | s01 r2-c2 |
| v1.violet | #7A1FE0 (est.) | tunnel mid-tone | s01 r2-c3 |
| v1.magenta | #F02BD8 (est.) | particles, neon frames, rings, skins-panel frame | s02 r1-c1 |
| v1.cart-pink | #FF3D9E (est.) | hero prop | s01 r2-c3 |
| v1.white | #FFFFFF (est.) | title, speed lines, star dots | s01 r2-c3 |
| v1.ring-yellow | #FFE83A (est.) | portal ring inner (yellow to magenta ramp) | s01 r1-c1 |
| v1.teal | #35E6D4 (est.) | Mines panel frame, header, TRAVEL | s01 r1-c2 |
| v1.indigo | #4A48B8 (est.) | Mines panel body well | s01 r1-c3 |
| v1.orange | #FFA11C (est.) | stat pill, featured-card CTA | s01 r1-c2 |
| v1.close-red | #E5233D (est.) | close button | s01 r1-c2 |
| v1.card-edge | #B88A2E (est.) | card border (gold-brown) | s01 r1-c3 |
| v1.here-grey | #D9DCE8 (est.) | "HERE" disabled chip | s01 r1-c3 |
| v1.skin-frame | #F03CC8 (est.) top to #8A2FD8 (est.) bottom | Skins panel frame gradient | s03 r1-c1 |
| v1.skin-stripe | #FF8FE0 (est.) | diagonal stripe on header | s03 r1-c1 |
| v1.preview-gold | #F6D41E (est.) to #E8A812 (est.) | preview backdrop | s03 r1-c1 |
| v1.tile-gold | #F2B51A (est.) | item tile frame | s03 r1-c1 |
| v1.tile-fill | #4B2390 (est.) | tile and info-card fill | s03 r1-c1 |
| v1.equip-green | #36D048 (est.) | primary CTA | s03 r1-c1 |
| v1.roll-gold | #FFC21C (est.) | secondary CTAs | s03 r1-c1 |

Stage hue coding (card art dominant colour, est.): Cosmic Mine blue-violet #3B3CC8; Golden Hollows amber #C8741C; Emerald Jungle green #2E9B3A; Magma Depths orange-red #D2461C; Infernal Core red #C0182A; Void Abyss indigo-purple #4B2BC0; Astral Depths blue #2D6BE0; Rainbow Mines pastel pink/blue #F0A8E0 and #9AD0F0 (all est., s01 r1-c3, r1-c4, r2-c1).

#### Panel A "Mines" (travel list): layer by layer (OBS, s01 r1-c2 to r2-c1, t=1-4)

| Layer | Construction |
|---|---|
| 1 Outer outline | thin dark navy/violet line, about 1-2% of panel height (est.) |
| 2 Frame | teal rim (v1.teal); gradient not resolvable |
| 3 Header bar | teal strip about 10-12% of panel height (est.). Left: icon tile + title "Mines" (white, dark stroke). Right: two pills (teal status pill, orange stat pill). Pill text is only low-confidence at this size: reads about "MINES OPEN 10/10" (teal) and "PICKAXE POWER 260" (orange), i.e. one progress pill + one stat pill |
| 4 Body well | indigo (v1.indigo), 2-column card grid, gutter about 2% of panel width (est.), vertical scroll |
| 5 Cards | see card anatomy |
| 6 Scrollbar | thin light-lavender bar on right edge, overlapping card edge (s01 r1-c3) |
| 7 Close | red rounded square, white X, about 6% of panel width (est.), straddles the top-right corner (about a third outside the frame) |
| 8 Glow / glass | none resolvable on the panel itself; inner shadow n/r. Bloom is on the scene behind |
| 9 Perspective | panel is warped by the curved monitor; do not read it as a 3D-tilted UI |

#### Card anatomy (Mines, s01 r1-c2 to r1-c4)

| Part | Observation |
|---|---|
| Art | Full-bleed illustrated scene per stage, hue-coded (see list above) |
| Shading | Dark gradient behind name text for legibility (est.) |
| Border | thin gold-brown edge (v1.card-edge) |
| Name | top-left, white bold title-case with dark stroke, about 0.6x panel-title size (est.) |
| Level badge | small round numbered badge at the corner (purple, orange or green fills seen); digits barely legible |
| Resource row | row of 4-5 tiny coloured gem glyphs bottom-left (n/r individually) |
| CTA | TRAVEL button bottom-right, about 25% card width x 30% card height (est.): teal for normal, orange for the featured card |
| Current state | "HERE" grey chip replaces the CTA on the current stage (s01 r1-c3) |
| Featured variant | one wide full-row card at top (Haunted Hollow, s01 r1-c2) with larger title, 2-3 description lines, orange CTA |
| Aspect | about 3:1 w:h (est.; monitor distortion possible) |

#### Panel B "Pickaxe Skins" (collection + roll): layer by layer (OBS, s02 r2-c3 to s03 r2-c3, t=14-22)

| Layer | Construction |
|---|---|
| 1 Frame | magenta-to-violet vertical gradient (v1.skin-frame), outer dark line |
| 2 Header strip | lighter pink with diagonal stripes (v1.skin-stripe); title "Pickaxe Skins" left (white, dark stroke); two orange pills right (collection count "x / 38" style, equipped label); red close overhanging the top-right |
| 3 Left column (about 30% width, est.) | Preview card: yellow gradient backdrop, rotating 3D item on a white disc, item name bottom-left in white + stroke, tiny "PREMIUM" tag top-left, 2-line description (n/r). Below it: full-width green EQUIP button |
| 4 Right column top | Violet info card: small tag pill, price lines (n/r), two gold buttons (ROLL x1, ROLL x10), a 5-tier odds line in tiny coloured text (tier words appear to read common-to-legendary; percentages n/r) |
| 5 Right column grid | Section strip "PREMIUM - ROBUX" with owned counter; 5-per-row tiles with gold frame, dark-violet fill, item render, name, "OWNED" sub-label; selected tile shows a small green check (s02 r2-c3); empty slots are a dark dotted-grid texture |
| 6 Footer strip | pink strip "SECRET - event" with counter |

#### Button recipe (OBS where noted)

| Button | Fill | Shape | Text | Size/position |
|---|---|---|---|---|
| TRAVEL | flat teal (orange when featured), lighter top band (est.) | rounded rect, radius about 25-30% of height (est.) | white all-caps bold, dark stroke | bottom-right of card |
| HERE | light grey, no saturation | same shape | dark/grey text | replaces CTA (state change by desaturation) |
| EQUIP | green, lighter top highlight | wide pill/rounded rect | white all-caps bold | full left-column width, about 10% of panel height (est.) |
| ROLL x1 / x10 | gold with white edge (est.) | rounded rect, side by side | text colour n/r | right-aligned in info card |
| Close | red + white X | rounded square | none | overhangs top-right corner |

#### Typography

| Element | Letterforms (OBS) | Case | Colour/stroke | Relative size | Candidate faces (license) |
|---|---|---|---|---|---|
| Panel titles ("Mines", "Pickaxe Skins") | heavy, round-terminal, slightly wide sans | Title Case | white fill, dark thick stroke (about 10-15% of cap height, est.) | 1.0x | Fredoka (SIL OFL), Lilita One (OFL), Baloo 2 (OFL). Roblox built-in Enum.Font such as FredokaOne needs no upload |
| Card names | same family, smaller | Title Case | white + dark stroke | about 0.6x | same |
| Buttons / chips | same family or one weight down | ALL CAPS | white + dark stroke | about 0.4-0.5x | same |
| Warp title "VOID ABYSS" | clean geometric bold sans, round O, no italic seen (n/r) | ALL CAPS | white fill (possibly a lilac-to-white vertical gradient, n/r), soft magenta outer glow, thin or no stroke | 1.0x (title card) | Montserrat (OFL), Poppins (OFL), Roblox GothamBold/GothamBlack (Roblox-only use) |
| Warp sub-label "NOW ARRIVING" | same sans, lighter weight, wide letter-spacing | ALL CAPS | white, glow | about 0.4x of title (est., s01 r2-c2) | same |

Icon style: glossy, chunky, low-poly/isometric renders on tiles (pickaxes), tiny flat gem glyphs for resources; white specular highlights. Detail n/r.

Layout/composition rules (OBS): panel fills about 60-70% of viewport width and about 50% of height, centred low (s01 r1-c3); title card sits at upper-third, centred, over the action with no backing panel (s01 r2-c2); the cart (hero) stays bottom-centre, tunnel vanishing point centre-up. Hue = place (stage), gold border = item tile, grey = disabled/current, orange = special (featured, stat), green = confirm/primary, red = close only.

### 1.3 VFX / motion timeline (OBS)

| ID | t (s) | Cell | Element | What it does | Dur (bound) | Easing impression | Layers |
|---|---|---|---|---|---|---|---|
| E1.01 | 0 | s01 r1-c1 | Ambient portal + planet | Neon ring yellow-to-magenta, banded voxel planet, avatar small at left; HUD quest tracker top-centre, green SELL bottom-left. Static in this sample | n/a | n/a | bloom/glow on ring |
| E1.02 | 0 to 1 | s01 r1-c1 to r1-c2 | Mines panel opens | Full-size by t=1; open animation n/r | <= 1 s | n/r | UI only; world behind still visible, no obvious blur |
| E1.03 | 1 to 3 | s01 r1-c2 to r1-c4 | List flick-scroll | top of list at t=1 (wide featured card, then Grassland Quarry / Crystal Caverns, then Cosmic Mine / Golden Hollows); about 2 rows t=1 to 2; about 1 row t=2 to 3; frames t=3 and t=4 are identical, so the list rests at its end (Astral Depths / Rainbow Mines last) by t=3. 11 stage cards seen in total | about 2 s | decelerating (inertial) | scrollbar visible |
| E1.04 | 1 to 4 | s01 r1-c2 to r2-c1 | Panel hold | panel on screen in 4 consecutive samples (t=1-4) | 3-5 s | n/a | n/a |
| E1.05 | 4 to 5 | s01 r2-c1 to r2-c2 | TRAVEL -> warp | Panel gone and tunnel scene full-screen at t=5. Cut/transition style n/r | <= 1 s | n/r | n/r |
| E1.06 | 5 to 6 | s01 r2-c2, r2-c3 | Title card | "VOID ABYSS" + smaller "NOW ARRIVING" centred upper-third; present t=5 and t=6, gone at t=7 | 1-3 s | n/r | text glow; a passing pink ring overlaps the O of "NOW" at t=6 |
| E1.07 | 5 to 8 | s01 r2-c2 to s02 r1-c1 | Tunnel of nested neon frames | Square frames rush toward camera; cart centred bottom on twin rails, camera behind/above; strong perspective (wide FOV, est.) | about 3-4 s | constant speed feel | geometry; bloom on magenta |
| E1.08 | 6 to 8 | s01 r2-c3, r2-c4; s02 r1-c1 | Speed lines | thin white radial lines from the vanishing point, about 8-14 visible at t=6-7, edge-only at t=8, none by t=10 | about 3 s, fade-out | linear, then cut/fade | 2D or 3D streaks |
| E1.09 | 5 to 8 | same | White star dots | round dots drifting outward, about 10-20 visible at t=6, fewer t=7 | about 3 s | outward accel (est.) | particles |
| E1.10 | 5 to 9 | same | Magenta shards/hearts | about 4-8 visible, rotating, bright white core + pink body | about 4 s | drift + spin | particles, additive |
| E1.11 | 6 to 7 | s01 r2-c3, r2-c4 | Neon torus ring | flat magenta ring bottom-left, size about 8% of viewport width (est.), spinning past camera | about 1-2 s | n/r | Neon part + bloom |
| E1.12 | 8 to 9 | s02 r1-c1, r1-c2 | Exit gate | dark rectangular opening with glowing-antler character visible in it; frames larger/closer | about 2 s | slowing | geometry |
| E1.13 | 10 to 11 | s02 r1-c3, r1-c4 | Station arrival | speed lines gone; cart on brick-walled station with branching rails; pink glow; small pink diamond sparkles at the character; small grey interaction prompt at right | about 2 s | decel to stop | light + sparkles |
| E1.14 | 12 to 13 | s02 r2-c1, r2-c2 | Hand-off to gameplay | camera drops/angles to third-person; magenta glow orbs in distance; white sparks on avatar; HUD (quest bar, SELL) back by t=13 | about 2 s | n/r | HUD returns |
| E1.15 | 13 to 14 | s02 r2-c2 to r2-c3 | Skins panel opens | full by t=14; open anim n/r | <= 1 s | n/r | UI |
| E1.16 | 14 to 22 | s02 r2-c3 to s03 r2-c3 | Preview swap per selection | 9 samples cover 6 distinct skins in tile order (Void t=14-15, Lava Forge t=16-17, Oceanic Trident t=18, Nature's Reaper t=19-20, Cyber Drill t=21, Kittycorn t=22): about 1-1.5 s per skin. The 4th tile (Cosmic) was not caught, so it was skipped or shown < 1 s. Auto-cycle vs. taps is n/r. 3D item rotates on white disc; per-item ground FX: yellow burst ring + glow (t=17), red radial crack lines (t=18), red block shard (t=19) | FX about 1 s each | burst-then-fade | ViewportFrame-like 3D + decals |

Not observed in v1: screen flash, camera shake, DOF, chromatic aberration. Dutch tilt at t=10 is probably handheld filming (do not copy). Whole select-to-control ride = about 8-9 s (t=5 to t=13), long for a phone loop.

### 1.4 Roblox build recipe (REC unless stated; start values to tune on device)

| ID | Effect | Primitives and starting values | Mobile cost |
|---|---|---|---|
| R1.01 | Scrollable stage list | ScrollingFrame + UIGridLayout (2 columns) + UIPadding; card = Frame + UICorner + ImageLabel (art) + UIGradient dark overlay + UIStroke (edge); ScrollingFrame inertia is built in | cheap (cost is image count: use at most about 12 art images, atlas where possible) |
| R1.02 | Candy panel | Frame + UICorner; UIStroke outer dark (about 1-2% of panel height, observed est.); inner Frame with UIGradient (2-stop vertical); header Frame with UIGradient (diagonal stripe image or Rotation=45 stripes); close = ImageButton/TextButton with ZIndex above frame, Position offset so about 30% overhangs | cheap |
| R1.03 | Panel open | UIScale 0.85 to 1.0 + CanvasGroup.GroupTransparency 1 to 0, TweenService 0.18-0.25 s, EasingStyle.Back Out (observed bound: <= 1 s) | cheap (one CanvasGroup at a time: it composites its subtree off-screen first; verify fill-rate on a low-end phone) |
| R1.04 | State chips/buttons | TextButton + UIStroke (text stroke via ApplyStrokeMode.Contextual); disabled = desaturate fill, swap label to HERE-style; press = UIScale 1 to 0.94 to 1 in 0.08 s | cheap |
| R1.05 | Warp title card | Two TextLabels, no backing frame. Roblox has no letter-spacing property: insert thin spaces (U+2009/U+200A) between glyphs or build per-glyph labels for the sub-label. UIStroke thin + a soft glow via an ImageLabel (9-slice radial glow) behind. Fade/scale in 0.2 s, hold about 1.5-2 s, fade 0.3 s | cheap |
| R1.06 | Speed lines (2D, preferred) | 16-24 thin Frames/ImageLabels in a full-screen ScreenGui, each rotated to angle theta and anchored at screen centre; tween Position outward + Size.Y stretch + Transparency 0.3 to 1 over 0.25-0.4 s, staggered, looping while active. IgnoreGuiInset true | cheap |
| R1.07 | Speed lines (3D alternative) | ParticleEmitter on a Part 20-30 studs ahead of camera: Orientation = VelocityParallel, Speed 80-150, Lifetime 0.3-0.5, Size small, LightEmission 1, Rate 30-60 | medium (overdraw) |
| R1.08 | FOV kick | Camera.FieldOfView tween 70 to about 85-95 over 0.35 s (Quad Out), hold, return over 0.6 s (Sine InOut). Pair with R1.06. Offer reduce-motion toggle | cheap |
| R1.09 | White star dots | ParticleEmitter: Rate 20-40, Lifetime 0.6-1.2, Speed 40-80, SpreadAngle 180, Size 0.15-0.4, LightEmission 1, Texture = soft dot | cheap |
| R1.10 | Magenta shards/hearts | ParticleEmitter: Rate 10-25, Lifetime 0.8-1.5, Speed 20-50, RotSpeed -180 to 180, Size 0.5-1.2 (NumberSequence shrink), LightEmission 0.8-1, ColorSequence = destination hue to white; needs a diamond/heart texture asset (not yet made) | cheap to medium |
| R1.11 | Neon torus ring | Part (torus mesh) Material Neon, rotate 90-180 deg/s via Heartbeat; or flat ring ImageLabel/Decal | cheap |
| R1.12 | Tunnel of frames | 8-12 frames, each 4 thin Neon bars; move toward camera and recycle at the far end (single Heartbeat loop, BulkMoveTo). Only if a tunnel actually exists in C&C | medium |
| R1.13 | Look grade | BloomEffect Intensity 0.6-1.2, Size 24-40, Threshold 0.8-0.95; ColorCorrectionEffect TintColor toward destination hue, Saturation +0.1 to +0.25, tween in/out with the moment. Post effects may be skipped at low graphics quality: verify | medium |
| R1.14 | Preview diorama | ViewportFrame + WorldModel with item rotating about 45-90 deg/s; ground FX as UI rings (ImageLabel scale 0.3 to 1.4, Transparency 0 to 1, 0.4-0.5 s) over the viewport rather than 3D particles (ParticleEmitters are believed not to render inside a ViewportFrame: verify in the current engine before relying on either) | medium (limit to 1 ViewportFrame live; stop updating when hidden) |
| R1.15 | Audio cues (n/r in frames) | SoundService: panel-open pop, whoosh riser during travel (PlaybackSpeed 0.9 to 1.1 over the ride), arrival impact + chime | cheap |

### 1.5 Mapping to Climb & Collect

| Moment | v1 technique that fits | Why | Limit / adaptation (REC) |
|---|---|---|---|
| Section unlock/arrival ("now arriving") | E1.06 two-tier name card + E1.08 speed lines + E1.09 dots + R1.13 look-grade pulse (REC) | Direct analogue: name the kingdom, tag it, let the world hue-wash for 1-2 s | Cut the 8-9 s ride to about 2-3 s. Use the section's own hue, not magenta. No tunnel needed |
| Section select / map | Panel A stage cards with hue per stage, status chip (HERE), featured wide card | Six kingdoms = six hue-coded cards; locked/current/available states by chip + desaturation | Climb & Collect lets all sections be attempted from the start (design record 2026-10-25): chips are HERE / SECURED-COUNT, not LOCKED |
| Guardian chase | E1.08 speed lines + E1.09 dots (OBS), plus R1.08 FOV kick (REC, not observed), in a danger hue | Cheapest way to make speed and threat readable on a phone | Only while chased; never during rest. Respect a reduce-motion toggle |
| Shop / bat-skin collection | Panel B: preview diorama + tile grid + EQUIP/roll CTAs + section strips | Bats have their own look/trail per level (owner rule 2026-10-26): a preview that shows the trail on selection is the same pattern | Roll UI: owner stance 2026-10-27 (project memory `overhaul-plan-decisions`) = paid random items only with odds shown, no paid power in raids or theft. So a roll button is cosmetic/convenience-only and needs a legible odds line (v1's odds line is about 7 px in the cell, n/r: make ours readable). Whether to ship rolls at all is still the owner's call |
| Level-up | Panel B tile "OWNED" check + pill counters | Counter pills (x / 38 style) give progress at a glance | Minor source |
| Summit | E1.06 title card on an otherwise clean screen | One name, one sub-label, nothing else | Pair with V2 sunburst |
| SKIP | Tunnel of neon frames, mine-cart prop, 8-9 s ride, magenta palette, Dutch tilt, quest tracker text, odds line | Prop/theme-specific, too long, or palette conflict | n/a |

---

## V2. Loot/luck reveal (TikTok, Studio screen-recording, ~16 s, 1 fps, 2 sheets)

### 2.1 What it is / why it feels premium

One line: "CAUGHT!" result card -> full-screen sunburst reward carousel (anticipation, spin, near-miss settle) -> mutated result card -> collect.

| # | The move (OBS) | Evidence |
|---|---|---|
| 1 | Three-phase structure: result, anticipation, reveal, result again with a bigger number. The mutation changes the answer. | s01 r1-c1 to s02 r2-c4 |
| 2 | Sunburst backdrop (alternating gold and near-black rays + dark vignette) swaps the whole world out: instant "jackpot" signal. | s01 r1-c4 to s02 r1-c3 |
| 3 | The LUCK multiplier badge is the biggest element and cycles hue through 5 colours, so the screen is alive while the carousel runs. | s01 r1-c4 to s02 r1-c4 |
| 4 | Slot-style carousel with a fixed gold selector (diamonds top and bottom) and a hover-then-move settle (Elixir at t=5, lands on Galaxy at t=6). | s01 r2-c2, r2-c3 |
| 5 | Copy escalates: "SOMETHING RARE IS COMING..." (gold, small) then "DIVINE BLESSING!" (white) then a mutation line (salmon). | s01 r2-c1; s02 r1-c1 |
| 6 | The result card counts up: multiplier and TOTAL tick through values, stat chips fill in. | s01 r1-c1 to r1-c3 |
| 7 | A forced beat before the CTA: "Collect" appears about 1 s after the card lands. | s02 r2-c1 vs r2-c2 |

### 2.2 UI anatomy

#### Palette tokens (est.)

| Token | Hex (est.) | Role | Cell |
|---|---|---|---|
| v2.parchment | #F2E2B6 (est.) | result card body | s01 r1-c1 |
| v2.card-trim | #D9A84A (est.) | card border/ribbon | s01 r1-c1 |
| v2.ink-brown | #5A3A14 (est.) | card title text | s01 r1-c1 |
| v2.total-green | #38D860 (est.) | TOTAL value | s01 r1-c3 |
| v2.chip-teal | #2FB8D0 (est.) | stat chips | s01 r1-c2 |
| v2.chip-violet | #7A3CE0 (est.) | descriptor pill | s01 r1-c1 |
| v2.chip-orange | #F5A623 (est.) | rarity pill under name | s01 r1-c1 |
| v2.ray-light | #F4BE22 (est.) | sunburst light rays | s01 r1-c4 |
| v2.ray-dark | #3A2606 (est.) | sunburst dark rays | s01 r1-c4 |
| v2.vignette | #120C04 (est.) | edge darkening | s01 r2-c1 |
| v2.slot-fill | #2A1A5C (est.) | carousel card fill | s01 r2-c2 |
| v2.slot-blue | #4C8CF0 (est.) | Elixir card edge | s01 r2-c2 |
| v2.slot-violet | #A04CF0 (est.) | Galaxy card edge | s01 r2-c3 |
| v2.slot-green | #3DBE5A (est.) | cash card edge | s01 r2-c3 |
| v2.selector-gold | #FFD23A (est.) | selected frame + diamond markers | s01 r2-c3 |
| v2.title-gold | #F2C23A (est.) | anticipation title | s01 r2-c1 |
| v2.title-white | #FFFFFF (est.) | reveal title | s02 r1-c1 |
| v2.sub-salmon | #FF7F9A (est.) | mutation line | s02 r1-c1 |
| v2.luck-cycle | #7A4CE0 (est.) purple, #F2D83A (est.) yellow, #4EB8E8 (est.) cyan, #F04CC0 (est.) pink, #4CE04C (est.) green | LUCK badge fill, in this order | s01 r1-c4 to s02 r1-c4 |
| v2.collect-gold | #F5B82A (est.) | Collect button | s02 r2-c2 |

#### Result card "CAUGHT!" (s01 r1-c1 to r1-c3; s02 r2-c1 to r2-c3): layer by layer

| Layer | Construction (OBS, details n/r where noted) |
|---|---|
| Size/position | about 30% viewport width x 85-90% viewport height, centred (est.); portrait-ish card; world behind visible, dimmed (about 30-40% black, est.) |
| 1 Shadow | soft dark drop shadow (n/r exact) |
| 2 Body | parchment (v2.parchment), lighter toward the top (est.) |
| 3 Trim | tan/gold border about 3% of card width, small corner radius |
| 4 Header | "CAUGHT!" centred, dark brown (v2.ink-brown), heavy, with light outline/glow (n/r) |
| 5 Item row | square icon tile left; item name bold + orange rarity pill + purple descriptor pill right; 1-2 micro lines (n/r) |
| 6 Stat block | 3-4 label/value micro rows; values green/teal (n/r) |
| 7 Multiplier row | dark navy tile with white heavy "X1 / X51.3 / X106" left; 3 coloured chips with item icons right; at t=12 one chip reads as the mutation line |
| 8 Footer | "TOTAL" micro label + large green number right-aligned |
| 9 CTA | gold "Collect" button appears about 1 s after the card is fully on screen (s02 r2-c1 none, r2-c2 present) |
| 10 Blue top glow | at t=2 a pale-blue light sweep on the top edge of the card (s01 r1-c3); n/r whether intentional |

#### Reveal screen (carousel): layer by layer (s01 r1-c4 to s02 r1-c3)

| Layer | Construction |
|---|---|
| 1 Backdrop | full-screen sunburst: alternating v2.ray-light/v2.ray-dark rays from the centre, dark vignette to near-black corners; opaque, world fully replaced; ray rotation n/r at 1 fps |
| 2 Title | top-centre small heavy text with dark outline: gold "SOMETHING RARE IS COMING..." (t=4-7), white "DIVINE BLESSING!" (t=8-10). A faint ghost of "CAUGHT!" sits behind the title (t=4-7): looks like a cross-fade leftover, not a design |
| 3 LUCK badge | left of row, about 21% viewport width x 42% height (est.), rounded rect, flat hue fill from the 5-colour cycle, small darker "LUCK" top band with a clover icon, huge white "X106" with dark stroke below (about 1.9x the LUCK label cap height, est.) |
| 4 Card row | 5-7 cards, row spans about 75% viewport width (est.); each card about 17% width x 38-44% height; dark violet fill, coloured rounded border by item type, glossy icon, name micro-label bottom |
| 5 Centre slot | fixed on screen: card there is about 10-15% larger, gold border, gold diamond markers on top and bottom edges |
| 6 Winner state | at t=8 centre card gets a thicker double gold frame, soft glow, and a one-frame burst of white/lilac sparkles around card + badge (s02 r1-c1); neighbours stay dark |
| 7 Subtitle | salmon "IT TURNED GALAXY!" under the row (t=8-10) |
| 8 Exit | t=11: backdrop crossfades to the world while the CAUGHT card scales in small and semi-transparent, slightly rotated, from upper-centre (s02 r1-c4) |

#### Button, typography, icon, value coding

| Topic | Observation |
|---|---|
| Button | Only one: "Collect", gold rounded rect, bottom-centre of the card; label n/r beyond the word |
| Typography | Heavy, slightly condensed rounded display with thick dark outline for "X106", "CAUGHT!", titles. Micro labels bold, white, outlined. Candidates: Luckiest Guy (Apache 2.0), Lilita One (OFL), Bangers (OFL). Roblox built-ins LuckiestGuy/Bangers need no upload |
| Size ratios (est.) | X106 about 1.9x LUCK label; titles about 0.5x X106; card names about 0.4x X106; chips micro |
| Icon style | Glossy, chunky, 3D-rendered potions/gems/cash with sparkles; flat star badge on top-tier card |
| Rarity/value coding | No explicit rarity ladder legible. Value is coded by: size (X106 is the biggest element), hue cycle on the badge, gold selection frame, star mark on the top-tier tile, violet edge + name change for the mutation ("Galaxy"), and a green number with magnitude suffix (K/M style) that jumps from +3.6M to +68.4M to +168.4M (est. readings) |

#### Layout / composition / spacing (v2, est., % of the game viewport, not of the video frame)

| Element | Placement | Cell |
|---|---|---|
| Result card | centred, about 31% W x 87% H, small top margin; world visible behind, dimmed | s01 r1-c1 |
| Card internal order | header, item row, stat block, then multiplier row + TOTAL footer (bottom quarter), CTA below the footer | s01 r1-c3; s02 r2-c2 |
| Reveal title | about 25% from the top, centred on the screen (not on the row) | s01 r2-c1 |
| LUCK badge | left-anchored, left margin about 12%, vertical centre about 55% | s01 r2-c1 |
| Carousel row | starts right of the badge (gap about one tile width); spans about 37-80% of height; runs past the right viewport edge (clipped or covered, n/r) | s01 r2-c2 |
| Selector slot | not screen-centred: sits right of centre at about 63-70% of width, so badge + row read as one lockup | s01 r1-c4; s02 r1-c1 |
| Subtitle | under the row at about 80% height, centred | s02 r1-c1 |
| Spacing | tile gap about 8-10% of tile width (est.); tiles slightly portrait (about 1 : 1.3) | s01 r2-c3 |

### 2.3 VFX / motion timeline (OBS)

| ID | t (s) | Cell | Element | What it does | Dur (bound) | Easing impression | Layers |
|---|---|---|---|---|---|---|---|
| E2.01 | 0 to 2 | s01 r1-c1 to r1-c3 | Result card counts | multiplier X1 to X51.3 to X106; TOTAL +3.6M to about +17.7M to about +68.4M (est. readings); stat chips fill in at t=1 | about 2 s | steps of about 1 s are aliased from 1 fps; true tick rate n/r | UI text |
| E2.02 | 2 to 3 | s01 r1-c3 to r1-c4 | Card -> reveal screen | card gone, sunburst + LUCK badge + carousel present at t=3; transition style n/r | <= 1 s | n/r | full-screen swap |
| E2.03 | 3 to 6 | s01 r1-c4 to r2-c3 | Carousel spin | centre item: Elixir (t=3), Sleepy-Syrup-like (t=4), Elixir (t=5), Galaxy (t=6). Identical layout at t=6 and t=7 so it has landed by t=6 | about 3 s | fast start, decelerating, one-step near-miss then settle | row translate |
| E2.04 | 3 to 11 | s01 r1-c4 to s02 r1-c4 | LUCK badge hue cycle | purple(3), yellow(4), cyan(5), pink(6), green(7), purple(8), yellow(9), cyan(10), pink(11): strict 5-colour order, at least 1 step/s | continuous | step or fast tween (n/r) | flat hue fill |
| E2.05 | 4 to 7 | s01 r2-c1 to r2-c4 | Title "SOMETHING RARE IS COMING..." | gold, small, top-centre, present t=4 to 7 (absent t=3) | about 3-4 s | n/r | text |
| E2.06 | 8 | s02 r1-c1 | Winner burst | title swaps to "DIVINE BLESSING!"; winner frame thickens; sparkle burst around centre card and badge; salmon "IT TURNED GALAXY!" appears | burst <= 1 s (gone by t=9) | pop | sparkles (about 10-20 white/lilac dots, est.) |
| E2.07 | 8 to 10 | s02 r1-c1 to r1-c3 | Hold | layout static; badge keeps cycling | about 3 s | n/a | n/a |
| E2.08 | 10 to 12 | s02 r1-c3 to r2-c1 | Back to result card | sunburst crossfades to world; CAUGHT card scales up from small, tilted, translucent (t=11) to full (t=12) with X106, mutation chip, "Giant Galaxy"-type name, TOTAL +168.4M (est. reading) | about 1-2 s | scale-up with settle | crossfade |
| E2.09 | 12 to 13 | s02 r2-c1, r2-c2 | CTA delay | "Collect" button appears about 1 s after card lands | about 1 s | fade | UI |
| E2.10 | 14 to 15 | s02 r2-c3, r2-c4 | Collect | card dismissed; the new entity (purple/white flying creature) now in the world with a small green-white sparkle cluster near it | <= 1 s | n/r | world particle |

Not observed in v2: camera movement/FOV, shake, blur, screen flash. Ray rotation and card tick audio n/r (1 fps, audio not analysed).

### 2.4 Roblox build recipe (REC; start values to tune)

| ID | Effect | Primitives and starting values | Mobile cost |
|---|---|---|---|
| R2.01 | Result card | CanvasGroup (GroupTransparency, UIScale), Frame + UICorner + UIStroke trim, UIGradient on body; pop-in: UIScale 0.6 to 1.05 to 1.0 over 0.3 s (Back Out) + rotation -4 to 0 deg | cheap |
| R2.02 | Count-up | NumberValue tweened 0.6-1.0 s (Quad Out); on Changed format with K/M/B/T suffix into TextLabel. Stagger: multiplier first, chips pop at 0.1-0.15 s intervals (scale 0 to 1, Back Out), TOTAL last | cheap |
| R2.03 | Sunburst backdrop | Best: one ray-pattern ImageLabel (needs a texture asset; not yet made) rotated 6-12 deg/s via Heartbeat. No-asset fallback: 12-16 long thin Frames rotated about a centre inside a ClipsDescendants frame, alternating two colours, plus a radial vignette ImageLabel. Fade in 0.25 s | cheap |
| R2.04 | Carousel | Frame with 15-25 pre-rolled cards in a UIListLayout (horizontal), winner at a pre-chosen index; tween Position.X over 3.0-3.5 s with EasingStyle.Quint Out; add a final +1 card overshoot step (near-miss) of 0.25 s before settling. Server decides the winner first; the client only animates. Centre slot = fixed overlay frame | cheap |
| R2.05 | Selector | Two small rotated squares (gold, UIStroke) at top/bottom of the centre slot; centre card scale 1.12-1.15 + gold UIStroke; on each card crossing the slot fire a tick Sound (PlaybackSpeed ramps 1.0 to 1.5 as it slows is the usual trick) | cheap |
| R2.06 | Luck badge hue cycle | TweenService on BackgroundColor3 across the 5 hues, 0.2-0.5 s each (observed: at least 1 step/s). Keep colour change rate under 3 per second (flash-safety). Pulse UIScale 1 to 1.08 on each step | cheap |
| R2.07 | Title ladder | One TextLabel; swap text with a 0.15-0.25 s scale-pop + colour change (gold to white); mutation line fades in 0.2 s under the row | cheap |
| R2.08 | Winner burst | 12-20 star ImageLabels spawned at the centre card, tween outward 40-90 px + Transparency 0 to 1 over 0.5-0.7 s; thick gold frame scale-pop 1.0 to 1.2 to 1.15 | cheap |
| R2.09 | CTA delay | Collect button fades in after 0.8-1.2 s; ignore input until visible | cheap |
| R2.10 | World dim | Fullscreen black Frame Transparency 0.6 to 0.65 under the card (observed est. 30-40% black) | cheap |
| R2.11 | Spawn after collect | Client ParticleEmitter burst on the new creature (Rate 0, :Emit(12-20)), Lifetime 0.6-1.0, LightEmission 0.6 | cheap |

### 2.5 Mapping to Climb & Collect

| Moment | v2 technique | Why | Limit / adaptation (REC) |
|---|---|---|---|
| Rarity reveal | E2.04 hue-cycling badge + E2.05 anticipation copy + E2.03 carousel + E2.06 winner burst | Builds anticipation and communicates value even before the result is read | Place the *long* version (about 8-10 s) in the safe sanctuary after the creature is secured, not at the nest: owner rule 2026-10-26 says an unsecured creature can be stolen and a serious fall loses it, so a full-screen takeover at the nest would be a vulnerability. At the nest use a 1.5-2.5 s in-world reveal (see V3) |
| Banking (creature secured at mountain exit) | E2.01 result card with count-up + E2.09 delayed Collect | Banking is the safe, rewarding beat: totals ticking up sells "it's yours now" | Count what is meaningful in C&C (creatures secured, coins, XP), not a multiplier |
| Hatch (sanctuary/incubation, if kept) | E2.08 "mutated result" second card | A second, bigger card after the reveal gives a "it turned X" beat for mutations/variants | Needs a mutation/variant rule from the owner; do not invent one |
| Level-up | E2.01 count-up + E2.02 stagger chips | Cheap, readable | Short: 1.0-1.5 s |
| Shop / daily reward | E2.03 carousel (spin for daily reward) | Familiar slot read | Rewards server-decided; any paid spin must show odds (owner stance 2026-10-27); a free daily spin has no such constraint |
| Summit | E2.03 backdrop (sunburst) + E2.05 title swap | Biggest "you did it" signal for the rarest moment | Use once per summit; consider reduce-motion fallback (static rays) |
| SKIP | LUCK multiplier concept, "Giant Shark" naming/copy, the parchment+gold theme (own palette needed), world fully hidden during reveal on the mountain | Not C&C mechanics; exposure risk | n/a |

---

## V3. Roblox Studio VFX: plot transformation (TikTok, ~9 s, 2 fps, 3 sheets)

### 3.1 What it is / why it feels premium

One line: a green fenced plot charges with orbiting streaks, shatters into a ring of cubes that darkens and picks up cyan glow cubes, then reassembles as a neon-purple version of the same plot. Static camera throughout.

| # | The move (OBS) | Evidence |
|---|---|---|
| 1 | Four readable beats: charge (about 1 s), break, swirl + recolour (about 2.5 s), reform (about 1.5 s). | s01 r1-c2 to s02 r1-c4 |
| 2 | Telegraph before action: thin white orbit streaks and a ground ring appear before anything breaks. | s01 r1-c2, r1-c3 |
| 3 | The "before" material is the debris: the same fence boards and grass cubes become the swirl, so the audience tracks the object through the change. | s01 r1-c4 to r2-c1 |
| 4 | Colour story: green to near-black violet. A small fraction of cubes (about 10%, est.) flips to glowing cyan; bloom does the rest. One hot accent on a dark mass. | s01 r2-c2 to r2-c4 |
| 5 | Pieces are real parts casting shadows on the baseplate, which grounds the effect (and is also what makes it expensive). | s01 r2-c1 to s02 r1-c1 |
| 6 | Restraint: no camera shake, no flash, no text, one ring motif. | whole clip |
| 7 | Clean settle: orbit streaks fade out by t=6 and the final prop has subtle cyan edge lines, which reads as "done". | s02 r1-c4 to s03 |

### 3.2 UI anatomy

None (no UI). Only an overlay caption (not game UI). Palette tokens (est.), for the VFX:

| Token | Hex (est.) | Role | Cell |
|---|---|---|---|
| v3.sky | #58C4F0 (est.) | scene sky (clear blue, soft clouds) | s01 r1-c1 |
| v3.floor | #7A7280 (est.) | baseplate (studs visible) | s01 r1-c1 |
| v3.grass | #6BD83A (est.) | plot plate | s01 r1-c1 |
| v3.fence-brown | #7A3E1E (est.) | original fence | s01 r1-c1 |
| v3.debris-dark | #231B5E (est.) | pieces after recolour | s01 r2-c3 |
| v3.debris-violet | #5B2FC0 (est.) | pieces mid-colour | s01 r2-c3 |
| v3.cyan-glow | #35E8FF (est.) | accent glow cubes | s01 r2-c3 |
| v3.ring-white | #FFFFFF (est.) | orbit streaks, ground rings | s01 r1-c3 |
| v3.new-fence | #4A55F0 (est.) | final fence rails | s02 r1-c4 |
| v3.new-cap | #8A44F0 (est.) | final post caps | s02 r1-c4 |
| v3.new-floor | #1E1450 (est.) with #C03AE0 (est.) speckle | final plate (galaxy-like speckle) | s02 r2-c1 |
| v3.late-streaks | white, #E04CE0 (est.) magenta, #8A5CF0 (est.) violet | fading orbit lines at t=5.5 | s02 r1-c4 |

### 3.3 VFX / motion timeline (OBS)

| ID | t (s) | Cell | Element | What it does | Dur (bound) | Easing impression | Layers |
|---|---|---|---|---|---|---|---|
| E3.01 | 0.0 | s01 r1-c1 | Intact plot | lime plate + brown rail fence, camera high three-quarter view, static all clip | 0.5 s | n/a | n/a |
| E3.02 | 0.5 to 1.5 | s01 r1-c2, r1-c3 | Charge: orbit streaks | 3-6 thin white arc streaks circle the plot at about fence height and above; faint ground ellipse ring at t=1.0 | about 1 s | accelerating | Trails/Beams, no particles |
| E3.03 | 1.5 | s01 r1-c4 | Break | fence + grass break into small boxes (brown, green, red flecks) lifting about 1-2 studs (est.) into a ring around the plot; faint violet glow low at left | <= 0.5 s | sudden, then drift | parts; no flash |
| E3.04 | 2.0 | s01 r2-c1 | Donut forming | green/brown pieces in a ring with visible hole; some boards fall at front; shadows start; 2 concentric ground rings | 0.5 s | n/a | shadows |
| E3.05 | 2.5 | s01 r2-c2 | Recolour start | pieces turn dark green/violet; first cyan cubes (about 6-8 visible, est.) | about 0.5 s | n/a | Neon + bloom |
| E3.06 | 3.0 | s01 r2-c3 | Recolour done | pieces dark navy/violet; about 10-14 glowing cyan cubes with halos; rings still there | about 0.5 s | n/a | bloom |
| E3.07 | 3.5 | s01 r2-c4 | Swirl sustain | donut slightly larger/higher; cyan cubes brightest | 0.5 s | n/a | bloom |
| E3.08 | 4.0 | s02 r1-c1 | Peak expansion | donut about 1.2-1.3x plot span (est.), pieces at varied heights, strong shadows | about 0.5 s | n/a | shadows |
| E3.09 | 4.5 | s02 r1-c2 | Collapse | pieces flatten toward the footprint; dark violet floor appears in the middle; cyan pieces cluster high | about 0.5 s | accelerate-in | n/a |
| E3.10 | 5.0 | s02 r1-c3 | Reform | new fence posts/rails assemble from the back-left; floor present; stragglers still flying; ground rings remain | about 0.5 s | stagger by position | n/a |
| E3.11 | 5.5 | s02 r1-c4 | Complete | new plot whole; 3-5 thin multi-colour orbit streaks (white/magenta/violet) fading around it | about 0.5 s | fade | Trails |
| E3.12 | 6.0 | s02 r2-c1 | Settle | one residual streak top-left | 0.5 s | fade | n/a |
| E3.13 | 6.5 to 8.5+ | s02 r2-c2 to s03 | Hold | static; thin cyan edge lines on fence, speckled floor | >= 2.5 s | n/a | n/a |

Totals (bounds): charge starts 0.5, break 1.5, reform complete 5.5, clean by 6.0: about 4.5-5 s end to end. Piece count: about 150-250 visible on desktop (est.). Not observed: camera motion, FOV, screen flash/shake, blur, text, audio (n/r).

### 3.4 Roblox build recipe (REC; start values to tune)

| ID | Effect | Primitives and starting values | Mobile cost |
|---|---|---|---|
| R3.01 | Orbit streaks (charge) | 3-5 invisible anchored Parts each with 2 Attachments + a Trail (Lifetime 0.4-0.7, WidthScale taper to 0, Color white, LightEmission 1, FaceCamera true), orbiting the object at radius about 1.0-1.2x footprint, heights 1-6 studs, angular speed ramping up over 1 s. Move with one Heartbeat loop | cheap |
| R3.02 | Ground rings | 2-3 flat thin cylinders (Neon, Transparency 0.3-0.6) or a ring Decal/ImageLabel in a SurfaceGui, scale 0.8x to 1.3x, fade out; stagger 0.15 s | cheap |
| R3.03 | Shatter pieces | Replace the model by N anchored Parts, CanCollide/CanQuery/CanTouch false, CastShadow false (the reference shows shadows; skip on phones). REC N = 40-80 on mobile (reference about 150-250). Seed each piece from the model parts' CFrames/colours; per-piece polar (angle, radius, height, spin) | medium (heavy if N > 150 or shadows on) |
| R3.04 | Swirl/torus motion | One Heartbeat (or RenderStepped) loop; per piece: angle += omega x dt, radius eases toward torus radius R (1.0x to 1.25x footprint), height = base + sin(phase). Apply with Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged) instead of per-part tweens | medium |
| R3.05 | Recolour | Per-piece Color tween (or lerp in the same loop) from source colour to dark violet over 1.0-1.5 s; 10-15% of pieces switch to Material Neon + cyan accent. No PointLights per piece (expensive) | cheap |
| R3.06 | Glow | BloomEffect (Intensity 0.6-1.0, Size 24-40, Threshold 0.9) to make Neon pieces halo; ramp in before recolour and out after reform | medium (post effect; verify on low graphics) |
| R3.07 | Reform | Precompute target CFrames from the final model; hide the final model (Transparency 1) until pieces arrive; each piece tweens/lerps to its target with 0 to 0.6 s stagger by distance (Quad In-Out, 0.5-0.8 s); swap in the final model and destroy pieces at completion | medium |
| R3.08 | Camera | Keep static as in reference. Optional: FOV 70 to 66 over 1.0 s at break (REC only) | cheap |
| R3.09 | Ownership | Run entirely on the client from a single RemoteEvent; the server only decides outcome | cheap (saves replication cost) |
| R3.10 | Audio cues (n/r in frames; REC) | Rising riser across the 1 s charge, crack/impact at break, shimmer loop under the swirl, soft thud + chime at reform. Route through one SoundGroup so the Settings audio sliders apply | cheap |

### 3.5 Mapping to Climb & Collect

| Moment | v3 technique | Why | Limit / adaptation (REC) |
|---|---|---|---|
| Egg break (at the nest, on the spot) | E3.02 charge + E3.03 break + E3.04-E3.07 swirl, with shell shards instead of fence cubes | A 1-second telegraph then a shatter; the same shell pieces become the swirl, so the egg is "tracked" through the change | 8-16 shell shards, not 150. Accent pieces in the creature's rarity hue (the cyan 10% trick). Total under 2.5 s so the carrier is not stuck while unsecured |
| Rarity reveal (in-world) | E3.05-E3.06 recolour + hot accent pieces | Rarity shows as the accent hue and how many accent pieces glow | Hue from the owner's palette, mapped per rarity tier |
| Hatch / creature appears | E3.09-E3.11 collapse and reform | The pieces collapse into the creature; streaks fade after it lands | Creature appears at about t=1.8-2.2 s into the break sequence |
| Guardian wakes | E3.02 orbit streaks + E3.02 ground ring as a telegraph | The 1 s ring telegraph gives the player reaction time before the chase | Danger hue for guardian; ring radius = aggro radius if the design wants a readable danger zone |
| Bat upgrade / level-up (bat skin) | Whole V3 sequence on the bat (bat model -> shards -> new-level skin) | Owner rule 2026-10-26: bats have their own look and trail per level; V3 is exactly "same object, re-skinned" | Use 20-40 pieces on the bat |
| Bat hit / dropped creature (3 s grab window) | E3.02 ground ring pulse around the dropped creature | A visible ring collapsing over 3 s shows the window to every player | REC only; ring drives a countdown, not decoration |
| Section unlock | E3.03-E3.11 on a gate/barrier object | "The barrier turns into the way forward" | Optional: V1 title card on top |
| Banking | E3.11-E3.13 settle: thin streaks fading around a now-owned object | "Secured" read: ring settles, edge glow stays on | Ring + edge glow only, no shatter |
| SKIP | Real shadow-casting parts, 150-250 piece counts, green-to-violet palette, baseplate grid look | Mobile cost, palette conflict | n/a |

---

## Mobile budget guardrails (REC; no source in the references, verify on a low-end Android before accepting)

| Guardrail | Starting value |
|---|---|
| Live ParticleEmitters | <= 6 |
| Live particles | <= 300 |
| Animated Parts in a single effect | <= 80, anchored, CastShadow off, no per-piece lights |
| Post effects at once | Bloom + one ColorCorrection pulse. Blur only for sub-second beats |
| ViewportFrames live | 1 |
| Effect ownership | Client-side from one RemoteEvent; server decides outcome only |
| Accessibility | A reduce-effects toggle (no shake, no FOV kick, no hue cycling) and no colour change faster than 3 per second. Matches the Camera Shake toggle called out in intel C |
| Devices | Owner's test phones are high-end iPhones; they do not prove low-end Android. Keep budgets conservative until measured |

## Moment map: best reference source per C&C moment

| Moment | Primary | Secondary | Duration target (REC) |
|---|---|---|---|
| Egg break at nest | V3 charge + break + swirl (shell shards) | V2 winner sparkle burst | 1.5-2.5 s, in-world |
| Rarity reveal (nest) | V3 accent-colour pieces | V2 title swap (small) | within the same 2.5 s |
| Rarity reveal (sanctuary, safe) | V2 carousel + sunburst + hue badge | V1 title card | 6-10 s |
| Hatch | V3 collapse + reform | V2 result card | 2-3 s |
| Guardian wakes | V3 ring telegraph | V1 speed lines at chase start | ring 1 s |
| Guardian chase | V1 speed lines + FOV kick + dots | n/a | while chased |
| Section arrival | V1 two-tier name card + grade pulse | V1 speed lines (short) | 2-3 s. The owner's overhaul phase 2 names "3-tier banners"; the tiers are not defined in any design/*.md, so size/duration per tier is OPEN (REC once defined: same name-card structure, scaled by tier) |
| Section select | V1 hue-coded stage cards | n/a | UI |
| Summit | V2 sunburst + title | V1 name card | 4-6 s |
| Banking | V2 count-up card + delayed CTA | V3 ring settle | 3-4 s |
| Level-up | V2 count-up + chips | V3 reskin (for bats) | 1.5-3 s |
| Shop / daily reward | V1 skins-panel pattern / V2 carousel | n/a | UI |

## Top 10 techniques to steal (ranked by visual impact per mobile cost)

| Rank | Technique (source) | Cost | Why it ranks here | Use in C&C |
|---|---|---|---|---|
| 1 | Sunburst ray backdrop + dark vignette (V2, E2.03/R2.03) | cheap | One backdrop converts any screen into a jackpot moment | sanctuary reveal, summit |
| 2 | Count-up result card with staggered chips and delayed CTA (V2, R2.02/R2.09) | cheap | Pure UI; makes numbers feel earned | banking, level-up |
| 3 | Slot carousel with fixed gold selector, decel and near-miss settle (V2, R2.04/R2.05) | cheap | Anticipation for almost no art | sanctuary reveal, daily reward |
| 4 | Anticipation copy ladder / title swap (V2, R2.07) | cheap | Zero-cost drama | all reveals |
| 5 | Radial speed lines + FOV kick + dots (V1, R1.06/R1.08/R1.09) | cheap | Speed and threat in one overlay | guardian chase, arrival |
| 6 | Hue-cycling badge (V2, R2.06) | cheap | Keeps the screen alive during waits (watch flash rate) | rare reveal badge |
| 7 | Ground ring + orbit streak telegraph (V3, R3.01/R3.02) | cheap | Readable warning before action | guardian wake, egg charge, steal window |
| 8 | Two-tier name card with tracked sub-label, no backing panel (V1, R1.05) | cheap | Sells place and moment with text only | section arrival, summit |
| 9 | Charge, break, swirl, recolour, reform with hot accent pieces + bloom (V3, R3.03-R3.07) | medium (cheap at <= 60 pieces, no shadows) | Highest visual payoff per idea; the single most "wow" beat | egg break, bat upgrade |
| 10 | Hue-per-stage cards with status chips and one CTA colour (V1, R1.01) | cheap (art cost separate) | Menu becomes content; states readable at a glance | section select |
