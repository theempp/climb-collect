local Players=game:GetService('Players')
Players.CharacterAutoLoads=false
local RS=game:GetService('ReplicatedStorage')
local C=require(RS.MountainShared.Catalog)
local R=require(RS.MountainShared.Rules)
local P=require(script.Parent.Profiles)
local B=require(script.Parent.Combat)
local UIRequests=require(script.Parent.UIRequests)
local UIProtocol=require(RS.MountainShared.UIProtocol)
local BatRules=require(RS.MountainShared.BatRules)
local EggOdds=require(RS.MountainShared.EggOdds)
local Explorer=require(RS.MountainShared.ExplorerRules)
local ShopRules=require(RS.MountainShared.ShopRules)
local A=require(game.ServerStorage.MountainWorld.Art)
if not workspace:FindFirstChild('ImpossibleMountain') then require(game.ServerStorage.MountainWorld.FreeClimb).build() end
local world=workspace.ImpossibleMountain
require(game.ServerStorage.MountainWorld.HomePromenade).apply(workspace:FindFirstChild('Sanctuary'),world)
require(game.ServerStorage.MountainWorld.MountainEntrances).apply(world,workspace:FindFirstChild('Sanctuary'))
-- Exit volumes are final once both frontage passes above have run; the HUD draws the safe-return line from them.
local exitBoxes={}
do local folder=world:FindFirstChild('SanctuaryExits');if folder then for _,v in ipairs(folder:GetChildren()) do if v:IsA('BasePart') then table.insert(exitBoxes,{cframe=v.CFrame,size=v.Size}) end end end end
-- Server section: the GuardianBounds box holding the position, nil outside every box.
local function sectionOf(position)
 local bounds=world:FindFirstChild('GuardianBounds');if not bounds then return nil end
 for k=1,6 do
  local box=bounds:FindFirstChild(tostring(k))
  if box then local q=box.CFrame:PointToObjectSpace(position);if math.abs(q.X)<=box.Size.X/2 and math.abs(q.Y)<=box.Size.Y/2 and math.abs(q.Z)<=box.Size.Z/2 then return k end end
 end
 return nil
end
local home=require(script.Parent.Sanctuary).new(workspace:FindFirstChild('Sanctuary'))
local tycoonWorld=require(script.Parent.TycoonWorld).new(home)
local areas={}
local Journey=require(script.Parent.Journey)
if not world:GetAttribute('FreeClimbVersion') then
 require(game.ServerStorage.MountainWorld.Polish).apply(world)
 require(game.ServerStorage.MountainWorld.TraversalArt).apply(world)
 require(script.Parent.Traversal).start(world)
end
local remotes=Instance.new('Folder');remotes.Name='MountainRemotes';remotes.Parent=RS
local request=Instance.new('RemoteEvent');request.Name='Request';request.Parent=remotes
local event=Instance.new('RemoteEvent');event.Name='Event';event.Parent=remotes
local uiRequest=Instance.new('RemoteEvent');uiRequest.Name='UIRequest';uiRequest.Parent=remotes
local uiResult=Instance.new('RemoteEvent');uiResult.Name='UIResult';uiResult.Parent=remotes
local sprintRequest=Instance.new('RemoteEvent');sprintRequest.Name='SprintRequest';sprintRequest.Parent=remotes
local movement=require(script.Parent.Movement).new(sprintRequest)
local uiService
local raids,guardians,carryVisuals,raidHazards,bats
local raidEggs={}
local state={}
local contextSnapshots={}
local busy={};local limits={};local companions={};local motion={};local recovering={}
local respawns={}
local function send(player,kind,data) if player.Parent==Players then event:FireClient(player,kind,data) end end
-- Typed HUD signals ride the same remote; every existing toast still fires beside them.
local function hud(player,kind,data) data=data or {};data.kind=kind;data.at=workspace:GetServerTimeNow();send(player,'hud',data) end
local function root(player) return player.Character and player.Character:FindFirstChild('HumanoidRootPart') end
local function living(player) local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 end
local function nearby(player,p,range) local rr=root(player);return rr and living(player) and (rr.Position-p.Position).Magnitude<=range end
local function safe(player) local s=motion[player];return s and os.clock()>s.blockedUntil and living(player) end
local function teleport(player,pos)
 local rr=root(player);if not rr or not living(player) then return false end
 local cf=if typeof(pos)=='CFrame' then pos else CFrame.new(pos)
 player.Character:PivotTo(cf);rr.AssemblyLinearVelocity=Vector3.zero;rr.AssemblyAngularVelocity=Vector3.zero
 pos=cf.Position
 motion[player]={pos=pos,time=os.clock(),blockedUntil=os.clock()+.5,fallTop=pos.Y}
 return true
