# Stampede Spire: mountain look-dev (2026-10-29)

Sources: only the approved r2 sheets in `concepts/2026-10-29/` and the approved r3 biome sheets in `concepts/2026-10-29-r3biomes/`. Round-1 sheets (01–05) were superseded by the owner's "REDO" and are not used.
Each sample is a luminance-percentile or hue-filtered median of the named pixel box (x0,y0)-(x1,y1) in the 1344×752 image (r2) or the 2688×1520 image (r3). The samplers are `art/tools/sample_refs.py` (r2) and `art/tools/sample_r3.py` (r3, same method; writes `art/palette_r3.json`). Any value not in this table is not used.
r3 filters (`sample_r3.py`): pale = B>200 & R>150 · cyan = G>170 & B>200 & R<150 · green = G>140 & G>R+50 & G≥B−10 · warm = R>G+25 & G>B+15 & R>120 · gold = R>170 & G>130 & B<G−25 · violet = B>180 & R>G+5 & B>R+15 · bright = R+G+B>690 · unblue = B−R<18 · rust = R>G+25 & G>B−5. "bg-masked" drops pixels within 28 of that species panel's empty box (panel x0+20, 470)-(x0+60, 510), panel x0 = 0 / 540 / 1080 / 1610 / 2140. r3 tokens are referred to as `s<N>.<token>` (e.g. s2.rock).

Short names: **Z1** = r2-zone1-taiga, **Z2** = r2-zone2-crevasse, **Z3** = r2-zone3-obsidian, **Z4** = r2-zone4-aurora, **RR** = r2-rider-roblox, **RP** = r2-replacements-saiga-ashmane, **S2** = r3-s2-rime-fog-forest, **S4** = r3-s4-ice-cave-labyrinth, **S5** = r3-s5-hot-spring-terraces, **S7** = r3-s7-storm-peaks, **S8** = r3-s8-wind-carved-spires, **S9** = r3-s9-cloud-sea-ridge.

## Zone 1: Frozen Taiga Foothills (Z1 header photo, x 540–1150, y 0–122; RR backgrounds)
| Token | Hex | Trace |
|---|---|---|
| sky_top | #ACC7DF | Z1 (700,2)-(780,15) p50 |
| sky_horizon / fog | #A5B8D5 | Z1 (760,40)-(800,48) p50 |
| sun_glow | #FAF9F6 | Z1 (900,8)-(930,20) p50 |
| far_mountain | #A5BDDA | Z1 (740,30)-(770,38) p50 |
| far_treeline | #7B93AE | Z1 (720,55)-(770,65) p50 |
| pine_dark / pine_mid / pine_snow | #2E3C4E / #3E5067 / #758B9F | Z1 pine (600,30)-(640,90) p10 / p35 / p92 |
| snow_lit / snow_mid / snow_shadow | #E9EAF0 / #DEE3EE / #688AB4 | Z1 foreground (850,105)-(900,120) p70; (700,100)-(900,122) p50; (700,100)-(760,122) p15 |
| river_ice | #81A1C0 | Z1 (770,85)-(820,92) p50 |
| rock | #343843 (cool) / #373331 (warm) | Z1 (1050,100)-(1100,118) p8; RR (0,300)-(440,440) p4 |

- **Light:** low morning sun behind the trees (Z1 sun at x≈915, y≈15, about a quarter of the frame up) → ClockTime ≈ 8.5. Warm-white sun, cool blue shadows (snow_shadow).
- **Fog/haze:** light. The far range at x 700–900 is still readable but lifted toward sky_horizon → low Atmosphere density, haze colour sky_horizon.
- **Set dressing:** dense snow-loaded conifers in clumps (Z1 left/right edges), open snowfields with soft drifts, a frozen river, low dark boulders half-buried in snow (Z1 x 1050–1100; RR foreground), and a distant snowy range.

