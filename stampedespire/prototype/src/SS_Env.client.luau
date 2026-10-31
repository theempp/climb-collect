-- Mountain environment (StarterPlayerScripts.SS_Env): per-zone lighting/atmosphere blended as you
-- climb, zone title cards, and the effects anchored on SS_Markers (canyon light shafts, steam vents,
-- lava and crystal glow, aurora curtains) plus camera-local weather (snow, ice motes, embers, wind).
-- Every value comes from SS_Config (Env, Fx), whose colours are LOOKDEV tokens from the r2 sheets.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RepS = game:GetService("ReplicatedStorage")

local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))
-- The marker effects sit on the Blender mountain; with the art hidden (ShowGreybox, P1 pace test) there is none.
local M = C.ShowGreybox and { Shafts = {}, Vents = {}, Plumes = {}, Lava = {}, Crystals = {} }
	or require(RepS:WaitForChild("SS_Markers"))
local player = Players.LocalPlayer
local hex = Color3.fromHex
local F = C.Fx

-- Lighting objects ------------------------------------------------------------------------------
local function ensure(class, name, parent)
	local o = (parent or Lighting):FindFirstChild(name)
	if not o then
		o = Instance.new(class)
		o.Name = name
		o.Parent = parent or Lighting
	end
	return o
end
local atm = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "SS_Atmosphere")
local cc = ensure("ColorCorrectionEffect", "SS_Grade")
local bloom = ensure("BloomEffect", "SS_Bloom")
local rays = ensure("SunRaysEffect", "SS_SunRays")
local sky = Lighting:FindFirstChildOfClass("Sky") or ensure("Sky", "SS_Sky")
bloom.Size = 28
bloom.Threshold = 1.1
rays.Intensity = 0.06
rays.Spread = 0.6
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.8

-- Zone weights: smooth blend across each border, same window as the terrain.
local function smooth(a)
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end
local function weights(d)
	local w, n = {}, #C.Zones
	local t = {}
	for i = 2, n do
		t[i] = smooth((d - P.Starts[i] + C.EnvBlend) / (2 * C.EnvBlend))
	end
	for k = 1, n do
		local into = k == 1 and 1 or t[k]
		local out = k == n and 0 or t[k + 1]
		w[k] = into * (1 - out)
	end
	return w
end

local function mixNum(w, key)
	local v = 0
	for k, e in C.Env do
		v += e[key] * w[k]
	end
	return v
end
local function mixCol(w, key)
	local r, g, b = 0, 0, 0
	for k, e in C.Env do
		local c = hex(e[key])
		r += c.R * w[k]
		g += c.G * w[k]
		b += c.B * w[k]
	end
	return Color3.new(r, g, b)
end

local function applyEnv(w)
	Lighting.ClockTime = mixNum(w, "Clock") % 24
	Lighting.Brightness = mixNum(w, "Brightness")
	Lighting.Ambient = mixCol(w, "Ambient")
	Lighting.OutdoorAmbient = mixCol(w, "Outdoor")
	Lighting.ColorShift_Top = mixCol(w, "Sun")
	atm.Color = mixCol(w, "AtmColor")
	atm.Decay = mixCol(w, "AtmDecay")
	atm.Density = mixNum(w, "Density")
	atm.Haze = mixNum(w, "Haze")
	atm.Glare = mixNum(w, "Glare")
	atm.Offset = mixNum(w, "Offset")
	local tint = Color3.new(1, 1, 1)
	local r, g, b = 0, 0, 0
	for k, e in C.Env do
		local c = Color3.new(1, 1, 1):Lerp(hex(e.Tint), e.TintMix)
		r += c.R * w[k]
		g += c.G * w[k]
		b += c.B * w[k]
	end
	tint = Color3.new(r, g, b)
	cc.TintColor = tint
	cc.Saturation = mixNum(w, "Saturation")
	cc.Contrast = mixNum(w, "Contrast")
	bloom.Intensity = mixNum(w, "Bloom")
	sky.StarCount = math.floor(mixNum(w, "Stars"))
