local S=require('../server/SanctuarySessions')
local n=0
local function check(v,m) assert(v,m);n+=1 end
local s=S.new(8)
local a,b={},{}
check(s.reserve(101,a)==1,'first player gets a plot')
check(s.reserve(102,b)==2,'simultaneous players distinct')
check(s.reserve(101,a)==1,'repeat reservation idempotent')
check(s.reserve(101,{})==nil,'duplicate connection cannot steal')
check(s.plot(101,{})==nil,'wrong session cannot read owned slot')
s.release(101,{})
check(s.plot(101,a)==1,'stale removal cannot release current owner')
s.release(101,a)
local a2={};check(s.reserve(101,a2)==1,'same server reconnect reclaims available slot')
for uid=103,108 do check(s.reserve(uid,uid)==uid-100,'remaining slots fill uniquely') end
check(s.reserve(109,{})==nil,'ninth join denied without collision')
s.release(104,104);local c={};check(s.reserve(109,c)==4,'released slot reused safely')
check(s.plot(104,104)==nil,'departed user no longer owns reused slot')
check(s.reserve(0,{})==nil and s.reserve(1.5,{})==nil,'invalid user ids rejected')
-- Studio test players use negative integral IDs.
local t=S.new(2);check(t.reserve(-1,a)==1 and t.reserve(-2,b)==2,'Studio users supported')
print('PASS '..n..' sanctuary reservation checks')
