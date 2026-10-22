-- Read-only telemetry for the actual traversal-controller bot; no profile or position writes.
local H=game.HttpService;local p=game.Players:GetPlayers()[1];local bot=game.ServerScriptService:WaitForChild('ActualAscentWalk')
local trace=Instance.new('StringValue');trace.Name='Trace';trace.Parent=script
local rows={};local start=os.clock()
while bot.Parent and bot:GetAttribute('Status')=='running' do
 local st=game.ServerStorage.CC_SummitReview:Invoke('profile');local a=st.active;local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 table.insert(rows,{after=math.floor(os.clock()-start),position=r and {r.Position.X,r.Position.Y,r.Position.Z},checkpoint=p:GetAttribute('CC_Checkpoint'),ascent=a and {seq=a.seq,invalid=a.invalid,camps=a.lastMilestone,band=a.routeEvidence.band,distance=math.floor(a.routeEvidence.distance),sections=a.routeEvidence.sections},completed=st.completedThrough,bot=bot:GetAttributes()})
 trace.Value=H:JSONEncode(rows);task.wait(10)
end
