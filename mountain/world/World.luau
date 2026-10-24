local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local A=require(script.Parent.Art)
local W={}
local function v(p) return Vector3.new(p.x,p.y,p.z) end
local function folder(parent,name) local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
local function attrs(p,t) for k,x in pairs(t) do p:SetAttribute(k,x) end end
local function prompt(p,action,kind,k,id)
 attrs(p,{Kind=kind,Kingdom=k,Id=id or p.Name})
 local q=Instance.new('ProximityPrompt');q.ActionText=action;q.ObjectText=p.Name;q.HoldDuration=.4;q.MaxActivationDistance=12;q.RequiresLineOfSight=false;q.Parent=p;return p
end
local function deck(parent,name,pos,size,color,material)
 return A.part(parent,name,size,CFrame.new(pos-Vector3.new(0,size.Y/2,0)),color,material,nil,true)
end
local function walkway(parent,name,a,b,width,k)
 local delta=b-a;local len=delta.Magnitude
 return A.part(parent,name,Vector3.new(width,1.2,len+1),CFrame.lookAt((a+b)/2,b),A.color(k.color):Lerp(Color3.fromRGB(211,201,173),.5),Enum.Material.Cobblestone,nil,true)
end
local function arch(parent,pos,k,radius)
 local col=A.color(k.rock):Lerp(Color3.new(1,1,1),.3)
 for i=0,10 do local a=math.pi*i/10
  A.part(parent,'ArchVoussoir',Vector3.new(4,5,6),CFrame.new(pos+Vector3.new(math.cos(a)*radius,7+math.sin(a)*radius,0))*CFrame.Angles(0,0,a-math.pi/2),col,Enum.Material.Marble,nil,true)
 end
 for _,s in ipairs({-1,1}) do A.part(parent,'Pillar',Vector3.new(4,9,6),CFrame.new(pos+Vector3.new(s*radius,4.5,0)),col,Enum.Material.Marble,nil,true) end
