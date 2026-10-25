-- Authored finishing compositions. Cosmetic only; baked in Edit, never on startup.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local F={}
local function triangle(parent,a,b,c,color,material,support)
 if support then
  -- Tiny overlap closes exact-edge ray/physics gaps between adjacent facets.
  local mid=(a+b+c)/3
  a+=(a-mid).Unit*.08;b+=(b-mid).Unit*.08;c+=(c-mid).Unit*.08
 end
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right)
 local h=math.abs(ab:Dot(up))
 for _,s in ipairs({{(a+b)/2,right,up,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,up,-back,math.abs(ac:Dot(back))}}) do
  local p=Instance.new('WedgePart');p.Name=if support then 'BackdropWalkSurface' else 'ButtressFacet';p.Size=Vector3.new(if support then 1 else .08,h,s[5]);p.CFrame=CFrame.fromMatrix(s[1],s[2],s[3],s[4])
  p.Color=color;p.Material=material;p.Anchored=true;p.CanCollide=support==true;p.CanQuery=support==true;p.CanTouch=false
  if support then p:SetAttribute('MountainArtSupport',true) end;p.Parent=parent
 end
end
local function folder(parent,name)
 local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f
end
function F.apply(world)
 assert(not game:GetService('RunService'):IsRunning(),'Edit only')
 assert(game.PlaceId==0 and world.Name=='ImpossibleMountain','Isolated local mountain only')
 assert(not world:FindFirstChild('EnvironmentFinish'),'Already finished')
 local root=folder(world,'EnvironmentFinish')
 local archive=folder(game.ServerStorage,'EnvironmentFinishPrior')
 local function block(parent,name,size,cf,color,material)
  return A.part(parent,name,size,cf,color,material)
 end
 local function rock(parent,cf,scale,color,material,seed)
  -- Interlocking wedges form a rooted, broken outcrop with broad faces.
  for i=1,7 do
   local p=Instance.new('WedgePart');p.Name='JointedOutcrop';p.Anchored=true
   p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
   local a=i*2.399+seed
   p.Size=Vector3.new(scale.X*(.36+.05*(i%3)),scale.Y*(.67+.11*(i%4)),scale.Z*(.42+.04*(i%3)))
   p.CFrame=cf*CFrame.new(math.cos(a)*scale.X*.2,-scale.Y*.12,math.sin(a)*scale.Z*.18)*CFrame.Angles(.09*math.sin(a),a,.09*math.cos(a))
   p.Material=material;p.Color=color:Lerp(Color3.fromRGB(219,220,207),.035*(i%4));p.Parent=parent
  end
 end
 local function voussoirs(parent,frame,radius,width,depth,color,material,start,finish)
  local count=math.ceil((finish-start)*radius/5)
  for j=1,count do
   local a=start+(finish-start)*(j-.5)/count
   local pos=Vector3.new(math.cos(a)*radius,math.sin(a)*radius,0)
   block(parent,'ArchStone',Vector3.new((finish-start)*radius/count*.92,width,depth),frame*CFrame.new(pos)*CFrame.Angles(0,0,a+math.pi/2),color:Lerp(Color3.new(1,1,1),.035*(j%3)),material)
  end
 end
 for ki,k in ipairs(C.kingdoms) do
  local group=folder(root,k.id);local old=world.EnvironmentComposition[k.id]
  local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
  local q=C.route(ki,.875);local out=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
  local frame=CFrame.lookAt(center,center-out)
  local stone=A.color(k.rock);local accent=A.color(k.accent)
  -- Remove only these previous decorative placeholders from the visible composition.
  local prior=folder(archive,k.id)
  -- Closed, tapering buttress: its lower end enters the mountain, its crown
  -- supports the external landmark. No disconnected pile of large wedges.
  for _,p in ipairs(old:GetChildren()) do
   if p.Name=='BackdropFoundation' or p.Name=='BackdropRoot' then p.Parent=prior end
  end
  local rings={}
  for ri,spec in ipairs({{46,58,-1,38},{40,40,-30,9},{30,30,-79,-37}}) do
   local ring={}
   for j=1,8 do
    local a=(j-1)*math.pi/4;local rough=1+.055*math.sin(j*2.7+ki)
    ring[j]=frame:PointToWorldSpace(Vector3.new(math.cos(a)*spec[1]*rough,spec[3],spec[4]+math.sin(a)*spec[2]*rough))
   end
   rings[ri]=ring
  end
  local crownCenter=frame:PointToWorldSpace(Vector3.new(0,-1,38))
  for j=1,8 do triangle(group,crownCenter,rings[1][j],rings[1][j%8+1],stone,Enum.Material[k.material],true) end
  for ri=1,2 do for j=1,8 do
   local n=j%8+1;local tint=stone:Lerp(Color3.fromRGB(176,183,176),.03*(j%4))
   triangle(group,rings[ri][j],rings[ri+1][j],rings[ri][n],tint,Enum.Material[k.material])
   triangle(group,rings[ri][n],rings[ri+1][j],rings[ri+1][n],tint,Enum.Material[k.material])
  end end
  -- The arena buttress is continuous; no separate hanging side-rock props.
  if ki==1 then
   -- Interleaved ivory garden masonry and hanging garden beds.
   for j=0,8 do
    local a=.15+j*math.pi*.105;local x=math.cos(a)*38;local z=58+math.sin(a)*13
    block(group,'GardenCapstone',Vector3.new(7,1.2,6),frame*CFrame.new(x,5,z)*CFrame.Angles(0,-a,0),Color3.fromRGB(191,190,159),Enum.Material.Limestone)
    for b=1,3 do
     local pos=(frame*CFrame.new(x+(b-2)*2,6,z)).Position
     A.part(group,'GardenFern',Vector3.new(2.8,.6,5),CFrame.new(pos)*CFrame.Angles(.3,b*1.3,.15),Color3.fromRGB(89,139,88),Enum.Material.Grass,Enum.PartType.Ball)
     A.part(group,'GardenBlossom',Vector3.new(1.8,.65,1.7),CFrame.new(pos+Vector3.new(0,.8,0)),accent:Lerp(Color3.new(1,1,1),b*.2),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    end
   end
   voussoirs(group,frame*CFrame.new(0,14,68),22,2.8,4,Color3.fromRGB(189,191,159),Enum.Material.Limestone,.12,math.pi-.12)
   for _,s in ipairs({-1,1}) do
    block(group,'GardenArchPier',Vector3.new(4.5,16,6),frame*CFrame.new(s*21.8,8,68),Color3.fromRGB(189,191,159),Enum.Material.Limestone)
    block(group,'GardenArchCapital',Vector3.new(6,1.2,7),frame*CFrame.new(s*21.8,15,68),Color3.fromRGB(206,205,177),Enum.Material.Limestone)
   end
  elseif ki==2 then
   -- Asymmetric falls: a hero curtain, two stepped tributaries, wet ledges and vines.
   for _,p in ipairs(old:GetChildren()) do
    if p.Name=='SilverCascade' or p.Name=='FallFoam' or p.Name=='SplashBasin' or p.Name=='WaterSculptedFin' then p.Parent=prior end
   end
   for j,spec in ipairs({{-19,55,12,65},{1,39,8,69},{20,29,6,62}}) do
    local x,h,width,z=table.unpack(spec)
    rock(group,frame*CFrame.new(x,h*.38,z+8),Vector3.new(width+14,h+14,22),stone,Enum.Material.Slate,j)
    local water=block(group,'SilkenWaterfall',Vector3.new(width,h,1),frame*CFrame.new(x,h/2,z-4),Color3.fromRGB(115,201,213),Enum.Material.SmoothPlastic);water.Transparency=.24
    for rib=1,5 do
     local f=block(group,'WaterThread',Vector3.new(.12+rib%2*.09,h*.97,.12),frame*CFrame.new(x-width/2+rib*width/6,h*.49,z-4.7),Color3.fromRGB(223,246,242),Enum.Material.SmoothPlastic);f.Transparency=.35+rib%2*.2
    end
    A.part(group,'FoamPool',Vector3.new(width+7,.6,12),frame*CFrame.new(x,.6,z-3),Color3.fromRGB(193,239,230),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    for s=-1,1,2 do
     for v=0,6 do
      A.part(group,'HangingFern',Vector3.new(2.8,.65,4.3),frame*CFrame.new(x+s*(width/2+2),h-v*3,z-4)*CFrame.Angles(.6,s*.6,.2),Color3.fromRGB(69,119+v*3,92),Enum.Material.Grass,Enum.PartType.Ball)
     end
    end
   end
  elseif ki==3 then
   voussoirs(group,frame*CFrame.new(0,12,61),24,4.8,7,Color3.fromRGB(210,168,108),Enum.Material.Sandstone,0,math.pi)
   for _,s in ipairs({-1,1}) do
    for level=0,4 do
     block(group,'WeatheredColumn',Vector3.new(8-level*.55,4.2,9-level*.5),frame*CFrame.new(s*27,3+level*5,60)*CFrame.Angles(0,s*.04*level,0),Color3.fromRGB(204+level*3,164+level*2,107),Enum.Material.Sandstone)
    end
    for j=1,4 do rock(group,frame*CFrame.new(s*(26+j*4),1,65+j*2),Vector3.new(7,5,8),stone,Enum.Material.Sandstone,j) end
   end
  elseif ki==4 then
   voussoirs(group,frame*CFrame.new(0,22,65),28,4.8,6,Color3.fromRGB(148,137,175),Enum.Material.Marble,.1,2.55)
   for j=1,6 do
    local angle=j*.48
    block(group,'ObservatoryInlay',Vector3.new(1.1,4,.3),frame*CFrame.new(math.cos(angle)*28,22+math.sin(angle)*28,61.8)*CFrame.Angles(0,0,angle),Color3.fromRGB(204,188,226),Enum.Material.Metal)
   end
  elseif ki==5 then
   voussoirs(group,frame*CFrame.new(0,9,59),26,6,9,Color3.fromRGB(78,65,65),Enum.Material.Basalt,.07,math.pi-.07)
   for j=-2,2 do
    block(group,'ForgeKeystone',Vector3.new(5,6+math.abs(j),8),frame*CFrame.new(j*6,35-math.abs(j)*2,60)*CFrame.Angles(0,0,-j*.1),Color3.fromRGB(85,69,65),Enum.Material.Basalt)
    block(group,'EmberInlay',Vector3.new(.6,3,.2),frame*CFrame.new(j*6,35-math.abs(j)*2,55.8),Color3.fromRGB(221,134,65),Enum.Material.Neon)
   end
  else
   voussoirs(group,frame*CFrame.new(0,30,61),29,3.8,6,Color3.fromRGB(214,225,235),Enum.Material.Marble,0,math.pi)
   for _,s in ipairs({-1,1}) do
    for level=0,5 do
     block(group,'SanctumAshlar',Vector3.new(8-level*.45,4.7,8-level*.4),frame*CFrame.new(s*29,3+level*5.2,60),Color3.fromRGB(205+level*4,216+level*3,228+level*2),Enum.Material.Marble)
    end
   end
  end
  task.wait()
 end
 -- Summit's large open meridian reads from below; thin silver rather than neon.
 local crown=folder(root,'CrownMeridian')
 local cf=CFrame.new(0,959,-25)*CFrame.Angles(0,-.65,.12)
 voussoirs(crown,cf,67,2.2,2.2,Color3.fromRGB(179,204,225),Enum.Material.Metal,-.15,math.pi*1.82)
 for j=1,7 do
  local a=j*math.pi/4
  local point=(cf*CFrame.new(math.cos(a)*67,math.sin(a)*67,0)).Position
  A.part(crown,'MeridianStar',Vector3.new(4,7,4),CFrame.new(point)*CFrame.Angles(0,.3,math.pi/4),Color3.fromRGB(204,226,241),Enum.Material.Marble)
 end
 root:SetAttribute('Revision',1)
 return #root:GetDescendants()
end
return F
