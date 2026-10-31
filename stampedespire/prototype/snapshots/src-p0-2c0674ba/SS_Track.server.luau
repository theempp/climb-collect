-- Lays the mountain's collision once (ServerScriptService.SS_Track): hidden slabs that follow the
-- smoothed SS_Path, invisible side walls, the spawn and the summit plateau. The visible mountain is
-- Workspace.SS_Mountain (Blender meshes, art/). C.ShowGreybox shows the slabs as the old lane strip.
-- Herd and riding run on the client.
local RepS = game:GetService("ReplicatedStorage")
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

if workspace:FindFirstChild("SS_Track") then
	return
end

local folder = Instance.new("Folder")
folder.Name = "SS_Track"
local show = C.ShowGreybox

local function part(name, size, cf, color, parent, visible)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Transparency = (show and visible ~= false) and 0 or 1
	p.CastShadow = show
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or folder
	return p
end

local zoneFolders = {}
for k in C.Zones do
	local zf = Instance.new("Folder")
	zf.Name = string.format("Zone%d", k)
	zf.Parent = folder
	zoneFolders[k] = zf
end

-- Slabs: the top face sits on the path surface; width covers the lanes plus the berm.
local wallTop = P.Total
local step = C.CollisionStep
for d = -160, P.Total + 260, step do
	local dc = math.clamp(d + step / 2, 0, P.Total)
	local k = P.zoneOf(dc)
	local w = C.LaneCount * P.laneWidth(dc) + 2 * C.CollisionPad
	local a, b = P.surf(d, 0, 0), P.surf(d + step, 0, 0)
	local mid = a.Position:Lerp(b.Position, 0.5)
	local cf = CFrame.lookAt(mid, b.Position, a.UpVector:Lerp(b.UpVector, 0.5))
	local len = (b.Position - a.Position).Magnitude + 0.6
	part("Slab", Vector3.new(w, 2, len), cf * CFrame.new(0, -1, 0), C.Zones[k].Ground, zoneFolders[k])
	if d < wallTop then
		for _, side in { -1, 1 } do
			part("Wall", Vector3.new(2, C.WallHeight, len), cf * CFrame.new(side * (w / 2 + 1), C.WallHeight / 2, 0),
				Color3.fromRGB(150, 155, 165), zoneFolders[k], false)
		end
	end
end

local spawn = Instance.new("SpawnLocation")
spawn.Size = Vector3.new(6, 1, 6)
spawn.CFrame = P.surf(-30, 0, 0.5)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Parent = folder
for _, dcl in spawn:GetChildren() do
	if dcl:IsA("Decal") then
		dcl:Destroy()
	end
end

-- Summit plateau (the path is flat past Total + SummitFlat).
part("SummitPad", Vector3.new(230, 2, 230), P.surf(P.Total + 75, 0, -1), Color3.fromRGB(200, 205, 212))

folder.Parent = workspace
