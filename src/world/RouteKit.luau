-- RouteKit (V3 Ascent, P4/P5): builds the route network's world pieces from _G.CC_PATHS.
--   RK.camps(Kit, Gen)                 camps 1-4 + merge: lodge, campfire, locker, beacon, route signpost, trigger
--   RK.route(Kit, Gen, name)           one route: bridges at its crossings, checkpoint markers + triggers,
--                                      route-style wayfinding (Shepherd: lanterns + fences on drop sides)
--   RK.hazards(Kit, Gen, name)         hazard models (attributes drive the client cycle; see runtime/AscentClient)
-- Triggers live in Workspace.World.Checkpoints and carry attributes the CheckpointService reads:
--   Checkpoint (name), Route ("*" for camps), Order (index along the route), Camp (bool).
-- All placements PROPOSED; colors are Kit.COL tokens.
local C = require(script.Parent.WorldConfig)
local RK = {}

local UP = Vector3.yAxis
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local STYLE = {
	Shepherd = { col = "meadow", bridgeW = 10, rail = "fence" },
	Waterfall = { col = "turquoise", bridgeW = 8, rail = "lantern" },
	Ledge = { col = "sandstone", bridgeW = 5, rail = "rope" },
	Spire = { col = "ice", bridgeW = 4, rail = "cairn" },
	SummitStair = { col = "ice", bridgeW = 8, rail = "rope" },
}
RK.STYLE = STYLE

