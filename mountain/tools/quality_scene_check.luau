-- Test actual baked collision, not only generator mathematics. Safe in Edit or Server.
local w=workspace.ImpossibleMountain
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.RespectCanCollide=true
local function floorAt(region,x,z)
 rp.FilterDescendantsInstances={region}
 local hit=workspace:Raycast(Vector3.new(x,600,z),Vector3.new(0,-650,0),rp)
 return hit and hit.Position.Y
end
local results={passed=true,checks=0,failures={},catchProfile={}}
local function check(ok,label,data)
 results.checks+=1;if not ok then results.passed=false;table.insert(results.failures,{label=label,data=data}) end
end
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
for k,c in C.kingdoms do
 local region=w[c.name];local y=16+(k-1)*64;local z=-210-(k-1)*200
 for _,x in {-88,-16,0,16,88} do
  local previous
  for d=0,120,1 do
   local h=floorAt(region,4096+x,z-d)
   check(h~=nil,k..':continuous-floor',{x=x,d=d})
   if h then
    if previous then check(math.abs(h-previous)<1.15,k..':walkable-seam',{x=x,d=d,rise=h-previous}) end
    previous=h
   end
  end
 end
 local deviation=0
 for _,d in {32,56,88} do local left=floorAt(region,4008,z-d);if left then deviation=math.max(deviation,math.abs(left-(y+64*d/120))) end end
 check(deviation>2,k..':shaped-shoulder',{maximumDeviation=deviation})
 local quality=region:FindFirstChild('MountainQuality')
 if quality then
  for _,p in quality.Scenery:GetDescendants() do if p:IsA('BasePart') then
   check(p.CanCollide==(p.Name=='BoulderCore'),k..':decorative-collision',{name=p.Name,collision=p.CanCollide})
  end end
  rp.FilterDescendantsInstances={quality.WalkSurface}
  for _,x in {3920,4008,4184,4272} do
   local d=if x==3920 or x==4272 then 60 else -2
   local hit=workspace:Raycast(Vector3.new(x,600,z-d),Vector3.new(0,-650,0),rp)
   check(hit==nil,k..':surface-within-original-footprint',{x=x,z=z-d})
  end
 end
end
local previous
for z=-764,-777,-.5 do
 local h=floorAt(w[C.kingdoms[3].name],4168,z);table.insert(results.catchProfile,{z=z,y=h})
 if previous and h then check(math.abs(h-previous)<.65,'walk-only-sandstone-catch-exit',{z=z,rise=h-previous}) end
 previous=h
end
return results
