-- Personal home courts use the existing cabin doors. No terrain/world rebuild; only visited courts exist.
-- Economic actions run against the owner's durable profile and require its physical station.
local Players, RS, Http = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("HttpService")
local C, H = require(RS.CC_Core.CoreConfig), require(RS.CC_Core.HomeConfig)
local Profile, Clock, Bank = require(script.Parent.Profile), require(script.Parent.Clock), require(script.Parent.Bank)
local CommerceRules = require(script.Parent.CommerceRules)
local Home = {}
local ctx, folder
local portals, directory, visits, rooms, roomSlots, opened, companions, petAt = {}, {}, {}, {}, {}, {}, {}, {}
local function bankItem(data, id)
	for _, b in ipairs(data.bank) do if b.creatureId == id then return b end end
	return nil
end
local function stoneItem(data, id)
	for _, s in ipairs(data.heartstones) do if s.id == id then return s end end
	return nil
end
function Home.rate(data)
	local rate, seen = 0, {}
	for i = 1, H.baseSpaces + data.home.upgrade do
		local b = bankItem(data, data.home.assigned[i])
		if b then
			local multiplier = (b.mutation and b.mutation ~= "") and (1 + C.MUTATION_BONUS) or 1
			rate += (C.YIELD_PER_HOUR[b.rarity] or 0) * multiplier * (seen[b.species] and C.DUPLICATE_YIELD or 1)
			seen[b.species] = true
		end
	end
	return rate * CommerceRules.multiplier(data)
end
function Home.settle(data, now)
	local home = data.home
	local elapsed = math.clamp(now - (home.settledAt or now), 0, H.offlineCap)
	home.uncollected = math.max(0, home.uncollected or 0) + elapsed * Home.rate(data) / 3600
	home.settledAt = now
	return home.uncollected
