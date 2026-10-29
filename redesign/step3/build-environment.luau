-- Step 3 only. Run once on a separately saved copy of the owner-approved Step 2.
local root=workspace:WaitForChild('MountainEmpire_Step1')
assert(not root:FindFirstChild('AlpineEnvironment_Step3'),'Step 3 already exists')
assert(#root.EnchantedAlpineLodges:GetChildren()==8)
local H=game:GetService('HttpService')
local props={'CFrame','Size','Color','Material','Transparency','CanCollide','CanQuery','CanTouch','Anchored','Reflectance'}
_G.Step3Protected={}
for _,group in {root.EnchantedAlpineLodges,root.SanctuaryPlots,root.EssentialAccess,root.GatewayTerrace} do
 for _,p in group:GetDescendants() do if p:IsA('BasePart') then local b={} for _,k in props do b[k]=p[k] end _G.Step3Protected[p]=b end end
end
local env=Instance.new('Folder') env.Name='AlpineEnvironment_Step3' env.Parent=root
local C={stone=Color3.fromRGB(125,139,139),light=Color3.fromRGB(185,193,178),dark=Color3.fromRGB(73,91,99),grass=Color3.fromRGB(90,135,82),pine=Color3.fromRGB(39,91,73),pine2=Color3.fromRGB(57,113,85),wood=Color3.fromRGB(98,68,43),gold=Color3.fromRGB(173,139,75),teal=Color3.fromRGB(46,94,99),snow=Color3.fromRGB(224,237,234),water=Color3.fromRGB(105,201,211)}
local function group(name) local m=Instance.new('Model') m.Name=name return m end
local function part(m,n,s,pos,c,mat,cf,solid,kind)
 local p=Instance.new(kind or 'Part') p.Name=n p.Size=s p.CFrame=cf or CFrame.new(pos) p.Color=c p.Material=mat or Enum.Material.Slate
 p.Anchored=true p.CanCollide=solid==true p.CanTouch=false p.CanQuery=solid==true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=m return p
end
local function box(m,n,x,y,z,sx,sy,sz,c,mat,solid) return part(m,n,Vector3.new(sx,sy,sz),Vector3.new(x,y,z),c,mat,nil,solid) end
local function beam(m,n,a,b,w,c,mat) return part(m,n,Vector3.new(w,w,(b-a).Magnitude),(a+b)/2,c,mat,CFrame.lookAt((a+b)/2,b)) end
local function rock(m,x,y,z,s,k)
 local p=part(m,'WeatheredBoulder',Vector3.new(s,s*.63,s*.82),Vector3.new(x,y+s*.18,z),C.stone:Lerp(C.dark,k or .2),Enum.Material.Rock,CFrame.new(x,y+s*.18,z)*CFrame.Angles(.15,.5+s,.2))
 local mesh=Instance.new('SpecialMesh') mesh.MeshType=Enum.MeshType.Sphere mesh.Scale=Vector3.new(1,1,1) mesh.Parent=p
end
local function pine(m,x,y,z,h,w)
 box(m,'CedarTrunk',x,y+h*.35,z,w*.12,h*.7,w*.12,C.wood,Enum.Material.Wood)
 for tier=1,3 do
  local size=w*(1-(tier-1)*.22) local height=h*.43 local cy=y+h*(.31+(tier-1)*.235)
  for q=0,3 do
   local cf=CFrame.new(x,cy,z)*CFrame.Angles(0,q*math.pi/2,0)*CFrame.new(size/4,0,size/4)
   part(m,'PineBough',Vector3.new(size/2,height,size/2),cf.Position,tier%2==0 and C.pine2 or C.pine,Enum.Material.Grass,cf,false,'CornerWedgePart')
  end
 end
end
local function lamp(m,x,y,z)
 box(m,'LanternPlinth',x,y+.5,z,2,1,2,C.stone)
 box(m,'CedarLanternPost',x,y+3,z,.5,5,.5,C.wood,Enum.Material.Wood)
 box(m,'BrassLanternBase',x,y+5.3,z,1.7,.3,1.7,C.gold,Enum.Material.Metal)
 box(m,'WarmLanternGlass',x,y+6,z,1.1,1.2,1.1,Color3.fromRGB(255,221,155),Enum.Material.Neon)
 box(m,'LanternCap',x,y+6.8,z,2,.4,2,C.teal)
end
local function flowers(m,x,y,z)
 box(m,'PlantingSoil',x,y+.12,z,3,.24,6,Color3.fromRGB(71,66,48),Enum.Material.Ground)
 for j=1,5 do
  local fx=x+math.sin(j*4)*.9 local fz=z-2.4+j*.85
  box(m,'AlpineLeaf',fx,y+.6,fz,.28,1.1,.28,C.pine2,Enum.Material.Grass)
  local p=box(m,'AlpineBlossom',fx,y+1.2,fz,.65,.5,.65,j%2==0 and Color3.fromRGB(182,155,213) or Color3.fromRGB(238,220,157),Enum.Material.SmoothPlastic) p.Shape=Enum.PartType.Ball
 end
end
-- Each planted strip stays strictly within its existing 8-stud buffer.
for i=1,7 do
 local x=-564+(i-1)*188 local m=group(string.format('NaturalBoundary_%02d',i))
 for _,z in {26,80,134,188} do
  box(m,'DryStoneSegment',x,1.1,z,2.8,2.2,22,C.stone,Enum.Material.Cobblestone,true)
  box(m,'StoneCoping',x,2.3,z,3.2,.35,22.5,C.light)
  for _,dz in {-11,11} do box(m,'TimberEndpost',x,2.2,z+dz,.7,4.4,.7,C.wood,Enum.Material.Wood) end
 end
 for _,z in {53,107,161,212} do pine(m,x,0,z,12+(i%3)*1.5,6.4) end
 for _,z in {8,42,96,150} do flowers(m,x+2,0,z) end
 for _,z in {15,122,202} do rock(m,x-1.8,0,z,2.7,.25) end
 lamp(m,x,0,4)
 m.Parent=env task.wait()
end
-- Cover the rectangular blockout retaining faces with layered geology and planted shelves.
local mass=root.TerrainMassing_NoLandscaping
for _,p in mass:GetChildren() do
 if p.Name=='MountainPeakMassing' then p:Destroy()
 elseif p:IsA('BasePart') and p.Name~='BeyondGateLanding' then p.Material=Enum.Material.Rock p.Color=C.dark end
end
for _,side in {-1,1} do
 local m=group(side<0 and 'WestBasinTerraces' or 'EastBasinTerraces')
 for j=0,10 do
  local z=-130+j*36 local x=side*(778+math.sin(j*1.8)*5)
  rock(m,x,7,z,31+(j%3)*4,.24)
  box(m,'MeadowShelf',side*788,24,z,43,1.8,37,C.grass,Enum.Material.Grass)
  rock(m,side*829,35,z,40+(j%3)*6,.33)
  if j%2==0 then pine(m,side*795,25,z,30+(j%3)*5,17) end
 end
 m.Parent=env task.wait()
end
for segment=0,7 do
 local m=group('RearGardenTerrace_'..segment) local cx=-658+segment*188
 for j=0,4 do
  local x=cx-76+j*38
  box(m,'LowerRetainingCourse',x,7.5,225,37,15,5,C.stone,Enum.Material.Cobblestone)
  box(m,'LowerCoping',x,15.5,225,38,1,6,C.light)
  box(m,'LowerMeadowShelf',x,16.5,242,39,1,29,C.grass,Enum.Material.Grass)
  rock(m,x,29,268,29+j%2*8,.15)
  box(m,'UpperMeadowShelf',x,37,284,39,2,26,C.grass,Enum.Material.Grass)
 end
 pine(m,cx-57,17,245,28,17) pine(m,cx+61,17,244,34,19)
 pine(m,cx+8,38,284,37,22)
 rock(m,cx+30,17,242,10,.2) flowers(m,cx-23,17,232) flowers(m,cx+23,17,232)
 m.Parent=env task.wait()
end
for _,side in {-1,1} do
 local m=group(side<0 and 'WestGateLandscape' or 'EastGateLandscape')
 for j=0,15 do
  local x=side*(137+j*39)
  box(m,'RetainingStone',x,11,-108,38,23,5,C.stone,Enum.Material.Cobblestone)
  box(m,'RetainingCap',x,23,-108,39,1.2,7,C.light)
  box(m,'PlantedLowerTerrace',x,28.6,-143,40,1.2,61,C.grass,Enum.Material.Grass)
  rock(m,x,40,-187,34+(j%3)*5,.22)
  box(m,'PlantedUpperTerrace',x,62.5,-220,40,1,63,C.grass,Enum.Material.Grass)
  if j%2==0 then pine(m,x,29,-143,29+(j%3)*5,17) pine(m,x+side*13,63,-229,38,22) end
  if j%4==0 then flowers(m,x,29,-119) lamp(m,x+9,29,-118) end
 end
 -- Two stepped water ribbons, kept wholly beyond the clear access zone.
 local x=side*222
 for _,v in {{49,-178,27,10},{30,-160,14,18},{16,-112,23,4}} do
  local p=box(m,'CascadeRibbon',x,v[1],v[2],11,v[3],v[4],C.water,Enum.Material.Glass) p.Transparency=.22
  box(m,'CascadeWhitewater',x,v[1]-v[3]/2+.4,v[2]+v[4]/2+.1,12,.8,2,C.snow,Enum.Material.SmoothPlastic)
 end
 box(m,'LowerCascadePool',x,.25,-98,29,.4,17,C.water,Enum.Material.Glass)
 for _,dx in {-17,17} do rock(m,x+dx,0,-99,8,.15) end
 m.Parent=env task.wait()
end
-- Bespoke Alpine gateway cladding. Existing piers/openings and all connections stay put.
for _,gate in root.ThreeGates_NoGameplay:GetChildren() do
 local m=group('FinishedGateway_'..gate.Name) local center=gate.Name=='Center' local cx=gate.Name=='West' and -72 or gate.Name=='East' and 72 or 0 local w=center and 60 or 45 local top=center and 54 or 45
 for _,p in gate:GetChildren() do if p:IsA('BasePart') then p.Color=C.stone p.Material=Enum.Material.Cobblestone end end
 for _,sx in {-1,1} do
  local x=cx+sx*(w/2-2.5)
  box(m,'PierFoot',x,18,-133,7,4,11,C.dark,Enum.Material.Slate)
  box(m,'PierCapital',x,top-4,-133,7,2,11,C.light)
  box(m,'CedarPierInlay',x,30,-128.75,1.2,20,.45,C.wood,Enum.Material.Wood)
  box(m,'BrassInlay',x,30,-128.45,.23,16,.16,C.gold,Enum.Material.Metal)
  lamp(m,x,top-2,-133)
  beam(m,'CantileverBrace',Vector3.new(x,top-9,-127.8),Vector3.new(cx+sx*(w/2-10),top-1,-127.8),1.4,C.wood,Enum.Material.Wood)
 end
 box(m,'CedarEntablature',cx,top+.2,-133,w+6,2.4,11,C.wood,Enum.Material.Wood)
 box(m,'TealCornice',cx,top+1.8,-133,w+10,1,14,C.teal)
 box(m,'BrassCorniceEdge',cx,top+1.1,-125.9,w+10,.35,.25,C.gold,Enum.Material.Metal)
 for _,sx in {-1,1} do
  local a=Vector3.new(cx,top+10,-133) local b=Vector3.new(cx+sx*(w/2+7),top+2,-133)
  local mid=(a+b)/2 local len=(b-a).Magnitude
  part(m,'CrownedRoof',Vector3.new(len,1.4,15),mid,C.teal,Enum.Material.Slate,CFrame.new(mid)*CFrame.Angles(0,0,sx<0 and math.atan(8/(w/2+7)) or -math.atan(8/(w/2+7))))
  beam(m,'RoofBrassLine',a+Vector3.new(0,.8,7.6),b+Vector3.new(0,.8,7.6),.35,C.gold,Enum.Material.Metal)
 end
 local gem=box(m,'GatewayCrest',cx,top+5,-125,2.7,3.8,.65,C.water,Enum.Material.Neon) gem.CFrame*=CFrame.Angles(0,0,math.pi/4)
 m.Parent=env task.wait()
end
-- Hand-composed massif: overlapping irregular triangular arêtes, foothills and snow shoulders.
local peaks={{-830,255,-420,260,230},{-620,325,-470,280,250},{-385,405,-520,340,280},{-155,330,-480,260,230},{65,560,-620,380,330},{325,435,-530,330,290},{580,350,-475,290,250},{825,280,-420,260,220}}
for i,v in peaks do
 local m=group(string.format('AlpineMassif_%02d',i)) local x,h,z,w,d=table.unpack(v)
 for k=0,2 do
  local hh=h*(1-k*.16) local xx=x+(k-1)*w*.18 local zz=z+k*22 local ww=w*(.78-k*.1)
  for _,s in {-1,1} do
   local cf=CFrame.new(xx+s*ww/4,hh/2-8,zz)*CFrame.Angles(0,s<0 and -math.pi/2 or math.pi/2,0)
   part(m,'GraniteArete',Vector3.new(d,hh,ww/2),cf.Position,C.dark:Lerp(C.stone,.32+k*.19),Enum.Material.Rock,cf,false,'WedgePart')
   local snowH=hh*.23 local snowW=ww*.23
   local scf=CFrame.new(xx+s*snowW/4,hh-snowH/2-7,zz)*CFrame.Angles(0,s<0 and -math.pi/2 or math.pi/2,0)
   part(m,'SnowShoulder',Vector3.new(d+1,snowH,snowW/2),scf.Position,C.snow,Enum.Material.Snow,scf,false,'WedgePart')
  end
 end
 for j=-1,1 do rock(m,x+j*w*.27,40,z+d*.5,90+(j+1)*20,.2) end
 m.Parent=env task.wait()
end
-- Bright clear daylight, restrained atmospheric distance, no runtime effects or lights.
local l=game:GetService('Lighting') l.ClockTime=10.7 l.Brightness=2.5 l.Ambient=Color3.fromRGB(135,146,155) l.OutdoorAmbient=Color3.fromRGB(155,168,175) l.GlobalShadows=true
local atm=l:FindFirstChildOfClass('Atmosphere') or Instance.new('Atmosphere',l) atm.Density=.22 atm.Offset=.15 atm.Color=Color3.fromRGB(201,224,235) atm.Decay=Color3.fromRGB(135,164,180) atm.Haze=.8 atm.Glare=.12
env:SetAttribute('Step',3) env:SetAttribute('Scope','Environment review only; approved Step2 lodges protected')
return 'Step3 environment built; verify before save'
