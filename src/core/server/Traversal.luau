-- One authoritative traversal state machine. Authored holds live in CC_TraversalDefs.
-- No generic wall climbing, altitude equipment, rescue rewards, or client-authored positions.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Run = game:GetService("RunService")
local HS = game:GetService("HttpService")
local K = require(RS.CC_Core.TraversalConfig)
local Rules = require(RS.CC_Core.TraversalRules)
local T = {}
local ctx, api
local states, sections, ropes, gates, darkZones = {}, {}, {}, {}, {}
local closedRouteIndex, openRouteIndex
local function V(a) return Vector3.new(a[1], a[2], a[3]) end
local function actor(plr)
	local ch = plr.Character
	return ch, ch and ch:FindFirstChildOfClass("Humanoid"), ch and ch:FindFirstChild("HumanoidRootPart")
end
local function ray(plr, p, d)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = plr.Character and { plr.Character } or {}
	return workspace:Raycast(p, d, rp)
end
local function grounded(plr)
	local _, h, r = actor(plr)
	if not h or not r or h.Health <= 0 then return false end
	local g = ray(plr, r.Position, Vector3.new(0, -(h.HipHeight + r.Size.Y / 2 + 0.8), 0))
	return g ~= nil and g.Normal.Y > 0.6 and r.AssemblyLinearVelocity.Y < 7
end
local function get(plr)
	if not states[plr] then states[plr] = { mode = "ground", stamina = plr:GetAttribute("CC_StaminaMax") or 100, hand = "L", nextAt = 0 } end
	return states[plr]
end
local function publish(plr, s)
	local ch = plr.Character
	if not ch then return end
	ch:SetAttribute("CC_TraversalState", s.mode)
	ch:SetAttribute("CC_ClimbState", (s.mode == "climb" or s.mode == "rope") and "climb" or s.mode == "hanging" and "slide" or "none")
	ch:SetAttribute("CC_ClimbS", (s.mode == "climb" or s.mode == "rope") and "climb" or s.mode == "hanging" and "slide" or "none")
	ch:SetAttribute("CC_Stamina", math.floor(s.stamina + 0.5))
	ch:SetAttribute("CC_SectionId", s.section and s.section.id or "")
	ch:SetAttribute("CC_HoldId", s.hold and s.hold.id or "")
	ch:SetAttribute("CC_NextHand", s.hand)
	ch:SetAttribute("CC_HoldIndex", s.index or 0)
	ch:SetAttribute("CC_ClimbDirection", s.direction or 1)
	ch:SetAttribute("CC_Clipped", s.clip ~= nil)
	ch:SetAttribute("CC_CanRecover", s.mode == "hanging" and s.stamina >= K.recoverAt)
	ch:SetAttribute("CC_RhythmAt", s.nextAt or 0)
end
local function detachRope(s)
	if s.rope then s.rope.occupants = math.max(0, s.rope.occupants - 1); s.rope = nil end
end
local function clearHarness(s)
	for _, part in ipairs(s.harness or {}) do part:Destroy() end
	s.harness = nil
end
local function clearFlight(plr)
	local ch, h, r = actor(plr)
	if r then
		for _, name in ipairs({ "CC_FlightVelocity", "CC_FlightAttachment" }) do local x = r:FindFirstChild(name); if x then x:Destroy() end end
	end
	if ch then local canopy = ch:FindFirstChild("CC_Parachute"); if canopy then canopy:Destroy() end end
	if h then h.PlatformStand = false; h.AutoRotate = true end
end
local function leave(plr, mode)
	local s = get(plr)
	detachRope(s)
	clearHarness(s)
	clearFlight(plr)
	local _, h, r = actor(plr)
	if r then r.Anchored = false; pcall(function() r:SetNetworkOwnershipAuto() end) end
	if h then h.PlatformStand = false; h.AutoRotate = true; if mode == "fall" then h:ChangeState(Enum.HumanoidStateType.Freefall) end end
	s.mode, s.section, s.hold, s.move, s.clip, s.index = mode or "ground", nil, nil, nil, nil, nil
	s.jumpAt = nil
	publish(plr, s)
end
local function authorize(plr, pos, kind)
	if api and api:FindFirstChild("AuthorizeMove") then api.AuthorizeMove:Invoke(plr, pos, kind) end
