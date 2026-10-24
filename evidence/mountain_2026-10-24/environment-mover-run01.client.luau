task.spawn(function()
 local hs=game.HttpService
 repeat task.wait(1); local raw=workspace:GetAttribute('MountainQA_OptionalMatrix'); local d=raw and hs:JSONDecode(raw)
 until d and d.done
 local prior=hs:JSONDecode(workspace:GetAttribute('MountainQA_OptionalMatrix'))
 if not prior.passed then workspace:SetAttribute('MountainQA_MoverMatrix',hs:JSONEncode({done=true,passed=false,reason='Optional matrix failed; no platform run started'}));return end
 local checks={}
 for _,kingdomId in ipairs({6,2,3,4,5,1}) do
  workspace:SetAttribute('MountainQA_MoverMatrix',hs:JSONEncode({done=false,active=kingdomId,checks=checks}))
  local script=Instance.new('LocalScript');script.Name='MountainQA_KingdomMover_'..kingdomId;script:SetAttribute('Kingdom',kingdomId);script.Parent=game.Players.LocalPlayer.PlayerScripts
  local ok,err=xpcall(function()
-- Parameterized actual-kingdom platform acceptance; earned travel only.
local kingdom=script:GetAttribute("Kingdom") or 1
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local player=game.Players.LocalPlayer;local char=player.Character
local h=char.Humanoid;local rr=char.HumanoidRootPart
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local w=workspace.ImpossibleMountain;local r=game.ReplicatedStorage.MountainRemotes
local state;local log={};local start=os.clock()
r.Event.OnClientEvent:Connect(function(kind,data)if kind=='state' then state=data end end)
local function record(label,ok,detail)
 table.insert(log,{label=label,ok=ok,detail=detail,position=tostring(rr.Position),elapsed=os.clock()-start})
 workspace:SetAttribute('MountainQA_Mover_'..kingdom,game.HttpService:JSONEncode({done=not ok,log=log}));return ok
end
local function walk(pos,label)
 controls:Disable()
 local begin=os.clock();while (rr.Position-pos).Magnitude>4 and os.clock()-begin<25 and h.Health>0 do local delta=pos-rr.Position;h:Move(Vector3.new(delta.X,0,delta.Z).Unit);task.wait(.03) end
 h:Move(Vector3.zero)
 controls:Enable()
 return record(label,(rr.Position-pos).Magnitude<=4)
end
if not script:GetAttribute('AtReward') then
if script:GetAttribute('FreshSpawn') then
 for i=0,20 do
  local q=C.route(kingdom,i/48);local target=Vector3.new(q.x,q.y+3,q.z)
  if i>0 and i%12==0 then local b=C.route(kingdom,(i+1)/48);target+=Vector3.new(b.x-q.x,0,b.z-q.z).Unit*3 end
  if not walk(target,'fresh-route:'..i) then return end
 end
elseif not script:GetAttribute('AtDock') then
r.Request:FireServer('Travel',kingdom..':recovery');task.wait(1)
if not record('earned-checkpoint-travel',(rr.Position-w.Checkpoints[kingdom..':recovery'].Position).Magnitude<12) then return end
for i=23,20,-1 do local q=C.route(kingdom,i/48);if not walk(Vector3.new(q.x,q.y+3,q.z),'route:'..i) then return end end
end
local q=C.route(kingdom,.42);local base=Vector3.new(q.x,q.y,q.z);local radial=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
local origin=base+radial*22;local finish=base+radial*57;local mover=w.Dynamics:FindFirstChild('KingdomLift_'..kingdom)
if not walk(base+Vector3.new(0,3,0),'challenge-junction') then return end
if not walk(origin-radial*4+Vector3.new(0,3,0),'dock') then return end
local begin=os.clock();while (mover.Position-origin).Magnitude>4 and os.clock()-begin<16 do task.wait(.1) end
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={char};rp.RespectCanCollide=true
local aboard=false;begin=os.clock();controls:Disable();h.Jump=true
repeat
 local delta=mover.Position-rr.Position;h:Move(Vector3.new(delta.X,0,delta.Z).Unit);task.wait(.03)
 local hit=workspace:Raycast(rr.Position,Vector3.new(0,-4,0),rp)
 local planar=Vector3.new(delta.X,0,delta.Z).Magnitude
 aboard=hit~=nil and hit.Instance==mover and h.FloorMaterial~=Enum.Material.Air and planar<2.5 and (mover.Position-origin).Magnitude>10
until aboard or os.clock()-begin>8
controls:Enable()
if not record('board',aboard) then return end
if kingdom==6 then
 local force;for _,v in ipairs(rr:GetChildren()) do if v:IsA('VectorForce') and v.Name=='MountainGravity' then force=v end end
 if not record('actual-gravity-force',force~=nil and force.Force.Y>0,force and tostring(force.Force)) then return end
end
h:Move(Vector3.zero)
begin=os.clock();while (mover.Position-finish).Magnitude>6 and os.clock()-begin<16 do task.wait(.1) end
if not record('ride',(rr.Position-mover.Position).Magnitude<9,{distanceToReward=(mover.Position-finish).Magnitude}) then return end
h.Jump=true
if not walk(finish-radial*2.5+Vector3.new(0,3,0),'reward-approach') then return end
task.wait(1)
local landing=workspace:Raycast(rr.Position,Vector3.new(0,-5,0),rp)
if not record('reward-landing',landing~=nil and landing.Instance.Name=='ChallengeRewardLedge',landing and landing.Instance.Name) then return end
end
local puzzle;for _,p in ipairs(w.Interactions:GetChildren())do if p:GetAttribute('Id')==kingdom..':puzzle' then puzzle=p end end
r.Request:FireServer('State');task.wait(.4)
local cargoBefore=state and #state.cargo
if not record('state-before-puzzle',cargoBefore~=nil) then return end
local solved=false
local camera=workspace.CurrentCamera;local previous=camera.CameraType;camera.CameraType=Enum.CameraType.Scriptable
for attempt=1,3 do
 for rune=1,3 do
  local begin=os.clock()
  repeat task.wait(.05) until (math.floor(workspace:GetServerTimeNow()/2)%3+1==rune and workspace:GetServerTimeNow()%2<.3) or os.clock()-begin>7
  workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,7,13),puzzle.Position)
  local prompt=puzzle:FindFirstChildOfClass('ProximityPrompt');prompt:InputHoldBegin();task.wait(.6);prompt:InputHoldEnd();task.wait(.2)
 end
 r.Request:FireServer('State');task.wait(.4)
 if state and #state.cargo==cargoBefore+1 then solved=true;break end
