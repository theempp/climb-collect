local J=require('../server/Journey');local R=require('../shared/Rules');local Run=require('../shared/RunRules')
local p=R.newProfile(0);local player={};local moved=0;local origin=true;local n=0
local function check(v,label) assert(v,label);n+=1 end
local j=J.new({profile=function() return p end,ready=function() return true end,origin=function() return origin end,
 resolve=function(_,destination) return if destination=='refuge' then {} else nil end,move=function() moved+=1;return true end,
 extract=function() error('new run travel must never bank') end,arrived=function() end,forfeit=function(_,reason) return Run.forfeit(p,reason) end})
Run.strike(p,{id='egg',runId='r1',species='mossbun',section=1,hitsRequired=1},0);Run.pickup(p,'r1')
local ok,reason=j.go(player,'refuge')
check(not ok and reason=='abandon_confirmation_required' and moved==0 and p.run~=nil,'confirmation cancel retains run')
check(not j.go(player,'refuge','wrong') and moved==0 and p.run~=nil,'stale confirmation cannot abandon newer run')
origin=false;check(not j.go(player,'refuge','r1') and p.run~=nil,'fresh origin validation before forfeit')
origin=true;check(not j.go(player,'locked','r1') and p.run~=nil,'invalid shortcut never moves or forfeits')
local owned=#p.creatures;local coins=p.coins
check(j.go(player,'refuge','r1') and moved==1 and p.run==nil and #p.creatures==owned and p.coins==coins,'confirmed abandon loses only unsecured')
check(j.go(player,'refuge') and moved==2,'secured travel grants nothing')
print('PASS '..n..' run journey checks')
