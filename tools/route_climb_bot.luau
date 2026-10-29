-- Route climb bot (dev tool, Client, playtest; v4 P3 run 2). Follows ReplicatedStorage.CC_Track.<route> (JSON
-- segments written by ClimbKit / LedgeP1) and walks ReplicatedStorage.CC_Route.<route> between segments. Drives
-- CC_ClimbClient through its Studio-only hooks (CC_BotMove / CC_BotJump), i.e. the same controller a player uses;
-- walking = Humanoid:MoveTo at WalkSpeed 12. All times are BOT times (perfect input).
-- Synced to ReplicatedStorage.CC_DevTools.RouteClimbBot. Client:
--   _G.CC_RBOT_CFG = { route = "Ledge", seg = "forest" }          -- one segment (teleport to its start)
--   _G.CC_RBOT_CFG = { route = "Ledge", s0 = 0, s1 = 12286 }      -- a stretch of the route incl. walking
--   _G.CC_RBOT_CFG = { ..., runs = 5, descend = true }            -- descend = also climb the segment back down
--   require(game.ReplicatedStorage.CC_DevTools.RouteClimbBot:Clone()); poll _G.CC_RBOT (back-to-back calls:
--   MCP client threads only run while a call is active)
local HS = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local plr = game.Players.LocalPlayer
local cfg = _G.CC_RBOT_CFG or {}
local B = { status = "running", runs = {} }
_G.CC_RBOT = B

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function V(t)
	return Vector3.new(t[1], t[2], t[3])
end

