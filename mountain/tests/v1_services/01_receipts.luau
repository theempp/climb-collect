-- E02: exactly-once grants across retries, lost responses, rejoin and server change, on real Profiles.transact.
local backend=Store.memory()
local serverA=Profiles.newForTests(backend,'serverA')
local serverB=Profiles.newForTests(backend,'serverB')
local buyer={UserId=5001,Name='buyer'}
local clockNow=10000
-- Test catalog with non-zero ids; the shipped catalog keeps every id at 0.
local catalog={list={
 {key='gems',kind='consumable',id=11,grant={coins=100}},
 {key='starter',kind='once',id=12,grant={coins=1000,eggTickets=3}},
 {key='vip',kind='pass',id=13,grant={title='vip'}},
 {key='shield',kind='consumable',id=14,grant={shield=1}},
 {key='bad',kind='consumable',id=15,grant={creature='floravelle'}},
}}
catalog.byKey={};catalog.byProductId={}
for _,item in ipairs(catalog.list) do catalog.byKey[item.key]=item;if item.kind~='pass' then catalog.byProductId[item.id]=item end end
local online={}
local prompts={}
local function deps(profiles,checkout,owns)
 return {profiles=profiles,products=catalog,playerByUserId=function(id) return online[id] end,clock=function() return clockNow end,
  checkoutEnabled=function() return checkout end,prompt=function(player,item) table.insert(prompts,item.key) end,
  ownsPass=owns or function() return true,false end}
end
local rA=Receipts.new(deps(serverA,true))
local rB=Receipts.new(deps(serverB,true))
local mock=MockMarketplace.new({prefix='t'})
-- shipped catalog: every id 0, checkout disabled, nothing purchasable
check(V1Products.byProductId[0]==nil and next(V1Products.byProductId)==nil and next(V1Products.byPassId)==nil,'shipped_products_unconfigured')
check(V1Config.checkoutEnabled==false,'checkout_disabled')
for _,item in ipairs(V1Products.list) do check(item.id==0 and V1Wallet.valid(item.grant),'shipped_product_safe '..item.key) end
-- not on this server -> retry, nothing written
local rcpt=mock.receipt(5001,11)
check(rA.process(rcpt)==Receipts.RETRY,'absent_buyer_retry')
local p=serverA.load(buyer);online[5001]=buyer
check(p and p.v1,'buyer_loaded_v1')
-- unknown product or id 0 never grants
check(rA.process(mock.receipt(5001,0))==Receipts.RETRY and rA.process(mock.receipt(5001,999))==Receipts.RETRY and p.coins==0,'unknown_product_never_grants')
check(rA.process(mock.receipt(5001,15))==Receipts.RETRY and p.coins==0,'invalid_grant_rejected')
check(rA.process(mock.receipt(5001,13))==Receipts.RETRY,'pass_ids_never_processed_as_receipts')
-- normal grant, then redelivery of the same receipt
check(rA.process(rcpt)==Receipts.GRANTED and serverA.get(buyer).coins==100,'granted_once')
check(rA.process(rcpt)==Receipts.GRANTED and serverA.get(buyer).coins==100,'redelivery_no_double')
-- datastore fails -> retry, then succeeds exactly once
local r2=mock.receipt(5001,11)
backend.failAll=true
check(rA.process(r2)==Receipts.RETRY and not serverA.get(buyer) and serverA.pending(buyer)=='rcpt:'..r2.PurchaseId,'store_down_retry_and_frozen')
backend.failAll=false
check(rA.process(r2)==Receipts.GRANTED and serverA.get(buyer).coins==200,'retry_after_outage_grants_once')
-- response lost after durable commit: next delivery must not grant again
local r3=mock.receipt(5001,11)
backend.failAfterCommit=1
check(rA.process(r3)==Receipts.GRANTED and serverA.get(buyer).coins==300,'lost_response_recovered_by_write_id')
check(rA.process(r3)==Receipts.GRANTED and serverA.get(buyer).coins==300,'lost_response_replay_once')
-- a different receipt while another is pending is refused (no interleaving)
local r4=mock.receipt(5001,11);local r5=mock.receipt(5001,11)
backend.failAll=true;check(rA.process(r4)==Receipts.RETRY,'pending_r4');backend.failAll=false
check(rA.process(r5)==Receipts.RETRY,'other_receipt_waits_for_pending')
check(rA.process(r4)==Receipts.GRANTED and rA.process(r5)==Receipts.GRANTED and serverA.get(buyer).coins==500,'both_granted_in_order')
-- once-products: second charge acknowledged without a second grant
local s1,s2=mock.receipt(5001,12),mock.receipt(5001,12)
check(rA.process(s1)==Receipts.GRANTED and serverA.get(buyer).coins==1500 and serverA.get(buyer).v1.eggTickets==3,'starter_granted')
check(rA.state(buyer,'starter')=='owned','starter_owned_state')
check(rA.process(s2)==Receipts.GRANTED and serverA.get(buyer).coins==1500,'starter_duplicate_not_regranted')
-- server change: receipt redelivered to server B after rejoin
local r6=mock.receipt(5001,14)
check(rA.process(r6)==Receipts.GRANTED and serverA.get(buyer).v1.tokens.shield==1,'shield_token_on_A')
check(serverA.save(buyer,true),'leave_A');online[5001]=nil
local pb=serverB.load(buyer);online[5001]=buyer
check(pb and pb.coins==1500 and pb.v1.tokens.shield==1,'rejoin_B_keeps_grants')
local ok,attempts=mock.deliver(r6,{rB},3);check(ok and attempts==1 and serverB.get(buyer).v1.tokens.shield==1,'server_change_redelivery_no_double')
local r7=mock.receipt(5001,11)
check(mock.deliver(r7,{rA,rB},4) and serverB.get(buyer).coins==1600,'delivery_loop_until_owning_server_grants')
-- session lock: A cannot write while B holds the profile
check(serverA.load(buyer)==nil,'session_lock_blocks_second_server')
-- states: pending is never ownership; disabled checkout is unavailable
local off=Receipts.new(deps(serverB,false))
check(off.state(buyer,'gems')=='unavailable' and not off.prompt(buyer,'gems'),'disabled_checkout_unavailable')
check(rB.prompt(buyer,'gems') and rB.state(buyer,'gems')=='pending' and prompts[#prompts]=='gems','prompt_pending')
local before=serverB.get(buyer).coins
rB.promptFinished(buyer,'gems')
check(serverB.get(buyer).coins==before and rB.state(buyer,'gems')=='available','client_finish_never_grants')
check(rB.state(buyer,'nope')=='unavailable','unknown_key_unavailable')
-- game passes: server-side ownership check only
local passes=Receipts.new(deps(serverB,true,function(_,id) return true,id==13 end))
check(#passes.syncPasses(buyer)==1 and serverB.get(buyer).v1.passes.vip and serverB.get(buyer).v1.titles.vip,'pass_granted_by_server_check')
check(#passes.syncPasses(buyer)==0,'pass_sync_idempotent')
local noPass=Receipts.new(deps(serverB,true,function() return false,'http error' end))
check(#noPass.syncPasses(buyer)==0,'pass_check_failure_grants_nothing')
check(Profiles.valid(serverB.get(buyer)),'profile_valid_after_purchases')
