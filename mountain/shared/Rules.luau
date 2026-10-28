local C = if script then require(script.Parent.Catalog) else require('./Catalog')
local R={}
R.tycoon=if script then require(script.Parent.Tycoon) else require('./Tycoon')
local function nextId(p,prefix) p.serial+=1;return prefix..p.serial end
local function find(list,id) for i,v in ipairs(list) do if v.id==id then return v,i end end end
function R.newProfile(now)
 local p={schema=2,legacyEntitlements={},securedRunIds={},serial=3,unlocked=1,wins={},captures={},cargo={},eggs={},creatures={},team={},checkpoint='1:entrance',discoveries={},claims={},shortcuts={},resources={},coins=0,trophies=0,lastIncome=now,competitionAt=0,explorer={v=1,repeatXp=0,day=0,secures=0,repeats=0,species={},won={}}}
 for i,id in ipairs({'mossbun','petalyn','fernox'}) do local v={id='c'..i,species=id,level=1,xp=0};table.insert(p.creatures,v);table.insert(p.team,v.id) end
 return p
end
R.run=if script then require(script.Parent.RunRules) else require('./RunRules')
function R.canEnter(p,k) return type(k)=='number' and k==math.floor(k) and k>=1 and k<=6 end
function R.stage(level) return if level>=35 then 3 elseif level>=15 then 2 else 1 end
function R.trialReady(k,resolvedPatterns,members)
 if resolvedPatterns<4 then return false end
 if k~=5 and k~=6 then return true end
 for _,m in pairs(members) do if m.objective then return true end end
 return false
end
function R.mastered(k,m) return m.dodges>=3 and ((k~=5 and k~=6) or m.objective==true) end
function R.addXP(c,xp)
 c.xp+=math.max(0,math.floor(xp))
 while c.level<50 and c.xp>=c.level*40 do c.xp-=c.level*40;c.level+=1 end
 if c.level>=50 then c.level=50;c.xp=0 end
end
function R.winGuardian(p,k,trial)
 if not R.canEnter(p,k) then return false end
 local g=C.guardians[k]
 if trial then
  if p.schema==2 then return false,'trial_requires_raid' end
  if not p.wins[tostring(k)] or p.captures[g.id] then return false end
  p.captures[g.id]=true
  table.insert(p.creatures,{id=nextId(p,'c'),species=g.id,level=1,xp=0})
 else
  p.wins[tostring(k)]=true;p.unlocked=math.max(p.unlocked,math.min(6,k+1))
 end
 return true
end
function R.collect(p,species,source,now)
 local s=C.byId[species]
 if not s or s.rarity=='Legendary' or not R.canEnter(p,s.kingdom) or #p.cargo>=3 or (p.claims[source] or 0)>now then return false end
 table.insert(p.cargo,{id=nextId(p,'e'),species=species});p.claims[source]=now+180
 return true
end
function R.extract(p)
 local n=#p.cargo
 for _,e in ipairs(p.cargo) do table.insert(p.eggs,e) end
 p.cargo={};return n
end
function R.incubate(p,id,now)
 local e=find(p.eggs,id)
 if not e or e.readyAt then return false end
 local active=0;for _,v in ipairs(p.eggs) do if v.readyAt then active+=1 end end
 if active>=3 then return false end
 e.readyAt=now+C.incubation[C.byId[e.species].rarity];return true
end
function R.hatch(p,id,now)
 local e,i=find(p.eggs,id)
 if not e or not e.readyAt or now<e.readyAt then return false end
 -- origin (nil earned, 'coin', 'robux') follows the egg into the creature.
 table.insert(p.creatures,{id=nextId(p,'c'),species=e.species,level=1,xp=0,origin=e.origin});table.remove(p.eggs,i);return true
end
-- D8: Robux creatures stay home; they never join the team.
function R.equip(p,ids)
 if type(ids)~='table' or #ids<1 or #ids>3 then return false end
 for key in pairs(ids) do if type(key)~='number' or key%1~=0 or key<1 or key>#ids then return false end end
 local seen={};for _,id in ipairs(ids) do local c=type(id)=='string' and find(p.creatures,id);if not c or seen[id] or c.origin=='robux' then return false end;seen[id]=true end
 p.team={};for _,id in ipairs(ids) do table.insert(p.team,id) end;return true
