-- The client sends intent only; the server chooses and reapplies speed.
local R=require(game.ReplicatedStorage.MountainShared.MovementRules)
local M={}
function M.new(remote,clock)
 clock=clock or os.clock
 local states={}
 local service={}
 function service.update(player)
  local s=states[player];local c=player.Character
  local h=c and c:FindFirstChildOfClass('Humanoid')
  if not s or not h then return end
  local active=R.active(s.wanted,h.Health,h.Sit,h.PlatformStand)
  if h.Health<=0 then s.wanted=false end
  h.WalkSpeed=R.speed(active,c:GetAttribute('CarryingCreature')==true)
  if c:GetAttribute('Sprinting')~=active then c:SetAttribute('Sprinting',active) end
 end
 function service.clear(player)
  local s=states[player]
  if s then for _,c in ipairs(s.connections) do c:Disconnect() end end
  states[player]=nil
 end
 function service.bind(player,character)
  service.clear(player)
  local s={wanted=false,lastPress=-math.huge,connections={}};states[player]=s
  local h=character:FindFirstChildOfClass('Humanoid')
  table.insert(s.connections,character:GetAttributeChangedSignal('CarryingCreature'):Connect(function() service.update(player) end))
  if h then table.insert(s.connections,h.Died:Connect(function() s.wanted=false;service.update(player) end)) end
  service.update(player)
 end
 function service.request(player,value)
  local s=states[player];if not s then return false end
  local now=clock()
  -- Never drop a changed intent: the client sends transitions, not a heartbeat.
  if type(value)~='boolean' or (value==s.wanted and not R.intent(value,now,s.lastPress)) then return false end
  if value then s.lastPress=now end
  s.wanted=value;service.update(player);return true
 end
 remote.OnServerEvent:Connect(service.request)
 return service
end
return M
