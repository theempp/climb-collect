-- Run through Studio Client execute_luau. Ordinary Humanoid movement; no teleports,
-- speed/health edits, inventory injection or progression bypasses.
local p=game.Players.LocalPlayer
local h=p.Character:WaitForChild('Humanoid');local rr=h.RootPart
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local w=workspace.ImpossibleMountain
local log={};local start=os.clock();local failed=false
local function publish(done)
 workspace:SetAttribute('MountainQA_QualityWalk',game.HttpService:JSONEncode({done=done,passed=done and not failed,elapsed=os.clock()-start,log=log,health=h.Health}))
end
local function walk(q,label,jump)
 local begin=os.clock();local timeout=(rr.Position-q).Magnitude/10+12
 local jumpObserved,airborneObserved,landingObserved=false,false,false
 local jumpStates={};local maxUp=0;local stateConnection
 if jump then
  stateConnection=h.StateChanged:Connect(function(_,state)
   table.insert(jumpStates,tostring(state))
   if state==Enum.HumanoidStateType.Jumping then jumpObserved=true end
   if jumpObserved and state==Enum.HumanoidStateType.Freefall then airborneObserved=true end
   if airborneObserved and (state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.Running) then landingObserved=true end
  end)
  -- The external QA runner sends an actual Space keyDown/keyUp to this Studio
  -- client when this marker appears. Observe the normal controller/physics path.
  workspace:SetAttribute('MountainQA_RequestJump',label)
 end
 repeat h:MoveTo(q);task.wait(.12);maxUp=math.max(maxUp,rr.AssemblyLinearVelocity.Y)
 until (Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<2.3 and (not jump or landingObserved)) or os.clock()-begin>timeout or h.Health<=0
 if stateConnection then stateConnection:Disconnect() end
 if jump then workspace:SetAttribute('MountainQA_RequestJump',nil) end
 local ok=Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<3 and math.abs(rr.Position.Y-q.Y)<5
 if jump then ok=ok and jumpObserved and airborneObserved and landingObserved and maxUp>10 end
 table.insert(log,{label=label,ok=ok,seconds=os.clock()-begin,position=tostring(rr.Position),target=tostring(q),speed=h.WalkSpeed,jump=jump==true,jumpObserved=jumpObserved,airborneObserved=airborneObserved,landingObserved=landingObserved,maxUp=maxUp,jumpStates=jumpStates})
 failed=failed or not ok;publish(not ok);return ok
end
local function point(k,x,d)
 local z=-210-((k-1)*200+d)*.85; x=4096+(x-4096)*.85
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={w[C.kingdoms[k].name]};rp.RespectCanCollide=true
 local hit=workspace:Raycast(Vector3.new(x,500,z),Vector3.new(0,-600,0),rp)
 assert(hit,'No collision below target '..k..' '..x..' '..d)
 return Vector3.new(x,hit.Position.Y+3.1,z)
end
task.spawn(function()
 local ok,err=pcall(function()
  for _,q in {Vector3.new(3438,3.1,-48),Vector3.new(3738,31.1,-108),Vector3.new(3960,31.1,-166),Vector3.new(3960,31.1,-182),Vector3.new(3960,19.1,-210),Vector3.new(4008,19.1,-210)} do if not walk(q,'entrance') then return end end
  for k=1,6 do

   for _,d in {2,20,40,60,80,100,122,140,196} do if not walk(point(k,4008,d),k..':west-ascent:'..d,d==60) then return end end
  end
  if not walk(point(6,4184,190),'summit crossing') then return end
  for k=6,1,-1 do
   for _,d in {190,124,100,80,60,40,20,2} do if not walk(point(k,4184,d),k..':east-descent:'..d,d==60) then return end end
  end
  if not walk(point(1,4096,2),'center transfer') then return end
  game.ReplicatedStorage.MountainRemotes.SprintRequest:FireServer(true);task.wait(.4)
  for k=1,6 do for _,d in {40,80,124,196} do if not walk(point(k,4090,d),k..':sprint-ascent:'..d) then return end end end
  for k=6,1,-1 do for _,d in {190,124,80,40,2} do if not walk(point(k,4090,d),k..':sprint-descent:'..d) then return end end end
  game.ReplicatedStorage.MountainRemotes.SprintRequest:FireServer(false)
  if not walk(Vector3.new(4090,19.1,-160),'physical exit') then return end
  publish(true)
 end)
 if not ok then failed=true;table.insert(log,{label='probe error',ok=false,error=tostring(err)});publish(true) end
end)
return 'Natural all-six walk/jump and sprint probe started'