end
function W.build()
 assert(not workspace:FindFirstChild('MountainEmpire_Phase1'),'Never build in Phase 1')
 assert(not workspace:FindFirstChild('ImpossibleMountain'),'Mountain already built; use a new review place')
 local root=folder(workspace,'ImpossibleMountain');root:SetAttribute('GeneratorVersion',C.version)
 local checkpoints=folder(root,'Checkpoints');local interactions=folder(root,'Interactions');local dynamics=folder(root,'Dynamics');local encounters=folder(root,'Encounters')
 local terrain=workspace.Terrain
 -- Continuous solid mass, bounded to a new place. No Terrain:Clear call.
 for y=-24,836,12 do
  local k=C.kingdoms[math.clamp(math.floor((y-16)/136)+1,1,6)]
  local radius=452-math.max(0,y)*.4
  terrain:FillCylinder(CFrame.new(0,y,0),16,radius,Enum.Material[k.material])
  if y%36==0 then task.wait() end
 end
 terrain:FillBall(Vector3.new(0,805,0),55,Enum.Material.Snow)
 local rng=Random.new(C.seed)
 for ki,k in ipairs(C.kingdoms) do
  local region=folder(root,k.name);region:SetAttribute('Kingdom',ki)
  -- Larger naturally broken rock silhouettes behind routes; path is carved afterward.
  for j=1,28 do
   local t=(j-.5)/28;local q=C.route(ki,t);local a=q.angle+.2
   local pos=Vector3.new(math.cos(a)*(q.radius-33),q.y-6,math.sin(a)*(q.radius-33))
   local rock=A.part(region,'ErodedStratum',Vector3.new(rng:NextNumber(24,46),rng:NextNumber(18,40),rng:NextNumber(22,48)),CFrame.new(pos)*CFrame.Angles(.15,a,.14),A.color(k.rock),Enum.Material[k.material],Enum.PartType.Ball,true)
  end
  local last=v(C.route(ki,0))
  for i=1,48 do
   local q=C.route(ki,i/48);local p=v(q)
   local delta=p-last
   terrain:FillBlock(CFrame.lookAt((p+last)/2+Vector3.new(0,9,0),p+Vector3.new(0,9,0)),Vector3.new(27,20,delta.Magnitude+4),Enum.Material.Air)
   if i%12==0 then
    local foot=Vector3.new(p.X,last.Y,p.Z)
    walkway(region,'CliffApproach',last,foot,14,k)
    local truss=Instance.new('TrussPart');truss.Name='ClimbLadder';truss.Anchored=true;truss.Size=Vector3.new(2,p.Y-last.Y+4,2);truss.CFrame=CFrame.new(p-Vector3.new(0,(p.Y-last.Y)/2,0));truss.Color=A.color(k.accent);truss.Parent=region
    deck(region,'ClimbLanding',p+Vector3.new(0,-.4,0),Vector3.new(14,1,14),A.color(k.rock),Enum.Material[k.material])
    for _,sign in ipairs({-1,1}) do A.link(region,'ClimbingRope',foot+Vector3.new(sign*2,0,0),p+Vector3.new(sign*2,2,0),.22,Color3.fromRGB(201,175,126),Enum.Material.Fabric) end
   else walkway(region,'PrimaryAscent',last,p,16,k) end
   if i%3==0 then
    local side=Vector3.new(math.cos(q.angle),0,math.sin(q.angle));local pos=p+side*13
    local post=A.part(region,'Wayfinder',Vector3.new(.6,4,.6),CFrame.new(pos+Vector3.new(0,2,0)),A.color(k.rock),Enum.Material.Wood)
    A.part(region,'RouteFlag',Vector3.new(2.5,1.5,.2),post.CFrame*CFrame.new(1,1,0),A.color(k.accent),Enum.Material.Fabric)
    if i%6==0 then
     local point=p-side*18
     if ki==3 or ki==4 or ki==6 then A.crystal(region,point,k,8) else A.tree(region,point,k,rng) end
     for n=1,6 do
      local pt=p+side*(10+n*.8)+Vector3.new(math.cos(n*2)*5,0,math.sin(n*2)*5)
      A.part(region,'Wildflower',Vector3.new(1.1,.5,1.1),CFrame.new(pt+Vector3.new(0,.6,0)),A.color(k.accent),Enum.Material.Grass,Enum.PartType.Ball)
     end
    end
   end
   last=p
   if i%12==0 then task.wait() end
  end
  -- Checkpoints at the entrance, mid-route recovery and Guardian approach.
  for _,spec in ipairs({{'entrance',0},{'recovery',.50},{'guardian',.875}}) do
   local pos=v(C.route(ki,spec[2]));local p=deck(checkpoints,ki..':'..spec[1],pos+Vector3.new(0,.3,0),Vector3.new(18,1,18),A.color(k.accent),Enum.Material.Slate)
   prompt(p,'Rest • extract eggs','Checkpoint',ki,p.Name);A.label(p,k.name..'\n'..spec[1],5)
  end
  -- Two optional discoveries, with readable branches and varied environmental compositions.
  for branch,t in ipairs({.29,.66}) do
   local q=C.route(ki,t);local base=v(q);local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle));local pos=base+outward*48
   walkway(region,'ExplorationBranch_'..branch,base,pos,10,k)
   deck(region,'BranchTerrace',pos,Vector3.new(34,5,32),A.color(k.rock),Enum.Material[k.material])
   arch(region,pos+Vector3.new(0,0,-7),k,10)
   local marker=A.part(interactions,k.landmarks[branch+1],Vector3.new(3,3,3),CFrame.new(pos+Vector3.new(-8,2,0)),A.color(k.accent),Enum.Material.Marble,Enum.PartType.Ball)
   prompt(marker,'Discover • gather','Discovery',ki,ki..':branch'..branch);A.label(marker,k.landmarks[branch+1],7)
   local nest=A.part(interactions,'Hidden nest',Vector3.new(3,4,3),CFrame.new(pos+Vector3.new(7,2,0)),A.color(k.accent),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
   prompt(nest,'Collect egg','Nest',ki,ki..':nest'..branch)
   if branch==2 then
    local short=A.part(interactions,'Ancient shortcut',Vector3.new(3,5,3),CFrame.new(pos+Vector3.new(0,2,8)),A.color(k.accent),Enum.Material.Marble)
    prompt(short,'Attune shortcut','Shortcut',ki,tostring(ki))
   end
   -- Roofed side cavern entrance; the main mountain remains solid.
   if branch==1 then
    for _,side in ipairs({-1,1}) do A.part(region,'CaveWall',Vector3.new(5,14,18),CFrame.new(pos+Vector3.new(side*14,7,5)),A.color(k.rock),Enum.Material[k.material],nil,true) end
    A.part(region,'CaveVault',Vector3.new(32,5,18),CFrame.new(pos+Vector3.new(0,14,5)),A.color(k.rock),Enum.Material[k.material],nil,true)
   end
  end
  -- Habitat encounter for every regular species, six distinct silhouettes per kingdom.
  for j=1,6 do
   local s=C.species[(ki-1)*6+j];local q=C.route(ki,.08+j*.115);local pos=v(q)+Vector3.new(math.cos(q.angle)*19,1,math.sin(q.angle)*19)
   deck(region,'EncounterLedge',pos-Vector3.new(0,1,0),Vector3.new(16,2,16),A.color(k.rock),Enum.Material[k.material])
   local pet=A.creature(encounters,s,pos,1.3,1);local trigger=pet.PrimaryPart
   prompt(trigger,'Wild encounter','Wild',ki,s.id);A.label(trigger,s.name..' • '..s.rarity,5)
  end
  local q=C.route(ki,.875);local entry=v(q);local outward=Vector3.new(math.cos(q.angle),0,math.sin(q.angle));local arena=entry+outward*66
  walkway(region,'GuardianApproach',entry,arena,18,k)
  local floor=A.part(region,'ArenaFloor',Vector3.new(5,82,82),CFrame.new(arena-Vector3.new(0,2.5,0))*CFrame.Angles(0,0,math.pi/2),A.color(k.rock),Enum.Material[k.material],Enum.PartType.Cylinder,true)
  floor:SetAttribute('Arena',ki)
  for j=1,12 do
   local angle=j*math.pi/6;local pos=arena+Vector3.new(math.cos(angle)*38,0,math.sin(angle)*38)
   A.part(region,'ArenaColumn',Vector3.new(3,12+(j%3)*3,3),CFrame.new(pos+Vector3.new(0,6,0)),A.color(k.rock):Lerp(Color3.new(1,1,1),.25),Enum.Material.Marble,nil,true)
   A.crystal(region,pos+Vector3.new(0,12,0),k,3)
  end
  local boss=A.creature(encounters,C.guardians[ki],arena+Vector3.new(0,1,-10),4.5,1);boss.Name='Guardian_'..ki
  local altar=A.part(interactions,C.guardians[ki].name,Vector3.new(4,3,4),CFrame.new(arena+Vector3.new(0,2,25)),A.color(k.accent),Enum.Material.Marble)
  attrs(altar,{ArenaX=arena.X,ArenaY=arena.Y,ArenaZ=arena.Z});prompt(altar,'Challenge Guardian','Guardian',ki,tostring(ki));A.label(altar,k.landmarks[1],8)
  local trial=A.part(interactions,'Legendary Trial',Vector3.new(3,4,3),CFrame.new(arena+Vector3.new(11,2,24)),A.color(k.accent),Enum.Material.Glass)
  prompt(trial,'Begin mastery trial','Trial',ki,tostring(ki))
  -- Biome signature: falls, oasis, crystals, lava and celestial rings.
  if ki==2 or ki==5 then
   for j=1,3 do
    local qp=C.route(ki,.15+j*.16);local pos=v(qp)-Vector3.new(math.cos(qp.angle)*32,0,math.sin(qp.angle)*32)
    local fall=A.part(region,if ki==2 then 'TurquoiseCascade' else 'Lavafall',Vector3.new(9,65,2),CFrame.new(pos-Vector3.new(0,22,0))*CFrame.Angles(0,-qp.angle,0),A.color(k.accent),if ki==2 then Enum.Material.Glass else Enum.Material.Neon)
    fall.Transparency=if ki==2 then .3 else .12
    A.part(region,'MistPool',Vector3.new(26,1,22),CFrame.new(pos-Vector3.new(0,54,0)),A.color(k.accent),Enum.Material.Glass,Enum.PartType.Ball)
   end
  end
  if ki==6 then
   for ring=1,3 do for j=1,24 do local a=j*math.pi/12;local r=25+ring*10
    A.part(region,'ConstellationRing',Vector3.new(1,1,10),CFrame.new(Vector3.new(math.cos(a)*r,850+ring*8,math.sin(a)*r))*CFrame.Angles(0,-a,0),A.color(k.accent),Enum.Material.Metal)
   end end
   arch(region,Vector3.new(0,837,0),k,25)
   walkway(region,'FinalSummitAscent',v(C.route(6,1)),Vector3.new(0,838,0),16,k)
   local summit=deck(interactions,'Impossible Summit',Vector3.new(0,840,0),Vector3.new(55,3,55),A.color(k.color),Enum.Material.Marble)
   prompt(summit,'Celebrate summit','Summit',6,'summit');A.label(summit,'IMPOSSIBLE MOUNTAIN\nEternal Astral Sanctum',14)
  end
  -- Moving bonus platform and a timed hazard sit on an optional challenge ledge.
  local dp=v(C.route(ki,.42));local radial=Vector3.new(math.cos(C.route(ki,.42).angle),0,math.sin(C.route(ki,.42).angle))
  local start=dp+radial*22;walkway(region,'ChallengeAccess',dp,start,10,k)
  local mover=deck(dynamics,'KingdomLift_'..ki,start,Vector3.new(12,1,12),A.color(k.accent),Enum.Material[k.material]);attrs(mover,{Kind='Moving',Kingdom=ki,AxisX=radial.X,AxisZ=radial.Z})
  local endP=dp+radial*57;deck(region,'ChallengeRewardLedge',endP,Vector3.new(18,2,18),A.color(k.rock),Enum.Material[k.material])
  local puzzle=A.part(interactions,'Constellation mechanism',Vector3.new(3,4,3),CFrame.new(endP+Vector3.new(0,2,0)),A.color(k.accent),Enum.Material.Marble)
  prompt(puzzle,'Align three runes','Puzzle',ki,ki..':puzzle')
  local hazard=deck(dynamics,'TimedHazard_'..ki,dp+radial*42+Vector3.new(0,-2,0),Vector3.new(14,.5,14),A.color(k.accent),Enum.Material.Neon);attrs(hazard,{Kind='Hazard',Kingdom=ki});hazard.CanCollide=false
  task.wait()
 end
 local refuge=folder(root,'ExpeditionRefuge_IntegrationFixture')
 deck(refuge,'RefugeIsland',Vector3.new(0,16,560),Vector3.new(130,14,110),Color3.fromRGB(121,150,125),Enum.Material.Grass)
 walkway(refuge,'GatewayInterface',Vector3.new(0,16,515),v(C.route(1,0)),20,C.kingdoms[1])
 arch(refuge,Vector3.new(0,16,515),C.kingdoms[1],14)
 local spawn=Instance.new('SpawnLocation');spawn.Name='MountainArrival';spawn.Anchored=true;spawn.Size=Vector3.new(8,1,8);spawn.CFrame=CFrame.new(0,17,555);spawn.Transparency=1;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=refuge
 for i,name in ipairs({'Incubator','Sanctuary','Training','Competition'}) do
  local pos=Vector3.new(-45+(i-1)*30,16,585)
  deck(refuge,name..'Dais',pos,Vector3.new(21,2,18),Color3.fromRGB(194,183,159),Enum.Material.Cobblestone)
  local p=A.part(interactions,name,Vector3.new(5,4,5),CFrame.new(pos+Vector3.new(0,2,0)),Color3.fromRGB(171,218,203),Enum.Material.Marble)
  prompt(p,'Open '..name,name,1,name);A.label(p,name,6)
 end
 local gateway=Instance.new('Attachment');gateway.Name='MountainGatewayEntry';gateway.CFrame=CFrame.new(0,20,545);gateway.Parent=workspace.Terrain
 for j=1,12 do A.tree(refuge,Vector3.new(if j%2==0 then 54 else -54,16,510+j*7),C.kingdoms[1],rng) end
 local L=game:GetService('Lighting');L.ClockTime=13.5;L.Brightness=2.5;L.Ambient=Color3.fromRGB(119,133,151);L.OutdoorAmbient=Color3.fromRGB(149,165,181)
 local atmosphere=Instance.new('Atmosphere');atmosphere.Density=.23;atmosphere.Offset=.12;atmosphere.Color=Color3.fromRGB(203,226,241);atmosphere.Decay=Color3.fromRGB(132,153,179);atmosphere.Parent=L
 local bloom=Instance.new('BloomEffect');bloom.Intensity=.18;bloom.Size=20;bloom.Threshold=1.4;bloom.Parent=L
 root:SetAttribute('Ready',true)
 return {kingdoms=6,species=36,guardians=6,checkpoints=#checkpoints:GetChildren(),instances=#root:GetDescendants()}
end
return W
