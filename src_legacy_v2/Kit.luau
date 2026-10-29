-- Kit: parametric prop builders for CLIMB & COLLECT (PROPOSED art, colors from design/world-tokens.md).
-- Prototypes (trees, bushes, flower patches) are CSG unions built once into ServerStorage.CC_Prototypes
-- and cloned with scale/rotation/colour variation, so each plant costs 1-2 instances.
local Kit = {}
local GS = game:GetService("GeometryService")
local SS = game:GetService("ServerStorage")

Kit.COL = {
	timber = Color3.fromRGB(140, 96, 60), -- §3 "timber"
	timberDark = Color3.fromRGB(98, 66, 42), -- shaded timber (roofs, beams)
	masonry = Color3.fromRGB(150, 146, 132), -- §3 "ruin masonry"
	lantern = Color3.fromRGB(255, 178, 72), -- §3/§4 lantern gold
	golden = Color3.fromRGB(255, 214, 150), -- §3 "golden daylight"
	meadow = Color3.fromRGB(84, 176, 82), -- §4 "meadow emerald"
	leafLight = Color3.fromRGB(118, 194, 92), -- §3 "lush saturated greens" (lit tone)
	forestTeal = Color3.fromRGB(38, 112, 98), -- §3 "deep forest teal"
	turquoise = Color3.fromRGB(46, 196, 182), -- §3 "clear turquoise falls"
	moon = Color3.fromRGB(220, 230, 255), -- §3 "moonlight"
	indigo = Color3.fromRGB(92, 76, 220), -- §4 "luminous indigo"
	sandstone = Color3.fromRGB(214, 150, 82),
	slate = Color3.fromRGB(62, 66, 76),
	ice = Color3.fromRGB(196, 232, 255),
	cyan = Color3.fromRGB(62, 224, 255),
	violet = Color3.fromRGB(138, 78, 255),
	rock = Color3.fromRGB(120, 128, 108), -- §3 "lichen-covered rock" (terrain Rock)
}
local COL = Kit.COL
Kit.SIGN_FONT = Enum.Font.FredokaOne -- OPEN: master.md names no typeface; provisional

---------------------------------------------------------------- basics
function Kit.part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	if parent then
		p.Parent = parent
	end
	return p
end

function Kit.wedge(parent, props)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	if parent then
		p.Parent = parent
	end
	return p
end

-- non-colliding, non-queryable decoration
function Kit.decor(p, shadow)
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = shadow == true
	return p
end

function Kit.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	if parent then
		m.Parent = parent
	end
	return m
end

function Kit.folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

function Kit.union(parts, usePartColor)
	local base = table.remove(parts, 1)
	local holder = Instance.new("Model")
	base.Parent = holder
	for _, p in ipairs(parts) do
		p.Parent = holder
	end
	holder.Parent = workspace -- UnionAsync needs parts in the DataModel
	local res = GS:UnionAsync(base, parts, {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Automatic,
		SplitApart = false,
	})
	local u = res[1]
	u.UsePartColor = usePartColor ~= false
	u.Anchored = true
	u.Parent = nil
	holder:Destroy()
	return u
end

local function cyl(len, d, cf)
	return Kit.part(nil, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, d, d), CFrame = cf })
end
local function ball(d, pos)
	return Kit.part(nil, { Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(pos) })
end
-- cylinder from a to b (Roblox cylinders run along X)
local function cylAB(a, b, d)
	local v = b - a
	local dir = v.Unit
	-- fromMatrix keeps vertical cylinders well-defined (lookAt degenerates when dir is parallel to Y)
	local ref = (math.abs(dir.Y) < 0.9) and Vector3.yAxis or Vector3.xAxis
	local up = dir:Cross(ref).Unit
	return cyl(v.Magnitude, d, CFrame.fromMatrix((a + b) / 2, dir, up))
end
Kit.cylAB = cylAB

---------------------------------------------------------------- prototypes
local PROTO
local function protoFolder()
	if PROTO and PROTO.Parent then
		return PROTO
	end
	PROTO = SS:FindFirstChild("CC_Prototypes")
	if not PROTO then
		PROTO = Instance.new("Folder")
		PROTO.Name = "CC_Prototypes"
		PROTO.Parent = SS
	end
	return PROTO
end

-- trunk + canopy unions in a Model whose pivot sits at ground level
local function makeTree(name, trunkParts, canopyParts, leafMat)
	local m = Instance.new("Model")
	m.Name = name
	local trunk = Kit.union(trunkParts)
	trunk.Name = "Trunk"
	trunk.Material = Enum.Material.Wood
	trunk.Color = COL.timberDark
	trunk.Parent = m
	local canopy = Kit.union(canopyParts)
	canopy.Name = "Canopy"
	canopy.Material = leafMat or Enum.Material.LeafyGrass
	canopy.Color = COL.meadow
	Kit.decor(canopy, true)
	canopy.CanQuery = false
	canopy.Parent = m
	-- no PrimaryPart: a union's frame follows its first part, which would tilt the pivot
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