end
local function checkpoint(p)
 return world.Checkpoints:FindFirstChild(p.checkpoint) or world.Checkpoints:FindFirstChild('1:entrance')
end
local function rebuildTeam(player)
 if companions[player] then companions[player]:Destroy() end
 local p=P.get(player);if not p then return end
 local f=Instance.new('Folder');f.Name='Team_'..player.UserId;f.Parent=world.Encounters;companions[player]=f
 -- Q8: followers and MaxHealth come from the battle team only; Robux creatures never follow.
 for i,c in ipairs(R.battleTeam(p)) do
  local m=A.creature(nil,C.byId[c.species],Vector3.new(0,-100,0),if C.byId[c.species].rarity=='Legendary' then 1.2 else .65,R.stage(c.level))
  -- Three companions per player: keep their anchored cosmetic parts available at upper camps.
  m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent;m:SetAttribute('Slot',i);m:SetAttribute('Species',c.species);m.Parent=f
 end
 local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if h then local total=0;for _,c in ipairs(R.battleTeam(p)) do total+=R.stats(c).health end;h.MaxHealth=140+total*.15;h.Health=math.min(h.Health,h.MaxHealth) end
end
local function atHome(player) local rr=root(player);return rr~=nil and home.ownsPosition(player,rr.Position) end
local function atRefuge(player) local rr=root(player);return rr~=nil and (home.ownsPosition(player,rr.Position) or (rr.Position-Vector3.new(0,17,560)).Magnitude<95) end
local function inBattle(player)
 if B.wild[player] then return true end
 for _,battle in pairs(B.battles) do if battle.members[player] then return true end end
 return false
end
local function nearCheckpoint(player)
 local p=P.get(player);if not p then return false end
 for _,cp in ipairs(world.Checkpoints:GetChildren()) do if p.discoveries[cp.Name] and R.canEnter(p,cp:GetAttribute('Kingdom')) and nearby(player,cp,20) then return true end end
 local summit=world.Interactions:FindFirstChild('Impossible Summit')
 return p~=nil and p.discoveries.summit==true and summit~=nil and nearby(player,summit,25) or false
end
local function nearestEgg(player)
 local rr=root(player);if not rr then return nil end
 local nearest,best=nil,12
 for id,egg in pairs(raidEggs) do local distance=(rr.Position-egg.position).Magnitude;if distance<best then nearest=id;best=distance end end
 return nearest
end
local function publish(player,visual)
 local p=P.get(player);if not p then return end
 for _,id in ipairs(BatRules.grantUnlocks(p)) do send(player,'toast','Index set complete! '..BatRules.byId[id].name..' unlocked.') end
 local s=table.clone(p);s.serverNow=os.time();s.saveMode=P.mode
 local serverClock=workspace:GetServerTimeNow();local cooldowns,dodgeReadyAt=B.cooldowns(player,serverClock)
 tycoonWorld.update(player,p)
 -- false (not nil) outside every section, so a context merge on the client clears the previous one.
 local rr=root(player);local section=rr and sectionOf(rr.Position) or false
 s.ui={nearestEgg=nearestEgg(player),atHome=atHome(player),sanctuaryConnected=true,plot=home.plot(player),inSanctuary=root(player)~=nil and home.inSanctuary(root(player).Position),atRefuge=atRefuge(player),nearCheckpoint=nearCheckpoint(player),serverClock=serverClock,cooldowns=cooldowns,dodgeReadyAt=dodgeReadyAt,settings=UIProtocol.settings(nil,p.settings),bats=if bats then bats.snapshot(p) else nil,section=section,exits=exitBoxes,explorer=Explorer.summary(p)}
 send(player,'state',s)
 if visual then rebuildTeam(player) end
