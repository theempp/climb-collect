# r3 species brief: 30 herd species for sections 2, 4, 5, 7, 8, 9 (2026-10-29)

Planning brief for M8-r3. Nothing has been built yet. Read-only inputs: the r3 sheets (S2–S9, `concepts/2026-10-29-r3biomes/`), `art/LOOKDEV.md` (r3 sections), `art/palette_r3.json`, `SS_Config.Species[2,4,5,7,8,9]`, `SECTIONS-PLAN.md` S8, `FINISH-PLAN.md` D9/M7/M8, `PERF-BUDGET.md`, `art/creatures/README.md` + `STYLE-STUDY.md` + `renders/`.

## Conventions
- **Panel:** each sheet has 5 species panels left to right. In original 2688×1520 pixels, panel x0 = 0 / 540 / 1080 / 1610 / 2140 (LOOKDEV bg-mask rule), the figure is at y ≈ 380–900 and the name/speed label at y ≈ 940–1020.
- **Height (A):** the creature's back or top height in avatar heights (1 A = 1.98 m, README). These are eyeballed off the downscaled sheet, so treat them as ±0.2 A. Re-measure them in the `SPECIES` table of `build_creatures.py`. Antler, horn and head tops are given separately.
- **Config role:** `SS_Config` currently sets only `Speed`. None of the 30 species set `Weight`, `Score`, `Big`, `Rare` or `Fly`, so all of them default to **common, Weight 1, Score 1**. The role column below reads that default plus the `spd` tier: fast ≥1.2, slow ≤0.85, otherwise std.
- **Base:** every built creature shares one bone layout (`Rig`, 22 bones: root, hips, spine, chest, neck, head, tail_1–2, 4 legs × upper/lower/foot, ear_l/r; README). "Base" names the built species whose **block template and proportions** to start from. "+bone" means an added bone on that same layout, not a new rig.
- **Palette:** only tokens already in LOOKDEV/`palette_r3.json` are used. Every other part colour is **TBD — needs sheet sample**: sample it on that species' panel with the `sample_creatures.py` method (box, percentile, bg-mask), then add it to LOOKDEV as PROPOSED. The coat ramp (`*_shadow` / `*_light`) for each species = p15 / p85 of the same box its body token used (README method). This is listed once here and not repeated in every row.
- **Widths:** no r3 sheet has a front view. Use the RR ratios (chest 0.82 × torso depth, head 0.88 × head depth, legs 0.47 × chest width), with the same "weakest trace" caveat as zone 1.
- **Budget (provisional, M7 phone test still open):** ≤3,000 tris and ≤24 bones per creature, one skinned MeshPart (far below the 10k-per-MeshPart cap). The tri numbers below are targets. The fallback, if the phone fails, is 2k (PERF-BUDGET).
- **Clips (D9):** gallop 0–24, idle 0–60, swap_jump 0–20, faceplant 0–48 at 30 fps, the same as zone 1, unless a row says otherwise. **No r3 species is a flyer** (no wings on any sheet, no `Fly` in config), so no glide or flap clips are needed.

## S2 Rime Fog Forest (sheet label: every species "SPEED: SLOW")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys (sheet) | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| Rime Stag | 1 (x 0–540) · back 1.8 A, antlers to 3.2 A | common std · 1.0 · 1 | large cervid → **taiga_elk** | very tall many-tined antlers with icicle drips, slender legs, frosted shaggy flank, short tail | body s2.stag #8D8C91; antler s2.stag_antler #E4F1FA (LOOKDEV S2) | 2,950 / 22 | Antlers are wider and taller than the elk's: watch the tri count and lane clearance (lane 11.5). Icicles go as hanging square locks. Hoof, eye: TBD. |
| Mistwool Llama | 2 (540–1080) · back 1.6 A, head 2.6 A | common std · 0.9 · 1 | long-neck camelid → **woolly_reindeer** +neck_2 | long upright neck, tall banana ears, shaggy wool body and legs, short tail | body s2.llama #A5AABE | 2,800 / 23 | Upright neck: the rider's view and the head clear the seat. Wool as offset lock blocks. Muzzle, hoof: TBD. |
| Hoarfrost Wolf | 3 (1080–1610) · back 2.1 A | common std · 1.15 · 1 | large canid → **snowshoe_hare_hound** | heavy ruffed neck, pointed ears, long muzzle, bushy low tail, paws | body s2.wolf #9096A6 | 2,800 / 22 | Hare ears → short pointed ears. Paw claws: TBD (hare.claw is Z1-only). Drop the hare's saddle (no tack on any r3 sheet). |
| Birchback Bison | 4 (1610–2140) · hump 2.4 A | common slow · 0.75 · 1 | heavy bovid → **musk_ox_calfrunner** | high shoulder hump, birch-bark white/dark striped mane, short curved horns, beard, thin rear | body s2.bison #878894; horn s2.bison_horn #827878 | 3,000 / 20–22 | Bark stripes need two TBD samples (pale and dark stripe). Hump plus stripe blocks is the S2 tri risk. Ears are visible on the sheet: add ear_l/r (22). |
| Fogtail Fox | 5 (2140–2688) · back 1.6 A | fast · 1.3 · 1 | small canid → **snowshoe_hare_hound** +tail_3 | oversized plume tail (≈ body length) arching up, big ears, slim legs | body s2.fox #ABB1C7 | 2,700 / 23 | Tail is the silhouette: it needs a 3rd tail bone and must not hide the rider. The tail's lilac tint: TBD. |

