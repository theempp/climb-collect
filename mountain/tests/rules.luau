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
-- EggOdds (C19): the shared table replaces Main's roll with identical results; odds shown = odds used.
local O=require('../shared/EggOdds')
local function oldRoll(k,r) for i=1,6 do local s=C.species[(k-1)*6+i];r-=s.weight;if r<=0 then return s.id end end;return C.species[k*6].id end
for k=1,6 do
 local same=true;for i=0,199 do local r=i*.5;if O.pick(k,r)~=oldRoll(k,r) then same=false end end
 check(same and O.pick(k,99.999999)==oldRoll(k,99.999999),'odds grid matches the old roll '..k)
 local sum=0;for _,s in ipairs(O.table(k)) do sum+=s.weight end;check(sum==100,'odds table sums to 100 '..k)
 local c=O.byColour(k)
 check(#c==4 and c[1].colour=='Blue' and c[1].percent==68 and c[2].colour=='Gold' and c[2].percent==18 and c[3].colour=='Violet' and c[3].percent==10 and c[4].colour=='Prismatic' and c[4].percent==4,'colour sums 68/18/10/4 '..k)
end
check(O.table(0)==nil and O.table(7)==nil and O.table(1.5)==nil and O.table(0/0)==nil and O.table('1')==nil and O.pick(7,10)==nil and O.pick(1,nil)==nil and O.byColour(0)==nil,'invalid odds input')
math.randomseed(241026)
for k=1,6 do
 local n=100000;local hits={}
 for _=1,n do local c=O.colourOf[C.byId[O.pick(k,math.random()*100)].rarity];hits[c]=(hits[c] or 0)+1 end
 local within=true;for _,c in ipairs(O.byColour(k)) do if math.abs((hits[c.colour] or 0)*100/n-c.percent)>1 then within=false end end
 check(within,'100k picks within 1 pt '..k)
end
-- Shown = used: every displayed item's bars equal its rolled frequencies on an exact midpoint grid.
local shown=0
for id,item in pairs(O.items) do
 local d=O.display(id)
 if item.currency~='coin' then check(d==nil,'robux odds hidden '..id) else
  shown+=1;local hits={}
  for i=0,9999 do local c=O.colourOf[C.byId[O.pick(d.section,(i+.5)/100)].rarity];hits[c]=(hits[c] or 0)+1 end
  local same=d.section==item.section;for _,c in ipairs(d.colours) do if hits[c.colour]~=c.percent*100 then same=false end end
  check(same,'shown = used '..id)
 end
end
check(shown==1 and O.display('meadow_egg').section==1 and O.display('mystery_egg')==nil and O.display('egg_luck')==nil and O.display('nope')==nil and O.display(nil)==nil,'only the meadow egg shows odds')
print('PASS '..count..' mountain rules checks')