## Zone 2: Crevasse Ice Canyons (Z2 header, x 400–1344, y 0–165; RP left panel)
| Token | Hex | Trace |
|---|---|---|
| ice_deep | #054480 | Z2 left wall (420,60)-(440,140) p10 |
| ice_mid | #1066B0 | Z2 wall (520,40)-(560,120) p50 |
| ice_hi | #A3DBF7 | Z2 wall (520,40)-(560,120) p95 |
| shaft (light) | #F1FBFE | Z2 light shaft (690,5)-(710,30) p50 |
| canyon_far / fog | #84D9FD | Z2 far canyon (660,60)-(690,100) p50 |
| floor_snow | #8CD6F8 | Z2 canyon floor (650,150)-(720,165) p60 |
| bridge | #43B2F3 | Z2 ice bridge (670,135)-(700,145) p50 |
| rock_ledge / shadow | #063D79 / #053E74 | Z2 ledge (850,110)-(950,160) p50; (400,130)-(420,165) p20 |
| ground_snow / cliff | #A5CCE8 / #2E669B | RP (100,430)-(300,470) p60; RP (0,100)-(120,300) p50 |

- **Light:** overhead daylight in narrow shafts from the canyon top (Z2 x 650–780) → ClockTime ≈ 12, with a strong blue tint on everything below the rim.
- **Fog/haze:** strong cyan haze in the depths (canyon_far) → higher density, haze colour canyon_far, decay toward ice_deep.
- **Set dressing:** towering faceted ice walls on both sides (Z2 x 400–640 and 960–1344), a distant arched ice bridge across the canyon (Z2 x 660–720, y 130–145), and rounded dark-blue ledges (Z2 x 820–1100). Light shafts become beams.

## Zone 3: Geothermal Obsidian Ridge (Z3 header, x 460–1180, y 0–122; RP right panel)
| Token | Hex | Trace |
|---|---|---|
| sky_upper | #41373D | Z3 (470,0)-(560,30) p50 |
| sky_haze | #A97F71 | Z3 (760,20)-(790,30) p50 |
| sky_sun / sky_glow | #E2A475 / #F6BE86 | Z3 (880,5)-(1000,40) R>150; (930,20)-(960,35) p50 |
| spire_dark (obsidian) | #0F090C | Z3 spire (620,30)-(660,70) p10 |
| rock_lit (basalt) | #2B1516 | Z3 (590,40)-(650,90) p75 |
| far_ridge | #4B2A24 | Z3 (830,50)-(870,70) p50 |
| ground | #6F4231 | Z3 (800,105)-(880,120) p40 |
| lava_deep / lava_orange / lava_hot | #9B260F / #F46E1E / #FDB844 | Z3 (560,60)-(660,115) red / orange / yellow pixel medians |
| steam | #F3C49D | Z3 plume (725,30)-(740,60) p60 |
| ash_ground | #713421 | RP (700,400)-(800,470) p50 |

- **Light:** low sun at the horizon (Z3 x≈940, y≈30) → ClockTime ≈ 17.8, sunset orange key, near-black ambient.
- **Fog/haze:** heavy warm haze (sky_haze), plus steam plumes rising from the ground (Z3 x 700–760 and 1080–1170).
- **Set dressing:** jagged leaning obsidian spires and ridges (Z3 x 560–720 and 1000–1130), glowing lava cracks running down the slopes and across the floor (Z3 x 560–640), steam vents, and dark basalt ground with ember edges (RP hooves panel).

## Zone 4: Aurora Crown (Z4 header, x 400–1190, y 0–178)
| Token | Hex | Trace |
|---|---|---|
| night_deep | #04132F | Z4 whole header, pixels with R+G+B<90 |
| sky_navy | #132765 | Z4 (620,5)-(860,60) p5 |
| aurora_green / aurora_teal | #41D4A2 / #51E6B3 | Z4 (600,0)-(800,60) green-dominant; (1000,10)-(1030,40) p60 |
| aurora_purple | #A469F4 | Z4 (850,0)-(1000,70) purple-dominant |
| crystal_glint / crystal_light / crystal_mid / crystal_deep | #B5ECFD / #3F91F6 / #3D62B2 / #0E255D | Z4 crystal (490,10)-(530,110) bright / mid; (440,90)-(470,130) p50; (430,80)-(500,150) p10 |
| rock_spire | #152653 | Z4 (870,90)-(900,130) p40 |
| far_mountains | #295593 | Z4 (600,80)-(640,95) p50 |
| snow_path / snow_shadow | #8195DA / #547ABB | Z4 path (960,130)-(1000,150) p60; (1100,140)-(1150,160) p40 |
| sky_zenith / sky_mid / sky_low | #123968 / #1D4D7D / #29518F | Z4 sky left of the crystals, blue-dominant pixels (B > G+10, B > R+10, R+G+B < 420), median of (400,0)-(600,10) / (400,30)-(600,40) / (400,50)-(600,60) |

