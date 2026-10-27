local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local UIProtocol=require(game.ReplicatedStorage.MountainShared.UIProtocol)
local Bats=require(game.ReplicatedStorage.MountainShared.BatRules)
local Store=require(script.Parent.Store)
local Http=game:GetService('HttpService')
local Run=game:GetService('RunService')
local Custody=R.run
local function log(...) if not Run:IsStudio() then print('[CC-SAVE]',...) end end
local function create(store,owner)
local P={sessions={},mode=if Run:IsStudio() then 'Studio memory • resets when Play stops' else 'Live DataStore'}
local function copy(t) return Http:JSONDecode(Http:JSONEncode(t)) end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function dense(t)
 if type(t)~='table' then return false end
 local count=0;for k in pairs(t) do if not finite(k) or k%1~=0 or k<1 or k>#t then return false end;count+=1 end
 return count==#t
end
local function valid(p)
 if type(p)~='table' or (p.schema~=1 and p.schema~=2) then return false end
 for _,key in ipairs({'creatures','team','cargo','eggs','wins','captures','discoveries','claims','shortcuts','resources'}) do if type(p[key])~='table' then return false end end
 for _,key in ipairs({'serial','unlocked','coins','trophies','lastIncome','competitionAt'}) do if type(p[key])~='number' or p[key]~=p[key] or math.abs(p[key])==math.huge then return false end end
 if p.unlocked<1 or p.unlocked>6 then return false end
 if p.tycoon~=nil and not R.tycoon.valid(p.tycoon) then return false end
 if p.settings~=nil and not UIProtocol.settings(p.settings) then return false end
 if p.bats~=nil then
  if type(p.bats)~='table' or type(p.bats.equipped)~='string' or type(p.bats.levels)~='table' or not p.bats.levels[p.bats.equipped] then return false end
  for id,n in pairs(p.bats.levels) do if not Bats.byId[id] or not finite(n) or n%1~=0 or n<1 or n>Bats.maxLevel then return false end end
 end
 for _,key in ipairs({'creatures','team','cargo','eggs'}) do if not dense(p[key]) then return false end end
 local ids={}
 for _,c in ipairs(p.creatures) do
  if type(c)~='table' or not C.byId[c.species] or type(c.id)~='string' or #c.id==0 or ids[c.id] or not finite(c.level) or c.level%1~=0 or c.level<1 or c.level>50 or not finite(c.xp) or c.xp<0 then return false end
  ids[c.id]=true
 end
 local team={};for _,id in ipairs(p.team) do if not ids[id] or team[id] then return false end;team[id]=true end
 for _,list in ipairs({p.eggs,p.cargo}) do for _,e in ipairs(list) do if type(e)~='table' or not C.byId[e.species] or C.byId[e.species].rarity=='Legendary' or type(e.id)~='string' or (e.readyAt and type(e.readyAt)~='number') then return false end end end
 if p.recovery~=nil then
  if type(p.recovery)~='table' or not dense(p.recovery.eggs) then return false end
  for _,e in ipairs(p.recovery.eggs) do if type(e)~='table' or type(e.id)~='string' or not C.byId[e.species] or C.byId[e.species].rarity=='Legendary' then return false end end
 end
 if p.schema==2 then
  if type(p.legacyEntitlements)~='table' or not dense(p.securedRunIds) or #p.securedRunIds>128 then return false end
  for _,id in ipairs(p.securedRunIds) do if type(id)~='string' or #id>128 then return false end end
  local r=p.run
  if r~=nil and (type(r)~='table' or type(r.id)~='string' or type(r.eggId)~='string' or not C.byId[r.species] or not R.canEnter(p,r.section) or not table.find({'breaking','revealed','carried'},r.phase) or type(r.hits)~='number' or r.hits<0 or r.hits%1~=0 or type(r.trial)~='boolean') then return false end
 end
 return true
