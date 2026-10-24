-- Procedural draft models. All scenery is anchored and decorative details do not collide.
local A={}
function A.color(c) return Color3.fromRGB(c[1],c[2],c[3]) end
function A.part(parent,name,size,cf,color,material,shape,collide)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=collide==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end;p.Parent=parent;return p
end
function A.link(parent,name,a,b,width,color,material,collide)
 return A.part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material,nil,collide)
end
function A.label(p,text,offset)
 local b=Instance.new('BillboardGui');b.Name='Label';b.Size=UDim2.fromOffset(230,54);b.StudsOffset=Vector3.new(0,offset or 5,0);b.MaxDistance=115;b.AlwaysOnTop=false;b.Parent=p
 local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=Color3.fromRGB(255,246,220);l.TextStrokeTransparency=.45;l.Font=Enum.Font.GothamBold;l.TextSize=17;l.TextWrapped=true;l.Parent=b
end
function A.creature(parent,s,position,scale,stage)
 local m=Instance.new('Model');m.Name=s.name
 local C=require(game.ReplicatedStorage.MountainShared.Catalog);local k=C.kingdoms[s.kingdom]
 local primary=A.color(k.color);local accent=A.color(k.accent);local dark=primary:Lerp(Color3.new(0,0,0),.35)
 local S=scale*(if s.rarity=='Legendary' then 1 else 1+((stage or 1)-1)*.16);local shape=s.shape
 local function p(n,sz,pos,col,kind,rot)
  return A.part(m,n,sz*S,CFrame.new(position+pos*S)*(rot or CFrame.identity),col,Enum.Material.SmoothPlastic,kind or Enum.PartType.Ball)
 end
 local long=table.find({'fox','otter','dog','cat','deer','rhino','dragon','turtle','whale','serpent','worm'},shape)~=nil
 local floating=table.find({'moth','fish','shard','orb','jelly','ghost','bird','star'},shape)~=nil
 local body=p('Body',Vector3.new(3.2,if floating then 3.2 else 2.5,if long then 4.6 else 3),Vector3.new(0,2.6,0),primary)
 m.PrimaryPart=body
 local head=p('Face',Vector3.new(2.5,2.2,2.5),Vector3.new(0,3.3,if long then -2.1 else -1.3),primary:Lerp(accent,.3))
 for _,sign in ipairs({-1,1}) do
  p('Eye',Vector3.new(.4,.48,.25),Vector3.new(sign*.68,3.6,if long then -3.23 else -2.43),Color3.fromRGB(22,33,52))
  p('EyeLight',Vector3.new(.11,.13,.1),Vector3.new(sign*.68-.06,3.69,if long then -3.36 else -2.56),Color3.new(1,1,1))
 end
 local legs=s.legs or (if floating then 0 elseif shape=='beetle' then 6 elseif shape=='golem' or shape=='sprout' then 2 else 4)
 for i=1,legs do
  local side=if i%2==0 then 1 else -1;local z=(math.ceil(i/2)-(legs/2+1)/2)*1.6
  p('Foot',Vector3.new(.85,1.6,1.25),Vector3.new(side*1.2,1.1,z),dark)
 end
 if shape=='rabbit' or shape=='cat' or shape=='fox' or shape=='dog' or shape=='bear' then
  for _,sign in ipairs({-1,1}) do p('Ear',Vector3.new(.8,if shape=='rabbit' then 2.7 else 1.3,1),Vector3.new(sign*.9,4.7,-1.5),accent,nil,CFrame.Angles(0,0,sign*.18)) end
 end
 if shape=='moth' or shape=='bird' or shape=='dragon' or shape=='fish' or shape=='whale' then
  for _,sign in ipairs({-1,1}) do for wing=1,(if s.id=='pyralune' then 3 else 2) do
   p('Wing',Vector3.new(3,.35,2.3),Vector3.new(sign*2.5,2.8+wing*.35,wing*1.3-2),accent,nil,CFrame.Angles(0,sign*.4,sign*.3))
  end end
 end
 if long then p('Tail',Vector3.new(1.1,1.1,3.8),Vector3.new(0,2.7,3),accent,nil,CFrame.Angles(.35,0,.1)) end
 if shape=='deer' or shape=='rhino' or shape=='hedgehog' or shape=='dragon' or s.rarity=='Legendary' then
  for _,sign in ipairs({-1,1}) do for j=1,3 do
   p('Crest',Vector3.new(.45,1.8+j*.3,.55),Vector3.new(sign*(.4+j*.35),4.2+j*.5,-1.3),accent,Enum.PartType.Block,CFrame.Angles(.2,0,sign*.45))
  end end
 end
 if shape=='turtle' or shape=='beetle' or shape=='rock' then p('Armor',Vector3.new(3.7,1.8,3.8),Vector3.new(0,3.8,.5),accent) end
 if shape=='shard' or shape=='orb' or shape=='jelly' or shape=='star' or shape=='golem' then
  for j=1,(if s.id=='zenthari' then 4 else 6) do local a=j*math.pi/3
   p('Orbit',Vector3.new(.7,1.7,.7),Vector3.new(math.cos(a)*3,3.3+math.sin(a)*2,0),accent,Enum.PartType.Block,CFrame.Angles(0,0,a))
  end
 end
 -- Each species has a different silhouette signature, beyond its biome palette.
 for j=1,(s.variant or 1) do
  local a=j*2.399;p('Signature',Vector3.new(.4,.7+(s.variant or 1)*.12,.4),Vector3.new(math.cos(a)*1.25,4.2,math.sin(a)*1.1),accent,Enum.PartType.Block,CFrame.Angles(0,a,.35))
 end
 if (stage or 1)>=2 and s.rarity~='Legendary' then p('EvolvedMane',Vector3.new(3.2,1.6,2),Vector3.new(0,3.3,-.9),accent) end
 if (stage or 1)>=3 and s.rarity~='Legendary' then
  for _,sign in ipairs({-1,1}) do p('AscendedCrest',Vector3.new(.6,3.6,1),Vector3.new(sign*1.4,5,-.7),accent,Enum.PartType.Block,CFrame.Angles(0,0,sign*.5)) end
 end
 m.Parent=parent;return m
