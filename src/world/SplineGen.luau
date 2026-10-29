--!native
-- SplineGen (v5 P1, 2026-10-21): route splines -> 3D trail samples + terrain cross-sections.
-- Data: RouteSpline.ROUTES (nodes with type / width / pieces per segment). Used by MountainGen.computeField
-- (opts.v5) after the base field and water are built:
--   local R = SG.build(def, Gen, pads)   -- samples every STEP studs: pts {x, z, y}, S, ty, w, pieces, wp, rests
--   SG.stamp(F_, R, Gen)                 -- carves the cross-section of every segment type into the heightfield
--   SG.auditJson(R)                      -- segments / hazards / rests for tools/spline_audit.py
-- Segment types (cross-section about the trail line; d > 0 = outer / downhill side):
--   ledge  wall inside (>= WALL above the tread), drop outside (>= DROP below the edge, falling away)
--   slot   walls both sides (cleft, gully, wet slot)          ridge  drops both sides (knife ridge, spine)
--   open   camp / viewpoint ground, blended to the terrain     gap    bridge span: ground kept >= GAP below
--   log    log over shallow water / a creek: terrain left as it is (water stays), the log is the only tread
--   ladder vertical step (foot -> top) against a built face    stair  boulder stair (blocks, twin ladders)
-- v6 (2026-10-21, beat chains: design/v6-trails-plan.md):
--   vertical pieces (SG.VERT; foot node + synthetic top node `run` ahead, `rise` up or down): ladder, pitch (marked
--   rock face), chimney (marked face between two side walls), steps (rock blocks to jump up / down; the terrain under
--   them is the lower end's height)
--   rim / path  tread only: banks above the tread are trimmed (6-stud blend), drops beside it are never filled (a
--           gorge rim, a falls edge, open ground next to a gorge); rim = the drop side is the exposure
--   jump    ledge whose floor SplineKit removes (a gap to jump; rock lips at both ends)
--   traverse ledge whose floor SplineKit removes (a hand traverse on a marked slab along the inner wall)
--   ford    stepping stones over water: terrain left as it is (like log)
--   node drop = n: the outer drop of ledge / rim / ridge segments is at least n deep (exposure; default SG.DROP)
--   SG.gorge(F_, Gen, spec): deepens a stretch of creek into a gorge with near-vertical walls (an enforced obstacle
--   on open ground: the only way across is the route's crossing)
-- All numbers PROPOSED (v5 plan LOCKED rules: 2-5 stud tight trail ~85 %, open <= 15 %).
local SG = {}
SG.VERT = { ladder = true, pitch = true, chimney = true, steps = true }
SG.STEP_H = 3.6 -- steps: max block-to-block rise (a jump clears ~5)
SG.STEP_RUN = 3.4 -- steps: block depth along the line
SG.STEP = 2
SG.WALL = 10 -- min wall above the tread (higher than a jump: 7.2)
SG.DROP = 7 -- min drop right past a ledge edge
SG.GAP = 14 -- min depth under a bridge / log span
SG.SINK = 0.2 -- the terrain IS the walking surface (user 2026-10-21: no plank / tread layer, natural rock)
-- no marked (catchable) rock under ledge edges: walking off an edge is a real fall to the last checkpoint (user
-- 2026-10-21: falls that cost progress keep the routes tense); climbing slips keep the catch window
SG.MARK_EDGES = false
-- terrain tread core reaches hw + EDGE from the line (4-stud voxels: a 5-wide line renders ~7 studs of flat ground),
-- then a SHOULDER studs lip 1.5 lower before the drop
SG.EDGE = 2
SG.SHOULDER = 2
SG.WALL_GAP = 1.5

local sqrt, floor, ceil, min, max, abs, clamp = math.sqrt, math.floor, math.ceil, math.min, math.max, math.abs, math.clamp
local readf32, writef32, writeu8, readu8 = buffer.readf32, buffer.writef32, buffer.writeu8, buffer.readu8

local function smoothstep(e0, e1, x)
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
local function lerp(a, b, t)
	return a + (b - a) * t
end

SG.WALK = { ledge = true, slot = true, ridge = true, open = true, gap = true, log = true, stair = true, rim = true, path = true, jump = true, traverse = true, ford = true }
SG.TIGHT = { ledge = true, slot = true, ridge = true, gap = true, log = true, stair = true, rim = true, path = true, jump = true, traverse = true, ford = true }

-- default run of a vertical piece (foot -> top landing, horizontal)
function SG.pieceRun(pc, w)
	if pc.run then
		return pc.run
	end
	if pc.kind == "steps" then
		return math.ceil(math.abs(pc.rise) / SG.STEP_H) * SG.STEP_RUN + 2
	end
	return pc.inward and (w + 4) or 5
end

-- effective radius (re) on the ray at theta where the natural ground crosses height y (bands fall outward)
function SG.contourRe(Gen, th, y, rLo, rHi)
	local function g(re)
		local x, z = Gen.toWorld(th, re)
		return Gen.baseHeight(x, z)
	end
	local lo, hi = rLo, rHi
	if g(lo) < y then
		return lo, "top"
	end
	if g(hi) > y then
		return hi, "bottom"
	end
	for _ = 1, 22 do
		local m = (lo + hi) / 2
		if g(m) > y then
			lo = m
		else
			hi = m
		end
	end
	return (lo + hi) / 2
end

-- centripetal Catmull-Rom between p1 and p2 (2D), t in [0, 1]
local function cr(p0, p1, p2, p3, t)
	local function tj(ti, a, b)
		local dx, dz = b[1] - a[1], b[2] - a[2]
		return ti + max(1e-3, (dx * dx + dz * dz) ^ 0.25)
	end
	local t0 = 0
	local t1 = tj(t0, p0, p1)
	local t2 = tj(t1, p1, p2)
	local t3 = tj(t2, p2, p3)
	local tt = lerp(t1, t2, t)
	local function L(a, b, ta, tb)
		local k = (tt - ta) / (tb - ta)
		return { lerp(a[1], b[1], k), lerp(a[2], b[2], k) }
	end
	local A1, A2, A3 = L(p0, p1, t0, t1), L(p1, p2, t1, t2), L(p2, p3, t2, t3)
	local B1, B2 = L(A1, A2, t0, t2), L(A2, A3, t1, t3)
	return L(B1, B2, t1, t2)
end

-- resolve every node to world {x, z, y, nd, yd}. yd = design height (explicit y, pads, ladder tops, auto band
-- nodes) or nil (natural ground + dy). A band node without y is AUTO: its height is spread evenly by distance between
-- the neighbouring known heights (minus ladder rises in between), so a ledge leg has one steady grade. A ladder node
-- (the foot) gets a synthetic top landing node `run` ahead toward the next node and `rise` up.
local function resolveNodes(def, Gen, pads, warn)
	local list = {}
	for k, nd in ipairs(def.nodes) do
		local r = { 0, 0, 0, nd = nd, k = k }
		local pad = nd.name and pads[nd.name]
		if pad and nd.pad ~= false then
			r[1], r[2], r[3], r.yd = pad.x, pad.z, pad.y, pad.y
		elseif nd.x then
			r[1], r[2] = nd.x, nd.z
			r.yd = nd.y
		else
			r.yd = nd.y
			r.auto = nd.band and not nd.y
		end
		list[#list + 1] = r
		local pc = nd.piece
		if pc and SG.VERT[pc.kind] then
			list[#list + 1] = { 0, 0, 0, nd = { t = nd.t, w = nd.w, band = nd.band, cut = nd.cut, drop = nd.drop, synthetic = true }, k = k, top = pc, foot = r }
		end
	end
	local function place(r, y)
		local nd = r.nd
		if r.foot then
			return
		end
		if nd.th then
			local re = nd.re
			if nd.band then
				re = SG.contourRe(Gen, nd.th, y + (nd.cut or 4), nd.band[1], nd.band[2])
			end
			r[1], r[2] = Gen.toWorld(nd.th, re)
		end
	end
	local function natural(r)
		return Gen.baseHeight(r[1], r[2]) + (r.nd.dy or 0)
	end
	-- pass 0: provisional heights (auto nodes: linear in node order between known heights)
	for _, r in ipairs(list) do
		if not r.auto and not r.foot then
			if r.yd then
				place(r, r.yd)
				r[3] = r.yd
			else
				place(r, 0)
				r[3] = natural(r)
			end
		end
	end
	local function topsAndAuto(byDist)
		-- ladder tops follow their foot
		local function tops()
			for i, r in ipairs(list) do
				if r.foot then
					local f = r.foot
					local nx = list[i + 1]
					local dx, dz = 1, 0
					if r.top.dir then
						dx, dz = r.top.dir[1], r.top.dir[2]
					elseif r.top.inward then
						dx, dz = -f[1], -f[2]
					elseif nx then
						dx, dz = nx[1] - f[1], nx[2] - f[2]
					end
					local L = math.max(1e-3, sqrt(dx * dx + dz * dz))
					local run = SG.pieceRun(r.top, r.nd.w or def.w or 4)
					-- v6: an inward piece on a band lands on the upper ledge's own contour (a landing run w + 4 inward
					-- sat inside the upper ledge's outer drop and was carved out: a hole at the ladder top), but at least
					-- far enough in for the face behind the ladder / pitch
					local fnd = f.nd
					if r.top.inward and not r.top.run and fnd.band and fnd.th and fnd.cut then
						local th = math.atan2(f[1], f[2])
						local re = SG.contourRe(Gen, th, f[3] + r.top.rise + (fnd.cut or 4), fnd.band[1], fnd.band[2])
						local cx, cz = Gen.toWorld(th, re)
						local ex, ez = cx - f[1], cz - f[2]
						local minRun = (r.nd.w or def.w or 4) / 2 + ((r.top.kind == "ladder") and 4.5 or 3)
						-- (capped: a top-out onto a gentle shelf found its contour 50 studs in)
						run = math.clamp(sqrt(ex * ex + ez * ez), minRun, minRun + 5)
					end
					r[1], r[2] = f[1] + dx / L * run, f[2] + dz / L * run
					r[3] = f[3] + r.top.rise
					r.yd = r[3]
				end
			end
		end
		local i = 1
		while i <= #list do
			if list[i].auto then
				local a = i - 1
				local b = i
				while b <= #list and (list[b].auto or list[b].foot) do
					b += 1
				end
				-- run a+1 .. b-1 is auto / ladder tops; anchors a and b (both known)
				local A, Bn = list[a], list[math.min(b, #list)]
				local rises, dist = 0, {}
				local tot = 0
				for j = a + 1, math.min(b, #list) do
					local p, q = list[j - 1], list[j]
					if q.foot then
						rises += q.top.rise
						dist[j] = tot
					else
						local dx, dz = q[1] - p[1], q[2] - p[2]
						tot += (byDist and sqrt(dx * dx + dz * dz)) or 1
						dist[j] = tot
					end
				end
				local walk = Bn[3] - A[3] - rises
				local passed = 0
				for j = a + 1, b - 1 do
					local r = list[j]
					if r.foot then
						passed += r.top.rise
					else
						r[3] = A[3] + walk * dist[j] / math.max(1e-3, tot) + passed
						r.yd = r[3]
						place(r, r[3])
					end
				end
				i = b
			else
				i += 1
			end
		end
		tops()
	end
	topsAndAuto(false)
	topsAndAuto(true)
	topsAndAuto(true)
	-- checks: contour clamps, and the grade each design segment needs
	for i, r in ipairs(list) do
		local nd = r.nd
		if nd.band and nd.th and not r.foot then
			local _, cl = SG.contourRe(Gen, nd.th, r[3] + (nd.cut or 4), nd.band[1], nd.band[2])
			if cl then
				warn[#warn + 1] = string.format("node %d th %.2f y %.0f: contour clamped at band %s", r.k, nd.th, r[3], cl)
			end
		end
		local q = list[i + 1]
		if q and r.yd and q.yd and not q.foot then
			local dx, dz = q[1] - r[1], q[2] - r[2]
			local L = sqrt(dx * dx + dz * dz)
			local g = math.abs(q[3] - r[3]) / math.max(0.1, L)
			local lim = ((nd.t == "stair") and 1.0 or (def.maxGrade or 0.6)) + 0.02
			if g > lim and L > 6 then
				warn[#warn + 1] = string.format("node %d th %s -> next: grade %.2f over %.0f studs (dy %.0f)", r.k, tostring(nd.th), g, L, q[3] - r[3])
			end
		end
	end
	return list
end

-- one route: nodes -> samples
function SG.build(def, Gen, pads)
	local STEP = SG.STEP
	local warn = {}
	local nodes = resolveNodes(def, Gen, pads, warn)
	local pts, ty, wd, dp, nodeAt = {}, {}, {}, {}, {}
	local pieces = {}
	local curDrop
	local function push(x, z, y, t, w)
		pts[#pts + 1] = { x, z, y }
		ty[#pts] = t
		wd[#pts] = w
		dp[#pts] = curDrop
	end
	local curT = def.t or "ledge"
	for k = 1, #nodes - 1 do
		local a, b = nodes[k], nodes[k + 1]
		local nd = a.nd
		curT = nd.t or curT -- a node without t continues the previous segment type
		local t = curT
		local w = nd.w or def.w or 4
		curDrop = nd.drop
		nodeAt[k] = #pts + 1
		local pc = nd.piece
		if pc and SG.VERT[pc.kind] then
			-- foot at the node, top landing `run` ahead toward the next node and `rise` up (the next node is the top)
			push(a[1], a[2], a[3], pc.kind, w)
			pieces[#pieces + 1] = { kind = pc.kind, i = #pts, rise = pc.rise, run = SG.pieceRun(pc, w), spec = pc }
			continue
		end
		if pc then
			pieces[#pieces + 1] = { kind = pc.kind, i = #pts + 1, spec = pc }
		end
		-- dense spline points between a and b (centripetal Catmull-Rom over the node polyline)
		local p0 = nodes[max(1, k - 1)]
		local p3 = nodes[min(#nodes, k + 2)]
		-- a ladder breaks the curve: the trail runs straight into a ladder foot and straight out of a ladder top (a
		-- curve through the top landing bent the approach into the face)
		local bp = b.nd.piece
		if (bp and SG.VERT[bp.kind]) or (k + 1 == #nodes) then
			p3 = { b[1] + (b[1] - a[1]), b[2] + (b[2] - a[2]) }
		end
		if a.foot or k == 1 then
			p0 = { a[1] - (b[1] - a[1]), a[2] - (b[2] - a[2]) }
		end
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local len = sqrt(dx * dx + dz * dz)
		local n = max(2, ceil(len / 0.5))
		local dense = table.create(n + 1)
		for s = 0, n - 1 do
			dense[#dense + 1] = cr(p0, a, b, p3, s / n)
		end
		-- resample to STEP
		local seg = { dense[1] }
		local need, px, pz = STEP, dense[1][1], dense[1][2]
		for i = 2, #dense do
			local q = dense[i]
			local ex, ez = q[1] - px, q[2] - pz
			local L = sqrt(ex * ex + ez * ez)
			while L >= need do
				local f = need / L
				px, pz = px + ex * f, pz + ez * f
				seg[#seg + 1] = { px, pz }
				ex, ez = q[1] - px, q[2] - pz
				L = sqrt(ex * ex + ez * ez)
				need = STEP
			end
			need -= L
			px, pz = q[1], q[2]
		end
		-- heights: band segments (both ends have a design y + band) follow the contour at a linear grade; others
		-- follow the smoothed natural ground (+ dy) and are grade-clamped later
		-- design heights at both ends: linear grade (stairs, band ledges); band ledges also hug the contour
		local lin = a.yd and b.yd
		local band = lin and nd.band and b.nd.band
		local m = #seg
		-- a ledge leaving a ladder top starts at the top landing (cut deeper into the face than its contour) and
		-- blends onto the contour over 40 studs
		local lo, hi = nd.band and min(nd.band[1], (b.nd.band or nd.band)[1]), nd.band and max(nd.band[2], (b.nd.band or nd.band)[2])
		local delta = 0
		if band and a.foot then
			local r0 = sqrt(a[1] * a[1] + a[2] * a[2])
			local reTop = r0 + Gen.rwarp(a[1], a[2], r0)
			delta = reTop - SG.contourRe(Gen, math.atan2(a[1], a[2]), a[3] + (nd.cut or 4), lo, hi)
		end
		for i = 1, m do
			local f = (i - 1) / m
			local x, z = seg[i][1], seg[i][2]
			local y
			if lin then
				y = lerp(a[3], b[3], f)
			end
			if band and i > 1 then
				local th = math.atan2(x, z)
				local re = SG.contourRe(Gen, th, y + (nd.cut or 4), lo, hi)
				re += delta * max(0, 1 - (i - 1) * STEP / 40)
				x, z = Gen.toWorld(th, re)
			end
			push(x, z, y, t, w)
		end
	end
	nodeAt[#nodes] = #pts + 1
	local last = nodes[#nodes]
	push(last[1], last[2], last[3], "end", def.w or 4)

	-- band samples: smooth the contour-projected xz (bisection jitter, rib noise) without moving node samples
	local isNode = {}
	for _, i in pairs(nodeAt) do
		isNode[i] = true
	end
	for _ = 1, 2 do
		local o = table.create(#pts)
		for i = 1, #pts do
			-- v6: the 3 samples before a vertical piece's foot stay raw too (averaged with samples further back only,
			-- they kinked away from the fixed foot into the wall: buried approaches at inward ladders / pitches)
			if isNode[i] or SG.VERT[ty[i]] or SG.VERT[ty[i - 1]] or SG.VERT[ty[i + 1]] or SG.VERT[ty[i + 2]] or SG.VERT[ty[i + 3]] then
				o[i] = pts[i]
			else
				local sx, sz, c = 0, 0, 0
				for d = -4, 4 do
					local j = clamp(i + d, 1, #pts)
					if not SG.VERT[ty[j]] then
						sx += pts[j][1]
						sz += pts[j][2]
						c += 1
					end
				end
				o[i] = { sx / c, sz / c, pts[i][3] }
			end
		end
		pts = o
	end

	-- natural heights (+ node dy, linearly between the two nodes) where no design y was set
	local nodeIdx = {}
	for k, i in pairs(nodeAt) do
		nodeIdx[#nodeIdx + 1] = { k = k, i = i }
	end
	table.sort(nodeIdx, function(p, q)
		return p.i < q.i
	end)
	local raw = table.create(#pts)
	for i = 1, #pts do
		raw[i] = Gen.baseHeight(pts[i][1], pts[i][2])
	end
	for s = 1, #nodeIdx - 1 do
		local A, Bn = nodeIdx[s], nodeIdx[s + 1]
		local na, nb = nodes[A.k].nd, nodes[math.min(Bn.k, #nodes)].nd
		local dyA, dyB = na.dy or 0, nb.dy or 0
		for i = A.i, Bn.i - 1 do
			if not pts[i][3] then
				local f = (i - A.i) / max(1, Bn.i - A.i)
				-- smoothed ground +-12 studs
				local sum, c = 0, 0
				for d = -6, 6 do
					local j = i + d
					if j >= A.i and j < Bn.i then
						sum += raw[j]
						c += 1
					end
				end
				pts[i][3] = sum / c + lerp(dyA, dyB, f)
			end
		end
	end
	-- node samples carry the node's own y (pads, design heights)
	for k, i in pairs(nodeAt) do
		if pts[i] and nodes[k] then
			pts[i][3] = nodes[k][3]
		end
	end
	-- ladder tops: the sample after a ladder foot is the next node (top); make sure it is rise above the foot
	for _, pc in ipairs(pieces) do
		if SG.VERT[pc.kind] then
			local top = pts[pc.i + 1]
			if top then
				top[3] = pts[pc.i][3] + pc.rise
			end
		end
	end

	-- grade clamp on walking samples (pins: node samples and both ends of every ladder)
	local pin = {}
	for i in pairs(isNode) do
		pin[i] = true
	end
	for _, pc in ipairs(pieces) do
		if SG.VERT[pc.kind] then
			pin[pc.i], pin[pc.i + 1] = true, true
		end
	end
	local G = def.maxGrade or 0.6
	for _ = 1, 4 do
		for i = 2, #pts do
			if not pin[i] and not SG.VERT[ty[i - 1]] then
				local g = ((ty[i - 1] == "stair") and 1.0 or G) * STEP
				pts[i][3] = clamp(pts[i][3], pts[i - 1][3] - g, pts[i - 1][3] + g)
			end
		end
		for i = #pts - 1, 1, -1 do
			if not pin[i] and not SG.VERT[ty[i]] then
				local g = ((ty[i] == "stair") and 1.0 or G) * STEP
				pts[i][3] = clamp(pts[i][3], pts[i + 1][3] - g, pts[i + 1][3] + g)
			end
		end
	end

	-- arc length (horizontal), waypoints, worst grade per walking segment
	local S = table.create(#pts)
	S[1] = 0
	for i = 2, #pts do
		local ex, ez = pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2]
		S[i] = S[i - 1] + sqrt(ex * ex + ez * ez)
	end
	local wp = {}
	for k, nr in ipairs(nodes) do
		if nr.nd.name and nodeAt[k] then
			wp[nr.nd.name] = nodeAt[k]
		end
	end
	local worst, worstI = 0, 1
	for i = 2, #pts do
		local ds = S[i] - S[i - 1]
		if ds > 0.5 and not SG.VERT[ty[i - 1]] then
			local g = abs(pts[i][3] - pts[i - 1][3]) / ds
			if g > worst then
				worst, worstI = g, i
			end
		end
	end
	return {
		name = def.name,
		def = def,
		v5 = true,
		pts = pts,
		S = S,
		ty = ty,
		w = wd,
		dp = dp,
		pieces = pieces,
		wp = wp,
		nodeAt = nodeAt,
		worstGrade = worst,
		warn = warn,
		worstGradeS = S[worstI],
	}
end

-- outward unit normal (x, z) at sample i: perpendicular to the trail, on the side away from the summit axis
function SG.normal(R, i)
	local pts, ty = R.pts, R.ty
	-- v6: never across a vertical piece (the first sample on a top landing took its tangent from the ledge below and
	-- turned its cross-section 90 deg: its wall buried the approach to the piece's foot)
	local a0, b0 = max(1, i - 2), min(#pts, i + 2)
	if ty then
		for j = i - 1, a0, -1 do
			if SG.VERT[ty[j]] then
				a0 = j + 1
				break
			end
		end
		for j = i, b0 - 1 do
			if SG.VERT[ty[j]] then
				b0 = j
				break
			end
		end
		if b0 <= a0 then
			a0, b0 = max(1, i - 2), min(#pts, i + 2)
		end
	end
	local a, b = pts[a0], pts[b0]
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local L = sqrt(dx * dx + dz * dz)
	if L < 1e-3 then
		return 1, 0, 0, 1
	end
	dx, dz = dx / L, dz / L
	local nx, nz = dz, -dx
	local p = pts[i]
	if nx * p[1] + nz * p[2] < 0 then
		nx, nz = -nx, -nz
	end
	return nx, nz, dx, dz
end

local function reachOf(t)
	return (t == "gap") and 10 or 18
end

-- cross-section stamp into the field (call after water / chasm carving). For each cell within reach of the route,
-- the nearest sample (perpendicular distance) defines the trail height, type, width and signed offset.
-- F_.TR (u8): 1 = tread cell (trail material), 2 = tread edge over a drop (marked rock: the descend grab catches a
-- walker who steps off), written for MountainGen's surface pass.
function SG.stamp(F_, R, Gen)
	local H = F_.H
	local N, HALF, CELL = Gen.N, Gen.HALF, Gen.CELL
	local cellC = Gen.cellC
	F_.TR = F_.TR or buffer.create(N * N)
	local TR = F_.TR
	local REACH = 30
	local best = {} -- idx -> { dist, d, y, t, w, i, drop }
	local treadClaim = {}
	local pts, ty, wd, dpa = R.pts, R.ty, R.w, R.dp or {}
	local LEDGEY = { ledge = true, jump = true, traverse = true }
	for i = 1, #pts do
		local t = ty[i]
		if t == "end" then
			t = ty[i - 1] or "open"
		end
		local p = pts[i]
		local y = p[3]
		local nx, nz, tx, tz = SG.normal(R, i)
		local ahead = SG.STEP * 0.75 + 0.01
		-- v6: a sample spaced wider than STEP from the next (a top landing, contour re-projection) claims up to it (a
		-- 5-stud gap after the ladder-1 landing left an unclaimed cell that became a 7-high wall bump)
		local nq = pts[i + 1]
		if nq and not SG.VERT[t] then
			local gx, gz = nq[1] - p[1], nq[2] - p[2]
			ahead = max(ahead, sqrt(gx * gx + gz * gz) - 1)
		end
		local stepsDown = false
		if t == "steps" and pts[i + 1] then
			-- steps: blocks from the foot to the top landing; the floor under them is the lower end's height (the
			-- blocks are the only way up or down), in the foot -> top direction
			local q = pts[i + 1]
			local ex, ez = q[1] - p[1], q[2] - p[2]
			local L = math.max(1e-3, sqrt(ex * ex + ez * ez))
			tx, tz = ex / L, ez / L
			nx, nz = tz, -tx
			if nx * p[1] + nz * p[2] < 0 then
				nx, nz = -nx, -nz
			end
			-- the last 3 studs belong to the top landing (up) / the first stud stays the rim (down)
			ahead = (q[3] > p[3]) and (L - 3) or (L - 1.5)
			y = min(p[3], q[3])
			stepsDown = q[3] < p[3]
		elseif SG.VERT[t] and i > 3 then
			-- ladder / pitch / chimney foot: incoming direction only (the next sample is the top landing, often
			-- inward), and the ledge runs 6 studs past the foot (a walker overshooting the foot stepped off the end)
			local q = pts[i - 3]
			local ex, ez = p[1] - q[1], p[2] - q[2]
			local L = math.max(1e-3, sqrt(ex * ex + ez * ez))
			tx, tz = ex / L, ez / L
			nx, nz = tz, -tx
			if nx * p[1] + nz * p[2] < 0 then
				nx, nz = -nx, -nz
			end
			ahead = 6
			-- inward pieces (the top landing is nearer the axis): the upper ledge runs on right above the ground past
			-- the foot, so the lower ledge stops 3 past it (its 6-stud overshoot won those cells and holed the upper
			-- ledge down to the tier below, the tall ladder, v6)
			local q1 = pts[i + 1]
			if q1 and sqrt(q1[1] * q1[1] + q1[2] * q1[2]) < sqrt(p[1] * p[1] + p[2] * p[2]) - 4 then
				ahead = 3
			end
		end
		local reach = (t == "open") and 26 or REACH
		local i0 = max(0, floor((p[1] - reach + HALF) / CELL))
		local i1 = min(N - 1, floor((p[1] + reach + HALF) / CELL))
		local j0 = max(0, floor((p[2] - reach + HALF) / CELL))
		local j1 = min(N - 1, floor((p[2] + reach + HALF) / CELL))
		for j = j0, j1 do
			local cz = cellC(j) - p[2]
			for ii = i0, i1 do
				local cx = cellC(ii) - p[1]
				local along = cx * tx + cz * tz
				-- a ladder / pitch / chimney top landing also claims back across the whole face width (a climber topping
				-- out off-centre had cliff above the head: no mantle, chimney v6)
				local topBack = i > 1 and SG.VERT[ty[i - 1]] and ty[i - 1] ~= "steps"
				local behind = stepsDown and 1 or (topBack and -((wd[i] or 4) / 2 + 5)) or -(SG.STEP * 0.75 + 0.01)
				if (along >= behind and along <= ahead) or (i == 1 and along < 0) or (i == #pts and along > 0) then
					local d = cx * nx + cz * nz
					local dist = abs(d) + abs(along) * 0.25
					if dist <= reach then
						local idx = j * N + ii
						local b = best[idx]
						local e = { dist, d, y, t, wd[i] or 4, i, dpa[i] }
						if not b or dist < b[1] then
							best[idx] = e
						end
						-- tread claims win over walls / drops of other samples (two arms of a ledge pass close at a
						-- ladder turn: the lower arm's wall must not bury the upper arm's footing)
						local hw_ = (wd[i] or 4) / 2
						if math.abs(d) <= hw_ + SG.EDGE and t ~= "gap" and t ~= "log" and t ~= "ford" and t ~= "open" and t ~= "jump" and t ~= "traverse" then
							local c = treadClaim[idx]
							if not c or math.abs(d) < math.abs(c[2]) then
								treadClaim[idx] = e
							end
						end
					end
				end
			end
		end
		if i % 400 == 0 then
			task.wait()
		end
	end
	local n = 0
	for idx, c in pairs(treadClaim) do
		best[idx] = c
	end
	for idx, b in pairs(best) do
		local d, y, t, w = b[2], b[3], b[4], b[5]
		local DROP = b[7] or SG.DROP
		local hw = w / 2
		local h = readf32(H, idx * 4)
		local ad = abs(d)
		local tread = y - SG.SINK
		local nh = h
		if t == "log" or t == "ford" then
			-- nothing: the creek / pond and its banks stay as written
		elseif SG.VERT[t] then
			-- the foot sample: its own cells are the landing at the foot (steps: the floor under the blocks); the face
			-- comes from the next (top) sample
			if ad <= hw + ((t == "steps") and 2.5 or 1.5) then
				nh = tread
				writeu8(TR, idx, 1)
			end
		elseif t == "open" then
			local k = smoothstep(hw + 1, hw + 18, ad)
			nh = lerp(tread, h, k)
			if ad <= hw + 1 then
				writeu8(TR, idx, 1)
			end
		elseif t == "rim" or t == "path" then
			-- v6: tread only; the banks are trimmed where they stand above the tread (6-stud blend) but never filled, so
			-- a gorge, slot or falls edge beside the line keeps its drop
			if ad <= hw + SG.EDGE then
				nh = tread
				writeu8(TR, idx, 1)
			elseif h > tread then
				nh = lerp(tread, h, smoothstep(0, 6, ad - hw - SG.EDGE))
			end
		elseif ad <= hw + SG.EDGE then
			nh = tread
			if t == "gap" or t == "jump" or t == "traverse" then
				-- (v6: jump gaps and hand traverses are open in the field itself, so the voxel writer keeps the cliff's
				-- columns solid around them; a 40-deep FillBlock carve punched through the terrain shell)
				nh = min(h, y - math.max(SG.GAP, DROP))
			else
				writeu8(TR, idx, 1)
				local outerDrop = (LEDGEY[t] and d > 0) or t == "ridge"
				if SG.MARK_EDGES and outerDrop and ad > hw - 2.5 then
					writeu8(TR, idx, 2)
				end
			end
		else
			local e = ad - hw - SG.EDGE -- distance past the tread edge
			local outer = d > 0
			local wall = (t == "slot") or (LEDGEY[t] and not outer) or (t == "stair")
			local drop = (t == "ridge") or (LEDGEY[t] and outer) or (t == "gap")
			if wall and e < SG.WALL_GAP then
				-- the wall foot stays back WALL_GAP studs: voxel rock bulges ~2 proud and nudged walkers off the edge
				nh = tread
				writeu8(TR, idx, 1)
			elseif wall then
				-- wall: at least WALL above the tread for 5 studs, then back to the terrain (steep, >= 50 deg)
				local top = y + SG.WALL + 2
				local tgt = (e < 5 + SG.WALL_GAP) and top or lerp(top, h, smoothstep(5 + SG.WALL_GAP, 14 + SG.WALL_GAP, e))
				nh = max(h, tgt)
			elseif drop then
				-- drop: DROP below the edge (node drop = exposure), falling away at 1.6:1, back to the terrain only if
				-- that is lower; a short shoulder first: a drop right at a 1-2 voxel ledge renders a rounded, tilted
				-- edge (walkers slid off)
				local cut = (e < SG.SHOULDER and t ~= "gap") and (y - 1.5) or (y - DROP - (e - SG.SHOULDER) * 1.6)
				local rf = reachOf(t) + ((DROP > SG.DROP) and 6 or 0)
				local tgt = lerp(cut, h, smoothstep(rf, rf + 6, e))
				nh = min(h, tgt)
			end
		end
		if nh ~= h then
			writef32(H, idx * 4, nh)
			n += 1
		end
	end
	return n
end

-- v6: creek gorge. spec = { th0, th1, depth, hw, wall, taper = { a, b }, rLo, rHi }: every water cell of the creek
-- between th0 and th1 (and rLo..rHi) is a gorge centre; cells within hw of a centre are lowered to that centre's water
-- level - depth (taper: depth ramps from 0 at theta a to full at theta b), the next `wall` studs blend steeply back
-- (near-vertical walls), and the stream runs 1 deep on the gorge floor over the old water cells. Run after
-- the water pass and before route stamps (the route's crossing pieces stand on the gorge floor).
function SG.gorge(F_, Gen, spec)
	local H, W = F_.H, F_.W
	local N, HALF, CELL = Gen.N, Gen.HALF, Gen.CELL
	local cellC = Gen.cellC
	local centres = {}
	local rLo, rHi = spec.rLo or 0, spec.rHi or 1e9
	-- scan the box of the arc for water cells
	local i0, i1, j0, j1 = N, 0, N, 0
	for _, th in ipairs({ spec.th0, spec.th1, (spec.th0 + spec.th1) / 2 }) do
		for _, r in ipairs({ rLo, rHi }) do
			local x, z = r * math.sin(th), r * math.cos(th)
			i0, i1 = min(i0, floor((x + HALF) / CELL)), max(i1, floor((x + HALF) / CELL))
			j0, j1 = min(j0, floor((z + HALF) / CELL)), max(j1, floor((z + HALF) / CELL))
		end
	end
	local pad = ceil((spec.hw + spec.wall) / CELL) + 1
	i0, i1, j0, j1 = max(0, i0 - pad), min(N - 1, i1 + pad), max(0, j0 - pad), min(N - 1, j1 + pad)
	for j = j0, j1 do
		for i = i0, i1 do
			local idx = j * N + i
			local w = readf32(W, idx * 4)
			local h = readf32(H, idx * 4)
			if w > -1000 and w > h + 0.2 then
				local x, z = cellC(i), cellC(j)
				local th, r = math.atan2(x, z), sqrt(x * x + z * z)
				if th >= spec.th0 and th <= spec.th1 and r >= rLo and r <= rHi then
					local dep = spec.depth
					if spec.taper then
						dep *= smoothstep(spec.taper[1], spec.taper[2], th)
					end
					centres[#centres + 1] = { x, z, w, dep }
				end
			end
		end
	end
	local reach = spec.hw + spec.wall
	local newH, newW = {}, {}
	for _, c in ipairs(centres) do
		local ci0, ci1 = max(0, floor((c[1] - reach + HALF) / CELL)), min(N - 1, floor((c[1] + reach + HALF) / CELL))
		local cj0, cj1 = max(0, floor((c[2] - reach + HALF) / CELL)), min(N - 1, floor((c[2] + reach + HALF) / CELL))
		local floorY = c[3] - 1 - c[4]
		for j = cj0, cj1 do
			local dz = cellC(j) - c[2]
			for i = ci0, ci1 do
				local dx = cellC(i) - c[1]
				local dd = sqrt(dx * dx + dz * dz)
				if dd <= reach then
					local idx = j * N + i
					local h = readf32(H, idx * 4)
					local tgt = (dd <= spec.hw) and floorY or lerp(floorY, h, smoothstep(spec.hw, reach, dd))
					if not newH[idx] or tgt < newH[idx] then
						newH[idx] = tgt
					end
					if dd <= 0.5 and c[4] > 0.5 then
						local wl = floorY + 1
						if not newW[idx] or wl < newW[idx] then
							newW[idx] = wl
						end
					end
				end
			end
		end
	end
	local n = 0
	for idx, v in pairs(newH) do
		if v < readf32(H, idx * 4) then
			writef32(H, idx * 4, v)
			n += 1
		end
		local w = readf32(W, idx * 4)
		if newW[idx] then
			writef32(W, idx * 4, newW[idx])
		elseif w > -1000 and w > v + 0.2 then
			-- old creek water above the new floor and outside the stream: removed
			writef32(W, idx * 4, -10000)
		end
	end
	return { centres = #centres, cells = n }
end

-- audit data for tools/spline_audit.py (segments merged by type / width / heading)
function SG.auditJson(R, hazards, rests)
	local segs = {}
	local pts, ty, wd, S = R.pts, R.ty, R.w, R.S
	local cur
	for i = 1, #pts - 1 do
		local t = ty[i]
		local dx, dz = pts[i + 1][1] - pts[i][1], pts[i + 1][2] - pts[i][2]
		local dir = math.deg(math.atan2(dx, dz)) % 360
		local len = S[i + 1] - S[i]
		local turn = cur and abs((dir - cur.dir0 + 180) % 360 - 180) or 0
		if cur and cur.type == t and cur.width == wd[i] and turn < 25 then
			cur.length += len
			cur.dir = dir
		else
			cur = { type = t, width = SG.VERT[t] and 2 or wd[i], length = len, open = (t == "open"), dir = dir, dir0 = dir }
			segs[#segs + 1] = cur
		end
	end
	for _, s in ipairs(segs) do
		s.dir0 = nil
	end
	return { segments = segs, hazards = hazards or {}, rests = rests or {} }
end

return SG
