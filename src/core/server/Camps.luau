-- Camps (ServerScriptService.CC_CoreServer): the Foothold bank point, guardian-free safe zones (Foothold + tents),
-- Camp Lockers, highest reached camp and resume (LOCKED: sessions start at the highest reached camp).
-- * Bank: a hold prompt on the existing plaza campfire (no new geometry; the Foothold layout stays frozen).
-- * Safe zones: the Foothold pad and a small radius around each camp (tent tier 1 = 46 studs, PROPOSED);
--   guardians never enter them (Nests asks Camps.isSafe).
-- * Locker: 1 slot at tent tier 1 (LOCKED 1 -> 3 by tier). Locker items are safe from falls and hits, persist in
--   the profile (lockers[camp]), are not banked (no codex/XP/yield) and are moved only by server-validated
--   requests from a player standing at that locker.
-- * Resume: a returning player (highestCamp >= 1) starts at that camp; for the first 60 s, with an empty
--   backpack, "Start at the Foothold" is offered instead (PROPOSED; no cargo can skip the risky return).
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")

local Anchors = require(script.Parent.LobbyAnchors)
local Camps = {}
local ctx, C, Inv, Clock, Prompts
local api
local campPads = {} -- [name] = { name, order, center, label }
local lockerParts = {} -- [name] = BasePart
local resumeWindow = {} -- [plr] = os.clock() deadline
local openLocker = {} -- [plr] = camp name

local function campOfPos(pos)
	for name, cp in pairs(campPads) do
		if (pos - cp.center).Magnitude < 70 then
			return name
		end
	end
	return nil
end

function Camps.safeRadius(name, userIdOrSession)
	local tier = 1
	if type(userIdOrSession) == "table" and userIdOrSession.data then
		tier = userIdOrSession.data.tents[name] or 1
	end
	return C.CAMP_SAFE_RADIUS[tier] or C.CAMP_SAFE_RADIUS[1]
end

-- isSafe(pos) -> true inside the Foothold or any camp's tent radius (guardian-free, LOCKED)
function Camps.isSafe(pos)
	if workspace.World:FindFirstChild("Fairground") then
		if Anchors.contains(pos) then return true end
	else
	local f = C.FOOTHOLD_SAFE
	if ((pos - f.center) * Vector3.new(1, 0, 1)).Magnitude < f.radius and pos.Y < f.center.Y + 60 then
		return true
	end
	end
	for name, cp in pairs(campPads) do
		if ((pos - cp.center) * Vector3.new(1, 0, 1)).Magnitude < Camps.safeRadius(name) and math.abs(pos.Y - cp.center.Y) < 40 then
			return true
		end
	end
	return false
end

local function lockerSlots(s, camp)
	local tier = s.data.tents[camp] or 1
	return C.LOCKER_SLOTS[tier] or 1
end
local function lockerUsed(s, camp)
	local n = 0
	for _, it in ipairs(s.data.lockers[camp] or {}) do
		n += it.slots or 1
	end
	return n
end

local function nearLocker(plr, camp)
	local part = lockerParts[camp]
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	return part and hrp and (hrp.Position - part.Position).Magnitude < 16
end

