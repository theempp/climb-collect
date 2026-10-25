local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local Config=if script then require(script.Parent.TycoonConfig) else require('./TycoonConfig')
local T={config=Config}
local function integer(v,lo,hi) return type(v)=='number' and v==v and v%1==0 and v>=lo and v<=hi end
local function fraction(v) return type(v)=='number' and v==v and v>=0 and v<1 end
local function find(p,id) for _,c in ipairs(p.creatures) do if c.id==id then return c end end end
local function storeValid(s) return type(s)=='table' and integer(s.eggs,0,Config.maxCount) and integer(s.value,0,Config.maxCount*100) and ((s.eggs==0 and s.value==0) or (s.eggs>0 and s.value>=s.eggs)) end
function T.valid(t)
 if type(t)~='table' or t.version~=1 or not integer(t.slots,2,8) or not integer(t.lastAt,0,9007199254740991) or not storeValid(t.bag) or not fraction(t.bankCarry) or not table.find(Config.cosmetics,t.cosmetic) then return false end
 if type(t.levels)~='table' or type(t.habitats)~='table' or #t.habitats~=8 then return false end
 for k,v in pairs(t.habitats) do if not integer(k,1,8) then return false end end
 for _,key in ipairs({'production','storage','bag','banking','automation'}) do if not integer(t.levels[key],0,#Config.paths[key].costs) then return false end end
 local seen={}
 for i,h in ipairs(t.habitats) do
  if not storeValid(h) or not integer(h.level,0,4) or not integer(h.kingdom,1,6) or not fraction(h.progress) or not fraction(h.processCarry) or not integer(h.cycle,0,9) then return false end
  if h.creature~=nil then
   if type(h.creature)~='string' or #h.creature<1 or #h.creature>80 or seen[h.creature] or i>t.slots then return false end
   seen[h.creature]=true
  end
 end
 return true
end
function T.ensure(p,now)
 if p.tycoon then return p.tycoon end
 local habitats={}
 for i=1,8 do habitats[i]={level=0,kingdom=1,eggs=0,value=0,progress=0,processCarry=0,cycle=0} end
 p.tycoon={version=1,slots=2,lastAt=math.floor(now),habitats=habitats,bag={eggs=0,value=0},levels={production=0,storage=0,bag=0,banking=0,automation=0},bankCarry=0,cosmetic='Nature'}
 return p.tycoon
end
function T.capacity(p,index) return 30+30*p.tycoon.levels.storage+10*p.tycoon.habitats[index].level end
function T.bagCapacity(p) return 20+20*p.tycoon.levels.bag end
function T.rate(p,index)
 local t=p.tycoon;local h=t.habitats[index];local c=h.creature and find(p,h.creature)
 if not c then return 0,0,0 end
 local species=C.byId[c.species];if not species then return 0,0,0 end
 local kin=0
 for i,other in ipairs(t.habitats) do
  local adjacent=(math.floor((i-1)/2)==math.floor((index-1)/2) and i~=index) or math.abs(i-index)==2
  local v=adjacent and i<=t.slots and other.creature and find(p,other.creature)
  if v and C.byId[v.species].kingdom==species.kingdom then kin+=1 end
 end
 local bonus=(if species.kingdom==h.kingdom then .05 else 0)+math.min(kin,2)*.05
 local rarity=Config.rarity[species.rarity]
 return rarity.rate*(1+t.levels.production*.15+h.level*.1)*(1+bonus),rarity.value,bonus
end
function T.collect(p,index)
 local t=p.tycoon
 if not integer(index,0,t.slots) then return 0 end
 local order={};for i=1,t.slots do if index==0 or index==i then table.insert(order,i) end end
 if t.levels.automation>=3 then table.sort(order,function(a,b)
  local x,y=t.habitats[a],t.habitats[b]
  local xv,yv=x.value/math.max(1,x.eggs),y.value/math.max(1,y.eggs)
  return if xv==yv then a<b else xv>yv
 end) end
 local moved=0
 for _,i in ipairs(order) do
  local h=t.habitats[i];local n=math.min(h.eggs,math.max(0,T.bagCapacity(p)-t.bag.eggs))
  if n>0 then
   local value=if n==h.eggs then h.value else math.floor(h.value*n/h.eggs)
   h.eggs-=n;h.value-=value;t.bag.eggs+=n;t.bag.value+=value;moved+=n
  end
 end
 return moved
end
function T.bank(p)
 local t=p.tycoon;if t.bag.eggs==0 then return 0 end
 local raw=t.bag.value*(1+t.levels.banking*.025)+t.bankCarry
 local value=math.floor(raw+1e-8)
 if p.coins+value>9007199254740991 then return 0 end
 t.bankCarry=math.max(0,raw-value);p.coins+=value;t.bag.eggs=0;t.bag.value=0
 return value
end
function T.settle(p,now,offline)
 local t=T.ensure(p,now)
 if not integer(now,0,9007199254740991) or now<=t.lastAt then return 0 end
 local elapsed=math.min(now-t.lastAt,Config.offlineSeconds);t.lastAt=now
 local made=0
 for i=1,t.slots do
  local h=t.habitats[i];local rate,value=T.rate(p,i)
  local raw=h.progress+elapsed*rate/3600;local whole=math.floor(raw+1e-8)
  h.progress=math.max(0,raw-whole)
  local count=math.min(whole,math.max(0,T.capacity(p,i)-h.eggs))
  local bonus=math.floor((h.cycle+count)/10);h.cycle=(h.cycle+count)%10
  local amount=(count+bonus)*value
  if t.levels.automation>=2 then
   local extra=amount*.05+h.processCarry;local added=math.floor(extra+1e-8)
   h.processCarry=math.max(0,extra-added);amount+=added
  end
  h.eggs+=count;h.value+=amount;made+=count
 end
 -- Offline catchup never drains storage, including when automatic banking is unlocked.
 if not offline and t.levels.automation>=4 then
  if t.levels.automation>=5 then
   T.bank(p)
   -- At most eight bounded stores; empty with finite batches, no per-egg iteration.
   for _=1,80 do if T.collect(p,0)==0 then break end;T.bank(p) end
  else T.collect(p,0) end
 end
 return made
end
function T.assign(p,index,id,now)
 local t=p.tycoon
 if not integer(index,1,t.slots) or (id~=nil and (type(id)~='string' or not find(p,id))) then return false end
 for i,h in ipairs(t.habitats) do if id and h.creature==id and i~=index then return false end end
 T.settle(p,now,false)
 t.habitats[index].creature=id;t.habitats[index].progress=0
 return true
end
function T.attune(p,index,kingdom,now)
 if not integer(index,1,p.tycoon.slots) or not integer(kingdom,1,6) or kingdom>p.unlocked then return false end
 T.settle(p,now,false);p.tycoon.habitats[index].kingdom=kingdom;return true
end
function T.swap(p,first,second,now)
 local t=p.tycoon
 if not integer(first,1,t.slots) or not integer(second,1,t.slots) or first==second then return false end
 local a,b=t.habitats[first],t.habitats[second]
 if not b.creature or not find(p,b.creature) or (a.creature and not find(p,a.creature)) then return false end
 T.settle(p,now,false)
 a.creature,b.creature=b.creature,a.creature
 -- Fractional production follows its creature; stored eggs remain in each habitat.
 a.progress,b.progress=b.progress,a.progress
 return true
end
function T.upgradeEffect(p,path)
 local t=p.tycoon
 if path=='habitats' then return 'Active habitats: '..t.slots..' → '..math.min(8,t.slots+1)
 elseif path=='habitat' then return '+10% base egg rate · +10 egg storage'
 elseif path=='production' then return '+15% base egg rate in every habitat'
 elseif path=='storage' then return 'Each habitat: +30 egg storage'
 elseif path=='bag' then return 'Bag: '..T.bagCapacity(p)..' → '..(T.bagCapacity(p)+20)..' eggs'
 elseif path=='banking' then return string.format('Bank value bonus: %.1f%% → %.1f%%',t.levels.banking*2.5,(t.levels.banking+1)*2.5)
 elseif path=='automation' then return Config.automation[t.levels.automation+1] or 'All automation installed' end
 return ''
end
function T.quote(p,path,index)
 local def=Config.paths[path];if not def then return nil end
 local t=p.tycoon;local level
 if path=='habitat' then if not integer(index,1,t.slots) then return nil end;level=t.habitats[index].level
 elseif path=='habitats' then level=t.slots-2 else level=t.levels[path] end
 local cost=def.costs[level+1];if not cost then return nil end
 local ready=true
 if path=='automation' and level>=1 then ready=t.levels.production>=math.min(level,4) and t.levels.storage>=math.min(level,4) and t.levels.banking>=math.max(0,level-2) end
 return {cost=cost,level=level,next=level+1,ready=ready,requirement=if ready then '' else 'Requires production/storage '..math.min(level,4)..' and banking '..math.max(0,level-2)}
end
function T.upgrade(p,path,index,now)
 local q=T.quote(p,path,index);if not q or not q.ready or p.coins<q.cost then return false end
 T.settle(p,now,false);p.coins-=q.cost
 if path=='habitats' then p.tycoon.slots+=1 elseif path=='habitat' then p.tycoon.habitats[index].level+=1 else p.tycoon.levels[path]+=1 end
 return true
end
function T.cosmetic(p,id)
 if not table.find(Config.cosmetics,id) then return false end
 p.tycoon.cosmetic=id;return true
end
function T.snapshot(p)
 local t=p.tycoon;local rows={};local eggs,value,rate=0,0,0
 for i,h in ipairs(t.habitats) do
  local r,v,bonus=T.rate(p,i);eggs+=h.eggs;value+=h.value;rate+=r
  rows[i]={creature=h.creature,level=h.level,kingdom=h.kingdom,eggs=h.eggs,value=h.value,capacity=T.capacity(p,i),rate=r,bonus=bonus,unlocked=i<=t.slots}
 end
 return {slots=t.slots,habitats=rows,eggs=eggs,value=value,rate=rate,bag=table.clone(t.bag),bagCapacity=T.bagCapacity(p),levels=table.clone(t.levels),cosmetic=t.cosmetic,offlineSeconds=Config.offlineSeconds}
end
return T
