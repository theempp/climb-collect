-- ShepherdP2 (v4 P2, 2026-10-21): one "gentle but alive" stretch of Shepherd's Road (master.md §0.8, LOCKED #6:
-- rope scrambles, railed ledges, one real view-down moment, ~25 % hands-on). Placements PROPOSED.
--   require(ServerStorage.CC_Generators:Clone().ShepherdP2).build(require(ServerStorage.CC_Generators.Kit))
-- Needs ReplicatedStorage.CC_Route.Shepherd. Tutorial beats 4-5 and the Rare nook (s~840) are untouched: this
-- stretch is s~1390-1500, past everything the tutorial uses. Output: Workspace.World.ShepherdP2.
-- Line: the road narrows to a railed ledge along the drop (a rock band squeezes it to ~5 studs; the road's own
-- drop-side fence is the rail) -> an old rockfall closes the road: a short marked scramble (fixed rope) up its
-- face -> along its top to a lookout jutting over the drop (view-down moment) -> timber stairs back down to the road.
local SP = {}

SP.BAND = { 1392, 1428 } -- railed-ledge squeeze
SP.BARRIER = { 1440, 1458 } -- rockfall across the road (its near face is the scramble)
SP.STAIRS_TO = 1476 -- stairs land on the road here
SP.SCRAMBLE_H = 14 -- barrier height above the road at its near face

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x, z)
	local r = workspace:Raycast(Vector3.new(x, 900, z), Vector3.new(0, -1000, 0), terrainOnly)
	return r and r.Position.Y or 0
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
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