end
record('puzzle-egg',solved,state and #state.cargo)
camera.CameraType=previous
if solved and not script:GetAttribute('AtReward') then
 local q=C.route(kingdom,.42);local base=Vector3.new(q.x,q.y,q.z)
 local radial=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
 local origin=base+radial*22;local finish=base+radial*57
 local mover=w.Dynamics:FindFirstChild('KingdomLift_'..kingdom)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={char};rp.RespectCanCollide=true
 local begin=os.clock();while (mover.Position-finish).Magnitude>4 and os.clock()-begin<16 do task.wait(.1) end
 local aboard=false;begin=os.clock();controls:Disable();h.Jump=true
 repeat
  local delta=mover.Position-rr.Position;h:Move(Vector3.new(delta.X,0,delta.Z).Unit);task.wait(.03)
  local hit=workspace:Raycast(rr.Position,Vector3.new(0,-4,0),rp)
  aboard=hit~=nil and hit.Instance==mover and h.FloorMaterial~=Enum.Material.Air and Vector3.new(delta.X,0,delta.Z).Magnitude<2.5 and (mover.Position-finish).Magnitude>10
 until aboard or os.clock()-begin>8
 controls:Enable()
 if not record('return-board',aboard) then return end
 h:Move(Vector3.zero);begin=os.clock()
 while (mover.Position-origin).Magnitude>6 and os.clock()-begin<16 do task.wait(.1) end
 if not record('return-ride',(rr.Position-mover.Position).Magnitude<9 and (mover.Position-origin).Magnitude<6) then return end
 h.Jump=true
 if not walk(origin-radial*4+Vector3.new(0,3,0),'return-dock') or not walk(base+Vector3.new(0,3,0),'return-junction') then return end
 for i=21,24 do
  local q=C.route(kingdom,i/48);local pos=Vector3.new(q.x,q.y+3,q.z)
  if i==24 then local b=C.route(kingdom,25/48);pos+=Vector3.new(b.x-q.x,0,b.z-q.z).Unit*3 end
  if not walk(pos,'return-route:'..i) then return end
 end
 local cp=w.Checkpoints[kingdom..':recovery']
 if not walk(cp.Position+Vector3.new(0,3,0),'extraction-approach') then return end
 camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,7,13),cp.Position)
 local prompt=cp:FindFirstChildOfClass('ProximityPrompt');prompt:InputHoldBegin();task.wait(prompt.HoldDuration+.2);prompt:InputHoldEnd();task.wait(.4)
 camera.CameraType=previous;r.Request:FireServer('State');task.wait(.3)
 if not record('puzzle-extracted',state and #state.cargo==0) then return end
end
local checked={}
for _,entry in ipairs(log) do if entry.ok then checked[entry.label]=true end end
workspace:SetAttribute('MountainQA_Mover_'..kingdom,game.HttpService:JSONEncode({done=true,passed=solved,log=log,kingdom=kingdom,checked=checked,start=if script:GetAttribute('AtReward') then 'reward-only' elseif script:GetAttribute('AtDock') then 'dock' elseif script:GetAttribute('FreshSpawn') then 'fresh-spawn' else 'earned-checkpoint',scope='Only successful checked labels establish coverage. Boarding, riding and landing are untested when absent; reward-only resume establishes puzzle coverage only.'}))


  end,debug.traceback)
  local raw=workspace:GetAttribute('MountainQA_Mover_'..kingdomId);local result=raw and hs:JSONDecode(raw)
  table.insert(checks,{kingdom=kingdomId,passed=ok and result and result.passed==true,error=not ok and err or nil})
  if not ok or not result or not result.passed then workspace:SetAttribute('MountainQA_MoverMatrix',hs:JSONEncode({done=true,passed=false,active=kingdomId,checks=checks}));return end
 end
 workspace:SetAttribute('MountainQA_MoverMatrix',hs:JSONEncode({done=true,passed=true,checks=checks}))
end)
return 'Queued actual platform matrix after successful optional-route run; no state grants'