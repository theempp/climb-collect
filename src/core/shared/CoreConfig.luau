-- CoreConfig (ReplicatedStorage.CC_Core): every core-loop number in one place.
-- LOCKED = user answer (design/core-loop-plan.md, master.md Â§0.7); PROPOSED = brief Â§3 default or a Run 1 choice
-- (logged in design/decision-log.md); ESTIMATE = not measured. Shared by server and client (no secrets here).
local C = {}

-- Rarity (LOCKED: 5 tiers; yield/h; duplicate 25%; mutation +50%)
C.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
C.RANK = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
C.YIELD_PER_HOUR = { Common = 1, Uncommon = 3, Rare = 10, Epic = 35, Legendary = 150 }
C.DUPLICATE_YIELD = 0.25
C.MUTATION_BONUS = 0.5
-- Rarity tint is secondary to pips/border (LOCKED); tints are existing world tokens (PROPOSED mapping).
C.RARITY_TINT = {
	Common = Color3.fromRGB(220, 230, 255), -- moonlight
	Uncommon = Color3.fromRGB(84, 176, 82), -- meadowEmerald
	Rare = Color3.fromRGB(92, 184, 245), -- skyBlue
	Epic = Color3.fromRGB(138, 78, 255), -- electricViolet
	Legendary = Color3.fromRGB(255, 214, 150), -- goldenDaylight
}

