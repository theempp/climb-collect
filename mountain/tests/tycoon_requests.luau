local Protocol=require('../shared/UIProtocol')
local Requests=require('../server/UIRequests')
local R=require('../shared/Rules')
local T=R.tycoon
local n=0;local function check(v,m) assert(v,m);n+=1 end
check(Protocol.validate('test:1','Tycoon',{op='collect',slot=0}),'production requests accepted')
for _,v in ipairs({{op='bank',coins=900},{op='assign',slot=0/0,id='c1'},{op='upgrade',path='fake'},{op='collect',slot=9},{op='assign',slot=1,id={}}}) do check(not Protocol.validate('test:1','Tycoon',v),'malformed rejected') end
local p=R.newProfile(100);T.ensure(p,100);T.assign(p,1,'c1',100);T.settle(p,3700,false)
local owned=false;local saves=0
local dispatch=Requests.actions({profiles={get=function() return p end},rules=R,clock=function() return 3700 end,safe=function() return true end,atHome=function() return owned end,save=function() saves+=1 end})
check(not dispatch('player','Tycoon',{op='collect',slot=0}) and p.tycoon.bag.eggs==0,'other plot denied')
owned=true
local now=0;local service=Requests.new({clock=function() now+=1;return now end,handle=dispatch})
check(service.process('player','test:1','Tycoon',{op='collect',slot=0}).ok,'own plot collects')
local result=service.process('player','test:2','Tycoon',{op='bank'});local coins=p.coins
check(result.ok and coins>0,'manual bank')
check(service.process('player','test:2','Tycoon',{op='bank'})==result and p.coins==coins,'correlated replay no double payout')
check(saves==2,'mutations request save')
print('PASS '..n..' tycoon request checks')
