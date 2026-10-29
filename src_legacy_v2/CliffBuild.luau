-- CliffBuild: Broken Cliffs (master.md §4: sandstone amber, charcoal slate, bright sky blue; signature
-- "Monumental bridge spanning an exposed chasm"; vertical scrambles, careful footing, caves/ledges).
-- Also provides edgeFences(), reused on every exposed stretch of the route above the forest.
local B = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

function B.dressSpec(Kit)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local c3 = P.pads.Camp3
	return {
		region = "BrokenCliffs", re0 = 705, re1 = 945, stride = 12, seed = 53,
		grove = { scale = 160, lo = 0.0, hi = 0.3 },
		items = {
			{ proto = "Pine", base = 0.03, groveBoost = 0.08, slopeMax = 0.9, scale = { 1.6, 2.6 }, colors = { C.forestTeal } },
			{ proto = "Bush", base = 0.03, groveBoost = 0.04, slopeMax = 1.0, scale = { 1.4, 2.2 }, colors = { C.forestTeal, C.meadow } },
			{ proto = "DeadTree", base = 0.006, slopeMax = 1.2, scale = { 1.6, 2.4 } },
		},
		rocks = { material = Enum.Material.Sandstone, prob = 0.006, slopeBoost = 0.025, rmin = 3, rmax = 9 },
		clear = { { c3.x, c3.z, 65 } },
	}
end

