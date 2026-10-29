-- LedgeP1 (v4 P1, 2026-10-20): Cliff Ledge Line, first section (master.md §0.8; v4-climb-concept §7 P1).
--   require(ServerStorage.CC_Generators:Clone().LedgeP1).build(require(ServerStorage.CC_Generators.Kit))
-- Needs the terrain with the Ledge route's stampSkip (s 40-640) applied (natural cliff, no stamped trail) and the
-- Ledge route in ReplicatedStorage.CC_Route (B.player). Run after B.camps (camps wipe World.Checkpoints).
-- Output: Workspace.World.LedgeP1 (+ World.Hazards.LedgeP1, two checkpoint triggers in World.Checkpoints).
-- Line (all placements PROPOSED): Ledge gate -> open foothills -> trailhead on the lower bench -> Face B (marked
-- strata face) -> Ledge L1 along the cliff contour with a fixed handline (a knife-ridge stretch standing off the
-- flank, a rest ledge + checkpoint, a rockfall chute crossed on a marked panel) -> the final pillar (ladder pitch,
-- then a marked face) -> the old ledge at s~645. Marked = Climbable attribute (CC_ClimbClient); everything else is
-- plain rock. Colors are existing Kit tokens: slate/sandstone strata (Broken Cliffs words, Ledge route identity =
-- sandstone), lantern ropes/flags (references: orange fixed ropes, glowing route flags), moon mist.
local LP = {}

LP.TH = Vector3.new(-470, 0, 1872) -- trailhead on the lower bench
LP.FACE_B = { x = -488, z = 1863, w = 11, top = 160 } -- bench -> L1
LP.L1 = { x0 = -489, x1 = -712, y0 = 160, y1 = 168, zLo = 1760, zHi = 1930 }
LP.FIN = { a = 0.08, b = 0.47, off = 16, ramp = 16 } -- run 2 fix: ~56 studs at full stand-off (was ~24); a ramp of 8 let walkers cut into air -- knife-ridge stretch (fractions of L1), stand-off from the flank, ramp
LP.REST = 0.50
LP.CHUTE = 0.76
LP.LADDER_TOP = 190 -- ladder from L1's end to here, then a marked face to the exit ledge
LP.EXIT_S = 645 -- Ledge route arc length where the section joins the old ledge
LP.APPROACH = { Vector3.new(-150, 0, 1834), Vector3.new(-300, 0, 1860) } -- flags gate -> trailhead

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
-- horizontal unit pointing down-slope at (x, z)
local function outwardAt(x, z)
	local gx = ground(x + 3, z) - ground(x - 3, z)
	local gz = ground(x, z + 3) - ground(x, z - 3)
	local v = Vector3.new(-gx, 0, -gz)
	return v.Magnitude > 1e-3 and v.Unit or Vector3.zAxis
end
-- z where the terrain at x crosses height y (terrain falls toward +z on this flank)
local function contourZ(x, y, zLo, zHi)
	for _ = 1, 22 do
		local m = (zLo + zHi) / 2
		if ground(x, m) > y then
			zLo = m
		else
			zHi = m
		end
	end
	return (zLo + zHi) / 2
end
local function routePoint(name, s)
	local sv = game:GetService("ReplicatedStorage"):FindFirstChild("CC_Route")
	sv = sv and sv:FindFirstChild(name)
	local best
	for tok in string.gmatch(sv and sv.Value or "", "[^;]+") do
		local x, y, z, ss = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		if tonumber(ss) >= s then
			best = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
			break
		end
	end
	return best
end

