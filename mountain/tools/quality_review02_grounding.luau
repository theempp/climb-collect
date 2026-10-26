-- Recover each generated plant frame from its first leaf/shard; compare to real collision triangles.
local r={passed=true,checked=0,failures={},maximumError=0}
for _,region in workspace.ImpossibleMountain:GetChildren() do
 local q=region:FindFirstChild('MountainQuality');if not q then continue end
 local k=q.Scenery:GetAttribute('Biome');local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={q.WalkSurface}
 for _,p in q.Scenery:GetChildren() do
  local cf,s
  if p.Name=='LeafSpray' and math.abs(p.Size.Z/p.Size.X-1.13/.42)<.001 then
   s=p.Size.X/.42;cf=p.CFrame*CFrame.Angles(-.255,0,.09):Inverse()*CFrame.new(0,s*.2,-s*1.13*.33):Inverse()*CFrame.Angles(0,2.39,0):Inverse()
  elseif p.Name=='AgaveLeaf' then
   s=p.Size.X/.3;cf=p.CFrame*CFrame.Angles(-.55,0,0):Inverse()*CFrame.new(0,s*.24,-s*.18):Inverse()
  elseif p.Name=='AmethystShard' and math.abs(p.Size.Y/p.Size.X-.72/.32)<.001 then
   s=p.Size.X/.32;cf=p.CFrame*CFrame.Angles(.1,0,.19):Inverse()*CFrame.new(.4,s*.22,0):Inverse()
  elseif p.Name=='BasaltScree' then
   s=p.Size.X/.65
   -- Both instances are checked with their local index reconstructed below.
   for j=1,2 do
    local candidate=p.CFrame*CFrame.Angles(.08,j,0):Inverse()*CFrame.new(j*.5,0,j*.4):Inverse()
    local hit=workspace:Raycast(Vector3.new((candidate.Position+candidate.UpVector*.08).X,16+(k-1)*64+100,(candidate.Position+candidate.UpVector*.08).Z),Vector3.new(0,-120,0),params)
    if hit and math.abs((candidate.Position-hit.Position):Dot(hit.Normal)+.08)<.002 then cf=candidate;break end
   end
   if not cf then cf=p.CFrame end
  elseif p.Name=='FrostShard' then
   s=p.Size.X/.4
   for j=1,2 do
    local candidate=p.CFrame*CFrame.Angles(.12,j,.2):Inverse()*CFrame.new(j*.4,.1,j*.3):Inverse()
    local hit=workspace:Raycast(Vector3.new((candidate.Position+candidate.UpVector*.08).X,16+(k-1)*64+100,(candidate.Position+candidate.UpVector*.08).Z),Vector3.new(0,-120,0),params)
    if hit and math.abs((candidate.Position-hit.Position):Dot(hit.Normal)+.08)<.002 then cf=candidate;break end
   end
   if not cf then cf=p.CFrame end
  end
  if cf then
   local d=-210-(k-1)*200-cf.Z
   if d>1 and d<119 then
    local hit=workspace:Raycast(Vector3.new((cf.Position+cf.UpVector*.08).X,16+(k-1)*64+100,(cf.Position+cf.UpVector*.08).Z),Vector3.new(0,-120,0),params)
    -- Buried frame shifts x/z slightly along the triangle normal; compare signed plane distance.
    local err=if hit then math.abs((cf.Position-hit.Position):Dot(hit.Normal)+.08) else math.huge
    r.checked+=1;r.maximumError=math.max(r.maximumError,err)
    if err>.002 then table.insert(r.failures,{path=p:GetFullName(),error=err,position=tostring(cf.Position)}) end
   end
  end
 end
end
r.passed=r.checked>400 and #r.failures==0
return r
