local w=workspace.ImpossibleMountain
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local G=require(game.ReplicatedStorage.MountainShared.CompactGeometry)
local F=require(game.ServerStorage.MountainWorld.FreeClimb)
local g=F.layout();local n=0;local misses={}
local function check(v,label) n+=1;if not v then table.insert(misses,label) end end
check(not workspace.StreamingEnabled,'full residency configured')
check(w:GetAttribute('CompactMountainVersion')==1,'compact baked geometry')
check(w:GetAttribute('CompactTerrainVersion')==1,'compact native terrain')
for k,s in g.sections do
 local region=w[C.kingdoms[k].name]
 check(region~=nil,'section '..k)
 check(math.abs(w.Sections[tostring(k)].Position.Y-s.terrace.y)<.01,'section altitude '..k)
 local hazard=w.Dynamics['Hazard_'..k]
 check((hazard.Position-Vector3.new(s.hazard.x,s.hazard.y+.4,s.hazard.z)).Magnitude<.2,'hazard anchor '..k)
 check(hazard.Size.X==32 and hazard.Size.Z==22,'full hazard clearance '..k)
 local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={region};rp.RespectCanCollide=true
 for _,x in {0,-88,88,-164,164} do for d=2,198,4 do
  local xx=4096+x*G.scale;local z=s.entry.z-d*G.scale
  local hit=workspace:Raycast(Vector3.new(xx,s.entry.y+100,z),Vector3.new(0,-140,0),rp)
  check(hit~=nil,'continuous ground '..k..':'..x..':'..d)
  if hit and x==0 then local expected=s.entry.y+64*G.scale*math.min(d/120,1);check(math.abs(hit.Position.Y-expected)<1,'center grade '..k..':'..d) end
 end end
 for _,p in region:GetChildren() do if p.Name=='DownhillLane' or p.Name=='OpenAscent' then check(p.Size.X==32,'escape width '..k) end end
end
local parts,colliders=0,0;for _,p in w:GetDescendants() do if p:IsA('BasePart') then parts+=1;if p.CanCollide then colliders+=1 end end end
for _,e in g.eggs do local pad=w.Interactions:FindFirstChild(e.id);check(pad and math.abs(pad.Position.X-e.position.x)<.01,'egg clearance '..e.id) end
check(parts==5384,'retained full scenery count');check(colliders==996,'retained collider count')
for _,p in workspace.Sanctuary.SanctuaryPlots:GetChildren() do check(p.Plot_180x220.Size.X==180 and p.Plot_180x220.Size.Z==220,'home footprint '..p.Name) end
return {passed=#misses==0,checks=n,failures=misses,parts=parts,colliders=colliders,routeDepth=1020,routeRise=326.4}
