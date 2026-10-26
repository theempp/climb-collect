-- Open-face review topology. Distances and hazard tuning are provisional.
local F={version=1}
local function point(x,y,z) return {x=x,y=y,z=z} end
function F.originalLayout()
 local g={sections={},eggs={},restPoints={},exit={x=4096,y=24,z=-166,width=180,height=24,depth=18}}
 for k=1,6 do
  local z=-210-(k-1)*200;local y=16+(k-1)*64
  local s={id=k,requiredWins=0,entry=point(4096,y,z),terrace=point(4096,y+64,z-160),finish=point(4096,y+64,z-200),escape={x=4096,width=32},bounds={minX=3924,maxX=4268,minZ=z-198,maxZ=z-2,minY=y-20,maxY=y+100},hazard={x=4168,y=y+64,z=z-154,halfWidth=16}}
  s.normalAltar=point(4068,y+65,z-181);s.trialAltar=point(4215,y+65,z-181)
  table.insert(g.sections,s)
  for i,x in ipairs({-58,58}) do table.insert(g.eggs,{id='raid:'..k..':'..i,section=k,position=point(4096+x,y+64,z-174)}) end
  for _,r in ipairs({{'entrance',point(4096,y,z-2)},{'recovery',point(4000,y+64,z-136)},{'guardian',point(4096,y+64,z-184)}}) do table.insert(g.restPoints,{id=k..':'..r[1],section=k,position=r[2]}) end
 end
 return g
end
function F.layout()
 local G=if game then require(game.ReplicatedStorage.MountainShared.CompactGeometry) else require('../shared/CompactGeometry')
 return G.layout(F.originalLayout())
