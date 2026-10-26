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
print('PASS '..checks..' combat raid integration checks')
