-- Additive dressing only. Production sits in the fixed re-packed grid of HomeLayout.contents.production; owner decor/displays use HomeLayout.decorSlots only.
-- Colors reuse the existing production palette and the owner's kingdom accent; no new palette.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local A=require(game.ServerStorage.MountainWorld.Art)
local Tags=game:GetService('CollectionService')
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local Home=T.home
local W={}
local PR=L.contents.production
function W.new(home)
 local plots={}
 local service={}
 local function part(parent,name,size,cf,color,material)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent;return p
 end
 local function label(p,text,height)
  local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(160,42);gui.MaxDistance=45;gui.Parent=p
  if height then gui.StudsOffsetWorldSpace=Vector3.new(0,height,0) else gui.StudsOffset=Vector3.new(0,3,0) end
  local textLabel=Instance.new('TextLabel');textLabel.Size=UDim2.fromScale(1,1);textLabel.BackgroundTransparency=.25;textLabel.BackgroundColor3=Color3.fromRGB(24,40,48)
  textLabel.TextColor3=Color3.fromRGB(245,240,218);textLabel.TextSize=14;textLabel.Font=Enum.Font.GothamMedium;textLabel.TextWrapped=true;textLabel.Text=text;textLabel.Parent=gui
  return textLabel
 end
 local WOOD,METAL,SLATE,GRASS=Color3.fromRGB(219,189,122),Color3.fromRGB(40,62,65),Color3.fromRGB(82,104,114),Color3.fromRGB(85,123,100)
 local function buildDecor(slotInfo,item,accent,view)
  slotInfo.folder:ClearAllChildren()
  local cf,f=slotInfo.cf,slotInfo.folder
  if item=='lantern_post' then
   part(f,'Post',Vector3.new(.6,5,.6),cf*CFrame.new(0,2.5,0),METAL,Enum.Material.Metal);part(f,'Lamp',Vector3.new(1.4,1.4,1.4),cf*CFrame.new(0,5.4,0),accent,Enum.Material.Neon)
  elseif item=='flower_barrel' then
   part(f,'Barrel',Vector3.new(3,2,3),cf*CFrame.new(0,1,0),WOOD,Enum.Material.Wood);part(f,'Blooms',Vector3.new(2.5,.5,2.5),cf*CFrame.new(0,2.2,0),GRASS,Enum.Material.Grass);part(f,'Flower',Vector3.new(1,1,1),cf*CFrame.new(0,2.9,0),accent,Enum.Material.SmoothPlastic)
  elseif item=='pennant_banner' then
   part(f,'Pole',Vector3.new(.4,8,.4),cf*CFrame.new(0,4,0),WOOD,Enum.Material.Wood);part(f,'Pennant',Vector3.new(.2,3,2.4),cf*CFrame.new(0,6,1.4),accent,Enum.Material.Fabric)
  elseif item=='stone_bench' then
   part(f,'Seat',Vector3.new(4.5,.6,1.6),cf*CFrame.new(0,1.5,0),SLATE,Enum.Material.Slate)
   for _,x in ipairs({-1.8,1.8}) do part(f,'Leg',Vector3.new(.6,1.3,1.4),cf*CFrame.new(x,.7,0),SLATE,Enum.Material.Slate) end
  elseif item=='garden_arch' then
   for _,x in ipairs({-2.4,2.4}) do part(f,'ArchPost',Vector3.new(.7,5.5,.7),cf*CFrame.new(x,2.75,0),WOOD,Enum.Material.Wood) end
   part(f,'ArchTop',Vector3.new(6,.8,.8),cf*CFrame.new(0,5.6,0),WOOD,Enum.Material.Wood);part(f,'ArchVine',Vector3.new(5.6,.5,1),cf*CFrame.new(0,6.1,0),GRASS,Enum.Material.Grass)
  elseif item=='wind_chime' then
   part(f,'Hook',Vector3.new(.4,6,.4),cf*CFrame.new(0,3,0),METAL,Enum.Material.Metal);part(f,'Arm',Vector3.new(3,.3,.3),cf*CFrame.new(1.4,6,0),METAL,Enum.Material.Metal)
   for k=0,2 do part(f,'Tube',Vector3.new(.3,2+k*.4,.3),cf*CFrame.new(.4+k*1,4.4-k*.2,0),accent,Enum.Material.Neon) end
  elseif item=='trophy_shelf' then
   part(f,'Back',Vector3.new(7,3.4,.3),cf*CFrame.new(0,2.5,-1),WOOD,Enum.Material.Wood);part(f,'Shelf',Vector3.new(7,.4,2),cf*CFrame.new(0,1.6,0),WOOD,Enum.Material.Wood)
   for k=1,math.min(5,view.trophies) do part(f,'Cup',Vector3.new(.9,1.1,.9),cf*CFrame.new(-2.8+(k-1)*1.4,2.35,0),accent,Enum.Material.Neon) end
  elseif item=='creature_pedestal' then
   local base=part(f,'Pedestal',Vector3.new(6.5,1,6.5),cf*CFrame.new(0,.5,0),WOOD,Enum.Material.Wood);base.Shape=Enum.PartType.Cylinder;base.CFrame=cf*CFrame.new(0,.5,0)*CFrame.Angles(0,0,math.pi/2);base.Size=Vector3.new(1,6.5,6.5)
  end
 end
 for slot=1,8 do
  local model=home.model(slot);local floor=model:FindFirstChild(L.floorName)
  local root=Instance.new('Model');root.Name='TycoonProduction';root.Parent=model
  local cf=floor.CFrame*CFrame.new(0,floor.Size.Y/2+.15,L.contents.tycoonZ)
  root:SetAttribute('Width',L.contents.tycoonHalfX*2);root:SetAttribute('Depth',L.contents.tycoonMaxZ-L.contents.tycoonMinZ)
  local spine=part(root,'ConveyorSpine',Vector3.new(10,.4,PR.spineLength),cf,Color3.fromRGB(40,62,65),Enum.Material.Metal)
  spine:SetAttribute('SanctuarySlot',slot);spine:SetAttribute('ActiveHabitats',0);Tags:AddTag(spine,'TycoonConveyor')
  for _,x in ipairs({-5.2,5.2}) do part(root,'SpineTrim',Vector3.new(.3,.25,PR.spineLength),cf*CFrame.new(x,.4,0),Color3.fromRGB(114,203,177),Enum.Material.Neon) end
  local habitats={}
  local PW,PD=PR.padWidth,PR.padDepth
  for i=1,8 do
   local x=if i%2==1 then -PR.columnX else PR.columnX;local z=PR.rowZ[math.ceil(i/2)]
   local center=cf*CFrame.new(x,0,z)
   local pad=part(root,'Habitat_'..i,Vector3.new(PW,.5,PD),center,Color3.fromRGB(85,123,100),Enum.Material.Grass)
   pad.CanQuery=true -- tappable: visitors and owners inspect species, level and rate
   pad:SetAttribute('SanctuarySlot',slot);pad:SetAttribute('HabitatIndex',i)
   local rim=part(root,'HabitatRim_'..i,Vector3.new(PW+1,.2,PD+1),center*CFrame.new(0,-.15,0),Color3.fromRGB(219,189,122),Enum.Material.Wood)
   local branch=part(root,'Feeder_'..i,Vector3.new(PR.feederLength,.25,3),cf*CFrame.new(if x<0 then -(5+PR.feederLength/2) else 5+PR.feederLength/2,.15,z),spine.Color,Enum.Material.Metal)
   local frame={}
   for _,dx in ipairs({-(PW/2-1),PW/2-1}) do for _,dz in ipairs({-(PD/2-1),PD/2-1}) do
    table.insert(frame,part(root,'HabitatPost_'..i,Vector3.new(.9,2.4,.9),center*CFrame.new(dx,1.3,dz),rim.Color,Enum.Material.Wood))
   end end
   table.insert(frame,part(root,'HabitatBackRail_'..i,Vector3.new(PW-2,.6,.6),center*CFrame.new(0,2,-(PD/2-1)),rim.Color,Enum.Material.Wood))
   local gaugeLen=PW-6;local gz=PD/2-1.5
   local gauge=part(root,'StorageTrack_'..i,Vector3.new(gaugeLen,.25,.8),center*CFrame.new(0,.5,gz),spine.Color,Enum.Material.Metal)
   local fill=part(root,'StorageFill_'..i,Vector3.new(.05,.3,.65),center*CFrame.new(-gaugeLen/2,.55,gz),rim.Color,Enum.Material.Neon)
   fill.Transparency=1
   -- Visible stock: up to five eggs pile up beside the gauge as the store fills (visual only).
   local pile={}
   for k=1,5 do
    local egg=part(root,'StockEgg_'..i,Vector3.new(1.3,1.7,1.3),center*CFrame.new(-PW/2+3+(k-1)*1.7,1.1,-(PD/2-3.2)),Color3.fromRGB(246,211,137),Enum.Material.SmoothPlastic)
    egg.Shape=Enum.PartType.Ball;egg.Transparency=1;pile[k]=egg
   end
   -- Full-store beacon pulses on the client (TycoonFeel); hidden until the store is full.
   local beacon=part(root,'FullBeacon_'..i,Vector3.new(1.4,1.4,1.4),center*CFrame.new(PW/2-2,3.4,-(PD/2-1)),rim.Color,Enum.Material.Neon)
   beacon.Shape=Enum.PartType.Ball;beacon.Transparency=1;Tags:AddTag(beacon,'HabitatBeacon')
   habitats[i]={pad=pad,rim=rim,branch=branch,label=label(pad,'Habitat '..i,7),cf=center,frame=frame,gauge=gauge,fill=fill,gaugeLen=gaugeLen,gz=gz,pile=pile,beacon=beacon}
   local click=Instance.new('ClickDetector');click.MaxActivationDistance=45;click.Parent=pad
   local index=i
   click.MouseClick:Connect(function(player) if service.onInspect then service.onInspect(player,slot,'habitat',index) end end)
  end
  local bank=part(root,'ProductionBank',Vector3.new(12,3,6),cf*CFrame.new(0,1.5,PR.bankZ),Color3.fromRGB(219,189,122),Enum.Material.Metal)
  bank.CanQuery=true;bank:SetAttribute('SanctuarySlot',slot);bank:SetAttribute('Service','Sanctuary')
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Manage / collect / bank';prompt.ObjectText='Production eggs';prompt.HoldDuration=.2;prompt.MaxActivationDistance=12;prompt.Parent=bank
  label(bank,'PRODUCTION BANK')
  part(root,'BankPlinth',Vector3.new(14,.6,8),cf*CFrame.new(0,.3,PR.bankZ),spine.Color,Enum.Material.Slate)
  part(root,'BankDepositSlot',Vector3.new(7,.15,1.2),cf*CFrame.new(0,3.1,PR.bankZ-1),spine.Color,Enum.Material.Metal)
  local machines={}
  for i,name in ipairs({'Processor','Sorter','Collector'}) do
   local machine=part(root,name,Vector3.new(4,3,5),cf*CFrame.new(0,1.6,PR.machineZ[i]),Color3.fromRGB(82,104,114),Enum.Material.Metal)
   local pieces={}
   for _,x in ipairs({-3.8,3.8}) do table.insert(pieces,part(root,name..'Pillar',Vector3.new(1.2,5,2),machine.CFrame*CFrame.new(x,.8,0),machine.Color,Enum.Material.Metal)) end
   table.insert(pieces,part(root,name..'Arch',Vector3.new(9,1,2),machine.CFrame*CFrame.new(0,3.3,0),machine.Color,Enum.Material.Metal))
   local light=part(root,name..'Status',Vector3.new(5,.2,.25),machine.CFrame*CFrame.new(0,3.3,1.15),bank.Color,Enum.Material.Neon)
   table.insert(pieces,light)
   -- Spinning wheel (client animates it while the machine is installed).
   local gear=part(root,name..'Gear',Vector3.new(.5,2.6,2.6),machine.CFrame*CFrame.new(0,3.3,-1.6),bank.Color,Enum.Material.Metal)
   gear.Shape=Enum.PartType.Cylinder;gear:SetAttribute('Spin',0);Tags:AddTag(gear,'MachineGear')
   table.insert(pieces,gear)
   -- Compact grid: machine labels only up close so they never stack over the habitat labels.
   local machineLabel=label(machine,name);machineLabel.Parent.MaxDistance=22
   machines[i]={part=machine,label=machineLabel,pieces=pieces,gear=gear}
  end
  local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2+.15,0)
  local decorSlots={}
  for _,def in ipairs(L.decorSlots) do
   local folder=Instance.new('Folder');folder.Name='Slot_'..def.id;folder.Parent=root
   decorSlots[def.id]={def=def,cf=base*CFrame.new(def.x,0,def.z),folder=folder,key=''}
   if def.kind=='display' then
    -- Tappable zone over the display slot for visitor inspection.
    local zone=part(root,'DisplayZone_'..def.id,Vector3.new(def.size,.2,def.size),decorSlots[def.id].cf,Color3.fromRGB(85,123,100),Enum.Material.Grass)
    zone.CanQuery=true;zone.Transparency=1;zone:SetAttribute('SanctuarySlot',slot)
    local click=Instance.new('ClickDetector');click.MaxActivationDistance=45;click.Parent=zone
    local id=def.id
    click.MouseClick:Connect(function(player) if service.onInspect then service.onInspect(player,slot,'display',id) end end)
   end
  end
  Tags:AddTag(bank,'ProductionBank')
  plots[slot]={root=root,spine=spine,habitats=habitats,machines=machines,bank=bank,decor=decorSlots,seen={eggs=0,bag=0,bagEggs=0,coins=0},collectSeq=0,bankSeq=0}
  task.wait()
 end
 function service.update(player,p)
  local slot=home.plot(player);local plot=slot and plots[slot];if not plot then return end
  local t=p.tycoon;local active=0
  local palette=table.find(T.config.cosmetics,t.cosmetic) or 1;local accent=Color3.fromRGB(table.unpack(C.kingdoms[palette].accent))
  plot.bank.Color=accent;plot.spine:SetAttribute('Automation',t.levels.automation)
  for i,row in ipairs(plot.habitats) do
   local h=t.habitats[i];local unlocked=i<=t.slots;local c=h.creature and (function() for _,v in ipairs(p.creatures) do if v.id==h.creature then return v end end end)()
   if c and unlocked then active+=1 end
   local species=c and C.byId[c.species]
   local key=if c then c.id..':'..c.level else ''
   if row.key~=key then
    if row.creature then row.creature:Destroy();row.creature=nil end
    if species and unlocked then
     row.creature=A.creature(plot.root,species,row.cf.Position+Vector3.new(0,2,0),.65,if c.level>=35 then 3 elseif c.level>=15 then 2 else 1)
     row.creature:SetAttribute('IdleSeed',i*1.3);Tags:AddTag(row.creature,'HabitatCreature')
    end
    local height=5
    if row.creature then local bounds,size=row.creature:GetBoundingBox();height=math.max(height,bounds.Position.Y+size.Y/2-row.pad.Position.Y+2) end
    row.label.Parent.StudsOffsetWorldSpace=Vector3.new(0,height,0)
    row.key=key
   end
   row.pad.Transparency=if unlocked then 0 else .8;row.rim.Color=accent;row.rim.Transparency=if unlocked then 0 else .8
   row.branch.Transparency=if unlocked then 0 else .8
   for _,piece in ipairs(row.frame) do piece.Color=accent;piece.Transparency=if unlocked then 0 else .9 end
   row.gauge.Transparency=if unlocked then 0 else .9
   local capacity=T.capacity(p,i);local ratio=math.clamp(h.eggs/capacity,0,1)
   row.fill.Size=Vector3.new(math.max(.05,row.gaugeLen*ratio),.3,.65)
   row.fill.CFrame=row.cf*CFrame.new(-row.gaugeLen/2+row.gaugeLen/2*ratio,.55,row.gz)
   row.fill.Color=if ratio>=1 then Color3.fromRGB(255,211,103) else accent
   row.fill.Transparency=if unlocked and h.eggs>0 then 0 else 1
   for k,egg in ipairs(row.pile) do egg.Color=accent;egg.Transparency=if unlocked and ratio>=(k-.5)/5 and h.eggs>0 then 0 else 1 end
   row.beacon.Transparency=if unlocked and ratio>=1 then .1 else 1;row.beacon.Color=accent
   row.label.Text=if not unlocked then 'Habitat '..i..' · locked' else (if species then species.name else 'Assign a creature')..'\n'..h.eggs..' / '..T.capacity(p,i)..' production eggs'
   if unlocked and ratio>=1 then row.label.Text..=' · FULL' end
  end
  for i,v in ipairs(plot.machines) do
   local enabled=t.levels.automation>=i+1;v.part.Transparency=if enabled then .1 else .85;v.label.Text=v.part.Name..(if enabled then ' · active' else ' · locked');v.part.Color=accent
   for _,piece in ipairs(v.pieces) do piece.Color=accent;piece.Transparency=if enabled then 0 else .9 end
   v.gear:SetAttribute('Spin',if enabled then 1.2+i*.4 else 0)
  end
  -- Collect and bank moments for the client (TycoonFeel). Counters only; the economy already settled on the server.
  local totalEggs=0;for i=1,t.slots do totalEggs+=t.habitats[i].eggs end
  if t.bag.eggs>plot.seen.bagEggs and totalEggs<plot.seen.eggs then plot.collectSeq+=1;plot.spine:SetAttribute('CollectSeq',plot.collectSeq) end
  if plot.seen.bagEggs>0 and t.bag.eggs==0 and p.coins>plot.seen.coins then plot.bankSeq+=1;plot.bank:SetAttribute('BankSeq',plot.bankSeq) end
  plot.seen.eggs=totalEggs;plot.seen.bagEggs=t.bag.eggs;plot.seen.coins=p.coins
  -- Showcase and decor from the profile record. Rebuilds only the slots whose content changed.
  local homeRec=t.home or Home.fresh();local view=Home.visitorView(p,T,C)
  for id,info in pairs(plot.decor) do
   local item,key
   if info.def.kind=='display' then
    local creatureId=homeRec.showcase[id];local shelf=homeRec.decor[id]
    item=if shelf then shelf else 'creature_pedestal'
    local c=creatureId and (function() for _,v in ipairs(p.creatures) do if v.id==creatureId then return v end end end)()
    key=item..':'..(if c then c.id..':'..c.level else '')..':'..(if shelf then view.trophies..palette else '')
    if info.key~=key then
     buildDecor(info,item,accent,view)
     if c and C.byId[c.species] then
      local model=A.creature(info.folder,C.byId[c.species],info.cf.Position+Vector3.new(0,1.6,0),.5,if c.level>=35 then 3 elseif c.level>=15 then 2 else 1)
      model:SetAttribute('IdleSeed',id:byte(2)*1.7);Tags:AddTag(model,'HabitatCreature')
     end
     info.key=key
    end
   else
    item=homeRec.decor[id];key=(item or '')..':'..palette
    if info.key~=key then info.folder:ClearAllChildren();if item then buildDecor(info,item,accent,view) end;info.key=key end
   end
  end
  plot.spine:SetAttribute('ActiveHabitats',active);plot.spine:SetAttribute('OwnerUserId',player.UserId)
 end
 function service.clear(slot)
  local plot=plots[slot];if not plot then return end
  plot.spine:SetAttribute('ActiveHabitats',0);plot.spine:SetAttribute('OwnerUserId',nil)
  plot.spine:SetAttribute('Automation',0)
  for _,row in ipairs(plot.habitats) do
   if row.creature then row.creature:Destroy();row.creature=nil end
   row.key=nil;row.label.Text='Unoccupied habitat';row.fill.Transparency=1;row.beacon.Transparency=1
   for _,egg in ipairs(row.pile) do egg.Transparency=1 end
   row.pad.Transparency=.8;row.rim.Transparency=.8;row.branch.Transparency=.8;row.gauge.Transparency=.9
   for _,piece in ipairs(row.frame) do piece.Transparency=.9 end
  end
  for _,info in pairs(plot.decor) do info.folder:ClearAllChildren();info.key='' end
  plot.seen={eggs=0,bag=0,bagEggs=0,coins=0}
  for _,v in ipairs(plot.machines) do v.gear:SetAttribute('Spin',0);v.part.Transparency=.85;v.label.Text=v.part.Name..' · locked';for _,piece in ipairs(v.pieces) do piece.Transparency=.9 end end
 end
 for slot=1,8 do service.clear(slot) end
 return service
end
return W
