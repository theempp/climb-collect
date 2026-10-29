-- Canonical ownership is the union of verified pass records; tier activation is contiguous.
local C=require(game.ReplicatedStorage.CC_Core.CommerceConfig)
local R={}
function R.default() return {tier=0,owned={},equipped={},passOwned={},processedPurchases={},pendingReveals={}} end
function R.activeTier(c)
 local tier=0
 for i=0,5 do if not c.passOwned["upgrade"..i] then break end; tier=i+1 end
 return tier
end
function R.applyOwnership(d)
 local c=d.commerce
 for id,v in pairs(c.passOwned) do
  local o=C.offers[id]
  if v==true and o and o.items then for _,item in ipairs(o.items) do c.owned[item]=true end end
 end
 c.tier=R.activeTier(c)
end
function R.multiplier(d) return C.tiers[d.commerce and d.commerce.tier or 0] or 1 end
function R.offerState(d,id)
 local o=C.offers[id]; if not o then return {status="unavailable"} end
 local c=d.commerce or R.default()
 if o.tier then
  if o.tier<=c.tier then return {status="owned"} end
  if c.passOwned[id] then return {status="pending",nextTier=c.tier+1} end
  return {status=o.tier==c.tier+1 and "next" or "locked",nextTier=c.tier+1}
 end
 if o.items then
  local count,missing=0,nil
  for _,item in ipairs(o.items) do if c.owned[item] then count+=1 else missing=item end end
  return {status=count==#o.items and "owned" or count>0 and "partial" or "available",missingItem=count>0 and missing or nil}
 end
 return {status="available"}
end
function R.coinPackForShortfall(n)
 if type(n)~="number" or n<=0 then return nil end
 for _,v in ipairs({100,350,900,2000}) do if v>=n then return "coins"..v end end
 return "coins2000"
end
function R.sanitize(raw)
 local c=R.default(); raw=type(raw)=="table" and raw or {}
 for id,v in pairs(type(raw.passOwned)=="table" and raw.passOwned or {}) do if C.offers[id] and C.offers[id].kind=="pass" and v==true then c.passOwned[id]=true end end
 -- Never synthesize verified ownership from a client-supplied or stale tier number.
 local d={commerce=c}; R.applyOwnership(d)
 for id,v in pairs(type(raw.equipped)=="table" and raw.equipped or {}) do if c.owned[id] and v==true then c.equipped[id]=true end end
 -- Paid IDs are NEVER trimmed. The Profile byte budget fails closed before new grants.
 for id,v in pairs(type(raw.processedPurchases)=="table" and raw.processedPurchases or {}) do if type(id)=="string" and v==true then c.processedPurchases[id]=true end end
 for id,v in pairs(type(raw.pendingReveals)=="table" and raw.pendingReveals or {}) do
  if type(id)=="string" and type(v)=="table" and C.offers[v.offerId] then c.pendingReveals[id]={offerId=v.offerId,grantId=id} end
 end
 return c
end
return R
