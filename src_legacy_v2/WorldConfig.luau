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
	{0, 3200}, {25, 3196}, {60, 3165}, {110, 3075}, {170, 2930}, {240, 2740}, {310, 2560}, {370, 2420}, {420, 2330}, -- spire
	{470, 2285}, {540, 2245}, -- Camp 4 shelf
	{600, 2140}, {660, 2010}, {730, 1880}, {790, 1805}, -- Storm Ridge band
	{840, 1785}, {880, 1765}, -- ruin shelf
	{915, 1700}, {950, 1645}, -- step
	{1000, 1615}, {1060, 1585}, -- Camp 3 shelf (Broken Cliffs)
	{1110, 1470}, {1160, 1350}, {1210, 1230}, {1260, 1130}, -- Broken Cliffs band
	{1320, 1070}, {1400, 1015}, {1470, 960}, {1530, 900}, -- Whispering Forest shelf (Camp 2)
	{1560, 820}, {1590, 720}, {1620, 640}, -- forest band
	{1680, 575}, {1750, 520}, {1820, 460}, {1890, 395}, -- Green Valley shelf (Camp 1)
	{1930, 320}, {1970, 230}, {2010, 150}, {2050, 100}, -- valley lip (the falls drop here)
	{2120, 70}, {2250, 48}, {2400, 42}, {2520, 55}, -- dry foothills (Foothold)
	{2600, 120}, {2680, 240}, {2760, 330}, {2800, 355}, {3800, 450}, -- rim
}

-- Biome bands by altitude (Gen.regionOf; noise wobbles the edges). Codes: 1 valley, 2 forest, 3 cliffs,
-- 4 storm, 5 summit, 6 rim, 7 dry foothills.
C.BIOME = { foothills = 165, valley = 640, forest = 1130, cliffs = 1760, storm = 2340, rimR = 2620 }
-- Region bands by re for dressing modules (outer edge inclusive).
C.REGION = { foothills = 2030, valley = 1600, forest = 1270, cliffs = 880, storm = 430 }

-- Summit spire: 4 aretes/buttresses via a superellipse metric (p < 2) inside SPIRE.outer.
C.SPIRE = { p = 1.15, angle = 0.3, inner = 330, outer = 470, norm = 1.14 }
-- Crown features (V3 plan P1 accept (b): >= 3 distinct features).
C.CROWN = {
	horns = { offset = 40, radius = 24, height = 58 }, -- twin horns either side of a notch
	notch = { halfWidth = 18, depth = 46, radius = 95 }, -- saddle where the summit pad sits
	fins = { -- thin blades on the recessed spire faces
		{ theta = 1.08, re0 = 110, re1 = 400, height = 46, halfWidth = 9 },
		{ theta = 2.62, re0 = 130, re1 = 380, height = 40, halfWidth = 8 },
		{ theta = 4.22, re0 = 120, re1 = 420, height = 52, halfWidth = 10 },
	},
	buttress = { height = 70, halfWidth = 46, re0 = 250, re1 = 520 }, -- arete roots spreading onto the shelf
	arch = { theta = 5.85, re0 = 205, re1 = 285, radius = 10, lift = 6, window = 95, windowHalf = 26 },
}

-- Massifs that break the radial symmetry (additive cones, kept off the routes).
C.PEAKS = {
	{ name = "Stormhorn", theta = 3.75, re = 700, height = 520, radius = 240 },
	{ name = "RuinTooth", theta = 2.05, re = 860, height = 300, radius = 130 },
	{ name = "WestShoulder", theta = 5.10, re = 1150, height = 260, radius = 230 },
	{ name = "SentinelPair", theta = 3.95, re = 1700, height = 210, radius = 170 },
}

