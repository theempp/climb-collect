-- LiveOps: server bootstrap for LiveConfig (DataStore key + 60 s poll + MessagingService nudge) and the
-- shared Analytics instance. One singleton; Main/UIRequests call LiveOps.event/economy, never AnalyticsService.
-- PlaceId 0 (Studio file) uses code defaults and never touches DataStores. Every call is safe to fail.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Analytics=require(RS.MountainShared.Analytics)
local LiveConfig=require(RS.MountainShared.LiveConfig)

local L={}
L.STORE,L.KEY,L.TOPIC,L.POLL='CC_LiveConfig','config','CC_LiveConfig',60

local live=game.PlaceId~=0
local store=live and game:GetService('DataStoreService'):GetDataStore(L.STORE) or nil
local function warnf(msg) warn('[LiveOps] '..msg) end

L.config=LiveConfig.new({warn=warnf,fetch=function()
 if not store then return {version=0,values={}} end
 return store:GetAsync(L.KEY)
end})
L.analytics=Analytics.new({service=game:GetService('AnalyticsService'),ccu=function() return #Players:GetPlayers() end,
 build=RS:GetAttribute('BuildVersion') or 'dev',warn=warnf})

-- Clients read flags + banner (no tunables) from ReplicatedStorage.LiveFlags attributes.
local flags=RS:FindFirstChild('LiveFlags') or Instance.new('Folder');flags.Name='LiveFlags';flags.Parent=RS
local function mirror() for k,v in L.config.publicView() do flags:SetAttribute(k,v) end end

local areas={}
function L.area(player,area)
 if areas[player]==area then return end
 areas[player]=area;L.event(player,'area_enter',{area=area})
end
function L.event(player,name,fields,value)
 fields=fields or {};if fields.area==nil then fields.area=areas[player] end
 return L.analytics.custom(player,name,value,fields)
end
-- flow 'source' | 'sink'; transaction from Analytics.TRANSACTIONS.
function L.economy(player,flow,amount,ending,transaction,sku)
 if amount<=0 then return false end
 local ft=if flow=='source' then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
 return L.analytics.economy(player,ft,'Coins',amount,ending,transaction,sku,{area=areas[player]})
end
-- Logs egg_lost only while the player carries an unsecured run (call before the cargo is dropped).
function L.lost(player,cause)
 local ok,p=pcall(function() return require(script.Parent.Profiles).get(player) end)
 if ok and p and p.run then L.event(player,'egg_lost',{context=cause}) end
end
function L.flag(key) return L.config.get(key) end

local started=false
function L.start()
 if started then return end;started=true
 L.config.onChanged(function(k) local any=Players:GetPlayers()[1];if any then L.event(any,'flag_changed',{context=if k:match('^shop') then 'shop' else 'other'}) end end)
 L.config.refresh();mirror()
 if live then
  task.spawn(pcall,function()
   game:GetService('MessagingService'):SubscribeAsync(L.TOPIC,function() if L.config.refresh()=='applied' then mirror() end end)
  end)
 end
 task.spawn(function()
  while true do
   task.wait(L.POLL)
   if live and L.config.refresh()=='applied' then mirror() end
   local any=Players:GetPlayers()[1];if any then L.analytics.flush(any) end
  end
 end)
 Players.PlayerRemoving:Connect(function(player) task.defer(function() areas[player]=nil end) end)
end

return L
