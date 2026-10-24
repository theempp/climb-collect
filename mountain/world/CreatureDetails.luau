-- Authored silhouette layers. Dimensions are in unscaled creature space.
local D={}
function D.decorate(A,m,s,origin,S)
 local k=require(game.ReplicatedStorage.MountainShared.Catalog).kingdoms[s.kingdom]
 local base=A.color(k.color);local accent=A.color(k.accent)
 local ivory=Color3.fromRGB(250,235,207);local ink=Color3.fromRGB(31,38,64)
 local function part(name,size,pos,color,rotation,shape,role,pivot,phase)
  local p=A.part(m,name,size*S,CFrame.new(origin+pos*S)*(rotation or CFrame.identity),color,Enum.Material.SmoothPlastic,shape or Enum.PartType.Ball)
  if role then p:SetAttribute('MotionRole',role);p:SetAttribute('MotionPivot',m.PrimaryPart.CFrame:PointToObjectSpace(origin+(pivot or pos)*S));p:SetAttribute('MotionPhase',phase or 0) end
  return p
 end
 local function petal(name,pos,size,color,tilt,role,pivot,phase)
  return part(name,size,pos,color,CFrame.Angles(tilt.X,tilt.Y,tilt.Z),nil,role,pivot,phase)
 end
 local long=table.find({'fox','otter','dog','cat','deer','rhino','dragon','turtle','whale','serpent','worm'},s.shape)~=nil
 local faceZ=if long then -2.1 else -1.3
 if s.rarity=='Legendary' then
  for _,p in ipairs(m:GetChildren()) do if p.Name=='Crest' or p.Name=='Signature' then p:Destroy() end end
 end
 -- Overlapping cheek/muzzle volumes and brows give the face a readable expression.
 part('Muzzle',Vector3.new(1.55,.85,.8),Vector3.new(0,2.95,faceZ-1),ivory)
 part('Nose',Vector3.new(.42,.28,.27),Vector3.new(0,3.19,faceZ-1.43),ink)
 for _,side in ipairs({-1,1}) do
  part('Cheek',Vector3.new(.65,.42,.25),Vector3.new(side*.91,3.22,faceZ-1.08),accent)
  petal('Brow',Vector3.new(side*.68,3.94,faceZ-1.11),Vector3.new(.7,.16,.23),base:Lerp(ink,.35),Vector3.new(0,0,side*-.12))
 end
 local footIndex=0
 for _,p in ipairs(m:GetChildren()) do
  if p:IsA('BasePart') then
   if p.Name=='Foot' then
    footIndex+=1;local offset=(p.Position-origin)/S
    part('Haunch',Vector3.new(1.1,2.1,1.25),Vector3.new(offset.X,1.4,offset.Z),base)
    p.Size=Vector3.new(.95,.8,1.5)*S;p.CFrame=CFrame.new(origin+Vector3.new(offset.X,.4,offset.Z-.12)*S)
    p:SetAttribute('MotionRole','Foot');p:SetAttribute('MotionPivot',m.PrimaryPart.CFrame:PointToObjectSpace(origin+Vector3.new(offset.X,1.8,offset.Z)*S));p:SetAttribute('MotionPhase',footIndex*math.pi)
   elseif p.Name=='Wing' then
    local side=if p.Position.X>origin.X then 1 else -1
    p:SetAttribute('MotionRole','Wing');p:SetAttribute('MotionPivot',m.PrimaryPart.CFrame:PointToObjectSpace(origin+Vector3.new(side*1.2,3,0)*S));p:SetAttribute('MotionPhase',side)
   elseif p.Name=='Tail' or p.Name=='Ear' then
    p:SetAttribute('MotionRole',p.Name);p:SetAttribute('MotionPivot',m.PrimaryPart.CFrame:PointToObjectSpace(p.Position));p:SetAttribute('MotionPhase',p.Position.X-origin.X)
   end
  end
 end
 if s.id=='floravelle' or s.id=='caeloryn' then
  local cosmic=s.id=='caeloryn'
  -- Petals/locks follow the neck, with a narrow inner ruff and long outer layers.
  for layer=1,2 do for j=1,11 do
   local a=j*math.pi*2/11;local r=1.25+layer*.35
   local col=if cosmic then Color3.fromRGB(46+layer*12,57+layer*10,116+layer*16) else accent:Lerp(ivory,(j%3)*.18)
   petal(if cosmic then 'CelestialMane' else 'SovereignPetal',Vector3.new(math.cos(a)*r,3.15+math.sin(a)*r,faceZ+.7+layer*.4),Vector3.new(.85,2+layer*.7,.32),col,Vector3.new(.2,0,a-math.pi/2),'Mane',Vector3.new(0,3.15,faceZ+.6),a)
  end end
  for _,side in ipairs({-1,1}) do
   local previous=Vector3.new(side*.7,4.1,faceZ)
   for j=1,4 do
    local tip=Vector3.new(side*(.7+j*.52),4.1+j*.85,faceZ+j*.15)
    A.link(m,'AntlerStem',origin+previous*S,origin+tip*S,(.36-j*.055)*S,if cosmic then accent else ivory)
    local tine=tip+Vector3.new(side*.25,.75,-.55)
    A.link(m,'AntlerTine',origin+tip*S,origin+tine*S,.14*S,if cosmic then ivory else accent)
    if cosmic then part('SuspendedStar',Vector3.new(.22,.22,.22),tip+Vector3.new(side*.5,-.35,-.3),ivory,nil,Enum.PartType.Ball,'Orbit',Vector3.new(0,4,faceZ),j) end
    previous=tip
   end
  end
 elseif s.id=='aquarune' then
  for _,side in ipairs({-1,1}) do for j=1,5 do
   local fin=petal('TidalFin',Vector3.new(side*(1.4+j*.2),2.9,1+j*.35),Vector3.new(.35,1.3+j*.3,2),accent:Lerp(ivory,j*.06),Vector3.new(.35,side*.35,side*.7),'Fin',Vector3.new(side*1.4,2.7,1),side+j*.2)
   fin.Transparency=.22
  end end
  for j=1,5 do petal('SapphireCrest',Vector3.new(0,4.2+j*.12,faceZ+(j-1)*.6),Vector3.new(.5,1.8-j*.2,.85),Color3.fromRGB(49,103,194),Vector3.new(.25,0,0)) end
 elseif s.id=='zenthari' then
  m.Body.Size=Vector3.new(3.8,3.4,3)*S
  for _,p in ipairs(m:GetChildren()) do if p.Name=='Orbit' or p.Name=='Crest' then p:Destroy() end end
  for _,side in ipairs({-1,1}) do for row=1,2 do
   local pos=Vector3.new(side*(2.4+row*.25),4.9-row*2,0)
   part('FloatingFist',Vector3.new(1.65,1.6,1.65),pos,accent,CFrame.Angles(.1,side*.25,side*.18),Enum.PartType.Block,'Fist',pos,side+row)
   for knuckle=1,3 do part('GoldenKnuckle',Vector3.new(.35,.5,.4),pos+Vector3.new((knuckle-2)*.45,.1,-.8),ivory,nil,nil,'Fist',pos,side+row) end
  end end
  for j=1,9 do local a=j*math.pi/5
   petal('SunstoneCrown',Vector3.new(math.cos(a)*1.25,5+math.sin(a)*.3,-1.2),Vector3.new(.38,1.5+j%2*.6,.4),accent,Vector3.new(0,a,math.cos(a)*-.3))
  end
 elseif s.id=='veylith' then
  m.Body.Size=Vector3.new(2.5,4.1,2.5)*S
  for _,p in ipairs(m:GetChildren()) do if p.Name=='Orbit' or p.Name=='Crest' then p:Destroy() end end
  part('CrystalCrown',Vector3.new(1.6,2.8,1.6),Vector3.new(0,5,0),accent,CFrame.Angles(0,math.pi/4,0),Enum.PartType.Block)
  for j=1,6 do local a=j*math.pi/3;local pos=Vector3.new(math.cos(a)*3.2,3.3+math.sin(a)*2.7,.5)
   part('AmethystSatellite',Vector3.new(.6,1.9,.7),pos,accent:Lerp(ivory,j%2*.2),CFrame.Angles(0,.6,a*.25),Enum.PartType.Block,'Orbit',Vector3.new(0,3.3,.5),a)
  end
 elseif s.id=='pyralune' then
  m.Body.Color=Color3.fromRGB(177,65,45);m.Face.Color=Color3.fromRGB(234,116,55)
  part('EmberHeart',Vector3.new(.9,1.1,.35),Vector3.new(0,2.3,-1.5),Color3.fromRGB(255,224,130))
  for _,side in ipairs({-1,1}) do for wing=1,3 do for feather=1,3 do
   petal('FlameFeather',Vector3.new(side*(2+feather*.5),2.5+wing*.4,(wing-2)*1.3),Vector3.new(1.6,.28,.7),accent:Lerp(ivory,feather*.12),Vector3.new(0,side*.4,side*.35),'Wing',Vector3.new(side*1.2,3,0),side)
  end end end
  for j=1,7 do petal('LivingFireCrown',Vector3.new((j-4)*.38,4.7+math.sin(j)*.2,-1),Vector3.new(.4,1.2+j%3*.3,.5),accent,Vector3.new(.2,0,(j-4)*-.14),'Mane',Vector3.new(0,4,-1),j) end
 else
  -- Species families keep their own body plans; named features add more than color.
  if s.shape=='deer' then
   for _,side in ipairs({-1,1}) do for j=1,3 do
    petal('AntlerLeaf',Vector3.new(side*(.8+j*.35),4.6+j*.4,-1.3),Vector3.new(.35,1.1,.65),accent,Vector3.new(0,side*.5,side*.6))
   end end
  elseif s.shape=='rabbit' then
   for _,side in ipairs({-1,1}) do petal('InnerEar',Vector3.new(side*.9,4.8,-2),Vector3.new(.4,1.85,.18),ivory,Vector3.new(0,0,side*.18),'Ear',Vector3.new(side*.9,4.1,-1.5),side) end
  elseif s.shape=='fox' or s.shape=='cat' or s.shape=='dog' then
   for _,side in ipairs({-1,1}) do for j=1,3 do petal('CheekTuft',Vector3.new(side*(1+j*.13),3.2-j*.18,faceZ),Vector3.new(.8,.3,.7),ivory,Vector3.new(0,side*.4,side*.3)) end end
  elseif s.shape=='turtle' or s.shape=='beetle' then
   for j=1,5 do part('ShellPlate',Vector3.new(.8,.4,1.2),Vector3.new((j%3-1)*.95,4.5,math.floor(j/3)*1.3-.6),base:Lerp(ivory,.3)) end
  end
 end
 -- Capture immutable rest transforms after geometry is complete. Root is never animated locally.
 for _,p in ipairs(m:GetChildren()) do if p:IsA('BasePart') and p~=m.PrimaryPart then p:SetAttribute('RestLocal',m.PrimaryPart.CFrame:ToObjectSpace(p.CFrame)) end end
 m:SetAttribute('ArtRevision',2);m:SetAttribute('Species',s.id);m:SetAttribute('CreatureScale',S)
end
return D