end
function A.tree(parent,pos,k,rng)
 local m=Instance.new('Model');m.Name='Grown_'..k.id
 local h=rng:NextNumber(13,23);local brown=Color3.fromRGB(91,72,63)
 local trunk=A.link(m,'Trunk',pos,pos+Vector3.new(1,h,0),2.1,brown,Enum.Material.Wood)
 for j=1,5 do
  local a=j*2.4;local endP=pos+Vector3.new(math.cos(a)*h*.35,h*(.6+j*.065),math.sin(a)*h*.35)
  A.link(m,'Branch',pos+Vector3.new(0,h*.5,0),endP,1,brown,Enum.Material.Wood)
  local leaf=A.part(m,'Canopy',Vector3.new(9,5,8)*rng:NextNumber(.8,1.3),CFrame.new(endP),A.color(if k.id=='blossom' then k.accent else k.color):Lerp(Color3.new(1,1,1),rng:NextNumber(0,.12)),Enum.Material.Grass,Enum.PartType.Ball)
  if k.id=='inferno' then leaf.Transparency=.75;leaf.Size=Vector3.new(2,2,2) end
 end
 m.Parent=parent;return trunk
end
function A.crystal(parent,pos,k,size)
 local m=Instance.new('Model');m.Name='MineralCluster'
 for i=1,4 do
  local p=A.part(m,'Facet',Vector3.new(size*.3,size*(.6+i*.2),size*.35),CFrame.new(pos+Vector3.new((i-2.5)*size*.25,size*.5,0))*CFrame.Angles(0,i,.15*(i-2)),A.color(k.accent),Enum.Material.Glass,nil,false)
  p.Reflectance=.12;p.Transparency=.12
 end
 m.Parent=parent
end
return A
