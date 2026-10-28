-- C02 + phase 7 on the real Combat module: duo health scaling, per-contributor wins/Trial rewards,
-- Caeloryn Gravity Choir / Constellation Accord / Celestial Dominion.
check(CaelorynAbilities.abilities[2].name=='Gravity Choir' and CaelorynAbilities.abilities[3].name=='Constellation Accord' and CaelorynAbilities.abilities[4].name=='Celestial Dominion','caeloryn_catalog_names')
check(CaelorynAbilities.abilities[2].role=='control' and CaelorynAbilities.abilities[3].role=='team_shield' and CaelorynAbilities.abilities[4].role=='ultimate','caeloryn_locked_roles')
local ult=CaelorynAbilities.resolve(4,100,{})
check(ult.charge==1.5 and math.abs(ult.total-(600+3*60*4))<1e-6,'ultimate_total')
local sh=CaelorynAbilities.resolve(3,100,{'a','b','c'});check(#sh.shieldTargets==2,'team_shield_duo_cap')
check(CaelorynAbilities.resolve(9,100,{})==nil and CaelorynAbilities.resolve(2,0/0,{})==nil,'resolve_rejects_bad_input')
check(CoopRules.health(1000,1,false,300)==1000 and CoopRules.health(1000,2,false,300)==1500 and CoopRules.health(1000,3,false,300)==1800 and CoopRules.health(1000,2,true,0)==1450,'coop_health')
-- fixtures
local vec={};vec.__index=vec
function vec.__sub(a,b) return setmetatable({x=a.x-b.x},vec) end
function vec.__index(a,key) if key=='Magnitude' then return math.abs(a.x) end;return rawget(vec,key) end
local function v(x) return setmetatable({x=x},vec) end
local function character(x)
 local rr={Position=v(x)};local h={Health=200,MaxHealth=200}
 return {FindFirstChild=function() return rr end,FindFirstChildOfClass=function() return h end},h
end
local a={UserId=601,DisplayName='A'};local b={UserId=602,DisplayName='B'};local c={UserId=603,DisplayName='C'}
local ha,hb;a.Character,ha=character(10);b.Character,hb=character(12);c.Character=character(14)
local pa,pb,pc=Rules.newProfile(1),Rules.newProfile(1),Rules.newProfile(1)
for _,p in ipairs({pa,pb,pc}) do p.wins['6']=true end
table.insert(pa.creatures,{id='cael',species='caeloryn',level=10,xp=0});pa.team={'cael','c1','c2'}
local ps={[a]=pa,[b]=pb,[c]=pc}
local state=GuardianRules.new(6,0);local rewards={};local wins={}
local context={guardians={resting=function() return false end,position=function() return v(0) end,alert=function() end,
 normalWin=function(_,ids) local _,fx=GuardianRules.normalWin(state,ids,5);return fx end},
 raids={reward=function(player) rewards[player.UserId]=(rewards[player.UserId] or 0)+1;return true end},manifest=function() return nil end}
Combat.init({get=function(player) return ps[player] end,save=function() return true end},function() end,function() end)
Combat.connectRaids(context)
Combat.onWin=function(player,k,trial) table.insert(wins,{player.UserId,k,trial}) end
Combat.battles={}
check(Combat.start(a,6,false,v(0)),'solo_start')
local battle=Combat.battles[6];local base=battle.max
check(battle.base==base,'base_recorded')
check(Combat.start(b,6,false,v(0)) and math.abs(battle.max-base*1.5)<1e-6 and math.abs(battle.hp-base*1.5)<1e-6,'duo_scales_health_1_5x')
check(Combat.start(c,6,false,v(0)) and math.abs(battle.max-(base*1.5+RaidConfig.section(6).joinHealth))<1e-6,'third_stranger_adds_join_health')
battle.members[c]=nil
-- Caeloryn ability 2: control (weaken + delayed next pattern) + damage
for _,m in pairs(battle.members) do m.engaged=true end
battle.nextAttack=100
local hp=battle.hp
check(Combat.special(a,1,2) and battle.weakenUntil and battle.nextAttack>=100+2.5 and battle.hp<hp,'gravity_choir_controls')
check(not Combat.special(a,1,2),'gravity_choir_cooldown')
-- ability 3: team shield on both duo members, heal, harm reduced
ha.Health=100;hb.Health=100
check(Combat.special(a,1,3),'constellation_accord_cast')
check(Combat.buffs[a] and Combat.buffs[b] and Combat.buffs[a].shieldGuard==.30 and Combat.buffs[b].shieldGuard==.30 and ha.Health==120 and hb.Health==120,'team_shield_and_heal_both')
-- ability 4: charged beam + constructs (task.delay runs immediately in fixtures)
local before=battle.hp
local atk=Rules.stats(pa.creatures[4]).attack
check(Combat.special(a,1,4),'celestial_dominion_cast')
local expected=Rules.damage('Cosmic','Cosmic',atk*6)+12*Rules.damage('Cosmic','Cosmic',atk*.6)
check(math.abs((before-battle.hp)-expected)<1e-6,'ultimate_damage_beam_plus_constructs')
check(battle.members[a].damage>0,'caster_contribution_counted')
-- per-contributor normal win: both members credited, hook fires per contributor
battle.members[a].damage=battle.max;battle.members[b].damage=battle.max*.05
Combat.finish(battle)
check(pa.wins['6'] and pb.wins['6'] and #wins==2 and wins[1][3]==false,'each_contributor_wins')
-- Trial: each contributor gets their own collectible reward attempt
state=GuardianRules.new(6,0);wins={}
Combat.battles={}
check(Combat.start(a,6,true,v(0)) and Combat.start(b,6,true,v(0)),'duo_trial')
local tb=Combat.battles['trial:6']
check(math.abs(tb.max-tb.base*1.45)<1e-6,'trial_duo_scaling')
for _,m in pairs(tb.members) do m.damage=tb.max;m.dodges=3;m.objective=true end
Combat.finish(tb)
check(rewards[601]==1 and rewards[602]==1 and #wins==2 and wins[1][3]==true,'each_contributor_trial_reward')
-- a non-contributor (below 3%) gets nothing
state=GuardianRules.new(6,0);Combat.battles={};rewards={}
Combat.start(a,6,true,v(0));Combat.start(b,6,true,v(0))
local t2=Combat.battles['trial:6'];t2.members[a].damage=t2.max;t2.members[a].dodges=3;t2.members[a].objective=true;t2.members[b].damage=t2.max*.01;t2.members[b].dodges=3
Combat.finish(t2)
check(rewards[601]==1 and rewards[602]==nil,'non_contributor_no_reward')
Combat.onWin=nil
