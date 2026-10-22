-- Profile (ServerScriptService.CC_CoreServer): persistent player profile, schema v2, behind the
-- Store adapter. Server-authoritative; the client never writes it.
-- Stored envelope per key:  { data = <profile>, lock = { job, session, at } | nil, meta = { lastSession, saves, updated } }
-- Session lock: load takes the lock with UpdateAsync; a live lock held by another server (refreshed by its
-- autosave within lockTTL) blocks the load (retried, then reported as "locked"). A stale lock is taken over.
-- Ownership check on every save: meta.lastSession must still be this session, otherwise another server has
-- loaded the profile since; this session is then marked lost and never writes again (no overwrite, no dupes).
-- Writes: autosave every 60 s (dirty sessions), on leave (lock released), on shutdown; retry with backoff.
-- Schema extensions beyond §3.9 (PROPOSED, logged): heartstones[].species/region, lockers, tx, flags,
-- lastTrip, stats, timers, quarantine.
local HttpService = game:GetService("HttpService")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local Clock = require(script.Parent.Clock)
local H = require(game:GetService("ReplicatedStorage").CC_Core:WaitForChild("HomeConfig"))

local CommerceRules = require(script.Parent.CommerceRules)
local PortfolioRules=require(game.ReplicatedStorage.CC_Core.PortfolioRules)
local P = {}
P.__index = P
P.VERSION = 3