## S4 Ice Cave Labyrinth (sheet label: every species "SPEED: MEDIUM")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| Lumen Elk | 1 · back 2.0 A, antlers 3.1 A | common std · 1.05 · 1 | large cervid → **taiga_elk** | glowing cyan antlers, glowing eyes, mottled coat, fringe on legs and belly, short tail | body s4.elk #6CA5C5; antler s4.elk_antler #40D6FA | 2,950 / 22 | **Glow:** LOOKDEV's material rules cover only zones 1–4, so a creature Neon/emissive part is an owner decision. Eye glow colour: TBD. |
| Cave Frost Bear | 2 · back 2.2 A | common slow · 0.8 · 1 | ursid → **musk_ox_calfrunner** body + **snowshoe_hare_hound** paws | massive hunched shoulders, ice-shard spikes on the back, small round ears, short snout, plantigrade paws | body s4.bear #416D9C | 3,000 / 22 | No hooves: use hare paw blocks with claws (claw colour TBD). Ice shards: reuse s4.armadillo_shards? It's a different box, so it needs its own TBD sample. |
| Shardback Armadillo | 3 · top 2.1 A (shards), body ≈1.7 A | common slow · 0.75 · 1 | low armoured → **pine_boar** | dome of large crystal shards, long pointed snout, small ears, short legs with claws, tail | body s4.armadillo #2F5177; shards s4.armadillo_shards #71C3FC | 3,000 / 22 | The shard dome is the tri hog (budget ~1.2k for shards). The seat sits on the shards: a flat seat block is needed (no tack on the sheet, so its colour is TBD). |
| Glowtail Lynx | 4 · back 1.6 A | fast · 1.4 · 1 | felid → **snowshoe_hare_hound** | tall tufted ears (glowing tips), spotted coat, glowing curled tail, big paws | body s4.lynx #5886AC; tail s4.lynx_tail #68EFFC | 2,700 / 22 | Spots as small flat blocks (TBD sample). Glow is the same owner question as the Lumen Elk. |
| Drip-Ice Tapir | 5 · back 2.0 A | common std · 0.95 · 1 | tapir → **pine_boar** | long drooping proboscis snout, icicle fringe hanging along the back and flanks, rounded rump, small ears | body s4.tapir #466E96; fringe s4.tapir_fringe #A5E3FB | 2,900 / 22 | The fringe is hanging lock blocks (like the ox skirt). No tusks. |

## S5 Hot Spring Terraces (sheet label: every species "SPEED: MEDIUM")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| Steam Buffalo | 1 · back 2.3 A | common slow · 0.8 · 1 | heavy bovid → **musk_ox_calfrunner** | wide swept-back curved horns, deep chest, wet shaggy coat, steam off the back | body s5.buffalo #877970; horn s5.buffalo_horn #D7BEA8 | 2,950 / 22 | Horn span ≈ 1.6 × head width: check lane clearance at lane 9.5. **Steam is FX, not mesh** (colour s5.steam #D5D1D1 exists, but the emitter on a creature is an owner decision). |
| Onsen Capybara | 2 · back 2.0 A | common slow · 0.85 · 1 | barrel rodent → **pine_boar** | blunt square head, small round ears, no visible tail, short legs, loaf body | body s5.capybara #907160 | 2,500 / 20 | Drop tail_1–2 (20 bones). Snout without tusks. The lighter belly and legs: TBD. |
| Geyser Goat | 3 · back 1.5 A, horns 2.4 A | fast · 1.2 · 1 | caprid → **woolly_reindeer** | big ridged curling horns with mineral crust, beard, long shaggy coat, short tail | body s5.goat #B6ABA0; horn s5.goat_horn #D6924A | 2,800 / 22 | Horns as stepped blocks (the ram-curl budget is ~500 tris). Yellow mineral stains on the coat: TBD. |
| Travertine Antelope | 4 · back 1.6 A, horns 2.3 A | fast · 1.4 · 1 | slim antelope → **woolly_reindeer** | long ringed lyre horns, long slender legs, cream coat with orange bands, tufted tail | body s5.antelope #C4AC95; horn s5.antelope_horn #AC9A90 | 2,700 / 22 | Bands as alternating blocks; the band colour is TBD (travertine_mineral #BC9068 is a terrain token and must not be reused without an owner OK). |
| Sulfur Boar | 5 · back 2.0 A | common slow · 0.85 · 1 | suid → **pine_boar** (direct) | bristle crest with yellow sulfur staining, curved tusks, pig snout, thin tail | body s5.boar #C9A06E | 2,800 / 22 | Closest reuse of all 30. Tusk, snout and sulfur-yellow: TBD (Z1 boar tokens may not be reused). |

