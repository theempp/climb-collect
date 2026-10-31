-- Grey-box herd + ride/swap loop (StarterPlayerScripts.SS_Ride). Client-side simulation, Play Solo prototype.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RepS = game:GetService("ReplicatedStorage")

local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))
local player = Players.LocalPlayer
local rad = math.rad
local laneX, surf, zoneOf, speedAt = P.laneX, P.surf, P.zoneOf, P.speedAt

-- Herd ------------------------------------------------------------------------------------------
local herdFolder = Instance.new("Folder")
herdFolder.Name = "SS_Herd"
herdFolder.Parent = workspace
local herd = {}
local herdStats = { recycles = 0, seenRecycles = 0, fastPops = 0 } -- BOT: recycles in the rider's view; fadeIn < FarFade inside Readable

-- Placeholder creature: torso (the pick/seat/ring target), chest, neck, head, horns, tail and four
-- legs that swing in a gallop. Each piece is (part, local CFrame from the creature frame, leg index).
-- The creature frame sits SizeY/2 above the lane, forward = -Z, like the old single block.
local function piece(m, name, size, color, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	if shape then
		p.Shape = shape
	end
	p.Parent = m
	return p
end

-- Name tag + swap highlight on a creature's body part.
-- In-range glow (owner, P4: a glow instead of the old gold outline): a Highlight over the whole creature and a
-- small PointLight, both in the creature's section Accent token, pulsing (C.Glow). c.box is the glow; its
-- Visible field is mirrored onto Highlight.Enabled / light.Enabled by setGlow.
local function decorate(body, spec, height, zone)
	local accent = Color3.fromHex(C.Zones[zone].Glow or C.Zones[zone].Accent)
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(C.Ui.TagSize.X, C.Ui.TagSize.Y)
	tag.StudsOffset = Vector3.new(0, height / 2 + 2.5, 0)
	tag.MaxDistance = C.NameTagDistance
	tag.Enabled = false -- the per-frame tag layout picks which tags show
	tag.Parent = body
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.3
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.Text = spec.Name
	tl.Parent = tag
	local hl = Instance.new("Highlight")
	hl.Adornee = body.Parent -- the whole creature (body, head, legs or the skinned mesh)
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.FillColor, hl.OutlineColor = accent, accent
	hl.FillTransparency, hl.OutlineTransparency = 1, 1
	hl.Enabled = false
	hl.Parent = body
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = C.Glow.LightRange
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	light.Parent = body
	return tag, tl, { hl = hl, light = light, Visible = false, offset = math.random() * math.pi * 2 }
end

local creatureRoot = RepS:FindFirstChild("SS_Creatures")
local creatureModels = creatureRoot and creatureRoot:FindFirstChild("Models")
local clipIds = {} -- model -> clip -> content id: an uploaded Animation asset (C.ClipAssets), else a local id in Studio
-- RegisterAnimationClip works only in Studio ("can only be called in Studio" in a published client, which killed the
-- herd build on the phone). Outside Studio a clip without an uploaded asset id returns nil: that creature runs
-- as a rigid mesh with a bob instead.
local function clipId(model, clip)
	clipIds[model] = clipIds[model] or {}
	if not clipIds[model][clip] then
		local asset = C.ClipAssets and C.ClipAssets[model] and C.ClipAssets[model][clip]
		if asset and asset ~= "" then
			clipIds[model][clip] = asset
		elseif RunService:IsStudio() and creatureRoot and creatureRoot:FindFirstChild("Clips") then
			-- the raw KeyframeSequences are not replicated any more (ServerStorage.SS_CreatureClips: about 18,000
			-- instances every client downloaded); this Studio-only path runs only if someone puts them back
			local ok, id = pcall(function()
				return game:GetService("AnimationClipProvider"):RegisterAnimationClip(creatureRoot.Clips[model][clip])
			end)
			clipIds[model][clip] = ok and id or false
		else
			clipIds[model][clip] = false
		end
	end
	return clipIds[model][clip] or nil
end

-- Skinned creature (M8): one MeshPart + bones, played by an Animator. The MeshPart is the body (pick/seat/
-- ring target); the frame is the mesh centre, SizeY/2 above the lane, forward = -Z.
local function makeMeshCreature(zone, spec, tpl, lane, d)
	local m = tpl:Clone()
	m.Name = spec.Name
	local body = m.PrimaryPart
	local size = body.Size
	local tag, tl, box = decorate(body, spec, size.Y, zone)
	m.Parent = herdFolder
	local ctl = m:FindFirstChildWhichIsA("AnimationController") or Instance.new("AnimationController", m)
	local animator = ctl:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", ctl)
	local gallop -- nil when no clip is available: the rigid mesh bobs instead
	local id = clipId(spec.Model, "gallop")
	if id then
		local ok, track = pcall(function()
			local a = Instance.new("Animation")
			a.AnimationId = id
			return animator:LoadAnimation(a)
		end)
		if ok and track then
			gallop = track
			gallop.Looped = true
			gallop:Play(0)
		else
			warn("SS_Ride: gallop clip failed for " .. tostring(spec.Model) .. ": " .. tostring(track))
		end
	end
	local c = {
		skinned = true,
		model = m, body = body, pieces = {}, legPhase = {}, box = box, lane = lane, d = d, zone = zone,
		name = spec.Name, size = size, tag = tag, tagLabel = tl, parts = { body }, fade = 0, gallop = gallop,
		seat = Vector3.new(0, body:GetAttribute("SeatUp"), body:GetAttribute("SeatBack")),
		spd = spec.Speed * (1 + (math.random() * 2 - 1) * C.SpeedJitter), phase = math.random() * 6,
		fly = spec.Fly or 0, score = spec.Score or 1, rare = spec.Rare, xo = 0, passT = 0,
	}
	return c
end

local function makeCreature(zone, sp, lane, d)
	local spec = C.Species[zone][sp]
	local zc = C.Zones[zone]
	local tpl = spec.Model and creatureModels and creatureModels:FindFirstChild(spec.Model)
	if tpl then
		return makeMeshCreature(zone, spec, tpl, lane, d)
	end
	local m = Instance.new("Model")
	m.Name = spec.Name
	local W, H, L = spec.Size.X, spec.Size.Y, spec.Size.Z
	local dark = spec.Color:Lerp(Color3.new(0, 0, 0), 0.35)
	local accent = Color3.fromHex(zc.Accent)
	local body = piece(m, "Body", Vector3.new(W * 0.9, H * 0.55, L * 0.75), spec.Color)
	local pieces = {}
	local function add(p, cf, leg)
		table.insert(pieces, { p = p, cf = cf, leg = leg })
	end
	local chestD = math.min(W, H * 0.62) * 1.05
	add(piece(m, "Chest", Vector3.new(chestD, chestD, chestD), spec.Color, Enum.PartType.Ball), CFrame.new(0, H * 0.2, -L * 0.3))
	add(piece(m, "Neck", Vector3.new(W * 0.36, H * 0.42, W * 0.4), spec.Color), CFrame.new(0, H * 0.42, -L * 0.42) * CFrame.Angles(math.rad(-30), 0, 0))
	local head = piece(m, "Head", Vector3.new(W * 0.42, H * 0.26, L * 0.24), spec.Color)
	add(head, CFrame.new(0, H * 0.6, -L * 0.53) * CFrame.Angles(math.rad(-12), 0, 0))
	add(piece(m, "Muzzle", Vector3.new(W * 0.3, H * 0.16, L * 0.1), dark), CFrame.new(0, H * 0.53, -L * 0.66))
	local glow = zc.AccentGlow and Enum.Material.Neon or Enum.Material.SmoothPlastic
	for _, sx in { -1, 1 } do
		add(piece(m, "Horn", Vector3.new(0.3, H * 0.38, 0.3), accent, nil, glow),
			CFrame.new(sx * W * 0.16, H * 0.82, -L * 0.48) * CFrame.Angles(math.rad(-25), 0, math.rad(-sx * 25)))
	end
	add(piece(m, "Tail", Vector3.new(0.5, 0.5, L * 0.22), dark), CFrame.new(0, H * 0.32, L * 0.42) * CFrame.Angles(math.rad(-25), 0, 0))
	if spec.Fly then -- flyer: two wings hinged at the shoulders, flapped in the render loop
		for _, sx in { -1, 1 } do
			local w = piece(m, "Wing", Vector3.new(L * 0.9, 0.3, L * 0.4), spec.Color:Lerp(accent, 0.35))
			table.insert(pieces, { p = w, cf = CFrame.new(sx * W * 0.4, H * 0.25, -L * 0.05), wing = sx })
		end
	else
		local legSize = Vector3.new(W * 0.2, H * 0.55, W * 0.2)
		local legs = { { -1, -1, 0 }, { 1, -1, 0.35 }, { -1, 1, math.pi }, { 1, 1, math.pi + 0.35 } } -- side, front(-1)/back(1), phase
		for i, l in legs do
			add(piece(m, "Leg", legSize, dark), CFrame.new(l[1] * W * 0.3, -H * 0.02, l[2] * L * 0.3), i)
		end
	end
	local tag, tl, box = decorate(body, spec, spec.Size.Y, zone)
	m.PrimaryPart = body
	m.Parent = herdFolder
	local all = { body }
	for _, pc in pieces do
		table.insert(all, pc.p)
	end
	local c = {
		model = m, body = body, pieces = pieces, legPhase = { 0, 0.35, math.pi, math.pi + 0.35 }, box = box, lane = lane, d = d,
		zone = zone, name = spec.Name, size = spec.Size, tag = tag, tagLabel = tl, parts = all, fade = 0,
		spd = spec.Speed * (1 + (math.random() * 2 - 1) * C.SpeedJitter), phase = math.random() * 6,
		fly = spec.Fly or 0, score = spec.Score or 1, rare = spec.Rare, xo = 0, passT = 0,
	}
	return c
end

-- Herd pools (P2): every biome's creatures are built once at load and parked (Parent nil); the pool step
-- further down brings them in and out around the rider. Per biome: Herd (default Pool.PerLane) x LaneCount
-- commons (the common species in turn) plus Pool.ExtraEach of every extra species (big, rare, flyer: Weight < 1). The
-- spawn roll uses each extra's Weight x the zone's Rare multiplier (default 1) against the commons' 1 each.
local pools, speciesW = {}, {}
local loadT0 = os.clock() -- LOADREC lines in the client log: where the load time goes (read them from /console on a phone)
local poolBuild = { eager = 0, eagerMs = 0, bg = 0, bgDoneAt = nil }
local buildJobs = {} -- [zone] = list of species indexes still to build in the background
local function buildCreature(k, i)
	local c = makeCreature(k, i, 1, P.Starts[k]) -- parented once, so a skinned gallop can load
	c.sp, c.parked, c.spd0 = i, true, c.spd
	c.model.Parent = nil
	table.insert(pools[k], c)
end
for k in C.Zones do
	pools[k] = {}
	local w = { common = {}, extra = {}, total = 0, extraW = 0 }
	local rare = C.Zones[k].Rare or 1
	for i, spec in C.Species[k] do
		local sw = spec.Weight or 1
		if sw < 1 then
			sw *= rare
			w.extra[#w.extra + 1] = { i = i, w = sw }
			w.extraW += sw
		else
			w.common[#w.common + 1] = i
		end
		w.total += sw
	end
	speciesW[k] = w
	local order = {}
	for n = 1, (C.Zones[k].Herd or C.Pool.PerLane) * C.LaneCount do
		order[#order + 1] = w.common[n % #w.common + 1]
	end
	for _, e in w.extra do
		for _ = 1, C.Pool.ExtraEach do
			order[#order + 1] = e.i
		end
	end
	if k <= C.Pool.EagerZones then
		local t = os.clock()
		for _, i in order do
			buildCreature(k, i)
		end
		poolBuild.eager += #order
		poolBuild.eagerMs += (os.clock() - t) * 1000
	else
		buildJobs[k] = order
	end
end
print(string.format("LOADREC pool eager: %d creatures (zones 1-%d) in %.0f ms, %.0f ms after script start",
	poolBuild.eager, C.Pool.EagerZones, poolBuild.eagerMs, (os.clock() - loadT0) * 1000))
RepS:SetAttribute("SS_PoolReady", true) -- SS_Loading: the first biomes' herd is built
-- The other biomes' creatures are built in the background, in order, a few ms of work a frame: the rider needs
-- biome 3 only after a full section (about 40 s). poolStep finds no candidates in a biome until it is built.
task.spawn(function()
	local slice = C.Pool.BuildSliceMs / 1000
	local t0 = os.clock()
	local sliceT = os.clock()
	for k = C.Pool.EagerZones + 1, #C.Zones do
		for _, i in buildJobs[k] or {} do
			buildCreature(k, i)
			poolBuild.bg += 1
			if os.clock() - sliceT >= slice then
				RunService.Heartbeat:Wait()
				sliceT = os.clock()
			end
		end
	end
	poolBuild.bgDoneAt = os.clock() - loadT0
	print(string.format("LOADREC pool background: %d creatures built over %.1f s (done %.1f s after script start)",
		poolBuild.bg, os.clock() - t0, poolBuild.bgDoneAt))
end)

-- Body + piece CFrames of creature c at frame cf, appended to parts / cfs (greybox legs and wings by its phase;
-- a skinned creature's body is the mesh). Used by the render loop and the BOT's fog targets.
local function placeParts(c, cf, parts, cfs, swing)
	parts[#parts + 1] = c.body
	cfs[#cfs + 1] = c.skinned and cf or cf * CFrame.new(0, c.size.Y * 0.175, 0)
	for _, pc in c.pieces do
		parts[#parts + 1] = pc.p
		if pc.wing then -- shoulder hinge: flap, then reach the wing out sideways
			local a = math.sin(c.phase * 0.5) * math.rad(C.FlyFlap) * pc.wing
			cfs[#cfs + 1] = cf * pc.cf * CFrame.Angles(0, 0, a) * CFrame.new(pc.wing * pc.p.Size.X / 2, 0, 0)
		elseif pc.leg then -- hip pivot, then hang the leg below it
			local a = math.sin(c.phase + c.legPhase[pc.leg]) * swing
			cfs[#cfs + 1] = cf * pc.cf * CFrame.Angles(a, 0, 0) * CFrame.new(0, -pc.p.Size.Y / 2, 0)
		else
			cfs[#cfs + 1] = cf * pc.cf
		end
	end
end

local function creatureCF(c)
	local bob = c.gallop and 0 or math.abs(math.sin(c.phase)) * C.BobHeight -- a skinned gallop carries its own bob
	if c.fly > 0 then -- flyers glide on a slow swell above their lane
		bob = math.sin(c.phase * 0.15) * C.FlyBob
	end
	return surf(c.d, laneX(c.lane, c.d) + c.xo, c.size.Y / 2 + bob + c.fly)
end

-- Character -------------------------------------------------------------------------------------
local hum, hrp, animate
local motors = {}
local state = "none" -- ride | stance | ring | jump | fall | free | summit
local mount, target
local stateT = 0
local jumpFrom
local fallFrom, fallTo
local freeSince = 0
local fallClock = 0
local stats = { swaps = 0, success = 0, fail = 0, remounts = 0, lastRemountWait = -1, lastResult = "", summits = 0, score = 0 }
local pendingPress -- seconds into the ring when a scheduled (bot) press fires
local probe -- creature parked by the BOT occlusion probe
local L = C.Leap
local leap -- in-air state: path coords d / x / h (height above the lane surface) and their velocities
local timeScale = 1 -- world time in the air (the herd slows with you)
local shakeT = 0 -- landing camera shake, studs, decays
local pointerPos, pointerT = nil, 0
local function trackPointer(i)
	local t = i.UserInputType
	if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
		pointerPos, pointerT = Vector2.new(i.Position.X, i.Position.Y), os.clock()
	end
end
UIS.InputChanged:Connect(trackPointer)
UIS.InputBegan:Connect(trackPointer)

local function seatCF(c)
	if c.seat then -- skinned: on the back above the spine bone
		return creatureCF(c) * CFrame.new(0, c.seat.Y + 1.6, c.seat.Z)
	end
	return creatureCF(c) * CFrame.new(0, c.size.Y / 2 + 1.6, 0.5)
end
local function standCF(c)
	local top, back = c.size.Y / 2, 0.5
	if c.seat then
		top, back = c.seat.Y, c.seat.Z
	end
	return creatureCF(c) * CFrame.new(0, top + hum.HipHeight + hrp.Size.Y / 2, back) * CFrame.Angles(0, rad(90), 0)
end

local function setAnimated(on)
	if animate then
		animate.Disabled = not on
	end
	if not on and hum then
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, tr in animator:GetPlayingAnimationTracks() do
				tr:Stop(0)
			end
		end
	end
end

-- Poses are applied after the Animator step (PreSimulation), or it overwrites Transform.
local curPose
local function pose(p)
	curPose = p
end
RunService.PreSimulation:Connect(function()
	if curPose then
		for name, m in motors do
			m.Transform = curPose[name] or CFrame.identity
		end
	end
end)

local function A(x, y, z)
	return CFrame.Angles(rad(x or 0), rad(y or 0), rad(z or 0))
end

local POSE_RIDE = {
	LeftHip = A(80, 0, -20), RightHip = A(80, 0, 20), LeftKnee = A(-75), RightKnee = A(-75),
	Waist = A(-30), Neck = A(20), LeftShoulder = A(70), RightShoulder = A(70), LeftElbow = A(25), RightElbow = A(25),
}

-- UI --------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SS_UI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
-- The hint is one short line at the top, under the top bar (off the lanes); the zone title card
-- (SS_Env) starts below it, so the two never overlap. The debug readout is off unless Ui.DebugHud.
local U = C.Ui
local TL = require(RepS:WaitForChild("SS_Timeline"))
local timeline = TL.new(gui, player) -- progress strip at the very top; the hint and title card start below it
local top = U.TopGap + TL.block()
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0.5, 0)
hint.Size = UDim2.new(U.HintWidth, 0, 0, U.HintHeight)
hint.Position = UDim2.new(0.5, 0, 0, top)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.new(1, 1, 1)
hint.TextStrokeTransparency = 0.3
hint.TextScaled = true
hint.Font = Enum.Font.GothamBold
local hintSize = Instance.new("UITextSizeConstraint")
hintSize.MaxTextSize = U.HintMaxText
hintSize.MinTextSize = U.HintMinText
hintSize.Parent = hint
hint.Parent = gui
local hud = hint:Clone()
hud.Name = "Hud"
hud.AnchorPoint = Vector2.zero
hud.Size = UDim2.new(0, 300, 0, 18)
hud.Position = UDim2.new(0, 12, 0, top + U.HintHeight + 4)
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.Visible = U.DebugHud
hud.Parent = gui
local scoreLabel = hint:Clone() -- score (M8 part 3): big and rare mounts pay Score x per stud
scoreLabel.Name = "Score"
scoreLabel.AnchorPoint = Vector2.new(1, 0)
scoreLabel.Size = UDim2.new(0, 160, 0, 22)
scoreLabel.Position = UDim2.new(1, -12, 0, top + U.HintHeight + 4)
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
scoreLabel.Parent = gui

-- Progression (P3): the server owns coins, best section and upgrade levels (SS_Save). We report the rider's
-- distance and cumulative score every Progress.ReportEvery s; it pushes the profile view back. Upgrade levels
-- move the swap tunables away from their base values.
local remotes = RepS:WaitForChild("SS_Remotes", 10)
local profile -- last view pushed by the server
local BASE = { SuccessWindow = C.SuccessWindow, StanceTime = C.StanceTime, WobbleAmp = C.WobbleAmp }
local upgradeOf = {}
for _, u in C.Upgrades do
	upgradeOf[u.Id] = u
end
local function applyUpgrades(levels)
	local ring, stance = levels.Ring or 0, levels.Stance or 0
	C.SuccessWindow = BASE.SuccessWindow + ring * upgradeOf.Ring.Window
	C.StanceTime = math.max(BASE.StanceTime - stance * upgradeOf.Stance.Time, 0.1)
	C.WobbleAmp = math.max(BASE.WobbleAmp - stance * upgradeOf.Stance.Wobble, 0)
end
local Shop = require(RepS:WaitForChild("SS_Shop"))
local shopY = top + U.HintHeight + 4 + 22 + 2
local shop = Shop.new(gui, shopY, function(id)
	if not remotes then
		return false, "offline"
	end
	return remotes.Buy:InvokeServer(id)
end)
-- Streaming (SS_Stream): before a jump (summit reset, debug teleport) the server streams in the ground at d;
-- returns (ok, seconds). Yields; no-op offline.
local feedT = 0
local lastPrepare -- BOT S3: the last prepare's d, result and seconds
local function prepare(d)
	local fn = remotes and remotes:FindFirstChild("Prepare")
	if not fn then
		return true, 0
	end
	local t0 = os.clock()
	local ok, res = pcall(fn.InvokeServer, fn, d)
	lastPrepare = { d = d, ok = ok and res == true, secs = os.clock() - t0 }
	return lastPrepare.ok, lastPrepare.secs
end
local summitPrep -- set once prepare(-30) for the summit reset returned
-- Herd Journal + medal toast (P4): the JOURNAL button sits under SHOP.
local journal = require(RepS:WaitForChild("SS_Journal")).new(gui, shopY + U.Shop.Line + 4 + U.Shop.Button.Y + 4,
	top + U.HintHeight + 4)
-- M7 perf recorder (C.Perf): per-section frame / memory stats, a card at the summit
local perf = C.Perf.Enabled and require(RepS:WaitForChild("SS_Perf")).new(gui, top + U.HintHeight + 4, function()
	local d = (leap and leap.d) or (mount and mount.d) or (target and target.d)
		or (hrp and hrp.Parent and state ~= "none" and state ~= "summit" and (P.project(hrp.Position))) or nil
	return d, state, #herd
end)
local appliedLevels = ""
if remotes then
	remotes.Profile.OnClientEvent:Connect(function(v)
		profile = v
		shop:set(v)
		journal:set(v)
		local key = string.format("%d/%d", v.upgrades.Ring or 0, v.upgrades.Stance or 0)
		if key ~= appliedLevels then -- only on a level change (BOT "tune" edits survive the 1 Hz pushes)
			appliedLevels = key
			applyUpgrades(v.upgrades)
		end
	end)
end
local reportT = 0

local ring = Instance.new("BillboardGui")
ring.Size = UDim2.fromOffset(180, 180)
ring.StudsOffset = Vector3.new(0, 7, 0)
ring.AlwaysOnTop = true
ring.Enabled = false
ring.ResetOnSpawn = false
ring.Parent = gui.Parent -- a BillboardGui inside a ScreenGui does not render
local function circle(color, thick)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thick
	s.Parent = f
	f.Parent = ring
	return f, s
end
local targetCircle = circle(Color3.fromRGB(120, 255, 140), 6)
local shrinkCircle, shrinkStroke = circle(Color3.new(1, 1, 1), 4)
local ringPx = 180 * C.TargetScale / C.RingStartScale -- target circle size in px
targetCircle.Size = UDim2.fromOffset(ringPx, ringPx)

-- State changes ---------------------------------------------------------------------------------
local function enter(s)
	state = s
	stateT = 0
end

local function mountOn(c)
	mount = c
	local ev = remotes and remotes:FindFirstChild("Ridden")
	if ev then
		ev:FireServer(c.name, c.d) -- Herd Journal ridden count (the server checks it against the run)
	end
	setAnimated(false)
	hrp.Anchored = true
	hum.PlatformStand = true
	enter("ride")
end

local function startJump(c)
	target = c
	jumpFrom = hrp.Position
	setAnimated(false)
	hrp.Anchored = true
	hum.PlatformStand = true
	enter("jump")
end

local function startSwap(c)
	if state ~= "ride" or c == mount then
		return false
	end
	if (c.body.Position - mount.body.Position).Magnitude > C.SwapRange then
		return false
	end
	target = c
	stats.swaps += 1
	pendingPress = nil
	enter("stance")
	return true
end

local function fail(why)
	stats.fail += 1
	stats.lastResult = "fail:" .. why
	ring.Enabled = false
	fallFrom = hrp.CFrame
	local back = math.max(mount.d - C.FallDistance, 0)
	fallTo = surf(back, laneX(mount.lane, back), 0.6) * CFrame.Angles(rad(-90), 0, 0) -- face-down on the lane
	fallClock = os.clock()
	mount = nil
	target = nil
	enter("fall")
end

-- Leap ------------------------------------------------------------------------------------------
local WEATHER = { snow = C.Fx.SnowColor, motes = C.Fx.MoteColor, embers = C.Fx.EmberColors[1], wind = C.Fx.WindColor }
local function zoneColour(d)
	return Color3.fromHex(WEATHER[C.Env[zoneOf(math.max(d, 0))].Fx])
end
local trailA0, trailA1, trail, puff
local function leapFx()
	if trail then
		return
	end
	trailA0, trailA1 = Instance.new("Attachment"), Instance.new("Attachment")
	trailA0.Position, trailA1.Position = Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
	trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = trailA0, trailA1
	trail.Lifetime = L.TrailLife
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new(0.35, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Enabled = false
	local holder = Instance.new("Part")
	holder.Name = "SS_LeapPuff"
	holder.Anchored, holder.CanCollide, holder.CanQuery, holder.Transparency = true, false, false, 1
	holder.Size = Vector3.one
	holder.Parent = workspace
	puff = Instance.new("ParticleEmitter")
	puff.Rate = 0
	puff.Lifetime = NumberRange.new(0.4, 0.8)
	puff.Speed = NumberRange.new(10, 22)
	puff.SpreadAngle = Vector2.new(80, 80)
	puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 3) })
	puff.Transparency = NumberSequence.new(0.2, 1)
	puff.Acceleration = Vector3.new(0, -30, 0)
	puff.Parent = holder
end

-- where a rider sits on c, in path coords (d, x, h above the lane surface)
local function seatDXH(c)
	local back, up = 0.5, c.size.Y / 2
	if c.seat then
		back, up = c.seat.Z, c.seat.Y
	end
	return c.d - back, laneX(c.lane, c.d) + c.xo, c.size.Y / 2 + up + 1.6 + c.fly
end

local function startLeap(c, power)
	leapFx()
	local from = mount
	local d0, x0 = P.project(hrp.Position)
	local _, _, h0 = seatDXH(from)
	local T = L.Time + L.PowerTime * power
	local td, tx, th = seatDXH(c)
	local vt = speedAt(c.d) * c.spd
	leap = {
		d = d0, x = x0, h = h0, from = from, spd = from.spd, T = T, t = 0, real = 0, start = os.clock(),
		grav = from.fly > 0 and L.Gravity * L.Glide or L.Gravity, -- off a flyer: a glide-leap
	}
	leap.vd, leap.vx, leap.vh = (td + vt * T - d0) / T, (tx - x0) / T, (th - h0 + 0.5 * leap.grav * T * T) / T
	trailA0.Parent, trailA1.Parent = hrp, hrp
	trail.Color = ColorSequence.new(zoneColour(d0))
	trail.Parent = hrp
	trail.Enabled = true
	mount = nil
	target = c
	setAnimated(false)
	hrp.Anchored = true
	hum.PlatformStand = true
	enter("leap")
end

local function endLeapFx()
	timeScale = 1
	if trail then
		trail.Enabled = false
	end
end

local function landOn(c)
	endLeapFx()
	stats.success += 1
	stats.lastResult = "success"
	c.dip = 1
	shakeT = L.Shake
	puff.Color = ColorSequence.new(zoneColour(leap.d))
	puff.Parent.CFrame = surf(leap.d, leap.x, leap.h - 1.6)
	puff:Emit(L.Puff)
	leap = nil
	mountOn(c)
	target = nil
end

local function missLeap()
	endLeapFx()
	stats.fail += 1
	stats.lastResult = "fail:missed"
	puff.Color = ColorSequence.new(zoneColour(leap.d))
	puff.Parent.CFrame = surf(leap.d, leap.x, 0.5)
	puff:Emit(L.Puff)
	shakeT = L.Shake * 0.6
	fallFrom = hrp.CFrame
	local back = math.max(leap.d - C.FallDistance * 0.5, 0)
	fallTo = surf(back, leap.x, 0.6) * CFrame.Angles(rad(-90), 0, 0)
	fallClock = os.clock()
	leap, target = nil, nil
	enter("fall")
end

-- aim: the mouse / touch point at the herd's back height, or (no pointer input since take-off) the picked
-- creature. Auto-target: the target is always the creature whose back is nearest that point.
local function leapAim()
	if pointerPos and pointerT > leap.start then
		local ray = workspace.CurrentCamera:ScreenPointToRay(pointerPos.X, pointerPos.Y)
		local plane = surf(leap.d, leap.x, 6).Position.Y
		local t = ray.Direction.Y < -0.02 and (plane - ray.Origin.Y) / ray.Direction.Y or 250
		local ad, ax = P.project(ray.Origin + ray.Direction * math.clamp(t, 5, 250))
		local edge = math.abs(laneX(1, leap.d)) + P.laneWidth(leap.d) * 0.5 -- no leaping off the track
		ax = math.clamp(ax, -edge, edge)
		local best, bd = nil, math.huge
		for _, c in herd do
			if c ~= leap.from and c.d > leap.d - 10 and c.d < leap.d + C.SwapRange * 2 then
				local sd, sx = seatDXH(c)
				local dist = math.sqrt((sd - ad) ^ 2 + (sx - ax) ^ 2)
				if dist < bd then
					best, bd = c, dist
				end
			end
		end
		target = best or target
	end
	local sd, sx = seatDXH(target)
	return sd, sx, speedAt(target.d) * target.spd
end

local function leapStep(dt)
	leap.real += dt
	-- time scale: ease into slow motion, back out just before the planned landing (or after MaxSlow)
	local kin = math.clamp(leap.real / L.EaseIn, 0, 1)
	local kout = math.clamp((leap.T - leap.t) / L.EaseOut, 0, 1)
	if leap.real > L.MaxSlow then
		kout = math.min(kout, math.clamp(1 - (leap.real - L.MaxSlow) / 0.3, 0, 1))
	end
	local k = math.min(kin, kout)
	k = k * k * (3 - 2 * k)
	timeScale = 1 - (1 - L.Slow) * k
	local g = dt * timeScale
	leap.t += g
	-- steer toward where the aim will be on arrival (relative to the herd flow); gravity on the height
	local ad, ax, av = leapAim()
	local tr = math.max(leap.T - leap.t, 0.15)
	local flow = speedAt(math.max(leap.d, 0)) * leap.spd
	local wd = flow + math.clamp((ad + av * tr - leap.d) / tr - flow, -L.AirSpeed, L.AirSpeed)
	local wx = math.clamp((ax - leap.x) / tr, -L.AirSpeed, L.AirSpeed)
	local acc = L.AirAccel * g
	leap.vd += math.clamp(wd - leap.vd, -acc, acc)
	leap.vx += math.clamp(wx - leap.vx, -acc, acc)
	leap.vh -= leap.grav * g
	leap.d += leap.vd * g
	leap.x += leap.vx * g
	leap.h += leap.vh * g
	-- auto-land: over the last Magnet seconds the flight bends onto the target's back
	local m = math.clamp(1 - (leap.T - leap.t) / L.Magnet, 0, 1)
	if m > 0 and target then
		local sd, sx, sh = seatDXH(target)
		local k = math.min(m * m * 12 * g / L.Magnet, 1)
		leap.d += (sd - leap.d) * k
		leap.x += (sx - leap.x) * k
		leap.h += (sh - leap.h) * k
		if leap.t >= leap.T or (math.abs(leap.d - sd) < 0.6 and math.abs(leap.x - sx) < 0.6 and math.abs(leap.h - sh) < 0.6) then
			landOn(target)
			return
		end
	end
	-- body: pitched with the climb / fall, rolled into the turn
	hrp.CFrame = surf(leap.d, leap.x, leap.h)
		* CFrame.Angles(math.clamp(-leap.vh / 60, -0.5, 0.5), 0, math.clamp(-leap.vx / 40, -0.5, 0.5))
	if leap.vh > 8 then -- rising: tucked
		pose({ LeftHip = A(70), RightHip = A(70), LeftKnee = A(-100), RightKnee = A(-100), LeftShoulder = A(0, 0, -40), RightShoulder = A(0, 0, 40) })
	elseif leap.vh > -10 then -- hanging at the apex: arms out, legs trailing
		pose({ LeftHip = A(-20), RightHip = A(-10), LeftKnee = A(-30), RightKnee = A(-20), LeftShoulder = A(0, 0, -95), RightShoulder = A(0, 0, 95), Waist = A(10) })
	else -- dropping: legs reach for the back
		pose({ LeftHip = A(50), RightHip = A(50), LeftKnee = A(-50), RightKnee = A(-50), LeftShoulder = A(0, 0, -60), RightShoulder = A(0, 0, 60) })
	end
	hint.Text = ""
	if leap.vh >= 0 then
		return
	end
	for _, c in herd do
		if c ~= leap.from or leap.t > 0.3 then
			local sd, sx, sh = seatDXH(c)
			if math.abs(leap.d - sd) < c.size.Z * 0.3 + L.CatchPad and math.abs(leap.x - sx) < c.size.X / 2 + L.CatchPad
				and leap.h <= sh + 0.5 and leap.h >= sh - 3 then
				landOn(c)
				return
			end
		end
	end
	if not target and leap.h <= hrp.Size.Y / 2 + 0.5 then
		missLeap()
	end
end

local function press()
	if state ~= "ring" then
		return nil
	end
	local s = C.RingStartScale * (1 - stateT / C.RingDuration)
	if math.abs(s - C.TargetScale) <= C.SuccessWindow then
		stats.lastResult = "leap"
		ring.Enabled = false
		startLeap(target, 1 - math.abs(s - C.TargetScale) / C.SuccessWindow)
		return true
	end
	fail("timing")
	return false
end

-- Input -----------------------------------------------------------------------------------------
local function pickCreature(screenPos)
	local cam = workspace.CurrentCamera
	local ray = cam:ScreenPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { herdFolder }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
	if hit then
		for _, c in herd do
			if hit.Instance:IsDescendantOf(c.model) then
				return c
			end
		end
	end
	-- touch-friendly fallback: nearest in-range creature on screen
	local best, bestD = nil, C.TapPickRadius
	for _, c in herd do
		if c ~= mount and (c.body.Position - mount.body.Position).Magnitude <= C.SwapRange then
			local p, on = cam:WorldToScreenPoint(c.body.Position)
			local dist = (Vector2.new(p.X, p.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
			if on and dist < bestD then
				best, bestD = c, dist
			end
		end
	end
	return best
end

UIS.InputBegan:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
		if state == "ride" and not processed then
			local c = pickCreature(input.Position)
			if c then
				startSwap(c)
			end
		elseif state == "ring" then
			press()
		end
	elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		press()
	end
end)
UIS.JumpRequest:Connect(function()
	if state == "ring" then
		press()
	end
end)

-- Per-frame -------------------------------------------------------------------------------------
local function nearestInLane(pd, px, range)
	for _, c in herd do
		if c.fly == 0 and math.abs(c.d - pd) < range and math.abs(laneX(c.lane, c.d) - px) < P.laneWidth(c.d) * 0.6 then
			return c
		end
	end
end

local function onFoot(d, x)
	return surf(d, x, hum.HipHeight + hrp.Size.Y / 2)
end

-- Ride camera: behind and above the rider, looking up the slope; FOV widens with speed.
local Cam = C.Cam
local camPos, camLook
local function rideCamera(dt, anchorD, anchorX, speed, anchorH)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local h = anchorH or 0 -- riding a flyer lifts the camera with it
	local want = surf(anchorD - Cam.Back, anchorX * Cam.LaneFollow, Cam.Up + h).Position
	local look = surf(anchorD + Cam.LookAhead, anchorX * Cam.LaneFollow * 0.5, Cam.LookUp + h * 0.8).Position
	local a = 1 - math.exp(-Cam.Lag * dt)
	camPos = camPos and camPos:Lerp(want, a) or want
	camLook = camLook and camLook:Lerp(look, a) or look
	local shake = Cam.Shake * speed / math.max(C.Zones[1].Speed, 1) + shakeT
	shakeT = math.max(shakeT - dt * 2.5, 0)
	local jitter = Vector3.new(math.noise(os.clock() * 7, 1) * shake, math.noise(os.clock() * 7, 2) * shake, 0)
	cam.CFrame = CFrame.lookAt(camPos + jitter, camLook)
	cam.FieldOfView = math.min(Cam.Fov + Cam.FovPerSpeed * speed, Cam.FovMax)
end

local function leapCamera(dt, ad, ax)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local want = surf(leap.d - Cam.Back, leap.x * Cam.LaneFollow, leap.h * 0.6 + Cam.Up).Position
	local look = surf(leap.d + Cam.LookAhead * 0.5 + (ad - leap.d) * 0.5, leap.x + (ax - leap.x) * 0.6, leap.h * 0.4).Position
	local a = 1 - math.exp(-Cam.Lag * dt)
	camPos = camPos and camPos:Lerp(want, a) or want
	camLook = camLook and camLook:Lerp(look, a) or look
	cam.CFrame = CFrame.lookAt(camPos, camLook)
	cam.FieldOfView = Cam.Fov + L.Fov * (1 - timeScale) / (1 - L.Slow)
end

local function summitCamera()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local centre = surf(P.Total + 75, 0, 0).Position
	-- the arc is centred on the downhill side, so the shot looks up past the crown into the Z4 sky (M6:
	-- a random start angle often looked back down onto zone 3's dark terrain and warm backdrop peaks)
	local down = surf(P.Total - 300, 0, 0).Position - centre
	local a = math.atan2(down.Z, down.X) + (stateT - C.SummitHold * 0.5) * Cam.SummitSpin
	local pos = centre + Vector3.new(math.cos(a) * Cam.SummitRadius, Cam.SummitHeight, math.sin(a) * Cam.SummitRadius)
	cam.CFrame = CFrame.lookAt(pos, centre + Vector3.new(0, 20, 0))
	cam.FieldOfView = Cam.Fov
	camPos, camLook = nil, nil
end

local function freeCamera()
	local cam = workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Custom then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		cam.FieldOfView = Cam.Fov
	end
	camPos, camLook = nil, nil
end

-- Occlusion: a creature the camera is inside is hidden; one between the camera and the rider fades.
-- Rough creature extents (half sizes) around the body part: width, height incl. horns, length incl. head.
local function extents(c)
	return Vector3.new(c.size.X * 0.5, c.size.Y * 0.7, c.size.Z * 0.6)
end
local SEG_SAMPLES = 8
local function fadeOccluders(dt, cam, focus)
	local camPos = cam.CFrame.Position
	local seg = focus - camPos
	local a = 1 - math.exp(-Cam.FadeSpeed * dt)
	for _, c in herd do
		local want = 0
		if c ~= mount and c ~= target and c.d > P.Total - C.SummitFade then -- fades out, then recycles
			want = math.min((c.d - P.Total + C.SummitFade) / C.SummitFade, 1)
		elseif c ~= mount and c ~= target and (c.body.Position - camPos).Magnitude < 60 then
			local bcf = c.body.CFrame
			local e = extents(c)
			local loc = bcf:PointToObjectSpace(camPos)
			local hm = e + Vector3.one * Cam.HideMargin
			if math.abs(loc.X) < hm.X and math.abs(loc.Y) < hm.Y and math.abs(loc.Z) < hm.Z then
				want = 1
			else
				local fm = e + Vector3.one * Cam.FadeMargin
				for i = 0, SEG_SAMPLES do
					local q = bcf:PointToObjectSpace(camPos + seg * (i / SEG_SAMPLES))
					if math.abs(q.X) < fm.X and math.abs(q.Y) < fm.Y and math.abs(q.Z) < fm.Z then
						want = Cam.FadeAlpha
						break
					end
				end
			end
		end
		if c.spawnT then -- just respawned (P2 pool): fade in over Pool.FadeIn
			local f = 1 - (os.clock() - c.spawnT) / (c.fadeDur or C.Pool.FadeIn)
			if f > 0 then
				want = math.max(want, f)
			else
				c.spawnT = nil
			end
		end
		if c.despawnT then -- leaving the pool ahead of the rider: fade out over Pool.FarFade (as slowly as it came), then it parks
			want = math.max(want, math.min((os.clock() - c.despawnT) / C.Pool.FarFade, 1))
		end
		c.fade = want == 1 and 1 or c.fade + (want - c.fade) * a
		if c.fade < 0.01 then
			c.fade = 0
		end
		if c.fade ~= c.applied then
			c.applied = c.fade
			for _, p in c.parts do
				p.LocalTransparencyModifier = c.fade
			end
		end
		if c.fade > 0.3 then -- a faded creature hugging the camera would draw a huge glow
			c.box.Visible = false
		end
		local g, on = c.box, c.box.Visible
		if g.hl.Enabled ~= on then
			g.hl.Enabled, g.light.Enabled = on, on
		end
		if on then -- pulse: 0 .. 1 at C.Glow.Hz
			local k = 0.5 + 0.5 * math.sin(os.clock() * C.Glow.Hz * math.pi * 2 + g.offset)
			g.hl.FillTransparency = C.Glow.FillMax + (C.Glow.FillMin - C.Glow.FillMax) * k
			g.hl.OutlineTransparency = C.Glow.Outline
			g.light.Brightness = C.Glow.LightMin + (C.Glow.LightMax - C.Glow.LightMin) * k
		end
	end
end

-- Name tags: at most Ui.TagMax, swappable creatures first, then the nearest. A tag that would overlap
-- one already placed on screen is lifted above it; tags fade out towards NameTagDistance. Tags never
-- sit on the hint line or on a showing zone title card (SS_Env's SS_Titles.Card).
local GuiService = game:GetService("GuiService")
local function uiBlocks()
	local out = { hint }
	local tg = gui.Parent:FindFirstChild("SS_Titles")
	local card = tg and tg:FindFirstChild("Card")
	local name = card and card:FindFirstChild("Title")
	if name and name.TextTransparency < 0.95 then
		table.insert(out, card)
	end
	return out
end
local function layoutTags(cam)
	local camPos = cam.CFrame.Position
	local inset = GuiService:GetGuiInset().Y
	local blocks = uiBlocks()
	local cands = {}
	for _, c in herd do
		local dist = (c.body.Position - camPos).Magnitude
		if c ~= mount and c.fade < 0.5 and dist <= C.NameTagDistance then
			table.insert(cands, { c = c, dist = dist, key = (c.box.Visible and 0 or 1e4) + dist })
		else
			c.tag.Enabled = false
		end
	end
	table.sort(cands, function(x, y)
		return x.key < y.key
	end)
	local placed = {}
	local perPx = 2 * math.tan(math.rad(cam.FieldOfView) / 2) / cam.ViewportSize.Y -- studs per px at depth 1
	local h = U.TagSize.Y + U.TagStackGap
	for i, e in cands do
		local c = e.c
		local base = c.size.Y / 2 + 2.5
		local sp, on = cam:WorldToViewportPoint(c.body.Position + cam.CFrame.UpVector * base)
		if i > U.TagMax or not on then
			c.tag.Enabled = false
			continue
		end
		local w = math.min(c.tagLabel.TextBounds.X, U.TagSize.X) + 8
		local y = sp.Y
		local moved = true
		while moved do -- y only ever decreases, so this ends
			moved = false
			for _, r in placed do
				if math.abs(sp.X - r.x) < (w + r.w) / 2 and math.abs(y - r.y) < h then
					y = r.y - h
					moved = true
				end
			end
		end
		local onUi = false
		for _, g in blocks do
			local p0, p1 = g.AbsolutePosition, g.AbsolutePosition + g.AbsoluteSize
			local gy = y - inset
			if sp.X + w / 2 > p0.X and sp.X - w / 2 < p1.X and gy + h / 2 > p0.Y and gy - h / 2 < p1.Y then
				onUi = true
				break
			end
		end
		if onUi then
			c.tag.Enabled = false
			continue
		end
		table.insert(placed, { x = sp.X, y = y, w = w })
		c.tag.StudsOffset = Vector3.new(0, base + (sp.Y - y) * perPx * sp.Z, 0)
		local fade = math.clamp((e.dist - U.TagFadeStart) / (C.NameTagDistance - U.TagFadeStart), 0, 1)
		c.tagLabel.TextTransparency = fade
		c.tagLabel.TextStrokeTransparency = 0.3 + 0.7 * fade
		c.tag.Enabled = true
	end
end

-- Herd pool (P2, SECTIONS-PLAN section 3) ---------------------------------------------------------
-- Only biomes overlapping the window [rider - Pool.Behind, rider + Pool.Ahead] have live creatures, each a
-- quota proportional to its overlap (so about PerLane x LaneCount in all, also across a border). The rider
-- d is the leap, else the mount, else the jump target, else the rider on foot. Each frame, an unridden live
-- creature that is out of view (outside RecycleClear behind .. RecycleAhead ahead) is parked when it has
-- left the window or its biome, or its biome is over quota; then each biome is topped up from its parked
-- creatures (species by weight, commons balanced) into a free slot out of view: slow ones ahead (anywhere past
-- the section's ViewDist up to Ahead) so the rider catches them, faster ones behind so they overtake. Only the
-- rider's own biome comes from behind, and there it may start up to Behind below its start, so a new
-- section fills in right after the border and a rider on foot near the bottom still gets passed. A rider
-- move over Pool.Jump in one frame (debug teleport, summit reset) re-lays the window at once, view or not.
-- Nothing runs while on the summit. herdStats.seenRecycles counts any appear / vanish in view (expect 0).
-- Herd fix (HERD-SIM.md): quotas use each zone's Herd; past its own biome an unridden creature tires (Pool.Tire)
-- and drops behind the rider, where it recycles; the lane solver lets pushed creatures step aside and anything
-- faster pull out from behind the ridden one; a swap target is never held still, so it can't drive into the mount.
local Pool = C.Pool
local lastR -- rider d last pool step
local herdDirty = false

local function protected(c)
	return c == mount or c == target or c == probe or (leap ~= nil and c == leap.from)
end
-- Per-section view distances (P4 fog table), read at the rider's section.
local function viewDist(r)
	return Pool.ViewDist[zoneOf(math.clamp(r or 0, 0, P.Total - 1))]
end
local function recycleAhead(r)
	return C.RecycleAhead[zoneOf(math.clamp(r, 0, P.Total - 1))]
end
local function inSeen(d, r)
	return d > r - C.RecycleClear and d < r + recycleAhead(r)
end
-- BOT measure, independent of the d bands that gate recycling: is this point on screen within the section's Pool.ViewDist?
-- Not counted for JumpQuiet s after a jump re-lay (a debug teleport; the lagged ride camera is still on its way).
local quietUntil = 0
local function onScreen(pos)
	if os.clock() < quietUntil then
		return false
	end
	local cam = workspace.CurrentCamera
	local v, on = cam:WorldToViewportPoint(pos)
	return on and v.Z > 0 and v.Z < viewDist(lastR)
end
local function park(c, r, quiet)
	if not quiet and c.fade < 0.95 and onScreen(c.body.Position) then
		herdStats.seenRecycles += 1 -- vanished on screen
		herdStats.seenLog = herdStats.seenLog or {}
		table.insert(herdStats.seenLog, string.format("park %s %s d%.0f r%.0f", state, c.name, c.d, r))
	end
	c.parked, c.despawnT = true, nil
	c.model.Parent = nil
	c.tag.Enabled, c.box.Visible = false, false
	c.dip, c.xo, c.spd = nil, 0, c.spd0 -- (the BOT occlusion probe may have changed its tier)
	c.model:SetAttribute("Passing", nil)
	herdDirty = true
end
local function unpark(c, quiet)
	c.parked = false
	c.fade, c.applied = quiet and 0 or 1, nil -- not quiet: fades in over c.fadeDur (fadeOccluders)
	c.spawnT = not quiet and os.clock() or nil
	-- P4: a respawn ahead of the rider is readable out to Pool.Readable, so it fades in over FarFade (not FadeIn)
	c.fadeDur = (lastR and c.d > lastR) and Pool.FarFade or Pool.FadeIn
	if not quiet and c.fadeDur < Pool.FarFade then
		local cam = workspace.CurrentCamera
		local v, on = cam:WorldToViewportPoint(creatureCF(c).Position)
		if on and v.Z > 0 and v.Z < Pool.Readable[zoneOf(math.clamp(lastR or 0, 0, P.Total - 1))] and os.clock() >= quietUntil then
			herdStats.fastPops += 1 -- a quick fade-in where a player could read it (expect 0)
		end
	end
	if not quiet and onScreen(creatureCF(c).Position) then
		herdStats.seenRecycles += 1 -- appeared on screen (even though it fades in)
		herdStats.seenLog = herdStats.seenLog or {}
		table.insert(herdStats.seenLog, string.format("spawn %s %s d%.0f r%.0f", state, c.name, c.d, lastR or -1))
	end
	c.model.Parent = herdFolder
	if c.gallop then
		if not c.gallop.IsPlaying then
			c.gallop:Play(0)
		end
		c.gallop.TimePosition = math.random() * c.gallop.Length
	end
	herd[#herd + 1] = c -- live at once, so the next placement this frame sees it
	herdStats.recycles += 1
	herdDirty = true
end
local function freeAt(c, lane, d)
	for _, o in herd do -- same layer as the lane solver: ground, or all flyers together
		if o ~= c and not o.parked and o.lane == lane and (o.fly > 0) == (c.fly > 0)
			and math.abs(o.d - d) < (o.size.Z + c.size.Z) / 2 + C.LaneGap then
			return false
		end
	end
	return true
end
-- Give c a free (lane, d) inside [lo, hi]; true on success. prefLane (a rider on foot) is tried first.
local function place(c, lo, hi, r, quiet, prefLane)
	if hi - lo < 1 then
		return false
	end
	for t = 1, Pool.Tries do
		local d = lo + math.random() * (hi - lo)
		local lane = t == 1 and prefLane or math.random(1, C.LaneCount)
		if freeAt(c, lane, d) then
			c.d, c.lane, c.xo, c.passT = d, lane, 0, 0
			return true
		end
	end
	return false
end
-- Out-of-view bands to try for c of biome k (rider at r in biome rk, rider ground speed riderV; 0 on foot).
-- Ahead starts past the section's ViewDist (and RecycleAhead), so a respawn is too small to read yet.
local function bandsFor(c, k, r, rk, riderV)
	local s, e = P.Starts[k], math.min(P.zoneEnd(k), P.Total) - 1
	local hi = math.min(e, r + Pool.Ahead)
	local near = math.max(recycleAhead(r), viewDist(r))
	local far = { math.max(s, r + near), hi }
	local front = { math.max(s, r + near), hi }
	if k ~= rk then
		return { far, front }
	end
	local rear = { math.max(s - Pool.Behind, r - Pool.Behind), math.min(e, r - C.RecycleClear) }
	if speedAt(math.max(rear[2], 0)) * c.spd > riderV then -- ground speeds (the zone below runs slower)
		return { rear, far } -- it overtakes from behind (ahead it would only run out of the window)
	end
	return { far, front } -- the rider catches it (behind it would only drop out of the window)
end
-- Biome k's share of the window. The rider's biome also owns the part below its start it may spawn into; a
-- biome below the rider's gets none (its creatures still in view stay until they leave it).
local function quota(k, lo, hi, rk)
	if k < rk then
		return 0
	end
	local s = k == rk and P.Starts[k] - Pool.Behind or P.Starts[k]
	local ov = math.min(P.zoneEnd(k), hi) - math.max(s, lo)
	if ov <= 0 then
		return 0
	end
	return math.ceil((C.Zones[k].Herd or Pool.PerLane) * C.LaneCount * ov / (Pool.Behind + Pool.Ahead))
end
-- Parked creatures of biome k to try, in order: an extra species if the weighted roll hits, then the common
-- species from fewest to most live. One per species (they are interchangeable).
local function candidates(k)
	local w, live, parkedBy = speciesW[k], {}, {}
	for _, c in pools[k] do
		if c.parked then
			parkedBy[c.sp] = parkedBy[c.sp] or c
		else
			live[c.sp] = (live[c.sp] or 0) + 1
		end
	end
	local out = {}
	if w.extraW > 0 and math.random() < w.extraW / w.total then
		local roll = math.random() * w.extraW
		for _, e in w.extra do
			roll -= e.w
			if roll <= 0 then
				out[1] = parkedBy[e.i]
				break
			end
		end
	end
	local commons = {}
	for _, i in w.common do
		if parkedBy[i] then
			commons[#commons + 1] = i
		end
	end
	table.sort(commons, function(a, b)
		return (live[a] or 0) < (live[b] or 0)
	end)
	for _, i in commons do
		out[#out + 1] = parkedBy[i]
	end
	return out
end

local function poolStep(r, jump)
	if jump then
		quietUntil = os.clock() + Pool.JumpQuiet
	end
	local lo, hi = r - Pool.Behind, r + Pool.Ahead
	local rk = zoneOf(math.clamp(r, 0, P.Total - 1))
	local rspd = (leap and leap.spd) or (mount and mount.spd) or 0
	for k in C.Zones do
		local s, e = P.Starts[k], P.zoneEnd(k)
		local q = quota(k, lo, hi, rk)
		-- On foot in this biome (P4 fix, sim --quota-natives): its tired stragglers past the biome's end no longer
		-- fill its quota, so fresh ones respawn behind and pick the rider up. Without it, near a border with the
		-- fog-table RecycleAhead the stragglers sat in the seen band and nothing came (sim: 60 s stuck).
		local skip = rspd == 0 and k == rk
		local function counted(c)
			return not (skip and c.d >= e and not protected(c))
		end
		-- live = staying, leaving = fading out ahead (P4 re-review: leavers no longer count as staying, so an excess
		-- of 1 fades out 1 creature, not every out-of-view one, and the rest don't snap back in when it parks)
		local live, leaving = 0, 0
		for _, c in pools[k] do
			if not c.parked and counted(c) then
				if c.despawnT then
					leaving += 1
				else
					live += 1
				end
			end
		end
		for _, c in pools[k] do
			if not c.parked and not protected(c) then
				local done = c.d >= P.Total and c.fade >= 0.95 -- faded out at the summit
				local outside = c.d < lo or c.d > hi or c.d < s - Pool.Behind or c.d >= e
				local over = if c.despawnT then live >= q else live > q
				if jump or done or (not inSeen(c.d, r) and (outside or over)) then
					if not jump and not done and c.d > r and c.fade < 0.95 then
						if not c.despawnT then -- ahead, maybe in sight up the slope: fade out first (FarFade)
							c.despawnT = os.clock()
							if counted(c) then
								live, leaving = live - 1, leaving + 1
							end
						end
					else
						local wasLeaving = c.despawnT ~= nil
						park(c, r, jump or done)
						if counted(c) then
							if wasLeaving then
								leaving -= 1
							else
								live -= 1
							end
						end
					end
				elseif c.despawnT then -- no longer leaving (quota rose again): back in as slowly as it left (FarFade)
					c.despawnT = nil
					c.fadeDur = Pool.FarFade
					c.spawnT = os.clock() - (1 - c.fade) * Pool.FarFade
					if counted(c) then
						live, leaving = live + 1, leaving - 1
					end
				end
			end
		end
		local budget = jump and math.huge or Pool.SpawnPerFrame
		local riderV = speedAt(math.max(r, 0)) * rspd
		local prefLane -- on foot: send respawns from behind down the rider's own lane, so one picks them up
		if rspd == 0 and k == rk and hrp and hrp.Parent then
			local _, px = P.project(hrp.Position)
			prefLane = math.clamp(math.floor(px / P.laneWidth(math.max(r, 0)) + (C.LaneCount + 1) / 2 + 0.5), 1, C.LaneCount)
		end
		while live + leaving < q and budget > 0 do -- (a leaver still holds its place until it parks)
			budget -= 1
			local got
			for _, c in candidates(k) do
				-- a biome ahead only gets creatures the rider can catch (a faster one would just run off)
				if jump or k == rk or speedAt(s) * c.spd < riderV then
					local ok = false
					if jump then
						ok = place(c, math.max(s, lo), math.min(math.min(e, P.Total) - 1, hi), r, true)
					else
						for _, b in bandsFor(c, k, r, rk, riderV) do
							if place(c, b[1], b[2], r, false, prefLane) then
								ok = true
								break
							end
						end
					end
					if ok then
						got = c
						break
					end
				end
			end
			if not got then
				break -- no species has a free slot this frame
			end
			unpark(got, jump)
			live += 1
		end
	end
	if herdDirty then
		herdDirty = false
		table.clear(herd)
		for k in C.Zones do
			for _, c in pools[k] do
				if not c.parked then
					herd[#herd + 1] = c
				end
			end
		end
	end
	herdStats.maxLive = math.max(herdStats.maxLive or 0, #herd)
end
local function reseedAt(d)
	lastR = d
	poolStep(d, true)
end

-- Summit: hold on the top pad, then back to the foothills onto the lowest creature in the middle lane.
local function sendToFoothills()
	reseedAt(-30)
	local mid = math.ceil(C.LaneCount / 2)
	local best -- a zone-1 ground creature, the middle lane first, then the lowest
	for _, h in herd do
		if h.zone == 1 and h.fly == 0 and h.d >= 0 and (not best
			or (h.lane == mid and best.lane ~= mid) or ((h.lane == mid) == (best.lane == mid) and h.d < best.d)) then
			best = h
		end
	end
	if not best then
		return false -- nothing placed yet: stay where we are and try again next frame
	end
	if best.d > 30 then -- HERD-SIM: start at the very bottom (the uniform re-lay often leaves 100-250 studs empty)
		place(best, 5, 30, -30, true, mid)
	end
	lastR = best.d -- the window follows the jump target from the next frame: not a second jump
	hrp.CFrame = onFoot(-30, 0)
	startJump(best)
	if not poolBuild.playableAt then
		poolBuild.playableAt = os.clock() - loadT0
		RepS:SetAttribute("SS_Playable", true) -- SS_Loading: the rider is mounted
		print(string.format("LOADREC playable: %.1f s after script start; background creatures built %d; game.IsLoaded %s; content queue %d",
			poolBuild.playableAt, poolBuild.bg, tostring(game:IsLoaded()),
			game:GetService("ContentProvider").RequestQueueSize))
	end
	if perf then
		perf:begin()
	end
	if remotes then -- P4 medals: the run starts at -30, so the server times section 1 from the d = 0 crossing
		remotes.Report:FireServer(-30, stats.score, true) -- flagged: the server starts a new run (SS_Progress spawn)
		reportT = 0
	end
	return true
end

local foothillsDue = false -- set by the summit hold and a (re)spawn; done at the top of the next frame so the
-- re-laid herd is moved before it renders
RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	if foothillsDue and hrp and hrp.Parent then
		foothillsDue = false
		if not sendToFoothills() then
			foothillsDue = true -- nothing to jump onto yet: try again next frame
		end
	end
	local parts, cfs = {}, {}
	local swing = math.rad(C.GallopSwing)
	local riderD = (leap and leap.d) or (mount and mount.d) or (target and target.d)
		or (hrp and hrp.Parent and state ~= "none" and (P.project(hrp.Position)))
	for _, c in herd do
		if c == mount or c == target then
			c.spd = c.spd0 -- a ridden (or targeted) creature never tires, even one caught while tiring
		elseif c.zone < #C.Zones and c.d >= P.zoneEnd(c.zone) and not protected(c) then -- a straggler tires and drops back
			c.spd = math.max(c.spd0 * Pool.Tire, c.spd - c.spd0 * Pool.TireRate * dt * timeScale)
		end
		local step = speedAt(c.d) * c.spd * dt * timeScale
		c.d += step
		if c.xo ~= 0 then
			c.xo *= math.exp(-C.PassEase * dt * timeScale)
			if math.abs(c.xo) < 0.01 then
				c.xo = 0
				c.model:SetAttribute("Passing", nil)
			end
		end
		c.phase += step * C.GallopPerStud
	end
	-- same lane: keep LaneGap nose-to-tail (followers wait; a ridden or swap-target creature pushes ahead)
	local now = os.clock()
	local function overtake(c)
		c.passT = now + C.PassRetry
		for _, dl in (math.random() < 0.5 and { -1, 1 } or { 1, -1 }) do
			local nl = c.lane + dl
			if nl >= 1 and nl <= C.LaneCount then
				local free = true
				for _, o in herd do
					if o ~= c and o.lane == nl and (o.fly > 0) == (c.fly > 0) -- same layer as the lane solver
						and math.abs(o.d - c.d) < (o.size.Z + c.size.Z) / 2 + C.LaneGap then
						free = false
						break
					end
				end
				if free then
					c.xo += laneX(c.lane, c.d) - laneX(nl, c.d)
					c.lane = nl
					c.model:SetAttribute("Passing", true) -- BOT: off the lane centre while it eases across
					return true
				end
			end
		end
		return false
	end
	local lanes = {}
	for _, c in herd do
		local key = c.fly > 0 and -c.lane or c.lane -- flyers keep their gap in the air layer
		local l = lanes[key]
		if not l then
			l = {}
			lanes[key] = l
		end
		l[#l + 1] = c
	end
	for key, l in lanes do
		local lane = math.abs(key)
		table.sort(l, function(a, b)
			return a.d > b.d
		end)
		local function need(lead, c) -- the lead's d that leaves LaneGap in front of c
			return c.d + (lead.size.Z + c.size.Z) / 2 + C.LaneGap
		end
		local function fixed(c)
			return c == mount or c == probe -- the BOT occlusion probe is parked on purpose
		end
		-- everyone else waits behind its leader (a swap target too: it never drives into the mount); a faster one
		-- blocked by a slower leader pulls out into a neighbouring lane with room instead (M8 part 3: speed tiers,
		-- so runners pass you). Behind the ridden creature any speed edge is enough. The lead is the nearest one
		-- still in this lane: one that just pulled out would otherwise drag c back into the gap behind it.
		local lead
		for _, c in l do
			if lead and not fixed(c) and lead ~= probe and lead.d < need(lead, c) then
				if c ~= target and c.spd > lead.spd * (lead == mount and 1 or 1.05) and now >= c.passT and overtake(c) then
					continue
				end
				c.d = lead.d - (lead.size.Z + c.size.Z) / 2 - C.LaneGap
			end
			if c.lane == lane then
				lead = c
			end
		end
		-- Then the ridden creature pushes the chain ahead of it; a pushed one steps into a free lane when it can
		-- (HERD-SIM: no endless convoy in front of you). A swap target is pushed like any other but keeps its lane.
		-- After the followers (P4 re-review): run first, a follower clamp behind a slow leader could pull a pushed
		-- creature back into the mount's gap (frame-rate dependent). One that pulled out this frame left the chain.
		for i = #l, 2, -1 do
			if l[i] == mount then
				local behind = mount
				for j = i - 1, 1, -1 do
					local lj = l[j]
					if lj.lane == lane then
						if fixed(lj) or lj.d >= need(lj, behind) then
							break
						end
						if lj ~= target and now >= lj.passT and overtake(lj) then
							break
						end
						lj.d = need(lj, behind)
						behind = lj
					end
				end
			end
		end
	end
	-- the pool follows the rider (after the lane gaps, so a creature pushed out of its biome recycles now):
	-- a ridden creature carries on up the mountain; the rest recycle out of view. Frozen on the summit.
	if riderD and state ~= "summit" then
		local jump = lastR ~= nil and math.abs(riderD - lastR) > Pool.Jump
		lastR = riderD
		poolStep(riderD, jump)
	end
	for _, c in herd do
		local cf = creatureCF(c)
		if c.dip then -- a landing rider pushes the back down, then it springs up
			cf *= CFrame.new(0, -L.Dip * math.sin(c.dip * math.pi), 0)
			c.dip = c.dip > 0.02 and c.dip - dt * 3 or nil
		end
		if c.gallop then -- skinned: the clip runs one stride per GallopClip seconds; match the ground speed
			c.gallop:AdjustSpeed(speedAt(c.d) * c.spd * C.GallopPerStud / (2 * math.pi) * C.GallopClip * timeScale)
		end
		placeParts(c, cf, parts, cfs, swing)
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)

	if not hrp or not hrp.Parent or state == "none" then
		return
	end
	stateT += dt
	local now = os.clock()
	local wob = math.sin(now * C.WobbleHz * math.pi * 2)

	for _, c in herd do
		c.box.Visible = state == "ride" and c ~= mount and (c.body.Position - mount.body.Position).Magnitude <= C.SwapRange
	end

	if state == "ride" then
		stats.score += speedAt(mount.d) * mount.spd * dt * C.ScoreRate * mount.score
		hrp.CFrame = seatCF(mount)
		pose(POSE_RIDE)
		hint.Text = "Tap / click a highlighted creature to swap"
		if mount.d >= P.Total then
			stats.summits += 1
			hrp.CFrame = onFoot(P.Total + 20, 0)
			mount = nil -- it fades out at the top and rejoins its pool on the summit reset
			summitPrep = nil
			task.spawn(function() -- stream the foothills in during the hold (STREAMING-PLAN B4)
				prepare(-30)
				summitPrep = true
			end)
			enter("summit")
			if perf then
				perf:summit()
			end
		end
	elseif state == "summit" then
		pose({})
		hint.Text = "SUMMIT! Back to the foothills..."
		if stateT >= C.SummitHold and (summitPrep or stateT >= C.SummitHold + C.Stream.PrepareTimeout) then
			foothillsDue = true
		end
	elseif state == "stance" or state == "ring" then
		hrp.CFrame = standCF(mount)
		local amp = C.WobbleAmp * (state == "stance" and math.min(stateT / C.StanceTime, 1) or 1)
		pose({
			LeftHip = A(30), RightHip = A(30), LeftKnee = A(-45), RightKnee = A(-45),
			Waist = A(-10, 0, amp * wob), Root = A(0, 0, -amp * 0.5 * wob), Neck = A(0, 0, -amp * 0.6 * wob),
			LeftShoulder = A(0, 0, -80 + 25 * wob), RightShoulder = A(0, 0, 80 + 25 * wob),
		})
		if state == "stance" then
			hint.Text = "Steady..."
			if stateT >= C.StanceTime then
				enter("ring")
				ring.Adornee = target.body
				ring.Enabled = true
			end
		else
			local s = C.RingStartScale * (1 - stateT / C.RingDuration)
			local px = ringPx * s / C.TargetScale
			shrinkCircle.Size = UDim2.fromOffset(px, px)
			shrinkStroke.Color = math.abs(s - C.TargetScale) <= C.SuccessWindow and Color3.fromRGB(120, 255, 140) or Color3.new(1, 1, 1)
			hint.Text = "Tap / Space when the rings match!"
			if pendingPress and stateT >= pendingPress then
				pendingPress = nil
				press()
			elseif stateT >= C.RingDuration then
				fail("timeout")
			end
		end
	elseif state == "jump" then
		local a = math.min(stateT / C.JumpTime, 1)
		local to = seatCF(target)
		local p = jumpFrom:Lerp(to.Position, a) + to.UpVector * (C.JumpHeight * 4 * a * (1 - a))
		hrp.CFrame = to.Rotation + p
		pose({ LeftHip = A(60), RightHip = A(60), LeftKnee = A(-90), RightKnee = A(-90), LeftShoulder = A(160), RightShoulder = A(160) })
		hint.Text = ""
		if a >= 1 then
			mountOn(target)
			target = nil
		end
	elseif state == "leap" then
		leapStep(dt)
	elseif state == "fall" then
		local a = math.min(stateT / C.FaceplantTime, 1)
		local e = 1 - (1 - a) ^ 2
		local p = fallFrom.Position:Lerp(fallTo.Position, e) + surf(P.project(fallTo.Position), 0).UpVector * (5 * math.sin(math.min(a * 2, 1) * math.pi))
		hrp.CFrame = fallFrom.Rotation:Lerp(fallTo.Rotation, math.min(a * 3, 1)) + p
		pose({ LeftShoulder = A(170), RightShoulder = A(170), LeftHip = A(-15), RightHip = A(-15) })
		hint.Text = "FACEPLANT!"
		if a >= 1 then
			pose(nil)
			for _, m in motors do
				m.Transform = CFrame.identity
			end
			hrp.CFrame = onFoot(P.project(fallTo.Position))
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = Vector3.zero
			hum.PlatformStand = false
			setAnimated(true)
			freeSince = now
			enter("free")
		end
	elseif state == "free" then
		hint.Text = "Wait for the next creature in your lane..."
		if now - freeSince >= C.RemountGrace then
			local pd, px = P.project(hrp.Position)
			local c = nearestInLane(pd, px, C.RemountRange)
			if c then
				stats.remounts += 1
				stats.lastRemountWait = now - fallClock
				startJump(c)
			end
		end
	end

	local d = mount and mount.d or P.project(hrp.Position)
	local follow = mount or target
	if state == "summit" then
		summitCamera()
	elseif state == "leap" and leap then
		local ad, ax = leapAim()
		leapCamera(dt, ad, ax)
	elseif follow and state ~= "fall" then
		rideCamera(dt, follow.d, laneX(follow.lane, follow.d), speedAt(follow.d) * follow.spd, follow == mount and follow.fly or 0)
	elseif state == "fall" and camPos then
		local pd, px = P.project(hrp.Position)
		rideCamera(dt, pd, px, 0)
	else
		freeCamera()
	end
	local cam = workspace.CurrentCamera
	fadeOccluders(dt, cam, hrp.Position + hrp.CFrame.UpVector * 1.5)
	scoreLabel.Text = string.format("%d%s", math.floor(stats.score), mount and mount.score > 1 and ("  x" .. mount.score) or "")
	shop:setZone(zoneOf(math.clamp(d, 0, P.Total)))
	journal:setZone(zoneOf(math.clamp(d, 0, P.Total)))
	feedT += dt
	if remotes and feedT >= 1 / C.Stream.FeedHz then -- SS_Stream: the server's streaming focus follows the ride
		feedT = 0
		local ev = remotes:FindFirstChild("Rider")
		if ev then
			ev:FireServer(d, os.clock()) -- the client's clock: the server measures speed from it
		end
	end
	reportT += dt
	if remotes and reportT >= C.Progress.ReportEvery then
		reportT = 0
		remotes.Report:FireServer(d, stats.score)
	end
	timeline:update(dt, d, mount, state)
	layoutTags(cam)
	if U.DebugHud then
		local k = zoneOf(math.max(d, 0))
		hud.Text = string.format("Zone %d %s | %d/%d studs | herd %.0f st/s%s", k, C.Zones[k].Name, d, P.Total, speedAt(d),
			mount and (" | " .. mount.name) or "")
	end
end)

-- Spawn -----------------------------------------------------------------------------------------
local function onCharacter(c)
	state = "none"
	-- a respawn mid-ride: drop the old ride so the pool window follows the new rider (P2 review)
	mount, target, leap, probe, pendingPress, lastR = nil, nil, nil, nil, nil, nil
	endLeapFx()
	ring.Enabled = false
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")
	animate = c:WaitForChild("Animate", 5)
	c:WaitForChild("UpperTorso")
	task.wait(0.5)
	motors = {}
	for _, m in c:GetDescendants() do
		if m:IsA("Motor6D") or m:IsA("AnimationConstraint") then -- new avatar joints are AnimationConstraints
			motors[m.Name] = m
		end
	end
	foothillsDue = true
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

local fogFolder, fogCache -- BOT fog targets (debug action fogTargets)
-- Studio-only debug hook for BOT checks (MCP Luau runs in its own VM).
if RunService:IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "SS_Debug"
	bf.OnInvoke = function(action, arg)
		if action == "state" then
			local d = mount and mount.d or -1
			return {
				state = state, d = d, zone = zoneOf(math.max(d, 0)), speed = speedAt(math.max(d, 0)), stats = stats,
				mount = mount and mount.name, mountZone = mount and mount.zone,
			}
		elseif action == "swapNearest" then
			local best, bd
			for _, c in herd do
				if mount and c ~= mount then
					local dist = (c.body.Position - mount.body.Position).Magnitude
					if dist <= C.SwapRange and (not bd or dist < bd) then
						best, bd = c, dist
					end
				end
			end
			return best ~= nil and startSwap(best)
		elseif action == "perfCard" then -- BOT 8e: the perf card filled with the widest values (or hide it)
			if not perf then
				return nil
			end
			if arg == "hide" then
				perf.card.Visible = false
				return true
			end
			perf:widest()
			return true
		elseif action == "pressAt" then -- seconds into the ring
			pendingPress = arg
			return true
		elseif action == "tune" then -- live-edit config values (Studio only)
			for k, v in arg do
				C[k] = v
			end
			return true
		elseif action == "idealPress" then
			return C.RingDuration * (C.RingStartScale - C.TargetScale) / C.RingStartScale
		elseif action == "speedTable" then
			local out = {}
			for k in C.Zones do
				for _, dd in { P.Starts[k], P.zoneEnd(k) - 1 } do
					out[tostring(dd)] = string.format("%.1f st/s, lane %.1f", speedAt(dd), P.laneWidth(dd))
				end
			end
			return out
		elseif action == "teleport" then -- move the ridden creature to distance arg
			probe = nil -- an occlusion-probe creature rejoins the pool
			if mount then
				prepare(arg) -- stream the ground in before the jump (yields up to Stream.PrepareTimeout)
				if not mount then -- the summit or a failed ring cleared it during the yield
					return false
				end
				mount.d = arg
			end
			return mount ~= nil
		elseif action == "fogTargets" then -- BOT fog: section arg.k's common species, one per lane at arg.d, standing
			-- still (real models: zone-1 skinned meshes, greybox elsewhere); returns their folder and models. nil clears.
			fogFolder = fogFolder or Instance.new("Folder")
			fogFolder.Name = "SS_FogTargets"
			if not arg then
				fogFolder:ClearAllChildren()
				fogCache = {}
				return fogFolder, {}
			end
			fogCache = fogCache or {}
			if not fogCache[arg.k] then
				fogFolder:ClearAllChildren()
				fogCache = { [arg.k] = {} }
				local lane = 0
				for sp, spec in C.Species[arg.k] do
					if not spec.Rare and lane < C.LaneCount then
						lane += 1
						local c = makeCreature(arg.k, sp, lane, arg.d)
						if c.gallop then
							c.gallop:Stop(0)
						end
						c.model.Parent = fogFolder
						table.insert(fogCache[arg.k], c)
					end
				end
			end
			local parts, cfs, models = {}, {}, {}
			for _, c in fogCache[arg.k] do
				c.d, c.phase = arg.d, 0
				placeParts(c, creatureCF(c), parts, cfs, 0)
				models[#models + 1] = c.model
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
			return fogFolder, models
		elseif action == "stream" then -- BOT S1/S3: the last prepare, and a collision slab under the rider
			local track = workspace:FindFirstChild("SS_Track")
			local hit
			if track and hrp then
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Include
				rp.FilterDescendantsInstances = { track }
				local res = workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rp)
				hit = res and (hrp.Position.Y - res.Position.Y) or nil
			end
			return { prepare = lastPrepare, slab = hit, d = hrp and (P.project(hrp.Position)) or nil, state = state }
		elseif action == "timeline" then -- marker progress and the distance it was drawn for, same frame
			local p, td = timeline:progress()
			return { p = p, d = td }
		elseif action == "mountSpd" then -- set the ridden creature's speed tier (BOT 10d rides at tier 1); returns the old one
			local old = mount and mount.spd0
			if mount and arg then
				mount.spd, mount.spd0 = arg, arg
			end
			return old
		elseif action == "probeOff" then -- the occlusion probe rejoins the pool (solver clamps behind it again)
			probe = nil
			return true
		elseif action == "probeOcclusion" then -- park a creature at the camera (arg 0) or mid-way to the rider (0.5)
			if not mount or not camPos then
				return nil
			end
			local p = camPos:Lerp(hrp.Position, arg or 0)
			local pd, px = P.project(p)
			-- reuse the current probe creature (P2: herd order changes, and a second probe parked between the
			-- mount and the first one would hold that one inside the lane gap)
			local list = probe and { probe } or {}
			for _, c in herd do
				list[#list + 1] = c
			end
			for _, c in list do
				if c ~= mount and c.fly == 0 and c.zone == zoneOf(math.max(pd, 0)) then
					local bestLane, bestDx = 1, math.huge
					for lane = 1, C.LaneCount do
						local dx = math.abs(laneX(lane, pd) - px)
						if dx < bestDx then
							bestLane, bestDx = lane, dx
						end
					end
					c.lane, c.d, c.spd = bestLane, pd, mount.spd
					probe = c
					return c.name
				end
			end
			return nil
		elseif action == "camUp" then -- set the ride camera height (BOT occlusion probe); returns the old one
			local old = Cam.Up
			Cam.Up = arg
			return old
		elseif action == "probeFade" then
			return probe and probe.body.LocalTransparencyModifier
		elseif action == "herdStats" then -- recycles so far, those in view, and the tightest same-lane gap now
			local minGap, gapWho = math.huge, ""
			for _, a in herd do
				for _, b in herd do
					if a ~= b and a ~= probe and b ~= probe and a.lane == b.lane and (a.fly > 0) == (b.fly > 0) and a.d >= b.d then
						local g = a.d - b.d - (a.size.Z + b.size.Z) / 2
						if g < minGap then
							minGap = g
							gapWho = string.format("%s%s%s/%s%s%s", a.name, a == mount and "*" or "", a.despawnT and "~" or "",
								b.name, b == mount and "*" or "", b.despawnT and "~" or "")
						end
					end
				end
			end
			-- P2 pool: live count, biomes with live creatures, and unridden creatures outside their biome while
			-- out of the rider's view (must be 0: they recycle first)
			-- (a creature may run in from up to Pool.Behind below its biome); native = share of the creatures in
			-- view that belong to the rider's biome
			local biomes, mismatch, ahead, near, natives, r = {}, 0, 0, 0, 0, lastR
			local rk = r and zoneOf(math.clamp(r, 0, P.Total - 1))
			local free = 0 -- live count and biomes exclude mount, swap target and probe (they are held, not pooled)
			local stragglers, farBiomes, reach = 0, {}, 0 -- outside their biome; biomes out of view; in swap range
			for _, c in herd do
				if not protected(c) then
					biomes[c.zone] = true
					free += 1
					if c.d >= P.zoneEnd(c.zone) or c.d < P.Starts[c.zone] - C.Pool.Behind then
						stragglers += 1
					end
					if r and not inSeen(c.d, r) then
						farBiomes[c.zone] = true
					end
				end
				if mount and c ~= mount and (c.body.Position - mount.body.Position).Magnitude <= C.SwapRange then
					reach += 1
				end
				if r and c ~= mount and c.d > r and c.d < r + 300 then
					ahead += 1
				end
				if r and not protected(c) and not c.despawnT and not inSeen(c.d, r) -- (a fading-out one is leaving)
					and (c.d >= P.zoneEnd(c.zone) or c.d < P.Starts[c.zone] - C.Pool.Behind) then
					mismatch += 1
				end
				if r and c ~= mount and inSeen(c.d, r) then
					near += 1
					natives += c.zone == rk and 1 or 0
				end
			end
			local nb, nf = 0, 0
			for _ in biomes do
				nb += 1
			end
			for _ in farBiomes do
				nf += 1
			end
			return { recycles = herdStats.recycles, seenRecycles = herdStats.seenRecycles, fastPops = herdStats.fastPops,
				minGap = minGap, gapWho = gapWho,
				seenLog = table.concat(herdStats.seenLog or {}, "; ", math.max(1, #(herdStats.seenLog or {}) - 7)),
				live = free, maxLive = herdStats.maxLive or 0, biomes = nb, mismatch = mismatch, ahead = ahead,
				native = near > 0 and natives / near or 1, stragglers = stragglers, farBiomes = nf, reach = reach, r = r }
		elseif action == "progress" then -- P3: last profile view, effective swap tunables, report inputs
			return { profile = profile, score = stats.score,
				tune = { SuccessWindow = C.SuccessWindow, StanceTime = C.StanceTime, WobbleAmp = C.WobbleAmp },
				base = BASE, shopVisible = shop.open.Visible, coinsText = shop.coins.Text }
		elseif action == "herdInfo" then -- species found inside each zone right now
			local out = {}
			for k in C.Zones do
				out[k] = {}
			end
			for _, c in herd do
				local k = zoneOf(math.max(c.d, 0))
				out[k][c.name] = (out[k][c.name] or 0) + 1
			end
			return out
		end
		return nil
	end
	bf.Parent = RepS
end
