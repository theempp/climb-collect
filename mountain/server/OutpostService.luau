-- C03-C06 server: Defense Outposts, async raids, vault, shields, revenge, matchmaking, seasons, friend raids.
-- Cross-player safety: another player's PROFILE is never written. Each outpost is its own record ('o'..UserId)
-- changed only through atomic store:update with an attack lock and idempotent attack ids. Credits into a
-- profile (vault collect, raid loot, season rewards, paid-shield token use) go through Profiles.transact with
-- a stable id recorded in profile.v1.applied, so retries, crashes and server changes apply them exactly once.
-- deps: store, index (Store interface), profiles {get,transact}, clock(), guid(), notify(player,kind,data)?,
--       playerByUserId(id)?, productionRate(profile)->coins/hour, teamXP(player,amount)?, track(player,event,n)?,
--       isFriend(a,b)->bool, friends(userId)->{userId}, leaderboard {set(season,userId,trophies)}?, badge(player,badgeKey)?
local Shared=if script then game.ReplicatedStorage.MountainShared else nil
local function need(name) return if Shared then require(Shared[name]) else require('../shared/'..name) end
local O=need('OutpostRules')
local Sim=need('OutpostSim')
local Seasons=need('Seasons')
local Config=need('V1Config')
local Schema=need('V1Schema')
local Wallet=need('V1Wallet')
local cfg=Config.outpost
local S={}
local function hash(s) local h=7;s=tostring(s);for i=1,#s do h=(h*31+string.byte(s,i))%2147483647 end;return h end
local function copy(t) if type(t)~='table' then return t end local c={};for k,v in pairs(t) do c[k]=copy(v) end;return c end
local function raidDay(v,now)
 local day=Config.dayIndex(now)
 if v.raid.day~=day then v.raid.day=day;v.raid.attacks=0;v.raid.loot=0;v.raid.rerolls=0;v.raid.practice=0;v.raid.revenges=0;v.raid.friendly=0 end
