-- RouteSpline (v5 P1, 2026-10-21): v5 route data. One spline per route; each node sets the segment that leaves it.
-- Node: polar { th, re } (shelf: y = natural ground + dy), or a band node { th, y, band = { reLo, reHi } } (the
-- trail sits on the band face where the natural ground is `cut` (4) above it: re is solved on the contour; without y
-- the height is AUTO, spread evenly by distance between the neighbouring known heights), or a
-- fixed { x, z } (pinned tutorial anchors). name = waypoint (Gate, Camp1..Camp4, Merge snap to their pads).
--   t      segment type: ledge | slot | ridge | open | gap | log | stair   (SplineGen header)
--   w      tread width (2-5 tight; open up to 10)
--   piece  set piece at this node: { kind = "ladder", rise, run, inward } (vertical step to a top landing `run`
--          ahead, or toward the summit axis with inward = true: a ledge that reverses at a ladder face),
--          { kind = "rest", style = "pavilion"|"tent" } (stamina refill + checkpoint), { kind = "cairn" }
--          (checkpoint only), { kind = "log" } / { kind = "ropebridge" } on a gap segment, { kind = "cleft" }
--          (boulders + slabs in a slot), { kind = "stairs", rise } (boulder stair blocks + twin ladders),
--          { kind = "tear" } (fog tear viewpoint)
-- First publish (user, 2026-10-21): Shepherd + Waterfall on this kit; Ledge + Spire gated "Coming soon".
-- Placements PROPOSED (route sequences: design/v5-trails-and-mountain-plan.md round 3).
local S = {}

S.LIVE = { "Shepherd", "Waterfall" }
S.GATED = { Ledge = true, Spire = true }

local LIP = { 1840, 2140 }
local FOREST = { 1480, 1660 }
local CLIFFS = { 1000, 1300 }
local STEPB = { 845, 970 }
local STORM = { 520, 820 }
local SPIRE = { 300, 490 }
S.BANDS = { lip = LIP, forest = FOREST, cliffs = CLIFFS, step = STEPB, storm = STORM, spire = SPIRE }

-- v6: world-polar node helper (theta, world radius; the band nodes use effective radius + contour solving instead)
local function WP(th, r, t)
	t = t or {}
	t.x, t.z = r * math.sin(th), r * math.cos(th)
	return t
end
-- v6: contour search window for the forest-band tiers (wider than FOREST: the band swings out to r ~1700 at th 1.0)
local BAND6 = { 1440, 1800 }
-- v6: creek gorge from the falls chute to the band foot (Shepherd leg 2): the only crossing of the creek on the open
-- shelf is the route's (steps down, stepping stones, pitch up). Water level - depth = gorge floor. hw is measured from
-- every creek water cell (the creek is ~10 wide), so floor half-width ~7 and walls to ~10 from the creek centre.
-- Full depth from th 0.448 (a taper to 0.495 left the chute crossable with a 20-stud drop at th 0.45-0.47: bypass
-- test, v6); below 0.44 the falls slot itself is the barrier.
S.GORGES = {
	{ name = "CreekGorge", th0 = 0.432, th1 = 0.668, depth = 26, hw = 2, wall = 3, taper = { 0.432, 0.448 }, rLo = 1520, rHi = 1760 },
}