- **Light:** night with the aurora as the main light (Z4 sky) → ClockTime ≈ 0, stars on, blue-violet ambient. The crystals self-glow (crystal_light/glint).
- **In Roblox (2026-10-29 contrast pass):** ClockTime 18.6 (dusk), because Roblox's midnight sky is black and dusk gives the sky_navy gradient. Outdoor ambient = crystal_glint, so lit facets and the path read pale as on the sheet. Crystal facets alternate between the crystal_deep end and the crystal_glint end of the ramp (Z4 crystal at x 490–530: one bright face beside one dark face). Small Neon crystal_glint shards sit on the ridge lip.
- **Clock (M6 sign-off pass):** Roblox darkens a custom skybox toward black after sunset, so at 18.6 the Z4 skybox read black (evidence/66–67). Zone 4 now runs ClockTime 13 at Brightness 0.6: the skybox shows at its authored sky_zenith → sky_low navy, and the night mood comes from the low brightness, the crystal_glint outdoor ambient and the tint. Stars don't render in daytime. Pending owner review (D5).
- **Aurora (M6 sign-off pass):** rays run aurora_green → aurora_teal → aurora_purple from foot to top on the left, and turn purple-dominant toward the right of the span (Z4 x 850–1000 is purple-dominant). Additive overlap washed a top-only purple out to white.
- **Summit shot (M6):** the summit orbit arc is centred on the downhill side, looking up past the crown into the Z4 sky and z4_far peaks; it no longer starts at a random angle that could face zone 3's dark terrain and z3_far peaks (evidence/36).
- **Sky (M6, 2026-10-29):** a skybox built only from sky_zenith → sky_mid → sky_low by elevation (zenith above 60°, mid at 25°, low at the horizon and below), shown in zone 4. The sheet's upper sky is mid-navy, not black (the earlier sky_navy token is the p5 dark end of that band).
- **Fog/haze:** clear air, low density, faint blue haze (far_mountains) on distant ranges.
- **Set dressing:** clustered tall hexagonal crystal spires (Z4 x 420–560 and 1040–1120), a jagged dark ridge (Z4 x 860–1000), a snowy path climbing the ridge to the top (Z4 x 900–1190), aurora curtains in green to purple across the whole sky, and blowing snow (wind gusts on the sheet).

## Section 2: Rime Fog Forest (S2 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| sky_fog | #E2E9F5 | S2 (1400,0)-(1600,60) p50 |
| fog_glow (key light) | #EBF1FA | S2 (1400,0)-(1600,150) p95 |
| horizon_fog | #BFCCE0 | S2 (1360,120)-(1480,200) p50 |
| far_trees | #C0CDE2 | S2 (1580,30)-(1740,140) p25 |
| birch_bark / birch_mark | #798495 / #2E2F36 | S2 birch trunk (935,40)-(965,250) p85 / p8 |
| rime_lit / rime_shadow | #B1C3DC / #63768B | S2 rimed ferns (2000,160)-(2150,300) p90 / p30 |
| snow_lit | #DCE4F3 | S2 path (1380,240)-(1560,320) p70 |
| snow_mid / snow_shadow | #CFD9EC / #BAC5DA | S2 (1350,200)-(1600,330) p50 / p15 |
| rock / rock_dark | #4C586F / #323D4F | S2 boulder (1640,250)-(1760,320) p40 / p8 |
| title_fill / title_shadow | #BBDFF4 / #384F61 | S2 "RIME FOG" (100,115)-(790,235) pale median / p3 |
| stag (Rime Stag) / stag_antler | #8D8C91 / #E4F1FA | S2 (160,620)-(320,700) p50; (170,380)-(500,530) bg-masked p70 |
| llama (Mistwool Llama) | #A5AABE | S2 (650,640)-(850,720) p50 |
| wolf (Hoarfrost Wolf) | #9096A6 | S2 (1200,600)-(1380,700) p50 |
| bison (Birchback Bison) / bison_horn | #878894 / #827878 | S2 (1720,600)-(1900,720) p50; (2075,540)-(2110,600) bg-masked p30 |
| fox (Fogtail Fox) | #ABB1C7 | S2 (2320,650)-(2480,730) p50 |

