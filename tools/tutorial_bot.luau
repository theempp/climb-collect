-- Tutorial bot (dev tool). Lives in Studio as ReplicatedStorage.CC_DevTools.TutorialBot (inert outside Studio: it
-- needs the Studio-only DevRequest remote). In a playtest, execute_luau on the CLIENT:
--   return require(game.ReplicatedStorage.CC_DevTools.TutorialBot:Clone())({ runs = 1, speed = 12, hit = false })
-- Runs the full onboarding with real inputs: Humanoid:MoveTo for walking, ProximityPrompt:InputHoldBegin/End for
-- every claim/net/bank (so the server's hold/range/stagger validation runs exactly as for a player).
-- Config: runs (default 1), speed (12 = timing run; higher = stuck check only, times not comparable), hit (true = on
-- even runs, stay near the nest after netting so the guardian hit + drop pack + recovery path runs).
-- Each run first resets the profile (Studio-only DevRequest "resetProfile"). Poll _G.CC_TBOT for results.
-- Times are BOT times (perfect input): not human times.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local remotes = RS:WaitForChild("CC_Remotes")
local dev, reqEv, stateEv, fxEv = remotes.DevRequest, remotes.CoreRequest, remotes.CoreState, remotes.CoreFx
local RUNS, SPEED, WANT_HIT = 1, 12, false

local B = { status = "running", runs = {}, log = {} }
_G.CC_TBOT = B
local st = {}
stateEv.OnClientEvent:Connect(function(s)
	st = s
end)
local lastFx = {}
fxEv.OnClientEvent:Connect(function(p)
	if type(p) == "table" and p.kind then
		lastFx[p.kind] = { t = os.clock(), p = p }
	end
end)

local function char()
	local ch = plr.Character or plr.CharacterAdded:Wait()
	return ch, ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function log(run, s)
	run.log[#run.log + 1] = string.format("%.1f %s", os.clock() - run.t0, s)
end
local function tutStep()
	return plr:GetAttribute("CC_Tutorial") or 0
end
local function waitFor(fn, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if fn() then
			return true
		end
		task.wait(0.1)
	end
	return false
end

-- walk to pos; retries MoveTo, jumps when stalled; returns true/false (stuck)
local function walkTo(run, pos, timeout, tol)
	local _, hum, hrp = char()
	tol = tol or 3
	timeout = timeout or ((flat(pos) - flat(hrp.Position)).Magnitude / SPEED * 2 + 6)
	local t0, lastP, lastT = os.clock(), hrp.Position, os.clock()
	while os.clock() - t0 < timeout do
		if (flat(pos) - flat(hrp.Position)).Magnitude < tol then
			return true
		end
		hum:MoveTo(pos)
		task.wait(0.15)
		if (hrp.Position - lastP).Magnitude > 1.5 then
			lastP, lastT = hrp.Position, os.clock()
		elseif os.clock() - lastT > 1.2 then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			lastT = os.clock()
		end
	end
	run.stuck += 1
	log(run, string.format("STUCK walking to (%.0f,%.0f,%.0f) from (%.0f,%.0f,%.0f)", pos.X, pos.Y, pos.Z, hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
	return false
end

local routeCache = {}
local function route(name)
	if routeCache[name] then
		return routeCache[name]
	end
	local out = {}
	for tok in string.gmatch(RS.CC_Route[name].Value, "[^;]+") do
		local x, y, z, s = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		out[#out + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
	end
	routeCache[name] = out
	return out
end
local function followRoute(run, name, s0, s1)
	local pts = route(name)
	local nextS = s0
	for _, q in ipairs(pts) do
		if q.s >= nextS and q.s <= s1 then
			nextS = q.s + 14
			walkTo(run, q.p, nil, 4) -- a stalled waypoint is logged; keep following the road
		end
	end
	return true
end

-- find a prompt by model name under World.Core.<folder> (waits for streaming)
local function findPrompt(folderName, modelName, promptName)
	local t0 = os.clock()
	while os.clock() - t0 < 8 do
		local core = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Core")
		local f = core and core:FindFirstChild(folderName)
		local m = f and f:FindFirstChild(modelName)
		local p = m and m:FindFirstChild(promptName, true)
		if p then
			return p, m
		end
		task.wait(0.2)
	end
	return nil
end
local function hold(prompt)
	-- prompts only show when their part is on screen: aim the camera at it from behind the character
	local _, _, hrp = char()
	local cam = workspace.CurrentCamera
	local target = prompt.Parent:IsA("BasePart") and prompt.Parent.Position or hrp.Position
	local back = flat(hrp.Position - target)
	back = back.Magnitude > 0.1 and back.Unit or Vector3.zAxis
	cam.CFrame = CFrame.lookAt(hrp.Position + back * 10 + Vector3.new(0, 6, 0), target)
	task.wait(0.35)
	prompt:InputHoldBegin()
	task.wait(prompt.HoldDuration + 0.25)
	prompt:InputHoldEnd()
	task.wait(0.3)
end

local function guardian(nestId)
	local g = workspace.World.Core:FindFirstChild("Guardians")
	for _, m in ipairs(g and g:GetChildren() or {}) do
		if m:GetAttribute("OwnerId") == plr.UserId and m:GetAttribute("NestId") == nestId then
			return m
		end
	end
	return nil
end

local function recoverPacks(run)
	for _ = 1, 3 do
		local p = st.packs and st.packs[1]
		if not p then
			return
		end
		log(run, "recovering drop pack")
		-- packs lie where you were hit: sneak back in only while the guardian is away from it
		waitFor(function()
			local gm = guardian("nest_r1_hollow")
			return not gm or (gm:GetAttribute("State") == "Patrol" and (flat(gm:GetPivot().Position) - flat(p.pos)).Magnitude > 22)
		end, 25)
		walkTo(run, p.pos, 25, 4)
		local packs = workspace.World.Core:FindFirstChild("DropPacks")
		for _, m in ipairs(packs and packs:GetChildren() or {}) do
			if m:GetAttribute("OwnerId") == plr.UserId then
				local pr = m:FindFirstChild("RecoverPrompt", true)
				if pr then
					local before = #(st.packs or {})
					hold(pr)
					task.wait(0.4)
					if #(st.packs or {}) < before then
						run.recovered += 1
					end
				end
			end
		end
		task.wait(0.5)
	end
end

local function oneRun(i)
	local run = { i = i, t0 = os.clock(), stuck = 0, log = {}, marks = {}, hits = 0, recovered = 0, speed = SPEED }
	B.runs[i] = run
	local ch, hum, hrp = char()
	dev:FireServer("resetProfile")
	task.wait(1.5)
	hum.WalkSpeed = SPEED
	reqEv:FireServer("state")
	waitFor(function()
		return tutStep() == 1
	end, 10)
	run.t0 = os.clock()
	local function mark(name)
		run.marks[name] = os.clock() - run.t0
		log(run, "MARK " .. name)
	end

	-- 1 look around: walk toward the plaza
	walkTo(run, hrp.Position + Vector3.new(0, 0, -16))
	waitFor(function()
		return tutStep() >= 2
	end, 10)
	-- 2 first common
	local p, m = findPrompt("Creatures", "Creature_tut_common", "ClaimPrompt")
	if p then
		walkTo(run, m.PrimaryPart.Position, nil, 5)
		hold(p)
	end
	if waitFor(function()
		return tutStep() >= 3
	end, 5) then
		mark("common")
	end
	-- 3 bank at the campfire
	local fire = workspace.World.Regions.Foothold.Core.Campfire.Core
	walkTo(run, fire.Position + Vector3.new(0, 0, 8), nil, 6)
	hold(fire.BankPrompt)
	if waitFor(function()
		return tutStep() >= 4
	end, 5) then
		mark("bank1")
	end
	-- 4 Shepherd's Road to the rope, climb (the gate opens west and is reached from the north-east)
	walkTo(run, Vector3.new(-150, 49, 1880), nil, 6)
	walkTo(run, Vector3.new(-192, 49, 1848), nil, 5)
	walkTo(run, Vector3.new(-222, 49, 1818), nil, 5)
	followRoute(run, "Shepherd", 0, 822)
	local base = st.tut and st.tut.target
	if base then
		walkTo(run, base, 20, 2.5)
	end
	local props = workspace.World.Core.Props
	local top = props.NookTop.Position
	local climbed = false
	for _ = 1, 3 do
		hum:MoveTo(top)
		if waitFor(function()
			hum:MoveTo(top)
			return hrp.Position.Y > top.Y - 3.5
		end, 9) then
			climbed = true
			break
		end
		walkTo(run, base, 10, 2.5)
	end
	if climbed then
		mark("rope")
	else
		run.stuck += 1
		log(run, "STUCK rope climb")
	end
	-- 5 the Rare
	p, m = findPrompt("Creatures", "Creature_nook_rare_r1", "ClaimPrompt")
	if p then
		walkTo(run, m.PrimaryPart.Position, 12, 4)
		hold(p)
	end
	if waitFor(function()
		return tutStep() >= 6
	end, 5) then
		mark("rare")
	end
	-- 6 the pup: get down, cross to the hollow (west of the hide spot), net from near max range
	local SAFE = Vector3.new(-1030, 70, 1990) -- retreat point north-north-west of the nest, open ground
	walkTo(run, Vector3.new(-1045, 111, 1884), 10, 4)
	walkTo(run, SAFE, 30, 5)
	local pupPos = st.tut and st.tut.target
	p, m = findPrompt("NestLive", "Pup_nest_r1_hollow", "NetPrompt")
	local function hasEpic()
		for _, it in ipairs(st.items or {}) do
			if it.rarity == "Epic" then
				return true
			end
		end
		return false
	end
	for attempt = 1, 4 do
		if not (p and pupPos) or hasEpic() then
			break
		end
		-- wait until the guardian is away from the pup and not checking the nest
		waitFor(function()
			local gm = guardian("nest_r1_hollow")
			return not gm or (gm:GetAttribute("State") == "Patrol" and not gm:GetAttribute("Looking") and (flat(gm:GetPivot().Position) - flat(pupPos)).Magnitude > 16)
		end, 20)
		local stand = pupPos + flat(SAFE - pupPos).Unit * 12
		walkTo(run, stand, 20, 2)
		local dist = (hrp.Position - m.PrimaryPart.Position).Magnitude
		hold(p)
		if waitFor(hasEpic, 2) then
			break
		end
		log(run, string.format("net attempt %d failed (3D distance %.1f, prompt enabled %s)", attempt, dist, tostring(p.Enabled)))
		if lastFx.loss and os.clock() - lastFx.loss.t < 6 then
			run.hits += 1
		end
		walkTo(run, SAFE, 20, 5)
		recoverPacks(run)
		walkTo(run, SAFE, 20, 5)
	end
	if hasEpic() then
		mark("pup")
	end
	-- the guardian wakes: retreat north behind the hide spot until it gives up
	if WANT_HIT and i % 2 == 0 then
		-- walk into the guardian once so the hit + drop pack + recovery path runs
		local t0 = os.clock()
		while os.clock() - t0 < 20 and not (lastFx.loss and lastFx.loss.t > t0) do
			local g = guardian("nest_r1_hollow")
			if g then
				hum:MoveTo(g:GetPivot().Position)
			end
			task.wait(0.2)
		end
		if lastFx.loss and os.clock() - lastFx.loss.t < 15 then
			run.hits += 1
			log(run, "hit by guardian (intended)")
			task.wait(2.5)
			-- run away first, then come back for the pack
			walkTo(run, SAFE, 15, 5)
			waitFor(function()
				local gm = guardian("nest_r1_hollow")
				return not gm or gm:GetAttribute("State") == "Patrol" or gm:GetAttribute("State") == "Retreat"
			end, 15)
			recoverPacks(run)
		end
	end
	walkTo(run, SAFE, 20, 5)
	waitFor(function()
		local gm = guardian("nest_r1_hollow")
		return not gm or gm:GetAttribute("State") == "Patrol"
	end, 20)
	-- 7 Heartstone: go in while it walks the ring (not checking the nest), retry if hit
	local hsP, hsM = findPrompt("NestLive", "Heartstone_nest_r1_hollow", "HeartstonePrompt")
	local function hasHS()
		for _, it in ipairs(st.items or {}) do
			if it.kind == "heartstone" then
				return true
			end
		end
		return false
	end
	for attempt = 1, 5 do
		if hasHS() then
			break
		end
		-- go in while it walks the far side of its ring and is not checking the nest
		waitFor(function()
			local gm = guardian("nest_r1_hollow")
			if not gm or not hsM then
				return true
			end
			local c = flat(hsM.PrimaryPart.Position)
			local away = (flat(gm:GetPivot().Position) - c):Dot((c - flat(SAFE)).Unit)
			return gm:GetAttribute("State") == "Patrol" and not gm:GetAttribute("Looking") and away > 4
		end, 25)
		if hsP then
			walkTo(run, hsM.PrimaryPart.Position, 15, 5)
			hold(hsP)
		end
		if waitFor(hasHS, 2) then
			break
		end
		log(run, "Heartstone attempt " .. attempt .. " failed")
		if lastFx.loss and os.clock() - lastFx.loss.t < 6 then
			run.hits += 1
		end
		walkTo(run, SAFE, 15, 5)
		recoverPacks(run)
		walkTo(run, SAFE, 15, 5)
	end
	if hasHS() then
		mark("heartstone")
	end
	-- 8 home: cross the foothills east to the campfire
	recoverPacks(run)
	-- home: north of the nest (clear of the guardian's ring and the hide-spot boulders), then east across the foothills
	-- (the last legs avoid the cabin terraces west of the plaza: in by the north-west, as on the way out)
	for _, wp in ipairs({ Vector3.new(-960, 85, 2000), Vector3.new(-880, 80, 2040), Vector3.new(-760, 45, 2110), Vector3.new(-500, 55, 2090), Vector3.new(-330, 50, 2010), Vector3.new(-150, 49, 1880), fire.Position + Vector3.new(0, 0, 8) }) do
		walkTo(run, wp, nil, 6)
	end
	hold(fire.BankPrompt)
	-- if the Heartstone was shaken into a pack on the way, go back for it and bank again (as a player would)
	for _ = 1, 2 do
		if waitFor(function()
			return tutStep() >= 9
		end, 5) then
			break
		end
		if not (st.packs and #st.packs > 0) then
			break
		end
		log(run, "Heartstone still in a drop pack: going back for it")
		recoverPacks(run)
		for _, wp in ipairs({ Vector3.new(-960, 85, 2000), Vector3.new(-880, 80, 2040), Vector3.new(-760, 45, 2110), Vector3.new(-500, 55, 2090), Vector3.new(-330, 50, 2010), Vector3.new(-150, 49, 1880), fire.Position + Vector3.new(0, 0, 8) }) do
			walkTo(run, wp, nil, 6)
		end
		hold(fire.BankPrompt)
	end
	if tutStep() >= 9 then
		mark("bank2")
	end
	-- 9 while the Heartstone ripens: two finds on the Foothold outskirts (shared commons; nearest one still there)
	local OUT_WP = { out_3 = { Vector3.new(-150, 49, 1880) }, out_1 = { Vector3.new(-150, 49, 1880), Vector3.new(-330, 50, 2010) } }
	for _ = 1, 2 do
		if tutStep() ~= 9 then
			break
		end
		local best, bd
		for _, m2 in ipairs(workspace.World.Core.Creatures:GetChildren()) do
			local id = string.match(m2.Name, "^Creature_(out_%d)$") or string.match(m2.Name, "^Creature_(shep_1)$")
			if id and m2.PrimaryPart then
				local d = (m2.PrimaryPart.Position - hrp.Position).Magnitude
				if not bd or d < bd then
					best, bd = m2, d
				end
			end
		end
		if not best then
			break
		end
		local id = string.match(best.Name, "^Creature_(.+)$")
		for _, wp in ipairs(OUT_WP[id] or {}) do
			walkTo(run, wp, nil, 6)
		end
		walkTo(run, best.PrimaryPart.Position, nil, 5)
		local pr = best:FindFirstChild("ClaimPrompt", true)
		if pr then
			hold(pr)
		end
		task.wait(0.5)
	end
	if waitFor(function()
		return tutStep() >= 10
	end, 5) then
		mark("outskirts")
	end
	-- 10 bank them
	for _, wp in ipairs({ Vector3.new(-150, 49, 1880), fire.Position + Vector3.new(0, 0, 8) }) do
		walkTo(run, wp, nil, 6)
	end
	hold(fire.BankPrompt)
	if waitFor(function()
		return tutStep() >= 11
	end, 5) then
		mark("bank3")
	end
	-- 11 cliffhanger plays (~7 s), then done (12)
	if waitFor(function()
		return tutStep() >= 12
	end, 15) then
		mark("done")
	end
	run.level, run.xp = st.level, st.xp
	run.total = os.clock() - run.t0
	run.finalStep = tutStep()
	run.pack = st.used
	run.heartstones = st.heartstones and #st.heartstones or 0
	return run
end

return function(cfg)
	cfg = cfg or {}
	RUNS, SPEED, WANT_HIT = cfg.runs or 1, cfg.speed or 12, cfg.hit == true
	B = { status = "running", runs = {}, log = {}, speed = SPEED }
	_G.CC_TBOT = B
	dev:FireServer("botSpeed", { factor = SPEED / 12 })
task.spawn(function()
	for i = 1, RUNS do
		local ok, err = pcall(oneRun, i)
		if not ok then
			B.log[#B.log + 1] = "run " .. i .. " ERROR " .. tostring(err)
		end
		B.where = "finished run " .. i
	end
	local _, hum = char()
	hum.WalkSpeed = 12
	B.status = "done"
end)
return "tutorial bot started: runs " .. RUNS .. " speed " .. SPEED
end
