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

 local monotonic=context.monotonic or os.clock

 local buyAt=setmetatable({},{__mode='k'})
 local inspectAt=setmetatable({},{__mode='k'})

 -- C12: Buy and Skin only in the sanctuary, empty-handed, out of battle and with nothing saving (a pending draft freezes P.get).
 local function shopRefusal(player,p)
  if P.pending and P.pending(player) then return 'Saving in progress. Try again shortly.' end
  if p.run then return 'Finish your current creature run first.' end
  if not context.inBattle or context.inBattle(player) then return 'Finish your fight before shopping.' end
  if not context.inSanctuary or not context.inSanctuary(player) then return 'Shop from your sanctuary.' end
  return nil
 end

 return function(player,action,payload)

  local p=P.get(player)

  if not p then return false,'Profile or saving unavailable.' end

  if action=='State' then context.publish(player);return true,'State refreshed.' end

  if action=='Settings' then

   local ok,settings=P.setSettings(player,payload)

   return ok,if ok then 'Settings saved.' else 'Settings save unavailable.',if ok then {settings=settings} else nil

  end

  if action=='Bat' then
   local Bat=context.batRules;if not Bat then return false,'Bats are unavailable.' end
   local ok,detail
   if payload.op=='equip' then ok=Bat.equip(p,payload.id) else ok,detail=Bat.upgrade(p,payload.id) end
   if ok then if context.equipBat then context.equipBat(player) end;if context.save then context.save(player) end end
   local message=if ok then (if payload.op=='equip' then 'Bat equipped.' else 'Bat upgraded.') elseif detail=='coins' then 'Not enough coins for this upgrade.' elseif detail=='max' then 'This bat is at maximum level.' elseif detail=='not_equipped' then 'Equip this bat to upgrade it.' else 'Complete the section index set to unlock this bat.'
   return ok==true,message,{bats=context.batSnapshot and context.batSnapshot(p)}
  end
  if not context.safe(player) then return false,'Wait until your character is ready and movement is safe.' end
  if action=='Buy' or action=='Skin' then
   local refused=shopRefusal(player,p);if refused then return false,refused end
   local Shop=context.shop
   -- C16: equip or clear an owned bat skin (looks only); the held bat is rebuilt and the choice saved, like Bat equip.
   if action=='Skin' then
    if not Shop then return false,'Bat skins are unavailable.' end
    local before=Shop.cosmetics(p).batSkin
    local ok=Shop.skin(p,payload.op,payload.id)
    -- A no-op (clear with nothing equipped, equip of the equipped skin) neither rebuilds nor saves.
    if ok and Shop.cosmetics(p).batSkin~=before then if context.equipBat then context.equipBat(player) end;if context.save then context.save(player) end end
    return ok==true,if ok then (if payload.op=='equip' then 'Bat skin equipped.' else 'Bat skin cleared.') else 'Buy this skin first.',{cosmetics=Shop.cosmetics(p)}
   end
   if not Shop or not P.transact then return false,'The shop is unavailable.' end
   -- C14: a 2 s cooldown, then a receipt already in the live profile is answered without a write.
   local now=monotonic();if now<(buyAt[player] or -math.huge) then return false,'Please wait a moment before buying again.' end;buyAt[player]=now+Shop.cooldown
   local receipt=payload.receipt
   if Shop.has(p,receipt) then return true,'Purchase already complete.',{receipt=receipt} end
   local skin=Shop.isSkin(payload.item)
   local r=if skin then nil elseif context.rollOdds then context.rollOdds() else math.random()*100;local granted
   -- The mutate runs once per pending draft; a failed commit stays pending (P.get is nil) until autosave or release commits it.
   local ok,reason=P.transact(player,'buy:'..receipt,function(draft) local done,why,item=Shop.buy(draft,payload.item,receipt,r);granted=item;return done,why end)
   -- A commit refreshes the live profile in place, so p already holds the new skin.
   if ok and skin then return true,'Bat skin added. Equip it from Bats.',{receipt=receipt,skin=payload.item,cosmetics=Shop.cosmetics(p)} end
   if ok or reason=='duplicate' then return true,if ok then 'Egg added to your collection.' else 'Purchase already complete.',{receipt=receipt,egg=if ok and granted then table.clone(granted) else nil} end
   local messages={coins='Not enough coins for this item.',egg_cap='Egg storage is full (24). Hatch an egg first.',unavailable='This item is not on sale yet.',unknown='Unknown shop item.',owned='You already own this skin.',
    busy='Purchase is saving. It appears once saving resumes.',save_pending='Purchase is saving. It appears once saving resumes.'}
   return false,messages[reason] or 'Purchase unavailable. No coins were spent.'
  end
  -- Home-base P2: tier and decor writes are durable before the reply (P.transact); the client effect waits for ok.
  if action=='Home' then
   local Home=context.home;if not Home or not P.transact or not context.guid then return false,'Home upgrades are unavailable.' end
   if not context.atHome or not context.atHome(player) then return false,'Use your own sanctuary plot.' end
   if P.pending and P.pending(player) then return false,'Saving in progress. Try again shortly.' end
   if p.run then return false,'Finish your current creature run first.' end
   local bought=false
   local ok,reason=P.transact(player,'home:'..context.guid(),function(draft)
    local done,why
    if payload.op=='tier' then done,why=Home.raise(draft)
    elseif payload.op=='place' then done,why,bought=Home.place(draft,payload.slot,payload.kind,payload.id)
    else done,why=Home.clear(draft,payload.slot) end
    return done,why
   end)
   if ok then
    if context.homeChanged then context.homeChanged(player,payload.op) end
    context.publish(player)
    local done={tier='Plot raised to '..Home.tiers.tiers[Home.tier(p)].name..'.',place=if bought then 'Bought and placed.' else 'Placed on display.',clear='Display cleared.'}
    return true,done[payload.op],{home=Home.snapshot(p)}
   end
   local messages={max='Your plot is at the top tier.',rank='Reach a higher rank to raise your plot.',coins='Not enough coins.',slot='Unknown display slot.',
    locked='Raise your plot to use this slot.',occupied='Clear this slot first.',owned='Choose a creature you own.',habitat='Take this creature out of its habitat first.',
    displayed='This creature is already on display.',unknown='Unknown decoration.',tier='Raise your plot to buy this decoration.',kind='Unknown decoration.',
    empty='This slot is already empty.',stock='Your storage for this decoration is full.',busy='Saving in progress. Try again shortly.',save_pending='Saving in progress. Try again shortly.'}
   return false,(messages[reason] or 'Home action unavailable. No coins were spent.'),{home=Home.snapshot(p)}
  end
  -- Any player, read-only: one displayed creature (or prop) on a plot, never inventory or coins.
  if action=='Inspect' then
   local Home=context.home;if not Home or not context.plotProfile then return false,'Inspect is unavailable.' end
   if not context.inSanctuary or not context.inSanctuary(player) then return false,'Visit the sanctuary to look closer.' end
   local now=monotonic();if now<(inspectAt[player] or -math.huge) then return false,'Please wait a moment.' end;inspectAt[player]=now+.5
   local owner,profile=context.plotProfile(payload.plot)
   local view=profile and Home.inspect(profile,payload.kind,payload.index)
   if not view then return false,if profile then 'Nothing on display there.' else 'Nobody is home on that plot.' end
   view.owner=owner;return true,'Inspect.',{inspect=view}
  end
  if action=='Swing' then
   if not context.bats then return false,'Bats are unavailable.' end
   local _,result=context.bats.swing(player)
   local messages={safe_zone='No bat hits in the sanctuary or at rest points.',protected='That climber is securing a creature.',same_victim='Give that climber a moment before swinging again.',hands_full='Both arms are carrying your creature.'}
   return result=='hit' or result=='miss',messages[result],{result=result}
  end

  if action=='Strike' or action=='Pickup' or action=='PutDown' then
   if not context.raids then return false,'Mountain discovery is unavailable.' end
   local ok,reason
   if action=='Strike' then ok,reason=context.raids.strike(player,payload)
   elseif action=='Pickup' then ok,reason=context.raids.pickup(player,payload)
   elseif context.atHome(player) and not p.run then context.putDown(player);ok=true end
   local messages={reserved='Another climber is breaking this egg.',full_hands='Finish your current creature run first.',too_far='Move closer to the egg.',cadence='Tap again after the pickaxe strike.',egg_resting='This egg is resting. Try another.',finish_battle='Finish your fight before breaking an egg.'}
   return ok==true,if ok then (if action=='Strike' then 'Strike landed.' elseif action=='Pickup' then 'Carry your creature downhill to sanctuary.' else 'Creature safely in your collection.') else messages[reason] or 'That action is unavailable.'
  end
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
   elseif request.op=='upgrade' then
    ok=T.upgrade(p,request.path,request.slot,context.clock());local q=not ok and T.quote(p,request.path,request.slot)
    message=if ok then 'Upgrade installed.' elseif q and q.tier then q.requirement..' to upgrade further.' else 'Check coins, prerequisites and maximum level.'
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

  elseif action=='Travel' or action=='TravelAbandon' then

   if not context.nearCheckpoint(player) and not context.atRefuge(player) then return false,'Fast travel begins at a checkpoint or refuge.' end

   local destination=if action=='TravelAbandon' then payload.destination else payload
   local ok,reason,runId=context.travel(player,destination,if action=='TravelAbandon' then payload.runId else nil)
   if not ok then
    if reason=='abandon_confirmation_required' then return false,'Travel abandons your unsecured creature.',{confirmAbandon=true,destination=destination,runId=runId} end
    return false,'Destination or travel unavailable.'
   end

   return true,'Travel complete.',{destination=payload}

  elseif action=='CollectIncome' then

   if not context.atRefuge(player) then return false,'Collect income on your own plot or at the refuge.' end

   local amount=R.settleIncome(p,context.clock());return true,'Collected '..amount..' sanctuary coins.',{coins=amount}

  end

  return false,'Unknown action.'

 end

end

return U

