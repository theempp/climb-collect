-- Progression (ServerScriptService.CC_CoreServer): XP -> level, backpack slots (LOCKED 4 -> 12: levels 2-7 +1 each,
-- two codex milestones +1 each). Pure functions over profile data.
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("CC_Core"):WaitForChild("CoreConfig"))

local Prog = {}

function Prog.levelFor(xp)
	local lv = 1
	for i, need in ipairs(C.LEVEL_XP) do
		if xp >= need then
			lv = i
		end
	end
	return lv
end

function Prog.speciesCount(data)
	local n = 0
	for _, c in pairs(data.codex) do
		if c > 0 then
			n += 1
		end
	end
	return n
end

function Prog.slots(data)
	local s = C.SLOTS_BASE
	for _, lv in ipairs(C.SLOT_LEVELS) do
		if data.level >= lv then
			s += 1
		end
	end
	local species = Prog.speciesCount(data)
	for _, m in ipairs(C.SLOT_MILESTONES) do
		if species >= m then
			s += 1
		end
	end
	return math.min(s, C.SLOTS_MAX)
end

-- add XP; recompute level and slots; returns levelsGained
function Prog.addXp(data, amount)
	local before = data.level
	data.xp += math.max(0, math.floor(amount))
	data.level = math.max(data.level or 1, Prog.levelFor(data.xp))
	data.slots = math.min(C.SLOTS_MAX, math.max(data.slots or C.SLOTS_BASE, Prog.slots(data)))
	return data.level - before
end

function Prog.refresh(data)
	-- A rebalance/migration cannot revoke previously earned levels or backpack upgrades.
	data.level = math.max(data.level or 1, Prog.levelFor(data.xp))
	data.slots = math.min(C.SLOTS_MAX, math.max(data.slots or C.SLOTS_BASE, Prog.slots(data)))
end

-- XP still needed for the next level (nil at max)
function Prog.nextLevelXp(data)
	return C.LEVEL_XP[data.level + 1]
end

return Prog
