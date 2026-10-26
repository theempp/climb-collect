local R=require('../shared/Rules')
local modulePath='../server/EggRaids'
local loaded,E=pcall(require,modulePath)
assert(loaded and type(E.new)=='function','authoritative egg raid service exists')
local n=0;local function check(v,name) assert(v,name);n+=1 end
local now=100;local serial=0;local alerts=0;local events={}
local a={UserId=1};local b={UserId=2};local ps={[a]=R.newProfile(100),[b]=R.newProfile(100)}
local alive={[a]=true,[b]=true};local distance={[a]=0,[b]=0};local exit=false;local failSave=false
local available=true
local profiles={get=function(p) return available and ps[p] end,pending=function() return false end,transact=function(p,id,fn) if failSave then return false,'save_pending' end;return fn(ps[p]) end}
local e=E.new({profiles=profiles,clock=function() return now end,guid=function() serial+=1;return 'r'..serial end,eggs={a={id='a',section=1,species='mossbun'},b={id='b',section=1,species='petalyn'}},alive=function(p) return alive[p] end,near=function(p) return distance[p]<=12 end,atExit=function() return exit end,alert=function() alerts+=1 end,changed=function() end,present=function(p,data) events[p]=data end})
distance[a]=100;check(not e.strike(a,'a'),'remote_distance');distance[a]=0
check(e.strike(a,'a') and alerts==1,'first strike alerts')
check(not e.strike(b,'a'),'two_players_same_egg')
check(not e.strike(a,'b'),'two_eggs_same_player')
check(not e.strike(a,'a') and ps[a].run.hits==1,'cadence_spam')
local id=ps[a].run.id
check(not e.pickup(b,id),'foreign_run_id')
for i=1,20 do now+=1;e.strike(a,'a');if ps[a].run.phase=='revealed' then break end end
check(ps[a].run.phase=='revealed' and #ps[a].creatures==3,'reveal_no_ownership')
alive[a]=false;check(not e.pickup(a,id),'post_death_delayed_pickup');e.forfeit(a,'reset');alive[a]=true
check(not e.pickup(a,id),'post_reset_replay')
now+=120;check(e.strike(a,'b'),'new attempt')
for i=1,20 do now+=1;e.strike(a,'b');if ps[a].run.phase=='revealed' then break end end
id=ps[a].run.id;check(e.pickup(a,id) and not e.strike(a,'a'),'full_hands')
check(not e.exit(a,id),'cannot_remote_bank')
exit=true;failSave=true;check(not e.exit(a,id) and #ps[a].creatures==3,'no_safe_before_save')
failSave=false;check(e.exit(a,id) and #ps[a].creatures==4,'exit_reward')
check(not e.exit(a,id) and #ps[a].creatures==4,'no_double_reward_replay')
exit=false;now+=120;e.strike(b,'a');now+=120;e.tick(now)
check(not ps[b].run,'abandoned_reservation_cleanup');now+=20;check(e.strike(a,'a'),'abandoned_egg_reusable_after_rest')
e.remove(a);check(not ps[a].run,'disconnect_forfeits')
now+=120;e.strike(a,'a');now+=1;e.strike(a,'a');now+=1;e.strike(a,'a');e.pickup(a,ps[a].run.id)
exit=true;failSave=true;e.exit(a,ps[a].run.id);e.remove(a)
check(not e.protected(a),'disconnected_exit_service_does_not_leak_player')
exit=false;failSave=false;now+=120;e.forfeit(b,'reset');e.strike(b,'b')
available=false;now+=120;e.tick(now);available=true;e.tick(now)
check(not ps[b].run,'expiry_deferred_until_mutation_resumes')
now+=120;check(e.strike(b,'b'),'failed_save_expiry_does_not_strand_full_hands')
print('PASS '..n..' egg raid checks')