local function loadRoute(name)
	local sv = RS:WaitForChild("CC_Route"):FindFirstChild(name)
	local pts = {}
	for tok in string.gmatch(sv and sv.Value or "", "[^;]+") do
		local x, y, z, s = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		pts[#pts + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
	end
	return pts
end
local function loadTrack(name)
	local sv = RS:WaitForChild("CC_Track"):FindFirstChild(name)
	return sv and HS:JSONDecode(sv.Value) or {}
end

local function run(idx)
	local ch = plr.Character or plr.CharacterAdded:Wait()
	local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
	hum.WalkSpeed = 12
	local R = { i = idx, splits = {}, stuck = 0, log = {}, handsOn = 0, rest = 0, lunges = 0 }
	B.cur = R
	local t0 = os.clock()
	local function log(s)
		R.log[#R.log + 1] = string.format("%.1f %s (%.0f,%.0f,%.0f)", os.clock() - t0, s, hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
	end
	local function mark(k)
		R.splits[#R.splits + 1] = string.format("%s %.1f", k, os.clock() - t0)
	end
	local function state()
		return ch:GetAttribute("CC_ClimbState") or "none"
	end
	local fall0 = plr:GetAttribute("CC_Falls") or 0
	local dropped = false
	-- same rule as CC_CheckpointService: a landing more than 24 studs below the last grounded height (0.25 s
	-- samples) is a fall, whether or not a checkpoint is set (walking down a slope is not)
	local lastG, acc = nil, 0
	local armed = false -- off during start-up teleports
	local fallConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
		-- v6: time on a face / ladder / slab (the controller's climb state), the "hands-on" share's strict half
		if armed and (ch:GetAttribute("CC_ClimbState") or "none") ~= "none" then
			R.face = (R.face or 0) + dt
		end
		acc += dt
		if acc < 0.25 or not armed then
			return
		end
		acc = 0
		if hum.FloorMaterial ~= Enum.Material.Air and (ch:GetAttribute("CC_ClimbState") or "none") == "none" then
			local y = hrp.Position.Y
			if lastG and lastG - y > 24 then
				dropped = true
				R.log[#R.log + 1] = string.format("%.1f FALL %.0f (%.0f,%.0f,%.0f)", os.clock() - t0, lastG - y, hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
			end
			lastG = y
		elseif (ch:GetAttribute("CC_ClimbState") or "none") ~= "none" then
			lastG = nil -- climbing moves are not falls; the next grounded sample starts fresh
		end
	end)
	local function fell()
		return dropped or (plr:GetAttribute("CC_Falls") or 0) > fall0
	end
	local function walk(p, tmax)
		local t1 = os.clock()
		local d0 = (flat(p) - flat(hrp.Position)).Magnitude
		tmax = tmax or d0 / 12 * 2.2 + 3
		local jumped = false
		local lastP, lastT = hrp.Position, os.clock()
		while os.clock() - t1 < tmax do
			if state() ~= "none" then
				-- grabbed something on the way (a marked wall beside the path): let go and keep walking
				ch:SetAttribute("CC_BotRelease", (ch:GetAttribute("CC_BotRelease") or 0) + 1)
				task.wait(0.5)
			end
			hum:MoveTo(p)
			if (flat(p) - flat(hrp.Position)).Magnitude < 2.2 then
				return true
			end
			if os.clock() - lastT > 1.2 then
				if (hrp.Position - lastP).Magnitude < 1 and not jumped and hum.FloorMaterial ~= Enum.Material.Air then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
					jumped = true
				end
				lastP, lastT = hrp.Position, os.clock()
			end
			task.wait(0.05)
		end
		R.stuck += 1
		log(string.format("STUCK walking -> (%.0f,%.0f,%.0f)", p.X, p.Y, p.Z))
		return false
	end
	-- push into the face until grabbed; hold dir (default: into = up) until the controller lets go (mantle / step off)
	local function climb(into, dir, tmax, label, canLunge, at)
		local t1 = os.clock()
		ch:SetAttribute("CC_BotMove", into)
		while state() == "none" and os.clock() - t1 < 3 do
			-- push into the face from the approach point (re-centres on narrow faces such as ladders)
			local base = at and Vector3.new(at.X, hrp.Position.Y, at.Z) or hrp.Position
			hum:MoveTo(base + into * 3)
			task.wait(0.05)
		end
		if state() == "none" then
			ch:SetAttribute("CC_BotMove", Vector3.zero)
			R.stuck += 1
			log("NO GRAB " .. label)
			return false
		end
		-- sideways moves are projected onto the face plane each tick (a slight "away from the wall" component reads
		-- as stepping off when there is floor right below)
		local function onFace(d)
			-- the face's own normal from the track (the character's look lags the grab by a few frames)
			local look = Vector3.new(into.X, 0, into.Z).Unit
			local p = d - look * d:Dot(look)
			return (p.Magnitude > 0.1) and p.Unit or d
		end
		ch:SetAttribute("CC_BotMove", dir and onFace(dir) or into)
		local lastY, lastT = hrp.Position, os.clock()
		local grabT = os.clock()
		-- stalled on the face: Jump = lunge, as a player would (at a marked blank band after 0.6 s, anywhere else
		-- only after 1.5 s without progress; an eager lunge near a top edge throws the climber off the line)
		local wait = canLunge and 0.6 or 1e9 -- only marked lunge faces get a lunge
		local ticks = 0
		local rpL = RaycastParams.new()
		rpL.FilterDescendantsInstances = { ch }
		while state() ~= "none" and os.clock() - t1 < (tmax or 40) do
			task.wait(0.05)
			if dir then
				ch:SetAttribute("CC_BotMove", onFace(dir))
			else
				-- on a ladder, steer back toward its centre line (a grab at the grip's side edge stalled the climb;
				-- a player steers the same way)
				local f = Vector3.new(into.X, 0, into.Z).Unit
				local hit = workspace:Raycast(hrp.Position, f * 4, rpL)
				local mv = into
				if hit and hit.Instance.Name == "LadderGrip" then
					local x = hit.Instance.CFrame:PointToObjectSpace(hrp.Position).X
					if math.abs(x) > 0.8 then
						mv = (into + hit.Instance.CFrame.RightVector * (-math.sign(x) * 0.6)).Unit
					end
				end
				ch:SetAttribute("CC_BotMove", mv)
			end
			ticks += 1
			if cfg.debug and ticks <= 3 then
				local lv = hrp.CFrame.LookVector
				log(string.format("dbg %s t%d st=%s move=%s look=(%.2f,%.2f) why=%s", label, ticks, state(), tostring(ch:GetAttribute("CC_BotMove")), lv.X, lv.Z, tostring(ch:GetAttribute("CC_DetachWhy"))))
			end
			if os.clock() - lastT > wait then
				if state() == "climb" and os.clock() - grabT > 1 and (hrp.Position - lastY).Magnitude < 0.3 then
					ch:SetAttribute("CC_BotJump", (ch:GetAttribute("CC_BotJump") or 0) + 1)
					R.lunges += 1
				end
				lastY, lastT = hrp.Position, os.clock()
			end
		end
		ch:SetAttribute("CC_BotMove", Vector3.zero)
		if state() ~= "none" then
			R.stuck += 1
			log("STUCK on face " .. label)
			return false
		end
		if cfg.verbose then
			log(string.format("off %s after %.1f s (%s)", label, os.clock() - t1, tostring(ch:GetAttribute("CC_DetachWhy"))))
		end
		return true
	end
	-- v6: jump to p (gap jumps, rock steps, stepping stones): walk toward p and jump when grounded with no floor 1.3
	-- ahead (a gap's lip) or a block at knee height ahead (a step), as a player would
	local rpJ = RaycastParams.new()
	rpJ.FilterType = Enum.RaycastFilterType.Exclude
	rpJ.FilterDescendantsInstances = { ch }
	local function jumpTo(p)
		local t1 = os.clock()
		local lastJ = 0
		local d0 = (flat(p) - flat(hrp.Position)).Magnitude
		while os.clock() - t1 < d0 / 12 * 2 + 4 do
			if fell() then
				return false
			end
			hum:MoveTo(p)
			local pos = hrp.Position
			local hd = (flat(p) - flat(pos)).Magnitude
			local grounded = hum.FloorMaterial ~= Enum.Material.Air
			if grounded and hd < 1.8 and math.abs(pos.Y - p.Y) < 3 then
				return true
			end
			if grounded and os.clock() - lastJ > 0.45 then
				local dir = flat(p - pos)
				dir = (dir.Magnitude > 0.1) and dir.Unit or Vector3.zero
				local edge = not workspace:Raycast(pos + dir * 1.3, Vector3.new(0, -5, 0), rpJ)
				local wall = workspace:Raycast(pos + Vector3.new(0, -1.6, 0), dir * 2.4, rpJ)
				if edge or wall or (p.Y > pos.Y + 1.5 and hd < 4.5) then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
					lastJ = os.clock()
					R.jumps = (R.jumps or 0) + 1
				end
			end
			task.wait(0.03)
		end
		R.stuck += 1
		log(string.format("STUCK jump -> (%.0f,%.0f,%.0f)", p.X, p.Y, p.Z))
		return false
	end
	local function hazardWait(path)
		local m = workspace
		for seg in string.gmatch(path, "[^%.]+") do
			if m ~= workspace or seg ~= "Workspace" then
				m = m and m:FindFirstChild(seg)
			end
		end
		if not m then
			return 0
		end
		local per, tell, off = m:GetAttribute("Period"), m:GetAttribute("Tell"), m:GetAttribute("Offset") or 0
		local w0 = os.clock()
		while os.clock() - w0 < per + 1 do
			local ph = (workspace:GetServerTimeNow() + off) % per
			if ph > tell + 1.5 and ph < per - 2.5 then
				break
			end
			task.wait(0.05)
		end
		return os.clock() - w0
	end
	local function restIfLow()
		local st = ch:GetAttribute("CC_Stamina") or 100
		if st < 35 then
			local w0 = os.clock()
			while (ch:GetAttribute("CC_Stamina") or 100) < 85 and os.clock() - w0 < 12 do
				task.wait(0.1)
			end
			R.rest += os.clock() - w0
		end
	end
	local lastWalk
	local function doNodes(seg, from)
		local ns = seg.nodes
		for ni = from or 1, #ns do
			local n = ns[ni]
			if fell() then
				log("fell before node " .. ni)
				return false
			end
			if n.k == "walk" then
				lastWalk = V(n.p)
				local y0 = hrp.Position.Y
				walk(V(n.p))
				if cfg.verbose and hrp.Position.Y < y0 - 6 then
					log(string.format("DROP %.0f at node %d", y0 - hrp.Position.Y, ni))
				end
			elseif n.k == "climb" then
				restIfLow()
				if not climb(V(n.into), n.dir and V(n.dir) or nil, 45, n.label, n.lunge, lastWalk) then
					return false
				end
			elseif n.k == "jump" then
				lastWalk = V(n.p)
				if not jumpTo(V(n.p)) then
					return false
				end
			elseif n.k == "wait" then
				R.waits = (R.waits or 0) + hazardWait(n.hz)
			elseif n.k == "descend" then
				-- hang lines: walk off the face top (the controller's descend grab takes the face), then pull away from
				-- the wall (= climb down) until the controller steps off onto the ledge
				local at, out = V(n.at), V(n.out)
				walk(at)
				local t1 = os.clock()
				ch:SetAttribute("CC_BotMove", Vector3.zero)
				while state() == "none" and os.clock() - t1 < 3 do
					hum:MoveTo(at + out * 8)
					task.wait(0.05)
				end
				if state() == "none" then
					R.stuck += 1
					log("NO DESCEND GRAB " .. n.label)
					return false
				end
				ch:SetAttribute("CC_BotMove", out)
				while state() ~= "none" and os.clock() - t1 < 30 do
					task.wait(0.05)
				end
				ch:SetAttribute("CC_BotMove", Vector3.zero)
				if state() ~= "none" then
					R.stuck += 1
					log("STUCK descending " .. n.label)
					return false
				end
				if cfg.verbose then
					log(string.format("down %s after %.1f s (%s)", n.label, os.clock() - t1, tostring(ch:GetAttribute("CC_DetachWhy"))))
				end
			end
		end
		return not fell()
	end
	local function walkRoute(pts, s0, s1)
		local lastS = -1e9
		for _, q in ipairs(pts) do
			if q.s >= s0 and q.s <= s1 and q.s - lastS >= (cfg.routeStep or 6) then
				lastS = q.s
				walk(q.p + Vector3.new(0, 3, 0))
				if fell() then
					return false
				end
			end
		end
		return true
	end

	local dev = RS:FindFirstChild("CC_Remotes") and RS.CC_Remotes:FindFirstChild("DevRequest")
	if dev then
		dev:FireServer("setCheckpoint", {})
		task.wait(0.4)
	end
	local route = cfg.route or "Ledge"
	local pts = loadRoute(route)
	local track = loadTrack(route)
	local ctr0 = {}
	for _, k in ipairs({ "CC_Grabs", "CC_Slips", "CC_Catches", "CC_Misses", "CC_Lunges", "CC_DescendGrabs" }) do
		ctr0[k] = ch:GetAttribute(k) or 0
	end
	local ok = true
	if cfg.seg then
		local seg
		for _, s in ipairs(track) do
			if s.id == cfg.seg then
				seg = s
			end
		end
		assert(seg, "no segment " .. tostring(cfg.seg))
		if cfg.fromLabel then
			for i, n in ipairs(seg.nodes) do
				if n.label == cfg.fromLabel then
					cfg.from = i - 1
					if n.k == "climb" and seg.nodes[i - 1] and seg.nodes[i - 1].k == "wait" then
						cfg.from = i - 2
					end
				end
			end
		end
		local first = seg.nodes[cfg.from or 1]
		local start = cfg.at and V(cfg.at) or V(first.p) + Vector3.new(0, 2, 0)
		ch:PivotTo(CFrame.new(start))
		task.wait(1.5)
		lastG, armed = nil, true
		t0 = os.clock()
		ok = doNodes(seg, cfg.from)
		mark("seg " .. seg.id)
		R.handsOn = os.clock() - t0
	else
		local s0, s1 = cfg.s0 or 0, cfg.s1 or 1e9
		local startP
		for _, q in ipairs(pts) do
			if q.s >= s0 then
				startP = q.p
				break
			end
		end
		ch:PivotTo(CFrame.new(startP + Vector3.new(0, 4, 0)))
		task.wait(2)
		lastG, armed = nil, true
		t0 = os.clock()
		local cur = s0
		for _, seg in ipairs(track) do
			if ok and seg.s1 > s0 and seg.s0 < s1 then
				ok = walkRoute(pts, cur, seg.s0)
				mark("at " .. seg.id)
				local h0 = os.clock()
				ok = ok and doNodes(seg)
				R.handsOn += os.clock() - h0
				mark("done " .. seg.id)
				cur = seg.s1
			end
		end
		if ok then
			ok = walkRoute(pts, cur, s1)
		end
	end
	fallConn:Disconnect()
	R.total = os.clock() - t0
	R.result = ok and "ok" or (fell() and "fell" or "failed")
	R.falls = (plr:GetAttribute("CC_Falls") or 0) - fall0
	for k, v in pairs(ctr0) do
		R[k] = (ch:GetAttribute(k) or 0) - v
	end
	R.endAt = string.format("(%.0f,%.0f,%.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
	return R
end

-- floor audit (cfg.audit = "<segment id>"): every 2 studs between consecutive walk nodes, the floor under the
-- walking line and 1.5 studs either side of it; reports holes (no floor within 6 below) and drops (> 2.5 below
-- the node height). Run in a playtest (edit-mode raycasts lag behind fresh voxel writes).
if cfg.audit then
	local ch = plr.Character or plr.CharacterAdded:Wait()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { ch, workspace.CurrentCamera }
	local bad, n = {}, 0
	local dev = RS:FindFirstChild("CC_Remotes") and RS.CC_Remotes:FindFirstChild("DevRequest")
	for _, seg in ipairs(loadTrack(cfg.route or "Ledge")) do
		if seg.id == cfg.audit or cfg.audit == "*" then
			-- stream the segment in (StreamingEnabled): stand at its first node for a few seconds
			if dev then
				dev:FireServer("setCheckpoint", {})
			end
			ch:PivotTo(CFrame.new(V(seg.nodes[1].p) + Vector3.new(0, 3, 0)))
			task.wait(cfg.streamWait or 5)
			local prev
			for ni, nd in ipairs(seg.nodes) do
				if nd.k == "walk" then
					local p = V(nd.p)
					if prev and (p - prev).Magnitude < 40 and math.abs(p.Y - prev.Y) < 2 then
						local d = (p - prev).Magnitude
						local side = flat(p - prev).Magnitude > 0.1 and flat(p - prev).Unit:Cross(Vector3.yAxis) or Vector3.xAxis
						for k = 0, math.floor(d / 2) do
							local q = prev:Lerp(p, k * 2 / math.max(d, 0.01))
							for _, off in ipairs({ -1.5, 0, 1.5 }) do
								local qq = q + side * off
								local r = workspace:Raycast(qq + Vector3.new(0, 2, 0), Vector3.new(0, -9, 0), rp)
								n += 1
								local fy = r and r.Position.Y
								-- a ray that starts inside the wall finds nothing: not a hole
								local inWall = not r and workspace:Raycast(q + Vector3.new(0, -1, 0), side * off * 1.1, rp) ~= nil
								if not inWall and (not fy or fy < q.Y - 3 - 2.5) then
									bad[#bad + 1] = string.format("%s n%d off%.1f (%.0f,%.0f,%.0f) %s", seg.id, ni, off, qq.X, qq.Y, qq.Z, fy and string.format("floor %.1f", fy) or "HOLE")
								end
							end
						end
					end
					prev = p
				elseif nd.k == "climb" then
					prev = nil
				end
			end
		end
	end
	B.audit = { samples = n, bad = bad }
	B.status = "done"
	return "audit done"
end

task.spawn(function()
	for i = 1, cfg.runs or 1 do
		B.where = "run " .. i
		local ok, r = pcall(run, i)
		B.runs[#B.runs + 1] = ok and r or { i = i, result = "error", err = tostring(r) }
		task.wait(1)
	end
	B.status = "done"
end)
return "route climb bot started"
