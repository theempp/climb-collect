local Requests=require('../server/UIRequests')
local Rules=require('../shared/Rules')
local Protocol=require('../shared/UIProtocol')
local count=0
local function check(value,message) assert(value,message);count+=1 end
local p=Rules.newProfile(100);p.coins=100
local profileService={get=function() return p end,setSettings=function(_,patch) p.settings=Protocol.settings(patch,p.settings);return true,p.settings end}
local refuge=true;local safe=true;local near=true;local published=0;local rebuilt=0;local traveled=nil
local handle=Requests.actions({profiles=profileService,rules=Rules,clock=function() return 200 end,safe=function() return safe end,atRefuge=function() return refuge end,nearCheckpoint=function() return near end,
 publish=function() published+=1 end,rebuildTeam=function() rebuilt+=1 end,send=function() end,
 travel=function(_,target) if target~='refuge' then return false end;Rules.extract(p);traveled=target;return true end,
 combat={special=function() return false end,dodge=function() return false end}})
check(not handle({},'Train','missing') and p.coins==100,'invalid creature never spends')
refuge=false;check(not handle({},'Train','c1') and p.coins==100,'training proximity enforced')
refuge=true;local ok,message,data=handle({},'Train','c1')
check(ok and p.coins==85 and data.previousLevel==1 and data.creature.level==2 and data.previousStage==1,'training returns authoritative XP and level feedback')
p.coins=0;check(not handle({},'Train','c1') and p.coins==0,'insufficient balance denied')
p.creatures[1].level=50;check(not handle({},'Train','c1'),'max level training denied')
check(not handle({},'Special',{slot=1}) and not handle({},'Dodge',nil),'combat failures never acknowledge success')
local okR,msgR=handle({},'RegisterDefense',nil);local okC,msgC=handle({},'ChallengeDefense',0);check(not okR and msgR=='Unknown action.' and not okC and msgC=='Unknown action.','removed defense actions are rejected as unknown')
Rules.collect(p,'mossbun','egg',100);Rules.extract(p)
local id=p.eggs[1].id
check(handle({},'Incubate',id),'real incubation accepted')
check(not handle({},'Hatch',id),'early hatch rejected')
p.eggs[1].readyAt=200
ok,message,data=handle({},'Hatch',id)
check(ok and data.creature.species=='mossbun' and data.creature.id=='c5' and #p.eggs==0,'hatch returns exact awarded creature')
check(not handle({},'Hatch',id),'hatch replay denied')
for i=1,4 do Rules.collect(p,'mossbun','incubator'..i,100);Rules.extract(p) end
for i=1,3 do check(handle({},'Incubate',p.eggs[i].id),'three existing incubators fill') end
check(not handle({},'Incubate',p.eggs[4].id),'fourth incubator rejects honestly')
check(handle({},'Equip',{'c1','c2','c3'}) and #p.team==3,'valid three-slot equipment acknowledged')
table.insert(p.creatures,{id='rx',species='bloomlet',level=1,xp=0,origin='robux'})
ok,message=handle({},'Equip',{'c1','rx'})
check(not ok and message=='Choose one to three distinct owned companions.' and #p.team==3 and not table.find(p.team,'rx'),'robux creature equip rejected with a message')
p.creatures[2].level=25
check(handle({},'Specialize',{id='c2',choice='Guard'}) and p.creatures[2].specialization=='Guard','eligible specialization acknowledged')
check(not handle({},'Specialize',{id='c2',choice='Power'}),'permanent specialization replay rejected')
ok,message,data=handle({},'CollectIncome',nil)
check(ok and type(data.coins)=='number','actual income result acknowledged')
check(not handle({},'Travel','locked'),'locked destination denied')
near=false;refuge=false;check(not handle({},'Travel','refuge') and not traveled,'travel origin proximity enforced')
refuge=true;check(handle({},'Travel','refuge') and traveled=='refuge','valid refuge travel confirmed')
safe=false;check(not handle({},'Equip',{'c1'}),'unsafe movement state denied')
check(handle({},'State',nil) and published==1,'State remains readable before safe movement')
ok,message,data=handle({},'Settings',{largeText=true})
check(ok and data.settings.largeText and p.settings.hints,'preferences UI only and not movement gated')
-- T9 (C12/C14): Buy through the dispatcher. The stub transact applies the mutate to a copy and counts writes.
local Shop=require('../shared/ShopRules')
local function deep(t) if type(t)~='table' then return t end;local c={};for k,v in pairs(t) do c[k]=deep(v) end;return c end
local bp=Rules.newProfile(100);bp.coins=6000
local pendingId=nil;local inSanct=true;local battle=false;local tick=0;local writes=0;local commit='ok'
local shopService={get=function() return bp end,pending=function() return pendingId end,
 transact=function(_,id,mutate)
  if commit=='duplicate' then return false,'duplicate' end
  local draft=deep(bp);local ok,why=mutate(draft);if not ok then return false,why end
  if commit=='save_pending' then pendingId=id;return false,'save_pending' end
  writes+=1;table.clear(bp);for k,v in pairs(draft) do bp[k]=v end;return true,why
 end}
local rolls=0;local skinEquips,skinSaves=0,0
local shop=Requests.actions({profiles=shopService,rules=Rules,clock=function() return 200 end,safe=function() return safe end,atRefuge=function() return true end,
 publish=function() end,rebuildTeam=function() end,send=function() end,shop=Shop,monotonic=function() return tick end,rollOdds=function() rolls+=1;return 50 end,
 equipBat=function() skinEquips+=1 end,save=function() skinSaves+=1 end,
 inSanctuary=function() return inSanct end,inBattle=function() return battle end})
local shopper={}
local function buy(receipt,item) return shop(shopper,'Buy',{item=item or 'meadow_egg',receipt=receipt}) end
safe=true
ok,message=handle({},'Buy',{item='meadow_egg',receipt='receipt-old1'});check(not ok and message=='Finish your fight before shopping.' and p.coins==0,'dispatcher without sanctuary and battle context fails closed')
bp.run={id='carry',eggId='raid:1:1',species='mossbun',section=1,trial=false,phase='carried',hits=2}
ok,message=buy('receipt-0001');check(not ok and message=='Finish your current creature run first.' and bp.coins==6000 and writes==0,'gate_refuses_carried_run')
bp.run=nil;battle=true
ok,message=buy('receipt-0001');check(not ok and message=='Finish your fight before shopping.' and writes==0,'gate_refuses_in_battle')
battle=false;inSanct=false
ok,message=buy('receipt-0001');check(not ok and message=='Shop from your sanctuary.' and writes==0,'gate_refuses_outside_sanctuary')
inSanct=true;pendingId='buy:other'
ok,message=buy('receipt-0001');check(not ok and message=='Saving in progress. Try again shortly.' and writes==0,'gate_refuses_pending_transaction')
pendingId=nil;safe=false
check(not buy('receipt-0001') and writes==0,'buy needs a safe character');safe=true
check(rolls==0,'refused buys never roll')
ok,message,data=buy('receipt-0001')
check(ok and message=='Egg added to your collection.' and bp.coins==3500 and #bp.eggs==1 and writes==1 and rolls==1,'buy debits once and grants once')
check(data.receipt=='receipt-0001' and data.egg.origin=='coin' and data.egg.species==require('../shared/EggOdds').pick(1,50) and data.egg.id==bp.eggs[1].id and data.egg~=bp.eggs[1],'buy returns a copy of the granted egg')
ok,message=buy('receipt-0002');check(not ok and message=='Please wait a moment before buying again.' and writes==1 and bp.coins==3500,'two_second_cooldown')
tick=1.99;check(not buy('receipt-0002') and writes==1,'cooldown holds until 2 s')
tick=2;ok,message,data=buy('receipt-0001')
check(ok and message=='Purchase already complete.' and data.receipt=='receipt-0001' and writes==1 and bp.coins==3500 and #bp.eggs==1,'known receipt answered from the live profile without a write')
tick=4;ok,message=buy('receipt-0003','golden_egg');check(not ok and message=='This item is not on sale yet.' and writes==1,'robux item refused')
tick=6;ok,message=buy('receipt-0004','pink_swirl');check(not ok and message=='Unknown shop item.' and writes==1,'unknown item refused')
tick=8;bp.coins=2499;ok,message=buy('receipt-0005');check(not ok and message=='Not enough coins for this item.' and bp.coins==2499 and writes==1,'insufficient coins refused')
tick=10;bp.coins=1e5;for i=1,23 do table.insert(bp.eggs,{id='f'..i,species='mossbun'}) end
ok,message=buy('receipt-0006');check(not ok and message=='Egg storage is full (24). Hatch an egg first.' and #bp.eggs==24 and writes==1,'egg cap refused')
for _=1,4 do table.remove(bp.eggs) end
tick=12;commit='save_pending';ok,message=buy('receipt-0007')
check(not ok and message=='Purchase is saving. It appears once saving resumes.' and pendingId=='buy:receipt-0007','failed commit reports saving, not a refund')
pendingId=nil;commit='duplicate';tick=14;ok,message=buy('receipt-0008')
check(ok and message=='Purchase already complete.','duplicate mutate is already applied')
-- T10 (C16): Candy Swirl through the same Buy path, then Skin equip/clear behind the C12 gate.
commit='ok';tick=16;ok,message=shop(shopper,'Skin',{op='clear'})
check(ok and message=='Bat skin cleared.' and bp.cosmetics==nil and skinEquips==0 and skinSaves==0,'clear with nothing equipped neither rebuilds nor saves')
ok,message,data=shop(shopper,'Skin',{op='equip',id='candy_swirl'})
check(not ok and message=='Buy this skin first.' and writes==1 and bp.cosmetics==nil and skinEquips==0 and skinSaves==0 and data.cosmetics.batSkin==nil,'skin equip needs ownership')
local rolled=rolls;tick=18;bp.coins=6000;ok,message,data=buy('skin-00001','candy_swirl')
check(ok and message=='Bat skin added. Equip it from Bats.' and bp.coins==1000 and bp.cosmetics.skins.candy_swirl and bp.cosmetics.batSkin==nil and #bp.eggs==20 and writes==2 and rolls==rolled,'candy swirl bought for 5,000 coins with no odds roll')
check(data.receipt=='skin-00001' and data.skin=='candy_swirl' and data.cosmetics.skins.candy_swirl and data.cosmetics~=bp.cosmetics and data.egg==nil,'skin buy returns a cosmetics copy')
tick=20;bp.coins=9000;ok,message=buy('skin-00002','candy_swirl');check(not ok and message=='You already own this skin.' and bp.coins==9000 and writes==2,'owned skin refused with no debit')
tick=22;ok,message=buy('skin-00001','candy_swirl');check(ok and message=='Purchase already complete.' and bp.coins==9000 and writes==2,'skin receipt replay needs no write')
ok,message,data=shop(shopper,'Skin',{op='equip',id='candy_swirl'})
check(ok and message=='Bat skin equipped.' and bp.cosmetics.batSkin=='candy_swirl' and skinEquips==1 and skinSaves==1 and data.cosmetics.batSkin=='candy_swirl' and writes==2,'skin equip rebuilds the bat and saves')
ok,message=shop(shopper,'Skin',{op='equip',id='candy_swirl'});check(ok and message=='Bat skin equipped.' and skinEquips==1 and skinSaves==1,'equipping the equipped skin neither rebuilds nor saves')
check(not shop(shopper,'Skin',{op='equip',id='meadow_egg'}) and bp.cosmetics.batSkin=='candy_swirl' and skinEquips==1,'only owned skin ids equip')
bp.run={id='carry',eggId='raid:1:1',species='mossbun',section=1,trial=false,phase='carried',hits=2}
ok,message=shop(shopper,'Skin',{op='clear'});check(not ok and message=='Finish your current creature run first.' and bp.cosmetics.batSkin=='candy_swirl','skin gate refuses carried run')
bp.run=nil;battle=true;ok,message=shop(shopper,'Skin',{op='clear'});check(not ok and message=='Finish your fight before shopping.' and bp.cosmetics.batSkin=='candy_swirl','skin gate refuses in battle')
battle=false;pendingId='buy:other';ok,message=shop(shopper,'Skin',{op='clear'});check(not ok and message=='Saving in progress. Try again shortly.' and bp.cosmetics.batSkin=='candy_swirl','skin gate refuses pending transaction')
pendingId=nil;safe=false;check(not shop(shopper,'Skin',{op='clear'}) and bp.cosmetics.batSkin=='candy_swirl','skin needs a safe character');safe=true
inSanct=false;ok,message=shop(shopper,'Skin',{op='clear'});check(not ok and message=='Shop from your sanctuary.' and bp.cosmetics.batSkin=='candy_swirl' and skinEquips==1,'skin shares the shop gate')
inSanct=true;ok,message=shop(shopper,'Skin',{op='clear'})
check(ok and message=='Bat skin cleared.' and bp.cosmetics.batSkin==nil and bp.cosmetics.skins.candy_swirl and skinEquips==2 and skinSaves==2 and writes==2,'skin clear keeps ownership')
for _=1,8 do shop(shopper,'Skin',{op='clear'}) end;check(skinEquips==2 and skinSaves==2,'repeated clear spam never saves')
-- The Bat action through the dispatcher (equip, upgrade, refusals).
local BatRules=require('../shared/BatRules')
local bat=Rules.newProfile(100);bat.coins=100;local equipped,saved=0,0
local bats=Requests.actions({profiles={get=function() return bat end},rules=Rules,safe=function() return false end,batRules=BatRules,
 equipBat=function() equipped+=1 end,save=function() saved+=1 end,batSnapshot=function(q) return {equipped=q.bats.equipped,level=q.bats.levels[q.bats.equipped]} end})
ok,message,data=bats({},'Bat',{op='equip',id='trail'})
check(ok and message=='Bat equipped.' and data.bats.equipped=='trail' and equipped==1 and saved==1,'bat equip through dispatcher')
ok,message=bats({},'Bat',{op='equip',id=BatRules.bats[2].id});check(not ok and message=='Complete the section index set to unlock this bat.' and equipped==1,'locked bat refused')
ok,message=bats({},'Bat',{op='upgrade',id='trail'});check(not ok and message=='Not enough coins for this upgrade.' and bat.coins==100,'bat upgrade needs coins')
bat.coins=500;ok,message,data=bats({},'Bat',{op='upgrade',id='trail'})
check(ok and message=='Bat upgraded.' and bat.coins==500-BatRules.upgradeCost(1) and data.bats.level==2 and saved==2,'bat upgrade debits and saves')
bat.bats.levels[BatRules.bats[2].id]=1;ok,message=bats({},'Bat',{op='upgrade',id=BatRules.bats[2].id});check(not ok and message=='Equip this bat to upgrade it.','upgrade needs the bat equipped')
bat.bats.levels.trail=BatRules.maxLevel;ok,message=bats({},'Bat',{op='upgrade',id='trail'});check(not ok and message=='This bat is at maximum level.','max level refused')
-- Home-base P2: Home and Inspect through the dispatcher. The stub transact applies the mutate to a copy (one write on ok).
local Home=require('../shared/HomeRules');local Explorer=require('../shared/ExplorerRules')
local hp=Rules.newProfile(100);Rules.tycoon.ensure(hp,100);Home.ensure(hp);hp.coins=5000
local atHome=true;local homeWrites=0;local homePending=nil;local commitHome='ok';local changedOps={};local homePublished=0
local homeService={get=function() return hp end,pending=function() return homePending end,
 transact=function(_,id,mutate)
  local draft=deep(hp);local done,why=mutate(draft);if not done then return false,why end
  if commitHome=='save_pending' then homePending=id;return false,'save_pending' end
  homeWrites+=1;table.clear(hp);for k,v in pairs(draft) do hp[k]=v end;return true,why
 end}
local owner={UserId=7};local visitorAt=0;local inSanctHome=true
local homeAct=Requests.actions({profiles=homeService,rules=Rules,clock=function() return 200 end,safe=function() return true end,home=Home,atHome=function() return atHome end,
 guid=function() return 'g' end,publish=function() homePublished+=1 end,homeChanged=function(_,op) table.insert(changedOps,op) end,monotonic=function() return visitorAt end,
 inSanctuary=function() return inSanctHome end,plotProfile=function(i) if i==3 then return 'Ada',hp end end})
ok,message=homeAct(owner,'Home',{op='tier'});check(not ok and message=='Reach a higher rank to raise your plot.' and hp.coins==5000 and homeWrites==0,'tier below rank refused, no write')
hp.explorer.repeatXp=Explorer.start(5);atHome=false;ok,message=homeAct(owner,'Home',{op='tier'});check(not ok and message=='Use your own sanctuary plot.' and hp.home.tier==1,'tier needs own plot')
atHome=true;hp.run={id='r'};ok,message=homeAct(owner,'Home',{op='tier'});check(not ok and message=='Finish your current creature run first.' and homeWrites==0,'tier refused mid-run');hp.run=nil
ok,message,data=homeAct(owner,'Home',{op='tier'})
check(ok and message=='Plot raised to Cedar Cloister.' and hp.home.tier==2 and hp.coins==4000 and homeWrites==1 and data.home.tier==2 and changedOps[1]=='tier' and homePublished==1,'tier raise commits once, publishes after commit')
ok,message=homeAct(owner,'Home',{op='tier'});check(not ok and message=='Reach a higher rank to raise your plot.' and hp.coins==4000 and homeWrites==1,'next tier rank-gated')
ok,message,data=homeAct(owner,'Home',{op='place',slot=1,kind='prop',id='lantern'})
check(ok and message=='Bought and placed.' and hp.coins==3200 and data.home.decor[1].id=='lantern' and homeWrites==2,'prop bought on place')
ok,message=homeAct(owner,'Home',{op='place',slot=1,kind='creature',id='c1'});check(not ok and message=='Clear this slot first.' and homeWrites==2,'occupied refused')
ok,message=homeAct(owner,'Home',{op='place',slot=8,kind='creature',id='c1'});check(not ok and message=='Raise your plot to use this slot.','locked slot refused')
ok,message=homeAct(owner,'Home',{op='place',slot=2,kind='prop',id='basin'});check(not ok and message=='Raise your plot to buy this decoration.' and hp.coins==3200,'tier-locked prop, no debit')
ok,message=homeAct(owner,'Home',{op='place',slot=2,kind='creature',id='zz'});check(not ok and message=='Choose a creature you own.','unowned refused')
ok,message=homeAct(owner,'Home',{op='place',slot=2,kind='creature',id='c2'});check(ok and message=='Placed on display.' and homeWrites==3,'creature placed')
ok,message=homeAct(owner,'Home',{op='clear',slot=1});check(ok and message=='Display cleared.' and hp.home.stock.lantern==1 and hp.coins==3200,'clear stocks the prop')
ok,message=homeAct(owner,'Home',{op='clear',slot=1});check(not ok and message=='This slot is already empty.','clear twice refused')
commitHome='save_pending';ok,message=homeAct(owner,'Home',{op='place',slot=3,kind='prop',id='bed'})
check(not ok and message=='Saving in progress. Try again shortly.' and hp.coins==3200 and hp.home.decor['3']==nil,'failed commit: live profile unchanged')
ok,message=homeAct(owner,'Home',{op='tier'});check(not ok and message=='Saving in progress. Try again shortly.','pending blocks the next home write');commitHome='ok';homePending=nil
-- Inspect: read-only, sanctuary only, rate-limited, never inventory.
local coinsBefore,writesBefore=hp.coins,homeWrites
ok,message,data=homeAct(owner,'Inspect',{plot=3,kind='decor',index=2})
check(ok and data.inspect.species=='petalyn' and data.inspect.owner=='Ada' and data.inspect.id==nil and data.inspect.coins==nil and hp.coins==coinsBefore and homeWrites==writesBefore,'inspect returns the public view only')
ok,message=homeAct(owner,'Inspect',{plot=3,kind='decor',index=1});check(not ok and message=='Please wait a moment.','inspect rate-limited')
visitorAt=1;ok,message=homeAct(owner,'Inspect',{plot=3,kind='decor',index=1});check(not ok and message=='Nothing on display there.','empty display')
visitorAt=2;ok,message=homeAct(owner,'Inspect',{plot=5,kind='decor',index=1});check(not ok and message=='Nobody is home on that plot.','empty plot')
visitorAt=3;inSanctHome=false;ok,message=homeAct(owner,'Inspect',{plot=3,kind='decor',index=2});check(not ok and message=='Visit the sanctuary to look closer.','inspect needs the sanctuary')
-- Tycoon comfort cap message names the tier.
hp.home.tier=1;hp.tycoon.habitats[1].level=1;hp.coins=1000
ok,message=homeAct(owner,'Tycoon',{op='upgrade',path='habitat',slot=1});check(not ok and message=='Raise your plot to Cedar Cloister to upgrade further.' and hp.coins==1000,'comfort cap names the tier, no debit')
print('PASS '..count..' server action checks')
