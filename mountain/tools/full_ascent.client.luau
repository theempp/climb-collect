local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local p=game.Players.LocalPlayer
local h=p.Character.Humanoid
local rr=p.Character.HumanoidRootPart
local remotes=game.ReplicatedStorage.MountainRemotes
local state, battle
local start=os.clock();local log={};local phase=0
local function record(label,ok,extra)
 table.insert(log,{label=label,ok=ok,extra=extra,position=tostring(rr.Position),elapsed=os.clock()-start})
 workspace:SetAttribute('MountainQA_FullAscent',game.HttpService:JSONEncode({done=not ok,log=log,elapsed=os.clock()-start}))
end
remotes.Event.OnClientEvent:Connect(function(kind,data)
 if kind=='state' then state=data elseif kind=='battle' then
  battle=data
  if data and data.phase and data.phase>phase then phase=data.phase;task.delay(.25,function() remotes.Request:FireServer('Dodge') end) end
 end
end)
remotes.Request:FireServer('State')
local function walk(pos,label)
 local begin=os.clock();local timeout=(rr.Position-pos).Magnitude/9+18
 while (rr.Position-pos).Magnitude>5 and os.clock()-begin<timeout and h.Health>0 do
  h:MoveTo(pos);workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,10,17),pos);task.wait(.3)
 end
 local ok=(rr.Position-pos).Magnitude<=5 and h.Health>0;record(label,ok,os.clock()-begin);return ok
end
local function press(part)
 workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,7,13),part.Position);task.wait(.2)
 local prompt=part:FindFirstChildOfClass('ProximityPrompt');prompt:InputHoldBegin();task.wait(.75);prompt:InputHoldEnd();task.wait(.3)
end
local world=workspace.ImpossibleMountain
if not walk(world.Checkpoints['1:guardian'].Position+Vector3.new(0,4,0),'return-to-ascent') then return end
press(world.Checkpoints['1:guardian'])
for k=1,6 do
 local first=if k==1 then 43 else 0
 for i=first,48 do
  local q=C.route(k,i/48);local pos=Vector3.new(q.x,q.y+3,q.z)
  if i>0 and i%12==0 then
   local qnext=C.route(k,math.min(1,i/48+1/48))
   local prev=C.route(k,(i-1)/48)
   local tangent=if i<48 then Vector3.new(qnext.x-q.x,0,qnext.z-q.z).Unit else Vector3.new(q.x-prev.x,0,q.z-prev.z).Unit
   pos+=tangent*3
  end
  if not walk(pos,k..':route'..i) then return end
  if i==0 or i==24 or i==42 then
   local cp=world.Checkpoints[k..':'..(if i==0 then 'entrance' elseif i==24 then 'recovery' else 'guardian')]
   press(cp)
  end
  if i==42 and k>1 then
   local altar=world.Interactions[C.guardians[k].name]
   if not walk(altar.Position+Vector3.new(0,3,3),k..':arena') then return end
   battle=nil;phase=0;press(altar)
   local begun=os.clock()
   while battle==nil and os.clock()-begun<5 do task.wait(.2) end
   if not battle then record(k..':battle-start',false,'No battle event');return end
   local center=Vector3.new(altar:GetAttribute('ArenaX'),altar:GetAttribute('ArenaY'),altar:GetAttribute('ArenaZ'))
   h:MoveTo(center+Vector3.new(27,3,27))
   while battle and os.clock()-begun<150 and h.Health>0 do
    remotes.Request:FireServer('Special',{slot=2,ability=1});task.wait(.35)
    remotes.Request:FireServer('Special',{slot=1,ability=1});task.wait(.35)
    remotes.Request:FireServer('Special',{slot=3,ability=1});task.wait(.65)
   end
   remotes.Request:FireServer('State');task.wait(.5)
   local won=state and state.wins[tostring(k)]==true
   record(k..':normal-guardian',won,{health=h.Health,seconds=os.clock()-begun})
   if not won then return end
   if not walk(world.Checkpoints[k..':guardian'].Position+Vector3.new(0,4,0),k..':return-to-ascent') then return end
   press(world.Checkpoints[k..':guardian'])
  end
 end
end
local summit=world.Interactions['Impossible Summit']
if not walk(Vector3.new(0,843,0),'final-summit') then return end
press(summit);remotes.Request:FireServer('State');task.wait(.5)
record('summit-reward',state and state.discoveries.summit==true,state and {coins=state.coins,trophies=state.trophies,wins=state.wins})
workspace:SetAttribute('MountainQA_FullAscent',game.HttpService:JSONEncode({done=true,passed=state and state.discoveries.summit==true,log=log,elapsed=os.clock()-start,scope='Natural movement and authorized game inputs. No position/progression injection. Continuation from natural Floravelle trial.'}))
