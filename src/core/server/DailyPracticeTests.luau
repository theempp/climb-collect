local T={}
function T.run()
 local rs=game.ReplicatedStorage.CC_Core
 assert(rs:FindFirstChild('DailyPracticeRules'),'DailyPracticeRules missing')
 local R=require(rs.DailyPracticeRules);local P=require(script.Parent.Profile);local n=0
 local function check(v,m) assert(v,m);n+=1 end
 local d=P.default();local config={target=7}
 check(R.dayKey(86400)==1 and R.dayKey(86399)==0,'UTC rollover')
 for day=0,2 do check(#R.descriptor(day).sections==({2,3,5})[day+1],'three routes') end
 check(not R.advance({next=1,sections={'Practice:1','Practice:2'}},'Practice:2',true),'order enforced')
 check(not R.advance({next=1,sections={'Practice:1'}},'Practice:1',false),'course bounds')
 check(R.credit(d,10,config).ok,'first stamp');check(not R.credit(d,10,config).credited,'same day once')
 for _,day in {12,15,20,21,25,31} do R.credit(d,day,config) end
 check(d.dailyPractice.stamps==7 and d.expedition.earnedCosmetics.practice_pennant,'seventh atomic cosmetic')
 check(not R.credit(d,31,config).credited,'milestone replay');R.credit(d,32,config);check(d.dailyPractice.stamps==7,'stops at milestone')
 check(not d.gear.training.unlocked['2'] and not d.gear.training.completed['2'],'free daily never unlocks paid lesson')
 local old=P.sanitize(d);check(old.dailyPractice.stamps==7,'round trip durable')
 local Store=require(script.Parent.Store);local store=Store.memory();local profile=P.new(store,{jobId='daily-private-fixture',loadTries=1,saveTries=1,backoff=.001});local s=assert(profile:load(994001))
 store.failAll=true;local pending=profile:transact(s,'dailypractice:994001:50',function(data)return R.credit(data,50,config)end)
 check(pending.pending and s.data.dailyPractice.stamps==0,'uncertain save does not expose stamp')
 store.failAll=false;check(profile:recover(s).ok and s.data.dailyPractice.stamps==1,'recovery credits once')
 check(profile:transact(s,'dailypractice:994001:50',function(data)return R.credit(data,50,config)end).dup and s.data.dailyPractice.stamps==1,'same receipt replay')
 s.data.receipts={};check(not profile:transact(s,'dailypractice:994001:50-retry',function(data)return R.credit(data,50,config)end).credited and s.data.dailyPractice.stamps==1,'day marker survives trimmed receipts')
 store.failAfterCommit=1;check(profile:transact(s,'dailypractice:994001:51',function(data)return R.credit(data,51,config)end).pending,'lost response fixture');check(profile:recover(s).ok and s.data.dailyPractice.stamps==2,'lost response recovered once')
 return {pass=n,fail=0,kind='pure rules/profile fixtures'}
end
return T