end
B.init(P,send,function(player) publish(player,true) end,hud)
local function restoreRecovery(player)
 local p=P.get(player);if not p then return end
 if p.recovery and p.recovery.expires<=os.time() then p.recovery=nil end
 if p.recovery then
  if recovering[player] then recovering[player]:Destroy() end
  local spot=checkpoint(p).Position+Vector3.new(6,2,0)
  local pack=A.part(world.Interactions,'Recoverable eggs • '..player.DisplayName,Vector3.new(3,3,3),CFrame.new(spot),Color3.fromRGB(249,192,117),Enum.Material.Wood)
  pack:SetAttribute('Kind','Recovery');pack:SetAttribute('Owner',player.UserId)
  local q=Instance.new('ProximityPrompt');q.ActionText='Recover eggs';q.MaxActivationDistance=10;q.HoldDuration=.4;q.Parent=pack
  recovering[player]=pack;send(player,'toast','Unsecured eggs recoverable beside your checkpoint for 3 minutes.')
 end
end
local function loseCargo(player)
 if raids then raids.forfeit(player,'fall') end
 local p=P.get(player);if not p then return end
 R.drop(p,os.time());restoreRecovery(player);publish(player)
end
local loadCharacter
local function onCharacter(player,character)
 local h=character:WaitForChild('Humanoid');local rr=character:WaitForChild('HumanoidRootPart');h.WalkSpeed=16;h.UseJumpPower=true;h.JumpPower=48;h.MaxHealth=140;h.Health=140
 movement.bind(player,character)
 local p=P.get(player);if not p then return end
 local pos=if areas[player]=='sanctuary' then home.spawn(player) else checkpoint(p).Position+Vector3.new(0,5,0)
 if not pos then player:Kick('Sanctuary slot unavailable. Please rejoin.');return end
 teleport(player,pos);rebuildTeam(player);if bats then bats.equip(player) end
 h.Died:Connect(function() loseCargo(player);if carryVisuals then carryVisuals.clear(player) end;B.remove(player);if guardians then guardians.remove(player,'death') end;respawns[player]=os.clock()+3 end)
end
loadCharacter=function(player)
 player:LoadCharacterAsync()
 -- CharacterAdded fires before Roblox finishes placing the character at its engine spawn.
 if player.Parent==Players and player.Character and P.get(player) then onCharacter(player,player.Character) end
end
local function join(player)
 if not home.reserve(player) then player:Kick('All eight sanctuary plots are occupied. Please join another server.');return end
 areas[player]='sanctuary'
 local p,err=P.load(player)
 if not p then home.release(player);areas[player]=nil;player:Kick('Safe load stopped: '..tostring(err)..' Please retry.');return end
 if player.Parent~=Players then home.release(player);areas[player]=nil;P.save(player,true);return end
 R.settleIncome(p,os.time())
 loadCharacter(player);restoreRecovery(player);publish(player)
end
Players.PlayerAdded:Connect(function(player) task.spawn(join,player) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(player)
 movement.clear(player);if bats then bats.remove(player) end
 if raids then raids.remove(player) end;if guardians then guardians.remove(player,'leave') end;if raidHazards then raidHazards.remove(player) end;if carryVisuals then carryVisuals.clear(player) end
 tycoonWorld.clear(home.plot(player));home.release(player);areas[player]=nil
 B.remove(player,true);if companions[player] then companions[player]:Destroy() end;if recovering[player] then recovering[player]:Destroy() end
 contextSnapshots[player]=nil;respawns[player]=nil;if uiService then uiService.remove(player) end
 P.save(player,true);state[player]=nil;busy[player]=nil;limits[player]=nil;motion[player]=nil;companions[player]=nil;recovering[player]=nil
end)
local rng=Random.new()
local function roll(k) return EggOdds.pick(k,rng:NextNumber()*100) end
carryVisuals=require(script.Parent.CarryVisuals).new(world,send,hud)
for _,part in ipairs(world.Interactions:GetChildren()) do
 if part:GetAttribute('Kind')=='Nest' then
  local id=part:GetAttribute('Id');local egg={id=id,section=part:GetAttribute('Kingdom'),position=part.Position,part=part}
  -- Studio-only review aid: the first Blossom nest always holds the finished sample offspring. Live servers roll normally.
  if require(game.ReplicatedStorage.MountainShared.BuildFlags).studioAids() and id=='raid:1:1' then egg.species='mossbun' end
  raidEggs[id]=egg;carryVisuals.shell(egg);part.Transparency=1
  local prompt=part:FindFirstChildOfClass('ProximityPrompt');if prompt then prompt.ActionText='Strike egg';prompt.HoldDuration=0 end
 end
