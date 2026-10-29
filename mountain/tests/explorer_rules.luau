-- Player XP (Glassbloom P2 §2, C3): curve, derived one-time XP, caps, monotonic day, normalize, ensure, summary.
local C=require('../shared/Catalog')
local R=require('../shared/Rules')
local X=require('../shared/ExplorerRules')
local n=0;local function check(v,name) assert(v,name);n+=1 end
-- §2.2 table, L1–30: {next, total}.
local curve={{60,0},{100,60},{140,160},{180,300},{220,480},{260,700},{300,960},{340,1260},{380,1600},{420,1980},
 {460,2400},{500,2860},{540,3360},{580,3900},{620,4480},{660,5100},{700,5760},{740,6460},{780,7200},{820,7980},
 {860,8800},{900,9660},{940,10560},{980,11500},{1020,12480},{1060,13500},{1100,14560},{1140,15660},{1180,16800},{1220,17980}}
for L,row in ipairs(curve) do
 check(X.need(L)==row[1] and X.start(L)==row[2],'curve_row_'..L)
 check(X.level(row[2])==L and (L==1 or X.level(row[2]-1)==L-1),'level_boundary_'..L)
end
check(X.level(59)==1 and X.level(60)==2,'level_59_is_1_and_60_is_2')
check(X.cap==49980 and X.start(50)==49980 and X.level(49979)==49 and X.level(49980)==50 and X.level(1e9)==50,'cap_L50_49980')
check(X.level(-5)==1 and X.level(0/0)==1 and X.level(math.huge)==1,'level_of_garbage_is_1')
local function fresh() return R.newProfile(100) end
local p=fresh()
check(type(p.explorer)=='table' and p.explorer.v==1 and p.explorer.repeatXp==0 and p.explorer.day==0 and next(p.explorer.species)==nil and next(p.explorer.won)==nil,'new_profile_default_explorer')
local s=X.summary(p);check(s.xp==0 and s.level==1 and s.into==0 and s.need==60 and s.cap==49980,'new_profile_summary')
-- X1: only the 18 free-climb rest points, 25×k; legacy ids are ignored.
p.discoveries={['1:entrance']=true,['2:recovery']=true,['6:guardian']=true,summit=true,['1:discovery']=true,['7:entrance']=true,['0:recovery']=true,['1:entrance:x']=true,[5]=true}
check(X.xp(p)==25+50+150,'rest_points_only_legacy_ids_ignored')
-- One-time pool: all rest points, wins, species and captures = 8,475.
local full=fresh();for k=1,6 do for _,kind in ipairs({'entrance','recovery','guardian'}) do full.discoveries[k..':'..kind]=true end;full.explorer.won[tostring(k)]=true;full.captures[C.guardians[k].id]=true end
local pool=0;for _,sp in ipairs(C.species) do if X.ledgerable(sp.id) then full.explorer.species[sp.id]=true;pool+=1 end end
check(pool==33 and X.xp(full)==8475,'one_time_pool_8475_over_33_species')
check(not X.ledgerable('mossbun') and not X.ledgerable('petalyn') and not X.ledgerable('fernox') and not X.ledgerable('floravelle') and not X.ledgerable('nope') and not X.ledgerable(7) and X.ledgerable('glimfox'),'ledger_pool_excludes_starters_legendary_unknown')
-- X4/X5 (home-base P2): secure pays by rarity (20/day); a new ledgerable species +50 on first insert only.
check(X.secureXp.Common==6 and X.secureXp.Uncommon==12 and X.secureXp.Rare==30 and X.secureXp.Epic==70 and X.secureXp.Mythic==150 and X.secureXp.Legendary==nil,'secure_rarity_table')
check(X.secureFor('mossbun')==6 and X.secureFor('fernox')==12 and X.secureFor('glimfox')==30 and X.secureFor('thorncub')==70 and X.secureFor('floramoth')==150,'secure_for_species')
check(X.secureFor('caeloryn')==0 and X.secureFor('nope')==0 and X.secureFor(nil)==0 and X.secureFor(7)==0,'secure_for_legendary_unknown_is_0')
local D=20000
p=fresh()
check(X.award(p,'secure',3,D,'glimfox')==80 and p.explorer.secures==1 and p.explorer.day==D,'secure_rare_30_plus_new_species')
check(X.award(p,'secure',3,D,'glimfox')==30,'second_same_species_no_bonus')
table.insert(p.creatures,{id='c9',species='glimfox',level=1,xp=0});table.remove(p.creatures)
check(X.award(p,'secure',1,D,'glimfox')==30 and X.award(p,'secure',1,D,'mossbun')==6,'ledger_first_insert_only_and_starter_pays_secure_only_section_ignored')
check(X.award(p,'secure',6,D,'caeloryn')==0 and not p.explorer.species.caeloryn,'legendary_never_in_ledger_and_pays_0')
p=fresh();p.explorer.secures=19;p.explorer.day=D
check(X.award(p,'secure',2,D,'mossbun')==6 and p.explorer.secures==20,'twentieth_secure_pays')
p=fresh();for i=1,25 do X.award(p,'secure',1,D,'floramoth') end
check(p.explorer.secures==20 and p.explorer.repeatXp==3000,'daily_secure_max_20_mythic_3000')
check(X.award(p,'secure',2,D,'mossbun')==0 and p.explorer.secures==20,'secure_cap_20_per_day')
check(X.award(p,'secure',2,D,'coralfen')==50 and p.explorer.species.coralfen,'capped_secure_still_ledgers_a_new_species')
-- X2/X3: first win per section 100k (derived from won), repeats 10k up to 5/day.
p=fresh()
check(X.award(p,'win',2,D)==200 and p.explorer.won['2'] and p.explorer.repeats==0,'first_win_100k')
for i=1,5 do check(X.award(p,'win',2,D)==20,'repeat_win_'..i) end
check(X.award(p,'win',4,D)==400,'first_win_other_section_is_not_a_repeat')
check(X.award(p,'win',2,D)==0 and p.explorer.repeats==5,'repeat_cap_5_per_day')
-- Monotonic day: D+1 → D → D+1 resets once.
check(X.award(p,'win',2,D+1)==20 and p.explorer.repeats==1 and p.explorer.day==D+1,'next_day_resets')
check(X.award(p,'win',2,D)==20 and p.explorer.repeats==2 and p.explorer.day==D+1,'earlier_day_never_resets_or_decreases')
check(X.award(p,'win',2,D+1)==20 and p.explorer.repeats==3,'same_day_again_no_second_reset')
-- Far-future day: clamped to today on load; D+1 is kept.
p=fresh();p.explorer.day=D+40;p.explorer.secures=7;X.ensure(p,D)
check(p.explorer.day==D and p.explorer.secures==7,'far_future_day_clamped_on_load')
p.explorer.day=D+1;X.ensure(p,D);check(p.explorer.day==D+1,'tomorrow_is_not_clamped')
-- Malformed explorer: normalized without error, never paying for bad ids.
for _,bad in ipairs({'junk',42,true,{repeatXp=0/0,day=-3,secures=-9,repeats=1e9,species='x',won={['1']=1,['9']=true,x=true}},
 {repeatXp=-50,day=0/0,species={floravelle=true,mossbun=true,nope=true,glimfox='yes',[1]=true},won={[1]=true,['2']=true}}}) do
 p=fresh();p.explorer=bad
 local ok=pcall(X.ensure,p,D)
 local e=p.explorer
 check(ok and type(e)=='table' and e.v==1 and e.repeatXp>=0 and e.repeatXp==math.floor(e.repeatXp) and e.day>=0 and e.secures>=0 and e.secures<=20 and e.repeats>=0 and e.repeats<=5,'malformed_normalized_'..type(bad))
 for id in pairs(e.species) do check(X.ledgerable(id),'malformed_species_dropped') end
 for key in pairs(e.won) do check(key=='1' or key=='2' or key=='3' or key=='4' or key=='5' or key=='6','malformed_won_keys_dropped') end
