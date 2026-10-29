-- Meaningful pure-rule checks plus authored graph invariants, runnable on the Studio server.
local RS=game:GetService("ReplicatedStorage")
local R=require(RS.CC_Core.TraversalRules)
local K=require(RS.CC_Core.TraversalConfig)
local Tests={}
function Tests.run()
	local passed=0
	local function check(name,fn)
		local ok,err=pcall(fn)
		assert(ok,name..": "..tostring(err)); passed+=1
	end
	check("one wrong hand is a recoverable error",function()
		local s={mode="climb",hand="L",stamina=50,nextAt=0}
		local ok,why=R.step(s,"R",{},1,K,false)
		assert(not ok and why=="hand" and s.stamina==50)
	end)
	check("no time deadline while waiting",function()
		assert(R.step({mode="climb",hand="L",stamina=50,nextAt=0},"L",{},1790000000,K,false))
	end)
	check("timing assistance preserves cost and progress",function()
		local s={mode="climb",hand="L",stamina=50,nextAt=0}
		local a,cost=R.step(s,"L",{},1,K,false)
		local b,assisted=R.step(s,"R",{},1,K,true)
		assert(a and b and cost==assisted)
	end)
	check("ice rope effects depend on actual state",function()
		local _,base=R.step({mode="climb",hand="L",stamina=50,nextAt=0},"L",{},1,K,false)
		local _,ice=R.step({mode="climb",hand="L",stamina=50,nextAt=0,ice=true},"L",{},1,K,false)
		local _,rope=R.step({mode="rope",hand="L",stamina=50,nextAt=0},"L",{},1,K,false)
		assert(ice<base and rope<base)
	end)
	check("walkoffs and slips cannot open parachute",function()
		assert(not R.canDeploy({mode="ground"},1,true,12,10,K))
		assert(not R.canDeploy({mode="climb",jumpAt=0,jumpY=10},0.4,true,12,10,K))
		assert(not R.canDeploy({mode="ground",jumpAt=0,jumpY=10},0.4,true,9,10,K))
		assert(R.canDeploy({mode="ground",jumpAt=0,jumpY=10},0.4,true,12,10,K))
		assert(R.canDeploy({mode="fall",jumpAt=0,jumpY=10},0.4,true,12,10,K))
	end)
	check("parachute cannot advance camps",function()
		assert(not R.canLand(1,2,500,600)); assert(not R.canLand(2,1,700,600)); assert(R.canLand(2,1,300,600))
	end)
	check("occupied ropes survive expiry and departure",function()
		assert(not R.canRemoveRope({expires=1,occupants=1,retiring=true},10))
		assert(R.canRemoveRope({expires=1,occupants=0,retiring=true},10))
	end)
	check("flight and closed route checkpoints reject",function()
		assert(not R.checkpointAllowed("flight",true,"Shepherd",1,0))
		assert(not R.checkpointAllowed("ground",true,"Spire",nil,0))
		assert(not R.checkpointAllowed("ground",true,"Shepherd",3,0))
		assert(R.checkpointAllowed("ground",true,"Shepherd",1,0))
	end)
	check("remote numeric validation rejects NaN infinity",function()
		assert(not R.finite(0/0) and not R.finite(math.huge) and not R.finite("3") and R.finite(3))
	end)
	local graphCount=0
	check("authored graphs have unique identities and bounded steps",function()
		local folder=assert(RS:FindFirstChild("CC_TraversalDefs"),"missing authoring")
		local ids={}
		for _,sv in ipairs(folder:GetChildren()) do
			local s=game:GetService("HttpService"):JSONDecode(sv.Value)
			assert(K.launchRoutes[s.route] and #s.holds>=2)
			local last
			for _,h in ipairs(s.holds) do
				assert(not ids[h.id],"duplicate "..h.id); ids[h.id]=true
				local p=Vector3.new(table.unpack(h.p)); if last then assert((p-last).Magnitude<=8,"disconnected "..s.id) end; last=p
				if h.alternative then assert(not ids[h.alternative.id]); ids[h.alternative.id]=true; assert(h.alternative.stable) end
			end
			graphCount+=1
		end
		assert(folder:FindFirstChild("Tutorial:RareNook"),"missing tutorial")
		for i=1,3 do assert(folder:FindFirstChild("Practice:"..i),"missing practice "..i) end
	end)
	return {passed=passed,sections=graphCount,kind="pure rules + authored graph invariants; not human feel test"}
end
return Tests
