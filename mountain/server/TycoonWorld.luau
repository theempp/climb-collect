-- Tier 1 Hut plot yard (home-base style S3). Built from WorldKit only; colours only from WorldStyle (tools/world_style_lint.py).
-- Positions: HomeLayout.contents (plot-local, front edge z -50). Ground/lamp geometry below is PROPOSED S3 (no plan line).
-- The lodge is kept until the S4 tier houses. Unowned plots get the full yard, dimmed (S3 answer).
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local HT=require(game.ReplicatedStorage.MountainShared.HomeTiers)
local HR=require(game.ReplicatedStorage.MountainShared.HomeRules)
local A=require(game.ServerStorage.MountainWorld.Art)
local Kit=require(game.ServerStorage.MountainWorld.WorldKit)
local Tags=game:GetService('CollectionService')
local W={}
local K=L.contents
local SHOWN_CREATURES=6 -- S1 STOP: max 6 creatures on decor stands per plot
local DIM=.6 -- locked/unowned fade (fraction of opacity removed)
-- PROPOSED S3 ground (x0,x1,z0,z1): entry apron, front cross walk, west walk, rear walk to the lodge.
local WALKS={{-8,8,-49.5,-33.5,'z'},{-31,31,-33.5,-30.5,'x'},{-31,-27,-30.5,7,'z'},{-31,27,7,11.5,'x'}}
local GLOW={{7.25,-41.5,.5,16},{-7.25,-41.5,.5,16},{-19.5,-33.25,23,.5},{19.5,-33.25,23,.5},{-2,7.25,58,.5},{-30.75,-11.75,.5,37.5}} -- x,z,w,d
local KERBS={{8.3,-41.5,.6,16},{-8.3,-41.5,.6,16},{-19.8,-33.8,22.4,.6},{19.8,-33.8,22.4,.6}}
local PATCHES={{-22,-39,6},{22,-39,6},{-28,41,7},{29,-23,4}}
local LAMPS={{-11.5,-36},{11.5,-36},{-21,13.5},{21,13.5}} -- index 3 = pink (S2 answer)
local function cheapest(tier)
 local best;for _,id in HT.propOrder do local d=HT.props[id];if d.tier<=tier and (not best or d.price<best) then best=d.price end end;return best
end
local function remember(m) for _,p in m:GetDescendants() do if p:IsA('BasePart') then p:SetAttribute('BaseT',p.Transparency) end end end
local function dim(m,on)
 for _,p in m:GetDescendants() do if p:IsA('BasePart') then
  local b=p:GetAttribute('BaseT') or 0;p.Transparency=if on then 1-(1-b)*(1-DIM) else b
 end end
end
-- Scale a model about its ground pivot so its footprint fits w x d (never up).
local function fit(m,ground,w,d)
 local cf,size=m:GetBoundingBox();local s=math.min(1,w/size.X,d/size.Z)
 m.WorldPivot=CFrame.new(cf.Position.X,cf.Position.Y-size.Y/2,cf.Position.Z)
 if s<1 then m:ScaleTo(s) end
 m:PivotTo(ground)
