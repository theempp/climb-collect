local R=require('../shared/Rules')
local H=R.tycoon.home
local L=require('../shared/HomeLayout')
local C=require('../shared/Catalog')
local T=R.tycoon
local n=0
local function check(v,m) assert(v,m);n+=1 end
local function fresh() local p=R.newProfile(100);T.ensure(p,100);p.coins=500;table.insert(p.creatures,{id='x1',species=C.species[1].id,level=7});table.insert(p.creatures,{id='x2',species=C.species[7].id,level=3});return p end
local p=fresh()
check(T.valid(p.tycoon) and p.tycoon.home==nil,'legacy profile without home record still validates')
check(H.valid(H.fresh()),'fresh home validates')
-- Buying
check(not H.buy(p,'nope'),'unknown item')
check(H.buy(p,'lantern_post') and p.coins==460 and p.tycoon.home.owned.lantern_post,'buy decor spends coins')
check(not H.buy(p,'lantern_post') and p.coins==460,'cannot buy twice')
local poor=fresh();poor.coins=10;check(not H.buy(poor,'garden_arch') and poor.coins==10,'cannot overspend')
-- Placing
check(not H.place(p,'P1','flower_barrel'),'must own the item')
check(H.place(p,'P1','lantern_post'),'place owned decor in decor slot')
check(not H.place(p,'D1','lantern_post'),'decor never goes into a display slot')
check(not H.place(p,'Z9','lantern_post') and not H.place(p,nil,'lantern_post') and not H.place(p,{},'lantern_post'),'unknown or malformed slot')
check(not H.place(p,'P2','creature_pedestal'),'pedestal is not a decor prop')
H.buy(p,'trophy_shelf');check(H.place(p,'D1','trophy_shelf') and p.tycoon.home.decor.D1=='trophy_shelf','trophy shelf in a display slot')
check(not H.place(p,'P3','trophy_shelf'),'display item never goes into a decor slot')
-- Showcase
check(H.showcase(p,'D2','x1') and p.tycoon.home.showcase.D2=='x1','showcase owned creature')
check(not H.showcase(p,'D3','ghost') and not H.showcase(p,'P1','x1'),'unowned creature or decor slot refused')
check(H.showcase(p,'D3','x1') and p.tycoon.home.showcase.D2==nil and p.tycoon.home.showcase.D3=='x1','a creature stands on one display at a time')
check(H.showcase(p,'D1','x2') and p.tycoon.home.decor.D1==nil,'showcase replaces a shelf in that slot')
check(H.clear(p,'D1') and p.tycoon.home.showcase.D1==nil and not H.clear(p,'D1'),'clear')
check(T.valid(p.tycoon),'record stays valid after edits')
-- Fail-closed validation
local function bad(mut) local q=fresh();H.ensure(q.tycoon);mut(q.tycoon.home);return not T.valid(q.tycoon) end
check(bad(function(h) h.version=2 end),'wrong version')
check(bad(function(h) h.owned.fake=true end),'unknown owned item')
check(bad(function(h) h.decor.P1='lantern_post' end),'placed but not owned')
check(bad(function(h) h.owned.lantern_post=true;h.decor.D1='lantern_post' end),'decor in a display slot')
check(bad(function(h) h.decor.Z1='x' end),'unknown slot')
check(bad(function(h) h.showcase.P1='x1' end),'showcase in decor slot')
check(bad(function(h) h.showcase.D1=('x'):rep(200) end),'oversized creature id')
check(bad(function(h) h.owned.creature_pedestal=nil;h.showcase.D1='x1' end),'showcase without pedestal item')
check(bad(function(h) h.extra=1;h.owned={lantern_post=1} end),'non-boolean owned flag')
-- Visitor view is minimal and read-only
T.assign(p,1,'x1',100);p.tycoon.habitats[1].eggs=12;p.tycoon.bag.eggs=5;p.tycoon.bag.value=5
local view=H.visitorView(p,T,C)
for _,key in ipairs({'coins','bag','eggs','levels','id','creatures','owned'}) do check(view[key]==nil,'visitor view hides '..key) end
check(view.habitats[1] and view.habitats[1].level==7 and view.habitats[1].rate>0,'visitor sees species, level and rate')
check(view.habitats[1].id==nil and view.habitats[1].eggs==nil,'habitat row hides ids and egg counts')
check(view.showcase.D3 and view.showcase.D3.level==7 and view.showcase.D3.id==nil,'showcase row minimal')
check(view.decor.P1=='lantern_post','decor visible')
check(H.describe(view,'habitat',1):find('level 7') and H.describe(view,'habitat',2)=='Empty habitat.','describe habitat')
check(H.describe(view,'display','D3'):find('on display') and H.describe(view,'display','D4')=='Empty display.','describe display')
-- Visiting never mutates the owner's profile
local before=p.coins+p.tycoon.bag.eggs+p.tycoon.habitats[1].eggs
H.visitorView(p,T,C);check(before==p.coins+p.tycoon.bag.eggs+p.tycoon.habitats[1].eggs,'inspect is read-only')
-- Economy (P5): decor is a small optional coin sink; it never buys production, storage or banking.
local total=0;for _,item in H.items do total+=item.cost;check(item.kind=='decor' or item.kind=='display','decor kinds only') end
local firstUpgrades=0;for _,path in T.config.paths do firstUpgrades+=path.costs[1] end
check(total<=2*firstUpgrades,'all decor costs at most twice the first rank of every upgrade path ('..total..' vs '..firstUpgrades..')')
local before=T.rate(p,1);H.buy(p,'wind_chime');H.place(p,'P6','wind_chime');check(T.rate(p,1)==before,'decor never changes production rate')
check(#H.items==8 and #L.decorSlots==14,'catalog and slot counts')
print('PASS '..n..' home decor checks')
