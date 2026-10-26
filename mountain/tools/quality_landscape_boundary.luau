-- Terrain itself must not intrude on the preserved walkable footprint.
local w=workspace.ImpossibleMountain
local terrain=RaycastParams.new();terrain.FilterType=Enum.RaycastFilterType.Include;terrain.FilterDescendantsInstances={workspace.Terrain}
local parts=RaycastParams.new();parts.FilterType=Enum.RaycastFilterType.Include;parts.FilterDescendantsInstances={w};parts.RespectCanCollide=true
local r={checks=0,passed=true,failures={},edges={}}
for k=1,6 do
 local y=16+(k-1)*64;local z=-210-(k-1)*200
 for _,side in {-1,1} do for d=4,196,4 do
  local x=4096+side*168
  local p=Vector3.new(x,y+90,z-d)
  local ground=workspace:Raycast(p,Vector3.new(0,-160,0),parts)
  local t=workspace:Raycast(p,Vector3.new(0,-160,0),terrain)
  local ok=ground~=nil and (t==nil or t.Position.Y<=ground.Position.Y+.05)
  r.checks+=1;r.passed=r.passed and ok
  if not ok then table.insert(r.failures,{section=k,side=side,d=d,part=ground and ground.Position.Y,terrain=t and t.Position.Y}) end
  if d==80 or d==160 then
   local outer=workspace:Raycast(Vector3.new(4096+side*180,900,z-d),Vector3.new(0,-1000,0),terrain)
   table.insert(r.edges,{section=k,side=side,d=d,route=ground and ground.Position.Y,outerTerrain=outer and outer.Position.Y})
  end
 end end
end
-- Summit edge, inside the existing final terrace. The backdrop starts behind it.
for x=3932,4260,8 do
 local p=Vector3.new(x,500,-1406)
 local ground=workspace:Raycast(p,Vector3.new(0,-200,0),parts)
 local t=workspace:Raycast(p,Vector3.new(0,-200,0),terrain)
 local ok=ground~=nil and (t==nil or t.Position.Y<=ground.Position.Y+.05)
 r.checks+=1;r.passed=r.passed and ok
 if not ok then table.insert(r.failures,{summitX=x,part=ground and ground.Position.Y,terrain=t and t.Position.Y}) end
end
return r
