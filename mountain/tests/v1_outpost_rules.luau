-- C03 pure rules: slots, play-only unlocks, defenders (no Robux-egg creatures), vault cap, shields, bots, simulation.
local R=require('../shared/Rules')
local S=require('../shared/V1Schema')
local O=require('../shared/OutpostRules')
local Sim=require('../shared/OutpostSim')
local Seasons=require('../shared/Seasons')
local V=require('../shared/V1Config')
local n=0
local function check(v,name) assert(v,name);n+=1 end
local function deep(t) if type(t)~='table' then return t end local c={};for k,v in pairs(t) do c[k]=deep(v) end;return c end
local p=S.migrate(R.newProfile(0))
local snap=O.newSnapshot(p)
check(#O.slots==10 and O.validSnapshot(snap) and #snap.defenders==3,'default_snapshot_10_slots_3_defenders')
check(O.setSlot(p,snap,8,'thorn_snare') and snap.slots[8]=='thorn_snare','set_unlocked_trap')
check(not O.setSlot(p,snap,8,'gravity_well'),'locked_piece_rejected')
check(not O.setSlot(p,snap,2,'thorn_snare'),'wrong_slot_type')
check(not O.setSlot(p,snap,1,false),'gate_required')
check(not O.setSlot(p,snap,11,'hedge_wall') and not O.setSlot(p,snap,0.5,'hedge_wall') and not O.setSlot(p,snap,2,'nope'),'invalid_slot_or_piece')
p.wins['6']=true;check(O.setSlot(p,snap,9,'gravity_well') and O.setSlot(p,snap,1,'astral_gate'),'unlocked_by_guardian_win')
for _,piece in ipairs(O.pieces) do check(piece.unlock~=nil and piece.price==nil,'no_paid_piece '..piece.id) end
-- defenders
check(not O.setDefenders(p,snap,{'c1','c1'}),'unique_defenders')
check(not O.setDefenders(p,snap,{'c1','c2','c3','c1'}),'max_three')
check(not O.setDefenders(p,snap,{'nope'}),'must_own')
table.insert(p.creatures,{id='paid1',species='bloomlet',level=5,xp=0,source='robux'})
check(select(2,O.setDefenders(p,snap,{'paid1'}))=='robux_creature_excluded','robux_creature_never_defends')
check(O.setDefenders(p,snap,{'c2'}) and #snap.defenders==1 and snap.defenders[1].species=='petalyn','set_defenders')
local p2=deep(p);p2.team={'paid1','c1'};check(#O.newSnapshot(p2).defenders==1,'default_snapshot_skips_robux')
-- validation
local bad=deep(snap);bad.slots[2]='thorn_snare';check(not O.validSnapshot(bad),'invalid_slot_piece')
bad=deep(snap);bad.defenders={{species='mossbun',level=99}};check(not O.validSnapshot(bad),'defender_level_bound')
bad=deep(snap);bad.slots[11]='hedge_wall';check(not O.validSnapshot(bad),'extra_slot_rejected')
-- vault
check(O.vaultCap(0)==V.outpost.vaultMinCap and O.vaultCap(1e9)==V.outpost.vaultMaxCap,'vault_cap_bounds')
local vault={coins=0,rate=600,updatedAt=0};O.accrue(vault,3600)
check(math.abs(vault.coins-60)<1e-6,'vault_fills_at_share_of_production')
O.accrue(vault,3600*1000);check(vault.coins==vault.cap and vault.cap==O.vaultCap(600),'vault_capped')
-- shields
local rec=O.newRecord(1,snap,0)
check(not O.shielded(rec,0),'no_shield_initially')
O.hitShield(rec,100);check(O.shielded(rec,100+V.outpost.shieldSeconds-1) and not O.shielded(rec,100+V.outpost.shieldSeconds),'four_hour_hit_shield')
local fresh=O.newRecord(1,snap,0);local t=10*86400
check(O.paidShield(fresh,t) and fresh.shield.untilTime==t+V.outpost.paidShieldSeconds,'paid_shield')
check(not O.paidShield(fresh,t+10),'one_paid_per_day')
local capped=O.newRecord(1,snap,0);O.hitShield(capped,t)
check(O.paidShield(capped,t) and capped.shield.untilTime==t+8*3600,'paid_stacks_to_cap')
local over=O.newRecord(1,snap,0);over.shield.untilTime=t+6*3600;check(select(2,O.paidShield(over,t))=='shield_cap','cap_8h')
check(O.paidShield(fresh,t+86400+V.outpost.paidShieldSeconds),'paid_resets_next_utc_day')
check(O.validRecord(fresh),'record_valid')
-- bots deterministic and valid at every bracket
for _,tr in ipairs({0,150,400,900,1500,3000}) do
 local b1,b2=O.bot(12345,tr),O.bot(12345,tr)
 check(O.validSnapshot(b1) and b1.slots[1]==b2.slots[1] and b1.defenders[1].species==b2.defenders[1].species,'bot_valid_deterministic '..tr)
end
-- simulation: deterministic, bounded, monotone in strength
local def=O.newSnapshot(S.migrate(R.newProfile(0)))
local weak={{species='mossbun',level=1}}
local strong={{species='caeloryn',level=50},{species='pyralune',level=50},{species='obsidrax',level=50}}
local planW={lanes={2},ability={false}}
local planS={lanes={1,2,3},ability={4,4,4}}
local a1=Sim.run(def,weak,planW,99);local a2=Sim.run(def,weak,planW,99)
check(a1.stars==a2.stars and a1.destruction==a2.destruction and #a1.events==#a2.events,'sim_deterministic')
local s1=Sim.run(def,strong,planS,99)
check(s1.stars==3 and s1.destruction==100 and s1.gate,'strong_team_three_stars')
check(a1.stars<s1.stars and a1.destruction<=s1.destruction,'weak_worse_than_strong')
check(#s1.events<=60 and s1.events[#s1.events].kind=='end','events_bounded_and_end')
for _,e in ipairs(s1.events) do check(e.t<=V.outpost.replaySeconds,'replay_within_20s') end
check(not Sim.validPlan({lanes={4}},1) and not Sim.validPlan({lanes={1,2}},1) and not Sim.validPlan({lanes={1},ability={-1}},1) and not Sim.validPlan({lanes={1},ability={0/0}},1) and not Sim.validPlan({lanes={1},ability={25}},1),'plan_validation')
check(not pcall(Sim.run,def,{},planW,1) and not pcall(Sim.run,def,strong,{lanes={1}},1),'sim_rejects_bad_input')
local planAbility=Sim.run(def,{{species='fernox',level=20}},{lanes={2},ability={0}},5)
local planNone=Sim.run(def,{{species='fernox',level=20}},{lanes={2},ability={false}},5)
check(planAbility.destruction>=planNone.destruction,'ability_helps')
-- seasons
local sr=O.newRecord(1,snap,V.weekStart(100));sr.trophies=820;sr.played=true
check(Seasons.rollover(sr,V.weekStart(101)+5) and sr.trophies==410 and sr.history[1].tier=='gold' and sr.history[1].season==100,'soft_reset_and_history')
check(not Seasons.rollover(sr,V.weekStart(101)+600),'one_rollover_per_week')
check(Seasons.rollover(sr,V.weekStart(102)) and #sr.history==1,'unplayed_season_no_reward_entry')
check(#Seasons.pending(sr.history,{})==1 and #Seasons.pending(sr.history,{100})==0,'pending_rewards_once')
check(Seasons.tier(0)=='bronze' and Seasons.tier(200)=='silver' and Seasons.tier(1600)=='astral','tiers')
print('PASS '..n..' outpost rules/sim/season checks')
