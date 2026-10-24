local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local A=require(game.ServerStorage.MountainWorld.Art)
local B={battles={},wild={},dodgeUntil={},specialAt={},buffs={},nextId=0}
local profiles,send,changed
local function root(player) local c=player.Character;return c and c:FindFirstChild('HumanoidRootPart') end
local function alive(player) local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 and h end
local function inArena(player,b) local r=root(player);return r and (r.Position-b.center).Magnitude<58 and alive(player) end
local function power(p,targetElement)
 local damage=0
 for _,id in ipairs(p.team) do local c=R.find(p.creatures,id);if c then local st=R.stats(c);damage+=if targetElement then R.damage(st.element,targetElement,st.attack) else st.attack end end
 return damage
end
local function harm(player,amount)
 local p=profiles.get(player);local h=alive(player);if not p or not h then return end
 local guard=0
 for _,id in ipairs(p.team) do local c=R.find(p.creatures,id);if c then local st=R.stats(c);guard+=st.guard+(if st.role=='Tank' then .05 else 0) end end
 local buff=B.buffs[player]
 if buff and os.clock()<buff.untilTime and buff.shield then guard+=.25 end
 h:TakeDamage(amount*(1-math.min(.65,guard)))
end
local guardianEffects={
 {'burst','control','heal','empower'}, {'burst','break','haste','burst'},
 {'burst','break','shield','empower'}, {'burst','control','haste','break'},
 {'burn','burst','heal','empower'}, {'break','control','empower','burst'},
}
local function warnPart(b,name,pos,size,color)
 local p=A.part(workspace.ImpossibleMountain.Dynamics,name,size,CFrame.new(pos),color,Enum.Material.Neon,nil,false);p.Transparency=.55;table.insert(b.effects,p);return p
end
function B.init(p,s,c) profiles=p;send=s;changed=c end
function B.start(player,k,trial,center)
 local p=profiles.get(player);if not p or not R.canEnter(p,k) or (trial and not p.wins[tostring(k)]) then return false,'Defeat the normal Guardian first.' end
 if B.wild[player] then return false,'Finish your wild encounter first.' end
 for _,other in pairs(B.battles) do if other.members[player] and other.k~=k then return false,'Already in another battle.' end end
 local b=B.battles[k]
 if b then
  if b.trial~=trial then return false,'A different encounter is already active.' end
  if b.members[player] then return false,'You are already in this encounter.' end
  if b.hp<b.max*.75 then return false,'Battle underway; join the next encounter.' end
  b.max+=350+k*80;b.hp+=350+k*80
 else
  b={k=k,trial=trial,center=center,hp=950+k*300,max=950+k*300,members={},nextAttack=os.clock()+4,beat=0,resolved=0,effects={},started=os.clock(),regen=false}
  B.battles[k]=b
 end
 b.members[player]={damage=0,dodges=0,hits=0,joined=os.clock()};send(player,'toast',if trial then 'Legendary Trial • dodge 3 patterns and win for guaranteed capture.' else 'Guardian battle • allies can join at the altar.');return true
end
function B.startWild(player,species,part)
 local p=profiles.get(player);local s=C.byId[species]
 if not p or not s or s.rarity=='Legendary' or #p.cargo>=3 then return false,'Make room for an egg first.' end
 if B.wild[player] then return false,'Already in a wild encounter.' end
 for _,b in pairs(B.battles) do if b.members[player] then return false,'Finish the Guardian encounter first.' end end
 if (p.claims['wild:'..species] or 0)>os.time() then return false,'This creature is resting.' end
 B.wild[player]={species=species,part=part,hp=s.health*2,nextAttack=os.clock()+3};return true,'Wild encounter started • stay near the creature.'
end
function B.dodge(player)
 local now=os.clock();if now<(B.dodgeUntil[player] or 0)+3 then return false end
 B.dodgeUntil[player]=now+.65;return true
