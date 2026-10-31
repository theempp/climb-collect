-- Mountain path math shared by track and herd (ReplicatedStorage.SS_Path).
-- d = studs climbed along the lane centreline. The slope is each zone's angle, eased over SlopeBlend studs
-- around every border (no kinks) and down to flat over SummitFlat past the top. The profile is integrated
-- once into a 1-stud table. In plan the path follows gentle bends (SS_Config.Bends): everything is defined
-- on the straight path (climbing along -Z) and warped onto the bent one (P.warp / P.unwarp), exactly as the
-- Blender build warps the mountain meshes.
-- art/tools/sspath.py is the Python twin used by the Blender build; keep the two in step.
local C = require(script.Parent:WaitForChild("SS_Config"))
local Z = C.Zones

local P = {}
local starts = {}
local acc = 0
for i, z in Z do
	starts[i] = acc
	acc += z.Length
end
P.Total = acc
P.Starts = starts
local MIN, MAX = -300, acc + 300

local function smooth(a)
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

-- Slope (radians) at d.
function P.slope(d)
	local deg = Z[1].SlopeDeg
	for i = 2, #Z do
		deg += (Z[i].SlopeDeg - Z[i - 1].SlopeDeg) * smooth((d - starts[i] + C.SlopeBlend / 2) / C.SlopeBlend)
	end
	deg -= Z[#Z].SlopeDeg * smooth((d - acc) / C.SummitFlat)
	return math.rad(deg)
end

-- Height (y) and forward (z) of the centreline at every whole stud from MIN to MAX (midpoint rule).
local ys, zs = { [0] = 0 }, { [0] = 0 }
for i = 0, MAX - 1 do
	local a = P.slope(i + 0.5)
	ys[i + 1], zs[i + 1] = ys[i] + math.sin(a), zs[i] - math.cos(a)
end
for i = 0, MIN + 1, -1 do
	local a = P.slope(i - 0.5)
	ys[i - 1], zs[i - 1] = ys[i] - math.sin(a), zs[i] + math.cos(a)
end

function P.zoneOf(d)
	local k = 1
	for i = 2, #Z do
		if d >= starts[i] then
			k = i
		end
	end
	return k
end

function P.zoneEnd(k)
	return starts[k] + Z[k].Length
end

-- Lane width ramps from this zone's to the next zone's over the last NarrowRamp studs.
function P.laneWidth(d)
	local k = P.zoneOf(d)
	local w = Z[k].LaneWidth
	local nxt = Z[k + 1]
	if nxt then
		local a = (d - (P.zoneEnd(k) - C.NarrowRamp)) / C.NarrowRamp
		if a > 0 then
			w += (nxt.LaneWidth - w) * math.min(a, 1)
		end
	end
	return w
end

function P.laneX(lane, d)
	return (lane - (C.LaneCount + 1) / 2) * P.laneWidth(d)
end

local function straightSurf(d, x, h)
	d = math.clamp(d, MIN, MAX - 1)
	local i = math.floor(d)
	local f = d - i
	local y = ys[i] + (ys[i + 1] - ys[i]) * f
	local z = zs[i] + (zs[i + 1] - zs[i]) * f
	return CFrame.new(0, y, z) * CFrame.Angles(P.slope(d), 0, 0) * CFrame.new(x or 0, h or 0, 0)
end

-- Plan-view bends --------------------------------------------------------------------------------
-- Heading (radians) at d: 0 = straight up the mountain (-Z), positive turns toward +X.
local function heading(d)
	local a = 0
	for _, b in C.Bends or {} do
		a += b.Deg * smooth((d - b.At + b.Len / 2) / b.Len)
	end
	return math.rad(a)
end
P.heading = heading

-- Bent centreline in plan at every whole stud: same horizontal step as the straight table, turned by heading.
local px, pz = { [0] = 0 }, { [0] = 0 }
for i = 0, MAX - 1 do
	local h, a = zs[i] - zs[i + 1], heading(i + 0.5)
	px[i + 1], pz[i + 1] = px[i] + h * math.sin(a), pz[i] - h * math.cos(a)
end
for i = 0, MIN + 1, -1 do
	local h, a = zs[i - 1] - zs[i], heading(i - 0.5)
	px[i - 1], pz[i - 1] = px[i] - h * math.sin(a), pz[i] + h * math.cos(a)
end

local function plan(d)
	local i = math.floor(d)
	local f = d - i
	return px[i] + (px[i + 1] - px[i]) * f, pz[i] + (pz[i + 1] - pz[i]) * f, heading(d)
end

local function dAtZ(zw) -- straight table: d whose centreline sits at world z
	local lo, hi = MIN, MAX - 1
	while hi - lo > 1 do
		local m = (lo + hi) // 2
		if zs[m] > zw then
			lo = m
		else
			hi = m
		end
	end
	return lo + (zs[lo] - zw) / (zs[lo] - zs[hi])
end

-- Straight-built point -> bent world point (and the heading there). Past either end of the table the path
-- carries on along its end heading. Mirrors sspath.warp.
function P.warp(p)
	local e, fwd
	if p.Z > zs[MIN] then
		e, fwd = MIN, zs[MIN] - p.Z
	elseif p.Z < zs[MAX - 1] then
		e, fwd = MAX - 1, zs[MAX - 1] - p.Z
	else
		e, fwd = dAtZ(p.Z), 0
	end
	local cx, cz, a = plan(e)
	local s, c = math.sin(a), math.cos(a)
	return Vector3.new(cx + fwd * s + p.X * c, p.Y, cz - fwd * c + p.X * s), a
end

-- Bent world point -> straight-built point (inverse of warp).
function P.unwarp(p)
	local lo, hi = MIN, MAX - 1
	while hi - lo > 1 do -- the bent plan z still falls as d rises (headings stay well under 90 degrees)
		local m = (lo + hi) // 2
		if pz[m] > p.Z then
			lo = m
		else
			hi = m
		end
	end
	local e = math.clamp(lo + (pz[lo] - p.Z) / (pz[lo] - pz[hi]), MIN, MAX - 1)
	for _ = 1, 4 do -- slide e until p sits square across the path from the centreline
		local cx, cz, a = plan(e)
		local along = (p.X - cx) * math.sin(a) - (p.Z - cz) * math.cos(a)
		local i = math.clamp(math.floor(e), MIN, MAX - 2)
		e = math.clamp(e + along / (zs[i] - zs[i + 1]), MIN, MAX - 1)
	end
	local cx, cz, a = plan(e)
	local fwd = (p.X - cx) * math.sin(a) - (p.Z - cz) * math.cos(a) -- non-zero only past the ends
	local lat = (p.X - cx) * math.cos(a) + (p.Z - cz) * math.sin(a)
	local i = math.floor(e)
	local zc = zs[i] + (zs[math.min(i + 1, MAX)] - zs[i]) * (e - i)
	return Vector3.new(lat, p.Y, zc - fwd)
end

-- Surface CFrame at distance d, sideways offset x, height h above the slope (on the bent path).
function P.surf(d, x, h)
	local s = straightSurf(d, x, h)
	local w, a = P.warp(s.Position)
	return CFrame.new(w) * CFrame.Angles(0, -a, 0) * s.Rotation
end

-- Inverse of surf for a world point: returns d, x.
function P.project(pos)
	pos = P.unwarp(pos)
	local lo, hi = MIN, MAX - 1
	while hi - lo > 1 do -- zs falls as d rises
		local m = (lo + hi) // 2
		if zs[m] > pos.Z then
			lo = m
		else
			hi = m
		end
	end
	local d, lp = lo, nil
	for _ = 1, 3 do
		lp = straightSurf(d, 0, 0):PointToObjectSpace(pos)
		d = math.clamp(d - lp.Z, MIN, MAX - 1)
	end
	return d, lp.X
end

-- Herd speed (P1): each section runs at its own Speed; entering a section the speed eases up from the one
-- below over SpeedRamp studs. Species tiers multiply on top.
function P.speedAt(d)
	d = math.max(d, 0)
	local k = P.zoneOf(d)
	local v = Z[k].Speed
	if k > 1 then
		v = Z[k - 1].Speed + (v - Z[k - 1].Speed) * smooth((d - starts[k]) / C.SpeedRamp)
	end
	return v
end

return P
