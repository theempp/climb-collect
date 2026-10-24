local T=require('../shared/TraversalRules')
local n=0
local function check(v,label) assert(v,label);n+=1 end
-- No upward assistance outside the authored volume, below it, or beyond its ceiling.
check(T.gravityScale(0,3,0,6,6)==.38,'standing in gravity field reduces gravity')
check(T.gravityScale(0,25,0,6,6)==.38,'jump remains assisted within field')
check(T.gravityScale(7,3,0,6,6)==1,'leaving field removes assistance')
check(T.gravityScale(0,-1,0,6,6)==1,'below field receives ordinary gravity')
check(T.gravityScale(0,31,0,6,6)==1,'above ceiling receives ordinary gravity')
check(T.gravityScale(0,3,7,6,6)==1,'depth boundary is enforced')
check(T.gravityScale(0/0,3,0,6,6)==1,'invalid position cannot create force')
check(T.sandSpeed(0)==0,'sand reverses through zero')
check(math.abs(T.sandSpeed(3)-5)<.001,'sand reaches bounded forward speed')
check(math.abs(T.sandSpeed(9)+5)<.001,'sand reverses direction')
for t=0,120 do check(math.abs(T.sandSpeed(t))<=5,'sand remains walkable against flow') end
print('Traversal checks passed: '..n)
