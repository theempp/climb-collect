-- On a separate Review06 copy only; source is read before each nearer destination.
assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local root=workspace.ImpossibleMountain
assert(not root:GetAttribute('CompactTerrainVersion'),'Do not rescale twice')
local G=require(game.ReplicatedStorage.MountainShared.CompactGeometry)
local T=workspace.Terrain;local scale=G.scale
local r={scale=scale,beforeCells=0,afterCells=0,beforeMin={math.huge,math.huge,math.huge},beforeMax={-math.huge,-math.huge,-math.huge},afterMin={math.huge,math.huge,math.huge},afterMax={-math.huge,-math.huge,-math.huge}}
local function bounds(which,x,y,z)
 local lo=r[which..'Min'];local hi=r[which..'Max']
 for i,v in {x,y,z} do lo[i]=math.min(lo[i],v);hi[i]=math.max(hi[i],v+4) end
end
-- Measure the actual authored native terrain, before selecting its new footprint.
for z=-2048,-224,16 do
 local m,o=T:ReadVoxels(Region3.new(Vector3.new(2800,-256,z),Vector3.new(5400,1024,z+16)),4)
 for x=1,#o do for y=1,#o[x] do for k=1,4 do if o[x][y][k]>0 then r.beforeCells+=1;bounds('before',2800+(x-1)*4,-256+(y-1)*4,z+(k-1)*4) end end end end
 task.wait()
end
for z=-224,-2048,-16 do
 local dest=Region3.new(Vector3.new(2800,-256,z),Vector3.new(5400,1024,z+16))
 local sourceLo=math.floor((-210+(z+210)/scale-4)/4)*4
 local sourceHi=math.ceil((-210+(z+16+210)/scale+4)/4)*4
 local sm,so=T:ReadVoxels(Region3.new(Vector3.new(2800,-256,sourceLo),Vector3.new(5400,1024,sourceHi)),4)
 local mats,occ={},{}
 for x=1,650 do mats[x]={};occ[x]={}
  local sx=(4096+(2800+(x-.5)*4-4096)/scale-2800)/4+.5
  local ix=math.floor(sx+.5)
  for y=1,320 do mats[x][y]={};occ[x][y]={}
   local sy=(16+(-256+(y-.5)*4-16)/scale+256)/4+.5;local iy=math.floor(sy+.5)
   for k=1,4 do
    local originalZ=-210+(z+(k-.5)*4+210)/scale
    local iz=math.floor((originalZ-sourceLo)/4)+1
    local solid=0;local material=Enum.Material.Air
    if ix>=1 and ix<=650 and iy>=1 and iy<=320 and originalZ>=-2048 and originalZ< -208 and so[ix][iy][iz] then solid=so[ix][iy][iz];material=sm[ix][iy][iz] end
    occ[x][y][k]=solid;mats[x][y][k]=material
    if solid>0 then r.afterCells+=1;bounds('after',2800+(x-1)*4,-256+(y-1)*4,z+(k-1)*4) end
   end
  end
 end
 T:WriteVoxels(dest,4,mats,occ);task.wait()
end
root:SetAttribute('CompactTerrainVersion',1)
r.parts=require(game.ServerStorage.MountainWorld.CompactMountain).apply(root)
workspace.StreamingEnabled=false
root:SetAttribute('ArrivalReady',nil)
return r
