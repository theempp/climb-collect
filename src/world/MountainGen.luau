--!native
-- MountainGen (V3 Ascent): heightfield + voxel writer for the CLIMB & COLLECT mountain.
-- Usage (edit mode, via execute_luau):
--   local Gen = require(folderClone.MountainGen)
--   Gen.computeField(opts)        -- builds _G.CC_HF (heights, water, materials) and _G.CC_PATHS
--                                 -- opts.routes = false skips stamping the four routes (P1 terrain-only)
--   Gen.writeRows(bj0, bj1)       -- writes voxel rows of 32x32-cell blocks
--   Gen.writeCrown()              -- voxel features a heightfield can't hold (the crown arch)
--   Gen.applyColors()
local C = require(script.Parent.WorldConfig)
local Gen = {}

local noise = math.noise
local sqrt, atan2, sin, cos, abs, exp = math.sqrt, math.atan2, math.sin, math.cos, math.abs, math.exp
local floor, ceil, min, max, clamp = math.floor, math.ceil, math.min, math.max, math.clamp
local PI, TAU = math.pi, 2 * math.pi
local readf32, writef32, readu8, writeu8 = buffer.readf32, buffer.writef32, buffer.readu8, buffer.writeu8

local CELL, HALF, N, BLOCK = C.CELL, C.HALF, C.N, C.BLOCK
local NN = N * N
Gen.CELL, Gen.HALF, Gen.N = CELL, HALF, N

local MAT = {
	Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud,
	Enum.Material.Rock, Enum.Material.Sandstone, Enum.Material.Slate, Enum.Material.Basalt,
	Enum.Material.Snow, Enum.Material.Glacier, Enum.Material.Ice, Enum.Material.Cobblestone,
	Enum.Material.Sand, Enum.Material.Limestone, Enum.Material.Salt, Enum.Material.Asphalt,
}
local M_GRASS, M_LEAFY, M_GROUND, M_MUD, M_ROCK, M_SAND_STONE, M_SLATE, M_BASALT = 1, 2, 3, 4, 5, 6, 7, 8
local M_SNOW, M_GLACIER, M_ICE, M_COBBLE, M_SAND, M_LIME, M_SALT = 9, 10, 11, 12, 13, 14, 15
local M_MARK = 16 -- v5: marked (climbable) rock under ledge edges, CoreConfig.CLIMB.terrainMaterial
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
local LUT_MAX = 4000
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
	local a = 70 * clamp((r - 180) / 600, 0, 1) * (1 - smoothstep(2450, 2700, r))
	if a == 0 then
		return 0
	end
	-- low-order lobes break the concentric "layer cake" read
	local th = atan2(x, z)
	local lobes = r * (0.10 * sin(2 * th + 0.7) + 0.065 * sin(3 * th + 2.1) + 0.03 * sin(5 * th + 0.9)) * clamp((r - 300) / 500, 0, 1)
		* (1 - 0.5 * smoothstep(2000, 2500, r))
	return lobes + a * (noise(x / 1200 + 0.37, z / 1200 + 0.11, 9.3) * 2 + 0.35 * noise(x / 400 + 0.2, z / 400 + 0.6, 4.1) * 2)
end

-- polar (theta, effective radius) -> world x, z (inverts rwarp by fixed-point iteration)
function Gen.toWorld(th, re)
	local s, c = sin(th), cos(th)
	local r = re
	for _ = 1, 6 do
		r = re - Gen.rwarp(r * s, r * c, r)
	end
	return r * s, r * c
end

-- rib (gully/ridge) amplitude by re: strong on the steep bands, weak on the shelves
local RIB = {
	{0, 0}, {40, 0}, {140, 70}, {380, 80}, {420, 10}, {530, 12}, {560, 80}, {780, 70}, {800, 18}, {880, 18},
	{900, 60}, {945, 55}, {960, 14}, {1050, 14}, {1070, 110}, {1250, 100}, {1280, 14}, {1520, 14}, {1550, 70},
	{1610, 60}, {1640, 8}, {1880, 8}, {1910, 30}, {2100, 26}, {2140, 5}, {2600, 5},
}
local DETAIL = {
	{0, 6}, {400, 12}, {480, 18}, {900, 20}, {1250, 14}, {1550, 10}, {1650, 6}, {2050, 4}, {2450, 4}, {2600, 30}, {3800, 40},
}
local SP, CR = C.SPIRE, C.CROWN
local SPCA, SPSA = cos(SP.angle), sin(SP.angle)