end
function T.travel(plr, pos, kind)
	if typeof(pos) ~= "Vector3" then return false end
	local ch, _, r = actor(plr)
	if not r then return false end
	leave(plr, "ground")
	local s = get(plr)
	s.mode = "travel"
	s.travelToken = (s.travelToken or 0) + 1
	local token = s.travelToken
	r.Anchored = true
	publish(plr, s)
	if kind == "homeEnter" or kind == "homeReturn" or kind == "shuttle" or kind == "resume" or kind == "reconnect" then
		-- Keep the avatar safe while the destination streams. Home courts stream atomically.
		local ok, err = pcall(function() plr:RequestStreamAroundAsync(pos, 4) end)
		if not ok then warn("[CC] destination streaming request: " .. tostring(err)) end
	end
	if plr.Character ~= ch or not r.Parent or states[plr] ~= s or s.travelToken ~= token then return false end
	authorize(plr, pos, kind or "travel")
	r.AssemblyLinearVelocity = Vector3.zero
	ch:PivotTo(CFrame.new(pos))
	s.lastGround, s.lastSafe = pos, pos
	s.travelAt, s.travelKind = ctx.Clock.now(), kind
	-- The durable inventory owner persists the receipt with the cargo; no adventure credit is granted here.
	local session = ctx.sessions[plr]
	if session then
		session.data.expedition = session.data.expedition or {}
		session.data.expedition.travel = { kind = kind or "travel", at = ctx.Clock.now(), x = pos.X, y = pos.Y, z = pos.Z }
		session.dirty = true
	end
	ctx.emit("travel", plr, kind, pos)
	ctx.push(plr)
	task.delay(0.45, function()
		if states[plr] == s and s.travelToken == token and plr.Character == ch and r.Parent then
			r.Anchored = false
			pcall(function() r:SetNetworkOwnershipAuto() end)
			s.mode = "ground"
			authorize(plr, r.Position, kind or "travel")
			publish(plr, s)
		end
	end)
	return true
end
function T.isProtected(plr)
	local s = states[plr]
	return s and (s.mode == "climb" or s.mode == "rope" or s.mode == "hanging" or s.mode == "flight") or false
end
function T.canBank(plr)
	local s = get(plr)
	if s.mode~="ground" or not grounded(plr) or workspace:GetServerTimeNow()<(plr:GetAttribute("CC_MovementInvalidUntil") or 0) then return false end
	local validate=api and api:FindFirstChild("ValidateMovement")
	return validate~=nil and validate:Invoke(plr)==true
end
local function location(plr)
	local _, _, r = actor(plr)
	if not r then return nil end
	local best, dist
	for name, cp in pairs(ctx.Camps and ctx.Camps._pads or {}) do
		local d = (r.Position - cp.center).Magnitude
		if d < K.flightLaunchRadius and (not dist or d < dist) then best, dist = { name = name, center = cp.center, order = table.find(ctx.C.RESUME_CAMPS, name) or 0 }, d end
	end
	return best
end
local function canUse(plr, section)
	if not section or not K.launchRoutes[section.route] then return false end
	if section.practice and ctx.Training and ctx.Training.canUseSection then return ctx.Training.canUseSection(plr, section.practice) or (ctx.DailyPractice and ctx.DailyPractice.canUseSection(plr, section.practice)) end
	return true
end
local function nearest(plr, top)
	local _, _, r = actor(plr)
	if not r then return nil end
	local best, distance
	for _, sec in pairs(sections) do
		local d = (r.Position - (top and sec.exit or sec.entry)).Magnitude
		if canUse(plr, sec) and d < (top and K.topRange or K.entryRange) and (not distance or d < distance) then best, distance = sec, d end
	end
	return best
end
local function currentRope(id)
	local rope = ropes[id]
	return rope and not rope.retiring and rope.expires > workspace:GetServerTimeNow() and rope or nil
end
local function moveTo(plr, s, pos, finish)
	local _, _, r = actor(plr)
	if not r then return end
	s.move = { from = r.Position, to = pos, start = workspace:GetServerTimeNow(), finish = finish }