end
function Home.best(data)
	local chosen, used, species = {}, {}, {}
	for _ = 1, H.baseSpaces + data.home.upgrade do
		local best, score
		for _, b in ipairs(data.bank) do
			if not used[b.creatureId] then
				local value = (C.YIELD_PER_HOUR[b.rarity] or 0) * ((b.mutation and b.mutation ~= "") and 1 + C.MUTATION_BONUS or 1) * (species[b.species] and C.DUPLICATE_YIELD or 1)
				if not score or value > score or (value == score and b.creatureId < best.creatureId) then best, score = b, value end
			end
		end
		chosen[#chosen + 1] = best and best.creatureId or ""
		if best then used[best.creatureId], species[best.species] = true, true end
	end
	return chosen
end
local function pos(plr)
	local ch = plr.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end
local function near(plr, point, range)
	local p = pos(plr)
	return p and (p - point).Magnitude <= (range or H.stationRange)
end
local function atHomeStation(plr, room)
	local visit, p = visits[plr], pos(plr)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if not visit or visit.returning or rooms[visit.owner] ~= room or not room or not room.occupants[plr]
		or not p or not hum or hum.Health <= 0 then return false end
	local offset = p - room.center
	-- Both side nests show prompts out to their outer edges. Use the same 32-stud station reach for
	-- opening, actions and closing, bounded to this visited 58x60 court rather than nearby world space.
	return math.abs(offset.X) <= 29 and math.abs(offset.Z) <= 30 and offset.Y >= -1 and offset.Y <= 16
		and (p - room.station.Position).Magnitude <= 32
end
local function part(parent, name, size, at, material, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Material, p.Color = name, size, CFrame.new(at), material, color
	p.Anchored, p.CastShadow = true, false
	p.Parent = parent
	return p
end
local function label(parent, text)
	local g = Instance.new("BillboardGui")
	g.Name, g.Size, g.StudsOffset, g.MaxDistance = "HomeLabel", UDim2.fromOffset(260, 56), Vector3.new(0, 3, 0), 75
	local l = Instance.new("TextLabel")
	l.Size, l.BackgroundTransparency, l.Text, l.Font, l.TextSize = UDim2.fromScale(1, 1), 1, text, Enum.Font.GothamMedium, 16
	l.TextColor3, l.TextStrokeTransparency, l.TextWrapped = Color3.fromRGB(255, 231, 185), 0.25, true
	l.Parent, g.Parent = g, parent
end
local function prompt(p, name, action, object, fn)
	local pr = require(script.Parent.Prompts).make(p, { Name = name, ActionText = action, ObjectText = object, HoldDuration = 0, MaxActivationDistance = 12 })
	pr.Triggered:Connect(function(plr)
		if near(plr, p.Position, 16) then fn(plr) end
	end)
	return pr
end
local function travel(plr, destination, reason)
	if ctx.Traversal and ctx.Traversal.travel then return ctx.Traversal.travel(plr, destination, reason) end
	ctx.toast(plr, "Travel is still loading. Try again in a moment.", "warn")
	return false
end
local function redraw(owner)
	local room, s = rooms[owner], ctx.sessions[owner]
	if not room or not s then return end
	if ctx.CommerceCosmetics then ctx.CommerceCosmetics.home(room,s.data) end
	room.display:ClearAllChildren()
	for i = 1, H.baseSpaces + s.data.home.upgrade do
		local x, z = ((i - 1) % 3 - 1) * 12, 3 + math.floor((i - 1) / 3) * 12
		local at = room.center + Vector3.new(x, 0.6, z)
		local b = bankItem(s.data, s.data.home.assigned[i])
		local e = b and ctx.Species.get(b.species)
		local habitat = part(room.display, "Habitat_" .. i, Vector3.new(9, 0.6, 9), at, Enum.Material.Grass, Color3.fromRGB(84, 112, 78))
		habitat:SetAttribute("HomeOwnerId", owner.UserId)
		habitat:SetAttribute("HabitatEcology", e and e.ecology or "adaptable")
		label(habitat, b and ((e and e.name or b.species) .. "\n" .. (e and e.ecology or "habitat")) or ("Earning space " .. i .. "\nAssign at the home station"))
		if b and ctx.Visuals then
			local m = ctx.Visuals.creature(b.species, at + Vector3.new(0, 2.1, 0))
			m:SetAttribute("HomeOwnerId", owner.UserId)
			m:SetAttribute("CreatureId", b.creatureId)
			for _, desc in ipairs(m:GetDescendants()) do
				if desc:IsA("ParticleEmitter") or desc:IsA("Beam") then desc.Enabled = false end
				if desc:IsA("BasePart") then desc.CanCollide, desc.CanTouch = false, false end
			end
			m.Parent = room.display
		end
	end
	for i, nest in ipairs(room.nests) do
		local stone = stoneItem(s.data, s.data.home.nests[i])
		nest:SetAttribute("StoneId", stone and stone.id or "")
		local old = nest:FindFirstChild("HomeLabel")
		if old then old:Destroy() end
		label(nest, stone and (stone.tier .. " Heartstone\n" .. (stone.ready and "Ready to hatch" or string.format("Adventure %.1f / %d", stone.progress, stone.required))) or ("Heartstone nest " .. i .. "\nPlace a banked stone"))
	end
end
local function openStation(plr)
	local visit = visits[plr]
	local room = visit and rooms[visit.owner]
	if room and atHomeStation(plr, room) then
		opened[plr] = true
		ctx.fx(plr, { kind = "home", open = true })
		ctx.push(plr)
	end
end
local function roomFor(owner)
	if rooms[owner] then return rooms[owner] end
	local slot = 1
	while roomSlots[slot] do slot += 1 end
	roomSlots[slot] = owner
	local center = Vector3.new(12000 + (slot % 6) * H.roomSpacing, H.roomY, math.floor(slot / 6) * H.roomSpacing)
	local model = Instance.new("Model")
	model.Name = "Home_" .. owner.UserId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("HomeOwnerId", owner.UserId)
	local slate, warm = Color3.fromRGB(62, 66, 76), Color3.fromRGB(182, 143, 89)
	part(model, "Court", Vector3.new(58, 3, 60), center - Vector3.new(0, 1.5, 0), Enum.Material.Slate, slate)
	-- Visible stone parapets keep this separate safe home court contained; mountain edges remain untouched.
	for _, wall in ipairs({ { Vector3.new(58, 5, 2), Vector3.new(0, 2.5, 29) }, { Vector3.new(58, 5, 2), Vector3.new(0, 2.5, -29) }, { Vector3.new(2, 5, 56), Vector3.new(28, 2.5, 0) }, { Vector3.new(2, 5, 56), Vector3.new(-28, 2.5, 0) } }) do
		part(model, "StoneWall", wall[1], center + wall[2], Enum.Material.Rock, slate)
	end
	local station = part(model, "HomeStation", Vector3.new(8, 3, 3), center + Vector3.new(0, 1.5, -15), Enum.Material.Wood, warm)
	label(station, owner.DisplayName .. "'s home\nNests · habitats · collection")
	local display = Instance.new("Folder"); display.Name, display.Parent = "Displays", model
	local room = { slot = slot, center = center, model = model, station = station, display = display, nests = {}, occupants = {} }
	rooms[owner] = room
	for i = 1, 2 do
		local nest = part(model, "HeartstoneNest_" .. i, Vector3.new(5, 1.4, 5), center + Vector3.new(i == 1 and -17 or 17, 0.7, -15), Enum.Material.Slate, warm)
		room.nests[i] = nest
		prompt(nest, "NestPrompt", "Manage nests", "Heartstone nest", openStation)
	end
	local collectPad = part(model, "CollectPad", Vector3.new(6, 0.35, 6), center + Vector3.new(0, 0.2, -5), Enum.Material.Slate, warm)
	label(collectPad, "Collect home income")
	prompt(collectPad, "CollectPrompt", "Collect income", "Home earnings", function(plr)
		if plr == owner then ctx.handlers.homeCollect(plr, {}) else ctx.toast(plr, "This is your host's collect pad.", "info") end
	end)
	prompt(station, "HomePrompt", "Manage home", "Home station", openStation)
	local exitPad = part(model, "ReturnDoor", Vector3.new(7, 5, 1), center + Vector3.new(0, 2.5, -25), Enum.Material.Wood, warm)
	label(exitPad, "Return to the same cabin entrance")
	prompt(exitPad, "ReturnPrompt", "Return to Foothold", "Cabin entrance", function(plr) Home.returnHome(plr) end)
	model.Parent = folder
	redraw(owner)
	return room
end
local function cleanRoom(owner)
	local room = rooms[owner]
	if room and next(room.occupants) == nil then
		room.model:Destroy(); roomSlots[room.slot], rooms[owner] = nil, nil
	end
end
function Home.returnHome(plr, force)
	local visit, s = visits[plr], ctx.sessions[plr]
	if not visit or not s or visit.returning then return end
	if s.pending and not force then ctx.toast(plr, "Your last change is still saving. Please retry shortly.", "warn"); return end
	visit.returning = true
	if not travel(plr, visit.entrance, "homeReturn") then visit.returning = nil; return end
	if visits[plr] ~= visit or ctx.sessions[plr] ~= s then return end
	local room = rooms[visit.owner]
	if room then room.occupants[plr] = nil end
	visits[plr], opened[plr] = nil, nil
	plr:SetAttribute("CC_InHome", false)
	if plr.Character then plr.Character:SetAttribute("CC_HomeVisit", false) end
	Profile.clearHomeReturn(s)
	ctx.saveSoon(s)
	ctx.push(plr)
	cleanRoom(visit.owner)
end
local function enter(plr, owner)
	local door, s = directory[plr], ctx.sessions[plr]
	if not door or not s or not ctx.sessions[owner] or not near(plr, door.Position, 18) or visits[plr] then return end
	local entrance = door.Position + Vector3.new(0, 4, 0)
	local res = ctx.transaction(plr, "home-enter:" .. Http:GenerateGUID(false), function(d)
		d.expedition.homeReturn = { x = entrance.X, y = entrance.Y, z = entrance.Z }
		return { ok = true }
	end, function()
		if ctx.sessions[plr] ~= s then return end
		if not plr.Parent or not owner.Parent or not ctx.sessions[owner] or not near(plr, door.Position, 18) then
			Profile.clearHomeReturn(s); ctx.saveSoon(s); return
		end
		local room = roomFor(owner)
		-- Reserve occupancy before destination streaming yields. A departing host can now return this
		-- visitor, and Traversal's travel token cancels the superseded entry without leaving a void court.
		local visit = { owner = owner, entrance = entrance }
		visits[plr], room.occupants[plr], directory[plr] = visit, true, nil
		if plr.Character then plr.Character:SetAttribute("CC_HomeVisit", true) end
		if not travel(plr, room.center + Vector3.new(0, 4, -20), "homeEnter") then
			if visits[plr] ~= visit or visit.returning then return end
			visits[plr], room.occupants[plr] = nil, nil
			if plr.Character then plr.Character:SetAttribute("CC_HomeVisit", false) end
			Profile.clearHomeReturn(s); ctx.saveSoon(s)
			cleanRoom(owner); return
		end
		if visits[plr] ~= visit or visit.returning or ctx.sessions[plr] ~= s then return end
		if not owner.Parent or not ctx.sessions[owner] then Home.returnHome(plr, true); return end
		plr:SetAttribute("CC_InHome", true)
		ctx.toast(plr, owner == plr and "Welcome home. Nests and habitats are at the stone station." or ("Visiting " .. owner.DisplayName .. ". Your host's home is read-only."), "info")
		opened[plr] = true
		ctx.fx(plr, { kind = "home", open = true })
		ctx.push(plr)
	end)
	if not res.ok then ctx.toast(plr, "Home travel is waiting for saving. Retry when connected.", "warn") end
	ctx.push(plr)
end
local function physicalOwner(plr)
	local v, s = visits[plr], ctx.sessions[plr]
	local room = v and rooms[v.owner]
	if not s or not room or v.owner ~= plr or not atHomeStation(plr, room) then return nil end
	return s
end
local errors = { pending = "Your last change is still saving.", store = "Saving is unavailable. Your change will be reconciled before another action.", notReady = "This stone needs more newly discovered expedition finds.", funds = "You need more Cairn Coins.", unavailable = "Your profile is not ready.", full = "That nest or space is occupied.", invalid = "That choice is no longer available." }
local function mutate(plr, payload, kind, fn, anywhere)
	local s = anywhere and ctx.sessions[plr] or physicalOwner(plr)
	if not s then ctx.toast(plr, "Use your own physical home station for that action.", "warn"); return end
	local tx = type(payload.txId) == "string" and #payload.txId <= 80 and payload.txId or (kind .. ":" .. Http:GenerateGUID(false))
	local result = ctx.transaction(plr, tx, fn, function(committed)
		if committed.message and not committed.dup then ctx.toast(plr, committed.message, "good") end
		redraw(plr)
		ctx.invChanged(plr)
	end)
	if not result.ok then ctx.toast(plr, errors[result.reason] or "That action couldn't be completed. Try again.", "warn") end
	ctx.invChanged(plr)
	return result
end
function Home.buyDecoration(d,id)
 if id~="lamp" or d.home.decorations.lamp then return {ok=false,reason="invalid"} end
 if d.coins<H.lampCost then return {ok=false,reason="funds"} end
 d.coins-=H.lampCost;d.home.decorations.lamp=true;d.home.decorEquipped.lamp=true
 return {ok=true,message="Sunbeam lamp set installed. 1,500 Cairn Coins spent."}
end
function Home.refreshCommerce(plr)
 local room,s=rooms[plr],ctx.sessions[plr]
 if room and s and ctx.CommerceCosmetics then ctx.CommerceCosmetics.home(room,s.data) end
end
function Home.init(c)
	ctx = c
 ctx.handlers.homeDecorBuy=function(plr,p)
  return mutate(plr,p,"decor-buy",function(d)
   if not physicalOwner(plr) then return {ok=false,reason="unavailable"} end
   return Home.buyDecoration(d,p.id)
  end)
 end
 ctx.handlers.homeDecorEquip=function(plr,p)
  return mutate(plr,p,"decor-equip",function(d)
   if not physicalOwner(plr) or p.id~="lamp" or not d.home.decorations.lamp or type(p.enabled)~="boolean" then return {ok=false,reason="invalid"} end
   d.home.decorEquipped.lamp=p.enabled or nil;return {message=p.enabled and "Lamp set installed." or "Lamp set stored."}
  end)
 end
	folder = Instance.new("Folder"); folder.Name, folder.Parent = "CC_ActiveHomes", workspace
	ctx.handlers.homeEnter = function(plr) enter(plr, plr) end
	ctx.handlers.homeVisit = function(plr, p)
		if type(p.ownerId) == "number" then local owner = Players:GetPlayerByUserId(p.ownerId); if owner then enter(plr, owner) end end
	end
	ctx.handlers.homeReturn = function(plr) Home.returnHome(plr) end
	ctx.handlers.homeDirectoryClose = function(plr) directory[plr] = nil; ctx.push(plr) end
	ctx.handlers.homeClose = function(plr) opened[plr] = nil; ctx.push(plr) end
	ctx.handlers.nestPlace = function(plr, p)
		mutate(plr, p, "nest-place", function(d)
			if p.slot ~= 1 and p.slot ~= 2 then return { ok = false, reason = "invalid" } end
			if type(p.id) ~= "string" or not stoneItem(d, p.id) or table.find(d.home.nests, p.id) then return { ok = false, reason = "invalid" } end
			if d.home.nests[p.slot] ~= "" then return { ok = false, reason = "full" } end
			d.home.nests[p.slot] = p.id
			return { message = "Heartstone placed. New expedition finds advance both occupied nests." }
		end)
	end
	ctx.handlers.nestRemove = function(plr, p)
		mutate(plr, p, "nest-remove", function(d)
			if p.slot ~= 1 and p.slot ~= 2 then return { ok = false, reason = "invalid" } end
			d.home.nests[p.slot] = ""
			return { message = "Heartstone returned to safe storage. Its progress is preserved." }
		end)
	end
	ctx.handlers.nestHatch = function(plr, p)
		local s = physicalOwner(plr)
		if not s then return end
		local r = ctx.transaction(plr, type(p.txId) == "string" and p.txId or ("hatch:" .. Http:GenerateGUID(false)), function(d) return Bank.hatchData(d, p.slot) end, function(committed)
			redraw(plr)
			if not committed.dup then ctx.fx(plr, { kind = "ripened", hatched = { committed.hatched } }); ctx.toast(plr, "Your Heartstone hatched. Its creature is safe in your collection.", "good") end
		end)
		if not r.ok then ctx.toast(plr, errors[r.reason] or "Hatching is waiting for saving.", "warn") end
		ctx.push(plr)
	end
	ctx.handlers.homeAssign = function(plr, p)
		mutate(plr, p, "home-assign", function(d)
			if type(p.slot) ~= "number" or p.slot % 1 ~= 0 or p.slot < 1 or p.slot > H.baseSpaces + d.home.upgrade or type(p.creatureId) ~= "string" then return { ok = false, reason = "invalid" } end
			if p.creatureId ~= "" and not bankItem(d, p.creatureId) then return { ok = false, reason = "invalid" } end
			Home.settle(d, Clock.now())
			for i, id in ipairs(d.home.assigned) do if id == p.creatureId and id ~= "" then d.home.assigned[i] = "" end end
			for i = 1, H.baseSpaces + d.home.upgrade do d.home.assigned[i] = d.home.assigned[i] or "" end
			d.home.assigned[p.slot] = p.creatureId
			return { message = p.creatureId == "" and "Creature returned to your collection." or "Creature settled into its suitable habitat." }
		end)
	end
	ctx.handlers.homeEquipBest = function(plr, p)
		mutate(plr, p, "home-best", function(d) Home.settle(d, Clock.now()); d.home.assigned = Home.best(d); return { message = "Best earning creatures assigned. Your choices stay until you change them." } end)
	end
	ctx.handlers.homeCollect = function(plr, p)
		mutate(plr, p, "home-collect", function(d)
			Home.settle(d, Clock.now())
			local amount = math.floor(d.home.uncollected)
			d.coins += amount; d.home.uncollected -= amount
			return { amount = amount, message = amount > 0 and ("Collected " .. amount .. " Cairn Coins.") or "Income is growing. Come back when a whole coin is ready." }
		end)
	end
	ctx.handlers.homeUpgrade = function(plr, p)
		mutate(plr, p, "home-upgrade", function(d)
			local cost = H.upgradeCosts[d.home.upgrade + 1]
			if not cost then return { ok = false, reason = "invalid" } end
			if d.coins < cost then return { ok = false, reason = "funds" } end
			Home.settle(d, Clock.now())
			d.coins -= cost; d.home.upgrade += 1
			return { message = "Home upgraded: one more earning space and more efficient adventure progress." }
		end)
	end
	ctx.handlers.homeFavorite = function(plr, p)
		mutate(plr, p, "home-favorite", function(d)
			if not bankItem(d, p.creatureId) then return { ok = false, reason = "invalid" } end
			d.home.favorites[p.creatureId] = not d.home.favorites[p.creatureId] or nil
			return {}
		end, true)
	end
	ctx.handlers.homeCompanion = function(plr, p)
		mutate(plr, p, "home-companion", function(d)
			if type(p.creatureId) ~= "string" or (p.creatureId ~= "" and not bankItem(d, p.creatureId)) then return { ok = false, reason = "invalid" } end
			d.home.companion = d.home.companion == p.creatureId and "" or p.creatureId
			if d.home.companion ~= "" then d.home.favorites[d.home.companion] = true end
			return { message = d.home.companion == "" and "Companion tucked away." or "Your favorite will follow on safe ground." }
		end, true)
	end
	ctx.handlers.homePet = function(plr, p)
		local s = physicalOwner(plr)
		if not s or not table.find(s.data.home.assigned, p.creatureId) or os.clock() - (petAt[plr] or 0) < H.petCooldown then return end
		petAt[plr] = os.clock()
		local b = bankItem(s.data, p.creatureId)
		if b then local e = ctx.Species.get(b.species); ctx.toast(plr, (e and e.name or "Your creature") .. " enjoys a gentle pat.", "good"); ctx.fx(plr, { kind = "pet", creatureId = p.creatureId }) end
	end
	task.spawn(function()
		local world = workspace:WaitForChild("World")
		local fairground=world:FindFirstChild("Fairground")
		if fairground then
			local door=require(script.Parent.LobbyAnchors).resolve(world).HomeDoor
			portals[#portals+1]=door
			prompt(door,"HomePortalPrompt","Enter home / visit","Your personal home",function(plr)
				if ctx.sessions[plr] and not visits[plr] then directory[plr]=door;ctx.fx(plr,{kind="homeDirectory",open=true});ctx.push(plr) end
			end)
			return
		end
		local cabins = world:FindFirstChild("Cabins", true)
		for _, cabin in ipairs(cabins and cabins:GetChildren() or {}) do
			local anchor = cabin:FindFirstChild("Terrace") or cabin:FindFirstChildWhichIsA("BasePart", true)
			if anchor then
				local door = part(cabin, "HomePortalStation", Vector3.new(2.5, 3, 1), anchor.Position + anchor.CFrame.LookVector * 11 + Vector3.new(0, anchor.Size.Y / 2 + 1.5, 0), Enum.Material.Wood, Color3.fromRGB(182, 143, 89))
				door.CanCollide = false
				portals[#portals + 1] = door
				label(door, "Your home · visits")
				prompt(door, "HomePortalPrompt", "Enter home / visit", "Cabin doorway", function(plr)
					if ctx.sessions[plr] and not visits[plr] then directory[plr] = door; ctx.fx(plr, { kind = "homeDirectory", open = true }); ctx.push(plr) end
				end)
			end
		end
	end)
	task.spawn(function()
		local nextRefresh = 0
		while true do
			task.wait(0.25)
			local refresh = os.clock() >= nextRefresh
			if refresh then nextRefresh = os.clock() + 5 end
			for plr, s in pairs(ctx.sessions) do
				local ch = plr.Character
				local root, hum = ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
				local state = ch and (ch:GetAttribute("CC_TraversalState") or ch:GetAttribute("CC_ClimbState"))
				local safe = root and hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air and (state == nil or state == "Grounded" or state == "ground" or state == "idle" or state == "Ground")
				local b = safe and bankItem(s.data, s.data.home.companion)
				local model = companions[plr]
				if model and (not b or model:GetAttribute("CreatureId") ~= b.creatureId) then model:Destroy(); companions[plr], model = nil, nil end
				if b and not model and ctx.Visuals then
					model = ctx.Visuals.creature(b.species, root.Position)
					model.Name = "FavoriteCompanion_" .. plr.UserId
					model:SetAttribute("CreatureId", b.creatureId)
					for _, d in ipairs(model:GetDescendants()) do
						if d:IsA("BasePart") then d.CanCollide, d.CanTouch, d.CanQuery = false, false, false end
						if d:IsA("ParticleEmitter") or d:IsA("Beam") then d.Enabled = false end
					end
					model.Parent, companions[plr] = folder, model
				end
				if model then model:PivotTo(root.CFrame * CFrame.new(3, -1.8, 2.5)) end
				if opened[plr] then
					local v = visits[plr]; local r = v and rooms[v.owner]
					if not r or not atHomeStation(plr, r) then opened[plr] = nil; ctx.push(plr) end
				end
				if refresh and (opened[plr] or directory[plr]) then ctx.push(plr) end
			end
		end
	end)
end
function Home.onLoaded(plr, s)
	Home.settle(s.data, Clock.now())
	s.dirty = true
	-- A crash in a temporary home always resumes from the saved cabin doorway, never from a vanished court.
	local ret = s.data.expedition.homeReturn
	if type(ret) == "table" and type(ret.x) == "number" and type(ret.y) == "number" and type(ret.z) == "number" then
		task.delay(1, function()
			if ctx.sessions[plr] == s and travel(plr, Vector3.new(ret.x, ret.y, ret.z), "homeReturn") then Profile.clearHomeReturn(s); ctx.saveSoon(s) end
		end)
	end
end
function Home.onCharacter(plr)
	if visits[plr] then
		task.delay(1, function() if plr.Parent then Home.returnHome(plr, true) end end)
	end
end
function Home.onLeave(plr)
	local visit = visits[plr]
	if visit and rooms[visit.owner] then rooms[visit.owner].occupants[plr] = nil; cleanRoom(visit.owner) end
	visits[plr], directory[plr], opened[plr], petAt[plr] = nil, nil, nil, nil
	if companions[plr] then companions[plr]:Destroy(); companions[plr] = nil end
	local room = rooms[plr]
	if room then
		local guests = {}
		for guest in pairs(room.occupants) do guests[#guests + 1] = guest end
		for _, guest in ipairs(guests) do Home.returnHome(guest, true) end
		cleanRoom(plr)
	end
end
function Home.state(plr, st)
	local s = ctx.sessions[plr]
	if not s then return end
	st.collection, st.memories, st.journal, st.settings = {}, s.data.memories, s.data.journal, s.data.settings
	for _, b in ipairs(s.data.bank) do
		local row = Profile.deepCopy(b)
		row.favorite, row.companion = s.data.home.favorites[b.creatureId] == true, s.data.home.companion == b.creatureId
		st.collection[#st.collection + 1] = row
	end
	st.inHome = visits[plr] ~= nil
	if directory[plr] then
		st.homeDirectory = { title = "Cabin visits", owners = {} }
		for owner in pairs(ctx.sessions) do st.homeDirectory.owners[#st.homeDirectory.owners + 1] = { ownerId = owner.UserId, name = owner.DisplayName } end
	end
	local visit = visits[plr]
	local owner = opened[plr] and visit and visit.owner
	local os = owner and ctx.sessions[owner]
	if not os then return end
	local d = os.data
	local preview = Profile.deepCopy(d)
	Home.settle(preview, Clock.now())
	local stones = {}
	for _, stone in ipairs(d.heartstones) do stones[#stones + 1] = ctx.Cargo.clientItem(stone, true) end
	st.home = { decorations = d.home.decorations, decorEquipped = d.home.decorEquipped, lampCost = H.lampCost, ownerId = owner.UserId, ownerName = owner.DisplayName, readOnly = owner ~= plr, station = "Home station", nests = {}, stones = stones, spaces = H.baseSpaces + d.home.upgrade, assigned = table.clone(d.home.assigned), income = preview.home.uncollected, rate = Home.rate(d), upgrades = { level = d.home.upgrade, max = H.maxUpgrade, cost = H.upgradeCosts[d.home.upgrade + 1] }, favorites = d.home.favorites, companion = d.home.companion, collection = Profile.deepCopy(d.bank), efficiency = H.progressEfficiency[d.home.upgrade + 1], offlineHours = H.offlineCap / 3600 }
	for i = 1, H.nestCount do
		local h = stoneItem(d, d.home.nests[i])
		st.home.nests[i] = { slot = i, id = h and h.id, progress = h and h.progress or 0, required = h and h.required or 0, ready = h and h.ready or false, tier = h and h.tier }
	end
end
return Home
