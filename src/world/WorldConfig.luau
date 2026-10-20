-- WorldConfig: layout + palette for the CLIMB & COLLECT mountain (all PROPOSED).
-- Angles: theta = 0 points to +Z (Foothold side); x = r*sin(theta), z = r*cos(theta).
-- "re" = effective radius (shelves follow re, which wobbles organically via Gen.rwarp).
-- Palette sources: design/world-tokens.md (traced to master.md §3/§4).
local C = {}

C.CELL = 4
C.HALF = 2400
C.N = 1200
C.BLOCK = 32

-- Radial height profile {re, y}. Concave overall (steepest at the summit spire) so the
-- peak reads from the valley; shelves host camps, steep bands are region transitions.
C.PROFILE = {
	{0, 2000}, {22, 1996}, {55, 1945}, {100, 1835}, {160, 1680}, {230, 1530}, {300, 1440}, -- summit spire
	{370, 1412}, -- Camp 4 shelf (300-370)
	{420, 1335}, {480, 1235}, -- upper Storm Ridge band
	{540, 1208}, -- ruin shelf (480-540)
	{600, 1085}, {660, 975}, {700, 912}, -- lower Storm Ridge band
	{800, 868}, -- Broken Cliffs shelf (700-800, Camp 3)
	{840, 760}, {880, 650}, {920, 560}, {950, 472}, -- cliff band
	{1000, 452}, {1080, 410}, {1150, 362}, {1200, 322}, -- Whispering Forest shelf (Camp 2)
	{1255, 255}, {1280, 226}, {1350, 206}, -- Camp 1 shelf (1280-1350); the falls cut their own cliff
	{1440, 140}, {1540, 78}, {1640, 36}, -- Green Valley meadows
	{1900, 26}, {2060, 30}, {2200, 85}, {2330, 205}, {2400, 265}, {3400, 380}, -- valley floor, rim
}

-- Region boundaries by re (outer edge inclusive).
C.REGION = { valley = 1215, forest = 945, cliffs = 705, storm = 300 }

-- Summit spire: 4 arêtes via a superellipse metric (p < 2) inside SPIRE.outer.
C.SPIRE = { p = 1.25, angle = 0.3, inner = 230, outer = 330, norm = 1.12 }

-- Sub-peaks that break the radial symmetry (additive cones, placed off the main route).
C.PEAKS = {
	{ name = "Stormhorn", theta = 5.55, re = 610, height = 260, radius = 170 },
	{ name = "RuinTooth", theta = 2.25, re = 440, height = 170, radius = 100 },
	{ name = "WestShoulder", theta = 4.15, re = 780, height = 110, radius = 190 },
}

C.FALL = { theta = 1.78, lipY = 326, poolY = 214, bowlHalf = 0.075, lipOuter = 1213, lipCut = 28, reMin = 1125, reMax = 1310 }
C.CHASM = { theta = 0.40, reIn = 680, reOut = 975, floor = 450 }
C.LAKE = { x = 1133, z = 1587, radius = 190, level = 22, depth = 14 }

-- Main route, polar control points {theta, re, name?}. Theta keeps increasing (spiral).
C.ROUTE = {
	{0.00, 1700, "FootholdGate"}, {0.30, 1640}, {0.60, 1590}, {0.88, 1555}, {1.10, 1500},
	{1.25, 1455}, {1.08, 1410}, {1.35, 1375}, {1.65, 1330}, {1.92, 1300, "Camp1"},
	{2.06, 1278}, {1.97, 1245}, {2.12, 1218}, {2.00, 1198}, {2.20, 1180, "ForestEdge"},
	{2.50, 1150}, {2.90, 1110}, {3.30, 1075}, {3.70, 1045}, {4.05, 1025, "GiantTree"},
	{4.45, 1005}, {4.85, 990}, {5.20, 975, "Camp2"},
	{5.25, 962}, {5.85, 935}, {5.30, 905}, {5.85, 875}, {5.30, 845}, {5.85, 818},
	{6.15, 790}, {6.40, 770}, {6.68, 760, "ChasmBridge"}, {6.90, 752}, {7.00, 748, "Camp3"},
	{7.05, 720}, {7.65, 690}, {7.05, 658}, {7.65, 626}, {7.05, 594}, {7.65, 562},
	{8.00, 540}, {8.30, 520}, {8.55, 510, "StormRuin"}, {8.85, 500},
	{8.90, 478}, {9.55, 452}, {8.95, 425}, {9.60, 398}, {10.00, 380}, {10.30, 360},
	{10.50, 340, "Camp4"},
}
-- Summit spiral appended procedurally: walkable spiral, then a steep stair section to the crown.
C.SUMMIT_SPIRAL = {
	{ theta0 = 10.5, re0 = 330, theta1 = 19.4, re1 = 95, step = 0.3 },
	{ theta0 = 19.4, re0 = 95, theta1 = 25.6, re1 = 22, step = 0.3, name = "SummitStairs" },
}
C.GRADE = { default = 0.30, stairs = 0.62, summitStairs = 0.8 }

