# References intel (atlas, 2026-10-20)

Source of truth: `references/` only. Tags: **OBSERVED** = directly visible; **INFERRED** = my reading (reason given). Hex values are **eyeballed estimates from displayed pixels, not sampled** (I have no pixel-sampling tool; tolerance roughly +-15% per channel). Nothing here comes from other projects or from memory of any game. Videos have no audio; nothing audio-related is claimed. Frame ids: `fN` = Nth cell of the contact sheet, left-to-right, top-to-bottom, 1-based; time order = cell order.

## 0. File index

| File | Shows | Res (as returned by reader) | Read how / limits |
|---|---|---|---|
| `images/img1.jpg` [img1] | Avatar from behind on a knife-edge rock ridge, big peak ahead, light shafts. No UI | 1206x702, rounded-corner frame | Read directly. Low-res, soft/compressed |
| `images/img2.jpg` [img2] | Avatars on faceted boulder stack with two ladders, tan fog; full HUD, chat, leaderboard | 1206x677 | Read directly. HUD text tiny, partly illegible; chat is Spanish |
| `images/img3.jpg` [img3] | Tiny avatar on a narrow brown dirt path in a rock gully between mossy boulders. No UI | 1206x687 | Read directly. Avatar ~25 px tall, so scale estimates are coarse |
| `images/img4.jpg` [img4] | Avatar from behind on a metal ladder over snowy rock face; name tag | 1206x732 | Read directly |
| `images/img5.jpg` [img5] | Avatar sprawled (ragdoll pose) on a mossy log in a clear green pond, forest, stilt pavilion. No UI | 1206x690 | Read directly |
| `frames/new_v1.jpg` [new_v1] (src `new_v1_9-01-49PM.mov`, 10 s, 576x576, 1 fps) | Two-climber roped ascent on a steep snow/rock slope, top-down camera; caption "we must to reach the peak together" (f1-f6); handle `@boluukejuu` | sheet 1536x1152, 4x3, cells 384; f1-f10 used, f11-f12 empty | Contact sheet only, no enlargement |
| `frames/new_v2.jpg` [new_v2] (`new_v2_9-04-29PM.mov`, 18.8 s, 9:16, 1 frame/2 s) | Day/night/blizzard snow climbing with ice-axe HUD; `@untraden` | 1280x910, 5x2, cells 256x455; f1-f9 used, f10 empty | Contact sheet only. 2 s between frames hides transitions |
| `frames/new_v3.jpg` [new_v3] (`new_v3_9-18-52PM.mp4`, 19.3 s, 16:9, 1 frame/2 s) | Desktop-HUD snow ascent: slope, blizzard, tent, night, summit ridge; `@.k2triad` | 1536x648, 4x3, cells 384x216; f1-f8 gameplay, f9-f10 TikTok end cards | Contact sheet only; HUD numerals illegible at this size |
| `frames/old_a.jpg` [old_a] (65.9 s portrait, 1 frame/3 s) | Whole-journey montage with word-by-word captions; camp, glacier ladder, HUD, gear shop, quest NPC, game card; `@knowblox` | 1536x1820, 6x4; f1-f22 used | Contact sheet only. Captions are karaoke words, not sentences |
| `frames/old_b.jpg` [old_b] (36 s, 3:4) | Group ascent with ladder, ropes, then avatar lying on scree/snow; `@calviora.youtube` | 1024x1023, 4x3; f1-f11 used, f12 end card | Contact sheet only |
| `frames/old_c.jpg` [old_c] (36 s, 16:9) | Summit-dome ascent above a cloud sea, "SUMMIT REACHED" banner; `@pavv1o` | ~1536x642, 4x3; f1-f11, f12 end card | Contact sheet only; summit number read as "8611" low confidence |
| `frames/old_d.jpg` [old_d] (19 s portrait) | Whiteout, avatar on roped snow slope, caption "Dude fell so fast he damn near broke the sound barrier"; `@panzer_kampf_wagen02` | 1280x910, 5x2; f1-f8 used, f9-f10 end cards | Contact sheet only; letterboxed, very low contrast |
| `frames/old_e.jpg` [old_e] (50 s portrait) | Multi-rope summit approach, captions about a "polish route", summit banner; `@ostepopsmich` | 1536x1365, 6x3; f1-f15 used, f16-f17 end cards | Contact sheet only; letterboxed, tiny |

