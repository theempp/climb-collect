local Sessions=require(script.Parent.SanctuarySessions)
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local S={}
function S.new(model)
 assert(model and model:IsA('Model'),'Use the baked sanctuary integration review')
 local allocator=Sessions.new(8)
 local plots={}
 for i=1,8 do
  local plot=assert(model.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',i)))
  local spawn=assert(plot:FindFirstChild('Spawn'))
  spawn.Enabled=false -- Main owns all character spawns, never random shared pads.
  plots[i]={model=plot,spawn=spawn,floor=assert(plot:FindFirstChild(L.floorName))}
 end
 local gates={}
 -- One grand gate at the mountain end of the promenade is the only way out to the mountain.
 do
  local g=L.gate
  local marker=Instance.new('Part');marker.Name='EnterBlossom';marker.Size=Vector3.new(5,5,1)
  marker.CFrame=CFrame.new(g.x,L.groundY+3,g.z+16);marker.Anchored=true;marker.CanCollide=false;marker.CanTouch=false;marker.Transparency=1
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Enter Blossom';prompt.ObjectText='Impossible Mountain';prompt.HoldDuration=.35;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=marker
  marker.Parent=assert(model:FindFirstChild('GrandGate'),'Promenade gate missing');gates[marker]=true
 end
 local service={}
 function service.model(index) return plots[index] and plots[index].model end
 local function slot(player) return allocator.plot(player.UserId,player) end
 function service.plot(player) return slot(player) end
 function service.spawn(player)
  local i=slot(player);return i and plots[i].spawn.CFrame+Vector3.new(0,4,0)
 end
 function service.ownsPosition(player,pos)
  local i=slot(player);if not i then return false end
  local floor=plots[i].floor;local q=floor.CFrame:PointToObjectSpace(pos)
  return math.abs(q.X)<=floor.Size.X/2-1 and math.abs(q.Z)<=floor.Size.Z/2-1 and q.Y>=0 and q.Y<=45
 end
 function service.inSanctuary(pos)
  local mountain=workspace:FindFirstChild('ImpossibleMountain')
  local north=if mountain and mountain:GetAttribute('FreeClimbVersion') then L.northZ else -1400
  return L.inSanctuary(pos.X,pos.Z,north)
 end
 function service.nearGate(pos)
  for marker in pairs(gates) do if (marker.Position-pos).Magnitude<=15 then return true end end
  return false
 end
 function service.prompt(part,player,pos)
  if gates[part] and (part.Position-pos).Magnitude<=15 then return 'Gate' end
  local i=slot(player)
  if i and part:GetAttribute('SanctuarySlot')==i and part:IsDescendantOf(plots[i].model) and (part.Position-pos).Magnitude<=15 then return part:GetAttribute('Service') end
 end
 function service.reserve(player)
  local i=allocator.reserve(player.UserId,player);if not i then return nil end
  plots[i].model:SetAttribute('OwnerUserId',player.UserId)
  player:SetAttribute('SanctuaryPlot',i)
  return i
 end
 function service.release(player)
  local i=slot(player)
  if i then plots[i].model:SetAttribute('OwnerUserId',nil) end
  allocator.release(player.UserId,player)
 end
 for i,plot in ipairs(plots) do
  for j,row in ipairs(L.contents.services) do
   local kind=row.kind
   local marker=Instance.new('Part');marker.Name=kind..'Service';marker.Size=Vector3.new(row.size,2,row.size)
   -- Intel B10: invisible prompt host above the hatchery pedestal / Beast statue (TycoonWorld builds the visible forms).
   marker.CFrame=plot.floor.CFrame*CFrame.new(row.x,plot.floor.Size.Y/2+(row.y or 1),row.z)
   marker.Anchored=true;marker.CanCollide=false;marker.CanTouch=false;marker.Transparency=1;marker.CastShadow=false
   marker:SetAttribute('SanctuarySlot',i);marker:SetAttribute('Service',kind)
   local prompt=Instance.new('ProximityPrompt');prompt.ActionText=if j==1 then 'Incubate / hatch' else 'Train companions'
   prompt.ObjectText='Your sanctuary';prompt.MaxActivationDistance=12;prompt.HoldDuration=.2;prompt.RequiresLineOfSight=false;prompt.Parent=marker
   marker.Parent=plot.model
  end
 end
 return service
end
return S