C.FALL = { theta = 0.40, lipY = 402, poolY = 104, bowlHalf = 0.06, lipOuter = 1895, lipCut = 26, reMin = 1800, reMax = 2080 }
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
			{ -0.06, 2060, "Gate" }, { -0.35, 2032 }, { -0.64, 2002 }, { -0.36, 1970 }, { -0.64, 1938 }, { -0.36, 1906 },
			{ -0.12, 1866 }, { 0.04, 1800 }, { 0.10, 1750, "Camp1" },
			{ 0.42, 1735 }, { 0.78, 1712 }, { 1.06, 1660 }, { 0.80, 1628 }, { 1.10, 1596 }, { 0.80, 1566 }, { 1.10, 1536 },
			{ 1.34, 1490 }, { 1.52, 1440 }, { 1.60, 1400, "Camp2" },
			{ 1.92, 1360 }, { 2.22, 1312 }, { 2.52, 1268 }, { 2.22, 1232 }, { 2.52, 1196 }, { 2.22, 1160 }, { 2.52, 1124 },
			{ 2.22, 1088 }, { 2.60, 1058 }, { 2.90, 1050, "ChasmBridge" }, { 3.10, 1030, "Camp3" },
			{ 3.40, 1000 }, { 3.66, 965 }, { 3.44, 938 }, { 3.66, 908 }, { 3.90, 870 }, { 4.12, 845 },
			{ 3.80, 808 }, { 4.14, 776 }, { 3.80, 744 }, { 4.14, 712 }, { 3.80, 680 }, { 4.14, 648 }, { 3.80, 616 },
			{ 4.14, 584 }, { 3.84, 556 }, { 4.24, 528 }, { 4.60, 500, "Camp4" },
			{ 4.98, 488 }, { 5.36, 470 }, { 5.06, 446 }, { 5.40, 422 }, { 5.10, 398 }, { 5.44, 374 }, { 5.80, 335, "Merge" },
		},
	},
	{
		name = "Waterfall", label = "Waterfall Stair", intensity = 5, hw = 5, blend = 7, grade = 0.45, prio = 3,
		ctrl = {
			{ 0.22, 2088, "Gate" }, { 0.34, 2068 }, { 0.50, 2040 }, { 0.56, 2006 }, { 0.66, 1976 }, { 0.54, 1948 },
			{ 0.66, 1920 }, { 0.54, 1894 }, { 0.44, 1866 }, { 0.30, 1808 }, { 0.10, 1750, "Camp1" },
			{ 0.26, 1716 }, { 0.40, 1676 }, { 0.50, 1640 }, { 0.62, 1618 }, { 0.52, 1592 }, { 0.62, 1566 }, { 0.52, 1540 },
			{ 0.66, 1508 }, { 0.92, 1468 }, { 1.24, 1430 }, { 1.60, 1400, "Camp2" },
			{ 1.74, 1346 }, { 1.90, 1300 }, { 2.08, 1270 }, { 1.92, 1240 }, { 2.08, 1210 }, { 1.92, 1180 }, { 2.08, 1150 },
			{ 1.92, 1120 }, { 2.08, 1090 }, { 2.36, 1040 }, { 2.66, 990 }, { 2.94, 978 }, { 3.10, 1030, "Camp3" },
			{ 3.22, 990 }, { 3.32, 958 }, { 3.20, 930 }, { 3.32, 904 }, { 3.44, 860 }, { 3.56, 820 }, { 3.44, 792 },
			{ 3.58, 764 }, { 3.44, 736 }, { 3.58, 708 }, { 3.44, 680 }, { 3.58, 652 }, { 3.44, 624 }, { 3.58, 596 },
			{ 3.86, 556 }, { 4.24, 518 }, { 4.60, 500, "Camp4" },
			{ 4.78, 470 }, { 4.98, 448 }, { 4.82, 426 }, { 5.00, 404 }, { 4.84, 384 }, { 5.20, 362 }, { 5.80, 335, "Merge" },
		},
	},
	{
		name = "Ledge", label = "Cliff Ledge Line", intensity = 8, hw = 2, blend = 4, grade = 0.45, prio = 2,
		ctrl = {
			{ -0.16, 2072, "Gate" }, { -0.26, 2040 }, { -0.02, 1994 }, { -0.24, 1946 }, { -0.02, 1898 }, { 0.06, 1806 },
			{ 0.10, 1750, "Camp1" },
			{ 0.40, 1768 }, { 0.80, 1760 }, { 1.12, 1720 }, { 1.20, 1660 }, { 1.44, 1600 }, { 1.22, 1540 }, { 1.48, 1480 },
			{ 1.60, 1400, "Camp2" },
			{ 1.90, 1420 }, { 2.30, 1360 }, { 2.62, 1300 }, { 2.66, 1240 }, { 2.36, 1172 }, { 2.68, 1110 }, { 2.48, 1062 },
			{ 2.70, 1010 }, { 2.94, 972 }, { 3.10, 1030, "Camp3" },
			{ 3.36, 1060 }, { 3.70, 1040 }, { 3.98, 990 }, { 4.10, 930 }, { 4.30, 870 }, { 4.52, 800 }, { 4.30, 730 },
			{ 4.54, 660 }, { 4.32, 590 }, { 4.50, 540 }, { 4.60, 500, "Camp4" },
			{ 4.40, 450 }, { 4.62, 400 }, { 5.00, 372 }, { 5.40, 350 }, { 5.80, 335, "Merge" },
		},
	},
	{
		name = "Spire", label = "Spire Ridge", intensity = 10, hw = 2.5, blend = 5, grade = 0.62, prio = 2, crest = 24,
		ctrl = {
			{ 0.08, 2078, "Gate" }, { 0.14, 2046 }, { 0.24, 2010 }, { 0.14, 1966 }, { 0.24, 1924 }, { 0.17, 1880 },
			{ 0.13, 1812 }, { 0.10, 1750, "Camp1" },
			{ 0.20, 1800 }, { 0.70, 1800 }, { 1.30, 1720 }, { 1.52, 1660 }, { 1.58, 1600 }, { 1.50, 1556 }, { 1.58, 1510 },
			{ 1.60, 1400, "Camp2" },
			{ 1.70, 1440 }, { 2.40, 1420 }, { 2.76, 1340 }, { 2.80, 1270 }, { 2.72, 1210 }, { 2.80, 1150 }, { 2.72, 1100 },
			{ 2.84, 1060 }, { 3.10, 1030, "Camp3" },
			{ 3.30, 1080 }, { 4.10, 1060 }, { 4.40, 980 }, { 4.56, 900 }, { 4.62, 820 }, { 4.56, 740 }, { 4.64, 660 },
			{ 4.58, 590 }, { 4.60, 500, "Camp4" },
			{ 4.36, 520 }, { 4.10, 470 }, { 4.30, 420 }, { 4.70, 380 }, { 5.20, 352 }, { 5.80, 335, "Merge" },
		},
	},
}
-- Shared final approach: spiral stair from the merge point to the summit notch.
C.SUMMIT_STAIR = { theta0 = 5.80, re0 = 335, theta1 = 11.6, re1 = 24, step = 0.25, grade = 0.8 }
C.GRADE = { default = 0.28, stairs = 0.62, summitStairs = 0.8 }