end
raids=require(script.Parent.EggRaids).new({profiles=P,clock=os.clock,guid=function() return game:GetService('HttpService'):GenerateGUID(false) end,
 eggs=raidEggs,roll=roll,alive=living,inBattle=inBattle,spawn=task.spawn,hud=hud,
 near=function(player,egg,range) local rr=root(player);return rr and safe(player) and (rr.Position-egg.position).Magnitude<=range end,
 atExit=function(player)
  local rr=root(player);local exits=world:FindFirstChild('SanctuaryExits');if not rr or not exits then return false end
  for _,v in ipairs(exits:GetChildren()) do local q=v.CFrame:PointToObjectSpace(rr.Position);if math.abs(q.X)<=v.Size.X/2 and math.abs(q.Y)<=v.Size.Y/2 and math.abs(q.Z)<=v.Size.Z/2 then return true end end
  return false
 end,
 alert=function(k,userId,eggId,now) if guardians then guardians.alert(k,userId,eggId,now) end end,
 changed=publish,present=function(player,data) if data.kind=='securing' then areas[player]='sanctuary' end;carryVisuals.show(player,data) end})
local guardianHeights={}
for k=1,6 do
 local m=world.Encounters:FindFirstChild('Guardian_'..k)
 if m and m.PrimaryPart then local cf,size=m:GetBoundingBox();guardianHeights[k]=m.PrimaryPart.Position.Y-cf.Position.Y+size.Y/2 end
end
local groundParams=RaycastParams.new();groundParams.FilterType=Enum.RaycastFilterType.Exclude
local ignore={world.Encounters,world.RaidPresentation,world.Interactions,world.Checkpoints};groundParams.FilterDescendantsInstances=ignore
local function guardianInside(k,position)
 local bounds=world:FindFirstChild('GuardianBounds');local box=bounds and bounds:FindFirstChild(tostring(k))
 if box then local q=box.CFrame:PointToObjectSpace(position);return math.abs(q.X)<=box.Size.X/2 and math.abs(q.Y)<=box.Size.Y/2 and math.abs(q.Z)<=box.Size.Z/2 end
 return position.Y>16+(k-1)*136-35 and position.Y<16+k*136+30 and not home.inSanctuary(position)
end
guardians=require(script.Parent.Guardians).new({world=world,clock=os.clock,players=function() return Players:GetPlayers() end,root=root,profile=P.get,alive=living,
 protected=raids.protected,inside=guardianInside,rootHeight=function(k) return guardianHeights[k] or 12 end,
 ground=function(pos,k)
  local hit=workspace:Raycast(pos+Vector3.new(0,30,0),Vector3.new(0,-95,0),groundParams)
  return hit and hit.Position
 end,
 warning=function(userId,k,eggId) local player=Players:GetPlayerByUserId(userId);if player then send(player,'toast',C.guardians[k].name..' heard your strike! Watch its approach.')
  hud(player,'alert',{guardian=C.guardians[k].name,guardianId=C.guardians[k].id,section=k,sectionName=C.kingdoms[k].name,eggId=eggId}) end end,
 calm=function(userId,k,reason) local player=Players:GetPlayerByUserId(userId);if player then hud(player,'calm',{guardianId=C.guardians[k].id,section=k,reason=reason}) end end,
 catch=function(player,k)
  if raids.protected(player) or os.clock()<(B.dodgeUntil[player] or 0) then return end
  local p=P.get(player);local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  if p and p.run then raids.forfeit(player,'catch');teleport(player,checkpoint(p).Position+Vector3.new(0,5,0));guardians.remove(player,'catch')
  elseif h then h:TakeDamage(14+k*4) end
 end})
B.connectRaids({guardians=guardians,raids=raids,manifest=function(k,center)
 local m=A.creature(world.Encounters,C.guardians[k],center+Vector3.new(0,1,0),3.2,1);m.Name='TrialManifestation_'..k
 for _,v in ipairs(m:GetDescendants()) do if v:IsA('BasePart') then v.Transparency=.38;v.Material=Enum.Material.Neon end end
 return m
end})
bats=require(script.Parent.Bats).new({profile=P.get,root=root,alive=living,clock=os.clock,players=function() return Players:GetPlayers() end,
 guid=function() return game:GetService('HttpService'):GenerateGUID(false) end,raids=raids,protected=raids.protected,folder=world.Interactions,
 safeZone=function(player)
  local rr=root(player);if not rr then return true end
  if home.inSanctuary(rr.Position) then return true end
  for _,cp in ipairs(world.Checkpoints:GetChildren()) do if (cp.Position-rr.Position).Magnitude<=BatRules.checkpointRadius then return true end end
  return false
 end,
 knock=function(target,velocity,stun)
  local m=motion[target];if m then m.blockedUntil=os.clock()+stun+.6 end
  send(target,'knock',{velocity=velocity,stun=stun})
 end,
 notify=function(player,text) send(player,'toast',text) end,hud=hud,
 creatureModel=function(_,species,position) local def=C.byId[species];return def and A.creature(nil,def,position,.65,1) end})
