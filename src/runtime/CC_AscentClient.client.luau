-- CC_AscentClient (StarterPlayerScripts): V3 hazards, knockback/stagger, fall reporting, checkpoint toast.
-- Hazards are deterministic: phase = (GetServerTimeNow() + Offset) % Period, so every client sees the same cycle
-- with no network traffic and no server work. Each client animates hazards locally (within ACTIVE_RANGE) and
-- applies hits only to its own character (character physics is client-owned; hits never grant anything).
-- Cycle: [0, Tell) tell (shake / dust / shadow strip / whipping flags), then the action, then rest.
-- Hits = knockback + short stagger, no HP damage (LOCKED). Falls are reported to CC_CheckpointService.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

local plr = Players.LocalPlayer
local ACTIVE_RANGE = 250
local FALL_DROP = 24
local SLATE = Color3.fromRGB(62, 66, 76) -- charcoalSlate token (shadow strips)
local MOON = Color3.fromRGB(220, 230, 255) -- moonlight token (dust, snow)

local remotes = RS:WaitForChild("CC_Remotes", 30)
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }

---------------------------------------------------------------- knockback / stagger
local lastHit = 0
local function knock(dir, strength)
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or os.clock() - lastHit < 1.2 then
		return
	end
	lastHit = os.clock()
	-- a climber on a face slips instead (CC_ClimbClient: slide + catch window), no ground knockback
	local cs = ch:GetAttribute("CC_TraversalState")
	if cs == "climb" or cs == "rope" or cs == "hanging" then
		remotes.CoreRequest:FireServer("traversal", { action = "slip" })
		return
	end
	if cs == "flight" then return end
	local d = Vector3.new(dir.X, 0, dir.Z)
	d = (d.Magnitude > 0.01) and d.Unit or Vector3.zAxis
	hrp.AssemblyLinearVelocity = d * strength + Vector3.new(0, 18, 0)
	hum.PlatformStand = true
	task.delay(0.45, function()
		if hum.Parent and plr.Character == ch then
			hum.PlatformStand = false
		end
	end)
end

---------------------------------------------------------------- hazard state
local hazards = {} -- model -> runtime table
local function attr(m, k)
	return m:GetAttribute(k)
end

local function setup(m)
	local h = {
		m = m,
		kind = attr(m, "Kind"),
		period = attr(m, "Period"),
		tell = attr(m, "Tell"),
		offset = attr(m, "Offset") or 0,
		strength = attr(m, "Strength"),
		center = attr(m, "Center"),
		dir = attr(m, "TrailDir"),
		out = attr(m, "Outward"),
	}
	if not h.kind or not h.center then
		return nil
	end
	if h.kind == "TreeFall" then
		h.tree = m:FindFirstChild("FallTree")
		h.hinge = attr(m, "Hinge")
		h.len = attr(m, "FallLen")
		h.rest = h.tree and h.tree:GetPivot()
	elseif h.kind == "Rockfall" or h.kind == "Avalanche" then
		h.top, h.bot, h.radius = attr(m, "Top"), attr(m, "Bottom"), attr(m, "Radius")
		h.straight = attr(m, "Straight") -- authored chutes (v4): the rock follows the top->bottom line, no ground snap
	elseif h.kind == "Gust" then
		h.len, h.half = attr(m, "Length"), attr(m, "HalfWidth")
		h.flags = {}
		for _, c in ipairs(m:GetChildren()) do
			if c.Name == "WindFlag" then
				h.flags[#h.flags + 1] = { p = c, cf = c.CFrame }
			end
		end
	end
	return h
end

local function localPart(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = workspace.CurrentCamera
	return p
end

-- shadow strip on the trail during the tell (pulses; shape + motion carry the warning, no new color)
local function strip(h, a, b, width)
	if not h.strip then
		h.strip = localPart({ Size = Vector3.new(width, 0.2, 1), Material = Enum.Material.SmoothPlastic, Color = SLATE, Transparency = 1 })
	end
	local len = (b - a).Magnitude
	h.strip.Size = Vector3.new(width, 0.2, len)
	h.strip.CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.3, 0), b + Vector3.new(0, 0.3, 0))
end

