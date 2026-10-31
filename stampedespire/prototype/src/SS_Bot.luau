-- Studio-only BOT checks for the ride/swap loop on the Blender mountain (ReplicatedStorage.SS_Bot).
-- Run from the command bar during Play Solo (it runs in the client context there):
--   require(game.ReplicatedStorage.SS_Bot)()          -- everything
--   require(game.ReplicatedStorage.SS_Bot)("ride")    -- 10d continuous ride + PERF only
-- Results print to Output and stay on a large on-screen panel so a desktop screenshot captures them.
local RepS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

local function herdOf(k)
	return (C.Zones[k].Herd or C.Pool.PerLane) * C.LaneCount
end
-- Under MinFps, Studio is not the foreground window and throttles frames (TEST-LOG P3/P2b read 15 fps): a
-- frame-timed result is then not valid (10d skips instead of passing or failing; PERF says so).
local MinFps = 30
-- 10d. Continuous ride (HERD-SIM.md section 6; also run alone by mode "ride"): one teleport to the middle of section 2, then ride on with no
-- teleport and no swap through all of section 3 to 300 studs into section 4 (2 borders, ~75 s at tier 1; the mount is
-- held at tier 1 for the ride like the sim's rider, else a 0.75 mount fails native +250 by its own slowness),
-- sampling every frame. Live <= the larger quota of the live biomes + 25 (P4; was + 15); stragglers (outside their biome)
-- <= 25% of live on average; <= 4 biomes live and <= 2 out of view; native share >= 50% on average in each
-- section and >= 30% at +250..300 past each border; nothing appears / vanishes in view and nothing fades in faster than Pool.FarFade inside Pool.Readable (P4); same-lane gap held;
-- the 300 studs ahead hold mean >= 5 creatures and are empty for <= 10% of the ride, never longer than 8 s
-- (HERD-SIM fix set, never-swapping rider: empty up to 5.7% of s2-s10, longest 6.7 s; a min of 2 never held); nothing in swap range for <= 25% of the ride and never
-- longer than 12 s. (25%, not the sim's 15%: that is for a player who swaps; the BOT never does, and the sim's
-- never-swapping rider gets 20-22% in sections 2-3 with p95 gaps of 11-13 s.)
local function ride10d(F, S, check, log)
	local k0, k1 = 2, 4
	local from, to = P.Starts[k0] + 300, P.Starts[k1] + 300
	F:Invoke("teleport", from)
	local oldSpd = F:Invoke("mountSpd", 1)
	task.wait(2)
	local hs1 = F:Invoke("herdStats")
	-- + 25, not 15 (owner, P4): with the fog-table RecycleAhead (350-400) creatures in that band can't be parked,
	-- so the continuous ride runs ~53-59 live (sim 10d: 58 in every run); M7 phone perf decides the herd size.
	local capC = math.max(herdOf(k0), herdOf(k0 + 1), herdOf(k1)) + 25
	local n, maxLive, sumStr, maxStr, maxB, maxFar, mism, minAhead, sumAhead = 0, 0, 0, 0, 0, 0, 0, math.huge, 0
	local minGapC, gapWhoC = math.huge, ""
	local nat, natN, natB = {}, {}, {} -- per section: native sum, samples; at +250..300 past its start: min
	local rideT, noT, gapT, longest, okRide = 0, 0, 0, 0, true
	local emptyT, emptyRun, emptyLong = 0, 0, 0
	local t0, last = os.clock(), os.clock()
	while os.clock() - t0 < 120 do
		local s = S()
		if s.d >= to then
			break
		end
		local now = os.clock()
		local dt = now - last
		last = now
		local h = F:Invoke("herdStats")
		n += 1
		maxLive = math.max(maxLive, h.live)
		local share = h.live > 0 and h.stragglers / h.live or 0
		sumStr += share
		maxStr = math.max(maxStr, share)
		maxB, maxFar, mism = math.max(maxB, h.biomes), math.max(maxFar, h.farBiomes), mism + h.mismatch
		minAhead, sumAhead = math.min(minAhead, h.ahead), sumAhead + h.ahead
		emptyRun = h.ahead == 0 and emptyRun + dt or 0
		emptyT, emptyLong = emptyT + (h.ahead == 0 and dt or 0), math.max(emptyLong, emptyRun)
		if h.minGap < minGapC then
			minGapC, gapWhoC = h.minGap, h.gapWho
		end
		local k = P.zoneOf(math.max(s.d, 0))
		nat[k], natN[k] = (nat[k] or 0) + h.native, (natN[k] or 0) + 1
		if s.d - P.Starts[k] >= 250 and s.d - P.Starts[k] < 300 and k > k0 then
			natB[k] = math.min(natB[k] or 1, h.native)
		end
		if s.state == "ride" then
			rideT += dt
			if h.reach == 0 then
				noT += dt
				gapT += dt
				longest = math.max(longest, gapT)
			else
				gapT = 0
			end
		else
			okRide = false
		end
		RunService.RenderStepped:Wait()
	end
	local reached = S().d >= to
	F:Invoke("mountSpd", oldSpd)
	local hs2 = F:Invoke("herdStats")
	local seenC = hs2.seenRecycles - hs1.seenRecycles
	local popsC = hs2.fastPops - hs1.fastPops -- P4: quick fade-ins inside the readable distance (Pool.Readable)
	local okNat, natRows = true, {}
	for k = k0, k1 do
		local avg = natN[k] and nat[k] / natN[k] or 0
		okNat = okNat and (k == k1 or avg >= 0.5) and (k == k0 or (natB[k] or 0) >= 0.3)
		table.insert(natRows, string.format("s%d %.0f%%/%s", k, avg * 100, natB[k] and string.format("%.0f%%", natB[k] * 100) or "-"))
	end
	local meanAhead = n > 0 and sumAhead / n or 0
	local avgStr = n > 0 and sumStr / n or 1
	local fps = n / math.max(os.clock() - t0, 1e-3)
	local report = fps < MinFps and function(_, s)
		log(string.format("SKIP %s [throttled %.0f fps < %d: Studio not the foreground window, not valid]", s, fps, MinFps))
	end or check
	report(reached and okRide and maxLive <= capC and avgStr <= 0.25 and maxB <= 4 and maxFar <= 2 and mism == 0 and okNat
		and seenC == 0 and popsC == 0 and minGapC >= C.LaneGap - 0.5 and meanAhead >= 5 and emptyT <= 0.1 * (os.clock() - t0) and emptyLong <= 8
		and noT <= 0.25 * rideT
		and longest <= 12,
		string.format("continuous ride %d->%d (%.0f s%s): live<=%d (cap %d), stragglers avg %.0f%% max %.0f%%, biomes<=%d far<=%d "
			.. "mismatch %d, native avg/+250 %s, in view %d, fast pops %d, min gap %.1f %s, ahead>=%d mean %.1f empty %.0f%% longest %.1f s, no target %.0f%% longest %.1f s",
			k0, k1, os.clock() - t0, reached and "" or " NOT REACHED", maxLive, capC, avgStr * 100, maxStr * 100, maxB, maxFar,
			mism, table.concat(natRows, " "), seenC, popsC, minGapC, gapWhoC, minAhead, meanAhead,
			emptyT / math.max(os.clock() - t0, 1e-3) * 100, emptyLong, rideT > 0 and noT / rideT * 100 or 100, longest))
end
-- 11. Perf snapshot while riding (also run by mode "ride")
local function perfSnapshot(log)
	local frames, t0, worst = 0, os.clock(), 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		frames += 1
		worst = math.max(worst, dt)
	end)
	task.wait(4)
	conn:Disconnect()
	local fps = frames / (os.clock() - t0)
	local nParts, nMesh = 0, 0
	for _, o in workspace:GetDescendants() do
		if o:IsA("BasePart") then
			nParts += 1
			if o:IsA("MeshPart") then
				nMesh += 1
			end
		end
	end
	local function mem(tag)
		local ok, v = pcall(function()
			return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[tag])
		end)
		return ok and v or -1
	end
	log(string.format("PERF fps %.0f (worst frame %.0f ms), parts %d (meshparts %d)%s", fps, worst * 1000, nParts, nMesh,
		fps < MinFps and " [throttled: Studio not the foreground window, not valid]" or ""))
	log(string.format("MEM MB: meshparts %.0f, textures %.0f, parts %.0f, instances %.0f, physics %.0f, total(Studio) %.0f",
		mem("GraphicsMeshParts"), mem("GraphicsTexture"), mem("GraphicsParts"), mem("Instances"), mem("PhysicsCollision"),
		Stats:GetTotalMemoryUsageMb()))
