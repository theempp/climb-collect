-- Additive dressing only. All offsets are inside the owned plot's 110x120 grid (HomeLayout.contents).
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local A=require(game.ServerStorage.MountainWorld.Art)
local Tags=game:GetService('CollectionService')
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local W={}
function W.new(home)
 local plots={}
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
 for slot=1,8 do
  local model=home.model(slot);local floor=model:FindFirstChild(L.floorName)
  local root=Instance.new('Model');root.Name='TycoonProduction';root.Parent=model
  local cf=floor.CFrame*CFrame.new(0,floor.Size.Y/2+.15,L.contents.tycoonZ)
  root:SetAttribute('Width',110);root:SetAttribute('Depth',120)
  local spine=part(root,'ConveyorSpine',Vector3.new(10,.4,100),cf,Color3.fromRGB(40,62,65),Enum.Material.Metal)
  spine:SetAttribute('SanctuarySlot',slot);spine:SetAttribute('ActiveHabitats',0);Tags:AddTag(spine,'TycoonConveyor')
  for _,x in ipairs({-5.2,5.2}) do part(root,'SpineTrim',Vector3.new(.3,.25,100),cf*CFrame.new(x,.4,0),Color3.fromRGB(114,203,177),Enum.Material.Neon) end
  local habitats={}
  for i=1,8 do
   local x=if i%2==1 then -30 else 30;local z=-44+math.floor((i-1)/2)*28
   local center=cf*CFrame.new(x,0,z)
   local pad=part(root,'Habitat_'..i,Vector3.new(36,.5,20),center,Color3.fromRGB(85,123,100),Enum.Material.Grass)
   local rim=part(root,'HabitatRim_'..i,Vector3.new(37,.2,21),center*CFrame.new(0,-.15,0),Color3.fromRGB(219,189,122),Enum.Material.Wood)
   local branch=part(root,'Feeder_'..i,Vector3.new(7,.25,3),cf*CFrame.new(if x<0 then -8.5 else 8.5,.15,z),spine.Color,Enum.Material.Metal)
   local frame={}
   for _,dx in ipairs({-17,17}) do for _,dz in ipairs({-9,9}) do
    table.insert(frame,part(root,'HabitatPost_'..i,Vector3.new(.9,2.4,.9),center*CFrame.new(dx,1.3,dz),rim.Color,Enum.Material.Wood))
   end end
   table.insert(frame,part(root,'HabitatBackRail_'..i,Vector3.new(34,.6,.6),center*CFrame.new(0,2,-9),rim.Color,Enum.Material.Wood))
   local gauge=part(root,'StorageTrack_'..i,Vector3.new(28,.25,.8),center*CFrame.new(0,.5,9),spine.Color,Enum.Material.Metal)
   local fill=part(root,'StorageFill_'..i,Vector3.new(.05,.3,.65),center*CFrame.new(-14,.55,9),rim.Color,Enum.Material.Neon)
   fill.Transparency=1
   habitats[i]={pad=pad,rim=rim,branch=branch,label=label(pad,'Habitat '..i,7),cf=center,frame=frame,gauge=gauge,fill=fill}
  end
  local bank=part(root,'ProductionBank',Vector3.new(12,3,6),cf*CFrame.new(0,1.5,56),Color3.fromRGB(219,189,122),Enum.Material.Metal)
  bank.CanQuery=true;bank:SetAttribute('SanctuarySlot',slot);bank:SetAttribute('Service','Sanctuary')
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Manage / collect / bank';prompt.ObjectText='Production eggs';prompt.HoldDuration=.2;prompt.MaxActivationDistance=12;prompt.Parent=bank
  label(bank,'PRODUCTION BANK')
  part(root,'BankPlinth',Vector3.new(14,.6,8),cf*CFrame.new(0,.3,56),spine.Color,Enum.Material.Slate)
  part(root,'BankDepositSlot',Vector3.new(7,.15,1.2),cf*CFrame.new(0,3.1,55),spine.Color,Enum.Material.Metal)
  local machines={}
  for i,name in ipairs({'Processor','Sorter','Collector'}) do
   local machine=part(root,name,Vector3.new(4,3,5),cf*CFrame.new(0,1.6,-30+(i-1)*28),Color3.fromRGB(82,104,114),Enum.Material.Metal)
   local pieces={}
   for _,x in ipairs({-3.8,3.8}) do table.insert(pieces,part(root,name..'Pillar',Vector3.new(1.2,5,2),machine.CFrame*CFrame.new(x,.8,0),machine.Color,Enum.Material.Metal)) end
   table.insert(pieces,part(root,name..'Arch',Vector3.new(9,1,2),machine.CFrame*CFrame.new(0,3.3,0),machine.Color,Enum.Material.Metal))
   local light=part(root,name..'Status',Vector3.new(5,.2,.25),machine.CFrame*CFrame.new(0,3.3,1.15),bank.Color,Enum.Material.Neon)
   table.insert(pieces,light)
   machines[i]={part=machine,label=label(machine,name),pieces=pieces}
  end
  plots[slot]={root=root,spine=spine,habitats=habitats,machines=machines,bank=bank}
  task.wait()
 end
 local service={}
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
    if species and unlocked then row.creature=A.creature(plot.root,species,row.cf.Position+Vector3.new(0,2,0),.65,if c.level>=35 then 3 elseif c.level>=15 then 2 else 1) end
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
   row.fill.Size=Vector3.new(math.max(.05,28*ratio),.3,.65)
   row.fill.CFrame=row.cf*CFrame.new(-14+14*ratio,.55,9)
   row.fill.Color=if ratio>=1 then Color3.fromRGB(255,211,103) else accent
   row.fill.Transparency=if unlocked and h.eggs>0 then 0 else 1
   row.label.Text=if not unlocked then 'Habitat '..i..' · locked' else (if species then species.name else 'Assign a creature')..'\n'..h.eggs..' / '..T.capacity(p,i)..' production eggs'
   if unlocked and ratio>=1 then row.label.Text..=' · FULL' end
  end
  for i,v in ipairs(plot.machines) do
   local enabled=t.levels.automation>=i+1;v.part.Transparency=if enabled then .1 else .85;v.label.Text=v.part.Name..(if enabled then ' · active' else ' · locked');v.part.Color=accent
   for _,piece in ipairs(v.pieces) do piece.Color=accent;piece.Transparency=if enabled then 0 else .9 end
  end
  plot.spine:SetAttribute('ActiveHabitats',active);plot.spine:SetAttribute('OwnerUserId',player.UserId)
 end
 function service.clear(slot)
  local plot=plots[slot];if not plot then return end
  plot.spine:SetAttribute('ActiveHabitats',0);plot.spine:SetAttribute('OwnerUserId',nil)
  plot.spine:SetAttribute('Automation',0)
  for _,row in ipairs(plot.habitats) do
   if row.creature then row.creature:Destroy();row.creature=nil end
   row.key=nil;row.label.Text='Unoccupied habitat';row.fill.Transparency=1
   row.pad.Transparency=.8;row.rim.Transparency=.8;row.branch.Transparency=.8;row.gauge.Transparency=.9
   for _,piece in ipairs(row.frame) do piece.Transparency=.9 end
  end
  for _,v in ipairs(plot.machines) do v.part.Transparency=.85;v.label.Text=v.part.Name..' · locked';for _,piece in ipairs(v.pieces) do piece.Transparency=.9 end end
 end
 for slot=1,8 do service.clear(slot) end
 return service
end
return W
