-- Local QA: each timed WalkSpeed-12 trip begins from the spawn fixture.
local H=game.HttpService;local b=game.ServerStorage.CC_DevBridge;local p=game.Players:GetPlayers()[1];local a=workspace.World.Fairground.Anchors
local rows={};script:SetAttribute('Status','running')
local ok,err=pcall(function()
 for _,name in {'Bank','Collection','RouteBoard','Exchange_Bundle','PracticeStart','HomeDoor'} do
  b:Invoke('move',{x=a.Spawn.Position.X,y=a.Spawn.Position.Y+3,z=a.Spawn.Position.Z});task.wait(.7)
  local r=p.Character.HumanoidRootPart;local h=p.Character.Humanoid;r:SetNetworkOwner(nil);h.WalkSpeed=12
  script:SetAttribute('Detail',name);local started=os.clock()
  while ((r.Position-a[name].Position)*Vector3.new(1,0,1)).Magnitude>3 do
   assert(os.clock()-started<12,'route blocked: '..name);h:MoveTo(a[name].Position);task.wait(.05)
  end
  table.insert(rows,{service=name,seconds=os.clock()-started,position=tostring(r.Position),range=3})
 end
end)
script:SetAttribute('Status',ok and 'complete' or 'failed');script:SetAttribute('Detail',ok and 'all services reached' or tostring(err))
local result=Instance.new('StringValue');result.Name='Report';result.Value=H:JSONEncode({ok=ok,error=not ok and tostring(err),walkSpeed=12,kind='actual Humanoid MoveTo; each starting location is a fixture',rows=rows});result.Parent=script
