-- EDIT MODE ONLY. Adds metadata to the finished world; never writes terrain or rebuilds routes.
-- require(ServerStorage.CC_DevTools.AuthorTraversal:Clone())()
return function()
	assert(not game:GetService("RunService"):IsRunning(), "Author traversal in Edit mode")
	local RS, HS = game:GetService("ReplicatedStorage"), game:GetService("HttpService")
	local world = workspace:WaitForChild("World")
	local old = RS:FindFirstChild("CC_TraversalDefs")
	local defs = Instance.new("Folder")
	defs.Name = "CC_TraversalDefs"
	local count, failed, reports, entryWarnings, exitRepairs = 0, {}, {}, {}, {}
	local function vec(a) return Vector3.new(a[1], a[2], a[3]) end
	local function arr(v) return { math.round(v.X * 100) / 100, math.round(v.Y * 100) / 100, math.round(v.Z * 100) / 100 } end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { world, workspace.Terrain }
	rp.RespectCanCollide = true
	local function cast(p, d) return workspace:Raycast(p, d, rp) end
	local function marked(r) return r and (r.Instance:GetAttribute("Climbable") == true or r.Material == Enum.Material.Asphalt) end
	local function save(id, route, points, entry, exit, into, opts)
		if #points < 2 then failed[#failed + 1] = id .. ": no hold chain"; return end
		if id=="Waterfall:storm:45" then
			-- This preserved terrain lip has a 45.1-degree center and drops beneath one foot.
			-- Resolve only its exit onto an existing wider, flatter footprint; all other exits stay fixed.
			local original,last=exit,points[#points]
			local best,bestScore
			local offsets={Vector3.new(1.3,0,0),Vector3.new(-1.3,0,0),Vector3.new(0,0,1.3),Vector3.new(0,0,-1.3),Vector3.new(.95,0,.95),Vector3.new(.95,0,-.95),Vector3.new(-.95,0,.95),Vector3.new(-.95,0,-.95)}
			for radius=0,12 do
				for angle=0,337.5,22.5 do
					local a=math.rad(angle)
					local q=original+Vector3.new(math.cos(a)*radius,10,math.sin(a)*radius)
					local center=cast(q,Vector3.new(0,-21,0))
					if center and center.Normal.Y>=0.78 then
						local candidate=center.Position+Vector3.yAxis*3
						local valid=(candidate-last).Magnitude<=12 and candidate.Y>=last.Y-2 and candidate.Y<=last.Y+9
						for _,offset in ipairs(offsets) do
							local support=cast(candidate+offset+Vector3.yAxis*2,Vector3.new(0,-8,0))
							if not support or support.Normal.Y<0.72 or math.abs(support.Position.Y-center.Position.Y)>1.7 then valid=false; break end
						end
						if cast(candidate,Vector3.yAxis*3) then valid=false end
						local score=(candidate-original).Magnitude+(candidate-last).Magnitude*.15
						if valid and (not bestScore or score<bestScore) then best,bestScore=candidate,score end
					end
				end
			end
			if not best then failed[#failed+1]=id..": no stable exit footprint within existing mantle reach"; return end
			exit=best
			exitRepairs[#exitRepairs+1]={id=id,from=arr(original),to=arr(exit),mantleDistance=math.round((exit-last).Magnitude*100)/100}
		end
		-- Bot approach coordinates can sit beyond a narrow natural ledge. Resolve a physically
		-- supported clip position beside the already-authored face, never add a landing platform.
		local originalSupport=cast(entry+Vector3.yAxis*2,Vector3.new(0,-15,0))
		local needsRepair=not originalSupport or originalSupport.Normal.Y<0.70 or math.abs(originalSupport.Position.Y+3-entry.Y)>2.5
		if needsRepair and not opts.tutorial then
			local best,bestScore,bestPrefix
			for radius=0,20,2 do
				for angle=0,337.5,22.5 do
					local a=math.rad(angle)
					local q=points[1]+Vector3.new(math.cos(a)*radius,6,math.sin(a)*radius)
					local support=cast(q,Vector3.new(0,-23,0))
					if support and support.Normal.Y>=0.72 then
						local candidate=support.Position+Vector3.yAxis*3
						local distance=(candidate-points[1]).Magnitude
						if candidate.Y<=points[1].Y+3.5 and distance<=18 then
							local face=cast(candidate-into*2,into*12)
							if marked(face) then
								local normal=Vector3.new(face.Normal.X,0,face.Normal.Z)
								if normal.Magnitude>0.1 then
									local first=face.Position+normal.Unit*1.65
									local prefix={}
									local valid=(candidate-first).Magnitude<=7
									local length=(first-points[1]).Magnitude
									local n=math.max(1,math.ceil(length/3))
									for i=0,n-1 do
										local p=first:Lerp(points[1],i/n)
										local surface=cast(p-into*2,into*7)
										if not marked(surface) then valid=false; break end
										local no=Vector3.new(surface.Normal.X,0,surface.Normal.Z)
										if no.Magnitude<0.1 then valid=false; break end
										local projected=surface.Position+no.Unit*1.65
										if prefix[#prefix] and (projected-prefix[#prefix]).Magnitude>7.5 then valid=false; break end
										prefix[#prefix+1]=projected
									end
									if prefix[#prefix] and (prefix[#prefix]-points[1]).Magnitude>7.5 then valid=false end
									local score=distance+((candidate-entry)*Vector3.new(1,0,1)).Magnitude*0.1
									if valid and (not bestScore or score<bestScore) then best,bestScore,bestPrefix=candidate,score,prefix end
								end
							end
						end
					end
				end
			end
			if best then
				entry=best
				local merged={}
				for _,p in ipairs(bestPrefix) do merged[#merged+1]=p end
				for _,p in ipairs(points) do merged[#merged+1]=p end
				points=merged
			elseif originalSupport and originalSupport.Normal.Y>=0.70 and math.abs(originalSupport.Position.Y+3-entry.Y)<=4 then
				entry=originalSupport.Position+Vector3.yAxis*3
			end
		end
		local holds = {}
		local right = into:Cross(Vector3.yAxis).Unit
		for i, p in ipairs(points) do
			holds[#holds + 1] = { id = id .. ":" .. i, p = arr(p), stable = i % 4 == 0, index = i }
		end
		-- Two visible choices occasionally share the next step. The outer option is stable, with a modest refill.
		for i = 3, #points - 2, 5 do
			local q = points[i] + right * 0.9
			local hit = cast(q - into * 1.5, into * 5)
			if marked(hit) or opts.explicit then
				holds[i].alternative = { id = id .. ":" .. i .. "s", p = arr(q), stable = true, index = i }
			end
		end
		local data = { version = 1, id = id, route = route, holds = holds, entry = arr(entry), exit = arr(exit), into = arr(into), protected = opts.protected ~= false, practice = opts.practice, tutorial = opts.tutorial }
		local sv = Instance.new("StringValue")
		sv.Name, sv.Value, sv.Parent = id, HS:JSONEncode(data), defs
		count += 1
		reports[#reports + 1] = { id = id, holds = #holds }
		local support=cast(entry+Vector3.yAxis*2,Vector3.new(0,-15,0))
		if not support or support.Normal.Y<0.65 or math.abs(support.Position.Y+3-entry.Y)>3 then
			entryWarnings[#entryWarnings+1]={id=id,entry=arr(entry),normal=support and math.round(support.Normal.Y*100)/100,rootDelta=support and math.round((support.Position.Y+3-entry.Y)*100)/100}
		end
	end
	local tracks = RS:FindFirstChild("CC_Track")
	for _, route in ipairs({ "Shepherd", "Waterfall" }) do
		local sv = tracks and tracks:FindFirstChild(route)
		local ok, segments = pcall(function() return HS:JSONDecode(sv.Value) end)
		if ok then
			for _, seg in ipairs(segments) do
				for j, node in ipairs(seg.nodes or {}) do
					if node.k == "climb" then
						local prev, nxt
						for k = j - 1, 1, -1 do if seg.nodes[k].p then prev = vec(seg.nodes[k].p); break end end
						for k = j + 1, #seg.nodes do if seg.nodes[k].p then nxt = vec(seg.nodes[k].p); break end end
						local id = route .. ":" .. tostring(seg.id) .. ":" .. j
						-- Spline ladders have an explicit authored grip plane. Use it directly: a recessed
						-- ladder's approach ray can strike its natural rock lip before reaching the grip.
						local pieces = world:FindFirstChild("Routes") and world.Routes:FindFirstChild(route)
						pieces = pieces and pieces:FindFirstChild("Pieces")
						local number = tostring(seg.id):match("^L(%d+)$")
						local model = number and pieces and pieces:FindFirstChild("Ladder_" .. number)
						local grip = model and model:FindFirstChild("LadderGrip")
						if grip and prev and nxt then
							local into = -grip.CFrame.LookVector
							local front = grip.Position - into * (grip.Size.Z / 2 + 1.65)
							local bottom, top = grip.Position.Y - grip.Size.Y / 2, grip.Position.Y + grip.Size.Y / 2
							local points = {}
							for y = bottom + 3, top + 0.5, 3 do points[#points + 1] = Vector3.new(front.X, y, front.Z) end
							local landing
							for depth = 3, 16 do
								local q = Vector3.new(front.X, top + 9, front.Z) + into * depth
								local r = cast(q, Vector3.new(0, -16, 0))
								if r and r.Normal.Y > 0.65 and r.Position.Y >= top - 5 and r.Position.Y <= top + 4 then landing = r.Position + Vector3.yAxis * 3; break end
							end
							if landing then save(id, route, points, Vector3.new(front.X, bottom + 3, front.Z) - into, landing, into, { explicit = true })
							else failed[#failed + 1] = id .. ": explicit ladder landing missing" end
							continue
						end
						if prev and nxt and node.into then
							local into = vec(node.into).Unit
							local hit
							for _, dy in ipairs({ 0, 1, -1, 2, -2 }) do
								hit = cast(prev + Vector3.yAxis * dy - into * 2, into * 18)
								if marked(hit) then break end
							end
							if marked(hit) then
								local normal = Vector3.new(hit.Normal.X, 0, hit.Normal.Z).Unit
								local base = hit.Position + normal * 1.65
								local points = { base }
								local direction = node.dir and vec(node.dir).Unit or Vector3.yAxis
								local maxDist = node.dir and math.min(100, (nxt - prev).Magnitude + 5) or math.min(160, math.max(10, nxt.Y - base.Y + 7))
								local missed = 0
								for d = 3, maxDist, 3 do
									local q = base + direction * d
									local r = cast(q - into * 2, into * 7)
									if marked(r) then points[#points + 1] = r.Position + normal * 1.65; missed = 0
									else missed += 1; if missed >= 2 then break end end
								end
								local last = points[#points]
								local landing
								for _, depth in ipairs({ 5, 4, 6, 3, 8 }) do
									local q = last + into * depth + Vector3.yAxis * 7
									if node.dir then q = last + direction * depth + Vector3.yAxis * 7 end
									local r = cast(q, Vector3.new(0, -13, 0))
									if r and r.Normal.Y > 0.65 and r.Position.Y >= last.Y - 6 then landing = r.Position + Vector3.yAxis * 3; break end
								end
								if not landing and (nxt - last).Magnitude < 18 then landing = nxt end
								if landing then save(id, route, points, prev, landing, into, {}) else failed[#failed + 1] = id .. ": no safe landing" end
							else failed[#failed + 1] = id .. ": authored face not found" end
						end
					end
				end
			end
		end
	end
	local props = world:FindFirstChild("Core") and world.Core:FindFirstChild("Props")
	if props and props:FindFirstChild("RopeBase") and props:FindFirstChild("NookTop") then
		local originalEntry = props.RopeBase:GetAttribute("TraversalOriginalEntry") or props.RopeBase.Position
		props.RopeBase:SetAttribute("TraversalOriginalEntry",originalEntry)
		local exit = props.NookTop.Position
		local entry = originalEntry
		-- The v6 handoff's tutorial base was on a steep voxel side: players slid nine studs
		-- below its marker. Find real, lower, stable approach ground and preserve every terrain voxel.
		local best, bestScore
		for radius = 0, 16, 2 do
			for angle = 0, 315, 45 do
				local a = math.rad(angle)
				local q = originalEntry + Vector3.new(math.cos(a)*radius, 8, math.sin(a)*radius)
				local hit = cast(q, Vector3.new(0,-38,0))
				if hit and hit.Normal.Y >= 0.72 then
					local candidate = hit.Position + Vector3.yAxis*3
					if candidate.Y <= originalEntry.Y-2 and candidate.Y >= originalEntry.Y-26 then
						local score=radius+math.abs(candidate.Y-originalEntry.Y)*0.08
						if not bestScore or score<bestScore then best,bestScore=candidate,score end
					end
				end
			end
		end
		if best then entry=best end
		local nook = props:FindFirstChild("RareNook")
		local truss = nook and nook:FindFirstChild("RopeTruss")
		local into = Vector3.new(exit.X - entry.X, 0, exit.Z - entry.Z).Unit
		local points = {}
		for y = entry.Y, exit.Y - 2, 3 do
			local q=Vector3.new(entry.X,y,entry.Z)-into*2
			local hit=cast(q,into*28)
			if hit then
				local normal=Vector3.new(hit.Normal.X,0,hit.Normal.Z)
				if normal.Magnitude>0.1 then points[#points+1]=hit.Position+normal.Unit*1.65 end
			end
		end
		assert(#points>=3,"Tutorial stable entry could not connect to the existing face")
		save("Tutorial:RareNook", "Tutorial", points, entry, exit, into, { explicit = true, tutorial = true })
		props.RopeBase.Position=entry
		props.RopeBase:SetAttribute("TraversalApproachRepaired",true)
		if truss then truss.CanCollide = false; truss.CanTouch = false; truss:SetAttribute("CC_AuthoredTraversal", true) end
	end
	local yard = world:FindFirstChild("TrainingYard")
	if yard then
		local walls = {}
		for _, p in ipairs(yard:GetChildren()) do if p:IsA("BasePart") and p.Name == "PracticeWall" then walls[#walls + 1] = p end end
		table.sort(walls, function(a,b) return a.Size.Y < b.Size.Y end)
		local previousTop
		for i, p in ipairs(walls) do
			local into = p.CFrame.LookVector
			local bottom, top = p.Position.Y - p.Size.Y / 2, p.Position.Y + p.Size.Y / 2
			local baseY = previousTop or bottom
			local front = p.Position - into * (p.Size.Z / 2 + 1.65)
			local points = {}
			for y = baseY + 3, top + 1, 3 do points[#points + 1] = Vector3.new(front.X, y, front.Z) end
			local entry = Vector3.new(front.X, baseY + 3, front.Z) - into
			local exit = Vector3.new(p.Position.X, top + 3, p.Position.Z)
			save("Practice:" .. i, "Practice", points, entry, exit, into, { explicit = true, practice = i })
			previousTop = top
		end
	end
	assert(count >= 4, "No usable traversal authoring; existing registry preserved")
	if old then old:Destroy() end
	defs.Parent = RS
	world:SetAttribute("CC_TraversalVersion", 1)
	world:SetAttribute("CC_WorldExpansionPlaytestGate", true)
	return { sections = count, failed = failed, details = reports, entryWarnings = entryWarnings, exitRepairs = exitRepairs, terrainChanged = false }
end
