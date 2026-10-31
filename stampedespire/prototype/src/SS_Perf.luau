-- Per-section perf recorder for the M7 phone test (ReplicatedStorage.SS_Perf, P4; M7-CHECKLIST "Record").
-- Client only. SS_Ride builds it when C.Perf.Enabled and calls begin() at each foothills start and summit() on
-- reaching the top. Every frame (raw RenderStepped dt, not SS_Ride's clamped one) goes to the rider's section:
-- FPS avg, 1% low (mean of the slowest 1% of frames), worst frame and the d / state it happened at. Every
-- C.Perf.MemEvery s: Stats memory total + the four M7 tags (max per section), live creatures (max), parts in
-- workspace (streamed + client-made, counted incrementally) and gameplay pauses (if LocalPlayer.GameplayPaused
-- is readable). At the summit it prints one "PERFREC" line per section (they land in the client log) and shows
-- a card under the hint line until tapped X. Sizes: C.Ui.Perf. Colours: the summit section's TitleStroke
-- backing (at Timeline.Back) / TitleColor outline, each row's section name in that section's TitleColor, white
-- GothamBold text like the shop.
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Players = game:GetService("Players")
local RepS = script.Parent
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

local M = {}
M.__index = M

local Tags = { "GraphicsMeshParts", "GraphicsTexture", "Instances", "PhysicsCollision" }
local Cols = { -- header, width share
	{ "S", 0.08 }, { "FPS", 0.11 }, { "1%", 0.11 }, { "WORST", 0.16 }, { "AT D", 0.16 }, { "MB", 0.14 }, { "LIVE", 0.11 },
	{ "PARTS", 0.13 },
}

local function label(parent, name, textSize, align)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.TextSize = textSize
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

pcall(function()
	Stats.MemoryTrackingEnabled = true -- off by default in a live client: every tag read then warns and returns 0
end)
local function trackingOn()
	local ok, v = pcall(function()
		return Stats.MemoryTrackingEnabled
	end)
	return ok and v
end
local function mem(tag)
	if not trackingOn() then
		return -1
	end
	local ok, v = pcall(function()
		return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[tag])
	end)
	return ok and v or -1
end

