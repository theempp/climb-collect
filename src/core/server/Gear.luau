-- Earned cosmetic equipment and automatic surface-aware climbing kit. No commerce or consumables.
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")

local Gear = {}
local ctx, C
local shopById = {}
local sites = {} -- { part, kind = "Market" | "Forge" }
local openSite = {} -- [plr] = "Market" | "Forge"
local trip = {} -- [plr] = { camps = { [name] = true }, refills = { [name] = true } }

for _, it in ipairs(require(game:GetService("ReplicatedStorage"):WaitForChild("CC_Core"):WaitForChild("CoreConfig")).SHOP) do
	shopById[it.id] = it
end

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function g(s)
	return s.data.gear
end

-- kit owned: level unlock or a Forge purchase
function Gear.hasKit(_,id)
 return id=="headlamp" or id=="axe" or id=="crampons"
end

local function atSite(plr, kind)
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	for _, st in ipairs(sites) do
		if (not kind or st.kind == kind) and st.part.Parent and (hrp.Position - st.part.Position).Magnitude < 22 then
			return true
		end
	end
	return false
end

---------------------------------------------------------------- avatar (cosmetics + visible kit)
local watched = {}
local function weld(part, to, cf)
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, false, true
	part.CFrame = to.CFrame * cf
	local w = Instance.new("Weld")
	w.Name = "KitWeld"
	w.Part0, w.Part1 = to, part
	w.C0 = cf
	w.Parent = part
	part.Parent = to.Parent:FindFirstChild("CC_Gear") or to.Parent
end

function Gear.refreshKit(plr)
 local ch=plr.Character local f=ch and ch:FindFirstChild("CC_Gear")
 local torso=ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
 if not f or not torso then return end
 local hand=ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
 local active=ch:GetAttribute("CC_AxeActive")==true and hand~=nil
 for _,p in ipairs(f:GetChildren()) do
  if p.Name=="AxeShaft" or p.Name=="AxeHead" then
   local w=p:FindFirstChild("KitWeld")
   if w then
    w.Part0=active and hand or torso
    if active then
     w.C0=CFrame.new(0,p.Name=="AxeHead" and 1.25 or 0.1,-0.35)*CFrame.Angles(0,0,math.rad(-12))
    else
     w.C0=CFrame.new(torso.Size.X*0.25+(p.Name=="AxeHead" and 0.55 or 0),p.Name=="AxeHead" and 1.15 or 0,torso.Size.Z*0.62)*CFrame.Angles(0,0,math.rad(25))
    end
   end
  elseif p.Name=="Crampon" then p.Transparency=ch:GetAttribute("CC_CramponsActive")==true and 0 or 1 end
 end
end

