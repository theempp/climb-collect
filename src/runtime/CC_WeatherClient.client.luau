-- CC_WeatherClient (StarterPlayerScripts), v4 P4 run 2: draws the server's day/night + weather (Weather module).
-- Concept LOCKED #13: dynamic, with mobile quality tiers, only after a measured cost test (design/v4-run2-log.md).
-- Tiers from the player's graphics level (Automatic counts as mid):
--   low  (1-3): ClockTime + atmosphere only (no particles, only your own headlamp lit)
--   mid  (4-7): + snow / mist particles at 40 % rate, headlamps of players within 120 studs
--   high (8-10): full particle rate
-- Colors are world tokens (design/world-tokens.md). workspace CC_WeatherOff (Studio dev action) = the static
-- LightingSetup look, for perf comparisons.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer
local C = require(RS:WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local W = C.WEATHER

local GOLDEN = Color3.fromRGB(255, 214, 150) -- goldenDaylight
local MOON = Color3.fromRGB(220, 230, 255) -- moonlight
local SAPPHIRE = Color3.fromRGB(30, 62, 140) -- deepSapphire
local STORM = Color3.fromRGB(46, 72, 122) -- stormBlue
local ICE = Color3.fromRGB(196, 232, 255) -- iceBlue

-- the static look (LightingSetup) = the clear-day target
local BASE = {
	Brightness = 2.6,
	OutdoorAmbient = Color3.fromRGB(128, 120, 112),
	Ambient = Color3.fromRGB(70, 68, 76),
	ColorShift_Top = GOLDEN,
	density = 0.24,
	haze = 1.4,
	atmColor = GOLDEN,
	cover = 0.5,
}
local LOOK = {
	clear = { density = 0.24, haze = 1.4, atmColor = GOLDEN, cover = 0.5, wind = 2 },
	mist = { density = 0.42, haze = 2.6, atmColor = MOON, cover = 0.62, wind = 3 },
	snow = { density = 0.34, haze = 2.2, atmColor = ICE, cover = 0.78, wind = 6 },
	gust = { density = 0.3, haze = 1.9, atmColor = STORM, cover = 0.72, wind = 16 },
}

local function tier()
	local ok, q = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	q = ok and q or 0
	if q == 0 then
		return "mid"
	end
	return (q <= 3 and "low") or (q <= 7 and "mid") or "high"
end

-- ClockTime from the server's day start (identical on every client)
local function clockNow()
	local start = workspace:GetAttribute("CC_DayStart")
	if not start then
		return 15.4
	end
	local cyc = W.dayMinutes * 60
	local phase = ((workspace:GetServerTimeNow() - start) % cyc) / cyc
	local dayH = W.nightFrom - W.nightTo
	if phase < W.dayShare then
		return W.nightTo + phase / W.dayShare * dayH
	end
	return (W.nightFrom + (phase - W.dayShare) / (1 - W.dayShare) * (24 - dayH)) % 24
end

-- 0 = full day, 1 = full night (an hour of dusk / dawn each side)
local function nightness(h)
	local function ramp(x, a, b)
		return math.clamp((x - a) / (b - a), 0, 1)
	end
	if h >= W.nightTo + 1 and h <= W.nightFrom - 1 then
		return 0
	end
	if h > W.nightFrom - 1 and h < 24 then
		return ramp(h, W.nightFrom - 1, W.nightFrom + 0.5)
	end
	return 1 - ramp(h, W.nightTo - 0.5, W.nightTo + 1)
end

-- particles: one emitter box above the camera (snow above snowY; mist anywhere)
local box = Instance.new("Part")
box.Name = "CC_WeatherBox"
box.Anchored, box.CanCollide, box.CanQuery, box.CanTouch = true, false, false, false
box.Transparency = 1
box.Size = Vector3.new(90, 1, 90)
box.Parent = workspace.CurrentCamera
local snow = Instance.new("ParticleEmitter")
snow.Name = "Snow"
snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
snow.Color = ColorSequence.new(ICE)
snow.LightEmission = 0.2
snow.Size = NumberSequence.new(0.35)
snow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
snow.Lifetime = NumberRange.new(5, 7)
snow.Speed = NumberRange.new(6, 9)
snow.EmissionDirection = Enum.NormalId.Bottom
snow.SpreadAngle = Vector2.new(20, 20)
snow.Rate = 0
snow.Parent = box
local mist = Instance.new("ParticleEmitter")
mist.Name = "Mist"
mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
mist.Color = ColorSequence.new(MOON)
mist.LightEmission = 0
mist.Size = NumberSequence.new(14, 22)
mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.82), NumberSequenceKeypoint.new(1, 1) })
mist.Lifetime = NumberRange.new(8, 12)
mist.Speed = NumberRange.new(1, 2)
mist.EmissionDirection = Enum.NormalId.Bottom
mist.Rate = 0
mist.Parent = box

