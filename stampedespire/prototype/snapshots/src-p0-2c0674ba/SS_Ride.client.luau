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
local herdStats = { recycles = 0, seenRecycles = 0 } -- BOT: recycles that happened in the rider's view

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
local function decorate(body, spec, height)
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
	local box = Instance.new("SelectionBox")
	box.Adornee = body
	box.LineThickness = 0.08
	box.Color3 = Color3.fromRGB(255, 220, 80)
	box.Visible = false
	box.Parent = body
	return tag, tl, box
end

local creatureRoot = RepS:FindFirstChild("SS_Creatures")
local creatureModels = creatureRoot and creatureRoot:FindFirstChild("Models")
local clipIds = {} -- model -> clip -> local content id (Studio test sessions; uploaded ids come with the sign-off)
local function clipId(model, clip)
	clipIds[model] = clipIds[model] or {}
	if not clipIds[model][clip] then
		local ks = creatureRoot.Clips[model][clip]
		clipIds[model][clip] = game:GetService("AnimationClipProvider"):RegisterAnimationClip(ks)
	end
	return clipIds[model][clip]
end

-- Skinned creature (M8): one MeshPart + bones, played by an Animator. The MeshPart is the body (pick/seat/
-- ring target); the frame is the mesh centre, SizeY/2 above the lane, forward = -Z.
local function makeMeshCreature(zone, spec, tpl, lane, d)
	local m = tpl:Clone()
	m.Name = spec.Name
	local body = m.PrimaryPart
	local size = body.Size
	local tag, tl, box = decorate(body, spec, size.Y)
	m.Parent = herdFolder
	local ctl = m:FindFirstChildWhichIsA("AnimationController") or Instance.new("AnimationController", m)
	local animator = ctl:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", ctl)
	local a = Instance.new("Animation")
	a.AnimationId = clipId(spec.Model, "gallop")
	local gallop = animator:LoadAnimation(a)
	gallop.Looped = true
	gallop:Play(0)
	local c = {
		model = m, body = body, pieces = {}, legPhase = {}, box = box, lane = lane, d = d, zone = zone,
		name = spec.Name, size = size, tag = tag, tagLabel = tl, parts = { body }, fade = 0, gallop = gallop,
		seat = Vector3.new(0, body:GetAttribute("SeatUp"), body:GetAttribute("SeatBack")),
		spd = spec.Speed * (1 + (math.random() * 2 - 1) * C.SpeedJitter), phase = math.random() * 6,
		fly = spec.Fly or 0, score = spec.Score or 1, rare = spec.Rare, xo = 0, passT = 0,
	}
	herd[#herd + 1] = c
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
	local tag, tl, box = decorate(body, spec, spec.Size.Y)
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
	herd[#herd + 1] = c
	return c
end

-- Each zone's herd starts spread over its own zone; common species (Weight 1) mix across lanes, and each
-- slot may instead roll an extra species (big, rare, flyer) by its Weight.
for zone, z in C.Zones do
	local s = P.Starts[zone]
	local common, extra, total, extraW = {}, {}, 0, 0
	for i, spec in C.Species[zone] do
		local w = spec.Weight or 1
		total += w
		if w < 1 then
			extra[#extra + 1] = i
			extraW += w
		else
			common[#common + 1] = i
		end
	end
	for lane = 1, C.LaneCount do
		for k = 1, C.HerdPerLane do
			local sp = common[(lane + k) % #common + 1]
			if math.random() < extraW / total then
				local r = math.random() * extraW
				for _, i in extra do
					r -= C.Species[zone][i].Weight
					if r <= 0 then
						sp = i
						break
					end
				end
			end
			makeCreature(zone, sp, lane, s + ((k - 1) / C.HerdPerLane * z.Length + lane * 41) % z.Length)
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
	local shake = Cam.Shake * speed / math.max(C.BaseSpeed, 1) + shakeT
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
		if c.fade > 0.3 then -- a faded creature hugging the camera would draw a huge outline
			c.box.Visible = false
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

-- Summit: hold on the top pad, then back to the foothills onto the lowest creature in the middle lane.
local function sendToFoothills()
	local mid = math.ceil(C.LaneCount / 2)
	local best
	for _, h in herd do
		if h.zone == 1 and h.lane == mid and (not best or h.d < best.d) then
			best = h
		end
	end
	hrp.CFrame = onFoot(-30, 0)
	startJump(best)
end

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local parts, cfs = {}, {}
	local swing = math.rad(C.GallopSwing)
	local riderD = (mount and mount.d) or (target and target.d) or (hrp and hrp.Parent and (P.project(hrp.Position)))
	for _, c in herd do
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
		-- unridden creatures stay in their own zone; a ridden one carries on up the mountain. They recycle
		-- out of the rider's view, so nobody vanishes ahead or pops in beside you.
		local zEnd = P.zoneEnd(c.zone)
		if c.d >= zEnd and c ~= mount and c ~= target then
			local seen = riderD and c.d - riderD < C.RecycleAhead and c.d > riderD - C.RecycleClear
			if not seen or (c.d >= P.Total and c.fade >= 0.95) then
				local start = P.Starts[c.zone]
				local nd = start + (c.d - zEnd) % C.Zones[c.zone].Length
				if riderD and math.abs(nd - riderD) < C.RecycleClear then
					nd = riderD - C.RecycleClear -- may sit just below the zone start: still behind the camera
				end
				if (seen and c.fade < 0.95) or (riderD and math.abs(nd - riderD) < C.RecycleClear) then
					herdStats.seenRecycles += 1
				end
				herdStats.recycles += 1
				c.d = nd
			end
		end
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
					if o ~= c and o.lane == nl and o.fly == c.fly
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
	for _, l in lanes do
		table.sort(l, function(a, b)
			return a.d > b.d
		end)
		local function need(lead, c) -- the lead's d that leaves LaneGap in front of c
			return c.d + (lead.size.Z + c.size.Z) / 2 + C.LaneGap
		end
		local function fixed(c)
			return c == mount or c == target or c == probe -- the BOT occlusion probe is parked on purpose
		end
		-- a ridden (or swap-target) creature pushes the chain ahead of it
		for i = #l, 2, -1 do
			if fixed(l[i]) and l[i] ~= probe then
				for j = i - 1, 1, -1 do
					if fixed(l[j]) or l[j].d >= need(l[j], l[j + 1]) then
						break
					end
					l[j].d = need(l[j], l[j + 1])
				end
			end
		end
		-- everyone else waits behind its leader; a faster one blocked by a slower leader pulls out into a
		-- neighbouring lane with room instead (M8 part 3: speed tiers, so runners pass you)
		for i = 2, #l do
			local lead, c = l[i - 1], l[i]
			if not fixed(c) and lead ~= probe and lead.d < need(lead, c) then
				if c.spd > lead.spd * 1.05 and now >= c.passT and overtake(c) then
					continue
				end
				c.d = lead.d - (lead.size.Z + c.size.Z) / 2 - C.LaneGap
			end
		end
	end
	for _, c in herd do
		local cf = creatureCF(c)
		parts[#parts + 1] = c.body
		if c.dip then -- a landing rider pushes the back down, then it springs up
			cf *= CFrame.new(0, -L.Dip * math.sin(c.dip * math.pi), 0)
			c.dip = c.dip > 0.02 and c.dip - dt * 3 or nil
		end
		if c.gallop then -- skinned: the clip runs one stride per GallopClip seconds; match the ground speed
			cfs[#cfs + 1] = cf
			c.gallop:AdjustSpeed(speedAt(c.d) * c.spd * C.GallopPerStud / (2 * math.pi) * C.GallopClip * timeScale)
		else
			cfs[#cfs + 1] = cf * CFrame.new(0, c.size.Y * 0.175, 0)
		end
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
			mount = nil -- it wraps back to its own zone next frame
			enter("summit")
		end
	elseif state == "summit" then
		pose({})
		hint.Text = "SUMMIT! Back to the foothills..."
		if stateT >= C.SummitHold then
			sendToFoothills()
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
	sendToFoothills()
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

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
			if mount then
				mount.d = arg
			end
			return mount ~= nil
		elseif action == "timeline" then -- marker progress and the distance it was drawn for, same frame
			local p, td = timeline:progress()
			return { p = p, d = td }
		elseif action == "probeOcclusion" then -- park a creature at the camera (arg 0) or mid-way to the rider (0.5)
			if not mount or not camPos then
				return nil
			end
			local p = camPos:Lerp(hrp.Position, arg or 0)
			local pd, px = P.project(p)
			for _, c in herd do
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
			local minGap = math.huge
			for _, a in herd do
				for _, b in herd do
					if a ~= b and a ~= probe and b ~= probe and a.lane == b.lane and a.fly == b.fly and a.d >= b.d then
						minGap = math.min(minGap, a.d - b.d - (a.size.Z + b.size.Z) / 2)
					end
				end
			end
			return { recycles = herdStats.recycles, seenRecycles = herdStats.seenRecycles, minGap = minGap }
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
