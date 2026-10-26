-- Loaded with the real Profiles/Store/Rules modules by run_persistence.py.
check(type(Profiles.transact)=='function','durable transaction interface exists')
local backend=Store.memory()
local service=Profiles.newForTests(backend,'owner')
local player={UserId=101}
local p=service.load(player)
check(p and p.schema==2,'schema2 loads')
local function carry(profile,id)
 RunRules.strike(profile,{id=id,runId=id,species='mossbun',section=1,hitsRequired=1},100)
 RunRules.pickup(profile,id)
end
carry(p,'a');backend.failAll=true
check(not service.transact(player,'a',function(draft) return RunRules.secure(draft,'a') end),'failed_save_no_safe_ack')
check(#p.creatures==3 and p.run.id=='a' and not service.get(player),'failed_save_keeps_live_ungranted_and_freezes')
check(not service.transact(player,'b',function(draft) draft.coins=999;return true end),'pending_blocks_unrelated_transaction')
backend.failAll=false;backend.failAfterCommit=1
check(service.transact(player,'a',function() error('retry must reuse prepared draft') end),'retry_same_exit_once')
check(#service.get(player).creatures==4 and not service.get(player).run,'ownership_published_after_commit')
check(service.transact(player,'a',function(draft) return RunRules.secure(draft,'a') end) and #service.get(player).creatures==4,'replay_no_duplicate')
check(service.save(player,true),'exit_then_disconnect_flushes')
p=service.load(player);check(#p.creatures==4,'exit_disconnect_race_owned_after_rejoin')
carry(p,'b');p.coins=52;p.tycoon.habitats[1].eggs=2;p.tycoon.habitats[1].value=3
local update=backend.update;local during=false
function backend:update(key,fn)
 if key=='u101' and not during then
  during=true
  check(not service.get(player),'concurrent_mutation_excluded_while_transaction_yields')
 end
 return update(self,key,fn)
end
check(service.transact(player,'b',function(draft) return RunRules.secure(draft,'b') end),'exit commits')
check(service.get(player).coins==52 and service.get(player).tycoon.habitats[1].value==3,'concurrent_tycoon_mutation_preserved')
backend.update=update
p=service.get(player);carry(p,'c');backend.backend.u101.lock.owner='new-owner'
check(not service.transact(player,'c',function(draft) return RunRules.secure(draft,'c') end) and #backend.backend.u101.profile.creatures==5,'stale_session_cannot_commit')
local old=Rules.newProfile(100);old.schema=1;old.cargo={{id='legacy1',species='mossbun'}};old.recovery={eggs={{id='legacy2',species='petalyn'}},expires=1}
backend.backend.u102={profile=old}
local migrated=service.load({UserId=102})
check(migrated and #migrated.eggs==2 and migrated.schema==2,'load_migrates_legacy_entitlements')
local bad=Rules.newProfile(100);bad.schema=1;bad.recovery={eggs={{id='broken',species='unknown'}}};backend.backend.u103={profile=bad}
check(not service.load({UserId=103}) and backend.backend.u103.profile.schema==1,'invalid_profile_no_overwrite')
local unsafe=Rules.newProfile(100);carry(unsafe,'offline');backend.backend.u104={profile=unsafe}
check(service.load({UserId=104}).run==nil,'reconnect_forfeits_unsecured_run')
-- Real interleaving: exit yields at the storage boundary, then disconnect waits.
local raceBackend=Store.memory();local race=Profiles.newForTests(raceBackend,'race');local leaver={UserId=105}
carry(race.load(leaver),'racing')
local originalUpdate=raceBackend.update;local pauseOnce=true
function raceBackend:update(key,fn)
 if pauseOnce then pauseOnce=false;coroutine.yield('storage') end
 return originalUpdate(self,key,fn)
end
local normalWait=task.wait;task.wait=function() coroutine.yield('wait') end
local exitOK,leaveOK
local exitThread=coroutine.create(function() exitOK=race.transact(leaver,'racing',function(draft) return RunRules.secure(draft,'racing') end) end)
local leaveThread=coroutine.create(function() leaveOK=race.save(leaver,true) end)
check(coroutine.resume(exitThread),'exit begins')
check(coroutine.resume(leaveThread),'disconnect waits')
check(coroutine.resume(exitThread) and exitOK,'exit commits during disconnect')
check(coroutine.resume(leaveThread) and leaveOK and race.sessions[leaver]==nil,'disconnect releases committed profile')
check(#raceBackend.backend.u105.profile.creatures==4 and raceBackend.backend.u105.lock==nil,'exit_disconnect_race_exactly_once')
-- Autosave is already in storage when exit is crossed; release resumes before exit.
local queuedBackend=Store.memory();local queued=Profiles.newForTests(queuedBackend,'queue');local qplayer={UserId=109}
carry(queued.load(qplayer),'queued-exit')
local qupdate=queuedBackend.update;local qpause=true
function queuedBackend:update(key,fn) if qpause then qpause=false;coroutine.yield('storage') end;return qupdate(self,key,fn) end
local qexitOK,qleaveOK
local autosave=coroutine.create(function() queued.save(qplayer,false) end)
local qexit=coroutine.create(function() qexitOK=queued.transact(qplayer,'queued-exit',function(draft) return RunRules.secure(draft,'queued-exit') end) end)
local qleave=coroutine.create(function() qleaveOK=queued.save(qplayer,true) end)
assert(coroutine.resume(autosave));assert(coroutine.resume(qexit));assert(coroutine.resume(qleave))
assert(coroutine.resume(autosave));assert(coroutine.resume(qleave));assert(coroutine.resume(qexit))
check(qexitOK and qleaveOK and #queuedBackend.backend.u109.profile.creatures==4,'exit_intent_survives_autosave_then_disconnect_winning_wait')
check(#queued.load(qplayer).creatures==4,'queued_exit_survives_rejoin')
task.wait=normalWait
local malformed=Rules.newProfile(1);malformed.creatures={false};backend.backend.u106={profile=malformed}
check(not service.load({UserId=106}) and backend.backend.u106.profile.creatures[1]==false,'malformed_entry_preserved')
local sparse=Rules.newProfile(1);sparse.schema=1;sparse.cargo={[2]={id='sparse',species='mossbun'}};backend.backend.u107={profile=sparse}
check(not service.load({UserId=107}) and backend.backend.u107.profile.cargo[2].id=='sparse','sparse_legacy_payload_preserved')
local invalid=Rules.newProfile(1);invalid.creatures[2].id=invalid.creatures[1].id;backend.backend.u108={profile=invalid}
check(not service.load({UserId=108}),'duplicate_roster_ids_rejected')
local conflict=Rules.newProfile(1);conflict.schema=1;conflict.eggs={{id='same',species='mossbun',readyAt=77}};conflict.cargo={{id='same',species='petalyn'}};backend.backend.u110={profile=conflict}
check(not service.load({UserId=110}) and backend.backend.u110.profile.schema==1 and #backend.backend.u110.profile.cargo==1,'conflicting_legacy_identity_preserved_without_overwrite')
print('PASS '..checks..' durable exit/migration checks (isolated adapter)')
