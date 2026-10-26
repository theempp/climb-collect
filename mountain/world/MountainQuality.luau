-- Mountain-only in-place upgrade. Never clears voxels or rebuilds gameplay anchors.
local Q={version=1}
local S=require(script.Parent.MountainSurface)
local A=require(script.Parent.Art)
local function folder(parent,name)
 local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f
end
local function part(parent,name,size,cf,color,material,collide,shape)
 return A.part(parent,name,size,cf,color,material,shape,collide)
end
local function wedge(parent,name,size,cf,color,material,collide)
 local p=Instance.new('WedgePart');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material
 p.Anchored=true;p.CanCollide=collide==true;p.CanQuery=p.CanCollide;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function triangle(parent,a,b,c,color,material,collide)
 -- Longest edge is the shared base of two right triangles; all cells share vertices.
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
 local h=math.abs(ab:Dot(up));local thickness=.2
 local shift=Vector3.new(0,-thickness/2,0)
 wedge(parent,'SculptedGround',Vector3.new(thickness,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2+shift,right,up,back),color,material,collide)
 wedge(parent,'SculptedGround',Vector3.new(thickness,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2+shift,-right,up,-back),color,material,collide)
end
local function ramp(parent,a,b,width,color,material)
 return part(parent,'CatchRecovery',Vector3.new(width,.6,(b-a).Magnitude+1),CFrame.lookAt((a+b)/2-Vector3.new(0,.3,0),b-Vector3.new(0,.3,0)),color,material,true)
end
local function rock(parent,p,scale,yaw,color,material,interior)
 -- Rounded mass plus cut strata. Interior boulders have conservative visible core collision.
 local cf=CFrame.new(p)*CFrame.Angles(0,yaw,0)
 local w,h,d=scale.X,scale.Y,scale.Z
 part(parent,'RockMass',Vector3.new(w,h,d),cf*CFrame.new(0,h*.32,0)*CFrame.Angles(.12,.18,-.11),color,material,false,Enum.PartType.Ball)
 part(parent,'RockMass',Vector3.new(w*.7,h*.73,d*.77),cf*CFrame.new(w*.15,h*.55,-d*.12)*CFrame.Angles(-.12,-.2,.23),color:Lerp(Color3.new(1,1,1),.08),material,false,Enum.PartType.Ball)
 wedge(parent,'Stratum',Vector3.new(w*.72,h*.12,d*.72),cf*CFrame.new(0,h*.47,0)*CFrame.Angles(0,.08,.07),color:Lerp(Color3.new(1,1,1),.15),material,false)
 if interior then
  local hull=part(parent,'BoulderCore',Vector3.new(w*.5,h*.65,d*.5),cf*CFrame.new(0,h*.3,0),color,material,true);hull.Transparency=1
 end
end
local function plant(parent,p,scale,color,accent,rng,flower)
 local cf=CFrame.new(p)*CFrame.Angles(0,rng:NextNumber(0,6.28),0)
 for j=1,5 do
  local a=j*math.pi*2/5;local leaf=cf*CFrame.Angles(0,a,0)*CFrame.new(0,scale*.45,-scale*.6)*CFrame.Angles(-.6,0,0)
  wedge(parent,'FernFrond',Vector3.new(scale*.35,scale*.12,scale*1.7),leaf,color:Lerp(Color3.new(1,1,1),j*.025),Enum.Material.Grass,false)
 end
 if flower then
  part(parent,'Bloom',Vector3.new(scale*.6,scale*.35,scale*.6),cf*CFrame.new(0,scale*.75,0),accent,Enum.Material.SmoothPlastic,false,Enum.PartType.Ball)
 end
end
local function tree(parent,p,scale,color,leaf,rng)
 local yaw=rng:NextNumber(0,6.28);local m=folder(parent,'CanopyGrove');local top=p+Vector3.new(1,scale,0)
 A.link(m,'Trunk',p,top,scale*.1,color,Enum.Material.Wood,false)
 for j=1,4 do
  local a=yaw+j*2.4;local q=p+Vector3.new(math.cos(a)*scale*.3,scale*(.65+j*.065),math.sin(a)*scale*.3)
  A.link(m,'Branch',p+Vector3.new(0,scale*.45,0),q,scale*.045,color,Enum.Material.Wood,false)
  part(m,'LeafCloud',Vector3.new(scale*.65,scale*.27,scale*.57),CFrame.new(q)*CFrame.Angles(.07,a,.12),leaf:Lerp(Color3.new(1,1,1),j*.025),Enum.Material.Grass,false,Enum.PartType.Ball)
 end
