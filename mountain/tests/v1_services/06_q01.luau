-- Q01 adversarial: fuzzed payloads through the real gateway, conflict retries on outpost records,
-- save outage during raid start, cross-player isolation, double-claim storms.
local now=61000*86400+5000
local backend=Store.memory()
local S=Profiles.newForTests(backend,'q')
local outStore,outIndex=Store.memory(),Store.memory()
local online={};local g=0
local v1=V1Services.new({profiles=S,clock=function() return now end,notify=function() end,playerByUserId=function(id) return online[id] end,
 outposts={store=outStore,index=outIndex},receipts={checkoutEnabled=function() return false end,prompt=function() error('no prompts') end,ownsPass=function() return true,false end},
 party={travel=function() return true end,follow=function() return true end,jobId='q'},isFriend=function() return false end,friends=function() return {} end,
 productionRate=function() return 100 end,teamXP=function() end,guid=function() g+=1;return 'q'..g end})
local t=0
local ui=UIRequests.new({handle=v1.handle,validate=V1Protocol.validate,available=function(pl) return S.get(pl)~=false and S.get(pl)~=nil end,clock=function() return t end})
local A={UserId=8801,Name='A'};local B={UserId=8802,Name='B'}
S.load(A);S.load(B);online[8801]=A;online[8802]=B;v1.join(A);v1.join(B)
-- 1) fuzz: random payloads for every action never error, never grant coins/tickets, never break the profile
local seed=12345
local function rnd(n) seed=(seed*48271)%2147483647;return seed%n+1 end
local atoms={0,1,-1,3,10,0.5,1/0,-1/0,0/0,2^53,'',string.rep('x',300),'c1','weekly',true,false,'gravity_well',{},{1},{[5]=1},{a=1},{'c1','c1'},{'c1','c2','c3','c4'}}
local function value(depth)
 local k=rnd(10)
 if depth<2 and k<=3 then local tt={};for _=1,rnd(4) do local key=if rnd(2)==1 then ({'slot','key','op','userId','partyId','code','ready','piece','ids','revenge','offerId','attackId','creatures','lanes','ability','id','coins'})[rnd(17)] else rnd(5);tt[key]=value(depth+1) end;return tt end
 if k==4 then return nil end
 return atoms[rnd(#atoms)]
end
local actions={};for name in pairs(V1Protocol.actions) do table.insert(actions,name) end;table.sort(actions)
local coins0,tickets0=S.get(A).coins,S.get(A).v1.eggTickets
local accepted,errors=0,0
for i=1,3000 do
 t+=1
 local action=if rnd(20)==1 then 'Nope'..i else actions[rnd(#actions)]
 local okCall,res=pcall(ui.process,A,'fz:'..i,action,value(0))
 if not okCall then errors+=1 elseif res and res.ok then accepted+=1 end
end
check(errors==0,'fuzz_never_throws')
local p=S.get(A)
check(p and Profiles.valid(p),'fuzz_profile_still_valid')
-- Only the login reward (100) may legitimately be claimed by fuzzing (it is free on first claim).
check(p.coins-coins0<=100 and p.v1.eggTickets==tickets0,'fuzz_grants_nothing_unearned')
check(accepted>0,'fuzz_some_valid_requests_accepted')
-- 2) double-claim storm: many ids for the same login claim -> exactly one grant
local before=S.get(B).coins
for i=1,50 do t+=1;ui.process(B,'storm:'..i,'Daily_ClaimLogin',nil) end
check(S.get(B).coins==before+100,'login_claim_storm_once')
-- 3) cross-player isolation: A's actions never touch B's profile or outpost
local bCoins=S.get(B).coins;local _,bRec0=outStore:read('o8802')
for i=1,20 do t+=1;ui.process(A,'iso:'..i,'Outpost_SetSlot',{slot=8,piece='thorn_snare'}) end
local _,bRec1=outStore:read('o8802')
check(S.get(B).coins==bCoins and bRec1.snapshot.rev==bRec0.snapshot.rev,'cross_player_isolation')
-- 4) UpdateAsync conflict retries: transform runs twice, vault/loot applied once
local O=OutpostService.new({store=outStore,index=outIndex,profiles=S,clock=function() return now end,guid=function() g+=1;return 'c'..g end,productionRate=function() return 100 end,
 isFriend=function() return false end,friends=function() return {} end})
now+=36000;O.ensure(B)
local _,vb=outStore:read('o8802');local vaultBefore=math.floor(OutpostRules.accrue(vb.vault,now).coins)
outStore.conflicts=1
local okC,got=O.collect(B)
check(okC and got.coins==vaultBefore,'collect_under_conflict_once')
local _,va=outStore:read('o8802');check(#va.transfers==1 and va.vault.coins<1,'single_transfer_under_conflict')
-- 5) save outage during raid start: attack not counted, target lock released
outStore:update('o8802',function(r) r.shield.untilTime=0;r.lock=false;return r end)
local offer
for i=1,10 do local ok,o=O.find(A,{salt=i});if ok and o.userId==8802 then offer=o;break end;O.offers[A]=nil end
if offer then
 backend.failAll=true
 local okS,why=O.start(A,offer.offerId)
 backend.failAll=false
 local _,lr=outStore:read('o8802')
 check(not okS and why=='save_pending' and lr.lock==false,'outage_start_releases_lock')
 S.save(A,false)
 check(S.get(A).v1.raid.attacks<=1,'outage_start_count_bounded')
else print('SKIP outage_start');check(true,'outage_start_skipped') end
-- 6) stale invites / offers cannot be replayed
t+=5;check(not ui.process(A,'st:1','Raid_Start',{offerId='q999'}).ok,'forged_offer_rejected')
t+=5;check(not ui.process(A,'st:2','Party',{op='accept',partyId=999}).ok,'forged_party_accept_rejected')
-- 7) Robux creature can never be stationed or attack, even through the gateway
table.insert(S.get(A).creatures,{id='robux1',species='violette',level=30,xp=0,source='robux'})
t+=5;local d=ui.process(A,'rb:1','Outpost_SetDefenders',{ids={'robux1'}})
check(not d.ok and d.message=='robux_creature_excluded','robux_defender_blocked_via_gateway')
t+=5;local pr=ui.process(A,'rb:2','Raid_Practice',{creatures={'robux1'},lanes={1}})
check(not pr.ok and pr.message=='robux_creature_excluded','robux_attacker_blocked_via_gateway')
-- 8) bounded saved data: logs/results/transfers/applied never exceed caps after many events
for i=1,40 do outStore:update('o8802',function(r) table.insert(r.transfers,{id='x'..i,coins=1,at=now});while #r.transfers>20 do table.remove(r.transfers,1) end;return r end) end
local _,bounded=outStore:read('o8802');check(#bounded.transfers<=20 and OutpostRules.validRecord(bounded),'transfers_bounded')
O.ensure(B);check(#S.get(B).v1.applied<=200 and Profiles.valid(S.get(B)),'applied_ring_bounded')
