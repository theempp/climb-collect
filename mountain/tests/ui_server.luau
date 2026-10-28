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
 combat={special=function() return false end,dodge=function() return false end},competition={register=function() return false end,challenge=function() return false,'Unavailable.' end}})
check(not handle({},'Train','missing') and p.coins==100,'invalid creature never spends')
refuge=false;check(not handle({},'Train','c1') and p.coins==100,'training proximity enforced')
refuge=true;local ok,message,data=handle({},'Train','c1')
check(ok and p.coins==85 and data.previousLevel==1 and data.creature.level==2 and data.previousStage==1,'training returns authoritative XP and level feedback')
p.coins=0;check(not handle({},'Train','c1') and p.coins==0,'insufficient balance denied')
p.creatures[1].level=50;check(not handle({},'Train','c1'),'max level training denied')
check(not handle({},'Special',{slot=1}) and not handle({},'Dodge',nil),'combat failures never acknowledge success')
check(not handle({},'RegisterDefense',nil) and not handle({},'ChallengeDefense',0),'unavailable defense service failure')
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
print('PASS '..count..' server action checks')