end

-- Effects ---------------------------------------------------------------------------------------
local fx = Instance.new("Folder")
fx.Name = "SS_FX"
fx.Parent = workspace

local function anchor(name, pos, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(pos)
	p.Parent = fx
	return p
end

local function seq(a, b)
	return NumberSequence.new(a, b)
end

-- Z2 light shafts: tall glowing columns falling from the canyon rim. They fade out near the camera
-- (ShaftFadeNear..Far) so riding through one never shows a translucent slab.
local shafts = {}
for i, pos in M.Shafts do
	local s = anchor("Shaft", pos, F.ShaftSize)
	table.insert(shafts, s)
	s.Transparency = F.ShaftTransparency
	s.Material = Enum.Material.Neon
	s.Color = hex(F.ShaftColor)
	s.CFrame = CFrame.new(pos - Vector3.new(0, F.ShaftSize.Y / 2 - 20, 0)) * CFrame.Angles(math.rad(8), math.rad(i * 37), math.rad(6))
end

-- Z3 steam: vents beside the track, big plumes out on the ridges.
local function steam(pos, big)
	local a = anchor(big and "Plume" or "Vent", pos, Vector3.new(4, 1, 4))
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(hex(F.SteamColor))
	e.LightInfluence = 0.7
	e.Size = big and seq(18, 70) or seq(3, 16)
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = big and NumberRange.new(7, 10) or NumberRange.new(2.5, 4)
	e.Rate = big and 3 or 7
	e.Speed = big and NumberRange.new(10, 16) or NumberRange.new(6, 10)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(4, 2, 0)
	e.Drag = 0.4
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Rotation = NumberRange.new(0, 360)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = a
end
for _, p in M.Vents do
	steam(p, false)
end
for _, p in M.Plumes do
	steam(p, true)
end

-- Lava and crystal glow (a few point lights; Neon/Glass meshes carry the rest).
local function lights(list, count, color, range, brightness)
	local stepN = math.max(1, math.floor(#list / count))
	for i = 1, #list, stepN do
		local a = anchor("Glow", list[i])
		local l = Instance.new("PointLight")
		l.Color = hex(color)
		l.Range = range
		l.Brightness = brightness
		l.Shadows = false
		l.Parent = a
	end
end
lights(M.Lava, F.LavaLights, F.LavaLightColor, F.LavaLightRange, 2.5)
lights(M.Crystals, F.CrystalLights, F.CrystalLightColor, F.CrystalLightRange, 2)

-- Z4 aurora: striated curtains of short vertical rays (green to purple, as on the sheet). Beams are
-- culled once an attachment is ~2048 studs from the camera, so the curtains ride along with the camera
-- like a sky layer (no parallax; reads as infinitely far).
local auroraBeams = {}
local auroraRoot = anchor("Aurora", Vector3.zero)
do
	local cols = {}
	for _, h in F.AuroraColors do
		table.insert(cols, hex(h))
	end
	-- green at the foot, purple at the top; across the span the purple takes over toward the right, as on
	-- the sheet (purple-dominant at Z4 x 850-1000). Rays overlap additively, so a top-only purple washed out.
	local function colour(t)
		local s = math.clamp((t - F.AuroraPurpleSide[1]) / (F.AuroraPurpleSide[2] - F.AuroraPurpleSide[1]), 0, 1)
		local f = math.max(F.AuroraPurpleFrom * (1 - 0.9 * s), 0.04)
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, cols[1]:Lerp(cols[3], s)), ColorSequenceKeypoint.new(f * 0.5, cols[2]:Lerp(cols[3], s)),
			ColorSequenceKeypoint.new(f, cols[3]), ColorSequenceKeypoint.new(1, cols[3]),
		})
	end
	for c = 1, F.AuroraCurtains do
		local rng = Random.new(c * 97)
		for i = 1, F.AuroraRays do
			local t = (i - 1) / (F.AuroraRays - 1)
			local x = (t * 2 - 1) * F.AuroraSpan
			local z = -F.AuroraDistance - (c - 1) * F.AuroraStep.Z - 160 * math.sin(t * math.pi * (2 + c * 0.6) + c) - 60 * math.sin(t * 17)
			local y = F.AuroraHeight + (c - 1) * F.AuroraStep.Y + 50 * math.sin(t * 5 + c)
			local h = F.AuroraRayHeight * (0.7 + 0.5 * rng:NextNumber())
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(x, y, z)
			a0.Parent = auroraRoot
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(x + rng:NextNumber(-20, 20), y + h, z)
			a1.Parent = auroraRoot
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = a0, a1
			b.FaceCamera = true
			b.Width0, b.Width1 = F.AuroraRayWidth, F.AuroraRayWidth * 1.3
			b.LightEmission = 1
			b.LightInfluence = 0
			b.Brightness = F.AuroraBrightness * (0.75 + 0.3 * rng:NextNumber())
			b.Color = colour(t)
			b.Parent = auroraRoot
			table.insert(auroraBeams, b)
		end
	end
