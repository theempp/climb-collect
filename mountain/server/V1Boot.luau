-- Roblox adapters for v1 services: remotes, receipts callback, stores, friends, badges, party directory.
-- Main.server.luau calls V1Boot.start(context) once. Remote names are new and V1_-prefixed; no existing
-- remote, action or profile field is renamed. Live-only adapters (DataStore, OrderedDataStore, MemoryStore,
-- TeleportService, BadgeService) are UNVERIFIED until a hosted test; Studio uses memory stores.
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
local RS=game:GetService('ReplicatedStorage')
local Store=require(script.Parent.Store)
local UIRequests=require(script.Parent.UIRequests)
local V1Services=require(script.Parent.V1Services)
local V1Protocol=require(RS.MountainShared.V1Protocol)
local V1Config=require(RS.MountainShared.V1Config)
local V1Products=require(RS.MountainShared.V1Products)
local Recognition=require(RS.MountainShared.Recognition)
local Boot={}
function Boot.start(ctx)
 local studio=RunService:IsStudio()
 local remotes=ctx.remotes
 local function remote(name) local r=Instance.new('RemoteEvent');r.Name=name;r.Parent=remotes;return r end
 local v1Request,v1Result,v1Event=remote('V1_Request'),remote('V1_Result'),remote('V1_Event')
 local function notify(player,kind,data) if player.Parent==Players then v1Event:FireClient(player,kind,data) end end
 local friendCache={}
 local function friends(userId)
  local cached=friendCache[userId];if cached and cached.at>os.clock()-300 then return cached.list end
  local list={}
  local ok,pages=pcall(Players.GetFriendsAsync,Players,userId)
  if ok then
   for _=1,4 do
    for _,f in ipairs(pages:GetCurrentPage()) do table.insert(list,f.Id) end
    if pages.IsFinished then break end
    if not pcall(pages.AdvanceToNextPageAsync,pages) then break end
   end
  end
  friendCache[userId]={at=os.clock(),list=list};return list
 end
 local function isFriend(a,b) return table.find(friends(a),b)~=nil end
 local function productionRate(p)
  local t=p.tycoon;if not t then return 0 end
  local total=0
  for i=1,t.slots do local h=t.habitats[i];if h and h.creature then local rate,value=ctx.rules.tycoon.rate(p,i);total+=rate*value end end
  return total
 end
 local directory,teleport,leaderboard=nil,nil,nil
 if not studio then
  local okM,map=pcall(function() return game:GetService('MemoryStoreService'):GetSortedMap('V1_PartyCodes') end)
  if okM then directory={
   publish=function(code,data) map:SetAsync(code,data,1800) end,
   lookup=function(code) return map:GetAsync(code) end,
   remove=function(code) map:RemoveAsync(code) end} end
  teleport=function(player,jobId,data)
   local options=Instance.new('TeleportOptions');options.ServerInstanceId=jobId;options:SetTeleportData(data)
   local ok,err=pcall(game:GetService('TeleportService').TeleportAsync,game:GetService('TeleportService'),game.PlaceId,{player},options)
   return ok,if ok then nil else tostring(err)
  end
  leaderboard={set=function(season,userId,trophies)
   local ds=game:GetService('DataStoreService'):GetOrderedDataStore('V1_Rank_'..season);ds:SetAsync(tostring(userId),trophies)
  end}
 end
 local MarketplaceService=game:GetService('MarketplaceService')
 local v1=V1Services.new({profiles=ctx.profiles,clock=os.time,notify=notify,playerByUserId=function(id) return Players:GetPlayerByUserId(id) end,
  outposts={store=Store.default('MountainEmpire_Outposts_v1'),index=Store.default('MountainEmpire_OutpostIndex_v1')},
  receipts={checkoutEnabled=function() return V1Config.checkoutEnabled end,
   prompt=function(player,item)
    if not V1Config.checkoutEnabled or item.id==0 then return end -- defensive: never prompt an unconfigured product
    if item.kind=='pass' then MarketplaceService:PromptGamePassPurchase(player,item.id) else MarketplaceService:PromptProductPurchase(player,item.id) end
   end,
   ownsPass=function(userId,passId) return pcall(MarketplaceService.UserOwnsGamePassAsync,MarketplaceService,userId,passId) end},
  party={travel=ctx.partyTravel,follow=ctx.partyFollow,directory=directory,teleport=teleport,jobId=game.JobId,seed=os.time()},
  isFriend=isFriend,friends=friends,productionRate=productionRate,teamXP=ctx.teamXP,leaderboard=leaderboard,
  badge=function(player,key)
   local badge=Recognition.byBadge[key]
   if badge and badge.robloxId~=0 then pcall(game:GetService('BadgeService').AwardBadge,game:GetService('BadgeService'),player.UserId,badge.robloxId) end
  end,
  guid=function() return Http:GenerateGUID(false) end})
 -- ProcessReceipt has exactly one owner: v1 receipts. Coin purchases (HUD chat D7) must not set it.
 MarketplaceService.ProcessReceipt=function(info) return Enum.ProductPurchaseDecision[v1.processReceipt(info)] end
 MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId,productId)
  local player=Players:GetPlayerByUserId(userId);if not player then return end
  for _,item in ipairs(V1Products.list) do if item.id==productId and item.id~=0 then v1.receipts.promptFinished(player,item.key) end end
 end)
 MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId)
  for _,item in ipairs(V1Products.list) do if item.id==passId and item.id~=0 then v1.receipts.promptFinished(player,item.key) end end
  task.spawn(v1.receipts.syncPasses,player) -- re-verified on the server; the client flag is ignored
 end)
 ctx.combat.onWin=function(player,k,trial) v1.track(player,'guardian_win',1) end
 local processor=UIRequests.new({handle=function(player,action,payload) return v1.handle(player,action,payload) end,validate=V1Protocol.validate,
  available=function(player) return ctx.profiles.get(player)~=nil and ctx.profiles.get(player)~=false end,
  failed=function(err) warn('v1 request failed: '..tostring(err)) end})
 v1Request.OnServerEvent:Connect(function(player,id,action,payload)
  local result=processor.process(player,id,action,payload)
  if result and player.Parent==Players then v1Result:FireClient(player,result) end
 end)
 task.spawn(function()
  while task.wait(1) do
   local ok,err=pcall(v1.tick);if not ok then warn('v1 tick failed: '..tostring(err)) end
   v1.party.sweep(function(userId) local player=Players:GetPlayerByUserId(userId);return player==nil or ctx.areas[player]=='sanctuary' end)
  end
 end)
 local service={}
 function service.join(player,teleportData) local ok,err=pcall(v1.join,player,teleportData);if not ok then warn('v1 join failed: '..tostring(err)) end end
 function service.remove(player) pcall(v1.remove,player);processor.remove(player);friendCache[player.UserId]=nil end
 service.observe=v1.observe;service.track=v1.track;service.afterAction=v1.afterAction;service.duoHealth=V1Services.duoHealth;service.v1=v1
 -- Players whose profile loaded before boot finished (Studio start) still get their v1 join.
 for _,player in ipairs(Players:GetPlayers()) do if ctx.profiles.get(player) then task.spawn(service.join,player,nil) end end
 return service
end
return Boot
