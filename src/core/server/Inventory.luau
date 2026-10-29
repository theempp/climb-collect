-- Inventory (ServerScriptService.CC_CoreServer): durable unbanked backpack, bound to profile.cargo.
-- Cargo retains expedition risk until banked; ownership changes use Profile transactions. Item:
--   { uid, kind = "creature" | "heartstone", species, rarity, tier?, mutation, region, slots, acquiredAt, source }
-- Capacity = Progression.slots(profile); a Heartstone takes 2 slots (LOCKED). The client never adds items.
local HttpService = game:GetService("HttpService")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local Cargo = require(script.Parent.Cargo)

local Inv = {}
local bags = {} -- [userId] = { items = {}, capacity = n }
local sessions = {}
Inv._bags = bags

function Inv.bag(userId)
	local b = bags[userId]
	if not b then
		b = { items = {}, capacity = C.SLOTS_BASE }
		bags[userId] = b
	end
	local s = sessions[userId]
	if s then
		s.data.cargo = s.data.cargo or {}
		b.items, b.capacity = s.data.cargo, s.data.slots
	end
	return b
end

function Inv.bind(userId, session)
	sessions[userId] = session
	return Inv.bag(userId)
end

function Inv.locked(userId)
	local s = sessions[userId]
	return s and (s.pending ~= nil or s.committing or s.saving or s.outcomePending or s.lost or s.released or s.closing) or false
end

function Inv.session(userId) return sessions[userId] end

local function changed(userId)
	local s = sessions[userId]
	if s then s.dirty = true end
end

function Inv.clear(userId)
	bags[userId] = nil
	sessions[userId] = nil
end

function Inv.used(userId)
	local n = 0
	for _, it in ipairs(Inv.bag(userId).items) do
		n += it.slots
	end
	return n
end

function Inv.setCapacity(userId, cap)
	Inv.bag(userId).capacity = cap
end

function Inv.free(userId)
	local b = Inv.bag(userId)
	return b.capacity - Inv.used(userId)
end

function Inv.newItem(kind, fields)
	local it = {
		uid = HttpService:GenerateGUID(false),
		kind = kind,
		species = fields.species,
		rarity = fields.rarity,
		tier = fields.tier,
		mutation = fields.mutation or "",
		region = fields.region or 1,
		slots = (kind == "heartstone") and C.HEARTSTONE_SLOTS or 1,
		acquiredAt = fields.acquiredAt or os.time(),
		source = fields.source or "",
		discovery = fields.discovery,
	}
	it.discovery = it.discovery or { id = it.uid, place = fields.place or it.source, method = fields.method or (kind == "heartstone" and "heartstone" or "encounter"), at = it.acquiredAt }
	return it
end

-- add(userId, item) -> ok, reason ("full")
function Inv.add(userId, item)
	if Inv.locked(userId) then return false, "pending" end
	if Inv.free(userId) < item.slots then
		return false, "full"
	end
	local b = Inv.bag(userId)
	for _, it in ipairs(b.items) do
		if it.uid == item.uid then
			return false, "duplicate"
		end
	end
	b.items[#b.items + 1] = item
	changed(userId)
	return true
end

function Inv.remove(userId, uid)
	if Inv.locked(userId) then return nil, "pending" end
	local b = Inv.bag(userId)
	for i, it in ipairs(b.items) do
		if it.uid == uid then
			table.remove(b.items, i)
			changed(userId)
			return it
		end
	end
	return nil
end

-- atomically take every item (bank deposit / disconnect)
function Inv.takeAll(userId)
	if Inv.locked(userId) then return {} end
	local b = Inv.bag(userId)
	local items = b.items
	b.items = {}
	if sessions[userId] then sessions[userId].data.cargo = b.items end
	changed(userId)
	return items
end

function Inv.value(it)
	if it.kind == "heartstone" then
		return 100 + (C.HEARTSTONE_VALUE[it.tier] or 0)
	end
	return C.RANK[it.rarity] or 0
end

-- the item a guardian hit or a fall shakes loose first: Heartstones (highest tier), then rarity, then newest.
-- skip(it) -> true leaves that item out (protected cargo).
function Inv.mostValuable(userId, skip)
	local best, bv = nil, -1
	for _, it in ipairs(Inv.bag(userId).items) do
		local v = Inv.value(it) + (it.acquiredAt or 0) * 1e-12
		if v > bv and not (skip and skip(it)) then
			best, bv = it, v
		end
	end
	return best
end

-- client view (no uids needed for display, but kept for locker moves)
function Inv.view(userId)
	local out = {}
	for _, it in ipairs(Inv.bag(userId).items) do
		out[#out + 1] = Cargo.clientItem({ uid = it.uid, kind = it.kind, species = it.species, rarity = it.rarity, tier = it.tier, slots = it.slots, mutation = it.mutation, discovery = it.discovery, source = it.source, acquiredAt = it.acquiredAt })
	end
	return out
end

return Inv
