-- Mountain-only in-place upgrade. Never clears voxels or rebuilds gameplay anchors.
local Q={version=4}
local S=require(script.Parent.MountainSurface)
local A=require(script.Parent.Art)
local rockPrototype
local function prepareRock()
 if not rockPrototype then
  -- One local CSG prototype, cloned thereafter: material-bearing cut faces without uploads.
  local ball=Instance.new('Part');ball.Shape=Enum.PartType.Ball;ball.Size=Vector3.one*10;ball.CFrame=CFrame.identity
  local cut=Instance.new('Part');cut.Size=Vector3.new(8,8.5,8);cut.CFrame=CFrame.new(.4,-.4,.2)*CFrame.Angles(.12,.22,.17)
  local ok,pieces=pcall(function()
   return game:GetService('GeometryService'):IntersectAsync(ball,{cut},{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic,SplitApart=false})
  end)
  ball:Destroy();cut:Destroy()
  assert(ok,'Rock prototype intersection failed: '..tostring(pieces))
  rockPrototype=assert(pieces[1],'Rock prototype intersection returned no geometry')
  for i=2,#pieces do pieces[i]:Destroy() end
 end
end
local function cutRock(parent,name,size,cf,color,material)
 local q=rockPrototype:Clone();q.Name=name;q.Size=size;q.CFrame=cf;q.Material=if material==Enum.Material.Grass then Enum.Material.Rock else material
 q.Color=color;q.UsePartColor=true;q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.Parent=parent;return q
end
local function folder(parent,name)
 local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f
end
local function part(parent,name,size,cf,color,material,collide,shape)
 -- Small accent silhouettes need only a few faces, not a tessellated sphere.
 if name=='Bloom' or name=='DesertBloom' or name=='TrailVerge' or name=='Foam' then shape=nil end
 if name=='DesertSucculent' then
  shape=Enum.PartType.Cylinder;size=Vector3.new(size.Y,size.X,size.Z);cf=cf*CFrame.Angles(0,0,math.pi/2)
 end
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
 -- Buried, tilted bedrock: one broad mass and a lateral fracture, never an oval stack.
 local cf=CFrame.new(p)*CFrame.Angles(0,yaw,0)
 local w,h,d=scale.X,scale.Y,scale.Z
 cutRock(parent,'RockMass',Vector3.new(w*.92,h*1.3,d),cf*CFrame.new(-w*.06,h*.29,0)*CFrame.Angles(.19,.18,-.24),color,material)
 cutRock(parent,'Fracture',Vector3.new(w*.51,h*.81,d*.83),cf*CFrame.new(w*.26,h*.22,d*.12)*CFrame.Angles(-.15,-.32,.18),color:Lerp(Color3.new(0,0,0),.08),material)
 if interior then
  local hull=part(parent,'BoulderCore',Vector3.new(w*.5,h*.65,d*.5),cf*CFrame.new(0,h*.3,0),color,material,true);hull.Transparency=1
 end