- **Light:** no sun disk. The brightest area is a diffuse fog glow at the top centre (S2 x 1400–1600, y 0–150) → overcast daylight, ClockTime ≈ 10 (judgement; no sun to read the time from). Soft, near-shadowless, cool grey-blue.
- **Fog/haze:** heavy. The trees behind x 1400–1750 fade almost to the fog (far_trees ≈ horizon_fog) → the densest Atmosphere so far, haze colour horizon_fog.
- **Set dressing:** tall birch trunks with dark bark marks (S2 x 920–990 and 2050–2200), snow-loaded firs fading into the fog, rime-frosted ferns and branches (S2 x 1950–2250, y 150–330), a snowy path running into the fog (S2 x 1350–1600), and a dark rounded boulder (S2 x 1600–1950, y 190–330).

## Section 4: Ice Cave Labyrinth (S4 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| cave_mouth (key light) | #B6F4FD | S4 opening (1300,40)-(1420,140) p80 |
| cave_haze | #5DCEFB | S4 (1360,0)-(1560,60) p50 |
| ice_wall | #0B6DA8 | S4 (1500,60)-(1640,140) p50 |
| ice_deep | #011F3C | S4 (2250,0)-(2600,90) p30 |
| ice_glow / ice_glint | #10E3F5 / #E0FDFE | S4 crystals (2060,120)-(2140,240) cyan median / p97 |
| moss_glow | #0ED0CD | S4 (950,220)-(1080,290) green median |
| ice_shelf | #1481C5 | S4 (1400,160)-(1600,220) p50 |
| floor_lit / floor_mid / floor_shadow | #5EC9F5 / #2497DC / #0C66B1 | S4 floor (1400,250)-(1700,330) p80 / p50 / p15 |
| rock_dark | #022959 | S4 (1960,250)-(2150,320) p10 |
| title_fill / title_shadow | #E5FAFD / #032C4E | S4 "ICE CAVE" (100,120)-(850,240) pale median / p3 |
| elk (Lumen Elk) / elk_antler | #6CA5C5 / #40D6FA | S4 (140,620)-(300,700) p50; (160,380)-(500,560) bg-masked cyan median |
| bear (Cave Frost Bear) | #416D9C | S4 (680,620)-(880,740) p50 |
| armadillo (Shardback Armadillo) / armadillo_shards | #2F5177 / #71C3FC | S4 (1250,700)-(1450,780) p50; (1150,560)-(1450,660) bg-masked cyan median |
| lynx (Glowtail Lynx) / lynx_tail | #5886AC / #68EFFC | S4 (1760,640)-(1940,720) p50; (1630,640)-(1710,740) bg-masked cyan median |
| tapir (Drip-Ice Tapir) / tapir_fringe | #466E96 / #A5E3FB | S4 (2420,560)-(2520,640) p50; (2280,600)-(2480,700) p85 |

- **Light:** no sky. Cold cyan daylight falls through a cave opening left of centre (S4 x 1300–1450, y 0–150) → overhead, ClockTime ≈ 12 as in zone 2. Glowing cyan crystals (S4 x 2050–2140, y 110–240) and teal moss (S4 x 900–1100, y 200–300) light their own surroundings.
- **Fog/haze:** medium-strong cyan haze toward the opening (cave_haze); the depths fall to ice_deep navy (S4 x 2200–2688).
- **Set dressing:** an icicle and stalactite ceiling (S4 x 900–1000 and 1550–1750, y 0–150), stepped frozen shelves (S4 x 1350–1650, y 150–230), clusters of glowing crystal spikes, glowing moss beds, and rounded snow-ice boulders on the floor (S4 x 1400–2000, y 230–330).