end
function F.build()
 assert(not workspace:FindFirstChild('ImpossibleMountain'),'Build only into a new review with its old mountain removed')
 local C=require(game.ReplicatedStorage.MountainShared.Catalog)
 local Config=require(game.ReplicatedStorage.MountainShared.RaidConfig)
 local A=require(script.Parent.Art)
 local function v(p) return Vector3.new(p.x,p.y,p.z) end
 local function folder(parent,name) local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
 local root=folder(workspace,'ImpossibleMountain');root:SetAttribute('FreeClimbVersion',F.version);root:SetAttribute('GeneratorVersion',C.version)
 local checkpoints=folder(root,'Checkpoints');local interactions=folder(root,'Interactions');local dynamics=folder(root,'Dynamics');local encounters=folder(root,'Encounters')
 local bounds=folder(root,'GuardianBounds');local exits=folder(root,'SanctuaryExits');local meta=folder(root,'Sections')
 local g=F.originalLayout();local rng=Random.new(42961)
 -- New-review terrain authority: only the open face beyond the sanctuary bridge.
 -- The exact historical terrain remains in the immutable baseline and backup.
 -- Eight-stud slices clear above the authored walk surface, with voxel-aligned bounds.
 for _,s in ipairs(g.sections) do for row=0,24 do
  local z=s.entry.z-row*8-4;local surface=s.entry.y+64*math.min(1,row*8/120)
  local bottom=math.floor((surface-12)/4)*4
  workspace.Terrain:FillBlock(CFrame.new(4096,(bottom+1024)/2,z),Vector3.new(384,1024-bottom,8),Enum.Material.Air)
 end end
 root:SetAttribute('TerrainAuthority','FreeClimb v1: x3904..4288 z-1410..-210, stepped floor to y1024; no sanctuary model edits')
 local function part(parent,name,pos,size,color,material,collide)
  return A.part(parent,name,size,CFrame.new(pos),color,material,nil,collide)
 end
 local function prompt(p,kind,k,id,text)
  p:SetAttribute('Kind',kind);p:SetAttribute('Kingdom',k);p:SetAttribute('Id',id)
  local q=Instance.new('ProximityPrompt');q.ActionText=text;q.ObjectText=p.Name;q.HoldDuration=0;q.MaxActivationDistance=12;q.RequiresLineOfSight=false;q.Parent=p
 end
 local function ramp(parent,name,a,b,width,color,thickness)
  local t=thickness or 6
  return A.part(parent,name,Vector3.new(width,t,(b-a).Magnitude+3),CFrame.lookAt((a+b)/2-Vector3.new(0,t/2,0),b-Vector3.new(0,t/2,0)),color,Enum.Material.Rock,nil,true)
 end
 local bridge=part(root,'SanctuaryApproach',Vector3.new(4096,13,-171),Vector3.new(180,6,82),Color3.fromRGB(179,174,151),Enum.Material.Cobblestone,true)
 local e=g.exit;local exit=part(exits,'SanctuaryExit',v(e),Vector3.new(e.width,e.height,e.depth),Color3.fromRGB(153,234,182),Enum.Material.Neon,false);exit.Transparency=1
 for _,x in ipairs({-85,85}) do local p=part(root,'ExitLantern',Vector3.new(4096+x,23,-166),Vector3.new(3,14,3),Color3.fromRGB(188,227,185),Enum.Material.Marble,true);A.label(p,'SAFE RETURN',10) end
 for k,s in ipairs(g.sections) do
  local c=C.kingdoms[k];local region=folder(root,c.name);region:SetAttribute('Kingdom',k)
  local entry=v(s.entry);local terrace=v(s.terrace);local top=Vector3.new(entry.X,terrace.Y,entry.Z-120)
  local stone=A.color(c.rock);local accent=A.color(c.accent);local plant=A.color(c.color)
  local marker=part(meta,tostring(k),terrace,Vector3.new(1,1,1),accent,nil,false);marker.Transparency=1;marker:SetAttribute('RequiredWins',0);marker:SetAttribute('SectionName',c.name)
  ramp(region,'OpenAscent',entry,top,344,stone)
  ramp(region,'DownhillLane',entry+Vector3.new(0,.45,0),top+Vector3.new(0,.45,0),32,stone:Lerp(Color3.fromRGB(240,227,182),.55),.4)
  -- Broad terrace keeps eggs and the shared defender in the same readable space.
  if k==3 then
   -- A shallow, escapable notch under actual breakaway sandstone plates.
   part(region,'TerraceFront',Vector3.new(4096,terrace.Y-4,entry.Z-131.5),Vector3.new(344,8,23),stone,Enum.Material.Sandstone,true)
   part(region,'TerraceBack',Vector3.new(4096,terrace.Y-4,entry.Z-182.5),Vector3.new(344,8,35),stone,Enum.Material.Sandstone,true)
   part(region,'TerraceLeft',Vector3.new(4038,terrace.Y-4,entry.Z-154),Vector3.new(228,8,22),stone,Enum.Material.Sandstone,true)
   part(region,'TerraceRight',Vector3.new(4226,terrace.Y-4,entry.Z-154),Vector3.new(84,8,22),stone,Enum.Material.Sandstone,true)
   part(region,'SandstoneCatch',Vector3.new(4168,terrace.Y-8,entry.Z-154),Vector3.new(32,4,22),stone,Enum.Material.Sandstone,true)
  else part(region,'Terrace',terrace-Vector3.new(0,4,0),Vector3.new(344,8,80),stone,Enum.Material[c.material],true) end
  part(region,'DownhillLane',terrace+Vector3.new(0,.15,0),Vector3.new(32,.3,80),stone:Lerp(Color3.fromRGB(240,227,182),.55),Enum.Material.Cobblestone,true)
  -- Cliff mass sits below the playable face; no terrain edits or camera tunnels.
  part(region,'MountainMass',terrace-Vector3.new(0,terrace.Y/2+25,0),Vector3.new(338,terrace.Y+10,76),stone:Lerp(Color3.new(0,0,0),.16),Enum.Material.Rock,true)
  for side=-1,1,2 do
   for j=1,4 do local p=Vector3.new(4096+side*(178+rng:NextNumber(0,16)),terrace.Y-18,entry.Z-115-j*18)
    local rock=part(region,'BrokenCliff',p,Vector3.new(20,46+rng:NextNumber(0,18),28),stone,Enum.Material.Rock,true);rock.CFrame*=CFrame.Angles(0,j*.3,side*.12)
   end
   for j=1,3 do local p=Vector3.new(4096+side*(130+j*7),terrace.Y,entry.Z-130-j*14)
    if k<=2 then A.tree(region,p,c,rng) else A.crystal(region,p,c,9+j*3) end
   end
  end
  local title=part(region,'SectionWayfinder',Vector3.new(3980,terrace.Y+5,entry.Z-121),Vector3.new(4,10,3),accent,Enum.Material.Marble,true)
  A.label(title,c.name..'\nAll climbers welcome',11)
  for j=1,6 do
   local p=part(region,'DownhillArrow',Vector3.new(4096,entry.Y+64*j/7+.7,entry.Z-120*j/7),Vector3.new(5,.2,3),accent,Enum.Material.Neon,false)
   p.CFrame=CFrame.lookAt(p.Position,p.Position+Vector3.new(0,-64,120))*CFrame.Angles(0,0,math.pi/4)
  end
  local b=s.bounds;local bound=part(bounds,tostring(k),Vector3.new((b.minX+b.maxX)/2,(b.minY+b.maxY)/2,(b.minZ+b.maxZ)/2),Vector3.new(b.maxX-b.minX,b.maxY-b.minY,b.maxZ-b.minZ),accent,nil,false);bound.Transparency=1
  local boss=A.creature(encounters,C.guardians[k],Vector3.new(4096,terrace.Y,entry.Z-185),3.2,1);boss.Name='Guardian_'..k;boss:SetAttribute('Kingdom',k)
  for _,kind in ipairs({'Guardian','Trial'}) do
   local pos=v(if kind=='Guardian' then s.normalAltar else s.trialAltar)
   local altar=part(interactions,if kind=='Guardian' then C.guardians[k].name else 'Trial_'..k,pos,Vector3.new(8,2,8),accent,Enum.Material.Marble,true)
   prompt(altar,kind,k,kind..':'..k,if kind=='Trial' then 'Begin harder Trial' else 'Challenge Guardian')
   altar:SetAttribute('ArenaX',pos.X);altar:SetAttribute('ArenaY',terrace.Y);altar:SetAttribute('ArenaZ',pos.Z)
   A.label(altar,if kind=='Trial' then 'GUARDIAN TRIAL\nCarry the reward home' else 'OPTIONAL FIGHT\nWin a brief raid opening',7)
  end
  local hp=s.hazard;local hazard=part(dynamics,'Hazard_'..k,Vector3.new(hp.x,hp.y+.4,hp.z),Vector3.new(32,.8,22),accent,Enum.Material.Neon,false)
  hazard:SetAttribute('Kind','RaidHazard');hazard:SetAttribute('Kingdom',k);hazard:SetAttribute('Hazard',Config.section(k).hazard);hazard:SetAttribute('Phase','quiet')
  A.label(hazard,({'ROOT SWEEP','WATER PULSE','SHIFTING SANDSTONE','PRISM CROSSING','FIRE VENTS','GRAVITY PULSE'})[k]..'\nWatch the warning • clear lane to the left',6)
  local details=folder(hazard,'TellArt')
  if k==1 then for j=1,3 do A.link(details,'Root',Vector3.new(hp.x-14,hp.y+1,hp.z-6+j*3),Vector3.new(hp.x+14,hp.y+1,hp.z-6+j*3),1.1,Color3.fromRGB(111,87,57),Enum.Material.Wood,false) end
  elseif k==2 then for j=1,3 do part(details,'WaterSheet',Vector3.new(hp.x,hp.y+j*.6,hp.z-7+j*4),Vector3.new(28,.3,2),Color3.fromRGB(114,212,242),Enum.Material.Neon,false) end
  elseif k==3 then for j=1,4 do part(details,'SandstoneSlab',Vector3.new(hp.x-20+j*8,hp.y+.5,hp.z),Vector3.new(8,1,22),stone,Enum.Material.Sandstone,true) end
  elseif k==4 then for side=-1,1,2 do local p=part(details,'PrismBeam',Vector3.new(hp.x,hp.y+2,hp.z),Vector3.new(28,.6,1),accent,Enum.Material.Neon,false);p.CFrame*=CFrame.Angles(0,side*.55,0) end
  elseif k==5 then for j=1,3 do part(details,'Vent',Vector3.new(hp.x-14+j*7,hp.y+1.5,hp.z),Vector3.new(3,3,3),Color3.fromRGB(255,145,72),Enum.Material.Neon,false) end
  else for j=1,5 do local a=j*math.pi*2/5;part(details,'GravityRune',Vector3.new(hp.x+math.cos(a)*10,hp.y+2,hp.z+math.sin(a)*6),Vector3.new(1,3,1),accent,Enum.Material.Neon,false) end end
 end
 for _,r in ipairs(g.restPoints) do
  local p=part(checkpoints,r.id,v(r.position)+Vector3.new(0,.2,0),Vector3.new(13,.4,13),Color3.fromRGB(178,208,173),Enum.Material.Cobblestone,true)
  prompt(p,'Checkpoint',r.section,r.id,'Rest here');A.label(p,'REST POINT\nEscape to sanctuary for safety',4);p.Label.MaxDistance=32
 end
 for _,e in ipairs(g.eggs) do
  local p=part(interactions,e.id,v(e.position)+Vector3.new(0,.4,0),Vector3.new(7,.8,7),A.color(C.kingdoms[e.section].accent),Enum.Material.Slate,true)
  prompt(p,'Nest',e.section,e.id,'Strike egg')
 end
 for _,p in ipairs(root.Interactions:GetChildren()) do local label=p:FindFirstChild('Label');if label then label.MaxDistance=45 end end
 for _,p in ipairs(root.Dynamics:GetChildren()) do local label=p:FindFirstChild('Label');if label then label.MaxDistance=50 end end
 require(script.Parent.MountainQuality).apply(root)
 require(script.Parent.CompactMountain).apply(root)
 return root,F.layout()
end
return F
