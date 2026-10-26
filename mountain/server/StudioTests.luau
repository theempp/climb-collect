-- Explicit Studio-only test suite, never runs automatically or alters a real player.
local T={}
function T.run()
 assert(game:GetService('RunService'):IsStudio(),'Studio only')
 local P=require(script.Parent.Profiles);local Store=require(script.Parent.Store)
 local R=require(game.ReplicatedStorage.MountainShared.Rules);local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 local checks={};local function check(name,value) assert(value,name);table.insert(checks,name) end
 local backend=Store.memory();local a=P.newForTests(backend,'test-a');local b=P.newForTests(backend,'test-b');local player={UserId=92833001}
 local p=a.load(player);check('new schema loads',p and p.schema==2)
 check('contended session rejects',not b.load(player))
 p.coins=97;R.collect(p,'mossbun','fixture',100);R.extract(p);R.incubate(p,p.eggs[1].id,100)
 check('release save succeeds',a.save(player,true))
 local q=b.load(player);check('reconnect retains coins and incubation',q and q.coins==97 and q.eggs[1].readyAt==130)
 check('early hatch rejected',not R.hatch(q,q.eggs[1].id,129));check('offline hatch ready',R.hatch(q,q.eggs[1].id,130))
 R.collect(q,'mossbun','recover-fixture',200);R.drop(q,200);b.save(player,true)
 q=a.load(player);check('recovery survives reconnect',q.recovery and #q.recovery.eggs==1 and q.recovery.expires==380)
 backend.failAll=true;check('save failure freezes mutations',not a.save(player,false) and not a.get(player))
 backend.failAll=false;check('save retry resumes',a.save(player,false) and a.get(player)==q)
 q.coins=121;backend.failAfterCommit=1;check('uncertain response retry safe',a.save(player,false));check('no duplicate currency',a.get(player).coins==121)
 local payload={q.team[1]};payload.extra='unsafe';check('dictionary team rejected',not R.equip(q,payload))
 q.unsupported={};q.unsupported.self=q.unsupported;check('serialization failure clears busy',not a.save(player,false) and not a.sessions[player].busy);q.unsupported=nil
 check('serialization repair resumes save',a.save(player,true))
 backend.failAll=true;check('failed load does not default',not b.load(player));backend.failAll=false
 check('failed load preserved durable state',b.load(player).coins==121);b.save(player,true)
 backend:update('u92833002',function() return {profile={schema=99},lock=nil} end)
 check('unknown schema never overwritten',not a.load({UserId=92833002}))
 local _,saved=backend:read('u92833002');check('unknown schema retained',saved.profile.schema==99)
 local slowBackend=Store.memory();local slowOnce=false
 local delayed={}
 function delayed:update(key,transform)
  if slowOnce then slowOnce=false;task.wait(13) end
  return slowBackend:update(key,transform)
 end
 local slow=P.newForTests(delayed,'slow-owner');local leaving={UserId=92833005}
 local last=slow.load(leaving);last.coins=10;slowOnce=true
 local autosaveDone=false
 task.spawn(function() slow.save(leaving,false);autosaveDone=true end)
 task.wait(.1);last.coins=42
 check('slow autosave release yields safely',not slow.save(leaving,true))
 local finish=os.clock()+8
 while slow.sessions[leaving] and os.clock()<finish do task.wait(.1) end
 local _,durable=slowBackend:read('u92833005')
 check('slow autosave completes',autosaveDone)
 check('final leave snapshot flushed',durable.profile.coins==42 and durable.lock==nil and slow.sessions[leaving]==nil)
 local profile=R.newProfile(100)
 for k=1,6 do
  check('gate '..k,R.canEnter(profile,k));check('normal win '..k,R.winGuardian(profile,k,false));local id='trial'..k;check('trial reward '..k,R.run.strike(profile,{id=id,runId=id,species=C.guardians[k].id,section=k,trial=true,hitsRequired=1},100) and R.run.pickup(profile,id) and R.run.secure(profile,id));check('duplicate capture '..k,not R.winGuardian(profile,k,true))
 end
 check('six permanent guardian captures',#profile.creatures==9)
 local defense=require(script.Parent.Competition)
 check('register defense snapshot',defense.register(profile,92833003))
 local challenger=R.newProfile(os.time());local ok,result=defense.challenge(challenger,92833004,92833003)
 check('offline snapshot challenge',ok and type(result.rounds)=='number')
 check('challenge replay cooldown',not defense.challenge(challenger,92833004,92833003))
 local guard=profile.creatures[1];guard.level=25;R.specialize(profile,guard.id,'Guard');check('guard has defensive stat',R.stats(guard).guard==.15)
 return {passed=#checks,checks=checks,scope='isolated memory profiles and snapshots; no live DataStore or actual player progression'}
end
return T
