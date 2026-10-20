-- Full-push measurement bot (dev tool, not part of the place). Paste into execute_luau on the CLIENT
-- during a playtest after setting PUSH/FROM/TO. It walks the main route (ReplicatedStorage.CC_Route)
-- from waypoint FROM to TO and runs every segment's recorded nodes on the way, in a background
-- thread. Poll _G.CC_BOT for progress. Times are BOT times: perfect inputs, no hesitation, no stops.
-- A target not reached in 8 s is logged as STUCK and skipped by teleport, so the run is flagged.
local PUSH, FROM, TO = "P1", "FootholdGate", "Camp1"

local plr = game.Players.LocalPlayer
local ch = plr.Character or plr.CharacterAdded:Wait()
local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = { ch }
local R = game.ReplicatedStorage:WaitForChild("CC_Route")

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function feet()
	return hrp.Position.Y - hum.HipHeight - hrp.Size.Y / 2
end

local B = { status = "running", log = {}, stuck = 0 }
_G.CC_BOT = B

local function go(target, flag, timeout, ytol)
	local t0 = os.clock()
	local jumped = false
	while os.clock() - t0 < timeout do
		hum:MoveTo(target)
		local to = flat(target - hrp.Position)
		local d = to.Magnitude
		if (flag == 1 or flag == 3) and not jumped and d > 1 and hum.FloorMaterial ~= Enum.Material.Air then
			-- jump at a ledge (no floor ahead) or in front of a step-up taller than a stride
			if not workspace:Raycast(hrp.Position + to.Unit * 1.2, Vector3.new(0, -5.5, 0), rp) or (target.Y - feet() > 1.5 and d < 6.5) then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				jumped = true
			end
		end
		-- bounce caps (flag 3) launch on landing, so arrival is horizontal only
		if (d < (flag == 0 and ytol and 3 or 2) and math.abs(feet() - target.Y) < (ytol or 2.5)) or (flag == 3 and d < 2.5) then
			return true
		end
		task.wait()
	end
	return false
end

local route = {}
for tok in string.gmatch(R.Main.Value, "[^;]+") do
	local x, y, z, s = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
	route[#route + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
end
local s0, s1 = R:GetAttribute(FROM) or 0, R:GetAttribute(TO)
local segs = {}
for _, m in ipairs(workspace.World.Traverse[PUSH]:GetChildren()) do
	if m:IsA("Model") and m:GetAttribute("StartS") and m:FindFirstChild("Nodes") then
		segs[#segs + 1] = m
	end
end
table.sort(segs, function(a, b)
	return a:GetAttribute("StartS") < b:GetAttribute("StartS")
end)

task.spawn(function()
	local first
	for _, r in ipairs(route) do
		if r.s >= s0 then
			first = r
			break
		end
	end
	hrp.CFrame = CFrame.new(first.p + Vector3.new(0, 4, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	task.wait(4)
	local T0 = os.clock()
	local k = 1
	local function stuck(what, p)
		B.stuck += 1
		B.log[#B.log + 1] = string.format("STUCK %s at s~%.0f (%.0f,%.0f,%.0f)", what, B.s or -1, hrp.Position.X, feet(), hrp.Position.Z)
		hrp.CFrame = CFrame.new(p + Vector3.new(0, 4, 0))
		hrp.AssemblyLinearVelocity = Vector3.zero
		task.wait(1)
	end
	for _, r in ipairs(route) do
		if r.s >= s0 and r.s <= s1 then
			local seg = segs[k]
			if seg and r.s >= seg:GetAttribute("StartS") - 1 then
				-- run the segment
				local tA = os.clock()
				local start = seg:GetAttribute("StartPos")
				if not go(start, 0, 8, 4) then
					stuck(seg.Name .. " start", start)
				end
				for tok in string.gmatch(seg.Nodes.Value, "[^;]+") do
					local x, y, z, f = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
					local p = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
					if not go(p, tonumber(f), 10) then
						stuck(seg.Name .. " node", p)
					end
				end
				B.log[#B.log + 1] = string.format("%s %.1fs (trail-walk %.1fs)", seg.Name, os.clock() - tA, (seg:GetAttribute("EndS") - seg:GetAttribute("StartS")) / hum.WalkSpeed)
				k += 1
			elseif k == 1 or r.s > segs[k - 1]:GetAttribute("EndS") then
				B.s = r.s
				if not go(r.p, 0, 8, 4) then
					stuck("trail", r.p)
				end
			end
			B.t = os.clock() - T0
		end
	end
	B.total = os.clock() - T0
	B.status = "done"
end)
return string.format("bot started: %s %s(%.0f) -> %s(%.0f), %d segments, %d route samples", PUSH, FROM, s0, TO, s1, #segs, #route)