end
function B.special(player,slot,ability)
 if type(slot)~='number' or slot%1~=0 or slot<1 or slot>3 then return false end
 local p=profiles.get(player);local c=p and R.find(p.creatures,p.team[slot]);if not c then return false end
 local s=C.byId[c.species];ability=if s.rarity=='Legendary' and type(ability)=='number' and ability%1==0 and ability>=1 and ability<=4 then ability else 1
 local key=tostring(player.UserId)..':'..c.id..':'..ability;local now=os.clock()
 if now<(B.specialAt[key] or 0) then return false end
 local battle
 for _,b in pairs(B.battles) do if b.members[player] and inArena(player,b) then battle=b;break end end
 local wild=B.wild[player]
 if not battle and not wild then return false end
 B.specialAt[key]=now+12+(ability-1)*3
 local damage=R.stats(c).attack*(if ability==4 then 6 else 3)
 local effect=if s.rarity=='Legendary' then guardianEffects[s.kingdom][ability] else ({Support='heal',Tank='shield',Control='control',Speed='haste',Magic='burn',Damage='burst'})[s.role]
 if effect=='heal' then
  local h=alive(player);if h then h.Health=math.min(h.MaxHealth,h.Health+40) end
  if battle then for ally in pairs(battle.members) do local ah=alive(ally);if ah and inArena(ally,battle) then ah.Health=math.min(ah.MaxHealth,ah.Health+24) end end end
 elseif effect=='shield' or effect=='haste' or effect=='empower' then
  local targets=if effect=='empower' and battle then battle.members else {[player]=true}
  for ally in pairs(targets) do B.buffs[ally]={untilTime=now+8,shield=effect=='shield',power=if effect=='haste' then 1.35 elseif effect=='empower' then 1.5 else 1} end
 end
 if battle then
  if effect=='control' then battle.weakenUntil=now+8 elseif effect=='break' then battle.breakUntil=now+8 elseif effect=='burn' then battle.burnUntil=now+6;battle.burnPower=damage*.2 end
  if battle.regen then
   local r=root(player)
   if r and battle.core and (r.Position-battle.core.Position).Magnitude<16 then battle.regen=false;for _,m in pairs(battle.members) do m.objective=true end;send(player,'toast','Regeneration interrupted!');damage*=2 end
  end
  damage=R.damage(s.element,C.kingdoms[battle.k].element,damage);battle.hp-=damage;battle.members[player].damage+=damage
 elseif wild and root(player) and (root(player).Position-wild.part.Position).Magnitude<30 then wild.hp-=damage end
 return true