end
local function pillText(m,text) local b=m:FindFirstChild('Pill',true);if b then b:FindFirstChild('Label',true).Text=text end end
function W.new(home)
 local plots={}
 for slot=1,8 do
  local model=home.model(slot);local floor=model:FindFirstChild(L.floorName)
  local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0) -- plot-local frame on the floor top
  local function at(x,y,z) return base*CFrame.new(x,y,z) end
  -- Lawn + kerbs: restyle the baked floor and edge strips (colour/material only).
  floor.Color=Kit.rgb('lawn');floor.Material=Enum.Material.SmoothPlastic
  for _,c in model:GetChildren() do if c:IsA('BasePart') and (c.Name=='PlotEdge' or c.Name=='FrontEdge' or c.Name=='RearEdge') then c.Color=Kit.rgb('kerb');c.Material=Enum.Material.SmoothPlastic end end
  local root=Kit.model(model,'TycoonProduction',base);root:SetAttribute('Width',L.plotWidth);root:SetAttribute('Depth',L.plotDepth)
  -- Ground: lilac pavers with pink inlay, thin flare glow, lip kerbs, light lawn patches.
  local ground=Kit.model(root,'Ground',base)
  for _,w in WALKS do
   local x,z,sx,sz=(w[1]+w[2])/2,(w[3]+w[4])/2,w[2]-w[1],w[4]-w[3]
   Kit.part(ground,'Paver','Block',Vector3.new(sx,.3,sz),at(x,.15,z),'paver','body',{collide=true})
   Kit.part(ground,'Inlay','Block',if w[5]=='z' then Vector3.new(.8,.1,sz) else Vector3.new(sx,.1,.8),at(x,.35,z),'inlay','body').CanQuery=false
  end
  for _,g in GLOW do Kit.part(ground,'PathGlow','Block',Vector3.new(g[3],.1,g[4]),at(g[1],.35,g[2]),'pathGlow','trim').CanQuery=false end
  for _,k in KERBS do Kit.part(ground,'Kerb','Block',Vector3.new(k[3],.45,k[4]),at(k[1],.225,k[2]),'kerb','body',{collide=true}) end
  for _,q in PATCHES do Kit.part(ground,'LawnPatch','Cyl',Vector3.new(q[3],.1,q[3]),at(q[1],.05,q[2]),'lawnLight','body').CanQuery=false end
  local lamps=Kit.model(root,'Lamps',base)
  for i,q in LAMPS do Kit.globeLamp(lamps,at(q[1],0,q[2]),{index=i,collide=true}) end
  -- Production: E-W spine (eggs roll toward the bank at +X), bank, 3 machines, per-habitat storage gauges.
  local prod=Kit.model(root,'Production',base)
  local sp=K.spine
  local spine=Kit.part(prod,'ConveyorSpine','Block',Vector3.new(sp.depth,.4,sp.width),at(sp.x,.2,sp.z)*CFrame.Angles(0,math.pi/2,0),'paver','body')
  spine:SetAttribute('SanctuarySlot',slot);spine:SetAttribute('ActiveHabitats',0);Tags:AddTag(spine,'TycoonConveyor')
  for _,dz in {-sp.depth/2+.25,sp.depth/2-.25} do Kit.part(prod,'SpineEdge','Block',Vector3.new(sp.width,.5,.5),at(sp.x,.45,sp.z+dz),'kerb','body') end
  Kit.part(prod,'SpineFlow','Block',Vector3.new(sp.width,.1,.8),at(sp.x,.45,sp.z),'pathGlow','trim').CanQuery=false
  local bk=K.bank
  Kit.part(prod,'BankPlinth','Block',Vector3.new(bk.width,.6,bk.depth),at(bk.x,.3,bk.z),'kerb','body',{collide=true})
  local bank=Kit.part(prod,'ProductionBank','Block',Vector3.new(12,3,6),at(bk.x,2.1,bk.z),'coin','body',{collide=true})
  bank.CanQuery=true;bank:SetAttribute('SanctuarySlot',slot);bank:SetAttribute('Service','Sanctuary')
  Kit.part(prod,'BankRim','Block',Vector3.new(12.4,.3,6.4),at(bk.x,3.75,bk.z),'coinRim','trim')
  Kit.part(prod,'BankDepositSlot','Block',Vector3.new(7,.15,1.2),at(bk.x,3.95,bk.z),'kerb','body')
  local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Manage / collect / bank';prompt.ObjectText='Production eggs';prompt.HoldDuration=.2;prompt.MaxActivationDistance=12;prompt.Parent=bank
  Kit.pillSign(prod,bank.CFrame,{adornee=bank,text='Production bank',offset=Vector3.new(0,3.5,0)})
  local machines={}
  for i,row in ipairs(K.machines) do
   local mm=Kit.model(prod,row.name,at(row.x,0,K.machine.z))
   local body=Kit.part(mm,row.name,'Block',Vector3.new(K.machine.w,3,K.machine.d),at(row.x,1.9,K.machine.z),'vi','body')
   for _,dz in {-3.2,3.2} do Kit.part(mm,row.name..'Pillar','Cyl',Vector3.new(1.2,5,1.2),at(row.x,2.5,K.machine.z+dz),'vi','body') end
   Kit.part(mm,row.name..'Arch','Block',Vector3.new(2,1,8),at(row.x,5.3,K.machine.z),'vi','body')
   Kit.part(mm,row.name..'Status','Block',Vector3.new(.25,.3,5),at(row.x+1.15,5.3,K.machine.z),'ctaHi','trim')
   Kit.pillSign(mm,body.CFrame,{adornee=body,text=row.name,offset=Vector3.new(0,5,0)})
   remember(mm);machines[i]={model=mm,name=row.name}
  end
  -- Habitats: 6 pens (S0.6 tints in habitat order), glass plaque + pill outside the gate, storage gauge by the back rail.
  local pens=Kit.model(root,'Habitats',base);local habitats={}
  local pw,pd=K.habitat.pad.w,K.habitat.pad.d
  for i,h in ipairs(K.habitats) do
   local cf=at(h.x,0,h.z)
   local fence=Kit.fence(pens,cf,{pen=i,w=pw,d=pd,collide=true});fence.Name='Pen_'..i
   local plaque=Kit.plaque(fence,at(h.x+4.5,0,h.z-pd/2-1.2),{text='Habitat '..i});remember(fence)
   local gauge=Kit.part(prod,'StorageTrack_'..i,'Block',Vector3.new(10,.25,.8),at(h.x,.35,h.z+pd/2-1.4),'kerb','body')
   local fill=Kit.part(prod,'StorageFill_'..i,'Block',Vector3.new(.05,.3,.65),at(h.x-5,.4,h.z+pd/2-1.4),'pathGlow','trim');fill.Transparency=1
   habitats[i]={fence=fence,plaque=plaque,cf=cf,gauge=gauge,fill=fill}
  end
  -- Decor stands (14): rebuilt per state key (coin / bare / prop / creature). Side strips face the yard.
  local standRoot=Kit.model(root,'DecorStands',base);local stands={}
  for i,d in ipairs(K.decor) do
   local yaw=if math.abs(d.z+44.5)<.01 then 0 elseif d.x<0 then -math.pi/2 else math.pi/2
   stands[i]={cf=at(d.x,0,d.z)*CFrame.Angles(0,yaw,0)}
  end
  plots[slot]={root=root,spine=spine,habitats=habitats,machines=machines,bank=bank,stands=stands,standRoot=standRoot,parts={ground=ground,lamps=lamps,prod=prod,pens=pens}}
  task.wait()
 end
 local function creatureOf(p,id) for _,v in ipairs(p.creatures) do if v.id==id then return v end end end
 local function setStand(plot,i,key,build)
  local s=plot.stands[i];if s.key==key then return end
  if s.model then s.model:Destroy();s.model=nil end
  s.key=key;local m=build(s.cf) -- builders may yield (unions); a newer state wins
  if s.key~=key then m:Destroy();return end
  s.model=m;m:SetAttribute('Slot',i)
 end
 local function bare(plot,i) setStand(plot,i,'bare',function(cf) return Kit.coinMarker(plot.standRoot,cf,{bare=true}) end) end
 local service={}
 function service.update(player,p)
  local slot=home.plot(player);local plot=slot and plots[slot];if not plot then return end
  local t=p.tycoon;local active=0
  plot.spine:SetAttribute('Automation',t.levels.automation)
  for i,row in ipairs(plot.habitats) do
   local h=t.habitats[i];local unlocked=i<=t.slots;local c=h.creature and creatureOf(p,h.creature)
   if c and unlocked then active+=1 end
   local species=c and C.byId[c.species]
   local key=if species and unlocked then c.id..':'..c.level else ''
   if row.key~=key then
    if row.creature then row.creature:Destroy();row.creature=nil end
    if key~='' then
     row.creature=A.creature(plot.root,species,row.cf.Position+Vector3.new(0,2,0),.65,if c.level>=35 then 3 elseif c.level>=15 then 2 else 1)
     row.creature:SetAttribute('DisplayCreature','pen');fit(row.creature,row.cf*CFrame.new(0,.2,0),11,10)
    end
    row.key=key
   end
   if row.unlocked~=unlocked then dim(row.fence,not unlocked);row.unlocked=unlocked end
   row.gauge.Transparency=if unlocked then 0 else .9
   local capacity=T.capacity(p,i);local ratio=math.clamp(h.eggs/capacity,0,1)
   row.fill.Size=Vector3.new(math.max(.05,10*ratio),.3,.65)
   row.fill.CFrame=row.gauge.CFrame*CFrame.new(-5+5*ratio,.05,0)
   row.fill.Color=Kit.rgb(if ratio>=1 then 'coin' else 'pathGlow')
   row.fill.Transparency=if unlocked and h.eggs>0 then 0 else 1
   local text=if not unlocked then 'Habitat '..i..' · locked' else (if species then species.name else 'Assign a creature')..' · '..h.eggs..'/'..capacity..' eggs'
   if unlocked and ratio>=1 then text..=' · FULL' end
   pillText(row.plaque,text)
  end
  for i,v in ipairs(plot.machines) do
   local enabled=t.levels.automation>=i+1
   if v.enabled~=enabled then dim(v.model,not enabled);v.enabled=enabled end
   pillText(v.model,v.name..(if enabled then ' · active' else ' · locked'))
  end
  -- Decor: usable empty = coin marker (price = cheapest buyable prop), beyond usable = bare, prop = catalog form,
  -- creature = first 6 shown on their stands, the rest leave a bare stand.
  local tier=HR.tier(p);local usable=HR.usable(p);local price=cheapest(tier);local decor=type(p.home)=='table' and p.home.decor or {};local shown=0
  for i=1,HT.slots do
   local d=decor[tostring(i)]
   if d and d.kind=='prop' and HT.props[d.id] then
    local def=HT.props[d.id]
    setStand(plot,i,'prop:'..d.id,function(cf)
     local m=Kit.coinMarker(plot.standRoot,cf,{bare=true});local top=cf*CFrame.new(0,Kit.standTop,0)
     local prop=Kit[def.proto](m,top,{});fit(prop,top,6.5,6.5);return m
    end)
   elseif d and d.kind=='creature' and shown<SHOWN_CREATURES and creatureOf(p,d.id) and C.byId[creatureOf(p,d.id).species] then
    shown+=1;local c=creatureOf(p,d.id)
    setStand(plot,i,'creature:'..c.id..':'..c.level,function(cf)
     local m=Kit.coinMarker(plot.standRoot,cf,{bare=true});local top=cf*CFrame.new(0,Kit.standTop,0)
     local cm=A.creature(m,C.byId[c.species],top.Position+Vector3.new(0,1,0),.35,if c.level>=35 then 3 elseif c.level>=15 then 2 else 1)
     cm:SetAttribute('DisplayCreature','stand');fit(cm,top,3.6,3.6);return m
    end)
   elseif not d and i<=usable and price then
    setStand(plot,i,'coin:'..price,function(cf) return Kit.coinMarker(plot.standRoot,cf,{price=price,pill=false}) end)
   else bare(plot,i) end
  end
  plot.owned=true
  plot.spine:SetAttribute('ActiveHabitats',active);plot.spine:SetAttribute('OwnerUserId',player.UserId)
 end
 function service.clear(slot)
  local plot=plots[slot];if not plot then return end
  plot.spine:SetAttribute('ActiveHabitats',0);plot.spine:SetAttribute('OwnerUserId',nil);plot.spine:SetAttribute('Automation',0)
  for i,row in ipairs(plot.habitats) do
   if row.creature then row.creature:Destroy();row.creature=nil end
   row.key=nil;row.fill.Transparency=1;row.gauge.Transparency=.9
   dim(row.fence,true);row.unlocked=false;pillText(row.plaque,'Unoccupied habitat')
  end
  for _,v in ipairs(plot.machines) do dim(v.model,true);v.enabled=false;pillText(v.model,v.name..' · locked') end
  for i in ipairs(plot.stands) do bare(plot,i) end
  plot.owned=false
 end
 for slot=1,8 do service.clear(slot) end
 return service
end
return W
