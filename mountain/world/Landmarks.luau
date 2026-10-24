local A=require(script.Parent.Art)
local L={}
function L.build(parent,k,index,center)
 local m=Instance.new('Model');m.Name=k.landmarks[1]..'_Signature'
 local stone=A.color(k.rock);local light=A.color(k.accent)
 local function p(name,size,offset,color,material,shape,rot)
  return A.part(m,name,size,CFrame.new(center+offset)*(rot or CFrame.identity),color or stone,material or Enum.Material.Rock,shape,false)
 end
 if index==1 then
  for j=1,16 do
   local a=j*math.pi/8;local pos=Vector3.new(math.cos(a)*35,0,math.sin(a)*35)
   p('GardenTerrace',Vector3.new(9,2,8),pos+Vector3.new(0,1,0),Color3.fromRGB(127,168,104),Enum.Material.Grass)
   for n=1,3 do p('ColosseumBlossom',Vector3.new(2,.8,2),pos+Vector3.new(math.cos(n*2)*2,2.4,math.sin(n*2)*2),light,Enum.Material.Grass,Enum.PartType.Ball) end
  end
  for _,sign in ipairs({-1,1}) do
   local base=center+Vector3.new(sign*28,0,-20)
   for n=1,5 do local next=base+Vector3.new(-sign*3,7,math.sin(n)*2);A.link(m,'AncientRoot',base,next,3.5,Color3.fromRGB(105,87,66),Enum.Material.Wood);base=next end
  end
 elseif index==2 then
  for j=1,5 do
   local offset=Vector3.new((j-3)*12,0,-36)
   p('WatercarvedCrest',Vector3.new(9,40+j%2*12,10),offset+Vector3.new(0,18,0),stone,Enum.Material.Slate)
   local water=p('HeartCascade',Vector3.new(7,36+j%2*12,1),offset+Vector3.new(0,19,6),light,Enum.Material.Glass);water.Transparency=.3
   p('TurquoisePool',Vector3.new(14,.6,12),offset+Vector3.new(0,.5,9),light,Enum.Material.Glass,Enum.PartType.Ball)
  end
 elseif index==3 then
  for tier=1,4 do p('SolarThroneStep',Vector3.new(37-tier*6,3,25-tier*3),Vector3.new(0,tier*3-1.5,-23),Color3.fromRGB(220-tier*8,175-tier*5,109),Enum.Material.Sandstone) end
  p('RoyalBackrest',Vector3.new(15,20,4),Vector3.new(0,19,-30),light,Enum.Material.Sandstone)
  for j=1,16 do local a=j*math.pi/8
   p('SolarCrownRay',Vector3.new(1.2,9,1.2),Vector3.new(math.cos(a)*13,32+math.sin(a)*13,-33),light,Enum.Material.Metal,nil,CFrame.Angles(0,0,a-math.pi/2))
  end
 elseif index==4 then
  for j=1,6 do local a=j*math.pi/3
   A.crystal(m,center+Vector3.new(math.cos(a)*32,0,math.sin(a)*32),k,13+j%2*5)
  end
  for j=1,20 do local a=j*math.pi/10
   p('ObservatoryOrbit',Vector3.new(1.2,1.2,11),Vector3.new(math.cos(a)*32,28+math.sin(a)*8,math.sin(a)*32),light,Enum.Material.Metal,nil,CFrame.Angles(.25,-a,0))
  end
  p('Mirror',Vector3.new(18,22,1),Vector3.new(0,15,-36),Color3.fromRGB(157,166,214),Enum.Material.Glass);m.Mirror.Reflectance=.5
 elseif index==5 then
  for j=1,8 do local a=j*math.pi/4
   p('VolcanicHorn',Vector3.new(5,28,5),Vector3.new(math.cos(a)*32,12,math.sin(a)*32),stone,Enum.Material.Basalt,nil,CFrame.Angles(math.sin(a)*.3,0,math.cos(a)*-.3))
   p('MagmaFissure',Vector3.new(1.2,18,1.2),Vector3.new(math.cos(a)*31,9,math.sin(a)*31),light,Enum.Material.Neon)
  end
  for j=1,20 do local a=j*math.pi/10;p('CrucibleRim',Vector3.new(7,2,3),Vector3.new(math.cos(a)*19,1,math.sin(a)*19),Color3.fromRGB(138,76,55),Enum.Material.Basalt,nil,CFrame.Angles(0,-a,0)) end
 else
  for j=1,8 do local a=j*math.pi/4
   p('AstralSpire',Vector3.new(3,29+j%2*10,3),Vector3.new(math.cos(a)*34,15,math.sin(a)*34),Color3.fromRGB(216,229,244),Enum.Material.Marble)
   A.crystal(m,center+Vector3.new(math.cos(a)*34,32,math.sin(a)*34),k,6)
  end
  for ring=1,2 do for j=1,24 do local a=j*math.pi/12
   p('CelestialOrbit',Vector3.new(.8,.8,9),Vector3.new(math.cos(a)*(25+ring*6),39+math.sin(a)*ring*5,math.sin(a)*(25+ring*6)),light,Enum.Material.Metal,nil,CFrame.Angles(0,-a,0))
  end end
 end
 m.Parent=parent
