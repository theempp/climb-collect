local J=require('../server/Journey')
local R=require('../shared/Rules')
local n=0
local function check(v,m) assert(v,m);n+=1 end
local p=R.newProfile(0);p.schema=1;R.collect(p,'mossbun','test',0)
local ready,origin,moveOK=true,true,false
local location='mountain';local destinationSeen
local j=J.new({profile=function()return p end,ready=function()return ready end,origin=function()return origin end,
 resolve=function(_,dest) if dest=='refuge' then return {plot=2,area='sanctuary'} end end,
 move=function(_,target) destinationSeen=target.plot;return moveOK end,extract=R.extract,
 arrived=function(_,target) location=target.area end})
check(not j.go({},'locked') and #p.cargo==1 and #p.eggs==0,'locked destination cannot extract')
check(not j.go({},'refuge') and #p.cargo==1 and location=='mountain','failed movement cannot extract or change area')
moveOK=true;origin=false;check(not j.go({},'refuge') and #p.cargo==1,'invalid origin denied')
origin=true;ready=false;check(not j.go({},'refuge') and #p.cargo==1,'dead unsafe or combat player denied')
ready=true;check(j.go({},'refuge') and destinationSeen==2 and location=='sanctuary' and #p.cargo==0 and #p.eggs==1,'successful return goes to resolved owned plot and extracts once')
check(j.go({},'refuge') and #p.eggs==1,'repeat return cannot duplicate eggs')
local real=p;p=nil;check(not j.go({},'refuge'),'unhealthy profile cannot travel');p=real
local player={};local recursive=false
local nested
nested=J.new({profile=function()return p end,ready=function()return true end,origin=function()return true end,resolve=function()return {} end,
 move=function()recursive=nested.go(player,'refuge');return true end,extract=R.extract,arrived=function()end})
check(nested.go(player,'refuge') and recursive==false,'yielding or reentrant move locked per connection')
print('PASS '..n..' journey checks')
