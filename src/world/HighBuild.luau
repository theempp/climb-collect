-- HighBuild: Storm Ridge + Frozen Summit (master.md §4).
-- Storm Ridge: storm blue, electric violet, cyan; "Wind-scarred ruin with magical lightning focal point";
--   gusts, reduced visibility, sheltered alternatives. Frozen Summit: luminous ice blue, deep sapphire,
--   aurora purple; "Crown-like crystalline summit observatory"; exceptional vista.
local B = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local VIOLET = Color3.fromRGB(138, 78, 255) -- electricViolet
local CYAN = Color3.fromRGB(62, 224, 255) -- electricCyan
local AURORA = Color3.fromRGB(156, 92, 246) -- auroraPurple
local SAPPHIRE = Color3.fromRGB(30, 62, 140) -- deepSapphire

function B.stormSpec(Kit)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local c4, ru = P.pads.Camp4, P.pads.StormRuin
	return {
		region = "StormRidge", re0 = 300, re1 = 705, stride = 13, seed = 67,
		grove = { scale = 150, lo = 0.05, hi = 0.35 },
		items = {
			{ proto = "SnowPine", base = 0.02, groveBoost = 0.07, slopeMax = 0.9, scale = { 1.5, 2.5 } },
			{ proto = "DeadTree", base = 0.012, slopeMax = 1.3, scale = { 1.6, 2.6 } },
			{ proto = "CrystalAurora", base = 0.004, slopeMax = 1.6, scale = { 1.5, 3.0 } },
		},
		rocks = { material = Enum.Material.Basalt, prob = 0.006, slopeBoost = 0.02, rmin = 3, rmax = 9 },
		clear = { { c4.x, c4.z, 60 }, { ru.x, ru.z, 70 } },
	}
end

function B.summitSpec(Kit)
	local P = _G.CC_PATHS
	local lz = P.pads.HeliLZ
	return {
		region = "FrozenSummit", re0 = 40, re1 = 300, stride = 12, seed = 79,
		grove = { scale = 90, lo = 0.0, hi = 0.3 },
		items = {
			{ proto = "CrystalIce", base = 0.01, groveBoost = 0.02, slopeMax = 3.5, scale = { 1.4, 3.2 } },
			{ proto = "CrystalAurora", base = 0.004, slopeMax = 3.5, scale = { 1.4, 2.6 } },
		},
		rocks = { material = Enum.Material.Glacier, prob = 0.004, rmin = 3, rmax = 7 },
		clear = { { lz.x, lz.z, 45 }, { 0, 0, 60 } },
	}
end

local function glowPart(Kit, parent, props, light)
	local p = Kit.part(parent, props)
	Kit.decor(p)
	if light then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = light[1], light[2], light[3], false
		l.Parent = p
	end
	return p
end

local function beacon(Kit, parent, pos, name)
	local C = Kit.COL
	local m = Kit.model(parent, name)
	Kit.part(m, { Name = "Pole", Size = Vector3.new(1.6, 24, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = C.timberDark })
	glowPart(Kit, m, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.6, CFrame = CFrame.new(pos + Vector3.new(0, 25.5, 0)), Material = Enum.Material.Neon, Color = C.lantern }, { C.lantern, 34, 2 })
	return m
end