## Section 5: Hot Spring Terraces (S5 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| sky | #CEDDED | S5 (1650,0)-(1760,40) p50 |
| sun_glow | #FEFEFD | S5 (1900,0)-(2060,60) p95 |
| steam | #D5D1D1 | S5 plume (1400,60)-(1520,140) p70 |
| far_mountain | #90BDE8 | S5 (2150,30)-(2300,90) p60 |
| far_forest | #6F88AA | S5 (2150,120)-(2340,200) p30 |
| travertine / travertine_mineral | #F0EAE3 / #BC9068 | S5 terraces (900,60)-(1250,200) p85 / warm median |
| pool / pool_deep | #AFD2CD / #83A4A8 | S5 pool (1000,220)-(1300,290) p50 / p15 |
| snow_lit / snow_mid / snow_shadow | #D9DCEB / #A5BFE5 / #8EACD4 | S5 terrace cap (1680,220)-(2080,250) p80 / p50 / p15 |
| pine_dark | #112637 | S5 (600,0)-(700,80) p10 |
| title_fill / title_shadow | #C8F0FD / #082743 | S5 "HOT SPRING" (65,120)-(855,235) pale median / p3 |
| buffalo (Steam Buffalo) / buffalo_horn | #877970 / #D7BEA8 | S5 (110,600)-(290,720) p50; (450,520)-(510,600) bg-masked unblue median |
| capybara (Onsen Capybara) | #907160 | S5 (660,620)-(900,740) p50 |
| goat (Geyser Goat) / goat_horn | #B6ABA0 / #D6924A | S5 (1150,640)-(1300,730) p50; (1360,450)-(1520,540) bg-masked warm median |
| antelope (Travertine Antelope) / antelope_horn | #C4AC95 / #AC9A90 | S5 (1740,620)-(1940,700) p50; (1960,460)-(2080,540) bg-masked unblue median |
| boar (Sulfur Boar) | #C9A06E | S5 (2220,620)-(2460,720) p50 |

- **Light:** the sun glow sits at the top edge right of centre (S5 x 1900–2060, y 0–60), high and veiled by steam → ClockTime ≈ 11.5. Warm-white light, blue snow shadows (snow_shadow).
- **Fog/haze:** the steam is the haze. Thick white plumes rise across the scene (S5 x 1350–2100, y 0–200) while the far mountains (S5 x 2150–2688) stay readable → medium density, haze colour steam.
- **Set dressing:** stepped travertine terraces with cream rims and orange mineral drips (S5 x 700–1340 and 1350–2100, y 150–330), turquoise pools (S5 x 850–1600, y 200–330), snow caps on the terrace edges, snowy pines behind (S5 x 1400–1700 and 2150–2688), and a snowy range on the far right.

## Section 7: Storm Peaks (S7 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| sky_storm | #192B5D | S7 (2000,0)-(2250,80) p30 |
| sky_cloud | #5869B4 | S7 (1950,90)-(2100,180) p60 |
| lightning_core / lightning_glow | #FBFBFE / #C1BAFB | S7 bolt (1020,0)-(1090,130) bright median; (950,0)-(1150,200) violet median |
| storm_haze | #3D4D9B | S7 (1200,40)-(1340,100) p50 |
| far_peaks | #24396B | S7 (2250,230)-(2450,300) p50 |
| storm_rock_lit / storm_rock | #586AAD / #1C2A5A | S7 peak (1100,150)-(1250,280) p70 / p10 |
| snow_lit / snow_mid / snow_shadow | #ABB9F3 / #6074C3 / #2A3D7B | S7 (1400,240)-(1600,320) p80 / p50 / p15 |
| title_fill / title_shadow | #D8F5FD / #0E2446 | S7 "STORM" (110,115)-(700,245) pale median / p3 |
| yak (Thunder Yak) / yak_horn | #3E477F / #C6D7F9 | S7 (100,620)-(280,720) p50; (500,500)-(550,600) bg-masked p60 |
| stallion (Stormmane Stallion) | #757C99 | S7 (720,610)-(880,690) p50 |
| gazelle (Stormcrest Gazelle) / gazelle_horn | #98A4D0 / #978CF8 | S7 (1200,620)-(1400,700) p50; (1340,460)-(1470,540) bg-masked violet median |
| rhino (Rumble Rhino) / rhino_horn | #475C87 / #9A92F9 | S7 (1720,600)-(1920,720) p50; (2000,560)-(2070,680) bg-masked violet median |
| wolf (Static Wolf) | #6877B6 | S7 (2260,620)-(2460,700) p50 |

