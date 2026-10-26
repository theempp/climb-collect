local R=require('../shared/MovementRules')
local checks=0
local function check(v,m) assert(v,m);checks+=1 end
check(R.speed(false,false)==16,'walk')
check(R.speed(true,false)==27,'sprint')
check(math.abs(R.speed(false,true)-14.4)<.001,'carry walk')
check(math.abs(R.speed(true,true)-24.3)<.001,'carry sprint')
check(R.intent(true,10,0)==true,'boolean request')
check(R.intent(false,10,10)==true,'release never throttled')
check(R.intent(true,10,10)==false,'press paced')
for _,v in ipairs({1,'true',{},math.huge}) do check(not R.intent(v,10,0),'malformed request') end
check(not R.intent(nil,10,0),'nil rejected')
check(R.active(true,100,false,false),'alive sprint')
check(not R.active(true,0,false,false),'dead')
check(not R.active(true,100,true,false),'seated')
check(not R.active(true,100,false,true),'platform stand')
check(not R.active(false,100,false,false),'released')
print('PASS '..checks..' movement policy checks')