## S7 Storm Peaks (sheet label: every species "SPEED: FAST")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| Thunder Yak | 1 · back 2.5 A | common slow · 0.8 · 1 | heavy bovid → **musk_ox_calfrunner** | very long skirt coat, forward-curving pale horns, violet lightning streaks in the fur | body s7.yak #3E477F; horn s7.yak_horn #C6D7F9 | 3,000 / 20 | Lightning arcs: as violet blocks, s7.lightning_glow #C1BAFB is a sky token, so it needs an owner OK or a TBD sample. Lane 8: bulk. |
| Stormmane Stallion | 2 · back 1.7 A, head 2.6 A | common std · 1.15 · 1 | equid → **taiga_elk** body, +neck_2 | long flowing violet-streaked mane and tail, arched neck, dappled coat, hooves | body s7.stallion #757C99 | 2,850 / 23 | No antlers. The mane goes as stepped lock blocks on the neck bones. The mane colour is TBD. |
| Stormcrest Gazelle | 3 · back 1.6 A, horns 2.6 A | fast · 1.4 · 1 | slim antelope → **woolly_reindeer** | tall zig-zag "lightning" horns, slender legs, mottled coat, small tail | body s7.gazelle #98A4D0; horn s7.gazelle_horn #978CF8 | 2,700 / 22 | Zig-zag horns are a good fit for stepped blocks. |
| Rumble Rhino | 4 · back 2.2 A | common slow · 0.75 · 1 | rhino → **musk_ox_calfrunner** | slate armour plates, big front horn plus a small second horn (violet), small ears, heavy legs | body s7.rhino #475C87; horn s7.rhino_horn #9A92F9 | 2,950 / 22 | Plates as layered slabs (the shading reads in-style). Remove the ox skirt and boss. Faceplant: the horn clips the snow, which is fine. |
| Static Wolf | 5 · back 1.9 A | common std · 1.1 · 1 | canid → **snowshoe_hare_hound** | violet-charged ruff and back spikes, pointed ears, long tail | body s7.wolf #6877B6 | 2,800 / 22 | Share the mesh template with the Hoarfrost Wolf (S2), recoloured, with different fur-spike blocks. |

## S8 Wind-Carved Spires (sheet label: every species "SPEED: FAST")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| Windrunner Pronghorn | 1 · back 1.8 A, horns 3.0 A | fast · 1.4 · 1 | slim antelope → **woolly_reindeer** | black hooked prongs, white throat bands, white belly and rump, tan back | body s8.pronghorn #B88A6C; horn s8.pronghorn_horn #333436 | 2,700 / 22 | The white markings are the identity: TBD sample. The body token is a "warm median", not a percentile, so its ramp method differs (flag at sign-off). |
| Spire Markhor | 2 · back 1.9 A, horns 3.0 A | common std · 0.95 · 1 | caprid → **woolly_reindeer** | tall corkscrew horns, long shaggy neck beard and skirt, short tail | body s8.markhor #948B8D; horn s8.markhor_horn #504C4D | 2,900 / 22 | Corkscrew horns as stepped twisted blocks (~600 tris). |
| **Frostdune Camel** | 3 · humps 2.3 A, head 2.5 A | common slow · 0.75 · 1 | camelid → **taiga_elk** body, +neck_2 | **2 humps (owner fix)**, curved long neck, thick shaggy fur on the humps, neck and legs, short tail | body s8.camel #A28574 | 2,900 / 23 | **The sheet reads as 3 humps** (fore hump, rear hump, and the shaggy neck ruff at the shoulder). Build exactly **2** hump stacks (over the chest and spine bones), and move the shoulder shag down onto the throat as hanging locks so it can't read as a third hump. The caption says "twin humps", so the fix is traceable. The seat sits between the humps. |
| Gale Snow Leopard | 4 · back 1.9 A | common std (fast) · 1.2 · 1 | felid → **snowshoe_hare_hound** +tail_3 | rosette spots, very long thick curled tail, big paws, small round ears | body s8.leopard #9FAFC1 | 2,850 / 23 | The rosettes need a dark spot sample (TBD). Share the felid template with the Glowtail Lynx. |
| Spirehorn Oryx | 5 · back 1.7 A, horns 3.3 A | common std · 0.95 · 1 | antelope → **woolly_reindeer** | very long straight ringed horns, black face mask and leg/flank stripes, tufted tail | body s8.oryx #9D8B86; horn s8.oryx_horn #1E1E22 | 2,750 / 22 | Tallest horns of all 30: they stay inside the swap_jump and faceplant arcs and must not clip the rider camera. Mask and stripes: TBD. |