- **Light:** no sun. A heavy storm-cloud ceiling (sky_storm), with forked lightning as the key light (S7 x 1020–1090 and 1500–1750, y 0–250). No stars, so it reads as a storm-dark day → day clock at low brightness (judgement, ClockTime ≈ 13).
- **Fog/haze:** medium violet-blue haze around the lit peaks (storm_haze); the far peaks drop to navy (far_peaks). Snow streaks blow diagonally across the frame.
- **Set dressing:** jagged dark storm-rock peaks with snow in the gullies (S7 x 700–1340 and 1350–2200), a rocky snow-covered summit under the player (S7 x 1600–2050, y 220–330), forked lightning strikes, and wind-blown snow.

## Section 8: Wind-Carved Spires (S8 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| sky_top | #4597E3 | S8 (1650,0)-(1780,60) p50 |
| sky_horizon | #9ECFF6 | S8 (2020,130)-(2120,180) p50 |
| wind_streak | #C1DCF3 | S8 (2000,40)-(2100,100) p90 |
| spire_lit / spire_rust / spire_shadow | #E19575 / #774641 / #572F30 | S8 spire (830,100)-(1000,300) rust pixels p85 / p50 / p15 |
| spire_dark | #362837 | S8 (830,100)-(1000,300) p3 |
| far_spires | #A6B2CD | S8 (1670,190)-(1720,240) p50 |
| snow_lit / snow_mid / snow_shadow | #F5F1F1 / #CACEDC / #989BAE | S8 drifts (2050,280)-(2250,330) p80 / p50 / p15 |
| title_fill / title_shadow | #C3EBFD / #214778 | S8 "WIND-CARVED" (40,115)-(900,225) pale median / p3 |
| pronghorn (Windrunner Pronghorn) / pronghorn_horn | #B88A6C / #333436 | S8 (170,600)-(300,650) warm median; (380,400)-(470,500) bg-masked p30 |
| markhor (Spire Markhor) / markhor_horn | #948B8D / #504C4D | S8 (680,610)-(880,690) p50; (840,400)-(980,520) bg-masked p40 |
| camel (Frostdune Camel) | #A28574 | S8 (1180,620)-(1380,720) p50 |
| leopard (Gale Snow Leopard) | #9FAFC1 | S8 (1800,620)-(1980,700) p60 |
| oryx (Spirehorn Oryx) / oryx_horn | #9D8B86 / #1E1E22 | S8 (2240,600)-(2420,680) p50; (2380,420)-(2480,540) bg-masked p20 |

- **Light:** bright clear day with no sun in frame; the faces turned to the viewer and the upper right are lit → high sun, ClockTime ≈ 14 (judgement). Deep blue sky with thin white wind streaks.
- **Fog/haze:** light. The distant spires (S8 x 1650–1720) fade only to far_spires → low density, haze colour sky_horizon.
- **Set dressing:** tall rust sandstone hoodoos and spires with snow on their ledges (S8 x 790–1100, 1350–1650 and 1950–2350), a natural arch (S8 x 1400–1650, y 100–230), wind-blown snow streaks, snowy slopes, and a rounded rust boulder under the player (S8 x 1690–2020, y 210–330).

