-- Studio-only BOT checks for the ride/swap loop on the Blender mountain (ReplicatedStorage.SS_Bot).
-- Run from the command bar during Play Solo (it runs in the client context there):
--   require(game.ReplicatedStorage.SS_Bot)()
-- Results print to Output and stay on a large on-screen panel so a desktop screenshot captures them.
local RepS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

return function()
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

	-- 2. Speed and lane table matches the formula
	local okT, parts = true, {}
	for k in C.Zones do
		for _, d in { P.Starts[k], P.zoneEnd(k) - 1 } do
			local want = (C.BaseSpeed + d * C.SpeedPerStud) * C.Zones[k].SpeedMul
			okT = okT and math.abs(P.speedAt(d) - want) < 0.01
			table.insert(parts, string.format("%d:%.1f/%.1f", d, P.speedAt(d), P.laneWidth(d)))
		end
	end
	check(okT, "speed/lane " .. table.concat(parts, " "))

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

	-- 3. Species per zone
	local info = F:Invoke("herdInfo")
	local okS, sp = true, {}
	for k, list in C.Species do
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
	for _, d in { 150, 1300, 2300, 3300 } do
		local started = trySwap(d, ideal)
		task.wait(ringWait)
		local s = S()
		check(started and s.stats.lastResult == "success" and s.state == "ride",
			string.format("swap at %d -> %s (zone %s) %s", d, tostring(s.mount), tostring(s.mountZone), s.stats.lastResult))
	end

	-- 6. Early press -> faceplant -> on foot on the collision -> remount
	for _, d in { 1500, 3400 } do
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
		check(started and okFree and okRide and h > 1.5 and h < 5,
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
	for _, spot in { { 300, 0, 1 }, { 300, 0.5, C.Cam.FadeAlpha }, { 3300, 0, 1 }, { 3300, 0.5, C.Cam.FadeAlpha } } do
		F:Invoke("teleport", spot[1])
		task.wait(1.2)
		local name = F:Invoke("probeOcclusion", spot[2])
		task.wait(0.8)
		local f = F:Invoke("probeFade") or 0
		okP = okP and name ~= nil and f >= spot[3] - 0.05
		table.insert(probes, string.format("d%d t%.1f %s=%.2f", spot[1], spot[2], tostring(name), f))
	end
	F:Invoke("camUp", oldUp)
	check(okP, "occlusion probe (cam Up 4): " .. table.concat(probes, ", "))

	-- 10b. Herd (M8): no recycle in the rider's view during the whole run; same-lane gap held, sampled 4 s
	local minGap = math.huge
	for _ = 1, 16 do
		minGap = math.min(minGap, F:Invoke("herdStats").minGap)
		task.wait(0.25)
	end
	local hs = F:Invoke("herdStats")
	local seen, rec = hs.seenRecycles - hs0.seenRecycles, hs.recycles - hs0.recycles
	check(seen == 0 and minGap >= C.LaneGap - 0.5,
		string.format("herd: %d recycles, %d in view; min same-lane gap %.1f studs (LaneGap %d)", rec, seen, minGap, C.LaneGap))

	-- 11. Perf snapshot while riding
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
	log(string.format("PERF fps %.0f (worst frame %.0f ms), parts %d (meshparts %d)", fps, worst * 1000, nParts, nMesh))
	log(string.format("MEM MB: meshparts %.0f, textures %.0f, parts %.0f, instances %.0f, physics %.0f, total(Studio) %.0f",
		mem("GraphicsMeshParts"), mem("GraphicsTexture"), mem("GraphicsParts"), mem("Instances"), mem("PhysicsCollision"),
		Stats:GetTotalMemoryUsageMb()))
	log(string.format("RESULT %d/%d checks passed", pass, total))
	return pass, total
end
