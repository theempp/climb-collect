-- One native dispatcher. Prompt completion is never evidence of a developer-product grant.
local RS, Run, Players, Http = game:GetService("ReplicatedStorage"),game:GetService("RunService"),game:GetService("Players"),game:GetService("HttpService")
local Market=game:GetService("MarketplaceService")
local C,R,Clock= require(RS.CC_Core.CommerceConfig),require(script.Parent.CommerceRules),require(script.Parent.Clock)
local Commerce={testAdapterSupported=Run:IsStudio()}; local Engine={};Engine.__index=Engine
function Commerce.new() return setmetatable({},Engine) end
local function ready(s) return s and not s.lost and not s.released and not s.closing and not s.outcomePending end
function Engine:grantReceipt(s,purchaseId,offerId)
 local o=C.offers[offerId]
 if not ready(s) or not o or o.kind~="product" or type(purchaseId)~="string" or #purchaseId<1 or #purchaseId>100 then return {ok=false,reason="unavailable"} end
 local tx="receipt:"..purchaseId
 -- transact checks ownership and serialization, and recovers exactly this uncertain write.
 return s.owner:transact(s,tx,function(d)
  if d.commerce.processedPurchases[purchaseId] then return {duplicate=true} end
  d.coins+=o.coins
  d.commerce.processedPurchases[purchaseId]=true
  d.commerce.pendingReveals[tx]={offerId=offerId,grantId=tx}
  return {coins=o.coins,grantId=tx}
 end)
end
function Engine:grantPasses(s,verified)
 if not ready(s) then return {ok=false,reason="unavailable"} end
 local changed=false
 for id,v in pairs(verified) do if v==true and C.offers[id] and C.offers[id].kind=="pass" and not s.data.commerce.passOwned[id] then changed=true end end
 if not changed then return {ok=true} end
 return s.owner:transact(s,"passes:"..Http:GenerateGUID(false),function(d)
  -- Settle old-rate income BEFORE applying any effective tier change (same atomic write).
  require(script.Parent.Home).settle(d,Clock.now())
  for id,v in pairs(verified) do
   local o=C.offers[id]
   if v==true and o and o.kind=="pass" and not d.commerce.passOwned[id] then
    local previous=R.offerState(d,id).status
    d.commerce.passOwned[id]=true
    if previous~="owned" then local grant="pass:"..id; d.commerce.pendingReveals[grant]={offerId=id,grantId=grant} end
   end
  end
  R.applyOwnership(d)
  return {tier=d.commerce.tier}
 end)
end
function Engine:ack(s,id)
 if not ready(s) or type(id)~="string" or #id>120 then return {ok=false} end
 if not s.data.commerce.pendingReveals[id] then return {ok=true} end
 return s.owner:transact(s,"reveal:"..Http:GenerateGUID(false),function(d) d.commerce.pendingReveals[id]=nil;return {} end)
end
local ctx, engine= nil, Commerce.new()
local pending, cooldown, metadata, reconciles = {},{},{},{}
local function refreshed(plr)
 if ctx.CommerceCosmetics then ctx.CommerceCosmetics.refresh(plr) end
 if ctx.Home and ctx.Home.refreshCommerce then ctx.Home.refreshCommerce(plr) end
 ctx.push(plr)
end
local injectedSafe
local function safe(plr)
 if injectedSafe then return injectedSafe(plr) end
 local ch=plr.Character;local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 local traversal=ch and ch:GetAttribute("CC_TraversalState")
 return hum and hum.Health>0 and hum.FloorMaterial~=Enum.Material.Air and (traversal==nil or traversal=="ground")
