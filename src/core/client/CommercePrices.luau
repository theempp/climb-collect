-- Metadata is advisory; only the server may initiate Roblox checkout.
local P={}
function P.new(catalogue,fetch,clock)
 local self={entries={}};clock=clock or os.clock
 function self:get(id)
  local e=self.entries[id]
  return e and e.value and clock()<e.expires and e.value or nil
 end
 function self:refresh(id)
  local o=catalogue.offers[id];if not o or o.platformId<=0 then return nil end
  local e=self.entries[id]
  if e and (e.busy or clock()<e.retry) then return self:get(id) end
  e=e or {};self.entries[id]=e;e.busy=true
  local ok,value=pcall(fetch,o)
  e.busy=false;e.value=ok and type(value)=="number" and value>=0 and value or nil
  e.expires=clock()+60;e.retry=clock()+(e.value and 60 or 5)
  return self:get(id)
 end
 return self
end
return P