end
function P.load(player)
 local now=os.time();local accepted=false
 local ok,data,err=store:update('u'..player.UserId,function(old)
  accepted=false
  if old and (type(old)~='table' or not valid(old.profile)) then return nil end
  if old and old.lock and old.lock.owner~=owner and old.lock.expires>now then return nil end
  local p=if old then old.profile else R.newProfile(now)
  p=Custody.migrate(p);if not p or not valid(p) then return nil end
  Custody.forfeit(p,'leave')
  if not p.tycoon then R.settleIncome(p,now);R.tycoon.ensure(p,now) else R.tycoon.settle(p,now,true) end
  accepted=true;return {profile=p,lock={owner=owner,expires=now+180}}
 end)
 if not ok or not accepted or not data or not valid(data.profile) then log('load FAIL',player.UserId,'ok',ok,'accepted',accepted,'err',err);return nil,err or 'Profile unavailable or in use; no data overwritten.' end
 log('load OK',player.UserId,'coins',data.profile.coins,'creatures',#data.profile.creatures,'serial',data.profile.serial)
 data.profile.settings=UIProtocol.settings(nil,data.profile.settings);Bats.normalize(data.profile)
 local s={p=data.profile,busy=false,healthy=true,closing=false,lastSave=now,leaseUntil=now+180}
 P.sessions[player]=s;return s.p
end
function P.get(player) local s=P.sessions[player];return s and s.healthy and not s.closing and not s.transacting and not s.pending and os.time()<s.leaseUntil and s.p end
-- A pending draft owns its write ID across uncertain responses. Normal access stays
-- frozen until durable commit; no caller can observe an unsaved ownership grant.
local function commitPending(player,s)
 local pending=s.pending;if not pending then return true end
 s.busy=true;s.transacting=true
 local written=false;local leaseUntil=s.leaseUntil
 for attempt=1,3 do
  local now=os.time();local accepted=false
  local ok=store:update('u'..player.UserId,function(old)
   accepted=false
   if not old or not old.lock or old.lock.owner~=owner or old.lock.expires<=now then return nil end
   if old.writeId==pending.writeId then accepted=true;leaseUntil=old.lock.expires;return old end
   leaseUntil=now+180;accepted=true
   return {profile=pending.draft,writeId=pending.writeId,lock={owner=owner,expires=leaseUntil}}
  end)
  if ok and accepted then written=true;break end
  if attempt<3 then task.wait(attempt) end
 end
 if written then
  -- Preserve the top-level profile identity used by existing synchronous services.
  table.clear(s.p);for k,v in pairs(pending.draft) do s.p[k]=v end
  pending.committed=true;s.pending=nil;s.lastSave=os.time();s.leaseUntil=leaseUntil
 end
 s.busy=false;s.transacting=false;s.healthy=written
 if s.releaseRequested then s.releaseRequested=nil;task.defer(P.save,player,true) end
 return written,if written then pending.reason else 'save_pending'
end
function P.transact(player,transactionId,mutate)
 local s=P.sessions[player]
 if not s or type(transactionId)~='string' or #transactionId<1 or #transactionId>128 then return false,'unavailable' end
 if s.pending and s.pending.id~=transactionId then return false,'save_pending' end
 if s.closing and not s.pending then return false,'closing' end
 if not s.pending then
  if not s.healthy or os.time()>=s.leaseUntil then return false,'unavailable' end
  local copied,draft=pcall(copy,s.p);if not copied then return false,'invalid_profile' end
  local called,ok,reason=pcall(mutate,draft)
  if not called or not ok or not valid(draft) then return false,reason or 'invalid_transaction' end
  s.pending={id=transactionId,writeId=Http:GenerateGUID(false),draft=draft,reason=reason}
 end
 -- Reserve the exact draft BEFORE yielding behind an autosave. Disconnect must
 -- commit this pending exit before releasing its lease, regardless of wait order.
 local requested=s.pending
 local deadline=os.clock()+12
 while s.busy and os.clock()<deadline do task.wait(.1) end
 if requested.committed then return true,requested.reason end
 if s.busy then return false,'busy' end
 return commitPending(player,s)
end
function P.pending(player) local s=P.sessions[player];return s and s.pending and s.pending.id end
function P.save(player,release)
 local s=P.sessions[player];if not s then return false end
 if release then s.closing=true end
 local deadline=os.clock()+12
 while s.busy and os.clock()<deadline do task.wait(.1) end
 if s.busy then s.healthy=false;if release then s.releaseRequested=true end;return false end
 if s.pending and not commitPending(player,s) then return false end
 s.busy=true
 if not valid(s.p) then s.busy=false;s.healthy=false;return false end
 local copied,snapshot=pcall(copy,s.p)
 if not copied then s.busy=false;s.healthy=false;return false end
 local written=false;local lastErr
 local writeId=Http:GenerateGUID(false)
 local leaseUntil=s.leaseUntil
 for attempt=1,3 do
  local now=os.time();local accepted=false
  local ok,_,err=store:update('u'..player.UserId,function(old)
   accepted=false
   if old and old.writeId==writeId then accepted=true;return old end
   if not old or not old.lock or old.lock.owner~=owner or old.lock.expires<=now then return nil end
   leaseUntil=now+180
   accepted=true;return {profile=snapshot,writeId=writeId,lock=if release then nil else {owner=owner,expires=leaseUntil}}
  end)
  if ok and accepted then written=true;break end
  lastErr=err or (if ok then 'lease_lost' else 'store_error')
  if attempt<3 then task.wait(attempt) end
 end
 log(if written then 'save OK' else 'save FAIL',player.UserId,'release',release==true,'coins',snapshot.coins,'creatures',#snapshot.creatures,'err',lastErr)
 s.busy=false;s.healthy=written;s.lastSave=os.time();s.leaseUntil=leaseUntil
 if release and written then P.sessions[player]=nil
 elseif s.releaseRequested and not release then
  s.releaseRequested=nil;task.defer(P.save,player,true)
 end
 return written
end
function P.setSettings(player,patch)
 local p=P.get(player);if not p then return false end
 local settings=UIProtocol.settings(patch,p.settings);if not settings then return false end
 p.settings=settings
 local ok=P.save(player,false)
 return ok,if ok then table.clone(settings) else nil
end
P.valid=valid
return P
end
local service=create(if Run:IsStudio() then Store.memory() else Store.datastore('MountainEmpire_FirstDraft_v1'),game.JobId..Http:GenerateGUID(false))
if Run:IsStudio() then service.newForTests=create end
return service
