# VFX / UI intel B — v4, v5, v6 (Atlas, 2026-10-27)

Scope: `references/vfx-ui-2026-10-27/frames/v4..v6` only. Style/technique source; nothing here is a layout, string, name or logo to copy 1:1. Sibling `vfx-ui-intel-C-settings-screenshot-2026-10-27.md` was read only to name the HUD v2 conflict (D2, D9); sibling A not merged. No SYSTEM.md edit made.

## 0. Method and limits

| Item | Value |
|---|---|
| Cell citation | `vN/sheet_NN cell r-c` (row-col, from 1). Grid 4 cols x 2 rows, cell width 360 px (README). |
| Time formula | `t = ((sheet-1)*8 + (r-1)*4 + (c-1)) / fps`. v4 1 fps (1.00 s/cell, 16 frames, 0-15 s). v5 0.7 fps (1.43 s/cell, 25 frames, 0-34.3 s; sheet_04 has 1 cell). v6 2 fps (0.5 s/cell, 22 frames, 0-10.5 s; sheet_03 has 6 cells). |
| Colours | All hex are eye-estimates `(est.)`, not sampled. v5 and v6 are a monitor / TikTok re-recording (glare, skew, curved-screen distortion) so hue and saturation are further unreliable. |
| Overlays to ignore | TikTok chrome, burned-in caption text and watermarks in all three videos; Studio editor chrome in v4. Not part of any UI or VFX. |
| Observed vs recipe | Sections 1.x-3.x tagged "Obs" are read from frames. "Recipe" sections are my recommendation (Roblox values are starting ranges, tune on device) and are not observed in the references. |
| Cost classes (relative, unmeasured) | cheap = UI tweens or <= ~20 live particles. medium = post-process (Bloom/Blur), ViewportFrame, or ~100 live particles. heavy = hundreds of animated parts, dynamic lights, many ViewportFrames. |
| Revision | Rev 2 (2026-10-27): every row re-checked against all 9 sheets. Corrections: v4 creature count (up to 3 gold + 1 dark visible at once); v5 header-ribbon tilt softened (ribbon reads level, icon is the tilted element); v5 `20`/`30`/`0-30` chips are world billboards, not HUD. Additions: v5 segment map, reveal fade read-out, reveal to inventory continuity, duration bounds for v5/v6, v4 cost table, moment matrix (section 4), D2/D7/D9 tied to project rules. |
| Project rules used for mapping | Read from project memory and CLAUDE.md, not from the refs: egg breaks at the nest on the spot, one creature carried, thieves can hit with bats, dropped creature is grabbable for 3 s; all six sections attemptable from the start; bats unlock per completed section set; phase order = HUD v2, then egg-break cinematic + 3-tier banners, then onboarding, intensity, animation/VFX; monetization sells tycoon speed/convenience/cosmetics, no paid power in raids or theft, odds shown on paid random items. |
| Not resolvable from sheets | Audio (none assessable). Exact easing curves and tween durations under ~1.4 s (v5) / ~0.5 s (v6) / ~1 s (v4). Part counts, particle settings, font identity, tiny text under ~6 px (reward tile text, HUD price chips, "OP" tag). Video files not opened. |

---

## 1. v4 — ornate winged ring-creatures (Roblox Studio viewport)

### 1.1 What it is / why premium
Roblox Studio viewport capture (16 s) of hovering "ophanim-style" creatures: gold armillary-ring bodies with eyes and white feather wings (2 visible in v4/sheet_01 cell 1-1, 3 in v4/sheet_02 cell 2-2) and one dark indigo/violet/black-ring creature with big blue-purple wings, over a flat blue sky and grid baseplate. Free-fly editor camera, no gameplay UI. Viewport is only ~1/4-1/3 of each cell height, so macro detail is soft.

| Premium driver | Evidence |
|---|---|
| Two-faction colour code: warm gold + white vs cool indigo/violet/black, on a near-flat sky | v4/sheet_01 cell 1-1..1-3 |
| Nested rings at different tilts read as a gyroscope; implies constant rotation even in stills | v4/sheet_01 cell 2-1, v4/sheet_02 cell 2-2 |
| Repeated micro-eye motif (dozens of small eyes per band, square cyan-lit windows on dark rings) gives fractal detail at every camera distance | v4/sheet_01 cell 2-4, v4/sheet_02 cell 1-2 |
| Layered feather planks give a strong silhouette; white wings vs indigo wings = instant faction read | v4/sheet_01 cell 1-4 |
| Sparse star sparkles only near the gold ring, not everywhere | v4/sheet_01 cell 2-4, v4/sheet_02 cell 2-3 |
| Hover with soft ground shadow = grounded, not floating-in-void | v4/sheet_02 cell 2-2 |
| Camera plan: wide -> medium -> macro fly-through -> wide; detail density is rewarded by the move | timeline below |

### 1.2 UI anatomy
None in the game view. (Studio toolbars/explorer are editor chrome, ignore.)

### 1.3 Palette (Obs, all est.)
| Token (obs- prefix, not project tokens) | Hex | Role |
|---|---|---|
| obs-sky-top | #2A7FE6 (est.) | sky upper |
| obs-sky-horizon | #CFE6F6 (est.) | sky lower / haze |
| obs-ground | #B9BFD6 (est.) | baseplate; grid lines ~#8F96B0 (est.) |
| obs-shadow | #6E7490 (est.) at ~40% | soft contact shadow |
| obs-gold | #F4C21A (est.) | ring body; highlight #FFE46B (est.); shade #C58A0C (est.) |
| obs-feather-white | #F6F3EA (est.) | wing; shade #C9D2E8 (est.) |
| obs-indigo | #1B2680 (est.) | dark wing base |
| obs-blue | #2F46C8 (est.) | mid wing |
| obs-violet | #7B2FD6 (est.), #A23FE0 (est.) | wing/ring accent |
| obs-ring-dark | #14163A (est.) | black-navy rings |
| obs-eye-glow | #2BB0FF (est.) with white core #EAF8FF (est.) | eye windows |
| obs-sparkle | #FFFFFF, #BFE6FF (est.) | star particles |

### 1.4 Anatomy of one creature (Obs)
| Part | Observation | Cell |
|---|---|---|
| Gold body | 3+ nested thin ring bands forming a sphere/lattice; small eyes spaced along bands; one large central eye; thin gold spikes radiating behind | v4/sheet_01 cell 2-1; v4/sheet_02 cell 2-2 |
| Wings (white) | pair, 3-4 stacked feather layers, spread near-horizontal, slight droop | v4/sheet_01 cell 1-1 |
| Dark body | 2-3 black/navy rings with square windows each holding a glowing blue eye; central eye in ring; violet-to-indigo wings, feathers visibly blocky/plank-like | v4/sheet_01 cell 2-2; v4/sheet_02 cell 1-1 |
| Ground | creatures hover ~1-2 body heights above plate; soft offset shadows | v4/sheet_02 cell 2-2 |