raidHazards=require(script.Parent.RaidHazards).new({world=world,players=function() return Players:GetPlayers() end,root=root,
 alive=function(player) local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 and h end,
 protected=raids.protected,inSanctuary=home.inSanctuary,dodging=function(player,now) return now<(B.dodgeUntil[player] or 0) end})
local function interact(player,part)
 local p=P.get(player);if not p or not safe(player) or not nearby(player,part,15) then return end
 local kind=part:GetAttribute('Kind');local k=part:GetAttribute('Kingdom') or 1;local id=part:GetAttribute('Id')
 if not R.canEnter(p,k) then send(player,'toast','Defeat the previous Guardian first.');return end
 if kind=='Checkpoint' then
  p.checkpoint=id;local first=not p.discoveries[id];local before=Explorer.xp(p)
  p.discoveries[id]=true
  local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then h.Health=h.MaxHealth end
  if first then for _,c in ipairs(R.battleTeam(p)) do R.addXP(c,40*k) end end
  -- Rest-point player XP is derived from discoveries; the event only names its source.
  local gained=Explorer.xp(p)-before;if gained>0 then hud(player,'xp',{amount=gained,source='rest',level=Explorer.summary(p).level}) end
  send(player,'toast','Rest point saved. Unsecured creatures still need the sanctuary exit.');task.spawn(P.save,player,false)
 elseif kind=='Nest' then
  local ok,reason
  if p.run and p.run.eggId==id and p.run.phase=='revealed' then ok,reason=raids.pickup(player,p.run.id) else ok,reason=raids.strike(player,id) end
  if not ok then send(player,'toast',if reason=='reserved' then 'Another climber is breaking this egg.' else 'Move closer or finish your current creature run.') end
 elseif kind=='Discovery' then
  if not p.discoveries[id] then p.discoveries[id]=true;p.resources[tostring(k)]=(p.resources[tostring(k)] or 0)+10;p.coins+=20
   for _,c in ipairs(R.battleTeam(p)) do R.addXP(c,60*k) end
   send(player,'toast','Landmark discovered • +10 '..C.kingdoms[k].resource)
  else send(player,'toast','Landmark recorded in your expedition journal.') end
 elseif kind=='Shortcut' then
  if p.run then send(player,'toast','Use the map to confirm abandoning your unsecured creature before travel.');return end
  if p.shortcuts[id] then teleport(player,world.Checkpoints[k..':guardian'].Position+Vector3.new(0,5,0));send(player,'toast','Shortcut to the Guardian approach.')
  else p.shortcuts[id]=true;send(player,'toast','Shortcut attuned • use again to reach the Guardian approach.') end
 elseif kind=='Wild' then send(player,'toast','Discover companions by breaking a guarded egg.')
 elseif kind=='Guardian' or kind=='Trial' then
  local center=Vector3.new(part:GetAttribute('ArenaX'),part:GetAttribute('ArenaY'),part:GetAttribute('ArenaZ'))
  local ok,msg=B.start(player,k,kind=='Trial',center);if not ok then send(player,'toast',msg) end
 elseif kind=='Puzzle' then
  state[player]=state[player] or {};local s=state[player];s.puzzle=s.puzzle or {};s.puzzle[id]=(s.puzzle[id] or 0)+1
  local rune=math.floor(workspace:GetServerTimeNow()/2)%3+1
  if rune~=s.puzzle[id] then s.puzzle[id]=0;send(player,'toast','Align runes in order: I → II → III. Wait for the matching rune.');return end
  if s.puzzle[id]>=3 then s.puzzle[id]=0;send(player,'toast','Three runes aligned. Find a guarded egg to discover a companion.') else send(player,'toast','Rune '..s.puzzle[id]..' / 3 aligned. Rotate again.') end
 elseif kind=='DroppedCreature' then
  local ok,reason=bats.grab(player,id)
  if not ok then send(player,'toast',if reason=='full_hands' then 'Your hands are full: secure your creature first.' else 'Too late — it slipped away.') end
 elseif kind=='Recovery' then
  if part:GetAttribute('Owner')==player.UserId and R.recover(p,os.time()) then part:Destroy();recovering[player]=nil;send(player,'toast','Eggs recovered • extract them now.') end
 elseif kind=='Summit' then
  if not p.discoveries.summit then p.discoveries.summit=true;p.coins+=1000 end
  send(player,'toast','IMPOSSIBLE MOUNTAIN CONQUERED • Sovereign Explorer!')
 elseif table.find({'Incubator','Sanctuary','Training'},kind) then
  R.settleIncome(p,os.time());send(player,'open',kind)
 end
 publish(player,true)
