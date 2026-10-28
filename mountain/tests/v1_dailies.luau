-- C07: hard streak, UTC resets, deterministic quests, one free reroll, server-only progress, one claim per period.
local S=require('../shared/V1Schema')
local D=require('../shared/Dailies')
local V=require('../shared/V1Config')
local n=0
local function check(v,name) assert(v,name);n+=1 end
local day=86400
local t0=20000*day+3600 -- 01:00 UTC
local d=S.new().daily
check(D.refresh(d,42,t0) and #d.quests==3 and d.weekly,'first_refresh_assigns')
local groups={};for _,q in ipairs(d.quests) do groups[D.byId[q.id].group]=true end
check(groups.mountain and groups.home and groups.social,'one_quest_per_pool')
local same=S.new().daily;D.refresh(same,42,t0+5000)
check(same.quests[1].id==d.quests[1].id and same.quests[3].id==d.quests[3].id and same.weekly.id==d.weekly.id,'deterministic_across_servers')
local other=S.new().daily;local differs=false
for uid=1,30 do D.refresh(other,uid,t0);other.day=-1;if other.quests[1].id~=d.quests[1].id then differs=true end end
check(differs,'varies_by_player')
check(not D.refresh(d,42,t0+60),'same_day_no_refresh')
-- login streak: hard reset on a missed UTC day
check(D.login(d,t0) and d.streak==1,'first_login')
check(not D.login(d,t0+3600) and d.streak==1,'same_day_login_once')
check(D.login(d,t0+day) and d.streak==2,'next_day_streak')
local r,id=D.claimLogin(d,t0+day);check(r and r.coins==150 and id=='l:'..(20001),'claim_day2_reward')
check(not D.claimLogin(d,t0+day+10),'login_claim_once_per_day')
check(not D.claimLogin(d,t0+2*day),'claim_requires_login_today')
check(D.login(d,t0+3*day) and d.streak==1,'missed_day_hard_reset')
for k=1,7 do D.login(d,t0+(3+k)*day) end
check(d.streak==8 and D.loginReward(8).coins==100 and D.loginReward(7).eggTickets==2,'track_wraps_after_7')
-- 23:59:59 -> 00:00:00 UTC boundary
local edge=S.new().daily;local midnight=20100*day
D.login(edge,midnight-1);check(D.login(edge,midnight) and edge.streak==2,'midnight_utc_is_new_day')
-- progress is server-only and bounded
local q=S.new().daily;D.refresh(q,7,t0)
local slot;for i,x in ipairs(q.quests) do if D.byId[x.id].group=='mountain' then slot=i end end
local def=D.byId[q.quests[slot].id]
check(#D.track(q,7,def.event,-1,t0)==0 and #D.track(q,7,def.event,0/0,t0)==0 and #D.track(q,7,def.event,1.5,t0)==0,'bad_amounts_ignored')
check(#D.track(q,7,'not_an_event',1,t0)==0,'unknown_event_ignored')
check(not D.claim(q,7,slot,t0),'cannot_claim_incomplete')
D.track(q,7,def.event,def.goal*5,t0);check(q.quests[slot].progress==def.goal,'progress_capped')
local reward,cid=D.claim(q,7,slot,t0);check(reward==def.reward and cid=='q:'..q.day..':'..slot,'claim_complete')
check(not D.claim(q,7,slot,t0),'claim_once')
check(not D.claim(q,7,9,t0) and not D.claim(q,7,'x',t0) and not D.claim(q,7,1.5,t0),'invalid_slots')
check(not D.reroll(q,7,slot,t0),'cannot_reroll_claimed')
-- reroll once per day, same group, different id, progress resets
local rr=S.new().daily;D.refresh(rr,9,t0)
local before=rr.quests[2].id;D.track(rr,9,D.byId[before].event,1,t0)
check(D.reroll(rr,9,2,t0) and rr.quests[2].id~=before and rr.quests[2].progress==0 and D.byId[rr.quests[2].id].group=='home','reroll_same_group')
check(not D.reroll(rr,9,1,t0),'one_reroll_per_day')
check(D.reroll(rr,9,'weekly',t0) and not D.reroll(rr,9,'weekly',t0),'one_weekly_reroll')
check(D.refresh(rr,9,t0+day) and rr.rerolls==0 and D.reroll(rr,9,1,t0+day),'reroll_resets_daily')
-- new day replaces quests and clears claim flags; weekly survives until Monday
local wk=S.new().daily;local monday=V.weekStart(3000);D.refresh(wk,5,monday+10)
local wid=wk.weekly.id;D.track(wk,5,D.byId[wid].event,1,monday+10)
D.refresh(wk,5,monday+3*day);check(wk.weekly.id==wid and wk.weekly.progress==1,'weekly_persists_midweek')
D.refresh(wk,5,monday+7*day);check(wk.weekly.progress==0 and wk.week==3001,'weekly_resets_monday')
-- weekly claim once
D.track(wk,5,D.byId[wk.weekly.id].event,999,monday+7*day)
check(D.claim(wk,5,'weekly',monday+7*day) and not D.claim(wk,5,'weekly',monday+7*day+60),'weekly_claim_once')
check(S.valid({version=1,processed={},passes={},tokens={raidReroll=0,shield=0},eggTickets=0,cosmetics={},titles={},badges={},boosts={production=0,xp=0},daily=wk,raid={day=-1,attacks=0,loot=0,rerolls=0,practice=0,friendlyWins=0,friendlyPlayed=0},applied={},seasons={},seasonSeen=-1}),'daily_state_valid')
-- rewards contain no power
for id,qd in pairs(D.byId) do check(qd.reward.creature==nil and qd.reward.attack==nil,'no_power '..id) end
local view=D.view(wk,monday+7*day);check(view.weekly and view.resetAt>monday+7*day and #view.quests==3,'view_shape')
print('PASS '..n..' dailies checks')