-- Circumferential ring trails (re), full loops.
C.RINGS = {
	{ name = "ValleyRing", re = 1640 },
	{ name = "ForestRing", re = 1080 },
	{ name = "CliffShelfRing", re = 765 },
	{ name = "RuinShelfRing", re = 510 },
	{ name = "StormShelfRing", re = 335 },
}

-- Short branch trails (polar control points).
C.BRANCHES = {
	{ name = "OverlookSpur", pts = { {2.20, 1180}, {2.02, 1190}, {1.88, 1195} } },
}

-- Flattened pads. height: "route" = main-route height at its waypoint, "h0" = natural, number = fixed.
C.PADS = {
	{ name = "Foothold", x = 0, z = 1880, radius = 300, blend = 90, height = 28, kind = 5 },
	{ name = "Camp1", theta = 1.92, re = 1300, radius = 46, blend = 24, height = "route", kind = 3 },
	{ name = "Camp2", theta = 5.20, re = 975, radius = 50, blend = 24, height = "route", kind = 3 },
	{ name = "Camp3", theta = 7.00, re = 748, radius = 44, blend = 20, height = "route", kind = 3 },
	{ name = "Camp4", theta = 10.50, re = 340, radius = 40, blend = 18, height = "route", kind = 3 },
	{ name = "FallsOverlook", theta = 1.88, re = 1195, radius = 20, blend = 10, height = "h0", kind = 4 },
	{ name = "GiantTree", theta = 4.05, re = 1025, radius = 40, blend = 16, height = "route", kind = 4 },
	{ name = "StormRuin", theta = 8.55, re = 510, radius = 44, blend = 16, height = "route", kind = 4 },
	{ name = "HeliLZ", theta = 15.10, re = 232, radius = 28, blend = 12, height = "route", kind = 4 },
	{ name = "SummitCrown", x = 0, z = 0, radius = 36, blend = 10, height = 2000, kind = 4 },
}

-- Water: river from the falls pool to the lake; creek feeding the falls lip.
C.RIVER = { pts = { {1.78, 1255}, {1.70, 1335}, {1.55, 1400}, {1.35, 1465}, {1.15, 1530}, {0.95, 1605}, {0.80, 1690}, {0.70, 1770}, {0.66, 1840} },
	halfWidth = 9, blend = 12, depth = 5, startLevel = 214 }
C.CREEK = { pts = { {2.30, 1080}, {2.12, 1125}, {1.95, 1160}, {1.78, 1187} }, halfWidth = 4.5, blend = 6, depth = 2.5, endLevel = 325 }
C.POOL = { theta = 1.78, re = 1222, radius = 30, bed = 203, level = 214 }

-- Terrain material colors (design/world-tokens.md).
C.MATERIAL_COLORS = {
	Grass = Color3.fromRGB(84, 176, 82),
	LeafyGrass = Color3.fromRGB(52, 128, 92),
	Ground = Color3.fromRGB(186, 150, 98),
	Mud = Color3.fromRGB(92, 70, 52),
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

-- Player movement (user-approved 2026-10-20): expedition pace, and a slope limit so the steep
-- bands can't be walked straight up (route max grade 38.7 deg; 50 deg ramps measured as blocked).
C.PLAYER = { walkSpeed = 12, maxSlope = 45 }

return C
