-- Stampede Spire grey-box tunables (ReplicatedStorage.SS_Config). All feel numbers live here.
-- Placeholder colours are sampled from the approved r2 zone sheets (concepts/2026-10-29/r2-*.png).
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	-- Mountain: zones in climb order. Length = studs along the slope; the mountain is their sum.
	-- LaneWidth narrows per zone; the change ramps in over NarrowRamp studs before each border.
	-- SpeedMul is the step applied from that zone's border on. Ground = sheet header sample.
	-- Tagline = the zone sheet's header line (shown on the zone title card). TitleStroke = the zone's darkest
	-- LOOKDEV token (z1 pine_dark, z2 ice_deep, z3 spire_dark, z4 night_deep): the outline that keeps a light
	-- title readable on a bright sky (M6). Accent = horn/antler tint
	-- for that zone's placeholder creatures (LOOKDEV token). art/tools/sspath.py reads Length/SlopeDeg/LaneWidth.
	Zones = {
		{ Name = "Frozen Taiga Foothills", Length = 1000, SlopeDeg = 10, LaneWidth = 12, SpeedMul = 1, Ground = rgb(217, 223, 234), Tagline = "BOREAL FOREST / SNOWFIELDS / WIDE LANES / MORNING LIGHT", TitleStroke = "#2E3C4E", TitleColor = "#E9EAF0", Accent = "#E9EAF0", AccentGlow = false },
		{ Name = "Crevasse Ice Canyons", Length = 1000, SlopeDeg = 13, LaneWidth = 10, SpeedMul = 1.25, Ground = rgb(67, 157, 221), Tagline = "TOWERING ICE WALLS. NARROW LANES. NEW HORIZONS.", TitleStroke = "#054480", TitleColor = "#A3DBF7", Accent = "#A3DBF7", AccentGlow = false },
		{ Name = "Geothermal Obsidian Ridge", Length = 1000, SlopeDeg = 16, LaneWidth = 8.5, SpeedMul = 1.55, Ground = rgb(129, 91, 79), Tagline = "HOTTER GROUND / HIGHER RISKS / STRONGER CREATURES", TitleStroke = "#0F090C", TitleColor = "#F46E1E", Accent = "#F46E1E", AccentGlow = true },
		{ Name = "Aurora Crown", Length = 1000, SlopeDeg = 20, LaneWidth = 7, SpeedMul = 1.85, Ground = rgb(18, 37, 86), Tagline = "MOUNTAIN PEAK", TitleStroke = "#04132F", TitleColor = "#B5ECFD", Accent = "#3F91F6", AccentGlow = true },
	},
	NarrowRamp = 40,
	LaneCount = 5,
	SlopeBlend = 80, -- studs: the slope eases from one zone's angle to the next, centred on each border
	SummitFlat = 40, -- studs past the top over which the slope eases to the flat summit plateau
	-- Plan-view bends (milestone 5): the path's heading turns by Deg over Len studs centred on At
	-- (smoothstep, so no kinks). The mountain is built straight and warped along this curve (SS_Path.warp,
	-- art/tools/sspath.py warp): lanes, herd, collision, walls and art all follow it. Keep the tightest
	-- radius (Len / (1.5 * rad(|Deg|))) above ~1,400 studs so the +-950 terrain and its skirts never fold.
	Bends = {
		{ At = 700, Len = 600, Deg = 10 },
		{ At = 2000, Len = 760, Deg = -20 },
		{ At = 3300, Len = 600, Deg = 10 },
	},

	-- Herd species per zone (index = zone). Size = placeholder body block (studs), relative to the
	-- avatar on each sheet. Speed = species tier relative to its zone (sheet "speed tier").
	-- Color = body sample from the sheet. Saiga and Ashmane come from r2-replacements.
	-- Model = skinned creature in ReplicatedStorage.SS_Creatures (M8, art/creatures); its mesh size replaces Size.
	-- M8 part 3 (owner playtest): Speed tiers vary per species (fast ones run past you, slow ones lag).
	-- Weight = spawn odds (default 1). Big + Rare = a large rare runner; Fly = a rideable flyer gliding Fly studs
	-- above its lane (greybox wings). Score = points per stud ridden (default 1). The 5 Rare flyers live only in
	-- zones 3-4. New species are greybox; their colours are LOOKDEV tokens (hex in the comment).
	Species = {
		{
			{ Name = "Taiga Elk", Model = "taiga_elk", Size = Vector3.new(4.5, 5, 10), Speed = 1, Color = rgb(65, 52, 45) },
			{ Name = "Woolly Reindeer", Model = "woolly_reindeer", Size = Vector3.new(4, 4.5, 9), Speed = 1.15, Color = rgb(154, 148, 144) },
			{ Name = "Musk Ox Calfrunner", Model = "musk_ox_calfrunner", Size = Vector3.new(5.5, 5, 9), Speed = 0.75, Color = rgb(56, 47, 44) },
			{ Name = "Snowshoe Hare-Hound", Model = "snowshoe_hare_hound", Size = Vector3.new(3.5, 4, 8), Speed = 1.5, Color = rgb(207, 211, 216) },
			{ Name = "Pine Boar", Model = "pine_boar", Size = Vector3.new(4.5, 3.5, 8), Speed = 0.85, Color = rgb(60, 52, 48) },
			{ Name = "Snowcrest Bull Elk", Size = Vector3.new(6.5, 7, 14), Speed = 1.3, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(57, 45, 40) }, -- #392D28
			{ Name = "Pine Owlhawk", Size = Vector3.new(3, 2, 5), Speed = 1.25, Fly = 14, Weight = 0.5, Color = rgb(62, 80, 103) }, -- #3E5067
		},
		{
			{ Name = "Crevasse Ibex", Size = Vector3.new(4, 4.5, 8.5), Speed = 1, Color = rgb(77, 107, 131) },
			{ Name = "Glacier Chamois", Size = Vector3.new(3.5, 4.5, 8), Speed = 1.45, Color = rgb(145, 202, 234) },
			{ Name = "Frostback Takin", Size = Vector3.new(5.5, 5, 9), Speed = 0.75, Color = rgb(74, 90, 103) },
			{ Name = "Rime Moose", Size = Vector3.new(5, 5.5, 10), Speed = 1, Color = rgb(35, 63, 87) },
			{ Name = "Glacier Saiga", Size = Vector3.new(4, 4.5, 9), Speed = 1.2, Color = rgb(180, 162, 139) },
			{ Name = "Glacier Mammoth", Size = Vector3.new(8, 8, 15), Speed = 1.25, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(46, 102, 155) }, -- #2E669B
			{ Name = "Crevasse Gull-Kite", Size = Vector3.new(3, 2, 5), Speed = 1.3, Fly = 15, Weight = 0.5, Color = rgb(163, 219, 247) }, -- #A3DBF7
		},
		{
			{ Name = "Ember Yak", Size = Vector3.new(5.5, 5, 9.5), Speed = 1, Color = rgb(30, 15, 11) },
			{ Name = "Basalt Rhino-Goat", Size = Vector3.new(5, 4.5, 9), Speed = 0.8, Color = rgb(76, 61, 58) },
			{ Name = "Steam Bison", Size = Vector3.new(5.5, 5.5, 10), Speed = 0.75, Color = rgb(29, 28, 28) },
			{ Name = "Obsidian Gazelle", Size = Vector3.new(3, 4, 8), Speed = 1.5, Color = rgb(50, 38, 37) },
			{ Name = "Ashmane Wild Horse", Size = Vector3.new(4, 5, 10), Speed = 1.2, Color = rgb(98, 83, 76) },
			{ Name = "Magma Behemoth", Size = Vector3.new(8, 8, 15), Speed = 1.2, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(43, 21, 22) }, -- #2B1516
			{ Name = "Ash Roc", Size = Vector3.new(3.5, 2.5, 6), Speed = 1.35, Fly = 16, Weight = 0.5, Color = rgb(113, 52, 33) }, -- #713421
			{ Name = "Cinder Wyvern", Size = Vector3.new(6, 3.5, 12), Speed = 1.6, Fly = 18, Rare = true, Weight = 0.12, Score = 5, Color = rgb(244, 110, 30) }, -- #F46E1E
			{ Name = "Lava Drake", Size = Vector3.new(6, 3.5, 12), Speed = 1.6, Fly = 18, Rare = true, Weight = 0.12, Score = 5, Color = rgb(155, 38, 15) }, -- #9B260F
		},
		{
			{ Name = "Crystal Ram", Size = Vector3.new(4.5, 4.5, 8.5), Speed = 1.05, Color = rgb(114, 122, 143) },
			{ Name = "Skyhorn Antelope", Size = Vector3.new(3.5, 4.5, 8.5), Speed = 1.45, Color = rgb(181, 196, 218) },
			{ Name = "Aurora Hart", Size = Vector3.new(3.5, 4.5, 9), Speed = 1, Color = rgb(157, 178, 241) },
			{ Name = "Gale Kirin-Horse", Size = Vector3.new(3.5, 4.5, 9.5), Speed = 1.1, Color = rgb(116, 148, 228) },
			{ Name = "Starfrost Ox", Size = Vector3.new(6, 5.5, 10), Speed = 0.75, Color = rgb(34, 50, 87) },
			{ Name = "Crown Colossus Ram", Size = Vector3.new(8, 8, 14), Speed = 1.25, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(61, 98, 178) }, -- #3D62B2
			{ Name = "Frost Swiftwing", Size = Vector3.new(3, 2, 5), Speed = 1.4, Fly = 16, Weight = 0.5, Color = rgb(181, 236, 253) }, -- #B5ECFD
			{ Name = "Aurora Dragon", Size = Vector3.new(7, 4, 14), Speed = 1.7, Fly = 20, Rare = true, Weight = 0.12, Score = 5, Color = rgb(65, 212, 162) }, -- #41D4A2
			{ Name = "Starwing Drake", Size = Vector3.new(6, 3.5, 12), Speed = 1.7, Fly = 20, Rare = true, Weight = 0.12, Score = 5, Color = rgb(164, 105, 244) }, -- #A469F4
			{ Name = "Crystal Phoenix", Size = Vector3.new(5, 3, 10), Speed = 1.8, Fly = 22, Rare = true, Weight = 0.12, Score = 5, Color = rgb(63, 145, 246) }, -- #3F91F6
		},
	},

	-- Herd speed: gradual ramp with distance, times the zone's SpeedMul step and the species tier
	BaseSpeed = 22, -- studs/s at the bottom
	SpeedPerStud = 0.005, -- extra studs/s per stud climbed
	HerdPerLane = 5, -- per zone; each herd runs its own zone and wraps to its start unless ridden
	SpeedJitter = 0.1, -- +/- fraction per creature, so lanes drift past each other
	-- M8: no pop-back, no same-lane overlap. A creature past its zone end only recycles to its zone start
	-- once it is RecycleAhead studs ahead of the rider (or behind it), or at the summit; until then it runs
	-- on into the next zone like a carried-on mount (a forced recycle at a fixed overrun showed as a pop). A
	-- recycle that would land within RecycleClear of the rider lands RecycleClear behind it instead (the
	-- camera looks up the slope; near a zone start that is just inside the zone below). Creatures keep
	-- LaneGap studs nose-to-tail; a ridden one pushes its leader.
	RecycleAhead = 250, RecycleClear = 120, LaneGap = 14,
	PassRetry = 0.6, PassEase = 2.5, -- a blocked faster creature tries a free neighbour lane every PassRetry s; sideways ease rate
	SummitFade = 40, -- studs before the summit over which unridden creatures fade out (they recycle there)
	NameTagDistance = 70, -- studs; species tags are hidden beyond this

	-- Phone UI (milestone 4). Swappable (in-range) creatures get their tag first, then the nearest.
	-- Tags that would overlap on screen are stacked upward; they fade out from TagFadeStart to NameTagDistance.
	Ui = {
		DebugHud = false, -- zone / studs / speed readout (Studio debugging only)
		TopGap = 6, -- px below the top bar where the hint line starts
		HintHeight = 26, HintWidth = 0.6, HintMaxText = 20, HintMinText = 11, -- hint line at the top, off the lanes
		TitleGap = 10, -- px between the hint line and the zone title card
		TitleWidth = 0.7, TitleHeight = 0.2, -- zone title card (scale of the safe area)
		TagMax = 4, TagFadeStart = 45, TagSize = Vector2.new(150, 20), TagStackGap = 2, -- px
		-- Progress timeline (SS_Timeline): the top strip. One equal-width segment per zone, a checkpoint node at
		-- every border, your rider + mount sliding along it. It sits at TopGap; the hint line and the title card
		-- start below it (Height + Gap). Colours are each zone's TitleColor / TitleStroke tokens. Width is a scale
		-- of the safe area, the rest px. Back = transparency of the unreached track and the icon disc, Smooth =
		-- marker easing per second, Pop = checkpoint pop seconds. All sizes and Back / Smooth / Pop are judgement
		-- values, shown at each sign-off like the D5 values.
		Timeline = {
			Enabled = true, Width = 0.6, Height = 36, Gap = 4,
			Icon = 24, Rider = 16, Bar = 7, Node = 13,
			Back = 0.35, Smooth = 10, Pop = 0.35,
		},
	},

	-- Swap
	SwapRange = 40, -- max body-to-body distance to start a swap
	TapPickRadius = 80, -- px: a tap this close to a creature on screen counts as tapping it
	StanceTime = 0.6, -- stand-up wobble before the ring appears
	WobbleAmp = 14, -- degrees
	WobbleHz = 3.2,
	RingDuration = 1.4, -- seconds for the ring to shrink from start to zero
	RingStartScale = 3, -- ring size relative to the target circle
	TargetScale = 1,
	SuccessWindow = 0.28, -- +/- ring scale around TargetScale that counts as a hit
	JumpTime = 0.55,
	JumpHeight = 9,
	-- Leap (owner, 2026-10-29): a ring hit launches a slow-motion leap. You steer it toward the mouse / touch
	-- point (the camera turns with you); without pointer input it homes on the picked creature. Land on any
	-- creature's back; hit the snow and it's a faceplant. Power 0..1 = ring accuracy.
	Leap = {
		Time = 1.1, PowerTime = 0.5, -- game seconds of flight to the picked creature: Time + PowerTime * power
		Gravity = 70, -- studs/s^2 (game time)
		Slow = 0.3, EaseIn = 0.15, EaseOut = 0.12, MaxSlow = 1.4, -- world time scale in the air; ease in (real s),
		-- ease out (game s before the planned landing), max real seconds of slow motion
		AirAccel = 70, AirSpeed = 30, -- studs/s^2 and studs/s of steering relative to the herd flow
		Assist = 10, -- studs: (unused since auto-target) kept for live tuning
		-- Auto-target (owner, M8 part 3): the aim always locks the creature nearest the pointer's spot (never the
		-- one you left); in the last Magnet game seconds the flight bends onto its back, so every leap lands.
		Magnet = 0.45,
		Glide = 0.5, -- gravity multiplier when leaping off a flyer (a glide-leap)
		CatchPad = 1.5, -- studs of slack around a back when landing
		Fov = 14, Shake = 0.9, Dip = 1.2, -- in-air FOV kick (deg), landing camera shake and creature dip (studs)
		Puff = 24, TrailLife = 0.35, -- landing puff particles and trail length (s), in the zone's weather colour
	},

	ScoreRate = 1, -- points per stud ridden, times the mount's Score
	FlyBob = 1.5, FlyFlap = 35, -- flyer glide bob (studs) and wing flap (degrees)

	-- Fail
	FallDistance = 30, -- studs dropped back down the lane on a faceplant
	FaceplantTime = 1.4,
	RemountRange = 9, -- a passing creature this close (same lane) picks you up
	RemountGrace = 0.4, -- seconds after standing before remount is allowed

	-- Summit
	SummitHold = 4, -- seconds on the summit (camera orbits the crown) before you are sent back to the foothills

	-- Art pass (milestone 3) -----------------------------------------------------------------------
	-- The visible mountain is Workspace.SS_Mountain (Blender meshes built by art/tools/build_mountain.py).
	-- SS_Track only lays invisible collision along the path; ShowGreybox re-shows the old lane strip.
	ShowGreybox = false,
	CollisionStep = 20, -- studs per hidden collision slab along the path
	CollisionPad = 6, -- studs of walkable berm beyond the outer lanes (matches the mesh berm)
	WallHeight = 14, -- invisible side walls that keep a dismounted rider on the track

	-- Placeholder creatures: blocky body/legs/head/horns with a gallop cycle (still not final art)
	GallopPerStud = 0.32, -- leg-cycle radians per stud travelled
	GallopClip = 0.8, -- seconds per stride in the skinned gallop clip (24 frames at 30 fps, art/creatures)
	GallopSwing = 38, -- degrees of leg swing
	BobHeight = 0.6,

	-- Ride camera (Scriptable while mounted). Speed reads as a FOV that widens with herd speed plus a
	-- small shake; the camera sits behind and above, looking up the slope so the vista stays in frame.
	Cam = {
		Back = 24, Up = 10, LookAhead = 55, LookUp = 4, LaneFollow = 0.55, Lag = 7,
		Fov = 66, FovPerSpeed = 0.2, FovMax = 88, Shake = 0.05,
		SummitRadius = 230, SummitHeight = 115, SummitSpin = 0.22, -- orbit around the crown on the summit
		-- Occlusion: herd creatures between the camera and the rider fade to FadeAlpha; one the camera
		-- would be inside (its box grown by HideMargin) is hidden. Fades ease at FadeSpeed per second.
		FadeMargin = 1.5, FadeAlpha = 0.75, HideMargin = 1.5, FadeSpeed = 10,
	},

	-- Zone title cards
	TitleHold = 2.6, -- seconds fully shown
	TitleFade = 0.5,

	-- Environment per zone, blended over EnvBlend studs either side of each border (the terrain uses the
	-- same blend). Colours are LOOKDEV tokens (art/LOOKDEV.md), all sampled from the r2 zone sheets.
	-- TintMix = how far ColorCorrection moves from white toward the zone tint. Z4 uses a daytime clock (13)
	-- at low brightness: Roblox darkens any skybox toward black after sunset, so only a day clock shows the
	-- Z4 skybox (sky_zenith/mid/low) at its authored navy (M6, evidence/69-70). Its outdoor
	-- ambient is crystal_glint (not snow_path) so lit crystal facets and the path read pale, as on the sheet.
	EnvBlend = 70,
	Env = {
		{ Clock = 8.5, Brightness = 2.2, Ambient = "#343843", Outdoor = "#688AB4", Sun = "#FAF9F6",
			AtmColor = "#A5B8D5", AtmDecay = "#7B93AE", Density = 0.3, Haze = 1.4, Glare = 0.5, Offset = 0.12,
			Tint = "#FAF9F6", TintMix = 1, Saturation = 0.05, Contrast = 0.06, Bloom = 0.35, Stars = 0, Fx = "snow" },
		{ Clock = 12, Brightness = 1.9, Ambient = "#053E74", Outdoor = "#2E669B", Sun = "#F1FBFE",
			AtmColor = "#84D9FD", AtmDecay = "#054480", Density = 0.42, Haze = 2.2, Glare = 0.2, Offset = 0.18,
			Tint = "#A3DBF7", TintMix = 0.35, Saturation = 0.1, Contrast = 0.08, Bloom = 0.7, Stars = 0, Fx = "motes" },
		{ Clock = 17.3, Brightness = 3, Ambient = "#4B2A24", Outdoor = "#6F4231", Sun = "#E2A475",
			AtmColor = "#A97F71", AtmDecay = "#41373D", Density = 0.45, Haze = 2.6, Glare = 0.5, Offset = 0.15,
			Tint = "#F6BE86", TintMix = 0.4, Saturation = 0.15, Contrast = 0.1, Bloom = 0.6, Stars = 0, Fx = "embers" },
		{ Clock = 13, Brightness = 0.6, Ambient = "#295593", Outdoor = "#B5ECFD", Sun = "#B5ECFD",
			AtmColor = "#295593", AtmDecay = "#132765", Density = 0.25, Haze = 1, Glare = 0, Offset = 0.25,
			Tint = "#B5ECFD", TintMix = 0.15, Saturation = -0.2, Contrast = 0.25, Bloom = 1.1, Stars = 3000, Fx = "wind",
			-- skybox from z4 sky_zenith/sky_mid/sky_low (art/tools/make_sky.py; private uploads, M6)
			Skybox = { Side = "rbxassetid://107253105174203", Up = "rbxassetid://133457787937137", Down = "rbxassetid://75604857964706" } },
	},

	-- Effects anchored on SS_Markers (generated with the Blender build). Colours are LOOKDEV tokens.
	Fx = {
		ShaftColor = "#F1FBFE", ShaftTransparency = 0.9, ShaftSize = Vector3.new(16, 240, 16), -- Z2 light shafts
		ShaftFadeNear = 30, ShaftFadeFar = 90, -- studs from the camera: shafts fade out up close (no slab look)
		SteamColor = "#F3C49D", -- Z3 vents and plumes
		LavaLightColor = "#F46E1E", LavaLightRange = 34, LavaLights = 14,
		CrystalLightColor = "#3F91F6", CrystalLightRange = 50, CrystalLights = 16,
		AuroraColors = { "#41D4A2", "#51E6B3", "#A469F4" }, -- Z4 sky curtains: green -> teal -> purple
		-- Aurora sky layer, relative to the camera (studs; keep every point < ~2000 from it or beams cull):
		-- curtains of vertical rays stacked up and away up the mountain (-Z)
		AuroraCurtains = 3, AuroraRays = 46, AuroraSpan = 1150, AuroraHeight = 280, AuroraDistance = 900,
		AuroraStep = Vector3.new(0, 150, 220), AuroraRayHeight = 460, AuroraRayWidth = 46,
		AuroraBrightness = 1.4, AuroraOpacity = 0.55,
		AuroraPurpleFrom = 0.6, -- ray fraction where aurora_purple takes over (left side)
		AuroraPurpleSide = { 0.45, 0.8 }, -- span fraction (left 0 -> right 1) over which the rays turn purple
		AuroraTopOpacity = 0.6, -- opacity of the ray tops (x AuroraOpacity)
		SnowColor = "#E9EAF0", MoteColor = "#F1FBFE", EmberColors = { "#FDB844", "#F46E1E" }, WindColor = "#8195DA",
		WeatherRate = { snow = 40, motes = 18, embers = 26, wind = 90 },
	},
}
