local Players=game:GetService('Players')
Players.CharacterAutoLoads=false
local RS=game:GetService('ReplicatedStorage')
local C=require(RS.MountainShared.Catalog)
local R=require(RS.MountainShared.Rules)
local P=require(script.Parent.Profiles)
local B=require(script.Parent.Combat)
local Competition=require(script.Parent.Competition)
local A=require(game.ServerStorage.MountainWorld.Art)
if not workspace:FindFirstChild('ImpossibleMountain') then require(game.ServerStorage.MountainWorld.World).build() end
local world=workspace.ImpossibleMountain
local remotes=Instance.new('Folder');remotes.Name='MountainRemotes';remotes.Parent=RS
local request=Instance.new('RemoteEvent');request.Name='Request';request.Parent=remotes
local event=Instance.new('RemoteEvent');event.Name='Event';event.Parent=remotes
local state={},{} -- forward state storage below
state={}
local busy={};local limits={};local companions={};local motion={};local recovering={}
local function send(player,kind,data) if player.Parent==Players then event:FireClient(player,kind,data) end end
local function root(player) return player.Character and player.Character:FindFirstChild('HumanoidRootPart') end
local function living(player) local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 end
local function nearby(player,p,range) local rr=root(player);return rr and living(player) and (rr.Position-p.Position).Magnitude<=range end
local function safe(player) local s=motion[player];return s and os.clock()>s.blockedUntil and living(player) end
local function teleport(player,pos)
 local rr=root(player);if not rr then return end
 player.Character:PivotTo(CFrame.new(pos));rr.AssemblyLinearVelocity=Vector3.zero
 motion[player]={pos=pos,time=os.clock(),blockedUntil=os.clock()+.5,fallTop=pos.Y}
end
local function checkpoint(p)
 return world.Checkpoints:FindFirstChild(p.checkpoint) or world.Checkpoints:FindFirstChild('1:entrance')
end
local function rebuildTeam(player)
 if companions[player] then companions[player]:Destroy() end
 local p=P.get(player);if not p then return end
 local f=Instance.new('Folder');f.Name='Team_'..player.UserId;f.Parent=world.Encounters;companions[player]=f
 for i,id in ipairs(p.team) do
  local c=R.find(p.creatures,id);if c then local m=A.creature(f,C.byId[c.species],Vector3.new(0,-100,0),if C.byId[c.species].rarity=='Legendary' then 1.2 else .65,R.stage(c.level));m:SetAttribute('Slot',i) end
 end
end
local function publish(player,visual)
 local p=P.get(player);if not p then return end
 local s=table.clone(p);s.serverNow=os.time();s.saveMode=P.mode;send(player,'state',s)
 if visual then rebuildTeam(player) end
end
B.init(P,send,function(player) publish(player,true) end)
local function loseCargo(player)
 local p=P.get(player);local rr=root(player);if not p then return end
 R.drop(p,os.time())
 if p.recovery then
  if recovering[player] then recovering[player]:Destroy() end
  local spot=checkpoint(p).Position+Vector3.new(6,2,0)
  local pack=A.part(world.Interactions,'Recoverable eggs • '..player.DisplayName,Vector3.new(3,3,3),CFrame.new(spot),Color3.fromRGB(249,192,117),Enum.Material.Wood)
  pack:SetAttribute('Kind','Recovery');pack:SetAttribute('Owner',player.UserId)
  local q=Instance.new('ProximityPrompt');q.ActionText='Recover eggs';q.MaxActivationDistance=10;q.HoldDuration=.4;q.Parent=pack
  recovering[player]=pack;send(player,'toast','Unsecured eggs recoverable beside your checkpoint for 3 minutes.')
 end
 publish(player)
end
local function onCharacter(player,character)
 local h=character:WaitForChild('Humanoid');local rr=character:WaitForChild('HumanoidRootPart');h.WalkSpeed=16;h.UseJumpPower=true;h.JumpPower=48;h.MaxHealth=140;h.Health=140
 local p=P.get(player);if not p then return end
 local pos=if p.checkpoint=='1:entrance' then Vector3.new(0,21,550) else checkpoint(p).Position+Vector3.new(0,5,0)
 teleport(player,pos);rebuildTeam(player)
 h.Died:Connect(function() loseCargo(player);B.remove(player);task.delay(3,function() if player.Parent==Players and P.get(player) then player:LoadCharacterAsync() end end) end)
