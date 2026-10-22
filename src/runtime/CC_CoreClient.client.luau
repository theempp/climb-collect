-- Expedition UI: server snapshots own every inventory, bank, home and travel outcome.
-- Landscape phones use full-size targets and scrolling sheets, never a shrunken desktop canvas.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CAS = game:GetService("ContextActionService")
local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local CoreRS = RS:WaitForChild("CC_Core")
local C = require(CoreRS:WaitForChild("CoreConfig"))
local CommerceUI = require(CoreRS:WaitForChild("Client"):WaitForChild("CommerceUI"))
local Species = require(CoreRS:WaitForChild("Species"))
local Net = require(CoreRS:WaitForChild("Net"))
local stateEv, toastEv, fxEv, reqEv = Net.get("CoreState"), Net.get("CoreToast"), Net.get("CoreFx"), Net.get("CoreRequest")
local T = {
	slate = Color3.fromRGB(62, 66, 76), deep = Color3.fromRGB(31, 33, 38),
	golden = Color3.fromRGB(255, 214, 150), moon = Color3.fromRGB(220, 230, 255),
	lantern = Color3.fromRGB(255, 178, 72), meadow = Color3.fromRGB(84, 176, 82),
	aurora = Color3.fromRGB(156, 92, 246), sandstone = Color3.fromRGB(214, 150, 82),
}
local state = { saveState = "loading" }
local preferences = { textScale = 1, reducedMotion = false, timingAssist = true, headlampMode = "auto" }
local clockSkew = 0
local ui = { tab = "Backpack", page = 1, mode = "expedition", device = "keyboard", notices = {}, holding = {}, deferred = {}, renderAt = 0 }
local render, openPanel, closePanel, refreshHud
local profileUI,nameTags,newHUD
local function request(action, payload) reqEv:FireServer(action, payload or {}) end
local function now() return os.time() + clockSkew end
local function fmtTime(sec)
	sec = math.max(0, math.floor(sec or 0))
	return sec >= 3600 and string.format("%dh %02dm", sec // 3600, (sec % 3600) // 60) or string.format("%d:%02d", sec // 60, sec % 60)
end
local function safeGround()
	local ch = plr.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local traversal = ch and ch:GetAttribute("CC_TraversalState")
	return hum and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air and (not traversal or traversal == "ground")
end
local function cancelHolds()
	for prompt in pairs(ui.holding) do pcall(prompt.InputHoldEnd, prompt) end
	table.clear(ui.holding)
end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "CC_CoreUI", false, false
gui.ScreenInsets, gui.ZIndexBehavior, gui.DisplayOrder = Enum.ScreenInsets.CoreUISafeInsets, Enum.ZIndexBehavior.Sibling, 20
gui.Parent = plr:WaitForChild("PlayerGui")
local function corner(object)
	local c = Instance.new("UICorner"); c.CornerRadius, c.Parent = UDim.new(0, 8), object
end
local function stroke(object, color, width)
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.ApplyStrokeMode, s.Parent = color or T.sandstone, width or 1, Enum.ApplyStrokeMode.Border, object
	return s
end
local function frame(parent, props)
	local f = Instance.new("Frame"); f.BackgroundColor3, f.BorderSizePixel = T.slate, 0
	for k, v in pairs(props or {}) do f[k] = v end
	corner(f); f.Parent = parent; return f
end
local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency, l.Font, l.TextColor3 = 1, Enum.Font.GothamMedium, T.moon
	l.TextSize, l.TextWrapped, l.TextXAlignment, l.TextYAlignment = 16, true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
	for k, v in pairs(props or {}) do l[k] = v end
	l:SetAttribute("BaseTextSize", (props and props.TextSize) or 16)
	l.TextSize = math.floor(l:GetAttribute("BaseTextSize") * preferences.textScale)
	l.Parent = parent; return l
end
local function button(parent, text, props, callback)
	local b = Instance.new("TextButton")
	b.Name, b.Text, b.Font = text, text, Enum.Font.GothamBold
	b.TextColor3, b.BackgroundColor3, b.BorderSizePixel = T.golden, T.deep, 0
	b.Size, b.TextSize, b.TextWrapped = UDim2.fromOffset(150, 50), 16, true
	b.AutoButtonColor, b.Selectable = true, true
	for k, v in pairs(props or {}) do b[k] = v end
	b:SetAttribute("BaseTextSize", (props and props.TextSize) or 16)
	b.TextSize = math.floor(b:GetAttribute("BaseTextSize") * preferences.textScale)
	corner(b); local border = stroke(b)
	b.SelectionGained:Connect(function() border.Color, border.Thickness = T.golden, 3 end)
	b.SelectionLost:Connect(function() border.Color, border.Thickness = T.sandstone, 1 end)
	if callback then b.Activated:Connect(callback) end
	b.Parent = parent; return b
end
local function pad(parent, n)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight, p.PaddingTop, p.PaddingBottom = UDim.new(0, n), UDim.new(0, n), UDim.new(0, n), UDim.new(0, n)
	p.Parent = parent
end
local function stack(parent, gap)
	local l = Instance.new("UIListLayout"); l.Padding, l.SortOrder, l.Parent = UDim.new(0, gap or 8), Enum.SortOrder.LayoutOrder, parent
end
local function itemName(it)
	if it.kind == "heartstone" or (it.tier and not it.rarity) then return (it.tier or "") .. " Heartstone" end
	local e = Species.get(it.species); return e and e.name or tostring(it.species or "Expedition find")
end
local function rarity(it)
	local r = it.rarity or it.tier or "Heartstone"
	return string.rep("◆", math.clamp(C.RANK[r] or 1, 1, 6)) .. " " .. r
end
local function discoveryPlace(value)
	if type(value) ~= "string" or value == "" then return nil end
	local id = value:gsub("^spawn:", ""):gsub("^pup:", "")
	local known = { tut_common = "The Foothold", nook_rare_r1 = "Shepherd's hidden nook", nest_r1_hollow = "Hollow nest", nest_r1_lip = "Lip nest" }
	if known[id] then return known[id] end
	if id:match("^shep_%d+$") then return "Shepherd's Road" end
	if id:match("^out_%d+$") then return "Foothold outskirts" end
	return value
end
local function discovery(it)
	local d = it.discovery or {}
	local place = discoveryPlace(d.place or it.place) or (it.region and ({ "Green Valley", "Whispering Forest", "Broken Cliffs", "Storm Ridge", "Frozen Summit" })[it.region]) or discoveryPlace(it.source)
	local method = d.method
	if method then method = ({ encounter = "Encounter", heartstone = "Heartstone", ["net capture"] = "Net capture", ["guardian distraction"] = "Wind chime puzzle" })[method] or method end
	if not method or method == "" then method = (it.kind == "heartstone" or (it.tier and not it.rarity)) and "Heartstone" or (type(it.source) == "string" and it.source:match("^pup:")) and "Net capture" or "Encounter" end
	return (place or "Original discovery preserved") .. " · " .. tostring(method)
end
local function notify(text, kind, seconds, priority)
	if type(text) ~= "string" or text == "" then return end
	for _, n in ipairs(ui.notices) do if n.text == text then return end end
	if ui.currentNotice and ui.currentNotice.text == text then return end
	ui.notices[#ui.notices + 1] = { text = text, kind = kind or "info", duration = seconds or 4.5, priority = priority or (kind == "bad" and 3 or kind == "warn" and 2 or 1) }
	table.sort(ui.notices, function(a, b) return a.priority > b.priority end)
	while #ui.notices > 12 do table.remove(ui.notices) end
end

-- Compact instrument strip. Secondary currencies are in the Backpack tab.
ui.hud = frame(gui, { Name = "ExpeditionHUD", Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(270, 105), BackgroundTransparency = 0.08 })
stroke(ui.hud)
ui.zone = label(ui.hud, { Text = "THE FOOTHOLD", Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -24, 0, 21), TextSize = 14, TextColor3 = T.golden })
ui.staminaText = label(ui.hud, { Text = "Stamina", Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 21), TextSize = 15 })
local staminaRail = frame(ui.hud, { Position = UDim2.fromOffset(12, 53), Size = UDim2.new(1, -24, 0, 7), BackgroundColor3 = T.deep })
ui.staminaFill = frame(staminaRail, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.golden })
ui.pack = label(ui.hud, { Text = "Pack — / —", Position = UDim2.fromOffset(12, 64), Size = UDim2.new(0.59, -12, 0, 25), TextSize = 15 })
ui.level = label(ui.hud, { Text = "Level —", Position = UDim2.new(0.59, 0, 0, 64), Size = UDim2.new(0.41, -12, 0, 25), TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right })
local xpRail = frame(ui.hud, { Position = UDim2.fromOffset(12, 94), Size = UDim2.new(1, -24, 0, 3), BackgroundColor3 = T.deep })
ui.xp = frame(xpRail, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.lantern })
ui.menuButton = button(gui, "Expedition [M]", { Name = "OpenExpedition", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(178, 50) }, function()
	if ui.panel.Visible then closePanel() else openPanel("expedition") end
end)
ui.altitude = frame(gui, { Name = "AltitudeTrack", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 66), Size = UDim2.fromOffset(116, 50), BackgroundTransparency = 0.12 })
ui.altitudeText = label(ui.altitude, { Text = "0 m", Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -20, 0, 25), TextColor3 = T.golden, TextSize = 17 })
local altitudeRail = frame(ui.altitude, { Position = UDim2.fromOffset(10, 36), Size = UDim2.new(1, -20, 0, 4), BackgroundColor3 = T.deep })
ui.altitudeFill = frame(altitudeRail, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.sandstone })
for i = 0, 4 do frame(altitudeRail, { Position = UDim2.new(i / 4, -2, 0.5, -3), Size = UDim2.fromOffset(4, 6), BackgroundColor3 = T.golden }) end
ui.save = frame(gui, { Name = "SaveStatus", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(500, 58), BackgroundColor3 = T.deep })
stroke(ui.save, T.lantern)
ui.saveText = label(ui.save, { Text = "Loading your expedition…", Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -115, 1, -8), TextSize = 15 })
ui.retry = button(ui.save, "Retry", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(88, 48), TextSize = 15 }, function()
	if state.bank and state.bank.retryable then request("bankRetry") else request("state") end
	notify("Checking your expedition status…", "info")
