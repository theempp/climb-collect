-- Server party glue: Roblox players <-> PartyRules, ready-check travel into the same mountain instance,
-- late follow, disconnect recovery, cross-server code join (adapters; live MemoryStore/Teleport UNVERIFIED).
-- deps: clock(), player(userId)->Player?, travel(player)->bool, follow(player,leader)->bool, notify(player,kind,data),
--       isFriend(userId,friendId)->bool, directory {publish(code,data),lookup(code)->data?,remove(code)}?,
--       teleport(player,jobId,data)->ok,err ?, jobId, track(player,event,amount)?
local Rules=if script then require(game.ReplicatedStorage.MountainShared.PartyRules) else require('../shared/PartyRules')
local S={}
function S.new(deps)
 local reg=Rules.new(deps.seed)
 local service={registry=reg}
 local function push(userId)
  local player=deps.player(userId);if not player then return end
  local party=Rules.partyOf(reg,userId);local invites={}
  for _,inv in pairs(reg.invites) do if inv.target==userId then table.insert(invites,{partyId=inv.party,from=inv.from,expires=inv.expires}) end end
  deps.notify(player,'party',{party=Rules.snapshot(party),invites=invites})
 end
 local function pushParty(party) if party then for _,id in ipairs(party.members) do push(id) end end end
 function service.state(player)
  local invites={}
  for _,inv in pairs(reg.invites) do if inv.target==player.UserId then table.insert(invites,{partyId=inv.party,from=inv.from,expires=inv.expires}) end end
  return {party=Rules.snapshot(Rules.partyOf(reg,player.UserId)),invites=invites}
 end
 local function publishCode(party)
  if deps.directory and party then pcall(deps.directory.publish,party.code,{jobId=deps.jobId,leader=party.leader,size=#party.members}) end
 end
 function service.request(player,op,payload)
  local uid,now=player.UserId,deps.clock()
  local ok,res
  if op=='create' then ok,res=Rules.create(reg,uid,now);if ok then publishCode(res) end
  elseif op=='invite' then
   if not deps.player(payload.userId) then return false,'target_not_in_server' end
   ok,res=Rules.invite(reg,uid,payload.userId,now)
   if ok then publishCode(Rules.partyOf(reg,uid));push(payload.userId) end
  elseif op=='accept' then ok,res=Rules.accept(reg,uid,payload.partyId,now)
  elseif op=='decline' then ok,res=Rules.decline(reg,uid,payload.partyId)
  elseif op=='friend' then
   if not deps.isFriend(uid,payload.userId) then return false,'not_friends' end
   ok,res=Rules.joinFriend(reg,uid,payload.userId,now)
  elseif op=='code' then
   ok,res=Rules.joinCode(reg,uid,payload.code,now)
   if not ok and res=='code_not_here' and deps.directory and deps.teleport then
    -- Seat the duo together: move the joiner to the leader's server; the code is retried on arrival.
    local found,entry=pcall(deps.directory.lookup,string.upper(payload.code))
    if not found or type(entry)~='table' or type(entry.jobId)~='string' then return false,'code_not_found' end
    if entry.jobId==deps.jobId then return false,'code_not_found' end
    if (entry.size or 1)>=2 then return false,'party_full' end
    local sent,err=deps.teleport(player,entry.jobId,{partyCode=string.upper(payload.code)})
    return sent==true,if sent then 'teleporting' else (err or 'teleport_failed')
   end
  elseif op=='leave' then
   local party=Rules.partyOf(reg,uid)
   ok,res=Rules.leave(reg,uid,now)
   if ok and party and res.dissolved and deps.directory then pcall(deps.directory.remove,party.code) end
   push(uid);if party then pushParty(reg.parties[party.id]) end
   return ok,res
  elseif op=='kick' then
   local party=Rules.partyOf(reg,uid)
   ok,res=Rules.kick(reg,uid,payload.userId,now)
   if ok then push(payload.userId);pushParty(party) end
   return ok,res
  elseif op=='ready_start' then ok,res=Rules.startReady(reg,uid,now)
  elseif op=='ready' then ok,res=Rules.setReady(reg,uid,payload.ready==true,now)
  elseif op=='follow' then
   local can,party=Rules.canFollow(reg,uid,now)
   if not can then return false,party end
   local leader
   for _,id in ipairs(party.travelers) do leader=leader or deps.player(id) end
   if not leader or not deps.follow(player,leader) then return false,'follow_unavailable' end
   Rules.followed(reg,uid);pushParty(party)
   return true,'following'
  else return false,'unknown_op' end
  if ok then pushParty(Rules.partyOf(reg,uid)) else push(uid) end
  return ok,if ok then 'ok' else res
 end
 function service.tick()
  local now=deps.clock()
  for _,e in ipairs(Rules.tick(reg,now)) do
   if e.kind=='invite_expired' then push(e.target)
   elseif e.kind=='travel' then
    local party=reg.parties[e.party];local moved={}
    for _,id in ipairs(e.travelers) do
     local player=deps.player(id)
     if player and deps.travel(player) then table.insert(moved,id) end
    end
    if party then party.travelers=moved end
    if #moved==2 and deps.track then for _,id in ipairs(moved) do local pl=deps.player(id);if pl then deps.track(pl,'party_expedition',1) end end end
    pushParty(party)
   end
  end
 end
 -- Disconnect: same as leave; the remaining member continues solo with the party kept open.
 function service.remove(player)
  local party=Rules.partyOf(reg,player.UserId)
  local ok,res=Rules.leave(reg,player.UserId,deps.clock())
  if ok and party then
   if res.dissolved and deps.directory then pcall(deps.directory.remove,party.code) end
   pushParty(reg.parties[party.id])
  end
 end
 -- Arrival with teleport data: auto-join the party whose code brought the player here.
 function service.arrived(player,data)
  if type(data)=='table' and type(data.partyCode)=='string' and #data.partyCode<=12 then
   local ok=Rules.joinCode(reg,player.UserId,data.partyCode,deps.clock())
   if ok then pushParty(Rules.partyOf(reg,player.UserId)) end
   return ok
  end
  return false
 end
 -- A departed party re-opens for a new ready check only when every traveler is back in the sanctuary
 -- (the member who stayed home keeps the follow window meanwhile).
 function service.sweep(inSanctuary)
  local now=deps.clock()
  for _,party in pairs(reg.parties) do
   if party.state=='departed' and party.departedAt and now>party.departedAt+5 then
    local home=true;for _,id in ipairs(party.travelers or {}) do if not inSanctuary(id) then home=false end end
    if home then Rules.reset(reg,party.id);pushParty(party) end
   end
  end
 end
 function service.returned(player)
  local party=Rules.partyOf(reg,player.UserId)
  if party and party.state=='departed' then Rules.reset(reg,party.id);pushParty(party) end
 end
 function service.mates(player)
  local list={};for _,id in ipairs(Rules.mates(reg,player.UserId)) do local pl=deps.player(id);if pl then table.insert(list,pl) end end
  return list
 end
 return service
end
return S