end
check(p.explorer.repeatXp==0 and p.explorer.day==0 and next(p.explorer.species)==nil and p.explorer.won['2'] and not p.explorer.won['1'],'bad_values_dropped_good_kept')
p=fresh();p.explorer={repeatXp=1e12}
check(X.award(p,'secure',1,D,'mossbun')==0 and X.xp(p)==49980 and p.explorer.repeatXp+X.derived(p)<=49980,'repeat_xp_bounded_by_cap')
-- Total: award never errors and never returns false.
for _,args in ipairs({{nil,'secure',1,D},{'p','win',1,D},{fresh(),'win',0/0,D},{fresh(),'secure',7,D,'glimfox'},{fresh(),'??',1,D},{fresh(),'win',1,0/0}}) do
 local ok,v=pcall(X.award,table.unpack(args,1,5))
 check(ok and type(v)=='number' and v>=0,'award_total')
end
p=fresh();check(X.award(p,'win',1,0/0)==100 and p.explorer.day==0,'non_finite_today_never_resets')
-- Migration seed: absent fields only; species from origin==nil, ledgerable creatures; won from p.wins.
p=fresh();p.explorer=nil;p.wins={['1']=true,['3']=true}
for i,sp in ipairs({'glimfox','floravelle','bubblit','coralfen','mistfin'}) do table.insert(p.creatures,{id='m'..i,species=sp,level=1,xp=0,origin=if sp=='bubblit' then 'coin' elseif sp=='mistfin' then 'robux' else nil}) end
X.ensure(p,D)
check(p.explorer.species.glimfox and p.explorer.species.coralfen and not p.explorer.species.floravelle and not p.explorer.species.mossbun,'seed_earned_ledgerable_species')
check(not p.explorer.species.bubblit and not p.explorer.species.mistfin,'seed_excludes_coin_and_robux_origin')
check(p.explorer.won['1'] and p.explorer.won['3'] and not p.explorer.won['2'],'seed_won_from_wins')
local seeded=X.xp(p);X.ensure(p,D);check(X.xp(p)==seeded,'ensure_is_idempotent')
p=fresh();p.explorer={species={},won={}};p.wins={['1']=true};table.insert(p.creatures,{id='m1',species='glimfox',level=1,xp=0});X.ensure(p,D)
check(next(p.explorer.species)==nil and next(p.explorer.won)==nil,'present_fields_are_not_reseeded')
-- X6: a Trial capture is derived (150k) and touches no counter or the ledger.
p=fresh();p.captures.zenthari=true
check(X.xp(p)==450 and p.explorer.secures==0 and next(p.explorer.species)==nil,'trial_capture_derived_150k')
-- Summary at the cap.
s=X.summary(full);check(s.xp==8475 and s.level==X.level(8475) and s.into==8475-X.start(s.level) and s.need==X.need(s.level),'summary_progress')
p=fresh();p.explorer.repeatXp=49980;s=X.summary(p);check(s.xp==49980 and s.level==50 and s.into==0 and s.need==0 and s.cap==49980,'summary_at_cap')
print('PASS '..n..' explorer rules checks')
