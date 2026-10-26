local C = require('../shared/Catalog')
local R = require('../shared/Rules')
local count=0
local function check(v,msg) assert(v,msg); count+=1 end
check(#C.kingdoms==6,'six kingdoms')
check(#C.species==36,'36 species')
local seen={}
for _,s in ipairs(C.species) do
 check(not seen[s.id],'unique ID');seen[s.id]=true
 check(s.rarity~='Legendary' and s.attack>0 and s.health>0 and s.shape and s.feature,'complete species')
end
for _,g in ipairs(C.guardians) do check(#g.abilities==4,'four abilities') end
local p=R.newProfile(100)
check(R.canEnter(p,1) and R.canEnter(p,6),'free section access')
check(not R.canEnter(p,0) and not R.canEnter(p,7) and not R.canEnter(p,0/0),'invalid kingdom')
check(R.winGuardian(p,2,false),'higher normal battle allowed')
check(R.winGuardian(p,1,false) and R.canEnter(p,2),'normal unlock')
check(not p.captures.floravelle,'normal never captures')
check(not R.winGuardian(p,1,true) and not p.captures.floravelle,'trial requires carried exit')
local reward={id='trial',runId='trial',species='floravelle',section=1,hitsRequired=1,trial=true}
check(R.run.strike(p,reward,100) and R.run.pickup(p,'trial') and R.run.secure(p,'trial') and p.captures.floravelle,'trial secured at exit')
local n=#p.creatures
R.winGuardian(p,1,true);check(#p.creatures==n,'no duplicate capture')
for i=1,3 do check(R.collect(p,'mossbun','nest'..i,100),'collect egg') end
check(not R.collect(p,'petalyn','overflow',100),'three unsecured slots')
check(not R.collect(p,'fake','fake',100),'unknown species')
check(R.extract(p)==3 and #p.cargo==0 and #p.eggs==3,'extract')
local egg=p.eggs[1].id
check(R.incubate(p,egg,100),'incubate free')
check(not R.hatch(p,egg,129),'server timestamp blocks early hatch')
check(R.hatch(p,egg,130),'hatch on time')
check(not R.hatch(p,egg,131),'hatch replay denied')
check(not R.equip(p,{'fake'}),'ownership')
check(not R.equip(p,{p.creatures[1].id,p.creatures[1].id}),'duplicate equip')
check(R.stage(14)==1 and R.stage(15)==2 and R.stage(35)==3,'evolution thresholds')
local creature=p.creatures[1];R.addXP(creature,10000000);check(creature.level==50,'level cap')
check(not R.specialize(p,'fake','Power'),'specialization ownership')
check(R.specialize(p,creature.id,'Power'),'specialization at 25')
check(not R.specialize(p,creature.id,'Speed'),'permanent specialization')
R.collect(p,'mossbun','loss',200);R.drop(p,200);check(#p.cargo==0 and #p.recovery.eggs==1,'recoverable loss')
check(R.recover(p,379) and #p.cargo==1,'recover before expiry')
R.drop(p,400);check(not R.recover(p,581),'expired recovery')
check(#p.eggs==2,'secured eggs survive loss')
check(not R.equip(p,{}) and not R.equip(p,'bad'),'invalid teams')
check(R.damage('Water','Fire',10)>R.damage('Water','Nature',10),'elemental interactions')
check(C.incubation.Common==30 and C.incubation.Mythic==1200,'incubation times')
check(R.newProfile(100).schema==2,'additive schema')
local income=R.newProfile(100)
for t=110,300,10 do R.settleIncome(income,t) end
check(income.coins==1,'fractional income survives frequent collection')
local malformed={income.team[1]};malformed.extra={bad='payload'}
check(not R.equip(income,malformed),'reject extra team keys')
check(not R.trialReady(1,3,{a={dodges=3}}),'strong teams cannot finish before telegraphs resolve')
check(R.trialReady(1,4,{a={dodges=3}}),'normal trial finish after mastery window')
check(not R.trialReady(5,4,{a={dodges=3}}),'fire trial requires interrupt')
check(R.trialReady(5,4,{a={dodges=3,objective=true}}),'fire interrupt satisfies objective')
check(not R.mastered(6,{dodges=3}),'astral capture requires constellation objective')
check(R.mastered(6,{dodges=3,objective=true}),'astral objective and dodge capture')
print('PASS '..count..' mountain rules checks')