### 1.5 VFX / motion timeline (Obs; 1 fps)
| t (s) | Cell | Element | What happens | Duration / easing impression | Layers |
|---|---|---|---|---|---|
| 0-3 | sheet_01 1-1..1-4 | all three creatures | wide establishing; positions and ring tilts differ every frame -> rings rotate on different axes; creatures drift/orbit each other; camera orbits and moves closer by t=3 | continuous, smooth, no snap | rings, wings, shadow, sky |
| 4 | sheet_01 2-1 | gold creature | centred hero frame; radial gold spikes visible; eye centred | settle | rings, spikes, eye |
| 5-6 | sheet_01 2-2, 2-3 | dark rings | camera low and close, dark ring dominates foreground, gold ring below; blue wings spread both sides | dolly-in feel | rings, wings |
| 7 | sheet_01 2-4 | gold ring + sparkles | white/blue 4-point star sparkles appear upper-left of the gold ring (~6 visible) | brief, <1 s each (est.) | particles |
| 8-12 | sheet_02 1-1..2-1 | camera inside rings | macro fly-through of ring bands: t=8 magenta ring with one large cyan eye fills frame; t=9 dark ring segment with square cyan windows fills frame; t=10 sandy blocky terrain at left with a yellow-white glow burst beside it (v4/sheet_02 cell 1-3: either a second scene, a light flash, or the camera passing the creature's own FX; unresolved); t=11 ring spiral seen from below with dark feather rows | fast; cut vs continuous not resolvable at 1 fps | rings, eye glow, flash |
| 13 | sheet_02 2-2 | gold sphere-lattice creature | pull-back to wide; sphere lattice centre; violet creature above; small gold creatures right | ease-out feel | all |
| 14 | sheet_02 2-3 | gold sphere | sparkle cluster around left gold creature again | ~1 s | particles |
| 15 | sheet_02 2-4 | gold ring + dark creature | closing frame, gold ring centre-right, dark creature top-centre | hold | all |

Unresolved: wing flap amplitude, ring RPM, hover bob amplitude, whether eyes track the camera, particle rate/size.

### 1.6 Recipe: building this from Parts / Attachments / ParticleEmitters (recommendation)
Rig (client-side only, decorative, no HingeConstraint):

| Piece | Build | Notes |
|---|---|---|
| Root | invisible Anchored Part = PrimaryPart; follows creature/target CFrame; bob `y += 0.3..0.5 * sin(t * 1.2..1.6)` | one driver per creature |
| Rings (3-4) | one MeshPart torus each (uploaded mesh, 150-400 tris), Neon or SmoothPlastic gold; Anchored, CanCollide/CanQuery/CanTouch false, CastShadow false | cheaper than N-part rings |
| Ring alt (no mesh) | 24-48 small Neon blocks placed by `CFrame.Angles(0,0,i*2pi/N) * CFrame.new(R,0,0)` inside a Model | heavy for >2 creatures; use only for hero |
| Ring rotation | single `RunService.RenderStepped` loop: `angle[i] += speed[i]*dt`; `ring:PivotTo(rootCF * CFrame.Angles(ax*angle, ay*angle, az*angle))`; start speeds ~0.4-1.5 rad/s with alternating signs per ring | batch with `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)` when moving many parts |
| Eyes on rings | ParticleEmitter on each ring: Shape Cylinder, ShapeStyle Surface, Speed 0, Rate 20-40, Lifetime 3-4, Size 0.4-0.7, Texture = authored eye sprite, LockedToPart = true, LightEmission 0.6, Orientation FacingCamera | eyes ride the ring with no extra parts; cheap-medium |
| Dark ring windows | Decal or SurfaceGui square (glow cyan) on ring MeshPart, or small Neon cube per window if MeshPart has fixed slots | cheap (decal) |
| Central eye | Neon sphere + smaller dark pupil sphere + optional PointLight (Range 10-14, Brightness 1-2); optional per-frame `CFrame.lookAt` pupil toward camera | one light max per creature, near LOD only |
| Spikes | 8-16 thin Neon parts (0.1x0.1x6-10) or Beams between Attachments on the root; Beam Width 0.1-0.25, LightEmission 1, FaceCamera true | cheap-medium |
| Wings | Model per wing: 6-10 feather MeshParts welded to a wing-root Part; flap via `wingRoot.CFrame = rootCF * CFrame.Angles(0,0,amp*sin(t*f + phase))`, amp 8-20 deg, f 1.2-2 Hz, per-feather phase lag +0.1-0.15 rad for ripple | cheap if <=20 parts per creature |
| Sparkles | ParticleEmitter: 4-point star sprite, Rate 8-14, Lifetime 0.7-1.3, Speed 1-4, SpreadAngle 180, Size NumberSequence 0 -> 0.6 -> 0, Transparency 0 -> 1, LightEmission 0.8-1, LightInfluence 0, RotSpeed -90..90, Color white -> #BFE6FF | cheap |
| Aura breathing | ParticleEmitter soft-circle: Size 6-10, Rate 2, Lifetime 2-3, Speed 0, LockedToPart true, Transparency 0.6 -> 1, LightEmission 1, ZOffset -1 | cheap |
| Ground shadow | flat Part with blob Decal (transparency 0.6) scaled to creature; no real shadow cost | cheap |
| Glow | scene `BloomEffect` Intensity 0.3-0.5, Size 24, Threshold ~0.9 so Neon blooms | medium (global) |
| Intro / state change | TweenService: rings scale 0 -> 1 (Back Out 0.5 s, 0.08 s stagger), wings unfold from ~80 deg to rest (Back Out 0.6 s), eye lid/opacity 0 -> 1 (0.2 s) | cheap |
| Camera flourish | `CameraType.Scriptable`; TweenService on CFrame (Quad InOut) + FieldOfView 70 -> 50 on approach; keep camera > 1.5 studs from parts (near-plane clipping); restore control after | cheap |

#### 1.6b Cost class, extra rows and prototype order (recommendation, not observed)
| Piece | Cost | Note |
|---|---|---|
| Root + hover bob | cheap | one shared `RunService.Heartbeat` loop that iterates all live creatures, not one connection per creature |
| Ring as 1 MeshPart (150-400 tris) | cheap | 3-4 per creature; spin cost = one `PivotTo` per ring per frame |
| Ring as 24-48 Parts | heavy | hero/cinematic only; more than 2 such creatures on a phone is a frame-time risk (est.) |
| Spin via TweenService (alternative) | cheap for <= 3 rings | tween a `NumberValue` 0 -> 2*pi, Linear, `RepeatCount = -1`, call `PivotTo` in `.Changed`; above ~6 rings use the shared loop (every Changed is a Lua call) |
| Gyroscope read | cheap | alternate spin sign, different axis per ring (x, z, y), speeds not in an integer ratio (e.g. 0.6 / 0.97 / 1.4 rad/s) so the pattern does not visibly repeat |
| Ring-riding eyes (emitter) | cheap-medium | UNVERIFIED in Studio: `Shape = Disc` with `ShapePartial` as an annulus may fit a ring better than Cylinder; test both |
| Square eye windows | cheap | decal/SurfaceGui, or baked into the ring mesh texture (cheapest) |
| Central eye + PointLight | medium | max one light per creature, near LOD only |
| Wings | cheap if <= 20 parts | phase-lagged feather rows give the ripple |
| Sparkles | cheap | prototype with the engine default texture `rbxasset://textures/particles/sparkles_main.dds`, then author a 4-point star sprite |
| Bloom | medium (global) | one effect for the scene, gated on graphics quality |
| Full reference rig, no LOD | heavy | not for phones |
Prototype order: (1) root + 3 rings spinning, (2) wings flap with phase lag, (3) sparkle + aura emitters, (4) eyes, (5) LOD switch + off-screen disable, (6) state-change tweens (unfold, lock-to-halo), (7) phone measurement before adding the central light.

LOD (mandatory for phones): far (>120 studs) = one glow billboard only; mid (40-120) = rings, no eye emitters, no lights; near (<40) = full. Disable emitters/lights off-screen. Cap simultaneous full creatures at 2-3 on mobile. Cost of the full reference rig: heavy; LOD'd rig: medium.
Sound cues (recipe): low tonal drone loop per faction (gold = airy shimmer, dark = sub hum), ring-spin whoosh on state change, soft glassy chime on sparkle bursts.

### 1.7 Mapping to Climb & Collect (v4)
| Moment | Technique | Why |
|---|---|---|
| Creature idle / aura | nested rotating rings + eye-emitters, ring count and eye density scale with rarity | readable at a glance; carried creature visibly valuable (see open decision D3) |
| Guardian presence | dark/cool faction rig: black rings, cyan square-window eyes, large wings; central eye "opens" and ring speed ramps on first strike alert | reuses v4 faction contrast; creature gold vs guardian dark is instantly separable |
| Banking / securing | rings lock into a clean aligned halo + one sparkle burst (0.5-0.8 s), then idle at slower speed | communicates "now safe" without UI |
| Summit | wide -> macro -> wide camera plan with sparkle cluster | rewards finishing; zero asset cost beyond camera tween |
| Egg break / hatch | rings unfold from the egg shell (scale 0 -> 1 Back Out), sparkles at peak | see section 2.6 for the fast in-world version |
| Section unlock | gold ring "seal" rotating then breaking into sparkles over the section gate | cheap one-shot |

---

## 2. v5 — strength-simulator UI + reveal (monitor re-recording)

### 2.1 What it is / why premium
35 s montage of one polished simulator game: HUD, REWARDS grid, TRAILS shop, REBIRTH before/after, PETS inventory, a hero cutscene reel, a zone/egg-shop tour, ending (HUD again). Numbers are not monotonic (Level 140 -> 154 -> 155 -> 114) so it is a montage of separate captures, not a progression.

| Premium driver | Evidence |
|---|---|
| One panel grammar everywhere: overhanging icon-ribbon header, overhanging red X, dark body, saturated gradient tiles with dark outline | v5/sheet_01 cell 1-2, 1-3, 1-4; v5/sheet_02 cell 1-1 |
| Colour carries meaning: green = go/claim/confirm, yellow = buy, blue = unequip/neutral, red = danger/close, purple = secondary/skip, rainbow = top tier | same cells |
| State shown by overlay not by new layout (green check = claimed, green CLAIM! = ready, mm:ss chip = locked) | v5/sheet_01 cell 1-2 |
| World stays visible but heavily blurred behind every modal | v5/sheet_01 cell 1-2..1-4 |
| Big numerals with K/M/B abbreviation and thick outline; stat, bar, quick-buy stacked bottom-centre | v5/sheet_01 cell 1-1, 2-1 |
| Reveal: whiteout bloom, name -> chance % -> multiplier -> "Click to continue", HUD hidden | v5/sheet_01 cell 2-4 |
| World tour: zones themed by material/colour, floating multiplier billboards escalate zone to zone | v5/sheet_03 cell 1-2..2-1 |

#### Segment map (Obs; burned-in caption changes mark the boundaries)
| Segment | t (s) | Cells | Content |
|---|---|---|---|
| A. UI | 0.00-11.43 | sheet_01 all; sheet_02 cell 1-1 | HUD, REWARDS, TRAILS, REBIRTH, HUD in motion, transition, mythic reveal, PETS inventory |
| B. Hero cutscene | 12.86-22.86 | sheet_02 cells 1-2..2-4; sheet_03 cell 1-1 | 8 frames, 8 different camera set-ups, so shot length <= ~1.4 s (est.) |
| C. World tour | 24.29-32.86 | sheet_03 cells 1-2..2-4 | themed lanes, egg shop, ball pads |
| D. Hype card | 34.29 | sheet_04 cell 1-1 | HUD + "releasing in one week" caption |
Flow evidence: the reveal's `x59` pet (sheet_01 cell 2-4, t=10.00) is the first card of the PETS inventory at t=11.43 (sheet_02 cell 1-1, gold card, `x59`, MYTHIC) = reveal -> inventory is one designed flow.

### 2.2 UI anatomy

#### Palette tokens (Obs, all est.)
| Token | Hex | Role / cell |
|---|---|---|
| obs-panel-body | #2B2E3A (est.) | dark navy-charcoal modal body; border/outer ~#4A4E5C (est.) | v5/sheet_01 cell 1-2 |
| obs-xp-track | #2B49D1 (est.) | level bar track (blue) | cell 1-1 |
| obs-xp-fill | #FF9A1F (est.) -> #FF4FA0 (est.) | fill gradient warm; marker = small rainbow ring at fill head | cells 2-1, 2-2 |
| obs-stat-yellow | #FFD21F (est.) | strength counter + multiplier text, black outline | cell 1-1 |
| obs-btn-gold | #FFC933 (est.) -> #F59A1B (est.) | +10K quick-buy | cell 1-1 |
| obs-btn-red | #E8353B (est.) -> #B81F2E (est.) | +100K quick-buy; Delete Mode; close X | cells 1-1, 1-2 |
| obs-btn-rainbow | magenta -> blue -> green -> yellow (est.) | +1M quick-buy (top tier) | cell 1-1 |
| obs-green | #3DDC3D (est.) | CLAIM!, Claim All, Rebirth, active tab, equipped dot, level-ok bar | cells 1-2, 1-4 |
| obs-tile-blue | #3D6BFF (est.) -> #2A4BD0 (est.) | reward tiles row 1 | cell 1-2 |
| obs-tile-purple | #8A4DE0 (est.) -> #6A2FC0 (est.) | reward tiles row 2; Skip Rebirth #8B3FE0 (est.) | cells 1-2, 1-4 |
| obs-tile-orange | #FF9F1A (est.) -> #E8791A (est.) | reward tiles row 3 (locked); Autumn trail row | cells 1-2, 1-3 |
| obs-yellow-btn | #FFD21F (est.) | BUY | cell 1-3 |
| obs-blue-btn | #2F7BFF (est.) | UNEQUIP | cell 1-3 |
| obs-subtitle | #FFC21A (est.) | "free gifts" line | cell 1-2 |
| obs-warn | #FF5A3C (est.) | reset-warning line | cell 1-4 |
| obs-rarity-mythic | #C9A8FF (est.) | lilac rarity word | cell 1-3 |
| obs-reveal-white | #FFFFFF with warm #FFF3B0 (est.) core | flash | cell 2-4 |

#### Panel construction, layer by layer (REWARDS as exemplar; TRAILS, REBIRTH, PETS share it) (Obs)
| # | Layer | Observation | Cell |
|---|---|---|---|
| 1 | Backdrop | live world visible, strong blur, no hard black dim | v5/sheet_01 cell 1-2, 1-3, 1-4 |
| 2 | Panel body | dark navy-charcoal rounded rect (radius ~5-6% of panel height, est.), thin lighter outer border, no visible gradient | cell 1-2 |
| 3 | Header ribbon | orange rounded ribbon pinned top-left, overlapping the panel's top edge; ribbon reads level (tilt <= ~3 deg, not resolvable); white title with dark-orange outline; round glossy icon (gift / trail / rebirth arrows / backpack) overhangs the ribbon's left end by ~20-30% and is visibly tilted (~10-15 deg, est.) | cells 1-2..1-4, sheet_02 1-1 |
| 4 | Tabs (REWARDS only) | two pills right of ribbon: active = green + light stroke, inactive = dark grey | cell 1-2 |
| 5 | Close | red rounded-square, white X, thick dark-red stroke, straddles top-right corner (~35% outside) | cells 1-2, 1-4 |
| 6 | Subtitle | yellow-orange single line centred under header | cell 1-2 |
| 7 | Content tiles/rows | saturated gradient fills, dark outline, lighter inner top highlight (est.) | cell 1-2, 1-3 |
| 8 | Footer | big green "Claim All" bottom-left; "Round 1" white right | cell 1-2 |

#### Button recipe (Obs)
| Type | Look | Examples |
|---|---|---|
| Primary | saturated green gradient, white heavy label with outline, darker bottom lip (3D feel), dark outline | CLAIM!, Claim All, Rebirth |
| Purchase | yellow face, dark label, same lip | BUY |
| Neutral toggle | blue face | UNEQUIP |
| Secondary | purple face, smaller than primary (~40% vs ~55% width) | Skip Rebirth |
| Danger / close | red face; X glyph, no label | close X; Delete Mode |
| Tab | active green+stroke, inactive dark grey | DAILY / PLAYTIME |
| HUD quick-buy | wide pill, ~3.2:1 (est.), icon left, "+10K / +100K / +1M" label, tiny green number chip bottom-right (meaning unreadable) | cell 1-1 |
Value ramp on HUD: gold < red < rainbow = more expensive/stronger (colour, not size, signals tier).

#### Typography (Obs)
| Trait | Observation |
|---|---|
| Letterforms | heavy rounded-geometric sans, near-all-caps for titles; mixed case for body ("Level 140", "Before/After") |
| Stroke | thick dark outline on all text over colour (title: dark orange; body/numerals: near-black), drop shadow beneath |
| Slant | titles upright (ribbon tilt <= ~3 deg, n/r); the icon, not the text, carries the tilt; v6 `BEST DEAL` / `CLOSE` are slanted italic (see section 3) |
| Size ratios (est.) | ribbon title : button label : stat/bar text : tile caption ~ 3 : 1.7 : 1.3 : 1; reward-tile captions are tiny (~1.2% of screen height, est.) and would fail on a phone |
| Numerals | K/M/B abbreviation in HUD and rewards; multipliers as `x5.3`, `x59`; times `mm:ss`; counts as `3/3`, `1/1` |
| Colour | white default; yellow for currency/strength; green for success; lilac/orange/purple for rarity words |
| Candidate faces (identify by letterform, not confirmed) | Roblox built-ins `FredokaOne` or `LuckiestGuy` (engine fonts); Google Fonts Lilita One (OFL), Fredoka (OFL), Baloo 2 (OFL). Verify licence for any non-built-in font before upload. |

#### Icons, layout, spacing (Obs)
| Aspect | Observation |
|---|---|
| Icon style | glossy sticker-like 3D icons (gold muscle arm, trophy, gift, rainbow-orb trail, round pets), consistent thick dark outline, soft top highlight; icons larger than their row/tile and overlap edges |
| Layout | modal ~85-90% of visible width on landscape capture (est.); rewards = 4 col x 3 row grid; trails = single full-width rows; rebirth = narrower (~60% width, est.); pets = 5-col grid with inline tooltip |
| Spacing | tile gaps ~2% panel width (est.); stroke ~1% panel width (est.); consistent radii across tile, button, panel |
| HUD placement | bottom-centre stack: stat line (arm icon + STRENGTH left, multiplier right) / XP bar full width (~70% screen width, est.) / three quick-buy pills; top-left currency pills with round icon; floating billboards in world |
| Density | high; many small items per panel. Phone risk: bottom-centre stack collides with Roblox mobile thumbstick/jump zones. |

#### Value / rarity / best-deal signalling (Obs)
| Signal | Where |
|---|---|
| Rainbow = top tier | +1M button; rainbow marker ring on XP bar; "MYTHIC" lilac word; rainbow trail orb |
| Colour-coded rarity word + multiplier bottom of each pet card (`x59 MYTHIC`, `x45 EPIC`, `x3.7 LEGENDARY`, `x2.8 EPIC`, `x2.35 RARE`) | sheet_02 cell 1-1 |
| Drop chance shown on reveal (`5%`) | sheet_01 cell 2-4 |
| Locked/earned/ready via overlay (check / CLAIM! / timer chip) | sheet_01 cell 1-2 |
| Zone escalation by floating multiplier billboards (`1x`, `4x`, `10x` ... `300x`) and zone theme change | sheet_03 cell 1-2..2-1 |
Card colour vs rarity: Birdhouse cards (EPIC) are blue, Butterfly (RARE) pink-purple, Dumble (RARE) yellow, so card colour appears pet-specific, not strictly rarity (too small to confirm).

#### Card anatomy (Obs)
| Card | Anatomy |
|---|---|
| Reward tile | top caption (value + type) -> centre icon (trophy / arm / pet) -> bottom either green CLAIM! button or dark mm:ss chip; claimed = large green check replacing icon. Row tint blue -> purple -> orange top to bottom (est.); timers read 00:56, 03:56, 06:56, 10:56, 15:56, 20:56, 30:56 (est. reading) = escalating gaps ~3,3,4,5,5,10 min. State at 1.43 s: 2 claimed, 3 ready, rest locked. (sheet_01 cell 1-2) |
| Trail row | full-width diagonal-gradient bar in the trail's own colour; large icon overflowing left edge; title white top-right; price line with trophy icon + "15,000 Wins"; action button right (BUY yellow / UNEQUIP blue); owned row replaces price with rarity word (sheet_01 cell 1-3) |
| Rebirth | two yellow stat boxes ("Before" -> "After", arm icon + `x5.3`/`x5.4` + STRENGTH) with arrow between; red-orange warning line; full-width green requirement capsule ("Level 167 / Level 167"); two buttons side by side (sheet_01 cell 1-4) |
| Pet card | name top, pet art, `xN` bottom-left, rarity word bottom-right, green dot top-right if equipped; selecting a card opens an inline dark tooltip (rarity title bar, name, `x45 Strength`, "Equipped - click to unequip") (sheet_02 cell 1-1) |
| Pet toolbar | Search field + Equip Best (green) + Delete Mode (red) + Filter (blue-grey); counter "Equipped 3/3" green on header (sheet_02 cell 1-1) |

#### Notification dots, progress, timers (Obs)
No red notification badges visible in any frame. Green dot = equipped; green check = claimed. Progress: XP bar with rainbow ring marker at the fill head (marker x matches fill: 735.6M/2.05B = 36% -> marker ~34% across, sheet_01 cell 2-2); rebirth requirement bar full green. Timers: mm:ss chips on locked reward tiles.

### 2.3 VFX / motion timeline (Obs; 1.43 s per frame — tweens inside a frame are not resolvable)
| t (s) | Cell | Element | What is seen / inferred | Layers |
|---|---|---|---|---|
| 0.00 | sheet_01 1-1 | HUD idle | bottom-centre stack at rest | UI |
| 1.43 | sheet_01 1-2 | REWARDS modal open | world blurred behind; fully formed | UI, blur |
| 2.86 | sheet_01 1-3 | TRAILS list | list scrolled (header partly offscreen) | UI, blur |
| 4.29 | sheet_01 1-4 | REBIRTH modal | blurred warm yellow world behind | UI, blur |
| 5.71 | sheet_01 2-1 | HUD, 84% XP | rainbow marker near fill head; floating world billboards (`70x Strength`) | UI, billboards |
| 7.14 | sheet_01 2-2 | HUD, 36% XP | camera turning; dark pills `20`, `30` with orb icon move with the camera between cell 2-1 and 2-2, and in sheet_03 cell 1-4 / sheet_04 they shrink with distance above each lane (`0 10 20 30`) = world billboards (requirement chips over lane gates), not HUD | UI, billboards |
| 8.57 | sheet_01 2-3 | transition | heavy colour wash + motion blur; bottom HUD bar absent (present at 5.71, 7.14) -> HUD hides when a transition/reveal starts (inference) | camera, blur, HUD hide |
| 10.00 | sheet_01 2-4 | mythic pet reveal | near-white flash (~70% opacity, est.) over world; small crowned winged cube pet centre; name top, `5%` chance under it, `x59` multiplier lower-left with arm icon, soft "Click to continue" bottom; pet has golden glow aura | white flash, bloom, aura, text |
| 11.43 | sheet_02 1-1 | PETS panel | inventory with tooltip | UI |
| 12.86 | sheet_02 1-2 | hero cutscene | low-angle close-up, gold-suit avatar grinning, cash bills in air, rainbow-streaked sky, blue pet with halo (lower-left) | camera low angle, particles (bills), sparkle |
| 14.29 | sheet_02 1-3 | run shot | white radial speed lines converging at centre; dribbling a ball; giant 3D ground text | overlay speed lines |
| 15.71 | sheet_02 1-4 | title card | green "location name" banner with sprout icons both sides, top-left; oversaturated bloom grade; avatar mid-air | title banner, grade |
| 17.14 | sheet_02 2-1 | face macro | paper bill in teeth + star glint on tooth; cash particles | particles, glint |
| 18.57 | sheet_02 2-2 | wide stroll | overhead signage "TRAINING", "EGGS" | world |
| 20.00 | sheet_02 2-3 | jump launch | yellow-white vertical light burst at feet, red ball above, title card again | beam/burst, grade |
| 21.43 | sheet_02 2-4 | fire fist | orange swirl aura on arm, motion streaks, bills, star glint | flame particles, motion blur |
| 22.86 | sheet_03 1-1 | fireball leap | orange glowing sphere + trailing bills | particles |
| 24.29-28.57 | sheet_03 1-2..2-1 | zone tour | lanes with floating multiplier billboards escalating by zone; zone themes = forest/wood, neon-crystal, candy blocks, crystals; rainbow arc, glowing pillars | world, billboards |
| 30.00-31.43 | sheet_03 2-2, 2-3 | egg shop | giant eggs on grass pedestals, pattern/colour per tier; white egg with halo ring + tiny gold wings + cyan glow orbs; gold crowned egg; price bubble with trophy + "2.5M Wins"; leaderboards behind | models, billboards |
| 32.86 | sheet_03 2-4 | ball shop pads | 3D pads with floating items and "OWNED" labels | world |
| 34.29 | sheet_04 1-1 | HUD again | 2.4% XP, buttons identical | UI |

#### 2.3b Reveal read-out and duration bounds (Obs bounds; inference flagged)
| Item | Read-out | Basis |
|---|---|---|
| Fade state of the reveal layer | name (pink), `5%`, `x59` and "Click to continue" are all semi-transparent (~40-60% visible, est.) while the pet is ~70% visible; the group looks mid-fade as one unit (CanvasGroup-style) under a separate white wash layer. Inference. | sheet_01 cell 2-4 |
| Direction (fade in vs out) | not resolvable: one sample, no neighbour with the same layout | cell 2-3 -> 2-4 |
| Lead-in | t=8.57 world is motion-blurred and colour-washed, bottom HUD absent; reveal layer at t=10.00 => wash-to-reveal <= 1.43 s | cells 2-3, 2-4 |
| Reveal reading order | name above pet -> chance % under name -> multiplier lower-left -> continue prompt bottom-centre | cell 2-4 |
| Modal open | REWARDS fully formed at t=1.43, TRAILS fully formed at t=2.86; no half-open frame caught, so open <= ~1.4 s (impression: fast) | cells 1-2, 1-3 |
| Radial speed lines | in 3 of 8 cutscene frames (t=14.29, 15.71, 20.00); starburst/light rays are the energy cue on jumps and dashes | sheet_02 cells 1-3, 1-4, 2-3 |
| Camera tricks seen | low-angle close-up (12.86), tracking run (14.29), macro face (17.14), wide pull-back (18.57), launch with ground burst (20.00), fiery-arm close-up with swirl + motion streaks (21.43) | sheet_02 |
| Easing / exact durations | not resolvable at 1.43 s sampling; section 2.4 gives recommended values | all |

### 2.4 Recipe: Roblox builds for v5 tricks (recommendation)
| Trick | Primitives and starting values | Cost |
|---|---|---|
| Panel shell | Frame (dark) + `UICorner` ~14-18 px + `UIStroke` 3-4 px near-black (Border mode) + 2-key `UIGradient` (rot 90, +/-8% lightness) + offset shadow Frame (0,6px, black 0.6) | cheap |
| Overhanging header/X | ribbon Frame `Rotation 0..-3`, `ClipsDescendants=false` on panel and ribbon; icon ImageLabel 120-130% ribbon height, `Rotation 8..15`; close X >= 44x44 px hit area, 35% outside corner | cheap |
| Outlined text | TextLabel + `UIStroke` (Contextual, 2-3 px, round joins); `UIGradient` for gold fill top #FFF3B0 -> bottom #FFC21A; `UITextSizeConstraint` min 12 | cheap |
| Lip button | outer Frame (lip colour) + inner Frame lifted 4-6 px (face + gradient + top highlight Frame); press = inner down to lip in 0.06 s Quad, release Back Out 0.12 s; click sound | cheap |
| Tile states | one tile component, state attribute: ready / claimed / locked; claim = scale 1 -> 0.92 -> 1.08 -> 1 (0.3 s), check pops (Back Out 0.25 s), 8-12 pooled star ImageLabels burst | cheap |
| Timers | `os.time()` delta, label update 1 Hz, never per frame | cheap |
| Backdrop blur | `BlurEffect` Size 0 -> 10-12 (phone) / 20-24 (desktop) in 0.2 s, + optional dim Frame 0.55; destroy/tween out on close; world stays visible | medium |
| XP bar | fill Frame with gradient, tween Size 0.35 s Quad Out; marker ImageLabel ring at fill X; level-up: white overlay 0.3 -> 1 over 0.25 s + numeral pop 1 -> 1.15 -> 1 Back | cheap |
| Before/After | two stat boxes + arrow; after-box tween scale pop 1 -> 1.12 -> 1 and number count-up 0.4 s | cheap |
| Whiteout reveal | full-screen white Frame 0 -> 1 transparency over 0.5-0.7 s; `BloomEffect` Intensity 2 -> 0.4 over 0.8 s; `ColorCorrectionEffect` Brightness +0.25 -> 0; FOV punch-in 70 -> 62 (0.15 s) then back Back Out 0.5 s; rotating sunburst ImageLabel behind pet (20-30 deg/s); pet in one ViewportFrame; texts staggered 0.12 s (fade + rise 12 px, 0.25 s); "Click to continue" fades in at ~1.0 s with 1.2 s pulse | medium |
| HUD hide on reveal | tween HUD ScreenGui group transparency/position out 0.15 s, restore on dismiss | cheap |
| Floating billboards | BillboardGui `MaxDistance` 80-120, `LightInfluence 0`, `StudsOffset` bob +/-0.3 over 1.5 s Sine, icon + outlined text | cheap (cap ~20 in view) |
| Speed lines | full-screen ImageLabel radial-lines texture, scale 1.0 -> 1.2 + alpha pulse; only during dash/sprint | cheap |
| Cash/confetti burst | ParticleEmitter, sprite sheet, Rate 0 + `:Emit(20-40)`, Lifetime 1-1.6, Speed 20-40, Acceleration (0,-30,0), RotSpeed +/-180, SpreadAngle 40 | cheap |
| Light burst at launch | Beam/Neon part cylinder, Size (2, 30, 2), Transparency 0.4 -> 1 and width 1 -> 0 over 0.4 s, LightEmission 1 | cheap |
| Location title card | ImageLabel banner + two leaf icons, fade + 8% scale-in 0.3 s, hold 1.8 s, fade 0.4 s | cheap |
| Sound cues | soft click (buttons), ratchet tick per number count-up step, rising sweep 0.6-1.0 s + bright chime at reveal peak, "ka-ching" coin tick on claim, whoosh on panel in/out | cheap |

### 2.5 Mapping to Climb & Collect (v5)
| Moment | Technique | Why |
|---|---|---|
| Rarity reveal | name -> chance % -> multiplier -> continue prompt; rainbow-only-for-top-tier | proven hierarchy; shows odds (also a paid-random disclosure habit) |
| Egg break / hatch (nest) | NOT the full-screen modal. Use a <=1.5 s in-world version: crack, white flash <=0.3 s, rarity ring, billboard name + chance; HUD stays | the player is on the mountain with guardians and bat-wielding thieves; blocking the screen is a risk (recommendation) |
| Egg secured (sanctuary) | full v5-style reveal with "Click to continue" and HUD hide | safe zone, no blocking risk; fits "secured stays" rule |
| Level-up | XP bar gradient + rainbow marker at fill head + numeral pop | cheap, high feedback |
| Daily rewards | tile grid with DAILY/PLAYTIME tabs, claimed/ready/locked overlays, timers, Claim All | direct structural fit; re-theme tiles and strings |
| Section unlock | location title card (leaf-banner style) + Before/After panel for what the new bat/section changes | bats unlock per completed section set (project rule) |
| Prestige | Before -> After panel, red-orange warning line, green requirement capsule, primary + secondary button | only if a prestige loop is added; otherwise reuse for bat upgrade compare |
| Banking | count-up tick + Claim-All style button + short sparkle | confirmation of safe state |
| Section gate chips | dark pill with round icon + number floating over each lane gate, multiplier label beneath, lane theme escalating (v5 sheet_03 cells 1-4, 2-1; sheet_04) | six sections need an instant difficulty/requirement read; all sections are attemptable from the start (project rule), so the chip signals danger tier or the bat-unlock requirement, never a lock | cheap |
| Reveal -> collection hand-off | revealed item is the first card in the inventory 1.43 s later (v5 sheet_01 cell 2-4 -> sheet_02 cell 1-1) | after "Click to continue" fly the creature card into its collection slot and pulse it once | cheap |
| Station wayfinding in sanctuary | floating icon+label billboards over each station | readable from distance on phone |
| Section/biome identity | zone theme change + floating tier billboard (`Nx`) at section entries | six kingdoms need instant tier read |

### 2.6 Skip (v5)
Strength/rebirth economy terms, "Round N", trophy "Wins" currency, tiny reward-tile text, bottom-centre stack that clashes with mobile controls, pay-to-skip rebirth button framing, text strings/names/pet designs.

---

## 3. v6 — shop screens (phone screen recording of a TikTok re-recording)

### 3.1 What it is / why premium
11 s: lobby with colour-coded floating-label pads (0-0.5 s, 8-8.5 s) and two shop pages: a coin-pack grid with a rainbow VIP "best deal" card (1-7.5 s) and a page of three large colour cards with a starburst pattern (9-10.5 s). TikTok sidebar and overlays cover the right edge (coin cards partly hidden); skew/tilt in frames may come from recording a curved monitor, not from design.

| Premium driver | Evidence |
|---|---|
| One holographic rainbow-chrome card in a field of flat gold = unmistakable hero offer | v6/sheet_01 cell 2-2, 2-3 |
| Crown overshooting the card corner, "BEST DEAL" tag straddling the top edge, giant wordmark, perk line | v6/sheet_01 cell 2-2 |
| Value escalation by full-digit numerals and bigger coin piles per tier | v6/sheet_02 cell 1-3 |
| Panel-less shop: cards float directly over the scene, no container | v6/sheet_02 cell 1-3 |
| Labelled red pill CLOSE (not just X), always separate from cards | v6/sheet_01 cell 2-3; v6/sheet_03 cell 1-4 |
| Lobby: saturated pads with icon-led floating labels | v6/sheet_01 cell 1-1 |

### 3.2 UI anatomy

#### Palette tokens (Obs, all est.)
| Token | Hex | Role |
|---|---|---|
| obs-lobby-ground | #35FF1F (est.) | neon green floor |
| obs-pad-magenta / cyan / green / yellow | #D81EC8 (est.) / #27B8F0 (est.) / #46E52E (est.) / #F5E21B (est.) | station pads |
| obs-fence-orange | #F0841E (est.) | arches/fence |
| obs-coin-card | #FFC21A (est.) -> #F59A1B (est.) | coin pack cards; lip darker ~#E27A12 (est.) |
| obs-card-text | #FFFFFF with outline ~#8A3A0A (est.) | numerals |
| obs-vip-chrome | yellow-orange #FFB020 (est.) -> lime #B6E21A (est.) -> cyan #2FD0E0 (est.) -> magenta #C03FD8 (est.) | VIP card holo gradient |
| obs-crown | #FFC21A (est.) with red jewels | best-deal crown |
| obs-close-red | #E8242C (est.) -> #B01820 (est.) | CLOSE pill |
| obs-shop-bg | faceted pale lavender planes #E6E6F2 (est.) + blue sky #2B6FEA (est.) | backdrop |
| obs-card-blue / red / green | #2F7CE8 (est.) / #E02B2B (est.) / #3CDC2E (est.) | page-2 cards, white starburst pattern |

#### Panel construction (Obs)
No container panel. Layers: (1) scene or sky backdrop, (2) cards with 3D lip and slight stacked-deck offset, (3) separate CLOSE pill with drop shadow, (4) green triangle pointer left of grid in sheet_02 cell 1-3/1-4 (purpose unclear). CLOSE position varies between frames (left-centre between VIP and coins at 1.5 s; below VIP at 2.5-3.5 s; below the coin grid at 5.0-6.0 s; sheet_02 cells 2-2..2-4 again between), which is inconsistent with one fixed screen layout. Hypothesis: shop is world-space / camera-driven or a swipeable pager; unresolved.

#### Button recipe (Obs)
CLOSE: red gradient pill, ~0.7x a coin card's width, heavy white label with dark outline, slight tilt (may be recording skew), shadow below, no icon. Coin cards are the buy buttons (whole card is the target); no separate buy button or price chip legible.

#### Typography (Obs)
| Trait | Observation |
|---|---|
| Numerals | FULL digits with commas (`10,000` ... `500,000,000`) on packs, unlike v5's K/M/B in HUD; white, heavy, thick brown-orange outline; fill ~80% of card width at card top |
| Tier value series | 10,000 / 50,000 / 250,000 / 1,000,000 / 50,000,000 / 500,000,000 |
| BEST DEAL | heavy caps, white fill, dark outline, straddles card top edge |
| V.I.P | largest text in the shop (~40% of VIP card height, est.), white/gold with thick dark outline, bottom-centre overlapping card edge |
| Perk line | right-aligned 3 lines "CUSTOM / [V.I.P] / TAG!" with bracketed middle word, small, tilted ~-5 deg (est.) |
| x2 callouts | two `x2` flanking a red cap-style icon on the VIP card |
| Faces | same heavy rounded family as v5 (candidates above) |

#### Icons, layout, spacing (Obs)
| Aspect | Observation |
|---|---|
| Coin icon | gold coin piles scale with tier: single small stack (10,000) -> wide pile (1,000,000) -> large mound (500,000,000) |
| Layout (sheet_02 cell 1-3) | 3 col x 2 row coin grid, near-square portrait cards (~0.8-0.9 w:h, est.), tight gaps (~5% card width, est.); VIP card left, ~2 coin cards wide, landscape ~2.2:1 (est.) |
| Spacing | card gap small; CLOSE separated by about half a card height |
| Page 2 (sheet_03 cell 1-4) | three tall cards (blue, red, green), slight fan rotation, each white sunburst pinwheel pattern + top-left count tag ("1/50", est. reading); CLOSE centred below |

#### Best-deal / value signalling (Obs)
| Signal | Detail |
|---|---|
| Different material | holographic rainbow vs flat gold |
| Size and position | largest element, first (left) in reading order |
| Ornament overshoot | crown tilted ~-20 deg (est.) off the corner; tag over edge; wordmark over edge |
| Perk callouts | `x2` x2, custom-tag line |
| Tier on packs | numeral size + pile size, not colour; one small corner tag ("OP", est. reading, bottom-left of the 1,000,000 card, too small to confirm) |
| Absent | no visible price chip, no strike-through price, no "limited" timer, no notification dot |

#### Progress / timers / dots
None observed.

#### Lobby station labels (Obs)
Floating small white outlined labels with colour icon above each pad (QUEST / REBIRTH / SHOP / UPGRADE / SETTINGS; settings also has a blue gear). Pads are big flat saturated discs distinguishing function by colour. (v6/sheet_01 cell 1-1, 1-2)

### 3.3 VFX / motion timeline (Obs; 0.5 s per frame; UI tween vs camera pan indistinguishable)
| t (s) | Cell | Element | What is seen | Layers |
|---|---|---|---|---|
| 0.0 | sheet_01 1-1 | lobby idle | pads and labels, avatar centred | world, billboards |
| 0.5 | sheet_01 1-2 | lobby tilt | settings pad enters frame right | camera |
| 1.0 | sheet_01 1-3 | shop in | shop content small and smeared (ghosted VIP card at far left), backdrop swaps to pale faceted planes + sky | scale-in or camera fly, motion blur |
| 1.5 | sheet_01 1-4 | shop settling | cards larger; CLOSE centre | UI |
| 2.0-2.5 | sheet_01 2-1, 2-2 | VIP focus | VIP card shrinks then grows to centre; crown, tag, wordmark readable | UI/camera |
| 3.0-3.5 | sheet_01 2-3, 2-4 | VIP hold | stable, CLOSE below | UI |
| 4.0-5.0 | sheet_02 1-1..1-3 | pan to coin grid | VIP card leaves left; grid centres; CLOSE moves below grid | pan |
| 5.5-6.0 | sheet_02 1-4, 2-1 | coin grid hold | grid centred, CLOSE below | UI |
| 6.5-7.5 | sheet_02 2-2..2-4 | pan back left | VIP card re-enters at far left, CLOSE between VIP and grid, grid right (partly under TikTok sidebar) | pan |
| 8.0-8.5 | sheet_03 1-1, 1-2 | back in lobby | shop closed | camera |
| 9.0 | sheet_03 1-3 | page 2 in | sky + rainbow arc backdrop; three tiny cards at top-left | scale-in from small |
| 9.5-10.5 | sheet_03 1-4, 2-1, 2-2 | page 2 hold | three large fanned cards, CLOSE below | UI |
Pop-in duration upper bound <= 0.5 s (sheet_03 cell 1-3 -> 1-4).

#### 3.3b Pan / pop-in bounds (Obs bounds; easing is impression only)
| Item | Bound | Basis |
|---|---|---|
| Lobby -> shop | <= 0.5 s: smeared ghost frame at t=1.0, settled by t=1.5 | sheet_01 cells 1-3, 1-4 |
| Pan VIP <-> coin grid | each leg ~1.0-1.5 s (mid-frames at t=2.0 and t=4.0, 6.5-7.0 on the way back) | sheet_01 cell 2-1, sheet_02 cells 1-1, 2-2 |
| Dwell | VIP >= 1.0 s (t=2.5-3.5); coin grid >= 1.0 s (t=5.0-6.0), identical hold frames | sheet_01 cells 2-2..2-4; sheet_02 cells 1-3..2-1 |
| Shop -> lobby | <= 0.5 s (shop at t=7.5, lobby at t=8.0) | sheet_02 cell 2-4, sheet_03 cell 1-1 |
| Lobby -> page 2 | page 2 tiny at t=9.0, full size at t=9.5; backdrop swaps to sky + rainbow arc | sheet_03 cells 1-3, 1-4 |
| Easing impression | ghosting/smear in the in-between frames = fast ease-out into place; overshoot not visible | all above | Resting frames show no shimmer visible at this resolution; whether the VIP gradient animates is unresolved.

### 3.4 Recipe: Roblox builds for v6 tricks (recommendation)
| Trick | Primitives and starting values | Cost |
|---|---|---|
| Holographic hero card | Frame + `UIGradient` 6-8 ColorSequence keys (yellow, lime, cyan, blue, magenta, orange), Rotation 20-30; loop `Offset` -1 -> 1 Linear 3-4 s (RepeatCount -1); white diagonal glint Frame with transparency-gradient, `ClipsDescendants`, sweeps 0.6 s every ~3 s | cheap |
| Best-deal ornaments | crown ImageLabel rotated -18 deg, ZIndex +1, bob +/-3 px 1.6 s Sine; tag straddling top edge `Rotation -3`; wordmark with `UIStroke` + `UIGradient` | cheap |
| Coin pack cards | one card template; tier -> pile icon (3-4 sprites) + full-digit numeral with `UIStroke`; 3D lip; tilt 0 (skip recording skew); press = scale 0.95 | cheap |
| Panel-less float | cards parented to a ScreenGui with no container; backdrop via BlurEffect or a themed ViewportFrame/world camera; staggered pop-in 0.05 s per card (Back Out 0.3 s) | cheap-medium |
| Labelled CLOSE | red lip button, label "CLOSE" not only X; >= 44 px high | cheap |
| Lobby labels | BillboardGui icon + short label above each pad, MaxDistance ~80, bob; pad colour = function | cheap |
| Starburst pattern | tiled ImageLabel pinwheel texture with ImageTransparency 0.5 over a coloured card; optional slow rotation 6-10 deg/s | cheap |
| Pop-in | UIScale 0 -> 1.06 -> 1 (Back Out 0.3-0.4 s) + fade 0.15 s; sound whoosh | cheap |
| Sound cues | whoosh on page in, soft metallic ping on hover/focus of hero card, coin-spill on purchase success | cheap |

### 3.5 Mapping to Climb & Collect (v6)
| Moment | Technique | Why |
|---|---|---|
| Shop starter pack | the hero card treatment (unique material, crown/ornament overshoot, tag, wordmark) placed first/left | the one offer meant to convert; flat siblings make it pop |
| VIP | same hero card with different perk line and x-multiplier callouts; highest-tier iconography | rainbow/holo = top tier language, consistent with v5 |
| Coin packs | tiered cards: full-digit numeral + escalating pile icon; no colour change per tier | magnitude read without reading numbers |
| "Best deal" claim | holographic material + tag + largest size + first position | four independent signals; only apply to an offer that really is best (consumer-honesty flag) |
| Sanctuary stations | pad + floating icon-label per function (shop, bats, collection, daily, settings) | phone-readable, zero UI chrome |
| Section/bat/egg pages | colour-coded tall cards with pattern + count tag (`n/50`-style) | quick scan of collections/passes |
| Close affordance | labelled red pill separated from content | reduces mis-taps on phone |

---

## 4. Moment -> technique matrix (recommendation; which technique, why, cost)
| Moment | Primary technique (source) | Secondary | Why it fits C&C | Cost | Constraint |
|---|---|---|---|---|---|
| Egg break at the nest | in-world crack + <= 0.3 s white flash + rarity ring + billboard name/chance; HUD stays (v5 reveal scaled down, 2.4 whiteout row) | ring-unfold sparkles (v4) | player is exposed to guardians and bat thieves; a blocking modal would be a hazard | medium, one-shot | break is on the spot, creature is unsecured (egg-loop rule) |
| Rarity tiers (3-tier banners) | tier 1 billboard only; tier 2 banner + sparkle burst; tier 3 flash + holographic name + aura; rainbow/holo reserved for the top tier (v5 HUD ramp, v6 VIP) | chance % line (v5) | one visual language where "more shine = rarer", readable at phone size | cheap to medium | tier names/count come from the owner's banner plan, not from these refs |
| Hatch / secured reveal (safe zone) | full v5 reveal: wash, name -> chance -> multiplier -> "Click to continue", HUD hidden, then card flies into collection slot (v5 cells 2-3..2-4, sheet_02 1-1) | v4 rings unfolding around the egg | no guardian risk in sanctuary, so a blocking beat is safe and feels like a prize | medium | secured creature stays (rule) |
| Creature idle / aura | nested counter-rotating rings + sparse star sparkles + soft breathing aura, ring count scales with rarity (v4) | blob ground shadow | value readable from distance without UI | cheap-medium with LOD | D3: is the carried creature's aura visible to thieves? |
| Guardian presence | dark/cool faction rig: black rings, cyan square-window eyes, large wings; eye opens and ring speed ramps on first strike (v4) | none observed for shake or fog | silhouette contrast with gold creatures; escalates without HUD text | medium, 1-2 in view | first strike alerts guardian (project rule) |
| Section unlock / new bat | location title card + Before -> After panel (v5) ; gold seal ring breaks into sparkles at the gate (v4) | gate chip billboard | marks progress and shows what changed | cheap | bats unlock per completed section set |
| Summit | wide -> macro -> wide camera with FOV tween, star-glint macro, sparkle cluster, optional confetti (v4 plan, v5 hero reel) | speed lines on final dash | pays off the climb for almost zero asset cost | cheap | replace cash bills with project-appropriate confetti |
| Banking / secure | rings lock into a halo, 0.5-0.8 s sparkle, count-up with tick, Claim-style button (v4, v5) | HUD number pop | says "now safe" without text | cheap | exit permanently secures (project rule) |
| Level-up | XP bar warm fill + rainbow marker at fill head + numeral pop (v5 cells 2-1, 2-2) | white flash 0.25 s | highest feedback per cost | cheap | phone thumb zones (D6) |
| Daily rewards | tile grid with DAILY/PLAYTIME tabs, claimed/ready/locked overlays, mm:ss chips, Claim All (v5 cell 1-2) | rising-gap timer ladder | retention loop with clear next goal | cheap | timers at 1 Hz, server time |
| Starter pack / hero offer | single holographic card, crown/ornament overshoot, tag, wordmark, perk line, first in order (v6) | x-multiplier callouts | one offer must stand out from flat siblings | cheap | perks = tycoon speed/convenience/cosmetics only |
| VIP / pass | same hero card, different perk set; top-tier iconography (v6) | gold->red->rainbow value ramp (v5 HUD) | consistent "rainbow = top" language | cheap | no paid power in raids/theft |
| Coin / currency packs | tiered cards: full-digit numeral + pile icon that grows per tier, flat colour (v6 sheet_02 cell 1-3) | K/M/B in HUD only | magnitude read before reading digits | cheap | show odds only on random items, not on fixed packs |
| Prestige-like reset | Before -> After boxes, warning line, green requirement capsule, primary + secondary buttons (v5 cell 1-4) | count-up on the After box | clear trade-off before commit | cheap | only if a prestige loop exists; else reuse for bat upgrade compare |
| Theft drop (3 s) | pillar beam + countdown ring over the dropped creature (recipe only, no reference shows it) | shrinking ring + tick | tells everyone it is grabbable and for how long | cheap | bat hit knocks carrier, drop lasts 3 s (rule) |
| Station wayfinding | pad colour = function + icon-led floating label (v6 sheet_01 cell 1-1) | bobbing billboard | phone-readable, no UI chrome | cheap | cap ~20 billboards in view |
| Modal backdrop | live world blurred behind the modal, no hard dim (v5 cells 1-2..1-4) | 0.55 dim frame | keeps place and context | medium | lower blur size on phone |

### 4.1 Moment index (where to look)
| Moment | Sections |
|---|---|
| Egg break | 1.7, 2.5 |
| Rarity reveal | 2.3 (10.00 s), 2.5 |
| Hatch | 1.7, 2.5 |
| Creature idle / aura | 1.4-1.7 |
| Guardian presence | 1.7 |
| Section unlock | 1.7, 2.5 |
| Summit | 1.5, 1.7, 2.3 (hero reel techniques) |
| Banking | 1.7, 2.5 |
| Level-up | 2.2, 2.4, 2.5 |
| Daily rewards | 2.2 card anatomy, 2.5 |
| Shop starter / VIP / coin packs | 3.2-3.5 |
| Prestige | 2.2 (Rebirth card), 2.5 |
| Theft drop (3 s) | recipe only: pillar Beam + mm:ss-style countdown ring over dropped creature (2.4 timers, 1.6 Beam row); no reference shows it |

## 5. Conflicts and open decisions (owner)
| # | Conflict | Recommendation | Cost |
|---|---|---|---|
| D1 | v4 (ornate, mythic, blue/purple/gold) vs v5/v6 (toy-candy, saturated, chunky outlines). Different registers. | v4 language for in-world creatures/guardians, v5/v6 language for UI; gold is the shared bridge | mythic VFX may feel more serious than the UI chrome. Note: v4's indigo/violet + gold also matches the third option sibling C offers (violet only for reward and magic moments) |
| D2 | v5/v6 UI vs the approved HUD v2 (per sibling C: blue panels, yellow CTAs, Bangers labels) and the verified E+B HUD review in CLAUDE.md (not read here). v5 role colours already match (yellow = buy, red = close); v5's dark charcoal body and orange ribbon do not match blue panels. | take v5/v6 structure (overhanging ribbon + X, lip button, state ladder, hero card, billboards) and keep HUD v2's blue skin; do not import the dark body or orange ribbon unless the owner asks; merge into SYSTEM.md only after the owner decides | ribbon accent colour becomes a decision; rework of already-verified HUD if the owner supersedes it |
| D3 | v4 aura = visible value; theft rule = carried unsecured creature can be stolen | owner decides whether a carried rare's aura is visible to other players. Visible = more theft, more tension; hidden = less readable risk | affects theft balance |
| D4 | v4 density (hundreds of parts, dynamic lights) vs phone target | LOD ladder in 1.6, cap 2-3 full creatures | lower fidelity far away |
| D5 | v5 full-screen reveal vs "break at nest on the spot" + chasing guardians | in-world short reveal at the nest, full reveal at sanctuary | two reveal builds |
| D6 | v5 HUD stack position vs Roblox mobile controls | move to safe zone; test on four phone sizes | layout differs from reference |
| D7 | Paid offers: "BEST DEAL", `x2` perk callouts and chance % displays. Owner stance (2026-10-27): sell tycoon speed/convenience/cosmetics, no paid power in raids or theft, show odds on paid random items. | keep "best deal" true; `x2`-style perks apply to tycoon income/speed only; show odds on any paid egg/roll; verify Roblox policy at publish; no products, prices or Robux without separate authorization | compliance work; hero card can only promote an offer that really is best |
| D8 | v6 shop positioning is ambiguous (world-space vs ScreenGui) | build ScreenGui first; world-space only if owner wants a diorama shop | none |
| D9 | Typeface: HUD v2 uses Bangers (per sibling C, a Roblox built-in); v5/v6 UI face reads rounder and heavier than a condensed comic face (the condensed caps in the frames are burned-in video captions, not game UI) | keep Bangers for HUD v2 consistency, or test FredokaOne / LuckiestGuy (built-ins) on the hero card and reveal only; do not mix more than two faces | face change on offer screens vs consistency |

## 6. Do-not-copy list
Panel strings (REWARDS, TRAILS, REBIRTH, BEST DEAL, V.I.P, CLOSE, "Click to continue", location banner text), creature/pet names and designs, the exact 4x3 rewards grid, the crown+holo VIP card composition as a 1:1 clone, "Strength/Wins" economy, the three-card starburst page, the sprout-banner treatment, the ophanim creature silhouettes as drawn.

## 7. Top 10 techniques to steal (impact per mobile cost, best first)
Ranking basis: visible impact in the frames (my judgement) divided by build and runtime cost on a phone. No device measurement exists for any of these.
| # | Technique | Source | Cost |
|---|---|---|---|
| 1 | Panel grammar: overhanging icon ribbon + overhanging red X + dark outline + lip buttons | v5 | cheap |
| 2 | Hero offer card: single holographic material, ornament overshoot, tag, size and first position | v6 | cheap |
| 3 | Reward tile state ladder (check / CLAIM! / timer chip) with Claim All | v5 | cheap |
| 4 | Heavy outlined numerals; K/M/B in HUD, full digits on packs, pile icon scales with tier | v5, v6 | cheap |
| 5 | Floating icon+label billboards over stations and zone entries | v6, v5 | cheap |
| 6 | Before -> After upgrade panel with green requirement bar and primary/secondary pair | v5 | cheap |
| 7 | XP bar with warm gradient fill and rainbow marker ring at the fill head; level-up pop | v5 | cheap |
| 8 | Reveal sequence: flash, name, chance %, multiplier, continue; HUD hides | v5 | medium (once per reveal) |
| 9 | Sparse 4-point star sparkles + soft breathing aura | v4 | cheap |
| 10 | Nested counter-rotating eye rings as rarity/faction aura, LOD'd | v4 | medium |

Honourable mentions: blurred live world behind modals (v5, medium), wide -> macro -> wide camera plan for the summit (v4, cheap), location title card (v5, cheap).
