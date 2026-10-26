-- EDIT ONLY: repeatable Review05 -> Review06 cosmetic recipe. No world rebuild.
assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local root=workspace.ImpossibleMountain
assert(root:GetAttribute('MountainQualityVersion')==4 and root:GetAttribute('LandscapeContinuationVersion')==1,'Requires Review05 baked world')
local P=require(game.ReplicatedStorage.MountainShared.AlpineProfile)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=workspace.Terrain
local result={parts=0,recolored=0,terrainMaterials=0}
local function folder(parent,name) local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
local function color(x,z) local c=P.ground(x,z);return Color3.fromRGB(c[1],c[2],c[3]) end
local function clean(parent,name) local f=parent:FindFirstChild(name);if f then f:Destroy() end;return folder(parent,name) end
local function wedge(parent,size,cf,col,mat)
 local p=Instance.new('WedgePart');p.Name='SurfaceBlend';p.Size=size;p.CFrame=cf;p.Color=col;p.Material=mat or Enum.Material.Rock
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent;result.parts+=1;return p
end
local function triangle(parent,a,b,c,col,mat)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 if ac:Cross(ab).Magnitude<.0001 then return end
 local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit;local h=math.abs(ab:Dot(up))
 wedge(parent,Vector3.new(.035,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),col,mat)
 wedge(parent,Vector3.new(.035,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),col,mat)
end
local prototype=root[C.kingdoms[1].name].MountainQuality.Scenery:FindFirstChild('RockMass')
assert(prototype and prototype:IsA('BasePart'),'Existing rock prototype required')
local function rock(parent,name,p,size,yaw,tilt,col,mat)
 local q=prototype:Clone();q.Name=name;q.Size=size;q.CFrame=CFrame.new(p)*CFrame.Angles(tilt,yaw,-tilt*.6)
 q.Color=col;q.Material=mat or Enum.Material.Rock;q.UsePartColor=true;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.Parent=parent;result.parts+=1;return q
end
for k,c in C.kingdoms do
 local region=root[c.name];local art=clean(region,'NaturalTransitions')
 local z0=-210-(k-1)*200;local y0=16+(k-1)*64
 -- Original physics and transforms remain exact; only visible ground palette changes.
 for _,p in region:GetDescendants() do
  if p:IsA('BasePart') and (p.Name=='SculptedGround' or p.Name=='OpenAscent' or p.Name=='DownhillLane' or p.Name:sub(1,7)=='Terrace' or p.Name=='MountainMass') then
   p.CustomPhysicalProperties=p.CustomPhysicalProperties or p.CurrentPhysicalProperties
   p.Color=color(p.Position.X-4096,p.Position.Z);p.Material=Enum.Material.Rock;result.recolored+=1
  end
 end
 -- Split flat terrace appearance into irregularly colored soil patches. The pit and
 -- moving hazard retain their original visible opening; no patch spans that void.
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include
 local floors={region.OpenAscent,region.MountainQuality.WalkSurface}
 for _,p in region:GetChildren() do if p:IsA('BasePart') and (p.Name:sub(1,7)=='Terrace' or p.Name=='DownhillLane') then table.insert(floors,p) end end
 ray.FilterDescendantsInstances=floors
 local function point(x,d)
  local hit=workspace:Raycast(Vector3.new(4096+x,y0+90,z0-d),Vector3.new(0,-120,0),ray)
  return if hit then hit.Position+Vector3.new(0,.045,0) else nil
 end
 local xs={-172,-140,-108,-76,-44,-24,-12,12,24,44,76,108,140,172}
 for ix=1,#xs-1 do for d=0,180,20 do
  local a,b=xs[ix],xs[ix+1]
  if d<120 and (a< -24 or b>24) then continue end
  if k==3 and a<96 and b>44 and d>=140 and d<180 then continue end
  -- Avoid raised lane edges by keeping each cell wholly inside one original plane.
  local inset=-.015;local aa,bb,cc,dd=point(a+inset,d-.015),point(b-inset,d-.015),point(a+inset,d+20.015),point(b-inset,d+20.015)
  if aa and bb and cc and dd then
   local col=color((a+b)/2,z0-d-10)
   triangle(art,aa,bb,cc,col,Enum.Material.Rock);triangle(art,bb,dd,cc,col,Enum.Material.Rock)
  end
 end end
 -- Rock fingers attach the colored face to the enclosing terrain. They never cross
 -- the outer tested walking line (x +/- 164) or the central escape/egg/hazard routes.
 for side=-1,1,2 do for j=1,7 do
  local d=8+j*26+(if side<0 then 0 else -12);local x=side*(190+12*math.sin(j*1.7+k))
  local y=y0+64*math.min(d/120,1)
  rock(art,'ShoulderSpur',Vector3.new(4096+x,y-8,z0-d),Vector3.new(37+9*(j%3),24+12*(j%2),48+8*(j%3)),side*.45+j*.27,.17,color(x,z0-d),Enum.Material.Rock)
 end end
 region:SetAttribute('NaturalTransitionsVersion',1);task.wait()
