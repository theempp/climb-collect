-- Stable service contract. A malformed new lobby must fail loudly, never silently use the old site.
local A={required={'Spawn','Bank','Return','HomeDoor','PracticeStart','Collection','RouteBoard','Exchange_Bundle','Exchange_Flag','Exchange_Trail','Exchange_Next','Exchange_Coins'}}
function A.resolve(world)
 world=world or workspace:FindFirstChild('World')
 assert(world,'LobbyAnchors: World missing')
 local f=world:FindFirstChild('Fairground')
 if f then
  local folder=f:FindFirstChild('Anchors');assert(folder,'LobbyAnchors: Anchors missing')
  local result={}
  for _,id in A.required do
   local found
   for _,p in folder:GetChildren() do if p:GetAttribute('ServiceId')==id then assert(not found,'LobbyAnchors: duplicate '..id);found=p end end
   assert(found and found:IsA('BasePart'),'LobbyAnchors: missing '..id)
   result[id]=found
  end
  return result
 end
 local foothold=world.Regions.Foothold
 local market=foothold.Districts.ProvisionsMarket
 local stalls={} for _,v in market:GetChildren() do if v.Name=='MarketStall' then table.insert(stalls,v) end end
 table.sort(stalls,function(a,b) return a:GetPivot().Position.Z<b:GetPivot().Position.Z end)
 local bank=foothold.Core.Campfire.Core
 local cabin=foothold:FindFirstChild('Cabins',true):GetChildren()[1]
 local sp=workspace:FindFirstChildOfClass('SpawnLocation')
 return {Spawn=sp,Bank=bank,Return=sp,HomeDoor=cabin:FindFirstChild('HomePortalStation') or cabin:FindFirstChildWhichIsA('BasePart',true),PracticeStart=world.TrainingYard.StartGate,Collection=bank,RouteBoard=foothold.Core.RouteBoard:FindFirstChildWhichIsA('BasePart',true),Exchange_Bundle=stalls[1]:FindFirstChildWhichIsA('BasePart',true),Exchange_Flag=stalls[2]:FindFirstChildWhichIsA('BasePart',true),Exchange_Trail=stalls[3]:FindFirstChildWhichIsA('BasePart',true),Exchange_Next=bank,Exchange_Coins=bank}
end
function A.contains(position,world)
 world=world or workspace:FindFirstChild('World')
 local f=world and world:FindFirstChild('Fairground')
 if not f then return false end
 local b=f:FindFirstChild('SafeBounds');assert(b,'LobbyAnchors: SafeBounds missing')
 local p=b.CFrame:PointToObjectSpace(position);local h=b.Size/2
 return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z
end
return A