end
-- D8: the team members that may fight, guard, heal, follow or earn companion XP (Robux creatures never do).
function R.battleTeam(p)
 local team={};for _,id in ipairs(p.team) do local c=find(p.creatures,id);if c and c.origin~='robux' then table.insert(team,c) end end
 return team
end
-- D8 load normalize: Robux ids leave the team and each freed slot takes the highest-level battle-eligible
-- creature not already on it (ties keep collection order); Robux eggs in cargo or recovery go back to p.eggs.
function R.stripRobux(p)
 local slots,freed,onTeam={},{},{}
 for i,id in ipairs(p.team) do local c=find(p.creatures,id);if c and c.origin=='robux' then table.insert(freed,i) else slots[i]=id;onTeam[id]=true end end
 if #freed>0 then
  local pool={};for i,c in ipairs(p.creatures) do if c.origin~='robux' and not onTeam[c.id] then table.insert(pool,{c=c,i=i}) end end
  table.sort(pool,function(a,b) if a.c.level~=b.c.level then return a.c.level>b.c.level end;return a.i<b.i end)
  for n,i in ipairs(freed) do if pool[n] then slots[i]=pool[n].c.id end end
  local size=#p.team;p.team={};for i=1,size do if slots[i] then table.insert(p.team,slots[i]) end end
 end
 local moved=0
 local function home(list)
  local i=1
  while i<=#list do
   local e=list[i]
   if e.origin=='robux' then table.remove(list,i);moved+=1;if not find(p.eggs,e.id) then table.insert(p.eggs,e) end else i+=1 end
  end
 end
 home(p.cargo);if p.recovery then home(p.recovery.eggs);if #p.recovery.eggs==0 then p.recovery=nil end end
 return #freed,moved
end
function R.specialize(p,id,choice)
 local c=find(p.creatures,id)
 if not c or c.level<25 or c.specialization or not table.find({'Power','Guard','Vitality'},choice) then return false end
 c.specialization=choice;return true
end
function R.drop(p,now)
 if #p.cargo==0 then return end
 p.recovery={eggs=p.cargo,expires=now+180};p.cargo={}
end
function R.recover(p,now)
 local r=p.recovery
 if not r then return false end
 if now>=r.expires then p.recovery=nil;return false end
 if #r.eggs+#p.cargo>3 then return false end
 for _,e in ipairs(r.eggs) do table.insert(p.cargo,e) end
 p.recovery=nil;return true
end
function R.damage(element,target,base)
 local strong={Water='Fire',Fire='Nature',Nature='Earth',Earth='Crystal',Crystal='Cosmic',Cosmic='Water'}
 return math.max(1,math.floor(base*(if strong[element]==target then 1.3 elseif strong[target]==element then .8 else 1)))
end
function R.stats(c)
 local s=C.byId[c.species];local factor=1+(c.level-1)*.065
 return {attack=s.attack*factor*(if c.specialization=='Power' then 1.2 else 1),health=s.health*factor*(if c.specialization=='Vitality' then 1.25 else 1),guard=if c.specialization=='Guard' then .15 else 0,element=s.element,role=s.role}
end
function R.settleIncome(p,now)
 if p.tycoon then R.tycoon.settle(p,now,false);return 0 end
 local elapsed=math.clamp(now-p.lastIncome,0,8*3600)
 if elapsed<10 then return 0 end
 -- Q3: Robux creatures earn no legacy income.
 local rate=0;for _,c in ipairs(p.creatures) do if c.origin~='robux' then rate+=({Common=6,Uncommon=12,Rare=24,Epic=48,Mythic=90,Legendary=150})[C.byId[c.species].rarity] end end
 local accrued=elapsed*rate/3600+(p.incomeCarry or 0)
 local amount=math.floor(accrued+0.00000001);p.incomeCarry=math.max(0,accrued-amount);p.coins+=amount;p.lastIncome=now;return amount
end
R.find=find
return R