Raw videos in `references/videos/` were not opened: this run had no shell/ffmpeg tool, so **no enlarged frames were extracted**. Durations/aspect ratios above come from the caller's brief and are unverified. No file was unreadable at sheet level.

## 1. Trail network

**What the references show is route segments and cues, not a network. No map, split point, junction signage or loop is shown in any file.**

- **Camps as a linear ladder.** OBSERVED [img2]: a vertical altitude track at top-left, red flag at the top, tick labels read as "Campamento 4 / 3 / 2" top-to-bottom (tiny, low legibility), current marker "Alt: 1176m" near the bottom; tick spacing looks unequal (INFERRED from pixel positions). OBSERVED [old_a f5, f13]: small red floating labels above a distant peak (text illegible; INFERRED camp/objective labels). OBSERVED [old_e f10-12] caption: "The last camp is at 7000m so we had to rush up fast as we can from polish route camp 2"; [old_e f1-2] "polish route". INFERRED: the source game has named routes with their own camps; the geometry of how they split is **not observed**.
- **Several coloured ropes on one slope.** OBSERVED [old_e f5-f12]: red, blue and dark rope lines run up the same summit dome, appearing parallel and in f10-f12 converging near two avatars. [new_v3 f7]: two lines (red, dark blue/black) fall away down both sides of the summit ridge. [old_c f1-f6]: two to three dark lines up the dome. [old_b f3, f6]: a thin blue line along the ridge. INFERRED (not confirmed): colour = route, routes run alongside and merge toward the summit. Cannot see where they separate.
- **Rope as the guide line.** OBSERVED in [new_v1], [new_v2 f4-f5], [new_v3 f5], [old_b f5-f9], [old_d], [old_e]: a single thin fixed rope (orange/red) runs along the line of travel; climbers are strung along it single file ([new_v2 f5] 5-6 avatars in a diagonal line; [old_b f3] 4-5 in a line). The rope is the path marker; no cut trail is visible on snow except footprints ([new_v3 f8] faint tracks).
- **Ladders as links.** OBSERVED: vertical metal ladder bridging a groove in an ice wall [old_a f10]; ladder up a snow groove with a climber at the top [old_b f1]; two ladders (a plain one lower-left, a rope-ladder lower-right) meeting the same boulder block [img2]; ladder with rope rails descending over snowy rock [img4]; yellow rope-ladder/strip diagonal across a camp slope [old_a f19]. INFERRED: ladders are connectors between ledges/ground, not whole routes.
- **Camp/rest points.** OBSERVED: red tent, labelled "Equipment", with table [old_a f3]; night camp with several tents, a lamp on a pole, a lit orange crate/rack [old_a f17]; tent interior (yellow-green fabric, two orange bars) [new_v3 f4]; tents on slope in background [old_a f19]; quest NPC "[QUESTS] Daws Sherpa" with a delivery request "I need these oxygen bottles delivered to Camp 2, can you ..." and Accept / Not right now buttons [old_a f19]; "Refill" prompt on a cloth-like object [old_a f14]; gear shop with helmets priced in "Points" [old_a f18].
- **Objectives.** OBSERVED: summit banner "SUMMIT REACHED! 8611 METERS +110 POINTS!" [old_c f8-f9]; "You Have Reached The Summit"-style orange banner (small, partly legible) [old_e f12-f13]; "Summits" column on the leaderboard (all 0) [img2]; delivery quest [old_a f19]; summit flags (small coloured specks) [new_v3 f8], [old_c f11], [old_e f13].
- **Not shown anywhere:** route splits at a base, crossings at camps, two-way traffic, shortcuts, bridges between routes, trail signage, minimap. Do not read a network into the ropes.

## 2. Trail complexity (per file)

Avatar-width = torso/shoulder width of the avatar in the same image (estimates, +-30%).

