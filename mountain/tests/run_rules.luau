-- Guards ownership against reveal, repeated exits, lost Trials and destructive migration.
local R=require('../shared/Rules')
local C=require('../shared/Catalog')
local n=0
local function check(v,name) assert(v,name);n+=1 end
local p=R.newProfile(100)
for k=1,6 do check(R.canEnter(p,k),'all_six_open_without_wins '..k) end
local Run=require('../shared/RunRules')
local function fresh() return Run.migrate(R.newProfile(100)) end
local function egg(id,trial) return {id=id,species=if trial then 'floravelle' else 'mossbun',section=1,trial=trial,hitsRequired=2,runId='run:'..id} end
p=fresh();local e=egg('a')
check(Run.strike(p,e,100),'first strike')
check(not Run.strike(p,egg('b'),101),'one_run_only')
check(Run.strike(p,e,101) and p.run.phase=='revealed' and #p.creatures==3,'reveal_is_not_ownership')
check(not Run.secure(p,'run:a'),'must_pickup_before_exit')
check(Run.pickup(p,'run:a') and Run.secure(p,'run:a') and #p.creatures==4,'exit_once')
check(Run.secure(p,'run:a') and #p.creatures==4,'retry_exit_once')
for _,reason in ipairs({'catch','fall','leave','reset'}) do
 p=fresh();Run.strike(p,e,100);Run.strike(p,e,101);Run.pickup(p,'run:a')
 check(Run.forfeit(p,reason) and p.run==nil and #p.creatures==3,'catch_fall_leave_reset_forfeit '..reason)
end
p=fresh();p.wins['1']=true;check(not R.winGuardian(p,1,true) and not p.captures.floravelle,'legacy_trial_cannot_bypass_exit');local t=egg('trial',true)
check(Run.strike(p,t,100) and Run.strike(p,t,101) and not p.captures.floravelle,'trial_capture_only_on_exit')
Run.pickup(p,'run:trial');Run.forfeit(p,'catch')
check(Run.strike(p,t,102),'lost_trial_can_retry');Run.strike(p,t,103);Run.pickup(p,'run:trial')
check(Run.secure(p,'run:trial') and p.captures.floravelle,'trial exit captures')
check(not Run.strike(p,egg('trial2',true),104),'secured trial cannot duplicate')
p=R.newProfile(100);p.schema=1;p.cargo={{id='old1',species='mossbun'}};p.recovery={eggs={{id='old1',species='mossbun'},{id='old2',species='petalyn'}},expires=1};p.eggs={{id='ready',species='fernox',readyAt=110}}
p.coins=91;p.captures.floravelle=true
Run.migrate(p);Run.migrate(p)
check(p.schema==2 and #p.eggs==3 and #p.cargo==0 and p.recovery==nil and p.coins==91 and p.eggs[1].readyAt==110 and p.captures.floravelle,'legacy_migration_twice_no_duplicates')
local bad={schema=99,coins=44};check(Run.migrate(bad)==nil and bad.schema==99 and bad.coins==44,'invalid_profile_no_overwrite')
print('PASS '..n..' run custody checks')
