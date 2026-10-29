-- ForestBuild: Whispering Forest (master.md §4: emerald/teal shadows, warm lantern gold, luminous indigo;
-- signature "Enormous enchanted tree / root arch"; §3 amber lanterns, iridescent mushrooms, ancient stone
-- ruins, glowing roots, floating particles). Dressing spec + authored landmarks.
local B = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

function B.dressSpec(Kit)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local clear = {}
	for _, n in ipairs({ "Camp2", "GiantTree" }) do
		local p = P.pads[n]
		clear[#clear + 1] = { p.x, p.z, n == "GiantTree" and 85 or 70 }
	end
	local ov = P.pads.FallsOverlook
	clear[#clear + 1] = { ov.x, ov.z, 45 }
	-- the falls bowl straddles the valley/forest boundary: keep it open from this side too
	local Gen = require(script.Parent.MountainGen)
	local lx, lz = Gen.toWorld(1.78, 1185)
	local px, pz = Gen.toWorld(1.78, 1222)
	clear[#clear + 1] = { lx, lz, 80 }
	clear[#clear + 1] = { px, pz, 110 }
	return {
		region = "WhisperingForest", re0 = 945, re1 = 1218, stride = 11, seed = 41,
		grove = { scale = 200, lo = -0.2, hi = 0.2 },
		items = {
			{ proto = "TreeTall", base = 0.09, groveBoost = 0.2, slopeMax = 1.1, scale = { 2.0, 3.2 }, colors = { C.forestTeal, C.meadow, C.forestTeal, C.leafLight } },
			{ proto = "Pine", base = 0.05, groveBoost = 0.1, slopeMax = 1.2, scale = { 2.0, 3.0 }, colors = { C.forestTeal } },
			{ proto = "TreeRound", base = 0.03, groveBoost = 0.05, slopeMax = 0.9, scale = { 1.8, 2.8 }, colors = { C.forestTeal, C.meadow } },
			{ proto = "Mushrooms", base = 0.025, groveBoost = 0.02, slopeMax = 0.7, scale = { 1.2, 2.2 } },
			{ proto = "Bush", base = 0.04, groveBoost = 0.04, slopeMax = 1.0, scale = { 1.5, 2.6 }, colors = { C.forestTeal, C.leafLight } },
			{ proto = "FlowersMoon", base = 0.012, slopeMax = 0.5, scale = { 1.3, 1.8 } },
		},
		rocks = { material = Enum.Material.Rock, prob = 0.004, slopeBoost = 0.02, rmin = 3, rmax = 8 },
		clear = clear,
	}
end

-- arc of cylinder segments (roots, arches)
local function arc(Kit, parent, a, b, rise, d, n, mat, col)
	local prev = a
	for i = 1, n do
		local t = i / n
		local p = a:Lerp(b, t) + Vector3.new(0, math.sin(t * math.pi) * rise, 0)
		local seg = Kit.cylAB(prev, p, d)
		seg.Material = mat
		seg.Color = col
		seg.Parent = parent
		prev = p
	end
end

local function sparkles(Kit, parent, pos, size, color, rate)
	local p = Kit.part(parent, { Name = "Sparkles", Size = size, CFrame = CFrame.new(pos), Transparency = 1 })
	Kit.decor(p)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = rate or 6
	e.Lifetime = NumberRange.new(4, 7)
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Acceleration = Vector3.new(0, 0.6, 0)
	e.Parent = p
	return p
end
B.sparkles = sparkles

function B.build(Kit, Gen)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local reg = Kit.folder(Kit.folder(Kit.folder(workspace, "World"), "Regions"), "WhisperingForest")
	local old = reg:FindFirstChild("Authored")
	if old then
		old:Destroy()
	end
	local auth = Kit.folder(reg, "Authored")
	local function v3(p)
		return Vector3.new(p[1], p[3], p[2])
	end
	local function y(x, z)
		return Gen.heightAt(x, z)
	end
	local function ground(p)
		return Vector3.new(p.X, y(p.X, p.Z), p.Z)
	end

	-- the Enormous Enchanted Tree, with a root arch over the trail
	local gt = P.pads.GiantTree
	local gi = P.wp.GiantTree
	local fwd = flat(v3(P.main[gi + 12]) - v3(P.main[gi - 12])).Unit
	local right = fwd:Cross(Vector3.yAxis).Unit
	local center = Vector3.new(gt.x, gt.y, gt.z)
	local mtnSide = (right:Dot(flat(-center).Unit) > 0) and right or -right
	-- S scales the whole tree: it must dwarf the 60-75 stud forest trees to read as "enormous"
	local S = 2.1
	local base = center + mtnSide * 30 * S
	base = Vector3.new(base.X, y(base.X, base.Z) - 2, base.Z)
	local tree = Kit.model(auth, "EnchantedTree")
	local trunkParts = {}
	local tiers = { { 0, 34 }, { 18, 28 }, { 36, 23 }, { 54, 19 }, { 70, 16 } }
	for k, tr in ipairs(tiers) do
		local nextY = tiers[k + 1] and tiers[k + 1][1] or 88
		trunkParts[#trunkParts + 1] = Kit.part(nil, { Shape = Enum.PartType.Cylinder, Size = Vector3.new((nextY - tr[1] + 2) * S, tr[2] * S, tr[2] * S), CFrame = CFrame.new(base + Vector3.new(0, (tr[1] + nextY) / 2 * S, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	end
	-- root legs; skip any whose outer half would land on the trail (one used to wall off half of it)
	local function nearTrail(p)
		for i = gi - 60, gi + 60 do
			local r = P.main[i]
			if (r[1] - p.X) ^ 2 + (r[2] - p.Z) ^ 2 < 18 ^ 2 then
				return true
			end
		end
		return false
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.4
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local foot = ground(base + dir * 32 * S)
		if not (nearTrail(foot) or nearTrail(base + dir * 24 * S)) then
			trunkParts[#trunkParts + 1] = Kit.cylAB(base + Vector3.new(0, 16 * S, 0) + dir * 8 * S, foot - Vector3.new(0, 2, 0), 7 * S)
		end
	end
	local trunk = Kit.union(trunkParts)
	trunk.Name = "Trunk"
	trunk.Material = Enum.Material.Wood
	trunk.Color = C.timberDark
	trunk.Parent = tree
	-- precise collision (set once parented; it does not stick on an unparented union): the default
	-- hull of trunk + six root legs is a 222-stud invisible box that blocked the trail at the tree
	trunk.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
	-- root arch: one great root leaves the trunk, vaults the trail and dives into the valley-side slope
	local across = ground(center - mtnSide * 30)
	arc(Kit, tree, base + Vector3.new(0, 14, 0) - mtnSide * 12 * S, across - Vector3.new(0, 4, 0), 44, 11, 14, Enum.Material.Wood, C.timberDark)
	arc(Kit, tree, base + Vector3.new(0, 8, 0) - mtnSide * 12 * S + fwd * 16, across - Vector3.new(0, 4, 0) + fwd * 20, 34, 7, 12, Enum.Material.Wood, C.timberDark)
	-- glowing roots (luminous indigo veins) around the base
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local vein = Kit.cylAB(ground(base + dir * 18 * S) + Vector3.new(0, 0.6, 0), ground(base + dir * 40 * S) + Vector3.new(0, 0.3, 0), 1.4)
		vein.Material = Enum.Material.Neon
		vein.Color = C.indigo
		Kit.decor(vein)
		vein.Parent = tree
	end
	-- canopy
	local canopyParts = {}
	local rng = Random.new(77)
	for k = 1, 9 do
		local a = k / 9 * math.pi * 2
		local r = ((k == 9) and 0 or rng:NextNumber(18, 34)) * S
		canopyParts[#canopyParts + 1] = Kit.part(nil, { Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(38, 56) * S, CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, rng:NextNumber(92, 112) * S, math.sin(a) * r)) })
	end
	local canopy = Kit.union(canopyParts)
	canopy.Name = "Canopy"
	canopy.Material = Enum.Material.LeafyGrass
	canopy.Color = C.forestTeal
	Kit.decor(canopy, true)
	canopy.Parent = tree
	-- hanging glow orbs
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		local r = rng:NextNumber(20, 44) * S
		local orb = Kit.part(tree, { Name = "GlowOrb", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(4, 6.5), CFrame = CFrame.new(base + Vector3.new(math.cos(a) * r, rng:NextNumber(72, 84) * S, math.sin(a) * r)), Material = Enum.Material.Neon, Color = (k % 3 == 0) and C.turquoise or C.indigo })
		Kit.decor(orb)
		if k % 5 == 0 then
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = C.indigo, 30, 1.2, false
			l.Parent = orb
		end
	end
	sparkles(Kit, tree, base + Vector3.new(0, 30 * S, 0), Vector3.new(70, 40, 70) * S, C.golden, 14)
	-- clear dressed trees the trunk and canopy would intersect
	local veg = reg:FindFirstChild("Vegetation")
	if veg then
		local bflat = Vector3.new(base.X, 0, base.Z)
		for _, m in ipairs(veg:GetChildren()) do
			local p = m:GetPivot().Position
			if (Vector3.new(p.X, 0, p.Z) - bflat).Magnitude < 110 then
				m:Destroy()
			end
		end
	end

	-- Camp 2 Rootgate
	local camp = Kit.folder(auth, "Camp2_Rootgate")
	local pad = P.pads.Camp2
	local Cc = Vector3.new(pad.x, pad.y, pad.z)
	local ci = P.wp.Camp2
	local cf = flat(v3(P.main[ci + 15]) - v3(P.main[ci - 15])).Unit
	local cr = cf:Cross(Vector3.yAxis).Unit
	local cm = (cr:Dot(flat(-Cc).Unit) > 0) and cr or -cr
	local co = -cm
	local lodgePos = Cc + cm * 28 + Vector3.new(0, 1.4, 0)
	Kit.cabin(camp, CFrame.lookAt(lodgePos, lodgePos - cm), 28, 20, 11, { name = "RootgateLodge", doorWidth = 6 })
	Kit.locker(camp, CFrame.lookAt(Cc + cm * 14 + cf * 10, Cc + cf * 10))
	local fire = Cc + co * 14
	Kit.campfire(camp, fire)
	for k = 0, 2 do
		local a = math.rad(-60 + k * 60)
		local bp = fire + (co * math.cos(a) + cf * math.sin(a)) * 8
		Kit.bench(camp, CFrame.lookAt(bp, Vector3.new(fire.X, bp.Y, fire.Z)))
	end
	-- the Rootgate: a timber arch with root-wrapped posts over the trail leaving camp toward the cliffs
	local gp = v3(P.main[ci + 22])
	local gfwd = flat(v3(P.main[ci + 26]) - v3(P.main[ci + 18])).Unit
	local gright = gfwd:Cross(Vector3.yAxis).Unit
	local gate = Kit.model(camp, "Rootgate")
	for _, s in ipairs({ -1, 1 }) do
		local postBase = ground(gp + gright * s * 10)
		Kit.part(gate, { Name = "Post", Size = Vector3.new(2.6, 20, 2.6), CFrame = CFrame.new(postBase + Vector3.new(0, 9, 0)), Material = Enum.Material.Wood, Color = C.timberDark })
		for k = 0, 2 do
			local root = Kit.cylAB(postBase + Vector3.new(math.cos(k * 2.1) * 3, 0, math.sin(k * 2.1) * 3), postBase + Vector3.new(0, 14 + k * 2, 0), 1.1)
			root.Material = Enum.Material.Wood
			root.Color = C.timber
			root.Parent = gate
		end
		Kit.lantern(gate, postBase + gfwd * -2 + gright * s * 2, 7)
	end
	local top = gp.Y + 19
	Kit.part(gate, { Name = "Lintel", Size = Vector3.new(26, 2.2, 3), CFrame = CFrame.lookAt(Vector3.new(gp.X, top, gp.Z), Vector3.new(gp.X, top, gp.Z) + gright) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Wood, Color = C.timberDark })
	arc(Kit, gate, ground(gp - gright * 10) + Vector3.new(0, 17, 0), ground(gp + gright * 10) + Vector3.new(0, 17, 0), 5, 1.4, 6, Enum.Material.Wood, C.timber)
	local bpos = Cc + co * 40
	local beacon = Kit.model(camp, "Camp2_Beacon")
	Kit.part(beacon, { Name = "Pole", Size = Vector3.new(1.6, 24, 1.6), CFrame = CFrame.new(ground(bpos) + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = C.timberDark })
	local lamp = Kit.part(beacon, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.6, CFrame = CFrame.new(ground(bpos) + Vector3.new(0, 25.5, 0)), Material = Enum.Material.Neon, Color = C.lantern })
	Kit.decor(lamp)
	local bl = Instance.new("PointLight")
	bl.Color, bl.Range, bl.Brightness, bl.Shadows = C.lantern, 34, 2, false
	bl.Parent = lamp
	local sp = ground(Cc - cf * 42 + co * 9)
	Kit.sign(camp, CFrame.lookAt(sp, sp + cf) * CFrame.Angles(0, math.rad(90), 0), { { "Rootgate - Camp 2", 0 }, { "Chasm Hut", math.rad(90) }, { "Meadow Lodge", math.rad(-90) } }, 9)
	local bo = workspace.World:FindFirstChild("Blockout")
	if bo and bo.CampBeacons:FindFirstChild("Camp2_Beacon") then
		bo.CampBeacons.Camp2_Beacon:Destroy()
	end

	-- ancient stone ruins in the forest, off the trail
	local ruins = Kit.folder(auth, "Ruins")
	for _, spot in ipairs({ { 2.75, 1065 }, { 3.55, 1120 }, { 4.6, 1070 } }) do
		local x, z = Gen.toWorld(spot[1], spot[2])
		local cpos = ground(Vector3.new(x, 0, z))
		local mi, d = Gen.nearestIdx(P.main, x, z)
		if d > 30 then
			local m = Kit.model(ruins, "Ruin")
			local rr = Random.new(math.floor(x))
			for k = 0, 5 do
				local a = k / 6 * math.pi * 2
				local ph = (k % 2 == 0) and rr:NextNumber(14, 22) or rr:NextNumber(4, 9)
				local pp = ground(cpos + Vector3.new(math.cos(a) * 14, 0, math.sin(a) * 14))
				Kit.part(m, { Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(ph, 3.6, 3.6), CFrame = CFrame.new(pp + Vector3.new(0, ph / 2 - 1, 0)) * CFrame.Angles(rr:NextNumber(-0.06, 0.06), 0, math.rad(90) + rr:NextNumber(-0.06, 0.06)), Material = Enum.Material.Cobblestone, Color = C.masonry })
				if ph > 12 then
					local moss = Kit.part(m, { Name = "Moss", Shape = Enum.PartType.Ball, Size = Vector3.one * 4.4, CFrame = CFrame.new(pp + Vector3.new(0, ph - 1, 0)), Material = Enum.Material.LeafyGrass, Color = C.forestTeal })
					Kit.decor(moss, false)
				end
			end
			Kit.part(m, { Name = "FallenLintel", Size = Vector3.new(18, 2.6, 3.4), CFrame = CFrame.new(cpos + Vector3.new(2, 0.8, 3)) * CFrame.Angles(0, 0.6, 0.12), Material = Enum.Material.Cobblestone, Color = C.masonry })
			sparkles(Kit, m, cpos + Vector3.new(0, 8, 0), Vector3.new(30, 14, 30), C.indigo, 4)
		end
	end

	-- amber lanterns along the forest stretch of the route (Camp 1 -> Camp 2), light on every other one
	local lan = Kit.folder(auth, "RouteLanterns")
	local s0, n = P.mainS[P.wp.ForestEdge], 0
	for k = P.wp.ForestEdge + 10, P.wp.Camp2 - 25 do
		if P.mainS[k] - s0 > 200 then
			s0 = P.mainS[k]
			local a, b = P.main[k - 1], P.main[k + 1]
			local side = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit:Cross(Vector3.yAxis) * 9.5
			n += 1
			Kit.lantern(lan, ground(v3(P.main[k]) + side) - Vector3.new(0, 0.3, 0), 7, n % 2 == 0)
		end
	end

	-- footbridge where the forest ring crosses the creek
	for _, c in ipairs(P.crossings) do
		if c.path == "ForestRing" then
			local pts = P.rings.ForestRing
			Kit.bridge(auth, v3(pts[math.max(1, c.i0 - 3)]), v3(pts[math.min(#pts, c.i1 + 3)]), 8, 2.5, "CreekFootbridge")
			if bo then
				for _, b in ipairs(bo.Bridges:GetChildren()) do
					if b.Name:match("^ForestRing_Bridge") then
						b:Destroy()
					end
				end
			end
		end
	end
	return { lanterns = n }
end

return B