end
local function begin(plr, sec, clip, descending)
	local s = get(plr)
	local ch, h, r = actor(plr)
	if s.mode ~= "ground" or not grounded(plr) or not r or not canUse(plr, sec) then return false end
	local start = descending and sec.exit or sec.entry
	if (r.Position - start).Magnitude > K.entryRange + 2 then return false end
	local rope = currentRope(sec.id)
	if sec.protected and not clip and not rope then return false end
	s.section, s.direction, s.hand = sec, descending and -1 or 1, "L"
	s.index = descending and #sec.holds or 1
	s.hold = sec.holds[s.index]
	s.clip = clip and sec.id or nil
	if clip and sec.topAnchor then
		local a = Instance.new("Attachment"); a.Name = "HarnessClip"; a.Position = Vector3.new(0, -0.6, 0); a.Parent = r
		local b = Instance.new("Attachment"); b.Name = "PersonalAnchor"; b.Parent = sec.topAnchor
		local beam = Instance.new("Beam")
		beam.Name, beam.Attachment0, beam.Attachment1 = "PersonalHarnessTether", a, b
		beam.Width0, beam.Width1, beam.FaceCamera, beam.Segments = 0.075, 0.075, true, 1
		beam.Color = ColorSequence.new(Color3.fromRGB(224, 173, 105))
		beam.Transparency, beam.LightInfluence, beam.Parent = NumberSequence.new(0.1), 1, a
		s.harness = { a, b }
	end
	s.mode, s.nextAt = rope and "rope" or "climb", workspace:GetServerTimeNow() + K.stepSeconds
	s.rope = rope
	if rope then rope.occupants += 1 end
	s.stamina = math.max(10, s.stamina)
	h.PlatformStand, h.AutoRotate = true, false
	r.AssemblyLinearVelocity = Vector3.zero
	pcall(function() r:SetNetworkOwner(nil) end)
	r.Anchored = true
	moveTo(plr, s, s.hold.pos)
	publish(plr, s)
	ctx.toast(plr, rope and "Shared rope attached. Alternate left and right to ascend." or "Harness clipped for this section. Alternate left and right; take your time.")
	return true
end
local function slip(plr, reason)
	local s = get(plr)
	if s.mode ~= "climb" and s.mode ~= "rope" then return end
	if s.clip == s.section.id then
		s.mode = "hanging"
		s.stamina = math.max(0, s.stamina - 5)
		moveTo(plr, s, s.hold.pos - Vector3.yAxis * K.hangDrop)
		ctx.toast(plr, "Harness caught you. Your finds are safe. Rest, then regain your hold.")
		ctx.emit("traversalCatch", plr, s.section.id, reason)
		publish(plr, s)
	else leave(plr, "fall") end
end
local function step(plr, payload)
	local s = get(plr)
	local _, _, r = actor(plr)
	if not s.section or not s.hold or not r or s.move then return end
	if (r.Position - s.hold.pos).Magnitude > K.holdTolerance then slip(plr, "displaced"); return end
	local nextIndex = s.index + s.direction
	local hold = s.section.holds[nextIndex]
	if hold and payload.choice == "stable" and hold.alternative then hold = hold.alternative end
	local now = workspace:GetServerTimeNow()
	local ok, cost = Rules.step(s, payload.hand, hold or { finish = true }, now, K, plr:GetAttribute("CC_TimingAssist") == true)
	if not ok then
		if cost == "tired" then slip(plr, "stamina")
		elseif (cost == "hand" or cost == "early") and now - (s.lastMistake or 0) > 0.4 then
			s.lastMistake = now
			-- One error never causes a fall; waiting is never an error.
			s.stamina = math.max(1, s.stamina - K.mistakeCost)
			ctx.fx(plr, { kind = "traversalCue", text = cost == "hand" and ("Next: " .. s.hand) or "A gentle rhythm. Try again.", mistake = true })
		end
		publish(plr, s)
		return
	end
	s.stamina -= cost
	s.hand = s.hand == "L" and "R" or "L"
	s.nextAt = now + (plr:GetAttribute("CC_TimingAssist") and K.assistedSeconds or K.stepSeconds)
	if hold then
		s.index, s.hold = nextIndex, hold
		moveTo(plr, s, hold.pos)
	else
		moveTo(plr, s, s.direction > 0 and s.section.exit or s.section.entry, true)
	end
	publish(plr, s)
