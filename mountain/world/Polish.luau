-- Additive, idempotent scenery pass: no terrain writes and no gameplay colliders.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local P={}
local function plant(parent,pos,k,seed,blend)
 local green=A.color(k.color):Lerp(Color3.fromRGB(62,108,78),.4)
 local flower=A.color(k.accent):Lerp(blend or A.color(k.accent),.25)
 for stem=1,3 do
  local a=seed+stem*2.4;local base=pos+Vector3.new(math.cos(a)*1.2,0,math.sin(a)*1.2)
  local tip=base+Vector3.new(math.cos(a)*.4,1.8+stem*.4,math.sin(a)*.4)
  A.link(parent,'Stem',base,tip,.12,green,Enum.Material.Grass)
  for side=-1,1,2 do
   for leaf=1,3 do
    local center=base:Lerp(tip,leaf*.2)+Vector3.new(side*.6,0,0)
    A.part(parent,'FernFrond',Vector3.new(1.6,.16,.55),CFrame.new(center)*CFrame.Angles(.15,a,side*.4),green:Lerp(flower,.08*leaf),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   end
  end
  if k.id=='blossom' or k.id=='astral' then
   for j=1,5 do local angle=j*math.pi*2/5
    A.part(parent,'Petal',Vector3.new(.65,.16,.38),CFrame.new(tip+Vector3.new(math.cos(angle)*.3,0,math.sin(angle)*.3))*CFrame.Angles(0,-angle,0),flower,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   end
   A.part(parent,'Pollen',Vector3.new(.25,.22,.25),CFrame.new(tip+Vector3.new(0,.08,0)),Color3.fromRGB(255,217,139),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  end
 end
end
function P.apply(world)
 if world:GetAttribute('ArtPassRevision')==1 then return end
 assert(world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Isolated mountain only')
 -- Keep the old interaction root pose and metadata exactly, even for wild prompts.
 for _,old in ipairs(world.Encounters:GetChildren()) do
  local index=tonumber(old.Name:match('Guardian_(%d+)'))
  local species=if index then C.guardians[index] else C.byId[string.lower(old.Name)]
  assert(species,'Unknown encounter '..old.Name)
  local fresh=A.creature(nil,species,Vector3.zero,if index then 4.5 else 1.3,1)
  fresh.Name=old.Name;fresh:PivotTo(old:GetPivot())
  for name,value in pairs(old:GetAttributes()) do fresh:SetAttribute(name,value) end
  for name,value in pairs(old.PrimaryPart:GetAttributes()) do fresh.PrimaryPart:SetAttribute(name,value) end
  for _,child in ipairs(old.PrimaryPart:GetChildren()) do if not child:IsA('DataModelMesh') then child:Clone().Parent=fresh.PrimaryPart end end
  local label=fresh.PrimaryPart:FindFirstChild('Label')
  if label then local text=label:FindFirstChildOfClass('TextLabel');if text then text.Text=species.name..' / '..species.rarity end end
  fresh.Parent=world.Encounters;old:Destroy()
 end
 local dress=Instance.new('Folder');dress.Name='ArtPassScenery';dress.Parent=world
 for _,p in ipairs(world:GetDescendants()) do if p:IsA('ProximityPrompt') then
  local kind=p.Parent:GetAttribute('Kind')
  if kind=='Checkpoint' then p.ActionText='Rest / extract eggs'
  elseif kind=='Discovery' then p.ActionText='Discover / gather' end
 end end
 -- Repair legacy decorative ellipsoids and turn square wooden links into rounded roots.
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('Part') and not p.CanCollide and not p:IsDescendantOf(world.Encounters) then
   if p.Shape==Enum.PartType.Ball and not p:FindFirstChildOfClass('SpecialMesh') then
    p.Shape=Enum.PartType.Block;local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
   end
   if (p.Name=='Trunk' or p.Name=='Branch' or p.Name=='AncientRoot') and p.Shape~=Enum.PartType.Cylinder then
    local size=p.Size;p.Size=Vector3.new(size.Z,size.Y,size.X);p.CFrame*=CFrame.Angles(0,math.pi/2,0);p.Shape=Enum.PartType.Cylinder
   end
  end
 end
 for ki,k in ipairs(C.kingdoms) do
  local group=Instance.new('Folder');group.Name=k.id;group.Parent=dress
  for _,altar in ipairs(world.Interactions:GetChildren()) do
   if altar:GetAttribute('Kind')=='Guardian' and altar:GetAttribute('Kingdom')==ki then
    local label=altar:FindFirstChild('Label');local text=label and label:FindFirstChildOfClass('TextLabel')
    if text then text.Text=k.landmarks[1] end
   end
  end
  local region=world:FindFirstChild(k.name)
  local floor=region:FindFirstChild('ArenaFloor')
  local signature=region:FindFirstChild(k.landmarks[1]..'_Signature')
  if signature and not signature:GetAttribute('BackdropOriented') then
   -- Guardians face -Z; their non-colliding throne/falls/mirror belong behind them.
   local center=floor.Position+Vector3.new(0,2.5,0)
   local frame=CFrame.new(center)
   signature:PivotTo(frame*CFrame.Angles(0,math.pi,0)*frame:Inverse()*signature:GetPivot())
   signature:SetAttribute('BackdropOriented',true)
  end
  for _,column in ipairs(region:GetChildren()) do if column.Name=='ArenaColumn' then
   local top=column.Position+Vector3.new(0,column.Size.Y/2,0)
   A.part(group,'CarvedCapital',Vector3.new(4.5,.7,4.5),CFrame.new(top),A.color(k.rock):Lerp(Color3.fromRGB(236,222,194),.4),Enum.Material.Marble)
   A.part(group,'ColumnCollar',Vector3.new(3.6,.5,3.6),CFrame.new(top-Vector3.new(0,1.1,0)),A.color(k.accent):Lerp(Color3.fromRGB(218,198,151),.5),Enum.Material.Sandstone)
  end end
  for beat=1,14 do
   local t=(beat-.35)/15;local q=C.route(ki,t)
   local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
   -- Inside shoulder: 11+ studs off the 16-stud-wide route; outside edge remains readable.
   local pos=Vector3.new(q.x,q.y,q.z)-outward*13
   local stone=A.color(k.rock)
   for layer=1,3 do
    local slab=A.part(group,'WeatheredStratum',Vector3.new(6-layer*.6,.8,3.8),CFrame.new(pos+Vector3.new(0,(layer-1)*.6-.6,0))*CFrame.Angles(.04,q.angle+.25,layer*.025),stone:Lerp(Color3.fromRGB(223,213,192),layer*.06),Enum.Material[k.material])
    slab:SetAttribute('ArtOnly',true)
   end
   local nextColor=if t>.8 and C.kingdoms[ki+1] then A.color(C.kingdoms[ki+1].accent) else nil
   if ki==1 or ki==2 or ki==6 then plant(group,pos+Vector3.new(0,1,0),k,beat,nextColor)
   elseif ki==3 then
    for j=1,7 do local a=j*math.pi*2/7
     A.part(group,'DesertAgave',Vector3.new(.35,3,1),CFrame.new(pos+Vector3.new(math.cos(a),1.7,math.sin(a)))*CFrame.Angles(math.sin(a)*.6,0,math.cos(a)*.6),Color3.fromRGB(113,146,126),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    end
   elseif ki==4 then A.crystal(group,pos+Vector3.new(0,1,0),k,3.5)
   else
    for j=1,3 do A.part(group,'BasaltShard',Vector3.new(.7,2+j,.8),CFrame.new(pos+Vector3.new(j-2,1+j*.3,0))*CFrame.Angles(0,j,.2),stone:Lerp(Color3.fromRGB(143,101,82),.3),Enum.Material.Basalt) end
   end
  end
  task.wait()
 end
 world:SetAttribute('ArtPassRevision',1)
end
return P
