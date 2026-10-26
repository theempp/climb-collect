-- Independent coverage requirement: terrain shoulders continue above every section.
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.Terrain}
local r={passed=true,checks=0,failures={},samples={}}
for k=1,6 do
 for _,side in {-1,1} do for _,d in {40,100,160} do
  local x=4096+side*280;local z=-210-(k-1)*200-d
  local hit=workspace:Raycast(Vector3.new(x,900,z),Vector3.new(0,-1000,0),rp)
  local expected=16+(k-1)*64+64*math.min(d/120,1)+20
  local ok=hit~=nil and hit.Position.Y>=expected
  r.checks+=1;r.passed=r.passed and ok
  local row={section=k,side=side,d=d,height=hit and hit.Position.Y or -999,minimum=expected}
  table.insert(r.samples,row);if not ok then table.insert(r.failures,row) end
 end end
end
for _,x in {3896,4096,4296} do
 local hit=workspace:Raycast(Vector3.new(x,900,-1540),Vector3.new(0,-1000,0),rp)
 local ok=hit~=nil and hit.Position.Y>440;r.checks+=1;r.passed=r.passed and ok
 if not ok then table.insert(r.failures,{summitX=x,height=hit and hit.Position.Y or -999}) end
end
return r
