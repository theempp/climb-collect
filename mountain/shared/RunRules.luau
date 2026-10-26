-- Pure custody. secure() mutates only a caller-owned transaction draft.
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local Run={}
local function text(v) return type(v)=='string' and #v>0 and #v<=128 end
local function eggs(list)
 if type(list)~='table' then return false end
 local count=0
 for key,e in pairs(list) do
  if type(key)~='number' or key%1~=0 or key<1 or key>#list or type(e)~='table' or not text(e.id) or not C.byId[e.species] or C.byId[e.species].rarity=='Legendary' then return false end
  count+=1
 end
 return count==#list
end
function Run.migrate(p)
 if type(p)~='table' or (p.schema~=1 and p.schema~=2) then return nil end
 if p.schema==2 then return p end
 if not eggs(p.eggs) or not eggs(p.cargo) or (p.recovery~=nil and (type(p.recovery)~='table' or not eggs(p.recovery.eggs))) then return nil end
 local identities={}
 for _,list in ipairs({p.eggs,p.cargo,if p.recovery then p.recovery.eggs else {}}) do for _,e in ipairs(list) do
  local previous=identities[e.id]
  if previous and (previous.species~=e.species or (previous.readyAt~=nil and e.readyAt~=nil and previous.readyAt~=e.readyAt)) then return nil end
  identities[e.id]=previous or e
 end end
 local seen={};for _,e in ipairs(p.eggs) do if seen[e.id] then return nil end;seen[e.id]=true end
 local entitlements={}
 for _,list in ipairs({p.cargo,if p.recovery then p.recovery.eggs else {}}) do
  for _,e in ipairs(list) do
   if type(e)~='table' or not text(e.id) or not C.byId[e.species] or C.byId[e.species].rarity=='Legendary' then return nil end
   if not seen[e.id] then seen[e.id]=true;table.insert(entitlements,table.clone(e)) end
  end
 end
 p.legacyEntitlements={};for _,e in ipairs(entitlements) do table.insert(p.eggs,e);p.legacyEntitlements[e.id]=true end
 p.cargo={};p.recovery=nil;p.run=nil;p.securedRunIds={};p.schema=2
 return p
end
function Run.strike(p,egg,now)
 if p.schema~=2 or type(egg)~='table' or not text(egg.id) or not text(egg.runId) or not C.byId[egg.species] or type(egg.section)~='number' or egg.section%1~=0 or egg.section<1 or egg.section>6 or type(now)~='number' or now~=now then return false,'invalid' end
 if egg.trial and (not p.wins[tostring(egg.section)] or p.captures[egg.species]) then return false,'trial_unavailable' end
 if p.run and (p.run.eggId~=egg.id or p.run.id~=egg.runId or p.run.phase~='breaking') then return false,'full_hands' end
 if not p.run then p.run={id=egg.runId,eggId=egg.id,species=egg.species,section=egg.section,trial=egg.trial==true,phase='breaking',hits=0,startedAt=now} end
 p.run.hits+=1
 if p.run.hits>=math.max(1,egg.hitsRequired or 1) then p.run.phase='revealed' end
 return true
end
function Run.pickup(p,runId)
 local r=p.run;if not r or r.id~=runId or r.phase~='revealed' then return false,'no_reveal' end
 r.phase='carried';return true
end
function Run.forfeit(p,reason)
 if not p.run then return false end
 p.run=nil;return true,reason
end
function Run.secure(p,runId)
 for _,id in ipairs(p.securedRunIds or {}) do if id==runId then return true,'already_secured' end end
 local r=p.run
 if not r or r.id~=runId or r.phase~='carried' then return false,'not_carried' end
 if r.trial and p.captures[r.species] then return false,'already_captured' end
 p.serial+=1
 table.insert(p.creatures,{id='c'..p.serial,species=r.species,level=1,xp=0})
 if r.trial then p.captures[r.species]=true end
 p.securedRunIds=p.securedRunIds or {};table.insert(p.securedRunIds,runId)
 if #p.securedRunIds>128 then table.remove(p.securedRunIds,1) end
 p.run=nil;return true,'secured'
end
return Run
