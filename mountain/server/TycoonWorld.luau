-- Tier 1 Hut plot yard (home-base style S3). Built from WorldKit only; colours only from WorldStyle (tools/world_style_lint.py).
-- Positions: HomeLayout.contents (plot-local, front edge z -50). Ground/lamp geometry below is PROPOSED S3 (no plan line).
-- S4 (intel B11): HomeSlot + tier House replace the baked cedar lodge (destroyed at runtime). Unowned plots get the full
-- yard and a Hut, dimmed (S3 answer, B11 unowned rule), no banner / ring.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local HT=require(game.ReplicatedStorage.MountainShared.HomeTiers)
local HR=require(game.ReplicatedStorage.MountainShared.HomeRules)
local X=require(game.ReplicatedStorage.MountainShared.ExplorerRules)
local A=require(game.ServerStorage.MountainWorld.Art)
local Kit=require(game.ServerStorage.MountainWorld.WorldKit)
local S=require(game.ReplicatedStorage.MountainShared.WorldStyle)
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
-- B10 (intel pass 4): hatchery + Training Beast. All sizes/offsets PROPOSED there; transcribed literally.
local CRADLES={-90,30,150} -- deg on r 1.5 around the tray centre; -90 = front (-Z)
-- Incubating egg on a cradle (P4 G3 answer). Ball parts are always spheres: d 1.8 stands in for the PROPOSED 1.6x2.1x1.6.
local EGG_D,EGG_SINK=1.8,.2 -- PROPOSED: centre = cradle top + d/2 - sink (nests in the cradle)
local ST=S.tier -- owner rarity map (Theme.luau 1b: blue/gold/violet/prism rc) = intel A house-body rows T1-T4
local EGG={Common=ST.hut.body,Uncommon=ST.hut.body,Rare=ST.villa.body,Epic=ST.manor.body,Mythic=ST.palace.body,Legendary=ST.palace.body}
local function v2(d,h) return Vector3.new(d,h,d) end
-- Invisible helper part (B10 anchors / collider): no colour, no shadow, no query, no touch.
local function ghost(parent,name,size,cf)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.Transparency=1
 p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=parent;return p