## S9 Cloud Sea Ridge (sheet label: every species "SPEED: VERY FAST")
| Species | Panel / ht | Role · spd · Score | Archetype → base | Silhouette keys | Palette refs | Tris / bones | Gotchas |
|---|---|---|---|---|---|---|---|
| **Nimbus Ostrich** | 1 · back 1.8 A, head 2.6 A | fast · 1.35 · 1 | **biped bird → NEW rig** | cloud-plume body and tail, long bare neck, small head and beak, 2 long legs with 2-toe feet, crest plume | body s9.ostrich #DFE0E8 | 2,800 / ~19 (root, hips, spine, chest, neck_1–3, head, tail, 2 × thigh/shin/tarsus/foot, wing_l/r stubs) | **Not a flyer:** the caption says "glide over snowy ridges", but there are no wings and no `Fly`. The gallop becomes a 2-leg run cycle, and all 4 clips must be authored fresh. The bare legs and beak are TBD. |
| Cloudmane Horse | 2 · back 1.9 A, head 2.7 A | common std · 1.0 · 1 | equid → **taiga_elk** +neck_2 | cloud-puff mane and tail, white coat, hooves | body s9.horse #C8CAD0 | 2,850 / 23 | Share the equid template with the Stormmane Stallion. Cloud puffs as clustered blocks. |
| Halo Deer | 3 · back 1.6 A, antlers 2.7 A | common std · 1.05 · 1 | cervid → **taiga_elk** (smaller) | golden glowing crown antlers, slim body, feathery mane, short tail | body s9.deer #DED6C7; antler s9.deer_antler #F5CE96 | 2,850 / 22 | Glow is the same owner question as S4. Its speed-label icon is a gauge, not a bolt like the other four (sheet quirk, ignore). |
| Skyfleece Sheep | 4 · top 2.3 A | common slow · 0.75 · 1 | woolly bovid → **musk_ox_calfrunner** | huge round cloud fleece hiding the legs, curled ram horns, small face | body s9.sheep #B8CDE9; horn s9.sheep_horn #7998BA | 3,000 / 22 | The fleece swallows the upper legs: rigid skin the fleece to the spine and chest so the gallop doesn't shear it. The widest S9 body against the narrowest lane so far (7). |
| Mistwing Kudu | 5 · back 1.7 A, horns 3.3 A | fast-ish · 1.15 · 1 | antelope → **woolly_reindeer** | long spiral horns, white side stripes, airy mane and tail wisps | body s9.kudu #B0B9D1; horn s9.kudu_horn #A38C7F | 2,800 / 22 | Despite the name, **no wings** on the sheet: not a flyer. Stripes: TBD. |