function B.build(Kit, Gen, Cliff)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local regions = Kit.folder(Kit.folder(workspace, "World"), "Regions")
	local function fresh(regionName)
		local reg = Kit.folder(regions, regionName)
		local old = reg:FindFirstChild("Authored")
		if old then
			old:Destroy()
		end
		return Kit.folder(reg, "Authored")
	end
	local storm, summit = fresh("StormRidge"), fresh("FrozenSummit")
	local function v3(p)
		return Vector3.new(p[1], p[3], p[2])
	end
	local function ground(p)
		return Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
	end
	local bo = workspace.World:FindFirstChild("Blockout")
	local rng = Random.new(101)

	-- Wind-scarred ruin with a lightning spire (the RuinTooth peak rises behind it)
	local ru = P.pads.StormRuin
	local R0 = Vector3.new(ru.x, ru.y, ru.z)
	local ruin = Kit.model(storm, "WindScarredRuin")
	for k = 0, 9 do
		if k % 4 ~= 1 then -- gaps where the wind broke through
			local a0, a1 = k / 10 * math.pi * 2, (k + 0.82) / 10 * math.pi * 2
			local p0 = ground(R0 + Vector3.new(math.cos(a0) * 30, 0, math.sin(a0) * 30))
			local p1 = ground(R0 + Vector3.new(math.cos(a1) * 30, 0, math.sin(a1) * 30))
			local h = rng:NextNumber(6, 18)
			local mid = (p0 + p1) / 2
			Kit.part(ruin, { Name = "Wall", Size = Vector3.new(3.5, h, (p1 - p0).Magnitude), CFrame = CFrame.lookAt(mid + Vector3.new(0, h / 2 - 1.5, 0), p1 + Vector3.new(0, h / 2 - 1.5, 0)), Material = Enum.Material.Cobblestone, Color = C.slate })
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		local pp = ground(R0 + Vector3.new(math.cos(a) * 20, 0, math.sin(a) * 20))
		local h = (k % 2 == 0) and rng:NextNumber(18, 28) or rng:NextNumber(6, 10)
		Kit.part(ruin, { Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 4, 4), CFrame = CFrame.new(pp + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(0, 0, math.rad(90) + rng:NextNumber(-0.08, 0.08)), Material = Enum.Material.Cobblestone, Color = C.masonry })
	end
	-- the spire: tapered obelisk with glowing rune bands, crackling top
	local spBase = ground(R0)
	for k = 0, 4 do
		local w = 9 - k * 1.5
		Kit.part(ruin, { Name = "Obelisk", Size = Vector3.new(w, 12, w), CFrame = CFrame.new(spBase + Vector3.new(0, 6 + k * 11.5, 0)) * CFrame.Angles(0, k * 0.15, 0), Material = Enum.Material.Basalt, Color = SAPPHIRE })
		glowPart(Kit, ruin, { Name = "Rune", Size = Vector3.new(w + 0.3, 0.8, w + 0.3), CFrame = CFrame.new(spBase + Vector3.new(0, 11.5 + k * 11.5, 0)) * CFrame.Angles(0, k * 0.15, 0), Material = Enum.Material.Neon, Color = (k % 2 == 0) and VIOLET or CYAN })
	end
	local core = glowPart(Kit, ruin, { Name = "StormCore", Shape = Enum.PartType.Ball, Size = Vector3.one * 5, CFrame = CFrame.new(spBase + Vector3.new(0, 64, 0)), Material = Enum.Material.Neon, Color = CYAN }, { VIOLET, 60, 3 })
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 25
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(8, 16)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	sparks.Color = ColorSequence.new(CYAN, VIOLET)
	sparks.LightEmission = 1
	sparks.Parent = core
	-- static lightning arc from the core to the RuinTooth peak (a beam, so it reads from afar)
	local tooth = nil
	for _, pk in ipairs(require(script.Parent.WorldConfig).PEAKS) do
		if pk.name == "RuinTooth" then
			local tx, tz = Gen.toWorld(pk.theta, pk.re)
			tooth = Vector3.new(tx, Gen.heightAt(tx, tz) + 4, tz)
		end
	end
	if tooth then
		local a0 = Instance.new("Attachment")
		a0.Parent = core
		local tp = glowPart(Kit, ruin, { Name = "ToothRod", Size = Vector3.new(1.2, 14, 1.2), CFrame = CFrame.new(tooth + Vector3.new(0, 7, 0)), Material = Enum.Material.Neon, Color = VIOLET })
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 7, 0)
		a1.Parent = tp
		local bm = Instance.new("Beam")
		bm.Attachment0, bm.Attachment1 = a0, a1
		bm.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		bm.TextureMode = Enum.TextureMode.Wrap
		bm.TextureLength = 6
		bm.TextureSpeed = 3
		bm.Width0, bm.Width1 = 3, 2
		bm.LightEmission = 1
		bm.FaceCamera = true
		bm.CurveSize0, bm.CurveSize1 = 20, -14
		bm.Segments = 24
		bm.Color = ColorSequence.new(CYAN, VIOLET)
		bm.Parent = core
	end

	-- Camp 4 Stormwatch: watchtower, windbreak, sheltered fire, locker, beacon
	local camp = Kit.folder(storm, "Camp4_Stormwatch")
	local pad = P.pads.Camp4
	local Cc = Vector3.new(pad.x, pad.y, pad.z)
	local ci = P.wp.Camp4
	local cf = flat(v3(P.main[ci + 12]) - v3(P.main[ci - 12])).Unit
	local cr = cf:Cross(Vector3.yAxis).Unit
	local cm = (cr:Dot(flat(-Cc).Unit) > 0) and cr or -cr
	local co = -cm
	local tw = Cc + cm * 22
	local tower = Kit.model(camp, "StormwatchTower")
	Kit.part(tower, { Name = "Shaft", Size = Vector3.new(12, 38, 12), CFrame = CFrame.new(tw + Vector3.new(0, 18, 0)), Material = Enum.Material.Cobblestone, Color = C.slate })
	Kit.part(tower, { Name = "Platform", Size = Vector3.new(18, 1.5, 18), CFrame = CFrame.new(tw + Vector3.new(0, 37.5, 0)), Material = Enum.Material.WoodPlanks, Color = C.timber })
	for _, s in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		Kit.part(tower, { Name = "Post", Size = Vector3.new(1.2, 10, 1.2), CFrame = CFrame.new(tw + Vector3.new(s[1] * 8, 43, s[2] * 8)), Material = Enum.Material.Wood, Color = C.timberDark })
	end
	Kit.part(tower, { Name = "Roof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 22, 22), CFrame = CFrame.new(tw + Vector3.new(0, 48.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = C.timberDark })
	glowPart(Kit, tower, { Name = "WatchLamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(tw + Vector3.new(0, 42, 0)), Material = Enum.Material.Neon, Color = C.lantern }, { C.lantern, 40, 2 })
	for k = -2, 2 do
		local a = math.rad(k * 24)
		local dir = (co * math.cos(a) + cf * math.sin(a))
		local p = ground(Cc + dir * 34)
		Kit.part(camp, { Name = "Windbreak", Size = Vector3.new(14, 7, 3), CFrame = CFrame.lookAt(p + Vector3.new(0, 2.5, 0), p + Vector3.new(0, 2.5, 0) + dir:Cross(Vector3.yAxis)), Material = Enum.Material.Cobblestone, Color = C.slate })
	end
	Kit.locker(camp, CFrame.lookAt(Cc + cm * 8 + cf * 10, Cc + cf * 10))
	local fire = Cc + co * 10
	Kit.campfire(camp, fire)
	for k = 0, 2 do
		local a = math.rad(-60 + k * 60)
		local bp = fire + (co * math.cos(a) + cf * math.sin(a)) * 8
		Kit.bench(camp, CFrame.lookAt(bp, Vector3.new(fire.X, bp.Y, fire.Z)))
	end
	beacon(Kit, camp, ground(Cc + co * 26 + cf * 14), "Camp4_Beacon")
	local sp = ground(Cc - cf * 34 + co * 8)
	Kit.sign(camp, CFrame.lookAt(sp, sp + cf) * CFrame.Angles(0, math.rad(90), 0), { { "Stormwatch - Camp 4", 0 }, { "Frozen Summit", math.rad(90) }, { "Chasm Hut", math.rad(-90) } }, 9)
	if bo and bo.CampBeacons:FindFirstChild("Camp4_Beacon") then
		bo.CampBeacons.Camp4_Beacon:Destroy()
	end

	-- cairns every ~150 studs from Camp 3 to the summit (wayfinding in whiteout)
	local cairns = Kit.folder(storm, "Cairns")
	local s0, n, side = P.mainS[P.wp.Camp3], 0, 1
	for k = P.wp.Camp3 + 20, #P.main - 20 do
		if P.mainS[k] - s0 > 150 then
			s0 = P.mainS[k]
			local a, b = P.main[k - 1], P.main[k + 1]
			local off = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit:Cross(Vector3.yAxis) * 10 * side
			side = -side
			-- on switchbacks a side offset can land on the neighbouring leg: try both sides, else skip
			local q
			for _, o in ipairs({ off, -off }) do
				local cand = v3(P.main[k]) + o
				local clear = true
				for j = math.max(1, k - 400), math.min(#P.main, k + 400) do
					if math.abs(j - k) > 6 then
						local r = P.main[j]
						if (r[1] - cand.X) ^ 2 + (r[2] - cand.Z) ^ 2 < 100 then
							clear = false
							break
						end
					end
				end
				if clear then
					q = ground(cand)
					break
				end
			end
			if q then
				Kit.place(cairns, "Cairn", q - Vector3.new(0, 0.3, 0), k, 1.6)
				n += 1
			end
		end
	end

	-- edge fences from Camp 3 up through Storm Ridge and the summit spiral
	local fences = Cliff.edgeFences(Kit, Gen, storm, P.main, P.wp.Camp3 + 10, P.wp.SummitStairs, "RidgeFences")

	-- Frozen Summit: summit stairs
	local stairs = Kit.folder(summit, "SummitStairs")
	local i = P.wp.SummitStairs
	while i < #P.main - 6 do
		local a, b = P.main[i], P.main[i + 6]
		if b[3] - a[3] > 4.5 then
			Kit.stairs(stairs, v3(a) + Vector3.new(0, 0.9, 0), v3(b) + Vector3.new(0, 0.9, 0), 10)
		end
		i += 6
	end

	-- Crown observatory on the summit pad
	local top = Vector3.new(0, 2000, 0)
	local obs = Kit.model(summit, "CrownObservatory")
	Kit.part(obs, { Name = "Platform", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 68, 68), CFrame = CFrame.new(top + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = C.moon })
	glowPart(Kit, obs, { Name = "RuneRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 64, 64), CFrame = CFrame.new(top + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = CYAN, Transparency = 0.2 })
	Kit.part(obs, { Name = "Inlay", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 61, 61), CFrame = CFrame.new(top + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = C.moon })
	Kit.part(obs, { Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 24, 24), CFrame = CFrame.new(top + Vector3.new(0, 6.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Limestone, Color = C.moon })
	Kit.part(obs, { Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.one * 23, CFrame = CFrame.new(top + Vector3.new(0, 12.5, 0)), Material = Enum.Material.Glass, Color = SAPPHIRE, Transparency = 0.25, Reflectance = 0.15 })
	local scope = Kit.cylAB(top + Vector3.new(0, 16, 0), top + Vector3.new(9, 27, -4), 2.6)
	scope.Name = "GreatTelescope"
	scope.Material = Enum.Material.Metal
	scope.Color = C.lantern
	scope.Parent = obs
	-- the crown: tall crystal blades leaning outward around the rim
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local h = (k % 2 == 0) and 46 or 30
		local basePos = top + Vector3.new(math.cos(a) * 31, 0, math.sin(a) * 31)
		local blade = Kit.part(obs, { Name = "CrownBlade", Size = Vector3.new(4.5, h, 4.5), CFrame = CFrame.new(basePos) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-12)) * CFrame.new(0, h / 2 - 1, 0) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Glass, Color = (k % 3 == 0) and AURORA or C.ice, Transparency = 0.1, Reflectance = 0.1 })
		Kit.decor(blade, true)
		blade.CanCollide = true
	end
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + 0.4
		glowPart(Kit, obs, { Name = "CrownLight", Size = Vector3.one, CFrame = CFrame.new(top + Vector3.new(math.cos(a) * 24, 10, math.sin(a) * 24)), Transparency = 1 }, { (k % 2 == 0) and CYAN or AURORA, 40, 1.6 })
	end
	Kit.sign(obs, CFrame.new(top + Vector3.new(0, 0, 24)), { { "Frozen Summit", 0 } }, 9)

	-- Helicopter landing zone (~80% elevation, PROPOSED in master.md §0.5)
	local lz = P.pads.HeliLZ
	local L0 = Vector3.new(lz.x, lz.y, lz.z)
	local pad3 = Kit.model(summit, "HeliLandingZone")
	Kit.part(pad3, { Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 46, 46), CFrame = CFrame.new(L0 + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Slate, Color = C.slate })
	Kit.part(pad3, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 40, 40), CFrame = CFrame.new(L0 + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = C.moon })
	Kit.part(pad3, { Name = "RingInner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 36, 36), CFrame = CFrame.new(L0 + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Slate, Color = C.slate })
	for _, d in ipairs({ { 0, 0, 3, 18 }, { -5, 0, 3, 18 }, { 5, 0, 3, 18 } }) do
		local horiz = d[1] == 0
		Kit.part(pad3, { Name = "H", Size = horiz and Vector3.new(10, 1.7, 2.6) or Vector3.new(2.6, 1.7, 16), CFrame = CFrame.new(L0 + Vector3.new(d[1], 0.4, 0)), Material = Enum.Material.SmoothPlastic, Color = C.moon })
	end
	beacon(Kit, pad3, ground(L0 + Vector3.new(26, 0, 0)), "LZ_BeaconMast")

	return { fences = fences, cairns = n, stairs = #stairs:GetChildren() }
end

return B
