-- End-to-end through UIRequests + V1Protocol: forged payloads, rate limit, replayed ids, daily claims across
-- servers, failed-save freeze, disabled shop, party/raid/season/title actions, server-only progress.
local now=60000*86400+7200
local backend=Store.memory()
local A_=Profiles.newForTests(backend,'vA')
local B_=Profiles.newForTests(backend,'vB')
local outStore,outIndex=Store.memory(),Store.memory()
local online={};local events={};local g=0
local function make(profiles)
 local v1=V1Services.new({profiles=profiles,clock=function() return now end,notify=function(pl,kind,data) table.insert(events,{pl.UserId,kind,data}) end,
  playerByUserId=function(id) return online[id] end,outposts={store=outStore,index=outIndex},
  receipts={checkoutEnabled=function() return V1Config.checkoutEnabled end,prompt=function() error('checkout must never prompt while disabled') end,ownsPass=function() return true,false end},
  party={travel=function() return true end,follow=function() return true end,jobId='job'},isFriend=function() return false end,friends=function() return {} end,
  productionRate=function() return 300 end,teamXP=function() end,guid=function() g+=1;return 'v'..g end})
 local clockT=0
 local ui=UIRequests.new({handle=v1.handle,available=function(pl) return profiles.get(pl)~=false and profiles.get(pl)~=nil end,validate=V1Protocol.validate,clock=function() return clockT end})
 return v1,ui,function(dt) clockT+=dt end
