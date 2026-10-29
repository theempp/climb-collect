-- Home-base commons v2 (layout C, plan 2026-10-29 §2). Rebuilds the v1 promenade in place as a grey-box:
-- 8 plots of 80x100 on a cross-shaped commons. Terrain, GrandGate and SanctuaryExits are untouched.
-- Colours/materials are A1 tokens (homebase-intel v2) or come from cloned HomeProtos; no new palette.
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local H={version=L.version}
local rgb=Color3.fromRGB
-- A1 tokens (copied from HomePromenade v1).
local K={
 dryStone=rgb(125,139,139),stoneCoping=rgb(185,193,178),cedar=rgb(98,68,43),pierFoot=rgb(73,91,99),
 tealCornice=rgb(46,94,99),brass=rgb(173,139,75),crest=rgb(105,201,211),lanternGlass=rgb(255,221,155),
 meadow=rgb(90,135,82),approach=rgb(179,174,151),pale=rgb(215,208,174),plotFloor=rgb(126,157,132),
 plotEdge=rgb(214,223,208),water=rgb(table.unpack(C.kingdoms[2].color)),
}
local M=Enum.Material
-- v1 lodge body centre, plot-local z (HomeLayout v1 contents.lodge.z).
local V1_LODGE_Z=64
local function part(parent,name,size,cf,color,material,collide,class)
 local p=Instance.new(class or 'Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material
 p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent;return p
end
local function folder(parent,name) local f=Instance.new('Folder');f.Name=name;f.Parent=parent;return f end
local function yawFrame(x,y,z,yaw) return CFrame.new(x,y,z)*CFrame.Angles(0,yaw,0) end
-- Axis-aligned world box between two x and two z values (any order), centred at height y.
local function box(parent,name,x0,x1,z0,z1,y,h,color,material,collide)
 local ax,bx,az,bz=math.min(x0,x1),math.max(x0,x1),math.min(z0,z1),math.max(z0,z1)
 return part(parent,name,Vector3.new(bx-ax,h,bz-az),CFrame.new((ax+bx)/2,y,(az+bz)/2),color,material,collide)
end
local function water(parent,name,x0,x1,z0,z1,y)
 local w=box(parent,name,x0,x1,z0,z1,y,.2,K.water,M.Glass,false);w.Transparency=.25;w.CanQuery=false;return w
end
local function rect(x0,x1,z0,z1) return {minX=math.min(x0,x1),maxX=math.max(x0,x1),minZ=math.min(z0,z1),maxZ=math.max(z0,z1)} end
-- Rect minus cut-outs: grid on all cut edges, then greedy merge (z run first, then widen in x).
local function tile(r,cuts)
 local function axis(lo,hi,a,b)
  local v={lo,hi}
  for _,c in cuts do for _,e in {c[a],c[b]} do if e>lo and e<hi then table.insert(v,e) end end end
  table.sort(v);local u={}
  for _,e in v do if #u==0 or e>u[#u] then table.insert(u,e) end end
  return u
 end
 local xs,zs=axis(r.minX,r.maxX,'minX','maxX'),axis(r.minZ,r.maxZ,'minZ','maxZ')
 local nx,nz=#xs-1,#zs-1;local used={};local out={}
 local function free(i,j)
  if used[i*1000+j] then return false end
  local x,z=(xs[i]+xs[i+1])/2,(zs[j]+zs[j+1])/2
  for _,c in cuts do if x>c.minX and x<c.maxX and z>c.minZ and z<c.maxZ then return false end end
  return true
 end
 for i=1,nx do for j=1,nz do if free(i,j) then
  local j2=j;while j2<nz and free(i,j2+1) do j2+=1 end
  local i2=i
  while i2<nx do
   local ok=true;for jj=j,j2 do if not free(i2+1,jj) then ok=false;break end end
   if not ok then break end;i2+=1
  end
  for ii=i,i2 do for jj=j,j2 do used[ii*1000+jj]=true end end
  table.insert(out,rect(xs[i],xs[i2+1],zs[j],zs[j2+1]))
 end end end
 return out
end

function H.apply(sanctuary,world)
 assert(sanctuary and world,'Sanctuary and mountain required')
 if sanctuary:GetAttribute('PromenadeVersion')==H.version then return false end
 assert(sanctuary:GetAttribute('PromenadeVersion')==1,'Expected the v1 promenade')
 local P=game.ServerStorage:FindFirstChild('HomeProtos');assert(P,'HomeProtos missing')
 for _,n in {'Lantern','Tree','PlantingBed','Boulder'} do assert(P:FindFirstChild(n) and P[n]:GetAttribute('PlacedScale'),'Proto '..n..' missing') end
 -- Clone a proto at an absolute scale (same meaning as the v1 place() scale).
 local function proto(name,to,parent,scale)
  local m=P[name];local from=m:GetPivot();local k=scale/m:GetAttribute('PlacedScale')
  for _,p in m:GetDescendants() do if p:IsA('BasePart') then
   local rel=from:ToObjectSpace(p.CFrame);local c=p:Clone()
   c.CFrame=to*(CFrame.new(rel.Position*k)*rel.Rotation);c.Size=p.Size*k;c.Anchored=true;c.CanTouch=false;c.Parent=parent
  end end
 end
 local gy=L.groundY;local a=L.axisX;local cr=L.cross;local poolZ=L.poolZ
 local cw=L.channelWidth/2;local pw=L.promenadeWidth/2;local pr=L.crossPool/2;local hr=L.armReach-L.endPlaza
 local report={removedParts=0,builtParts=0,lodgePartsOutside=0}

 -- Tear down v1.
 local old=sanctuary:FindFirstChild('HomePromenade')
 if old then for _,d in old:GetDescendants() do if d:IsA('BasePart') then report.removedParts+=1 end end;old:Destroy() end

 -- Plots refit to 80x100, fronts on the vertical street.
 local shift=L.contents.lodge.z-V1_LODGE_Z
 for i,p in L.plots do
  local plot=sanctuary.SanctuaryPlots[string.format('Plot_%02d',i)]
  local floor=plot:FindFirstChild('Plot_140x180') or plot:FindFirstChild(L.floorName)
  assert(floor,'Plot floor missing: '..plot.Name)
  local oldCF=floor.CFrame;local newCF=yawFrame(p.x,gy-1,p.z,p.yaw)
  local function move(inst)
   local rel=oldCF:ToObjectSpace(inst:IsA('Model') and inst:GetPivot() or inst.CFrame)
   local cf=newCF*CFrame.new(rel.X,rel.Y,rel.Z+shift)*rel.Rotation
   if inst:IsA('Model') then inst:PivotTo(cf) else inst.CFrame=cf end
  end
  local lodge=sanctuary.EnchantedAlpineLodges[string.format('Lodge_%02d',i)]
  move(lodge)
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
  local sx,sz=L.spawnWorld(i);local lx,lz=L.spawnLook(i)
  plot.Spawn.CFrame=CFrame.lookAt(Vector3.new(sx,gy+.1,sz),Vector3.new(lx,gy+.1,lz))
  floor.Size=Vector3.new(L.plotWidth,2,L.plotDepth);floor.CFrame=newCF;floor.Name=L.floorName
  plot:SetAttribute('Side',if p.side<0 then 'West' else 'East');plot:SetAttribute('Row',p.row)
  -- Lodge must end inside its plot (part centres checked).
  local e=L.extent(i)
  for _,d in lodge:GetDescendants() do
   if d:IsA('BasePart') and (d.Position.X<e.minX or d.Position.X>e.maxX or d.Position.Z<e.minZ or d.Position.Z>e.maxZ) then report.lodgePartsOutside+=1 end
  end
 end
 if report.lodgePartsOutside>0 then warn('HomeCommons: lodge parts outside plots: '..report.lodgePartsOutside) end

 local root=folder(sanctuary,'HomeCommons');local span=L.span()
 -- Cut-outs shared by the ground slab and the crossing plaza paving.
 local vCut=rect(a-cw,a+cw,L.firstZ,poolZ-pr)
 local hCuts={rect(a-hr,a-pr,cr.z-cw,cr.z+cw),rect(a+pr,a+hr,cr.z-cw,cr.z+cw)}
 local crossPool=rect(a-pr,a+pr,cr.z-pr,cr.z+pr);local southPool=rect(a-pr,a+pr,poolZ-pr,poolZ+pr)
 local cuts={vCut,hCuts[1],hCuts[2],crossPool,southPool}
 local vSegs={rect(a-cw,a+cw,L.firstZ,cr.z-pr),rect(a-cw,a+cw,cr.z+pr,poolZ-pr)}

 -- Ground: meadow slab tiling the basin minus channels/pools; foundations and beds below the cuts.
 local ground=folder(root,'Ground')
 for _,r in tile(rect(span.minX-12,span.maxX+12,L.gate.z-8,L.basin.southZ+76),cuts) do
  box(ground,'BasinGround',r.minX,r.maxX,r.minZ,r.maxZ,gy-.1-8,16,K.meadow,M.Grass)
 end
 for _,r in {vSegs[1],vSegs[2],hCuts[1],hCuts[2],crossPool,southPool} do
  box(ground,'ChannelFoundation',r.minX,r.maxX,r.minZ,r.maxZ,gy-1.7-7.5,15,K.pierFoot,M.Slate)
 end
 for _,r in {vSegs[1],vSegs[2],hCuts[1],hCuts[2]} do box(ground,'ChannelBed',r.minX,r.maxX,r.minZ,r.maxZ,gy-1.2,1,K.pierFoot,M.Slate) end

 local function pave(parent,name,r) box(parent,name,r.minX,r.maxX,r.minZ,r.maxZ,gy-.4,1,K.approach,M.Cobblestone) end
 local streets=folder(root,'Streets')
 -- Vertical street: lanes and kerbs stop at the crossing; channel segments stop at the pools.
 for _,side in {-1,1} do
  for _,z in {{L.firstZ,cr.z0},{cr.z1,poolZ-pr}} do
   box(streets,'WalkingLane',a+side*cw,a+side*pw,z[1],z[2],gy-.4,1,K.approach,M.Cobblestone)
   box(streets,'LaneKerb',a+side*(pw-1.5),a+side*pw,z[1],z[2],gy-.3,1.1,K.pale,M.Slate)
  end
  for _,r in vSegs do box(streets,'ChannelCoping',a+side*(cw-1),a+side*cw,r.minZ,r.maxZ,gy,1.4,K.stoneCoping,M.Slate) end
 end
 for _,r in vSegs do
  water(streets,'ChannelWater',a-(cw-1),a+(cw-1),r.minZ,r.maxZ,gy-.5)
  for _,dx in {-2.5,2.5} do box(streets,'ConveyorGuide',a+dx-.15,a+dx+.15,r.minZ,r.maxZ,gy-.64,.12,K.brass,M.Metal,false) end
 end
 -- Horizontal street arms: two lanes either side of the channel, end plaza with a head coping.
 for _,side in {-1,1} do
  local xi,xo,xc=a+side*pw,a+side*hr,a+side*pr
  for _,z in {{cr.z0,cr.z0+L.crossLane},{cr.z1-L.crossLane,cr.z1}} do box(streets,'WalkingLane',xi,xo,z[1],z[2],gy-.4,1,K.approach,M.Cobblestone) end
  for _,z in {{cr.z0,cr.z0+1.5},{cr.z1-1.5,cr.z1}} do box(streets,'LaneKerb',xi,xo,z[1],z[2],gy-.3,1.1,K.pale,M.Slate) end
  for _,z in {{cr.z-cw,cr.z-cw+1},{cr.z+cw-1,cr.z+cw}} do box(streets,'ChannelCoping',xc,xo,z[1],z[2],gy,1.4,K.stoneCoping,M.Slate) end
  water(streets,'ChannelWater',xc,xo,cr.z-(cw-1),cr.z+(cw-1),gy-.5)
  for _,dz in {-2.5,2.5} do box(streets,'ConveyorGuide',xc,xo,cr.z+dz-.15,cr.z+dz+.15,gy-.64,.12,K.brass,M.Metal,false) end
  box(streets,'ChannelHeadCoping',xo-side,xo,cr.z-cw,cr.z+cw,gy,1.4,K.stoneCoping,M.Slate)
  pave(streets,'EndPlazaPaving',rect(xo,a+side*L.armReach,cr.z0,cr.z1))
 end
 -- Crossing plaza paving around the pool and the four channel mouths.
 for _,r in tile(rect(a-pw,a+pw,cr.z0,cr.z1),cuts) do pave(streets,'CrossingPaving',r) end
 box(streets,'PoolBasin',a-pr,a+pr,cr.z-pr,cr.z+pr,gy-1.2,1,K.pierFoot,M.Slate)
 water(streets,'PoolWater',a-(pr-1),a+(pr-1),cr.z-(pr-1),cr.z+(pr-1),gy-.5)
 -- Coping: z edges carry the corners, x edges stop short of them; 12-wide mouths stay open.
 for _,e in {-pr,pr} do for _,s in {-1,1} do
  box(streets,'PoolCoping',a+s*cw,a+s*(pr+1),cr.z+e-1,cr.z+e+1,gy,1.4,K.stoneCoping,M.Slate)
  box(streets,'PoolCoping',a+e-1,a+e+1,cr.z+s*cw,cr.z+s*(pr-1),gy,1.4,K.stoneCoping,M.Slate)
 end end

 -- Gate plaza and the north channel head.
 local gate=folder(root,'GatePlaza')
 pave(gate,'GatePlazaPaving',L.commons.gatePlaza)
 box(gate,'ChannelHeadCoping',a-cw,a+cw,L.firstZ,L.firstZ+1,gy,1.4,K.stoneCoping,M.Slate)

 -- South plaza: v1 recipe moved to poolZ (inflow edge open).
 local south=folder(root,'SouthPlaza')
 for _,sgn in {-1,1} do part(south,'PlazaPaving',Vector3.new(42,1,35),CFrame.new(a+sgn*34,gy-.4,poolZ+4.5),K.approach,M.Cobblestone) end
 part(south,'PlazaPaving',Vector3.new(26,1,9),CFrame.new(a,gy-.4,poolZ+17.5),K.approach,M.Cobblestone)
 part(south,'PoolBasin',Vector3.new(26,1,26),CFrame.new(a,gy-1.2,poolZ),K.pierFoot,M.Slate)
 local pool=part(south,'PoolWater',Vector3.new(24,.2,24),CFrame.new(a,gy-.5,poolZ),K.water,M.Glass,false);pool.Transparency=.25;pool.CanQuery=false
 for _,e in {{0,13,26,1},{-13,0,1,26},{13,0,1,26}} do
  part(south,'PoolCoping',Vector3.new(e[3]+1,1.4,e[4]+1),CFrame.new(a+e[1],gy,poolZ+e[2]),K.stoneCoping,M.Slate)
 end

 -- Lanterns: V lane outer edges at plot front ends and strip centres; H street outer edges; south pool.
 local lights=folder(root,'Lanterns')
 local vz={}
 for _,z in L.rows do table.insert(vz,z-(L.plotWidth/2-6));table.insert(vz,z+(L.plotWidth/2-6)) end
 for _,s in L.stripZ do table.insert(vz,(s[1]+s[2])/2) end
 for _,z in vz do for _,side in {-1,1} do proto('Lantern',CFrame.new(a+side*(pw-3),gy,z),lights,1.7) end end
 for _,z in {cr.z0+3,cr.z1-3} do for _,side in {-1,1} do for _,dx in {pw+10,hr-6} do
  proto('Lantern',CFrame.new(a+side*dx,gy,z),lights,1.7)
 end end end
 for _,dx in {-24,24} do proto('Lantern',CFrame.new(a+dx,gy,poolZ+6),lights,1.7) end

 -- Plot shells: v1 front frame plus low dry-stone side walls to the rear edge.
 local shells=folder(root,'PlotShells')
 local fw=L.contents.frontWall
 for _,p in L.plots do
  local pf=yawFrame(p.x,gy,p.z,p.yaw)
  local f=pf*CFrame.new(0,0,-L.plotDepth/2+1.6)
  for _,sgn in {-1,1} do
   local mid=sgn*(L.plotWidth/2+18)/2
   part(shells,'FrontDryStone',Vector3.new(L.plotWidth/2-18,2.2,2.8),f*CFrame.new(mid,1.1,0),K.dryStone,M.Cobblestone)
   part(shells,'FrontCoping',Vector3.new(L.plotWidth/2-17.5,.3,3.2),f*CFrame.new(mid,2.35,0),K.stoneCoping,M.Slate)
   part(shells,'EntryPost',Vector3.new(1.4,11,1.4),f*CFrame.new(sgn*18,5.5,0),K.cedar,M.Wood)
   part(shells,'EntryPostFoot',Vector3.new(2.4,1.2,2.4),f*CFrame.new(sgn*18,.6,0),K.dryStone,M.Slate)
   part(shells,'CornerEndpost',Vector3.new(.9,4.4,.9),f*CFrame.new(sgn*(L.plotWidth/2-.6),2.2,0),K.cedar,M.Wood)
   local len=L.plotDepth/2-fw.z1;local zc=(fw.z1+L.plotDepth/2)/2;local sx=sgn*(L.plotWidth/2-1.4)
   part(shells,'SideDryStone',Vector3.new(2.8,2.2,len),pf*CFrame.new(sx,1.1,zc),K.dryStone,M.Cobblestone)
   part(shells,'SideCoping',Vector3.new(3.2,.3,len),pf*CFrame.new(sx,2.35,zc),K.stoneCoping,M.Slate)
  end
  part(shells,'EntryBeam',Vector3.new(38.5,1.2,1.6),f*CFrame.new(0,11.6,0),K.cedar,M.Wood)
  part(shells,'EntryBrassInlay',Vector3.new(30,.3,1.7),f*CFrame.new(0,11.2,0),K.brass,M.Metal,false)
  part(shells,'EntryCap',Vector3.new(40,.5,2.4),f*CFrame.new(0,12.45,0),K.tealCornice,M.Slate)
 end

 -- Gardens: shared strips (trees at the ends, 4 beds along the centreline, boulder mid) + v1 south garden.
 local gardens=folder(root,'Gardens')
 for _,g in L.gardens do
  local zc=(g.minZ+g.maxZ)/2;local len=g.maxX-g.minX
  local function at(t) return g.minX+t*len end
  for _,t in {.08,.92} do proto('Tree',CFrame.new(at(t),gy,zc),gardens,1.9) end
  for _,t in {.2,.38,.62,.8} do proto('PlantingBed',CFrame.new(at(t),gy,zc)*CFrame.Angles(0,math.pi/2,0),gardens,1.4) end
  proto('Boulder',CFrame.new(at(.5),gy,zc)*CFrame.Angles(0,math.pi/2,0),gardens,2.5)
 end
 -- v1 offsets kept relative to poolZ (v1: southZ 436, poolZ 476).
 for k,dx in {-48,-30,30,48} do
  proto('Tree',CFrame.new(a+dx,gy,poolZ-10+(k%2)*14),gardens,2.2)
  proto('PlantingBed',CFrame.new(a+dx*.6,gy,poolZ+16),gardens,1.6)
 end
 for _,x in {-88,-44,44,88} do proto('Boulder',CFrame.new(a+x,gy,poolZ+20)*CFrame.Angles(0,x,0),gardens,2.5) end

 for _,d in root:GetDescendants() do if d:IsA('BasePart') then report.builtParts+=1 end end
 sanctuary:SetAttribute('PlotWidth',L.plotWidth);sanctuary:SetAttribute('PlotDepth',L.plotDepth)
 sanctuary:SetAttribute('PromenadeVersion',H.version);sanctuary:SetAttribute('PromenadeRemovedParts',report.removedParts)
 world:SetAttribute('PromenadeGateVersion',H.version)
 return report
end

-- Terrain (from HomePromenade v1, unchanged shape): berms are written against the kept v1 basin (L.basin.southZ).
-- Writes only empty cells inside the home-base box (z >= -208); existing mountain cells are never touched.
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
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
 if lateral>0 and z>=-208 and z<=L.basin.southZ+220 then up(gy+ridge(lateral,x,z)) end
 local south=L.basin.southZ+70
 if z>south then up(gy+ridge(z-south,x,z)*fall(lateral)) end
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
