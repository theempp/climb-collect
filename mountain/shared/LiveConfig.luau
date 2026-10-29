-- LiveConfig: the single source of kill switches and tunables (design/live-ops-tools-plan-2026-10-28.md).
-- The owner's Open Cloud script writes one versioned JSON key; servers poll it (~60 s) and on a
-- MessagingService nudge. Fetching is injected (deps.fetch) so the core runs in plain Luau tests.
-- An invalid or older config is rejected whole; the last good one (or the code defaults) stays.
local C={}

-- type, default, and range for numbers. Flags default ON except where noted; a missing key = default.
C.SCHEMA={
 ['shop.enabled']={t='boolean',d=true},
 ['shop.ladders']={t='boolean',d=true},
 ['shop.eggs']={t='boolean',d=true},
 ['shop.cosmetics']={t='boolean',d=true},
 ['events.enabled']={t='boolean',d=true},
 ['dailies.enabled']={t='boolean',d=true},
 ['homebase.tiers']={t='boolean',d=true},
 ['economy.coinRate']={t='number',d=1,min=0,max=5},
 ['economy.xpRate']={t='number',d=1,min=0,max=5},
 ['economy.coinMultCap']={t='number',d=100,min=1,max=100},
 ['economy.eventMult']={t='number',d=1,min=1,max=3},
 ['hatch.floorSeconds']={t='number',d=60,min=30,max=3600},
 ['banner']={t='string',d='',enum={['']=true,maintenance=true,event_live=true,new_content=true,known_issue=true}},
}
-- Per-kingdom and per-Guardian switches share one rule.
for _,k in {'blossom','azure','sunstone','violet','inferno','astral'} do
 C.SCHEMA['mountain.'..k]={t='boolean',d=true}
 C.SCHEMA['guardian.'..k]={t='boolean',d=true}
end

function C.defaults()
 local v={}
 for k,s in C.SCHEMA do v[k]=s.d end
 return v
end

-- raw = {version=n, values={key=value}}. Returns ok, values|errors.
function C.validate(raw)
 local errs={}
 if type(raw)~='table' or type(raw.version)~='number' or type(raw.values)~='table' then return false,{'shape'} end
 local v=C.defaults()
 for k,x in raw.values do
  local s=C.SCHEMA[k]
  if not s then table.insert(errs,'unknown '..tostring(k))
  elseif type(x)~=s.t then table.insert(errs,'type '..k)
  elseif s.t=='number' and (x~=x or x<s.min or x>s.max) then table.insert(errs,'range '..k)
  elseif s.enum and not s.enum[x] then table.insert(errs,'enum '..k)
  else v[k]=x end
 end
 if #errs>0 then return false,errs end
 return true,v
end

function C.new(deps)
 local self={values=C.defaults(),version=0,fetch=deps.fetch,warn=deps.warn or function() end,listeners={},rejected=0}

 function self.get(k)
  local v=self.values[k]
  if v==nil then error('LiveConfig unknown key '..tostring(k)) end
  return v
 end
 function self.onChanged(fn) table.insert(self.listeners,fn) end

 -- Returns 'applied' | 'same' | 'rejected' | 'fetch_failed'.
 function self.refresh()
  local ok,raw=pcall(self.fetch)
  if not ok or raw==nil then self.warn('LiveConfig fetch failed');return 'fetch_failed' end
  local good,res=C.validate(raw)
  if not good then self.rejected+=1;self.warn('LiveConfig rejected: '..table.concat(res,', '));return 'rejected' end
  if raw.version<=self.version then return 'same' end
  local old=self.values
  self.values=res;self.version=raw.version
  for k,v in res do
   if old[k]~=v then for _,fn in self.listeners do pcall(fn,k,v,old[k]) end end
  end
  return 'applied'
 end

 -- Values clients may see (flags + banner only, no tunables).
 function self.publicView()
  local p={}
  for k,v in self.values do if type(v)~='number' then p[k]=v end end
  return p
 end
 return self
end

return C
