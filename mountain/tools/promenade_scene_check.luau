-- Edit-mode scene checks for the home-base layout C grey-box (run after bake and after cold reopen).
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local S=workspace.Sanctuary;local w=workspace.ImpossibleMountain
local n=0;local misses={}
local function check(v,label) n+=1;if not v then table.insert(misses,label) end end
-- Mountain unchanged apart from the removed three-way frontage (20 approach parts, 2 side exits).
check(not workspace.StreamingEnabled,'full residency configured')
check(w:GetAttribute('CompactMountainVersion')==1 and w:GetAttribute('CompactTerrainVersion')==1,'compact mountain retained')
check(w:FindFirstChild('MountainApproaches')==nil,'old approaches removed')
local exits=w.SanctuaryExits:GetChildren();check(#exits==1 and exits[1].Name=='SanctuaryExit','single sanctuary exit')
local e=w.SanctuaryExits.SanctuaryExit;local span=L.span()
check(math.abs(e.Position.Z-L.gate.z)<.01 and e.Size.X>=span.maxX-span.minX,'exit spans the basin on the gate line')
local parts,colliders=0,0;for _,p in w:GetDescendants() do if p:IsA('BasePart') then parts+=1;if p.CanCollide then colliders+=1 end end end
check(parts==5362,'mountain parts 5384-22 = 5362')
-- Old row and the v1 promenade gone.
for _,name in {'ThreeGates_NoGameplay','GatewayTerrace','EssentialAccess','TerrainMassing_NoLandscaping','AlpineEnvironment_Step3','HomePromenade'} do check(S:FindFirstChild(name)==nil,'removed '..name) end
for _,c in S:GetChildren() do check(not c.Name:match('^Buffer_'),'removed '..c.Name) end
check(S:GetAttribute('PromenadeVersion')==L.version,'promenade version')
check(S:FindFirstChild('HomeCommons')~=nil,'commons built')
-- Homes: footprint, pose, lodge, spawn facing the street.
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={w}
local c=L.contents
for i,p in L.plots do
 local plot=S.SanctuaryPlots[string.format('Plot_%02d',i)];local f=plot:FindFirstChild(L.floorName)
 check(f and f.Size.X==L.plotWidth and f.Size.Z==L.plotDepth,'home footprint '..i)
 check(plot:FindFirstChild('Plot_140x180')==nil,'old floor renamed '..i)
 if f then
  check((f.Position-Vector3.new(p.x,L.groundY-1,p.z)).Magnitude<.01,'home position '..i)
  local look=f.CFrame.LookVector;check(math.abs(look.X+p.side)<1e-3,'home faces street '..i)
  local lodge=S.EnchantedAlpineLodges[string.format('Lodge_%02d',i)];local cf,size=lodge:GetBoundingBox()
  local q=f.CFrame:PointToObjectSpace(cf.Position)
  -- Lodge behind the yard, between the hatchery and the Beast pen, inside the rear margin.
  check(math.abs(q.X)+size.X/2<=c.pen.x-c.pen.size/2-3 and q.Z+size.Z/2<=L.plotDepth/2-2 and q.Z-size.Z/2>=c.yard.maxZ+3,'lodge inside rear of plot '..i)
  local s=plot.Spawn;local sq=f.CFrame:PointToObjectSpace(s.Position)
  check(math.abs(sq.X-c.spawn.x)<.01 and math.abs(sq.Z-c.spawn.z)<.01,'spawn position '..i)
  local lx,lz=L.spawnLook(i);local toStreet=(Vector3.new(lx,s.Position.Y,lz)-s.Position).Unit
  check(s.CFrame.LookVector:Dot(toStreet)>.999,'spawn faces street '..i)
  -- Lodge footprint marker parts moved with the lodge (no stray parts outside the floor).
  for _,d in plot:GetDescendants() do if d:IsA('BasePart') and d~=f then
   local r=f.CFrame:PointToObjectSpace(d.Position)
   check(math.abs(r.X)<=L.plotWidth/2+.5 and math.abs(r.Z)<=L.plotDepth/2+.5,'plot part inside floor '..i..':'..d.Name)
  end end
  -- Floor is the walking surface (no berm terrain or art intruding); lodge rect skipped.
  for _,pt in {{-30,-40},{0,-40},{30,-40},{-30,-25},{30,-25},{-30,-10},{0,-10},{30,-10},{-30,5},{0,5},{30,5},{-30,40},{30,40}} do
   local o=f.CFrame*CFrame.new(pt[1],40,pt[2]);local hit=workspace:Raycast(o.Position,Vector3.new(0,-60,0),rp)
   check(hit and hit.Position.Y>=L.groundY-.05 and hit.Position.Y<L.groundY+16 and hit.Instance~=workspace.Terrain,'plot surface '..i..':'..pt[1]..':'..pt[2])
  end
 end
end
-- Walking surfaces: vertical street lanes, H street lanes, gate plaza, crossing plaza; all at lane height.
local function surface(x,z,label)
 local hit=workspace:Raycast(Vector3.new(x,L.groundY+30,z),Vector3.new(0,-40,0),rp)
 check(hit and math.abs(hit.Position.Y-(L.groundY+.1))<.2 and hit.Instance~=workspace.Terrain,label)
end
local cm=L.commons
for z=cm.street.minZ+4,cm.street.maxZ-2,8 do for _,side in {-1,1} do surface(L.axisX+side*(L.channelWidth/2+L.laneWidth/2),z,'street lane '..side..':'..z) end end
for x=L.promenadeWidth/2+4,L.armReach-4,8 do for _,side in {-1,1} do
 for _,z in {L.cross.z0+L.crossLane/2,L.cross.z1-L.crossLane/2} do surface(L.axisX+side*x,z,'arm lane '..side..':'..x..':'..z) end
end end
for x=-50,50,10 do for z=cm.gatePlaza.minZ+4,cm.gatePlaza.maxZ-2,8 do surface(L.axisX+x,z,'gate plaza '..x..':'..z) end end
for _,x in {-30,-20,20,30} do for z=L.cross.z0+3,L.cross.z1-3,8 do surface(L.axisX+x,z,'crossing '..x..':'..z) end end
-- East-west on foot through the crossing (channels stop at the plaza edges, the pool sits alone).
for _,x in {-34,-26,-18,18,26,34} do for _,z in {L.cross.z0+2,L.cross.z,L.cross.z1-2} do surface(L.axisX+x,z,'crossing east-west '..x..':'..z) end end
for _,z in {L.cross.z0+2,L.cross.z1-2} do for x=-30,30,10 do surface(L.axisX+x,z,'crossing north-south '..x..':'..z) end end
-- Every new commons part stays inside the kept basin.
local hc=S:FindFirstChild('HomeCommons');local hcParts=0
if hc then for _,d in hc:GetDescendants() do if d:IsA('BasePart') then hcParts+=1
 local pos=d.Position
 check(pos.X>=span.minX-12 and pos.X<=span.maxX+12 and pos.Z>=L.gate.z-8 and pos.Z<=span.maxZ+76,'inside basin '..d:GetFullName())
end end end
-- Gate: one model, opening clear from ground to lintel, towers either side.
local gate=S:FindFirstChild('GrandGate');check(gate~=nil,'grand gate')
if gate then
 for x=L.gate.x-L.gate.opening/2+3,L.gate.x+L.gate.opening/2-3,6 do
  local hit=workspace:Raycast(Vector3.new(x,L.groundY+3,L.gate.z+30),Vector3.new(0,0,-60),rp)
  check(hit==nil or hit.Instance.CanCollide==false,'gate opening clear '..x)
 end
 local towers=0;for _,c in gate:GetChildren() do if c.Name=='TowerShaft' then towers+=1 end end;check(towers==2,'two towers')
end
local sp=0;for _,d in S:GetDescendants() do if d:IsA('BasePart') then sp+=1 end end
return {passed=#misses==0,checks=n,failures=misses,mountainParts=parts,mountainColliders=colliders,sanctuaryParts=sp,commonsParts=hcParts}
