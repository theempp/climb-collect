-- Deterministic economy experiments using production rules, not a parallel model.
local R=require('../shared/Rules')
local C=require('../shared/Catalog')
local T=R.tycoon
local checks=0
local function check(v,m) assert(v,m);checks+=1 end
local function fresh()
 local p=R.newProfile(0);T.ensure(p,0)
 T.assign(p,1,'c1',0);T.assign(p,2,'c2',0)
 return p
end
local function drain(p)
 T.bank(p)
 while T.collect(p,0)>0 do T.bank(p) end
end
for _,minutes in ipairs({5,15,30,60}) do
 local p=fresh()
 for now=60,8*3600,60 do
  T.settle(p,now,false)
  if now%(minutes*60)==0 then drain(p) end
 end
 check(T.valid(p.tycoon),'valid manual simulation')
 print(string.format('ECONOMY starter visit=%dm eight-hour-coins=%d',minutes,p.coins))
end
local p=fresh();local first={}
for now=1,3600 do
 T.settle(p,now,false);drain(p)
 for _,cost in ipairs({20,25,40,50,100}) do if not first[cost] and p.coins>=cost then first[cost]=now end end
end
for _,cost in ipairs({20,25,40,50,100}) do print(string.format('ECONOMY starter save-%d=%.2fm',cost,first[cost]/60)) end
check(first[20]<15*60 and first[50]<30*60,'starter purchases within a session with both starters assigned')
local profiles={}
for player=1,8 do
 local v=fresh();v.coins=100000;v.home={v=1,tier=4,decor={},stock={}} -- tier 4: comfort cap 4
 for _=1,4 do assert(T.upgrade(v,'habitats',nil,0),'fixture expansion') end
 for _,path in ipairs({'production','storage','banking','bag'}) do for _=1,4 do assert(T.upgrade(v,path,nil,0),'fixture '..path) end end
 for _=1,5 do assert(T.upgrade(v,'automation',nil,0),'fixture automation') end
 v.creatures={}
 for i=1,6 do
  table.insert(v.creatures,{id='p'..player..'c'..i,species=C.guardians[(i-1)%6+1].id,level=1,xp=0})
  assert(T.assign(v,i,v.creatures[i].id,0),'fixture assignment')
  for _=1,4 do assert(T.upgrade(v,'habitat',i,0),'fixture comfort') end
 end
 v.coins=0;profiles[player]=v
end
local started=os.clock()
for now=1,3600 do for _,v in ipairs(profiles) do T.settle(v,now,false) end end
print(string.format('ECONOMY eight max profiles: 28800 ticks in %.4fs; coins/hour/profile=%d',os.clock()-started,profiles[1].coins))
for i,v in ipairs(profiles) do
 check(T.valid(v.tycoon),'stress state persists')
 check(v.coins==profiles[1].coins,'equal inputs yield equal output')
 check(v.tycoon.bag.eggs==0,'autobank drains bag')
 check(not T.assign(v,1,'p'..(i%8+1)..'c1',3600),'foreign profile creature rejected')
 local coins=v.coins;T.settle(v,3600,false);check(v.coins==coins,'replayed tick cannot mint')
 T.settle(v,3600+86400,true);check(v.coins==coins,'offline cannot autobank')
 for index=1,v.tycoon.slots do check(v.tycoon.habitats[index].eggs==T.capacity(v,index),'offline storage capped') end
 local saved=v.tycoon.habitats[1].eggs;T.settle(v,3600+2*86400,true)
 check(v.tycoon.habitats[1].eggs==saved,'stored eggs survive next day')
end
for _,species in ipairs({'mossbun','fernox','bloomlet','thorncub','floramoth','floravelle'}) do
 local v=fresh();v.creatures[1].species=species;T.assign(v,2,nil,0)
 for now=1,3600 do T.settle(v,now,false);drain(v) end
 print(string.format('ECONOMY single %s level-zero hourly-coins=%d',C.byId[species].rarity,v.coins))
end
print('PASS '..checks..' tycoon economy checks')
