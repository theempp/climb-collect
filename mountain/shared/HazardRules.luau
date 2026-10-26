local Config=if script then require(script.Parent.RaidConfig) else require('./RaidConfig')
local H={}
function H.sample(k,now)
 local c=Config.section(k);local cycle=math.floor(now/c.hazardPeriod);local t=now%c.hazardPeriod
 return if t<c.hazardTell then 'warning' elseif t<c.hazardTell+c.hazardActive then 'active' else 'quiet',cycle
end
function H.contains(x,y,z,halfX,halfZ)
 return math.abs(x)<=halfX and math.abs(z)<=halfZ and y>=-2 and y<=9
end
return H
