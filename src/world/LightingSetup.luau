-- LightingSetup: lower-mountain lighting baseline (PROPOSED).
-- Palette values come from design/world-tokens.md (master.md §3 "golden daylight",
-- "atmospheric depth", §4 storm blue). Ambient levels are technical, not palette.
local L = {}

local GOLDEN = Color3.fromRGB(255, 214, 150) -- goldenDaylight
local STORM = Color3.fromRGB(46, 72, 122) -- stormBlue (far haze decays toward it)

local function child(parent, class, name)
	local c = parent:FindFirstChild(name)
	if not c then
		c = Instance.new(class)
		c.Name = name
		c.Parent = parent
	end
	return c
end

function L.apply()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 15.4
	Lighting.GeographicLatitude = 23
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(70, 68, 76)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 120, 112)
	Lighting.ColorShift_Top = GOLDEN
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.25

	local atm = child(Lighting, "Atmosphere", "Atmosphere")
	atm.Density = 0.24
	atm.Offset = 0.18
	atm.Color = GOLDEN
	atm.Decay = STORM
	atm.Glare = 0.35
	atm.Haze = 1.4

	local bloom = child(Lighting, "BloomEffect", "Bloom")
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.6

	local rays = child(Lighting, "SunRaysEffect", "SunRays")
	rays.Intensity = 0.06
	rays.Spread = 0.6

	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.Enabled = false -- readability + mobile cost
	end

	local cc = child(Lighting, "ColorCorrectionEffect", "WorldGrade")
	cc.Saturation = 0.12 -- §3 "vibrant stylized nature"
	cc.Contrast = 0.06
	cc.Brightness = 0
	cc.TintColor = Color3.new(1, 1, 1)

	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.5
	clouds.Density = 0.55
	clouds.Color = Color3.new(1, 1, 1)
	clouds.Parent = workspace.Terrain
end

return L
