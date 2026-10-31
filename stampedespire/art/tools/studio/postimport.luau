-- Command-bar job (Edit mode): gathers the imported zone models into Workspace.SS_Mountain and applies
-- the per-mesh settings from art/export/ss_manifest.json. Safe to re-run.
return function()
	local H = game:GetService("HttpService")
	local man = H:JSONDecode(H:GetAsync("http://127.0.0.1:8798/export/ss_manifest.json?" .. os.clock()))
	local root = workspace:FindFirstChild("SS_Mountain")
	if not root then
		root = Instance.new("Model")
		root.Name = "SS_Mountain"
		root.Parent = workspace
	end
	local function folder(n)
		local f = root:FindFirstChild(n)
		if not f then
			f = Instance.new("Folder")
			f.Name = n
			f.Parent = root
		end
		return f
	end
	local log, n, maxErr, fixed, unknown = {}, 0, 0, 0, {}
	local sources = { "ss_zone1", "ss_zone2", "ss_zone3", "ss_zone4", "ss_backdrop", "ss_patch", "SS_Mountain" }
	for _, src in sources do
		local m = workspace:FindFirstChild(src)
		for _, p in (m and m:GetDescendants() or {}) do
			if p:IsA("MeshPart") then
				local e = man[p.Name]
				if not e then
					table.insert(unknown, p:GetFullName())
					continue
				end
				n += 1
				local want = Vector3.new(e.pos[1], e.pos[2], e.pos[3])
				local err = (p.Position - want).Magnitude
				maxErr = math.max(maxErr, err)
				if err > 0.05 then
					p.CFrame = CFrame.new(want)
					fixed += 1
				end
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.CastShadow = e.castShadow == true
				pcall(function()
					p.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				pcall(function()
					p.RenderFidelity = Enum.RenderFidelity[e.fidelity or "Automatic"]
				end)
				local mat = e.material or "SmoothPlastic"
				p.Material = Enum.Material[mat]
				if e.color then
					p.Color = Color3.fromHex(e.color)
				end
				local zone = p.Name:match("^Z(%d)_")
				p.Parent = folder(zone and ("Zone" .. zone) or "Backdrop")
			end
		end
		if m and m ~= root and #m:GetDescendants() == 0 then
			m:Destroy()
		elseif m and m ~= root then
			table.insert(log, src .. " left " .. #m:GetDescendants() .. " children")
		end
	end
	local bp = workspace:FindFirstChild("Baseplate")
	if bp then
		bp:Destroy()
	end
	local t = workspace:FindFirstChild("ss_test")
	if t then
		t:Destroy()
	end
	local count = 0
	for name in man do
		count += 1
	end
	return string.format("POSTIMPORT meshes=%d/%d maxPosErr=%.3f fixed=%d unknown=%d %s %s", n, count, maxErr, fixed, #unknown,
		table.concat(unknown, ","), table.concat(log, "; "))
end
