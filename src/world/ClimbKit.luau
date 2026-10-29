-- ClimbKit (v4 P3, run 2, 2026-10-21): shared builders for authored climbing lines (master.md §0.8 LOCKED form;
-- placements and numbers PROPOSED). Terrain-first: tier ledges are terrain (route material), marked faces are
-- terrain Asphalt (CoreConfig.CLIMB.terrainMaterial, used nowhere else, so only authored faces are climbable).
-- Parts are only the cues (fixed ropes, pitons, handlines, flags), hazards, rest zones and checkpoint triggers, so a
-- whole pitch stack costs ~100-200 instances (the +15 % per-location cap; a part-built stack was ~400+).
--   local ck = ClimbKit.new(Kit, "Ledge")           -- one per route build
--   ck:stack({ name, s0, s1, ... })                 -- one switchback band rebuilt as a pitch stack
--   ck:export()                                     -- bot track -> ReplicatedStorage.CC_Track.<route> (JSON)
-- Stack = faces up the band joined by tier ledges that run across the old switchback window, alternating
-- direction (the climb zig-zags up the band). Features per tier: rest (RestZone + checkpoint), broken ledge
-- (sideways traverse on a marked strip), rockfall chute (timed crossing on a marked strip), lunge band (a blank
-- rock band in a face that needs a Jump-lunge).
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local T = workspace.Terrain
local MARK = Enum.Material.Asphalt

local CK = {}
CK.__index = CK
CK.MARK = MARK

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { T }

-- ground height: the in-memory heightfield (Gen.heightAt) when present, so geometry does not depend on raycasts
-- right after voxel writes (they lag, CLAUDE.md gotcha); raycast fallback
local function ground(x, z)
	local G = _G.CC_Gen
	if G and _G.CC_HF then
		return G.heightAt(x, z)
	end
	local r = workspace:Raycast(Vector3.new(x, 3600, z), Vector3.new(0, -4000, 0), terrainOnly)
	return r and r.Position.Y or -1e4
end
CK.ground = ground
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function radial(th)
	return Vector3.new(math.sin(th), 0, math.cos(th))
end
local function polar(th, r, y)
	return Vector3.new(r * math.sin(th), y, r * math.cos(th))
end
local function thetaOf(v)
	local t = math.atan2(v.X, v.Z)
	if t < -1 then
		t += 2 * math.pi
	end
	return t
end
CK.radial, CK.polar, CK.thetaOf = radial, polar, thetaOf

local function v3(t)
	return { math.floor(t.X * 10 + 0.5) / 10, math.floor(t.Y * 10 + 0.5) / 10, math.floor(t.Z * 10 + 0.5) / 10 }
end

