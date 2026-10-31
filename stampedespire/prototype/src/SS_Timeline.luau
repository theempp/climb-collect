-- Progress timeline (ReplicatedStorage.SS_Timeline): a strip at the top of the screen with one equal-width
-- segment per zone, a checkpoint node at every border (a diamond at the summit), and your rider + current
-- mount sliding along it. SS_Ride builds it once and calls :update every frame. Sizes are SS_Config.Ui.Timeline;
-- colours are each zone's own TitleColor / TitleStroke LOOKDEV tokens.
local RepS = script.Parent
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

local M = {}

-- Pixels the rest of the top HUD (hint line, title card) must clear below the strip.
function M.block()
	local T = C.Ui.Timeline
	return T.Enabled and (T.Height + T.Gap) or 0
end

local function round(f)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
end

local function stroke(f, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = f
	return s
end

local function frame(parent, name, color, transparency)
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function colours(k)
	local z = C.Zones[k]
	return Color3.fromHex(z.TitleColor), Color3.fromHex(z.TitleStroke)
end

function M.new(parent, player)
	local T, Z = C.Ui.Timeline, C.Zones
	local N = #Z
	local barY = T.Height - T.Node / 2

	local root = Instance.new("Frame")
	root.Name = "Timeline"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.5, 0, 0, C.Ui.TopGap)
	root.Size = UDim2.new(T.Width, 0, 0, T.Height)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = parent

	-- The track leaves half an icon free at both ends so the marker never leaves the strip.
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.new(0, T.Icon / 2, 0, barY)
	track.Size = UDim2.new(1, -T.Icon, 0, T.Bar)
	track.BackgroundTransparency = 1
	track.Parent = root

	local fills, nodes = {}, {}
	for i = 1, N do
		local light, dark = colours(i)
		local seg = frame(track, "Seg" .. i, dark, T.Back)
		seg.Position = UDim2.fromScale((i - 1) / N, 0)
		seg.Size = UDim2.new(1 / N, -2, 1, 0)
		round(seg)
		local fill = frame(seg, "Fill", light)
		fill.Size = UDim2.fromScale(0, 1)
		round(fill)
		fills[i] = fill
	end
	for i = 1, N do
		local light, dark = colours(i)
		local summit = i == N
		local size = summit and T.Node * 0.8 or T.Node
		local node = frame(track, "Node" .. i, dark)
		node.AnchorPoint = Vector2.new(0.5, 0.5)
		node.Position = UDim2.new(i / N, -1, 0.5, 0)
		node.Size = UDim2.fromOffset(size, size)
		node.ZIndex = 2
		node:SetAttribute("Reached", false)
		if summit then
			node.Rotation = 45
		else
			round(node)
		end
		stroke(node, light, 1.5)
		local scale = Instance.new("UIScale")
		scale.Parent = node
		local label
		if not summit then
			label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 9
			label.TextColor3 = light
			label.Text = tostring(i)
			label.ZIndex = 3
			label.Parent = node
		end
		nodes[i] = { f = node, scale = scale, label = label, reached = false, pop = 0 }
	end

	-- Marker: the mount (a live clone in a ViewportFrame) with the rider's headshot perched on top.
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0)
	marker.Size = UDim2.fromOffset(T.Icon, T.Icon)
	marker.BackgroundTransparency = 1
	marker.ZIndex = 5
	marker.Parent = root
	local light0, dark0 = colours(1)
	local disc = frame(marker, "Disc", dark0, T.Back)
	disc.Size = UDim2.fromScale(1, 1)
	disc.ClipsDescendants = true
	disc.ZIndex = 5
	round(disc)
	local rim = stroke(disc, light0, 2)
	local view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(150, 150, 150)
	view.LightColor = Color3.new(1, 1, 1)
	view.LightDirection = Vector3.new(-0.4, -1, -0.6)
	view.ZIndex = 5
	view.Parent = disc
	round(view)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = view
	view.CurrentCamera = cam
	local pin = frame(marker, "Pin", light0)
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.Position = UDim2.new(0.5, 0, 1, 1)
	pin.Size = UDim2.fromOffset(6, 6)
	pin.Rotation = 45
	pin.ZIndex = 4
	local rider = Instance.new("ImageLabel")
	rider.Name = "Rider"
	rider.AnchorPoint = Vector2.new(0.5, 0.5)
	rider.Position = UDim2.new(1, -3, 0, 3)
	rider.Size = UDim2.fromOffset(T.Rider, T.Rider)
	rider.BackgroundColor3 = dark0
	rider.BorderSizePixel = 0
	rider.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100", player.UserId)
	rider.ZIndex = 6
	rider.Parent = marker
	round(rider)
	local riderRim = stroke(rider, light0, 1.5)

	local self = { root = root, track = track, marker = marker, view = view, nodes = nodes, fills = fills }
	local p, zone, shownMount, started, lastD = 0, 1, nil, false, 0
	local hop = 0
	local markerY = 0

	local function setZone(k)
		zone = k
		local light, dark = colours(k)
		disc.BackgroundColor3, rim.Color, pin.BackgroundColor3 = dark, light, light
		rider.BackgroundColor3, riderRim.Color = dark, light
	end

	local function setMount(c)
		shownMount = c
		for _, o in view:GetChildren() do
			if o ~= cam then
				o:Destroy()
			end
		end
		local m = c.model:Clone()
		for _, o in m:GetDescendants() do
			if o:IsA("BillboardGui") or o:IsA("SelectionBox") or o:IsA("BaseScript") or o:IsA("AnimationController") or o:IsA("Animator") then
				o:Destroy()
			end
		end
		m.Parent = view
		m:PivotTo(CFrame.identity)
		local bc, size = m:GetBoundingBox()
		local reach = math.max(size.Y, size.Z) / 2 / math.tan(math.rad(cam.FieldOfView / 2)) * 1.15 + size.X / 2
		-- side view; creatures face -Z, which is screen-right when looking along -X
		cam.CFrame = CFrame.lookAt(bc.Position + Vector3.new(reach, 0, 0), bc.Position)
		hop = 1
	end

	-- d: studs climbed by the rider; mountC: the ridden creature (nil while on foot); state: SS_Ride state.
	function self:update(dt, d, mountC, state)
		local on = T.Enabled and state ~= "none"
		root.Visible = on
		if not on then
			return
		end
		d = math.max(d, 0)
		lastD = d
		local k = P.zoneOf(d)
		local frac = math.clamp((d - P.Starts[k]) / Z[k].Length, 0, 1)
		local target = d >= P.Total and 1 or ((k - 1) + frac) / N
		local snap = not started or math.abs(target - p) > 0.5 -- first frame or a summit reset
		started = true
		p = snap and target or p + (target - p) * math.min(1, dt * T.Smooth)
		if k ~= zone then
			setZone(k)
		end
		if mountC and mountC ~= shownMount then
			setMount(mountC)
		end
		hop = math.max(hop - dt * 4, 0)
		markerY = -math.sin(hop * math.pi) * 5
		marker.Position = UDim2.new(p, T.Icon * (0.5 - p), 0, markerY)
		local dim = mountC and T.Back or 0.7 -- on foot: the mount icon greys out
		disc.BackgroundTransparency = dim
		view.ImageTransparency = mountC and 0 or 0.5
		local reached = p * N
		for i = 1, N do
			fills[i].Size = UDim2.fromScale(math.clamp(reached - (i - 1), 0, 1), 1)
			local n = nodes[i]
			local now = reached >= i - 0.001
			if now ~= n.reached then
				n.reached = now
				local light, dark = colours(i)
				n.f.BackgroundColor3 = now and light or dark
				n.f:SetAttribute("Reached", now)
				if n.label then
					n.label.TextColor3 = now and dark or light
				end
				n.pop = (now and not snap) and 1 or 0
			end
			if n.pop > 0 then
				n.pop = math.max(n.pop - dt / T.Pop, 0)
				n.scale.Scale = 1 + 0.6 * math.sin(n.pop * math.pi)
			elseif n.scale.Scale ~= 1 then
				n.scale.Scale = 1
			end
		end
	end

	-- Progress shown by the marker (0..1) and the distance it was last drawn for (BOT).
	function self:progress()
		return p, lastD
	end

	return self
end

return M
