# World design tokens — CLIMB & COLLECT (PROPOSED)

No `references/` folder exists. Per `OVERNIGHT_BRIEF.md`, the only design source is the
region palette and mood text in `master.md` §3 and §4. Every value below names the exact
master.md phrase it was derived from. A value that can't be traced gets deleted.
All values are PROPOSED until the user approves them.

## Palette (RGB)

| Token | RGB | Derived from (master.md) |
|---|---|---|
| goldenDaylight | 255, 214, 150 | §3 "golden daylight"; §4 Green Valley "Golden daylight" |
| meadowEmerald | 84, 176, 82 | §4 "meadow emerald"; §3 "lush saturated greens" |
| turquoise | 46, 196, 182 | §4 "turquoise"; §3 "clear turquoise falls" |
| forestTeal | 38, 112, 98 | §3 "deep forest teal"; §4 "Emerald/teal shadows" |
| lanternGold | 255, 178, 72 | §3 "amber lanterns"; §4 "warm lantern gold" |
| luminousIndigo | 92, 76, 220 | §4 Whispering Forest "luminous indigo" |
| sandstoneAmber | 214, 150, 82 | §4 Broken Cliffs "Sandstone amber" |
| charcoalSlate | 62, 66, 76 | §4 "charcoal slate" |
| skyBlue | 92, 184, 245 | §4 Broken Cliffs "bright sky blue" |
| stormBlue | 46, 72, 122 | §4 Storm Ridge "Storm blue"; §3 "deep cobalt" |
| electricViolet | 138, 78, 255 | §4 "electric violet"; §3 "storm violet" |
| electricCyan | 62, 224, 255 | §3/§4 "electric cyan" / "cyan" |
| iceBlue | 196, 232, 255 | §4 Frozen Summit "Luminous ice blue" |
| deepSapphire | 30, 62, 140 | §4 "deep sapphire" |
| auroraPurple | 156, 92, 246 | §4 "aurora purple" |
| moonlight | 220, 230, 255 | §3 "moonlight" |

## Terrain material colors

| Material | Use | Color token / RGB | Source phrase |
|---|---|---|---|
| Grass | Green Valley meadows | meadowEmerald 84,176,82 | §4 "meadow emerald" |
| LeafyGrass | Whispering Forest floor | forestTeal-leaning green 52,128,92 | §3 "deep forest teal", §4 "Emerald/teal shadows" |
| Ground | trails (valley, forest) | warm path 186,150,98 | §3 "ground paths" lit by "golden daylight" |
| Mud | creek banks, damp forest | 92,70,52 | §3 "wet stone"/"moss" damp ground |
| Rock | lower-mountain outcrops | lichen grey-green 120,128,108 | §3 "lichen-covered rock" |
| Sandstone | Broken Cliffs strata, ledges | sandstoneAmber 214,150,82 | §4 "Sandstone amber" |
| Slate | cliff strata, storm flats, summit trail | charcoalSlate 62,66,76 | §4 "charcoal slate" |
| Basalt | Storm Ridge rock, summit outcrops | stormBlue-dark 44,54,82 | §4 "Storm blue"; §3 "deep cobalt" |
| Limestone | Storm Ridge trail (contrast) | pale 196,192,178 | §3 "Preserve bright traversal contrast" |
| Snow | summit snowfields | iceBlue-white 236,244,255 | §4 "Luminous ice blue" |
| Glacier | summit ice faces | 150,206,240 | §4 "Luminous ice blue", §3 "icy crystal facets" |
| Ice | crystal ice accents | 176,232,252 | §3 "icy crystal facets" |
| Cobblestone | camp pads, ruin masonry | 150,146,132 | §3 "ruin masonry", "ancient stone ruins" |
| Sand | lake and river beds | 222,206,160 | makes water read §3 "clear turquoise" |
| Water (WaterColor) | lake, river, falls | turquoise 46,196,182 | §3 "clear turquoise falls" |

## Lighting baseline (lower mountain)

- ClockTime 15.4, warm sun: §3 "golden daylight".
- Atmosphere: haze for depth, decay toward stormBlue so far silhouettes cool off: §3 "atmospheric depth", "soft volumetric-looking mist (cheap implementation)".
- No glass/blur/glow material effects except focal magic accents (§3 "Magical effects used as focal accents, not everywhere").

## Scale and readability rules

- Avatar-scale checks from 5–6 studs above the trail (§3 "Validate in Roblox Studio at actual avatar scale").
- Trails always contrast with surrounding ground (§3 "Preserve bright traversal contrast").
- Summit visible from Foothold and every camp (§3 "Repeated summit glimpses").
