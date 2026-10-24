-- Conservative bounding-box audit of baked backdrops above the arena floor.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local world=workspace.ImpossibleMountain
local results={};local passed=true
for ki,k in ipairs(C.kingdoms) do
 local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local q=C.route(ki,.875);local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
 local frame=CFrame.lookAt(center,center-outward)
 local group=world.EnvironmentComposition[k.id]
 local result={kingdom=k.id,checked=0,minimumRadius=math.huge,violations={}}
 for _,p in ipairs(group:GetDescendants()) do
  if p:IsA('BasePart') and p.Name~='BiomeInterleave' then
   assert(not p.CanCollide and not p.CanQuery and not p.CanTouch,'Scenery became gameplay geometry')
   local cf=frame:ToObjectSpace(p.CFrame);local ext=Vector3.zero
   for _,axis in ipairs({cf.RightVector*p.Size.X/2,cf.UpVector*p.Size.Y/2,cf.LookVector*p.Size.Z/2}) do ext+=Vector3.new(math.abs(axis.X),math.abs(axis.Y),math.abs(axis.Z)) end
   if cf.Position.Y+ext.Y>.05 then
    local radius=Vector2.new(math.max(0,math.abs(cf.Position.X)-ext.X),math.max(0,math.abs(cf.Position.Z)-ext.Z)).Magnitude
    result.checked+=1;result.minimumRadius=math.min(result.minimumRadius,radius)
    if radius<44 then table.insert(result.violations,{name=p.Name,radius=radius});passed=false end
   end
  end
 end
 table.insert(results,result)
end
return {passed=passed,arenaRadius=41,clearance=3,results=results,scope='Conservative boxes of backdrop parts above arena plane; excludes route accents. Does not establish visual quality.'}
