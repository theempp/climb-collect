-- Studio server only. require(...TraversalRouteSmoke)(startIndex, count)
-- Runs real section transitions through the live server bridge. Batches stop before 52 seconds.
-- Rest/normal recovery are used; stamina is never written by the test.
return function(startIndex,count)
	assert(game:GetService("RunService"):IsStudio())
	local HS=game:GetService("HttpService")
	local RS=game:GetService("ReplicatedStorage")
	local bridge=game:GetService("ServerStorage"):WaitForChild("CC_DevBridge")
	local plr=game:GetService("Players"):GetPlayers()[1]
	assert(plr and plr.Character,"player missing")
	local ch=plr.Character
	local root=ch:WaitForChild("HumanoidRootPart")
	local humanoid=ch:WaitForChild("Humanoid")
	local start=root.Position
	local sections={}
	for _,sv in ipairs(RS.CC_TraversalDefs:GetChildren()) do sections[#sections+1]=HS:JSONDecode(sv.Value) end
	table.sort(sections,function(a,b) return a.id<b.id end)
	startIndex=math.clamp(tonumber(startIndex) or 1,1,#sections)
	count=math.clamp(tonumber(count) or 6,1,8)
	local function call(action,p)
		p=p or {}; p.name=plr.Name
		return HS:JSONDecode(bridge:Invoke(action,p)).result
	end
	local function request(action,p)
		p=p or {}; p.action=action
		return call("request",{action="traversal",payload=p})
	end
	local function move(pos) call("move",{x=pos.X,y=pos.Y,z=pos.Z}) end
	local function mode() return ch:GetAttribute("CC_TraversalState") end
	local function position() local p=root.Position; return {p.X,p.Y,p.Z} end
	local function cargo()
		local st=call("snapshot"); local ids={}
		for _,it in ipairs(st.items or {}) do ids[#ids+1]=it.uid end
		table.sort(ids); return table.concat(ids,",")
	end
	local before=cargo()
	local started=os.clock()
	local rows={}
	local nextIndex=startIndex
	for index=startIndex,math.min(#sections,startIndex+count-1) do
		local sec=sections[index]
		local estimated=#sec.holds*0.52+5
		if #rows>0 and os.clock()-started+estimated>51 then break end
		local row={index=index,id=sec.id,holds=#sec.holds,pass=false}
		local entry,exit=Vector3.new(table.unpack(sec.entry)),Vector3.new(table.unpack(sec.exit))
		local ok,err=pcall(function()
			pcall(function() plr:RequestStreamAroundAsync(entry,2) end)
			move(entry); task.wait(0.95)
			row.entryDelta=(root.Position-entry).Magnitude
			row.entryPosition=position()
			row.floor=humanoid.FloorMaterial.Name
			request("clip"); task.wait(0.4)
			if mode()~="climb" and mode()~="rope" then
				row.reason=sec.practice and sec.practice>1 and "locked practice or unsupported entry" or "clip rejected"
				return
			end
			row.selectedSection=ch:GetAttribute("CC_SectionId")
			if row.selectedSection~=sec.id then row.reason="nearest anchor selected another section"; return end
			local attempts,catches=0,0
			while attempts<#sec.holds+12 and os.clock()-started<50 do
				if mode()=="ground" then break end
				if mode()=="hanging" then
					catches+=1
					task.wait(2.1); request("recover"); task.wait(0.4)
				elseif mode()=="climb" or mode()=="rope" then
					local i=ch:GetAttribute("CC_HoldIndex") or 1
					local h=sec.holds[i]
					if (ch:GetAttribute("CC_Stamina") or 100)<6 and h and (h.stable or h.alternative) then task.wait(2) end
					request("step",{hand=ch:GetAttribute("CC_NextHand"),choice="stable"})
					attempts+=1; task.wait(0.5)
				else break end
			end
			task.wait(0.7)
			row.exitDelta=(root.Position-exit).Magnitude
			row.catches,row.attempts=catches,attempts
			row.pass=mode()=="ground" and humanoid.FloorMaterial~=Enum.Material.Air and row.exitDelta<7 and cargo()==before
			if not row.pass then row.reason="landing/state/cargo mismatch" end
		end)
		if not ok then row.reason=tostring(err) end
		row.mode,row.position,row.stamina=mode(),position(),ch:GetAttribute("CC_Stamina")
		rows[#rows+1]=row
		nextIndex=index+1
		if mode()=="ground" and os.clock()-started<47 then task.wait(3) end
	end
	move(start)
	return {rows=rows,nextIndex=nextIndex,total=#sections,done=nextIndex>#sections,elapsed=os.clock()-started,kind="scripted actual rig/section test, not whole-route walking or human feel"}
end