end
local function pattern(b)
 b.beat+=1;local phase=(b.beat-1)%4+1;local center=b.center;local tell=if b.trial then 1.6 else 2.2
 local guardian=workspace.ImpossibleMountain.Encounters:FindFirstChild('Guardian_'..b.k)
 if guardian then guardian:SetAttribute('TellUntil',workspace:GetServerTimeNow()+tell) end
 local effects={};local attackPos=center
 if b.k==5 and phase==3 then
  b.regen=true
  for i=1,3 do
   local p=warnPart(b,if i==2 then 'TrueEmberHeart' else 'EmberDecoy',center+Vector3.new((i-2)*20,4,-8),Vector3.new(4,6,4),if i==2 then Color3.fromRGB(255,220,110) else Color3.fromRGB(209,70,51))
   if i==2 then b.core=p end;table.insert(effects,p)
  end
  for player in pairs(b.members) do send(player,'toast','Find the golden heart. Use a special nearby to interrupt healing!') end
  tell=5
 elseif b.k==6 and phase==3 then
  b.aligned={};b.runeCount=0
  for i=1,3 do
   local p=warnPart(b,'StarAlignment',center+Vector3.new((i-2)*20,3,12),Vector3.new(5,5,5),Color3.fromRGB(150,195,255));table.insert(effects,p)
   local q=Instance.new('ProximityPrompt');q.ActionText='Align constellation';q.HoldDuration=.25;q.MaxActivationDistance=10;q.RequiresLineOfSight=false;q.Parent=p
   q.Triggered:Connect(function(player)
    if not b.members[player] or not inArena(player,b) or not root(player) or (root(player).Position-p.Position).Magnitude>12 or b.aligned[i] then return end
    b.aligned[i]=true;b.runeCount+=1;p.Color=Color3.fromRGB(133,255,175)
    if b.runeCount==3 then for _,m in pairs(b.members) do m.objective=true end end
   end)
  end
  tell=6
  for player in pairs(b.members) do send(player,'toast','Align all three constellation stones before the gravity wave!') end
 elseif phase==1 then
  for player in pairs(b.members) do local r=root(player);if r then attackPos=Vector3.new(r.Position.X,center.Y+.4,r.Position.Z);break end end
  table.insert(effects,warnPart(b,'DodgeCircle',attackPos,Vector3.new(22,.25,22),Color3.fromRGB(255,100,100)))
 elseif phase==2 then
  table.insert(effects,warnPart(b,'CrossBeam',center+Vector3.new(0,.3,0),Vector3.new(13,.3,80),Color3.fromRGB(255,176,91)))
  if b.k==4 or b.k==6 then table.insert(effects,warnPart(b,'PrismCross',center+Vector3.new(0,.3,0),Vector3.new(80,.3,13),Color3.fromRGB(255,176,91))) end
 else
  for i=1,16 do local a=i*math.pi/8;table.insert(effects,warnPart(b,'ExpandingWave',center+Vector3.new(math.cos(a)*25,.3,math.sin(a)*25),Vector3.new(8,.25,8),Color3.fromRGB(235,112,162))) end
 end
 task.delay(tell,function()
  if B.battles[b.k]~=b then for _,e in ipairs(effects) do e:Destroy() end;return end
  for player,m in pairs(b.members) do
   if inArena(player,b) then
    local p=root(player).Position;local d=p-center;local hit
    if b.k==5 and phase==3 then hit=b.regen
    elseif b.k==6 and phase==3 then hit=b.runeCount<3
    elseif phase==1 then hit=(p-attackPos).Magnitude<15
    elseif phase==2 then hit=math.abs(d.X)<7 or ((b.k==4 or b.k==6) and math.abs(d.Z)<7)
    else hit=d.Magnitude>17 and d.Magnitude<34 end
    if hit and os.clock()>(B.dodgeUntil[player] or 0) then
     harm(player,(if b.trial then 30 else 19)*(if os.clock()<(b.weakenUntil or 0) then .7 else 1));m.hits+=1
    else m.dodges+=1 end
   end
  end
  b.resolved+=1
  if b.regen then b.hp=math.min(b.max,b.hp+b.max*.08) end
  b.regen=false;b.core=nil
  for _,e in ipairs(effects) do e:Destroy() end
 end)
