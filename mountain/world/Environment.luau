-- Deterministic art shell. Never writes terrain or changes a gameplay surface.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local E={}
local function folder(parent,name)
 local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f
end
local function wedge(parent,name,size,cf,color,material)
 local p=Instance.new('WedgePart');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Rock
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function arc(parent,name,center,radius,start,finish,color,width,tilt)
 local previous
 for j=0,20 do
  local a=start+(finish-start)*j/20
  local pos=center+Vector3.new(math.cos(a)*radius,math.sin(a)*radius,math.sin(a)*(tilt or 0))
  if previous then A.link(parent,name,previous,pos,width,color,Enum.Material.Marble) end
  previous=pos
 end
end
local function spire(parent,center,width,height,depth,color,material,angle)
 local function triangle(a,b,c,tint)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
  elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right)
  local h=math.abs(ab:Dot(up))
  wedge(parent,'SculptedFace',Vector3.new(.08,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),tint,material)
  wedge(parent,'SculptedFace',Vector3.new(.08,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),tint,material)
 end
 local tip=center+Vector3.new(width*.15,height/2,-depth*.12)
 for face=0,4 do
  local a=angle+face*math.pi*2/5;local b=angle+(face+1)*math.pi*2/5
  local p=center+Vector3.new(math.cos(a)*width,-height/2,math.sin(a)*depth*.6)
  local q=center+Vector3.new(math.cos(b)*width,-height/2,math.sin(b)*depth*.6)
  triangle(tip,p,q,color:Lerp(Color3.fromRGB(223,225,218),face*.035))
 end