end

-- P4 fog measurement (mode "fog", ~6 min; art/tools/fogmeasure.py captures the screen meanwhile; Studio must stay
-- the foreground window: a background Studio throttles and draws less far). Per section: the mount is moved to
-- the middle of the section and held still (tier 0, so the camera shows Cam.Fov, the narrowest view: on foot,
-- falling, slow mounts), the herd, HUD, weather particles and the rider's own character are hidden, then the
-- section's 5 common species stand one per lane at FogDists studs up the path from the camera: the real models
-- (zone-1 skinned meshes, greybox elsewhere; SS_Ride debug action fogTargets), shown and hidden in turn. A code
-- square in the top-left corner (R = section x 20, G = distance index x 14, B = 220 shown / 20 hidden; black
-- between sections) and magenta corner squares let the sampler pair the frames and map viewport px to screen
-- px; each model's viewport rect (from its bounding box) is printed ("FOGRECT ..."). Nothing in Lighting changes.
local FogDists = { 75, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600, 700, 800, 900, 1000, 1200, 1500 }
local FogHold = 0.6 -- s per shown / hidden state
local function fogMeasure(F, log)
	local cam = workspace.CurrentCamera
	local plr = Players.LocalPlayer
	local pg = plr.PlayerGui
	local guis = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then
			g.Enabled = false
			guis[#guis + 1] = g
		end
	end
	local herd = workspace:FindFirstChild("SS_Herd")
	if herd then
		herd.Parent = nil
	end
	local ems = {}
	for _, e in workspace:GetDescendants() do
		if e:IsA("ParticleEmitter") and e.Enabled then
			e.Enabled = false
			e:Clear()
			ems[#ems + 1] = e
		end
	end
	local hiddenChar = {} -- the rider stands in the middle lane in front of the camera (it hid the lane-3 target)
	local function hideChar()
		for _, o in (plr.Character and plr.Character:GetDescendants() or {}) do
			if o:IsA("BasePart") or o:IsA("Decal") then
				hiddenChar[o] = true
				o.LocalTransparencyModifier = 1
			end
		end
	end
	local mk = Instance.new("ScreenGui")
	mk.Name = "SS_FogCode"
	mk.IgnoreGuiInset = true
	mk.DisplayOrder = 100
	local function sq(pos, col)
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(16, 16)
		f.Position = pos
		f.BorderSizePixel = 0
		f.BackgroundColor3 = col
		f.Parent = mk
		return f
	end
	local magenta = Color3.fromRGB(255, 0, 255)
	sq(UDim2.fromOffset(0, 0), magenta)
	sq(UDim2.new(1, -16, 1, -16), magenta)
	local code = sq(UDim2.fromOffset(16, 0), Color3.new(0, 0, 0))
	mk.Parent = pg
	local oldSpd
	local vp = cam.ViewportSize
	local fovs = {} -- the ride camera's FOV at each section's tier-1 speed (the held mount shows Cam.Fov)
	for k, z in C.Zones do
		fovs[k] = string.format("%.1f", math.min(C.Cam.Fov + C.Cam.FovPerSpeed * z.Speed, C.Cam.FovMax))
	end
	log(string.format("FOGVP %d %d fovRide %s", vp.X, vp.Y, table.concat(fovs, ",")))
	for k, z in C.Zones do
		code.BackgroundColor3 = Color3.new(0, 0, 0) -- not a measured state while teleporting and settling
		F:Invoke("teleport", P.Starts[k] + z.Length / 2)
		local o = F:Invoke("mountSpd", 0)
		oldSpd = oldSpd or o
		task.wait(3)
		hideChar()
		local camD = P.project(cam.CFrame.Position)
		local atm = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
		print(string.format("FOGSEC %d camD %.0f fov %.1f atm %.2f/%.2f", k, camD, cam.FieldOfView, atm and atm.Density or -1,
			atm and atm.Haze or -1))
		for i, D in FogDists do
			local folder, models = F:Invoke("fogTargets", { k = k, d = camD + D })
			for phase = 1, 0, -1 do -- shown, then hidden
				folder.Parent = phase == 1 and workspace or nil
				code.BackgroundColor3 = Color3.fromRGB(k * 20, i * 14, phase == 1 and 220 or 20)
				task.wait(FogHold)
			end
			for lane, m in models do
				local cf, size = m:GetBoundingBox()
				local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
				for _, sx in { -0.5, 0.5 } do
					for _, sy in { -0.5, 0.5 } do
						for _, sz in { -0.5, 0.5 } do
							local v = cam:WorldToViewportPoint(cf * (size * Vector3.new(sx, sy, sz)))
							x0, y0, x1, y1 = math.min(x0, v.X), math.min(y0, v.Y), math.max(x1, v.X), math.max(y1, v.Y)
						end
					end
				end
				print(string.format("FOGRECT %d %d %d %d %s %.1f %.1f %.1f %.1f", k, i, D, lane, (m.Name:gsub(" ", "_")), x0, y0, x1, y1))
			end
		end
	end
	code.BackgroundColor3 = Color3.new(0, 0, 0)
	task.wait(0.5) -- let the sampler see the black code, so it saves the last state before the squares go
	local folder = F:Invoke("fogTargets", nil)
	folder.Parent = nil
	mk:Destroy()
	for o in hiddenChar do
		o.LocalTransparencyModifier = 0
	end
	F:Invoke("mountSpd", oldSpd or 1)
	if herd then
		herd.Parent = workspace
	end
	for _, e in ems do
		e.Enabled = true
	end
	for _, g in guis do
		g.Enabled = true
	end
	log("FOG done: run art/tools/fogmeasure.py analyse")
end

return function(mode)
	local F = RepS:WaitForChild("SS_Debug")
	local gui = Instance.new("ScreenGui")
	gui.Name = "SS_BotPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = Players.LocalPlayer.PlayerGui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.5, 0.86)
	label.Position = UDim2.fromScale(0.49, 0.07)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 17
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Parent = gui
	local lines, pass, total = {}, 0, 0
	local function log(s)
		table.insert(lines, s)
		label.Text = table.concat(lines, "\n")
		print("BOT", s)
	end
	local function check(ok, s)
		total += 1
		if ok then
			pass += 1
		end
		log((ok and "PASS " or "FAIL ") .. s)
	end
	local hs0 = F:Invoke("herdStats")
	local function S()
		return F:Invoke("state")
	end
	local function waitFor(fn, timeout)
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if fn(S()) then
				return true, os.clock() - t0
			end
			task.wait(0.1)
		end
		return false, timeout
	end
	local ideal = F:Invoke("idealPress")
	local ringWait = C.StanceTime + C.RingDuration + C.Leap.MaxSlow + C.Leap.Time + C.Leap.PowerTime + 1
	waitFor(function(s)
		return s.state == "ride"
	end, 20)
	if mode == "fog" then
		gui:Destroy()
		fogMeasure(F, function(s)
			print("BOT", s)
		end)
		return
	end
	if mode == "ride" then -- 10d + PERF only (~90 s): short enough to keep Studio the foreground window
		ride10d(F, S, check, log)
		perfSnapshot(log)
		log(string.format("RESULT %d/%d checks passed", pass, total))
		return pass, total
	end

	-- 1. Path: no kinks. Zone joins ease over SlopeBlend (milestone 2 had a 3-4 degree step in one stud);
	-- the summit eases to flat over SummitFlat. The 1-stud table steps must stay 1 stud long.
	local joinStep, topStep, maxErr = 0, 0, 0
	local prevS, prevPos = P.slope(-100), P.surf(-100, 0, 0).Position
	for d = -99, P.Total + 100 do
		local s, pos = P.slope(d), P.surf(d, 0, 0).Position
		local ds = math.deg(math.abs(s - prevS))
		if d < P.Total then
			joinStep = math.max(joinStep, ds)
		else
			topStep = math.max(topStep, ds)
		end
		maxErr = math.max(maxErr, math.abs((pos - prevPos).Magnitude - 1))
		prevS, prevPos = s, pos
	end
	check(joinStep < 0.1 and topStep < 1 and maxErr < 0.01,
		string.format("path smooth: joins %.3f deg/stud, summit ease %.2f deg/stud, step error %.4f", joinStep, topStep, maxErr))

	-- 1b. Plan-view bends (milestone 5): the Luau path matches the Python twin that warped the meshes
	-- (SS_Markers.PathCheck, written by the Blender build), and lane centres project back exactly on the curve.
	local M = require(RepS:WaitForChild("SS_Markers"))
	local twinErr = 0
	for _, e in M.PathCheck or {} do
		twinErr = math.max(twinErr, (P.surf(e[1], e[2], 0).Position - e[3]).Magnitude)
	end
	local laneErr, maxHead = 0, 0
	for d = 0, P.Total, 10 do
		maxHead = math.max(maxHead, math.abs(math.deg(P.heading(d))))
		for lane = 1, C.LaneCount do
			local x = P.laneX(lane, d)
			local pd, px = P.project(P.surf(d, x, 0).Position)
			laneErr = math.max(laneErr, math.abs(pd - d), math.abs(px - x))
		end
	end
	check(#(M.PathCheck or {}) > 0 and twinErr < 0.01 and laneErr < 0.01,
		string.format("bends: max heading %.1f deg, Luau vs Python path %.4f studs over %d points, lane-centre error %.4f",
			maxHead, twinErr, #(M.PathCheck or {}), laneErr))

	-- 2. Speed and lane table (P1): each section runs at its Speed from SpeedRamp in to its end, enters at the
	-- speed below, and is faster than the one below; lanes never widen going up.
	local okT, parts = true, {}
	for k, z in C.Zones do
		local enter = k > 1 and C.Zones[k - 1].Speed or z.Speed
		local s0, s1, s2 = P.speedAt(P.Starts[k]), P.speedAt(P.Starts[k] + C.SpeedRamp), P.speedAt(P.zoneEnd(k) - 1)
		okT = okT and math.abs(s0 - enter) < 0.01 and math.abs(s1 - z.Speed) < 0.01 and math.abs(s2 - z.Speed) < 0.01
		okT = okT and (k == 1 or (z.Speed > C.Zones[k - 1].Speed and z.LaneWidth <= C.Zones[k - 1].LaneWidth))
		table.insert(parts, string.format("%d:%.1f>%.1f/%.1f", k, s0, s2, P.laneWidth(P.Starts[k] + 1)))
	end
	check(okT, "speed/lane " .. table.concat(parts, " "))

	-- 2c. Sections (P1): 10 of them, each rides in Length / Speed within 10% of its target Time
	local okSec, secs, tot = #C.Zones == 10, {}, 0
	for k, z in C.Zones do
		local t = z.Length / z.Speed
		tot += t
		okSec = okSec and math.abs(t - z.Time) <= 0.1 * z.Time
		table.insert(secs, string.format("%d:%.0fs", k, t))
	end
	check(okSec, string.format("sections: %d, %d studs, %.0f s at tier 1 (%s)", #C.Zones, P.Total, tot, table.concat(secs, " ")))

	-- 2b. Herd stays in its lanes on the curve: every creature body sits on a lane centre (projected)
	local herdErr, herdN = 0, 0
	for _ = 1, 10 do
		for _, m in workspace.SS_Herd:GetChildren() do
			if m.PrimaryPart and not m:GetAttribute("Passing") then -- creatures changing lane are mid-ease
				local pd, px = P.project(m.PrimaryPart.Position)
				local w = P.laneWidth(math.clamp(pd, 0, P.Total))
				local k = math.clamp(math.floor(px / w + (C.LaneCount + 1) / 2 + 0.5), 1, C.LaneCount)
				herdErr = math.max(herdErr, math.abs(px - P.laneX(k, pd)))
				herdN += 1
			end
		end
		task.wait(0.2)
	end
	check(herdN > 0 and herdErr < 0.05, string.format("herd in lanes: %d samples, max off-centre %.3f studs", herdN, herdErr))

	-- 12. Progression (P3), before any teleport so the live run is still legit.
	local DS = RepS:WaitForChild("SS_DebugServer", 10)
	local R = RepS:WaitForChild("SS_Remotes", 10)
	local function prog()
		return F:Invoke("progress")
	end
	local function until_(fn, timeout)
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if fn() then
				return true
			end
			task.wait(0.1)
		end
		return false
	end
	-- 12a. the validator's synthetic climbs and cheats (SS_Progress.selfTest on the server)
	local st, bad = DS:InvokeServer("selfTest"), {}
	for _, e in st do
		if not e.ok then
			table.insert(bad, e.name)
		end
		log(string.format("  %s %s: %s", e.ok and "ok" or "BAD", e.name, e.detail))
	end
	check(#st >= 9 and #bad == 0, string.format("progress self-test: %d/%d%s", #st - #bad, #st,
		#bad > 0 and (" (failed: " .. table.concat(bad, ", ") .. ")") or ""))
	-- 12b. live reports: the run is valid and every reported point is accepted (none clamped), coins follow
	until_(function()
		local p = DS:InvokeServer("profile")
		return p and p.lastScore ~= nil
	end, 5)
	local pr0 = DS:InvokeServer("profile")
	local fixture = pr0.prof
	task.wait(3.5)
	local pr1 = DS:InvokeServer("profile")
	local dAcc, dRep = pr1.prof.score - pr0.prof.score, pr1.lastScore - pr0.lastScore
	local dCoins, wantC = pr1.prof.coins - pr0.prof.coins, dAcc * C.Progress.CoinPerScore
	local cl = prog()
	check(pr1.view.run and pr1.view.run.valid and dRep > 0 and math.abs(dAcc - dRep) < 0.01
		and dCoins >= math.floor(wantC) - 1 and dCoins <= math.ceil(wantC) + 1
		and cl.profile ~= nil and cl.shopVisible,
		string.format("live reports: store %s, run valid %s, reported +%.1f accepted +%.1f, coins +%d (%.2f), client view %s",
			tostring(RepS:GetAttribute("SS_StoreMode")), tostring(pr1.view.run and pr1.view.run.valid), dRep, dAcc, dCoins,
			wantC, cl.profile and "yes" or "NO"))
	local bestBefore, ascentsBefore = pr1.prof.best, pr1.prof.ascents
	fixture = pr1.prof -- (P4) restore the profile as it is now: the ride may pass a checkpoint during the window above
	-- 12c. shop: buying moves coins and levels on the server, and the client's swap tunables follow
	local U1, U2 = C.Upgrades[1], C.Upgrades[2]
	DS:InvokeServer("set", { coins = 1000, best = bestBefore, ascents = ascentsBefore, score = fixture.score, upgrades = {} })
	until_(function()
		local p = prog().profile
		return p and p.coins >= 1000 and (p.upgrades.Ring or 0) == 0
	end, 3)
	local base = prog().base
	local okR, costR = R.Buy:InvokeServer("Ring")
	local okS, costS = R.Buy:InvokeServer("Stance")
	local tuned = until_(function()
		local t = prog().tune
		return math.abs(t.SuccessWindow - (base.SuccessWindow + U1.Window)) < 1e-6
			and math.abs(t.StanceTime - (base.StanceTime - U2.Time)) < 1e-6 and math.abs(t.WobbleAmp - (base.WobbleAmp - U2.Wobble)) < 1e-6
	end, 3)
	local coinsAfter = DS:InvokeServer("profile").prof.coins
	DS:InvokeServer("set", { coins = 0, upgrades = { Ring = 1 } })
	local okPoor, whyPoor = R.Buy:InvokeServer("Ring")
	DS:InvokeServer("set", { coins = 100000, upgrades = { Ring = U1.Max } })
	local okMax, whyMax = R.Buy:InvokeServer("Ring")
	local spent = 1000 - coinsAfter
	check(okR and okS and costR == U1.Cost[1] and costS == U2.Cost[1] and spent >= costR + costS - 3 and spent <= costR + costS
		and tuned and not okPoor and whyPoor == "coins" and not okMax and whyMax == "max",
		string.format("shop: Ring %s (%s) Stance %s (%s), coins 1000 -> %d, tunables %s, broke %s, max %s",
			tostring(okR), tostring(costR), tostring(okS), tostring(costS), coinsAfter, tuned and "follow" or "STALE",
			tostring(whyPoor), tostring(whyMax)))
	-- 12d. save / load round trip (a simulated rejoin): profile identical, best section + upgrades restored on
	-- the client, then the original profile is put back and the tunables return to base
	DS:InvokeServer("set", { coins = 1234, best = 7, ascents = 2, score = 4321, upgrades = { Ring = 2, Stance = 1 } })
	local rt = DS:InvokeServer("roundtrip")
	local restored = until_(function()
		local c = prog()
		return c.profile and c.profile.best == 7 and (c.profile.upgrades.Ring or 0) == 2
			and math.abs(c.tune.SuccessWindow - (base.SuccessWindow + 2 * U1.Window)) < 1e-6
	end, 3)
	DS:InvokeServer("set", fixture)
	local back = until_(function()
		local c = prog()
		return c.profile and (c.profile.upgrades.Ring or 0) == (fixture.upgrades.Ring or 0)
			and math.abs(c.tune.SuccessWindow - (base.SuccessWindow + (fixture.upgrades.Ring or 0) * U1.Window)) < 1e-6
	end, 3)
	check(rt.okSave and rt.equal and rt.after.best == 7 and rt.after.ascents == 2 and rt.after.upgrades.Ring == 2
		and restored and back,
		string.format("save/load (%s): saved %s, equal %s, best %d ascents %d Ring %d Stance %d, client restored %s, fixture back %s",
			tostring(rt.mode), tostring(rt.okSave), tostring(rt.equal), rt.after.best, rt.after.ascents, rt.after.upgrades.Ring or 0,
			rt.after.upgrades.Stance or 0, tostring(restored), tostring(back)))

	-- 3. Species per zone. P2: only the biomes around the rider have creatures, so visit each zone in turn.
	local okS, sp = true, {}
	for k, list in C.Species do
		F:Invoke("teleport", P.Starts[k] + 300)
		task.wait(0.6)
		local info = F:Invoke("herdInfo")
		local n = 0
		local want = 0
		for _, spec in list do
			if (spec.Weight or 1) >= 1 then -- rare / flyer extras spawn by chance; commons must all be there
				want += 1
			end
			if (spec.Weight or 1) >= 1 and info[k][spec.Name] then
				n += 1
			end
		end
		okS = okS and n == want
		table.insert(sp, string.format("z%d=%d/%d", k, n, want))
	end
	check(okS, "species per zone " .. table.concat(sp, " "))
	F:Invoke("teleport", 150) -- back down for the carry-on run

	-- 4. Carry-on across each border
	for k = 1, #C.Zones - 1 do
		local before = S().mount
		F:Invoke("teleport", P.Starts[k + 1] - 12)
		task.wait(1.5)
		local s = S()
		check(s.state == "ride" and s.zone == k + 1 and s.mount == before, string.format("carry-on %d->%d on %s (state %s, zone %d)", k, k + 1, tostring(before), s.state, s.zone))
	end

	-- 5. Ideal-time swaps in every zone
	-- The mount is teleported to d, then (if nothing is in swap range) beside the nearest creature in another
	-- lane: with 5 creatures 200 studs apart per lane, waiting for one to drift into range can take >10 s.
	local function besideCreature(d)
		local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local _, mx = P.project(hrp.Position)
		local best, bd
		for _, m in workspace.SS_Herd:GetChildren() do
			if m.PrimaryPart and not m:GetAttribute("Passing") then -- creatures changing lane are mid-ease
				local pd, px = P.project(m.PrimaryPart.Position)
				if math.abs(px - mx) > 2 and P.zoneOf(math.max(pd, 0)) == P.zoneOf(d) and (not bd or math.abs(pd - d) < bd) then
					best, bd = pd, math.abs(pd - d)
				end
			end
		end
		return best
	end
	local function trySwap(d, pressAt)
		F:Invoke("teleport", d)
		task.wait(0.4)
		if F:Invoke("swapNearest") then
			F:Invoke("pressAt", pressAt)
			return true
		end
		local near = besideCreature(d)
		if near then
			F:Invoke("teleport", near - 4)
			task.wait(0.3)
		end
		for _ = 1, 40 do
			if F:Invoke("swapNearest") then
				F:Invoke("pressAt", pressAt)
				return true
			end
			task.wait(0.15)
		end
		return false
	end
	local N = #C.Zones
	for _, d in { 150, P.Starts[4] + 150, P.Starts[7] + 150, P.Starts[N] + 150 } do
		local started = trySwap(d, ideal)
		task.wait(ringWait)
		local s = S()
		check(started and s.stats.lastResult == "success" and s.state == "ride",
			string.format("swap at %d -> %s (zone %s) %s", d, tostring(s.mount), tostring(s.mountZone), s.stats.lastResult))
	end

	-- 6. Early press -> faceplant -> on foot on the collision -> remount
	-- 60 and Starts[4] + 40 (P2): on foot near a section start, someone must still come from behind
	for _, d in { 60, P.Starts[4] + 40, P.Starts[3] + 400, P.Starts[N] + 400 } do
		local started = trySwap(d, 0.2)
		local okFree = waitFor(function(s)
			return s.state == "free"
		end, ringWait + 2)
		local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		-- standing height above the track: 5 samples over 0.25 s; the settled (lowest) one must be a
		-- standing pose, the highest is reported (a remount jump can start within the window)
		local h, hMax = math.huge, -1
		for _ = 1, 5 do
			if hrp and S().state == "free" then
				local pd = P.project(hrp.Position)
				local cf = P.surf(pd, 0, 0)
				local hh = (hrp.Position - cf.Position):Dot(cf.UpVector)
				h, hMax = math.min(h, hh), math.max(hMax, hh)
			end
			task.wait(0.05)
		end
		local okRide, waited = waitFor(function(s)
			return s.state == "ride"
		end, 30)
		local s = S()
		check(started and okFree and okRide and h > 1.5 and h < 5 and s.stats.lastRemountWait <= 15, -- HERD-SIM: 15 s
			string.format("fail at %d: %s, stood %.1f (max %.1f) above track, remount %.1fs", d, s.stats.lastResult, h, hMax, s.stats.lastRemountWait))
	end

	-- 7. Summit and back to the foothills
	local before = S().stats.summits
	F:Invoke("teleport", P.Total - 15)
	local okSum = waitFor(function(s)
		return s.state == "summit"
	end, 6)
	local okBack = waitFor(function(s)
		return s.state == "ride" and s.mountZone == 1
	end, C.SummitHold + 8)
	local s = S()
	check(okSum and okBack and s.stats.summits == before + 1, string.format("summit: summits %d -> %d, back on %s at d=%.0f", before, s.stats.summits, tostring(s.mount), s.d))

	-- S1 / S3 (STREAMING-PLAN section 6; SS_Stream): right after the summit reset, then after 5 teleports (section
	-- 10 included). S1: the server's focus part vs the client's d, <= 50 studs, and it is the ReplicationFocus.
	-- S3: the jump's prepare(d) ran for that d and returned; a collision slab is under the rider afterwards (0
	-- misses); prepare seconds reported.
	local DST = RepS:WaitForChild("SS_DebugStream", 10)
	local okS1, okS3, rowsS, worstGap, worstPrep = DST ~= nil, true, {}, 0, 0
	local function probeStream(label, wantD)
		task.wait(1) -- >= 4 feed reports at Stream.FeedHz
		local st = F:Invoke("stream")
		local cd = S().d
		local f = DST and DST:InvokeServer("focus")
		local gap = f and math.abs(f.focusD - cd) or math.huge
		local prep = st.prepare
		local prepOk = prep ~= nil and prep.ok and math.abs(prep.d - wantD) < 1
		local slabOk = st.slab ~= nil and st.slab < 40
		okS1 = okS1 and gap <= 50 and f ~= nil and f.isFocus
		okS3 = okS3 and prepOk and slabOk
		worstGap = math.max(worstGap, gap)
		worstPrep = math.max(worstPrep, prep and prep.secs or 0)
		table.insert(rowsS, string.format("%s %.0f/%s/%.2fs%s", label, gap, slabOk and "slab" or "NO SLAB",
			prep and prep.secs or -1, prepOk and "" or " (no prepare)"))
	end
	probeStream("summit", -30)
	for _, d in { P.Starts[2] + 200, P.Starts[5] + 200, P.Starts[8] + 200, P.Starts[10] + 400, P.Starts[3] + 200 } do -- (not near the summit: later checks ride on)
		F:Invoke("teleport", d)
		probeStream(string.format("d%d", d), d)
	end
	check(okS1, string.format("S1 server rider feed: focus vs client d max %.0f studs (limit 50): %s", worstGap,
		table.concat(rowsS, ", ")))
	check(okS3, string.format("S3 jump readiness: slab under the rider after every jump, prepare max %.2f s", worstPrep))

	-- 8. Phone UI: debug readout off, the hint line sits in the top band and never overlaps the title card
	local pg = Players.LocalPlayer.PlayerGui
	local hud, hint, card, tl = pg.SS_UI.Hud, pg.SS_UI.Hint, pg.SS_Titles.Card, pg.SS_UI.Timeline
	local vp = workspace.CurrentCamera.ViewportSize
	local function rect(g)
		return g.AbsolutePosition, g.AbsolutePosition + g.AbsoluteSize
	end
	local function hit(a0, a1, b0, b1)
		return a0.X < b1.X and b0.X < a1.X and a0.Y < b1.Y and b0.Y < a1.Y
	end
	local h0, h1 = rect(hint)
	local c0, c1 = rect(card)
	local t0, t1 = rect(tl)
	local overlap = hit(h0, h1, c0, c1)
	local tlOverlap = hit(t0, t1, h0, h1) or hit(t0, t1, c0, c1)
	-- the hint sits in the top band, below the timeline strip (which pushes it down by its own height)
	check(not hud.Visible and tl.Visible and not overlap and not tlOverlap and h1.Y < vp.Y * 0.25 + require(RepS.SS_Timeline).block(),
		string.format("ui: debug hud %s, timeline y %d-%d, hint y %d-%d, title y %d-%d, overlap %s/%s (viewport %dx%d)",
			hud.Visible and "ON" or "off", t0.Y, t1.Y, h0.Y, h1.Y, c0.Y, c1.Y, tostring(overlap), tostring(tlOverlap), vp.X, vp.Y))

	-- 8c. Shop UI (P3): the coin text and the SHOP button clear the title card, timeline, hint and score; the
	-- opened panel fits on screen
	local ui = pg.SS_UI
	local function textRect(l) -- right-aligned label: only the drawn text
		local a, b = rect(l)
		return Vector2.new(b.X - l.TextBounds.X, a.Y), b
	end
	local k0, k1 = textRect(ui.Coins)
	local b0, b1 = rect(ui.ShopButton)
	local s0, s1 = textRect(ui.Score)
	local clash = {}
	for name, r in { card = { c0, c1 }, timeline = { t0, t1 }, hint = { h0, h1 } } do
		if hit(k0, k1, r[1], r[2]) or hit(b0, b1, r[1], r[2]) then
			table.insert(clash, name)
		end
	end
	if hit(k0, k1, s0, s1) or hit(b0, b1, s0, s1) or hit(k0, k1, b0, b1) then
		table.insert(clash, "score/coins/button")
	end
	ui.ShopPanel.Visible = true
	task.wait()
	local p0, p1 = rect(ui.ShopPanel)
	ui.ShopPanel.Visible = false
	local fits = p0.X >= 0 and p0.Y >= 0 and p1.X <= ui.AbsoluteSize.X and p1.Y <= ui.AbsoluteSize.Y -- the GUI area
	check(ui.ShopButton.Visible and #clash == 0 and fits,
		string.format("shop ui: coins x %d-%d y %d-%d, button x %d-%d y %d-%d, panel %dx%d fits %s, clashes %s", k0.X, k1.X,
			k0.Y, k1.Y, b0.X, b1.X, b0.Y, b1.Y, p1.X - p0.X, p1.Y - p0.Y, tostring(fits),
			#clash > 0 and table.concat(clash, ",") or "none"))

	-- 8d. Herd Journal + medal toast (P4): the JOURNAL button clears the SHOP button, score, coins, timeline and
	-- hint; the opened panel fits on screen below the hint line; the toast (shown for the check) fits, clears the
	-- buttons and keeps its text left of the pips
	local j0, j1 = rect(ui.JournalButton)
	local jclash = {}
	for name, r in { shop = { b0, b1 }, coins = { k0, k1 }, score = { s0, s1 }, timeline = { t0, t1 }, hint = { h0, h1 } } do
		if hit(j0, j1, r[1], r[2]) then
			table.insert(jclash, name)
		end
	end
	ui.JournalPanel.Visible = true
	task.wait()
	local q0, q1 = rect(ui.JournalPanel)
	ui.JournalPanel.Visible = false
	local toast = ui.MedalToast
	toast.Visible = true
	toast.Text.Text = "SECTION 10  BRONZE  45.2 s" -- the longest line
	task.wait()
	local m0, m1 = rect(toast)
	local x0, x1 = rect(toast.Text)
	local pp0 = rect(toast.Pips)
	local textEnd = x0.X + toast.Text.TextBounds.X
	toast.Visible = false
	local area = ui.AbsoluteSize -- the GUI area (the viewport minus the top bar), not Camera.ViewportSize
	local jfits = q0.X >= 0 and q0.Y >= h1.Y and q1.X <= area.X and q1.Y <= area.Y
		and m0.X >= 0 and m1.Y <= area.Y and not hit(m0, m1, b0, b1) and not hit(m0, m1, j0, j1) and textEnd <= pp0.X
	check(ui.JournalButton.Visible and #jclash == 0 and jfits,
		string.format("journal ui: button x %d-%d y %d-%d, panel y %d-%d of %d (hint ends %d), toast y %d-%d text ends %d pips %d, clashes %s",
			j0.X, j1.X, j0.Y, j1.Y, q0.Y, q1.Y, area.Y, h1.Y, m0.Y, m1.Y, textEnd, pp0.X,
			#jclash > 0 and table.concat(jclash, ",") or "none"))

	-- 8e. M7 perf card (C.Perf): filled with the widest values, it fits the GUI area below the hint line, clears the
	-- SHOP / JOURNAL buttons, and every cell's text fits its cell
	if C.Perf.Enabled then
		F:Invoke("perfCard")
		task.wait()
		local card = ui.PerfCard
		local e0, e1 = rect(card)
		local cut = {}
		for _, l in card:GetChildren() do
			if l:IsA("TextLabel") and l.TextBounds.X > l.AbsoluteSize.X + 0.5 then
				table.insert(cut, l.Name)
			end
		end
		F:Invoke("perfCard", "hide")
		local efits = e0.X >= 0 and e0.Y >= h1.Y and e1.X <= area.X and e1.Y <= area.Y
		local eclash = hit(e0, e1, b0, b1) or hit(e0, e1, j0, j1)
		check(efits and not eclash and #cut == 0,
			string.format("perf card: x %d-%d y %d-%d of %dx%d (hint ends %d), clashes buttons %s, cut cells %s", e0.X, e1.X,
				e0.Y, e1.Y, area.X, area.Y, h1.Y, tostring(eclash), #cut > 0 and table.concat(cut, ",") or "none"))
	else
		log("perf card: skipped (C.Perf.Enabled false)")
	end

	-- 9. Name tags and camera occlusion, sampled every frame while riding through each zone:
	-- at most Ui.TagMax tags, no two tags overlapping on screen, the camera never inside a visible
	-- creature, and no visible creature between the camera and the rider.
	local herdF = workspace.SS_Herd
	local maxTags, tagOverlaps, tagOnUi, inside, blocked, frames = 0, 0, 0, 0, 0, 0
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { herdF }
	local function sample()
		local cam = workspace.CurrentCamera
		local camPos = cam.CFrame.Position
		local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		frames += 1
		local rects = {}
		for _, m in herdF:GetChildren() do
			local body = m.PrimaryPart
			local tag = body and body:FindFirstChildOfClass("BillboardGui")
			if tag and tag.Enabled then
				local sp, on = cam:WorldToViewportPoint(body.Position + cam.CFrame.UpVector * tag.StudsOffset.Y)
				if on then
					table.insert(rects, { x = sp.X, y = sp.Y, w = tag.TextLabel.TextBounds.X })
				end
			end
			if body and body.LocalTransparencyModifier < 0.5 then
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") then
						local loc = p.CFrame:PointToObjectSpace(camPos)
						if math.abs(loc.X) < p.Size.X / 2 and math.abs(loc.Y) < p.Size.Y / 2 and math.abs(loc.Z) < p.Size.Z / 2 then
							inside += 1
						end
					end
				end
			end
		end
		maxTags = math.max(maxTags, #rects)
		local inset = game:GetService("GuiService"):GetGuiInset().Y
		local blocks = { hint }
		if card.Title.TextTransparency < 0.95 then
			table.insert(blocks, card)
		end
		for _, r in rects do
			for _, g in blocks do
				local p0, p1 = g.AbsolutePosition, g.AbsolutePosition + g.AbsoluteSize
				local gy = r.y - inset
				if math.abs(r.x - (p0.X + p1.X) / 2) < (r.w + p1.X - p0.X) / 2 - 3 and math.abs(gy - (p0.Y + p1.Y) / 2) < (C.Ui.TagSize.Y + p1.Y - p0.Y) / 2 - 3 then
					tagOnUi += 1
				end
			end
		end
		for i = 1, #rects do
			for j = i + 1, #rects do
				local a, b = rects[i], rects[j]
				if math.abs(a.x - b.x) < (a.w + b.w) / 2 - 3 and math.abs(a.y - b.y) < C.Ui.TagSize.Y - 3 then
					tagOverlaps += 1
				end
			end
		end
		local head = hrp.Position + hrp.CFrame.UpVector * 1.5
		local from, dir = camPos, head - camPos
		for _ = 1, 8 do -- walk past faded parts
			local hit = workspace:Raycast(from, dir, rp)
			if not hit or (hit.Position - head).Magnitude < 6 then
				break
			end
			if hit.Instance.LocalTransparencyModifier < 0.5 then
				blocked += 1
				break
			end
			from = hit.Position + dir.Unit * 0.05
			dir = head - from
		end
	end
	for k in C.Zones do
		F:Invoke("teleport", P.Starts[k] - 20) -- ride in across the border so the title card shows
		task.wait(1.2) -- let the lagged camera catch up after the jump
		local t0 = os.clock()
		while os.clock() - t0 < 3 do
			task.wait()
			sample()
		end
	end
	check(maxTags <= C.Ui.TagMax and tagOverlaps == 0 and tagOnUi == 0 and inside == 0 and blocked == 0,
		string.format("tags+camera over %d frames: max tags %d (limit %d), tag overlaps %d, tags on hint/title %d, cam inside creature %d, creature blocking rider %d",
			frames, maxTags, C.Ui.TagMax, tagOverlaps, tagOnUi, inside, blocked))

	-- 9b. Timeline, mid-zone in each zone: the marker's pixel centre matches its progress p (geometry), p matches
	-- (k - 1 + frac) / N for the distance the strip last drew (mapping), exactly k - 1 checkpoint nodes are lit,
	-- the segments before it are full, and the mount icon holds a creature clone. Row: px/p/want, drawn d, S().d.
	local track, marker, view = tl.Track, tl.Marker, tl.Marker.Disc.View
	local tlBad, tlRows = 0, {}
	for k, z in C.Zones do
		F:Invoke("teleport", P.Starts[k] + z.Length / 2)
		task.wait(1.2) -- the marker eases in
		RunService.RenderStepped:Wait() -- read pixels and progress in one frame
		local centre = marker.AbsolutePosition.X + marker.AbsoluteSize.X / 2
		local got = (centre - track.AbsolutePosition.X) / track.AbsoluteSize.X
		local t = F:Invoke("timeline")
		local want = ((k - 1) + (t.d - P.Starts[k]) / z.Length) / #C.Zones
		local lit, full = 0, 0
		for i = 1, #C.Zones do
			lit += track["Node" .. i]:GetAttribute("Reached") and 1 or 0
			full += track["Seg" .. i].Fill.Size.X.Scale > 0.999 and 1 or 0
		end
		local hasIcon = view:FindFirstChildWhichIsA("Model") ~= nil
		if math.abs(got - t.p) > 0.01 or math.abs(t.p - want) > 0.02 or lit ~= k - 1 or full ~= k - 1 or not hasIcon then
			tlBad += 1
		end
		table.insert(tlRows, string.format("z%d %.3f/%.3f/%.3f d%.0f s%.0f lit%d full%d%s", k, got, t.p, want, t.d, S().d, lit, full,
			hasIcon and "" or " NOICON"))
	end
	check(tlBad == 0 and tl.Marker.Rider.Image ~= "", "timeline: " .. table.concat(tlRows, ", "))

	-- 10. Occlusion probe: with the camera lowered into the herd (Up 4), a creature parked at the camera
	-- must hide (1) and one mid-way to the rider must fade (>= FadeAlpha). The normal camera (Up 10) rides
	-- above the herd, so this forces the case check 9 rarely sees.
	local probes = {}
	local okP = true
	local oldUp = F:Invoke("camUp", 4)
	local top = P.Starts[#C.Zones] + 300
	for _, spot in { { 300, 0, 1 }, { 300, 0.5, C.Cam.FadeAlpha }, { top, 0, 1 }, { top, 0.5, C.Cam.FadeAlpha } } do
		F:Invoke("teleport", spot[1])
		task.wait(1.2)
		local name = F:Invoke("probeOcclusion", spot[2])
		task.wait(0.8)
		local f = F:Invoke("probeFade") or 0
		okP = okP and name ~= nil and f >= spot[3] - 0.05
		table.insert(probes, string.format("d%d t%.1f %s=%.2f", spot[1], spot[2], tostring(name), f))
	end
	F:Invoke("camUp", oldUp)
	F:Invoke("probeOff") -- else the herd check below sees followers waiting at the parked probe
	task.wait(0.5)
	check(okP, "occlusion probe (cam Up 4): " .. table.concat(probes, ", "))

	-- 10b. Herd (M8): no recycle in the rider's view during the whole run; same-lane gap held, sampled 4 s
	-- P2: "in view" = parked or respawned on screen within the section's Pool.ViewDist (camera test); last events listed
	local minGap, gapWho = math.huge, ""
	for _ = 1, 16 do
		local h = F:Invoke("herdStats")
		if h.minGap < minGap then
			minGap, gapWho = h.minGap, h.gapWho
		end
		task.wait(0.25)
	end
	local hs = F:Invoke("herdStats")
	local seen, rec = hs.seenRecycles - hs0.seenRecycles, hs.recycles - hs0.recycles
	local pops = hs.fastPops - hs0.fastPops -- P4: no quick fade-in inside Pool.Readable (respawns ahead use FarFade)
	check(seen == 0 and pops == 0 and minGap >= C.LaneGap - 0.5,
		string.format("herd: %d respawns, %d in view, %d fast pops; min same-lane gap %.1f studs %s (LaneGap %d)%s", rec, seen, pops, minGap, gapWho,
			C.LaneGap, seen > 0 and (" [" .. hs.seenLog .. "]") or ""))

	-- 10c. Herd pool (P2): ride on across a border (no teleport) and sample every frame. At most 2 biomes out of view,
	-- Cap creatures live (about PerLane x LaneCount by the overlap quotas, plus mount and stragglers still in
	-- view); no unridden creature out of view sits outside its own biome; the 300 studs ahead hold >= 2;
	-- 250 studs past the border at least half the creatures in view are the new section's; nothing appears or
	-- vanishes in view.
	-- cap (HERD-SIM): the larger quota of the two live biomes + 15 (rounding, stragglers still in view)
	local cap = math.max(herdOf(3), herdOf(6), herdOf(9)) + 15
	local poolRows, okPool = {}, true
	local seen0 = F:Invoke("herdStats").seenRecycles
	local oldSpd10c -- (P4) the mount is held at tier 1 like 10d: a leftover slow mount (0.75) let the 300 ahead dip to 1
	for _, k in { 4, 7, #C.Zones } do
		F:Invoke("teleport", P.Starts[k] - 60)
		local o = F:Invoke("mountSpd", 1)
		oldSpd10c = oldSpd10c or o
		task.wait(1)
		local maxLive, maxBiomes, mism, minAhead, t0 = 0, 0, 0, math.huge, os.clock()
		local okRide = true
		while S().d < P.Starts[k] + 250 and os.clock() - t0 < 25 do
			local h = F:Invoke("herdStats")
			-- biomes: out of view at most 2 (HERD-SIM: up to 4 overall while stragglers drop back through view)
			maxLive, maxBiomes, mism = math.max(maxLive, h.live), math.max(maxBiomes, h.farBiomes), mism + h.mismatch
			minAhead = math.min(minAhead, h.ahead)
			okRide = okRide and S().state == "ride"
			RunService.RenderStepped:Wait()
		end
		local crossed = S().d >= P.Starts[k] + 250
		local native = F:Invoke("herdStats").native
		okPool = okPool and okRide and crossed and maxLive <= cap and maxBiomes <= 2 and mism == 0 and minAhead >= 2 -- HERD-SIM: >= 2 (respawns spread over the out-of-view band)
			and native >= 0.5
		table.insert(poolRows, string.format("%d->%d: live<=%d far biomes<=%d mismatch %d ahead>=%d native %.0f%%%s", k - 1, k,
			maxLive, maxBiomes, mism, minAhead, native * 100, crossed and "" or " NOT CROSSED"))
	end
	if oldSpd10c then
		F:Invoke("mountSpd", oldSpd10c)
	end
	local seenPool = F:Invoke("herdStats").seenRecycles - seen0
	check(okPool and seenPool == 0, string.format("pool (cap %d): %s; in view %d", cap, table.concat(poolRows, ", "), seenPool))

	ride10d(F, S, check, log)

	-- 12e. Live anti-cheat: the BOT's teleports (summit included) earned no checkpoint and no ascent
	local prE = DS:InvokeServer("profile")
	check(prE.prof.best == bestBefore and prE.prof.ascents == ascentsBefore,
		string.format("teleports uncredited: best %d (before %d), ascents %d (before %d), run %s %s", prE.prof.best, bestBefore,
			prE.prof.ascents, ascentsBefore, prE.view.run and (prE.view.run.valid and "valid" or "invalid") or "-",
			tostring(prE.view.run and prE.view.run.reason)))

	perfSnapshot(log)
	log(string.format("RESULT %d/%d checks passed", pass, total))
	return pass, total
end
