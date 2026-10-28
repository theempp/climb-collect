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
local newer=Rules.newProfile(100);newer.settings={largeText=true,futurePref=true};backend.backend.u106={profile=newer}
local loaded=service.load({UserId=106})
check(loaded and loaded.settings.largeText and loaded.settings.futurePref==nil,'unknown_settings_key_loads_no_kick')
check(backend.backend.u106.profile.settings.futurePref==true and backend.backend.u106.lock~=nil,'unknown_settings_key_load_no_overwrite')
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
-- Player XP (C3): a legacy profile is seeded in the load write; a malformed explorer never refuses a load or a secure.
local legacyXp=Rules.newProfile(100);legacyXp.explorer=nil;legacyXp.wins['2']=true
for i,sp in ipairs({'glimfox','floravelle','bubblit'}) do table.insert(legacyXp.creatures,{id='x'..i,species=sp,level=1,xp=0,origin=if sp=='bubblit' then 'coin' else nil}) end
backend.backend.u111={profile=legacyXp}
local xpPlayer={UserId=111};local seeded=service.load(xpPlayer);local stored=backend.backend.u111.profile.explorer
check(seeded and seeded.explorer.won['2'] and seeded.explorer.species.glimfox and not seeded.explorer.species.floravelle and not seeded.explorer.species.bubblit,'legacy_profile_explorer_seeded')
check(type(stored)=='table' and stored.won['2'] and stored.species.glimfox and ExplorerRules.xp(seeded)==ExplorerRules.xp({discoveries={},captures={},explorer=stored}),'legacy_explorer_seed_persisted_in_load_write')
for i,bad in ipairs({'junk',7,true}) do
 local junk=Rules.newProfile(100);junk.explorer=bad;backend.backend['u'..(111+i)]={profile=junk}
 local j=service.load({UserId=111+i})
 check(j and type(j.explorer)=='table' and type(backend.backend['u'..(111+i)].profile.explorer)=='table','malformed_explorer_loads_reseeded_'..type(bad))
