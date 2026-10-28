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
-- Player XP (C3, C5): only an engaged contributor (dodges+hits >= 2) earns it; the wins flag and companion XP are unchanged.
local e={UserId=204,DisplayName='E'};local pe=Rules.newProfile(100);ps[e]=pe;local xpHuds={}
Combat.init({get=function(player) return ps[player] end,save=function() return true end},function() end,function() end,function(player,kind,data) table.insert(xpHuds,{player=player,kind=kind,data=data}) end)
context.guardians.normalWin=function(_,ids) return {xp=ids} end
local function win(player,k,dodges,hits)
 local battle={key='xp'..k,k=k,trial=false,max=1000,hp=0,members={[player]={damage=1000,dodges=dodges,hits=hits}},effects={}}
 Combat.battles[battle.key]=battle;return Combat.finish(battle)
end
local companion=pe.creatures[1].level
win(e,2,1,0)
check(pe.wins['2'] and pe.unlocked==3 and pe.creatures[1].level>companion and not pe.explorer.won['2'] and ExplorerRules.xp(pe)==0 and #xpHuds==0,'leech_gets_wins_flag_and_companion_xp_but_0_player_xp')
win(e,2,1,1)
check(pe.explorer.won['2'] and ExplorerRules.xp(pe)==200 and pe.explorer.repeats==0,'engaged_first_win_100k')
check(#xpHuds==1 and xpHuds[1].player==e and xpHuds[1].kind=='xp' and xpHuds[1].data.amount==200 and xpHuds[1].data.source=='win' and xpHuds[1].data.level==3,'engaged_win_xp_event')
for i=1,5 do win(e,2,2,0) end
check(ExplorerRules.xp(pe)==300 and pe.explorer.repeats==5,'five_repeat_wins_pay_10k_each')
win(e,2,0,3);check(ExplorerRules.xp(pe)==300 and pe.explorer.repeats==5 and #xpHuds==6,'repeat_cap_5_per_day')
win(e,3,0,1);check(pe.wins['3'] and not pe.explorer.won['3'] and ExplorerRules.xp(pe)==300,'leech_first_win_elsewhere_pays_0')
local legacyWin={UserId=205,DisplayName='F'};local pf=Rules.newProfile(100);pf.explorer=nil;pf.wins['4']=true;ps[legacyWin]=pf
win(legacyWin,4,1,1);check(pf.explorer.won['4'] and pf.explorer.repeats==1 and ExplorerRules.xp(pf)==440,'unseeded_explorer_judges_prior_win_before_flag_is_set')
-- D8 (C9): an injected Robux id adds no power, guard, special or companion XP; Competition snapshots skip it.
local rp={UserId=206,DisplayName='R'};local pr=Rules.newProfile(100);ps[rp]=pr
table.insert(pr.creatures,{id='rx',species='fernox',level=1,xp=0,origin='robux',specialization='Guard'});pr.team={'rx','c1'}
local taken={};local rh={Health=140,MaxHealth=140,TakeDamage=function(_,n) table.insert(taken,n) end};local rroot={Position=v(0)}
rp.Character={FindFirstChild=function() return rroot end,FindFirstChildOfClass=function() return rh end}
local wildHp=1e6;Combat.wild[rp]={species='petalyn',part={Parent=true,Position=v(0)},hp=wildHp,nextAttack=0}
Combat.tick()
local st=Rules.stats(pr.creatures[1]);local guard=st.guard+(if st.role=='Tank' then .05 else 0)
check(Combat.wild[rp].hp==wildHp-Rules.damage(st.element,Catalog.byId.petalyn.element,st.attack),'robux_adds_no_power')
check(#taken==1 and taken[1]==8*(1-math.min(.65,guard)),'robux_adds_no_guard')
check(not Combat.special(rp,1,1) and Combat.special(rp,2,1),'robux_slot_has_no_special')
Combat.wild[rp].hp=0;Combat.tick()
check(Combat.wild[rp]==nil and pr.creatures[1].xp+pr.creatures[1].level>1 and pr.creatures[4].xp==0 and pr.creatures[4].level==1,'robux_gets_no_wild_xp')
local before=pr.creatures[1].xp+pr.creatures[1].level*1000;win(rp,1,2,0)
check(pr.creatures[1].xp+pr.creatures[1].level*1000>before and pr.creatures[4].xp==0 and pr.creatures[4].level==1,'robux_gets_no_battle_xp')
local snap=Competition.snapshot(pr,206)
check(#snap.team==1 and snap.team[1].species=='mossbun','competition_snapshot_excludes_robux')
-- Q4 (C17): 5 coin-paying Competition wins per UTC day (practice and snapshot); trophies always count; the day only moves forward.
do
 local cp=Rules.newProfile(100);for _,c in ipairs(cp.creatures) do c.level=50 end
 local function practice() cp.competitionAt=0;local ok,value=Competition.challenge(cp,301,0);assert(ok and value.won,'practice win');return value end
 local today=math.floor(os.time()/86400)
 for i=1,5 do local value=practice();check(value.coins==35 and cp.coins==35*i and cp.trophies==10*i and cp.competition.wins==i and cp.competition.day==today,'coin_win_'..i) end
 local sixth=practice()
 check(sixth.coins==0 and cp.coins==175 and cp.trophies==60 and cp.competition.wins==5,'sixth_coin_win_pays_zero_coins_keeps_trophies')
 cp.competition={day=today-1,wins=5};check(practice().coins==35 and cp.competition.day==today and cp.competition.wins==1,'new_day_resets_once')
 cp.competition={day=today+1,wins=5};check(practice().coins==0 and cp.competition.day==today+1,'day_never_moves_back')
 cp.competition={day=today+40,wins=5};check(practice().coins==0 and cp.competition.day==today,'far_future_day_clamped_counter_kept')
 for _,bad in ipairs({'junk',{day=0/0,wins=-3},{day=today,wins=math.huge},{day=-5,wins='x'}}) do
  cp.competition=bad;local coins=cp.coins;local value=practice()
  check(type(cp.competition)=='table' and cp.competition.wins>=1 and cp.competition.wins<=5 and cp.coins==coins+value.coins,'malformed_competition_normalized')
 end
 local weak=Rules.newProfile(100);weak.competitionAt=0;local ok,value=Competition.challenge(weak,302,0)
 check(ok and not value.won and value.coins==0 and weak.competition==nil and weak.coins==0,'loss_pays_nothing_and_counts_nothing')
end
print('PASS '..checks..' combat raid integration checks')
