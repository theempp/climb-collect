-- Read-only Studio probe. Returns existing stable ground on closed corridors and shared controls.
-- Does not move players, create objects, alter metadata, or write terrain.
return function()
	local RS=game:GetService("ReplicatedStorage")
	local HS=game:GetService("HttpService")
	local Rules=require(RS.CC_Core.TraversalRules)
	local world=workspace:WaitForChild("World")
	local closedPaths,openPaths,closedSamples={}, {}, {}
	local gates,pads={},{}
	local function append(route,points)
		local closed=route=="Ledge" or route=="Spire"
		if #points>=2 then table.insert(closed and closedPaths or openPaths,{route=route,points=points}) end
		if closed then
			for i=1,#points,3 do closedSamples[#closedSamples+1]={route=route,p=points[i]} end
		end
	end
	for _,sv in ipairs(RS.CC_Route:GetChildren()) do
		if sv:IsA("StringValue") then
			local points={}
			for row in sv.Value:gmatch("[^;]+") do
				local x,y,z=row:match("([^,]+),([^,]+),([^,]+)")
				x,y,z=tonumber(x),tonumber(y),tonumber(z)
				if Rules.finite(x) and Rules.finite(y) and Rules.finite(z) then points[#points+1]={x,y,z} end
			end
			append(sv.Name,points)
		end
	end
	for _,sv in ipairs(RS.CC_Track:GetChildren()) do
		if sv:IsA("StringValue") then
			local ok,tracks=pcall(function() return HS:JSONDecode(sv.Value) end)
			if ok then
				for _,track in ipairs(tracks) do
					local points={}
					for _,node in ipairs(track.nodes or {}) do if node.p then points[#points+1]=node.p end end
					append(sv.Name,points)
				end
			end
		end
	end
	for _,sv in ipairs(RS.CC_TraversalDefs:GetChildren()) do
		local sec=HS:JSONDecode(sv.Value)
		local points={sec.entry}
		for _,hold in ipairs(sec.holds) do points[#points+1]=hold.p end
		points[#points+1]=sec.exit
		append(sec.route,points)
	end
	for _,d in ipairs(world:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute("ComingSoon") and d:FindFirstChild("Board") then gates[d:GetAttribute("Route") or d.Name:gsub("Gate_","")]=d:GetPivot() end
	end
	for _,part in ipairs(world.Checkpoints:GetChildren()) do
		if part:IsA("BasePart") and tostring(part:GetAttribute("Checkpoint")):match("^Camp%d$") then pads[#pads+1]=part.Position-Vector3.yAxis*part.Size.Y/2 end
	end
	local closed,open=Rules.routeIndex(closedPaths,64),Rules.routeIndex(openPaths,64)
	local empty=Rules.routeIndex({},64)
	local rp=RaycastParams.new()
	rp.FilterType=Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances={world,workspace.Terrain}
	rp.RespectCanCollide=true
	local function arr(v) return {math.round(v.X*100)/100,math.round(v.Y*100)/100,math.round(v.Z*100)/100} end
	local rows,found={},{}
	local function add(key,row)
		if not found[key] then found[key]=true; row.case=key; rows[#rows+1]=row end
	end
	for _,sample in ipairs(closedSamples) do
		local v=Vector3.new(table.unpack(sample.p))
		local hit=workspace:Raycast(v+Vector3.yAxis*12,Vector3.new(0,-36,0),rp)
		if hit and hit.Normal.Y>=0.76 then
			local pos=hit.Position+Vector3.yAxis*3
			local p={pos.X,pos.Y,pos.Z}
			local raw=Rules.closedRouteAt(closed,empty,p)
			local guarded=Rules.closedRouteAt(closed,open,p)
			local gate=gates[sample.route]
			if raw and gate then
				local localP=gate:PointToObjectSpace(pos)
				local entrance=math.abs(localP.X)<85 and localP.Z<-2 and localP.Z>-180 and localP.Y>-30 and localP.Y<150
				local atCamp=false
				for _,pad in ipairs(pads) do if (pos-pad).Magnitude<80 then atCamp=true; break end end
				local row={route=sample.route,position=arr(pos),normal=hit.Normal.Y,gateLocal=arr(localP),sourcePosition=sample.p,expected=guarded and not atCamp and "return to closed gate" or "remain on open/shared ground"}
				if guarded==sample.route and not atCamp then
					if not entrance and (pos-gate.Position).Magnitude>220 then add(sample.route..":outsideEntranceBox",row) end
					if (pos-gate.Position).Magnitude>1000 then add(sample.route..":farAlongPath",table.clone(row)) end
				elseif (not guarded or atCamp) and not entrance then add("sharedOpenControl",row) end
			end
		end
	end
	local missing={}
	for _,route in ipairs({"Ledge","Spire"}) do if not found[route..":outsideEntranceBox"] then missing[#missing+1]=route..": no supported isolated closed-path sample found; do not invent terrain" end end
	return {rows=rows,missing=missing,closedSegments=closed.segments,openSegments=open.segments,readOnly=true}
end