end
function B.tick()
 local now=os.clock()
 for player,w in pairs(B.wild) do
  local p=profiles.get(player);local rr=root(player)
  if not p or not rr or not alive(player) or not w.part.Parent or (rr.Position-w.part.Position).Magnitude>35 then B.wild[player]=nil;send(player,'battle',false);send(player,'toast','Wild encounter ended.')
  else
   w.hp-=power(p,C.byId[w.species].element)
   send(player,'battle',{name=C.byId[w.species].name,hp=math.max(0,w.hp),max=C.byId[w.species].health*2,trial=false,kingdom=C.byId[w.species].kingdom,resolved=0,objective=false,members={{userId=player.UserId,name=player.DisplayName}},captureOwned=false})
   if now>=w.nextAttack then w.nextAttack=now+4;if now>(B.dodgeUntil[player] or 0) then harm(player,8) end end
   if w.hp<=0 then
    local collected=R.collect(p,w.species,'wild:'..w.species,os.time());for _,id in ipairs(p.team) do local c=R.find(p.creatures,id);if c then R.addXP(c,50) end end
    B.wild[player]=nil;changed(player);send(player,'toast',if collected then 'Encounter won • egg collected. Extract at a checkpoint.' else 'Encounter won • cargo full. Extract eggs before trying again.');send(player,'battle',false)
   end
  end
 end
 for k,b in pairs(B.battles) do
  local active=0
  for player,m in pairs(b.members) do
   local p=profiles.get(player)
   if not p or not inArena(player,b) then b.members[player]=nil;send(player,'battle',false)
   else
    active+=1;local buff=B.buffs[player];local damage=power(p,C.kingdoms[k].element)*(if buff and now<buff.untilTime then buff.power else 1)*(if now<(b.breakUntil or 0) then 1.25 else 1)
    if now<(b.burnUntil or 0) then damage+=(b.burnPower or 0)/math.max(1,active) end
    b.hp-=damage;m.damage+=damage
    local members={};for ally in pairs(b.members) do table.insert(members,{userId=ally.UserId,name=ally.DisplayName}) end
    table.sort(members,function(a,c) return a.userId<c.userId end)
    send(player,'battle',{name=C.guardians[k].name,hp=math.max(0,b.hp),max=b.max,trial=b.trial,dodges=m.dodges,phase=b.beat,kingdom=k,resolved=b.resolved,objective=m.objective==true,objectiveText=if k==5 then 'Interrupt the golden heart' elseif k==6 then 'Align all three constellation stones' elseif b.trial then 'Dodge three patterns and win' else 'Defeat the Guardian',members=members,captureOwned=p.captures[C.guardians[k].id]==true})
   end
  end
  if active==0 or now-b.started>300 then
   for player in pairs(b.members) do send(player,'battle',false);send(player,'toast','Encounter ended • challenge again at the altar.') end
   B.battles[k]=nil;for _,e in ipairs(b.effects) do e:Destroy() end
  elseif b.hp<=0 and b.trial and not R.trialReady(k,b.resolved,b.members) then
   b.hp=1
   if now>=b.nextAttack then b.nextAttack=now+5;pattern(b) end
  elseif b.hp<=0 then
   for player,m in pairs(b.members) do
    local p=profiles.get(player)
    if p and m.damage>=b.max*.03 then
     if not b.trial or R.mastered(k,m) then
      local captured=R.winGuardian(p,k,b.trial);p.coins+=80*k
      for _,id in ipairs(p.team) do local c=R.find(p.creatures,id);if c then R.addXP(c,200*k) end end
      send(player,'toast',if b.trial then (if captured then 'Guaranteed capture! '..C.guardians[k].name..' joins your collection.' else 'Trial mastered • Guardian already owned.') else C.guardians[k].name..' defeated • next kingdom unlocked!')
     else send(player,'toast','Victory, but mastery requires 3 clean dodges. Retry the Trial.') end
     changed(player);task.spawn(profiles.save,player,false)
    end
    send(player,'battle',false)
   end
   B.battles[k]=nil;for _,e in ipairs(b.effects) do e:Destroy() end
  elseif now>=b.nextAttack then b.nextAttack=now+5;pattern(b) end
 end
end
function B.cooldowns(player,serverClock)
 local now=os.clock();local result={};local prefix=tostring(player.UserId)..':'
 for key,deadline in pairs(B.specialAt) do
  if key:sub(1,#prefix)==prefix and deadline>now then result[key:sub(#prefix+1)]=serverClock+(deadline-now) end
 end
 local dodge=B.dodgeUntil[player]
 return result,if dodge then serverClock+math.max(0,dodge+3-now) else 0
end
function B.remove(player,leaving)
 B.wild[player]=nil;B.dodgeUntil[player]=nil;B.buffs[player]=nil
 if leaving then
  local prefix=tostring(player.UserId)..':'
  for key in pairs(B.specialAt) do if key:sub(1,#prefix)==prefix then B.specialAt[key]=nil end end
 end
 for _,b in pairs(B.battles) do b.members[player]=nil end
 send(player,'battle',false)
end
return B