---------------------------------------------------------------- schema
function P.default()
	return {
		version = P.VERSION,
		commerce = CommerceRules.default(),
		dailyPractice=require(game.ReplicatedStorage.CC_Core.DailyPracticeRules).default(),
		portfolio={titleId="",showcase={},frameId=""},
		coins = 0,
		xp = 0,
		level = 1,
		slots = C.SLOTS_BASE,
		bank = {}, -- { creatureId, species, rarity, mutation, acquiredAt, source }
		codex = {}, -- [speciesId] = count
		heartstones = {}, -- banked storage: { id, tier, species, mutation, progress, required, ready, discovery }
		habitats = { { id = "h1", slots = { "", "", "" } } }, -- LOCKED start: 1 habitat x 3 slots
		tents = {}, -- [campName] = tier (missing = 1)
		highestCamp = 0,
		dailyGoal = { day = 0, id = "", done = false },
		streak = 0,
		lastSeen = 0,
		cosmetics = {},
		-- extensions (PROPOSED)
		lockers = {}, -- [campName] = { item, ... } safe from falls, not banked
		tx = {}, -- last C.PERSIST.txKeep deposit transaction ids
		flags = { tutorial = 0, tutorialV = 0, firstBankAt = 0, netTier = "cloth", parachuteIntroduced = false, parachutePractice = false },
		lastTrip = { left = 0, at = 0 },
		stats = { banked = 0, falls = 0, shaken = 0, recovered = 0, lost = 0, hits = 0 },
		timers = {}, -- [key] = epoch seconds: per-player spawn claims, nest/pup respawns (rejoin can't reset them)
		quarantine = {}, -- entries that failed validation (kept, never silently deleted)
		cargo = {}, -- durable backpack; ownership transfers use transact
		drops = {}, -- durable recovery manifests, reconstructed after reconnect
		receipts = {}, -- durable transaction results; item discovery ledger outlives receipt trimming
		discoveryCredited = {},
		memories = {},
		journal = {},
		expedition = {},
		settings = { textScale = 1, reducedMotion = false, timingAssist = true, headlampMode = "auto" },
		home = { decorations = {}, decorEquipped = {}, nests = { "", "" }, upgrade = 0, assigned = {}, favorites = {}, companion = "", uncollected = 0, settledAt = Clock.now() },
		-- v4 P4 (run 2, PROPOSED): Summit Points, owned / equipped cosmetics, earned kit, canisters, Training Yard,
		-- summits by route. Older profiles load with these defaults (no migration needed: sanitize fills them).
		gear = {
			points = 0,
			owned = {}, -- [shopId] = true
			equipped = { head = "", eyes = "", body = "" },
			kit = {}, -- [kitId] = true (bought at the Forge; level unlocks are computed, not stored)
			canisters = 0,
			training = { level = 0, lastAt = 0, unlocked = {}, completed = {} },
			summits = {}, -- [route] = count
		},
	}
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local o = {}
	for k, v in pairs(t) do
		o[k] = deepCopy(v)
	end
	return o
end
P.deepCopy = deepCopy

local function num(v, d)
	return (type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge) and v or d
end
local function str(v, d)
	return type(v) == "string" and v or d
end

function P.discovery(it, fallbackId)
	local v = type(it.discovery) == "table" and it.discovery or {}
	local source = str(it.source, "")
	if source == "" then source = "Unknown original location" end
	return {
		id = str(v.id, fallbackId or it.uid or it.id or it.creatureId or ""),
		place = str(v.place, source),
		method = str(v.method, (it.kind == "heartstone" or it.tier ~= nil or it.source == "heartstone") and "heartstone" or "encounter"),
		at = num(v.at, num(it.acquiredAt, num(it.startedAt, 0))),
	}
end

-- an unbanked item (locker contents): rebuilt from validated fields only, or nil if malformed
function P.cleanItem(it)
	if type(it) ~= "table" or type(it.uid) ~= "string" or type(it.species) ~= "string" then
		return nil
	end
	if it.kind == "heartstone" then
		if not C.RIPEN_SECONDS[it.tier] then
			return nil
		end
	elseif it.kind ~= "creature" or not C.RANK[it.rarity] then
		return nil
	end
	return {
		uid = it.uid,
		kind = it.kind,
		species = it.species,
		rarity = it.kind == "creature" and it.rarity or nil,
		tier = it.kind == "heartstone" and it.tier or nil,
		mutation = str(it.mutation, ""),
		region = num(it.region, 1),
		slots = it.kind == "heartstone" and C.HEARTSTONE_SLOTS or 1,
		acquiredAt = num(it.acquiredAt, 0),
		source = str(it.source, ""),
		discovery = P.discovery(it, it.uid),
		travel = type(it.travel) == "table" and deepCopy(it.travel) or nil,
	}
end

-- Keep every valid field, fill missing ones, move malformed list entries to quarantine (never delete).
function P.sanitize(d)
	local def = P.default()
	if type(d) ~= "table" then
		return def, 1
	end
	local fixes = 0
	local out = def
	out.version = P.VERSION
	out.commerce = CommerceRules.sanitize(d.commerce)
	out.coins = math.max(0, math.floor(num(d.coins, 0)))
	out.xp = math.max(0, math.floor(num(d.xp, 0)))
	out.level = math.clamp(math.floor(num(d.level, 1)), 1, #C.LEVEL_XP)
	out.slots = math.clamp(math.floor(num(d.slots, C.SLOTS_BASE)), C.SLOTS_BASE, C.SLOTS_MAX)
	out.highestCamp = math.clamp(math.floor(num(d.highestCamp, 0)), 0, #C.RESUME_CAMPS)
	out.streak = math.max(0, math.floor(num(d.streak, 0)))
	out.lastSeen = num(d.lastSeen, 0)
	local q = type(d.quarantine) == "table" and d.quarantine or {}
	local seen = {}
	for _, b in ipairs(type(d.bank) == "table" and d.bank or {}) do
		if type(b) == "table" and type(b.creatureId) == "string" and type(b.species) == "string" and not seen[b.creatureId] then
			seen[b.creatureId] = true
			out.bank[#out.bank + 1] = { creatureId = b.creatureId, species = b.species, rarity = str(b.rarity, "Common"), mutation = str(b.mutation, ""), acquiredAt = num(b.acquiredAt, 0), source = str(b.source, ""), discovery = P.discovery(b, b.creatureId) }
		else
			q[#q + 1] = { where = "bank", value = b }
			fixes += 1
		end
	end
	for k, v in pairs(type(d.codex) == "table" and d.codex or {}) do
		if type(k) == "string" and type(v) == "number" then
			out.codex[k] = math.max(0, math.floor(v))
		end
	end
	local hsSeen = {}
	for _, h in ipairs(type(d.heartstones) == "table" and d.heartstones or {}) do
		if type(h) == "table" and type(h.id) == "string" and H.stoneProgress[h.tier] and not hsSeen[h.id] and not seen[h.id] then
			hsSeen[h.id] = true
			local required = math.max(1, num(h.required, H.stoneProgress[h.tier]))
			local progress = math.clamp(num(h.progress, 0), 0, required)
			out.heartstones[#out.heartstones + 1] = { id = h.id, tier = h.tier, mutation = str(h.mutation, ""), species = str(h.species, ""), region = num(h.region, 1), progress = progress, required = required, ready = h.ready == true or progress >= required, acquiredAt = num(h.acquiredAt, num(h.startedAt, 0)), source = str(h.source, ""), discovery = P.discovery(h, h.id) }
		else
			q[#q + 1] = { where = "heartstones", value = h }
			fixes += 1
		end
	end
	if type(d.habitats) == "table" and #d.habitats > 0 then
		out.habitats = {}
		for i, h in ipairs(d.habitats) do
			if type(h) == "table" and type(h.slots) == "table" then
				local slots = {}
				for _, s in ipairs(h.slots) do
					slots[#slots + 1] = str(s, "")
				end
				out.habitats[#out.habitats + 1] = { id = str(h.id, "h" .. i), slots = slots }
			end
		end
		if #out.habitats == 0 then
			out.habitats = def.habitats
		end
	end
	for k, v in pairs(type(d.tents) == "table" and d.tents or {}) do
		if type(k) == "string" and type(v) == "number" then
			out.tents[k] = math.clamp(math.floor(v), 1, 3)
		end
	end
	if type(d.dailyGoal) == "table" then
		out.dailyGoal = { day = num(d.dailyGoal.day, 0), id = str(d.dailyGoal.id, ""), done = d.dailyGoal.done == true }
	end
	for _, c in ipairs(type(d.cosmetics) == "table" and d.cosmetics or {}) do
		if type(c) == "string" then
			out.cosmetics[#out.cosmetics + 1] = c
		end
	end
	for camp, items in pairs(type(d.lockers) == "table" and d.lockers or {}) do
		if type(camp) == "string" and type(items) == "table" then
			local list = {}
			for _, it in ipairs(items) do
				local clean = P.cleanItem(it)
				if clean then
					list[#list + 1] = clean
				else
					q[#q + 1] = { where = "locker:" .. camp, value = it }
					fixes += 1
				end
			end
			out.lockers[camp] = list
		end
	end
	for _, t in ipairs(type(d.tx) == "table" and d.tx or {}) do
		if type(t) == "string" then
			out.tx[#out.tx + 1] = t
		end
	end
	if type(d.flags) == "table" then
		out.flags.tutorial = math.max(0, math.floor(num(d.flags.tutorial, 0)))
		out.flags.tutorialV = math.max(0, math.floor(num(d.flags.tutorialV, 0)))
		out.flags.firstBankAt = num(d.flags.firstBankAt, 0)
		out.flags.netTier = C.NET_TIERS[d.flags.netTier] and d.flags.netTier or "cloth"
		out.flags.parachuteIntroduced = d.flags.parachuteIntroduced == true
		out.flags.parachutePractice = d.flags.parachutePractice == true
	end
	if type(d.lastTrip) == "table" then
		out.lastTrip = { left = math.max(0, math.floor(num(d.lastTrip.left, 0))), at = num(d.lastTrip.at, 0) }
	end
	for k, v in pairs(type(d.timers) == "table" and d.timers or {}) do
		if type(k) == "string" and #k <= 64 and type(v) == "number" then
			out.timers[k] = v
		end
	end
	if type(d.stats) == "table" then
		for k in pairs(out.stats) do
			out.stats[k] = math.max(0, math.floor(num(d.stats[k], 0)))
		end
	end
	if type(d.gear) == "table" then
		local g, og = d.gear, out.gear
		og.points = math.max(0, math.floor(num(g.points, 0)))
		local shop = {}
		for _, it in ipairs(C.SHOP or {}) do
			shop[it.id] = it
		end
		for id, v in pairs(type(g.owned) == "table" and g.owned or {}) do
			if shop[id] and v == true then
				og.owned[id] = true
			end
		end
		for _, slot in ipairs({ "head", "eyes", "body" }) do
			local id = type(g.equipped) == "table" and g.equipped[slot]
			og.equipped[slot] = (type(id) == "string" and og.owned[id] and shop[id].slot == slot) and id or ""
		end
		for id, v in pairs(type(g.kit) == "table" and g.kit or {}) do
			if C.KIT and C.KIT[id] and v == true then
				og.kit[id] = true
			end
		end
		og.canisters = math.clamp(math.floor(num(g.canisters, 0)), 0, C.CANISTER and C.CANISTER.max or 3)
		if type(g.training) == "table" then
			og.training.level = math.clamp(math.floor(num(g.training.level, 0)), 0, C.TRAINING and #C.TRAINING.gains or 5)
			og.training.lastAt = num(g.training.lastAt, 0)
			og.training.unlocked = type(g.training.unlocked) == "table" and deepCopy(g.training.unlocked) or {}
			og.training.completed = type(g.training.completed) == "table" and deepCopy(g.training.completed) or {}
		end
		for route, n in pairs(type(g.summits) == "table" and g.summits or {}) do
			if type(route) == "string" and #route <= 24 and type(n) == "number" then
				og.summits[route] = math.max(0, math.floor(n))
			end
		end
	end
	-- Persistent cargo and recovery state. One identity can occupy only one container.
	local owned = {}
	for id in pairs(seen) do owned[id] = true end
	for id in pairs(hsSeen) do owned[id] = true end
	local function cleanList(list, where)
		local result = {}
		for _, it in ipairs(type(list) == "table" and list or {}) do
			local clean = P.cleanItem(it)
			if clean and not owned[clean.uid] then
				owned[clean.uid] = true
				result[#result + 1] = clean
			else
				q[#q + 1] = { where = where, value = it }
				fixes += 1
			end
		end
		return result
	end
	-- Lockers were parsed above; apply the cross-container identity check here.
	for camp, list in pairs(out.lockers) do out.lockers[camp] = cleanList(list, "locker:" .. camp) end
	out.cargo = cleanList(d.cargo, "cargo")
	local dropSeen = {}
	for _, drop in ipairs(type(d.drops) == "table" and d.drops or {}) do
		if type(drop) == "table" and type(drop.id) == "string" and not dropSeen[drop.id]
			and type(drop.items) == "table" and num(drop.expiresAt, nil) and drop.expiresAt >= 0
			and type(drop.pos) == "table" and num(drop.pos.x, nil) and num(drop.pos.y, nil) and num(drop.pos.z, nil) then
			dropSeen[drop.id] = true
			local copied = deepCopy(drop)
			copied.items = cleanList(drop.items, "drop:" .. drop.id)
			out.drops[#out.drops + 1] = copied
		else
			q[#q + 1] = { where = "drops", value = drop }
			fixes += 1
		end
	end
	for _, receipt in ipairs(type(d.receipts) == "table" and d.receipts or {}) do
		if type(receipt) == "table" and type(receipt.id) == "string" and type(receipt.result) == "table" then
			out.receipts[#out.receipts + 1] = deepCopy(receipt)
		end
	end
	for id, value in pairs(type(d.discoveryCredited) == "table" and d.discoveryCredited or {}) do
		if type(id) == "string" and value == true then out.discoveryCredited[id] = true end
	end
	for _, entry in ipairs(out.bank) do out.discoveryCredited[entry.discovery.id] = true end
	for _, entry in ipairs(out.heartstones) do out.discoveryCredited[entry.discovery.id] = true end
	for species, memory in pairs(type(d.memories) == "table" and d.memories or {}) do
		if type(species) == "string" and type(memory) == "table" then out.memories[species] = P.discovery({ discovery = memory }) end
	end
	for _, entry in ipairs(out.bank) do
		if not out.memories[entry.species] then out.memories[entry.species] = deepCopy(entry.discovery) end
	end
	out.journal = type(d.journal) == "table" and deepCopy(d.journal) or {}
	out.expedition = type(d.expedition) == "table" and deepCopy(d.expedition) or {}
	if type(d.settings) == "table" then
		out.settings.textScale = math.clamp(num(d.settings.textScale, 1), 0.9, 1.4)
		out.settings.reducedMotion = d.settings.reducedMotion == true
		out.settings.timingAssist = d.settings.timingAssist ~= false
		out.settings.headlampMode = table.find({ "auto", "on", "off" }, d.settings.headlampMode) and d.settings.headlampMode or "auto"
	end
	if type(d.home) == "table" then
		local home = d.home
		out.home.decorations.lamp = type(home.decorations) == "table" and home.decorations.lamp == true or nil
		out.home.decorEquipped.lamp = out.home.decorations.lamp and type(home.decorEquipped) == "table" and home.decorEquipped.lamp == true or nil
		out.home.upgrade = math.clamp(math.floor(num(home.upgrade, 0)), 0, H.maxUpgrade)
		out.home.uncollected = math.max(0, num(home.uncollected, 0))
		out.home.settledAt = num(home.settledAt, num(d.lastSeen, Clock.now()))
		local nestSeen, assignmentSeen = {}, {}
		for i = 1, H.nestCount do
			local id = type(home.nests) == "table" and home.nests[i]
			if type(id) == "string" and hsSeen[id] and not nestSeen[id] then out.home.nests[i], nestSeen[id] = id, true end
		end
		for i = 1, H.baseSpaces + out.home.upgrade do
			local id = type(home.assigned) == "table" and home.assigned[i]
			out.home.assigned[i] = type(id) == "string" and seen[id] and not assignmentSeen[id] and id or ""
			if out.home.assigned[i] ~= "" then assignmentSeen[id] = true end
		end
		for id, fav in pairs(type(home.favorites) == "table" and home.favorites or {}) do
			if seen[id] and fav == true then out.home.favorites[id] = true end
		end
		out.home.companion = seen[home.companion] and home.companion or ""
	end
	out.dailyPractice=require(game.ReplicatedStorage.CC_Core.DailyPracticeRules).clean(d.dailyPractice)
	out.portfolio=PortfolioRules.cleanSelections(d.portfolio,out.bank)
	out.quarantine = q
	return out, fixes
end

-- version migrations: MIGRATIONS[v] upgrades a v-profile to v+1 (v0 = pre-schema / missing version)
local MIGRATIONS = {
	[2] = function(d) d.commerce = CommerceRules.sanitize(d.commerce); d.version = 3; return d end,
	[0] = function(d)
		d.version = 1
		return d
	end,
	[1] = function(d)
		local now = Clock.now()
		for _, stone in ipairs(type(d.heartstones) == "table" and d.heartstones or {}) do
			if type(stone) == "table" and H.stoneProgress[stone.tier] then
				local total = C.RIPEN_SECONDS[stone.tier]
				local readyAt = num(stone.readyAt, now + total)
				local startedAt = num(stone.startedAt, readyAt - total)
				local fraction = math.clamp((now - startedAt) / math.max(1, readyAt - startedAt), 0, 1)
				stone.required = H.stoneProgress[stone.tier]
				stone.progress = math.max(num(stone.progress, 0), fraction * stone.required)
				stone.ready = stone.ready == true or readyAt <= now or stone.progress >= stone.required
				stone.discovery = P.discovery(stone, stone.id)
			end
		end
		d.version = 2
		return d
	end,
}
function P.migrate(d)
	if type(d) ~= "table" then
		return P.default()
	end
	local v = math.floor(num(d.version, 0))
	while v < P.VERSION do
		local m = MIGRATIONS[v]
		if not m then
			break
		end
		d = m(d)
		v = math.floor(num(d.version, v + 1))
	end
	return d
end

---------------------------------------------------------------- service
-- P.new(store, { jobId = string, now = fn }) -> profile service (one per server; tests make two to act as two servers)
function P.new(store, opts)
	opts = opts or {}
	return setmetatable({
		store = store,
		jobId = opts.jobId or ((game.JobId ~= "" and game.JobId) or ("studio-" .. HttpService:GenerateGUID(false))),
		loadTries = opts.loadTries or C.PERSIST.loadTries,
		lockWait = opts.lockWait or C.PERSIST.lockWait,
		saveTries = opts.saveTries or C.PERSIST.saveTries,
		backoff = opts.backoff or 1,
		lockTTL = opts.lockTTL or C.PERSIST.lockTTL,
		active = {}, -- [userId] = live session on this server
		log = {},
	}, P)
end

function P:_log(s)
	self.log[#self.log + 1] = s
	if #self.log > 200 then
		table.remove(self.log, 1)
	end
end

function P:key(userId)
	return C.PERSIST.keyPrefix .. tostring(userId)
end

-- load(userId) -> session | nil, reason ("locked" | "store" | "error"), detail
function P:load(userId)
	local key = self:key(userId)
	local sessionId = HttpService:GenerateGUID(false)
	local lastErr, lockedBy = nil, nil
	for attempt = 1, self.loadTries do
		local blocked, fixes, newer = nil, 0, false
		local now = Clock.now()
		local ok, env, err = self.store:update(key, function(old)
			blocked, newer = nil, false
			old = type(old) == "table" and old or {}
			-- a profile written by a newer build: never downgrade or strip it on an older server
			if type(old.data) == "table" and num(old.data.version, 0) > P.VERSION then
				newer = true
				return nil
			end
			local lock = old.lock
			-- a live lock blocks, unless it is this server's own lock and that session is no longer active here
			-- (fast rejoin after a release that failed to reach the store)
			local ownDead = type(lock) == "table" and lock.job == self.jobId and not self.active[userId]
			if type(lock) == "table" and lock.session ~= sessionId and type(lock.at) == "number" and now - lock.at < self.lockTTL and not ownDead then
				blocked = lock
				return nil
			end
			local data, f = P.sanitize(P.migrate(old.data))
			fixes = f
			local meta = type(old.meta) == "table" and old.meta or {}
			return {
				data = data,
				lock = { job = self.jobId, session = sessionId, at = now },
				meta = { lastSession = sessionId, saves = num(meta.saves, 0), updated = num(meta.updated, 0), stoleFrom = (type(lock) == "table" and lock.session) or nil },
			}
		end)
		if ok and not blocked and type(env) == "table" and type(env.meta) == "table" and env.meta.lastSession == sessionId then
			local s = {
				owner = self,
				userId = userId,
				key = key,
				sessionId = sessionId,
				data = env.data,
				outcomePending = #(env.data.expedition.outcomes or {}) > 0,
				loadedAt = now,
				dirty = fixes > 0,
				lost = false,
				released = false,
				saving = false,
				lastSave = now,
				fixes = fixes,
				stoleLock = env.meta.stoleFrom ~= nil,
			}
			self:_log(string.format("load %s ok attempt %d fixes %d stole %s", key, attempt, fixes, tostring(s.stoleLock)))
			self.active[userId] = s
			return s
		end
		if ok and newer then
			self:_log(string.format("load %s refused: stored schema is newer than v%d", key, P.VERSION))
			return nil, "newer"
		end
		if ok and blocked then
			lockedBy = blocked
			self:_log(string.format("load %s blocked by live lock %s (attempt %d)", key, tostring(blocked.job), attempt))
			task.wait(self.lockWait)
		else
			lastErr = err
			self:_log(string.format("load %s store error (attempt %d): %s", key, attempt, tostring(err)))
			task.wait(math.min(8, self.backoff * 2 ^ (attempt - 1)))
		end
	end
	if lockedBy then
		return nil, "locked", lockedBy
	end
	return nil, "store", lastErr
end

-- save(session, release) -> ok, reason. release = clear the lock (leave/shutdown). Never writes after loss.
function P:save(session, release)
	if session.lost then return false, "lost" end
	if session.pending then
		local recovered = self:recover(session)
		if not recovered.ok then return false, recovered.reason or "store" end
	end
	if session.lost then
		return false, "lost"
	end
	if session.released then
		return true, "released"
	end
	-- one write at a time per session (no cap: two overlapping writes could commit an older snapshot last)
	while session.saving do
		task.wait(0.05)
	end
	-- re-check: the write we waited on may have released or lost the profile
	if session.lost then
		return false, "lost"
	end
	if session.released then
		return true, "released"
	end
	session.saving = true
	session.data.lastSeen = Clock.now()
	local snapshot = deepCopy(session.data)
	local okSize, enc = pcall(HttpService.JSONEncode, HttpService, snapshot)
	if not okSize or #enc > C.PERSIST.maxBytes then
		session.saving = false
		self:_log("save refused: profile not serializable or too large")
		return false, "size"
	end
	local lastErr
	for attempt = 1, (release and self.saveTries or 1) do
		local lostTo = nil
		local now = Clock.now()
		local ok, _, err = self.store:update(session.key, function(old)
			lostTo = nil
			old = type(old) == "table" and old or {}
			local meta = type(old.meta) == "table" and old.meta or {}
			if meta.lastSession ~= session.sessionId then
				lostTo = meta.lastSession or "?"
				return nil
			end
			return {
				data = snapshot,
				lock = (not release) and { job = self.jobId, session = session.sessionId, at = now } or nil,
				meta = { lastSession = session.sessionId, saves = num(meta.saves, 0) + 1, updated = now },
			}
		end)
		if ok and lostTo then
			session.lost = true
			session.saving = false
			if self.active[session.userId] == session then
				self.active[session.userId] = nil
			end
			self:_log(string.format("save %s: ownership lost to session %s; not writing", session.key, tostring(lostTo)))
			return false, "lost"
		end
		if ok then
			session.saving = false
			session.lastSave = now
			-- Gameplay can mark a session dirty while an autosave yields. Do not erase that work.
			local okCurrent, current = pcall(HttpService.JSONEncode, HttpService, session.data)
			session.dirty = not okCurrent or current ~= enc
			if release then
				session.released = true
				if self.active[session.userId] == session then
					self.active[session.userId] = nil
				end
			end
			return true
		end
		lastErr = err
		self:_log(string.format("save %s failed (attempt %d): %s", session.key, attempt, tostring(err)))
		if attempt < (release and self.saveTries or 1) then
			task.wait(math.min(8, self.backoff * 2 ^ (attempt - 1)))
		end
	end
	session.saving = false
	return false, "store", lastErr
end

local function receipt(data, id)
	for _, r in ipairs(data.receipts or {}) do
		if r.id == id then return r.result end
	end
	return nil
end

-- Physical outcomes can occur while a store request yields. Keep their identities in both live/candidate
-- outboxes, then merge at confirmation; an unavailable store never turns a fall into a free cargo shield.
function P.queueOutcome(session, outcome)
	local function append(data)
		data.expedition = data.expedition or {}
		data.expedition.outcomes = data.expedition.outcomes or {}
		for _, old in ipairs(data.expedition.outcomes) do if old.id == outcome.id then return end end
		data.expedition.outcomes[#data.expedition.outcomes + 1] = deepCopy(outcome)
	end
	append(session.data)
	if session.pending then append(session.pending.candidate) end
	session.outcomePending, session.dirty = true, true
end

-- Returning to the mountain can interrupt a pending home mutation. A replayed durable receipt must not
-- restore an obsolete home doorway after that physical return has already happened.
function P.clearHomeReturn(session)
	session.data.expedition.homeReturn = nil
	if session.pending then
		session.pending.candidate.expedition.homeReturn = nil
		session.clearedHomeReturn = true
	end
	session.dirty = true
end

local function resultCopy(result, duplicate)
	local out = deepCopy(result)
	out.ok = true
	if duplicate then out.dup = true end
	return out
end

-- A transaction's candidate and receipt are ONE UpdateAsync write. A timeout may mean the write committed;
-- hold its candidate and block ownership changes until replay resolves that exact receipt. Never roll back an
-- uncertain result or create a new transaction id for it. Transform executes once locally, before any yield.
function P:transact(session, txId, transform)
	if not session or session.owner ~= self or session.lost or session.released or session.closing then
		return { ok = false, reason = "unavailable" }
	end
	if type(txId) ~= "string" or #txId < 4 or #txId > 128 or type(transform) ~= "function" then
		return { ok = false, reason = "badtx" }
	end
	if session.pending then
		if session.pending.id ~= txId then return { ok = false, reason = "pending", pending = true, txId = session.pending.id } end
		return self:recover(session)
	end
	while session.saving do task.wait(0.02) end
	if session.pending then return { ok = false, reason = "pending", pending = true, txId = session.pending.id } end
	if session.lost or session.released or session.closing then return { ok = false, reason = "unavailable" } end
	local prior = receipt(session.data, txId)
	if prior then return resultCopy(prior, true) end
	local candidate = deepCopy(session.data)
	local okFn, res = pcall(transform, candidate)
	if not okFn then
		self:_log("transaction transform failed: " .. tostring(res))
		return { ok = false, reason = "invalid" }
	end
	res = type(res) == "table" and res or { ok = true }
	if res.ok == false then return res end
	res.ok, res.txId = true, txId
	candidate.receipts = candidate.receipts or {}
	candidate.receipts[#candidate.receipts + 1] = { id = txId, result = deepCopy(res), at = Clock.now() }
	while #candidate.receipts > 96 do table.remove(candidate.receipts, 1) end
	candidate.lastSeen = Clock.now()
	local okEnc, enc = pcall(HttpService.JSONEncode, HttpService, candidate)
	if not okEnc or #enc > C.PERSIST.maxBytes then return { ok = false, reason = "size" } end
	session.pending = { id = txId, candidate = candidate, result = res }
	return self:recover(session)
end

function P:recover(session)
	if session and session.lost then return { ok = false, reason = "lost" } end
	if not session or session.released then return { ok = false, reason = "unavailable" } end
	while session.saving do task.wait(0.02) end
	local pending = session.pending
	if not pending then return { ok = true, recovered = false } end
	session.saving, session.committing = true, true
	for attempt = 1, self.saveTries do
		local lost, replayed = false, false
		local now = Clock.now()
		local ok, env, err = self.store:update(session.key, function(old)
			lost, replayed = false, false
			local meta = type(old) == "table" and old.meta
			if type(meta) ~= "table" or meta.lastSession ~= session.sessionId then lost = true; return nil end
			if receipt(old.data or {}, pending.id) then replayed = true; return old end
			return {
				data = pending.candidate,
				lock = { job = self.jobId, session = session.sessionId, at = now },
				meta = { lastSession = session.sessionId, saves = num(meta.saves, 0) + 1, updated = now },
			}
		end)
		if ok and lost then
			session.lost, session.saving, session.committing = true, false, false
			if self.active[session.userId] == session then self.active[session.userId] = nil end
			return { ok = false, reason = "lost" }
		end
		local saved = ok and type(env) == "table" and type(env.data) == "table" and receipt(env.data, pending.id)
		if saved then
			local changed = false
			local outcomes = session.data.expedition and session.data.expedition.outcomes or {}
			-- For an outcome transaction, its chosen record was deliberately consumed in the candidate.
			local consumed = pending.result.outcomeId
			local target = env.data.expedition.outcomes or {}
			for _, outcome in ipairs(outcomes) do
				local exists = false
				for _, stored in ipairs(target) do if stored.id == outcome.id then exists = true; break end end
				if not exists and outcome.id ~= consumed then target[#target + 1] = deepCopy(outcome); changed = true end
			end
			env.data.expedition.outcomes = target
			if session.departurePosition then env.data.expedition.returnPos = deepCopy(session.departurePosition); changed = true end
			if session.clearedHomeReturn then env.data.expedition.homeReturn = nil; changed = true end
			if (session.data.highestCamp or 0) > (env.data.highestCamp or 0) then env.data.highestCamp = session.data.highestCamp; changed = true end
			for _, flag in ipairs({ "parachuteIntroduced", "parachutePractice" }) do
				if session.data.flags[flag] and not env.data.flags[flag] then env.data.flags[flag] = true; changed = true end
			end
			session.data = env.data
			session.clearedHomeReturn = nil
			if not session.leaving then session.departurePosition = nil end
			session.pending, session.saving, session.committing = nil, false, false
			session.outcomePending = #target > 0
			session.dirty, session.lastSave = changed, now
			local res = resultCopy(saved, false)
			res.reconciled = replayed
			return res
		end
		self:_log("transaction " .. pending.id .. " uncertain: " .. tostring(err))
		if attempt < self.saveTries then task.wait(math.min(4, self.backoff * 2 ^ (attempt - 1))) end
	end
	session.saving, session.committing = false, false
	return { ok = false, reason = "store", pending = true, txId = pending.id }
end

-- peek (tests/tools): the stored envelope, read-only
function P:peek(userId)
	return self.store:read(self:key(userId))
end

return P
