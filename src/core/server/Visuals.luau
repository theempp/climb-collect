-- Visuals (ServerScriptService.CC_CoreServer): runtime models for creatures, guardians, Heartstones, drop packs and
-- the carried-Heartstone glow. Creature/guardian looks are Codex's track (Phase C): if ServerStorage.CC_Creatures
-- holds a Model named after the species id it is cloned read-only; otherwise a neutral STUB stands in (a plain ball
-- + rarity pips), deliberately not species art. Rarity reads by pips first, tint second (LOCKED); particle
-- richness rises per tier and only Legendary gets a world beam (LOCKED). Colors are existing world tokens.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local C = require(RS:WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local Species = require(RS.CC_Core:WaitForChild("Species"))

local V = {}
local TOK = {
	slate = Color3.fromRGB(62, 66, 76),
	golden = Color3.fromRGB(255, 214, 150),
	moon = Color3.fromRGB(220, 230, 255),
	lantern = Color3.fromRGB(255, 178, 72),
	timber = Color3.fromRGB(140, 96, 60),
	timberDark = Color3.fromRGB(98, 66, 42),
	aurora = Color3.fromRGB(156, 92, 246),
	ice = Color3.fromRGB(196, 232, 255),
}
V.TOK = TOK
local SIZE = { Common = 2.2, Uncommon = 2.6, Rare = 3.0, Epic = 3.0, Legendary = 4.0 }

local function part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function pips(rarity)
	return string.rep("◆", C.RANK[rarity] or 1) .. string.rep("◇", 5 - (C.RANK[rarity] or 1))
end
V.pips = pips

local function tag(parent, adornee, top, bottom, color, maxDist)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"
	bb.Adornee = adornee
	bb.Size = UDim2.fromOffset(170, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + 1.6, 0)
	bb.MaxDistance = maxDist or 70
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Top"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.5, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.4
	t.Text = top
	t.Parent = bb
	local b = t:Clone()
	b.Name = "Bottom"
	b.Position = UDim2.fromScale(0, 0.5)
	b.TextColor3 = TOK.moon
	b.Text = bottom
	b.Parent = bb
	bb.Parent = parent
	return bb
end

local function codexModel(speciesId)
	local lib = SS:FindFirstChild("CC_Creatures") -- Codex's library: read-only, never modified here
	local m = lib and lib:FindFirstChild(speciesId)
	if m and m:IsA("Model") then
		local c = m:Clone()
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		return c
	end
	return nil
end

-- creature at pos; returns model with PrimaryPart "Body" (prompt attaches there)
function V.creature(speciesId, pos)
	local e = Species.get(speciesId)
	local rarity = e and e.rarity or "Common"
	local m = codexModel(speciesId)
	if m then
		m:PivotTo(CFrame.new(pos))
		if not m.PrimaryPart then
			m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart", true)
		end
	else
		m = Instance.new("Model")
		m.Name = speciesId
		local s = SIZE[rarity] or 2.4
		local body = part(m, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.one * s, CFrame = CFrame.new(pos), Material = Enum.Material.SmoothPlastic, Color = C.RARITY_TINT[rarity], CanQuery = true })
		m.PrimaryPart = body
		m:SetAttribute("Stub", true)
	end
	local body = m.PrimaryPart
	tag(m, body, pips(rarity), (e and e.name or speciesId), C.RARITY_TINT[rarity], 60)
	if (C.RANK[rarity] or 1) >= 3 then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "RarityGlint"
		pe.Color = ColorSequence.new(C.RARITY_TINT[rarity])
		pe.LightEmission = 0.6
		pe.Rate = 2 + (C.RANK[rarity] - 3) * 4
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Speed = NumberRange.new(0.5, 1.2)
		pe.Size = NumberSequence.new(0.35, 0)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = body
	end
	if rarity == "Legendary" then
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = body, body
		a1.Position = Vector3.new(0, 120, 0)
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Color = ColorSequence.new(C.RARITY_TINT.Legendary)
		beam.Width0, beam.Width1 = 1.6, 0.4
		beam.LightEmission = 1
		beam.FaceCamera = true
		beam.Parent = body
	end
	m:SetAttribute("Species", speciesId)
	m:SetAttribute("Rarity", rarity)
	return m
end

