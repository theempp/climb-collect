-- Stampede Spire grey-box tunables (ReplicatedStorage.SS_Config). All feel numbers live here.
-- Placeholder colours are sampled from the approved r2 zone sheets (concepts/2026-10-29/r2-*.png).
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

return {
	-- Mountain: zones (= sections, P1: 10 of them, one biome each, prototype/SECTIONS-PLAN.md) in climb order.
	-- Length = studs along the slope; the mountain is their sum. Sections are sized by ride time: Speed =
	-- 22 x (78/22)^((k-1)/9) studs/s, Time = target seconds at a tier-1 mount, Length ~ Speed x Time.
	-- LaneWidth narrows per zone; the change ramps in over NarrowRamp studs before each border.
	-- Ground = sheet header sample.
	-- Tagline = the zone sheet's header line (shown on the zone title card). TitleStroke = the zone's darkest
	-- LOOKDEV token (z1 pine_dark, z2 ice_deep, z3 spire_dark, z4 night_deep): the outline that keeps a light
	-- title readable on a bright sky (M6). Accent = horn/antler tint
	-- for that zone's placeholder creatures (LOOKDEV token). art/tools/sspath.py reads Length/SlopeDeg/LaneWidth.
	Zones = {
		{ Name = "Frozen Taiga Foothills", Length = 880, SlopeDeg = 9, LaneWidth = 12, Speed = 22, Time = 40, Herd = 8, Ground = rgb(217, 223, 234), Tagline = "BOREAL FOREST / SNOWFIELDS / WIDE LANES / MORNING LIGHT", TitleStroke = "#2E3C4E", TitleColor = "#E9EAF0", Accent = "#E9EAF0", AccentGlow = false },
		{ Name = "Rime Fog Forest", Length = 1010, SlopeDeg = 10, LaneWidth = 11.5, Speed = 25.3, Time = 40, Herd = 7, Ground = rgb(207, 217, 236), Tagline = "FROZEN FOG. SILENT TREES. FOLLOW THE HERD.", TitleStroke = "#384F61", TitleColor = "#BBDFF4", Accent = "#E4F1FA", AccentGlow = false }, -- s2.snow_mid / title_shadow / title_fill / stag_antler
		{ Name = "Crevasse Ice Canyons", Length = 1170, SlopeDeg = 11, LaneWidth = 11, Speed = 29.1, Time = 40, Herd = 6, Ground = rgb(67, 157, 221), Tagline = "TOWERING ICE WALLS. NARROW LANES. NEW HORIZONS.", TitleStroke = "#054480", TitleColor = "#A3DBF7", Accent = "#A3DBF7", AccentGlow = false },
		{ Name = "Ice Cave Labyrinth", Length = 1340, SlopeDeg = 13, LaneWidth = 10, Speed = 33.5, Time = 40, Herd = 6, Ground = rgb(36, 151, 220), Tagline = "GLOWING TUNNELS. HIDDEN PATHS. NO WAY BUT UP.", TitleStroke = "#032C4E", TitleColor = "#E5FAFD", Accent = "#40D6FA", AccentGlow = true }, -- s4.floor_mid / title_shadow / title_fill / elk_antler
		{ Name = "Hot Spring Terraces", Length = 1540, SlopeDeg = 14, LaneWidth = 9.5, Speed = 38.6, Time = 40, Herd = 6, Ground = rgb(240, 234, 227), Tagline = "WARM STEAM. COLD AIR. KEEP CLIMBING.", TitleStroke = "#082743", TitleColor = "#C8F0FD", Accent = "#D6924A", AccentGlow = false }, -- s5.travertine / title_shadow / title_fill / goat_horn
		{ Name = "Geothermal Obsidian Ridge", Length = 1780, SlopeDeg = 15, LaneWidth = 8.5, Speed = 44.4, Time = 40, Herd = 6, Ground = rgb(129, 91, 79), Tagline = "HOTTER GROUND / HIGHER RISKS / STRONGER CREATURES", TitleStroke = "#0F090C", TitleColor = "#F46E1E", Accent = "#F46E1E", AccentGlow = true },
		{ Name = "Storm Peaks", Length = 2050, SlopeDeg = 16, LaneWidth = 8, Speed = 51.2, Time = 40, Herd = 6, Ground = rgb(96, 116, 195), Tagline = "DARK SKIES. BRIGHT STRIKES. RIDE THROUGH IT.", TitleStroke = "#0E2446", TitleColor = "#D8F5FD", Accent = "#9A92F9", AccentGlow = true }, -- s7.snow_mid / title_shadow / title_fill / rhino_horn
		{ Name = "Wind-Carved Spires", Length = 2360, SlopeDeg = 17, LaneWidth = 7.5, Speed = 58.9, Time = 40, Herd = 6, Ground = rgb(202, 206, 220), Tagline = "SCULPTED STONE. HOWLING GUSTS. HOLD ON.", TitleStroke = "#214778", TitleColor = "#C3EBFD", Accent = "#504C4D", AccentGlow = false, Glow = "#C3EBFD" }, -- s8.snow_mid / title_shadow / title_fill / markhor_horn; Glow = s8.title_fill (owner, P4: the dark horn Accent made the glow a dark pulse)
		{ Name = "Cloud Sea Ridge", Length = 2710, SlopeDeg = 19, LaneWidth = 7, Speed = 67.8, Time = 40, Herd = 5, Ground = rgb(254, 247, 213), Tagline = "ABOVE THE CLOUDS. THIN AIR. ALMOST THERE.", TitleStroke = "#4F79AF", TitleColor = "#BEF1FD", Accent = "#F5CE96", AccentGlow = true }, -- s9.snow_lit / title_shadow / title_fill / deer_antler
		{ Name = "Aurora Crown", Length = 3120, SlopeDeg = 20, LaneWidth = 6.5, Speed = 78, Time = 40, Herd = 5, Ground = rgb(18, 37, 86), Tagline = "MOUNTAIN PEAK", TitleStroke = "#04132F", TitleColor = "#B5ECFD", Accent = "#3F91F6", AccentGlow = true },
	},
	NarrowRamp = 40,
	LaneCount = 5,
	SlopeBlend = 80, -- studs: the slope eases from one zone's angle to the next, centred on each border
	SummitFlat = 40, -- studs past the top over which the slope eases to the flat summit plateau
	-- Plan-view bends (milestone 5): the path's heading turns by Deg over Len studs centred on At
	-- (smoothstep, so no kinks). The mountain is built straight and warped along this curve (SS_Path.warp,
	-- art/tools/sspath.py warp): lanes, herd, collision, walls and art all follow it. Keep the tightest
	-- radius (Len / (1.5 * rad(|Deg|))) above ~1,400 studs so the +-950 terrain and its skirts never fold.
	-- P1: 6 bends over the 10 sections (heading stays within +-8 deg; tightest radius ~2,600).
	Bends = {
		{ At = 1700, Len = 900, Deg = 8 },
		{ At = 4400, Len = 1100, Deg = -16 },
		{ At = 7100, Len = 1100, Deg = 14 },
		{ At = 10000, Len = 1100, Deg = -14 },
		{ At = 12700, Len = 1100, Deg = 14 },
		{ At = 15500, Len = 1000, Deg = -6 },
	},

	-- Herd species per zone (index = zone). Size = placeholder body block (studs), relative to the
	-- avatar on each sheet. Speed = species tier relative to its zone (sheet "speed tier").
	-- Color = body sample from the sheet. Saiga and Ashmane come from r2-replacements.
	-- Model = skinned creature in ReplicatedStorage.SS_Creatures (M8, art/creatures); its mesh size replaces Size.
	-- M8 part 3 (owner playtest): Speed tiers vary per species (fast ones run past you, slow ones lag).
	-- Weight = spawn odds (default 1). Big + Rare = a large rare runner; Fly = a rideable flyer gliding Fly studs
	-- above its lane (greybox wings). Score = points per stud ridden (default 1). The 5 Rare flyers live only in
	-- the old zones 3-4 (now sections 6 and 10). New species are greybox; their colours are LOOKDEV tokens (hex in
	-- the comment). P1: index = section (1 Taiga, 3 Crevasse, 6 Obsidian, 10 Aurora; the rest are r3 biomes).
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
		-- Sections 2, 4, 5, 7, 8, 9: greybox species from the r3 sheets (sheet order). Colours are r3 LOOKDEV body
		-- tokens; Size and Speed are judgement values against the sheet avatar (each sheet gives one speed label).
		{ -- S2 Rime Fog Forest
			{ Name = "Rime Stag", Size = Vector3.new(4, 5, 9.5), Speed = 1, Color = rgb(141, 140, 145) }, -- s2.stag #8D8C91
			{ Name = "Mistwool Llama", Size = Vector3.new(3.5, 4.5, 9), Speed = 0.9, Color = rgb(165, 170, 190) }, -- s2.llama #A5AABE
			{ Name = "Hoarfrost Wolf", Size = Vector3.new(4, 5, 9.5), Speed = 1.15, Color = rgb(144, 150, 166) }, -- s2.wolf #9096A6
			{ Name = "Birchback Bison", Size = Vector3.new(5.5, 5.5, 10.5), Speed = 0.75, Color = rgb(135, 136, 148) }, -- s2.bison #878894
			{ Name = "Fogtail Fox", Size = Vector3.new(3, 3.5, 8), Speed = 1.3, Color = rgb(171, 177, 199) }, -- s2.fox #ABB1C7
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
		{ -- S4 Ice Cave Labyrinth
			{ Name = "Lumen Elk", Size = Vector3.new(4, 5, 9.5), Speed = 1.05, Color = rgb(108, 165, 197) }, -- s4.elk #6CA5C5
			{ Name = "Cave Frost Bear", Size = Vector3.new(5.5, 5.5, 10), Speed = 0.8, Color = rgb(65, 109, 156) }, -- s4.bear #416D9C
			{ Name = "Shardback Armadillo", Size = Vector3.new(5, 4.5, 9.5), Speed = 0.75, Color = rgb(47, 81, 119) }, -- s4.armadillo #2F5177
			{ Name = "Glowtail Lynx", Size = Vector3.new(3, 4, 8), Speed = 1.4, Color = rgb(88, 134, 172) }, -- s4.lynx #5886AC
			{ Name = "Drip-Ice Tapir", Size = Vector3.new(4.5, 5, 9.5), Speed = 0.95, Color = rgb(70, 110, 150) }, -- s4.tapir #466E96
		},
		{ -- S5 Hot Spring Terraces
			{ Name = "Steam Buffalo", Size = Vector3.new(5.5, 5.5, 10), Speed = 0.8, Color = rgb(135, 121, 112) }, -- s5.buffalo #877970
			{ Name = "Onsen Capybara", Size = Vector3.new(4.5, 4.5, 9), Speed = 0.85, Color = rgb(144, 113, 96) }, -- s5.capybara #907160
			{ Name = "Geyser Goat", Size = Vector3.new(3.5, 4.5, 8.5), Speed = 1.2, Color = rgb(182, 171, 160) }, -- s5.goat #B6ABA0
			{ Name = "Travertine Antelope", Size = Vector3.new(3, 4.5, 8.5), Speed = 1.4, Color = rgb(196, 172, 149) }, -- s5.antelope #C4AC95
			{ Name = "Sulfur Boar", Size = Vector3.new(4.5, 4, 9), Speed = 0.85, Color = rgb(201, 160, 110) }, -- s5.boar #C9A06E
		},
		{
			{ Name = "Ember Yak", Size = Vector3.new(5.5, 5, 9.5), Speed = 1, Color = rgb(30, 15, 11) },
			{ Name = "Basalt Rhino-Goat", Size = Vector3.new(5, 4.5, 9), Speed = 0.8, Color = rgb(76, 61, 58) },
			{ Name = "Steam Bison", Size = Vector3.new(5.5, 5.5, 10), Speed = 0.75, Color = rgb(29, 28, 28) },
			{ Name = "Obsidian Gazelle", Size = Vector3.new(3, 4, 8), Speed = 1.5, Color = rgb(50, 38, 37) },
			{ Name = "Ashmane Wild Horse", Size = Vector3.new(4, 5, 10), Speed = 1.2, Color = rgb(98, 83, 76) },
			{ Name = "Magma Behemoth", Size = Vector3.new(8, 8, 15), Speed = 1.2, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(43, 21, 22) }, -- #2B1516
			{ Name = "Ash Roc", Size = Vector3.new(3.5, 2.5, 6), Speed = 1.35, Fly = 16, Weight = 0.5, Color = rgb(113, 52, 33) }, -- #713421
			{ Name = "Cinder Wyvern", Size = Vector3.new(6, 3.5, 12), Speed = 1.6, Fly = 18, Rare = true, Weight = 0.05, Score = 5, Color = rgb(244, 110, 30) }, -- #F46E1E
			{ Name = "Lava Drake", Size = Vector3.new(6, 3.5, 12), Speed = 1.6, Fly = 18, Rare = true, Weight = 0.05, Score = 5, Color = rgb(155, 38, 15) }, -- #9B260F
		},
		{ -- S7 Storm Peaks
			{ Name = "Thunder Yak", Size = Vector3.new(5.5, 5.5, 10), Speed = 0.8, Color = rgb(62, 71, 127) }, -- s7.yak #3E477F
			{ Name = "Stormmane Stallion", Size = Vector3.new(3.5, 4.5, 10), Speed = 1.15, Color = rgb(117, 124, 153) }, -- s7.stallion #757C99
			{ Name = "Stormcrest Gazelle", Size = Vector3.new(3, 4, 8.5), Speed = 1.4, Color = rgb(152, 164, 208) }, -- s7.gazelle #98A4D0
			{ Name = "Rumble Rhino", Size = Vector3.new(5.5, 5, 10), Speed = 0.75, Color = rgb(71, 92, 135) }, -- s7.rhino #475C87
			{ Name = "Static Wolf", Size = Vector3.new(3.5, 4.5, 9), Speed = 1.1, Color = rgb(104, 119, 182) }, -- s7.wolf #6877B6
		},
		{ -- S8 Wind-Carved Spires
			{ Name = "Windrunner Pronghorn", Size = Vector3.new(3, 4.5, 9), Speed = 1.4, Color = rgb(184, 138, 108) }, -- s8.pronghorn #B88A6C
			{ Name = "Spire Markhor", Size = Vector3.new(3.5, 4.5, 9), Speed = 0.95, Color = rgb(148, 139, 141) }, -- s8.markhor #948B8D
			{ Name = "Frostdune Camel", Size = Vector3.new(4.5, 5.5, 10), Speed = 0.75, Color = rgb(162, 133, 116) }, -- s8.camel #A28574
			{ Name = "Gale Snow Leopard", Size = Vector3.new(3, 4, 8.5), Speed = 1.2, Color = rgb(159, 175, 193) }, -- s8.leopard #9FAFC1
			{ Name = "Spirehorn Oryx", Size = Vector3.new(3.5, 4.5, 9.5), Speed = 0.95, Color = rgb(157, 139, 134) }, -- s8.oryx #9D8B86
		},
		{ -- S9 Cloud Sea Ridge
			{ Name = "Nimbus Ostrich", Size = Vector3.new(3, 5, 8), Speed = 1.35, Color = rgb(223, 224, 232) }, -- s9.ostrich #DFE0E8
			{ Name = "Cloudmane Horse", Size = Vector3.new(3.5, 4.5, 10), Speed = 1, Color = rgb(200, 202, 208) }, -- s9.horse #C8CAD0
			{ Name = "Halo Deer", Size = Vector3.new(3, 4.5, 9), Speed = 1.05, Color = rgb(222, 214, 199) }, -- s9.deer #DED6C7
			{ Name = "Skyfleece Sheep", Size = Vector3.new(5, 5, 9), Speed = 0.75, Color = rgb(184, 205, 233) }, -- s9.sheep #B8CDE9
			{ Name = "Mistwing Kudu", Size = Vector3.new(3.5, 4.5, 9.5), Speed = 1.15, Color = rgb(176, 185, 209) }, -- s9.kudu #B0B9D1
		},
		{
			{ Name = "Crystal Ram", Size = Vector3.new(4.5, 4.5, 8.5), Speed = 1.05, Color = rgb(114, 122, 143) },
			{ Name = "Skyhorn Antelope", Size = Vector3.new(3.5, 4.5, 8.5), Speed = 1.45, Color = rgb(181, 196, 218) },
			{ Name = "Aurora Hart", Size = Vector3.new(3.5, 4.5, 9), Speed = 1, Color = rgb(157, 178, 241) },
			{ Name = "Gale Kirin-Horse", Size = Vector3.new(3.5, 4.5, 9.5), Speed = 1.1, Color = rgb(116, 148, 228) },
			{ Name = "Starfrost Ox", Size = Vector3.new(6, 5.5, 10), Speed = 0.75, Color = rgb(34, 50, 87) },
			{ Name = "Crown Colossus Ram", Size = Vector3.new(8, 8, 14), Speed = 1.25, Big = true, Rare = true, Weight = 0.25, Score = 3, Color = rgb(61, 98, 178) }, -- #3D62B2
			{ Name = "Frost Swiftwing", Size = Vector3.new(3, 2, 5), Speed = 1.4, Fly = 16, Weight = 0.5, Color = rgb(181, 236, 253) }, -- #B5ECFD
			{ Name = "Aurora Dragon", Size = Vector3.new(7, 4, 14), Speed = 1.7, Fly = 20, Rare = true, Weight = 0.05, Score = 5, Color = rgb(65, 212, 162) }, -- #41D4A2
			{ Name = "Starwing Drake", Size = Vector3.new(6, 3.5, 12), Speed = 1.7, Fly = 20, Rare = true, Weight = 0.05, Score = 5, Color = rgb(164, 105, 244) }, -- #A469F4
			{ Name = "Crystal Phoenix", Size = Vector3.new(5, 3, 10), Speed = 1.8, Fly = 22, Rare = true, Weight = 0.05, Score = 5, Color = rgb(63, 145, 246) }, -- #3F91F6
		},
	},

	-- Herd speed (P1): each zone's Speed (Zones), eased in from the zone below over SpeedRamp studs, times the
	-- species tier.
	SpeedRamp = 40,
	SpeedJitter = 0.1, -- +/- fraction per creature, so lanes drift past each other
	-- Herd pool (P2; SS_Ride "Herd pool"): only biomes overlapping the window [rider - Behind, rider + Ahead]
	-- have live creatures (at most 2: every section is longer than the window), a quota of PerLane x LaneCount
	-- times the biome's share of the window. Each biome's creatures are built at load and parked: PerLane x
	-- LaneCount commons plus ExtraEach of every extra species; a zone's Rare (default 1) multiplies its extras'
	-- Weight. Out of view = outside RecycleClear behind .. RecycleAhead ahead of the rider (the camera looks up
	-- the slope); creatures only park and respawn there. Slow ones respawn ahead (the far FrontBand of the
	-- window first), faster ones behind (the rider's own biome only, from up to Behind below its start); a
	-- respawn fades in over FadeIn s. SpawnPerFrame caps respawns per biome per frame; Tries = random slot
	-- attempts per placement; a rider move over Jump studs in one frame (debug teleport, summit reset)
	-- re-lays the whole window at once. Creatures keep LaneGap studs nose-to-tail; a ridden one pushes ahead.
	-- ViewDist: respawns ahead start at least this far up (and the BOT counts any park / respawn on screen
	-- closer than this as seen).
	-- Herd fix (2026-10-29, prototype/HERD-SIM.md): a zone's Herd (default PerLane) replaces PerLane for its
	-- creature count and quota (denser low sections, where the herd is slow: 8 at the bottom .. 5 at the top;
	-- P4 pace (owner): s5-s10 5,5,5,5,4,4 -> 6,6,6,6,5,5, the upper road looked empty on the tour).
	-- Respawns ahead spread over the whole out-of-view band (ViewDist .. Ahead). Past its own biome
	-- an unridden creature tires: its tier eases down by TireRate x its tier per s to Tire x its tier, so it
	-- drops behind the rider and recycles there (no stragglers riding along through later sections). Tire 0.15,
	-- not 0.3: at 0.3 a straggler crossing just ahead of the rider was still in view 250 studs into the next
	-- section (sim, never-swapping rider, 12 seeds: worst native share there 0%; at 0.15: 67%, no-target unchanged).
	-- P4 fog measurement (TEST-LOG "P4 fog re-measure"; owner: readable = >= 4 px tall and >= 5% contrast on the
	-- 750x401 phone): Readable = per section, the distance from the camera where the most visible common species
	-- (real models, tier-1 ride FOV) can still be read. The Atmosphere only limits s2; elsewhere size does.
	-- Spawning ahead past Readable fails 10d (sim 6-14/16 runs), so (owner, P4) respawns ahead start at ViewDist
	-- (350; RecycleAhead the same) and fade in over FarFade s instead of FadeIn; a creature leaving ahead fades out
	-- as slowly. FarFade 2, not 3: at 3 s the slower fade-outs kept up to 62 live (10d cap 60) in 2/48 sim runs.
	-- BOT: nothing appears or vanishes inside ViewDist, and nothing fades in faster than FarFade inside Readable.
	-- Ahead 700 -> 500 (owner, P4: the lever for 10d) -> 420 (P4 re-review: once an over-quota excess fades out
	-- only its excess, not every out-of-view creature, 500 failed 2/48 sim runs; 420: 0/48, empty 0%, live <= 59).
	Pool = { Behind = 150, Ahead = 420, ViewDist = { 350, 350, 350, 350, 350, 350, 350, 350, 350, 350 },
		Readable = { 700, 600, 600, 600, 550, 550, 550, 550, 450, 500 }, FarFade = 2,
		PerLane = 5, ExtraEach = 2, SpawnPerFrame = 4,
		EagerZones = 2, BuildSliceMs = 4, -- load: only these first biomes' creatures are built before the ride; the rest are built in the background, BuildSliceMs of work a frame
		Tries = 8, Jump = 40, JumpQuiet = 1.5, FadeIn = 1, Tire = 0.15, TireRate = 0.5 }, -- Jump: riding moves <= 8
	-- studs a frame; BOT nudges are larger. JumpQuiet: s after a jump in which the BOT's on-screen count is off
	-- (the camera is catching up). RecycleClear 60: the ride camera sits ~24-45 studs behind the rider.
	RecycleAhead = { 350, 350, 350, 350, 350, 350, 350, 350, 350, 350 }, RecycleClear = 60, LaneGap = 14,
	PassRetry = 0.6, PassEase = 2.5, -- a blocked faster creature tries a free neighbour lane every PassRetry s; sideways ease rate
	SummitFade = 40, -- studs before the summit over which unridden creatures fade out (they recycle there)
	NameTagDistance = 70, -- studs; species tags are hidden beyond this
	-- In-range glow (owner, P4; replaces the untraced gold outline): Highlight fill + rim and a PointLight in the
	-- creature's section Glow token if it has one (s8: its pale title_fill), else its Accent. Fill transparency pulses FillMax..FillMin, light LightMin..LightMax, at
	-- Hz. Judgement values, reviewed at each sign-off like the D5 values.
	Glow = { Hz = 1.2, FillMin = 0.45, FillMax = 0.75, Outline = 0.15, LightMin = 0.8, LightMax = 2, LightRange = 12 },

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
		-- Coins + shop (P3, SS_Shop): the coin line sits under the score, the SHOP button under it (right side,
		-- off the lanes). The panel uses the current zone's TitleStroke (backing, at Timeline.Back) and TitleColor
		-- (outline, buttons) tokens, white GothamBold text like the hint. Sizes are px judgement values (sign-off).
		Shop = { Line = 22, Button = Vector2.new(84, 28), Width = 320, Row = 58, Pad = 10, Text = 18, Small = 14 },
		-- Herd Journal + medal toast (P4, SS_Journal): a JOURNAL button under SHOP; the panel shows one section
		-- per page (that section's TitleStroke backing / TitleColor outline and buttons, like the shop), its top
		-- just under the hint line, species in two columns. Medals
		-- are 1-3 pips in TitleColor (owner: no new colours). The toast sits under the buttons for Toast s.
		-- Sizes are px judgement values (sign-off).
		Journal = { Width = 360, Row = 22, Swatch = 14, Count = 34, Pip = 10, Toast = 2.5, ToastWidth = 240, ToastHeight = 30 },
		-- Perf card (SS_Perf, M7): shown at the summit under the hint line, like the Journal panel (same Width);
		-- 13 rows (title, header, 10 sections, memory footer) fit the 343 px GUI area of a 401 px phone. px judgement values.
		Perf = { Width = 360, Row = 18, Text = 12 },
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

	-- Progression (P3, owner 2026-10-29): every run starts at the bottom (join, summit, reset). A checkpoint
	-- (each section end) only lights its node and counts toward your best section. Score turns into coins
	-- as you ride (CoinPerScore) and coins save all the time; a summit is an ascent (+AscentBonus coins).
	-- The server (SS_Save / SS_Progress) checks the distance each client reports: a run is valid only if it
	-- starts within RunStartMax of the bottom and never moves faster than the fastest legit mount (speed x
	-- MaxSpd x (1 + SpeedJitter) + Leap.AirSpeed, x Slack), budgeted over Burst s for network jitter. A drop of
	-- more than NewRun studs (summit reset, respawn) starts a new run; a faceplant (FallDistance) does not.
	-- Accepted score per report <= forward studs x ScoreRate x the best species Score x ScoreSlack (banked up
	-- to ScoreBank studs), so rare mounts still pay. Store = DataStore name; Studio unpublished places fall
	-- back to an in-memory store. Saves every AutoSave s when something changed, and on leave / shutdown.
	Progress = {
		ReportEvery = 1, MinReportGap = 0.2, -- client report cadence; the server ignores reports closer than this
		RestartGap = 3, -- s: the client's spawn report (d <= 0, flagged) may skip MinReportGap once per RestartGap
		CoinPerScore = 0.01, AscentBonus = 100,
		RunStartMax = 300, NewRun = 200, Slack = 1.2, Burst = 2, ScoreSlack = 1.05, ScoreBank = 400,
		Store = "SS_Progress_v1", AutoSave = 60, Retries = 3,
	},
	-- Section medals (owner, P4): by section time on a valid run (server-timed from the reports, crossing times
	-- interpolated). GOLD <= Gold s, SILVER <= Silver s, BRONZE = finished. Every section's Time is 40 s at tier 1;
	-- fast mounts and flyers ride a section in ~26-30 s (sim). Score medals wait for M9 (sections 2, 4, 5, 7, 8, 9
	-- have commons only). RiddenMax caps a species' ridden count in the Herd Journal; a ridden report counts if its
	-- d is within RiddenNear studs of the run's next reported d (1 s of the fastest mount is ~140).
	Medals = { Gold = 30, Silver = 40, Names = { "BRONZE", "SILVER", "GOLD" }, RiddenMax = 9999, RiddenNear = 300 },
	-- Server rider feed (SS_Stream, STREAMING-PLAN section 2 / Q3). The client sends its d FeedHz times a second;
	-- the server's focus part follows it (Player.ReplicationFocus) and every PrefetchEvery s streams in the ground
	-- Lead s ahead (speed measured from the feed, capped at MaxSpeed; a move over JumpStuds is a jump, not a
	-- speed; SpeedSmooth = share of each new sample, from the client's clock). Prepare(d) before a jump waits up to
	-- PrepareTimeout s. Margin: studs past either end of the path.
	-- Provisional until M7 (STREAMING-PLAN section 4).
	Stream = { FeedHz = 4, Lead = 6, PrefetchEvery = 1.5, PrefetchTimeout = 2, PrepareTimeout = 5, MaxSpeed = 200, SpeedSmooth = 0.5,
		RespawnHold = 1, -- s after a respawn in which feeds far from the spawn (in flight from the old life) are ignored
		JumpStuds = 200, Margin = 60 },
	-- Per-section perf recorder (SS_Perf, M7-CHECKLIST "Record"): FPS avg / 1% low / worst frame per section, memory
	-- + tags, live creatures and parts every MemEvery s; PERFREC lines and a card at the summit. On for the M7
	-- phone run; set Enabled false after M7.
	Perf = { Enabled = true, MemEvery = 1 },
	-- Upgrades (P3): Cost[n] buys level n. Ring widens SuccessWindow by Window per level; Stance shortens
	-- StanceTime by Time and lowers WobbleAmp by Wobble per level. Prices x2 (owner, P4): a full run earns ~280 coins
	-- at tier 1 (~6.5 min; 350-630 on fast mounts / rares, sim), so the first upgrade comes after run 1 and the whole
	-- shop (6,620) after ~24 runs (~2.6 h). CoinPerScore 0.01 unchanged.
	Upgrades = {
		{ Id = "Ring", Name = "Wider ring", Info = "Bigger timing window", Max = 5, Cost = { 100, 240, 500, 1000, 1800 }, Window = 0.04 },
		{ Id = "Stance", Name = "Steady stance", Info = "Stand up faster, less wobble", Max = 5, Cost = { 80, 200, 400, 800, 1500 }, Time = 0.08, Wobble = 2 },
	},

	-- Art pass (milestone 3) -----------------------------------------------------------------------
	-- The visible mountain is Workspace.SS_Mountain (Blender meshes built by art/tools/build_mountain.py).
	-- SS_Track only lays invisible collision along the path; ShowGreybox re-shows the old lane strip.
	ShowGreybox = true, -- P1 pace test (StampedeSpire.Sections.rbxl): the old 4-zone art is parked, marker FX off
	CollisionStep = 20, -- studs per hidden collision slab along the path
	CollisionPad = 6, -- studs of walkable berm beyond the outer lanes (matches the mesh berm)
	WallHeight = 14, -- invisible side walls that keep a dismounted rider on the track

	-- Placeholder creatures: blocky body/legs/head/horns with a gallop cycle (still not final art)
	GallopPerStud = 0.32, -- leg-cycle radians per stud travelled
	GallopClip = 0.8, -- seconds per stride in the skinned gallop clip (24 frames at 30 fps, art/creatures)
	-- [model] = { gallop = "rbxassetid://..." }: uploaded private Animation assets (owner account, 2026-10-30). A model without
	-- one runs as a rigid bob in a published client; Studio registers local clips instead.
	ClipAssets = {
		taiga_elk = { gallop = "rbxassetid://133688782933288" },
		woolly_reindeer = { gallop = "rbxassetid://72537654229111" },
		musk_ox_calfrunner = { gallop = "rbxassetid://82163452524648" },
		snowshoe_hare_hound = { gallop = "rbxassetid://128318368515536" },
		pine_boar = { gallop = "rbxassetid://70586627577149" },
	},
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
	-- Loading card (SS_Loading). Colours are zone 1's TitleStroke / TitleColor, text is zone 1's Tagline; the fade is TitleFade.
	-- Layout values are fractions of the screen (not design tokens); the name is the working title (owner to confirm).
	Loading = { Name = "STAMPEDE SPIRE", Timeout = 20, MinShow = 0.8, ErrHold = 2.5, DisplayOrder = 1000,
		TextWidth = 0.7, NameY = 0.34, NameH = 0.14, TagY = 0.5, TagH = 0.05, ErrY = 0.7, ErrH = 0.05,
		BarY = 0.6, BarWidth = 0.4, BarHeight = 6, TrackTransparency = 0.8, BarTween = 0.15 },
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
		-- Sections 2, 4, 5, 7, 8, 9 (r3 sheets): colours are r3 LOOKDEV tokens; the numbers are judgement values
		-- read from each sheet (reviewed at that biome's sign-off, like D5). Fx: closest existing weather type.
		{ Clock = 10, Brightness = 1.6, Ambient = "#323D4F", Outdoor = "#63768B", Sun = "#EBF1FA", -- s2: fog glow, no sun disk
			AtmColor = "#BFCCE0", AtmDecay = "#C0CDE2", Density = 0.45, Haze = 2.6, Glare = 0, Offset = 0.25,
			Tint = "#E2E9F5", TintMix = 0.3, Saturation = -0.2, Contrast = 0.06, Bloom = 0.5, Stars = 0, Fx = "motes" }, -- later: fog banks
		{ Clock = 12, Brightness = 1.9, Ambient = "#053E74", Outdoor = "#2E669B", Sun = "#F1FBFE",
			AtmColor = "#84D9FD", AtmDecay = "#054480", Density = 0.42, Haze = 2.2, Glare = 0.2, Offset = 0.18,
			Tint = "#A3DBF7", TintMix = 0.35, Saturation = 0.1, Contrast = 0.08, Bloom = 0.7, Stars = 0, Fx = "motes" },
		{ Clock = 12, Brightness = 1.2, Ambient = "#022959", Outdoor = "#0B6DA8", Sun = "#B6F4FD", -- s4: light through the cave mouth
			AtmColor = "#5DCEFB", AtmDecay = "#011F3C", Density = 0.4, Haze = 2, Glare = 0, Offset = 0.2,
			Tint = "#B6F4FD", TintMix = 0.35, Saturation = 0.15, Contrast = 0.15, Bloom = 1, Stars = 0, Fx = "motes" }, -- later: crystal/moss glow lights
		{ Clock = 11.5, Brightness = 2.4, Ambient = "#112637", Outdoor = "#8EACD4", Sun = "#FEFEFD", -- s5: high sun veiled by steam
			AtmColor = "#D5D1D1", AtmDecay = "#90BDE8", Density = 0.35, Haze = 1.8, Glare = 0.4, Offset = 0.15,
			Tint = "#F0EAE3", TintMix = 0.5, Saturation = 0.1, Contrast = 0.08, Bloom = 0.6, Stars = 0, Fx = "motes" }, -- later: pool steam plumes
		{ Clock = 17.3, Brightness = 3, Ambient = "#4B2A24", Outdoor = "#6F4231", Sun = "#E2A475",
			AtmColor = "#A97F71", AtmDecay = "#41373D", Density = 0.45, Haze = 2.6, Glare = 0.5, Offset = 0.15,
			Tint = "#F6BE86", TintMix = 0.4, Saturation = 0.15, Contrast = 0.1, Bloom = 0.6, Stars = 0, Fx = "embers" },
		{ Clock = 13, Brightness = 0.8, Ambient = "#1C2A5A", Outdoor = "#586AAD", Sun = "#C1BAFB", -- s7: storm-dark, day clock
			AtmColor = "#3D4D9B", AtmDecay = "#192B5D", Density = 0.4, Haze = 2, Glare = 0.1, Offset = 0.2,
			Tint = "#C1BAFB", TintMix = 0.25, Saturation = 0, Contrast = 0.2, Bloom = 0.9, Stars = 0, Fx = "wind" }, -- later: lightning
		{ Clock = 14, Brightness = 2.6, Ambient = "#572F30", Outdoor = "#989BAE", Sun = "#F5F1F1", -- s8: clear high-sun day
			AtmColor = "#9ECFF6", AtmDecay = "#4597E3", Density = 0.28, Haze = 1.2, Glare = 0.4, Offset = 0.12,
			Tint = "#F5F1F1", TintMix = 1, Saturation = 0.15, Contrast = 0.1, Bloom = 0.4, Stars = 0, Fx = "wind" },
		{ Clock = 17.5, Brightness = 2.4, Ambient = "#4E4745", Outdoor = "#A6A0BB", Sun = "#FEFADA", -- s9: low golden sun
			AtmColor = "#FED2A9", AtmDecay = "#B3AFC2", Density = 0.3, Haze = 1.6, Glare = 0.5, Offset = 0.12,
			Tint = "#FDDAC4", TintMix = 0.4, Saturation = 0.1, Contrast = 0.08, Bloom = 0.8, Stars = 0, Fx = "motes" }, -- later: cloud-sea layer
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