## Sheet vs config: cross-cutting mismatches
1. **Speed labels:** every sheet gives one label for all 5 species (S2 SLOW, S4/S5 MEDIUM, S7/S8 FAST, S9 VERY FAST). These track the section speed ramp (`Zones[k].Speed`), not per-species tiers. The config `spd` spread (0.75–1.4) is a judgement value (the config comment says so). The sheet supports neither the spread nor equal tiers.
2. **No big-rare or flyer per section:** the old zones each carry a Big+Rare (Score 3) and a `Fly` species; the 6 r3 sections have none, and the sheets show none. No rarity role can be traced for the r3 species.
3. **Scale:** r3 animals are drawn larger against the avatar than the Z1 ones (Z1 elk overall ≈ 2.1 A; the Rime Stag's antlers reach ≈ 3.2 A). Lanes narrow 11.5 → 7 across S2 → S9, so the bulky species (bison, bear, buffalo, yak, rhino, sheep) may overlap neighbouring lanes. Config `Size` is a placeholder (the mesh replaces it), so set the import scale per species at M8.
4. **No tack:** no saddle or reins on any r3 creature, so the rider seat has no traceable part colour (the hare-hound saddle is a Z1 token).
5. **Emissive parts and FX on the sheets** (S4 glows, S5 steam, S7 lightning fur, S9 halo antlers): LOOKDEV's material rules cover zones 1–4 only.
6. **Missing tokens:** each species has one body token, plus one horn/antler/accent token for 18 of the 30. Every ramp, hoof, eye, glint, muzzle and marking is TBD. Eyes and glints must be resampled per sheet (the Z1 eye tokens don't transfer).

## Rig-reuse summary
| Base | Species (count) | Bone changes |
|---|---|---|
| taiga_elk | Rime Stag, Lumen Elk, Halo Deer, Stormmane Stallion, Cloudmane Horse, Frostdune Camel (6) | +neck_2 for the horses and the camel (23) |
| woolly_reindeer | Mistwool Llama, Geyser Goat, Travertine Antelope, Stormcrest Gazelle, Windrunner Pronghorn, Spire Markhor, Spirehorn Oryx, Mistwing Kudu (8) | +neck_2 for the llama |
| musk_ox_calfrunner | Birchback Bison, Cave Frost Bear, Steam Buffalo, Thunder Yak, Rumble Rhino, Skyfleece Sheep (6) | add ears where the sheet shows them; the bear takes hare paws |
| pine_boar | Shardback Armadillo, Drip-Ice Tapir, Onsen Capybara, Sulfur Boar (4) | the capybara drops the tail (20) |
| snowshoe_hare_hound | Hoarfrost Wolf, Fogtail Fox, Glowtail Lynx, Static Wolf, Gale Snow Leopard (5) | +tail_3 for the fox and the leopard |
| **NEW biped** | Nimbus Ostrich (1) | ~19 bones, new clip set |

**New rigs: 1** (biped ostrich). 29 of 30 reuse the shared 22-bone quadruped layout (±1–2 bones, all ≤24), so the existing 4 clips retarget by bone name. **Wing rigs needed: 0.**

## Suggested build order (grouped by base, cheapest first)
1. **pine_boar group:** Sulfur Boar (near-direct), then Capybara, Tapir, Armadillo (the shard budget test).
2. **snowshoe_hare_hound group:** the canid template (Hoarfrost Wolf → Static Wolf recolour), then the felid template (Lynx → Snow Leopard, +tail_3), then the Fox.
3. **woolly_reindeer group:** the antelope template (Gazelle → Antelope → Pronghorn → Oryx → Kudu), then the caprids (Goat, Markhor), then the Llama (+neck_2).
4. **taiga_elk group:** the cervids (Rime Stag, Lumen Elk, Halo Deer), then the equid template with +neck_2 (Stallion → Horse), then the **Camel** (2-hump fix, reuses the +neck_2 work).
5. **musk_ox group:** Bison, Buffalo, Yak, Sheep (fleece skin test), Rhino, then the Bear (mixed base).
6. **New biped:** Nimbus Ostrich, last (new rig and new clips).

Sign-off still goes per section (M8 rule), so batch the renders per section once each section's 5 are done. Sections finish in this order: S5 and S7 early, S9 last (ostrich).

## Open questions for the owner
**Answered 2026-10-29 (SECTIONS-PLAN S12):** glow yes and creature FX yes; keep the spd spread; scale bulky species down at import; sampling pass OK (PROPOSED); ostrich biped run cycle, no glide. Q3: commons only until the M9 sheets (S10).
1. **Creature glow/emissive** (Lumen Elk antlers and eyes, Lynx tail, Halo Deer antlers, Storm violet arcs): allow a Neon/emissive part on creatures, or flat colour only?
2. **Creature FX** (S5 steam plumes, S7 lightning crackle): add them as per-creature emitters, or leave them out?
3. **Big-rare and flyer roles for sections 2–9:** the r3 sheets have none. Keep the 5 commons only, or generate new sheet panels (D8 credit OK needed)?
4. **Speed tiers:** keep the judgement `spd` spread, or make all 5 per section equal, as the sheet labels read?
5. **Bulk vs lane width** in S7–S9 (lanes 8–7): scale the bulky species down at import, or accept lane overlap?
6. **Sampling pass:** OK to run a `sample_creatures.py`-style pass on the 6 r3 sheets to propose about 150 missing tokens (ramps, hooves, eyes, markings) as PROPOSED in LOOKDEV?
7. **Ostrich:** confirm it gets a biped rig and a run cycle (no glide clip), since its caption says "glide".
