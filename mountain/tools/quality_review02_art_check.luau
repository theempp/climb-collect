-- Real scene contract: tiny repeated ornaments should not spend sphere tessellation.
local r={passed=true,smallSpheres={},decorativeColliders={},sections={}}
for _,region in workspace.ImpossibleMountain:GetChildren() do
 local q=region:FindFirstChild('MountainQuality')
 if q then
  local n=0
  for _,p in q.Scenery:GetDescendants() do
   if p:IsA('BasePart') then
    n+=1
    if p.CanCollide and p.Name~='BoulderCore' then table.insert(r.decorativeColliders,p:GetFullName()) end
    local m=p:FindFirstChildOfClass('SpecialMesh')
    if m and m.MeshType==Enum.MeshType.Sphere and math.max(p.Size.X,p.Size.Y,p.Size.Z)<6 then table.insert(r.smallSpheres,p:GetFullName()) end
   end
  end
  r.sections[region.Name]=n
 end
end
r.passed=#r.smallSpheres==0 and #r.decorativeColliders==0
return r
