local R=require('../shared/Rules')
assert(type(R.tycoon)=='table','Tycoon rules must be integrated into the existing profile contract')
local T=R.tycoon
local n=0
local function check(v,m) assert(v,m);n+=1 end
local function fresh() local p=R.newProfile(100);T.ensure(p,100);return p end
local p=fresh()
check(T.valid(p.tycoon),'fresh tycoon validates')
check(p.tycoon.slots==2 and #p.tycoon.habitats==8,'two initial / eight available')
check(T.assign(p,1,'c1',100),'assign owned creature')
check(not T.assign(p,2,'c1',100),'no duplicate production assignment')
check(not T.assign(p,3,'c2',100),'locked habitat')
check(not T.assign(p,1,'foreign',100),'foreign creature')
check(p.team[1]=='c1','combat independent')
T.settle(p,3700,false)
local eggs=p.tycoon.habitats[1].eggs
check(eggs>0 and p.coins==0 and #p.eggs==0 and #p.cargo==0,'production does not mint coins or hatchable eggs')
local moved=T.collect(p,0)
check(moved>0 and p.tycoon.bag.eggs==moved,'batch collect')
local paid=T.bank(p)
check(paid>0 and p.coins==paid and T.bank(p)==0,'bank once')
T.settle(p,3700,false);check(p.tycoon.habitats[1].eggs==eggs-moved,'same timestamp no duplication')
local a,b=fresh(),fresh();T.assign(a,1,'c1',100);T.assign(b,1,'c1',100)
T.settle(a,700,false);for t=101,700 do T.settle(b,t,false) end
check(a.tycoon.habitats[1].eggs==b.tycoon.habitats[1].eggs and a.tycoon.habitats[1].value==b.tycoon.habitats[1].value,'partition invariance')
T.settle(a,10000000,true);local full=a.tycoon.habitats[1].eggs
check(full==T.capacity(a,1),'storage capped')
T.settle(a,10000100,true);check(a.tycoon.habitats[1].eggs==full,'full storage retained')
T.collect(a,0);T.bank(a);T.settle(a,10000100,false)
check(a.tycoon.habitats[1].eggs==full-T.bagCapacity(a),'no hidden backlog after collection')
local stamp=a.tycoon.lastAt;T.settle(a,stamp-100,false);check(a.tycoon.lastAt==stamp,'future timestamp does not move backward')
local old=fresh();old.coins=123;old.tycoon=nil;T.ensure(old,500);T.ensure(old,600)
check(old.coins==123 and old.tycoon.lastAt==500,'idempotent migration does not alter balance')
check(not T.assign(p,0/0,'c1',4000) and not T.assign(p,1.1,'c1',4000),'invalid slots')
check(not T.upgrade(p,'fake',nil,4000),'invalid upgrade')
p.coins=1000000
for _=1,6 do check(T.upgrade(p,'habitats',nil,4000),'unlock next habitat') end
check(p.tycoon.slots==8 and not T.upgrade(p,'habitats',nil,4000),'habitat maximum')
local malformed=fresh().tycoon;malformed.bag.eggs=0/0;check(not T.valid(malformed),'NaN persisted egg rejected')
malformed=fresh().tycoon;malformed.habitats[1].eggs=-1;check(not T.valid(malformed),'negative eggs rejected')
check(not T.cosmetic(p,'unknown'),'unknown cosmetics rejected')
local swap=fresh();T.assign(swap,1,'c1',100);T.assign(swap,2,'c2',100)
T.settle(swap,700,false)
local firstEggs,secondEggs=swap.tycoon.habitats[1].eggs,swap.tycoon.habitats[2].eggs
check(type(T.swap)=='function','atomic swap exists')
check(T.swap(swap,1,2,700) and swap.tycoon.habitats[1].creature=='c2' and swap.tycoon.habitats[2].creature=='c1','owned habitat swap')
check(swap.tycoon.habitats[1].eggs==firstEggs and swap.tycoon.habitats[2].eggs==secondEggs,'swap preserves stored eggs')
check(not T.swap(swap,1,9,700) and not T.swap(swap,1,1,700),'invalid swaps rejected')
local neighbors=fresh();neighbors.coins=100000
for _=1,6 do T.upgrade(neighbors,'habitats',nil,100) end
T.assign(neighbors,1,'c1',100);T.assign(neighbors,8,'c2',100)
local _,_,distant=T.rate(neighbors,1)
T.assign(neighbors,8,nil,100);T.assign(neighbors,2,'c2',100)
local _,_,adjacent=T.rate(neighbors,1)
check(math.abs(adjacent-distant-.05)<1e-8,'synergy only from adjacent grid habitats')
local auto=fresh();auto.coins=100000
check(T.upgrade(auto,'automation',nil,100),'routing unlock')
check(not T.upgrade(auto,'automation',nil,100),'advanced automation prerequisite')
for _,path in ipairs({'production','storage','banking'}) do for _=1,4 do check(T.upgrade(auto,path,nil,100),'linear upgrade') end end
for _=1,4 do check(T.upgrade(auto,'automation',nil,100),'advanced automation unlock') end
T.assign(auto,1,'c1',100);local coins=auto.coins
T.settle(auto,100000,true)
check(auto.coins==coins and auto.tycoon.habitats[1].eggs>0,'offline automation cannot evade storage cap')
T.settle(auto,100001,false)
check(auto.coins>coins and auto.tycoon.habitats[1].eggs==0 and auto.tycoon.bag.eggs==0,'online automation collects and banks')
check(T.valid(auto.tycoon),'advanced production remains persistable')
local capped,exact=fresh(),fresh();T.assign(capped,1,'c1',100);T.assign(exact,1,'c1',100)
T.settle(capped,99999999,true);T.settle(exact,100+T.config.offlineSeconds,true)
check(capped.tycoon.habitats[1].eggs==exact.tycoon.habitats[1].eggs and math.abs(capped.tycoon.habitats[1].progress-exact.tycoon.habitats[1].progress)<1e-8,'offline duration cap matches exact duration')
local over=fresh();over.tycoon.habitats[1].eggs=999;over.tycoon.habitats[1].value=1999
T.settle(over,99999,true)
check(over.tycoon.habitats[1].eggs==999 and over.tycoon.habitats[1].value==1999,'over-cap migrated inventory never clamped away')
local conservation=fresh();conservation.tycoon.habitats[1].eggs=23;conservation.tycoon.habitats[1].value=47
T.collect(conservation,1);T.bank(conservation);T.collect(conservation,1);T.bank(conservation)
check(conservation.coins==47,'partial batches conserve total egg value')
local quote=fresh()
check(type(T.upgradeEffect)=='function','upgrade effects available to hub')
check(T.upgradeEffect(quote,'bag')=='Bag: 20 → 40 eggs','bag benefit matches next capacity')
check(T.upgradeEffect(quote,'storage')=='Each habitat: +30 egg storage','storage benefit')
check(T.upgradeEffect(quote,'habitats')=='Active habitats: 2 → 3','expansion benefit')
print('PASS '..n..' tycoon checks')