-- guardian (nest NPC). Stub: a dark ball sized by its traits; Codex model by id when it exists.
function V.guardian(speciesId, pos, scale)
	local e = Species.get(speciesId)
	local m = codexModel(speciesId)
	if m then
		m:ScaleTo(scale)
		m:PivotTo(CFrame.new(pos))
	else
		m = Instance.new("Model")
		m.Name = speciesId
		local s = 6 * scale
		local body = part(m, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.one * s, CFrame = CFrame.new(pos), Material = Enum.Material.SmoothPlastic, Color = TOK.slate, CanQuery = false })
		m.PrimaryPart = body
		-- facing marker so players can read where a stub is looking (gameplay readability, not species art)
		local nose = part(m, { Name = "Facing", Size = Vector3.new(s * 0.3, s * 0.3, s * 0.35), CFrame = CFrame.new(pos) * CFrame.new(0, s * 0.08, -s * 0.5), Material = Enum.Material.SmoothPlastic, Color = TOK.lantern, CanQuery = false })
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = body, nose
		w.Parent = nose
		m:SetAttribute("Stub", true)
	end
	local body = m.PrimaryPart
	tag(m, body, "Guardian", (e and e.name or speciesId), TOK.lantern, 90)
	-- the tell: a "!" shown by every client while State == "Alert" (brief §3.3: visible tell >= 1.5 s)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Tell"
	bb.Adornee = body
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(60, 60)
	bb.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y / 2 + 4, 0)
	bb.Enabled = false
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = TOK.lantern
	t.TextStrokeTransparency = 0
	t.Text = "!"
	t.Parent = bb
	bb.Parent = m
	-- "checking its nest" cue (Patrol pause): the moment it can see the nest centre
	local wb = bb:Clone()
	wb.Name = "Watch"
	wb.Size = UDim2.fromOffset(44, 44)
	wb.TextLabel.Text = "◉"
	wb.TextLabel.TextColor3 = TOK.moon
	wb.Parent = m
	m:SetAttribute("Species", speciesId)
	return m
end

-- Heartstone on a nest cradle: aurora-crystal core (LOCKED wording) with a soft light
function V.heartstone(pos, tier)
	local m = Instance.new("Model")
	m.Name = "Heartstone"
	local core = part(m, { Name = "Core", Size = Vector3.new(1.8, 2.4, 1.8), CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(45), math.rad(12)), Material = Enum.Material.Neon, Color = TOK.aurora, CanQuery = true })
	part(m, { Name = "Shell", Size = Vector3.new(2.4, 3.0, 2.4), CFrame = core.CFrame, Material = Enum.Material.Glass, Color = TOK.ice, Transparency = 0.55 })
	local l = Instance.new("PointLight")
	l.Color = TOK.aurora
	l.Range = 12
	l.Brightness = 1.4
	l.Parent = core
	m.PrimaryPart = core
	tag(m, core, tier .. " Heartstone", "bank, then place in a home nest", TOK.aurora, 60)
	return m
end

-- drop pack (owner-only recovery; countdown text is written by the owner's client)
function V.dropPack(pos)
	local m = Instance.new("Model")
	m.Name = "DropPack"
	local box = part(m, { Name = "Pack", Size = Vector3.new(2.4, 2.8, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0.15, 0.4, 0.1), Material = Enum.Material.Fabric, Color = TOK.timber, CanQuery = true })
	part(m, { Name = "Strap", Size = Vector3.new(2.5, 0.4, 1.7), CFrame = box.CFrame * CFrame.new(0, 0.6, 0), Material = Enum.Material.Fabric, Color = TOK.lantern })
	local l = Instance.new("PointLight")
	l.Color = TOK.lantern
	l.Range = 10
	l.Brightness = 1
	l.Parent = box
	m.PrimaryPart = box
	local bb = tag(m, box, "Drop pack", "", TOK.lantern, 200)
	bb.AlwaysOnTop = true
	return m
end

-- carried Heartstone glow on the character's back (others see cargo value, LOCKED); server-owned, replicated
function V.setCarryGlow(character, tierOrNil)
	if not character then
		return
	end
	local old = character:FindFirstChild("CC_CarryGlow")
	if not tierOrNil then
		if old then
			old:Destroy()
		end
		return
	end
	if old and old:GetAttribute("Tier") == tierOrNil then
		return
	end
	if old then
		old:Destroy()
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then
		return
	end
	local g = Instance.new("Part")
	g.Name = "CC_CarryGlow"
	g.Size = Vector3.new(1, 1.4, 1)
	g.Material = Enum.Material.Neon
	g.Color = TOK.aurora
	g.CanCollide, g.CanTouch, g.CanQuery, g.Massless = false, false, false, true
	g.CastShadow = false
	g.CFrame = torso.CFrame * CFrame.new(0, 0.2, 0.9) * CFrame.Angles(0, math.rad(45), 0)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = torso, g
	w.Parent = g
	local l = Instance.new("PointLight")
	l.Color = TOK.aurora
	l.Range = 10 + (C.HEARTSTONE_VALUE[tierOrNil] or 30) / 10
	l.Brightness = 1.6
	l.Parent = g
	g:SetAttribute("Tier", tierOrNil)
	g.Parent = character
end

return V
