local ClientState = require('../client/UI/ClientState')
local Requests = require('../server/UIRequests')
local Rules = require('../shared/Rules')
local checks = 0
local function check(value,message) assert(value,message); checks+=1 end
check(type(ClientState.new)=='function','client store constructor exists')
local function signal()
 local handlers={}
 local s={}
 function s:Connect(fn)
  local connection={Connected=true}; handlers[connection]=fn
  function connection:Disconnect() self.Connected=false; handlers[self]=nil end
  return connection
 end
 function s:fire(...)
  local snapshot=table.clone(handlers)
  for c,fn in pairs(snapshot) do if c.Connected then fn(...) end end
 end
 function s:count() local n=0;for _ in pairs(handlers) do n+=1 end;return n end
 return s
end
local function harness(late)
 local elapsed=0;local jobs={};local sent={}
 local runtime={monotonic=function() return elapsed end,epoch=function() return 1000+elapsed end,
  clock=function() return 500+elapsed end,token=function() return 'session-123' end}
 function runtime.delay(seconds,fn) local job={at=elapsed+seconds,fn=fn};jobs[job]=true;return job end
 function runtime.cancel(job) jobs[job]=nil end
 local event,result,added,removed=signal(),signal(),signal(),signal()
 local request={}
 function request:FireServer(id,action,payload) table.insert(sent,{id=id,action=action,payload=payload}) end
 local folder={Event={OnClientEvent=event},ChildAdded=added,ChildRemoved=removed}
 function folder:FindFirstChild(name) return self[name] end
 if not late then folder.UIRequest=request;folder.UIResult={OnClientEvent=result} end
 local h={folder=folder,event=event,result=result,sent=sent}
 function h:advance(seconds)
  elapsed+=seconds
  local due={};for job in pairs(jobs) do if job.at<=elapsed then table.insert(due,job) end end
  for _,job in ipairs(due) do if jobs[job] then jobs[job]=nil;job.fn() end end
 end
 function h:attach()
  folder.UIResult={OnClientEvent=result};added:fire(folder.UIResult)
  folder.UIRequest=request;added:fire(request)
 end
 function h:removeResult() folder.UIResult=nil;removed:fire() end
 function h:jobs() local n=0;for _ in pairs(jobs) do n+=1 end;return n end
 function h:server(fn) request.FireServer=function(_,id,action,payload) table.insert(sent,{id=id,action=action,payload=payload});fn(id,action,payload) end end
 function h:brokenClock() runtime.clock=function() error('clock offline') end end
 h.store=ClientState.new(folder,runtime)
 return h