end
local function plant(parent,p,scale,color,accent,rng,flower)
 local yaw=rng:NextNumber(0,6.28)
 local biome=parent:GetAttribute('Biome') or 1
 local x=p.X-4096;local d=-210-(biome-1)*200-p.Z
 local up=Vector3.yAxis
 if d>=0 and d<=120 then
  -- Ground on the rendered wedges, not the continuous profile between vertices.
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={parent.Parent.WalkSurface}
  local hit=workspace:Raycast(Vector3.new(p.X,16+(biome-1)*64+100,p.Z),Vector3.new(0,-120,0),params)
  if hit then p=hit.Position;up=hit.Normal end
 end
 local right=Vector3.new(up.Y,-up.X,0).Unit
 local cf=CFrame.fromMatrix(p-up*.08,right,up)*CFrame.Angles(0,yaw,0)
 if biome<=2 then
  -- Low unequal sprays grow from a buried root rather than a five-legged tripod.
  for j=1,3 do
   local length=scale*(.85+j*.28)
   local leaf=cf*CFrame.Angles(0,j*2.39,0)*CFrame.new(0,scale*.2,-length*.33)*CFrame.Angles(-.22-j*.035,0,.09)
   wedge(parent,'LeafSpray',Vector3.new(scale*(.34+j*.08),scale*.12,length),leaf,color:Lerp(Color3.new(1,1,1),j*.04),Enum.Material.Grass,false)
  end
  if flower then
   part(parent,'Bloom',Vector3.new(scale*.48,.18,scale*.48),cf*CFrame.new(.15,scale*.38,-.2)*CFrame.Angles(0,.7,.1),accent,Enum.Material.SmoothPlastic,false)
  end
 elseif biome==3 then
  for j=1,3 do wedge(parent,'AgaveLeaf',Vector3.new(scale*.3,scale*.15,scale),cf*CFrame.Angles(0,j*2.4,0)*CFrame.new(0,scale*.24,-scale*.18)*CFrame.Angles(-.55,0,0),color,Enum.Material.Grass,false) end
 elseif biome==4 then
  for j=1,2 do wedge(parent,'AmethystShard',Vector3.new(scale*.32,scale*(.5+j*.22),scale*.4),cf*CFrame.new(j*.4,scale*.22,0)*CFrame.Angles(.1,0,j*.19),accent:Lerp(color,.45),Enum.Material.Slate,false) end
 elseif biome==5 then
  for j=1,2 do wedge(parent,'BasaltScree',Vector3.new(scale*.65,scale*.27,scale),cf*CFrame.new(j*.5,0,j*.4)*CFrame.Angles(.08,j,0),color:Lerp(Color3.fromRGB(45,43,46),.55),Enum.Material.Basalt,false) end
 else
  for j=1,2 do wedge(parent,'FrostShard',Vector3.new(scale*.4,scale*.45,scale*.8),cf*CFrame.new(j*.4,.1,j*.3)*CFrame.Angles(.12,j,.2),color:Lerp(accent,.3),Enum.Material.Ice,false) end
 end
end
local function tree(parent,p,scale,color,leaf,rng)
 local yaw=rng:NextNumber(0,6.28);local m=folder(parent,'CanopyGrove');local top=p+Vector3.new(1,scale,0)
 A.link(m,'Trunk',p,top,scale*.1,color,Enum.Material.Wood,false)
 for j=1,5 do
  local a=yaw+j*2.4;local q=p+Vector3.new(math.cos(a)*scale*(.2+j*.025),scale*(.68+j*.055),math.sin(a)*scale*.28)
  A.link(m,'Branch',p+Vector3.new(0,scale*.45,0),q,scale*.045,color,Enum.Material.Wood,false)
  part(m,'LeafCloud',Vector3.new(scale*(.47+j*.025),scale*(.48+j%3*.06),scale*.58),CFrame.new(q)*CFrame.Angles(.17,a,.22),leaf:Lerp(Color3.new(1,1,1),j*.025),Enum.Material.Grass,false,Enum.PartType.Ball)
 end
end
local function crystal(parent,p,height,color,yaw)
 local cf=CFrame.new(p)*CFrame.Angles(.1,yaw,.14)
 -- Opposed tapered faces meet at one ridge; no separate cuboid stem and cap.
 wedge(parent,'CrystalFacet',Vector3.new(height*.3,height,height*.32),cf*CFrame.new(0,height*.43,-height*.16),color,Enum.Material.Slate,false)
 wedge(parent,'CrystalFacet',Vector3.new(height*.3,height,height*.32),cf*CFrame.new(0,height*.43,height*.16)*CFrame.Angles(0,math.pi,0),color:Lerp(Color3.new(1,1,1),.23),Enum.Material.Slate,false)
 local vein=part(parent,'CrystalVein',Vector3.new(.1,height*.48,.12),cf*CFrame.new(height*.152,height*.25,0),color:Lerp(Color3.new(1,1,1),.3),Enum.Material.Neon,false);vein.CastShadow=false