end
local function join(player)
 local p,err=P.load(player)
 if not p then player:Kick('Safe load stopped: '..tostring(err)..' Please retry.');return end
 if player.Parent~=Players then P.save(player,true);return end
 R.settleIncome(p,os.time());player.CharacterAdded:Connect(function(c) onCharacter(player,c) end)
 player:LoadCharacterAsync();publish(player)
end
Players.PlayerAdded:Connect(function(player) task.spawn(join,player) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(player)
 B.remove(player);if companions[player] then companions[player]:Destroy() end;if recovering[player] then recovering[player]:Destroy() end
 P.save(player,true);state[player]=nil;busy[player]=nil;limits[player]=nil;motion[player]=nil;companions[player]=nil;recovering[player]=nil
end)
local rng=Random.new()
local function roll(k)
 local r=rng:NextNumber()*100;for i=1,6 do local s=C.species[(k-1)*6+i];r-=s.weight;if r<=0 then return s.id end end;return C.species[k*6].id
end
local function interact(player,part)
 local p=P.get(player);if not p or not safe(player) or not nearby(player,part,15) then return end
 local kind=part:GetAttribute('Kind');local k=part:GetAttribute('Kingdom') or 1;local id=part:GetAttribute('Id')
 if not R.canEnter(p,k) then send(player,'toast','Defeat the previous Guardian first.');return end
 if kind=='Checkpoint' then
  p.checkpoint=id;local n=R.extract(p);local first=not p.discoveries[id]
  p.discoveries[id]=true
  if first then for _,cid in ipairs(p.team) do local c=R.find(p.creatures,cid);if c then R.addXP(c,40*k) end end end
  send(player,'toast','Checkpoint saved • '..n..' eggs secured.');task.spawn(P.save,player,false)
 elseif kind=='Nest' then
  send(player,'toast',if R.collect(p,roll(k),id,os.time()) then 'Egg found • carry it to an extraction checkpoint.' else 'Nest resting or your three egg slots are full.')
 elseif kind=='Discovery' then
  if not p.discoveries[id] then p.discoveries[id]=true;p.resources[tostring(k)]=(p.resources[tostring(k)] or 0)+10;p.coins+=20
   for _,cid in ipairs(p.team) do local c=R.find(p.creatures,cid);if c then R.addXP(c,60*k) end end
   send(player,'toast','Landmark discovered • +10 '..C.kingdoms[k].resource)
  else send(player,'toast','Landmark recorded in your expedition journal.') end
 elseif kind=='Shortcut' then
  if p.shortcuts[id] then teleport(player,world.Checkpoints[k..':guardian'].Position+Vector3.new(0,5,0));send(player,'toast','Shortcut to the Guardian approach.')
  else p.shortcuts[id]=true;send(player,'toast','Shortcut attuned • use again to reach the Guardian approach.') end
 elseif kind=='Wild' then local _,msg=B.startWild(player,id,part);send(player,'toast',msg)
 elseif kind=='Guardian' or kind=='Trial' then
  local altar=world.Interactions:FindFirstChild(C.guardians[k].name);local center=Vector3.new(altar:GetAttribute('ArenaX'),altar:GetAttribute('ArenaY'),altar:GetAttribute('ArenaZ'))
  local ok,msg=B.start(player,k,kind=='Trial',center);if not ok then send(player,'toast',msg) end
 elseif kind=='Puzzle' then
  state[player]=state[player] or {};local s=state[player];s.puzzle=s.puzzle or {};s.puzzle[id]=(s.puzzle[id] or 0)+1
  if s.puzzle[id]>=3 then s.puzzle[id]=0;send(player,'toast',if R.collect(p,roll(k),id,os.time()) then 'Three runes aligned • egg discovered!' else 'Puzzle resting or cargo full.') else send(player,'toast','Rune '..s.puzzle[id]..' / 3 aligned. Rotate again.') end
 elseif kind=='Recovery' then
  if part:GetAttribute('Owner')==player.UserId and R.recover(p,os.time()) then part:Destroy();recovering[player]=nil;send(player,'toast','Eggs recovered • extract them now.') end
 elseif kind=='Summit' then
  if not p.wins['6'] then send(player,'toast','Caeloryn guards the final summit.');return end
  if not p.discoveries.summit then p.discoveries.summit=true;p.coins+=1000;p.trophies+=100 end
  send(player,'toast','IMPOSSIBLE MOUNTAIN CONQUERED • Sovereign Explorer!')
 elseif table.find({'Incubator','Sanctuary','Training','Competition'},kind) then
  R.extract(p);R.settleIncome(p,os.time());send(player,'open',kind)
 end
 publish(player,true)
