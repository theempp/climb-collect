local R=require('../src/core/shared/MovementRules')
local C=require('../src/core/shared/MovementConfig')
local count=0
local function check(name,fn) assert(fn(),name);count+=1 end
local function sample(extra)
 local s={zone='mountain',mode='ground',alive=true,grounded=true,moving=true,locked=false,stamina=50,maxStamina=100}
 for k,v in extra or {} do s[k]=v end
 return s
end
local function step(extra,intent) return R.step(intent or {requested=true,exhausted=false},sample(extra),0.2,C) end
check('lobby unlimited',function() local r=step({zone='lobby'});return r.walkSpeed==22 and r.stamina>=50 and not r.requested end)
check('mountain walk recovers',function() local r=step(nil,{requested=false});return r.walkSpeed==16 and math.abs(r.stamina-52.6)<0.001 end)
check('moving sprint drains shared pool',function() local r=step();return r.walkSpeed==23 and r.stamina==48 and r.sprinting end)
check('idle intent no drain',function() local r=step({moving=false});return r.requested and not r.sprinting and r.stamina>50 end)
check('exhaustion requires retoggle',function() local r=step({stamina=1});local again=R.step(r,sample({stamina=40}),0.2,C);return r.exhausted and not r.requested and r.walkSpeed==16 and not again.sprinting end)
check('locks win over lobby',function() local r=step({zone='lobby',locked=true});return r.walkSpeed==0 and not r.requested end)
check('jump clears intent',function() local r=step({grounded=false,mode='fall'});return r.walkSpeed==16 and r.stamina==50 and not r.requested end)
for _,mode in {'climb','rope','hanging','flight','travel'} do
 check(mode..' preserves traversal stamina',function() local r=step({mode=mode});return r.walkSpeed==0 and r.stamina==50 and not r.requested end)
end
check('brief contact loss keeps sprint pace',function() local r=step({grounded=false,mode='fall',airborneFor=0.2});return r.requested and r.walkSpeed==23 and r.stamina==50 and not r.sprinting end)
check('long air clears sprint',function() local r=step({grounded=false,mode='fall',airborneFor=0.6});return not r.requested and r.walkSpeed==16 end)
check('lobby air keeps lobby pace',function() local r=step({zone='lobby',grounded=false,mode='fall',airborneFor=0.6});return r.walkSpeed==22 and not r.requested end)
check('exhausted brief air does not sprint',function() local r=step({grounded=false,mode='fall',airborneFor=0.1,stamina=5},{requested=true,exhausted=true});return not r.requested and r.walkSpeed==16 end)
check('home no sprint',function() local r=step({zone='home'});return r.walkSpeed==16 and not r.sprinting end)
check('clamp maximum',function() return step({stamina=140,maxStamina=100}).stamina<=100 end)
check('invalid budget numbers reject',function() local _,ok=R.advanceBudget(8,0/0,23,0,C);return not ok end)
check('legitimate running passes',function() local credit=8;for _=1,100 do local ok;credit,ok=R.advanceBudget(credit,0.15,23,3.45,C);if not ok then return false end end;return true end)
check('sustained overspeed rejects',function() local credit=8;for _=1,100 do local ok;credit,ok=R.advanceBudget(credit,0.15,23,9,C);if not ok then return true end end;return false end)
check('rejection does not refill budget',function() local credit,ok=R.advanceBudget(1,0.1,16,80,C);return not ok and credit<=1 end)
print('Movement rules: '..count..'/'..count..' passed')
