-- SliceBuild: authored Gate C pieces for Green Valley -> Camp 1 (Meadow Lodge).
-- Bridges, waterfall FX, band stairs, Camp 1 settlement, Falls Overlook, signs, route lanterns.
local S = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function telescope(Kit, parent, pos, facing)
	local COL = Kit.COL
	local m = Kit.model(parent, "Telescope")
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		local foot = pos + Vector3.new(math.cos(a) * 1.6, 0, math.sin(a) * 1.6)
		local leg = Kit.cylAB(foot, pos + Vector3.new(0, 4, 0), 0.35)
		leg.Name = "Leg"
		leg.Material = Enum.Material.Wood
		leg.Color = COL.timberDark
		leg.Parent = m
	end
	local tubeA = pos + Vector3.new(0, 4.4, 0) - facing * 1.8
	local tubeB = pos + Vector3.new(0, 5.4, 0) + facing * 2.2
	local tube = Kit.cylAB(tubeA, tubeB, 0.9)
	tube.Name = "Tube"
	tube.Material = Enum.Material.Metal
	tube.Color = COL.lantern
	tube.Parent = m
	return m
end
S.telescope = telescope

function S.build(Kit, Gen)
	local P = _G.CC_PATHS
	local COL = Kit.COL
	local world = Kit.folder(workspace, "World")
	local gv = Kit.folder(Kit.folder(world, "Regions"), "GreenValley")
	local auth = gv:FindFirstChild("Authored")
	if auth then
		auth:Destroy()
	end
	auth = Kit.folder(gv, "Authored")
	local function y(x, z)
		return Gen.heightAt(x, z)
	end
	local function v3(p)
		return Vector3.new(p[1], p[3], p[2])
	end

	-- remove blockout placeholders this slice replaces
	local bo = world:FindFirstChild("Blockout")
	if bo then
		for _, b in ipairs(bo.Bridges:GetChildren()) do
			if b.Name:match("^Main_Bridge_1$") or b.Name:match("^ValleyRing_Bridge") then
				b:Destroy()
			end
		end
		local beacon = bo.CampBeacons:FindFirstChild("Camp1_Beacon")
		if beacon then
			beacon:Destroy()
		end
	end

	-- bridges over the river (main route and valley ring)
	for _, c in ipairs(P.crossings) do
		local pts = c.path == "Main" and P.main or P.rings[c.path]
		local a, b = v3(pts[math.max(1, c.i0 - 3)]), v3(pts[math.min(#pts, c.i1 + 3)])
		if c.path == "Main" and a.Y < 300 then
			Kit.bridge(auth, a, b, 12, 6, "MeadowBridge")
		elseif c.path == "ValleyRing" then
			Kit.bridge(auth, a, b, 9, 4, "ValleyRingBridge")
		end
	end

	-- waterfall FX on the lip (terrain already holds the pool, creek and a water sheet)
	local F = { theta = 1.78 }
	local lx, lz = Gen.toWorld(F.theta, 1181)
	local outward = Vector3.new(math.sin(F.theta), 0, math.cos(F.theta))
	Kit.waterfall(auth, Vector3.new(lx, 325.5, lz), outward, 30, 214)

	-- stairs where the band climb beside the falls is steeper than 25%
	local stairs = Kit.folder(auth, "BandStairs")
	local i = P.wp.Camp1
	while i < P.wp.ForestEdge - 6 do
		local a, b = P.main[i], P.main[i + 6]
		if b[3] - a[3] > 4.5 then
			Kit.stairs(stairs, v3(a) + Vector3.new(0, 0.9, 0), v3(b) + Vector3.new(0, 0.9, 0), 11)
		end
		i += 6
	end

	-- Camp 1 Meadow Lodge
	local camp = Kit.folder(auth, "Camp1_MeadowLodge")
	local pad = P.pads.Camp1
	local C = Vector3.new(pad.x, pad.y, pad.z)
	local pin, pout = v3(P.main[P.wp.Camp1 - 20]), v3(P.main[P.wp.Camp1 + 20])
	local fwd = flat(pout - pin).Unit
	local right = fwd:Cross(Vector3.yAxis).Unit
	-- the mountain lies on the side pointing toward the summit axis
	local toAxis = flat(-C).Unit
	local mountainSide = (right:Dot(toAxis) > 0) and 1 or -1
	local mtn, out = right * mountainSide, right * -mountainSide
	local function at(off, h)
		local p = C + off
		return Vector3.new(p.X, (h or y(p.X, p.Z)), p.Z)
	end
	local lodgePos = at(mtn * 27, pad.y + 1.4)
	local lodge = Kit.cabin(camp, CFrame.lookAt(lodgePos, lodgePos - mtn), 34, 22, 13, { name = "MeadowLodge", doorWidth = 6 })
	lodge:SetAttribute("Camp", 1)
	Kit.locker(camp, CFrame.lookAt(at(mtn * 12 + fwd * 9, pad.y), at(fwd * 9, pad.y)))
	local fire = at(out * 14, pad.y)
	Kit.campfire(camp, fire)
	for k = 0, 2 do
		local a = math.rad(-60 + k * 60)
		local dir = (out * math.cos(a) + fwd * math.sin(a))
		local bp = fire + dir * 8
		Kit.bench(camp, CFrame.lookAt(Vector3.new(bp.X, pad.y, bp.Z), Vector3.new(fire.X, pad.y, fire.Z)))
	end
	-- beacon pole on the valley side, visible from below (camp beacons stay in the world, §0.5)
	local bpos = at(out * 38, pad.y)
	local beacon = Kit.model(camp, "Camp1_Beacon")
	Kit.part(beacon, { Name = "Pole", Size = Vector3.new(1.6, 24, 1.6), CFrame = CFrame.new(bpos + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
	local lamp = Kit.part(beacon, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(3.6, 3.6, 3.6), CFrame = CFrame.new(bpos + Vector3.new(0, 25.5, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
	Kit.decor(lamp)
	local bl = Instance.new("PointLight")
	bl.Color, bl.Range, bl.Brightness, bl.Shadows = COL.lantern, 34, 2, false
	bl.Parent = lamp
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		Kit.part(beacon, { Name = "Brace", Size = Vector3.new(0.6, 6, 0.6), CFrame = CFrame.new(bpos + Vector3.new(math.cos(a) * 1.6, 2.6, math.sin(a) * 1.6)) * CFrame.Angles(math.sin(a) * 0.35, 0, -math.cos(a) * 0.35), Material = Enum.Material.Wood, Color = COL.timber })
	end
	for k = -1, 1, 2 do
		Kit.lantern(camp, at(fwd * 30 * k + out * 6, pad.y), 7)
		Kit.lantern(camp, at(fwd * 30 * k + mtn * 6, pad.y), 7)
	end
	local signPos = at(-fwd * 40 + out * 9)
	Kit.sign(camp, CFrame.lookAt(signPos, signPos + fwd) * CFrame.Angles(0, math.rad(90), 0), {
		{ "Meadow Lodge - Camp 1", 0 },
		{ "Rootgate", math.rad(90) },
		{ "Foothold", math.rad(-90) },
	}, 9)

	-- camp dressing: valley-side fence, woodpile, crates, planters, two shade trees
	local routeNear = {}
	for k = P.wp.Camp1 - 40, P.wp.Camp1 + 40 do
		routeNear[#routeNear + 1] = v3(P.main[k])
	end
	local function clear(p, r)
		for _, q in ipairs(routeNear) do
			if (flat(q - p)).Magnitude < r then
				return false
			end
		end
		return true
	end
	local fencePts = {}
	for k = -5, 5 do
		local a = math.rad(k * 11)
		local dir = out * math.cos(a) + fwd * math.sin(a)
		local p = C + dir * 43
		if clear(p, 9) then
			fencePts[#fencePts + 1] = Vector3.new(p.X, pad.y, p.Z)
		elseif #fencePts > 1 then
			Kit.fence(camp, fencePts, 3.4)
			fencePts = {}
		else
			fencePts = {}
		end
	end
	if #fencePts > 1 then
		Kit.fence(camp, fencePts, 3.4)
	end
	local wp = at(mtn * 20 - fwd * 22, pad.y)
	local pile = Kit.model(camp, "Woodpile")
	for row = 0, 2 do
		for k = 0, 3 - row do
			local off = (k - (3 - row) / 2) * 1.7
			Kit.part(pile, { Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 1.6, 1.6), CFrame = CFrame.lookAt(wp, wp + fwd) * CFrame.new(off, 0.8 + row * 1.45, 0) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
	end
	for k = 1, 3 do
		local cp = at(mtn * (16 + k * 2.5) + fwd * (14 + (k % 2) * 3.5), pad.y)
		local s = 2.6 + (k % 2) * 0.8
		Kit.part(camp, { Name = "Crate", Size = Vector3.new(s, s, s), CFrame = CFrame.new(cp + Vector3.new(0, s / 2 + (k == 3 and 2.6 or 0), 0)) * CFrame.Angles(0, k * 0.4, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	end
	for k = 0, 9 do
		local a = math.rad(-150 + k * 33)
		local dir = out * math.cos(a) + fwd * math.sin(a)
		local p = C + dir * 40
		if clear(p, 10) then
			local kinds = { "FlowersGold", "FlowersTurq", "FlowersMoon" }
			Kit.place(camp, kinds[k % 3 + 1], Vector3.new(p.X, y(p.X, p.Z) - 0.2, p.Z), a, 1.4)
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		local tp = C + mtn * 38 + fwd * 34 * s
		if clear(tp, 12) then
			Kit.place(camp, "TreeRound", Vector3.new(tp.X, y(tp.X, tp.Z) - 0.5, tp.Z), s, 2.1, COL.leafLight)
		end
	end

	-- Falls Hut + dock on the pool shore (waterfall-side settlement)
	local px, pz = Gen.toWorld(1.78, 1222)
	local pool = Vector3.new(px, 214, pz)
	local toCamp = flat(C - pool).Unit
	local hutPos = pool + toCamp * 52
	hutPos = Vector3.new(hutPos.X, y(hutPos.X, hutPos.Z) + 1.2, hutPos.Z)
	Kit.cabin(camp, CFrame.lookAt(hutPos, Vector3.new(pool.X, hutPos.Y, pool.Z)), 14, 12, 8, { name = "FallsHut", chimney = false })
	local dockC = pool + toCamp * 26
	Kit.deck(camp, CFrame.lookAt(Vector3.new(dockC.X, 215.6, dockC.Z), Vector3.new(pool.X, 215.6, pool.Z)), 8, 16, 205, "back")

	-- Falls Overlook (first panoramic overlook, master.md §4)
	local ov = P.pads.FallsOverlook
	-- face the deck out over the river valley, turned toward the lake (straight south is blocked by the shelf)
	local phi = 1.88 - 0.6
	local look = Vector3.new(math.sin(phi), 0, math.cos(phi))
	local ovc = Vector3.new(ov.x, ov.y + 1, ov.z) + look * 6
	local over = Kit.folder(auth, "FallsOverlook")
	Kit.deck(over, CFrame.lookAt(ovc, ovc + look), 18, 14, ov.y - 10, "back")
	telescope(Kit, over, ovc + look * 3, look)
	Kit.bench(over, CFrame.lookAt(ovc - look * 3 + Vector3.new(0, 0, 0), ovc + look * 8))
	local sp = Vector3.new(ov.x, ov.y, ov.z) - look * 9
	Kit.sign(over, CFrame.lookAt(sp, sp + look) * CFrame.Angles(0, math.rad(90), 0), { { "Falls Overlook", 0 } }, 8)

	-- junction sign where the overlook spur leaves the main route
	local fe = v3(P.main[P.wp.ForestEdge])
	Kit.sign(auth, CFrame.new(fe + Vector3.new(6, 0, 6)), {
		{ "Rootgate", 0 },
		{ "Falls Overlook", math.rad(160) },
		{ "Meadow Lodge", math.rad(-110) },
	}, 8)
	-- Foothold gate sign beside the trail on the Foothold side (it used to stand on the centerline);
	-- boards point up the trail (+X) and back toward Foothold (+Z), never over the trail
	local g = v3(P.main[1]) + Vector3.new(0, 0, 11)
	Kit.sign(auth, CFrame.new(g.X, y(g.X, g.Z), g.Z), { { "Meadow Lodge", 0 }, { "Foothold", math.rad(-90) } }, 8)

	-- sparse route lanterns: every ~240 studs between the gate and Camp 1 (light only on alternate ones)
	local lanterns = Kit.folder(auth, "RouteLanterns")
	local s0 = 0
	local n = 0
	for k = 2, P.wp.Camp1 - 30 do
		if P.mainS[k] - s0 > 240 then
			s0 = P.mainS[k]
			local a, b = P.main[k - 1], P.main[k + 1]
			local d = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit
			local side = d:Cross(Vector3.yAxis).Unit * 9.5
			local p = v3(P.main[k]) + side
			n += 1
			Kit.lantern(lanterns, Vector3.new(p.X, y(p.X, p.Z) - 0.3, p.Z), 7, n % 2 == 0)
		end
	end
	return { stairs = #stairs:GetChildren(), lanterns = n }
end

return S