end
local function deployRope(plr, id)
	local s = get(plr)
	local sec = id and sections[id] or nearest(plr, true)
	local _, _, r = actor(plr)
	if s.mode ~= "ground" or not r or not grounded(plr) or not canUse(plr, sec) or (r.Position - sec.exit).Magnitude > K.topRange then return end
	local now = workspace:GetServerTimeNow()
	if now - (s.lastRope or -100) < K.ropeCooldown then return end
	if currentRope(sec.id) then ctx.toast(plr, "A shared rope is already ready here."); return end
	local owned = 0
	for _, rope in pairs(ropes) do if rope.owner == plr.UserId then owned += 1 end end
	if owned >= K.ropeLimit then ctx.toast(plr, "Two ropes are already out. Occupied ropes remain safe until everyone leaves."); return end
	-- A retiring occupied rope cannot be replaced under its occupants.
	if ropes[sec.id] then ctx.toast(plr, "This rope is finishing its current climbs."); return end
	local a, b = sec.holds[1].pos, sec.holds[#sec.holds].pos
	local p = Instance.new("Part")
	p.Name, p.Shape, p.Material = "SharedRope", Enum.PartType.Cylinder, Enum.Material.Fabric
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Size, p.Color = Vector3.new((b - a).Magnitude, 0.22, 0.22), Color3.fromRGB(244, 192, 105)
	p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
	p.Parent = workspace.World:FindFirstChild("ExpeditionTraversal") or workspace.World
	ropes[sec.id] = { owner = plr.UserId, section = sec.id, expires = now + K.ropeSeconds, occupants = 0, part = p }
	s.lastRope = now
	ctx.toast(plr, "Shared rope deployed. Other climbers attach at the lower anchor.", "good")
end
local function flightLanding(plr, s, pos)
	if workspace.World:FindFirstChild("Fairground") and require(script.Parent.LobbyAnchors).contains(pos) then return true end
	local base = ctx.C.FOOTHOLD_SAFE
	if not workspace.World:FindFirstChild("Fairground") and ((pos - base.center) * Vector3.new(1,0,1)).Magnitude < base.radius and pos.Y < base.center.Y + 60 then return true end
	for name, cp in pairs(ctx.Camps and ctx.Camps._pads or {}) do
		local order = table.find(ctx.C.RESUME_CAMPS, name) or 0
		if (pos - cp.center).Magnitude < K.flightLandingRadius and Rules.canLand(s.launch.order, order, pos.Y, s.launch.center.Y) then return true end
	end
	return false
end
local function deploy(plr)
	local s = get(plr)
	local ch, h, r = actor(plr)
	local now = workspace:GetServerTimeNow()
	if not r or not s.launch or not Rules.canDeploy(s, now, not grounded(plr), r.Position.Y, s.launch.center.Y, K) then return end
	if (r.Position - s.launch.center).Magnitude > K.flightLaunchRadius + 6 then return end
	s.mode, s.flightAt, s.steer = "flight", now, Vector3.zero
	h.PlatformStand, h.AutoRotate = true, false
	pcall(function() r:SetNetworkOwner(nil) end)
	local att = Instance.new("Attachment"); att.Name = "CC_FlightAttachment"; att.Parent = r
	local lv = Instance.new("LinearVelocity")
	lv.Name, lv.Attachment0, lv.RelativeTo = "CC_FlightVelocity", att, Enum.ActuatorRelativeTo.World
	lv.MaxForce, lv.VectorVelocity, lv.Parent = math.huge, Vector3.new(0, -K.flightSink, 0), r
	local canopy = Instance.new("Part")
	canopy.Name, canopy.Shape, canopy.Size = "CC_Parachute", Enum.PartType.Ball, Vector3.new(11, 2.6, 7)
	canopy.Color, canopy.Material = Color3.fromRGB(194, 139, 73), Enum.Material.Fabric
	canopy.CanCollide, canopy.CanQuery, canopy.CanTouch, canopy.Massless = false, false, false, true
	canopy.CFrame, canopy.Parent = r.CFrame + Vector3.new(0, 8, 0), ch
	local weld = Instance.new("WeldConstraint"); weld.Part0, weld.Part1, weld.Parent = r, canopy, canopy
	publish(plr, s)
	ctx.toast(plr, "Parachute open. Steer gently toward a camp below or the Foothold. Landing keeps finds in your pack.")
end
function T.rescue(helper, climber)
	local s = states[climber]
	local _, _, a = actor(helper)
	local _, _, b = actor(climber)
	if helper == climber or not s or s.mode ~= "hanging" or not grounded(helper) or not a or not b then return false end
	if (a.Position - b.Position).Magnitude > 14 or a.Position.Y < b.Position.Y + 2 or workspace:GetServerTimeNow() - (s.rescuedAt or 0) < 30 then return false end
	s.rescuedAt = workspace:GetServerTimeNow()
	s.stamina = math.min(climber:GetAttribute("CC_StaminaMax") or 100, s.stamina + 30)
	ctx.toast(helper, "You helped them regain their grip.", "good")
	ctx.toast(climber, helper.DisplayName .. " helped you. Regain your hold when ready.", "good")
	return true
end
local function recover(plr)
	local s = get(plr)
	if s.mode ~= "hanging" or s.stamina < K.recoverAt or s.move then return end
	s.mode = s.rope and "rope" or "climb"
	s.nextAt = workspace:GetServerTimeNow() + K.stepSeconds
	moveTo(plr, s, s.hold.pos)
	publish(plr, s)
end
local function handle(plr, p)
	local s = get(plr)
	if not ctx.sessions[plr] or type(p.action) ~= "string" then return end
	if p.action == "step" then step(plr, p)
	elseif p.action == "clip" then begin(plr, nearest(plr, false), true, false)
	elseif p.action == "grab" then local sec = nearest(plr, false); if sec and currentRope(sec.id) then begin(plr, sec, false, false) end
	elseif p.action == "descend" then begin(plr, nearest(plr, true), true, true)
	elseif p.action == "recover" then recover(plr)
	elseif p.action == "release" and (s.mode == "climb" or s.mode == "rope" or s.mode == "hanging") then leave(plr, "fall")
	elseif p.action == "slip" then slip(plr, "hazard")
	elseif p.action == "rope" then deployRope(plr)
	elseif p.action == "jump" and s.mode == "ground" and grounded(plr) then
		local launch = location(plr)
		local _, _, r = actor(plr)
		if launch and r then s.jumpAt, s.jumpY, s.launch, s.jumpAirborne = workspace:GetServerTimeNow(), r.Position.Y, launch, false end
	elseif p.action == "parachute" then deploy(plr)
	elseif p.action == "steer" and s.mode == "flight" and Rules.finite(p.x) and Rules.finite(p.z) then
		local v = Vector3.new(p.x, 0, p.z); s.steer = v.Magnitude > 1 and v.Unit or v
		s.steerAt = workspace:GetServerTimeNow()
	end
end
local function iceAt(plr, s, r)
	local hit = ray(plr, r.Position, s.section and s.section.into * 5 or Vector3.new(0,-5,0))
	return hit and (hit.Material == Enum.Material.Ice or hit.Material == Enum.Material.Glacier or hit.Instance:GetAttribute("Icy") == true) or false
end
local function isDark(pos, plr)
	local W = ctx.C.WEATHER
	local phase = ((workspace:GetServerTimeNow() - (workspace:GetAttribute("CC_DayStart") or workspace:GetServerTimeNow())) % (W.dayMinutes * 60)) / (W.dayMinutes * 60)
	if phase >= W.dayShare then return true end
	for _, z in ipairs(darkZones) do
		if z.Parent then local p = z.CFrame:PointToObjectSpace(pos); local h = z.Size / 2; if math.abs(p.X)<h.X and math.abs(p.Y)<h.Y and math.abs(p.Z)<h.Z then return true end end
	end
	-- Covered stone passages and recesses use actual occlusion, never altitude.
	local roof = ray(plr, pos + Vector3.yAxis * 2, Vector3.yAxis * 18)
	if roof then
		local walls = 0
		for _, d in ipairs({ Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis }) do
			if ray(plr, pos + Vector3.yAxis, d * 12) then walls += 1 end
		end
		if walls >= 2 then return true end
	end
	return false
end
local function update(plr, s, dt, now)
	local ch, h, r = actor(plr)
	if not r or not h or h.Health <= 0 then return end
	if s.mode == "travel" then return end
	local maxSt = plr:GetAttribute("CC_StaminaMax") or 100
	if now >= (s.senseAt or 0) then
		s.senseAt = now + 0.5
		s.ice = iceAt(plr, s, r)
		ch:SetAttribute("CC_IceActive", s.ice)
		ch:SetAttribute("CC_AxeActive", s.ice and (s.mode == "climb" or s.mode == "rope"))
		ch:SetAttribute("CC_CramponsActive", s.ice)
		local dark = isDark(r.Position, plr)
		ch:SetAttribute("CC_Dark", dark)
		ch:SetAttribute("CC_HeadlampActive", dark and plr:GetAttribute("CC_HeadlampMode") ~= "off")
	end
	if s.move then
		local m = s.move
		local f = math.clamp((now - m.start) / K.moveSeconds, 0, 1)
		local pos = m.from:Lerp(m.to, f * f * (3 - 2*f))
		r.CFrame = CFrame.lookAt(pos, pos + s.section.into)
		if f >= 1 then
			s.move = nil
			if m.finish then
				local id, route, direction = s.section.id, s.section.route, s.direction
				authorize(plr, m.to, "climbLanding")
				leave(plr, "ground")
				if direction > 0 then ctx.emit("traversalSection", plr, id, route) end
			end
		end
	elseif s.mode == "hanging" then s.stamina = math.min(maxSt, s.stamina + K.hangingRegen * dt)
	elseif s.mode == "climb" or s.mode == "rope" then
		if s.hold.stable then s.stamina = math.min(maxSt, s.stamina + K.stableRegen * dt) end
		if (r.Position - s.hold.pos).Magnitude > K.holdTolerance then slip(plr, "displaced") end
	elseif s.mode == "flight" then
		local velocity = r:FindFirstChild("CC_FlightVelocity")
		if now - (s.steerAt or 0) > 0.75 then s.steer = Vector3.zero end
		if velocity then velocity.VectorVelocity = (s.steer or Vector3.zero) * K.flightSpeed + Vector3.new(0, -K.flightSink, 0) end
		local floor = ray(plr, r.Position, Vector3.new(0,-4,0))
		if now - s.flightAt > 0.6 and floor and floor.Normal.Y > 0.6 then
			local pos = floor.Position + Vector3.yAxis * 3
			if flightLanding(plr, s, pos) then
				T.travel(plr, pos, "parachute")
				local session = ctx.sessions[plr]
				if session and not session.data.flags.parachutePractice then
					session.data.flags.parachutePractice = true; session.dirty = true
					plr:SetAttribute("CC_ParachutePractice", true)
					ctx.saveSoon(session)
				end
				ctx.toast(plr, "Landed. Parachute packed; your finds are still in your backpack.", "good")
			else
				T.travel(plr, s.launch.center + Vector3.yAxis * 4, "practiceReturn")
				ctx.toast(plr, "That ledge is outside the landing areas. Returned safely to your launch camp with your finds.")
			end
		elseif now - s.flightAt > K.flightMaxSeconds or r.Position.Y < -100 then
			T.travel(plr, s.launch.center + Vector3.yAxis * 4, "practiceReturn")
		end
	elseif grounded(plr) then
		if s.mode ~= "ground" or not s.groundSince then s.groundSince=now end
		s.mode = "ground"
		if s.jumpAirborne then s.jumpAt, s.jumpAirborne = nil, nil end
		s.stamina = math.min(maxSt, s.stamina + K.groundRegen * dt)
		s.lastGround = r.Position
		-- Actual ice only: counter ground drift when no movement is requested.
		if s.ice and h.MoveDirection.Magnitude < 0.1 then local v=r.AssemblyLinearVelocity; r.AssemblyLinearVelocity=Vector3.new(v.X*0.25,v.Y,v.Z*0.25) end
	else
		-- A grounded jump receipt remains eligible for its short deploy window; walkoffs have no receipt.
		s.mode = "fall"
		s.groundSince=nil
		if s.jumpAt then s.jumpAirborne = true end
	end
	-- Reject access after landing settles, so this never becomes a midair fall rescue.
	if s.mode=="ground" and s.groundSince and now-s.groundSince>=0.25 and not ch:GetAttribute("CC_HomeVisit") and now>=(s.routeCheckAt or 0) then
		s.routeCheckAt=now+0.2
		local closed=closedRouteIndex and Rules.closedRouteAt(closedRouteIndex,openRouteIndex,{r.Position.X,r.Position.Y,r.Position.Z})
		if closed then
			for _,cp in pairs(ctx.Camps and ctx.Camps._pads or {}) do
				if (r.Position-cp.center).Magnitude<80 then closed=nil; break end
			end
		end
		for _, gate in ipairs(gates) do
			local p = gate.cf:PointToObjectSpace(r.Position)
			if closed==gate.route and Rules.closedGateApproach(p.X,p.Y,p.Z) then closed=nil end
			-- The old 170x178 gate rectangle crossed the adjacent open Shepherd approach.
			-- Guard the actual closed entrance; the route index still guards the closed trail beyond it.
			local entrance=math.abs(p.X)<24 and p.Z<-2 and p.Z>-50 and p.Y>-6 and p.Y<32
			if entrance and Rules.nearestRoute(openRouteIndex,{r.Position.X,r.Position.Y,r.Position.Z},24) then entrance=false end
			if entrance or closed==gate.route then
				T.travel(plr, gate.cf:PointToWorldSpace(Vector3.new(0,3,16)), "closedRoute")
				ctx.toast(plr, gate.route .. " is Coming Soon. Choose Shepherd or Waterfall.")
				break
			end
		end
	end
	if now - (s.pubAt or 0) >= 0.2 then s.pubAt = now; publish(plr, s) end
end
function T.state(plr, st)
	local s = get(plr)
	st.traversal = { mode=s.mode, stamina=s.stamina, maxStamina=plr:GetAttribute("CC_StaminaMax") or 100, section=s.section and s.section.id, hand=s.hand, clipped=s.clip ~= nil }
end
function T.onCharacter(plr, ch)
	local old = states[plr]; if old then detachRope(old); clearHarness(old) end
	states[plr] = nil
	local s = get(plr)
	local h = ch:WaitForChild("Humanoid",10)
	if h then
		h:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		h.Died:Connect(function() leave(plr,"fall") end)
	end
	publish(plr,s)
end
function T.onLoaded(plr, session)
	plr:SetAttribute("CC_ParachuteUnlocked", session.data.highestCamp >= 1 or session.data.flags.parachuteIntroduced == true)
	plr:SetAttribute("CC_ParachutePractice", session.data.flags.parachutePractice == true)
end
function T.onLeave(plr)
	local s=states[plr]; if s then detachRope(s); clearHarness(s) end
	states[plr]=nil
	for _, rope in pairs(ropes) do if rope.owner == plr.UserId then rope.retiring=true end end
end
function T.init(c)
	ctx=c; ctx.Traversal=T
	api=SS:WaitForChild("CC_CheckpointAPI",10)
	local folder=RS:WaitForChild("CC_TraversalDefs",10)
	assert(folder,"Missing authored traversal registry; run AuthorTraversal in Edit mode")
	for _, sv in ipairs(folder:GetChildren()) do
		local ok,sec=pcall(function() return HS:JSONDecode(sv.Value) end)
		if ok and sec.holds and #sec.holds>=2 and K.launchRoutes[sec.route] then
			sec.entry,sec.exit,sec.into=V(sec.entry),V(sec.exit),V(sec.into)
			for _,hold in ipairs(sec.holds) do hold.pos=V(hold.p); if hold.alternative then hold.alternative.pos=V(hold.alternative.p) end end
			sections[sec.id]=sec
		end
	end
	T.sections, T.states = sections, states
	local world=workspace:WaitForChild("World")
	local old=world:FindFirstChild("ExpeditionTraversal"); if old then old:Destroy() end
	local anchors=Instance.new("Folder"); anchors.Name="ExpeditionTraversal"; anchors.Parent=world
	local Prompts=require(script.Parent.Prompts)
	for _,sec in pairs(sections) do
		for _,top in ipairs({false,true}) do
			local p=Instance.new("Part")
			p.Name=top and "TopAnchor" or "ClipAnchor"
			p.Size=Vector3.new(0.6,0.9,0.6); p.Color=Color3.fromRGB(238,184,98); p.Material=Enum.Material.Metal
			p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
			p.Position=(top and sec.exit or sec.entry)+sec.into:Cross(Vector3.yAxis)*2-Vector3.yAxis*1
			p:SetAttribute("SectionId",sec.id); p.Parent=anchors
			if top then sec.topAnchor = p end
			local prompt=Prompts.make(p,{Name=top and "SharedRopePrompt" or "HarnessPrompt",ActionText=top and "Deploy shared rope" or "Clip & climb",ObjectText=sec.tutorial and "First protected climb" or sec.practice and ("Practice crag "..sec.practice) or "Marked climbing anchor",HoldDuration=0,MaxActivationDistance=7})
			prompt.KeyboardKeyCode=Enum.KeyCode.F; prompt.GamepadKeyCode=Enum.KeyCode.ButtonY
			prompt.Triggered:Connect(function(plr) if Prompts.validate(prompt,plr) then if top then deployRope(plr,sec.id) else begin(plr,sec,true,false) end end end)
		end
	end
	for _,d in ipairs(world:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("DarkZone") then darkZones[#darkZones+1]=d end
		if d:IsA("Model") and d:GetAttribute("ComingSoon") then
			local board=d:FindFirstChild("Board")
			if board then gates[#gates+1]={cf=d:GetPivot(),route=d:GetAttribute("Route") or d.Name:gsub("Gate_","")} end
		end
	end
	local closedPaths,openPaths={},{}
	local function append(route,points)
		if #points>=2 then table.insert((route=="Ledge" or route=="Spire") and closedPaths or openPaths,{route=route,points=points}) end
	end
	-- Marked public approaches connect the compact court to the two existing open entrances.
	-- Old closed-route spline tails overlap this shared flat ground; they are not entrances.
	for _,path in require(RS.CC_Core.LobbyApproaches) do append('LobbyApproach',path.points) end
	for _,sv in ipairs((RS:FindFirstChild("CC_Route") and RS.CC_Route:GetChildren()) or {}) do
		if sv:IsA("StringValue") then
			local points={}
			for row in sv.Value:gmatch("[^;]+") do
				local x,y,z=row:match("([^,]+),([^,]+),([^,]+)")
				x,y,z=tonumber(x),tonumber(y),tonumber(z)
				if Rules.finite(x) and Rules.finite(y) and Rules.finite(z) then points[#points+1]={x,y,z} end
			end
			append(sv.Name,points)
		end
	end
	for _,sv in ipairs((RS:FindFirstChild("CC_Track") and RS.CC_Track:GetChildren()) or {}) do
		if sv:IsA("StringValue") then
			local ok,tracks=pcall(function() return HS:JSONDecode(sv.Value) end)
			if ok and type(tracks)=="table" then
				for _,track in ipairs(tracks) do
					local points={}
					for _,node in ipairs(track.nodes or {}) do if node.p then points[#points+1]=node.p end end
					append(sv.Name,points)
				end
			end
		end
	end
	for _,sec in pairs(sections) do
		local points={{sec.entry.X,sec.entry.Y,sec.entry.Z}}
		for _,hold in ipairs(sec.holds) do points[#points+1]=hold.p end
		points[#points+1]={sec.exit.X,sec.exit.Y,sec.exit.Z}
		append(sec.route,points)
	end
	closedRouteIndex,openRouteIndex=Rules.routeIndex(closedPaths,64),Rules.routeIndex(openPaths,64)
	ctx.handlers.traversal=handle
	ctx.on("hit",function(plr) slip(plr,"guardian") end)
	if api then
		api.CampReached.Event:Connect(function(plr, name)
			local session = ctx.sessions[plr]
			if session and tostring(name):match("^Camp[1-4]$") and not session.data.flags.parachuteIntroduced then
				session.data.flags.parachuteIntroduced = true; session.dirty = true
				plr:SetAttribute("CC_ParachuteUnlocked", true)
				ctx.toast(plr, "Your parachute is ready. Practice here: jump from the camp, then use Open parachute. Landings keep your finds carried.")
				ctx.saveSoon(session)
			end
		end)
	end
	local accumulator=0
	Run.Heartbeat:Connect(function(dt)
		accumulator+=dt; if accumulator<0.05 then return end
		local elapsed=math.min(accumulator,0.2); accumulator=0
		local now=workspace:GetServerTimeNow()
		for plr,s in pairs(states) do update(plr,s,elapsed,now) end
		for id,rope in pairs(ropes) do
			if now>=rope.expires then rope.retiring=true end
			if Rules.canRemoveRope(rope,now) then if rope.part then rope.part:Destroy() end; ropes[id]=nil end
		end
	end)
	if ctx.devHandlers then
		ctx.devHandlers.traversal=function(plr,p) handle(plr,p) end
	end
end
return T
