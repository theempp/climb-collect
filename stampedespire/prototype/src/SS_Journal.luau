-- Herd Journal + section medal toast (ReplicatedStorage.SS_Journal, P4; owner: medals by section time, pips in
-- the section's own colours, Journal = species + section stats). SS_Ride builds it under the SHOP button and
-- feeds it the server's profile view. One page per section, locked until you reach it: each species (commons,
-- then extras) with its swatch (its SS_Config Color, a LOOKDEV token), times ridden, or ??? if never ridden;
-- the footer shows your best time and medal there. Sizes: C.Ui.Journal / C.Ui.Shop. Colours: the page's (or,
-- for the toast, the medal section's) TitleStroke / TitleColor tokens, white GothamBold text like the shop.
local RepS = script.Parent
local C = require(RepS:WaitForChild("SS_Config"))

local M = {}
M.__index = M

local function label(parent, name, size, textSize, align)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.TextSize = textSize
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function button(parent, name, size, text, textSize)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.TextSize = textSize
	b.Text = text
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	b.Parent = parent
	return b
end

-- n pips (1-3 filled of 3) in fill colour; returns the frame and a setter
local function pips(parent, size)
	local f = Instance.new("Frame")
	f.Name = "Pips"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromOffset(size * 3 + 8, size)
	f.Parent = parent
	local dots = {}
	for i = 1, 3 do
		local d = Instance.new("Frame")
		d.Size = UDim2.fromOffset(size, size)
		d.Position = UDim2.fromOffset((i - 1) * (size + 4), 0)
		d.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = d
		local s = Instance.new("UIStroke")
		s.Thickness = 1.5
		s.Parent = d
		d.Parent = f
		dots[i] = { frame = d, stroke = s }
	end
	return f, function(n, fill)
		for i, d in dots do
			d.frame.BackgroundColor3 = fill
			d.frame.BackgroundTransparency = i <= n and 0 or 1
			d.stroke.Color = fill
		end
	end
end

local function tokens(k)
	local z = C.Zones[k]
	return Color3.fromHex(z.TitleColor), Color3.fromHex(z.TitleStroke)
end

-- gui: the SS_UI ScreenGui; y: px where the JOURNAL button goes (under SHOP); panelTop: px below the hint line
-- (the panel is taller than the shop's: centred it covered the hint and the timeline on a 401 px phone)
function M.new(gui, y, panelTop)
	local S, J = C.Ui.Shop, C.Ui.Journal
	local self = setmetatable({ page = 1, view = nil, rows = {}, shown = 0 }, M)

	self.open = button(gui, "JournalButton", UDim2.fromOffset(S.Button.X, S.Button.Y), "JOURNAL", S.Small)
	self.open.AnchorPoint = Vector2.new(1, 0)
	self.open.Position = UDim2.new(1, -12, 0, y)
	self.open.Visible = false -- until the first profile arrives

	local maxRows = 0
	for _, list in C.Species do
		maxRows = math.max(maxRows, #list)
	end
	-- two columns (P4 re-review: one column of 10 species ran past the bottom of a 401 px phone's GUI area)
	local perCol = math.ceil(maxRows / 2)
	local h = S.Pad * 4 + S.Line * 2 + perCol * J.Row
	local panel = Instance.new("Frame")
	panel.Name = "JournalPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, panelTop)
	panel.Size = UDim2.new(0.9, 0, 0, h)
	panel.BorderSizePixel = 0
	panel.Active = true -- taps on the panel never reach the herd
	panel.Visible = false
	local lim = Instance.new("UISizeConstraint")
	lim.MaxSize = Vector2.new(J.Width, math.huge)
	lim.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	self.outline = Instance.new("UIStroke")
	self.outline.Thickness = 2
	self.outline.Parent = panel
	panel.Parent = gui
	self.panel = panel

	self.prev = button(panel, "Prev", UDim2.fromOffset(S.Line, S.Line), "<", S.Small)
	self.prev.Position = UDim2.fromOffset(S.Pad, S.Pad)
	self.title = label(panel, "Title", UDim2.new(1, -S.Pad * 4 - S.Line * 3, 0, S.Line), S.Small, Enum.TextXAlignment.Center)
	self.title.Position = UDim2.fromOffset(S.Pad * 2 + S.Line, S.Pad)
	self.title.TextTruncate = Enum.TextTruncate.AtEnd
	self.next = button(panel, "Next", UDim2.fromOffset(S.Line, S.Line), ">", S.Small)
	self.next.AnchorPoint = Vector2.new(1, 0)
	self.next.Position = UDim2.new(1, -S.Pad * 2 - S.Line, 0, S.Pad)
	self.close = button(panel, "Close", UDim2.fromOffset(S.Line, S.Line), "X", S.Small)
	self.close.AnchorPoint = Vector2.new(1, 0)
	self.close.Position = UDim2.new(1, -S.Pad, 0, S.Pad)

	for i = 1, maxRows do
		local col, r = (i - 1) // perCol, (i - 1) % perCol
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(0.5, -S.Pad - 4, 0, J.Row)
		row.Position = UDim2.new(col * 0.5, col == 0 and S.Pad or 4, 0, S.Pad * 2 + S.Line + r * J.Row)
		row.Parent = panel
		local sw = Instance.new("Frame")
		sw.Name = "Swatch"
		sw.Size = UDim2.fromOffset(J.Swatch, J.Swatch)
		sw.Position = UDim2.new(0, 0, 0.5, -J.Swatch / 2)
		sw.BorderSizePixel = 0
		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 4)
		sc.Parent = sw
		sw.Parent = row
		local name = label(row, "Name", UDim2.new(1, -J.Swatch - 6 - J.Count, 1, 0), S.Small)
		name.Position = UDim2.fromOffset(J.Swatch + 6, 0)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local count = label(row, "Count", UDim2.new(0, J.Count, 1, 0), S.Small, Enum.TextXAlignment.Right)
		count.AnchorPoint = Vector2.new(1, 0)
		count.Position = UDim2.fromScale(1, 0)
		self.rows[i] = { frame = row, swatch = sw, name = name, count = count }
	end
	self.lock = label(panel, "Locked", UDim2.new(1, -S.Pad * 2, 0, S.Line * 2), S.Text, Enum.TextXAlignment.Center)
	self.lock.Position = UDim2.new(0, S.Pad, 0.5, -S.Line)
	self.footer = label(panel, "Footer", UDim2.new(1, -S.Pad * 3 - J.Pip * 3 - 8, 0, S.Line), S.Small)
	self.footer.Position = UDim2.new(0, S.Pad, 1, -S.Pad - S.Line)
	local fp
	fp, self.setPips = pips(panel, J.Pip)
	fp.AnchorPoint = Vector2.new(1, 0.5)
	fp.Position = UDim2.new(1, -S.Pad, 1, -S.Pad - S.Line / 2)

	-- medal toast: under the buttons, off the lanes; hidden until a medal arrives
	local toast = Instance.new("Frame")
	toast.Name = "MedalToast"
	toast.AnchorPoint = Vector2.new(1, 0)
	toast.Position = UDim2.new(1, -12, 0, y + S.Button.Y + 6)
	toast.Size = UDim2.fromOffset(J.ToastWidth, J.ToastHeight)
	toast.BorderSizePixel = 0
	toast.Visible = false
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 8)
	tc.Parent = toast
	self.toastStroke = Instance.new("UIStroke")
	self.toastStroke.Thickness = 2
	self.toastStroke.Parent = toast
	self.toastText = label(toast, "Text", UDim2.new(1, -J.Pip * 3 - 24, 1, -6), S.Small)
	self.toastText.Position = UDim2.fromOffset(8, 3)
	self.toastText.TextScaled = true -- the longest line ("SECTION 10  BRONZE  45.2 s") must stay left of the pips
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = S.Small
	fit.Parent = self.toastText
	local tp
	tp, self.setToastPips = pips(toast, J.Pip)
	tp.AnchorPoint = Vector2.new(1, 0.5)
	tp.Position = UDim2.new(1, -8, 0.5, 0)
	toast.Parent = gui
	self.toast = toast

	self.open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			self:refresh()
		end
	end)
	self.close.Activated:Connect(function()
		panel.Visible = false
	end)
	self.prev.Activated:Connect(function()
		self.page = (self.page - 2) % #C.Zones + 1
		self:refresh()
	end)
	self.next.Activated:Connect(function()
		self.page = self.page % #C.Zones + 1
		self:refresh()
	end)
	return self