local atm = Lighting:FindFirstChildOfClass("Atmosphere")
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local cur = { density = BASE.density, haze = BASE.haze, atmColor = BASE.atmColor, cover = BASE.cover, wind = 2 }
local myTier = tier()
local tierAt = 0
local lampAt = 0

local function lerp(a, b, t)
	return a + (b - a) * t
end

Run.RenderStepped:Connect(function(dt)
	if workspace:GetAttribute("CC_WeatherOff") then
		-- static LightingSetup look
		Lighting.ClockTime = 15.4
		snow.Rate, mist.Rate = 0, 0
		return
	end
	if os.clock() - tierAt > 5 then
		tierAt = os.clock()
		myTier = tier()
	end
	local h = clockNow()
	Lighting.ClockTime = h
	local n = nightness(h)
	-- night: moonlit sapphire ambient, cooler top shift, a little less sun brightness (markers still glow)
	Lighting.OutdoorAmbient = BASE.OutdoorAmbient:Lerp(SAPPHIRE, n * 0.7)
	Lighting.ColorShift_Top = GOLDEN:Lerp(MOON, n)
	Lighting.Brightness = lerp(BASE.Brightness, 1.6, n)

	local state = workspace:GetAttribute("CC_Weather") or "clear"
	local look = LOOK[state] or LOOK.clear
	local k = math.min(1, dt / 6) -- ~6 s blend
	cur.density = lerp(cur.density, look.density, k)
	cur.haze = lerp(cur.haze, look.haze, k)
	cur.atmColor = cur.atmColor:Lerp(look.atmColor, k)
	cur.cover = lerp(cur.cover, look.cover, k)
	cur.wind = lerp(cur.wind, look.wind, k)
	if atm then
		atm.Density = cur.density
		atm.Haze = cur.haze
		atm.Color = cur.atmColor:Lerp(SAPPHIRE, n * 0.5)
	end
	if clouds then
		clouds.Cover = cur.cover
	end
	workspace.GlobalWind = Vector3.new(cur.wind, 0, cur.wind * 0.4)

	local camPos = workspace.CurrentCamera.CFrame.Position
	box.CFrame = CFrame.new(camPos + Vector3.new(0, 30, 0))
	local rateMul = (myTier == "high" and 1) or (myTier == "mid" and 0.4) or 0
	snow.Rate = (state == "snow" and camPos.Y > W.snowY) and 260 * rateMul or 0
	mist.Rate = (state == "mist") and 6 * rateMul or 0

	-- headlamps: on at night (low tier: only your own)
	if os.clock() - lampAt > 0.5 then
		lampAt = os.clock()
		for _, p in ipairs(Players:GetPlayers()) do
			local ch = p.Character
			local g = ch and ch:FindFirstChild("CC_Gear")
			local lamp = g and g:FindFirstChild("Headlamp")
			local light = lamp and lamp:FindFirstChild("HeadlampLight")
			if light then
				local near = p == plr or (myTier ~= "low" and ch.PrimaryPart and (ch.PrimaryPart.Position - camPos).Magnitude < 120)
				light.Enabled = ch:GetAttribute("CC_HeadlampActive") == true and near
			end
		end
	end
end)
