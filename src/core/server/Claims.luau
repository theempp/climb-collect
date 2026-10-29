-- Claims (ServerScriptService.CC_CoreServer): creature spawns and hold-to-claim (LOCKED verb).
-- Spawn anchors come from Workspace.World.Core.Spawns (CoreProps generator). Species are picked server-side by
-- query (region + rarity + ecology) from the one species table, so the Codex roster replaces stubs without code
-- changes. The server owns rarity; the client only holds the prompt.
-- Shared spawns: first valid claim wins, then the spot respawns after `Respawn` s with a re-rolled species.
-- Per-player spawns (tutorial common, guardian-free Rare nook): each player can claim them once per cooldown
-- (0 = once ever); the time is stored in the profile (timers) so a rejoin can't reset it. Others never lose it.
-- Deterministic edge cases (master.md §5): full bag -> refused, nothing lost; competing claimants -> first valid
-- Triggered wins, the other is told; hit during the hold -> refused (Prompts.validate); disconnect -> nothing.
local Players = game:GetService("Players")

local Claims = {}
local ctx, C, Inv, Clock, Species, Visuals, Prompts
local spawns = {} -- [id] = spawn
local folder
local rng = Random.new()
local REGION_NAMES = { "Green Valley", "Whispering Forest", "Broken Cliffs", "Storm Ridge", "Frozen Summit" }
local function discoveryPlace(id, region, authored)
	if type(authored) == "string" and authored:match("%S") then return authored end
	if id == "tut_common" then return "The Foothold" end
	if id == "nook_rare_r1" then return "Shepherd's hidden nook" end
	if id:match("^shep_%d+$") then return "Shepherd's Road" end
	if id:match("^out_%d+$") then return "Foothold outskirts" end
	return (REGION_NAMES[region] or "Mountain") .. " creature nook"
end

