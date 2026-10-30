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
for _=1,4 do check(T.upgrade(p,'habitats',nil,4000),'unlock next habitat') end
check(p.tycoon.slots==6 and T.maxSlots==6 and not T.upgrade(p,'habitats',nil,4000) and #p.tycoon.habitats==8,'habitat maximum 6, stored array keeps 8 (owner Q10)')
check(#T.snapshot(p).habitats==6 and T.upgradeEffect(p,'habitats')=='Active habitats: 6 → 6','snapshot shows the 6 that can unlock')
-- Home-base P2: plot tier caps habitat comfort (tier 1 = 1, absent home = tier 1); levels bought before stay.
check(T.upgrade(p,'habitat',1,4000) and p.tycoon.habitats[1].level==1,'tier 1 allows comfort 1')
local q=T.quote(p,'habitat',1);check(not T.upgrade(p,'habitat',1,4000) and p.tycoon.habitats[1].level==1 and q and not q.ready and q.tier==2 and q.requirement=='Raise your plot to Villa','comfort 2 needs tier 2, no debit')
local coins=p.coins;p.home={v=1,tier=2,decor={},stock={}};check(T.upgrade(p,'habitat',1,4000) and p.coins==coins-75 and not T.upgrade(p,'habitat',1,4000),'tier 2 allows comfort 2 only')
p.home.tier=4;check(T.upgrade(p,'habitat',1,4000) and T.upgrade(p,'habitat',1,4000) and not T.quote(p,'habitat',1),'tier 4 reaches comfort 4 max')
p.home.tier=1;check(p.tycoon.habitats[1].level==4 and T.valid(p.tycoon),'a lower tier never strips bought comfort')
p.home.decor['1']={kind='creature',id='c3'};check(not T.assign(p,2,'c3',4000),'displayed creature cannot enter a habitat');p.home=nil
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
-- Q3 (C11): a Robux creature may sit in a habitat but adds 0 coins and no kin bonus.
local kin=fresh();table.insert(kin.creatures,{id='rx',species='petalyn',level=1,xp=0,origin='robux'})
check(T.assign(kin,1,'c1',100) and T.assign(kin,2,'rx',100),'robux creature may sit in a habitat')
local _,_,earnedBonus=T.rate(kin,1);local rr,rv,rb=T.rate(kin,2)
check(rr==0 and rv==0 and rb==0,'robux habitat rate is 0')
local coinKin=fresh();table.insert(coinKin.creatures,{id='cx',species='petalyn',level=1,xp=0,origin='coin'});T.assign(coinKin,1,'c1',100);T.assign(coinKin,2,'cx',100)
local _,_,coinBonus=T.rate(coinKin,1)
check(earnedBonus==.05 and coinBonus>earnedBonus and T.snapshot(kin).habitats[2].rate==0,'robux neighbour adds no kin bonus')
local solo=fresh();table.insert(solo.creatures,{id='rx',species='violette',level=1,xp=0,origin='robux'});T.assign(solo,1,'rx',100)
T.settle(solo,36100,false);T.collect(solo,0)
check(solo.tycoon.habitats[1].eggs==0 and T.bank(solo)==0 and solo.coins==0,'robux habitat adds 0 coins')
-- hud-polish D: coins/s = Σ unlocked, assigned slots of eggs/h × coins/egg ÷ 3600 (base rate), pure.
local function dump(v) if type(v)~='table' then return tostring(v) end;local k={};for x in pairs(v) do table.insert(k,tostring(x)) end;table.sort(k);local s='{';for _,x in ipairs(k) do s..=x..'='..dump(v[x] or v[tonumber(x)])..',' end;return s..'}' end
check(T.coinRate(fresh())==0 and T.coinRate({})==0 and T.coinRate(nil)==0,'coin rate: empty habitats / no tycoon give 0')
local cr=fresh();cr.tycoon.habitats[3].creature='c3' -- slot 3 is locked (slots 2): never counted
check(T.coinRate(cr)==0,'coin rate: a locked slot gives 0')
check(T.coinRate(solo)==0,'coin rate: a Robux creature gives 0')
T.assign(cr,1,'c1',100);T.assign(cr,2,'c2',100)
local r1,v1=T.rate(cr,1);local r2,v2=T.rate(cr,2);local before=dump(cr)
check(r1*v1>0 and math.abs(T.coinRate(cr)-(r1*v1+r2*v2)/3600)<1e-12,'coin rate: sum of rate × value / 3600 over unlocked slots')
check(dump(cr)==before,'coin rate: profile unchanged')
print('PASS '..n..' tycoon checks')