local function pt(R, i)
	local p = R.pts[math.clamp(i, 1, #R.pts)]
	return Vector3.new(p[1], p[3], p[2])
end
local function dirAt(R, i)
	return flat(pt(R, i + 3) - pt(R, i - 3)).Unit
end
-- unit vector across the route pointing downhill (away from the summit axis)
local function outward(R, i)
	local r = dirAt(R, i):Cross(UP)
	return (r:Dot(flat(pt(R, i))) > 0) and r or -r
end
RK.pt, RK.dirAt, RK.outward = pt, dirAt, outward

local function trigger(parent, name, pos, size, attrs)
	local t = Instance.new("Part")
	t.Name = name
	t.Anchored = true
	t.CanCollide = false
	t.CanQuery = false
	t.CanTouch = true
	t.Transparency = 1
	t.Size = size
	t.CFrame = CFrame.new(pos + Vector3.new(0, size.Y / 2 - 1, 0))
	for k, v in pairs(attrs) do
		t:SetAttribute(k, v)
	end
	t.Parent = parent
	return t
end

local function cpFolder(Kit)
	return Kit.folder(Kit.folder(workspace, "World"), "Checkpoints")
end

---------------------------------------------------------------- camps
local CAMP_NAMES = { Camp1 = "Meadow Lodge", Camp2 = "Rootgate", Camp3 = "Chasm Hut", Camp4 = "Stormwatch", Merge = "Crown Approach" }
RK.CAMP_NAMES = CAMP_NAMES

function RK.camps(Kit, Gen)
	local COL = Kit.COL
	local P = _G.CC_PATHS
	local root = Kit.folder(Kit.folder(workspace, "World"), "Camps")
	for _, c in ipairs(root:GetChildren()) do
		c:Destroy()
	end
	local cps = cpFolder(Kit)
	for i, name in ipairs({ "Camp1", "Camp2", "Camp3", "Camp4", "Merge" }) do
		local pad = P.pads[name]
		local c0 = Vector3.new(pad.x, pad.y, pad.z)
		-- v5: the camp's props cluster on the side of the pad no trail uses (trails crossed the fire / bench ring)
		local dirs = {}
		for _, R in pairs(P.routes) do
			local wi = R.wp and R.wp[name]
			if wi then
				for _, o in ipairs({ -20, 20 }) do
					local q = pt(R, wi + o)
					local v = flat(q - c0)
					if v.Magnitude > 3 then
						dirs[#dirs + 1] = v.Unit
					end
				end
			end
		end
		if name == "Merge" and P.routes.SummitStair then
			local v = flat(pt(P.routes.SummitStair, 12) - c0)
			if v.Magnitude > 3 then
				dirs[#dirs + 1] = v.Unit
			end
		end
		local out = flat(c0).Unit
		if #dirs > 0 then
			local best, bestA = -1, 0
			for k = 0, 71 do
				local a = k * math.pi / 36
				local v = Vector3.new(math.sin(a), 0, math.cos(a))
				local worst = math.huge
				for _, dv in ipairs(dirs) do
					worst = math.min(worst, math.acos(math.clamp(v:Dot(dv), -1, 1)))
				end
				if worst > best then
					best, bestA = worst, a
				end
			end
			out = Vector3.new(math.sin(bestA), 0, math.cos(bestA))
		end
		local side = out:Cross(UP).Unit
		local m = Kit.folder(root, name)
		local fireP = c0 + out * 16
		Kit.campfire(m, fireP)
		if name ~= "Merge" then
			local lp = c0 + out * (pad.radius - 22) - side * 12
			lp = Vector3.new(lp.X, pad.y + 1.4, lp.Z)
			Kit.cabin(m, CFrame.lookAt(lp, lp - out), 22, 16, 10, { name = "Lodge", doorWidth = 6 })
			Kit.locker(m, CFrame.lookAt(c0 + out * 24 + side * 10, c0 + out * 24))
			for k = 0, 3 do
				Kit.bench(m, CFrame.lookAt(fireP + Vector3.new(math.cos(k * 1.57) * 8, 0, math.sin(k * 1.57) * 8), fireP) * CFrame.Angles(0, math.rad(90), 0))
			end
		end
		-- beacon: tall pole with a lantern-gold glow, visible from below (camp beacons stay in the world)
		local bp = c0 + out * (pad.radius - 6) + side * 18
		bp = Vector3.new(bp.X, pad.y, bp.Z)
		Kit.part(m, { Name = "BeaconPole", Size = Vector3.new(1.2, 26, 1.2), CFrame = CFrame.new(bp + Vector3.new(0, 13, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
		local g = Kit.part(m, { Name = "Beacon", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.4, CFrame = CFrame.new(bp + Vector3.new(0, 27, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
		Kit.decor(g)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = COL.lantern, 30, 1.6, false
		l.Parent = g
		-- signpost: camp name + the routes that leave it
		local lines = { { CAMP_NAMES[name], 0 } }
		if name ~= "Merge" then
			for _, rn in ipairs({ "Shepherd", "Waterfall", "Ledge", "Spire" }) do
				local R = P.routes[rn]
				local wi = R and R.wp[name]
				if wi then
					local ahead = pt(R, wi + 25)
					local d = flat(ahead - c0)
					local yaw = math.atan2(-d.X, -d.Z) - math.atan2(-out.X, -out.Z)
					lines[#lines + 1] = { R.def.label, yaw }
				end
			end
		else
			lines[2] = { "Summit stair", 0 }
		end
		Kit.sign(m, CFrame.lookAt(c0 + out * 12 - side * 16, c0 + out * 12 - side * 16 - out), lines, 11)
		trigger(cps, "CP_" .. name, c0, Vector3.new(pad.radius * 1.6, 14, pad.radius * 1.6), {
			Checkpoint = name,
			Label = CAMP_NAMES[name],
			Route = "*",
			Order = i,
			Camp = true,
		})
	end
	-- summit: the last checkpoint for everyone
	local sc = P.pads.SummitCrown
	trigger(cps, "CP_Summit", Vector3.new(sc.x, sc.y, sc.z), Vector3.new(36, 14, 36), { Checkpoint = "Summit", Label = "Summit", Route = "*", Order = 9, Camp = true })
	return true
end

---------------------------------------------------------------- one route
function RK.route(Kit, Gen, name)
	local COL = Kit.COL
	local P = _G.CC_PATHS
	local R = P.routes[name]
	local st = STYLE[name]
	local root = Kit.folder(Kit.folder(workspace, "World"), "Routes")
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Kit.folder(root, name)
	local counts = { bridges = 0, markers = 0, lanterns = 0, fenceRuns = 0, ropeRuns = 0, cairns = 0 }
	-- v4: stretches the route does NOT stamp (R.skips, authored climbs: LedgeP1, ClimbKit stacks) get none of this
	local function skipped(i)
		local s0 = R.S[math.clamp(i, 1, #R.S)]
		for _, r in ipairs(R.skips or {}) do
			if s0 >= r[1] - 12 and s0 <= r[2] + 12 then
				return true
			end
		end
		return false
	end
	RK.skipped = skipped
	-- hang lines keep their lane (stamped) but close it with notches: no checkpoint or hazard on the closed lane
	-- (a respawn there would be stranded between the notches)
	local function inHang(i)
		local s0 = R.S[math.clamp(i, 1, #R.S)]
		for _, ln in ipairs(R.def.lines or {}) do
			if ln.kind == "hang" and ln.s0 and s0 >= ln.s0 - 30 and s0 <= ln.s1 + 30 then
				return true
			end
		end
		return false
	end
	RK.inHang = inHang

	-- bridges at this route's crossings (water, chasm, dips the trail can't stand on)
	local bf = Kit.folder(f, "Bridges")
	local onBridge = {}
	for _, cr in ipairs(P.crossings) do
		if cr.path == name and not skipped(cr.i0) and not skipped(cr.i1) then
			local a, b = pt(R, cr.i0 - 2), pt(R, cr.i1 + 2)
			local span = flat(b - a).Magnitude
			Kit.bridge(bf, a, b, st.bridgeW, math.min(3, span * 0.03), "Bridge_" .. cr.i0)
			for i = cr.i0 - 3, cr.i1 + 3 do
				onBridge[i] = true
			end
			counts.bridges += 1
		end
	end

	-- built stone ramps where the trail is steeper than 0.5 or its ground is past the 45 deg slope limit:
	-- smooth parts at <= 38.7 deg are walkable where 4-stud voxel faces are not (P2 bot: summit stair)
	local rf = Kit.folder(f, "Ramps")
	local rpar = RaycastParams.new()
	rpar.FilterType = Enum.RaycastFilterType.Include
	rpar.FilterDescendantsInstances = { workspace.Terrain }
	local rampW = math.max(5, (R.def.hw or 4) * 2 + 1)
	local i = 2
	while i < #R.pts - 4 do
		local a, b = pt(R, i), pt(R, i + 4)
		local g = math.abs(b.Y - a.Y) / math.max(0.1, flat(b - a).Magnitude)
		local hit = workspace:Raycast(a + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), rpar)
		if not onBridge[i] and not skipped(i) and not skipped(i + 4) and (g > 0.5 or (hit and hit.Normal.Y < 0.74)) then
			local mid = (a + b) / 2
			local rcf = CFrame.lookAt(mid, b) * CFrame.new(0, -0.9, 0)
			local len = (b - a).Magnitude + 1.2
			-- clear voxels poking through the ramp top (P4a bot stucks on the summit stair)
			workspace.Terrain:FillBlock(rcf * CFrame.new(0, 4.6, 0), Vector3.new(rampW - 1, 7, len), Enum.Material.Air)
			Kit.part(rf, {
				Name = "Ramp",
				Size = Vector3.new(rampW, 2, len),
				CFrame = rcf,
				Material = Enum.Material.Slate,
				Color = COL.masonry,
			})
			counts.ramps = (counts.ramps or 0) + 1
		end
		i += 4
	end

	-- checkpoint markers: cairn + pennant pole + glow; trigger box across the trail
	local cps = cpFolder(Kit)
	for _, t in ipairs(cps:GetChildren()) do
		if t:GetAttribute("Route") == name then
			t:Destroy() -- re-running a route replaces its own triggers
		end
	end
	local mf = Kit.folder(f, "Checkpoints")
	if R.checkpoints then
		local order = 0
		for _, cp in ipairs(R.checkpoints) do
			order += 1
			if not cp.camp and not skipped(cp.i) and not inHang(cp.i) then
				local p = pt(R, cp.i)
				local o = outward(R, cp.i)
				local mp = p - o * ((R.def.hw or 4) + 3)
				mp = Vector3.new(mp.X, Gen.heightAt(mp.X, mp.Z), mp.Z)
				Kit.place(mf, "Cairn", mp, 0, 1.2)
				Kit.part(mf, { Name = "PennantPole", Size = Vector3.new(0.5, 9, 0.5), CFrame = CFrame.new(mp + Vector3.new(0, 4.5, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
				local pen = Kit.part(mf, { Name = "Pennant", Size = Vector3.new(0.2, 1.8, 3), CFrame = CFrame.new(mp + Vector3.new(0, 8, 1.5)), Material = Enum.Material.Fabric, Color = COL[st.col] })
				Kit.decor(pen, true)
				local glow = Kit.part(mf, { Name = "CheckpointGlow", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.2, CFrame = CFrame.new(mp + Vector3.new(0, 9.4, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
				Kit.decor(glow)
				trigger(cps, "CP_" .. cp.name, p, Vector3.new(20, 14, 20), { Checkpoint = cp.name, Label = R.def.label .. " checkpoint", Route = name, Order = order, Camp = false })
				counts.markers += 1
			end
		end
	end

	-- wayfinding by route style
	local wf = Kit.folder(f, "Wayfinding")
	local hw = R.def.hw or 4
	local n = #R.pts
	if st.rail == "fence" or st.rail == "rope" then
		-- rails on the drop side wherever the ground 4 studs past the trail edge falls away by > 5 studs
		local run = {}
		local function flush()
			if #run >= 3 then
				if st.rail == "fence" then
					Kit.fence(wf, run, 3.4)
					counts.fenceRuns += 1
				else
					-- fixed rope: posts every ~18 studs, one rope span per post pair, lantern-gold rope (wayfinding
					-- token). Was a post every ~9 and a rope part per sample (~1,150 parts on Ledge alone; run 2
					-- instance budget)
					local m = Kit.model(wf, "FixedRope")
					local last
					for k = 1, #run do
						if k % 6 == 1 or k == #run then
							Kit.part(m, { Name = "RopePost", Size = Vector3.new(0.5, 4, 0.5), CFrame = CFrame.new(run[k] + Vector3.new(0, 1.8, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
							if last then
								local a, b = last + Vector3.new(0, 3.4, 0), run[k] + Vector3.new(0, 3.4, 0)
								local rope = Kit.part(m, { Name = "Rope", Size = Vector3.new(0.3, 0.3, (b - a).Magnitude + 0.2), CFrame = CFrame.lookAt((a + b) / 2, b), Material = Enum.Material.Fabric, Color = COL.lantern })
								Kit.decor(rope)
							end
							last = run[k]
						end
					end
					counts.ropeRuns += 1
				end
			end
			run = {}
		end
		local oPrev
		for i = 6, n - 6, 3 do
			local p = pt(R, i)
			local o = outward(R, i)
			-- around a hairpin tip "outward" flips sides; end the run there so no rail crosses the trail
			if oPrev and o:Dot(oPrev) < 0.7 then
				flush()
			end
			oPrev = o
			local edge = p + o * (hw + 1.5)
			local far = p + o * (hw + 5.5)
			local drop = p.Y - Gen.heightAt(far.X, far.Z)
			if drop > 5 and not onBridge[i] and not skipped(i) then
				run[#run + 1] = Vector3.new(edge.X, math.max(Gen.heightAt(edge.X, edge.Z), p.Y - 1), edge.Z)
				if #run >= 24 then
					local last = run[#run]
					flush()
					run[1] = last
				end
			else
				flush()
			end
		end
		flush()
	end
	if st.rail == "fence" or st.rail == "lantern" then
		local every = (st.rail == "fence") and 50 or 84 -- samples (x3 studs)
		local k = 0
		for i = 20, n - 20, every do
			if not onBridge[i] then
				k += 1
				local p = pt(R, i)
				local lp = p - outward(R, i) * (hw + 2.5)
				lp = Vector3.new(lp.X, Gen.heightAt(lp.X, lp.Z), lp.Z)
				Kit.lantern(wf, lp, 7, k % 3 == 0) -- every third lantern carries a light (mobile budget)
				counts.lanterns += 1
			end
		end
	end
	if st.rail == "cairn" or st.rail == "rope" then
		for i = 40, n - 40, 66 do
			if skipped(i) then
				continue
			end
			local p = pt(R, i)
			local cp2 = p - outward(R, i) * (hw + 2)
			cp2 = Vector3.new(cp2.X, Gen.heightAt(cp2.X, cp2.Z), cp2.Z)
			Kit.place(wf, "Cairn", cp2, i, 0.9)
			counts.cairns += 1
		end
	end
	return counts
end

---------------------------------------------------------------- hazards
-- Hazard definitions per route (PROPOSED): kind, where (fraction of the sample range whose trail height lies in
-- [y0, y1]), and cycle. Tells: easy route 3 s, hard routes 2 s (LOCKED decision 10). Strength = knockback speed.
local HAZ = {
	Shepherd = {
		{ kind = "TreeFall", y0 = 700, y1 = 1100, at = 0.30, period = 12, tell = 3, strength = 30 },
		{ kind = "TreeFall", y0 = 700, y1 = 1100, at = 0.70, period = 14, tell = 3, strength = 30, offset = 5 },
		{ kind = "Rockfall", y0 = 1200, y1 = 1550, at = 0.55, period = 11, tell = 3, strength = 34 },
		{ kind = "Gust", y0 = 1850, y1 = 2230, at = 0.50, period = 10, tell = 3, strength = 7, length = 150 }, -- mild: slower than walking
	},
	Waterfall = {
		{ kind = "TreeFall", y0 = 700, y1 = 1100, at = 0.5, period = 10, tell = 2.5, strength = 40 },
		{ kind = "Rockfall", y0 = 1200, y1 = 1550, at = 0.5, period = 9, tell = 2.5, strength = 44 },
		{ kind = "Gust", y0 = 1850, y1 = 2230, at = 0.5, period = 9, tell = 2.5, strength = 22, length = 120 },
	},
	Ledge = {
		{ kind = "Rockfall", y0 = 1150, y1 = 1600, at = 0.35, period = 8, tell = 2, strength = 55 },
		{ kind = "Rockfall", y0 = 1150, y1 = 1600, at = 0.75, period = 9, tell = 2, strength = 55, offset = 3 },
		{ kind = "Gust", y0 = 1800, y1 = 2240, at = 0.5, period = 8, tell = 2, strength = 30, length = 140 },
		{ kind = "Avalanche", y0 = 2260, y1 = 2560, at = 0.5, period = 13, tell = 2, strength = 60 },
	},
	Spire = {
		{ kind = "TreeFall", y0 = 600, y1 = 1100, at = 0.5, period = 9, tell = 2, strength = 55 },
		{ kind = "Rockfall", y0 = 1150, y1 = 1650, at = 0.5, period = 7, tell = 2, strength = 60 },
		{ kind = "Gust", y0 = 1800, y1 = 2250, at = 0.4, period = 7, tell = 2, strength = 34, length = 120 },
		{ kind = "Avalanche", y0 = 2260, y1 = 2560, at = 0.5, period = 11, tell = 2, strength = 70 },
		{ kind = "Gust", y0 = 2260, y1 = 2560, at = 0.7, period = 7, tell = 2, strength = 34, length = 80, offset = 3 },
	},
}
RK.HAZ = HAZ

local function pickSample(R, h)
	local idx = {}
	for i = 30, #R.pts - 30 do
		local y = R.pts[i][3]
		if y >= h.y0 and y <= h.y1 then
			idx[#idx + 1] = i
		end
	end
	if #idx == 0 then
		return nil
	end
	return idx[math.clamp(math.floor(#idx * h.at + 0.5), 1, #idx)]
end

function RK.hazards(Kit, Gen, name)
	local COL = Kit.COL
	local P = _G.CC_PATHS
	local R = P.routes[name]
	local root = Kit.folder(Kit.folder(workspace, "World"), "Hazards")
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Kit.folder(root, name)
	local out = {}
	local function skippedH(i)
		local s0 = R.S[math.clamp(i, 1, #R.S)]
		for _, r in ipairs(R.skips or {}) do
			if s0 >= r[1] - 30 and s0 <= r[2] + 30 then
				return true
			end
		end
		return false
	end
	for n, h in ipairs(HAZ[name] or {}) do
		local i = pickSample(R, h)
		local inHang = false
		for _, ln in ipairs(i and R.def.lines or {}) do
			local si = R.S[math.clamp(i, 1, #R.S)]
			if ln.kind == "hang" and ln.s0 and si >= ln.s0 - 30 and si <= ln.s1 + 30 then
				inHang = true
			end
		end
		if i and not skippedH(i) and not inHang then
			local p = pt(R, i)
			local d = dirAt(R, i)
			local o = outward(R, i)
			local hw = R.def.hw or 4
			local m = Kit.model(f, string.format("%s_%d", h.kind, n))
			m:SetAttribute("Kind", h.kind)
			m:SetAttribute("Route", name)
			m:SetAttribute("Period", h.period)
			m:SetAttribute("Tell", h.tell)
			m:SetAttribute("Offset", h.offset or 0)
			m:SetAttribute("Strength", h.strength)
			m:SetAttribute("Center", p)
			m:SetAttribute("TrailDir", d)
			m:SetAttribute("Outward", o)
			if h.kind == "TreeFall" then
				-- a tall tree on the uphill side falls across the trail (hinge at its base, falls outward)
				local base = p - o * (hw + 5)
				base = Vector3.new(base.X, Gen.heightAt(base.X, base.Z) - 0.5, base.Z)
				local tree = Kit.place(m, "TreeTall", base, math.atan2(o.X, o.Z), 1.7, COL.forestTeal)
				tree.Name = "FallTree"
				for _, q in ipairs(tree:GetDescendants()) do
					if q:IsA("BasePart") then
						q.CanCollide = false
					end
				end
				m:SetAttribute("Hinge", base)
				m:SetAttribute("FallLen", hw * 2 + 16)
				-- dodge marker: a cut stump on the far side shows where the trunk lands
			elseif h.kind == "Rockfall" or h.kind == "Avalanche" then
				-- lane across the trail from uphill (top) to downhill; a rut marks it, an alcove is beside it
				local top = p - o * (hw + 26)
				top = Vector3.new(top.X, Gen.heightAt(top.X, top.Z) + 3, top.Z)
				local bot = p + o * (hw + 20)
				bot = Vector3.new(bot.X, Gen.heightAt(bot.X, bot.Z) + 2, bot.Z)
				m:SetAttribute("Top", top)
				m:SetAttribute("Bottom", bot)
				m:SetAttribute("Radius", (h.kind == "Avalanche") and 9 or 4)
				local rut = Kit.part(m, { Name = "LaneRut", Size = Vector3.new((h.kind == "Avalanche") and 18 or 9, 0.3, (top - bot).Magnitude), CFrame = CFrame.lookAt((top + bot) / 2 - Vector3.new(0, 2.6, 0), bot - Vector3.new(0, 2.6, 0)), Material = (h.kind == "Avalanche") and Enum.Material.Snow or Enum.Material.Slate, Color = (h.kind == "Avalanche") and COL.moon or COL.slate, Transparency = 0.2 })
				Kit.decor(rut)
				-- shelter alcove: low stone wall on the uphill side, 14 studs before the lane
				local ap = p - d * 16 - o * (hw + 1)
				ap = Vector3.new(ap.X, Gen.heightAt(ap.X, ap.Z), ap.Z)
				Kit.part(m, { Name = "Alcove", Size = Vector3.new(8, 6, 2), CFrame = CFrame.lookAt(ap + Vector3.new(0, 3, 0), ap + Vector3.new(0, 3, 0) + d), Material = Enum.Material.Cobblestone, Color = COL.masonry })
			elseif h.kind == "Gust" then
				m:SetAttribute("Length", h.length or 120)
				m:SetAttribute("HalfWidth", hw + 10)
				-- windbreak shelters every ~40 studs on the uphill side (stand behind one during the gust)
				local L = h.length or 120
				for s2 = -L / 2, L / 2, 40 do
					local wp = p + d * s2 - o * (hw - 0.5)
					wp = Vector3.new(wp.X, Gen.heightAt(wp.X, wp.Z), wp.Z)
					Kit.part(m, { Name = "Windbreak", Size = Vector3.new(7, 5, 1.6), CFrame = CFrame.lookAt(wp + Vector3.new(0, 2.5, 0) + o * 2.4, wp + Vector3.new(0, 2.5, 0) + o * 2.4 + d), Material = Enum.Material.Cobblestone, Color = COL.masonry })
				end
				-- flags show the wind: they whip during the tell
				for s2 = -L / 2, L / 2, 60 do
					local fp = p + d * s2 - o * (hw + 3)
					fp = Vector3.new(fp.X, Gen.heightAt(fp.X, fp.Z), fp.Z)
					Kit.part(m, { Name = "FlagPole", Size = Vector3.new(0.4, 8, 0.4), CFrame = CFrame.new(fp + Vector3.new(0, 4, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
					local flag = Kit.part(m, { Name = "WindFlag", Size = Vector3.new(0.15, 1.6, 3.2), CFrame = CFrame.new(fp + Vector3.new(0, 7.2, 0) + o * 1.6) * CFrame.lookAt(Vector3.zero, d), Material = Enum.Material.Fabric, Color = COL.lantern })
					Kit.decor(flag)
				end
			end
			out[#out + 1] = string.format("%s@s%.0f(y%.0f)", h.kind, R.S[i], p.Y)
		end
	end
	return out
end

return RK