local function piece(name, size, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.CastShadow = false
	return p
end

function Gear.dress(plr)
	local s = ctx.sessions[plr]
	local ch = plr.Character
	if not (s and ch) then
		return
	end
	local old = ch:FindFirstChild("CC_Gear")
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "CC_Gear"
	f.Parent = ch
	local head = ch:FindFirstChild("Head")
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	local eq = g(s).equipped
	if head then
		local it = shopById[eq.head]
		if it then
			local hs = head.Size
			if it.id == "cap_trail" then
				weld(piece("Cap", Vector3.new(hs.X * 1.05, hs.Y * 0.3, hs.Z * 1.05), rgb(it.color), Enum.Material.Fabric), head, CFrame.new(0, hs.Y * 0.42, 0))
				weld(piece("Brim", Vector3.new(hs.X * 0.9, 0.08, hs.Z * 0.45), rgb(it.color2), Enum.Material.Fabric), head, CFrame.new(0, hs.Y * 0.3, -hs.Z * 0.6))
			else
				weld(piece("Helmet", Vector3.new(hs.X * 1.18, hs.Y * 0.6, hs.Z * 1.18), rgb(it.color), Enum.Material.SmoothPlastic, Enum.PartType.Ball), head, CFrame.new(0, hs.Y * 0.3, 0))
				weld(piece("Stripe", Vector3.new(hs.X * 0.2, 0.1, hs.Z * 1.1), rgb(it.color2), Enum.Material.Neon), head, CFrame.new(0, hs.Y * 0.6, 0))
			end
		end
		local gg = shopById[eq.eyes]
		if gg then
			local hs = head.Size
			weld(piece("GoggleBand", Vector3.new(hs.X * 1.08, hs.Y * 0.16, hs.Z * 1.08), rgb(gg.color2), Enum.Material.Fabric), head, CFrame.new(0, hs.Y * 0.12, 0))
			for _, sx in ipairs({ -1, 1 }) do
				weld(piece("Lens", Vector3.new(hs.X * 0.3, hs.Y * 0.22, 0.12), rgb(gg.color), Enum.Material.Glass), head, CFrame.new(sx * hs.X * 0.2, hs.Y * 0.12, -hs.Z * 0.55))
			end
		end
		if Gear.hasKit(s, "headlamp") then
			local hs = head.Size
			local lamp = piece("Headlamp", Vector3.new(0.3, 0.25, 0.2), rgb({ 255, 214, 150 }), Enum.Material.Neon) -- goldenDaylight
			weld(lamp, head, CFrame.new(0, hs.Y * 0.32, -hs.Z * 0.55))
			local light = Instance.new("SpotLight")
			light.Name = "HeadlampLight"
			light.Face = Enum.NormalId.Front
			light.Angle = 70
			light.Range = 34
			light.Brightness = 2.2
			light.Color = rgb({ 255, 214, 150 })
			light.Shadows = false
			light.Enabled = false -- traversal client uses actual darkness + player preference
			light.Parent = lamp
		end
	end
	if torso then
		local it = shopById[eq.body]
		local ts = torso.Size
		if it then
			weld(piece("Jacket", Vector3.new(ts.X * 1.1, ts.Y * 0.95, ts.Z * 1.25), rgb(it.color), Enum.Material.Fabric), torso, CFrame.new(0, -ts.Y * 0.02, 0))
			weld(piece("Collar", Vector3.new(ts.X * 0.7, ts.Y * 0.18, ts.Z * 1.3), rgb(it.color2), Enum.Material.Fabric), torso, CFrame.new(0, ts.Y * 0.45, 0))
		end
		if Gear.hasKit(s, "axe") then
			weld(piece("AxeShaft", Vector3.new(0.18, 2.6, 0.18), rgb({ 62, 66, 76 }), Enum.Material.Metal), torso, CFrame.new(ts.X * 0.25, 0, ts.Z * 0.62) * CFrame.Angles(0, 0, math.rad(25)))
			weld(piece("AxeHead", Vector3.new(1.1, 0.2, 0.2), rgb({ 196, 232, 255 }), Enum.Material.Metal), torso, CFrame.new(ts.X * 0.25 + 0.55, 1.15, ts.Z * 0.62) * CFrame.Angles(0, 0, math.rad(25)))
		end
	end
	if Gear.hasKit(s, "crampons") then
		for _, foot in ipairs({ {"LeftFoot","Left Leg"}, {"RightFoot","Right Leg"} }) do
			local fp = ch:FindFirstChild(foot[1]) or ch:FindFirstChild(foot[2])
			if fp then
				weld(piece("Crampon", Vector3.new(fp.Size.X * 1.05, 0.12, fp.Size.Z * 1.05), rgb({ 62, 66, 76 }), Enum.Material.Metal), fp, CFrame.new(0, -fp.Size.Y / 2, 0))
			end
		end
	end
	for id in pairs(C.KIT) do
		ch:SetAttribute("CC_Kit_" .. id, Gear.hasKit(s, id))
	end
	plr:SetAttribute("CC_StaminaMax", Gear.staminaMax(s))
 if not watched[plr] or watched[plr].character~=ch then
  if watched[plr] then for _,c in ipairs(watched[plr].connections) do c:Disconnect() end end
  watched[plr]={character=ch,connections={
   ch:GetAttributeChangedSignal("CC_AxeActive"):Connect(function() Gear.refreshKit(plr) end),
   ch:GetAttributeChangedSignal("CC_CramponsActive"):Connect(function() Gear.refreshKit(plr) end)
  }}
 end
 Gear.refreshKit(plr)
end

function Gear.trainingBonus(s)
 local tr=g(s).training
 local legacy=0 for i=1,tr.level or 0 do legacy+=C.TRAINING.gains[i] or 0 end
 local practiced=0 for i,gain in ipairs(C.PRACTICE.gains) do if tr.completed and tr.completed[tostring(i)] then practiced+=gain end end
 return math.max(legacy,practiced)
end
function Gear.staminaMax(s)
 return math.min(C.PRACTICE.staminaCap,C.CLIMB.stamina+math.max(0,s.data.level-1)*3+Gear.trainingBonus(s))
end
function Gear.state(plr,st)
 local s=ctx.sessions[plr] if not s then return end
 local gs=g(s)
 st.gear={points=gs.points,owned=gs.owned,equipped=gs.equipped,summits=gs.summits,kit={headlamp={owned=true},axe={owned=true},crampons={owned=true}},training={level=gs.training.level,max=3,bonus=Gear.trainingBonus(s)},staminaMax=Gear.staminaMax(s)}
end
function Gear.init(c)
 ctx=c C=c.C ctx.Gear=Gear
 -- Currency and owned cosmetics are retained. No shop/refill/purchase handlers or prompts are registered.
 ctx.on("bank",function(plr) Gear.dress(plr) end)
 if ctx.devHandlers then ctx.devHandlers.gearGrant=function(plr,p)
  local s=ctx.sessions[plr] if s then s.data.coins+=math.floor(tonumber(p.coins) or 0) g(s).points+=math.floor(tonumber(p.points) or 0) s.dirty=true ctx.push(plr) end
 end end
end
function Gear.onLoaded(plr) Gear.dress(plr) end
function Gear.onCharacter(plr) task.wait(0.5) Gear.dress(plr) end
function Gear.onLeave(plr)
 if watched[plr] then for _,c in ipairs(watched[plr].connections) do c:Disconnect() end watched[plr]=nil end
end
return Gear

