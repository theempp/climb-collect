-- SplineKit (v5 P1, 2026-10-21): world pieces for a v5 spline route (after the terrain is written).
--   SplineKit.build(Kit, Gen, name)  -> report string. Rebuild-safe: replaces Workspace.World.Routes.<name>, its
--   checkpoint triggers (Route = name) and ReplicatedStorage.CC_Track.<name>.
-- Pieces: tread parts on every tight segment (crisp 2-5 stud edges; the terrain under them sits 1.1 lower), rope
-- rails on drops (rail = "rope"), ladders (steel rails + rungs + an invisible Climbable grip, rock face behind),
-- boulder-stair blocks, log / rope bridges over gap segments, cleft boulders, rests (pavilion low / tent mid-high:
-- RestZone + checkpoint), cairns (terrain + checkpoint), guide flags (GuideOrder for CC_ClimbClient's Guide).
-- Colours: design/v5-tokens.md only (references-intel swatches). Placements PROPOSED.
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local T = workspace.Terrain
local MARK = Enum.Material.Asphalt -- CoreConfig.CLIMB.terrainMaterial: marked (climbable) rock
local SK = {}

local function hex(h)
	return Color3.fromRGB(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16))
end
SK.COL = {
	dirtPath = hex("#8a5a3a"),
	gullyRock = hex("#6e7273"),
	moss = hex("#6d6a3f"),
	fogRock = hex("#7d8079"),
	snowRock = hex("#4a4d52"),
	snowLit = hex("#e0e3e6"),
	rope = hex("#a86a2e"),
	ropeBright = hex("#d9722a"),
	darkWood = hex("#4a2d22"),
	lakeMoss = hex("#a9b83a"),
	tentRed = hex("#b0221d"),
	ladderStrip = hex("#e0a21e"),
}
local COL = SK.COL
local UP = Vector3.yAxis

local function V(p)
	return Vector3.new(p[1], p[3], p[2])
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- tread look by altitude (references: img3 dirt low, img3 rock mid, img4 dark rock high)
local function treadLook(y)
	if y < 1100 then
		return Enum.Material.Ground, COL.dirtPath
	elseif y < 1900 then
		return Enum.Material.Slate, COL.gullyRock
	end
	return Enum.Material.Slate, COL.snowRock
end

