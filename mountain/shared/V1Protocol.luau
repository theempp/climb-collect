-- Wire validation for the v1 services remotes (V1_Request -> V1_Result). Shape checks only: every
-- ownership, cap, lock and cost rule is enforced again on the server. Unknown fields are rejected.
local UIProtocol=if script then require(script.Parent.UIProtocol) else require('./UIProtocol')
local P={}
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function int(v,lo,hi) return finite(v) and v%1==0 and v>=lo and v<=hi end
local function text(v,max) return type(v)=='string' and #v>0 and #v<=(max or 64) end
local function fields(value,allowed)
 if type(value)~='table' then return false end
 for key in pairs(value) do if not allowed[key] then return false end end
 return true
end
local function list(v,max,each)
 if type(v)~='table' or #v>max then return false end
 for k,x in pairs(v) do if not int(k,1,#v) or not each(x) then return false end end
 return true
end
local function userId(v) return int(v,1,9007199254740991) end
local function plan(v,extra)
 local allowed={creatures=true,lanes=true,ability=true}
 for k in pairs(extra or {}) do allowed[k]=true end
 if not fields(v,allowed) then return false end
 if not list(v.creatures,3,function(x) return text(x) end) or #v.creatures<1 then return false end
 if not list(v.lanes,3,function(x) return int(x,1,3) end) or #v.lanes~=#v.creatures then return false end
 if v.ability~=nil and not list(v.ability,3,function(x) return x==false or int(x,0,20) end) then return false end
 return true
end
local partyOps={create={},leave={},ready_start={},follow={},invite={userId=userId},kick={userId=userId},friend={userId=userId},
 accept={partyId=function(v) return int(v,1,1e9) end},decline={partyId=function(v) return int(v,1,1e9) end},
 code={code=function(v) return type(v)=='string' and #v>=4 and #v<=12 and v:match('^[%w]+$')~=nil end},ready={ready=function(v) return type(v)=='boolean' end}}
P.actions={
 V1_State=function(v) return v==nil end,
 Daily_ClaimLogin=function(v) return v==nil end,
 Daily_Claim=function(v) return fields(v,{slot=true}) and (v.slot=='weekly' or int(v.slot,1,3)) end,
 Daily_Reroll=function(v) return fields(v,{slot=true}) and (v.slot=='weekly' or int(v.slot,1,3)) end,
 Shop_State=function(v) return v==nil end,
 Shop_Prompt=function(v) return fields(v,{key=true}) and text(v.key,32) end,
 Party=function(v)
  if type(v)~='table' or type(v.op)~='string' then return false end
  local spec=partyOps[v.op];if not spec then return false end
  for k,val in pairs(v) do if k~='op' and (not spec[k] or not spec[k](val)) then return false end end
  for k in pairs(spec) do if v[k]==nil then return false end end
  return true
 end,
 Outpost_State=function(v) return v==nil end,
 Outpost_SetSlot=function(v) return fields(v,{slot=true,piece=true}) and int(v.slot,1,10) and (v.piece==false or text(v.piece,32)) end,
 Outpost_SetDefenders=function(v) return fields(v,{ids=true}) and list(v.ids,3,function(x) return text(x) end) end,
 Outpost_Collect=function(v) return v==nil end,
 Outpost_Shield=function(v) return v==nil end,
 Raid_Find=function(v) return v==nil or (fields(v,{revenge=true}) and userId(v.revenge)) end,
 Raid_Reroll=function(v) return v==nil end,
 Raid_Start=function(v) return fields(v,{offerId=true}) and text(v.offerId,64) end,
 Raid_Submit=function(v) return plan(v,{attackId=true}) and text(v.attackId,64) end,
 Raid_Abandon=function(v) return v==nil end,
 Raid_Log=function(v) return v==nil end,
 Raid_Practice=function(v) return plan(v) end,
 Raid_Friendly=function(v) return plan(v,{userId=true}) and userId(v.userId) end,
 Season_State=function(v) return v==nil end,
 Title_Equip=function(v) return fields(v,{id=true}) and (v.id==false or text(v.id,32)) end,
}
-- Same request-id contract as UIProtocol ('token:sequence'); UIRequests.new enforces ordering and caching.
function P.validate(id,action,payload)
 if not UIProtocol.parseId(id) then return false,'Invalid request id.' end
 local check=type(action)=='string' and P.actions[action]
 if not check then return false,'Unknown action.' end
 local ok,valid=pcall(check,payload)
 if not ok or not valid then return false,'Invalid action payload.' end
 return true
end
return P