end

function M:refresh()
	local v = self.view
	if not v then
		return
	end
	self.open.Visible = true
	local k = self.page
	local fill, dark = tokens(k)
	self.panel.BackgroundColor3 = dark
	self.panel.BackgroundTransparency = C.Ui.Timeline.Back
	self.outline.Color = fill
	for _, b in { self.prev, self.next, self.close } do
		b.BackgroundColor3, b.TextColor3 = fill, dark
	end
	self.title.Text = string.format("%d / %d  %s", k, #C.Zones, string.upper(C.Zones[k].Name))
	local locked = k > (v.best or 0) + 1 -- reached = every section before it completed once
	self.lock.Visible = locked
	self.lock.Text = locked and string.format("Reach section %d to unlock", k) or ""
	local list = C.Species[k]
	for i, r in self.rows do
		local spec = list[i]
		r.frame.Visible = spec ~= nil and not locked
		if spec then
			local n = v.ridden and v.ridden[spec.Name] or 0
			r.swatch.BackgroundColor3 = spec.Color
			r.swatch.BackgroundTransparency = n > 0 and 0 or 0.7
			r.name.Text = n > 0 and spec.Name or "???"
			r.count.Text = n > 0 and ("x" .. n) or ""
		end
	end
	local medal = v.medals and v.medals[k] or 0
	local secs = v.times and v.times[k] or 0
	self.footer.Text = locked and "" or (medal > 0
		and string.format("Best %.1f s  %s", secs, C.Medals.Names[medal]) or "No medal yet")
	self.setPips(locked and 0 or medal, fill)
end

function M:set(v)
	self.view = v
	if not self.started then -- open on the furthest page reached; don't pop medals from before this session
		self.started = true
		self.page = math.clamp((v.best or 0) + 1, 1, #C.Zones)
		self.shown = v.medal and v.medal.n or 0
	end
	local m = v.medal
	if m and m.n > self.shown then
		self.shown = m.n
		self:pop(m)
	end
	if self.panel.Visible or not self.open.Visible then
		self:refresh()
	end
end

-- Called every frame with the rider's zone: the JOURNAL button wears that zone's tokens, like SHOP.
function M:setZone(k)
	if k == self.zone then
		return
	end
	self.zone = k
	local fill, dark = tokens(k)
	self.open.BackgroundColor3, self.open.TextColor3 = fill, dark
end

function M:pop(m)
	local fill, dark = tokens(m.k)
	self.toast.BackgroundColor3 = dark
	self.toast.BackgroundTransparency = C.Ui.Timeline.Back
	self.toastStroke.Color = fill
	self.toastText.Text = string.format("SECTION %d  %s  %.1f s", m.k, C.Medals.Names[m.tier], m.secs)
	self.setToastPips(m.tier, fill)
	self.toast.Visible = true
	local token = {}
	self.toastToken = token
	task.delay(C.Ui.Journal.Toast, function()
		if self.toastToken == token then
			self.toast.Visible = false
		end
	end)
end

return M
