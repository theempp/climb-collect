-- Schema 3 migration, validation bounds and the shared reward pipeline (pure CLI).
local R=require('../shared/Rules')
local Run=require('../shared/RunRules')
local S=require('../shared/V1Schema')
local W=require('../shared/V1Wallet')
local V=require('../shared/V1Config')
local n=0
local function check(v,name) assert(v,name);n+=1 end
local function deep(t) if type(t)~='table' then return t end local c={};for k,v in pairs(t) do c[k]=deep(v) end;return c end
-- migration chain: schema 1 -> 2 (custody) -> 3 (v1), idempotent, never clobbers
local p=R.newProfile(100);p.schema=1;p.cargo={{id='old1',species='mossbun'}};p.coins=77
p=S.migrate(Run.migrate(p))
check(p and p.schema==3 and p.coins==77 and #p.eggs==1 and S.valid(p.v1),'schema1_to_3_keeps_eggs_and_coins')
local again=S.migrate(Run.migrate(p));check(again==p and p.schema==3,'migrate_idempotent')
local two=R.newProfile(5);local creatures=#two.creatures
check(S.migrate(two) and two.schema==3 and #two.creatures==creatures,'schema2_to_3_adds_only_v1')
check(Run.migrate(two)==two,'custody_migration_accepts_schema3')
local clash=R.newProfile(5);clash.v1={evil=true};check(S.migrate(clash)==nil and clash.schema==2,'unknown_v1_field_refused_not_clobbered')
local broken=R.newProfile(5);S.migrate(broken);broken.v1.eggTickets=-1;check(S.migrate(broken)==nil,'invalid_schema3_refused')
check(S.migrate({schema=99})==nil and S.migrate({schema=4})==nil,'future_schema_refused')
-- custody rules still work on schema 3
local e={id='a',species='mossbun',section=1,hitsRequired=1,runId='run:a'}
local q=S.migrate(R.newProfile(1));check(Run.strike(q,e,1) and Run.pickup(q,'run:a') and Run.secure(q,'run:a') and #q.creatures==4,'custody_on_schema3')
check(not R.winGuardian(q,1,true),'legacy_trial_bypass_still_blocked_on_schema3')
-- validation bounds
local v=S.new();check(S.valid(v),'fresh_valid')
local function bad(mut,name) local c=deep(S.new());mut(c);check(not S.valid(c),name) end
bad(function(c) c.eggTickets=1/0 end,'inf_tickets')
bad(function(c) c.eggTickets=0/0 end,'nan_tickets')
bad(function(c) c.tokens.gold=1 end,'unknown_token')
bad(function(c) c.passes.vip='yes' end,'set_values_true_only')
bad(function(c) for i=1,201 do c.processed[i]='r'..i end end,'receipt_ring_bound')
bad(function(c) c.processed[3]='gap' end,'sparse_ring')
bad(function(c) c.title='unowned' end,'equipped_title_must_be_owned')
bad(function(c) c.daily.quests={{id='x',goal=0,progress=0,claimed=false}} end,'quest_goal_positive')
bad(function(c) c.daily.quests={{},{},{},{}} end,'quest_count_bound')
bad(function(c) c.raid.loot=0.5 end,'raid_ints')
-- wallet
local w=S.migrate(R.newProfile(0));local now=1000
check(not W.grant(w,{coins=-5},now) and w.coins==0,'negative_rejected')
check(not W.grant(w,{creature='floravelle'},now),'no_creature_rewards')
check(not W.grant(w,{boost='attack',seconds=10},now),'no_power_boosts')
check(not W.grant(w,{boost='xp'},now),'boost_needs_seconds')
local got=W.grant(w,{coins=10,eggTickets=2,cosmetic='trim_x',title='t1',raidReroll=1},now)
check(got and w.coins==10 and w.v1.eggTickets==2 and w.v1.cosmetics.trim_x and w.v1.titles.t1 and w.v1.tokens.raidReroll==1,'grant_all_kinds')
for _=1,10 do W.grant(w,{boost='production',seconds=3600},now) end
check(w.v1.boosts.production==now+V.wallet.boostCapSeconds,'boost_capped')
check(W.boostActive(w,'production',now) and not W.boostActive(w,'xp',now),'boost_active')
check(W.grant(w,{boost='production',seconds=3600},now).seconds==0,'capped_boost_reports_zero')
for _=1,60 do W.grant(w,{shield=1},now) end;check(w.v1.tokens.shield==V.wallet.maxTokens,'token_cap')
check(S.valid(w.v1),'valid_after_grants')
-- time boundaries: daily 00:00 UTC, week Monday 00:00 UTC
check(V.dayIndex(86399)==0 and V.dayIndex(86400)==1,'day_boundary_utc')
check(V.weekIndex(4*86400-1)==0 and V.weekIndex(4*86400)==1,'week_starts_monday') -- 1970-01-05 was a Monday
check(V.weekStart(V.weekIndex(1761609600))<=1761609600 and V.weekStart(V.weekIndex(1761609600)+1)>1761609600,'week_start_roundtrip')
check(os.date('!%w',V.weekStart(2911))=='1','week_start_is_monday')
print('PASS '..n..' v1 schema/wallet checks')