local function pickSpecies(sp)
	local pool = Species.query({ region = sp.region, rarity = sp.rarity, kind = "creature", ecology = sp.ecology })
	if #pool == 0 then
		pool = Species.query({ region = sp.region, rarity = sp.rarity, kind = "creature" })
	end
	if #pool == 0 then
		return nil
	end
	return sp.perPlayer and pool[1].id or pool[rng:NextInteger(1, #pool)].id
end

local function timerKey(sp)
	return "spawn:" .. sp.id
end

-- is this per-player spawn currently claimed by the player? (profile timers)
local function claimedBy(sp, plr)
	local s = ctx.sessions[plr]
	local t = s and s.data.timers[timerKey(sp)]
	if not t then
		return false
	end
	return sp.respawn == 0 or Clock.now() < t + sp.respawn
end
Claims.claimedBy = claimedBy

local function show(sp)
	sp.generation = (sp.generation or 0) + 1
	sp.species = pickSpecies(sp)
	if not sp.species then
		return
	end
	local m = Visuals.creature(sp.species, sp.pos)
	m.Name = "Creature_" .. sp.id
	m:SetAttribute("SpawnId", sp.id)
	m:SetAttribute("PerPlayer", sp.perPlayer)
	local e = Species.get(sp.species)
	local prompt = Prompts.make(m.PrimaryPart, {
		Name = "ClaimPrompt",
		ActionText = "Claim",
		ObjectText = (e and e.name or sp.species) .. "  " .. Visuals.pips(sp.rarity),
		HoldDuration = C.HOLD_SECONDS[sp.rarity] or 1,
		MaxActivationDistance = C.CLAIM_RANGE,
	})
	prompt.Triggered:Connect(function(plr)
		Claims.tryClaim(plr, sp, prompt)
	end)
	sp.model, sp.prompt, sp.available = m, prompt, true
	m.Parent = folder
end

-- Consume one authored shared occurrence once. An uncertain departing claimant conservatively consumes the
-- occurrence too: immediately unreserving could award it twice if the durable write already committed.
local function consumeShared(sp, generation)
	if sp.perPlayer or sp.generation ~= generation or not sp.available then return false end
	sp.available, sp.reserved, sp.reservedGeneration = false, nil, nil
	if sp.model then sp.model:Destroy() end
	sp.model, sp.prompt = nil, nil
	task.delay(sp.respawn, function()
		if sp.generation == generation and not sp.available then show(sp) end
	end)
	return true
end

function Claims.tryClaim(plr, sp, prompt)
	local ok, why = Prompts.validate(prompt, plr)
	if not ok then
		if why == "hit" then
			ctx.toast(plr, "Knocked off balance. Try again.", "warn")
		end
		return
	end
	if sp.perPlayer then
		if claimedBy(sp, plr) then
			return
		end
		if not ctx.sessions[plr] then
			ctx.toast(plr, "Wait for your profile to load.", "warn")
			return
		end
	elseif not sp.available then
		ctx.toast(plr, "Someone else claimed it first.", "info")
		return
	end
	local place = sp.label or discoveryPlace(sp.id, sp.region)
	local item = Inv.newItem("creature", { species = sp.species, rarity = sp.rarity, region = sp.region, source = sp.id, acquiredAt = Clock.now(), place = place, method = sp.ecology == "hiding" and "Hidden nook" or "Encounter" })
	local species,generation=sp.species,sp.generation
	ctx.Cargo.acquire(plr,item,{
		pos=sp.pos,label=place,
		valid=function()
			local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			return hrp and (hrp.Position-sp.pos).Magnitude<=C.CLAIM_RANGE+4 and sp.generation==generation and sp.species==species and not sp.reserved and (sp.perPlayer and not claimedBy(sp,plr) or not sp.perPlayer and sp.available)
		end,
		reserve=function() if not sp.perPlayer then if sp.reserved or not sp.available or sp.generation~=generation then return false end sp.reserved,sp.reservedGeneration=plr,generation end return true end,
		unreserve=function() if sp.reserved==plr and sp.reservedGeneration==generation then sp.reserved,sp.reservedGeneration=nil,nil end end,
		write=function(d)
			if sp.perPlayer then
				local t=d.timers[timerKey(sp)]
				if t and (sp.respawn==0 or Clock.now()<t+sp.respawn) then return false,"claimed" end
				d.timers[timerKey(sp)]=Clock.now()
			end
			return true
		end,
		commit=function(saved)
			if not sp.perPlayer then
				consumeShared(sp,generation)
			end
			local e=Species.get(saved.species)
			ctx.toast(plr,"Claimed "..(e and e.name or saved.species).."  "..Visuals.pips(sp.rarity),"good")
			ctx.fx(plr,{kind="claim",species=saved.species,rarity=sp.rarity,pos=sp.pos})
			ctx.emit("claim",plr,sp.id,saved)
		end,
	})
end

function Claims.onLeave(plr)
	for _, sp in pairs(spawns) do
		if sp.reserved == plr then consumeShared(sp, sp.reservedGeneration) end
	end
end

function Claims.init(c)
	ctx = c
	C, Inv, Clock, Species = c.C, c.Inv, c.Clock, c.Species
	Visuals = require(script.Parent.Visuals)
	Prompts = require(script.Parent.Prompts)
	ctx.Claims = Claims
	local core = workspace:WaitForChild("World"):WaitForChild("Core", 10)
	if not core or not core:FindFirstChild("Spawns") then
		warn("[CC] Claims: Workspace.World.Core.Spawns missing (run CoreProps.build)")
		return
	end
	folder = core:FindFirstChild("Creatures") or Instance.new("Folder")
	folder.Name = "Creatures"
	folder.Parent = core
	for _, a in ipairs(core.Spawns:GetChildren()) do
		local id = a:GetAttribute("SpawnId")
		if id then
			local sp = {
				id = id,
				label = discoveryPlace(id, a:GetAttribute("Region") or 1, a:GetAttribute("DiscoveryLabel") or a:GetAttribute("Label")),
				pos = a.Position,
				rarity = a:GetAttribute("Rarity") or "Common",
				ecology = a:GetAttribute("Ecology"),
				region = a:GetAttribute("Region") or 1,
				perPlayer = a:GetAttribute("PerPlayer") == true,
				respawn = a:GetAttribute("Respawn") or 90,
			}
			spawns[id] = sp
			show(sp)
		end
	end
end

-- per-player spawns this player has claimed (client hides them locally)
function Claims.state(plr, st)
	-- per-player spawns this player has claimed, with the time they come back (client hides them until then)
	local hidden = {}
	local s = ctx.sessions[plr]
	for id, sp in pairs(spawns) do
		if sp.perPlayer and claimedBy(sp, plr) then
			local t = s and s.data.timers[timerKey(sp)] or 0
			hidden[#hidden + 1] = { id = id, untilAt = sp.respawn == 0 and math.huge or (t + sp.respawn) }
		end
	end
	st.hiddenSpawns = hidden
end

function Claims.spawnPos(id)
	return spawns[id] and spawns[id].pos or nil
end
Claims._spawns = spawns
return Claims
