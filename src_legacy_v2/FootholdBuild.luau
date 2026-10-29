-- FootholdBuild: the home base (master.md §0.5 "Foothold", name PROPOSED).
-- buildCore (Gate C): summit-view terrace + spawn, central campfire plaza, Expedition Hall, avenue.
-- buildFull (Gate E): the remaining districts.
local B = {}

local F0 = Vector3.new(0, 28, 1880) -- pad centre (WorldConfig PADS.Foothold)

local function paint(x0, z0, x1, z1, y0, y1, mat)
	local T = workspace.Terrain
	local reg = Region3.new(Vector3.new(math.min(x0, x1), y0, math.min(z0, z1)), Vector3.new(math.max(x0, x1), y1, math.max(z0, z1))):ExpandToGrid(4)
	for _, from in ipairs({ Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Rock }) do
		T:ReplaceMaterial(reg, 4, from, mat)
	end
end
B.paint = paint

-- balustrade of stone posts with a cap rail between two points
local function balustrade(Kit, parent, a, b)
	local COL = Kit.COL
	local len = (b - a).Magnitude
	local n = math.max(2, math.floor(len / 5))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		Kit.part(parent, { Name = "Baluster", Size = Vector3.new(1.4, 3.2, 1.4), CFrame = CFrame.new(p + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	end
	local mid = (a + b) / 2
	Kit.part(parent, { Name = "Rail", Size = Vector3.new(2, 0.8, len + 1.4), CFrame = CFrame.lookAt(mid + Vector3.new(0, 3.5, 0), b + Vector3.new(0, 3.5, 0)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
end
B.balustrade = balustrade

-- porch: deck, posts and a lean-to roof in front of a building's door side
local function porch(Kit, parent, cf, w, d, h)
	local COL = Kit.COL
	Kit.part(parent, { Name = "PorchDeck", Size = Vector3.new(w, 0.8, d), CFrame = cf * CFrame.new(0, 0.4, -d / 2), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for _, x in ipairs({ -w / 2 + 1, -w / 6, w / 6, w / 2 - 1 }) do
		Kit.part(parent, { Name = "PorchPost", Size = Vector3.new(1.2, h, 1.2), CFrame = cf * CFrame.new(x, h / 2 + 0.8, -d + 0.8), Material = Enum.Material.Wood, Color = COL.timberDark })
	end
	Kit.part(parent, { Name = "PorchRoof", Size = Vector3.new(w + 2, 0.9, d + 1.5), CFrame = cf * CFrame.new(0, h + 1.4, -d / 2 + 0.2) * CFrame.Angles(math.rad(-12), 0, 0), Material = Enum.Material.WoodPlanks, Color = COL.timberDark })
end
B.porch = porch

function B.buildCore(Kit, Gen, Slice)
	local COL = Kit.COL
	local world = Kit.folder(workspace, "World")
	local regions = Kit.folder(world, "Regions")
	local root = regions:FindFirstChild("Foothold")
	if root then
		root:Destroy()
	end
	root = Kit.folder(regions, "Foothold")
	local core = Kit.folder(root, "Core")
	local y0 = F0.Y

	-- avenue: central plaza north to the trail gate (0, ~1501)
	paint(-9, 1500, 9, 1812, y0 - 8, y0 + 12, Enum.Material.Cobblestone)
	local P = _G.CC_PATHS
	local gate = P.main[1]
	paint(-8, gate[2] - 6, 8, 1500, gate[3] - 10, gate[3] + 8, Enum.Material.Ground)

	-- Summit-View Terrace (first-screenshot moment): raised stone terrace west of the avenue
	local tc = Vector3.new(-48, y0, 1650)
	local tw, td, th = 64, 34, 6
	local terrace = Kit.model(core, "SummitViewTerrace")
	Kit.part(terrace, { Name = "Platform", Size = Vector3.new(tw, th, td), CFrame = CFrame.new(tc + Vector3.new(0, th / 2 - 1, 0)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	Kit.part(terrace, { Name = "Paving", Size = Vector3.new(tw - 2, 0.4, td - 2), CFrame = CFrame.new(tc + Vector3.new(0, th - 0.8, 0)), Material = Enum.Material.Slate, Color = COL.masonry })
	local top = y0 + th - 1
	local function tp(x, z)
		return tc + Vector3.new(x, th - 1, z)
	end
	balustrade(Kit, terrace, tp(-tw / 2 + 1, -td / 2 + 1), tp(tw / 2 - 1, -td / 2 + 1)) -- north edge faces the summit
	balustrade(Kit, terrace, tp(-tw / 2 + 1, -td / 2 + 1), tp(-tw / 2 + 1, td / 2 - 1))
	balustrade(Kit, terrace, tp(tw / 2 - 1, -td / 2 + 1), tp(tw / 2 - 1, td / 2 - 10))
	-- steps down to the avenue on the east side (south part)
	for k = 0, 5 do
		Kit.part(terrace, { Name = "Step", Size = Vector3.new(3, th - 1 - k, 10), CFrame = CFrame.new(tc + Vector3.new(tw / 2 + 1.5 + k * 3, (th - 1 - k) / 2 - 0.5, td / 2 - 5)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	end
	Slice.telescope(Kit, terrace, tp(0, -td / 2 + 5), Vector3.new(0, 0.35, -1).Unit)
	for _, x in ipairs({ -16, 16 }) do
		Kit.bench(terrace, CFrame.lookAt(tp(x, -td / 2 + 8), tp(x, -td / 2 - 10)))
		Kit.lantern(terrace, tp(x * 1.7, -td / 2 + 2.5), 7)
	end
	Kit.sign(terrace, CFrame.new(tp(-tw / 2 + 6, td / 2 - 4)), { { "Summit View", math.rad(-90) } }, 8)
	-- spawn on the terrace, facing the summit
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.CFrame = CFrame.lookAt(tp(0, 4) + Vector3.new(0, 0.5, 0), Vector3.new(0, top + 0.5, 0))
		spawn.Material = Enum.Material.Slate
		spawn.Color = COL.masonry
		spawn.Transparency = 0
		local d = spawn:FindFirstChildOfClass("Decal")
		if d then
			d:Destroy()
		end
	end

	-- central campfire plaza
	local plaza = Kit.model(core, "CampfirePlaza")
	Kit.campfire(plaza, F0)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local p = F0 + Vector3.new(math.cos(a) * 15, 0, math.sin(a) * 15)
		local log = Kit.part(plaza, { Name = "LogSeat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 2, 2), CFrame = CFrame.lookAt(p + Vector3.new(0, 1, 0), F0 + Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Wood, Color = COL.timberDark })
		log.Name = "LogSeat"
	end
	for k = 0, 7 do
		local a = (k + 0.5) / 8 * math.pi * 2
		Kit.lantern(plaza, F0 + Vector3.new(math.cos(a) * 58, 0, math.sin(a) * 58), 9, k % 2 == 0)
	end

	-- Expedition Hall: big timber hall on the west of the plaza, facing east
	local hallPos = F0 + Vector3.new(-128, 1.4, -6)
	local hallCF = CFrame.lookAt(hallPos, hallPos + Vector3.new(1, 0, 0))
	local hall = Kit.cabin(core, hallCF, 48, 32, 18, { name = "ExpeditionHall", doorWidth = 8, roofRise = 20 })
	porch(Kit, hall, hallCF * CFrame.new(0, -1.2, -16), 30, 8, 10)
	Kit.sign(core, CFrame.lookAt(hallPos + Vector3.new(30, -1.4, -14), hallPos + Vector3.new(31, -1.4, -14)), { { "Expedition Hall", 0 } }, 10)

	-- avenue lanterns
	for z = 1530, 1790, 40 do
		for _, x in ipairs({ -11, 11 }) do
			Kit.lantern(core, Vector3.new(x, Gen.heightAt(x, z) - 0.2, z), 8, (z / 40) % 2 == 0 and x > 0)
		end
	end
	return { ok = true }
end

-- dirt/cobble path between two ground points, painted into the terrain surface
local function paintPath(a, b, width, mat)
	local T = workspace.Terrain
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local n = math.max(1, math.floor(d.Magnitude / 4))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		local reg = Region3.new(p - Vector3.new(width / 2, 6, width / 2), p + Vector3.new(width / 2, 3, width / 2)):ExpandToGrid(4)
		for _, from in ipairs({ Enum.Material.Grass, Enum.Material.LeafyGrass }) do
			T:ReplaceMaterial(reg, 4, from, mat)
		end
	end
end
B.paintPath = paintPath

-- market stall: four posts, counter, sloped striped awning (palette accents)
local function stall(Kit, parent, cf, awning)
	local C = Kit.COL
	local m = Kit.model(parent, "MarketStall")
	for _, x in ipairs({ -5, 5 }) do
		for _, z in ipairs({ -3, 3 }) do
			Kit.part(m, { Name = "Post", Size = Vector3.new(0.8, (z < 0) and 9 or 7.5, 0.8), CFrame = cf * CFrame.new(x, ((z < 0) and 9 or 7.5) / 2, z), Material = Enum.Material.Wood, Color = C.timberDark })
		end
	end
	Kit.part(m, { Name = "Counter", Size = Vector3.new(11, 3.2, 2.4), CFrame = cf * CFrame.new(0, 1.6, -2.6), Material = Enum.Material.WoodPlanks, Color = C.timber })
	for k = 0, 4 do
		Kit.part(m, { Name = "Awning", Size = Vector3.new(2.4, 0.4, 8.4), CFrame = cf * CFrame.new(-4.8 + k * 2.4, 8.4, 0) * CFrame.Angles(math.rad(10), 0, 0), Material = Enum.Material.Fabric, Color = (k % 2 == 0) and awning or C.moon })
	end
	-- goods: crates and produce baskets
	for k = 0, 2 do
		Kit.part(m, { Name = "Crate", Size = Vector3.new(2, 2, 2), CFrame = cf * CFrame.new(-3.5 + k * 3.5, 4.2, -2.6) * CFrame.Angles(0, k * 0.3, 0), Material = Enum.Material.WoodPlanks, Color = C.timber })
		local fruit = Kit.part(m, { Name = "Goods", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, CFrame = cf * CFrame.new(-3.5 + k * 3.5, 5.5, -2.6), Material = Enum.Material.SmoothPlastic, Color = ({ C.lantern, C.meadow, C.golden })[k + 1] })
		Kit.decor(fruit)
	end
	return m
end

-- player cabin on a stone terrace with a fenced habitat yard on the outer side (master.md §0.5/§7)
local function playerCabin(Kit, Gen, parent, pos, facing, idx)
	local C = Kit.COL
	local m = Kit.model(parent, "PlayerCabin_" .. idx)
	local outward = -facing
	local right = facing:Cross(Vector3.yAxis).Unit
	local terraceH = 2.5 + (idx % 2) * 2.5 -- alternating terrace heights
	local tcf = CFrame.lookAt(pos, pos + facing)
	Kit.part(m, { Name = "Terrace", Size = Vector3.new(30, terraceH + 2, 26), CFrame = tcf * CFrame.new(0, terraceH / 2 - 1, 2), Material = Enum.Material.Cobblestone, Color = C.masonry })
	for k = 0, math.floor(terraceH / 1.2) - 1 do
		Kit.part(m, { Name = "Step", Size = Vector3.new(8, 1.2, 2), CFrame = tcf * CFrame.new(0, 0.6 + k * 1.2 - 0.6, -11 - (math.floor(terraceH / 1.2) - k) * 2 + 2), Material = Enum.Material.Cobblestone, Color = C.masonry })
	end
	local top = pos + Vector3.new(0, terraceH, 0)
	Kit.cabin(m, CFrame.lookAt(top + Vector3.new(0, 1.4, 0) + outward * 2, top + Vector3.new(0, 1.4, 0) + outward * 2 + facing), 16, 13, 8, { name = "Cabin", doorWidth = 4 })
	Kit.lantern(m, top - facing * -10 + right * 7, 6)
	-- habitat yard behind the cabin
	local yc = pos + outward * 30
	yc = Vector3.new(yc.X, Gen.heightAt(yc.X, yc.Z), yc.Z)
	local pts = {}
	for k = 0, 10 do
		local a = math.pi * (k / 10) - math.pi / 2
		local d = right * math.sin(a) * 15 + outward * math.cos(a) * 12
		local p = yc + d
		pts[#pts + 1] = Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
	end
	Kit.fence(m, pts, 3)
	Kit.place(m, "TreeRound", yc + outward * 4 + right * 6, idx, 1.3, C.leafLight)
	Kit.place(m, "Bush", yc - right * 7, idx, 1.4, C.meadow)
	Kit.place(m, ({ "FlowersGold", "FlowersTurq", "FlowersMoon" })[idx % 3 + 1], yc + outward * 6 - right * 3, idx, 1.3)
	local trough = Kit.part(m, { Name = "Trough", Size = Vector3.new(5, 1.4, 2), CFrame = CFrame.lookAt(yc + Vector3.new(0, 0.7, 0), yc + Vector3.new(0, 0.7, 0) + right), Material = Enum.Material.WoodPlanks, Color = C.timber })
	Kit.decor(trough, true)
	m:SetAttribute("CabinSlot", idx)
	return m
end

function B.buildFull(Kit, Gen)
	local C = Kit.COL
	local root = Kit.folder(Kit.folder(Kit.folder(workspace, "World"), "Regions"), "Foothold")
	local old = root:FindFirstChild("Districts")
	if old then
		old:Destroy()
	end
	local dist = Kit.folder(root, "Districts")
	local y0 = F0.Y
	local function g(x, z)
		return Vector3.new(x, Gen.heightAt(x, z), z)
	end
	local function facingTo(p, q)
		local d = Vector3.new(q.X - p.X, 0, q.Z - p.Z)
		return d.Unit
	end

	-- Hall of Wonders: south of the plaza, facing north up the avenue (collection showcase)
	local how = Kit.folder(dist, "HallOfWonders")
	local hp = g(0, 2012) + Vector3.new(0, 1.4, 0)
	local hcf = CFrame.lookAt(hp, hp + Vector3.new(0, 0, -1))
	local hall = Kit.cabin(how, hcf, 56, 34, 18, { name = "HallOfWonders", doorWidth = 10, roofRise = 18, roofColor = C.slate })
	for _, w in ipairs(hall:GetChildren()) do
		if w.Name:match("^Wall") or w.Name == "Lintel" or w.Name == "Gable" then
			w.Material = Enum.Material.Cobblestone
			w.Color = C.masonry
		end
	end
	for k = -2, 2 do
		local cp = (hcf * CFrame.new(k * 9.5, 0, -22)).Position
		Kit.part(how, { Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 3.4, 3.4), CFrame = CFrame.new(cp + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = C.moon })
	end
	Kit.part(how, { Name = "Portico", Size = Vector3.new(50, 2, 10), CFrame = hcf * CFrame.new(0, 21, -21), Material = Enum.Material.Limestone, Color = C.moon })
	for k = 0, 2 do
		Kit.part(how, { Name = "Step", Size = Vector3.new(48 - k * 4, 1.2, 4), CFrame = hcf * CFrame.new(0, 0.6 - k * 1.2 + 1.2, -19 - k * 3), Material = Enum.Material.Limestone, Color = C.moon })
	end
	-- display plinths inside (empty: creatures arrive with the gameplay phases)
	for _, x in ipairs({ -18, -6, 6, 18 }) do
		for _, z in ipairs({ -4, 8 }) do
			local pp = (hcf * CFrame.new(x, 2.4, z)).Position
			Kit.part(how, { Name = "Plinth", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 5, 5), CFrame = CFrame.new(pp) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = C.moon })
			local glow = Kit.part(how, { Name = "PlinthGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 4.4, 4.4), CFrame = CFrame.new(pp + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = C.lantern })
			Kit.decor(glow)
		end
	end
	Kit.sign(how, CFrame.lookAt(hp + Vector3.new(30, -1.4, -26), hp + Vector3.new(31, -1.4, -26)), { { "Hall of Wonders", 0 } }, 10)
	paintPath(g(0, 1925), g(0, 1985), 10, Enum.Material.Cobblestone)

	-- Gear Forge: north-east of the plaza
	local forge = Kit.folder(dist, "GearForge")
	local fp = g(110, 1815) + Vector3.new(0, 1.4, 0)
	local fcf = CFrame.lookAt(fp, Vector3.new(F0.X, fp.Y, F0.Z))
	local fb = Kit.cabin(forge, fcf, 30, 22, 12, { name = "GearForge", doorWidth = 8, roofColor = C.slate })
	local hearth = (fcf * CFrame.new(-10, 0, -15)).Position
	Kit.part(forge, { Name = "Hearth", Size = Vector3.new(8, 6, 6), CFrame = CFrame.lookAt(hearth + Vector3.new(0, 1.6, 0), hearth + Vector3.new(0, 1.6, 0) - fcf.LookVector), Material = Enum.Material.Cobblestone, Color = C.masonry })
	local coals = Kit.part(forge, { Name = "Coals", Size = Vector3.new(5, 2, 1), CFrame = CFrame.lookAt(hearth + Vector3.new(0, 2.2, 0) + fcf.LookVector * 3, hearth + Vector3.new(0, 2.2, 0) + fcf.LookVector * 4), Material = Enum.Material.Neon, Color = C.lantern })
	Kit.decor(coals)
	local fire = Instance.new("Fire")
	fire.Size, fire.Heat, fire.Color, fire.SecondaryColor = 4, 6, C.lantern, Color3.fromRGB(255, 120, 40)
	fire.Parent = coals
	local fl = Instance.new("PointLight")
	fl.Color, fl.Range, fl.Brightness = C.lantern, 22, 2
	fl.Parent = coals
	local anvil = (fcf * CFrame.new(2, 0, -19)).Position
	Kit.part(forge, { Name = "AnvilBase", Size = Vector3.new(2, 2.4, 2), CFrame = CFrame.new(anvil + Vector3.new(0, 1.2, 0)), Material = Enum.Material.Wood, Color = C.timberDark })
	Kit.part(forge, { Name = "Anvil", Size = Vector3.new(3.4, 1.2, 1.6), CFrame = CFrame.new(anvil + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0.4, 0), Material = Enum.Material.Metal, Color = C.slate })
	Kit.sign(forge, CFrame.lookAt(fp + Vector3.new(-18, -1.4, -10), fp + Vector3.new(-17, -1.4, -10)), { { "Gear Forge", 0 } }, 8)
	paintPath(g(40, 1860), g(fp.X - 12, fp.Z + 4), 8, Enum.Material.Cobblestone)

	-- Provisions Market: stalls along the east side of the avenue
	local market = Kit.folder(dist, "ProvisionsMarket")
	local awnings = { C.golden, C.turquoise, C.meadow, C.lantern }
	for k = 0, 3 do
		local sp = g(28, 1705 + k * 24)
		stall(Kit, market, CFrame.lookAt(sp, sp + Vector3.new(-1, 0, 0)), awnings[k + 1])
	end
	Kit.sign(market, CFrame.new(g(14, 1692)), { { "Provisions Market", math.rad(90) } }, 10)
	paintPath(g(12, 1700), g(22, 1790), 8, Enum.Material.Cobblestone)

	-- Garage (ATV launch, master.md §0.5): open-front shed south-east of the plaza
	local garage = Kit.folder(dist, "Garage")
	local gp = g(118, 1992)
	local gcf = CFrame.lookAt(gp, Vector3.new(F0.X, gp.Y, F0.Z))
	Kit.part(garage, { Name = "Slab", Size = Vector3.new(34, 1, 22), CFrame = gcf * CFrame.new(0, 0.1, 0), Material = Enum.Material.Concrete, Color = C.masonry })
	Kit.part(garage, { Name = "BackWall", Size = Vector3.new(34, 12, 1), CFrame = gcf * CFrame.new(0, 6.5, 11), Material = Enum.Material.WoodPlanks, Color = C.timber })
	for _, s in ipairs({ -1, 1 }) do
		Kit.part(garage, { Name = "SideWall", Size = Vector3.new(1, 12, 22), CFrame = gcf * CFrame.new(s * 17, 6.5, 0), Material = Enum.Material.WoodPlanks, Color = C.timber })
	end
	for _, x in ipairs({ -8.5, 0, 8.5 }) do
		Kit.part(garage, { Name = "FrontPost", Size = Vector3.new(1.2, 12, 1.2), CFrame = gcf * CFrame.new(x, 6.5, -11), Material = Enum.Material.Wood, Color = C.timberDark })
	end
	Kit.part(garage, { Name = "Roof", Size = Vector3.new(37, 1.2, 26), CFrame = gcf * CFrame.new(0, 13.3, 0) * CFrame.Angles(math.rad(6), 0, 0), Material = Enum.Material.WoodPlanks, Color = C.timberDark })
	for k = 0, 2 do
		Kit.part(garage, { Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 2.4, 2.4), CFrame = gcf * CFrame.new(-13 + k * 2.6, 1.6, 8) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = (k == 1) and C.lantern or C.slate })
	end
	Kit.part(garage, { Name = "ToolRack", Size = Vector3.new(8, 5, 0.6), CFrame = gcf * CFrame.new(8, 6, 10.3), Material = Enum.Material.WoodPlanks, Color = C.timberDark })
	Kit.sign(garage, CFrame.lookAt(gp + Vector3.new(0, 0, 0) + gcf.LookVector * 16 + gcf.RightVector * 14, gp + gcf.LookVector * 17 + gcf.RightVector * 14), { { "Garage", math.rad(90) } }, 7)
	-- ATV trail start: south-east between the outer cabins and the base pad, toward the open valley floor
	paintPath(g(gp.X + 16, gp.Z + 6), g(320, 2150), 9, Enum.Material.Ground)

	-- Base Pad (helicopter arrival auto-banks, master.md §0.5)
	local hp2 = g(190, 2088)
	local pad = Kit.folder(dist, "BasePad")
	Kit.part(pad, { Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 50, 50), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Concrete, Color = C.slate })
	Kit.part(pad, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 44, 44), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = C.golden })
	Kit.part(pad, { Name = "RingInner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 40, 40), CFrame = CFrame.new(hp2 + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Concrete, Color = C.slate })
	for _, d in ipairs({ 0, -5.5, 5.5 }) do
		Kit.part(pad, { Name = "H", Size = (d == 0) and Vector3.new(11, 1.7, 2.8) or Vector3.new(2.8, 1.7, 17), CFrame = CFrame.new(hp2 + Vector3.new(d, 0.5, 0)), Material = Enum.Material.SmoothPlastic, Color = C.golden })
	end
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local l = Kit.part(pad, { Name = "LandingLight", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.6, 1.6), CFrame = CFrame.new(hp2 + Vector3.new(math.cos(a) * 26, 0.6, math.sin(a) * 26)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = C.lantern })
		Kit.decor(l)
	end
	local ws = hp2 + Vector3.new(32, 0, -14)
	Kit.part(pad, { Name = "WindsockPole", Size = Vector3.new(0.6, 14, 0.6), CFrame = CFrame.new(ws + Vector3.new(0, 7, 0)), Material = Enum.Material.Metal, Color = C.slate })
	for k = 0, 3 do
		local seg = Kit.part(pad, { Name = "Windsock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 2.2 - k * 0.35, 2.2 - k * 0.35), CFrame = CFrame.new(ws + Vector3.new(1.4 + k * 2, 13.4 - k * 0.3, 0)), Material = Enum.Material.Fabric, Color = (k % 2 == 0) and C.lantern or C.moon })
		Kit.decor(seg, true)
	end
	Kit.sign(pad, CFrame.new(hp2 + Vector3.new(-30, 0, -18)), { { "Base Pad", math.rad(-30) } }, 7)
	paintPath(g(60, 1950), g(hp2.X - 26, hp2.Z - 10), 8, Enum.Material.Cobblestone)

	-- Hatchery (eggs hatch at base, master.md §0.5): round stone nursery with an egg yard
	local hat = Kit.folder(dist, "Hatchery")
	local hc = g(-115, 1985)
	for k = 0, 15 do
		local a0, a1 = k / 16 * math.pi * 2, (k + 1) / 16 * math.pi * 2
		if k ~= 3 then -- doorway facing the plaza
			local p0 = hc + Vector3.new(math.cos(a0) * 14, 0, math.sin(a0) * 14)
			local p1 = hc + Vector3.new(math.cos(a1) * 14, 0, math.sin(a1) * 14)
			local mid = (p0 + p1) / 2
			Kit.part(hat, { Name = "Wall", Size = Vector3.new(1.4, 10, (p1 - p0).Magnitude + 0.4), CFrame = CFrame.lookAt(mid + Vector3.new(0, 5, 0), p1 + Vector3.new(0, 5, 0)), Material = Enum.Material.Cobblestone, Color = C.masonry })
		end
	end
	for k = 0, 5 do
		local r = 17 - k * 2.8
		Kit.part(hat, { Name = "Roof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, r * 2, r * 2), CFrame = CFrame.new(hc + Vector3.new(0, 10.5 + k * 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = (k % 2 == 0) and C.timberDark or C.timber })
	end
	local lamp = Kit.part(hat, { Name = "RoofLantern", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.4, CFrame = CFrame.new(hc + Vector3.new(0, 20.5, 0)), Material = Enum.Material.Neon, Color = C.lantern })
	Kit.decor(lamp)
	local il = Instance.new("PointLight")
	il.Color, il.Range, il.Brightness = C.lantern, 24, 1.6
	il.Parent = Kit.decor(Kit.part(hat, { Name = "InteriorLight", Size = Vector3.one, CFrame = CFrame.new(hc + Vector3.new(0, 7, 0)), Transparency = 1 }))
	local eggCols = { C.turquoise, C.indigo, C.golden, C.violet }
	for k = 0, 3 do
		local a = (k + 0.5) / 4 * math.pi * 2
		local np = hc + Vector3.new(math.cos(a) * 7, 0, math.sin(a) * 7)
		local nest = Kit.part(hat, { Name = "Nest", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 5, 5), CFrame = CFrame.new(np + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Grass, Color = C.golden })
		-- egg: a block with a sphere mesh gives a true ellipsoid (Ball parts force uniform size)
		local egg = Kit.part(hat, { Name = "Egg", Size = Vector3.new(3, 3.8, 3), CFrame = CFrame.new(np + Vector3.new(0, 2.6, 0)), Material = Enum.Material.SmoothPlastic, Color = eggCols[k + 1] })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = egg
		Kit.decor(egg, true)
	end
	Kit.sign(hat, CFrame.new(hc + Vector3.new(16, 0, -14)), { { "Hatchery", math.rad(-45) } }, 7)
	paintPath(g(-40, 1925), g(hc.X + 10, hc.Z - 10), 8, Enum.Material.Cobblestone)

	-- terraced player cabins with habitat yards: west arc and east arc around the plaza
	local cabins = Kit.folder(dist, "Cabins")
	local slots = { 150, 170, 190, 210, 230, 330, 350, 10, 30 }
	for i, deg in ipairs(slots) do
		local a = math.rad(deg)
		local pos = g(F0.X + math.cos(a) * 238, F0.Z + math.sin(a) * 238)
		local facing = facingTo(pos, F0)
		playerCabin(Kit, Gen, cabins, pos, facing, i)
		paintPath(g(F0.X + math.cos(a) * 70, F0.Z + math.sin(a) * 70), pos - facing * -14, 6, Enum.Material.Ground)
	end

	-- shade trees and flower beds that frame the plaza (kept out of the summit sightline)
	local green = Kit.folder(dist, "Greenery")
	local rng = Random.new(5)
	local footprints = { { 0, 2012, 40 }, { 118, 1992, 30 }, { -115, 1985, 30 }, { 110, 1815, 30 }, { -128, 1874, 40 }, { 28, 1740, 45 }, { -48, 1650, 42 } }
	local function blocked(x, z)
		for _, f in ipairs(footprints) do
			if (x - f[1]) ^ 2 + (z - f[2]) ^ 2 < f[3] * f[3] then
				return true
			end
		end
		return false
	end
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		local deg = math.deg(a) % 360
		local r = 135 + rng:NextNumber(-10, 10)
		local x, z = F0.X + math.cos(a) * r, F0.Z + math.sin(a) * r
		if not (deg > 240 and deg < 300) and not blocked(x, z) then -- north = toward the summit; keep clear
			local p = g(x, z)
			Kit.place(green, (k % 3 == 0) and "TreeTall" or "TreeRound", p - Vector3.new(0, 0.5, 0), a, rng:NextNumber(1.4, 1.9), (k % 2 == 0) and C.leafLight or C.meadow)
		end
	end
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local p = g(F0.X + math.cos(a) * 30, F0.Z + math.sin(a) * 30)
		Kit.place(green, ({ "FlowersGold", "FlowersTurq", "FlowersMoon" })[k % 3 + 1], p - Vector3.new(0, 0.2, 0), a, 1.2)
	end
	return { cabins = #slots }
end

return B
