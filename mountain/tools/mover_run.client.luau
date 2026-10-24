local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local player=game.Players.LocalPlayer;local char=player.Character
local h=char.Humanoid;local rr=char.HumanoidRootPart
local controls=require(player.PlayerScripts.PlayerModule):GetControls()
local w=workspace.ImpossibleMountain;local r=game.ReplicatedStorage.MountainRemotes
local state;local log={};local start=os.clock()
r.Event.OnClientEvent:Connect(function(kind,data)if kind=='state' then state=data end end)
local function record(label,ok,detail)
 table.insert(log,{label=label,ok=ok,detail=detail,position=tostring(rr.Position),elapsed=os.clock()-start})
 workspace:SetAttribute('MountainQA_Mover',game.HttpService:JSONEncode({done=not ok,log=log}));return ok
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
  local q=C.route(1,i/48);local target=Vector3.new(q.x,q.y+3,q.z)
  if i>0 and i%12==0 then local b=C.route(1,(i+1)/48);target+=Vector3.new(b.x-q.x,0,b.z-q.z).Unit*3 end
  if not walk(target,'fresh-route:'..i) then return end
 end
elseif not script:GetAttribute('AtDock') then
r.Request:FireServer('Travel','1:recovery');task.wait(1)
if not record('earned-checkpoint-travel',(rr.Position-w.Checkpoints['1:recovery'].Position).Magnitude<12) then return end
for i=23,20,-1 do local q=C.route(1,i/48);if not walk(Vector3.new(q.x,q.y+3,q.z),'route:'..i) then return end end
end
local q=C.route(1,.42);local base=Vector3.new(q.x,q.y,q.z);local radial=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
local origin=base+radial*22;local finish=base+radial*57;local mover=w.Dynamics.KingdomLift_1
if not walk(base+Vector3.new(0,3,0),'challenge-junction') then return end
if not walk(origin-radial*4+Vector3.new(0,3,0),'dock') then return end
local begin=os.clock();while (mover.Position-origin).Magnitude>4 and os.clock()-begin<16 do task.wait(.1) end
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={char};rp.RespectCanCollide=true
local aboard=false;begin=os.clock();controls:Disable();h.Jump=true
repeat
 local delta=mover.Position-rr.Position;h:Move(Vector3.new(delta.X,0,delta.Z).Unit);task.wait(.03)
 local hit=workspace:Raycast(rr.Position,Vector3.new(0,-4,0),rp)
 aboard=hit~=nil and hit.Instance==mover and h.FloorMaterial~=Enum.Material.Air
until aboard or os.clock()-begin>8
controls:Enable()
if not record('board',aboard) then return end
h:Move(Vector3.zero)
begin=os.clock();while (mover.Position-finish).Magnitude>6 and os.clock()-begin<16 do task.wait(.1) end
if not record('ride',(rr.Position-mover.Position).Magnitude<9,{distanceToReward=(mover.Position-finish).Magnitude}) then return end
h.Jump=true
if not walk(finish-radial*2.5+Vector3.new(0,3,0),'reward-approach') then return end
task.wait(1)
local landing=workspace:Raycast(rr.Position,Vector3.new(0,-5,0),rp)
if not record('reward-landing',landing~=nil and landing.Instance.Name=='ChallengeRewardLedge',landing and landing.Instance.Name) then return end
end
local puzzle;for _,p in ipairs(w.Interactions:GetChildren())do if p:GetAttribute('Id')=='1:puzzle' then puzzle=p end end
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
 if state and #state.cargo>0 then solved=true;break end
end
record('puzzle-egg',solved,state and #state.cargo)
camera.CameraType=previous
workspace:SetAttribute('MountainQA_Mover',game.HttpService:JSONEncode({done=true,passed=solved,log=log,scope=if script:GetAttribute('FreshSpawn') then 'Fresh spawn, directional avatar movement, physical platform boarding, stationary ledge landing and timed rune prompts' else 'Earned checkpoint travel, natural movement, platform ride and timed rune prompt inputs'}))