local function lockerView(s, camp)
	local items = {}
	for _, it in ipairs(s.data.lockers[camp] or {}) do
		items[#items + 1] = ctx.Cargo.clientItem({ uid = it.uid, kind = it.kind, species = it.species, rarity = it.rarity, tier = it.tier, slots = it.slots })
	end
	return { camp = camp, label = campPads[camp] and campPads[camp].label or camp, slots = lockerSlots(s, camp), used = lockerUsed(s, camp), items = items }
end

function Camps.state(plr, st)
	local camp = openLocker[plr]
	local s = ctx.sessions[plr]
	if camp and s then
		st.locker = lockerView(s, camp)
	end
 local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
 local nearby=root and campOfPos(root.Position)
 if nearby then st.travelOffer={camp=nearby,label=campPads[nearby].label,available=true} end
 st.lockers={}
 if s then for name,items in pairs(s.data.lockers) do table.insert(st.lockers,{camp=name,label=campPads[name] and campPads[name].label or name,count=#items}) end end
 st.resumeOffer = resumeWindow[plr] and (os.clock() < resumeWindow[plr]) or false
end

local function teleport(plr, pos)
	if ctx.Traversal then ctx.Traversal.travel(plr,pos+Vector3.new(0,4,0),"resume") return end
	local ch = plr.Character
	if ch and ch:FindFirstChild("HumanoidRootPart") then
		ch.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
		ch:PivotTo(CFrame.new(pos + Vector3.new(0, 4, 0)))
	end
end

function Camps.init(c)
	ctx = c
	C, Inv, Clock = c.C, c.Inv, c.Clock
	Prompts = require(script.Parent.Prompts)
	ctx.Camps = Camps
	local world = workspace:WaitForChild("World")
	api = SS:WaitForChild("CC_CheckpointAPI", 10)

	-- camp pads from the checkpoint triggers (Camp1..Camp4); lockers from the built camp props
	local cps = world:WaitForChild("Checkpoints")
	for _, t in ipairs(cps:GetChildren()) do
		local name = t:GetAttribute("Checkpoint")
		if name and table.find(C.RESUME_CAMPS, name) then
			campPads[name] = { name = name, order = t:GetAttribute("Order"), center = t.Position - Vector3.new(0, t.Size.Y / 2, 0), label = t:GetAttribute("Label") or name }
		end
	end
	local campsF = world:FindFirstChild("Camps")
	for name in pairs(campPads) do
		local f = campsF and campsF:FindFirstChild(name)
		local lk = f and f:FindFirstChild("CampLocker")
		local box = lk and lk:FindFirstChild("Box")
		if box then
			lockerParts[name] = box
			local p = Prompts.make(box, { Name = "LockerPrompt", ActionText = "Open locker", ObjectText = campPads[name].label .. " Camp Locker", HoldDuration = 0, MaxActivationDistance = 10 })
			p.Triggered:Connect(function(plr)
				if not Prompts.validate(p,plr) or not ctx.sessions[plr] then
					ctx.toast(plr, "Lockers open once your profile has loaded.", "warn")
					return
				end
				openLocker[plr] = name
				ctx.fx(plr, { kind = "locker", open = true })
				ctx.push(plr)
			end)
		end
	end

	-- the bank: hold on the plaza campfire
	local corePart = Anchors.resolve(world).Bank
	if corePart then
		local p = Prompts.make(corePart, { Name = "BankPrompt", ActionText = "Bank finds", ObjectText = "Expedition bank", HoldDuration = 0.5, MaxActivationDistance = 14 })
		Camps.bankPart = corePart
		local last = setmetatable({}, { __mode = "k" })
		p.Triggered:Connect(function(plr)
			if not Prompts.validate(p, plr) then
				return
			end
			if last[plr] and os.clock() - last[plr] < 0.8 then
				return -- double tap: the second trigger would find an empty pack anyway
			end
			last[plr] = os.clock()
			ctx.deposit(plr)
		end)
	else
		warn("[CC] Camps: plaza campfire not found; no bank point")
	end

	-- highest camp (only Camp1..Camp4 count; checkpoint service reports every camp touch)
	if api then
		api:WaitForChild("CampReached").Event:Connect(function(plr, name, order)
			local s = ctx.sessions[plr]
			local cp = campPads[name]
			if s and cp then
				local idx = table.find(C.RESUME_CAMPS, name)
				if idx and idx > s.data.highestCamp then
					s.data.highestCamp = idx
					-- Camp progression is monotonic. A pending candidate must not overwrite a camp reached
					-- while its DataStore request is yielding; Profile merges the live maximum on recovery.
					if s.pending then s.pending.candidate.highestCamp = math.max(s.pending.candidate.highestCamp or 0, idx) end
					s.dirty = true
					if not s.pending then ctx.saveSoon(s) else s.saveAgain = true end
					ctx.toast(plr, "New highest camp: " .. cp.label .. ". Next session starts here.", "good")
					ctx.push(plr)
				end
			end
		end)
	end

 -- Locker transfers commit both locations atomically, preserving item records.
 local function transfer(plr,p,take)
  local session=ctx.sessions[plr]
  local camp=openLocker[plr]
  local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
  if not session or not camp or not hum or hum.Health<=0 or not nearLocker(plr,camp) or type(p.uid)~="string" or #p.uid>128 then return end
  local tx="locker:"..game:GetService("HttpService"):GenerateGUID(false)
  local r=ctx.transaction(plr,tx,function(d)
   d.lockers[camp]=d.lockers[camp] or {}
   local from=take and d.lockers[camp] or d.cargo
   local to=take and d.cargo or d.lockers[camp]
   local i,it=ctx.Cargo.locate(from,p.uid)
   if not it then return {ok=false,reason="missing"} end
   local cap=take and d.slots or (C.LOCKER_SLOTS[d.tents[camp] or 1] or 1)
   if ctx.Cargo.used(to)+(it.slots or 1)>cap then return {ok=false,reason="full"} end
   table.remove(from,i) table.insert(to,it)
   return {ok=true}
  end,function() ctx.invChanged(plr) ctx.toast(plr,take and "Retrieved. Carry it to the Foothold bank." or "Stored safely at this camp. Return here to retrieve it.","good") end)
  if not r.ok then ctx.toast(plr,r.reason=="full" and "Not enough room." or "Waiting for saving; the transfer is not confirmed.","warn") end
 end
 ctx.handlers.lockerStore=function(plr,p) transfer(plr,p,false) end
 ctx.handlers.lockerTake=function(plr,p) transfer(plr,p,true) end
 ctx.handlers.shuttle=function(plr)
  local session=ctx.sessions[plr]
  local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
  local camp=root and campOfPos(root.Position)
  if not session or not camp or not hum or hum.Health<=0 or hum.FloorMaterial==Enum.Material.Air then return end
  local state=plr.Character:GetAttribute("CC_TraversalState")
  if state and state~="ground" then return end
  local sp=workspace:FindFirstChildOfClass("SpawnLocation")
  if not sp or not ctx.Traversal then return end
  -- Arrival is the entrance/spawn terrace. Cargo stays carried; no automatic banking.
  ctx.transaction(plr,"shuttle:"..game:GetService("HttpService"):GenerateGUID(false),function(d)
   d.expedition.returnedAt=Clock.now() d.expedition.returnFrom=camp
   return {ok=true}
  end,function()
   local current=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
   local currentHum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
   local currentState=plr.Character and plr.Character:GetAttribute("CC_TraversalState")
   if ctx.sessions[plr]~=session or not current or not currentHum or currentHum.Health<=0 or currentHum.FloorMaterial==Enum.Material.Air or (currentState and currentState~="ground") or campOfPos(current.Position)~=camp then
    ctx.toast(plr,"Shuttle ready. Return to that camp to board.","info")
    return
   end
   if api then api.SetCheckpoint:Invoke(plr,nil) end
   ctx.Traversal.travel(plr,sp.Position+Vector3.new(0,4,0),"shuttle")
   ctx.toast(plr,"Foothold entrance. Your cargo is with you; walk to the campfire bank.","good")
   ctx.push(plr)
  end)
 end
	ctx.handlers.lockerClose = function(plr)
		openLocker[plr] = nil
		ctx.push(plr)
	end
	ctx.handlers.resumeFoothold = function(plr)
		if resumeWindow[plr] and os.clock() < resumeWindow[plr] and Inv.used(plr.UserId) == 0 then
			resumeWindow[plr] = nil
			-- clear the checkpoint first: the move down to the Foothold must not read as a fall
			if api then
				api.SetCheckpoint:Invoke(plr, nil)
			end
			local sp = workspace:FindFirstChildOfClass("SpawnLocation")
			if sp then
				teleport(plr, sp.Position)
			end
			ctx.push(plr)
		end
	end

	-- close the locker panel when walking away; camp attribute for the HUD zone name
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, plr in ipairs(Players:GetPlayers()) do
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local camp = campOfPos(hrp.Position)
					local label = camp and ((hrp.Position - campPads[camp].center) * Vector3.new(1, 0, 1)).Magnitude < Camps.safeRadius(camp) and campPads[camp].label or ""
					if plr:GetAttribute("CC_Camp") ~= label then
						plr:SetAttribute("CC_Camp", label)
					end
					if openLocker[plr] and not nearLocker(plr, openLocker[plr]) then
						openLocker[plr] = nil
						ctx.push(plr)
					end
				end
			end
		end
	end)
end

function Camps.onLoaded(plr, s)
	local idx = s.data.highestCamp
	local name = C.RESUME_CAMPS[idx]
	if not name or not campPads[name] or not api then
		return
	end
	local pos = api.SetCheckpoint:Invoke(plr, name)
	-- Cargo reconnect and home return own their location. Do not first move them to the highest camp.
	if s.data.expedition.homeReturn or (#s.data.cargo > 0 and s.data.expedition.returnPos) then return end
	if pos then
		resumeWindow[plr] = os.clock() + 60
		local ch = plr.Character or plr.CharacterAdded:Wait()
		ch:WaitForChild("HumanoidRootPart", 10)
		teleport(plr, pos)
		ctx.fx(plr, { kind = "resume", camp = campPads[name].label })
		ctx.toast(plr, "Resuming at " .. campPads[name].label .. " (your highest camp).", "info")
		ctx.push(plr)
	end
end

function Camps.onLeave(plr)
	openLocker[plr] = nil
	resumeWindow[plr] = nil
end

Camps._pads = campPads
return Camps
