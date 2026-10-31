-- Coins line + upgrade shop (ReplicatedStorage.SS_Shop, P3). SS_Ride builds it under the score and feeds it
-- the server's profile view (SS_Remotes.Profile); Buy goes to the server, which owns coins and levels.
-- Sizes: SS_Config.Ui.Shop. Colours: the current zone's TitleStroke / TitleColor LOOKDEV tokens, white
-- GothamBold text like the hint line.
local RepS = script.Parent
local C = require(RepS:WaitForChild("SS_Config"))

local M = {}
M.__index = M

local function label(parent, name, size, textSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.TextSize = textSize
	l.TextXAlignment = Enum.TextXAlignment.Left
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

-- gui: the SS_UI ScreenGui; y: px where the coin line starts (under the score); buy(id) -> ok, reason
function M.new(gui, y, buy)
	local U = C.Ui.Shop
	local self = setmetatable({ zone = 0, view = nil, buy = buy, rows = {} }, M)

	self.coins = label(gui, "Coins", UDim2.new(0, 160, 0, U.Line), U.Text)
	self.coins.AnchorPoint = Vector2.new(1, 0)
	self.coins.Position = UDim2.new(1, -12, 0, y)
	self.coins.TextXAlignment = Enum.TextXAlignment.Right
	self.coins.Text = ""

	self.open = button(gui, "ShopButton", UDim2.fromOffset(U.Button.X, U.Button.Y), "SHOP", U.Small)
	self.open.AnchorPoint = Vector2.new(1, 0)
	self.open.Position = UDim2.new(1, -12, 0, y + U.Line + 4)
	self.open.Visible = false -- until the first profile arrives

	local n = #C.Upgrades
	local h = U.Pad * 3 + U.Line * 2 + n * U.Row
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.9, 0, 0, h)
	panel.BorderSizePixel = 0
	panel.Active = true -- taps on the panel never reach the herd
	panel.Visible = false
	local lim = Instance.new("UISizeConstraint")
	lim.MaxSize = Vector2.new(U.Width, math.huge)
	lim.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	self.outline = Instance.new("UIStroke")
	self.outline.Thickness = 2
	self.outline.Parent = panel
	panel.Parent = gui
	self.panel = panel

	local title = label(panel, "Title", UDim2.new(1, -U.Pad * 2 - U.Line, 0, U.Line), U.Text)
	title.Position = UDim2.fromOffset(U.Pad, U.Pad)
	title.Text = "SHOP"
	self.close = button(panel, "Close", UDim2.fromOffset(U.Line, U.Line), "X", U.Small)
	self.close.AnchorPoint = Vector2.new(1, 0)
	self.close.Position = UDim2.new(1, -U.Pad, 0, U.Pad)

	for i, u in C.Upgrades do
		local row = Instance.new("Frame")
		row.Name = u.Id
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -U.Pad * 2, 0, U.Row)
		row.Position = UDim2.fromOffset(U.Pad, U.Pad * 2 + U.Line + (i - 1) * U.Row)
		row.Parent = panel
		local name = label(row, "Name", UDim2.new(1, -U.Button.X - 6, 0, U.Text + 4), U.Text)
		local info = label(row, "Info", UDim2.new(1, -U.Button.X - 6, 0, U.Small + 4), U.Small)
		info.Position = UDim2.fromOffset(0, U.Text + 6)
		info.Text = u.Info
		local b = button(row, "Buy", UDim2.fromOffset(U.Button.X, U.Button.Y), "", U.Small)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.fromScale(1, 0.5)
		self.rows[u.Id] = { name = name, buy = b, u = u }
		b.Activated:Connect(function()
			self:purchase(u.Id)
		end)
	end
	self.footer = label(panel, "Footer", UDim2.new(1, -U.Pad * 2, 0, U.Line), U.Small)
	self.footer.Position = UDim2.new(0, U.Pad, 1, -U.Pad - U.Line)

	self.open.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	self.close.Activated:Connect(function()
		panel.Visible = false
	end)
	return self
end

function M:purchase(id)
	task.spawn(function()
		local ok, res = self.buy(id)
		if not ok then
			self.note = res == "coins" and "Not enough coins" or res == "max" and "Already maxed" or "Try again"
			self.noteT = os.clock()
			self:refresh()
		end
	end)
end

function M:refresh()
	local v = self.view
	if not v then
		return
	end
	self.coins.Text = string.format("%d coins", v.coins)
	self.open.Visible = true
	for id, r in self.rows do
		local lvl = v.upgrades[id] or 0
		r.name.Text = string.format("%s  Lv %d/%d", r.u.Name, lvl, r.u.Max)
		local cost = r.u.Cost[lvl + 1]
		r.buy.Text = cost and tostring(cost) or "MAX"
		r.buy.BackgroundTransparency = (cost and v.coins >= cost) and 0 or 0.6
	end
	local note = self.note and os.clock() - (self.noteT or 0) < 2 and self.note
	self.footer.Text = note or string.format("Best: section %d / %d    Ascents: %d", v.best, #C.Zones, v.ascents)
end

function M:set(v)
	self.view = v
	self:refresh()
end

-- Called every frame with the rider's zone; recolours on a zone change.
function M:setZone(k)
	if k == self.zone then
		return
	end
	self.zone = k
	local z = C.Zones[k]
	local fill, dark = Color3.fromHex(z.TitleColor), Color3.fromHex(z.TitleStroke)
	self.panel.BackgroundColor3 = dark
	self.panel.BackgroundTransparency = C.Ui.Timeline.Back
	self.outline.Color = fill
	for _, b in { self.open, self.close } do
		b.BackgroundColor3, b.TextColor3 = fill, dark
	end
	for _, r in self.rows do
		r.buy.BackgroundColor3, r.buy.TextColor3 = fill, dark
	end
end

return M