| File | Width | Gradient | Features | Exposure / sightlines |
|---|---|---|---|---|
| [img1] | Walking top ~2 avatar-widths at the feet, narrowing ahead (est. from 155 px strip vs ~75 px shoulders) | Flat to gently rising crest, flanks near-vertical-looking (INFERRED from shading) | Knife ridge, a natural rock arch/notch ahead in the crest, snow in crevices, broken block steps at the foot of frame | Dark faces fall away both sides out of frame; big peak dead ahead on the line = strong sightline; layered far ridges |
| [img2] | Boulder top ~3-4 widths; ladders ~1 width | Stepped diagonal rise (faceted blocks), ladders steep (est. 60-75 deg) | 2 ladders to one block, faceted slab steps, climbers on both ladders | Fog hides the drop and far side (not observed); sightline only a few tens of studs-equivalent, fog-limited |
| [img3] | Path ~2-3 widths near camera, ~2 at far end (est.) | Gentle-to-moderate rise (INFERRED from foreshortening) | Narrow brown dirt strip in a cleft; upright slabs partly blocking the line ahead; no rope/rail | Enclosed: walls on both sides, **no drop beside the line**; sightline closed by slabs, small bright patch of sky at top |
| [img4] | Ladder ~1 width, rails + rungs | Steep, camera looks down the ladder (est. 60+ deg) | Metal ladder, a second long diagonal rail/ladder at left, orange rope arcs in foreground | Rock face and snow slabs; the ground far below is **not observed**; wind-sculpted snow lip at right |
| [img5] | Log ~1-1.5 widths | Flat | Fallen mossy log across water, boulder steps left, stilt pavilion right | Shallow clear water, no drop; wide sightline to a cabin in trees |
| [new_v1] | Rock rib the climbers stand on ~2 widths [f5-f6]; otherwise open slope with rope | Steep; top-down view hides angle (INFERRED 45+ deg from poses) | Fixed rope diagonal; black rock ribs in snow; pale turquoise patches [f5, f6] (crevasse or water, unclear) | Camera looks straight down; slope falls into white haze, huge pale wall texture at top [f1-f4]; strong exposure read |
| [new_v2] | Open slope, climbers spaced in line ~3-5 widths apart [f5] | Steep traverse [f4, f5] | Fixed rope diagonal, single-file climbers, narrow gully in red light [f6], whiteout wall [f7-f9] | Far mountain range visible [f4-f5]; fog/night remove sightline [f2, f6, f7-f9] |
| [new_v3] | Open slope; rope vertical in a lane at right [f5] | Steep [f1, f2, f5] | Rope, dark diagonal rock ribs [f1-f2], tent camp [f4], rounded summit ridge with two ropes [f7] | Top-down view [f5] shows grey rock and snow far below; cloud sea at summit [f7] |
| [old_a] | Open snow/scree; ladder ~1 width [f10] | Steep snow [f8], ice wall [f10] | Moraine plain with big pyramid peak ahead [f4]; crevasse/ice wall with ladder [f10]; glacier with snow flurry [f6, f7, f11]; dark rock ridge with rope [f9] | Peak visible from the plain [f4-f5, f13]; ladder dead-ends in white sky/blur [f10] |
| [old_b] | Open slopes; party of 3 abreast on the ridge [f6] | Steep face with rope [f5, f7-f9] | Ladder in snow groove [f1]; scree with snow patches [f2-f3]; ridge to blue sky [f6] | Camera above looking down at steep faces [f4, f7, f8]; avatar lying in scree [f10-f11] |
| [old_c] | Rounded dome, several widths wide | Moderate-to-steep rounded slope | 2-3 dark rope lines up the dome [f1-f6], summit flags [f11] | Cloud sea below, far peaks poking through [f10]; big visible void on both sides of the dome |
| [old_d] | Open slope | Steep-ish | Rope (red) from avatar; dark patch lower left [f7] | Whiteout, almost nothing visible |
| [old_e] | Open dome | Steep dome | 3 coloured rope lines [f7-f12]; steep dark-rock/snow descent [f15] | Cloud sea [f1-f6]; whiteout bright face [f15] |