end

function L.branch(parent,k,index,branch,center)
 local m=Instance.new('Model');m.Name=k.landmarks[branch+1]..'_Composition'
 local stone=A.color(k.rock);local light=A.color(k.accent)
 local function p(name,size,offset,color,material,shape,rot)
  return A.part(m,name,size,CFrame.new(center+offset)*(rot or CFrame.identity),color or stone,material or Enum.Material.Rock,shape,false)
 end
 if index==1 then
  for j=1,8 do local a=j*math.pi/4
   p('MossTerrace',Vector3.new(5,1,4),Vector3.new(math.cos(a)*11,.4,math.sin(a)*11),Color3.fromRGB(115,161,94),Enum.Material.Grass)
   p('GardenBloom',Vector3.new(2,.7,2),Vector3.new(math.cos(a)*11,1.3,math.sin(a)*11),light,Enum.Material.Grass,Enum.PartType.Ball)
  end
  if branch==2 then for j=1,4 do p('FallenRuins',Vector3.new(3,5+j,3),Vector3.new(-11+j*5,3,-11),stone,Enum.Material.Marble,nil,CFrame.Angles(0,0,(j-2)*.12)) end end
 elseif index==2 then
  local water=p('HiddenWaterCurtain',Vector3.new(21,13,.5),Vector3.new(0,6,-5),light,Enum.Material.Glass);water.Transparency=.62
  for j=1,9 do
   A.link(m,'HangingVine',center+Vector3.new(j*3-15,14,-3),center+Vector3.new(j*3-15,4+j%3,-3),.25,Color3.fromRGB(61,125,89),Enum.Material.Grass)
   p('FernBed',Vector3.new(4,2,3),Vector3.new(j*3-15,1,12),Color3.fromRGB(69,141,102),Enum.Material.Grass,Enum.PartType.Ball)
  end
 elseif index==3 then
  if branch==1 then
   local pool=p('OasisWater',Vector3.new(14,.3,13),Vector3.new(0,.2,5),Color3.fromRGB(75,177,179),Enum.Material.Glass,Enum.PartType.Ball);pool.Transparency=.25
   for _,s in ipairs({-1,1}) do
    A.link(m,'PalmTrunk',center+Vector3.new(s*11,0,-7),center+Vector3.new(s*9,16,-7),.8,Color3.fromRGB(121,92,58),Enum.Material.Wood)
    for leaf=1,6 do p('PalmLeaf',Vector3.new(1,1,10),Vector3.new(s*9,16,-7),Color3.fromRGB(86,143,94),Enum.Material.Grass,Enum.PartType.Ball,CFrame.Angles(.3,leaf*math.pi/3,0)) end
   end
  else for j=1,5 do p('DawnObelisk',Vector3.new(2,5+j*2,2),Vector3.new(j*5-15,2.5+j,-10),light,Enum.Material.Sandstone) end end
 elseif index==4 then
  for j=1,7 do A.crystal(m,center+Vector3.new(math.cos(j)*12,0,math.sin(j)*12),k,7+j%3*3) end
  if branch==2 then for j=1,6 do local mirror=p('ReflectionSlab',Vector3.new(4,.3,8),Vector3.new(j*4-14,.3,3),light,Enum.Material.Glass);mirror.Reflectance=.45 end end
 elseif index==5 then
  for _,s in ipairs({-1,1}) do p('TemplePillar',Vector3.new(3,17,3),Vector3.new(s*11,8,-9),stone,Enum.Material.Basalt) end
  p('TempleLintel',Vector3.new(27,3,5),Vector3.new(0,17,-9),stone,Enum.Material.Basalt)
  local basin=p('EmberBasin',Vector3.new(8,.3,8),Vector3.new(0,.3,9),light,Enum.Material.Neon,Enum.PartType.Ball)
  local at=Instance.new('Attachment');at.Parent=basin;local ember=Instance.new('ParticleEmitter');ember.Rate=3;ember.Lifetime=NumberRange.new(1.2,2);ember.Speed=NumberRange.new(2,4);ember.Size=NumberSequence.new(.12);ember.Color=ColorSequence.new(light);ember.LightEmission=.5;ember.Parent=at
 else
  for j=1,12 do local a=j*math.pi/6
   p('StarGardenStone',Vector3.new(2,.8,2),Vector3.new(math.cos(a)*12,.5,math.sin(a)*12),Color3.fromRGB(224,231,242),Enum.Material.Marble)
   A.crystal(m,center+Vector3.new(math.cos(a)*12,1,math.sin(a)*12),k,2.5)
  end
  if branch==2 then for j=1,12 do local a=j*math.pi/6;p('GateConstellation',Vector3.new(2,2,2),Vector3.new(math.cos(a)*12,14+math.sin(a)*12,-6),light,Enum.Material.Glass,Enum.PartType.Ball) end end
 end
 m.Parent=parent
end
return L