## Section 9: Cloud Sea Ridge (S9 header, x 0–2688, y 0–330; species panels y 380–900)
| Token | Hex | Trace |
|---|---|---|
| sky_zenith / sky_warm | #B3AFC2 / #ECD3C9 | S9 (900,0)-(1100,30) p50; (1500,0)-(1700,30) p50 |
| sky_horizon | #FED2A9 | S9 (1600,70)-(1800,100) p50 |
| sun_core / sun_glow | #FFFEFE / #FEFADA | S9 (2100,40)-(2170,90) p97; (1950,0)-(2300,100) p70 |
| cloud_lit / cloud_mid / cloud_shadow | #FDDAC4 / #D7B8BC / #A6A0BB | S9 cloud sea (900,150)-(1300,320) p85 / p50 / p15 |
| far_peak | #B7A0BA | S9 (1170,60)-(1270,110) p50 |
| snow_lit / snow_shadow | #FEF7D5 / #C09E9E | S9 ridge (1960,240)-(2150,320) p80 / p15 |
| rock | #4E4745 | S9 (1720,240)-(1800,310) p30 |
| title_fill / title_shadow | #BEF1FD / #4F79AF | S9 "CLOUD SEA" (75,110)-(835,220) pale median / p3 |
| ostrich (Nimbus Ostrich) | #DFE0E8 | S9 (120,590)-(320,680) p50 |
| horse (Cloudmane Horse) | #C8CAD0 | S9 (700,620)-(880,700) p50 |
| deer (Halo Deer) / deer_antler | #DED6C7 / #F5CE96 | S9 (1160,620)-(1360,700) p50; (1360,450)-(1500,530) bg-masked gold median |
| sheep (Skyfleece Sheep) / sheep_horn | #B8CDE9 / #7998BA | S9 (1700,580)-(1950,720) p50; (1885,530)-(1945,600) bg-masked p40 |
| kudu (Mistwing Kudu) / kudu_horn | #B0B9D1 / #A38C7F | S9 (2260,600)-(2420,680) p50; (2380,380)-(2520,500) bg-masked p50 |

- **Light:** a low sun just above the cloud-sea horizon (S9 x≈2135, y≈70; horizon at y≈100) → golden hour, ClockTime ≈ 17.5. The sheet can't tell dawn from dusk; 6.5 matches the sun height as well. Warm peach sky, lavender cloud shadows (cloud_shadow).
- **Fog/haze:** medium warm haze at the horizon (sky_horizon); cloud fills everything below the ridge.
- **Set dressing:** a sea of cloud tops across the lower header (S9 x 0–2688, y 100–330), a few snow peaks poking through (S9 x 1150–1300, 1400–1650 and 2180–2350), and a snow ridge with exposed brown rock under the player (S9 x 1600–2200, y 190–330).

