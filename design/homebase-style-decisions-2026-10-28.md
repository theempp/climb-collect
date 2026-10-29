# Home-base world style: owner decisions (2026-10-28)

Source: interview popups, 2026-10-28. Colour values are from `climb&collect/design/hud-glassbloom-intel.md` §1 only. Nothing here is built. Branch `codex/homebase-c`.

## Decisions (LOCKED by owner)
| # | Topic | Decision |
|---|---|---|
| 1 | World style | **Candy-glass world**: HUD look made solid (violet/pink/mint accents, glossy rounded bodies, glowing trims). Alpine stone/cedar/brass/teal family is retired for restyled parts. |
| 2 | Proportions | Chunky and rounded: fat volumes, big soft bevels, oversized doors/windows, thick roofs. |
| 3 | Outlines / lip | **None.** No ink outline, no lip plinth, no inverted hulls. Colour and gloss only. |
| 4 | Materials | SmoothPlastic bodies; Neon trims/windows/crests; Glass (T.25) on few accents. No textured materials. |
| 5 | Home silhouette | Fat gabled cottage: wide rounded body, huge soft overhanging roof, big arched door, round porthole windows, chimney with glow gem. |
| 6 | Tiers | **A different house model per tier**, colour ladder from rarity (intel §1b): T1 blue #6C8CF0, T2 gold #F7A21B, T3 violet #B06CF0, T4 prismatic #FFB8EA. |
| 7 | Tier names | Renamed to the ladder: Hut, Cottage, Manor, Palace (final wording drafted for owner OK). Replaces Dry-stone Yard / Cedar Cloister / Brass & Lantern / Azure Terrace. |
| 8 | Rank flair | Banner by the door plus a ground **aura ring** in the rank colour. |
| 9 | Aura ring gameplay | **Coin multiplier by rank, built now** (owner). Needs economy numbers, balance pass and a STOP with the owner before any code; interacts with tier (rank AND coins) and secure XP. |
| 10 | Plot balance | Compact showpiece: house about 1/5 of the 80x100 plot at the back, big front yard for 6 habitats and 14 decor slots. |
| 11 | Gate | Giant rounded arch (about 2x today's height) with a floating crest gem, flanking round lantern pillars, glass name pill. |
| 12 | Gate motion | Idle gem bob/spin + 3 sparkles (pink #F78AD0, flare #7BD8FF). On arrival with secured creatures: mint #7BFFD0 pillar flash and sparkle burst, in sync with the rank arrival pop-up. |
| 13 | Ground / path | Mint lawn #2FAE8A (light patches #7BFFD0); glossy rounded lilac pavers #CBBCF2 with pink #F46BC4 centre inlay; kerb #5A2299. Owner added: **glow/lighting on the walkway so it stands out.** The lawn green is the HUD's only green ramp (owner accepted my pick). |
| 14 | Lights / signs | Candy globe lamps (thick violet pole, glowing globe, warm #FFDD9B or pink tint) and Glassbloom pill signs (night2 #14063C, white text, pk stroke). |
| 15 | Fast travel | **Rideable mount/hoverboard** wanted. Owner then chose it as a **separate feature**; this pass only reserves wide paths and speed-lane room and styles the mount in the same look when built. |
| 16 | Plants | Lollipop/swirl-style trees, **plus many more types of trees, plants and decorations throughout**: variety with one consistent look. Needs a flora list in the atlas pass. |
| 17 | Pens / props | Rounded pastel fences on round posts, glass pill sign per habitat, soft tint floor per habitat; coin props chunky gold #FFD84A with gold glow and floating price pill. |
| 18 | Ambience | Light and nearby only: gate gem, globes, own crest gem and a few sparkles near the player; other plots static unless close. Honours Reduce effects / LOW gates and the Motion caps. |
| 19 | Commons | One chunky landmark per plaza: rounded glass-panel board on a thick post; tiered round streak shrine with flame gem; round pool with gem fountain (flare #7BD8FF tint); round lilac plazas with pink inlay ring. |
| 20 | Perf | Today's budget +25%: per plot up to 1.25x today's parts (lodge 128, plot about 175 at runtime). Gate and commons landmarks may spend more. Neon instead of PointLights (max 1 light per house). Far plots drop decorative motion. Median 60 FPS on the phone target. |
| 21 | Scope | **Home base + mountain**, home base first. Mountain = camps, signs, lamps, route props and gate dressing only. Terrain, routes, traversal and collision untouched. Lake world later. |

## Risks and conflicts to settle at the STOP
- **#9 vs economy:** a rank coin multiplier changes balance, monetisation and the secure-XP grind the owner wants. Numbers must be PROPOSED, simulated and approved before code. Must be server-authoritative.
- **#6 vs perf:** four distinct house models cost art time; only the current tier's house exists per plot, so runtime cost is unchanged.
- **#3 vs HUD:** the HUD uses ink outline + crescent lip; the world will not. Accepted by owner.
- **#13:** glow on a lit path across 8 plots: use Neon strips, not lights.
- **Previous intel A6/A1 alpine tier roles are superseded** by #6/#7; `HomeTiers` role names (`azureWater` etc.) need migrating.
- **#21:** mountain props touch the approved MountainQuality world; needs its own atlas pass and a before/after capture check.
- Existing `HomeCommons` v2 is grey-box; restyle replaces its parts, not its layout.

## Open (ask the owner at the STOP)
Final tier names; exact flora/decor list; aura multiplier numbers; whether the speed-lane strips are wanted before the mount exists.

## S0 answers (owner popups, 2026-10-28/29) — close F1-F9
| # | Item | Answer |
|---|---|---|
| S0.1 | Rank colour (F1) | 4 bands: L<5 blue #6C8CF0, 5-14 gold #F7A21B, 15-29 violet #B06CF0, 30+ prism #FFB8EA |
| S0.2 | Gate height (F3) | about 1.4x today, ~100 studs |
| S0.3 | House footprint (F4) | 12-13 % (35x35 slot); tiers grow upward |
| S0.4 | Perf (F5) | per plot 750 x 1.25 = ~937 parts |
| S0.5 | Plaza (F6) | lilac disc (d <= 54) + pink Neon inlay ring inside the paved square; whole square lilac #CBBCF2; layout unchanged |
| S0.6 | Pen fences (F7) | HUD pastel set, one per habitat: #FFD0F0, #CBBCF2, #9FB6FF, #FFD27A, #C99BFF, #7BFFD0 |
| S0.7 | Habitat sign (F9) | night pill billboard + Glass T.25 #8246DC plaque on a post |
| S0.8 | Tier names (F2) | **Hut, Villa, Manor, Palace** |
| S0.9 | Path glow (F8) | **flare #7BD8FF** Neon strip (inlay stays pink #F46BC4) |
| S0.10 | Speed lanes (F8) | **build strips now** (decorative until the mount ships) |
| S0.11 | Door | deep #2B1457 in a #FFD2FF arch |
| S0.12 | Roof | tier gradient bottom stop (T1 #5B78E8, T2 #F0952A, T3 #8A4BE6), ridge = top stop; T4 cycles 4 prism bands |

## S1 STOP (owner, 2026-10-29): approved
S1 plan `design/homebase-style-s1-plan-2026-10-29.md` + atlas pass 3 approved. Decor display names: Candy boulder, Bloom bed, Puff hedge, Globe lamp, Cloud tree, Gem basin (ids unchanged). Max 6 creatures shown on decor stands per plot. Gate: the two lantern globes share one pulse loop (6 loops = idle cap). Flare split: plan §5 positions + atlas B9 dash pitch.