S.ROUTES = {
	{
		-- no rails (user 2026-10-21: falls and lost progress keep it tense; supersedes the "railed ledges" in decision 3)
		name = "Shepherd", label = "Shepherd's Road", w = 5, rail = "none", maxGrade = 0.6,
		nodes = {
			-- leg 1: Foothold gate -> tutorial lowland (pinned: the Rare nook rope is beside the s 840 road point) ->
			-- railed ledge up the lip band -> lip nest lower shelf -> pavilion -> Camp 1
			{ x = -227.2, z = 1812.2, y = 48, name = "Gate", t = "open", w = 8 },
			{ x = -610.6, z = 1908.5, t = "open", w = 8 },
			{ x = -1047.2, z = 1879.6, name = "Nook", t = "ledge" },
			{ th = -0.42, band = LIP, piece = { kind = "cairn" } },
			{ th = -0.30, band = LIP },
			{ th = -0.20, band = LIP, t = "slot", piece = { kind = "cleft" } },
			{ th = -0.16, y = 340, band = LIP, t = "ledge" },
			{ x = -175, z = 1648, name = "LipShelf", t = "slot", dy = -3 },
			{ th = 0.00, re = 1845, piece = { kind = "rest", style = "pavilion" } },
			{ th = 0.05, re = 1790, t = "open", w = 8 },
			-- leg 2 (v6 beat chain, 2026-10-21): Camp 1 -> cleft -> shelf -> cleft 2 -> falls overlook -> creek-gorge
			-- west rim -> steps down into the gorge, stepping stones, pitch up the far wall -> band foot -> the forest band
			-- climbed in 10 eastward tiers (pitch, ladders, chimney, rock steps, jump gaps, pinches, a hand traverse,
			-- rope bridges, the tall ladder) -> top-out pitch -> upper shelf cleft -> Camp 2. Checkpoints: band foot,
			-- band tent, L5 cairn (fall cost ~1-1.5 min this low; design/v6-trails-plan.md)
			{ name = "Camp1", t = "slot", dy = -4, piece = { kind = "cleft" } },
			WP(0.135, 1556, { dy = -5 }),
			WP(0.175, 1588, { t = "path", w = 5 }),
			WP(0.235, 1614, {}),
			WP(0.275, 1630, { t = "slot", dy = -5, piece = { kind = "cleft" } }),
			WP(0.325, 1650, { t = "path", w = 5 }),
			WP(0.375, 1676, { w = 6 }),
			WP(0.402, 1694, { w = 6, piece = { kind = "tear" } }), -- falls overlook at the slot head
			WP(0.432, 1678, { t = "rim", w = 6 }),
			-- gorge west rim, ~22 inside the creek centre (th 0.47 r 1680, 0.50 1660, 0.53 1646, 0.56 1637); the gorge wall
			-- top is ~13-14 out. w 6: a 4-wide terrain tread on the 30-deg cross-slope rendered rounded and the bot slid in
			WP(0.470, 1658, {}),
			WP(0.500, 1638, {}),
			WP(0.530, 1624, {}),
			WP(0.560, 1615, { w = 5 }),
			-- the crossing (creek centre c0 = (897, 1360), up-creek (0.722, -0.692), outer (0.692, 0.722)): rock steps down
			-- the west wall going up-creek, stepping stones over the stream, a marked pitch up the east wall
			{ x = 885.2, z = 1347.7, y = 608, t = "ford", w = 4, piece = { kind = "steps", rise = -25, run = 32.7, dir = { 0.960, -0.281 } } },
			{ x = 920.0, z = 1342.1, y = 583, t = "path", w = 4, piece = { kind = "pitch", rise = 20, run = 7, dir = { 0.692, 0.722 } } },
			-- east bank: a 45-deg side slope (the band's skirt), so a ledge cut into it with two rock steps up to the foot
			{ th = 0.615, y = 605, band = BAND6, t = "ledge", w = 6 },
			{ th = 0.650, y = 607, band = BAND6, w = 6 },
			{ th = 0.680, y = 610, band = BAND6, w = 6, piece = { kind = "steps", rise = 18 } },
			{ th = 0.703, y = 629, band = BAND6, w = 6 },
			{ th = 0.710, y = 630, band = BAND6, w = 6, piece = { kind = "steps", rise = 18 } },
			-- the forest band, eastward tiers (contour nodes; drop = exposure below the ledge edge). w 8: on this ~80-deg band
			-- the voxel tread renders lumpy and only ~w - 1 flat (w 4 and w 6 both lost the bot off L5 / L6); pinches w 5.
			-- cut 8: each tier sits a little deeper in the cliff, clear of the tier below
			{ th = 0.730, y = 652, band = BAND6, t = "ledge", w = 6, drop = 30, piece = { kind = "cairn" } },
			{ th = 0.742, y = 654, band = BAND6, cut = 8, w = 8, piece = { kind = "pitch", rise = 24, inward = true } },
			{ th = 0.752, y = 678, band = BAND6, cut = 8, w = 8 },
			{ th = 0.790, y = 683, band = BAND6, cut = 8, w = 8, t = "jump" },
			{ th = 0.7928, y = 683, band = BAND6, cut = 8, w = 8, t = "ledge" },
			{ th = 0.832, y = 688, band = BAND6, cut = 8, w = 8, piece = { kind = "ladder", rise = 16, inward = true } },
			{ th = 0.845, y = 704, band = BAND6, cut = 8, w = 8 },
			{ th = 0.878, y = 708, band = BAND6, cut = 8, w = 5, drop = 40 }, -- pinch over the band bulge
			{ th = 0.912, y = 712, band = BAND6, cut = 8, w = 8 },
			{ th = 0.924, y = 714, band = BAND6, cut = 8, w = 8, t = "gap", piece = { kind = "ropebridge" } },
			{ th = 0.934, y = 714, band = BAND6, cut = 8, w = 8, t = "ledge" },
			{ th = 0.953, y = 718, band = BAND6, cut = 8, w = 8, piece = { kind = "chimney", rise = 28, inward = true } },
			{ th = 0.966, y = 746, band = BAND6, cut = 8, w = 8 },
			{ th = 1.000, y = 750, band = BAND6, cut = 8, w = 8, piece = { kind = "rest", style = "tent" } },
			{ th = 1.040, y = 754, band = BAND6, cut = 8, w = 8, t = "traverse" },
			{ th = 1.050, y = 754, band = BAND6, cut = 8, w = 8, t = "ledge" },
			{ th = 1.082, y = 758, band = BAND6, cut = 8, w = 8, piece = { kind = "steps", rise = 16 } },
			{ th = 1.100, y = 774, band = BAND6, cut = 8, w = 8 },
			{ th = 1.140, y = 779, band = BAND6, cut = 8, w = 8, t = "jump" },
			{ th = 1.1428, y = 779, band = BAND6, cut = 8, w = 8, t = "ledge" },
			{ th = 1.160, y = 782, band = BAND6, cut = 8, w = 5, drop = 40 },
			{ th = 1.182, y = 784, band = BAND6, cut = 8, w = 8 },
			{ th = 1.203, y = 786, band = BAND6, cut = 8, w = 8, piece = { kind = "ladder", rise = 38, inward = true } }, -- the tall one
			{ th = 1.215, y = 824, band = BAND6, cut = 8, w = 8 },
			{ th = 1.250, y = 829, band = BAND6, cut = 8, w = 8, t = "gap", piece = { kind = "ropebridge" } },
			{ th = 1.260, y = 829, band = BAND6, cut = 8, w = 8, t = "ledge" },
			{ th = 1.288, y = 834, band = BAND6, cut = 8, w = 8, piece = { kind = "cairn" } },
			{ th = 1.303, y = 836, band = BAND6, cut = 8, w = 8, piece = { kind = "pitch", rise = 30, inward = true } },
			{ th = 1.315, y = 866, band = BAND6, cut = 8, w = 8 },
			{ th = 1.372, y = 874, band = BAND6, cut = 8, w = 8, piece = { kind = "pitch", rise = 28, inward = true } },
			{ th = 1.384, y = 902, band = BAND6, cut = 8, w = 8 },
			{ th = 1.412, y = 906, band = BAND6, cut = 8, w = 8, piece = { kind = "steps", rise = 18 } },
			{ th = 1.432, y = 924, band = BAND6, cut = 8, w = 8 },
			{ th = 1.444, y = 928, band = BAND6, cut = 8, w = 8, piece = { kind = "pitch", rise = 38, inward = true } }, -- top-out
			-- upper shelf: viewpoint at the band edge, cleft with a step-up to Camp 2
			WP(1.458, 1572, { y = 966, t = "open", w = 6, piece = { kind = "tear" } }),
			WP(1.490, 1530, { t = "slot", dy = -5, w = 4, piece = { kind = "cleft" } }),
			WP(1.530, 1478, { dy = -5 }),
			WP(1.560, 1440, { dy = -4 }),
			-- leg 3: forest shelf, cliffs band in three ledges (ladder faces at the turns), boulder slots
			{ name = "Camp2", t = "slot", dy = -4 },
			{ th = 1.76, re = 1342, dy = -5 },
			{ th = 1.96, re = 1322, dy = -4, piece = { kind = "cairn" } },
			{ th = 2.12, re = 1312, t = "ledge" },
			{ th = 2.22, band = CLIFFS },
			{ th = 2.36, band = CLIFFS },
			{ th = 2.50, band = CLIFFS, piece = { kind = "rest", style = "tent" } },
			{ th = 2.62, band = CLIFFS, t = "gap", piece = { kind = "ropebridge" } },
			{ th = 2.65, band = CLIFFS, t = "ledge" },
			{ th = 2.78, band = CLIFFS },
			{ th = 2.92, y = 1380, band = CLIFFS, piece = { kind = "ladder", rise = 12, inward = true } },
			{ th = 2.84, band = CLIFFS, piece = { kind = "cairn" } },
			{ th = 2.72, band = CLIFFS, t = "slot", piece = { kind = "cleft" } },
			{ th = 2.66, band = CLIFFS, t = "ledge" },
			{ th = 2.53, y = 1520, band = CLIFFS, piece = { kind = "ladder", rise = 14, inward = true } },
			{ th = 2.62, band = CLIFFS },
			{ th = 2.76, band = CLIFFS, piece = { kind = "tear" } },
			{ th = 2.90, band = CLIFFS },
			{ th = 3.06, y = 1660, band = CLIFFS, t = "slot" },
			-- leg 4: step band, ruin shelf, storm band in three ledges
			{ name = "Camp3", t = "ledge" },
			{ th = 3.20, re = 962 },
			{ th = 3.30, band = STEPB, piece = { kind = "cairn" } },
			{ th = 3.44, band = STEPB },
			{ th = 3.56, y = 1840, band = STEPB },
			{ th = 3.64, re = 828, t = "slot", dy = -4 },
			{ th = 3.72, band = STORM, t = "ledge" },
			{ th = 3.86, band = STORM, piece = { kind = "rest", style = "tent" } },
			{ th = 4.00, band = STORM },
			{ th = 4.14, band = STORM },
			{ th = 4.28, band = STORM },
			{ th = 4.40, y = 2000, band = STORM, piece = { kind = "ladder", rise = 12, inward = true } },
			{ th = 4.30, band = STORM, piece = { kind = "cairn" } },
			{ th = 4.20, band = STORM, t = "gap", piece = { kind = "ropebridge" } },
			{ th = 4.17, band = STORM, t = "ledge" },
			{ th = 4.04, band = STORM },
			{ th = 3.86, y = 2130, band = STORM, piece = { kind = "ladder", rise = 12, inward = true } },
			{ th = 3.98, band = STORM },
			{ th = 4.12, band = STORM, piece = { kind = "rest", style = "tent" } },
			{ th = 4.26, band = STORM },
			{ th = 4.36, y = 2205, band = STORM, t = "slot" },
			{ th = 4.46, re = 545 },
			-- leg 5: Camp 4 -> spire ledges -> boulder stair in fog -> merge
			{ name = "Camp4", t = "ledge" },
			{ th = 4.76, re = 468 },
			{ th = 4.92, band = SPIRE },
			{ th = 5.08, band = SPIRE, piece = { kind = "cairn" } },
			{ th = 5.22, band = SPIRE },
			{ th = 5.32, y = 2380, band = SPIRE },
			{ th = 5.42, y = 2398, band = SPIRE, t = "stair", piece = { kind = "stairs" } },
			-- boulder stair in fog up the merge buttress (twin ladders between the blocks)
			{ th = 5.50, re = 337, y = 2422, piece = { kind = "ladder", rise = 30 } },
			{ th = 5.585, re = 337, y = 2474, piece = { kind = "ladder", rise = 20 } },
			{ th = 5.67, re = 336, y = 2514, piece = { kind = "ladder", rise = 20 } },
			{ th = 5.73, re = 336, y = 2546, t = "open" },
			{ name = "Merge", t = "open" },
		},
	},
}

return S