end
-- Beams stay Enabled and fade by Transparency. (After a long debug teleport the curtains take ~5-9 s
-- to appear; riding up continuously they are there as the zone blends in.)
local function setAurora(alpha) -- alpha 0 = hidden, 1 = full
	local op = F.AuroraOpacity * alpha
	local tr = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1 - op * 0.5), NumberSequenceKeypoint.new(0.15, 1 - op),
		NumberSequenceKeypoint.new(0.6, 1 - op * 0.75), NumberSequenceKeypoint.new(0.85, 1 - op * F.AuroraTopOpacity),
		NumberSequenceKeypoint.new(1, 1 - op * F.AuroraTopOpacity * 0.4),
	})
	if alpha <= 0.02 then
		tr = NumberSequence.new(1)
	end
	for _, b in auroraBeams do
		b.Transparency = tr
	end
end

-- Camera-local weather: one box emitter per kind, rate scaled by that zone's weight.
local weatherBox = anchor("Weather", Vector3.zero, Vector3.new(120, 50, 120))
local weather = {}
local function emitter(kind, props)
	local e = Instance.new("ParticleEmitter")
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	for k, v in props do
		e[k] = v
	end
	e.Rate = 0
	e.Parent = weatherBox
	weather[kind] = e
end
emitter("snow", {
	Color = ColorSequence.new(hex(F.SnowColor)), Size = seq(0.35, 0.25), Lifetime = NumberRange.new(4, 6),
	Speed = NumberRange.new(4, 7), EmissionDirection = Enum.NormalId.Bottom, Acceleration = Vector3.new(3, -2, 0),
	LightEmission = 0.3, Transparency = seq(0.1, 0.6), RotSpeed = NumberRange.new(-60, 60),
})
emitter("motes", {
	Color = ColorSequence.new(hex(F.MoteColor)), Size = seq(0.25, 0.1), Lifetime = NumberRange.new(5, 8),
	Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Transparency = seq(0.2, 1),
})
emitter("embers", {
	Color = ColorSequence.new(hex(F.EmberColors[1]), hex(F.EmberColors[2])), Size = seq(0.35, 0.05),
	Lifetime = NumberRange.new(2, 4), Speed = NumberRange.new(3, 8), EmissionDirection = Enum.NormalId.Top,
	SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(2, 3, 0), LightEmission = 1, Transparency = seq(0, 1),
})
emitter("wind", {
	Color = ColorSequence.new(hex(F.WindColor)), Size = seq(0.18, 0.1), Lifetime = NumberRange.new(0.8, 1.4),
	Speed = NumberRange.new(55, 80), EmissionDirection = Enum.NormalId.Right, SpreadAngle = Vector2.new(6, 6),
	LightEmission = 0.15, Transparency = seq(0.35, 0.95), Squash = seq(-1.2, -1.2),
})