-- Flattened pads. height: "h0" = natural terrain, number = fixed. kind 3 = camp, 4 = feature, 5 = Foothold.
C.PADS = {
	{ name = "Foothold", theta = 0.0, re = 2290, radius = 270, blend = 90, height = 46, kind = 5 },
	{ name = "Camp1", camp = true, radius = 58, blend = 26, height = "h0", kind = 3 },
	{ name = "Camp2", camp = true, radius = 58, blend = 26, height = "h0", kind = 3 },
	{ name = "Camp3", camp = true, radius = 54, blend = 24, height = "h0", kind = 3 },
	{ name = "Camp4", camp = true, radius = 50, blend = 22, height = "h0", kind = 3 },
	{ name = "Merge", camp = true, radius = 34, blend = 14, height = "h0", kind = 4 },
	{ name = "SummitCrown", x = 0, z = 0, radius = 16, blend = 10, height = 3196, kind = 4 },
}

-- Water: river from the falls pool to the foothill lake; creek from the forest band to the falls lip.
C.RIVER = { pts = { {0.40, 1960}, {0.46, 2030}, {0.56, 2090}, {0.66, 2160}, {0.76, 2230}, {0.86, 2290}, {0.92, 2310} },
	halfWidth = 10, blend = 12, depth = 5, startLevel = 104 }
C.CREEK = { pts = { {0.66, 1610}, {0.60, 1680}, {0.52, 1760}, {0.44, 1840}, {0.40, 1878} }, halfWidth = 5, blend = 7, depth = 2.5, endLevel = 401 }

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
}
C.WATER_COLOR = Color3.fromRGB(46, 196, 182)
-- Dry-foothill prop colors (PROPOSED, word-derived, swap here when a reference arrives).
C.DRY = {
	dryGrass = Color3.fromRGB(192, 166, 96), -- "dry grass"
	redEarth = Color3.fromRGB(150, 82, 54), -- "red-brown earth"
	scrub = Color3.fromRGB(118, 126, 70), -- "scrub": dusty olive between meadowEmerald and dryGrass
}

-- Player movement (user-approved 2026-10-20): expedition pace and a 45 deg slope limit.
C.PLAYER = { walkSpeed = 12, maxSlope = 45 }

return C
