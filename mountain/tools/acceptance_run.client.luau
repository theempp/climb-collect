-- Automated natural-avatar acceptance: no position, health, inventory or gate injection.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local player=game.Players.LocalPlayer
local character=player.Character or player.CharacterAdded:Wait()
local h=character:WaitForChild('Humanoid')
local rr=character:WaitForChild('HumanoidRootPart')
local world=workspace.ImpossibleMountain
local remotes=game.ReplicatedStorage.MountainRemotes
local state,battle
local started=os.clock()
local log={}
local function record(label,ok,detail)
 table.insert(log,{label=label,ok=ok,detail=detail,elapsed=os.clock()-started,position=tostring(rr.Position)})
 workspace:SetAttribute('MountainQA_Acceptance',game.HttpService:JSONEncode({done=not ok,log=log,elapsed=os.clock()-started}))
 return ok
end
remotes.Event.OnClientEvent:Connect(function(kind,data)
 if kind=='state' then state=data elseif kind=='battle' then battle=data end
end)
local function request(action,data) remotes.Request:FireServer(action,data);task.wait(.16) end
request('State')
local function walk(pos,label)
 local start=os.clock();local timeout=(rr.Position-pos).Magnitude/9+18
 while (rr.Position-pos).Magnitude>5 and os.clock()-start<timeout and h.Health>0 do
  h:MoveTo(pos);task.wait(.2)
 end
 return record(label,h.Health>0 and (rr.Position-pos).Magnitude<=5,os.clock()-start)
end
local function press(part)
 workspace.CurrentCamera.CFrame=CFrame.lookAt(rr.Position+Vector3.new(0,7,13),part.Position)
 task.wait(.3)
 local prompt=part:FindFirstChildOfClass('ProximityPrompt')
 prompt:InputHoldBegin();task.wait(prompt.HoldDuration+.2);prompt:InputHoldEnd();task.wait(.4)
end
local function fight(k,trial)
 local altar=world.Interactions[C.guardians[k].name]
 local target=altar
 if trial then for _,p in ipairs(world.Interactions:GetChildren()) do
  if p:GetAttribute('Kind')=='Trial' and p:GetAttribute('Kingdom')==k then target=p;break end
 end end
 if not walk(target.Position+Vector3.new(0,3,3),k..':altar:'..tostring(trial)) then return false end
 battle=nil;press(target);local start=os.clock()
 while not battle and os.clock()-start<5 do task.wait(.1) end
 if not battle then return record(k..':battle-start',false,'No battle event') end
 local center=Vector3.new(altar:GetAttribute('ArenaX'),altar:GetAttribute('ArenaY'),altar:GetAttribute('ArenaZ'))
 local phase=-1;local specialAt=0
 while battle and h.Health>0 and os.clock()-start<240 do
  local beat=battle.phase or 0
  local pattern=(beat-1)%4+1
  if beat~=phase then
   phase=beat
   if beat==0 then h:MoveTo(center+Vector3.new(26,3,26))
   elseif pattern==1 then
    local delta=rr.Position-center
    h:MoveTo(center+Vector3.new(if delta.X>0 then -26 else 26,3,26))
   elseif pattern==2 then h:MoveTo(center+Vector3.new(26,3,26))
   elseif k==5 and pattern==3 then h:MoveTo(center+Vector3.new(0,3,-8))
   elseif k==6 and pattern==3 then
    for _,p in ipairs(world.Dynamics:GetChildren()) do
     if p.Name=='StarAlignment' and (p.Position-center).Magnitude<50 then
      if not walk(p.Position,k..':constellation') then return false end
      press(p)
     end
    end
   else h:MoveTo(center+Vector3.new(0,3,0)) end
  end
  -- Keep one special available for the golden-heart interrupt.
  if k==5 and pattern==3 and (rr.Position-(center+Vector3.new(0,3,-8))).Magnitude<13 then request('Special',{slot=3,ability=1}) end
  if os.clock()>specialAt then
   specialAt=os.clock()+1
   request('Special',{slot=2,ability=1});request('Special',{slot=1,ability=1})
   if k~=5 then request('Special',{slot=3,ability=1}) end
  end
  task.wait(.1)
 end
 request('State');task.wait(.3)
 local won=state and (if trial then state.captures[C.guardians[k].id] else state.wins[tostring(k)])
 return record(k..(if trial then ':trial' else ':normal'),won==true,{seconds=os.clock()-start,health=h.Health})
end
for k=script:GetAttribute('StartKingdom') or 1,6 do
 for i=(if k==(script:GetAttribute('StartKingdom') or 1) then script:GetAttribute('StartRoute') or 0 else 0),48 do
  local q=C.route(k,i/48);local pos=Vector3.new(q.x,q.y+3,q.z)
  if i>0 and i%12==0 then
   local a=C.route(k,math.max(0,(i-1)/48));local b=C.route(k,math.min(1,(i+1)/48))
   pos+=Vector3.new(b.x-a.x,0,b.z-a.z).Unit*3
  end
  if not walk(pos,k..':route:'..i) then return end
  if i==0 or i==24 or i==42 then press(world.Checkpoints[k..':'..(if i==0 then 'entrance' elseif i==24 then 'recovery' else 'guardian')]) end
  if i==42 then
   if not (state and state.wins[tostring(k)]) and not fight(k,false) then return end
   if not (state and state.captures[C.guardians[k].id]) and not fight(k,true) then return end
   if not walk(world.Checkpoints[k..':guardian'].Position+Vector3.new(0,4,0),k..':return') then return end
   press(world.Checkpoints[k..':guardian'])
  end
 end
end
if not walk(Vector3.new(0,843,0),'summit') then return end
press(world.Interactions['Impossible Summit']);request('State');task.wait(.3)
record('summit-reward',state and state.discoveries.summit==true,{wins=state.wins,captures=state.captures})
workspace:SetAttribute('MountainQA_Acceptance',game.HttpService:JSONEncode({done=true,passed=state.discoveries.summit==true,log=log,elapsed=os.clock()-started,scope='Automated natural avatar movement and game actions; no progression/position/health injection. Includes Trials; not a direct-ascent human timing benchmark.'}))
