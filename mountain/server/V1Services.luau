-- v1 services orchestrator: dailies (C07), receipts (E02), duo party (C01-C02), outposts/raids (C03-C04),
-- seasons/recognition (C05-C06). Server/shared logic only; the HUD reads design/v1-services-ui-contract.md.
-- deps: profiles, clock, notify(player,kind,data), playerByUserId(id), outposts {store,index}, receipts {products,
--       checkoutEnabled,prompt,ownsPass}, party {travel,follow,isFriend,directory?,teleport?,jobId,seed?},
--       isFriend(a,b), friends(userId), productionRate(p), teamXP(player,n), badge(player,key)?, leaderboard?, guid()
local Shared=if script then game.ReplicatedStorage.MountainShared else nil
local function need(name) return if Shared then require(Shared[name]) else require('../shared/'..name) end
local Dailies=need('Dailies')
local Wallet=need('V1Wallet')
local Products=need('V1Products')
local Recognition=need('Recognition')
local Config=need('V1Config')
local Receipts=if script then require(script.Parent.Receipts) else require('./Receipts')
local PartyService=if script then require(script.Parent.PartyService) else require('./PartyService')
local OutpostService=if script then require(script.Parent.OutpostService) else require('./OutpostService')
local V={}
local function copy(t) if type(t)~='table' then return t end local c={};for k,v in pairs(t) do c[k]=copy(v) end;return c end
-- Guardian/Trial duo scaling (C02): health multiplier by encounter size (1-2 players). PROPOSED values.
function V.duoHealth(trial,members)
 local list=if trial then Config.duo.trialHealth else Config.duo.guardianHealth
 return list[math.clamp(members,1,#list)]
end
function V.new(deps)
 local P=deps.profiles
 local service={}
 local lastDay={}
 local function notify(player,kind,data) if deps.notify then deps.notify(player,kind,data) end end
 local receipts=Receipts.new({profiles=P,products=deps.products or Products,playerByUserId=deps.playerByUserId,clock=deps.clock,
  checkoutEnabled=deps.receipts.checkoutEnabled,prompt=deps.receipts.prompt,ownsPass=deps.receipts.ownsPass,notify=notify})
 local party=PartyService.new({clock=deps.clock,player=deps.playerByUserId,travel=deps.party.travel,follow=deps.party.follow,notify=notify,
  isFriend=deps.isFriend,directory=deps.party.directory,teleport=deps.party.teleport,jobId=deps.party.jobId,seed=deps.party.seed,
  track=function(player,event,n) service.track(player,event,n) end})
 local outposts=OutpostService.new({store=deps.outposts.store,index=deps.outposts.index,profiles=P,clock=deps.clock,guid=deps.guid,notify=notify,
  playerByUserId=deps.playerByUserId,productionRate=deps.productionRate,teamXP=deps.teamXP,isFriend=deps.isFriend,friends=deps.friends,
  leaderboard=deps.leaderboard,badge=deps.badge,track=function(player,event,n) service.track(player,event,n) end})
 service.receipts,service.party,service.outposts=receipts,party,outposts
 local function wallet(p)
  local v=p.v1
  return {eggTickets=v.eggTickets,tokens=copy(v.tokens),boosts=copy(v.boosts),cosmetics=copy(v.cosmetics),titles=copy(v.titles),badges=copy(v.badges),title=v.title,passes=copy(v.passes)}
 end
 local function shop(player)
  local items={}
  for _,item in ipairs((deps.products or Products).list) do
   table.insert(items,{key=item.key,kind=item.kind,price=item.price,grant=copy(item.grant),state=receipts.state(player,item.key)})
  end
  return {checkoutEnabled=deps.receipts.checkoutEnabled(),items=items}
 end
 -- Rolls the UTC day for an online player: refresh quests, count the login (hard streak), earn titles.
 local function daily(player)
  local p=P.get(player);if not p then return false end
  local now=deps.clock()
  local changed=Dailies.refresh(p.v1.daily,player.UserId,now)
  changed=Dailies.login(p.v1.daily,now) or changed
  for _,id in ipairs(Recognition.earned(p)) do p.v1.titles[id]=true;changed=true end
  for _,key in ipairs(Recognition.badgesEarned(p)) do p.v1.badges[key]=true;changed=true;if deps.badge then pcall(deps.badge,player,key) end end
  lastDay[player]=Config.dayIndex(now)
  return changed
 end
 function service.state(player)
  local p=P.get(player);if not p then return nil end
  daily(player)
  return {daily=Dailies.view(p.v1.daily,deps.clock()),wallet=wallet(p),shop=shop(player),party=party.state(player),
   raid={attacks=p.v1.raid.attacks,loot=p.v1.raid.loot,friendlyWins=p.v1.raid.friendlyWins,friendlyPlayed=p.v1.raid.friendlyPlayed},serverNow=deps.clock()}
 end
 function service.join(player,teleportData)
  local p=P.get(player);if not p then return false end
  daily(player)
  receipts.syncPasses(player)
  outposts.ensure(player)
  if teleportData then party.arrived(player,teleportData) end
  notify(player,'v1_state',service.state(player))
  return true
 end
 -- Server-only progress. Never reachable from a client payload.
 function service.track(player,event,amount)
  local p=P.get(player);if not p then return {} end
  local advanced=Dailies.track(p.v1.daily,player.UserId,event,amount or 1,deps.clock())
  if #advanced>0 then notify(player,'daily',Dailies.view(p.v1.daily,deps.clock())) end
  return advanced
 end
 -- EggRaids presentation events (strike / safe) feed quests without changing custody code.
 function service.observe(player,data)
  if type(data)~='table' then return end
  if data.kind=='strike' then service.track(player,'strike',1)
  elseif data.kind=='safe' then service.track(player,'secure',1) end
 end
 -- Successful legacy UI actions advance home quests (Main passes the dispatcher result; server-side only).
 function service.afterAction(player,action,payload,coinsBefore)
  local p=P.get(player);if not p then return end
  if action=='Hatch' then service.track(player,'hatch',1)
  elseif action=='Incubate' then service.track(player,'incubate',1)
  elseif action=='Tycoon' and type(payload)=='table' then
   if payload.op=='upgrade' then service.track(player,'upgrade',1)
   elseif payload.op=='bank' and type(coinsBefore)=='number' and p.coins>coinsBefore then service.track(player,'bank',math.floor(p.coins-coinsBefore)) end
  end
 end
 local function claim(player,id,fn)
  local granted
  local ok,reason=P.transact(player,'daily:'..id,function(d)
   local reward,why=fn(d)
   if not reward then return false,why end
   granted=Wallet.grant(d,reward,deps.clock())
   if not granted then return false,'invalid_reward' end
   return true,'claimed'
  end)
  return ok,if ok then 'claimed' else reason,granted
 end
 local handlers={}
 handlers.V1_State=function(player) return true,'ok',service.state(player) end
 handlers.Daily_ClaimLogin=function(player)
  local p=P.get(player);local now=deps.clock();daily(player)
  local probe=copy(p.v1.daily);local reward,id=Dailies.claimLogin(probe,now)
  if not reward then return false,id end
  local ok,msg,got=claim(player,id,function(d) return Dailies.claimLogin(d.v1.daily,now) end)
  return ok,msg,{granted=got,daily=Dailies.view(P.get(player) and P.get(player).v1.daily or probe,now)}
 end
 handlers.Daily_Claim=function(player,payload)
  local p=P.get(player);local now=deps.clock();daily(player)
  local probe=copy(p.v1.daily);local reward,id=Dailies.claim(probe,player.UserId,payload.slot,now)
  if not reward then return false,id end
  local ok,msg,got=claim(player,id,function(d) return Dailies.claim(d.v1.daily,player.UserId,payload.slot,now) end)
  return ok,msg,{granted=got,daily=Dailies.view(P.get(player) and P.get(player).v1.daily or probe,now)}
 end
 handlers.Daily_Reroll=function(player,payload)
  local p=P.get(player);local now=deps.clock();daily(player)
  local ok,why=Dailies.reroll(p.v1.daily,player.UserId,payload.slot,now)
  return ok,if ok then 'rerolled' else why,{daily=Dailies.view(p.v1.daily,now)}
 end
 handlers.Shop_State=function(player) return true,'ok',shop(player) end
 handlers.Shop_Prompt=function(player,payload) local ok,state=receipts.prompt(player,payload.key);return ok,state,{key=payload.key,state=receipts.state(player,payload.key)} end
 handlers.Party=function(player,payload) local ok,msg=party.request(player,payload.op,payload);return ok,if type(msg)=='string' then msg else 'ok',party.state(player) end
 handlers.Outpost_State=function(player) local ok,view=outposts.state(player);return ok,if ok then 'ok' else view,if ok then view else nil end
 handlers.Outpost_SetSlot=function(player,payload) local ok,r=outposts.setSlot(player,payload.slot,payload.piece);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Outpost_SetDefenders=function(player,payload) local ok,r=outposts.setDefenders(player,payload.ids);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Outpost_Collect=function(player) local ok,r=outposts.collect(player);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Outpost_Shield=function(player) local ok,r=outposts.shield(player);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Find=function(player,payload) local ok,r=outposts.find(player,{revenge=payload and payload.revenge});return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Reroll=function(player) local ok,r=outposts.reroll(player);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Start=function(player,payload) local ok,r=outposts.start(player,payload.offerId);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Submit=function(player,payload) local ok,r=outposts.submit(player,payload.attackId,payload);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Abandon=function(player) local ok,r=outposts.abandon(player);return ok,if ok then 'ok' else r end
 handlers.Raid_Log=function(player) local ok,r=outposts.log(player);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Practice=function(player,payload) local ok,r=outposts.practice(player,payload);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Raid_Friendly=function(player,payload) local ok,r=outposts.friendly(player,payload.userId,payload);return ok,if ok then 'ok' else r,if ok then r else nil end
 handlers.Season_State=function(player)
  local ok,view=outposts.state(player);local p=P.get(player)
  if not ok or not p then return false,'unavailable' end
  return true,'ok',{season=view.season,gallery=Recognition.gallery(p,view.season.history)}
 end
 handlers.Title_Equip=function(player,payload)
  local p=P.get(player);local ok,why=Recognition.equip(p.v1,payload.id)
  return ok,if ok then 'ok' else why,{title=p.v1.title}
 end
 -- payload already passed V1Protocol.validate; profile availability is checked here.
 function service.handle(player,action,payload)
  if not P.get(player) then return false,'unavailable' end
  local h=handlers[action];if not h then return false,'unknown_action' end
  return h(player,payload)
 end
 function service.processReceipt(info) return receipts.process(info) end
 function service.tick()
  party.tick()
  local today=Config.dayIndex(deps.clock())
  for player,day in pairs(lastDay) do
   if day~=today and P.get(player) and daily(player) then notify(player,'daily',Dailies.view(P.get(player).v1.daily,deps.clock())) end
  end
 end
 function service.remove(player)
  party.remove(player);outposts.remove(player);receipts.remove(player);lastDay[player]=nil
 end
 service.duoHealth=V.duoHealth
 return service
end
return V
