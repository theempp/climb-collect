-- TraverseKit: shared builders for the traversal segments on the main route (design/traversal-plan.md).
-- Segments are placed by route distance along _G.CC_PATHS.main. They carve terrain and clear props along their
-- span, which only a full rebuild restores, so BuildAll.traverse() must run on a fresh BuildAll pass.
-- Every segment model records StartS/EndS/StartPos/EndPos attributes and a "Nodes" StringValue
-- ("x,y,z,flag;..."; flag 1 = jump, 2 = climb, 3 = bounce cap) that the measurement bot follows.
local TK = {}
local C = require(script.Parent.WorldConfig)

local UP = Vector3.yAxis
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
TK.flat = flat

function TK.applyPlayer()
	local SP = game:GetService("StarterPlayer")
	SP.CharacterWalkSpeed = C.PLAYER.walkSpeed
	SP.CharacterMaxSlopeAngle = C.PLAYER.maxSlope
end

-- Route samples for runtime code (the measurement bot now, an objective pointer later):
-- ReplicatedStorage.CC_Route.Main = "x,y,z,s;..." every 3rd sample; named waypoints as attributes (s).
function TK.exportRoute()
	local P = _G.CC_PATHS
	local RS = game:GetService("ReplicatedStorage")
	local f = RS:FindFirstChild("CC_Route")
	if not f then
		f = Instance.new("Folder")
		f.Name = "CC_Route"
		f.Parent = RS
	end
	local t = {}
	for i = 1, #P.main, 3 do
		local q = P.main[i]
		t[#t + 1] = string.format("%.1f,%.1f,%.1f,%.1f", q[1], q[3], q[2], P.mainS[i])
	end
	local sv = f:FindFirstChild("Main") or Instance.new("StringValue")
	sv.Name = "Main"
	sv.Value = table.concat(t, ";")
	sv.Parent = f
	for name, i in pairs(P.wp) do
		f:SetAttribute(name, P.mainS[i])
	end
end

---------------------------------------------------------------- context
local Ctx = {}
Ctx.__index = Ctx

function TK.begin(Kit, Gen, name)
	local root = Kit.folder(Kit.folder(workspace, "World"), "Traverse")
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	return setmetatable({ Kit = Kit, Gen = Gen, P = _G.CC_PATHS, COL = Kit.COL, folder = Kit.folder(root, name) }, Ctx)
end

-- route sample i as a world point (P.main stores {x, z, y})
function Ctx:pt(i)
	local p = self.P.main[math.clamp(i, 1, #self.P.main)]
	return Vector3.new(p[1], p[3], p[2])
end

function Ctx:dir(i)
	return flat(self:pt(i + 2) - self:pt(i - 2)).Unit
end

-- unit vector across the route pointing toward the summit axis
function Ctx:mtn(i)
	local r = self:dir(i):Cross(UP)
	return (r:Dot(flat(-self:pt(i))) > 0) and r or -r
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Terrain }
-- terrain height under (x, z); unlike Gen.heightAt it sees carved terrain
function Ctx:ground(x, z, fromY)
	fromY = fromY or C.TOP
	local r = workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -fromY - 50, 0), rp)
	return r and r.Position.Y or self.Gen.heightAt(x, z)
end

