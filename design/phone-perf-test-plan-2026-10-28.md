# Phone performance test plan (2026-10-28)

Docs only. Nothing built, published or changed. Numbers marked PROPOSED are untested starting points.

## Situation
- No low-end device available (owner, 2026-10-28). Only owner iPhone 16 Pro and a reported iPhone 18 Pro Max.
- The "30 FPS on iPhone XR-class" line in the listing draft (publish-prep §5) has no evidence. **Do not publish that claim.**

## Listing wording until a low-end phone is tested
- Supported: "Modern phones (tested on iPhone 16 Pro) and desktop."
- Do not state a minimum model or FPS.
- Revisit after the soft-launch device data below.

## Test A: owner iPhone 16 Pro (hosted private server, ~10 min)
Needs a hosted copy (Studio playtest is not a phone measurement). Open the in-game Developer Console / MicroProfiler (Settings > Developer Console is available to the place owner).

Stand at each spot for 30 s, record FPS (avg and low), memory, ping:
1. Spawn / sanctuary
2. Blossom mountain, first section
3. Lava section
4. Astral section
5. Home base (largest tier built)
6. Shop open, then egg hatch reveal
7. 8-player moment (Studio Test Session clients do not count for phone numbers; use friends if possible)

Pass (PROPOSED, on a flagship): avg >= 55 FPS, no sustained frames over 50 ms, no memory growth over 20 min.

## Test B: stress proxies for a weak phone (no device needed)
- Set Graphics Quality to the lowest level on the iPhone and repeat spots 2-5.
- Turn on the game's own LOW tier / Reduce effects (Motion.luau) and repeat.
- Low-quality results approximate headroom, not an XR. A flagship that holds 60 only on high quality is a warning sign.

## Test C: real low-end data after launch (soft launch)
- Release to a small group first (friends, then small public).
- Creator Dashboard > Analytics > Performance: FPS, memory and crash rate by device class. This is the actual low-end test.
- Go/no-go (PROPOSED): crash rate on any phone class under 2%, no class below 25 FPS median. If failed: raise the stated floor or cut cost (see levers).

## Cost levers if results are poor (ordered by effort)
1. Auto quality tier on first load, based on measured frame time, with a visible setting.
2. Lower particle and beam caps in LOW (Motion.luau already has the gate).
3. Check CSG union count and streaming radius in the mountain world (older V2 world had ~20k unions).
4. Reduce shadows / post effects on phone.
5. Creature mesh budget: 3,500 tris (6,000 Legendary/Guardian), <= 16 parts. Re-check before bulk upload.

## Open
- Hosted copy is required for Test A (private, no public release).
- Real DataStore behavior is still unverified and should be checked in the same hosted session.
