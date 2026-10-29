-- Checkpoint tool (dev, edit mode). Paste into execute_luau (Edit) with NAME set; never overwrites.
-- Snapshot = whole-map TerrainRegion + World/Lighting/SpawnLocation clones + generator, core and runtime
-- sources + CC_Route, under ServerStorage.CC_Checkpoints/<NAME>. Same layout as the V3 checkpoints.
local NAME = _G.CC_CP_NAME or error("set _G.CC_CP_NAME first")
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SP = game:GetService("StarterPlayer")
local root = SS:WaitForChild("CC_Checkpoints")
assert(not root:FindFirstChild(NAME), "checkpoint exists: " .. NAME)

local f = Instance.new("Folder")
f.Name = NAME
local cells = Region3int16.new(Vector3int16.new(-720, -40, -720), Vector3int16.new(720, 870, 720))
local tr = workspace.Terrain:CopyRegion(cells)
tr.Name = "Terrain"
tr.Parent = f
local w = workspace:FindFirstChild("World")
if w then
	w:Clone().Parent = f
end
local sp = workspace:FindFirstChildOfClass("SpawnLocation")
if sp then
	sp:Clone().Parent = f
end
local lf = Instance.new("Folder")
lf.Name = "Lighting"
for _, c in ipairs(game:GetService("Lighting"):GetChildren()) do
	c:Clone().Parent = lf
end
lf.Parent = f
for _, src in ipairs({ SS:FindFirstChild("CC_Generators"), RS:FindFirstChild("CC_Route"), RS:FindFirstChild("CC_Core"), SSS:FindFirstChild("CC_CoreServer") }) do
	if src then
		src:Clone().Parent = f
	end
end
local rt = Instance.new("Folder")
rt.Name = "Runtime"
for _, s in ipairs(SSS:GetChildren()) do
	if s:IsA("BaseScript") then
		local c = s:Clone()
		c.Enabled = false
		c.Parent = rt
	end
end
for _, s in ipairs(SP.StarterPlayerScripts:GetChildren()) do
	if s:IsA("BaseScript") then
		local c = s:Clone()
		c.Enabled = false
		c.Parent = rt
	end
end
rt.Parent = f
f:SetAttribute("TakenAt", os.date("!%Y-%m-%dT%H:%M:%SZ"))
f.Parent = root
return NAME .. ": " .. #f:GetDescendants() .. " instances"