-- vegetation and route props that a segment may displace (camps and landmarks are never touched)
local CLEARABLE = {
	Vegetation = true, Trees = true, Flowers = true, Bushes = true, RouteLanterns = true,
	BandStairs = true, LedgeFences = true, RidgeFences = true, Cairns = true, SummitStairs = true,
}
function Ctx:clear(i0, i1, radius)
	local pts = {}
	for i = i0, i1, 2 do
		pts[#pts + 1] = self:pt(i)
	end
	local n = 0
	for _, f in ipairs(workspace.World.Regions:GetDescendants()) do
		if f:IsA("Folder") and CLEARABLE[f.Name] then
			for _, m in ipairs(f:GetChildren()) do
				if m:IsA("Model") or m:IsA("BasePart") then
					local pos = m:GetPivot().Position
					for _, q in ipairs(pts) do
						if flat(pos - q).Magnitude < radius and math.abs(pos.Y - q.Y) < 40 then
							m:Destroy()
							n += 1
							break
						end
					end
				end
			end
		end
	end
	return n
end

function Ctx:iAtS(s)
	local S = self.P.mainS
	local lo, hi = 1, #S
	while hi - lo > 1 do
		local m = (lo + hi) // 2
		if S[m] < s then
			lo = m
		else
			hi = m
		end
	end
	return hi
end

-- Terrain renders a voxel surface ~1.7 studs above its filled height (same constant as MountainGen)
local SURF = 1.7

-- Carve the route between distances s0 and s1 into a gorge (Read/WriteVoxels on the 4-stud grid,
-- so its ends land within +-2 studs of s0/s1; put kerbs or wall parts over the ends for exact edges).
-- floorAt(t, y) = absolute visible floor height at t = 0..1 (y = trail height there); inW/outW =
-- lateral extent toward the mountain / the valley. Cut faces become opts.wallMat; terrain already
-- lower than the floor is left alone. Returns floor(s), the floor height by route distance.
function Ctx:gorge(s0, s1, floorAt, inW, outW, floorMat, opts)
	opts = opts or {}
	local T = workspace.Terrain
	local S = self.P.mainS
	local L = s1 - s0
	local samp = {}
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	-- samples and region reach past the cut so the backing band (8 studs) is covered
	for i = self:iAtS(s0 - 12), self:iAtS(s1 + 12) do
		local p, m = self:pt(i), self:mtn(i)
		samp[#samp + 1] = { p = p, m = m, d = self:dir(i), s = S[i] }
		local fy = floorAt(math.clamp((S[i] - s0) / L, 0, 1), p.Y)
		for _, o in ipairs({ -outW - 12, inW + 12 }) do
			local q = p + m * o
			local top = math.max(p.Y, self.Gen.heightAt(q.X, q.Z))
			lo = lo:Min(Vector3.new(q.X - 6, fy - 20, q.Z - 6))
			hi = hi:Max(Vector3.new(q.X + 6, top + 12, q.Z + 6))
		end
	end
	local region = Region3.new(lo, hi):ExpandToGrid(4)
	local mats, occs = T:ReadVoxels(region, 4)
	local size = mats.Size
	local corner = region.CFrame.Position - region.Size / 2
	local wallMat = opts.wallMat or Enum.Material.Rock
	local n = #samp
	local AIR = Enum.Material.Air
	for ix = 1, size.X do
		for iz = 1, size.Z do
			local cx, cz = corner.X + (ix - 0.5) * 4, corner.Z + (iz - 0.5) * 4
			-- nearest sample in plan, then continuous route distance of the voxel column
			local best, k = math.huge, 1
			for j = 1, n do
				local q = samp[j].p
				local dd = (q.X - cx) ^ 2 + (q.Z - cz) ^ 2
				if dd < best then
					best, k = dd, j
				end
			end
			local sp = samp[k]
			local rel = Vector3.new(cx - sp.p.X, 0, cz - sp.p.Z)
			local lat, sv = rel:Dot(sp.m), sp.s + rel:Dot(sp.d)
			local inSpan = sv >= s0 and sv <= s1
			local inside = inSpan and lat >= -outW and lat <= inW
			-- band around the cut (sides and ends) that keeps solid backing behind its faces
			local near = sv >= s0 - 8 and sv <= s1 + 8 and lat >= -outW - 8 and lat <= inW + 8
			local h = floorAt(math.clamp((sv - s0) / L, 0, 1), self:at(sv).Y) - SURF
			-- original surface of this column (MountainGen writes terrain as a shell ~10 studs thick,
			-- so a deep cut must rebuild solid ground under its floor and behind its walls)
			local top0
			for iy = size.Y, 1, -1 do
				if occs[ix][iy][iz] > 0.02 and mats[ix][iy][iz] ~= Enum.Material.Water then
					top0 = corner.Y + (iy - 1) * 4 + 4 * occs[ix][iy][iz]
					break
				end
			end
			for iy = 1, size.Y do
				local yb = corner.Y + (iy - 1) * 4
				local o0 = occs[ix][iy][iz]
				if inside then
					local o = math.clamp((h - yb) / 4, 0, 1)
					if o < o0 then
						occs[ix][iy][iz] = o
						mats[ix][iy][iz] = (o > 0.02) and floorMat or AIR
					elseif top0 and top0 > h + 1 and yb >= h - 14 and o > o0 then
						occs[ix][iy][iz] = o
						mats[ix][iy][iz] = (yb > h - 8) and floorMat or wallMat
					elseif o0 > 0 and yb > h - 8 then
						mats[ix][iy][iz] = floorMat
					end
				elseif near and top0 then
					if yb + 4 <= top0 - 2 and yb >= math.min(h, top0) - 14 and o0 < 1 then
						occs[ix][iy][iz] = 1
						mats[ix][iy][iz] = wallMat
					elseif inSpan and o0 > 0.02 and yb + 4 > h and mats[ix][iy][iz] ~= Enum.Material.Water then
						mats[ix][iy][iz] = wallMat
					end
				end
			end
		end
	end
	T:WriteVoxels(region, 4, mats, occs)
	return function(sq)
		return floorAt(math.clamp((sq - s0) / L, 0, 1), self:at(sq).Y)
	end
end

-- stone kerb over a gully end: its top is flush with the trail at s and its edge sits exactly at s,
-- hiding the voxel-quantized cut. back = +1 for a start lip (kerb behind s), -1 for an end lip.
function Ctx:kerb(s, back, inW, outW)
	local K, COL = self.Kit, self.COL
	local y = self:at(s).Y
	local a, b = self:at(s - back * 7, (inW - outW) / 2), self:at(s, (inW - outW) / 2)
	local mid = Vector3.new((a.X + b.X) / 2, y - 1.5, (a.Z + b.Z) / 2)
	K.part(self.folder, { Name = "Kerb", Size = Vector3.new(inW + outW, 3, 7), CFrame = CFrame.lookAt(mid, mid + flat(b - a)), Material = Enum.Material.Cobblestone, Color = COL.masonry })
end

-- dry gully across the trail between two stone kerbs; returns the floor function
function Ctx:gully(sLip, sEnd, depth, inW, outW, floorMat)
	self:clear(self:iAtS(sLip) - 4, self:iAtS(sEnd) + 4, 30)
	local fl = self:gorge(sLip - 3, sEnd + 3, function(_, y)
		return y - depth
	end, inW, outW, floorMat or Enum.Material.Mud)
	self:kerb(sLip, 1, inW, outW)
	self:kerb(sEnd, -1, inW, outW)
	return fl
end

-- trailhead sign on the valley side of sample i
function Ctx:sign(i, text)
	local p = self:pt(i) - self:mtn(i) * 8
	p = Vector3.new(p.X, self:ground(p.X, p.Z, p.Y + 30), p.Z)
	local d = self:dir(i)
	self.Kit.sign(self.folder, CFrame.lookAt(p, p + d) * CFrame.Angles(0, math.rad(90), 0), { { text, 0 } }, 8)
end

---------------------------------------------------------------- pieces
-- vertical stone column whose flat top sits at topY, grounded on the terrain below.
-- floorY: known floor under freshly carved terrain (raycasts lag behind WriteVoxels)
local function column(c, center, size, topY, kind, floorY)
	local K, COL = c.ctx.Kit, c.ctx.COL
	local g = c.ctx:ground(center.X, center.Z, topY + 30)
	if floorY then
		g = math.min(g, floorY)
	end
	local bottom = math.min(g, topY) - 3
	local h = topY - bottom
	local upright = CFrame.Angles(0, c.rng:NextNumber(0, math.pi), math.rad(90))
	if kind == "boulder" then
		K.part(c.model, { Name = "Stone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, size, size), CFrame = CFrame.new(center.X, bottom + h / 2, center.Z) * upright, Material = Enum.Material.Rock, Color = COL.rock })
		local skirt = math.min(h * 0.4, h - 3)
		if skirt > 1 then
			K.part(c.model, { Name = "Skirt", Shape = Enum.PartType.Cylinder, Size = Vector3.new(skirt, size + 1.6, size + 1.6), CFrame = CFrame.new(center.X, bottom + skirt / 2, center.Z) * upright, Material = Enum.Material.Rock, Color = COL.rock })
		end
		K.decor(K.part(c.model, { Name = "Moss", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, size - 1.6, size - 1.6), CFrame = CFrame.new(center.X, topY - 0.1, center.Z) * upright, Material = Enum.Material.Grass, Color = COL.meadow }))
	elseif kind == "stump" then
		K.part(c.model, { Name = "Stump", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, size, size), CFrame = CFrame.new(center.X, bottom + h / 2, center.Z) * upright, Material = Enum.Material.Wood, Color = COL.timberDark })
		K.decor(K.part(c.model, { Name = "Rings", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, size - 0.8, size - 0.8), CFrame = CFrame.new(center.X, topY - 0.1, center.Z) * upright, Material = Enum.Material.Wood, Color = COL.timber }))
	elseif kind == "cap" then
		-- glowing forest mushroom (§3 "iridescent mushrooms"); the cap disc is the bounce surface
		local stemD = math.max(1.6, size * 0.3)
		K.part(c.model, { Name = "Stem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h - 1.2, stemD, stemD), CFrame = CFrame.new(center.X, bottom + (h - 1.2) / 2, center.Z) * upright, Material = Enum.Material.SmoothPlastic, Color = COL.moon })
		local cap = K.part(c.model, { Name = "Cap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, size, size), CFrame = CFrame.new(center.X, topY - 0.7, center.Z) * upright, Material = Enum.Material.SmoothPlastic, Color = COL.indigo })
		cap:AddTag("CC_Bounce")
		cap:SetAttribute("Height", c.bounceH or 16)
		K.decor(K.part(c.model, { Name = "Glow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, size - 2, size - 2), CFrame = CFrame.new(center.X, topY + 0.05, center.Z) * upright, Material = Enum.Material.Neon, Color = COL.turquoise, Transparency = 0.35 }))
	else -- "slab": masonry block
		K.part(c.model, { Name = "Block", Size = Vector3.new(size, h, size), CFrame = CFrame.new(center.X, bottom + h / 2, center.Z) * CFrame.Angles(0, c.rng:NextNumber(-0.3, 0.3), 0), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	end
end
TK.column = column

-- climbable face: invisible trusses (Roblox native climb, no button needed on mobile) in front of a
-- solid wall, dressed per kind. face = foot of the wall's near face, d = travel direction.
-- Returns the far top edge of the wall (the next walking point).
function TK.climbFace(ctx, model, face, d, h, width, kind, depth)
	local K, COL = ctx.Kit, ctx.COL
	h = 2 * math.ceil(h / 2)
	width = 2 * math.max(2, math.floor(width / 2))
	depth = depth or 6
	local cf = CFrame.lookAt(face, face + d)
	K.part(model, { Name = "ClimbWall", Size = Vector3.new(width + 4, h + 4, depth), CFrame = cf * CFrame.new(0, (h - 4) / 2, -depth / 2), Material = Enum.Material.Rock, Color = COL.rock })
	for k = 0, width / 2 - 1 do
		local t = Instance.new("TrussPart")
		t.Name = "Climb"
		t.Anchored = true
		t.Style = Enum.Style.NoSupports
		t.Size = Vector3.new(2, h, 2)
		t.CFrame = cf * CFrame.new(-width / 2 + 1 + 2 * k, h / 2, 1)
		t.Transparency = 1
		t.CastShadow = false
		t.Parent = model
	end
	if kind == "frame" then
		-- timber climbing frame: two posts, rungs every 1.75 studs, a cap beam
		for _, s in ipairs({ -1, 1 }) do
			K.part(model, { Name = "Post", Size = Vector3.new(0.9, h + 2.5, 0.9), CFrame = cf * CFrame.new(s * (width / 2 + 0.45), (h + 2.5) / 2 - 1, 1), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
		local y = 1
		while y < h - 0.5 do
			local r = K.cylAB((cf * CFrame.new(-width / 2, y, 1.6)).Position, (cf * CFrame.new(width / 2, y, 1.6)).Position, 0.45)
			r.Name = "Rung"
			r.Material = Enum.Material.Wood
			r.Color = COL.timber
			K.decor(r)
			r.Parent = model
			y += 1.75
		end
		K.part(model, { Name = "Cap", Size = Vector3.new(width + 1.8, 0.8, 1.2), CFrame = cf * CFrame.new(0, h + 1.1, 1), Material = Enum.Material.Wood, Color = COL.timberDark })
	elseif kind == "roots" then
		-- roots draped over the face (§4 Whispering Forest root arch, §3 "glowing roots"): three
		-- trailing roots, cross-roots as handholds, one indigo glow vein
		local function root(a, b, dia, col, mat)
			local r = K.cylAB((cf * a).Position, (cf * b).Position, dia)
			r.Name = "Root"
			r.Material = mat or Enum.Material.Wood
			r.Color = col or COL.timberDark
			K.decor(r)
			r.Parent = model
		end
		for k = -1, 1 do
			local x = k * width / 3
			root(CFrame.new(x + 0.8, -1, 1.5), CFrame.new(x - 0.8, h + 1.5, 1.3), 1.4)
		end
		local y = 1.2
		while y < h - 0.5 do
			root(CFrame.new(-width / 2, y, 1.7), CFrame.new(width / 2, y + 0.4, 1.7), 0.8, COL.timber)
			y += 2.2
		end
		root(CFrame.new(-width / 3 + 1.2, -0.5, 2), CFrame.new(-width / 3 - 0.4, h + 1, 1.8), 0.35, COL.indigo, Enum.Material.Neon)
	end
	return face + d * depth + UP * h
end

---------------------------------------------------------------- course cursor
-- A course is authored in route distance: c.s = distance along the main route, c.side = lateral
-- offset toward the mountain. Pieces follow the trail's curve without per-segment geometry math.
local Course = {}
Course.__index = Course

-- route point at distance s, offset `side` studs toward the mountain
function Ctx:at(s, side)
	local S = self.P.mainS
	local i = math.max(2, self:iAtS(s))
	local t = math.clamp((s - S[i - 1]) / math.max(1e-3, S[i] - S[i - 1]), 0, 1)
	local p = self:pt(i - 1):Lerp(self:pt(i), t)
	if side and side ~= 0 then
		p += self:mtn(i) * side
	end
	return p
end

-- course starting at route distance s0; floor (optional) = function(s) from Ctx:gorge, so pieces
-- reach the freshly carved floor
function Ctx:course(name, s0, seed, floor)
	local m = self.Kit.model(self.folder, name)
	local c = setmetatable({ ctx = self, model = m, s = s0, side = 0, pos = self:at(s0), dir = self:dir(self:iAtS(s0)), nodes = {}, rng = Random.new(seed or math.floor(s0)), floor = floor }, Course)
	m:SetAttribute("StartS", s0)
	m:SetAttribute("StartPos", self:at(s0 - 1))
	return c
end

function Course:node(p, flag)
	self.nodes[#self.nodes + 1] = string.format("%.1f,%.1f,%.1f,%d", p.X, p.Y, p.Z, flag or 0)
	self.walked = false
end

function Course:aim(target)
	self.dir = flat(target - self.pos).Unit
end

-- advance the cursor to route distance s (lateral offset kept) at height y
function Course:advance(s, y)
	self.s = s
	self.dir = self.ctx:dir(self.ctx:iAtS(s))
	local e = self.ctx:at(s, self.side)
	self.pos = Vector3.new(e.X, y, e.Z)
end

-- jump to a platform `gap` studs ahead (edge to edge) whose top is `rise` above the current
-- surface; side = lateral offset toward the mountain (kept for later pieces)
function Course:hop(size, gap, rise, kind, side)
	self.side = side or self.side
	local top = self.pos.Y + rise
	local sc = self.s + gap + size / 2
	local cxz = self.ctx:at(sc, self.side)
	local center = Vector3.new(cxz.X, top, cxz.Z)
	column(self, center, size, top, kind, self.floor and self.floor(sc))
	self:node(center, (gap > 0.5 or rise > 1.5) and 1 or 0)
	self:advance(self.s + gap + size, top)
end

-- like hop, onto a bounce cap that launches to `height` studs (CC_TraverseClient); node flag 3
function Course:bounce(size, gap, rise, height, side)
	self.bounceH = height
	self:hop(size, gap, rise, "cap", side)
	self.nodes[#self.nodes] = self.nodes[#self.nodes]:gsub(",%d+$", ",3")
	self.onCap = true
end

-- fallen log `len` long starting `gap` ahead, top `rise` above the current surface. A flat box
-- carries the collision; a slightly wider round bark shell is decoration. Supports reach the floor.
function Course:log(len, rise, gap, side)
	self.side = side or self.side
	local K, COL = self.ctx.Kit, self.ctx.COL
	local top = self.pos.Y + rise
	local a0, b0 = self.ctx:at(self.s + gap, self.side), self.ctx:at(self.s + gap + len, self.side)
	local a, b = Vector3.new(a0.X, top, a0.Z), Vector3.new(b0.X, top, b0.Z)
	local cf = CFrame.lookAt((a + b) / 2, b)
	K.part(self.model, { Name = "Log", Size = Vector3.new(4, 2.6, (b - a).Magnitude), CFrame = cf * CFrame.new(0, -1.3, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
	local bark = K.cylAB(a - UP * 2.1, b - UP * 2.1, 4.6)
	bark.Name = "Bark"
	bark.Material = Enum.Material.Wood
	bark.Color = COL.timberDark
	K.decor(bark, true)
	bark.Parent = self.model
	for _, e in ipairs({ { a, self.s + gap + 1.5 }, { b, self.s + gap + len - 1.5 } }) do
		local q, sq = e[1], e[2]
		local g = self.ctx:ground(q.X, q.Z, q.Y + 20)
		if self.floor then
			g = math.min(g, self.floor(sq))
		end
		if q.Y - g > 3 then
			local post = K.cylAB(Vector3.new(q.X, g - 1, q.Z), q - UP * 2, 1.8)
			post.Name = "Prop"
			post.Material = Enum.Material.Wood
			post.Color = COL.timberDark
			post.Parent = self.model
		end
	end
	self:node(a + (b - a).Unit * 2, self.onCap and 0 or 1)
	self:node(b - (b - a).Unit * 1, 0)
	self.onCap = false
	self:advance(self.s + gap + len, top)
end

-- climb a wall whose near face starts at the current point; depth = depth of the wall top
function Course:climb(h, width, kind, depth)
	depth = depth or 6
	self.dir = self.ctx:dir(self.ctx:iAtS(self.s))
	local top = TK.climbFace(self.ctx, self.model, self.pos, self.dir, h, width, kind, depth)
	if self.walked then
		self.nodes[#self.nodes] = nil -- a walk that ends on the wall face would count as arrived on top
	end
	self:node(self.pos - self.dir * 2.5, 0)
	self:node(top - self.dir * 2, 2)
	self:advance(self.s + depth, top.Y)
end

-- walk `dist` along existing ground/floor; y = floor height at the end (default: unchanged)
function Course:walk(dist, y)
	self:advance(self.s + dist, y or self.pos.Y)
	self:node(self.pos, 0)
	self.walked = true
end

-- walkable strip `len` ahead rising `rise`, with posts down to the ground where it floats
function Course:slab(len, rise, width, kind)
	local K, COL = self.ctx.Kit, self.ctx.COL
	local a = self.pos
	local e = self.ctx:at(self.s + len, self.side)
	local b = Vector3.new(e.X, a.Y + rise, e.Z)
	local d = flat(b - a).Unit
	local cf = CFrame.lookAt((a + b) / 2, b)
	local timber = kind == "plank"
	K.part(self.model, { Name = timber and "Plank" or "Slab", Size = Vector3.new(width, 1, (b - a).Magnitude + 0.3), CFrame = cf * CFrame.new(0, -0.5, 0), Material = timber and Enum.Material.WoodPlanks or Enum.Material.Cobblestone, Color = timber and COL.timber or COL.masonry })
	for k, q0 in ipairs({ a + d * 0.8, b - d * 0.8 }) do
		local g = self.ctx:ground(q0.X, q0.Z, q0.Y + 20)
		if self.floor then
			g = math.min(g, self.floor(k == 1 and self.s + 0.8 or self.s + len - 0.8))
		end
		if q0.Y - g > 1.5 then
			for _, sg in ipairs({ -1, 1 }) do
				local q = q0 + d:Cross(UP) * sg * (width / 2 - 0.5)
				K.part(self.model, { Name = "Post", Size = Vector3.new(0.8, q0.Y - g + 2, 0.8), CFrame = CFrame.new(q.X, (q0.Y + g) / 2 - 1, q.Z), Material = Enum.Material.Wood, Color = COL.timberDark })
			end
		end
	end
	self:node(b, 0)
	self:advance(self.s + len, b.Y)
end

-- close the course on the trail at route distance s1 and record measurement data.
-- jump = true: the last move is a jump onto the trail lip instead of a built connector.
function Course:finish(s1, jump)
	local target = self.ctx:at(s1)
	local len = s1 - self.s
	if jump then
		self:node(target, 1)
	elseif len > 1 then
		local rise = target.Y - self.pos.Y
		if rise > len * 0.7 then
			self.ctx.Kit.stairs(self.model, self.pos, target, 6)
			self:node(target, 0)
			self.pos = target
		else
			self.side = 0
			self:slab(len, rise, 7, "stone")
		end
	end
	if not jump then
		self:node(target, 0)
	end
	local m = self.model
	m:SetAttribute("EndS", s1)
	m:SetAttribute("EndPos", target)
	local sv = Instance.new("StringValue")
	sv.Name = "Nodes"
	sv.Value = table.concat(self.nodes, ";")
	sv.Parent = m
	return m
end

return TK
