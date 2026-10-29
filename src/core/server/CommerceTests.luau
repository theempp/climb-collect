-- Disposable Studio fixtures only. No Marketplace purchases or real account saves.
local T = {}
function T.run()
	local pass, fail, lines = 0, 0, {}
	local function test(name, fn)
		local ok, err = pcall(fn)
		if ok then pass += 1 else fail += 1 end
		table.insert(lines, (ok and "PASS " or "FAIL ") .. name .. (ok and "" or ": " .. tostring(err)))
	end
	local root = game.ReplicatedStorage.CC_Core
	test("catalogue and canonical rules exist", function()
		assert(root:FindFirstChild("CommerceConfig") and script.Parent:FindFirstChild("CommerceRules"), "Commerce catalogue/rules not implemented")
	end)
	if fail > 0 then return {pass=pass,fail=fail,lines=lines} end
	local C, R, P = require(root.CommerceConfig), require(script.Parent.CommerceRules), require(script.Parent.Profile)
	test("six next-only total tiers; 298 draft Robux; 12x cap", function()
		local d, total = P.default(), 0
		assert(R.multiplier(d)==1)
		for i, tier in ipairs({2,4,6,8,10,12}) do
			for j=1,6 do assert(R.offerState(d,"upgrade"..(j-1)).status == (j<i and "owned" or j==i and "next" or "locked")) end
			d.commerce.passOwned["upgrade"..(i-1)]=true
			R.applyOwnership(d)
			assert(R.multiplier(d)==tier)
			total += C.offers["upgrade"..(i-1)].draftPrice
		end
		assert(total==298 and R.offerState(d,"upgrade5").status=="owned")
	end)
	test("external upper pass remains pending until contiguous prerequisites", function()
		local d=P.default(); d.commerce.passOwned.upgrade5=true; R.applyOwnership(d)
		assert(R.multiplier(d)==1 and R.offerState(d,"upgrade5").status=="pending")
		for i=0,4 do d.commerce.passOwned["upgrade"..i]=true end
		R.applyOwnership(d); assert(R.multiplier(d)==12)
	end)
	test("bundle union, partial direction and full ownership", function()
		local d=P.default(); d.commerce.passOwned.lantern=true; R.applyOwnership(d)
		assert(R.offerState(d,"bundle").status=="partial" and R.offerState(d,"bundle").missingItem=="banner")
		d.commerce.passOwned.banner=true; R.applyOwnership(d); assert(R.offerState(d,"bundle").status=="owned")
		d=P.default(); d.commerce.passOwned.bundle=true; R.applyOwnership(d)
		assert(R.offerState(d,"lantern").status=="owned" and R.offerState(d,"banner").status=="owned")
	end)
	test("exact packs and smallest sufficient shortfall", function()
		for i,n in ipairs({100,350,900,2000}) do local o=C.offers["coins"..n]; assert(o.coins==n and o.draftPrice==({9,25,59,119})[i]) end
		for _,row in ipairs({{1,"coins100"},{100,"coins100"},{101,"coins350"},{250,"coins350"},{351,"coins900"},{901,"coins2000"},{2200,"coins2000"}}) do assert(R.coinPackForShortfall(row[1])==row[2]) end
		assert(R.coinPackForShortfall(0)==nil)
	end)
	test("v2 migration twice preserves legacy state and commerce ledger", function()
		local d=P.default(); d.version=2; d.commerce=nil; d.coins=417; d.gear.points=28; d.home.upgrade=2; d.home.uncollected=2.75
		local a=P.sanitize(P.migrate(d)); local b=P.sanitize(P.migrate(P.deepCopy(a)))
		assert(a.version==3 and b.version==3 and b.coins==417 and b.gear.points==28 and b.home.upgrade==2 and b.home.uncollected==2.75)
		assert(R.multiplier(b)==1 and next(b.commerce.owned)==nil)
		b.commerce.processedPurchases["paid-record"]=true; b.commerce.passOwned.bundle=true; R.applyOwnership(b)
		b.commerce.equipped.banner=true; b.home.decorations.lamp=true
		local c=P.sanitize(b); assert(c.commerce.processedPurchases["paid-record"] and c.commerce.owned.banner and c.commerce.equipped.banner and c.home.decorations.lamp)
	end)

 test("durable commerce service exists",function() assert(script.Parent:FindFirstChild("Commerce"),"Commerce grant boundary not implemented") end)
 if script.Parent:FindFirstChild("Commerce") then
  local Commerce, Store=require(script.Parent.Commerce),require(script.Parent.Store)
  local function fixture()
   local store=Store.memory();local p=P.new(store,{jobId="commerce-test",loadTries=1,saveTries=1,backoff=0.001})
   local s=assert(p:load(992299));return p,s,store,Commerce.new()
  end
  test("exact paid coins at 12x; durable replay beyond 96 general receipts",function()
   local p,s,_,e=fixture();for i=0,5 do s.data.commerce.passOwned["upgrade"..i]=true end;R.applyOwnership(s.data)
   assert(e:grantReceipt(s,"receipt-1","coins350").ok and s.data.coins==350)
   for i=1,110 do assert(p:transact(s,"ordinary:"..i,function(d) d.xp+=1;return {} end).ok) end
   assert(e:grantReceipt(s,"receipt-1","coins350").ok and s.data.coins==350)
   assert(s.data.commerce.pendingReveals["receipt:receipt-1"])
  end)
  test("receipt failure and timeout-after-commit never acknowledge early",function()
   local p,s,store,e=fixture();store.failAll=true
   assert(not e:grantReceipt(s,"receipt-2","coins900").ok and s.data.coins==0)
   store.failAll=false;store.failAfterCommit=1
   assert(not e:grantReceipt(s,"receipt-2","coins900").ok and s.data.coins==0)
   assert(e:grantReceipt(s,"receipt-2","coins900").ok and s.data.coins==900)
   assert(p:save(s,true));local re=assert(p:load(s.userId));assert(e:grantReceipt(re,"receipt-2","coins900").ok and re.data.coins==900)
  end)
  test("unknown, malformed, lost, closing and absent sessions fail closed",function()
   local _,s,_,e=fixture()
   assert(not e:grantReceipt(nil,"receipt-x","coins100").ok)
   assert(not e:grantReceipt(s,"receipt-x","bundle").ok)
   assert(not e:grantReceipt(s,"receipt-x","forged").ok)
   assert(not e:grantReceipt(s,{},"coins100").ok)
   s.closing=true;assert(not e:grantReceipt(s,"receipt-x","coins100").ok)
   s.closing=false;s.lost=true;assert(not e:grantReceipt(s,"receipt-x","coins100").ok and s.data.coins==0)
  end)
  test("permanent grant union and reveal ack preserve ownership",function()
   local _,s,_,e=fixture();assert(e:grantPasses(s,{bundle=true}).ok)
   assert(s.data.commerce.owned.lantern and s.data.commerce.owned.banner)
   assert(e:ack(s,"pass:bundle").ok and not s.data.commerce.pendingReveals["pass:bundle"])
   assert(e:grantPasses(s,{bundle=true}).ok and not s.data.commerce.pendingReveals["pass:bundle"])
  end)
  test("size cap rejects grant without ledger eviction",function()
   local _,s,_,e=fixture();s.data.commerce.processedPurchases[string.rep("x",4000000)]=true
   assert(not e:grantReceipt(s,"receipt-size","coins100").ok and s.data.coins==0)
  end)
 end

 test("earned bank rewards multiply once without XP or point changes",function()
  local Store,Inv,Bank=require(script.Parent.Store),require(script.Parent.Inventory),require(script.Parent.Bank)
  local p=P.new(Store.memory(),{jobId="commerce-bank",loadTries=1});local s=assert(p:load(992399));Inv.bind(s.userId,s)
  for i=0,5 do s.data.commerce.passOwned["upgrade"..i]=true end;R.applyOwnership(s.data)
  local it=Inv.newItem("creature",{species="stub_common_1",rarity="Common",source="test"});s.data.cargo={it}
  local base=require(root.CoreConfig).COINS_ON_BANK.Common
  local r=Bank.deposit(s,s.userId,"commerce-bank-1");assert(r.ok and r.coins==base*12 and s.data.gear.points==0)
  local xp=s.data.xp;local again=Bank.deposit(s,s.userId,"commerce-bank-2");assert(again.coins==0 and s.data.xp==xp)
 end)
 test("old-rate settlement, fractional income and offline cap",function()
  local Home,Store,Commerce,Clock=require(script.Parent.Home),require(script.Parent.Store),require(script.Parent.Commerce),require(script.Parent.Clock)
  local p=P.new(Store.memory(),{jobId="commerce-income",loadTries=1});local s=assert(p:load(992499));local d=s.data
  d.bank={{creatureId="earner",species="test",rarity="Common"}};d.home.assigned={"earner"};d.home.settledAt=Clock.now()-3600;d.home.uncollected=0.25
  assert(Commerce.new():grantPasses(s,{upgrade0=true}).ok)
  assert(math.abs(s.data.home.uncollected-1.25)<0.01 and Home.rate(s.data)==2)
  Home.settle(s.data,s.data.home.settledAt+3600*10);assert(math.abs(s.data.home.uncollected-17.25)<0.01)
 end)
 test("lamp is separate exact 1500-coin one-time sink",function()
  local Home=require(script.Parent.Home);assert(Home.buyDecoration,"decoration not implemented")
  local d=P.default();d.coins=1499;assert(not Home.buyDecoration(d,"lamp").ok and d.coins==1499)
  d.coins=1500;assert(Home.buyDecoration(d,"lamp").ok and d.coins==0 and d.home.decorations.lamp)
  d.coins=2000;assert(not Home.buyDecoration(d,"lamp").ok and d.coins==2000 and d.home.upgrade==0)
  assert(not Home.buyDecoration(d,"forged").ok)
 end)

 test("presentation modules exist without replacing legacy gear",function()
  assert(root:FindFirstChild("CommerceArt") and root:FindFirstChild("Client") and root.Client:FindFirstChild("CommerceUI"),"responsive shop missing")
  assert(script.Parent:FindFirstChild("CommerceDisplays") and script.Parent:FindFirstChild("CommerceCosmetics"),"visible commerce missing")
 end)

 test("concurrent receipts share atomic grant and isolated balances",function()
  local Store,E=require(script.Parent.Store),require(script.Parent.Commerce).new()
  local store=Store.memory();local p=P.new(store,{jobId="concurrent",loadTries=1,saveTries=1});local a=assert(p:load(992599));local b=assert(p:load(992600));store.latency=0.02
  local results={};for i=1,3 do task.spawn(function() results[i]=E:grantReceipt(a,"same-receipt","coins100") end) end
  local untilAt=os.clock()+3;repeat task.wait(0.02) until #results==3 or os.clock()>untilAt
  assert(#results==3 and a.data.coins==100 and b.data.coins==0)
  for _,r in ipairs(results) do assert(r.ok) end
 end)
 test("native flow adapter supports isolated Studio fakes",function()
  assert(require(script.Parent.Commerce).testAdapterSupported,"isolated native checkout adapter missing")
 end)

 if require(script.Parent.Commerce).testAdapterSupported then
  local function nativeFixture()
   local store=require(script.Parent.Store).memory();local profiles=P.new(store,{jobId="native-fake",loadTries=1,saveTries=1})
   local plr={UserId=993100,Parent=true};local s=assert(profiles:load(plr.UserId))
   local function signal() local f;return {Connect=function(_,fn) f=fn end,Fire=function(_,...) return f(...) end} end
   local owns={};local market={count=0,PromptGamePassPurchaseFinished=signal(),PromptProductPurchaseFinished=signal()}
   function market:GetProductInfoAsync() if self.beforeInfo then self.beforeInfo() end;if self.priceFail then error("metadata unavailable") end;return {PriceInRobux=19,IsForSale=true} end
   function market:UserOwnsGamePassAsync(_,id) if self.ownershipFail then error("lookup unavailable") end;return owns[id]==true end
   function market:PromptGamePassPurchase(_,id) self.count+=1;self.last=id end
   market.PromptProductPurchase=market.PromptGamePassPurchase
   local cat=P.deepCopy(C);cat.offers.bundle.platformId=7001;cat.offers.coins100.platformId=7002;cat.offers.upgrade0.platformId=7003
   local ctx={sessions={[plr]=s},handlers={},transaction=function(_,id,fn,cb) local r=profiles:transact(s,id,fn);if r.ok and cb then cb(r) end;return r end,push=function() end,toast=function() end}
   local clone=script.Parent.Commerce:Clone();clone.Name="CommerceTestInstance";clone.Parent=script.Parent
   local mod=require(clone);mod.init(ctx,{market=market,catalogue=cat,players={GetPlayerByUserId=function(_,id) if id==plr.UserId then return plr end end},safe=function() return true end})
   return mod,plr,s,market,owns,ctx,store
  end
  test("native cancel and duplicate clicks never grant or double prompt",function()
   local e,p,s,m=nativeFixture()
   assert(e.purchase(p,{offerId="bundle",price=0,coins=999999}).ok and m.count==1)
   assert(not e.purchase(p,{offerId="coins100"}).ok and m.count==1)
   m.PromptGamePassPurchaseFinished:Fire(p,7001,false)
   local st={};e.state(p,st);assert(st.commerce.checkout==nil and next(s.data.commerce.owned)==nil)
  end)
  test("native product prompt completion grants nothing; only valid receipt grants",function()
   local e,p,s,m=nativeFixture();assert(e.purchase(p,{offerId="coins100"}).ok)
   m.PromptProductPurchaseFinished:Fire(p.UserId,7002,true);assert(s.data.coins==0)
   assert(e.processReceipt({PlayerId=p.UserId,ProductId=7002,PurchaseId="native-product"})==Enum.ProductPurchaseDecision.PurchaseGranted and s.data.coins==100)
   assert(e.processReceipt({PlayerId=p.UserId,ProductId=999,PurchaseId="unknown"})==Enum.ProductPurchaseDecision.NotProcessedYet)
  end)
  test("metadata and ownership failures disable checkout without revocation",function()
   local e,p,s,m=nativeFixture();m.priceFail=true;assert(not e.purchase(p,{offerId="bundle"}).ok and m.count==0)
   e,p,s,m=nativeFixture();m.ownershipFail=true;s.data.commerce.passOwned.flag=true;R.applyOwnership(s.data)
   assert(not e.purchase(p,{offerId="bundle"}).ok and m.count==0 and s.data.commerce.owned.flag)
  end)
  test("yielded checkout revalidates lost profile and ownership",function()
   local e,p,s,m=nativeFixture();m.beforeInfo=function() s.lost=true end
   assert(not e.purchase(p,{offerId="bundle"}).ok and m.count==0)
   e,p,s,m=nativeFixture();m.beforeInfo=function() s.data.commerce.passOwned.lantern=true;R.applyOwnership(s.data) end
   assert(not e.purchase(p,{offerId="bundle"}).ok and m.count==0)
  end)
  test("server verified permanent pass commits before reveal",function()
   local e,p,s,m,owns=nativeFixture();owns[7001]=true
   assert(e.reconcile(p) and s.data.commerce.owned.lantern and s.data.commerce.pendingReveals["pass:bundle"])
   assert(not e.purchase(p,{offerId="bundle"}).ok and m.count==0)
  end)
 end

 test("client price lookup recovers from transient failure and expires stale prices",function()
  local module=root.Client:FindFirstChild("CommercePrices");assert(module,"price recovery not implemented")
  local cache=require(module);local now,calls,fail=0,0,true
  local cat={offers={sample={platformId=42,kind="pass"},unset={platformId=0,kind="product"}},order={"sample","unset"}}
  local p=cache.new(cat,function() calls+=1;if fail then error("offline") end;return 19 end,function() return now end)
  p:refresh("sample");assert(p:get("sample")==nil)
  p:refresh("sample");assert(calls==1,"failure retry hammered metadata")
  now=6;fail=false;p:refresh("sample");assert(p:get("sample")==19)
  now=70;assert(p:get("sample")==nil,"stale price still enabled checkout")
  p:refresh("sample");assert(p:get("sample")==19)
  p:refresh("unset");assert(p:get("unset")==nil and calls==3)
 end)
 return {pass=pass,fail=fail,lines=lines}
end
return T
