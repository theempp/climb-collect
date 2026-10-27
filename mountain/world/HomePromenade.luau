-- Home-base promenade rebuild (approved 2026-10-26). Rebuilds the baked Review02 sanctuary in place:
-- 4 homes each side of a garden promenade, one grand gate at the mountain end. Mountain terrain/art untouched.
-- Every colour/material here is copied from existing sanctuary/lodge/gateway art or the Catalog; no new palette.
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local H={version=L.version}
local rgb=Color3.fromRGB
-- Tokens sampled from the Review02 sanctuary (names = the source part names).
local K={
 dryStone=rgb(125,139,139),stoneCoping=rgb(185,193,178),cedar=rgb(98,68,43),pierFoot=rgb(73,91,99),
 tealCornice=rgb(46,94,99),brass=rgb(173,139,75),crest=rgb(105,201,211),lanternGlass=rgb(255,221,155),
 meadow=rgb(90,135,82),approach=rgb(179,174,151),pale=rgb(215,208,174),plotFloor=rgb(126,157,132),
 plotEdge=rgb(214,223,208),water=rgb(table.unpack(C.kingdoms[2].color)),
}
local M=Enum.Material
local function part(parent,name,size,cf,color,material,collide,class)
 local p=Instance.new(class or 'Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material
 p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent;return p
end
local function folder(parent,name) local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
-- Clone a cluster of existing art parts from one frame to another (optionally scaled about the source origin).
local function place(protos,from,to,parent,scale)
 scale=scale or 1
 for _,p in protos do
  local rel=from:ToObjectSpace(p.CFrame);local c=p:Clone()
  c.CFrame=to*(CFrame.new(rel.Position*scale)*rel.Rotation);c.Size=p.Size*scale;c.Parent=parent
 end
end
local function pick(model,center,radius,names)
 local out={}
 for _,p in model:GetChildren() do
  if p:IsA('BasePart') and names[p.Name] and Vector2.new(p.Position.X-center.X,p.Position.Z-center.Z).Magnitude<=radius then table.insert(out,p:Clone()) end
 end
 return out
end
local function yawFrame(x,y,z,yaw) return CFrame.new(x,y,z)*CFrame.Angles(0,yaw,0) end

function H.apply(sanctuary,world)
 assert(sanctuary and world,'Sanctuary and mountain required')
 local baked=sanctuary:GetAttribute('PromenadeVersion')
 if baked==H.version then return false end
 -- v1 promenade (Review06) -> v2 compact homes: refit the existing art in place.
 if baked==1 then return H.refit(sanctuary,world) end
 assert(sanctuary.SanctuaryPlots.Plot_01:FindFirstChild('Plot_180x220'),'Expected the Review02 home row')
 local env=sanctuary.AlpineEnvironment_Step3;local gy=L.groundY
 -- Prototypes from the existing boundary art, taken before the old row is cleared.
 local b1=env.NaturalBoundary_01
 local proto={
  lantern={from=CFrame.new(3532,0,4),parts=pick(b1,Vector3.new(3532,0,4),1.5,{LanternCap=true,LanternPlinth=true,CedarLanternPost=true,WarmLanternGlass=true,BrassLanternBase=true})},
  tree={from=CFrame.new(3532,0,53),parts=pick(b1,Vector3.new(3532,0,53),9,{CedarTrunk=true,PineBough=true})},
  bed={from=CFrame.new(3534,0,8),parts=pick(b1,Vector3.new(3534,0,8),4.5,{PlantingSoil=true,AlpineBlossom=true,AlpineLeaf=true})},
  boulder={from=CFrame.new(3530.2,0,15),parts=pick(b1,Vector3.new(3530.2,0,15),1,{WeatheredBoulder=true})},
 }
 -- Boundary hedges become plot dividers (trimmed to the 180 depth).
 local boundaries={}
 for _,m in env:GetChildren() do if m.Name:match('^NaturalBoundary_') then table.insert(boundaries,m) end end
 table.sort(boundaries,function(a,b) return a.Name<b.Name end)
 local report={removedParts=0}

 -- Phase 2: plots refit to 140x180, turned to face the promenade.
 for i,p in L.plots do
  local plot=sanctuary.SanctuaryPlots[string.format('Plot_%02d',i)]
  local floor=plot.Plot_180x220;local oldCF=floor.CFrame
  local newCF=yawFrame(p.x,gy-1,p.z,p.yaw)
  local shift=L.contents.lodge.z-90
  local function move(inst) -- keep lodge-relative offsets, slide toward the new rear
   local rel=oldCF:ToObjectSpace(inst:IsA('Model') and inst:GetPivot() or inst.CFrame)
   local cf=newCF*CFrame.new(rel.X,rel.Y,rel.Z+shift)*rel.Rotation
   if inst:IsA('Model') then inst:PivotTo(cf) else inst.CFrame=cf end
  end
  move(sanctuary.EnchantedAlpineLodges[string.format('Lodge_%02d',i)])
  for _,c in plot:GetChildren() do
   if c.Name=='RearLodgeFootprint_35x30' or c.Name=='LodgeFootprintEdge' then move(c)
   elseif c.Name=='PlotEdge' then
    local rel=oldCF:ToObjectSpace(c.CFrame);c.Size=Vector3.new(c.Size.X,c.Size.Y,L.plotDepth)
    c.CFrame=newCF*CFrame.new(math.sign(rel.X)*(L.plotWidth/2-.25),rel.Y,0)
   elseif c.Name=='FrontEdge' or c.Name=='RearEdge' then
    local rel=oldCF:ToObjectSpace(c.CFrame);c.Size=Vector3.new(L.plotWidth,c.Size.Y,c.Size.Z)
    c.CFrame=newCF*CFrame.new(0,rel.Y,math.sign(rel.Z)*(L.plotDepth/2-.25))
   end
  end
  local s=L.contents.spawn
  local sx,sz=L.toWorld(i,s.x,s.z)
  plot.Spawn.CFrame=CFrame.lookAt(Vector3.new(sx,gy+.1,sz),Vector3.new(L.gate.x,gy+.1,L.gate.z))
  floor.Size=Vector3.new(L.plotWidth,2,L.plotDepth);floor.CFrame=newCF;floor.Name=L.floorName
  plot:SetAttribute('Side',if p.side<0 then 'West' else 'East');plot:SetAttribute('Row',p.row)
 end

 -- Phase 3: clear the old row, its three gates, approaches and their landscapes.
 local function clear(inst) if inst then for _,d in inst:GetDescendants() do if d:IsA('BasePart') then report.removedParts+=1 end end;inst:Destroy() end end
 for _,c in sanctuary:GetChildren() do if c.Name:match('^Buffer_') then clear(c) end end
 for _,name in {'EssentialAccess','GatewayTerrace','ThreeGates_NoGameplay','TerrainMassing_NoLandscaping'} do clear(sanctuary:FindFirstChild(name)) end
 for _,m in env:GetChildren() do if not m.Name:match('^NaturalBoundary_') then clear(m) end end
 clear(world:FindFirstChild('MountainApproaches'))
 for _,name in {'WestSanctuaryExit','EastSanctuaryExit'} do clear(world.SanctuaryExits:FindFirstChild(name)) end
 local span=L.span()
 -- The one remaining exit spans the whole basin at the gate line, so every return crosses it.
 local exit=world.SanctuaryExits.SanctuaryExit
 exit.Size=Vector3.new(span.maxX-span.minX+120,44,18);exit.CFrame=CFrame.new(L.gate.x,gy+22,L.gate.z)

 local root=folder(sanctuary,'HomePromenade')
 -- Ground: slab either side of the channel; the channel bed sits lower for a future conveyor.
 local ground=folder(root,'Ground')
 local x0,x1,z0,z1=span.minX-12,span.maxX+12,L.gate.z-8,L.southZ+76
 local cw=L.channelWidth/2
 for _,side in {-1,1} do
  local a,b=L.axisX+side*cw,(if side<0 then x0 else x1)
  part(ground,'BasinGround',Vector3.new(math.abs(b-a),16,z1-z0),CFrame.new((a+b)/2,gy-.1-8,(z0+z1)/2),K.meadow,M.Grass)
 end
 local poolZ=L.southZ+40
 -- The channel starts in the gate forecourt, clear of the mountain return path through the gate.
 local pz0,pz1=L.gate.z+L.gate.towerDepth/2+6,poolZ-13
 local plen=pz1-pz0;local pc=(pz0+pz1)/2
 part(ground,'ChannelBed',Vector3.new(L.channelWidth,1,plen),CFrame.new(L.axisX,gy-1.2,pc),K.pierFoot,M.Slate)
 part(ground,'ChannelFoundation',Vector3.new(L.channelWidth,15,z1-z0),CFrame.new(L.axisX,gy-1.7-7.5,(z0+z1)/2),K.pierFoot,M.Slate)
 -- Close the slab gap where there is no channel: the gate forecourt and south of the pool.
 part(ground,'GroundPlug',Vector3.new(L.channelWidth,2,pz0-z0),CFrame.new(L.axisX,gy-1.1,(z0+pz0)/2),K.meadow,M.Grass)
 part(ground,'GroundPlug',Vector3.new(L.channelWidth,2,z1-(poolZ+13)),CFrame.new(L.axisX,gy-1.1,(poolZ+13+z1)/2),K.meadow,M.Grass)
 part(ground,'ForecourtPaving',Vector3.new(L.promenadeWidth+40,1,pz0-(L.gate.z+L.gate.towerDepth/2)),CFrame.new(L.axisX,gy-.4,(pz0+L.gate.z+L.gate.towerDepth/2)/2),K.approach,M.Cobblestone)

 -- Phase 5: promenade paving, channel, lanterns, planting, plot-front frames.
 local prom=folder(root,'Promenade')
 for _,side in {-1,1} do
  local lx=L.axisX+side*(cw+L.laneWidth/2)
  part(prom,'WalkingLane',Vector3.new(L.laneWidth,1,plen),CFrame.new(lx,gy-.4,pc),K.approach,M.Cobblestone)
  part(prom,'LaneKerb',Vector3.new(1.5,1.1,plen),CFrame.new(L.axisX+side*(L.promenadeWidth/2-.75),gy-.3,pc),K.pale,M.Slate)
  -- Channel coping: low and walkable, shaped as the edge of a conveyor bed.
  part(prom,'ChannelCoping',Vector3.new(1,1.4,plen),CFrame.new(L.axisX+side*(cw-.5),gy+.0,pc),K.stoneCoping,M.Slate)
 end
 part(prom,'ChannelHeadCoping',Vector3.new(L.channelWidth,1.4,1),CFrame.new(L.axisX,gy,pz0+.5),K.stoneCoping,M.Slate)
 local water=part(prom,'ChannelWater',Vector3.new(L.channelWidth-2,.2,plen),CFrame.new(L.axisX,gy-.5,pc),K.water,M.Glass,false)
 water.Transparency=.25;water.CanQuery=false
 -- Inset brass guide strips mark where conveyor rails could later be fitted.
 for _,dx in {-2.5,2.5} do part(prom,'ConveyorGuide',Vector3.new(.3,.12,plen),CFrame.new(L.axisX+dx,gy-.64,pc),K.brass,M.Metal,false) end
 -- South plaza: paved head with a pool where the channel ends.
 local plaza=folder(root,'SouthGarden')
 for _,sgn in {-1,1} do part(plaza,'PlazaPaving',Vector3.new(42,1,35),CFrame.new(L.axisX+sgn*34,gy-.4,poolZ+4.5),K.approach,M.Cobblestone) end
 part(plaza,'PlazaPaving',Vector3.new(26,1,9),CFrame.new(L.axisX,gy-.4,poolZ+17.5),K.approach,M.Cobblestone)
 part(plaza,'PoolBasin',Vector3.new(26,1,26),CFrame.new(L.axisX,gy-1.2,poolZ),K.pierFoot,M.Slate)
 local pool=part(plaza,'PoolWater',Vector3.new(24,.2,24),CFrame.new(L.axisX,gy-.5,poolZ),K.water,M.Glass,false);pool.Transparency=.25;pool.CanQuery=false
 for _,e in {{0,-13,26,1},{0,13,26,1},{-13,0,1,26},{13,0,1,26}} do
  if not(e[2]==-13) then part(plaza,'PoolCoping',Vector3.new(e[3]+1,1.4,e[4]+1),CFrame.new(L.axisX+e[1],gy,poolZ+e[2]),K.stoneCoping,M.Slate) end
 end
 -- Lanterns line both lane edges at every plot front and divider.
 local lights=folder(root,'Lanterns')
 for row=1,4 do
  local zc=L.firstZ+(row-1)*L.rowPitch+L.plotWidth/2
  for _,z in {zc-52,zc+52,zc+L.rowPitch/2} do
   if z<L.southZ+30 then for _,side in {-1,1} do
    place(proto.lantern.parts,proto.lantern.from,yawFrame(L.axisX+side*(L.promenadeWidth/2-3),gy,z,0),lights,1.7)
   end end
  end
 end
 for _,dx in {-24,24} do place(proto.lantern.parts,proto.lantern.from,CFrame.new(L.axisX+dx,gy,poolZ+6),lights,1.7) end
 -- Plot-front frames: low dry-stone walls with a cedar-and-brass entry frame facing the promenade.
 local frames=folder(root,'PlotFronts')
 for i,p in L.plots do
  local f=yawFrame(p.x,gy,p.z,p.yaw)*CFrame.new(0,0,-L.plotDepth/2+1.6)
  for _,sgn in {-1,1} do
   local mid=sgn*(L.plotWidth/2+18)/2
   part(frames,'FrontDryStone',Vector3.new(L.plotWidth/2-18,2.2,2.8),f*CFrame.new(mid,1.1,0),K.dryStone,M.Cobblestone)
   part(frames,'FrontCoping',Vector3.new(L.plotWidth/2-17.5,.3,3.2),f*CFrame.new(mid,2.35,0),K.stoneCoping,M.Slate)
   part(frames,'EntryPost',Vector3.new(1.4,11,1.4),f*CFrame.new(sgn*18,5.5,0),K.cedar,M.Wood)
   part(frames,'EntryPostFoot',Vector3.new(2.4,1.2,2.4),f*CFrame.new(sgn*18,.6,0),K.dryStone,M.Slate)
   part(frames,'CornerEndpost',Vector3.new(.9,4.4,.9),f*CFrame.new(sgn*(L.plotWidth/2-.6),2.2,0),K.cedar,M.Wood)
  end
  part(frames,'EntryBeam',Vector3.new(38.5,1.2,1.6),f*CFrame.new(0,11.6,0),K.cedar,M.Wood)
  part(frames,'EntryBrassInlay',Vector3.new(30,.3,1.7),f*CFrame.new(0,11.2,0),K.brass,M.Metal,false)
  part(frames,'EntryCap',Vector3.new(40,.5,2.4),f*CFrame.new(0,12.45,0),K.tealCornice,M.Slate)
  for _,sgn in {-1,1} do place(proto.bed.parts,proto.bed.from,f*CFrame.new(sgn*26,0,4.5)*CFrame.Angles(0,math.pi/2,0),frames,1.4) end
 end
 -- Dividers between rows (and at the south end), from the promenade edge outward.
 local dividers=folder(root,'Dividers')
 local lines={}
 for row=1,4 do
  local z=L.firstZ+row*L.rowPitch-L.buffer/2
  for _,side in {-1,1} do table.insert(lines,{z=z,side=side}) end
 end
 for k,line in lines do
  local src=boundaries[k] or boundaries[1]:Clone()
  local from=CFrame.new(src:GetPivot().X,0,0)
  local edge=L.axisX+line.side*L.promenadeWidth/2
  local to=yawFrame(edge,gy,line.z,line.side*math.pi/2)
  local kept={}
  for _,c in src:GetChildren() do if c:IsA('BasePart') and c.Position.Z>=-1 and c.Position.Z<=L.plotDepth+1 then table.insert(kept,c) end end
  local m=Instance.new('Model');m.Name=string.format('Divider_%02d',k);m.Parent=dividers
  place(kept,from,to,m,1)
  -- Trees at the promenade end of every divider.
  place(proto.tree.parts,proto.tree.from,yawFrame(edge+line.side*6,gy,line.z,0),m,1.9)
 end
 for _,m in boundaries do m:Destroy() end
 env:Destroy()
 -- South garden trees and beds; gate forecourt beds.
 for k,dx in {-48,-30,30,48} do
  place(proto.tree.parts,proto.tree.from,CFrame.new(L.axisX+dx,gy,L.southZ+30+(k%2)*14),plaza,2.2)
  place(proto.bed.parts,proto.bed.from,CFrame.new(L.axisX+dx*.6,gy,L.southZ+56),plaza,1.6)
 end
 for _,x in {-88,-44,44,88} do place(proto.boulder.parts,proto.boulder.from,CFrame.new(L.axisX+x,gy,L.southZ+60)*CFrame.Angles(0,x,0),plaza,2.5) end

 -- Phase 4: the single grand gate.
 local gate=Instance.new('Model');gate.Name='GrandGate';gate.Parent=sanctuary
 local g=L.gate;local half=g.opening/2;local tw,td=g.towerWidth,g.towerDepth
 for _,side in {-1,1} do
  local tx=g.x+side*(half+tw/2)
  part(gate,'PierFoot',Vector3.new(tw+4,6,td+4),CFrame.new(tx,gy+3,g.z),K.pierFoot,M.Slate)
  part(gate,'TowerShaft',Vector3.new(tw,56,td),CFrame.new(tx,gy+34,g.z),K.dryStone,M.Cobblestone)
  for _,fz in {-1,1} do
   for _,ix in {-1,1} do part(gate,'CedarPierInlay',Vector3.new(1.6,44,.6),CFrame.new(tx+ix*(tw/2-4),gy+34,g.z+fz*(td/2+.3)),K.cedar,M.Wood,false) end
   part(gate,'BrassInlay',Vector3.new(tw-6,.6,.7),CFrame.new(tx,gy+56,g.z+fz*(td/2+.3)),K.brass,M.Metal,false)
  end
  part(gate,'PierCapital',Vector3.new(tw+4,3,td+4),CFrame.new(tx,gy+63.5,g.z),K.stoneCoping,M.Slate)
  for _,rz in {-1,1} do
   local w=part(gate,'CrownedRoof',Vector3.new(tw+4,10,(td+4)/2),CFrame.new(tx,gy+70,g.z+rz*(td+4)/4)*CFrame.Angles(0,if rz<0 then math.pi else 0,0),K.tealCornice,M.Slate,true,'WedgePart')
  end
  part(gate,'RoofBrassLine',Vector3.new(tw+4.4,.5,.8),CFrame.new(tx,gy+75,g.z),K.brass,M.Metal,false)
  -- Lanterns on the opening faces of both towers, both sides of the gate.
  for _,fz in {-1,1} do
   local lf=CFrame.new(tx-side*(tw/2+1.6),gy+26,g.z+fz*(td/2-3))
   part(gate,'BrassLanternBase',Vector3.new(2.6,.5,2.6),lf*CFrame.new(0,-2.6,0),K.brass,M.Metal,false)
   local glass=part(gate,'WarmLanternGlass',Vector3.new(2,4,2),lf,K.lanternGlass,M.Neon,false)
   part(gate,'LanternCap',Vector3.new(3,.6,3),lf*CFrame.new(0,2.4,0),K.tealCornice,M.Slate,false)
   local light=Instance.new('PointLight');light.Color=K.lanternGlass;light.Range=22;light.Brightness=1.4;light.Parent=glass
  end
  -- Wing walls close the basin between the towers and the planted berms.
  local inner=tx+side*tw/2;local outer=(if side<0 then span.minX else span.maxX)+side*70
  local wl=math.abs(outer-inner);local wx=(inner+outer)/2
  part(gate,'WingDryStone',Vector3.new(wl,22,6),CFrame.new(wx,gy+11,g.z),K.dryStone,M.Cobblestone)
  part(gate,'WingCoping',Vector3.new(wl,1,7.4),CFrame.new(wx,gy+22.5,g.z),K.stoneCoping,M.Slate)
  for t=1,math.floor(wl/24) do part(gate,'WingEndpost',Vector3.new(1.2,6,1.2),CFrame.new(inner+side*t*24,gy+25,g.z+3.9),K.cedar,M.Wood,false) end
  for t=0,2 do place(proto.tree.parts,proto.tree.from,CFrame.new(inner+side*(16+t*30),gy,g.z+9),gate,2.4) end
 end
 -- Lintel spanning the opening, cornice, crest and a crowned centre roof.
 local span2=g.opening+tw*2
 part(gate,'CedarEntablature',Vector3.new(g.opening+tw,4,td-4),CFrame.new(g.x,gy+52,g.z),K.cedar,M.Wood)
 part(gate,'Lintel',Vector3.new(g.opening+tw,8,td-2),CFrame.new(g.x,gy+58,g.z),K.dryStone,M.Cobblestone)
 part(gate,'TealCornice',Vector3.new(span2,1.5,td+2),CFrame.new(g.x,gy+62.75,g.z),K.tealCornice,M.Slate)
 part(gate,'BrassCorniceEdge',Vector3.new(span2+.4,.5,td+2.4),CFrame.new(g.x,gy+63.75,g.z),K.brass,M.Metal,false)
 for _,rz in {-1,1} do
  part(gate,'CrownedRoof',Vector3.new(48,9,(td+2)/2),CFrame.new(g.x,gy+68.5,g.z+rz*(td+2)/4)*CFrame.Angles(0,if rz<0 then math.pi else 0,0),K.tealCornice,M.Slate,true,'WedgePart')
  local crest=part(gate,'GatewayCrest',Vector3.new(9,9,.6),CFrame.new(g.x,gy+58,g.z+rz*(td/2))*CFrame.Angles(0,0,math.pi/4),K.crest,M.Neon,false)
  part(gate,'CrestFrame',Vector3.new(11,11,.4),CFrame.new(g.x,gy+58,g.z+rz*(td/2-.1))*CFrame.Angles(0,0,math.pi/4),K.brass,M.Metal,false)
  for _,ix in {-1,1} do
   part(gate,'CantileverBrace',Vector3.new(1.4,14,1.4),CFrame.new(g.x+ix*(half-4.5),gy+45,g.z+rz*(td/2-3))*CFrame.Angles(0,0,ix*math.rad(40)),K.cedar,M.Wood,false)
  end
 end
 part(gate,'RidgeBrass',Vector3.new(48.4,.5,.8),CFrame.new(g.x,gy+73,g.z),K.brass,M.Metal,false)
 -- Existing exit lanterns flank the opening on the sanctuary side.
 local lanterns={};for _,c in world:GetChildren() do if c.Name=='ExitLantern' then table.insert(lanterns,c) end end
 table.sort(lanterns,function(a,b) return a.Position.X<b.Position.X end)
 for k,c in lanterns do c.CFrame=CFrame.new(g.x+(if k==1 then -1 else 1)*(half-6),c.Position.Y,g.z+16) end

 sanctuary:SetAttribute('PlotWidth',L.plotWidth);sanctuary:SetAttribute('PlotDepth',L.plotDepth)
 sanctuary:SetAttribute('FrontWalkingDepth',nil);sanctuary:SetAttribute('Revision2',nil)
 sanctuary:SetAttribute('PromenadeVersion',H.version);sanctuary:SetAttribute('PromenadeRemovedParts',report.removedParts)
 world:SetAttribute('PromenadeGateVersion',H.version)
 return report
end

-- v1 numbers, frozen: the Review06 bake was built from these. Used only to locate the existing art.
local V1={plotWidth=140,plotDepth=180,rowPitch=148,southZ=436,frontHalf=52,floorName='Plot_140x180'}
V1.poolZ=V1.southZ+40;V1.groundZ1=V1.southZ+76
local function v1Plot(i)
 local p=L.plots[i];return L.axisX+p.side*(L.promenadeWidth/2+V1.plotDepth/2),L.firstZ+(p.row-1)*V1.rowPitch+V1.plotWidth/2
end
-- Refit the v1 promenade to the compact v2 layout (2026-10-27). Moves, trims and scales existing art only; no new palette.
function H.refit(sanctuary,world)
 local gy=L.groundY;local report={moved=0,trimmed=0,lodgeScale=0}
 local plots=sanctuary.SanctuaryPlots;local root=sanctuary.HomePromenade
 -- Lodges shrink uniformly to fit the 30x22 rear allowance (35x30 before).
 local lodgeScale=math.min(L.contents.lodge.width/35,L.contents.lodge.depth/30);report.lodgeScale=lodgeScale
 for i,p in L.plots do
  local plot=plots[string.format('Plot_%02d',i)];local floor=plot[V1.floorName]
  local ox,oz=v1Plot(i)
  local oldCF,newCF=yawFrame(ox,gy-1,oz,p.yaw),yawFrame(p.x,gy-1,p.z,p.yaw)
  local oldFp=plot.RearLodgeFootprint_35x30.CFrame;local fpRel=oldCF:ToObjectSpace(oldFp)
  local newFp=newCF*CFrame.new(0,fpRel.Y,L.contents.lodge.z)*fpRel.Rotation
  local lodge=sanctuary.EnchantedAlpineLodges[string.format('Lodge_%02d',i)]
  local rel=oldFp:ToObjectSpace(lodge:GetPivot())
  lodge:ScaleTo(lodge:GetScale()*lodgeScale)
  lodge:PivotTo(newFp*CFrame.new(rel.Position*lodgeScale)*rel.Rotation)
  for _,c in plot:GetChildren() do
   if c.Name=='RearLodgeFootprint_35x30' or c.Name=='LodgeFootprintEdge' then
    local r=oldFp:ToObjectSpace(c.CFrame)
    c.Size=Vector3.new(if c.Size.X>1 then c.Size.X*lodgeScale else c.Size.X,c.Size.Y,if c.Size.Z>1 then c.Size.Z*lodgeScale else c.Size.Z)
    c.CFrame=newFp*CFrame.new(r.X*lodgeScale,r.Y,r.Z*lodgeScale)*r.Rotation
   elseif c.Name=='PlotEdge' then
    local r=oldCF:ToObjectSpace(c.CFrame);c.Size=Vector3.new(c.Size.X,c.Size.Y,L.plotDepth)
    c.CFrame=newCF*CFrame.new(math.sign(r.X)*(L.plotWidth/2-.25),r.Y,0)
   elseif c.Name=='FrontEdge' or c.Name=='RearEdge' then
    local r=oldCF:ToObjectSpace(c.CFrame);c.Size=Vector3.new(L.plotWidth,c.Size.Y,c.Size.Z)
    c.CFrame=newCF*CFrame.new(0,r.Y,math.sign(r.Z)*(L.plotDepth/2-.25))
   end
  end
  local s=L.contents.spawn;local sx,sz=L.toWorld(i,s.x,s.z)
  plot.Spawn.CFrame=CFrame.lookAt(Vector3.new(sx,gy+.1,sz),Vector3.new(L.gate.x,gy+.1,L.gate.z))
  floor.Size=Vector3.new(L.plotWidth,2,L.plotDepth);floor.CFrame=newCF;floor.Name=L.floorName
  report.moved+=1
 end
 -- Plot fronts: each piece follows its plot; the dry-stone runs shorten to the 100 frontage.
 for _,c in root.PlotFronts:GetDescendants() do
  if c:IsA('BasePart') then
   local best,bi,br=math.huge,1,CFrame.new()
   for i,p in L.plots do
    local x,z=v1Plot(i);local f=yawFrame(x,gy,z,p.yaw)*CFrame.new(0,0,-V1.plotDepth/2+1.6)
    local r=f:ToObjectSpace(c.CFrame);if r.Position.Magnitude<best then best,bi,br=r.Position.Magnitude,i,r end
   end
   local p=L.plots[bi];local f=yawFrame(p.x,gy,p.z,p.yaw)*CFrame.new(0,0,-L.plotDepth/2+1.6)
   local sgn=if br.X<0 then -1 else 1
   if c.Name=='FrontDryStone' or c.Name=='FrontCoping' then
    c.Size=Vector3.new(L.plotWidth/2-18+(if c.Name=='FrontCoping' then .5 else 0),c.Size.Y,c.Size.Z)
    c.CFrame=f*CFrame.new(sgn*(L.plotWidth/2+18)/2,br.Y,br.Z)*br.Rotation
   elseif c.Name=='CornerEndpost' then c.CFrame=f*CFrame.new(sgn*(L.plotWidth/2-.6),br.Y,br.Z)*br.Rotation
   else c.CFrame=f*br end
  end
 end
 -- Promenade lanes, kerbs, coping, water and guides: same cross-section, shorter run to the moved pool.
 local dz=L.southZ-V1.southZ;local poolZ=L.southZ+40
 local pz0=L.gate.z+L.gate.towerDepth/2+6;local pz1=poolZ-13;local plen=pz1-pz0;local pc=(pz0+pz1)/2
 for _,c in root.Promenade:GetChildren() do
  if c:IsA('BasePart') and c.Name~='ChannelHeadCoping' then c.Size=Vector3.new(c.Size.X,c.Size.Y,plen);c.Position=Vector3.new(c.Position.X,c.Position.Y,pc) end
 end
 for _,c in root.Ground:GetChildren() do
  if c.Name=='ChannelBed' then c.Size=Vector3.new(c.Size.X,c.Size.Y,plen);c.Position=Vector3.new(c.Position.X,c.Position.Y,pc)
  elseif c.Name=='GroundPlug' and c.Position.Z>0 then
   local a,b=poolZ+13,V1.groundZ1;c.Size=Vector3.new(c.Size.X,c.Size.Y,b-a);c.Position=Vector3.new(c.Position.X,c.Position.Y,(a+b)/2)
  end
 end
 -- South garden and its pool lanterns slide north with the shorter rows.
 for _,c in root.SouthGarden:GetDescendants() do if c:IsA('BasePart') then c.CFrame+=Vector3.new(0,0,dz) end end
 -- Lane lanterns: re-anchor every cluster to its new plot-front or divider position.
 local anchors={}
 for row=1,4 do
  local zo=L.firstZ+(row-1)*V1.rowPitch+V1.plotWidth/2;local zn=L.firstZ+(row-1)*L.rowPitch+L.plotWidth/2;local fn=L.plotWidth/2-18
  table.insert(anchors,{zo-V1.frontHalf,zn-fn});table.insert(anchors,{zo+V1.frontHalf,zn+fn});table.insert(anchors,{zo+V1.rowPitch/2,zn+L.rowPitch/2})
 end
 table.insert(anchors,{V1.poolZ+6,poolZ+6})
 for _,c in root.Lanterns:GetDescendants() do
  if c:IsA('BasePart') then
   local best,to=math.huge,nil
   for _,a in anchors do local d=math.abs(c.Position.Z-a[1]);if d<best then best,to=d,a end end
   if to and best<6 then c.CFrame+=Vector3.new(0,0,to[2]-to[1]) end
  end
 end
 -- Dividers: same hedges, moved to the new row lines and trimmed to the 130 depth.
 local dividers=root.Dividers:GetChildren();table.sort(dividers,function(a,b) return a.Name<b.Name end)
 for k,m in dividers do
  local row,side=math.ceil(k/2),if k%2==1 then -1 else 1
  local edge=L.axisX+side*L.promenadeWidth/2
  local oldTo=yawFrame(edge,gy,L.firstZ+row*V1.rowPitch-L.buffer/2,side*math.pi/2)
  local newTo=yawFrame(edge,gy,L.firstZ+row*L.rowPitch-L.buffer/2,side*math.pi/2)
  for _,c in m:GetDescendants() do
   if c:IsA('BasePart') then
    local r=oldTo:ToObjectSpace(c.CFrame)
    if r.Z>L.plotDepth+1 then c:Destroy();report.trimmed+=1 else c.CFrame=newTo*r end
   end
  end
 end
 -- Gate wing walls end where the narrower basin's berms begin.
 local gate=sanctuary.GrandGate;local g=L.gate;local span=L.span()
 for _,side in {-1,1} do
  local inner=g.x+side*(g.opening/2+g.towerWidth);local outer=(if side<0 then span.minX else span.maxX)+side*70
  local wl=math.abs(outer-inner);local wx=(inner+outer)/2
  for _,c in gate:GetChildren() do
   if c:IsA('BasePart') and math.sign(c.Position.X-g.x)==side then
    if c.Name=='WingDryStone' or c.Name=='WingCoping' then c.Size=Vector3.new(wl,c.Size.Y,c.Size.Z);c.Position=Vector3.new(wx,c.Position.Y,c.Position.Z)
    elseif c.Name=='WingEndpost' and math.abs(c.Position.X-g.x)>math.abs(outer-g.x) then c:Destroy() end
   end
  end
 end
 sanctuary:SetAttribute('PlotWidth',L.plotWidth);sanctuary:SetAttribute('PlotDepth',L.plotDepth)
 sanctuary:SetAttribute('PromenadeVersion',H.version);world:SetAttribute('PromenadeGateVersion',H.version)
 return report
end

-- Terrain: planted berms enclose the basin and rise into the mountain foothills.
-- Writes only empty cells inside the home-base box (z >= -208); existing mountain cells are never touched.
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
-- Rolling ridge: rises over 50 studs from the basin edge, then falls away outward.
local function ridge(d,x,z)
 local r=30+6*math.sin(z*.021+x*.013)+4*math.sin(z*.057+1.3)
 if d<=50 then return r*smooth(d/50) end
 return r*(1-smooth((d-50)/80))-30*smooth((d-110)/50)
end
local function fall(d) return if d<=50 then 1 else 1-smooth((d-50)/80) end
function H.bermTop(x,z)
 local s=L.span();local g=L.gate;local gy=L.groundY;local top=nil
 local function up(v) top=if top then math.max(top,v) else v end
 local west,east=s.minX-4,s.maxX+4
 local lateral=if x<west then west-x elseif x>east then x-east else 0
 if lateral>0 and z>=-208 and z<=L.southZ+220 then up(gy+ridge(lateral,x,z)) end
 local south=L.southZ+70
 if z>south then up(gy+ridge(z-south,x,z)*fall(lateral)) end
 -- Behind the gate wings: higher planted shoulders that step down to the mountain's own toe.
 local off=math.abs(x-g.x)-g.opening/2-g.towerWidth-1
 if z<g.z-4 and z>=-208 and off>0 then
  local h=54-34*smooth((g.z-6-z)/36)
  up(gy+(h-gy)*smooth(off/30)*fall(lateral))
 end
 return top
end
H.terrainBox={minX=3600,maxX=4600,minZ=-208,maxZ=820,minY=-24,maxY=100}
-- Measured on Review02: the only original cells in this box are a thin slab y-8..0, z-208..-192 (4352 cells).
function H.protected(y,z) return z<-192 and y<0 end
function H.terrain()
 local T=workspace.Terrain;local b=H.terrainBox;local written,cleared=0,0
 for z=b.minZ,b.maxZ-4,16 do
  local region=Region3.new(Vector3.new(b.minX,b.minY,z),Vector3.new(b.maxX,b.maxY,math.min(z+16,b.maxZ))):ExpandToGrid(4)
  local m,o=T:ReadVoxels(region,4)
  local lo=region.CFrame.Position-region.Size/2
  for i=1,#m do local x=lo.X+(i-.5)*4
   for k=1,#m[i][1] do local zz=lo.Z+(k-.5)*4
    local top=H.bermTop(x,zz)
    for j=1,#m[i] do local y=lo.Y+(j-.5)*4
     if not H.protected(y,zz) then
      local occ=if top then math.clamp((top-(y-2))/4,0,1) else 0
      if occ>0 and y>=-22 then
       o[i][j][k]=occ;m[i][j][k]=if top>L.groundY+34 and y>top-8 then Enum.Material.Rock else Enum.Material.Grass;written+=1
      elseif o[i][j][k]>0 then o[i][j][k]=0;m[i][j][k]=Enum.Material.Air;cleared+=1 end
     end
    end
   end
  end
  T:WriteVoxels(region,4,m,o)
  task.wait()
 end
 return {written=written,cleared=cleared}
end
return H
