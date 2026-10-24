-- Real character traversal and authorized game inputs; no profile/position fixtures.
local p=game.Players.LocalPlayer;local h=p.Character.Humanoid;local rr=p.Character.HumanoidRootPart
local C=require(game.ReplicatedStorage.MountainShared.Catalog);local remotes=game.ReplicatedStorage.MountainRemotes
local current;local log={};local start=os.clock()
remotes.Event.OnClientEvent:Connect(function(kind,data) if kind=='state' then current=data end end)
local function record(name,ok,details)
 table.insert(log,{name=name,ok=ok,details=details,position=tostring(rr.Position),elapsed=os.clock()-start})
 workspace:SetAttribute('MountainQA_EggLoop',game.HttpService:JSONEncode({done=not ok,log=log}))
end
local function walk(pos,name)
 local began=os.clock();local timeout=(pos-rr.Position).Magnitude/9+16
 while (pos-rr.Position).Magnitude>5 and h.Health>0 and os.clock()-began<timeout do
  h:MoveTo(pos);workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,10,17),pos);task.wait(.25)
 end
 local ok=(pos-rr.Position).Magnitude<=5;record(name,ok);return ok
end
local function press(part)
 local q=part:FindFirstChildOfClass('ProximityPrompt');q:InputHoldBegin();task.wait(.75);q:InputHoldEnd();task.wait(.5)
end
local world=workspace.ImpossibleMountain
if not walk(Vector3.new(0,20,515),'refuge-exit') then return end
for i=0,9 do local q=C.route(1,i/48);if not walk(Vector3.new(q.x,q.y+3,q.z),'outward-route-'..i) then return end end
local creature=world.Encounters.Mossbun.PrimaryPart
if not walk(creature.Position+Vector3.new(0,1,4),'mossbun-approach') then return end
press(creature);local begun=os.clock()
while (not current or #current.cargo==0) and os.clock()-begun<30 do task.wait(.5) end
local ok=current and #current.cargo==1 and current.cargo[1].species=='mossbun';record('wild-egg-acquired',ok,current and current.cargo)
if not ok then return end
for i=9,0,-1 do local q=C.route(1,i/48);if not walk(Vector3.new(q.x,q.y+3,q.z),'return-route-'..i) then return end end
press(world.Checkpoints['1:entrance']);remotes.Request:FireServer('State');task.wait(.5)
record('checkpoint-extraction',current and #current.cargo==0 and #current.eggs==1,current and current.eggs)
remotes.Request:FireServer('Travel','refuge');task.wait(1)
record('earned-refuge-travel',(rr.Position-Vector3.new(0,21,550)).Magnitude<10)
workspace:SetAttribute('MountainQA_EggLoop',game.HttpService:JSONEncode({done=true,log=log,state=current,scope='Natural fresh-spawn wild encounter, extraction and authorized checkpoint travel. Incubation/hatch UI tested separately.'}))
