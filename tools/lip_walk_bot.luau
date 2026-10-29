-- Lip-nest walk bot (dev tool, Client, playtest). Walks Shepherd's Road from the gate to s = S_LEAVE at SPEED_ROAD
-- (stuck check), then leaves the road and walks the PathfindingService line down to the lip nest at WalkSpeed 12.
-- Logs stuck targets, server-detected falls (CC_Fell attribute / respawn jumps) and the BOT time of the descent.
-- Poll _G.CC_LIP. Labels: road leg = stuck check only (speed > 12); descent leg = BOT time at 12.
local PFS = game:GetService("PathfindingService")
local plr = game.Players.LocalPlayer
local ch = plr.Character or plr.CharacterAdded:Wait()
local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
local cfg = _G.CC_LIP_CFG or {}
local S_LEAVE = cfg.sLeave or 5559
local SPEED_ROAD = cfg.speedRoad or 36
local NEST = cfg.nest or Vector3.new(-91, 376, 1632)

local L = { status = "running", log = {}, stuck = 0, jumps = 0 }
_G.CC_LIP = L
local function log(s)
	L.log[#L.log + 1] = string.format("%.1f %s", os.clock() - (L.t0 or os.clock()), s)
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function walk(p, speed, climb)
	local d0 = (p - hrp.Position).Magnitude
	local t0 = os.clock()
	local last = hrp.Position
	while os.clock() - t0 < d0 / speed * 2.5 + 2 do
		hum:MoveTo(p)
		if (flat(p) - flat(hrp.Position)).Magnitude < 3 and (not climb or math.abs(p.Y - hrp.Position.Y) < 4) then
			return true
		end
		if (hrp.Position - last).Magnitude > 60 then
			L.jumps += 1
			log(string.format("position jump %.0f studs (respawn?) at (%.0f,%.0f,%.0f)", (hrp.Position - last).Magnitude, hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
			return false
		end
		last = hrp.Position
		task.wait(0.1)
	end
	L.stuck += 1
	log(string.format("STUCK near (%.0f,%.0f,%.0f) -> (%.0f,%.0f,%.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z, p.X, p.Y, p.Z))
	return false
end

task.spawn(function()
	local pts = {}
	for x, y, z, s in game.ReplicatedStorage.CC_Route.Shepherd.Value:gmatch("([%-%d%.]+),([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		pts[#pts + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
	end
	L.t0 = os.clock()
	-- road leg (stuck check)
	hum.WalkSpeed = SPEED_ROAD
	if not cfg.skipRoad then
		ch:PivotTo(CFrame.new(pts[1].p + Vector3.new(0, 4, 0)))
		task.wait(2)
		for i = 1, #pts, 4 do
			if pts[i].s > S_LEAVE then
				break
			end
			L.where = string.format("road s=%.0f", pts[i].s)
			if not walk(pts[i].p, SPEED_ROAD) then
				ch:PivotTo(CFrame.new(pts[i].p + Vector3.new(0, 4, 0)))
				task.wait(1)
			end
		end
		L.roadSecs = os.clock() - L.t0
	end
	-- descent leg (BOT at 12)
	hum.WalkSpeed = 12
	local leave
	for _, q in ipairs(pts) do
		if q.s >= S_LEAVE then
			leave = q.p
			break
		end
	end
	if cfg.skipRoad then
		ch:PivotTo(CFrame.new(leave + Vector3.new(0, 4, 0)))
		task.wait(3)
	end
	local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true, WaypointSpacing = 6 })
	path:ComputeAsync(hrp.Position, NEST)
	L.pathStatus = tostring(path.Status)
	local t1 = os.clock()
	local fellBefore = plr:GetAttribute("CC_Falls") or 0
	for i, w in ipairs(path:GetWaypoints()) do
		L.where = "descent wp " .. i
		if w.Action == Enum.PathWaypointAction.Jump then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		local climb = w.Label == "Climb" or w.Action == Enum.PathWaypointAction.Custom
		if climb then
			L.climbs = (L.climbs or 0) + 1
		end
		if not walk(w.Position, 12, climb) then
			break
		end
	end
	L.descentSecs = os.clock() - t1
	L.reached = (hrp.Position - NEST).Magnitude < 14
	L.finalPos = string.format("%.0f,%.0f,%.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
	L.status = "done"
end)
return "lip walk started"