end
function Q.apply(root,onlySection)
 assert(root and root:GetAttribute('FreeClimbVersion')==1,'Requires current free-climb world')
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 -- Resolve the yielding CSG dependency before replacing any existing region.
 prepareRock()
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
  art:SetAttribute('Biome',k)
  local material=Enum.Material[if k<=2 then 'Grass' else c.material]
  local ground=if k<=2 then green:Lerp(stone,.25) else stone:Lerp(green,.22)
  -- The escape shares the surrounding soil instead of forming a dark ruler stripe.
  -- Keep Review03 route physics while changing visible material, including fresh builds.
  region.OpenAscent.CustomPhysicalProperties=region.OpenAscent.CustomPhysicalProperties or PhysicalProperties.new(Enum.Material.Rock)
  region.OpenAscent.Color=ground;region.OpenAscent.Material=material
  for _,p in region:GetChildren() do
   if p:IsA('BasePart') and string.sub(p.Name,1,7)=='Terrace' then p.Color=ground end
   if p.Name=='DownhillLane' then
    p.CustomPhysicalProperties=p.CustomPhysicalProperties or PhysicalProperties.new(Enum.Material[if k<=2 then 'Ground' else c.material])
    p.Color=ground;p.Material=material
   end
   if p.Name=='DownhillArrow' then p.Size=Vector3.new(2,.2,1.4);p.Transparency=.3 end
  end
  for ix=1,#S.widths-1 do if not (S.widths[ix]==-16 and S.widths[ix+1]==16) then
   for iz=1,#S.depths-1 do
    local x1,x2=S.widths[ix],S.widths[ix+1];local d1,d2=S.depths[iz],S.depths[iz+1]
    local function v(x,d) return Vector3.new(4096+x,y+S.height(k,x,d),z-d) end
    local a,b,cc,d=v(x1,d1),v(x2,d1),v(x1,d2),v(x2,d2)
    local col=ground:Lerp(stone,math.clamp((math.noise((x1+x2)*.009,(d1+d2)*.0125,k*.7)+.35)*.18,0,.13))
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
   -- Waterfall composition is authored below as one source and basin.
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
  -- Foreground patches make the path read as a worn trail, with a clear center for escape.
  -- Added after the primary geometry pass so every tested collider remains identical.
  for side=-1,1,2 do for j=1,7 do
   local d=8+j*14+math.sin(j*2.3+k)*5;local x=side*(35+((j*23+k*11)%43));local p=groundAt(x,d)
   local col=if k==1 then Color3.fromRGB(81,142,79) elseif k==2 then Color3.fromRGB(70,133,124) elseif k==3 then Color3.fromRGB(143,147,88) elseif k==4 then Color3.fromRGB(123,101,160) elseif k==5 then Color3.fromRGB(114,88,72) else Color3.fromRGB(143,169,191)
   for n=1,3 do
    local px=x+math.sin(n*2.4+j)*4;local pd=d+math.cos(n*2.4+j)*5
    plant(art,groundAt(px,pd),if k<=2 then 2.3+(n%3)*.55 else 1.5+(n%3)*.4,col,accent,rng,k==1)
   end
   -- Low irregular verge stones soften the edge without collision or route narrowing.
   if j%2==0 then wedge(art,'TrailVerge',Vector3.new(2.8,.35,3.8),CFrame.new(groundAt(side*(19+j%2),d))*CFrame.Angles(0,j,.08),stone,Enum.Material.Rock,false) end
  end end
  if k==1 then
   for j=1,3 do tree(art,groundAt(-110-j*6,35+j*18),17+j*1.8,Color3.fromRGB(91,72,63),accent:Lerp(green,.15),rng) end
  elseif k==2 then
   -- Keep the foreground of the falls open.
  elseif k==3 then
   for j=1,3 do rock(art,groundAt(-112-j*5,60+j*10),Vector3.new(14,20+j*2,23),.3,stone:Lerp(accent,.12),Enum.Material.Sandstone) end
   for j=1,5 do
    local p=groundAt((if j%2==0 then 1 else -1)*(44+j*5),14+j*16);local col=Color3.fromRGB(95,134,94)
    part(art,'DesertSucculent',Vector3.new(2.6,4+j*.6,2.6),CFrame.new(p+Vector3.new(0,2+j*.3,0)),col,Enum.Material.Grass,false,Enum.PartType.Ball)
    part(art,'DesertBloom',Vector3.new(1.4,.7,1.4),CFrame.new(p+Vector3.new(0,4.3+j*.6,0)),accent,Enum.Material.SmoothPlastic,false,Enum.PartType.Ball)
   end
  elseif k==4 then
   for j=1,5 do crystal(art,groundAt(-105-j*5,64+j*3),13+j*1.8,accent,j*.9) end
  elseif k==5 then
   for j=1,5 do
    local p=groundAt(-106-j*5,65+j*4)
    rock(art,p,Vector3.new(12,17+j,18),j*.33,stone,Enum.Material.Basalt)
    local seam=part(art,'BasaltFissure',Vector3.new(.4,14+j,.5),CFrame.new(p+Vector3.new(1,8,8)),accent,Enum.Material.Neon,false);seam.CastShadow=false
   end
  else
   local p=groundAt(-123,98);local pale=stone:Lerp(green,.65)
   rock(art,p+Vector3.new(-13,0,0),Vector3.new(12,23,15),-.12,pale,Enum.Material.Snow)
   rock(art,p+Vector3.new(13,0,0),Vector3.new(12,23,15),.12,pale,Enum.Material.Snow)
   for j=-1,1 do part(art,'CrownArch',Vector3.new(15,7,13),CFrame.new(p+Vector3.new(j*9,20+3*(1-math.abs(j)),0))*CFrame.Angles(0,0,-j*.35),pale,Enum.Material.Snow,false,Enum.PartType.Ball) end
   for j=1,5 do local star=part(art,'CrownStar',Vector3.new(1,1,1),CFrame.new(p+Vector3.new((j-3)*4,10+math.sin(j)*3,2))*CFrame.Angles(0,0,.78),accent,Enum.Material.Neon,false);star.CastShadow=false end
  end
  -- Low paired outcrops carry the adjacent palette across the outer terrace seam.
  -- Keep the entire encounter apron and all three escape lines empty.
  if k<6 then
   local nextStone=A.color(C.kingdoms[k+1].rock)
   for side=-1,1,2 do
    local p=groundAt(side*(145-k%2*4),193-side*3)
    rock(art,p-Vector3.new(0,1.5,0),Vector3.new(24,7+k%3,16),side*.7,stone:Lerp(nextStone,.35),Enum.Material[c.material])
    for n=1,3 do plant(art,groundAt(side*(129+n*3),185+n*3),2+n*.3,green:Lerp(nextStone,.25),accent,rng,k==1) end
   end
  end
  -- Authored diagonal shoulders continue through the seam at different offsets.
  -- These low shelves sit outside x=16 escape and x=88 side lines, behind raid aprons.
  for side=-1,1,2 do
   for j=1,3 do
    local x=side*(39+j*9);local d=189+j*2+side*3
    local col=stone:Lerp(ground,.35)
    rock(art,groundAt(x,d)-Vector3.new(0,2,0),Vector3.new(16+j*3,4+j*.8,11+j*2),side*.4+j*.2,col,Enum.Material[c.material])
   end
  end
  -- A single broad asymmetrical outer landform replaces a line of tiny props.
  local flank=if k==3 or k==5 then 1 else -1
  for j=1,3 do
   local x=flank*(121+j*7);local d=30+j*23;local h=if k==5 then 21+j*4 else 12+j*3
   rock(art,groundAt(x,d)-Vector3.new(0,4,0),Vector3.new(30+j*3,h,39-j*3),flank*(.15+j*.22),stone,Enum.Material[c.material])
  end
  if k<=2 then
   -- Unequal drifts around the existing boulders create planted beds, not a grid.
   for j=1,8 do
    local side=if j%3==0 then 1 else -1
    local bx=side*(101+(j*17)%39);local bd=18+(j*29)%139
    for n=1,5 do
     local px=bx+math.sin(n*2.39+j)*7;local pd=bd+math.cos(n*2.39+j)*9
     plant(art,groundAt(px,pd),2.5+(n%3)*.5,green:Lerp(Color3.fromRGB(43,92,65),.25),accent,rng,k==1 and n%2==0)
    end
    local p=groundAt(bx,bd)
    part(art,'Understory',Vector3.new(8+j%3,4+j%2,7),CFrame.new(p+Vector3.new(0,1.6,0))*CFrame.Angles(.12,j,.18),green:Lerp(Color3.fromRGB(48,100,65),.2),Enum.Material.Grass,false,Enum.PartType.Ball)
   end
  end
  if k==2 then
   -- Water starts in a perched source, descends over an exposed lip into a rock basin.
   for _,p in art:GetChildren() do if p.Name=='FallsRibbon' or p.Name=='Foam' or p.Name=='CascadingFalls' or p.Name=='FallsPool' then p:Destroy() end end
   local p=groundAt(-124,87);local waterColor=Color3.fromRGB(94,194,200)
   for j=1,5 do
    local a=j*1.05
    rock(art,p+Vector3.new(math.cos(a)*16,-2,13+math.sin(a)*9),Vector3.new(12,5+j%2*2,10),a,stone,Enum.Material.Slate)
   end
   local function water(name,size,pos,tilt)
    local q=part(art,name,size,CFrame.new(pos)*CFrame.Angles(tilt or 0,0,0),waterColor,Enum.Material.SmoothPlastic,false,Enum.PartType.Ball);q.Transparency=.12;q.CastShadow=false;return q
   end
   water('SourcePool',Vector3.new(18,.4,13),p+Vector3.new(0,24,-2))
   rock(art,p+Vector3.new(-13,15,-5),Vector3.new(13,16,22),-.3,stone,Enum.Material.Slate)
   rock(art,p+Vector3.new(11,15,-8),Vector3.new(14,17,24),.4,stone,Enum.Material.Slate)
   water('WaterCurtain',Vector3.new(10,25,1.8),p+Vector3.new(-1,12,6),-.12)
   water('WaterCurtain',Vector3.new(5,21,1.4),p+Vector3.new(5,10,7),-.15)
   water('FallsBasin',Vector3.new(29,.45,18),p+Vector3.new(0,.4,14))
   for j=1,5 do
    local q=part(art,'FallsFoam',Vector3.new(3+j%2,.18,1.3),CFrame.new(p+Vector3.new((j-3)*3,.7,9+j%2*2))*CFrame.Angles(0,j*.6,0),Color3.fromRGB(210,240,229),Enum.Material.SmoothPlastic,false,Enum.PartType.Ball);q.CastShadow=false
   end
  elseif k==3 then
   -- Warm erosion layers run laterally instead of three equal upright pillars.
   local p=groundAt(-132,74)
   for j=1,4 do
    rock(art,p+Vector3.new(j*4,2+j*4,-j*2),Vector3.new(39-j*5,7,26-j*2),-.22,stone:Lerp(accent,j*.035),Enum.Material.Sandstone)
   end
  elseif k==4 then
   local p=groundAt(-126,76)
   rock(art,p-Vector3.new(0,3,0),Vector3.new(39,14,31),.3,stone:Lerp(Color3.fromRGB(47,36,65),.3),Enum.Material.Slate)
   for j=1,7 do crystal(art,p+Vector3.new(math.sin(j*2.4)*12,3,math.cos(j*2.4)*9),9+(j%4)*4,accent:Lerp(Color3.fromRGB(105,143,192),j*.035),j*.8) end
  elseif k==5 then
   -- Leaning basalt fins and low talus frame one fissure on the outer shoulder.
   for j=1,6 do
    local p=groundAt(116+j*4,51+j*8)
    part(art,'BasaltFin',Vector3.new(8+j%2*4,18+j*2,16),CFrame.new(p+Vector3.new(0,5,0))*CFrame.Angles(-.2,j*.17,-.25),stone:Lerp(Color3.new(0,0,0),.1),Enum.Material.Basalt,false)
    rock(art,p+Vector3.new(-8,-1,7),Vector3.new(17,7,20),j*.6,stone,Enum.Material.Basalt)
   end
  elseif k==6 then
   -- Crown stones lean inward around a luminous opening, with a low snowy foreground.
   for _,q in art:GetChildren() do if q.Name=='CrownArch' or q.Name=='CrownStar' then q:Destroy() end end
   local p=groundAt(-123,98);local pale=stone:Lerp(green,.65)
   for j=-2,2 do
    local a=j*.65
    cutRock(art,'CrownStone',Vector3.new(13,13,13),CFrame.new(p+Vector3.new(math.sin(a)*17,4+math.cos(a)*17,0))*CFrame.Angles(0,.1,-a),pale:Lerp(Color3.new(1,1,1),(j+2)*.018),Enum.Material.Snow)
   end
   crystal(art,p+Vector3.new(0,3,0),13,accent,0)
   for j=1,4 do rock(art,p+Vector3.new((j-2.5)*11,-3,11+j%2*3),Vector3.new(16,5,12),j*.7,pale,Enum.Material.Snow) end
  end
  region:SetAttribute('MountainQualityVersion',Q.version)
  task.wait()
 end end
 if not onlySection then root:SetAttribute('MountainQualityVersion',Q.version) end
 return root
end
return Q