end
local typed=Rules.newProfile(100);check(Profiles.valid(typed),'explorer_table_valid');typed.explorer='junk';check(not Profiles.valid(typed),'explorer_type_checked_by_valid')
typed.explorer=nil;check(Profiles.valid(typed),'explorer_absent_valid')
local xp=service.get(xpPlayer);xp.explorer={secures=-4,species='x',won=5,day=-1,repeatXp=-3};carry(xp,'xp-run')
check(service.transact(xpPlayer,'xp-run',function(draft) local r=draft.run;local ok,why=RunRules.secure(draft,'xp-run');ExplorerRules.award(draft,'secure',r.section,20000,r.species);return ok,why end)
 and #service.get(xpPlayer).creatures==7 and not service.get(xpPlayer).run and service.get(xpPlayer).explorer.secures==1,'malformed_explorer_still_secures_once_through_transact')
-- D8 (C8): an all-Robux team loads stripped and refilled in the load write (no kick); Robux eggs in cargo or recovery return to p.eggs.
local paid=Rules.newProfile(100);paid.creatures[3].level=4
for i=1,3 do table.insert(paid.creatures,{id='r'..i,species='bloomlet',level=30,xp=0,origin='robux'}) end
paid.team={'r1','r2','r3'};paid.cargo={{id='re1',species='mossbun',origin='robux'},{id='e1',species='petalyn'}};paid.recovery={eggs={{id='re2',species='fernox',origin='robux'}},expires=os.time()+180}
backend.backend.u120={profile=paid}
local stripped=service.load({UserId=120});local saved=backend.backend.u120.profile
check(stripped and #stripped.team==3 and stripped.team[1]=='c3' and stripped.team[2]=='c1' and stripped.team[3]=='c2','all_robux_team_loads_stripped_and_refilled')
check(#saved.team==3 and saved.team[1]=='c3' and #saved.cargo==1 and saved.recovery==nil and #saved.eggs==2 and saved.eggs[1].origin=='robux','strip_persisted_in_load_write')
check(Rules.find(stripped.creatures,'r1').origin=='robux' and #stripped.creatures==6,'robux creatures stay owned')
-- T9 (C14/C15): Meadow Egg through the real dispatcher and Profiles. A known receipt never writes again.
local shopBackend=Store.memory();local shops=Profiles.newForTests(shopBackend,'shop');local buyer={UserId=130}
local tick=0;local live=shops.load(buyer);live.coins=6000
check(live.receipts==nil,'legacy_profile_without_receipts_loads')
local buy=UIRequests.actions({profiles=shops,rules=Rules,safe=function() return true end,shop=ShopRules,monotonic=function() return tick end,
 rollOdds=function() return 50 end,inSanctuary=function() return true end,inBattle=function() return false end})
local function order(receipt) return buy(buyer,'Buy',{item='meadow_egg',receipt=receipt}) end
local function durable() return shopBackend.backend.u130.profile end
local writes=shopBackend.calls.update
local ok,message,data=order('receipt-a001')
check(ok and data.egg.origin=='coin' and shopBackend.calls.update==writes+1 and durable().coins==3500 and #durable().eggs==1 and durable().receipts[1]=='receipt-a001','buy_commits_debit_grant_receipt_in_one_write')
local okReplays=0
for i=1,6 do tick+=1;if order('receipt-a001') then okReplays+=1 end end
check(okReplays==3 and shopBackend.calls.update==writes+1 and shops.get(buyer).coins==3500 and #shops.get(buyer).eggs==1,'n_replays_of_one_receipt_write_exactly_once')
tick+=2;writes=shopBackend.calls.update;ok,message=order('receipt-a001')
check(ok and message=='Purchase already complete.' and shopBackend.calls.update==writes,'same_receipt_after_commit_no_write_returns_ok')
-- failNext=3: every commit attempt fails, the draft stays pending (P.get nil, requests refused) until autosave commits it once.
tick+=2;shopBackend.failNext=3;ok,message=order('receipt-a002')
check(not ok and message=='Purchase is saving. It appears once saving resumes.' and shops.pending(buyer)=='buy:receipt-a002' and not shops.get(buyer),'failed_commit_stays_pending')
check(durable().coins==3500 and #durable().eggs==1,'nothing_durable_before_commit')
tick+=2;writes=shopBackend.calls.update;ok,message=order('receipt-a002')
check(not ok and message=='Profile or saving unavailable.' and shopBackend.calls.update==writes,'pending_refuses_buy_without_write')
check(shops.save(buyer,false) and not shops.pending(buyer),'autosave_commits_pending_buy')
local after=shops.get(buyer)
check(after.coins==1000 and #after.eggs==2 and #after.receipts==2 and durable().coins==1000 and #durable().eggs==2 and durable().receipts[2]=='receipt-a002','autosave_commits_exactly_one_debit_and_grant')
tick+=2;writes=shopBackend.calls.update;ok=order('receipt-a002')
check(ok and shopBackend.calls.update==writes and shops.get(buyer).coins==1000,'committed_pending_receipt_replays_without_write')
-- failAfterCommit: the response is lost after the durable write; the retry reuses the same write id, so one debit.
after.coins=4000;tick+=2;shopBackend.failAfterCommit=1;ok=order('receipt-a003')
check(ok and shops.get(buyer).coins==1500 and #shops.get(buyer).eggs==3 and durable().coins==1500 and #durable().eggs==3,'fail_after_commit_single_debit')
tick+=2;writes=shopBackend.calls.update;check(order('receipt-a003') and shopBackend.calls.update==writes and #durable().eggs==3,'fail_after_commit_replay_single')
check(shops.save(buyer,true),'buyer_releases')
local back=shops.load(buyer)
check(back.coins==1500 and #back.eggs==3 and #back.receipts==3 and back.eggs[3].origin=='coin' and ShopRules.has(back,'receipt-a001'),'coins_eggs_receipts_survive_release_and_reload')
print('PASS '..checks..' durable exit/migration checks (isolated adapter)')
