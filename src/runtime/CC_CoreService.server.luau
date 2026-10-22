-- CC_CoreService (ServerScriptService): boots the core loop (Run 1: A1 persistence + B systems).
-- Owns player sessions: profile load (session lock, retries), autosave every 60 s, release on leave and shutdown,
-- manual Heartstone progress, the bank deposit entry point, state pushes and toasts, the CoreRequest router (rate-limited)
-- and Studio-only test hooks. Gameplay modules in ServerScriptService.CC_CoreServer plug in through ctx:
--   M.init(ctx) · M.onLoaded(plr, session) · M.onLeave(plr, session) · M.onCharacter(plr, char) · M.state(plr, st)
-- Real DataStore only when the place is published (game.PlaceId ~= 0); otherwise the in-memory store (UNVERIFIED
-- real-DataStore behavior, see design/core-run-report.md).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local CoreRS = RS:WaitForChild("CC_Core")
local C = require(CoreRS:WaitForChild("CoreConfig"))
local Species = require(CoreRS:WaitForChild("Species"))
local Net = require(CoreRS:WaitForChild("Net"))
local SrvF = script.Parent:WaitForChild("CC_CoreServer")
local Clock = require(SrvF.Clock)
local Store = require(SrvF.Store)
local Profile = require(SrvF.Profile)
local Inv = require(SrvF.Inventory)
local Bank = require(SrvF.Bank)
local Prog = require(SrvF.Progression)

-- Publish builds: Studio dev tools never exist in a live server (user review 2026-10-20: strip them before
-- publishing; Studio keeps them). tools/publish_strip.luau removes them from a publish copy; this is the backstop.
if not Run:IsStudio() then
	local SS = game:GetService("ServerStorage")
	for _, pair in ipairs({ { RS, "CC_DevTools" }, { SS, "CC_DevTools" }, { SS, "CC_DevBridge" }, { SS, "CC_Checkpoints" }, { SrvF, "Tests" } }) do
		local inst = pair[1]:FindFirstChild(pair[2])
		if inst then
			inst:Destroy()
		end
	end
end

local remotes = Net.serverInit()
local stateEv, toastEv, fxEv, reqEv = remotes.CoreState, remotes.CoreToast, remotes.CoreFx, remotes.CoreRequest

local store = Store.default(C.PERSIST.dataStore)
-- 2 quick attempts per load call; loadLoop keeps retrying every 15 s and shows the safe message meanwhile
local profiles = Profile.new(store, { loadTries = 2 })

local ctx = {
	C = C,
	Species = Species,
	Clock = Clock,
	Inv = Inv,
	Bank = Bank,
	Prog = Prog,
	Profile = Profile,
	profiles = profiles,
	store = store,
	sessions = {}, -- [plr] = session
	saveState = {}, -- [plr] = "loading" | "ok" | "unavailable" | "locked" | "lost"
	handlers = {}, -- [action] = fn(plr, payload)
	modules = {},
	remotes = remotes,
}
_G.CC_CORE_CTX = Run:IsStudio() and ctx or nil

local MESSAGES = {
	loading = "Loading your expedition…",
	unavailable = "Can't reach the save server. Your finds stay in your backpack; banking is paused until it reconnects.",
	locked = "Your profile is still saving on another server. Retrying…",
	lost = "Your profile was opened on another server, so this session stopped saving.",
	outdated = "This server runs an older version than your save. Rejoin to get a newer server.",
	back = "Saving reconnected. Banking is open again.",
	bankPaused = "Banking is paused until saving reconnects. Nothing was lost.",
}

---------------------------------------------------------------- outputs
function ctx.toast(plr, text, kind)
	if plr and plr.Parent then
		toastEv:FireClient(plr, { text = text, kind = kind or "info" })
	end
end
function ctx.fx(plr, payload)
	if plr and plr.Parent then
		fxEv:FireClient(plr, payload)
	end
end
function ctx.fxAll(payload)
	fxEv:FireAllClients(payload)
end

local dirty = {}
function ctx.push(plr)
	dirty[plr] = true
end

-- tiny event bus between gameplay modules: claim, bank, net, heartstone, hit, cliffhanger
local listeners = {}
function ctx.on(name, fn)
	listeners[name] = listeners[name] or {}
	table.insert(listeners[name], fn)