function LP.build(Kit)
	local COL = Kit.COL
	local world = Kit.folder(workspace, "World")
	local old = world:FindFirstChild("LedgeP1")
	if old then
		old:Destroy()
	end
	local root = Kit.folder(world, "LedgeP1")
	local hz = Kit.folder(world, "Hazards")
	local oldH = hz:FindFirstChild("LedgeP1")
	if oldH then
		oldH:Destroy()
	end
	local cps = Kit.folder(world, "Checkpoints")
	for _, n in ipairs({ "CP_LedgeP1_Start", "CP_LedgeP1_Rest" }) do
		local c = cps:FindFirstChild(n)
		if c then
			c:Destroy()
		end
	end
	local report = {}
	local nParts = 0
	local function P(parent, props)
		nParts += 1
		return Kit.part(parent, props)
	end

	-- strata: band heights and colors cycle deterministically (slate / sandstone / slate / lichen rock)
	local rng = Random.new(4207)
	-- run 2 fix (self-review "striped boxes"): faces are one rock mass. Strata differ in texture (Rock / Slate
	-- material) and a small shade step between the lichen-rock and slate tokens, never in hue; sandstone stays on
	-- the walking ledges (Ledge route identity) only.
	local function bandAt()
		local r = rng:NextNumber()
		local mat = (r < 0.6) and Enum.Material.Rock or Enum.Material.Slate
		return { COL.rock:Lerp(COL.slate, 0.08 + rng:NextNumber() * 0.3), mat }
	end

	-- a rock buttress with a vertical front at `front` (bottom-centre point; y ignored) facing `o` (outward):
	-- strata slabs from y0 to y1, each deep enough to reach back into the slope; marked climbable or not
	local function buttress(parent, name, front, o, width, y0, y1, climbable)
		local m = Kit.model(parent, name)
		local right = o:Cross(Vector3.yAxis).Unit
		local y, i = y0, 0
		while y < y1 - 0.01 do
			i += 1
			local band = bandAt()
			local h = math.min(y1 - y, 2.6 + rng:NextNumber() * 3.4)
			if y1 - (y + h) < 1.5 then
				h = y1 - y
			end
			-- depth: back from the front plane until the slope is above the band top (sampled at both edges)
			local depth = 4
			for _, k in ipairs({ -0.45, 0, 0.45 }) do
				local base = front + right * (width * k)
				for d = 0, 60, 1 do
					local q = base - o * d
					if ground(q.X, q.Z) > y + h + 1 then
						depth = math.max(depth, d + 2.5)
						break
					end
					if d == 60 then
						depth = math.max(depth, 60)
					end
				end
			end
			local jit = rng:NextNumber() * 0.5 - 0.2
			local c = Vector3.new(front.X, y + h / 2, front.Z) - o * (depth / 2 - jit)
			local s = P(m, {
				Name = climbable and "MarkedRock" or "Rock",
				Size = Vector3.new(width + rng:NextNumber() * 0.8, h, depth),
				CFrame = CFrame.lookAt(c, c + o) * CFrame.Angles(0, math.rad(rng:NextNumber() * 3 - 1.5), math.rad(rng:NextNumber() * 3 - 1.5)),
				Material = band[2],
				Color = band[1],
			})
			if climbable then
				s:SetAttribute("Climbable", true)
			end
			y += h
		end
		return m, i
	end

	-- fixed rope down a marked face (the cue that this rock is climbable) with pitons
	local function faceRope(parent, front, o, y0, y1)
		local a = Vector3.new(front.X, y0 + 0.5, front.Z) + o * 0.45
		local b = Vector3.new(front.X, y1 + 0.6, front.Z) + o * 0.45
		local r = P(parent, { Name = "FixedRope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((b - a).Magnitude, 0.34, 0.34), CFrame = CFrame.new((a + b) / 2) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = COL.lantern })
		Kit.decor(r)
		for y = y0 + 4, y1, 6 do
			Kit.decor(P(parent, { Name = "Piton", Size = Vector3.new(0.4, 0.4, 1.2), CFrame = CFrame.lookAt(Vector3.new(front.X, y, front.Z) + o * 0.3, Vector3.new(front.X, y, front.Z) + o * 2), Material = Enum.Material.Metal, Color = COL.slate }))
		end
	end

	-- glowing route flag on a cairn (guidance layer a; GuideOrder feeds the Guide pulse, layer b)
	local function marker(parent, pos, order, outward)
		local m = Kit.model(parent, "Flag_" .. order)
		local g = Vector3.new(pos.X, pos.Y, pos.Z)
		for k, sz in ipairs({ 2.2, 1.6, 1.1 }) do
			Kit.decor(P(m, { Name = "Cairn", Size = Vector3.new(sz, sz * 0.6, sz), CFrame = CFrame.new(g + Vector3.new(0.6, (k - 0.6) * sz * 0.6, 0.4)) * CFrame.Angles(0, k * 0.9, 0), Material = Enum.Material.Slate, Color = (k == 2) and COL.sandstone or COL.slate }))
		end
		Kit.decor(P(m, { Name = "Pole", Size = Vector3.new(0.35, 7, 0.35), CFrame = CFrame.new(g + Vector3.new(0, 3.5, 0)), Material = Enum.Material.Wood, Color = COL.timberDark }))
		local o = outward or Vector3.xAxis
		local flag = P(m, { Name = "GuideFlag", Size = Vector3.new(0.15, 1.5, 2.6), CFrame = CFrame.lookAt(g + Vector3.new(0, 6.2, 0) + o * 1.3, g + Vector3.new(0, 6.2, 0) + o * 1.3 + o:Cross(Vector3.yAxis)), Material = Enum.Material.SmoothPlastic, Color = COL.lantern })
		Kit.decor(flag)
		-- the glow: a small lamp bead on the pole top (a whole Neon flag blooms into a blob)
		Kit.decor(P(m, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.55, CFrame = CFrame.new(g + Vector3.new(0, 7.2, 0)), Material = Enum.Material.Neon, Color = COL.lantern }))
		flag:SetAttribute("GuideOrder", order)
		flag:SetAttribute("GuideRoute", "Ledge")
		local l = Instance.new("PointLight")
		l.Color = COL.lantern
		l.Range = 12
		l.Brightness = 0.9
		l.Shadows = false
		l.Parent = flag
		return m
	end

	local function trigger(name, pos, attrs)
		local t = Instance.new("Part")
		t.Name = name
		t.Anchored, t.CanCollide, t.CanQuery = true, false, false
		t.Transparency = 1
		t.Size = Vector3.new(16, 14, 16)
		t.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
		for k, v in pairs(attrs) do
			t:SetAttribute(k, v)
		end
		t.Parent = cps
		return t
	end

	------------------------------------------------ approach flags (gate -> trailhead, open foothills)
	local appr = Kit.folder(root, "Approach")
	for k, a in ipairs(LP.APPROACH) do
		marker(appr, Vector3.new(a.X, ground(a.X, a.Z), a.Z), k, Vector3.new(0, 0, 1))
	end

	------------------------------------------------ trailhead + Face B
	local th = Vector3.new(LP.TH.X, ground(LP.TH.X, LP.TH.Z), LP.TH.Z)
	marker(root, th, 3, Vector3.new(0, 0, 1))
	Kit.sign(root, CFrame.lookAt(th + Vector3.new(4, 0, 3), th + Vector3.new(4, 0, 8)), { { "CLIFF LEDGE LINE" }, { "Push into roped rock to climb" }, { "Jump = lunge  ·  X = let go" } }, 9)
	trigger("CP_LedgeP1_Start", th, { Checkpoint = "LedgeP1_Start", Label = "Cliff Ledge Line", Route = "Ledge", Order = 1, Camp = false })
	local FB = LP.FACE_B
	local oB = Vector3.new(0, 0, 1)
	local fbFront = Vector3.new(FB.x, 0, FB.z)
	local fbBase = ground(FB.x, FB.z + 2) - 2
	local _, nb = buttress(root, "FaceB", fbFront, oB, FB.w, fbBase, FB.top, true)
	faceRope(root, fbFront, oB, fbBase + 2, FB.top)
	report.faceB = string.format("Face B %d strata, %.0f -> %.0f (%.0f studs)", nb, fbBase + 2, FB.top, FB.top - fbBase - 2)

	------------------------------------------------ Ledge L1 along the contour
	local L = LP.L1
	local raw = {}
	for x = L.x0, L.x1, -4 do
		local t = (x - L.x0) / (L.x1 - L.x0)
		local y = L.y0 + (L.y1 - L.y0) * t
		raw[#raw + 1] = Vector3.new(x, y, contourZ(x, y, L.zLo, L.zHi))
	end
	for _ = 1, 3 do
		local sm = { raw[1] }
		for i = 2, #raw - 1 do
			sm[i] = Vector3.new(raw[i].X, raw[i].Y, (raw[i - 1].Z + raw[i].Z * 2 + raw[i + 1].Z) / 4)
		end
		sm[#raw] = raw[#raw]
		raw = sm
	end
	-- resample every 8 studs of arc
	local cum = { 0 }
	for i = 2, #raw do
		cum[i] = cum[i - 1] + (flat(raw[i]) - flat(raw[i - 1])).Magnitude
	end
	local total = cum[#cum]
	local function at(s)
		for i = 2, #raw do
			if cum[i] >= s then
				local k = (s - cum[i - 1]) / math.max(1e-3, cum[i] - cum[i - 1])
				return raw[i - 1]:Lerp(raw[i], k), flat(raw[i] - raw[i - 1]).Unit
			end
		end
		return raw[#raw], flat(raw[#raw] - raw[#raw - 1]).Unit
	end
	local l1 = Kit.folder(root, "L1")
	local SEG = 8
	local nSeg = math.floor(total / SEG)
	local chuteS, restS = total * LP.CHUTE, total * LP.REST
	local finA, finB = total * LP.FIN.a, total * LP.FIN.b
	local function finOff(s)
		if s <= finA or s >= finB then
			return 0
		end
		local k = math.clamp(math.min(s - finA, finB - s) / LP.FIN.ramp, 0, 1)
		return LP.FIN.off * k * k * (3 - 2 * k)
	end
	-- walk centre of segment k (fin decks run between the midpoints of these, so the spur walkway is continuous)
	local function walkCentre(k)
		local s = (math.clamp(k, 0, nSeg - 1) + 0.5) * SEG
		local c, t = at(s)
		local o = outwardAt(c.X, c.Z)
		o = flat(o - t * o:Dot(t)).Unit
		return c + o * (1.6 + finOff(s))
	end
	local pitons = {}
	local restPos, chutePos, chuteO, finStart, chuteEdgeE
	for k = 0, nSeg - 1 do
		local s = (k + 0.5) * SEG
		local c, t = at(s)
		local o = outwardAt(c.X, c.Z)
		o = flat(o - t * o:Dot(t)).Unit -- perpendicular to the ledge
		local cf = function(center)
			return CFrame.lookAt(center, center + t)
		end
		local inChute = math.abs(s - chuteS) < 4
		local off = finOff(s)
		if inChute then
			-- the gap: no floor; a marked traverse panel on the back wall, a scree chute below
			chutePos, chuteO = c, o
			-- 0.4 proud of the back wall so face rays always meet the marked rock first
			-- as tall as the back wall (top 12 above the ledge) so it can't be jumped onto to skip the crossing
			local panel = P(l1, { Name = "MarkedPanel", Size = Vector3.new(2, 15, SEG + 6), CFrame = cf(c - o * 0.6 + Vector3.new(0, 4.5, 0)), Material = Enum.Material.Slate, Color = COL.rock:Lerp(COL.slate, 0.4) })
			panel:SetAttribute("Climbable", true)
			-- the chute floor: carve the terrain under the gap and line it with a 63-degree scree plate, so a
			-- dropped climber slides out of the chute (no foothold to stand on or to cross the gap from)
			local TAN = 1.96
			local function plateY(d)
				return c.Y - 1.5 - (d + 0.5) * TAN
			end
			local lo = c + Vector3.new(-22, -44, -22)
			local hi = c + Vector3.new(22, 4, 22)
			local region = Region3.new(lo, hi):ExpandToGrid(4)
			local mats, occ = workspace.Terrain:ReadVoxels(region, 4)
			local sz = mats.Size
			for ix = 1, sz.X do
				for iy = 1, sz.Y do
					for iz = 1, sz.Z do
						local vc = region.CFrame.Position - region.Size / 2 + Vector3.new(ix - 0.5, iy - 0.5, iz - 0.5) * 4
						local rel = Vector3.new(vc.X - c.X, 0, vc.Z - c.Z)
						local al, d = rel:Dot(t), rel:Dot(o)
						if math.abs(al) < 6 and d > -3 and d < 20 and vc.Y > plateY(d) - 2 and vc.Y < c.Y + 3 and occ[ix][iy][iz] > 0 then
							mats[ix][iy][iz], occ[ix][iy][iz] = Enum.Material.Air, 0
						end
					end
				end
			end
			workspace.Terrain:WriteVoxels(region, 4, mats, occ)
			local pa, pb = c + o * -0.5 + Vector3.new(0, plateY(-0.5) - c.Y, 0), c + o * 19 + Vector3.new(0, plateY(19) - c.Y, 0)
			local plate = P(l1, { Name = "ChuteScree", Size = Vector3.new(SEG + 2, 1.2, (pb - pa).Magnitude), CFrame = CFrame.lookAt((pa + pb) / 2, pb), Material = Enum.Material.Slate, Color = COL.rock })
			plate.CustomPhysicalProperties = PhysicalProperties.new(2.7, 0.05, 0.1, 100, 1)
		elseif off > 0.5 then
			-- knife-ridge stretch: a rock spur standing off the flank; open drops on both sides, no handline
			local w0, w1, w2 = walkCentre(k - 1), walkCentre(k), walkCentre(k + 1)
			local m1, m2 = (w0 + w1) / 2, (w1 + w2) / 2
			m1, m2 = Vector3.new(m1.X, c.Y - 1, m1.Z), Vector3.new(m2.X, c.Y - 1, m2.Z)
			local dc = (m1 + m2) / 2
			local dcf = CFrame.lookAt(dc, dc + flat(m2 - m1).Unit)
			local len = (flat(m2 - m1)).Magnitude + 1
			local d = w1
			local gB = ground(dc.X, dc.Z)
			P(l1, { Name = "FinDeck", Size = Vector3.new(4.4, 2, len), CFrame = dcf, Material = Enum.Material.Sandstone, Color = COL.sandstone })
			local hBody = (c.Y - 2) - (gB - 3)
			if hBody > 1 then
				local bb = bandAt()
				P(l1, { Name = "FinBody", Size = Vector3.new(4, hBody * 0.7, len - 0.4), CFrame = dcf + Vector3.new(0, -1 - hBody * 0.35, 0), Material = bb[2], Color = bb[1] })
				local rb = bandAt()
				P(l1, { Name = "FinRoot", Size = Vector3.new(6, hBody * 0.3 + 2, len + 0.6), CFrame = dcf + Vector3.new(0, (gB - 3 + (hBody * 0.3 + 2) / 2) - (c.Y - 1), 0), Material = rb[2], Color = rb[1] })
			end
			if not finStart then
				finStart = Vector3.new(d.X, c.Y, d.Z)
			end
		else
			local wide = math.abs(s - restS) < 6
			local w = wide and 8 or 4.2
			local floor = P(l1, { Name = wide and "RestLedge" or "Ledge", Size = Vector3.new(w, 2.2, SEG + 0.6), CFrame = cf(c + o * (w / 2 - 0.5) - Vector3.new(0, 1.1, 0)), Material = Enum.Material.Sandstone, Color = COL.sandstone })
			if wide then
				floor:SetAttribute("RestLedge", true)
				restPos = c + o * 3.5
			end
			-- the cliff band the ledge is cut into: a tall back wall (ragged top) and rock under the ledge
			local bh = 11 + rng:NextNumber() * 6
			local bb = bandAt()
			P(l1, { Name = "Backing", Size = Vector3.new(3, bh, SEG + 0.8), CFrame = cf(c - o * 1.5 + Vector3.new(0, bh / 2 - 1, 0)) * CFrame.Angles(math.rad(rng:NextNumber() * 4 - 2), 0, math.rad(rng:NextNumber() * 3)), Material = bb[2], Color = bb[1] })
			local ub = bandAt()
			P(l1, { Name = "UnderBand", Size = Vector3.new(3.4, 9, SEG + 0.4), CFrame = cf(c + o * (w - 2.4) - Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, 0, math.rad(-6 - rng:NextNumber() * 6)), Material = ub[2], Color = ub[1] })
			if k % 2 == 0 and not (s > finA - 6 and s < finB + 6) then
				pitons[#pitons + 1] = c + Vector3.new(0, 3.4, 0) + o * 0.1
			end
			if s > chuteS - 12 and s < chuteS - 4 then
				chuteEdgeE = c + o * 1.6
			end
		end
	end
	-- handline between consecutive pitons (skipped over the fin and the chute)
	for i = 1, #pitons do
		local p = pitons[i]
		Kit.decor(P(l1, { Name = "Piton", Size = Vector3.new(0.4, 0.4, 1.2), CFrame = CFrame.new(p), Material = Enum.Material.Metal, Color = COL.slate }))
		local q = pitons[i + 1]
		if q and (q - p).Magnitude < SEG * 2.6 then
			local sag = (p + q) / 2 - Vector3.new(0, 0.5, 0)
			for _, ab in ipairs({ { p, sag }, { sag, q } }) do
				Kit.decor(P(l1, { Name = "Handline", Shape = Enum.PartType.Cylinder, Size = Vector3.new((ab[2] - ab[1]).Magnitude, 0.3, 0.3), CFrame = CFrame.lookAt((ab[1] + ab[2]) / 2, ab[2]) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.lantern }))
			end
		end
	end
	local l1Start = at(0)
	local l1End, tEnd = at(nSeg * SEG) -- where the last slab ends (the pillar floor overlaps it)
	report.l1 = string.format("L1 %.0f studs, %d segments, y %.0f -> %.0f", total, nSeg, l1Start.Y, l1End.Y)

	-- markers along L1 + the rest ledge checkpoint
	marker(root, l1Start + outwardAt(l1Start.X, l1Start.Z) * 2.4, 4, outwardAt(l1Start.X, l1Start.Z))
	if finStart then
		marker(root, finStart, 5, outwardAt(finStart.X, finStart.Z))
	end
	if restPos then
		marker(root, restPos + Vector3.new(0, 0, 0), 6, outwardAt(restPos.X, restPos.Z))
		trigger("CP_LedgeP1_Rest", restPos, { Checkpoint = "LedgeP1_Rest", Label = "Ledge rest", Route = "Ledge", Order = 2, Camp = false })
	end
	if chuteEdgeE then
		marker(root, chuteEdgeE, 7, outwardAt(chuteEdgeE.X, chuteEdgeE.Z))
	end

	------------------------------------------------ rockfall chute (tell: dust + pulsing strip; rocks fall past the panel)
	if chutePos then
		local m = Kit.model(Kit.folder(hz, "LedgeP1"), "Rockfall_Chute")
		local top = chutePos + chuteO * 1.8 + Vector3.new(0, 26, 0)
		local bot = chutePos + chuteO * 16 - Vector3.new(0, 26, 0)
		for k, v in pairs({ Kind = "Rockfall", Route = "Ledge", Period = 8, Tell = 3, Offset = 0, Strength = 30, Center = chutePos, TrailDir = tEnd, Outward = chuteO, Top = top, Bottom = bot, Radius = 2.6, Straight = true }) do
			m:SetAttribute(k, v)
		end
		-- the chute itself: a dark groove above the panel (where the rocks come from)
		Kit.decor(P(m, { Name = "ChuteGroove", Size = Vector3.new(1, 22, 6), CFrame = CFrame.lookAt(chutePos - chuteO * 1.2 + Vector3.new(0, 15, 0), chutePos + Vector3.new(0, 15, 0)), Material = Enum.Material.Slate, Color = COL.slate }))
		report.chute = string.format("chute at (%.0f,%.0f,%.0f) period 8 tell 3", chutePos.X, chutePos.Y, chutePos.Z)
	end

	------------------------------------------------ final pillar: ladder pitch, then a marked face to the old ledge
	local exitP = routePoint("Ledge", LP.EXIT_S)
	local oE = outwardAt(l1End.X, l1End.Z)
	oE = flat(oE - tEnd * oE:Dot(tEnd)).Unit
	-- axis ~5 studs past the last slab: with L1 ending at x -712 this lands on the old ledge's walkable start
	local pillarFront = l1End + tEnd * 5 - oE * 0.8
	local exitY = exitP and exitP.Y or 212
	local pil = Kit.model(root, "Pillar")
	local _, np1 = buttress(pil, "PillarLower", pillarFront, oE, 10, l1End.Y - 3, LP.LADDER_TOP, false)
	-- the upper pitch is wider so its top meets the old ledge with room to spare (13 studs)
	local _, np2 = buttress(pil, "PillarUpper", pillarFront, oE, 13, LP.LADDER_TOP, exitY, true)
	-- the floor under the ladder: L1 runs on to the pillar foot
	P(pil, { Name = "Ledge", Size = Vector3.new(4.2, 2.2, 10.5), CFrame = CFrame.lookAt(l1End + tEnd * 2.5 + oE * 1.6 - Vector3.new(0, 1.1, 0), l1End + tEnd * 3.5 + oE * 1.6 - Vector3.new(0, 1.1, 0)), Material = Enum.Material.Sandstone, Color = COL.sandstone })
	-- ladder: steel rails + rungs on the lower pillar, one invisible marked plane behind them
	local lad = Kit.model(pil, "Ladder")
	local lb = Vector3.new(pillarFront.X, l1End.Y, pillarFront.Z) + oE * 0.6
	local right = oE:Cross(Vector3.yAxis).Unit
	local H = LP.LADDER_TOP - l1End.Y + 1
	for _, sgn in ipairs({ -1, 1 }) do
		Kit.decor(P(lad, { Name = "Rail", Size = Vector3.new(0.3, H, 0.3), CFrame = CFrame.new(lb + right * 1.2 * sgn + Vector3.new(0, H / 2, 0)), Material = Enum.Material.Metal, Color = COL.slate }))
	end
	for y = 1, H - 0.5, 1.4 do
		Kit.decor(P(lad, { Name = "Rung", Size = Vector3.new(2.4, 0.22, 0.22), CFrame = CFrame.lookAt(lb + Vector3.new(0, y, 0), lb + Vector3.new(0, y, 0) + oE), Material = Enum.Material.Metal, Color = COL.slate }))
	end
	-- run 2: 6 wide (a 3-wide grip lost off-centre grabs)
	local plane = P(lad, { Name = "LadderGrip", Size = Vector3.new(6, H, 0.4), CFrame = CFrame.lookAt(lb - oE * 0.2 + Vector3.new(0, H / 2, 0), lb - oE * 0.2 + Vector3.new(0, H / 2, 0) + oE), Transparency = 1, Material = Enum.Material.SmoothPlastic })
	plane:SetAttribute("Climbable", true)
	faceRope(pil, pillarFront, oE, LP.LADDER_TOP + 1, exitY)
	marker(root, l1End + oE * 2.2, 8, oE)
	if exitP then
		marker(root, exitP + flat(exitP - pillarFront).Unit * -1, 9, oE)
	end
	report.pillar = string.format("pillar ladder %.0f -> %d, face -> %.0f (%d + %d strata); exit (%.0f,%.0f,%.0f)", l1End.Y, LP.LADDER_TOP, exitY, np1, np2, exitP and exitP.X or 0, exitY, exitP and exitP.Z or 0)

	------------------------------------------------ atmosphere (static): cloud layer below L1, light shafts on the hero view
	local atm = Kit.folder(root, "Atmosphere")
	-- cloud layer below L1: three soft-particle volumes (engine smoke texture, ~15 particles each), no hard edges
	for k, c in ipairs({ Vector3.new(-560, 112, 1950), Vector3.new(-650, 108, 1965), Vector3.new(-740, 115, 1945) }) do
		local host = P(atm, { Name = "MistVolume", Size = Vector3.new(90, 8, 70), CFrame = CFrame.new(c), Transparency = 1 })
		host.CanCollide, host.CanQuery, host.CanTouch, host.CastShadow = false, false, false, false
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Mist"
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(COL.moon)
		pe.LightInfluence = 0.7
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 34), NumberSequenceKeypoint.new(1, 52) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.72), NumberSequenceKeypoint.new(0.75, 0.78), NumberSequenceKeypoint.new(1, 1) })
		pe.Lifetime = NumberRange.new(26, 34)
		pe.Rate = 0.5
		pe.Speed = NumberRange.new(0.3, 0.9)
		pe.SpreadAngle = Vector2.new(180, 8)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Shape = Enum.ParticleEmitterShape.Box
		pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		pe.Rotation = NumberRange.new(0, 360)
		pe.RotSpeed = NumberRange.new(-2, 2)
		pe.Parent = host
	end
	local sun = Vector3.new(-0.45, -0.8, 0.4).Unit
	local hero = restPos or l1Start
	for k = 1, 3 do
		local foot = hero + Vector3.new(-20 + k * 15, -30, 30 + k * 6)
		local len = 170
		local sh = P(atm, { Name = "LightShaft", Size = Vector3.new(4 + k, len, 0.4), CFrame = CFrame.fromMatrix(foot - sun * len / 2, sun:Cross(Vector3.zAxis).Unit, -sun), Material = Enum.Material.Neon, Color = COL.golden, Transparency = 0.955 })
		sh.CanCollide, sh.CanQuery, sh.CanTouch, sh.CastShadow = false, false, false, false
	end

	------------------------------------------------ v4 P2 fix: the cliff above the bench reads as rock, not foothill earth
	-- (P1 self-review: "rock structures on an earth cliff"); terrain Mud / Salt -> Rock (lichen rock token) in the box
	-- 8-stud bands with ragged east/west ends, so the edge of the repaint is not a straight seam
	for yb = 104, 248, 8 do
		local e = -430 + math.noise(yb * 0.07, 1.3) * 60
		local w = -770 + math.noise(yb * 0.07, 7.9) * 40
		local cliff = Region3.new(Vector3.new(w, yb, 1784), Vector3.new(e, yb + 8, 1912)):ExpandToGrid(4)
		workspace.Terrain:ReplaceMaterial(cliff, 4, Enum.Material.Mud, Enum.Material.Rock)
		workspace.Terrain:ReplaceMaterial(cliff, 4, Enum.Material.Salt, Enum.Material.Rock)
	end

	report.parts = string.format("%d parts, %d instances in World.LedgeP1", nParts, #root:GetDescendants())
	return report
end

return LP