function SP.build(Kit)
	local COL = Kit.COL
	local world = Kit.folder(workspace, "World")
	local old = world:FindFirstChild("ShepherdP2")
	if old then
		old:Destroy()
	end
	local root = Kit.folder(world, "ShepherdP2")
	local rng = Random.new(1517)
	local n = 0
	local function P(parent, props)
		n += 1
		return Kit.part(parent, props)
	end
	local pts = routePts("Shepherd")
	-- frame at arc length s: road centre (trail height), along-road t, outward o (toward the drop)
	local function frame(s)
		for i = 2, #pts do
			if pts[i].s >= s then
				local a, b = pts[i - 1], pts[i]
				local k = (s - a.s) / math.max(1e-3, b.s - a.s)
				local c = a.p:Lerp(b.p, k)
				local t = flat(b.p - a.p).Unit
				local side = Vector3.new(-t.Z, 0, t.X)
				local o = (ground(c.X + side.X * 20, c.Z + side.Z * 20) < ground(c.X - side.X * 20, c.Z - side.Z * 20)) and side or -side
				return c, t, o
			end
		end
	end
	-- run 2 fix (self-review "boxy striped band"): one rock mass; strata vary in texture and a small shade step
	-- between the lichen-rock and slate tokens, not in hue
	local function band()
		local r = rng:NextNumber()
		return { COL.rock:Lerp(COL.slate, 0.08 + rng:NextNumber() * 0.3), (r < 0.6) and Enum.Material.Rock or Enum.Material.Slate }
	end
	local report = {}

	------------------------------------------------ railed ledge: a rock band squeezes the road to ~5 studs at the drop
	local bandF = Kit.folder(root, "RailedLedge")
	for s = SP.BAND[1], SP.BAND[2], 6 do
		local c, t, o = frame(s)
		-- taper in/out over the first and last 6 studs
		local k = math.clamp(math.min(s - SP.BAND[1], SP.BAND[2] - s) / 6, 0, 1)
		local inner = 1.5 * k + (-7.5) * (1 - k) -- the band's outer face, along o (road hw 7: walkable = inner..7)
		local w = inner + 12
		local h = 9 + rng:NextNumber() * 6
		local b = band()
		local centre = c + o * (inner - w / 2) + Vector3.new(0, h / 2 - 1.5, 0)
		P(bandF, { Name = "RockBand", Size = Vector3.new(w, h, 6.8), CFrame = CFrame.lookAt(centre, centre + t) * CFrame.Angles(math.rad(rng:NextNumber() * 4 - 2), 0, math.rad(rng:NextNumber() * 4 - 2)), Material = b[2], Color = b[1] })
	end
	report.ledge = string.format("railed ledge s %d-%d, walkable ~5.5 studs at the drop-side fence", SP.BAND[1], SP.BAND[2])

	------------------------------------------------ the rockfall barrier; its near face is the marked scramble
	local bar = Kit.model(root, "Rockfall")
	local c0, t0, o0 = frame(SP.BARRIER[1])
	local c1 = frame(SP.BARRIER[2])
	local topY = c0.Y + SP.SCRAMBLE_H
	local len = (flat(c1 - c0)).Magnitude
	local mid = (c0 + c1) / 2
	local tm = flat(c1 - c0).Unit
	-- strata blocks from the bank (o -13) to past the outer edge (o +10), road level -3 to the top
	local y, i = c0.Y - 3, 0
	while y < topY - 0.01 do
		i += 1
		local h = math.min(topY - y, 2.6 + rng:NextNumber() * 2.4)
		if topY - (y + h) < 1.2 then
			h = topY - y
		end
		local b = band()
		local centre = Vector3.new(mid.X, y + h / 2, mid.Z) + o0 * (-1.5 + rng:NextNumber() * 0.6)
		local blk = P(bar, { Name = "MarkedRock", Size = Vector3.new(23 + rng:NextNumber() * 1.5, h, len + rng:NextNumber() * 0.6), CFrame = CFrame.lookAt(centre, centre + tm) * CFrame.Angles(0, math.rad(rng:NextNumber() * 2 - 1), 0), Material = b[2], Color = b[1] })
		-- only the near face is meant to be climbed, but every side of marked rock is climbable (simple rule)
		blk:SetAttribute("Climbable", true)
		y += h
	end
	-- a fixed rope down the near face, centred on the road, + pitons
	local face = Vector3.new(c0.X, 0, c0.Z) - tm * 0.4 + o0 * 2
	local ra, rb = Vector3.new(face.X, c0.Y + 0.5, face.Z), Vector3.new(face.X, topY + 0.6, face.Z)
	Kit.decor(P(bar, { Name = "FixedRope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((rb - ra).Magnitude, 0.34, 0.34), CFrame = CFrame.new((ra + rb) / 2) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = COL.lantern }))
	for py = c0.Y + 4, topY, 5 do
		Kit.decor(P(bar, { Name = "Piton", Size = Vector3.new(0.4, 0.4, 1.2), CFrame = CFrame.lookAt(Vector3.new(face.X, py, face.Z), Vector3.new(face.X, py, face.Z) - tm), Material = Enum.Material.Metal, Color = COL.slate }))
	end
	report.scramble = string.format("scramble %.0f studs up the rockfall at s %d (top y %.0f)", SP.SCRAMBLE_H, SP.BARRIER[1], topY)

	------------------------------------------------ the lookout: a slab jutting out over the drop from the rockfall's top
	local lk = Kit.model(root, "Lookout")
	local lc = Vector3.new(mid.X, topY - 0.6, mid.Z) + o0 * 14
	P(lk, { Name = "LookoutSlab", Size = Vector3.new(10, 1.2, 9), CFrame = CFrame.lookAt(lc, lc + tm), Material = Enum.Material.Slate, Color = COL.slate })
	-- timber rail on its three open sides
	local corners = {}
	for _, q in ipairs({ { 5, -4.5 }, { 5, 4.5 }, { -2, 4.5 }, { -2, -4.5 } }) do
		corners[#corners + 1] = lc + o0 * q[1] + tm * q[2] + Vector3.new(0, 0.6, 0)
	end
	Kit.fence(lk, { corners[4], corners[1], corners[2], corners[3] }, 3)
	Kit.lantern(lk, lc + o0 * 3.5 + tm * 3.6 + Vector3.new(0, 0.6, 0), 5, true)
	report.lookout = string.format("lookout at (%.0f,%.0f,%.0f), drop below %.0f studs", lc.X, lc.Y, lc.Z, topY - ground(lc.X + o0.X * 6, lc.Z + o0.Z * 6))

	------------------------------------------------ stairs back down to the road
	local s1c = frame(SP.BARRIER[2])
	local a = Vector3.new(s1c.X, topY, s1c.Z) - tm * 1 - o0 * 0.5
	local sc = frame(SP.STAIRS_TO)
	local bpt = Vector3.new(sc.X, sc.Y, sc.Z) - o0 * 0.5
	-- Kit.stairs climbs from a (bottom) to b (top): bottom = the road, top = the rockfall
	Kit.stairs(root, bpt, a, 6)
	report.stairs = string.format("stairs %.1f studs down over %.0f studs", topY - sc.Y, (flat(a - bpt)).Magnitude)
	report.parts = string.format("%d parts + stairs, %d instances", n, #root:GetDescendants())
	return report
end

return SP
