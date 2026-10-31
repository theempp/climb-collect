-- Server rider feed (ServerScriptService.SS_Stream; STREAMING-PLAN section 2, owner Q3: before M7). The client
-- anchors its HRP while riding and moves it by CFrame, so the server may not see where the rider is (B3). The
-- client reports its d Stream.FeedHz times a second (SS_Remotes.Rider); the server moves an anchored focus part
-- to P.surf(d) and makes it the player's ReplicationFocus, and every Stream.PrefetchEvery s asks for the ground
-- Stream.Lead s ahead at the rider's measured speed. SS_Remotes.Prepare(d) streams in around P.surf(d) before
-- a jump (summit reset, debug teleport) and returns once it is there (or after Stream.PrepareTimeout s).
-- The focus takes over from the character only once the client has fed or prepared (a client that never feeds
-- keeps the default character focus). A respawn puts it back at the spawn (d -30) and streams that in.
-- Speed: from the client's own clock between reports (server arrival times jitter), smoothed by SpeedSmooth.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))
local S = C.Stream

local remotes = RepS:WaitForChild("SS_Remotes") -- made by SS_Save
local riderEv = Instance.new("RemoteEvent")
riderEv.Name = "Rider"
riderEv.Parent = remotes
local prepareFn = Instance.new("RemoteFunction")
prepareFn.Name = "Prepare"
prepareFn.Parent = remotes

local foci = Instance.new("Folder")
foci.Name = "SS_Focus"
foci.Parent = workspace
local riders = {} -- player -> { part, d, v, t, nextPrefetch }

local function clampD(d)
	return math.clamp(d, -S.Margin, P.Total + S.Margin)
end
local function at(d) -- the path is defined past both ends (spawn at -30, summit pad at Total + 20)
	return P.surf(d, 0, 0)
end
local function rider(player)
	local r = riders[player]
	if not r then
		local p = Instance.new("Part")
		p.Name = "Focus_" .. player.UserId
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Transparency = 1
		p.Size = Vector3.one
		p.CFrame = at(-30)
		p.Parent = foci
		r = { part = p, d = -30, v = 0, tc = nil, t = os.clock(), nextPrefetch = 0, active = false, respawnT = -math.huge }
		riders[player] = r
	end
	return r
end
local function activate(player, r)
	if not r.active then
		r.active = true
		player.ReplicationFocus = r.part
	end
end
local function stream(player, d, timeout)
	return pcall(player.RequestStreamAroundAsync, player, at(d).Position, timeout)
end

riderEv.OnServerEvent:Connect(function(player, d, tc)
	if type(d) ~= "number" or d ~= d or math.abs(d) > 1e6 then
		return
	end
	d = clampD(d)
	local r = rider(player)
	local now = os.clock()
	if now - r.respawnT < S.RespawnHold and math.abs(d + 30) > S.JumpStuds then
		return -- a feed from the old life, still in flight when the new character spawned
	end
	activate(player, r)
	if type(tc) == "number" and tc == tc and r.tc then
		local dtc = tc - r.tc
		if math.abs(d - r.d) > S.JumpStuds then
			r.v = 0 -- a jump is not a speed
		elseif dtc > 0.05 and dtc < 2 then
			local v = math.clamp((d - r.d) / dtc, 0, S.MaxSpeed)
			r.v += (v - r.v) * S.SpeedSmooth
		end
	end
	r.d, r.tc, r.t = d, type(tc) == "number" and tc or nil, now
	r.part.CFrame = at(d)
	if now >= r.nextPrefetch then
		r.nextPrefetch = now + S.PrefetchEvery
		task.spawn(stream, player, d + S.Lead * r.v, S.PrefetchTimeout)
	end
end)

prepareFn.OnServerInvoke = function(player, d)
	if type(d) ~= "number" or d ~= d or math.abs(d) > 1e6 then
		return false, 0
	end
	d = clampD(d)
	local r = rider(player)
	activate(player, r)
	r.d, r.v, r.tc, r.t = d, 0, nil, os.clock()
	r.part.CFrame = at(d)
	local t0 = os.clock()
	local ok = stream(player, d, S.PrepareTimeout)
	return ok, os.clock() - t0
end

local function onPlayer(player)
	rider(player)
	player.CharacterAdded:Connect(function()
		local r = riders[player]
		if r and r.active then -- a respawn lands at the spawn (d -30): the focus goes there before the client feeds
			r.d, r.v, r.tc, r.t, r.respawnT = -30, 0, nil, os.clock(), os.clock()
			r.part.CFrame = at(-30)
			task.spawn(stream, player, -30, S.PrepareTimeout)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, pl in Players:GetPlayers() do
	onPlayer(pl)
end
Players.PlayerRemoving:Connect(function(player)
	local r = riders[player]
	if r then
		r.part:Destroy()
		riders[player] = nil
	end
end)

-- Studio-only BOT hook (S1): where the server thinks the rider is.
if RunService:IsStudio() then
	local dbg = Instance.new("RemoteFunction")
	dbg.Name = "SS_DebugStream"
	dbg.OnServerInvoke = function(player, action)
		local r = riders[player]
		if action == "focus" and r then
			local fd = P.project(r.part.Position)
			return { d = r.d, focusD = fd, isFocus = player.ReplicationFocus == r.part, age = os.clock() - r.t,
				streaming = workspace.StreamingEnabled }
		end
		return nil
	end
	dbg.Parent = RepS
end