end
local function info(id,o)
 if o.platformId<=0 then return nil end
 local now=os.clock();local old=metadata[id]
 if old and now-old.at<60 then return old.value end
 local ok,v=pcall(Market.GetProductInfoAsync,Market,o.platformId,o.kind=="pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
 v=ok and type(v)=="table" and v.IsForSale~=false and type(v.PriceInRobux)=="number" and v or nil
 metadata[id]={at=now,value=v};return v
end
function Commerce.reconcile(plr)
 local s=ctx.sessions[plr];if not ready(s) or reconciles[plr] then return false end
 reconciles[plr]=true
 local verified,failed={},false
 for _,id in ipairs(C.order) do
  local o=C.offers[id]
  if o.kind=="pass" and o.platformId>0 then
   local ok,owns=pcall(Market.UserOwnsGamePassAsync,Market,plr.UserId,o.platformId)
   if ok and owns then verified[id]=true elseif not ok then failed=true end
  end
 end
 if ctx.sessions[plr]~=s or not ready(s) then reconciles[plr]=nil;return false end
 local r=engine:grantPasses(s,verified)
 reconciles[plr]=nil
 if r.ok then refreshed(plr) end
 return r.ok and not failed
end
function Commerce.purchase(plr,payload)
 local id=payload.offerId;local o=type(id)=="string" and C.offers[id]
 local s=ctx.sessions[plr]
 if not o or not ready(s) or s.pending or s.saving or s.busy or pending[plr] or not safe(plr) then return {ok=false,reason="unavailable"} end
 if os.clock()-(cooldown[plr] or -100)<2 then return {ok=false,reason="rate"} end
 cooldown[plr]=os.clock()
 -- Reserve before metadata / ownership calls yield: duplicate clicks cannot open two prompts.
 local token={id=id,session=s}; pending[plr]=token
 local function release(reason) if pending[plr]==token then pending[plr]=nil end;ctx.push(plr);return {ok=false,reason=reason} end
 if o.platformId<=0 then ctx.toast(plr,"Checkout unavailable: product setup is pending.","info");return release("unconfigured") end
 if not Commerce.reconcile(plr) then return release("ownership") end
 local product=info(id,o)
 if ctx.sessions[plr]~=s or not ready(s) or s.pending or s.saving or pending[plr]~=token or not safe(plr) then return release("changed") end
 local state=R.offerState(s.data,id)
 if state.status~="available" and state.status~="next" then return release(state.status) end
 if not product then return release("price") end
 local ok=pcall(function()
  if o.kind=="pass" then Market:PromptGamePassPurchase(plr,o.platformId) else Market:PromptProductPurchase(plr,o.platformId) end
 end)
 if not ok then return release("prompt") end
 ctx.push(plr)
 task.delay(90,function() if pending[plr]==token then pending[plr]=nil;ctx.push(plr) end end)
 return {ok=true}
end
function Commerce.processReceipt(receipt)
 local unresolved=Enum.ProductPurchaseDecision.NotProcessedYet
 if type(receipt)~="table" then return unresolved end
 local plr=Players:GetPlayerByUserId(receipt.PlayerId)
 local s=plr and ctx.sessions[plr]
 local offer
 for _,id in ipairs(C.order) do local o=C.offers[id];if o.kind=="product" and o.platformId>0 and o.platformId==receipt.ProductId then offer=id;break end end
 if not offer or not ready(s) then return unresolved end
 local r=engine:grantReceipt(s,receipt.PurchaseId,offer)
 if not r.ok then ctx.push(plr);return unresolved end
 refreshed(plr)
 return Enum.ProductPurchaseDecision.PurchaseGranted
end
function Commerce.init(c,deps)
 if deps then
  assert(Run:IsStudio() and game.PlaceId==0,"test services forbidden outside unpublished Studio")
  Market=assert(deps.market);C=assert(deps.catalogue);Players=assert(deps.players);injectedSafe=assert(deps.safe)
 end
 ctx=c
 Market.ProcessReceipt=Commerce.processReceipt
 ctx.handlers.commercePurchase=Commerce.purchase
 ctx.handlers.commerceRevealAck=function(plr,p) local r=engine:ack(ctx.sessions[plr],p.grantId);ctx.push(plr);return r end
 ctx.handlers.commerceEquip=function(plr,p)
  if type(p.id)~="string" or not C.cosmetics[p.id] or type(p.enabled)~="boolean" then return end
  return ctx.transaction(plr,"equip:"..Http:GenerateGUID(false),function(d)
   if not d.commerce.owned[p.id] then return {ok=false,reason="unowned"} end
   d.commerce.equipped[p.id]=p.enabled or nil;return {}
  end,function() refreshed(plr) end)
 end
 Market.PromptGamePassPurchaseFinished:Connect(function(plr,passId,bought)
  local token=pending[plr];local o=token and C.offers[token.id]
  if not o or o.kind~="pass" or o.platformId~=passId then return end
  if not bought then pending[plr]=nil;ctx.push(plr);return end
  task.spawn(function()
   for _,delay in ipairs({0,1,2,4,8,16}) do
    if delay>0 then task.wait(delay) end
    if ctx.sessions[plr]~=token.session then break end
    Commerce.reconcile(plr)
    if token.session.data.commerce.passOwned[token.id] then break end
   end
   if pending[plr]==token then pending[plr]=nil end
   ctx.push(plr)
  end)
 end)
 Market.PromptProductPurchaseFinished:Connect(function(userId,productId,_bought)
  local plr=Players:GetPlayerByUserId(userId);local token=plr and pending[plr];local o=token and C.offers[token.id]
  if o and o.kind=="product" and o.platformId==productId then pending[plr]=nil;ctx.push(plr) end
 end)
 -- These injected grants exist ONLY in a disposable unpublished Studio server, never UI or production.
 if Run:IsStudio() and game.PlaceId==0 and ctx.devHandlers then
  ctx.devHandlers.commerceTestGrant=function(plr,p)
   local s=ctx.sessions[plr];local o=C.offers[p.offerId];if not o then return {ok=false} end
   local result=o.kind=="product" and engine:grantReceipt(s,p.purchaseId or ("studio-"..Http:GenerateGUID(false)),p.offerId) or engine:grantPasses(s,{[p.offerId]=true})
   if result.ok then refreshed(plr) end;return result
  end
 end
end
function Commerce.onLoaded(plr,s)
 task.spawn(function()
  for _,waitTime in ipairs({0,2,8,30}) do
   if waitTime>0 then task.wait(waitTime) end
   if ctx.sessions[plr]~=s then return end
   if Commerce.reconcile(plr) then return end
  end
 end)
end
function Commerce.onLeave(plr) pending[plr],cooldown[plr],reconciles[plr]=nil,nil,nil end
function Commerce.state(plr,st)
 local s=ctx.sessions[plr];if not s then return end
 local d=s.data;local view={tier=d.commerce.tier,multiplier=R.multiplier(d),owned=d.commerce.owned,equipped=d.commerce.equipped,offers={},pendingReveals=d.commerce.pendingReveals,checkout=pending[plr] and pending[plr].id}
 for _,id in ipairs(C.order) do local v=R.offerState(d,id);v.configured=C.offers[id].platformId>0;view.offers[id]=v end
 st.commerce=view
end
return Commerce