end
local landscape=clean(root,'NaturalLandscape')
-- Rear ridgeline is sculpted native Terrain, not oversized decorative blocks.
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={T}
local peaks={{-230,-1570,765,165,190},{-40,-1640,780,150,160},{180,-1580,730,175,160},{330,-1490,620,120,130}}
for z0=-1840,-1456,32 do
 local reg=Region3.new(Vector3.new(3392,-64,z0),Vector3.new(4800,800,z0+32))
 local mats,occ=T:ReadVoxels(reg,4)
 for i=1,#mats do for kk=1,8 do
  local x=3392+(i-.5)*4-4096;local z=z0+(kk-.5)*4;local height=-64
  for n,p in peaks do
   local dx=x-p[1];local dz=z-p[2];local u=dx*.94+dz*.34;local v=-dx*.34+dz*.94
   local t=math.max(0,1-math.abs(u)/p[4]-math.abs(v)/p[5])
   if t>0 then height=math.max(height,350+(p[3]-350)*t+math.noise(x*.03,z*.022,n)*12*t) end
  end
  for j=1,#mats[i] do
   local y=-64+(j-.5)*4;local target=math.floor(math.clamp((height-y+2)/4,0,1)*256)/256
   if target>occ[i][j][kk] then occ[i][j][kk]=target;mats[i][j][kk]=if y>600+math.noise(x*.022,z*.02,2)*35 then Enum.Material.Snow else Enum.Material.Rock end
  end
 end end
 T:WriteVoxels(reg,4,mats,occ);task.wait()
end
-- Sparse conifer groves connect the bare exterior foothills to the garden/river.
for i=1,32 do
 local side=if i%2==0 then 1 else -1;local x=side*(228+(i%5)*35);local z=-280-(i*37)%410
 local hit=workspace:Raycast(Vector3.new(4096+x,700,z),Vector3.new(0,-800,0),ray)
 if hit then
  local h=14+(i%4)*4;local pos=hit.Position
  local trunk=Instance.new('Part');trunk.Name='AlpineTrunk';trunk.Size=Vector3.new(1.3,h*.65,1.3);trunk.CFrame=CFrame.new(pos+Vector3.new(0,h*.3,0));trunk.Color=Color3.fromRGB(88,76,62);trunk.Material=Enum.Material.Wood;trunk.Anchored=true;trunk.CanCollide=false;trunk.CanQuery=false;trunk.CanTouch=false;trunk.Parent=landscape;result.parts+=1
  for j=1,3 do
   local s=h*(.65-j*.11);local q=wedge(landscape,Vector3.new(s,h*.6,s),CFrame.new(pos+Vector3.new(0,h*(.32+j*.17),0))*CFrame.Angles(0,i*2.4+j,0),Color3.fromRGB(65+j*5,101+j*7,85+j*4),Enum.Material.Grass);q.Name='FirBough';q.CastShadow=true
  end
 end
end
-- Material-only terrain pass: never changes occupancy. Keep a 176-stud corridor
-- guard so the tested route and boundary samples retain their exact terrain.
for z0=-1840,-240,32 do
 local reg=Region3.new(Vector3.new(3392,-64,z0),Vector3.new(4800,800,z0+32))
 local mats,occ=T:ReadVoxels(reg,4);local changed=0
 for i=1,#mats do
  local x=3392+(i-.5)*4-4096
  for kk=1,8 do
   local z=z0+(kk-.5)*4
   if math.abs(x)>=176 or z< -1420 then
    local top=0;for j=#mats[i],1,-1 do if occ[i][j][kk]>0 then top=-64+(j-.5)*4;break end end
    for j=1,#mats[i] do if occ[i][j][kk]>0 then
     local y=-64+(j-.5)*4;local material=Enum.Material.Rock
     local snow=760-210*P.smooth(900,1500,-z)+math.noise(x*.012,z*.013,8)*58
     local green=380-120*P.smooth(500,1000,-z)+65*math.noise(x*.007,z*.008,15)
     if y>snow then material=Enum.Material.Snow
     elseif y>top-12 and y<green and z> -850 then material=Enum.Material.Grass
     elseif z> -930 and z< -600 and y<300 and y>top-9 and math.noise(x*.009,z*.01,6)>.08 then material=Enum.Material.Sandstone
     elseif z< -1050 and z> -1350 and y<360 then material=Enum.Material.Slate end
     if mats[i][j][kk]~=material then mats[i][j][kk]=material;changed+=1 end
    end end
   end
  end
 end
 if changed>0 then T:WriteVoxels(reg,4,mats,occ) end
 result.terrainMaterials+=changed;task.wait()
end
root:SetAttribute('NaturalLandscapeVersion',1)
return result
