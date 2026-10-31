-- Command-bar job (Edit mode): files the imported creature models (art/tools/export_creatures.py) into
-- ReplicatedStorage.SS_Creatures.Models and splits each one's imported timeline (ServerStorage.RBX_ANIMSAVES)
-- into its clips (SS_Creatures.Clips.<model>.<clip>, ranges from art/export/creatures/clips.json). Safe to re-run.
return function()
	local H = game:GetService("HttpService")
	local RepS = game:GetService("ReplicatedStorage")
	local info = H:JSONDecode(H:GetAsync("http://127.0.0.1:8798/export/creatures/clips.json?" .. os.clock()))
	local root = RepS:FindFirstChild("SS_Creatures") or Instance.new("Folder")
	root.Name = "SS_Creatures"
	root.Parent = RepS
	local function sub(parent, name)
		local f = parent:FindFirstChild(name) or Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end
	local models = sub(root, "Models")
	-- raw clips stay out of ReplicatedStorage (18,000 instances every client would download); the game plays the
	-- uploaded Animation assets in SS_Config.ClipAssets
	local clips = game:GetService("ServerStorage"):FindFirstChild("SS_CreatureClips") or Instance.new("Folder")
	clips.Name = "SS_CreatureClips"
	clips.Parent = game:GetService("ServerStorage")
	local out = {}
	for name, ranges in info.clips do
		local m = workspace:FindFirstChild(name) or models:FindFirstChild(name)
		local saves = game:GetService("ServerStorage"):FindFirstChild("RBX_ANIMSAVES")
		local src = saves and saves:FindFirstChild(name) and saves[name]:FindFirstChildWhichIsA("KeyframeSequence")
		if not m or not src then
			table.insert(out, name .. " MISSING model=" .. tostring(m ~= nil) .. " anim=" .. tostring(src ~= nil))
			continue
		end
		local part = m:FindFirstChild(name)
		part.Anchored, part.CanCollide, part.CanQuery, part.CastShadow = true, false, false, true
		-- the head sits toward -Z (Roblox forward) unless the import flipped the model
		local head = part:FindFirstChild("head", true)
		local headZ = part.CFrame:PointToObjectSpace(head.WorldPosition).Z
		local seat = ranges._seat
		part:SetAttribute("Flip", headZ > 0)
		part:SetAttribute("SeatUp", seat.up)
		part:SetAttribute("SeatBack", seat.fwd) -- studs toward the tail from the mesh centre
		m.PrimaryPart = part
		m.Parent = models
		local cf = sub(clips, name)
		local nk = {}
		for clip, r in ranges do
			if clip == "_seat" then
				continue
			end
			local old = cf:FindFirstChild(clip)
			if old then
				old:Destroy()
			end
			local ks = Instance.new("KeyframeSequence")
			ks.Name = clip
			ks.Loop = r.loop
			ks.Priority = Enum.AnimationPriority.Core
			local n = 0
			for _, k in src:GetKeyframes() do
				if k.Time >= r.start - 0.001 and k.Time <= r.stop + 0.001 then
					local c = k:Clone()
					c.Time = k.Time - r.start
					c.Parent = ks
					n += 1
				end
			end
			ks.Parent = cf
			table.insert(nk, clip .. "=" .. n)
		end
		table.insert(out, string.format("%s headZ=%.2f flip=%s seatUp=%.2f %s", name, headZ, tostring(headZ > 0), seat.up, table.concat(nk, ",")))
	end
	return "CREATURES " .. table.concat(out, " | ")
end
