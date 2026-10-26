-- Provisional local-review tuning. No ownership or currency mutations.
local R={walk=16,sprint=27,carryMultiplier=.9,requestInterval=.08}
function R.speed(sprint,carrying)
 return (if sprint then R.sprint else R.walk)*(if carrying then R.carryMultiplier else 1)
end
function R.intent(value,now,lastPress)
 return type(value)=='boolean' and (not value or now-lastPress>=R.requestInterval)
end
function R.active(wanted,health,seated,platformStand)
 return wanted==true and health>0 and not seated and not platformStand
end
return R
