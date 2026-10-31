-- Loading card (ReplicatedFirst.SS_Loading; MASTER-PLAN "Loading card plan", owner L1-L2). Covers the screen from the first
-- frame, shows the name, the zone-1 tagline and a bar that fills from four REAL steps, then fades out once the rider is
-- mounted. After C.Loading.Timeout s it shows an error line naming the missing step, logs it, and drops the card so a
-- stuck load can never trap the player. Colours / font / fade are existing tokens only: zone 1 TitleStroke (backing),
-- zone 1 TitleColor (text, bar), Tagline, the title-card fonts, C.TitleFade. First load only (ResetOnSpawn off, one run).
local Players = game:GetService("Players")
local RepF = game:GetService("ReplicatedFirst")
local RepS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local C = require(RepS:WaitForChild("SS_Config")) -- the default Roblox loading screen stays up until the tokens are here
local L = C.Loading
local z1 = C.Zones[1]
local t0 = os.clock()
RepF:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local function hex(h)
	return Color3.fromHex(h)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SS_Loading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = L.DisplayOrder
gui.Parent = player:WaitForChild("PlayerGui")

local back = Instance.new("Frame")
back.Name = "Back"
back.Size = UDim2.fromScale(1, 1)
back.BackgroundColor3 = hex(z1.TitleStroke)
back.BorderSizePixel = 0
back.Active = true -- swallows taps while the card is up
back.Parent = gui

local function label(name, y, h, font, text)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.AnchorPoint = Vector2.new(0.5, 0)
	t.Position = UDim2.fromScale(0.5, y)
	t.Size = UDim2.fromScale(L.TextWidth, h)
	t.BackgroundTransparency = 1
	t.Font = font
	t.TextScaled = true
	t.TextColor3 = hex(z1.TitleColor)
	t.Text = text
	t.Parent = back
	return t
end
local tName = label("Name", L.NameY, L.NameH, Enum.Font.GothamBlack, L.Name)
local tTag = label("Tag", L.TagY, L.TagH, Enum.Font.GothamMedium, z1.Tagline)
local tErr = label("Error", L.ErrY, L.ErrH, Enum.Font.GothamBold, "")
tErr.TextTransparency = 1

local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0.5, 0)
track.Position = UDim2.fromScale(0.5, L.BarY)
track.Size = UDim2.new(L.BarWidth, 0, 0, L.BarHeight)
track.BackgroundColor3 = hex(z1.TitleColor)
track.BackgroundTransparency = L.TrackTransparency
track.BorderSizePixel = 0
track.Parent = back
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = hex(z1.TitleColor)
fill.BorderSizePixel = 0
fill.Parent = track
for _, o in { track, fill } do
	local r = Instance.new("UICorner")
	r.CornerRadius = UDim.new(0.5, 0)
	r.Parent = o
end

-- The four real steps ------------------------------------------------------------------------------------
local STEPS = { "game", "assets", "herd", "ground" }
local done = {}
local function finish(step)
	if done[step] then
		return
	end
	done[step] = true
	local n = 0
	for _ in done do
		n += 1
	end
	TweenService:Create(fill, TweenInfo.new(L.BarTween), { Size = UDim2.fromScale(n / #STEPS, 1) }):Play()
	print(string.format("LOADREC card: %s done at %.2f s (%d/%d)", step, os.clock() - t0, n, #STEPS))
end

task.spawn(function() -- game loaded
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	finish("game")
end)

task.spawn(function() -- the uploaded gallop clips and the creature meshes
	local list = {}
	for _, clips in C.ClipAssets or {} do
		for _, id in clips do
			local a = Instance.new("Animation")
			a.AnimationId = id
			table.insert(list, a)
		end
	end
	local models = RepS:WaitForChild("SS_Creatures", 10)
	models = models and models:FindFirstChild("Models")
	if models then
		for _, d in models:GetDescendants() do
			if d:IsA("MeshPart") or d:IsA("Animation") then
				table.insert(list, d)
			end
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(list)
	end)
	finish("assets")
end)

task.spawn(function() -- SS_Ride built the first biomes' herd
	while not RepS:GetAttribute("SS_PoolReady") do
		RepS:GetAttributeChangedSignal("SS_PoolReady"):Wait()
	end
	finish("herd")
end)

task.spawn(function() -- the server streamed in the ground around the spawn (SS_Stream Prepare)
	local remotes = RepS:WaitForChild("SS_Remotes", L.Timeout)
	local fn = remotes and remotes:WaitForChild("Prepare", L.Timeout)
	if fn then
		pcall(fn.InvokeServer, fn, -30)
	end
	if RunService:IsStudio() then
		while RepS:GetAttribute("SS_LoadingBlock") do -- BOT: simulate a stalled step
			task.wait(0.2)
		end
	end
	if fn then
		finish("ground")
	end
end)

-- Exit ---------------------------------------------------------------------------------------------------
local function close()
	local info = TweenInfo.new(C.TitleFade)
	for _, t in { tName, tTag, tErr } do
		TweenService:Create(t, info, { TextTransparency = 1 }):Play()
	end
	TweenService:Create(track, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(fill, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(back, info, { BackgroundTransparency = 1 }):Play()
	task.delay(C.TitleFade + 0.1, function()
		gui:Destroy()
	end)
end

local function allDone()
	for _, s in STEPS do
		if not done[s] then
			return false
		end
	end
	return true
end

local stalled = false
while true do
	local t = os.clock() - t0
	if allDone() and RepS:GetAttribute("SS_Playable") and t >= L.MinShow then
		print(string.format("LOADREC card: closed at %.2f s", t))
		close()
		return
	end
	if t >= L.Timeout then
		stalled = true
		break
	end
	task.wait(0.1)
end

if stalled then -- L2: say what is missing, log it, then hand the player the game
	local missing = {}
	for _, s in STEPS do
		if not done[s] then
			table.insert(missing, s)
		end
	end
	if not RepS:GetAttribute("SS_Playable") then
		table.insert(missing, "ride")
	end
	local msg = "LOAD PROBLEM: " .. table.concat(missing, ", ")
	warn("LOADREC card: stalled after " .. L.Timeout .. " s, missing " .. table.concat(missing, ", "))
	tErr.Text = msg
	TweenService:Create(tErr, TweenInfo.new(C.TitleFade), { TextTransparency = 0 }):Play()
	task.wait(L.ErrHold)
	close()
end