-- gui: the SS_UI ScreenGui; panelTop: px below the hint line; probe() -> rider d (or nil), state, live creatures
function M.new(gui, panelTop, probe)
	local U, S = C.Ui.Perf, C.Ui.Shop
	local self = setmetatable({ probe = probe, run = 0, secs = {}, parts = 0, paused = false }, M)

	-- parts in workspace, kept up to date without walking the tree each sample
	for _, o in workspace:GetDescendants() do
		if o:IsA("BasePart") then
			self.parts += 1
		end
	end
	workspace.DescendantAdded:Connect(function(o)
		if o:IsA("BasePart") then
			self.parts += 1
		end
	end)
	workspace.DescendantRemoving:Connect(function(o)
		if o:IsA("BasePart") then
			self.parts -= 1
		end
	end)
	local lp = Players.LocalPlayer
	pcall(function() -- the property may not be readable; then pauses stay "-"
		self.paused = lp.GameplayPaused
		self.pauseReadable = true
		lp:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
			self.paused = lp.GameplayPaused
			local s = self.cur
			if self.paused and s and self.recording then
				s.pauses += 1
			end
		end)
	end)

	local h = S.Pad * 2 + U.Row * (#C.Zones + 3)
	local card = Instance.new("Frame")
	card.Name = "PerfCard"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, panelTop)
	card.Size = UDim2.new(0.9, 0, 0, h)
	card.BorderSizePixel = 0
	card.Active = true
	card.Visible = false
	local lim = Instance.new("UISizeConstraint")
	lim.MaxSize = Vector2.new(U.Width, math.huge)
	lim.Parent = card
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	self.outline = Instance.new("UIStroke")
	self.outline.Thickness = 2
	self.outline.Parent = card
	card.Parent = gui
	self.card = card

	self.title = label(card, "Title", U.Text)
	self.title.Size = UDim2.new(1, -S.Pad * 3 - U.Row, 0, U.Row)
	self.title.Position = UDim2.fromOffset(S.Pad, S.Pad)
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Size = UDim2.fromOffset(U.Row, U.Row)
	close.Position = UDim2.new(1, -S.Pad, 0, S.Pad)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBold
	close.TextSize = U.Text
	close.Text = "X"
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 6)
	cc.Parent = close
	close.Parent = card
	close.Activated:Connect(function()
		card.Visible = false
	end)
	self.close = close

	-- rows: 0 = header, 1..10 = sections; each a list of cells
	self.cells = {}
	for r = 0, #C.Zones do
		local row = {}
		local x = 0
		for i, col in Cols do
			local l = label(card, string.format("R%dC%d", r, i), U.Text,
				i == 1 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right)
			l.Size = UDim2.new(col[2], -2 * S.Pad * col[2] - (i == 1 and 0 or 4), 0, U.Row) -- shares of the inner width
			l.Position = UDim2.new(x, S.Pad * (1 - 2 * x), 0, S.Pad + U.Row * (r + 1))
			l.Text = r == 0 and col[1] or ""
			if r > 0 and i == 1 then
				l.TextColor3 = Color3.fromHex(C.Zones[r].TitleColor)
			end
			x += col[2]
			row[i] = l
		end
		self.cells[r] = row
	end
	self.foot = label(card, "Foot", U.Text)
	self.foot.Size = UDim2.new(1, -S.Pad * 2, 0, U.Row)
	self.foot.Position = UDim2.fromOffset(S.Pad, S.Pad + U.Row * (#C.Zones + 2))

	local memT = 0
	RunService.RenderStepped:Connect(function(dt)
		if not self.recording then
			return
		end
		local d, state, live = self.probe()
		if not d then
			return
		end
		if self.lastD and math.abs(d - self.lastD) > C.Stream.JumpStuds then
			self.jumped = true -- a teleport: not a clean ride
		end
		self.lastD = d
		local k = P.zoneOf(math.max(d, 0))
		local s = self.secs[k]
		if not s then
			s = { frames = {}, sum = 0, worst = 0, mem = 0, tags = {}, live = 0, parts = 0, pauses = 0 }
			self.secs[k] = s
		end
		self.cur = s
		table.insert(s.frames, dt)
		s.sum += dt
		if dt > s.worst then
			s.worst, s.worstD, s.worstState = dt, d, state
		end
		s.live = math.max(s.live, live)
		memT -= dt
		if memT <= 0 or #s.frames == 1 then
			memT = C.Perf.MemEvery
			if trackingOn() then
				s.mem = math.max(s.mem, Stats:GetTotalMemoryUsageMb())
			end
			for _, t in Tags do
				s.tags[t] = math.max(s.tags[t] or 0, mem(t))
			end
			s.parts = math.max(s.parts, self.parts)
		end
	end)
	return self
end

-- a new run starts at the foothills
function M:begin()
	self.run += 1
	self.secs, self.cur, self.lastD, self.jumped = {}, nil, nil, false
	self.recording = true
end

local function summary(s)
	local n = #s.frames
	if n == 0 then
		return nil
	end
	table.sort(s.frames, function(a, b)
		return a > b
	end)
	local m, slow = math.max(1, n // 100), 0
	for i = 1, m do
		slow += s.frames[i]
	end
	return { fps = n / s.sum, low = m / slow, worst = s.worst * 1000, at = s.worstD, state = s.worstState, mem = s.mem,
		tags = s.tags, live = s.live, parts = s.parts, pauses = s.pauses, secs = s.sum }
end

-- fill the card from rows[k] = summary or nil (unreached)
function M:render(title, rows, foot)
	local z = C.Zones[#C.Zones]
	self.card.BackgroundColor3 = Color3.fromHex(z.TitleStroke)
	self.card.BackgroundTransparency = C.Ui.Timeline.Back
	self.outline.Color = Color3.fromHex(z.TitleColor)
	self.close.BackgroundColor3, self.close.TextColor3 = Color3.fromHex(z.TitleColor), Color3.fromHex(z.TitleStroke)
	self.title.Text = title
	for k = 1, #C.Zones do
		local r, c = rows[k], self.cells[k]
		c[1].Text = tostring(k)
		if r then
			c[2].Text = string.format("%.0f", r.fps)
			c[3].Text = string.format("%.0f", r.low)
			c[4].Text = string.format("%.0fms", r.worst)
			c[5].Text = string.format("%.0f", r.at or 0)
			c[6].Text = string.format("%.0f", r.mem)
			c[7].Text = tostring(r.live)
			c[8].Text = tostring(r.parts)
		else
			for i = 2, #Cols do
				c[i].Text = "-"
			end
		end
	end
	self.foot.Text = foot
	self.card.Visible = true
end

-- at the summit: print the per-section lines and show the card
function M:summit()
	if not self.recording then
		return
	end
	self.recording = false
	local rows, tagMax, worst, worstK = {}, {}, 0, nil
	local q = "?"
	pcall(function()
		q = tostring(UserSettings().GameSettings.SavedQualityLevel.Value)
	end)
	local vp = workspace.CurrentCamera.ViewportSize
	print(string.format("PERFREC run %d %s, viewport %dx%d, quality %s, pauses %s", self.run,
		self.jumped and "TELEPORTED (not a clean ride)" or "clean", vp.X, vp.Y, q,
		self.pauseReadable and "readable" or "not readable"))
	for k = 1, #C.Zones do
		local s = self.secs[k] and summary(self.secs[k])
		rows[k] = s
		if s then
			for _, t in Tags do
				tagMax[t] = math.max(tagMax[t] or 0, s.tags[t] or 0)
			end
			if s.worst > worst then
				worst, worstK = s.worst, k
			end
			print(string.format("PERFREC s%d %.1f s: fps %.1f, 1%% low %.1f, worst %.0f ms at d %.0f (%s), mem %.0f MB "
				.. "(mesh %.0f tex %.0f inst %.0f phys %.0f), live %d, parts %d, pauses %s", k, s.secs, s.fps, s.low, s.worst,
				s.at or 0, tostring(s.state), s.mem, s.tags.GraphicsMeshParts or -1, s.tags.GraphicsTexture or -1,
				s.tags.Instances or -1, s.tags.PhysicsCollision or -1, s.live, s.parts,
				self.pauseReadable and tostring(s.pauses) or "-"))
		else
			print(string.format("PERFREC s%d not reached", k))
		end
	end
	self:render(string.format("PERF RUN %d%s  Q%s", self.run, self.jumped and " (TELEPORTED)" or "", q), rows,
		string.format("MAX MB mesh %.0f tex %.0f inst %.0f phys %.0f", tagMax.GraphicsMeshParts or -1,
			tagMax.GraphicsTexture or -1, tagMax.Instances or -1, tagMax.PhysicsCollision or -1))
end

-- BOT layout check: the widest plausible values in every cell
function M:widest()
	local r = { fps = 60, low = 60, worst = 999, at = 17960, mem = 9999, live = 99, parts = 99999 }
	local rows = {}
	for k = 1, #C.Zones do
		rows[k] = r
	end
	self:render("PERF RUN 99 (TELEPORTED)  Q10", rows, "MAX MB mesh 9999 tex 9999 inst 9999 phys 9999")
	return self.card
end

return M
