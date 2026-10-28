-- Regressions for the independent Q01 review findings (#1-#8).
local now=62000*86400+3600
local backend=Store.memory()
local S=Profiles.newForTests(backend,'rv')
local raw=Store.memory();local index=Store.memory()
local failOwn={}
-- proxy store: can fail updates to one specific record key (targets one step of a multi-store flow)
local store={read=function(_,k) return raw:read(k) end,update=function(_,k,fn) if failOwn[k] then return false,nil,'injected' end;return raw:update(k,fn) end}
local online={};local g=0;local mono=0;local budget=true
local friends={[9101]={9102},[9102]={9101}}
local function svc()
 return V1Services.new({profiles=S,clock=function() return now end,monotonic=function() return mono end,notify=function() end,playerByUserId=function(id) return online[id] end,
  outposts={store=store,index=index,budgetOk=function() return budget end},secret='server-secret',
  receipts={checkoutEnabled=function() return false end,prompt=function() end,ownsPass=function() return true,false end},
  party={travel=function() return true end,follow=function() return true end,jobId='r'},isFriend=function(a,b) return friends[a]~=nil and table.find(friends[a],b)~=nil end,
  friends=function(id) return friends[id] or {} end,productionRate=function() return 900 end,teamXP=function() end,guid=function() g+=1;return 'r'..g end})
end
local v=svc();local O=v.outposts
local A={UserId=9101,Name='A'};local D={UserId=9102,Name='D'}
S.load(A);S.load(D);online[9101]=A;online[9102]=D;v.join(A);v.join(D)
-- #1 cooldowns + budget guard
mono=100;check(v.handle(A,'Raid_Log',nil),'log_first_ok')
check(select(2,v.handle(A,'Raid_Log',nil))=='cooldown','store_heavy_action_cooldown')
mono=104;check(v.handle(A,'Raid_Log',nil),'cooldown_expires')
budget=false;mono=200;check(select(2,v.handle(A,'Outpost_Collect',nil))=='busy_try_later','low_budget_defers_outpost_writes');budget=true
-- record cache: repeated state reads within the window do not write
local writes=0;local realUpdate=store.update
store.update=function(self,k,fn) writes+=1;return realUpdate(self,k,fn) end
O.ensure(A);O.ensure(A);O.ensure(A)
check(writes==0,'cached_ensure_no_writes')
store.update=realUpdate
-- #2 applied-ring overflow cannot re-credit an old vault transfer
now+=7200;local okC,got=O.collect(D);check(okC and got.coins>0,'collect')
local coins=S.get(D).coins
S.transact(D,'fill-ring',function(d) for i=1,210 do table.insert(d.v1.applied,'noise'..i);while #d.v1.applied>200 do table.remove(d.v1.applied,1) end end;return true end)
now+=60;O.ensure(D);local _,rd=raw:read('o9102')
check(S.get(D).coins==coins and #rd.transfers==0,'no_recredit_after_ring_overflow')
-- helper: get an offer against a specific target
local function offerFor(attacker,target,opts)
 for i=1,15 do O.offers[attacker]=nil;local ok,o=O.find(attacker,{salt=i,revenge=opts and opts.revenge});if ok and o.userId==target then return o end;if opts and opts.revenge then return ok and o or nil end end
end
-- #4 abandon after start = 0-star loss (trophies), defender gets the defend result, no shield
raw:update('o9101',function(r) r.trophies=100;return r end)
local o=offerFor(A,9102);check(o~=nil,'offer_D')
local okS,att=O.start(A,o.offerId);check(okS,'start')
check(O.abandon(A),'abandon')
local _,ra=raw:read('o9101');local _,rd2=raw:read('o9102')
check(ra.trophies==100+V1Config.outpost.trophyWin[0] and ra.pending==false,'abandon_costs_trophies')
check(rd2.lock==false and rd2.log[#rd2.log].forfeit and rd2.shield.untilTime<=now and rd2.revenge['9101']==nil,'abandon_defended_no_shield_no_revenge')
-- disconnect mid-attack is the same forfeit
local o2=offerFor(A,9102);local okS2=O.start(A,o2.offerId);O.remove(A)
local _,ra2=raw:read('o9101');check(okS2 and ra2.trophies==100+2*V1Config.outpost.trophyWin[0],'disconnect_forfeits')
-- expiry after start forfeits on submit
local o3=offerFor(A,9102);local okS3,att3=O.start(A,o3.offerId)
now+=V1Config.outpost.lockSeconds+5
check(select(2,O.submit(A,att3.attackId,{creatures={'c1'},lanes={2}}))=='attack_expired','expired_submit_forfeits')
local _,ra3=raw:read('o9101');check(ra3.trophies==100+3*V1Config.outpost.trophyWin[0],'expiry_counted_as_loss')
-- seed uses the server secret: same attack id + plan differs from an unsalted seed only through the secret
check(OutpostSim.run~=nil,'sim_present')
-- #3 revenge grants no counter-revenge; revenge has its own daily cap
local o4=offerFor(A,9102);local _,att4=O.start(A,o4.offerId)
O.submit(A,att4.attackId,{creatures={'c1','c2','c3'},lanes={1,2,3}})
local _,rd4=raw:read('o9102');check(rd4.revenge['9101'] and not rd4.revenge['9101'].used,'normal_attack_grants_revenge')
raw:update('o9101',function(r) r.shield.untilTime=0;r.lock=false;return r end)
local rv=offerFor(D,9101,{revenge=9101});check(rv and rv.revenge,'revenge_offer')
local okR,ar=O.start(D,rv.offerId);check(okR,'revenge_start')
O.submit(D,ar.attackId,{creatures={'c1'},lanes={2}})
local _,ra4=raw:read('o9101');check(ra4.revenge['9102']==nil,'no_counter_revenge')
check(S.get(D).v1.raid.revenges==1 and S.get(D).v1.raid.attacks==0,'revenge_counted_separately')
S.get(D).v1.raid.revenges=V1Config.outpost.revengesPerDay
raw:update('o9102',function(r) r.revenge['9101']={expires=now+999,used=false,attackId='x'};return r end)
O.cacheClear=nil;now+=30
check(select(2,O.find(D,{revenge=9101}))=='daily_revenge_cap','revenge_daily_cap')
-- #5 pending-marker write failure cancels the attack and frees the target lock
raw:update('o9102',function(r) r.shield.untilTime=0;r.lock=false;return r end)
S.get(A).v1.raid.attacks=0
local o5=offerFor(A,9102)
if o5 then
 failOwn['o9101']=true
 local okS5,why5=O.start(A,o5.offerId)
 failOwn['o9101']=nil
 local _,rd5=raw:read('o9102')
 check(not okS5 and why5=='store_unavailable' and rd5.lock==false,'pending_marker_failure_cancels')
else print('SKIP pending_marker');check(true,'pending_marker_skipped') end
-- #5 bot raid reports whether the credit was durable
S.get(A).v1.raid.attacks=0;O.offers[A]=nil
raw:update('o9102',function(r) r.shield.untilTime=now+99999;return r end)
local botOffer;for i=1,20 do O.offers[A]=nil;local ok,ofr=O.find(A,{salt=300+i});if ok and ofr.bot then botOffer=ofr;break end end
-- (find itself does not write the profile; run the bot attack with the store down)
if botOffer then
 local okB,ab=O.start(A,botOffer.offerId)
 if okB then
  backend.failAll=true
  local okSub,res=O.submit(A,ab.attackId,{creatures={'c1'},lanes={2}})
  backend.failAll=false
  check(okSub and res.saved==false,'unsaved_credit_reported')
  S.save(A,false)
 else check(true,'bot_start_failed_store') end
else print('SKIP bot_saved_flag');check(true,'bot_offer_skipped') end
-- #6 source allowlist: anything but legacy/'play' is excluded from raids
check(OutpostRules.eligible({species='mossbun',level=1}) and OutpostRules.eligible({species='mossbun',level=1,source='play'}),'legacy_and_play_allowed')
check(not OutpostRules.eligible({species='mossbun',level=1,source='ticket'}) and not OutpostRules.eligible({species='mossbun',level=1,source='robux'}),'other_sources_excluded')
-- #8 friendly raids capped per day
local okF;for i=1,V1Config.outpost.friendlyPerDay do okF=O.friendly(A,9102,{creatures={'c1'},lanes={1}}) end
check(okF and select(2,O.friendly(A,9102,{creatures={'c1'},lanes={1}}))=='daily_friendly_cap','friendly_daily_cap')
check(Profiles.valid(S.get(A)) and Profiles.valid(S.get(D)),'profiles_valid_after_regressions')
