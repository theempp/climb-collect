-- Real service code with fake player, fake movement API, and private fixture data.
local H=game.HttpService;local parent=game.ServerScriptService.CC_CoreServer;local P=require(parent.Profile)
local api=Instance.new('Folder');api.Name='CC_QACheckpointAPI';api.Parent=game.ServerStorage
local called={};local set=Instance.new('BindableFunction');set.Name='SetCheckpoint';set.OnInvoke=function(_,name)table.insert(called,name or 'clear')end;set.Parent=api
for _,name in {'MovementObserved','AuthorizedTravel','CheckpointConfirmed'} do local e=Instance.new('BindableEvent');e.Name=name;e.Parent=api end
local function source(name)
 local m=Instance.new('ModuleScript');m.Name=name..'ReconnectFixture';m.Source=H:GetAsync('http://127.0.0.1:8772/src/core/server/'..name..'.luau',true):gsub('CC_CheckpointAPI','CC_QACheckpointAPI'):gsub("probe.Name='CC_SummitReview'","probe.Name='CC_SummitQAReconnect'");m.Parent=parent;return m,require(m)
end
local em,E=source('ExpeditionRun');local sm,S=source('SummitFinish')
local p={UserId=998888,Parent=true};local s={data=P.default()};local R=require(game.ReplicatedStorage.CC_Core.ExpeditionRunRules)
local st=R.default();s.data.expedition.summit=st;st.active=R.begin(1,'Shepherd',100);st.active.lastMilestone=2;st.active.lastCheckpoint='Camp2';st.active.lastPos={150,1500,100};st.nextSeq=2
local movements={};local ctx={sessions={[p]=s},Profile=P,handlers={},on=function()end,Clock={now=function()return 500 end},toast=function()end,push=function()end,fx=function()end}
ctx.Traversal={travel=function(_,pos,kind)table.insert(movements,{position=tostring(pos),kind=kind});return true end}
ctx.transaction=function(_,_,fn,cb)local r=fn(s.data);if r.ok then cb(r)end;return r end
E.init(ctx);S.init(ctx);E.onLoaded(p,s);task.wait(1.8)
assert(called[1]=='Camp2' and called[2]=='Camp2' and movements[1].kind=='reconnect','checkpoint allowance restored before position')
assert(st.active.lastMilestone==2 and st.active.routeEvidence.band==0,'reconnect granted no new evidence')
E.onLeave(p);st.active=nil;st.lobbyResume=true;st.completedThrough=1;st.returnedThrough=1;st.acknowledgedSeq=1;s.data.highestCamp=4
S.onLoaded(p,s);task.wait(2.2);assert(called[#called]=='clear' and movements[#movements].kind=='summitReturn','acknowledged empty-cargo resume stays at bank')
E.begin(p,'Waterfall');assert(st.active and st.active.seq==2 and not st.lobbyResume,'fresh departure clears lobby resume')
E.onLeave(p);ctx.sessions={};api:Destroy();em:Destroy();sm:Destroy();local probe=game.ServerStorage:FindFirstChild('CC_SummitQAReconnect');if probe then probe:Destroy() end
return {pass=4,fail=0,kind='real services / isolated fake player and checkpoint API; not real network reconnect',movementOrder=movements}
