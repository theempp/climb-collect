-- Species (ReplicatedStorage.CC_Core): the ONE species table (Codex contract, design/autonomous-build-brief.md §0).
-- Every system refers to species only by snake_case id through this module: id -> name, region, rarity, ecology,
-- kind, stub. Until creatures/roster.json exists, placeholder stubs stand in (stub_common_1, ...). Spawn code
-- asks by query (region + rarity + ecology), never by a hard-coded id, so the roster can replace the stubs
-- without touching gameplay code. To wire the roster: generate a child ModuleScript "Roster" (returns an array
-- of entries in the same shape, optional `replaces = "stub_..."`) with tools/roster_to_luau.py.
-- Kinds: "creature" (collectible), "guardian" (nest guardian, not collectible). The server owns rarity.
local Species = {}

local REGION_COUNT = 5
local ECO_COMMON = { "ground", "hopping", "perched" }
local ECO_UNCOMMON = { "floating", "hiding" }
-- Readable names for the existing fallback artwork; stable stub ids still support roster replacement.
local REGION_NAMES = { "Foothill", "Forest", "Cliffside", "Stormridge", "Frostpeak" }
local COMMON_NAMES = { "Forager", "Hopper", "Lookout" }
local UNCOMMON_NAMES = { "Drifter", "Peeker" }
local WEATHER_NAMES = { "Storm Glider", "Aurora Drifter", "Snowfield Wanderer" }

local list = {}
local function add(e)
	e.stub = e.stub ~= false
	list[#list + 1] = e
end

-- 40 regional stubs (3 Common, 2 Uncommon, 1 Rare, 1 Epic = the guardian's pup, 1 Legendary per region) +
-- 3 weather-linked Legendaries + 1 guardian per region. Split PROPOSED (brief §1, confirmed "as written").
for r = 1, REGION_COUNT do
	for k = 1, 3 do
		local n = (r - 1) * 3 + k
		add({ id = "stub_common_" .. n, name = REGION_NAMES[r] .. " " .. COMMON_NAMES[k], region = r, rarity = "Common", ecology = ECO_COMMON[k], kind = "creature" })
	end
	for k = 1, 2 do
		local n = (r - 1) * 2 + k
		add({ id = "stub_uncommon_" .. n, name = REGION_NAMES[r] .. " " .. UNCOMMON_NAMES[k], region = r, rarity = "Uncommon", ecology = ECO_UNCOMMON[k], kind = "creature" })
	end
	add({ id = "stub_rare_" .. r, name = REGION_NAMES[r] .. " Nookling", region = r, rarity = "Rare", ecology = "hiding", kind = "creature" })
	add({ id = "stub_epic_" .. r, name = REGION_NAMES[r] .. " Pup", region = r, rarity = "Epic", ecology = "pup", kind = "creature", guardian = "stub_guardian_" .. r })
	add({ id = "stub_legendary_" .. r, name = REGION_NAMES[r] .. " Wayfarer", region = r, rarity = "Legendary", ecology = "floating", kind = "creature" })
	add({ id = "stub_guardian_" .. r, name = REGION_NAMES[r] .. " Guardian", region = r, ecology = "guardian", kind = "guardian", pup = "stub_epic_" .. r })
end
for k, w in ipairs({ "Storm", "AuroraNight", "SnowWhiteout" }) do
	local n = REGION_COUNT + k
	add({ id = "stub_legendary_" .. n, name = WEATHER_NAMES[k], region = 0, rarity = "Legendary", ecology = "floating", kind = "creature", weather = w })
end

-- roster merge (by id; `replaces` retires a stub so queries return the real species)
local rosterMod = script:FindFirstChild("Roster")
if rosterMod then
	local ok, roster = pcall(require, rosterMod)
	if ok and type(roster) == "table" then
		local retired = {}
		for _, e in ipairs(roster) do
			if type(e.id) == "string" and e.id:match("^[a-z][a-z0-9_]*$") then
				if e.replaces then
					retired[e.replaces] = e.id
				end
				e.stub = false
				list[#list + 1] = e
			end
		end
		local keep = {}
		for _, e in ipairs(list) do
			if not retired[e.id] then
				keep[#keep + 1] = e
			end
		end
		list = keep
		Species.retired = retired
	else
		warn("[CC] Species roster failed to load; using stubs: " .. tostring(roster))
	end
end

local byId = {}
for _, e in ipairs(list) do
	byId[e.id] = e
end

Species.list = list
function Species.get(id)
	return byId[id] or (Species.retired and Species.retired[id] and byId[Species.retired[id]]) or nil
end
function Species.isValid(id)
	return Species.get(id) ~= nil
end
function Species.rarity(id)
	local e = Species.get(id)
	return e and e.rarity or nil
end

-- query { region = n, rarity = "Common", kind = "creature", ecology = "ground" } -> array
function Species.query(q)
	local out = {}
	for _, e in ipairs(list) do
		if (q.region == nil or e.region == q.region) and (q.rarity == nil or e.rarity == q.rarity) and (q.kind == nil or e.kind == q.kind) and (q.ecology == nil or e.ecology == q.ecology) then
			out[#out + 1] = e
		end
	end
	return out
end

return Species
