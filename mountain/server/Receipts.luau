-- E02 exactly-once receipts and entitlements. The grant and its receipt id commit in ONE durable profile
-- transaction (Profiles.transact), so retries, rejoins and server changes can never grant twice, and
-- PurchaseGranted is only returned after that commit. Client purchase callbacks never grant anything.
-- deps: profiles {get,transact}, products (V1Products shape), playerByUserId(id), clock(), checkoutEnabled(),
--       prompt(player,item) (real MarketplaceService prompt; never called while checkout is disabled),
--       ownsPass(userId,passId) -> ok,owned, notify(player,kind,data)
local Shared=if script then game.ReplicatedStorage.MountainShared else nil
local Schema=if Shared then require(Shared.V1Schema) else require('../shared/V1Schema')
local Wallet=if Shared then require(Shared.V1Wallet) else require('../shared/V1Wallet')
local Config=if Shared then require(Shared.V1Config) else require('../shared/V1Config')
local R={GRANTED='PurchaseGranted',RETRY='NotProcessedYet'}
function R.new(deps)
 local products=deps.products
 local pending={} -- [player]={[key]=expiresAt}: prompt shown, outcome unknown. Never implies ownership.
 local service={log={}}
 local function note(kind,data) table.insert(service.log,{kind=kind,data=data});if #service.log>200 then table.remove(service.log,1) end end
 function service.state(player,key)
  local item=products.byKey[key];local p=deps.profiles.get(player)
  if not item or not p then return 'unavailable' end
  if (item.kind=='once' or item.kind=='pass') and p.v1.passes[key] then return 'owned' end
  local waiting=pending[player] and pending[player][key]
  if waiting and waiting>deps.clock() then return 'pending' end
  if item.id==0 or not deps.checkoutEnabled() then return 'unavailable' end
  return 'available'
 end
 function service.prompt(player,key)
  local state=service.state(player,key)
  if state~='available' then return false,state end
  pending[player]=pending[player] or {};pending[player][key]=deps.clock()+120
  deps.prompt(player,products.byKey[key])
  return true,'pending'
 end
 -- PromptProductPurchaseFinished / PromptGamePassPurchaseFinished: only clears the pending flag.
 function service.promptFinished(player,key)
  if pending[player] then pending[player][key]=nil end
 end
 function service.process(receipt)
  if type(receipt)~='table' then return R.RETRY end
  local item=products.byProductId[receipt.ProductId]
  local player=deps.playerByUserId(receipt.PlayerId)
  local purchase=receipt.PurchaseId
  if type(purchase)~='string' and type(purchase)~='number' then return R.RETRY end
  local id='rcpt:'..tostring(purchase)
  -- Unknown or unconfigured product, or the buyer is not on this server: leave it for a later retry.
  if not item or item.kind=='pass' or not player then note('deferred',{id=id,product=receipt.ProductId});return R.RETRY end
  if #id>128 then return R.RETRY end
  local now=deps.clock()
  local ok,reason=deps.profiles.transact(player,id,function(draft)
   local v=draft.v1
   if Schema.has(v.processed,id) then return true,'already_granted' end
   if item.kind=='once' and v.passes[item.key] then
    -- Charged twice for a one-per-account item: record it so it is acknowledged once, grant nothing more.
    Schema.push(v.processed,id,Config.receipts.ring);return true,'duplicate_once'
   end
   local got=Wallet.grant(draft,item.grant,now)
   if not got then return false,'invalid_grant' end
   if item.kind=='once' then v.passes[item.key]=true end
   Schema.push(v.processed,id,Config.receipts.ring)
   return true,'granted'
  end)
  if not ok then note('retry',{id=id,reason=reason});return R.RETRY end
  service.promptFinished(player,item.key)
  note(reason,{id=id,key=item.key,userId=receipt.PlayerId})
  if deps.notify and reason=='granted' then deps.notify(player,'purchase',{key=item.key,state='owned_or_granted'}) end
  return R.GRANTED
 end
 -- Game passes: ownership is always re-checked on the server (join, and after a purchase prompt closes).
 function service.syncPasses(player)
  local granted={}
  for _,item in ipairs(products.list) do
   if item.kind=='pass' and item.id~=0 then
    local p=deps.profiles.get(player)
    if p and not p.v1.passes[item.key] then
     local okCall,owned=deps.ownsPass(player.UserId,item.id)
     if okCall and owned then
      local ok=deps.profiles.transact(player,'pass:'..item.key,function(draft)
       if draft.v1.passes[item.key] then return true,'owned' end
       if not Wallet.grant(draft,item.grant,deps.clock()) then return false,'invalid_grant' end
       draft.v1.passes[item.key]=true;return true,'granted'
      end)
      if ok then table.insert(granted,item.key) end
     end
    end
   end
  end
  return granted
 end
 function service.remove(player) pending[player]=nil end
 return service
end
return R