end
function S.new(deps)
 local store,index=deps.store,deps.index
 local offers,active,finished,buckets,cache={}, {}, {}, {}, {}
 -- Outpost writes yield to profile saves when the DataStore budget is low (Q01 #1).
 local function budgetOk() return deps.budgetOk==nil or deps.budgetOk() end
 local service={offers=offers,active=active}
 local function clock() return deps.clock() end
 local function key(uid) return 'o'..uid end
 local function readRec(uid)
  local ok,rec=store:read(key(uid))
  if not ok then return false,'store_unavailable' end
  if rec~=nil and not O.validRecord(rec) then return false,'invalid_record' end
  return true,rec
 end
 -- Own-record write. fn(rec,now) -> ok,reason. Creates the record from the live profile when absent.
 local function updateOwn(player,fn)
  if not budgetOk() then return false,'busy_try_later' end
  local uid=player.UserId;local t=clock();local result,reason
  local p=deps.profiles.get(player)
  local ok,rec=store:update(key(uid),function(old)
   result,reason=false,nil
   local r=old
   if r~=nil and not O.validRecord(r) then reason='invalid_record';return nil end
   if r==nil then if not p then reason='unavailable';return nil end;r=O.newRecord(uid,O.newSnapshot(p),t) end
   O.accrue(r.vault,t);Seasons.rollover(r,t);r.lastActive=t
   local good,why=fn(r,t)
   if not good then reason=why;return nil end
   result=true;return r
  end)
  if not ok then return false,'store_unavailable' end
  if not result then return false,reason or 'cancelled' end
  cache[player]={rec=rec,at=clock()}
  return true,rec
 end
 local function applied(p,id) return Schema.has(p.v1.applied,id) end
 -- Profile credit with a stable id: applied at most once, even across servers.
 local function credit(player,id,mutate)
  return deps.profiles.transact(player,id,function(draft)
   if Schema.has(draft.v1.applied,id) then return true,'already_applied' end
   local good,why=mutate(draft)
   if not good then return false,why end
   Schema.push(draft.v1.applied,id,200);return true,'applied'
  end)
 end
 local function register(player,rec)
  local b=O.bucket(rec.trophies);local uid=player.UserId
  if buckets[player]==b then return end
  local entry={u=uid,t=rec.trophies,a=rec.lastActive}
  local ok=index:update('b'..b,function(old)
   local list=type(old)=='table' and old or {}
   for i=#list,1,-1 do if type(list[i])~='table' or list[i].u==uid then table.remove(list,i) end end
   table.insert(list,entry);while #list>cfg.bucketKeep do table.remove(list,1) end
   return list
  end)
  if ok then buckets[player]=b end
 end
 -- Credit first: the pending marker is cleared only after the loot is durable, so a failed save is retried
 -- by reconcile() (target result is the source of truth) instead of being lost.
 local function applyAttack(player,attackId,outcome)
  local okC=credit(player,'raid:'..attackId,function(draft)
   raidDay(draft.v1,clock());draft.coins+=outcome.loot;draft.v1.raid.loot+=outcome.loot;return true
  end)
  if not okC then return false end
  local okR,rec=updateOwn(player,function(r)
   if table.find(r.attacks,attackId) then if r.pending and r.pending.id==attackId then r.pending=false;return true end;return false,'already' end
   r.trophies=math.max(0,r.trophies+outcome.trophiesA)
   if not outcome.bot then r.played=true end
   table.insert(r.attacks,attackId);while #r.attacks>64 do table.remove(r.attacks,1) end
   if r.pending and r.pending.id==attackId then r.pending=false end
   return true
  end)
  if okR and deps.leaderboard then pcall(deps.leaderboard.set,rec.season,player.UserId,rec.trophies) end
  return true,rec
 end
 -- Brings outbox records into the profile: vault transfers, paid shields, interrupted attacks, season rewards.
 function service.reconcile(player,rec)
  local p=deps.profiles.get(player);if not p or not rec then return false end
  for _,x in ipairs(rec.transfers) do
   if not applied(p,'xfer:'..x.id) then credit(player,'xfer:'..x.id,function(d) d.coins+=x.coins;return true end);p=deps.profiles.get(player) or p end
  end
  for _,id in ipairs(rec.paidShields) do
   if not applied(p,'pshield:'..id) then credit(player,'pshield:'..id,function(d) d.v1.tokens.shield=math.max(0,d.v1.tokens.shield-1);return true end);p=deps.profiles.get(player) or p end
  end
  if rec.pending then
   local pending=rec.pending
   local okT,target=readRec(pending.target)
   if okT and target then
    local found;for _,r in ipairs(target.results) do if r.id==pending.id then found=r end end
    if found then applyAttack(player,pending.id,{loot=found.loot,trophiesA=found.trophiesA})
    elseif not (target.lock and target.lock.id==pending.id and target.lock.expires>clock()) then
     updateOwn(player,function(r) if r.pending and r.pending.id==pending.id then r.pending=false;return true end;return false,'nothing' end)
    end
   end
  end
  local granted={}
  for _,h in ipairs(Seasons.pending(rec.history,p.v1.seasons)) do
   local reward=Seasons.reward(h.tier)
   local ok=deps.profiles.transact(player,'season:'..h.season,function(d)
    if table.find(d.v1.seasons,h.season) then return true,'already' end
    local r={coins=reward.coins,eggTickets=reward.eggTickets,title=reward.title,badge=reward.badge,cosmetic=reward.cosmetic}
    if not Wallet.grant(d,r,clock()) then return false,'invalid_reward' end
    table.insert(d.v1.seasons,h.season);while #d.v1.seasons>32 do table.remove(d.v1.seasons,1) end
    d.v1.seasonSeen=math.max(d.v1.seasonSeen,h.season);return true,'granted'
   end)
   if ok then table.insert(granted,h);if reward.badge and deps.badge then pcall(deps.badge,player,reward.badge) end end
  end
  if #granted>0 and deps.notify then deps.notify(player,'season_rewards',{seasons=granted}) end
  -- Prune outbox entries once durably applied, so a forgotten applied-ring id can never re-credit (Q01 #2).
  p=deps.profiles.get(player)
  if p and (#rec.transfers>0 or #rec.paidShields>0) then
   local drop=false
   for _,x in ipairs(rec.transfers) do if applied(p,'xfer:'..x.id) then drop=true end end
   for _,id in ipairs(rec.paidShields) do if applied(p,'pshield:'..id) then drop=true end end
   if drop then updateOwn(player,function(r)
    for i=#r.transfers,1,-1 do if applied(p,'xfer:'..r.transfers[i].id) then table.remove(r.transfers,i) end end
    for i=#r.paidShields,1,-1 do if applied(p,'pshield:'..r.paidShields[i]) then table.remove(r.paidShields,i) end end
    return true
   end) end
  end
  return true
 end
 function service.ensure(player)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  local rate=deps.productionRate(p)
  local c=cache[player]
  if c and clock()-c.at<cfg.cacheSeconds and c.rec.vault.rate==math.max(0,rate) and not c.rec.pending then return true,c.rec end
  local ok,rec=updateOwn(player,function(r) r.name=tostring(player.Name or ''):sub(1,32);r.vault.rate=math.max(0,rate);return true end)
  if not ok then return false,rec end
  register(player,rec);service.reconcile(player,rec)
  return true,rec
 end
 local function ownView(player,rec)
  local p=deps.profiles.get(player);local t=clock()
  local unlocked=if p then O.unlocked(p) else {}
  local pieces={};for _,piece in ipairs(O.pieces) do table.insert(pieces,{id=piece.id,slot=piece.slot,hp=piece.hp,damage=piece.damage,effect=piece.effect,unlocked=unlocked[piece.id]==true,needs=piece.needs}) end
  local revenge={};for uid,r in pairs(rec.revenge) do if r.expires>t and not r.used then table.insert(revenge,{userId=tonumber(uid),expires=r.expires,attackId=r.attackId}) end end
  local raid=p and p.v1.raid
  local today=Config.dayIndex(t)
  local attacksUsed=if raid and raid.day==today then raid.attacks else 0
  local rerollsUsed=if raid and raid.day==today then raid.rerolls else 0
  local paidLeft=if rec.shield.paidDay==today then cfg.paidShieldsPerDay-rec.shield.paidCount else cfg.paidShieldsPerDay
  return {snapshot=rec.snapshot,slotTypes=O.slots,pieces=pieces,vault={coins=math.floor(rec.vault.coins),cap=rec.vault.cap,ratePerHour=rec.vault.rate*cfg.vaultShareOfProduction},
   shield={untilTime=rec.shield.untilTime,paidLeftToday=paidLeft,capSeconds=cfg.shieldCapSeconds},trophies=rec.trophies,season=Seasons.view(rec,t),revenge=revenge,
   attacksLeft=math.max(0,cfg.attacksPerDay-attacksUsed),freeRerollsLeft=math.max(0,cfg.freeRerollsPerDay-rerollsUsed),
   lootToday=if raid and raid.day==today then raid.loot else 0,lootCap=cfg.dailyLootCap,offer=service.offerView(player),attack=active[player] and {attackId=active[player].id,expires=active[player].expires} or nil}
 end
 function service.state(player)
  local ok,rec=service.ensure(player);if not ok then return false,rec end
  return true,ownView(player,rec)
 end
 function service.setSlot(player,slot,piece)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  local ok,rec=updateOwn(player,function(r) return O.setSlot(p,r.snapshot,slot,piece) end)
  return ok,if ok then ownView(player,rec) else rec
 end
 function service.setDefenders(player,ids)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  local ok,rec=updateOwn(player,function(r) return O.setDefenders(p,r.snapshot,ids) end)
  return ok,if ok then ownView(player,rec) else rec
 end
 function service.collect(player)
  if not deps.profiles.get(player) then return false,'unavailable' end
  local amount=0
  local ok,rec=updateOwn(player,function(r)
   amount=math.floor(r.vault.coins)
   if amount<1 then return false,'vault_empty' end
   r.vault.coins-=amount
   table.insert(r.transfers,{id=deps.guid(),coins=amount,at=clock()});while #r.transfers>20 do table.remove(r.transfers,1) end
   return true
  end)
  if not ok then return false,rec end
  service.reconcile(player,rec)
  return true,{coins=amount}
 end
 function service.shield(player)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  if (p.v1.tokens.shield or 0)<1 then return false,'no_shield_token' end
  local id=deps.guid()
  local ok,rec=updateOwn(player,function(r)
   local good,why=O.paidShield(r,clock());if not good then return false,why end
   table.insert(r.paidShields,id);while #r.paidShields>20 do table.remove(r.paidShields,1) end
   return true
  end)
  if not ok then return false,rec end
  service.reconcile(player,rec)
  return true,{untilTime=rec.shield.untilTime}
 end
 ---------------------------------------------------------------- matchmaking
 function service.offerView(player)
  local o=offers[player];if not o or o.expires<=clock() then return nil end
  return {offerId=o.id,bot=o.target==nil,userId=o.target,name=o.name,trophies=o.trophies,snapshot=o.snapshot,revenge=o.revenge,expires=o.expires}
 end
 local function candidate(uid,me,t)
  if uid==me then return nil end
  local ok,rec=readRec(uid)
  if not ok or not rec then return nil end
  Seasons.rollover(rec,t)
  if O.shielded(rec,t) or (rec.lock and rec.lock.expires>t) or rec.lastActive<t-cfg.activeDays*86400 then return nil end
  return rec
 end
 function service.find(player,opts)
  opts=opts or {}
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  if active[player] then return false,'attack_in_progress' end
  local t=clock();local uid=player.UserId
  raidDay(p.v1,t)
  local okOwn,own=service.ensure(player);if not okOwn then return false,own end
  local offer
  if opts.revenge then
   local r=own.revenge[tostring(opts.revenge)]
   if not r or r.used or r.expires<=t then return false,'no_revenge' end
   if p.v1.raid.revenges>=cfg.revengesPerDay then return false,'daily_revenge_cap' end
   local rec=candidate(opts.revenge,uid,t)
   if not rec then return false,'target_protected' end
   offer={target=opts.revenge,name=rec.name,trophies=rec.trophies,snapshot=rec.snapshot,revenge=true}
  else
   if p.v1.raid.attacks>=cfg.attacksPerDay then return false,'daily_attack_cap' end
   local seen,pool={},{}
   local b=O.bucket(own.trophies)
   for _,off in ipairs({0,-1,1,-2,2}) do
    if b+off>=0 then
     local okB,list=index:read('b'..(b+off))
     if okB and type(list)=='table' then for _,e in ipairs(list) do
      if type(e)=='table' and type(e.u)=='number' and not seen[e.u] and e.u~=uid and e.u~=opts.exclude and (e.a or 0)>=t-cfg.activeDays*86400 then seen[e.u]=true;table.insert(pool,e.u) end
     end end
    end
   end
   if deps.friends then
    local okF,friends=pcall(deps.friends,uid)
    if okF and type(friends)=='table' then for _,f in ipairs(friends) do if type(f)=='number' and not seen[f] and f~=opts.exclude then seen[f]=true;table.insert(pool,f) end end end
   end
   local salt=hash(uid..':'..t..':'..(opts.salt or 0))
   local function order(u)
    -- nonlinear (xorshift + add) so every candidate can come first for some salt
    local x=(hash(u)+salt)%4294967296
    for _=1,3 do x=bit32.bxor(x,bit32.lshift(x,13));x=bit32.bxor(x,bit32.rshift(x,17));x=bit32.bxor(x,bit32.lshift(x,5));x=(x+salt)%4294967296 end
    return x
   end
   table.sort(pool,function(a,c) return order(a)<order(c) end)
   for i=1,math.min(#pool,6) do
    local rec=candidate(pool[i],uid,t)
    if rec then offer={target=pool[i],name=rec.name,trophies=rec.trophies,snapshot=rec.snapshot};break end
   end
   if not offer then
    local seed=hash(uid..':bot:'..math.floor(t/cfg.offerSeconds)..':'..(opts.salt or 0))
    offer={bot=seed,name='bot',trophies=math.max(0,own.trophies+(seed%121)-60),snapshot=O.bot(seed,own.trophies)}
   end
  end
  offer.id=deps.guid();offer.expires=t+cfg.offerSeconds
  offers[player]=offer
  return true,service.offerView(player)
 end
 -- Re-roll the offered target: free rerolls per day, then a paid reroll token (mock receipt service).
 function service.reroll(player)
  local p=deps.profiles.get(player);local o=offers[player]
  if not p then return false,'unavailable' end
  if not o or o.expires<=clock() then return false,'no_offer' end
  if o.revenge then return false,'revenge_fixed' end
  raidDay(p.v1,clock())
  if p.v1.raid.rerolls<cfg.freeRerollsPerDay then p.v1.raid.rerolls+=1
  else
   if (p.v1.tokens.raidReroll or 0)<1 then return false,'no_reroll_token' end
   local okT=deps.profiles.transact(player,'reroll:'..o.id,function(d)
    if d.v1.tokens.raidReroll<1 then return false,'no_reroll_token' end
    d.v1.tokens.raidReroll-=1;return true
   end)
   if not okT then return false,'save_pending' end
  end
  offers[player]=nil
  return service.find(player,{exclude=o.target,salt=hash(o.id)})
 end
 ---------------------------------------------------------------- attack
 function service.start(player,offerId)
  local p=deps.profiles.get(player);local o=offers[player];local t=clock();local uid=player.UserId
  if not p then return false,'unavailable' end
  if active[player] then return false,'attack_in_progress' end
  if not o or o.id~=offerId or o.expires<=t then return false,'offer_expired' end
  raidDay(p.v1,t)
  if not o.revenge and p.v1.raid.attacks>=cfg.attacksPerDay then return false,'daily_attack_cap' end
  local attackId=deps.guid()
  local snapshot,trophies=o.snapshot,o.trophies
  if o.target then
   local reason
   local ok=store:update(key(o.target),function(old)
    reason=nil
    if not old or not O.validRecord(old) then reason='target_gone';return nil end
    Seasons.rollover(old,t)
    if O.shielded(old,t) then reason='shielded';return nil end
    if old.lock and old.lock.expires>t then reason='under_attack';return nil end
    old.lock={id=attackId,attacker=uid,expires=t+cfg.lockSeconds}
    snapshot,trophies=copy(old.snapshot),old.trophies
    return old
   end)
   if not ok then return false,'store_unavailable' end
   if reason then offers[player]=nil;return false,reason end
  end
  local counted=deps.profiles.transact(player,'raidstart:'..attackId,function(d)
   raidDay(d.v1,t)
   if not o.revenge then if d.v1.raid.attacks>=cfg.attacksPerDay then return false,'daily_attack_cap' end;d.v1.raid.attacks+=1
   else if d.v1.raid.revenges>=cfg.revengesPerDay then return false,'daily_revenge_cap' end;d.v1.raid.revenges+=1 end
   return true
  end)
  if not counted then
   if o.target then store:update(key(o.target),function(old) if old and old.lock and old.lock.id==attackId then old.lock=false;return old end;return nil end) end
   return false,'save_pending'
  end
  if o.target then
   local marked,why=updateOwn(player,function(r)
    r.pending={id=attackId,target=o.target,at=t}
    if o.revenge and r.revenge[tostring(o.target)] then r.revenge[tostring(o.target)].used=true end
    return true
   end)
   -- Without the pending marker a later credit failure could not be recovered: cancel instead (Q01 #5).
   if not marked then
    store:update(key(o.target),function(old) if old and old.lock and old.lock.id==attackId then old.lock=false;return old end;return nil end)
    offers[player]=nil;return false,why
   end
  end
  offers[player]=nil
  active[player]={id=attackId,target=o.target,bot=o.bot,snapshot=snapshot,trophies=trophies,revenge=o.revenge,expires=t+cfg.lockSeconds,name=o.name}
  return true,{attackId=attackId,snapshot=snapshot,expires=t+cfg.lockSeconds,bot=o.target==nil}
 end
 -- Builds the attacking team from the player's own eligible creatures (never Robux-egg creatures).
 local function team(p,ids)
  if type(ids)~='table' or #ids<1 or #ids>3 then return nil,'invalid_team' end
  local list,seen={},{}
  for k,id in pairs(ids) do
   if type(k)~='number' or k%1~=0 or k<1 or k>#ids or type(id)~='string' or seen[id] then return nil,'invalid_team' end
   seen[id]=true
   local found;for _,c in ipairs(p.creatures) do if c.id==id then found=c end end
   if not found then return nil,'not_owned' end
   if not O.eligible(found) then return nil,'robux_creature_excluded' end
   table.insert(list,{species=found.species,level=found.level,specialization=found.specialization})
  end
  return list
 end
 service.team=team
 local function resultView(r) return {attackId=r.id,stars=r.stars,destruction=r.destruction,loot=r.loot,trophies=r.trophiesA,events=r.events,bot=r.bot,saved=r.saved,forfeit=r.forfeit} end
 -- Commits a simulated (or forfeited) attack. Forfeit = abandon, disconnect or expiry after start: a 0-star
 -- result, so leaving can never dodge the trophy loss (Q01 #4). Revenge attacks grant no counter-revenge (Q01 #3).
 local function commit(player,a,sim,forfeit)
  local p=deps.profiles.get(player);local t=clock();local uid=player.UserId;local attackId=a.id
  local room=0
  if p then raidDay(p.v1,t);room=math.max(0,cfg.dailyLootCap-p.v1.raid.loot) end
  local loot,trophiesA,stored=0,0,nil
  if a.bot then
   loot=if forfeit then 0 else math.min(cfg.botLoot[sim.stars],room);trophiesA=math.floor(cfg.trophyWin[sim.stars]*cfg.botTrophyFactor)
  else
   local reason
   local ok=store:update(key(a.target),function(old)
    reason,stored=nil,nil
    if not old or not O.validRecord(old) then reason='target_gone';return nil end
    for _,r in ipairs(old.results) do if r.id==attackId then stored=r;return nil end end
    local ours=old.lock and old.lock.id==attackId
    if forfeit then if not ours then reason='lock_lost';return nil end
    elseif not ours or old.lock.expires<t then reason='stale_attack';return nil end
    O.accrue(old.vault,t);Seasons.rollover(old,t)
    loot=if forfeit then 0 else math.min(math.floor(old.vault.coins*cfg.lootShare[sim.stars]),room)
    trophiesA=cfg.trophyWin[sim.stars]
    local trophiesD=cfg.trophyDefend[sim.stars]
    old.vault.coins-=loot
    old.trophies=math.max(0,old.trophies+trophiesD);old.played=true
    if not forfeit then
     O.hitShield(old,t)
     if not a.revenge then old.revenge[tostring(uid)]={expires=t+cfg.revengeSeconds,used=false,attackId=attackId} end
    end
    for k,r in pairs(old.revenge) do if r.expires<=t then old.revenge[k]=nil end end
    table.insert(old.log,{id=attackId,attacker=uid,name=tostring(player.Name or ''):sub(1,32),at=t,stars=sim.stars,destruction=sim.destruction,loot=loot,trophies=trophiesD,revenge=not forfeit and not a.revenge,forfeit=forfeit or nil,events=sim.events})
    while #old.log>cfg.logKeep do table.remove(old.log,1) end
    table.insert(old.results,{id=attackId,attacker=uid,stars=sim.stars,destruction=sim.destruction,loot=loot,trophiesA=trophiesA,at=t})
    while #old.results>cfg.resultKeep do table.remove(old.results,1) end
    old.lock=false
    return old
   end)
   if not ok then return false,'store_unavailable' end -- active kept: the same result can be committed on retry
   if stored then loot,trophiesA=stored.loot,stored.trophiesA
   elseif reason=='lock_lost' then trophiesA=cfg.trophyWin[0] -- lock already gone: still record the attacker's loss
   elseif reason then active[player]=nil;return false,reason end
  end
  local saved=applyAttack(player,attackId,{loot=loot,trophiesA=trophiesA,bot=a.bot~=nil})
  if deps.track and not forfeit then deps.track(player,'raid_attack',1) end
  local r={id=attackId,stars=sim.stars,destruction=sim.destruction,loot=loot,trophiesA=trophiesA,events=sim.events,bot=a.bot~=nil,saved=saved==true,forfeit=forfeit or nil}
  finished[player]=finished[player] or {}
  finished[player][attackId]=r;active[player]=nil
  local victim=a.target and deps.playerByUserId and deps.playerByUserId(a.target)
  if victim and deps.notify and not forfeit then deps.notify(victim,'raided',{attacker=uid,stars=sim.stars,loot=loot}) end
  return true,r
 end
 local function forfeitSim() return {stars=0,destruction=0,events={{t=0,kind='end',stars=0,destruction=0,forfeit=true}}} end
 function service.submit(player,attackId,plan)
  local p=deps.profiles.get(player);local t=clock()
  if not p then return false,'unavailable' end
  finished[player]=finished[player] or {}
  if finished[player][attackId] then return true,resultView(finished[player][attackId]) end -- replayed request
  local a=active[player]
  if not a or a.id~=attackId then return false,'stale_attack' end
  if t>a.expires then
   local ok,r=commit(player,a,forfeitSim(),true)
   return false,if ok then 'attack_expired' else r
  end
  if not a.sim then
   local attackers,why=team(p,type(plan)=='table' and plan.creatures)
   if not attackers then return false,why end
   if not Sim.validPlan({lanes=plan.lanes,ability=plan.ability},#attackers) then return false,'invalid_plan' end
   -- The first accepted plan is final for this attack id: a retry cannot swap plans after a failed commit.
   -- The seed mixes a per-server secret so a client cannot pre-run plans against the snapshot (Q01 #4).
   a.sim=Sim.run(a.snapshot,attackers,{lanes=plan.lanes,ability=plan.ability},hash(attackId..(deps.secret or '')))
  end
  local ok,r=commit(player,a,a.sim,false)
  if not ok then return false,r end
  return true,resultView(r)
 end
 function service.abandon(player)
  local a=active[player];if not a then return false,'no_attack' end
  local ok=commit(player,a,forfeitSim(),true)
  if not ok then
   active[player]=nil
   if a.target then store:update(key(a.target),function(old) if old and old.lock and old.lock.id==a.id then old.lock=false;return old end;return nil end) end
  end
  return true,'forfeited'
 end
 function service.log(player)
  if not deps.profiles.get(player) then return false,'unavailable' end
  local t=clock();local seenAt=0;local entries
  local ok,rec=updateOwn(player,function(r) seenAt=r.logSeen;r.logSeen=t;return true end)
  if not ok then return false,rec end
  entries=rec.log
  local report={attacks=0,defended=0,coinsLost=0,trophies=0}
  for _,e in ipairs(entries) do if e.at>seenAt then report.attacks+=1;if e.stars==0 then report.defended+=1 end;report.coinsLost+=e.loot;report.trophies+=e.trophies end end
  return true,{entries=entries,report=report,since=seenAt}
 end
 ---------------------------------------------------------------- practice + friendly (no stakes, no rank)
 local function friendlyRun(p,snapshot,plan,salt)
  local attackers,why=team(p,type(plan)=='table' and plan.creatures)
  if not attackers then return nil,why end
  if not Sim.validPlan({lanes=plan.lanes,ability=plan.ability},#attackers) then return nil,'invalid_plan' end
  return Sim.run(snapshot,attackers,{lanes=plan.lanes,ability=plan.ability},hash(salt))
 end
 function service.practice(player,plan)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  local okE,rec=service.ensure(player);if not okE then return false,rec end
  local t=clock()
  local sim,why=friendlyRun(p,O.bot(hash(player.UserId..':practice'),rec.trophies),plan,deps.guid());if not sim then return false,why end
  raidDay(p.v1,t)
  local xp=0
  if p.v1.raid.practice<10 then p.v1.raid.practice+=1;xp=cfg.practiceXP;if deps.teamXP then deps.teamXP(player,xp) end end
  if deps.track then deps.track(player,'practice_raid',1) end
  return true,{stars=sim.stars,destruction=sim.destruction,events=sim.events,xp=xp,coins=0,trophies=0}
 end
 function service.friendly(player,friendId,plan)
  local p=deps.profiles.get(player);if not p then return false,'unavailable' end
  if type(friendId)~='number' or friendId==player.UserId or not deps.isFriend(player.UserId,friendId) then return false,'not_friends' end
  raidDay(p.v1,clock())
  if p.v1.raid.friendly>=cfg.friendlyPerDay then return false,'daily_friendly_cap' end
  local ok,rec=readRec(friendId)
  if not ok then return false,rec end
  if not rec then return false,'no_outpost' end
  local sim,why=friendlyRun(p,rec.snapshot,plan,deps.guid());if not sim then return false,why end
  p.v1.raid.friendly+=1;p.v1.raid.friendlyPlayed+=1;if sim.stars>=2 then p.v1.raid.friendlyWins+=1 end
  if deps.track then deps.track(player,'friendly_raid',1) end
  local friend=deps.playerByUserId and deps.playerByUserId(friendId)
  if friend and deps.notify then deps.notify(friend,'friendly_result',{attacker=player.UserId,stars=sim.stars,destruction=sim.destruction,events=sim.events}) end
  return true,{stars=sim.stars,destruction=sim.destruction,events=sim.events,coins=0,trophies=0,friendlyWins=p.v1.raid.friendlyWins}
 end
 function service.remove(player)
  if active[player] then service.abandon(player) end
  offers[player]=nil;finished[player]=nil;buckets[player]=nil;cache[player]=nil
 end
 return service
end
return S