## PROPOSED (M8 prep): zone-1 creature tokens — not approved, not in use
Proposed by the M8-prep session on 2026-10-29. Nothing reads these yet; the owner approves them or vetoes them at the zone-1 creature sign-off.
Sampled on Z1 by `art/tools/sample_creatures.py`, using a luminance percentile of the creature pixels in each box. "bg-masked" means pixels near the panel colour are dropped; "unblue" keeps pixels with B−R < 18 (the panel's B−R is 27); "gold" and "leather" are hue filters. The models and their traces are in `art/creatures/README.md`.

| Token | Hex | Trace |
|---|---|---|
| elk.coat_shadow / coat / coat_light | #392D28 / #58483F / #7B685C | Z1 (120,260)-(220,305) p15 / p50 / p85 |
| elk.mane_shadow / mane | #5F544E / #94887E | Z1 (245,240)-(310,315) p20 / p70 |
| elk.antler | #B4B3B4 | Z1 (245,150)-(370,220) p70 unblue, bg-masked |
| elk.leg | #242223 | Z1 (50,340)-(130,390) p40 bg-masked |
| elk.hoof | #202124 | Z1 (25,387)-(40,405) p20 bg-masked |
| elk.muzzle | #332D29 | Z1 (340,250)-(365,265) p20 bg-masked |
| reindeer.coat_shadow / coat / coat_light | #695E58 / #877C75 / #ACA097 | Z1 (545,270)-(620,320) p15 / p50 / p85 |
| reindeer.antler | #897B73 | Z1 (710,172)-(780,220) p50 unblue, bg-masked |
| reindeer.leather | #5C4E47 | Z1 (610,240)-(730,330) p40 leather, bg-masked |
| reindeer.bell | #BE905A | Z1 (690,237)-(730,317) p60 gold, bg-masked |
| reindeer.hoof | #313034 | Z1 (480,380)-(495,398) p20 bg-masked |
| muskox.coat_shadow / coat / coat_light | #161414 / #262120 / #3D3430 | Z1 (975,280)-(1125,350) p15 / p50 / p85 |
| muskox.frost | #B0B0B2 | Z1 (975,245)-(1125,270) p97 bg-masked |
| muskox.horn | #80756C | Z1 (1150,237)-(1175,275) p70 unblue, bg-masked |
| muskox.sock | #726F70 | Z1 (915,365)-(930,380) p70 bg-masked |
| muskox.hoof | #2D2A2B | Z1 (965,385)-(1000,407) p10 bg-masked |
| hare.coat_shadow / coat / coat_light | #6A6F78 / #8F959E / #B6BEC8 | Z1 (215,570)-(290,615) p15 / p50 / p90 |
| hare.ear_tip | #7A7E84 | Z1 (420,465)-(435,500) p20 bg-masked |
| hare.saddle | #5D4940 | Z1 (285,545)-(340,570) p50 leather, bg-masked |
| hare.strap | #382D26 | Z1 (320,575)-(345,625) p40 leather, bg-masked |
| hare.claw | #313032 | Z1 (420,677)-(435,690) p15 bg-masked |
| boar.coat_shadow / coat / coat_light | #1F1D1D / #2E2A29 / #4B433E | Z1 (740,560)-(865,630) p15 / p50 / p85 |
| boar.frost | #B2B2B3 | Z1 (765,525)-(880,560) p98 bg-masked |
| boar.tusk | #938D86 | Z1 (920,600)-(935,622) p70 unblue, bg-masked |
| boar.snout | #625D64 | Z1 (940,605)-(960,620) p30 bg-masked |
| boar.hoof | #212123 | Z1 (860,677)-(880,687) p15 bg-masked |
| elk / reindeer / muskox / hare / boar .eye | #0C0A0A / #12100F / #181516 / #161212 / #141111 | Z1 eye boxes (322,236)-(334,243) / (751,231)-(762,239) / (1164,261)-(1174,269) / (432,522)-(443,531) / (912,578)-(921,586) p5 |
| <species>.eye_glint | #B0B0B2 (boar #B2B2B3) | = that zone's frost sample: Z1 (975,245)-(1125,270) p97 (boar (765,525)-(880,560) p98), bg-masked |

- **Proposed shape rules:**
  - Proportions are measured on the Z1 side views in avatar heights; 1 A = 1.98 m, from Z1's "R15 AVATAR (6.5 FT)".
  - Lateral widths use the RR front-view ratios: chest width = 0.82 × torso depth, head width = 0.88 × head depth, leg spacing = 0.47 × chest width.
  - Block-built models (owner decision 2026-10-29, creature-only exception to the faceted fidelity rule): bevelled box/wedge parts, flat colour per part, rigid per-part skinning. The coat is a 3-step height band (shadow / mid / light) from each species' own coat box.
- **Proposed style reference (creatures only):** "Ride a Dino" and "Steal An Egg" in-game footage, for shape language, detail density and shading only; no colour, species or proportion is taken from them. See `art/creatures/STYLE-STUDY.md` and `concepts/style-refs/SOURCES.md`.
- **Budget (M7, `prototype/PERF-BUDGET.md`):** ≤3k tris and ≤24 bones per creature.

## Cross-zone rules
- **Fidelity:** stylized and simplified, faceted low-poly shapes with painted gradients, phone-friendly (owner decision 2026-10-29). Painted look = per-zone palette atlas ramps (dark→light along U) built only from the tokens above.
- **Materials:** zone 1 snow/rock are matte; zone 2 ice gets a slight gloss; zone 3 obsidian is glossy black and lava cracks emit light (Neon); zone 4 crystals emit a glow (Neon/Glass). Each effect is traced to the matching sheet header: ice highlights (Z2 ice_hi), lava glow (Z3), crystal glow (Z4).
- **Transitions:** lighting and fog blend across each zone border with the same ramp as the slope blend.
- **Terrain edges (2026-10-29, Roblox build):** the mountain's flanks under the outer terrain edges are painted only with each zone's existing rock row (z1_rock, z2_ledge, z3_obsidian, z4_rock), from the light end at the rim to the dark end at the foot, the same dark-to-light reading as each sheet's cliff faces. No new tokens.
