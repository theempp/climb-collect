check(type(Combat.connectRaids)=='function','combat connects shared guardian and reward custody')
local a={UserId=201,DisplayName='A'};local b={UserId=202,DisplayName='B'}
local pa=Rules.newProfile(100);local pb=Rules.newProfile(100);pa.wins['1']=true;pb.wins['1']=true
local ps={[a]=pa,[b]=pb};local state=GuardianRules.new(1,0);local awards=0;local manifests=0
local context={guardians={resting=function() return state.phase=='resting' end,position=function() return {} end,alert=function(k,id) GuardianRules.alert(state,id,nil,0) end,normalWin=function(k,ids) local _,fx=GuardianRules.normalWin(state,ids,5);return fx end},raids={reward=function(player,k,species) awards+=1;return RunRules.strike(ps[player],{id='trial',runId='trial',section=k,species=species,trial=true,hitsRequired=1},100) end},manifest=function() manifests+=1;return {Destroy=function() end} end}
Combat.init({get=function(player) return ps[player] end,save=function() return true end},function() end,function() end)
Combat.connectRaids(context)
check(Combat.start(a,1,false,{}) and Combat.start(b,1,true,{}),'normal_and_trial_coexist')
check(Combat.battles[1] and Combat.battles['trial:1'] and manifests==1 and state.threats[a.UserId],'trial_leaves_defender_active')
check(Combat.battles['trial:1'].max>Combat.battles[1].max,'trial_is_harder')
local trial=Combat.battles['trial:1'];trial.members[b].damage=trial.max;trial.members[b].dodges=3
Combat.finish(trial)
check(awards==1 and pb.run and not pb.captures.floravelle and #pb.creatures==3,'trial_reward_requires_exit')
RunRules.forfeit(pb,'catch')
check(Combat.start(b,1,true,{}),'lost_trial_can_retry')
local retry=Combat.battles['trial:1'];retry.members[b].damage=retry.max;retry.members[b].dodges=3
Combat.finish(retry)
check(awards==2 and pb.run and not pb.captures.floravelle,'retried_trial_still_unsecured')
local normal=Combat.battles[1];normal.members[a].damage=normal.max
Combat.finish(normal)
check(state.phase=='resting' and pa.creatures[1].xp>0 and not pa.captures.floravelle,'normal_win_respite_xp')
local xp=pa.creatures[1].xp;Combat.finish(normal);check(pa.creatures[1].xp==xp,'normal_win_xp_once')
RunRules.pickup(pb,'trial');RunRules.secure(pb,'trial')
check(not Combat.start(b,1,true,{}),'repeat_secured_capture_denied')
check(not Combat.start(a,1,false,{}),'cannot_stack_respite')
-- A mobile defender can be across the terrace when another player challenges.
local vector={};vector.__index=vector
function vector.__sub(a,b) return setmetatable({x=a.x-b.x},vector) end
function vector.__index(a,key) if key=='Magnitude' then return math.abs(a.x) end;return rawget(vector,key) end
local function v(x) return setmetatable({x=x},vector) end
local rr={Position=v(4068)};local h={Health=140}
a.Character={FindFirstChild=function() return rr end,FindFirstChildOfClass=function() return h end}
state=GuardianRules.new(1,0);context.guardians.position=function() return v(4154) end
check(Combat.start(a,1,false,v(4068)),'moving_defender_accepts_altar_challenge')
local approach=Combat.battles[1];local hp=approach.hp;approach.nextAttack=math.huge
check(not Combat.special(a,1,1) and approach.hp==hp,'no_remote_special_before_first_tick')
Combat.tick()
check(Combat.battles[1]==approach and approach.hp==hp and approach.members[a].damage==0,'approach_grace_without_remote_damage')
rr.Position=v(4120);Combat.tick()
check(approach.members[a].engaged and approach.hp<hp,'approach_enters_real_arena_and_deals_damage')
rr.Position=v(4068);Combat.tick()
check(not Combat.battles[1],'engaged_member_leaving_arena_still_exits')
check(Combat.start(a,1,false,v(4068)),'can_retry_after_leaving')
Combat.battles[1].members[a].approachUntil=0;Combat.tick()
check(not Combat.battles[1],'unused_approach_grace_expires')
-- Typed hud calm: the real Guardians service sends calm once on every threat removal.
local calms,warnings,clock={},{},0
local home={Position={X=0,Y=0,Z=0},X=0,Z=0}
local encounter={PrimaryPart=true,GetPivot=function() return home end,SetAttribute=function() end}
local g=Guardians.new({world={Encounters={FindFirstChild=function() return encounter end}},clock=function() return clock end,players=function() return {} end,
 root=function() return nil end,profile=function() return nil end,alive=function() return false end,protected=function() return false end,inside=function() return true end,
 rootHeight=function() return 12 end,ground=function() return nil end,catch=function() end,
 warning=function(id,k,eggId) table.insert(warnings,{id=id,k=k,eggId=eggId}) end,calm=function(id,k,reason) table.insert(calms,{id=id,k=k,reason=reason}) end})
local function calmsFor(id) local n,last=0,nil;for _,c in ipairs(calms) do if c.id==id then n+=1;last=c end end;return n,last end
g.alert(1,a.UserId,'raid:1:1',0);check(#warnings==1 and warnings[1].eggId=='raid:1:1' and warnings[1].k==1,'egg_alert_passes_egg_id_to_warning')
g.alert(1,b.UserId,nil,0);check(warnings[2].eggId==nil,'battle_join_alert_has_nil_egg')
g.remove(a,'catch');local n,last=calmsFor(a.UserId)
check(n==1 and last.k==1 and last.reason=='catch','alert_catch_calm')
g.tick(1);g.remove(a,'catch');check(calmsFor(a.UserId)==1,'catch_calm_sent_once')
g.alert(2,a.UserId,'raid:2:1',1);g.remove(a,'death');n,last=calmsFor(a.UserId)
check(n==2 and last.k==2 and last.reason=='death','alert_death_calm')
g.alert(3,a.UserId,'raid:3:1',1);g.remove(a,'leave');n,last=calmsFor(a.UserId)
check(n==3 and last.k==3 and last.reason=='leave','alert_leave_calm')
check(calmsFor(b.UserId)==1 and #calms==4,'tick_calms_lapsed_battle_join_threat')
g.remove({UserId=999},'leave');check(#calms==4,'no_calm_without_threat')
local c={UserId=203}
calms={};g=Guardians.new({world={Encounters={FindFirstChild=function() return encounter end}},clock=function() return clock end,players=function() return {} end,
 root=function() return nil end,profile=function() return nil end,alive=function() return false end,protected=function() return false end,inside=function() return true end,
 rootHeight=function() return 12 end,ground=function() return nil end,catch=function() end,calm=function(id,k,reason) table.insert(calms,{id=id,k=k,reason=reason}) end})
g.alert(4,a.UserId,'e',0);g.alert(4,b.UserId,nil,0);g.alert(5,c.UserId,'f',0)
g.normalWin(4,{a.UserId})
check(#calms==2 and calmsFor(a.UserId)==1 and calmsFor(b.UserId)==1 and calms[1].reason=='respite' and calms[2].reason=='respite' and calms[1].k==4,'normal_win_calms_each_threatened_user')
check(calmsFor(c.UserId)==0 and g.states[5].threats[c.UserId],'normal_win_leaves_other_sections')
g.normalWin(4,{a.UserId});check(#calms==2,'resting_win_sends_no_extra_calm')
g.tick(1);n,last=calmsFor(c.UserId)
check(n==1 and last.k==5 and last.reason=='step' and not g.states[5].threats[c.UserId],'step_removal_calm')
g.tick(2);g.remove(c,'leave');check(calmsFor(c.UserId)==1 and #calms==3,'step_calm_once')
print('PASS '..checks..' combat raid integration checks')