-- fences on the drop side wherever the ground falls away from the trail edge
function B.edgeFences(Kit, Gen, parent, pts, i0, i1, name)
	local folder = Kit.folder(parent, name or "EdgeFences")
	local run = {}
	local count = 0
	local function flush()
		if #run >= 3 then
			Kit.fence(folder, run, 3.4)
			count += 1
		end
		run = {}
	end
	local lastSide = 0
	for i = math.max(2, i0), math.min(#pts - 1, i1), 4 do
		local p = pts[i]
		local a, b = pts[i - 1], pts[i + 1]
		local d = Vector3.new(b[1] - a[1], 0, b[2] - a[2])
		if d.Magnitude > 0 then
			local side = d.Unit:Cross(Vector3.yAxis)
			local best, bestSide = 0, 0
			for _, s in ipairs({ -1, 1 }) do
				local q = Vector3.new(p[1], 0, p[2]) + side * s * 14
				local drop = p[3] - Gen.heightAt(q.X, q.Z)
				if drop > best then
					best, bestSide = drop, s
				end
			end
			if best > 7 then
				if lastSide ~= 0 and bestSide ~= lastSide then
					flush()
				end
				local f = Vector3.new(p[1], 0, p[2]) + side * bestSide * 8.6
				run[#run + 1] = Vector3.new(f.X, Gen.heightAt(f.X, f.Z), f.Z)
				lastSide = bestSide
			else
				flush()
				lastSide = 0
			end
		end
	end
	flush()
	return count
end

function B.build(Kit, Gen)
	local C = Kit.COL
	local P = _G.CC_PATHS
	local reg = Kit.folder(Kit.folder(Kit.folder(workspace, "World"), "Regions"), "BrokenCliffs")
	local old = reg:FindFirstChild("Authored")
	if old then
		old:Destroy()
	end
	local auth = Kit.folder(reg, "Authored")
	local function v3(p)
		return Vector3.new(p[1], p[3], p[2])
	end
	local function ground(p)
		return Vector3.new(p.X, Gen.heightAt(p.X, p.Z), p.Z)
	end
	local bo = workspace.World:FindFirstChild("Blockout")

	-- Monumental Chasm Bridge: stone gate towers, sagging suspension cables, hangers, plank deck
	for _, c in ipairs(P.crossings) do
		if c.path == "Main" and P.main[c.i0][3] > 800 then
			local a = v3(P.main[math.max(1, c.i0 - 4)])
			local b = v3(P.main[math.min(#P.main, c.i1 + 4)])
			local m = Kit.model(auth, "ChasmBridge")
			local dir = flat(b - a).Unit
			local right = dir:Cross(Vector3.yAxis).Unit
			local W = 14
			Kit.bridge(m, a, b, W, 3, "Deck")
			local towerTop = {}
			for _, e in ipairs({ { a, -1 }, { b, 1 } }) do
				local p, s = e[1], e[2]
				local t = {}
				for _, side in ipairs({ -1, 1 }) do
					local tp = p + right * side * (W / 2 + 3) - dir * s * 2
					Kit.part(m, { Name = "Tower", Size = Vector3.new(6, 46, 6), CFrame = CFrame.new(tp + Vector3.new(0, 18, 0)), Material = Enum.Material.Cobblestone, Color = C.masonry })
					Kit.part(m, { Name = "TowerCap", Size = Vector3.new(7.5, 2, 7.5), CFrame = CFrame.new(tp + Vector3.new(0, 42, 0)), Material = Enum.Material.Slate, Color = C.slate })
					t[side] = tp + Vector3.new(0, 40, 0)
				end
				Kit.part(m, { Name = "GateLintel", Size = Vector3.new(W + 12, 4, 5), CFrame = CFrame.lookAt(p + Vector3.new(0, 34, 0) - dir * s * 2, p + Vector3.new(0, 34, 0) - dir * s * 2 + right) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Cobblestone, Color = C.masonry })
				towerTop[s] = t
				Kit.lantern(m, p + right * (W / 2 + 6) - dir * s * 6, 8)
			end
			-- cables: catenary-ish sag from tower tops to just above the deck rail at mid-span
			for _, side in ipairs({ -1, 1 }) do
				local A, Bt = towerTop[-1][side], towerTop[1][side]
				local prev = A
				local n = 16
				for k = 1, n do
					local t = k / n
					local deckY = a.Y + (b.Y - a.Y) * t + math.sin(t * math.pi) * 3
					local sag = A:Lerp(Bt, t)
					local y = deckY + 6 + (sag.Y - deckY - 6) * (1 - math.sin(t * math.pi) ^ 0.7)
					local q = Vector3.new(sag.X, y, sag.Z)
					local cab = Kit.cylAB(prev, q, 0.9)
					cab.Material = Enum.Material.Metal
					cab.Color = C.slate
					cab.Parent = m
					if k < n then
						local deckPt = a:Lerp(b, t) + Vector3.new(0, math.sin(t * math.pi) * 3, 0) + right * side * (W / 2 - 0.4)
						local hanger = Kit.cylAB(deckPt + Vector3.new(0, 3.4, 0), q, 0.35)
						hanger.Material = Enum.Material.Metal
						hanger.Color = C.slate
						hanger.Parent = m
					end
					prev = q
				end
			end
		end
	end
	-- short gaps on the switchback ledges get plank ledge bridges
	for _, c in ipairs(P.crossings) do
		if c.path == "Main" and P.main[c.i0][3] > 450 and P.main[c.i0][3] < 800 then
			local a = v3(P.main[math.max(1, c.i0 - 4)])
			local b = v3(P.main[math.min(#P.main, c.i1 + 4)])
			Kit.bridge(auth, a, b, 12, 1.5, "LedgeBridge")
		end
	end
	if bo then
		for _, b in ipairs(bo.Bridges:GetChildren()) do
			local deck = b:FindFirstChild("Deck")
			if deck and deck.Position.Y > 450 and deck.Position.Y < 1000 then
				b:Destroy()
			end
		end
	end

	-- Camp 3 Chasm Hut: stone hut, fire, locker, beacon
	local camp = Kit.folder(auth, "Camp3_ChasmHut")
	local pad = P.pads.Camp3
	local Cc = Vector3.new(pad.x, pad.y, pad.z)
	local ci = P.wp.Camp3
	local cf = flat(v3(P.main[ci + 15]) - v3(P.main[ci - 15])).Unit
	local cr = cf:Cross(Vector3.yAxis).Unit
	local cm = (cr:Dot(flat(-Cc).Unit) > 0) and cr or -cr
	local co = -cm
	local hutPos = Cc + cm * 24 + Vector3.new(0, 1.4, 0)
	local hut = Kit.cabin(camp, CFrame.lookAt(hutPos, hutPos - cm), 24, 18, 10, { name = "ChasmHut", doorWidth = 6, roofColor = C.slate })
	for _, w in ipairs(hut:GetChildren()) do
		if w.Name:match("^Wall") or w.Name == "Lintel" or w.Name == "Gable" then
			w.Material = Enum.Material.Cobblestone
			w.Color = C.sandstone
		end
	end
	Kit.locker(camp, CFrame.lookAt(Cc + cm * 10 + cf * 10, Cc + cf * 10))
	local fire = Cc + co * 12
	Kit.campfire(camp, fire)
	for k = 0, 2 do
		local a = math.rad(-60 + k * 60)
		local bp = fire + (co * math.cos(a) + cf * math.sin(a)) * 8
		Kit.bench(camp, CFrame.lookAt(bp, Vector3.new(fire.X, bp.Y, fire.Z)))
	end
	local bpos = ground(Cc + co * 36)
	local beacon = Kit.model(camp, "Camp3_Beacon")
	Kit.part(beacon, { Name = "Pole", Size = Vector3.new(1.6, 24, 1.6), CFrame = CFrame.new(bpos + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = C.timberDark })
	local lamp = Kit.part(beacon, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.6, CFrame = CFrame.new(bpos + Vector3.new(0, 25.5, 0)), Material = Enum.Material.Neon, Color = C.lantern })
	Kit.decor(lamp)
	local bl = Instance.new("PointLight")
	bl.Color, bl.Range, bl.Brightness, bl.Shadows = C.lantern, 34, 2, false
	bl.Parent = lamp
	local sp = ground(Cc - cf * 38 + co * 9)
	Kit.sign(camp, CFrame.lookAt(sp, sp + cf) * CFrame.Angles(0, math.rad(90), 0), { { "Chasm Hut - Camp 3", 0 }, { "Stormwatch", math.rad(90) }, { "Rootgate", math.rad(-90) } }, 9)
	if bo and bo.CampBeacons:FindFirstChild("Camp3_Beacon") then
		bo.CampBeacons.Camp3_Beacon:Destroy()
	end

	-- edge fences on the switchback ledges (Camp 2 -> Camp 3) and the cliff-shelf stretch
	local fences = B.edgeFences(Kit, Gen, auth, P.main, P.wp.Camp2 + 20, P.wp.Camp3 - 10, "LedgeFences")
	return { fences = fences }
end

return B
