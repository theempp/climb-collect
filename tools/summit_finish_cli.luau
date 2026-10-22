local R=require('../src/core/shared/ExpeditionRunRules')
local C={bandHeight=100,minimumSeconds=60,requiredCamps=4}
local n=0;local function check(v,m) assert(v,m);n+=1 end
check(not R.eligible(nil,{grounded=true},C).ok,'no departure no award')
check(R.begin(1,'Ledge',100)==nil,'closed route')
local a=R.begin(1,'Shepherd',100);check(a~=nil,'open departure')
R.reduce(a,{kind='sample',at=101,y=50,distance=0,valid=true,nearRoute=true},C)
R.reduce(a,{kind='sample',at=102,y=3050,distance=3000,valid=false,nearRoute=true},C)
check(not R.eligible(a,{grounded=true,at=200},C).ok,'teleport rejected')
a=R.begin(2,'Shepherd',100)
R.reduce(a,{kind='camp',index=4,at=100},C);check(a.lastMilestone==0,'skipped camps rejected')
for i=0,31 do R.reduce(a,{kind='sample',at=100+i*5,y=50+i*100,distance=100,valid=true,nearRoute=true},C) end
for i=1,4 do R.reduce(a,{kind='camp',index=i,at=300+i},C) end
R.reduce(a,{kind='section',id='Shepherd:test',route='Shepherd',at=310},C)
check(R.eligible(a,{grounded=true,at=320},C).ok,'ordered observed ascent')
R.reduce(a,{kind='travel',travel='homeEnter',at=321},C);check(a.seq==2 and not a.invalid,'home preserves identity')
R.reduce(a,{kind='travel',travel='test',at=322},C);check(a.invalid,'debug travel never grants')
print('Summit run rules '..n..'/'..n)
