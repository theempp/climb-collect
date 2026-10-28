-- C02 co-op Guardian/Trial scaling for 1-2 players (duo parties). The second member scales health by the
-- PROPOSED duo multiplier; extra strangers beyond two keep the legacy additive join health.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local C={}
function C.health(base,members,trial,joinHealth)
 local list=if trial then Config.duo.trialHealth else Config.duo.guardianHealth
 local m=math.max(1,math.floor(members))
 return base*list[math.min(m,#list)]+math.max(0,m-#list)*(joinHealth or 0)
end
return C