end
local function crystal(parent,p,height,color,yaw)
 local cf=CFrame.new(p)*CFrame.Angles(.1,yaw,.14)
 part(parent,'CrystalBody',Vector3.new(height*.22,height*.68,height*.27),cf*CFrame.new(0,height*.34,0)*CFrame.Angles(0,math.pi/4,0),color,Enum.Material.Slate,false)
 wedge(parent,'CrystalPoint',Vector3.new(height*.3,height*.35,height*.3),cf*CFrame.new(0,height*.84,0),color:Lerp(Color3.new(1,1,1),.25),Enum.Material.Glass,false)
 local vein=part(parent,'CrystalVein',Vector3.new(.18,height*.55,.2),cf*CFrame.new(height*.115,height*.37,-height*.14),color,Enum.Material.Neon,false);vein.CastShadow=false
end
function Q.apply(root,onlySection)
 assert(root and root:GetAttribute('FreeClimbVersion')==1,'Requires current free-climb world')
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 for k,c in C.kingdoms do if not onlySection or onlySection==k then
  local region=assert(root:FindFirstChild(c.name),'Missing biome '..c.name)
  if region:GetAttribute('MountainQualityVersion')==Q.version then continue end
  local old=region:FindFirstChild('MountainQuality');if old then old:Destroy() end
  local y=16+(k-1)*64;local z=-210-(k-1)*200;local top=y+64
  local stone=A.color(c.rock);local accent=A.color(c.accent);local green=A.color(c.color)
  -- Retain the original center floor and all terraces; replace only its two planar shoulders.
  region.OpenAscent.Size=Vector3.new(32,region.OpenAscent.Size.Y,region.OpenAscent.Size.Z)
  for _,p in region:GetChildren() do
   if p.Name=='BrokenCliff' or p.Name=='MineralCluster' or string.sub(p.Name,1,6)=='Grown_' then p:Destroy() end
  end
  local quality=folder(region,'MountainQuality');local surface=folder(quality,'WalkSurface');local art=folder(quality,'Scenery')
  local material=Enum.Material[if k<=2 then 'Grass' else c.material]
  local ground=if k<=2 then green:Lerp(stone,.25) else stone:Lerp(green,.22)
  for _,p in region:GetChildren() do
   if p:IsA('BasePart') and string.sub(p.Name,1,7)=='Terrace' then p.Color=ground end
   if p.Name=='DownhillLane' then p.Color=stone:Lerp(Color3.fromRGB(205,197,163),.32) end
   if p.Name=='DownhillArrow' then p.Transparency=.2 end
  end
  for ix=1,#S.widths-1 do if not (S.widths[ix]==-16 and S.widths[ix+1]==16) then
   for iz=1,#S.depths-1 do
    local x1,x2=S.widths[ix],S.widths[ix+1];local d1,d2=S.depths[iz],S.depths[iz+1]
    local function v(x,d) return Vector3.new(4096+x,y+S.height(k,x,d),z-d) end
    local a,b,cc,d=v(x1,d1),v(x2,d1),v(x1,d2),v(x2,d2)
    local col=ground:Lerp(stone,if ix==1 or ix==#S.widths-1 then .45 else .08*((ix+iz)%3))
    triangle(surface,a,b,cc,col,material,true);triangle(surface,b,d,cc,col,material,true)
   end
  end end
  local rng=Random.new(70031+k*397)
  local function groundAt(x,d) return Vector3.new(4096+x,y+S.height(k,x,math.min(d,120)),z-d) end
  -- Asymmetric mid-slope islands make two open climbing lines around the continuous escape.
  -- Their conservative cores stay between x32..76, clear of center and x88 side routes.
  for j=1,4 do
   local side=if j%2==0 then 1 else -1;local d=22+j*19;local x=side*(52+(k+j)%3*3)
   local p=groundAt(x,d)
   rock(art,p-Vector3.new(0,1.5,0),Vector3.new(23,8+j%2*4,19),side*.22,stone,Enum.Material[c.material],true)
   for n=1,3 do plant(art,p+Vector3.new(side*(9+n),0,n*4-8),1.8,if k<=2 then green else stone:Lerp(green,.4),accent,rng,k==1 or k==4 or k==6) end
   if k<=2 and j%2==0 then tree(art,p+Vector3.new(2,0,-3),13,Color3.fromRGB(91,72,63),if k==1 then accent else green,rng)
   elseif k>=4 then crystal(art,p+Vector3.new(side*4,3,0),6+j,accent,j)
   end
  end
  -- Sloped edge buttresses break the ruler-straight side into a composed rock shoulder.
  for side=-1,1,2 do
   for j=1,5 do
    local d=14+j*30;local x=side*(153+rng:NextNumber(-4,9));local h=if d<120 then 8+j*1.5 else 16+j
    rock(art,groundAt(x,d)-Vector3.new(0,3,0),Vector3.new(24+rng:NextNumber(0,7),h,30+rng:NextNumber(0,9)),side*.3+j*.3,stone,Enum.Material[c.material])
    local p=groundAt(side*(133+rng:NextNumber(-4,7)),d+4)
    if k==1 or k==2 then tree(art,p,12+j*1.5,Color3.fromRGB(89,75,62),if k==1 then accent else green:Lerp(accent,.18),rng)
    elseif k==3 then plant(art,p,3.2,Color3.fromRGB(103,131,85),accent,rng,false)
    else crystal(art,p,6+j*1.2,accent,side+j*.7) end
   end
   -- Low vegetation is clustered at rock feet, leaving the center and encounter apron open.
   for j=1,12 do
    local d=12+j*13;local x=side*(114+rng:NextNumber(0,24));local p=groundAt(x,d)
    local col=if k==3 then Color3.fromRGB(117,139,87) elseif k==5 then Color3.fromRGB(111,94,82) elseif k==6 then Color3.fromRGB(130,164,182) else green
    plant(art,p,if k<=2 then rng:NextNumber(1.3,2.5) else rng:NextNumber(.9,1.8),col,accent,rng,k==1 or k==4 or k==6)
   end
  end
  -- A single side landmark per biome, always outside the 32-stud escape and raid apron.
  if k==1 then
   tree(art,groundAt(-118,104),24,Color3.fromRGB(91,72,63),accent,rng)
   for j=1,6 do plant(art,groundAt(-104+j*3,104+j%2*5),2,green,accent,rng,true) end
  elseif k==2 then
   for j=1,3 do
    local p=groundAt(-147+j*5,92);rock(art,p,Vector3.new(12,17+j*2,16),j*.4,stone,Enum.Material.Slate)
    local water=part(art,'FallsRibbon',Vector3.new(3,17+j*2,.3),CFrame.new(p+Vector3.new(0,8+j,8)),accent,Enum.Material.Glass,false);water.Transparency=.22;water.CastShadow=false
    part(art,'Foam',Vector3.new(6,.15,3),CFrame.new(p+Vector3.new(0,.2,9)),Color3.fromRGB(210,244,239),Enum.Material.SmoothPlastic,false,Enum.PartType.Ball)
   end
  elseif k==3 then
   for j=1,3 do rock(art,groundAt(-150+j*9,100)-Vector3.new(0,3,0),Vector3.new(13,17+j*3,22),-.3+j*.2,stone:Lerp(accent,.14),Enum.Material.Sandstone) end
   local p=S.sandstoneRecovery();ramp(surface,Vector3.new(p[1].x,p[1].y,p[1].z),Vector3.new(p[2].x,p[2].y,p[2].z),10,stone,Enum.Material.Sandstone)
  elseif k==4 then
   for j=1,5 do crystal(art,groundAt(-145+j*7,99+j%2*8),8+j*2.5,accent,j*.65) end
  elseif k==5 then
   for j=1,4 do
    local p=groundAt(-150+j*9,100);rock(art,p,Vector3.new(14,14+j*2,18),j*.5,stone,Enum.Material.Basalt)
    local ember=part(art,'EmberSeam',Vector3.new(.3,7+j,1),CFrame.new(p+Vector3.new(2,6,9)),accent,Enum.Material.Neon,false);ember.CastShadow=false
   end
  else
   for j=1,4 do
    local p=groundAt(-149+j*10,105);rock(art,p,Vector3.new(15,9+j*2,18),j*.3,stone:Lerp(green,.5),Enum.Material.Snow)
    crystal(art,p+Vector3.new(0,5,0),8+j,accent,j)
   end
  end
  region:SetAttribute('MountainQualityVersion',Q.version)
  task.wait()
 end end
 if not onlySection then root:SetAttribute('MountainQualityVersion',Q.version) end
 return root
end
return Q
