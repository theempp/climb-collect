--!native
-- MountainGen: heightfield + voxel writer for the CLIMB & COLLECT mountain.
-- Usage (edit mode, via execute_luau):
--   local Gen = require(folderClone.MountainGen)
--   Gen.computeField()            -- builds _G.CC_HF (heights, water, materials) and _G.CC_PATHS
--   Gen.writeRows(bj0, bj1)       -- writes voxel rows of 32x32-cell blocks
--   Gen.applyColors()
local C = require(script.Parent.WorldConfig)
local Gen = {}

local noise = math.noise
local sqrt, atan2, sin, cos, abs = math.sqrt, math.atan2, math.sin, math.cos, math.abs
local floor, ceil, min, max, clamp = math.floor, math.ceil, math.min, math.max, math.clamp
local PI, TAU = math.pi, 2 * math.pi
local readf32, writef32, readu8, writeu8 = buffer.readf32, buffer.writef32, buffer.readu8, buffer.writeu8

local CELL, HALF, N, BLOCK = C.CELL, C.HALF, C.N, C.BLOCK
local NN = N * N

local MAT = {
	Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud,
	Enum.Material.Rock, Enum.Material.Sandstone, Enum.Material.Slate, Enum.Material.Basalt,
	Enum.Material.Snow, Enum.Material.Glacier, Enum.Material.Ice, Enum.Material.Cobblestone,
	Enum.Material.Sand, Enum.Material.Limestone,
}
local M_GRASS, M_LEAFY, M_GROUND, M_MUD, M_ROCK, M_SAND_STONE, M_SLATE, M_BASALT = 1, 2, 3, 4, 5, 6, 7, 8
local M_SNOW, M_GLACIER, M_ICE, M_COBBLE, M_SAND, M_LIME = 9, 10, 11, 12, 13, 14
Gen.MAT = MAT

local function smoothstep(e0, e1, x)
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
local function lerp(a, b, t)
	return a + (b - a) * t
end
local function angDiff(a, b)
	local d = (a - b) % TAU
	if d > PI then
		d -= TAU
	end
	return d
