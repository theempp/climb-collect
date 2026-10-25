local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local UIProtocol=require(game.ReplicatedStorage.MountainShared.UIProtocol)
local Store=require(script.Parent.Store)
local Http=game:GetService('HttpService')
local Run=game:GetService('RunService')
local function create(store,owner)
local P={sessions={},mode=if Run:IsStudio() then 'Studio memory • resets when Play stops' else 'Live DataStore'}
local function copy(t) return Http:JSONDecode(Http:JSONEncode(t)) end
local function valid(p)
 if type(p)~='table' or p.schema~=1 then return false end
 for _,key in ipairs({'creatures','team','cargo','eggs','wins','captures','discoveries','claims','shortcuts','resources'}) do if type(p[key])~='table' then return false end end
 for _,key in ipairs({'serial','unlocked','coins','trophies','lastIncome','competitionAt'}) do if type(p[key])~='number' or p[key]~=p[key] or math.abs(p[key])==math.huge then return false end end
 if p.unlocked<1 or p.unlocked>6 then return false end
 if p.settings~=nil and not UIProtocol.settings(p.settings) then return false end
 for _,c in ipairs(p.creatures) do if not C.byId[c.species] or type(c.id)~='string' or type(c.level)~='number' or c.level<1 or c.level>50 or type(c.xp)~='number' then return false end end
 for _,list in ipairs({p.eggs,p.cargo}) do for _,e in ipairs(list) do if not C.byId[e.species] or C.byId[e.species].rarity=='Legendary' or type(e.id)~='string' or (e.readyAt and type(e.readyAt)~='number') then return false end end end
 return true
end
function P.load(player)
 local now=os.time();local accepted=false
 local ok,data,err=store:update('u'..player.UserId,function(old)
  accepted=false
  if old and (type(old)~='table' or not valid(old.profile)) then return nil end
  if old and old.lock and old.lock.owner~=owner and old.lock.expires>now then return nil end
  local p=if old then old.profile else R.newProfile(now)
  accepted=true;return {profile=p,lock={owner=owner,expires=now+180}}
 end)
 if not ok or not accepted or not data or not valid(data.profile) then return nil,err or 'Profile unavailable or in use; no data overwritten.' end
 data.profile.settings=UIProtocol.settings(nil,data.profile.settings)
 local s={p=data.profile,busy=false,healthy=true,closing=false,lastSave=now}
 P.sessions[player]=s;return s.p
end
function P.get(player) local s=P.sessions[player];return s and s.healthy and not s.closing and s.p end
function P.save(player,release)
 local s=P.sessions[player];if not s then return false end
 if release then s.closing=true end
 local deadline=os.clock()+12
 while s.busy and os.clock()<deadline do task.wait(.1) end
 if s.busy then s.healthy=false;if release then s.releaseRequested=true end;return false end
 s.busy=true
 local copied,snapshot=pcall(copy,s.p)
 if not copied then s.busy=false;s.healthy=false;return false end
 local written=false
 for attempt=1,3 do
  local now=os.time();local accepted=false
  local ok=store:update('u'..player.UserId,function(old)
   accepted=false
   if not old or not old.lock or old.lock.owner~=owner then return nil end
   accepted=true;return {profile=snapshot,lock=if release then nil else {owner=owner,expires=now+180}}
  end)
  if ok and accepted then written=true;break end
  if attempt<3 then task.wait(attempt) end
 end
 s.busy=false;s.healthy=written;s.lastSave=os.time()
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