end
game:GetService('ProximityPromptService').PromptTriggered:Connect(function(prompt,player)
 local part=prompt.Parent
 if not part or not part:IsA('BasePart') or not part:IsDescendantOf(world) or not part:GetAttribute('Kind') then return end
 local now=os.clock();if now<(limits[player] or 0) or busy[player] then return end
 limits[player]=now+.35;interact(player,part)
end)
local function atRefuge(player) local rr=root(player);return rr and (rr.Position-Vector3.new(0,17,560)).Magnitude<95 end
local function handle(player,action,data)
 local p=P.get(player);if not p then return end
 if action=='State' then publish(player);return end
 if not safe(player) then return end
 if action=='Special' then if type(data)=='table' then B.special(player,data.slot,data.ability) end
 elseif action=='Dodge' then if B.dodge(player) then send(player,'dodge',true) end
 elseif action=='Equip' then if R.equip(p,data) then rebuildTeam(player) end
 elseif action=='Incubate' or action=='Hatch' then
  if not atRefuge(player) or type(data)~='string' then send(player,'toast','Use the expedition refuge incubator.');return end
  local ok=if action=='Incubate' then R.incubate(p,data,os.time()) else R.hatch(p,data,os.time())
  send(player,'toast',if ok then (if action=='Hatch' then 'A new companion hatched!' else 'Incubation started • hatching is free.') else 'Not ready or all three incubators are occupied.');if ok then task.spawn(P.save,player,false) end
 elseif action=='Specialize' then if type(data)=='table' and R.specialize(p,data.id,data.choice) then send(player,'toast','Specialization selected.');rebuildTeam(player) end
 elseif action=='Train' then
  if not atRefuge(player) or type(data)~='string' then return end
  local c=R.find(p.creatures,data)
  if c and c.level<50 and p.coins>=15 then p.coins-=15;R.addXP(c,80);send(player,'toast','Training complete • +80 XP');rebuildTeam(player) end
 elseif action=='Travel' then
  if type(data)~='string' then return end
  local near=false
  for _,cp in ipairs(world.Checkpoints:GetChildren()) do if nearby(player,cp,20) then near=true;break end end
  if not near and not atRefuge(player) then send(player,'toast','Fast travel begins at a checkpoint or refuge.');return end
  if data=='refuge' then R.extract(p);teleport(player,Vector3.new(0,21,550))
  else local cp=world.Checkpoints:FindFirstChild(data)
   if cp and p.discoveries[data] and R.canEnter(p,cp:GetAttribute('Kingdom')) then R.extract(p);teleport(player,cp.Position+Vector3.new(0,5,0)) end
  end
 elseif action=='CollectIncome' then if atRefuge(player) then local n=R.settleIncome(p,os.time());send(player,'toast','Collected '..n..' sanctuary coins.') end
 elseif action=='RegisterDefense' then
  if not atRefuge(player) then return end
  send(player,'toast',if Competition.register(p,player.UserId) then 'Defense snapshot saved • others can challenge your UserId while you are offline.' else 'Defense save unavailable. Try again later.')
 elseif action=='ChallengeDefense' then
  if not atRefuge(player) then return end
  local ok,result=Competition.challenge(p,player.UserId,data)
  if ok then send(player,'competition',result);task.spawn(P.save,player,false) else send(player,'toast',result) end
 end
 publish(player)