end
game:GetService('ProximityPromptService').PromptTriggered:Connect(function(prompt,player)
 local part=prompt.Parent
 if not part or not part:IsA('BasePart') or not part:IsDescendantOf(world) or not part:GetAttribute('Kind') then return end
 local now=os.clock();if now<(limits[player] or 0) or busy[player] then return end
 limits[player]=now+.35;interact(player,part)
end)
local journey=Journey.new({profile=P.get,ready=function(player) return safe(player) and not inBattle(player) end,
 origin=function(player,destination)
  local rr=root(player)
  if destination=='blossom' then return rr~=nil and home.nearGate(rr.Position) end
  return atRefuge(player) or nearCheckpoint(player)
 end,
 resolve=function(player,destination)
  if destination=='refuge' then local cf=home.spawn(player);return cf and {cf=cf,area='sanctuary'} end
  if destination=='blossom' then return {cf=world.Checkpoints['1:entrance'].CFrame+Vector3.new(0,5,0),area='mountain'} end
  local p=P.get(player);local cp=world.Checkpoints:FindFirstChild(destination)
  if not p or not cp or not p.discoveries[destination] or not R.canEnter(p,cp:GetAttribute('Kingdom')) then return nil end
  return {cf=cp.CFrame+Vector3.new(0,5,0),area='mountain'}
 end,
 move=function(player,target) return teleport(player,target.cf) end,extract=R.extract,forfeit=raids.forfeit,
 arrived=function(player,target) areas[player]=target.area end,
})
game:GetService('ProximityPromptService').PromptTriggered:Connect(function(prompt,player)
 local rr=root(player);local p=P.get(player)
 if not rr or not p or not safe(player) or busy[player] then return end
 local part=prompt.Parent;if not part or not part:IsA('BasePart') then return end
 local kind=home.prompt(part,player,rr.Position);if not kind then return end
 local now=os.clock();if now<(limits[player] or 0) then return end;limits[player]=now+.35
 if kind=='Gate' then
  local ok=journey.go(player,'blossom');send(player,'toast',if ok then 'Welcome to Blossom Gardens.' else 'Travel unavailable. Finish your encounter and try again.')
 else send(player,'open',kind) end
 publish(player)
end)
local dispatch=UIRequests.actions({profiles=P,rules=R,combat=B,clock=os.time,
 safe=safe,atHome=atHome,atRefuge=atRefuge,nearCheckpoint=nearCheckpoint,publish=publish,rebuildTeam=rebuildTeam,send=send,
 save=function(player) task.spawn(function() local saved=P.save(player,false);send(player,'save',saved) end) end,
 travel=journey.go,raids=raids,putDown=carryVisuals.clear,
 bats=bats,batRules=BatRules,equipBat=function(player) bats.equip(player) end,batSnapshot=function(p) return bats.snapshot(p) end,
 shop=ShopRules,rollOdds=function() return rng:NextNumber()*100 end,inBattle=inBattle,inSanctuary=function(player) local rr=root(player);return rr~=nil and home.inSanctuary(rr.Position) end,
})
local function handle(player,action,data,correlated)
 local ok,message,result=dispatch(player,action,data)
 if action=='Settings' then send(player,'save',ok) end
 if action~='State' then
  if not correlated and action~='Swing' and (action~='Special' and action~='Dodge' or not ok) then send(player,'toast',message) end
  if action=='Swing' and message then send(player,'toast',message) end
  publish(player)
 end
 return ok,message,result