-- Title cards ------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SS_Titles"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
-- Starts below SS_Ride's hint line (same top-bar inset), so the card and the hint never overlap.
local U = C.Ui
local card = Instance.new("Frame")
card.Name = "Card"
card.BackgroundTransparency = 1
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, U.TopGap + require(RepS:WaitForChild("SS_Timeline")).block() + U.HintHeight + U.TitleGap)
card.Size = UDim2.fromScale(U.TitleWidth, U.TitleHeight)
card.Parent = gui
local function text(name, y, h, font)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0, y)
	t.Size = UDim2.fromScale(1, h)
	t.Font = font
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.6
	t.TextTransparency = 1
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.Parent = card
	return t
end
local tZone = text("Zone", 0, 0.22, Enum.Font.GothamBold)
local tName = text("Title", 0.22, 0.5, Enum.Font.GothamBlack)
local tTag = text("Tag", 0.76, 0.2, Enum.Font.GothamMedium)
local titleSeq = 0
local function showTitle(k)
	titleSeq += 1
	local my = titleSeq
	local z = C.Zones[k]
	tZone.Text = string.format("SECTION %d / %d", k, #C.Zones)
	tName.Text = string.upper(z.Name)
	tName.TextColor3 = hex(z.TitleColor)
	for _, t in { tZone, tName, tTag } do
		t.TextStrokeColor3 = hex(z.TitleStroke)
	end
	tTag.Text = z.Tagline
	local info = TweenInfo.new(C.TitleFade)
	for _, t in { tZone, tName, tTag } do
		TweenService:Create(t, info, { TextTransparency = 0, TextStrokeTransparency = 0.15 }):Play()
	end
	task.delay(C.TitleFade + C.TitleHold, function()
		if my ~= titleSeq then
			return
		end
		for _, t in { tZone, tName, tTag } do
			TweenService:Create(t, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Zone-4 skybox (LOOKDEV z4 sky tokens, art/tools/make_sky.py): shown while zone 4 dominates the blend;
-- zones 1-3 keep the place's own sky.
local SKY_FACES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }
local baseSky = {}
for _, f in SKY_FACES do
	baseSky[f] = sky[f]
end
local skyOn
local function setSkybox(on)
	local z4 = C.Env[#C.Env].Skybox
	if on == skyOn or not z4 then
		return
	end
	skyOn = on
	for _, f in SKY_FACES do
		local id = (f == "SkyboxUp" and z4.Up) or (f == "SkyboxDn" and z4.Down) or z4.Side
		sky[f] = on and id or baseSky[f]
	end
end

-- Per-frame --------------------------------------------------------------------------------------
local lastZone = 0
local acc = 0
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local d = hrp and P.project(hrp.Position) or 0
	local w = weights(d)
	acc += dt
	if acc > 0.1 then -- lighting at 10 Hz is plenty for a blend
		acc = 0
		applyEnv(w)
		setAurora(w[#w])
		sky.CelestialBodiesShown = w[#w] < 0.5 -- the Z4 sheet shows no moon; zones 1-3 keep the sun
		setSkybox(w[#w] >= 0.5)
	end
	auroraRoot.CFrame = CFrame.new(cam.CFrame.Position)
	for _, sh in shafts do
		local a = Vector2.new(sh.Position.X - cam.CFrame.Position.X, sh.Position.Z - cam.CFrame.Position.Z).Magnitude
		sh.LocalTransparencyModifier = 1 - math.clamp((a - F.ShaftFadeNear) / (F.ShaftFadeFar - F.ShaftFadeNear), 0, 1)
	end
	weatherBox.CFrame = CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 30 + Vector3.new(0, 18, 0))
	local rate = {} -- several zones can share one weather type: sum their weights
	for k, e in C.Env do
		rate[e.Fx] = (rate[e.Fx] or 0) + (F.WeatherRate[e.Fx] or 0) * w[k]
	end
	for kind, em in weather do
		em.Rate = rate[kind] or 0
	end
	local k = P.zoneOf(math.clamp(d, 0, P.Total - 1))
	if hrp and k ~= lastZone and d > -60 and d < P.Total then
		if k > lastZone or lastZone == 0 or k == 1 then
			showTitle(k)
		end
		lastZone = k
	end
end)
applyEnv(weights(0))