function SK.build(Kit, Gen, name)
	local P = _G.CC_PATHS
	local R = P.routes[name]
	assert(R and R.v5, "not a v5 route: " .. tostring(name))
	local SG = require(script.Parent.SplineGen)
	local def = R.def
	local pts, ty, wd, S = R.pts, R.ty, R.w, R.S
	local n = #pts
	local root = Kit.folder(Kit.folder(workspace, "World"), "Routes")
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Kit.folder(root, name)
	local cps = Kit.folder(Kit.folder(workspace, "World"), "Checkpoints")
	for _, t in ipairs(cps:GetChildren()) do
		if t:GetAttribute("Route") == name then
			t:Destroy()
		end
	end
	local cnt = { tread = 0, rail = 0, ladders = 0, stair = 0, bridges = 0, rests = 0, cairns = 0, flags = 0, cleft = 0 }
	local function P_(parent, props)
		return Kit.part(parent, props)
	end
	local function D_(parent, props)
		return Kit.decor(Kit.part(parent, props))
	end
	local function outward(i)
		local nx, nz, tx, tz = SG.normal(R, i)
		return Vector3.new(nx, 0, nz), Vector3.new(tx, 0, tz)
	end

	------------------------------------------------ tread parts: OFF by default (user 2026-10-21: the trail is the
	-- mountain's own rock / earth, no plank or flooring layer); def.treadParts = true brings the old layer back
	local tf = Kit.folder(f, "Tread")
	local TREAD = def.treadParts and { ledge = true, slot = true, ridge = true } or {}
	local i = 1
	while i < n do
		local t = ty[i]
		if TREAD[t] then
			-- grow the run while the heading and grade stay close and the run is <= 14 studs
			local a = V(pts[i])
			local j = i + 1
			local d0 = flat(V(pts[j]) - a).Unit
			local g0 = (pts[j][3] - pts[i][3]) / math.max(0.1, S[j] - S[i])
			while j < n and ty[j] == t and wd[j] == wd[i] and S[j + 1] - S[i] <= 14 do
				local dj = flat(V(pts[j + 1]) - V(pts[j]))
				if dj.Magnitude < 0.05 then
					break
				end
				local gj = (pts[j + 1][3] - pts[j][3]) / math.max(0.1, S[j + 1] - S[j])
				if dj.Unit:Dot(d0) < 0.995 or math.abs(gj - g0) > 0.06 then
					break
				end
				j += 1
			end
			local b = V(pts[j])
			local len = (b - a).Magnitude
			if len > 0.2 then
				local mat, col = treadLook(a.Y)
				local w = wd[i] or 4
				local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.8, 0)
				local p = P_(tf, { Name = "Tread", Size = Vector3.new(w, 1.6, len + 0.6), CFrame = cf, Material = mat, Color = col })
				p.CastShadow = false
				cnt.tread += 1
			end
			i = j
		else
			i += 1
		end
	end

	------------------------------------------------ rope rails on drops (outer side; ridges both sides)
	if def.rail == "rope" then
		local rf = Kit.folder(f, "Rails")
		local function railRun(side)
			local run = {}
			local function flush()
				if #run >= 4 then
					local m = Kit.model(rf, "RopeRail")
					local last
					for k = 1, #run do
						if k == 1 or k == #run or (run[k].s - run[1].s) % 20 < 2.1 then
							local q = run[k].p
							D_(m, { Name = "Post", Size = Vector3.new(0.45, 4, 0.45), CFrame = CFrame.new(q + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Wood, Color = COL.darkWood })
							if last then
								local A, B = last + Vector3.new(0, 3.2, 0), q + Vector3.new(0, 3.2, 0)
								D_(m, { Name = "Rope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((B - A).Magnitude + 0.1, 0.28, 0.28), CFrame = CFrame.lookAt((A + B) / 2, B) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.rope })
							end
							last = q
						end
					end
					cnt.rail += 1
				end
				run = {}
			end
			for k = 3, n - 3, 1 do
				local t = ty[k]
				local want = (t == "ridge") or (t == "ledge" and side > 0)
				if want then
					local o = outward(k)
					local p = V(pts[k])
					local e = p + o * side * ((wd[k] or 4) / 2 - 0.35)
					local far = p + o * side * ((wd[k] or 4) / 2 + 4)
					local drop = p.Y - Gen.heightAt(far.X, far.Z)
					if drop > 5 then
						run[#run + 1] = { p = e, s = S[k] }
						if S[k] - run[1].s > 60 then
							local keep = run[#run]
							flush()
							run[1] = keep
						end
					else
						flush()
					end
				else
					flush()
				end
			end
			flush()
		end
		railRun(1)
		railRun(-1)
	end

	------------------------------------------------ pieces
	local pf = Kit.folder(f, "Pieces")
	local track = {}
	local order = 0
	local cpOrder = 0
	local function trigger(key, pos, label, camp)
		cpOrder += 1
		local t = Instance.new("Part")
		t.Name = "CP_" .. name .. "_" .. key
		t.Anchored, t.CanCollide, t.CanQuery = true, false, false
		t.Transparency = 1
		t.Size = Vector3.new(16, 14, 16)
		t.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
		for k, v in pairs({ Checkpoint = name .. "_" .. key, Label = label, Route = name, Order = cpOrder, Camp = false }) do
			t:SetAttribute(k, v)
		end
		t.Parent = cps
		return t
	end
	local function flag(pos, o)
		order += 1
		local m = Kit.model(pf, "GuideFlag_" .. order)
		local g = Vector3.new(pos.X, pos.Y, pos.Z)
		D_(m, { Name = "Pole", Size = Vector3.new(0.3, 6, 0.3), CFrame = CFrame.new(g + Vector3.new(0, 3, 0)), Material = Enum.Material.Wood, Color = COL.darkWood })
		local fl = D_(m, { Name = "GuideFlag", Size = Vector3.new(0.12, 1.3, 2.2), CFrame = CFrame.lookAt(g + Vector3.new(0, 5.3, 0) + o * 1.1, g + Vector3.new(0, 5.3, 0) + o * 1.1 + o:Cross(UP)), Material = Enum.Material.Fabric, Color = COL.ladderStrip })
		fl:SetAttribute("GuideOrder", order)
		fl:SetAttribute("GuideRoute", name)
		cnt.flags += 1
		return fl
	end
	local restN, cairnN = 0, 0
	local rests = {}
	for _, pc in ipairs(R.pieces) do
		local k = math.clamp(pc.i, 1, n)
		local p = V(pts[k])
		local o, dir = outward(k)
		local w = wd[k] or 4
		local spec = pc.spec or {}
		if pc.kind == "ladder" then
			-- foot sample k, top = k + 1. Face: a rock block from just past the ladder up to the top landing.
			local top = V(pts[k + 1])
			local d = flat(top - p).Unit
			local rise = top.Y - p.Y
			local lm = Kit.model(pf, "Ladder_" .. k)
			-- ladder plane: 1.2 ahead of the foot, or at the inner tread edge for an inward ladder (the trail turns at it)
			local off = spec.inward and (w / 2 - 0.2) or 1.2
			local base = p + d * off
			-- the face block reaches from just behind the ladder to the top landing (inward turns run ~w + 4)
			local FACE_OFF = 3 -- rock face 3 behind the ladder plane: rendered voxels bulge ~2 proud (v4: 3.6)
			local faceD = math.max(4.4, flat(top - p).Magnitude - off - FACE_OFF + 2)
			-- the block's top is the rock landing at the top of the ladder (no landing plank, user 2026-10-21)
			local faceC = base + d * (FACE_OFF + faceD / 2) + Vector3.new(0, (rise + 1.8) / 2 - 2, 0)
			T:FillBlock(CFrame.lookAt(faceC, faceC + d), Vector3.new(w + 6, rise + 1.8, faceD), Enum.Material.Rock)
			-- clear rock between the foot and the ladder plane (rendered voxels bulge, CLAUDE.md gotcha)
			local airC = p + d * (off + FACE_OFF / 2 - 1) + Vector3.new(0, rise / 2 + 2.5, 0)
			T:FillBlock(CFrame.lookAt(airC, airC + d), Vector3.new(w + 2, rise + 3, FACE_OFF + 2), Enum.Material.Air)
			local right = d:Cross(UP)
			local H = rise + 3.2
			for _, sg in ipairs({ -1, 1 }) do
				D_(lm, { Name = "Rail", Size = Vector3.new(0.3, H, 0.3), CFrame = CFrame.new(base + right * 1.2 * sg + Vector3.new(0, H / 2, 0)), Material = Enum.Material.Metal, Color = COL.snowRock })
			end
			for y = 1, H - 0.5, 2 do
				D_(lm, { Name = "Rung", Size = Vector3.new(2.4, 0.2, 0.2), CFrame = CFrame.lookAt(base + Vector3.new(0, y, 0), base + Vector3.new(0, y, 0) + d), Material = Enum.Material.Metal, Color = COL.snowRock })
			end
			-- grip ends 1 above the top: the controller mantles only when nothing is in front of the head
			local GH = rise + 1
			local gc = base + d * 0.3 + Vector3.new(0, GH / 2, 0)
			local grip = P_(lm, { Name = "LadderGrip", Size = Vector3.new(6, GH, 0.4), CFrame = CFrame.lookAt(gc, gc - d), Transparency = 1, Material = Enum.Material.SmoothPlastic })
			grip.CastShadow = false
			grip:SetAttribute("Climbable", true)
			flag(top + d * 3 + d:Cross(UP) * (w / 2 + 0.6), o)
			cnt.ladders += 1
			track[#track + 1] = {
				id = "L" .. k,
				s0 = S[math.max(1, k - 3)],
				s1 = S[math.min(n, k + 4)],
				-- approach along the trail (an inward ladder turns the trail: "behind the foot" is off the ledge), leave
				-- along the trail past the top landing
				nodes = {
					{ k = "walk", p = { pts[math.max(1, k - 3)][1], pts[math.max(1, k - 3)][3] + 3, pts[math.max(1, k - 3)][2] } },
					{ k = "walk", p = { p.X, p.Y + 3, p.Z } },
					{ k = "climb", into = { d.X, 0, d.Z }, label = "L" .. k },
					{ k = "walk", p = { pts[math.min(n, k + 4)][1], pts[math.min(n, k + 4)][3] + 3, pts[math.min(n, k + 4)][2] } },
				},
			}
		elseif pc.kind == "rest" then
			restN += 1
			-- platform on the outer side (pavilion: stilts + roof, low band; tent: small A-frame, mid/high)
			local c = p + o * (w / 2 + 4)
			local rm = Kit.model(pf, "Rest_" .. restN)
			local deckY = p.Y
			local deckCF = CFrame.lookAt(Vector3.new(c.X, deckY - 0.6, c.Z), Vector3.new(c.X, deckY - 0.6, c.Z) + dir)
			P_(rm, { Name = "Deck", Size = Vector3.new(8, 1.2, 10), CFrame = deckCF, Material = Enum.Material.WoodPlanks, Color = COL.darkWood })
			if spec.style == "pavilion" then
				for _, q in ipairs({ { -3.5, -4.5 }, { 3.5, -4.5 }, { -3.5, 4.5 }, { 3.5, 4.5 } }) do
					local pp = (deckCF * CFrame.new(q[1], 0, q[2])).Position
					local gy = Gen.heightAt(pp.X, pp.Z)
					local top = deckY + 7
					local bot = math.min(gy, deckY - 1) - 1
					P_(rm, { Name = "Post", Size = Vector3.new(0.7, top - bot, 0.7), CFrame = CFrame.new(pp.X, (top + bot) / 2, pp.Z), Material = Enum.Material.Wood, Color = COL.darkWood })
				end
				P_(rm, { Name = "Roof", Size = Vector3.new(9.5, 0.6, 11.5), CFrame = deckCF * CFrame.new(0, 7.6, 0) * CFrame.Angles(math.rad(6), 0, 0), Material = Enum.Material.WoodPlanks, Color = COL.darkWood })
			else
				local tc = deckCF * CFrame.new(0, 0.6, 1.5)
				for _, sg in ipairs({ -1, 1 }) do
					D_(rm, { Name = "Tent", Size = Vector3.new(0.3, 4.6, 6), CFrame = tc * CFrame.new(sg * 1.55, 2, 0) * CFrame.Angles(0, 0, math.rad(-sg * 34)), Material = Enum.Material.Fabric, Color = COL.tentRed })
				end
			end
			local z = P_(rm, { Name = "RestZone", Size = Vector3.new(10, 8, 12), CFrame = deckCF * CFrame.new(0, 4, 0), Transparency = 1 })
			z.CanCollide, z.CanQuery, z.CanTouch, z.CastShadow = false, false, false, false
			z:SetAttribute("RestZone", true)
			trigger("R" .. restN, p, (spec.style == "pavilion") and "Pavilion rest" or "Tent rest")
			flag(p + o * (w / 2 + 0.6) - dir * 2, o)
			rests[#rests + 1] = { at = S[k] - 10, len = 30 }
			cnt.rests += 1
		elseif pc.kind == "cairn" then
			cairnN += 1
			local c = p - o * (w / 2 + 1.8)
			local gy = math.max(Gen.heightAt(c.X, c.Z), p.Y - 1)
			for s = 0, 3 do
				T:FillBall(Vector3.new(c.X, gy + 0.8 + s * 1.5, c.Z), 1.5 - s * 0.25, Enum.Material.Slate)
			end
			trigger("C" .. cairnN, p, "Cairn")
			flag(Vector3.new(c.X, gy + 5.5, c.Z), o)
			cnt.cairns += 1
		elseif pc.kind == "log" or pc.kind == "ropebridge" then
			-- span the gap segment from its first sample to the next node
			local k1 = k
			while k1 < n and (ty[k1] == "gap" or ty[k1] == "log") do
				k1 += 1
			end
			local a = V(pts[math.max(1, k - 1)])
			local b = V(pts[k1])
			local L = (b - a).Magnitude
			local bm = Kit.model(pf, (pc.kind == "log") and "Log" or "RopeBridge")
			local cf = CFrame.lookAt((a + b) / 2, b)
			if pc.kind == "log" then
				D_(bm, { Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(L + 4, 3.2, 3.2), CFrame = cf * CFrame.new(0, -1.6, 0) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Wood, Color = COL.darkWood })
				D_(bm, { Name = "Moss", Size = Vector3.new(1.6, 0.25, L * 0.6), CFrame = cf * CFrame.new(0.4, 0.02, 0), Material = Enum.Material.Grass, Color = COL.lakeMoss })
				P_(bm, { Name = "LogWalk", Size = Vector3.new(2.6, 0.6, L + 5), CFrame = cf * CFrame.new(0, -0.3, 0), Transparency = 1 }).CastShadow = false
			else
				P_(bm, { Name = "Planks", Size = Vector3.new(3.2, 0.5, L + 2), CFrame = cf * CFrame.new(0, -0.25, 0), Material = Enum.Material.WoodPlanks, Color = COL.darkWood })
				local right = cf.RightVector
				for _, sg in ipairs({ -1, 1 }) do
					local A, B = a + right * 1.9 * sg + Vector3.new(0, 3, 0), b + right * 1.9 * sg + Vector3.new(0, 3, 0)
					D_(bm, { Name = "Handrope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((B - A).Magnitude, 0.3, 0.3), CFrame = CFrame.lookAt((A + B) / 2, B) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.rope })
					for _, e in ipairs({ a, b }) do
						P_(bm, { Name = "Post", Size = Vector3.new(0.6, 4.2, 0.6), CFrame = CFrame.new(e + right * 1.9 * sg + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Wood, Color = COL.darkWood })
					end
				end
			end
			cnt.bridges += 1
		elseif pc.kind == "cleft" then
			-- boulders + leaning slabs at the slot sides (img3), moss tops; never on the tread line
			local cm = Kit.model(pf, "Cleft_" .. k)
			for q = 0, 5 do
				local kk = math.min(n, k + q * 6)
				local pq = V(pts[kk])
				local oq = outward(kk)
				local sd = (q % 2 == 0) and 1 or -1
				local bp = pq + oq * sd * ((wd[kk] or 4) / 2 + 2.6)
				local sz = Vector3.new(3.5 + (q % 3), 5 + (q % 2) * 3, 4 + (q % 2))
				P_(cm, { Name = "Boulder", Size = sz, CFrame = CFrame.new(bp + Vector3.new(0, sz.Y / 2 - 1.5, 0)) * CFrame.Angles(0.15 * sd, q * 0.9, 0.12), Material = Enum.Material.Rock, Color = COL.gullyRock })
				D_(cm, { Name = "Moss", Size = Vector3.new(sz.X * 0.8, 0.3, sz.Z * 0.8), CFrame = CFrame.new(bp + Vector3.new(0, sz.Y - 1.35, 0)) * CFrame.Angles(0.15 * sd, q * 0.9, 0.12), Material = Enum.Material.Grass, Color = COL.moss })
			end
			cnt.cleft += 1
		elseif pc.kind == "stairs" then
			cnt.stair += 1 -- blocks below
		elseif pc.kind == "pitch" or pc.kind == "chimney" then
			-- v6: a marked rock face (terrain Asphalt = climbable, CoreConfig.CLIMB.terrainMaterial) from the foot up to the
			-- top landing; chimney = the same face between two rock side walls. Cue: a fixed rope down one side.
			local top = V(pts[k + 1])
			local d = flat(top - p).Unit
			local rise = top.Y - p.Y
			local pm = Kit.model(pf, (pc.kind == "chimney" and "Chimney_" or "Pitch_") .. k)
			local off = spec.inward and (w / 2 - 0.2) or 1.2
			local base = p + d * off
			-- face front this far behind the grab plane; the face fill (after the air clear) overlaps the clear's far end, so
			-- the marked rock wins the shared voxels (FRONT 1.4 left natural rock in front where a gorge wall stood close).
			-- Chimney: the face stands 2.5 back in a 10-wide recess cut into the cliff, whose own rock is the slot's sides
			-- (built side walls rasterized wider than their boxes and wedged the climber, v6)
			local FRONT = (pc.kind == "chimney") and 2.5 or 0.6
			local faceD = math.max(4.4, flat(top - p).Magnitude - off - FRONT + 2)
			local faceC = base + d * (FRONT + faceD / 2) + Vector3.new(0, (rise + 1.8) / 2 - 2, 0)
			local fw = (pc.kind == "chimney") and 11 or (w + 6)
			local clearD = FRONT + 3
			-- clear from 1 above the foot to 10 above the top (a recess roofed by the cliff above its top blocked the mantle)
			local clearH = rise + ((pc.kind == "chimney") and 10 or 3)
			local airC = p + d * (off + FRONT - clearD / 2) + Vector3.new(0, 1 + clearH / 2, 0)
			T:FillBlock(CFrame.lookAt(airC, airC + d), Vector3.new(fw - 1, clearH, clearD), Enum.Material.Air)
			T:FillBlock(CFrame.lookAt(faceC, faceC + d), Vector3.new(fw, rise + 1.8, faceD), MARK)
			local right = d:Cross(UP)
			-- fixed rope (cue only): anchored at the top edge, hanging down the face's right side
			local rx = right * ((pc.kind == "chimney") and 1.6 or (fw / 2 - 1.2))
			local A_ = base + d * (FRONT - 0.3) + rx + Vector3.new(0, rise + 1.2, 0)
			local B_ = base + d * (FRONT - 0.5) + rx + Vector3.new(0, 1.2, 0)
			D_(pm, { Name = "FixedRope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((A_ - B_).Magnitude, 0.25, 0.25), CFrame = CFrame.lookAt((A_ + B_) / 2, A_) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.ropeBright })
			for _, q in ipairs({ A_, B_:Lerp(A_, 0.5) }) do
				D_(pm, { Name = "Piton", Size = Vector3.new(0.5, 0.5, 0.9), CFrame = CFrame.lookAt(q - d * 0.2, q + d), Material = Enum.Material.Metal, Color = COL.snowRock })
			end
			flag(top + d * 3 + right * (w / 2 + 0.6), o)
			cnt.pitches = (cnt.pitches or 0) + 1
			cnt.climbRise = (cnt.climbRise or 0) + rise
			track[#track + 1] = {
				id = (pc.kind == "chimney" and "C" or "P") .. k,
				s0 = S[math.max(1, k - 3)],
				s1 = S[math.min(n, k + 4)],
				nodes = {
					{ k = "walk", p = { pts[math.max(1, k - 3)][1], pts[math.max(1, k - 3)][3] + 3, pts[math.max(1, k - 3)][2] } },
					{ k = "walk", p = { p.X, p.Y + 3, p.Z } },
					{ k = "walk", p = { p.X + d.X * (off + FRONT - 1.2), p.Y + 3, p.Z + d.Z * (off + FRONT - 1.2) } },
					{ k = "climb", into = { d.X, 0, d.Z }, label = pc.kind .. k },
					{ k = "walk", p = { pts[math.min(n, k + 4)][1], pts[math.min(n, k + 4)][3] + 3, pts[math.min(n, k + 4)][2] } },
				},
			}
		elseif pc.kind == "steps" then
			-- v6: rock blocks to jump up (or step down) between the foot and the top landing; the terrain under them is
			-- the lower end's height (SplineGen), so the blocks are the only way
			local top = V(pts[k + 1])
			local dv = flat(top - p)
			local L = dv.Magnitude
			local d = dv.Unit
			local rise = top.Y - p.Y
			local nB = math.ceil(math.abs(rise) / SG.STEP_H)
			local hs = rise / nB
			local floorY = math.min(p.Y, top.Y)
			local sm = Kit.model(pf, "Steps_" .. k)
			local nodes = { { k = "walk", p = { p.X - d.X * 3, p.Y + 3, p.Z - d.Z * 3 } }, { k = "walk", p = { p.X, p.Y + 3, p.Z } } }
			local up = rise > 0
			local stepLen = up and (L - 0.5) / nB or L / nB
			for j = 1, up and nB or (nB - 1) do
				local along = up and (0.5 + (j - 0.5) * stepLen) or ((j - 0.5) * stepLen)
				local ty_ = p.Y + j * hs
				local bot = floorY - 3
				local c = p + d * along
				local jit = ((k * 7 + j * 13) % 5 - 2) * 0.15
				local sz = Vector3.new(w + 1 + jit, ty_ - bot, stepLen + 0.5)
				if up and j == nB then
					-- the last block reaches 3 on into the top landing (the cells between the steps' floor and the landing
					-- are neither: a 10-deep hole after the last block, east-bank steps, v6)
					sz = Vector3.new(sz.X, sz.Y, sz.Z + 3)
					c = c + d * 1.5
				end
				local b = P_(sm, { Name = "Step", Size = sz, CFrame = CFrame.lookAt(Vector3.new(c.X, bot + sz.Y / 2, c.Z), Vector3.new(c.X, bot + sz.Y / 2, c.Z) + d) * CFrame.Angles(0, jit * 0.1, 0), Material = Enum.Material.Rock, Color = (j % 2 == 0) and COL.fogRock or COL.gullyRock })
				b.CastShadow = false
				nodes[#nodes + 1] = { k = up and "jump" or "walk", p = { c.X, ty_ + 3, c.Z } }
			end
			-- ascending: on past the top edge; descending: the bottom itself (a gorge floor leaves no room to overshoot)
			local over = up and 2 or 0
			nodes[#nodes + 1] = { k = up and "jump" or "walk", p = { top.X + d.X * over, top.Y + 3, top.Z + d.Z * over } }
			nodes[#nodes + 1] = { k = "walk", p = { pts[math.min(n, k + 4)][1], pts[math.min(n, k + 4)][3] + 3, pts[math.min(n, k + 4)][2] } }
			cnt.steps = (cnt.steps or 0) + 1
			track[#track + 1] = { id = "S" .. k, s0 = S[math.max(1, k - 2)], s1 = S[math.min(n, k + 4)], nodes = nodes }
		end
	end

	------------------------------------------------ v6 segment pieces: jump gaps, hand traverses, stepping stones
	do
		local gf = Kit.folder(f, "Gaps")
		local k = 1
		while k < n do
			local t = ty[k]
			if t == "jump" or t == "traverse" or t == "ford" then
				local k1 = k
				while k1 < n and ty[k1] == t do
					k1 += 1
				end
				-- span: from the node sample where the run starts to the first sample after it
				local A = V(pts[k])
				local B = V(pts[k1])
				local d = flat(B - A).Unit
				local L = flat(B - A).Magnitude
				local w = wd[k] or 4
				local o = outward(k)
				local y = A.Y
				local right = d:Cross(UP)
				if t == "jump" or t == "traverse" then
					-- the gap itself is open in the field (SplineGen); here only a shallow clean-up of voxel rounding between
					-- the lips, never inward of the tread (deeper carves went through the terrain shell, v6)
					local mid = (A + B) / 2
					local cc = Vector3.new(mid.X, y - 2.5, mid.Z) + o * 2
					T:FillBlock(CFrame.lookAt(cc, cc + d), Vector3.new(w + 4, 6, math.max(1, L - 1)), Enum.Material.Air)
					-- rock lips: crisp take-off and landing edges
					local lm = Kit.model(gf, ((t == "jump") and "Jump_" or "Traverse_") .. k)
					for _, e in ipairs({ { A - d * 1.1, "Takeoff" }, { B + d * 1.1, "Landing" } }) do
						local c = e[1] + o * 0.6
						local lp = P_(lm, { Name = e[2], Size = Vector3.new(w + 2.5, 3, 2.6), CFrame = CFrame.lookAt(Vector3.new(c.X, y - 1.35, c.Z), Vector3.new(c.X, y - 1.35, c.Z) + d), Material = Enum.Material.Rock, Color = COL.gullyRock })
						lp.CastShadow = false
					end
					if t == "jump" then
						cnt.jumps = (cnt.jumps or 0) + 1
						track[#track + 1] = {
							id = "J" .. k,
							s0 = S[math.max(1, k - 3)],
							s1 = S[math.min(n, k1 + 3)],
							nodes = {
								{ k = "walk", p = { A.X - d.X * 4, y + 3, A.Z - d.Z * 4 } },
								{ k = "jump", p = { B.X + d.X * 2.5, y + 3, B.Z + d.Z * 2.5 } },
								{ k = "walk", p = { pts[math.min(n, k1 + 3)][1], pts[math.min(n, k1 + 3)][3] + 3, pts[math.min(n, k1 + 3)][2] } },
							},
						}
					else
						-- marked slab on the inner side (the climber's root hangs ~1.55 from its face), 4 past each end (a
						-- walker stopping a little short of the gap still has it beside them)
						local inner = -o
						local sc = (A + B) / 2 + inner * (1.55 + 2) + Vector3.new(0, -1, 0)
						local slab = P_(lm, { Name = "TraverseSlab", Size = Vector3.new(4, 11, L + 8), CFrame = CFrame.lookAt(sc, sc + d), Material = Enum.Material.Slate, Color = COL.gullyRock })
						slab:SetAttribute("Climbable", true)
						-- cue: a handline of fixed rope along the slab
						local a2, b2 = A - d * 2 + inner * 1.4 + Vector3.new(0, 3.2, 0), B + d * 2 + inner * 1.4 + Vector3.new(0, 3.2, 0)
						D_(lm, { Name = "FixedRope", Shape = Enum.PartType.Cylinder, Size = Vector3.new((b2 - a2).Magnitude, 0.25, 0.25), CFrame = CFrame.lookAt((a2 + b2) / 2, b2) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Fabric, Color = COL.ropeBright })
						cnt.traverses = (cnt.traverses or 0) + 1
						track[#track + 1] = {
							id = "T" .. k,
							s0 = S[math.max(1, k - 3)],
							s1 = S[math.min(n, k1 + 3)],
							nodes = {
								{ k = "walk", p = { A.X - d.X * 0.6, y + 3, A.Z - d.Z * 0.6 } },
								{ k = "climb", into = { inner.X, 0, inner.Z }, dir = { d.X, 0, d.Z }, label = "traverse" .. k },
								{ k = "walk", p = { pts[math.min(n, k1 + 3)][1], pts[math.min(n, k1 + 3)][3] + 3, pts[math.min(n, k1 + 3)][2] } },
							},
						}
					end
				else
					-- ford: stepping stones every ~4.2 studs over the stream (tops at the line height)
					local sm = Kit.model(gf, "Ford_" .. k)
					local ns = math.max(1, math.floor(L / 4.2))
					local nodes = { { k = "walk", p = { A.X - d.X * 2, y + 3, A.Z - d.Z * 2 } } }
					for j = 1, ns do
						local c = A:Lerp(B, j / (ns + 1))
						local cy = A.Y + (B.Y - A.Y) * j / (ns + 1)
						local st = P_(sm, { Name = "Stone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 3.2, 3.2), CFrame = CFrame.new(c.X, cy - 3, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Rock, Color = COL.gullyRock })
						st.CastShadow = false
						D_(sm, { Name = "Moss", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2.2, 2.2), CFrame = CFrame.new(c.X, cy + 0.05, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Grass, Color = COL.moss })
						nodes[#nodes + 1] = { k = "jump", p = { c.X, cy + 3, c.Z } }
					end
					-- (no jump to the far bank: a pitch foot stands right there and a jump at it grabbed the face; the next
					-- track segment walks on from the last stone)
					cnt.fords = (cnt.fords or 0) + 1
					track[#track + 1] = { id = "F" .. k, s0 = S[math.max(1, k - 2)], s1 = S[math.min(n, k1 + 2)], nodes = nodes }
				end
				k = k1
			else
				k += 1
			end
		end
	end
	table.sort(track, function(a, b)
		return a.s0 < b.s0
	end)

	------------------------------------------------ boulder-stair blocks (every stair sample run of ~2.4 studs)
	local sf = Kit.folder(f, "Stair")
	local lastS = -1e9
	for k = 1, n - 1 do
		if ty[k] == "stair" and S[k] - lastS >= 2.4 then
			lastS = S[k]
			local p = V(pts[k])
			local _, dir = outward(k)
			local w = wd[k] or 4
			local gy = Gen.heightAt(p.X, p.Z)
			local bot = math.min(gy, p.Y - 2) - 2
			local h = p.Y - bot
			local b = P_(sf, { Name = "Block", Size = Vector3.new(w + 1, h, 2.8), CFrame = CFrame.lookAt(Vector3.new(p.X, bot + h / 2, p.Z), Vector3.new(p.X, bot + h / 2, p.Z) + dir) * CFrame.Angles(0, (k % 3 - 1) * 0.05, 0), Material = Enum.Material.Rock, Color = COL.fogRock })
			b.CastShadow = false
		end
	end

	------------------------------------------------ guide flags along the line (every ~180 studs) + track export
	local nextS = 90
	for k = 1, n do
		if S[k] >= nextS and (ty[k] == "ledge" or ty[k] == "slot" or ty[k] == "ridge") then
			nextS = S[k] + 180
			local o = outward(k)
			local p = V(pts[k])
			flag(p - o * ((wd[k] or 4) / 2 + 0.5), o)
		end
	end
	local tf2 = RS:FindFirstChild("CC_Track") or Instance.new("Folder")
	tf2.Name = "CC_Track"
	tf2.Parent = RS
	local sv = tf2:FindFirstChild(name) or Instance.new("StringValue")
	sv.Name = name
	sv.Value = HS:JSONEncode(track)
	sv.Parent = tf2
	R.rests = rests
	local parts = 0
	for _, d in ipairs(f:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return string.format("%s: %d instances (%d parts) | tread %d, rails %d, ladders %d, stairs %d, bridges %d, rests %d, cairns %d, flags %d, clefts %d | v6: pitches %d (rise %d), steps %d, jumps %d, traverses %d, fords %d",
		name, #f:GetDescendants(), parts, cnt.tread, cnt.rail, cnt.ladders, cnt.stair, cnt.bridges, cnt.rests, cnt.cairns, cnt.flags, cnt.cleft,
		cnt.pitches or 0, cnt.climbRise or 0, cnt.steps or 0, cnt.jumps or 0, cnt.traverses or 0, cnt.fords or 0)
end

return SK