local builders = {}

builders.TreeRound = function()
	local t = {
		cylAB(Vector3.new(0, -1, 0), Vector3.new(0.6, 12, 0.3), 2.4),
		cylAB(Vector3.new(0.4, 8, 0.2), Vector3.new(3.6, 12.5, 1.2), 1.1),
		cylAB(Vector3.new(0.3, 9, 0.1), Vector3.new(-2.8, 13, -1.4), 1.0),
	}
	local c = {
		ball(11, Vector3.new(0.5, 15.5, 0)),
		ball(8.5, Vector3.new(4.2, 14, 1.5)),
		ball(8, Vector3.new(-3.6, 14.3, -1.6)),
		ball(7.5, Vector3.new(0.8, 13.5, -4)),
		ball(7, Vector3.new(-0.5, 19, 1)),
	}
	return makeTree("TreeRound", t, c)
end

builders.TreeTall = function()
	local t = {
		cylAB(Vector3.new(0, -1, 0), Vector3.new(-0.4, 16, 0.4), 2.2),
		cylAB(Vector3.new(-0.2, 10, 0.2), Vector3.new(2.6, 14, 0.6), 0.9),
	}
	local c = {
		ball(8.5, Vector3.new(-0.3, 15, 0.2)),
		ball(9, Vector3.new(0, 19.5, 0)),
		ball(7.5, Vector3.new(0.5, 23.5, -0.3)),
		ball(6.5, Vector3.new(2.6, 16.5, 1.2)),
	}
	return makeTree("TreeTall", t, c)
end