end)
ui.notice = frame(gui, { Name = "PriorityMessage", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(540, 72), BackgroundColor3 = T.deep, Visible = false })
ui.noticeBorder = stroke(ui.notice)
ui.noticeText = label(ui.notice, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 1, -12), TextSize = 16 })

-- One sheet for menus and physical stations. Pinned header / footer, scrolling body.
ui.shadow = frame(gui, { Name = "SheetShadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 4, 0.5, 6), BackgroundColor3 = T.deep, BackgroundTransparency = 0.25, ZIndex = 40, Visible = false })
ui.panel = frame(gui, { Name = "ExpeditionPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -24, 1, -16), BackgroundColor3 = T.slate, ZIndex = 41, Visible = false })
stroke(ui.panel, T.golden, 2)
ui.heading = label(ui.panel, { Text = "EXPEDITION", Font = Enum.Font.FredokaOne, TextSize = 24, TextColor3 = T.golden, Position = UDim2.fromOffset(16, 5), Size = UDim2.new(1, -86, 0, 45) })
ui.close = button(ui.panel, "×", { Name = "CloseSheet", TextSize = 26, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(52, 48) }, function() closePanel() end)
ui.tabs = Instance.new("Frame")
ui.tabs.BackgroundTransparency, ui.tabs.Position, ui.tabs.Size, ui.tabs.Parent = 1, UDim2.fromOffset(12, 56), UDim2.new(1, -24, 0, 48), ui.panel
ui.tabButtons = {}
for i, name in ipairs({ "Backpack", "Collection", "Routes", "Settings" }) do
	ui.tabButtons[name] = button(ui.tabs, name, { Name = "Tab" .. name, Position = UDim2.new((i - 1) / 4, 3, 0, 0), Size = UDim2.new(0.25, -6, 1, 0), TextSize = 16 }, function()
		ui.tab, ui.page, ui.choose = name, 1, nil; render(true)
	end)
end
ui.body = Instance.new("ScrollingFrame")
ui.body.Name, ui.body.BackgroundTransparency, ui.body.BorderSizePixel = "Content", 1, 0
ui.body.Position, ui.body.Size = UDim2.fromOffset(16, 115), UDim2.new(1, -32, 1, -177)
ui.body.AutomaticCanvasSize, ui.body.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
ui.body.ScrollBarThickness, ui.body.ScrollBarImageColor3 = 6, T.golden
ui.body.ScrollingDirection, ui.body.ElasticBehavior = Enum.ScrollingDirection.Y, Enum.ElasticBehavior.WhenScrollable
ui.body.Parent = ui.panel; stack(ui.body, 9)
ui.footer = label(ui.panel, { Name = "LiveWorldNote", Text = "The world keeps moving. Find safe ground to browse.", Position = UDim2.new(0, 16, 1, -53), Size = UDim2.new(1, -170, 0, 44), TextSize = 13 })
ui.done = button(ui.panel, "Continue", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -7), Size = UDim2.fromOffset(142, 48) }, function() closePanel() end)
local function fit()
	local sz = gui.AbsoluteSize
	if sz.X <= 0 or sz.Y <= 0 then sz = workspace.CurrentCamera.ViewportSize end
	local w, h = math.min(920, sz.X - 24), math.min(650, sz.Y - 16)
	ui.panel.Size, ui.shadow.Size = UDim2.fromOffset(w, h), UDim2.fromOffset(w, h)
	ui.hud.Size = UDim2.fromOffset(sz.X < 700 and 236 or 270, 105)
	ui.menuButton.Size = UDim2.fromOffset(sz.X < 700 and 150 or 178, 50)
	ui.save.Size = UDim2.fromOffset(math.min(500, sz.X - 28), 72)
	ui.notice.Size = UDim2.fromOffset(math.min(540, sz.X - 32), 72)
	if ui.tutorial then
		ui.tutorial.Size = UDim2.fromOffset(math.min(430, sz.X - 32), 66)
		ui.tutorial.Position = UDim2.new(0.5, 0, 0, 120)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit(); if ui.panel.Visible and render then render() end end)

local rowOrder = 0
local function row(title, detail, actions, tint)
	rowOrder += 1
	local f = frame(ui.body, { Name = "Row" .. rowOrder, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = rowOrder, BackgroundColor3 = T.deep, BackgroundTransparency = 0.16 })
	pad(f, 12); stack(f, 7)
	label(f, { Name = "Title", Text = title, TextColor3 = tint or T.golden, TextSize = 18, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
	if detail and detail ~= "" then label(f, { Name = "Detail", Text = detail, TextSize = 15, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 }) end
	if actions and #actions > 0 then
		local columns = math.min(ui.panel.AbsoluteSize.X < 600 and 2 or 3, #actions)
		local tray = Instance.new("Frame")
		tray.BackgroundTransparency, tray.Size, tray.LayoutOrder, tray.Parent = 1, UDim2.new(1, 0, 0, math.ceil(#actions / columns) * 56 - 6), 3, f
		for i, a in ipairs(actions) do
			local b = button(tray, a.label, { Name = a.id or ("Row" .. rowOrder .. "Action" .. i), Position = UDim2.new(((i - 1) % columns) / columns, 0, 0, math.floor((i - 1) / columns) * 56), Size = UDim2.new(1 / columns, -6, 0, 50), TextSize = 15 }, function()
				if a.enabled ~= false then if a.run then a.run() elseif a.action then request(a.action, a.payload) end end
			end)
			if a.enabled == false then b.AutoButtonColor, b.Selectable, b.TextTransparency = false, false, 0.45 end
		end
	end
	return f
end
local function action(text, name, payload, enabled) return { label = text, action = name, payload = payload, enabled = enabled } end
local function localAction(text, fn) return { label = text, run = fn } end
local function pageRows(items, fn)
	local size, count = 12, math.max(1, math.ceil(#items / 12))
	ui.page = math.clamp(ui.page, 1, count)
	for i = (ui.page - 1) * size + 1, math.min(#items, ui.page * size) do fn(items[i], i) end
	if count > 1 then row(string.format("Page %d of %d", ui.page, count), "", {
		{ label = "Previous", enabled = ui.page > 1, run = function() ui.page -= 1; render(true) end },
		{ label = "Next", enabled = ui.page < count, run = function() ui.page += 1; render(true) end },
	}) end
end
local BANNER = {
	loading = "Loading your expedition. Your live world is still running.",
	unavailable = "Saving is unavailable. Keep your finds; check again shortly.",
	locked = "Your profile is open elsewhere. Waiting for a safe reconnect.",
	lost = "This session cannot save. Rejoin to continue safely.",
	outdated = "This server needs an update. Rejoin a newer server.",
}
refreshHud = function()
	ui.pack.Text = string.format("%s %d/%d", (state.used or 0) >= (state.capacity or C.SLOTS_BASE) and "FULL" or "Pack", state.used or 0, state.capacity or C.SLOTS_BASE)
	ui.level.Text = state.level and ("Level " .. state.level) or "Level —"
	local floor, ceiling = state.levelXp or 0, state.nextXp
	ui.xp.Size = UDim2.fromScale(ceiling and math.clamp(((state.xp or 0) - floor) / math.max(1, ceiling - floor), 0, 1) or (state.level and 1 or 0), 1)
	local bank = state.bank or {}
	local pending = bank.status == "saving" or bank.status == "uncertain" or bank.status == "error"
	ui.save.Visible = state.saveState ~= "ok" or pending
	ui.saveText.Text = pending and (bank.message or (bank.status == "saving" and "Banking securely… keep this session open." or "Banking needs a status check. Your finds are protected.")) or BANNER[state.saveState] or "Checking your expedition…"
	ui.retry.Visible = bank.retryable == true or (state.saveState ~= "ok" and state.saveState ~= "lost" and state.saveState ~= "outdated")
	ui.saveText.Size = UDim2.new(1, ui.retry.Visible and -115 or -24, 1, -8)
	fit()
end

local function backpack()
	row(string.format("BACKPACK  ·  %d / %d slots", state.used or 0, state.capacity or C.SLOTS_BASE), "Carry finds to the Foothold campfire to bank them. Landing, shuttles and lockers do not bank your cargo.")
	if state.bank and state.bank.status and state.bank.status ~= "idle" then row("Bank · " .. state.bank.status, state.bank.message or "Only confirmed bank transactions appear in your Collection.", state.bank.retryable and { action("Check transaction", "bankRetry") } or nil) end
	if #(state.items or {}) == 0 then row("Room for your next discovery", "Look for creatures in visible rock and forest nooks. Hold the interaction prompt to collect one.") end
	pageRows(state.items or {}, function(it) row(itemName(it), rarity(it) .. " · " .. (it.slots or 1) .. " slot(s)\n" .. discovery(it)) end)
	if state.travelOffer then row(state.travelOffer.label or "Camp shuttle", "Return with your backpack to the Foothold entrance, then walk to the bank.", { action("Shuttle to Foothold", "shuttle", {}, state.travelOffer.available ~= false) }) end
	if state.resumeOffer and (state.used or 0) == 0 then row("Resume your expedition", "Your highest camp is ready. You can also begin at the Foothold with this empty pack.", { action("Start at the Foothold", "resumeFoothold") }) end
	if state.inHome then row("Home visit", "Return to the same cabin entrance with your backpack.", { action("Return to Foothold", "homeReturn") }) end
	row("Expedition record", string.format("%d Cairn Coins  ·  %d species found  ·  %d banked creatures", state.coins or 0, state.codexCount or 0, state.bankCount or 0))
	for _, lk in ipairs(state.lockers or state.lockerSummary or {}) do row(lk.label or lk.camp, string.format("%d find(s) stored here. Return to this camp to retrieve them.", lk.count or lk.used or 0)) end
end
local function collection()
	local items = state.collection or {}
	row("COLLECTION  ·  " .. tostring(state.codexCount or 0) .. " species", "Banked finds are safe. Read your collection anywhere; manage nests and earning spaces at home.", {
		localAction("Creatures", function() ui.collectionKind = "creatures"; ui.page = 1; render(true) end),
		localAction("Heartstones", function() ui.collectionKind = "stones"; ui.page = 1; render(true) end),
		localAction("Memories", function() ui.collectionKind = "memories"; ui.page = 1; render(true) end),
	})
	if ui.collectionKind == "stones" then
		local stones = state.heartstones or {}
		if #stones == 0 then row("No banked Heartstones yet", "Find a guarded nook, bank its Heartstone, then place it manually in one of your two home nests.") end
		pageRows(stones, function(it) row(itemName(it), string.format("%.1f / %d adventure progress%s\nVisit home to place or hatch this stone. New expedition discoveries advance occupied nests.", it.progress or 0, it.required or 1, it.ready and " · READY" or "")) end)
		return
	elseif ui.collectionKind == "memories" then
		local entries = {}
		for key, memory in pairs(state.memories or {}) do if type(memory) == "table" then entries[#entries + 1] = { species = memory.species or key, place = memory.place, method = memory.method } end end
		table.sort(entries, function(a, b) return tostring(a.species) < tostring(b.species) end)
		if #entries == 0 then row("Your first-discovery journal", "Bank a new expedition discovery to record its original place and discovery method.") end
		pageRows(entries, function(m) row(itemName(m), tostring(m.place or "Mountain expedition") .. " · " .. tostring(m.method or "Discovery")) end)
		return
	end
	if #items == 0 then row("Your collection starts at the bank", "Carry your first find to the Foothold campfire. It appears here after the bank confirms your save.") end
	pageRows(items, function(it)
		local id = it.creatureId or it.uid
		local companion = it.companion == true or state.companion == id or (state.home and state.home.companion == id)
		row((it.favorite and "★ " or "") .. itemName(it), rarity(it) .. ((it.mutation and it.mutation ~= "") and (" · " .. it.mutation) or "") .. "\n" .. discovery(it), {
			action(it.favorite and "Unfavorite" or "Favorite", "homeFavorite", { creatureId = id }),
			action(companion and "Tuck companion away" or "Set companion", "homeCompanion", { creatureId = companion and "" or id }),
		})
	end)
end
local ROUTES = {
	{ id = "Shepherd", name = "Shepherd", difficulty = "◆  Steady", detail = "Natural paths, rock steps and protected practice climbs.", available = true },
	{ id = "Waterfall", name = "Waterfall", difficulty = "◆◆  Adventurous", detail = "Waterfall ledges and vertical climbing sections.", available = true },
	{ id = "Ledge", name = "Ledge", difficulty = "◆◆◆  Exposed", detail = "Coming Soon. This route is closed.", available = false },
	{ id = "Spire", name = "Spire", difficulty = "◆◆◆◆  Technical", detail = "Coming Soon. This route is closed.", available = false },
}
local function routes()
	row("THE MOUNTAIN", "Five regions, four route identities. Walk to a marked route entrance to begin. The map never teleports or unlocks a closed route.")
	for _, r in ipairs(state.routes or ROUTES) do
		local closed = r.available == false or r.status == "Coming Soon" or r.id == "Ledge" or r.id == "Spire"
		row(r.name or r.id, string.rep("◆", r.pips or 1) .. " " .. (r.difficulty or "") .. "\n" .. (r.detail or r.description or "") .. "\n" .. (closed and "COMING SOON" or "OPEN · follow the marked entrance"), nil, closed and T.moon or T.golden)
	end
	row("REGION JOURNEY", "1  Green Valley\n2  Whispering Forest\n3  Broken Cliffs\n4  Storm Ridge\n5  Frozen Summit")
	row("Camp progress", string.format("Highest camp reached: %d / 4\nCheckpoints keep your climb progress. Ordinary walkoffs remain real falls.", state.highestCamp or 0))
	local lines = {}
	for key, v in pairs(state.viewpoints or state.journal or {}) do if v then lines[#lines + 1] = type(v) == "table" and (v.label or v.name or tostring(key)) or tostring(key) end end
	table.sort(lines)
	row("Viewpoint journal", #lines > 0 and table.concat(lines, "\n") or "Visit a marked viewpoint and use its journal prompt to collect a stamp.")
end
local function setPreference(key, value)
	preferences[key] = value
	plr:SetAttribute(({ textScale = "CC_TextScale", reducedMotion = "CC_ReducedMotion", timingAssist = "CC_TimingAssist", headlampMode = "CC_HeadlampMode" })[key], value)
	request("settingsSet", { key = key, value = value })
	for _, obj in ipairs(gui:GetDescendants()) do if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj:GetAttribute("BaseTextSize") then obj.TextSize = math.floor(obj:GetAttribute("BaseTextSize") * preferences.textScale) end end
	render()
end
local function controlsText()
	local controls = ui.device == "gamepad" and "L1 / R1: climbing rhythm · X: interact\nY: marked anchor, recover or parachute\nD-pad right: foothold choice · Down: climb down\nB: deliberate release · Select: Expedition\nB closes an open panel" or ui.device == "touch" and "Use the left / right climbing buttons shown on the rock. Context actions appear when available. Release stays separate from the rhythm." or "Q / R: climbing rhythm · E: interact\nF: marked anchor, recover or parachute\nTab: foothold choice · C: climb down\nX: deliberate release · M: Expedition"
	return controls .. "\nInteraction prompts follow your active device. Movement and camera controls stay available while browsing."
end
local function settings()
	row("READABILITY", "Text size changes the text, never the size of your touch targets.", {
		localAction("Standard", function() setPreference("textScale", 1) end), localAction("Larger", function() setPreference("textScale", 1.15) end), localAction("Largest", function() setPreference("textScale", 1.3) end),
	})
	row("Reduced motion · " .. (preferences.reducedMotion and "On" or "Off"), "Keep messages and progress feedback while reducing pulses and celebratory motion.", { localAction(preferences.reducedMotion and "Turn off" or "Turn on", function() setPreference("reducedMotion", not preferences.reducedMotion) end) })
	row("Timing assistance · " .. (preferences.timingAssist and "On" or "Off"), "A more generous climbing rhythm with the same rewards. Waiting never counts as repeated mistakes.", { localAction(preferences.timingAssist and "Turn off" or "Turn on", function() setPreference("timingAssist", not preferences.timingAssist) end) })
	row("Headlamp · " .. tostring(preferences.headlampMode), "Automatic light in darkness. Manual on/off applies only when dark; there is no battery.", {
		localAction("Automatic", function() setPreference("headlampMode", "auto") end), localAction("On in darkness", function() setPreference("headlampMode", "on") end), localAction("Off in darkness", function() setPreference("headlampMode", "off") end),
	})
	ui.controlsRow = row("Controls · " .. ui.device, controlsText())
	row("Feedback", "Rarity includes its name and diamond pips. Cues and system messages remain visible without sound. This multiplayer world does not pause in menus.")
end
local function locker()
	local lk = state.locker; if not lk then row("Locker closed", "Return to a camp locker to open it."); return end
	row((lk.label or lk.camp or "Camp") .. " locker", string.format("%d / %d slots · safe storage, not banked. Retrieve finds here and carry them to the Foothold.", lk.used or 0, lk.slots or 1))
	for _, it in ipairs(lk.items or {}) do row(itemName(it), rarity(it), { action("Take into backpack", "lockerTake", { uid = it.uid }, (state.used or 0) + (it.slots or 1) <= (state.capacity or C.SLOTS_BASE)) }) end
	if #(lk.items or {}) == 0 then row("The locker is empty", "Store a find from your backpack below.") end
	for _, it in ipairs(state.items or {}) do row("Carrying · " .. itemName(it), rarity(it), { action("Store in this locker", "lockerStore", { uid = it.uid }, (lk.used or 0) + (it.slots or 1) <= (lk.slots or 1)) }) end
end
local function directory()
	row("CABIN VISITS", "Step through a cabin portal to visit a home. Your backpack stays with you.", { action("Enter your home", "homeEnter") })
	for _, owner in ipairs((state.homeDirectory or {}).owners or {}) do if owner.ownerId ~= plr.UserId then row(owner.name or "Explorer", "Visit and observe. The owner manages their creatures and earnings.", { action("Visit home", "homeVisit", { ownerId = owner.ownerId }) }) end end
end
local function practice()
	local p = state.practice
	if not p then row("Practice station closed", "Return to the practice crag to choose a lesson."); return end
	row("HOME PRACTICE CRAG", string.format("Finite training · +%d stamina earned · total stamina cap %d\nClimb the authored walls in order. Take your time; there is no countdown.", p.bonus or 0, p.cap or 140))
	for _, lesson in ipairs(p.sections or {}) do
		local status = lesson.complete and "COMPLETE" or lesson.unlocked and "AVAILABLE" or "LOCKED"
		local acts = lesson.unlocked and { action(lesson.complete and "Practice again" or "Start lesson", "practiceStart", { id = lesson.id }) } or { action("Unlock · " .. (lesson.cost or 0) .. " coins", "practiceBuy", { id = lesson.id }, (state.coins or 0) >= (lesson.cost or 0)) }
		row(lesson.label or ("Section " .. lesson.id), status .. " · " .. tostring(lesson.gain or 0) .. " stamina progression\n" .. (lesson.complete and "Already earned. Repeating does not grant this upgrade again." or "Complete the previous lesson before unlocking the next."), acts)
	end
end
local function home()
	local h = state.home; if not h then row("Home station closed", "Visit your home station to manage nests and habitats."); return end
	if h.readOnly or (h.ownerId and h.ownerId ~= plr.UserId) then
		row((h.ownerName or "Explorer") .. "'s home", "Visiting · you can observe. The owner manages creatures, nests and earnings.", { action("Return to Foothold", "homeReturn") })
		for _, n in ipairs(h.nests or {}) do row("Heartstone nest " .. tostring(n.slot), n.id and string.format("Adventure progress %.1f / %d%s", n.progress or 0, n.required or 1, n.ready and " · Ready" or "") or "Empty") end
		local assigned = {}; for _, id in ipairs(h.assigned or {}) do assigned[id] = true end
		for _, it in ipairs(h.collection or h.displayed or {}) do if assigned[it.creatureId] or not h.collection then row(itemName(it), rarity(it)) end end
		return
	end
	if ui.choose then
		local choose = ui.choose
		row(choose.kind == "stone" and ("Choose a Heartstone for nest " .. choose.slot) or ("Choose a creature for space " .. choose.slot), "You choose what lives here. Other collection items remain safe.", { localAction("Back to home", function() ui.choose = nil; ui.page = 1; render(true) end) })
		local list = {}
		if choose.kind == "stone" then
			local occupied = {}; for _, n in ipairs(h.nests or {}) do if n.id then occupied[n.id] = true end end
			for _, stone in ipairs(h.stones or {}) do if not occupied[stone.id] then list[#list + 1] = stone end end
		else list = state.collection or {} end
		if #list == 0 then row("Nothing available yet", choose.kind == "stone" and "Bank a Heartstone, then place it here manually." or "Bank a creature to settle it into your home.") end
		pageRows(list, function(it)
			local a = choose.kind == "stone" and action("Place in nest", "nestPlace", { slot = choose.slot, id = it.id or it.uid }) or action("Assign to space", "homeAssign", { slot = choose.slot, creatureId = it.creatureId or it.uid })
			row(itemName(it), rarity(it) .. "\n" .. discovery(it), { a })
		end); return
	end
 local cost=h.lampCost or 1500;local short=math.max(0,cost-(state.coins or 0))
 local owned=h.decorations and h.decorations.lamp
 if owned then
  row("SUNBEAM LAMP SET", "Permanent decoration · yours to keep. Functional home upgrades stay separate.", {action(h.decorEquipped and h.decorEquipped.lamp and "Store lamp set" or "Install lamp set","homeDecorEquip",{id="lamp",enabled=not (h.decorEquipped and h.decorEquipped.lamp)})})
 elseif short==0 then row("SUNBEAM LAMP SET", "1,500 Cairn Coins · you have enough. No Robux needed.",{action("Install · 1,500 coins","homeDecorBuy",{id="lamp"})})
 else
  local pack=short<=100 and 100 or short<=350 and 350 or short<=900 and 900 or 2000
  row("SUNBEAM LAMP SET", "1,500 coins · need "..short.." more. Optional "..pack.."-coin pack"..(short>pack and (" leaves "..(short-pack).." to earn.") or ".").." Buying coins never installs the decoration.", {localAction("View "..pack.." coins",function() CommerceUI.open("coins"..pack) end),localAction("Keep earning",closePanel)})
 end
	row("YOUR HOME", "Banking new expedition discoveries advances both occupied nests. Banked stones stay in storage until you place them.", state.inHome and { action("Return to Foothold", "homeReturn") } or nil)
	for i = 1, 2 do
		local n = (h.nests or {})[i] or { slot = i }; local slot = n.slot or i
		if n.id then row("Heartstone nest " .. slot, string.format("%.1f / %d adventure progress%s", n.progress or 0, n.required or 1, n.ready and " · READY TO HATCH" or ""), { action("Hatch deliberately", "nestHatch", { slot = slot }, n.ready == true), action("Return to storage", "nestRemove", { slot = slot }) })
		else row("Heartstone nest " .. slot, "Empty · choose a banked stone to begin.", { localAction("Choose Heartstone", function() ui.choose = { kind = "stone", slot = slot }; ui.page = 1; render(true) end) }) end
	end
	row("Heartstone storage", tostring(#(h.stones or {})) .. " banked stone(s) safely stored. Stones never place themselves.")
	row("Displayed earning spaces", string.format("%d coins ready at last check · %s coins per hour\nOnly assigned creatures earn. Offline earnings are capped at %s hours.", math.floor(h.income or 0), tostring(h.rate or 0), tostring(h.offlineHours or 8)), { action("Collect income", "homeCollect"), action("Equip Best", "homeEquipBest") })
	local byId = {}; for _, it in ipairs(state.collection or {}) do byId[it.creatureId or it.uid] = it end
	local spaces = type(h.spaces) == "number" and h.spaces or #(h.spaces or {})
	for i = 1, spaces do
		local assigned = (h.assigned or {})[i]
		local id = type(assigned) == "table" and (assigned.creatureId or assigned.uid) or assigned
		local it, slot = id and byId[id], i
		local acts = { localAction("Choose creature", function() ui.choose = { kind = "creature", slot = slot }; ui.page = 1; render(true) end) }
		if it then acts[#acts + 1] = action("Pet", "homePet", { creatureId = id }); acts[#acts + 1] = action("Clear space", "homeAssign", { slot = slot, creatureId = "" }) end
		row("Space " .. slot .. " · " .. (it and itemName(it) or "Empty"), it and (rarity(it) .. " · " .. tostring(it.habitat or "Suitable home habitat")) or "Assign a banked creature. Empty spaces do not earn.", acts)
	end
	local up = h.upgrades or {}
	row("Nest & habitat upgrade", string.format("Level %d / %d · improves adventure efficiency and adds earning spaces.", up.level or 0, up.max or 0), { action((up.level or 0) >= (up.max or 0) and "Fully upgraded" or ("Upgrade · " .. tostring(up.cost or 0) .. " coins"), "homeUpgrade", {}, (up.level or 0) < (up.max or 0) and (state.coins or 0) >= (up.cost or 0)) })
end
local function swap()
	local offer = state.swapOffer; if not offer then row("This encounter has ended", "No backpack items were changed."); return end
	row("BACKPACK FULL", "Compare your find with what you carry. A swap returns the replaced creature safely to the world. Wait for server confirmation.")
	row("Found · " .. itemName(offer.item or {}), rarity(offer.item or {}) .. "\n" .. tostring(offer.sourceName or "Creature nook"), { action("Leave this find", "swapLeave", { token = offer.token }) })
	for _, it in ipairs(state.items or {}) do
		local fits = (state.used or 0) - (it.slots or 1) + ((offer.item or {}).slots or 1) <= (state.capacity or C.SLOTS_BASE)
		row("Carrying · " .. itemName(it), rarity(it) .. " · " .. tostring(it.slots or 1) .. " slot(s)\n" .. discovery(it), { action("Swap this find", "swapConfirm", { token = offer.token, uid = it.uid }, fits) })
	end
end
local function loss()
	local p = ui.loss or {}
	row("Your expedition continues", "Banked finds are always safe. Follow the drop-pack marker to recover what shook loose.")
	for _, it in ipairs(p.lost or {}) do row(itemName(it), rarity(it) .. " · in your drop pack") end
	row("Recovery", string.format("%d find(s) still carried.\nDrop-pack time remaining: %s", p.keptCount or 0, fmtTime((p.expiresAt or now()) - now())))
end
render = function(resetScroll)
	if not ui.panel.Visible then return end
	local scroll = resetScroll and 0 or ui.body.CanvasPosition.Y
	local selected = GuiService.SelectedObject; local selectedName = selected and selected.Name
	for _, child in ipairs(ui.body:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	rowOrder = 0; ui.tabs.Visible = ui.mode == "expedition"
	-- On short landscape phones the tabs are the header; retaining a second title row wastes reading space.
	local compact = ui.tabs.Visible and ui.panel.AbsoluteSize.Y < 330
	ui.heading.Visible = not compact
	ui.tabs.Position = UDim2.fromOffset(12, compact and 4 or 56)
	ui.tabs.Size = UDim2.new(1, compact and -84 or -24, 0, 48)
	local bodyY = ui.tabs.Visible and not compact and 115 or 60
	ui.body.Position = UDim2.fromOffset(16, bodyY)
	ui.body.Size = UDim2.new(1, -32, 1, -(bodyY + 62))
	ui.heading.Text = ({ expedition = "◆  EXPEDITION", home = "◆  HOME STATION", directory = "◆  CABIN VISITS", practice = "◆  PRACTICE CRAG", locker = "◆  CAMP LOCKER", swap = "◆  COMPARE FINDS", loss = "◆  KEEP EXPLORING" })[ui.mode] or "EXPEDITION"
	for name, b in pairs(ui.tabButtons) do b.BackgroundColor3 = name == ui.tab and T.sandstone or T.deep; b.TextColor3 = name == ui.tab and T.deep or T.golden end
	if state.saveState == "loading" then row("Loading your expedition…", "Waiting for your profile. Movement stays available.", { action("Check again", "state") })
	elseif ui.mode == "home" then home()
	elseif ui.mode == "directory" then directory()
	elseif ui.mode == "practice" then practice()
	elseif ui.mode == "locker" then locker()
	elseif ui.mode == "swap" then swap()
	elseif ui.mode == "loss" then loss()
	elseif ui.tab == "Backpack" then backpack()
	elseif ui.tab == "Collection" then collection()
	elseif ui.tab == "Routes" then routes()
	else settings() end
	ui.body.CanvasPosition, ui.renderAt = Vector2.new(0, scroll), os.clock()
	if ui.device == "gamepad" then local replacement = selectedName and ui.panel:FindFirstChild(selectedName, true); GuiService.SelectedObject = replacement and replacement:IsA("GuiButton") and replacement or ui.close end
end
closePanel = function()
	local mode = ui.mode
	ui.panel.Visible, ui.shadow.Visible, ui.choose = false, false, nil
	plr:SetAttribute("CC_MenuOpen", false); GuiService.SelectedObject = nil; cancelHolds()
	if mode == "locker" then request("lockerClose") elseif mode == "home" then request("homeClose") elseif mode == "directory" then request("homeDirectoryClose") elseif mode == "practice" then request("practiceClose") elseif mode == "swap" and state.swapOffer then request("swapLeave", { token = state.swapOffer.token }) end
end
openPanel = function(mode)
	if profileUI then profileUI.close() end
	CommerceUI.close()
	cancelHolds(); ui.mode, ui.choose, ui.page = mode or "expedition", nil, 1
	ui.panel.Visible, ui.shadow.Visible = true, true
	plr:SetAttribute("CC_MenuOpen", true); fit(); render(true)
	if ui.device == "gamepad" then GuiService.SelectedObject = ui.close end
end
local function updateDevice(inputType)
	ui.device = string.find(tostring(inputType), "Gamepad") and "gamepad" or inputType == Enum.UserInputType.Touch and "touch" or "keyboard"
	ui.menuButton.Text = ui.device == "gamepad" and "Expedition [Select]" or ui.device == "touch" and "Expedition" or "Expedition [M]"
	cancelHolds()
	-- Do not rebuild buttons on InputBegan: destroying the tapped button would swallow the first action
	-- when changing between mouse, gamepad and touch. Update the help labels in place instead.
	if ui.controlsRow and ui.controlsRow.Parent then ui.controlsRow.Title.Text = "Controls · " .. ui.device; ui.controlsRow.Detail.Text = controlsText() end
	if ui.panel.Visible then GuiService.SelectedObject = ui.device == "gamepad" and (GuiService.SelectedObject or ui.close) or nil end
end
UIS.LastInputTypeChanged:Connect(updateDevice)
UIS.WindowFocusReleased:Connect(cancelHolds)
updateDevice(UIS:GetLastInputType())
CAS:BindActionAtPriority("CC_ExpeditionMenu", function(_, inputState)
	if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
	if inputState == Enum.UserInputState.Begin then if ui.panel.Visible then closePanel() else openPanel("expedition") end end
	return Enum.ContextActionResult.Sink
end, false, 3000, Enum.KeyCode.M, Enum.KeyCode.ButtonSelect)
CAS:BindActionAtPriority("CC_ExpeditionClose", function(_, inputState)
	if not ui.panel.Visible then return Enum.ContextActionResult.Pass end
	if inputState == Enum.UserInputState.Begin then closePanel() end
	return Enum.ContextActionResult.Sink
end, false, 3100, Enum.KeyCode.ButtonB)
PPS.PromptButtonHoldBegan:Connect(function(p) if ui.panel.Visible or CommerceUI.isOpen() then pcall(p.InputHoldEnd, p) else ui.holding[p] = true end end)
PPS.PromptButtonHoldEnded:Connect(function(p) ui.holding[p] = nil end)

-- Preserve tutorial guidance and per-player world visibility. There are no camera takeovers.
ui.tutorial = frame(gui, { Name = "TutorialRibbon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(430, 66), BackgroundColor3 = T.deep, Visible = false })
stroke(ui.tutorial)
ui.tutorialText = label(ui.tutorial, { Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -92, 1, -10), TextSize = 15, TextColor3 = T.golden })
button(ui.tutorial, "Skip", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(68, 48), TextSize = 14 }, function() request("tutorialSkip") end)
local markerAnchor = Instance.new("Part")
markerAnchor.Name, markerAnchor.Size = "CC_ObjectiveAnchor", Vector3.one
markerAnchor.Anchored, markerAnchor.CanCollide, markerAnchor.CanQuery, markerAnchor.CanTouch, markerAnchor.Transparency = true, false, false, false, 1
markerAnchor.Parent = workspace.CurrentCamera
local marker = Instance.new("BillboardGui")
marker.Name, marker.AlwaysOnTop, marker.Size, marker.LightInfluence = "CC_Objective", true, UDim2.fromOffset(180, 56), 0
marker.Adornee, marker.Parent, marker.Enabled = markerAnchor, markerAnchor, false
label(marker, { Text = "◆", TextSize = 24, TextColor3 = T.lantern, Size = UDim2.new(1, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 })
local markerText = label(marker, { Text = "", TextSize = 14, TextColor3 = T.moon, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 })
local edge = label(gui, { Name = "EdgeArrow", Text = "➤", TextSize = 30, TextColor3 = T.lantern, Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3 })
local wisp = Instance.new("Part")
wisp.Name, wisp.Shape, wisp.Size, wisp.Material, wisp.Color = "CC_Wisp", Enum.PartType.Ball, Vector3.one * 0.9, Enum.Material.Neon, T.lantern
wisp.Anchored, wisp.CanCollide, wisp.CanQuery, wisp.CanTouch, wisp.CastShadow = true, false, false, false, false
local wl = Instance.new("PointLight"); wl.Color, wl.Range, wl.Brightness, wl.Parent = T.lantern, 9, 1.1, wisp
local function pickObjective()
	local best, time = nil, math.huge
	for _, p in ipairs(state.packs or {}) do local left = (p.expiresAt or 0) - now(); if left > 0 and left < time then best, time = p, left end end
	if best then return { pos = best.pos, label = "Drop pack " .. fmtTime(time) } end
	if state.tut and state.tut.target then return { pos = state.tut.target, label = state.tut.label or "Next step" } end
	return nil
end
local function coreFolder(name)
	local w = workspace:FindFirstChild("World"); local c = w and w:FindFirstChild("Core"); return c and c:FindFirstChild(name)
end
local function setVisible(model, on)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.LocalTransparencyModifier = on and 0 or 1
		elseif d:IsA("BillboardGui") and d.Name == "Tag" then d.Enabled = on
		elseif d:IsA("ProximityPrompt") then d.Enabled = on
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("Beam") then d.Enabled = on end
	end
end
local function applyVisibility()
	local hidden = {}
	for _, h in ipairs(state.hiddenSpawns or {}) do if type(h) == "table" and now() < (h.untilAt or 0) then hidden[h.id] = true end end
	local cr = coreFolder("Creatures")
	for _, m in ipairs(cr and cr:GetChildren() or {}) do local id = m:GetAttribute("SpawnId"); if id and m:GetAttribute("PerPlayer") then setVisible(m, not hidden[id] and state.saveState == "ok") end end
	local nests = coreFolder("NestFinds") or coreFolder("NestLive")
	for _, m in ipairs(nests and nests:GetChildren() or {}) do local n = state.nests and state.nests[m:GetAttribute("NestId")]; if n then setVisible(m, now() >= ((m:GetAttribute("Pup") and n.pupAt or n.heartstoneAt) or 0)) end end
	local guards = coreFolder("Guardians")
	for _, m in ipairs(guards and guards:GetChildren() or {}) do
		local mine = m:GetAttribute("OwnerId") == plr.UserId
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = mine and 0 or 1
			elseif d:IsA("BillboardGui") and not mine then d.Enabled = false
			elseif d:IsA("BillboardGui") and mine and d.Name == "Tag" then d.Enabled = true end
		end
	end
	local packs = coreFolder("ExpeditionDrops") or coreFolder("DropPacks")
	for _, m in ipairs(packs and packs:GetChildren() or {}) do
		local mine = m:GetAttribute("OwnerId") == plr.UserId
		local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true); if prompt then prompt.Enabled = mine end
		local tag = m:FindFirstChild("Tag", true)
		if tag then tag.Enabled = mine; local bottom = tag:FindFirstChild("Bottom"); if bottom then local expires = m:GetAttribute("ExpiresAt") or 0; bottom.Text = (expires > 0 and fmtTime(expires - now()) or "Safely returned") .. " · " .. tostring(m:GetAttribute("Count") or 0) .. " finds" end end
	end
end
local function burst(pos, color)
	if preferences.reducedMotion or not safeGround() then return end
	local p = Instance.new("Part")
	p.Name, p.Shape, p.Size, p.Material, p.Color = "CC_DiscoveryGlow", Enum.PartType.Ball, Vector3.one, Enum.Material.Neon, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.CFrame, p.Parent = CFrame.new(pos), workspace.CurrentCamera
	TweenService:Create(p, TweenInfo.new(0.5), { Size = Vector3.one * 5, Transparency = 1 }):Play()
	task.delay(0.6, function() p:Destroy() end)
end
toastEv.OnClientEvent:Connect(function(p) if type(p) == "table" then notify(p.text, p.kind) end end)
fxEv.OnClientEvent:Connect(function(p)
	if type(p) ~= "table" then return end
	if nameTags then nameTags.fx(p) end
	if profileUI and p.kind=="profileOwn" then profileUI.own() end
	CommerceUI.fx(p)
	if p.kind == "stagger" then cancelHolds()
	elseif p.kind == "loss" then ui.deferred[#ui.deferred + 1] = { kind = "loss", payload = p }
	elseif p.kind == "claim" or p.kind == "heartstone" or p.kind == "hatch" then ui.deferred[#ui.deferred + 1] = { kind = "discovery", payload = p }
	elseif p.kind == "bank" then notify("Bank confirmed. Your finds are safe in your collection.", "good", 5, 3)
	elseif p.kind == "welcome" then ui.deferred[#ui.deferred + 1] = { kind = "welcome", payload = p }
	elseif p.kind == "cliffhanger" then notify("A guarded Heartstone nook lies ahead. Watch for its distraction interaction.", "info", 6)
	elseif p.kind == "recovered" then notify("Recovered your finds. Carry them to the bank when ready.", "good")
	elseif p.kind == "packGone" then notify("The drop pack has expired. Your banked collection is safe.", "warn")
	elseif p.kind == "trainStart" then notify("Practice started. Use the marked holds; take your time.", "info")
	elseif p.kind == "ripened" then
		if p.hatched then for _, it in ipairs(p.hatched) do ui.deferred[#ui.deferred + 1] = { kind = "discovery", payload = { kind = "hatch", species = it.species, rarity = it.rarity } } end
		else notify("A home Heartstone is ready. Return home to hatch it when you choose.", "good") end
	end
	while #ui.deferred > 12 do table.remove(ui.deferred, 1) end
end)
stateEv.OnClientEvent:Connect(function(st)
	if type(st) ~= "table" then return end
	local previous = state; state = st
	if type(st.serverNow) == "number" then clockSkew = st.serverNow - os.time() end
	if type(st.settings) == "table" then
		for k in pairs(preferences) do if st.settings[k] ~= nil then preferences[k] = st.settings[k] end end
		preferences.textScale = math.clamp(tonumber(preferences.textScale) or 1, 1, 1.3)
		plr:SetAttribute("CC_TextScale", preferences.textScale); plr:SetAttribute("CC_TimingAssist", preferences.timingAssist)
		plr:SetAttribute("CC_ReducedMotion", preferences.reducedMotion); plr:SetAttribute("CC_HeadlampMode", preferences.headlampMode)
		for _, obj in ipairs(gui:GetDescendants()) do if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj:GetAttribute("BaseTextSize") then obj.TextSize = math.floor(obj:GetAttribute("BaseTextSize") * preferences.textScale) end end
	end
	CommerceUI.update(st)
	if profileUI then profileUI.updateOwner(st);nameTags.update(st) end
	refreshHud()
	if st.swapOffer and (not previous.swapOffer or previous.swapOffer.token ~= st.swapOffer.token) then openPanel("swap")
	elseif st.home and not previous.home then openPanel("home")
	elseif st.homeDirectory and not previous.homeDirectory then openPanel("directory")
	elseif st.practice and not previous.practice then openPanel("practice")
	elseif st.locker and not previous.locker then openPanel("locker")
	elseif ui.panel.Visible and ((ui.mode == "home" and not st.home) or (ui.mode == "directory" and not st.homeDirectory) or (ui.mode == "practice" and not st.practice) or (ui.mode == "locker" and not st.locker) or (ui.mode == "swap" and not st.swapOffer)) then closePanel()
	elseif ui.panel.Visible then render() end
	if previous.level and st.level and st.level > previous.level then ui.deferred[#ui.deferred + 1] = { kind = "level", level = st.level } end
end)
local BANDS = { { 165, "Dry Foothills" }, { 640, "Green Valley" }, { 1130, "Whispering Forest" }, { 1760, "Broken Cliffs" }, { 2340, "Storm Ridge" }, { math.huge, "Frozen Summit" } }
local function zoneName(pos)
	local f = C.FOOTHOLD_SAFE
	if ((pos - f.center) * Vector3.new(1, 0, 1)).Magnitude < f.radius and pos.Y < f.center.Y + 60 then return "The Foothold" end
	for _, b in ipairs(BANDS) do if pos.Y < b[1] then return b[2] end end
	return "The Mountain"
end
local tickAt, visibilityAt, loadingAt, wispPos = 0, 0, 0, nil
Run.RenderStepped:Connect(function(dt)
	local ch, cam = plr.Character, workspace.CurrentCamera
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local objective = pickObjective()
	if objective and typeof(objective.pos) == "Vector3" and hrp then
		markerAnchor.Position, marker.Enabled = objective.pos + Vector3.new(0, 4, 0), not ui.panel.Visible
		markerText.Text = objective.label .. " · " .. math.floor((objective.pos - hrp.Position).Magnitude + 0.5)
		local sp, onScreen = cam:WorldToViewportPoint(markerAnchor.Position); local vp = cam.ViewportSize
		edge.Visible = not ui.panel.Visible and (not onScreen or sp.Z <= 0)
		if edge.Visible then
			local v = Vector2.new(sp.X, sp.Y) - vp / 2; if sp.Z < 0 then v = -v end
			if v.Magnitude < 1 then v = Vector2.new(0, -1) end
			local k = math.min((vp.X / 2 - 36) / math.max(1, math.abs(v.X)), (vp.Y / 2 - 64) / math.max(1, math.abs(v.Y)))
			local point = vp / 2 + v * k; edge.Position, edge.Rotation = UDim2.fromOffset(point.X, point.Y), math.deg(math.atan2(v.Y, v.X))
		end
	else marker.Enabled, edge.Visible = false, false end
	wisp.Parent = state.tut and cam or nil
	if wisp.Parent and hrp then
		local ahead = hrp.Position + Vector3.new(0, 3.2, 0)
		local dir = objective and typeof(objective.pos) == "Vector3" and ((objective.pos - hrp.Position) * Vector3.new(1, 0, 1)) or hrp.CFrame.RightVector
		if dir.Magnitude > 0.1 then ahead += dir.Unit * math.min(6, dir.Magnitude) end
		if not preferences.reducedMotion then ahead += Vector3.new(0, math.sin(os.clock() * 2) * 0.3, 0) end
		wispPos = wispPos and wispPos:Lerp(ahead, math.min(1, dt * 3)) or ahead; wisp.CFrame = CFrame.new(wispPos)
	end
	if os.clock() - tickAt < 0.15 then return end; tickAt = os.clock()
	if hrp then
		local stamina = ch:GetAttribute("CC_Stamina") or plr:GetAttribute("CC_StaminaMax") or C.CLIMB.stamina
		local maximum = plr:GetAttribute("CC_StaminaMax") or C.CLIMB.stamina
		ui.staminaText.Text = string.format("Stamina  %d / %d", math.floor(stamina), maximum)
		ui.staminaFill.Size = UDim2.fromScale(math.clamp(stamina / math.max(1, maximum), 0, 1), 1)
		ui.staminaFill.BackgroundColor3 = stamina / math.max(1, maximum) < 0.25 and T.lantern or T.golden
		local inHome = state.inHome or plr:GetAttribute("CC_InHome") == true
		ui.zone.Text = inHome and "Home courtyard" or ((plr:GetAttribute("CC_Camp") and plr:GetAttribute("CC_Camp") ~= "") and plr:GetAttribute("CC_Camp") or zoneName(hrp.Position))
		ui.altitudeText.Text = inHome and "HOME" or string.format("%d m", math.max(0, math.floor(hrp.Position.Y)))
		ui.altitudeFill.Size = UDim2.fromScale(inHome and 0 or math.clamp(hrp.Position.Y / 2600, 0, 1), 1)
	end
	if state.tut then ui.tutorialText.Text = string.format("%s  ·  %d/%d", state.tut.line or "", state.tut.step or 1, state.tut.total or 1) end
	ui.hud.Visible, ui.altitude.Visible = not ui.panel.Visible, not ui.panel.Visible
	local needsSave = state.saveState ~= "ok" or (state.bank and (state.bank.status == "saving" or state.bank.status == "uncertain" or state.bank.status == "error"))
	local traversalGui = gui.Parent:FindFirstChild("CC_TraversalUI")
	local traversalPanel = traversalGui and traversalGui:FindFirstChildWhichIsA("Frame")
	local bandBlocked = not ui.panel.Visible and traversalPanel and traversalPanel.Visible and ui.notice.AbsolutePosition.Y + ui.notice.AbsoluteSize.Y + 4 > traversalPanel.AbsolutePosition.Y
	ui.save.Visible = not ui.panel.Visible and not bandBlocked and needsSave or false
	if bandBlocked and needsSave then ui.zone.Text = state.saveState == "ok" and "Saving status · Expedition" or "Save paused · Expedition" end
	-- One message band fits between the top instruments and bottom traversal controls even at 330 px.
	-- Shorter screens defer this band while traversal uses the space; save status remains in the HUD.
	-- Save recovery outranks notices; notices outrank tutorial prose. Hidden messages keep their dwell time.
	if (ui.save.Visible or bandBlocked) and ui.currentNotice then ui.currentNotice.untilAt = os.clock() + ui.currentNotice.duration end
	if ui.currentNotice and os.clock() >= ui.currentNotice.untilAt then ui.currentNotice = nil end
	if not ui.currentNotice and #ui.notices > 0 and not ui.save.Visible and not bandBlocked then
		ui.currentNotice = table.remove(ui.notices, 1); ui.currentNotice.untilAt = os.clock() + ui.currentNotice.duration
		ui.noticeText.Text = ui.currentNotice.text
		ui.noticeBorder.Color = ({ info = T.golden, good = T.meadow, warn = T.lantern, bad = T.sandstone })[ui.currentNotice.kind] or T.golden
	end
	ui.notice.Visible = ui.currentNotice ~= nil and not ui.panel.Visible and not ui.save.Visible and not bandBlocked
	ui.tutorial.Visible = state.tut ~= nil and (state.tut.line or "") ~= "" and not ui.panel.Visible and not ui.save.Visible and not ui.notice.Visible and not bandBlocked and safeGround() == true
	ui.footer.Text = ui.currentNotice and ui.currentNotice.text or "The world keeps moving. Find safe ground to browse."
	ui.footer.TextColor3 = ui.currentNotice and T.golden or T.moon
	if safeGround() and not ui.panel.Visible and not CommerceUI.isOpen() and not ui.currentNotice and #ui.deferred > 0 then
		local e = table.remove(ui.deferred, 1)
		if e.kind == "loss" then ui.loss = e.payload; openPanel("loss")
		elseif e.kind == "welcome" then notify("Welcome back. Your next expedition is waiting.", "good")
		elseif e.kind == "level" then notify("Level " .. e.level .. " reached. Check your backpack capacity.", "good")
		else local p = e.payload
			notify((p.kind == "hatch" and "Hatched · " or p.kind == "heartstone" and "Heartstone found · " or "Discovered · ") .. (p.kind == "heartstone" and tostring(p.tier or "") or itemName(p)) .. "  " .. rarity(p), "good", 5)
			if p.pos then burst(p.pos, C.RARITY_TINT[p.rarity] or T.golden) end
		end
	end
	if os.clock() - visibilityAt > 1 then visibilityAt = os.clock(); applyVisibility() end
	if state.saveState == "loading" and os.clock() - loadingAt > 5 then loadingAt = os.clock(); request("state") end
	if ui.panel.Visible and ui.mode == "loss" and os.clock() - ui.renderAt > 1 then render() end
 CommerceUI.tick()
 if CommerceUI.isOpen() then ui.hud.Visible=false;ui.altitude.Visible=false;ui.tutorial.Visible=false;ui.notice.Visible=false;ui.save.Visible=false;ui.menuButton.Visible=false else ui.menuButton.Visible=true end
end)
plr:SetAttribute("CC_MenuOpen", false)
local checkpointEvent = RS:WaitForChild("CC_Remotes"):FindFirstChild("Checkpoint")
if checkpointEvent then checkpointEvent.OnClientEvent:Connect(function(name) notify("Checkpoint · " .. tostring(name), "good", 3.5, 2) end) end
local traversalConnection
local function characterReady(ch)
	cancelHolds(); if ui.panel.Visible then closePanel() end
	if traversalConnection then traversalConnection:Disconnect() end
	traversalConnection = ch:GetAttributeChangedSignal("CC_TraversalState"):Connect(cancelHolds)
end
plr.CharacterAdded:Connect(characterReady)
if plr.Character then characterReady(plr.Character) end
_G.CC_CORE_CLIENT = { toast = notify, state = function() return state end, request = request, gui = gui, tokens = T, button = button, frame = frame, label = label, fmtTime = fmtTime, serverNow = now, open = openPanel, close = closePanel }
if Run:IsStudio() then
	-- Studio's execution VM does not share LocalScript globals. This read/visual-only probe gives QA
	-- deterministic menu navigation and measures actual rendered bounds without mutating gameplay state.
	local probe = Instance.new("BindableFunction")
	probe.Name, probe.Parent = "CC_UIProbe", gui
	probe.OnInvoke = function(command, payload)
		payload = type(payload) == "table" and payload or {}
		if command == "open" then
			if table.find({ "Backpack", "Collection", "Routes", "Settings" }, payload.tab) then ui.tab = payload.tab end
			openPanel("expedition")
		elseif command == "close" then closePanel()
		elseif command == "audit" then
			local small, textOverflows, visibleButtons = {}, {}, 0
			for _, obj in ipairs(gui:GetDescendants()) do
				if obj:IsA("GuiButton") or obj:IsA("TextLabel") then
					local visible, ancestor = obj.Visible, obj.Parent
					while ancestor and ancestor ~= gui do if ancestor:IsA("GuiObject") and not ancestor.Visible then visible = false end; ancestor = ancestor.Parent end
					if visible then
						if obj:IsA("GuiButton") then
							visibleButtons += 1
							if obj.AbsoluteSize.X < 48 or obj.AbsoluteSize.Y < 48 then small[#small + 1] = obj:GetFullName() end
						end
						if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not obj.TextFits then textOverflows[#textOverflows + 1] = { name = obj:GetFullName(), text = obj.Text, size = tostring(obj.AbsoluteSize), bounds = tostring(obj.TextBounds) } end
					end
				end
			end
			return { viewport = tostring(gui.AbsoluteSize), panelSize = tostring(ui.panel.AbsoluteSize), panelPosition = tostring(ui.panel.AbsolutePosition), mode = ui.mode, tab = ui.tab, visibleButtons = visibleButtons, smallTargets = small, textOverflows = textOverflows, scrollHeight = ui.body.AbsoluteCanvasSize.Y, viewHeight = ui.body.AbsoluteSize.Y, saveState = state.saveState }
		end
		return true
	end
end
CommerceUI.init({parent=gui,request=request,safe=safeGround,otherOpen=function() return ui.panel.Visible or (profileUI and profileUI.isOpen()) or plr:GetAttribute("CC_SummitPresentation")==true end,
 closeOtherPanels=function() if profileUI then profileUI.close() end;if ui.panel.Visible then closePanel() end;cancelHolds() end,
 onModalChanged=function(open) plr:SetAttribute("CC_MenuOpen",open);cancelHolds() end})
if Run:IsStudio() then _G.CC_COMMERCE_UI=CommerceUI end
profileUI=require(CoreRS.Client.ProfileUI).mount({parent=gui,request=request,modal=function(open) plr:SetAttribute("CC_MenuOpen",open);cancelHolds() end,closeOthers=function() CommerceUI.close();if ui.panel.Visible then closePanel() end end,collection=function() ui.tab="Collection";openPanel("expedition") end})
nameTags=require(CoreRS.Client.NameTags).mount({parent=gui,request=request,profile=profileUI})
newHUD=require(CoreRS.Client.ExpeditionHUD).mount({parent=gui,ui=ui,profile=profileUI,blocked=function() return ui.panel.Visible or profileUI.isOpen() or CommerceUI.isOpen() or plr:GetAttribute("CC_SummitPresentation")==true end})
if Run:IsStudio() then local r=Instance.new("BindableFunction");r.Name="PortfolioReview";r.OnInvoke=function(action) if action=="open" then profileUI.own() elseif action=="close" then profileUI.close() end end;r.Parent=gui end
fit(); refreshHud(); request("state")
