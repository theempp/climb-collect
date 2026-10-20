-- Measurement bot (dev tool, not part of the place). Paste into execute_luau on the CLIENT during a
-- playtest, after setting PUSH and SEGS below. It follows each segment's recorded "Nodes"
-- (flag 0 walk, 1 jump, 2 climb, 3 bounce cap) with Humanoid:MoveTo. Jumps are timed by a ledge check (no floor
-- 1.2 studs ahead), like a player would time them. Results are BOT times (perfect, no hesitation),
-- a lower bound for skilled players, not a human measurement.
local PUSH = "P1"
local SEGS = { "1a_MeadowBoulderHop", "1b_ShepherdsStep", "1c_LookoutRocks" }

local plr = game.Players.LocalPlayer
local ch = plr.Character or plr.CharacterAdded:Wait()
local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = { ch }

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function feet()
	return hrp.Position.Y - hum.HipHeight - hrp.Size.Y / 2
end

local function go(target, flag, timeout)
	local t0 = os.clock()
	local jumped = false
	local minY = feet()
	while os.clock() - t0 < timeout do
		hum:MoveTo(target)
		local to = flat(target - hrp.Position)
		local d = to.Magnitude
		minY = math.min(minY, feet())
		if (flag == 1 or flag == 3) and not jumped and d > 1 and hum.FloorMaterial ~= Enum.Material.Air then
			local ahead = hrp.Position + to.Unit * 1.2
			-- jump at a ledge (no floor ahead) or in front of a step-up taller than a stride
			if not workspace:Raycast(ahead, Vector3.new(0, -5.5, 0), rp) or (target.Y - feet() > 1.5 and d < 6.5) then
				hum:ChangeState(Enum.HumanoidStateType.Jumping) -- hum.Jump is overwritten by the ControlModule
				jumped = true
			end
		end
		-- bounce caps (flag 3) launch on landing, so arrival is horizontal only
		if (d < 2 and math.abs(feet() - target.Y) < 2.5) or (flag == 3 and d < 2.5) then
			return true, os.clock() - t0, minY
		end
		task.wait()
	end
	return false, os.clock() - t0, minY
end

local function parse(seg)
	local nodes = {}
	for tok in string.gmatch(seg.Nodes.Value, "[^;]+") do
		local x, y, z, f = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		nodes[#nodes + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), f = tonumber(f) }
	end
	return nodes
end

local out = {}
for _, name in ipairs(SEGS) do
	local seg = workspace.World.Traverse[PUSH]:WaitForChild(name, 10)
	local nodes = parse(seg)
	local start = seg:GetAttribute("StartPos")
	local d0 = flat(nodes[1].p - start).Unit
	hrp.CFrame = CFrame.lookAt(start - d0 * 12 + Vector3.new(0, 4, 0), start + Vector3.new(0, 4, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	task.wait(3) -- let streaming load the segment
	go(start, 0, 10)
	local T0 = os.clock()
	local log, ok = {}, true
	for k, n in ipairs(nodes) do
		local good, dt, minY = go(n.p, n.f, 15)
		log[#log + 1] = string.format("%d%s%.1f", k, good and ":" or ":FAIL@", dt)
		if minY < n.p.Y - 4 and k > 1 then
			log[#log] ..= "(dip)"
		end
		if not good then
			ok = false
			break
		end
	end
	local total = os.clock() - T0
	local trail = (seg:GetAttribute("EndS") - seg:GetAttribute("StartS")) / hum.WalkSpeed
	out[#out + 1] = string.format("%s: %s bot %.1fs vs trail-walk %.1fs (+%.1fs) [%s]", name, ok and "OK" or "FAILED", total, trail, total - trail, table.concat(log, " "))
end
return table.concat(out, "\n")