local function hideFx(h)
	if h.strip then
		h.strip.Transparency = 1
	end
	if h.ball then
		h.ball.Transparency = 1
	end
	if h.dust then
		h.dust.Enabled = false
	end
	if h.pebbles then
		h.pebbles.Enabled = false
	end
end

local function step(h, now, hrp, dt)
	local t = (now + h.offset) % h.period
	local tell = h.tell
	local pulse = 0.35 + 0.3 * math.sin(now * 12)
	if h.kind == "TreeFall" and h.tree then
		local fallDir = h.out
		local axis = Vector3.yAxis:Cross(fallDir).Unit
		local ang = 0
		if t < tell then
			ang = math.rad(2.5) * math.sin(now * 18) -- creaking shake
			strip(h, h.hinge, h.hinge + fallDir * h.len, 6)
			h.strip.Transparency = pulse
		elseif t < tell + 0.7 then
			local k = (t - tell) / 0.7
			ang = math.rad(88) * k * k
			h.strip.Transparency = 1
		elseif t < tell + 2.7 then
			ang = math.rad(88)
		elseif t < tell + 3.9 then
			ang = math.rad(88) * (1 - (t - tell - 2.7) / 1.2)
		end
		local hinge = CFrame.new(h.hinge)
		h.tree:PivotTo(hinge * CFrame.fromAxisAngle(axis, ang) * hinge:Inverse() * h.rest)
		-- hit: while the trunk sweeps down (40..88 deg) the character is under its line
		if ang > math.rad(40) and t >= tell and t < tell + 0.8 then
			local rel = hrp.Position - h.hinge
			local along = rel:Dot(fallDir)
			local side = rel:Dot(h.dir)
			if along > 0 and along < h.len and math.abs(side) < 4 and rel.Y < 14 then
				knock(h.dir * ((side >= 0) and 1 or -1), h.strength)
			end
		end
	elseif h.kind == "Rockfall" or h.kind == "Avalanche" then
		local dur = (h.kind == "Avalanche") and 2 or 1.4
		if not h.ball then
			h.ball = localPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * h.radius * 2, Material = (h.kind == "Avalanche") and Enum.Material.Snow or Enum.Material.Slate, Color = (h.kind == "Avalanche") and MOON or SLATE, Transparency = 1 })
			local att = Instance.new("Attachment")
			local anchor = localPart({ Size = Vector3.one, Transparency = 1, CFrame = CFrame.new(h.top) })
			att.Parent = anchor
			att.WorldPosition = h.top
			local pe = Instance.new("ParticleEmitter")
			pe.Color = ColorSequence.new(MOON)
			pe.Rate = 30
			pe.Lifetime = NumberRange.new(0.8, 1.4)
			pe.Speed = NumberRange.new(4, 8)
			pe.SpreadAngle = Vector2.new(60, 60)
			pe.Size = NumberSequence.new(1.6, 3)
			pe.Transparency = NumberSequence.new(0.3, 1)
			pe.Enabled = false
			pe.Parent = att
			h.dust = pe
			if h.straight then
				-- authored chutes (vertical): the tell is a trickle of pebbles down the chute line plus the dust,
				-- not a ground strip (a strip on a vertical line read as a glass pane, run 2 self-review)
				local pb = Instance.new("ParticleEmitter")
				pb.Color = ColorSequence.new(SLATE)
				pb.LightInfluence = 1
				pb.Rate = 14
				pb.Lifetime = NumberRange.new(1.2, 1.8)
				pb.Speed = NumberRange.new(2, 5)
				pb.Acceleration = (h.bot - h.top).Unit * 40
				pb.SpreadAngle = Vector2.new(12, 12)
				pb.EmissionDirection = Enum.NormalId.Bottom
				pb.Size = NumberSequence.new(0.35, 0.6)
				pb.Rotation = NumberRange.new(0, 360)
				pb.RotSpeed = NumberRange.new(-200, 200)
				pb.Enabled = false
				pb.Parent = att
				h.pebbles = pb
			end
		end
		if t < tell then
			if h.straight then
				h.pebbles.Enabled = true
			else
				strip(h, h.top, h.bot, h.radius * 2 + 2)
				h.strip.Transparency = pulse
			end
			h.dust.Enabled = true
			h.ball.Transparency = 1
		elseif t < tell + dur then
			local k = (t - tell) / dur
			local p = h.top:Lerp(h.bot, k)
			-- roll on the ground (the straight top->bottom line can float above or dip below the trail)
			local g = not h.straight and workspace:Raycast(p + Vector3.new(0, 60, 0), Vector3.new(0, -140, 0), terrainOnly)
			if g then
				p = Vector3.new(p.X, g.Position.Y + h.radius * 0.8, p.Z)
			end
			p += Vector3.new(0, math.abs(math.sin(k * math.pi * 3)) * 2, 0)
			h.ball.CFrame = CFrame.new(p) * CFrame.Angles(k * 20, 0, 0)
			h.ball.Transparency = 0
			if h.strip then
				h.strip.Transparency = 1
			end
			if h.pebbles then
				h.pebbles.Enabled = false
			end
			h.dust.Enabled = false
			if (hrp.Position - p).Magnitude < h.radius + 2.5 then
				knock((h.bot - h.top), h.strength)
			end
		else
			hideFx(h)
		end
	elseif h.kind == "Gust" then
		local rel = hrp.Position - h.center
		local inside = math.abs(rel:Dot(h.dir)) < h.len / 2 and math.abs(rel:Dot(h.out)) < h.half and math.abs(rel.Y) < 20
		local whip = 0
		if t < tell then
			whip = math.sin(now * 25) * 0.6 * (t / tell)
		elseif t < tell + 1.6 then
			whip = math.sin(now * 40) * 0.9
			if inside then
				-- sheltered behind a windbreak (between the player and the wind source) = no push
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Include
				rp.FilterDescendantsInstances = { h.m }
				local hit = workspace:Raycast(hrp.Position, -h.out * 4, rp)
				if not (hit and hit.Instance.Name == "Windbreak") then
					-- the Humanoid cancels velocity changes while grounded, so the gust nudges the root
					-- (a frame-sized step) unless a fence, wall or slope is in the way
					local step = h.out * h.strength * dt
					local block = RaycastParams.new()
					block.FilterType = Enum.RaycastFilterType.Exclude
					block.FilterDescendantsInstances = { plr.Character, workspace.CurrentCamera }
					if not workspace:Raycast(hrp.Position, step.Unit * (step.Magnitude + 1.5), block) then
						hrp.CFrame += step
					end
				end
			end
		end
		for _, fl in ipairs(h.flags) do
			fl.p.CFrame = fl.cf * CFrame.Angles(0, whip, 0)
		end
	end
