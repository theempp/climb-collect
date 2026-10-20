-- CC_TraverseClient (StarterPlayerScripts): client-side traversal mechanics. Character physics is
-- client-owned, so pushes and launches are applied here. Nothing here grants rewards, so there is
-- nothing for the server to trust yet.
-- Bounce caps (P2): parts tagged "CC_Bounce" launch the character when it lands on them, to
-- attribute Height (studs). Landing is the input, so there is no button to find on mobile.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local lastBounce = 0
local SQUISH = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

local function squish(cap)
	if cap:GetAttribute("Squishing") then
		return
	end
	cap:SetAttribute("Squishing", true)
	-- caps are upright cylinders, so their height is Size.X
	local t = TweenService:Create(cap, SQUISH, { Size = cap.Size * Vector3.new(0.7, 1.08, 1.08) })
	t.Completed:Once(function()
		cap:SetAttribute("Squishing", nil)
	end)
	t:Play()
end

RunService.Heartbeat:Connect(function()
	local ch = plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) or hum.Health <= 0 or os.clock() - lastBounce < 0.35 then
		return
	end
	rp.FilterDescendantsInstances = { ch }
	local reach = hum.HipHeight + hrp.Size.Y / 2 + 0.8
	local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -reach, 0), rp)
	local cap = hit and hit.Instance
	if cap and CollectionService:HasTag(cap, "CC_Bounce") and hrp.AssemblyLinearVelocity.Y <= 2 then
		local v = hrp.AssemblyLinearVelocity
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, math.sqrt(2 * workspace.Gravity * (cap:GetAttribute("Height") or 14)), v.Z)
		lastBounce = os.clock()
		squish(cap)
	end
end)