-- route samples from the in-memory paths (built by Gen.computeField / B.terrain(1))
local function routeAt(R, s)
	for i = 2, #R.pts do
		if R.S[i] >= s then
			local p = R.pts[i]
			return Vector3.new(p[1], p[3], p[2]), i
		end
	end
	local p = R.pts[#R.pts]
	return Vector3.new(p[1], p[3], p[2]), #R.pts
end
CK.routeAt = routeAt

function CK.new(Kit, route)
	local self = setmetatable({}, CK)
	self.Kit, self.COL, self.route = Kit, Kit.COL, route
	self.n = 0
	self.segments = {}
	self.report = {}
	local world = Kit.folder(workspace, "World")
	self.lines = Kit.folder(Kit.folder(world, "Lines"), route)
	self.hz = Kit.folder(world, "Hazards")
	self.cps = Kit.folder(world, "Checkpoints")
	return self
end

function CK:P(parent, props)
	self.n += 1
	return self.Kit.part(parent, props)
end
function CK:D(parent, props)
	self.n += 1
	return self.Kit.decor(self.Kit.part(parent, props))
end

-- clear what an earlier build of this line left (parts, hazards, checkpoints); terrain is rebuilt by the caller
function CK:clearLine(name)
	local f = self.lines:FindFirstChild(name)
	if f then
		f:Destroy()
	end
	local h = self.hz:FindFirstChild(self.route .. "_" .. name)
	if h then
		h:Destroy()
	end
	for _, c in ipairs(self.cps:GetChildren()) do
		if c:GetAttribute("Line") == self.route .. "_" .. name then
			c:Destroy()
		end
	end
end

---------------------------------------------------------------- cues
-- glowing route flag (guidance layer a): pole, cloth, lamp bead + light; the cairn is terrain (no instances)
function CK:flag(parent, pos, order, outward)
	local COL = self.COL
	local gy = ground(pos.X, pos.Z)
	local g = (math.abs(gy - pos.Y) < 6) and Vector3.new(pos.X, gy, pos.Z) or pos
	T:FillBall(g + Vector3.new(0.4, 0.2, 0.3), 1.3, Enum.Material.Slate)
	local o = flat(outward or Vector3.xAxis)
	o = (o.Magnitude > 0.1) and o.Unit or Vector3.xAxis
	self:D(parent, { Name = "Pole", Size = Vector3.new(0.35, 7, 0.35), CFrame = CFrame.new(g + Vector3.new(0, 3.5, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
	local flag = self:D(parent, { Name = "GuideFlag", Size = Vector3.new(0.15, 1.5, 2.6), CFrame = CFrame.lookAt(g + Vector3.new(0, 6.2, 0) + o * 1.3, g + Vector3.new(0, 6.2, 0) + o * 1.3 + o:Cross(Vector3.yAxis)), Material = Enum.Material.SmoothPlastic, Color = COL.lantern })
	local lamp = self:D(parent, { Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.55, CFrame = CFrame.new(g + Vector3.new(0, 7.2, 0)), Material = Enum.Material.Neon, Color = COL.lantern })
	flag:SetAttribute("GuideOrder", order)
	flag:SetAttribute("GuideRoute", self.route)
	local l = Instance.new("PointLight")
	l.Color = COL.lantern
	l.Range = 12
	l.Brightness = 0.9
	l.Shadows = false
	l.Parent = lamp
	self.n += 1
	return flag
end

-- decor rope between two points (fixed ropes, handlines)
function CK:rope(parent, a, b, d)
	return self:D(parent, { Name = "Rope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((b - a).Magnitude, d or 0.32, d or 0.32), CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = self.COL.lantern })
end
function CK:piton(parent, p, out)
	return self:D(parent, { Name = "Piton", Size = Vector3.new(0.4, 0.4, 1.2), CFrame = CFrame.lookAt(p, p + out), Material = Enum.Material.Metal, Color = self.COL.slate })
end

function CK:checkpoint(lineName, key, pos, label, order)
	local t = Instance.new("Part")
	t.Name = "CP_" .. self.route .. "_" .. lineName .. "_" .. key
	t.Anchored, t.CanCollide, t.CanQuery = true, false, false
	t.Transparency = 1
	t.Size = Vector3.new(16, 14, 16)
	t.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
	for k, v in pairs({ Checkpoint = self.route .. "_" .. lineName .. "_" .. key, Label = label, Route = self.route, Order = order, Camp = false, Line = self.route .. "_" .. lineName }) do
		t:SetAttribute(k, v)
	end
	t.Parent = self.cps
	self.n += 1
	return t
end

function CK:restZone(parent, cf, size)
	local z = self:P(parent, { Name = "RestZone", Size = size, CFrame = cf, Transparency = 1 })
	z.CanCollide, z.CanQuery, z.CanTouch, z.CastShadow = false, false, false, false
	z:SetAttribute("RestZone", true)
	return z
end

---------------------------------------------------------------- terrain geometry
-- outer radius where the terrain along the ray at theta crosses height y (the band falls outward)
function CK.contour(th, y, rLo, rHi)
	local o = radial(th)
	local function g(r)
		return ground(o.X * r, o.Z * r)
	end
	if g(rLo) < y or g(rHi) > y then
		return nil
	end
	for _ = 1, 24 do
		local m = (rLo + rHi) / 2
		if g(m) > y then
			rLo = m
		else
			rHi = m
		end
	end
	-- the rendered rock on these bands stands 0.5-2 studs outward of the heightfield crossing (measured on
	-- untouched bands: +0.5 .. +2.1, mean +1.4), so field contours get a bias
	return (rLo + rHi) / 2 + ((_G.CC_Gen and _G.CC_HF) and CK.CONTOUR_BIAS or 0)
end
CK.CONTOUR_BIAS = 1.5

-- the steep band along a ray: longest run of slope > minDeg from outside in; returns foot y, top y, r foot, r top
function CK.bandOnRay(th, rIn, rOut, minDeg)
	local o = radial(th)
	local k = math.tan(math.rad(minDeg or 50))
	local best, cur = nil, nil
	local prevR, prevY = rOut, ground(o.X * rOut, o.Z * rOut)
	for r = rOut - 4, rIn, -4 do
		local y = ground(o.X * r, o.Z * r)
		if (y - prevY) / 4 > k then
			if not cur then
				cur = { footY = prevY, footR = prevR }
			end
			cur.topY, cur.topR = y, r
		elseif cur then
			if not best or (cur.topY - cur.footY) > (best.topY - best.footY) then
				best = cur
			end
			cur = nil
		end
		prevR, prevY = r, y
	end
	if cur and (not best or (cur.topY - cur.footY) > (best.topY - best.footY)) then
		best = cur
	end
	return best
end

local function fill(cf, size, mat)
	T:FillBlock(cf, size, mat)
end

-- terrain ramp from p to q (walking surface on the straight line, max ~40 deg): fills under the line, carves head room
-- above it. Joins an unstamped stack to the stamped trail (their heights can differ by tens of studs).
function CK.ramp(p, q, width, mat, walk)
	local d = flat(q - p)
	local L = d.Magnitude
	if L < 2 then
		return 0
	end
	local t = d.Unit
	local n = math.max(1, math.ceil(L / 3))
	-- pitched boxes (top face along the slope; flat boxes left 50-deg risers at every joint); carve the whole line
	-- first, then fill it (the fill wins the voxels both touch)
	local seg = (q - p) / n
	local along = seg.Unit
	local segLen = seg.Magnitude
	for pass = 1, 2 do
		for i = 0, n - 1 do
			local a = p:Lerp(q, i / n)
			local mid = a + seg / 2
			local cf = CFrame.lookAt(mid, mid + along)
			if pass == 1 then
				fill(cf * CFrame.new(0, 5.2, 0), Vector3.new(width + 2, 10, segLen + 0.5), Enum.Material.Air)
			else
				fill(cf * CFrame.new(0, -3, 0), Vector3.new(width, 6, segLen + 1), mat)
			end
		end
	end
	-- walk: an invisible collision walkway on the rendered surface (terrain ramps keep voxel steps of up to ~50
	-- deg at box joints; the terrain is the look, the walkway the footing), one part per ~20 studs
	if walk then
		local m = math.max(1, math.ceil((q - p).Magnitude / 20))
		-- callers pass the surface line minus 2.6 (the fill's render offset); +0.4 more clears the voxel lumps that
		-- poke up to ~0.4 above a 40-deg ramp's surface (a bot stalled on one, Waterfall lip exit, run 2)
		local up = Vector3.new(0, 3.3, 0)
		for i = 0, m - 1 do
			local a, b = p:Lerp(q, i / m) + up, p:Lerp(q, (i + 1) / m) + up
			local wpart = Instance.new("Part")
			wpart.Name = "Walkway"
			wpart.Anchored, wpart.CanCollide, wpart.CanQuery, wpart.CanTouch, wpart.CastShadow = true, true, true, false, false
			wpart.Transparency = 1
			wpart.Size = Vector3.new(width - 1, 1, (b - a).Magnitude + 0.6)
			wpart.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.5, 0)
			wpart.Parent = walk
		end
		return n, m
	end
	return n
end

-- the box a stack rewrites from the generated field before building (its route stretch +- 30, 70 studs around)
function CK.rewrite(R, s0, s1)
	local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
	for i, p in ipairs(R.pts) do
		if R.S[i] >= s0 - 30 and R.S[i] <= s1 + 30 then
			x0, z0, x1, z1 = math.min(x0, p[1]), math.min(z0, p[2]), math.max(x1, p[1]), math.max(z1, p[2])
		end
	end
	if x0 < math.huge then
		_G.CC_Gen.writeBox(x0 - 70, z0 - 70, x1 + 70, z1 + 70)
	end
end

---------------------------------------------------------------- the pitch stack
-- spec: name, R (route paths entry), s0, s1, rise (tier height, default 40), ledgeMat, ledgeW, faceW,
--       foot/top (optional: else measured), ta/tb (optional window), features = { rest = {tier}, traverse =
--       {tier}, chute = {tier}, lunge = {face}, avalanche = {tier} }, handline = true, guideBase, order0
function CK:stack(spec)
	local COL = self.COL
	local name = spec.name
	self:clearLine(name)
	local root = self.Kit.folder(self.lines, name)
	local R = spec.R
	local A = routeAt(R, spec.s0)
	local B = routeAt(R, spec.s1)
	-- window: theta and radius span of the old switchbacks
	-- theta unwrapped around A's angle (windows near +-pi or past 2pi stay one continuous range)
	local ref = math.atan2(A.X, A.Z)
	local function unwrap(v)
		local t = math.atan2(v.X, v.Z)
		while t - ref > math.pi do
			t -= 2 * math.pi
		end
		while t - ref < -math.pi do
			t += 2 * math.pi
		end
		return t
	end
	local ta, tb, rLo, rHi = math.huge, -math.huge, math.huge, 0
	for i, p in ipairs(R.pts) do
		if R.S[i] >= spec.s0 and R.S[i] <= spec.s1 then
			local v = Vector3.new(p[1], 0, p[2])
			local th = unwrap(v)
			ta, tb = math.min(ta, th), math.max(tb, th)
			rLo, rHi = math.min(rLo, v.Magnitude), math.max(rHi, v.Magnitude)
		end
	end
	ta, tb = spec.ta or (ta + (spec.margin or 0.014)), spec.tb or (tb - (spec.margin or 0.014))
	local rIn, rOut = spec.rIn or (rLo - 40), spec.rOut or (rHi + 60)
	-- start from the generated terrain (an earlier build of this stack wrote ledges/faces into it). A full build
	-- rewrites every stack's box first and then builds with rewrite = false (BuildAll.allLines): boxes of
	-- neighbouring stacks overlap, and a later rewrite erased an earlier stack's ledges (run 2)
	if _G.CC_Gen and spec.rewrite ~= false then
		CK.rewrite(R, spec.s0, spec.s1)
	end
	rLo, rHi = rLo - 160, rHi + 160
	-- band heights: median foot / top of the steepest run over 7 rays across the window (overridable)
	-- "trail" pins an end to the trail itself (A's / B's height): short scrambles on the easy road climb exactly from
	-- the trail below to the trail above
	local foot = (spec.foot == "trail") and A.Y or spec.foot
	local top = (spec.top == "trail") and B.Y or spec.top
	if not (foot and top) then
		local fs, ts = {}, {}
		for k = 0, 6 do
			local b = CK.bandOnRay(ta + (tb - ta) * k / 6, rIn, rOut, spec.minDeg or 50)
			if b then
				fs[#fs + 1], ts[#ts + 1] = b.footY, b.topY
			end
		end
		table.sort(fs)
		table.sort(ts)
		if #fs > 0 then
			foot = foot or (fs[math.floor(#fs / 2) + 1] + 3)
			top = top or (ts[math.floor(#ts / 2) + 1] - 3)
		else
			foot, top = foot or 0, top or 0
		end
	end
	-- the stack starts at the trail's height (A) and ends near B's: the bands' gentler skirts (40-50 deg) are
	-- neither walkable nor worth a ramp, so the first face starts at A's level and the last tops out close to B
	local tA, tB = unwrap(A), unwrap(B)
	-- tiers cover only the steep run; A -> face 1 and the top -> B are walked on the natural ground (ramped only where
	-- it is steeper than ~42 deg, see the entry/exit ramps below). A and B are where the V3 trail lies on natural ground.
	-- If even a straight ramp from A to the band foot would be steeper than ~35 deg, the foot comes down (the first
	-- tiers then stand on the band's skirt) until the approach is walkable.
	local footAnchor = nil
	if spec.foot == nil then
		local thF = tA -- face 1 stands just ahead of A
		for _ = 1, 4 do
			local rF0 = CK.contour(thF, foot, rLo, rHi)
			if not rF0 then
				break
			end
			local dist = flat(polar(thF, rF0 + 6, 0) - A).Magnitude
			if (foot - A.Y) <= 0.7 * dist then
				break
			end
			foot = math.max(A.Y + 1, A.Y + 0.62 * dist)
		end
	end
	-- never start below A or end above B (a trail already partway up the band would ramp down to the first face)
	if spec.foot == nil and A.Y > foot then
		foot = A.Y
	end
	if spec.top == nil and B.Y < top then
		top = B.Y
	end
	-- a trail that passes just above the stack top: the last face tops out at the trail (no ramp up under it)
	if spec.top == nil and B.Y > top and B.Y - top < 25 then
		top = B.Y
	end
	local rep = { name = name, window = string.format("theta %.3f..%.3f", ta, tb), band = string.format("y %.0f..%.0f", foot, top) }
	self.report[name] = rep
	if not (top - foot >= 24) then
		rep.error = "band too low or not found"
		return rep
	end
	local rise = spec.rise or 40
	local n = math.max(2, math.floor((top - foot) / rise + 0.5))
	-- face 1 stands just ahead of A in the trail's own direction (a face at the window edge behind A put the entry
	-- ramp back over the trail it came on); faces 2.. alternate between the window edges, starting with the edge
	-- farther from face 1; the line count is nudged so the last face ends on B's side
	local rA = flat(A).Magnitude
	local Ahead = routeAt(R, spec.s0 + 24)
	local hd = (unwrap(Ahead) >= tA) and 1 or -1
	-- a narrow window at the start of the stretch (Shepherd one-arm scrambles): the climb happens there and the exit
	-- ramp walks the rest of the arm at the top's height
	if spec.windowLen then
		local t2 = tA + hd * spec.windowLen / rA
		ta, tb = math.min(tA, t2), math.max(tA, t2)
	end
	local th1 = math.clamp(tA + hd * ((spec.faceW or 16) / 2 + 4) / rA, ta, tb)
	local e1 = (math.abs(tb - th1) >= math.abs(ta - th1)) and tb or ta
	local e2 = (e1 == tb) and ta or tb
	local function sideOf(k)
		if k == 1 then
			return th1
		end
		return (k % 2 == 0) and e1 or e2
	end
	local wantLast = (math.abs(tB - ta) <= math.abs(tB - tb)) and ta or tb
	if sideOf(n) ~= wantLast and spec.matchB ~= false then
		n += 1
	end
	local h = {}
	for k = 0, n do
		h[k] = foot + (top - foot) * k / n
	end
	rep.tiers = string.format("%d faces of %.1f", n, (top - foot) / n)
	local faceW = spec.faceW or 16
	local ledgeW = spec.ledgeW or 10
	local ledgeMat = spec.ledgeMat or Enum.Material.Sandstone
	local feats = spec.features or {}
	local function has(list, k)
		for _, v in ipairs(list or {}) do
			if v == k then
				return true
			end
		end
		return false
	end
	local function faceSide(k)
		return sideOf(k)
	end

	-- 1) geometry first (contours on the untouched terrain; writes below would change the answers)
	local faces = {}
	for k = 1, n do
		local th = faceSide(k)
		-- edge faces sit a little inside the window so the ledge reaches under their full width
		if k > 1 then
			local inward = (th == ta) and 1 or -1
			local mid = (rLo + rHi) / 2
			th += inward * (faceW / 2 + 2) / mid
		end
		local rF = (k == 1 and footAnchor) or CK.contour(th, h[k - 1], rLo, rHi)
		local rT = CK.contour(th, h[k], rLo, rHi)
		if not (rF and rT) then
			rep.error = "no contour for face " .. k
			return rep
		end
		-- front (nominal): 1 behind the wall line (terrain renders ~2 proud), but on steep bands at least 6 outward
		-- of the upper ledge's contour, so the face's top platform reaches the upper ledge's walking line (wall + 4)
		faces[k] = { th = th, rF = rF, rT = rT, y0 = h[k - 1], y1 = h[k], front = math.max(rF - 1, rT + 6) }
	end
	local ledges = {}
	for k = 1, n - 1 do
		local th0, th1 = faces[k].th, faces[k + 1].th
		local mid = (faces[k].rT + faces[k + 1].rF) / 2
		local steps = math.max(2, math.floor(math.abs(th1 - th0) * mid / 4))
		local pts = {}
		for i = 0, steps do
			local th = th0 + (th1 - th0) * i / steps
			pts[#pts + 1] = { th = th, r = CK.contour(th, h[k], rLo, rHi) }
		end
		-- fill gaps (no crossing found) from neighbours, then smooth the radius
		for i, q in ipairs(pts) do
			if not q.r then
				local a, b = nil, nil
				for j = i - 1, 1, -1 do
					if pts[j].r then
						a = pts[j].r
						break
					end
				end
				for j = i + 1, #pts do
					if pts[j].r then
						b = pts[j].r
						break
					end
				end
				q.r = a and b and (a + b) / 2 or a or b
			end
		end
		-- ends pinned to the faces (start = top of face k, end = foot of face k+1), so no crevice opens between a
		-- ledge and the face it meets; the middle is smoothed
		pts[1].r, pts[#pts].r = faces[k].rT, faces[k + 1].rF
		for _ = 1, 3 do
			local sm = {}
			for i, q in ipairs(pts) do
				if i == 1 or i == #pts then
					sm[i] = q
				else
					local a, b = pts[i - 1], pts[i + 1]
					sm[i] = { th = q.th, r = (a.r + q.r * 2 + b.r) / 4 }
				end
			end
			pts = sm
		end
		-- run the floor on past the next face's centre (half a face width) so its foot isn't a rounded voxel end
		local last = pts[#pts]
		local d = (th1 > th0) and 1 or -1
		pts[#pts + 1] = { th = last.th + d * (faceW / 2 + 1) / last.r, r = last.r, extra = true }
		ledges[k] = { pts = pts, y = h[k], dir = d }
	end

	-- 2) terrain: faces (marked), ledges (route material), features
	local function o(th)
		return radial(th)
	end
	-- entry (A -> the first face's foot landing) and exit (top landing -> B) ramps
	local entryLine, exitLine
	do
		local f1, fn = faces[1], faces[n]
		local foot = polar(f1.th, f1.front + 7, f1.y0)
		local topL = polar(fn.th, fn.rT - 6, fn.y1)
		-- ramp only where the natural line is too steep to walk (> ~42 deg between 4-stud samples)
		-- also when the ground strays > 6 studs from the straight line (a gully under it, a spur across it)
		local function needsRamp(p, q)
			local d = flat(q - p).Magnitude
			local n = math.max(1, math.floor(d / 4))
			local prev = ground(p.X, p.Z)
			for i = 1, n do
				local x = p:Lerp(q, i / n)
				local g = ground(x.X, x.Z)
				if math.abs(g - prev) / (d / n) > 0.9 or math.abs(g - x.Y) > 6 then
					return true
				end
				prev = g
			end
			return false
		end
		-- ramp ends sit on the real ground (A / B can be a few studs off the path height), and the fill's rendered
		-- surface stands ~2.8 above its nominal top (measured), so the line is laid that much lower
		-- the ramps start / end exactly on the stamped trail (A / B are path points; the trail surface is the path
		-- height), and always carry a walkway: the junction with the trail is where a trench or causeway can leave
		-- a step the terrain alone doesn't smooth
		local R3 = Vector3.new(0, 2.6, 0)
		local wf = self.Kit.folder(root, "Walkways")
		do
			local _, m = CK.ramp(A - R3, foot - R3, 7, ledgeMat, wf)
			rep.entryRamp, self.n = m, self.n + (m or 0)
		end
		do
			local _, m = CK.ramp(topL - R3, B - R3, 7, ledgeMat, wf)
			rep.exitRamp, self.n = m, self.n + (m or 0)
		end
		rep.entrySteep, rep.exitSteep = needsRamp(A, foot), needsRamp(topL, B)
		entryLine, exitLine = { A, foot }, { topL, B }
	end
	local gaps = {} -- [k] = list of { a, b, kind } index ranges on ledge k with no floor
	for k, L in pairs(ledges) do
		local pts = L.pts
		local gl = {}
		local function addGap(kind, frac, len)
			local i0 = math.floor(#pts * frac)
			local stepLen = math.max(1, math.floor(len / 4 + 0.5))
			gl[#gl + 1] = { a = i0, b = i0 + stepLen, kind = kind }
		end
		if has(feats.traverse, k) then
			addGap("traverse", 0.3, spec.traverseLen or 24)
		end
		if has(feats.chute, k) then
			addGap("chute", 0.68, 10)
		end
		gaps[k] = gl
		local function inGap(i)
			for _, g in ipairs(gl) do
				if i >= g.a and i < g.b then
					return g
				end
			end
			return nil
		end
		-- the marked strip also runs over one floor segment at each end: grab it from the ledge, step off at the far end
		local function onStrip(i)
			for _, g in ipairs(gl) do
				if i >= g.a - 1 and i <= g.b then
					return g
				end
			end
			return nil
		end
		local restI = has(feats.rest, k) and math.floor(#pts * 0.5) or nil
		local faceSkip = math.ceil((faceW / 2 + 3) / 4)
		L.restI = restI
		-- pass 1: head room over the walking strip (none near the faces at either end: it would shave the proud
		-- face front and leave a notch to stand in); pass 2: floors (they win the voxels the carve shared with them,
		-- so the floor is never lowered); pass 3: marked strips (traverse / chute crossings) on top of both
		for pass = 1, 3 do
			for i = 1, #pts - 1 do
				local p, q = pts[i], pts[i + 1]
				local a, b = polar(p.th, p.r, L.y), polar(q.th, q.r, L.y)
				local t = flat(b - a)
				if t.Magnitude > 0.1 then
					local mo = o((p.th + q.th) / 2)
					local g = inGap(i)
					local wide = restI and math.abs(i - restI) <= 2
					-- the last ~12 studs before the next face are wider: on steep bands that face's front stands
					-- out over this ledge (see faces[k].front) and the climber waits in front of it
					local w = (wide and 12) or ((i >= #pts - faceSkip - 1) and 13) or ledgeW
					if pass == 1 and not g then
						local nearFace = (i <= faceSkip) or (i >= #pts - faceSkip - 1)
						if not nearFace then
							local ca = (a + b) / 2 + mo * (w / 2 + 1) + Vector3.new(0, 4.6, 0)
							fill(CFrame.lookAt(ca, ca + t.Unit), Vector3.new(w, 9, t.Magnitude + 0.4), Enum.Material.Air)
						end
					elseif pass == 2 and not g and i > 2 then
						-- (segments 1-2, the first 8 studs, lie on face k's top platform: faces are 16 wide, so no
						-- ledge floor overlaps a face and renders proud over its top edge)
						-- at the start of a ledge (the top of face k) the floor must not reach past face k's front, or
						-- the top of the face turns into unmarked floor rock with an overhanging lip
						-- floor outer edge (contour + w - 1) stays 1.5 behind the face's nominal front (rF - 1) wherever the
						-- ledge overlaps the face's own width (first ~8 studs); the very first segment has no floor at all:
						-- the face's top platform is the floor there

						-- the block reaches 3 studs into the wall (no gap at the rock) and is w + 3.5 deep and 6 thick:
						-- voxel smoothing rounds the outer ~4 studs, the walking line (wall + 3) stays on the flat part
						local c = (a + b) / 2 + mo * ((w + 0.5) / 2 - 3) - Vector3.new(0, 3, 0)
						fill(CFrame.lookAt(c, c + t.Unit), Vector3.new(w + 3.5, 6, t.Magnitude + 0.8), ledgeMat)
					elseif pass == 3 and onStrip(i) then
						-- the crossing itself is a marked part (see step 3): terrain strips rendered either proud (a
						-- shelf on top to stand on) or behind the natural rock (face rays hit plain rock and stalled)
						L.strip = L.strip or {}
						L.strip[#L.strip + 1] = { a = a, b = b, o = mo }
					end
				end
			end
		end
	end

	-- faces last: they win every voxel they share with ledges, ramps and strips
	for k, f in ipairs(faces) do
		-- nominal front 1 stud behind the wall line: terrain renders ~2 studs proud, so the face ends up flush with
		-- the rock (a proud face jutted into the ledge's walking line and got grabbed by its side corner)
		local D = math.max(5, f.front - f.rT + 6)
		local c = polar(f.th, f.front - D / 2, (f.y0 - 6 + f.y1) / 2)
		-- faceStyle "ladder" (Waterfall Stair): plain rock wall with a steel ladder; "alt": ladders on even faces
		f.ladder = (spec.faceStyle == "ladder") or (spec.faceStyle == "alt" and k % 2 == 0)
		-- (written before the face itself: the pad's rendered edge covered the face's top 5 studs with unmarked rock)
		-- landing pad on the top of the last face (the shelf above may not be flat right at the edge), from the face
		-- front back to the exit ramp's start (rT - 12), with the rock above it cleared first: a natural rib between
		-- the mantle spot and the ramp blocked the walk-off (Waterfall storm, run 2)
		if k == n then
			local r0, r1 = f.front, f.rT - 12
			local depth = r0 - r1
			local yb = math.ceil((f.y1 + 0.2) / 4) * 4
			-- (the carve stops at the ramp start, rT - 6: the exit ramp's terrain begins there)
			local ca = polar(f.th, (r0 + f.rT - 6) / 2, yb + 7)
			fill(CFrame.lookAt(ca, ca + o(f.th)), Vector3.new(faceW + 4, 14, math.max(2, r0 - (f.rT - 6))), Enum.Material.Air)
			local cp = polar(f.th, (r0 + r1) / 2, f.y1 - 2)
			fill(CFrame.lookAt(cp, cp + o(f.th)), Vector3.new(faceW + 4, 4, depth), ledgeMat)
			-- open the junction with the exit ramp (its carve is only 9 wide, so its side wall cut the pad off from
			-- the ramp when the ramp leaves at an angle), then lay the ramp's terrain again (its walkways stay)
			if exitLine then
				local tl = polar(f.th, f.rT - 6, yb + 7)
				fill(CFrame.lookAt(tl, tl + o(f.th)), Vector3.new(faceW + 10, 14, 18), Enum.Material.Air)
				local R3 = Vector3.new(0, 2.6, 0)
				CK.ramp(exitLine[1] - R3, exitLine[2] - R3, 7, ledgeMat, nil)
			end
		end
		fill(CFrame.lookAt(c, c + o(f.th)), Vector3.new(faceW, f.y1 - f.y0 + 6, D), f.ladder and Enum.Material.Rock or MARK)
		-- foot landing in front of the first face (the band foot is ~50 deg; nowhere to stand without it)
		if k == 1 then
			-- (14 deep, faceW + 10 wide: a 10-deep landing let walkers coming in at an angle step off its far edge)
			local cf0 = polar(f.th, f.front + 7.5, f.y0 - 2)
			fill(CFrame.lookAt(cf0, cf0 + o(f.th)), Vector3.new(faceW + 10, 4, 14), ledgeMat)
			local yb0 = math.ceil((f.y0 + 0.2) / 4) * 4
			local ca0 = polar(f.th, f.front + 8, (yb0 + f.y0 + 9) / 2)
			fill(CFrame.lookAt(ca0, ca0 + o(f.th)), Vector3.new(faceW + 5, f.y0 + 9 - yb0, 8), Enum.Material.Air)
		end
		if has(feats.lunge, k) and f.y1 - f.y0 > 16 then
			-- a blank band across the face: climbing stops below it, a Jump-lunge (8 studs) crosses it. A part, not
			-- terrain: voxel bands rounded into lips the climber stepped off onto. 0.7 proud, 4 tall, unmarked.
			local yb = f.y0 + (f.y1 - f.y0) * 0.55
			f.lunge = yb
		end
	end
	-- 3) parts: ropes + pitons on faces, handlines on ledges, flags, rest zones, checkpoints, hazards
	local guide = spec.guideBase or 100
	local nodes = {}
	local function node(t)
		nodes[#nodes + 1] = t
	end
	local fm = self.Kit.folder(root, "Faces")
	for k, f in ipairs(faces) do
		local oo = o(f.th)
		if f.ladder then
			-- steel ladder stood off the rendered rock (front + 3.6: rock voxels bulge up to ~2.9 proud and stopped a
			-- climber at front + 2.5): two rails, rungs every 4, one invisible marked grip plane behind them (6 wide:
			-- a 3-wide grip lost off-centre grabs in P1)
			local H = f.y1 - f.y0 + 1
			local base = polar(f.th, f.front + 3.6, f.y0)
			local right = oo:Cross(Vector3.yAxis).Unit
			for _, sg in ipairs({ -1, 1 }) do
				self:D(fm, { Name = "Rail", Size = Vector3.new(0.3, H, 0.3), CFrame = CFrame.new(base + right * 1.2 * sg + Vector3.new(0, H / 2, 0)), Material = Enum.Material.Metal, Color = COL.slate })
			end
			for y = 1, H - 0.5, 8 do
				self:D(fm, { Name = "Rung", Size = Vector3.new(2.4, 0.22, 0.22), CFrame = CFrame.lookAt(base + Vector3.new(0, y, 0), base + Vector3.new(0, y, 0) + oo), Material = Enum.Material.Metal, Color = COL.slate })
			end
			local gc = base - oo * 0.3 + Vector3.new(0, H / 2, 0)
			local grip = self:P(fm, { Name = "LadderGrip", Size = Vector3.new(6, H, 0.4), CFrame = CFrame.lookAt(gc, gc + oo), Transparency = 1, Material = Enum.Material.SmoothPlastic })
			grip:SetAttribute("Climbable", true)
		end
		local a = polar(f.th, f.front + 2.5, f.y0 + 0.5)
		local b = polar(f.th, f.front + 2.5, f.y1 + 0.6)
		if not f.ladder then
			self:rope(fm, a, b, 0.34)
		end
		for y = f.y0 + 4, f.y1 - 2, f.ladder and 1e9 or 24 do
			if not (f.lunge and math.abs(y - f.lunge) < 4) then
				self:piton(fm, polar(f.th, f.front + 2.3, y), oo)
			end
		end
		if f.lunge then
			-- on the rendered rock: terrain faces render ~2 studs proud of their nominal front (measured), and a part at
			-- the nominal front was buried in the rock
			local cb = polar(f.th, f.front + 2.1, f.lunge)
			-- a wedge (sloped top, ~73 deg), so a sliding climber can't land on it as on a shelf
			self.n += 1
			-- no collision: the climber's body (held 1.55 off the rock) bumped the band's front and every lunge stalled
			-- (rays still hit it, so it still reads as "no grip here")
			local band = self.Kit.wedge(fm, { Name = "BlankBand", Size = Vector3.new(faceW + 1, 4, 1.2), CFrame = CFrame.lookAt(cb, cb + oo), Material = Enum.Material.Slate, Color = COL.rock:Lerp(COL.slate, 0.35) })
			if band then
				band.CanCollide = false
			end
		end
		guide += 1
		local tSide = (f.th < (ta + tb) / 2) and 1 or -1 -- flag stands on the ledge side away from the window edge
		self:flag(fm, polar(f.th + tSide * (faceW / 2 + 2.5) / f.rF, math.max(f.rF, f.front) + 8, f.y0), guide, oo) -- outer edge: its cairn sat on the walking line
	end
	local lm = self.Kit.folder(root, "Ledges")
	local cpN = 0
	for k, L in pairs(ledges) do
		local pts = L.pts
		-- handline on the wall side, ~36 studs per span (piton + rope = 2 instances a span), broken over gaps
		if spec.handline ~= false then
			local last
			for i = 1, #pts, 9 do
				local p = pts[i]
				local inG = false
				for _, g in ipairs(gaps[k]) do
					if i >= g.a - 1 and i <= g.b + 1 then
						inG = true
					end
				end
				local pp = polar(p.th, p.r - 0.2, L.y + 3.4)
				if inG then
					last = nil
				else
					self:piton(lm, pp, o(p.th))
					if last then
						self:rope(lm, last, pp, 0.26)
					end
					last = pp
				end
			end
		end
		if L.restI then
			local p = pts[L.restI]
			local c = polar(p.th, p.r + 3.5, L.y + 3)
			self:restZone(lm, CFrame.lookAt(c, c + o(p.th)), Vector3.new(16, 8, 10))
			cpN += 1
			self:checkpoint(name, "R" .. cpN, polar(p.th, p.r + 3.5, L.y), spec.label or (name .. " rest"), (spec.order0 or 0) + cpN)
			guide += 0 -- rest flags share the face numbering
		end
		-- marked crossing strips: ONE straight part per crossing (a chain of parts along a wiggly contour had kinks
		-- the climber stalled at). Placed on the chord from the last floor segment before the gap to the first after
		-- it, at the outermost wall point of that stretch, 0.5 proud of the rendered rock, 3 deep (reaches back
		-- into the rock wherever the wall recedes), floor - 2 .. floor + 7.5 (above a jump; rock above stops a mantle)
		for _, g in ipairs(gaps[k]) do
			-- starts two segments before the gap: the approach point (middle of the last segment before it) must face
			-- the strip's front, not its end (an end-face grab reads sideways moves as pulling away)
			local i0, i1 = math.max(1, g.a - 2), math.min(#pts, g.b + 1)
			local pa, pb = pts[i0], pts[i1]
			local A2, B2 = polar(pa.th, pa.r, L.y), polar(pb.th, pb.r, L.y)
			local tt = flat(B2 - A2)
			if tt.Magnitude > 2 then
				local nrm = Vector3.new(-tt.Z, 0, tt.X).Unit -- horizontal normal to the chord
				local mid = (A2 + B2) / 2
				if nrm:Dot(flat(mid)) < 0 then
					nrm = -nrm -- outward (away from the mountain axis)
				end
				-- front plane 2 studs inward of the approach point (the bot's / player's stand on the walking line,
				-- wall + 4), so the strip is always in reach; 6 deep so it meets the rock where the wall recedes, and a
				-- clean lane carved in front of it where the wall bulges (contours wiggle by several studs on skirts)
				local pa1, pg1 = pts[math.max(1, g.a - 1)], pts[math.max(1, g.a)]
				local appr = polar((pa1.th + pg1.th) / 2, (pa1.r + pg1.r) / 2 + 4, L.y)
				local front = (appr - mid):Dot(nrm) - 2
				local ybL = math.ceil((L.y + 0.2) / 4) * 4 -- from the next voxel boundary: never lowers a floor
				local lane = mid + nrm * (front + 3.2) + Vector3.new(0, (ybL + L.y + 9) / 2 - L.y, 0)
				fill(CFrame.lookAt(lane, lane + nrm), Vector3.new(tt.Magnitude + 2, L.y + 9 - ybL, 6), Enum.Material.Air)
				local c = mid + nrm * (front - 3) + Vector3.new(0, 2.75, 0)
				local strip = self:P(lm, { Name = "MarkedStrip", Size = Vector3.new(tt.Magnitude + 2, 9.5, 6), CFrame = CFrame.lookAt(c, c + nrm), Material = MARK, Color = COL.rock })
				strip:SetAttribute("Climbable", true)
				g.strip = strip
				g.normal = nrm
			end
		end
		for _, g in ipairs(gaps[k]) do
			local pa, pb = pts[math.max(1, g.a)], pts[math.min(#pts, g.b)]
			if g.kind == "chute" then
				local pc = pts[math.floor((g.a + g.b) / 2)]
				local c = polar(pc.th, pc.r, L.y)
				local oo, tt = o(pc.th), flat(polar(pb.th, pb.r, 0) - polar(pa.th, pa.r, 0)).Unit
				local m = self.Kit.model(self.Kit.folder(self.hz, self.route .. "_" .. name), "Rockfall_T" .. k)
				local topP = c + oo * 1.6 + Vector3.new(0, 24, 0)
				-- the rock stops ~18 below this tier: ledges alternate, so a longer line crossed the tier below (a rock
				-- from cliffs chute 6 knocked climbers off traverse 5 in full runs)
				local botP = c + oo * 7 - Vector3.new(0, 18, 0)
				for key, v in pairs({ Kind = "Rockfall", Route = self.route, Period = spec.chutePeriod or 8, Tell = 3, Offset = k * 1.7, Strength = 30, Center = c, TrailDir = tt, Outward = oo, Top = topP, Bottom = botP, Radius = 2.6, Straight = true }) do
					m:SetAttribute(key, v)
				end
				self:D(m, { Name = "ChuteGroove", Size = Vector3.new(1, 20, 7), CFrame = CFrame.lookAt(c - oo * 1.6 + Vector3.new(0, 16, 0), c + Vector3.new(0, 16, 0)), Material = Enum.Material.Slate, Color = COL.slate })
				g.model = m
			end
		end
	end

	-- 4) bot track (same order a climber takes): walk to face 1, climb, walk each ledge (crossing gaps on the
	-- marked strip), climb the next face, ..., last face, walk to B
	local function lineNodes(ln)
		local p, q = ln[1], ln[2]
		local d = flat(q - p).Magnitude
		local m = math.max(1, math.floor(d / 24))
		for i = 0, m do
			node({ k = "walk", p = v3(p:Lerp(q, i / m) + Vector3.new(0, 3, 0)) })
		end
	end
	lineNodes(entryLine)
	for k = 1, n do
		local f = faces[k]
		local oo = o(f.th)
		-- coming along a ledge, first step out past the face's corner (a straight line from the last ledge node to the
		-- foot cut the corner of a proud face and stalled, Spire storm F4, run 2)
		local Lp = ledges[k - 1]
		if Lp then
			local side = -(Lp.dir or 1)
			node({ k = "walk", p = v3(polar(f.th + side * (faceW / 2 + 3) / math.max(f.front, 1), f.front + 4.2, f.y0 + 3)) })
		end
		node({ k = "walk", p = v3(polar(f.th, f.front + (f.ladder and 5.2 or 4.2), f.y0 + 3)) })
		node({ k = "climb", into = v3(-oo), label = name .. "_F" .. k, lunge = f.lunge and true or nil })
		local L = ledges[k]
		if L then
			local pts = L.pts
			-- step from the face top inward onto the ledge line
			local p1 = pts[1]
			node({ k = "walk", p = v3(polar(p1.th, p1.r + 4, L.y + 3)) })
			local i = 1
			while i <= #pts do
				local gap
				for _, g in ipairs(gaps[k]) do
					if i >= g.a - 1 and i < g.b then
						gap = g
					end
				end
				if gap then
					local pa = pts[math.max(1, gap.a - 1)]
					local pb = pts[math.min(#pts, gap.b + 1)]
					local pg = pts[math.max(1, gap.a)]
					node({ k = "walk", p = v3(polar((pa.th + pg.th) / 2, (pa.r + pg.r) / 2 + 4, L.y + 3)) })
					local tt = flat(polar(pb.th, pb.r, 0) - polar(pa.th, pa.r, 0)).Unit
					if gap.model then
						node({ k = "wait", hz = gap.model:GetFullName() })
					end
					node({ k = "climb", into = v3(-(gap.normal or o(pa.th))), dir = v3(tt), label = name .. "_" .. gap.kind .. k })
					i = gap.b + 2
				else
					-- no walk nodes within the next face's width (its block can stand out over the ledge end); the
					-- face-foot node in front of it comes next
					local fN = faces[k + 1]
					local nearNext = fN and math.abs(pts[i].th - fN.th) * pts[i].r < faceW / 2 + 2
					if (i % 2 == 1 or i == #pts) and not nearNext then
						local p = pts[i]
						node({ k = "walk", p = v3(polar(p.th, p.r + 4, L.y + 3)) })
					end
					i += 1
				end
			end
		end
	end
	lineNodes(exitLine)
	-- exit flag where the stamped trail resumes
	guide += 1
	self:flag(root, B + radial(tB) * 6, guide, radial(tB)) -- beside the trail, not on it
	self.segments[#self.segments + 1] = { id = name, s0 = spec.s0, s1 = spec.s1, nodes = nodes }
	local ledgeLen = 0
	for _, L in pairs(ledges) do
		ledgeLen += math.abs(L.pts[#L.pts].th - L.pts[1].th) * L.pts[1].r
	end
	rep.ledges = string.format("%d tier ledges, %.0f studs", n - 1, ledgeLen)
	rep.parts = #root:GetDescendants()
	return rep
end

---------------------------------------------------------------- the hang line
-- (v4 P3 run 2; user: "hang lines on the route's own lane") the long shelf traverse of a hard route becomes a ledge
-- line on the band face just BELOW the lane: from A, climb DOWN a marked entry face to a contour ledge `drop` studs
-- below the trail, traverse it (broken-ledge crossings on marked strips, a rockfall chute, a rest spot), climb UP a
-- marked exit face to B. The lane itself stays (WorldConfig line kind "hang", stamp = true): a notch 16 studs wide
-- (wider than a jump) and ~18 deep is cut across it just past the entry face and just before the exit face, so the
-- ledge line is the way through (the bypass test checks the notch shoulders). rep.steep = share of the ledge under a
-- > 50-deg face.
-- spec: name, R, s0, s1, drop (28), faceW (14), ledgeW (9), ledgeMat, outward (contours searched outward of the
--       lane only: crest lanes fall on both sides), features = { traverse = { frac, ... }, chute = { frac, ... },
--       rest = { frac, ... } }, notch (default true), label, guideBase, order0, rewrite
function CK:hang(spec)
	local COL = self.COL
	local name = spec.name
	self:clearLine(name)
	local root = self.Kit.folder(self.lines, name)
	local R = spec.R
	local A = routeAt(R, spec.s0)
	local B = routeAt(R, spec.s1)
	if _G.CC_Gen and spec.rewrite ~= false then
		CK.rewrite(R, spec.s0, spec.s1)
	end
	local ref = math.atan2(A.X, A.Z)
	local function unwrap(th)
		while th - ref > math.pi do
			th -= 2 * math.pi
		end
		while th - ref < -math.pi do
			th += 2 * math.pi
		end
		return th
	end
	local tA, tB = unwrap(math.atan2(A.X, A.Z)), unwrap(math.atan2(B.X, B.Z))
	local dir = (tB > tA) and 1 or -1
	local drop = spec.drop or 28
	local yL = math.min(A.Y, B.Y) - drop
	local faceW = spec.faceW or 14
	local ledgeW = spec.ledgeW or 9
	local ledgeMat = spec.ledgeMat or Enum.Material.Sandstone
	local feats = spec.features or {}
	local rep = { name = name, kind = "hang", ledgeY = string.format("%.0f (trail %.0f / %.0f)", yL, A.Y, B.Y) }
	self.report[name] = rep
	local rA, rB = flat(A).Magnitude, flat(B).Magnitude
	local rLo, rHi = math.min(rA, rB) - 80, math.max(rA, rB) + 320
	if spec.outward then
		-- crest lanes: search only the outer flank, and not so far out that the next rise breaks the bracket
		rLo, rHi = math.min(rA, rB) + 1, math.max(rA, rB) + 140
	end
	local function o(th)
		return radial(th)
	end
	-- 1) geometry on the untouched terrain
	local thE = tA + dir * (faceW / 2 + 8) / rA
	local thX = tB - dir * (faceW / 2 + 8) / rB
	local function faceAt(th, yTop)
		local rF = CK.contour(th, yL, rLo, rHi)
		local rT = CK.contour(th, yTop, rLo, rHi)
		if not (rF and rT) then
			return nil
		end
		return { th = th, rF = rF, rT = rT, y0 = yL, y1 = yTop, front = math.max(rF - 1, rT + 6) }
	end
	local fE, fX = faceAt(thE, A.Y), faceAt(thX, B.Y)
	if not (fE and fX) then
		rep.error = "no contour at the line ends"
		return rep
	end
	local pts = {}
	local midR = (fE.rF + fX.rF) / 2
	local steps = math.max(4, math.floor(math.abs(thX - thE) * midR / 4))
	local steep = 0
	for i = 0, steps do
		local th = thE + (thX - thE) * i / steps
		local r = CK.contour(th, yL, rLo, rHi)
		-- steep face above the ledge? (the contour 20 studs higher lies within ~17 studs inward = steeper than 50 deg)
		local r20 = CK.contour(th, yL + 20, rLo, rHi)
		if r and r20 and (r - r20) < 17 then
			steep += 1
		end
		pts[#pts + 1] = { th = th, r = r }
	end
	for i, q in ipairs(pts) do
		if not q.r then
			local a, b
			for j = i - 1, 1, -1 do
				if pts[j].r then
					a = pts[j].r
					break
				end
			end
			for j = i + 1, #pts do
				if pts[j].r then
					b = pts[j].r
					break
				end
			end
			q.r = a and b and (a + b) / 2 or a or b
		end
	end
	if not pts[1].r then
		rep.error = "no ledge contour"
		return rep
	end
	pts[1].r, pts[#pts].r = fE.rF, fX.rF
	for _ = 1, 3 do
		local sm = {}
		for i, q in ipairs(pts) do
			if i == 1 or i == #pts then
				sm[i] = q
			else
				sm[i] = { th = q.th, r = (pts[i - 1].r + q.r * 2 + pts[i + 1].r) / 4 }
			end
		end
		pts = sm
	end
	rep.steep = string.format("%d %% of the ledge under a > 50-deg face", math.floor(100 * steep / #pts + 0.5))
	rep.ledge = string.format("%.0f studs at y %.0f", math.abs(thX - thE) * midR, yL)
	-- gaps (features by fraction of the ledge)
	local gaps = {}
	local function addGap(kind, frac, len)
		local i0 = math.max(3, math.floor(#pts * frac))
		gaps[#gaps + 1] = { a = i0, b = math.min(#pts - 3, i0 + math.max(1, math.floor(len / 4 + 0.5))), kind = kind }
	end
	for _, f in ipairs(feats.traverse or {}) do
		addGap("traverse", f, spec.traverseLen or 24)
	end
	for _, f in ipairs(feats.chute or {}) do
		addGap("chute", f, 10)
	end
	table.sort(gaps, function(a, b)
		return a.a < b.a
	end)
	local function inGap(i)
		for _, g in ipairs(gaps) do
			if i >= g.a and i < g.b then
				return g
			end
		end
	end
	local rests = {}
	for _, f in ipairs(feats.rest or {}) do
		rests[#rests + 1] = math.floor(#pts * f)
	end
	local function nearRest(i)
		for _, ri in ipairs(rests) do
			if math.abs(i - ri) <= 2 then
				return true
			end
		end
		return false
	end
	-- 2) terrain: entry / exit walkways from the trail to the face tops, the ledge (carve, floor), faces last
	local R3 = Vector3.new(0, 2.6, 0)
	local wf = self.Kit.folder(root, "Walkways")
	local topE = polar(fE.th, fE.rT - 2, A.Y)
	local topX = polar(fX.th, fX.rT - 2, B.Y)
	CK.ramp(A - R3, topE - R3, 7, ledgeMat, wf)
	CK.ramp(topX - R3, B - R3, 7, ledgeMat, wf)
	local faceSkip = math.ceil((faceW / 2 + 3) / 4)
	for pass = 1, 2 do
		for i = 1, #pts - 1 do
			local p, q = pts[i], pts[i + 1]
			local a, b = polar(p.th, p.r, yL), polar(q.th, q.r, yL)
			local t = flat(b - a)
			if t.Magnitude > 0.1 then
				local mo = o((p.th + q.th) / 2)
				local g = inGap(i)
				local w = nearRest(i) and 12 or ledgeW
				local nearFace = (i <= faceSkip) or (i >= #pts - faceSkip)
				if pass == 1 and not g and not nearFace then
					local ca = (a + b) / 2 + mo * (w / 2 + 1) + Vector3.new(0, 4.6, 0)
					fill(CFrame.lookAt(ca, ca + t.Unit), Vector3.new(w, 9, t.Magnitude + 0.4), Enum.Material.Air)
				elseif pass == 2 and not g then
					local c = (a + b) / 2 + mo * ((w + 0.5) / 2 - 3) - Vector3.new(0, 3, 0)
					fill(CFrame.lookAt(c, c + t.Unit), Vector3.new(w + 3.5, 6, t.Magnitude + 0.8), ledgeMat)
				end
			end
		end
	end
	for _, f in ipairs({ fE, fX }) do
		local D = math.max(5, f.front - f.rT + 6)
		local c = polar(f.th, f.front - D / 2, (f.y0 - 6 + f.y1) / 2)
		fill(CFrame.lookAt(c, c + o(f.th)), Vector3.new(faceW, f.y1 - f.y0 + 6, D), MARK)
		-- top platform from the face front back to the walkway end (the lane ground may be uneven there)
		local cp = polar(f.th, (f.front + f.rT - 4) / 2, f.y1 - 2)
		fill(CFrame.lookAt(cp, cp + o(f.th)), Vector3.new(faceW + 2, 4, math.max(4, f.front - f.rT + 4)), ledgeMat)
	end
	-- notches across the lane (the lane stays stamped): just past the entry face and just before the exit face
	if spec.notch ~= false then
		for k, f in ipairs({ fE, fX }) do
			local side = (k == 1) and dir or -dir
			local rr = (k == 1) and rA or rB
			local thN = f.th + side * (faceW / 2 + 9) / rr
			local yTop = (k == 1) and A.Y or B.Y
			local cN = polar(thN, rr, yTop + 6 - 12)
			-- along the lane 16 wide, across it 46 (lane + shoulders, reaching out over the band edge), yTop - 18 .. +6
			fill(CFrame.lookAt(cN, cN + o(thN)), Vector3.new(16, 24, 46), Enum.Material.Air)
		end
	end
	-- 3) parts: ropes + pitons on both faces, handline, strips, rest + checkpoint, chute hazards, flags
	local fm = self.Kit.folder(root, "Faces")
	local guide = spec.guideBase or 100
	for k, f in ipairs({ fE, fX }) do
		local oo = o(f.th)
		self:rope(fm, polar(f.th, f.front + 2.5, f.y0 + 0.5), polar(f.th, f.front + 2.5, f.y1 + 0.6), 0.34)
		for y = f.y0 + 4, f.y1 - 2, 12 do
			self:piton(fm, polar(f.th, f.front + 2.3, y), oo)
		end
		guide += 1
		local side = (k == 1) and -dir or dir -- beside the face, toward the trail it joins
		self:flag(fm, polar(f.th + side * (faceW / 2 + 3) / f.rT, f.rT - 4, f.y1), guide, oo)
	end
	local lm = self.Kit.folder(root, "Ledges")
	do
		local last
		for i = 1, #pts, 9 do
			local p = pts[i]
			local inG = false
			for _, g in ipairs(gaps) do
				if i >= g.a - 1 and i <= g.b + 1 then
					inG = true
				end
			end
			local pp = polar(p.th, p.r - 0.2, yL + 3.4)
			if inG then
				last = nil
			else
				self:piton(lm, pp, o(p.th))
				if last then
					self:rope(lm, last, pp, 0.26)
				end
				last = pp
			end
		end
	end
	for n, ri in ipairs(rests) do
		local p = pts[ri]
		local c = polar(p.th, p.r + 3.5, yL + 3)
		self:restZone(lm, CFrame.lookAt(c, c + o(p.th)), Vector3.new(16, 8, 10))
		self:checkpoint(name, "R" .. n, polar(p.th, p.r + 3.5, yL), spec.label or (name .. " rest"), (spec.order0 or 0) + n)
		guide += 1
		self:flag(lm, polar(p.th, p.r + ledgeW - 1, yL), guide, o(p.th))
	end
	for _, g in ipairs(gaps) do
		local i0, i1 = math.max(1, g.a - 2), math.min(#pts, g.b + 1)
		local pa, pb = pts[i0], pts[i1]
		local A2, B2 = polar(pa.th, pa.r, yL), polar(pb.th, pb.r, yL)
		local tt = flat(B2 - A2)
		if tt.Magnitude > 2 then
			local nrm = Vector3.new(-tt.Z, 0, tt.X).Unit
			local mid = (A2 + B2) / 2
			if nrm:Dot(flat(mid)) < 0 then
				nrm = -nrm
			end
			local pa1, pg1 = pts[math.max(1, g.a - 1)], pts[math.max(1, g.a)]
			local appr = polar((pa1.th + pg1.th) / 2, (pa1.r + pg1.r) / 2 + 4, yL)
			local front = (appr - mid):Dot(nrm) - 2
			local ybL = math.ceil((yL + 0.2) / 4) * 4
			local lane = mid + nrm * (front + 3.2) + Vector3.new(0, (ybL + yL + 9) / 2 - yL, 0)
			fill(CFrame.lookAt(lane, lane + nrm), Vector3.new(tt.Magnitude + 2, yL + 9 - ybL, 6), Enum.Material.Air)
			local c = mid + nrm * (front - 3) + Vector3.new(0, 2.75, 0)
			local strip = self:P(lm, { Name = "MarkedStrip", Size = Vector3.new(tt.Magnitude + 2, 9.5, 6), CFrame = CFrame.lookAt(c, c + nrm), Material = MARK, Color = COL.rock })
			strip:SetAttribute("Climbable", true)
			g.normal = nrm
		end
		if g.kind == "chute" then
			local pc = pts[math.floor((g.a + g.b) / 2)]
			local c = polar(pc.th, pc.r, yL)
			local oo = o(pc.th)
			local tt2 = flat(polar(pb.th, pb.r, 0) - polar(pa.th, pa.r, 0)).Unit
			local m = self.Kit.model(self.Kit.folder(self.hz, self.route .. "_" .. name), "Rockfall_H" .. g.a)
			for key, v in pairs({ Kind = "Rockfall", Route = self.route, Period = spec.chutePeriod or 8, Tell = 3, Offset = g.a * 0.37, Strength = 30, Center = c, TrailDir = tt2, Outward = oo, Top = c + oo * 1.6 + Vector3.new(0, 24, 0), Bottom = c + oo * 7 - Vector3.new(0, 18, 0), Radius = 2.6, Straight = true }) do
				m:SetAttribute(key, v)
			end
			self:D(m, { Name = "ChuteGroove", Size = Vector3.new(1, 20, 7), CFrame = CFrame.lookAt(c - oo * 1.6 + Vector3.new(0, 16, 0), c + Vector3.new(0, 16, 0)), Material = Enum.Material.Slate, Color = COL.slate })
			g.model = m
		end
	end
	-- 4) bot track: walk A -> entry top, descend, ledge, climb the exit face, walk to B
	local nodes = {}
	local function node(t)
		nodes[#nodes + 1] = t
	end
	local function lineNodes(p, q)
		local m = math.max(1, math.floor(flat(q - p).Magnitude / 24))
		for i = 0, m do
			node({ k = "walk", p = v3(p:Lerp(q, i / m) + Vector3.new(0, 3, 0)) })
		end
	end
	lineNodes(A, topE)
	node({ k = "descend", at = v3(polar(fE.th, fE.front - 1.5, fE.y1 + 3)), out = v3(o(fE.th)), label = name .. "_down" })
	local i = 1
	while i <= #pts do
		local gap
		for _, g in ipairs(gaps) do
			if i >= g.a - 1 and i < g.b then
				gap = g
			end
		end
		if gap then
			local pa, pb, pg = pts[math.max(1, gap.a - 1)], pts[math.min(#pts, gap.b + 1)], pts[math.max(1, gap.a)]
			node({ k = "walk", p = v3(polar((pa.th + pg.th) / 2, (pa.r + pg.r) / 2 + 4, yL + 3)) })
			local tt = flat(polar(pb.th, pb.r, 0) - polar(pa.th, pa.r, 0)).Unit
			if gap.model then
				node({ k = "wait", hz = gap.model:GetFullName() })
			end
			node({ k = "climb", into = v3(-(gap.normal or o(pa.th))), dir = v3(tt), label = name .. "_" .. gap.kind .. gap.a })
			i = gap.b + 2
		else
			local nearExit = math.abs(pts[i].th - fX.th) * pts[i].r < faceW / 2 + 2
			if (i % 2 == 1 or i == #pts) and not nearExit and i > faceSkip then
				local p = pts[i]
				node({ k = "walk", p = v3(polar(p.th, p.r + 4, yL + 3)) })
			end
			i += 1
		end
	end
	node({ k = "walk", p = v3(polar(fX.th, fX.front + 4.2, yL + 3)) })
	node({ k = "climb", into = v3(-o(fX.th)), label = name .. "_up" })
	lineNodes(topX, B)
	guide += 1
	self:flag(root, B + radial(tB) * 6, guide, radial(tB))
	self.segments[#self.segments + 1] = { id = name, s0 = spec.s0, s1 = spec.s1, nodes = nodes }
	rep.parts = #root:GetDescendants()
	return rep
end

-- bot track: ordered segments { id, s0, s1, nodes } for the whole route (the bot walks the route polyline between
-- segments). Stored as JSON so tools/route_climb_bot.luau can read it in a playtest.
function CK:export(replace)
	local f = RS:FindFirstChild("CC_Track") or Instance.new("Folder")
	f.Name = "CC_Track"
	f.Parent = RS
	local sv = f:FindFirstChild(self.route) or Instance.new("StringValue")
	sv.Name = self.route
	local old = {}
	local ok, dec = pcall(function()
		return HS:JSONDecode(sv.Value)
	end)
	-- replace: a full build owns the whole track (stale segments of removed lines must go); a partial build merges
	if ok and type(dec) == "table" and not replace then
		for _, s in ipairs(dec) do
			old[s.id] = s
		end
	end
	for _, s in ipairs(self.segments) do
		old[s.id] = s
	end
	local list = {}
	for _, s in pairs(old) do
		list[#list + 1] = s
	end
	table.sort(list, function(a, b)
		return a.s0 < b.s0
	end)
	sv.Value = HS:JSONEncode(list)
	sv.Parent = f
	return #list
end

return CK
