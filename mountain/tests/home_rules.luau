-- Home-base P2: plot tiers (rank AND coins), habitat cap, decor slots (creatures + coin props), stock, inspect.
local R=require('../shared/Rules')
local X=require('../shared/ExplorerRules')
local T=require('../shared/HomeTiers')
local H=require('../shared/HomeRules')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local function fresh(level,coins)
 local p=R.newProfile(100);R.tycoon.ensure(p,100);p.coins=coins or 0
 p.explorer.repeatXp=X.start(level or 1);H.ensure(p);return p
end
-- Table (PROPOSED numbers, STOP 3).
check(#T.tiers==4 and T.slots==14 and T.stockCap==4,'four tiers, fourteen slots, stock cap 4')
local want={{'Hut',1,0,1,4},{'Villa',5,1000,2,7},{'Manor',15,5000,3,10},{'Palace',30,15000,4,14}}
for i,w in ipairs(want) do local t=T.tiers[i];check(t.name==w[1] and t.rank==w[2] and t.fee==w[3] and t.habitatCap==w[4] and t.usable==w[5],'tier_row_'..i) end
for i=2,4 do check(T.tiers[i].rank>T.tiers[i-1].rank and T.tiers[i].fee>T.tiers[i-1].fee and T.tiers[i].usable>T.tiers[i-1].usable,'tier_'..i..'_strictly_above') end
local WS=require('../shared/WorldStyle');local styles={}
for i,t in ipairs(T.tiers) do check(t.roles==nil and WS.tier[t.style]~=nil and not styles[t.style],'tier_style_'..i);styles[t.style]=true end
local props=0;for _,id in ipairs(T.propOrder) do local d=T.props[id];props+=1;check(d and d.id==id and d.price>0 and d.price%1==0 and d.tier>=1 and d.tier<=4 and #d.name<=24,'prop_row_'..id) end
check(props==6,'six props');for id in pairs(T.props) do check(table.find(T.propOrder,id)~=nil,'prop_ordered_'..id) end
-- Seed.
local p=fresh();check(p.home.v==1 and p.home.tier==1 and next(p.home.decor)==nil and next(p.home.stock)==nil and H.valid(p.home),'ensure seeds tier 1 empty')
local same=p.home;H.ensure(p);check(p.home==same,'ensure is idempotent')
check(H.tier({})==1 and H.tier({home={tier=9}})==1 and H.habitatCap(p)==1 and H.usable(p)==4,'tier read is total')
-- Tier gate: rank AND coins (owner Q1).
p=fresh(4,1000000);local ok,why=H.raise(p);check(not ok and why=='rank' and p.home.tier==1 and p.coins==1000000,'rank 4 cannot raise, no debit')
p=fresh(5,999);ok,why=H.raise(p);check(not ok and why=='coins' and p.home.tier==1 and p.coins==999,'rank 5 short one coin refused, no debit')
p=fresh(5,1000);ok=H.raise(p);check(ok and p.home.tier==2 and p.coins==0,'rank 5 + 1000 coins raises to tier 2, exact debit')
ok,why=H.raise(p);check(not ok and why=='rank' and p.home.tier==2,'one tier per rank band')
p=fresh(14,1e6);H.raise(p);ok,why=H.raise(p);check(not ok and why=='rank' and p.home.tier==2 and p.coins==1e6-1000,'rank 14 stops at tier 2')
p=fresh(30,21000);for _=1,3 do check(H.raise(p),'climb_to_4') end
check(p.home.tier==4 and p.coins==0,'tiers 2-4 cost 21000 in total')
ok,why=H.raise(p);check(not ok and why=='max' and H.quote(p)==nil,'top tier: max and no quote')
p=fresh(50,0);local q=H.quote(p);check(q.tier==2 and q.level==50 and q.reason=='coins' and not q.ready,'quote names the missing piece')
p=fresh(1,1e9);p.coins=nil;ok,why=H.raise(p);check(not ok and why=='rank','garbage coins never raise')
p=fresh(5,1e9);p.coins=nil;ok,why=H.raise(p);check(not ok and why=='coins','nil coins refused as coins')
-- Decor: creatures (owned, not in a habitat, shown once) in usable empty slots.
p=fresh(1,0)
check(H.place(p,1,'creature','c1') and p.home.decor['1'].id=='c1','owned creature placed')
ok,why=H.place(p,2,'creature','c1');check(not ok and why=='displayed' and p.home.decor['2']==nil,'one creature, one display')
ok,why=H.place(p,1,'creature','c2');check(not ok and why=='occupied' and p.home.decor['1'].id=='c1','occupied slot refused (replay safe)')
ok,why=H.place(p,2,'creature','nope');check(not ok and why=='owned','unowned creature refused')
R.tycoon.assign(p,1,'c2',100);ok,why=H.place(p,2,'creature','c2');check(not ok and why=='habitat','habitat creature refused')
ok,why=H.place(p,5,'creature','c3');check(not ok and why=='locked','slot 5 locked at tier 1 (4 usable)')
for _,bad in ipairs({0,15,1.5,0/0,-1,'1'}) do ok,why=H.place(p,bad,'creature','c3');check(not ok and why=='slot','bad_slot_'..tostring(bad)) end
ok,why=H.place(p,3,'robot','c3');check(not ok and why=='kind','unknown kind refused')
check(H.displayed(p,'c1') and not H.displayed(p,'c3') and not R.tycoon.assign(p,2,'c1',100),'displayed creature blocked from habitats')
-- Props: buy on place (tier + coins), stock on clear, reuse from stock.
p=fresh(1,450)
ok,why=H.place(p,1,'prop','hedge');check(not ok and why=='tier' and p.coins==450,'tier 2 prop refused at tier 1, no debit')
ok,why=H.place(p,1,'prop','castle');check(not ok and why=='unknown','unknown prop refused')
ok,why,bought=H.place(p,1,'prop','bed');check(ok and bought and p.coins==150 and p.home.decor['1'].kind=='prop','buy on place debits price')
ok,why=H.place(p,2,'prop','bed');check(not ok and why=='coins' and p.coins==150 and p.home.decor['2']==nil,'short coins refused, no debit')
check(H.clear(p,1) and p.home.stock.bed==1 and p.home.decor['1']==nil and p.coins==150,'clear returns the prop to stock, no refund')
ok,why,bought=H.place(p,4,'prop','bed');check(ok and not bought and p.coins==150 and p.home.stock.bed==nil,'place from stock is free')
ok,why=H.clear(p,2);check(not ok and why=='empty','clear empty refused')
ok,why=H.clear(p,99);check(not ok and why=='slot','clear bad slot refused')
p.home.stock.boulder=4;p.home.decor['3']={kind='prop',id='boulder'};ok,why=H.clear(p,3);check(not ok and why=='stock' and p.home.decor['3'],'full stock keeps the prop placed')
check(H.clear(p,4) and H.place(p,4,'creature','c1'),'a cleared slot takes a creature')
-- Creature clear never touches the collection.
local creatures=#p.creatures;check(H.clear(p,4) and #p.creatures==creatures and not H.displayed(p,'c1'),'creature clear keeps the creature')
-- Usable slots grow with tier.
p=fresh(30,1e6);for _=1,3 do H.raise(p) end
check(H.usable(p)==14 and H.place(p,14,'prop','basin') and H.place(p,13,'creature','c1'),'tier 4 opens slot 14 and the basin')
-- Valid: strict structure.
check(H.valid(p.home),'built home valid')
local bad={'x',{},{v=2,tier=1,decor={},stock={}},{v=1,tier=5,decor={},stock={}},{v=1,tier=0,decor={},stock={}},{v=1,tier=1.5,decor={},stock={}},
 {v=1,tier=1,decor={},stock={},extra=1},{v=1,tier=1,stock={}},{v=1,tier=1,decor={}},
 {v=1,tier=1,decor={['15']={kind='prop',id='bed'}},stock={}},{v=1,tier=1,decor={[1]={kind='prop',id='bed'}},stock={}},{v=1,tier=1,decor={['01']={kind='prop',id='bed'}},stock={}},
 {v=1,tier=1,decor={['1']={kind='egg',id='bed'}},stock={}},{v=1,tier=1,decor={['1']={kind='prop',id=''}},stock={}},{v=1,tier=1,decor={['1']={kind='prop',id='bed',x=1}},stock={}},
 {v=1,tier=1,decor={['1']='bed'},stock={}},{v=1,tier=1,decor={},stock={bed=5}},{v=1,tier=1,decor={},stock={bed=-1}},{v=1,tier=1,decor={},stock={bed=0/0}},{v=1,tier=1,decor={},stock={[1]=1}}}
for i,b in ipairs(bad) do check(not H.valid(b),'invalid_home_'..i) end
check(H.valid({v=1,tier=4,decor={['14']={kind='prop',id='future_prop'},['1']={kind='creature',id='gone'}},stock={future_prop=2}}),'valid is structural: unknown prop and stale creature load (normalize handles meaning)')
-- Snapshot and inspect (public view only).
local s=H.snapshot(p);check(s.tier==4 and s.name=='Palace' and s.usable==14 and #s.decor==14 and s.decor[14].id=='basin' and s.decor[1]==false and s.next==nil,'snapshot')
check(H.snapshot(fresh(5,1000)).next.ready,'snapshot carries the next quote')
R.tycoon.assign(p,1,'c2',100)
local v=H.inspect(p,'habitat',1);check(v and v.species=='petalyn' and v.rarity=='Common' and v.level==1 and v.kind=='creature' and v.id==nil and v.coins==nil,'inspect habitat creature, no ids')
v=H.inspect(p,'decor',13);check(v and v.species=='mossbun','inspect displayed creature')
v=H.inspect(p,'decor',14);check(v and v.kind=='prop' and v.name=='Gem basin','inspect prop')
check(H.inspect(p,'decor',2)==nil and H.inspect(p,'habitat',2)==nil and H.inspect(p,'habitat',7)==nil and H.inspect(p,'bag',1)==nil and H.inspect(p,'decor',0)==nil,'inspect empty or out of range is nil')
print('PASS '..n..' home rules checks')
