-- Isolated service fixture: real SummitFinish + Profile/Store, fake player/character.
-- Never changes runtime players, active ascent evidence, or a real DataStore.
local H=game.HttpService;local parent=game.ServerScriptService.CC_CoreServer
local m=Instance.new('ModuleScript');m.Name='SummitPendingFixture'
m.Source=H:GetAsync('http://127.0.0.1:8772/src/core/server/SummitFinish.luau',true):gsub("probe.Name='CC_SummitReview'","probe.Name='CC_SummitQAUnit'");m.Parent=parent
local S=require(m);local P=require(parent.Profile);local Store=require(parent.Store);local R=require(game.ReplicatedStorage.CC_Core.ExpeditionRunRules)
local store=Store.memory();local profile=P.new(store,{jobId='pending-isolated',loadTries=1,saveTries=1,backoff=.001});local session=assert(profile:load(997777))
local a=R.begin(1,'Shepherd',100);a.lastMilestone=4;a.merge=true;a.routeEvidence={band=32,distance=10000,sections=12};session.data.expedition.summit=R.default();session.data.expedition.summit.active=a
local ch=Instance.new('Model');local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=Vector3.new(40,3255,12);root.Parent=ch;local hum=Instance.new('Humanoid');hum.Parent=ch
local p={UserId=997777,Parent=true,Character=ch,SetAttribute=function()end}
local callback;local travelled=0
local ctx={sessions={[p]=session},handlers={},Clock={now=function()return 800 end},ExpeditionRun={eligible=function()return {ok=true,run=a}end},push=function()end,fx=function()end}
ctx.Traversal={travel=function(_,pos)travelled+=1;root.Position=pos;return true end}
ctx.transaction=function(_,id,transform,cb) callback=cb;local result=profile:transact(session,id,transform);if result.ok then cb(result) end;return result end
S.init(ctx);store.failAll=true
local result=S.tryFinish(p);assert(result.pending and root.Anchored and not session.data.expedition.summit.pendingResult)
task.wait(8.4)
local snapshot={};S.state(p,snapshot);assert(not root.Anchored and snapshot.summit.status=='saving' and S.isHolding(p),'8-second status/physics ownership')
root.Position=Vector3.new(100,3200,50);task.wait(.4);assert(travelled>0 and (root.Position-Vector3.new(40,3255,12)).Magnitude<1,'pending safe-zone containment')
store.failAll=false;local recovered=profile:recover(session);assert(recovered.ok);callback(recovered);S.state(p,snapshot)
assert(snapshot.summit.status=='confirmed' and not S.isHolding(p) and session.data.coins==150,'confirmation after recovery')
ctx.sessions={};ch:Destroy();m:Destroy();local probe=game.ServerStorage:FindFirstChild('CC_SummitQAUnit');if probe then probe:Destroy() end
return {pass=3,fail=0,kind='isolated real service/memory-store fixture with fake player; eight-second timeout, safe containment, recovery'}
