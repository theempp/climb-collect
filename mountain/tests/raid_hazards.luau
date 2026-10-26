local ok,H=pcall(require,'../shared/HazardRules')
assert(ok and H.sample,'authored hazard rules exist')
local Config=require('../shared/RaidConfig');local n=0
local function check(v,label) assert(v,label);n+=1 end
for k=1,6 do
 local c=Config.section(k);local phase,cycle=H.sample(k,0)
 check(phase=='warning' and cycle==0,'visible warning before active')
 check(H.sample(k,c.hazardTell+.1)=='active','active window')
 check(H.sample(k,c.hazardTell+c.hazardActive+.1)=='quiet','safe gap')
 check(H.contains(2,3,2,16,11) and not H.contains(0,30,0,16,11),'bounded vertical danger')
 check(not H.contains(-72,3,0,16,11),'downhill lane stays clear')
end
print('PASS '..n..' authored hazard checks')