end
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
  -- B11: the baked Lodge_0i (Sanctuary.EnchantedAlpineLodges, or under the plot) goes; the footprint markers stay (G14).
  local lodgeName=string.format('Lodge_%02d',slot);local lodges=model.Parent and model.Parent.Parent and model.Parent.Parent:FindFirstChild('EnchantedAlpineLodges')
  local lodge=(lodges and lodges:FindFirstChild(lodgeName)) or model:FindFirstChild(lodgeName,true);if lodge then lodge:Destroy() end
  local homeSlot=Kit.homeSlot(root,at(0,0,0));remember(homeSlot)
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
  -- B10 hatchery: lip / Neon ring / lavText disc dais, lip-vi-lavText pedestal, 3 cradles on static ctaHi rings,
  -- 2 gem clusters, 5 invisible P7 stage anchors. Incubating eggs sit on the cradles (service.update).
  local hx,hz=K.hatchery.x,K.hatchery.z;local col={collide=true}
  local hatch=Kit.model(root,'Hatchery',at(hx,0,hz))
  Kit.part(hatch,'DaisLip','Cyl',v2(13.4,.5),at(hx,.25,hz),'kerb','body',col)
  Kit.part(hatch,'DaisRing','Cyl',v2(12.4,.75),at(hx,.375,hz),'plazaRing','trim',col)
  Kit.part(hatch,'DaisDisc','Cyl',v2(11.6,.8),at(hx,.4,hz),'plazaDisc','body',col)
  Kit.part(hatch,'PedestalFoot','Cyl',v2(5,.8),at(hx,1.2,hz),'lip','body',col)
  Kit.part(hatch,'PedestalColumn','Cyl',v2(3.2,2.4),at(hx,2.8,hz),'vi','body',col)
  Kit.part(hatch,'PedestalTray','Cyl',v2(5.4,.8),at(hx,4.4,hz),'lavText','body',col)
  local cradles={}
  for i,a in ipairs(CRADLES) do
   local x,z=hx+1.5*math.cos(math.rad(a)),hz+1.5*math.sin(math.rad(a))
   Kit.part(hatch,'Cradle'..i,'Cyl',v2(2,.6),at(x,5.1,z),'lip','body')
   Kit.part(hatch,'CradleStatus'..i,'Cyl',v2(2.3,.2),at(x,4.9,z),'ctaHi','trim') -- static in P4; state colours = P7
   cradles[i]=at(x,5.4,z) -- cradle top
  end
  for _,q in {{-34.6,31.6},{-23.4,31.6}} do Kit.gemCluster(hatch,at(q[1],0,q[2])) end
  local stage=Instance.new('Folder');stage.Name='HatchStage';stage.Parent=hatch
  local centre=at(hx,7,hz)
  ghost(stage,'StageCentre',Vector3.one*.2,centre):SetAttribute('RingRadius',8)
  ghost(stage,'Ring1',Vector3.one*.2,centre*CFrame.Angles(math.rad(20),0,0)):SetAttribute('Ring',1)
  ghost(stage,'Ring2',Vector3.one*.2,centre*CFrame.Angles(0,0,math.rad(-25))):SetAttribute('Ring',2)
  ghost(stage,'Ring3',Vector3.one*.2,centre*CFrame.Angles(math.rad(55),0,0)*CFrame.Angles(0,math.rad(45),0)):SetAttribute('Ring',3)
  ghost(stage,'CubeOrigin',Vector3.one*.2,at(hx,5.4,hz))
  remember(hatch)
  -- B10 Training Beast: plain-part pen (Kit.fence only takes pen tints 1-6), violet candy statue on a lip plinth,
  -- one invisible collider. Faces -Z (gate side).
  local bx,bz=K.pen.x,K.pen.z
  local beast=Kit.model(root,'TrainingBeast',at(bx,0,bz))
  local pen=Kit.model(beast,'Pen',at(bx,0,bz))
  Kit.part(pen,'Floor','Block',Vector3.new(12,.2,12),at(bx,.1,bz),'paver','body',col)
  for _,dx in {-6,6} do for _,dz in {-6,6} do
   Kit.part(pen,'Post','Cyl',v2(1.5,3.2),at(bx+dx,1.6,bz+dz),'vi','body',col)
   Kit.part(pen,'Cap','Ball',v2(2,2),at(bx+dx,3.6,bz+dz),'ctaHi','body')
  end end
  for _,dx in {-2,2} do Kit.part(pen,'GatePost','Cyl',v2(1.5,3.2),at(bx+dx,1.6,bz-6),'vi','body',col) end
  Kit.part(pen,'RailBack','TiltCyl',v2(1,12),at(bx,2.24,bz+6),'vi','body',col)
  for _,dx in {-6,6} do Kit.part(pen,if dx<0 then 'RailLeft' else 'RailRight','TiltCyl',v2(1,12),at(bx+dx,2.24,bz)*CFrame.Angles(0,math.pi/2,0),'vi','body',col) end
  local statue=Kit.model(beast,'Beast',at(bx,0,bz+1))
  Kit.part(statue,'Plinth','Cyl',v2(7,.8),at(bx,.6,bz+1),'lip','body',col)
  for _,dx in {-1.4,1.4} do for _,dz in {-1.5,1.5} do Kit.part(statue,'Leg','Cyl',v2(1.6,2),at(bx+dx,2,bz+1+dz),'vi','body') end end
  Kit.part(statue,'Body','Ball',v2(5,5),at(bx,5,bz+.8),'vi','body')
  Kit.part(statue,'Rump','Ball',v2(4.4,4.4),at(bx,4.6,bz+2.6),'vi','body')
  Kit.part(statue,'Head','Ball',v2(3.6,3.6),at(bx,6.8,bz-1.4),'vi','body')
  Kit.part(statue,'Muzzle','Ball',v2(2.2,2.2),at(bx,6.2,bz-2.7),'lavText','body')
  for _,s in {-1,1} do
   Kit.part(statue,'Eye','Ball',v2(.7,.7),at(bx+s*.75,7.3,bz-3),'door','body')
   Kit.part(statue,'Horn','TiltCyl',v2(.8,1.8),at(bx+s*1.1,8.5,bz-1.2)*CFrame.Angles(0,0,math.pi/2-s*math.rad(25)),'pinkText','body') -- axis up, tip out 25 deg
  end
  Kit.part(statue,'Collar','TiltCyl',v2(3.8,.5),at(bx,6.1,bz-.4)*CFrame.Angles(0,math.pi/2,0),'ctaHi','trim') -- axis along Z
  local blocker=ghost(beast,'BeastCollider',Vector3.new(4.6,8.4,8),at(bx,5.2,bz+.6));blocker.CanCollide=true;blocker.CanQuery=true
  remember(beast)
  -- Decor stands (14): rebuilt per state key (coin / bare / prop / creature). Side strips face the yard.
  local standRoot=Kit.model(root,'DecorStands',base);local stands={}
  for i,d in ipairs(K.decor) do
   local yaw=if math.abs(d.z+44.5)<.01 then 0 elseif d.x<0 then -math.pi/2 else math.pi/2
   stands[i]={cf=at(d.x,0,d.z)*CFrame.Angles(0,yaw,0)}
  end
  plots[slot]={model=model,home={slot=homeSlot,cf=at(0,0,0)},root=root,spine=spine,habitats=habitats,machines=machines,bank=bank,stands=stands,standRoot=standRoot,hatch=hatch,cradles=cradles,beast=beast,parts={ground=ground,lamps=lamps,prod=prod,pens=pens}}
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
 local function clearEggs(plot) if plot.eggs then plot.eggs:Destroy();plot.eggs=nil end;plot.eggKey=nil end
 -- One sphere per incubating egg (readyAt set; ready-to-hatch looks the same), max 3, cradles 1..3 in p.eggs order.
 -- Colour = egg rarity (owner map). Rebuilt only when the incubating egg set changes.
 local function setEggs(plot,p)
  local list,key={},''
  for _,e in ipairs(p.eggs or {}) do
   local s=e.readyAt and C.byId[e.species]
   if s and EGG[s.rarity] and #list<#plot.cradles then table.insert(list,{e=e,s=s});key..=tostring(e.id)..':'..e.species..';' end
  end
  if plot.eggKey==key then return end
  clearEggs(plot);plot.eggKey=key
  if #list==0 then return end
  local m=Kit.model(plot.hatch,'Eggs',plot.cradles[1])
  for i,v in ipairs(list) do
   local egg=Kit.part(m,'Egg','Ball',v2(EGG_D,EGG_D),plot.cradles[i]*CFrame.new(0,EGG_D/2-EGG_SINK,0),EGG[v.s.rarity],'body')
   egg.CanQuery=false;egg:SetAttribute('EggId',v.e.id);egg:SetAttribute('Cradle',i)
  end
  plot.eggs=m
 end
 -- B11 home: House rebuilt only on a tier change; banner + ring only with a rank band (recoloured in place on a band
 -- change). Plot attributes DevTier / DevRank (Studio dev action below) win over the profile; any override shows the
 -- plot undimmed. Unowned, no override: dimmed Hut, no banner / ring, CrestGem untagged.
 local function setHome(plot)
  local h,p=plot.home,plot.owned and plot.profile
  local dt,dr=plot.model:GetAttribute('DevTier'),plot.model:GetAttribute('DevRank')
  local key=Kit.houseTiers[dt or (p and HR.tier(p)) or 1];local level=dr or (p and X.summary(p).level)
  if h.key~=key then
   if h.house then h.house:Destroy() end
   h.house=Kit.house(plot.root,h.cf,key);remember(h.house);h.key=key;h.dimmed=nil;h.crest=nil
  end
  local crest=plot.owned==true
  if h.crest~=crest then h.house.CrestGem:SetAttribute('WorldMotion',if crest then 'crestPulse' else nil);h.crest=crest end
  local band=level and S.rankBand(level).key
  if h.band~=band then
   if not band then
    if h.banner then h.banner:Destroy();h.ring:Destroy();h.banner=nil;h.ring=nil end
   elseif h.banner then Kit.setRank(h.banner,band);Kit.setRank(h.ring,band)
   else h.banner=Kit.banner(h.slot,h.cf,band);h.ring=Kit.auraRing(h.slot,h.cf,band);remember(h.banner);remember(h.ring);h.dimmed=nil end
   h.band=band
  end
  local dimmed=not plot.owned and dt==nil and dr==nil
  if h.dimmed~=dimmed then dim(h.house,dimmed);dim(h.slot,dimmed);h.dimmed=dimmed end
 end
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
  if not plot.owned then dim(plot.hatch,false);dim(plot.beast,false) end
  setEggs(plot,p)
  plot.owned=true;plot.profile=p;setHome(plot)
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
  clearEggs(plot);dim(plot.hatch,true);dim(plot.beast,true)
  plot.owned=false;plot.profile=nil;setHome(plot)
 end
 for slot=1,8 do service.clear(slot) end
 -- Studio-only dev tier action (display override, never profile data). Server:
 -- game.ServerStorage.HomeDevTier:Invoke(slot, tier 1..4 or nil, rank level or nil) -> House tier key, House parts,
 -- HomeSlot parts (dais + steps + banner + ring). nil clears that override.
 if require(game.ReplicatedStorage.MountainShared.BuildFlags).studioAids() then
  local old=game.ServerStorage:FindFirstChild('HomeDevTier');if old then old:Destroy() end
  local f=Instance.new('BindableFunction');f.Name='HomeDevTier'
  f.OnInvoke=function(slot,tier,rank)
   local plot=plots[slot];assert(plot,'slot 1..8')
   assert(tier==nil or Kit.houseTiers[tier],'tier 1..4 or nil');assert(rank==nil or (type(rank)=='number' and rank>=1),'rank level >= 1 or nil')
   plot.model:SetAttribute('DevTier',tier);plot.model:SetAttribute('DevRank',rank);setHome(plot)
   local n=0;for _,d in plot.home.slot:GetDescendants() do if d:IsA('BasePart') then n+=1 end end
   return plot.home.key,plot.home.house:GetAttribute('Parts'),n
  end
  f.Parent=game.ServerStorage
 end
 return service
end
return W