-- Progression (PROPOSED, B-polish 2026-10-20): XP on bank, first-of-species x1.5 (floored), cumulative XP to reach
-- L1..L9. Was 10/25/80/250/1000 with x2, which ended the tutorial at L4 (Epic pup alone = 500 XP). Now the tutorial
-- (common + Rare + pup + two outskirts finds) ends at L2 with ~25 XP to spare before L3 (user: "must not end at L4").
C.XP_ON_BANK = { Common = 10, Uncommon = 20, Rare = 40, Epic = 80, Legendary = 300 }
C.FIRST_OF_SPECIES_XP = 1.5
-- The tutorial Rare (guardian-free nook) can't be shaken loose by a guardian or a fall until it has been banked once
-- (user review 2026-10-20, "Protect it"). Matched by the item's spawn source.
C.TUTORIAL_RARE_SOURCE = "nook_rare_r1"
-- Tutorial beat 9 (after the Heartstone is banked): claim two finds on the Foothold outskirts while it ripens.
C.TUT_OUTSKIRTS = { "out_3", "out_1", "out_2", "shep_1" }
C.TUT_OUTSKIRTS_TIMEOUT = 150 -- s: shared commons may be taken by others; the beat never blocks the tutorial
C.LEVEL_XP = { 0, 100, 250, 500, 900, 1500, 2400, 3800, 6000 }
-- Backpack (LOCKED: 4 -> 12; L2-7 +1 each; two major codex milestones +1 each; L8-9 stamina only)
C.SLOTS_BASE = 4
C.SLOTS_MAX = 12
C.SLOT_LEVELS = { 2, 3, 4, 5, 6, 7 }
C.SLOT_MILESTONES = { 10, 25 } -- distinct species in the codex (PROPOSED thresholds)
-- Coins on bank (PROPOSED: equal to the rarity's LOCKED yield/h; real economy is tuned in Phase D/G)
C.COINS_ON_BANK = C.YIELD_PER_HOUR

-- Heartstone (LOCKED: 2 slots, ripen Common 5 min / Rare 30 min / Legendary 4 h)
C.HEARTSTONE_SLOTS = 2
C.HEARTSTONE_TIERS = { "Common", "Rare", "Legendary" }
C.RIPEN_SECONDS = { Common = 300, Rare = 1800, Legendary = 14400 }
-- What a ripe Heartstone becomes (PROPOSED): rarity weights by tier, species from the nest's region.
C.HATCH_WEIGHTS = {
	Common = { Common = 70, Uncommon = 30 },
	Rare = { Rare = 100 },
	Legendary = { Legendary = 100 },
}
C.HEARTSTONE_VALUE = { Common = 30, Rare = 60, Legendary = 100 } -- shake order: above any carried creature

-- Claims (PROPOSED): hold seconds by rarity; Heartstone hold 3 s (brief Â§3.4), longer by tier
C.HOLD_SECONDS = { Common = 1.0, Uncommon = 1.5, Rare = 2.0, Epic = 2.0, Legendary = 3.0 }
C.HEARTSTONE_HOLD = { Common = 3.0, Rare = 4.0, Legendary = 5.0 }
C.CLAIM_RANGE = 10 -- prompt MaxActivationDistance (studs)
C.HOLD_TOLERANCE = 0.3 -- seconds of network slack accepted on a hold
-- Net (LOCKED: 3 tiers set throw range and interaction time only; cloth free). Numbers PROPOSED.
C.NET_TIERS = {
	cloth = { order = 1, range = 18, hold = 1.5 },
	rope = { order = 2, range = 24, hold = 1.2, level = 4 },
	aurora = { order = 3, range = 30, hold = 1.0 },
}
C.PUP_COOLDOWN = 600 -- one pup per guardian per cooldown (LOCKED rule, 10 min PROPOSED = nest respawn)

-- Legacy tuning retained for guardian pace; NOT the active bank movement validator.
-- Traversal / CheckpointService validate physical bank travel and shared movement policy.
C.WALK_SPEED = 12
C.TRAVEL_SLACK = 1.5

-- Risk (LOCKED: drop pack 3 min; hit = stagger + one unbanked item; no shake in R1 before first bank)
C.DROP_PACK_SECONDS = 180
C.STAGGER_SECONDS = 1.2 -- brief Â§3.3
C.STAGGER_IMMUNE = 2.0
C.FALL_SHAKES = 1 -- items moved to the drop pack per accepted fall (PROPOSED; partial loss)

-- Nests + guardians (brief Â§3.3/Â§3.4; PROPOSED within the brief's ranges; R1 = gentle)
C.NEST_RESPAWN = 600
C.GUARDIAN = {
	tell = 1.6, -- Alert tell >= 1.5 s
	loseYou = 3.0, -- search time before retreat
	leash = 110, -- max distance from its nest
	reach = 3.5, -- hit distance added to its half size
	region = { -- speed as a fraction of WalkSpeed 12, sense range in studs, size factor
		[1] = { speed = { 0.55, 0.7 }, sense = { 25, 34 }, size = { 0.8, 1.0 }, weakness = { "height" } },
	},
	tierStep = 0.10, -- +10% sense/speed per nest value tier (and per region step)
	maxSpeed = 1.15, -- never faster than 1.15x run speed (fairness)
}

-- Camps (LOCKED: tents are guardian-free; small safe radius; locker 1 -> 3 by tent tier)
C.CAMP_SAFE_RADIUS = { 46, 52, 58 } -- by tent tier (PROPOSED)
C.FOOTHOLD_SAFE = { center = Vector3.new(0, 48, 2160), radius = 330 } -- whole Foothold pad + amphitheater
C.LOCKER_SLOTS = { 1, 2, 3 } -- by tent tier
C.RESUME_CAMPS = { "Camp1", "Camp2", "Camp3", "Camp4" }

-- Persistence (brief Â§3.9: autosave 60 s + on leave, retry with backoff, session lock)
C.PERSIST = {
	dataStore = "CC_Profiles_v1",
	keyPrefix = "p_",
	autosave = 60,
	lockTTL = 240, -- a lock older than this (no autosave refresh) is considered dead
	loadTries = 6,
	lockWait = 5,
	saveTries = 4,
	txKeep = 32,
	maxBytes = 3500000,
}

C.REGIONS = { "GreenValley", "WhisperingForest", "BrokenCliffs", "StormRidge", "FrozenSummit" }

-- v4 climb state (LOCKED: marked faces, stamina, auto-grab, Jump = lunge, slide + catch window, fall -> last
-- checkpoint; numbers PROPOSED, v4-climb-concept Â§3: ~25-35 s per bar, refill ~5-8 s, catch ~1.5-2 s)
C.CLIMB = {
	speed = 7, -- studs/s on a face (walk is 12)
	grabDist = 2.6, -- auto-grab when pushed into a marked face within this distance of the root
	holdDist = 1.55, -- root distance kept from the face while climbing
	lungeDist = 8, -- Jump on a face = lunge this far in the stick direction (up when idle)
	lungeTime = 0.32,
	lungeCost = 12,
	stamina = 100,
	drainMove = 3.3, -- ~30 s of continuous climbing per bar
	drainHold = 1.4,
	regenGround = 12.5, -- full in 8 s on any ground
	regenRest = 25, -- full in 4 s on a rest ledge (parts with RestLedge = true)
	catchWindow = 1.75, -- seconds to re-grab after a slip
	catchStamina = 15, -- a caught slip leaves this much grip (one catch per slip)
	slideSpeed = 14,
	releaseCooldown = 0.45,
	fov = 80, -- camera FOV while on a face (auto-frame; the player can still orbit)
	cameraOffset = Vector3.new(0, -1.2, 3.2), -- character space: out from the face and a little down
	steepNormalY = 0.66, -- no jumping while standing on ground steeper than ~49 deg (jump-spam would climb any slope)
	-- v4 P3 (run 2): marked faces can also be terrain of this material (used nowhere else in the terrain), so pitch
	-- stacks cost no instances; ledges on rest spots are terrain too, so rest is by a RestZone part/attribute
	terrainMaterial = Enum.Material.Asphalt,
	descendGrab = 0.7, -- s after walking off an edge in which a marked face behind/below is auto-grabbed (two-way lines)
 -- Surface equipment multipliers are owned by TraversalConfig (no altitude survival rules).
 cramponDrain = 0.8,
 ropeDrain = 0.5,
}

-- v4 P4 (run 2): currencies + gear shop (user: "Both" currencies, "Mid 150-1,200" prices; items, prices and
-- unlock levels PROPOSED). Cairn Coins = existing coins (banking, yield). Summit Points = expedition currency:
-- camps and summits reached (first time per route pays more). Shop = cosmetics only (master.md Â§0.7: currency never
-- buys creatures or Heartstones; nothing sold gives a competitive claim advantage). Colors = world tokens.
C.POINTS = {
	camp = 10, -- each camp touch (once per camp per trip: a trip resets at the Foothold)
	summit = 60, -- reaching the Summit
	firstSummitRoute = 140, -- extra, the first summit by each route (Shepherd, Waterfall, Ledge, Spire)
}
C.SHOP = {
	{ id = "cap_trail", slot = "head", name = "Trail Cap", price = 150, cur = "coins", color = { 214, 150, 82 }, color2 = { 62, 66, 76 } }, -- sandstoneAmber / charcoalSlate
	{ id = "helm_climb", slot = "head", name = "Climber Helmet", price = 400, cur = "coins", color = { 255, 178, 72 }, color2 = { 62, 66, 76 } }, -- lanternGold
	{ id = "helm_storm", slot = "head", name = "Storm Helm", price = 900, cur = "points", color = { 46, 72, 122 }, color2 = { 62, 224, 255 } }, -- stormBlue / electricCyan
	{ id = "gog_glacier", slot = "eyes", name = "Glacier Goggles", price = 300, cur = "coins", color = { 196, 232, 255 }, color2 = { 62, 66, 76 } }, -- iceBlue
	{ id = "gog_aurora", slot = "eyes", name = "Aurora Goggles", price = 750, cur = "points", color = { 156, 92, 246 }, color2 = { 220, 230, 255 } }, -- auroraPurple / moonlight
	{ id = "suit_wool", slot = "body", name = "Shepherd Wool", price = 250, cur = "coins", color = { 192, 166, 96 }, color2 = { 150, 82, 54 } }, -- dryGrass / redEarth
	{ id = "suit_ledge", slot = "body", name = "Ledge Shell", price = 600, cur = "coins", color = { 38, 112, 98 }, color2 = { 255, 178, 72 } }, -- forestTeal / lanternGold
	{ id = "suit_summit", slot = "body", name = "Summit Down Suit", price = 1200, cur = "points", color = { 30, 62, 140 }, color2 = { 196, 232, 255 } }, -- deepSapphire / iceBlue
}
-- earned kit (concept Â§4: changes route choices, not raw power; visible on the avatar). Level or Forge purchase.
C.KIT = {
	headlamp = { name = "Headlamp", level = 2, forge = 150, info = "Lights the rock at night." },
	axe = { name = "Ice Axe", level = 3, forge = 400, info = "A second catch when you slip." },
	crampons = { name = "Crampons", level = 5, forge = 800, info = "Less grip lost on snow and ice faces." },
}
-- Legacy canister counts remain in profile migration only; there is no consumable survival system.
C.SHOP_SITES = {} -- shops postponed; legacy cosmetic definitions preserve existing owned appearances.

-- Training Yard annex (concept LOCKED #10: outside the frozen Foothold, capped diminishing gains; numbers PROPOSED)
C.TRAINING = {
	gains = { 6, 5, 4, 3, 2 }, -- + max stamina per level (100 -> 120)
	cooldown = 600, -- s between counted laps (real time; can't be ground)
	parMin = 14, -- s: a lap faster than this is refused (BOT lap ~22 s)
	parMax = 120, -- s: slower laps don't count
}

-- Rescue assist + party ropes (concept LOCKED #14: shared fixed ropes + rescue assist, no tether; numbers PROPOSED)
C.COOP = {
	rescueRange = 14, -- helper within this distance of the climber
	rescueAbove = 2, -- helper standing at least this much higher (a hand up, never a pull from below)
	rescueStamina = 40,
	rescueCooldown = 30, -- per climber
	ropeSeconds = 120,
	ropeCooldown = 45, -- per placer
	ropeMax = 2, -- live party ropes per server per player
	ropeLen = 44,
}

-- Day/night + weather (concept LOCKED #13: dynamic with mobile quality tiers, only after a measured cost test)
C.WEATHER = {
	dayMinutes = 18, -- real minutes per full day
	dayShare = 0.78, -- share of the cycle that is daytime (nightTo -> nightFrom): ~14 min day, ~4 min night
	nightFrom = 19.5, -- ClockTime
	nightTo = 5.5,
	states = { "clear", "mist", "snow", "gust" },
	minHold = 150, -- s a weather state lasts at least
	maxHold = 330,
	snowY = 1700, -- snowfall shows above this height only
}

C.PRACTICE = {
 costs = { 0, 25, 60 },
 gains = { 6, 7, 7 },
 staminaCap = 140,
 labels = { "Rhythm & footholds", "Anchors & recovery", "Fork choices" },
}
return C
