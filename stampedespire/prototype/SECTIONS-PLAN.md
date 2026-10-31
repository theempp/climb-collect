# Stampede Spire: 10-section mountain plan (rev 2, 2026-10-29 late, owner decisions)

Goal: a much longer climb in 10 long sections, with a progress timeline and a grind loop. This supersedes the decision "1,000 studs per zone" (Inbox note, 2026-10-29). The 4 signed-off biomes keep their look (M6) and species lists.

## 0. Owner decisions (2026-10-29 late, supersede rev 1)
| # | Decision |
|---|---|
| S1 | **10 biomes, one per section.** The 4 signed-off biomes are spread out; 6 new ones fill the gaps; Aurora Crown stays the summit. |
| S2 | New biomes: Rime Fog Forest, Ice Cave Labyrinth, Hot Spring Terraces, Storm Peaks, Wind-Carved Spires, Cloud Sea Ridge (Crystal Geode Fields dropped: reads like Aurora Crown). Order below approved. |
| S3 | **Top speed 78** (today's). Riders and herds get progressively faster up the mountain: 22 -> 78, about 15% per section. |
| S4 | **~40 s per section at tier 1, ~6.7 min total** (owner chose shorter than the ~8.7 min of rev 1). |
| S5 | **Reference sheets first** for the 6 new biomes, in the r2 sheet style, owner-approved before any build (D8; owner OK'd the image credits for them). |
| S6 | Pace-test in a copy of the place (`StampedeSpire.Sections.rbxl`), art hidden. |
| S7 | Start P1 now (real-phone test still before sections' final art). |
| S8 | **r3 biome sheets approved** (2026-10-29): `concepts/2026-10-29-r3biomes/r3-s{2,4,5,7,8,9}-*.png`, generated with gpt_image_2_5 from the r2 Crevasse + Aurora sheets as style refs. **5 species per new biome (30)**, as named on the sheets. Known fix at modelling time: the Frostdune Camel reads as 3 humps (should be 2). |
| S9 | **P3 (2026-10-29):** every run starts at the bottom (join, summit, reset). Checkpoints only light their node and count toward the best section. Coins save all the time (score x 0.01); summit = ascent (+100). Shop: wider ring, steady stance (rider gear later, needs art). Medals and the Herd Journal are deferred. The server caps score at distance x the best Score. |
| S10 | **P4 decisions (2026-10-29):** Aurora Dragon Weight 0.12 -> **0.05**. r3 sections 2/4/5/7/8/9 stay commons-only; their big-rare + flyer come with M9 r3 sheets. Shop prices + CoinPerScore stay placeholders, tuned by feel in P4. **Section medals and the Herd Journal are built in P4.** |
| S11 | **Streaming (STREAMING-PLAN Q1-Q8):** one private, unlisted publish allowed for M7 + a SLIM trial (owner clicks publish). Z origin shift at P5: yes. Stream-lag pause: custom loading card. 512-stud Atomic tiles. Server rider feed (4 Hz + focus part + `prepare(d)`) **before M7**. Greybox stays Persistent and frozen. S9 clouds decided at S9 art time. Target radius raised only if M7 memory allows. |
| S13 | **P4 (2026-10-30):** readable = **>= 4 px tall and >= 5% contrast** on the 750x401 phone; fog re-measure (real models) gives `Pool.Readable` 700,600,600,600,550,550,550,550,450,500, so respawns ahead stay at **ViewDist 350** and **fade in (and out) over `FarFade` 2 s** (owner chose the slow far fade over thicker fog or a bigger herd; BOT counts fast pops inside Readable). **Pool.Ahead 700 -> 500** (-> 420 after the re-review's leaving fix, same lever). **10d live cap = quota + 25** (was + 15). **Medals by time:** GOLD <= 30 s, SILVER <= 40 s, BRONZE = finished; **pips in the section's TitleColor, no new colours.** **Herd Journal:** one page per section, species + swatch + ridden count, ??? if never ridden, best time + medal. **In-range glow** (Highlight + PointLight) replaces the gold outline, in the section Accent; **s8 uses its TitleColor** (#C3EBFD). **Pace:** Herd s5-s10 -> 6,6,6,6,5,5. **Shop prices x2** (6,620 in all). |
| S12 | **r3 species (SPECIES-BRIEF-r3 Q1-Q7):** creature glows (Neon from sheet colours) **and** creature FX emitters (S5 steam, S7 crackle) allowed. Keep the `spd` spread. Bulky species scaled down at import to fit lanes. Sampling pass OK (tokens PROPOSED). Nimbus Ostrich = biped run cycle, no glide. |

## 1. Design in time, not studs
Each section has a target ride time (40 s at a tier-1 mount) and its length is `Speed x Time`. Speed per section is `22 x (78/22)^((k-1)/9)`.

| # | Biome | Status | Time | Speed | Length | Slope | Lane |
|---|---|---|---|---|---|---|---|
| 1 | Frozen Taiga Foothills | signed off | 40 s | 22.0 | 880 | 9 | 12 |
| 2 | Rime Fog Forest | new | 40 s | 25.3 | 1,010 | 10 | 11.5 |
| 3 | Crevasse Ice Canyons | signed off | 40 s | 29.1 | 1,170 | 11 | 11 |
| 4 | Ice Cave Labyrinth | new | 40 s | 33.5 | 1,340 | 13 | 10 |
| 5 | Hot Spring Terraces | new | 40 s | 38.6 | 1,540 | 14 | 9.5 |
| 6 | Geothermal Obsidian Ridge | signed off | 40 s | 44.4 | 1,780 | 15 | 8.5 |
| 7 | Storm Peaks | new | 40 s | 51.2 | 2,050 | 16 | 8 |
| 8 | Wind-Carved Spires | new | 40 s | 58.9 | 2,360 | 17 | 7.5 |
| 9 | Cloud Sea Ridge | new | 40 s | 67.8 | 2,710 | 19 | 7 |
| 10 | Aurora Crown | signed off | 40 s | 78.0 | 3,120 | 20 | 6.5 |

Total 17,960 studs, 400 s (6.7 min) at tier 1. Rise about 4,900 studs (today ~1,000): check lighting, fog and camera far range at that height. Slope and lane columns are carried from rev 1 and get tuned by feel in P4.

## 2. Data model (SS_Config)
- With one biome per section, **`Zones` simply grows to 10 entries** and keeps holding the look fields; `Env[k]` and `Species[k]` stay indexed by zone. No `Biomes` table and no call-site rewrite (rev 1's ~50 sites). New fields per zone: `Speed`, `Time` (target), `Rare` (spawn odds multiplier), `Checkpoint = true`.
- **Speed:** drop `BaseSpeed` / `SpeedPerStud`. `P.speedAt(d) = lerp(prev.Speed, zone.Speed, smooth((d - start) / SpeedRamp))`. Creature tiers (`spd`) still multiply on top.
- **Bends** (6, M5 +-10 deg heading; positions scaled to 17,960): `{ At = 1700, Len = 900, Deg = 8 }, { 4400, 1100, -16 }, { 7100, 1100, 14 }, { 10000, 1100, -14 }, { 12700, 1100, 14 }, { 15500, 1000, -6 }`.
- **Title cards:** a biome card at each section start ("SECTION 4 / 10" line under the biome name). The timeline already marks each zone with a node.
- **New-biome looks** (`Zones`, `Env`, `Species` entries for 2, 4, 5, 7, 8, 9) come only from their approved sheets via `art/LOOKDEV.md`. Until a sheet is approved its section is greybox-only and is not built.

## 3. Herd becomes a rider-relative pool
Each biome owns a pool of about 25 creatures that is active only while the window around the rider (150 behind, 700 ahead) overlaps that biome. A creature that falls out of the window respawns ahead, out of view, in a free slot (LaneGap kept), with species and rarity from `Weight` x the section's `Rare`. At most 2 biomes are active, so about 50 creatures.

## 4. Art, streaming, phone
- The existing mountain is built for the old 4 x 1,000 path and will not line up. **Do not touch the signed-off place.** Pace-test in the copy with the art hidden and `ShowGreybox` on.
- 6 new biomes need: a sheet (S5), LOOKDEV tokens, terrain + props + backdrop meshes, and **5 herd species each = 30 new species** on top of D2's 20 (scope flag for M8).
- `SS_Mountain` is Persistent today. That cannot hold 18k studs: track and terrain must stream normally. **Run the real-phone test (M7) before building the final art.**

## 5. Phases (each ends with BOT green and `src/` == Studio)
| Phase | Work | New BOT checks |
|---|---|---|
| P0 (done, BOT 20/20) | Timeline HUD: `SS_Timeline`, `Ui.Timeline` | UI layout with the strip; marker, lit nodes, mount icon |
| S (done) | 6 biome sheets (r2 style), owner approval, LOOKDEV tokens | none |
| P1 (done 2026-10-29, BOT 27/27, Sections SHA ba061e88…) | 10 `Zones`, speed model, bends, section cards, pace-test copy | zone count 10; per-zone `Length / Speed` within 10% of `Time`; speed rises every zone; lane table; carry-on across all 9 borders |
| P2 (done 2026-10-29, BOT 30/30, Sections SHA fa1b57eb…) | Herd pool (overlap quotas, drift-based respawn bands, prebuilt parked pools) | active count <= cap; no recycle in view; gap held; species match biome |
| P2b (done 2026-10-29, BOT 36/37 then 10d limit recalibrated, Sections SHA 1f02a101…) | Herd-sim fixes: yield, stragglers tire to 0.3x, RecycleClear 60, FrontBand 400, per-section Herd 8..4, swap-target clamp, start at d 5-30 | continuous ride across 2 borders (10d); remount <= 15 s |
| P3 (done 2026-10-29, BOT 36/36, Sections SHA a16bd69a…) | Checkpoints as progress markers, coins + ascent, upgrade shop, server DataStore (memory fallback), distance/score validation | self-test 9/9; live reports; shop; save / load round trip; teleports uncredited; shop UI layout |
| P4 (in progress 2026-10-30; BOT 40/40 at Sections SHA c942e383…) | Fog re-measure + far fade, pace (upper herd), medals + Herd Journal, server rider feed, shop prices; then M7 phone test (`M7-CHECKLIST.md`) | 10d fast pops; S1 / S3 rider feed; medals + journal self-tests; journal UI; perf per section (M7) |
| P5 | Art per biome, streaming change, sign-off per biome | placement error 0.001, clearance, prop grounding |
| P6 | M9 rarities / mythics; M10 wind | as in FINISH-PLAN |

## 6. Grind loop (details in P3)
Checkpoint at each section end, restart from the furthest. `stats.score` -> coins, spent on swap-ring size, stance wobble, and rider gear. Herd Journal gated by section. Summit reset becomes an ascent (coin bonus, harder variant). Section medals by time and score.

## 7. Risks
- Two sessions share one Studio: serialize runs.
- Tier-1 time is a baseline; slow mounts make sections ~33% longer, fast flyers ~40% shorter.
- 30 new species is a large addition to M8.
- No server-side persistence or anti-exploit exists yet; score is client-side (`SS_Ride`).