end
function E.orient(world)
 assert(not game:GetService('RunService'):IsRunning(),'Orient in Edit only')
 assert(world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Isolated mountain only')
 local root=world:FindFirstChild('EnvironmentComposition')
 if not root then return end
 for ki,k in ipairs(C.kingdoms) do
  local group=root:FindFirstChild(k.id)
  if group and not group:GetAttribute('OutwardBackdrop') then
   local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
   local q=C.route(ki,.875)
   local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
   -- Keep the whole backdrop beyond the 41-stud arena, not through its combat lanes.
   local orient=CFrame.lookAt(center,center-outward)*CFrame.new(0,0,24)*CFrame.new(-center)
   for _,p in ipairs(group:GetDescendants()) do
    if p:IsA('BasePart') and p.Name~='BiomeInterleave' then p.CFrame=orient*p.CFrame end
   end
   group:SetAttribute('OutwardBackdrop',true)
   -- Non-colliding rooted rock shoulders connect the displaced scenery to the arena mass.
   local rock=A.color(k.rock)
   A.part(group,'BackdropFoundation',Vector3.new(76,32,62),CFrame.lookAt(center+outward*48-Vector3.new(0,16,0),center+outward*47-Vector3.new(0,16,0)),rock,Enum.Material[k.material],Enum.PartType.Ball)
   A.part(group,'BackdropRoot',Vector3.new(66,42,56),CFrame.lookAt(center+outward*30-Vector3.new(0,36,0),center+outward*29-Vector3.new(0,36,0)),rock,Enum.Material[k.material],Enum.PartType.Ball)
  end
 end
 root:SetAttribute('Revision',2)
end
function E.apply(world)
 assert(not game:GetService('RunService'):IsRunning(),'Build in Edit only')
 assert(world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Isolated mountain only')
 if world:FindFirstChild('EnvironmentComposition') then E.orient(world);return 'already built; orientation current' end
 local root=folder(world,'EnvironmentComposition')
 local protected={}
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then table.insert(protected,p) end
 end
 -- Conservative world-space AABB exclusion: preserves full height above paths,
 -- not merely collisions. This also protects branches, ladders and reward docks.
 local function clear(cf,size)
  local ext=Vector3.zero
  for _,axis in ipairs({cf.RightVector*size.X/2,cf.UpVector*size.Y/2,cf.LookVector*size.Z/2}) do ext+=Vector3.new(math.abs(axis.X),math.abs(axis.Y),math.abs(axis.Z)) end
  for _,p in ipairs(protected) do
   local d=cf.Position-p.Position;local ps=p.Size/2
   local pe=Vector3.zero
   for _,a in ipairs({p.CFrame.RightVector*ps.X,p.CFrame.UpVector*ps.Y,p.CFrame.LookVector*ps.Z}) do pe+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   if math.abs(d.X)<ext.X+pe.X+5 and math.abs(d.Z)<ext.Z+pe.Z+5 and d.Y+ext.Y> -pe.Y-2 and d.Y-ext.Y<pe.Y+12 then return false end
  end
  return true
 end
 -- Side-fin experiments were visually rejected; retained only in dated checkpoints.
 -- Unequal crown peaks, grounded in the existing summit rather than floating.
 local crown=folder(root,'SplitCrown')
 for i,spec in ipairs({{-72,-22,105,34,65},{35,-75,137,32,60},{81,-28,83,28,60}}) do
  local x,z,height,width,depth=table.unpack(spec)
  local cf=CFrame.new(x,840+height/2,z)*CFrame.Angles(0,i*.9,0)
  local size=Vector3.new(width,height,depth)
  if clear(CFrame.new(cf.Position),Vector3.new(width*2,height,depth*1.2)) then
   spire(crown,cf.Position,width,height,depth,Color3.fromRGB(198,211,226),Enum.Material.Slate,i*.9)
   spire(crown,cf.Position+Vector3.new(0,height*.08,0),width*.65,height*.84,depth*.65,Color3.fromRGB(230,237,243),Enum.Material.Snow,i*.9)
  end
 end
 for ki,k in ipairs(C.kingdoms) do
  local region=world[k.name];local group=folder(root,k.id)
  local center=region.ArenaFloor.Position+Vector3.new(0,2.5,0)
  local stone=A.color(k.rock);local accent=A.color(k.accent)
  local function part(name,size,offset,color,material,shape,rot)
   return A.part(group,name,size,CFrame.new(center+offset)*(rot or CFrame.identity),color or stone,material or Enum.Material.Rock,shape)
  end
  -- Backdrops sit beyond the arena's play space. Original checkpoints retain old art.
  local old=region:FindFirstChild(k.landmarks[1]..'_Signature')
  if old then
   local archive=game.ServerStorage:FindFirstChild('EnvironmentPriorLandmarks') or folder(game.ServerStorage,'EnvironmentPriorLandmarks')
   old.Parent=archive
  end
  if ki==1 then
   for _,side in ipairs({-1,1}) do
    local base=center+Vector3.new(side*31,0,32)
    for j=1,7 do
     local next=base+Vector3.new(-side*(2+j*.25),6,1.2)
     local limb=A.link(group,'LivingGardenArch',base,next,6-j*.55,Color3.fromRGB(105,91,75),Enum.Material.Wood)
     limb.Size=Vector3.new((next-base).Magnitude,6-j*.55,6-j*.55);limb.CFrame*=CFrame.Angles(0,math.pi/2,0);limb.Shape=Enum.PartType.Cylinder;base=next
     if j>3 then
      for b=1,3 do A.part(group,'BlossomCanopy',Vector3.new(19-b,8,14),CFrame.new(base+Vector3.new(side*b*3,2,math.sin(b+j)*5)),accent:Lerp(Color3.fromRGB(255,226,230),b*.18),Enum.Material.Grass,Enum.PartType.Ball) end
     end
    end
   end
   for j=1,9 do local a=j*math.pi/10
    local o=Vector3.new(math.cos(a)*36,0,22+math.sin(a)*18)
    for tier=1,3 do part('GardenMasonry',Vector3.new(7,1.3,5),o+Vector3.new(0,tier*1.3,0),stone:Lerp(Color3.fromRGB(197,198,160),.5),Enum.Material.Limestone) end
   end
  elseif ki==2 then
   for j=1,7 do
    local h=32+18*math.sin(j*.7)^2;local x=(j-4)*10
    wedge(group,'WaterSculptedFin',Vector3.new(14,h+13,20),CFrame.new(center+Vector3.new(x,h/2,43))*CFrame.Angles(0,.14*j,0),stone,Enum.Material.Slate)
    local water=part('SilverCascade',Vector3.new(5.5,h,1.2),Vector3.new(x,h/2,31),accent:Lerp(Color3.new(1,1,1),.18),Enum.Material.SmoothPlastic);water.Transparency=.2
    for rib=1,3 do part('FallFoam',Vector3.new(.2,h,.2),Vector3.new(x-2+rib, h/2,30.2),Color3.fromRGB(218,245,247),Enum.Material.SmoothPlastic).Transparency=.4 end
    part('SplashBasin',Vector3.new(13,.7,12),Vector3.new(x,1,29),accent,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   end
  elseif ki==3 then
   for _,side in ipairs({-1,1}) do
    part('SolarPylonFoot',Vector3.new(12,3,12),Vector3.new(side*27,1.5,35),stone,Enum.Material.Sandstone)
    wedge(group,'SolarPylon',Vector3.new(9,39,10),CFrame.new(center+Vector3.new(side*27,21,35))*CFrame.Angles(0,side*math.pi/2,0),Color3.fromRGB(218,177,116),Enum.Material.Sandstone)
    for y=1,5 do part('PylonCarving',Vector3.new(5,.7,.4),Vector3.new(side*27,7+y*5,29.7),accent,Enum.Material.Metal) end
   end
   arc(group,'DawnArch',center+Vector3.new(0,12,37),23,0,math.pi,Color3.fromRGB(226,193,141),4)
   arc(group,'SolarDisc',center+Vector3.new(0,30,39),10,0,math.pi*2,accent,1)
   for j=1,12 do local a=j*math.pi/6;local p=center+Vector3.new(math.cos(a)*13,30+math.sin(a)*13,39)
    A.link(group,'Sunray',p,p+Vector3.new(math.cos(a)*4,math.sin(a)*4,0),.8,accent,Enum.Material.Metal)
   end
  elseif ki==4 then
   arc(group,'FracturedObservatory',center+Vector3.new(0,22,37),27,.15,math.pi*.85,stone:Lerp(Color3.new(1,1,1),.3),3)
   arc(group,'BrokenOrbit',center+Vector3.new(0,23,40),20,math.pi*.9,math.pi*1.85,accent,1,9)
   for j=1,7 do A.crystal(group,center+Vector3.new((j-4)*10,0,35+math.abs(j-4)*2),k,12+j%3*7) end
   for _,s in ipairs({-1,1}) do part('MirrorWing',Vector3.new(9,23,1),Vector3.new(s*12,18,35),Color3.fromRGB(168,184,218),Enum.Material.Glass,nil,CFrame.Angles(0,s*.3,s*.2)).Reflectance=.35 end
  elseif ki==5 then
   for j=1,7 do
    local h=24+(j%3)*9;local x=(j-4)*10
    wedge(group,'CrucibleRib',Vector3.new(12,h,15),CFrame.new(center+Vector3.new(x,h/2,37))*CFrame.Angles(0,j*.16,0),stone,Enum.Material.Basalt)
    part('CoolingSeam',Vector3.new(.6,h*.65,.5),Vector3.new(x,h*.4,28),accent:Lerp(Color3.fromRGB(153,53,27),.3),Enum.Material.Neon)
   end
   arc(group,'ForgeLintel',center+Vector3.new(0,9,35),24,.1,math.pi-.1,Color3.fromRGB(88,65,63),5)
  else
   for _,s in ipairs({-1,1}) do
    part('SanctumPier',Vector3.new(6,37,7),Vector3.new(s*28,18.5,34),Color3.fromRGB(215,224,236),Enum.Material.Marble)
    for y=1,4 do part('SilverCollar',Vector3.new(7,.7,8),Vector3.new(s*28,y*8,34),accent,Enum.Material.Metal) end
   end
   arc(group,'SanctumCrown',center+Vector3.new(0,30,35),28,0,math.pi,Color3.fromRGB(229,235,244),3)
   arc(group,'CelestialMeridian',center+Vector3.new(0,38,35),18,0,math.pi*2,accent,.75,12)
   for j=1,5 do A.crystal(group,center+Vector3.new((j-3)*10,37+18-math.abs(j-3)*4,35),k,5) end
  end
  -- Material overlap at the next kingdom: a diagonal seam of small mineral/plant beds.
  if ki<6 then for j=1,12 do
   local q=C.route(ki,.78+j*.017);local out=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
   local pos=Vector3.new(q.x,q.y,q.z)-out*(18+j%3*3)
   local next=C.kingdoms[ki+1]
   local size=Vector3.new(8,3+j%3,6);local cf=CFrame.new(pos)*CFrame.Angles(.12,q.angle,.12)
   if clear(cf,size) then wedge(group,'BiomeInterleave',size,cf,stone:Lerp(A.color(next.rock),j/12),Enum.Material[next.material]) end
  end end
  task.wait()
 end
 -- Orient backdrops outward without rotating route-relative biome accents.
 E.orient(world)
 return #root:GetDescendants()
end
return E
