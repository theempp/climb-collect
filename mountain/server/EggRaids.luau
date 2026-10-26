local Run=if script then require(game.ReplicatedStorage.MountainShared.RunRules) else require('../shared/RunRules')
local Config=if script then require(game.ReplicatedStorage.MountainShared.RaidConfig) else require('../shared/RaidConfig')
local E={}
function E.new(context)
 local P=context.profiles
 local reservations,owners,cooldowns,exits,cancellations={},{},{},{},{}
 local service={}
 local function changed(player) if context.changed then context.changed(player) end end
 local function present(player,data) if context.present then context.present(player,data) end end
 local function release(player,rest)
  local reservation=owners[player]
  if reservation then
   if reservations[reservation.egg.id]==reservation then reservations[reservation.egg.id]=nil end
   if rest then cooldowns[reservation.egg.id]=context.clock()+Config.eggRestSeconds end
  end
  owners[player]=nil
 end
 function service.strike(player,eggId)
  local p=P.get(player);local egg=type(eggId)=='string' and context.eggs[eggId]
  if not p or not egg or not context.alive(player) or exits[player] then return false,'unavailable' end
  if context.inBattle and context.inBattle(player) then return false,'finish_battle' end
  if not context.near(player,egg,Config.strikeRange) then return false,'too_far' end
  local now=context.clock();local config=Config.section(egg.section)
  if not config or now<(cooldowns[eggId] or 0) then return false,'egg_resting' end
  local current=reservations[eggId]
  if current and current.player~=player then return false,'reserved' end
  if p.run and (not current or p.run.id~=current.runId or p.run.phase~='breaking') then return false,'full_hands' end
  if current and now-current.lastStrike<Config.strikeCadence then return false,'cadence' end
  local first=current==nil
  if not current then
   current={player=player,runId=context.guid(),egg=egg,lastStrike=-math.huge,expiresAt=now+Config.reservationSeconds,species=egg.species or context.roll(egg.section)}
  end
  local ok,reason=Run.strike(p,{id=egg.id,runId=current.runId,species=current.species,section=egg.section,hitsRequired=config.hits},now)
  if not ok then return false,reason end
  current.lastStrike=now;current.expiresAt=now+Config.reservationSeconds
  reservations[eggId]=current;owners[player]=current
  if first and context.alert then context.alert(egg.section,player.UserId,eggId,now) end
  present(player,{kind='strike',run=table.clone(p.run),egg=egg,hitsRequired=config.hits})
  changed(player);return true,p.run.phase
 end
 function service.pickup(player,runId)
  local p=P.get(player);local current=owners[player]
  if not p or not current or current.runId~=runId or not context.alive(player) or exits[player] then return false,'no_reveal' end
  if not context.near(player,current.egg,Config.pickupRange) then return false,'too_far' end
  local ok,reason=Run.pickup(p,runId)
  if ok then current.expiresAt=nil;present(player,{kind='carry',run=table.clone(p.run)});changed(player) end
  return ok,reason
 end
 function service.forfeit(player,reason)
  if exits[player] or (P.pending and P.pending(player)) then return false,'save_pending' end
  local p=P.get(player);local lost=p and p.run and table.clone(p.run)
  if not p then cancellations[player]=reason;return false,'profile_unavailable' end
  cancellations[player]=nil;Run.forfeit(p,reason)
  release(player,true)
  if lost then present(player,{kind='lost',reason=reason,species=lost.species,eggId=lost.eggId});changed(player) end
  return lost~=nil
 end
 function service.exit(player,runId)
  local pending=exits[player]
  if pending and pending.runId~=runId then return false,'save_pending' end
  if pending and pending.busy then return false,'saving' end
  if not pending then
   local p=P.get(player)
   if not p or not p.run or p.run.id~=runId or p.run.phase~='carried' or not context.alive(player) or not context.atExit(player) then return false,'not_at_exit' end
   pending={runId=runId,species=p.run.species};exits[player]=pending
   present(player,{kind='securing',run=table.clone(p.run)})
  end
  pending.busy=true
  local ok,reason=P.transact(player,runId,function(draft) return Run.secure(draft,runId) end)
  pending.busy=false;pending.retryAt=context.clock()+Config.saveRetrySeconds
  if ok then
   release(player,true);exits[player]=nil
   present(player,{kind='safe',species=pending.species,runId=runId});changed(player)
  end
  return ok,reason
 end
 -- Only a completed server-authoritative Trial calls this; clients cannot name species.
 function service.reward(player,section,species,position)
  local p=P.get(player)
  if not p or p.run or exits[player] or not context.alive(player) then return false,'full_hands' end
  local runId=context.guid();local egg={id='trial:'..runId,section=section,species=species,position=position}
  local ok,reason=Run.strike(p,{id=egg.id,runId=runId,species=species,section=section,trial=true,hitsRequired=1},context.clock())
  if not ok then return false,reason end
  local record={player=player,runId=runId,egg=egg,species=species,expiresAt=context.clock()+Config.reservationSeconds}
  owners[player]=record;reservations[egg.id]=record
  present(player,{kind='reveal',run=table.clone(p.run),egg=egg});changed(player)
  return true,runId
 end
 function service.remove(player)
  if not exits[player] then service.forfeit(player,'leave') end
  -- Profiles owns pending durable work after disconnect; do not retain this Player.
  exits[player]=nil
  cancellations[player]=nil
  release(player,true)
 end
 function service.tick(now)
  for player,reason in pairs(cancellations) do service.forfeit(player,reason) end
  for player,record in pairs(owners) do
   if record.expiresAt and now>=record.expiresAt then service.forfeit(player,'abandoned') end
  end
  for player,pending in pairs(exits) do
   if not pending.busy and now>=(pending.retryAt or 0) then
    if context.spawn then context.spawn(service.exit,player,pending.runId) else service.exit(player,pending.runId) end
   end
  end
 end
 function service.protected(player) return exits[player]~=nil end
 return service
end
return E