end
request.OnServerEvent:Connect(function(player,action,data)
 if type(action)~='string' or #action>32 or busy[player] then return end
 local now=os.clock();if now<(limits[player] or 0) then return end;limits[player]=now+.12;busy[player]=true
 local ok,err=pcall(handle,player,action,data);busy[player]=nil
 if not ok then warn('Mountain request failed: '..tostring(err));send(player,'toast','Action unavailable. Your saved data is preserved.') end
end)
-- Server-only integration contract; no Phase 1 coordinate is guessed or written.
local gateway=Instance.new('BindableFunction');gateway.Name='MountainGateway';gateway.Parent=game.ServerStorage
gateway.OnInvoke=function(player) if P.get(player) then teleport(player,Vector3.new(0,21,550));return true end;return false end
local moving={}
for _,part in ipairs(world.Dynamics:GetChildren()) do if part:GetAttribute('Kind')=='Moving' then table.insert(moving,{part=part,origin=part.CFrame,last=part.CFrame}) end end
local combatTick,checkTick=0,0
game:GetService('RunService').Heartbeat:Connect(function(dt)
 local now=os.clock()
 for _,m in ipairs(moving) do
  local offset=(math.sin(now*.5)+1)*17
  local cf=m.origin+CFrame.new().Position+Vector3.new(m.part:GetAttribute('AxisX')*offset,0,m.part:GetAttribute('AxisZ')*offset)
  local delta=cf.Position-m.part.Position
  for _,player in ipairs(Players:GetPlayers()) do local rr=root(player)
   if rr and math.abs(rr.Position.X-m.part.Position.X)<7 and math.abs(rr.Position.Z-m.part.Position.Z)<7 and rr.Position.Y-m.part.Position.Y>0 and rr.Position.Y-m.part.Position.Y<6 then player.Character:PivotTo(player.Character:GetPivot()+delta) end
  end
  m.part.CFrame=cf
 end
 for player,f in pairs(companions) do local rr=root(player)
  if rr then for _,m in ipairs(f:GetChildren()) do
   local i=m:GetAttribute('Slot');local target=rr.CFrame*CFrame.new((i-2)*4, -1.8+math.sin(now*2+i)*.2,5)
   m:PivotTo(m:GetPivot():Lerp(target,.15))
  end end
 end
 combatTick+=dt;checkTick+=dt
 if combatTick>=1 then combatTick=0;B.tick() end
 if checkTick<.2 then return end;checkTick=0
 for _,player in ipairs(Players:GetPlayers()) do
  local p=P.get(player);local rr=root(player);local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  if p and rr and h and h.Health>0 then
   local m=motion[player]
   if m then
    local elapsed=now-m.time;local distance=(rr.Position-m.pos).Magnitude
    if distance>math.max(22,elapsed*75) and now>m.blockedUntil then teleport(player,m.pos);send(player,'toast','Movement corrected.');m=motion[player] end
    local ceiling=16+p.unlocked*136+6
    if rr.Position.Y>ceiling then teleport(player,checkpoint(p).Position+Vector3.new(0,5,0));send(player,'toast','Defeat the previous Guardian to enter this kingdom.');m=motion[player] end
    if h.FloorMaterial==Enum.Material.Air then m.fallTop=math.max(m.fallTop,rr.Position.Y)
    else
     if m.fallTop-rr.Position.Y>38 then loseCargo(player);teleport(player,checkpoint(p).Position+Vector3.new(0,5,0));m=motion[player] end
     m.fallTop=rr.Position.Y
    end
    if rr.Position.Y < -25 then loseCargo(player);teleport(player,checkpoint(p).Position+Vector3.new(0,5,0));m=motion[player] end
    m.pos=rr.Position;m.time=now
   end
   if p.recovery and os.time()>=p.recovery.expires then p.recovery=nil;if recovering[player] then recovering[player]:Destroy();recovering[player]=nil end;publish(player) end
   for _,hazard in ipairs(world.Dynamics:GetChildren()) do
    if hazard:GetAttribute('Kind')=='Hazard' then
     local active=math.floor(now/3)%2==0;hazard.Transparency=if active then .2 else .85
     if active and (rr.Position-hazard.Position).Magnitude<10 and now>(B.dodgeUntil[player] or 0) then h:TakeDamage(3) end
    end
   end
  end
 end
end)
task.spawn(function()
 while task.wait(45) do
  for player,s in pairs(P.sessions) do
   if not s.closing then task.spawn(function() local ok=P.save(player,false);send(player,'save',ok);if not ok then send(player,'toast','Saving paused. Progress actions are locked to protect your profile.') end end) end
  end
 end
end)
game:BindToClose(function()
 local remaining=0
 for player in pairs(P.sessions) do remaining+=1;task.spawn(function() P.save(player,true);remaining-=1 end) end
 local untilTime=os.clock()+25;while remaining>0 and os.clock()<untilTime do task.wait(.1) end
end)
print('Impossible Mountain ready • six kingdoms • isolated profile namespace')