end
local function plin(tbl, x)
	if x <= tbl[1][1] then
		return tbl[1][2]
	end
	for k = 2, #tbl do
		local p = tbl[k]
		if x <= p[1] then
			local q = tbl[k - 1]
			return q[2] + (p[2] - q[2]) * (x - q[1]) / (p[1] - q[1])
		end
	end
	return tbl[#tbl][2]
end
Gen.smoothstep, Gen.lerp, Gen.angDiff = smoothstep, lerp, angDiff

local function cellC(i)
	return -HALF + (i + 0.5) * CELL
end
Gen.cellC = cellC

---------------------------------------------------------------- profile (monotone cubic LUT)
local LUT_MAX = 3500
local PROFILE_LUT
local function buildProfile()
	local P = C.PROFILE
	local n = #P
	local xs, ys, d, m = {}, {}, {}, {}
	for k = 1, n do
		xs[k], ys[k] = P[k][1], P[k][2]
	end
	for k = 1, n - 1 do
		d[k] = (ys[k + 1] - ys[k]) / (xs[k + 1] - xs[k])
	end
	m[1], m[n] = d[1], d[n - 1]
	for k = 2, n - 1 do
		m[k] = (d[k - 1] * d[k] <= 0) and 0 or (d[k - 1] + d[k]) / 2
	end
	for k = 1, n - 1 do
		if d[k] == 0 then
			m[k], m[k + 1] = 0, 0
		else
			local a, b = m[k] / d[k], m[k + 1] / d[k]
			local s = a * a + b * b
			if s > 9 then
				local t = 3 / sqrt(s)
				m[k], m[k + 1] = t * a * d[k], t * b * d[k]
			end
		end
	end
	PROFILE_LUT = table.create(LUT_MAX + 1, 0)
	local seg = 1
	for r = 0, LUT_MAX do
		while seg < n - 1 and r > xs[seg + 1] do
			seg += 1
		end
		local x0, x1 = xs[seg], xs[seg + 1]
		local hg = x1 - x0
		local t = clamp((r - x0) / hg, 0, 1)
		local t2, t3 = t * t, t * t * t
		PROFILE_LUT[r + 1] = (2 * t3 - 3 * t2 + 1) * ys[seg] + (t3 - 2 * t2 + t) * hg * m[seg]
			+ (-2 * t3 + 3 * t2) * ys[seg + 1] + (t3 - t2) * hg * m[seg + 1]
	end
end
buildProfile()

function Gen.profile(r)
	if r <= 0 then
		return PROFILE_LUT[1]
	end
	if r >= LUT_MAX then
		return PROFILE_LUT[LUT_MAX + 1]
	end
	local r0 = floor(r)
	local a = PROFILE_LUT[r0 + 1]
	return a + (PROFILE_LUT[r0 + 2] - a) * (r - r0)
end

---------------------------------------------------------------- shape
function Gen.rwarp(x, z, r)
	local a = 55 * clamp((r - 150) / 500, 0, 1) * (1 - smoothstep(2000, 2200, r))
	if a == 0 then
		return 0
	end
	-- low-order lobes break the concentric "layer cake" read
	local th = atan2(x, z)
	local lobes = r * (0.08 * sin(2 * th + 0.7) + 0.05 * sin(3 * th + 2.1)) * clamp((r - 250) / 400, 0, 1)
	return lobes + a * (noise(x / 1000 + 0.37, z / 1000 + 0.11, 9.3) * 2 + 0.35 * noise(x / 330 + 0.2, z / 330 + 0.6, 4.1) * 2)
end

-- polar (theta, effective radius) -> world x, z (inverts rwarp by fixed-point iteration)
function Gen.toWorld(th, re)
	local s, c = sin(th), cos(th)
	local r = re
	for _ = 1, 5 do
		r = re - Gen.rwarp(r * s, r * c, r)
	end
	return r * s, r * c
end

local RIB = {
	{0, 0}, {40, 0}, {120, 30}, {290, 35}, {305, 10}, {370, 12}, {400, 70}, {470, 60}, {485, 20},
	{535, 20}, {560, 90}, {690, 80}, {710, 15}, {795, 15}, {820, 110}, {940, 100}, {960, 14},
	{1180, 14}, {1220, 0},
}
local DETAIL = {
	{0, 6}, {300, 12}, {370, 18}, {700, 20}, {950, 14}, {1200, 10}, {1300, 6}, {1660, 2.5},
	{2060, 3}, {2300, 28}, {3400, 40},
}
local SP = C.SPIRE

-- sub-peaks break the radial symmetry (world positions resolved lazily: toWorld needs rwarp)
local PEAKS
local function peakBonus(x, z)
	if not PEAKS then
		PEAKS = {}
		for _, pk in ipairs(C.PEAKS) do
			local px, pz = Gen.toWorld(pk.theta, pk.re)
			PEAKS[#PEAKS + 1] = { px, pz, pk.height, pk.radius }
		end
	end
	local add = 0
	for _, pk in ipairs(PEAKS) do
		local dx, dz = x - pk[1], z - pk[2]
		local d2 = dx * dx + dz * dz
		if d2 < pk[4] * pk[4] then
			add += pk[3] * (1 - sqrt(d2) / pk[4]) ^ 1.6
		end
	end
	return add
end

local F = C.FALL
local function applyFall(h, re, th)
	if re < F.reMin or re > F.reMax then
		return h
	end
	local adth = abs(angDiff(th, F.theta))
	local outer = F.bowlHalf * 1.5
	if adth >= outer then
		return h
	end
	local u = adth / F.bowlHalf
	local rLip = F.lipOuter - F.lipCut * max(0, 1 - u * u)
	local w = 1 - smoothstep(F.bowlHalf, outer, adth)
	if re < rLip then
		return lerp(h, max(h, F.lipY), w)
	end
	local floorY = F.poolY + 1 + max(0, re - rLip - 40) * 0.12
	return lerp(h, min(h, floorY), w)
end
function Gen.fallLip(th)
	local u = abs(angDiff(th, F.theta)) / F.bowlHalf
	return F.lipOuter - F.lipCut * max(0, 1 - u * u)
end

-- natural height before stamps; returns h, re, r, th
function Gen.baseHeight(x, z)
	local r = sqrt(x * x + z * z)
	local th = atan2(x, z)
	local re = r + Gen.rwarp(x, z, r)
	local reh = re
	if re < SP.outer and r > 0.001 then
		-- superellipse metric: ridges on the rotated axes, recessed faces between (4 aretes)
		local ca, sa = cos(SP.angle), sin(SP.angle)
		local u, v = abs(x * ca + z * sa) / r, abs(-x * sa + z * ca) / r
		local f = (u ^ SP.p + v ^ SP.p) ^ (1 / SP.p) / SP.norm
		reh = lerp(re * f, re, smoothstep(SP.inner, SP.outer, re))
	end
	-- wavy band edges: buttresses and recesses so the cliff and storm bands aren't cylinders
	local bw = 40 * smoothstep(805, 840, re) * (1 - smoothstep(925, 955, re))
		+ 30 * smoothstep(545, 575, re) * (1 - smoothstep(665, 695, re))
	if bw > 0 then
		reh += bw * (0.6 * sin(5 * th + 1.3) + 0.4 * sin(9 * th + 0.4))
	end
	local h = Gen.profile(reh)
	local ct, st = cos(th), sin(th)

	local ribA = plin(RIB, re)
	if ribA > 0 then
		local n1 = noise(ct * 2.2 + 11.3, st * 2.2 + 3.7, re / 260 + 0.31)
		local n2 = noise(ct * 5.1 + 2.9, st * 5.1 + 7.1, re / 140 + 0.77)
		local rib = 1 - min(1, abs(n1) * 2.2)
		h += ribA * ((rib - 0.45) * 1.2 + n2 * 0.8)
	end

	h += peakBonus(x, z)

	local dA = plin(DETAIL, re)
	h += dA * (noise(x / 170 + 0.13, z / 170 + 0.71, 5.5) * 1.4 + noise(x / 70 + 0.41, z / 70 + 0.29, 2.7) * 0.6)

	-- rolling meadow hills (Green Valley)
	local mw = smoothstep(1300, 1380, re) * (1 - smoothstep(1600, 1720, re))
	if mw > 0 then
		h += mw * 22 * noise(x / 420 + 0.3, z / 420 + 0.9, 2.2) * 2
	end

	-- outer rim peaks frame the valley
	if r > 1980 then
		local wr = smoothstep(1980, 2420, r)
		local n = noise(x / 520 + 0.5, z / 520 + 0.25, 6.6)
		local ridge = 1 - min(1, abs(n) * 2)
		h += wr * (240 * ridge * ridge + 50 * noise(x / 210 + 0.1, z / 210 + 0.3, 1.9) * 2)
	end

	h = applyFall(h, re, th)
	return h, re, r, th
end

local R_VALLEY, R_FOREST, R_CLIFFS, R_STORM = C.REGION.valley, C.REGION.forest, C.REGION.cliffs, C.REGION.storm
function Gen.regionOf(re, r)
	if r > 2060 then
		return 6
	elseif re >= R_VALLEY then
		return 1
	elseif re >= R_FOREST then
		return 2
	elseif re >= R_CLIFFS then
		return 3
	elseif re >= R_STORM then
		return 4
	end
	return 5
end

---------------------------------------------------------------- paths
local function densifyPolar(pts, step, ctrlIdx)
	local out = {}
	for k = 1, #pts - 1 do
		if ctrlIdx then
			ctrlIdx[k] = #out + 1
		end
		local a, b = pts[k], pts[k + 1]
		local len = abs(b[1] - a[1]) * (a[2] + b[2]) / 2 + abs(b[2] - a[2])
		local n = max(1, ceil(len / step))
		for s = 0, n - 1 do
			local t = s / n
			local x, z = Gen.toWorld(lerp(a[1], b[1], t), lerp(a[2], b[2], t))
			out[#out + 1] = { x, z }
		end
	end
	local last = pts[#pts]
	local x, z = Gen.toWorld(last[1], last[2])
	out[#out + 1] = { x, z }
	if ctrlIdx then
		ctrlIdx[#pts] = #out
	end
	return out
end

local function smoothXZ(pts, k, iters, closed)
	for _ = 1, iters do
		local n = #pts
		local o = table.create(n)
		for i = 1, n do
			if not closed and (i == 1 or i == n) then
				o[i] = pts[i]
			else
				local sx, sz, c = 0, 0, 0
				for d = -k, k do
					local j = i + d
					if closed then
						j = ((j - 1) % n) + 1
					else
						j = clamp(j, 1, n)
					end
					sx += pts[j][1]
					sz += pts[j][2]
					c += 1
				end
				o[i] = { sx / c, sz / c }
			end
		end
		pts = o
	end
	return pts
end

local function resample(pts, step, closed)
	local n = #pts
	local out = { { pts[1][1], pts[1][2] } }
	local px, pz = pts[1][1], pts[1][2]
	local need = step
	local lastI = closed and n + 1 or n
	for i = 2, lastI do
		local q = pts[((i - 1) % n) + 1]
		local qx, qz = q[1], q[2]
		local dx, dz = qx - px, qz - pz
		local L = sqrt(dx * dx + dz * dz)
		while L >= need and L > 0 do
			local t = need / L
			px, pz = px + dx * t, pz + dz * t
			out[#out + 1] = { px, pz }
			dx, dz = qx - px, qz - pz
			L = sqrt(dx * dx + dz * dz)
			need = step
		end
		need -= L
		px, pz = qx, qz
	end
	if not closed then
		out[#out + 1] = { pts[n][1], pts[n][2] }
	end
	return out
end

local STEP = 3
-- grade: number, or per-sample array of max rise per stud
local function pathHeights(pts, win, grade, closed)
	local n = #pts
	local raw = table.create(n)
	for i = 1, n do
		raw[i] = Gen.baseHeight(pts[i][1], pts[i][2])
	end
	local sm = table.create(n)
	for i = 1, n do
		local s, c = 0, 0
		for d = -win, win do
			local j = i + d
			if closed then
				j = ((j - 1) % n) + 1
				s += raw[j]
				c += 1
			elseif j >= 1 and j <= n then
				s += raw[j]
				c += 1
			end
		end
		sm[i] = s / c
	end
	local ga = type(grade) == "table"
	for _ = 1, 3 do
		for i = 2, n do
			local g = (ga and grade[i] or grade) * STEP
			sm[i] = clamp(sm[i], sm[i - 1] - g, sm[i - 1] + g)
		end
		for i = n - 1, 1, -1 do
			local g = (ga and grade[i + 1] or grade) * STEP
			sm[i] = clamp(sm[i], sm[i + 1] - g, sm[i + 1] + g)
		end
	end
	for i = 1, n do
		pts[i][3] = sm[i]
	end
	return pts
end

-- re-run the grade clamp while holding pinned samples (pads, hairpin landings) at fixed heights
local function clampPinned(pts, pins, grade)
	local n = #pts
	local ga = type(grade) == "table"
	for i, y in pairs(pins) do
		pts[i][3] = y
	end
	for _ = 1, 3 do
		for i = 2, n do
			if not pins[i] then
				local g = (ga and grade[i] or grade) * STEP
				pts[i][3] = clamp(pts[i][3], pts[i - 1][3] - g, pts[i - 1][3] + g)
			end
		end
		for i = n - 1, 1, -1 do
			if not pins[i] then
				local g = (ga and grade[i + 1] or grade) * STEP
				pts[i][3] = clamp(pts[i][3], pts[i + 1][3] - g, pts[i + 1][3] + g)
			end
		end
	end
end

-- pin the contiguous run of samples around the nearest sample that lies inside the disc
local function pinDisc(pts, pins, x, z, rad, y, soft, id)
	local n = #pts
	local best, c = math.huge, nil
	for i, p in ipairs(pts) do
		local dx, dz = p[1] - x, p[2] - z
		local d = dx * dx + dz * dz
		if d < best then
			best, c = d, i
		end
	end
	local r2 = rad * rad
	if not c or best > r2 then
		return
	end
	local function inside(i)
		local p = pts[i]
		local dx, dz = p[1] - x, p[2] - z
		return dx * dx + dz * dz <= r2
	end
	local i = c
	while i >= 1 and inside(i) do
		pins[i] = y
		if soft then
			soft[i] = id
		end
		i -= 1
	end
	i = c + 1
	while i <= n and inside(i) do
		pins[i] = y
		if soft then
			soft[i] = id
		end
		i += 1
	end
end

local function cumulative(pts)
	local s = table.create(#pts, 0)
	for i = 2, #pts do
		local dx, dz = pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2]
		s[i] = s[i - 1] + sqrt(dx * dx + dz * dz)
	end
	return s
end

local function nearestIdx(pts, x, z)
	local best, bi = math.huge, 1
	for i = 1, #pts do
		local dx, dz = pts[i][1] - x, pts[i][2] - z
		local d = dx * dx + dz * dz
		if d < best then
			best, bi = d, i
		end
	end
	return bi, sqrt(best)
end
Gen.nearestIdx = nearestIdx

-- spatial hash of path samples for proximity queries
local function hashPts(pts)
	local H = {}
	for i, p in ipairs(pts) do
		local key = (floor(p[1] / 32) + 200) * 1000 + (floor(p[2] / 32) + 200)
		local b = H[key]
		if not b then
			b = {}
			H[key] = b
		end
		b[#b + 1] = i
	end
	return H
end
local function queryHash(H, pts, x, z, rad)
	local best, bi = rad * rad, nil
	local cx, cz = floor(x / 32), floor(z / 32)
	for ox = -1, 1 do
		for oz = -1, 1 do
			local b = H[(cx + ox + 200) * 1000 + (cz + oz + 200)]
			if b then
				for _, i in ipairs(b) do
					local dx, dz = pts[i][1] - x, pts[i][2] - z
					local d = dx * dx + dz * dz
					if d < best then
						best, bi = d, i
					end
				end
			end
		end
	end
	return bi, sqrt(best)
end
Gen.hashPts, Gen.queryHash = hashPts, queryHash

function Gen.buildPaths()
	local P = { rings = {}, branches = {} }
	-- main route + summit spiral (control points carry optional waypoint names)
	local ctrl = {}
	for _, c in ipairs(C.ROUTE) do
		ctrl[#ctrl + 1] = { c[1], c[2], c[3] }
	end
	for _, S in ipairs(C.SUMMIT_SPIRAL) do
		local th = S.theta0 + S.step
		local first = true
		while th <= S.theta1 + 1e-6 do
			local t = (th - S.theta0) / (S.theta1 - S.theta0)
			ctrl[#ctrl + 1] = { th, lerp(S.re0, S.re1, t), first and S.name or nil }
			first = false
			th += S.step
		end
	end
	local ctrlIdx = {}
	local dense = smoothXZ(densifyPolar(ctrl, 8, ctrlIdx), 3, 2, false)
	local denseS = cumulative(dense)
	local main = resample(dense, STEP, false)
	-- expected resampled index of each control point (avoids snapping to a neighbouring switchback leg)
	local function ctrlSample(k, x, z)
		local est = floor(denseS[ctrlIdx[k]] / STEP) + 1
		local best, bi = math.huge, est
		for i = max(1, est - 30), min(#main, est + 30) do
			local dx, dz = main[i][1] - x, main[i][2] - z
			local d = dx * dx + dz * dz
			if d < best then
				best, bi = d, i
			end
		end
		return bi
	end
	P.main = main
	P.mainS = cumulative(main)
	P.wp = {}
	for k, c in ipairs(ctrl) do
		if c[3] then
			local x, z = Gen.toWorld(c[1], c[2])
			P.wp[c[3]] = ctrlSample(k, x, z)
		end
	end
	P.wp.Summit = #main

	-- per-sample grade limits: stair sections beside the falls and on the summit crown
	local G = C.GRADE
	local grade = table.create(#main, G.default)
	for i = P.wp.Camp1, P.wp.ForestEdge do
		grade[i] = G.stairs
	end
	for i = P.wp.SummitStairs, #main do
		grade[i] = G.summitStairs
	end
	P.grade = grade
	pathHeights(main, 16, grade, false)

	-- hairpin landings: flat 84-stud landing at every switchback apex so the two arms meet level
	local pins, soft = {}, {}
	local R = C.ROUTE
	for k = 2, #R - 1 do
		if (R[k][1] - R[k - 1][1]) * (R[k + 1][1] - R[k][1]) < 0 then
			local x, z = Gen.toWorld(R[k][1], R[k][2])
			local a = ctrlSample(k, x, z)
			-- wide average so rib bumps don't set the landing height
			local s, c = 0, 0
			for i = max(1, a - 30), min(#main, a + 30) do
				s += main[i][3]
				c += 1
			end
			local y = s / c
			local leg = min(abs(R[k][1] - R[k - 1][1]), abs(R[k + 1][1] - R[k][1])) * R[k][2]
			local half = clamp(floor(leg / STEP / 8), 3, 14)
			for i = max(1, a - half), min(#main, a + half) do
				pins[i] = y
				soft[i] = k
			end
		end
	end
	-- pads: route-height pads pin the route flat across the pad; fixed pads pin to their height
	P.pads = {}
	for _, pad in ipairs(C.PADS) do
		local x, z = pad.x, pad.z
		if not x then
			x, z = Gen.toWorld(pad.theta, pad.re)
		end
		local y = pad.height
		if y == "route" then
			y = main[P.wp[pad.name] or nearestIdx(main, x, z)][3]
		elseif y == "h0" then
			y = Gen.baseHeight(x, z)
		end
		P.pads[pad.name] = { x = x, y = y, z = z, radius = pad.radius, blend = pad.blend, kind = pad.kind }
		local isSoft = pad.kind == 4 and pad.height == "route"
		pinDisc(main, pins, x, z, pad.radius, y, isSoft and soft or nil, pad.name)
	end
	clampPinned(main, pins, grade)
	-- drop soft pins (landings, feature pads) that make the grade infeasible, then re-clamp
	for _ = 1, 8 do
		local dropped = false
		for i = 2, #main do
			if abs(main[i][3] - main[i - 1][3]) > grade[i] * STEP * 1.25 + 0.01 then
				local id = soft[i] or soft[i - 1]
				if id then
					for k2, v in pairs(soft) do
						if v == id then
							soft[k2], pins[k2] = nil, nil
						end
					end
					dropped = true
				end
			end
		end
		if not dropped then
			break
		end
		clampPinned(main, pins, grade)
	end
	local mainHash = hashPts(main)
	P.mainHash = mainHash

	-- rings: closed loops, heights pulled to the main route where they meet it
	for _, rg in ipairs(C.RINGS) do
		local ctl = {}
		for k = 0, 125 do
			ctl[#ctl + 1] = { k / 126 * TAU, rg.re }
		end
		local pts = densifyPolar(ctl, 8)
		table.remove(pts) -- duplicate of first point
		pts = smoothXZ(pts, 2, 1, true)
		pts = resample(pts, STEP, true)
		pathHeights(pts, 20, 0.25, true)
		local rpins = {}
		for i, p in ipairs(pts) do
			local mi, d = queryHash(mainHash, main, p[1], p[2], 36)
			if mi then
				p[3] = lerp(main[mi][3], p[3], smoothstep(10, 36, d))
				if d < 12 then
					rpins[i] = main[mi][3]
				end
			end
		end
		for _, pad in pairs(P.pads) do
			pinDisc(pts, rpins, pad.x, pad.z, pad.radius, pad.y)
		end
		clampPinned(pts, rpins, 0.25)
		P.rings[rg.name] = pts
	end
	for _, br in ipairs(C.BRANCHES) do
		local pts = resample(smoothXZ(densifyPolar(br.pts, 8), 2, 1, false), STEP, false)
		pathHeights(pts, 10, 0.3, false)
		local bpins = {}
		local mi = queryHash(mainHash, main, pts[1][1], pts[1][2], 40)
		if mi then
			bpins[1] = main[mi][3]
		end
		for _, pad in pairs(P.pads) do
			pinDisc(pts, bpins, pad.x, pad.z, pad.radius, pad.y)
		end
		clampPinned(pts, bpins, 0.3)
		P.branches[br.name] = pts
	end
	return P
end

---------------------------------------------------------------- field
local function newF32(v)
	local b = buffer.create(NN * 4)
	if v ~= 0 then
		for i = 0, NN - 1 do
			writef32(b, i * 4, v)
		end
	end
	return b
end

local function cellRange(cx, R)
	return max(0, floor((cx - R + HALF) / CELL)), min(N - 1, floor((cx + R + HALF) / CELL))
end
Gen.cellRange = cellRange

local function stampDisc(F_, cx, cz, rad, blend, y, kind, prio)
	local R = rad + blend
	local i0, i1 = cellRange(cx, R)
	local j0, j1 = cellRange(cz, R)
	local SW, SH, SK = F_.SW, F_.SH, F_.SK
	for j = j0, j1 do
		local dz = cellC(j) - cz
		for i = i0, i1 do
			local dx = cellC(i) - cx
			local d = sqrt(dx * dx + dz * dz)
			if d < R then
				-- tiny falloff inside the core so the nearest sample (not the first stamped) sets the height
				local w = (d <= rad) and (1 - 0.02 * d / rad) or (0.98 * (1 - smoothstep(rad, R, d)))
				local score = w + prio * 0.001
				local idx = j * N + i
				if score > readf32(SW, idx * 4) then
					writef32(SW, idx * 4, score)
					writef32(SH, idx * 4, y)
					writeu8(SK, idx, kind)
				end
			end
		end
	end
end

local function stampPath(F_, pts, hw, blend, kind, prio)
	for i = 1, #pts do
		local p = pts[i]
		stampDisc(F_, p[1], p[2], hw, blend, p[3], kind, prio)
	end
end

-- carve a water channel along samples with per-sample water level
local function carveChannel(F_, pts, wl, hw, blend, depth)
	local H, W, FL = F_.H, F_.W, F_.FL
	for k = 1, #pts do
		local p = pts[k]
		local level = wl[k]
		local bed = level - depth
		local R = hw + blend
		local i0, i1 = cellRange(p[1], R)
		local j0, j1 = cellRange(p[2], R)
		for j = j0, j1 do
			local dz = cellC(j) - p[2]
			for i = i0, i1 do
				local dx = cellC(i) - p[1]
				local d = sqrt(dx * dx + dz * dz)
				if d < R then
					local idx = j * N + i
					local h = readf32(H, idx * 4)
					if d < hw then
						local t = d / hw
						local target = bed + t * t * (level + 1.2 - bed)
						if h > target then
							h = target
						end
						writef32(H, idx * 4, h)
						if h < level and readf32(W, idx * 4) < level then
							writef32(W, idx * 4, level)
						end
						writeu8(FL, idx, 1)
					else
						local t = smoothstep(0, 1, (d - hw) / blend)
						local target = lerp(level + 1.2, h, t)
						if h > target then
							writef32(H, idx * 4, target)
						end
					end
				end
			end
		end
	end
end

local function waterLevels(F_, pts, first, last, drop)
	local n = #pts
	local H = F_.H
	local raw = table.create(n)
	for k = 1, n do
		local i = clamp(floor((pts[k][1] + HALF) / CELL), 0, N - 1)
		local j = clamp(floor((pts[k][2] + HALF) / CELL), 0, N - 1)
		raw[k] = readf32(H, (j * N + i) * 4)
	end
	local wl = table.create(n)
	for k = 1, n do
		local s, c = 0, 0
		for d = -12, 12 do
			local j = k + d
			if j >= 1 and j <= n then
				s += raw[j]
				c += 1
			end
		end
		-- never above the local channel floor, so water can't stand proud of its banks
		wl[k] = min(s / c - drop, raw[k] - drop * 0.5)
	end
	if first then
		wl[1] = first
	end
	for k = 2, n do
		wl[k] = min(wl[k], wl[k - 1])
	end
	if last then
		for k = 1, n do
			wl[k] = max(wl[k], last)
		end
		local tail = max(2, floor(n * 0.08))
		for k = n - tail, n do
			local t = (k - (n - tail)) / tail
			wl[k] = lerp(wl[k], last, t)
		end
	end
	return wl
end

function Gen.computeField()
	local t0 = os.clock()
	local F_ = {}
	F_.H = newF32(0)
	F_.RE = newF32(0)
	F_.SW = newF32(0)
	F_.SH = newF32(0)
	F_.W = newF32(-10000)
	F_.SK = buffer.create(NN)
	F_.FL = buffer.create(NN)
	F_.K = buffer.create(NN)
	F_.R = buffer.create(NN)
	local H, RE = F_.H, F_.RE

	for j = 0, N - 1 do
		local z = cellC(j)
		for i = 0, N - 1 do
			local h, re = Gen.baseHeight(cellC(i), z)
			local idx = (j * N + i) * 4
			writef32(H, idx, h)
			writef32(RE, idx, re)
		end
		if j % 150 == 149 then
			task.wait()
		end
	end
	local tBase = os.clock() - t0

	local P = Gen.buildPaths()
	stampPath(F_, P.main, 8, 10, 1, 3)
	for _, pts in pairs(P.rings) do
		stampPath(F_, pts, 5, 7, 2, 1)
	end
	for _, pts in pairs(P.branches) do
		stampPath(F_, pts, 4, 6, 2, 2)
	end
	task.wait()

	for _, pad in pairs(P.pads) do
		stampDisc(F_, pad.x, pad.z, pad.radius, pad.blend, pad.y, pad.kind, 5 + pad.kind)
	end

	-- apply stamps
	local SW, SH = F_.SW, F_.SH
	for idx = 0, NN - 1 do
		local w = readf32(SW, idx * 4)
		if w > 0 then
			w = min(1, w)
			local h = readf32(H, idx * 4)
			writef32(H, idx * 4, h + (readf32(SH, idx * 4) - h) * w)
		end
	end
	task.wait()

	-- water: lake
	local L = C.LAKE
	do
		local R = L.radius * 1.15 + 45
		local i0, i1 = cellRange(L.x, R)
		local j0, j1 = cellRange(L.z, R)
		for j = j0, j1 do
			local dz = cellC(j) - L.z
			for i = i0, i1 do
				local dx = cellC(i) - L.x
				local d = sqrt(dx * dx + dz * dz)
				local a = atan2(dx, dz)
				local Rr = L.radius * (1 + 0.24 * noise(cos(a) * 1.4 + 0.3, sin(a) * 1.4 + 0.7, 3.3))
				local idx = j * N + i
				local h = readf32(H, idx * 4)
				if d < Rr then
					local t = d / Rr
					local bed = L.level - L.depth * (1 - t * t)
					if h > bed then
						h = bed
					end
					writef32(H, idx * 4, h)
					if h < L.level then
						writef32(F_.W, idx * 4, L.level)
					end
					writeu8(F_.FL, idx, 1)
				elseif d < Rr + 45 then
					local t = smoothstep(0, 1, (d - Rr) / 45)
					local target = lerp(L.level + 0.6, h, t)
					if h > target then
						writef32(H, idx * 4, target)
					end
				end
			end
		end
	end

	-- falls pool
	local PL = C.POOL
	local px, pz = Gen.toWorld(PL.theta, PL.re)
	do
		local i0, i1 = cellRange(px, PL.radius + 2)
		local j0, j1 = cellRange(pz, PL.radius + 2)
		for j = j0, j1 do
			local dz = cellC(j) - pz
			for i = i0, i1 do
				local dx = cellC(i) - px
				local d = sqrt(dx * dx + dz * dz)
				if d < PL.radius then
					local idx = j * N + i
					local t = d / PL.radius
					local target = PL.bed + t * t * (PL.level + 1 - PL.bed)
					local h = readf32(H, idx * 4)
					if h > target then
						writef32(H, idx * 4, target)
						h = target
					end
					if h < PL.level then
						writef32(F_.W, idx * 4, PL.level)
					end
					writeu8(F_.FL, idx, 1)
				end
			end
		end
	end

	-- creek (forest shelf -> falls lip) and river (pool -> lake)
	local CR = C.CREEK
	local creek = resample(smoothXZ(densifyPolar(CR.pts, 6), 2, 2, false), STEP, false)
	local creekWl = waterLevels(F_, creek, nil, nil, 1.2)
	carveChannel(F_, creek, creekWl, CR.halfWidth, CR.blend, CR.depth)
	local RV = C.RIVER
	local river = resample(smoothXZ(densifyPolar(RV.pts, 6), 3, 2, false), STEP, false)
	local riverWl = waterLevels(F_, river, RV.startLevel, L.level, 1.8)
	carveChannel(F_, river, riverWl, RV.halfWidth, RV.blend, RV.depth)
	P.river, P.creek = river, creek
	for k = 1, #river do
		river[k][3] = riverWl[k]
	end
	for k = 1, #creek do
		creek[k][3] = creekWl[k]
	end

	-- waterfall sheet: vertical water against the lip wall
	do
		local x0, z0 = Gen.toWorld(F.theta, 1200)
		local i0, i1 = cellRange(x0, 60)
		local j0, j1 = cellRange(z0, 60)
		for j = j0, j1 do
			local z = cellC(j)
			for i = i0, i1 do
				local x = cellC(i)
				local idx = j * N + i
				local th = atan2(x, z)
				if abs(angDiff(th, F.theta)) < 0.013 then
					local re = readf32(RE, idx * 4)
					local rl = Gen.fallLip(th)
					if re >= rl - 0.5 and re <= rl + 7 and readf32(H, idx * 4) < F.lipY - 1 then
						writef32(F_.W, idx * 4, F.lipY - 1)
						writeu8(F_.FL, idx, 2)
					end
				end
			end
		end
	end

	-- chasm (Broken Cliffs gorge under the monumental bridge)
	local CH = C.CHASM
	do
		local x0, z0 = Gen.toWorld(CH.theta, (CH.reIn + CH.reOut) / 2)
		local i0, i1 = cellRange(x0, 230)
		local j0, j1 = cellRange(z0, 230)
		for j = j0, j1 do
			local z = cellC(j)
			for i = i0, i1 do
				local x = cellC(i)
				local idx = j * N + i
				local re = readf32(RE, idx * 4)
				if re > CH.reIn and re < CH.reOut then
					local th = atan2(x, z)
					local d = abs(angDiff(th, CH.theta) * re)
					local hw = (32 + (re - CH.reIn) * 0.06 + 7 * noise(re / 60 + 0.3, 4.4, 0.7) * 2)
						* smoothstep(CH.reIn, CH.reIn + 28, re)
					if d < hw + 6 then
						local floorY = CH.floor + (CH.reOut - re) * 0.3
						local t = max(smoothstep(hw - 4, hw + 6, d), smoothstep(CH.reOut - 22, CH.reOut, re))
						local h = readf32(H, idx * 4)
						local target = lerp(floorY, h, t)
						if h > target then
							writef32(H, idx * 4, target)
						end
					end
				end
			end
		end
	end
	task.wait()

	-- crossings that need bridges (route/rings vs river, creek, chasm)
	P.crossings = {}
	local function findCross(pathName, pts)
		local inRun, startI = false, 0
		for i = 1, #pts do
			local p = pts[i]
			local ci = clamp(floor((p[1] + HALF) / CELL), 0, N - 1)
			local cj = clamp(floor((p[2] + HALF) / CELL), 0, N - 1)
			local idx = cj * N + ci
			local h = readf32(H, idx * 4)
			local gap = (p[3] - h) > 3.5 or readu8(F_.FL, idx) ~= 0
			if gap and not inRun then
				inRun, startI = true, i
			elseif not gap and inRun then
				inRun = false
				if i - startI >= 2 then
					table.insert(P.crossings, { path = pathName, i0 = startI, i1 = i })
				end
			end
		end
	end
	findCross("Main", P.main)
	for name, pts in pairs(P.rings) do
		findCross(name, pts)
	end
	-- merge runs split by a short bank (one bridge per crossing)
	local merged = {}
	for _, c in ipairs(P.crossings) do
		local last = merged[#merged]
		if last and last.path == c.path and c.i0 - last.i1 <= 5 then
			last.i1 = c.i1
		else
			merged[#merged + 1] = c
		end
	end
	P.crossings = merged

	-- surfaces
	local K, Rg, FL, SK = F_.K, F_.R, F_.FL, F_.SK
	local TRAIL = { M_GROUND, M_GROUND, M_SLATE, M_LIME, M_SLATE, M_GROUND }
	for j = 0, N - 1 do
		local z = cellC(j)
		local jm, jp = max(0, j - 1), min(N - 1, j + 1)
		for i = 0, N - 1 do
			local x = cellC(i)
			local idx = j * N + i
			local h = readf32(H, idx * 4)
			local im, ip = max(0, i - 1), min(N - 1, i + 1)
			local sx = (readf32(H, (j * N + ip) * 4) - readf32(H, (j * N + im) * 4)) / ((ip - im) * CELL)
			local sz = (readf32(H, (jp * N + i) * 4) - readf32(H, (jm * N + i) * 4)) / ((jp - jm) * CELL)
			local slope = sqrt(sx * sx + sz * sz)
			local re = readf32(RE, idx * 4)
			local r = sqrt(x * x + z * z)
			local reg = Gen.regionOf(re, r)
			writeu8(Rg, idx, reg)
			local sw = min(1, readf32(SW, idx * 4))
			local sk = readu8(SK, idx)
			local n = noise(x / 90 + 0.17, z / 90 + 0.53, 8.8)
			local k
			if readu8(FL, idx) ~= 0 then
				k = M_SAND
			elseif sw > 0.55 and (sk == 1 or sk == 2) and slope < 1.2 then
				k = TRAIL[reg]
			elseif sk == 3 and sw > 0.975 then
				-- camp pads: cobbled core, trodden ring; the blend slopes fall through to grass/rock
				k = (sw > 0.988) and M_COBBLE or M_GROUND
			elseif sk == 5 and sw > 0.5 then
				local dz = z - 1880
				k = (sqrt(x * x + dz * dz) < 70) and M_COBBLE or M_GRASS
			elseif sk == 4 and sw > 0.8 and reg <= 2 then
				k = M_GROUND
			elseif reg == 1 then
				-- meadow emerald with deeper leafy patches so open meadows aren't one flat colour
				local n2 = noise(x / 240 + 0.61, z / 240 + 0.19, 4.4)
				k = (slope > 1.6) and M_ROCK or (((re < 1330 and n > 0.18) or n2 > 0.22) and M_LEAFY or M_GRASS)
			elseif reg == 2 then
				k = (slope > 1.6) and M_ROCK or ((n > 0.3) and M_GRASS or M_LEAFY)
			elseif reg == 3 then
				if slope > 0.8 then
					local b = floor((h + n * 20) / 24) % 5
					k = (b == 2 or b == 4) and M_SLATE or M_SAND_STONE
				else
					k = (n > 0.32) and M_GRASS or M_SAND_STONE
				end
			elseif reg == 4 then
				if slope > 0.75 then
					-- storm-blue rock with charcoal strata and wind-blown snow streaks
					if n > 0.3 and slope < 1.7 then
						k = M_SNOW
					else
						k = (floor((h + n * 24) / 36) % 3 == 2) and M_SLATE or M_BASALT
					end
				else
					k = (n + (h - 1250) / 300 * 0.6 > 0.35) and M_SNOW or M_SLATE
				end
			elseif reg == 5 then
				-- icy spire (§4 "Luminous ice blue"), dark rock only as sparse accents
				if slope < 0.9 then
					k = M_SNOW
				elseif slope > 1.2 and n > 0.38 then
					k = M_BASALT
				else
					k = (slope < 2.4) and M_GLACIER or M_ICE
				end
			else
				-- rim backdrop: green lower slopes, rock only on steep faces, snow caps
				local n2 = noise(x / 240 + 0.61, z / 240 + 0.19, 4.4)
				if h > 430 + n * 60 then
					k = (slope > 1.6) and M_ROCK or M_SNOW
				else
					k = (slope > 1.35) and M_ROCK or ((n2 > 0.1) and M_LEAFY or M_GRASS)
				end
			end
			writeu8(K, idx, k)
		end
		if j % 200 == 199 then
			task.wait()
		end
	end

	_G.CC_HF = F_
	_G.CC_PATHS = P
	return { seconds = os.clock() - t0, baseSeconds = tBase, mainSamples = #P.main, crossings = #P.crossings }
end

---------------------------------------------------------------- voxel writer
local AIR, WATER = Enum.Material.Air, Enum.Material.Water
-- Measured 2026-10-20: Roblox renders a voxel column's surface ~1.6-2.0 studs above the filled height
-- (two full 4-stud layers topped at y render at y+1.6). Writing h - SURF makes the visible surface match
-- the heightfield, so props, stairs and bridges placed with heightAt() / path heights sit on the ground.
local SURF = 1.7

local function deepMat(reg, y, depth, sn)
	if reg == 1 or reg == 6 then
		return depth < 12 and M_GROUND or M_ROCK
	elseif reg == 2 then
		return depth < 10 and M_GROUND or M_ROCK
	elseif reg == 3 then
		local b = floor((y + sn * 18) / 22) % 5
		return (b == 2 or b == 4) and M_SLATE or M_SAND_STONE
	elseif reg == 4 then
		return (floor((y + sn * 16) / 30) % 3 == 2) and M_SLATE or M_BASALT
	end
	return depth < 12 and M_GLACIER or M_BASALT
end

function Gen.writeBlock(bi, bj)
	local F_ = _G.CC_HF
	local H, W, K, Rg = F_.H, F_.W, F_.K, F_.R
	local i0, j0 = bi * BLOCK, bj * BLOCK
	local i1, j1 = min(i0 + BLOCK, N) - 1, min(j0 + BLOCK, N) - 1
	local nx, nz = i1 - i0 + 1, j1 - j0 + 1
	local tops, bots, wts, ks, rs, sns = {}, {}, {}, {}, {}, {}
	local ymin, ymax = math.huge, -math.huge
	for jj = 0, nz - 1 do
		local j = j0 + jj
		for ii = 0, nx - 1 do
			local i = i0 + ii
			local idx = j * N + i
			local h = readf32(H, idx * 4) - SURF
			local nb = h + SURF
			for dj = -1, 1 do
				local jn = clamp(j + dj, 0, N - 1)
				for di = -1, 1 do
					local hn = readf32(H, (jn * N + clamp(i + di, 0, N - 1)) * 4)
					if hn < nb then
						nb = hn
					end
				end
			end
			local w = readf32(W, idx * 4) - SURF
			local c = jj * nx + ii + 1
			local b = nb - SURF - 10
			local t = max(h, w)
			tops[c], bots[c], wts[c] = h, b, w
			ks[c], rs[c] = readu8(K, idx), readu8(Rg, idx)
			sns[c] = noise(i * 0.045 + 0.31, j * 0.045 + 0.77, 1.3)
			if b < ymin then
				ymin = b
			end
			if t > ymax then
				ymax = t
			end
		end
	end
	local y0 = floor(ymin / 4) * 4
	local y1 = ceil(ymax / 4) * 4
	if y1 <= y0 then
		y1 = y0 + 4
	end
	local ny = (y1 - y0) / 4
	local mats, occ = table.create(nx), table.create(nx)
	for ii = 1, nx do
		local mX, oX = table.create(ny), table.create(ny)
		for yi = 1, ny do
			local yb = y0 + (yi - 1) * 4
			local mXY, oXY = table.create(nz, AIR), table.create(nz, 0)
			for jj = 1, nz do
				local c = (jj - 1) * nx + ii
				local h = tops[c]
				if yb + 4 > bots[c] then
					if yb < h then
						local o = min(1, (h - yb) / 4)
						if o > 0.02 then
							local depth = h - yb - 2
							local m = (depth < 13) and ks[c] or deepMat(rs[c], yb, depth, sns[c])
							mXY[jj] = MAT[m]
							oXY[jj] = o
						end
					else
						local w = wts[c]
						if yb < w then
							mXY[jj] = WATER
							oXY[jj] = min(1, (w - yb) / 4)
						end
					end
				end
			end
			mX[yi], oX[yi] = mXY, oXY
		end
		mats[ii], occ[ii] = mX, oX
	end
	local region = Region3.new(
		Vector3.new(cellC(i0) - CELL / 2, y0, cellC(j0) - CELL / 2),
		Vector3.new(cellC(i1) + CELL / 2, y1, cellC(j1) + CELL / 2)
	)
	workspace.Terrain:WriteVoxels(region, 4, mats, occ)
	return nx * ny * nz
end

function Gen.writeRows(bj0, bj1)
	local nb = ceil(N / BLOCK)
	local total = 0
	for bj = bj0, min(bj1, nb - 1) do
		for bi = 0, nb - 1 do
			total += Gen.writeBlock(bi, bj)
			if bi % 4 == 3 then
				task.wait()
			end
		end
		task.wait()
	end
	return total
end

function Gen.applyColors()
	local T = workspace.Terrain
	for name, col in pairs(C.MATERIAL_COLORS) do
		T:SetMaterialColor(Enum.Material[name], col)
	end
	T.WaterColor = C.WATER_COLOR
	T.WaterTransparency = 0.55
	T.WaterReflectance = 0.25
	T.WaterWaveSize = 0.08
	T.WaterWaveSpeed = 6
end

-- height lookup on the written field (for prop placement)
function Gen.heightAt(x, z)
	local F_ = _G.CC_HF
	local fi = (x + HALF) / CELL - 0.5
	local fj = (z + HALF) / CELL - 0.5
	local i, j = clamp(floor(fi), 0, N - 2), clamp(floor(fj), 0, N - 2)
	local tx, tz = clamp(fi - i, 0, 1), clamp(fj - j, 0, 1)
	local H = F_.H
	local a = readf32(H, (j * N + i) * 4)
	local b = readf32(H, (j * N + i + 1) * 4)
	local c = readf32(H, ((j + 1) * N + i) * 4)
	local d = readf32(H, ((j + 1) * N + i + 1) * 4)
	return lerp(lerp(a, b, tx), lerp(c, d, tx), tz)
end

return Gen
