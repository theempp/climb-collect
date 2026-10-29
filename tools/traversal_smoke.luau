-- Studio SERVER only. Uses the actual Core service bridge and real authored tutorial section.
-- Returns observed transitions; this is a scripted smoke test, not a human/device playtest.
return function()
	assert(game:GetService("RunService"):IsStudio())
	local HS=game:GetService("HttpService")
	local RS=game:GetService("ReplicatedStorage")
	local bridge=game:GetService("ServerStorage"):WaitForChild("CC_DevBridge")
	local plr=game:GetService("Players"):GetPlayers()[1]
	assert(plr and plr.Character,"player missing")
	local ch=plr.Character
	local root=ch:WaitForChild("HumanoidRootPart")
	local start=root.Position
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
	local observations={}
	local function record(name,ok,detail)
		observations[#observations+1]={name=name,pass=ok,detail=detail}
		assert(ok,name..": "..tostring(detail))
	end
	local function cargo()
		local st=call("snapshot"); local ids={}
		for _,it in ipairs(st.items or {}) do ids[#ids+1]=it.uid end
		table.sort(ids); return table.concat(ids,",")
	end
	local before=cargo()
	local originalAssist=plr:GetAttribute("CC_TimingAssist")
	plr:SetAttribute("CC_TimingAssist",false)
	local falls=plr:GetAttribute("CC_Falls") or 0
	local sec=HS:JSONDecode(RS.CC_TraversalDefs["Tutorial:RareNook"].Value)
	local ok,err=pcall(function()
		move(Vector3.new(table.unpack(sec.entry)))
		task.wait(1)
		request("clip"); task.wait(0.6)
		record("clip starts authored section",mode()=="climb",mode())
		local i=ch:GetAttribute("CC_HoldIndex")
		request("step",{hand="R"}); task.wait(0.2)
		record("single wrong hand does not slip",mode()=="climb" and ch:GetAttribute("CC_HoldIndex")==i,mode())
		request("step",{hand="L"}); task.wait(0.55)
		record("correct rhythm advances exactly one hold",ch:GetAttribute("CC_HoldIndex")==i+1,ch:GetAttribute("CC_HoldIndex"))
		request("slip"); task.wait(0.4)
		record("protected slip hangs",mode()=="hanging",mode())
		record("harness preserves cargo and fall count",cargo()==before and (plr:GetAttribute("CC_Falls") or 0)==falls,cargo())
		request("recover"); task.wait(0.55)
		record("hanging recovery regains hold",mode()=="climb",mode())
		for _=1,#sec.holds+2 do
			if mode()~="climb" then break end
			request("step",{hand=ch:GetAttribute("CC_NextHand")}); task.wait(0.55)
		end
		record("authored final transition lands",mode()=="ground",mode())
		record("landing preserves cargo",cargo()==before,cargo())
		request("rope"); task.wait(0.1)
		move(Vector3.new(table.unpack(sec.entry))); task.wait(0.8)
		request("grab"); task.wait(0.4)
		record("shared rope attaches without personal clip",mode()=="rope" and ch:GetAttribute("CC_Clipped")==false,mode())
		request("parachute"); task.wait(0.1)
		record("climb cannot deploy emergency parachute",mode()=="rope",mode())
	end)
	move(start)
	plr:SetAttribute("CC_TimingAssist",originalAssist)
	return {ok=ok,error=not ok and tostring(err) or nil,observations=observations,kind="Studio scripted live traversal smoke"}
end
