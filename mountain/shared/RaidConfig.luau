-- All timings and distances are provisional local-playtest tuning, not approved targets.
local Config={version=1,provisional=true,strikeRange=12,pickupRange=12,strikeCadence=.45,reservationSeconds=55,eggRestSeconds=18,seriousFall=32,saveRetrySeconds=5}
local hazards={'root','water','sandstone','prism','fire','gravity'}
local records={}
for k=1,6 do
 records[k]={section=k,hits=2+k,hazard=hazards[k],guardianSpeed=9+k*1.1,approachSeconds=1.8,catchRange=5,attackCooldown=2.5,targetDwell=1.8,respiteSeconds=24,threatSeconds=70,hazardPeriod=10-k*.5,hazardTell=2.5-k*.15,hazardActive=1.2,hazardDamage=12+k*5,normalHealth=950+k*300,trialHealthMultiplier=1.6,joinHealth=350+k*80,companionXP=200*k,contributionFraction=.03}
end
function Config.section(k) return records[k] end
return Config
