-- CoreProps (Run 1 phase B): world anchors and props for the Green Valley core loop. Generator, run in edit mode:
--   require(ServerStorage.CC_Generators:Clone().CoreProps).build(require(ServerStorage.CC_Generators.Kit))
-- Output: Workspace.World.Core.{Props, Spawns, Nests}. Rebuild-safe (clears its own folders only).
-- Spawns are invisible anchors; creatures, Heartstones and guardians are spawned at runtime by the server
-- (CC_CoreServer). No species art here: creature visuals are stubs until the Codex roster arrives.
-- Placements (all PROPOSED, logged): first common on the plaza between spawn and the campfire; the guardian-free
-- Rare nook up a short fixed rope on the steep inner bank of Shepherd's Road (~s840); the gentle tutorial nest in
-- the dry-grass hollow south of the road; the cliffhanger "lip nest" on the valley lip above the plaza.
-- Colors are existing Kit tokens only.
local C = require(script.Parent.WorldConfig)
local P = {}

local NAMES = { "Props", "Spawns", "Nests" }
P.TUT_COMMON = Vector3.new(-22, 48, 2125)
P.NEST1 = Vector3.new(-1000, 0, 2080) -- y from terrain
P.NEST2 = Vector3.new(-92, 0, 1632)
P.NOOK_S = 840 -- Shepherd's Road arc length for the rope + nook
-- v5 (2026-10-21): Shepherd is a 5-wide tread between a wall and a drop; commons sit on the terrain strip just
-- inside the wall, every 110 studs up to Camp 1 (leg 1 is ~2,230 studs; v4 was 5,900 with spawns every 230)
P.COMMONS_TO, P.COMMONS_EVERY, P.COMMONS_OFF = 2200, 110, 3.4
-- lip nest access: two short timber stairs over the rock steps between the lower shelf (reached on foot from the
-- road, s~5560) and the nest shelf; bottom -> top, y from terrain (measured profile 2026-10-20: steps ~7 and ~6 studs)
P.LIP_STAIRS = {
	{ Vector3.new(-158, 0, 1641), Vector3.new(-147, 0, 1641) },
	{ Vector3.new(-140, 0, 1640), Vector3.new(-120, 0, 1640) },
}

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x, z)
	-- v6: the in-memory heightfield when present (raycasts right after the voxel writes of a rebuild still see the
	-- old terrain: the nook rope was placed from stale heights and its truss hung 4 studs up, tutorial regression)
	local G = _G.CC_Gen
	if G and _G.CC_HF then
		local h = G.heightAt(x, z)
		local hx, hz = G.heightAt(x + 2, z) - G.heightAt(x - 2, z), G.heightAt(x, z + 2) - G.heightAt(x, z - 2)
		return h, Vector3.new(-hx / 4, 1, -hz / 4).Unit
	end
	local r = workspace:Raycast(Vector3.new(x, 3400, z), Vector3.new(0, -3600, 0), terrainOnly)
	return r and r.Position.Y or 0, r and r.Normal or Vector3.yAxis
end