end
uiService=UIRequests.new({handle=function(player,action,data) return handle(player,action,data,true) end,available=function(player) return P.get(player)~=nil end,
 busy=function(player) return busy[player]==true end,
 setBusy=function(player,value) busy[player]=if value then true else nil end,
 failed=function(err) warn('Mountain UI request failed: '..tostring(err)) end,
})
uiRequest.OnServerEvent:Connect(function(player,id,action,data)
 local result=uiService.process(player,id,action,data)
 if result and player.Parent==Players then uiResult:FireClient(player,result) end
end)
-- The original remote remains supported, with the same rules and honest errors.
request.OnServerEvent:Connect(function(player,action,data)
 if not UIProtocol.validate('legacy:1',action,data) or busy[player] then return end
 local now=os.clock();if now<(limits[player] or 0) then return end;limits[player]=now+.12;busy[player]=true
 local ok,err=pcall(handle,player,action,data);busy[player]=nil
 if not ok then warn('Mountain request failed: '..tostring(err));send(player,'toast','Action unavailable. Your saved data is preserved.') end
end)
-- Server-only integration contract; no Phase 1 coordinate is guessed or written.
local gateway=Instance.new('BindableFunction');gateway.Name='MountainGateway';gateway.Parent=game.ServerStorage
gateway.OnInvoke=function(player) return journey.go(player,'blossom') end
local moving={}
for _,part in ipairs(world.Dynamics:GetChildren()) do if part:GetAttribute('Kind')=='Moving' then
 local decorations={};for _,child in ipairs(part:GetChildren()) do if child:IsA('BasePart') then table.insert(decorations,{part=child,offset=part.CFrame:ToObjectSpace(child.CFrame)}) end end
 table.insert(moving,{part=part,origin=part.CFrame,decorations=decorations})
