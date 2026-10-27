-- Edit-mode scene checks for the home-base promenade review (run after bake and after cold reopen).
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
-- Old row gone.
for _,name in {'ThreeGates_NoGameplay','GatewayTerrace','EssentialAccess','TerrainMassing_NoLandscaping','AlpineEnvironment_Step3'} do check(S:FindFirstChild(name)==nil,'removed '..name) end
for _,c in S:GetChildren() do check(not c.Name:match('^Buffer_'),'removed '..c.Name) end
check(S:GetAttribute('PromenadeVersion')==L.version,'promenade version')
-- Homes: footprint, pose, contents, lodge, spawn facing the gate.
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={w}
for i,p in L.plots do
 local plot=S.SanctuaryPlots[string.format('Plot_%02d',i)];local f=plot:FindFirstChild(L.floorName)
 check(f and f.Size.X==L.plotWidth and f.Size.Z==L.plotDepth,'home footprint '..i)
 if f then
  check((f.Position-Vector3.new(p.x,L.groundY-1,p.z)).Magnitude<.01,'home position '..i)
  local look=f.CFrame.LookVector;check(math.abs(look.X+p.side)<1e-3,'home faces promenade '..i)
  local lodge=S.EnchantedAlpineLodges[string.format('Lodge_%02d',i)];local cf,size=lodge:GetBoundingBox()
  local q=f.CFrame:PointToObjectSpace(cf.Position)
  check(math.abs(q.X)+size.X/2<=L.plotWidth/2 and q.Z+size.Z/2<=L.plotDepth/2+.5 and q.Z-size.Z/2>=L.contents.spawn.z,'lodge inside rear of plot '..i)
  local s=plot.Spawn;local sq=f.CFrame:PointToObjectSpace(s.Position)
  check(math.abs(sq.X-L.contents.spawn.x)<.01 and math.abs(sq.Z-L.contents.spawn.z)<.01,'spawn position '..i)
  local toGate=(Vector3.new(L.gate.x,s.Position.Y,L.gate.z)-s.Position).Unit;check(s.CFrame.LookVector:Dot(toGate)>.999,'spawn faces gate '..i)
  -- Floor is the walking surface (no berm terrain or art intruding) across the plot interior.
  for _,lx in {-60,-30,0,30,60} do for _,lz in {-80,-40,0,40} do
   local pt=f.CFrame*CFrame.new(lx,40,lz);local hit=workspace:Raycast(pt.Position,Vector3.new(0,-60,0),rp)
   check(hit and hit.Position.Y>=L.groundY-.05 and hit.Position.Y<L.groundY+16 and hit.Instance~=workspace.Terrain,'plot surface '..i..':'..lx..':'..lz)
  end end
 end
end
-- Promenade: continuous walkable lanes from the gate forecourt to the south plaza.
for z=L.gate.z+16,L.southZ+20,8 do for _,side in {-1,1} do
 local x=L.axisX+side*(L.channelWidth/2+L.laneWidth/2)
 local hit=workspace:Raycast(Vector3.new(x,L.groundY+30,z),Vector3.new(0,-40,0),rp)
 check(hit and math.abs(hit.Position.Y-(L.groundY+.1))<.2,'lane '..side..':'..z)
end end
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
return {passed=#misses==0,checks=n,failures=misses,mountainParts=parts,mountainColliders=colliders,sanctuaryParts=sp}