end
local h=harness(false);local s=h.store;local events={}
check(#h.sent==0,'no State request before UI listener')
local unsubscribe=s:subscribe(function(kind,payload) table.insert(events,{kind=kind,payload=payload}) end)
check(#h.sent==1 and h.sent[1].action=='State','first subscription initiates handshake after listener')
check(h.sent[1].id=='session-123:1','wire ID uses monotonic session sequence')
h.event:fire('state',{coins=42,serverNow=2000,team={},creatures={},ui={serverClock=500}})
check(s.status=='ready' and s.profile.coins==42,'only authoritative snapshot makes store ready')
h:advance(2)
check(s:now()==2002 and s:clock()==502,'epoch estimate and synchronized combat clock remain separate')
h.result:fire({id=h.sent[1].id,action='State',ok=true,message='Loaded'})
local callbacks=0
local intent={id='c1',choice='Power'}
local id=s:request('Specialize',intent,function(r) check(r.ok,'late successful ack reaches callback');callbacks+=1 end)
intent.choice='Guard'
check(s.profile.coins==42 and s.lastResult.action=='State','request never grants optimistic success or mutates profile')
check(s:request('Specialize',{id='c2',choice='Guard'})==nil and #h.sent==2,'double tap cannot create second mutation')
h.result:fire({id=id,action='Train',ok=true,message='wrong action'})
check(s.pending[id]~=nil and callbacks==0,'mismatched ack cannot finish intent')
h:advance(8)
check(s.pending[id].status=='timeout' and callbacks==0,'eight second timeout preserves unknown outcome')
check(#h.sent==2,'mutations are never automatically retried')
check(s:request('Specialize',{})==nil,'timed out mutation retains action lock')
s.pending[id].payload.choice='Vitality'
check(s:retry(id) and h.sent[3].id==id and h.sent[3].payload.choice=='Power','manual retry retains exact ID and private original intent')
check(not s:retry(id),'cannot retry a currently in-flight request')
h.result:fire({id=id,action='Specialize',ok=true,message='Confirmed',data={level=25}})
check(s.pending[id]==nil and s.lastResult.ok and callbacks==1,'ack resolves pending once')
h.result:fire({id=id,action='Specialize',ok='true',message='Invalid'})
check(s.lastResult.message=='Confirmed','malformed success flag cannot overwrite authoritative result')
h.result:fire({id=id,action='Specialize',ok=true,message='Duplicate'})
check(callbacks==1 and s.lastResult.message=='Confirmed','duplicate result has no duplicate reveal or callback')
local train=s:request('Train','c1')
h:advance(8)
h.result:fire({id=train,action='Train',ok=false,message='Not at refuge'})
check(s.pending[train]==nil and s.lastResult.ok==false,'late rejection reconciles timeout honestly')
local train2=s:request('Train','c1')
h.result:fire({id=train2,action='Train',ok=true,message='Trained'})
check(s.profile.coins==42,'successful ack waits for server snapshot to change wallet')
h.event:fire('battle',{hp=50});check(s.battle.hp==50,'battle snapshot propagated')
h.event:fire('battle',false);check(s.battle==false,'battle cancellation clears stale encounter')
h.event:fire('context',{atRefuge=true,nearCheckpoint=false})
check(s.profile.ui.atRefuge==true and s.profile.ui.nearCheckpoint==false and s.profile.ui.serverClock==500,'context refresh merges authoritative proximity without losing cooldown clock data')
h.event:fire('context',{atRefuge=false,serverClock=520})
h:brokenClock();h:advance(1)
check(s:clock()==521,'server clock falls back to latest authoritative context anchor')
for _,kind in ipairs({'open','toast','save'}) do h.event:fire(kind,kind..' payload');check(events[#events].kind==kind,'context event '..kind..' forwarded') end
local hudPayload={kind='calm',section=2,reason='step'};h.event:fire('hud',hudPayload)
check(events[#events].kind=='hud' and events[#events].payload==hudPayload,'typed hud event forwarded unchanged')
local count=#events;h.event:fire('knock',{});check(#events==count,'unlisted kinds still dropped')
local before=#events;unsubscribe();h.event:fire('toast','after disconnect')
check(#events==before,'subscription cleanup removes listener')
s:destroy()
check(h.event:count()==0 and h.result:count()==0 and h.folder.ChildAdded:count()==0 and h.folder.ChildRemoved:count()==0 and h:jobs()==0,'destroy releases signals and timers')
check(s:request('Train','c1')==nil and not s:retry(train2),'destroyed store cannot send requests')
local late=harness(true);local received={}
late.store:subscribe(function(kind,payload) table.insert(received,{kind,payload}) end)
check(late.store.status=='error' and #late.sent==0,'missing correlated remotes are unavailable without legacy fallback')
late:attach()
check(#late.sent==1 and late.sent[1].action=='State','late remote arrival recovers state handshake')
late.event:fire('state',{coins=3,serverNow=1000})
check(late.store.status=='ready','late service recovers ready status')
late.store:destroy()
local stale=harness(false)
stale.store:subscribe(function() end)
local stateId=stale.sent[1].id
stale:advance(8)
check(stale.store.status=='error' and stale.store.pending[stateId].status=='timeout','initial State timeout exposes retryable loading error')
check(stale.store:retry(stateId) and stale.sent[2].id==stateId,'State retry also keeps original correlation')
stale.event:fire('state',{coins=10,serverNow=1008})
stale.result:fire({id=stateId,action='State',ok=true,message='Loaded'})
check(stale.store.status=='ready','late snapshot and ack restore loading')
for i=1,160 do
 local requestId=stale.store:request('Train','c1')
 stale.result:fire({id=requestId,action='Train',ok=true,message='ok'})
end
local n=0;for _ in pairs(stale.store.pending) do n+=1 end
check(n==0 and stale:jobs()==0,'many completed actions leave no pending entries or timers')
check(#stale.store._history==64,'completed correlation history remains bounded under repeated actions')
stale.store:destroy()
local transport=harness(false)
transport.store:subscribe(function() end)
transport.result:fire({id=transport.sent[1].id,action='State',ok=true,message='Loaded'})
transport.event:fire('state',{coins=25,serverNow=1000})
transport:server(function() error('network unavailable') end)
local failed=transport.store:request('CollectIncome')
check(transport.store.pending[failed].status=='timeout' and transport.store.profile.coins==25,'transport exception exposes unknown outcome without inventing success')
transport:removeResult()
check(transport.store.status=='error' and not transport.store:retry(failed),'missing result connection prevents unsafe unobservable retry')
transport:attach()
check(transport.store.status=='ready' and #transport.sent==2,'restored transport preserves intent without automatic replay')
transport.result:fire({id=failed,action='CollectIncome',ok=true,message='Collected',data={coins=0}})
check(transport.store.pending[failed]==nil and transport.store.lastResult.ok,'late success reconciles timeout without retry')
transport.store:destroy()
-- Run the real server idempotency boundary and real training rules through the
-- client transport. Delay/drop only the network reply, never the mutation.
local integrated=harness(false)
local player={UserId=1};local p=Rules.newProfile(1000);p.coins=100
local handler=Requests.actions({profiles={get=function() return p end},rules=Rules,
 safe=function() return true end,atRefuge=function() return true end,rebuildTeam=function() end,
 publish=function() integrated.event:fire('state',{coins=p.coins,creatures=p.creatures,team=p.team,serverNow=1000}) end})
local server=Requests.new({clock=function() return 100 end,minInterval=0,handle=handler})
local drop=false
integrated:server(function(requestId,action,payload)
 local reply=server.process(player,requestId,action,payload)
 if not drop then integrated.result:fire(reply) end
end)
integrated.store:subscribe(function() end)
drop=true
local paid=integrated.store:request('Train','c1')
check(p.coins==85 and integrated.store.profile.coins==100,'real paid mutation may finish while client remains unconfirmed')
integrated:advance(8)
check(integrated.store.pending[paid].status=='timeout','dropped real server result exposes unknown outcome')
drop=false
check(integrated.store:retry(paid),'paid intent offers same-ID retry')
check(p.coins==85 and integrated.store.lastResult.ok and integrated.store.lastResult.data.creature.level==2,'real server cached reply confirms once without charging twice')
local lateSuccess=integrated.store:request('Hatch','missing')
check(integrated.store.lastResult.ok==false,'real rule rejection never becomes a successful reveal')
check(not integrated.store:retry(lateSuccess),'completed rejection cannot be replayed from UI retry')
integrated.store:destroy()
local production=harness(false)
local productionId=production.store:request('Tycoon',{op='bank'})
check(productionId~=nil and production.sent[1].action=='Tycoon','production hub sends correlated intents')
production.event:fire('state',{coins=1,team={'c1'},creatures={{id='c1'}},serverNow=1000})
production.event:fire('production',{coins=2,tycoon={slots=2},serverNow=1001})
check(production.store.profile.coins==2 and production.store.profile.tycoon.slots==2 and production.store.profile.team[1]=='c1','compact production update preserves other profile fields')
production.store:destroy()
print('PASS '..checks..' UI client state checks')
