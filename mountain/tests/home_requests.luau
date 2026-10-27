local Protocol=require('../shared/UIProtocol')
local Requests=require('../server/UIRequests')
local R=require('../shared/Rules')
local C=require('../shared/Catalog')
local T=R.tycoon
local n=0;local function check(v,m) assert(v,m);n+=1 end
-- Protocol: malformed Home / Inspect payloads are rejected before any rule runs.
local ok=function(a,v) return (Protocol.validate('t:1',a,v)) end
check(ok('Home',{op='buy',item='lantern_post'}) and ok('Home',{op='place',slot='P1',item='lantern_post'}) and ok('Home',{op='clear',slot='P1'}) and ok('Home',{op='showcase',slot='D1'}) and ok('Home',{op='showcase',slot='D1',id='x1'}),'valid home ops')
for _,v in ipairs({{op='buy'},{op='buy',item=5},{op='place',slot='P1'},{op='clear',slot={}},{op='showcase',slot='D1',id=7},{op='buy',item='lantern_post',coins=1},{op='fly',slot='P1'}}) do check(not ok('Home',v),'reject home payload') end
check(not ok('Home',nil) and not ok('Home','x'),'reject non-table home payload')
check(ok('Inspect',{plot=3,kind='habitat',key=2}) and ok('Inspect',{plot=8,kind='display',key='D4'}),'valid inspect')
for _,v in ipairs({{plot=0,kind='habitat',key=1},{plot=9,kind='habitat',key=1},{plot=1.5,kind='habitat',key=1},{plot=1,kind='habitat',key='D1'},{plot=1,kind='display',key=1},{plot=1,kind='other',key=1},{plot=1,kind='habitat',key=9},{plot=1,kind='habitat',key=1,extra=true}}) do check(not ok('Inspect',v),'reject inspect payload') end
-- Owner and visitor profiles.
local owner=R.newProfile(100);T.ensure(owner,100);owner.coins=300;table.insert(owner.creatures,{id='x1',species=C.species[1].id,level=9});T.assign(owner,1,'x1',100)
local visitor=R.newProfile(200);T.ensure(visitor,200);visitor.coins=50
local profiles={owner=owner,visitor=visitor};local home={owner=true,visitor=false};local saves=0
local dispatch=Requests.actions({profiles={get=function(player) return profiles[player] end},rules=R,catalog=C,clock=function() return 200 end,safe=function() return true end,
 atHome=function(player) return home[player] end,inSanctuary=function() return true end,profileAtPlot=function(plot) return if plot==1 then owner else nil end,save=function() saves+=1 end})
-- Owner edits their own home.
check(dispatch('owner','Home',{op='buy',item='lantern_post'}) and owner.coins==260,'owner buys decor')
check(dispatch('owner','Home',{op='place',slot='P1',item='lantern_post'}) and owner.tycoon.home.decor.P1=='lantern_post','owner places decor')
check(dispatch('owner','Home',{op='showcase',slot='D1',id='x1'}) and owner.tycoon.home.showcase.D1=='x1','owner poses creature')
check(saves==3,'each owner mutation saves')
-- Visitor cannot change anything anywhere: not their own plot area, not the owner's.
local snapshot=T.valid(owner.tycoon) and {coins=owner.coins,bag=owner.tycoon.bag.eggs,decor=owner.tycoon.home.decor.P1,show=owner.tycoon.home.showcase.D1}
for _,req in ipairs({{op='buy',item='garden_arch'},{op='place',slot='P2',item='lantern_post'},{op='clear',slot='P1'},{op='showcase',slot='D1'}}) do
 check(not dispatch('visitor','Home',req),'visitor cannot '..req.op..' while away from their own plot')
end
for _,req in ipairs({{op='collect',slot=0},{op='bank'},{op='assign',slot=1,id='x1'},{op='upgrade',path='bag'}}) do check(not dispatch('visitor','Tycoon',req),'visitor cannot '..req.op) end
check(owner.coins==snapshot.coins and owner.tycoon.bag.eggs==snapshot.bag and owner.tycoon.home.decor.P1==snapshot.decor and owner.tycoon.home.showcase.D1==snapshot.show and visitor.coins==50 and saves==3,'owner state untouched by visitor attempts')
-- Visitor inspect works and leaks nothing.
local good,message,data=dispatch('visitor','Inspect',{plot=1,kind='habitat',key=1})
check(good and message:find('level 9') and message:find('eggs/hour'),'visitor inspects habitat')
check(data.view.habitats[1].species==C.byId[C.species[1].id].name and data.view.coins==nil and data.view.bag==nil,'visitor view minimal')
check(select(2,dispatch('visitor','Inspect',{plot=1,kind='display',key='D1'})):find('on display'),'visitor inspects display')
check(not dispatch('visitor','Inspect',{plot=2,kind='habitat',key=1}),'empty home refuses')
check(saves==3,'inspect never saves')
print('PASS '..n..' home request checks')
