-- WorldConfig (V3 Ascent): layout + palette for the CLIMB & COLLECT mountain (all PROPOSED unless noted).
-- Angles: theta = 0 points to +Z (Foothold side); x = r*sin(theta), z = r*cos(theta).
-- "re" = effective radius (bands follow re, which wobbles organically via Gen.rwarp).
-- Palette sources: design/world-tokens.md (traced to master.md §3/§4; dry-foothill colors derived from the
-- user's interview words only, PROPOSED/awaiting reference).
local C = {}

C.VERSION = 3
C.CELL = 4
C.HALF = 2800 -- 5,600-stud map (V3 plan decision 3, PROPOSED footprint)
C.N = 1400
C.BLOCK = 32
C.TOP = 3400 -- ray-cast start height for ground queries

-- Radial height profile {re, y}. Summit ~3,200 (LOCKED). Shelves host camps at ~16/32/50/71% of height
-- (PROPOSED); steep bands are region transitions and where the four routes differ.
C.PROFILE = {
	{0, 3200}, {25, 3196}, {60, 3160}, {100, 3060}, {140, 2900}, {165, 2830}, {205, 2805}, -- crown tower + shoulder ledge
	{240, 2740}, {300, 2590}, {370, 2430}, {420, 2330}, -- lower spire
	{470, 2285}, {540, 2245}, -- Camp 4 shelf
	{600, 2140}, {660, 2010}, {730, 1880}, {790, 1805}, -- Storm Ridge band
	{840, 1785}, {880, 1765}, -- ruin shelf
	{915, 1700}, {950, 1645}, -- step
	{1000, 1615}, {1080, 1580}, -- Camp 3 shelf (Broken Cliffs)
	{1125, 1470}, {1170, 1350}, {1215, 1230}, {1260, 1130}, -- Broken Cliffs band
	{1320, 1070}, {1400, 1015}, {1470, 960}, {1530, 900}, -- Whispering Forest shelf (Camp 2)
	{1560, 820}, {1590, 720}, {1620, 640}, -- forest band
	{1680, 575}, {1750, 520}, {1820, 460}, {1890, 395}, -- Green Valley shelf (Camp 1)
	{1950, 330}, {2010, 250}, {2070, 170}, {2130, 105}, -- valley lip (the falls drop here)
	{2200, 70}, {2300, 52}, {2420, 44}, {2560, 58}, -- dry foothills (Foothold)
	{2640, 130}, {2720, 250}, {2790, 340}, {2800, 350}, {3800, 450}, -- rim
}

-- Biome bands by altitude (Gen.regionOf; noise wobbles the edges). Codes: 1 valley, 2 forest, 3 cliffs,
-- 4 storm, 5 summit, 6 rim, 7 dry foothills.
C.BIOME = { foothills = 165, valley = 640, forest = 1130, cliffs = 1760, storm = 2340, rimR = 2700 }
-- Region bands by re for dressing modules (outer edge inclusive).
C.REGION = { foothills = 2030, valley = 1600, forest = 1270, cliffs = 880, storm = 430 }

-- Summit spire: 4 aretes/buttresses via a superellipse metric (p < 2) inside SPIRE.outer.
C.SPIRE = { p = 0.85, angle = 0.3, inner = 300, outer = 470, norm = 1.30 }
-- Crown features (V3 plan P1 accept (b): >= 3 distinct features).
C.CROWN = {
	horns = { offset = 46, radius = 26, height = 58 }, -- twin horns either side of a notch
	notch = { halfWidth = 20, depth = 40, radius = 95 }, -- saddle where the summit pad sits
	fins = { -- thin blades on the recessed spire faces
		{ theta = 1.08, re0 = 100, re1 = 420, height = 110, halfWidth = 16 },
		{ theta = 2.62, re0 = 120, re1 = 400, height = 90, halfWidth = 14 },
		{ theta = 4.22, re0 = 110, re1 = 430, height = 120, halfWidth = 18 },
	},
	buttress = { height = 130, halfWidth = 54, re0 = 200, re1 = 470 }, -- arete roots spreading onto the shelf
	arch = { atRe = 190, halfSpan = 24, height = 46, thickness = 8 }, -- Crown Gate: free-standing rock arch over the summit stair
}

-- Massifs that break the radial symmetry (additive cones, kept off the routes).
-- Peaks are ridges: stretch = tangential elongation of the cone.
C.PEAKS = {
	{ name = "Stormhorn", theta = 5.45, re = 780, height = 820, radius = 300, stretch = 1.9 },
	{ name = "RuinTooth", theta = 0.95, re = 880, height = 460, radius = 190, stretch = 1.6 },
	{ name = "WestShoulder", theta = 5.05, re = 1180, height = 380, radius = 260, stretch = 2.0 },
	{ name = "SentinelPair", theta = 3.95, re = 1700, height = 210, radius = 170, stretch = 1.5 },
}

C.FALL = { theta = 0.40, lipY = 402, poolY = 104, bowlHalf = 0.06, lipOuter = 1895, lipCut = 26, reMin = 1800, reMax = 2170 }
C.CHASM = { theta = 2.90, reIn = 1000, reOut = 1265, floor = 1040 }
C.LAKE = { theta = 0.95, re = 2330, radius = 200, level = 38, depth = 14 }
C.POOL = { theta = 0.40, re = 1930, radius = 34, bed = 92, level = 104 }

-- Camps and junctions (polar). Heights are taken from the natural terrain at the pad ("h0").
C.CAMPS = {
	Camp1 = { theta = 0.10, re = 1750 }, -- Meadow Lodge (Green Valley)
	Camp2 = { theta = 1.60, re = 1400 }, -- Rootgate (Whispering Forest)
	Camp3 = { theta = 3.10, re = 1030 }, -- Chasm Hut (Broken Cliffs)
	Camp4 = { theta = 4.60, re = 500 }, -- Stormwatch (Storm Ridge)
	Merge = { theta = 5.80, re = 335 }, -- all routes merge here for the summit stair
}

-- Four routes (V3 plan §1, character PROPOSED). Control points {theta, re, name?}; named points
-- "Camp1".."Merge" snap to the camp pads. hw/blend = trail half-width and shoulder; grade = max rise per
-- stud on walk sections, stairGrade on sections flagged by name pairs in `stairs`.
C.ROUTES = {
	{
		name = "Shepherd", label = "Shepherd's Road", intensity = 2, hw = 7, blend = 10, grade = 0.28, prio = 4,
		ctrl = {
			{ -0.12, 2110, "Gate" }, { -0.30, 2150 }, { -0.52, 2120 }, { -0.80, 2076 }, { -0.52, 2032 }, { -0.80, 1988 },
			{ -0.52, 1944 }, { -0.78, 1900 }, { -0.60, 1815 }, { -0.10, 1790 }, { 0.10, 1750, "Camp1" },
			{ 0.40, 1722 }, { 0.78, 1704 }, { 1.06, 1650 }, { 0.80, 1620 }, { 1.06, 1590 }, { 0.80, 1560 }, { 1.06, 1522 },
			{ 1.12, 1430 }, { 1.60, 1400, "Camp2" },
			{ 1.70, 1290 }, { 2.10, 1258 }, { 1.80, 1222 }, { 2.12, 1186 }, { 1.80, 1150 }, { 2.12, 1114 }, { 1.82, 1080 },
			{ 2.10, 1040 }, { 2.50, 975 }, { 2.90, 966 }, { 3.10, 1030, "Camp3" },
			{ 3.22, 965 }, { 3.62, 923 }, { 3.22, 881 }, { 3.62, 839 }, { 3.22, 797 }, { 3.62, 755 }, { 3.22, 713 },
			{ 3.62, 671 }, { 3.22, 629 }, { 3.62, 587 }, { 3.24, 545 }, { 3.70, 448 }, { 4.40, 445 }, { 4.60, 500, "Camp4" },
			-- spire flank: 5 arms ~28 studs apart (was 8 arms at ~18: props and cuts of one arm landed on the next)
			{ 4.72, 450 }, { 5.16, 436 }, { 4.66, 408 }, { 5.16, 380 }, { 4.68, 352 },
			{ 5.24, 338 }, { 5.60, 334 }, { 5.80, 335, "Merge" },
		},
		-- (v4 P3 run 2: one-arm scramble stacks were tried on Shepherd arms and removed: the arms are gentle slopes, so
		-- contour ledges ran inside the hillside and entries dropped; the rework needs authored set pieces like P2)
	},
	{
		name = "Waterfall", label = "Waterfall Stair", intensity = 5, hw = 5, blend = 7, grade = 0.45, prio = 3,
		-- v4 P3: the falls-side lip climb and the band climbs are ladder stacks on wet rock (RouteLines.luau)
		lines = {
			{ kind = "stack", c0 = 6, c1 = 15, pad0 = 3, pad1 = 24, band = "lip" }, -- s 1208 .. 3041 (beside the falls)
			{ kind = "stack", c0 = 19, c1 = 25, pad0 = 258, pad1 = 38, band = "forest" }, -- s 4013 .. 4672: ends where the switchback trail passes over the stack top (s 4991 left a 46-deg exit ramp; s 4631 put the exit ramp under the trail, run 2)
			{ kind = "stack", c0 = 35, c1 = 42, pad0 = 731, pad1 = -290, band = "cliffs" }, -- s 7906 .. 9307
			{ kind = "stack", c0 = 52, c1 = 61, pad0 = 102, pad1 = -96, band = "storm" }, -- s 11298 .. 12375
		},
		ctrl = {
			{ 0.12, 2110, "Gate" }, { 0.22, 2160 }, { 0.38, 2160 }, { 0.50, 2120 }, { 0.36, 2084 }, { 0.30, 2064 },
			{ 0.16, 2042 }, { 0.28, 2014 }, { 0.16, 1986 }, { 0.28, 1958 }, { 0.16, 1932 }, { 0.28, 1910 }, { 0.18, 1894 },
			{ 0.27, 1882 }, { 0.20, 1830 }, { 0.10, 1750, "Camp1" },
			{ 0.18, 1690 }, { 0.32, 1650 }, { 0.44, 1648 }, { 0.53, 1636 }, { 0.63, 1614 }, { 0.53, 1592 }, { 0.63, 1570 }, { 0.53, 1548 },
			{ 0.63, 1526 }, { 0.62, 1470 }, { 0.70, 1380 }, { 0.92, 1300 }, { 1.12, 1300 }, { 1.20, 1360 }, { 1.36, 1340 },
			{ 1.60, 1400, "Camp2" },
			{ 1.80, 1360 }, { 2.22, 1350 }, { 2.28, 1284 }, { 2.48, 1256 }, { 2.28, 1228 }, { 2.48, 1200 }, { 2.28, 1172 },
			{ 2.48, 1144 }, { 2.28, 1116 }, { 2.48, 1090 }, { 2.40, 1060 }, { 2.52, 1004 }, { 2.95, 1005 }, { 3.10, 1030, "Camp3" },
			{ 3.30, 990 }, { 3.80, 988 }, { 3.98, 950 }, { 3.80, 910 }, { 3.98, 870 }, { 3.80, 830 }, { 3.98, 790 },
			{ 3.80, 750 }, { 3.98, 710 }, { 3.80, 670 }, { 3.98, 630 }, { 3.80, 590 }, { 3.98, 548 }, { 4.02, 482 },
			{ 4.45, 480 }, { 4.60, 500, "Camp4" },
			{ 4.80, 470 }, { 5.25, 466 }, { 5.44, 446 }, { 5.24, 428 }, { 5.44, 410 }, { 5.24, 392 }, { 5.44, 376 },
			{ 5.72, 368 }, { 5.80, 335, "Merge" },
		},
	},
	{
		-- hw 3 (kind-6 bench cut only uphill) rendered ~3 studs wide and walkers slid off (run 2 walk test, s~785);
		-- the stamped connectors between the authored lines are now 9-wide benches cut and filled both sides
		name = "Ledge", label = "Cliff Ledge Line", intensity = 8, hw = 4.5, blend = 6, grade = 0.45, prio = 2,
		-- v4 P1: s 40-640 is not stamped: open foothills from the gate to the authored climb (LedgeP1) on the natural cliff
		stampSkip = { 40, 640 },
		-- v4 P3: each switchback climb through a steep band is unstamped and rebuilt as an authored pitch stack
		-- (LedgeRoute.luau). c0/c1 = indices into ctrl below (the stack runs between those two points).
		-- pad0 / pad1 (studs along the route, + = inward): each unstamped stretch begins and ends where the V3 trail
		-- lies on natural ground (V3 trails run in trenches down to -60 and on causeways up to +230 near the bands)
		lines = {
			-- v4 P3 run 2 (user: hang lines on the route's own lane): the lip shelf traverse -> a ledge line 28 below it
			-- (starts past the falls: s 3000 put the ledge through the falls' water at s ~3200)
			{ kind = "hang", s0 = 3300, s1 = 3850, stamp = true, band = "lip", drop = 28, label = "Lip line rest" },
			{ kind = "stack", c0 = 13, c1 = 16, pad0 = 141, pad1 = 90, band = "forest" }, -- s 5287 .. 6024
			{ kind = "stack", c0 = 20, c1 = 23, pad0 = 360, pad1 = -36, band = "cliffs" }, -- s 8076 .. 8922
			-- (storm, s 10146-11422: a stack there sat its lower tiers on the 47-deg step and gave irregular footing in
			-- bot runs; the V3 causeway stays until the step gets its own approach, run 2 decision log)
			-- (spire approach c34-c40 stays the V3 causeway: natural ground is 130-230 studs below the Merge pad)
		},
		ctrl = {
			{ -0.04, 2110, "Gate" }, { -0.16, 2080 }, { -0.42, 2040 }, { -0.18, 1980 }, { -0.40, 1915 }, { -0.20, 1858 },
			{ -0.06, 1850 }, { 0.10, 1750, "Camp1" },
			{ 0.20, 1800 }, { 0.32, 1862 }, { 0.80, 1868 }, { 1.30, 1858 }, { 1.36, 1640 }, { 1.56, 1586 }, { 1.38, 1530 },
			{ 1.54, 1470 }, { 1.60, 1400, "Camp2" },
			{ 1.70, 1440 }, { 2.40, 1440 }, { 2.52, 1272 }, { 2.84, 1210 }, { 2.56, 1150 }, { 2.84, 1092 }, { 2.88, 1062 },
			{ 3.10, 1030, "Camp3" },
			{ 3.30, 1036 }, { 4.02, 1036 }, { 4.36, 940 }, { 4.04, 840 }, { 4.36, 740 }, { 4.04, 640 }, { 4.34, 548 },
			{ 4.50, 520 }, { 4.60, 500, "Camp4" },
			{ 4.80, 500 }, { 5.42, 498 }, { 5.64, 430 }, { 5.46, 378 }, { 5.70, 362 }, { 5.80, 335, "Merge" },
		},
	},
	{
		name = "Spire", label = "Spire Ridge", intensity = 10, hw = 3.5, blend = 5, grade = 0.8, prio = 2, crest = 22,
		-- (hw 2.5 -> 3.5, run 2: the 5-stud crest rendered thin and rounded in 4-stud voxels; walkers slid into the couloirs)
		-- v4 P3: band climbs rebuilt as pitch stacks (RouteLines.luau), ends where the trail lies on natural ground;
		-- the crest-stamped shelf traverses stay (knife-ridge crests)
		lines = {
			-- (v4 P3 run 2: no hang lines on Spire. Its long legs are knife-ridge crests with 30-deep couloirs on both
			-- sides, so a ledge 28 below would lie on a couloir floor that runs beside the whole leg: a walkable bypass.
			-- The crest walk stays the exposure; see decision log.)
			{ kind = "stack", c0 = 14, c1 = 21, pad0 = 383, pad1 = 294, band = "forest" }, -- s 3678 .. 4241
			{ kind = "stack", c0 = 24, c1 = 29, pad0 = 33, pad1 = -84, band = "cliffs" }, -- s 6917 .. 7743
			{ kind = "stack", c0 = 32, c1 = 41, pad0 = 398, pad1 = 133, band = "storm" }, -- s 9542 .. 10088 (was .. 10308: 52-deg exit ramp, run 2)
		},
		ctrl = {
			{ 0.04, 2112, "Gate" }, { -0.02, 2084 }, { -0.09, 2050 }, { 0.02, 2016 }, { -0.09, 1982 }, { 0.02, 1948 },
			{ -0.08, 1914 }, { 0.00, 1880 }, { 0.06, 1820 }, { 0.10, 1750, "Camp1" },
			{ 0.30, 1760 }, { 0.44, 1796 }, { 0.80, 1796 }, { 1.20, 1780 }, { 1.20, 1700 }, { 1.30, 1662 }, { 1.20, 1622 }, { 1.30, 1584 },
			{ 1.21, 1546 }, { 1.30, 1494 }, { 1.48, 1470 }, { 1.60, 1400, "Camp2" },
			{ 1.70, 1490 }, { 2.94, 1490 }, { 3.00, 1270 }, { 3.08, 1220 }, { 2.98, 1170 }, { 3.08, 1120 }, { 3.02, 1080 },
			{ 3.10, 1030, "Camp3" },
			{ 3.30, 1074 }, { 4.42, 1074 }, { 4.44, 960 }, { 4.56, 910 }, { 4.44, 850 }, { 4.56, 790 }, { 4.44, 730 },
			{ 4.56, 670 }, { 4.44, 610 }, { 4.56, 556 }, { 4.60, 500, "Camp4" },
			{ 4.80, 532 }, { 5.62, 532 }, { 5.74, 470 }, { 5.64, 420 }, { 5.76, 380 }, { 5.80, 335, "Merge" },
		},
	},
}
-- Skilled-time model per route (PROPOSED, V3 plan §1): walk at C.PLAYER.walkSpeed plus segMin minutes of
-- obstacle/hazard time spread along the route. Mini-checkpoints are placed so each gap is ~cpTarget seconds
-- of skilled time; camps are checkpoints too (LOCKED: camps + a mini-checkpoint about every ~4 min).
C.ROUTE_MODEL = { cpTarget = 240, cpMax = 300, segMin = { Shepherd = 2, Waterfall = 8, Ledge = 11, Spire = 13 } }

-- Shared final approach: spiral stair from the merge point to the summit notch.
C.SUMMIT_STAIR = { theta0 = 5.80, re0 = 335, theta1 = 11.6, re1 = 6, step = 0.25, grade = 0.8 }
C.GRADE = { default = 0.28, stairs = 0.62, summitStairs = 0.8 }

-- Flattened pads. height: "h0" = natural terrain, number = fixed. kind 3 = camp, 4 = feature, 5 = Foothold.
C.PADS = {
	{ name = "Foothold", theta = 0.0, re = 2370, radius = 270, blend = 90, height = 48, kind = 5 },
	{ name = "Camp1", camp = true, radius = 58, blend = 26, height = "h0", kind = 3 },
	{ name = "Camp2", camp = true, radius = 58, blend = 26, height = "h0", kind = 3 },
	{ name = "Camp3", camp = true, radius = 54, blend = 24, height = "h0", kind = 3 },
	{ name = "Camp4", camp = true, radius = 50, blend = 22, height = "h0", kind = 3 },
	{ name = "Merge", camp = true, radius = 34, blend = 14, height = "h0", kind = 4 },
	{ name = "SummitCrown", x = 0, z = 0, radius = 20, blend = 10, height = 3170, kind = 4 },
}

-- Water: river from the falls pool to the foothill lake; creek from the forest band to the falls lip.
C.RIVER = { pts = { {0.40, 1960}, {0.46, 2030}, {0.56, 2090}, {0.66, 2160}, {0.76, 2230}, {0.86, 2290}, {0.92, 2310} },
	halfWidth = 10, blend = 12, depth = 5, startLevel = 104 }
C.CREEK = { pts = { {0.72, 1525}, {0.70, 1600}, {0.62, 1680}, {0.52, 1760}, {0.44, 1840}, {0.40, 1878} }, halfWidth = 5, blend = 7, depth = 2.5, endLevel = 401 }

-- Terrain material colors (design/world-tokens.md). Salt and Mud carry the dry-foothill colors
-- (PROPOSED, derived from the interview words "dry grass" / "red-brown earth", awaiting a reference image).
C.MATERIAL_COLORS = {
	Grass = Color3.fromRGB(84, 176, 82),
	LeafyGrass = Color3.fromRGB(52, 128, 92),
	Ground = Color3.fromRGB(186, 150, 98),
	Mud = Color3.fromRGB(150, 82, 54), -- redEarth: "red-brown earth"
	Salt = Color3.fromRGB(192, 166, 96), -- dryGrass: "dry grass"
	Rock = Color3.fromRGB(120, 128, 108),
	Sandstone = Color3.fromRGB(214, 150, 82),
	Slate = Color3.fromRGB(62, 66, 76),
	Basalt = Color3.fromRGB(46, 72, 122),
	Limestone = Color3.fromRGB(196, 192, 178),
	Snow = Color3.fromRGB(236, 244, 255),
	Glacier = Color3.fromRGB(150, 206, 240),
	Ice = Color3.fromRGB(176, 232, 252),
	Cobblestone = Color3.fromRGB(150, 146, 132),
	Sand = Color3.fromRGB(222, 206, 160),
	-- v4 P3: terrain marked (climbable) rock, used only on authored faces: Asphalt's speckled granite texture tinted
	-- with the lichen-rock token, so it sits in the rock mass but reads as grippy rock (Pavement rendered as brick
	-- paving, rejected); the orange fixed rope is the first cue, the texture the second
	Asphalt = Color3.fromRGB(120, 128, 108),
}
C.WATER_COLOR = Color3.fromRGB(46, 196, 182)
-- Dry-foothill prop colors (PROPOSED, word-derived, swap here when a reference arrives).
C.DRY = {
	dryGrass = Color3.fromRGB(192, 166, 96), -- "dry grass"
	redEarth = Color3.fromRGB(150, 82, 54), -- "red-brown earth"
	scrub = Color3.fromRGB(118, 126, 70), -- "scrub": dusty olive between meadowEmerald and dryGrass
}

-- Player movement (user-approved 2026-10-20): expedition pace and a 45 deg slope limit.
C.PLAYER = { walkSpeed = 16, maxSlope = 45 }

return C
