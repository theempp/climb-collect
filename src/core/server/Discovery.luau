-- Journal stamps are proximity-validated observations, never an income/adventure reward loop.
local Discovery={}
local ctx
local routes={
	{id="Shepherd",name="Shepherd's Road",status="Open",difficulty="Gentle",pips=1,description="Natural trails, short gaps and protected practice climbs."},
	{id="Waterfall",name="Waterfall Stair",status="Open",difficulty="Moderate",pips=2,description="Falls-side pitches and visible rock holds."},
	{id="Ledge",name="Cliff Ledge Line",status="Coming Soon",difficulty="Hard",pips=3,description="This route is closed."},
	{id="Spire",name="Spire Ridge",status="Coming Soon",difficulty="Expert",pips=4,description="This route is closed."},
}
function Discovery.init(c)
	ctx=c
	local Prompts=require(script.Parent.Prompts)
	local points={}
	for _,t in ipairs(workspace.World.Checkpoints:GetChildren()) do
		local name=t:GetAttribute("Checkpoint")
		if name and (string.match(name,"^Camp%d$") or name=="Summit") then points[name]=t end
	end
	local foothold=workspace:FindFirstChildOfClass("SpawnLocation")
	if foothold then points.Foothold=foothold end
	for id,part in pairs(points) do
		local name=id=="Foothold" and "The mountain from home" or (part:GetAttribute("Label") or id)
		local p=Prompts.make(part,{Name="ViewpointPrompt",ActionText="Stamp viewpoint",ObjectText=name,HoldDuration=0.4,MaxActivationDistance=12})
		p.Triggered:Connect(function(plr)
			local s=ctx.sessions[plr]
			if not s or not Prompts.validate(p,plr) then return end
			if s.data.journal[id] then ctx.toast(plr,"This view is already in your journal.","info") return end
			ctx.transaction(plr,"viewpoint:"..id,function(d)
				d.journal[id]={label=name,at=ctx.Clock.now(),method="viewpoint",region=id}
				return {ok=true}
			end,function() ctx.toast(plr,"Journal stamp: "..name,"good") ctx.push(plr) end)
		end)
	end
end
function Discovery.state(_,st) st.routes=routes st.regions={"Green Valley","Whispering Forest","Broken Cliffs","Storm Ridge","Frozen Summit"} end
return Discovery
