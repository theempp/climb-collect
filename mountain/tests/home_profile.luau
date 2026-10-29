-- Home-base P2 load migration (pure part): seed home, retire habitat modules 7-8 with a refund (owner Q10),
-- normalize displays, idempotent. Profiles-level refusal and persistence are in run_persistence.luau.
local R=require('../shared/Rules')
local H=require('../shared/HomeRules')
local Cfg=require('../shared/TycoonConfig')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local function legacy(slots)
 local p=R.newProfile(100);p.home=nil;R.tycoon.ensure(p,100);p.coins=10
 for i=4,9 do table.insert(p.creatures,{id='c'..i,species='mossbun',level=1,xp=0}) end
 p.tycoon.slots=slots
 return p
end
-- Old profile, no home: seeded, nothing else moves.
local p=legacy(2);local report=H.migrate(p)
check(p.home and p.home.v==1 and p.home.tier==1 and H.valid(p.home) and report.refund==0 and report.eggValue==0 and #report.unassigned==0 and p.coins==10,'old profile seeded at tier 1, no refund')
check(R.tycoon.valid(p.tycoon) and p.tycoon.slots==2,'tycoon untouched below 7')
-- Six modules: untouched.
p=legacy(6);p.tycoon.habitats[6].creature='c6';report=H.migrate(p)
check(p.tycoon.slots==6 and p.tycoon.habitats[6].creature=='c6' and report.refund==0 and p.coins==10,'six modules keep everything')
-- Seven modules: module 7 (750) + its comfort + its stored value refunded; creature unassigned, kept.
p=legacy(7);local h7=p.tycoon.habitats[7];h7.creature='c7';h7.level=2;h7.eggs=12;h7.value=30;h7.kingdom=3;h7.progress=.5
report=H.migrate(p)
check(report.refund==750+Cfg.paths.habitat.costs[1]+Cfg.paths.habitat.costs[2] and report.refund==850 and report.eggValue==30 and report.unassigned[1]=='c7','slot 7 refund = module 750 + comfort 25+75; eggs 30')
check(p.coins==10+850+30 and p.tycoon.slots==6,'refund paid as coins, slots capped at 6')
local after=p.tycoon.habitats[7]
check(after.creature==nil and after.level==0 and after.eggs==0 and after.value==0 and after.progress==0 and after.kingdom==3 and #p.tycoon.habitats==8,'entry 7 reset, array keeps 8, attunement kept')
local found=false;for _,c in ipairs(p.creatures) do if c.id=='c7' then found=true end end;check(found,'unassigned creature stays in the collection')
check(R.tycoon.valid(p.tycoon) and H.valid(p.home),'migrated profile valid')
-- Eight modules: 750 + 1200 + both comfort ladders (max 4 = 800 each) + both stores.
p=legacy(8)
for i=7,8 do local h=p.tycoon.habitats[i];h.creature='c'..i;h.level=4;h.eggs=5;h.value=9 end
report=H.migrate(p)
check(report.refund==750+1200+2*(25+75+200+500) and report.refund==3550 and report.eggValue==18 and #report.unassigned==2,'eight modules refund 3550 + 18 egg value')
check(p.coins==10+3550+18 and p.tycoon.slots==6,'coins credited once')
-- Idempotent: a replayed load write (UpdateAsync may run twice) pays nothing more.
local coins=p.coins;report=H.migrate(p);check(report.refund==0 and p.coins==coins,'second migrate pays nothing')
-- Upgrade path after the cap: no module 7 to buy.
p.coins=1e6;check(not R.tycoon.upgrade(p,'habitats',nil,200) and p.coins==1e6,'module 7 cannot be bought again')
-- Coins never pass the safe integer limit.
p=legacy(8);p.coins=9007199254740991-5;H.migrate(p);check(p.coins==9007199254740991,'refund clamps at 2^53-1')
-- Normalize: a stale display leaves; a duplicate keeps the lowest slot; unknown props stay inert.
p=legacy(2);H.ensure(p);R.tycoon.assign(p,1,'c1',100)
p.home.decor={['1']={kind='creature',id='gone'},['2']={kind='creature',id='c4'},['3']={kind='creature',id='c4'},['4']={kind='creature',id='c1'},['5']={kind='prop',id='future_prop'}}
H.migrate(p)
check(p.home.decor['1']==nil and p.home.decor['2'].id=='c4' and p.home.decor['3']==nil and p.home.decor['4']==nil and p.home.decor['5'].id=='future_prop','normalize: unowned out, duplicate out, habitat creature out, unknown prop kept')
-- A malformed home is never "repaired" by migrate: valid() refuses it at load (fail closed).
check(not H.valid({v=1,tier='2',decor={},stock={}}) and not H.valid({v=2,tier=1,decor={},stock={}}),'malformed and newer homes stay invalid')
print('PASS '..n..' home profile checks')