end

local function scan()
	local w = workspace:FindFirstChild("World")
	local hf = w and w:FindFirstChild("Hazards")
	if not hf then
		return
	end
	for _, m in ipairs(hf:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("Kind") and not hazards[m] then
			hazards[m] = setup(m) or false
		end
	end
end

local nextScan = 0
Run.RenderStepped:Connect(function(dt)
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local now = workspace:GetServerTimeNow()
	if os.clock() > nextScan then
		nextScan = os.clock() + 1
		scan()
	end
	for m, h in pairs(hazards) do
		if h then
			if not m.Parent then
				hazards[m] = nil
			elseif (hrp.Position - h.center).Magnitude < ACTIVE_RANGE then
				h.active = true
				step(h, now, hrp, dt)
			elseif h.active then
				h.active = false
				hideFx(h)
			end
		end
	end
end)

---------------------------------------------------------------- guardian stagger (Run 1 core loop)
-- CC_CoreService sends CoreFx { kind = "stagger", dir, strength, secs } after a server-validated guardian hit:
-- the same knockback as a hazard, then the character can't walk for `secs` (brief §3.3: stagger 1.2 s).
local fxEv = remotes and remotes:WaitForChild("CoreFx", 30)
if fxEv then
	fxEv.OnClientEvent:Connect(function(p)
		if type(p) ~= "table" or p.kind ~= "stagger" then
			return
		end
		local ch = plr.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		lastHit = 0 -- a guardian hit is never swallowed by the hazard cooldown
		knock(typeof(p.dir) == "Vector3" and p.dir or Vector3.zAxis, tonumber(p.strength) or 26)
		-- Movement owns speed; CoreClient renews a suppression lease for this effect.

	end)
end

-- Fall outcomes and checkpoint messages are owned by server traversal and the Expedition interface.