-- massifs (world positions resolved lazily: toWorld needs rwarp)
local PEAKS
local function peakBonus(x, z)
	if not PEAKS then
		PEAKS = {}
		for _, pk in ipairs(C.PEAKS) do
			local px, pz = Gen.toWorld(pk.theta, pk.re)
			local L = sqrt(px * px + pz * pz)
			PEAKS[#PEAKS + 1] = { px, pz, pk.height, pk.radius, px / L, pz / L, pk.stretch or 1 }
		end
	end
	local add = 0
	for _, pk in ipairs(PEAKS) do
		local dx, dz = x - pk[1], z - pk[2]
		local R = pk[4] * pk[7]
		if dx * dx + dz * dz < R * R then
			-- radial component at full radius, tangential stretched: a ridge along the contour
			local rad = dx * pk[5] + dz * pk[6]
			local tan = -dx * pk[6] + dz * pk[5]
			local d = sqrt(rad * rad + (tan / pk[7]) ^ 2)
			if d < pk[4] then
				add += pk[3] * (1 - d / pk[4]) ^ 1.6
			end
		end
	end
	return add
end

-- crown: twin horns + notch, 3 fins, 4 buttress roots (the Crown Gate arch is voxels, writeCrown)
local function crownBonus(x, z, r, re, th)
	local add = 0
	local u, v = x * SPCA + z * SPSA, -x * SPSA + z * SPCA
	if r < 140 then
		local H = CR.horns
		local R2 = H.radius * H.radius
		local du1, du2 = u - H.offset, u + H.offset
		add += H.height * (exp(-(du1 * du1 + v * v) / R2) + exp(-(du2 * du2 + v * v) / R2))
		local Nt = CR.notch
		add -= Nt.depth * max(0, 1 - abs(u) / Nt.halfWidth) * (1 - smoothstep(Nt.radius * 0.5, Nt.radius, r))
	end
	for _, f in ipairs(CR.fins) do
		if re > f.re0 and re < f.re1 then
			local d = abs(angDiff(th, f.theta)) * r
			if d < f.halfWidth then
				local env = smoothstep(f.re0, f.re0 + 50, re) * (1 - smoothstep(f.re1 - 70, f.re1, re))
				add += f.height * (1 - d / f.halfWidth) ^ 1.2 * env
			end
		end
	end
	local B = CR.buttress
	if re > B.re0 and re < B.re1 then
		local q = (th - SP.angle) % (PI / 2)
		local d = min(q, PI / 2 - q) * r
		local env = smoothstep(B.re0, B.re0 + 60, re) * (1 - smoothstep(B.re1 - 90, B.re1, re))
		add += B.height * exp(-(d / B.halfWidth) ^ 2) * env
	end
	return add
end

-- dark-rock mask for the crown materials: fins and buttress ridges read as basalt against the ice
function Gen.crownRock(x, z)
	local r = sqrt(x * x + z * z)
	if r < 60 or r > 560 then
		return 0
	end
	local th = atan2(x, z)
	local re = r + Gen.rwarp(x, z, r)
	local m = 0
	for _, f in ipairs(CR.fins) do
		if re > f.re0 and re < f.re1 then
			local d = abs(angDiff(th, f.theta)) * r
			if d < f.halfWidth * 1.3 then
				m = max(m, 1 - d / (f.halfWidth * 1.3))
			end
		end
	end
	local B = CR.buttress
	if re > B.re0 and re < B.re1 + 40 then
		local q = (th - SP.angle) % (PI / 2)
		local d = min(q, PI / 2 - q) * r
		m = max(m, exp(-(d / (B.halfWidth * 0.55)) ^ 2))
	end
	return m
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
	local floorY = F.poolY + 1 + max(0, re - rLip - 50) * 0.12
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
		local uu, vv = abs(x * SPCA + z * SPSA) / r, abs(-x * SPSA + z * SPCA) / r
		local f = (uu ^ SP.p + vv ^ SP.p) ^ (1 / SP.p) / SP.norm
		reh = lerp(re * f, re, smoothstep(SP.inner, SP.outer, re))
	end
	-- wavy band edges: buttresses and recesses so the bands aren't cylinders
	local bw = 95 * smoothstep(1085, 1120, re) * (1 - smoothstep(1225, 1260, re))
		+ 80 * smoothstep(560, 600, re) * (1 - smoothstep(760, 800, re))
		+ 45 * smoothstep(1545, 1570, re) * (1 - smoothstep(1600, 1625, re))
		+ 40 * smoothstep(1900, 1930, re) * (1 - smoothstep(2090, 2125, re))
	if bw > 0 then
		reh += bw * (0.6 * sin(5 * th + 1.3) + 0.4 * sin(9 * th + 0.4))
	end
	local h = Gen.profile(reh)
	local ct, st = cos(th), sin(th)
	-- asymmetry: the mid mountain leans (one flank higher), so shelves and bands aren't level rings
	local tiltA = 150 * smoothstep(380, 700, re) * (1 - smoothstep(1500, 1950, re))
	if tiltA > 0 then
		h += tiltA * (0.6 * sin(th - 0.8) + 0.4 * sin(2 * th + 0.3))
	end

	local ribA = plin(RIB, re)
	if ribA > 0 then
		local n1 = noise(ct * 2.2 + 11.3, st * 2.2 + 3.7, re / 300 + 0.31)
		local n2 = noise(ct * 5.1 + 2.9, st * 5.1 + 7.1, re / 160 + 0.77)
		local rib = 1 - min(1, abs(n1) * 2.2)
		h += ribA * ((rib - 0.45) * 1.2 + n2 * 0.8)
	end

	h += peakBonus(x, z)
	if re < 560 then
		h += crownBonus(x, z, r, re, th)
	end

	local dA = plin(DETAIL, re)
	h += dA * (noise(x / 170 + 0.13, z / 170 + 0.71, 5.5) * 1.4 + noise(x / 70 + 0.41, z / 70 + 0.29, 2.7) * 0.6)

	-- rolling meadow hills (Green Valley shelf)
	local mw = smoothstep(1640, 1700, re) * (1 - smoothstep(1840, 1900, re))
	if mw > 0 then
		h += mw * 20 * noise(x / 420 + 0.3, z / 420 + 0.9, 2.2) * 2
	end
	-- dry foothills: low rounded hills and gullies
	local fw = smoothstep(2150, 2230, re) * (1 - smoothstep(2580, 2680, re))
	if fw > 0 then
		h += fw * (26 * noise(x / 300 + 0.71, z / 300 + 0.17, 3.9) * 2 + 8 * noise(x / 90 + 0.5, z / 90 + 0.2, 1.1) * 2)
	end

	-- outer rim peaks frame the mountain
	if r > 2600 then
		local wr = smoothstep(2600, 2850, r)
		local n = noise(x / 560 + 0.5, z / 560 + 0.25, 6.6)
		local ridge = 1 - min(1, abs(n) * 2)
		h += wr * (360 * ridge * ridge + 60 * noise(x / 210 + 0.1, z / 210 + 0.3, 1.9) * 2)
	end

	h = applyFall(h, re, th)
	return h, re, r, th
end

-- biome by altitude (edges wobble with noise n in [-1, 1]); 6 = rim backdrop
local BI = C.BIOME
function Gen.regionOf(h, r, n)
	n = n or 0
	if r > BI.rimR then
		return 6
	end
	local y = h + n * 45
	if y < BI.foothills then
		return 7
	elseif y < BI.valley then
		return 1
	elseif y < BI.forest then
		return 2
	elseif y < BI.cliffs then
		return 3
	elseif y < BI.storm then
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

local function smoothXZ(pts, k, iters, closed, lock)
	for _ = 1, iters do
		local n = #pts
		local o = table.create(n)
		for i = 1, n do
			if (not closed and (i == 1 or i == n)) or (lock and lock[i]) then
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
Gen.STEP = STEP
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
		pts[i][4] = raw[i]
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
	for _ = 1, 4 do
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

-- pin every sample inside the disc to height y
local function pinDisc(pts, pins, x, z, rad, y, soft, id)
	local r2 = rad * rad
	for i, p in ipairs(pts) do
		local dx, dz = p[1] - x, p[2] - z
		if dx * dx + dz * dz <= r2 then
			pins[i] = y
			if soft then
				soft[i] = id
			end
		end
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
Gen.cumulative = cumulative

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
	local reach = ceil(rad / 32)
	for ox = -reach, reach do
		for oz = -reach, reach do
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

-- hairpins: each unnamed switchback apex becomes a semicircle (radius >= trail width + 2) so the two arms
-- stay apart up to the turn. Smoothing alone collapsed apexes into a V with a height step between the arms
-- (P4a bot stucks at s 7,586 / 17,126). Returns the expanded ctrl list and the ctrl index ranges to lock.
local function expandHairpins(ctrl, hw)
	local out, locks, orig = {}, {}, {}
	for k, c in ipairs(ctrl) do
		local a, b = ctrl[k - 1], ctrl[k + 1]
		if a and b and not c[3] and (c[1] - a[1]) * (b[1] - c[1]) < 0 then
			local leg = math.min(abs(a[2] - c[2]), abs(b[2] - c[2]))
			local r = clamp(max(leg * 0.5, hw * 2 + 2), 8, 26)
			local sg = (a[1] > c[1]) and 1 or -1 -- the arms lie on this side of the apex (theta)
			local ia = (a[2] >= b[2]) and 1 or -1 -- incoming arm on this side (radius)
			local hp = clamp(floor(math.min(abs(c[1] - a[1]), abs(b[1] - c[1])) * c[2] / STEP / 10), 2, 8)
			local k0 = #out + 1
			for d = 90, -90, -30 do
				local ph = math.rad(d)
				local u = sg * r * (1 - math.cos(ph))
				out[#out + 1] = { c[1] + u / c[2], c[2] + ia * r * math.sin(ph), hp = (d == 0) and hp or nil }
				if d == 0 then
					orig[k] = #out -- the apex of the semicircle stands for the original hairpin point
				end
			end
			locks[#locks + 1] = { k0, #out }
		else
			out[#out + 1] = c
			orig[k] = #out
		end
	end
	return out, locks, orig
end

-- one route: polar control points -> resampled {x, z, y, raw} samples with pins at pads and hairpins
local function buildRoute(def, pads)
	local ctrl, locks, orig = expandHairpins(def.ctrl, def.hw or 4)
	local ctrlIdx = {}
	local d0 = densifyPolar(ctrl, 8, ctrlIdx)
	local lock = {}
	for _, l in ipairs(locks) do
		for i = ctrlIdx[l[1]], ctrlIdx[l[2]] do
			lock[i] = true
		end
	end
	local dense = smoothXZ(d0, 3, 2, false, lock)
	local denseS = cumulative(dense)
	local pts = resample(dense, STEP, false)
	local function ctrlSample(k)
		local x, z = Gen.toWorld(ctrl[k][1], ctrl[k][2])
		local est = floor(denseS[ctrlIdx[k]] / STEP) + 1
		local best, bi = math.huge, est
		for i = max(1, est - 30), min(#pts, est + 30) do
			local dx, dz = pts[i][1] - x, pts[i][2] - z
			local d = dx * dx + dz * dz
			if d < best then
				best, bi = d, i
			end
		end
		return bi
	end
	local wp = {}
	for k, c in ipairs(ctrl) do
		if c[3] then
			wp[c[3]] = ctrlSample(k)
		end
	end
	pathHeights(pts, 14, def.grade, false)
	local pins, soft = {}, {}
	-- hairpin landings: short flat landing at each switchback apex so the two arms meet level
	for k = 2, #ctrl - 1 do
		if (ctrl[k][1] - ctrl[k - 1][1]) * (ctrl[k + 1][1] - ctrl[k][1]) < 0 then
			local a = ctrlSample(k)
			local s, c = 0, 0
			for i = max(1, a - 20), min(#pts, a + 20) do
				s += pts[i][3]
				c += 1
			end
			local y = s / c
			local half = ctrl[k].hp or clamp(floor(math.min(abs(ctrl[k][1] - ctrl[k - 1][1]), abs(ctrl[k + 1][1] - ctrl[k][1])) * ctrl[k][2] / STEP / 10), 2, 8)
			for i = max(1, a - half), min(#pts, a + half) do
				pins[i] = y
				soft[i] = k
			end
		end
	end
	-- pads: camps and the Foothold pin the route flat across the pad core
	for name, pad in pairs(pads) do
		-- pin across the pad core plus its blend ring (whole ring for the Foothold), so trailheads sit on the pad
		pinDisc(pts, pins, pad.x, pad.z, pad.radius + pad.blend * ((pad.kind == 5) and 1 or 0.35), pad.y)
	end
	clampPinned(pts, pins, def.grade)
	for _ = 1, 8 do
		local dropped = false
		for i = 2, #pts do
			if abs(pts[i][3] - pts[i - 1][3]) > def.grade * STEP * 1.25 + 0.01 then
				local id = soft[i] or soft[i - 1]
				if not id then
					-- the conflict sits at a hard pin: drop the nearest soft landing instead
					for o = 1, 400 do
						id = soft[i + o] or soft[i - 1 - o]
						if id then
							break
						end
					end
				end
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
		clampPinned(pts, pins, def.grade)
	end
	-- v4 P3: sample index + arc length of every ORIGINAL ctrl point (route "lines" in WorldConfig refer to them)
	local S = cumulative(pts)
	local ctrlI, ctrlS = {}, {}
	for k = 1, #def.ctrl do
		local e = orig[k]
		if e then
			ctrlI[k] = ctrlSample(e)
			ctrlS[k] = S[ctrlI[k]]
		end
	end
	return { name = def.name, def = def, pts = pts, S = S, wp = wp, ctrlI = ctrlI, ctrlS = ctrlS }
end

-- opts.skip = { [name] = true }: v4 routes not built (v5: gated routes and routes rebuilt on the spline kit)
function Gen.buildPaths(opts)
	local skip = (opts and opts.skip) or {}
	local P = { routes = {}, routeList = {}, rings = {}, branches = {} }
	-- pads first: camps sit at their natural height, every route is pinned to them
	P.pads = {}
	for _, pad in ipairs(C.PADS) do
		local x, z = pad.x, pad.z
		if pad.camp then
			local cp = C.CAMPS[pad.name]
			x, z = Gen.toWorld(cp.theta, cp.re)
		elseif not x then
			x, z = Gen.toWorld(pad.theta, pad.re)
		end
		local y = pad.height
		if y == "h0" then
			-- wide average so a rib bump doesn't set the pad height
			local s, c = 0, 0
			for ox = -1, 1 do
				for oz = -1, 1 do
					s += Gen.baseHeight(x + ox * pad.radius * 0.6, z + oz * pad.radius * 0.6)
					c += 1
				end
			end
			y = s / c
		end
		P.pads[pad.name] = { x = x, y = y, z = z, radius = pad.radius, blend = pad.blend, kind = pad.kind }
	end
	for _, def in ipairs(C.ROUTES) do
		if not skip[def.name] then
			local R = buildRoute(def, P.pads)
			P.routes[def.name] = R
			P.routeList[#P.routeList + 1] = R
		end
	end
	-- shared summit stair: spiral from the merge pad to the crown notch
	local S = C.SUMMIT_STAIR
	local ctrl = {}
	local th = S.theta0
	while th <= S.theta1 + 1e-6 do
		local t = (th - S.theta0) / (S.theta1 - S.theta0)
		ctrl[#ctrl + 1] = { th, lerp(S.re0, S.re1, t) }
		th += S.step
	end
	local stair = buildRoute({ name = "SummitStair", ctrl = ctrl, grade = S.grade, hw = 5, blend = 6 }, {
		Merge = P.pads.Merge,
		SummitCrown = P.pads.SummitCrown,
	})
	P.routes.SummitStair = stair
	-- checkpoints (RouteNet): camps + evenly spaced mini-checkpoints per leg, ~cpTarget s of skilled time apart
	local RM = C.ROUTE_MODEL
	local legs = { "Gate", "Camp1", "Camp2", "Camp3", "Camp4", "Merge" }
	local walk = C.PLAYER.walkSpeed
	for _, R in ipairs(P.routeList) do
		local total = R.S[#R.S] + stair.S[#stair.S]
		local k = (total / walk + RM.segMin[R.name] * 60) / (total / walk)
		R.skilledMin = (total / walk) * k / 60
		R.walkMin = total / walk / 60
		R.checkpoints = {}
		for li = 1, #legs - 1 do
			local i0, i1 = R.wp[legs[li]], R.wp[legs[li + 1]]
			local legT = (R.S[i1] - R.S[i0]) / walk * k
			-- fewest checkpoints that keep every gap <= cpMax (gaps land between ~2.5 and 5 min)
			local n = math.max(0, math.ceil(legT / RM.cpMax) - 1)
			for c = 1, n do
				local s = R.S[i0] + (R.S[i1] - R.S[i0]) * c / (n + 1)
				local bi = i0
				while bi < i1 and R.S[bi] < s do
					bi += 1
				end
				R.checkpoints[#R.checkpoints + 1] = { i = bi, leg = li, name = string.format("%s_CP%d_%d", R.name, li, c) }
			end
			if li < #legs - 1 then
				R.checkpoints[#R.checkpoints + 1] = { i = i1, leg = li, name = legs[li + 1], camp = true }
			end
		end
	end
	if P.routes.Shepherd then
		Gen.buildMain(P)
	end
	return P
end

-- legacy single-route view (TraverseKit, exportRoute): Shepherd's Road + summit stair
function Gen.buildMain(P)
	local sh = P.routes.Shepherd
	local stair = P.routes.SummitStair
	local main = table.clone(sh.pts)
	for i = 2, #stair.pts do
		main[#main + 1] = stair.pts[i]
	end
	P.main = main
	P.mainS = cumulative(main)
	P.wp = table.clone(sh.wp)
	P.wp.FootholdGate = sh.wp.Gate
	P.wp.SummitStairs = #sh.pts
	P.wp.Summit = #main
	P.mainHash = hashPts(main)
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

-- knife-edge crest along a route: the ground falls away at `slope` on both sides of the trail
local function stampCrest(F_, pts, hw, reach, slope)
	local H = F_.H
	for k = 1, #pts, 2 do
		local p = pts[k]
		local i0, i1 = cellRange(p[1], reach)
		local j0, j1 = cellRange(p[2], reach)
		for j = j0, j1 do
			local dz = cellC(j) - p[2]
			for i = i0, i1 do
				local dx = cellC(i) - p[1]
				local d = sqrt(dx * dx + dz * dz)
				if d < reach then
					local idx = j * N + i
					local h = readf32(H, idx * 4)
					local ridge = p[3] - slope * max(0, d - hw)
					local w = 1 - smoothstep(reach * 0.6, reach, d)
					local target = lerp(h, ridge, w)
					-- only lower (cut couloirs beside the crest) or raise up to the crest line
					if (d < reach * 0.6) or (target < h) then
						writef32(H, idx * 4, target)
					end
				end
			end
		end
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

function Gen.computeField(opts)
	opts = opts or {}
	local withRoutes = opts.routes ~= false
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

	-- v5 (opts.v5): live routes are spline routes (RouteSpline + SplineGen), gated routes are not built at all
	local RSd = opts.v5 and require(script.Parent.RouteSpline)
	local skip = {}
	if RSd then
		for _, name in ipairs(RSd.LIVE) do
			skip[name] = true
		end
		for name in pairs(RSd.GATED) do
			skip[name] = true
		end
		for _, name in ipairs(opts.v4Keep or {}) do
			skip[name] = nil -- a live route not rebuilt yet keeps its v4 path (P1 prototype: Waterfall)
		end
	end
	local P = Gen.buildPaths({ skip = skip })
	P.withRoutes = withRoutes
	if withRoutes then
		-- unstamped stretches: stampSkip = { s0, s1 } (v4 P1) and every v4 route line with stamp ~= true
		-- (lines = { { kind, c0, c1 } }, ctrl indices): the line there is an authored climb, so the natural
		-- cliff stays and no stamped trail is left as a bypass
		local function skipList(R)
			local d, out = R.def, {}
			if d.stampSkip then
				out[#out + 1] = { d.stampSkip[1], d.stampSkip[2] }
			end
			for _, ln in ipairs(d.lines or {}) do
				-- a line by absolute arc length (s0 / s1, hang lines) or by control points (c0 / c1 + pads, stacks)
				if ln.stamp ~= true and ln.s0 and ln.s1 then
					out[#out + 1] = { ln.s0, ln.s1 }
				elseif ln.stamp ~= true and R.ctrlS[ln.c0] and R.ctrlS[ln.c1] then
					out[#out + 1] = { R.ctrlS[ln.c0] + (ln.pad0 or 0), R.ctrlS[ln.c1] - (ln.pad1 or 0) }
				end
			end
			R.skips = out
			return out
		end
		local function kept(R)
			local sk = R.skips or skipList(R)
			if #sk == 0 then
				return R.pts
			end
			local pts = {}
			for i, p in ipairs(R.pts) do
				local skip = false
				for _, r in ipairs(sk) do
					if R.S[i] >= r[1] and R.S[i] <= r[2] then
						skip = true
						break
					end
				end
				if not skip then
					pts[#pts + 1] = p
				end
			end
			return pts
		end
		for _, R in ipairs(P.routeList) do
			if R.def.crest then
				stampCrest(F_, kept(R), R.def.hw + 1, R.def.crest + 16, 1.25)
			end
		end
		for _, R in ipairs(P.routeList) do
			local d = R.def
			stampPath(F_, kept(R), d.hw, d.blend, (d.hw <= 3) and 6 or ((d.name == "Shepherd") and 1 or 2), d.prio)
		end
		local st = P.routes.SummitStair
		stampPath(F_, st.pts, 5, 6, 1, 4)
	end
	task.wait()

	for _, pad in pairs(P.pads) do
		stampDisc(F_, pad.x, pad.z, pad.radius, pad.blend, pad.y, pad.kind, 5 + pad.kind)
	end

	-- apply stamps (ledge stamps, kind 6, only cut outside their core: the drop side stays a drop)
	local SW, SH, SK = F_.SW, F_.SH, F_.SK
	for idx = 0, NN - 1 do
		local w = readf32(SW, idx * 4)
		if w > 0 then
			w = min(1, w)
			local h = readf32(H, idx * 4)
			local y = readf32(SH, idx * 4)
			if not (readu8(SK, idx) == 6 and w < 0.95 and y > h) then
				writef32(H, idx * 4, h + (y - h) * w)
			end
		end
	end
	task.wait()

	-- water: foothill lake
	local L = C.LAKE
	local lx, lz = Gen.toWorld(L.theta, L.re)
	do
		local R = L.radius * 1.15 + 45
		local i0, i1 = cellRange(lx, R)
		local j0, j1 = cellRange(lz, R)
		for j = j0, j1 do
			local dz = cellC(j) - lz
			for i = i0, i1 do
				local dx = cellC(i) - lx
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
	P.lake = { x = lx, z = lz, level = L.level, radius = L.radius }

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
	P.pool = { x = px, z = pz, level = PL.level, radius = PL.radius }

	-- creek (forest band -> falls lip) and river (pool -> lake)
	local CRK = C.CREEK
	local creek = resample(smoothXZ(densifyPolar(CRK.pts, 6), 2, 2, false), STEP, false)
	local creekWl = waterLevels(F_, creek, nil, nil, 1.2)
	carveChannel(F_, creek, creekWl, CRK.halfWidth, CRK.blend, CRK.depth)
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
		local x0, z0 = Gen.toWorld(F.theta, F.lipOuter - 10)
		local i0, i1 = cellRange(x0, 70)
		local j0, j1 = cellRange(z0, 70)
		for j = j0, j1 do
			local z = cellC(j)
			for i = i0, i1 do
				local x = cellC(i)
				local idx = j * N + i
				local th = atan2(x, z)
				if abs(angDiff(th, F.theta)) < 0.011 then
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
		local i0, i1 = cellRange(x0, 260)
		local j0, j1 = cellRange(z0, 260)
		for j = j0, j1 do
			local z = cellC(j)
			for i = i0, i1 do
				local x = cellC(i)
				local idx = j * N + i
				local re = readf32(RE, idx * 4)
				if re > CH.reIn and re < CH.reOut then
					local th = atan2(x, z)
					local d = abs(angDiff(th, CH.theta) * re)
					local hw = (34 + (re - CH.reIn) * 0.06 + 7 * noise(re / 60 + 0.3, 4.4, 0.7) * 2)
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

	-- v5 spline routes: built and stamped after water and chasm carving (their cross-sections win)
	if RSd and withRoutes then
		local SG = require(script.Parent.SplineGen)
		P.v5 = {}
		-- v6: creek gorges (enforced crossings on open ground) before the routes that cross them
		P.gorges = {}
		for _, g in ipairs(RSd.GORGES or {}) do
			P.gorges[#P.gorges + 1] = SG.gorge(F_, Gen, g)
		end
		for _, def in ipairs(RSd.ROUTES) do
			if skip[def.name] then
				local R = SG.build(def, Gen, P.pads)
				P.routes[def.name] = R
				P.routeList[#P.routeList + 1] = R
				P.v5[#P.v5 + 1] = def.name
				R.stamped = SG.stamp(F_, R, Gen)
				task.wait()
			end
		end
		if P.routes.Shepherd and P.routes.Shepherd.v5 then
			Gen.buildMain(P)
		end
	end

	-- pit fill (v4 run 2): overlapping switchback cuts left narrow shafts and slots 25-190 studs deep beside hairpins
	-- on the Waterfall / Ledge summit approaches (players fell in). Near every route point but off the trail core
	-- (hw + 3, so a trail cut through a spur is never filled), a cell is raised when it is surrounded on >= 10 of 12
	-- sides by ground > 10 higher (a shaft), or sits > 20 below both sides of a narrow (<= 16 studs) slot. Changed
	-- cells are listed in F_.pitFixes (world x, z) so a rebuild can rewrite just those.
	F_.pitFixes = {}
	if P.routeList then
		local near, core = {}, {}
		local function markAround(set, x, z, rad)
			local i0, i1 = cellRange(x, rad)
			local j0, j1 = cellRange(z, rad)
			for j = j0, j1 do
				local dz = cellC(j) - z
				for i = i0, i1 do
					local dx = cellC(i) - x
					if dx * dx + dz * dz <= rad * rad then
						set[j * N + i] = true
					end
				end
			end
		end
		-- only around hairpin apexes (heading turns > 120 deg over ~24 points): gullies, the falls slot and the chasm
		-- beside straight trail are left alone; never on the trail core of any route
		for _, R in pairs(P.routes) do
			local hw = (R.def and (R.def.hw or (R.def.w and R.def.w / 2 + 2))) or 5
			local pts = R.pts
			for k = 1, #pts, 2 do
				markAround(core, pts[k][1], pts[k][2], hw + 3)
			end
			-- two scales: long arms (+-12 points) and the short summit-approach arms (+-5)
			for _, w in ipairs({ 12, 5 }) do
				for k = w + 1, #pts - w, 2 do
					local a, b, c = pts[k - w], pts[k], pts[k + w]
					local ux, uz = b[1] - a[1], b[2] - a[2]
					local vx, vz = c[1] - b[1], c[2] - b[2]
					local lu, lv = sqrt(ux * ux + uz * uz), sqrt(vx * vx + vz * vz)
					if lu > 1 and lv > 1 and (ux * vx + uz * vz) / (lu * lv) < -0.5 then
						markAround(near, b[1], b[2], 26)
					end
				end
			end
		end
		local DIRS = {}
		for a = 0, 11 do
			DIRS[#DIRS + 1] = { math.cos(a * math.pi / 6), math.sin(a * math.pi / 6) }
		end
		local function hAt(i, j)
			return readf32(H, (clamp(j, 0, N - 1) * N + clamp(i, 0, N - 1)) * 4)
		end
		for _ = 1, 4 do
			local changed = 0
			for idx in pairs(near) do
				if not core[idx] and readf32(F_.W, idx * 4) < readf32(H, idx * 4) + 0.5 then
					local i, j = idx % N, idx // N
					local h = readf32(H, idx * 4)
					local target = nil
					for _, rc in ipairs({ 3, 5 }) do
						local higher, lo = 0, math.huge
						for _, d in ipairs(DIRS) do
							local hn = hAt(i + floor(d[1] * rc + 0.5), j + floor(d[2] * rc + 0.5))
							if hn > h + 10 then
								higher += 1
							end
							if hn < lo then
								lo = hn
							end
						end
						if higher >= 10 and lo > h + 1 then
							target = math.max(target or -math.huge, lo)
						end
					end
					-- a narrow slot across one of 6 axes (both sides within 8 studs stand > 20 higher)
					for a = 1, 6 do
						local d = DIRS[a]
						local ha = hAt(i + floor(d[1] * 2 + 0.5), j + floor(d[2] * 2 + 0.5))
						local hb = hAt(i - floor(d[1] * 2 + 0.5), j - floor(d[2] * 2 + 0.5))
						local m = math.min(ha, hb)
						if m > h + 20 then
							target = math.max(target or -math.huge, m - 2)
						end
					end
					if target and target > h + 1 then
						writef32(H, idx * 4, target)
						changed += 1
						F_.pitFixes[#F_.pitFixes + 1] = { cellC(i), cellC(j) }
					end
				end
			end
			task.wait()
			if changed == 0 then
				break
			end
		end
	end

	-- crossings that need bridges (each route vs water, chasm, or a dip it can't stand on)
	P.crossings = {}
	local function findCross(pathName, pts)
		local inRun, startI = false, 0
		local found = {}
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
					found[#found + 1] = { path = pathName, i0 = startI, i1 = i }
				end
			end
		end
		local merged = {}
		for _, c in ipairs(found) do
			local last = merged[#merged]
			if last and c.i0 - last.i1 <= 5 then
				last.i1 = c.i1
			else
				merged[#merged + 1] = c
			end
		end
		for _, c in ipairs(merged) do
			P.crossings[#P.crossings + 1] = c
		end
	end
	if withRoutes then
		for name, R in pairs(P.routes) do
			if not R.v5 then
				findCross(name, R.pts)
			end
		end
	end

	-- surfaces
	local K, Rg, FL = F_.K, F_.R, F_.FL
	-- trail material per biome: valley, forest, cliffs, storm, summit, rim, foothills
	local TRAIL = { M_GROUND, M_GROUND, M_SLATE, M_LIME, M_SLATE, M_GROUND, M_MUD }
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
			local r = sqrt(x * x + z * z)
			local n = noise(x / 90 + 0.17, z / 90 + 0.53, 8.8)
			local nb = noise(x / 380 + 0.41, z / 380 + 0.83, 2.6)
			local reg = Gen.regionOf(h, r, nb)
			writeu8(Rg, idx, reg)
			local sw = min(1, readf32(SW, idx * 4))
			local sk = readu8(SK, idx)
			local k
			local tr = F_.TR and readu8(F_.TR, idx) or 0
			if readu8(FL, idx) ~= 0 then
				k = M_SAND
			elseif tr == 2 then
				k = M_MARK
			elseif tr == 1 and slope < 1.3 then
				k = TRAIL[reg]
			elseif sw > 0.55 and (sk == 1 or sk == 2 or sk == 6) and slope < 1.3 then
				k = TRAIL[reg]
			elseif sk == 3 and sw > 0.975 then
				-- camp pads: cobbled core, trodden ring; the blend slopes fall through to the biome
				k = (sw > 0.988) and M_COBBLE or M_GROUND
			elseif sk == 5 and sw > 0.5 then
				k = M_SALT -- Foothold pad: dry grass; FootholdV3 paints the plaza and paths
			elseif sk == 4 and sw > 0.8 then
				k = (reg >= 4 and reg ~= 7) and M_SLATE or M_GROUND
			elseif reg == 7 then
				-- dry foothills: dry grass with red-brown earth patches and gullies, rock on steep faces
				local n2 = noise(x / 160 + 0.61, z / 160 + 0.19, 4.4)
				if slope > 1.4 then
					k = (n > 0.1) and M_ROCK or M_MUD
				elseif slope > 0.7 or n2 > 0.28 then
					k = M_MUD
				else
					k = M_SALT
				end
			elseif reg == 1 then
				-- meadow emerald with deeper leafy patches so open meadows aren't one flat colour
				local n2 = noise(x / 240 + 0.61, z / 240 + 0.19, 4.4)
				k = (slope > 2.4) and M_ROCK or ((n > 0.2 or n2 > 0.24 or slope > 1.3) and M_LEAFY or M_GRASS)
			elseif reg == 2 then
				k = (slope > 2.6) and M_ROCK or ((n > 0.3 and slope < 1.2) and M_GRASS or M_LEAFY)
			elseif reg == 3 then
				if slope > 0.8 then
					local b = floor((h + n * 5) / 26) % 5
					k = (b == 2 or b == 4) and M_SLATE or M_SAND_STONE
				else
					k = (n > 0.3) and M_GRASS or M_SAND_STONE
				end
			elseif reg == 4 then
				if slope > 0.75 then
					-- storm-blue rock with charcoal strata and wind-blown snow streaks
					if n > 0.3 and slope < 1.7 then
						k = M_SNOW
					else
						k = (floor((h + n * 24) / 40) % 3 == 2) and M_SLATE or M_BASALT
					end
				else
					k = (n + (h - 1900) / 450 * 0.6 > 0.35) and M_SNOW or M_SLATE
				end
			elseif reg == 5 then
				-- icy spire (§4 "Luminous ice blue"); fins and buttress ridges are dark rock, faces carry
				-- vertical rock streaks (no blotches)
				if Gen.crownRock(x, z) > 0.45 and slope > 0.6 then
					k = M_BASALT
				elseif slope < 0.9 then
					k = M_SNOW
				else
					k = M_GLACIER
				end
			else
				-- rim backdrop: dry lower slopes like the foothills, rock on steep faces, snow caps
				if h > 520 + n * 70 then
					k = (slope > 1.6) and M_ROCK or M_SNOW
				elseif h > 260 + n * 60 then
					k = (slope > 1.1) and M_ROCK or M_LEAFY
				else
					k = (slope > 1.2) and M_ROCK or ((n > 0.15) and M_MUD or M_SALT)
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
	local lens = {}
	for name, R in pairs(P.routes) do
		lens[name] = floor(R.S[#R.S])
	end
	return { seconds = os.clock() - t0, baseSeconds = tBase, routes = lens, crossings = #P.crossings }
end

---------------------------------------------------------------- voxel writer
local AIR, WATER = Enum.Material.Air, Enum.Material.Water
-- Measured 2026-10-20: Roblox renders a voxel column's surface ~1.6-2.0 studs above the filled height
-- (two full 4-stud layers topped at y render at y+1.6). Writing h - SURF makes the visible surface match
-- the heightfield, so props, stairs and bridges placed with heightAt() / path heights sit on the ground.
local SURF = 1.7

local function deepMat(reg, y, depth, sn)
	if reg == 7 then
		return depth < 12 and M_MUD or M_ROCK
	elseif reg == 1 or reg == 6 then
		return depth < 12 and M_GROUND or M_ROCK
	elseif reg == 2 then
		return depth < 10 and M_GROUND or M_ROCK
	elseif reg == 3 then
		local b = floor((y + sn * 4) / 22) % 5
		return (b == 2 or b == 4) and M_SLATE or M_SAND_STONE
	elseif reg == 4 then
		return (floor((y + sn * 16) / 30) % 3 == 2) and M_SLATE or M_BASALT
	end
	return depth < 12 and M_GLACIER or M_BASALT
end

-- writes the voxel columns of cells i0..i1 x j0..j1 (extraAir: also clear that many studs above the top)
local function writeCells(i0, i1, j0, j1, extraAir)
	local F_ = _G.CC_HF
	local H, W, K, Rg = F_.H, F_.W, F_.K, F_.R
	local nx, nz = i1 - i0 + 1, j1 - j0 + 1
	local tops, bots, wts, ks, rs, sns, exps = {}, {}, {}, {}, {}, {}, {}
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
			-- exposed side of a steep column keeps the surface material (strata regions show layered rock)
			local rg = rs[c]
			exps[c] = (rg == 3 or rg == 4) and 13 or max(13, h + SURF - nb + 8)
			-- v6: trail tread columns show the trail material only near the top (a ledge on a cliff hung dirt "drips"
			-- the whole height of its outer face)
			if F_.TR and readu8(F_.TR, idx) == 1 then
				exps[c] = 4
			end
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
	local y1 = ceil((ymax + (extraAir or 0)) / 4) * 4
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
							local m = (depth < exps[c]) and ks[c] or deepMat(rs[c], yb, depth, sns[c])
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

function Gen.writeBlock(bi, bj)
	local i0, j0 = bi * BLOCK, bj * BLOCK
	return writeCells(i0, min(i0 + BLOCK, N) - 1, j0, min(j0 + BLOCK, N) - 1)
end

-- rewrite only the cells inside a world-space box from the current field (local re-stamps, e.g. a route stretch
-- that is no longer stamped); clears 160 studs of air above so an old raised stamp can't survive
function Gen.writeBox(x0, z0, x1, z1)
	local function ci(v)
		return clamp(floor((v + HALF) / CELL), 0, N - 1)
	end
	local i0, i1, j0, j1 = ci(min(x0, x1)), ci(max(x0, x1)), ci(min(z0, z1)), ci(max(z0, z1))
	local total = 0
	for jb = j0, j1, BLOCK do
		for ib = i0, i1, BLOCK do
			total += writeCells(ib, min(ib + BLOCK - 1, i1), jb, min(jb + BLOCK - 1, j1), 160)
			task.wait()
		end
	end
	return total
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
Gen.BLOCK_ROWS = ceil(N / BLOCK)

-- Crown Gate: a free-standing voxel rock arch on the crown shoulder, straddling the summit stair
function Gen.writeCrown()
	local A = C.CROWN.arch
	local T = workspace.Terrain
	local st = _G.CC_PATHS.routes.SummitStair
	local best, bi = math.huge, 2
	for i = 2, #st.pts - 1 do
		local p = st.pts[i]
		local d = abs(sqrt(p[1] * p[1] + p[2] * p[2]) + Gen.rwarp(p[1], p[2], sqrt(p[1] * p[1] + p[2] * p[2])) - A.atRe)
		if d < best then
			best, bi = d, i
		end
	end
	local p, q = st.pts[bi - 1], st.pts[bi + 1]
	local c = st.pts[bi]
	local dx, dz = q[1] - p[1], q[2] - p[2]
	local L = sqrt(dx * dx + dz * dz)
	local nx, nz = -dz / L, dx / L
	local base = c[3]
	local n = 0
	for a = 0, PI + 1e-6, PI / 40 do
		local x = c[1] + nx * cos(a) * A.halfSpan
		local z = c[2] + nz * cos(a) * A.halfSpan
		local y = base + sin(a) * A.height
		T:FillBall(Vector3.new(x, y, z), A.thickness * (1 + 0.35 * (1 - sin(a))), Enum.Material.Basalt)
		n += 1
	end
	-- legs root into the shoulder
	for side = -1, 1, 2 do
		local x = c[1] + nx * side * A.halfSpan
		local z = c[2] + nz * side * A.halfSpan
		T:FillBlock(CFrame.new(x, base - 8, z), Vector3.new(A.thickness * 2.4, 20, A.thickness * 2.4), Enum.Material.Basalt)
	end
	_G.CC_PATHS.crownGate = { x = c[1], y = base, z = c[2], i = bi }
	return n
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
