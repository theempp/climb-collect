-- Ledge P1 bot (dev tool, Client, playtest). Drives CC_ClimbClient through its Studio-only hooks (CC_BotMove /
-- CC_BotJump), i.e. the same controller a player uses; walking uses Humanoid:MoveTo at WalkSpeed 12 (BOT timing).
-- Synced to ReplicatedStorage.CC_DevTools.LedgeBot. Client: _G.CC_LBOT_CFG = { fromGate = true, runs = 1 };
-- require(game.ReplicatedStorage.CC_DevTools.LedgeBot:Clone()); poll _G.CC_LBOT
-- with back-to-back calls (MCP client threads only run during a call). Results per run: total, splits, stuck,
-- grabs/slips/catches/misses/lunges, falls (server CC_Falls), reached.
local PFS = game:GetService("PathfindingService")
local plr = game.Players.LocalPlayer
local cfg = _G.CC_LBOT_CFG or {}
local B = { status = "running", runs = {}, log = {} }
_G.CC_LBOT = B

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function run(idx)
	local ch = plr.Character or plr.CharacterAdded:Wait()
	local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
	hum.WalkSpeed = 12
	local R = { i = idx, splits = {}, stuck = 0, log = {} }
	local t0 = os.clock()
	local function mark(k)
		R.splits[#R.splits + 1] = string.format("%s %.1f (%.0f,%.0f,%.0f)", k, os.clock() - t0, hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
	end
	local function log(s)
		R.log[#R.log + 1] = string.format("%.1f %s", os.clock() - t0, s)
	end
	local function state()
		return ch:GetAttribute("CC_ClimbState") or "none"
	end
	local function walk(p, tmax)
		local t1 = os.clock()
		local d0 = (flat(p) - flat(hrp.Position)).Magnitude
		tmax = tmax or d0 / 12 * 2.2 + 2.5
		while os.clock() - t1 < tmax do
			hum:MoveTo(p)
			if (flat(p) - flat(hrp.Position)).Magnitude < 2.2 then
				return true
			end
			task.wait(0.05)
		end
		R.stuck += 1
		log(string.format("STUCK walking near (%.0f,%.0f,%.0f) -> (%.0f,%.0f,%.0f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z, p.X, p.Y, p.Z))
		return false
	end
	-- push into a marked face until grabbed, hold `dir` until the controller leaves the face (mantle/step-off)
	local function climb(into, dir, tmax, label)
		local t1 = os.clock()
		ch:SetAttribute("CC_BotMove", into)
		while state() == "none" and os.clock() - t1 < 3 do
			task.wait(0.05)
		end
		if state() == "none" then
			ch:SetAttribute("CC_BotMove", Vector3.zero)
			R.stuck += 1
			log("NO GRAB at " .. label)
			return false
		end
		mark("grab " .. label)
		ch:SetAttribute("CC_BotMove", dir or into)
		while state() ~= "none" and os.clock() - t1 < tmax do
			task.wait(0.05)
		end
		ch:SetAttribute("CC_BotMove", Vector3.zero)
		if state() ~= "none" then
			R.stuck += 1
			log("STUCK on face " .. label .. string.format(" at y %.0f", hrp.Position.Y))
			return false
		end
		mark("off " .. label)
		return true
	end

	-- the teleport to the start is a client move: clear the server checkpoint first so it isn't judged a fall
	local dev = game.ReplicatedStorage:FindFirstChild("CC_Remotes") and game.ReplicatedStorage.CC_Remotes:FindFirstChild("DevRequest")
	if dev then
		dev:FireServer("setCheckpoint", {})
		task.wait(0.5)
	end
	local W = workspace:WaitForChild("World")
	local LP = W:WaitForChild("LedgeP1")
	local fallsBefore = plr:GetAttribute("CC_Falls") or 0
	for _, k in ipairs({ "CC_Grabs", "CC_Slips", "CC_Catches", "CC_Misses", "CC_Lunges" }) do
		R[k .. "0"] = ch:GetAttribute(k) or 0
	end

	-- 1) gate -> trailhead over the foothills (or start at the trailhead)
	local thFlag = LP:FindFirstChild("Flag_3", true)
	local th = thFlag and thFlag:FindFirstChild("GuideFlag").Position - Vector3.new(0, 6, 0)
	if cfg.fromGate then
		ch:PivotTo(CFrame.new(Vector3.new(-82, 52, 1800)))
		task.wait(2)
		t0 = os.clock()
		-- follow the approach flags (guidance layer a), as a player would
		for _, n in ipairs({ "Flag_1", "Flag_2" }) do
			local f = LP:FindFirstChild(n, true)
			if f then
				walk(f:FindFirstChild("GuideFlag").Position - Vector3.new(0, 4, 0) + Vector3.new(0, 0, 4))
			end
		end
		walk(Vector3.new(-482, 101, 1872))
	else
		ch:PivotTo(CFrame.new(Vector3.new(-482, 104, 1872)))
		task.wait(2)
		t0 = os.clock()
	end
	mark("trailhead")

	-- 2) Face B (faces +z): push north
	walk(Vector3.new(-488, 101, 1866))
	if not climb(Vector3.new(0, 0, -1), nil, 20, "FaceB") then
		R.result = "faceB"
		return R
	end

	-- 3) L1: walk the ledge parts east -> west; cross the chute on the panel when the rockfall is clear
	local walkParts = {}
	for _, p in ipairs(LP.L1:GetChildren()) do
		if p.Name == "Ledge" or p.Name == "RestLedge" or p.Name == "FinDeck" then
			walkParts[#walkParts + 1] = p
		end
	end
	table.sort(walkParts, function(a, b)
		return a.Position.X > b.Position.X
	end)
	local panel = LP.L1:FindFirstChild("MarkedPanel")
	local haz = W.Hazards:FindFirstChild("LedgeP1") and W.Hazards.LedgeP1:FindFirstChild("Rockfall_Chute")
	local crossed = false
	for _, p in ipairs(walkParts) do
		local top = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
		-- walking line: centre of the walkable top, but never hugging the back wall
		if panel and not crossed and top.X < panel.Position.X then
			-- reached the gap: wait for the rock to pass, then grab the panel and traverse west
			local o = -panel.CFrame.RightVector -- panel X axis spans the wall thickness (lookAt along the ledge)
			if (flat(hrp.Position) - flat(panel.Position)):Dot(o) < 0 then
				o = -o
			end
			local along = -panel.CFrame.LookVector
			if along:Dot(Vector3.new(-1, 0, 0)) < 0 then
				along = -along
			end
			along = flat(along).Unit
			-- step to the gap's near edge on the walking line (panel front + 1.6 out, 5 studs before the gap centre)
			local edge = flat(panel.Position) + o * 2.6 - along * 5.2
			walk(Vector3.new(edge.X, hrp.Position.Y, edge.Z))
			mark("chute")
			if haz then
				local per, tell, off = haz:GetAttribute("Period"), haz:GetAttribute("Tell"), haz:GetAttribute("Offset")
				local waited = os.clock()
				while true do
					local ph = (workspace:GetServerTimeNow() + off) % per
					if ph > tell + 1.5 and ph < per - 2.5 then
						break
					end
					task.wait(0.05)
				end
				R.chuteWait = os.clock() - waited
			end

			if not climb(-o, flat(along).Unit, 12, "panel") then
				R.result = "panel"
				return R
			end
			crossed = true
		end
		walk(top + Vector3.new(0, 3, 0))
	end
	mark("L1 end")

	-- 4) pillar: ladder pitch + marked face, mantle at the old ledge
	local grip = LP.Pillar.Ladder.LadderGrip
	local oE = grip.CFrame.LookVector
	walk(grip.Position + oE * 2.5 - Vector3.new(0, grip.Size.Y / 2 - 3, 0))
	if not climb(-flat(oE).Unit, nil, 25, "pillar") then
		R.result = "pillar"
		return R
	end
	-- 5) straight back over the pillar top onto the old ledge, then to the exit marker
	local ex = LP:FindFirstChild("Flag_9", true)
	if ex then
		local fp = ex:FindFirstChild("GuideFlag").Position
		walk(Vector3.new(grip.Position.X, hrp.Position.Y, fp.Z))
		walk(fp - Vector3.new(0, 4, 0))
	end
	mark("exit")
	R.total = os.clock() - t0
	R.reached = ex and (flat(hrp.Position) - flat(ex:FindFirstChild("GuideFlag").Position)).Magnitude < 8
	R.falls = (plr:GetAttribute("CC_Falls") or 0) - fallsBefore
	for _, k in ipairs({ "CC_Grabs", "CC_Slips", "CC_Catches", "CC_Misses", "CC_Lunges" }) do
		R[k] = (ch:GetAttribute(k) or 0) - R[k .. "0"]
		R[k .. "0"] = nil
	end
	R.result = "ok"
	return R
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
return "ledge bot started"