end
function ctx.emit(name, ...)
	for _, fn in ipairs(listeners[name] or {}) do
		task.spawn(fn, ...)
	end
end

-- after any backpack change: carried-Heartstone glow (others see cargo value) + state push
function ctx.invChanged(plr)
	local best
	for _, it in ipairs(Inv.bag(plr.UserId).items) do
		if it.kind == "heartstone" and (not best or (C.HEARTSTONE_VALUE[it.tier] or 0) > (C.HEARTSTONE_VALUE[best] or 0)) then
			best = it.tier
		end
	end
	if ctx.Visuals and plr.Character then
		ctx.Visuals.setCarryGlow(plr.Character, best)
	end
	ctx.push(plr)
end

local function snapshot(plr)
	local s = ctx.sessions[plr]
	local uid = plr.UserId
	local st = {
		saveState = ctx.saveState[plr] or "loading",
		storeKind = store.kind,
		serverNow = Clock.now(),
		items = Inv.view(uid),
		used = Inv.used(uid),
		capacity = Inv.bag(uid).capacity,
	}
	if s then
		local d = s.data
		st.coins, st.xp, st.level, st.slots = d.coins, d.xp, d.level, d.slots
		st.nextXp = Prog.nextLevelXp(d)
		st.levelXp = C.LEVEL_XP[d.level]
		st.bankCount = #d.bank
		st.codexCount = Prog.speciesCount(d)
		st.firstBank = d.flags.firstBankAt > 0
		st.tutorial = d.flags.tutorial
		st.netTier = d.flags.netTier
		st.highestCamp = d.highestCamp
		st.heartstones = {}
		for _, h in ipairs(d.heartstones) do
			st.heartstones[#st.heartstones + 1] = { uid=h.id, id=h.id, tier=h.tier, progress=h.progress, required=h.required, ready=h.ready }
		end
	end
	st.bank = ctx.bankState and ctx.bankState[plr] or {status="idle"}
	st.settings = s and s.data.settings or nil
	st.journal = s and s.data.journal or {}
	for _, m in ipairs(ctx.modules) do
		if m.state then
			local ok, err = pcall(m.state, plr, st)
			if not ok then
				warn("[CC] state hook: " .. tostring(err))
			end
		end
	end
	return st
end
ctx.snapshot = snapshot

---------------------------------------------------------------- durable transaction boundary
local completions = {} -- one callback for a pending durable transaction; world changes follow confirmation
local bankState = {}
ctx.bankState=bankState
local function finishCommit(plr,s,r)
 local pending=completions[s]
 if pending and r.ok then
  completions[s]=nil
  if pending.fn then local ok,err=pcall(pending.fn,r) if not ok then warn("[CC] committed effect: "..tostring(err)) end end
  ctx.invChanged(plr)
 end
end
function ctx.transaction(plr,tx,transform,committed)
 local s=ctx.sessions[plr]
 if not s or s.closing or s.lost then return {ok=false,reason="unavailable"} end
 if s.outcomePending and not string.match(tx,"^outcome:") then return {ok=false,reason="busy"} end
 if s.pending or s.busy or s.saving then return {ok=false,reason="busy"} end
 local r=profiles:transact(s,tx,transform)
 if r.ok then
  if committed then local ok,err=pcall(committed,r) if not ok then warn("[CC] committed effect: "..tostring(err)) end end
 elseif r.pending then
  completions[s]={fn=committed,tx=tx}
  ctx.saveState[plr]="unavailable"
  plr:SetAttribute("CC_SaveState","unavailable")
 end
 ctx.push(plr)
 return r
end
local function atBank(plr)
 local part=ctx.Camps and ctx.Camps.bankPart
 local ch=plr.Character
 local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 return part and hrp and hum and hum.Health>0 and (hrp.Position-part.Position).Magnitude<=18
  and (not ctx.Traversal or not ctx.Traversal.canBank or ctx.Traversal.canBank(plr))
end
function ctx.deposit(plr,txId)
 local s=ctx.sessions[plr]
 if not s or not atBank(plr) then return {ok=false,reason="bank_distance"} end
 if s.outcomePending then return {ok=false,reason="outcome_pending"} end
 if type(txId)~="string" or #txId>128 then txId=nil end
 local function complete(r)
  bankState[plr]={status="success",message="Saved at the bank.",retryable=false}
  if not r.dup and ((r.creatures or 0)+(r.heartstones or 0))>0 then
   ctx.toast(plr,string.format("Banked %d creatures and %d Heartstones. Saved.",r.creatures or 0,r.heartstones or 0),"good")
   ctx.fx(plr,{kind="bank",res=r}) ctx.emit("bank",plr,r)
   plr:SetAttribute("CC_FirstBank",s.data.flags.firstBankAt>0)
  end
  ctx.invChanged(plr)
 end
 if s.pending then
  local r=profiles:recover(s)
  if r.ok then
   finishCommit(plr,s,r)
   ctx.saveState[plr]="ok" plr:SetAttribute("CC_SaveState","ok")
  end
  ctx.push(plr)
  return r
 end
 if ctx.saveState[plr]~="ok" or s.busy or s.saving then
  bankState[plr]={status="error",message="Saving is unavailable. Your cargo is safe; retry here.",retryable=true}
  ctx.push(plr) return {ok=false,reason="unavailable"}
 end
 bankState[plr]={status="saving",message="Saving your finds…",retryable=false} ctx.push(plr)
 local tx=txId or HttpService:GenerateGUID(false)
 local r=Bank.deposit(s,plr.UserId,tx)
 if r.ok then complete(r)
 elseif r.pending then
  completions[s]={fn=complete,tx=tx}
  bankState[plr]={status="uncertain",message="Confirming the save. Please wait or retry here.",retryable=true}
  ctx.saveState[plr]="unavailable" plr:SetAttribute("CC_SaveState","unavailable")
 else bankState[plr]={status="error",message="Could not bank. Your finds stay in your backpack.",retryable=true} end
 ctx.push(plr)
 return r
end

---------------------------------------------------------------- sessions
local pendingRelease = {} -- [userId] = session whose release has not reached the store yet

-- write a banked deposit right away instead of waiting for the 60-s autosave (shrinks the crash window);
-- if a write is in flight, the 15-s loop picks it up
function ctx.saveSoon(s)
	if s.saving or s.pending or s.busy then
		s.saveAgain = true
		return
	end
	task.spawn(function()
		if s.pending or s.busy then s.saveAgain=true return end
		local plr
		for p, x in pairs(ctx.sessions) do
			if x == s then
				plr = p
			end
		end
		local ok, reason = profiles:save(s, false)
		if not ok and plr and reason ~= "lost" and ctx.sessions[plr] == s then
			ctx.saveState[plr] = "unavailable"
			plr:SetAttribute("CC_SaveState", "unavailable")
			ctx.push(plr)
		end
	end)
end

local function setSave(plr, st)
	local prev = ctx.saveState[plr]
	ctx.saveState[plr] = st
	plr:SetAttribute("CC_SaveState", st)
	-- loading/unavailable/locked are shown by the client's persistent save banner, so no toast for them
	if st ~= prev and st == "lost" then
		ctx.toast(plr, MESSAGES.lost, "warn")
	elseif st == "ok" and (prev == "unavailable" or prev == "locked") then
		ctx.toast(plr, MESSAGES.back, "good")
	end
	ctx.push(plr)
end

-- stub ids retired by the Codex roster (Species `replaces`) are remapped once, so the codex never double-counts
local function remapRetired(d)
	local map = Species.retired
	if not map then
		return false
	end
	local changed = false
	for _, b in ipairs(d.bank) do
		if map[b.species] then
			b.species, changed = map[b.species], true
		end
	end
	for _, h in ipairs(d.heartstones) do
		if map[h.species] then
			h.species, changed = map[h.species], true
		end
	end
	for old, new in pairs(map) do
		if d.codex[old] then
			d.codex[new] = (d.codex[new] or 0) + d.codex[old]
			d.codex[old] = nil
			changed = true
		end
	end
	return changed
end

local function afterLoad(plr, s)
	ctx.sessions[plr] = s
	if remapRetired(s.data) then
		s.dirty = true
	end
	Prog.refresh(s.data)
	Inv.bind(plr.UserId,s)
	Inv.setCapacity(plr.UserId, s.data.slots)
	local away = (s.data.lastSeen > 0) and (Clock.now() - s.data.lastSeen) or 0
 setSave(plr,"ok")
 plr:SetAttribute("CC_Tutorial",s.data.flags.tutorial)
 plr:SetAttribute("CC_FirstBank",s.data.flags.firstBankAt>0)
 for key,attr in pairs({textScale="CC_TextScale",reducedMotion="CC_ReducedMotion",timingAssist="CC_TimingAssist",headlampMode="CC_HeadlampMode"}) do
  plr:SetAttribute(attr,s.data.settings[key])
 end
 ctx.fx(plr,{kind="welcome",away=away,hatched={}})
	for _, m in ipairs(ctx.modules) do
		if m.onLoaded then
			task.spawn(m.onLoaded, plr, s)
		end
	end
end

local loading = {} -- [plr] = true while a loadLoop owns this player (PlayerAdded + startup sweep can overlap)

local function loadLoop(plr)
	if loading[plr] or ctx.sessions[plr] then
		return
	end
	loading[plr] = true
	local uid = plr.UserId
	-- same-server rejoin while the last release is still retrying: reuse that in-memory session (freshest data),
	-- but only once no write is in flight; if that write released the profile meanwhile, load normally.
	local pend = pendingRelease[uid]
	if pend then
		while pend.saving do
			task.wait(0.05)
		end
		if not pend.lost and not pend.released then
			pendingRelease[uid] = nil
			pend.leaving, pend.closing = false, false
			loading[plr] = nil
			afterLoad(plr, pend)
			return
		end
		pendingRelease[uid] = nil
	end
	setSave(plr, "loading")
	while plr.Parent do
		local s, reason = profiles:load(uid)
		if not plr.Parent then
			if s then
				profiles:save(s, true)
			end
			return
		end
		if s then
			loading[plr] = nil
			afterLoad(plr, s)
			return
		end
		setSave(plr, (reason == "locked" and "locked") or (reason == "newer" and "outdated") or "unavailable")
		task.wait(15)
	end
	loading[plr] = nil
end

local function release(plr, s)
	if not s then
		return
	end
	s.leaving, s.closing = true, true -- closing: no deposit can be acknowledged after the release snapshot
	completions[s]=nil -- durable state is reconstructed by onLoaded; old Player callbacks must not survive departure
	local ok = profiles:save(s, true)
	if ok or s.lost then
		return
	end
	-- keep retrying in the background (5 min); a rejoin to this server reuses the session meanwhile
	pendingRelease[s.userId] = s
	task.spawn(function()
		for _ = 1, 20 do
			task.wait(15)
			if pendingRelease[s.userId] ~= s or not s.leaving then
				return
			end
			if profiles:save(s, true) or s.lost then
				pendingRelease[s.userId] = nil
				return
			end
		end
		if pendingRelease[s.userId] == s then
			pendingRelease[s.userId] = nil
			s.lost = true -- never reuse it: the store may hold newer data by now
			if profiles.active[s.userId] == s then
				profiles.active[s.userId] = nil
			end
		end
		warn("[CC] gave up releasing profile " .. s.key .. " after 5 min; data since the last save is lost")
	end)
end

-- one join path for PlayerAdded and the startup sweep (Studio / deferred events can deliver PlayerAdded after the
-- sweep already loaded the player; a second pass must not reset the save state or clear the backpack)
local joined = setmetatable({}, { __mode = "k" })
local function onJoin(plr)
	if joined[plr] then
		return
	end
	joined[plr] = true
	Inv.clear(plr.UserId)
	ctx.saveState[plr] = "loading"
	plr.CharacterAdded:Connect(function(ch)
		task.delay(0.5, function()
			if plr.Parent then
				ctx.invChanged(plr)
			end
		end)
		for _, m in ipairs(ctx.modules) do
			if m.onCharacter then
				task.spawn(m.onCharacter, plr, ch)
			end
		end
	end)
	task.spawn(loadLoop, plr)
end
Players.PlayerAdded:Connect(onJoin)

Players.PlayerRemoving:Connect(function(plr)
	loading[plr] = nil
	local s = ctx.sessions[plr]
	for _, m in ipairs(ctx.modules) do
		if m.onLeave then
			local ok, err = pcall(m.onLeave, plr, s)
			if not ok then
				warn("[CC] onLeave: " .. tostring(err))
			end
		end
	end
	ctx.sessions[plr] = nil
	ctx.saveState[plr] = nil
	dirty[plr] = nil
	Inv.clear(plr.UserId)
	release(plr, s)
end)

-- shutdown: release EVERY session this server still owns, including leave-releases already in flight
-- (those live only in profiles.active); the server waits for BindToClose, not for other threads
game:BindToClose(function()
	local list, seen = {}, {}
	local function add(s)
		if s and not seen[s] then
			seen[s] = true
			list[#list + 1] = s
		end
	end
	for _, s in pairs(ctx.sessions) do
		add(s)
	end
	for _, s in pairs(pendingRelease) do
		add(s)
	end
	for _, s in pairs(profiles.active) do
		add(s)
	end
	local left = #list
	for _, s in ipairs(list) do
		s.closing = true
		task.spawn(function()
			profiles:save(s, true) -- waits for an in-flight write first, then releases (or reports "released")
			left -= 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 25 do
		task.wait(0.1)
	end
end)

-- autosave every 60 s (also refreshes the session lock). While saves fail, banking pauses (safe banner) and the
-- save is retried every 15 s, so no deposit is acknowledged that the store can't take.
task.spawn(function()
	while true do
		task.wait(15)
		for plr, s in pairs(ctx.sessions) do
			local failing = ctx.saveState[plr] == "unavailable"
			if not s.pending and (failing or s.saveAgain or Clock.now() - (s.lastSave or 0) >= C.PERSIST.autosave) and not s.saving then
				s.saveAgain = false
				task.spawn(function()
					local ok, reason = profiles:save(s, false)
					if ok then
						if ctx.saveState[plr] == "unavailable" and ctx.sessions[plr] == s then
							setSave(plr, "ok")
						end
					elseif reason == "lost" then
						setSave(plr, "lost")
						ctx.sessions[plr] = nil
						if not Run:IsStudio() then
							plr:Kick(MESSAGES.lost)
						end
					else
						warn("[CC] autosave failed for " .. s.key .. ": " .. tostring(reason))
						if ctx.sessions[plr] == s then
							setSave(plr, "unavailable")
						end
					end
				end)
			end
		end
	end
end)

task.spawn(function()
 while true do
  task.wait(3)
  for plr,s in pairs(ctx.sessions) do
   if s.pending and not s.saving and not s.busy then
    local r=profiles:recover(s)
    if r.ok then finishCommit(plr,s,r) setSave(plr,"ok")
    elseif r.reason=="lost" then
     completions[s]=nil setSave(plr,"lost")
     if not Run:IsStudio() then plr:Kick(MESSAGES.lost) end
    end
   end
  end
 end
end)

Run.Heartbeat:Connect(function()
	for plr in pairs(dirty) do
		dirty[plr] = nil
		if plr.Parent then
			stateEv:FireClient(plr, snapshot(plr))
		end
	end
end)

---------------------------------------------------------------- requests (rate-limited)
local buckets = {} -- [plr] = { tokens, t }
local function allow(plr,action)
	local lane=action=="traversal" and "traversal" or "menu"
	buckets[plr]=buckets[plr] or {}
	local b = buckets[plr][lane]
	local cap,rate=lane=="traversal" and 16 or 8,lane=="traversal" and 12 or 4
	local now = os.clock()
	if not b then
		b = { tokens = cap, t = now }
		buckets[plr][lane] = b
	end
	b.tokens = math.min(cap, b.tokens + (now - b.t) * rate)
	b.t = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end
Players.PlayerRemoving:Connect(function(plr)
	buckets[plr] = nil
end)

reqEv.OnServerEvent:Connect(function(plr, action, payload)
	if type(action) ~= "string" or #action > 32 or not allow(plr,action) then
		return
	end
	if action == "state" then
		ctx.push(plr)
		return
	end
 local s=ctx.sessions[plr]
 if s and (s.pending or s.busy or s.saving or s.outcomePending) and action~="traversal" and action~="bankRetry" then
  ctx.toast(plr,"Finishing a save. Please try again in a moment.","info") return
 end
 local h = ctx.handlers[action]
 if h then
		local ok, err = pcall(h, plr, type(payload) == "table" and payload or {})
		if not ok then
			warn("[CC] request " .. action .. ": " .. tostring(err))
		end
	end
end)

if Run:IsStudio() then
	ctx.devHandlers = {} -- filled by modules (init) and the Studio-only block below
end

ctx.handlers.bankRetry=function(plr)
 local r=ctx.deposit(plr)
 if r.reason=="bank_distance" then ctx.toast(plr,"Return to the Foothold campfire to retry banking.","info") end
end
ctx.handlers.settingsSet=function(plr,p)
 local allowed={textScale="CC_TextScale",reducedMotion="CC_ReducedMotion",timingAssist="CC_TimingAssist",headlampMode="CC_HeadlampMode"}
 if type(p.key)~="string" or not allowed[p.key] then return end
 local v=p.value
 if p.key=="textScale" then if type(v)~="number" or v~=v then return end v=math.clamp(v,0.9,1.3)
 elseif p.key=="headlampMode" then if v~="auto" and v~="on" and v~="off" then return end
 elseif type(v)~="boolean" then return end
 ctx.transaction(plr,"setting:"..HttpService:GenerateGUID(false),function(d) d.settings[p.key]=v return {ok=true} end,function()
  plr:SetAttribute(allowed[p.key],v) ctx.push(plr)
 end)
end

---------------------------------------------------------------- gameplay modules (B)
-- v4 P4 (run 2): Gear (shop, kit, canisters, Summit Points), Coop (rescue + party ropes), Training (Yard annex),
-- Weather (day/night + weather states)
for _, name in ipairs({ "Visuals", "Cargo", "DropPacks", "Camps", "Claims", "Nests", "Tutorial", "Gear", "Traversal", "Coop", "Training", "Home", "Discovery", "Weather", "CommerceCosmetics", "CommerceDisplays", "Commerce", "PublicProfile" }) do
	local m = SrvF:FindFirstChild(name)
	if m then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" then
			ctx[name] = mod
			ctx.modules[#ctx.modules + 1] = mod
		else
			warn("[CC] module " .. name .. " failed: " .. tostring(mod))
		end
	end
end
for _, m in ipairs(ctx.modules) do
	if m.init then
		local ok, err = pcall(m.init, ctx)
		if not ok then
			warn("[CC] init: " .. tostring(err))
		end
	end
end

---------------------------------------------------------------- Studio-only test hooks
if Run:IsStudio() then
	local dev = remotes:FindFirstChild("DevRequest")
	dev.OnServerEvent:Connect(function(plr, action, payload)
		local h = ctx.devHandlers[action]
		if h then
			local ok, err = pcall(h, plr, type(payload) == "table" and payload or {})
			if not ok then
				warn("[CC] dev " .. tostring(action) .. ": " .. tostring(err))
			end
		end
	end)
	-- leave + rejoin inside one Play Solo session, through the same release path as PlayerRemoving.
	-- p.failOnJoin: the store goes down after the leave (a join while the store is down).
	-- p.clockOffset: time away before the join (offline gap).
	function ctx.devRejoin(plr, p)
		p = p or {}
		local s = ctx.sessions[plr]
		for _, m in ipairs(ctx.modules) do
			if m.onLeave then
				pcall(m.onLeave, plr, s)
			end
		end
		ctx.sessions[plr] = nil
		Inv.clear(plr.UserId)
		release(plr, s)
		if p.failOnJoin and store.kind == "memory" then
			store.failAll = true
		end
		if type(p.clockOffset) == "number" then
			Clock.offset = p.clockOffset
		end
		task.spawn(loadLoop, plr)
		return s ~= nil and s.released == true
	end
	ctx.devHandlers.rejoin = function(plr, p)
		return ctx.devRejoin(plr, p)
	end
	ctx.devHandlers.storeFail = function(_, p)
		if store.kind == "memory" then
			store.failAll = p.on == true
		end
		return store.failAll
	end
	ctx.devHandlers.clock = function(_, p)
		Clock.offset = tonumber(p.offset) or 0
		return Clock.offset
	end
	ctx.devHandlers.grant = function(plr, p)
		local added = 0
		for _, g in ipairs(p.items or {}) do
			local it
			if g.kind == "heartstone" then
				local sp = Bank.rollHatch(g.tier or "Common", 1)
				it = Inv.newItem("heartstone", { tier = g.tier or "Common", species = sp, region = 1, source = "dev" })
			else
				local e = Species.query({ region = 1, rarity = g.rarity or "Common", kind = "creature" })[1]
				it = Inv.newItem("creature", { species = e.id, rarity = e.rarity, region = 1, source = type(g.source) == "string" and g.source or "dev" })
			end
			if Inv.add(plr.UserId, it) then
				added += 1
			end
		end
		ctx.push(plr)
		return added
	end
	-- fresh profile for repeated tutorial bot runs (keeps the session and its lock; Studio only)
	ctx.devHandlers.resetProfile = function(plr)
		local s = ctx.sessions[plr]
		if not s then
			return false
		end
		Inv.clear(plr.UserId)
		if ctx.DropPacks then
			ctx.DropPacks.clearOwner(plr.UserId)
		end
		for _, name in ipairs({ "Nests", "Camps", "Tutorial" }) do
			local m = ctx[name]
			if m and m.onLeave then
				pcall(m.onLeave, plr, s)
			end
		end
		s.data = Profile.default()
		Inv.bind(plr.UserId,s)
		s.dirty = true
		Prog.refresh(s.data)
		Inv.setCapacity(plr.UserId, s.data.slots)
		Clock.offset = 0
		local api = game:GetService("ServerStorage"):FindFirstChild("CC_CheckpointAPI")
		if api then
			api.SetCheckpoint:Invoke(plr, nil)
		end
		local sp = workspace:FindFirstChildOfClass("SpawnLocation")
		local ch = plr.Character
		if sp and ch then
			ch:PivotTo(sp.CFrame + Vector3.new(0, 4, 0))
		end
		ctx.invChanged(plr)
		if ctx.Tutorial then
			ctx.Tutorial.onLoaded(plr, s)
		end
		return true
	end
	-- fast bots (WalkSpeed > 12) scale the bank travel check; Studio only
	ctx.devHandlers.botSpeed = function(_, p)
		ctx.devSpeed = math.clamp(tonumber(p.factor) or 1, 1, 6)
		return ctx.devSpeed
	end
	ctx.devHandlers.setCheckpoint = function(plr, p)
		local api = game:GetService("ServerStorage"):FindFirstChild("CC_CheckpointAPI")
		return api and api.SetCheckpoint:Invoke(plr, type(p.name) == "string" and p.name or nil)
	end
	ctx.devHandlers.deposit = function(plr, p)
		return ctx.deposit(plr, p.tx)
	end
 ctx.devHandlers.snapshot=function(plr) return ctx.snapshot(plr) end
 ctx.devHandlers.request=function(plr,p) local h=ctx.handlers[p.action] if h then return h(plr,p.payload or {}) end end
 ctx.devHandlers.move=function(plr,p)
  local pos=Vector3.new(p.x,p.y,p.z)
  if ctx.Traversal then ctx.Traversal.travel(plr,pos,"test") else plr.Character:PivotTo(CFrame.new(pos)) end
  return true
 end
 ctx.devHandlers.status = function()
		local out = { store = store.kind, failAll = store.failAll, clockOffset = Clock.offset, players = {} }
		for _, plr in ipairs(Players:GetPlayers()) do
			local s = ctx.sessions[plr]
			local row = { name = plr.Name, saveState = ctx.saveState[plr], used = Inv.used(plr.UserId), capacity = Inv.bag(plr.UserId).capacity }
			if s then
				row.bank, row.coins, row.xp, row.level = #s.data.bank, s.data.coins, s.data.xp, s.data.level
				row.heartstones, row.highestCamp, row.tutorial = #s.data.heartstones, s.data.highestCamp, s.data.flags.tutorial
				row.firstBank = s.data.flags.firstBankAt > 0
				row.session = s.sessionId:sub(1, 8)
			end
			out.players[#out.players + 1] = row
		end
		out.log = profiles.log
		return out
	end
	-- the MCP's execute_luau runs in its own VM (no shared _G), so tests reach the live server through this
	local bridge = game:GetService("ServerStorage"):FindFirstChild("CC_DevBridge") or Instance.new("BindableFunction")
	bridge.Name = "CC_DevBridge"
	bridge.OnInvoke = function(action, p)
		p = type(p) == "table" and p or {}
		local plr = p.name and Players:FindFirstChild(p.name) or Players:GetPlayers()[1]
		local h = ctx.devHandlers[action]
		if not h then
			return "unknown action " .. tostring(action)
		end
		return HttpService:JSONEncode({ result = h(plr, p) })
	end
	bridge.Parent = game:GetService("ServerStorage")
end

for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onJoin, plr)
end
