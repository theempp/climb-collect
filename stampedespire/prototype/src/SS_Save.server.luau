-- Player progression server (ServerScriptService.SS_Save, P3): loads and saves each player's profile, takes
-- the client's distance + score reports (ReplicatedStorage.SS_Remotes.Report) through the SS_Progress
-- validator, sells upgrades (Buy) and pushes the profile view back (Profile). Every run starts at the bottom;
-- checkpoints only count toward the best section. Studio adds SS_DebugServer for the BOT.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local C = require(RepS:WaitForChild("SS_Config"))
local Prog = require(script.Parent:WaitForChild("SS_Progress"))
local G = C.Progress

local store, mode, why = Prog.openStore()
RepS:SetAttribute("SS_StoreMode", mode)
if why then
	print("SS_Save: in-memory store (" .. why .. ")")
end

local remotes = Instance.new("Folder")
remotes.Name = "SS_Remotes"
local function remote(class, name)
	local r = Instance.new(class)
	r.Name = name
	r.Parent = remotes
	return r
end
local reportEv = remote("RemoteEvent", "Report")
local profileEv = remote("RemoteEvent", "Profile")
local buyFn = remote("RemoteFunction", "Buy")
local riddenEv = remote("RemoteEvent", "Ridden") -- Herd Journal (P4): the client names each species it mounts
remotes.Parent = RepS

local sessions = {} -- player -> { prof, tracker, dirty, noSave, lastRecv }

local function key(player)
	return "p_" .. player.UserId
end

local function view(s)
	local r = s.tracker.run
	return {
		coins = s.prof.coins, ascents = s.prof.ascents, best = s.prof.best, score = s.prof.score,
		upgrades = table.clone(s.prof.upgrades), mode = mode, noSave = s.noSave,
		medals = table.clone(s.prof.medals), times = table.clone(s.prof.times), ridden = table.clone(s.prof.ridden),
		medal = s.lastMedal, -- the newest section medal of this run (the client pops it once)
		run = r and { valid = r.valid, reason = r.reason, cp = r.cp, top = r.top } or nil,
	}
end

local function push(player)
	local s = sessions[player]
	if s and s.prof then
		profileEv:FireClient(player, view(s))
	end
end

local function load(player)
	local ok, raw = store.load(key(player))
	local s = sessions[player]
	if not s then
		return
	end
	s.prof = Prog.migrate(ok and raw or nil)
	s.noSave = not ok -- a failed load must never overwrite the saved profile
	if not ok then
		warn("SS_Save: load failed for " .. player.Name .. ": " .. tostring(raw))
	end
	push(player)
end

local function save(player)
	local s = sessions[player]
	if not s or not s.prof or s.noSave then
		return false
	end
	s.dirty = false
	local ok, err = store.save(key(player), s.prof)
	if not ok then
		s.dirty = true
		warn("SS_Save: save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

local function onPlayer(player)
	sessions[player] = { tracker = Prog.newTracker(), dirty = false, lastRecv = 0 }
	load(player)
end
Players.PlayerAdded:Connect(onPlayer)
for _, pl in Players:GetPlayers() do
	task.spawn(onPlayer, pl)
end
Players.PlayerRemoving:Connect(function(player)
	save(player)
	sessions[player] = nil
end)
game:BindToClose(function()
	for pl in sessions do
		task.spawn(save, pl)
	end
	task.wait(2)
end)
task.spawn(function()
	while true do
		task.wait(G.AutoSave)
		for pl, s in sessions do
			if s.dirty then
				task.spawn(save, pl)
			end
		end
	end
end)

local function finite(v)
	return type(v) == "number" and v == v and math.abs(v) < 1e9
end

reportEv.OnServerEvent:Connect(function(player, d, score, spawn)
	local s = sessions[player]
	local now = os.clock()
	if not s or not s.prof or not finite(d) or not finite(score) then
		return
	end
	-- the client's spawn report (summit reset, respawn: d -30, flagged) starts a new run and is never dropped by
	-- MinReportGap, but only once per RestartGap (P4 re-review: any big drop skipping the gap doubled a farm loop)
	spawn = spawn == true and d <= 0 and now - (s.lastSpawn or -math.huge) >= G.RestartGap
	if now - s.lastRecv < G.MinReportGap and not spawn then
		return
	end
	if spawn then
		s.lastSpawn = now
	end
	s.lastRecv = now
	local ev = Prog.step(s.tracker, s.prof, d, math.max(score, 0), now, spawn)
	if ev.coins > 0 or ev.cp or ev.ascent or ev.newRun or ev.invalid or ev.ridden then
		s.dirty = true
	end
	if ev.medal then
		s.medalN = (s.medalN or 0) + 1
		s.lastMedal = { n = s.medalN, k = ev.medal.k, tier = ev.medal.tier, secs = ev.medal.secs }
	end
	push(player)
end)

riddenEv.OnServerEvent:Connect(function(player, name, d)
	local s = sessions[player]
	if s then -- (queued even before the profile loads: it is counted at the next report)
		Prog.ridden(s.tracker, name, d) -- counted at the next report (SS_Progress)
	end
end)

buyFn.OnServerInvoke = function(player, id)
	local s = sessions[player]
	if not s or not s.prof or type(id) ~= "string" then
		return false, "busy"
	end
	local ok, res = Prog.buy(s.prof, id)
	if ok then
		s.dirty = true
	end
	push(player)
	return ok, res
end

-- Studio-only BOT hooks (never in a live server).
if RunService:IsStudio() then
	local dbg = Instance.new("RemoteFunction")
	dbg.Name = "SS_DebugServer"
	dbg.OnServerInvoke = function(player, action, arg)
		local s = sessions[player]
		if action == "profile" then
			return s and s.prof and { view = view(s), prof = table.clone(s.prof), lastScore = s.tracker.lastScore }
		elseif action == "selfTest" then
			return Prog.selfTest()
		elseif action == "set" then -- replace the profile (BOT fixtures); arg goes through migrate
			s.prof = Prog.migrate(arg)
			s.dirty = true
			push(player)
			return true
		elseif action == "roundtrip" then -- save, drop the session's profile, load it back like a rejoin
			local before = Prog.migrate(s.prof)
			local okSave = save(player)
			s.prof = nil
			load(player)
			return { okSave = okSave, equal = Prog.equal(before, s.prof), before = before, after = s.prof, mode = mode }
		end
		return nil
	end
	dbg.Parent = RepS
end