builders.Pine = function()
	local t = { cylAB(Vector3.new(0, -1, 0), Vector3.new(0, 10, 0), 1.8) }
	local c = {}
	-- four overlapping stepped cones (no cone primitive): each tier is a stack of shrinking discs
	local tiers = { { 4, 14, 8 }, { 9.5, 11.5, 7 }, { 14.5, 8.5, 6 }, { 19, 5.5, 5 } }
	for _, tr in ipairs(tiers) do
		local y0, R, H = tr[1], tr[2], tr[3]
		for k = 0, 5 do
			local f = 1 - k / 6
			c[#c + 1] = cyl(H / 6 + 0.05, R * f, CFrame.new(0, y0 + k * H / 6, 0) * CFrame.Angles(0, 0, math.rad(90)))
		end
	end
	c[#c + 1] = ball(1.8, Vector3.new(0, 24.2, 0))
	return makeTree("Pine", t, c)
end

builders.Bush = function()
	local m = Instance.new("Model")
	m.Name = "Bush"
	local u = Kit.union({
		ball(5, Vector3.new(0, 1.6, 0)),
		ball(4, Vector3.new(2.2, 1.2, 0.6)),
		ball(3.6, Vector3.new(-2, 1.1, -0.5)),
		ball(3.2, Vector3.new(0.4, 1, 2)),
	})
	u.Name = "Leaves"
	u.Material = Enum.Material.LeafyGrass
	u.Color = COL.leafLight
	Kit.decor(u, false)
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- flower patch: stems + heads unioned with original colours kept
local function flowerPatch(name, colors, seed)
	local rng = Random.new(seed)
	local parts = {}
	for i = 1, 14 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0, 5.5)
		local x, z = math.cos(a) * r, math.sin(a) * r
		local h = rng:NextNumber(1.6, 3.2)
		local stem = cylAB(Vector3.new(x, -0.3, z), Vector3.new(x, h, z), 0.3)
		stem.Color = COL.meadow
		parts[#parts + 1] = stem
		local head = ball(rng:NextNumber(1.3, 1.9), Vector3.new(x, h + 0.3, z))
		head.Color = colors[(i % #colors) + 1]
		head.Material = Enum.Material.SmoothPlastic
		parts[#parts + 1] = head
	end
	local m = Instance.new("Model")
	m.Name = name
	local u = Kit.union(parts, false)
	u.Name = "Flowers"
	Kit.decor(u, false)
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end
builders.FlowersGold = function()
	return flowerPatch("FlowersGold", { COL.golden, COL.lantern, COL.golden }, 11)
end
builders.FlowersTurq = function()
	return flowerPatch("FlowersTurq", { COL.turquoise, COL.moon, COL.golden }, 23)
end
builders.FlowersMoon = function()
	return flowerPatch("FlowersMoon", { COL.moon, COL.indigo, COL.moon }, 37)
end

-- Whispering Forest: iridescent mushroom cluster (§3 "iridescent mushrooms"), caps in turquoise/indigo/violet
builders.Mushrooms = function()
	local parts = {}
	local specs = { { 0, 0, 5.5, 4.6, COL.turquoise }, { 3.4, 1.2, 3.6, 3.2, COL.indigo }, { -2.6, 2, 2.6, 2.4, COL.violet }, { 1, -3, 2.2, 2, COL.turquoise } }
	for _, s in ipairs(specs) do
		local x, z, h, r, c = s[1], s[2], s[3], s[4], s[5]
		local stem = cylAB(Vector3.new(x, -0.4, z), Vector3.new(x, h, z), r * 0.35)
		stem.Color = COL.moon
		parts[#parts + 1] = stem
		local cap = cyl(r * 0.25, r * 2, CFrame.new(x, h, z) * CFrame.Angles(0, 0, math.rad(90)))
		cap.Color = c
		parts[#parts + 1] = cap
		local dome = ball(r * 1.9, Vector3.new(x, h + r * 0.05, z))
		dome.Color = c
		parts[#parts + 1] = dome
	end
	-- keep only the upper half of each dome by unioning with the cap disc (domes sit on the caps)
	local m = Instance.new("Model")
	m.Name = "Mushrooms"
	local u = Kit.union(parts, false)
	u.Name = "Caps"
	u.Material = Enum.Material.SmoothPlastic
	Kit.decor(u, false)
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- Frozen Summit / Storm Ridge: crystal cluster (§3 "icy crystal facets", "controlled crystalline magical structures")
local function crystalCluster(name, color)
	local parts = {}
	local rng = Random.new(#name * 7)
	for i = 1, 6 do
		local h = rng:NextNumber(4, 11)
		local w = rng:NextNumber(1.2, 2.4)
		local a = i / 6 * math.pi * 2
		local tilt = rng:NextNumber(0.15, 0.45)
		local base = Vector3.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2)
		local cf = CFrame.new(base) * CFrame.Angles(0, a, 0) * CFrame.Angles(tilt, 0, 0) * CFrame.new(0, h / 2 - 0.5, 0) * CFrame.Angles(0, math.rad(45), 0)
		parts[#parts + 1] = Kit.part(nil, { Size = Vector3.new(w, h, w), CFrame = cf })
	end
	parts[#parts + 1] = Kit.part(nil, { Size = Vector3.new(2.4, 13, 2.4), CFrame = CFrame.new(0, 6, 0) * CFrame.Angles(0, math.rad(45), 0) })
	local m = Instance.new("Model")
	m.Name = name
	local u = Kit.union(parts)
	u.Name = "Crystal"
	u.Material = Enum.Material.Glass
	u.Color = color
	u.Transparency = 0.15
	u.Reflectance = 0.1
	Kit.decor(u, true)
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end
builders.CrystalIce = function()
	return crystalCluster("CrystalIce", COL.ice)
end
builders.CrystalAurora = function()
	return crystalCluster("CrystalAurora", Color3.fromRGB(156, 92, 246))
end

-- Storm Ridge: snow-dusted pine (tiers with white caps, original colours kept)
builders.SnowPine = function()
	local t = { cylAB(Vector3.new(0, -1, 0), Vector3.new(0, 10, 0), 1.8) }
	local c = {}
	local tiers = { { 4, 13, 7 }, { 9, 10.5, 6 }, { 13.5, 8, 5 }, { 17.5, 5.5, 4.5 } }
	for _, tr in ipairs(tiers) do
		local y0, R, H = tr[1], tr[2], tr[3]
		for k = 0, 5 do
			local f = 1 - k / 6
			local d = cyl(H / 6 + 0.05, R * f, CFrame.new(0, y0 + k * H / 6, 0) * CFrame.Angles(0, 0, math.rad(90)))
			d.Color = (k >= 4) and COL.moon or COL.forestTeal
			c[#c + 1] = d
		end
	end
	local m = Instance.new("Model")
	m.Name = "SnowPine"
	local trunk = Kit.union(t)
	trunk.Name = "Trunk"
	trunk.Material = Enum.Material.Wood
	trunk.Color = COL.timberDark
	trunk.Parent = m
	local canopy = Kit.union(c, false)
	canopy.Name = "Canopy"
	canopy.Material = Enum.Material.LeafyGrass
	Kit.decor(canopy, true)
	canopy.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- Storm Ridge: wind-scarred dead tree (bare, leaning branches)
builders.DeadTree = function()
	local p = {
		cylAB(Vector3.new(0, -1, 0), Vector3.new(1.2, 14, 0.3), 1.6),
		cylAB(Vector3.new(0.6, 7, 0.1), Vector3.new(5, 11, 1), 0.7),
		cylAB(Vector3.new(0.9, 10, 0.2), Vector3.new(4.6, 15, -0.8), 0.6),
		cylAB(Vector3.new(0.8, 9, 0.2), Vector3.new(-2.2, 12.5, 1.6), 0.55),
	}
	local m = Instance.new("Model")
	m.Name = "DeadTree"
	local u = Kit.union(p)
	u.Name = "Trunk"
	u.Material = Enum.Material.Wood
	u.Color = Color3.fromRGB(110, 104, 100)
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

-- trail cairn: stacked flat stones as wayfinding in high, low-visibility terrain
builders.Cairn = function()
	local p = {}
	local y = 0
	for i = 0, 4 do
		local s = 3.6 - i * 0.6
		local h = 1.1 - i * 0.08
		p[#p + 1] = Kit.part(nil, { Size = Vector3.new(s, h, s * 0.85), CFrame = CFrame.new(math.sin(i) * 0.2, y + h / 2, math.cos(i) * 0.2) * CFrame.Angles(0, i * 0.7, 0) })
		y += h * 0.9
	end
	local m = Instance.new("Model")
	m.Name = "Cairn"
	local u = Kit.union(p)
	u.Name = "Stones"
	u.Material = Enum.Material.Slate
	u.Color = COL.masonry
	u.Parent = m
	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

function Kit.proto(name)
	local f = protoFolder()
	local p = f:FindFirstChild(name)
	if not p then
		p = builders[name]()
		p.Parent = f
	end
	return p
end

-- place a prototype clone: ground position, yaw, uniform scale, optional leaf colour
function Kit.place(parent, name, pos, yaw, scale, leafColor, tilt)
	local m = Kit.proto(name):Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(scale)
	end
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0)
	if tilt then
		cf *= CFrame.Angles(tilt.X, 0, tilt.Z)
	end
	m:PivotTo(cf)
	if leafColor then
		local c = m:FindFirstChild("Canopy") or m:FindFirstChild("Leaves")
		if c then
			c.Color = leafColor
		end
	end
	m.Parent = parent
	return m
end

---------------------------------------------------------------- small props
function Kit.lantern(parent, pos, height, withLight)
	local m = Kit.model(parent, "Lantern")
	height = height or 7
	Kit.part(m, { Name = "Post", Size = Vector3.new(0.7, height, 0.7), CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
	Kit.part(m, { Name = "Arm", Size = Vector3.new(2.2, 0.4, 0.4), CFrame = CFrame.new(pos + Vector3.new(0.9, height - 0.3, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
	local cage = Kit.part(m, { Name = "Cage", Size = Vector3.new(1.1, 1.4, 1.1), CFrame = CFrame.new(pos + Vector3.new(1.7, height - 1.3, 0)), Material = Enum.Material.Metal, Color = COL.timberDark, Transparency = 0.15 })
	Kit.decor(cage)
	local glow = Kit.part(m, { Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = cage.CFrame, Material = Enum.Material.Neon, Color = COL.lantern })
	Kit.decor(glow)
	if withLight ~= false then
		local l = Instance.new("PointLight")
		l.Color = COL.lantern
		l.Range = 16
		l.Brightness = 1.2
		l.Shadows = false
		l.Parent = glow
	end
	return m
end

function Kit.sign(parent, cf, lines, width)
	width = width or 7
	local m = Kit.model(parent, "Sign")
	Kit.part(m, { Name = "Post", Size = Vector3.new(0.8, 7, 0.8), CFrame = cf * CFrame.new(0, 3.5, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
	for i, line in ipairs(lines) do
		local text, dir = line[1], line[2] or 0
		local board = Kit.part(m, { Name = "Board", Size = Vector3.new(width, 1.5, 0.35), CFrame = cf * CFrame.new(0, 6.6 - (i - 1) * 1.8, 0) * CFrame.Angles(0, dir, 0) * CFrame.new(width / 2 - 0.6, 0, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local g = Instance.new("SurfaceGui")
			g.Face = face
			g.CanvasSize = Vector2.new(width * 40, 60)
			g.LightInfluence = 1
			g.Parent = board
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Text = text
			t.Font = Kit.SIGN_FONT
			t.TextScaled = true
			t.TextColor3 = COL.golden
			t.Parent = g
		end
	end
	return m
end

function Kit.bench(parent, cf)
	local m = Kit.model(parent, "Bench")
	Kit.part(m, { Name = "Seat", Size = Vector3.new(6, 0.5, 1.8), CFrame = cf * CFrame.new(0, 1.8, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for _, x in ipairs({ -2.4, 2.4 }) do
		Kit.part(m, { Name = "Leg", Size = Vector3.new(0.6, 1.6, 1.6), CFrame = cf * CFrame.new(x, 0.8, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
	end
	return m
end

function Kit.campfire(parent, pos)
	local m = Kit.model(parent, "Campfire")
	local rng = Random.new(math.floor(pos.X + pos.Z))
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		local s = rng:NextNumber(1.2, 1.7)
		Kit.part(m, { Name = "Stone", Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 3, 0.4, math.sin(a) * 3)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), a, 0), Material = Enum.Material.Slate, Color = COL.masonry })
	end
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		local log = Kit.part(m, { Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.6, 0.8, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, a, math.rad(25)), Material = Enum.Material.Wood, Color = COL.timberDark })
		Kit.decor(log, true)
	end
	local core = Kit.part(m, { Name = "Core", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 1.2, 0)), Transparency = 1 })
	Kit.decor(core)
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 9
	fire.Color = COL.lantern
	fire.SecondaryColor = Color3.fromRGB(255, 120, 40)
	fire.Parent = core
	local l = Instance.new("PointLight")
	l.Color = COL.lantern
	l.Range = 26
	l.Brightness = 2
	l.Shadows = true
	l.Parent = core
	return m
end

-- Camp Locker (1-3 safe slots per master.md §0.5): sturdy chest with lantern-gold trim
function Kit.locker(parent, cf)
	local m = Kit.model(parent, "CampLocker")
	Kit.part(m, { Name = "Box", Size = Vector3.new(5, 3, 3), CFrame = cf * CFrame.new(0, 1.5, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	Kit.part(m, { Name = "Lid", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 3, 3), CFrame = cf * CFrame.new(0, 3, 0), Material = Enum.Material.WoodPlanks, Color = COL.timberDark })
	for _, x in ipairs({ -1.8, 1.8 }) do
		Kit.part(m, { Name = "Band", Size = Vector3.new(0.4, 3.2, 3.1), CFrame = cf * CFrame.new(x, 1.6, 0), Material = Enum.Material.Metal, Color = COL.lantern })
	end
	local lock = Kit.part(m, { Name = "Lock", Size = Vector3.new(0.8, 0.9, 0.3), CFrame = cf * CFrame.new(0, 2.6, -1.6), Material = Enum.Material.Neon, Color = COL.lantern })
	Kit.decor(lock)
	m:SetAttribute("CampLocker", true)
	return m
end

-- fence along points {Vector3}; posts every ~6 studs, two rails
function Kit.fence(parent, pts, height)
	height = height or 3.4
	local m = Kit.model(parent, "Fence")
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local len = (b - a).Magnitude
		local n = math.max(1, math.floor(len / 6))
		for k = 0, n - 1 do
			local p = a:Lerp(b, k / n)
			Kit.part(m, { Name = "Post", Size = Vector3.new(0.6, height + 1, 0.6), CFrame = CFrame.new(p + Vector3.new(0, (height + 1) / 2 - 1, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
		for _, h in ipairs({ height * 0.45, height * 0.9 }) do
			local r = cylAB(a + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0), 0.45)
			r.Name = "Rail"
			r.Material = Enum.Material.Wood
			r.Color = COL.timber
			r.Parent = m
		end
	end
	Kit.part(m, { Name = "Post", Size = Vector3.new(0.6, height + 1, 0.6), CFrame = CFrame.new(pts[#pts] + Vector3.new(0, (height + 1) / 2 - 1, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
	return m
end

-- straight wooden stair from a (bottom) to b (top), with side stringers
function Kit.stairs(parent, a, b, width)
	width = width or 10
	local m = Kit.model(parent, "Stairs")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local rise = b.Y - a.Y
	local steps = math.max(2, math.floor(math.abs(rise) / 1.2))
	local dir = flat.Unit
	local run = flat.Magnitude / steps
	local cf0 = CFrame.lookAt(a, a + dir)
	for i = 0, steps - 1 do
		local y = rise * (i + 0.5) / steps
		Kit.part(m, { Name = "Step", Size = Vector3.new(width, 1.2, run + 0.6), CFrame = cf0 * CFrame.new(0, y - 0.6, -(i + 0.5) * run), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	end
	for _, s in ipairs({ -1, 1 }) do
		local p0 = (cf0 * CFrame.new(s * (width / 2 + 0.3), 0, 0)).Position
		local p1 = (cf0 * CFrame.new(s * (width / 2 + 0.3), rise, -flat.Magnitude)).Position
		local str = cylAB(p0 + Vector3.new(0, 2.6, 0), p1 + Vector3.new(0, 2.6, 0), 0.5)
		str.Name = "Handrail"
		str.Material = Enum.Material.Wood
		str.Color = COL.timberDark
		str.Parent = m
		local n = math.max(2, math.floor(flat.Magnitude / 7))
		for k = 0, n do
			local p = p0:Lerp(p1, k / n)
			Kit.part(m, { Name = "Baluster", Size = Vector3.new(0.5, 3, 0.5), CFrame = CFrame.new(p + Vector3.new(0, 1.1, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
	end
	return m
end

-- arched plank bridge between a and b (deck surface points), stone abutments
function Kit.bridge(parent, a, b, width, arch, name)
	width = width or 12
	arch = arch or 6
	local m = Kit.model(parent, name or "Bridge")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = flat.Unit
	local len = flat.Magnitude
	local n = math.max(6, math.floor(len / 3))
	local function deckPoint(t)
		local p = a:Lerp(b, t)
		return p + Vector3.new(0, math.sin(t * math.pi) * arch, 0)
	end
	for i = 0, n - 1 do
		local p0, p1 = deckPoint(i / n), deckPoint((i + 1) / n)
		local mid = (p0 + p1) / 2
		local seg = (p1 - p0)
		local plank = Kit.part(m, { Name = "Plank", Size = Vector3.new(width, 0.9, seg.Magnitude + 0.15), CFrame = CFrame.lookAt(mid, p1) * CFrame.new(0, -0.45, 0), Material = Enum.Material.WoodPlanks, Color = (i % 2 == 0) and COL.timber or COL.timberDark })
		plank.Name = "Plank"
	end
	-- rails and posts
	local right = dir:Cross(Vector3.yAxis).Unit
	for _, s in ipairs({ -1, 1 }) do
		local prev
		for i = 0, n, 2 do
			local p = deckPoint(i / n) + right * s * (width / 2 - 0.4)
			Kit.part(m, { Name = "Post", Size = Vector3.new(0.7, 4, 0.7), CFrame = CFrame.new(p + Vector3.new(0, 1.6, 0)), Material = Enum.Material.Wood, Color = COL.timberDark })
			if prev then
				local r = cylAB(prev + Vector3.new(0, 3.4, 0), p + Vector3.new(0, 3.4, 0), 0.5)
				r.Name = "Rail"
				r.Material = Enum.Material.Wood
				r.Color = COL.timber
				r.Parent = m
			end
			prev = p
		end
	end
	-- abutments
	for _, e in ipairs({ { a, -1 }, { b, 1 } }) do
		local p, s = e[1], e[2]
		Kit.part(m, { Name = "Abutment", Size = Vector3.new(width + 3, 8, 5), CFrame = CFrame.lookAt(p, p + dir) * CFrame.new(0, -4.6, s * -1.5), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	end
	return m
end

-- timber cabin: plank walls, gable roof with overhang, stone chimney, warm windows
function Kit.cabin(parent, cf, w, d, h, opts)
	opts = opts or {}
	local m = Kit.model(parent, opts.name or "Cabin")
	-- stone plinth
	Kit.part(m, { Name = "Plinth", Size = Vector3.new(w + 1.2, 2.4, d + 1.2), CFrame = cf * CFrame.new(0, -0.4, 0), Material = Enum.Material.Cobblestone, Color = COL.masonry })
	-- walls (hollow box: floor, four walls with a door gap at the front)
	Kit.part(m, { Name = "Floor", Size = Vector3.new(w, 0.6, d), CFrame = cf * CFrame.new(0, 1.1, 0), Material = Enum.Material.WoodPlanks, Color = COL.timberDark })
	local wallT = 0.9
	local door = opts.doorWidth or 4
	Kit.part(m, { Name = "WallBack", Size = Vector3.new(w, h, wallT), CFrame = cf * CFrame.new(0, 0.8 + h / 2, d / 2 - wallT / 2), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	for _, s in ipairs({ -1, 1 }) do
		Kit.part(m, { Name = "WallSide", Size = Vector3.new(wallT, h, d), CFrame = cf * CFrame.new(s * (w / 2 - wallT / 2), 0.8 + h / 2, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
		local seg = (w - door) / 2
		Kit.part(m, { Name = "WallFront", Size = Vector3.new(seg, h, wallT), CFrame = cf * CFrame.new(s * (door / 2 + seg / 2), 0.8 + h / 2, -d / 2 + wallT / 2), Material = Enum.Material.WoodPlanks, Color = COL.timber })
		-- corner logs
		for _, z in ipairs({ -1, 1 }) do
			Kit.part(m, { Name = "Corner", Size = Vector3.new(1.4, h + 0.6, 1.4), CFrame = cf * CFrame.new(s * w / 2, 0.8 + h / 2, z * d / 2), Material = Enum.Material.Wood, Color = COL.timberDark })
		end
	end
	Kit.part(m, { Name = "Lintel", Size = Vector3.new(door + 0.4, h - 7, wallT), CFrame = cf * CFrame.new(0, 0.8 + 7 + (h - 7) / 2, -d / 2 + wallT / 2), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	-- windows (warm glow) on sides and front
	local wins = {}
	for _, s in ipairs({ -1, 1 }) do
		wins[#wins + 1] = cf * CFrame.new(s * (w / 2 + 0.05), 0.8 + h * 0.55, 0) * CFrame.Angles(0, math.rad(90), 0)
		wins[#wins + 1] = cf * CFrame.new(s * (door / 2 + (w - door) / 4), 0.8 + h * 0.55, -d / 2 - 0.05)
	end
	for _, wcf in ipairs(wins) do
		local g = Kit.part(m, { Name = "Window", Size = Vector3.new(2.6, 2.4, 0.3), CFrame = wcf, Material = Enum.Material.Neon, Color = COL.golden, Transparency = 0.15 })
		Kit.decor(g)
		Kit.part(m, { Name = "Frame", Size = Vector3.new(3.2, 0.4, 0.5), CFrame = wcf * CFrame.new(0, -1.4, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
		Kit.part(m, { Name = "Frame", Size = Vector3.new(3.2, 0.4, 0.5), CFrame = wcf * CFrame.new(0, 1.4, 0), Material = Enum.Material.Wood, Color = COL.timberDark })
	end
	-- gable roof (two slabs) + ridge beam + gable infills
	local rise = opts.roofRise or (w * 0.42)
	local over = 1.8
	local halfW = w / 2 + over
	local slope = math.atan2(rise, halfW)
	local slabLen = math.sqrt(halfW * halfW + rise * rise)
	local top = 0.8 + h
	for _, s in ipairs({ -1, 1 }) do
		Kit.part(m, { Name = "Roof", Size = Vector3.new(slabLen + 0.6, 1.1, d + over * 2), CFrame = cf * CFrame.new(s * halfW / 2, top + rise / 2 - 0.2, 0) * CFrame.Angles(0, 0, -s * slope), Material = Enum.Material.WoodPlanks, Color = opts.roofColor or COL.timberDark })
	end
	Kit.part(m, { Name = "Ridge", Size = Vector3.new(1.4, 1.4, d + over * 2 + 0.6), CFrame = cf * CFrame.new(0, top + rise + 0.2, 0), Material = Enum.Material.Wood, Color = COL.timber })
	for _, z in ipairs({ -1, 1 }) do
		for _, s in ipairs({ -1, 1 }) do
			Kit.wedge(m, { Name = "Gable", Size = Vector3.new(wallT, rise, w / 2), CFrame = cf * CFrame.new(s * w / 4, top + rise / 2, z * (d / 2 - wallT / 2)) * CFrame.Angles(0, s * math.rad(90), 0) * CFrame.Angles(0, math.rad(180), 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
		end
	end
	-- chimney
	if opts.chimney ~= false then
		local chim = Kit.part(m, { Name = "Chimney", Size = Vector3.new(3, h + rise + 3, 3), CFrame = cf * CFrame.new(w / 2 - 2.5, 0.8 + (h + rise + 3) / 2, d / 4), Material = Enum.Material.Cobblestone, Color = COL.masonry })
		local smoke = Instance.new("Smoke")
		smoke.Size = 3
		smoke.RiseVelocity = 4
		smoke.Opacity = 0.08
		smoke.Color = COL.moon
		local att = Instance.new("Attachment")
		att.Position = Vector3.new(0, chim.Size.Y / 2 + 0.5, 0)
		att.Parent = chim
		smoke.Parent = chim
	end
	-- warm interior light
	local core = Kit.part(m, { Name = "InteriorLight", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 0.8 + h * 0.7, 0), Transparency = 1 })
	Kit.decor(core)
	local l = Instance.new("PointLight")
	l.Color = COL.lantern
	l.Range = math.max(w, d) * 0.9
	l.Brightness = 1.4
	l.Shadows = false
	l.Parent = core
	return m
end

-- wooden viewing deck with rails; legs reach down to legY
function Kit.deck(parent, cf, w, d, legY, openSide)
	local m = Kit.model(parent, "Deck")
	Kit.part(m, { Name = "Floor", Size = Vector3.new(w, 1, d), CFrame = cf * CFrame.new(0, -0.5, 0), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	local top = cf.Position.Y
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local p = (cf * CFrame.new(sx * (w / 2 - 0.6), 0, sz * (d / 2 - 0.6))).Position
			local len = top - (legY or (top - 8))
			if len > 1 then
				Kit.part(m, { Name = "Leg", Size = Vector3.new(1.2, len, 1.2), CFrame = CFrame.new(p.X, top - len / 2 - 1, p.Z), Material = Enum.Material.Wood, Color = COL.timberDark })
			end
		end
	end
	local sides = {
		{ Vector3.new(-w / 2, 0, -d / 2), Vector3.new(w / 2, 0, -d / 2), "front" },
		{ Vector3.new(w / 2, 0, -d / 2), Vector3.new(w / 2, 0, d / 2), "right" },
		{ Vector3.new(w / 2, 0, d / 2), Vector3.new(-w / 2, 0, d / 2), "back" },
		{ Vector3.new(-w / 2, 0, d / 2), Vector3.new(-w / 2, 0, -d / 2), "left" },
	}
	for _, s in ipairs(sides) do
		if s[3] ~= openSide then
			Kit.fence(m, { (cf * CFrame.new(s[1])).Position, (cf * CFrame.new(s[2])).Position }, 3.4)
		end
	end
	return m
end

---------------------------------------------------------------- water FX
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"

-- waterfall curtain: scrolling beams down a lip, plus mist and splash at the pool
function Kit.waterfall(parent, lipCenter, outward, width, bottomY)
	local m = Kit.model(parent, "WaterfallFX")
	local right = outward:Cross(Vector3.yAxis).Unit
	local drop = lipCenter.Y - bottomY
	local anchor = Kit.part(m, { Name = "Anchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(lipCenter), Transparency = 1 })
	Kit.decor(anchor)
	local strands = math.max(3, math.floor(width / 7))
	for i = 0, strands - 1 do
		local off = (i / (strands - 1) - 0.5) * width
		-- parent before setting WorldPosition (otherwise it is stored as a local offset)
		local a0 = Instance.new("Attachment")
		a0.Parent = anchor
		a0.WorldPosition = lipCenter + right * off + outward * 8.5
		local a1 = Instance.new("Attachment")
		a1.Parent = anchor
		a1.WorldPosition = lipCenter + right * off * 1.06 + outward * 12 - Vector3.new(0, drop, 0)
		-- orient attachments so the beam faces outward
		a0.WorldAxis = outward
		a1.WorldAxis = outward
		local bm = Instance.new("Beam")
		bm.Attachment0, bm.Attachment1 = a0, a1
		bm.Texture = SMOKE_TEX
		bm.TextureMode = Enum.TextureMode.Wrap
		bm.TextureLength = 18
		bm.TextureSpeed = -2.2
		bm.Width0 = width / strands * 1.9
		bm.Width1 = width / strands * 2.3
		bm.FaceCamera = true -- ribbons stay visible from any angle (fixed-plane beams vanish edge-on)
		bm.LightEmission = 0.5
		bm.LightInfluence = 0.6
		bm.Color = ColorSequence.new(Color3.fromRGB(235, 252, 250), COL.turquoise)
		bm.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.85, 0.2),
			NumberSequenceKeypoint.new(1, 0.5),
		})
		bm.Segments = 4
		bm.CurveSize0 = 3
		bm.Parent = anchor
	end
	-- mist + splash at the base
	local base = Kit.part(m, { Name = "Splash", Size = Vector3.new(width, 1, 6), CFrame = CFrame.lookAt(Vector3.new(lipCenter.X, bottomY + 1, lipCenter.Z) + outward * 8, Vector3.new(lipCenter.X, bottomY + 1, lipCenter.Z) + outward * 9), Transparency = 1 })
	Kit.decor(base)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = SMOKE_TEX
	mist.Rate = 14
	mist.Lifetime = NumberRange.new(3, 5)
	mist.Speed = NumberRange.new(3, 6)
	mist.SpreadAngle = Vector2.new(40, 40)
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 22) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
	mist.Color = ColorSequence.new(Color3.fromRGB(240, 252, 252))
	mist.LightEmission = 0.2
	mist.Acceleration = Vector3.new(0, 1.5, 0)
	mist.Parent = base
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = SPARK_TEX
	splash.Rate = 22
	splash.Lifetime = NumberRange.new(0.6, 1.2)
	splash.Speed = NumberRange.new(10, 18)
	splash.SpreadAngle = Vector2.new(35, 35)
	splash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0.2) })
	splash.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	splash.Color = ColorSequence.new(Color3.fromRGB(240, 255, 255))
	splash.Acceleration = Vector3.new(0, -30, 0)
	splash.Parent = base
	return m
end

return Kit
