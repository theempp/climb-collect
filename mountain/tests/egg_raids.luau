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
-- Player XP on secure (C3, C4; home-base P2 rarity table): Common 6 once, +50 new species, Trial only its derived 150k, stolen 0, no daily cap (STOP 3).
local X=require('../shared/ExplorerRules')
local day=20000;local c={UserId=3};local d={UserId=4};local twice=false;local huds={}
ps[c]=R.newProfile(100);ps[d]=R.newProfile(100);alive[c]=true;alive[d]=true;distance[c]=0;distance[d]=0;exit=false;failSave=false
local xprofiles={get=function(p) return ps[p] end,pending=function() return false end,transact=function(p,id,fn)
 if failSave then return false,'save_pending' end
 if twice then fn(ps[p]) end;return fn(ps[p])
end}
local x=E.new({profiles=xprofiles,clock=function() return now end,guid=function() serial+=1;return 'x'..serial end,today=function() return day end,
 eggs={s1={id='s1',section=1,species='mossbun'},s3={id='s3',section=3,species='glimfox'},s2={id='s2',section=2,species='coralfen'}},
 alive=function(p) return alive[p] end,near=function(p) return distance[p]<=12 end,atExit=function() return exit end,changed=function() end,present=function() end,
 hud=function(p,kind,data) table.insert(huds,{player=p,kind=kind,data=data}) end})
local function carry(player,egg)
 now+=120
 for _=1,20 do now+=1;x.strike(player,egg);if ps[player].run and ps[player].run.phase=='revealed' then break end end
 x.pickup(player,ps[player].run.id);return ps[player].run.id
end
local function bank(player,id)
 exit=true;local before=X.xp(ps[player]);local creatures=#ps[player].creatures
 local ok,reason=x.exit(player,id);exit=false
 return ok,reason,X.xp(ps[player])-before,#ps[player].creatures-creatures
end
local id1=carry(c,'s1');check(ps[c].run.firstCarrier==3,'pickup_sets_first_carrier')
twice=true;local ok1,why1,gain1,added1=bank(c,id1);twice=false
check(ok1 and why1=='already_secured' and gain1==6 and added1==1 and ps[c].explorer.secures==1,'secure_pays_common_6_once_and_already_secured_pays_0')
local hx=huds[#huds];check(#huds==1 and hx.kind=='xp' and hx.player==c and hx.data.source=='secure' and hx.data.amount==6,'secure_xp_event')
local _,_,gain3=bank(c,carry(c,'s3'));check(gain3==80 and ps[c].explorer.species.glimfox,'secure_new_species_plus_50')
-- Trial: only the derived 150k capture row; no counter slot and no species.
ps[c].wins['1']=true;local secures=ps[c].explorer.secures;local okT,trialId=x.reward(c,1,'floravelle',{})
check(okT and x.pickup(c,trialId) and ps[c].run.firstCarrier==3,'trial_reward_carried')
local okTrial,_,gainT,addedT=bank(c,trialId)
check(okTrial and gainT==150 and addedT==1 and ps[c].captures.floravelle and ps[c].explorer.secures==secures and not ps[c].explorer.species.floravelle,'trial_pays_only_150k')
check(huds[#huds].data.source=='trial' and huds[#huds].data.amount==150,'trial_xp_event')
-- Stolen: the thief secures for 0; a regrab by the first carrier still pays.
carry(c,'s2');local snap=x.drop(c);check(snap and snap.firstCarrier==3,'drop_snapshot_keeps_first_carrier')
local okA,stolenId=x.adopt(d,snap,{});check(okA and ps[d].run.firstCarrier==3,'receive_keeps_first_carrier')
local count=#huds;local okS,_,gainS,addedS=bank(d,stolenId)
check(okS and addedS==1 and gainS==0 and ps[d].explorer.secures==0 and not ps[d].explorer.species.coralfen and #huds==count,'stolen_secure_pays_0')
now+=120;carry(c,'s2');snap=x.drop(c);local okR,regrabId=x.adopt(c,snap,{})
local okG,_,gainG=bank(c,regrabId);check(okR and okG and gainG==62 and ps[c].explorer.species.coralfen,'first_carrier_regrab_pays')
-- Malformed draft.explorer still secures exactly once.
for _,bad in ipairs({'junk',{repeatXp=0/0,secures=-4,day=-1,species='x',won=5}}) do
 ps[c].explorer=bad;local okM,whyM,_,addedM=bank(c,carry(c,'s1'))
 check(okM and whyM=='secured' and addedM==1 and not ps[c].run and type(ps[c].explorer)=='table','malformed_explorer_secures_once_'..type(bad))
end
-- No daily cap: the 21st secure of the day still pays; the next day resets the count.
ps[c].explorer.secures=20;ps[c].explorer.day=day
local okC,_,gainC=bank(c,carry(c,'s1'));check(okC and gainC==6 and ps[c].explorer.secures==21,'twenty_first_secure_pays')
day+=1;local _,_,gainN=bank(c,carry(c,'s1'));check(gainN==6 and ps[c].explorer.secures==1,'next_day_secure_pays')
print('PASS '..n..' egg raid checks')
