-- Durable banking and deliberate Heartstone hatching. Adventure credit follows original discovery identity.
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local H = require(RS.CC_Core:WaitForChild("HomeConfig"))
local Species = require(RS.CC_Core:WaitForChild("Species"))
local Clock, Inv, Prog, Profile = require(script.Parent.Clock), require(script.Parent.Inventory), require(script.Parent.Progression), require(script.Parent.Profile)
local CommerceRules = require(script.Parent.CommerceRules)
local Bank = {}
local function find(list, key, id)
	for _, entry in ipairs(list) do if entry[key] == id then return entry end end
	return nil
end
local function collect(data, item, award)
	if find(data.bank, "creatureId", item.uid) then return nil end
	local discovery = Profile.discovery(item, item.uid)
	data.bank[#data.bank + 1] = { creatureId = item.uid, species = item.species, rarity = item.rarity, mutation = item.mutation or "", acquiredAt = item.acquiredAt or discovery.at, source = item.source or "", discovery = discovery }
	local first = (data.codex[item.species] or 0) == 0
	data.codex[item.species] = (data.codex[item.species] or 0) + 1
	if not data.memories[item.species] then data.memories[item.species] = Profile.deepCopy(discovery) end
	local xp = award and math.floor((C.XP_ON_BANK[item.rarity] or 0) * (first and C.FIRST_OF_SPECIES_XP or 1)) or 0
	if xp > 0 then Prog.addXp(data, xp) end
	return xp, first
end
function Bank._collect(data, id, species, rarity, mutation, at, source)
	return collect(data, { uid = id, species = species, rarity = rarity, mutation = mutation, acquiredAt = at, source = source }, true)
end
function Bank.deposit(session, userId, txId)
	if not session or not session.owner or session.lost or session.released or session.closing then return { ok = false, reason = "unavailable" } end
	if session.userId ~= userId then return { ok = false, reason = "invalid" } end
	if type(txId) ~= "string" or #txId < 4 or #txId > 64 then return { ok = false, reason = "badtx" } end
	-- Isolated old tools use unbound bags; runtime binds on load.
	if Inv.session(userId) ~= session and not session.pending then
		-- A restored profile already owns its cargo. An empty/stale compatibility bag cannot replace it,
		-- nor may cargo from a different session be copied into a newer owner of the same profile.
		if not Inv.session(userId) and #session.data.cargo == 0 then
			session.data.cargo = Profile.deepCopy(Inv.bag(userId).items)
		end
		Inv.bind(userId, session)
	end
	local result = session.owner:transact(session, txId, function(data)
		local now = Clock.now()
		local res = { creatures = 0, heartstones = 0, coins = 0, xp = 0, items = {}, firsts = 0, adventure = 0 }
		local occupied, keep = table.clone(data.home.nests), {}
		for _, raw in ipairs(data.cargo) do
			local it = Profile.cleanItem(raw)
			if not it then
				keep[#keep + 1] = raw
				res.kept = (res.kept or 0) + 1
			elseif not find(data.bank, "creatureId", it.uid) and not find(data.heartstones, "id", it.uid) then
				local discovery = it.discovery
				local newDiscovery = not data.discoveryCredited[discovery.id]
				if it.kind == "heartstone" then
					data.heartstones[#data.heartstones + 1] = { id = it.uid, tier = it.tier, mutation = it.mutation, species = it.species, region = it.region, progress = 0, required = H.stoneProgress[it.tier], ready = false, acquiredAt = it.acquiredAt, source = it.source, discovery = discovery }
					res.heartstones += 1
					res.items[#res.items + 1] = { kind = "heartstone", id = it.uid, tier = it.tier }
				else
					local xp, first = collect(data, it, newDiscovery)
					if xp then
						local coins = newDiscovery and (C.COINS_ON_BANK[it.rarity] or 0) * CommerceRules.multiplier(data) or 0
						data.coins += coins
						res.coins += coins
						res.xp += xp
						res.creatures += 1
						res.firsts += first and 1 or 0
						res.items[#res.items + 1] = { kind = "creature", id = it.uid, species = it.species, rarity = it.rarity, first = first }
					end
				end
				if newDiscovery then data.discoveryCredited[discovery.id] = true; res.adventure += 1 end
			end
		end
		data.cargo = keep
		local efficiency = H.progressEfficiency[data.home.upgrade + 1] or 1
		for _, id in ipairs(occupied) do
			local stone = find(data.heartstones, "id", id)
			if stone and not stone.ready then
				stone.progress = math.min(stone.required, stone.progress + res.adventure * efficiency)
				stone.ready = stone.progress >= stone.required
			end
		end
		if res.creatures + res.heartstones > 0 then
			if data.flags.firstBankAt == 0 then data.flags.firstBankAt = now end
			data.stats.banked += res.creatures + res.heartstones
		end
		data.tx[#data.tx + 1] = txId
		while #data.tx > C.PERSIST.txKeep do table.remove(data.tx, 1) end
		Prog.refresh(data)
		return res
	end)
	if result.dup then result.creatures, result.heartstones, result.coins, result.xp, result.items = 0, 0, 0, 0, {} end
	return result
end
function Bank.rollHatch(tier, region, rng)
	rng = rng or Random.new()
	local weights = C.HATCH_WEIGHTS[tier] or C.HATCH_WEIGHTS.Common
	local total = 0
	for _, weight in pairs(weights) do total += weight end
	local pick, roll = nil, rng:NextNumber(0, total)
	for _, rarity in ipairs(C.RARITIES) do
		if weights[rarity] then roll -= weights[rarity]; if roll <= 0 and not pick then pick = rarity end end
	end
	local pool = Species.query({ region = region, rarity = pick or "Common", kind = "creature" })
	if #pool == 0 then pool = Species.query({ rarity = pick or "Common", kind = "creature" }) end
	local e = pool[rng:NextInteger(1, #pool)]
	return e.id, e.rarity
end
function Bank.hatchData(data, slot)
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > H.nestCount then return { ok = false, reason = "invalid" } end
		local id = data.home.nests[slot]
		local stone = find(data.heartstones, "id", id)
		if not stone or not stone.ready then return { ok = false, reason = "notReady" } end
		local species = stone.species
		if species == "" then
			local seed = 1
			for i = 1, #stone.id do seed = (seed * 31 + string.byte(stone.id, i)) % 2147483647 end
			species = Bank.rollHatch(stone.tier, stone.region, Random.new(seed))
		end
		local rarity = Species.rarity(species) or "Common"
		collect(data, { uid = stone.id, species = species, rarity = rarity, mutation = stone.mutation, acquiredAt = stone.acquiredAt, source = stone.source, discovery = stone.discovery }, false)
		for i, h in ipairs(data.heartstones) do if h.id == id then table.remove(data.heartstones, i); break end end
		data.home.nests[slot] = ""
		Prog.refresh(data)
		return { hatched = { id = id, species = species, rarity = rarity }, creatures = 1 }
end
function Bank.hatch(session, slot, txId)
	if not session or not session.owner then return { ok = false, reason = "invalid" } end
	return session.owner:transact(session, txId, function(data) return Bank.hatchData(data, slot) end)
end
-- Time never hatches or advances stones. Kept for existing service/tool compatibility.
function Bank.ripen(_session) return {} end
return Bank