local function routePts(name)
	local out = {}
	local sv = game:GetService("ReplicatedStorage"):FindFirstChild("CC_Route")
	sv = sv and sv:FindFirstChild(name)
	for tok in string.gmatch(sv and sv.Value or "", "[^;]+") do
		local x, y, z, s = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		out[#out + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
	end
	return out
end
local function atS(pts, s)
	for i = 2, #pts do
		if pts[i].s >= s then
			local a, b = pts[i - 1], pts[i]
			local k = (s - a.s) / math.max(1e-3, b.s - a.s)
			return a.p:Lerp(b.p, k), (b.p - a.p) * Vector3.new(1, 0, 1)
		end
	end
	return pts[#pts].p, Vector3.xAxis
end

local function anchor(parent, name, pos, attrs)
	local a = Instance.new("Part")
	a.Name = name
	a.Anchored = true
	a.CanCollide, a.CanTouch, a.CanQuery = false, false, false
	a.Transparency = 1
	a.Size = Vector3.new(1, 1, 1)
	a.CFrame = CFrame.new(pos)
	for k, v in pairs(attrs) do
		a:SetAttribute(k, v)
	end
	a.Parent = parent
	return a
end

local function boulder(Kit, parent, pos, size, yaw, tilt)
	local p = Kit.part(parent, {
		Name = "Boulder",
		Size = size,
		CFrame = CFrame.new(pos) * CFrame.Angles(tilt or 0.2, yaw or 0, (tilt or 0.2) * 0.6),
		Material = Enum.Material.Rock,
		Color = Kit.COL.rock,
	})
	return p
end

-- nest: stone ring, aurora crystals (Heartstone = aurora-crystal core, LOCKED), cradle, pup spot, patrol radius
local function nest(Kit, parent, id, center, opts)
	local COL = Kit.COL
	local m = Kit.model(parent, id)
	local y = center.Y
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local s = 1.4 + (i % 3) * 0.35
		Kit.part(m, { Name = "RingStone", Size = Vector3.new(s * 1.3, s, s), CFrame = CFrame.new(center + Vector3.new(math.cos(a) * 6, s * 0.35, math.sin(a) * 6)) * CFrame.Angles(0.15, a, 0.1), Material = Enum.Material.Slate, Color = COL.masonry })
	end
	local cradle = Kit.part(m, { Name = "Cradle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 4.4, 4.4), CFrame = CFrame.new(center + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Slate, Color = COL.slate })
	cradle.CanCollide = false
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.6
		Kit.place(m, "CrystalAurora", center + Vector3.new(math.cos(a) * 8.5, -0.3, math.sin(a) * 8.5), a, opts.crystalScale or 0.45)
	end
	m:SetAttribute("NestId", id)
	m:SetAttribute("Tier", opts.tier)
	m:SetAttribute("Region", 1)
	m:SetAttribute("Patrol", opts.patrol)
	m:SetAttribute("GuardianScale", opts.guardianScale or 1)
	m:SetAttribute("SenseScale", opts.senseScale or 1)
	m:SetAttribute("Center", center)
	m:SetAttribute("HeartstonePos", center + Vector3.new(0, 3.2, 0))
	m:SetAttribute("PupPos", center + opts.pupOffset)
	m:SetAttribute("Label", opts.label)
	m.ModelStreamingMode = opts.persistent and Enum.ModelStreamingMode.Persistent or Enum.ModelStreamingMode.Default
	return m
end

function P.build(Kit)
	local COL = Kit.COL
	local world = workspace:WaitForChild("World")
	local core = Kit.folder(world, "Core")
	for _, n in ipairs(NAMES) do
		local f = core:FindFirstChild(n)
		if f then
			f:Destroy()
		end
	end
	local props = Kit.folder(core, "Props")
	local spawns = Kit.folder(core, "Spawns")
	local nests = Kit.folder(core, "Nests")
	local report = {}

	------------------------------------------------ tutorial common (per player, once)
	anchor(spawns, "TutCommon", P.TUT_COMMON + Vector3.new(0, 1.6, 0), { SpawnId = "tut_common", Kind = "creature", Rarity = "Common", Ecology = "ground", Region = 1, PerPlayer = true, Respawn = 0 })

	------------------------------------------------ rope + Rare nook on Shepherd's Road
	local shep = routePts("Shepherd")
	local roadP, dir = atS(shep, P.NOOK_S)
	local inward = (-roadP * Vector3.new(1, 0, 1)).Unit
	local along = dir.Magnitude > 0 and dir.Unit or inward:Cross(Vector3.yAxis)
	local baseXZ = roadP + inward * (C.ROUTES[1].hw + 2.5)
	local gBase = ground(baseXZ.X, baseXZ.Z)
	local shelfXZ = roadP + inward * (C.ROUTES[1].hw + 9)
	local gShelf = ground(shelfXZ.X, shelfXZ.Z)
	local shelfTop = math.max(gShelf + 1.2, gBase + 12)
	local climb = shelfTop - gBase
	local nook = Kit.model(props, "RareNook")
	local face = CFrame.lookAt(Vector3.new(baseXZ.X, 0, baseXZ.Z), Vector3.new(baseXZ.X, 0, baseXZ.Z) - inward) -- looks toward the road
	-- shelf (flat stone ledge pushed into the bank)
	local shelfCF = CFrame.lookAt(Vector3.new(shelfXZ.X, shelfTop - 1, shelfXZ.Z), Vector3.new(shelfXZ.X, shelfTop - 1, shelfXZ.Z) + along)
	Kit.part(nook, { Name = "Shelf", Size = Vector3.new(11, 2, 16), CFrame = shelfCF, Material = Enum.Material.Slate, Color = COL.rock })
	-- the step face under the shelf (so the rope hangs on rock, not on a terrain slope)
	local faceH = climb + 1
	Kit.part(nook, { Name = "StepFace", Size = Vector3.new(16, faceH, 3), CFrame = CFrame.new(Vector3.new(baseXZ.X, gBase + faceH / 2 - 0.5, baseXZ.Z) + inward * 2.4) * face.Rotation, Material = Enum.Material.Rock, Color = COL.rock })
	-- climbable truss (invisible) + visible fixed rope with knots and a piton
	local truss = Instance.new("TrussPart")
	truss.Name = "RopeTruss"
	truss.Anchored = true
	truss.Size = Vector3.new(2, math.floor(climb / 2 + 1) * 2, 2)
	truss.CFrame = CFrame.new(Vector3.new(baseXZ.X, gBase + truss.Size.Y / 2, baseXZ.Z)) * face.Rotation
	truss.Transparency = 1
	truss.Parent = nook
	local ropeTop = Vector3.new(baseXZ.X, shelfTop + 0.6, baseXZ.Z)
	local ropeBot = Vector3.new(baseXZ.X, gBase + 0.4, baseXZ.Z)
	-- vertical rope: a cylinder's axis is X, so roll it 90 deg about Z
	local rope = Kit.part(nook, { Name = "Rope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((ropeTop - ropeBot).Magnitude, 0.45, 0.45), CFrame = CFrame.new((ropeTop + ropeBot) / 2) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = COL.lantern })
	Kit.decor(rope)
	for y = gBase + 2, shelfTop - 1, 2.5 do
		local knot = Kit.part(nook, { Name = "Knot", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(Vector3.new(baseXZ.X, y, baseXZ.Z)), Material = Enum.Material.Fabric, Color = COL.lantern })
		Kit.decor(knot)
	end
	local piton = Kit.part(nook, { Name = "Piton", Size = Vector3.new(0.5, 0.5, 1.6), CFrame = CFrame.new(ropeTop) * face.Rotation, Material = Enum.Material.Metal, Color = COL.slate })
	Kit.decor(piton)
	-- boulders + scrub hide the Rare from the road (guardian-free nook, LOCKED)
	local shelfC = Vector3.new(shelfXZ.X, shelfTop, shelfXZ.Z)
	boulder(Kit, nook, shelfC - inward * 3.5 + along * 5, Vector3.new(4, 3.4, 3.6), 0.4, 0.25)
	boulder(Kit, nook, shelfC - inward * 3.2 - along * 5.5, Vector3.new(4.6, 3, 3.2), 1.2, 0.2)
	Kit.place(nook, "Bush", shelfC + along * 2.5 + inward * 3, 0.7, 1.3, C.DRY.scrub)
	Kit.place(nook, "Bush", shelfC - along * 3 + inward * 3.5, 2.1, 1.1, C.DRY.scrub)
	anchor(spawns, "TutRare", shelfC + inward * 0.5 + Vector3.new(0, 1.8, 0), { SpawnId = "nook_rare_r1", Kind = "creature", Rarity = "Rare", Ecology = "hiding", Region = 1, PerPlayer = true, Respawn = 1200 })
	anchor(props, "NookTop", shelfC + Vector3.new(0, 3, 0), { Marker = "NookTop" })
	anchor(props, "RopeBase", Vector3.new(baseXZ.X, gBase + 3, baseXZ.Z) - inward * 3, { Marker = "RopeBase" })
	report.nook = string.format("road s%d (%.0f,%.0f,%.0f) climb %.1f studs, shelf top %.1f", P.NOOK_S, roadP.X, roadP.Y, roadP.Z, climb, shelfTop)

	------------------------------------------------ nests
	local g1 = ground(P.NEST1.X, P.NEST1.Z)
	local n1c = Vector3.new(P.NEST1.X, g1, P.NEST1.Z)
	-- the tutorial nest's guardian is the first one a player meets: shorter senses (net range 18 is outside them)
	nest(Kit, nests, "nest_r1_hollow", n1c, { tier = "Common", patrol = 14, pupOffset = Vector3.new(-8, 1.4, -19), label = "Hollow nest", crystalScale = 0.45, senseScale = 0.6 })
	-- hide spot east of the nest (off the road-to-nest approach): boulder cluster + scrub, breaks line of sight
	local toRoad = Vector3.new(0, 0, -1)
	local hs = n1c + Vector3.new(26, 0, -6)
	local gh = ground(hs.X, hs.Z)
	local hide = Kit.model(props, "HideSpot_r1")
	boulder(Kit, hide, Vector3.new(hs.X, gh + 3.2, hs.Z), Vector3.new(9, 7, 6), 0.3, 0.12)
	boulder(Kit, hide, Vector3.new(hs.X, gh + 2.2, hs.Z) + toRoad:Cross(Vector3.yAxis) * 6, Vector3.new(6, 5, 5), 1.1, 0.18)
	Kit.place(hide, "Bush", Vector3.new(hs.X, gh, hs.Z) - toRoad:Cross(Vector3.yAxis) * 6, 0.4, 1.8, C.DRY.scrub)
	hide:SetAttribute("HideSpot", true)
	local g2 = ground(P.NEST2.X, P.NEST2.Z)
	local n2c = Vector3.new(P.NEST2.X, g2, P.NEST2.Z)
	nest(Kit, nests, "nest_r1_lip", n2c, { tier = "Rare", patrol = 12, pupOffset = Vector3.new(-8, 1.4, 6), label = "Lip nest", guardianScale = 1.4, crystalScale = 0.6, persistent = true })
	report.nests = string.format("hollow (%.0f,%.0f,%.0f) | lip (%.0f,%.0f,%.0f) | hide spot (%.0f,%.0f,%.0f)", n1c.X, n1c.Y, n1c.Z, n2c.X, n2c.Y, n2c.Z, hs.X, gh, hs.Z)

	------------------------------------------------ lip nest access (B-polish 2026-10-20, PROPOSED)
	-- The on-foot walk goes from Shepherd's Road (s~5560) down to a lower shelf west of the nest; from there a walkable
	-- slope climbs to the nest shelf, broken by two rock steps (~7 and ~6 studs) a player can't jump. A short timber
	-- stair over each step (same kit as the valley stairs) keeps the climb on foot.
	local lipM = Kit.model(props, "LipStairs")
	local rises = {}
	for _, st in ipairs(P.LIP_STAIRS) do
		local a = Vector3.new(st[1].X, (ground(st[1].X, st[1].Z)), st[1].Z)
		-- pick the shortest top point (from 6 studs out to the listed end) whose stair line stays above the ground
		-- across the stair's width, so no step is buried under the rock (the listed end is only the search limit)
		local dirS = Vector3.new(st[2].X - a.X, 0, st[2].Z - a.Z)
		local maxD = dirS.Magnitude
		dirS = dirS.Unit
		local sideS = Vector3.new(-dirS.Z, 0, dirS.X)
		local function gMax(p)
			local m = -math.huge
			for _, k in ipairs({ -2, 0, 2 }) do
				m = math.max(m, (ground(p.X + sideS.X * k, p.Z + sideS.Z * k)))
			end
			return m
		end
		local b, bestBad = nil, math.huge
		for d = 6, maxD, 0.5 do
			local tp = a + dirS * d
			local cand = Vector3.new(tp.X, gMax(tp) + 0.2, tp.Z)
			local bad = 0
			for t = 0.5, d - 0.5, 0.5 do
				local q = a + dirS * t
				bad = math.max(bad, gMax(q) - (a.Y + (cand.Y - a.Y) * t / d))
			end
			if bad <= 0.3 then
				b, bestBad = cand, bad
				break
			elseif bad < bestBad then
				b, bestBad = cand, bad
			end
		end
		Kit.stairs(lipM, a, b, 5)
		rises[#rises + 1] = string.format("%.1f", b.Y - a.Y)
		-- the rock bulges above the stair line (up to ~3 studs, measured): clear voxels whose centre sits 0-8 studs
		-- above the line inside a 6-stud corridor so there is head room (whole 4-stud voxels, Read/WriteVoxels)
		local lo = Vector3.new(math.min(a.X, b.X) - 6, math.min(a.Y, b.Y) - 4, math.min(a.Z, b.Z) - 6)
		local hi = Vector3.new(math.max(a.X, b.X) + 6, math.max(a.Y, b.Y) + 12, math.max(a.Z, b.Z) + 6)
		local region = Region3.new(lo, hi):ExpandToGrid(4)
		local mats, occ = workspace.Terrain:ReadVoxels(region, 4)
		local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = dir.Magnitude
		dir = dir.Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local cleared = 0
		local sz = mats.Size
		for ix = 1, sz.X do
			for iy = 1, sz.Y do
				for iz = 1, sz.Z do
					local c = region.CFrame.Position - region.Size / 2 + Vector3.new(ix - 0.5, iy - 0.5, iz - 0.5) * 4
					local rel = Vector3.new(c.X - a.X, 0, c.Z - a.Z)
					local along, across = rel:Dot(dir), math.abs(rel:Dot(side))
					if along >= -1 and along <= len + 1 and across <= 3 then
						local lineY = a.Y + (b.Y - a.Y) * math.clamp(along / len, 0, 1)
						if c.Y - lineY > 0 and c.Y - lineY < 8 and occ[ix][iy][iz] > 0 then
							mats[ix][iy][iz], occ[ix][iy][iz] = Enum.Material.Air, 0
							cleared += 1
						end
					end
				end
			end
		end
		workspace.Terrain:WriteVoxels(region, 4, mats, occ)
		rises[#rises] ..= string.format("(run %.1f, worst ground above line %.1f, %d vox)", (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude, bestBad, cleared)
	end
	report.lipStairs = "rises " .. table.concat(rises, " + ")

	------------------------------------------------ shared commons along Shepherd's Road (+ a few uncommons)
	local n, ecos = 0, { "ground", "hopping", "perched" }
	local nextS = 160
	local side = 1
	for _, q in ipairs(shep) do
		if q.s >= nextS and q.s <= P.COMMONS_TO then
			nextS = q.s + P.COMMONS_EVERY
			local _, d = atS(shep, q.s)
			local right = (d.Magnitude > 0 and d.Unit or Vector3.xAxis):Cross(Vector3.yAxis)
			-- the road is cut into steep banks, so spawns sit on the trail edge (either side, must be level with it)
			local x, z, gy, nrm
			for _, sd in ipairs({ side, -side }) do
				local off = right * sd * P.COMMONS_OFF
				local gx, gz = q.p.X + off.X, q.p.Z + off.Z
				local y, nr = ground(gx, gz)
				if nr.Y > 0.8 and math.abs(y - q.p.Y) < 3 then
					x, z, gy, nrm = gx, gz, y, nr
					break
				end
			end
			side = -side
			if x then
				n += 1
				local unc = (n % 5 == 0)
				anchor(spawns, "Common_" .. n, Vector3.new(x, gy + 1.6, z), {
					SpawnId = "shep_" .. n,
					Kind = "creature",
					Rarity = unc and "Uncommon" or "Common",
					Ecology = unc and ((n % 10 == 0) and "hiding" or "floating") or ecos[(n % 3) + 1],
					Region = 1,
					PerPlayer = false,
					Respawn = 90,
				})
			end
		end
	end
	-- a few on the Foothold outskirts so a returning player meets one near home
	for k, pos in ipairs({ Vector3.new(-330, 0, 2010), Vector3.new(310, 0, 2000), Vector3.new(-120, 0, 1890) }) do
		local gy = ground(pos.X, pos.Z)
		anchor(spawns, "Outskirts_" .. k, Vector3.new(pos.X, gy + 1.6, pos.Z), { SpawnId = "out_" .. k, Kind = "creature", Rarity = "Common", Ecology = ecos[k], Region = 1, PerPlayer = false, Respawn = 90 })
	end
	report.commons = n .. " route spawn points + 3 outskirts"
	return report
end

return P
