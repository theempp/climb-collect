-- Correlated requests are scoped to one player connection. Retired IDs never execute.

local Protocol=if script then require(game.ReplicatedStorage.MountainShared.UIProtocol) else require('../shared/UIProtocol')

local U={}

function U.new(options)

 local sessions={}

 local clock=options.clock or os.clock

 local maxCached=options.maxCached or 128

 local maxTokens=options.maxTokens or 4

 local interval=options.minInterval or .12

 local service={}

 local function result(id,action,ok,message,data)

  return {id=if type(id)=='string' and #id<=64 then id else '',action=if type(action)=='string' and #action<=32 then action else '',ok=ok==true,message=message,data=data}

 end

 function service.process(player,id,action,payload)

  local token,sequence=Protocol.parseId(id)

  if not token then return result(id,action,false,'Invalid request id.') end

  local session=sessions[player]

  if not session then session={cache={},order={},tokens={},tokenCount=0,nextAt=0};sessions[player]=session end

  if session.cache[id] then return session.cache[id] end

  if session.running==id then return nil end -- The original call owns the eventual terminal reply.

  local high=session.tokens[token]

  if high and sequence<=high then return result(id,action,false,'Request expired. Refresh before trying again.') end

  if not high then

   if session.tokenCount>=maxTokens then return result(id,action,false,'Too many UI sessions. Please reconnect.') end

   session.tokenCount+=1

  end

  session.tokens[token]=sequence

  local function finish(value)

   session.cache[id]=value;table.insert(session.order,id)

   if #session.order>maxCached then session.cache[table.remove(session.order,1)]=nil end

   return value

  end

  local valid,message=Protocol.validate(id,action,payload)

  if not valid then return finish(result(id,action,false,message)) end

  if session.running or (options.busy and options.busy(player)) then return finish(result(id,action,false,'Another action is in progress. Please wait.')) end

  local now=clock()

  if now<session.nextAt then return finish(result(id,action,false,'Please wait before trying another action.')) end

  session.nextAt=now+interval

  if options.available and not options.available(player) then return finish(result(id,action,false,'Profile or saving unavailable. Please retry when saving resumes.')) end

  session.running=id

  if options.setBusy then options.setBusy(player,true) end

  local called,ok,reply,data=pcall(options.handle,player,action,payload)

  session.running=nil

  if options.setBusy then options.setBusy(player,false) end

  if not called then

   if options.failed then options.failed(ok) end

   return finish(result(id,action,false,'Action unavailable. Refresh your state before trying again.'))

  end

  return finish(result(id,action,ok,if type(reply)=='string' then reply else (if ok==true then 'Action complete.' else 'Action rejected.'),data))

 end

 function service.remove(player) sessions[player]=nil end

 return service

end

-- This dispatcher shares the legacy rules rather than creating a second economy.

function U.actions(context)

 local P,R=context.profiles,context.rules

 local function copyCreature(c) return if c then table.clone(c) else nil end

 return function(player,action,payload)

  local p=P.get(player)

  if not p then return false,'Profile or saving unavailable.' end

  if action=='State' then context.publish(player);return true,'State refreshed.' end

  if action=='Settings' then

   local ok,settings=P.setSettings(player,payload)

   return ok,if ok then 'Settings saved.' else 'Settings save unavailable.',if ok then {settings=settings} else nil

  end

  if not context.safe(player) then return false,'Wait until your character is ready and movement is safe.' end

  if action=='Tycoon' or (action=='CollectIncome' and p.tycoon) then
   if not context.atHome or not context.atHome(player) then return false,'Use your own sanctuary plot.' end
   local T=R.tycoon;local request=if action=='CollectIncome' then {op='bank'} else payload
   T.settle(p,context.clock(),false)
   local ok=false;local message='Action unavailable.'
   if request.op=='collect' then local amount=T.collect(p,request.slot);ok=amount>0;message=if ok then 'Collected '..amount..' production eggs.' else 'No eggs collected: storage empty or bag full.'
   elseif request.op=='bank' then local amount=T.bank(p);ok=amount>0;message=if ok then 'Banked production eggs for '..amount..' coins.' else 'Your production egg bag is empty.'
   elseif request.op=='assign' then ok=T.assign(p,request.slot,request.id,context.clock());message=if ok then 'Habitat assignment updated.' else 'Choose an owned creature not assigned to another habitat.'
   elseif request.op=='swap' then ok=T.swap(p,request.slot,request.other,context.clock());message=if ok then 'Habitat creatures swapped. Stored eggs preserved.' else 'Choose two unlocked owned habitats.'
   elseif request.op=='attune' then ok=T.attune(p,request.slot,request.kingdom,context.clock());message=if ok then 'Habitat attuned.' else 'Unlock that kingdom first.'
   elseif request.op=='upgrade' then ok=T.upgrade(p,request.path,request.slot,context.clock());message=if ok then 'Upgrade installed.' else 'Check coins, prerequisites and maximum level.'
   elseif request.op=='cosmetic' then ok=T.cosmetic(p,request.id);message=if ok then 'Sanctuary palette updated.' else 'Unknown palette.' end
   if ok and context.save then context.save(player) end
   return ok,message,{tycoon=T.snapshot(p)}
  end
  if action=='Special' then

   local ok=context.combat.special(player,payload.slot,payload.ability)

   return ok,if ok then 'Special activated.' else 'Special unavailable: check the encounter, team and cooldown.'

  elseif action=='Dodge' then

   local ok=context.combat.dodge(player)

   if ok then context.send(player,'dodge',true) end

   return ok,if ok then 'Dodge ready.' else 'Dodge is cooling down.'

  elseif action=='Equip' then

   if not R.equip(p,payload) then return false,'Choose one to three distinct owned companions.' end

   context.rebuildTeam(player);return true,'Team equipped.',{team=table.clone(p.team)}

  elseif action=='Incubate' or action=='Hatch' then

   if not context.atRefuge(player) then return false,'Use incubation on your own plot or at the refuge.' end

   local ok=if action=='Incubate' then R.incubate(p,payload,context.clock()) else R.hatch(p,payload,context.clock())

   if not ok then return false,'Not ready or all three incubators are occupied.' end

   local data=if action=='Hatch' then {creature=copyCreature(p.creatures[#p.creatures])} else {egg=table.clone(R.find(p.eggs,payload))}

   if context.save then context.save(player) end

   return true,if action=='Hatch' then 'A new companion hatched!' else 'Incubation started • hatching is free.',data

  elseif action=='Specialize' then

   if not R.specialize(p,payload.id,payload.choice) then return false,'Specialization requires an owned level 25 companion without an existing choice.' end

   context.rebuildTeam(player);return true,'Specialization selected.',{creature=copyCreature(R.find(p.creatures,payload.id))}

  elseif action=='Train' then

   if not context.atRefuge(player) then return false,'Train on your own plot or at the refuge.' end

   local c=R.find(p.creatures,payload)

   if not c then return false,'Companion unavailable.' end

   if c.level>=50 then return false,'This companion is already at maximum level.' end

   if p.coins<15 then return false,'Training requires 15 coins.' end

   local previousLevel=c.level;local previousStage=R.stage(c.level)

   p.coins-=15;R.addXP(c,80);context.rebuildTeam(player)

   return true,'Training complete • +80 XP',{creature=copyCreature(c),previousLevel=previousLevel,previousStage=previousStage,stage=R.stage(c.level),xp=80,cost=15}

  elseif action=='Travel' then

   if not context.nearCheckpoint(player) and not context.atRefuge(player) then return false,'Fast travel begins at a checkpoint or refuge.' end

   if not context.travel(player,payload) then return false,'Destination locked or unavailable.' end

   return true,'Travel complete.',{destination=payload}

  elseif action=='CollectIncome' then

   if not context.atRefuge(player) then return false,'Collect income on your own plot or at the refuge.' end

   local amount=R.settleIncome(p,context.clock());return true,'Collected '..amount..' sanctuary coins.',{coins=amount}

  elseif action=='RegisterDefense' then

   if not context.atRefuge(player) then return false,'Register a defense on your own plot or at the refuge.' end

   local ok=context.competition.register(p,player.UserId)

   return ok,if ok then 'Defense snapshot saved • others can challenge your UserId while you are offline.' else 'Defense save unavailable. Try again later.'

  elseif action=='ChallengeDefense' then

   if not context.atRefuge(player) then return false,'Challenge a defense on your own plot or at the refuge.' end

   local ok,value=context.competition.challenge(p,player.UserId,payload)

   if not ok then return false,value end

   context.send(player,'competition',value);if context.save then context.save(player) end

   return true,if value.won then 'Defense challenge won.' else 'Defense challenge complete.',value

  end

  return false,'Unknown action.'

 end

end

return U

