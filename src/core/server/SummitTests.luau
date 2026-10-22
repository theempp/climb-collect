-- Private memory-store fixtures. Never access real profiles or award runtime players.
local P=require(script.Parent.Profile);local Store=require(script.Parent.Store)
local R=require(game.ReplicatedStorage.CC_Core.ExpeditionRunRules)
local S=require(script.Parent.SummitFinish);local C=require(game.ReplicatedStorage.CC_Core.SummitConfig)
local Tests={}
local function run(seq)
 local a=R.begin(seq,'Shepherd',100);a.routeEvidence={band=32,distance=10000,sections=12};a.lastMilestone=4;a.merge=true;return a
end
local function session(id)
 local store=Store.memory();local p=P.new(store,{jobId='summit-fixtures',loadTries=1,saveTries=1,backoff=.001});local s=assert(p:load(id))
 s.data.expedition.summit=R.default();s.data.expedition.summit.active=run(1);s.data.expedition.summit.nextSeq=2
 return p,s,store
end
function Tests.run()
 local passed,failed,lines=0,0,{}
 local function test(name,fn) local ok,err=pcall(fn);if ok then passed+=1 else failed+=1 end;table.insert(lines,(ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err))) end
 local function finish(p,s,tx,a) return p:transact(s,tx or 'summit:1',function(d) return S.completeData(d,a or run(1),C,500) end) end
 test('two callbacks and reentry award once',function() local p,s=session(993001);assert(finish(p,s).ok);local n=s.data.coins;assert(finish(p,s,'other-callback').alreadyCompleted);assert(s.data.coins==n and s.data.gear.summits.Shepherd==1) end)
 test('no active fresh departure rejects',function() local p,s=session(993002);s.data.expedition.summit.active=nil;assert(not finish(p,s).ok);assert(s.data.coins==0) end)
 test('teleport evidence rejects',function() local p,s=session(993003);local a=run(1);a.invalid='transport';assert(not finish(p,s,nil,a).ok) end)
 test('camp skip and missing bands reject',function() local p,s=session(993004);local a=run(1);a.lastMilestone=3;assert(not finish(p,s,nil,a).ok);a.lastMilestone=4;a.routeEvidence.band=30;assert(not finish(p,s,nil,a).ok) end)
 test('uncertain save displays no confirmed candidate',function() local p,s,store=session(993005);store.failAll=true;local r=finish(p,s);assert(r.pending and s.data.coins==0 and not s.data.expedition.summit.pendingResult);store.failAll=false;assert(p:recover(s).ok and s.data.coins==150) end)
 test('committed lost response recovers once',function() local p,s,store=session(993006);store.failAfterCommit=1;assert(finish(p,s).pending);assert(p:recover(s).ok);assert(finish(p,s,'replayed').alreadyCompleted and s.data.gear.points==200) end)
 test('monotonic marker survives receipt trimming',function() local p,s=session(993007);assert(finish(p,s).ok);s.data.receipts={};assert(finish(p,s,'new-receipt').alreadyCompleted);assert(s.data.coins==150) end)
 test('stale session cannot finish',function() local p,s=session(993008);s.lost=true;assert(not finish(p,s).ok and s.data.coins==0) end)
 test('unreturned previous completion blocks new attempt',function() local p,s=session(993009);assert(finish(p,s).ok);local st=s.data.expedition.summit;st.active=run(2);assert(not finish(p,s,'run2',run(2)).ok) end)
 test('legacy totals preserved without retroactive prizes',function() local p,s=session(993010);s.data.gear.summits.Shepherd=12;assert(finish(p,s).ok);assert(s.data.gear.summits.Shepherd==13 and s.data.coins==50 and s.data.gear.points==60 and not s.data.expedition.earnedCosmetics.summit_first) end)
 test('cargo bank lockers codex and occupied nests unchanged',function()
  local p,s=session(993011);s.data.cargo={{uid='a',kind='creature',species='stub_common_1',rarity='Common',acquiredAt=110},{uid='b',kind='heartstone',tier='Rare',species='stub_rare_1'}};s.data.heartstones={{id='nested',progress=2,required=8}};s.data.home.nests={'nested',''}
  local h=game.HttpService;local before=h:JSONEncode({s.data.cargo,s.data.bank,s.data.codex,s.data.lockers,s.data.home,s.data.heartstones})
  assert(finish(p,s).ok);assert(before==h:JSONEncode({s.data.cargo,s.data.bank,s.data.codex,s.data.lockers,s.data.home,s.data.heartstones}));assert(s.data.expedition.summit.pendingResult.newUnbankedSpecies==1)
 end)
 test('retired sequence never grants',function() local p,s=session(993012);s.data.expedition.summit.retiredThrough=1;assert(not finish(p,s).ok) end)
 test('cosmetic crossed once and successful history bounded',function()
  local p,s=session(993013)
  for i=1,35 do local st=s.data.expedition.summit;st.active=run(i);st.pendingResult=nil;st.returnedThrough=i-1;assert(finish(p,s,'summit:'..i,run(i)).ok) end
  assert(#s.data.expedition.successfulRuns==10);for _,m in C.milestones do assert(s.data.expedition.earnedCosmetics[m.id]) end
  assert(#game.HttpService:JSONEncode(s.data)<20000)
 end)
 test('confirmed result survives sanitize and reconnect',function() local p,s=session(993014);assert(finish(p,s).ok);local d=P.sanitize(s.data);assert(d.expedition.summit.pendingResult.id=='ascent:1' and d.expedition.summit.completedThrough==1) end)
 return {pass=passed,fail=failed,lines=lines}
end
return Tests
