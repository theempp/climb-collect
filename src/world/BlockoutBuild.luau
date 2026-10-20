-- BlockoutBuild: Gate B placeholders (bridges over detected crossings, camp beacons).
-- Everything here lives in Workspace.World.Blockout and is replaced by authored builds later.
local B = {}

local WOOD = Color3.fromRGB(140, 96, 60) -- §3 "timber"
local LANTERN = Color3.fromRGB(255, 178, 72) -- lanternGold

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
B.folder = folder

-- straight plank deck between two path samples (x, z, y) with rails
local function deck(parent, a, b, width, name)
	local pa = Vector3.new(a[1], a[3], a[2])
	local pb = Vector3.new(b[1], b[3], b[2])
	local mid = (pa + pb) / 2
	local len = (pb - pa).Magnitude + 6
	local cf = CFrame.lookAt(mid, pb) * CFrame.new(0, -0.6, 0)
	local m = Instance.new("Model")
	m.Name = name
	part({ Name = "Deck", Size = Vector3.new(width, 1.2, len), CFrame = cf, Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = m })
	for _, side in ipairs({ -1, 1 }) do
		part({ Name = "Rail", Size = Vector3.new(0.6, 0.6, len), CFrame = cf * CFrame.new(side * (width / 2 - 0.3), 3.2, 0), Material = Enum.Material.Wood, Color = WOOD, Parent = m })
		local posts = math.max(2, math.floor(len / 10))
		for i = 0, posts do
			local z = -len / 2 + len * i / posts
			part({ Name = "Post", Size = Vector3.new(0.7, 3.4, 0.7), CFrame = cf * CFrame.new(side * (width / 2 - 0.3), 1.7, z), Material = Enum.Material.Wood, Color = WOOD, Parent = m })
		end
	end
	m:SetAttribute("Blockout", true)
	m.Parent = parent
	return m
end

function B.build()
	local P = _G.CC_PATHS
	local world = folder(workspace, "World")
	local bo = world:FindFirstChild("Blockout")
	if bo then
		bo:Destroy()
	end
	bo = folder(world, "Blockout")
	local bridges = folder(bo, "Bridges")
	local n = 0
	for _, c in ipairs(P.crossings) do
		local pts = c.path == "Main" and P.main or P.rings[c.path]
		local a = pts[math.max(1, c.i0 - 3)]
		local b = pts[math.min(#pts, c.i1 + 3)]
		n += 1
		deck(bridges, a, b, c.path == "Main" and 12 or 9, string.format("%s_Bridge_%d", c.path, n))
	end
	local camps = folder(bo, "CampBeacons")
	for _, name in ipairs({ "Camp1", "Camp2", "Camp3", "Camp4" }) do
		local pad = P.pads[name]
		local m = Instance.new("Model")
		m.Name = name .. "_Beacon"
		part({ Name = "Post", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 2.4, 2.4),
			CFrame = CFrame.new(pad.x, pad.y + 7, pad.z) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Wood, Color = WOOD, Parent = m })
		local lamp = part({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3),
			CFrame = CFrame.new(pad.x, pad.y + 15, pad.z), Material = Enum.Material.Neon, Color = LANTERN, CanCollide = false, Parent = m })
		local light = Instance.new("PointLight")
		light.Color = LANTERN
		light.Range = 24
		light.Brightness = 1.5
		light.Parent = lamp
		m:SetAttribute("Blockout", true)
		m.Parent = camps
	end
	return n
end

return B