Not observed in any file: switchbacks, plank bridges, hanging bridges, stairs, handrails, guardrails, wooden signs.

## 3. Terrain silhouette

- [img1] OBSERVED: sharp triangular peak on the centreline, leading ridge in front rising toward it; second, smaller pointed summit upper-left with snow; **natural arch/window in the crest at upper-left of the avatar** (the left peak's lower mass has a hole with a pale rock bridge above it); right flank a single huge slab face tilted down-right with fine vertical fluting; ridges recede to pale haze. Horizon is broken peaks with sky between.
- [img2] OBSERVED: rounded fog-eroded boulder domes behind; a stepped angular stack (large faceted blocks, grey, smooth with cracks) forming a diagonal staircase up-right. Horizon not visible (fog).
- [img3] OBSERVED: cracked slab fields, huge rounded and angular boulders, a cleft with upright thin slabs; horizon closed except a small sky gap at top centre.
- [img4] OBSERVED: snow-plastered cracked rock face, large smooth wind-formed snow slab with a sharp lip on the right; a snow-covered shoulder at upper left; horizon is a grey overcast sky above a ridgeline.
- [img5] OBSERVED: low rolling forest terrain, rock outcrops, no mountain horizon. INFERRED relevance: low-band/foothill reference, not alpine.
- [new_v1] OBSERVED: steep snow face dotted with black rock ribs and patches; a large pale wall with vertical striations at the top of f1-f4. [new_v2] OBSERVED: big snow faces, one distant snowy range with several peaks [f4-f5]. [new_v3 f7] OBSERVED: rounded snowy summit ridge crest and cloud sea; a rock/snow shoulder at upper left [f1].
- [old_a] OBSERVED: single steep pyramid peak above a flat scree plain [f4, f5, f13]; glacier ice wall [f10]; dark ridge on blue-black sky [f9]. [old_b f6] ridge against sky. [old_c] rounded dome with a snowy ridge descending right; far peaks above clouds [f10]. No arches, spires or arêtes other than [img1].
- INFERRED: most K2-style frames are large smooth snow planes with rock ribs; the only strong silhouette-driven reference is [img1].

## 4. Palette and materials (eyeballed estimates, not sampled)

| Group / file | Observed materials | Estimated swatches (role) |
|---|---|---|
| Dark ridge [img1] | Dark grey-brown rock with moss/green-brown patches at the foot, pale snow in crevices | rock shadow ~#2b2a2a; lit rock foot ~#6b6f58 (greenish) ; sky/cloud ~#c9c6bc; far haze ~#a39e92; snow patch ~#d8dadc |
| Fog boulders [img2] | Smooth grey-green faceted rock, tan haze, grey-metal ladders, orange helmets, red jacket | haze ~#b8a98c; rock ~#7d8079; helmet ~#c8631f (accent); HUD green bar ~#5cb338, blue ~#4b93d1, orange ~#cf8a2c; panel dark ~#1f2630 |
| Mossy gully [img3] | Crumpled grey rock with a wet-looking pale grey sheen, olive moss on boulder tops, red-brown dirt path with dry grass flecks | rock ~#6e7273; moss ~#6d6a3f; dirt path ~#8a5a3a; pale streaks ~#aab0b3; shadow ~#1e2020 |
| Ladder over snow [img4] | Snow-dusted grey rock, white snow slabs, dark steel ladder, orange-brown rope, tan backpack, red sleeves | snow lit ~#e0e3e6; snow shade ~#9aa4ae; rock ~#4a4d52; rope ~#a86a2e; sky ~#d5d7d8; name-tag gold ~#c9ae45 |
| Forest/lake [img5] | Translucent green-yellow shallow water with ripple caustics, bright yellow-green moss, dark brown wood, grey lichen rock, palms + conifers | water ~#9db98a; moss ~#a9b83a; dark wood ~#4a2d22; rock ~#8a8579; foliage ~#4c6b3a; haze ~#d6d4b8 |
| Roped snow [new_v1] | White snow, bluish shadow, black rock ribs, yellow hood/helmets, blue barrel pack, orange rope, green laser line [f2] | snow ~#eef2f7; shade ~#b9c7d9; rock ~#232426; yellow ~#f0c419; blue ~#2a6fc0; rope ~#d9722a; green beam ~#6ee03a |
| Day/night snow [new_v2] | Day: white/blue-violet snow with clear sky and clouds; night: near black; red-lit gully; whiteout grey | day snow ~#f3f5fa; dusk slope ~#5a58a8; sky ~#4a8fd0; night ~#0a0f22; red light ~#d01818; fog ~#b7bac2; HUD bar orange ~#f39a1c; avatar pack white ~#d9dcdf + orange ~#e26a1b |
| Desktop snow [new_v3] | Yellow-green jacket, white pack, red jacket, snow white, black rock, sky blue, dark-red night, HUD dark panel with orange-ringed buttons | jacket ~#c4e21f; snow ~#f1f4f8; sky ~#3b79c0; night ~#3a0d10; HUD ~#222a33; ring orange ~#d9822b |
| Journey [old_a] | Glacier blue ice, sun-bloom snow, black scree, red tent, orange/yellow ropes and ladder, dark gear-shop UI with orange borders | ice ~#a7c4de; scree ~#4a4743; red tent ~#b0221d; ladder/strip ~#e0a21e; shop panel ~#1d1f23 with orange ~#e8892b |
| Summit [old_c, old_e] | Blue-violet shadowed snow, white cloud sea, deep blue sky, multi-colour flags | snow shadow ~#7d79c0; cloud ~#e9eef5; sky ~#1b4f9b; rope red ~#c42b2b / blue ~#2e55c7 |

Cross-file OBSERVED: snow bands read blue-violet in shadow and white in sun [new_v2 f3, old_c]; rock is black/grey where snow is absent; accent colours are almost all on avatars, ropes and HUD (yellow, orange, red, blue). INFERRED: no single unified palette is implied; the lush warm palette of [img5] and the moss of [img3] contradict the all-snow palette of the K2-style clips, so treat them as separate altitude bands.

## 5. Atmosphere and lighting

- [img1] OBSERVED: strong crepuscular light shafts raking from upper right across the dark face; very dark foreground against bright cloudy sky; layered distance haze (far ridges fade to warm pale grey); broken cloud sky. Depth is from value falloff, not from colour shift.
- [img2] OBSERVED: thick beige fog/dust reducing view to a few tens of avatar-lengths; HUD text "Sunset", "10°", "Viento: 3 mph"; small orange ember/dust specks drifting. Rock domes disappear into fog.
- [img3] OBSERVED: overcast, desaturated, flat light, mild fog; no strong shadows; small bright sky gap.
- [img4] OBSERVED: overcast white-grey sky, flat diffuse light, no cast shadows visible on snow; no visible particles.
- [img5] OBSERVED: warm hazy daylight through trees, bright specular ripples on water, soft bloom; no shafts observed.
- [new_v1] OBSERVED: white haze/spindrift bank upper-right [f1-f4]; frames f7-f10 are soft near the edges (INFERRED depth-of-field or motion blur).
- [new_v2] OBSERVED: night scenes near-black with a headlamp glow [f2]; a few pinpoint white dots upper-left of f2 (INFERRED stars); dusk blue-violet slope with clouds [f4]; red-lit scenes [f6] (source not visible); whiteout with large white snowflake sprites [f7-f9].
- [new_v3] OBSERVED: blizzard of big snowflake sprites [f3]; whiteout interior [f4]; night red-dark with a lamp cone [f6]; sky + cloud sea at summit [f7-f8].
- [old_a] OBSERVED: sun disc with lens glare [f1, f13]; big white snow-sprite flakes [f2, f6, f7, f11, f15]; night [f9, f16, f17] with a lit lamp at camp; dark blue night sky gradient [f9].
- [old_c] OBSERVED: sun disc with halo behind the avatar [f1, f5, f8]; cloud sea below, deep blue sky above; blue-violet shadow side of the dome. [old_d] OBSERVED: whiteout grey. [old_e] OBSERVED: sunlit dome over cloud sea; bright white-out in f15.
- Time-of-day variety across the set: sunset (img2 label), day, dusk, night, blizzard. Whether it is a dynamic cycle in one game is **not observed**.

## 6. Pacing and feel

- Camera: always third-person behind and above the avatar [all clips]. On steep slopes it pitches to look **down along the slope** (top-down [new_v1], [new_v3 f5], [old_b f4, f7, f8]); when walking the camera is low and close [new_v2 f7-f9]; zoomed-out single-avatar framing in [img3].
- [new_v1] second to second: climbing beside a partner along a rope, camera drifts from high/wide to closer; green beam appears for 1 frame [f2] (purpose unobserved); single sustained action, no set piece.
- [new_v2]: ice-axe hotbar (slot 1 selected), L and R orange bars at 1-2 frames [f1, f3] (INFERRED per-hand grip/stamina), a small ring reticle in the same screen position in every frame [f2-f9] (right of centre, ~62% down; INFERRED aim point); cuts between day, night, dusk, red-lit, whiteout within 18 s (set pieces are weather/light changes, not terrain).
- [new_v3]: desktop HUD: left icon column, bottom-right info panel, top-right list menu; alternates climbing, blizzard, tent, night, summit; ~8 gameplay beats in ~16 s.
- [old_a]: montage of beats (camp tent, plain, glacier, ladder, night, HUD, shop, quest, game card), cut every ~3 s so density is edited, not true pacing.
- [old_c]/[old_e]: long plain dome climb then summit banner; captions claim 50 min [old_c] and "2 hours" [old_e] for a full climb.
- [old_b f10-f11], [old_d]: fall consequence: avatar lying on scree/snow [old_b]; no frame shows the fall claimed by the [old_d] caption (not observed).
- HUD layout: [img2] landscape: top-left menu+weather, top-left vertical altitude track with camp ticks, left circle buttons (cart, group), left-bottom "OXYGEN FLOW ON" and "INVENTORY OPEN" buttons, bottom-left health/water/stamina bars (100 / 60 / 97), centre-bottom 3-slot hotbar, bottom-right chat (GLOBAL/LOCAL/EQUIPO tabs), top-right leaderboard. [new_v2], [old_*] portrait: hotbar centred at bottom (3 numbered slots or 1), panel bottom-right in [old_a f12], [old_c], [old_e]. Name tags: yellow role badge "Climbers" + name + health bar + two small counters [img4]; small green bar + name [img2]. Touch controls: **not observed**; mobile vs desktop for any clip is not determinable (portrait ones may be cropped desktop).

## 7. Per-file cheat sheet

- **[img1]**: narrow ridge top (~2 avatar widths) with sheer dark faces both sides; big peak on the centreline; crest arch as landmark; strong light shafts + layered haze for depth; moss-green only at the foot.
- **[img2]**: fog limits view; boulder-stack stairs with two ladders converging; dense HUD (altitude track with camps, oxygen toggle, hotbar, chat, leaderboard "Summits"); tan/orange palette; Spanish UI/chat in places.
- **[img3]**: narrow dirt path in enclosed rock cleft (~2-3 widths); slabs blocking the line; cracked grey rock + olive moss + red-brown dirt; overcast, no exposure; a lower-band tone.
- **[img4]**: ladder over snow-rock face seen from above-behind; rope arcs in foreground; overcast; role-badge name tag; snow slab with sharp lip.
- **[img5]**: warm, clear, lush low band: green translucent water, moss-covered log crossing, palms + conifers, wood pavilion; reads very different from the alpine set.
- **[new_v1]**: roped partner climb on steep snow with black rock ribs; straight-down camera for exposure; white spindrift; blue/yellow gear colours; no HUD beyond one hotbar icon.
- **[new_v2]**: ice-axe hotbar (3 slots), L/R bars, ring reticle; day/dusk/night/red/whiteout cuts; single-file climbers on rope; big snowflake sprites in whiteout.
- **[new_v3]**: desktop HUD set (left icon column, bottom-right panel, top-right menu); blizzard, tent, night, top-down view; summit with two diverging ropes over cloud sea.
- **[old_a]**: full-journey inventory: tent camp, glacier ladder, night camp, shop (helmets in "Points"), quest NPC, altitude/wind/oxygen HUD; ends on a "K2 CLIMBING SIMULATION" game card.
- **[old_b]**: ladder in snow groove; group in single file; steep face with rope seen from above; avatar lying on scree after (INFERRED) a fall.
- **[old_c]**: rounded dome over cloud sea; sun halo; multiple dark ropes; "SUMMIT REACHED +110 POINTS" banner; summit flags.
- **[old_d]**: whiteout; letterboxed; fall caption not visible in frames; only shows near-zero visibility.
- **[old_e]**: red/blue/black ropes diverging and converging on a summit dome; captions imply named routes and a last camp; summit banner; descent frame.

## 8. Unreadable / not observed / contradictions

**Unreadable or low confidence:** HUD numerals and labels in [new_v2], [new_v3], [old_c], [old_e] (only altitude-like values "5xxxM/6xxxM" and "8611 METERS" roughly legible); camp label text above peaks [old_a f5, f13]; green beam purpose [new_v1 f2]; red light source [new_v2 f6], [new_v3 f6]; turquoise patches [new_v1 f5-f6]; all hex values (eyeballed); gradient angles (inferred from foreshortening only).

**Not observed anywhere:** route splits/merges at a known point, bridges (plank, rope, stone), stairs, switchbacks, handrails, signage, minimap, mobile touch controls, audio, a stamina-out slide, rockfall/avalanche events, how a fall plays out (only the after-state [old_b f10-f11]), weather transitions as one continuous event, Foothold/town-like base.

**Contradictions with `design/v4-climb-concept.md` §2 (flagged, not edited):**
1. It says clip 1 ends on a "Fall 2: Deadpoint" card (sandstone canyon, bolted plank walkway on a wall, hanging rope-and-plank bridge, "You caused a rockslide!" notice, avatar clinging upside down, camera looking into fog and canopy). **None of that is in the present set.** [old_a] ends on a "[BETA] K2 CLIMBING SIMULATION by 14PEAKS STUDIOS"-style card (small text, mid legibility). No sandstone canyon, plank walkway or rockslide text appears in any of the 8 sheets or 5 stills. Either that clip is not in `references/videos/` (the folder holds 5 old + 3 new videos, the concept says "six clips") or it was misattributed. The Fall 2 claims in §2 and the "narrow plank line on a wall" premise of §1 therefore have **no support in this reference set** and should be re-sourced or dropped.
2. It says clips 2-6 are K2 "per captions". Captions/cards name K2 in [old_a] (card), [old_c] ("K2 climbing simulation") and [old_e] ("roblox K2"); [old_b], [old_d] and the three new clips carry no game name in the frames (INFERRED same game from matching gear, HUD and snow look).
3. The concept's thesis ("narrow visible line + big visible void") is supported strongly only by [img1] (knife ridge, source unknown, no UI) and, weakly, by ladders [img4], [old_a f10], [old_b f1]. The K2-style slope clips mostly show wide open snow with a rope; tension there comes from steepness, top-down camera, whiteout and night, not from narrowness. [img3] is a narrow path with no void.
4. The concept's "straight-down camera into fog and canopy" is attributed to Fall 2; straight-down camera is OBSERVED in [new_v1], [new_v3 f5], [old_b] (snow, not canopy).
5. Concept says oxygen is a canister consumable with no meter; the references show an "OXYGEN FLOW ON/OFF" toggle [img2] and an oxygen gauge in the HUD panel [old_a f12]. Decision stays the user's; flagging the mismatch with the reference.
6. Concept says "Neither reference has our colour variety". [img5] (green/yellow lake) and [img3] (moss, dirt) do show colour variety, but none shows altitude-banded colour in one clip.
7. Shop currency "Points" is OBSERVED [old_a f18]; concept lists currency as OPEN, so this is evidence only, not a decision.
