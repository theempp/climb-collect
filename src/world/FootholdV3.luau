-- FootholdV3: the home base on the dry foothills (V3 plan P3; master.md §0.6, all placements PROPOSED).
-- Summit-view amphitheater spawn, central campfire plaza (r 125), Route Board, 4 trailhead gates styled by route,
-- Lookout Tower landmark, decorative cable-car station, Hall of Wonders, Gear Forge, Provisions Market, Garage +
-- ATV trail start, Base Pad, Hatchery, 9 terraced player cabins with habitat yards.
-- Layout is relative to the Foothold pad: f = toward the summit, r = right when facing it.
local C = require(script.Parent.WorldConfig)
local V = {}

local UP = Vector3.yAxis
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- route identity (PROPOSED): colors are existing tokens tied to each route's character, intensity as pips
local ROUTE_STYLE = {
	Shepherd = { col = "meadow", pips = 1 },
	Waterfall = { col = "turquoise", pips = 2 },
	Ledge = { col = "sandstone", pips = 3 },
	Spire = { col = "ice", pips = 4 },
}
V.ROUTE_STYLE = ROUTE_STYLE

local function stall(Kit, parent, cf, awning)
	local COL = Kit.COL
	local m = Kit.model(parent, "MarketStall")
	for _, x in ipairs({ -5, 5 }) do
		for _, z in ipairs({ -3, 3 }) do
			local h = (z < 0) and 9 or 7.5
			Kit.part(m, { Name = "Post", Size = Vector3.new(0.8, h, 0.8), CFrame = cf * CFrame.new(x, h / 2, z), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
	end
	Kit.part(m, { Name = "Counter", Size = Vector3.new(11, 3.2, 2.4), CFrame = cf * CFrame.new(0, 1.6, -2.6), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for k = 0, 4 do
		Kit.part(m, { Name = "Awning", Size = Vector3.new(2.4, 0.4, 8.4), CFrame = cf * CFrame.new(-4.8 + k * 2.4, 8.4, 0) * CFrame.Angles(math.rad(10), 0, 0), Material = Enum.Material.Fabric, Color = (k % 2 == 0) and awning or COL.moon })
	end
	for k = 0, 2 do
		Kit.part(m, { Name = "Crate", Size = Vector3.new(2, 2, 2), CFrame = cf * CFrame.new(-3.5 + k * 3.5, 4.2, -2.6) * CFrame.Angles(0, k * 0.3, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	end
	return m
end

-- pips: small stone blocks on a gate/board, one per intensity step (shape, not only color)
local function pips(Kit, parent, cf, n, col)
	for k = 1, 4 do
		local on = k <= n
		local p = Kit.part(parent, {
			Name = on and "Pip" or "PipOff",
			Size = Vector3.new(1.4, 1.4, 0.6),
			CFrame = cf * CFrame.new((k - 2.5) * 2, 0, 0) * CFrame.Angles(0, 0, math.rad(45)),
			Material = on and Enum.Material.Neon or Enum.Material.Slate,
			Color = on and col or Kit.COL.slate,
		})
		Kit.decor(p)
	end
end

-- trailhead gate, styled per route so they read apart by silhouette
local function gate(Kit, parent, name, pos, facing, label)
	local COL = Kit.COL
	local st = ROUTE_STYLE[name]
	local col = COL[st.col]
	local m = Kit.model(parent, "Gate_" .. name)
	local cf = CFrame.lookAt(pos, pos + facing)
	if name == "Shepherd" then
		-- wide, low timber arch with flower boxes: welcoming
		for _, s in ipairs({ -1, 1 }) do
			Kit.part(m, { Name = "Post", Size = Vector3.new(1.6, 12, 1.6), CFrame = cf * CFrame.new(s * 9, 6, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
			Kit.part(m, { Name = "FlowerBox", Size = Vector3.new(4, 1.6, 2.4), CFrame = cf * CFrame.new(s * 11.5, 0.8, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
			Kit.place(m, "FlowersGold", (cf * CFrame.new(s * 11.5, 1.4, 0)).Position, 0, 0.6)
		end
		Kit.part(m, { Name = "Beam", Size = Vector3.new(22, 1.6, 2), CFrame = cf * CFrame.new(0, 12.4, 0), Material = Enum.Material.Wood, Color = COL.timber })
		Kit.part(m, { Name = "Board", Size = Vector3.new(14, 2.6, 0.5), CFrame = cf * CFrame.new(0, 10.2, -0.6), Material = Enum.Material.WoodPlanks, Color = col })
	elseif name == "Waterfall" then
		-- round stone arch with a turquoise banner
		for k = 0, 12 do
			local a = math.pi * k / 12
			Kit.part(m, { Name = "Voussoir", Size = Vector3.new(2.4, 2.4, 3), CFrame = cf * CFrame.new(math.cos(a) * 8, 6 + math.sin(a) * 9, 0) * CFrame.Angles(0, 0, a), Material = Enum.Material.Cobblestone, Color = COL.masonry })
		end
		for _, s in ipairs({ -1, 1 }) do
			Kit.part(m, { Name = "Pier", Size = Vector3.new(3, 6, 3.4), CFrame = cf * CFrame.new(s * 8, 3, 0), Material = Enum.Material.Cobblestone, Color = COL.masonry })
		end
		Kit.part(m, { Name = "Banner", Size = Vector3.new(3, 7, 0.3), CFrame = cf * CFrame.new(0, 9, 0.4), Material = Enum.Material.Fabric, Color = col })
	elseif name == "Ledge" then
		-- narrow timber frame with a gold fixed rope (wayfinding token) and a warning cairn
		for _, s in ipairs({ -1, 1 }) do
			Kit.part(m, { Name = "Post", Size = Vector3.new(1.2, 16, 1.2), CFrame = cf * CFrame.new(s * 3.2, 8, 0) * CFrame.Angles(0, 0, math.rad(-s * 4)), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
		Kit.part(m, { Name = "Lintel", Size = Vector3.new(9, 1.2, 1.2), CFrame = cf * CFrame.new(0, 15.6, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
		Kit.part(m, { Name = "Rope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 0.35, 0.35), CFrame = cf * CFrame.new(-3.6, 8, -6) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.lantern })
		Kit.part(m, { Name = "Board", Size = Vector3.new(6, 2.4, 0.4), CFrame = cf * CFrame.new(0, 13.4, -0.7), Material = Enum.Material.WoodPlanks, Color = col })
		Kit.place(m, "Cairn", (cf * CFrame.new(5.5, 0, -2)).Position, 0, 1)
	else
		-- Spire Ridge: tall dark slate monolith pair with an ice crystal: expert, stark
		for _, s in ipairs({ -1, 1 }) do
			Kit.part(m, { Name = "Monolith", Size = Vector3.new(2.6, 22, 3), CFrame = cf * CFrame.new(s * 4, 11, 0) * CFrame.Angles(0, 0, math.rad(-s * 6)), Material = Enum.Material.Slate, Color = COL.slate })
		end
		Kit.place(m, "CrystalIce", (cf * CFrame.new(0, 0, 1.5)).Position, 0, 0.8)
		Kit.part(m, { Name = "Board", Size = Vector3.new(6, 2.4, 0.4), CFrame = cf * CFrame.new(0, 17, -1.2), Material = Enum.Material.Slate, Color = col })
	end
	pips(Kit, m, cf * CFrame.new(0, 3.5, -2.2), st.pips, col)
	-- name + warning sign beside the gate (hard routes are optional and marked, LOCKED decision 14)
	local lines = { { label, 0 } }
	if st.pips >= 3 then
		lines[2] = { (st.pips == 4) and "EXPERT - exposed ridge" or "HARD - exposed ledges", 0 }
	else
		lines[2] = { (st.pips == 1) and "Beginner friendly" or "Moderate - stairs", 0 }
	end
	Kit.sign(m, cf * CFrame.new(-8, 0, -4) * CFrame.Angles(0, math.rad(180), 0), lines, 11)
	m:SetAttribute("Route", name)
	-- 1.6x so the four silhouettes read from the plaza (scaled about the gate base)
	m.WorldPivot = cf
	m:ScaleTo(1.6)
	return m
end

function V.build(Kit, Gen)
	local COL = Kit.COL
	local P = _G.CC_PATHS
	local pad = P.pads.Foothold
	local C0 = Vector3.new(pad.x, pad.y, pad.z)
	local f = flat(-C0).Unit -- toward the summit
	local r = f:Cross(UP).Unit
	local function at(df, dr)
		local p = C0 + f * df + r * dr
		return Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
	end
	local function face(p, q)
		return flat(q - p).Unit
	end
	local root = Kit.folder(Kit.folder(Kit.folder(workspace, "World"), "Regions"), "Foothold")
	for _, c in ipairs(root:GetChildren()) do
		c:Destroy()
	end
	local core = Kit.folder(root, "Core")
	local dist = Kit.folder(root, "Districts")
	-- paint a path into the foothill surface (dry grass / red earth / grass) between two ground points
	local function paintPath(a, b, width, mat)
		local T0 = workspace.Terrain
		local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local n = math.max(1, math.floor(d.Magnitude / 4))
		for i = 0, n do
			local p = a:Lerp(b, i / n)
			local reg = Region3.new(p - Vector3.new(width / 2, 6, width / 2), p + Vector3.new(width / 2, 3, width / 2)):ExpandToGrid(4)
			for _, from in ipairs({ Enum.Material.Salt, Enum.Material.Mud, Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground }) do
				if from ~= mat then
					T0:ReplaceMaterial(reg, 4, from, mat)
				end
			end
		end
	end

	-- central campfire plaza (radius 125: >= 3x the V2 plaza footprint)
	local plaza = at(10, 0)
	local T = workspace.Terrain
	for ring = 0, 125, 4 do
		local n = math.max(6, math.floor(ring * 0.8))
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local p = plaza + Vector3.new(math.cos(a) * ring, 0, math.sin(a) * ring)
			T:ReplaceMaterial(Region3.new(p - Vector3.new(3, 6, 3), p + Vector3.new(3, 3, 3)):ExpandToGrid(4), 4, Enum.Material.Salt, Enum.Material.Cobblestone)
		end
	end
	Kit.campfire(core, plaza)
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		local bp = plaza + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)
		Kit.bench(core, CFrame.lookAt(bp, plaza) * CFrame.Angles(0, math.rad(90), 0))
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		Kit.lantern(core, plaza + Vector3.new(math.cos(a) * 118, 0, math.sin(a) * 118), 8, k % 3 == 0)
	end

	-- summit-view amphitheater spawn: 6 curved stone tiers rising away from the mountain, spawn on top
	local amph = Kit.folder(core, "Amphitheater")
	local ac = at(-120, 0)
	for tier = 0, 5 do
		local rad = 40 + tier * 9
		for k = -7, 7 do
			local a = k / 7 * math.rad(65)
			local dir = (-f * math.cos(a) + r * math.sin(a))
			local p = ac + dir * rad
			local w = rad * math.rad(65) / 7 * 1.08
			Kit.part(amph, {
				Name = "Tier",
				Size = Vector3.new(w, 2.4 + tier * 2.4, 9.2),
				CFrame = CFrame.lookAt(Vector3.new(p.X, ac.Y + (2.4 + tier * 2.4) / 2 - 1, p.Z), Vector3.new(ac.X, ac.Y + (2.4 + tier * 2.4) / 2 - 1, ac.Z)),
				Material = Enum.Material.Cobblestone,
				Color = COL.masonry,
			})
		end
	end
	local spawnPos = ac - f * 86 + Vector3.new(0, 14.4, 0)
	local sp = workspace:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation")
	sp.Size = Vector3.new(10, 1, 10)
	sp.CFrame = CFrame.lookAt(spawnPos, spawnPos + f)
	sp.Anchored = true
	sp.Material = Enum.Material.Cobblestone
	sp.Color = COL.masonry
	sp.Transparency = 0
	sp.Duration = 0
	sp.Parent = workspace
	Kit.sign(amph, CFrame.lookAt(ac - f * 70 + r * 12 + Vector3.new(0, 12, 0), ac - f * 70 + r * 12 + Vector3.new(0, 12, 0) + r), { { "Foothold", 0 }, { "Summit 3,200 up", 0 } }, 9)
	paintPath(ac, plaza, 14, Enum.Material.Cobblestone)

	-- Route Board: stepped relief of the mountain on a round stone table, one pip row per route
	local board = Kit.folder(core, "RouteBoard")
	local bp = at(70, 0)
	Kit.part(board, { Name = "Table", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 26, 26), CFrame = CFrame.new(bp + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	local tiers = { { 11, "golden" }, { 9.5, "meadow" }, { 8, "forestTeal" }, { 6.5, "sandstone" }, { 5, "slate" } }
	for k, t in ipairs(tiers) do
		Kit.part(board, { Name = "Relief", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, t[1] * 2, t[1] * 2), CFrame = CFrame.new(bp + Vector3.new(0, 3 + k * 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = COL[t[2]] })
	end
	local spire = Kit.part(board, { Name = "ReliefSpire", Size = Vector3.new(3, 9, 3), CFrame = CFrame.new(bp + Vector3.new(0, 13.4, 0)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Glass, Color = COL.ice })
	Kit.decor(spire)
	local order = { "Shepherd", "Waterfall", "Ledge", "Spire" }
	for i, name in ipairs(order) do
		local st = ROUTE_STYLE[name]
		local cf = CFrame.lookAt(bp - f * 14 + r * ((i - 2.5) * 6) + Vector3.new(0, 1.5, 0), bp - f * 30 + r * ((i - 2.5) * 6) + Vector3.new(0, 1.5, 0))
		pips(Kit, board, cf * CFrame.new(0, 1.2, 0) * CFrame.new(0, 0, 0), st.pips, COL[st.col])
	end
	local function tile(nm, label, stars)
		return { label .. "  " .. stars .. (P.routes[nm] and "" or "  (coming soon)"), 0 }
	end
	Kit.sign(board, CFrame.lookAt(bp - f * 18 - r * 16, bp - f * 18 - r * 16 - f), { { "Route Board", 0 }, tile("Shepherd", "Shepherd's Road", "*"), tile("Waterfall", "Waterfall Stair", "**"), tile("Ledge", "Cliff Ledge Line", "***"), tile("Spire", "Spire Ridge", "****") }, 13)

	-- trailhead gates at each route's start, avenues from the plaza
	local gates = Kit.folder(core, "Gates")
	local labels = { Shepherd = "Shepherd's Road", Waterfall = "Waterfall Stair", Ledge = "Cliff Ledge Line", Spire = "Spire Ridge" }
	for _, name in ipairs(order) do
		local R = P.routes[name]
		local gp, dir
		if R then
			local g0 = R.pts[1]
			local g1 = R.pts[math.min(#R.pts, 12)]
			gp = Vector3.new(g0[1], g0[3], g0[2])
			dir = flat(Vector3.new(g1[1], 0, g1[2]) - Vector3.new(g0[1], 0, g0[2])).Unit
		else
			-- v5 gated route (not built): the gate stands at its V3 trailhead, closed
			for _, d in ipairs(C.ROUTES) do
				if d.name == name then
					local x0, z0 = Gen.toWorld(d.ctrl[1][1], d.ctrl[1][2])
					local x1, z1 = Gen.toWorld(d.ctrl[2][1], d.ctrl[2][2])
					gp = Vector3.new(x0, Gen.heightAt(x0, z0), z0)
					dir = flat(Vector3.new(x1 - x0, 0, z1 - z0)).Unit
				end
			end
		end
		local gm = gate(Kit, gates, name, gp, dir, labels[name])
		if not R then
			-- "Coming soon" (v5 first publish, user 2026-10-21): rope across the gate, timber barrier, sign
			local cf = CFrame.lookAt(gp, gp + dir)
			local cm = Kit.model(gm, "ComingSoon")
			for _, sg in ipairs({ -1, 1 }) do
				Kit.part(cm, { Name = "BarrierPost", Size = Vector3.new(1, 5, 1), CFrame = cf * CFrame.new(sg * 6, 2.5, -3), Material = Enum.Material.Wood, Color = COL.timberDark })
			end
			Kit.part(cm, { Name = "BarrierRail", Size = Vector3.new(13, 1, 0.6), CFrame = cf * CFrame.new(0, 3.8, -3), Material = Enum.Material.WoodPlanks, Color = COL.timber })
			Kit.part(cm, { Name = "BarrierRail", Size = Vector3.new(13, 1, 0.6), CFrame = cf * CFrame.new(0, 1.8, -3), Material = Enum.Material.WoodPlanks, Color = COL.timber })
			Kit.sign(cm, cf * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(180), 0), { { labels[name], 0 }, { "Coming soon", 0 } }, 10)
			gm:SetAttribute("ComingSoon", true)
		end
		paintPath(plaza + flat(gp - plaza).Unit * 100, gp, (name == "Shepherd") and 12 or 8, Enum.Material.Cobblestone)
	end

	-- Lookout Tower: the landmark (stone shaft, timber crown, lantern) north-west of the plaza
	local tw = Kit.folder(dist, "LookoutTower")
	local tp = at(60, -150)
	for k = 0, 5 do
		local w = 16 - k * 1.2
		Kit.part(tw, { Name = "Shaft", Size = Vector3.new(w, 8, w), CFrame = CFrame.new(tp + Vector3.new(0, 4 + k * 8, 0)) * CFrame.Angles(0, math.rad(45 * (k % 2)) * 0.15, 0), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	end
	Kit.part(tw, { Name = "Deck", Size = Vector3.new(18, 1.2, 18), CFrame = CFrame.new(tp + Vector3.new(0, 49, 0)), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for _, x in ipairs({ -8, 8 }) do
		for _, z in ipairs({ -8, 8 }) do
			Kit.part(tw, { Name = "CrownPost", Size = Vector3.new(1.2, 9, 1.2), CFrame = CFrame.new(tp + Vector3.new(x, 54, z)), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
	end
	Kit.part(tw, { Name = "Roof", Size = Vector3.new(14, 14, 14), CFrame = CFrame.new(tp + Vector3.new(0, 62, 0)) * CFrame.Angles(math.rad(45), math.rad(45), 0), Material = Enum.Material.WoodPlanks, Color = COL.timberDark })
	local beacon = Kit.part(tw, { Name = "Beacon", Shape = Enum.PartType.Ball, Size = Vector3.one * 4, CFrame = CFrame.new(tp + Vector3.new(0, 52, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
	Kit.decor(beacon)
	local bl = Instance.new("PointLight")
	bl.Color, bl.Range, bl.Brightness = COL.lantern, 40, 2
	bl.Parent = beacon

	-- cable-car station (decorative landmark only; PROPOSED): station hut + two cables up toward Camp 1
	local cc = Kit.folder(dist, "CableCar")
	local cs = at(150, -95)
	local ccf = CFrame.lookAt(cs + Vector3.new(0, 1.4, 0), Vector3.new(P.pads.Camp1.x, cs.Y + 1.4, P.pads.Camp1.z))
	Kit.cabin(cc, ccf, 22, 16, 10, { name = "CableStation", doorWidth = 8, roofColor = COL.slate })
	local top = Vector3.new(P.pads.Camp1.x - 70, P.pads.Camp1.y + 30, P.pads.Camp1.z + 40)
	local a0 = (ccf * CFrame.new(0, 14, -9)).Position
	for _, s in ipairs({ -2.5, 2.5 }) do
		local a = a0 + ccf.RightVector * s
		local b = top + ccf.RightVector * s
		local n = 12
		for k = 0, n - 1 do
			local p0, p1 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
			local sag0 = -math.sin(math.pi * k / n) * 18
			local sag1 = -math.sin(math.pi * (k + 1) / n) * 18
			p0 += Vector3.new(0, sag0, 0)
			p1 += Vector3.new(0, sag1, 0)
			local cable = Kit.part(cc, { Name = "Cable", Size = Vector3.new(0.35, 0.35, (p1 - p0).Magnitude), CFrame = CFrame.lookAt((p0 + p1) / 2, p1), Material = Enum.Material.Metal, Color = COL.slate })
			Kit.decor(cable)
		end
	end
	for _, t in ipairs({ 0.33, 0.66 }) do
		local p = a0:Lerp(top, t)
		local gy = Gen.heightAt(p.X, p.Z)
		local h = p.Y - gy - math.sin(math.pi * t) * 18 + 3
		if h > 4 then
			Kit.part(cc, { Name = "Pylon", Size = Vector3.new(2.4, h, 2.4), CFrame = CFrame.new(p.X, gy + h / 2, p.Z), Material = Enum.Material.Metal, Color = COL.slate })
			Kit.part(cc, { Name = "PylonArm", Size = Vector3.new(8, 1, 1.4), CFrame = CFrame.lookAt(Vector3.new(p.X, gy + h, p.Z), Vector3.new(p.X, gy + h, p.Z) + ccf.RightVector), Material = Enum.Material.Metal, Color = COL.slate })
		end
	end
	local car = Kit.part(cc, { Name = "Gondola", Size = Vector3.new(5, 5, 6), CFrame = CFrame.new(a0:Lerp(top, 0.2) - Vector3.new(0, math.sin(math.pi * 0.2) * 18 + 4, 0)), Material = Enum.Material.WoodPlanks, Color = COL.lantern })
	Kit.decor(car)
	Kit.sign(cc, ccf * CFrame.new(13, -1.4, -4), { { "Cable Car (closed)", 0 } }, 10)

	-- Hall of Wonders (east, facing the plaza): stone hall with portico and 8 display plinths
	local how = Kit.folder(dist, "HallOfWonders")
	local hp = at(0, 180) + Vector3.new(0, 1.4, 0)
	local hcf = CFrame.lookAt(hp, Vector3.new(plaza.X, hp.Y, plaza.Z))
	local hall = Kit.cabin(how, hcf, 56, 34, 18, { name = "HallOfWonders", doorWidth = 10, roofRise = 18, roofColor = COL.slate })
	for _, w in ipairs(hall:GetChildren()) do
		if w.Name:match("^Wall") or w.Name == "Lintel" or w.Name == "Gable" then
			w.Material = Enum.Material.Cobblestone
			w.Color = COL.masonry
		end
	end
	for k = -2, 2 do
		local cp = (hcf * CFrame.new(k * 9.5, 0, -22)).Position
		Kit.part(how, { Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 3.4, 3.4), CFrame = CFrame.new(cp + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = COL.moon })
	end
	Kit.part(how, { Name = "Portico", Size = Vector3.new(50, 2, 10), CFrame = hcf * CFrame.new(0, 21, -21), Material = Enum.Material.Limestone, Color = COL.moon })
	for _, x in ipairs({ -18, -6, 6, 18 }) do
		for _, z in ipairs({ -4, 8 }) do
			local pp = (hcf * CFrame.new(x, 2.4, z)).Position
			Kit.part(how, { Name = "Plinth", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 5, 5), CFrame = CFrame.new(pp) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = COL.moon })
		end
	end
	Kit.sign(how, hcf * CFrame.new(28, -1.4, -26), { { "Hall of Wonders", 0 } }, 10)
	paintPath(plaza + flat(hp - plaza).Unit * 120, hp, 10, Enum.Material.Cobblestone)

	-- Gear Forge (north-east)
	local forge = Kit.folder(dist, "GearForge")
	local fp = at(95, 165) + Vector3.new(0, 1.4, 0)
	local fcf = CFrame.lookAt(fp, Vector3.new(plaza.X, fp.Y, plaza.Z))
	Kit.cabin(forge, fcf, 30, 22, 12, { name = "GearForge", doorWidth = 8, roofColor = COL.slate })
	local hearth = (fcf * CFrame.new(-10, 0, -15)).Position
	Kit.part(forge, { Name = "Hearth", Size = Vector3.new(8, 6, 6), CFrame = CFrame.new(hearth + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	local coals = Kit.part(forge, { Name = "Coals", Size = Vector3.new(5, 2, 1), CFrame = CFrame.new(hearth + Vector3.new(0, 4.4, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
	Kit.decor(coals)
	Kit.sign(forge, fcf * CFrame.new(-18, -1.4, -10), { { "Gear Forge", 0 } }, 8)

	-- Provisions Market: four stalls on the south-east arc of the plaza
	local market = Kit.folder(dist, "ProvisionsMarket")
	local awn = { COL.golden, COL.turquoise, COL.meadow, COL.lantern }
	for k = 0, 3 do
		local a = math.rad(110 + k * 14)
		local p = plaza + (f * math.cos(a) + r * math.sin(a)) * 108
		p = Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
		stall(Kit, market, CFrame.lookAt(p, Vector3.new(plaza.X, p.Y, plaza.Z)), awn[k + 1])
	end

	-- Garage + ATV trail start (south-east, toward the open foothills)
	local garage = Kit.folder(dist, "Garage")
	local gp = at(-110, 200)
	local gcf = CFrame.lookAt(gp, Vector3.new(plaza.X, gp.Y, plaza.Z))
	Kit.part(garage, { Name = "Slab", Size = Vector3.new(34, 1, 22), CFrame = gcf * CFrame.new(0, 0.1, 0), Material = Enum.Material.Concrete, Color = COL.masonry })
	Kit.part(garage, { Name = "BackWall", Size = Vector3.new(34, 12, 1), CFrame = gcf * CFrame.new(0, 6.5, 11), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for _, s in ipairs({ -1, 1 }) do
		Kit.part(garage, { Name = "SideWall", Size = Vector3.new(1, 12, 22), CFrame = gcf * CFrame.new(s * 17, 6.5, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	end
	Kit.part(garage, { Name = "Roof", Size = Vector3.new(37, 1.2, 26), CFrame = gcf * CFrame.new(0, 13.3, 0) * CFrame.Angles(math.rad(6), 0, 0), Material = Enum.Material.WoodPlanks, Color = COL.timberDark })
	Kit.sign(garage, gcf * CFrame.new(14, 0, -16), { { "Garage / ATV", 0 } }, 8)
	paintPath(gp, at(-250, 330), 9, Enum.Material.Ground)

	-- Base Pad (helicopter arrival, auto-bank) south-west
	local padf = Kit.folder(dist, "BasePad")
	local hp2 = at(-150, -190)
	Kit.part(padf, { Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 50, 50), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Concrete, Color = COL.slate })
	Kit.part(padf, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 44, 44), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = COL.golden })
	Kit.part(padf, { Name = "RingInner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 40, 40), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Concrete, Color = COL.slate })
	for _, d in ipairs({ 0, -5.5, 5.5 }) do
		Kit.part(padf, { Name = "H", Size = (d == 0) and Vector3.new(11, 1.7, 2.8) or Vector3.new(2.8, 1.7, 17), CFrame = CFrame.new(hp2 + Vector3.new(d, 0.5, 0)), Material = Enum.Material.SmoothPlastic, Color = COL.golden })
	end
	Kit.sign(padf, CFrame.new(hp2 + r * 30), { { "Base Pad", 0 } }, 7)

	-- Hatchery (west): round stone nursery with four nests
	local hat = Kit.folder(dist, "Hatchery")
	local hc = at(-10, -180)
	for k = 0, 15 do
		local a0, a1 = k / 16 * math.pi * 2, (k + 1) / 16 * math.pi * 2
		if k ~= 4 then
			local p0 = hc + Vector3.new(math.cos(a0) * 14, 0, math.sin(a0) * 14)
			local p1 = hc + Vector3.new(math.cos(a1) * 14, 0, math.sin(a1) * 14)
			local mid = (p0 + p1) / 2
			Kit.part(hat, { Name = "Wall", Size = Vector3.new(1.4, 10, (p1 - p0).Magnitude + 0.4), CFrame = CFrame.lookAt(mid + Vector3.new(0, 5, 0), p1 + Vector3.new(0, 5, 0)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
		end
	end
	for k = 0, 5 do
		local rr = 17 - k * 2.8
		Kit.part(hat, { Name = "Roof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, rr * 2, rr * 2), CFrame = CFrame.new(hc + Vector3.new(0, 10.5 + k * 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = (k % 2 == 0) and COL.timberDark or COL.timber })
	end
	local eggCols = { COL.turquoise, COL.indigo, COL.golden, COL.violet }
	for k = 0, 3 do
		local a = (k + 0.5) / 4 * math.pi * 2
		local np = hc + Vector3.new(math.cos(a) * 7, 0, math.sin(a) * 7)
		local egg = Kit.part(hat, { Name = "Egg", Size = Vector3.new(3, 3.8, 3), CFrame = CFrame.new(np + Vector3.new(0, 2.6, 0)), Material = Enum.Material.SmoothPlastic, Color = eggCols[k + 1] })
		local sm = Instance.new("SpecialMesh")
		sm.MeshType = Enum.MeshType.Sphere
		sm.Parent = egg
		Kit.decor(egg, true)
	end
	Kit.sign(hat, CFrame.new(hc + r * 18 - f * 10), { { "Hatchery", 0 } }, 7)
	paintPath(plaza + flat(hc - plaza).Unit * 120, hc, 8, Enum.Material.Cobblestone)

	-- 9 terraced player cabins with habitat yards on the outer ring (south-east and south-west arcs)
	local cabins = Kit.folder(dist, "Cabins")
	local slots = { -150, -132, -114, -96, 96, 114, 132, 150, 168 }
	local n = 0
	for i, deg in ipairs(slots) do
		local a = math.rad(deg)
		local p = C0 + (f * math.cos(a) + r * math.sin(a)) * 235
		local pos = Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
		local facing = face(pos, plaza)
		local m = Kit.model(cabins, "PlayerCabin_" .. i)
		local tcf = CFrame.lookAt(pos, pos + facing)
		local th = 2.5 + (i % 2) * 2.5
		Kit.part(m, { Name = "Terrace", Size = Vector3.new(30, th + 2, 26), CFrame = tcf * CFrame.new(0, th / 2 - 1, 2), Material = Enum.Material.Cobblestone, Color = COL.masonry })
		local top = pos + Vector3.new(0, th, 0)
		Kit.cabin(m, CFrame.lookAt(top + Vector3.new(0, 1.4, 0) - facing * 2, top + Vector3.new(0, 1.4, 0) - facing * 2 + facing), 16, 13, 8, { name = "Cabin", doorWidth = 4 })
		local yc = pos - facing * 30
		local pts = {}
		for k = 0, 10 do
			local aa = math.pi * (k / 10) - math.pi / 2
			local rr = facing:Cross(UP).Unit
			local q = yc + rr * math.sin(aa) * 15 - facing * math.cos(aa) * 12
			pts[#pts + 1] = Vector3.new(q.X, Gen.heightAt(q.X, q.Z), q.Z)
		end
		Kit.fence(m, pts, 3)
		m:SetAttribute("CabinSlot", i)
		n += 1
		paintPath(plaza + flat(pos - plaza).Unit * 122, pos + facing * 14, 6, Enum.Material.Mud)
	end

	-- dry-foothill planting kept out of the summit sightline: scrub bushes, a few shade trees
	local green = Kit.folder(dist, "Greenery")
	local rng = Random.new(5)
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local dirv = f * math.cos(a) + r * math.sin(a)
		if math.cos(a) < 0.55 then -- skip the arc toward the summit
			local p = plaza + dirv * (140 + rng:NextNumber(-8, 8))
			p = Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
			if k % 3 == 0 then
				Kit.place(green, "TreeRound", p - Vector3.new(0, 0.5, 0), a, rng:NextNumber(1.3, 1.7), C.DRY.scrub)
			else
				Kit.place(green, "Bush", p - Vector3.new(0, 0.3, 0), a, rng:NextNumber(1.2, 1.8), C.DRY.scrub)
			end
		end
	end
	return { cabins = n, spawn = spawnPos }
end

return V