end end
local combatTick,checkTick,contextTick=0,0,0
game:GetService('RunService').Heartbeat:Connect(function(dt)
 local now=os.clock()
 carryVisuals.tick();raids.tick(now);bats.tick(now);guardians.tick(now);raidHazards.tick(now)
 for _,m in ipairs(moving) do
  local offset=(math.sin(now*.5)+1)*17
  local k=m.part:GetAttribute('Kingdom')
  local cf=m.origin+Vector3.new(m.part:GetAttribute('AxisX')*offset,if k==4 or k==6 then math.sin(now*.5)*5 else 0,m.part:GetAttribute('AxisZ')*offset)
  if k==4 then cf*=CFrame.Angles(0,math.sin(now*.5)*.25,0) end
  -- Let character physics carry riders while preserving client-owned walking/jumping.
  -- Velocity is the derivative of the anchored platform's sinusoidal trajectory.
  m.part.CFrame=cf
  local speed=8.5*math.cos(now*.5)
  m.part.AssemblyLinearVelocity=Vector3.new(m.part:GetAttribute('AxisX')*speed,if k==4 or k==6 then 2.5*math.cos(now*.5) else 0,m.part:GetAttribute('AxisZ')*speed)
  m.part.AssemblyAngularVelocity=if k==4 then Vector3.new(0,.125*math.cos(now*.5),0) else Vector3.zero
   for _,d in ipairs(m.decorations) do d.part.CFrame=cf*d.offset end
 end
 for player,f in pairs(companions) do local rr=root(player)
  if rr then for _,m in ipairs(f:GetChildren()) do
   local i=m:GetAttribute('Slot');local target=rr.CFrame*CFrame.new((i-2)*4, -1.8+math.sin(now*2+i)*.2,5)
   m.PrimaryPart.CFrame=m.PrimaryPart.CFrame:Lerp(target,1-math.exp(-10*dt))
  end end
 end
 combatTick+=dt;checkTick+=dt;contextTick+=dt
 local contextDue=contextTick>=.5;if contextDue then contextTick=0 end
 if combatTick>=1 then combatTick=0;B.tick() end
 if checkTick<.2 then return end;checkTick=0
 for _,player in ipairs(Players:GetPlayers()) do
  movement.update(player)
  local p=P.get(player);local rr=root(player);local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
  if p and respawns[player] and now>=respawns[player] then respawns[player]=nil;task.spawn(loadCharacter,player) end
  if p and contextDue then
   local refuge,near=atRefuge(player),nearCheckpoint(player);local previous=contextSnapshots[player];local section=rr and sectionOf(rr.Position) or false
   if not previous or previous.atHome~=atHome(player) or previous.atRefuge~=refuge or previous.nearCheckpoint~=near or previous.inSanctuary~=(rr~=nil and home.inSanctuary(rr.Position)) or previous.nearestEgg~=nearestEgg(player) or previous.section~=section then
    local context={nearestEgg=nearestEgg(player),atHome=atHome(player),sanctuaryConnected=true,plot=home.plot(player),inSanctuary=rr~=nil and home.inSanctuary(rr.Position),atRefuge=refuge,nearCheckpoint=near,serverClock=workspace:GetServerTimeNow(),section=section,exits=exitBoxes};contextSnapshots[player]=context;send(player,'context',context)
   end
  end
  -- C13: movement correction keys on the session, so a pending save (P.get nil) never suspends it; fall, void and exit checks need p.
  if P.sessions[player] and rr and h and h.Health>0 then
   local m=motion[player]
   if m then
    local elapsed=now-m.time;local distance=(rr.Position-m.pos).Magnitude
    if distance>math.max(22,elapsed*75) and now>m.blockedUntil then teleport(player,m.pos);send(player,'toast','Movement corrected.');m=motion[player] end
    if h.FloorMaterial==Enum.Material.Air then m.fallTop=math.max(m.fallTop,rr.Position.Y)
    else
     if p and m.fallTop-rr.Position.Y>require(RS.MountainShared.RaidConfig).seriousFall and not raids.protected(player) then loseCargo(player);teleport(player,if areas[player]=='sanctuary' then home.spawn(player) else checkpoint(p).Position+Vector3.new(0,5,0));m=motion[player] end
     m.fallTop=rr.Position.Y
    end
    if p and rr.Position.Y < -25 then loseCargo(player);teleport(player,if areas[player]=='sanctuary' then home.spawn(player) else checkpoint(p).Position+Vector3.new(0,5,0));m=motion[player] end
    m.pos=rr.Position;m.time=now
    if home.inSanctuary(rr.Position) then areas[player]='sanctuary' elseif world:GetAttribute('FreeClimbVersion') then areas[player]='mountain' end
    if p and p.run and p.run.phase=='carried' and not raids.protected(player) then task.spawn(raids.exit,player,p.run.id) end
   end
  end
  if p and rr and h and h.Health>0 then
   if p.recovery and os.time()>=p.recovery.expires then p.recovery=nil;if recovering[player] then recovering[player]:Destroy();recovering[player]=nil end;publish(player) end
   for _,hazard in ipairs(world.Dynamics:GetChildren()) do
    if hazard:GetAttribute('Kind')=='Hazard' then
     local active=math.floor(now/3)%2==0;hazard.Transparency=if active then .2 else .85
     if active and (rr.Position-hazard.Position).Magnitude<10 and now>(B.dodgeUntil[player] or 0) then h:TakeDamage(3) end
    elseif hazard:GetAttribute('Kind')=='Crumbling' then
     local crumbled=math.floor(now/4)%3==0;hazard.CanCollide=not crumbled;hazard.Transparency=if crumbled then .9 else 0
    end
   end
  end
 end
 for _,puzzle in ipairs(world.Interactions:GetChildren()) do if puzzle:GetAttribute('Kind')=='Puzzle' then
  local rune=math.floor(workspace:GetServerTimeNow()/2)%3+1;local prompt=puzzle:FindFirstChildOfClass('ProximityPrompt');prompt.ObjectText='Rune '..({'I','II','III'})[rune]..' • align in order';puzzle.Color=({Color3.fromRGB(145,230,191),Color3.fromRGB(247,203,117),Color3.fromRGB(195,169,249)})[rune]
 end end
end)
task.spawn(function()
 while task.wait(2) do
  for player in pairs(P.sessions) do
   local p=P.get(player)
   if p then
    local coins,bag=p.coins,p.tycoon.bag.eggs
    local made=R.tycoon.settle(p,os.time(),false)
    if made>0 or coins~=p.coins or bag~=p.tycoon.bag.eggs then
     tycoonWorld.update(player,p)
     send(player,'production',{tycoon=p.tycoon,coins=p.coins,serverNow=os.time()})
    end
   end
  end
 end
end)
task.spawn(function()
 while task.wait(45) do
  for player,s in pairs(P.sessions) do
   if s.closing then task.spawn(P.save,player,true)
   else task.spawn(function() local ok=P.save(player,false);send(player,'save',ok);if not ok then send(player,'toast','Saving paused. Progress actions are locked to protect your profile.') end end) end
  end
 end
end)
game:BindToClose(function()
 local remaining=0
 for player in pairs(P.sessions) do remaining+=1;task.spawn(function() P.save(player,true);remaining-=1 end) end
 local untilTime=os.clock()+25;while remaining>0 and os.clock()<untilTime do task.wait(.1) end
end)
world:SetAttribute('ArrivalReady',true)
print('Impossible Mountain ready • six kingdoms • isolated profile namespace')
