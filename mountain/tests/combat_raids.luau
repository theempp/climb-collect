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
print('PASS '..checks..' combat raid integration checks')