end
local v1,ui,advance=make(A_)
local pl={UserId=7007,Name='Seven'}
A_.load(pl);online[7007]=pl
check(v1.join(pl),'join')
local p=A_.get(pl)
check(p.v1.daily.streak==1 and #p.v1.daily.quests==3,'join_logs_in_and_assigns_quests')
local pushed=false;for _,e in ipairs(events) do if e[2]=='v1_state' and e[3].daily and e[3].shop then pushed=true end end
check(pushed,'v1_state_pushed_on_join')
local seq=0
local function req(action,payload) seq+=1;advance(1);return ui.process(pl,'v1:'..seq,action,payload) end
-- forged / malformed payloads
check(not req('Daily_Claim',{slot=1,coins=999}).ok,'extra_field_rejected')
check(not req('Daily_Claim',{slot=0/0}).ok and not req('Daily_Claim',{slot=4}).ok,'bad_slot_rejected')
check(not req('Grant_Coins',nil).ok,'unknown_action_rejected')
check(not req('Raid_Submit',{attackId='x',creatures={'c1','c2'},lanes={1}}).ok,'lane_count_mismatch_rejected')
check(not req('Party',{op='invite'}).ok and not req('Party',{op='invite',userId=-5}).ok and not req('Party',{op='nuke'}).ok,'party_payloads')
check(not req('Shop_Prompt',{key=string.rep('a',200)}).ok,'long_key_rejected')
check(not req('Raid_Find',{revenge=1.5}).ok,'fractional_user_rejected')
-- rate limit + replay cache
seq+=1;local id='v1:'..seq
local r1=ui.process(pl,id,'V1_State',nil);local r2=ui.process(pl,id,'V1_State',nil)
check(r1.ok and r2==r1,'replayed_id_returns_cached_result')
seq+=1;local fast=ui.process(pl,'v1:'..seq,'V1_State',nil)
check(not fast.ok and fast.message:find('wait'),'rate_limited')
check(not ui.process(pl,'v1:1','V1_State',nil).ok,'old_sequence_expired')
-- daily login + quest claims
local lr=req('Daily_ClaimLogin',nil);check(lr.ok and A_.get(pl).coins==100,'login_reward')
check(not req('Daily_ClaimLogin',nil).ok and A_.get(pl).coins==100,'login_once')
local q=A_.get(pl).v1.daily.quests;local slot;for i,x in ipairs(q) do if Dailies.byId[x.id].group=='mountain' then slot=i end end
check(req('Daily_Claim',{slot=slot}).message=='not_complete','incomplete_claim_refused')
local def=Dailies.byId[q[slot].id]
-- progress only via server hooks (observe/track), never via a client payload
if def.event=='strike' or def.event=='secure' then for _=1,def.goal do v1.observe(pl,{kind=if def.event=='strike' then 'strike' else 'safe'}) end
else v1.track(pl,def.event,def.goal) end
local before=A_.get(pl).coins
local cr=req('Daily_Claim',{slot=slot});check(cr.ok and cr.data.granted,'quest_claimed')
check(not req('Daily_Claim',{slot=slot}).ok,'quest_claim_once')
-- failed-save freeze: claim during outage freezes, other claims refused, retry commits once
local home;for i,x in ipairs(A_.get(pl).v1.daily.quests) do if Dailies.byId[x.id].group=='home' then home=i end end
local hdef=Dailies.byId[A_.get(pl).v1.daily.quests[home].id];v1.track(pl,hdef.event,hdef.goal)
backend.failAll=true
local frozen=req('Daily_Claim',{slot=home});check(not frozen.ok,'outage_claim_not_acknowledged')
check(not A_.get(pl),'profile_frozen_after_failed_save')
check(not req('V1_State',nil).ok,'actions_blocked_while_frozen')
backend.failAll=false
A_.save(pl,false)
check(A_.get(pl) and A_.get(pl).v1.daily.quests[home].claimed,'pending_claim_committed_on_save')
check(not req('Daily_Claim',{slot=home}).ok,'no_second_grant_after_recovery')
-- server change same UTC day: claims stay claimed, streak not double-counted
local coinsBefore=A_.get(pl).coins
check(A_.save(pl,true),'leave_A');v1.remove(pl)
local v1b,uib,advb=make(B_)
B_.load(pl);v1b.join(pl)
check(B_.get(pl).coins==coinsBefore and B_.get(pl).v1.daily.streak==1,'rejoin_B_same_day')
seq+=1;advb(5);check(not uib.process(pl,'v2:'..seq,'Daily_ClaimLogin',nil).ok,'login_claim_once_across_servers')
seq+=1;advb(5);check(not uib.process(pl,'v2:'..seq,'Daily_Claim',{slot=slot}).ok,'quest_claim_once_across_servers')
-- next UTC day: tick rolls quests and streak
now+=86400;v1b.tick()
check(B_.get(pl).v1.daily.streak==2 and B_.get(pl).v1.daily.day==V1Config.dayIndex(now),'tick_rolls_day_and_streak')
-- shop: checkout disabled, all unavailable, prompt never reaches MarketplaceService
seq+=1;advb(5);local shop=uib.process(pl,'v2:'..seq,'Shop_State',nil)
local allOff=shop.ok;for _,item in ipairs(shop.data.items) do if item.state~='unavailable' then allOff=false end end
check(allOff and shop.data.checkoutEnabled==false,'shop_all_unavailable')
seq+=1;advb(5);check(not uib.process(pl,'v2:'..seq,'Shop_Prompt',{key='starter_pack'}).ok,'prompt_refused_while_disabled')
-- party / outpost / raid / season / title through the gateway
seq+=1;advb(5);check(uib.process(pl,'v2:'..seq,'Party',{op='create'}).ok,'party_create_via_gateway')
seq+=1;advb(5);local os_=uib.process(pl,'v2:'..seq,'Outpost_State',nil);check(os_.ok and os_.data.snapshot and os_.data.attacksLeft==5,'outpost_state_via_gateway')
seq+=1;advb(5);check(not uib.process(pl,'v2:'..seq,'Outpost_SetSlot',{slot=9,piece='gravity_well'}).ok,'locked_piece_via_gateway')
seq+=1;advb(5);local fr=uib.process(pl,'v2:'..seq,'Raid_Find',nil);check(fr.ok and fr.data.offerId,'raid_find_via_gateway')
seq+=1;advb(5);local st=uib.process(pl,'v2:'..seq,'Raid_Start',{offerId=fr.data.offerId});check(st.ok,'raid_start_via_gateway')
seq+=1;advb(5);local sb=uib.process(pl,'v2:'..seq,'Raid_Submit',{attackId=st.data.attackId,creatures={'c1','c2','c3'},lanes={1,2,3}});check(sb.ok and sb.data.events,'raid_submit_via_gateway')
seq+=1;advb(5);check(uib.process(pl,'v2:'..seq,'Season_State',nil).ok,'season_state_via_gateway')
seq+=1;advb(5);check(not uib.process(pl,'v2:'..seq,'Title_Equip',{id='astral_sovereign'}).ok,'unowned_title_refused')
B_.get(pl).v1.titles.gold_climber=true
seq+=1;advb(5);check(uib.process(pl,'v2:'..seq,'Title_Equip',{id='gold_climber'}).ok and B_.get(pl).v1.title=='gold_climber','owned_title_equipped')
check(Profiles.valid(B_.get(pl)),'profile_valid_end')
-- duo scaling values
check(V1Services.duoHealth(false,1)==1 and V1Services.duoHealth(false,2)==1.5 and V1Services.duoHealth(true,2)==1.45 and V1Services.duoHealth(false,8)==1.5,'duo_health_scaling')
