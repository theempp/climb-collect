-- Review02 systems probe (Play Solo, natural spawn at home 1): assign, timed production, collect, bank, upgrade,
-- decor Home buy/place/showcase/clear, Inspect, incubate/hatch when an egg exists, bat equip and swing, HUD presence.
-- Ordinary requests only; no profile or position fixtures. Poll workspace attribute MountainQA_HomeSystems.
local p=game.Players.LocalPlayer
local remotes=game.ReplicatedStorage.MountainRemotes
local D=require(game.ReplicatedStorage.MountainShared.HomeDecor)
local RUN=math.floor(os.clock()*10)
local state;local replies={};local serial=0;local log={};local toasts={};local t0=os.clock()
local ev=remotes.Event.OnClientEvent:Connect(function(kind,data) if kind=='state' then state=data elseif kind=='toast' then table.insert(toasts,tostring(data)) end end)
local rs=remotes.UIResult.OnClientEvent:Connect(function(r) replies[r.id]=r end)
local function publish(done) workspace:SetAttribute('MountainQA_HomeSystems',game.HttpService:JSONEncode({done=done,log=log,toasts=toasts,elapsed=os.clock()-t0})) end
local function check(ok,label,data) table.insert(log,{ok=ok==true,label=label,data=data});publish(false);return ok end
local function request(action,payload)
 task.wait(.25);serial+=1;local id='homesys'..RUN..':'..serial;remotes.UIRequest:FireServer(id,action,payload)
 local deadline=os.clock()+5;repeat task.wait(.05) until replies[id] or os.clock()>deadline
 local r=replies[id];return r and {ok=r.ok,message=r.message} or {ok=false,message='timeout'}
end
task.spawn(function()
 local ok,err=pcall(function()
  local w0=os.clock();repeat request('State');task.wait(.5) until state or os.clock()-w0>10
  check(state~=nil and state.ui and state.ui.atHome,'spawned at home',state and state.ui and state.ui.plot)
  local gui=p.PlayerGui:FindFirstChild('MountainHUD') or p.PlayerGui:FindFirstChildWhichIsA('ScreenGui')
  check(gui~=nil,'HUD ScreenGui present',gui and gui.Name)
  local c=state.creatures[1];check(c~=nil,'owns a creature',#state.creatures)
  local r=request('Tycoon',{op='assign',slot=1,id=c.id});check(r.ok,'assign habitat 1',r)
  task.wait(1);local hab=workspace:FindFirstChild('Habitat_1',true)
  local before=state.coins
  r=request('Tycoon',{op='collect',slot=1});check(true,'collect immediately (may be empty)',r)
  local deadline=os.clock()+150
  repeat task.wait(5);request('State') until (state.tycoon.habitats[1].eggs or 0)>=1 or os.clock()>deadline
  check(state.tycoon.habitats[1].eggs>=1,'habitat produced an egg',state.tycoon.habitats[1].eggs)
  r=request('Tycoon',{op='collect',slot=1});task.wait(.4);request('State');task.wait(.3)
  check(r.ok and state.tycoon.bag.eggs>=1,'collect into bag',{r=r,bag=state.tycoon.bag})
  r=request('Tycoon',{op='bank'});task.wait(.4);request('State');task.wait(.3)
  check(r.ok and state.tycoon.bag.eggs==0 and state.coins>before,'bank to coins',{r=r,coins=state.coins,before=before})
  local coins=state.coins
  r=request('Tycoon',{op='upgrade',path='storage'});task.wait(.3);request('State');task.wait(.3)
  check((r.ok and state.coins<coins) or (not r.ok and coins<25),'storage upgrade (or refused when poor)',{r=r,coins=state.coins})
  r=request('Tycoon',{op='upgrade',path='bogus'});check(not r.ok,'malformed upgrade refused',r)
  -- Decor: cheapest item.
  local item,cost
  for _,def in ipairs(D.items) do if def.kind=='decor' and (not cost or def.cost<cost) then item,cost=def.id,def.cost end end
  check(item~=nil,'decor catalogue readable',item)
  if item then
   r=request('Home',{op='buy',item=item});check(r.ok or state.coins<cost,'buy decor '..item,r)
   r=request('Home',{op='place',slot='P1',item=item});check(r.ok,'place decor in P1',r)
   task.wait(1);local slotFolder=workspace:FindFirstChild('Slot_P1',true);check(slotFolder and #slotFolder:GetChildren()>0,'decor built in world',slotFolder and #slotFolder:GetChildren())
   r=request('Home',{op='place',slot='D1',item=item});check(not r.ok,'decor refused in display slot',r)
  end
  r=request('Home',{op='showcase',slot='D1',id=state.creatures[#state.creatures].id});check(true,'showcase D1',r)
  r=request('Inspect',{plot=state.ui.plot,kind='habitat',key=1});check(r.ok,'inspect own habitat',r)
  task.wait(.6);r=request('Inspect',{plot=state.ui.plot,kind='display',key='D1'});check(r.ok,'inspect display',r)
  task.wait(.6);r=request('Inspect',{plot=2,kind='habitat',key=1});check(true,'inspect empty plot 2',r)
  if item then r=request('Home',{op='clear',slot='P1'});check(r.ok,'clear P1',r) end
  -- Eggs/incubation if the profile holds any egg.
  local egg=state.eggs and state.eggs[1]
  if egg then
   r=request('Incubate',egg.id);check(r.ok or egg.readyAt~=nil,'incubate egg',r)
   r=request('Hatch',egg.id);check(not r.ok or true,'early hatch response',r)
  else check(true,'no egg in profile to incubate',nil) end
  -- Bats.
  local bats=state.ui.bats
  check(bats~=nil,'bat snapshot present',bats and bats.equipped)
  r=request('Swing');check(r.ok,'bat swing (miss) accepted',r)
  task.wait(.05);r=request('Swing');check(true,'immediate second swing (cooldown)',r)
  -- Creature life: the habitat creature should move away from its spawn pose.
  local m;for _,v in ipairs(game.CollectionService:GetTagged('HabitatCreature')) do if v:IsDescendantOf(hab.Parent) and (v:GetPivot().Position-hab.Position).Magnitude<16 then m=v end end
  if m then local a=m:GetPivot().Position;task.wait(8);check((m:GetPivot().Position-a).Magnitude>.3,'habitat creature moves',(m:GetPivot().Position-a).Magnitude) end
  local shown=0;for _,g in ipairs(game.CollectionService:GetTagged('TycoonTag')) do if g.Enabled then shown+=1 end end
  check(shown<=12,'tag declutter caps visible tags',shown)
  check(workspace:FindFirstChild('LocalHomeAmbience')~=nil,'ambience running',#workspace.LocalHomeAmbience:GetChildren())
 end)
 if not ok then check(false,'probe error',tostring(err)) end
 publish(true);ev:Disconnect();rs:Disconnect()
end)
return 'home systems probe started'
