-- Phase B scripted checks (dev tool). Lives in Studio as ReplicatedStorage.CC_DevTools.BChecks (needs the
-- Studio-only DevRequest remote). In a playtest, execute_luau on the CLIENT:
--   return require(game.ReplicatedStorage.CC_DevTools.BChecks:Clone())({ realTimePack = true })
-- then poll _G.CC_BCHK. Uses real prompts/movement where it matters (guardian hit, locker, claim refusal) and Studio
-- dev hooks for setup (profile reset, grants, checkpoint, clock offset). Labels: "real time" vs "simulated clock".
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local remotes = RS:WaitForChild("CC_Remotes")
local dev, reqEv, stateEv, fxEv, toastEv = remotes.DevRequest, remotes.CoreRequest, remotes.CoreState, remotes.CoreFx, remotes.CoreToast

local R = { status = "running", results = {}, log = {} }
local st = {}
stateEv.OnClientEvent:Connect(function(s)
	st = s
end)
local toasts = {}
toastEv.OnClientEvent:Connect(function(p)
	toasts[#toasts + 1] = { t = os.clock(), text = p.text }
end)
local fx = {}
fxEv.OnClientEvent:Connect(function(p)
	fx[#fx + 1] = { t = os.clock(), p = p }
end)

local function char()
	local ch = plr.Character or plr.CharacterAdded:Wait()
	return ch, ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
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
local function refresh()
	reqEv:FireServer("state")
	task.wait(0.4)
end
local function toastSince(t0, pat)
	for _, x in ipairs(toasts) do
		if x.t >= t0 and string.find(x.text, pat, 1, true) then
			return x.text
		end
	end
	return nil
end
local function result(name, pass, detail)
	R.results[#R.results + 1] = string.format("[%s] %s — %s", pass and "PASS" or "FAIL", name, detail)
end
local function teleport(pos)
	local ch = char()
	ch:PivotTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
	task.wait(0.8)
end
local function hold(prompt)
	local _, _, hrp = char()
	local cam = workspace.CurrentCamera
	local target = prompt.Parent.Position
	local back = flat(hrp.Position - target)
	back = back.Magnitude > 0.1 and back.Unit or Vector3.zAxis
	cam.CFrame = CFrame.lookAt(hrp.Position + back * 10 + Vector3.new(0, 6, 0), target)
	task.wait(0.35)
	prompt:InputHoldBegin()
	task.wait(prompt.HoldDuration + 0.25)
	prompt:InputHoldEnd()
	task.wait(0.4)
end
local function guardianOf(nestId)
	local g = workspace.World.Core:FindFirstChild("Guardians")
	for _, m in ipairs(g and g:GetChildren() or {}) do
		if m:GetAttribute("OwnerId") == plr.UserId and m:GetAttribute("NestId") == nestId then
			return m
		end
	end
end
-- walk into the hollow nest's guardian until a hit lands (stagger fx) or timeout
local function getHit(timeout)
	local _, hum = char()
	teleport(Vector3.new(-1010, 66, 2052))
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		for _, x in ipairs(fx) do
			if x.t > t0 and x.p.kind == "stagger" then
				return true
			end
		end
		local g = guardianOf("nest_r1_hollow")
		if g then
			hum:MoveTo(g:GetPivot().Position)
		end
		task.wait(0.2)
	end
	return false
end
local function packCount()
	refresh()
	return #(st.packs or {})
end

local CHECKS = {}

CHECKS[#CHECKS + 1] = function(cfg)
	-- no item shake before the first bank (beginner protection), real guardian hit
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Rare" } } })
	refresh()
	local before = st.used
	local t0 = os.clock()
	local hit = getHit(25)
	task.wait(1)
	refresh()
	local prot = toastSince(t0, "Beginner protection")
	result("no item shake before the first bank", hit and st.used == before and #(st.packs or {}) == 0 and prot ~= nil, string.format("guardian hit %s, pack %d -> %d, drop packs %d, toast '%s'", tostring(hit), before, st.used, #(st.packs or {}), tostring(prot)))
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- after the first bank a hit shakes the most valuable item into a 3-min pack; recover it near the end (real time)
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Common" } } })
	task.wait(0.3)
	dev:FireServer("deposit", { tx = "BCHK-first-bank" })
	task.wait(0.5)
	dev:FireServer("grant", { items = { { rarity = "Common" }, { rarity = "Rare" } } })
	refresh()
	local t0 = os.clock()
	local hit = getHit(25)
	task.wait(1)
	refresh()
	local pack = st.packs and st.packs[1]
	local lossFx
	for _, x in ipairs(fx) do
		if x.t > t0 and x.p.kind == "loss" then
			lossFx = x.p
		end
	end
	local shaken = lossFx and lossFx.lost and lossFx.lost[1]
	local window = pack and (pack.expiresAt - (st.serverNow or 0)) or -1
	result("hit after first bank shakes the most valuable item", hit and shaken ~= nil and shaken.rarity == "Rare" and st.used == 1, string.format("shaken %s, pack window %d s, still carrying %d", shaken and shaken.rarity or "none", window, st.used))
	if not pack then
		result("drop pack recoverable for 3 min", false, "no pack")
		return
	end
	-- leave, then come back at ~2:50 (real time) and recover
	teleport(Vector3.new(-1060, 70, 1980))
	local waitS = cfg.realTimePack and 150 or 0
	if not cfg.realTimePack then
		dev:FireServer("clock", { offset = 168 })
	end
	task.wait(waitS)
	refresh()
	local leftBefore
	waitFor(function()
		local g = guardianOf("nest_r1_hollow")
		return not g or (g:GetAttribute("State") == "Patrol" and (flat(g:GetPivot().Position) - flat(pack.pos)).Magnitude > 22)
	end, 25)
	refresh()
	leftBefore = (st.packs and st.packs[1]) and (st.packs[1].expiresAt - st.serverNow) or -1
	teleport(pack.pos + Vector3.new(4, 0, 4))
	local m
	for _, x in ipairs(workspace.World.Core.DropPacks:GetChildren()) do
		if x:GetAttribute("OwnerId") == plr.UserId then
			m = x
		end
	end
	local pr = m and m:FindFirstChild("RecoverPrompt", true)
	if pr then
		hold(pr)
	end
	refresh()
	result("drop pack recoverable for 3 min (" .. (cfg.realTimePack and "real time" or "simulated clock") .. ")", pr ~= nil and st.used == 2 and #(st.packs or {}) == 0, string.format("recovered with %d s left; carrying %d, packs %d", leftBefore, st.used, #(st.packs or {})))
	dev:FireServer("clock", { offset = 0 })
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- a pack that is not recovered expires after 3 min with a message (simulated clock)
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Common" } } })
	task.wait(0.3)
	dev:FireServer("deposit", { tx = "BCHK-first-bank-2" })
	task.wait(0.5)
	dev:FireServer("grant", { items = { { rarity = "Uncommon" } } })
	local hit = getHit(25)
	teleport(Vector3.new(-1060, 70, 1980))
	local t0 = os.clock()
	dev:FireServer("clock", { offset = 185 })
	task.wait(1.5)
	refresh()
	local faded = toastSince(t0, "faded")
	result("unrecovered pack expires after 3 min with a loss message (simulated clock)", hit and #(st.packs or {}) == 0 and faded ~= nil, string.format("packs %d, toast '%s'", #(st.packs or {}), tostring(faded)))
	dev:FireServer("clock", { offset = 0 })
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- fall after the first bank: respawn at the checkpoint, one item into a pack at the ledge (real fall)
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Common" } } })
	task.wait(0.3)
	dev:FireServer("deposit", { tx = "BCHK-first-bank-3" })
	task.wait(0.5)
	dev:FireServer("grant", { items = { { rarity = "Common" }, { rarity = "Uncommon" } } })
	task.wait(0.5)
	local _, _, hrp = char()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local g = workspace:Raycast(Vector3.new(-700, 400, 2100), Vector3.new(0, -500, 0), rp)
	dev:FireServer("setCheckpoint", { name = nil })
	teleport(g.Position)
	task.wait(1.5)
	dev:FireServer("setCheckpoint", { name = "Camp1" })
	task.wait(0.5)
	local t0 = os.clock()
	local ch = char()
	ch:PivotTo(CFrame.new(-700, 200, 2100)) -- ~140-stud drop onto the foothills
	waitFor(function()
		return hrp.Position.Y > 400
	end, 12)
	task.wait(1)
	refresh()
	local lossFall
	for _, x in ipairs(fx) do
		if x.t > t0 and x.p.kind == "loss" and x.p.reason == "fall" then
			lossFall = x.p
		end
	end
	result("fall after the first bank: respawn at checkpoint + 1 item to a pack", hrp.Position.Y > 400 and lossFall ~= nil and lossFall.lost[1].rarity == "Uncommon" and st.used == 1 and #(st.packs or {}) == 1, string.format("respawn y %.0f, shaken %s, carrying %d, packs %d", hrp.Position.Y, lossFall and lossFall.lost[1].rarity or "none", st.used, #(st.packs or {})))
	dev:FireServer("setCheckpoint", { name = nil })
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- Camp Locker: store one item at Camp1, take it back (server-validated, persisted in the profile)
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Rare" } } })
	local locker = workspace.World.Camps:WaitForChild("Camp1"):WaitForChild("CampLocker")
	local box = locker:WaitForChild("Box")
	teleport(box.Position + Vector3.new(0, 0, -6))
	local pr = box:WaitForChild("LockerPrompt", 5)
	hold(pr)
	refresh()
	local opened = st.locker ~= nil
	local uid = st.items and st.items[1] and st.items[1].uid
	reqEv:FireServer("lockerStore", { uid = uid })
	task.wait(0.6)
	refresh()
	local stored = st.locker and #st.locker.items == 1 and st.used == 0
	reqEv:FireServer("lockerTake", { uid = uid })
	task.wait(0.6)
	refresh()
	local back = st.locker and #st.locker.items == 0 and st.used == 1
	reqEv:FireServer("lockerClose")
	result("Camp Locker store + take (1 slot at tent tier 1)", opened and stored and back, string.format("opened %s, stored %s, taken back %s", tostring(opened), tostring(stored), tostring(back)))
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- resume at the highest camp: touch Camp1's trigger, leave + rejoin, spawn there; Foothold offer while empty
	dev:FireServer("resetProfile")
	task.wait(1.5)
	local trig = workspace.World.Checkpoints:WaitForChild("CP_Camp1")
	teleport(trig.Position)
	task.wait(1.5)
	refresh()
	local hc = st.highestCamp
	dev:FireServer("rejoin", {})
	task.wait(4)
	local _, _, hrp = char()
	refresh()
	local d = (flat(hrp.Position) - flat(trig.Position)).Magnitude
	result("resume at the highest reached camp", hc == 1 and d < 60 and st.resumeOffer == true, string.format("highestCamp %s, spawn %.0f studs from Camp1, Foothold offer %s", tostring(hc), d, tostring(st.resumeOffer)))
	reqEv:FireServer("resumeFoothold")
	task.wait(1)
	local sp = workspace:FindFirstChildOfClass("SpawnLocation")
	local d2 = sp and (flat(hrp.Position) - flat(sp.Position)).Magnitude or -1
	result("'Start at the Foothold' (empty pack, first 60 s)", d2 >= 0 and d2 < 30, string.format("%.0f studs from the Foothold spawn", d2))
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- full backpack: a claim is refused and nothing is lost
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Common" }, { rarity = "Common" }, { rarity = "Common" }, { rarity = "Common" } } })
	refresh()
	local m = workspace.World.Core.Creatures:WaitForChild("Creature_tut_common", 5)
	teleport(m.PrimaryPart.Position + Vector3.new(4, 0, 4))
	local t0 = os.clock()
	hold(m.PrimaryPart:FindFirstChild("ClaimPrompt"))
	refresh()
	local refused = toastSince(t0, "Backpack full")
	result("full backpack refuses a claim without loss", refused ~= nil and st.used == 4, string.format("toast '%s', pack %d/%d", tostring(refused), st.used, st.capacity))
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- disconnect with unbanked cargo: items go to a 3-min pack on this server, notice on the next join
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Rare" }, { rarity = "Common" } } })
	task.wait(0.4)
	local t0 = os.clock()
	dev:FireServer("rejoin", {})
	task.wait(4)
	refresh()
	local notice = toastSince(t0, "Last trip")
	result("disconnect: unbanked items to a pack + 'last trip' notice", #(st.packs or {}) == 1 and st.used == 0 and notice ~= nil, string.format("packs %d, carrying %d, toast '%s'", #(st.packs or {}), st.used, tostring(notice)))
end

CHECKS[#CHECKS + 1] = function(cfg)
	-- B-polish: the tutorial Rare (source nook_rare_r1) is not shaken loose until it has been banked once
	dev:FireServer("resetProfile")
	task.wait(1.5)
	dev:FireServer("grant", { items = { { rarity = "Common" } } })
	task.wait(0.3)
	dev:FireServer("deposit", { tx = "BCHK-tutrare-first" })
	task.wait(0.5)
	dev:FireServer("grant", { items = { { rarity = "Common" }, { rarity = "Rare", source = "nook_rare_r1" } } })
	refresh()
	local t0 = os.clock()
	local hit = getHit(25)
	task.wait(1)
	refresh()
	local kept = false
	for _, it in ipairs(st.items or {}) do
		if it.rarity == "Rare" then
			kept = true
		end
	end
	local note = toastSince(t0, "protected until you bank it")
	result("tutorial Rare protected until banked once", hit and kept and st.used == 1 and note ~= nil, string.format("hit %s, Rare kept %s, carrying %d, toast '%s'", tostring(hit), tostring(kept), st.used, tostring(note)))
	-- after it has been banked once, a later nook Rare follows the normal rule
	teleport(Vector3.new(-1060, 70, 1980))
	-- the bank travel-time check holds a nook find for ~56 s after its claim: simulate the walk home on the clock
	dev:FireServer("clock", { offset = 120 })
	task.wait(0.3)
	dev:FireServer("deposit", { tx = "BCHK-tutrare-bank" })
	task.wait(0.5)
	dev:FireServer("clock", { offset = 0 })
	task.wait(0.3)
	dev:FireServer("grant", { items = { { rarity = "Rare", source = "nook_rare_r1" } } })
	task.wait(3)
	refresh()
	local t1 = os.clock()
	local hit2 = getHit(25)
	task.wait(1)
	refresh()
	local lossFx
	for _, x in ipairs(fx) do
		if x.t > t1 and x.p.kind == "loss" then
			lossFx = x.p
		end
	end
	local shaken = lossFx and lossFx.lost and lossFx.lost[1]
	result("tutorial Rare shakes normally after it was banked once", hit2 and shaken ~= nil and shaken.rarity == "Rare", string.format("hit %s, shaken %s", tostring(hit2), shaken and shaken.rarity or "none"))
	teleport(Vector3.new(-1060, 70, 1980))
end

return function(cfg)
	cfg = cfg or {}
	_G.CC_BCHK = R
	task.spawn(function()
		for i, fn in ipairs(CHECKS) do
			if cfg.only and not table.find(cfg.only, i) then
				continue
			end
			R.where = "check " .. i
			local ok, err = pcall(fn, cfg)
			if not ok then
				R.results[#R.results + 1] = "[ERROR] check " .. i .. ": " .. tostring(err)
			end
		end
		dev:FireServer("clock", { offset = 0 })
		R.status = "done"
	end)
	return "B checks started (" .. #CHECKS .. ")"
end
