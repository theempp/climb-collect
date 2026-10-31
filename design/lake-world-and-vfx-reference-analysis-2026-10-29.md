# Lake world + VFX reference analysis (design only) â€” 2026-10-29

No game, Studio, code, publish or Robux changes. Source: five owner videos (TikTok screen recordings by other creators). Frames saved in `references/lake-world/` (contact sheets, 1-2 fps; videos not copied). Timings below are read from 1-2 fps sampling, so +-0.5 s. No audio was analysed.

Rule: these are mood/mechanic references. Rebuild with our own geometry and names; copy no creator's assets, signage or NPC names. Palette and sizes come from an Atlas pass on `references/lake-world/`, not from me. Colour words below are descriptions, not tokens.

## 1. Video 1 -> the fishing world (foggy forest)
What the frames show:
- **Depth is built from fog.** Dense cool teal-grey haze; trunks fade out within about 3-5 tree rows. Layers: near dark grass and trunks, mid lit path, far silhouettes.
- **Light is local, not global.** Almost no sky. Light comes from lantern posts (warm yellow, glass boxes on short wooden poles), floating fireflies and dust motes, and a pale glow from the portal. Warm-vs-cool contrast guides the eye along the path.
- **Trees:** very tall pale birch-like trunks with low-poly dark leaf canopies; some huge dark trunks with hollows/knots at the path edge; ferns, reeds, red berry bushes, mushrooms/brackets on trunks.
- **Ground:** long, soft, swaying grass in a lit meadow near the portal; a worn dirt path winding between trunks; low wooden fences; small wooden signposts.
- **Portal:** a plain stone frame filled with pure white light, standing in the meadow, readable from far away through the fog. Direct match for our portal-to-lake idea.
- **Camera:** third person, close and low; grass blades overlap the avatar.
- **Perf note:** fog is also the cheap trick that hides draw distance. Grass density and fireflies need a LOW tier for the phone 30 FPS floor.

Mapping to our fishing world ("Hollow Lake" working name, not a commitment):
- Enter via the lake portal in the commons (existing decision); arrive in a lit clearing at a stone portal frame.
- Not an open lake: a **winding path through woods with several still pools, a creek and one big mist-covered pond**; fishing spots are docks/stones/path edges lit by lanterns.
- Same core loop (cast, pull in zone, egg -> break/reveal/carry/secure). The world's extra value: rarer eggs and creatures than the main lake, farther/deeper water = rarer (existing Luck + zones idea).
- Safe-zone readability: lantern-lit path = safe; dark fog beyond = danger. This replaces a fence/wall.

## 2. Video 2 -> plot tier-up animation (about 8.8 s, effect about 6 s)
Sequence (green pen with fence turns into a purple neon pen):
1. 0.0-1.0 s: idle. Thin white ring lines start circling the plot (anticipation).
2. 1.5-2.0 s: the plot's pieces (fence rails, grass tiles) break into cubes and lift off; a flat ring shockwave expands on the ground.
3. 2.5-4.5 s: all cubes swirl in a donut-shaped cloud around the plot. Colour shifts green -> dark violet mid-swirl. Cyan glow orbs and thin light streaks mark the motion. 2-3 concentric rings pulse.
4. 5.0-5.5 s: the cloud contracts toward the centre and settles.
5. 6.0-6.5 s: the new tier appears: different fence (posts with glowing caps), dark galaxy-like floor. Rings fade; hold.
Takeaways:
- It is **deconstruct -> swirl -> reconstruct**. The recolour happens while the old model is hidden in the swirl, so no pop.
- Anticipation, burst, swirl, settle are four distinct beats; the swirl carries the whole "growth" feeling.
- Fits our decision: tier unlocks the right to upgrade, coins buy it, and the plot visibly grows/changes by tier.
Implementation shape (later): server sets tier; client plays the effect from a capped pool of cubes (cube count caps per quality tier, 0 under Reduce effects -> short crossfade); skippable; no gameplay lock longer than the effect.

## 3. Video 3 -> hatch/reveal VFX (about 11 s)
Card-pack opening: dark screen with a red droplet charge-up -> a mystery box wrapped in pink/magenta orbit rings with cube debris and light shafts -> white flash -> the card appears, fans out with a 3D carousel of cards, flips -> chosen card centred under a ring halo (blue-white + red-purple rings), confetti, rarity line and a star rating pop above it.
Takeaways for the hatchery "big hatch moment": charge-up (shake/drop), orbit rings, burst, reveal, rarity label + stars, confetti scaled by rarity. Bigger rarity = more rings and longer hold; common stays fast (hatch spam must not feel slow).
Existing Glassbloom hatch reveal strip stays the UI; this is the world-space stage around the egg.

## 4. Video 4 -> energy vortex (about 20 s, one 8 s effect looped)
A ring appears (violet/magenta, layered thin rings), grows with a cloud/smoke swirl above it, then a **column of stacked helical rings** descends through the centre; hold, then cut. Night sky and moon.
Fit: the **lake-portal activation** in the commons (ring opens, vortex above, ring column) and the same family for the tier-up shockwave rings and the guardian-related effects. One shared ring/swirl kit keeps cost low.

## 5. Video 5 -> sky menu camera (about 9.6 s)
Player stands on a plot with pad buttons (Rebirth/Shop/Upgrade/Settings). Press a button -> the **camera tilts up into a cloud sky** and panels float there (a best-deal pack slides in beside coin packs; Close button below). Close -> camera drops back to the plot. A second menu opens the same way (three tall cards with rays).
Takeaways:
- The sky is the stage: the world falls away so the menu has a clean backdrop; it hides the world's clutter and gives a "special place" feeling.
- Panels slide sideways in and out as a carousel; one Close button always visible.
Conflicts and rules:
- Existing decision: shop is UI-only and opens from anywhere. Keep that: a HUD button on phone and desktop. The physical pad in the plot is an **extra** that plays the camera-to-sky flourish, never the only door.
- The video's candy-bright rainbow panel styling must NOT be copied: panels use our Glassbloom intel. Only the camera/sky-stage mechanic transfers.
- Needs: skip/instant option (phone, accessibility, Reduce effects), camera returns even on error, no input lock if the player is hit/disconnects, no world exposure to harm while the camera is up (menu only opens in safe zones).

## Owner decisions (2026-10-29 popups)
- Guardian: a forest-fitting water creature replaces the shark in this world (same telegraph-and-lunge rule; creature design TBD).
- Layout: 3-4 connected lantern-lit clearings along a path; fog hides the gaps.
- Sky-menu stage: Shop + Upgrade only, via physical pads in the plot; the HUD button still opens them anywhere.
- Lighting: constant misty dusk, no day-night cycle.

## Still open
1. Per-tier plot looks (needs the owner's themes; none invented).
2. Which creature guards the water, and whether the main lake keeps the shark.
3. Owner's remaining VFX references for tier upgrades (this batch may cover them; confirm).

## Next steps (no build now)
1. Atlas pass on `references/lake-world/` -> tokens (fog feel, lantern tint, grass/trunk shapes) into `design/`.
2. Fold these decisions into the home-base build spec.
3. Build later in the single planned build, in a Studio copy, never the main place.
